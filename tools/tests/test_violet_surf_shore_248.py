"""Guard shore-tile restoration for each registered Johto map-local Surf helper."""
from pathlib import Path
import re
import unittest

ROOT = Path(__file__).resolve().parents[2]

def has_map_local_shore_tile_restore(source: str, helper: str, next_label: str) -> bool:
    try:
        start = source.index("CollisionCheckOnWater::")
        tail = source[start:]
        end = re.search(rf"(?m)^\.{re.escape(next_label)}\s*$", tail)
        if end is None:
            return False
        body = tail[:end.start()]
    except ValueError:
        return False
    # Strip comments first: comments may be inserted without changing the
    # required instruction order, but the legacy branch must not satisfy this.
    code = "\n".join(line.split(";", 1)[0].strip() for line in body.splitlines())
    return re.search(
        rf"callab {re.escape(helper)}\s+"
        r"jp c, \.noCollision\s+"
        rf"(?:callab JohtoCherrygroveShoreFloorAhead\s+jp c, \.stopSurfing\s+)?"
        r"ld a, \[wTileInFrontOfPlayer\]\s+"
        r"ld c, a\s+"
        r"jr \.checkIfNextTileIsPassable",
        code,
    ) is not None

class MapLocalSurfShoreRegression(unittest.TestCase):
    def test_violet_nonwater_branch_restores_front_tile_to_c(self):
        source = (ROOT / "home/overworld.asm").read_text()
        self.assertTrue(has_map_local_shore_tile_restore(
            source, 'JohtoVioletWaterAhead', 'checkCherrygroveSurf'))
        self.assertTrue(has_map_local_shore_tile_restore(
            source, 'JohtoCherrygroveWaterAhead', 'legacySurfTile'))

    def test_guard_rejects_the_old_buggy_branch(self):
        source = (ROOT / "home/overworld.asm").read_text()
        buggy = re.sub(
            r"\n\s*ld a, \[wTileInFrontOfPlayer\]\n\s*ld c, a(?=\n\s*jr \.checkIfNextTileIsPassable)",
            "", source, count=1,
        )
        self.assertNotEqual(source, buggy, "mutation must remove the map-local restoration")
        self.assertFalse(has_map_local_shore_tile_restore(
            buggy, 'JohtoVioletWaterAhead', 'checkCherrygroveSurf'))

if __name__ == "__main__":
    unittest.main()
