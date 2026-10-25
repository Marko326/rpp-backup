SECTION "Game Version", ROM0

; 公共游戏版本号。以后发布新版本时只需要修改这一处。
; 放在 ROM0 中，任何 ROMX bank 都可以直接读取，无需额外切换 ROM bank。
GameVersionText::
IF DEF(BATTLE_TEST_BUILD)
	; Short public test label, shared by the menu footer and Options.
	db "TEST-217@"
ELSE
	; Manual Transform executes one copied move in the same action; successful Transform also clears stale Disable state.
	db "TRF-5.62.210@"
ENDC
