#!/usr/bin/env python3
"""One command for the 5-module OFFLINE Gold -> RPP indoor/gate toolchain.

Writes only an external staging folder. It will never patch the game; graph
PASS is not gameplay PASS. Unmatched art and collision rules remain blockers.
"""
from __future__ import annotations
import argparse
import json
import re
from pathlib import Path
from johto_indoor_common import ConversionError, dump, safe_roots, sha, gold_warps, gold_dimensions
from johto_native_warp_converter import analyze
from johto_bidirectional_warp_validator import validate
from johto_indoor_tiles_converter import build_mapping, stage_dedicated_gold_tileset
from johto_indoor_collision_adapter import check
from johto_indoor_registration_generator import generate
from johto_indoor_resource_budget import inspect as inspect_resource_budget
from johto_indoor_palette_vram_audit import inspect as inspect_palette_vram
from johto_indoor_manifest import create_manifest
from johto_indoor_conversion_plan import create_plan, validate_plan


def pipeline(rpp: Path,gold: Path,out: Path, *, gold_room='Route31VioletGate',
             rpp_room='JohtoRoute31VioletGate', outdoor=('JohtoVioletCity','JohtoRoute31'),
             gold_tileset='gate', rpp_tileset='gate',
             reference_room='Route15Gate1F', strict_pairs=True):
    rpp,gold,out=safe_roots(rpp,gold,out)
    plan=analyze(rpp,gold,gold_room,rpp_room,tuple(outdoor),reference_room)
    graph=validate(rpp,plan,strict_pairs=strict_pairs)
    artwork,candidate=build_mapping(rpp,gold,gold_room,gold_tileset,rpp_tileset)
    collision=check(rpp,gold,artwork,rpp_tileset)
    registration=generate(rpp,rpp_room)
    resources=inspect_resource_budget(rpp,gold,artwork)
    palette_vram=inspect_palette_vram(rpp,gold,artwork,resources)
    for name,report in [('01_native_warps.json',plan),('02_bidirectional_warps.json',graph),
                        ('03_indoor_art.json',artwork),('04_collision.json',collision),
                        ('05_registration.json',registration)]:
        dump(out,name,report)
    dump(out,'08_resource_budget.json',resources)
    dump(out,'09_palette_vram.json',palette_vram)
    if candidate:
        (out/f'{gold_room}.pixel_candidate.blk').write_bytes(candidate)
        isolated=None
    else:
        isolated=stage_dedicated_gold_tileset(
            gold,out,gold_room,gold_tileset,
            fixed_slots=palette_vram['loader']['fixed_copy_8x8_slots'])
        dump(out,'06_isolated_original_art.json',isolated)
    conversion_plan = create_plan(artwork, collision, palette_vram, isolated)
    check_plan = validate_plan(conversion_plan, artwork, collision, palette_vram, isolated)
    dump(out, '10_conversion_plan.json', conversion_plan)
    dump(out, '11_conversion_plan_validation.json', check_plan)
    # Every stage must have positive evidence before import is even considered.
    blockers=[]
    if not check_plan['structural_valid']:blockers.append('CONVERSION_PLAN_INVALID')
    if plan['warnings']:blockers.append('WARP_REVIEW')
    if graph['graph_check']!='PASS':blockers.append('GRAPH_BROKEN')
    if artwork['status']!='PIXEL_CANDIDATE_ONLY':blockers.append('ART_UNMAPPED')
    if collision['status']!='COLLISION_CERTIFIED':blockers.append('COLLISION_NOT_PROVEN')
    if registration['status']!='PRESENT_REVIEW_DEPENDENCIES':blockers.append('MAP_REGISTRATION_INCOMPLETE')
    if resources['status']!='RESOURCE_BUDGET_CERTIFIED':blockers.append('RESOURCE_BUDGET_UNVERIFIED')
    if not palette_vram['import_allowed']:blockers.append('PALETTE_VRAM_UNVERIFIED')
    blockers.append('GAMEPLAY_NOT_TESTED')
    overview={'schema':'johto-indoor-toolchain-v1','scope':f'{gold_room} -> {rpp_room} against Route15 native reference',
              'output':'OFFLINE_ONLY','game_sources_changed':False,
              'rpp_game_version_unchanged':True,'import_allowed':False,
              'native_warp_warnings':len(plan['warnings']),
              'warp_graph':graph['graph_check'],'behavior':graph['behavior_check'],
              'strict_pair_index_check':strict_pairs,'reference_room':reference_room,
              'art_exact_unique_blocks':artwork['exact_mapped'],
              'art_missing_unique_blocks':len(artwork['unmapped']),
              'isolated_gold_art_candidate':bool(isolated),
              'registration':registration['status'],
              'registration_failed_checks':registration['failed_checks'],
              'resource_budget':resources['status'],
              'palette_vram':palette_vram['status'],
              'source_confirmed_copy_tiles':palette_vram['loader']['fixed_copy_8x8_slots'],
              'conversion_plan': 'OFFLINE_REVIEW_ONLY',
              'conversion_plan_structural_valid': check_plan['structural_valid'],
              'gold_distinct_source_tiles':resources['gold']['distinct_tile_ids_referenced'],
              'blockers':blockers}
    dump(out,'00_summary.json',overview)
    readme=['# 城都室内外转换工具链 · 静态验收报告','',
            '所有输出是**离线候选/审核报告**，不修改 Gold 或 RPP，不编译 ROM。','',
            f'- 原生 Warp 配置警告：{len(plan["warnings"])}',
            f'- 双向 Warp 索引图：{graph["graph_check"]}（不代表实际操作正常）',
            f'- Gold 室内使用区块：{artwork["used_unique_blocks"]}；像素精确映射：{artwork["exact_mapped"]}；未匹配：{len(artwork["unmapped"])}',
            f'- Gold 专用图形候选暂存：{bool(isolated)}（未接入 RPP；需新 tileset 注册）',
            f'- 碰撞：{collision["status"]}',
            f'- 注册：{registration["status"]}（失败结构项：{len(registration["failed_checks"])}）',
            f'- 资源预算：{resources["status"]}；引用 Gold 8×8 图块：{resources["gold"]["distinct_tile_ids_referenced"]}',
            f'- 图形加载窗口：{palette_vram["loader"]["fixed_copy_8x8_slots"]} 个 8×8 tile（来源：home/overworld.asm，不是空闲 VRAM）',
            f'- RPP 调色表已有引用：{palette_vram["existing_palette"]["source_entries"]} 项；新室内调色映射：尚未批准',
            '- 动态行为：进门前一格停留、立即反向进出等，必须实际游戏测试。','',
            '## 当前阻断项','']+[f'- {x}' for x in blockers]+['','## 详情文件','',
            '1. `01_native_warps.json`：指定的 RPP 门型对照、Gold/RPP Warp 及图块白名单',
            '2. `02_bidirectional_warps.json`：双向目标编号与最小游戏测试清单',
            '3. `03_indoor_art.json`：像素精确匹配，缺失图块列表',
            '4. `04_collision.json`：Gold/RPP 碰撞差异（不自动批准）',
            '5. `05_registration.json`：地图注册检查与后续手工接入项',
            '6. `06_isolated_original_art.json` + isolated_gold_art_candidate/：缺少复用图块时的独立 Gold 图形候选',
            '7. `00_summary.json`：可机读总览',
            '8. `07_source_manifest.json`：源码及离线产物指纹，防止拿过期报告进行移植',
            '9. `08_resource_budget.json`：候选块数、8×8 图块需求、现有色板引用与资源审核缺口',
            '10. `09_palette_vram.json`：源码溯源的图形加载窗口、调色表和新资源接入缺口',
            '11. `10_conversion_plan.json`：逐区块候选、隔离图块、调色审核方案（不可直接导入）',
            '12. `11_conversion_plan_validation.json`：结构一致性核验（不是实机验收）',
            '', '严禁直接把报告中的素材 ID 或门口目标编号当成已验收数据写入游戏。','']
    (out/'REPORT_zh.md').write_text('\n'.join(readme),encoding='utf-8')
    create_manifest(rpp,gold,out,gold_room=gold_room,rpp_room=rpp_room,
                    outdoor=tuple(outdoor),reference_room=reference_room,
                    gold_tileset=gold_tileset,rpp_tileset=rpp_tileset)
    return overview


def _gold_name_key(value: str) -> str:
    return re.sub(r'[^a-z0-9]', '', value.lower())


def _gold_interaction_inventory(gold: Path, room: str, width: int, height: int) -> dict:
    """Read Gold dialogue/interactions, but do not imply RPP script support."""
    source = (gold / 'maps' / f'{room}.asm').read_text(encoding='utf-8')
    results = {'npcs': [], 'backgrounds': []}
    for kind, target in (('object_event', 'npcs'), ('bg_event', 'backgrounds')):
        for line in re.findall(r'^\s*' + kind + r'\s+([^;\n]+)', source, re.M):
            parts = [p.strip() for p in line.split(',')]
            if len(parts) < (12 if kind == 'object_event' else 4):
                raise ConversionError(f'Gold {room} {kind} 字段不完整')
            try:
                x, y = int(parts[0]), int(parts[1])
            except ValueError as exc:
                raise ConversionError(f'Gold {room} {kind} 坐标不是数字') from exc
            if not 0 <= x < 2 * width or not 0 <= y < 2 * height:
                raise ConversionError(f'Gold {room} {kind} 坐标越界: ({x},{y})')
            label = parts[-2] if kind == 'object_event' else parts[-1]
            if not re.fullmatch(r'[A-Za-z_][A-Za-z_0-9]*', label) or not re.search(
                    r'^' + re.escape(label) + r':', source, re.M):
                raise ConversionError(f'Gold {room} {kind} 脚本标签缺失: {label}')
            results[target].append({'x': x, 'y': y, 'script': label})
    return results


def _gold_outdoor_pairs(gold: Path, room: str, outside: str, indoor_warps: list) -> dict:
    """Prove the one-outside-map house topology using independent Gold source.

    This is only for a small house whose *every* indoor return points to one
    outdoor map. Other interiors may connect many maps and must be reviewed
    separately; do not generalize this into an automatic Warp converter.
    """
    out_warps = gold_warps(gold, outside)
    linked = [w for w in out_warps if _gold_name_key(w['dest_map']) == _gold_name_key(room)]
    if not linked:
        raise ConversionError(f'Gold {outside} 未发现指向 {room} 的入口')
    if any(w['dest_id'] > len(indoor_warps) or w['dest_id'] < 1 for w in linked):
        raise ConversionError('Gold 城外 Warp 指向不存在的房内 1-based 索引')
    linked_ids = {w['id'] for w in linked}
    if any(_gold_name_key(w['dest_map']) != _gold_name_key(outside)
           or w['dest_id'] not in linked_ids for w in indoor_warps):
        raise ConversionError('Gold 室内出口并未全部回到指定室外入口，拒绝按简单民宅处理')
    if any(indoor_warps[w['dest_id'] - 1]['dest_id'] != w['id'] for w in linked):
        raise ConversionError('Gold 室外入口对应的房内回程索引不一致')
    return {'outside_map': outside, 'outside_to_indoor_1_based': linked,
            'inside_to_outside_1_based': indoor_warps,
            'verified_single_outside_house_topology': True,
            'rpp_destination_indices_0_based_review_only': [
                {'outside_gold_warp_id': w['id'], 'indoor_destination_zero_based': w['dest_id'] - 1}
                for w in linked],
            'runtime_approved': False}


def prestage_unregistered(rpp: Path, gold: Path, out: Path, *, gold_room: str,
                          rpp_room: str, gold_tileset: str = 'gate',
                          rpp_tileset: str = 'gate', gold_outside_map: str | None = None,
                          rpp_outside_map: str | None = None):
    """Use existing art/collision pipeline before an RPP room is registered.

    Unregistered houses can be reviewed like gates but are never auto-imported.
    Outdoor links are taken from real Gold source, not guessed from the room.
    """
    rpp, gold, out = safe_roots(rpp, gold, out)
    if (rpp/'data/mapHeaders'/f'{rpp_room}.asm').exists() or (rpp/'data/mapObjects'/f'{rpp_room}.asm').exists():
        raise ConversionError('目标室内已登记，必须使用完整流水线，不能跳过运行时 Warp 审查')
    if rpp_outside_map and not gold_outside_map:
        raise ConversionError('指定 RPP 室外地图时必须指定 Gold 对照室外地图')
    width, height = gold_dimensions(gold, gold_room)
    warps = gold_warps(gold, gold_room)
    if not warps or any(not (0 <= w['x'] < width*2 and 0 <= w['y'] < height*2) for w in warps):
        raise ConversionError('Gold 室内 Warp 缺失或不在原始地图边界内')
    pair = _gold_outdoor_pairs(gold, gold_room, gold_outside_map, warps) if gold_outside_map else None
    outside_rpp = None
    if rpp_outside_map:
        from johto_indoor_common import rpp_warps
        entries = rpp_warps(rpp, rpp_outside_map)
        if any(_gold_name_key(w['dest_map']) == _gold_name_key(rpp_room) for w in entries):
            raise ConversionError('目标室内未注册，但室外已有指向它的 Warp，必须先修复运行时')
        outside_rpp = {'map': rpp_outside_map, 'existing_active_warps': entries,
                       'new_warp_enabled': False}
    interactions = _gold_interaction_inventory(gold, gold_room, width, height)
    artwork, candidate = build_mapping(rpp, gold, gold_room, gold_tileset, rpp_tileset)
    collision = check(rpp, gold, artwork, rpp_tileset)
    resources = inspect_resource_budget(rpp, gold, artwork)
    palette = inspect_palette_vram(rpp, gold, artwork, resources)
    isolated = None
    if candidate is None:
        isolated = stage_dedicated_gold_tileset(
            gold, out, gold_room, gold_tileset,
            fixed_slots=palette['loader']['fixed_copy_8x8_slots'])
    else:
        (out/f'{gold_room}.pixel_candidate.blk').write_bytes(candidate)
    blockers = ['RPP_ROOM_NOT_REGISTERED', 'OUTDOOR_WARP_NOT_ENABLED',
                'WARP_DIRECTION_AND_IMMEDIATE_RETURN_NOT_TESTED',
                'NPC_AND_BG_SCRIPTS_NOT_PORTED', 'COLLISION_NOT_RUNTIME_CERTIFIED',
                'PALETTE_RGB_NOT_PHONE_ACCEPTED', 'BANK_LAYOUT_NOT_LINKED']
    if pair is None:
        blockers.append('GOLD_OUTDOOR_RETURN_NOT_REVIEWED')
    overview = {
        'schema': 'johto-indoor-prestage-v2',
        'status': 'OFFLINE_UNREGISTERED_ONLY',
        'gold_room': gold_room, 'rpp_room_not_registered': rpp_room,
        'gold_dimensions_blocks': [width, height],
        'gold_warps_1_based': warps,
        'gold_outdoor_pairs': pair,
        'rpp_outdoor_state': outside_rpp,
        'gold_interactions': interactions,
        'art_exact_blocks': artwork['exact_mapped'],
        'art_missing_gold_blocks': artwork['unmapped'],
        'isolated_candidate_only': isolated is not None,
        'runtime_warp_enabled': False, 'game_source_modified': False,
        'import_allowed': False, 'rom_compiled': False,
        'blockers': blockers,
    }
    for name, data in [('00_summary.json', overview), ('01_gold_native_warps.json', {'warps':warps}),
                       ('02_gold_outdoor_pairs.json', pair or {'status':'NOT_REVIEWED'}),
                       ('03_indoor_art.json', artwork), ('04_collision.json', collision),
                       ('08_resource_budget.json', resources), ('09_palette_vram.json', palette),
                       ('12_gold_interactions.json', interactions)]:
        dump(out, name, data)
    if isolated is not None:
        dump(out, '06_isolated_original_art.json', isolated)
    (out/'REPORT_zh.md').write_text(
        f'# {gold_room}：未注册室内离线预备\n\n'
        f'- RPP 目标：`{rpp_room}`；**未注册，不得打开入口**。\n'
        f'- Gold 尺寸：{width} × {height} block，室内 Warp {len(warps)} 条，'
        f'NPC {len(interactions["npcs"])} 个，背景交互 {len(interactions["backgrounds"])} 个。\n'
        f'- Gold 室外往返检查：{"已核对" if pair else "尚未指定室外地图"}；'
        f'**Gold Warp # 从 1 开始，RPP 从 0 开始**。\n'
        f'- 室外 RPP 地图：{rpp_outside_map or "未指定"}，不得替换尚未开放的其它入口。\n'
        f'- 图块精确匹配：{artwork["exact_mapped"]}/{artwork["used_unique_blocks"]}；'
        f'隔离 Gold 原图候选：{isolated is not None}。\n'
        '- **碰撞／调色／ROM Bank／NPC 脚本与手机操作均未验收**。\n\n'
        '该预备包是来源证据和候选素材，不生成或安装游戏 Warp。\n',
        encoding='utf-8')
    return overview


def main(argv=None):
    ap=argparse.ArgumentParser(description=__doc__)
    ap.add_argument('--rpp',required=True,type=Path)
    ap.add_argument('--gold',required=True,type=Path)
    ap.add_argument('--output',required=True,type=Path)
    ap.add_argument('--gold-room',default='Route31VioletGate')
    ap.add_argument('--prestage-unregistered',action='store_true',
                    help='stage Gold indoor art and topology before a room is registered; never open Warp')
    ap.add_argument('--gold-outside-map',help='Gold outdoor map for pre-stage reciprocal warp review')
    ap.add_argument('--rpp-outside-map',help='RPP outdoor map for pre-stage closed-door inventory')
    ap.add_argument('--reference-room',default='Route15Gate1F')
    ap.add_argument('--allow-shared-landing',action='store_true')
    ap.add_argument('--rpp-room',default='JohtoRoute31VioletGate')
    ap.add_argument('--outside-maps',nargs='+',default=['JohtoVioletCity','JohtoRoute31'])
    ap.add_argument('--gold-tileset',default='gate')
    ap.add_argument('--rpp-tileset',default='gate')
    args=ap.parse_args(argv)
    try:
        if args.prestage_unregistered:
            result=prestage_unregistered(args.rpp,args.gold,args.output,
                gold_room=args.gold_room,rpp_room=args.rpp_room,
                gold_tileset=args.gold_tileset,rpp_tileset=args.rpp_tileset,
                gold_outside_map=args.gold_outside_map,rpp_outside_map=args.rpp_outside_map)
            print(json.dumps(result,ensure_ascii=False,indent=2))
            return 0
        result=pipeline(args.rpp,args.gold,args.output,gold_room=args.gold_room,rpp_room=args.rpp_room,
                        outdoor=tuple(args.outside_maps),gold_tileset=args.gold_tileset,rpp_tileset=args.rpp_tileset,
                        reference_room=args.reference_room,
                        strict_pairs=not args.allow_shared_landing)
    except (OSError,ConversionError,ValueError) as exc:
        ap.error(str(exc))
    print(json.dumps(result,ensure_ascii=False,indent=2))
    return 0

if __name__=='__main__':raise SystemExit(main())
