; EGG-A4-5.61.75: runtime move types that inherit the acting Pokemon's first type.
; Keep the policy table-driven so another move can opt in with one data byte.

ApplyCurrentMovePrimaryTypeOverride::
	call GetCurrentMoveID
	call IsPrimaryTypeMove
	ret nc
	ldh a, [H_WHOSETURN]
	and a
	jr nz, .enemy
	ld a, [wBattleMonType1]
	ld [wPlayerMoveType], a
	ret
.enemy
	ld a, [wEnemyMonType1]
	ld [wEnemyMoveType], a
	ret

; Input: C = enemy AI candidate real move ID (callba does not preserve A).
ApplyEnemyCandidatePrimaryTypeOverride::
	; MOVE-5.62.155: evaluate mapped Bite as BUG for enemy AI.
	ld a, c
	cp AGILITY
	jr z, .rockPolish
	cp BITE
	jr nz, .primaryType
	push bc ; IsInArray overwrites B/C, including the candidate move ID.
	ld a, [wEnemyMonSpecies]
	call IsBugBiteSpecies
	pop bc
	jr nc, .primaryType
	ld a, BUG
	ld [wEnemyMoveType], a
	xor a
	ld [wEnemyMoveEffect], a
	ret
.rockPolish
	push bc
	ld a, [wEnemyMonSpecies]
	call IsRockPolishSpecies
	pop bc
	jr nc, .primaryType
	ld a, ROCK
	ld [wEnemyMoveType], a
	ret
.primaryType
	ld a, c
	call IsPrimaryTypeMove
	ret nc
	ld a, [wEnemyMonType1]
	ld [wEnemyMoveType], a
	ret

IsPrimaryTypeMove:
	ld hl, PrimaryTypeMoveIDs
	ld de, 1
	jp IsInArray

PrimaryTypeMoveIDs:
	db EGG_BOMB
	db $ff

; GetCurrentMove loads a real selected move into the side-specific six-byte move
; buffer, then tail-calls here. Keep its original name-loading behavior intact.
FinalizeCurrentMoveLoad::
	callba MaybeLoadExperimentalMoveBattleStats
	call ApplyCurrentMovePrimaryTypeOverride
	call ApplyCurrentBugBiteOverride
	call ApplyCurrentRockPolishTypeOverride
	ldh a, [H_WHOSETURN]
	and a
	jr nz, .ordinaryName
	ld a, [wExtendedActiveMoveOrdinal]
	and a
	jr z, .ordinaryName
	ld e, a ; ordinal survives CALLBA in DE
	callba LoadExtendedMoveNameByOrdinalToCD6D
	jr c, .ordinaryName
	ld de, wcd6d
	jp CopyStringToCF4B
.ordinaryName
	call GetCurrentMoveID
	cp EXT_MOVE_SLOT_ESCAPE
	jr z, .powerWhipName
	ld a, BANK(MoveNames)
	ld [wPredefBank], a
	ld a, MOVE_NAME
	ld [wNameListType], a
	call GetName
	call GetCurrentBattleMoveNamePointer
	jp CopyStringToCF4B
.powerWhipName
	ld de, PowerWhipExperimentName
	jp CopyStringToCF4B

; Metronome / Mirror Move / Mimic reload an already-selected child move. Their
; historical return contract is NZ on success, so preserve it here.
FinalizeReloadedMoveData::
	call ApplyCurrentMovePrimaryTypeOverride
	call ApplyCurrentBugBiteOverride
	call ApplyCurrentRockPolishTypeOverride
	call GetMoveName
	call GetCurrentBattleMoveNamePointer
	call CopyStringToCF4B
	ld a, $1
	and a
	ret

; MOVE-5.62.155: battle-only reinterpretation of real BITE ($2C).
; The six-byte current move buffer is temporary; stored IDs, PP, animation,
; and the global Bite move record remain unchanged.
ApplyCurrentBugBiteOverride:
	call GetCurrentMoveID
	cp BITE
	ret nz
	call GetActingBattleSpecies
	call IsBugBiteSpecies
	ret nc
	ldh a, [H_WHOSETURN]
	and a
	jr nz, .enemy
	ld a, BUG
	ld [wPlayerMoveType], a
	xor a ; NO_ADDITIONAL_EFFECT
	ld [wPlayerMoveEffect], a
	ret
.enemy
	ld a, BUG
	ld [wEnemyMoveType], a
	xor a
	ld [wEnemyMoveEffect], a
	ret

; Mapped AGILITY keeps its +2 Speed effect and 30 PP, but uses ROCK during
; battle for the Rock Polish family. Never alter the shared move record.
ApplyCurrentRockPolishTypeOverride:
	call GetCurrentMoveID
	cp AGILITY
	ret nz
	call GetActingBattleSpecies
	call IsRockPolishSpecies
	ret nc
	ldh a, [H_WHOSETURN]
	and a
	jr nz, .enemy
	ld a, ROCK
	ld [wPlayerMoveType], a
	ret
.enemy
	ld a, ROCK
	ld [wEnemyMoveType], a
	ret

; Input: none; output A=the currently acting species. Transform already
; updates the runtime species, so copied moves follow the current user.
GetActingBattleSpecies:
	ldh a, [H_WHOSETURN]
	and a
	jr nz, .enemy
	ld a, [wBattleMonSpecies]
	ret
.enemy
	ld a, [wEnemyMonSpecies]
	ret

; Carry set for species authorized to reinterpret BITE during battle.
; Keep this explicit so unrelated Bug-types are not silently affected.
IsBugBiteSpecies:
	ld hl, BugBiteSpeciesIDs
	ld de, 1
	jp IsInArray

BugBiteSpeciesIDs:
	db CATERPIE, METAPOD, BUTTERFREE
	db WEEDLE, KAKUNA, BEEDRILL
	db PARAS, PARASECT
	db $ff

; Call only after the original GetName/GetMoveName has filled wcd6d.
; This never changes the global move name or out-of-battle screens.
GetCurrentBattleMoveNamePointer:
	call GetCurrentMoveID
	cp BITE
	jr z, .bugBite
	cp AGILITY
	jr nz, .normal
	call GetActingBattleSpecies
	call IsRockPolishSpecies
	jr nc, .normal
	ld de, RockPolishBattleName
	ret
.bugBite
	call GetActingBattleSpecies
	call IsBugBiteSpecies
	jr nc, .normal
	ld de, BugBiteBattleName
	ret
.normal
	ld de, wcd6d ; IsInArray overwrites DE, so set it last.
	ret

; Only AGILITY is reinterpreted. Preserve ROCK_POLISH ($F0) for old saves
; and the separately maintained regional learnsets during this trial.
IsRockPolishSpecies:
	ld hl, RockPolishSpeciesIDs
	ld de, 1
	jp IsInArray

RockPolishSpeciesIDs:
	db GEODUDE, GRAVELER, GOLEM, ONIX, STEELIX
	db $ff

; Used by the animation bank through callab; the result is a carry flag.
IsRockPolishActingUser::
	call GetActingBattleSpecies
	jp IsRockPolishSpecies

BugBiteBattleName:
	db "Bug Bite@"

RockPolishBattleName:
	db "Rock Polish@"

; MOVE-5.62.171: legacy aliases retained only as local rendering fallbacks;
; the generic extended name loader is now the identity source for all ordinals.
PowerWhipExperimentName:
	db "Power Whip@"

PlayRoughExperimentName:
	db "Play Rough@"

GetExtendedRenderedSlotName:
	push bc
	push de
	push af
	ld d, a
	ld a, b
	ld e, a
	ld a, c
.shift
	ld c, a
	ld a, e
	and a
	ld a, c
	jr z, .bit
	srl a
	dec e
	jr .shift
.bit
	and 1
	jr z, .ordinary
	ld e, d ; one-based ordinal survives CALLBA in DE
	callba LoadExtendedMoveNameByOrdinalToCD6D
	jr c, .ordinary
	ld hl, wcd6d
	pop af
	pop de
	pop bc
	scf
	ret
.ordinary
	pop af
	pop de
	pop bc
	and a
	ret

; Only the regular in-battle Fight menu calls this entry. Mimic, relearn,
; Party/PC, and all other FormatMovesString callers stay stock.
FormatBugBiteBattleMovesString::
	ld hl, wMoves
	ld de, wMovesString
	ld b, 0
.moveLoop
	ld a, [hli]
	and a
	jp z, .dashLoop
	push hl
	push af
	ld a, [wExtendedBattleMoveFlags]
	ld c, a
	pop af
	call GetExtendedRenderedSlotName
	jr c, .copyName
	cp EXT_MOVE_SLOT_ESCAPE
	jr nz, .checkNormalMove
	ld hl, PowerWhipExperimentName
	jr .copyName
.checkNormalMove
	cp BITE
	jr z, .checkBite
	cp AGILITY
	jr z, .checkPolish
	jr .normalMove
.checkBite
	push bc
	push de ; IsInArray uses DE as its stride and B/C as scratch.
	ld a, [wBattleMonSpecies]
	call IsBugBiteSpecies
	pop de
	pop bc
	jr nc, .ordinaryBite
	ld hl, BugBiteBattleName
	jr .copyName
.ordinaryBite
	ld a, BITE
	jr .normalMove
.checkPolish
	push bc
	push de
	ld a, [wBattleMonSpecies]
	call IsRockPolishSpecies
	pop de
	pop bc
	jr nc, .ordinaryAgility
	ld hl, RockPolishBattleName
	jr .copyName
.ordinaryAgility
	ld a, AGILITY
.normalMove
	ld [wd0b5], a
	ld a, BANK(MoveNames)
	ld [wPredefBank], a
	ld a, MOVE_NAME
	ld [wNameListType], a
	call GetName
	ld hl, wcd6d
.copyName
	ld a, [hli]
	cp "@"
	jr z, .endName
	ld [de], a
	inc de
	jr .copyName
.endName
	ld a, b
	ld [wNumMovesMinusOne], a
	inc b
	ld a, $4e ; line break
	ld [de], a
	inc de
	pop hl
	ld a, b
	cp NUM_MOVES
	jr z, .done
	jp .moveLoop
.dashLoop
	ld a, "-"
	ld [de], a
	inc de
	inc b
	ld a, b
	cp NUM_MOVES
	jr z, .done
	ld a, $4e
	ld [de], a
	inc de
	jr .dashLoop
.done
	ld a, "@"
	ld [de], a
	ret

; MOVE-5.62.161: Party/PC StatusScreen Page 2 only. Handle each stored
; AGILITY using the currently loaded mon species, within this same ROM bank.
; All other IDs use the stock GetName path. Rebuild wMovesString to keep
; the longer alias from shifting adjacent lines; do not alter MoveDex.
FormatRockPolishStatusMovesString::
	ld hl, wMoves
	ld de, wMovesString
	ld b, 0
.moveLoop
	ld a, [hli]
	and a
	jp z, .dashLoop
	push hl
	push af
	ld a, [wExtendedStatusMoveFlags]
	ld c, a
	pop af
	call GetExtendedRenderedSlotName
	jr c, .copyName
	cp EXT_MOVE_SLOT_ESCAPE
	jr nz, .checkAgility
	ld hl, PowerWhipExperimentName
	jr .copyName
.checkAgility
	cp AGILITY
	jr nz, .normalMove
	; StatusScreen_LoadCurrentMon has already copied the selected
	; party/box member into wLoadedMon. Use its actual species byte.
	ld a, [wLoadedMonSpecies]
	cp GEODUDE
	jr z, .mappedAgility
	cp GRAVELER
	jr z, .mappedAgility
	cp GOLEM
	jr z, .mappedAgility
	cp ONIX
	jr z, .mappedAgility
	cp STEELIX
	jr z, .mappedAgility
	ld a, AGILITY
	jr .normalMove
.mappedAgility
	ld hl, RockPolishBattleName
	jr .copyName
.normalMove
	ld [wd0b5], a
	ld a, BANK(MoveNames)
	ld [wPredefBank], a
	ld a, MOVE_NAME
	ld [wNameListType], a
	call GetName
	ld hl, wcd6d
.copyName
	ld a, [hli]
	cp "@"
	jr z, .endName
	ld [de], a
	inc de
	jr .copyName
.endName
	ld a, b
	ld [wNumMovesMinusOne], a
	inc b
	ld a, $4e ; line break
	ld [de], a
	inc de
	pop hl
	ld a, b
	cp NUM_MOVES
	jr z, .done
	jp .moveLoop
.dashLoop
	ld a, "-"
	ld [de], a
	inc de
	inc b
	ld a, b
	cp NUM_MOVES
	jr z, .done
	ld a, $4e
	ld [de], a
	inc de
	jr .dashLoop
.done
	ld a, "@"
	ld [de], a
	ret

; MOVE-5.62.161: learn-move prompts and replacement text only. GetMoveName
; has already put the base name in wcd6d. Its input wd11e is the REAL move ID;
; wWhichPokemon is the selected 0-based party slot, not a list row.
; Return DE = wcd6d as GetMoveName does; do not change the global MoveNames.
MaybeRenameRockPolishLearningMoveName::
	ld a, [wd11e]
	cp AGILITY
	jr nz, .original
	call GetRockPolishLearningSpecies
	call IsRockPolishSpecies
	jr nc, .original
	ld de, RockPolishBattleName
	ld hl, wcd6d
	call CopyString ; DE = source and HL = destination, never reversed.
.original
	ld de, wcd6d
	ret

; Input: wWhichPokemon = selected party index. Returns species in A.
; No scratch WRAM or menu-row state is introduced.
GetRockPolishLearningSpecies:
	ld a, [wWhichPokemon]
	ld c, a
	ld b, 0
	ld hl, wPartySpecies
	add hl, bc
	ld a, [hl]
	ret

; Move-forget four-row list only. The learned move prompt retains wcf4b;
; all old-move names are built afresh, including the longer Rock Polish.
; This is NOT the relearner/deleter list or the shared FormatMovesString.
FormatRockPolishLearningMovesString::
	ld hl, wMoves
	ld de, wMovesString
	ld b, 0
.moveLoop
	ld a, [hli]
	and a
	jp z, .dashLoop
	push hl
	push af
	push bc
	callab GetCurrentPartyExtendedMoveMask
	pop bc
	ld a, [wExtendedMoveFlagsScratch]
	ld c, a
	pop af
	call GetExtendedRenderedSlotName
	jr c, .copyName
	cp EXT_MOVE_SLOT_ESCAPE
	jr nz, .checkAgility
	ld hl, PowerWhipExperimentName
	jr .copyName
.checkAgility
	cp AGILITY
	jr nz, .normalMove
	; Preserve renderer loop index and output pointer across species check.
	push bc
	push de
	call GetRockPolishLearningSpecies
	call IsRockPolishSpecies
	pop de
	pop bc
	jr nc, .ordinaryAgility
	ld hl, RockPolishBattleName
	jr .copyName
.ordinaryAgility
	ld a, AGILITY
.normalMove
	ld [wd0b5], a
	ld a, BANK(MoveNames)
	ld [wPredefBank], a
	ld a, MOVE_NAME
	ld [wNameListType], a
	call GetName
	ld hl, wcd6d
.copyName
	ld a, [hli]
	cp "@"
	jr z, .endName
	ld [de], a
	inc de
	jr .copyName
.endName
	ld a, b
	ld [wNumMovesMinusOne], a
	inc b
	ld a, $4e ; line break
	ld [de], a
	inc de
	pop hl
	ld a, b
	cp NUM_MOVES
	jr z, .done
	jp .moveLoop
.dashLoop
	ld a, "-"
	ld [de], a
	inc de
	inc b
	ld a, b
	cp NUM_MOVES
	jr z, .done
	ld a, $4e ; line break
	ld [de], a
	inc de
	jr .dashLoop
.done
	ld a, "@"
	ld [de], a
	ret

; MOVE-5.62.161: the NPC move lists reuse wWhichPokemon as a menu row.
; Temporarily use wMoveMenuType for the selected Party species while one
; Move Deleter/Relearner list is open; each caller saves/restores its value.
SetRockPolishNPCMoveListSpecies::
	call GetRockPolishLearningSpecies
	ld [wMoveMenuType], a
	ret

; Called only by the generic MOVESLISTMENU renderer. Keep its draw pointer
; intact at the call site, return DE=wcd6d as GetMoveName does, and scope the
; alias to the NPC shared list so other list menus remain unchanged.
; Move Deleter/Relearner can display the $ff experiment without indexing the
; legacy MoveNames array. This does not change ordinary global GetMoveName.
CopyPowerWhipExperimentToCD6D::
	ld de, PowerWhipExperimentName
	ld hl, wcd6d
	call CopyString
	ld de, wcd6d
	ret

MaybeRenameRockPolishNPCListMoveName::
	ld a, [wd11e]
	cp AGILITY
	jr nz, .original
	ld a, [wListPointer]
	cp LOW(wRelearnableMoves)
	jr nz, .original
	ld a, [wListPointer + 1]
	cp HIGH(wRelearnableMoves)
	jr nz, .original
	ld a, [wMoveMenuType]
	call IsRockPolishSpecies
	jr nc, .original
	ld de, RockPolishBattleName
	ld hl, wcd6d
	call CopyString ; source DE -> destination HL.
.original
	ld de, wcd6d
	ret
