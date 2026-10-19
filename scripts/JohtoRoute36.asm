; R36-5.62.218: information signs only; NPC and Sudowoodo scripts deferred.
JohtoRoute36TextPointers:
	dw JohtoRoute36Tips2Text
	dw JohtoRoute36RuinsText
	dw JohtoRoute36SignText
	dw JohtoRoute36Tips1Text

JohtoRoute36Tips2Text:
	text "TRAINER TIPS"
	para "Be prepared for"
	line "the road ahead."
	done
	db "@"
JohtoRoute36RuinsText:
	text "RUINS OF ALPH"
	para "Gate is closed"
	line "for now."
	done
	db "@"
JohtoRoute36SignText:
	text "ROUTE 36"
	para "VIOLET CITY -"
	line "NATIONAL PARK"
	done
	db "@"
JohtoRoute36Tips1Text:
	text "TRAINER TIPS"
	para "Enjoy the journey!"
	done
	db "@"
