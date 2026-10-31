"""FIX-287: all 26 active Johto map scripts share their header bank."""
import sys
from pathlib import Path
import unittest
ROOT=Path(__file__).resolve().parents[2]
sys.path.insert(0,str(ROOT/'tools'))
from johto_map_script_bank_audit_287 import audit

class ParkScriptBank287Tests(unittest.TestCase):
    def test_every_active_map_script_bank_matches_header(self):
        r=audit(ROOT)
        self.assertEqual('PASS_STATIC_ONLY',r['status'],r['errors'])
        self.assertEqual(32,len(r['checks']))
    def bad(self,old,new,expected):
        p='data/johto_park_runtime_286.asm';s=(ROOT/p).read_text()
        self.assertIn(old,s)
        r=audit(ROOT,{p:s.replace(old,new,1)})
        self.assertTrue(any(expected in e for e in r['errors']),r['errors'])
    def test_south_gate_cannot_reference_script_in_bank4c(self):
        p='data/johto_park_runtime_286.asm';s=(ROOT/p).read_text()
        idx=s.index('JohtoParkSouthGateRuntimeHeader::');a=s[:idx];b=s[idx:].replace('dw JohtoParkLocalScript','dw JohtoSouthScript',1)
        r=audit(ROOT,{p:a+b})
        self.assertTrue(any('JohtoParkSouthGateRuntimeHeader_script_in_header_bank' in x for x in r['errors']),r['errors'])
    def test_east_gate_cannot_reference_script_in_bank4c(self):
        p='data/johto_park_runtime_286.asm';s=(ROOT/p).read_text()
        idx=s.index('JohtoParkEastGateRuntimeHeader::')
        r=audit(ROOT,{p:s[:idx]+s[idx:].replace('dw JohtoParkLocalScript','dw JohtoSouthScript',1)})
        self.assertTrue(any('JohtoParkEastGateRuntimeHeader_script_in_header_bank' in x for x in r['errors']),r['errors'])
    def test_park_cannot_reference_script_in_bank4c(self):
        p='data/johto_park_runtime_286.asm';s=(ROOT/p).read_text()
        r=audit(ROOT,{p:s.replace('dw JohtoParkLocalScript','dw JohtoSouthScript',1)})
        self.assertTrue(any('JohtoParkRuntimeHeader_script_in_header_bank' in x for x in r['errors']),r['errors'])
    def test_runmapscript_bank_guard_cannot_be_removed(self):
        p='home/overworld.asm';s=(ROOT/p).read_text();part=s.split('RunMapScript::',1)[1].split('LoadWalkingPlayerSpriteGraphics::',1)[0]
        self.assertIn('call SwitchToMapRomBank',part)
        r=audit(ROOT,{p:s.replace('RunMapScript::'+part, 'RunMapScript::'+part.replace('call SwitchToMapRomBank','nop',1),1)})
        self.assertTrue(any('map_script_execution_is_unbanked_jump' in x for x in r['errors']),r['errors'])

if __name__=='__main__':unittest.main()
