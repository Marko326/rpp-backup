"""Shared, phase-safe validation for historical Johto source audits.

Earlier features remain testable on later milestones.  A later approved label
or map count is fine, but the *active* in-ROM label must be unique and must
match the canonical annotation if one is present.  Historical comments must
never satisfy a live-version gate.
"""
from __future__ import annotations
import re


def approved_phase(version_source: str, constants_source: str, minimum_maps: int,
                   minimum_ref: int = 312) -> bool:
    # Only match an actual db instruction, not a past REF-NNN@ comment.
    labels = re.findall(r'(?m)^\s*db\s+"([^"\n]+)"\s*(?:;[^\n]*)?$', version_source)
    if len(labels) != 1:
        return False
    version = re.fullmatch(r'REF-(\d{3})[A-Z]?@', labels[0])
    if version is None or int(version.group(1)) < minimum_ref:
        return False

    # Full source files document the canonical release.  Small synthetic
    # fixtures need not carry that comment, but a present one must agree.
    canonical = re.findall(r'Canonical project version REF-5\.62\.(\d+)\b', version_source)
    if len(canonical) > 1 or (canonical and int(canonical[0]) != int(version.group(1))):
        return False

    counts = re.findall(r'(?m)^DEF\s+NUM_JOHTO_ACTIVE_MAPS\s+EQU\s+(\d+)\b', constants_source)
    return len(counts) == 1 and int(counts[0]) >= minimum_maps
