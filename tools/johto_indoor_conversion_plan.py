#!/usr/bin/env python3
"""Cross-check Gold->RPP art/collision/palette proposals against source evidence.

This is a review manifest, NOT an importable map or a collision patch.
Even a valid proposal cannot certify runtime warps, palettes, or collision.
"""
from __future__ import annotations

from pathlib import Path
from johto_indoor_common import ConversionError


def create_plan(art: dict, collision: dict, palette: dict, isolated: dict | None) -> dict:
    """Build a room-independent, deterministic, inspectable *proposal*.

    Pixel candidates are preserved, not chosen when ambiguous. The isolated
    compact tileset is a different target namespace from existing RPP IDs.
    """
    blocks = []
    collisions = {b['gold_block_id']: b for b in collision['blocks']}
    for entry in art['mapping']:
        source_id = entry['gold_block_id']
        evidence = collisions.get(source_id)
        if evidence is None:
            raise ConversionError(f'Gold block {source_id} 缺少碰撞证据')
        candidates = sorted(set(entry['rpp_candidates']))
        available = {c['rpp_block_id']: c for c in evidence['rpp_candidates']}
        if set(candidates) != set(available):
            raise ConversionError(f'Gold block {source_id} 图形/碰撞候选不一致')
        safe = [i for i in candidates if available[i]['all_ordinary_quadrants_match']]
        blocks.append({
            'gold_block_id': source_id,
            'count': entry['count'],
            'gold_pixel_sha': entry['gold_pixel_sha'],
            'gold_collision': list(evidence['gold_collision']),
            'rpp_pixel_exact_candidates': candidates,
            'rpp_collision_compatible_candidates': safe,
            'selected_rpp_block_id': None,
            'is_special': any(q not in ('FLOOR', 'WALL', 'COUNTER')
                              for q in evidence['gold_collision']),
        })
    if len(blocks) != art['used_unique_blocks']:
        raise ConversionError('Gold block 条目与统计数不一致')
    source_tiles = isolated['source_tile_ids'] if isolated is not None else []
    fixed_slots = palette['loader']['fixed_copy_8x8_slots']
    if len(source_tiles) > fixed_slots:
        raise ConversionError('候选图块超过已证实的加载窗口')
    tiles = [{'compact_tile_id': i, 'gold_tile_id': source_id,
              'requested_rpp_palette': None} for i, source_id in enumerate(source_tiles)]
    return {
        'schema': 'johto-indoor-conversion-plan-v1',
        'source_map': art['source_map'], 'gold_tileset': art['gold_tileset'],
        'rpp_tileset': art['rpp_tileset'],
        'gold_layout_sha256': art['gold_layout_sha256'],
        'dimensions_in_blocks': [art['width'], art['height']],
        'target_namespaces': ['EXISTING_RPP_BLOCK_ID', 'ISOLATED_COMPACT_BLOCK_ID'],
        'blocks': blocks, 'isolated_candidate': bool(isolated),
        'isolated_gold_block_ids': list(isolated['source_block_ids']) if isolated else [],
        'tiles': tiles,
        'fixed_loader_tile_slots': fixed_slots,
        'reference_palette_symbols': palette['existing_palette']['distinct_palette_symbols'],
        'palette_evidence_source': palette['existing_palette']['source'],
        'palette_mapping_approved': False,
        'collision_mapping_approved': False,
        'warp_behavior_approved': False,
        'import_allowed': False,
    }


def validate_plan(plan: dict, art: dict, collision: dict, palette: dict,
                  isolated: dict | None) -> dict:
    """Reject stale/tampered source mappings, ID collisions and invalid palettes.

    This is evidence consistency validation only, not permission to import.
    """
    expected = create_plan(art, collision, palette, isolated)
    errors = []
    if not isinstance(plan, dict) or set(plan) != set(expected):
        return {'schema': 'johto-indoor-plan-check-v1',
                'structural_valid': False, 'errors': ['PLAN_SCHEMA_MISMATCH'],
                'import_allowed': False, 'gameplay_tested': False}
    for key in expected:
        if key in ('blocks', 'tiles'):
            continue
        if plan[key] != expected[key]:
            errors.append(f'SOURCE_FACT_CHANGED:{key}')
    if not isinstance(plan['blocks'], list) or len(plan['blocks']) != len(expected['blocks']):
        errors.append('BLOCK_COVERAGE_INVALID')
    else:
        for old, new in zip(expected['blocks'], plan['blocks']):
            if not isinstance(new, dict) or set(old) != set(new):
                errors.append('BLOCK_SCHEMA_INVALID')
                continue
            for key in old:
                if key == 'selected_rpp_block_id':
                    selected = new[key]
                    if selected is not None and (type(selected) is not int or
                                                selected not in old['rpp_collision_compatible_candidates']):
                        errors.append(f'UNPROVEN_BLOCK_SELECTION:{old["gold_block_id"]}')
                elif new[key] != old[key]:
                    errors.append(f'BLOCK_SOURCE_FACT_CHANGED:{old["gold_block_id"]}:{key}')
    if not isinstance(plan['tiles'], list) or len(plan['tiles']) != len(expected['tiles']):
        errors.append('TILE_COVERAGE_INVALID')
    else:
        symbols = set(expected['reference_palette_symbols'])
        for old, new in zip(expected['tiles'], plan['tiles']):
            if not isinstance(new, dict) or set(old) != set(new):
                errors.append('TILE_SCHEMA_INVALID')
                continue
            for key in ('compact_tile_id', 'gold_tile_id'):
                if type(new[key]) is not int or new[key] != old[key]:
                    errors.append(f'TILE_SOURCE_FACT_CHANGED:{old["compact_tile_id"]}:{key}')
            selected = new['requested_rpp_palette']
            if selected is not None and (type(selected) is not str or selected not in symbols):
                errors.append(f'UNKNOWN_PALETTE:{old["compact_tile_id"]}')
    errors = sorted(set(errors))
    return {'schema': 'johto-indoor-plan-check-v1',
            'structural_valid': not errors, 'errors': errors,
            'block_selections_made': sum(isinstance(b, dict) and b.get('selected_rpp_block_id') is not None
                                         for b in plan['blocks']) if isinstance(plan['blocks'], list) else 0,
            'palette_selections_made': sum(isinstance(t, dict) and t.get('requested_rpp_palette') is not None
                                           for t in plan['tiles']) if isinstance(plan['tiles'], list) else 0,
            'import_allowed': False, 'gameplay_tested': False,
            'reason': 'Source-safe candidates alone cannot certify collision, runtime palette, door behavior or ROM integration'}
