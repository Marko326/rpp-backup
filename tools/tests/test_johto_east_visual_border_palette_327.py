"""Device-discovered defects: drop either visual fix -> audit MUST fail."""
from pathlib import Path
import sys
import pytest

ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(ROOT / 'tools'))
from johto_east_visual_border_palette_327 import audit


def test_current_and_gold_reference_borders():
    result = audit(ROOT)
    assert result['status'] == 'PASS_STATIC_ONLY', result['errors']


@pytest.mark.parametrize('rel, old, new, expected', [
    ('data/johto_route44_runtime_324.asm',
     'db $71 ; Gold Route44 map_attributes border: rock, not generic $05 trees',
     'db $05 ; trees mistakenly accepted', 'route44_gold_rock_border'),
    ('data/johto_blackthorn_runtime_326.asm',
     'db $71 ; Gold BlackthornCity map_attributes border: rock, not $05 trees',
     'db $05 ; trees mistakenly accepted', 'blackthorn_gold_rock_border'),
    ('color/loadpalettes.asm',
     'cp JOHTO_ROUTE_44_LOCAL_ID\n    jp z,.route42',
     'cp JOHTO_ROUTE_44_LOCAL_ID\n    jp z,.done',
     'route44_inherits_mahogany_roof_colors'),
    ('color/loadpalettes.asm',
     'cp JOHTO_MAHOGANY_TOWN_LOCAL_ID\n    jp z,.route42',
     'cp JOHTO_MAHOGANY_TOWN_LOCAL_ID\n    jp z,.done',
     'mahogany_roof_reference_still_selected'),
])
def test_mutation_rejected(rel, old, new, expected):
    src = (ROOT/rel).read_text()
    assert old in src
    result = audit(ROOT, changes={rel:src.replace(old, new, 1)})
    assert expected in result['errors'], result


def test_main_audit_cannot_silently_skip_visual_check():
    code = (ROOT/'tools/johto_pilot_migration_audit.py').read_text()
    assert 'visual327 = audit_visual_327(project, gold_root)' in code
    assert "'johto_visual_327_' + item['name']" in code
