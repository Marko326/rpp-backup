"""Future enabled Johto doors cannot silently avoid the reviewed door contract."""
from pathlib import Path
import shutil
import sys
from tempfile import TemporaryDirectory
import unittest

ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(ROOT / 'tools'))
from johto_door_onboarding_audit import audit, audit_warp_capabilities  # noqa: E402


class DoorOnboardingTests(unittest.TestCase):
    def setUp(self):
        self.gold = Path(__import__('os').environ['JOHTO_GOLD_SOURCE'])

    def test_existing_enabled_johto_warps_have_contracts(self):
        errors, tests = audit(ROOT, self.gold)
        self.assertEqual(errors, [])
        self.assertGreaterEqual(len(tests), 7)

    def test_unregistered_new_map_warp_is_rejected(self):
        with TemporaryDirectory() as tmp:
            fake = Path(tmp)
            (fake / 'data/mapObjects').mkdir(parents=True)
            (fake / 'tools').mkdir()
            shutil.copy2(ROOT / 'tools/johto_door_contracts.json', fake / 'tools')
            (fake / 'data/mapObjects/JohtoFutureGate.asm').write_text(
                'JohtoFutureGateObject:\n\tdb $05\n\tdb $01\n'
                '\tdb 5, 5, 0, JOHTO_ROUTE_32\n')
            errors, _ = audit(fake, self.gold)
            self.assertTrue(any('enabled Johto Warp lacks type/Gold/test contract:' in e
                                and 'JohtoFutureGate' in e for e in errors), errors)

    def test_existing_contract_count_drift_is_rejected(self):
        with TemporaryDirectory() as tmp:
            fake = Path(tmp)
            (fake / 'data/mapObjects').mkdir(parents=True)
            (fake / 'tools').mkdir()
            shutil.copy2(ROOT / 'tools/johto_door_contracts.json', fake / 'tools')
            for f in (ROOT / 'data/mapObjects').glob('Johto*.asm'):
                shutil.copy2(f, fake / 'data/mapObjects')
            f = fake / 'data/mapObjects/JohtoRoute32.asm'
            t = f.read_text()
            self.assertIn('\tdb $01 ; the original cave-mouth Warp', t)
            f.write_text(t.replace('\tdb $01 ; the original cave-mouth Warp',
                                   '\tdb $00 ; the original cave-mouth Warp', 1))
            errors, _ = audit(fake, self.gold)
            self.assertTrue(any('Johto Warp count/contract mismatch JohtoRoute32' in e
                                for e in errors), errors)


class WarpCapabilityStatusTests(unittest.TestCase):
    def test_native_warp_status_matches_active_route33(self):
        self.assertEqual(audit_warp_capabilities(ROOT), [])

    def test_forbidden_active_route33_warp_is_rejected(self):
        with TemporaryDirectory() as tmp:
            fake = Path(tmp)
            (fake / 'tools').mkdir()
            (fake / 'data/mapObjects').mkdir(parents=True)
            source = (ROOT / 'tools/johto_native_maps.json').read_text()
            import json
            manifest = json.loads(source)
            route = next(m for m in manifest['maps'] if m['local_id'] == 9)
            route['feature_status']['warp'] = 'FORBIDDEN'
            (fake / 'tools/johto_native_maps.json').write_text(json.dumps(manifest))
            shutil.copy2(ROOT / 'data/mapObjects/JohtoRoute33.asm', fake / 'data/mapObjects')
            self.assertTrue(any('JohtoRoute33 has active Warp' in e
                                for e in audit_warp_capabilities(fake)))
