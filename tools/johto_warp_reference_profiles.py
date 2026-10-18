#!/usr/bin/env python3
"""Extract evidence about an existing RPP door/edge-warp pattern.

This is an inspection tool, not a statement that any second map behaves alike.
Different tilesets can route through different ExtraWarpCheck branches.
"""
from __future__ import annotations

import argparse
import json
import re
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



# Audit every Gold gate via the existing warp reference tool. No new conversion
# pipeline, scripts, runtime Warp handler, or automatic movement is introduced.
# A Gold warp_event is a link, NOT evidence of post-warp simulated movement.
GOLD_WARP_EVENT = re.compile(
    r"(?m)^\s*warp_event\s+(\d+)\s*,\s*(\d+)\s*,\s*([A-Z][A-Z_0-9]*)\s*,\s*(\d+)\b")

# Gold Kanto gate names are used as reference geometry, NOT assumed equivalent
# to the existing RPP Kanto engine or confirmed to be implemented verbatim.
KANTO_GATE_REFERENCES = frozenset({
    'Route15FuchsiaGate', 'Route16Gate', 'Route17Route18Gate',
    'Route19FuchsiaGate', 'Route2Gate', 'Route5SaffronGate',
    'Route6SaffronGate', 'Route7SaffronGate', 'Route8SaffronGate',
})


def _gold_gate_endpoints(raw: str) -> list[dict]:
    if raw.count('def_warp_events') != 1 or raw.count('def_coord_events') != 1:
        raise ConversionError('Gold gate warp/coord sections must occur exactly once')
    section = raw.split('def_warp_events', 1)[1].split('def_coord_events', 1)[0]
    return [dict(x=int(x), y=int(y), destination=name, warp_number=int(number))
            for x, y, name, number in GOLD_WARP_EVENT.findall(section)]


def _gate_edges(warps: list[dict]) -> tuple[str, dict]:
    """Label common 10x8 Gold gate perimeter, never invent a door step.

    An 8-Warp VictoryRoadGate or another topology is kept as COMPLEX rather
    than squeezed into the usual north/south or east/west 2-lane contract.
    """
    coords = {(w['x'], w['y']) for w in warps}
    if len(warps) == 4 and coords == {(0,4), (0,5), (9,4), (9,5)}:
        family = 'EAST_WEST_PAIR'
        edge = lambda w: 'west' if w['x'] == 0 else 'east'
    elif (len(warps) == 4 and
          {w['y'] for w in warps} == {0, 7} and
          len({w['x'] for w in warps}) == 2 and
          max(w['x'] for w in warps) - min(w['x'] for w in warps) == 1):
        family = 'NORTH_SOUTH_PAIR'
        edge = lambda w: 'north' if w['y'] == 0 else 'south'
    else:
        family = 'COMPLEX_MULTI_EXIT'
        edge = lambda w: 'unclassified'
    edges = defaultdict(list)
    for w in warps:
        edges[edge(w)].append(dict(x=w['x'], y=w['y'],
                                   dest=w['destination'], dest_warp=w['warp_number']))
    return family, dict(edges)


def gold_gate_inventory(rpp: Path, gold: Path) -> dict:
    """Source-based audit of *all* Gold Gate maps, including the future ones.

    Arrival-step need is NOT deducible from compass direction or target Warp
    index. It remains a per-destination/per-direction reviewed gameplay rule.
    """
    gold_maps = gold / 'maps'
    if not gold_maps.is_dir():
        raise ConversionError('Gold maps/ directory missing')
    contracts = json.loads((rpp / 'tools/johto_door_contracts.json').read_text(encoding='utf-8'))
    active = {c['gold_map']: c for c in contracts['active_warp_maps']
              if c.get('family') == 'GATE_INDOOR'}
    gates = []
    for f in sorted(gold_maps.glob('*Gate*.asm')):
        name = f.stem
        src = f.read_text(encoding='utf-8')
        warps = _gold_gate_endpoints(src)
        if not warps:
            raise ConversionError(name + ': no Gold warp events')
        topology, sides = _gate_edges(warps)
        if name in active and active[name].get('arrival_step_review', {}).get('layout') != topology:
            raise ConversionError(name + ': RPP reviewed gate layout differs from Gold warp geometry')
        merged = []
        for side, items in sides.items():
            if (len(items) >= 2 and len({x['dest_warp'] for x in items}) == 1
                    and len({x['dest'] for x in items}) == 1):
                merged.append(side)
        # These are event script behaviors (not evidence of gate arrival stepping).
        scenes = len(re.findall(r'(?m)^\s*scene_script\s+', src))
        coord_events = len(re.findall(r'(?m)^\s*coord_event\s+', src))
        player_movement_scripts = len(re.findall(
            r'(?m)^\s*applymovement\s+PLAYER\b', src))
        flags = []
        if merged:
            flags.append('TWO_LANES_TO_ONE_DESTINATION')
        if topology == 'COMPLEX_MULTI_EXIT':
            flags.append('MULTI_EXIT_CUSTOM_ROUTING')
        if scenes or coord_events or player_movement_scripts:
            flags.append('SCRIPTED_ACCESS_OR_MOVEMENT')
        if 'Beta' in name:
            flags.append('UNRELEASED_GOLD_BETA')
        if name in active:
            status = 'ALREADY_REGISTERED_JOHTO'
        elif name in KANTO_GATE_REFERENCES:
            status = 'KANTO_GOLD_REFERENCE_NOT_RPP_EQUIVALENCE'
        elif 'Beta' in name:
            status = 'GOLD_BETA_REFERENCE_ONLY'
        else:
            status = 'NOT_REGISTERED_JOHTO_CANDIDATE'
        gates.append(dict(gold_map=name, status=status,
                          rpp_map=active[name]['rpp_map'] if name in active else None,
                          reviewed_arrival_step=(active[name]['arrival_step_review']['by_gate_side']
                                                 if name in active else None),
                          layout=topology, warp_count=len(warps),
                          sides=sides, flags=flags,
                          scene_script_count=scenes,
                          coord_event_count=coord_events,
                          applymovement_player_count=player_movement_scripts,
                          arrival_step_contract='REVIEW_PER_DESTINATION_AND_DIRECTION',
                          **{'is_implemented_in_project': name in active}))
    families = {f: sum(g['layout'] == f for g in gates)
                for f in ('EAST_WEST_PAIR', 'NORTH_SOUTH_PAIR', 'COMPLEX_MULTI_EXIT')}
    return dict(schema='gold-gate-preflight-inventory-v1',
                source='Gold maps/*Gate*.asm and current RPP GATE_INDOOR contracts',
                caveat=('Geometry/Gold scripts cannot prove whether an RPP arrival '
                        'requires zero or one simulated step; review incoming map, '
                        'direction, Gold destination and collision for each side.'),
                totals=dict(gold_gates=len(gates), **families,
                            unregistered_johto=sum(g['status'] == 'NOT_REGISTERED_JOHTO_CANDIDATE' for g in gates),
                            scene_or_nonstandard=sum(bool(g['flags']) for g in gates)),
                gates=gates)


def gate_inventory_markdown(report: dict) -> str:
    lines = ['# Gold 全门房预检（地图开发前使用）', '',
             '来源：Gold 原版 `maps/*Gate*.asm`，与项目当前 `GATE_INDOOR` 登记对照。',
             '**不会根据南北/东西方向猜测自动走一步。** 下表的危险标志仅用于规划，'
             '真实 Warp 落点和自动步行仍需逐端审核。', '',
             f"Gold 门房：{report['totals']['gold_gates']}；横向：{report['totals']['EAST_WEST_PAIR']}；"
             f"纵向：{report['totals']['NORTH_SOUTH_PAIR']}；复杂：{report['totals']['COMPLEX_MULTI_EXIT']}；"
             f"未注册城都候选：{report['totals']['unregistered_johto']}。", '',
             '| Gold 门房 | 地图形态 | 状态 | 特殊风险 |',
             '|---|---|---|---|']
    labels = {'EAST_WEST_PAIR': '东西双格', 'NORTH_SOUTH_PAIR': '南北双格',
              'COMPLEX_MULTI_EXIT': '多方向特殊'}
    for g in report['gates']:
        flags = ', '.join(g['flags']) or '普通 Warp 结构（仍需逐端核对）'
        if g['reviewed_arrival_step'] is not None:
            flags += '；现有到达配置 ' + str(g['reviewed_arrival_step'])
        lines.append(f"| `{g['gold_map']}` | {labels[g['layout']]} | {g['status']} | {flags} |")
    lines += ['', '## 新门房必须先登记的动作合同', '',
              '每条入口单独核对：来源地图、出入口坐标与面向、Gold Warp 目标编号、'
              'RPP 0-based 目标编号、落点格以及前后两格 Gold 碰撞，切图后 `NONE`'
              '还是 `D_UP/D_DOWN/D_LEFT/D_RIGHT` 自动一步，错误方向和立即反向行为。',
              '非对称合流必须列出 2→1 对应；剧情/场景脚本与门房到达步行**分开登记**。',
              '已有的 `GetJohtoWarpArrivalStep` / `PlayerStepOutFromDoor` 只在有证据的'
              '目的地增加精确规则，不可因 `NORTH_SOUTH_PAIR` 就为上下两端都追加一步。',
              '此审计不修改 ROM、Gold 源码，也不能代替编译和手机实机测试。', '']
    return '\n'.join(lines)

def main(argv=None):
    ap = argparse.ArgumentParser(description=__doc__)
    for name in ('rpp', 'gold', 'output'):
        ap.add_argument('--' + name, type=Path, required=True)
    ap.add_argument('--inventory-gold-gates', action='store_true',
                    help='Read-only preflight inventory of ALL Gold Gate maps')
    ap.add_argument('--reference-room', default='Route15Gate1F')
    ap.add_argument('--rpp-room', default='JohtoRoute31VioletGate')
    args = ap.parse_args(argv)
    rpp, gold, output = safe_roots(args.rpp, args.gold, args.output)
    if args.inventory_gold_gates:
        report = gold_gate_inventory(rpp, gold)
        dump(output, 'gold_gate_inventory.json', report)
        (output / 'GOLD_ALL_GATE_PREFLIGHT_zh.md').write_text(
            gate_inventory_markdown(report), encoding='utf-8')
        print('GOLD_GATE_INVENTORY_ONLY:', report['totals'])
        return 0
    reference, target = profile(rpp, args.reference_room), profile(rpp, args.rpp_room)
    result = {'reference': reference, 'target': target, 'comparison': compare(reference, target)}
    dump(output, 'native_reference_profiles.json', result)
    print(result['comparison']['status'])
    return 0


if __name__ == '__main__':
    raise SystemExit(main())
