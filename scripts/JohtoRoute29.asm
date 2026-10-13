; MAP-5.62.126: original scenery/NPC positions, neutral dialogue only.
; Gen 2 trainer, catching tutorial, item ball and fruit-tree events
; are intentionally not transplanted into the Gen 1 script engine.
JohtoRoute29TextPointers:
	dw JohtoRoute29GuideText
	dw JohtoRoute29YoungsterText
	dw JohtoRoute29TeacherText
	dw JohtoRoute29FisherText
	dw JohtoRoute29EastSignText
	dw JohtoRoute29WestSignText
	dw JohtoRoute29GateSignText

JohtoRoute29GuideText:
	text "This is Route 29."
	para "The tall grass"
	line "is thick here!"
	done
	db "@"

JohtoRoute29YoungsterText:
	text "This road goes to"
	line "CHERRYGROVE CITY."
	para "The city exit is"
	line "closed for now."
	done
	db "@"

JohtoRoute29TeacherText:
	text "Watch your step"
	line "near the ledges!"
	done
	db "@"

JohtoRoute29FisherText:
	text "The gate ahead"
	line "is still closed."
	done
	db "@"

JohtoRoute29EastSignText:
	text "ROUTE 29"
	para "NEW BARK TOWN -"
	line "CHERRYGROVE CITY"
	done
	db "@"

JohtoRoute29WestSignText:
	text "ROUTE 29"
	para "CHERRYGROVE CITY -"
	line "NEW BARK TOWN"
	done
	db "@"

JohtoRoute29GateSignText:
	text "ROUTE 46 GATE"
	para "Closed for now."
	done
	db "@"
