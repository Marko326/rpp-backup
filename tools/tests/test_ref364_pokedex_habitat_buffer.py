"""REF-364: Pokédex wild-location buffer and one-hit-per-group regression.

Source/data-only verification, not a ROM build or device test.  The 30-byte
wBuffer must hold all recorded groups plus optional Route 20/Seafoam logical
locations and the trailing $ff.  Check both _HARD encounter branches; the
wild-mons table currently has no _RED/_BLUE conditional branches.
"""

from collections import Counter
from pathlib import Path
import re

import pytest

ROOT = Path(__file__).resolve().parents[2]
CAPACITY = 30
LOGICAL_EXTRA_MAX = 2


def source(name):
    return (ROOT / name).read_text(encoding="utf-8")


def active_lines(text, hard):
    """Read the supported encounter-table conditional grammar; reject additions."""
    branch = None
    for raw in text.splitlines():
        line = raw.split(";", 1)[0].strip()
        if not line:
            continue
        if line == "IF DEF(_HARD)":
            assert branch is None, "nested encounter condition needs explicit audit"
            branch = hard
        elif line == "ELSE":
            assert branch is not None
            branch = not branch
        elif line == "ENDC":
            assert branch is not None
            branch = None
        else:
            assert not re.match(r"^(IF|ELIF|REPT|INCLUDE|MACRO)\b", line), line
            if branch is None or branch:
                yield line
    assert branch is None, "unterminated encounter conditional"


def parse_encounters(hard):
    wild = source("data/wild_mons.asm")
    table_text = wild.split("WildDataTable:", 1)[1].split("\n\tdb $ff", 1)[0]
    maps = re.findall(r"^\s*wild_data\s+(\w+),\s*(\w+)\s*$", table_text, re.M)
    assert maps and len(set(map_id for map_id, _ in maps)) == len(maps)
    assert not re.search(r"^\s*(?:IF|ELSE|ENDC)\b", table_text, re.M)

    # Only source encounter files in the active WildDataTable INCLUDE list.
    included = re.findall(r'^INCLUDE "(data/wildPokemon/[^\"]+)"', wild, re.M)
    entries = {}
    for path in included:
        current = None
        values = []
        for line in active_lines(source(path), hard):
            label = re.fullmatch(r"([A-Za-z_]\w*):", line)
            if label:
                if current is not None:
                    entries[current] = decode_groups(values, path)
                current, values = label.group(1), []
                assert current not in entries
                continue
            operand = re.fullmatch(r"db\s+(.+)", line)
            assert operand and current is not None, (path, line)
            values.append(operand.group(1).strip())
        if current is not None:
            entries[current] = decode_groups(values, path)
    assert set(name for _, name in maps) <= set(entries), "unknown wild data pointer"
    return [(map_id, *entries[ptr]) for map_id, ptr in maps]


def decode_groups(values, path):
    groups = []
    i = 0
    for kind in ("land", "water"):
        assert i < len(values), (path, kind)
        rate = values[i]
        assert re.fullmatch(r"\$[0-9A-Fa-f]{2}", rate), (path, rate)
        i += 1
        if rate == "$00":
            groups.append(())
            continue
        assert i + 10 <= len(values), (path, kind, "truncated")
        slots = []
        for item in values[i : i + 10]:
            match = re.fullmatch(r"\d+\s*,\s*([A-Za-z_]\w*)", item)
            assert match, (path, kind, item)
            slots.append(match.group(1))
        groups.append(tuple(slots))
        i += 10
    assert i == len(values), (path, "trailing encounter bytes", values[i:])
    return groups


def habitat_records(data, species, dedupe):
    out = []
    for map_id, land, water in data:
        for slots in (land, water):
            if dedupe:
                if species in slots:
                    out.append(map_id)
            else:
                out.extend(map_id for mon in slots if mon == species)
    return out


def check_budget(record_count, logical_extra=LOGICAL_EXTRA_MAX):
    used = record_count + logical_extra + 1  # $ff list terminator
    assert used <= CAPACITY, f"Pokédex habitat wBuffer overflow: {used}>{CAPACITY}"
    return used


def test_scan_code_skips_remaining_slots_but_keeps_land_water_separate():
    asm = source("engine/items/items.asm")
    func = asm.split("\nCheckMapForMon:", 1)[1].split("\n; item-use bank.", 1)[0]
    func = "\n".join(line.split(";", 1)[0].strip() for line in func.splitlines() if line.split(";", 1)[0].strip())
    assert re.search(
        r"inc hl\s+ld b, \$a\s+\.loop\s+ld a, \[wd11e\]\s+cp \[hl\]\s+"
        r"jr nz, \.nextEntry\s+ld a, c\s+ld \[de\], a\s+inc de\s+"
        r"\.skipRemaining\s+inc hl\s+inc hl\s+dec b\s+"
        r"jr nz, \.skipRemaining\s+dec hl\s+ret\s+"
        r"\.nextEntry\s+inc hl\s+inc hl\s+dec b\s+jr nz, \.loop\s+"
        r"dec hl\s+ret",
        func,
    ), "first hit must skip to the next encounter rate without writing a second map ID"
    assert func.count("ld [de], a") == 1

    find = asm.split("\nFindWildLocationsOfMon:", 1)[1].split("\nCheckMapForMon:", 1)[0]
    assert find.count("call nz, CheckMapForMon") == 2
    assert re.search(r"call nz, CheckMapForMon\s*; land", find)
    assert re.search(r"call nz, CheckMapForMon\s*; water", find)
    assert re.search(r"ld a, \$ff\s*; list terminator\s+ld \[de\], a", find)
    assert "wBuffer::" in source("wram.asm")
    assert "Temporary storage area of 30 bytes" in source("wram.asm")


def test_source_scope_and_version():
    wild = source("data/wild_mons.asm")
    # _RED and _BLUE share the same Kanto habitat data in this REF snapshot.
    assert not re.search(r"\b(?:_RED|_BLUE)\b", wild)
    assert all(not re.search(r"\b(?:_RED|_BLUE)\b", source(path))
               for path in re.findall(r'^INCLUDE "(data/wildPokemon/[^\"]+)"', wild, re.M))
    assert 'db "REF-364@"' in source("data/game_version.asm")
    # Keep capacity checks where the logical second layer owns them.
    townmap = source("main.asm")
    assert "ld c, 29 ; keep one of wBuffer's 30 bytes reserved" in townmap


@pytest.mark.parametrize("hard", [False, True], ids=["normal", "hard"])
def test_all_species_keep_same_visible_locations_and_fit_buffer(hard):
    data = parse_encounters(hard)
    species = sorted({mon for _, land, water in data for slots in (land, water) for mon in slots})
    assert len(data) == 60 and species
    sizes = {}
    for mon in species:
        before = habitat_records(data, mon, dedupe=False)
        after = habitat_records(data, mon, dedupe=True)
        assert set(before) == set(after), (mon, "changed visible map ID set")
        assert len(after) <= len(before)
        check_budget(len(after))  # pessimistically reserve both extra logical nodes
        sizes[mon] = (len(before), len(after))
    assert sizes
    worst = max(sizes, key=lambda mon: sizes[mon][1])
    print(f"hard={hard}, max after={worst} {sizes[worst]}, max before={max(v[0] for v in sizes.values())}")


def test_duplicate_within_table_is_removed_not_other_sources():
    data = [("ONE", ("MON", "OTHER", "MON"), ("MON", "MON")),
            ("TWO", ("MON",), ())]
    assert habitat_records(data, "MON", True) == ["ONE", "ONE", "TWO"]
    assert habitat_records(data, "MON", False) == ["ONE"] * 4 + ["TWO"]


def test_future_over_capacity_encounter_data_is_rejected():
    # Injection: 28 distinct land groups + two logical markers + $ff = 31 bytes.
    sample = [(f"MAP_{i}", ("MON",), ()) for i in range(28)]
    with pytest.raises(AssertionError, match="wBuffer overflow"):
        check_budget(len(habitat_records(sample, "MON", True)))
