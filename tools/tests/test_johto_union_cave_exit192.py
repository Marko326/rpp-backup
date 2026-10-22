"""Gold-anchored negative checks for Route33 <-> Union Cave 1F and Dig."""
from pathlib import Path
import os, shutil, sys, unittest
from tempfile import TemporaryDirectory

ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(ROOT / 'tools'))
from johto_union_cave_exit192_audit import audit

FILES = (
    'data/mapObjects/JohtoUnionCave1F.asm', 'data/mapObjects/JohtoRoute32.asm',
    'data/mapObjects/JohtoRoute33.asm', 'engine/overworld/region_map_lookup.asm',
    'engine/overworld/johto_cave_escape.asm', 'engine/overworld/johto_route33_collision.asm',
    'engine/overworld/player_state.asm', 'engine/special_warps.asm',
    'home/overworld.asm', 'data/warp_tile_ids.asm',
)

class UnionCaveExit192(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.gold = Path(os.environ.get('JOHTO_GOLD_SOURCE', '/missing-gold'))
        if not (cls.gold / 'maps/Route33.asm').exists():
            raise AssertionError('complete Gold reference required')

    def setUp(self):
        self.temp = TemporaryDirectory()
        self.addCleanup(self.temp.cleanup)
        self.root = Path(self.temp.name)
        for rel in FILES:
            f = self.root / rel
            f.parent.mkdir(parents=True, exist_ok=True)
            shutil.copy2(ROOT / rel, f)

    def mutate(self, path, before, after):
        f = self.root / path
        src = f.read_text()
        self.assertIn(before, src)
        f.write_text(src.replace(before, after, 1))
        self.assertNotEqual(audit(self.root, self.gold), [])

    def test_two_mouths_gold_matched(self):
        self.assertEqual(audit(self.root, self.gold), [])

    def test_route33_entry_requires_north_from_11_10(self):
        rel='engine/overworld/johto_route33_collision.asm'
        path=self.root/rel
        raw=path.read_text()
        lead, section=raw.split('JohtoRoute33CanStepAhead::',1)
        body, tail=section.split('JohtoRoute33BlockedRows::',1)
        before='cp PLAYER_DIR_UP\n\tjp z, .allowed'
        self.assertIn(before,body)
        path.write_text(lead+'JohtoRoute33CanStepAhead::'+body.replace(
            before, 'cp PLAYER_DIR_DOWN\n\tjp z, .allowed',1)
            +'JohtoRoute33BlockedRows::'+tail)
        self.assertNotEqual(audit(self.root,self.gold), [])

    def test_wrong_southern_exit_y_is_rejected(self):
        self.mutate('engine/overworld/player_state.asm',
                    'cp 31\n\tjr z, .setCarry', 'cp 30\n\tjr z, .setCarry')

    def test_wrong_cave_warp_slot_is_rejected(self):
        self.mutate('data/mapObjects/JohtoUnionCave1F.asm',
                    'db 31, 17, 0, REGION_WARP_ESCAPE',
                    'db 31, 16, 0, REGION_WARP_ESCAPE')

    def test_wrong_route33_cave_warp_slot_is_rejected(self):
        self.mutate('data/mapObjects/JohtoRoute33.asm',
                    'db 9, 11, 1, REGION_WARP_ESCAPE',
                    'db 9, 11, 0, REGION_WARP_ESCAPE')

    def test_reverse_warp_misrouting_is_rejected(self):
        self.mutate('engine/overworld/region_map_lookup.asm',
                    'db JOHTO_UNION_CAVE_1F_LOCAL_ID, 1, 0, MAP_REGION_JOHTO, JOHTO_ROUTE_33_LOCAL_ID',
                    'db JOHTO_UNION_CAVE_1F_LOCAL_ID, 1, 0, MAP_REGION_JOHTO, JOHTO_ROUTE_32_LOCAL_ID')

    def test_return_state_captured_before_resolver(self):
        self.mutate('engine/overworld/region_map_lookup.asm',
                    'call RecordJohtoCaveEscapeSource\n\tcall StoreNativeWarpTarget',
                    'call StoreNativeWarpTarget\n\tcall RecordJohtoCaveEscapeSource')

    def test_source_requires_exact_route33_map(self):
        self.mutate('engine/overworld/region_map_lookup.asm',
                    'cp JOHTO_ROUTE_33_LOCAL_ID\n\tjp nz, .done',
                    'cp JOHTO_ROUTE_32_LOCAL_ID\n\tjp nz, .done')

    def test_wrong_return_route33_safe_point_is_rejected(self):
        self.mutate('engine/overworld/johto_cave_escape.asm',
                    'FLYWARP_DATA JOHTO_ROUTE_33_WIDTH, 10, 11',
                    'FLYWARP_DATA JOHTO_ROUTE_33_WIDTH, 9, 11')

    def test_blackout_cannot_read_escape_source(self):
        self.mutate('engine/overworld/johto_cave_escape.asm',
                    'and (1 << 3) | (1 << 6)', 'and (1 << 6)')

    def test_cave_cannot_autostep(self):
        self.mutate('engine/overworld/region_map_lookup.asm',
                    'db REGION_NATIVE_MAP_SLOT, JOHTO_ROUTE_33_LOCAL_ID, 9, 11, REGION_NATIVE_MAP_SLOT, D_DOWN',
                    'db REGION_NATIVE_MAP_SLOT, JOHTO_UNION_CAVE_1F_LOCAL_ID, 31, 17, REGION_NATIVE_MAP_SLOT, D_DOWN')

    def test_other_cave_floors_must_stay_sealed(self):
        self.mutate('data/mapObjects/JohtoUnionCave1F.asm',
                    'db $02\n\tdb 3, 17', 'db $03\n\tdb 3, 17')

if __name__=='__main__': unittest.main()
