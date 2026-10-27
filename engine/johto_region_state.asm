; P2-003: authenticated region/local map key inside six existing main-save bytes.
; All fields live in bank 1's existing wMainDataStart..End span; no new WRAM,
; SRAM or save-size allocation. Never reuse the regional Pokedex $D7A4..$D7AB.
;
; Current stage has zero Johto active maps; a stale, forged or invalid Johto
; identity therefore always returns to the safe Kanto identity. No overworld
; map loader, warp, Fly or wCurMap path is routed through these helpers yet.
;
; Public far-call ABI: only JohtoGetPhysicalMapKey's D/E are return values.
; A/flags cannot be used across callba due to the bank-switch wrapper.

JohtoResetRegionStateToKanto::
	ld a, JOHTO_REGION_MAGIC_0
	ld [wRegionStateMagic0], a
	ld a, JOHTO_REGION_MAGIC_1
	ld [wRegionStateMagic1], a
	xor a ; MAP_REGION_KANTO
	ld [wCurRegion], a
	ld [wLastRegion], a
	ld a, [wCurMap]
	ld [wCurLocalMapID], a
	ld a, [wLastMap]
	ld [wLastLocalMapID], a
	ret

; Called after the original checksum has passed and wMainData was copied
; from SRAM. Only normalize WRAM; do not modify SRAM until a normal save.
JohtoValidateSavedRegionState::
	ld a, [wRegionStateMagic0]
	cp JOHTO_REGION_MAGIC_0
	jp nz, JohtoResetRegionStateToKanto
	ld a, [wRegionStateMagic1]
	cp JOHTO_REGION_MAGIC_1
	jp nz, JohtoResetRegionStateToKanto

	ld a, [wCurRegion]
	cp MAP_REGION_KANTO
	jr z, .kanto
	cp MAP_REGION_JOHTO
	jp nz, JohtoResetRegionStateToKanto
	; A physical Johto save must use only the shared runtime handle.
	ld a, [wCurMap]
	cp JOHTO_RUNTIME_MAP_HANDLE
	jp nz, JohtoResetRegionStateToKanto
	ld a, [wCurLocalMapID]
	ld e, a
	call GetJohtoActiveSlot
	ld a, e
	cp JOHTO_INVALID_ACTIVE_SLOT
	jp z, JohtoResetRegionStateToKanto
	jr .checkLast
.kanto
	; Kanto map IDs remain the original wCurMap values, never Johto IDs.
	ld a, [wCurMap]
	ld [wCurLocalMapID], a
.checkLast
	ld a, [wLastRegion]
	cp MAP_REGION_KANTO
	jr z, .kantoLast
	cp MAP_REGION_JOHTO
	jr nz, .invalidLast
	ld a, [wLastLocalMapID]
	ld e, a
	call GetJohtoActiveSlot
	ld a, e
	cp JOHTO_INVALID_ACTIVE_SLOT
	ret nz
.invalidLast
	xor a
	ld [wLastRegion], a
.kantoLast
	; For a Kanto previous map, the existing wLastMap is authoritative.
	ld a, [wLastMap]
	ld [wLastLocalMapID], a
	ret

; Called immediately before copying wMainData to SRAM and checksumming it.
; This keeps Kanto current/last local IDs aligned with legacy map fields.
JohtoPrepareRegionStateForSave::
	jp JohtoValidateSavedRegionState

; Inspect physical identity without confusing the legacy engine map handle
; with a stable local map ID. Input: none. Output: D=region, E=local ID.
JohtoGetPhysicalMapKey::
	ld a, [wCurRegion]
	cp MAP_REGION_KANTO
	jr nz, .read
	; Native Kanto remains authoritative between saves too, not just on load.
	ld a, [wCurMap]
	ld [wCurLocalMapID], a
	ld a, [wLastRegion]
	cp MAP_REGION_KANTO
	jr nz, .read
	ld a, [wLastMap]
	ld [wLastLocalMapID], a
.read
	ld a, [wCurRegion]
	ld d, a
	ld a, [wCurLocalMapID]
	ld e, a
	ret
