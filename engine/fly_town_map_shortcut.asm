; FLY-5.62.79: START on the Fly Map targets the last recovery point.
; Teleport/blackout both read wLastBlackoutMap, which is set on healing;
; it is NOT the most recently walked-through town.
;
; in:  the currently selected city/special Fly cursor is still in wBuffer
; out: DE = selected wBuffer entry, or 0 if no valid Fly destination exists
;      (the caller then keeps the original cursor/list). No RAM is added.
FindFlyTeleportShortcut::
	ld a, [wLastBlackoutMap]
	cp ROUTE_4 ; Mt. Moon Pokemon Center (Teleport's Route 4 warp)
	jp z, .mtMoon
	cp ROUTE_10 ; Rock Tunnel Pokemon Center (Teleport's Route 10 warp)
	jp z, .rockTunnel
	cp SAFFRON_CITY + 1 ; normal city/Fly destination IDs are 0..10
	jp nc, .unavailable
	; Verify the actual Fly visit bit *before* rebuilding wBuffer, so an
	; unavailable city leaves the current city/special selection untouched.
	ld e, a
	ld hl, wKantoTownVisitedFlag
	cp 8
	jr c, .cityFlagByte
	inc hl
	sub 8
.cityFlagByte
	ld b, a
	ld a, b
	and a
	ld a, 1
	jr z, .cityMaskReady
.cityShiftMask
	add a, a
	dec b
	jr nz, .cityShiftMask
.cityMaskReady
	and [hl]
	jp z, .unavailable
	ld a, e
	push af
	xor a
	ld [wFlyLocationsAxis], a
	callab BuildFlyLocationsList
	pop af
	ld e, a
	ld d, 0
	ld hl, wBuffer + 1
	add hl, de
	ld a, [hl]
	cp $fe
	jr z, .firstVisitedCity
	cp $ff
	jr z, .firstVisitedCity
	jr .found
.firstVisitedCity
	ld hl, wBuffer + 1
.scanCity
	ld a, [hli]
	cp $ff
	jr z, .unavailable
	cp $fe
	jr z, .scanCity
	dec hl
	jr .found

.mtMoon
	; Fly only offers this Route 4 warp after Mt. Moon is unlocked.
	ld a, [wSpecialFlyVisitedFlag]
	bit 0, a
	jr z, .unavailable
	ld c, MT_MOON_3
	jr .special
.rockTunnel
	; Likewise, Route 10's Teleport warp uses the Rock Tunnel Fly entry.
	ld a, [wSpecialFlyVisitedFlag]
	bit 2, a
	jr z, .unavailable
	ld c, ROCK_TUNNEL_1
.special
	push bc
	ld a, 1
	ld [wFlyLocationsAxis], a
	callab BuildSpecialFlyLocationsList
	pop bc
	ld hl, wBuffer + 1
.findSpecial
	ld a, [hli]
	cp c
	jr z, .specialFound
	cp $ff
	jr nz, .findSpecial
	; A corrupt/inconsistent special Fly flag should never select $fe/$ff.
	; The rebuilt list still has the newly visited destination in normal saves.
	jr .unavailable
.specialFound
	dec hl
.found
	ld d, h
	ld e, l
	ret
.unavailable
	ld de, 0
	ret
