; DEV-337: Gold-specific nurse Yes animation. The fixed Bank $01 Kanto
; AnimateHealingMachine and its sprite table remain completely unchanged.
; Gold OAM placements come from pokegold/master HealMachineAnim.PC_ElmsLab_OAM.
; Sprite indices $fc/$fd are temporary and restored by UpdateSprites.
AnimateHealingMachineRegional337::
    ld a, [wCurMap]
    cp JOHTO_RUNTIME_MAP_HANDLE
    jr nz, .kanto
    ld a, [wCurLocalMapID]
    cp JOHTO_CHERRYGROVE_POKECENTER_1F_LOCAL_ID
    jr z, .johto
.kanto
    callba AnimateHealingMachine
    ret
.johto
    xor a
    call PlayMusic
    ld de, JohtoGoldHealMachineGFX337
    ld hl, vChars0 + $fc0
    lb bc, BANK(JohtoGoldHealMachineGFX337), 2
    call CopyVideoData
    ld hl, wUpdateSpritesEnabled
    ld a, [hl]
    push af
    ld [hl], $ff
    push hl
    ld a, [rOBP1]
    push af
    ld hl, wOAMBuffer + $80
    ld de, .GoldOAM
    call .copyOne
    call .copyOne
    ld a, [wPartyCount]
    ld b, a
.partyLoop
    call .copyOne
    ld a, SFX_HEALING_MACHINE
    call PlaySound
    ld c, 30
    call DelayFrames
    dec b
    jr nz, .partyLoop
    ld a, [wAudioROMBank]
    cp $1f
    ld [wAudioSavedROMBank], a
    jr nz, .next
    ld a, $ff
    ld [wNewSoundID], a
    call PlaySound
    xor a
    ld [wAudioROMBank], a
.next
    ld a, MUSIC_PKMN_HEALED
    ld [wNewSoundID], a
    call PlayMusic
    ld d, %01110100
    ld b, 8
.flashLoop
    ld a, [rOBP1]
    xor d
    ld [rOBP1], a
    ld c, 10
    call DelayFrames
    dec b
    jr nz, .flashLoop
    call WaitForSongToFinish
    ld c, 32
    call DelayFrames
    pop af
    ld [rOBP1], a
    pop hl
    pop af
    ld [hl], a
    ; Entered Johto branch only with active Center stable ID 123 and nurse
    ; Yes animation, so there is no second volatile map check after music.
    ; Kanto wLastBlackoutMap is never modified here.
    ld a, JOHTO_CHERRYGROVE_POKECENTER_1F_LOCAL_ID
    ld [wJohtoLastHealLocalID], a
    ld a, JOHTO_LAST_HEAL_MAGIC
    ld [wJohtoLastHealMagic], a
    jp UpdateSprites
.copyOne
    ld a, [de]
    inc de
    ld [hli], a
    ld a, [de]
    inc de
    ld [hli], a
    ld a, [de]
    inc de
    ld [hli], a
    ld a, [de]
    inc de
    ld [hli], a
    ret
.GoldOAM
    ; Raw Gold 8x8 OBJ coords: monitor at Y32 X34/38, then 6 balls
    ; at Y38/43/48, X32/40.  Use the two original Gold graphics.
    db 32, 34, $fc, $14
    db 32, 38, $fc, $14
    db 38, 32, $fd, $14
    db 38, 40, $fd, $34
    db 43, 32, $fd, $14
    db 43, 40, $fd, $34
    db 48, 32, $fd, $14
    db 48, 40, $fd, $34
.GoldOAMEnd
ASSERT .GoldOAMEnd - .GoldOAM == 8 * 4

JohtoGoldHealMachineGFX337::
    INCBIN "gfx/johto_gold_heal_machine.2bpp"
JohtoGoldHealMachineGFX337End::
ASSERT JohtoGoldHealMachineGFX337End - JohtoGoldHealMachineGFX337 == 2 * 16
