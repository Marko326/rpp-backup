CeladonMansion1TextPointers:
	dw CeladonMansion1Text1
	dw CeladonMansion1Text2
	dw CeladonMansion1Text3
	dw CeladonMansion1Text4
	dw CeladonMansion1Text5
IF DEF(BATTLE_TEST_BUILD)
	dw CeladonMansion1TestNpcText
ENDC

CeladonMansion1Text1: ; original old lady (always preserved)
	TX_FAR _CeladonMansion1Text1
	db "@"

CeladonMansion1Text2: ; Tutor 1
	TX_ASM
	ld a, 9 ; Thunder Punch
	jp CeladonMansionTutors

CeladonMansion1Text3: ; Tutor 2
	TX_ASM
	ld a, 10 ; Fire Punch
	jp CeladonMansionTutors

CeladonMansion1Text4: ; Tutor 3
	TX_ASM
	ld a, 11 ; Ice Punch
	jp CeladonMansionTutors

CeladonMansion1Text5: ; Sign on wall
	TX_FAR _CeladonMansion1Text5
	db "@"

IF DEF(BATTLE_TEST_BUILD)
CeladonMansion1TestNpcText: ; extra Pokey, TEST ROM only
    TX_ASM
    ; No Yes/No or TX_RAM: show the selection menu immediately.
    ; Its fixed bottom footer reads GameVersionText directly from ROM0.
    callab TestSuite_StartFromNpc
    call DisableWaitingAfterTextDisplay
    jp TextScriptEnd

ENDC
CeladonMansionTutors: ; Common to all three tutors
	ld [wWhichTrade], a
	callba MoveTutorScript
	jp TextScriptEnd
