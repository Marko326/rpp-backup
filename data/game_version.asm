SECTION "Game Version", ROM0

; 公共游戏版本号。以后发布新版本时只需要修改这一处。
; 放在 ROM0 中，任何 ROMX bank 都可以直接读取，无需额外切换 ROM bank。
GameVersionText::
IF DEF(BATTLE_TEST_BUILD)
	; Visible test build identity: 14 chars at options-screen X=6.
	db "B-5.62.204-T09@"
ELSE
	; The new official release version; test code is compiled out.
	db "BATTLE-5.62.204@"
ENDC
