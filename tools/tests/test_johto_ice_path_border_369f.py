from pathlib import Path
import pytest
from tools.johto_ice_path_border_369f_audit import audit, BORDERS

ROOT = Path(__file__).resolve().parents[2]


def test_all_five_gold_borders():
    assert audit(ROOT) == []


@pytest.mark.parametrize('name,label', [(n,x[0]) for n,x in BORDERS.items()])
def test_wrong_border_detected(name, label):
    path='data/johto_ice_path_stage/'+name
    code=(ROOT/path).read_text()
    original=BORDERS[name][1]
    wrong = 0x09 if original==0x19 else 0x19
    position=code.index(label)
    before, rest=code[:position],code[position:]
    text=rest.replace(f'db ${original:02x}', f'db ${wrong:02x}', 1)
    assert text != rest
    assert audit(ROOT, {path:before+text})
