; Visible city signs follow the seven Gold BG_EVENT locations exactly.
; These messages do not activate unopened interiors or storyline events.
JohtoEcruteakCityTextPointers:
	dw JohtoEcruteakCitySignText
	dw JohtoEcruteakTinTowerSignText
	dw JohtoEcruteakGymSignText
	dw JohtoEcruteakDanceSignText
	dw JohtoEcruteakBurnedTowerSignText
	dw JohtoEcruteakPokecenterSignText
	dw JohtoEcruteakMartSignText

JohtoEcruteakCitySignText:
	text "ECRUTEAK CITY"
	line "A HISTORICAL CITY"
	done
	db "@"
JohtoEcruteakTinTowerSignText:
	text "TIN TOWER"
	line "LEGENDARY #MON"
	done
	db "@"
JohtoEcruteakGymSignText:
	text "ECRUTEAK GYM"
	line "LEADER: MORTY"
	done
	db "@"
JohtoEcruteakDanceSignText:
	text "DANCE THEATER"
	done
	db "@"
JohtoEcruteakBurnedTowerSignText:
	text "BURNED TOWER"
	line "DAMAGED BY FIRE"
	done
	db "@"
JohtoEcruteakPokecenterSignText:
	text "#MON CENTER"
	done
	db "@"
JohtoEcruteakMartSignText:
	text "#MON MART"
	done
	db "@"
