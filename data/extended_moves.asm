; MOVE-5.62.171: isolated ten-entry second move table, not a replacement for Moves.
; This file is included after data/moves.asm defines the legacy six-byte move macro.
; Full identity: $0100 + ordinal - 1; never reinterpret legacy $00 as an expanded move.
ExtendedMoves::
	move VINE_WHIP, NO_ADDITIONAL_EFFECT, 120, GRASS, 85, 10
	; MOVE-5.62.169: second distinct identity; learned by the pilot Bellsprout.
	move BITE, NO_ADDITIONAL_EFFECT, 90, FAIRY, 90, 10
	; MOVE-5.62.171: placeholder identities 03-10. They deliberately reuse
	; simple legacy animation IDs and NO_ADDITIONAL_EFFECT; final balance is
	; outside this capacity experiment.
	move POUND,       NO_ADDITIONAL_EFFECT, 40, NORMAL,  100, 35
	move TACKLE,      NO_ADDITIONAL_EFFECT, 40, NORMAL,  100, 35
	move MEGA_PUNCH,  NO_ADDITIONAL_EFFECT, 80, NORMAL,   85, 20
	move CUT,         NO_ADDITIONAL_EFFECT, 50, NORMAL,   95, 30
	move GUST,        NO_ADDITIONAL_EFFECT, 40, FLYING,  100, 35
	move PECK,        NO_ADDITIONAL_EFFECT, 35, FLYING,  100, 35
	move VICEGRIP,    NO_ADDITIONAL_EFFECT, 55, NORMAL,  100, 30
	move STRENGTH,    NO_ADDITIONAL_EFFECT, 80, NORMAL,  100, 15
ExtendedMovesEnd::
ASSERT ExtendedMovesEnd - ExtendedMoves == NUM_EXTENDED_MOVES * (MoveEnd - Moves)

; Keep the optional extended names separate from the original MoveNames table.
ExtendedMoveNamePointers::
	; Ten entries are asserted below so adding another placeholder cannot silently
	; leave the name table shorter than the six-byte data table.
	dw ExtendedMoveNames.powerWhip, ExtendedMoveNames.playRough, ExtendedMoveNames.placeholder03, ExtendedMoveNames.placeholder04, ExtendedMoveNames.placeholder05
	dw ExtendedMoveNames.placeholder06, ExtendedMoveNames.placeholder07, ExtendedMoveNames.placeholder08, ExtendedMoveNames.placeholder09, ExtendedMoveNames.placeholder10
ExtendedMoveNamePointersEnd::
ASSERT (ExtendedMoveNamePointersEnd - ExtendedMoveNamePointers) / 2 == NUM_EXTENDED_MOVES
; The name strings must have their own global scope: the pointer-table end
; label above closes ExtendedMoveNamePointers' local-label namespace.
ExtendedMoveNames::
.powerWhip
	db "Power Whip@"
.playRough
	db "Play Rough@"
.placeholder03
	db "Ext Move 03@"
.placeholder04
	db "Ext Move 04@"
.placeholder05
	db "Ext Move 05@"
.placeholder06
	db "Ext Move 06@"
.placeholder07
	db "Ext Move 07@"
.placeholder08
	db "Ext Move 08@"
.placeholder09
	db "Ext Move 09@"
.placeholder10
	db "Ext Move 10@"
