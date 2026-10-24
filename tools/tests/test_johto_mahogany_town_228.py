"""ID64: Gold-exact Mahogany / Fly / ledge; static negative regression."""
import json, os, sys, unittest, re, shutil
from tempfile import TemporaryDirectory
from pathlib import Path
ROOT=Path(__file__).resolve().parents[2]
GOLD=Path(os.environ.get('JOHTO_GOLD_SOURCE','/missing-gold'))
sys.path.insert(0,str(ROOT/'tools'))
from johto_fly_destination_audit import audit as fly_audit
from ledge_regression_audit import audit as ledge_audit, coordinate_hops, expected_gold_hops
from johto_rpp_connection_guard import audit_all_active
from johto_region_id_audit import audit as region_audit, INPUTS as REGION_INPUTS
from johto_gold_cells import decode_cells
class Mahogany228(unittest.TestCase):
    def test_exact_gold_city_tiles_and_twenty_eight_active_slots(self):
        self.assertEqual((ROOT/'maps/JohtoMahoganyTown.blk').read_bytes(),(GOLD/'maps/MahoganyTown.blk').read_bytes())
        maps=json.loads((ROOT/'tools/johto_native_maps.json').read_text())['maps']
        self.assertEqual(len(maps),49)  # east slots 41..44, gate 45 and Olivine houses 46..48
        self.assertEqual(maps[27]['local_id'],64)
        # JohtoActiveLocalIDs assigns compact slot 27 after the west 23/24 and east 62/63.
        index=(ROOT/'data/johto_map_headers.asm').read_text()
        self.assertIn('dw JohtoMahoganyTown_h ; stable $40 -> slot $1b',index)
    def test_exact_twelve_ledge_actions(self):
        self.assertEqual(coordinate_hops((ROOT/'engine/overworld/ledges.asm').read_text(),'.mahoganyHops'),expected_gold_hops(GOLD,'MahoganyTown','johto'))
        self.assertEqual(ledge_audit(ROOT,GOLD)['errors'],[])
    def test_bidirectional_east_west_and_bounded_edges(self):
        result=audit_all_active(ROOT,GOLD)
        self.assertEqual(result['status'],'PASS',result.get('issues'))
        valid={(e['current'],e['target'],e['direction']) for e in result['edges'] if e['status']=='PASS'}
        self.assertIn(('JohtoRoute42','JohtoMahoganyTown','east'),valid)
        self.assertIn(('JohtoMahoganyTown','JohtoRoute42','west'),valid)
    def test_city_fly_destination_is_real_not_deferred(self):
        self.assertEqual(fly_audit(ROOT,GOLD),[])
        events=(ROOT/'constants/event_constants.asm').read_text()
        self.assertIn('ASSERT EVENT_JOHTO_FLY_MAHOGANY == $451',events)
        name=(ROOT/'engine/overworld/map_name_sign.asm').read_text()
        self.assertNotIn('cp JOHTO_MAHOGANY_TOWN_LOCAL_ID\n\tret z',name)
    def test_all_native_current_markers_match_saved_normal_locations(self):
        # This compares the actual 45-entry browse landmark against the
        # active-slot marker, not only two tables against the same wrong JSON.
        self.assertEqual(region_audit(ROOT), [])
        part=(ROOT/'engine/overworld/johto_town_map_helpers.asm').read_text().split('JohtoNativeTownMapIndices::',1)[1].split('JohtoNativeTownMapIndicesEnd::',1)[0]
        indices=[int(n) for row in re.findall(r'(?m)^\s*db\s+([\d, ]+)',part) for n in row.split(',')]
        self.assertEqual(len(indices),49)  # stable Mahogany 27; Olivine House1 family slots 46..48
        self.assertEqual(indices[18],17)  # older Route35 gate mistakenly National Park
        self.assertEqual(indices[27],34)  # Mahogany was mistakenly Mt. Mortar
        self.assertEqual(indices[26],32)  # Route42 must NOT be changed

    def test_correlated_wrong_manifest_and_runtime_marker_is_still_detected(self):
        # Previous gate only compared each table to its JSON mirror and could
        # incorrectly PASS if the mirror repeated the exact same wrong index.
        with TemporaryDirectory() as t:
            p=Path(t)
            for rel in REGION_INPUTS:
                out=p/rel
                out.parent.mkdir(parents=True,exist_ok=True)
                shutil.copyfile(ROOT/rel,out)
            mapper=p/'engine/overworld/johto_town_map_helpers.asm'
            text=mapper.read_text()
            self.assertIn(', 32, 32, 34, 25, 26, 28, 30, 31 ;',text)
            mapper.write_text(text.replace(', 32, 32, 34, 25, 26, 28, 30, 31 ;',', 32, 32, 33, 25, 26, 28, 30, 31 ;',1))
            manifest=p/'tools/johto_native_maps.json'
            data=json.loads(manifest.read_text())
            data['maps'][27]['town_map_index']=33
            manifest.write_text(json.dumps(data))
            self.assertTrue(any('slot 27 current Town Map marker mismatch' in x
                         for x in region_audit(p)),region_audit(p))

    def test_route42_to_mahogany_both_direction_gold_walkable_seam(self):
        collision=(ROOT/'engine/overworld/johto_route33_collision.asm').read_text()
        # Validate the four executable paths with the complete natural seam,
        # not a misleading y14..17-only subset.
        parts={name:collision.split(name+'::',1)[1].split('::',1)[0]
               for name in ('JohtoRoute42EdgeFence','JohtoRoute42CanStepAhead',
                            'JohtoMahoganyTownEdgeFence','JohtoMahoganyTownCanStepAhead')}
        for name,body in parts.items():
            numbers=[int(n) for n in re.findall(r'(?m)^\s*cp (\d+)\s*$',body)]
            for threshold in (4,8,9,18):
                self.assertIn(threshold,numbers,(name,threshold))
            if name.startswith('JohtoMahoganyTown'):
                # The Route44 east seam legitimately has y16/17 lanes.
                # This legacy check protects the old Route42 west seam only.
                self.assertIn('cp 16\n', body)
                label = '.west\n' if name.endswith('EdgeFence') else '.westSeam\n'
                self.assertIn(label,body)
                west=body.split(label,1)[1].split('\n.',1)[0]
                self.assertNotIn('cp 16\n',west,name)
            else:
                self.assertNotIn('cp 16\n',body,name)
            self.assertEqual(set(range(14,18)),{14,15,16,17})
        metatiles=(GOLD/'data/tilesets/johto_metatiles.bin').read_bytes()
        tilecoll=(GOLD/'data/tilesets/johto_collision.asm').read_text()
        for name,width,edge_x,stride in [('Route42',30,59,8),('MahoganyTown',10,0,3)]:
            cells=decode_cells((GOLD/'maps'/f'{name}.blk').read_bytes(),
                               metatiles,tilecoll,width,9)
            mask=(ROOT/'maps'/f'Johto{name}.blocked_mask.bin').read_bytes()
            for y in range(14,18):
                self.assertEqual(cells[y*width*2+edge_x]['role'],'FLOOR',(name,y))
                self.assertFalse(mask[y*stride+edge_x//8]&(1<<(edge_x%8)),(name,y))
        # Also prove that y14 can be reached from real interior ground, not
        # merely that the outermost block happens to be marked FLOOR.
        from collections import deque
        for name,width,start,finish in [('Route42',60,(54,15),(59,14)),
                                        ('MahoganyTown',20,(4,17),(0,14))]:
            mask=(ROOT/'maps'/f'Johto{name}.blocked_mask.bin').read_bytes()
            stride=(width+7)//8
            ground={(x,y) for y in range(18) for x in range(width)
                    if not mask[y*stride+x//8]&(1<<(x%8))}
            self.assertIn(start,ground)
            reached={start}
            q=deque([start])
            while q:
                x,y=q.popleft()
                for next_xy in ((x-1,y),(x+1,y),(x,y-1),(x,y+1)):
                    if next_xy in ground and next_xy not in reached:
                        reached.add(next_xy)
                        q.append(next_xy)
            self.assertIn(finish,reached,f'{name}: y14 entrance unreachable from inside')
        # Old y16/17-only predicate blocks BOTH y14/15 Gold floor lanes.
        self.assertEqual({y for y in range(14,18) if 16<=y<18},{16,17})

    def test_real_east_road_seam_executes_both_collision_layers_in_both_directions(self):
        # Original Gold has TWO disconnected approach corridors on this seam.
        # The first ID64 candidate opened only y14..17; old tests mistakenly
        # accepted that subset because they never executed the route-side gate.
        from johto_masked_step_audit import parse_caller, trace_masked_step
        collision=(ROOT/'engine/overworld/johto_route33_collision.asm').read_text()
        expected=set(range(4,8)) | set(range(9,18))
        for name,width,x,direction,local in (
            ('Route42',60,59,'RIGHT','JOHTO_ROUTE_42_LOCAL_ID'),
            ('MahoganyTown',20,0,'LEFT','JOHTO_MAHOGANY_TOWN_LOCAL_ID')):
            mask=(ROOT/'maps'/f'Johto{name}.blocked_mask.bin').read_bytes()
            for function in (f'Johto{name}EdgeFence',f'Johto{name}CanStepAhead'):
                program, labels=parse_caller(collision,function)
                for y in range(18):
                    blocked,via=trace_masked_step(program,labels,mask,width,18,local,x,y,direction)
                    self.assertEqual(not blocked,y in expected,
                                     (function,x,y,'allowed' if not blocked else 'blocked',via))
            # Gold and RPP mask agree, even for the unreachable top fragments:
            # the edge fence, not the raw block mask, must reject those.
            opposite='MahoganyTown' if name=='Route42' else 'Route42'
            other_x=0 if name=='Route42' else 59
            other_width=20 if name=='Route42' else 60
            other_mask=(ROOT/'maps'/f'Johto{opposite}.blocked_mask.bin').read_bytes()
            for y in expected:
                self.assertFalse(mask[y*((width+7)//8)+x//8] & (1<<(x%8)))
                self.assertFalse(other_mask[y*((other_width+7)//8)+other_x//8] & (1<<(other_x%8)))

    def test_real_east_road_approaches_connect_interior_to_seam(self):
        from collections import deque
        corridor_sets=[]
        for name,width,seed,edge_x in (
            ('Route42',60,(54,9),59),('MahoganyTown',20,(4,9),0),
            ('Route42',60,(54,15),59),('MahoganyTown',20,(4,17),0)):
            mask=(ROOT/'maps'/f'Johto{name}.blocked_mask.bin').read_bytes()
            stride=(width+7)//8
            ground={(x,y) for y in range(18) for x in range(width)
                    if not (mask[y*stride+x//8] & (1 << (x%8)))}
            self.assertIn(seed,ground)
            visited={seed}
            queue=deque([seed])
            while queue:
                x,y=queue.popleft()
                for xy in ((x+1,y),(x-1,y),(x,y+1),(x,y-1)):
                    if xy in ground and xy not in visited:
                        visited.add(xy)
                        queue.append(xy)
            corridor_sets.append({y for y in range(18) if (edge_x,y) in visited})
        self.assertEqual(corridor_sets[0],set(range(4,8)))
        self.assertEqual(corridor_sets[1],set(range(4,8)))
        self.assertEqual(corridor_sets[2],set(range(9,18)))
        self.assertEqual(corridor_sets[3],set(range(9,18)))

    def test_earlier_y14_only_airwall_is_detected_by_executed_gate(self):
        # Mutation is in memory only; this reproduces the exact old failure.
        from johto_masked_step_audit import parse_caller, trace_masked_step
        source=(ROOT/'engine/overworld/johto_route33_collision.asm').read_text()
        body=source.split('JohtoRoute42EdgeFence::',1)[1].split('JohtoRoute42CanStepAhead::',1)[0]
        self.assertIn('\tcp 4\n\tjr c, .block\n\tcp 8\n\tjr c, .clear\n\tcp 9\n\tjr c, .block\n\tcp 18',body)
        broken=source.replace(
            '\tcp 4\n\tjr c, .block\n\tcp 8\n\tjr c, .clear\n\tcp 9\n\tjr c, .block\n\tcp 18',
            '\tcp 14\n\tjr c, .block\n\tcp 18',1)
        mask=(ROOT/'maps/JohtoRoute42.blocked_mask.bin').read_bytes()
        program,labels=parse_caller(broken,'JohtoRoute42EdgeFence')
        for y in (4,5,6,7,9,10,11,12,13):
            blocked,_=trace_masked_step(program,labels,mask,60,18,
                                        'JOHTO_ROUTE_42_LOCAL_ID',59,y,'RIGHT')
            self.assertTrue(blocked,f'old air wall at y{y} must be rejected')
        good_program,good_labels=parse_caller(source,'JohtoRoute42EdgeFence')
        for y in (4,5,6,7,9,10,11,12,13):
            blocked,_=trace_masked_step(good_program,good_labels,mask,60,18,
                                        'JOHTO_ROUTE_42_LOCAL_ID',59,y,'RIGHT')
            self.assertFalse(blocked,f'fixed approach y{y} must be allowed')

    @staticmethod
    def _mahogany_preview_errors(source, gold_last_three):
        """Assert executable hook, map identity, buffer area and exact Gold rows."""
        failures=[]
        if len(re.findall(r'(?m)^\s+call PatchJohtoMahoganyNorthBorder\s*$',source)) != 1:
            failures.append('missing preview hook')
        try:
            body=source.split('PatchJohtoMahoganyNorthBorder::',1)[1].split(
                '; GATE-5.62.224 video correction:',1)[0]
        except IndexError:
            return failures+['missing preview routine']
        checks=('cp REGION_NATIVE_MAP_SLOT','cp MAP_REGION_JOHTO',
                'cp JOHTO_MAHOGANY_TOWN_LOCAL_ID',
                'ld b, JOHTO_MAHOGANY_TOWN_WIDTH',
                'ld hl, wOverworldMap + MAP_BORDER',
                'ld hl, wOverworldMap + (JOHTO_MAHOGANY_TOWN_WIDTH + 2 * MAP_BORDER) + MAP_BORDER',
                'ld hl, wOverworldMap + 2 * (JOHTO_MAHOGANY_TOWN_WIDTH + 2 * MAP_BORDER) + MAP_BORDER')
        failures.extend(f'missing {value}' for value in checks if value not in body)
        # Reject a misplaced row or a row copied from the wrong neighboring map.
        for i,row in enumerate(gold_last_three):
            match=re.search(r'(?m)^\.row'+str(i)+r'\s+db\s+([^\n]+)',body)
            if not match:
                failures.append(f'missing row{i}')
                continue
            actual=bytes(int(x.strip().replace('$','0x'),16)
                         for x in match.group(1).split(','))
            if actual != row:
                failures.append(f'wrong row{i}')
        return failures

    def test_mahogany_north_border_shows_gold_route43_roof_on_both_load_paths(self):
        source=(ROOT/'engine/overworld/johto_route33_collision.asm').read_text()
        gold=(GOLD/'maps/Route43.blk').read_bytes()
        self.assertEqual(len(gold),10*27)
        rows=[gold[(27-3+i)*10:(27-2+i)*10] for i in range(3)]
        self.assertEqual(self._mahogany_preview_errors(source,rows),[])
        attrs=(GOLD/'data/maps/attributes.asm').read_text()
        self.assertIn('connection north, Route43, ROUTE_43, 0',attrs)
        self.assertIn('connection south, MahoganyTown, MAHOGANY_TOWN, 0',attrs)
        home=(ROOT/'home/overworld.asm').read_text()
        self.assertEqual(home.count('callba PatchJohtoMapBordersAfterBlockLoad'),2)
        self.assertIn('call PatchJohtoMahoganyNorthBorder',source.split(
            'PatchJohtoMapBordersAfterBlockLoad::',1)[1].split(
            'PatchJohtoAzaleaWestGateBorder::',1)[0])
        # Rendering only: ID65/67 inactive and town north edge stays blocked.
        registered=(ROOT/'data/johto_map_headers.asm').read_text()
        self.assertIn('dw JohtoRoute43_h',registered)
        self.assertIn('dw JohtoRoute43MahoganyGate_h',registered)
        self.assertIn('JohtoMahoganyTownEdgeFence::',source)
        self.assertEqual((ROOT/'maps/JohtoMahoganyTown.blk').read_bytes(),
                         (GOLD/'maps/MahoganyTown.blk').read_bytes())

    def test_mahogany_preview_missing_hook_or_wrong_roof_is_detected(self):
        source=(ROOT/'engine/overworld/johto_route33_collision.asm').read_text()
        gold=(GOLD/'maps/Route43.blk').read_bytes()
        rows=[gold[(27-3+i)*10:(27-2+i)*10] for i in range(3)]
        self.assertEqual(self._mahogany_preview_errors(source,rows),[])
        broken=source.replace('\tcall PatchJohtoMahoganyNorthBorder',
                              '\t; call PatchJohtoMahoganyNorthBorder',1)
        self.assertIn('missing preview hook',self._mahogany_preview_errors(broken,rows))
        broken=source.replace('db $71, $71, $71, $69, $08, $09, $05, $05, $68, $71',
                              'db $05, $71, $71, $69, $08, $09, $05, $05, $68, $71',1)
        self.assertIn('wrong row2',self._mahogany_preview_errors(broken,rows))

    def test_headbutt_is_deferred_exact_xy(self):
        moves=json.loads((ROOT/'tools/johto_deferred_field_moves.json').read_text())['maps']['MahoganyTown']
        self.assertEqual(moves['headbutt']['status'],'DEFERRED')
        self.assertTrue(moves['headbutt']['gold_xy'])
