; These routines manage gradual fading
; (e.g., entering a doorway)
LoadGBPal::
	ld a, [wMapPalOffset] ;tells if wCurMap is dark (requires HM5_FLASH?)
	ld b, a
	ld hl, FadePal4
	ld a, l
	sub b
	ld l, a
	jr nc, .ok
	dec h
.ok
	ld a, [hli]
	ld [rBGP], a
	ld a, [hli]
	ld [rOBP0], a
	ld a, [hli]
	ld [rOBP1], a
	ret

GBFadeInFromBlack::
	ld hl, FadePal1
	ld b, 4
	jr GBFadeIncCommon

GBFadeOutToWhite::
	ld hl, FadePal6
	ld b, 3

GBFadeIncCommon:
	ld a, [hli]
	ld [rBGP], a
	ld a, [hli]
	ld [rOBP0], a
	ld a, [hli]
	ld [rOBP1], a
	ld c, 8
	call DelayFrames
	dec b
	jr nz, GBFadeIncCommon
	ret

GBFadeOutToBlack::
	ld hl, FadePal4 + 2
	ld b, 4
	jr GBFadeDecCommon

; REF-353: same four stages/eight frames as a door, without briefly
; brightening an unlit cave. GBFadeDecCommon walks 3 bytes BACKWARDS
; per stage; point to the final row (+11), not the first row (+2).
; Otherwise it reads neighboring FadePal tables and leaves the loader visible.
; Only PlayMapChangeSound uses these entry points.
; A dark Johto BG has normally colored sprites; Kanto Rock Tunnel can have
; both BG and OBJ already dark. Neither path changes the LCD-on loader.
GBFadeOutToBlackDarkBG353::
	ld hl, FadePalDarkBG353 + 11
	ld b, 4
	jr GBFadeDecCommon

GBFadeOutToBlackAlreadyDark353::
	ld hl, FadePalAlreadyDark353 + 11
	ld b, 4
	jr GBFadeDecCommon

GBFadeInFromWhite::
	ld hl, FadePal7 + 2
	ld b, 3

GBFadeDecCommon:
	ld a, [hld]
	ld d, a ; stage OBP1
	ld a, [hld]
	ld e, a ; stage OBP0
	ld a, [hld]
	ldh [hDoorwayFadeTargetBGP], a
	ldh a, [hDoorwayCGBFadeActive]
	and a
	jr z, .commitFadePalettes
	; Prepare the scaled copy before publishing the matching BGP/OBP stage.
	; Preserve the fade loop's BC counter and HL table cursor across callab.
	push bc
	push de
	push hl
	callab DoorwayFadePreparePalette
	pop hl
	pop de
	pop bc
.commitFadePalettes
	; Publish OBP1/OBP0/BGP as one stage; STAT/VBlank must not see a mixed set.
	di
	ld a, d
	ld [rOBP1], a
	ld a, e
	ld [rOBP0], a
	ldh a, [hDoorwayFadeTargetBGP]
	ld [rBGP], a
	ei
	ld c, 8
	call DelayFrames
	dec b
	jr nz, GBFadeDecCommon
	ret

; HAX: some of these palettes have been modified, mostly to make BGP/OBP0/OBP1 consistent
; with each other.
; Gold DARKNESS keeps the player sprite bright while darkening only the cave BG.
; Keep Rock Tunnel's existing FadePal2 intact: the native Johto cave uses this
; separate record (FadePal4 - 12) with a NORMAL OBJ mapping, including on CGB.
FadePalJohtoDark349:: db %11111110, %11100100, %11100100
FadePal1:: db %11111111, %11111111, %11111111
FadePal2:: db %11111110, %11111110, %11111110 ; legacy Kanto dark rooms
FadePal3:: db %11111001, %11111001, %11111001
FadePal4:: db %11100100, %11100100, %11100100 ; This is the "standard" palette
;                rBGP      rOBP0      rOBP1
FadePal5:: db %11100100, %11100100, %11100100
FadePal6:: db %10010000, %10010000, %10010000
FadePal7:: db %01000000, %01000000, %01000000
FadePal8:: db %00000000, %00000000, %00000000
; Reverse order: the common fade starts at the LAST row (+11) and walks backward.
FadePalDarkBG353::
	db $ff, $ff, $ff ; final black
	db $fe, $fe, $fe ; BG remains dark; OBJ is almost black
	db $fe, $f9, $f9 ; BG remains dark; OBJ dims
	db $fe, $e4, $e4 ; no brightening on the first stage
FadePalAlreadyDark353::
	db $ff, $ff, $ff
	db $fe, $fe, $fe
	db $fe, $fe, $fe
	db $fe, $fe, $fe
ASSERT FadePal4 - FadePalJohtoDark349 == 12
