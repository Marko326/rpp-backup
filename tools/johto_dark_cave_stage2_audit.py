#!/usr/bin/env python3
"""REF-349 strict Gold-role and Route31/Route46 two-exit audit; source-only."""
from __future__ import annotations
from pathlib import Path
from collections import Counter
import json,re
try:
    from johto_dark_cave_stage_349 import check as gold_check, BLOCKS, COLL
except ImportError:
    from tools.johto_dark_cave_stage_349 import check as gold_check, BLOCKS, COLL

ROLE={'FLOOR':0,'WALL':1,'WATER':2,'UP_WALL':3,'HOP_DOWN':4,'HOP_LEFT':5,'WARP_CARPET_DOWN':6,'CAVE':7}
def check(root:Path,overrides:dict[str,str|bytes]|None=None)->list[str]:
    root=Path(root); overrides=overrides or {}; errs=[]
    def raw(p):
        if p in overrides:
            v=overrides[p]
            return v.encode() if isinstance(v,str) else v
        return (root/p).read_bytes()
    def txt(p):return raw(p).decode()
    def yes(p,label):
        if not p:errs.append(label)
    try:
        errs += gold_check(root, overrides={p:v for p,v in overrides.items() if p in (BLOCKS,COLL,'docs/REF349_DARK_CAVE_VIOLET_STAGE1.json')})
        gold=raw(BLOCKS); coll=txt(COLL)
        blocks={int(m.group(2),16):[r.strip() for r in m.group(1).split(',')]
                for m in re.finditer(r'\btilecoll\s+([^;]+);\s*([0-9a-fA-F]{2})\b',coll)}
        expectation=bytes(ROLE[blocks[gold[y//2*20+x//2]][(y%2)*2+x%2]] for y in range(36) for x in range(40))
        roles=raw('data/johto_dark_cave_stage/DarkCaveVioletEntrance.roles.bin')
        yes(roles==expectation and len(roles)==1440,'role grid not identical to Gold')
        yes(roles[15*40+3]==6 and roles[1*40+17]==7 and roles[33*40+35]==6,'Gold cave exits role mismatch')
        assert len(roles)==1440
        yes(Counter(roles)==Counter({0:1002,1:296,2:64,3:41,4:12,5:14,6:10,7:1}),'role totals wrong')
        # Test the *executed two-step jump*, not just the declared number of
        # ledges. The original REF349 test mistakenly shifted the source one
        # square behind Gold's HOP cell, so all 26 simulated landings were WALL.
        hops=[(x,y,'PLAYER_DIR_DOWN') for y in range(36) for x in range(40) if roles[y*40+x]==4]
        hops += [(x,y,'PLAYER_DIR_LEFT') for y in range(36) for x in range(40) if roles[y*40+x]==5]
        for x,y,direction in hops:
            dx,dy=(0,1) if direction=='PLAYER_DIR_DOWN' else (-1,0)
            intermediate=(x+dx,y+dy)
            landing=(x+2*dx,y+2*dy)
            yes(0<=landing[0]<40 and 0<=landing[1]<36 and
                roles[intermediate[1]*40+intermediate[0]]==1 and
                roles[landing[1]*40+landing[0]] not in (1,7),
                f'Gold hop path must cross WALL then land on walkable terrain: {(x,y,direction)}')
        ledges=txt('engine/overworld/ledges.asm')
        live_hops=re.search(r'JohtoDarkCaveGoldHops:\n(.*?)\nJohtoBurnedTowerB1FGoldHops:',ledges,re.S)
        got=[(int(x),int(y),d) for x,y,d in re.findall(r'(?m)^\s*db (\d+), (\d+), (PLAYER_DIR_\w+)\s*$', live_hops[1] if live_hops else '')]
        yes(len(got)==26 and len(set(got))==26 and set(got)==set(hops),
            '26 directed Gold HOP cells must be literal takeoff points, not the preceding tiles')
        yes('jp .ruinsCoordinateHopLookup' in ledges.split('\n.darkCave\n',1)[1].split('\n.burnedTowerB1F\n',1)[0] and
            'ld [wSimulatedJoypadStatesEnd + 1], a' in ledges and
            'ld [wSimulatedJoypadStatesIndex], a' in ledges,
            'Dark Cave hops must dispatch to the common two-step ledge executor')
        yes('jp z, .darkCave' in ledges.split('JohtoSouthHopLandingGuard::',1)[1] and
            'ld hl, JohtoDarkCaveGoldHops' in ledges.split('JohtoSouthHopLandingGuard::',1)[1],
            'Dark Cave two-step landing guard missing')
        # DEVICE FIX: the first collision gateway executes before HandleLedges.
        # It must guard map bounds only, not reject the WALL ahead of each HOP.
        pilot=txt('engine/johto_pilot_runtime.asm')
        edge=(pilot.split('\n.darkCaveClosedEdge\n',1)[-1]
              .split('\n.unionCaveClosedEdge\n',1)[0])
        yes('\n.darkCaveClosedEdge\n' in pilot and
            'callab JohtoDarkCaveLandDecision' not in edge and
            all(f'cp {direction}' in edge for direction in
                ('PLAYER_DIR_UP','PLAYER_DIR_DOWN','PLAYER_DIR_LEFT','PLAYER_DIR_RIGHT')) and
            'cp JOHTO_DARK_CAVE_WIDTH * 2 - 1' in edge and
            'cp JOHTO_DARK_CAVE_HEIGHT * 2 - 1' in edge and
            '.darkCaveNorthEdge' in edge and '.darkCaveSouthEdge' in edge and
            '.darkCaveWestEdge' in edge and
            edge.count('jp z, .closed')>=2 and edge.count('jp nc, .closed')>=2,
            'Dark Cave edge gateway must check map bounds, not internal HOP-adjacent WALL')
        world=txt('home/overworld.asm')
        onland=world.split('CollisionCheckOnLand::',1)[-1].split('\n.checkedJohtoEdge\n',1)[0]
        yes('callab JohtoPilotIsClosedOutdoorEdge' in onland and
            'jp nz,.collision' in onland,
            'early collision gateway path changed; recheck Gold HOP bypass')
        gateway=txt('engine/johto_land_collision_gateway_272.asm')
        cave_gateway=gateway.split('\n.darkCave\n',1)[-1].split('\n.unionCave\n',1)[0]
        yes('callab HandleLedges' in cave_gateway and
            'callab JohtoDarkCaveLandDecision' in cave_gateway and
            cave_gateway.index('callab HandleLedges') < cave_gateway.index('callab JohtoDarkCaveLandDecision') and
            'bit 6, a' in cave_gateway and '.allowJump' in cave_gateway,
            'Dark Cave must execute ledge handler before internal Gold wall collision')
        for x,y,d in hops:
            dx,dy=(0,1) if d=='PLAYER_DIR_DOWN' else (-1,0)
            yes(0<x+dx<39 and 0<y+dy<35 and roles[(y+dy)*40+(x+dx)]==1,
                f'{(x,y,d)} crosses interior wall, must not be stopped by edge gate')
        run=txt('data/johto_dark_cave_stage/REF349_stage2_runtime.asm')
        yes('ASSERT @ - JohtoDarkCave_GFX == 65 * 16' in run,
            'graphics length ASSERT must match Makefile trimmed output (65 tiles / 1040 bytes)')
        # Preserve Gold's three source ordinals; the Blackthorn room stays sealed.
        cave_warps=re.findall(r'(?m)^\s*db (?:\$[0-9a-fA-F]+|\d+), (?:\$[0-9a-fA-F]+|\d+), (?:\d+), JOHTO_REGISTERED_WARP_SELECTOR', run)
        yes('db 3   ; Gold indices' in run and len(cave_warps)==3 and
            'db 15, 3, 2, JOHTO_REGISTERED_WARP_SELECTOR' in run and
            'db $ff, $ff, 0, JOHTO_REGISTERED_WARP_SELECTOR' in run and
            'db 33, 35, 2, JOHTO_REGISTERED_WARP_SELECTOR' in run,
            'Gold cave warp ordinals0/1/2 or sealed Blackthorn placeholder broken')
        warp=txt('engine/johto_pilot_runtime.asm')
        subset=warp.split('JohtoRegisteredWarpRoutes::',1)[1].split('JohtoRegisteredWarpRoutesEnd::',1)[0]
        routes=re.findall(r'(?m)^\s*db MAP_REGION_JOHTO, (JOHTO_\w+_LOCAL_ID), (\d+), MAP_REGION_JOHTO, (JOHTO_\w+_LOCAL_ID)',subset)
        yes(len(routes)==164,'expected exactly 164 registered Johto warps')
        for expected in (
            ('JOHTO_ROUTE_31_LOCAL_ID','2','JOHTO_DARK_CAVE_VIOLET_ENTRANCE_LOCAL_ID'),
            ('JOHTO_DARK_CAVE_VIOLET_ENTRANCE_LOCAL_ID','0','JOHTO_ROUTE_31_LOCAL_ID'),
            ('JOHTO_ROUTE_46_LOCAL_ID','2','JOHTO_DARK_CAVE_VIOLET_ENTRANCE_LOCAL_ID'),
            ('JOHTO_DARK_CAVE_VIOLET_ENTRANCE_LOCAL_ID','2','JOHTO_ROUTE_46_LOCAL_ID')):
            yes(routes.count(expected)==1, f'missing or duplicate route: {expected}')
        yes(not any(row[0]=='JOHTO_DARK_CAVE_VIOLET_ENTRANCE_LOCAL_ID' and row[1]=='1' for row in routes),
            'Blackthorn source warp ordinal1 must remain sealed')
        route=txt('data/johto_pilot_map_headers.asm')
        yes('db 5, 34, 0, JOHTO_REGISTERED_WARP_SELECTOR' in route, 'Route31 exact entrance missing')
        route46=txt('data/johto_south_chain_runtime_328.asm')
        yes('db 3 ; Gold Route46: Gate north pair + Dark Cave north DOOR' in route46 and
            'db 5, 14, 2, JOHTO_REGISTERED_WARP_SELECTOR' in route46 and
            'db 33, 7, 0, JOHTO_REGISTERED_WARP_SELECTOR' in route46 and
            'db 33, 8, 1, JOHTO_REGISTERED_WARP_SELECTOR' in route46,
            'Route46 Gold warp #3 must preserve both existing Gate ordinals')
        route46_roles=raw('maps/johto_pilot/Route46.roles.bin')
        yes(len(route46_roles)==720 and route46_roles[5*20+14]==1 and route46_roles[6*20+14]==0 and
            roles[33*40+35]==6, 'Gold Route46 cave mouth WALL and cave DOWN carpet mismatch')
        gate=txt('data/johto_vertical_gate_runtime_314.asm')
        yes('db JOHTO_ROUTE_46_LOCAL_ID, PLAYER_DIR_UP, 14, 6' in gate and
            'db JOHTO_ROUTE_46_LOCAL_ID, PLAYER_DIR_UP, 14, 5, 2' in gate and
            'db JOHTO_ROUTE_46_LOCAL_ID, 14, 5, D_DOWN' in gate,
            'Route46 must enter on UP solid-door collision and auto-step DOWN on return')
        yes('JOHTO_DARK_CAVE_VIOLET_ENTRANCE_LOCAL_ID' in txt('data/johto_stable_id_slots.asm') or
            re.search(r'^\s*db [^\n]* 63, JOHTO_INVALID_ACTIVE_SLOT ; \$b0-\$bf',txt('data/johto_stable_id_slots.asm'),re.M),
            'stable ID190 should be registered at slot 63')
        yes('DEF NUM_JOHTO_ACTIVE_MAPS EQU 64' in txt('constants/region_map_constants.asm'), 'active count not 64')
        sp=txt('engine/johto_dark_cave_stage2.asm')
        for needle in ('cp 36','cp 40','JohtoDarkCaveGoldRoles','cp 3','cp 7','cp 2','JohtoDarkCaveWaterAhead::','JohtoDarkCaveSurfDecision::'):
            yes(needle in sp, 'spatial movement missing '+needle)
        surf=txt('engine/johto_violet_field_skills.asm')
        yes(re.search(r'cp JOHTO_DARK_CAVE\s+jp z, \.darkCave',surf) is not None and
            'callab JohtoDarkCaveSurfDecision' in surf and 'callab JohtoDarkCaveWaterAhead' in surf,
            'Surf movement or field skill not connected')
        yes('callab JohtoDarkCaveLandDecision' in txt('engine/johto_land_collision_gateway_272.asm'),
            'land path does not use Gold spatial role')
        yes('ld [wMapPalOffset], a' in warp and
            'cp JOHTO_DARK_CAVE_VIOLET_ENTRANCE_LOCAL_ID' in warp and
            'ld a, 12 ; FadePal4 - FadePalJohtoDark349' in warp and
            'xor a\n.storePalette349' in warp,
            'Flash darkness or exit restoration missing')
        # REF-349 field-behavior hotfix: these checks must fail for the
        # regressions that were invisible to the stage2 role/warp audit.
        palette=txt('color/data/map_palette_sets.asm')
        dark_colors=palette.split('; REF-349 hotfix:',1)[-1].split('MapPaletteSetsEnd::',1)[0]
        yes('db CAVE_GRAY, CAVE_RED, CAVE_GREEN, CAVE_BLUE' in dark_colors and
            'db CAVE_YELLOW, CAVE_BROWN, CAVE_LIGHT_BLUE, CRYS_TEXTBOX' in dark_colors and
            'OUTDOOR_GRAY' not in dark_colors,
            'Dark Cave must use Gold CAVE/NITE RGB5 colors, not outdoor DAY colors')
        # RPP uses rBGP to build the *GBC* palette buffer in VBlank too;
        # Offset 12 is the Johto-only DARKNESS record; old Kanto offset 6 is untouched.
        cgb=txt('color/vblank.asm')
        yes('ld a,[rBGP]' in cgb and 'call SetColor' in cgb,
            'DMG dark offset must also reach GBC palette conversion')
        # REF-349 phone video (Gold first, RPP second): unlit RPP rendered
        # the BG almost black AND its player sprite black. Its cave frame
        # also appeared at full purple brightness before the dark mapping.
        # Verify the byte-palette semantics and the entry/exit call order,
        # not merely the presence of a palette name or generic flash helper.
        fade=txt('home/fade.asm')
        yes(bool(re.search(r'FadePalJohtoDark349::\s*db\s*%11111110,\s*%11100100,\s*%11100100',fade)) and
            'ASSERT FadePal4 - FadePalJohtoDark349 == 12' in fade and
            fade.index('FadePalJohtoDark349::') < fade.index('FadePal1::') < fade.index('FadePal4::'),
            'Gold DARKNESS must darken BG while keeping both Johto OBJ palettes normal')
        yes('FadePal2:: db %11111110, %11111110, %11111110' in fade,
            'Kanto Rock Tunnel legacy darkness must remain unchanged')
        ov=txt('home/overworld.asm')
        map_sound=ov.split('PlayMapChangeSound::',1)[-1].split('ExtraWarpCheck::',1)[0]
        yes('call GBFadeOutToBlackDarkBG353' in map_sound and
            'call GBFadeOutToBlackAlreadyDark353' in map_sound and
            'call GBFadeOutToBlack' in map_sound and
            'ldh [hMapLoadVRAMSafeFlag],a' in map_sound and
            'ret nz ; leave Kanto Rock Tunnel' not in map_sound and
            'jp GBFadeOutToWhite' not in map_sound,
            'Dark Cave and Rock Tunnel must share the LCD-on black doorway with monotonic dim-source fades')
        loader=ov.split('LoadMapData::',1)[-1].split('SwitchToMapRomBank::',1)[0]
        yes('_LoadMapVramAndColors' in loader and
            'callab JohtoDarkCavePreLCDPalette349' in loader and
            loader.index('_LoadMapVramAndColors') < loader.index('callab JohtoDarkCavePreLCDPalette349') < loader.index('call EnableLCD'),
            'Dark Cave palette must be staged while LCD is off, before first visible target frame')
        resolve=warp.split('JohtoPilotResolveRegisteredWarp::',1)[-1].split('JohtoPilotMapProfiles::',1)[0]
        yes(bool(re.search(r'ld a, c\s*; source stable ID[^\n]*\n\s*cp JOHTO_DARK_CAVE_VIOLET_ENTRANCE_LOCAL_ID',resolve)) and
            'cp 12 ; was the source cave still unlit?' in resolve and
            all('ld ['+r+'], a' not in resolve for r in ('rBGP','rOBP0','rOBP1')) and
            resolve.index('ld a, 12 ; FadePal4 - FadePalJohtoDark349') < resolve.index('ld [wMapPalOffset], a'),
            'Unlit cave exit must not force a white screen before the common black fade')
        prelcd=sp.split('JohtoDarkCavePreLCDPalette349::',1)[-1] if 'JohtoDarkCavePreLCDPalette349::' in sp else ''
        yes(all(token in prelcd for token in (
                'cp JOHTO_RUNTIME_MAP_HANDLE','cp MAP_REGION_JOHTO',
                'cp 12 ; FadePalJohtoDark349',
                'cp JOHTO_DARK_CAVE_VIOLET_ENTRANCE_LOCAL_ID',
                'jr z, .apply','ld [wMapPalOffset], a',
                'ldh a, [hMapLoadVRAMSafeFlag]',
                'ret nz ; stay black until LoadPlayerSpriteGraphics completes',
                'jp LoadGBPal')),
            'Dark Cave palette offset must be cleared on exit but LCD-on map must stay black through sprite upload')
        arrival=warp.split('JohtoPilotGateArrivalStep::',1)[-1].split('JohtoPilotGateDoorApproachAllowed::',1)[0]
        yes('cp JOHTO_ROUTE_31_LOCAL_ID' in arrival and
            'cp 34' in arrival and 'cp 5' in arrival and
            'ld e, D_DOWN' in arrival.split('\n.notRoute31CaveArrival349\n',1)[0] and
            'cp JOHTO_DARK_CAVE_VIOLET_ENTRANCE_LOCAL_ID\n    ret z' in arrival,
            'Route31 cave-mouth arrival needs one DOWN step; cave carpet stays stationary')
        flash=re.split(r'(?m)^\.flash\s*$',txt('engine/menu/start_sub_menus.asm'),maxsplit=1)[-1].split('\n.dig\n',1)[0]
        eligibility=sp.split('JohtoFlashEligibility349::',1)[-1].split('JohtoDarkCavePreLCDPalette349::',1)[0]
        yes('callab JohtoFlashEligibility349' in flash and
            'ld [wMapPalOffset], a' in flash and
            'cp JOHTO_RUNTIME_MAP_HANDLE' in eligibility and
            'cp MAP_REGION_JOHTO' in eligibility and
            'cp JOHTO_DARK_CAVE_VIOLET_ENTRANCE_LOCAL_ID' in eligibility and
            'cp 12 ; Johto unlit Dark Cave' in eligibility and
            'cp ROCK_TUNNEL_1' in eligibility and
            'cp ROCK_TUNNEL_2' in eligibility and
            'cp 6 ; Kanto unlit Rock Tunnel' in eligibility and
            '.checkKantoCave' in eligibility and
            'jr nz, .notDark' in eligibility and
            'wObtainedJohtoBadges' in eligibility and
            'wObtainedKantoBadges' in eligibility and
            'ld e, 1' in eligibility,
            'Flash must check active unlit Kanto/Johto cave identity and existing badge rules')
        shore=sp.split('JohtoDarkCaveSurfDecision::',1)[-1]
        yes(all(k in shore for k in (
                'cp JOHTO_RUNTIME_MAP_HANDLE','cp MAP_REGION_JOHTO',
                'cp JOHTO_DARK_CAVE_VIOLET_ENTRANCE_LOCAL_ID',
                'cp 3 ; UP_WALL','cp 4 ; HOP_DOWN','cp 5 ; HOP_LEFT',
                'cp PLAYER_DIR_DOWN','cp PLAYER_DIR_UP','cp PLAYER_DIR_RIGHT')) and
            'cp 0 ; FLOOR' in shore and 'cp 6 ; the exit carpet' in shore,
            'Surf shore must admit Gold LAND roles by their direction; isolate Violet role grid')
        yes('JOHTO_DARK_CAVE' in txt('data/dungeon_tilesets.asm'),
            'same-tileset cave map warps must reload destination coords')

        # Gold BikeFunction permits CAVE, but only FLOOR_TILE (collision
        # permission low nibble 0) when mounting. Gold cave carpet $70 is
        # also FLOOR_TILE. Keep the exception ID190-only: the INDOOR
        # hTilesetType is needed to protect GBC background animations.
        bike=txt('home/rom0_relief_349.asm').split('IsBikeRidingAllowed::',1)[1].split('INCLUDE "data/bike_riding_tilesets.asm"',1)[0]
        bike_head=bike.split('\n.legacyBike\n',1)[0]
        bike_exception=bike.split('\n.darkCaveBike\n',1)[1]
        yes(bool(re.search(r'cp JOHTO_DARK_CAVE_VIOLET_ENTRANCE_LOCAL_ID\s+jp z, \.darkCaveBike',bike_head)) and
            bool(re.search(r'ld a, \[wWalkBikeSurfState\]\s+cp 1\s+jr z, \.allowed\s+callab JohtoDarkCaveBikeFloorAllowed349\s+ret',bike_exception)) and
            'callab IsBikeRidingAllowed' in txt('engine/items/items.asm').split('ItemUseBicycle:',1)[1].split('ItemUseSurfboard:',1)[0] and
            'callab IsBikeRidingAllowed' in txt('home/overworld.asm').split('LoadPlayerSpriteGraphics::',1)[1].split('LoadTilesetTilePatternData::',1)[0],
            'Gold CAVE bike exception must support both item use and existing mounted sprite reload')
        bike_floor=sp.split('JohtoDarkCaveBikeFloorAllowed349::',1)[-1].split('JohtoDarkCaveLandDecision::',1)[0]
        yes(all(t in bike_floor for t in (
            'cp JOHTO_RUNTIME_MAP_HANDLE','cp MAP_REGION_JOHTO',
            'cp JOHTO_DARK_CAVE_VIOLET_ENTRANCE_LOCAL_ID',
            'ld a, [wYCoord]','ld a, [wXCoord]',
            'call JohtoDarkCaveRoleAt','cp 6 ; WARP_CARPET_DOWN',
            'and a ; carry clear','scf')) and
            bool(re.search(r'call JohtoDarkCaveRoleAt\s+pop hl\s+pop bc\s+and a[^\n]*\n\s+jr z, \.allowed',bike_floor)) and
            'JOHTO_DARK_CAVE' not in txt('data/bike_riding_tilesets.asm'),
            'Bike mount must be scoped to Gold FLOOR/warp carpet, not a shared tileset global allowlist')
        yes(roles.count(0)==1002 and roles.count(6)==10 and
            all(roles[y*40+x] != 0 for x,y in ((8,12),(8,13))),
            'Bike whitelist must not treat Gold WATER or HOP roles as flooring')
        # Safety: Gold Dig/Escape Rope rely on entrance-return state. RPP
        # currently uses the old blackout/Fly special warp, so a simple
        # tileset permit would be unsafe until a region-aware return exists.
        rope=txt('engine/items/items.asm')
        yes('JOHTO_DARK_CAVE' not in rope.split('EscapeRopeTilesets:',1)[1].split('ItemUseRepel:',1)[0],
            'Do not enable Gold Dig/Escape Rope using Kanto blackout fallback')

        # Surf must survive BOTH the normal text-close sprite reload and the
        # LCD-off party-summary return. This is a runtime-state requirement:
        # a surfable Dark Cave deliberately has hTilesetType=INDOOR to suppress
        # unrelated CAVERN background animation.
        headers=txt('data/tileset_headers.asm')
        yes(bool(re.search(r'tileset JohtoDarkCave_Block,.*INDOOR',headers)),
            'Dark Cave static graphics animation isolation was changed')
        for rel,label in [('home/overworld.asm','normal sprite loader'),
                          ('engine/menu/summary_return_helpers.asm','LCD-off summary sprite loader')]:
            source=txt(rel)
            label_key=('LoadPlayerSpriteGraphics::' if rel.startswith('home/') else
                       'Summary_LoadPlayerSpriteGraphicsLCDOff:')
            routine=source.split(label_key,1)[1].split('\n.ridingBike\n',1)[0]
            yes(bool(re.search(r'ld a, \[hTilesetType\]\s+and a\s+jr nz, \.determineGraphics\s+.*?'
                               r'ld a, \[wCurMapTileset\]\s+cp JOHTO_DARK_CAVE\s+jr nz, \.startWalking\s+'
                               r'ld a, \[wWalkBikeSurfState\]\s+cp 2\s+jr z, \.determineGraphics',
                               routine,re.S)),
                label+' must keep active Surf state in static-animation Dark Cave')
        items=txt('engine/items/items.asm')
        stop=items.split('ItemUseSurfboard:',1)[1].split('; uses a simulated button press',1)[0]
        yes(bool(re.search(r'\.tryToStopSurfing.*?cp JOHTO_DARK_CAVE\s+jr nz, \.legacyShore\s+'
                           r'callab JohtoDarkCaveSurfDecision\s+ld a, e\s+and a\s+jr z, \.stopSurfing',stop,re.S)) and
            'wTilesetCollisionPtr' in stop.split('.legacyShore',1)[1] and
            'call .makePlayerMoveForward' in stop,
            'Surfboard dismount must check spatial Gold shore, then simulate a safe step')
        home=txt('home/overworld.asm')
        yes('callab JohtoOverworldSurfDecision' in home.split('CollisionCheckOnWater::',1)[1] and
            '.stopSurfing' in home.split('CollisionCheckOnWater::',1)[1],
            'directional surfing must reach Gold spatial WATER/LAND handler')
        spbadge=sp.split('JohtoSurfBadgeAllowed349::',1)[1].split('JohtoFlashEligibility349::',1)[0]
        yes(all(k in spbadge for k in ('cp JOHTO_RUNTIME_MAP_HANDLE','cp MAP_REGION_JOHTO',
                'cp JOHTO_DARK_CAVE_VIOLET_ENTRANCE_LOCAL_ID','wObtainedJohtoBadges',
                'bit 3, a ; Fog Badge','wObtainedKantoBadges','bit 4, a ; Soul Badge',
                'and a ; carry clear','scf')),
            'Surf badge must allow Gold Fog in Violet cave, retain Soul compatibility and clear carry otherwise')
        yes('callab JohtoSurfBadgeAllowed349' in txt('engine/overworld/field_moves.asm').split('TrySurf:',1)[1].split('TryCut:',1)[0] and
            'callab JohtoSurfBadgeAllowed349' in txt('engine/menu/start_sub_menus.asm').split('\n.surf\n',1)[1].split('.strength',1)[0],
            'both facing-water and party-menu Surf must use the same badge contract')

        cave_exit=warp.split('JohtoDarkCaveDownCarpet349::',1)[-1]
        yes('JohtoDarkCaveDownCarpet349::' in warp and
            all(k in cave_exit for k in ('cp PLAYER_DIR_DOWN','cp 3','cp 15',
                                        'cp 35','cp 33','.route46Carpet','.allow')),
            'cave must allow DOWN-only carpets at Gold (3,15) and (35,33)')
        for key in ('JohtoPilotTownMapEntriesEnd','JohtoPilotTownMapBrowseIndexBySlotEnd'):
            yes(key in txt('engine/fly_town_map_helpers.asm'),'town map table missing '+key)
        yes('db MUSIC_GBP_GSC_DARK_CAVE ; slot63' in txt('engine/menu/options_menu.asm'),'64th music slot missing')
        yes('(JOHTO_DARK_CAVE + 1) * 8' in txt('color/data/map_palette_sets.asm') and
            '(JOHTO_DARK_CAVE + 1) * $60' in txt('color/data/map_palette_assignments.asm') and
            'color/tilesets/johto_dark_cave_violet.asm' in txt('color/data/map_palette_assignments.asm'),
            'Dark Cave palette sets / assignments are not fully indexed')
    except (OSError,KeyError,ValueError,IndexError,AssertionError,TypeError) as e:errs.append('cannot inspect Gold Dark Cave runtime: '+str(e))
    return errs

def main():
    import argparse
    ap=argparse.ArgumentParser();ap.add_argument('--project',type=Path,default=Path(__file__).resolve().parents[1]);args=ap.parse_args();err=check(args.project)
    if err:
        print('FAIL: Dark Cave Stage2:',*err,sep='\n - ');return 1
    print('PASS: Dark Cave Stage3 Route31/Route46 two-way warps, Gold spatial roles, 26 HOP, 64 WATER (static only)');return 0
if __name__=='__main__':raise SystemExit(main())
