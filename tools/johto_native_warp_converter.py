#!/usr/bin/env python3
"""Read-only native RPP gate warp conversion plan (Route15 -> Johto).

No ASM is rewritten: landing pair IDs and collision semantics require review.
A complete plan is evidence for human review, NOT a playable warp guarantee.
"""
from __future__ import annotations
import argparse
from pathlib import Path
from johto_indoor_common import (ConversionError, dump, gold_warps, rpp_warps,
    rpp_tileset, rpp_map_symbol, safe_roots, target_tile_group, tile_at, warp_tile_ids)
from johto_warp_reference_profiles import profile, compare


def analyze(rpp: Path, gold: Path, room='Route31VioletGate',
            indoor='JohtoRoute31VioletGate', outdoor=('JohtoVioletCity','JohtoRoute31'),
            reference_room='Route15Gate1F'):
    reference_profile = profile(rpp, reference_room)
    target_profile = profile(rpp, indoor)
    geometry = compare(reference_profile, target_profile)
    reference = reference_profile['warps']
    names = [indoor, *outdoor]
    loaded = {name: rpp_warps(rpp,name) for name in names}
    gold_w = gold_warps(gold,room)
    warnings=[]
    if not geometry['same_edge_port_shape']:
        warnings.append('原生参考门口与目标门口的边缘几何不同，不能直接照搬')
    original_gold_pairs = {(w['x'],w['y']):w for w in gold_w}
    room_pairs=[]
    for r in loaded[indoor]:
        g=original_gold_pairs.get((r['x'],r['y']))
        room_pairs.append({'rpp':r, 'gold':g,
                           'gold_dest_index_zero_based':g['dest_id']-1 if g else None,
                           'matches_gold_index':g is not None and r['dest_id']==g['dest_id']-1})
    if len(gold_w) != len(loaded[indoor]) or not all(q['matches_gold_index'] for q in room_pairs):
        warnings.append('室内 Warp 目标编号与 Gold 不完全一致，必须确认重新排序/映射')
    outside=[]
    for name in outdoor:
        ts=rpp_tileset(rpp,name)
        sym=target_tile_group(ts)
        safeids=warp_tile_ids(rpp,sym) if sym else []
        for w in loaded[name]:
            if w['dest_map']!=rpp_map_symbol(rpp,indoor):
                continue
            pixels=tile_at(rpp,name,w['x'],w['y'],ts.lower())
            immediate=any(tile in safeids for tile in pixels)
            if immediate:
                warnings.append(f'{name} ({w["x"]},{w["y"]}) 属于 warp tile 白名单：不能确认门口停留不传送')
            outside.append({'map':name,'warp':w,'tileset':ts,'four_tiles':pixels,
                            'native_warp_tile_list':sym,'matching_warp_tiles':[t for t in pixels if t in safeids],
                            'potential_standing_trigger':immediate})
    src=(rpp/'home/overworld.asm').read_text(encoding='utf-8')
    state=(rpp/'engine/overworld/player_state.asm').read_text(encoding='utf-8')
    engine={'collision_path':all(t in src for t in ('CollisionCheckOnLand','ExtraWarpCheck','CheckWarpsCollision')),
            'standing_path':'CheckWarpsNoCollisionLoop::' in src and 'IsPlayerStandingOnDoorTileOrWarpTile' in src,
            'facing_warp_tiles':'IsWarpTileInFrontOfPlayer:' in state,
            'warp_tile_state_reset':'res 2, [hl]' in state,
            'native_gate_tiles':warp_tile_ids(rpp, 'GateWarpTileIDs'),
            'native_overworld_tiles':warp_tile_ids(rpp, 'OverworldWarpTileIDs'),
            'johto_tiles':warp_tile_ids(rpp, 'NewBarkWarpTileIDs'),
            'extra_warp_checks_johto_explicit':'cp JOHTO' in src[src.index('ExtraWarpCheck::'):src.index('MapEntryAfterBattle::')]}
    if not all(engine[key] for key in ('collision_path','standing_path','facing_warp_tiles')):
        warnings.append('RPP 引擎 Warp 入口与预期不同，必须重新审查')
    if not engine['extra_warp_checks_johto_explicit']:
        warnings.append('ExtraWarpCheck 未有显式 JOHTO 分支，不能把室外判断视为 Route15 等价')
    if not outside: warnings.append('未找到已接入的城都室外门 Warp')
    return {'schema':'johto-native-gate-plan-v1','mode':'OFFLINE_ANALYSIS_ONLY',
            'reference_map':reference_room,'reference_warps':reference,
            'reference_profile':reference_profile, 'target_profile':target_profile,
            'reference_geometry':geometry,
            'reference_not_directly_connected_to_fuchsia':'FuchsiaCity 通过 Route15 地图连接，非 gate->Fuchsia 直接 Warp',
            'gold_room':room, 'rpp_room':indoor,'outdoor_maps':list(outdoor),'gold_room_warps':gold_w,
            'rpp_room_warps':room_pairs, 'outside_warps':outside,
            'engine':engine,'warnings':warnings,
            'review_required':['门外停留不传送','进入后立即反向离开','离开后立即反向进入',
                               '上下两个入口配对','实际门框碰撞图块及方向','目的地落点及对象/地图边界'],
            'status':'REVIEW_REQUIRED'}


def main(argv=None):
    ap=argparse.ArgumentParser(description=__doc__)
    ap.add_argument('--rpp',type=Path,required=True)
    ap.add_argument('--gold',type=Path,required=True)
    ap.add_argument('--output',type=Path,required=True)
    ap.add_argument('--gold-room',default='Route31VioletGate')
    ap.add_argument('--reference-room',default='Route15Gate1F')
    ap.add_argument('--rpp-room',default='JohtoRoute31VioletGate')
    ap.add_argument('--outside-maps',nargs='+',default=['JohtoVioletCity','JohtoRoute31'])
    args=ap.parse_args(argv)
    rpp,gold,out=safe_roots(args.rpp,args.gold,args.output)
    report=analyze(rpp,gold,args.gold_room,args.rpp_room,tuple(args.outside_maps),args.reference_room)
    dump(out,'native_warps.json',report)
    print('native warp source review:',report['status'],'warnings:',len(report['warnings']))
    return 0

if __name__=='__main__':
    raise SystemExit(main())
