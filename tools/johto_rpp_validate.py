#!/usr/bin/env python3
"""Independent, read-only audit of a .135 Johto batch staging directory.

Static passes mean candidate bytes are internally consistent; they are NOT a
ROM build, equivalent collision physics, safe scripting, or playable maps.
Writes verification reports ONLY beneath --output.
"""
import argparse
from collections import Counter
import hashlib
from html import escape
import json
from pathlib import Path
import re
from johto_gold_sources import gold_block_sources
from johto_gold_compat import PROFILES, resolve_gold_root
from johto_rpp_tileset_contract import matches_gold_prefix, check_runtime_contract

CLONE_TO_SOURCE = {0x20: 0x05, 0x21: 0x4c, 0x30: 0x06, 0x5b: 0x07}
SAFE_NAME = re.compile(r'^[A-Za-z][A-Za-z0-9_]*$')
REFERENCE = {'Route29': 'maps/JohtoRoute29.blk',
             'NewBarkTown': 'maps/NewBarkTown.blk'}


def sha(data):
    return hashlib.sha256(data).hexdigest()


def checked_file(root, relative):
    # Path membership and symlink checks keep a report from accidentally
    # validating an arbitrary path outside the designated staging tree.
    path = root / relative
    if Path(relative).is_absolute() or '..' in Path(relative).parts:
        raise ValueError('unsafe relative path: ' + str(relative))
    if any(p.is_symlink() for p in (path, *path.parents) if p != root.parent):
        raise ValueError('symlink in audit path: ' + str(path))
    return path.read_bytes()


def diagnostic(code, detail='', level='ERROR'):
    return {'level': level, 'code': code, 'detail': str(detail)}


def load_json(output, relative, problems):
    try:
        return json.loads(checked_file(output, relative))
    except (OSError, ValueError, json.JSONDecodeError) as ex:
        problems.append(diagnostic('required_artifact_unreadable', f'{relative}: {ex}'))
        return None


def compare_graphics(gold_layout, staged_layout, gold_metatiles, shared):
    """Count geometry mismatches, ignoring known exact-copy tile variants.

    This deliberately compares tile IDs, not a screenshot or game collision.
    """
    bad = []
    for block_idx, (s, t) in enumerate(zip(gold_layout, staged_layout)):
        a = gold_metatiles[s * 16:s * 16 + 16]
        b = shared[t * 16:t * 16 + 16]
        if len(a) != 16 or len(b) != 16:
            bad.append(block_idx)
        elif a != bytes(CLONE_TO_SOURCE.get(tile, tile) for tile in b):
            bad.append(block_idx)
    return bad



def gold_collision_labels(path):
    """Parse the original 16x16 Gold labels independently of the converter."""
    labels = []
    for line in path.read_text().splitlines():
        match = re.search(r'\btilecoll\s+([^;]+)\s*;', line)
        if match:
            labels.append(tuple(part.strip() for part in match.group(1).split(',')))
    if len(labels) != 128 or any(len(row) != 4 for row in labels):
        raise ValueError('invalid Gold Johto collision labels')
    return labels


def staged_walkability_errors(gold_map, candidate, width, height,
                              labels, blocks, passable):
    """Check the FINAL candidate bytes, never the source metatile indices."""
    must_walk = {'LADDER', 'TALL_GRASS', 'WARP_CARPET_LEFT',
                 'WARP_CARPET_RIGHT', 'WARP_CARPET_DOWN'}
    if (len(gold_map) != width * height or len(candidate) != width * height
            or len(blocks) % 16 or
            any(b >= len(blocks) // 16 for b in candidate)):
        raise ValueError('invalid candidate dimensions or metatile indices')
    bad = []
    for y in range(height * 2):
        for x in range(width * 2):
            pos = (y // 2) * width + x // 2
            quadrant = (y % 2) * 2 + (x % 2)
            if labels[gold_map[pos]][quadrant] not in must_walk:
                continue
            off = (y % 2) * 8 + (x % 2) * 2 + 4
            tile = blocks[candidate[pos] * 16 + off]
            if tile not in passable:
                bad.append((x, y, tile))
    return bad


def verify(output, gold, project):
    output, gold, project = (Path(x).resolve() for x in (output, gold, project))
    problems = []
    manifest = load_json(output, 'manifest.json', problems)
    inventory = load_json(output, 'full_gold_inventory.json', problems)
    import_plan = load_json(output, 'import_plan.json', problems)
    events = load_json(output, 'full_gold_events_locations.json', problems)
    staged_events = load_json(output, 'events_locations.json', problems)
    if not all(isinstance(x, dict) for x in
               (manifest, inventory, import_plan, events, staged_events)):
        return make_result([], problems, {}, {})
    if manifest.get('schema') != 'rpp-johto-batch-preview-v1':
        problems.append(diagnostic('wrong_manifest_schema'))
    if inventory.get('schema') != 'rpp-gold-full-map-inventory-v1':
        problems.append(diagnostic('wrong_inventory_schema'))
    if import_plan.get('schema') != 'rpp-johto-import-plan-v1':
        problems.append(diagnostic('wrong_import_plan_schema'))
    if (manifest.get('mode') != 'OFFLINE_PREVIEW_ONLY' or
            import_plan.get('mode') != 'NON_EXECUTABLE_PLAN'):
        problems.append(diagnostic('unexpected_write_or_import_mode'))
    try:
        shared = checked_file(output, 'johto_blockset_candidate.bst')
        gold_tiles = checked_file(gold, 'data/tilesets/johto_metatiles.bin')
        rpp_tiles = checked_file(project, 'gfx/blocksets/johto.bst')
    except (OSError, ValueError) as ex:
        problems.append(diagnostic('required_tileset_unreadable', ex))
        return make_result([], problems, {}, {})
    if (len(shared) % 16 or not 128 <= len(shared)//16 <= 256 or
            len(gold_tiles) != 2048 or not shared.startswith(rpp_tiles) or
            not matches_gold_prefix(gold_tiles, rpp_tiles)):
        problems.append(diagnostic('shared_tileset_incompatible',
                                   f'{len(shared)} bytes staged'))
    try:
        check_runtime_contract(gold_tiles, project)
    except (ValueError, OSError) as ex:
        problems.append(diagnostic('johto_runtime_collision_or_palette_incompatible', ex))
    try:
        johto_labels = gold_collision_labels(gold / 'data/tilesets/johto_collision.asm')
        passable = set(checked_file(project, 'gfx/tilesets/johto.tilecoll')[:-1])
    except (OSError, ValueError) as ex:
        johto_labels, passable = None, set()
        problems.append(diagnostic('gold_collision_or_runtime_walkability_unreadable', ex))
    count = len(shared)//16
    if count != manifest.get('shared_block_count'):
        problems.append(diagnostic('shared_block_count_mismatch'))
    plan_rows = import_plan.get('maps', [])
    inv_rows = inventory.get('maps', [])
    stage_rows = manifest.get('maps', [])
    if not all(isinstance(x, list) for x in (plan_rows, inv_rows, stage_rows)):
        problems.append(diagnostic('invalid_manifest_structure'))
        return make_result([], problems, {}, {})
    def index_rows(rows, section):
        result = {}
        for row in rows:
            name = row.get('name') if isinstance(row, dict) else None
            if not isinstance(name, str) or not SAFE_NAME.fullmatch(name) or name in result:
                problems.append(diagnostic('invalid_or_duplicate_map_name', f'{section}:{name}'))
                continue
            result[name] = row
        return result
    staged = index_rows(stage_rows, 'stage')
    inventories = index_rows(inv_rows, 'inventory')
    plans = index_rows(plan_rows, 'plan')
    if set(staged) != set(plans):
        problems.append(diagnostic('import_plan_stage_names_disagree'))
    if not set(staged).issubset(inventories):
        problems.append(diagnostic('inventory_missing_staged_maps'))
    if len(inventories) != inventory.get('registered_gold_maps'):
        problems.append(diagnostic('inventory_count_mismatch'))
    if len(staged) != inventory.get('staged_johto_maps'):
        problems.append(diagnostic('staged_map_count_mismatch'))
    proposed_ids = [p.get('proposed_johto_local_id') for p in plans.values()]
    if (any(type(x) is not int for x in proposed_ids) or
            set(proposed_ids) != set(range(len(proposed_ids))) or
            len(proposed_ids) != len(plans)):
        problems.append(diagnostic('non_contiguous_local_map_ids'))
    if len(staged) > 2 and any(p.get('game_registered') is True for name, p in plans.items() if name not in REFERENCE):
        problems.append(diagnostic('unverified_map_claimed_registered'))
    try:
        gold_layout_sources = gold_block_sources(gold)
    except (OSError, ValueError) as ex:
        problems.append(diagnostic('gold_blocks_index_unreadable', ex))
        gold_layout_sources = {}
    source_users = {}
    for name in inventories:
        if name in gold_layout_sources:
            source_users.setdefault(gold_layout_sources[name], []).append(name)
    map_results = []
    known_destinations = {name.replace('_', '').lower() for name in inventories}
    for name, row in sorted(inventories.items()):
        issues = []
        w, h = row.get('width'), row.get('height')
        if type(w) is not int or type(h) is not int or w <= 0 or h <= 0:
            issues.append(diagnostic('invalid_dimensions'))
            w = h = 0
        source_layout = gold_layout_sources.get(name)
        if source_layout is None:
            issues.append(diagnostic('gold_blocks_label_missing', name))
        elif source_layout != row.get('source_layout'):
            issues.append(diagnostic('source_layout_reference_mismatch',
                                     f'{row.get("source_layout")} vs {source_layout}'))
        expected_shared = sorted(other for other in source_users.get(source_layout, [])
                                 if other != name)
        if row.get('shared_layout_with') != expected_shared:
            issues.append(diagnostic('shared_layout_references_mismatch', name))
        try:
            original = checked_file(gold, source_layout) if source_layout else None
        except (OSError, ValueError) as ex:
            issues.append(diagnostic('original_map_unreadable', ex))
            original = None
        if original is not None:
            if len(original) != w * h:
                issues.append(diagnostic('original_map_size_mismatch', f'{len(original)} vs {w*h}'))
            if sha(original) != row.get('source_sha256'):
                issues.append(diagnostic('original_map_hash_mismatch'))
        report = {'name': name, 'tileset': row.get('tileset'),
                  'dimensions': [w, h], 'candidate': None,
                  'tile_identity': 'NOT_CHECKED', 'issues': issues,
                  'stage_status': row.get('terrain_status'),
                  'events': Counter(), 'game_status': 'NOT_TESTED'}
        if name in staged:
            entry = staged[name]
            status = entry.get('status')
            report['stage_status'] = status
            # Independent source-level entrance audit. The candidate only
            # stages scenery: Gold DOOR/CAVE do not prove that an RPP door
            # tile, destination Warp, or return path exists.
            if (name not in REFERENCE and entry.get('status') != 'blocked' and
                    johto_labels is not None and
                    original is not None and len(original) == w * h and
                    max(original, default=0) < len(johto_labels)):
                entrances = {'DOOR': 0, 'CAVE': 0}
                for pos in original:
                    for label in johto_labels[pos]:
                        if label in entrances:
                            entrances[label] += 1
                entrances = {label: num for label, num in entrances.items() if num}
                if entrances:
                    listed = [item for item in entry.get('findings', [])
                              if isinstance(item, dict) and
                              item.get('code') == 'entrance_requires_warp_and_engine_review']
                    expected_warps = len(events.get(name, {}).get('warps', []))
                    if (len(listed) != 1 or
                            listed[0].get('count') != sum(entrances.values()) or
                            listed[0].get('by_label') != entrances or
                            listed[0].get('gold_warp_count') != expected_warps):
                        issues.append(diagnostic('entrance_review_manifest_missing_or_mismatched'))
                    if entry.get('status') == 'candidate':
                        issues.append(diagnostic('entrance_candidate_claimed_ready'))
            if entry.get('source_sha256') != row.get('source_sha256'):
                issues.append(diagnostic('manifest_source_hash_mismatch'))
            if [entry.get('width'), entry.get('height')] != [w, h]:
                issues.append(diagnostic('staged_dimensions_disagree'))
            path = f'candidate_maps/{name}.blk'
            try:
                candidate = checked_file(output, path)
            except FileNotFoundError:
                candidate = None
            except (OSError, ValueError) as ex:
                candidate = None
                issues.append(diagnostic('candidate_unreadable', ex))
            if status == 'blocked':
                if candidate is not None:
                    issues.append(diagnostic('blocked_map_has_candidate'))
            elif candidate is None:
                issues.append(diagnostic('nonblocked_map_missing_candidate'))
            if candidate is not None:
                report['candidate'] = path
                if len(candidate) != w * h:
                    issues.append(diagnostic('candidate_size_mismatch', f'{len(candidate)} vs {w*h}'))
                if candidate and max(candidate) >= count:
                    issues.append(diagnostic('candidate_block_index_overflow', f'{max(candidate)}>={count}'))
                if (johto_labels is not None and original is not None and
                        len(candidate) == len(original) == w * h and
                        max(original, default=0) < 128 and
                        max(candidate, default=0) < count):
                    try:
                        missing = staged_walkability_errors(
                            original, candidate, w, h, johto_labels, shared, passable)
                        if missing:
                            issues.append(diagnostic('candidate_walkability_regression',
                                                     f'{len(missing)} cells; examples {missing[:8]}'))
                    except (ValueError, IndexError) as ex:
                        issues.append(diagnostic('candidate_walkability_audit_failed', ex))
                if name in REFERENCE:
                    try:
                        preserved = checked_file(project, REFERENCE[name])
                        if candidate != preserved:
                            issues.append(diagnostic('reference_map_mutated'))
                    except (OSError, ValueError) as ex:
                        issues.append(diagnostic('reference_map_unreadable', ex))
                    report['tile_identity'] = 'EXISTING_RPP_REFERENCE'
                elif (original is not None and len(candidate) == len(original)
                      and len(original) == w*h and
                      max(candidate, default=0) < count and
                      max(original, default=0) < 128 and
                      len(gold_tiles) == 2048):
                    bad = compare_graphics(original, candidate, gold_tiles, shared)
                    report['tile_identity'] = 'PASS' if not bad else 'FAIL'
                    if bad:
                        issues.append(diagnostic('tile_identity_mismatch',
                                                 f'{len(bad)} blocks; examples {bad[:8]}'))
        elif row.get('unverified_layout_candidate'):
            path = row['unverified_layout_candidate']
            if not (isinstance(path, str) and re.fullmatch(
                    r'unverified_shared_metatiles_maps/[A-Za-z][A-Za-z0-9_]*\.blk', path)
                    and path.endswith('/' + name + '.blk')):
                issues.append(diagnostic('invalid_unverified_candidate_path'))
            else:
                try:
                    candidate = checked_file(output, path)
                    report['candidate'] = path
                    if original != candidate:
                        issues.append(diagnostic('unverified_layout_not_source_copy'))
                except (OSError, ValueError) as ex:
                    issues.append(diagnostic('unverified_layout_unreadable', ex))
        if row.get('tileset') == 'TILESET_JOHTO' and name not in staged:
            issues.append(diagnostic('johto_map_not_in_staging'))
        if name in staged:
            gold_original = None
            try:
                gold_original = checked_file(output, f'original_maps/{name}.blk')
            except (OSError, ValueError) as ex:
                issues.append(diagnostic('staged_source_unreadable', ex))
            if original is not None and gold_original != original:
                issues.append(diagnostic('staged_source_disagrees_with_gold'))
            plan = plans.get(name, {})
            if plan.get('terrain_status') != report['stage_status']:
                issues.append(diagnostic('plan_stage_status_disagree'))
            if plan.get('terrain_file') != (f'candidate_maps/{name}.blk' if report['stage_status'] != 'blocked' else None):
                issues.append(diagnostic('plan_candidate_path_disagree'))
            if name not in REFERENCE and (plan.get('game_registered') is True or not plan.get('requires_native_region_map_support')):
                issues.append(diagnostic('nonreference_map_pretends_integrated'))
            for connection in entry.get('connections', []):
                target = connection.get('to')
                if target not in inventories:
                    issues.append(diagnostic('connection_target_absent', target, 'WARNING'))
                if connection.get('direction') not in ('north', 'south', 'east', 'west'):
                    issues.append(diagnostic('invalid_connection_direction'))
        for event_section, all_evs in ((events.get(name), 'all'), (staged_events.get(name), 'staged')):
            if event_section is None:
                if all_evs == 'all':
                    issues.append(diagnostic('missing_event_inventory'))
                continue
            for key in ('warps', 'signs', 'objects', 'coord_events'):
                nodes = event_section.get(key, [])
                report['events'][key] = max(report['events'][key], len(nodes))
                for node in nodes:
                    x, y = node.get('x'), node.get('y')
                    if type(x) is not int or type(y) is not int or not 0 <= x < w*2 or not 0 <= y < h*2:
                        issues.append(diagnostic('event_coordinate_invalid', f'{all_evs}:{key}:{x},{y}'))
                    if key == 'warps':
                        destination = node.get('destination', '')
                        keyname = str(destination).replace('_', '').lower()
                        if keyname not in known_destinations and keyname not in ('lastmap', 'mapnull', '0', 'none'):
                            issues.append(diagnostic('warp_destination_unresolved',
                                                     f'{destination}', 'WARNING'))
            for warning in event_section.get('warnings', []):
                issues.append(diagnostic('source_event_warning', warning, 'WARNING'))
        report['issues'] = issues
        report['static_status'] = 'FAIL' if any(x['level'] == 'ERROR' for x in issues) else (
            'REVIEW' if report['stage_status'] in ('blocked', 'review_required', 'requires_adapter',
                                                   'source_review_required', 'unverified_shared_metatiles_candidate')
            or issues or report['tile_identity'] == 'NOT_CHECKED' else 'PASS')
        map_results.append(report)
    # Reject orphan candidates as stale pipeline artifacts.
    for folder, key in (('candidate_maps', staged),
                        ('original_maps', staged),
                        ('unverified_shared_metatiles_maps', inventories)):
        target = output / folder
        if target.is_symlink():
            problems.append(diagnostic('unsafe_staging_directory', folder))
        elif target.exists():
            for path in target.glob('*.blk'):
                if path.is_symlink() or path.stem not in key:
                    problems.append(diagnostic('unexpected_staging_file', str(path.relative_to(output))))
                elif folder == 'unverified_shared_metatiles_maps' and inventories[path.stem].get('unverified_layout_candidate') != f'{folder}/{path.name}':
                    problems.append(diagnostic('stale_unverified_candidate', path.name))
    for name, row in inventories.items():
        if name not in staged and row.get('tileset') != 'TILESET_JOHTO':
            if row.get('terrain_status') == 'unverified_shared_metatiles_candidate' and not row.get('unverified_layout_candidate'):
                problems.append(diagnostic('unverified_candidate_without_path', name))
    # This is a source-level *presence* check, not an assertion that the
    # far-call, collision or save-path code was formally verified.
    readiness = {'native_region_map_paths': 'UNVERIFIED',
                 'bulk_map_registration': 'NOT_IMPLEMENTED',
                 'compiled_rom': 'NOT_RUN', 'emulator_smoke_test': 'NOT_RUN',
                 'scripts_and_collision': 'NOT_VERIFIED'}
    try:
        resolver = checked_file(project, 'engine/overworld/region_map_lookup.asm').decode('utf-8')
        headers = checked_file(project, 'data/johto_map_headers.asm').decode('utf-8')
        if 'SyncLegacyMapRegions::' in resolver and 'LegacyMapIDToRegionKey::' in resolver:
            readiness['native_region_map_paths'] = 'LEGACY_COMPATIBILITY_ONLY'
        if 'JohtoMapHeaderPointers::' in headers and 'JohtoMapLegacyAliases::' in headers:
            readiness['bulk_map_registration'] = 'REFERENCE_MAPS_ONLY'
    except (OSError, ValueError):
        problems.append(diagnostic('engine_source_not_readable', '', 'WARNING'))
    return make_result(map_results, problems, readiness, {'source_maps': len(inventories)})


def make_result(rows, problems, readiness, extras):
    failures = sum(x.get('static_status') == 'FAIL' for x in rows)
    reviews = sum(x.get('static_status') == 'REVIEW' for x in rows)
    passes = sum(x.get('static_status') == 'PASS' for x in rows)
    fatal = sum(x['level'] == 'ERROR' for x in problems)
    groups = {}
    for row in rows:
        k = row['tileset']
        group = groups.setdefault(k, {'maps': 0, 'static_pass': 0, 'static_review': 0,
                                      'static_fail': 0, 'tileset_adapter': 'UNVERIFIED'})
        group['maps'] += 1
        group['static_' + row['static_status'].lower()] += 1
        if k == 'TILESET_JOHTO':
            group['tileset_adapter'] = 'OFFLINE_TERRAIN_ONLY'
    result = {'schema': 'rpp-johto-validation-v1',
              'mode': 'READ_ONLY_STATIC_AUDIT',
              'status': 'FAILED' if failures or fatal else 'OFFLINE_REVIEW_ONLY',
              'notes': ['PASS only verifies staged byte/metadata integrity, not collision semantics.',
                        'No new maps are registered, built, or emulator tested by this auditor.'],
              'summary': {'maps': len(rows), 'static_pass': passes,
                          'static_review': reviews, 'static_fail': failures,
                          'global_errors': fatal, **extras},
              'readiness': readiness, 'tileset_coverage': dict(sorted(groups.items())), 'problems': problems,
              'maps': [{**row, 'events': dict(row['events'])} for row in rows]}
    return result



def render_previews(output, gold, project, result, limit=12):
    """Draw byte-layout side-by-side previews; never claim Gold palette parity.

    Previews show the RPP Johto tile artwork for BOTH original and candidate
    maps. Thus they help diagnose geometry, but do not certify Gold artwork.
    """
    if limit == 0:
        return
    from PIL import Image, ImageDraw
    previews = output / 'verification' / 'previews'
    if output.is_symlink() or (output / 'verification').is_symlink() or previews.is_symlink():
        raise ValueError('refusing symlinked preview directory')
    previews.mkdir(parents=True, exist_ok=True)
    for stale in previews.glob('*.png'):
        if stale.is_symlink():
            raise ValueError('symlinked preview: ' + str(stale))
        stale.unlink()
    try:
        tiles = Image.open(project / 'gfx/tilesets/johto.png').convert('RGB')
        candidate_tiles = Image.open(output / 'johto_tileset_candidate.png').convert('RGB')
        if tiles.size != (128, 48) or candidate_tiles.size != (128, 48):
            raise ValueError('unexpected Johto tile image dimensions')
        original_blocks = checked_file(gold, 'data/tilesets/johto_metatiles.bin')
        candidate_blocks = checked_file(output, 'johto_blockset_candidate.bst')
    except (OSError, ValueError) as exc:
        result['problems'].append(diagnostic('preview_resources_unavailable', exc, 'WARNING'))
        return
    # Two references plus up to `limit` staged candidates selected across
    # representative statuses. This is a preview, not a per-map manual gate.
    selected = [r for r in result['maps'] if r['tileset'] == 'TILESET_JOHTO'
                and r['candidate'] and r['stage_status'] != 'blocked']
    rank = {'reference_preserved': 0, 'review_required': 1, 'candidate': 2}
    selected.sort(key=lambda r: (rank.get(r['stage_status'], 9), r['name']))
    for row in selected[:limit if limit > 0 else len(selected)]:
        name = row['name']
        w, h = row['dimensions']
        if not w or not h or w * h > 8192:
            result['problems'].append(diagnostic('preview_size_skipped', name, 'WARNING'))
            continue
        try:
            original = checked_file(output, f'original_maps/{name}.blk')
            candidate = checked_file(output, f'candidate_maps/{name}.blk')
            if len(original) != w * h or len(candidate) != w * h:
                continue
            def paint(layout, blocks, atlas):
                canvas = Image.new('RGB', (w * 32, h * 32), '#ffffff')
                for block_i, block_id in enumerate(layout):
                    data = blocks[block_id * 16:block_id * 16 + 16]
                    if len(data) < 16:
                        raise ValueError('invalid block index in render')
                    px, py = block_i % w * 32, block_i // w * 32
                    for i, tile in enumerate(data):
                        x, y = (tile % 16) * 8, (tile // 16) * 8
                        if y + 8 > atlas.height:
                            raise ValueError('tile outside image atlas')
                        canvas.paste(atlas.crop((x, y, x+8, y+8)),
                                     (px + (i % 4) * 8, py + (i // 4) * 8))
                return canvas
            left = paint(original, original_blocks, tiles)
            right = paint(candidate, candidate_blocks, candidate_tiles)
            out = Image.new('RGB', (w * 64 + 16, h * 32 + 35), '#f1f5f9')
            out.paste(left, (0, 30))
            out.paste(right, (w * 32 + 16, 30))
            pen = ImageDraw.Draw(out)
            pen.text((8, 8), 'Original layout (RPP tile artwork)', fill='#111827')
            pen.text((w*32 + 22, 8), 'Staged candidate', fill='#111827')
            # Event locations as circles: cyan warp, orange object, purple sign.
            event_records = load_json(output, 'events_locations.json', []) or {}
            locs = event_records.get(name, {})
            for key, color in (('warps', '#06b6d4'), ('objects', '#f97316'),
                               ('signs', '#a855f7')):
                for item in locs.get(key, []):
                    x, y = item['x'] * 16 + w*32 + 16 + 8, item['y'] * 16 + 30 + 8
                    if w*32+16 <= x < w*64+16 and 30 <= y < h*32+30:
                        pen.ellipse((x-5, y-5, x+5, y+5), fill=color, outline='black', width=1)
            if out.width > 1500:
                out.thumbnail((1500, 1500), Image.Resampling.NEAREST)
            file = previews / (name + '.png')
            out.save(file)
            row['preview'] = 'previews/' + file.name
        except (OSError, ValueError, IndexError) as exc:
            result['problems'].append(diagnostic('preview_failed', f'{name}: {exc}', 'WARNING'))


def write_reports(output, result):
    out = output / 'verification'
    if output.is_symlink():
        raise ValueError('refusing symlinked output root')
    if out.is_symlink():
        raise ValueError('refusing symlinked verification output')
    out.mkdir(exist_ok=True)
    for owned in ('verification.json', 'index.html'):
        if (out / owned).is_symlink():
            raise ValueError('refusing symlinked verification file: ' + owned)
    (out / 'verification.json').write_text(
        json.dumps(result, indent=2, ensure_ascii=False) + '\n', encoding='utf-8')
    def e(v):
        return escape(str(v), quote=True)
    counters = result['summary']
    parts = ['<!doctype html><html lang="zh-CN"><head><meta charset="utf-8">',
             '<meta name="viewport" content="width=device-width,initial-scale=1">',
             '<title>金银地图批量转换校验</title>',
             '<style>body{font:15px system-ui,sans-serif;max-width:1220px;margin:2em auto;padding:0 1em;color:#1b2530;background:#f8fafc}'
             'h1,h2{margin:1em 0 .5em}.box{background:white;border:1px solid #e2e8f0;border-radius:12px;padding:16px;margin-bottom:15px}'
             '.metrics{display:flex;gap:12px;flex-wrap:wrap}.metric{flex:1;min-width:125px;background:#edf2f7;padding:12px;border-radius:8px}'
             '.metric strong{font-size:24px;display:block}.tag{border-radius:5px;padding:3px 7px;font-weight:bold;font-size:12px}'
             '.PASS{background:#d1fae5}.FAIL{background:#fee2e2}.REVIEW{background:#fef3c7}'
             'table{border-collapse:collapse;width:100%;font-size:13px;background:white}th,td{border-bottom:1px solid #e5e7eb;text-align:left;padding:8px;vertical-align:top}'
             'th{position:sticky;top:0;background:#edf2f7}td:nth-child(5){max-width:390px;word-break:break-word}'
             'code{white-space:pre-wrap}a{color:#175c8e}</style></head><body>',
             '<h1>金银 → RPP 批量转换静态校验</h1>',
             '<div class="box"><p><strong>结果：'+ e(result['status']) + '</strong></p>',
             '<p>这里只检查离线文件完整性。通过 ≠ 游戏可运行，未执行 ROM 编译、模拟器测试或碰撞语义认证。</p>',
             '<div class="metrics">']
    for label, value in [('盘点地图', counters.get('maps', 0)), ('静态通过', counters.get('static_pass', 0)),
                         ('待复查', counters.get('static_review', 0)), ('静态失败', counters.get('static_fail', 0)),
                         ('全局错误', counters.get('global_errors', 0))]:
        parts.append(f'<div class="metric">{e(label)}<strong>{e(value)}</strong></div>')
    parts += ['</div></div><div class="box"><h2>接入关卡</h2>']
    for key, value in result['readiness'].items():
        parts.append(f'<div>{e(key)}：<strong>{e(value)}</strong></div>')
    parts += ['</div><div class="box"><h2>全局异常</h2>']
    if result['problems']:
        for p in result['problems']:
            parts.append(f'<p>{e(p["level"])} / {e(p["code"])}：{e(p["detail"])}</p>')
    else:
        parts.append('<p>未发现全局结构错误</p>')
    parts += ['</div><div class="box"><h2>按图块集汇总</h2><table><thead><tr><th>图块集</th><th>地图</th><th>静态通过</th><th>待复查</th><th>失败</th><th>可用适配能力</th></tr></thead><tbody>']
    for tileset, group in result['tileset_coverage'].items():
        parts.append('<tr>' + ''.join(f'<td>{e(v)}</td>' for v in
                     (tileset, group['maps'], group['static_pass'], group['static_review'],
                      group['static_fail'], group['tileset_adapter'])) + '</tr>')
    parts += ['</tbody></table></div><h2>地图清单</h2><table><thead><tr><th>地图</th><th>图块集</th><th>地形阶段</th>',
              '<th>静态检查</th><th>异常及证据</th><th>游戏运行</th></tr></thead><tbody>']
    for row in result['maps']:
        issues = '; '.join(f'{x["level"]}:{x["code"]}({x["detail"]})' for x in row['issues']) or '无'
        state = row['static_status']
        parts.append(f'<tr><td>{e(row["name"])}</td><td>{e(row["tileset"])}</td>'
                     f'<td>{e(row["stage_status"])}</td><td><span class="tag {e(state)}">{e(state)}</span></td>'
                     f'<td>{e(issues)}<div>图块对照：{e(row["tile_identity"])}</div>'
                     + (f'<div><a href="{e(row["preview"])}">查看地图对照图</a></div>' if row.get('preview') else '')
                     + '</td><td>未测试</td></tr>')
    parts.append('</tbody></table><p>机器可读明细：<a href="verification.json">verification.json</a></p></body></html>')
    (out/'index.html').write_text(''.join(parts), encoding='utf-8')


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--output', required=True, type=Path)
    parser.add_argument('--gold-root', required=True, type=Path)
    parser.add_argument('--gold-profile', choices=PROFILES, default='auto')
    parser.add_argument('--project', required=True, type=Path)
    parser.add_argument('--preview-limit', type=int, default=12, help='side-by-side map previews; 0 disables')
    args = parser.parse_args()
    gold = resolve_gold_root(args.gold_root, args.gold_profile)
    result = verify(args.output, gold, args.project)
    render_previews(args.output, gold, args.project, result, args.preview_limit)
    write_reports(args.output, result)
    print(json.dumps({**result['summary'], 'status': result['status']}, ensure_ascii=False))
    return 2 if result['status'] == 'FAILED' else 0


if __name__ == '__main__':
    raise SystemExit(main())
