HandleLedges:
	ld a, [wd736]
	bit 6, a ; already jumping down ledge
	ret nz
	ld a, [wCurMapTileset]
	cp JOHTO
	jr z, .johto
	and a ; Kanto OVERWORLD
	ret nz
	predef GetTileAndCoordsInFrontOfPlayer
	ld a, [wSpriteStateData1 + 9]
	ld b, a
	aCoord 8, 9
	ld c, a
	ld a, [wTileInFrontOfPlayer]
	ld d, a
	ld hl, LedgeTiles
.loop
	ld a, [hli]
	cp $ff
	ret z
	cp b
	jr nz, .nextLedgeTile1
	ld a, [hli]
	cp c
	jr nz, .nextLedgeTile2
	ld a, [hli]
	cp d
	jr nz, .nextLedgeTile3
	ld a, [hl]
	ld e, a
	jr .foundMatch
.nextLedgeTile1
	inc hl
.nextLedgeTile2
	inc hl
.nextLedgeTile3
	inc hl
	jr .loop

; Gold's HOP_* label belongs to the safe cliff-lip (launch) cell.
; RPP checks the front tile; converter records the middle barrier cell.
; Use the same .foundMatch and two-step jump used by Kanto.
.johto
	ld a, [wCurMap]
	cp JOHTO_ROUTE_29
	ret nz
	predef GetTileAndCoordsInFrontOfPlayer ; D=y, E=x, next cell
	ld a, [wSpriteStateData1 + 9]
	ld b, a
	ld hl, JohtoRoute29LedgeRules
.johtoLoop
	ld a, [hli] ; barrier x
	cp $ff
	ret z
	cp e
	jr nz, .skipX
	ld a, [hli] ; barrier y
	cp d
	jr nz, .skipY
	ld a, [hli] ; required facing
	cp b
	jr nz, .skipFacing
	ld a, [hli] ; required joypad input
	ld e, a
	jr .foundMatch
.skipX
	inc hl ; y
.skipY
	inc hl ; facing
.skipFacing
	inc hl ; input
	jr .johtoLoop
.foundMatch
	ld a, [hJoyHeld]
	and e
	ret z
	ld a, $ff
	ld [wJoyIgnore], a
	ld hl, wd736
	set 6, [hl] ; jumping down ledge
	call StartSimulatingJoypadStates
	ld a, e
	ld [wSimulatedJoypadStatesEnd], a
	ld [wSimulatedJoypadStatesEnd + 1], a
	; MAP-5.62.133: this initial real direction press already starts
	; the first step in CollisionCheckOnLand. Kanto's original pair
	; rules keep two ADDITIONAL simulated steps. The Johto converter
	; records a one-cell barrier and a landing TWO cells from launch:
	; simulate only ONE additional step there (total = initial + 1).
	ld a, [wCurMapTileset]
	cp JOHTO
	ld a, $2
	jr nz, .setJumpStepCount
	dec a
.setJumpStepCount
	ld [wSimulatedJoypadStatesIndex], a
	call LoadHoppingShadowOAM
	ld a, SFX_LEDGE
	call PlaySound
	ret

	; (player direction) (tile player standing on) (ledge tile) (input required)
LedgeTiles:
	db SPRITE_FACING_DOWN, $2C,$37,D_DOWN
	db SPRITE_FACING_DOWN, $39,$36,D_DOWN
	db SPRITE_FACING_DOWN, $39,$37,D_DOWN
	db SPRITE_FACING_LEFT, $2C,$27,D_LEFT
	db SPRITE_FACING_LEFT, $39,$27,D_LEFT
	db SPRITE_FACING_RIGHT,$2C,$0D,D_RIGHT
	db SPRITE_FACING_RIGHT,$2C,$1D,D_RIGHT
	db SPRITE_FACING_RIGHT,$39,$0D,D_RIGHT
	db $FF

; Route 29 bridge: Gold marks the safe cliff lip as HOP_*; its NEXT
; 16x16 cell is the intermediary barrier. Many right-facing barriers are
; visually $05 in Red and would otherwise be freely walkable backwards.
; Only HandleLedges can cross this cell, via the existing Kanto hop action.
; Block any normal step into a listed barrier (reverse OR sideways).
; Return carry on collision; preserve the caller's tile-pair HL externally.
CheckJohtoReverseLedgeCollision:
	ld a, [wCurMap]
	cp JOHTO_ROUTE_29
	jr nz, .pass
	predef GetTileAndCoordsInFrontOfPlayer ; D = front y, E = front x
	ld hl, JohtoRoute29LedgeRules
.loop
	ld a, [hli] ; barrier x
	cp $ff
	jr z, .pass
	cp e
	jr nz, .skipX
	ld a, [hli] ; barrier y
	cp d
	jr nz, .skipY
	; The allowed approach was handled by HandleLedges first: its
	; bit 6 causes CheckForJumpingAndTilePairCollisions to return early.
	scf
	ret
.skipX
	inc hl ; y
.skipY
	inc hl ; facing
	inc hl ; input
	jr .loop
.pass
	and a
	ret

INCLUDE "data/generated/johto_route29_ledges.asm"

LoadHoppingShadowOAM:
	ld hl, vChars1 + $7f0
	ld de, LedgeHoppingShadow
	lb bc, BANK(LedgeHoppingShadow), (LedgeHoppingShadowEnd - LedgeHoppingShadow) / $8
	call CopyVideoDataDouble
	ld a, $9
	lb bc, $54, $48 ; b, c = y, x coordinates of shadow
	ld de, LedgeHoppingShadowOAM
	call WriteOAMBlock
	ret

LedgeHoppingShadow:
	INCBIN "gfx/ledge_hopping_shadow.1bpp"
LedgeHoppingShadowEnd:

LedgeHoppingShadowOAM:
	db $FF,$10,$FF,$20
	db $FF,$40,$FF,$60
