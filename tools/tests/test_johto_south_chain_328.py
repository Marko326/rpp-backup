"""DEV-328: wrong preview, Gold assets, gate warp and crossing regressions MUST fail."""
from pathlib import Path
import os
import sys
import pytest
ROOT=Path(__file__).resolve().parents[2]
sys.path.insert(0,str(ROOT/'tools'))
from johto_south_chain_328_audit import audit


def test_source_only_baseline_and_geometry():
    report=audit(ROOT)
    assert report['status']=='PASS_STATIC_ONLY',report['errors']
    assert len(report['checks'])>=27

@pytest.mark.parametrize('rel,old,new,check', [
    ('data/johto_pilot_map_headers.asm','db NORTH | WEST | EAST','db WEST | EAST','Route29_north_preview_not_default_trees'),
    ('data/johto_pilot_map_headers.asm','dw JohtoRoute46Route29NorthMirror + JOHTO_ROUTE_46_WIDTH * (JOHTO_ROUTE_46_HEIGHT - 3)','dw JohtoPilotRoute29RuntimeBlocks','Route29_north_preview_not_default_trees'),
    ('data/johto_south_chain_runtime_328.asm','dw JohtoRoute29Mirror + 10','dw JohtoRoute29Mirror','Route46_south_preview_not_default_trees'),
    ('data/johto_pilot_source_resources.asm','JOHTO_ROUTE_46_LOCAL_ID, SOUTH, MAP_REGION_JOHTO, JOHTO_ROUTE_29_LOCAL_ID','JOHTO_ROUTE_46_LOCAL_ID, NORTH, MAP_REGION_JOHTO, JOHTO_ROUTE_29_LOCAL_ID','six_independent_directed_source_edges'),
    ('engine/johto_pilot_runtime.asm','db MAP_REGION_JOHTO, JOHTO_ROUTE_29_ROUTE_46_GATE_LOCAL_ID, 2, MAP_REGION_JOHTO, JOHTO_ROUTE_29_LOCAL_ID','db MAP_REGION_JOHTO, JOHTO_ROUTE_29_ROUTE_46_GATE_LOCAL_ID, 2, MAP_REGION_JOHTO, JOHTO_ROUTE_46_LOCAL_ID','seven_original_gate_warps_exact'),
    ('data/johto_east_runtime_300.asm','cp JOHTO_ROUTE_46_HEIGHT * 2 - 1\n    jp nc, .closed','cp JOHTO_ROUTE_46_HEIGHT * 2 - 1\n    jp c, .closed','Route29_to_Route46_is_preview_only'),
])
def test_mutation_rejected(rel,old,new,check):
    text=(ROOT/rel).read_text();assert old in text
    results=audit(ROOT,overrides={rel:text.replace(old,new,1)})
    assert check in results['errors'],results['errors']

def test_bad_gate_source_block_rejected():
    p='maps/johto_pilot/Route29Route46Gate.gold.blk'
    b=bytearray((ROOT/p).read_bytes());b[0]^=1
    # Gold reference validation must reject malformed Gold asset
    gold=Path(os.environ['GOLD_SOURCE_ROOT']) if os.environ.get('GOLD_SOURCE_ROOT') else None
    if gold is None or not gold.is_dir():
        pytest.skip('Gold source not present: skip external byte comparison')
    results=audit(ROOT,gold,overrides={p:bytes(b)})
    assert 'Gold_exact_original_Route29Route46Gate' in results['errors']

def test_route46_mirror_requires_exact_bytes():
    p='maps/johto_pilot/Route46.north_route29_mirror.blk'
    b=bytearray((ROOT/p).read_bytes());b[-10]^=1
    results=audit(ROOT,overrides={p:bytes(b)})
    assert 'Route46_north_preview_matches_full_source' in results['errors']
