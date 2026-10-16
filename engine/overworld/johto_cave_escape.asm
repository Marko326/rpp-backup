; MAP-5.62.192: Union Cave 1F Dig/Escape Rope follows the last verified
; entering outdoor mouth (Route32 or Route33), like Gold's entry-Warp return.
; Recorded in the existing saved wLastMap/region/local triple before $FE
; resolver changes source identity. No SRAM extension or other cave enable.
; Old/unidentified entry state safely falls back to vetted Route32 approach.

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
	; Only a validated cave can intercept this field move. Blackout
	; remains on the original wLastBlackoutMap branch, untouched here.
	ld hl, wd732
	res 6, [hl]
	; Exact saved physical key is necessary: $FC alone is shared by maps.
	ld a, [wLastMap]
	cp REGION_NATIVE_MAP_SLOT
	jr nz, .route32
	ld a, [wLastRegion]
	cp MAP_REGION_JOHTO
	jr nz, .route32
	ld a, [wLastLocalMapID]
	cp JOHTO_ROUTE_33_LOCAL_ID
	jr nz, .route32
	ld a, REGION_NATIVE_MAP_SLOT
	ld [wCurMap], a
	ld [wDestinationMap], a
	ld a, JOHTO_ROUTE_33_LOCAL_ID
	ld [wCurLocalMapID], a
	ld a, JOHTO_MODERN
	ld [wCurMapTileset], a
	ld hl, .route33ReturnWarpData
	jr .finish
.route32
	; Pre-.192 Continue/unknown source: approved Route32 approach.
	ld a, JOHTO_ROUTE_32
	ld [wCurMap], a
	ld [wDestinationMap], a
	ld a, JOHTO_ROUTE_32_LOCAL_ID
	ld [wCurLocalMapID], a
	ld a, JOHTO
	ld [wCurMapTileset], a
	ld hl, .route32ReturnWarpData
.finish
	ld a, MAP_REGION_JOHTO
	ld [wCurRegion], a
	ld de, wCurrentTileBlockMapViewPointer
	ld bc, 6
	call CopyData
	ld e, 0 ; carry indicates handled; A=0 restored by special-warp caller
	scf
	ret
.notOurWarp
	and a
	ret
.route32ReturnWarpData
	; Original approved 32 cave approach, not solid Gold doorway (6,79).
	FLYWARP_DATA JOHTO_ROUTE_32_WIDTH, 80, 6
.route33ReturnWarpData
	; Gold Route33 (11,9) is solid CAVE art. Safely land at (11,10).
	FLYWARP_DATA JOHTO_ROUTE_33_WIDTH, 10, 11
