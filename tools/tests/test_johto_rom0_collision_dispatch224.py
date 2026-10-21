"""ROM0 relief: exact native land-collision routing and carry ABI regressions."""
from pathlib import Path
import sys
import unittest

ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(ROOT / 'tools'))
from johto_rom0_collision_audit import audit

HOME = 'home/overworld.asm'
ROMX = 'engine/overworld/johto_route33_collision.asm'
MAIN = 'main.asm'


class Rom0CollisionDispatch224(unittest.TestCase):
    def mutate(self, name, before, after, expected):
        raw = (ROOT / name).read_text(encoding='utf8')
        self.assertIn(before, raw)
        changed = raw.replace(before, after, 1)
        self.assertNotEqual(raw, changed)
        problems = audit(ROOT, {name: changed})
        self.assertTrue(any(expected in err for err in problems), problems)

    def test_original_all_11_native_ids_dispatch_and_generic_fallback(self):
        self.assertEqual([], audit(ROOT))

    def test_removing_single_rom0_farcall_is_rejected(self):
        self.mutate(HOME, 'callba JohtoNativeCanStepAhead',
                    'callba JohtoRoute35CanStepAhead', 'single far-call')

    def test_carry_bit_abi_cannot_be_replaced_with_and(self):
        self.mutate(HOME, 'bit 0, e ; BIT preserves Carry',
                    'ld a, e\n\tand 1 ; BIT preserves Carry', 'Carry-preserving')

    def test_unknown_native_map_must_fall_back_to_generic_collision(self):
        self.mutate(ROMX, ' ld e, 0\n ret\n.route35',
                    '\tld e, 1\n\tret\n.route35', 'unknown local ID')

    def test_no_native_map_can_use_wrong_collision_mask(self):
        self.mutate(ROMX, '.route36\n\tcall JohtoRoute36CanStepAhead',
                    '.route36\n\tcall JohtoRoute35CanStepAhead', 'wrong native map->collision predicate')

    def test_missing_ruins_exact_id_must_fail(self):
        self.mutate(ROMX, 'cp JOHTO_ROUTE36_RUINS_GATE_LOCAL_ID\n\tjr z, .ruins',
                    'cp JOHTO_ROUTE_33_LOCAL_ID\n\tjr z, .ruins', 'local-ID inventory')

    def test_unconditional_native_branch_must_fail(self):
        self.mutate(ROMX, 'cp JOHTO_ROUTE_36_LOCAL_ID\n\tjr z, .route36',
                    'cp JOHTO_ROUTE_36_LOCAL_ID\n\tjr nz, .route36', 'equality branches')

    def test_legacy_map_32_seam_must_remain(self):
        self.mutate(HOME, 'cp JOHTO_ROUTE_32_HEIGHT * 2 - 1',
                    'cp JOHTO_ROUTE_32_HEIGHT * 2 - 2', 'legacy Route32 seam')

    def test_moving_romx_dispatch_to_unrelated_bank_is_rejected(self):
        self.mutate(MAIN, 'SECTION "Johto Route33 Collision Mask", ROMX, BANK[$43]',
                    'SECTION "Johto Route33 Collision Mask", ROMX, BANK[$42]', 'co-banked')

    def test_rom0_new_per_map_chain_is_rejected(self):
        self.mutate(HOME, 'callba JohtoNativeCanStepAhead',
                    'cp JOHTO_ROUTE_36_LOCAL_ID\n\tcallba JohtoNativeCanStepAhead',
                    'must not grow per-map')


if __name__ == '__main__':
    unittest.main()
