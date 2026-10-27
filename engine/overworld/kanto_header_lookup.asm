; JOHTO-P1b: Kanto map header pointer resolver in expansion ROM bank $40.
; Input: E = legacy Kanto map ID (A is clobbered by callab/Bankswitch).
; Output: HL = original map header pointer, with original map bank restored
; by Bankswitch before the caller dereferences [HL]. BC is clobbered.
GetKantoMapHeaderPointer::
	ld l, e
	ld h, 0
	add hl, hl
	ld bc, MapHeaderPointers
	add hl, bc
	ld a, [hli]
	ld h, [hl]
	ld l, a
	ret
