#!/usr/bin/env python3
"""Batch stage Gold maps, then independently audit the staging area.

No game files are modified. Output is intentionally NOT importable into RPP.
"""
import argparse
import json
import re
from pathlib import Path
from johto_rpp_batch import batch, gold_event_records
from johto_rpp_validate import verify, write_reports, render_previews
from johto_indoor_tiles_converter import stage_preserved_gold_tileset
from johto_indoor_collision_adapter import plan_gold_quadrant_collision
from johto_indoor_common import dump, safe_roots
from johto_rpp_asset_audit import layout_inventory, tileset_key
from johto_indoor_registration_generator import generate as audit_registration
from johto_indoor_common import rpp_warps, ConversionError


def make_map_onboarding(gold: Path, map_name: str, art: dict, geometry: dict) -> dict:
    """Generate a Gold-evidence-based, fail-closed *review checklist*.

    A map's appearance, Gold collision, or Gold event count cannot certify
    RPP field move permissions. None of these records enable runtime features.
    """
    registration = (gold / 'data/maps/maps.asm').read_text(encoding='utf-8')
    map_rows = re.findall(r'^\s*map\s+' + re.escape(map_name)
                          + r'\s*,\s*TILESET_[A-Z0-9_]+\s*,\s*([A-Z_]+)\s*,',
                          registration, re.M)
    if len(map_rows) != 1:
        raise ValueError('Gold map environment not uniquely registered: ' + map_name)
    environment = map_rows[0]
    width, height = art['width'], art['height']
    events = gold_event_records(gold, map_name, width, height)
    if events['warnings']:
        raise ValueError('Gold map event source unavailable: ' + ', '.join(events['warnings']))
    roles = geometry['collision_roles']
    water = sum(count for role, count in roles.items() if role in
                ('WATER', 'WATERFALL', 'WHIRLPOOL', 'CURRENT_DOWN', 'CURRENT_UP',
                 'CURRENT_LEFT', 'CURRENT_RIGHT'))
    cave = environment == 'CAVE'
    outside = environment in ('ROUTE', 'TOWN')
    town = environment == 'TOWN'
    special = geometry['special_cells']
    hops = geometry['hops'] or geometry['unsafe_hop_candidates']
    # This is *source evidence*, not an RPP permission/implementation report.
    def item(name, needed, reason, paths, kind='manual'):
        return {'id': name, 'status': 'REVIEW_REQUIRED' if needed else 'NOT_APPLICABLE',
                'reason': reason, 'rpp_review_sources': paths, 'verification': kind,
                'runtime_approved': False}
    checks = [
        item('map_registration', True, '地区/局部 ID、Header、Bank、图块集与地图尺寸必须完整登记',
             ['constants/region_map_constants.asm','data/johto_map_headers.asm','main.asm']),
        item('art_palette_vram_bank', True, '图像、色板、音效/背景音乐与固定 Bank 空间需要核对',
             ['data/tileset_headers.asm','color/data/map_palette_sets.asm','home/overworld.asm']),
        item('collision_and_ledge', True,
             f'Gold 特殊地格 {len(special)}、跳崖候选 {len(geometry["hops"])}、不安全跳崖 {len(geometry["unsafe_hop_candidates"])}',
             ['home/overworld.asm','engine/overworld/player_state.asm']),
        item('outdoor_connections', outside,
             '确认Gold连接方向、连接条带、反向、越界与跨tileset重载；没有自动放行',
             ['data/mapHeaders/','home/overworld.asm','tools/johto_rpp_connection_guard.py']),
        item('roof_mapgroup_gold_reference', outside,
             '按 Gold data/maps/maps.asm 的 mapgroup 反查 roofs.asm 专属9 tile、roofs.pal RGB5；'
             '每张道路与所属城市共用原版屋顶组，且 full-load 与连接热替换均必需。'
             '必须通过 johto_roof_reference_audit，不允许手调近似颜色或只核对 .blk。',
             ['tools/johto_roof_reference_audit.py','data/maps/roofs.asm',
              'gfx/tilesets/roofs.pal','color/loadpalettes.asm',
              'engine/overworld/johto_goldenrod_roof_gfx.asm']),
        item('warp_entrances', bool(events['warps'] or special),
             f'Gold Warp {len(events["warps"])} 个，特殊入口 {len(special)} 格；逐一核对双向、方向及落点',
             ['data/mapObjects/','tools/johto_door_contracts.json',
              'tools/johto_door_onboarding_audit.py']),
        item('surf', water > 0,
             f'Gold 水域相关16x16地格 {water} 个；逐岸核对上水、移动、上岸、徽章、音乐及双入口',
             ['engine/overworld/field_moves.asm','engine/items/items.asm',
              'home/overworld.asm','engine/overworld/johto_union_cave_surf.asm']),
        item('dig_escape_rope', cave,
             '洞穴需分别审核技能准入、最近入口来源、跨地区安全返程、旧档与黑屏返回',
             ['engine/items/items.asm','engine/special_warps.asm',
              'tools/johto_cave_escape_audit.py']),
        item('fly_use', outside,
             '室外可使用 Fly 的许可与徽章检查；不等于该地图是可选择的目的地',
             ['engine/menu/start_sub_menus.asm']),
        item('fly_destination', town,
             '城镇/城市的到访记录、目的地登记和安全落点，独立于Fly使用许可',
             ['engine/johto_fly_town_map.asm','engine/overworld/missable_objects.asm',
              'engine/fly_town_map_helpers.asm','engine/special_warps.asm',
              'tools/johto_fly_destination_audit.py']),
        item('bicycle', outside or cave,
             '按实际地图/tileset和入口限制核对骑行与进门下车，不自动加入白名单',
             ['data/bike_riding_tilesets.asm','engine/overworld/player_state.asm']),
        item('obstacle_field_moves', outside or cave,
             'Cut、Strength、Rock Smash、Flash及环境机关须独立查Gold事件与RPP能力',
             ['engine/overworld/field_moves.asm','engine/items/items.asm']),
        item('town_map', True, '地标显示坐标、可浏览与实际可Fly目的地分别核验',
             ['data/johto_map_headers.asm','tools/johto_town_map_bike_audit.py']),
        item('music_transitions', True, '正常切图、Warp、Surf、骑行/战斗后的音乐恢复',
             ['data/johto_map_headers.asm','home/overworld.asm']),
        item('encounters_and_events', bool(events['objects'] or events['signs'] or
                                           events['coord_events'] or outside or cave),
             f'Gold对象 {len(events["objects"])}、路牌 {len(events["signs"])}、坐标事件 {len(events["coord_events"])}；野生遭遇和脚本是独立移植项目',
             ['data/mapObjects/','scripts/','engine/overworld/wild_mons.asm']),
        item('save_continue_and_blackout', True,
             '地区/局部地图ID、Continue、旧档、Teleport、治疗点及跨地图返回安全',
             ['home/overworld.asm','engine/special_warps.asm']),
        item('runtime_build_and_phone', True,
             '编译链接/Bank余量、手机正反方向、边缘和旧功能回归须独立验收',
             ['RPP_PROJECT_CONTEXT/03_PROJECT_REQUIREMENTS.txt']),
    ]
    return {'schema': 'johto-gold-map-onboarding-v1', 'map': map_name,
            'gold_environment': environment, 'gold_tileset': art['tileset'],
            'evidence': {'water_cells': water, 'special_entrance_cells': len(special),
                         'hop_candidates': len(geometry['hops']),
                         'unsafe_hop_candidates': len(geometry['unsafe_hop_candidates']),
                         'warp_events': len(events['warps']), 'signs': len(events['signs']),
                         'objects': len(events['objects']),
                         'coord_events': len(events['coord_events'])},
            'checks': checks, 'scope': 'OFFLINE_REVIEW_ONLY',
            'runtime_approved': False, 'build_performed': False,
            'warning': 'REVIEW_REQUIRED means a check is needed, never that the feature is enabled. Do not auto-edit field move allow-lists.'}


def review_rpp_integration(rpp: Path, rpp_map: str, onboarding: dict) -> dict:
    """Reuse existing registration/Warp contracts; NEVER assert field-move execution.

    This is source-evidence only. Native capability metadata is not an engine
    switch; Fly *destination* status is not outdoor Fly *use* permission.
    """
    if not re.fullmatch(r'[A-Za-z][A-Za-z0-9_]*', rpp_map):
        raise ValueError('Invalid RPP map name')
    registration = audit_registration(rpp, rpp_map)
    errors = list(registration['failed_checks'])
    native_path = rpp/'tools/johto_native_maps.json'
    door_path = rpp/'tools/johto_door_contracts.json'
    native = json.loads(native_path.read_text(encoding='utf-8'))['maps']
    doors = json.loads(door_path.read_text(encoding='utf-8'))['active_warp_maps']
    matches = [entry for entry in native if entry.get('header') == rpp_map+'_h']
    if len(matches) != 1:
        errors.append('native map identity missing or duplicated')
    feature_status = matches[0].get('feature_status', {}) if len(matches)==1 else {}
    try:
        existing_warps = rpp_warps(rpp, rpp_map)
    except ConversionError as exc:
        existing_warps = []
        errors.append('RPP Warp table invalid: '+str(exc))
    door_contracts = [entry for entry in doors if entry.get('rpp_map') == rpp_map]
    if len(door_contracts) > 1 or (existing_warps and len(door_contracts) != 1):
        errors.append('active Warp requires exactly one existing door contract')
    if door_contracts:
        contract = door_contracts[0]
        if contract.get('warp_count') != len(existing_warps):
            errors.append('active Warp count differs from existing door contract')
        if contract.get('gold_map') != onboarding['map']:
            errors.append('door contract refers to another Gold map')
    if existing_warps and feature_status.get('warp') == 'FORBIDDEN':
        errors.append('enabled Warp contradicts forbidden map status')
    # A missing/unchecked permission never becomes an automatic ALLOWED flag.
    # DEFERRED is historical metadata, not proof of a runtime bug.
    return {
        'schema': 'johto-rpp-map-integration-review-v1',
        'rpp_map': rpp_map, 'gold_map': onboarding['map'],
        'registration': registration, 'gold_warps': onboarding['evidence']['warp_events'],
        'rpp_active_warps': len(existing_warps),
        'warp_contract_present': len(door_contracts) == 1,
        'native_feature_metadata': feature_status,
        'fly_destination_is_not_fly_use': True,
        'errors': errors,
        'status': 'STRUCTURAL_ERRORS' if errors else 'STATIC_STRUCTURE_PRESENT_REVIEW_RUNTIME',
        'runtime_approved': False, 'build_performed': False,
        'warning': ('Registration and existing contracts are static evidence only. '
                    'Surf/Dig/Escape Rope/Fly still need the independent runtime '
                    'gates, link/build evidence and actual gameplay tests.'),
    }



def run_project_static_gate(rpp: Path, gold: Path, integration: dict | None) -> dict:
    """Call the EXISTING full Gold audit; do not duplicate field-move logic.

    A passing project gate is only project-wide static evidence, not proof that
    this Gold candidate has been imported or that a field move works in-game.
    """
    from johto_map_release_audit import audit_project
    gate = audit_project(rpp, gold, expected_version=None, run_tests=True)
    errors = list(gate['errors'])
    if integration is not None:
        errors.extend('MAP_STRUCTURE: ' + err for err in integration['errors'])
    return {
        'schema': 'johto-rpp-project-static-preflight-v1',
        'status': ('STATIC_FAIL' if errors else 'PROJECT_STATIC_PASS_MAP_RUNTIME_PENDING'),
        'project_gate': gate,
        'map_structure_present': integration is not None and not integration['errors'],
        'map_specific_runtime_verified': False,
        'field_moves_approved': False,
        'compiled_rom': False,
        'phone_accepted': False,
        'errors': errors,
        "warning": ("A passing shared static gate does not certify this map\'s "
                    'Surf/Dig/Escape Rope/Fly, music, connections, Continue, '
                    'bank layout, compilation, or phone behavior.'),
    }

def full_gold_corpus(rpp: Path, gold: Path, output: Path) -> dict:
    """Scan every registered Gold map; errors never become runtime approvals."""
    import csv
    from collections import Counter
    from johto_indoor_common import gold_dimensions
    from johto_indoor_collision_adapter import portal_approach_edges
    rpp, gold, output = safe_roots(rpp, gold, output)
    registered = layout_inventory(gold)
    rows, edges, failures = [], [], []
    for item in registered:
        name, tileset = item['name'], tileset_key(item['tileset'])
        row = {'map': name, 'gold_tileset': item['tileset'],
               'width_blocks': item['width'], 'height_blocks': item['height'],
               'source_status': 'SOURCE_FAILED', 'source_error': '',
               'special_entrance_cells': 0, 'directional_cells': 0,
               'portal_approach_edges': 0, 'warp_events': 0,
               'collision_roles': '', 'runtime_status': 'NOT_TESTED',
               'phone_status': 'NOT_TESTED'}
        try:
            geometry, _ = plan_gold_quadrant_collision(gold, name, tileset)
            events = gold_event_records(gold, name, item['width'], item['height'])
            if events['warnings']:
                raise ConversionError('Gold 事件异常: ' + ','.join(events['warnings']))
            row.update(source_status='SOURCE_GEOMETRY_OK_RUNTIME_UNVERIFIED',
                       special_entrance_cells=len(geometry['special_cells']),
                       directional_cells=sum(x['role'].startswith('HOP_')
                                             for x in geometry['special_cells']),
                       portal_approach_edges=len(geometry['portal_edges']),
                       warp_events=len(events['warps']),
                       collision_roles=','.join(sorted(geometry['collision_roles'])))
            edges.extend({'map': name, **edge} for edge in geometry['portal_edges'])
        except (ConversionError, ValueError, OSError, KeyError) as exc:
            row['source_error'] = str(exc)
            failures.append({'map': name, 'error': str(exc)})
        rows.append(row)
    output.mkdir(parents=True, exist_ok=True)
    for filename, records, fields in (
        ('full_gold_corpus_preflight.csv', rows, list(rows[0])),
        ('full_gold_portal_edges.csv', edges,
         ['map', 'from_x', 'from_y', 'from_role', 'to_x', 'to_y', 'to_role',
          'direction', 'source_semantics', 'review_priority', 'rpp_runtime_verified'])):
        with (output/filename).open('w', encoding='utf-8', newline='') as stream:
            writer = csv.DictWriter(stream, fieldnames=fields)
            writer.writeheader()
            writer.writerows(records)
    summary = {'registered_maps': len(rows), 'source_ok': len(rows)-len(failures),
               'source_failed': len(failures), 'errors': failures,
               'special_entrance_cells': sum(x['special_entrance_cells'] for x in rows),
               'portal_approach_edges': len(edges), 'runtime_maps_verified': 0,
               'phone_maps_verified': 0,
               'status': 'FAIL' if failures else 'SOURCE_ONLY_RUNTIME_UNVERIFIED'}
    dump(output, 'full_gold_corpus_summary.json', summary)
    return summary


def main():
    ap = argparse.ArgumentParser(description=__doc__)
    ap.add_argument('--gold-root', type=Path, required=True)
    ap.add_argument('--project', type=Path, required=True)
    ap.add_argument('--output', type=Path, required=True)
    ap.add_argument('--preview-limit', type=int, default=12, help='preview maps; 0 disables')
    ap.add_argument('--audit-only', action='store_true', help='validate existing staged output')
    ap.add_argument('--full-gold-corpus', action='store_true', help='fail-closed scan of EVERY Gold map')
    ap.add_argument('--gold-map', default=None, help='single Gold map candidate using its own tileset')
    ap.add_argument('--gold-tileset', default=None, help='Optional cross-check; inferred from Gold registration if omitted')
    ap.add_argument('--rpp-map', default=None, help='When already wired, review the existing RPP map registration and Warp contract')
    ap.add_argument('--runtime-gate', action='store_true',
                    help='Reuse the complete existing Gold static gate; NEVER approves a map for gameplay')
    args = ap.parse_args()
    # Defense against accidentally wiping the project with staging outputs.
    # Unlike the legacy .135 script, this wrapper enforces disjoint trees.
    if args.output.is_symlink():
        ap.error('--output must not be a symlink')
    project = args.project.resolve()
    gold = args.gold_root.resolve()
    output = args.output.resolve()
    if output == project or project in output.parents or output in project.parents:
        ap.error('--output must be separate from the RPP project tree')
    if output == gold or gold in output.parents or output in gold.parents:
        ap.error('--output must be separate from the Gold source tree')
    if args.rpp_map and not args.gold_map:
        ap.error('--rpp-map requires --gold-map')
    if args.runtime_gate and (not args.gold_map or args.audit_only):
        ap.error('--runtime-gate requires --gold-map and cannot be used with --audit-only')
    if args.full_gold_corpus:
        if args.gold_map or args.audit_only or args.runtime_gate or args.rpp_map:
            ap.error('--full-gold-corpus cannot combine with single-map modes')
        summary = full_gold_corpus(project, gold, output)
        print('full_gold_corpus:', json.dumps(summary, ensure_ascii=False))
        return 2 if summary['source_failed'] else 0
    if args.gold_map is not None:
        if args.audit_only:
            ap.error('--gold-map cannot use --audit-only')
        rpp, gold, out = safe_roots(project, gold, output)
        matched = [m for m in layout_inventory(gold) if m['name']==args.gold_map]
        if len(matched)!=1:
            ap.error('--gold-map must identify exactly one Gold registered map')
        gold_set = tileset_key(matched[0]['tileset'])
        if args.gold_tileset and args.gold_tileset != gold_set:
            ap.error('--gold-tileset disagrees with Gold map registration')
        art = stage_preserved_gold_tileset(gold,out,args.gold_map,gold_set)
        geometry, mask = plan_gold_quadrant_collision(gold,args.gold_map,gold_set)
        (out/'gold_collision_mask.bin').write_bytes(mask)
        dump(out,'gold_art_candidate.json',art)
        dump(out,'gold_collision_candidate.json',geometry)
        onboarding = make_map_onboarding(gold,args.gold_map,art,geometry)
        dump(out,'map_onboarding.json',onboarding)
        integration = None
        if args.rpp_map:
            integration = review_rpp_integration(rpp,args.rpp_map,onboarding)
            dump(out,'rpp_integration_review.json',integration)
        runtime_review = None
        if args.runtime_gate:
            runtime_review = run_project_static_gate(rpp, gold, integration)
            dump(out, 'rpp_runtime_preflight.json', runtime_review)
        (out/'map_onboarding.md').write_text(
            '# '+args.gold_map+'｜地图接入与Field Moves核对清单\n\n'
            + '> 来源：Gold离线数据。此表不代表ROM已注册或技能已开放。\n\n'
            + '| 检查点 | 状态 | 原因 |\n|---|---|---|\n'
            + ''.join('| '+x['id']+' | '+x['status']+' | '+x['reason']+' |\n'
                      for x in onboarding['checks'])
            + ('\n## 已有RPP接入的结构核查\n\n'
               + ('发现待修复的结构错误：' + ', '.join(integration['errors'])
                  if integration['errors'] else '已找到地图登记和门口合同；技能运行状态仍待独立验证。')
               + '\n\n' if integration else ''), encoding='utf-8')
        print('Gold candidate:', json.dumps({'map':args.gold_map,
            'blocks':art['width']*art['height'],
            'blocked':geometry['blocked_count'], 'hops':len(geometry['hops']),
            'unsafe_hops':len(geometry['unsafe_hop_candidates']),
            'status':('OFFLINE_REVIEW_REQUIRED' if geometry['unsafe_hop_candidates']
                      else 'OFFLINE_CANDIDATE_ONLY')},ensure_ascii=False))
        return 2 if (integration and integration['errors']) or (runtime_review and runtime_review['errors']) else 0
    if not args.audit_only:
        outcome = batch(args.gold_root, args.project, args.output)
        print('stage:', json.dumps(outcome, ensure_ascii=False))
    report = verify(args.output, args.gold_root, args.project)
    render_previews(args.output, args.gold_root, args.project, report, args.preview_limit)
    write_reports(args.output, report)
    print('audit:', json.dumps({**report['summary'], 'status': report['status']}, ensure_ascii=False))
    print('HTML:', args.output / 'verification' / 'index.html')
    if report['status'] == 'FAILED':
        return 2
    print('Offline static checks complete; this is NOT a compiled/playable ROM.')
    return 0


if __name__ == '__main__':
    raise SystemExit(main())
