; MOVE-5.62.169: Bill's PC and switch-box identity sidecars.
; The stock one-byte move slots and saved Party/Box structures are unchanged.
; Each current/stored box slot owns a nibble mask (four extended move flags).
; Never call in an interrupt or from a context with SRAM already banked.
; All routines reside in the SaveSAV ROM bank $1C.
;
; The old 168 $ff Power Whip sentinel is intentionally NOT converted here.
; This code stays inert for extended identities until the 2-move learning path
; is installed; keep ordinary old-SAV loads compatible (invalid magic => 0).

EXT_BOX_MAGIC_0 EQU $a7
EXT_BOX_MAGIC_1 EQU $51
EXT_BOX_SEED EQU $b7

ExtendedPCEnableBank1:
	ld a, 1
	ld [wHaltAudio], a
	ld a, SRAM_ENABLE
	ld [MBC1SRamEnable], a
	ld a, 1
	ld [MBC1SRamBankingMode], a
	ld [MBC1SRamBank], a
	ret

ExtendedPCDisableSRAM:
	xor a
	ld [MBC1SRamBankingMode], a
	ld [MBC1SRamEnable], a
	ld [wHaltAudio], a
	ret

; Bank 1 enabled. Validate twenty low-nibble bytes and their xor checksum.
; If this record is absent or corrupt, initialize zero masks in-place.
EnsureExtendedCurrentBoxFlags:
	ld a, [sExtendedCurrentBoxMagic0]
	cp EXT_BOX_MAGIC_0
	jr nz, .clear
	ld a, [sExtendedCurrentBoxMagic1]
	cp EXT_BOX_MAGIC_1
	jr nz, .clear
	ld hl, sExtendedCurrentBoxMoveFlags
	ld b, MONS_PER_BOX
	ld c, EXT_BOX_SEED
.loop
	ld a, [hli]
	and $f0
	jr nz, .clear
	dec hl
	ld a, [hli]
	xor c
	ld c, a
	dec b
	jr nz, .loop
	ld a, [sExtendedCurrentBoxChecksum]
	cp c
	ret z
.clear
	ld hl, sExtendedCurrentBoxMoveFlags
	ld bc, MONS_PER_BOX
	xor a
	call FillMemory
	jp FinalizeExtendedCurrentBoxFlags

; Bank 1 enabled. Signature is written after the data/checksum.
FinalizeExtendedCurrentBoxFlags:
	xor a
	ld [sExtendedCurrentBoxMagic0], a
	ld [sExtendedCurrentBoxMagic1], a
	ld hl, sExtendedCurrentBoxMoveFlags
	ld b, MONS_PER_BOX
	ld c, EXT_BOX_SEED
.loop
	ld a, [hli]
	and $0f
	dec hl
	ld [hli], a
	xor c
	ld c, a
	dec b
	jr nz, .loop
	ld a, c
	ld [sExtendedCurrentBoxChecksum], a
	ld a, EXT_BOX_MAGIC_1
	ld [sExtendedCurrentBoxMagic1], a
	ld a, EXT_BOX_MAGIC_0
	ld [sExtendedCurrentBoxMagic0], a
	ret

; Called once on a new game; prior SRAM content must not leak identities.
ResetExtendedCurrentBoxFlags::
	call ExtendedPCEnableBank1
	ld hl, sExtendedCurrentBoxMoveFlags
	ld bc, MONS_PER_BOX
	xor a
	call FillMemory
	call FinalizeExtendedCurrentBoxFlags
	jp ExtendedPCDisableSRAM

; Called after a successful PARTY_TO_BOX MoveMon (before RemovePokemon).
ExtendedPCDepositFlag::
	call ExtendedPCEnableBank1
	call EnsureExtendedCurrentBoxFlags
	ld a, [wWhichPokemon]
	ld e, a
	ld d, 0
	ld hl, wExtendedPartyMoveFlags
	add hl, de
	ld a, [hl]
	ld [wExtendedMoveFlagsScratch], a
	ld a, [wNumInBox]
	dec a
	ld e, a
	ld hl, sExtendedCurrentBoxMoveFlags
	add hl, de
	ld a, [wExtendedMoveFlagsScratch]
	and $0f
	ld [hl], a
	call FinalizeExtendedCurrentBoxFlags
	jp ExtendedPCDisableSRAM

; Called after a successful BOX_TO_PARTY MoveMon (before RemovePokemon).
ExtendedPCWithdrawFlag::
	call ExtendedPCEnableBank1
	call EnsureExtendedCurrentBoxFlags
	ld a, [wWhichPokemon]
	ld e, a
	ld d, 0
	ld hl, sExtendedCurrentBoxMoveFlags
	add hl, de
	ld a, [hl]
	ld [wExtendedMoveFlagsScratch], a
	ld a, [wPartyCount]
	dec a
	ld e, a
	ld hl, wExtendedPartyMoveFlags
	add hl, de
	ld a, [wExtendedMoveFlagsScratch]
	and $0f
	ld [hl], a
	jp ExtendedPCDisableSRAM

; Called after Party removal in Bill's PC. Shift all masks down, zero tail.
ExtendedPCRemovePartyFlag::
	ld a, [wWhichPokemon]
	ld e, a
	ld d, 0
	ld hl, wExtendedPartyMoveFlags
	add hl, de
	ld a, e
	cp PARTY_LENGTH - 1
	jr z, .last
	ld b, a
	ld a, PARTY_LENGTH - 1
	sub b
	ld c, a
.shift
	ld d, h
	ld e, l
	inc de
	ld a, [de]
	ld [hli], a
	dec c
	jr nz, .shift
.last
	xor a
	ld [hl], a
	ret

; Called after Box removal, including release. No stale mask follows a new mon.
ExtendedPCRemoveBoxFlag::
	call ExtendedPCEnableBank1
	call EnsureExtendedCurrentBoxFlags
	ld a, [wWhichPokemon]
	ld e, a
	ld d, 0
	ld hl, sExtendedCurrentBoxMoveFlags
	add hl, de
	ld a, e
	cp MONS_PER_BOX - 1
	jr z, .last
	ld b, a
	ld a, MONS_PER_BOX - 1
	sub b
	ld c, a
.shift
	ld d, h
	ld e, l
	inc de
	ld a, [de]
	ld [hli], a
	dec c
	jr nz, .shift
.last
	xor a
	ld [hl], a
	call FinalizeExtendedCurrentBoxFlags
	jp ExtendedPCDisableSRAM

; Current box index to bank 2/3 + a 23-byte optional sidecar record.
; B = target SRAM bank, HL = pointer to flags (20 bytes + checksum + magics).
GetExtendedStoredBoxLocation:
	ld a, [wCurrentBoxNum]
	and $7f
	ld b, 2
	cp NUM_BOXES / 2
	jr c, .index
	inc b
	sub NUM_BOXES / 2
.index
	ld e, a
	ld d, 0
	ld hl, ExtendedStoredBoxPointerTable
	add hl, de
	add hl, de
	ld a, [hli]
	ld h, [hl]
	ld l, a
	ret

ExtendedStoredBoxPointerTable:
	dw sStoredBox1MoveFlags
	dw sStoredBox2MoveFlags
	dw sStoredBox3MoveFlags
	dw sStoredBox4MoveFlags
	dw sStoredBox5MoveFlags
	dw sStoredBox6MoveFlags
	; bank 2
	dw sStoredBox7MoveFlags
	dw sStoredBox8MoveFlags
	dw sStoredBox9MoveFlags
	dw sStoredBox10MoveFlags
	dw sStoredBox11MoveFlags
	dw sStoredBox12MoveFlags
	; bank 3

; SRAM selected to the stored box's bank; HL starts at its 20 flag bytes.
; Returns carry clear on a valid record and carry set on any bad field.
ValidateExtendedStoredBox:
	push hl
	ld bc, MONS_PER_BOX
	add hl, bc
	ld a, [hli]
	ld d, a
	ld a, [hli]
	cp EXT_BOX_MAGIC_0
	jr nz, .invalid
	ld a, [hl]
	cp EXT_BOX_MAGIC_1
	jr nz, .invalid
	pop hl
	push hl
	ld b, MONS_PER_BOX
	ld c, EXT_BOX_SEED
.loop
	ld a, [hli]
	and $f0
	jr nz, .invalid
	dec hl
	ld a, [hli]
	xor c
	ld c, a
	dec b
	jr nz, .loop
	ld a, c
	cp d
	pop hl
	jr nz, .bad
	and a
	ret
.invalid
	pop hl
.bad
	scf
	ret

; Bank 1 current box flags -> selected bank 2/3 box record.
; Called only after the old box's original data was copied to SRAM.
SaveExtendedCurrentBoxToStoredBox::
	call ExtendedPCEnableBank1
	call EnsureExtendedCurrentBoxFlags
	call GetExtendedStoredBoxLocation
	ld a, b
	ld [MBC1SRamBank], a
	push hl
	ld de, MONS_PER_BOX + 1
	add hl, de
	xor a
	ld [hli], a
	ld [hl], a
	pop hl
	ld de, sExtendedCurrentBoxMoveFlags
	ld c, MONS_PER_BOX
.copy
	ld a, 1
	ld [MBC1SRamBank], a
	ld a, [de]
	inc de
	ld [wExtendedMoveFlagsScratch], a
	ld a, b
	ld [MBC1SRamBank], a
	ld a, [wExtendedMoveFlagsScratch]
	and $0f
	ld [hli], a
	dec c
	jr nz, .copy
	; HL now addresses stored record checksum; remain in bank 2 or 3.
	ld bc, -MONS_PER_BOX
	add hl, bc
	ld b, MONS_PER_BOX
	ld c, EXT_BOX_SEED
.check
	ld a, [hli]
	xor c
	ld c, a
	dec b
	jr nz, .check
	ld [hl], c
	inc hl
	ld a, EXT_BOX_MAGIC_0
	ld [hli], a
	ld a, EXT_BOX_MAGIC_1
	ld [hl], a
	jp ExtendedPCDisableSRAM

; Current box record <- selected saved-box record. Invalid/legacy = zeros.
LoadExtendedStoredBoxToCurrentBox::
	call ExtendedPCEnableBank1
	call GetExtendedStoredBoxLocation
	ld a, b
	ld [MBC1SRamBank], a
	push bc
	call ValidateExtendedStoredBox
	pop bc
	jr c, .zero
	ld d, h
	ld e, l
	ld hl, sExtendedCurrentBoxMoveFlags
	ld c, MONS_PER_BOX
.copy
	ld a, b
	ld [MBC1SRamBank], a
	ld a, [de]
	inc de
	ld [wExtendedMoveFlagsScratch], a
	ld a, 1
	ld [MBC1SRamBank], a
	ld a, [wExtendedMoveFlagsScratch]
	ld [hli], a
	dec c
	jr nz, .copy
	jr .finish
.zero
	ld a, 1
	ld [MBC1SRamBank], a
	ld hl, sExtendedCurrentBoxMoveFlags
	ld bc, MONS_PER_BOX
	xor a
	call FillMemory
.finish
	; Both paths have bank 1 selected.
	call FinalizeExtendedCurrentBoxFlags
	jp ExtendedPCDisableSRAM

; Summary for an active PC box member, called in bank $1C.
ReadExtendedCurrentBoxStatusMask::
	call ExtendedPCEnableBank1
	call EnsureExtendedCurrentBoxFlags
	ld a, [wWhichPokemon]
	cp MONS_PER_BOX
	jr nc, .bad
	ld e, a
	ld d, 0
	ld hl, sExtendedCurrentBoxMoveFlags
	add hl, de
	ld a, [hl]
	and $0f
	jr .write
.bad
	xor a
.write
	ld [wExtendedStatusMoveFlags], a
	jp ExtendedPCDisableSRAM
