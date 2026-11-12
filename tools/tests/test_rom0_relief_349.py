"""REF-349: ROM0 helper relocation and far-call ABI regression guards.

Static/source-only checks. These do not replace RGBDS link/MAP or device tests.
"""
from __future__ import annotations
import re
import hashlib
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
HOME = (ROOT / "home.asm").read_text()
OVERWORLD = (ROOT / "home/overworld.asm").read_text()
RELIEF = (ROOT / "home/rom0_relief_349.asm").read_text()

HELPERS = (
    "CheckIfInOutsideMap",
    "IsBikeRidingAllowed",
    "PartyMenuInitState",
    "GetMachineName",
    "PlayTrainerMusic",
)

# SHA-256 of the normalized REF-348 instruction bodies from the supplied source
# archive. This ensures the relocation does not quietly rewrite game logic.
EXPECTED_BODY_SHA256 = {
    "outside": "1195b26f3af50f823c00f972e835e52fab0b6beb2c75dae214d3a2cef8275afb",
    "bike": "a00154cea07dca5a54248d55abc869710ec5560c733890bc775342af3891ee2a",
    "party": "0b548c9c1a6eef153d8522ae52499f44390638b06e291be825000d6aef427a9c",
    "machine": "6966274d16e709206b5b5453e9d61b061bd03698eea9f20ff0a715f6ac88a1ad",
    "trainer": "86b11757ee1b719558ece1b9e09aa989a020ff2d931dea09ec06fefa048ee835",
}


def code_only(text: str) -> str:
    return "\n".join(line.split(";", 1)[0].strip() for line in text.splitlines())


def normalized_hash(text: str) -> str:
    normalized = "\n".join(
        " ".join(code.split())
        for line in text.splitlines()
        if (code := line.split(";", 1)[0].strip())
    )
    return hashlib.sha256(normalized.encode("utf-8")).hexdigest()


class Rom0Relief349(unittest.TestCase):
    def test_all_helpers_and_data_are_in_dedicated_bank_2a_section(self):
        self.assertIn('SECTION "REF349 ROM0 Relief Helpers", ROMX, BANK[$2A]', RELIEF)
        for symbol in HELPERS:
            self.assertEqual(1, RELIEF.count(symbol + "::"), symbol)
            self.assertNotIn(symbol + "::", HOME + OVERWORLD, symbol + " must not remain in ROM0")
        for symbol in (
            "BikeRidingTilesets", "TechnicalPrefix", "HiddenPrefix",
            "FemaleTrainerList", "EvilTrainerList",
        ):
            self.assertIn(symbol, RELIEF)
        self.assertIn('INCLUDE "data/bike_riding_tilesets.asm"', RELIEF)
        self.assertIn('INCLUDE "data/trainer_types.asm"', RELIEF)
        for assertion in (
            'ASSERT BANK(CheckIfInOutsideMap) == $2a',
            'ASSERT BANK(IsBikeRidingAllowed) == $2a',
            'ASSERT BANK(BikeRidingTilesets) == BANK(IsBikeRidingAllowed)',
            'ASSERT BANK(PartyMenuInitState) == $2a',
            'ASSERT BANK(GetMachineName) == $2a',
            'ASSERT BANK(TechnicalPrefix) == BANK(GetMachineName)',
            'ASSERT BANK(HiddenPrefix) == BANK(GetMachineName)',
            'ASSERT BANK(PlayTrainerMusic) == $2a',
            'ASSERT BANK(FemaleTrainerList) == BANK(PlayTrainerMusic)',
            'ASSERT BANK(EvilTrainerList) == BANK(PlayTrainerMusic)',
        ):
            self.assertIn(assertion, RELIEF)

    def test_no_direct_near_calls_to_relocated_symbols_remain(self):
        source = []
        for path in ROOT.rglob("*.asm"):
            if ".git" in path.parts:
                continue
            source.append(path.read_text(errors="ignore"))
        all_asm = "\n".join(source)
        for symbol in HELPERS:
            direct = re.findall(rf"(?m)^\s*(?:call|jp)(?!ab|ba)\s+{symbol}\b", all_asm)
            self.assertEqual([], direct, f"near call/jump still targets moved {symbol}")

    def test_far_call_sites_cover_all_old_callers(self):
        self.assertIn("callab CheckIfInOutsideMap", OVERWORLD)
        self.assertEqual(2, (ROOT / "engine/menu/start_sub_menus.asm").read_text().count("callab CheckIfInOutsideMap"))
        self.assertIn("callab IsBikeRidingAllowed", OVERWORLD)
        self.assertIn("callab IsBikeRidingAllowed", (ROOT / "engine/items/items.asm").read_text())
        self.assertIn("callab IsBikeRidingAllowed", (ROOT / "engine/menu/summary_return_helpers.asm").read_text())
        self.assertIn("farcall IsBikeRidingAllowed", (ROOT / "engine/overworld/bike_shortcut.asm").read_text())
        self.assertIn("jpba PartyMenuInitState", HOME)
        self.assertEqual(2, (ROOT / "engine/menu/battle_party_summary_fast_path.asm").read_text().count("callab PartyMenuInitState"))
        self.assertEqual(2, HOME.count("jpba PlayTrainerMusic"))
        self.assertEqual(2, HOME.count("callab GetMachineName"))

    def test_return_flag_and_register_contracts_are_explicit(self):
        bike = RELIEF.split("IsBikeRidingAllowed::", 1)[1].split('INCLUDE "data/bike_riding_tilesets.asm"', 1)[0]
        self.assertIn("scf\n\tret", bike)
        outside = RELIEF.split("CheckIfInOutsideMap::", 1)[1].split("; Gold GATE", 1)[0]
        self.assertRegex(outside, r"callab JohtoPilotGetOutdoorFlag[^\n]*\n\s*ld a, e\s+cp 1\s+ret")
        self.assertIn("Bankswitch preserves return flags and DE, but clobbers A/BC/HL", RELIEF)
        # GetItemName keeps A/flags around the far call; GetName also saves BC/HL.
        item = HOME.split("GetItemName::", 1)[1].split("IsItemHM::", 1)[0]
        self.assertRegex(item, r"push af\s+callab GetMachineName\s+pop af")
        getname = HOME.split("GetName::", 1)[1].split("\n.noItem", 1)[0]
        self.assertRegex(getname, r"push af\s+push bc\s+push hl\s+callab GetMachineName\s+pop hl\s+pop bc\s+pop af\s+ret")


    def test_moved_instruction_bodies_match_ref348(self):
        bodies = {
            "outside": RELIEF.split("CheckIfInOutsideMap::", 1)[1].split("; Gold GATE", 1)[0],
            "bike": RELIEF.split("IsBikeRidingAllowed::", 1)[1].split('INCLUDE "data/bike_riding_tilesets.asm"', 1)[0],
            "party": RELIEF.split("PartyMenuInitState::", 1)[1].split("; TM/HM name builder", 1)[0],
            "machine": RELIEF.split("GetMachineName::", 1)[1].split("; Trainer encounter music", 1)[0],
            "trainer": RELIEF.split("PlayTrainerMusic::", 1)[1].split("ASSERT BANK(CheckIfInOutsideMap)", 1)[0],
        }
        # REF-349 Dark Cave adds a strictly map-scoped bike policy to the
        # previously relocated helper. Verify the remaining legacy body still
        # matches the original REF-348 hash instead of replacing that historic
        # hash with the new implementation's checksum.
        bikes = bodies["bike"]
        self.assertIn("cp JOHTO_DARK_CAVE_VIOLET_ENTRANCE_LOCAL_ID\n\tjp z, .darkCaveBike", bikes)
        self.assertIn("\n.darkCaveBike\n", bikes)
        bikes = bikes.replace("\tcp JOHTO_DARK_CAVE_VIOLET_ENTRANCE_LOCAL_ID\n\tjp z, .darkCaveBike\n", "", 1)
        # REF-365C adds the same ID-scoped dispatcher for Blackthorn, while
        # the pre-349 Kanto / gate bike decision body stays unchanged.
        self.assertIn("cp JOHTO_DARK_CAVE_BLACKTHORN_ENTRANCE_LOCAL_ID\n\tjp z, .darkCaveBike", bikes)
        bikes = bikes.replace("\tcp JOHTO_DARK_CAVE_BLACKTHORN_ENTRANCE_LOCAL_ID\n\tjp z, .darkCaveBike\n", "", 1)
        # REF-367J adds an Ice Path-only entry in ROMX; remove this one
        # explicit exception before comparing the untouched REF-348 legacy body.
        self.assertIn("cp JOHTO_ICE_PATH_1F_LOCAL_ID\n\tjp z, .icePathBike", bikes)
        bikes = bikes.replace("\tcp JOHTO_ICE_PATH_1F_LOCAL_ID\n\tjp z, .icePathBike\n", "", 1)
        bikes = bikes.split("\n.darkCaveBike\n", 1)[0]
        bodies["bike"] = bikes
        for name, body in bodies.items():
            self.assertEqual(EXPECTED_BODY_SHA256[name], normalized_hash(body), name)



if __name__ == "__main__":
    unittest.main()
