"""FIX-274 regression: jumping must never leave a collision-bypass index."""
from pathlib import Path
import shutil
import sys
import tempfile
import unittest

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
from johto_ledge_state_preflight_274 import audit

ROOT = Path(__file__).resolve().parents[2]
FILES = ('home/overworld.asm', 'engine/overworld/player_animations.asm', 'engine/overworld/ledges.asm')


class JumpTeardown274(unittest.TestCase):
    def test_current_lifecycle_and_rom0_gate(self):
        self.assertEqual([], audit(ROOT))

    def test_stale_index_cannot_bypass_collision(self):
        # Model the actual GB RLCA/Carry gate on wd730 bit7, showing that an
        # index left at 1 is NOT a collision bypass after bit7 was cleared.
        for active_bit, index, bypass in ((0, 0, False), (0, 1, False),
                                          (0, 2, False), (1, 1, True), (1, 2, True)):
            self.assertEqual(bool(((active_bit * 0x80) << 1) & 0x100), bypass)

    def test_missing_finalizer_queue_clear_is_rejected(self):
        with tempfile.TemporaryDirectory() as d:
            temp = Path(d)
            for name in FILES:
                dest = temp / name
                dest.parent.mkdir(parents=True, exist_ok=True)
                shutil.copyfile(ROOT / name, dest)
            self.assertEqual([], audit(temp))
            p = temp / 'engine/overworld/player_animations.asm'
            source = p.read_text()
            p.write_text(source.replace('\tld [wSimulatedJoypadStatesIndex], a\n', '', 1))
            self.assertTrue(any('wSimulatedJoypadStatesIndex' in s for s in audit(temp)))
            p.write_text(source)
            p = temp / 'home/overworld.asm'
            original = p.read_text()
            p.write_text(original.replace('\trlca\n\tjp c,.noCollision ; active simulated movement only',
                                               '\tand a\n\tjp nz,.noCollision ; stale index still skips collisions', 1))
            self.assertTrue(any('ROM0 land collision' in s for s in audit(temp)))
            p.write_text(original)
            self.assertEqual([], audit(temp))

if __name__ == '__main__':
    unittest.main()
