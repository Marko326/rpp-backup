"""Gold-exact three-map sea chain, cross-bank preview and fail-closed entrances."""
import os
import sys
import re
import json
from pathlib import Path
from tempfile import TemporaryDirectory
import unittest
ROOT=Path(__file__).resolve().parents[2]
sys.path.insert(0,str(ROOT/'tools'))
from johto_gold_cells import decode_cells
from johto_indoor_collision_adapter import plan_gold_quadrant_collision
from johto_indoor_common import ConversionError
from johto_rpp_pipeline import stage_adjacent_chain
from johto_rpp_connection_guard import audit_all_active, check_native_connection_preview_abi, check_sea_chain_surf_outer_edge, check_olivine_route40_walk_seam, ConnectionError
from johto_fly_destination_audit import audit as fly_audit
from johto_roof_reference_audit import audit as roof_audit
from johto_rom0_collision_audit import audit as collision_audit

GOLD=Path(os.environ.get('JOHTO_GOLD_SOURCE',os.environ.get('JOHTO_GOLD_ROOT','/missing-gold')))
MAPS={'Route40':(10,18,466),'Route41':(25,27,1699),'CianwoodCity':(15,27,519)}

def water_map(name):
    w,h,_=MAPS[name]
    blocks=(GOLD/'maps'/f'{name}.blk').read_bytes()
    cells=decode_cells(blocks,(GOLD/'data/tilesets/johto_metatiles.bin').read_bytes(),
                      (GOLD/'data/tilesets/johto_collision.asm').read_text(),w,h)
    return {(cell['x'],cell['y']):cell['role'] for cell in cells}


class SeaChain234(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        if not (GOLD/'maps/Route41.blk').is_file():
            raise RuntimeError('Gold source required for sea-chain tests')

    def test_three_maps_are_generated_from_original_gold(self):
        for name,(w,h,nwater) in MAPS.items():
            with self.subTest(map=name):
                expected=(GOLD/'maps'/f'{name}.blk').read_bytes()
                self.assertEqual((ROOT/'maps'/f'Johto{name}.blk').read_bytes(),expected)
                geom,mask=plan_gold_quadrant_collision(GOLD,name,'johto')
                self.assertEqual((ROOT/'maps'/f'Johto{name}.blocked_mask.bin').read_bytes(),mask)
                roles=water_map(name)
                self.assertEqual(sum(v=='WATER' for v in roles.values()),nwater)
                stride=(w*2+7)//8
                actual=(ROOT/'maps'/f'Johto{name}.water_mask.bin').read_bytes()
                self.assertEqual(len(actual),stride*h*2)
                for (x,y),role in roles.items():
                    self.assertEqual(bool(actual[y*stride+x//8] & (1<<(x%8))),role=='WATER')

    def test_only_water_water_seams_can_cross(self):
        oldcity=water_map('Route40'); coast=water_map('Route41'); last=water_map('CianwoodCity')
        gold_olivine={(c['x'],c['y']):c['role'] for c in decode_cells(
           (GOLD/'maps/OlivineCity.blk').read_bytes(),
           (GOLD/'data/tilesets/johto_metatiles.bin').read_bytes(),
           (GOLD/'data/tilesets/johto_collision.asm').read_text(),20,18)}
        for y in range(26,32):
            self.assertEqual((gold_olivine[(0,y)],oldcity[(19,y-18)]),('WATER','WATER'))
        for x in range(2,19):
            self.assertEqual((oldcity[(x,35)],coast[(x+30,0)]),('WATER','WATER'))
        for y in range(1,46):
            self.assertEqual((coast[(0,y)],last[(29,y)]),('WATER','WATER'))

    def test_whirlpool_cave_and_indoor_doors_remain_sealed(self):
        for name in ('Route41','CianwoodCity'):
            w,h,_=MAPS[name]
            role=water_map(name)
            mask=(ROOT/'maps'/f'Johto{name}.blocked_mask.bin').read_bytes()
            stride=(w*2+7)//8
            def blocked(x,y):return bool(mask[y*stride+x//8] & (1<<(x%8)))
            for (x,y),r in role.items():
                if r in ('WHIRLPOOL','CAVE','DOOR'):
                    self.assertTrue(blocked(x,y),(name,x,y,r))
            self.assertIn('db $00', (ROOT/'data/mapObjects'/f'Johto{name}.asm').read_text())
        self.assertEqual(sum(v=='WHIRLPOOL' for v in water_map('Route41').values()),4)

    def test_chain_command_rejects_missing_middle_map(self):
        with TemporaryDirectory() as tmp:
            out=Path(tmp)/'chain'
            with self.assertRaisesRegex(ConversionError,'not a direct bidirectional'):
                stage_adjacent_chain(ROOT,GOLD,out,('Route40','CianwoodCity'))
            self.assertFalse(out.exists())

    def test_gold_chain_converter_stages_three_maps_and_four_seams(self):
        with TemporaryDirectory() as tmp:
            result=stage_adjacent_chain(ROOT,GOLD,Path(tmp)/'chain',tuple(MAPS))
            self.assertEqual(len(result['maps']),3)
            self.assertEqual(len(result['direct_seams']),4)
            self.assertTrue(result['source_geometry_verified'])
            self.assertFalse(result['runtime_approved'])

    def test_active_connections_and_cross_bank_preview_are_guarded(self):
        outcome=audit_all_active(ROOT,GOLD)
        self.assertEqual(outcome['status'],'PASS',outcome['issues']+[x for x in outcome['edges'] if x['status']!='PASS'])
        self.assertEqual(len(outcome['edges']),46)  # original 42 plus reciprocal Route43/Lake seam
        home=(ROOT/'home/overworld.asm').read_text()
        for direction in range(4):
            self.assertIn(f'ld e,{direction}\n callab ResolveNativeConnectionPreviewBank',home)
        self.assertEqual(home.count('callab ResolveNativeConnectionPreviewBank'),4)

    def test_gold_olivine_route40_land_seam_is_reciprocal_and_walkable(self):
        result=check_olivine_route40_walk_seam(ROOT,GOLD)
        self.assertEqual(result['land_rows'],[20,22,23,24,25])
        self.assertEqual(result['water_rows'],list(range(26,32)))

    def test_false_land_airwall_and_illegal_shore_openings_fail(self):
        asm=(ROOT/'engine/overworld/johto_route33_collision.asm').read_text()
        # Each branch is exercised, not just checked for the presence of a label.
        muts=(
            ('olivine edge Y22', ' cp 22\n jr c,.block', ' cp 23\n jr c,.block'),
            ('olivine step Y22', ' cp 22\n jr c,.northRoad', ' cp 23\n jr c,.northRoad'),
            ('route40 edge Y4', ' cp 4\n jr c,.block', ' cp 5\n jr c,.block'),
            ('route40 step Y4', ' cp 4\n jr c,.mask', ' cp 5\n jr c,.mask'),
            ('water must not be walkable', ' cp 26\n jr c,.clear', ' cp 32\n jr c,.clear'),
            ('buoys are not a path', ' cp 14\n jr c,.clear', ' cp 16\n jr c,.clear'),
        )
        for label,old,new in muts:
            with self.subTest(injection=label):
                self.assertIn(old,asm)
                changed=asm.replace(old,new,1)
                with self.assertRaisesRegex(ConnectionError,'seam mismatch'):
                    check_olivine_route40_walk_seam(ROOT,GOLD,collision_source=changed)

    def test_surf_outer_boundary_checked_before_legacy_shore(self):
        self.assertTrue(check_sea_chain_surf_outer_edge(ROOT,GOLD))

    def test_port_lagoon_is_not_the_route40_seam(self):
        from collections import deque
        w=40;h=36
        roles={(c['x'],c['y']):c['role'] for c in decode_cells(
            (GOLD/'maps/OlivineCity.blk').read_bytes(),
            (GOLD/'data/tilesets/johto_metatiles.bin').read_bytes(),
            (GOLD/'data/tilesets/johto_collision.asm').read_text(),20,18)}
        water={pos for pos,role in roles.items() if role=='WATER'}
        port=(22,24);exitpoint=(0,26)
        self.assertIn(port,water)
        self.assertIn(exitpoint,water)
        def reachable(origin):
            seen={origin}; queue=deque([origin])
            while queue:
                x,y=queue.popleft()
                for p in ((x+1,y),(x-1,y),(x,y+1),(x,y-1)):
                    if p in water and p not in seen:
                        seen.add(p);queue.append(p)
            return seen
        # Screen-visible water is not equivalent to a route connection.
        self.assertNotIn(exitpoint,reachable(port))
        self.assertEqual({(0,y) for y in range(26,32)}&water,
                         {(0,y) for y in range(26,32)})

    def test_surf_boundary_guard_fault_injection(self):
        from shutil import copy2
        rels=('home/overworld.asm','engine/overworld/johto_union_cave_surf.asm')
        with TemporaryDirectory() as tmp:
            stage=Path(tmp)
            for rel in rels:
                (stage/rel).parent.mkdir(parents=True,exist_ok=True)
                copy2(ROOT/rel,stage/rel)
            home=stage/rels[0];original=home.read_text()
            for before,after in (
                ('callba IsJohtoSeaChainUnsafeSurfEdge','; dropped edge guard'),
                ('jr c, .collision\n\tld a, [wTileInFrontOfPlayer]',
                 'jr nc, .collision\n\tld a, [wTileInFrontOfPlayer]')):
                home.write_text(original.replace(before,after,1))
                with self.assertRaisesRegex(ConnectionError,'Surf edge guard'):
                    check_sea_chain_surf_outer_edge(stage,GOLD)
            home.write_text(original)
            surf=stage/rels[1];source=surf.read_text()
            surf.write_text(source.replace(
                'cp JOHTO_CIANWOOD_CITY_LOCAL_ID\n jr nz,.clear\n.check',
                'cp JOHTO_ROUTE_42_LOCAL_ID\n jr nz,.clear\n.check',1))
            with self.assertRaisesRegex(ConnectionError,'map whitelist'):
                check_sea_chain_surf_outer_edge(stage,GOLD)

    def test_preview_direction_survives_far_bank_call(self):
        # A is replaced by BANK(callee) in Bankswitch; E is preserved.
        check_native_connection_preview_abi(ROOT)

    def test_preview_abi_fault_injection(self):
        from shutil import copy2
        paths=('home/overworld.asm', 'engine/overworld/region_map_lookup.asm',
               'macros/asm_macros.asm','home.asm')
        with TemporaryDirectory() as tmp:
            root=Path(tmp)
            for rel in paths:
                file=root/rel
                file.parent.mkdir(parents=True,exist_ok=True)
                copy2(ROOT/rel,file)
            home=root/'home/overworld.asm'
            source=home.read_text()
            for old,new in [('ld e,0\n callab ResolveNativeConnectionPreviewBank',
                             'ld a,0\n callab ResolveNativeConnectionPreviewBank'),
                            ('ld e,3\n callab ResolveNativeConnectionPreviewBank',
                             'ld a,3\n callab ResolveNativeConnectionPreviewBank')]:
                home.write_text(source.replace(old,new,1))
                with self.assertRaisesRegex(ConnectionError,'must use E'):
                    check_native_connection_preview_abi(root)
            home.write_text(source)
            resolver=root/'engine/overworld/region_map_lookup.asm'
            original=resolver.read_text()
            resolver.write_text(original.replace(
                'ResolveNativeConnectionPreviewBank::\n ld c,e',
                'ResolveNativeConnectionPreviewBank::\n ld c,a',1))
            with self.assertRaisesRegex(ConnectionError,'clobbers A'):
                check_native_connection_preview_abi(root)

    def test_fly_collision_and_roof_regressions(self):
        self.assertEqual(fly_audit(ROOT,GOLD),[])
        self.assertEqual(roof_audit(ROOT,GOLD),[])
        self.assertEqual(collision_audit(ROOT),[])
        fly=(ROOT/'engine/johto_fly_town_map.asm').read_text()
        self.assertEqual(len(re.findall(r'(?m)^\.selectCianwood\s*$',fly)),1)
        self.assertEqual(len(re.findall(r'(?m)^\.selectOlivine\s*$',fly)),1)
        self.assertEqual(fly.count('call .findForward'),3)
        self.assertNotIn('call .cianwoodName',fly)


if __name__=='__main__': unittest.main()
