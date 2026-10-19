#!/usr/bin/env python3
"""Gold-backed Route33 native runtime source audit (not a ROM build)."""
from pathlib import Path
import re
from hashlib import sha256
from johto_indoor_collision_adapter import plan_gold_quadrant_collision
from johto_gold_cells import read_route33


def audit(root: Path, gold: Path) -> list[str]:
    root, gold = Path(root), Path(gold)
    errors = []
    try:
        blob = lambda name: (root / name).read_bytes()
        text = lambda name: (root / name).read_text()
        if blob('maps/JohtoRoute33.blk') != (gold / 'maps/Route33.blk').read_bytes():
            errors.append('Route33 runtime layout is not Gold 10x9')
        if blob('gfx/blocksets/johto_modern.bst') != (gold / 'data/tilesets/johto_modern_metatiles.bin').read_bytes():
            errors.append('Route33 runtime modern blockset mismatches Gold')
        if blob('gfx/tilesets/johto_modern.png') != (gold / 'gfx/tilesets/johto_modern.png').read_bytes():
            errors.append('Route33 runtime modern graphics mismatches Gold')
        if text('color/tilesets/johto_modern.asm') != (gold / 'gfx/tilesets/johto_modern_palette_map.asm').read_text():
            errors.append('Route33 runtime modern palette mapping mismatches Gold')
        # Reuse the existing runtime/source gate for the few Gold metadata
        # assertions not already covered by runtime asset parity, geometry190,
        # Gold-wide door inventory, or the cave-exit192 contract.
        gold_maps = (gold / 'data/maps/maps.asm').read_text()
        gold_attrs = (gold / 'data/maps/attributes.asm').read_text()
        gold_events = (gold / 'maps/Route33.asm').read_text()
        if 'map Route33, TILESET_JOHTO_MODERN, ROUTE,' not in gold_maps:
            errors.append('Gold Route33 tileset/type source contract changed')
        if not re.search(r'map_attributes Route33, ROUTE_33, \$05, NORTH \| WEST\s+connection north, Route32, ROUTE_32, 0\s+connection west, AzaleaTown, AZALEA_TOWN, 0', gold_attrs):
            errors.append('Gold Route33 source connection metadata changed')
        if not re.search(r'^\s*bg_event\s+11,\s*11,', gold_events, re.M):
            errors.append('Gold Route33 sign source coordinate changed')
        if 'db $01 ; one route sign' not in text('data/mapObjects/JohtoRoute33.asm') or 'db 11, 11, 1' not in text('data/mapObjects/JohtoRoute33.asm'):
            errors.append('RPP Route33 sign registration missing')
        if blob('gfx/tilesets/johto_modern.tilecoll') != b'\xff':
            errors.append('Route33 cannot use a global modern walkability whitelist')
        # R33-5.62.193: Gold TALL_GRASS needs the original RPP player-foot
        # priority mask. It is a graphic tile ID, not a collision whitelist.
        gold_data = read_route33(gold)
        _, _, cells = gold_data
        grass_cells = [cell for cell in cells if cell['role'] == 'TALL_GRASS']
        grass_count = len(grass_cells)
        grass_ids = {tile for cell in grass_cells for tile in cell['graphics']}
        if grass_count != 12 or grass_ids != {0x04}:
            errors.append('Gold Route33 grass geometry/graphic ID drifted')
        header = text('data/tileset_headers.asm')
        if not re.search(r'(?m)^\s*tileset JohtoModern_Block,\s*JohtoModern_GFX,\s*JohtoModern_Coll,\s*\$FF,\s*\$FF,\s*\$FF,\s*\$04,\s*OUTDOOR\b', header):
            errors.append('Route33 must use its verified $04 grass tile for original foot occlusion')
        fly_menu = text('engine/menu/start_sub_menus.asm')
        fly_branch = fly_menu.split('\n.fly\n', 1)[-1].split('\n.canFly\n', 1)[0]
        if not re.search(r'cp JOHTO\s+jr z, \.canFly\s+.*?cp JOHTO_MODERN\s+jr z, \.canFly\s+call CheckIfInOutsideMap', fly_branch, re.S):
            errors.append('Fly must allow JOHTO_MODERN outdoors without changing the common outside-map test')
        r, mask = plan_gold_quadrant_collision(gold, 'Route33', 'johto_modern')
        if mask != blob('maps/JohtoRoute33.blocked_mask.bin'):
            errors.append('Route33 movement mask differs from Gold audited map')
        constants = text('constants/region_map_constants.asm')
        if not re.search(r'DEF JOHTO_ROUTE_33_LOCAL_ID EQU 9\b', constants):
            errors.append('Route33 native identity missing or shifted')
        hdr32 = text('data/mapHeaders/JohtoRoute32.asm')
        hdr33 = text('data/mapHeaders/JohtoRoute33.asm')
        for part, keys in ((hdr32,('db NORTH | SOUTH','db REGION_NATIVE_MAP_SLOT','dw JohtoRoute33Blocks')),
                           (hdr33,('db JOHTO_MODERN','db NORTH','db JOHTO_ROUTE_32','dw JohtoRoute32Blocks + JOHTO_ROUTE_32_WIDTH * (JOHTO_ROUTE_32_HEIGHT - 3)'))):
            if any(key not in part for key in keys):
                errors.append('Route32/33 connection header contract incomplete')
        if 'db NORTH | WEST' in hdr33:
            # A reviewed Azalea map may open the formerly sealed edge, but
            # only if the existing generic strip verifier accepts BOTH ways.
            from johto_rpp_connection_guard import audit as connection_audit
            for source, target, gold_source, gold_target, direction in (
                    ('JohtoRoute33','JohtoAzaleaTown','Route33','AzaleaTown','west'),
                    ('JohtoAzaleaTown','JohtoRoute33','AzaleaTown','Route33','east')):
                try:
                    seam = connection_audit(root,gold,source,target,gold_source,gold_target,direction)
                    if seam['status'] != 'PASS':
                        errors.append('Azalea connection strip mismatch: '+str(seam['issues']))
                except (OSError, ValueError) as exc:
                    errors.append('Azalea connection requires review: '+str(exc))
            resolver = text('engine/overworld/region_map_lookup.asm')
            if not all(line in resolver for line in (
                    'db JOHTO_ROUTE_33_LOCAL_ID, 2, MAP_REGION_JOHTO, JOHTO_AZALEA_TOWN_LOCAL_ID',
                    'db JOHTO_AZALEA_TOWN_LOCAL_ID, 3, MAP_REGION_JOHTO, JOHTO_ROUTE_33_LOCAL_ID')):
                errors.append('Azalea west/east native target table incomplete')
            fences = text('engine/overworld/johto_route33_collision.asm')
            west = fences.split('JohtoRoute33EdgeFence::',1)[-1].split('JohtoAzaleaEdgeFence::',1)[0]
            east = fences.split('JohtoAzaleaEdgeFence::',1)[-1].split('JohtoRoute33CanStepAhead::',1)[0]
            for label, span in (('Route33 west',west),('Azalea east',east)):
                if not all(t in span for t in ('cp 14','cp 16','.block','.clear')):
                    errors.append(label+' passage must be limited to y14/15')
        elif 'WEST' in hdr33:
            errors.append('Route33 west opened without registered Azalea connection')
        mapping = text('engine/overworld/region_map_lookup.asm')
        if 'db JOHTO_ROUTE_32_LOCAL_ID, 1, MAP_REGION_JOHTO, JOHTO_ROUTE_33_LOCAL_ID' not in mapping:
            errors.append('Route32 south $FC target not resolved as native Route33')
        if 'db JOHTO_UNION_CAVE_1F_LOCAL_ID, 0, 0, MAP_REGION_JOHTO, JOHTO_ROUTE_32_LOCAL_ID' not in mapping:
            errors.append('Union Cave fixed Route32 warp must stay unchanged')
        if 'db JOHTO_ROUTE_33_LOCAL_ID, 0, 1, MAP_REGION_JOHTO, JOHTO_UNION_CAVE_1F_LOCAL_ID' not in mapping:
            errors.append('Route33 cave source must resolve to Union Cave southern Warp')
        if 'db JOHTO_UNION_CAVE_1F_LOCAL_ID, 1, 0, MAP_REGION_JOHTO, JOHTO_ROUTE_33_LOCAL_ID' not in mapping:
            errors.append('Union Cave southern exit must resolve to Route33 mouth')
        main = text('main.asm')
        if 'SECTION "Johto Route33 Map", ROMX, BANK[JOHTO_ROM_BANK]' not in main:
            errors.append('Route33 and Route32 block maps must share ROM bank for neighbor-strip copy')
        if 'callba JohtoRoute33EdgeFence' not in main or 'jp z, JohtoRoute33EdgeFence' in main:
            errors.append('Route33 cross-bank edge fence must use callba')
        if 'cp 15 ; Gold Route32->Route33 seam: x=0..14 only' not in main:
            errors.append('Route32 seam guard must reject x>=15')
        runtime = text('engine/overworld/johto_route33_collision.asm')
        home = text('home/overworld.asm')
        if 'JohtoRoute33CanStepAhead::' not in runtime or 'JohtoRoute33BlockedRows::' not in runtime:
            errors.append('Route33 16x16 mask routine missing')
        if 'INCBIN "maps/JohtoRoute33.blocked_mask.bin"' not in runtime:
            errors.append('Route33 mask not linked to Gold-reviewed source')
        if 'cp 15' not in runtime or 'jr z, .west' not in runtime or 'jr c, .allowed' not in runtime:
            errors.append('Route33 edge restrictions missing')
        from johto_rom0_collision_audit import audit as native_collision_audit
        if native_collision_audit(root):
            errors.append('Route33 precise collision not routed through land movement')
        # A header-only seamless map connection preserves the previous VRAM
        # tiles, which is invalid when moving between JOHTO and JOHTO_MODERN.
        conn = home.split('.loadNewMap ; load the connected map that was entered', 1)[-1].split('.didNotEnterConnectedMap', 1)[0]
        if ('cp JOHTO_ROUTE_33_LOCAL_ID' not in conn or
                'cp JOHTO_MODERN' not in conn or
                conn.count('jp z, .route33TilesetReload') != 2 or
                'ld [wDestinationWarpID], a' not in conn or
                'jp EnterMap' not in conn or
                'call LoadMapHeader' not in conn):
            errors.append('Route32/33 cross-tileset connection must fully reload graphics both ways')
        # MAP-5.62.194: original Violet City -> Route32 must NOT take the
        # Route32/33-specific LCD-off reload.  The missing not-equal branch
        # introduced in .191 caused a ~0.1 s white frame on ordinary entry.
        conn_code = '\n'.join(line for line in conn.splitlines() if not line.strip().startswith(';'))
        if not re.search(r'cp JOHTO_MODERN\s+jp z, \.route33TilesetReload\s+jr \.ordinaryConnection\s+\.route33TilesetReload', conn_code):
            errors.append('non-modern entries into Route32 must retain seamless fast connection')
        ledges = text('engine/overworld/ledges.asm')
        for x,y,d in [(9,10,'LEFT'),(9,11,'LEFT'),(9,12,'LEFT'),(9,12,'DOWN'),
                       (10,12,'DOWN'),(11,12,'DOWN'),(12,12,'DOWN')]:
            if f'db {x}, {y}, PLAYER_DIR_{d}' not in ledges:
                errors.append(f'Gold Route33 hop missing: {x},{y},{d}')
        if len(re.findall(r'\bdb \d+, \d+, PLAYER_DIR_(?:LEFT|DOWN)\b',
                          ledges.split('.route33Hops',1)[-1].split('db $ff',1)[0])) != 7:
            errors.append('Route33 ledge table has an unaudited hop')
        hops = ledges.split('.matchHop',1)[-1].split('.route33Hops',1)[0]
        if ('ld e, D_LEFT' not in hops or 'ld e, D_DOWN' not in hops or
                'ld e, [hl]' in hops):
            errors.append('Route33 hop must convert facing PLAYER_DIR to joypad D_* bits')
        if 'db $01 ; Union Cave 1F entry, explicit native target' not in text('data/mapObjects/JohtoRoute33.asm') or 'db 9, 11, 1, REGION_WARP_ESCAPE' not in text('data/mapObjects/JohtoRoute33.asm'):
            errors.append('Route33 Gold cave mouth (11,9) missing')
        if 'JohtoModern_Block' not in text('data/tileset_headers.asm') or 'JohtoModern_Coll::' not in text('data/collision.asm'):
            errors.append('Route33 modern tileset/collision not registered')
        if 'cp JOHTO_MODERN' not in text('engine/overworld/map_sprites.asm'):
            errors.append('Route33 fails shared Johto outdoor sprite loader')
        if 'db 140, 90' not in text('engine/town_map.asm'):
            errors.append('Route33 Town Map position must be Gold coordinate (140,90)')
    except (OSError, ValueError, IndexError) as exc:
        errors.append('incomplete Route33 runtime source: ' + str(exc))
    return errors
