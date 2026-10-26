"""SPID-5.62.240A: execute the missing legacy Route29 doorway + north preview branches.

A registered STEP_ON Warp is useless if the physical tile cannot be entered.
A connection field is not a rendering contract unless the correct source ROM
bank is selected while LoadTileBlockMap copies its 3-row border.
"""
import re
from pathlib import Path
import unittest
from johto_gatehouse_behavior_audit import predicate

ROOT = Path(__file__).resolve().parents[2]


def section(asm, start, end):
    return asm.split(start, 1)[1].split(end, 1)[0]


def instructions(section_text):
    program, labels = [], {}
    for raw in section_text.splitlines():
        stmt = raw.split(';', 1)[0].strip()
        if not stmt:
            continue
        if re.fullmatch(r'\.[A-Za-z][A-Za-z0-9_]*:?', stmt):
            labels[stmt.rstrip(':')] = len(program)
        else:
            program.append(stmt)
    return program, labels


def legacy_route29_door_step(home, collision, *, alias='JOHTO_ROUTE_29',
                             region='MAP_REGION_JOHTO', local='JOHTO_ROUTE_29_LOCAL_ID',
                             x=27, y=2, direction='PLAYER_DIR_UP'):
    # Execute the ROMX helper that is actually called by CollisionCheckOnLand
    # AFTER the sprite / tile-pair checks, BEFORE generic legacy passability.
    chunk=section(home,'CollisionCheckOnLand::','CheckTilePassable::')
    chunk=re.sub(r';[^\n]*','',chunk)
    m=re.search(r'(?m)^\.normalTileCollision\s*\n'
                r'\s*ld a,\[wCurMap\]\s+cp JOHTO_ROUTE_29\s+'
                r'jr nz,\.normalTilePassability\s+'
                r'callba JohtoRoute29GateStepAllowed\s+'
                r'jr c,\.noCollision\s+'
                r'\.normalTilePassability\s+call CheckTilePassable',chunk)
    if not m:
        raise AssertionError('real ROM0 movement does not call the Route29 DOOR override')
    # Route29 is a legacy source, but OTHER legacy aliases must never enter.
    if alias!='JOHTO_ROUTE_29':return False
    ids={'JOHTO_ROUTE_29_LOCAL_ID':1,'JOHTO_ROUTE_30_LOCAL_ID':3}
    return predicate(collision,'JohtoRoute29GateStepAllowed',local,x,y,
                     direction.replace('PLAYER_DIR_',''),ids,region,alias)


def preview_bank(source, *, alias='JOHTO_ROUTE_29',
                 region='MAP_REGION_JOHTO', local='JOHTO_ROUTE_29_LOCAL_ID', edge=0):
    body = section(source, 'ResolveNativeConnectionPreviewBank::', 'NativeRegionConnectionTargets::')
    program, labels = instructions(body)
    mem = {'wCurMap': alias, 'wCurRegion': region, 'wCurLocalMapID': local}
    a, b, c, e, z, pc = None, None, None, edge, False, 0
    for _ in range(120):
        if pc >= len(program):
            raise AssertionError('preview bank resolver ran past function')
        op = program[pc]; pc += 1
        if op == 'ld c,e':
            c = e; continue
        if op == 'ld a,c':
            a = c; continue
        m = re.fullmatch(r'ld a,\[(w\w+)\]', op)
        if m:
            a = mem[m[1]]; continue
        m = re.fullmatch(r'cp (\w+)', op)
        if m:
            token=m.group(1)
            value=int(token,0) if token.isdigit() else token
            z = a == value; continue
        m = re.fullmatch(r'(?:jr|jp) (z|nz),\s*(\.\w+)', op)
        if m:
            if z == (m[1]=='z'):
                pc = labels[m[2]]
            continue
        m = re.fullmatch(r'(?:jr|jp)\s+(\.\w+)', op)
        if m:
            pc = labels[m[1]]; continue
        if op == 'and a':
            z = (a == 0); continue
        m = re.fullmatch(r'ld e,\s*(BANK\(\w+\)|\$ff)', op)
        if m:
            e = m[1]; continue
        if op == 'ret':
            return e
        if op == 'ld b,a' or op == 'ld hl,NativeRegionConnectionTargets':
            raise AssertionError('Unexpected native selector scan in a reviewed Cherrygrove seam')
        raise AssertionError('unknown cross-bank preview ASM: '+op)
    raise AssertionError('preview bank lookup did not terminate')


class Route29GateRuntime240A(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.home = (ROOT/'home/overworld.asm').read_text()
        cls.lookup = (ROOT/'engine/overworld/region_map_lookup.asm').read_text()
        cls.collision = (ROOT/'engine/overworld/johto_route33_collision.asm').read_text()

    def test_real_legacy_step_into_gold_door(self):
        # Gold DOOR is (27,1). Starting at the floor below is (27,2).
        self.assertTrue(legacy_route29_door_step(self.home, self.collision))
        for changes in ({'y':1}, {'y':3}, {'x':26}, {'x':28},
                        {'direction':'PLAYER_DIR_DOWN'}, {'direction':'PLAYER_DIR_LEFT'},
                        {'direction':'PLAYER_DIR_RIGHT'}, {'local':'JOHTO_ROUTE_30_LOCAL_ID'},
                        {'region':'MAP_REGION_KANTO'}, {'alias':'JOHTO_ROUTE_30'}):
            with self.subTest(changes=changes):
                self.assertFalse(legacy_route29_door_step(self.home, self.collision, **changes))
        standing = section(self.home, 'CheckWarpsNoCollisionLoop::', 'CheckWarpsCollision::')
        self.assertIn('callba JohtoNorthGateStepWarpAllowed', standing)
        self.assertIn('jp c, WarpFound1', standing)

    def test_legacy_preview_reads_actual_route46_bank(self):
        expected = 'BANK(JohtoRoute46Blocks)'
        self.assertEqual(preview_bank(self.lookup), expected)
        self.assertEqual(preview_bank(self.lookup, edge=2), 'BANK(JohtoCherrygroveCityBlocks)')
        for changes in ({'edge':1}, {'edge':3},
                        {'region':'MAP_REGION_KANTO'}, {'local':'JOHTO_ROUTE_30_LOCAL_ID'},
                        {'alias':'JOHTO_ROUTE_30'}):
            self.assertEqual(preview_bank(self.lookup, **changes), '$ff')
        # This is a REAL cross-bank copy: the two blocks cannot be read with
        # the source map's bank ($40). Derive declarations independently.
        main = (ROOT/'main.asm').read_text()
        self.assertRegex(main, r'SECTION "Johto Route 29 Map", ROMX, BANK\[JOHTO_ROM_BANK\]')
        self.assertRegex(main, r'SECTION "Johto Route46 Map", ROMX, BANK\[\$47\]')
        self.assertRegex(main, r'DEF JOHTO_ROM_BANK EQU \$40')
        route29 = (ROOT/'data/mapHeaders/JohtoRoute29.asm').read_text()
        self.assertIn('dw JohtoRoute46Blocks + JOHTO_ROUTE_46_WIDTH * (JOHTO_ROUTE_46_HEIGHT - 3)', route29)
        self.assertIn('db NORTH | WEST | EAST', route29)
        home = self.home
        self.assertIn('callab ResolveNativeConnectionPreviewBank',
                      section(home, 'LoadTileBlockMap::', 'LoadNorthSouthConnectionsTileMap::'))
        self.assertIn('ld [MBC1RomBank],a', section(home, '\n.northConnection\n', '\n.southConnection\n'))

    def test_wrong_runtime_steps_are_rejected(self):
        anchor=' cp 2\n jr nz,.deny\n scf'
        self.assertEqual(self.collision.count(anchor),1)
        bad=self.collision.replace(anchor, anchor.replace('cp 2','cp 1'),1)
        self.assertFalse(legacy_route29_door_step(self.home,bad))
        anchor=' cp PLAYER_DIR_UP\n jr nz,.deny'
        self.assertEqual(self.collision.count(anchor),1)
        bad=self.collision.replace(anchor,anchor.replace('PLAYER_DIR_UP','PLAYER_DIR_DOWN'),1)
        self.assertFalse(legacy_route29_door_step(self.home,bad))
        anchor='callba JohtoRoute29GateStepAllowed'
        self.assertEqual(self.home.count(anchor),1)
        bad=self.home.replace(anchor,'callba JohtoNorthGateStepWarpAllowed',1)
        with self.assertRaises(AssertionError):
            legacy_route29_door_step(bad,self.collision)

    def test_cherrygrove_native_mixed_edges_select_correct_preview_banks(self):
        self.assertEqual(preview_bank(self.lookup, alias='JOHTO_ROUTE_29',
            local='JOHTO_ROUTE_29_LOCAL_ID', edge=2), 'BANK(JohtoCherrygroveCityBlocks)')
        self.assertEqual(preview_bank(self.lookup, alias='JOHTO_ROUTE_30',
            local='JOHTO_ROUTE_30_LOCAL_ID', edge=1), 'BANK(JohtoCherrygroveCityBlocks)')
        self.assertEqual(preview_bank(self.lookup, alias='REGION_NATIVE_MAP_SLOT',
            local='JOHTO_CHERRYGROVE_LOCAL_ID', edge=0), 'BANK(JohtoRoute30Blocks)')
        self.assertEqual(preview_bank(self.lookup, alias='REGION_NATIVE_MAP_SLOT',
            local='JOHTO_CHERRYGROVE_LOCAL_ID', edge=3), 'BANK(JohtoRoute29Blocks)')

    def test_wrong_preview_bank_and_edge_are_rejected(self):
        anchor='ld e,BANK(JohtoRoute46Blocks)'
        self.assertEqual(self.lookup.count(anchor), 1)
        bad = self.lookup.replace(anchor, 'ld e,BANK(JohtoRoute29Blocks)',1)
        self.assertNotEqual(preview_bank(bad), 'BANK(JohtoRoute46Blocks)')
        anchor='ld a,c\n and a ; north edge still leads to Route46'
        self.assertEqual(self.lookup.count(anchor), 1)
        bad=self.lookup.replace(anchor, 'ld a,c\n cp 1 ; incorrect south edge',1)
        self.assertNotEqual(preview_bank(bad), 'BANK(JohtoRoute46Blocks)')

if __name__ == '__main__':
    unittest.main()
