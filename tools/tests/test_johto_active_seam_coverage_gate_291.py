"""An added direct seam is blocked until explicitly reviewed, not silently skipped."""
import unittest
from pathlib import Path
from tools.johto_active_seam_coverage_gate_291 import audit
from tools.johto_pilot_migration_audit import EXPECTED_ACTIVE_IDS, MAP_LAYOUTS

ROOT=Path(__file__).resolve().parents[2]
SRC='data/johto_pilot_source_resources.asm'

class ActiveSeamCoverage291(unittest.TestCase):
    def run_audit(self, **kw):
        return audit(ROOT,EXPECTED_ACTIVE_IDS,MAP_LAYOUTS,**kw)

    def test_all_current_connections_covered(self):
        result=self.run_audit()
        self.assertEqual('PASS_STATIC_ONLY',result['status'],result['errors'])

    def test_new_connection_fails_even_when_registration_succeeds(self):
        source=(ROOT/SRC).read_text()
        injected=source.replace('JohtoPilotSourceConnectionsEnd::',
            '    db MAP_REGION_JOHTO, JOHTO_ROUTE_33_LOCAL_ID, NORTH, MAP_REGION_JOHTO, JOHTO_ROUTE_36_LOCAL_ID\nJohtoPilotSourceConnectionsEnd::')
        self.assertNotEqual(source,injected)
        r=self.run_audit(registry_override=injected)
        self.assertIn('new_connection_requires_visual_review',
                      {x['check'] for x in r['checks'] if x['status']=='FAIL'})

    def test_new_narrow_to_wide_connection_fails(self):
        source=(ROOT/SRC).read_text()
        injected=source.replace('JohtoPilotSourceConnectionsEnd::',
            '    db MAP_REGION_JOHTO, JOHTO_ROUTE_35_LOCAL_ID, SOUTH, MAP_REGION_JOHTO, JOHTO_VIOLET_CITY_LOCAL_ID\nJohtoPilotSourceConnectionsEnd::')
        r=self.run_audit(registry_override=injected)
        self.assertIn('narrow_to_wide_seams_have_review_contracts',
                      {x['check'] for x in r['checks'] if x['status']=='FAIL'})

    def test_route35_reverts_to_ten_columns_fails(self):
        rel='data/johto_north_runtime_283.asm'
        src=(ROOT/rel).read_text()
        old='db JOHTO_ROUTE35_WIDTH + MAP_BORDER ; 13 visible columns, not 10'
        self.assertIn(old,src)
        r=self.run_audit(overrides={rel:src.replace(old,'db JOHTO_ROUTE35_WIDTH',1)})
        self.assertIn('preview_width_and_source_reviewed_Route35_NORTH',
                      {x['check'] for x in r['checks'] if x['status']=='FAIL'})

    def test_route30_offset_replaced_fails(self):
        rel='data/johto_pilot_map_headers.asm'
        src=(ROOT/rel).read_text()
        old='dw JohtoPilotCherrygroveRuntimeBlocks + 5'
        self.assertIn(old,src)
        r=self.run_audit(overrides={rel:src.replace(old,'dw JohtoPilotCherrygroveRuntimeBlocks',1)})
        self.assertIn('preview_width_and_source_reviewed_Route30_SOUTH',
                      {x['check'] for x in r['checks'] if x['status']=='FAIL'})

    def test_route32_north_old_ten_columns_is_rejected(self):
        # Historical NPC .223 regression: screen requires ten overlap cols
        # plus three preview cols; fixing walk lanes is not sufficient.
        rel='data/johto_route32_runtime.asm'
        src=(ROOT/rel).read_text()
        old='db JOHTO_ROUTE_32_WIDTH + 3 ; visual margin needed for city beyond Route32 east edge'
        self.assertIn(old,src)
        r=self.run_audit(overrides={rel:src.replace(old,'db JOHTO_ROUTE_32_WIDTH',1)})
        self.assertIn('preview_width_and_source_reviewed_Route32_NORTH',
                      {x['check'] for x in r['checks'] if x['status']=='FAIL'})

    def test_route30_south_old_fifteen_columns_is_rejected(self):
        # Historical NPC .223 bug: old macro silently copied 15 columns
        # instead of ten offset from Cherrygrove column five.
        rel='data/johto_pilot_map_headers.asm'
        src=(ROOT/rel).read_text()
        old='db JOHTO_ROUTE_30_WIDTH\n    db JOHTO_CHERRYGROVE_WIDTH'
        self.assertIn(old,src)
        r=self.run_audit(overrides={rel:src.replace(old,
            'db JOHTO_ROUTE_30_WIDTH + 5\n    db JOHTO_CHERRYGROVE_WIDTH',1)})
        self.assertIn('preview_width_and_source_reviewed_Route30_SOUTH',
                      {x['check'] for x in r['checks'] if x['status']=='FAIL'})

    def test_side_seam_route31_header_corruption_fails(self):
        rel='data/johto_pilot_map_headers.asm'
        src=(ROOT/rel).read_text()
        old='dw JohtoPilotVioletRuntimeBlocks + JOHTO_VIOLET_CITY_WIDTH * 9 + JOHTO_VIOLET_CITY_WIDTH - 3'
        self.assertIn(old,src)
        r=self.run_audit(overrides={rel:src.replace(old,
            'dw JohtoPilotVioletRuntimeBlocks + JOHTO_VIOLET_CITY_WIDTH - 3',1)})
        self.assertIn('preview_width_and_source_reviewed_Route31_WEST',
                      {x['check'] for x in r['checks'] if x['status']=='FAIL'})

    def test_side_seam_route36_header_corruption_fails(self):
        rel='data/johto_ruins_north_runtime.asm'
        src=(ROOT/rel).read_text()
        old='db JOHTO_ROUTE_36_HEIGHT ; map rows (the border is refilled by 3 extra rows)\n    db JOHTO_VIOLET_CITY_WIDTH'
        self.assertIn(old,src)
        r=self.run_audit(overrides={rel:src.replace(old,
            'db JOHTO_ROUTE_36_HEIGHT - 1\n    db JOHTO_VIOLET_CITY_WIDTH',1)})
        self.assertIn('preview_width_and_source_reviewed_Route36_EAST',
                      {x['check'] for x in r['checks'] if x['status']=='FAIL'})

    def test_new_short_to_tall_side_edge_is_flagged(self):
        source=(ROOT/SRC).read_text()
        injected=source.replace('JohtoPilotSourceConnectionsEnd::',
            '    db MAP_REGION_JOHTO, JOHTO_ROUTE_33_LOCAL_ID, WEST, MAP_REGION_JOHTO, JOHTO_VIOLET_CITY_LOCAL_ID\nJohtoPilotSourceConnectionsEnd::')
        r=self.run_audit(registry_override=injected)
        self.assertIn('short_to_tall_side_seams_have_review_contracts',
                      {x['check'] for x in r['checks'] if x['status']=='FAIL'})

    def test_all_seams_still_bidirectional(self):
        source=(ROOT/SRC).read_text()
        old='db MAP_REGION_JOHTO, JOHTO_ROUTE_36_LOCAL_ID, SOUTH, MAP_REGION_JOHTO, JOHTO_ROUTE_35_LOCAL_ID'
        self.assertIn(old,source)
        injected=source.replace(old,'; disabled reverse for test',1)
        r=self.run_audit(registry_override=injected)
        self.assertIn('all_registered_seams_bidirectional',
                      {x['check'] for x in r['checks'] if x['status']=='FAIL'})

if __name__=='__main__': unittest.main()
