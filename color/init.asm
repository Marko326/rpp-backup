InitGbcMode: ; Sets double speed & clears extra memory
	; Deselect both joypad key groups before executing STOP.
	; The boot ROM may leave rJOYP selecting a key group, and a held
	; button can interfere with the early CGB double-speed switch.
	ld a, 1 << 4 + 1 << 5
	ld [rJOYP], a

	; Allow the joypad input lines to settle before switching speed.
	; This follows the repeated-read style used by red++ ReadJoypad.
	rept 6
		ld a, [rJOYP]
	endr

	; Request CGB double-speed mode only after rJOYP is normalized.
	ld a, $01
	ld [rKEY1], a
	stop
	nop ; Harmless instruction immediately after the speed switch.

	; Clear memory (banks 2-7)
ClearGbcMemory:
	ld d,7
.clearBank
	ld a,d
	ld [rSVBK],a
	xor a
	ld hl, W2_BgPaletteData
	ld bc, $0f00 ; Leave a bit of space for the stack
	call FillMemory
	dec d
	ld a,d
	dec a
	jr nz,.clearBank

	xor a
	ld [rSVBK],a
	ret
