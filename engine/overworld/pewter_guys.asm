PewterGuys:
	ld hl, wSimulatedJoypadStatesEnd
	ld a, [wSimulatedJoypadStatesIndex]
	dec a ; this decrement causes it to overwrite the last byte before $FF in the list
	ld [wSimulatedJoypadStatesIndex], a
	ld d, 0
	ld e, a
	add hl, de
	ld d, h
	ld e, l
	; PWT-5.40.03: only the Gym guide still uses this positioning helper.
	ld hl, PewterGymGuyCoords
	ld a, [wYCoord]
	ld b, a
	ld a, [wXCoord]
	ld c, a
.findMatchingCoordsLoop
	ld a, [hli]
	cp b
	jr nz, .nextEntry1
	ld a, [hli]
	cp c
	jr nz, .nextEntry2
	ld a, [hli]
	ld h, [hl]
	ld l, a
.copyMovementDataLoop
	ld a, [hli]
	cp $ff
	ret z
	ld [de], a
	inc de
	push hl
	ld hl, wSimulatedJoypadStatesIndex
	; 60FPS: zero is a one-frame pause marker, so duplicate it to preserve
	; the original scripted pause duration after the overworld rate doubles.
	and a
	jr nz, .notWaitIndicator
	ld [de], a
	inc de
	inc [hl]
.notWaitIndicator
	inc [hl]
	pop hl
	jr .copyMovementDataLoop
.nextEntry1
	inc hl
.nextEntry2
	inc hl
	inc hl
	jr .findMatchingCoordsLoop

; these are the five coordinates which trigger the gym guy and pointers to
; different movements for the player to make to get positioned before the
; main movement
; $00 is a pause
PewterGymGuyCoords:
	db 16, 34
	dw .one
	db 17, 35
	dw .two
	db 18, 37
	dw .three
	db 19, 37
	dw .four
	db 17, 36
	dw .five

.one
	db D_LEFT, D_DOWN, D_DOWN, D_RIGHT, $ff
.two
	db D_LEFT, D_DOWN, D_RIGHT, D_LEFT, $ff
.three
	db D_LEFT, D_LEFT, D_LEFT, $00, $00, $00, $00, $00, $00, $00, $00, $ff
.four
	db D_LEFT, D_LEFT, D_UP, D_LEFT, $ff
.five
	db D_LEFT, D_DOWN, D_LEFT, $00, $00, $00, $00, $00, $00, $00, $00, $ff
