"""MAP-293 source-only onboarding must reject unreviewed activation and wrong assets."""
import json
import sys
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0,str(ROOT/'tools'))
from johto_next_corridor_source_gate_293 import audit, MANIFEST


class NextCorridorSourceGate293(unittest.TestCase):
    def baseline(self, overrides=None):
        return audit(ROOT, overrides=overrides)

    def manifest(self):
        return json.loads((ROOT/MANIFEST).read_text())

    def failed(self, overrides, cause):
        r=self.baseline(overrides)
        self.assertEqual(r['status'],'FAIL',r)
        self.assertTrue(any(cause in e for e in r['errors']),r['errors'])

    def test_baseline_source_only(self):
        r=self.baseline()
        self.assertEqual(r['status'],'PASS_SOURCE_ONLY',r['errors'])
        self.assertFalse(r['runtime_approved'])

    def test_corrupt_gold_block(self):
        p=self.manifest()['maps'][0]['assets']['gold_blk']['path']
        blob=bytearray((ROOT/p).read_bytes());blob[0]^=1
        self.failed({p:bytes(blob)},'Route37_gold_blk_sha256')

    def test_wrong_gold_length_even_if_sha_changed(self):
        m=self.manifest(); rec=m['maps'][1]; p=rec['assets']['gold_blk']['path']
        blob=(ROOT/p).read_bytes()[:-1]
        import hashlib
        rec['assets']['gold_blk']['sha256']=hashlib.sha256(blob).hexdigest()
        rec['assets']['gold_blk']['bytes']=len(blob)
        self.failed({MANIFEST:json.dumps(m).encode(),p:blob},'EcruteakCity_gold_frozen_sha')

    def test_wrong_stable_id(self):
        m=self.manifest();m['maps'][0]['stable_id']=19
        self.failed({MANIFEST:json.dumps(m).encode()},'Route37_identity')

    def test_wrong_gold_westward_gate_source(self):
        m=self.manifest();m['maps'][2]['gold_source']='maps/Route38EcruteakGate.blk'
        self.failed({MANIFEST:json.dumps(m).encode()},'Route38EcruteakGate_identity')

    def test_wrong_seam_offset(self):
        m=self.manifest();m['seams'][2]['offset']=0
        self.failed({MANIFEST:json.dumps(m).encode()},'six_source_seams_exact')

    def test_no_early_activate_route37(self):
        p='constants/region_map_constants.asm'
        s=(ROOT/p).read_text().replace('DEF NUM_JOHTO_ACTIVE_MAPS EQU 28','DEF NUM_JOHTO_ACTIVE_MAPS EQU 29')
        self.failed({p:s.encode()},'staging_does_not_advance_game_version')

    def test_no_early_route38_warp(self):
        p='data/johto_pilot_source_resources.asm'
        s=(ROOT/p).read_text().replace('JohtoPilotSourceConnectionsEnd::',
              '    db MAP_REGION_JOHTO, JOHTO_ECRUTEAK_CITY_LOCAL_ID, WEST, MAP_REGION_JOHTO, JOHTO_ROUTE_38_LOCAL_ID\nJohtoPilotSourceConnectionsEnd::')
        self.failed({p:s.encode()},'no_unapproved_live_connection')

    def test_no_early_header_pointer(self):
        p='data/johto_header_descriptors.asm'
        s=(ROOT/p).read_text().replace('JohtoHeaderDescriptorsEnd::',
              '    dw JohtoRoute38RuntimeHeader\nJohtoHeaderDescriptorsEnd::')
        self.failed({p:s.encode()},'staging_not_registered_in_live_headers')

    def test_mutated_mature_mask(self):
        p=self.manifest()['maps'][1]['assets']['npc_mature_mask']['path']
        b=bytearray((ROOT/p).read_bytes());b[0]^=1
        self.failed({p:bytes(b)},'EcruteakCity_npc_mature_mask_sha256')


if __name__=='__main__':unittest.main()
