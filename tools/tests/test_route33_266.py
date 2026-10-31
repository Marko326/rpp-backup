"""Gold-backed stage-266 regression, with isolated failure mutations."""
from pathlib import Path
import os, shutil, sys, tempfile, unittest
from PIL import Image
ROOT=Path(__file__).resolve().parents[2]
sys.path.insert(0,str(ROOT/'tools'))
from johto_route33_266_audit import audit
GOLD=Path(os.getenv('GOLD_SOURCE_ROOT') or os.getenv('JOHTO_GOLD_SOURCE') or '/__missing__')
REQUIRED=(
 'maps/johto_pilot/Route33.gold.blk','maps/johto_pilot/Route33.runtime.blk',
 'maps/johto_pilot/Route33.blocked_mask.bin','gfx/blocksets/johto_modern.bst',
 'gfx/tilesets/johto_modern.png','gfx/tilesets/johto_modern.tilecoll',
 'color/tilesets/johto_modern.asm','data/johto_route33_runtime.asm',
 'data/johto_union_cave_runtime.asm','engine/johto_pilot_runtime.asm',
 'engine/overworld/ledges.asm','engine/johto_land_collision_gateway_272.asm','data/tileset_headers.asm',
 'data/bike_riding_tilesets.asm','home/overworld.asm',
)
@unittest.skipUnless(GOLD.is_dir(),'Gold reference required')
class Route33Stage266(unittest.TestCase):
    def test_current_gold_assets_and_two_way_portal(self):
        report=audit(ROOT,GOLD)
        self.assertEqual('PASS_STATIC_ONLY',report['status'],report['errors'])
        self.assertGreaterEqual(len(report['checks']),15)
        self.assertFalse(report['rom_built'])
        self.assertFalse(report['phone_accepted'])
    def test_failure_injection_rejects_four_independent_regressions(self):
        with tempfile.TemporaryDirectory() as tmp:
            dst=Path(tmp)
            for rel in REQUIRED:
                p=dst/rel;p.parent.mkdir(parents=True,exist_ok=True);shutil.copyfile(ROOT/rel,p)
            scenarios=[
             ('south_wrong_ordinal','data/johto_union_cave_runtime.asm',b'db 31, 17, 0, JOHTO_REGISTERED_WARP_SELECTOR',b'db 31, 17, 2, JOHTO_REGISTERED_WARP_SELECTOR','south_cave_warp'),
             ('wrong_terrain','maps/johto_pilot/Route33.blocked_mask.bin',None,None,'full_gold_terrain_collision'),
             ('wrong_png_source','gfx/tilesets/johto_modern.png',None,None,'gold_tileset_png_source'),
             ('unregistered_return','engine/johto_pilot_runtime.asm',b'db MAP_REGION_JOHTO, JOHTO_ROUTE_33_LOCAL_ID, 0, MAP_REGION_JOHTO, JOHTO_UNION_CAVE_1F_LOCAL_ID',b'db MAP_REGION_JOHTO, JOHTO_ROUTE_33_LOCAL_ID, 1, MAP_REGION_JOHTO, JOHTO_UNION_CAVE_1F_LOCAL_ID','route33_to_south'),
             ('wrong_ledge_direction','engine/overworld/ledges.asm',b'db 9, 10, PLAYER_DIR_LEFT',b'db 9, 10, PLAYER_DIR_DOWN','all_and_only_directed_gold_hops'),
            ]
            for tag,rel,old,new,expected in scenarios:
                with self.subTest(tag=tag):
                    p=dst/rel;src=p.read_bytes()
                    if tag=='wrong_png_source':
                        image=Image.open(p).convert('RGB')
                        pixel=image.getpixel((0,0))
                        colors=[color for _,color in image.getcolors(image.width*image.height) if color!=pixel]
                        self.assertTrue(colors)
                        image.putpixel((0,0),colors[0]);image.save(p)
                        modified=p.read_bytes()
                    elif old is None:
                        data=bytearray(src);data[3]^=1;modified=bytes(data)
                    else:
                        self.assertIn(old,src);modified=src.replace(old,new,1)
                    p.write_bytes(modified)
                    result=audit(dst,GOLD)
                    self.assertEqual('FAIL',result['status'],(tag,result))
                    self.assertTrue(any(x['name']==expected and x['result']=='FAIL' for x in result['checks']), (tag,result))
                    p.write_bytes(src)
if __name__=='__main__':unittest.main()
