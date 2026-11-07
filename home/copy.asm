SECTION "Home Far Copy Data", ROM0

FarCopyData::
; Copy bc bytes from a:hl to de.
	ld [wBuffer], a
	ld a, [H_LOADEDROMBANK]
	push af
	ld a, [wBuffer]
	ld [H_LOADEDROMBANK], a
	ld [MBC1RomBank], a
	call CopyData
	pop af
	ld [H_LOADEDROMBANK], a
	ld [MBC1RomBank], a
	ret

SECTION "Home Copy Data", ROM0

CopyData::
; REF-350 / DOR-1.17B: while an ordinary door destination is loading with
; the LCD enabled, gate only VRAM destinations ($8000-$9fff) to safe LCD modes.
; All non-VRAM copies and all legacy LCD-off loads retain the original fast path.
	ldh a, [hMapLoadVRAMSafeFlag]
	and a
	jr z, .fast
	ld a, d
	cp $80
	jr c, .fast
	cp $a0
	jr nc, .fast
.safe
	di
.waitVRAM
	ld a, [rSTAT]
	and %10 ; modes 0 and 1 permit VRAM writes
	jr nz, .waitVRAM
	ld a, [hli]
	ld [de], a
	inc de
	dec bc
	ei
	ld a, c
	or b
	jr nz, .safe
	ret
.fast
	ld a, [hli]
	ld [de], a
	inc de
	dec bc
	ld a, c
	or b
	jr nz, .fast
	ret

SECTION "Home Far Copy Data 2", ROM0

FarCopyData2::
; Identical to FarCopyData, but uses $ff8b
; as temp space instead of wBuffer.
	ld [$ff8b],a
	ld a,[H_LOADEDROMBANK]
	push af
	ld a,[$ff8b]
	ld [H_LOADEDROMBANK],a
	ld [MBC1RomBank],a
	call CopyData
	pop af
	ld [H_LOADEDROMBANK],a
	ld [MBC1RomBank],a
	ret
