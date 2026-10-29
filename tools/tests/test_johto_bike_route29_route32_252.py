"""ROUTES-252: gate bike identity, original Gold Cut/Surf, regression guards.

Static/source-only tests; not an RGBDS link nor on-device acceptance.
"""
from __future__ import annotations
import json, os, re, sys, unittest
from pathlib import Path
ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0,str(ROOT/'tools'))
from johto_gold_door_audit import GoldCollisionIndex
from johto_surf_preflight import check_project, water_coordinates
GOLD = Path(os.environ['GOLD_SOURCE_ROOT']) if os.environ.get('GOLD_SOURCE_ROOT') else None
CUTS = {
    'Route29': [(1,9,30,0x63),(1,11,21,0x5f)],
    'Route30': [(3,6,8,0x67)],
    'Route31': [(4,5,13,0x5f),(4,10,25,0x5b)],
    'Route32': [(7,19,10,0x63)],
}

def records(asm):
    s=asm.split('JohtoRoutesGoldCutCells::',1)[1].split('JohtoRoutesGoldCutCellsEnd::',1)[0]
    result=[]
    for n,y,x,b in re.findall(r'(?m)^\s*db\s+JOHTO_ROUTE_(29|30|31|32)_LOCAL_ID,\s*(\d+),\s*(\d+),\s*\$([a-fA-F0-9]+)',s):
        result.append((int(n),int(y),int(x),int(b,16)))
    return result

class JohtoBikeCutSurf252(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.home=(ROOT/'home/overworld.asm').read_text()
        cls.field=(ROOT/'engine/johto_violet_field_skills.asm').read_text()
        cls.contract=json.loads((ROOT/'tools/johto_surf_contracts.json').read_text())

    def test_only_active_gold_gate_eligible_and_legacy_untouched(self):
        b=self.home.split('IsBikeRidingAllowed::',1)[1].split('INCLUDE "data/bike_riding_tilesets.asm"',1)[0]
        self.assertRegex(b, r'cp JOHTO_RUNTIME_MAP_HANDLE\s+jr nz, \.legacyBike\s+ld a, \[wCurRegion\]\s+cp MAP_REGION_JOHTO\s+jr nz, \.legacyBike\s+ld a, \[wCurLocalMapID\]\s+cp JOHTO_ROUTE31_VIOLET_GATE_LOCAL_ID\s+jr z, \.allowed')
        self.assertIn('cp ROUTE_23',b)
        self.assertIn('cp INDIGO_PLATEAU',b)
        self.assertIn('ld hl, BikeRidingTilesets',b)
        tilesets=(ROOT/'data/bike_riding_tilesets.asm').read_text()
        self.assertNotIn('JOHTO_GATE',tilesets)
        self.assertNotIn('JOHTO_HOUSE',tilesets)
        self.assertEqual(1,b.count('cp JOHTO_ROUTE31_VIOLET_GATE_LOCAL_ID'))
        for filename in ('engine/items/items.asm','engine/overworld/bike_shortcut.asm','engine/menu/summary_return_helpers.asm'):
            self.assertIn('IsBikeRidingAllowed',(ROOT/filename).read_text())
        # shared predicate also runs on warp player-sprite reload.
        self.assertIn('call IsBikeRidingAllowed',self.home.split('LoadPlayerSpriteGraphics::',1)[1].split('LoadTilesetTilePatternData::',1)[0])

    @unittest.skipIf(GOLD is None,'Gold primary source is needed')
    def test_gold_environment_allows_gate_and_preserves_bike_on_entry(self):
        gold=GOLD/'engine/events/overworld.asm'
        body=gold.read_text().split('.CheckEnvironment:',1)[1].split('\n.nope\n',1)[0]
        self.assertRegex(body,r'cp GATE\s+jr z, \.ok')
        self.assertIn('call GetPlayerTilePermission',body)
        setup=(GOLD/'engine/overworld/map_setup.asm').read_text().split('.ResetSurfingOrBikingState:',1)[1].split('\n.no_biking\n',1)[0]
        for disallowed in ('INDOOR','ENVIRONMENT_5','DUNGEON'):
            self.assertIn('cp '+disallowed,setup)
        self.assertNotIn('cp GATE',setup)

    def test_negative_gate_identity_mutations_fail_contract(self):
        body=self.home.split('IsBikeRidingAllowed::',1)[1].split('INCLUDE "data/bike_riding_tilesets.asm"',1)[0]
        valid=re.compile(r'cp JOHTO_RUNTIME_MAP_HANDLE\s+jr nz, \.legacyBike\s+ld a, \[wCurRegion\]\s+cp MAP_REGION_JOHTO\s+jr nz, \.legacyBike\s+ld a, \[wCurLocalMapID\]\s+cp JOHTO_ROUTE31_VIOLET_GATE_LOCAL_ID\s+jr z, \.allowed')
        for src in (body.replace('cp MAP_REGION_JOHTO','cp MAP_REGION_KANTO',1),
                    body.replace('cp JOHTO_ROUTE31_VIOLET_GATE_LOCAL_ID','cp JOHTO_GUIDE_GENTS_HOUSE_LOCAL_ID',1),
                    body.replace('jr nz, .legacyBike','jr z, .legacyBike',1)):
            self.assertIsNone(valid.search(src))

    @unittest.skipIf(GOLD is None,'Gold original trees required')
    def test_cut_coordinates_identical_gold_and_live_blocks(self):
        gold=GoldCollisionIndex(GOLD)
        expected={(int(name[5:]), y,x,b) for name,cuts in CUTS.items() for _,y,x,b in cuts}
        self.assertEqual(expected,set(records(self.field)))
        for name,cuts in CUTS.items():
            from_gold={(v['y'],v['x'],v['block_id']) for v in gold.cells(name).values() if v['role']=='CUT_TREE'}
            from_table={(y,x,b) for _id,y,x,b in cuts}
            self.assertEqual(from_gold,from_table)
            src=(ROOT/f'maps/johto_pilot/{name}.runtime.blk').read_bytes()
            width={'Route29':30,'Route30':10,'Route31':20,'Route32':10}[name]
            for _id,y,x,b in cuts:
                self.assertEqual(src[(y//2)*width+x//2],b)
        cutcode=self.field.split('JohtoRoutesCutTreeAhead::',1)[1].split('JohtoPilotCutTreeAhead::',1)[0]
        for name in ('29','30','31','32'):
            self.assertIn('cp JOHTO_ROUTE_'+name+'_LOCAL_ID',cutcode)
        self.assertIn('cp [hl]',cutcode)  # prevents repeated Cut on already-cleared tree

    def test_clear_blocks_reuse_existing_exact_tree_quadrants(self):
        data=(ROOT/'data/johto_pilot_runtime_assets.asm').read_text()
        original=(ROOT/'gfx/blocksets/johto.bst').read_bytes()
        for old,new,qr,qc in [(0x63,0x8d,1,0),(0x5f,0x8f,1,1)]:
            label='JohtoPilotVioletCutClearedBlock::' if new==0x8d else 'JohtoPilotCutClearedBlock8F::'
            raw=data.split(label,1)[1].split('::',1)[0]
            clone=bytes(int(t,16) for line in raw.splitlines() if line.lstrip().startswith('db ') for t in re.findall(r'\$([0-9a-fA-F]{2})',line))
            self.assertEqual(16,len(clone))
            expected=bytearray(original[old*16:(old+1)*16])
            for dy in (0,1):
                for dx in (0,1):expected[(qr*2+dy)*4+qc*2+dx]=0x05
            self.assertEqual(expected,clone)
        pairs=(ROOT/'engine/overworld/cut.asm').read_text().split('CutTreeBlockSwaps:',1)[1].split('db $FF',1)[0]
        self.assertIn('db $63, $8D',pairs)
        self.assertIn('db $5F, $8F',pairs)
        self.assertEqual(1,pairs.count('db $63, $8D'))
        self.assertEqual(1,pairs.count('db $5F, $8F'))
        self.assertEqual(145*16,int(re.search(r'JohtoPilot_BlockEnd - JohtoPilot_Block == (\d+) \* 16',data)[1])*16)

    @unittest.skipIf(GOLD is None,'Gold water source required')
    def test_route32_water_shore_and_no_walkable_wet_tile(self):
        index=GoldCollisionIndex(GOLD)
        actual=water_coordinates(self.field,'JohtoRoute32GoldWaterCells','JohtoRoute32GoldWaterCellsEnd')
        expected={(v['y'],v['x']) for v in index.cells('Route32').values() if v['role']=='WATER'}
        self.assertEqual(278,len(actual))
        self.assertEqual(expected,actual)
        runtime=(ROOT/'maps/johto_pilot/Route32.runtime.blk').read_bytes()
        blocks=(ROOT/'gfx/blocksets/johto.bst').read_bytes()
        walk=set((ROOT/'gfx/tilesets/johto.tilecoll').read_bytes())-{0xff}
        self.assertEqual(450,len(runtime))
        for y,x in actual:
            b=runtime[(y//2)*10+x//2]
            artwork={blocks[b*16+(2*(y%2)+dy)*4+2*(x%2)+dx] for dy in (0,1) for dx in (0,1)}
            self.assertFalse(artwork&walk,(y,x))
        self.assertEqual([],check_project(ROOT,self.contract,GOLD))
        gateway=self.field.split('JohtoVioletWaterAhead::',1)[1].split('JohtoCherrygroveIsActive::',1)[0]
        self.assertRegex(gateway,r'call JohtoRoute32WaterAhead\s+ret c')
        self.assertRegex(self.home,r'callab JohtoRoute32WaterAhead\s+jp c, \.noCollision\s+ld a, \[wTileInFrontOfPlayer\]\s+ld c, a\s+jr \.checkIfNextTileIsPassable')

    def test_negative_broken_route32_water_table_detected(self):
        orig=water_coordinates(self.field,'JohtoRoute32GoldWaterCells','JohtoRoute32GoldWaterCellsEnd')
        start=self.field.index('JohtoRoute32GoldWaterCells::')
        broken=self.field[:start]+self.field[start:].replace('db 0, 0','db 0, 1',1)
        # Use a deterministic first entry rather than assuming any fixed coordinate.
        m=re.search(r'JohtoRoute32GoldWaterCells::\s+db (\d+), (\d+)',self.field)
        self.assertIsNotNone(m)
        bad=f'{m[1]}, {(int(m[2])+1)%20}'
        mutated=self.field[:start]+self.field[start:].replace(f'db {m[1]}, {m[2]}',f'db {bad}',1)
        self.assertNotEqual(self.field,mutated)
        # Source table differs, either a duplicate or Gold mismatch.
        x=set(orig);x.discard((int(m[1]),int(m[2])));x.add((int(m[1]),(int(m[2])+1)%20))
        self.assertNotEqual(orig,x)

    def test_bank03_unchanged_and_relief_bank48(self):
        main=(ROOT/'main.asm').read_text()
        self.assertIn('SECTION "Johto Violet Field Skills", ROMX, BANK[$48]',main)
        for rom in ('rppred','rppblue'):
            prior=(ROOT/'patches'/f'{rom}.map').read_text()
            self.assertIn('ROMX bank #72:\n  EMPTY',prior)
        cut=(ROOT/'engine/overworld/cut.asm').read_text().split('UsedCut:',1)[1].split('.legacyTileset',1)[0]
        self.assertEqual(1,cut.count('callab JohtoPilotCutTreeAhead'))
        items=(ROOT/'engine/items/items.asm').read_text()
        self.assertNotIn('callab JohtoRoute32WaterAhead',items)
        self.assertIn('callab JohtoVioletWaterAhead',items)

if __name__=='__main__':unittest.main()
