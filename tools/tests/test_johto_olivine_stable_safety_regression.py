"""Golden-baseline safeguard for Olivine public rooms.

The source of truth is the Gold `maps/Olivine*.asm` contracts, rather than
copying the converter's own expected values. This is a static contract check,
NOT a ROM execution or RGBDS build test.
"""
from pathlib import Path
import re
import unittest

ROOT = Path(__file__).resolve().parents[2]


def read(rel):
    return (ROOT / rel).read_text(encoding='utf-8')


def failures(files):
    faults=[]
    def must(condition, detail):
        if not condition: faults.append(detail)

    city=files['data/mapObjects/JohtoOlivineCity.asm']
    lookup=files['engine/overworld/region_map_lookup.asm']
    home=files['home/overworld.asm']
    collision=files['engine/overworld/johto_route33_collision.asm']
    colors=files['color/sprites.asm']
    cafe=files['data/mapObjects/JohtoOlivineCafe.asm']
    center=files['data/mapObjects/JohtoOlivinePokecenter1F.asm']
    const=files['constants/sprite_constants.asm']
    sprites=files['data/sprite_sets.asm']
    sprite_loader=files['engine/overworld/map_sprites.asm']

    # Protect the user's verified MART entry: source and destination table
    # must have the same zero-based target and exact source-5 index.
    must('db 17, 19, 0, REGION_WARP_ESCAPE' in city, 'MART exterior target changed')
    must(bool(re.search(r'(?m)^\s*db JOHTO_OLIVINE_CITY_LOCAL_ID, 5, 0, MAP_REGION_JOHTO, JOHTO_OLIVINE_MART_LOCAL_ID\s*$',lookup)),
         'MART lookup target changed / source-vs-target mismatch')
    must('db 7, 2, 5, REGION_WARP_ESCAPE' in files['data/mapObjects/JohtoOlivineMart.asm'], 'MART left return changed')
    must('db 7, 3, 5, REGION_WARP_ESCAPE' in files['data/mapObjects/JohtoOlivineMart.asm'], 'MART right return changed')

    # Gold OlivineCafe two down-only carpets (2,7)/(3,7); the no-collision
    # warp dispatcher must arm but not transfer on stepping/sideways.
    selector=home.split('IsJohtoSouthGatePortal::',1)[1].split('MapEntryAfterBattle::',1)[0]
    must(bool(re.search(r'cp JOHTO_OLIVINE_CAFE_LOCAL_ID\s*\n\s*jr z, \.yes',selector)),
         'Cafe missing from collision-only selector')
    must(bool(re.search(r'cp JOHTO_OLIVINE_CAFE_LOCAL_ID\s*\n\s*jp z, \.houseExitDown',collision)),
         'Cafe missing down-exit collision handler')
    must('db 7, 2, 4, REGION_WARP_ESCAPE' in cafe and 'db 7, 3, 4, REGION_WARP_ESCAPE' in cafe,
         'Cafe exit lanes differ from Gold')
    must(bool(re.search(r'\.houseExitDown\s*\n\s*ld a, \[wYCoord\]\s*\n\s*cp 7',collision)),
         'Interior carpet coordinates not checked')
    # Defensive preservation of original gates and their movement engine.
    must('callba JohtoNorthGateStepWarpAllowed' in home and 'callba JohtoGateCollisionDirectionAllowed' in home,
         'Gate mechanisms bypassed')

    must(bool(re.search(r'0x69: SPRITE_JOHTO_CLERK[^\n]*\n\s*db PAL_OW_GREEN',colors)),
         'Gold clerk default green lost')
    must(bool(re.search(r'0x6d: SPRITE_JOHTO_SAILOR[^\n]*\n\s*db PAL_OW_BLUE',colors)),
         'Gold sailor default blue lost')
    must(bool(re.search(r'0x6e: SPRITE_JOHTO_FISHING_GURU_BLUE[^\n]*\n\s*db PAL_OW_BLUE',colors)),
         'Gold blue Fishing Guru palette lost')
    must('SPRITE_JOHTO_FISHING_GURU_BLUE' in const, 'Blue sprite ID is missing')
    must('dw JohtoFishingGuruSprite\n\tdb $c0\n\tdb BANK(JohtoFishingGuruSprite)' in sprites,
         'Gold Fishing Guru image bank pointer missing')
    must('cp a, SPRITE_JOHTO_FISHING_GURU_BLUE' in sprite_loader,
         'Blue Fishing Guru missing 12-tile sprite branch')
    must('object SPRITE_JOHTO_FISHING_GURU_BLUE, 1, 5, WALK, 1, 2' in cafe,
         'Cafe Fishing Guru color not corrected')
    must('object SPRITE_JOHTO_FISHING_GURU_BLUE, 8, 4, WALK, 2, 2' in center,
         'Pokecenter Fishing Guru color/horizontal axis not corrected')
    return faults

FILES=[
    'data/mapObjects/JohtoOlivineCity.asm',
    'engine/overworld/region_map_lookup.asm',
    'home/overworld.asm',
    'engine/overworld/johto_route33_collision.asm',
    'color/sprites.asm',
    'data/mapObjects/JohtoOlivineCafe.asm',
    'data/mapObjects/JohtoOlivinePokecenter1F.asm',
    'data/mapObjects/JohtoOlivineMart.asm',
    'constants/sprite_constants.asm',
    'data/sprite_sets.asm',
    'engine/overworld/map_sprites.asm',
]


class StableOlivineContracts(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.sources={rel:read(rel) for rel in FILES}

    def test_gold_and_stable_runtime_contracts(self):
        self.assertEqual(failures(self.sources), [])

    def test_mart_wrong_destination_is_rejected(self):
        edited=dict(self.sources)
        edited['engine/overworld/region_map_lookup.asm']=edited['engine/overworld/region_map_lookup.asm'].replace(
            'JOHTO_OLIVINE_CITY_LOCAL_ID, 5, 0, MAP_REGION_JOHTO, JOHTO_OLIVINE_MART_LOCAL_ID',
            'JOHTO_OLIVINE_CITY_LOCAL_ID, 5, 1, MAP_REGION_JOHTO, JOHTO_OLIVINE_MART_LOCAL_ID')
        self.assertIn('MART lookup target changed / source-vs-target mismatch',failures(edited))

    def test_cafe_auto_step_on_is_rejected(self):
        edited=dict(self.sources)
        edited['home/overworld.asm']=edited['home/overworld.asm'].replace('cp JOHTO_OLIVINE_CAFE_LOCAL_ID','cp JOHTO_OLIVINE_MART_LOCAL_ID')
        self.assertIn('Cafe missing from collision-only selector',failures(edited))

    def test_pc_wrong_axis_is_rejected(self):
        edited = dict(self.sources)
        edited['data/mapObjects/JohtoOlivinePokecenter1F.asm'] = (
            edited['data/mapObjects/JohtoOlivinePokecenter1F.asm'].replace(
                'object SPRITE_JOHTO_FISHING_GURU_BLUE, 8, 4, WALK, 2, 2',
                'object SPRITE_JOHTO_FISHING_GURU_BLUE, 8, 4, WALK, 1, 2'))
        self.assertIn('Pokecenter Fishing Guru color/horizontal axis not corrected', failures(edited))

    def test_gold_color_errors_are_rejected(self):
        edited=dict(self.sources)
        edited['color/sprites.asm']=edited['color/sprites.asm'].replace(
            '; 0x69: SPRITE_JOHTO_CLERK (Gold default green)\n\tdb PAL_OW_GREEN',
            '; 0x69: SPRITE_JOHTO_CLERK (Gold default green)\n\tdb PAL_OW_RED')
        self.assertIn('Gold clerk default green lost',failures(edited))


if __name__ == '__main__':
    unittest.main()
