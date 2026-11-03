; DEV-335: reuse the Gold 5x4 compact center from NPC-5.62.243.
; Graphics/palettes/block tiles are reindexed (9<->10, 2e<->11, 32<->34)
; to use the already-ROM0 Pokecenter_Coll, without changing any Gold pixels
; or room passability. One interior for future Johto centers.
DEF JOHTO_SHARED_POKECENTER_WIDTH EQU 5
DEF JOHTO_SHARED_POKECENTER_HEIGHT EQU 4
JohtoSharedPokecenterRuntimeBlocks::
    INCBIN "maps/johto_pilot/CherrygrovePokecenter1F.runtime.blk" ; Gold 5x4 shared layout
JohtoSharedPokecenterRuntimeBlocksEnd::
ASSERT JohtoSharedPokecenterRuntimeBlocksEnd - JohtoSharedPokecenterRuntimeBlocks == JOHTO_SHARED_POKECENTER_WIDTH * JOHTO_SHARED_POKECENTER_HEIGHT

JohtoSharedPokecenterRuntimeHeader::
    db JOHTO_POKECENTER
    db JOHTO_SHARED_POKECENTER_HEIGHT, JOHTO_SHARED_POKECENTER_WIDTH
    dw JohtoSharedPokecenterRuntimeBlocks
    dw JohtoSharedPokecenterTextPointers
    dw JohtoSharedPokecenterMapScript
    db 0 ; indoor, no outdoor connections
    dw JohtoSharedPokecenterRuntimeObjects
JohtoSharedPokecenterRuntimeHeaderEnd::
ASSERT JohtoSharedPokecenterRuntimeHeaderEnd - JohtoSharedPokecenterRuntimeHeader == 12
ASSERT BANK(JohtoSharedPokecenterRuntimeHeader) == BANK(JohtoSharedPokecenterRuntimeBlocks)
ASSERT JOHTO_CHERRYGROVE_POKECENTER_1F_LOCAL_ID == 123

JohtoSharedPokecenterMapScript::
    call EnableAutoTextBoxDrawing
    ret

JohtoSharedPokecenterTextPointers:
    dw JohtoSharedPokecenterNurseText
JohtoSharedPokecenterNurseText:
    TX_POKECENTER_NURSE ; reusable RPP heal animation/yes-no dialog

JohtoSharedPokecenterRuntimeObjects::
    db $0f ; Gold black interior border
    db 2
    db 7, 3, 1, JOHTO_REGISTERED_WARP_SELECTOR
    db 7, 4, 1, JOHTO_REGISTERED_WARP_SELECTOR
    db 0 ; signs (PC/storage and upstairs are not exposed this stage)
    db 1 ; just one real, working nurse, no dummy NPCs
    object SPRITE_NURSE, $3, $1, STAY, DOWN, $1 ; Gold and Kanto agree; counter talk needs $15 tile

; Reusable center carpet predicate for the existing Johto warp pipeline.
; E=1 only when standing on an actual Gold exit carpet and pressing DOWN.
; Any LEFT/RIGHT movement on the paired carpets must not trigger a warp;
; other collisions while on them must not leave the center either.
JohtoSharedCenterDownCollision336::
    ld e, 0
    ld a, [wCurLocalMapID]
    cp JOHTO_CHERRYGROVE_POKECENTER_1F_LOCAL_ID
    ret nz
    ld a, [wPlayerDirection]
    cp PLAYER_DIR_DOWN
    ret nz
    ld a, [wYCoord]
    cp 7
    ret nz
    ld a, [wXCoord]
    cp 3
    jr z, .allow
    cp 4
    ret nz
.allow
    ld e, 1
    ret

; RPP's original Kanto healing logic relocated from near-full Bank $01.
; This wrapper is used by both regions; only an explicitly active Johto
; Pokecenter may set the separate saved Johto recovery key.
SetLastBlackoutMapRegional::
    ld a, [wCurMap]
    cp JOHTO_RUNTIME_MAP_HANDLE
    ret z ; Johto is recorded ONLY after the successful machine animation
.kanto
    ; Exact original Safari Zone and Kanto last-blackout semantics.
    push hl
    ld hl, .safariRestHouses
    ld a, [wCurMap]
    ld b, a
.loop
    ld a, [hli]
    cp -1
    jr z, .notRestHouse
    cp b
    jr nz, .loop
    jr .done
.notRestHouse
    ld a, [wLastMap]
    ld [wLastBlackoutMap], a
.done
    pop hl
    ret
.safariRestHouses
    db SAFARI_ZONE_REST_HOUSE_2, SAFARI_ZONE_REST_HOUSE_3, SAFARI_ZONE_REST_HOUSE_4, -1

