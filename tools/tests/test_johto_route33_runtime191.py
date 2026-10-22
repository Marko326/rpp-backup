"""R33 native map and collision source constraints with negative variants."""
from pathlib import Path
import os,sys,shutil,unittest
from tempfile import TemporaryDirectory
ROOT=Path(__file__).resolve().parents[2]
sys.path.insert(0,str(ROOT/'tools'))
from johto_route33_runtime191 import audit
FILES=('data/johto_map_headers.asm','constants/map_constants.asm','data/mapHeaders/JohtoAzaleaTown.asm',
       'maps/JohtoAzaleaTown.blk', 'maps/JohtoRoute33.blk','gfx/blocksets/johto_modern.bst',
       'gfx/tilesets/johto_modern.png','gfx/tilesets/johto_modern.tilecoll',
       'color/tilesets/johto_modern.asm','constants/region_map_constants.asm',
       'data/mapHeaders/JohtoRoute32.asm','data/mapHeaders/JohtoRoute33.asm',
       'engine/overworld/region_map_lookup.asm','main.asm',
       'engine/overworld/johto_route33_collision.asm','engine/overworld/johto_east_exterior.asm','home/overworld.asm',
       'engine/overworld/ledges.asm','data/mapObjects/JohtoRoute33.asm',
       'data/tileset_headers.asm','data/collision.asm',
       'engine/menu/start_sub_menus.asm',
       'engine/overworld/map_sprites.asm','engine/town_map.asm',
       'maps/JohtoRoute33.blocked_mask.bin')

class Route33Runtime191(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.gold=Path(os.environ.get('JOHTO_GOLD_SOURCE','/missing-gold'))
        assert (cls.gold/'maps/Route33.blk').is_file(),'Gold source required'
    def setUp(self):
        self.tmp=TemporaryDirectory();self.addCleanup(self.tmp.cleanup)
        self.root=Path(self.tmp.name)
        for name in FILES:
            f=self.root/name;f.parent.mkdir(parents=True,exist_ok=True)
            shutil.copy2(ROOT/name,f)
    def replace(self,file,old,new):
        p=self.root/file;s=p.read_text();self.assertIn(old,s)
        p.write_text(s.replace(old,new,1))
        self.assertTrue(audit(self.root,self.gold))
    def test_exact_gold_assets_and_johto_connection(self):
        self.assertEqual(audit(self.root,self.gold),[])
    def test_route33_sign_cannot_disappear(self):
        # Former staging189-only Gold sign check is now owned by runtime191.
        self.root.joinpath('data/mapObjects/JohtoRoute33.asm').write_text(
            (self.root/'data/mapObjects/JohtoRoute33.asm').read_text().replace(
                'db 11, 11, 1', 'db 11, 10, 1', 1))
        self.assertTrue(audit(self.root, self.gold))

    def test_gold_source_metadata_mutation_is_rejected(self):
        # Prove the migrated Gold-specific check is not just another marker.
        with TemporaryDirectory() as tmp:
            gold = Path(tmp)
            paths = ('maps/Route33.blk', 'maps/Route33.asm',
                     'data/tilesets/johto_modern_metatiles.bin',
                     'data/tilesets/johto_modern_collision.asm',
                     'gfx/tilesets/johto_modern.png',
                     'gfx/tilesets/johto_modern_palette_map.asm',
                     'data/maps/maps.asm', 'data/maps/attributes.asm')
            for rel in paths:
                target = gold / rel
                target.parent.mkdir(parents=True, exist_ok=True)
                shutil.copy2(self.gold / rel, target)
            attrs = gold/'data/maps/attributes.asm'
            data = attrs.read_text()
            expected = 'map_attributes Route33, ROUTE_33, $05, NORTH | WEST'
            self.assertIn(expected, data)
            attrs.write_text(data.replace(expected,
                                          'map_attributes Route33, ROUTE_33, $05, NORTH', 1))
            errors = audit(self.root, gold)
            self.assertTrue(any('source connection metadata changed' in x for x in errors), errors)

    def test_wrong_route33_grass_tile_is_rejected(self):
        self.replace('data/tileset_headers.asm',
                     'JohtoModern_Coll, $FF,$FF,$FF, $04, OUTDOOR',
                     'JohtoModern_Coll, $FF,$FF,$FF, $FF, OUTDOOR')
    def test_route33_fly_permission_missing_is_rejected(self):
        self.replace('engine/menu/start_sub_menus.asm',
                     'cp JOHTO_MODERN\n\tjr z, .canFly',
                     'cp JOHTO_GATE\n\tjr z, .canFly')
    def test_fly_other_outdoor_check_must_remain(self):
        self.replace('engine/menu/start_sub_menus.asm',
                     'call CheckIfInOutsideMap\n\tjr z,.canFly',
                     'xor a ; incorrect global Fly bypass\n\tjr z,.canFly')
    def test_wrong_route32_seam_is_rejected(self):
        self.replace('main.asm','cp 15 ; Gold Route32->Route33 seam: x=0..14 only','cp 20 ; Gold Route32->Route33 seam: x=0..14 only')
    def test_wrong_native_target_is_rejected(self):
        self.replace('engine/overworld/region_map_lookup.asm',
                     'db JOHTO_ROUTE_32_LOCAL_ID, 1, MAP_REGION_JOHTO, JOHTO_ROUTE_33_LOCAL_ID',
                     'db JOHTO_ROUTE_32_LOCAL_ID, 1, MAP_REGION_JOHTO, JOHTO_UNION_CAVE_1F_LOCAL_ID')
    def test_cave_warp_cannot_open(self):
        self.replace('data/mapObjects/JohtoRoute33.asm',
                     'db $01 ; Union Cave 1F entry, explicit native target',
                     'db $00 ; Union Cave 1F entry, explicit native target')
    def test_unsafe_crossbank_jp_cannot_ship(self):
        self.replace('main.asm','callba JohtoRoute33EdgeFence','jp z, JohtoRoute33EdgeFence')
    def test_modern_global_tile_whitelist_disallowed(self):
        (self.root/'gfx/tilesets/johto_modern.tilecoll').write_bytes(b'\x05\xff')
        self.assertTrue(audit(self.root,self.gold))
    def test_missing_left_hop_is_rejected(self):
        self.replace('engine/overworld/ledges.asm','db 9, 11, PLAYER_DIR_LEFT','db 9, 11, PLAYER_DIR_DOWN')
    def test_wrong_modern_crossing_vram_path_is_rejected(self):
        self.replace('home/overworld.asm','cp JOHTO_MODERN\n\tjp z, .route33TilesetReload','cp JOHTO_MODERN\n\tjp z, OverworldLoopLessDelay')
    def test_violet_to_route32_does_not_white_flash(self):
        self.replace('home/overworld.asm',
                     'jr .ordinaryConnection\n.route33TilesetReload',
                     '.route33TilesetReload')
    def test_hop_facing_bits_cannot_be_joypad_mask(self):
        self.replace('engine/overworld/ledges.asm','ld e, D_LEFT','ld e, PLAYER_DIR_LEFT')
    def test_stale_warp_id_must_be_cleared_on_cross_tileset_connection(self):
        self.replace('home/overworld.asm','ld [wDestinationWarpID], a','ld [wUnusedD119], a')

if __name__=='__main__': unittest.main()
