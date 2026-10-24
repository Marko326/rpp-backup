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
CeladonMansion1TestNpcText: ; extra NPC in test ROM only
	TX_ASM
	; A/No/B have already been consumed by the nested native menus.
	; Finish through DisplayTextID's own window-hide/map-restore path;
	; do not leave the original warning displayed until another A press.
	ld hl, CeladonMansion1TestOnlyText
	call PrintText
	call YesNoChoice
	ld a, [wCurrentMenuItem]
	and a
	jr nz, .finish ; first NO/B: never edit the party
	; Replace the warning with relevant controls BEFORE the three-way menu.
	; The chooser saves this new textbox in Buffer1 and restores it on A/B;
	; DisplayTextID then closes it on this very same interaction.
	ld hl, CeladonMansion1TestSelectText
	call PrintText
	callab TestSuite_StartFromNpc ; group B cancels before any party edit
.finish
	call DisableWaitingAfterTextDisplay
	jp TextScriptEnd

CeladonMansion1TestOnlyText:
	TX_FAR _CeladonMansion1TestOnlyText
	db "@"

CeladonMansion1TestSelectText:
	TX_FAR _CeladonMansion1TestSelectText
	db "@"

ENDC
CeladonMansionTutors: ; Common to all three tutors
	ld [wWhichTrade], a
	callba MoveTutorScript
	jp TextScriptEnd
