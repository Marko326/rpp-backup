; Colosseum50 party normalization lives in bank $35 because bank 1 is tight.
; Call this routine with callba immediately before link party serialization.

; Temporarily converts every player-party member to level 50 and recalculates
; its five battle stats from species base stats, Stat Exp and DVs.
; Moves, PP Ups, experience, Stat Exp, DVs and ownership data are preserved.
; The mandatory Cable Club save remains unchanged and Soft Reset restores it.
NormalizePartyForLevel50LinkBattle:
	xor a ; PLAYER_PARTY_DATA
	ld [wMonDataLocation], a
	ld [wWhichPokemon], a
	ld a, [wPartyCount]
	and a
	ret z

.loop
	call LoadMonData

	; Keep both stored level fields consistent with the recalculated stats.
	ld a, LINK_BATTLE_LEVEL_50
	ld [wLoadedMonBoxLevel], a
	ld [wLoadedMonLevel], a
	ld [wCurEnemyLVL], a

	; Recalculate level-50 HP, Attack, Defense, Speed and Special.
	ld hl, wLoadedMonHPExp - 1
	ld de, wLoadedMonStats
	ld b, 1 ; include Stat Exp in the standard generation-I formula
	call CalcStats

	; Use the new maximum HP before copying the temporary structure back.
	ld a, [wLoadedMonMaxHP]
	ld [wLoadedMonHP], a
	ld a, [wLoadedMonMaxHP + 1]
	ld [wLoadedMonHP + 1], a

	; Copy one complete party structure; growth data and moves were not edited.
	ld hl, wPartyMons
	ld bc, wPartyMon2 - wPartyMon1
	ld a, [wWhichPokemon]
	call AddNTimes
	ld d, h
	ld e, l
	ld hl, wLoadedMon
	ld bc, wPartyMon2 - wPartyMon1
	call CopyData

	ld hl, wWhichPokemon
	inc [hl]
	ld a, [wPartyCount]
	cp [hl]
	jr nz, .loop

	; Match normal Colosseum behavior: each battle starts fully healed.
	predef HealParty
	xor a
	ld [wWhichPokemon], a
	ld [wMonDataLocation], a
	ret
