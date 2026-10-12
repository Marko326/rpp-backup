; REG-5.62.118: small ROM0 adapter for the existing Bank $03 table.
; Called from the ROMX region resolver: A = legacy ID, returns its bank in A.
; All bank changes and restoration happen while executing in ROM0.
SECTION "Region Kanto Header Bank Adapter", ROM0
GetKantoMapHeaderBank::
	push bc
	ld c, a
	ld b, 0
	ld a, [H_LOADEDROMBANK]
	push af
	ld a, BANK(MapHeaderBanks)
	ld [H_LOADEDROMBANK], a
	ld [MBC1RomBank], a
	ld hl, MapHeaderBanks
	add hl, bc
	ld a, [hl]
	ld c, a
	pop af
	ld [H_LOADEDROMBANK], a
	ld [MBC1RomBank], a
	ld a, c
	pop bc
	ret
