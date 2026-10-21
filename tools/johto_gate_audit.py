#!/usr/bin/env python3
"""Static RPP/Gold dual-source preflight and Route31-Violet Gate geometry audit.

MUST have both readable complete source trees. Not a ROM-build/runtime test.
Usage: python tools/johto_gate_audit.py --rpp . --gold /path/to/pokegold-master
"""
import argparse
from pathlib import Path
import re
import sys

RPP_REQUIRED = (
    'Makefile', 'constants.asm', 'wram.asm',
    'main.asm', 'home/overworld.asm', 'data/game_version.asm',
    'constants/map_constants.asm', 'constants/region_map_constants.asm',
    'data/map_header_banks.asm', 'data/map_header_pointers.asm',
    'data/johto_map_headers.asm', 'data/town_map_entries.asm',
    'data/mapObjects/JohtoRoute31.asm', 'data/mapObjects/JohtoVioletCity.asm',
    'data/mapObjects/JohtoRoute31VioletGate.asm',
    'data/mapHeaders/JohtoRoute31.asm', 'data/mapHeaders/JohtoVioletCity.asm',
    'data/mapHeaders/JohtoRoute31VioletGate.asm',
    'maps/JohtoRoute31VioletGate.blk', 'maps/Route11Gate1F.blk',
    'gfx/blocksets/gate.bst', 'gfx/tilesets/gate.t1.png',
    'engine/overworld/region_map_lookup.asm', 'engine/town_map.asm',
    'scripts/JohtoRoute31VioletGate.asm',
    'data/warp_tile_ids.asm', 'gfx/blocksets/johto.bst',
    'gfx/tilesets/johto.tilecoll', 'maps/JohtoRoute31.blk', 'maps/JohtoVioletCity.blk',
    'RPP_DEVELOPMENT_PITFALLS.md',
    'gfx/tilesets/johto_gate.png',
    'gfx/blocksets/johto_gate.bst', 'color/tilesets/johto_gate.asm',
)
GOLD_REQUIRED = (
    'Makefile', 'main.asm', 'includes.asm',
    'maps/Route31.asm', 'maps/VioletCity.asm', 'maps/Route31VioletGate.asm',
    'maps/EastWestGate.blk', 'data/maps/blocks.asm', 'data/maps/maps.asm',
    'data/tilesets/gate_metatiles.bin', 'gfx/tilesets/gate.png', 'gfx/tilesets/gate_palette_map.asm',
)
WARP_RPP = re.compile(r'^\s*db\s+(\d+),\s*(\d+),\s*(\d+),\s*(JOHTO_[A-Z_0-9]+)\s*$', re.M)
WARP_GOLD = re.compile(r'^\s*warp_event\s+(\d+),\s*(\d+),\s*([A-Z_0-9]+),\s*(\d+)\s*$', re.M)
RPP_EXPECTED = {
    'JohtoRoute31.asm': [(6,4,2,'JOHTO_ROUTE31_VIOLET_GATE'), (7,4,3,'JOHTO_ROUTE31_VIOLET_GATE')],
    'JohtoVioletCity.asm': [(24,39,0,'JOHTO_ROUTE31_VIOLET_GATE'), (25,39,1,'JOHTO_ROUTE31_VIOLET_GATE')],
    'JohtoRoute31VioletGate.asm': [(4,0,0,'JOHTO_VIOLET_CITY'), (5,0,1,'JOHTO_VIOLET_CITY'),
                                   (4,9,0,'JOHTO_ROUTE_31'), (5,9,1,'JOHTO_ROUTE_31')],
}
GOLD_GATE = [(0,4,'VIOLET_CITY',8),(0,5,'VIOLET_CITY',9),
             (9,4,'ROUTE_31',1),(9,5,'ROUTE_31',2)]
# GATE-5.62.159: original Gold 5x4 artwork, no temporary Kanto gate adapter.
GOLD_GATE_SOURCE_BLOCKS = 13
GOLD_GATE_SOURCE_TILES = 22


def text(root, rel):
    return (root/rel).read_text(encoding='utf-8')


def preflight(rpp, gold):
    problems = []
    for label, root, minimum in (('RPP',Path(rpp),3200),('GOLD',Path(gold),4000)):
        if not root.is_dir():
            problems.append(f'{label} SOURCE DIRECTORY MISSING: {root}')
        else:
            count=sum(p.is_file() for p in root.rglob('*') if '.git' not in p.parts)
            if count < minimum:
                problems.append(f'{label} INCOMPLETE SOURCE TREE: only {count} files (<{minimum})')
    for label, root, names in (('RPP',Path(rpp),RPP_REQUIRED), ('GOLD',Path(gold),GOLD_REQUIRED)):
        for name in names:
            file = root/name
            if not file.is_file():
                problems.append(f'{label} MISSING {name}')
            else:
                try:
                    if len(file.read_bytes()) == 0:
                        problems.append(f'{label} EMPTY {name}')
                except OSError as ex:
                    problems.append(f'{label} UNREADABLE {name}: {ex}')
    return problems


def gold_gate_source_to_compact_tiles(rpp, gold):
    """Resolve *actual* 8x8 tile IDs using paired Gold/RPP metatile cells.

    RPP remaps the graphics (e.g. Gold tile 1 -> compact tile 2 and Gold
    tile 7 -> compact tile 0). Sorting Gold tile IDs does NOT give the RPP
    compact tile order. This broke P16D and recolored the entire gate.
    """
    original_layout = (gold / 'maps/EastWestGate.blk').read_bytes()
    original_ids = sorted(set(original_layout))
    if len(original_layout) != 20 or len(original_ids) != GOLD_GATE_SOURCE_BLOCKS:
        raise ValueError('invalid Gold gate geometry for source palette mapping')
    compact_layout = (rpp / 'maps/JohtoRoute31VioletGate.blk').read_bytes()
    if compact_layout != bytes(original_ids.index(x) for x in original_layout):
        raise ValueError('RPP/Gold gate layout mismatch: no reliable palette mapping')
    source_blocks = (gold / 'data/tilesets/gate_metatiles.bin').read_bytes()
    compact_blocks = (rpp / 'gfx/blocksets/johto_gate.bst').read_bytes()
    if len(source_blocks) % 16 or len(compact_blocks) < GOLD_GATE_SOURCE_BLOCKS * 16:
        raise ValueError('incomplete source or compact gate metatiles')
    source_to_compact, compact_to_source = {}, {}
    for compact_block, source_block in enumerate(original_ids):
        if (source_block + 1) * 16 > len(source_blocks):
            raise ValueError('Gold gate metatile index outside table')
        source_cells = source_blocks[source_block*16:(source_block+1)*16]
        compact_cells = compact_blocks[compact_block*16:(compact_block+1)*16]
        for source_id, compact_id in zip(source_cells, compact_cells):
            if (source_id in source_to_compact and source_to_compact[source_id] != compact_id
                or compact_id in compact_to_source and compact_to_source[compact_id] != source_id):
                raise ValueError('gate tile reuse mismatch between Gold and compact graphics')
            source_to_compact[source_id] = compact_id
            compact_to_source[compact_id] = source_id
    if len(source_to_compact) != GOLD_GATE_SOURCE_TILES or len(compact_to_source) != GOLD_GATE_SOURCE_TILES:
        raise ValueError('gate 8x8 source/compact correspondence is incomplete')
    return compact_to_source


def verify_gold_gate_palette_map(rpp, gold):
    """Compare palettes for matching graphic IDs, NOT sorted tile positions."""
    def attrs(path):
        return [v.strip() for line in path.read_text().splitlines()
                if 'tilepal 0,' in line
                for v in line.split('tilepal 0,', 1)[1].split(';', 1)[0].split(',')]
    try:
        compact_to_source = gold_gate_source_to_compact_tiles(rpp, gold)
        source = attrs(gold / 'gfx/tilesets/gate_palette_map.asm')
        dest = attrs(rpp / 'color/tilesets/johto_gate.asm')
    except (ValueError, OSError, IndexError) as exc:
        return [f'Gold gate palette mapping cannot be established: {exc}']
    if len(source) != 96 or len(dest) != 96:
        return ['Gold gate palette assignment must have 96 tiles on both sides']
    return [f'GOLD GATE palette mismatch: compact tile {compact:02x} from Gold tile {orig:02x}: '
            f'{dest[compact]} != {source[orig]}'
            for compact, orig in sorted(compact_to_source.items())
            if compact >= len(dest) or orig >= len(source) or dest[compact] != source[orig]]


def verify_gold_gate_art(rpp, gold):
    """Compare actual room pixels and 16x16 collision evidence against Gold.

    Unlike the former art-adapter check, this validates the 159 imported
    resources without presuming numeric tile ID equivalence across engines.
    """
    from PIL import Image
    from johto_gold_sources import gold_block_sources
    from johto_rpp_asset_audit import blocks_for, gold_resource_aliases, collision_labels

    errors = []
    aliases = gold_resource_aliases(gold)
    src_layout = (gold/gold_block_sources(gold)['Route31VioletGate']).read_bytes()
    dst_layout = (rpp/'maps/JohtoRoute31VioletGate.blk').read_bytes()
    original_ids = sorted(set(src_layout))
    if len(src_layout)!=20 or len(dst_layout)!=20 or len(original_ids)!=GOLD_GATE_SOURCE_BLOCKS:
        return ['GOLD GATE layout/unique metatiles differ from reviewed 5x4 source']
    if dst_layout!=bytes(original_ids.index(v) for v in src_layout):
        errors.append('RPP room layout no longer remaps Gold original metatiles exactly')
        return errors
    source_blocks,_,_ = blocks_for(gold,'gate','gold', aliases)
    target_blocks=(rpp/'gfx/blocksets/johto_gate.bst').read_bytes()
    is_border_fixed = 'GATE-5.62.159@' not in text(rpp,'data/game_version.asm')
    expected_count = len(original_ids) + int(is_border_fixed)
    if len(target_blocks)!=expected_count*16:
        return [f'JOHTO_GATE .bst is not {expected_count} complete 32x32 metatiles']
    gold_labels,_ = collision_labels(gold,'gate', aliases)
    allowed=set((rpp/'gfx/tilesets/gate.tilecoll').read_bytes()[:-1])
    tiles_used=set()
    with Image.open(gold/'gfx/tilesets/gate.png') as src, Image.open(rpp/'gfx/tilesets/johto_gate.png') as dest:
        src=src.convert('RGBA'); dest=dest.convert('RGBA')
        if dest.size!=(128,48): errors.append('JOHTO_GATE artwork must have 96 8x8 slots')
        for compact,source_id in enumerate(original_ids):
            qlabels = [x.strip() for x in gold_labels[source_id].split(',')]
            for cell in range(16):
                source_tile=source_blocks[source_id*16+cell]
                target_tile=target_blocks[compact*16+cell]
                tiles_used.add(source_tile)
                source_box=(source_tile%16*8, source_tile//16*8, source_tile%16*8+8, source_tile//16*8+8)
                target_box=(target_tile%16*8, target_tile//16*8, target_tile%16*8+8, target_tile//16*8+8)
                if src.crop(source_box).tobytes()!=dest.crop(target_box).tobytes():
                    errors.append(f'GOLD pixel mismatch: block {source_id}, cell {cell}')
                quadrant=(cell//4//2)*2+(cell%4//2)
                label=qlabels[quadrant]
                passable=label=='FLOOR' or label.startswith('WARP_CARPET_')
                if (target_tile in allowed)!=passable:
                    errors.append(f'GOLD/RPP walkability mismatch: block {source_id}, cell {cell}')
    errors.extend(verify_gold_gate_palette_map(rpp, gold))
    from johto_gate_rgb_audit import verify as verify_gold_gate_rgb
    errors.extend(verify_gold_gate_rgb(rpp, gold))
    if len(tiles_used)!=GOLD_GATE_SOURCE_TILES:
        errors.append('Gold source no longer uses 22 referenced tiles')
    if is_border_fixed:
        # Verify the out-of-bounds metatile independently of the 5x4 room.
        # The old GATE object border $0a now means a *wall* in JOHTO_GATE.
        from johto_indoor_border_adapter import _load_palette_entries, _parse_border
        object_source = text(rpp,'data/mapObjects/JohtoRoute31VioletGate.asm')
        border_id,_ = _parse_border(object_source,'JohtoRoute31VioletGate')
        if border_id != len(original_ids):
            errors.append(f'JOHTO_GATE border must be independent metatile {len(original_ids)}, got {border_id}')
        elif border_id*16+16 > len(target_blocks):
            errors.append('Border metatile index exceeds .bst')
        else:
            border_tiles=set(target_blocks[border_id*16:(border_id+1)*16])
            if len(border_tiles)!=1 or any(tile in allowed for tile in border_tiles):
                errors.append('Border metatile must reference one impassable tile ID only')
            else:
                only=next(iter(border_tiles))
                pal=_load_palette_entries(rpp/'color/tilesets/johto_gate.asm')
                with Image.open(rpp/'gfx/tilesets/johto_gate.png') as atlas:
                    tile=atlas.convert('RGB').crop(((only%16)*8,(only//16)*8,
                                                    (only%16+1)*8,(only//16+1)*8))
                    if tile.getbbox() is not None or pal[only]!='GRAY':
                        errors.append('Border must render solid black in GRAY palette')
    from johto_indoor_tiles_converter import strict_2bpp
    makefile = text(rpp, 'Makefile')
    if not re.search(r'(?m)^gfx/tilesets/johto_gate\.2bpp:\s+gfx/tilesets/johto_gate\.png\s*\n\s+\$\(RGBGFX\) -o \$@ \$<', makefile):
        errors.append('Missing dedicated non-trimming 96-tile 2bpp build rule')
    with Image.open(rpp/'gfx/tilesets/johto_gate.png') as graphic:
        expected = strict_2bpp(graphic,96)
    if len(expected) != 96*16:
        errors.append('PNG does not encode a fixed 96-slot graphics window')
    generated = rpp/'gfx/tilesets/johto_gate.2bpp'
    if generated.exists() and expected != generated.read_bytes():
        errors.append('Generated 2bpp does not match the PNG (stale or trimmed artifact)')
    hdr=text(rpp,'data/mapHeaders/JohtoRoute31VioletGate.asm')
    if not re.search(r'^\s*db JOHTO_GATE\b',hdr,re.M): errors.append('Room not registered to its own tileset')
    if not all(t in text(rpp,'home/overworld.asm').split('ExtraWarpCheck::',1)[1].split('MapEntryAfterBattle::',1)[0] for t in ('ld hl, IsPlayerFacingEdgeOfMap', 'ld hl, IsWarpTileInFrontOfPlayer', 'ld b, BANK(IsWarpTileInFrontOfPlayer)')):
        errors.append('Missing map-edge Warp check for JOHTO_GATE')
    if 'dw JohtoGateWarpTileIDs' not in text(rpp,'data/warp_tile_ids.asm'):
        errors.append('JOHTO_GATE WarpTile pointer missing')
    return errors


def audit(rpp, gold):
    rpp, gold = Path(rpp), Path(gold)
    problems = preflight(rpp, gold)
    if problems: return problems  # hard-stop, no extrapolation on partial sources
    if not any(v in text(rpp,'data/game_version.asm') for v in
               ('GATE-5.62.159@','GATE-5.62.160@','MUS-5.62.161@','MUS-5.62.162@','MUS-5.62.163@')):
        problems.append('WRONG RPP BASE: expected GATE-5.62.159/160 or MUS-5.62.161-163 Gold gate')
    # GATE-5.62.157: the portal remains walkable, but stepping on it must
    # never auto-warp. The second outward input collides and uses native Warp.
    # The outdoor entrance 16x16 cells still contain four $40 subtiles.
    coll=(rpp/'gfx/tilesets/johto.tilecoll').read_bytes()
    if coll != bytes((3,4,5,6,0x40,0xff)):
        problems.append('RPP JOHTO COLLISION must allow gate portal tile $40')
    if not re.search(r'NewBarkWarpTileIDs:\s*db\s+\$06,\$FF',text(rpp,'data/warp_tile_ids.asm')):
        problems.append('RPP JOHTO WARP TILES must exclude $40 (no standing auto-warp)')
    src = text(rpp,'home/overworld.asm')
    facing = text(rpp,'engine/overworld/player_state.asm')
    if 'cp JOHTO_ROUTE31_VIOLET_GATE' not in src[src.index('CheckWarpsNoCollisionLoop::'):src.index('CheckWarpsCollision::')]:
        problems.append('RPP missing gate on-step Warp suppression')
    if 'cp JOHTO_ROUTE_31' not in facing[facing.index('IsPlayerFacingEdgeOfMap:'):facing.index('IsWarpTileInFrontOfPlayer:')]:
        problems.append('RPP missing Route31 pseudo-edge facing check')
    bst=(rpp/'gfx/blocksets/johto.bst').read_bytes()
    for basename,width,points in (('JohtoRoute31',20,[(4,6),(4,7)]),
                                  ('JohtoVioletCity',20,[(39,24),(39,25)])):
        blocks=(rpp/f'maps/{basename}.blk').read_bytes()
        for x,y in points:
            bid=blocks[(y//2)*width+x//2]
            sub=bst[bid*16:(bid+1)*16]
            row=(y%2)*2; col=(x%2)*2
            portal=[sub[row*4+col],sub[row*4+col+1],sub[(row+1)*4+col],sub[(row+1)*4+col+1]]
            if portal!=[0x40]*4:
                problems.append(f'{basename} entry ({x},{y}) changed from portal tile $40: {portal}')
    # Avoid making an unrelated Johto floor tile walkable by accident.
    gate_blocks={b for b in range(len(bst)//16) if 0x40 in bst[b*16:(b+1)*16]}
    for basename in ('JohtoRoute29','JohtoRoute30','JohtoCherrygroveCity'):
        ids=set((rpp/f'maps/{basename}.blk').read_bytes())
        if ids & gate_blocks:
            problems.append(f'{basename} unexpectedly uses gate portal tile $40')
    constants = text(rpp,'constants/map_constants.asm')
    if not re.search(r'mapconst JOHTO_ROUTE31_VIOLET_GATE,\s*4,\s*5\b',constants):
        problems.append('RPP GATE DIMENSIONS must be Height=4 Width=5 (Gold 5x4)')
    if len((gold/'maps/EastWestGate.blk').read_bytes()) != 20:
        problems.append('GOLD EastWestGate 5x4 source is not 20 blocks')
    if 'Route31VioletGate_Blocks:' not in text(gold,'data/maps/blocks.asm'):
        problems.append('GOLD shared EastWestGate map label missing')
    if 'INCBIN "maps/EastWestGate.blk"' not in text(gold,'data/maps/blocks.asm'):
        problems.append('GOLD shared EastWestGate reference missing')
    gg = [(int(x),int(y),m,int(dest)) for x,y,m,dest in WARP_GOLD.findall(text(gold,'maps/Route31VioletGate.asm'))]
    if gg != GOLD_GATE: problems.append(f'GOLD GATE WARPS changed: {gg!r}')
    gold_route = [(int(x),int(y),m,int(dest)) for x,y,m,dest in WARP_GOLD.findall(text(gold,'maps/Route31.asm'))]
    if gold_route[:2] != [(4,6,'ROUTE_31_VIOLET_GATE',3),(4,7,'ROUTE_31_VIOLET_GATE',4)]:
        problems.append('GOLD Route31 original gate coordinates changed')
    gold_city = [(int(x),int(y),m,int(dest)) for x,y,m,dest in WARP_GOLD.findall(text(gold,'maps/VioletCity.asm'))]
    if gold_city[-2:] != [(39,24,'ROUTE_31_VIOLET_GATE',1),(39,25,'ROUTE_31_VIOLET_GATE',2)]:
        problems.append('GOLD VioletCity original gate coordinates changed')
    for name,expected in RPP_EXPECTED.items():
        got=[(int(y),int(x),int(i),m) for y,x,i,m in WARP_RPP.findall(text(rpp,'data/mapObjects/'+name))]
        if got!=expected: problems.append(f'RPP WARPS {name}: {got!r} expected {expected!r}')
    try:
        problems.extend(verify_gold_gate_art(rpp, gold))
    except (ValueError, OSError, IndexError, KeyError) as ex:
        problems.append(f'Original Gold gate art check failed: {ex}')
    refs={
        'constants/region_map_constants.asm':['JOHTO_ROUTE31_VIOLET_GATE_LOCAL_ID EQU 6','NUM_JOHTO_MAPS EQU 7'],
        'data/johto_map_headers.asm':['dw JohtoRoute31VioletGate_h','db BANK(JohtoRoute31VioletGate_h)','db JOHTO_ROUTE31_VIOLET_GATE'],
        'data/map_header_banks.asm':['db BANK(JohtoRoute31VioletGate_h)'],
        'data/map_header_pointers.asm':['dw JohtoRoute31VioletGate_h'],
        'data/mapHeaders/JohtoRoute31VioletGate.asm':['db JOHTO_GATE','JOHTO_ROUTE31_VIOLET_GATE_HEIGHT, JOHTO_ROUTE31_VIOLET_GATE_WIDTH'],
        'main.asm':['INCLUDE "data/mapHeaders/JohtoRoute31VioletGate.asm"','INCLUDE "data/mapObjects/JohtoRoute31VioletGate.asm"', 'JohtoRoute31VioletGateBlocks: INCBIN "maps/JohtoRoute31VioletGate.blk"'],
        'RPP_DEVELOPMENT_PITFALLS.md':['SRC-PREFLIGHT-151','Gold 双源码'],
        }
    for rel,markers in refs.items():
        data=text(rpp,rel)
        for marker in markers:
            if marker not in data: problems.append(f'RPP MISSING REGISTRATION {rel}: {marker}')
    for name in ('JohtoRoute31.asm','JohtoVioletCity.asm'):
        src=text(rpp, 'data/mapHeaders/'+name)
        if re.search(r'^\s*(WEST_MAP_CONNECTION|EAST_MAP_CONNECTION)\b', src, re.M):
            problems.append(f'RPP FORBIDDEN outdoor straight crossing: {name}')
    return problems


if __name__=='__main__':
    parser=argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--rpp',required=True,type=Path)
    parser.add_argument('--gold',required=True,type=Path)
    args=parser.parse_args()
    errors=audit(args.rpp,args.gold)
    if errors:
        print('FAIL - incomplete/mismatched source; stop modifications:')
        print('\n'.join(errors))
        sys.exit(1)
    print('PASS - RPP + Gold source present; original 5x4 gate, exact warp coordinates, map registrations (STATIC ONLY)')
