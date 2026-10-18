#!/usr/bin/env python3
"""P16 east gate preservation contract; P17 west gate is checked separately.

Keep the already accepted Azalea/east-gate source and render behavior intact.
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
    expect([(v['x'],v['y'],v['dest_id'],v['dest_map']) for v in gate[:2]] ==
           [(9,4,0,'REGION_WARP_ESCAPE'),(9,5,1,'REGION_WARP_ESCAPE')],
           'P16 gate return Warp must retain the two Gold east exits')
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
    keys=(rpp/'constants/region_map_constants.asm').read_text()
    expect('DEF JOHTO_ILEX_AZALEA_GATE_LOCAL_ID EQU 11' in keys and
           'DEF NUM_JOHTO_MAPS EQU 13' in keys, 'P16 gate local id invalid')
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
    gate_meta=next(x for x in reg['maps'] if x['local_id']==11)
    expect(gate_meta['local_id']==11 and gate_meta['feature_status']['warp']=='ALLOWED' and
           gate_meta['feature_status']['fly']=='DEFERRED' and
           gate_meta['feature_status']['surf']=='DEFERRED',
           'P16 gate permission metadata not explicit')
    return errors

# P17 proof is an extension of the existing gate audit, NOT another Gold parser.
# All Gold Warp decoding is delegated to johto_indoor_common. Forest
# resources start from the generic Gold pipeline and acquire only verified
# pixel-identical native ledge-pair tile/block adaptations.
FOREST_FILES = (
    'data/mapObjects/JohtoIlexForest.asm', 'data/mapHeaders/JohtoIlexForest.asm',
    'maps/JohtoIlexForest.blk', 'maps/JohtoIlexForest.blocked_mask.bin',
    'gfx/blocksets/johto_ilex_forest.bst', 'gfx/tilesets/johto_ilex_forest.png',
    'color/tilesets/johto_ilex_forest.asm',
    'engine/overworld/johto_ilex_forest_collision.asm', 'engine/overworld/ledges.asm',
    'data/mapObjects/JohtoIlexAzaleaGate.asm', 'home/overworld.asm',
    'engine/overworld/region_map_lookup.asm', 'engine/overworld/johto_route33_collision.asm',
    'constants/region_map_constants.asm', 'data/johto_map_headers.asm',
    'data/tileset_headers.asm', 'engine/overworld/tileset_header.asm',
    'engine/overworld/player_state.asm', 'color/loadpalettes.asm', 'main.asm', 'Makefile',
)
FOREST_HOP_CELLS = ((22,2),(24,2),(25,2),(15,14),(15,15),(23,22),(24,22),(26,22))


def audit_ilex_forest(rpp: Path, gold: Path) -> list[str]:
    """Fail-closed static source/Gold contract; not a ROM or phone test."""
    rpp, gold = Path(rpp), Path(gold)
    problems = []
    missing = [name for name in FOREST_FILES if not (rpp/name).is_file()]
    if missing:
        return ['P17 forest registration/resources missing: ' + ', '.join(missing)]

    def require(ok, detail):
        if not ok:
            problems.append('P17 '+detail)

    # P17 first phone run exposed a pre-existing 8-bit overflow at tileset 32.
    # Check engine runtime table indexing, not just valid-looking Gold outputs.
    header=(rpp/'engine/overworld/tileset_header.asm').read_text()
    header_index=header.split('LoadTilesetHeader:',1)[-1].split('.copyTilesetHeaderLoop',1)[0]
    require('\tld l, a\n\tld h, 0\n\tadd hl, hl ; id * 2\n\tadd hl, hl ; id * 4\n\tld d, h\n\tld e, l\n\tadd hl, hl ; id * 8\n\tadd hl, de ; id * 12\n\tld de, Tilesets\n\tadd hl, de' in header_index,
            'tileset 32 table offset must be 16-bit ($180, not $080)')
    palette=(rpp/'color/loadpalettes.asm').read_text()
    palette_index=palette.split('LoadTilesetPalette:',1)[-1].split('.nextPalette',1)[0]
    require('\tld d,0\n\tld e,a\n\tsla e\n\trl d\n\tsla e\n\trl d\n\tsla e\n\trl d\n\tld hl, MapPaletteSets' in palette_index,
            'tileset 32 palette offset must be 16-bit ($100, not $000)')

    # The main loop checks ExtraWarpCheck before CheckWarpsCollision. Gold
    # forest x=3 is not the east map edge, so an exact facing-right exception
    # is necessary even with perfectly registered two-way Warp objects.
    overworld=(rpp/'home/overworld.asm').read_text()
    extra=overworld.split('ExtraWarpCheck::',1)[-1].split('IsJohtoSouthGatePortal::',1)[0]
    require(all(v in extra for v in (
        'cp REGION_NATIVE_MAP_SLOT', 'cp MAP_REGION_JOHTO',
        'cp JOHTO_ILEX_FOREST_LOCAL_ID',
        'cp PLAYER_DIR_RIGHT',
        'cp 3\n\tjr nz, .ordinaryCheck',
        'cp 42\n\tjr z, .forestReturns',
        'cp 43\n\tjr nz, .ordinaryCheck',
        '.forestReturns\n\tscf\n\tret',
        '.ordinaryCheck\n\tld a, [wCurMap]'
    )), 'Forest x3/y42,43 right-facing ExtraWarpCheck required for safe return')

    # Forest HOP-only block variants reuse the tested Route29 native tile-pair
    # conversion; the converted blockset and art are intentionally no longer
    # byte-identical to Gold. Every unrelated pixel and palette must still match.
    from johto_rpp_ledge_converter import (build_forest_native_pairs,
             clone_forest_tiles_and_palettes)
    from johto_rpp_asset_audit import collision_labels, gold_resource_aliases
    from PIL import Image
    try:
        labels, _=collision_labels(gold,'forest',gold_resource_aliases(gold))
        if not labels:
            raise ValueError('Gold Forest collision data missing')
        tuples=[tuple(x.strip() for x in row.split(',')) for row in labels]
        mapbytes=(gold/'maps/IlexForest.blk').read_bytes()
        blockbytes=(gold/'data/tilesets/forest_metatiles.bin').read_bytes()
        exp_map,exp_blocks,source_hops,variants=build_forest_native_pairs(
            mapbytes,blockbytes,tuples)
        require((rpp/'maps/JohtoIlexForest.blk').read_bytes()==exp_map,
                'native Forest ledge map variants differ from Gold conversion')
        require((rpp/'gfx/blocksets/johto_ilex_forest.bst').read_bytes()==exp_blocks,
                'native Forest ledge block variants differ from Gold conversion')
        image_path=gold/'gfx/tilesets/forest.png'
        palette_path=gold/'gfx/tilesets/forest_palette_map.asm'
        clone_image,clone_palette=clone_forest_tiles_and_palettes(image_path,palette_path)
        with Image.open(rpp/'gfx/tilesets/johto_ilex_forest.png') as img:
            require(img.size==clone_image.size and img.convert('RGB').tobytes()==
                    clone_image.convert('RGB').tobytes(),
                    'native Forest copied tile art differs from Gold pixels')
        require((rpp/'color/tilesets/johto_ilex_forest.asm').read_text()==clone_palette,
                'native Forest copied tile palettes differ from Gold')
        require(len(source_hops)==10 and variants==5,
                'native Forest ledge pair inventory or clones changed')
    except (ValueError, OSError, IndexError, ImportError) as exc:
        problems.append('P17 native Forest ledge asset conversion: '+str(exc))
    try:
        gate = rpp_warps(rpp, 'JohtoIlexAzaleaGate')
        forest = rpp_warps(rpp, 'JohtoIlexForest')
        gold_gate = gold_warps(gold, 'IlexForestAzaleaGate')
        gold_forest = gold_warps(gold, 'IlexForest')
    except (ConversionError, OSError) as exc:
        return problems + ['P17 forest Warp decoding: '+str(exc)]
    require(len(gate)==4 and [(v['x'],v['y'],v['dest_id'],v['dest_map']) for v in gate] == [
        (9,4,0,'REGION_WARP_ESCAPE'),(9,5,1,'REGION_WARP_ESCAPE'),
        (0,4,0,'REGION_WARP_ESCAPE'),(0,5,1,'REGION_WARP_ESCAPE')],
        'west/east two-lane gate Warp positions or dest changed')
    require(len(forest)==2 and [(v['x'],v['y'],v['dest_id'],v['dest_map']) for v in forest] == [
        (3,42,2,'REGION_WARP_ESCAPE'),(3,43,3,'REGION_WARP_ESCAPE')],
        'south forest double return Warp positions or dest changed')
    require([(v['x'],v['y'],v['dest_map'],v['dest_id']) for v in gold_gate[:2]] == [
        (0,4,'ILEX_FOREST',2),(0,5,'ILEX_FOREST',3)] and
        [(v['x'],v['y'],v['dest_map'],v['dest_id']) for v in gold_forest[1:]] == [
        (3,42,'ILEX_FOREST_AZALEA_GATE',1),(3,43,'ILEX_FOREST_AZALEA_GATE',2)],
        'Gold-original forest double door topology drift')
    registry=(rpp/'engine/overworld/region_map_lookup.asm').read_text()
    rows=registry.split('NativeRegionWarpTargets::',1)[-1].split('db $ff',1)[0]
    for left in (
        'JOHTO_ILEX_AZALEA_GATE_LOCAL_ID, 2, 0, MAP_REGION_JOHTO, JOHTO_ILEX_FOREST_LOCAL_ID',
        'JOHTO_ILEX_AZALEA_GATE_LOCAL_ID, 3, 1, MAP_REGION_JOHTO, JOHTO_ILEX_FOREST_LOCAL_ID',
        'JOHTO_ILEX_FOREST_LOCAL_ID, 0, 2, MAP_REGION_JOHTO, JOHTO_ILEX_AZALEA_GATE_LOCAL_ID',
        'JOHTO_ILEX_FOREST_LOCAL_ID, 1, 3, MAP_REGION_JOHTO, JOHTO_ILEX_AZALEA_GATE_LOCAL_ID',
    ):
        require(rows.count('db '+left)==1, 'native region warp graph missing/duplicated: '+left)
    home=(rpp/'home/overworld.asm').read_text()
    entry=home.split('CheckWarpsNoCollisionLoop::',1)[-1].split('CheckWarpsCollision::',1)[0]
    coll=home.split('CheckWarpsCollision::',1)[-1].split('CheckWarpsNoCollisionRetry1::',1)[0]
    portal=home.split('IsJohtoSouthGatePortal::',1)[-1].split('MapEntryAfterBattle::',1)[0]
    require('call IsJohtoSouthGatePortal' in entry and
            entry.index('call IsJohtoSouthGatePortal') < entry.index('callba IsPlayerStandingOnDoorTileOrWarpTile') and
            'jp CheckWarpsNoCollisionRetry2' in entry,
            'standing carpet must not instantly Warp')
    require(all(x in portal for x in ('cp REGION_NATIVE_MAP_SLOT','cp MAP_REGION_JOHTO',
            'cp JOHTO_AZALEA_TOWN_LOCAL_ID','cp JOHTO_ILEX_AZALEA_GATE_LOCAL_ID',
            'cp JOHTO_ILEX_FOREST_LOCAL_ID')), 'three-region exact portal identity lost')
    require(all(x in coll for x in (
        'cp JOHTO_ILEX_FOREST_LOCAL_ID\n\tjr z, .gateReturnsEast',
        'ld a, [wXCoord]\n\tand a\n\tjr z, .gateGoesWest',
        '.gateGoesWest\n\tld a, [wPlayerDirection]\n\tcp PLAYER_DIR_LEFT',
        '.gateReturnsEast\n\tld a, [wPlayerDirection]\n\tcp PLAYER_DIR_RIGHT',
        'jr nz, .retry2')), 'wrong-direction Warp not blocked')
    step=home.split('CheckTilePassable::',1)[-1].split('predef GetTileAndCoordsInFrontOfPlayer',1)[0]
    require('cp JOHTO_ILEX_FOREST_LOCAL_ID' in step and
            'callba JohtoIlexForestCanStepAhead' in step,
            'forest must use precise Gold quadrant collision mask')
    source=(rpp/'engine/overworld/johto_ilex_forest_collision.asm').read_text()
    for token in ('cp JOHTO_ILEX_FOREST_LOCAL_ID','cp 42','cp 43',
                  'cp PLAYER_DIR_UP','cp PLAYER_DIR_DOWN','cp PLAYER_DIR_RIGHT',
                  'ld hl, JohtoIlexForestBlockedRows','jp JohtoModernMaskedStep',
                  'INCBIN "maps/JohtoIlexForest.blocked_mask.bin"'):
        require(token in source,'forest collision carpet behavior missing '+token)
    masked=(rpp/'engine/overworld/johto_route33_collision.asm').read_text()
    require('ld a, [wCurrentMapHeight2]\n\tcp b' in masked,
            'shared mask must accept 54-cell height without old fixed 18-cell cap')
    mask=(rpp/'maps/JohtoIlexForest.blocked_mask.bin').read_bytes()
    require(len(mask)==54*4,'30x54 forest collision mask length changed')
    if len(mask)==54*4:
        def blocked(x,y): return bool(mask[y*4+x//8] & (1<<(x%8)))
        require(blocked(1,5),'Route34 north exit must remain blocked')
        require(all(blocked(x,y) for x,y in [(3,42),(3,43),(4,42),(4,43)]),
                'double carpet collision must need directional exception')
        require(all(not blocked(x,y) for x,y in [(2,42),(2,43)]),
                'south approach path must remain clear')
        require(all(not blocked(x,y) for x,y in FOREST_HOP_CELLS),
                'Gold forest HOP takeoff cells must be enterable')
        require(all(blocked(x,y) for x,y in ((22,3),(24,3),(25,3),
                    (14,14),(14,15),(23,23),(24,23),(26,23),(22,22),(27,22))),
                'Gold forest ledge wall must remain blocked outside a jump')
        require(blocked(8,25), 'Gold forest Cut tree must remain blocked')
        try:
            from johto_indoor_collision_adapter import plan_gold_quadrant_collision
            geometry, expected_mask = plan_gold_quadrant_collision(gold, 'IlexForest', 'forest')
            require(mask == expected_mask, 'forest mask no longer matches full Gold source')
            # The Gold labels define ten orthogonal jump actions from eight
            # takeoff cells; compound HOP_DOWN_RIGHT is not a diagonal jump.
            expected_hops = {(h['x'],h['y'],h['dx'],h['dy']) for h in
                    geometry['hops'] + geometry['unsafe_hop_candidates']}
            require(len(expected_hops) == 10 and len(geometry['hops']) +
                    len(geometry['unsafe_hop_candidates']) == 10,
                    'Gold Forest HOP role/direction inventory is incomplete')
        except (ValueError, OSError) as exc:
            problems.append('P17 Gold Forest ledge source: ' + str(exc))
            expected_hops = set()
        ledges = (rpp/'engine/overworld/ledges.asm').read_text()
        require(all(code in ledges for code in (
            'cp JOHTO_ILEX_FOREST\n\tjp z, .ilexForest',
            '.ilexForest\n\t; ILEX-5.62.206',
            'cp JOHTO_ILEX_FOREST_LOCAL_ID\n\tret nz\n\tld hl, JohtoIlexForestLedgeTiles\n\tjp .checkPairs',
            'JohtoIlexForestLedgeTiles:\n\tdb SPRITE_FACING_DOWN,  $05,$40,D_DOWN',
            '\tdb SPRITE_FACING_LEFT,  $05,$41,D_LEFT',
            '\tdb SPRITE_FACING_RIGHT, $05,$42,D_RIGHT',
            'cp JOHTO_ILEX_FOREST\n\tld a, $2\n\tjr nz, .hopCountReady\n\tdec a',
        )), 'native Forest ledge tile-pair trigger/facing/two-cell scope missing')
        require('.ilexHops' not in ledges and 'ld hl, .ilexHops' not in ledges,
                'retired Forest coordinate HOP interpreter reintroduced')
        home=(rpp/'home/overworld.asm').read_text()
        require('cp JOHTO_ILEX_FOREST\n\tjr nz, .checkRunningButton\n'
                '\tld a, [wd736]\n\tbit 6, a\n\tjr nz, .notRunning' in home,
                'Forest hopping must not be accelerated by held B')
    hdr=(rpp/'data/mapHeaders/JohtoIlexForest.asm').read_text()
    require('db JOHTO_ILEX_FOREST_HEIGHT, JOHTO_ILEX_FOREST_WIDTH' in hdr and
            'db $00 ; original Route34 gate is not implemented' in hdr,
            'map dimensions/north connection not safely registered')
    main=(rpp/'main.asm').read_text()
    require('SECTION "Johto Ilex Forest Tileset", ROMX, BANK[$44]' in main and
            'SECTION "Johto Ilex Forest Collision Mask", ROMX, BANK[$43]' in main and
            'SECTION "Johto Route33 Collision Mask", ROMX, BANK[$43]' in main,
            'forest sections/bank locality not proven in source')
    return problems
