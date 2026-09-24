Route8GateScript:
Route7GateScript:
Route6GateScript:
Route5GateScript:
	call EnableAutoTextBoxDrawing
	call SaffronGateGetData
	ld a, [hli]
	ld e, a
	ld a, [hli]
	ld d, a
	ld a, [de]
	and a
	jr nz, SaffronGateWaitForPushback

	ld a, [wd728]
	bit 6, a
	ret nz
	inc hl
	ld a, [hli]
	ld c, a
	ld a, [hli]
	ld b, a
	push hl
	ld h, b
	ld l, c
	call ArePlayerCoordsInArray
	pop hl
	ret nc
	ld a, [hli]
	ld [wPlayerMovingDirection], a
	xor a
	ld [hJoyHeld], a
	push de
	push hl
	callba RemoveGuardDrink
	pop hl
	pop de
	ld a, [$ffdb]
	and a
	jr nz, .gaveDrink

	ld a, $2
	ld [hSpriteIndexOrTextID], a
	push hl
	push de
	call DisplayTextID
	pop de
	pop hl
	ld a, [hl]
	call SaffronGateStartPushback
	ld a, $1
	ld [de], a
	ret

.gaveDrink
	ld a, $3
	ld [hSpriteIndexOrTextID], a
	call DisplayTextID
	ld hl, wd728
	set 6, [hl]
	ret

SaffronGateWaitForPushback:
	ld a, [wSimulatedJoypadStatesIndex]
	and a
	ret nz
	push hl
	push de
	call Delay3
	pop de
	pop hl
	xor a
	ld [wJoyIgnore], a
	ld [de], a
	bit 0, [hl]
	ret z
; Route 7's original script also cleared the generic map-script index here.
	ld [wCurMapScript], a
	ret

SaffronGateStartPushback:
; a = direction that sends the player back toward the route they entered from
	ld [wSimulatedJoypadStatesEnd], a
	ld a, $1
	ld [wSimulatedJoypadStatesIndex], a
	jp StartSimulatingJoypadStates

SaffronGateGetData:
; Keep map selection explicit so another gate can be added without depending on
; map-ID spacing or changing the shared state machine.
	ld a, [wCurMap]
	cp ROUTE_6_GATE
	jr z, .route6
	cp ROUTE_7_GATE
	jr z, .route7
	cp ROUTE_8_GATE
	jr z, .route8
	ld hl, SaffronGateRoute5Data
	ret
.route6
	ld hl, SaffronGateRoute6Data
	ret
.route7
	ld hl, SaffronGateRoute7Data
	ret
.route8
	ld hl, SaffronGateRoute8Data
	ret

; current-script pointer, flags, trigger coordinates, facing, pushback direction
; flag bit 0 preserves Route 7's original wCurMapScript reset after movement.
SaffronGateRoute5Data:
	dw wRoute5GateCurScript
	db 0
	dw .Coords
	db PLAYER_DIR_LEFT, D_UP
.Coords
	db 3, 3
	db 3, 4
	db $ff

SaffronGateRoute6Data:
	dw wRoute6GateCurScript
	db 0
	dw .Coords
	db PLAYER_DIR_RIGHT, D_DOWN
.Coords
	db 2, 3
	db 2, 4
	db $ff

SaffronGateRoute7Data:
	dw wRoute7GateCurScript
	db 1
	dw .Coords
	db PLAYER_DIR_UP, D_LEFT
.Coords
	db 3, 3
	db 4, 3
	db $ff

SaffronGateRoute8Data:
	dw wRoute8GateCurScript
	db 0
	dw .Coords
	db PLAYER_DIR_LEFT, D_RIGHT
.Coords
	db 3, 2
	db 4, 2
	db $ff

Route5GateTextPointers:
	dw Route5GateText1
	dw Route5GateText2
	dw Route5GateText3

Route8GateText1:
Route7GateText1:
Route6GateText1:
Route5GateText1:
	TX_ASM
	ld a, [wd728]
	bit 6, a
	jr nz, .alreadyAllowed
	call SaffronGateGetData
	ld a, [hli]
	ld e, a
	ld a, [hli]
	ld d, a
	inc hl
	inc hl
	inc hl
	inc hl
	push hl
	push de
	callba RemoveGuardDrink
	pop de
	pop hl
	ld a, [$ffdb]
	and a
	jr nz, .gaveDrink
	push hl
	push de
	ld hl, Route5GateText2
	call PrintText
	pop de
	pop hl
	ld a, [hl]
	call SaffronGateStartPushback
	ld a, $1
	ld [de], a
	jp TextScriptEnd
.gaveDrink
	ld hl, Route5GateText3
	call PrintText
	ld hl, wd728
	set 6, [hl]
	jp TextScriptEnd
.alreadyAllowed
	ld hl, SaffronGateText_1dff6
	call PrintText
	jp TextScriptEnd

Route8GateText2:
Route7GateText2:
Route6GateText2:
Route5GateText2:
	TX_FAR _SaffronGateText_1dfe7
	db "@"

Route8GateText3:
Route7GateText3:
Route6GateText3:
Route5GateText3:
	TX_FAR _SaffronGateText_8aaa9
	TX_SFX_KEY_ITEM
	TX_FAR _SaffronGateText_1dff1
	db "@"

SaffronGateText_1dff6:
	TX_FAR _SaffronGateText_1dff6
	db "@"
