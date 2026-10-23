_CeladonMansion1Text1::
	text "Hello, dearie."
	line "Make yourself at"
	cont "home."
	done

_CeladonMansion1Text5::
	text "Celadon Mansion"
	line "Manager's Suite"
	done

IF DEF(BATTLE_TEST_BUILD)
; Test build warning. Keep every line within the 18-character text width.
_CeladonMansion1TestOnlyText::
	text "RUN-009 TEST ROM!"
	line "Use TEST save!"
	para "B-5.62.204-T09"
	line "Start now?"
	done

; Shown only AFTER the first YES, while the native three-item menu is open.
; Two short lines fit within the Game Boy dialogue frame.
_CeladonMansion1TestSelectText::
	text "Up/Down: Choose"
	line "A:Start B:Back"
	done

ENDC
