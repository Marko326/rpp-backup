"""Guard shore-tile restoration for each registered Johto map-local Surf helper."""
from pathlib import Path
import re
import unittest

ROOT = Path(__file__).resolve().parents[2]

def has_map_local_shore_tile_restore(source: str, helper: str, next_label: str) -> bool:
    # All registered map-local queries now share a single ROM0 restore path.
    code = "\n".join(line.split(";", 1)[0].strip() for line in source.splitlines())
    return re.search(
        r"callab JohtoOverworldSurfDecision\s+"
        r"jr nc, \.johtoSurfNotWater\s+"
        r"jp z, \.noCollision\s+"
        r"jp \.stopSurfing\s+"
        r"\.johtoSurfNotWater\s+"
        r"jr nz, \.legacySurfTile\s+"
        r"ld a, \[wTileInFrontOfPlayer\]\s+"
        r"ld c, a\s+"
        r"jp \.checkIfNextTileIsPassable", code,
    ) is not None

class MapLocalSurfShoreRegression(unittest.TestCase):
    def test_violet_nonwater_branch_restores_front_tile_to_c(self):
        source = (ROOT / "home/overworld.asm").read_text()
        self.assertTrue(has_map_local_shore_tile_restore(
            source, 'JohtoVioletWaterAhead', 'checkNewBarkSurf'))
        self.assertTrue(has_map_local_shore_tile_restore(
            source, 'JohtoCherrygroveWaterAhead', 'legacySurfTile'))

    def test_guard_rejects_the_old_buggy_branch(self):
        source = (ROOT / "home/overworld.asm").read_text()
        buggy = re.sub(
            r"\n\s*ld a, \[wTileInFrontOfPlayer\]\n\s*ld c, a(?=\n\s*(?:jr|jp) \.checkIfNextTileIsPassable)",
            "", source, count=1,
        )
        self.assertNotEqual(source, buggy, "mutation must remove the map-local restoration")
        self.assertFalse(has_map_local_shore_tile_restore(
            buggy, 'JohtoVioletWaterAhead', 'checkNewBarkSurf'))

if __name__ == "__main__":
    unittest.main()
