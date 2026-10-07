; EVO-5.62.27: keep evolution-stone compatibility/level UI out of fixed banks
; $03/$04. The EV_ITEM layout is item, minimum level, target species.

EvolutionStoneGetMinimumLevel::
	; Registered regional forms own their evolution table. Carry from the bank-$34
	; helper says the instance was handled; E is 0 or the matching minimum level.
	callba RegionalFormGetEvolutionStoneMinimumLevel
	ret c

	; Stock species keep their evolution data in bank $0E. Read the 16-bit table
	; pointer once, then stream one byte at a time instead of copying a maximum-size
	; evolution block into wEnemyMon, which crosses the $CFFF WRAM0 boundary.
	ld hl,EvosMovesPointerTable
	ld b,0
	ld a,[wLoadedMonSpecies]
	dec a
	add a
	rl b
	ld c,a
	add hl,bc
	ld de,wEvolutionStoneReadPointer
	ld a,BANK(EvosMovesPointerTable)
	ld bc,2
	call FarCopyData2
.loop
	call .readStockByte
	and a
	jr z,.notAble
	cp EV_ITEM
	jr z,.item
	ld c,2
	cp EV_RAND
	jr z,.longPayload
	cp EV_TYROGUE
	jr nz,.skipPayload
.longPayload
	inc c
.skipPayload
	call .readStockByte
	dec c
	jr nz,.skipPayload
	jr .loop
.item
	call .readStockByte
	ld b,a ; required item
	call .readStockByte
	ld e,a ; minimum level
	call .readStockByte ; target species
	ld a,[wEvoStoneItemID]
	cp b
	jr nz,.loop
	ret
.notAble
	xor a
	ld e,a
	ret

.readStockByte
	; Preserve the parser's BC/DE state while FarCopyData2 uses them for its
	; one-byte transfer. The source pointer advances in HL and is stored back.
	push bc
	push de
	ld a,[wEvolutionStoneReadPointer]
	ld l,a
	ld a,[wEvolutionStoneReadPointer + 1]
	ld h,a
	ld de,wBuffer
	ld a,BANK(EvosMovesPointerTable)
	ld bc,1
	call FarCopyData2
	ld a,l
	ld [wEvolutionStoneReadPointer],a
	ld a,h
	ld [wEvolutionStoneReadPointer + 1],a
	ld a,[wBuffer]
	pop de
	pop bc
	ret

EvolutionStoneDrawPartyStatus::
	; INPUT: DE = current Party-menu entry origin. CALLBA overwrites HL with this
	; function's ROM address, so HL must never be used as an incoming tilemap ptr.
	; Preserve DE before the lookup because the lookup itself uses DE as scratch.
	push de
	call EvolutionStoneGetMinimumLevel
	ld a,e
	and a
	jr z,.notAble
	ld b,a
	ld a,[wLoadedMonLevel]
	cp b
	jr c,.levelRequired
	ld de,.ableText
	jr .placeText
.notAble
	ld de,.notAbleText
.placeText
	pop hl
	ld bc,SCREEN_WIDTH + 9
	add hl,bc
	jp PlaceString
.levelRequired
	; Matching stone, but not usable yet: show the requirement instead of
	; misleading the player with either Able or Not able.
	ld a,e
	ld [wd11e],a
	pop hl
	ld bc,SCREEN_WIDTH + 9
	add hl,bc
	ld a,"L"
	ld [hli],a
	ld a,"v"
	ld [hli],a
	ld de,wd11e
	ld b,LEFT_ALIGN | 1
	ld c,3
	call PrintNumber
	ld [hl],"+"
	ret
.ableText
	db "Able@"
.notAbleText
	db "Not able@"

EvolutionStoneCheckSelectedMonLevel::
	; DisplayPartyMenu leaves wWhichPokemon on the selected slot. Reload that exact
	; instance so the check uses its species, persistent form marker, and level.
	; Carry set means the stone must not be used. wd11e is 0 for a non-matching
	; stone, or the dynamic minimum level when the only blocker is level.
	call LoadMonData
	ld a,[wEvoStoneItemID]
	ld [wcf91],a ; LoadMonData returns the species here; restore the used stone
	call EvolutionStoneGetMinimumLevel
	ld a,e
	ld [wd11e],a
	and a
	jr z,.blocked
	ld b,a
	ld a,[wLoadedMonLevel]
	cp b
	jr nc,.allowed
	ld hl,.needsLevelText
	call PrintText
.blocked
	scf
	ret
.allowed
	and a ; clear carry
	ret
.needsLevelText
	text "It has no effect"
	line "before Lv@"
	TX_NUM wd11e,1,3
	text "."
	prompt
