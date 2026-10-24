; NAME-5.29.01: block-indexed lookup for packed Pokémon names.
; Input: wd11e = species ID (1..NUM_POKEMON).
; Output: wcd6d contains the expanded main-charmap @-terminated name,
;         DE = wcd6d (legacy GetMonName contract).
;
; Important: do not pass the species in A through callba. Bankswitch uses A
; for the destination bank before entering this routine, so the stable input
; lives in wd11e just like the legacy GetMonName path.
GetPackedMonName::
	ld a,[wd11e]
	dec a
	ld c,a
	and $0f
	ld b,a ; index inside 16-species block
	ld a,c
	and $f0
	swap a ; block index
	add a ; 2-byte block pointer
	ld e,a
	ld d,0
	ld hl,MonsterNameBlockPointers
	add hl,de
	ld a,[hli]
	ld h,[hl]
	ld l,a

.seekEntry
	ld a,b
	and a
	jr z,.foundEntry
.seekTerminator
	ld a,[hli]
	cp "@"
	jr nz,.seekTerminator
	dec b
	jr .seekEntry

.foundEntry
	ld d,h
	ld e,l ; DE = packed entry start
.findEnd
	ld a,[hli]
	cp "@"
	jr nz,.findEnd

	; HL is one byte past @. Store source metadata before DecodePackedName
	; reuses wcd6d as packed-input staging and expanded-output scratch.
	ld a,e
	ld [wcd6d],a
	ld a,d
	ld [wcd6d + 1],a
	ld a,BANK(MonsterNames)
	ld [wcd6d + 2],a
	ld a,l
	sub e
	ld c,a
	ld a,h
	sbc d
	jr nz,.invalidLength
	ld a,c
	ld [wcd6d + 3],a

	; Keep the existing shared decoder in its original bank. It intentionally
	; leaves DE advanced through the scratch window, so restore the legacy
	; GetMonName return pointer explicitly afterwards.
	callba DecodePackedName
	ld de,wcd6d
	ret

.invalidLength
	; A single Pokémon name can never legitimately exceed 255 packed bytes.
	; Fail safely with an empty string if the table is ever corrupted.
	ld de,wcd6d
	ld a,"@"
	ld [de],a
	ret
