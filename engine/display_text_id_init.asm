; function that performs initialization for DisplayTextID
DisplayTextIDInit:
	xor a
	ld [wListMenuID],a

	; MAPSIGN-5.19.41: START and the map-name sign share Window BG $9c00.
	; Hide the existing Window before START begins its multi-frame font/tilemap
	; transfer; otherwise the visible map-name sign briefly shows partially
	; overwritten START-menu rows. $91 is the existing START hidden sentinel.
	ld a,[hSpriteIndexOrTextID]
	and a
	jr nz,.windowOwnerReady
	; MENU-5.62.11: every new START session begins on the lightweight path.
	; Special auto-text maps may set this flag again below before legacy init.
	ld hl,wStartMenuSavedMenuItem
	res START_MENU_FULL_RESTORE_F,[hl]
	ld a,$91
	ld [hWY],a
.windowOwnerReady
	ld a,[wAutoTextBoxDrawingControl]
	bit 0,a
	jr nz,.skipDrawingTextBoxBorder
	ld a,[hSpriteIndexOrTextID] ; text ID (or sprite ID)
	and a
	jr nz,.notStartMenu
	; MENU-5.62.11: DrawStartMenu owns the START border; skip the duplicate hidden draw.
	jr .skipDrawingTextBoxBorder
; if text ID is not 0 (i.e. not the start menu) then do a standard dialogue text box
.notStartMenu
	coord hl, 0, 12
	ld b,$04
	ld c,$12
	call TextBoxBorder
.skipDrawingTextBoxBorder
	ld hl,wFontLoaded
	set 0,[hl]
	ld hl,wFlags_0xcd60
	bit 4,[hl]
	res 4,[hl]
	jr nz,.skipMovingSprites
	call UpdateSprites
.skipMovingSprites
; loop to copy C1X9 (direction the sprite is facing) to C2X9 for each sprite
; this is done because when you talk to an NPC, they turn to look your way
; the original direction they were facing must be restored after the dialogue is over
	ld hl,wSpriteStateData1 + $19
	ld c,$0f
	ld de,$0010
.spriteFacingDirectionCopyLoop
	ld a,[hl]
	inc h
	ld [hl],a
	dec h
	add hl,de
	dec c
	jr nz,.spriteFacingDirectionCopyLoop
	; MENU-5.62.11: START normally renders from the resident Bank-1 font/textbox
	; copy. Auto-text maps still require the legacy Bank-0 font contract; mark that
	; session for the complete map/sprite restore before entering normal init.
	ld a,[hSpriteIndexOrTextID]
	and a
	jr nz,.normalTextInit
	ld a,[wAutoTextBoxDrawingControl]
	bit 0,a
	jr z,.startFastTextInit
	ld hl,wStartMenuSavedMenuItem
	set START_MENU_FULL_RESTORE_F,[hl]
	jr .normalTextInit
.startFastTextInit
	; If a just-finished step still has one row/column redraw armed, let that VBlank
	; finish before START enables its three-part Window transfer. This preserves the
	; safety condition from the older fast-font path without paying a font upload.
	ld a,[hRedrawRowOrColumnMode]
	and a
	call nz,DelayFrame
	ret

.normalTextInit
; loop to force all the sprites in the middle of animation to stand still
; (so that they don't like they're frozen mid-step during the dialogue)
	ld hl,wSpriteStateData1 + 2
	ld de,$0010
	ld c,e
.spriteStandStillLoop
	ld a,[hl]
	cp a,$ff ; is the sprite visible?
	jr z,.nextSprite
; if it is visible
	and a,$fc
	ld [hl],a
.nextSprite
	add hl,de
	dec c
	jr nz,.spriteStandStillLoop
	call LoadFontTilePatterns
	ld b,$9c ; window background address
	call CopyScreenTileBufferToVRAM ; transfer background in WRAM to VRAM
	xor a
	ld [hWY],a ; put the window on the screen
	ld a,$01
	ld [H_AUTOBGTRANSFERENABLED],a ; enable continuous WRAM to VRAM transfer each V-blank
	ret
