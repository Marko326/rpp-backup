PewterMartScript:
	call EnableAutoTextBoxDrawing
	ld a, $1
	ld [wAutoTextBoxDrawingControl], a
	ret

PewterMartTextPointers:
	dw PewterCashierText
	dw PewterMartText2
	dw PewterMartText3

PewterMartText2:
	TX_ASM
	ld hl, .Text
	jp PrintTextAndTextScriptEnd
.Text
	TX_FAR _PewterMartText2
	db "@"

PewterMartText3:
	TX_ASM
	ld hl, .Text
	jp PrintTextAndTextScriptEnd
.Text
	TX_FAR _PewterMartText3
	db "@"
