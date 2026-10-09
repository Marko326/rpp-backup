AnimatePartyMon_ForceSpeed1:
	; ICO-5.62.56: bit 7 identifies the naming screen's single-icon case.
	ld a, $80
	ld [wCurrentMenuItem], a
	ld b, 0
	ld a, 1
	jr GetAnimationSpeed

; wPartyMenuHPBarColors contains the party mon's health bar colors
; 0: green
; 1: yellow
; 2: red
AnimatePartyMon:
	ld hl, wPartyMenuHPBarColors
	ld a, [wCurrentMenuItem]
	ld c, a
	ld b, 0
	add hl, bc
	ld a, [hl]

GetAnimationSpeed:
	ld c, a
	ld hl, PartyMonSpeeds
	add hl, bc
	ld a, [wOnSGB]
	xor $1
	add [hl]
	ld c, a
	add a
	ld b, a
	ld a, [wAnimCounter]
	and a
	jr z, .resetSprites
	cp c
	jr z, .animateSprite
.incTimer
	inc a
	cp b
	jr nz, .skipResetTimer
	xor a ; reset timer
.skipResetTimer
	ld [wAnimCounter], a
	jp DelayFrame
.resetSprites
	push bc
	ld hl, wMonPartySpritesSavedOAM
	ld de, wOAMBuffer
	ld bc, $60
	call CopyData
	pop bc
	xor a
	jr .incTimer
.animateSprite
	push bc
	ld hl, wOAMBuffer + $02 ; OAM tile id
	ld bc, $10
	ld a, [wCurrentMenuItem]
	and $7f ; bit 7 is set only by naming-screen animation
	call AddNTimes
	push hl
	ld a, [wCurrentMenuItem]
	bit 7, a
	jr nz, .singleSpecies
	ld c, a
	ld b, 0
	ld hl, wPartySpecies
	add hl, bc
	ld a, [hl]
	jr .checkSpriteKind
.singleSpecies
	ld a, [wcf91]
.checkSpriteKind
	call GetPartyMonSpriteID
	pop hl
	cp SPRITE_BALL_M
	jr z, .editCoords
	cp SPRITE_HELIX
	jr z, .editCoords
	ld c, $4 ; second frame is four tiles after frame one
	jr .editTileIDS
; Ball and Helix only shake up and down.
.editCoords
	dec hl
	dec hl ; back from OAM tile id to Y
	ld c, 1
; otherwise, load a second sprite frame
.editTileIDS
	ld b, $4
	ld de, $4
.loop
	ld a, [hl]
	add c
	ld [hl], a
	add hl, de
	dec b
	jr nz, .loop
	pop bc
	ld a, c
	jr .incTimer

; Party mon animations cycle between 2 frames.
; The members of the PartyMonSpeeds array specify the number of V-blanks
; that each frame lasts for green HP, yellow HP, and red HP in order.
; On the naming screen, the yellow HP speed is always used.
PartyMonSpeeds:
	db 5, 16, 32

; ICO-5.62.56: party icon artwork is stored by class in ROM. Party view
; streams up to six icons into eight 8x8 tiles per slot, frame 2 at +4 tiles.
; A single-icon screen also duplicates frame 2 at +$40 tiles because the
; existing trade animation toggles its tile IDs with XOR $40.
LoadMonPartySpriteGfx:
	call DisableLCD
	ld a, [wcf91]
	call GetPartyMonSpriteID
	ld de, vSprites
	call LoadPartyIconAtDE
	ld hl, vSprites + $40
	ld de, vSprites + $400
	ld bc, $40
	call CopyData
	; ICO-5.62.56: retain trade's independent circle/oval graphic frames.
	ld hl, PartyIconTradeCircleGfx
	ld de, vSprites + $380
	ld bc, $40
	ld a, BANK(PartyIconTradeCircleGfx)
	call FarCopyData2
	ld hl, PartyIconTradeCircleGfx + $40
	ld de, vSprites + $780
	ld bc, $40
	ld a, BANK(PartyIconTradeCircleGfx)
	call FarCopyData2
	jp EnableLCD

LoadAnimSpriteGfx:
; Load animated sprite tile patterns into VRAM during V-blank. hl is the address
; of an array of structures that contain arguments for CopyVideoData and a is
; the number of structures in the array.
	ld bc, $0
.loop
	push af
	push bc
	push hl
	add hl, bc
	ld a, [hli]
	ld e, a
	ld a, [hli]
	ld d, a
	ld a, [hli]
	ld c, a
	ld a, [hli]
	ld b, a
	ld a, [hli]
	ld h, [hl]
	ld l, a
	call CopyVideoData
	pop hl
	pop bc
	ld a, $6
	add c
	ld c, a
	pop af
	dec a
	jr nz, .loop
	ret

LoadMonPartySpriteGfxWithLCDDisabled:
	call DisableLCD
LoadMonPartySpriteGfxLCDOff::
	xor a
	ld [hPartyMonIndex], a
.loop
	ld a, [hPartyMonIndex]
	ld c, a
	ld b, 0
	ld hl, wPartySpecies
	add hl, bc
	ld a, [hl]
	cp $ff
	jr z, .done
	call GetPartyMonSpriteID
	push af
	ld a, [hPartyMonIndex]
	add a
	ld c, a
	ld b, 0
	ld hl, PartyIconVRAMSlots
	add hl, bc
	ld a, [hli]
	ld e, a
	ld d, [hl]
	pop af
	call LoadPartyIconAtDE
	; Fresh Party icon upload puts each member in its original VRAM slot.
	ld a, [hPartyMonIndex]
	ld c, a
	ld b, 0
	ld hl, wPartyIconSlotMap
	add hl, bc
	ld [hl], a
	ld hl, hPartyMonIndex
	inc [hl]
	ld a, [hl]
	cp 6
	jr c, .loop
.done
	xor a
	ld [hPartyMonIndex], a
	jp EnableLCD

; A = class ID, DE = LCD-off VRAM destination (8 tiles, $80 bytes).
; The three-byte source records let later versions add icons in any ROM bank
; without increasing per-party VRAM or changing existing class IDs.
LoadPartyIconAtDE:
	push de
	ld c, a
	ld b, 0
	ld h, b
	ld l, c
	add hl, bc
	add hl, bc
	ld bc, PartyIconSourcePointers
	add hl, bc
	ld a, [hli]
	ld e, a
	ld a, [hli]
	ld d, a
	ld a, [hl]
	ld h, d
	ld l, e
	pop de
	ld bc, $80
	jp FarCopyData2

PartyIconVRAMSlots:
	dw vSprites + $000, vSprites + $080, vSprites + $100
	dw vSprites + $180, vSprites + $200, vSprites + $280

; The first 14 templates reproduce 5.62.55 at the pixel level. Entries may
; be added with 'dw label / db BANK(label)' alongside one new sprite constant.
PartyIconSourcePointers:
	dw PartyIconRuntimeAtlas + $000 ; 00 MON
	db BANK(PartyIconRuntimeAtlas)
	dw PartyIconRuntimeAtlas + $080 ; 01 BALL_M
	db BANK(PartyIconRuntimeAtlas)
	dw PartyIconRuntimeAtlas + $100 ; 02 HELIX
	db BANK(PartyIconRuntimeAtlas)
	dw PartyIconRuntimeAtlas + $180 ; 03 FAIRY
	db BANK(PartyIconRuntimeAtlas)
	dw PartyIconRuntimeAtlas + $200 ; 04 BIRD_M
	db BANK(PartyIconRuntimeAtlas)
	dw PartyIconRuntimeAtlas + $280 ; 05 WATER
	db BANK(PartyIconRuntimeAtlas)
	dw PartyIconRuntimeAtlas + $300 ; 06 BUG
	db BANK(PartyIconRuntimeAtlas)
	dw PartyIconRuntimeAtlas + $380 ; 07 GRASS
	db BANK(PartyIconRuntimeAtlas)
	dw PartyIconRuntimeAtlas + $400 ; 08 SNAKE
	db BANK(PartyIconRuntimeAtlas)
	dw PartyIconRuntimeAtlas + $480 ; 09 QUADRUPED
	db BANK(PartyIconRuntimeAtlas)
	dw PartyIconRuntimeAtlas + $500 ; 10 PIKACHU_YELLOW
	db BANK(PartyIconRuntimeAtlas)
	dw PartyIconRuntimeAtlas + $580 ; 11 STARYU_GS
	db BANK(PartyIconRuntimeAtlas)
	dw PartyIconRuntimeAtlas + $600 ; 12 GHOST_GS
	db BANK(PartyIconRuntimeAtlas)
	dw PartyIconRuntimeAtlas + $680 ; 13 BAT_GS
	db BANK(PartyIconRuntimeAtlas)
	; ICO-5.62.58: Gen II legendary icons use full, asymmetric frames.
	dw LugiaGoldPartyIcon          ; 14 LUGIA_GS
	db BANK(LugiaGoldPartyIcon)
	dw HoOhGoldPartyIcon           ; 15 HO_OH_GS
	db BANK(HoOhGoldPartyIcon)

	; ICO-5.62.59: targeted Gold icons, source from each original 16x32 double frame.
	dw GoldIconBulbasaur             ; 16 BULBASAUR_GS
	db BANK(GoldIconBulbasaur)
	dw GoldIconCharmander            ; 17 CHARMANDER_GS
	db BANK(GoldIconCharmander)
	dw GoldIconBigmon                ; 18 BIGMON_GS
	db BANK(GoldIconBigmon)
	dw GoldIconSquirtle              ; 19 SQUIRTLE_GS
	db BANK(GoldIconSquirtle)
	dw GoldIconGyarados              ; 20 GYARADOS_GS
	db BANK(GoldIconGyarados)
	dw GoldIconSnorlax               ; 21 SNORLAX_GS
	db BANK(GoldIconSnorlax)
	dw GoldIconSlowpoke              ; 22 SLOWPOKE_GS
	db BANK(GoldIconSlowpoke)
	dw GoldIconLapras                ; 23 LAPRAS_GS
	db BANK(GoldIconLapras)
	dw GoldIconGeodude               ; 24 GEODUDE_GS
	db BANK(GoldIconGeodude)
	dw GoldIconPoliwag               ; 25 POLIWAG_GS
	db BANK(GoldIconPoliwag)

	; ICO-5.62.60: distinct Gold menu icons, 16x32 double frame.
	dw GoldIconJigglypuff           ; 26 JIGGLYPUFF_GS
	db BANK(GoldIconJigglypuff)
	dw GoldIconDiglett              ; 27 DIGLETT_GS
	db BANK(GoldIconDiglett)
	dw GoldIconJellyfish            ; 28 JELLYFISH_GS
	db BANK(GoldIconJellyfish)
	dw GoldIconFighter              ; 29 FIGHTER_GS
	db BANK(GoldIconFighter)

	; ICO-5.62.61: Gen I/II mixed-class refinement; original Gold two-frame art.
	dw GoldIconShell                ; 30 SHELL_GS
	db BANK(GoldIconShell)
	dw GoldIconCaterpillar          ; 31 CATERPILLAR_GS
	db BANK(GoldIconCaterpillar)
	dw GoldIconMoth                 ; 32 MOTH_GS
	db BANK(GoldIconMoth)
	dw GoldIconBlob                 ; 33 BLOB_GS
	db BANK(GoldIconBlob)

	; ICO-5.62.62: selected Oddish/Fish sprites; Clefairy reuses Gen I Fairy.
	dw GoldIconOddish               ; 34 ODDISH_GS
	db BANK(GoldIconOddish)
	dw GoldIconFish                 ; 35 FISH_GS
	db BANK(GoldIconFish)
PartyIconSourcePointersEnd:
PARTY_ICON_CLASS_COUNT EQU (PartyIconSourcePointersEnd - PartyIconSourcePointers) / 3
IF PARTY_ICON_CLASS_COUNT != SPRITE_FISH_GS + 1
	fail "Party icon source table is missing a shipped class"
ENDC

WriteMonPartySpriteOAMByPartyIndex:
; Graphics stay in their original VRAM slots when Party members swap.
	push hl
	push de
	push bc
	ld a, [hPartyMonIndex]
	ld e, a
	ld d, 0
	ld hl, wPartyIconSlotMap
	add hl, de
	ld a, [hl]
	add a
	add a
	add a
	ld [wOAMBaseTile], a
	call WriteMonPartySpriteOAM
	pop bc
	pop de
	pop hl
	ret

SwapPartyIconSlots:
; ICO-5.62.57: exchange only OAM tile-slot mappings after party data swap.
; Both normal and SELECT swap reach SwitchPartyMon; no LCD/VRAM reload.
; The two menu indices are zero-based; each maps to the slot loaded on entry.
	ld a, [wSwappedMenuItem]
	ld e, a
	ld d, 0
	ld hl, wPartyIconSlotMap
	add hl, de
	push hl
	ld a, [wCurrentMenuItem]
	ld e, a
	ld hl, wPartyIconSlotMap
	add hl, de
	ld b, [hl]
	pop de
	ld a, [de]
	ld [hl], a
	ld a, b
	ld [de], a
	ret

WriteMonPartySpriteOAMBySpecies:
; Naming/trade display exactly one icon at base tile zero.
	xor a
	ld [hPartyMonIndex], a
	ld [wOAMBaseTile], a
	jr WriteMonPartySpriteOAM

; ICO-5.62.56: retired an old unused loader that indexed the fixed-atlas
; structure incorrectly. It was not referenced by any menu or trade caller.
WriteMonPartySpriteOAM:
; All runtime entries are stored as complete 4-tile 16x16 frames. The source
; art is unchanged; mirrored appearances are normalized only in the atlas.
	ld c, $10
	ld h, wOAMBuffer / $100
	ld a, [hPartyMonIndex]
	swap a
	ld l, a
	add $10
	ld b, a
	call WriteAsymmetricMonPartySpriteOAM
	ld hl, wOAMBuffer
	ld de, wMonPartySpritesSavedOAM
	ld bc, $60
	jp CopyData

GetPartyMonSpriteID:
; A = internal species ID. IndexToPokedex returns the contiguous 1-based
; Pokédex position in wd11e; use the one-byte class mapping directly.
	ld [wd11e], a
	predef IndexToPokedex
	ld a, [wd11e]
	and a
	jr z, .fallback
	cp 209
	jr nc, .fallback
	dec a
	ld e, a
	ld d, 0
	ld hl, MonPartyData
	add hl, de
	ld a, [hl]
	cp PARTY_ICON_CLASS_COUNT
	ret c
.fallback
	xor a ; safe default for invalid Pokédex or missing icon imports
	ret

INCLUDE "data/mon_party_sprites.asm"
