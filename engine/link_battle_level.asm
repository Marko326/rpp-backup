; Link battle level normalization is placed in bank $35 because bank1 is full.
; Calls from the Cable Club code must use callba.

; Temporarily normalizes the player's party for Colosseum battles.
; The Cable Club requires a save before entry and reloads it when leaving, so
; level, HP, status, PP and calculated stats are never written to the save file.
; Moves, experience, stat experience and DVs are copied back unchanged.
NormalizePartyForLinkBattle:
	xor a ; PLAYER_PARTY_DATA
	ld [wMonDataLocation], a
	ld [wWhichPokemon], a
	ld a, [wPartyCount]
	and a
	ret z

.loop
	call LoadMonData

	ld a, LINK_BATTLE_LEVEL
	ld [wLoadedMonBoxLevel], a
	ld [wLoadedMonLevel], a
	ld [wCurEnemyLVL], a

	; Recalculate level 50 stats from base stats, Stat Exp and DVs.
	ld hl, wLoadedMonHPExp - 1
	ld de, wLoadedMonStats
	ld b, 1
	call CalcStats

	; Keep the temporary party data internally consistent before HealParty.
	ld a, [wLoadedMonMaxHP]
	ld [wLoadedMonHP], a
	ld a, [wLoadedMonMaxHP + 1]
	ld [wLoadedMonHP + 1], a

	; Copy the normalized party struct back without changing moves or growth data.
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

	; Colosseum parties start each battle fully healed, including rematches.
	predef HealParty
	xor a
	ld [wWhichPokemon], a
	ld [wMonDataLocation], a
	ret

