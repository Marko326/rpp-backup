SECTION "Game Version", ROM0

; 公共游戏版本号。以后发布新版本时只需要修改这一处。
; 放在 ROM0 中，任何 ROMX bank 都可以直接读取，无需额外切换 ROM bank。
GameVersionText::
IF DEF(BATTLE_TEST_BUILD)
	; Short public test label, shared by the menu footer and Options.
	db "TEST-231@"
ELSE
	; FIX-295: restore Ecruteak pond water movement and Gold shore disembark; require live-path audit.
	; FIX-288: protect Park borders, mature east-gate passability and long grass.
	; FIX-287: keep Park/Gate map scripts in the same ROMX bank as their active headers.
	; FIX-284: Route35 south Gold-compatible preview and closed park lane, preserve warp landing.
	; FIX-281: reopen only registered Route34 north-gate carpet lanes and audit live warp collisions.
	; FIX-280: synchronize real in-ROM version with cumulative Route34/Goldenrod fixes.
	; FIX-279: restore Gold Route34 tree border, four seam lanes and north preview.
	; FIX-276: adapt mature Forest/Azalea width constants to active Johto symbols.
	; FIX-269: repair Route33 west seam, accepted ILEX-217 HOP/Cut, Gold roof PNG/RGB5.
	; MAP-268: six Gold southern maps, Ilex gates, Surf/Cut/hops and Gold seam guards.
	; FIX-272: move southern land decision to ROMX; cap ROM0 gateway at 25B.
	; FIX-271: preserve NPC-243 south borders, ILEX-217 jump speed, and guarded doors.
	; FIX-270: avoid two added ROM0 roof farcalls; reuse existing ROMX hooks.
	; FIX-267: correct 16-bit tileset and palette pointer indexing for ID 32.
	; R33-266: Union Cave south warp and Route33 modern outdoor map.
	; FIX-265: preserve north-facing cave arrival; leave DOWN collision exit unchanged.
	; FIX-264: connect cave preflight in ExtraWarpCheck to Gold DOWN collision exit.
	; FIX-262: move per-map Surf decision out of nearly-full ROM0; retain unbanked cave collision.
	; FIX-261: complete Union Cave slot 13 GSC music table; audit RGBDS ASSERT lengths.
	; MUS-259: inherit active Gold gate music without restart; audit music and cycling.
	; FIX-258: register new neutral gate name-sign and enforce full active-map name audit.
	; FIX-256: restore Gold coordinate/direction ledges and reject unsafe Ruins landing.
	; FIX-255: preserve SELECT-only input without opening the Start menu.
	; MAP-254: open Gold Ruins of Alph south exterior via Route32 EastWestGate.
	; ROUTES-253: restore New Bark Town's original pond block and enable Surf.
	; ROUTES-252: allow exact Gold FLOOR at the southwest shore and normal walking.
	; CHERRY-249: add exact Gold WATER handling for Cherrygrove Surf.
	; VIOLET-248: restore the shore tile ID before Surf landing checks.
	; SAV-244: restore tileset pointers after loading older saves.
	db "FIX-5.62.295@"
ENDC
