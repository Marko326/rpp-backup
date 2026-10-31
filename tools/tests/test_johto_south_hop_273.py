"""FIX-273: source-backed landing overrun, mature gate, and legacy protections."""
import hashlib
import re
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
LEDGES = ROOT/'engine/overworld/ledges.asm'
OVERWORLD = ROOT/'home/overworld.asm'
GATES = ROOT/'data/johto_south_runtime.asm'


HOPS = {
    'IlexForest': ('JohtoIlexForestGoldHops', 30, 54, ROOT/'maps/johto_pilot/IlexForest.roles.bin'),
    'AzaleaTown': ('JohtoAzaleaGoldHops', 40, 18, ROOT/'maps/johto_pilot/AzaleaTown.roles.bin'),
    'Route33': ('JohtoRoute33Hops', 20, 18, ROOT/'maps/johto_pilot/Route33.blocked_mask.bin'),
}


def hop_records(text, name):
    part=text.split(name+':',1)[1].split('db $FF',1)[0].split('db $ff',1)[0]
    return [(int(x),int(y),d) for x,y,d in re.findall(r'db\s+(\d+),\s*(\d+),\s*PLAYER_DIR_(LEFT|RIGHT|DOWN)',part)]


class MatureSouthHop273(unittest.TestCase):
    def test_all_jump_landings_and_barriers_are_source_backed(self):
        text=LEDGES.read_text()
        counts={'IlexForest':10, 'AzaleaTown':10,'Route33':7}
        for mapname,(label,w,h,path) in HOPS.items():
            records=hop_records(text,label)
            self.assertEqual(len(records),counts[mapname],mapname)
            cells=path.read_bytes()
            self.assertEqual(len(cells),w*h)
            for x,y,d in records:
                dx,dy={'LEFT':(-1,0),'RIGHT':(1,0),'DOWN':(0,1)}[d]
                first=(x+dx,y+dy); landing=(x+2*dx,y+2*dy)
                with self.subTest(map=mapname,takeoff=(x,y),direction=d):
                    for cx,cy in (first,landing): self.assertTrue(0<=cx<w and 0<=cy<h)
                    self.assertEqual(cells[first[1]*w+first[0]],1)
                    self.assertEqual(cells[landing[1]*w+landing[0]],0)

    def test_guard_uses_shared_queue_and_only_blocks_second_cell_overrun(self):
        txt=LEDGES.read_text(); ow=OVERWORLD.read_text()
        helper=txt.split('JohtoSouthHopLandingGuard::',1)[1].split('; (player direction)',1)[0]
        for label in ('JohtoIlexForestGoldHops','JohtoRoute33Hops','JohtoAzaleaGoldHops'):
            self.assertIn('ld hl, '+label,helper)
        self.assertIn('inc c\n    inc c',helper)
        self.assertIn('dec b\n    dec b',helper)
        self.assertIn('inc b\n    inc b',helper)
        self.assertIn('ld e, 1',helper)
        self.assertIn('callab JohtoSouthHopLandingGuard',ow)
        self.assertIn('scf ; refuse overrun',ow)
        self.assertIn('ld a, $2\n\tld [wSimulatedJoypadStatesIndex], a',txt)
        self.assertIn('cp JOHTO_RUNTIME_MAP_HANDLE',ow.split('CollisionCheckOnLand::',1)[1].split('\n.notJumping',1)[0])

    def test_two_mature_gates_use_compact_blocks_without_overwriting_gold(self):
        text=GATES.read_text()
        for n,approved in {
            'IlexForestAzaleaGate': 'JohtoIlexAzaleaGate.blk',
            'Route34IlexForestGate': 'JohtoRoute29Route46Gate.blk',
        }.items():
            mature=(ROOT/'maps/johto_pilot'/f'{n}.mature.blk').read_bytes()
            baseline=(ROOT/'maps/johto_pilot'/f'{n}.gold.blk').read_bytes()
            gold=(ROOT/'maps/johto_pilot'/f'{n}.runtime.blk').read_bytes()
            self.assertEqual(baseline,gold)
            import hashlib
            expected_hash = {'IlexForestAzaleaGate': 'cc1cea3f', 'Route34IlexForestGate': '6bf53a71'}[n]
            self.assertTrue(hashlib.sha256(mature).hexdigest().startswith(expected_hash))
            self.assertIn(f'INCBIN "maps/johto_pilot/{n}.mature.blk"',text)
            body=text.split('JohtoSouth'+n+'RuntimeHeader::',1)[1].split('dw JohtoSouth'+n+'Blocks',1)[0]
            self.assertIn('db JOHTO_GATE',body)
            obj=text.split('JohtoSouth'+n+'RuntimeObjects::',1)[1]
            self.assertIn('db $0d',obj.splitlines()[1])

if __name__=='__main__': unittest.main()
