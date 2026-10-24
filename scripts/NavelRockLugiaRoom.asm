NavelRockLugiaRoomScript:
	; TMD-5.47.00: use the bank-local shared trainer dispatcher/table.
	ld hl, NavelRockLugiaRoomTrainerHeaders
	ld bc, wNavelRockLugiaRoomCurScript
	jp Bank34RunStandardTrainerMapScript

NavelRockLugiaRoomTextPointers:
	dw NavelRockLugiaRoomText1 ; Lugia
	dw NavelRockLugiaRoomText2 ; Ho-oh

NavelRockLugiaRoomTrainerHeaders:
NavelRockLugiaRoomTrainerHeader0:
	dbEventFlagBit EVENT_BEAT_LUGIA
	db ($0 << 4) ; trainer's view range
	dwEventFlagAddress EVENT_BEAT_LUGIA
	dw NavelRockLugiaRoomLugiaText ; TextBeforeBattle
	dw NavelRockLugiaRoomLugiaText ; TextAfterBattle
	dw NavelRockLugiaRoomLugiaText ; TextEndBattle

NavelRockLugiaRoomTrainerHeader1:
	dbEventFlagBit EVENT_BEAT_HO_OH
	db ($0 << 4) ; trainer's view range
	dwEventFlagAddress EVENT_BEAT_HO_OH
	dw NavelRockLugiaRoomHoohText ; TextBeforeBattle
	dw NavelRockLugiaRoomHoohText ; TextAfterBattle
	dw NavelRockLugiaRoomHoohText ; TextEndBattle

	db $ff

NavelRockLugiaRoomText1:
	TX_TRAINER NavelRockLugiaRoomTrainerHeader0

NavelRockLugiaRoomText2:
	TX_TRAINER NavelRockLugiaRoomTrainerHeader1

NavelRockLugiaRoomLugiaText:
	TX_FAR _NavelRockLugiaRoomLugiaText
	TX_ASM
	ld a, LUGIA
	call PlayCry
	call WaitForSoundToFinish
	jp TextScriptEnd

NavelRockLugiaRoomHoohText:
	TX_FAR _NavelRockLugiaRoomHoohText
	TX_ASM
	ld a, HO_OH
	call PlayCry
	call WaitForSoundToFinish
	jp TextScriptEnd
