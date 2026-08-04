_MoveRelearnerGreetingText::
	text "For ¥500, I can"
	line "make a #mon"
	cont "remember a move."
	done

_MoveRelearnerNotEnoughMoneyText::
	text "Hmmm..."

	para "You don't have"
	line "enough money!"
	done

_MoveRelearnerWhichMoveText::
	text "Which move should"
	line "@"
	TX_RAM wcd6d
	text " learn?"
	done

_MoveRelearnerByeText::
	text "Come visit me"
	line "again!"
	done

_MoveRelearnerNoMovesText::
	text "This #mon"
	line "hasn't forgotten"
	cont "any moves."
	done
