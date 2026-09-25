PewterCityScript:
	call EnableAutoTextBoxDrawing
	ld hl, PewterCityScriptPointers
	ld a, [wPewterCityCurScript]
	jp CallFunctionInTable

PewterCityScriptPointers:
	dw PewterCityScript0
	dw PewterCityGymGuideArrived
	dw PewterCityGymGuideExitWait
	dw PewterCityGymGuideRestore

PewterCityTextPointers:
	dw PewterCityText1
	dw PewterCityText2
	dw PewterCityText3
	dw PewterCityText4
	dw PewterCityText5
	dw PewterCityTree1
	dw PewterCityTree2
	dw PewterCityText6
	dw PewterCityText7
	dw MartSignText
	dw PokeCenterSignText
	dw PewterCityText10
	dw PewterCityText11
	dw PewterCityText12
	dw PewterCityText13
	dw PewterCityText14
   
PewterCityScript0:
	xor a
	ld [wMuseum1fCurScript], a
	ResetEvent EVENT_BOUGHT_MUSEUM_TICKET
	call PewterCityScript_1925e
	ret

PewterCityScript_1925e:
	CheckEvent EVENT_BEAT_BROCK
	ret nz
	ld hl, CoordsData_19277
	call ArePlayerCoordsInArray
	ret nc
	ld a, $f0
	ld [wJoyIgnore], a
	ld a, $5
	ld [hSpriteIndexOrTextID], a
	jp DisplayTextID

CoordsData_19277:
	db $11,$23
	db $11,$24
	db $12,$25
	db $13,$25
	db $ff

; PWT-5.40.03: the Museum NPC is a normal town NPC again; only the Gym
; guide keeps scripted movement, arrival dialogue, exit animation, and restore.
PewterCityGymGuideArrived:
	ld a, [wNPCMovementScriptPointerTableNum]
	and a
	ret nz
	ld a, $5
	ld [H_SPRITEINDEX], a
	ld a, SPRITE_FACING_LEFT
	ld [hSpriteFacingDirection], a
	call SetSpriteFacingDirectionAndDelay
	ld a, ($1 << 4) | SPRITE_FACING_LEFT
	ld [hSpriteImageIndex], a
	call SetSpriteImageIndexAfterSettingFacingDirection
	call PlayDefaultMusic
	ld hl, wFlags_0xcd60
	set 4, [hl]
	ld a, $10
	ld [hSpriteIndexOrTextID], a
	call DisplayTextID
	ld a, $3c
	ld [$ffeb], a
	ld a, $40
	ld [$ffec], a
	ld a, $16
	ld [$ffed], a
	ld a, $10
	ld [$ffee], a
	ld a, $5
	ld [wSpriteIndex], a
	call SetSpritePosition1
	ld de, MovementData_PewterGymGuyExit
	call MoveSprite
	ld a, $2
	ld [wPewterCityCurScript], a
	ret

PewterCityGymGuideExitWait:
	ld a, [wd730]
	bit 0, a
	ret nz
	ld a, HS_GYM_GUY
	ld [wMissableObjectIndex], a
	predef HideObject
	ld a, $3
	ld [wPewterCityCurScript], a
	ret

PewterCityGymGuideRestore:
	ld a, $5
	ld [wSpriteIndex], a
	call SetSpritePosition2
	ld a, HS_GYM_GUY
	ld [wMissableObjectIndex], a
	predef ShowObject
	xor a
	ld [wJoyIgnore], a
	ld [wPewterCityCurScript], a
	ret

MovementData_PewterGymGuyExit:
	db NPC_MOVEMENT_RIGHT
	db NPC_MOVEMENT_RIGHT
	db NPC_MOVEMENT_RIGHT
	db NPC_MOVEMENT_RIGHT
	db NPC_MOVEMENT_RIGHT
	db $FF

PewterCityStartGymGuide:
	xor a
	ld [hJoyHeld], a
	ld [wNPCMovementScriptFunctionNum], a
	ld a, $3 ; NPC movement table 3 = Gym guide
	ld [wNPCMovementScriptPointerTableNum], a
	ld a, [H_LOADEDROMBANK]
	ld [wNPCMovementScriptBank], a
	ld a, $5
	ld [wSpriteIndex], a
	call GetSpritePosition2
	ld a, $1
	ld [wPewterCityCurScript], a
	ret

PewterCityText1:
	TX_FAR _PewterCityText1
	db "@"

PewterCityText2:
	TX_FAR _PewterCityText2
	db "@"

PewterCityText3:
PewterCityText13:
	TX_FAR _PewterCityText3
	db "@"

PewterCityText4:
	TX_ASM
	ld hl, PewterCityText_19427
	call PrintText
	call YesNoChoice
	ld a, [wCurrentMenuItem]
	cp $0
	jr nz, .asm_1941e
	ld hl, PewterCityText_1942c
	call PrintText
	jr .asm_19424
.asm_1941e
	ld hl, PewterCityText_19431
	call PrintText
.asm_19424
	jp TextScriptEnd

PewterCityText_19427:
	TX_FAR _PewterCityText_19427
	db "@"

PewterCityText_1942c:
	TX_FAR _PewterCityText_1942c
	db "@"

PewterCityText_19431:
	TX_FAR _PewterCityText_19431
	db "@"

PewterCityText5:
	TX_ASM
	ld hl, PewterCityText_1945d
	call PrintText
	call PewterCityStartGymGuide
	jp TextScriptEnd

PewterCityText_1945d:
	TX_FAR _PewterCityText_1945d
	db "@"

PewterCityText14:
	TX_FAR _PewterCityText14
	db "@"

PewterCityText6:
	TX_FAR _PewterCityText6
	db "@"

PewterCityText7:
	TX_FAR _PewterCityText7
	db "@"

PewterCityText10:
	TX_FAR _PewterCityText10
	db "@"

PewterCityText11:
	TX_FAR _PewterCityText11
	db "@"

PewterCityText12:
	TX_FAR _PewterCityText12
	db "@"

PewterCityTree1:
	TX_ASM
	ld a, 3 ; tree number
	ld [wWhichTrade],a
	callba BerryTreeScript
	jp TextScriptEnd
	
PewterCityTree2:
	TX_ASM
	ld a, 4 ; tree number
	ld [wWhichTrade],a
	callba BerryTreeScript
	jp TextScriptEnd
