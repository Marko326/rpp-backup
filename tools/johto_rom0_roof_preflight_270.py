#!/usr/bin/env python3
"""ROM0 roof caller budget and ROMX trampoline contract (static only).

The owner-reported rgblink failure was ``Home Copy Data``.  FIX-269 inserted
2 * six-byte callba macros into the almost-full Home ROM0.  This check verifies
both paths now reuse existing six-byte callba slots; it does not link a ROM.
"""
from pathlib import Path
import re

ROOT = Path(__file__).resolve().parents[1]


def audit(root=ROOT):
    root = Path(root)
    problems=[]
    home=(root/'home/overworld.asm').read_text(encoding='utf-8')
    roofs=(root/'engine/johto_south_roofs_269.asm').read_text(encoding='utf-8')
    mains=(root/'main.asm').read_text(encoding='utf-8')
    macros=(root/'macros/asm_macros.asm').read_text(encoding='utf-8')
    def part(text, beginning, end):
        try:
            after=text.split(beginning,1)[1]
            match=re.search(r'(?m)^'+re.escape(end)+r'\s*$',after)
            if match is None: raise IndexError
            return after[:match.start()]
        except IndexError:
            problems.append('missing section: '+beginning)
            return ''
    connection=part(home, 'CheckMapConnections::', '.didNotEnterConnectedMap')
    tileset=part(home, 'LoadTilesetTilePatternData::', 'LoadTileBlockMap::')
    complete=part(home, 'LoadMapData::', 'SwitchToMapRomBank::')
    if re.search(r'(?m)^\s*callba\s+JohtoSouthRoof(?:OnConnection|AfterTilesetLoad)\b',home):
        problems.append('new roof callba in Home reintroduces ROM0 overflow')
    if not re.search(r'(?s)callba JohtoSouthConnectionSpritesAndRoofs270\s+call LoadTileBlockMap\s+jp OverworldLoopLessDelay',connection):
        problems.append('seamless map wrapper / Home LoadTileBlockMap order is wrong')
    if connection.count('callba JohtoSouthConnectionSpritesAndRoofs270')!=1:
        problems.append('seamless map must use exactly one existing six-byte farcall')
    if connection.count('callba InitMapSprites'):
        problems.append('unwrapped InitMapSprites would skip roof art on seamless connections')
    if not re.search(r'(?s)call FarCopyData2.*?callba JohtoSouthTilesetGfxFinalizer270\s+ret',tileset):
        problems.append('tileset finalizer must replace Snow farcall after base tileset copy')
    if tileset.count('callba JohtoSouthTilesetGfxFinalizer270')!=1:
        problems.append('tileset must use exactly one existing six-byte farcall')
    if complete.count('call LoadTilesetTilePatternData')!=1 or 'callba JohtoSouth' in complete:
        problems.append('LoadMapData must not add a second roof ROM0 callba')
    # The two ROM0 callba instructions replace existing callba instructions
    # (6 bytes each: LD B,n / LD HL,nn / RST $18). Old .269 appended two more.
    if 'ld b, BANK(\\1)\n\tld hl, \\1\n\trst $18' not in macros:
        problems.append('callba instruction-size ABI no longer matches six bytes')
    wrap_tile=part(roofs,'JohtoSouthTilesetGfxFinalizer270::','JohtoSouthConnectionSpritesAndRoofs270::')
    wrap_conn=part(roofs,'JohtoSouthConnectionSpritesAndRoofs270::','JohtoSouthRoofAfterTilesetLoad::')
    if not re.search(r'callba ApplySnowTilesetGfxPatch\s+jp JohtoSouthRoofAfterTilesetLoad',wrap_tile):
        problems.append('ROMX tileset wrapper must preserve Snow then Gold roof load')
    if not re.search(r'callba InitMapSprites\s+jp JohtoSouthRoofOnConnection',wrap_conn):
        problems.append('ROMX connection wrapper must preserve sprite init then roof copy')
    if 'SECTION "Johto Gold Roofs 269", ROMX, BANK[$4F]' not in mains:
        problems.append('roof wrappers must remain in ROMX Bank $4F')
    if 'jp nz,.noCollision' not in home or 'jr nz,.noCollision' in home:
        problems.append('owner-tested long JP has been overwritten')
    return problems


if __name__=='__main__':
    errors=audit()
    if errors:
        print('FAIL:',*errors,sep='\n- ')
        raise SystemExit(1)
    print('PASS: two reused Home farcalls, both ROMX roof paths, -12 ROM0 bytes vs FIX-269; STATIC ONLY')
