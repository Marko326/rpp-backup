; JHT-5.62.110: deliberately independent of Gold's story flags and warps.
NewBarkTownTextPointers:
	dw NewBarkTownSailorText
	dw NewBarkTownTeacherText
	dw NewBarkTownFisherText
	dw NewBarkTownVisitorText
	dw NewBarkTownSignText
	dw NewBarkTownHomeSignText
	dw NewBarkTownLabSignText
	dw NewBarkTownElmsHouseSignText

NewBarkTownSailorText:
	text "The ferry connects"
	line "this town with"
	cont "Vermilion Port."
	para "Step onto the"
	line "shore to board!"
	done
	db "@"

NewBarkTownTeacherText:
	text "Welcome to"
	line "New Bark Town!"
	done
	db "@"

NewBarkTownFisherText:
	text "The routes out of"
	line "town are closed"
	cont "for now."
	done
	db "@"

NewBarkTownVisitorText:
	text "This is PROF."
	line "ELM's famous lab."
	done
	db "@"

NewBarkTownSignText:
	text "NEW BARK TOWN"
	para "The Town Where"
	line "Winds of a New"
	cont "Beginning Blow"
	done
	db "@"

NewBarkTownHomeSignText:
	text "<PLAYER>'s House"
	para "Closed for now."
	done
	db "@"

NewBarkTownLabSignText:
	text "ELM #MON LAB"
	para "Closed for now."
	done
	db "@"

NewBarkTownElmsHouseSignText:
	text "ELM'S HOUSE"
	para "Closed for now."
	done
	db "@"
