"""DEV-335 negative tests for the Gold 5x4 center and post-animation recovery."""
from pathlib import Path
import shutil, tempfile, unittest, sys
sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
from johto_pokecenter_335_audit import audit

ROOT=Path(__file__).resolve().parents[2]
FILES=[
'maps/johto_pilot/reference/johto_pokecenter_243.png',
'maps/johto_pilot/reference/johto_pokecenter_243.bst',
'maps/johto_pilot/reference/johto_pokecenter_243.blk',
'maps/johto_pilot/reference/johto_pokecenter_243.tilecoll',
'maps/johto_pilot/reference/johto_pokecenter_243_palette.asm',
'gfx/tilesets/johto_shared_pokecenter.png',
'gfx/tilesets/pokecenter.tilecoll',
'gfx/blocksets/johto_shared_pokecenter.bst',
'maps/johto_pilot/CherrygrovePokecenter1F.runtime.blk',
'maps/johto_pilot/CherrygrovePokecenter1F.gold.blk',
'color/tilesets/johto_shared_pokecenter.asm',
'color/data/map_palette_sets.asm','color/data/map_palette_assignments.asm','color/sprites.asm',
'engine/johto_shared_pokecenter.asm','engine/overworld/healing_machine.asm',
'engine/overworld/pokecenter.asm','engine/overworld/set_blackout_map.asm',
'engine/johto_gold_healing_machine_337.asm',
'engine/johto_pilot_runtime.asm','engine/town_map.asm','constants/tilesets.asm',
'data/tileset_headers.asm','main.asm','home.asm'
]
class GoldCenter335(unittest.TestCase):
    def setUp(self):
        tmp=tempfile.TemporaryDirectory();self.addCleanup(tmp.cleanup);self.root=Path(tmp.name)
        for f in FILES:
            p=self.root/f;p.parent.mkdir(parents=True,exist_ok=True);shutil.copy2(ROOT/f,p)
    def check_mutation(self,rel,old,new,expected):
        p=self.root/rel;s=p.read_text();self.assertIn(old,s);p.write_text(s.replace(old,new,1))
        self.assertIn(expected,audit(self.root)['errors'])
    def test_gold_reference_passes(self):
        x=audit(self.root);self.assertEqual(x['status'],'PASS_STATIC_ONLY',x)
        self.assertEqual(len(x['checks']),13)
    def test_corrupt_gold_blockset(self):
        p=self.root/'gfx/blocksets/johto_shared_pokecenter.bst';d=bytearray(p.read_bytes());d[0]=0xff;p.write_bytes(d)
        self.assertIn('full_blockset_reference_reindex',audit(self.root)['errors'])
    def test_corrupt_runtime_blk(self):
        p=self.root/'maps/johto_pilot/CherrygrovePokecenter1F.runtime.blk';d=bytearray(p.read_bytes());d[0]=3;p.write_bytes(d)
        self.assertIn('old_conversion_and_gold_5x4',audit(self.root)['errors'])
    def test_corrupt_gold_floor_passability(self):
        p=self.root/'gfx/tilesets/pokecenter.tilecoll';data=bytearray(p.read_bytes());data[0]=9;p.write_bytes(data)
        self.assertIn('every_room_tile_collision_equivalent',audit(self.root)['errors'])
    def test_corrupt_palette(self):
        self.check_mutation('color/tilesets/johto_shared_pokecenter.asm','RED, GRAY','WATER, GRAY','same_96_gold_palettes')
    def test_unregistered_tileset(self):
        self.check_mutation('data/tileset_headers.asm','JohtoSharedPokecenter_GFX, Pokecenter_Coll',
                            'JohtoSharedPokecenter_GFX, Gate_Coll','isolated_gold_tileset_37')
    def test_wrong_room_tileset(self):
        self.check_mutation('engine/johto_shared_pokecenter.asm','db JOHTO_POKECENTER','db POKECENTER','gold_runtime_room_and_warps')
    def test_nurse_yes_must_write_record(self):
        self.check_mutation('engine/johto_gold_healing_machine_337.asm','ld [wJohtoLastHealMagic], a',
                            'ld [wLastBlackoutMap], a','healing_yes_only_post_animation')
    def test_record_after_animation_not_before(self):
        self.check_mutation('engine/johto_gold_healing_machine_337.asm','call WaitForSongToFinish',
                            'call SomeOtherFunction','healing_yes_only_post_animation')
    def test_kanto_recovery_preserved(self):
        self.check_mutation('engine/johto_shared_pokecenter.asm','ld [wLastBlackoutMap], a',
                            'ld [wJohtoLastHealLocalID], a','kanto_heal_kept_and_no_early_johto_stamp')
    def test_writer_rejects_wrong_map(self):
        self.check_mutation('engine/johto_gold_healing_machine_337.asm',
                            'cp JOHTO_CHERRYGROVE_POKECENTER_1F_LOCAL_ID',
                            'cp JOHTO_CHERRYGROVE_LOCAL_ID',
                            'writer_restricted_to_active_center')
    def test_magic_required(self):
        self.check_mutation('engine/johto_pilot_runtime.asm','cp JOHTO_LAST_HEAL_MAGIC',
                            'cp 0','town_start_recovers_record_or_player')
    def test_wrong_sprite_palette(self):
        self.check_mutation('color/sprites.asm','cp JOHTO_POKECENTER','cp JOHTO_GATE','sprite_palettes_heal_machine')

if __name__=='__main__': unittest.main()
