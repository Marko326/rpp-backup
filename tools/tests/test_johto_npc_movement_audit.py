"""Gold NPC movement parity audit: current gaps and fail-closed regressions."""
from pathlib import Path
import os
import sys
import tempfile
import unittest

ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(ROOT / "tools"))
from johto_npc_movement_audit import audit, parse_patrol_table, PATROL_MAP_IDS
from johto_olivine_public_runtime import _npc_foot_index

GOLD = Path(os.environ.get("JOHTO_GOLD_SOURCE", ROOT / "pokegold-master"))


class NpcMovementAuditTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        if not GOLD.is_dir():
            raise AssertionError("Gold original checkout required")

    def test_all_six_live_patrols_have_gold_bounds(self):
        # Route29 is intentionally an unfinished placeholder; live indoor
        # patrols must not have any direction or radius audit issues.
        errors = audit(ROOT, GOLD)
        for map_stem in PATROL_MAP_IDS:
            self.assertFalse(any(f"{map_stem}.asm" in err for err in errors), errors)
        self.assertTrue(any("JohtoRoute29.asm" in err for err in errors), errors)
        table = (ROOT / 'engine/overworld/johto_npc_patrol_bounds.asm').read_text()
        records, parse_errors = parse_patrol_table(table)
        self.assertFalse(parse_errors)
        self.assertEqual(set(records), set(PATROL_MAP_IDS.values()))

    def test_wrong_gold_patrol_radius_is_detected(self):
        path = 'engine/overworld/johto_npc_patrol_bounds.asm'
        raw = (ROOT / path).read_text()
        bad = raw.replace('7+4-2, 7+4+2', '7+4-3, 7+4+3', 1)
        self.assertNotEqual(raw, bad)
        errors = audit(ROOT, GOLD, {path: bad})
        self.assertTrue(any('JohtoCherrygroveMart.asm (7,6)' in e
                            and 'runtime bound table' in e for e in errors), errors)

    def test_removed_or_unhooked_patrol_bound_fails(self):
        path = 'engine/overworld/johto_npc_patrol_bounds.asm'
        raw = (ROOT / path).read_text()
        mutated = raw.replace('db JOHTO_OLIVINE_CAFE_LOCAL_ID', '; db JOHTO_OLIVINE_CAFE_LOCAL_ID')
        errors = audit(ROOT, GOLD, {path: mutated})
        self.assertTrue(any('missing active patrol entry JOHTO_OLIVINE_CAFE_LOCAL_ID' in e
                            for e in errors), errors)
        engine = (ROOT / 'engine/overworld/movement.asm').read_text()
        errors = audit(ROOT, GOLD, {'engine/overworld/movement.asm': engine.replace(
            'callab CheckJohtoNPCPatrolBounds', 'nop ; deleted call')})
        self.assertTrue(any('Johto patrol check is not' in e for e in errors), errors)

    def test_patrol_bounds_do_not_require_kanto_engine_replacement(self):
        engine = (ROOT / 'engine/overworld/movement.asm').read_text()
        start = engine.index('.notScripted', engine.index('CanWalkOntoTile:'))
        snippet = engine[start:start+500]
        self.assertIn('callab CheckJohtoNPCPatrolBounds', snippet)
        self.assertIn('push bc', snippet)
        self.assertIn('pop bc', snippet)
        self.assertIn('ret c', snippet)
        helper = (ROOT / 'engine/overworld/johto_npc_patrol_bounds.asm').read_text()
        for token in ('wCurMap', 'REGION_NATIVE_MAP_SLOT', 'wCurRegion',
                      'MAP_REGION_JOHTO', 'wCurLocalMapID', 'cp WALK',
                      'ld a, [hl]                  ; map X',
                      'ld a, [hl]                  ; map Y', 'add e', 'add d',
                      'ld [hl], 2                  ; c1x1 = delayed', 'call Random'):
            self.assertIn(token, helper)

    def test_exact_radius_boundaries_on_each_axis(self):
        # Test walk outcomes with no furniture/occupants; these extra checks
        # are applied before the existing Kanto collision and sprite test.
        table, errors = parse_patrol_table((ROOT / 'engine/overworld/johto_npc_patrol_bounds.asm').read_text())
        self.assertFalse(errors)
        expected = {  # (Gold origin on travel axis, Gold radius)
            'JOHTO_CHERRYGROVE_MART_LOCAL_ID': (7, 2),
            'JOHTO_OLIVINE_MART_LOCAL_ID': (6, 2),
            'JOHTO_OLIVINE_POKECENTER_1F_LOCAL_ID': (8, 1),
            'JOHTO_OLIVINE_CAFE_LOCAL_ID': (5, 1),
            'JOHTO_OLIVINE_PUNISHMENT_SPEECH_HOUSE_LOCAL_ID': (5, 2),
            'JOHTO_CHERRYGROVE_GYM_SPEECH_HOUSE_LOCAL_ID': (5, 1),
        }
        for name, (origin, radius) in expected.items():
            with self.subTest(name=name):
                start, r, packed = table[name]
                lo, hi = divmod(packed, 256)
                self.assertEqual((start,r), (origin, radius))
                self.assertEqual((lo,hi), (origin+4-radius, origin+4+radius))
                self.assertFalse(lo <= lo-1 <= hi)
                self.assertFalse(lo <= hi+1 <= hi)
                self.assertTrue(lo <= lo <= hi)
                self.assertTrue(lo <= hi <= hi)
                self.assertTrue(lo <= origin+4 <= hi)

    def test_compare_branch_reversal_is_detected_by_actual_source_interpretation(self):
        """Reproduce the independent review's confirmed previous audit blind spot."""
        path = 'engine/overworld/johto_npc_patrol_bounds.asm'
        raw = (ROOT / path).read_text()
        for old, new in (
            ('jr c, .blocked', 'jr nc, .blocked'),
            ('jr nc, .blocked', 'jr c, .blocked'),
            ('cp c\n\tjr z, .allow', 'cp c\n\tjr nz, .allow'),
            ('cp b\n\tjr c, .blocked', 'cp c\n\tjr c, .blocked'),
        ):
            with self.subTest(fault=f'{old} => {new}'):
                self.assertIn(old, raw)
                mutated = raw.replace(old, new, 1)
                errors = audit(ROOT, GOLD, {path: mutated})
                self.assertTrue(any('patrol compare branch incorrect' in e for e in errors), errors)

    def test_bad_compare_instruction_fails_closed(self):
        path = 'engine/overworld/johto_npc_patrol_bounds.asm'
        raw = (ROOT / path).read_text()
        mutated = raw.replace('jr c, .blocked', 'adc b', 1)
        errors = audit(ROOT, GOLD, {path: mutated})
        self.assertTrue(any('cannot be semantically audited' in e for e in errors), errors)

    def test_romx_helper_include_must_exist(self):
        main = (ROOT / 'main.asm').read_text()
        original = 'INCLUDE "engine/overworld/johto_npc_patrol_bounds.asm"'
        self.assertIn(original, main)
        errors = audit(ROOT, GOLD, {'main.asm': main.replace(original, '; '+original, 1)})
        self.assertTrue(any('main.asm: Johto patrol helper ROMX SECTION/INCLUDE is missing' in e
                            for e in errors), errors)

    def test_map_region_walker_and_table_guards_must_remain(self):
        path = 'engine/overworld/johto_npc_patrol_bounds.asm'
        raw = (ROOT / path).read_text()
        for old, new in (
            ('cp REGION_NATIVE_MAP_SLOT', 'cp $ff'),
            ('cp MAP_REGION_JOHTO', 'cp MAP_REGION_KANTO'),
            ('cp WALK', 'cp STAY'),
            ('jr nz, .allow', 'jr z, .allow'),
            ('jr z, .found', 'jr nz, .found'),
        ):
            if old not in raw:
                continue
            with self.subTest(old=old):
                errors = audit(ROOT, GOLD, {path: raw.replace(old, new, 1)})
                self.assertTrue(any('guards or local-map lookup changed' in e
                                    or 'map table search' in e for e in errors), errors)

    def test_allow_and_blocked_carry_and_delay_contract_fail_closed(self):
        path = 'engine/overworld/johto_npc_patrol_bounds.asm'
        raw = (ROOT / path).read_text()
        for old, new in (
            ('\tand a                       ; success/clear carry', '\tscf                        ; broken carry'),
            ('\tld [hl], 2                  ; c1x1 = delayed', '\tld [hl], 1                  ; broken delay'),
            ('\tscf\n\tret\n\n.bounds', '\tand a\n\tret\n\n.bounds'),
        ):
            with self.subTest(old=old):
                self.assertIn(old, raw)
                errors = audit(ROOT, GOLD, {path: raw.replace(old, new, 1)})
                self.assertTrue(any('carry' in e or 'blocked path' in e or 'allow path' in e
                                    for e in errors), errors)

    def test_kanto_call_register_and_carry_sequence_must_remain(self):
        path = 'engine/overworld/movement.asm'
        raw = (ROOT / path).read_text()
        for old, new in (
            ('pop bc\n\tret c', 'pop bc\n\tret nc'),
            ('push bc\n\tcallab CheckJohtoNPCPatrolBounds',
             'nop\n\tcallab CheckJohtoNPCPatrolBounds'),
        ):
            with self.subTest(old=old):
                self.assertIn(old, raw)
                errors = audit(ROOT, GOLD, {path: raw.replace(old, new, 1)})
                self.assertTrue(any('patrol check is not on Kanto NPC movement path' in e
                                    for e in errors), errors)

    def test_second_walker_in_patrol_map_is_detected_before_release(self):
        # The current runtime uses map identity rather than sprite identity.
        # A second WALK would share the first NPC's bounds: fail the audit.
        path = 'data/mapObjects/JohtoOlivineMart.asm'
        raw = (ROOT / path).read_text()
        old = 'object SPRITE_JOHTO_LASS, 1, 6, STAY, LEFT, 3'
        self.assertEqual(raw.count(old), 1)
        changed = raw.replace(old, old.replace('STAY, LEFT', 'WALK, 2'), 1)
        errors = audit(ROOT, GOLD, {path: changed})
        self.assertTrue(any('JohtoOlivineMart.asm: patrol-map contract requires exactly one WALK NPC, found 2'
                            in e for e in errors), errors)

    def test_wrong_walk_axis_is_reported(self):
        path = "data/mapObjects/JohtoCherrygroveMart.asm"
        raw = (ROOT / path).read_text()
        old = "object SPRITE_JOHTO_COOLTRAINER_M, 7, 6, WALK, 2, 2"
        new = "object SPRITE_JOHTO_COOLTRAINER_M, 7, 6, WALK, 1, 2"
        self.assertEqual(raw.count(old), 1)
        errors = audit(ROOT, GOLD, {path: raw.replace(old, new, 1)})
        self.assertTrue(any("JohtoCherrygroveMart.asm (7,6)" in e and "requires RPP WALK axis=2" in e
                            for e in errors), errors)

    def test_olivine_pc_fishing_guru_has_kanto_horizontal_axis(self):
        # Gold names the intended direction; Kanto's existing WALK byte is 2
        # for horizontal and 1 for vertical. Do not port Gold's mover engine.
        path = "data/mapObjects/JohtoOlivinePokecenter1F.asm"
        raw = (ROOT / path).read_text()
        correct = "object SPRITE_JOHTO_FISHING_GURU_BLUE, 8, 4, WALK, 2, 2"
        self.assertEqual(raw.count(correct), 1)
        self.assertIn("SPRITEMOVEDATA_WALK_LEFT_RIGHT, 1, 0",
                      (GOLD / "maps/OlivinePokecenter1F.asm").read_text())
        installer = (ROOT / 'tools/install_olivine_public_runtime.py').read_text()
        self.assertIn("'object SPRITE_JOHTO_FISHING_GURU_BLUE, 8, 4, WALK, 2, 2')", installer)
        self.assertNotIn("'object SPRITE_JOHTO_FISHING_GURU_BLUE, 8, 4, WALK, 1, 2')", installer)
        errors = audit(ROOT, GOLD)
        self.assertFalse(any("JohtoOlivinePokecenter1F.asm (8,4)" in issue
                             and "requires RPP WALK axis=" in issue for issue in errors), errors)
        mutated = raw.replace(correct, correct.replace("WALK, 2, 2", "WALK, 1, 2"))
        errors = audit(ROOT, GOLD, {path: mutated})
        self.assertTrue(any("JohtoOlivinePokecenter1F.asm (8,4)" in issue
                            and "requires RPP WALK axis=2" in issue for issue in errors), errors)

    @staticmethod
    def _kanto_foot_step(room, tileset, x, y, delta, *, collision_override=None,
                         mask_override=None):
        # Actual Kanto CanWalkOntoTile reads the lower-left 8x8 foot tile
        # of the candidate 16x16 cell, via wTilesetCollisionPtr. The player
        # Gold position-mask is separate. Check both to catch bad conversions.
        blocks = (ROOT / f"maps/{room}.blk").read_bytes()
        bst = (ROOT / f"gfx/blocksets/{tileset}.bst").read_bytes()
        allowed = (ROOT / f"gfx/tilesets/{tileset}.tilecoll").read_bytes()
        if collision_override is not None:
            allowed = collision_override
        mask = (ROOT / f"maps/{room}.blocked_mask.bin").read_bytes()
        if mask_override is not None:
            mask = mask_override
        width = {'JohtoOlivineMart': 12, 'JohtoOlivinePokecenter1F': 10,
                 'JohtoOlivineCafe': 8}[room]
        dest_x, dest_y = x + delta[0], y + delta[1]
        if not (0 <= dest_x < width and 0 <= dest_y < 8):
            return False, 'out of map'
        block = blocks[(dest_y // 2) * (width // 2) + dest_x // 2]
        offset = _npc_foot_index(dest_x, dest_y)
        foot_tile = bst[block * 16 + offset]
        blocked = bool(mask[dest_y * ((width + 7) // 8) + dest_x // 8]
                       & (1 << (dest_x % 8)))
        passable = foot_tile in allowed[:-1]
        return passable and not blocked, f"foot=${foot_tile:02x}, listed={passable}, mask_blocked={blocked}"

    def test_kanto_npc_axis_and_adjacent_floor_contract(self):
        # Both MART walkers have open left and right tiles, as does Olivine
        # PC. Cafe's working fisherman is the vertical control case.
        specs = (
            ('JohtoCherrygroveMart', 'JohtoOlivineMart', 'johto_olivine_mart', 7, 6, 2),
            ('JohtoOlivineMart', 'JohtoOlivineMart', 'johto_olivine_mart', 6, 2, 2),
            ('JohtoOlivinePokecenter1F', 'JohtoOlivinePokecenter1F',
             'johto_olivine_pokecenter', 8, 4, 2),
            ('JohtoOlivineCafe', 'JohtoOlivineCafe', 'johto_olivine_cafe', 1, 5, 1),
        )
        for npc_room, art_room, tileset, x, y, axis in specs:
            with self.subTest(npc=npc_room):
                objects = (ROOT / f"data/mapObjects/{npc_room}.asm").read_text()
                self.assertRegex(objects, rf'(?m)^\s*object .*?, {x}, {y}, WALK, {axis}, \d+')
                directions = ((-1, 0), (1, 0)) if axis == 2 else ((0, -1), (0, 1))
                for d in directions:
                    ok, why = self._kanto_foot_step(art_room, tileset, x, y, d)
                    self.assertTrue(ok, f"{npc_room} {x,y} to {d}: {why}")
        engine = (ROOT / 'engine/overworld/movement.asm').read_text()
        walk = engine.split('CanWalkOntoTile:', 1)[1].split('GetTileSpriteStandsOn:', 1)[0]
        self.assertIn('ld a, [wTilesetCollisionPtr]', walk)
        self.assertIn('call DetectCollisionBetweenSprites', walk)
        self.assertIn('cp c', walk)
        self.assertIn('cp $2', engine.split('.determineDirection', 1)[1])
        self.assertIn('cp $1', engine.split('.determineDirection', 1)[1])

    def test_kanto_tilecoll_and_mask_fault_injection(self):
        room, tileset = 'JohtoOlivineMart', 'johto_olivine_mart'
        ok, _ = self._kanto_foot_step(room, tileset, 6, 2, (1, 0))
        self.assertTrue(ok)
        coll = (ROOT / f'gfx/tilesets/{tileset}.tilecoll').read_bytes()
        # The conversion fixes shifted foot IDs. Never assume the pre-fix $38
        # (the current generated MART floor is $20).
        blocks = (ROOT / f'maps/{room}.blk').read_bytes()
        bst = (ROOT / f'gfx/blocksets/{tileset}.bst').read_bytes()
        foot_x, foot_y = 7, 2
        block = blocks[(foot_y // 2) * 6 + foot_x // 2]
        foot_id = bst[block * 16 + _npc_foot_index(foot_x, foot_y)]
        self.assertIn(foot_id, coll[:-1])
        ok, reason = self._kanto_foot_step(room, tileset, 6, 2, (1, 0),
                                           collision_override=coll.replace(bytes([foot_id]), b''))
        self.assertFalse(ok, reason)
        mask = bytearray((ROOT / f'maps/{room}.blocked_mask.bin').read_bytes())
        mask[2 * 2] |= (1 << 7)
        ok, reason = self._kanto_foot_step(room, tileset, 6, 2, (1, 0),
                                           mask_override=bytes(mask))
        self.assertFalse(ok, reason)

    def test_wrong_stationary_facing_is_reported(self):
        path = "data/mapObjects/JohtoCherrygrovePokecenter1F.asm"
        raw = (ROOT / path).read_text()
        old = "object SPRITE_JOHTO_NURSE, 3, 1, STAY, DOWN, 1"
        new = "object SPRITE_JOHTO_NURSE, 3, 1, STAY, UP, 1"
        self.assertEqual(raw.count(old), 1)
        errors = audit(ROOT, GOLD, {path: raw.replace(old, new, 1)})
        self.assertTrue(any("JohtoCherrygrovePokecenter1F.asm (3,1)" in e and "requires RPP STAY,DOWN" in e
                            for e in errors), errors)

    def test_unknown_gold_movement_fails_closed(self):
        path = "maps/CherrygroveMart.asm"
        raw = (GOLD / path).read_text()
        old = "SPRITEMOVEDATA_WALK_LEFT_RIGHT, 2, 0"
        new = "SPRITEMOVEDATA_WANDER, 2, 0"
        self.assertEqual(raw.count(old), 1)
        errors = audit(ROOT, GOLD, {"gold/" + path: raw.replace(old, new, 1)})
        self.assertTrue(any("JohtoCherrygroveMart.asm (7,6)" in e and "unsupported Gold movement behavior SPRITEMOVEDATA_WANDER" in e
                            for e in errors), errors)

    def test_new_johto_map_without_gold_source_is_not_silently_skipped(self):
        with tempfile.TemporaryDirectory(prefix="npc-movement-audit-") as tmp:
            root = Path(tmp) / "rpp"
            gold = Path(tmp) / "gold"
            (root / "data/mapObjects").mkdir(parents=True)
            (gold / "maps").mkdir(parents=True)
            (root / "data/mapObjects/JohtoFutureTown.asm").write_text(
                "JohtoFutureTownObject:\n db $00\n db $00\n object SPRITE_GIRL, 1, 1, WALK, 2, 1\n",
                encoding="utf-8")
            errors = audit(root, gold)
            self.assertTrue(any("JohtoFutureTown.asm" in e and "Gold source" in e and "missing" in e
                                for e in errors), errors)

    def test_rpp_npc_without_gold_coordinate_is_reported(self):
        path = "data/mapObjects/JohtoCherrygroveMart.asm"
        raw = (ROOT / path).read_text()
        old = "object SPRITE_JOHTO_COOLTRAINER_M, 7, 6, WALK, 2, 2"
        new = "object SPRITE_JOHTO_COOLTRAINER_M, 6, 6, WALK, 2, 2"
        self.assertEqual(raw.count(old), 1)
        errors = audit(ROOT, GOLD, {path: raw.replace(old, new, 1)})
        self.assertTrue(any("JohtoCherrygroveMart.asm (6,6)" in e and "no Gold object_event" in e
                            for e in errors), errors)

    def test_known_spinrandom_slow_equivalence_is_not_a_false_positive(self):
        errors = audit(ROOT, GOLD)
        self.assertFalse(any("JohtoOlivineTimsHouse.asm (2,3)" in e for e in errors), errors)


if __name__ == "__main__":
    unittest.main()
