#!/usr/bin/env python3
"""Extract evidence about an existing RPP door/edge-warp pattern.

This is an inspection tool, not a statement that any second map behaves alike.
Different tilesets can route through different ExtraWarpCheck branches.
"""
from __future__ import annotations

import argparse
from collections import defaultdict
from pathlib import Path

from johto_indoor_common import (ConversionError, dump, rpp_dimensions,
                                 rpp_tileset, rpp_warps, safe_roots)


def edge_of(warp: dict, width: int, height: int) -> str:
    """Coordinates here are 16x16 *tiles*; width/height are 32x32 blocks."""
    x, y = warp['x'], warp['y']
    if not (0 <= x < width * 2 and 0 <= y < height * 2):
        raise ConversionError(f'Warp 超出地图边界: ({x},{y}) / {width}x{height} blocks')
    edge = []
    if x == 0: edge.append('WEST')
    if x == width * 2 - 1: edge.append('EAST')
    if y == 0: edge.append('NORTH')
    if y == height * 2 - 1: edge.append('SOUTH')
    return '+'.join(edge) if edge else 'INTERIOR'


def profile(rpp: Path, room: str) -> dict:
    width, height = rpp_dimensions(rpp, room)
    warps = rpp_warps(rpp, room)
    groups = defaultdict(list)
    for warp in warps:
        where = edge_of(warp, width, height)
        groups[where].append({'id': warp['id'], 'x': warp['x'],
                              'y': warp['y'], 'dest_map': warp['dest_map'],
                              'dest_id': warp['dest_id']})
    ports = []
    for edge, items in sorted(groups.items()):
        if edge == 'INTERIOR' or '+' in edge:
            for item in items:
                ports.append({'edge': edge, 'warp_ids': [item['id']],
                              'tiles': [[item['x'], item['y']]]})
            continue
        axis = 'y' if edge in ('WEST', 'EAST') else 'x'
        secondary = 'x' if axis == 'y' else 'y'
        last = None
        cluster = []
        for item in sorted(items, key=lambda it: (it[axis], it[secondary])):
            if last is not None and item[axis] != last + 1:
                ports.append({'edge': edge, 'warp_ids': [w['id'] for w in cluster],
                              'tiles': [[w['x'], w['y']] for w in cluster]})
                cluster = []
            cluster.append(item)
            last = item[axis]
        if cluster:
            ports.append({'edge': edge, 'warp_ids': [w['id'] for w in cluster],
                          'tiles': [[w['x'], w['y']] for w in cluster]})
    return {'schema': 'johto-native-reference-profile-v1', 'map': room,
            'width_blocks': width, 'height_blocks': height,
            'tileset': rpp_tileset(rpp, room), 'warp_count': len(warps),
            'edge_ports': ports, 'warps': warps,
            'runtime_behavior': 'NOT_PROVEN_BY_SOURCE',
            'caution': '边缘入口形状相似不等于 Warp 状态、方向和碰撞相同'}


def compare(reference: dict, target: dict) -> dict:
    """Compare edge-port topology only; never approve gameplay from geometry."""
    def shape(p):
        return sorted((entry['edge'], len(entry['warp_ids']))
                      for entry in p['edge_ports'] if entry['edge'] != 'INTERIOR')
    reference_shape, target_shape = shape(reference), shape(target)
    return {'reference': reference['map'], 'target': target['map'],
            'reference_edges': reference_shape, 'target_edges': target_shape,
            'same_edge_port_shape': reference_shape == target_shape,
            'runtime_equivalent': False,
            'status': 'GEOMETRY_MATCH_ONLY' if reference_shape == target_shape
                      else 'REVIEW_DIFFERENT_DOOR_GEOMETRY'}


def main(argv=None):
    ap = argparse.ArgumentParser(description=__doc__)
    for name in ('rpp', 'gold', 'output'):
        ap.add_argument('--' + name, type=Path, required=True)
    ap.add_argument('--reference-room', default='Route15Gate1F')
    ap.add_argument('--rpp-room', default='JohtoRoute31VioletGate')
    args = ap.parse_args(argv)
    rpp, _, output = safe_roots(args.rpp, args.gold, args.output)
    reference, target = profile(rpp, args.reference_room), profile(rpp, args.rpp_room)
    result = {'reference': reference, 'target': target, 'comparison': compare(reference, target)}
    dump(output, 'native_reference_profiles.json', result)
    print(result['comparison']['status'])
    return 0


if __name__ == '__main__':
    raise SystemExit(main())
