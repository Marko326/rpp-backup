from pathlib import Path
import pytest
from tools.johto_ice_path_player_fall_369s_audit import audit, B1, B2, PILOT, FALL, CONTRACT

ROOT = Path(__file__).resolve().parents[2]


def test_player_gold_pit_source_and_receive_gate():
    assert audit(ROOT) == []


@pytest.mark.parametrize('file,needle,replacement,expected', [
    (B1, 'db 2, 11, 2, JOHTO_REGISTERED_WARP_SELECTOR',
     'db $ff, $ff, 2, JOHTO_REGISTERED_WARP_SELECTOR', 'PIT warp source'),
    (B2, 'db 4, 11, 2, JOHTO_REGISTERED_WARP_SELECTOR',
     'db 4, 12, 2, JOHTO_REGISTERED_WARP_SELECTOR', 'receive-only player landing'),
    (B1, 'jp z, .allow', 'ret z ; bad PIT blocked', 'player collision'),
    (PILOT, 'db MAP_REGION_JOHTO, JOHTO_ICE_PATH_B1F_LOCAL_ID, 4, MAP_REGION_JOHTO, JOHTO_ICE_PATH_B2F_MAHOGANY_SIDE_LOCAL_ID',
     '; missing PIT #5 route', 'source route'),
    (PILOT, 'ld e, 1 ; exact arrival-only ICE',
     'ld e, 2 ; wrongly makes receiver an EXIT', 'B2F warp mode'),
    (PILOT, 'ld e, 0 ; B2F Gold PIT ICE arrival can never act as a source warp',
     'ld e, 1 ; bad collision exit', 'collision'),
    (FALL, 'cp JOHTO_ICE_PATH_B1F_LOCAL_ID\n    jr z, .icePath369S',
     'cp JOHTO_ICE_PATH_1F_LOCAL_ID\n    jr z, .icePath369S', 'fall flag'),
    (FALL, 'cp 6\n    ret nc\n    ld a, [wDestinationWarpID]',
     'cp 8\n    ret nc\n    ld a, [wDestinationWarpID]', 'fall flag'),
    (FALL, 'jp PlaySilentMapChange369V',
     'jp GBFadeOutToWhite', 'Ice Path PIT'),
])
def test_one_way_player_pit_mutations_fail(file, needle, replacement, expected):
    text=(ROOT/file).read_text()
    assert needle in text, needle
    mutated=text.replace(needle,replacement,1)
    assert any(expected in issue for issue in audit(ROOT,{file:mutated})), audit(ROOT,{file:mutated})


def test_route_contract_is_reviewed_not_frozen_amended():
    text=(ROOT/CONTRACT).read_text()
    import json
    data=json.loads(text)
    assert 'frozen_ref365c_route_rows' in data
    modified=False
    for entry in data['critical_arrivals']:
        if entry.get('from') == 'JOHTO_ICE_PATH_B1F_LOCAL_ID' and entry.get('ordinal') == 2:
            entry.pop('new_route_review',None)
            modified=True
            break
    assert modified
    assert any('explicit safe receive-only warp field review' in issue for issue in
               audit(ROOT,{CONTRACT:json.dumps(data)}))
