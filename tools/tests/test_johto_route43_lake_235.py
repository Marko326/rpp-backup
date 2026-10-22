"""Gold-linked .235 batch: Mahogany north gate -> Route43 -> Lake of Rage.

Use existing project validators and real Gold records. No ROM construction.
"""
import json
import os
import re
import sys
import unittest
from unittest.mock import patch
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
GOLD = Path(os.environ.get('JOHTO_GOLD_SOURCE',
                os.environ.get('JOHTO_GOLD_ROOT', '/missing-Gold')))
sys.path.insert(0, str(ROOT/'tools'))
from johto_rpp_connection_guard import (audit_all_active, map_header_bank,
                                         check_native_connection_preview_abi)
from johto_gatehouse_behavior_audit import audit as gate_audit, predicate, object_warps
from johto_indoor_tiles_converter import build_mapping
from johto_warp_arrival_audit import audit as arrival_audit, profiles
from johto_door_onboarding_audit import audit as door_audit
from johto_region_id_audit import audit as region_audit
from johto_roof_reference_audit import audit as roof_audit
from johto_rom0_collision_audit import audit as collision_audit
from johto_fly_destination_audit import audit as fly_audit
from johto_gate_rgb_audit import verify as gate_rgb
from johto_gate_audit import verify_gold_gate_palette_map
from johto_map_release_audit import (audit_new_native_map_signs,
                                    audit_new_native_field_move_roles)
from johto_gold_cells import decode_cells

GATE='JOHTO_ROUTE_43_MAHOGANY_GATE_LOCAL_ID'
ROUTE='JOHTO_ROUTE_43_LOCAL_ID'
TOWN='JOHTO_MAHOGANY_TOWN_LOCAL_ID'
LAKE='JOHTO_LAKE_OF_RAGE_LOCAL_ID'

class Route43Lake235(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        if not (GOLD/'maps/Route43MahoganyGate.asm').is_file():
            raise RuntimeError('JOHTO_GOLD_SOURCE full original Gold required')
        cls.gates=json.loads((ROOT/'tools/johto_door_contracts.json').read_text())
        cls.gate=next(x for x in cls.gates['active_warp_maps']
                      if x['rpp_map']=='JohtoRoute43MahoganyGate')
        cls.collision=(ROOT/'engine/overworld/johto_route33_collision.asm').read_text()
        cls.lookup=(ROOT/'engine/overworld/region_map_lookup.asm').read_text()

    def test_four_lane_gold_warp_and_native_routes(self):
        self.assertEqual(door_audit(ROOT,GOLD)[0],[])
        warps=object_warps((ROOT/'data/mapObjects/JohtoRoute43MahoganyGate.asm').read_text(),
                           'JohtoRoute43MahoganyGate')
        self.assertEqual({(y,x) for y,x,_,_ in warps}, {(0,4),(0,5),(7,4),(7,5)})
        self.assertEqual(len(self.gate['gatehouse_runtime']['native_routes']),7)
        for origin,src_idx,dst_idx,dest in self.gate['gatehouse_runtime']['native_routes']:
            token=f'db {origin}, {src_idx}, {dst_idx}, MAP_REGION_JOHTO, {dest}'
            self.assertIn(token,self.lookup)
        self.assertEqual((ROOT/'maps/JohtoRoute43.blk').read_bytes(),
                         (GOLD/'maps/Route43.blk').read_bytes())
        self.assertEqual((ROOT/'maps/JohtoLakeOfRage.blk').read_bytes(),
                         (GOLD/'maps/LakeOfRage.blk').read_bytes())

    def test_four_direction_runtime_predicate(self):
        cases=[(TOWN,9,1,'UP','STEP_ON'),
               (ROUTE,9,51,'DOWN','COLLISION_ONLY'),
               (ROUTE,10,51,'DOWN','COLLISION_ONLY')]
        cases += [(GATE,x,y,d,trigger)
                  for y,d,trigger in ((0,'UP','STEP_ON'),(7,'DOWN','COLLISION_ONLY'))
                  for x in (4,5)]
        for symbol,x,y,wanted,mode in cases:
            for d in ('UP','DOWN','LEFT','RIGHT'):
                self.assertEqual(predicate(self.collision,
                    'JohtoGateCollisionDirectionAllowed',symbol,x,y,d),d==wanted,
                    (symbol,x,y,d))
                self.assertEqual(predicate(self.collision,
                    'JohtoNorthGateStepWarpAllowed',symbol,x,y,d),
                    d==wanted and mode=='STEP_ON',(symbol,x,y,d))
        self.assertEqual(gate_audit(ROOT,GOLD),[])

    def test_immediate_return_warp_arrival_safe(self):
        self.assertEqual(arrival_audit(ROOT,GOLD),[])
        actual={(local,y,x):d for _,local,y,x,_,d in profiles(self.lookup)}
        # Outside paired collision-only carpet: stay on it for immediate DOWN
        # reentry. This is different from a solid doorway landing in Mahogany.
        for x in (9,10):
            self.assertNotIn((ROUTE,51,x),actual)
        self.assertEqual(actual[(TOWN,1,9)],'D_DOWN')
        for x in (4,5):self.assertEqual(actual[(GATE,0,x)],'D_DOWN')
        for mapname,w,dims in (('Route43',20,(9,50)),('Route43MahoganyGate',10,(4,1)),
                               ('MahoganyTown',20,(9,2))):
            x,y=dims
            data=(ROOT/f'maps/Johto{mapname}.blocked_mask.bin').read_bytes()
            self.assertFalse(data[y*((w+7)//8)+x//8]&(1<<(x%8)),(mapname,x,y))
        anchor = ' ; Outside Route43 gate\'s paired COLLISION_ONLY carpets (9/10,51)'
        self.assertEqual(self.lookup.count(anchor),1)
        source=self.lookup.replace(anchor,
            ' db REGION_NATIVE_MAP_SLOT, JOHTO_ROUTE_43_LOCAL_ID, 51, 9, REGION_NATIVE_MAP_SLOT, D_UP\n' + anchor)
        self.assertNotEqual(source,self.lookup)
        self.assertTrue(gate_audit(ROOT,GOLD,overrides={
            'engine/overworld/region_map_lookup.asm':source}))

    def test_north_west_preview_and_openings_execute_as_gold(self):
        from johto_rpp_connection_guard import audit as connection_audit
        result=connection_audit(ROOT,GOLD,'JohtoRoute43','JohtoLakeOfRage',
                                'Route43','LakeOfRage','north')
        self.assertEqual(result['status'],'PASS',result)
        self.assertEqual(result['overlap']['visual_left_border'],3)
        self.assertEqual(result['overlap']['visual_right_border'],0)
        self.assertEqual(result['overlap']['source_columns'],[5,14])
        self.assertEqual(result['overlap']['dest_columns'],[0,9])
        self.assertEqual(result['actual']['width'],13)
        self.assertEqual(result['actual']['source_start']%20,2)
        self.assertEqual(result['actual']['dest_start']%(10+6),0)
        registry=json.loads((ROOT/'tools/johto_native_maps.json').read_text())
        route=next(item for item in registry['maps'] if item['header']=='JohtoRoute43_h')
        self.assertEqual(route['north_connection_exit_x_tiles'],[0,8,9,10,11])

    def test_map_bank_budget_and_native_cross_bank_preview(self):
        # .234 MAP: $40 slack was only 156 bytes. Newly added full maps cannot
        # share it. The existing $45 bank has room for both contiguous maps.
        self.assertEqual(map_header_bank(ROOT, 'JohtoMahoganyTown'), 0x40)
        self.assertEqual(map_header_bank(ROOT, 'JohtoRoute43'), 0x45)
        self.assertEqual(map_header_bank(ROOT, 'JohtoLakeOfRage'), 0x45)
        main = (ROOT/'main.asm').read_text()
        self.assertIn('SECTION "Johto Town Map Artwork", ROMX, BANK[$45]', main)
        town_map = (ROOT/'engine/town_map.asm').read_text()
        for symbol in ('JohtoTownMapTileGraphics', 'JohtoTownMapTilemap'):
            self.assertIn('BANK('+symbol+')', town_map)
        self.assertGreaterEqual(town_map.count('call FarCopyData2'), 3)
        check_native_connection_preview_abi(ROOT)
        result = audit_all_active(ROOT, GOLD)
        self.assertEqual(result['status'], 'PASS', result)
        for start, target in (('JohtoMahoganyTown', 'JohtoRoute43'),
                              ('JohtoRoute43', 'JohtoMahoganyTown')):
            self.assertIn((start, target), {(e['current'], e['target'])
                for e in result['edges'] if e['status']=='PASS'})

    def test_wrong_cross_bank_map_placement_is_rejected(self):
        from johto_rpp_connection_guard import map_header_bank as actual_bank
        # Fault injection: a future split of Route43/Lake into two banks must
        # not accidentally pass because the Mahogany/Route43 seam is allowed.
        def misplaced(project, name):
            return 0x44 if name == 'JohtoLakeOfRage' else actual_bank(project, name)
        with patch('johto_rpp_connection_guard.map_header_bank', side_effect=misplaced):
            report = audit_all_active(ROOT, GOLD)
        self.assertEqual(report['status'], 'FAIL')
        self.assertTrue(any('ROM bank mismatch' in issue
                for item in report['edges'] for issue in item.get('issues', [])), report)

    def test_actual_46_gold_road_connections(self):
        result=audit_all_active(ROOT,GOLD)
        self.assertEqual(result['status'],'PASS',result)
        self.assertEqual(len(result['edges']),56)  # Four Gold exterior maps add ten directed joins
        actual={(e['current'],e['target'],e['direction'])
                 for e in result['edges'] if e['status']=='PASS'}
        self.assertTrue({('JohtoMahoganyTown','JohtoRoute43','north'),
            ('JohtoRoute43','JohtoMahoganyTown','south'),
            ('JohtoRoute43','JohtoLakeOfRage','north'),
            ('JohtoLakeOfRage','JohtoRoute43','south')} <= actual)
        self.assertEqual(region_audit(ROOT),[])

    def test_indoor_neutral_name(self):
        asm=(ROOT/'engine/overworld/map_name_sign.asm').read_text()
        self.assertRegex(asm,r'cp JOHTO_ROUTE_43_MAHOGANY_GATE_LOCAL_ID\s+ret z')
        self.assertNotRegex(asm,r'cp JOHTO_ROUTE_43_LOCAL_ID\s+ret z')
        self.assertNotRegex(asm,r'cp JOHTO_LAKE_OF_RAGE_LOCAL_ID\s+ret z')
        self.assertEqual(audit_new_native_map_signs(ROOT,GOLD),[])

    def test_gate_gold_shared_layout_and_palette(self):
        mapping,blocks=build_mapping(ROOT,GOLD,'Route43MahoganyGate','gate','johto_gate')
        self.assertEqual((ROOT/'maps/JohtoRoute43MahoganyGate.blk').read_bytes(),blocks)
        self.assertEqual(mapping['exact_mapped'],mapping['used_unique_blocks'])
        self.assertEqual(verify_gold_gate_palette_map(ROOT,GOLD),[])
        self.assertEqual(roof_audit(ROOT,GOLD),[])

    def test_gate_rgb_preserves_old_assets(self):
        self.assertEqual(gate_rgb(ROOT,GOLD),[])
        self.assertEqual(gate_audit(ROOT,GOLD),[])
        self.assertIn('callba PatchJohtoMapBordersAfterBlockLoad',
                      (ROOT/'home/overworld.asm').read_text())

    def test_prior_gate_contracts_still_pass(self):
        self.assertEqual(gate_audit(ROOT,GOLD),[])
        self.assertEqual(door_audit(ROOT,GOLD)[0],[])
        self.assertEqual(collision_audit(ROOT),[])

    def test_road_lake_gold_water_cut_and_deferred_headbutt(self):
        self.assertEqual(audit_new_native_field_move_roles(ROOT,GOLD),[])
        m=json.loads((ROOT/'tools/johto_native_maps.json').read_text())['maps']
        for n,expected_water,expected_cut in [('Route43',72,1),('LakeOfRage',300,5)]:
            data=next(r for r in m if r['header']==f'Johto{n}_h')
            self.assertEqual(data['feature_status']['cut'],'ALLOWED')
            self.assertEqual(data['feature_status']['surf'],'ALLOWED')
            w,h={'Route43':(10,27),'LakeOfRage':(20,18)}[n]
            cells=decode_cells((GOLD/'maps'/f'{n}.blk').read_bytes(),
                (GOLD/'data/tilesets/johto_metatiles.bin').read_bytes(),
                (GOLD/'data/tilesets/johto_collision.asm').read_text(),w,h)
            self.assertEqual(sum(c['role']=='WATER' for c in cells),expected_water)
            self.assertEqual(sum(c['role']=='CUT_TREE' for c in cells),expected_cut)
            self.assertEqual(data['deferred_gold_moves']['headbutt_tree_yx'],
                    [[c['y'],c['x']] for c in cells if c['role']=='HEADBUTT_TREE'])


    def test_235b_gold_floor_masks_have_no_hidden_walls_across_three_maps(self):
        # Independently audit ALL 960 Gold FLOOR cells, not just the seam lanes.
        # Do not auto-open DOOR, HEADBUTT_TREE, or WATER with this land check.
        metatiles=(GOLD/'data/tilesets/johto_metatiles.bin').read_bytes()
        collision=(GOLD/'data/tilesets/johto_collision.asm').read_text()
        examined_floor=0
        for name,w,h in (('MahoganyTown',20,18),('Route43',20,54),
                         ('LakeOfRage',40,36)):
            cells=decode_cells((GOLD/'maps'/f'{name}.blk').read_bytes(),
                               metatiles,collision,w//2,h//2)
            mask=(ROOT/'maps'/f'Johto{name}.blocked_mask.bin').read_bytes()
            stride=(w+7)//8
            def mismatches(mask_bytes):
                wrong=[]
                for cell in cells:
                    role=cell['role'];x=cell['x'];y=cell['y']
                    bit=bool(mask_bytes[y*stride+x//8]&(1<<(x%8)))
                    if role in ('FLOOR','TALL_GRASS') and bit:
                        wrong.append((x,y,'hidden_wall',role))
                    if role in ('WALL','UP_WALL','HEADBUTT_TREE','CUT_TREE') and not bit:
                        wrong.append((x,y,'opened_solid',role))
                return wrong
            self.assertEqual(mismatches(mask),[],name)
            examined_floor+=sum(c['role']=='FLOOR' for c in cells)
            if name=='Route43':
                # Fault injection: add an invisible wall to the original west
                # corridor while keeping map blocks and seam tables untouched.
                west=next(c for c in cells if c['x']==0 and c['y']==1)
                self.assertEqual(west['role'],'FLOOR')
                tampered=bytearray(mask)
                tampered[stride*1] |= 1
                self.assertIn((0,1,'hidden_wall','FLOOR'),mismatches(tampered))
        self.assertEqual(examined_floor,960)

    def test_235b_mahogany_gate_arrival_is_physically_walkable(self):
        # A registered Warp is insufficient when the Gold DOOR is masked.
        from johto_masked_step_audit import parse_caller, trace_masked_step
        source=self.collision
        mask=(ROOT/'maps/JohtoMahoganyTown.blocked_mask.bin').read_bytes()
        gold=decode_cells((GOLD/'maps/MahoganyTown.blk').read_bytes(),
            (GOLD/'data/tilesets/johto_metatiles.bin').read_bytes(),
            (GOLD/'data/tilesets/johto_collision.asm').read_text(),10,9)
        roles={(c['x'],c['y']):c['role'] for c in gold}
        self.assertEqual([roles[(9,2)],roles[(9,1)],roles[(9,0)]],
                         ['FLOOR','DOOR','WALL'])
        # Original DOOR remains masked: only the exact approach is allowed.
        self.assertTrue(mask[1*3+9//8] & (1<<(9%8)))
        def blocked(src,x,y,d):
            program,labels=parse_caller(src,'JohtoMahoganyTownCanStepAhead')
            return trace_masked_step(program,labels,mask,20,18,TOWN,x,y,d)[0]
        self.assertFalse(blocked(source,9,2,'UP'))
        self.assertTrue(blocked(source,9,1,'UP'))  # Solid roof beyond the step-on Warp
        self.assertTrue(blocked(source,8,2,'UP'))  # No open house wall beside door
        self.assertFalse(blocked(source,9,1,'DOWN'))
        home=(ROOT/'home/overworld.asm').read_text()
        ids={}
        for name in ('constants/region_map_constants.asm','constants/johto_fixed_map_ids.asm'):
            ids.update({key:int(val) for key,val in re.findall(
                r'(?m)^DEF\s+(JOHTO_[A-Z0-9_]+_LOCAL_ID)\s+EQU\s+(\d+)',
                (ROOT/name).read_text())})
        # The HOME Johto selector dispatches the Gold DOOR to native step-on
        # logic on the FIRST approach move, not a second UP collision.
        self.assertTrue(predicate(home,'IsJohtoSouthGatePortal',TOWN,9,1,'UP',ids))
        self.assertFalse(predicate(home,'IsJohtoSouthGatePortal',TOWN,9,1,'UP',ids,
                                   region='MAP_REGION_KANTO'))
        self.assertTrue(predicate(source,'JohtoInternalDoorFacingCheck',TOWN,9,1,'UP'))
        self.assertTrue(predicate(source,'JohtoNorthGateStepWarpAllowed',TOWN,9,1,'UP'))
        self.assertTrue(predicate(source,'JohtoGateCollisionDirectionAllowed',TOWN,9,1,'UP'))
        self.assertFalse(predicate(source,'JohtoGateCollisionDirectionAllowed',TOWN,9,1,'DOWN'))
        # Fault injection: restore the old missing mouth exception or remove
        # the HOME selector. Both were previously invisible to 831 green tests.
        mutated=source.replace(' cp 9\n jr nz, .westSeam\n ld a, [wYCoord]',
                               ' cp 8\n jr nz, .westSeam\n ld a, [wYCoord]',1)
        self.assertNotEqual(mutated,source)
        self.assertTrue(blocked(mutated,9,2,'UP'))
        bad_home=home.replace('\tjr z, .yes\n\tcp JOHTO_ROUTE_43_MAHOGANY_GATE_LOCAL_ID',
                              '\tjr nz, .yes\n\tcp JOHTO_ROUTE_43_MAHOGANY_GATE_LOCAL_ID',1)
        self.assertNotEqual(bad_home,home)
        self.assertFalse(predicate(bad_home,'IsJohtoSouthGatePortal',TOWN,9,1,'UP',ids))

    def test_235d_single_gold_door_first_step_warps_without_second_up(self):
        # Gold's single DOOR x9/y1 is not Route43's paired carpet: entering
        # from y2 must be one UP move + immediate native Warp recognition.
        from johto_masked_step_audit import parse_caller, trace_masked_step
        from johto_gatehouse_behavior_audit import gold_solid_north_door_errors
        gate = self.gate['gatehouse_runtime']
        town = next(a for a in gate['approaches'] if a['map_local']==TOWN)
        self.assertEqual((town['x'],town['y'],town['direction'],town['trigger']),
                         (9,1,'UP','STEP_ON'))
        self.assertEqual(gold_solid_north_door_errors(ROOT,GOLD,[self.gate]),[])
        asm,labels=parse_caller(self.collision,'JohtoMahoganyTownCanStepAhead')
        mask=(ROOT/'maps/JohtoMahoganyTown.blocked_mask.bin').read_bytes()
        self.assertFalse(trace_masked_step(asm,labels,mask,20,18,TOWN,9,2,'UP')[0])
        self.assertTrue(predicate(self.collision,'JohtoNorthGateStepWarpAllowed',
                                  TOWN,9,1,'UP'))
        for d in ('DOWN','LEFT','RIGHT'):
            self.assertFalse(predicate(self.collision,'JohtoNorthGateStepWarpAllowed',
                                       TOWN,9,1,d))
        home=(ROOT/'home/overworld.asm').read_text()
        self.assertIn('callba JohtoNorthGateStepWarpAllowed',
                      home.split('CheckWarpsNoCollisionLoop::',1)[1].split('CheckWarpsCollision::',1)[0])
        self.assertIn('jp c, WarpFound1',
                      home.split('CheckWarpsNoCollisionLoop::',1)[1].split('CheckWarpsCollision::',1)[0])
        self.assertEqual(gate_audit(ROOT,GOLD),[])

    def test_235d_self_consistent_wrong_door_contract_fails_gold_reference(self):
        # Reproduce the exact .235C false-green: both ASM and JSON claim the
        # Gold solid door is collision-only. Gold input must reject BOTH.
        import copy
        manifest=copy.deepcopy(self.gates)
        gate=next(a for a in manifest['active_warp_maps']
                  if a['rpp_map']=='JohtoRoute43MahoganyGate')
        approach=next(a for a in gate['gatehouse_runtime']['approaches']
                      if a['map_local']==TOWN)
        approach['trigger']='COLLISION_ONLY'
        src=self.collision
        target=('\tcp JOHTO_MAHOGANY_TOWN_LOCAL_ID\n'
                '\tjr z, .mahoganyNorthDoor\n')
        self.assertEqual(src.count(target),1)
        damaged=src.replace(target,'',1)
        self.assertFalse(predicate(damaged,'JohtoNorthGateStepWarpAllowed',
                                   TOWN,9,1,'UP'))
        errors=gate_audit(ROOT,GOLD,
            overrides={'engine/overworld/johto_route33_collision.asm':damaged},
            manifest=manifest)
        self.assertTrue(any('Gold single solid DOOR' in msg and
                            'must be STEP_ON' in msg for msg in errors),errors)

    def test_235b_every_gold_floor_seam_lane_runs_both_collision_layers(self):
        # Require all five independent Gold lanes through both guards.
        from johto_masked_step_audit import parse_caller, trace_masked_step
        gold_roles={}
        for mapname,w,h in (('Route43',10,27),('LakeOfRage',20,18)):
            gold_roles[mapname]={(c['x'],c['y']):c['role'] for c in decode_cells(
                (GOLD/f'maps/{mapname}.blk').read_bytes(),
                (GOLD/'data/tilesets/johto_metatiles.bin').read_bytes(),
                (GOLD/'data/tilesets/johto_collision.asm').read_text(),w,h)}
        golden={x for x in range(20) if gold_roles['Route43'][(x,0)]=='FLOOR'
                    and gold_roles['LakeOfRage'][(x+10,35)]=='FLOOR'}
        self.assertEqual(golden,{0,8,9,10,11})
        # Independently from both masks and ASM, validate the Gold approach
        # from one cell inside each map (prevents opening unreachable edges).
        for x in golden:
            self.assertEqual(gold_roles['Route43'][(x,1)],'FLOOR')
            self.assertEqual(gold_roles['LakeOfRage'][(x+10,34)],'FLOOR')
        for name,width,height,edge_y,direction,local,shift in (
            ('Route43',20,54,0,'UP',ROUTE,0),
            ('LakeOfRage',40,36,35,'DOWN',LAKE,10)):
            mask=(ROOT/f'maps/Johto{name}.blocked_mask.bin').read_bytes()
            def audit_source(src):
                mismatches=[]
                for suffix in ('EdgeFence','CanStepAhead'):
                    prog,labels=parse_caller(src,'Johto'+name+suffix)
                    for x in range(20):
                        actual_blocked,_=trace_masked_step(
                            prog,labels,mask,width,height,local,x+shift,edge_y,
                            direction,gold_cut_cells=set())
                        expected_allowed=x in golden
                        if actual_blocked==expected_allowed:
                            mismatches.append((suffix,x,'blocked' if actual_blocked else 'allowed'))
                return mismatches
            self.assertEqual(audit_source(self.collision),[],name)
            # Inject the former missing west branch into either executor.
            if name=='Route43':
                for old,new in ((' and a\n jr z, .clear\n cp 8',
                                 ' and a\n jr nz, .clear\n cp 8'),
                                (' and a\n jp z,.allowed\n cp 8',
                                 ' and a\n jp nz,.allowed\n cp 8')):
                    self.assertEqual(1,self.collision.count(old),
                                     ('fault-injection anchor must match exactly once',name,old))
                    faulty=self.collision.replace(old,new,1)
                    self.assertNotEqual(faulty,self.collision,'fault injection must change source')
                    self.assertTrue(audit_source(faulty),('missing fault',name,old))
            else:
                for old,new in ((' cp 10\n jr z,.clear\n cp 18',
                                 ' cp 10\n jr nz,.clear\n cp 18'),
                                (' cp 10\n jr z,.allowed\n cp 18',
                                 ' cp 10\n jr nz,.allowed\n cp 18')):
                    self.assertEqual(1,self.collision.count(old),
                                     ('fault-injection anchor must match exactly once',name,old))
                    faulty=self.collision.replace(old,new,1)
                    self.assertNotEqual(faulty,self.collision,'fault injection must change source')
                    self.assertTrue(audit_source(faulty),('missing fault',name,old))

    def test_235b_left_west_road_is_truly_connected_to_lake_shore(self):
        # West x0 corridor from south gate and the lake shore must connect.
        # This is not the same path as the four open lanes east of the trees.
        from collections import deque
        def reachable(name,w,h,seed,goal):
            mask=(ROOT/f'maps/Johto{name}.blocked_mask.bin').read_bytes()
            stride=(w+7)//8
            allowed=lambda x,y:0<=x<w and 0<=y<h and not bool(
                mask[y*stride+x//8]&(1<<(x%8)))
            self.assertTrue(allowed(*seed))
            self.assertTrue(allowed(*goal))
            seen={seed};todo=deque([seed])
            while todo:
                x,y=todo.popleft()
                for nx,ny in ((x-1,y),(x+1,y),(x,y-1),(x,y+1)):
                    if (nx,ny) not in seen and allowed(nx,ny):
                        seen.add((nx,ny));todo.append((nx,ny))
            self.assertIn(goal,seen,(name,seed,goal))
        reachable('Route43',20,54,(9,50),(0,0))
        reachable('LakeOfRage',40,36,(10,35),(10,34))
        reachable('LakeOfRage',40,36,(20,35),(20,34))

    def test_lake_fly_and_identity(self):
        self.assertEqual(fly_audit(ROOT,GOLD),[])
        self.assertIn('FLYWARP_DATA JOHTO_LAKE_OF_RAGE_WIDTH, 29, 21',
                      (ROOT/'engine/fly_town_map_helpers.asm').read_text())
        self.assertIn('ASSERT EVENT_JOHTO_FLY_LAKE_OF_RAGE == $44c',
                      (ROOT/'constants/event_constants.asm').read_text())

if __name__=='__main__': unittest.main()
