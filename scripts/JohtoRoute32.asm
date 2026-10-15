; R32-5.62.165: terrain and signs only, no Gold engine event scripts.
JohtoRoute32TextPointers:
	dw JohtoRoute32SignText
	dw JohtoRoute32RuinsText
	dw JohtoRoute32CaveText
	dw JohtoRoute32CenterText

JohtoRoute32SignText:
	text "ROUTE 32"
	para "VIOLET CITY -"
	line "AZALEA TOWN"
	done
	db "@"

JohtoRoute32RuinsText:
	text "RUINS OF ALPH"
	para "Entrance closed"
	line "for now."
	done
	db "@"

JohtoRoute32CaveText:
	text "UNION CAVE"
	para "Entrance closed"
	line "for now."
	done
	db "@"

JohtoRoute32CenterText:
	text "#MON CENTER"
	para "Closed for now."
	done
	db "@"
