; HOME-5.62.122: relocate legacy map Header pointer table to Bank $40.
; Returns HL = legacy Kanto map header pointer.
; Input: E = legacy map id (callab/Bankswitch overwrites A).
; Output: HL = header pointer; the far-call restores the map ROM bank.
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
