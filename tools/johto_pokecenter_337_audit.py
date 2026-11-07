#!/usr/bin/env python3
"""DEV-337 source-only review: Gold nurse OAM, heal stamp, and room step fastpath.

Checks the executable paths and frozen Gold art. Cannot establish RGBDS/linker
placement, live WRAM values, or frame timing; device validation is mandatory.
"""
from __future__ import annotations
import argparse
import hashlib
import json
from pathlib import Path
import re
import struct

ROOM = 'JOHTO_CHERRYGROVE_POKECENTER_1F_LOCAL_ID'
GOLD_PNG_SHA256 = 'd62bad94c8ff93ae8c554df22d43b4f472696e5a3b1023d04fd16b030f4ff34f'
OAM_GOLD = [
    (32, 34, '$fc', '$14'), (32, 38, '$fc', '$14'),
    (38, 32, '$fd', '$14'), (38, 40, '$fd', '$34'),
    (43, 32, '$fd', '$14'), (43, 40, '$fd', '$34'),
    (48, 32, '$fd', '$14'), (48, 40, '$fd', '$34'),
]

def audit(root: Path) -> dict:
    root = Path(root)
    checks = []
    errors = []
    def ck(name, predicate):
        checks.append({'check': name, 'status': 'PASS' if predicate else 'FAIL'})
        if not predicate:
            errors.append(name)
    def read(rel):
        return (root / rel).read_text(encoding='utf-8')
    def src(rel):
        return '\n'.join(line.partition(';')[0] for line in read(rel).splitlines())
    try:
        anim = src('engine/johto_gold_healing_machine_337.asm')
        main = src('main.asm')
        nurse = src('engine/overworld/pokecenter.asm')
        original = src('engine/overworld/healing_machine.asm')
        runtime = src('engine/johto_pilot_runtime.asm')
        land = src('engine/johto_land_collision_gateway_272.asm')
        town = src('engine/town_map.asm')
        fly = src('engine/johto_pilot_fly_map.asm')
        version = read('data/game_version.asm')
        png = (root/'gfx/johto_gold_heal_machine.png').read_bytes()
        ck('gold_machine_png_exact_gold_source',
           hashlib.sha256(png).hexdigest() == GOLD_PNG_SHA256 and
           png.startswith(b'\x89PNG\r\n\x1a\n') and
           struct.unpack('>II', png[16:24]) == (8, 16))
        ck('gold_machine_floating_romx_not_rom0',
           'SECTION "Johto Gold Healing Machine 337", ROMX\nINCLUDE "engine/johto_gold_healing_machine_337.asm"' in main and
           'SECTION "Johto Gold Healing Machine 337", ROM0' not in main)
        ck('kanto_healing_machine_stays_independent',
           'AnimateHealingMachine:' in original and
           'INCBIN "gfx/pokecenter_ball.2bpp"' in original and
           'callab JohtoRecordSuccessfulCenterHeal335' not in original and
           re.search(r'\.kanto\s+callba AnimateHealingMachine\s+ret', anim) is not None)
        ck('yes_only_nurse_dispatches_regional_animation',
           bool(re.search(r'jr nz, \.declinedHealing.*?predef HealParty\s+callba AnimateHealingMachineRegional337', nurse, re.S)) and
           nurse.count('callba AnimateHealingMachineRegional337') == 1 and
           'callba AnimateHealingMachine' not in nurse.replace('callba AnimateHealingMachineRegional337', ''))
        entry = anim.split('AnimateHealingMachineRegional337::', 1)[1].split('\n.johto\n', 1)[0]
        ck('gold_animation_requires_map_and_center_id',
           bool(re.search(r'ld a, \[wCurMap\]\s+cp JOHTO_RUNTIME_MAP_HANDLE\s+jr nz, \.kanto', entry)) and
           bool(re.search(r'ld a, \[wCurLocalMapID\]\s+cp ' + ROOM + r'\s+jr z, \.johto', entry)))
        ck('gold_uses_exact_two_tile_asset_and_oam_placement',
           'lb bc, BANK(JohtoGoldHealMachineGFX337), 2' in anim and
           'INCBIN "gfx/johto_gold_heal_machine.2bpp"' in anim and
           'ASSERT JohtoGoldHealMachineGFX337End - JohtoGoldHealMachineGFX337 == 2 * 16' in anim and
           'ld hl, wOAMBuffer + $80' in anim and 'ld de, .GoldOAM' in anim and
           'ASSERT .GoldOAMEnd - .GoldOAM == 8 * 4' in anim and
           [tuple(int(x.strip()) if j<2 else x.strip().lower() for j,x in enumerate(line.split('db ',1)[1].split(',')))
            for line in anim.split('.GoldOAM\n',1)[1].split('.GoldOAMEnd',1)[0].splitlines() if line.strip().startswith('db ')] == OAM_GOLD)
        yes = anim.split('\n.johto\n',1)[1].split('\n.copyOne\n',1)[0]
        stamp = yes.find('ld [wJohtoLastHealLocalID], a')
        ck('stamp_only_after_song_and_sprite_restore',
           'call WaitForSongToFinish' in yes and stamp > yes.find('call WaitForSongToFinish') > 0 and
           stamp > yes.find('ld [hl], a') and
           re.search(r'ld a, \[wCurLocalMapID\]\s+ld \[wJohtoLastHealLocalID\], a\s+' +
                     r'ld a, JOHTO_LAST_HEAL_MAGIC\s+ld \[wJohtoLastHealMagic\], a\s+jp UpdateSprites', yes) is not None)
        helper = runtime.split('JohtoPilotGetLastHealLandmarkOrPlayer::', 1)[1].split('JohtoPilotLoadMapMusic::',1)[0]
        ck('town_start_reads_saved_heal_and_fallback',
           all(t in helper for t in ('ld a, [wJohtoLastHealMagic]', 'cp JOHTO_LAST_HEAL_MAGIC',
                                    'ld a, [wJohtoLastHealLocalID]', 'cp '+ROOM,
                                    'ld e, 2', 'jp JohtoPilotGetTownMapLandmark')) and
           'callab JohtoPilotGetLastHealLandmarkOrPlayer' in town)
        ck('fly_does_not_overwrite_saved_heal',
           re.search(r'ld\s+\[wJohtoLastHealMagic\]\s*,', fly) is None and
           re.search(r'ld\s+\[wJohtoLastHealLocalID\]\s*,', fly) is None)
        edge = runtime.split('JohtoPilotIsClosedOutdoorEdge::', 1)[1].split('JohtoPilotGetLastHealLandmarkOrPlayer::', 1)[0] if 'JohtoPilotGetLastHealLandmarkOrPlayer::' in runtime.split('JohtoPilotIsClosedOutdoorEdge::', 1)[1] else runtime.split('JohtoPilotIsClosedOutdoorEdge::',1)[1]
        ck('center_edge_fastpath_keeps_finite_guard',
           re.search(r'ld a, \[wCurLocalMapID\]\s+cp '+ROOM+r'\s+jp z, \.verticalGateClosedEdge314', edge) is not None and
           edge.index('cp '+ROOM) < edge.index('cp JOHTO_CHERRYGROVE_LOCAL_ID') and
           'callab JohtoVerticalGateClosedEdge314' in edge)
        step = runtime.split('JohtoPilotGateDoorApproachAllowed::',1)[1]
        ck('center_skips_outdoor_door_router',
           re.search(r'cp '+ROOM+r'\s+ret z',step) is not None and
           step.index('cp '+ROOM) < step.index('call JohtoPilotIsVerticalGatePairMap314'))
        collision = land.split('JohtoOverworldSouthLandDecision::',1)[1]
        ck('center_skips_outdoor_role_dispatch_and_uses_legacy_collision',
           re.search(r'ld e, 2\s+ld a, \[wCurLocalMapID\]\s+cp '+ROOM+r'\s+ret z',collision) is not None and
           collision.index('cp '+ROOM) < collision.index('.southMaps'))
        ck('same_version_all_builds', 'GameVersionText::' in version and
           bool(re.search(r'(?m)^\s*db "REF-(\d{3})[A-Z]?@"$', version)) and int(re.search(r'(?m)^\s*db "REF-(\d{3})[A-Z]?@"$', version).group(1)) >= 349)
    except (OSError, ValueError, IndexError, TypeError) as exc:
        errors.append('input_error: '+str(exc))
    return {'status': 'PASS_STATIC_ONLY' if not errors else 'FAIL', 'checks': checks,
            'errors': errors, 'rom_built': False, 'runtime_frame_profiled': False,
            'device_accepted': False}

if __name__ == '__main__':
    ap=argparse.ArgumentParser(); ap.add_argument('--project',type=Path,default=Path.cwd())
    a=ap.parse_args(); r=audit(a.project)
    print(json.dumps(r,ensure_ascii=False,indent=2))
    raise SystemExit(bool(r['errors']))
