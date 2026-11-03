"""DEV-337 negative/source regression for Gold healing machine and movement."""
from pathlib import Path
import sys
import shutil
import tempfile
import unittest
sys.path.insert(0,str(Path(__file__).resolve().parents[1]))
from johto_pokecenter_337_audit import audit

ROOT=Path(__file__).resolve().parents[2]
FILES=(
    'engine/johto_gold_healing_machine_337.asm', 'main.asm',
    'engine/overworld/pokecenter.asm', 'engine/overworld/healing_machine.asm',
    'engine/johto_pilot_runtime.asm','engine/johto_land_collision_gateway_272.asm',
    'engine/town_map.asm', 'engine/johto_pilot_fly_map.asm',
    'data/game_version.asm', 'gfx/johto_gold_heal_machine.png',
)

class GoldCenter337(unittest.TestCase):
    def setUp(self):
        t=tempfile.TemporaryDirectory();self.addCleanup(t.cleanup)
        self.root=Path(t.name)
        for rel in FILES:
            dest=self.root/rel;dest.parent.mkdir(parents=True,exist_ok=True)
            shutil.copy2(ROOT/rel,dest)

    def mutate(self,rel,old,new,failure):
        p=self.root/rel;s=p.read_text();self.assertIn(old,s)
        p.write_text(s.replace(old,new,1))
        self.assertIn(failure,audit(self.root)['errors'])

    def test_valid_source(self):
        r=audit(self.root)
        self.assertEqual(r['status'],'PASS_STATIC_ONLY',r)
        self.assertEqual(len(r['checks']),13)
        self.assertFalse(r['rom_built']);self.assertFalse(r['runtime_frame_profiled'])

    def test_gold_png_must_remain_original(self):
        p=self.root/'gfx/johto_gold_heal_machine.png'
        d=bytearray(p.read_bytes());d[-6]^=1;p.write_bytes(d)
        self.assertIn('gold_machine_png_exact_gold_source',audit(self.root)['errors'])

    def test_do_not_place_healing_machine_in_rom0(self):
        self.mutate('main.asm', 'SECTION "Johto Gold Healing Machine 337", ROMX',
                    'SECTION "Johto Gold Healing Machine 337", ROM0',
                    'gold_machine_floating_romx_not_rom0')

    def test_kanto_animation_must_remain_separate(self):
        self.mutate('engine/johto_gold_healing_machine_337.asm',
                    '.kanto\n    callba AnimateHealingMachine',
                    '.kanto\n    callba AnimateHealingMachineRegional337',
                    'kanto_healing_machine_stays_independent')

    def test_dead_kanto_johto_writer_stays_removed(self):
        self.mutate('engine/overworld/healing_machine.asm',
                    'jp UpdateSprites',
                    'callab JohtoRecordSuccessfulCenterHeal335\n\tjp UpdateSprites',
                    'kanto_healing_machine_stays_independent')

    def test_no_heal_animation_when_no(self):
        self.mutate('engine/overworld/pokecenter.asm',
                    'jr nz, .declinedHealing', 'jr z, .declinedHealing',
                    'yes_only_nurse_dispatches_regional_animation')

    def test_never_show_gold_graphics_outside_johto_room(self):
        self.mutate('engine/johto_gold_healing_machine_337.asm',
                    'cp JOHTO_CHERRYGROVE_POKECENTER_1F_LOCAL_ID',
                    'cp JOHTO_CHERRYGROVE_LOCAL_ID',
                    'gold_animation_requires_map_and_center_id')

    def test_wrong_graphic_length(self):
        self.mutate('engine/johto_gold_healing_machine_337.asm',
                    'BANK(JohtoGoldHealMachineGFX337), 2',
                    'BANK(JohtoGoldHealMachineGFX337), 3',
                    'gold_uses_exact_two_tile_asset_and_oam_placement')

    def test_wrong_oam_xy(self):
        self.mutate('engine/johto_gold_healing_machine_337.asm',
                    'db 38, 32, $fd, $14','db 38, 48, $fd, $14',
                    'gold_uses_exact_two_tile_asset_and_oam_placement')

    def test_no_heal_stamp_before_finish(self):
        self.mutate('engine/johto_gold_healing_machine_337.asm',
                    'call WaitForSongToFinish', 'call Delay3',
                    'stamp_only_after_song_and_sprite_restore')

    def test_id_stamp_must_match_valid_room(self):
        self.mutate('engine/johto_gold_healing_machine_337.asm',
                    'ld a, JOHTO_CHERRYGROVE_POKECENTER_1F_LOCAL_ID\n    ld [wJohtoLastHealLocalID], a',
                    'ld a, JOHTO_CHERRYGROVE_LOCAL_ID\n    ld [wJohtoLastHealLocalID], a',
                    'stamp_only_after_song_and_sprite_restore')

    def test_town_start_must_not_ignore_saved_heal(self):
        self.mutate('engine/johto_pilot_runtime.asm',
                    'cp JOHTO_LAST_HEAL_MAGIC','cp $00',
                    'town_start_reads_saved_heal_and_fallback')

    def test_fly_must_not_stamp_new_treatment_point(self):
        p=self.root/'engine/johto_pilot_fly_map.asm'
        p.write_text(p.read_text()+'\n    ld [wJohtoLastHealMagic], a\n')
        self.assertIn('fly_does_not_overwrite_saved_heal',audit(self.root)['errors'])

    def test_bounds_must_be_first(self):
        self.mutate('engine/johto_pilot_runtime.asm',
                    'cp JOHTO_CHERRYGROVE_POKECENTER_1F_LOCAL_ID\n    jp z, .verticalGateClosedEdge314',
                    'cp JOHTO_CHERRYGROVE_POKECENTER_1F_LOCAL_ID\n    jp z, .city',
                    'center_edge_fastpath_keeps_finite_guard')

    def test_outdoor_door_dispatch_skipped(self):
        self.mutate('engine/johto_pilot_runtime.asm',
                    'cp JOHTO_CHERRYGROVE_POKECENTER_1F_LOCAL_ID\n    ret z',
                    'cp JOHTO_CHERRYGROVE_POKECENTER_1F_LOCAL_ID\n    ret nz',
                    'center_skips_outdoor_door_router')

    def test_no_outdoor_role_grid_in_center(self):
        self.mutate('engine/johto_land_collision_gateway_272.asm',
                    'cp JOHTO_CHERRYGROVE_POKECENTER_1F_LOCAL_ID\n    ret z',
                    'cp JOHTO_CHERRYGROVE_POKECENTER_1F_LOCAL_ID\n    ret nz',
                    'center_skips_outdoor_role_dispatch_and_uses_legacy_collision')

if __name__ == '__main__':
    unittest.main()
