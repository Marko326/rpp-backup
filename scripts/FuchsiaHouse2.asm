FuchsiaHouse2TextPointers:
	dw FuchsiaHouse2Text1
	dw PickUpItemText
	dw BoulderText
	dw FuchsiaHouse2Text4
	dw FuchsiaHouse2Text5

FuchsiaHouse2Text1:
	TX_ASM
	CheckEvent EVENT_GOT_HM04
	jr nz, .explainHM04
	ld b, GOLD_TEETH
	call IsItemInBag
	jr z, .gibberish

; HM4-5.38.00: make the Gold Teeth -> HM04 reward atomic. Gold Teeth is
; a unique quantity-1 overworld item, so removing it always frees one
; wBagItems slot before HM04 is added. The old EVENT_GAVE_GOLD_TEETH /
; bag-full intermediate state is therefore unnecessary.
	ld hl, WardenTeethText1
	call PrintText
	ld a, GOLD_TEETH
	ld [$ffdb], a
	callba RemoveItemByID
	ld hl, WardenThankYouText
	call PrintText
	lb bc, HM_04, 1
	call GiveItem
	ld hl, ReceivedHM04Text
	call PrintText
	SetEvent EVENT_GOT_HM04
	jr .done

.gibberish
	ld hl, WardenGibberishText1
	call PrintText
	call YesNoChoice
	ld a, [wCurrentMenuItem]
	and a
	ld hl, WardenGibberishText3
	jr nz, .printGibberishReply
	ld hl, WardenGibberishText2
.printGibberishReply
	call PrintText
	jr .done

.explainHM04
	ld hl, HM04ExplanationText
	call PrintText
.done
	jp TextScriptEnd

WardenGibberishText1:
	TX_FAR _WardenGibberishText1
	db "@"

WardenGibberishText2:
	TX_FAR _WardenGibberishText2
	db "@"

WardenGibberishText3:
	TX_FAR _WardenGibberishText3
	db "@"

WardenTeethText1:
	TX_FAR _WardenTeethText1
	TX_SFX_ITEM_1

WardenTeethText2:
	TX_FAR _WardenTeethText2
	db "@"

WardenThankYouText:
	TX_FAR _WardenThankYouText
	db "@"

ReceivedHM04Text:
	TX_FAR _ReceivedHM04Text
	TX_SFX_ITEM_1
	db "@"

HM04ExplanationText:
	TX_FAR _HM04ExplanationText
	db "@"

FuchsiaHouse2Text5:
FuchsiaHouse2Text4:
	TX_ASM
	ld a, [H_SPRITEINDEX]
	cp $4
	ld hl, FuchsiaHouse2Text_7517b
	jr nz, .asm_4c9a2
	ld hl, FuchsiaHouse2Text_75176
.asm_4c9a2
	call PrintText
	jp TextScriptEnd

FuchsiaHouse2Text_75176:
	TX_FAR _FuchsiaHouse2Text_75176
	db "@"

FuchsiaHouse2Text_7517b:
	TX_FAR _FuchsiaHouse2Text_7517b
	db "@"
