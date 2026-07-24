GetTrainerName_:
	ld hl, wLinkEnemyTrainerName
	ld a, [wLinkState]
	cp LINK_STATE_BATTLING
	jr nz, .notLinkBattle

	; Generic trainer battle text prints both wTrainerName and
	; wCurTrainerName. InitOpponent uses OPP_SONY1 for link battles, which
	; leaves the local rival's personal name in wCurTrainerName and produces
	; text such as "Ashley John wants to battle!". Terminate the optional
	; second name so link battles display only the received player name.
	ld a, "@"
	ld [wCurTrainerName], a
	jr .foundName
.notLinkBattle
	ld a, [wTrainerClass]
	ld [wd0b5], a
	ld a, TRAINER_NAME
	ld [wNameListType], a
	ld a, BANK(TrainerNames)
	ld [wPredefBank], a
	call GetName
	ld hl, wcd6d
.foundName
	ld de, wTrainerName
	ld bc, $d
	jp CopyData
