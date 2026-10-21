; Original officer dialogue is retained for future NPC event activation.
; No fake trainer or story progression event is introduced here.
JohtoRoute38EcruteakGateTextPointers:
	dw JohtoRoute38EcruteakGateOfficerText
JohtoRoute38EcruteakGateOfficerText:
	text "NEW BARK TOWN?"
	line "PROF. ELM lives"
	cont "there, right?"
	para "You've come a long"
	line "way to get here."
	done
	db "@"
