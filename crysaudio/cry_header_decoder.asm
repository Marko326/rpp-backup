; CRY-5.32.01: decoder for the fixed 4-byte cry header table.
; INPUT:
;   DE = zero-based species index (0..$fe)
; OUTPUT:
;   DE = cry id
;   CryPitch / CryEcho / CryLength = decoded parameters
; The caller has already switched to BANK(CryHeaders).

DecodePackedCryHeader::
	; Preserve a 1-based species key for the sparse full-width override table.
	ld a, e
	inc a
	ld b, a

	; Fixed 4-byte table: offset = index * 4.
	sla e
	rl d
	sla e
	rl d
	ld hl, CryHeaders
	add hl, de

	ld a, [hli]
	ld c, a
	and $7f
	cp $7f
	jr z, .override

	; Compact entry.
	ld e, a
	ld d, 0
	ld a, [hli]
	ld [CryPitch], a
	ld a, [hli]
	ld [CryEcho], a
	ld a, [hl]
	ld [CryLength], a
	ld a, c
	and $80
	rlca
	ld [CryLength + 1], a
	ret

.override
	ld hl, CryHeaderOverrides
.loop
	ld a, [hli]
	and a
	jr z, .missing
	cp b
	jr z, .found
	ld de, 6 ; skip cry id, pitch, echo, length
	add hl, de
	jr .loop

.found
	ld e, [hl]
	inc hl
	ld d, [hl]
	inc hl
	ld a, [hli]
	ld [CryPitch], a
	ld a, [hli]
	ld [CryEcho], a
	ld a, [hli]
	ld [CryLength], a
	ld a, [hl]
	ld [CryLength + 1], a
	ret

.missing
	; Assembly-time generation makes this path unreachable for a valid marker.
	; Fail closed to an all-zero cry rather than reading unrelated ROM data.
	ld de, 0
	xor a
	ld [CryPitch], a
	ld [CryEcho], a
	ld [CryLength], a
	ld [CryLength + 1], a
	ret
