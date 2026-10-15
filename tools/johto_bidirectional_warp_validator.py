#!/usr/bin/env python3
"""Static 2-way Warp graph checks + required in-game scenario plan.

The RPP engine owns runtime flags, facing direction and collision; source
inspection cannot assert real-time input behavior. Such cases stay UNTESTED.
"""
from __future__ import annotations
import argparse
from pathlib import Path
from johto_indoor_common import ConversionError, dump, rpp_warps, safe_roots, rpp_dimensions, rpp_map_symbol
from johto_native_warp_converter import analyze


def validate(rpp: Path, plan: dict, *, strict_pairs=True):
    names=[plan['rpp_room'],*plan['outdoor_maps']]
    from_map={name:rpp_map_symbol(rpp,name) for name in names}
    normalized={v:k for k,v in from_map.items()}
    warps={k:rpp_warps(rpp,k) for k in from_map}
    if len(normalized) != len(from_map):
        raise ConversionError('加载的多张地图共用了同一个 RPP 地图符号')
    findings=[]; edges=[]
    inbound={name: set() for name in names}
    for name, rows in warps.items():
        width,height=rpp_dimensions(rpp,name)
        for w in rows:
            item={'from':name,'from_id':w['id'],'x':w['x'],'y':w['y'],
                  'to':w['dest_map'],'to_id':w['dest_id']}
            if w['x'] >= width*2 or w['y'] >= height*2:
                findings.append({'code':'OUT_OF_BOUNDS','edge':item})
            target=normalized.get(w['dest_map'])
            if target:
                if w['dest_id']>=len(warps[target]):
                    findings.append({'code':'TARGET_INDEX_INVALID','edge':item})
                else:
                    dest=warps[target][w['dest_id']]
                    item['lands_at']={'map':target,'x':dest['x'],'y':dest['y']}
                    if dest['dest_map'] != from_map[name]:
                        findings.append({'code':'NO_RECIPROCAL_WARP','edge':item})
                    else:
                        item['reverse_id'] = dest['dest_id']
                        if strict_pairs and dest['dest_id'] != w['id']:
                            findings.append({'code':'REVERSE_INDEX_MISMATCH','edge':item,
                                             'detail':'目标 warp 返回了另一入口；双口关卡不能只按地图名验收'})
                    inbound[target].add(w['dest_id'])
            else:
                # $ff and other external destinations cannot be proven by this
                # local set of maps; do not silently report a complete graph.
                findings.append({'code':'UNRESOLVED_TARGET_MAP','edge':item})
            edges.append(item)
    for room, index_set in inbound.items():
        if room != plan['rpp_room']:
            continue
        for item in warps[room]:
            if item['dest_map'] in from_map.values() and item['id'] not in index_set:
                findings.append({'code':'UNREACHABLE_RETURN_ENTRANCE',
                                 'map':room, 'warp_id':item['id']})
    flags=plan['engine']
    if not flags['extra_warp_checks_johto_explicit']:
        findings.append({'code':'JOHTO_DIRECTION_BRANCH_UNVERIFIED',
                         'detail':'ExtraWarpCheck 路由与 OVERWORLD/Route15 不同'})
    if any(q['potential_standing_trigger'] for q in plan['outside_warps']):
        findings.append({'code':'OUTDOOR_STANDING_TRIGGER_RISK',
                         'detail':'室外门口图块进入 WarpTileID 白名单，可能提前触发'})
    scenarios=[{'name':name,'result':'NOT_RUN_IN_GAME'} for name in (
        '门外第一格站住不进门','从正确方向进门','进入后不移动立即反向出门',
        '出门后不移动立即反向进门','左右/上下双入口不串位',
        '门旁横向移动不误进门','若叶镇/吉花市旧 Warp 回归')]
    fatal = {'OUT_OF_BOUNDS','TARGET_INDEX_INVALID','NO_RECIPROCAL_WARP',
             'REVERSE_INDEX_MISMATCH','UNREACHABLE_RETURN_ENTRANCE'}
    graph_status = ('FAIL' if any(f['code'] in fatal for f in findings) else
                    'PARTIAL' if any(f['code']=='UNRESOLVED_TARGET_MAP' for f in findings) else
                    'PASS')
    return {'schema':'johto-biwarp-static-v2','strict_pair_index_check':strict_pairs,
            'graph_check':graph_status,
            'behavior_check':'NOT_PROVEN_STATICALLY', 'edges':edges,'findings':findings,
            'scenarios':scenarios,'gameplay_accepted':False}


def main(argv=None):
    ap=argparse.ArgumentParser(description=__doc__)
    ap.add_argument('--rpp',type=Path,required=True)
    ap.add_argument('--gold',type=Path,required=True)
    ap.add_argument('--output',type=Path,required=True)
    ap.add_argument('--gold-room',default='Route31VioletGate')
    ap.add_argument('--reference-room',default='Route15Gate1F')
    ap.add_argument('--allow-shared-landing',action='store_true',
                    help='普通房屋可能共用返回落点；此开关不适用于双口 Gate')
    ap.add_argument('--rpp-room',default='JohtoRoute31VioletGate')
    ap.add_argument('--outside-maps',nargs='+',default=['JohtoVioletCity','JohtoRoute31'])
    args=ap.parse_args(argv)
    rpp,gold,out=safe_roots(args.rpp,args.gold,args.output)
    result=validate(rpp,analyze(rpp,gold,args.gold_room,args.rpp_room,tuple(args.outside_maps),args.reference_room),
                    strict_pairs=not args.allow_shared_landing)
    dump(out,'bidirectional_warps.json',result)
    print('graph:',result['graph_check'],'gameplay:',result['behavior_check'])
    return int(result['graph_check']!='PASS')

if __name__=='__main__':
    raise SystemExit(main())
