"""REF-349 staging guard: exact Gold source; fail-closed negative controls."""
from pathlib import Path

from tools.johto_dark_cave_stage_349 import check, BLOCKS, EVENTS, CONTRACT

PROJECT = Path(__file__).resolve().parents[2]


def test_frozen_gold_with_staged_or_active_contract():
    assert check(PROJECT) == []


def test_corrupt_one_gold_block_is_detected():
    raw = bytearray((PROJECT / BLOCKS).read_bytes())
    raw[0] ^= 1
    assert check(PROJECT, overrides={BLOCKS: bytes(raw)})


def test_corrupt_warp_target_is_detected():
    s = (PROJECT / EVENTS).read_text()
    assert 'ROUTE_46, 3' in s
    assert check(PROJECT, overrides={EVENTS: s.replace('ROUTE_46, 3', 'ROUTE_46, 2')})


def test_stage2_manifest_flag_drift_is_rejected():
    s = (PROJECT / CONTRACT).read_text()
    assert check(PROJECT, overrides={CONTRACT: s.replace('"route31_entry": true', '"route31_entry": false')})


def test_flash_palette_must_not_be_reclassified_as_fixed_nite():
    s = (PROJECT / CONTRACT).read_text()
    assert check(PROJECT, overrides={CONTRACT: s.replace('PALETTE_DARK', 'PALETTE_NITE')})
