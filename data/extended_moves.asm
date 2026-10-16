; MOVE-5.62.172: isolated twenty-entry second move table, not a replacement for Moves.
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
	; MOVE-5.62.172: ordinal 11-20 capacity placeholders. Keep the old
	; compatible battle animations / standard damage path, but vary stats
	; and PP so offset errors are visible during testing.
	move SCRATCH,     NO_ADDITIONAL_EFFECT, 40, NORMAL,  100, 30
	move HORN_ATTACK, NO_ADDITIONAL_EFFECT, 65, NORMAL,  100, 25
	move WING_ATTACK, NO_ADDITIONAL_EFFECT, 60, FLYING,  100, 20
	move POUND,       NO_ADDITIONAL_EFFECT, 45, NORMAL,   95, 25
	move VICEGRIP,    NO_ADDITIONAL_EFFECT, 55, NORMAL,  100, 15
	move GUST,        NO_ADDITIONAL_EFFECT, 40, FLYING,  100, 25
	move PECK,        NO_ADDITIONAL_EFFECT, 35, FLYING,  100, 20
	move TACKLE,      NO_ADDITIONAL_EFFECT, 50, NORMAL,  100, 20
	move MEGA_PUNCH,  NO_ADDITIONAL_EFFECT, 80, NORMAL,   85, 15
	move STRENGTH,    NO_ADDITIONAL_EFFECT, 75, NORMAL,  100, 10
ExtendedMovesEnd::
ASSERT ExtendedMovesEnd - ExtendedMoves == NUM_EXTENDED_MOVES * (MoveEnd - Moves)

; Keep the optional extended names separate from the original MoveNames table.
ExtendedMoveNamePointers::
	; Pointer count is asserted below so adding a placeholder cannot silently
	; leave the name table shorter than the six-byte data table.
	dw ExtendedMoveNames.powerWhip, ExtendedMoveNames.playRough, ExtendedMoveNames.placeholder03, ExtendedMoveNames.placeholder04, ExtendedMoveNames.placeholder05
	dw ExtendedMoveNames.placeholder06, ExtendedMoveNames.placeholder07, ExtendedMoveNames.placeholder08, ExtendedMoveNames.placeholder09, ExtendedMoveNames.placeholder10
	dw ExtendedMoveNames.placeholder11, ExtendedMoveNames.placeholder12, ExtendedMoveNames.placeholder13, ExtendedMoveNames.placeholder14, ExtendedMoveNames.placeholder15
	dw ExtendedMoveNames.placeholder16, ExtendedMoveNames.placeholder17, ExtendedMoveNames.placeholder18, ExtendedMoveNames.placeholder19, ExtendedMoveNames.placeholder20
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
; MOVE-5.62.172: additional ordinal-indexed name entries.
.placeholder11
	db "Ext Move 11@"
.placeholder12
	db "Ext Move 12@"
.placeholder13
	db "Ext Move 13@"
.placeholder14
	db "Ext Move 14@"
.placeholder15
	db "Ext Move 15@"
.placeholder16
	db "Ext Move 16@"
.placeholder17
	db "Ext Move 17@"
.placeholder18
	db "Ext Move 18@"
.placeholder19
	db "Ext Move 19@"
.placeholder20
	db "Ext Move 20@"
