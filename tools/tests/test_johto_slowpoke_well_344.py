"""Gold-backed REF-344 common Cave migration and corruption rejection."""
import os
import sys
import unittest
from pathlib import Path
sys.path.insert(0,str(Path(__file__).resolve().parents[1]))
from johto_slowpoke_well_344_audit import check

ROOT=Path(__file__).resolve().parents[2]
GOLD=Path(os.environ['JOHTO_GOLD_ROOT']) if os.environ.get('JOHTO_GOLD_ROOT') else None


class B2FContract(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        if GOLD is None or not (GOLD/'maps/SlowpokeWellB2F.blk').is_file():
            raise unittest.SkipTest('Set JOHTO_GOLD_ROOT to the extracted pokegold-master directory')
    def test_gold_and_shared_cave_contract(self):
        self.assertEqual(check(ROOT,GOLD), [])

    def test_corrupt_water_table_rejected(self):
        fn='engine/johto_violet_field_skills.asm'
        orig=(ROOT/fn).read_text()
        anchor='JohtoSlowpokeWellB2FGoldWaterCells::\n'
        self.assertIn(anchor,orig)
        altered=orig.replace(anchor+'\tdb 2, 8\n',anchor+'\tdb 2, 9\n',1)
        self.assertNotEqual(orig,altered)
        self.assertTrue(any('GoldWaterCells' in e for e in check(ROOT,GOLD,{fn:altered})))

    def test_warp_route_missing_rejected(self):
        fn='engine/johto_pilot_runtime.asm'
        orig=(ROOT/fn).read_text()
        row='    db MAP_REGION_JOHTO, JOHTO_SLOWPOKE_WELL_B2F_LOCAL_ID, 0, MAP_REGION_JOHTO, JOHTO_SLOWPOKE_WELL_B1F_LOCAL_ID\n'
        self.assertIn(row,orig)
        errors=check(ROOT,GOLD,{fn:orig.replace(row,'',1)})
        self.assertTrue(any('144' in e or 'reciprocal' in e for e in errors))

    def test_map_asset_tampering_rejected(self):
        fn='maps/johto_pilot/SlowpokeWellB2F.runtime.blk'
        data=(ROOT/fn).read_bytes()
        altered=bytes([data[0]^0x01])+data[1:]
        errors=check(ROOT,GOLD,{fn:altered})
        self.assertTrue(any('conversion' in e for e in errors))


if __name__=='__main__': unittest.main()
