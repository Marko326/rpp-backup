; Pokédex Info browsing helpers.
; This file is included from bank $34 so the capacity-constrained ROM0 and
; bank $10 sections do not grow. Far-call inputs use DE because Bankswitch
; overwrites A/BC/HL before entering the target routine.

; Input: D = final Pokédex number, E = preferred visible row (0..6).
; Keep the current Pokémon on the same row when possible, clamping only near
; the beginning/end of the list so no rows extend beyond wDexMaxSeenMon.
PokedexData_SelectCurrentListEntry:
	ld a,d
	ld [wd11e],a
	dec a
	ld c,a ; zero-based absolute list index
	ld a,[wDexMaxSeenMon]
	cp 7
	jr c,.firstPage
	sub 7
	ld d,a ; maximum legal scroll offset
	ld a,c
	sub e
	jr nc,.havePreferredOffset
	xor a
.havePreferredOffset
	cp d
	jr c,.storeOffset
	ld a,d
.storeOffset
	ld [wListScrollOffset],a
	ld d,a
	ld a,c
	sub d
	ld [wCurrentMenuItem],a
	ld [wLastMenuItem],a
	ret
.firstPage
	xor a
	ld [wListScrollOffset],a
	ld a,c
	ld [wCurrentMenuItem],a
	ld [wLastMenuItem],a
	ret

PokedexData_BeginSessionVolume:
	; UpdateSound writes Volume back to NR50 every audio tick. Store the reduced
	; value in Volume itself so it persists for the whole Info session. Music Off
	; and BGM Volume 0 stay untouched to avoid changing silent routed DACs.
	ld a,[wOptions]
	bit 5,a
	ret nz
	ld a,[wBGMVolume]
	cp $a0
	ret z
	ld a,$33
	ld [Volume],a
	ret

PokedexData_EndSession:
	call GBPalWhiteOut
	call ClearScreen
	call RunDefaultPaletteCommand
	call LoadTextBoxTilePatterns
	call GBPalNormal
	ld hl,wd72c
	res 1,[hl]
	ld a,[wOptions]
	bit 5,a
	ret nz
	ld a,[wBGMVolume]
	cp $a0 ; BGM Volume 0 keeps the silent master-volume state
	ret z
	ld a,$77 ; restore the audio engine's normal master volume
	ld [Volume],a
	ret

PokedexData_WaitForVerticalRelease:
	call DelayFrame
	call Joypad
	ld a,[hJoyHeld]
	and D_UP | D_DOWN
	jr nz,PokedexData_WaitForVerticalRelease
	ret

; Return Z when the current Pokédex entry is Seen but not Owned, matching the
; original detail-screen rule that hides height/weight/description until caught.
PokedexData_CurrentMonOwned:
	ld a,[wcf91]
	ld [wd11e],a
	predef IndexToPokedex
	ld hl,wPokedexOwned
	call PokedexData_TestPokemonBit
	push af
	ld a,[wcf91]
	ld [wd11e],a
	pop af
	and a
	ret

; Input: E = 0 for the first description half, 1 for the second.
; The text is rendered directly from its far-ROM bytes into wTileMap. This keeps
; the global ROM0 text engine untouched: `next`, `page` and `dex` are consumed
; here instead of teaching Char49 a Pokédex-only behavior.
PokedexData_DrawDescriptionPage:
	ld a,e
	ld [wBuffer + 20],a
	coord hl,1,10
	lb bc,7,18
	call ClearScreenArea

	call PokedexData_GetDescriptionPointer
	jp nc,.finish
	ld [wBuffer + 29],a ; description ROM bank
	inc hl ; skip the leading `text` command byte

	ld a,[wBuffer + 20]
	and a
	jr z,.beginRender
.skipFirstHalf
	call PokedexData_ReadDescriptionLine
	jp nc,.finish
	cp $49 ; `page`
	jr z,.beginRender
	cp $5f ; `dex`: malformed/no second half
	jp z,.finish
	jr .skipFirstHalf

.beginRender
	coord de,1,11
	ld a,e
	ld [wBuffer + 22],a
	ld a,d
	ld [wBuffer + 23],a
.renderLine
	call PokedexData_ReadDescriptionLine
	jr nc,.finish
	ld [wBuffer + 21],a ; terminating command for this line
	push hl ; next far-ROM line pointer

	ld a,c
	and a
	jr z,.lineCopied
	; Terminate the buffered source line and let the normal PlaceString decoder
	; expand dictionary tokens such as # -> "Poké". The command byte itself was
	; not copied, so `next`/`page`/`dex` remain owned by this page renderer.
	ld b,0
	ld hl,wBuffer
	add hl,bc
	ld [hl],"@"
	ld de,wBuffer
	ld a,[wBuffer + 22]
	ld l,a
	ld a,[wBuffer + 23]
	ld h,a
	call PlaceString
	; Original Char5F writes the final period when `dex` ends an entry. Recreate
	; that one visible side effect after PlaceString returns BC = output endpoint.
	ld a,[wBuffer + 21]
	cp $5f
	jr nz,.lineCopied
	ld a,"."
	ld [bc],a
.lineCopied
	pop hl
	ld a,[wBuffer + 21]
	cp $4e ; `next`
	jr nz,.endPage
	; Pokédex description lines are intentionally double-spaced: the original
	; PlaceString `next` command advances by 2 * SCREEN_WIDTH, not one row.
	ld a,[wBuffer + 22]
	add 2 * SCREEN_WIDTH
	ld [wBuffer + 22],a
	jr nc,.renderLine
	ld a,[wBuffer + 23]
	inc a
	ld [wBuffer + 23],a
	jr .renderLine

.endPage
	cp $49 ; first half ended at `page`
	jr nz,.finish
	ld a,[wBuffer + 20]
	and a
	jr nz,.finish
	ld a,"▼"
	Coorda 18,16
.finish
	call Delay3
	ret

; Resolve the current internal species (wcf91) to its TX_FAR description.
; Output: carry set, A = text bank, HL = far pointer to the leading `text` byte.
PokedexData_GetDescriptionPointer:
	ld a,[wcf91]
	dec a
	ld e,a
	ld d,0
	ld hl,PokedexEntryPointers
	add hl,de
	add hl,de
	ld de,wBuffer
	ld bc,2
	ld a,BANK(PokedexEntryPointers)
	call FarCopyData
	ld a,[wBuffer]
	ld l,a
	ld a,[wBuffer + 1]
	ld h,a
.findSpeciesEnd
	ld de,wBuffer + 28
	ld bc,1
	ld a,BANK(PokedexEntryPointers)
	call FarCopyData
	ld a,[wBuffer + 28]
	cp "@"
	jr nz,.findSpeciesEnd
	; HL is now just after the species terminator. Skip height (2), weight (2)
	; and the TX_FAR opcode, then read pointer low/high and bank.
	ld de,5
	add hl,de
	ld de,wBuffer
	ld bc,3
	ld a,BANK(PokedexEntryPointers)
	call FarCopyData
	ld a,[wBuffer]
	ld l,a
	ld a,[wBuffer + 1]
	ld h,a
	ld a,[wBuffer + 2]
	scf
	ret

; Read one encoded description line without crossing the source bank boundary.
; Input: HL = far source line, wBuffer+29 = source bank.
; Output: carry set, A = terminator (`next`/`page`/`dex`), C = character count,
;         HL = source immediately after the terminator, wBuffer = line bytes.
;         carry clear if no terminator is found within the 18-column line limit.
PokedexData_ReadDescriptionLine:
	push hl ; original line start
	xor a
	ld [wBuffer + 27],a ; character count
.scan
	ld de,wBuffer + 28
	ld bc,1
	ld a,[wBuffer + 29]
	call FarCopyData ; advances HL by one source byte
	ld a,[wBuffer + 28]
	cp $4e ; `next`
	jr z,.found
	cp $49 ; `page`
	jr z,.found
	cp $5f ; `dex`
	jr z,.found
	ld a,[wBuffer + 27]
	inc a
	ld [wBuffer + 27],a
	cp 19 ; source data is constrained to the 18-column Pokédex text area
	jr c,.scan
	pop de ; discard original line start
	and a
	ret
.found
	ld [wBuffer + 26],a
	ld a,l
	ld [wBuffer + 24],a
	ld a,h
	ld [wBuffer + 25],a
	pop hl ; restore original line start for an exact-length copy
	ld a,[wBuffer + 27]
	and a
	jr z,.restoreNext
	ld c,a
	ld b,0
	ld de,wBuffer
	ld a,[wBuffer + 29]
	call FarCopyData
.restoreNext
	ld a,[wBuffer + 24]
	ld l,a
	ld a,[wBuffer + 25]
	ld h,a
	ld a,[wBuffer + 27]
	ld c,a
	ld a,[wBuffer + 26]
	scf
	ret

; Input: E = fresh D_UP or D_DOWN press, wd11e = current internal species.
; Output: carry set with wd11e changed to the previous/next Seen species;
; carry clear with the original internal species restored when no target exists.
; Navigation stops at the first/last Seen boundary and never wraps. Unseen
; entries between Seen Pokémon are still skipped in the selected direction.
PokedexData_TryStepSeen:
	ld a,e
	ld [wBuffer + 20],a
	ld a,[wd11e]
	push af
	predef IndexToPokedex
.search
	ld a,[wBuffer + 20]
	bit BIT_D_UP,a
	jr z,.down
.up
	ld a,[wd11e]
	cp 1
	jr z,.noChange
	dec a
	jr .candidate
.down
	ld a,[wDexMaxSeenMon]
	ld c,a
	ld a,[wd11e]
	cp c
	jr nc,.noChange
	inc a
.candidate
	ld [wd11e],a
	ld hl,wPokedexSeen
	call PokedexData_TestPokemonBit
	jr z,.search
	callba PokedexToIndex
	pop af ; discard saved original internal index
	scf
	ret
.noChange
	pop af
	ld [wd11e],a
	and a
	ret

; Same bit-test primitive used by bank $10's IsPokemonBitSet, kept local so a
; far call never needs to pass HL/BC through Bankswitch (which overwrites them).
PokedexData_TestPokemonBit:
	ld a,[wd11e]
	dec a
	ld c,a
	ld b,FLAG_TEST
	predef FlagActionPredef
	ld a,c
	and a
	ret
