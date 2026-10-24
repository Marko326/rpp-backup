NameRaterScript_1da15:
	call PrintTextAndYesNoChoice
	ret

NameRaterScript_1da20:
	ld hl, wPartyMonOT
	ld bc, NAME_LENGTH
	ld a, [wWhichPokemon]
	call AddNTimes
	ld de, wPlayerName
	ld c, NAME_LENGTH
	call .asm_1da47
	jr c, .asm_1da52
	ld hl, wPartyMon1OTID
	ld bc, wPartyMon2 - wPartyMon1
	ld a, [wWhichPokemon]
	call AddNTimes
	ld de, wPlayerID
	ld c, $2
.asm_1da47
	ld a, [de]
	cp [hl]
	jr nz, .asm_1da52
	inc hl
	inc de
	dec c
	jr nz, .asm_1da47
	and a
	ret
.asm_1da52
	scf
	ret

NameRaterTextPointers:
	dw NameRaterText1

NameRaterText1:
	TX_ASM
	call SaveScreenTilesToBuffer2
	ld hl, NameRaterText_1dab3
	call NameRaterScript_1da15
	jr nz, .asm_1daae
	ld hl, NameRaterText_1dab8
	call PrintText
.chooseMon
	; MENU-5.61.06: naming-screen/text restoration re-enables overworld sprite
	; updates. Reapply Party state before every return so Pokémon icons stay in OAM.
	xor a
	ld [wPartyMenuTypeOrMessageID], a
	ld [wUpdateSpritesEnabled], a
	ld [wMenuItemToSwap], a
	; MENU-5.61.06: keep Party as the parent of rename confirmation/naming.
	call DisplayPartyMenu
	push af
	call GBPalWhiteOutWithDelay3
	call RestoreScreenTilesAndReloadTilePatterns
	call LoadGBPal
	pop af
	jr c, .asm_1daae
	call GetPartyMonName2
	ld a, [wExtraFlags]
	bit 2, a
	jr nz, .canRename
	call NameRaterScript_1da20
	ld hl, NameRaterText_1dad1
	jr c, .asm_1daa8
.canRename
	ld hl, NameRaterText_1dabd
	call NameRaterScript_1da15
	jp nz, .chooseMon ; No/B only cancels this Pokémon's rename operation
	ld hl, NameRaterText_1dac2
	call PrintText
	callba DisplayNameRaterScreen
	jp c, .chooseMon ; empty-name cancel also returns to the Pokémon list
	ld hl, NameRaterText_1dac7
.asm_1daa8
	jp PrintTextAndTextScriptEnd
.asm_1daae
	ld hl, NameRaterText_1dacc
	jr .asm_1daa8

NameRaterText_1dab3:
	TX_FAR _NameRaterText_1dab3
	db "@"

NameRaterText_1dab8:
	TX_FAR _NameRaterText_1dab8
	db "@"

NameRaterText_1dabd:
	TX_FAR _NameRaterText_1dabd
	db "@"

NameRaterText_1dac2:
	TX_FAR _NameRaterText_1dac2
	db "@"

NameRaterText_1dac7:
	TX_FAR _NameRaterText_1dac7
	db "@"

NameRaterText_1dacc:
	TX_FAR _NameRaterText_1dacc
	db "@"

NameRaterText_1dad1:
	TX_FAR _NameRaterText_1dad1
	db "@"
