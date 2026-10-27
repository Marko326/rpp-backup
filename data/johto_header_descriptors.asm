; P2-002: region-aware physical map key -> compact slot -> header descriptor.
; D = region, E = stable local map ID. Only MAP_REGION_JOHTO is accepted.
; Return on success: E = dense active slot, D = header ROM bank, HL = header address.
; Return on failure: E = $FF, D = 0, HL = 0. A/flags are volatile.
;
; callab restores the caller's ROM bank; use E/D/HL, never A or carry, as
; output across the far-call boundary. Do not dereference HL until the caller
; explicitly switches to the returned header bank D. In particular, calling
; this routine NEVER makes a still-inactive map playable.
;
; Header pointer and bank live in one descriptor to prevent skew between two
; independent parallel arrays. Slot n corresponds to bytes [3*n .. 3*n+2].
; A row MUST be added only alongside all other map runtime resources, a
; stable-ID map entry, and an increment of NUM_JOHTO_ACTIVE_MAPS.
; P3-001 registers New Bark Town (stable ID 0) and Route 29 (stable ID 1).
JohtoHeaderDescriptors::
    dw JohtoPilotNewBarkRuntimeHeader
    db BANK(JohtoPilotNewBarkRuntimeHeader)
    dw JohtoPilotRoute29RuntimeHeader
    db BANK(JohtoPilotRoute29RuntimeHeader)
    dw JohtoPilotCherrygroveRuntimeHeader
    db BANK(JohtoPilotCherrygroveRuntimeHeader)
JohtoHeaderDescriptorsEnd::
ASSERT JohtoHeaderDescriptorsEnd - JohtoHeaderDescriptors == NUM_JOHTO_ACTIVE_MAPS * JOHTO_HEADER_DESCRIPTOR_BYTES
ASSERT JOHTO_HEADER_DESCRIPTOR_BYTES == 3

ResolveJohtoHeaderDescriptor::
	ld a, d
	cp MAP_REGION_JOHTO
	jr nz, .invalid
	call GetJohtoActiveSlot ; E=slot / $ff, BC/HL/D preserved
	ld a, e
	cp JOHTO_INVALID_ACTIVE_SLOT
	jr z, .invalid
	; Guard against any malformed non-dense slot even if the mapper changes.
	cp NUM_JOHTO_ACTIVE_MAPS
	jr nc, .invalid

	push bc
	ld l, e
	ld h, 0
	ld c, e
	ld b, 0
	add hl, hl ; 2 * slot (16-bit)
	add hl, bc ; 3 * slot (16-bit, safe above slot 85)
	ld bc, JohtoHeaderDescriptors
	add hl, bc
	; Combined 3B descriptor: [lo, hi, bank].
	ld a, [hli]
	push af ; low byte of header pointer
	ld a, [hli] ; high byte of header pointer
	ld d, [hl] ; ROM bank of header
	ld h, a
	pop af
	ld l, a
	pop bc
	ret
.invalid
	ld e, JOHTO_INVALID_ACTIVE_SLOT
	ld d, 0
	ld hl, 0
	ret
