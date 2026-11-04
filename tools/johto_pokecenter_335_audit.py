#!/usr/bin/env python3
"""DEV-335 Gold 5x4 center and post-heal callback audit; standard-library only.

Checks the NPC-243 reference artwork pixel-for-pixel after lossless tile-ID
permutation, full room passability, palette correspondence and actual healing
call chain. This is static source checking, not Game Boy execution or linking.
"""
from __future__ import annotations
import argparse, json, re, struct, zlib
from pathlib import Path

SWAPS={9:0x10, 0x10:9, 0x2e:0x11, 0x11:0x2e, 0x32:0x34, 0x34:0x32}

def gray_png_rows(path):
    raw=path.read_bytes()
    if not raw.startswith(b'\x89PNG\r\n\x1a\n'): raise ValueError('not PNG')
    off=8; compressed=bytearray(); width=height=None
    while off<len(raw):
        n=struct.unpack('>I',raw[off:off+4])[0];typ=raw[off+4:off+8];dat=raw[off+8:off+8+n]
        off+=n+12
        if typ==b'IHDR':
            width,height,depth,kind,*_=struct.unpack('>IIBBBBB',dat)
            if depth!=8 or kind!=0: raise ValueError('expected grayscale 8bpp PNG')
        if typ==b'IDAT': compressed.extend(dat)
        if typ==b'IEND':break
    if width!=64 or height!=96: raise ValueError(f'unexpected {width}x{height}')
    raw=zlib.decompress(compressed);i=0;rows=[];prev=[0]*width
    for y in range(height):
        filt=raw[i];i+=1
        line=list(raw[i:i+width]);i+=width
        for x in range(width):
            a=line[x-1] if x else 0;b=prev[x];c=prev[x-1] if x else 0
            if filt==1:pred=a
            elif filt==2:pred=b
            elif filt==3:pred=(a+b)//2
            elif filt==4:
                p=a+b-c;pa=abs(p-a);pb=abs(p-b);pc=abs(p-c)
                pred=a if pa<=pb and pa<=pc else b if pb<=pc else c
            elif filt==0:pred=0
            else:raise ValueError('unknown PNG filter')
            line[x]=(line[x]+pred)&255
        rows.append(bytes(line));prev=line
    return rows

def tiles(rows):
    return [tuple(row[(i%8)*8:(i%8+1)*8] for row in rows[(i//8)*8:((i//8)+1)*8]) for i in range(96)]

def palette_colors(path):
    out=[]
    for line in path.read_text().splitlines():
        line=line.split(';')[0]
        if 'tilepal' in line: out.extend(x.strip() for x in line.split(',',1)[1].split(','))
    return out

def audit(root):
    root=Path(root);checks=[];errors=[]
    def ck(name,ok):
        checks.append({'check':name,'status':'PASS' if ok else 'FAIL'})
        if not ok:errors.append(name)
    try:
        ref=root/'maps/johto_pilot/reference'
        rp=ref/'johto_pokecenter_243.png';newpng=root/'gfx/tilesets/johto_shared_pokecenter.png'
        source=tiles(gray_png_rows(rp));current=tiles(gray_png_rows(newpng))
        ck('exact_gold_pixel_permutation',all(source[i]==current[SWAPS.get(i,i)] for i in range(96)))
        oldbst=(ref/'johto_pokecenter_243.bst').read_bytes()
        newbst=(root/'gfx/blocksets/johto_shared_pokecenter.bst').read_bytes()
        ck('full_blockset_reference_reindex',len(oldbst)==len(newbst)==256 and
           newbst==bytes(SWAPS.get(v,v) for v in oldbst))
        oldblk=(ref/'johto_pokecenter_243.blk').read_bytes()
        newblk=(root/'maps/johto_pilot/CherrygrovePokecenter1F.runtime.blk').read_bytes()
        gold=(root/'maps/johto_pilot/CherrygrovePokecenter1F.gold.blk').read_bytes()
        ck('old_conversion_and_gold_5x4',len(gold)==len(oldblk)==len(newblk)==20 and newblk==oldblk)
        oldpass=set((ref/'johto_pokecenter_243.tilecoll').read_bytes())-{0xff}
        newpass=set((root/'gfx/tilesets/pokecenter.tilecoll').read_bytes())-{0xff}
        used={t for block in oldblk for t in oldbst[block*16:block*16+16]}
        ck('every_room_tile_collision_equivalent',oldpass=={9,0x2e} and
           all((t in oldpass)==(SWAPS.get(t,t) in newpass) for t in used))
        # Palette source is frozen along with the exact old compact graphics.
        orig=root/'maps/johto_pilot/reference/johto_pokecenter_243_palette.asm'
        oldpal=palette_colors(orig);newpal=palette_colors(root/'color/tilesets/johto_shared_pokecenter.asm')
        ck('same_96_gold_palettes',len(oldpal)==len(newpal)==96 and all(oldpal[i]==newpal[SWAPS.get(i,i)] for i in range(96)))
        def code(rel):return '\n'.join(s.split(';')[0] for s in (root/rel).read_text().splitlines())
        room=code('engine/johto_shared_pokecenter.asm');heal=code('engine/overworld/healing_machine.asm')
        goldheal=code('engine/johto_gold_healing_machine_337.asm')
        nurse=code('engine/overworld/pokecenter.asm');town=code('engine/johto_pilot_runtime.asm')
        tile=code('data/tileset_headers.asm');sets=code('color/data/map_palette_sets.asm')
        pal=code('color/data/map_palette_assignments.asm');sprite=code('color/sprites.asm')
        menu=code('engine/town_map.asm');main=code('main.asm')
        ck('isolated_gold_tileset_37',all(t in code('constants/tilesets.asm') for t in ('const JOHTO_POKECENTER','const JOHTO_PARK_GATE')) and
           'tileset JohtoSharedPokecenter_Block, JohtoSharedPokecenter_GFX, Pokecenter_Coll' in tile and
           '(JOHTO_POKECENTER + 1) * 12' in tile and
           '(JOHTO_POKECENTER + 1) * 8' in sets and
           '(JOHTO_POKECENTER + 1) * $60' in pal and
           'INCLUDE "color/tilesets/johto_shared_pokecenter.asm"' in pal and
           'JohtoSharedPokecenter_GFX:: INCBIN "gfx/tilesets/johto_shared_pokecenter.2bpp"' in main and
           'JohtoSharedPokecenter_Block:: INCBIN "gfx/blocksets/johto_shared_pokecenter.bst"' in main)
        ck('gold_runtime_room_and_warps',all(t in room for t in ('DEF JOHTO_SHARED_POKECENTER_WIDTH EQU 5','db JOHTO_POKECENTER',
            'db 7, 3, 1, JOHTO_REGISTERED_WARP_SELECTOR','db 7, 4, 1, JOHTO_REGISTERED_WARP_SELECTOR','db $0f','TX_POKECENTER_NURSE')) and
           room.count('db JOHTO_POKECENTER')==10)
        ck('sprite_palettes_heal_machine',bool(re.search(r'cp POKECENTER\s+jr z, \.gotPaletteList\s+cp JOHTO_POKECENTER\s+jr z, \.gotPaletteList',sprite)))
        entry=goldheal.split('AnimateHealingMachineRegional337::',1)[1].split('\n.johto\n',1)[0]
        writer=goldheal.split('\n.johto\n',1)[1].split('\n.copyOne\n',1)[0]
        pre=room.split('SetLastBlackoutMapRegional::',1)[1]
        ck('healing_yes_only_post_animation',
            bool(re.search(r'jr nz, \.declinedHealing.*?predef HealParty.*?callba AnimateHealingMachineRegional337',nurse,re.S)) and
            nurse.count('callba AnimateHealingMachineRegional337')==1 and
            'callab JohtoRecordSuccessfulCenterHeal335' not in heal and
            'JohtoRecordSuccessfulCenterHeal335::' not in room and
            'call WaitForSongToFinish' in writer and
            writer.find('ld [wJohtoLastHealMagic], a')>writer.find('call WaitForSongToFinish'))
        ck('kanto_heal_kept_and_no_early_johto_stamp', 'ret z' in pre.split('.kanto',1)[0] and
           'ld [wLastBlackoutMap], a' in pre and 'ld [wJohtoLastHealMagic], a' not in pre and
           'callab SetLastBlackoutMapRegional' in code('engine/overworld/set_blackout_map.asm'))
        ck('writer_restricted_to_active_center',
           bool(re.search(r'ld a, \[wCurMap\]\s+cp JOHTO_RUNTIME_MAP_HANDLE\s+jr nz, \.kanto\s+ld a, \[wCurLocalMapID\]\s+cp JOHTO_CHERRYGROVE_POKECENTER_1F_LOCAL_ID\s+jr z, \.johto\s+cp JOHTO_ROUTE_32_POKECENTER_1F_LOCAL_ID\s+jr z, \.johto',entry)) and
           bool(re.search(r'ld a, \[wCurLocalMapID\]\s+ld \[wJohtoLastHealLocalID\], a\s+ld a, JOHTO_LAST_HEAL_MAGIC\s+ld \[wJohtoLastHealMagic\], a\s+jp UpdateSprites', writer)))
        s=town.split('JohtoPilotGetLastHealLandmarkOrPlayer::',1)[1].split('JohtoPilotLoadMapMusic::',1)[0]
        ck('town_start_recovers_record_or_player',all(t in s for t in ('cp JOHTO_LAST_HEAL_MAGIC',
            'cp JOHTO_CHERRYGROVE_POKECENTER_1F_LOCAL_ID','ld e, 2','jp JohtoPilotGetTownMapLandmark')) and
            'callab JohtoPilotGetLastHealLandmarkOrPlayer' in menu)
        ck('rom0_collision_data_reused', 'JohtoCenter_Coll' not in code('home.asm') and
           'Pokecenter_Coll' in tile and 'SECTION "Johto Gold Shared Pokemon Center Tileset 335", ROMX' in main)
    except (OSError,IndexError,ValueError,struct.error) as ex:
        errors.append('read_and_parse: '+str(ex))
    return {'status':'PASS_STATIC_ONLY' if not errors else 'FAIL','checks':checks,'errors':errors,'rom_built':False,'device_accepted':False}

if __name__=='__main__':
    p=argparse.ArgumentParser();p.add_argument('--project',type=Path,default=Path('.'));args=p.parse_args()
    r=audit(args.project);print(json.dumps(r,indent=2));raise SystemExit(bool(r['errors']))
