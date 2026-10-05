VBlank::

	push af
	push bc
	push de
	push hl

	ld a, [H_LOADEDROMBANK]
	ld [wVBlankSavedROMBank], a

	ld a, [hSCX]
	ld [rSCX], a

	; ANM-5.62.06: mode 5 is the VBlank-latched Iron Tail raster stop. The
	; active mode is configured later, after the normal LY=$6e color interrupt.
	ld a, [wBattleAnimRasterMode]
	cp 5
	jr nz, .ironTailRasterDone
	xor a
	ld [wBattleAnimRasterMode], a
	ld [wBattleAnimRasterTableHigh], a
.ironTailRasterDone

	; ANM-5.61.94: Icy Wind swaps between two page-aligned SCY tables at the VBlank boundary.
	; This gives line 0 its own value before the fast STAT path owns lines 1..143.
	ld a, [wBattleAnimRasterMode]
	cp 2
	jr z, .icyWindRasterStartFrame
	cp 3
	jr z, .icyWindRasterStop
.normalSCY
	ld a, [hSCY]
	jr .commitSCY
.icyWindRasterStartFrame
	ld a, [wBattleAnimRasterTableHigh]
	cp HIGH(wIcyWindWaveBufferA)
	ld a, HIGH(wIcyWindWaveBufferA)
	jr nz, .icyWindRasterTableReady
	ld a, HIGH(wIcyWindWaveBufferB)
.icyWindRasterTableReady
	ld [wBattleAnimRasterTableHigh], a
	ld h, a
	ld l, 0
	ld a, [hl]
	ld [rSCY], a
	; The prior visible frame disabled mode-0 at its target-band boundary. Arm it
	; again only now, after line 0 has been preloaded for this complete frame.
	ld a, [rSTAT]
	or $08
	ld [rSTAT], a
	ld a, [wIcyWindRasterHue]
	ld [rBGP], a
	ld [rOBP1], a
	jr .scyDone
.icyWindRasterStop
	; Mode 3 is requested during the final visible wave frame. Stop mode-0 STAT
	; before the following line 0 and restore the ordinary SCY shadow.
	ld a, [rSTAT]
	and $f7
	ld [rSTAT], a
	xor a
	ld [wBattleAnimRasterMode], a
	ld a, [hSCY]
.commitSCY
	ld [rSCY], a
.scyDone

	ld a, [wDisableVBlankWYUpdate]
	and a
	jr nz, .ok
	ld a, [hWY]
	ld [rWY], a
.ok

	call AutoBgMapTransfer
	call VBlankCopyBgMap
	call RedrawRowOrColumn
	call VBlankCopy
	call VBlankCopyDouble
	;call UpdateMovingBgTiles
	call $ff80 ; OAM DMA
	rst $10 ; HAX: VBlank hook (loads palettes)
	nop
	nop

	; Iron Tail keeps Gold's exact user bands (enemy Y=0..55, player Y=48..95).
	; LYC fires on the preceding line and only arms mode-0; the actual SCX switch
	; happens in that line's HBlank, after every target pixel has finished drawing.
	ld a, [wBattleAnimRasterMode]
	cp 4
	jr nz, .ironTailLYCDone
	ld a, [rSTAT]
	and $f7
	or $40
	ld [rSTAT], a
	ld a, [rIE]
	or 1 << LCD_STAT
	ld [rIE], a
	ldh a, [H_WHOSETURN]
	and a
	jr z, .ironTailPlayerLYC
	; Enemy user starts shifted at line 0. HBlank 55 restores baseline for line 56.
	ld a, [wBattleAnimRasterTableHigh]
	ld [rSCX], a
	ld a, $37
	jr .ironTailSetLYC
.ironTailPlayerLYC
	; Player user starts shifting after HBlank 47, so line 48 is the first moved row.
	ld a, $2f
.ironTailSetLYC
	ld [rLYC], a
.ironTailLYCDone
	; HAX: don't update sprites here. They're updated elsewhere to prevent wobbliness.
	;ld a, Bank(PrepareOAMData)
	nop
	nop
	;ld [H_LOADEDROMBANK], a
	nop
	nop
	;ld [MBC1RomBank], a
	nop
	nop
	nop
	;call PrepareOAMData ; update OAM buffer with current sprite data
	nop
	nop
	nop

	; VBlank-sensitive operations end. Icy Wind still needs its mode-0 STAT
	; handler to preempt the long audio/timekeeping tail if it spills into visible
	; lines. Iron Tail only arms mode-0 later from sparse visible-line LYC triggers.
	ld a, [wBattleAnimRasterMode]
	cp 2
	jr z, .battleRasterInterruptibleTail
	call .nonCriticalTail
	jr .finish
.battleRasterInterruptibleTail
	ld a, [rIE]
	push af
	ld a, 1 << LCD_STAT
	ld [rIE], a
	ei
	call .nonCriticalTail
	di
	pop af
	ld [rIE], a
.finish
	pop hl
	pop de
	pop bc
	pop af
	ret

.nonCriticalTail
	call Random

	ld a, [H_VBLANKOCCURRED]
	and a
	jr z, .skipZeroing
	xor a
	ld [H_VBLANKOCCURRED], a

.skipZeroing
	; 下箭头闪烁使用独立的每帧锁，不再借用 DelayFrame 的同步标记。
	xor a
	ld [hDownArrowBlinkFrameProcessed], a

	ld a, [H_FRAMECOUNTER]
	and a
	jr z, .skipDec
	dec a
	ld [H_FRAMECOUNTER], a

.skipDec
;	call FadeOutAudio

	call UpdateSound
;	ld a, [wAudioROMBank] ; music ROM bank
;	ld [H_LOADEDROMBANK], a
;	ld [MBC1RomBank], a

;	cp BANK(Audio1_UpdateMusic)
;	jr nz, .checkForAudio2
;.audio1
;	call Audio1_UpdateMusic
;	jr .afterMusic
;.checkForAudio2
;	cp BANK(Audio2_UpdateMusic)
;	jr nz, .audio3
;.audio2
;	call Music_DoLowHealthAlarm
;	call Audio2_UpdateMusic
;	jr .afterMusic
;.audio3
;	call Audio3_UpdateMusic
;.afterMusic

	callba TrackPlayTime ; keep track of time played

	ld a, [hDisableJoypadPolling]
	and a
	call z, ReadJoypad

	ld a, [wVBlankSavedROMBank]
	ld [H_LOADEDROMBANK], a
	ld [MBC1RomBank], a
	ret


DelayFrame::
; Wait for the next vblank interrupt.
; As a bonus, this saves battery.

NOT_VBLANKED EQU 1

	call DelayFrameHook ; HAX
	nop
	;ld a,1
	;ld [H_VBLANKOCCURRED],a
.halt
	halt
	ld a, [H_VBLANKOCCURRED]
	and a
	jr nz,.halt
	ret
