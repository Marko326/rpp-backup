from pathlib import Path
import itertools

from tools.johto_ice_path_save_flag_audit_369b import audit, B1, B2, EVENTS, WRAM

ROOT = Path(__file__).resolve().parents[2]


def test_ref369b_save_flag_ownership_contract():
    assert audit(ROOT) == []


def test_pit_event_cannot_alias_fly_ecruteak():
    source = (ROOT / B1).read_text()
    bad = source.replace(
        'DEF JOHTO_ICE_PATH_PIT_FLAGS_369B EQU EVENT_JOHTO_ICE_PATH_PIT_1_FILLED / 8',
        'DEF JOHTO_ICE_PATH_PIT_FLAGS_369B EQU EVENT_JOHTO_FLY_ECRUTEAK / 8', 1)
    assert any('derive from their named events' in error or 'D855 Fly/Articuno' in error for error in audit(ROOT, {B1: bad}))


def test_source_stone_flags_cannot_alias_escape_anchor():
    source = (ROOT / B1).read_text()
    bad = source.replace(
        'DEF JOHTO_ICE_PATH_STONE_FLAGS_369B EQU EVENT_JOHTO_ICE_PATH_BOULDER_1_DROPPED / 8',
        'DEF JOHTO_ICE_PATH_STONE_FLAGS_369B EQU EVENT_9CA / 8', 1)
    assert any('derive from their named events' in error for error in audit(ROOT, {B1: bad}))


def test_migration_must_preserve_both_seafoam_bits():
    source = (ROOT / B1).read_text()
    bad = source.replace('and $c3 ; preserve Seafoam B2F bits 0..1; clear PIT bits 2..5',
                         'and $c1 ; preserve Seafoam B2F bits 0..1; clear PIT bits 2..5', 1)
    assert any('migration must preserve' in error for error in audit(ROOT, {B1: bad}))


def test_migration_must_preserve_ice_path_escape_anchor_bits():
    source = (ROOT / B1).read_text()
    bad = source.replace('and $0f ; preserve Seafoam B3F and Ice Path escape anchor bits 0..3',
                         'and $03 ; preserve Seafoam B3F and Ice Path escape anchor bits 0..3', 1)
    assert any('migration must preserve' in error for error in audit(ROOT, {B1: bad}))


def test_migration_must_not_write_d855():
    source = (ROOT / B1).read_text()
    bad = source.replace('ld [wEventFlags + JOHTO_ICE_PATH_STONE_FLAGS_369B], a',
                         'ld [wEventFlags + 138], a', 1)
    assert any('migration may write only D852/D853' in error for error in audit(ROOT, {B1: bad}))


def test_b1f_must_run_migration_before_replaying_stones():
    source = (ROOT / B1).read_text()
    bad = source.replace('    call JohtoIcePathInitializePitState369B\n', '', 1)
    assert any('B1F must run save migration' in error for error in audit(ROOT, {B1: bad}))


def test_b2f_must_run_migration_before_reading_landed_stones():
    source = (ROOT / B2).read_text()
    bad = source.replace('    callab JohtoIcePathInitializePitState369B\n', '', 1)
    assert any('B2F must run save migration' in error for error in audit(ROOT, {B2: bad}))


def test_event_address_comment_must_match_real_event_index():
    source = (ROOT / EVENTS).read_text()
    bad = source.replace('current 450, (D855, bit 0)', 'current 450, (D854, bit 0)', 1)
    assert any('event annotation' in error for error in audit(ROOT, {EVENTS: bad}))


def test_d855_fly_and_articuno_owners_must_remain_intact():
    source = (ROOT / EVENTS).read_text()
    bad = source.replace('EVENT_BEAT_ARTICUNO', 'EVENT_9D9', 1)
    assert any('EVENT_BEAT_ARTICUNO' in error or 'D855' in error for error in audit(ROOT, {EVENTS: bad}))


def test_event_array_must_not_be_resized():
    source = (ROOT / WRAM).read_text()
    bad = source.replace('wEventFlags:: ; d7cb\n\tds 139', 'wEventFlags:: ; d7cb\n\tds 140', 1)
    assert any('139-byte save layout' in error for error in audit(ROOT, {WRAM: bad}))


def migrate_once(d852: int, d853: int) -> tuple[int, int]:
    """Byte-level model of the documented one-time migration mask."""
    if d852 & 0xC0 == 0xC0:
        return d852, d853
    return ((d852 & 0x03) | 0xC0), (d853 & 0x0F)


def test_migration_model_exhaustively_preserves_unrelated_bits():
    # Exhaust all 65,536 pairs of old D852/D853 byte values.
    for d852, d853 in itertools.product(range(256), repeat=2):
        new852, new853 = migrate_once(d852, d853)
        if d852 & 0xC0 == 0xC0:
            assert (new852, new853) == (d852, d853)
        else:
            assert new852 & 0x03 == d852 & 0x03  # Seafoam B2F
            assert new852 & 0x3C == 0             # reset only four PIT flags
            assert new852 & 0xC0 == 0xC0         # mark migration complete
            assert new853 & 0x0F == d853 & 0x0F  # Seafoam B3F + escape anchors
            assert new853 & 0xF0 == 0             # reset only four source-rock bits


def test_migration_does_not_try_to_repair_ambiguous_legacy_d855():
    source = (ROOT / B1).read_text()
    migration = source.split('JohtoIcePathInitializePitState369B::', 1)[1].split(
        'JohtoIcePathB1FHideDropped369B::', 1)[0]
    active = '\n'.join(line.split(';', 1)[0] for line in migration.splitlines())
    assert 'D855' not in active
    assert 'wEventFlags + 138' not in active
    assert 'EVENT_JOHTO_FLY_' not in active
