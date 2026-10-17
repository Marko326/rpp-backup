#!/usr/bin/env python3
"""Shared source-only helpers for Gold -> RPP indoor *candidates*.

Every output is written to an isolated directory. No ROM assembler, ASM patcher,
or presumed equivalence of the two engines exists in this module.
"""
from __future__ import annotations
import hashlib
import json
from pathlib import Path
import re

class ConversionError(ValueError):
    pass


def safe_roots(rpp: Path, gold: Path, output: Path):
    rpp, gold, output = (Path(x).resolve() for x in (rpp, gold, output))
    for label, src, required in (
        ('RPP', rpp, ('main.asm', 'home/overworld.asm', 'data/warp_tile_ids.asm')),
        ('Gold', gold, ('main.asm', 'data/maps/maps.asm', 'data/maps/blocks.asm')),
    ):
        if not src.is_dir() or any(not (src / name).is_file() for name in required):
            raise ConversionError(f'{label} 源码不完整: {src}')
        if output == src or output in src.parents or src in output.parents:
            raise ConversionError('输出必须与两套源码目录完全分离')
    if output.is_symlink() or (output.exists() and (not output.is_dir() or any(output.iterdir()))):
        raise ConversionError('输出目录必须不存在或为空，且不能是符号链接')
    return rpp, gold, output


def dump(output: Path, name: str, obj):
    output.mkdir(parents=True, exist_ok=True)
    (output/name).write_text(json.dumps(obj, indent=2, ensure_ascii=False)+'\n', encoding='utf-8')


def read(root: Path, relative: str) -> str:
    p = root / relative
    if not p.is_file():
        raise ConversionError(f'缺文件: {p}')
    return p.read_text(encoding='utf-8')


def sha(raw):
    return hashlib.sha256(raw).hexdigest()


def number(value):
    value = value.strip()
    if value.startswith('$'): return int(value[1:], 16)
    if value.lower().startswith('0x'): return int(value, 16)
    if re.fullmatch(r'-?\d+', value): return int(value, 10)
    raise ConversionError(f'不是数字字面值: {value}')


def rpp_warps(rpp: Path, name: str):
    """Read an object table, honoring its explicit warp count and Y/X convention."""
    src = read(rpp, f'data/mapObjects/{name}.asm')
    lines = src.splitlines()
    head = next((i for i, x in enumerate(lines) if re.match(r'^\s*[A-Za-z_][A-Za-z0-9_]*Object:\s*$', x)), None)
    if head is None:
        raise ConversionError(f'未找到 {name}Object 表')
    records = []
    for line in lines[head+1:]:
        m = re.match(r'^\s*db\s+([^;]+)', line)
        if not m: continue
        records.append([p.strip() for p in m[1].split(',')])
    if len(records) < 2 or len(records[1]) != 1:
        raise ConversionError(f'{name} 对象表缺 warp count')
    count = number(records[1][0])
    if count > 255 or len(records) < count+2:
        raise ConversionError(f'{name} warp count 与表体不符')
    result = []
    for i, row in enumerate(records[2:count+2]):
        if len(row) != 4: raise ConversionError(f'{name} warp #{i} 不是4字段')
        y, x, dst_id = (number(s) for s in row[:3])
        if not all(0 <= n <= 255 for n in (x, y, dst_id)):
            raise ConversionError(f'{name} warp #{i} 坐标或目标编号越界')
        result.append({'id': i, 'x': x, 'y': y, 'dest_id': dst_id, 'dest_map': row[3]})
    if len({(w['x'],w['y']) for w in result}) != len(result):
        raise ConversionError(f'{name} 有重复 Warp 坐标')
    return result


def gold_warps(gold: Path, name: str):
    text = read(gold, f'maps/{name}.asm')
    matches = re.findall(r'^\s*warp_event\s+(\d+)\s*,\s*(\d+)\s*,\s*([A-Z_0-9]+)\s*,\s*(\d+)', text, re.M)
    return [{'id': i+1, 'x': int(x), 'y': int(y), 'dest_map': d, 'dest_id': int(slot)}
            for i, (x,y,d,slot) in enumerate(matches)]


def rpp_map_symbol(rpp: Path, map_name: str):
    header = read(rpp, f'data/mapHeaders/{map_name}.asm')
    match = re.search(r'^\s*db\s+([A-Z_0-9]+)_HEIGHT\s*,\s*\1_WIDTH', header, re.M)
    if not match:
        raise ConversionError(f'RPP 未找到地图宽高常量: {map_name}')
    return match[1]

def rpp_dimensions(rpp: Path, map_name: str):
    """Resolve both legacy mapconst and native (region, local_id) dimensions.

    Native width/height come from region_map_constants.asm; never infer a map
    identity from the shared $FC compatibility byte. Conflicting declarations
    fail closed rather than arbitrarily preferring one representation.
    """
    symbol = re.escape(rpp_map_symbol(rpp, map_name))
    legacy = read(rpp, 'constants/map_constants.asm')
    pairs = []
    for height, width in re.findall(
            r'^\s*mapconst\s+' + symbol + r'\s*,\s*(\d+)\s*,\s*(\d+)',
            legacy, re.M):
        pairs.append((int(width), int(height)))
    native_file = rpp / 'constants/region_map_constants.asm'
    if native_file.is_file():
        native = native_file.read_text(encoding='utf-8')
        native_values = {}
        for dimension in ('WIDTH', 'HEIGHT'):
            found = re.findall(r'^\s*DEF\s+' + symbol + '_' + dimension +
                               r'\s+EQU\s+(\d+)\b', native, re.M)
            if len(found) > 1:
                raise ConversionError(f'{map_name} 重复的原生 {dimension} 定义')
            if found:
                native_values[dimension] = int(found[0])
        if native_values:
            if set(native_values) != {'WIDTH', 'HEIGHT'}:
                raise ConversionError(f'{map_name} 原生宽高常量不完整')
            pairs.append((native_values['WIDTH'], native_values['HEIGHT']))
    if not pairs:
        raise ConversionError(f'RPP 未登记尺寸: {map_name}')
    if any(pair != pairs[0] for pair in pairs[1:]) or min(pairs[0]) <= 0:
        raise ConversionError(f'{map_name} 新旧宽高定义不一致或无效: {pairs}')
    return pairs[0]


def gold_dimensions(gold: Path, map_name: str):
    text = read(gold, 'constants/map_constants.asm')
    snake = re.sub(r'(?<!^)(?=[A-Z])','_',map_name).upper()
    raw = re.findall(r'^\s*map_const\s+(\w+)\s*,\s*(\d+)\s*,\s*(\d+)', text, re.M)
    matches = [(int(w),int(h)) for name,w,h in raw if name.replace('_','').lower() == map_name.lower()]
    if len(matches) != 1: raise ConversionError(f'Gold 未找到唯一尺寸: {map_name}')
    return matches[0]


def tile_at(rpp: Path, name: str, x: int, y: int, tileset: str):
    width,height = rpp_dimensions(rpp, name)
    if not (0 <= x < width*2 and 0 <= y < height*2):
        raise ConversionError(f'{name} ({x},{y}) 坐标越界')
    data = (rpp/f'maps/{name}.blk').read_bytes()
    blocks = (rpp/f'gfx/blocksets/{tileset}.bst').read_bytes()
    if len(data) != width*height or len(blocks)%16:
        raise ConversionError(f'{name}/{tileset} .blk/.bst 尺寸不合格')
    block = data[(y//2)*width + x//2]
    if block >= len(blocks)//16: raise ConversionError(f'{name} block ID 越界')
    return [blocks[block*16 + (y%2)*8 + (x%2)*2 + j*4 + i]
            for j in range(2) for i in range(2)]


def rpp_tileset(rpp: Path, name: str):
    text = read(rpp, f'data/mapHeaders/{name}.asm')
    m = re.search(r'^\s*db\s+([A-Z_0-9]+)\s*(?:;[^\n]*)?$', text, re.M)
    if not m: raise ConversionError(f'{name} 找不到 tileset')
    return m[1]


def warp_tile_ids(rpp: Path, symbol: str):
    text = read(rpp, 'data/warp_tile_ids.asm')
    start = re.search(r'^'+re.escape(symbol)+r':\s*$', text, re.M)
    if not start: raise ConversionError(f'找不到 warp tile 表: {symbol}')
    values=[]
    for line in text[start.end():].splitlines():
        line=line.split(';')[0].strip()
        if not line: continue
        if re.match(r'^\w+:$', line):
            if values: break
            continue
        m=re.match(r'^db\s+(.+)$',line)
        if m:
            values += [number(v) for v in m[1].split(',')]
            if 0xff in values: return values[:values.index(0xff)]
    raise ConversionError(f'warp tile 表 {symbol} 没有终止符')


def target_tile_group(tileset: str):
    return {'JOHTO':'NewBarkWarpTileIDs', 'GATE':'GateWarpTileIDs',
            'OVERWORLD':'OverworldWarpTileIDs'}.get(tileset)
