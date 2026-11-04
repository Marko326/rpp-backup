#!/usr/bin/env python3
"""REF-334 Azalea Pokecenter: fail-closed Gold source and runtime admission.

Read-only static evidence. Deliberately does not link ROM, simulate the CPU,
claim mobile acceptance, or modify the project. `overrides` support mutants.
"""
from __future__ import annotations
import argparse
import json
from pathlib import Path
import re

try:
    from johto_gold_door_audit import GoldCollisionIndex
except ImportError:
    from tools.johto_gold_door_audit import GoldCollisionIndex

CENTER = 'JOHTO_AZALEA_POKECENTER_1F_LOCAL_ID'
TOWN = 'JOHTO_AZALEA_TOWN_LOCAL_ID'


def audit(root: Path, gold_root: Path | None = None, overrides: dict | None = None) -> dict:
    root, overrides = Path(root), overrides or {}
    checks, errors = [], []

    def read(rel, binary=False):
        data = overrides.get(rel)
        if data is None:
            data = (root / rel).read_bytes()
        if isinstance(data, str):
            data = data.encode('utf8')
        return data if binary else data.decode('utf8')

    def code(rel):
        return '\n'.join(line.split(';', 1)[0].rstrip() for line in read(rel).splitlines())

    def check(name, predicate):
        checks.append({'check': name, 'status': 'PASS' if predicate else 'FAIL'})
        if not predicate:
            errors.append(name)

    try:
        count = code('constants/region_map_constants.asm')
        slots = code('data/johto_stable_id_slots.asm')
        headers = code('data/johto_header_descriptors.asm')
        source = code('data/johto_pilot_source_resources.asm')
        assets = code('data/johto_pilot_runtime_assets.asm')
        room = code('engine/johto_shared_pokecenter.asm')
        runtime = code('engine/johto_pilot_runtime.asm')
        town = code('data/johto_south_runtime.asm')
        geo = code('engine/johto_south_geometry.asm')
        portal = code('engine/johto_south_portals.asm')
        nurse = code('engine/johto_gold_healing_machine_337.asm')
        fly = code('engine/johto_pilot_fly_map.asm')
        names = code('engine/fly_town_map_helpers.asm')
        music = code('engine/menu/options_menu.asm')
        guard = code('data/johto_vertical_gate_runtime_314.asm')
        raw = read('maps/johto_pilot/AzaleaPokecenter1F.gold.blk', True)
        runtime_blk = read('maps/johto_pilot/AzaleaPokecenter1F.runtime.blk', True)
        reference = read('maps/johto_pilot/CherrygrovePokecenter1F.gold.blk', True)
        check('append_only_slot_and_identity',
              'DEF NUM_JOHTO_ACTIVE_MAPS EQU 56' in count and
              'ASSERT JOHTO_AZALEA_POKECENTER_1F_LOCAL_ID == 135' in room and
              bool(re.search(r'(?m)^\s*db\s+[^\n]*\b49\b[^\n]*; \$80-\$8f', read('data/johto_stable_id_slots.asm'))) and
              'dw JohtoAzaleaPokecenterRuntimeHeader' in headers and
              'db BANK(JohtoAzaleaPokecenterRuntimeHeader)' in headers and
              'JohtoAzaleaPokecenterRuntimeDescriptor::\n    db '+CENTER+', JOHTO_POKECENTER, 5, 4' in assets)
        check('gold_room_and_unique_source_identity',
              raw == reference and runtime_blk == read('maps/johto_pilot/CherrygrovePokecenter1F.runtime.blk', True) and len(raw) == len(runtime_blk) == 20 and
              'JohtoAzaleaPokecenterGoldBlocks:: INCBIN "maps/johto_pilot/AzaleaPokecenter1F.gold.blk"' in source and
              'db MAP_REGION_JOHTO, '+CENTER+', 5, 4\n    dw JohtoAzaleaPokecenterGoldBlocks\n    db BANK(JohtoAzaleaPokecenterGoldBlocks)' in source and
              'dw JohtoSharedPokecenterRuntimeBlocks' in assets)
        obj = room.split('JohtoAzaleaPokecenterRuntimeObjects::', 1)[1].split('JohtoVioletPokecenterRuntimeObjects::', 1)[0]
        check('independent_header_and_two_gold_carpets',
              bool(re.search(r'JohtoAzaleaPokecenterRuntimeHeader::.*?db JOHTO_POKECENTER.*?dw JohtoSharedPokecenterRuntimeBlocks.*?dw JohtoSharedPokecenterTextPointers.*?dw JohtoSharedPokecenterMapScript.*?dw JohtoAzaleaPokecenterRuntimeObjects',room,re.S)) and
              bool(re.search(r'db 2\s+db 7, 3, 2, JOHTO_REGISTERED_WARP_SELECTOR\s+db 7, 4, 2, JOHTO_REGISTERED_WARP_SELECTOR\s+db 0\s+db 1\s+object SPRITE_NURSE, \$3, \$1, STAY, DOWN, \$1',obj)) and
              room.count('object SPRITE_NURSE, $3, $1, STAY, DOWN, $1') == 9)
        town_warps = town.split('JohtoSouthAzaleaTownRuntimeObjects::', 1)[1].split('JohtoSouthIlexForestAzaleaGateBlocks::', 1)[0]
        check('only_center_door_unlocked_existing_gate_ordinals',
              bool(re.search(r'db 3\s+db 10, 2, 2, JOHTO_REGISTERED_WARP_SELECTOR\s+db 11, 2, 3, JOHTO_REGISTERED_WARP_SELECTOR\s+db 9, 15, 0, JOHTO_REGISTERED_WARP_SELECTOR',town_warps)) and
              'db 0' in town_warps)
        routes = runtime.split('JohtoRegisteredWarpRoutes::', 1)[1].split('JohtoRegisteredWarpRoutesEnd::', 1)[0]
        rows = [line.split(';',1)[0].strip() for line in routes.splitlines()
                if line.strip() and not line.lstrip().startswith(';')]
        target = [
            'db MAP_REGION_JOHTO, '+TOWN+', 2, MAP_REGION_JOHTO, '+CENTER,
            'db MAP_REGION_JOHTO, '+CENTER+', 0, MAP_REGION_JOHTO, '+TOWN,
            'db MAP_REGION_JOHTO, '+CENTER+', 1, MAP_REGION_JOHTO, '+TOWN,
        ]
        check('registered_113_exact_bidirectional_center_routes',
              len(rows) == 131 and all(rows.count(x)==1 for x in target) and
              'db MAP_REGION_JOHTO, JOHTO_AZALEA_TOWN_LOCAL_ID, 0, MAP_REGION_JOHTO, JOHTO_ILEX_AZALEA_GATE_LOCAL_ID' in routes and
              'db MAP_REGION_JOHTO, JOHTO_AZALEA_TOWN_LOCAL_ID, 1, MAP_REGION_JOHTO, JOHTO_ILEX_AZALEA_GATE_LOCAL_ID' in routes)
        fence = geo.split('JohtoSouthMatureDoorFence::',1)[1].split('JohtoSouthAzaleaTownRoles::',1)[0]
        closed = fence.split('.closedDoorTargets',1)[-1]  # collect only table below label
        check('door_fence_only_up_and_other_22_closed',
              bool(re.search(r'\.azaleaDoor\s+ld a, e\s+cp 15\s+jr nz, \.scanOther\s+ld a, d\s+cp 9\s+jr nz, \.scanOther\s+ld a, \[wPlayerDirection\]\s+cp PLAYER_DIR_UP\s+jp z, \.open\s+jp \.blocked', fence)) and
              'db '+TOWN+', 15, 9' not in geo and
              all('db '+TOWN+', '+x+', '+y in geo for x,y in [('9','5'),('21','5'),('21','13'),('10','15')]) and
              '.scanOther\n    ld a, [wCurLocalMapID]' in fence)
        after = portal.split('JohtoSouthPortalAfterStep::',1)[1].split('JohtoSouthPortalArrivalStep::',1)[0]
        before = portal.split('JohtoSouthPortalBeforeStep::',1)[1]
        arrival = portal.split('JohtoSouthPortalArrivalStep::',1)[1].split('JohtoSouthPortalBeforeStep::',1)[0]
        check('door_approach_before_and_after_step',
              '.azaleaCenterDoor\n    ld a, [wXCoord]\n    cp 15\n    ret nz\n    ld a, [wYCoord]\n    cp 10\n    jp z, .allow' in before and
              '.azaleaCenterDoor\n    ld a, [wXCoord]\n    cp 15\n    ret nz\n    ld a, [wYCoord]\n    cp 9\n    jp z, .door' in after and
              bool(re.search(r'\.azalea\s+ld a, \[wPlayerDirection\]\s+cp PLAYER_DIR_UP\s+jr z, \.azaleaCenterDoor', before)) and
              bool(re.search(r'\.azalea\s+ld a, \[wPlayerDirection\]\s+cp PLAYER_DIR_UP\s+jr z, \.azaleaCenterDoor', after)))
        check('door_return_forces_gold_south_step',
              bool(re.search(r'\.azalea\s+ld a, \[wXCoord\]\s+cp 15\s+ret nz\s+ld a, \[wYCoord\]\s+cp 9\s+jp z, \.south', arrival)) and
              '.south\n    ld e, D_DOWN\n    ret' in arrival)
        collision = room.split('JohtoSharedCenterDownCollision336::',1)[1].split('SetLastBlackoutMapRegional::',1)[0]
        check('same_down_only_exit_and_finite_bounds',
              bool(re.search(r'cp '+CENTER+r'\s+jr z, \.center\s+cp JOHTO_VIOLET_POKECENTER_1F_LOCAL_ID\s+jr z, \.center\s+cp JOHTO_GOLDENROD_POKECENTER_1F_LOCAL_ID\s+jr z, \.center\s+cp JOHTO_ECRUTEAK_POKECENTER_1F_LOCAL_ID\s+jr z, \.center\s+cp JOHTO_OLIVINE_POKECENTER_1F_LOCAL_ID\s+jr z, \.center\s+cp JOHTO_CIANWOOD_POKECENTER_1F_LOCAL_ID\s+jr z, \.center\s+cp JOHTO_MAHOGANY_POKECENTER_1F_LOCAL_ID\s+ret nz\s+\.center\s+ld a, \[wPlayerDirection\]\s+cp PLAYER_DIR_DOWN\s+ret nz\s+ld a, \[wYCoord\]\s+cp 7\s+ret nz\s+ld a, \[wXCoord\]\s+cp 3\s+jr z, \.allow\s+cp 4\s+ret nz',collision)) and
              'db '+CENTER+', 10, 8' in guard and
              'ASSERT JohtoVerticalGateBoundsProfilesEnd314 - JohtoVerticalGateBoundsProfiles314 == 37' in guard and
              'cp '+CENTER+'\n    jp z, .verticalGateClosedEdge314' in runtime)
        check('treatment_success_records_135_not_other_centers',
              bool(re.search(r'cp '+CENTER+r'\s+jr z, \.johto', nurse)) and
              'call WaitForSongToFinish' in nurse and
              'ld a, [wCurLocalMapID]\n    ld [wJohtoLastHealLocalID], a' in nurse and
              'cp '+CENTER+'\n    jr z, .azaleaHeal' in runtime and
              '.azaleaHeal\n    ld e, 11' in runtime)
        check('town_map_music_and_no_extra_fly_stop',
              'db 140, 76' in names and
              'dw JohtoPilotSouthAzaleaName\n    db 76, 92' in names and
              'db 11 ; slot49 Azalea Center inherits city browse index' in read('engine/fly_town_map_helpers.asm') and
              'db MUSIC_GBP_GSC_POKEMON_CENTER ; slot49 Azalea Center' in read('engine/menu/options_menu.asm') and
              'DEF JOHTO_FLY_TOWN_COUNT EQU 11' in fly and
              'cp '+CENTER in fly and
              'cp JOHTO_ROUTE_32_POKECENTER_1F_LOCAL_ID' not in fly)
        start = fly.split('\n.startShortcut\n',1)[1].split('\n.specialAxis\n',1)[0]
        check('fly_start_existing_azalea_unlocked_only',
              'cp '+CENTER in start and
              'ld a, 3' in start and 'ld a, 1' in start and
              'call .isUnlocked\n    jr z, .startRestore' in start and
              'ld [wFlyLocationsAxis], a' in start and
              'ld [wWhichTownMapLocation], a' in start and
              'ld [wJohtoFlySelectedLocalID], a' not in start)
        if gold_root:
            gold = GoldCollisionIndex(gold_root)
            ref = Path(gold_root)/'maps'/'Pokecenter1F.blk'
            check('gold_original_entrance_and_dual_carpets',
                  gold.role_at('AzaleaTown', 15, 9) == 'DOOR' and
                  all(gold.role_at('AzaleaPokecenter1F', x, 7) == 'WARP_CARPET_DOWN' for x in (3,4)) and
                  raw == ref.read_bytes())
    except (OSError, KeyError, ValueError, IndexError, TypeError) as exc:
        errors.append('input_error: '+str(exc))
    return {'status':'PASS_STATIC_ONLY' if not errors else 'FAIL',
            'checks':checks, 'errors':errors, 'rom_built':False, 'phone_accepted':False}


if __name__ == '__main__':
    cli=argparse.ArgumentParser()
    cli.add_argument('--project',type=Path,default=Path.cwd())
    cli.add_argument('--gold-root',type=Path)
    args=cli.parse_args()
    r=audit(args.project,args.gold_root)
    print(json.dumps(r,ensure_ascii=False,indent=2))
    raise SystemExit(bool(r['errors']))
