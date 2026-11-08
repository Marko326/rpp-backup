SECTION "Game Version", ROM0

; 公共游戏版本号。以后发布新版本时只需要修改这一处。
; Canonical project version REF-5.62.354; one shared in-ROM label for all build flavors.
; 放在 ROM0 中，任何 ROMX bank 都可以直接读取，无需额外切换 ROM bank。
GameVersionText::
	; REF-317: add exact north ID66 carpet re-entry/lane-switch profiles; keep coarse role grid fail-closed and DOWN-only Warp.
	; REF-310: Gold-accurate green/brown map palette selection for two Park gates.
	; REF-309: fold repeated 10x8 gate role-grid dimensions in ROMX Bank $4E.
	; REF-306: correct UP-facing counter probe from upper-left $00 to lower-left $0E.
	; REF-305: Gold red Officer alias (color works); previous counter tile was wrong.
	; DEV-313: activate Gold Route43MahoganyGate (ID65) as a safe Mahogany round trip; north remains closed.
	; DEV-314: shared data-driven vertical gate threshold/arrival/bounds profiles; ID65 behavior unchanged.
	; REF-315: activate Gold Route43 (ID67) via north ID65 gate; Lake physical connection remains closed, ROMX only.
	; DEV-316: keep ID65 south Route43 WARP_CARPET_DOWN on the collision path; do not bypass the y=52 forest-edge collision.
	; DEV-317: restore Gold Route43 north/south visual previews; physical edges remain fail-closed.
	; DEV-319: ID66 Route43Gate transit skeleton and complete Gold Warp pairs, scene deferred.
	; REF-318 / DEV-321: activate exact Gold Lake of Rage outdoor + audited Route43 seam; story/houses deferred.
	; REF-319: route Lake of Rage land movement through the exact Gold role grid; audit chained ledges separately.
	; DEV-325: restore Gold Route44 east cliff preview without activating Blackthorn.
	; REF-338: Blackthorn Center door #5 and two own return carpets.
	; REF-337: Ecruteak/Mahogany center doors target the first 1F carpet warp (0).
	; REF-348: Burned Tower B1F, source-only PIT warp and reused RPP Strength/SCY animations.
	; REF-344: open Slowpoke Well B2F via shared cave adapter and enable Gold B1F boulder via existing Strength engine.
	; REF-342: Union Cave LADDER warps trigger only on step-in; standing collision cannot re-warp.
	; REF-341: Union Cave same-tileset floor warps rebuild destination coordinates; cave NPC/events remain closed.
	; REF-304: restore map-local Officer sprites and independent West/East Gate dialogue.
	; REF-303: shared East/West Gate carpet-entry decision (that candidate's separate TEST label is now retired).
	; FIX-302: allow inward steps onto East/West gate carpets from floor, with ASM move simulation.
	; MAP-300: activate Ecruteak east gate, Route42 and Mahogany outdoor corridor; keep Route43/44/Mt Mortar closed.
	; MAP-299: activate Route40/Route41/Cianwood outdoor sea chain with Gold/mature collision and Surf seams.
	; FIX-298: keep ordinary Johto Town Map labels in-bank; prevent garble/WRAM overwrite on exit.
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
	; REF-350: keep ordinary door transitions on the black-fade, LCD-on CGB path and upload staged BG tile/attribute rows with HBlank DMA.
	; REF-351A: copy up to two consecutive VRAM bytes per LCD-safe CopyData window.
	; REF-351B: use uniform RGB555 scaling for ordinary CGB doorway fade stages.
	; REF-352: reuse LCD-safe two-byte copies for ordinary door graphics loads.
	; REF-353: unify cave/ordinary door black fades and safe LCD-on loading.
	; REF-354: preserve Spark damage-power registers and extended animation identity.
	; REF-355: show shared short item descriptions in Player PC item lists.
	; REF-356: quantity picker local held-key repeat, 40/5 frames.
	db "REF-356@"
