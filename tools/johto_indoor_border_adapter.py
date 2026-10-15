#!/usr/bin/env python3
"""Offline, source-safe RPP indoor border adapter.

A Gold -> RPP interior must translate two independent block namespaces:
(1) the map's .blk cells, and (2) the object table's out-of-bounds
"border block". Re-using the latter's old numeric value corrupts the visible
void even when the entire 5x4 interior is pixel-perfect.

This utility writes ONLY an isolated output directory, never the RPP tree.
It adds a dedicated black, impassable 32x32 border metatile and reports its
new ID; the color/graphics/collision evidence is checked rather than guessed.
"""
from __future__ import annotations

import argparse
import hashlib
import json
import re
from pathlib import Path
from PIL import Image

from johto_indoor_common import ConversionError


GREYS = {(255, 255, 255), (170, 170, 170), (85, 85, 85), (0, 0, 0)}


def _sha(data: bytes) -> str:
    return hashlib.sha256(data).hexdigest()


def _load_palette_entries(path: Path) -> list[str]:
    result: list[str] = []
    for line in path.read_text(encoding='utf-8').splitlines():
        row = re.match(r'^\s*tilepal\s+0\s*,\s*([^;]+)', line)
        if row:
            parts = [part.strip() for part in row[1].split(',')]
            if len(parts) != 8:
                raise ConversionError('调色表每行必须恰好 8 个 tilepal')
            result.extend(parts)
    if not result:
        raise ConversionError('未找到图块调色映射')
    return result


def _parse_border(obj_text: str, room: str) -> tuple[int, tuple[int, int]]:
    label = re.search(r'(?m)^' + re.escape(room) +
                      r'Object:\s*\n(?P<row>\s*db\s+(?:\$[0-9a-fA-F]{1,2}|\d+))',
                      obj_text)
    if not label:
        raise ConversionError('目标房间对象表缺少边界区块 ID')
    raw = re.search(r'\bdb\s+(\$[0-9a-fA-F]+|\d+)', label['row'])[1]
    num = int(raw[1:], 16) if raw.startswith('$') else int(raw)
    return num, label.span('row')


def _preview(blocks: bytes, layout: bytes, atlas: Image.Image, width: int,
             border_id: int, ring: int) -> Image.Image:
    height = len(layout) // width
    dest = Image.new('RGB', ((width+2*ring)*32, (height+2*ring)*32))
    for by in range(height+2*ring):
        for bx in range(width+2*ring):
            interior = ring <= by < height+ring and ring <= bx < width+ring
            bid = layout[(by-ring)*width+(bx-ring)] if interior else border_id
            for sub in range(16):
                tid = blocks[bid*16+sub]
                left, top = (tid % (atlas.width//8))*8, (tid // (atlas.width//8))*8
                dest.paste(atlas.crop((left, top, left+8, top+8)),
                           ((bx*32)+(sub%4)*8, (by*32)+(sub//4)*8))
    return dest


def build(rpp: Path, out: Path, *, room='JohtoRoute31VioletGate',
          tileset='johto_gate', collision='gate', map_width=5,
          fixed_slots=96) -> dict:
    rpp, out = rpp.resolve(), out.resolve()
    if not rpp.is_dir() or out == rpp or rpp in out.parents or out in rpp.parents:
        raise ConversionError('输出目录必须位于 RPP 源码外')
    if out.exists() and (out.is_symlink() or not out.is_dir() or any(out.iterdir())):
        raise ConversionError('输出目录必须不存在或为空')
    if not (1 <= fixed_slots <= 256 and 1 <= map_width <= 255):
        raise ConversionError('图块窗口或地图宽度非法')
    image_path = rpp / f'gfx/tilesets/{tileset}.png'
    block_path = rpp / f'gfx/blocksets/{tileset}.bst'
    map_path = rpp / f'maps/{room}.blk'
    object_path = rpp / f'data/mapObjects/{room}.asm'
    collision_path = rpp / f'gfx/tilesets/{collision}.tilecoll'
    palette_path = rpp / f'color/tilesets/{tileset}.asm'
    paths = (image_path, block_path, map_path, object_path, collision_path, palette_path)
    if any(not p.is_file() or p.is_symlink() for p in paths):
        raise ConversionError('源素材/碰撞/房间对象/调色配置缺失或是符号链接')
    with Image.open(image_path) as im:
        atlas = im.convert('RGB')
    if atlas.width % 8 or atlas.height % 8 or atlas.width*atlas.height != fixed_slots*64:
        raise ConversionError('图集必须完整包含固定图形加载窗口')
    if any(pixel not in GREYS for pixel in atlas.get_flattened_data()):
        raise ConversionError('图集不是可无损转换的原始四色灰度')
    blocks = block_path.read_bytes()
    layout = map_path.read_bytes()
    if not blocks or len(blocks)%16 or len(blocks)//16 >= 256:
        raise ConversionError('区块集大小非法或没有剩余区块编号')
    if not layout or len(layout)%map_width or max(layout)*16+16>len(blocks):
        raise ConversionError('地图 .blk 长度或区块引用非法')
    if any(tile >= fixed_slots for tile in blocks):
        raise ConversionError('区块图块编号超出固定窗口')
    old_obj = object_path.read_text(encoding='utf-8')
    previous, span = _parse_border(old_obj, room)
    if previous >= len(blocks)//16:
        raise ConversionError('当前外围 ID 在图块集中不存在')
    palette = _load_palette_entries(palette_path)
    if len(palette) != fixed_slots:
        raise ConversionError('调色条目与图块窗口不一致')
    whitelist = collision_path.read_bytes()
    if not whitelist or whitelist[-1] != 0xff or 0xff in whitelist[:-1]:
        raise ConversionError('碰撞白名单终止符错误')
    walkable = set(whitelist[:-1])
    # Prefer a free blocked GRAY slot. Never reassign or change a tile already
    # referenced by any in-room metatile (including walls and door carpets).
    used_tiles = set(blocks)
    free = [i for i in range(fixed_slots)
            if i not in used_tiles and i not in walkable and palette[i] == 'GRAY']
    if not free:
        raise ConversionError('没有空闲且不可通行的灰色图块槽位，禁止覆盖现有图块')
    black_id = free[0]
    new_border_id = len(blocks)//16
    border_block = bytes([black_id]*16)
    result_blocks = blocks + border_block
    modified_atlas = atlas.copy()
    columns = atlas.width//8
    x, y = (black_id%columns)*8, (black_id//columns)*8
    modified_atlas.paste((0,0,0), (x,y,x+8,y+8))
    new_line = (f'\tdb ${new_border_id:02x} ; dedicated solid-black, impassable '+
                '32x32 out-of-map border block')
    row_end = old_obj.find('\n', span[1])
    if row_end < 0:
        raise ConversionError('对象表的边界数据行不完整')
    result_object = old_obj[:span[0]]+new_line+old_obj[row_end:]
    # A complete render, NOT only the 5x4 room, is the acceptance criterion.
    original_inner = _preview(blocks, layout, atlas, map_width, previous, 0)
    resulting_inner = _preview(result_blocks, layout, modified_atlas,
                               map_width, new_border_id, 0)
    if original_inner.tobytes() != resulting_inner.tobytes():
        raise ConversionError('添加外围区块错误地修改了房间内部像素')
    border = _preview(result_blocks, layout, modified_atlas,
                      map_width, new_border_id, 1)
    for by in range(0, border.height, 32):
        for bx in range(0, border.width, 32):
            if bx in (0,border.width-32) or by in (0,border.height-32):
                if border.crop((bx,by,bx+32,by+32)).getbbox():
                    raise ConversionError('外围仍有非黑色素材')
    if black_id in walkable or black_id in used_tiles:
        raise ConversionError('外围槽位覆盖了可走地板或已使用素材')
    # The user's .2bpp is ignored build output; NEVER stage it as source.
    outputs = {str(image_path.relative_to(rpp)): modified_atlas,
               str(block_path.relative_to(rpp)): result_blocks,
               str(object_path.relative_to(rpp)): result_object}
    out.mkdir(parents=True, exist_ok=True)
    for rel, data in outputs.items():
        target = out / rel
        target.parent.mkdir(parents=True, exist_ok=True)
        if isinstance(data, Image.Image):
            data.save(target)
        elif isinstance(data, bytes):
            target.write_bytes(data)
        else:
            target.write_text(data, encoding='utf-8')
    border.save(out/'preview_including_border.png')
    report = {'schema': 'johto-indoor-border-v1', 'room':room, 'tileset':tileset,
              'original_border_metatile':previous, 'new_border_metatile':new_border_id,
              'new_black_tile_slot':black_id, 'blockset_count':len(result_blocks)//16,
              'fixed_tile_slots':fixed_slots, 'black_palette':palette[black_id],
              'non_walkable':black_id not in walkable,
              'interior_pixel_identical':True, 'border_all_black':True,
              'generated_source_paths':list(outputs),
              'generated_2bpp':False, 'gameplay_tested':False,
              'room_layout_sha256':_sha(layout),
              'pre_conversion_blockset_sha256':_sha(blocks),
              'preview_sha256':_sha(border.tobytes())}
    (out/'border_report.json').write_text(json.dumps(report,indent=2,ensure_ascii=False)+'\n',encoding='utf-8')
    return report


def main(argv=None):
    ap=argparse.ArgumentParser(description=__doc__)
    ap.add_argument('--rpp',type=Path,required=True)
    ap.add_argument('--output',type=Path,required=True)
    ap.add_argument('--room',default='JohtoRoute31VioletGate')
    ap.add_argument('--tileset',default='johto_gate')
    ap.add_argument('--collision',default='gate')
    ap.add_argument('--map-width',type=int,default=5)
    args=ap.parse_args(argv)
    report=build(args.rpp,args.output,room=args.room,tileset=args.tileset,
                 collision=args.collision,map_width=args.map_width)
    print(json.dumps(report,indent=2,ensure_ascii=False))


if __name__=='__main__':
    main()
