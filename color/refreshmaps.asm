; Most of the functions here are called during vblank, maybe they belong in vblank.asm...


; Called when a map is loaded. Loads tilemap and tile attributes.
; REF-350 keeps the original fast LCD-off path and adds a CGB-only safe path
; for ordinary door transitions where the LCD remains enabled.
LoadMapVramAndColors:
	ldh a,[hMapLoadVRAMSafeFlag]
	and a
	jr nz,.safeLCDOn

.fastLCDOff
	ld a,$02
	ld [rSVBK],a

	coord hl, 0, 0
	ld de,vBGMap0
	ld b,18
.vramCopyLoop
	ld c,20
.vramCopyInnerLoop
	ld a,$01
	ld [rVBK],a
	ld a,[hl]
	push hl
	ld h,W2_TilesetPaletteMap>>8
	ld l,a
	ld a,[hl]
	ld [de],a
	pop hl
	xor a
	ld [rVBK],a
	ld a,[hli]
	ld [de],a
	inc e

	dec c
	jr nz,.vramCopyInnerLoop
	ld a,32 - 20
	add e
	ld e,a
	jr nc,.noCarry
	inc d
.noCarry
	dec b
	jr nz,.vramCopyLoop

	xor a
	ld [rSVBK],a
	ret

.safeLCDOn
	; The BG map is 20x18 inside a 32-byte row stride. Stage both planes in
	; WRAM bank 2 so each row starts on a 16-byte HDMA boundary. Only columns
	; 0-19 are uploaded; the 12 off-screen columns remain untouched.
	;
	; Build one attribute row at a time. Keep SVBK at bank 1 while interrupts
	; are enabled because the VBlank handlers use the normal game WRAM bank.
	coord hl, 0, 0
	ld de,W2_DoorwayAttrMapBuffer
	ld b,18
.buildAttrRow
	di
	ld a,2
	ld [rSVBK],a
	ld c,20
.buildAttrColumn
	ld a,[hli]
	push hl
	ld h,W2_TilesetPaletteMap>>8
	ld l,a
	ld a,[hl]
	pop hl
	ld [de],a
	inc de
	dec c
	jr nz,.buildAttrColumn
	ld a,32 - 20
	add e
	ld e,a
	jr nc,.buildAttrNoCarry
	inc d
.buildAttrNoCarry
	xor a
	ld [rSVBK],a
	ei
	dec b
	jr nz,.buildAttrRow

	; Build the matching tile plane with the same 32-byte row stride.
	coord hl, 0, 0
	ld de,W2_DoorwayTileMapBuffer
	ld b,18
.buildTileRow
	di
	ld a,2
	ld [rSVBK],a
	ld c,20
.buildTileColumn
	ld a,[hli]
	ld [de],a
	inc de
	dec c
	jr nz,.buildTileColumn
	ld a,32 - 20
	add e
	ld e,a
	jr nc,.buildTileNoCarry
	inc d
.buildTileNoCarry
	xor a
	ld [rSVBK],a
	ei
	dec b
	jr nz,.buildTileRow

	; Upload attributes to VBK 1, then tile IDs to VBK 0. Each row uses one
	; 16-byte HBlank DMA block plus four individually mode-checked CPU writes.
	ld hl,W2_DoorwayAttrMapBuffer
	ld de,vBGMap0
	ld b,18
	ld c,1
	call .copyDoorwayMapRowsHDMA

	ld hl,W2_DoorwayTileMapBuffer
	ld de,vBGMap0
	ld b,18
	ld c,0
	call .copyDoorwayMapRowsHDMA

	xor a
	ld [rVBK],a
	ld [rSVBK],a
	ret

; Input: HL = row-padded source buffer in WRAM bank 2, DE = vBGMap0,
;        B = 18 rows, C = destination VBK (1 attributes, 0 tile IDs).
; Each row copies 16 bytes with one HBlank DMA block, then copies the final
; four visible columns with CPU writes that independently wait for mode 0/1.
; Interrupts remain disabled only while bank 2 / the selected VBK is active.
.copyDoorwayMapRowsHDMA
.hdmaRowLoop
	di
	ld a,2
	ld [rSVBK],a
	push bc
	ld a,c
	ld [rVBK],a

	ld a,h
	ld [rHDMA1],a
	ld a,l
	ld [rHDMA2],a
	ld a,d
	and $1f
	ld [rHDMA3],a
	ld a,e
	ld [rHDMA4],a
	ld a,$80 ; one 16-byte HBlank DMA block
	ld [rHDMA5],a
.hdmaWaitBlock
	ld a,[rHDMA5]
	bit 7,a
	jr z,.hdmaWaitBlock

	; HDMA updates its own addresses, not HL/DE.
	ld a,16
	add l
	ld l,a
	jr nc,.hdmaSourceNoCarry
	inc h
.hdmaSourceNoCarry
	ld a,16
	add e
	ld e,a
	jr nc,.hdmaDestNoCarry
	inc d
.hdmaDestNoCarry
	ld b,4
.hdmaTailLoop
.hdmaWaitTailVRAM
	ldh a,[rSTAT]
	and %10 ; modes 0 and 1 permit VRAM writes
	jr nz,.hdmaWaitTailVRAM
	ld a,[hli]
	ld [de],a
	inc de
	dec b
	jr nz,.hdmaTailLoop

	; Skip the 12 off-screen columns to the next 32-byte BG-map row.
	ld a,32 - 20
	add l
	ld l,a
	jr nc,.hdmaSourceRowNoCarry
	inc h
.hdmaSourceRowNoCarry
	ld a,32 - 20
	add e
	ld e,a
	jr nc,.hdmaDestRowNoCarry
	inc d
.hdmaDestRowNoCarry
	pop bc
	xor a
	ld [rVBK],a
	ld [rSVBK],a
	ei
	dec b
	jr nz,.hdmaRowLoop
	ret


; Refresh 1/3 of the window each frame. Called during vblank.
RefreshWindow:
	ld a,[H_AUTOBGTRANSFERENABLED]
	and a
	ret z

	ld a,2
	ld [rSVBK],a

	; Check that the pre-vblank functions have run already (if not, let it catch up)
	ld hl,W2_UpdatedWindowPortion
	ld a,[hl]
	and a
	jp z,.palettesDone
	ld [hl],0

	ld hl,sp + 0
	ld a,h
	ld [H_SPTEMP],a
	ld a,l
	ld [H_SPTEMP+1],a	; Store stack pointer
	ld a,[H_AUTOBGTRANSFERPORTION]
	and a
	jr z,.transferTopThird
	dec a
	jr z,.transferMiddleThird
.transferBottomThird
	coord hl, 0, 12
	ld sp,hl
	ld a,[H_AUTOBGTRANSFERDEST+1]
	ld h,a
	ld a,[H_AUTOBGTRANSFERDEST]
	ld l,a
	ld de,(12 * 32)
	add hl,de
	xor a ; TRANSFERTOP
	jr .doTransfer
.transferTopThird
	coord hl, 0, 0
	ld sp,hl
	ld a,[H_AUTOBGTRANSFERDEST+1]
	ld h,a
	ld a,[H_AUTOBGTRANSFERDEST]
	ld l,a
	ld a,TRANSFERMIDDLE
	jr .doTransfer
.transferMiddleThird
	coord hl, 0, 6
	ld sp,hl
	ld a,[H_AUTOBGTRANSFERDEST+1]
	ld h,a
	ld a,[H_AUTOBGTRANSFERDEST]
	ld l,a
	ld de,(6 * 32)
	add hl,de
	ld a,TRANSFERBOTTOM

; sp now points to map data in wram, hl points to vram destination.
.doTransfer
	ld [H_AUTOBGTRANSFERPORTION],a
	ld b,6

.drawRow:
REPT 9
	pop de
	ld [hl],e
	inc l
	ld [hl],d
	inc l
ENDR
	pop de
	ld [hl],e
	inc l
	ld [hl],d
	; Don't inc l this time.
	; Careful here, because credits break due to carry if you inc l and add a
	; with 12 instead of 13.

	ld a,13
	add l
	ld l,a
	jr nc,.noCarry
	inc h
.noCarry
	dec b
	jr nz,.drawRow

	; Restore sp and set hl to point to destination again
	ld b,h
	ld c,l

	ld a,[H_SPTEMP]
	ld h,a
	ld a,[H_SPTEMP+1]
	ld l,a
	ld sp,hl

	ld h,b
	ld l,c
	ld bc, -$c0
	add hl,bc

; BEGIN loading palette maps

	ld a,1
	ld [rVBK],a

	; Always update if using tile-based palettes
	ld a,[W2_TileBasedPalettes]
	and a
	jr nz,.continue

	; If using static palettes, we can check whether that's been updated
	ld a,[W2_StaticPaletteMapChanged_vbl]
	and a
	jr z, .palettesDone
	xor a
	ld [W2_StaticPaletteMapChanged_vbl],a

.continue

	; DMA from W2_ScreenPalettesBuffer to hl (window attribute map)
	ld c,$51
	ld a, W2_ScreenPalettesBuffer>>8
	ld [$ff00+c],a
	inc c
	ld a, W2_ScreenPalettesBuffer&$ff
	ld [$ff00+c],a
	inc c
	ld a, h
	ld [$ff00+c],a
	inc c
	ld a, l
	ld [$ff00+c],a
	inc c

	ld a, 6*32/$10-1
	ld [$ff00+c],a ; Start DMA transfer

.palettesDone
	xor a
	ld [rVBK],a
	ld [rSVBK],a
	ret


; Replaces the "TransferBgRows" function. Called when menus first appear on top of bg
; layer. (called 3 times to fully draw it)
; b = # rows to copy
; hl = destination
; sp = source (need to restore sp after this)
WindowTransferBgRowsAndColors:
	; Store # of rows to ocpy
	ld a,$02
	ld [rSVBK],a
	ld a,b
	ld [W2_VBCOPYBGNUMROWS],a
	xor a
	ld [rSVBK],a

.nextRow
	ld c,l
; Copy tilemap
rept 20 / 2 - 1
	pop de
	ld [hl],e
	inc l
	ld [hl],d
	inc l
endr
	pop de
	ld [hl],e
	inc l
	ld [hl],d

	; Go back to start of row to do palettes
	ld l,c
	add sp,-20
	ld a,$01
	ld [rVBK],a
	ld a,$02
	ld [rSVBK],a

	ld d, W2_TilesetPaletteMap>>8
rept 20 / 2
	pop bc
	ld e,c
	ld a,[de]
	ld [hli],a
	ld e,b
	ld a,[de]
	ld [hli],a
endr

	; Advance through "unused" tiles
	ld a,$0c
	add l
	ld l,a
	jr nc,.noCarry
	inc h
.noCarry
	ld a,[W2_VBCOPYBGNUMROWS]
	dec a
	ld [W2_VBCOPYBGNUMROWS],a

	ld a,$00 ; Don't xor so we don't change the flags
	ld [rVBK],a
	ld [rSVBK],a

	; Jump if W2_VBCOPYBGNUMROWS is nonzero
	jp nz,.nextRow

	ld a,[H_SPTEMP]
	ld h,a
	ld a,[H_SPTEMP+1]
	ld l,a
	ld sp,hl

	; Restore ROM bank (we obviously can't do that here, so jump to bank 0)
	ld a,[H_LOADEDROMBANK]
	jp SetRomBank


; Called when scrolling the screen vertically (at vblank)
DrawMapRow:
	ld a,2
	ld [rSVBK],a

	ld a,1
	ld [W2_DrewRowOrColumn],a

	ld hl,wRedrawRowOrColumnSrcTiles ; This is wram bank 0
	ld a,[hRedrawRowOrColumnDest]
	ld e,a
	ld a,[hRedrawRowOrColumnDest + 1]
	ld d,a
	push de
	call .drawHalf ; draw upper half
	pop de
	ld a,32 ; width of VRAM background map
	add e
	ld e,a
	call .drawHalf ; draw lower half

	; Start drawing palettes
	ld a,1
	ld [rVBK],a
	ld hl,wRedrawRowOrColumnSrcTiles
	ld a,[hRedrawRowOrColumnDest]
	ld e,a
	ld a,[hRedrawRowOrColumnDest + 1]
	ld d,a

	push de
	call .drawHalfPalette ; draw upper half
	pop de
	ld a,32 ; width of VRAM background map
	add e
	ld e,a
	call .drawHalfPalette ; draw lower half

	xor a
	ld [rSVBK],a
	ld [rVBK],a
	ret

.drawHalf
	ld c,10
.loop2
	ld a,[hli]
	ld [de],a
	inc de
	ld a,[hli]
	ld [de],a
	ld a,e
	inc a
; the following 6 lines wrap us from the right edge to the left edge if necessary
	and a,$1f
	ld b,a
	ld a,e
	and a,$e0
	or b
	ld e,a
	dec c
	jr nz,.loop2
	ret

.drawHalfPalette
	ld b, W2_TilesetPaletteMap>>8
REPT 10
	ld a,[hli]
	ld c,a
	ld a,[bc]
	ld [de],a
	inc de
	ld a,[hli]
	ld c,a
	ld a,[bc]
	ld [de],a
	ld a,e
	inc a
; the following 6 lines wrap us from the right edge to the left edge if necessary
	and a,$1f
	ld c,a
	ld a,e
	and a,$e0
	or c
	ld e,a
ENDR
	ret


; Called when scrolling the screen horizontally (at vblank)
DrawMapColumn:
	ld a,2
	ld [rSVBK],a

	ld a,1
	ld [W2_DrewRowOrColumn],a

	; Draw tiles
	ld hl,wRedrawRowOrColumnSrcTiles
	ld a,[hRedrawRowOrColumnDest]
	ld e,a
	ld a,[hRedrawRowOrColumnDest + 1]
	ld d,a
	ld c,SCREEN_HEIGHT
.loop1
	ld a,[hli]
	ld [de],a
	inc de
	ld a,[hli]
	ld [de],a
	ld a,31
	add e
	ld e,a
	jr nc,.noCarry
	inc d
.noCarry
; the following 4 lines wrap us from bottom to top if necessary
	ld a,d
	and a,$03
	or a,$98
	ld d,a
	dec c
	jr nz,.loop1

; =======================
	; Draw palettes
	ld a,1
	ld [rVBK],a

	ld hl,wRedrawRowOrColumnSrcTiles
	ld a,[hRedrawRowOrColumnDest]
	ld e,a
	ld a,[hRedrawRowOrColumnDest + 1]
	ld d,a
	ld b, W2_TilesetPaletteMap>>8
REPT 18
	ld a,[hli]
	ld c,a
	ld a,[bc]
	ld [de],a
	inc de
	ld a,[hli]
	ld c,a
	ld a,[bc]
	ld [de],a
	ld a,31
	add e
	ld e,a
	jr nc,.noCarry\@
	inc d
.noCarry\@
; the following 4 lines wrap us from bottom to top if necessary
	ld a,d
	and a,$03
	or a,$98
	ld d,a
ENDR

	xor a
	ld [hRedrawRowOrColumnMode],a
	ld [rVBK],a
	ld [rSVBK],a
	ret
