#!/usr/bin/env python3
"""Batch stage Gold maps, then independently audit the staging area.

No game files are modified. Output is intentionally NOT importable into RPP.
"""
import argparse
import hashlib
import json
import re
from pathlib import Path
from johto_gold_sources import gold_block_sources
from johto_gold_compat import PROFILES, detect_gold_profile, resolve_gold_root
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
             ['constants/region_map_constants.asm','constants/johto_fixed_map_ids.asm','data/johto_header_descriptors.asm','data/johto_pilot_map_headers.asm']),
        item('art_palette_vram_bank', True, '图像、色板、音效/背景音乐与固定 Bank 空间需要核对',
             ['data/tileset_headers.asm','data/johto_pilot_runtime_assets.asm','home.asm','home/overworld.asm']),
        item('collision_and_ledge', True,
             f'Gold 特殊地格 {len(special)}、跳崖候选 {len(geometry["hops"])}、不安全跳崖 {len(geometry["unsafe_hop_candidates"])}',
             ['home/overworld.asm','data/johto_pilot_runtime_assets.asm','gfx/tilesets/johto.tilecoll']),
        item('outdoor_connections', outside,
             '确认Gold连接方向、连接条带、反向、越界与跨tileset重载；没有自动放行',
             ['data/johto_pilot_map_headers.asm','home/overworld.asm','tools/johto_pilot_migration_audit.py']),
        item('roof_mapgroup_gold_reference', outside,
             '按 Gold data/maps/maps.asm 的 mapgroup 反查 roofs.asm 专属9 tile、roofs.pal RGB5；'
             '每张道路与所属城市共用原版屋顶组，且 full-load 与连接热替换均必需。'
             '必须通过 johto_roof_reference_audit，不允许手调近似颜色或只核对 .blk。',
             ['data/tileset_headers.asm','color/loadpalettes.asm','RPP_PROJECT_CONTEXT/03_PROJECT_REQUIREMENTS.txt']),
        item('warp_entrances', bool(events['warps'] or special),
             f'Gold Warp {len(events["warps"])} 个，特殊入口 {len(special)} 格；逐一核对双向、方向及落点',
             ['data/johto_pilot_map_headers.asm','data/johto_indoor_house.asm',
              'engine/johto_pilot_runtime.asm','tools/johto_pilot_migration_audit.py']),
        item('surf', water > 0,
             f'Gold 水域相关16x16地格 {water} 个；逐岸核对上水、移动、上岸、徽章、音乐及双入口；有水域必须运行 johto_surf_preflight.py 并登记水域合同',
             ['home/overworld.asm','engine/overworld/player_movement.asm','data/johto_pilot_runtime_assets.asm']),
        item('dig_escape_rope', cave,
             '洞穴需分别审核技能准入、最近入口来源、跨地区安全返程、旧档与黑屏返回',
             ['engine/special_warps.asm','engine/johto_pilot_runtime.asm',
              'RPP_PROJECT_CONTEXT/03_PROJECT_REQUIREMENTS.txt']),
        item('fly_use', outside,
             '室外可使用 Fly 的许可与徽章检查；不等于该地图是可选择的目的地',
             ['engine/menu/start_sub_menus.asm']),
        item('fly_destination', town,
             '城镇/城市的到访记录、目的地登记和安全落点，独立于Fly使用许可',
             ['engine/johto_pilot_fly_map.asm','engine/fly_town_map_helpers.asm',
              'engine/johto_pilot_runtime.asm']),
        item('bicycle', outside or cave,
             '按实际地图/tileset和入口限制核对骑行与进门下车，不自动加入白名单',
             ['data/bike_riding_tilesets.asm','engine/overworld/player_state.asm']),
        item('obstacle_field_moves', outside or cave,
             'Cut、Strength、Rock Smash、Flash及环境机关须独立查Gold事件与RPP能力',
             ['engine/overworld/field_moves.asm','engine/items/items.asm','home/overworld.asm']),
        item('town_map', True, '地标显示坐标、可浏览与实际可Fly目的地分别核验',
             ['data/town_map_entries.asm','color/town_map_pals.asm','engine/fly_town_map_helpers.asm','tools/johto_pilot_migration_audit.py']),
        item('music_transitions', True, '正常切图、Warp、Surf、骑行/战斗后的音乐恢复',
             ['data/map_songs.asm','engine/johto_pilot_runtime.asm','home/overworld.asm']),
        item('encounters_and_events', bool(events['objects'] or events['signs'] or
                                           events['coord_events'] or outside or cave),
             f'Gold对象 {len(events["objects"])}、路牌 {len(events["signs"])}、坐标事件 {len(events["coord_events"])}；野生遭遇和脚本是独立移植项目',
             ['data/johto_pilot_map_headers.asm','scripts/','engine/overworld/wild_mons.asm']),
        item('save_continue_and_blackout', True,
             '地区/局部地图ID、Continue、旧档、Teleport、治疗点及跨地图返回安全',
             ['home/overworld.asm','engine/johto_pilot_runtime.asm','RPP_PROJECT_CONTEXT/03_PROJECT_REQUIREMENTS.txt']),
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
    """Review a candidate against the CURRENT stable-ID pilot registration.

    The NPC-5.62.243 toolchain expected data/mapHeaders + johto_native_maps.json;
    the current project instead uses johto_pilot_map_headers.asm and compact
    active slots. This adapter intentionally accepts only current active labels.
    It is static evidence, never gameplay approval.
    """
    from johto_pilot_migration_audit import audit_project

    if not re.fullmatch(r'[A-Za-z][A-Za-z0-9_]*', rpp_map):
        raise ValueError('Invalid RPP map/header name')
    active = {
        'JohtoPilotNewBarkRuntimeHeader': ('NewBarkTown', 0),
        'JohtoPilotRoute29RuntimeHeader': ('Route29', 1),
        'JohtoPilotCherrygroveRuntimeHeader': ('CherrygroveCity', 2),
        'JohtoPilotRoute30RuntimeHeader': ('Route30', 3),
        'JohtoPilotRoute31RuntimeHeader': ('Route31', 4),
        'JohtoGuideGentsHouseRuntimeHeader': ('GuideGentsHouse', 125),
    }
    alias = {
        'JohtoNewBarkTown': 'JohtoPilotNewBarkRuntimeHeader',
        'JohtoRoute29': 'JohtoPilotRoute29RuntimeHeader',
        'JohtoCherrygroveCity': 'JohtoPilotCherrygroveRuntimeHeader',
        'JohtoRoute30': 'JohtoPilotRoute30RuntimeHeader',
        'JohtoRoute31': 'JohtoPilotRoute31RuntimeHeader',
        'JohtoGuideGentsHouse': 'JohtoGuideGentsHouseRuntimeHeader',
    }
    canonical = alias.get(rpp_map, rpp_map)
    errors = []
    if canonical not in active:
        errors.append('RPP map/header is not one of the current active pilot registrations')
        stable_id = None
        expected_gold = None
    else:
        expected_gold, stable_id = active[canonical]
        if expected_gold != onboarding['map']:
            errors.append(f'Gold map {onboarding["map"]} does not match active RPP header {canonical} ({expected_gold})')
    static_gate = audit_project(rpp)
    errors.extend('PILOT_AUDIT: ' + error for error in static_gate['errors'])
    return {
        'schema': 'johto-pilot-rpp-map-integration-review-v1',
        'rpp_map': rpp_map, 'canonical_header': canonical,
        'gold_map': onboarding['map'], 'stable_local_id': stable_id,
        'registered_active_map': canonical in active,
        'current_pilot_audit_status': static_gate['status'],
        'errors': errors,
        'status': 'STRUCTURAL_ERRORS' if errors else 'STATIC_STRUCTURE_PRESENT_REVIEW_RUNTIME',
        'runtime_approved': False, 'build_performed': False,
        'warning': ('Current stable-ID/active-slot structure was inspected. This does not certify map art, collisions, Warp arrivals, connections, bank space, compilation, or phone behavior.')
    }


def run_project_static_gate(rpp: Path, gold: Path, integration: dict | None) -> dict:
    """Run the current project's static migration gate, never a legacy ABI gate."""
    from johto_pilot_migration_audit import audit_project
    gate = audit_project(rpp, gold)
    errors = list(gate['errors'])
    if integration is not None:
        errors.extend('MAP_STRUCTURE: ' + err for err in integration['errors'])
    return {
        'schema': 'johto-pilot-project-static-preflight-v1',
        'status': 'STATIC_FAIL' if errors else 'PROJECT_STATIC_PASS_MAP_RUNTIME_PENDING',
        'project_gate': gate,
        'map_structure_present': integration is not None and not integration['errors'],
        'map_specific_runtime_verified': False,
        'field_moves_approved': False,
        'compiled_rom': False,
        'phone_accepted': False,
        'errors': errors,
        'warning': ('A passing current-project static gate does not certify this candidate map is playable, nor does it replace current Red/Blue build, MAP, or phone acceptance.')
    }


# User-requested, explicitly scoped source-corpus exclusion. This abandoned
# Gold beta Safari map is NOT scanned or counted as passed. Do not broaden this
# list to working Johto maps or silently change the excluded name.
GOLD_CORPUS_SOURCE_EXCLUSIONS = frozenset({'SafariZoneBeta'})


def full_gold_corpus(rpp: Path, gold: Path, output: Path) -> dict:
    """Source-audit all Gold maps except explicitly documented beta exclusions."""
    import csv
    from collections import Counter
    from johto_indoor_common import gold_dimensions
    from johto_indoor_collision_adapter import portal_approach_edges
    rpp, gold, output = safe_roots(rpp, gold, output)
    registered = layout_inventory(gold)
    rows, edges, failures, excluded = [], [], [], []
    for item in registered:
        if item['name'] in GOLD_CORPUS_SOURCE_EXCLUSIONS:
            excluded.append({'map': item['name'], 'reason': 'USER_EXCLUDED_BETA_MAP'})
            continue  # no asset, geometry, or event scan of this excluded map
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
    summary = {'registered_maps': len(registered), 'scanned_maps': len(rows),
               'excluded_maps': excluded, 'excluded_count': len(excluded),
               'source_ok': len(rows)-len(failures),
               'source_failed': len(failures), 'errors': failures,
               'special_entrance_cells': sum(x['special_entrance_cells'] for x in rows),
               'portal_approach_edges': len(edges), 'runtime_maps_verified': 0,
               'phone_maps_verified': 0,
               'status': 'FAIL' if failures else 'SOURCE_ONLY_RUNTIME_UNVERIFIED'}
    dump(output, 'full_gold_corpus_summary.json', summary)
    return summary



def stage_gold_map_candidate(rpp: Path, gold: Path, out: Path, map_name: str,
                             tileset: str, rpp_map: str | None = None,
                             runtime_gate: bool = False) -> dict:
    """Stage exactly one Gold map using the existing converter and audit parts.

    Shared by single-map and adjacent-pair mode.  This is *never* an RPP
    runtime registration and cannot approve Surf, Fly or a Warp.
    """
    art = stage_preserved_gold_tileset(gold, out, map_name, tileset)
    geometry, mask = plan_gold_quadrant_collision(gold, map_name, tileset)
    (out/'gold_collision_mask.bin').write_bytes(mask)
    dump(out, 'gold_art_candidate.json', art)
    dump(out, 'gold_collision_candidate.json', geometry)
    onboarding = make_map_onboarding(gold, map_name, art, geometry)
    dump(out, 'map_onboarding.json', onboarding)
    integration = None
    if rpp_map:
        integration = review_rpp_integration(rpp, rpp_map, onboarding)
        dump(out, 'rpp_integration_review.json', integration)
    runtime_review = None
    if runtime_gate:
        runtime_review = run_project_static_gate(rpp, gold, integration)
        dump(out, 'rpp_runtime_preflight.json', runtime_review)
    (out/'map_onboarding.md').write_text(
        '# '+map_name+'｜地图接入与Field Moves核对清单\n\n'
        + '> 来源：Gold离线数据。此表不代表ROM已注册或技能已开放。\n\n'
        + '| 检查点 | 状态 | 原因 |\n|---|---|---|\n'
        + ''.join('| '+x['id']+' | '+x['status']+' | '+x['reason']+' |\n'
                  for x in onboarding['checks'])
        + ('\n## 已有RPP接入的结构核查\n\n'
           + ('发现待修复的结构错误：' + ', '.join(integration['errors'])
              if integration['errors'] else '已找到地图登记和门口合同；技能运行状态仍待独立验证。')
           + '\n\n' if integration else ''), encoding='utf-8')
    errors = ((integration and integration['errors']) or
              (runtime_review and runtime_review['errors']) or [])
    return {'map': map_name, 'width': art['width'], 'height': art['height'],
            'tileset': tileset, 'blocked': geometry['blocked_count'],
            'hops': len(geometry['hops']),
            'unsafe_hops': len(geometry['unsafe_hop_candidates']),
            'gold_warps': onboarding['evidence']['warp_events'],
            'water_cells': onboarding['evidence']['water_cells'],
            'gold_block_source': gold_block_sources(gold).get(map_name),
            'gold_blk_sha256': hashlib.sha256((gold/gold_block_sources(gold)[map_name]).read_bytes()).hexdigest(),
            'staged_blk_matches_gold': (out/'preserved_gold_art_candidate'/f'{map_name}.blk').read_bytes()
                == (gold/gold_block_sources(gold)[map_name]).read_bytes(),
            'status': 'STATIC_REVIEW_FAILED' if errors else 'OFFLINE_REVIEW_REQUIRED',
            'runtime_approved': False, 'build_performed': False,
            'errors': errors}


def stage_adjacent_pair(rpp: Path, gold: Path, output: Path, names: tuple[str, str]) -> dict:
    """Conservatively prepare two *directly neighboring* Gold maps in one run.

    The frozen source connection audit independently verifies original Gold's
    two-way topology.  It intentionally does not generate speculative RPP ASM,
    collision exceptions, offscreen preview strips, or gameplay permissions.
    """
    from johto_gold_connection_reference import (check_frozen_gold_source,
                                                  GATE_REPLACED_DIRECT_SEAMS)
    rpp, gold, output = safe_roots(rpp, gold, output)
    first, second = names
    if first == second or any(not re.fullmatch(r'[A-Za-z][A-Za-z0-9_]*', n) for n in names):
        raise ConversionError('Adjacent pair needs two different registered Gold map names')
    inventory = {item['name']: item for item in layout_inventory(gold)}
    if any(n not in inventory for n in names):
        raise ConversionError('Both adjacent-pair maps must exist in Gold registration')
    seams = check_frozen_gold_source(gold)
    forward = [ (direction, offset) for (current, direction), (target, offset) in seams.items()
                if current == first and target == second]
    reverse = [ (direction, offset) for (current, direction), (target, offset) in seams.items()
                if current == second and target == first]
    if len(forward) != 1 or len(reverse) != 1:
        raise ConversionError(f'{first} and {second} are not a direct bidirectional Gold connection')
    direction, offset = forward[0]
    direction_back, offset_back = reverse[0]
    if ((first, direction, second) in GATE_REPLACED_DIRECT_SEAMS or
        (second, direction_back, first) in GATE_REPLACED_DIRECT_SEAMS):
        raise ConversionError('Gold pair uses an intentionally gate-replaced connection')
    results = []
    for name in names:
        subdir = output/name
        # Re-run safe_roots on the actual subdirectory to preserve both
        # source separation and "empty output" semantics on subsequent runs.
        safe_roots(rpp, gold, subdir)
        key = tileset_key(inventory[name]['tileset'])
        results.append(stage_gold_map_candidate(rpp, gold, subdir, name, key))
    info = {'schema': 'johto-gold-adjacent-pair-source-v1',
            'maps': results, 'source_adjacent': True,
            'direct_seams': [
                {'from': first, 'to': second, 'direction': direction,
                 'gold_offset_blocks': offset},
                {'from': second, 'to': first, 'direction': direction_back,
                 'gold_offset_blocks': offset_back}],
            'checked_gold_connection_contract': 'all_142_edges_match_source',
            'source_geometry_verified': all(r['staged_blk_matches_gold'] for r in results),
            'runtime_approved': False, 'build_performed': False,
            'status': 'OFFLINE_PAIR_REVIEW_REQUIRED',
            'outstanding': ['both directions of RPP connection and visible edge preview',
                            'stable ID / active slot / headers / banks / audio / Town Map',
                            'all applicable Surf, Fly, Warp, collision and ledge contracts',
                            'release audit, real build and phone testing']}
    dump(output, 'adjacent_pair_manifest.json', info)
    return info

def stage_adjacent_chain(rpp: Path, gold: Path, output: Path,
                         names: tuple[str, ...]) -> dict:
    """Use Gold's existing converter to stage a strictly connected batch.

    Each consecutive pair needs two reciprocal, frozen Gold connections;
    do not equate numeric stable ID order with actual geographic adjacency.
    All topology is checked *before* the first file is written.
    """
    from johto_gold_connection_reference import (check_frozen_gold_source,
                                                  GATE_REPLACED_DIRECT_SEAMS)
    rpp, gold, output = safe_roots(rpp, gold, output)
    if not 2 <= len(names) <= 3 or len(names) != len(set(names)) or any(
            not re.fullmatch(r'[A-Za-z][A-Za-z0-9_]*', name) for name in names):
        raise ConversionError('Adjacent chain requires 2-3 distinct Gold maps')
    inventory = {item['name']: item for item in layout_inventory(gold)}
    if any(name not in inventory for name in names):
        raise ConversionError('Adjacent chain contains an unknown Gold map')
    seams = check_frozen_gold_source(gold)
    links=[]
    for first,second in zip(names,names[1:]):
        fwd=[(direction,offset) for (src,direction),(dst,offset) in seams.items()
             if src==first and dst==second]
        back=[(direction,offset) for (src,direction),(dst,offset) in seams.items()
              if src==second and dst==first]
        if len(fwd)!=1 or len(back)!=1 or any(
            (a,b,c) in GATE_REPLACED_DIRECT_SEAMS for a,b,c in
            ((first,fwd[0][0],second),(second,back[0][0],first))):
            raise ConversionError(f'{first} and {second} are not a direct bidirectional Gold connection')
        links.extend([{'from':first,'to':second,'direction':fwd[0][0],
                       'gold_offset_blocks':fwd[0][1]},
                      {'from':second,'to':first,'direction':back[0][0],
                       'gold_offset_blocks':back[0][1]}])
    results=[]
    for name in names:
        dest=output/name
        safe_roots(rpp,gold,dest)
        results.append(stage_gold_map_candidate(rpp,gold,dest,name,
                       tileset_key(inventory[name]['tileset'])))
    info={'schema':'johto-gold-adjacent-chain-source-v1',
          'maps':results,'direct_seams':links,'source_adjacent':True,
          'source_geometry_verified':all(r['staged_blk_matches_gold'] for r in results),
          'runtime_approved':False,'build_performed':False,
          'status':'OFFLINE_CHAIN_REVIEW_REQUIRED'}
    dump(output,'adjacent_chain_manifest.json',info)
    return info


def main():
    ap = argparse.ArgumentParser(description=__doc__)
    ap.add_argument('--gold-root', type=Path, required=True,
                    help='已解压的 pret/MUS Gold 根目录，或只包含一个项目根的父目录')
    ap.add_argument('--gold-profile', choices=PROFILES, default='auto',
                    help='auto 自动识别；pret/mus 用于严格核对输入身份')
    ap.add_argument('--project', type=Path, required=True)
    ap.add_argument('--output', type=Path, required=True)
    ap.add_argument('--preview-limit', type=int, default=12, help='preview maps; 0 disables')
    ap.add_argument('--audit-only', action='store_true', help='validate existing staged output')
    ap.add_argument('--full-gold-corpus', action='store_true', help='source scan of all Gold maps except explicitly excluded beta maps')
    ap.add_argument('--gold-map', default=None, help='single Gold map candidate using its own tileset')
    ap.add_argument('--adjacent-pair', nargs=2, metavar=('FIRST', 'SECOND'),
                    help='stage two directly adjacent Gold maps and audit their source topology')
    ap.add_argument('--adjacent-chain', nargs='+', metavar='MAP',
                    help='stage a Gold-connected sequence of 2-3 maps with reciprocal seams')
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
    output = args.output.resolve()
    if output == project or project in output.parents or output in project.parents:
        ap.error('--output must be separate from the RPP project tree')
    try:
        gold = resolve_gold_root(args.gold_root, args.gold_profile)
    except ValueError as exc:
        ap.error(str(exc))
    if output == gold or gold in output.parents or output in gold.parents:
        ap.error('--output must be separate from the Gold source tree')
    if args.rpp_map and not args.gold_map:
        ap.error('--rpp-map requires --gold-map')
    if args.runtime_gate and (not args.gold_map or args.audit_only):
        ap.error('--runtime-gate requires --gold-map and cannot be used with --audit-only')
    print(f"Gold source profile: {detect_gold_profile(gold)}; root: {gold}")
    if args.adjacent_chain:
        if (args.gold_map or args.audit_only or args.runtime_gate or args.rpp_map or
            args.full_gold_corpus or args.gold_tileset or args.adjacent_pair):
            ap.error('--adjacent-chain cannot combine with other modes')
        info=stage_adjacent_chain(project,gold,output,tuple(args.adjacent_chain))
        print('Gold adjacent chain:',json.dumps({'maps':args.adjacent_chain,
              'seams':info['direct_seams'],'status':info['status']},ensure_ascii=False))
        return 0
    if args.adjacent_pair:
        if args.gold_map or args.audit_only or args.runtime_gate or args.rpp_map or args.full_gold_corpus or args.gold_tileset:
            ap.error('--adjacent-pair cannot combine with other staging modes')
        info = stage_adjacent_pair(project, gold, output, tuple(args.adjacent_pair))
        print('Gold adjacent pair:', json.dumps({'maps': args.adjacent_pair,
              'seams': info['direct_seams'], 'status': info['status']}, ensure_ascii=False))
        return 0
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
        item = stage_gold_map_candidate(rpp, gold, out, args.gold_map, gold_set,
                                        args.rpp_map, args.runtime_gate)
        print('Gold candidate:', json.dumps(item, ensure_ascii=False))
        return 2 if item['errors'] else 0
    if not args.audit_only:
        outcome = batch(gold, project, output)
        print('stage:', json.dumps(outcome, ensure_ascii=False))
    report = verify(output, gold, project)
    render_previews(output, gold, project, report, args.preview_limit)
    write_reports(output, report)
    print('audit:', json.dumps({**report['summary'], 'status': report['status']}, ensure_ascii=False))
    print('HTML:', output / 'verification' / 'index.html')
    if report['status'] == 'FAILED':
        return 2
    print('Offline static checks complete; this is NOT a compiled/playable ROM.')
    return 0


if __name__ == '__main__':
    raise SystemExit(main())
