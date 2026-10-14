; MAP-5.62.139 P2-2: outdoor-only text; no pokegold script interpreter.
JohtoRoute30TextPointers:
	dw JohtoRoute30SignText
	dw JohtoRoute30DirectionsText
	dw JohtoRoute30HouseText
	dw JohtoRoute30TipsText

JohtoRoute30SignText:
	text "ROUTE 30"
	para "CHERRYGROVE CITY -"
	line "VIOLET CITY"
	done
	db "@"

JohtoRoute30DirectionsText:
	text "MR.#MON'S HOUSE"
	para "North through the"
	line "tall grass."
	done
	db "@"

JohtoRoute30HouseText:
	text "MR.#MON'S HOUSE"
	para "Closed for now."
	done
	db "@"

JohtoRoute30TipsText:
	text "TRAINER TIPS"
	para "Watch for ledges"
	line "on this route!"
	done
	db "@"
