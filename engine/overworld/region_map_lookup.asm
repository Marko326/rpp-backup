; REG-5.62.118: opt-in two-part map key resolver.
; Call with DE = (region << 8) | local_map_id via callab/callba.
; On success: D = ROM bank, HL = map header address, carry clear.
; On failure: D = 0, HL = 0, carry set.  A/BC are not preserved.
; The returned bank is metadata: this routine does not leave it selected.
; Existing warp/save users still use wCurMap until later REG phases.
ResolveRegionMapHeader::
	ld a, d
	cp MAP_REGION_JOHTO
	jr z, .johto
	cp MAP_REGION_KANTO
	jr nz, .invalid
.kanto
	ld a, e
	cp NUM_LEGACY_MAPS
	jr nc, .invalid
	ld l, e
	ld h, 0
	add hl, hl
	ld bc, MapHeaderPointers
	add hl, bc
	ld a, [hli]
	ld h, [hl]
	ld l, a
	push hl
	ld a, e
	call GetKantoMapHeaderBank
	ld d, a
	pop hl
	and a
	ret
.johto
	ld a, e
	cp NUM_JOHTO_MAPS
	jr nc, .invalid
	ld l, e
	ld h, 0
	add hl, hl
	ld bc, JohtoMapHeaderPointers
	add hl, bc
	ld a, [hli]
	ld h, [hl]
	ld l, a
	push hl
	ld l, e
	ld h, 0
	ld bc, JohtoMapHeaderBanks
	add hl, bc
	ld d, [hl]
	pop hl
	and a
	ret
.invalid
	ld d, 0
	ld hl, 0
	scf
	ret

; A legacy one-byte ID can be translated to the new key without touching
; the saved value.  Use this only where the ID is known to be a map ID;
; not for the unrelated Town Map/Fly indices.
; Input: E = old map ID.  Output: DE = region/local map key.
LegacyMapIDToRegionKey::
	ld d, MAP_REGION_KANTO
	ld a, e
	cp NEW_BARK_TOWN
	ret nz
	ld d, MAP_REGION_JOHTO
	ld e, JOHTO_NEW_BARK_LOCAL_ID
	ret

; REG-5.62.119: while warps and connections still carry legacy one-byte IDs,
; derive both saved region fields from those IDs at every map-header load.
; This fills the compatible region fields for older saves at map load.
; Both fields are overwritten, not restored as independent saved-region keys.
; $E7 is Johto local $00; all other legacy IDs are Kanto for this phase.
; Do not replace this with an unconditional reset once region-aware warps land.
SyncLegacyMapRegions::
	ld a, [wCurMap]
	cp NEW_BARK_TOWN
	ld a, MAP_REGION_KANTO
	jr nz, .currentReady
	ld a, MAP_REGION_JOHTO
.currentReady
	ld [wCurRegion], a
	ld a, [wLastMap]
	cp NEW_BARK_TOWN
	ld a, MAP_REGION_KANTO
	jr nz, .lastReady
	ld a, MAP_REGION_JOHTO
.lastReady
	ld [wLastRegion], a
	ld a, REGION_STATE_MAGIC0
	ld [wRegionStateMagic0], a
	ld a, REGION_STATE_MAGIC1
	ld [wRegionStateMagic1], a
	ret
