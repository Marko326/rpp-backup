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

; Route32 center uses the exact same Gold 5x4 room, tileset and nurse.
; Its separate header/warp objects prevent an exit back to Cherrygrove.
JohtoRoute32PokecenterRuntimeHeader::
    db JOHTO_POKECENTER
    db JOHTO_SHARED_POKECENTER_HEIGHT, JOHTO_SHARED_POKECENTER_WIDTH
    dw JohtoSharedPokecenterRuntimeBlocks
    dw JohtoSharedPokecenterTextPointers
    dw JohtoSharedPokecenterMapScript
    db 0
    dw JohtoRoute32PokecenterRuntimeObjects
JohtoRoute32PokecenterRuntimeHeaderEnd::
ASSERT JohtoRoute32PokecenterRuntimeHeaderEnd - JohtoRoute32PokecenterRuntimeHeader == 12
ASSERT BANK(JohtoRoute32PokecenterRuntimeHeader) == BANK(JohtoSharedPokecenterRuntimeBlocks)
ASSERT JOHTO_ROUTE_32_POKECENTER_1F_LOCAL_ID == 106

; Azalea has its own outbound target but shares the Gold 5x4 room and nurse.
JohtoAzaleaPokecenterRuntimeHeader::
    db JOHTO_POKECENTER
    db JOHTO_SHARED_POKECENTER_HEIGHT, JOHTO_SHARED_POKECENTER_WIDTH
    dw JohtoSharedPokecenterRuntimeBlocks
    dw JohtoSharedPokecenterTextPointers
    dw JohtoSharedPokecenterMapScript
    db 0
    dw JohtoAzaleaPokecenterRuntimeObjects
JohtoAzaleaPokecenterRuntimeHeaderEnd::
ASSERT JohtoAzaleaPokecenterRuntimeHeaderEnd - JohtoAzaleaPokecenterRuntimeHeader == 12
ASSERT BANK(JohtoAzaleaPokecenterRuntimeHeader) == BANK(JohtoSharedPokecenterRuntimeBlocks)
ASSERT JOHTO_AZALEA_POKECENTER_1F_LOCAL_ID == 135

JohtoVioletPokecenterRuntimeHeader::
    db JOHTO_POKECENTER
    db JOHTO_SHARED_POKECENTER_HEIGHT, JOHTO_SHARED_POKECENTER_WIDTH
    dw JohtoSharedPokecenterRuntimeBlocks
    dw JohtoSharedPokecenterTextPointers
    dw JohtoSharedPokecenterMapScript
    db 0
    dw JohtoVioletPokecenterRuntimeObjects
JohtoVioletPokecenterRuntimeHeaderEnd::
ASSERT JohtoVioletPokecenterRuntimeHeaderEnd - JohtoVioletPokecenterRuntimeHeader == 12
ASSERT BANK(JohtoVioletPokecenterRuntimeHeader) == BANK(JohtoSharedPokecenterRuntimeBlocks)
ASSERT JOHTO_VIOLET_POKECENTER_1F_LOCAL_ID == 133

JohtoGoldenrodPokecenterRuntimeHeader::
    db JOHTO_POKECENTER
    db JOHTO_SHARED_POKECENTER_HEIGHT, JOHTO_SHARED_POKECENTER_WIDTH
    dw JohtoSharedPokecenterRuntimeBlocks
    dw JohtoSharedPokecenterTextPointers
    dw JohtoSharedPokecenterMapScript
    db 0
    dw JohtoGoldenrodPokecenterRuntimeObjects
JohtoGoldenrodPokecenterRuntimeHeaderEnd::
ASSERT JohtoGoldenrodPokecenterRuntimeHeaderEnd - JohtoGoldenrodPokecenterRuntimeHeader == 12
ASSERT BANK(JohtoGoldenrodPokecenterRuntimeHeader) == BANK(JohtoSharedPokecenterRuntimeBlocks)
ASSERT JOHTO_GOLDENROD_POKECENTER_1F_LOCAL_ID == 146

JohtoEcruteakPokecenterRuntimeHeader::
    db JOHTO_POKECENTER
    db JOHTO_SHARED_POKECENTER_HEIGHT, JOHTO_SHARED_POKECENTER_WIDTH
    dw JohtoSharedPokecenterRuntimeBlocks
    dw JohtoSharedPokecenterTextPointers
    dw JohtoSharedPokecenterMapScript
    db 0
    dw JohtoEcruteakPokecenterRuntimeObjects
JohtoEcruteakPokecenterRuntimeHeaderEnd::
ASSERT JohtoEcruteakPokecenterRuntimeHeaderEnd - JohtoEcruteakPokecenterRuntimeHeader == 12
ASSERT BANK(JohtoEcruteakPokecenterRuntimeHeader) == BANK(JohtoSharedPokecenterRuntimeBlocks)
ASSERT JOHTO_ECRUTEAK_POKECENTER_1F_LOCAL_ID == 160

JohtoOlivinePokecenterRuntimeHeader::
    db JOHTO_POKECENTER
    db JOHTO_SHARED_POKECENTER_HEIGHT, JOHTO_SHARED_POKECENTER_WIDTH
    dw JohtoSharedPokecenterRuntimeBlocks
    dw JohtoSharedPokecenterTextPointers
    dw JohtoSharedPokecenterMapScript
    db 0
    dw JohtoOlivinePokecenterRuntimeObjects
JohtoOlivinePokecenterRuntimeHeaderEnd::
ASSERT JohtoOlivinePokecenterRuntimeHeaderEnd - JohtoOlivinePokecenterRuntimeHeader == 12
ASSERT BANK(JohtoOlivinePokecenterRuntimeHeader) == BANK(JohtoSharedPokecenterRuntimeBlocks)
ASSERT JOHTO_OLIVINE_POKECENTER_1F_LOCAL_ID == 30

JohtoCianwoodPokecenterRuntimeHeader::
    db JOHTO_POKECENTER
    db JOHTO_SHARED_POKECENTER_HEIGHT, JOHTO_SHARED_POKECENTER_WIDTH
    dw JohtoSharedPokecenterRuntimeBlocks
    dw JohtoSharedPokecenterTextPointers
    dw JohtoSharedPokecenterMapScript
    db 0
    dw JohtoCianwoodPokecenterRuntimeObjects
JohtoCianwoodPokecenterRuntimeHeaderEnd::
ASSERT JohtoCianwoodPokecenterRuntimeHeaderEnd - JohtoCianwoodPokecenterRuntimeHeader == 12
ASSERT BANK(JohtoCianwoodPokecenterRuntimeHeader) == BANK(JohtoSharedPokecenterRuntimeBlocks)
ASSERT JOHTO_CIANWOOD_POKECENTER_1F_LOCAL_ID == 42

JohtoMahoganyPokecenterRuntimeHeader::
    db JOHTO_POKECENTER
    db JOHTO_SHARED_POKECENTER_HEIGHT, JOHTO_SHARED_POKECENTER_WIDTH
    dw JohtoSharedPokecenterRuntimeBlocks
    dw JohtoSharedPokecenterTextPointers
    dw JohtoSharedPokecenterMapScript
    db 0
    dw JohtoMahoganyPokecenterRuntimeObjects
JohtoMahoganyPokecenterRuntimeHeaderEnd::
ASSERT JohtoMahoganyPokecenterRuntimeHeaderEnd - JohtoMahoganyPokecenterRuntimeHeader == 12
ASSERT BANK(JohtoMahoganyPokecenterRuntimeHeader) == BANK(JohtoSharedPokecenterRuntimeBlocks)
ASSERT JOHTO_MAHOGANY_POKECENTER_1F_LOCAL_ID == 77

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

; Route32 Gold warp 1F #1/#2 both return to outdoor Gold warp #1,
; registered here as Route32 runtime ordinal 3 (the first three stay fixed).
JohtoRoute32PokecenterRuntimeObjects::
    db $0f
    db 2
    db 7, 3, 3, JOHTO_REGISTERED_WARP_SELECTOR
    db 7, 4, 3, JOHTO_REGISTERED_WARP_SELECTOR
    db 0 ; PC/2F remain closed
    db 1
    object SPRITE_NURSE, $3, $1, STAY, DOWN, $1

; Gold Azalea center exits #1/#2 both return to the only active town
; Pokecenter doorway (Azalea outdoor source ordinal 2 / Gold warp #1).
JohtoAzaleaPokecenterRuntimeObjects::
    db $0f
    db 2
    db 7, 3, 2, JOHTO_REGISTERED_WARP_SELECTOR
    db 7, 4, 2, JOHTO_REGISTERED_WARP_SELECTOR
    db 0 ; PC and 2F are deferred
    db 1
    object SPRITE_NURSE, $3, $1, STAY, DOWN, $1

JohtoVioletPokecenterRuntimeObjects::
    db $0f
    db 2
    db 7, 3, 2, JOHTO_REGISTERED_WARP_SELECTOR
    db 7, 4, 2, JOHTO_REGISTERED_WARP_SELECTOR
    db 0 ; no PC storage, 2F or side characters yet
    db 1
    object SPRITE_NURSE, $3, $1, STAY, DOWN, $1

JohtoGoldenrodPokecenterRuntimeObjects::
    db $0f
    db 2
    db 7, 3, 1, JOHTO_REGISTERED_WARP_SELECTOR
    db 7, 4, 1, JOHTO_REGISTERED_WARP_SELECTOR
    db 0 ; no PC storage, 2F or side characters yet
    db 1
    object SPRITE_NURSE, $3, $1, STAY, DOWN, $1

JohtoEcruteakPokecenterRuntimeObjects::
    db $0f
    db 2
    db 7, 3, 4, JOHTO_REGISTERED_WARP_SELECTOR
    db 7, 4, 4, JOHTO_REGISTERED_WARP_SELECTOR
    db 0 ; PC storage / upstairs / side NPCs deferred
    db 1
    object SPRITE_NURSE, $3, $1, STAY, DOWN, $1

JohtoOlivinePokecenterRuntimeObjects::
    db $0f
    db 2
    db 7, 3, 0, JOHTO_REGISTERED_WARP_SELECTOR
    db 7, 4, 0, JOHTO_REGISTERED_WARP_SELECTOR
    db 0 ; PC storage / upstairs / side NPCs deferred
    db 1
    object SPRITE_NURSE, $3, $1, STAY, DOWN, $1

JohtoCianwoodPokecenterRuntimeObjects::
    db $0f
    db 2
    db 7, 3, 0, JOHTO_REGISTERED_WARP_SELECTOR
    db 7, 4, 0, JOHTO_REGISTERED_WARP_SELECTOR
    db 0 ; PC storage / upstairs / side NPCs deferred
    db 1
    object SPRITE_NURSE, $3, $1, STAY, DOWN, $1

JohtoMahoganyPokecenterRuntimeObjects::
    db $0f
    db 2
    db 7, 3, 1, JOHTO_REGISTERED_WARP_SELECTOR
    db 7, 4, 1, JOHTO_REGISTERED_WARP_SELECTOR
    db 0 ; PC storage / upstairs / side NPCs deferred
    db 1
    object SPRITE_NURSE, $3, $1, STAY, DOWN, $1

; Reusable center carpet predicate for the existing Johto warp pipeline.
; E=1 only when standing on an actual Gold exit carpet and pressing DOWN.
; Any LEFT/RIGHT movement on the paired carpets must not trigger a warp;
; other collisions while on them must not leave the center either.
JohtoSharedCenterDownCollision336::
    ld e, 0
    ld a, [wCurLocalMapID]
    cp JOHTO_CHERRYGROVE_POKECENTER_1F_LOCAL_ID
    jr z, .center
    cp JOHTO_ROUTE_32_POKECENTER_1F_LOCAL_ID
    jr z, .center
    cp JOHTO_AZALEA_POKECENTER_1F_LOCAL_ID
    jr z, .center
    cp JOHTO_VIOLET_POKECENTER_1F_LOCAL_ID
    jr z, .center
    cp JOHTO_GOLDENROD_POKECENTER_1F_LOCAL_ID
    jr z, .center
    cp JOHTO_ECRUTEAK_POKECENTER_1F_LOCAL_ID
    jr z, .center
    cp JOHTO_OLIVINE_POKECENTER_1F_LOCAL_ID
    jr z, .center
    cp JOHTO_CIANWOOD_POKECENTER_1F_LOCAL_ID
    jr z, .center
    cp JOHTO_MAHOGANY_POKECENTER_1F_LOCAL_ID
    ret nz
.center
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

