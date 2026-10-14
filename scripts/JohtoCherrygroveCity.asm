; P2-1: independent RPP signs; no Gold engine/script dependencies.
JohtoCherrygroveCityTextPointers:
	dw JohtoCherrygroveCitySignText
	dw JohtoCherrygroveHouseSignText
	dw JohtoCherrygroveMartSignText
	dw JohtoCherrygroveCenterSignText

JohtoCherrygroveCitySignText:
	text "CHERRYGROVE CITY"
	para "The City of"
	line "Fragrant Flowers"
	done
	db "@"

JohtoCherrygroveHouseSignText:
	text "GUIDE GENT'S HOUSE"
	para "Closed for now."
	done
	db "@"

JohtoCherrygroveMartSignText:
	text "#MON MART"
	para "Closed for now."
	done
	db "@"

JohtoCherrygroveCenterSignText:
	text "#MON CENTER"
	para "Closed for now."
	done
	db "@"
