; R31-5.62.147: static scenery notices, no transplanted Gold engine scripts.
JohtoRoute31TextPointers:
	dw JohtoRoute31SignText
	dw JohtoRoute31CaveSignText

JohtoRoute31SignText:
	text "ROUTE 31"
	para "VIOLET CITY -"
	line "CHERRYGROVE CITY"
	done
	db "@"

JohtoRoute31CaveSignText:
	text "DARK CAVE"
	para "Entrance closed"
	line "for now."
	done
	db "@"
