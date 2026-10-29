SECTION "Game Version", ROM0

; 公共游戏版本号。以后发布新版本时只需要修改这一处。
; 放在 ROM0 中，任何 ROMX bank 都可以直接读取，无需额外切换 ROM bank。
GameVersionText::
IF DEF(BATTLE_TEST_BUILD)
	; Short public test label, shared by the menu footer and Options.
	db "TEST-231@"
ELSE
	; VIOLET-248: restore the shore tile ID before Surf landing checks.
	; SAV-244: restore tileset pointers after loading older saves.
	db "PAL-5.62.248@"
ENDC
