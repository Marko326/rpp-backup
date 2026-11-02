"""Milestone guards must be monotonic but reject accidental rollbacks."""
from pathlib import Path
import sys
sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
from johto_audit_phase import approved_phase


def test_later_release_keeps_valid_older_contract():
    assert approved_phase('db "REF-319@"', 'DEF NUM_JOHTO_ACTIVE_MAPS EQU 42', 26)
    assert approved_phase('db "REF-320@"', 'DEF NUM_JOHTO_ACTIVE_MAPS EQU 43', 28)


def test_downgrade_or_malformed_contract_rejected():
    assert not approved_phase('db "REF-311@"', 'DEF NUM_JOHTO_ACTIVE_MAPS EQU 42', 26)
    assert not approved_phase('db "REF-319@"', 'DEF NUM_JOHTO_ACTIVE_MAPS EQU 22', 26)
    assert not approved_phase('db "TEST-319@"', 'DEF NUM_JOHTO_ACTIVE_MAPS EQU 42', 26)
    assert not approved_phase('db "REF-X@"', 'DEF NUM_JOHTO_ACTIVE_MAPS EQU 42', 26)


def test_comment_cannot_spoof_live_version():
    constants = 'DEF NUM_JOHTO_ACTIVE_MAPS EQU 42'
    assert not approved_phase('; REF-319@ is old\ndb "REF-300@"', constants, 39)
    assert not approved_phase('db "REF-319@"\ndb "REF-300@"', constants, 39)
    assert not approved_phase('db "REF-319@"\ndb "TEST-319@"', constants, 39)
    assert not approved_phase('db "REF-319@"\n; Canonical project version REF-5.62.320', constants, 39)
    assert not approved_phase('db "REF-319@"\n; Canonical project version REF-5.62.318', constants, 39)
    assert not approved_phase('db "REF-319@"', constants + '\nDEF NUM_JOHTO_ACTIVE_MAPS EQU 1', 39)


def test_history_comments_and_canonical_label_are_allowed():
    src = ('; REF-310: historical release note\n'
           '; Canonical project version REF-5.62.319; one in-ROM label\n'
           '    db "REF-319@"\n')
    assert approved_phase(src, 'DEF NUM_JOHTO_ACTIVE_MAPS EQU 42', 39)
