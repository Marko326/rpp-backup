_MoveTutorSpecialIntroText::
	text "For ¥500,"
	line "I can teach"
	cont "your #mon"
	cont "a mighty move."
	prompt

_MoveTutorChooseMoveText::
	text "Please choose a"
	line "move!"
	done

_TeachTutorMoveText::
	text "For ¥500, I can"
	line "teach @"
	TX_RAM wcf4b
	db $0
	cont "to a #mon."
	done

_MoveTutorComeAgainText::
	text "Come again!"
	done

_MonCannotLearnTutorMoveText::
	text "Oh, I can't teach"
	line "that #mon"
	cont "@"
	TX_RAM wcf4b
	text "."
	prompt

_MonNotStrongEnoughTutorText::
	text "@"
	TX_RAM wcd6d
	text " isn't"
	line "strong enough to"
	cont "master this move."
	prompt

_MoveTutorNotEnoughMoneyText::
	text "I'm sorry, you"
	line "don't have enough"
	cont "money."
	done
