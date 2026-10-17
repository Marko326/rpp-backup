#!/usr/bin/env python3
"""Stage Gold indoor .blk only when every used 32x32 block is pixel-identical.

Never transfer raw Gold metatile IDs to RPP based on numeric equality.
If art or a PNG atlas is missing, produce a mapping review, NOT an importable map.
Collision, palette, animations and runtime behavior remain separate gates.
"""
from __future__ import annotations
import argparse
from collections import Counter
from PIL import Image
from pathlib import Path
from johto_gold_sources import gold_block_sources
from johto_rpp_asset_audit import load_png_tiles, metatile_entries, blocks_for, gold_resource_aliases
from johto_indoor_common import ConversionError, dump, gold_dimensions, safe_roots, sha


def build_mapping(rpp: Path, gold: Path, map_name='Route31VioletGate',
                  gold_set='gate', rpp_set='gate'):
    w,h=gold_dimensions(gold,map_name)
    src_name=gold_block_sources(gold).get(map_name)
    if not src_name: raise ConversionError(f'Gold 未找到 {map_name} 共享布局引用')
    original=(gold/src_name).read_bytes()
    if len(original)!=w*h:raise ConversionError(f'{map_name} Gold 布局长度不对')
    gblocks,_,_=blocks_for(gold,gold_set,'gold',gold_resource_aliases(gold))
    rblocks,_,_=blocks_for(rpp,rpp_set,'rpp')
    if not gblocks or not rblocks:raise ConversionError('Gold/RPP 目标区块集缺失')
    gtiles=load_png_tiles(gold/'gfx/tilesets'/f'{gold_set}.png')
    rpp_png=rpp/'gfx/tilesets'/f'{rpp_set}.png'
    if not rpp_png.is_file():rpp_png=rpp/'gfx/tilesets'/f'{rpp_set}.t1.png'
    rtiles=load_png_tiles(rpp_png)
    gold_entries=metatile_entries(gblocks,gtiles)
    rpp_entries=metatile_entries(rblocks,rtiles)
    lookup={}
    for e in rpp_entries:
        if e['pixel_sha']: lookup.setdefault(e['pixel_sha'],[]).append(e['id'])
    # Use the exact-pixel signature, not shape similarity or coincidental IDs.
    used=Counter(original)
    plan={}; missing=[]
    for block,count in sorted(used.items()):
        if block>=len(gold_entries):raise ConversionError(f'Gold 区块 ID 超界: {block}')
        entry=gold_entries[block]
        targets=lookup.get(entry['pixel_sha'],[]) if entry['pixel_sha'] else []
        row={'gold_block_id':block,'count':count,'gold_pixel_sha':entry['pixel_sha'],
             'rpp_candidates':targets, 'status':'PIXEL_EXACT' if targets else 'REVIEW_ART'}
        plan[block]=row
        if not targets:missing.append(block)
    compatible=len(missing)==0 and bool(gtiles) and bool(rtiles)
    result={'schema':'johto-indoor-art-v1','source_map':map_name,
            'gold_layout':src_name,'gold_layout_sha256':sha(original),
            'gold_tileset':gold_set,'rpp_tileset':rpp_set,'rpp_png':str(rpp_png.relative_to(rpp)),
            'width':w,'height':h,'block_count':w*h,
            'used_unique_blocks':len(used),'exact_mapped':len(plan)-len(missing),
            'unmapped':missing,'mapping':list(plan.values()),
            'can_stage_pixel_exact_candidate':compatible,
            'status':'PIXEL_CANDIDATE_ONLY' if compatible else 'BLOCKED_ART_REVIEW',
            'important':'pixel match is NOT verified collision, palette or ROM registration'}
    converted=(bytes(plan[v]['rpp_candidates'][0] for v in original) if compatible else None)
    return result,converted


def stage_preserved_gold_tileset(gold: Path, output: Path, map_name: str,
                                 gold_set: str, fixed_slots: int = 96) -> dict:
    """Emit a *read-only* full-ID Gold map/art candidate, not ROM integration.

    Unlike the existing compact candidate, source block/tile IDs are kept.
    No RPP assets or any map-specific script are read to create the result.
    """
    from johto_rpp_asset_audit import collision_labels
    w, h = gold_dimensions(gold, map_name)
    source = gold_block_sources(gold).get(map_name)
    if source is None:
        raise ConversionError('Gold source map has no unique blocks location')
    layout = (gold / source).read_bytes()
    blocks, source_blocks, _ = blocks_for(gold, gold_set, 'gold', gold_resource_aliases(gold))
    image_path = gold / 'gfx/tilesets' / (gold_set + '.png')
    tiles = load_png_tiles(image_path)
    collision, collision_file = collision_labels(gold, gold_set, gold_resource_aliases(gold))
    block_count = len(blocks)//16
    if (not blocks or len(blocks)%16 or block_count > 256 or not tiles
            or not collision or len(collision) != block_count):
        raise ConversionError('Gold tileset art/collision incomplete or unexpected block count')
    if len(layout) != w*h or any(b >= block_count for b in layout):
        raise ConversionError('Gold map width/height or layout indices invalid')
    # Gold's unreferenced border tiles may use 0xff, which must never be
    # silently used as a real image ID by the staged map.
    used = sorted(set(layout))
    used_image_ids = {i for b in used for i in blocks[b*16:(b+1)*16]}
    if max(used_image_ids) >= fixed_slots or max(used_image_ids) >= len(tiles):
        raise ConversionError('Used Gold graphics exceed RPP candidate tile window')
    folder = output/'preserved_gold_art_candidate'
    if folder.exists():
        raise ConversionError('candidate already exists')
    folder.mkdir(parents=True)
    (folder/(map_name+'.blk')).write_bytes(layout)
    (folder/(gold_set+'.bst')).write_bytes(blocks)
    import shutil
    shutil.copyfile(image_path, folder/(gold_set+'.png'))  # preserve Gold PNG bytes
    return {'schema':'gold-full-id-candidate-v1', 'map':map_name,
            'tileset':gold_set, 'width':w, 'height':h,
            'used_block_count':len(used), 'used_graphic_count':len(used_image_ids),
            'tile_slots':fixed_slots, 'source_layout':source,
            'source_blockset':source_blocks, 'source_collision':collision_file,
            'layout_sha256':sha(layout), 'blockset_sha256':sha(blocks),
            'source_png_sha256':sha(image_path.read_bytes()),
            'candidate_only':True, 'engine_implementation':False,
            'needs_runtime_review':['palette','VRAM','tileset registry',
                'map header','warp and connection safety','special movement',
                'Surf/Fly/Dig permits','bank space']}


def strict_2bpp(tile_image: Image.Image, width_slots: int) -> bytes:
    """Encode isolated grayscale candidates to exactly the RPP loader window.

    No color conversion is inferred: only the four original GB grays are
    accepted. Check a pixel-exact 2bpp -> RGBA roundtrip before returning.
    """
    rgba = tile_image.convert('RGBA')
    if rgba.width % 8 or rgba.height % 8:
        raise ConversionError('候选图集尺寸必须是 8 的倍数')
    source_columns = rgba.width // 8
    total = source_columns * (rgba.height // 8)
    if total > width_slots:
        raise ConversionError('候选图块数量超过载入窗口')
    color_to_index = {(255,255,255,255):0, (170,170,170,255):1,
                      (85,85,85,255):2, (0,0,0,255):3}
    index_to_color = {v:k for k,v in color_to_index.items()}
    encoded = bytearray()
    pixels = rgba.load()
    for tile in range(total):
        ox, oy = (tile % source_columns)*8, (tile // source_columns)*8
        for row in range(8):
            lo = hi = 0
            for x in range(8):
                sample = pixels[ox+x, oy+row]
                if sample not in color_to_index:
                    raise ConversionError('非 4 阶原始灰度：禁止推断 2bpp 像素编码')
                color = color_to_index[sample]
                lo |= (color & 1) << (7-x)
                hi |= ((color >> 1) & 1) << (7-x)
            encoded.extend((lo, hi))
    if len(encoded) != 16*total:
        raise AssertionError('2bpp 单图块字节数异常')
    for tile in range(total):
        ox, oy = (tile % source_columns)*8, (tile // source_columns)*8
        for row in range(8):
            lo,hi = encoded[tile*16+row*2:tile*16+row*2+2]
            for x in range(8):
                decoded = (lo >> (7-x) & 1) | ((hi >> (7-x) & 1) << 1)
                if pixels[ox+x, oy+row] != index_to_color[decoded]:
                    raise AssertionError('2bpp 编码与 PNG 逐像素回读不一致')
    encoded.extend(bytes(16*(width_slots-total)))
    return bytes(encoded)


def stage_dedicated_gold_tileset(gold: Path, output: Path, map_name='Route31VioletGate',
                                 gold_set='gate', fixed_slots=96):
    """Isolated *new tileset* candidate when existing RPP art does not match.

    This is not a drop-in GATE replacement: RPP tileset registration, VRAM,
    palettes, door collision and bank budgets remain unapproved.
    """
    w,h=gold_dimensions(gold,map_name)
    source=gold_block_sources(gold).get(map_name)
    if not source: raise ConversionError('Gold map label missing')
    layout=(gold/source).read_bytes()
    blocks,_,_=blocks_for(gold,gold_set,'gold',gold_resource_aliases(gold))
    png=gold/'gfx/tilesets'/f'{gold_set}.png'
    tiles=load_png_tiles(png)
    if not tiles or len(layout)!=w*h or not blocks:
        raise ConversionError('Gold 专用候选缺原始图像/尺寸/区块')
    ids=sorted(set(layout))
    for src_id in ids:
        if (src_id+1)*16>len(blocks):raise ConversionError('Gold 32x32 block ID out of range')
        tiles_used=blocks[src_id*16:(src_id+1)*16]
        if any(t>=len(tiles) for t in tiles_used):
            raise ConversionError(f'Gold tile ID 超出 PNG atlas；需要先解析 VRAM 符号索引：{src_id}')
    # Compact *both* 32x32 metatiles and 8x8 graphics references. Gold tile IDs
    # are not portable directly into a newly registered RPP tileset.
    source_tile_ids = sorted({tile for bid in ids for tile in blocks[bid*16:(bid+1)*16]})
    if len(source_tile_ids) >= fixed_slots or len(ids) >= 255:
        raise ConversionError('候选室内没有额外的独立外围区块/图块槽位')
    new_ids = {old: i for i, old in enumerate(ids)}
    tile_ids = {old: i for i, old in enumerate(source_tile_ids)}
    candidate_layout = bytes(new_ids[b] for b in layout)
    # The room layout and the out-of-bounds border have independent block IDs.
    # Reserving a black border at the conversion stage prevents accidentally
    # re-using a valid wall/floor block as the RPP object's filler.
    border_block_id = len(ids)
    border_tile_id = len(source_tile_ids)
    candidate_blockset = bytes(tile_ids[t] for src_id in ids
                               for t in blocks[src_id*16:(src_id+1)*16]) + bytes([border_tile_id] * 16)
    for i in range(len(layout)):
        original_cells = blocks[layout[i]*16:(layout[i]+1)*16]
        mapped_cells = candidate_blockset[candidate_layout[i]*16:(candidate_layout[i]+1)*16]
        if tuple(source_tile_ids[t] for t in mapped_cells) != tuple(original_cells):
            raise AssertionError('候选图像 tile ID 没有逐格还原')

    # Preserve source PNG mode and exact pixel data. Padding is merely for
    # a rectangular preview; padding slots are NOT assigned in the blockset.
    with Image.open(png) as source_image:
        image = source_image.copy()
    columns = 8
    rows = (len(source_tile_ids)+1+columns-1)//columns
    background = image.getpixel((0, 0))
    compact_image = Image.new(image.mode, (columns*8, rows*8), background)
    source_cols = image.width//8
    for old_id, new_id in tile_ids.items():
        src_x, src_y = (old_id % source_cols)*8, (old_id // source_cols)*8
        dst_x, dst_y = (new_id % columns)*8, (new_id // columns)*8
        compact_image.paste(image.crop((src_x, src_y, src_x+8, src_y+8)),
                            (dst_x, dst_y))
    # Dedicated void tile is solid black; Gold may use a different entry for
    # the out-of-bounds filler than any block inside the room.
    compact_image.paste(0, ((border_tile_id%columns)*8, (border_tile_id//columns)*8,
                            (border_tile_id%columns+1)*8, (border_tile_id//columns+1)*8))
    # Verify pixel identity, not just remapped numeric IDs.
    for old_id, new_id in tile_ids.items():
        sx, sy = (old_id % source_cols)*8, (old_id // source_cols)*8
        dx, dy = (new_id % columns)*8, (new_id // columns)*8
        if image.crop((sx, sy, sx+8, sy+8)).convert('RGBA').tobytes() != \
           compact_image.crop((dx, dy, dx+8, dy+8)).convert('RGBA').tobytes():
            raise ConversionError('压缩后的 PNG tile 与 Gold 原图不一致')

    folder = output/'isolated_gold_art_candidate'
    if folder.exists(): raise ConversionError('候选目录已存在：拒绝覆盖')
    folder.mkdir(parents=True)
    (folder/f'{map_name}.blk').write_bytes(candidate_layout)
    (folder/f'{gold_set}.bst').write_bytes(candidate_blockset)
    compact_image.save(folder/f'{gold_set}.png')
    # Standalone fixed-length evidence, never referenced from game ASM.
    candidate_2bpp = strict_2bpp(compact_image, fixed_slots)
    (folder/f'{gold_set}.fixed{fixed_slots}.2bpp').write_bytes(candidate_2bpp)
    return {'schema':'johto-isolated-original-art-v2',
            'layout':str((folder/f'{map_name}.blk').relative_to(output)),
            'blockset':str((folder/f'{gold_set}.bst').relative_to(output)),
            'atlas':str((folder/f'{gold_set}.png').relative_to(output)),
            'fixed_2bpp':str((folder/f'{gold_set}.fixed{fixed_slots}.2bpp').relative_to(output)),
            'fixed_2bpp_bytes':len(candidate_2bpp),
            'width':w,'height':h,'used_compacted_blocks':len(ids),
            'compacted_tile_ids':len(source_tile_ids),
            'source_tile_ids':source_tile_ids,
            'source_block_ids':ids,'source_layout_sha256':sha(layout),
            'reserved_black_border_block_id': border_block_id,
            'reserved_black_border_tile_id': border_tile_id,
            'border_block_uses_black_only': True,
            'warning_border_collision_not_mapped': True,
            'status':'PIXEL_ASSET_CANDIDATE_ONLY',
            'warnings':['独立候选专用 tileset，不可覆盖原 RPP gate',
                        'PNG 含 padding；隔离 2bpp 已填充到现有 96 tile 固定窗口，但未注册',
                        '黑色外围预留区块只供未来的 RPP 对象表引用；必须映射到不可通行的 RPP tile ID',
                        '未适配碰撞、VRAM 注册、色板、动画或 ROM Bank',
                        '候选图形未经运行时验证，禁止直接导入 ROM']}


def main(argv=None):
    ap=argparse.ArgumentParser(description=__doc__)
    ap.add_argument('--rpp',type=Path,required=True)
    ap.add_argument('--gold',type=Path,required=True)
    ap.add_argument('--output',type=Path,required=True)
    ap.add_argument('--gold-map',default='Route31VioletGate')
    ap.add_argument('--gold-tileset',default='gate')
    ap.add_argument('--rpp-tileset',default='gate')
    args=ap.parse_args(argv)
    rpp,gold,out=safe_roots(args.rpp,args.gold,args.output)
    result,stage=build_mapping(rpp,gold,args.gold_map,args.gold_tileset,args.rpp_tileset)
    dump(out,'indoor_art.json',result)
    if stage: (out/f'{args.gold_map}.pixel_candidate.blk').write_bytes(stage)
    if not stage:
        fallback=stage_dedicated_gold_tileset(gold,out,args.gold_map,args.gold_tileset)
        dump(out,'isolated_original_art.json',fallback)
    print('indoor graphics:',result['status'], 'used/unmapped:',result['used_unique_blocks'],len(result['unmapped']))
    return 0

if __name__=='__main__':raise SystemExit(main())
