#!/usr/bin/env python3
"""Fail-closed Gold mapgroup roof audit for *all registered* native Johto exteriors.

Read the Gold map registry, roofs.pal, roof image mappings and the RPP local map
registry each time. Do not maintain a second manually numbered list of routes.
No ROM build or mutation is performed. Only Gold daytime roof RGB is validated.
"""
import argparse
import json
import re
from pathlib import Path
from PIL import Image


def read(path):
    return path.read_text(encoding='utf-8')


def parse_gold(gold):
    src = read(gold/'data/maps/maps.asm')
    group_names = re.findall(r'(?m)^\s*dw\s+MapGroup_(\w+)\s*;\s*(\d+)\s*$', src)
    if len(group_names) != 26 or set(int(n) for _, n in group_names) != set(range(1,27)):
        raise ValueError('Gold map group pointer table must contain exactly 1..26')
    groups = {}
    for group_name, num in group_names:
        body = re.search(r'(?ms)^MapGroup_'+re.escape(group_name)+r':\s*\n(.*?)(?=^MapGroup_\w+:|\Z)', src)
        if body is None:
            raise ValueError('Gold group definition missing: '+group_name)
        for name, tileset, environment in re.findall(
            r'(?m)^\s*map\s+(\w+)\s*,\s*TILESET_(\w+)\s*,\s*(\w+)\s*,', body.group(1)):
            if name in groups:
                raise ValueError('duplicate Gold map: '+name)
            groups[name] = (int(num), tileset, environment)
    # Each numeric mapgroup selects one roof image family; some share one family.
    roof_src = read(gold/'data/maps/roofs.asm')
    roofs = {}
    rows = re.findall(r'(?m)^\s*db\s+(ROOF_\w+|-1)\s*;\s*(\d+)\b', roof_src)
    if len(rows) != 27 or {int(n) for _,n in rows} != set(range(27)):
        raise ValueError('Gold numbered roof group index table incomplete')
    for symbol, number in rows:
        roofs[int(number)] = None if symbol=='-1' else symbol[5:].lower()
    roof_rgbs = [tuple(int(x) for x in row) for row in re.findall(
        r'(?m)^\s*RGB\s+(\d+)\s*,\s*(\d+)\s*,\s*(\d+)', read(gold/'gfx/tilesets/roofs.pal'))]
    if len(roof_rgbs) < 27*4:
        raise ValueError('Gold roof RGB group palette table truncated')
    return groups, roofs, roof_rgbs


def roof_2bpp(path):
    with Image.open(path) as image:
        if image.size != (24,24):
            raise ValueError('Gold roof image is not 24x24: '+str(path))
        image = image.convert('L')
        values = list(image.tobytes())
    if not set(values) <= {0, 85, 170, 255}:
        raise ValueError('Gold roof image has non-indexed grayscale pixels: '+str(path))
    tiles = bytearray()
    for tile_y in range(3):
        for tile_x in range(3):
            for row in range(8):
                pixels = [(255-values[(tile_y*8+row)*24+tile_x*8+x])//85 for x in range(8)]
                tiles.extend((sum((c & 1) << (7-x) for x,c in enumerate(pixels)),
                              sum(((c >> 1) & 1) << (7-x) for x,c in enumerate(pixels))))
    return bytes(tiles)


def roof_table(src, start, end):
    body = src.split(start+':',1)
    if len(body) != 2:
        raise ValueError('missing table '+start)
    body = body[1].split(end+':',1)
    if len(body) != 2:
        raise ValueError('missing table terminator '+end)
    rows = re.findall(r'(?m)^\s*db\s+([^;\n]+)',body[0])
    parsed=[]
    for row in rows:
        for token in row.split(','):
            value = token.strip().replace('$','0x')
            if not re.fullmatch(r'0x[0-9a-fA-F]+|\d+',value):
                raise ValueError('non-numeric roof table value: '+token)
            parsed.append(None if int(value,0) == 255 else int(value,0))
    return parsed



def roof_selector_contract(src, families):
    """Fail closed on changes to the *executed* roof source/BANK selection.

    Families are in RPP local map-group order, but come from Gold roofs.asm.
    Unlike a label-presence search, this checks every dispatch branch, the two
    base-tileset fallbacks, matching source/BANK operands and success/failure
    exits. The accepted assembly shape is intentionally narrow: a refactor of
    this low-level routine must review/update the contract, not silently pass.
    """
    label = 'SelectGoldenrodRoofSource:'
    if src.count(label) != 1:
        return ['roof runtime selector missing or defined more than once']
    if 'new_bark' not in families:
        return ['roof runtime selector has no Gold new_bark base group']

    body = src.split(label, 1)[1]
    # Stop at the next global assembler label, if a future file adds one.
    next_global = re.search(r'(?m)^\s*[A-Za-z_]\w*::?\s*(?:;[^\n]*)?$', body)
    if next_global:
        body = body[:next_global.start()]
    # Strip comments and insignificant spacing, never instructions or labels.
    actual = [re.sub(r'\s+', '', line.split(';', 1)[0]).lower()
              for line in body.splitlines()]
    actual = [line for line in actual if line]

    expected = [
        'ld a,[wCurMapTileset]', 'cp JOHTO', 'jr z,.johtoTileset',
        'cp JOHTO_MODERN', 'jr nz,.no', '.johtoTileset',
        'ld a,[wCurRegion]', 'cp MAP_REGION_JOHTO', 'jr nz,.no',
        'ld a,[wCurLocalMapID]', 'cp NUM_JOHTO_MAPS', 'jr nc,.no',
        'ld e,a', 'ld d,0', 'ld hl,JohtoRoofGroupForLocalMap',
        'add hl,de', 'ld a,[hl]', 'cp $ff', 'jr z,.no',
    ]
    non_base = [(group, family) for group, family in enumerate(families)
                if family != 'new_bark']
    for group, family in non_base:
        expected += [f'cp {group}', f'jr z,.{family}']
    expected += [
        'ld a,[wCurMapTileset]', 'cp JOHTO_MODERN', 'jr z,.modernBase',
        'ld hl,NewBark_GFX + $0a * $10', 'ld a,BANK(NewBark_GFX)',
        'jr .yes', '.modernBase',
        'ld hl,JohtoModern_GFX + $0a * $10',
        'ld a,BANK(JohtoModern_GFX)', 'jr .yes',
    ]
    # Several Gold mapgroups may share one art family and jump to one label.
    unique_families = list(dict.fromkeys(family for _, family in non_base))
    for index, family in enumerate(unique_families):
        symbol = f'Johto{family.title().replace("_", "")}Roofs_GFX'
        expected += [f'.{family}', f'ld hl,{symbol}', f'ld a,BANK({symbol})']
        if index != len(unique_families) - 1:
            expected.append('jr .yes')
    expected += ['.yes', 'scf', 'ret', '.no', 'and a', 'ret']
    expected = [re.sub(r'\s+', '', line).lower() for line in expected]
    for i in range(max(len(actual), len(expected))):
        got = actual[i] if i < len(actual) else '<missing>'
        want = expected[i] if i < len(expected) else '<end-of-selector>'
        if got != want:
            return [f'roof runtime selector source/BANK/group dispatch mismatch at '
                    f'instruction {i + 1}: expected {want}, got {got}']
    return []


def audit(root: Path, gold: Path):
    errors=[]
    try:
        groups, roof_names, rgb = parse_gold(gold)
        maps = json.loads(read(root/'tools/johto_native_maps.json'))['maps']
        if not maps or sorted(row['local_id'] for row in maps) != list(range(len(maps))):
            raise ValueError('native map local IDs are not unique contiguous zero-based IDs')
        expected=[]
        observed_groups=[]
        families=[]
        for row in sorted(maps,key=lambda m: m['local_id']):
            header=row['header']
            if not re.fullmatch(r'[A-Za-z0-9_]+_h',header):
                raise ValueError('native map header syntax invalid: '+str(header))
            rpp_name=header[:-2]
            header_src=read(root/'data/mapHeaders'/f'{rpp_name}.asm')
            head = re.search(r'(?m)^'+re.escape(header)+r':\s*\n\s*db\s+(\w+)',header_src)
            if head is None:
                raise ValueError('map header tileset not found: '+header)
            if head.group(1) not in ('JOHTO','JOHTO_MODERN'):
                expected.append(None)
                continue
            gold_name=rpp_name.removeprefix('Johto')
            if gold_name not in groups:
                raise ValueError('Gold map registry does not contain outdoor '+gold_name)
            number, tileset, environment=groups[gold_name]
            if tileset not in ('JOHTO','JOHTO_MODERN') or environment not in ('ROUTE','TOWN'):
                raise ValueError(f'{gold_name} is not a Gold Johto exterior')
            family=roof_names.get(number)
            if not family:
                # Some Gold outdoor mapgroups (e.g. Ruins) intentionally have
                # no roof PNG. Require the executable tables to use $ff.
                expected.append(None)
                continue
            if number not in observed_groups:
                observed_groups.append(number)
                families.append(family)
            expected.append(observed_groups.index(number))
        color_src=read(root/'color/loadpalettes.asm')
        gfx_src=read(root/'engine/overworld/johto_goldenrod_roof_gfx.asm')
        errors.extend(roof_selector_contract(gfx_src, families))
        for name,source,begin,end in (
            ('palette',color_src,'JohtoGoldDayRoofGroups','JohtoGoldDayRoofGroupsEnd'),
            ('graphics',gfx_src,'JohtoRoofGroupForLocalMap','JohtoRoofGroupForLocalMapEnd')):
            actual=roof_table(source,begin,end)
            if actual != expected:
                errors.append(f'{name} roof local-ID table differs from Gold mapgroups: expected {expected}; got {actual}')
            if f'ASSERT {end} - {begin} == NUM_JOHTO_MAPS' not in source:
                errors.append(f'{name} missing map-count assembler ASSERT')
        # Gold RGB for a roof group uses two center colors; light and dark are shared.
        pal_section=color_src.split('JohtoGoldDayRoofPalettes:',1)
        if len(pal_section)!=2 or 'JohtoGoldDayRoofPalettesEnd:' not in pal_section[1]:
            errors.append('missing Gold daytime roof palette table')
        else:
            section=pal_section[1].split('JohtoGoldDayRoofPalettesEnd:',1)[0]
            actual_rgbs=[tuple(int(x) for x in row) for row in re.findall(
                r'(?m)^\s*RGB\s+(\d+)\s*,\s*(\d+)\s*,\s*(\d+)',section)]
            expected_rgbs=[]
            for number in observed_groups:
                expected_rgbs += [(27,31,27),*rgb[4*number:4*number+2],(7,7,7)]
            if actual_rgbs != expected_rgbs:
                errors.append('Gold roof RGB5 differs from registered mapgroup palettes')
            if f'ASSERT JohtoGoldDayRoofPalettesEnd - JohtoGoldDayRoofPalettes == {len(observed_groups)} * 8' not in color_src:
                errors.append('Gold roof palette size ASSERT does not match active group count')
        # Every distinct non-base Gold roof art must have its true 9 tiles.
        for family in set(families):
            original=roof_2bpp(gold/'gfx/tilesets/roofs'/f'{family}.png')
            if family=='new_bark':
                for tileset in ('johto','johto_modern'):
                    with Image.open(root/'gfx/tilesets'/f'{tileset}.png') as image:
                        # RPP tileset graphics are arranged 16 columns x 8 px per tile.
                        gray=image.convert('L')
                        pixels=gray.load()
                        buf=bytearray()
                        for tile in range(10,19):
                            for y in range(8):
                                p=[(255-pixels[(tile%16)*8+x,(tile//16)*8+y])//85 for x in range(8)]
                                buf.extend((sum((v&1)<<(7-x) for x,v in enumerate(p)),
                                            sum(((v>>1)&1)<<(7-x) for x,v in enumerate(p))))
                    if bytes(buf)!=original:
                        errors.append(f'{tileset} base roof graphics differ from Gold new_bark')
            else:
                # Check the *tracked* image source, not a disposable build output.
                # `make clean` deletes all .2bpp; auditing must still work then.
                path=root/'gfx/tilesets'/f'johto_{family}_roofs.png'
                if not path.is_file() or roof_2bpp(path)!=original:
                    errors.append(f'{family} rooftop PNG differs from Gold 9-tile art or missing')
                if f'Johto{family.title().replace("_", "")}Roofs_GFX' not in gfx_src:
                    errors.append(f'{family} group missing roof source selector')
        makefile=read(root/'Makefile')
        rule='gfx/tilesets/johto_%_roofs.2bpp: gfx/tilesets/johto_%_roofs.png\n\t$(RGBGFX) -o $@ $<'
        if rule not in makefile or '-eq 144' not in makefile:
            errors.append('roof PNG-to-2bpp Makefile rule is missing, trims tiles or lacks 9-tile size guard')
        asm=read(root/'main.asm')
        for family in set(families)-{'new_bark'}:
            source=f'INCBIN "gfx/tilesets/johto_{family}_roofs.2bpp"'
            if source not in asm:
                errors.append(f'{family} runtime roof INCBIN missing')
        world=read(root/'home/overworld.asm')
        for hook in ('PatchGoldenrodRoofOnConnection','PatchGoldenrodRoofAfterTilesetLoad'):
            if world.count('callba '+hook)!=1:
                errors.append(f'roof full-load or connection hook missing/duplicated: {hook}')
        for critical in ('cp MAP_REGION_JOHTO','cp NUM_JOHTO_MAPS','cp $ff'):
            if critical not in gfx_src or critical not in color_src:
                errors.append('roof map safety guard missing: '+critical)
        if 'CopyVideoData' not in gfx_src or 'FarCopyData2' not in gfx_src:
            errors.append('roof graphics must cover connection and complete map load')
        return errors
    except (OSError, ValueError, KeyError, json.JSONDecodeError) as exc:
        return [str(exc)]


def main():
    p=argparse.ArgumentParser(description=__doc__)
    p.add_argument('--rpp',type=Path,required=True)
    p.add_argument('--gold',type=Path,required=True)
    args=p.parse_args()
    errors=audit(args.rpp,args.gold)
    print(json.dumps({'status':'FAIL' if errors else 'PASS','errors':errors,
                      'build_performed':False},ensure_ascii=False,indent=2))
    return int(bool(errors))


if __name__=='__main__':
    raise SystemExit(main())
