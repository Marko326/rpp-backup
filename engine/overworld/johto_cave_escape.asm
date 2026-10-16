; DIG-5.62.188: narrow native Johto Dig / Escape Rope pilot.
; Gold saves the most recent outdoor-to-indoor source map/group/warp.
; Union Cave 1F currently has exactly one enabled outside entrance: Route32.
; This fixed (region, local, safe approach) destination therefore needs no
; additional saved byte and remains deterministic across Continue / old saves.
; A second entrance or cave floor MUST replace this single-entry contract.

; Called only after the original battle / Agatha guards. Carry = allowed.
; Never use the cave tileset as a global eligibility wildcard.
CanUseJohtoUnionCaveEscape::
	ld a, [wCurMap]
	cp REGION_NATIVE_MAP_SLOT
	jr nz, .deny
	ld a, [wCurRegion]
	cp MAP_REGION_JOHTO
	jr nz, .deny
	ld a, [wCurLocalMapID]
	cp JOHTO_UNION_CAVE_1F_LOCAL_ID
	jr nz, .deny
	ld a, [wCurMapTileset]
	cp JOHTO_UNION_CAVE
	jr nz, .deny
	ld a, [wRegionStateMagic0]
	cp REGION_STATE_MAGIC0
	jr nz, .deny
	ld a, [wRegionStateMagic1]
	cp REGION_STATE_MAGIC1
	jr nz, .deny
	scf
	ret
.deny
	and a
	ret

; Called from LoadSpecialWarpData before old blackout/Fly target selection.
; Detect actual Dig/Rope transition: wd732 bit3 is set by ItemUseEscapeRope,
; and bit6 requests a center return in legacy RPP. Blackout clears bit3,
; so it MUST bypass this branch and retain wLastBlackoutMap.
; Carry = handled. On no match, change no memory and keep old dispatch.
TryLoadJohtoUnionCaveEscapeWarp::
	ld a, [wd732]
	and (1 << 3) | (1 << 6)
	cp (1 << 3) | (1 << 6)
	jr nz, .notOurWarp
	call CanUseJohtoUnionCaveEscape
	jr nc, .notOurWarp
	; Only this fully identified and validated cave can be routed here.
	; A field move cannot escape to the stale Kanto healing destination.
	ld hl, wd732
	res 6, [hl]
	ld a, JOHTO_ROUTE_32
	ld [wCurMap], a
	ld [wDestinationMap], a
	ld a, MAP_REGION_JOHTO
	ld [wCurRegion], a
	ld a, JOHTO_ROUTE_32_LOCAL_ID
	ld [wCurLocalMapID], a
	ld hl, .returnWarpData
	ld de, wCurrentTileBlockMapViewPointer
	ld bc, 6
	call CopyData
	ld a, JOHTO
	ld [wCurMapTileset], a
	ld e, 0 ; carry still signals handled; special-warp offsets need A=0
	scf
	ret
.notOurWarp
	and a
	ret
.returnWarpData
	; Gold Route32 cave Warp: (x=6, y=79), approved RPP exit step
	; reaches the walkable approach (x=6, y=80). Special Warp lands there
	; directly to avoid re-entering the solid doorway or an extra auto-step.
	FLYWARP_DATA JOHTO_ROUTE_32_WIDTH, 80, 6
