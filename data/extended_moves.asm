; MOVE-5.62.169: isolated second move table, not a replacement for Moves.
; This file is included after data/moves.asm defines the legacy six-byte move macro.
; Full identity: $0100 (Power Whip); never reinterpret legacy $00 as this move.
ExtendedMoves::
	move VINE_WHIP, NO_ADDITIONAL_EFFECT, 120, GRASS, 85, 10
	; MOVE-5.62.169: second distinct identity; learned by the pilot Bellsprout.
	move BITE, NO_ADDITIONAL_EFFECT, 90, FAIRY, 90, 10
ExtendedMovesEnd::
ASSERT ExtendedMovesEnd - ExtendedMoves == NUM_EXTENDED_MOVES * (MoveEnd - Moves)

; Keep the optional extended names separate from the original MoveNames table.
ExtendedMoveNamePointers::
	dw .powerWhip, .playRough
.powerWhip
	db "Power Whip@"
.playRough
	db "Play Rough@"
