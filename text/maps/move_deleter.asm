_MoveDeleterGreetingText::
	text "Shall I make a"
	line "#mon forget?"
	done

_MoveDeleterWhichMoveText::
	text "Which move should"
	line "@"
	TX_RAM wcd6d
	text " forget?"
	done

_MoveDeleterConfirmText::
	text "Should @"
	TX_RAM wcd6d
	text ""
	line "forget this move?"
	done

_MoveDeleterForgotText::
	text "@"
	TX_RAM wcf4b
	text " was"
	line "forgotten!"
	prompt

_MoveDeleterByeText::
	text "Come visit me"
	line "again!"
	done

_MoveDeleterOneMoveText::
	text "That #mon"
	line "knows only one"
	cont "move."
	done
