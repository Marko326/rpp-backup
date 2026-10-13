; Exact trade helper routines moved out of the tight cable / NPC exchange banks.
; The actual received Owned mark remains a separate success-only call.

; FORM-5.62.13: preserve the selected stored instances' form-marker bytes before
; RemovePokemon shifts the local party and the received structure is appended.
TradeCenter_CaptureRegionalFormMarkers:
	ld a, [wTradingWhichPlayerMon]
	ld hl, wPartyMon1CatchRate
	ld bc, wPartyMon2 - wPartyMon1
	call AddNTimes
	ld a, [hl]
	ld [wTradedPlayerMonFormMarker], a
	ld a, [wTradingWhichEnemyMon]
	ld hl, wEnemyMon1CatchRate
	ld bc, wEnemyMon2 - wEnemyMon1
	call AddNTimes
	ld a, [hl]
	ld [wTradedEnemyMonFormMarker], a
	ret


InGameTrade_CopyDataToReceivedMon:
	ld hl, wPartyMonNicks
	ld bc, NAME_LENGTH
	call InGameTrade_GetReceivedMonPointer
	ld hl, wInGameTradeMonNick
	ld bc, NAME_LENGTH
	call CopyData
	ld hl, wPartyMonOT
	ld bc, NAME_LENGTH
	call InGameTrade_GetReceivedMonPointer
	ld hl, wCurTrainerName;InGameTrade_TrainerString
	ld bc, NAME_LENGTH
	call CopyData
	ld hl, wPartyMon1OTID
	ld bc, wPartyMon2 - wPartyMon1
	call InGameTrade_GetReceivedMonPointer
	ld hl, wTradedEnemyMonOTID
	ld bc, $2
	jp CopyData

; the received mon's index is (partyCount - 1),
; so this adds bc to hl (partyCount - 1) times and moves the result to de
InGameTrade_GetReceivedMonPointer:
	ld a, [wPartyCount]
	dec a
	call AddNTimes
	ld e, l
	ld d, h
	ret
