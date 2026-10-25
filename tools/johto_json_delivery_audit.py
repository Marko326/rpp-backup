#!/usr/bin/env python3
"""Fail-closed check that Olivine source JSONs are exportable and usable.

Read-only: never creates, deletes, replaces or stages an existing JSON file.
Use --require-tracked before a Git/RPP delivery to catch ignored/untracked inputs.
"""
from __future__ import annotations

import argparse
import hashlib
import json
from pathlib import Path
import re
import subprocess


ROOMS = ("olivine_pokecenter_1f", "olivine_cafe", "olivine_mart")
CANDIDATES = Path("tools/olivine_public_candidates")
REQUIRED = (
    Path("tools/manifests/olivine_public_buildings_241.json"),
    *(CANDIDATES / room / "provenance.json" for room in ROOMS),
    CANDIDATES / "shared_gold_sprites/provenance.json",
    Path("tools/olivine_public_runtime_manifest.json"),
)
_SHA256 = re.compile(r"[0-9a-f]{64}\Z")


def _git(root: Path, *args: str) -> subprocess.CompletedProcess[str]:
    return subprocess.run(["git", "-C", str(root), *args],
                          text=True, capture_output=True, check=False)


def _hash_files(root: Path, directory: Path, hashes: dict, errors: list[str], label: str) -> None:
    if not isinstance(hashes, dict) or not hashes:
        errors.append(f"{label}: missing/non-object checksum table")
        return
    for filename, digest in hashes.items():
        if (not isinstance(filename, str) or Path(filename).name != filename or
                filename in ("", ".", "..") or not isinstance(digest, str) or
                not _SHA256.fullmatch(digest)):
            errors.append(f"{label}: invalid asset name/SHA-256")
            continue
        path = root / directory / filename
        if not path.is_file():
            errors.append(f"{label}: missing asset {directory / filename}")
        elif hashlib.sha256(path.read_bytes()).hexdigest() != digest:
            errors.append(f"{label}: SHA-256 mismatch {directory / filename}")


def audit(root: Path, require_tracked: bool = False) -> tuple[list[str], list[str]]:
    root = root.resolve()
    errors: list[str] = []
    notes: list[str] = []
    documents: dict[Path, dict] = {}
    git_available = _git(root, "rev-parse", "--is-inside-work-tree").returncode == 0
    if require_tracked and not git_available:
        errors.append("Git index unavailable: cannot prove JSON files are tracked")

    for rel in REQUIRED:
        path = root / rel
        if not path.is_file():
            errors.append(f"missing required source JSON: {rel}")
        else:
            try:
                content = json.loads(path.read_text(encoding="utf-8"))
                if not isinstance(content, dict):
                    raise ValueError("expected JSON object")
                documents[rel] = content
            except (OSError, UnicodeError, ValueError) as exc:
                errors.append(f"invalid source JSON {rel}: {exc}")

        if git_available:
            # --no-index reports the ignore rule even for already tracked files.
            ignore = _git(root, "check-ignore", "--no-index", "-v", "--", str(rel))
            if ignore.returncode == 0 and not ignore.stdout.split("\t", 1)[0].rsplit(":", 1)[-1].startswith("!"):
                errors.append(f"source JSON is ignored: {rel}: {ignore.stdout.strip()}")
            if require_tracked and _git(root, "ls-files", "--error-unmatch", "--", str(rel)).returncode != 0:
                errors.append(f"source JSON not in Git index: {rel}")
        elif not require_tracked:
            notes.append("No .git directory: tracked/ignored status cannot be independently verified")

    manifest_rel = REQUIRED[0]
    if manifest_rel in documents:
        manifest = documents[manifest_rel]
        jobs = manifest.get("jobs")
        if (manifest.get("schema") != "johto-indoor-batch-v2" or
                not isinstance(jobs, list) or
                {job.get("id") for job in jobs if isinstance(job, dict)} != set(ROOMS) or
                len(jobs) != len(ROOMS)):
            errors.append(f"{manifest_rel}: expected three distinct Olivine batch-v2 jobs")

    for room in ROOMS:
        rel = CANDIDATES / room / "provenance.json"
        if rel not in documents:
            continue
        value = documents[rel]
        if (value.get("candidate_status") != "OFFLINE_ONLY_NEVER_REGISTERED" or
                not isinstance(value.get("dimensions_blocks"), list) or
                len(value["dimensions_blocks"]) != 2 or
                not isinstance(value.get("compacted_source_ids"), list) or
                not isinstance(value.get("warps_gold_one_based"), list) or
                not isinstance(value.get("npc_gold"), list)):
            errors.append(f"{rel}: required source/provenance fields invalid")
        _hash_files(root, rel.parent, value.get("asset_sha256"), errors, str(rel))

    shared_rel = CANDIDATES / "shared_gold_sprites/provenance.json"
    if shared_rel in documents:
        hashes = documents[shared_rel].get("sha256")
        if not isinstance(hashes, dict) or len(hashes) != 8:
            errors.append(f"{shared_rel}: expected 8 verified source sprites")
        _hash_files(root, shared_rel.parent, hashes, errors, str(shared_rel))

    runtime_rel = REQUIRED[-1]
    if runtime_rel in documents:
        entries = documents[runtime_rel].get("maps")
        expected = {"JohtoOlivinePokecenter1F", "JohtoOlivineCafe", "JohtoOlivineMart"}
        if (not isinstance(entries, list) or len(entries) != 3 or
                {e.get("map") for e in entries if isinstance(e, dict)} != expected):
            errors.append(f"{runtime_rel}: expected three runtime map entries")
        else:
            for entry in entries:
                tileset = entry.get("tileset")
                hashes = entry.get("runtime_hashes")
                if not isinstance(tileset, str) or not re.fullmatch(r"johto_olivine_[a-z_]+", tileset):
                    errors.append(f"{runtime_rel}: unsafe/invalid tileset name")
                    continue
                if not isinstance(hashes, dict):
                    errors.append(f"{runtime_rel}: missing runtime hashes for {tileset}")
                    continue
                assets = {
                    "atlas": Path(f"gfx/tilesets/{tileset}.png"),
                    "blockset": Path(f"gfx/blocksets/{tileset}.bst"),
                    "tilecoll": Path(f"gfx/tilesets/{tileset}.tilecoll"),
                    "palette": Path(f"color/tilesets/{tileset}.asm"),
                }
                for kind, rel_asset in assets.items():
                    digest = hashes.get(kind)
                    if not isinstance(digest, str) or not _SHA256.fullmatch(digest):
                        errors.append(f"{runtime_rel}: invalid {kind} hash for {tileset}")
                    elif not (root / rel_asset).is_file():
                        errors.append(f"{runtime_rel}: missing {rel_asset}")
                    elif hashlib.sha256((root / rel_asset).read_bytes()).hexdigest() != digest:
                        errors.append(f"{runtime_rel}: SHA-256 mismatch {rel_asset}")

    # Avoid claiming a clean archive when Git is absent or the six JSONs are untracked.
    if not git_available and not require_tracked:
        notes = list(dict.fromkeys(notes))
    return errors, notes


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--rpp", type=Path, default=Path("."))
    parser.add_argument("--require-tracked", action="store_true",
                        help="also fail when required JSONs are not in the Git index")
    args = parser.parse_args()
    errors, notes = audit(args.rpp, args.require_tracked)
    for message in notes:
        print("WARN:", message)
    for message in errors:
        print("FAIL:", message)
    if errors:
        print(f"FAIL: JSON delivery check: {len(errors)} error(s)")
        return 1
    print("PASS: six required source JSONs and referenced source/runtime assets verified")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
