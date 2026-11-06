#!/usr/bin/env python3
"""REF-333 Route32 Union Cave roadside center: Gold/source/Warp contract.

Static only; never builds ROM or claims mobile gameplay acceptance. Each
check is fail-closed and supports in-memory mutation testing.
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

OLD = 'JOHTO_CHERRYGROVE_POKECENTER_1F_LOCAL_ID'
NEW = 'JOHTO_ROUTE_32_POKECENTER_1F_LOCAL_ID'
ROAD = 'JOHTO_ROUTE_32_LOCAL_ID'


def audit(root: Path, gold_root: Path | None = None, overrides: dict | None = None) -> dict:
    root = Path(root)
    overrides = overrides or {}
    checks, errors = [], []

    def get(path, binary=False):
        value = overrides.get(path)
        if value is None:
            value = (root / path).read_bytes()
        elif isinstance(value, str):
            value = value.encode('utf-8')
        return value if binary else value.decode('utf-8')

    def check(name, ok):
        checks.append({'check': name, 'status': 'PASS' if ok else 'FAIL'})
        if not ok:
            errors.append(name)

    try:
        runtime = get('engine/johto_pilot_runtime.asm')
        room = get('engine/johto_shared_pokecenter.asm')
        road = get('data/johto_route32_runtime.asm')
        healer = get('engine/johto_gold_healing_machine_337.asm')
        sign = get('engine/overworld/map_name_sign.asm')
        fly = get('engine/johto_pilot_fly_map.asm')
        browse = get('engine/fly_town_map_helpers.asm')
        slots = get('data/johto_stable_id_slots.asm')
        headers = get('data/johto_header_descriptors.asm')
        objects = room.split('JohtoRoute32PokecenterRuntimeObjects::', 1)[1].split('JohtoSharedCenterDownCollision336::', 1)[0]
        # Unique stable-ID/slot; original slot 47 must retain Cherrygrove.
        check('identity_and_append_only',
              'DEF NUM_JOHTO_ACTIVE_MAPS EQU 64' in get('constants/region_map_constants.asm') and
              'ASSERT NUM_JOHTO_ACTIVE_MAPS == 64' in get('data/johto_pilot_runtime_assets.asm') and
              bool(re.search(r'(?m)^\s*db[^\n]*\b48\s*,[^\n]*; \$60-\$6f', slots)) and
              'dw JohtoRoute32PokecenterRuntimeHeader' in headers and
              'db BANK(JohtoRoute32PokecenterRuntimeHeader)' in headers and
              'ASSERT '+NEW+' == 106' in room)
        # Both 20-byte layouts remain unmodified, with source Gold identity.
        raw = get('maps/johto_pilot/Route32Pokecenter1F.gold.blk', True)
        shared = get('maps/johto_pilot/CherrygrovePokecenter1F.gold.blk', True)
        check('gold_5x4_room_asset', len(raw) == 20 and raw == shared and
              get('maps/johto_pilot/Route32Pokecenter1F.runtime.blk', True) ==
              get('maps/johto_pilot/CherrygrovePokecenter1F.runtime.blk', True))
        check('standalone_header_reuses_gold_room_and_nurse',
              bool(re.search(r'JohtoRoute32PokecenterRuntimeHeader::.*?dw JohtoSharedPokecenterRuntimeBlocks.*?dw JohtoSharedPokecenterTextPointers.*?dw JohtoSharedPokecenterMapScript.*?dw JohtoRoute32PokecenterRuntimeObjects', room, re.S)) and
              'object SPRITE_NURSE, $3, $1, STAY, DOWN, $1' in objects)
        check('outdoor_warp_preserves_three_old_ordinals',
              [line.strip().split(';',1)[0].strip() for line in road.split('JohtoPilotRoute32RuntimeObjects::',1)[1].splitlines()[:6]] == [
                  '', 'db $05', 'db 4',
                  'db 2, 4, 2, JOHTO_REGISTERED_WARP_SELECTOR',
                  'db 3, 4, 3, JOHTO_REGISTERED_WARP_SELECTOR',
                  'db 79, 6, 0, JOHTO_REGISTERED_WARP_SELECTOR'] and
              'db 73, 11, 0, JOHTO_REGISTERED_WARP_SELECTOR' in road)
        check('indoor_carpet_two_returns_to_route32',
              'db 7, 3, 3, JOHTO_REGISTERED_WARP_SELECTOR' in objects and
              'db 7, 4, 3, JOHTO_REGISTERED_WARP_SELECTOR' in objects and
              'db 0 ; PC/2F remain closed' in objects)
        routes = runtime.split('JohtoRegisteredWarpRoutes::', 1)[1].split('JohtoRegisteredWarpRoutesEnd::', 1)[0]
        check('three_exact_registered_routes', all(routes.count(x) == 1 for x in (
            'db MAP_REGION_JOHTO, '+ROAD+', 3, MAP_REGION_JOHTO, '+NEW,
            'db MAP_REGION_JOHTO, '+NEW+', 0, MAP_REGION_JOHTO, '+ROAD,
            'db MAP_REGION_JOHTO, '+NEW+', 1, MAP_REGION_JOHTO, '+ROAD)))
        # Upward approach must reach the new (11,73) door, not old cave at (6,79).
        land = get('engine/johto_land_collision_gateway_272.asm')
        check('north_door_pre_step_and_collision',
              'cp JOHTO_ROUTE_32_LOCAL_ID' in land and 'cp 74' in land and
              'cp 11' in land and
              bool(re.search(r'\.route32Alph\s+ld a, \[wPlayerDirection\]\s+cp PLAYER_DIR_UP\s+jr z, \.route32NorthDoor', runtime)) and
              '.route32NorthDoor\n    ld a, [wXCoord]\n    cp 11' in runtime and
              'cp 74\n    jp z, .allow' in runtime)
        check('north_door_post_step_warp_and_cave_preserved',
              len(re.findall(r'\.route32Alph\s+ld a, \[wPlayerDirection\]\s+cp PLAYER_DIR_UP\s+jr z, \.route32NorthDoor',runtime)) == 2 and
              'cp 73\n    jp z, .yesDoor' in runtime and
              'cp 79\n    ret nz\n    jp .yesDoor' in runtime)
        check('all_centers_only_down_exit',
              bool(re.search(r'JohtoSharedCenterDownCollision336::.*?cp '+OLD+r'.*?cp '+NEW+r'.*?cp JOHTO_AZALEA_POKECENTER_1F_LOCAL_ID.*?cp JOHTO_VIOLET_POKECENTER_1F_LOCAL_ID.*?cp JOHTO_GOLDENROD_POKECENTER_1F_LOCAL_ID\s+jr z, \.center\s+cp JOHTO_ECRUTEAK_POKECENTER_1F_LOCAL_ID\s+jr z, \.center\s+cp JOHTO_OLIVINE_POKECENTER_1F_LOCAL_ID\s+jr z, \.center\s+cp JOHTO_CIANWOOD_POKECENTER_1F_LOCAL_ID\s+jr z, \.center\s+cp JOHTO_MAHOGANY_POKECENTER_1F_LOCAL_ID.*?cp PLAYER_DIR_DOWN.*?cp 7.*?cp 3.*?cp 4', room, re.S)) and
              room.count('object SPRITE_NURSE, $3, $1, STAY, DOWN, $1') == 10)
        check('healing_stamps_actual_center_not_cherrygrove',
              bool(re.search(r'AnimateHealingMachineRegional337::.*?cp '+OLD+r'\s+jr z, \.johto\s+cp '+NEW+r'\s+jr z, \.johto',healer,re.S)) and
              'call WaitForSongToFinish' in healer and
              'ld a, [wCurLocalMapID]\n    ld [wJohtoLastHealLocalID], a' in healer)
        check('town_map_uses_route32_without_new_fly',
              'cp '+NEW+'\n    jr z, .route32Heal' in runtime and
              '.route32Heal\n    ld e, 7' in runtime and
              'dw JohtoPilotRoute32Name' in browse and
              NEW not in fly and 'Route32Pokecenter' not in fly and
              'db 7 ; slot48 Route32 Center' in browse)
        check('route32_name_sign_and_music',
              'cp '+NEW in sign and
              'johto_map_profile 0, 7, MUSIC_POKECENTER, 0 ; slot48' in runtime and
              'db MUSIC_GBP_GSC_POKEMON_CENTER' in get('engine/menu/options_menu.asm'))
        if gold_root is not None:
            gold = GoldCollisionIndex(gold_root)
            check('gold_original_door_and_carpets',
                  gold.role_at('Route32',11,73) == 'DOOR' and
                  gold.role_at('Route32',11,74) != 'DOOR' and
                  all(gold.role_at('Route32Pokecenter1F',x,7) == 'WARP_CARPET_DOWN' for x in (3,4)) and
                  raw == (Path(gold_root)/'maps'/'Pokecenter1F.blk').read_bytes())
    except (OSError, ValueError, IndexError, KeyError) as exc:
        check('required_sources_present', False)
        errors.append('input_error: '+str(exc))
    return dict(status='PASS_STATIC_ONLY' if not errors else 'FAIL', checks=checks,
                errors=errors, rom_built=False, phone_accepted=False)


if __name__ == '__main__':
    parser = argparse.ArgumentParser()
    parser.add_argument('--project',type=Path,default=Path.cwd())
    parser.add_argument('--gold-root',type=Path)
    args = parser.parse_args()
    report = audit(args.project,args.gold_root)
    print(json.dumps(report,ensure_ascii=False,indent=2))
    raise SystemExit(bool(report['errors']))
