"""DEV-332: source-level fault injection for ordinary/Fly/Nest menu flows."""
import shutil
import tempfile
import unittest
from pathlib import Path

try:
    from tools.johto_town_map_menu_audit_332 import audit
except ImportError:
    from johto_town_map_menu_audit_332 import audit

ROOT = Path(__file__).resolve().parents[2]
SOURCES = [
    "engine/town_map.asm",
    "engine/johto_pilot_town_map_browse.asm",
    "engine/johto_pilot_fly_map.asm",
]


class TownMapMenuAudit332Test(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.addCleanup(self.temp.cleanup)
        self.root = Path(self.temp.name)
        for file in SOURCES:
            dest = self.root / file
            dest.parent.mkdir(parents=True, exist_ok=True)
            shutil.copy2(ROOT / file, dest)

    def mutate(self, file, before, after):
        path = self.root / file
        source = path.read_text(encoding="utf-8")
        self.assertIn(before, source, f"mutated marker missing: {before!r}")
        path.write_text(source.replace(before, after, 1), encoding="utf-8")

    def assert_fails(self, needle):
        result = audit(self.root)
        self.assertEqual(result["status"], "FAIL", result)
        self.assertTrue(any(needle in e for e in result["errors"]), result["errors"])

    def test_known_good_last_heal_policy(self):
        result = audit(self.root)
        self.assertEqual(result["status"], "PASS_STATIC_ONLY", result)
        self.assertEqual(len(result["checks"]), 19)
        self.assertFalse(result["rom_built"])
        self.assertFalse(result["runtime_verified"])

    def test_ordinary_jotho_wrong_region_selector_is_caught(self):
        self.mutate("engine/town_map.asm", ".selectKantoTownMap\n\txor a", ".selectKantoTownMap\n\tld a, 1")
        self.assert_fails("ordinary_region_dispatch")

    def test_ordinary_initial_cross_bank_name_is_caught(self):
        self.mutate("engine/town_map.asm", "\tcall DrawJohtoPilotFlyPlayerMarker\n\tld de, wBuffer", "\tcall DrawJohtoPilotFlyPlayerMarker\n\tld de, wcd6d")
        self.assert_fails("ordinary_banked_name_and_marker")

    def test_ordinary_browse_cross_bank_name_is_caught(self):
        self.mutate("engine/town_map.asm", "\tld de, wBuffer\n.writeBrowseName", "\tld de, wcd6d\n.writeBrowseName")
        self.assert_fails("ordinary_banked_name_and_marker")

    def test_ordinary_menu_b_exit_missing_is_caught(self):
        self.mutate("engine/town_map.asm", "\tcall ExitTownMap\n\tret\n.pressedStart", "\tret\n.pressedStart")
        self.assert_fails("ordinary_input_exit")

    def test_johto_start_no_player_lookup_is_caught(self):
        self.mutate("engine/town_map.asm", "\tcallab JohtoPilotGetLastHealLandmarkOrPlayer\n\tld a, e", "\txor a\n\tld a, e")
        self.assert_fails("ordinary_johto_start_recenter")

    def test_ordinary_45_entry_wrap_corruption_is_caught(self):
        self.mutate("engine/town_map.asm", "\tcp JOHTO_TOWNMAP_LANDMARK_COUNT\n\tjr c, .storeUp", "\tcp 47\n\tjr c, .storeUp")
        self.assert_fails("ordinary_45_landmark_wrap")

    def test_fly_johto_incorrect_screen_axis_is_caught(self):
        self.mutate("engine/johto_pilot_fly_map.asm", "\tld a, 1\n\tld [wFlyLocationsAxis], a", "\txor a\n\tld [wFlyLocationsAxis], a")
        self.assert_fails("fly_johto_entry")

    def test_fly_cancel_button_routed_to_wrong_action_is_caught(self):
        self.mutate("engine/johto_pilot_fly_map.asm", "\tbit 1, b\n\tjp nz, .cancel", "\tbit 1, b\n\tjp nz, .accept")
        self.assert_fails("fly_input_and_cancel")

    def test_fly_start_without_unlock_guard_is_caught(self):
        self.mutate("engine/johto_pilot_fly_map.asm", "\tcall .isUnlocked\n\tjr z, .startRestore", "\tcall .isUnlocked\n\tjr nz, .startRestore")
        self.assert_fails("fly_start_last_heal_guard")

    def test_fly_start_missing_restore_on_miss_is_caught(self):
        self.mutate("engine/johto_pilot_fly_map.asm", "\tpop af\n\tld [wFlyLocationsAxis], a\n\tpop af", "\tpop af\n\tld [wWhichTownMapLocation], a\n\tpop af")
        self.assert_fails("fly_start_last_heal_guard")

    def test_fly_start_no_old_current_map_shortcut(self):
        self.mutate("engine/johto_pilot_fly_map.asm", "\tld a, [wJohtoLastHealLocalID]", "\tld a, [wCurLocalMapID]")
        self.assert_fails("fly_start_last_heal_guard")

    def test_fly_start_invalid_magic_cannot_pass(self):
        self.mutate("engine/johto_pilot_fly_map.asm", "\tcp JOHTO_LAST_HEAL_MAGIC", "\tcp 0")
        self.assert_fails("fly_start_last_heal_guard")

    def test_fly_start_wrong_room_id_cannot_pass(self):
        self.mutate("engine/johto_pilot_fly_map.asm", "\tcp JOHTO_CHERRYGROVE_POKECENTER_1F_LOCAL_ID", "\tcp JOHTO_CHERRYGROVE_LOCAL_ID")
        self.assert_fails("fly_start_last_heal_guard")

    def test_fly_start_wrong_fly_row_cannot_pass(self):
        self.mutate("engine/johto_pilot_fly_map.asm", "\tld a, 1 ; Cherrygrove City row", "\tld a, 7 ; Cherrygrove City row")
        self.assert_fails("fly_start_last_heal_guard")

    def test_fly_lake_special_locked_destination_is_caught(self):
        self.mutate("engine/johto_pilot_fly_map.asm", "\tcall .isUnlocked\n\tjr nz, .specialUnlocked", "\tcall .isUnlocked\n\tjr z, .specialUnlocked")
        self.assert_fails("fly_lake_special_axis_guard")

    def test_fly_special_return_cannot_bypass_visit_scan(self):
        self.mutate("engine/johto_pilot_fly_map.asm", "\tcall .findBackward\n\tjp .render\n.accept", "\tnop\n\tjp .render\n.accept")
        self.assert_fails("fly_special_to_city_returns")

    def test_fly_confirm_unlock_guard_removed_is_caught(self):
        self.mutate("engine/johto_pilot_fly_map.asm", ".accept\n\tcall .isUnlocked\n\tjp z, .input", ".accept\n\tcall .isUnlocked\n\tjp nz, .input")
        self.assert_fails("fly_accept_requires_unlock")

    def test_fly_traversal_skips_only_ten_rows_is_caught(self):
        self.mutate("engine/johto_pilot_fly_map.asm", ".findBackward\n\tld b, JOHTO_FLY_TOWN_COUNT", ".findBackward\n\tld b, 10")
        self.assert_fails("fly_locked_row_skip_both_directions")

    def test_fly_active_slot_guard_removed_is_caught(self):
        self.mutate("engine/johto_pilot_fly_map.asm", "\tcp JOHTO_INVALID_ACTIVE_SLOT\n\tpop hl\n\tjr z, .locked", "\tcp JOHTO_INVALID_ACTIVE_SLOT\n\tpop hl\n\tjr nz, .locked")
        self.assert_fails("fly_active_and_visit_flags")

    def test_fly_visit_event_guard_removed_is_caught(self):
        self.mutate("engine/johto_pilot_fly_map.asm", "\tand [hl]\n\tret\n.locked", "\tor [hl]\n\tret\n.locked")
        self.assert_fails("fly_active_and_visit_flags")

    def test_fly_dispatch_recheck_removed_is_caught(self):
        self.mutate("engine/johto_pilot_fly_map.asm", "\tand [hl]\n\tjp z, SoftReset", "\tand [hl]\n\tjp nz, SoftReset")
        self.assert_fails("fly_warp_rechecks_unlock")

    def test_fly_register_11th_row_deleted_is_caught(self):
        self.mutate("engine/johto_pilot_fly_map.asm", "\tdb JOHTO_BLACKTHORN_CITY_LOCAL_ID, EVENT_JOHTO_FLY_BLACKTHORN", "\t; disabled\n\t; db JOHTO_BLACKTHORN_CITY_LOCAL_ID, EVENT_JOHTO_FLY_BLACKTHORN")
        self.assert_fails("fly_11_registered_candidates")

    def test_lake_special_row_identity_corruption_is_caught(self):
        self.mutate("engine/johto_pilot_fly_map.asm", "	db JOHTO_LAKE_OF_RAGE_LOCAL_ID, EVENT_JOHTO_FLY_LAKE_OF_RAGE", "	db JOHTO_MAHOGANY_TOWN_LOCAL_ID, EVENT_JOHTO_FLY_LAKE_OF_RAGE")
        self.assert_fails("fly_11_registered_candidates")

    def test_nest_becomes_johto_without_data_is_caught(self):
        self.mutate("engine/town_map.asm", "LoadTownMap_Nest:\n\tld a, [hTilesetType]\n\tpush af\n\txor a", "LoadTownMap_Nest:\n\tld a, [hTilesetType]\n\tpush af\n\tld a, 1")
        self.assert_fails("nest_kanto_only_policy_unchanged")

    def test_kanto_special_axis_removed_is_caught(self):
        self.mutate("engine/town_map.asm", "\tcallab BuildSpecialFlyLocationsListFromCityAnchor", "\tcallab BuildFlyLocationsList")
        self.assert_fails("kanto_fly_special_axis_preserved")


if __name__ == "__main__":
    unittest.main()
