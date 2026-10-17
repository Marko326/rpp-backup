#!/usr/bin/env python3
"""P16 independent Gold-gated south gate runtime source contract, no ROM build.

Only Azalea <-> south gate is live. Forest itself is not a registered destination.
"""
from pathlib import Path
import json
from johto_indoor_common import gold_warps, rpp_warps, ConversionError

FILES = ('home/overworld.asm', 'data/mapObjects/JohtoAzaleaTown.asm',
         'data/mapObjects/JohtoIlexAzaleaGate.asm',
         'data/mapHeaders/JohtoIlexAzaleaGate.asm',
         'engine/overworld/region_map_lookup.asm',
         'engine/overworld/johto_route33_collision.asm',
         'engine/overworld/player_state.asm',
         'engine/overworld/map_name_sign.asm',
         'constants/region_map_constants.asm',
         'data/johto_map_headers.asm',
         'tools/johto_native_maps.json', 'tools/johto_door_contracts.json',
         'data/game_version.asm', 'maps/JohtoAzaleaTown.blocked_mask.bin',
         'maps/JohtoAzaleaTown.blk', 'gfx/blocksets/johto_modern.bst')

def audit(rpp: Path, gold: Path):
    errors=[]
    rpp,gold=Path(rpp),Path(gold)
    if any(not (rpp/f).is_file() for f in FILES):
        return ['P16 source contract incomplete']
    if any(not (gold/f).is_file() for f in ('maps/AzaleaTown.asm',
                         'maps/IlexForestAzaleaGate.asm','maps/EastWestGate.blk')):
        return ['P16 Gold originals incomplete']
    def expect(v, msg):
        if not v: errors.append(msg)
    try:
        town=rpp_warps(rpp,'JohtoAzaleaTown')
        gate=rpp_warps(rpp,'JohtoIlexAzaleaGate')
    except ConversionError as exc:
        return ['P16 gate return Warp invalid: '+str(exc)]
    expect([(v['x'],v['y'],v['dest_id'],v['dest_map']) for v in town] ==
           [(2,10,0,'REGION_WARP_ESCAPE'),(2,11,1,'REGION_WARP_ESCAPE')],
           'P16 town gate Warp must be exactly the two Gold x2 entrances')
    expect([(v['x'],v['y'],v['dest_id'],v['dest_map']) for v in gate] ==
           [(9,4,0,'REGION_WARP_ESCAPE'),(9,5,1,'REGION_WARP_ESCAPE')],
           'P16 gate return Warp must be exactly the two Gold east exits; west sealed')
    goldtown=gold_warps(gold,'AzaleaTown')
    goldgate=gold_warps(gold,'IlexForestAzaleaGate')
    expect([(v['x'],v['y'],v['dest_map'],v['dest_id']) for v in goldtown[6:]] ==
           [(2,10,'ILEX_FOREST_AZALEA_GATE',3),(2,11,'ILEX_FOREST_AZALEA_GATE',4)],
           'P16 Gold town gate pairing changed')
    expect([(v['x'],v['y'],v['dest_map'],v['dest_id']) for v in goldgate[2:]] ==
           [(9,4,'AZALEA_TOWN',7),(9,5,'AZALEA_TOWN',8)],
           'P16 Gold gate return pairing changed')
    expect((rpp/'maps/JohtoIlexAzaleaGate.blk').read_bytes() ==
           (rpp/'maps/JohtoRoute31VioletGate.blk').read_bytes(),
           'P16 gate cannot reuse previously accepted JOHTO_GATE art')
    src=(rpp/'engine/overworld/region_map_lookup.asm').read_text()
    regionrows=src.split('NativeRegionWarpTargets::',1)[1].split('db $ff',1)[0]
    required=(
       'db JOHTO_AZALEA_TOWN_LOCAL_ID, 0, 0, MAP_REGION_JOHTO, JOHTO_ILEX_AZALEA_GATE_LOCAL_ID',
       'db JOHTO_AZALEA_TOWN_LOCAL_ID, 1, 1, MAP_REGION_JOHTO, JOHTO_ILEX_AZALEA_GATE_LOCAL_ID',
       'db JOHTO_ILEX_AZALEA_GATE_LOCAL_ID, 0, 0, MAP_REGION_JOHTO, JOHTO_AZALEA_TOWN_LOCAL_ID',
       'db JOHTO_ILEX_AZALEA_GATE_LOCAL_ID, 1, 1, MAP_REGION_JOHTO, JOHTO_AZALEA_TOWN_LOCAL_ID',
    )
    expect(all(regionrows.count(r)==1 for r in required), 'P16 native two-way warp mapping missing/wrong')
    expect('JOHTO_ILEX_FOREST_LOCAL_ID' not in regionrows,
           'P16 must not register a Forest target')
    keys=(rpp/'constants/region_map_constants.asm').read_text()
    expect('DEF JOHTO_ILEX_AZALEA_GATE_LOCAL_ID EQU 11' in keys and
           'DEF NUM_JOHTO_MAPS EQU 12' in keys, 'P16 gate local id invalid')
    maphead=(rpp/'data/mapHeaders/JohtoIlexAzaleaGate.asm').read_text()
    expect('db JOHTO_GATE' in maphead and 'db 4, 5' in maphead and
           'db $00 ; indoor gate' in maphead, 'P16 gate header/tileset wrong')
    asm=(rpp/'engine/overworld/johto_route33_collision.asm').read_text()
    section=asm.split('JohtoAzaleaCanStepAhead::',1)[-1].split('JohtoAzaleaGateWarpTileCheck::',1)[0]
    expect(all(v in section for v in ('cp PLAYER_DIR_LEFT','cp 3','cp 10','cp 11',
                                      'cp 2','cp PLAYER_DIR_UP','cp PLAYER_DIR_DOWN',
                                      '.upperCarpet', '.enterGate')),
           'P16 Azalea gate carpet must walk vertically and enter only from x=3')
    expect('.upperCarpet\n\tld a, [wPlayerDirection]\n\tcp PLAYER_DIR_DOWN\n\tjr z, .allowed' in section and
           'cp PLAYER_DIR_UP\n\tjr z, .allowed' in section and
           'cp PLAYER_DIR_LEFT\n\tjr nz, .eastConnection' in section,
           'P16 gate carpet direction-specific vertical/left exception invalid')
    player=(rpp/'engine/overworld/player_state.asm').read_text()
    facing=player.split('\n.facingLeft\n',1)[-1].split('\n.facingRight\n',1)[0]
    expect(all(v in facing for v in ('cp REGION_NATIVE_MAP_SLOT',
                                      'cp MAP_REGION_JOHTO',
                                      'cp JOHTO_AZALEA_TOWN_LOCAL_ID',
                                      'cp 2', 'cp 10', 'cp 11',
                                      '.route31LeftGate', 'cp JOHTO_ROUTE_31')),
           'P16 left collision must recognize only Azalea x2 gate lanes and preserve Route31')
    expect('JohtoAzaleaGateWarpTileCheck' not in asm + player,
           'P16 south gate must not auto-teleport from standing on the carpet')
    home=(rpp/'home/overworld.asm').read_text()
    entry=home.split('CheckWarpsNoCollisionLoop::',1)[-1].split('CheckWarpsCollision::',1)[0]
    exit=home.split('CheckWarpsCollision::',1)[-1].split('CheckWarpsNoCollisionRetry1::',1)[0]
    helper=home.split('IsJohtoSouthGatePortal::',1)[-1].split('ExtraWarpCheck::',1)[0]
    expect(all(v in entry for v in ('call IsJohtoSouthGatePortal',
                                   '.checkOrdinaryWarpTile',
                                   'jp CheckWarpsNoCollisionRetry2',
                                   'callba IsPlayerStandingOnDoorTileOrWarpTile')) and
           entry.index('call IsJohtoSouthGatePortal') <
           entry.index('callba IsPlayerStandingOnDoorTileOrWarpTile'),
           'P16 step-on auto-warp must be suppressed before normal tile detection')
    expect(all(v in exit for v in ('call IsJohtoSouthGatePortal',
                                  'cp JOHTO_AZALEA_TOWN_LOCAL_ID',
                                  'cp PLAYER_DIR_LEFT', 'cp PLAYER_DIR_RIGHT',
                                  'jr nz, .retry2')) and
           exit.index('call IsJohtoSouthGatePortal') < exit.index('ld [wDestinationWarpID],a'),
           'P16 collision Warp must require west outdoors/east indoors')
    expect(all(v in helper for v in ('cp REGION_NATIVE_MAP_SLOT',
                                    'cp MAP_REGION_JOHTO',
                                    'cp JOHTO_AZALEA_TOWN_LOCAL_ID',
                                    'cp JOHTO_ILEX_AZALEA_GATE_LOCAL_ID')),
           'P16 gate source identity must distinguish both native maps')
    sign=(rpp/'engine/overworld/map_name_sign.asm').read_text()
    native_sign=sign.split('\n.IsNeutralMap\n',1)[-1].split('\n.NeutralMapList\n',1)[0]
    expect(all(v in native_sign for v in (
               'cp REGION_NATIVE_MAP_SLOT', 'cp MAP_REGION_JOHTO',
               'cp JOHTO_ILEX_AZALEA_GATE_LOCAL_ID', 'ret z', '.legacyMap',
               'ld hl, .NeutralMapList')) and
           native_sign.index('cp JOHTO_ILEX_AZALEA_GATE_LOCAL_ID') <
           native_sign.index('ld hl, .NeutralMapList'),
           'P16 native gate map-name popup must be neutral without suppressing other $FC maps')
    # Both full map entry and seamless Route33 connection rebuild the map buffer.
    # Check both paths separately; P16B only covered the full-load route.
    render=asm.split('PatchJohtoAzaleaWestGateBorder::',1)[-1].split('JohtoModernMaskedStep::',1)[0]
    full=home.split('LoadMapData::',1)[-1].split('; HAX: Padding',1)[0]
    connected=home.split('.ordinaryConnection\n',1)[-1].split('.didNotEnterConnectedMap',1)[0]
    hook='callba PatchJohtoAzaleaWestGateBorder'
    expect(home.count(hook)==2 and
           all(path.count('call LoadTileBlockMap')==1 and path.count(hook)==1 and
               path.index('call LoadTileBlockMap') < path.index(hook) for path in (full, connected)) and
           full.index(hook)<full.index('call LoadCurrentMapView') and
           connected.index(hook)<connected.index('jp OverworldLoopLessDelay'),
           'P16 west gate border BOTH full Warp and seamless connected-map entry paths')
    expect(all(v in render for v in (
               'cp REGION_NATIVE_MAP_SLOT','cp MAP_REGION_JOHTO',
               'cp JOHTO_AZALEA_TOWN_LOCAL_ID',
               'wOverworldMap + (MAP_BORDER + 4) * (JOHTO_AZALEA_TOWN_WIDTH + 2 * MAP_BORDER) + MAP_BORDER - 1',
               'wOverworldMap + (MAP_BORDER + 5) * (JOHTO_AZALEA_TOWN_WIDTH + 2 * MAP_BORDER) + MAP_BORDER - 1',
               'ld [hl], $08', 'ld [hl], $1c')),
           'P16 west gate border LEFT Gold building halves, not duplicate right halves')
    azalea_map=(rpp/'maps/JohtoAzaleaTown.blk').read_bytes()
    modern=(rpp/'gfx/blocksets/johto_modern.bst').read_bytes()
    original=(gold/'data/tilesets/johto_modern_metatiles.bin').read_bytes()
    expect(len(azalea_map)==180 and azalea_map[4*20]==0x09 and
           azalea_map[5*20]==0x1e and len(modern)>=0x1f*16 and
           all(modern[n*16:(n+1)*16]==original[n*16:(n+1)*16]
               for n in (0x08,0x09,0x1c,0x1e)),
           'P16 Gold left/right building block pairs source-exact')
    # Source data declares Gold WARP_CARPET_LEFT at x2/10-11, however the
    # blocked mask legitimately marks it blocked. Directional runtime exceptions
    # (above) are mandatory; passability is NOT proved by a Warp object alone.
    blocked=(rpp/'maps/JohtoAzaleaTown.blocked_mask.bin').read_bytes()
    def is_blocked(x,y): return bool(blocked[y*5 + x//8] & (1<<(x%8)))
    expect(len(blocked)==90 and all(is_blocked(2,y) for y in (9,10,11,12)) and
           all(not is_blocked(3,y) for y in (10,11)),
           'P16 Gold doorway collision mask changed; reevaluate directional exception')
    door_contract=json.loads((rpp/'tools/johto_door_contracts.json').read_text())
    azalea_door=next((m for m in door_contract['active_warp_maps']
                       if m['rpp_map']=='JohtoAzaleaTown'), {})
    expect(azalea_door.get('visual_border_status')=='STATIC_CANDIDATE_PHONE_PENDING',
           'P16 exterior west border is not phone verified; do not mark visually accepted')
    reg=json.loads((rpp/'tools/johto_native_maps.json').read_text())
    gate_meta=reg['maps'][-1]
    expect(gate_meta['local_id']==11 and gate_meta['feature_status']['warp']=='ALLOWED' and
           gate_meta['feature_status']['fly']=='DEFERRED' and
           gate_meta['feature_status']['surf']=='DEFERRED',
           'P16 gate permission metadata not explicit')
    expect(len(reg['maps'])==12 and not any('ILEX_FOREST_LOCAL_ID' in x['local_symbol'] for x in reg['maps']),
           'P16 Forest opened without source/tileset registration')
    return errors
