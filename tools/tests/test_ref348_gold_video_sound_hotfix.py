"""REF-348 Gold Burned Tower field-SFX regression, no ROM build needed."""
from pathlib import Path
import re
import unittest

ROOT = Path(__file__).resolve().parents[2]


def read(rel):
    return (ROOT / rel).read_text(encoding="utf-8")


def audio_pair_status(constants, pointers):
    # The project's SFX pointer table reserves index zero; constants start at one.
    start = constants.rfind("const_value = 1")
    ids = re.findall(r"^\s*const\s+([A-Z0-9_]+)", constants[start:], re.M)
    table = pointers.split("\nSFX:\n", 1)[1]
    slots = re.findall(r"^\s*dbw\s+(.+)$", table, re.M)
    expected = {
        "GSSFX_BURNED_TOWER_KINESIS": "BANK(Sfx_Kinesis), Sfx_Kinesis",
        "GSSFX_BURNED_TOWER_STRENGTH": "BANK(Sfx_Strength), Sfx_Strength",
    }
    if len(slots) != len(ids) + 1:
        return False
    return all(k in ids and slots[ids.index(k) + 1] == v for k, v in expected.items())


class GoldBurnedTowerFieldSounds(unittest.TestCase):
    def test_exact_pointer_aliases_in_correct_slots(self):
        self.assertTrue(audio_pair_status(read("constants/music_constants.asm"), read("crysaudio/rbsfx.asm")))

    def test_sound_data_reused_not_copied(self):
        data = read("crysaudio/sfx.asm")
        self.assertIn("Sfx_Kinesis:", data)
        self.assertIn("Sfx_Strength:", data)
        self.assertEqual(read("crysaudio/rbsfx.asm").count("dbw BANK(Sfx_Kinesis), Sfx_Kinesis"), 1)
        self.assertEqual(read("crysaudio/rbsfx.asm").count("dbw BANK(Sfx_Strength), Sfx_Strength"), 1)

    def test_pit_dispatch_calls_both_gold_sfx_in_order(self):
        s = read("data/johto_burned_tower/REF348_b1f_runtime.asm")
        section = s.split("JohtoBurnedTowerFallEntryAnim::", 1)[1].split("JohtoBurnedTowerEarthquake16::", 1)[0]
        self.assertIn("ld a, GSSFX_BURNED_TOWER_KINESIS", section)
        self.assertIn("ld a, GSSFX_BURNED_TOWER_STRENGTH", section)
        self.assertLess(section.index("GSSFX_BURNED_TOWER_KINESIS"), section.index("GSSFX_BURNED_TOWER_STRENGTH"))
        self.assertNotIn("ld a, SFX_FAINT_FALL", section)
        self.assertNotIn("ld a, SFX_BATTLE_26", section)

    def test_gold_skyfall_shake_timing_preserved(self):
        s = read("data/johto_burned_tower/REF348_b1f_runtime.asm")
        section = s.split("JohtoBurnedTowerFallEntryAnim::", 1)[1]
        self.assertRegex(section, r"ld c, 16\s+call DelayFrames\s+ld hl, \.SkyfallOffsets\s+ld b, 16")
        self.assertRegex(section, r"call JohtoBurnedTowerEarthquake16\s+ld c, 32")
        self.assertIn("ld b, 16", section.split("JohtoBurnedTowerEarthquake16::", 1)[1])
        self.assertRegex(section, r"ld c, 2[^\n]*\n\s*call DelayFrames")
        self.assertIn("ld [hSCY], a", section)

    def test_mutated_pointer_is_rejected(self):
        consts = read("constants/music_constants.asm")
        ptrs = read("crysaudio/rbsfx.asm")
        broken = ptrs.replace("BANK(Sfx_Kinesis), Sfx_Kinesis", "BANK(Sfx_Squeak), Sfx_Squeak")
        self.assertFalse(audio_pair_status(consts, broken))


if __name__ == "__main__":
    unittest.main()
