SECTION "Game Version", ROM0

; 公共游戏版本号。以后发布新版本时只需要修改这一处。
; 放在 ROM0 中，任何 ROMX bank 都可以直接读取，无需额外切换 ROM bank。
GameVersionText::
IF DEF(BATTLE_TEST_BUILD)
	; Short public test label, shared by the menu footer and Options.
	db "TEST-231@"
ELSE
	; FIX-256: restore Gold coordinate/direction ledges and reject unsafe Ruins landing.
	; FIX-255: preserve SELECT-only input without opening the Start menu.
	; MAP-254: open Gold Ruins of Alph south exterior via Route32 EastWestGate.
	; ROUTES-253: restore New Bark Town's original pond block and enable Surf.
	; ROUTES-252: allow exact Gold FLOOR at the southwest shore and normal walking.
	; CHERRY-249: add exact Gold WATER handling for Cherrygrove Surf.
	; VIOLET-248: restore the shore tile ID before Surf landing checks.
	; SAV-244: restore tileset pointers after loading older saves.
	db "FIX-5.62.256@"
ENDC
