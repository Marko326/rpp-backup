"""Regression tests for JSON delivery exclusions and fail-closed source checks."""
import hashlib
import json
from pathlib import Path
import subprocess
import sys
from tempfile import TemporaryDirectory
import unittest

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
from johto_json_delivery_audit import audit, CANDIDATES, REQUIRED, ROOMS


class JsonDeliveryAuditTests(unittest.TestCase):
    def setUp(self):
        self.tmp = TemporaryDirectory()
        self.addCleanup(self.tmp.cleanup)
        self.root = Path(self.tmp.name)
        subprocess.run(["git", "init", "-q", str(self.root)], check=True)
        (self.root / ".gitignore").write_text("tools/cache/**/*.json\n", encoding="utf-8")
        jobs = [{"id": room} for room in ROOMS]
        self.write_json(REQUIRED[0], {"schema": "johto-indoor-batch-v2", "jobs": jobs})
        for room in ROOMS:
            rel = CANDIDATES / room / "provenance.json"
            file = rel.parent / "candidate.blk"
            self.write_bytes(file, room.encode())
            self.write_json(rel, {"candidate_status": "OFFLINE_ONLY_NEVER_REGISTERED",
                                  "dimensions_blocks": [4, 4], "compacted_source_ids": [1],
                                  "warps_gold_one_based": [], "npc_gold": [],
                                  "asset_sha256": {"candidate.blk": self.digest(room.encode())}})
        shared = CANDIDATES / "shared_gold_sprites/provenance.json"
        table = {}
        for i in range(8):
            data = bytes([i])
            self.write_bytes(shared.parent / f"sprite{i}.png", data)
            table[f"sprite{i}.png"] = self.digest(data)
        self.write_json(shared, {"sha256": table})
        entries = []
        for room, map_name in zip(ROOMS, ["JohtoOlivinePokecenter1F", "JohtoOlivineCafe", "JohtoOlivineMart"]):
            tileset = {"olivine_pokecenter_1f": "johto_olivine_pokecenter",
                       "olivine_cafe": "johto_olivine_cafe",
                       "olivine_mart": "johto_olivine_mart"}[room]
            paths = {
                "atlas": f"gfx/tilesets/{tileset}.png",
                "blockset": f"gfx/blocksets/{tileset}.bst",
                "tilecoll": f"gfx/tilesets/{tileset}.tilecoll",
                "palette": f"color/tilesets/{tileset}.asm",
            }
            hashes = {}
            for name, rel in paths.items():
                content = (name + room).encode()
                self.write_bytes(Path(rel), content)
                hashes[name] = self.digest(content)
            entries.append({"map": map_name, "tileset": tileset, "runtime_hashes": hashes})
        self.write_json(REQUIRED[-1], {"maps": entries})
        subprocess.run(["git", "-C", str(self.root), "add", "."], check=True)

    @staticmethod
    def digest(data):
        return hashlib.sha256(data).hexdigest()

    def write_bytes(self, rel, data):
        path = self.root / rel
        path.parent.mkdir(parents=True, exist_ok=True)
        path.write_bytes(data)

    def write_json(self, rel, data):
        self.write_bytes(rel, (json.dumps(data, ensure_ascii=False) + "\n").encode())

    def test_complete_tracked_jsons_pass(self):
        errors, notes = audit(self.root, require_tracked=True)
        self.assertEqual(errors, [])
        self.assertEqual(notes, [])

    def test_missing_source_fails(self):
        (self.root / REQUIRED[0]).unlink()
        errors, _ = audit(self.root)
        self.assertTrue(any("missing required source JSON" in e for e in errors), errors)

    def test_invalid_json_fails(self):
        self.write_bytes(REQUIRED[1], b'{broken json')
        errors, _ = audit(self.root)
        self.assertTrue(any("invalid source JSON" in e for e in errors), errors)

    def test_ignored_source_fails_even_if_tracked(self):
        (self.root / ".gitignore").write_text("*.json\n", encoding="utf-8")
        errors, _ = audit(self.root)
        self.assertTrue(any("source JSON is ignored" in e for e in errors), errors)

    def test_explicit_unignore_is_not_counted_as_ignored(self):
        rules = "*.json\n" + "".join(f"!{rel.as_posix()}\n" for rel in REQUIRED)
        (self.root / ".gitignore").write_text(rules, encoding="utf-8")
        errors, _ = audit(self.root, require_tracked=True)
        self.assertEqual(errors, [])

    def test_untracked_source_fails_in_delivery_mode(self):
        subprocess.run(["git", "-C", str(self.root), "rm", "--cached", "-q", "--", str(REQUIRED[0])], check=True)
        errors, _ = audit(self.root, require_tracked=True)
        self.assertTrue(any("not in Git index" in e for e in errors), errors)

    def test_tampered_candidate_fails(self):
        self.write_bytes(CANDIDATES / ROOMS[0] / "candidate.blk", b"tampered")
        errors, _ = audit(self.root)
        self.assertTrue(any("SHA-256 mismatch" in e for e in errors), errors)

    def test_tampered_runtime_fails(self):
        self.write_bytes(Path("gfx/tilesets/johto_olivine_cafe.png"), b"tampered")
        errors, _ = audit(self.root)
        self.assertTrue(any("SHA-256 mismatch" in e for e in errors), errors)


if __name__ == "__main__":
    unittest.main()
