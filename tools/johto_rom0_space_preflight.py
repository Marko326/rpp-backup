#!/usr/bin/env python3
"""Read-only preflight for ROM0-bound Johto Surf code and shared collision tables.

This is NOT a linker or exact free-space calculation. The included MAP may be
from a previous build and cannot certify the present source's linkability.
"""
from __future__ import annotations
import argparse
import json
import re
from pathlib import Path
try:
    from johto_surf_preflight import routine, shore_branch_valid, dispatcher_contract_ok
except ImportError:
    from tools.johto_surf_preflight import routine, shore_branch_valid, dispatcher_contract_ok

# Measured from the last user-submitted pre-relocation source, not a compiled ROM.
PREVIOUS_ROM0_INLINE_SURF_ESTIMATE = 196
MAX_ROM0_SURF_GATEWAY_BYTES = 40


def code_lines(source: str):
    for line in source.splitlines():
        code = line.split(';', 1)[0].strip()
        if code and not code.startswith('.'):
            yield code


def gateway_estimate(block: str) -> int:
    """Size precisely for the deliberately limited ROM0 Surf gateway subset."""
    a = block.find('callab JohtoOverworldSurfDecision')
    fallback = re.search(r'(?m)^\.legacySurfTile$', block[a:]) if a >= 0 else None
    if not fallback:
        raise ValueError('missing banked Surf call or legacy fallback label')
    b = a + fallback.start()
    size = 0
    for code in code_lines(block[a:b]):
        op = code.split(maxsplit=1)[0]
        if op == 'callab':
            size += 6  # ld hl,imm16; ld b,imm8; rst $18
        elif op == 'jp':
            size += 3
        elif op == 'jr':
            size += 2
        elif code == 'ld c, a':
            size += 1
        elif code.startswith('ld a, ['):
            size += 3
        else:
            raise ValueError('unmeasured new instruction in ROM0 Surf gateway: ' + code)
    return size


def inspect(project: Path, require_fresh_map: bool = False, minimum_rom0_slack: int = 64) -> dict:
    project = Path(project)
    issues = []
    warnings = []
    metrics = {}
    files = ('home/overworld.asm', 'home.asm', 'main.asm',
             'engine/johto_violet_field_skills.asm', 'macros/asm_macros.asm')
    try:
        sources = {name: (project/name).read_text(encoding='utf8') for name in files}
    except OSError as exc:
        return {'status': 'FAIL', 'issues': [str(exc)], 'warnings': [], 'metrics': {}}
    overworld = sources['home/overworld.asm']
    try:
        block = routine(overworld, 'CollisionCheckOnWater')
        current_size = gateway_estimate(block)
        metrics['rom0_gateway_bytes'] = current_size
        metrics['previous_inline_bytes_estimate'] = PREVIOUS_ROM0_INLINE_SURF_ESTIMATE
        metrics['estimated_rom0_bytes_released'] = PREVIOUS_ROM0_INLINE_SURF_ESTIMATE - current_size
        if current_size > MAX_ROM0_SURF_GATEWAY_BYTES:
            issues.append(f'ROM0 Surf gateway grew to {current_size} bytes (limit {MAX_ROM0_SURF_GATEWAY_BYTES})')
        if not shore_branch_valid(overworld, 'JohtoOverworldSurfDecision'):
            issues.append('ROM0 Surf branch/shore C register restore or C/Z routing is wrong')
        if any(re.search(r'\bcallab Johto\w+WaterAhead\b', line) for line in block.splitlines()):
            issues.append('old inline ROM0 Johto Surf water calls reintroduced')
    except ValueError as exc:
        issues.append(str(exc))
    main = sources['main.asm']
    if not re.search(r'SECTION "Johto Violet Field Skills", ROMX, BANK\[\$48\]\s*\nINCLUDE "engine/johto_violet_field_skills.asm"', main):
        issues.append('banked Surf helper must remain in available fixed ROMX Bank $48')
    field = sources['engine/johto_violet_field_skills.asm']
    if not dispatcher_contract_ok(field):
        issues.append('banked Surf dispatcher four-way flag contract is incomplete')
    try:
        banked = routine(field, 'JohtoOverworldSurfDecision')
        for name in ('Violet', 'NewBark', 'Cherrygrove', 'Route30', 'Route31', 'Route32', 'Ruins', 'UnionCave'):
            if not re.search(rf'(?m)^call Johto{name}WaterAhead$', banked):
                issues.append(f'banked Surf dispatcher missing Gold water check: {name}')
        if not re.search(r'(?m)^call JohtoCherrygroveShoreFloorAhead$', banked):
            issues.append('banked Surf dispatcher missing Cherrygrove shore FLOOR exception')
        if not re.search(r'(?m)^cp JOHTO_PILOT$', banked) or not re.search(r'(?m)^cp MAP_REGION_JOHTO$',banked):
            issues.append('banked Surf dispatcher missing tileset/region guards')
    except ValueError as exc:
        issues.append(str(exc))
    home = sources['home.asm']
    for name, path, size in (('JohtoPilot_Coll','johto.tilecoll',8),
                             ('JohtoHouse_Coll','johto_house.tilecoll',4),
                             ('JohtoUnionCave_Coll','johto_union_cave.tilecoll',13)):
        if f'{name}:: INCBIN "gfx/tilesets/{path}"' not in home or f'ASSERT {name}End - {name} == {size}' not in home:
            issues.append(f'{name} must keep its {size} bytes of unbanked collision data in ROM0')
    wrapper = sources['macros/asm_macros.asm']
    if not re.search(r'callab: MACRO\s+ld hl, \\1\s+ld b, BANK\(\\1\)\s+rst \$18', wrapper):
        issues.append('callab no longer matches assessed ROM0 6-byte call ABI')
    if not re.search(r'Bankswitch::(?s:.*?)\.Return\s+pop bc\s+ld a,b\s+ld \[H_LOADEDROMBANK\],a\s+ld \[MBC1RomBank\],a\s+ret', home):
        issues.append('Bankswitch must preserve C/Z flags during bank restoration')
    # The attached MAP is a prior successful link, NOT a result from the
    # current sources. Detect its old local-label layout before trusting slack.
    map_path = project / 'patches/rppred.map'
    if map_path.exists():
        map_text = map_path.read_text(encoding='utf8', errors='replace')
        rom0 = re.search(r'ROM0 bank #0:(.*?)(?=ROMX bank #1:)', map_text, re.S)
        if rom0:
            old_labels = ('CollisionCheckOnWater.checkNewBarkSurf',
                          'CollisionCheckOnWater.checkRoute32Surf')
            new_label = 'CollisionCheckOnWater.johtoSurfNotWater'
            stale = (any(label in rom0.group(1) for label in old_labels)
                     or new_label not in rom0.group(1))
            metrics['rom0_map_is_from_new_dispatcher'] = not stale
            m = re.search(r'SLACK: \$([0-9a-fA-F]+)', rom0.group(1))
            if m:
                slack = int(m.group(1), 16)
                metrics['map_rom0_slack_bytes'] = slack
                if stale:
                    metrics['previous_map_rom0_slack_bytes'] = slack
                    warnings.append(f'old MAP ROM0 slack {slack} B is stale: no evidence of this source linking')
                elif slack < minimum_rom0_slack:
                    issues.append(f'fresh MAP ROM0 slack {slack} B below safety minimum {minimum_rom0_slack} B')
            elif require_fresh_map:
                issues.append('MAP has no parseable ROM0 SLACK')
            if stale and require_fresh_map:
                issues.append('MAP still contains pre-relocation ROM0 Surf labels; obtain a fresh user-side link')
        elif require_fresh_map:
            issues.append('MAP lacks ROM0 bank section')
    elif require_fresh_map:
        issues.append('no MAP supplied: user-side linking is required')
    warnings.append('STATIC ONLY: user-side rgblink + freshly generated MAP required for ROM0 capacity acceptance')
    return {'status':'PASS_STATIC_ONLY' if not issues else 'FAIL',
            'issues':issues,'warnings':warnings,'metrics':metrics}


def main() -> int:
    parser=argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--root', type=Path, default=Path.cwd())
    parser.add_argument('--require-fresh-map', action='store_true',
                        help='fail if MAP lacks the new ROM0 layout or has <64B slack; for owner build gate')
    args=parser.parse_args()
    result=inspect(args.root, require_fresh_map=args.require_fresh_map)
    print(json.dumps(result,ensure_ascii=False,indent=2))
    return 0 if result['status']=='PASS_STATIC_ONLY' else 1


if __name__=='__main__':
    raise SystemExit(main())
