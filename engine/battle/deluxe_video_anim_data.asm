; Deluxe 55 recording-only animation byte streams and display names.
; Indexed 00..54 by the player/foe gallery, but contains no battle hooks.
; Do not remap them to old move IDs (GEAR GRIND collides with TWINEEDLE).
; This file is intentionally the first, independent "animation data" commit.
; The runner INCLUDEs it inside the SAME ROMX SECTION as its pointer users.

VideoRecipePointers:
	dw VideoRecipe00 ; 18 SAND TOMB / SandTombAnim
	dw VideoRecipe01 ; 99 SUPERPOWER / SuperpowerAnim
	dw VideoRecipe02 ; 116 HEAT WAVE / HeatWaveAnim
	dw VideoRecipe03 ; 117 DOOM DESIRE / DoomDesireAnim
	dw VideoRecipe04 ; 134 COSMIC POWER / CosmicPowerAnim
	dw VideoRecipe05 ; 204 DRAIN PUNCH / DrainPunchAnim
	dw VideoRecipe06 ; 205 VACUUM WAVE / VacuumWaveAnim
	dw VideoRecipe07 ; 206 DRAGON PULSE / DragonPulseAnim
	dw VideoRecipe08 ; 207 SUCKER PUNCH / SuckerPunchAnim
	dw VideoRecipe09 ; 208 MOONLIGHT / MoonlightAnim
	dw VideoRecipe10 ; 209 VOLT TACKLE / VoltTackleAnim
	dw VideoRecipe11 ; 210 ICE SHARD / IceShardAnim
	dw VideoRecipe12 ; 211 CRUNCH / CrunchAnim
	dw VideoRecipe13 ; 212 DARK PULSE / DarkPulseAnim
	dw VideoRecipe14 ; 213 NIGHT SLASH / NightSlashAnim
	dw VideoRecipe15 ; 214 FAKE TEARS / FakeTearsAnim
	dw VideoRecipe16 ; 215 BULLET PUNCH / BulletPunchAnim
	dw VideoRecipe17 ; 216 FLASH CANNON / FlashCannonAnim
	dw VideoRecipe18 ; 217 IRON HEAD / IronHeadAnim
	dw VideoRecipe19 ; 218 STEEL WING / SteelWingAnim
	dw VideoRecipe20 ; 219 LEAF BLADE / LeafBladeAnim
	dw VideoRecipe21 ; 220 DAZZLING GLEAM / DazzlingleamAnim
	dw VideoRecipe22 ; 221 DRAINING KISS / DrainingkissAnim
	dw VideoRecipe23 ; 222 PLAY ROUGH / PlayRoughAnim
	dw VideoRecipe24 ; 223 MOONBLAST / MoonblastAnim
	dw VideoRecipe25 ; 224 GUNK SHOT / GunkShotAnim
	dw VideoRecipe26 ; 225 WOOD HAMMER / WoodHammerAnim
	dw VideoRecipe27 ; 226 POISON JAB / PoisonJabAnim
	dw VideoRecipe28 ; 227 SLUDGE WAVE / SludgeWaveAnim
	dw VideoRecipe29 ; 228 BUG BUZZ / BugBuzzAnim
	dw VideoRecipe30 ; 229 MEGAHORN / MegahornAnim
	dw VideoRecipe31 ; 230 PSYCHO CUT / PsychoCutAnim
	dw VideoRecipe32 ; 231 X SCISSOR / XScissorAnim
	dw VideoRecipe33 ; 232 SHADOW PUNCH / ShadowPunchAnim
	dw VideoRecipe34 ; 233 EXTREMESPEED / ExtremespeedAnim
	dw VideoRecipe35 ; 234 ROCK POLISH / RockPolishAnim
	dw VideoRecipe36 ; 235 OMINOUS WIND / OminousWindAnim
	dw VideoRecipe37 ; 236 CROSS CHOP / CrossChopAnim
	dw VideoRecipe38 ; 237 HURRICANE / HurricaneAnim
	dw VideoRecipe39 ; 238 ANCIENT POWER / AncientpowerAnim
	dw VideoRecipe40 ; 239 GEAR GRIND / GearGrindAnim
	dw VideoRecipe41 ; 240 SHIFT GEAR / ShiftGearAnim
	dw VideoRecipe42 ; 241 AQUA JET / AquaJetAnim
	dw VideoRecipe43 ; 242 BOOMBURST / BoomburstAnim
	dw VideoRecipe44 ; 243 AIR SLASH / AirSlashAnim
	dw VideoRecipe45 ; 244 ROOST / RoostAnim
	dw VideoRecipe46 ; 245 MUD SHOT / MudShotAnim
	dw VideoRecipe47 ; 246 ROCK WRECKER / RockWreckerAnim
	dw VideoRecipe48 ; 247 ZAP CANNON / ZapCannonAnim
	dw VideoRecipe49 ; 248 WILL O WISP / WillOWispAnim
	dw VideoRecipe50 ; 249 DRAGON RUSH / DragonRushAnim
	dw VideoRecipe51 ; 250 METAL SOUND / MetalSoundAnim
	dw VideoRecipe52 ; 252 POWER WHIP / PowerWhipAnim
	dw VideoRecipe53 ; 253 STONE EDGE / StoneEdgeAnim
	dw VideoRecipe54 ; 254 DRILL RUN / DrillRunAnim

VideoNamePointers:
	dw VideoName00
	dw VideoName01
	dw VideoName02
	dw VideoName03
	dw VideoName04
	dw VideoName05
	dw VideoName06
	dw VideoName07
	dw VideoName08
	dw VideoName09
	dw VideoName10
	dw VideoName11
	dw VideoName12
	dw VideoName13
	dw VideoName14
	dw VideoName15
	dw VideoName16
	dw VideoName17
	dw VideoName18
	dw VideoName19
	dw VideoName20
	dw VideoName21
	dw VideoName22
	dw VideoName23
	dw VideoName24
	dw VideoName25
	dw VideoName26
	dw VideoName27
	dw VideoName28
	dw VideoName29
	dw VideoName30
	dw VideoName31
	dw VideoName32
	dw VideoName33
	dw VideoName34
	dw VideoName35
	dw VideoName36
	dw VideoName37
	dw VideoName38
	dw VideoName39
	dw VideoName40
	dw VideoName41
	dw VideoName42
	dw VideoName43
	dw VideoName44
	dw VideoName45
	dw VideoName46
	dw VideoName47
	dw VideoName48
	dw VideoName49
	dw VideoName50
	dw VideoName51
	dw VideoName52
	dw VideoName53
	dw VideoName54

VideoName00: db "SAND TOMB@"
VideoName01: db "SUPERPOWER@"
VideoName02: db "HEAT WAVE@"
VideoName03: db "DOOM DESIRE@"
VideoName04: db "COSMIC POWER@"
VideoName05: db "DRAIN PUNCH@"
VideoName06: db "VACUUM WAVE@"
VideoName07: db "DRAGON PULSE@"
VideoName08: db "SUCKER PUNCH@"
VideoName09: db "MOONLIGHT@"
VideoName10: db "VOLT TACKLE@"
VideoName11: db "ICE SHARD@"
VideoName12: db "CRUNCH@"
VideoName13: db "DARK PULSE@"
VideoName14: db "NIGHT SLASH@"
VideoName15: db "FAKE TEARS@"
VideoName16: db "BULLET PUNCH@"
VideoName17: db "FLASH CANNON@"
VideoName18: db "IRON HEAD@"
VideoName19: db "STEEL WING@"
VideoName20: db "LEAF BLADE@"
VideoName21: db "DAZZLING GLEAM@"
VideoName22: db "DRAINING KISS@"
VideoName23: db "PLAY ROUGH@"
VideoName24: db "MOONBLAST@"
VideoName25: db "GUNK SHOT@"
VideoName26: db "WOOD HAMMER@"
VideoName27: db "POISON JAB@"
VideoName28: db "SLUDGE WAVE@"
VideoName29: db "BUG BUZZ@"
VideoName30: db "MEGAHORN@"
VideoName31: db "PSYCHO CUT@"
VideoName32: db "X SCISSOR@"
VideoName33: db "SHADOW PUNCH@"
VideoName34: db "EXTREMESPEED@"
VideoName35: db "ROCK POLISH@"
VideoName36: db "OMINOUS WIND@"
VideoName37: db "CROSS CHOP@"
VideoName38: db "HURRICANE@"
VideoName39: db "ANCIENT POWER@"
VideoName40: db "GEAR GRIND@"
VideoName41: db "SHIFT GEAR@"
VideoName42: db "AQUA JET@"
VideoName43: db "BOOMBURST@"
VideoName44: db "AIR SLASH@"
VideoName45: db "ROOST@"
VideoName46: db "MUD SHOT@"
VideoName47: db "ROCK WRECKER@"
VideoName48: db "ZAP CANNON@"
VideoName49: db "WILL O WISP@"
VideoName50: db "DRAGON RUSH@"
VideoName51: db "METAL SOUND@"
VideoName52: db "POWER WHIP@"
VideoName53: db "STONE EDGE@"
VideoName54: db "DRILL RUN@"

; SAND TOMB / Deluxe move #18, 13 bytes
VideoRecipe00:
	db VideoRecipe00End - VideoRecipe00Data
VideoRecipe00Data:
	db $46,$6B,$28
	db $04,$FF,$0A
	db $06,$83,$23
	db $06,$83,$23
	db $FF
VideoRecipe00End:
	ASSERT VideoRecipe00End - VideoRecipe00Data <= 30

; SUPERPOWER / Deluxe move #99, 12 bytes
VideoRecipe01:
	db VideoRecipe01End - VideoRecipe01Data
VideoRecipe01Data:
	db SE_SHAKE_SCREEN, $58
	db SE_SHAKE_SCREEN, $58
	db SE_DARK_SCREEN_FLASH, $FF
	db $46,$81,$05
	db SE_DARK_SCREEN_FLASH, $FF
	db $FF
VideoRecipe01End:
	ASSERT VideoRecipe01End - VideoRecipe01Data <= 30

; HEAT WAVE / Deluxe move #116, 9 bytes
VideoRecipe02:
	db VideoRecipe02End - VideoRecipe02Data
VideoRecipe02Data:
	db $46,$34,$1F
	db SE_WAVY_SCREEN, $FF
	db $46,$FF,$0E
	db $FF
VideoRecipe02End:
	ASSERT VideoRecipe02End - VideoRecipe02Data <= 30

; DOOM DESIRE / Deluxe move #117, 11 bytes
VideoRecipe03:
	db VideoRecipe03End - VideoRecipe03Data
VideoRecipe03Data:
	db SE_FLASH_SCREEN_LONG, $FF
	db SE_LIGHT_SCREEN_PALETTE, $48
	db SE_SHAKE_SCREEN, $58
	db SE_DARK_SCREEN_FLASH, $FF
	db SE_RESET_SCREEN_PALETTE, $FF
	db $FF
VideoRecipe03End:
	ASSERT VideoRecipe03End - VideoRecipe03Data <= 30

; COSMIC POWER / Deluxe move #134, 7 bytes
VideoRecipe04:
	db VideoRecipe04End - VideoRecipe04Data
VideoRecipe04Data:
	db SE_LIGHT_SCREEN_PALETTE, $FF
	db SE_WAVY_SCREEN, $5D
	db SE_RESET_SCREEN_PALETTE, $FF
	db $FF
VideoRecipe04End:
	ASSERT VideoRecipe04End - VideoRecipe04Data <= 30

; DRAIN PUNCH / Deluxe move #204, 12 bytes
VideoRecipe05:
	db VideoRecipe05End - VideoRecipe05Data
VideoRecipe05Data:
	db $06,$07,$02
	db $03,$FF,$21
	db $03,$FF,$22
	db SE_DARK_SCREEN_FLASH, $FF
	db $ff
VideoRecipe05End:
	ASSERT VideoRecipe05End - VideoRecipe05Data <= 30

; VACUUM WAVE / Deluxe move #205, 8 bytes
VideoRecipe06:
	db VideoRecipe06End - VideoRecipe06Data
VideoRecipe06Data:
	db SE_SLIDE_MON_OFF, $A3
	db $06,$07,$02
	db SE_SHOW_MON_PIC, $FF
	db $ff
VideoRecipe06End:
	ASSERT VideoRecipe06End - VideoRecipe06Data <= 30

; DRAGON PULSE / Deluxe move #206, 23 bytes
VideoRecipe07:
	db VideoRecipe07End - VideoRecipe07Data
VideoRecipe07Data:
	db SE_DARK_SCREEN_PALETTE, $FF
	db $46,$51,$1F
	db $46,$FF,$0C
	db SE_DARK_SCREEN_FLASH, $FF
	db $46,$FF,$0D
	db SE_DARK_SCREEN_FLASH, $FF
	db $46,$FF,$0E
	db SE_DARK_SCREEN_FLASH, $FF
	db SE_RESET_SCREEN_PALETTE, $FF
	db $ff
VideoRecipe07End:
	ASSERT VideoRecipe07End - VideoRecipe07Data <= 30

; SUCKER PUNCH / Deluxe move #207, 12 bytes
VideoRecipe08:
	db VideoRecipe08End - VideoRecipe08Data
VideoRecipe08Data:
	db SE_DARK_SCREEN_PALETTE, $FF
	db SE_SLIDE_MON_OFF, $A3
	db $06,$07,$02
	db SE_SHOW_MON_PIC, $FF
	db SE_RESET_SCREEN_PALETTE, $FF
	db $ff
VideoRecipe08End:
	ASSERT VideoRecipe08End - VideoRecipe08Data <= 30

; MOONLIGHT / Deluxe move #208, 7 bytes
VideoRecipe09:
	db VideoRecipe09End - VideoRecipe09Data
VideoRecipe09Data:
	db SE_DARK_SCREEN_PALETTE, $49
	db SE_SPIRAL_BALLS_INWARD, $FF
	db SE_RESET_SCREEN_PALETTE, $FF
	db $ff
VideoRecipe09End:
	ASSERT VideoRecipe09End - VideoRecipe09Data <= 30

; VOLT TACKLE / Deluxe move #209, 18 bytes
VideoRecipe10:
	db VideoRecipe10End - VideoRecipe10Data
VideoRecipe10Data:
	db SE_SQUISH_MON_PIC, $63
	db SE_SHOOT_BALLS_UPWARD, $FF
	db SE_DARK_SCREEN_PALETTE, $48
	db SE_DARK_SCREEN_FLASH, $25
	db $42,$54,$29
	db SE_DARK_SCREEN_FLASH, $25
	db SE_RESET_SCREEN_PALETTE, $FF
	db SE_SHOW_MON_PIC, $FF
	db $ff
VideoRecipe10End:
	ASSERT VideoRecipe10End - VideoRecipe10Data <= 30

; ICE SHARD / Deluxe move #210, 11 bytes
VideoRecipe11:
	db VideoRecipe11End - VideoRecipe11Data
VideoRecipe11Data:
	db SE_MOVE_MON_HORIZONTALLY, $48
	db $06,$82,$04
	db $10,$FF,$2F
	db SE_RESET_MON_POSITION, $FF
	db $ff
VideoRecipe11End:
	ASSERT VideoRecipe11End - VideoRecipe11Data <= 30

; CRUNCH / Deluxe move #211, 8 bytes
VideoRecipe12:
	db VideoRecipe12End - VideoRecipe12Data
VideoRecipe12Data:
	db SE_DARK_SCREEN_PALETTE, $ff
	db $0a,$2B,$02
	db SE_RESET_SCREEN_PALETTE, $FF
	db $ff
VideoRecipe12End:
	ASSERT VideoRecipe12End - VideoRecipe12Data <= 30

; DARK PULSE / Deluxe move #212, 8 bytes
VideoRecipe13:
	db VideoRecipe13End - VideoRecipe13Data
VideoRecipe13Data:
	db SE_DARK_SCREEN_PALETTE, $ff
	db $0f,$3B,$2E
	db SE_RESET_SCREEN_PALETTE, $FF
	db $ff
VideoRecipe13End:
	ASSERT VideoRecipe13End - VideoRecipe13Data <= 30

; NIGHT SLASH / Deluxe move #213, 8 bytes
VideoRecipe14:
	db VideoRecipe14End - VideoRecipe14Data
VideoRecipe14Data:
	db SE_DARK_SCREEN_PALETTE, $ff
	db $06,$A2,$0F
	db SE_RESET_SCREEN_PALETTE, $FF
	db $ff
VideoRecipe14End:
	ASSERT VideoRecipe14End - VideoRecipe14Data <= 30

; FAKE TEARS / Deluxe move #214, 7 bytes
VideoRecipe15:
	db VideoRecipe15End - VideoRecipe15Data
VideoRecipe15Data:
	db SE_LIGHT_SCREEN_PALETTE, $FF
	db SE_SPIRAL_BALLS_INWARD, $38
	db SE_RESET_SCREEN_PALETTE, $FF
	db $ff
VideoRecipe15End:
	ASSERT VideoRecipe15End - VideoRecipe15Data <= 30

; BULLET PUNCH / Deluxe move #215, 25 bytes
VideoRecipe16:
	db VideoRecipe16End - VideoRecipe16Data
VideoRecipe16Data:
	db $01,$28,$01
	db $01,$28,$01
	db $01,$28,$01
	db $01,$28,$01
	db $01,$28,$01
	db $01,$28,$01
	db $01,$28,$01
	db $01,$28,$01
	db $ff
VideoRecipe16End:
	ASSERT VideoRecipe16End - VideoRecipe16Data <= 30

; FLASH CANNON / Deluxe move #216, 8 bytes
VideoRecipe17:
	db VideoRecipe17End - VideoRecipe17Data
VideoRecipe17Data:
	db SE_LIGHT_SCREEN_PALETTE, $FF
	db $0f,$3B,$2E
	db SE_RESET_SCREEN_PALETTE, $FF
	db $ff
VideoRecipe17End:
	ASSERT VideoRecipe17End - VideoRecipe17Data <= 30

; IRON HEAD / Deluxe move #217, 12 bytes
VideoRecipe18:
	db VideoRecipe18End - VideoRecipe18Data
VideoRecipe18Data:
	db SE_LIGHT_SCREEN_PALETTE, $FF
	db SE_MOVE_MON_HORIZONTALLY, $48
	db $02,$14,$02
	db SE_RESET_MON_POSITION, $FF
	db SE_RESET_SCREEN_PALETTE, $FF
	db $ff
VideoRecipe18End:
	ASSERT VideoRecipe18End - VideoRecipe18Data <= 30

; STEEL WING / Deluxe move #218, 8 bytes
VideoRecipe19:
	db VideoRecipe19End - VideoRecipe19Data
VideoRecipe19Data:
	db SE_LIGHT_SCREEN_PALETTE, $FF
	db $46,$10,$04
	db SE_RESET_SCREEN_PALETTE, $FF
	db $ff
VideoRecipe19End:
	ASSERT VideoRecipe19End - VideoRecipe19Data <= 30

; LEAF BLADE / Deluxe move #219, 16 bytes
VideoRecipe20:
	db VideoRecipe20End - VideoRecipe20Data
VideoRecipe20Data:
	db SE_LEAVES_FALLING, $4A
	db $41,$80,$44
	db SE_DARK_SCREEN_FLASH, $FF
	db $01,$0C,$16
	db SE_DARK_SCREEN_FLASH, $FF
	db $46,$0D,$18
	db $ff
VideoRecipe20End:
	ASSERT VideoRecipe20End - VideoRecipe20Data <= 30

; DAZZLING GLEAM / Deluxe move #220, 7 bytes
VideoRecipe21:
	db VideoRecipe21End - VideoRecipe21Data
VideoRecipe21Data:
	db SE_LIGHT_SCREEN_PALETTE, $48
	db SE_WAVY_SCREEN, $88
	db SE_RESET_SCREEN_PALETTE, $FF
	db $ff
VideoRecipe21End:
	ASSERT VideoRecipe21End - VideoRecipe21Data <= 30

; DRAINING KISS / Deluxe move #221, 16 bytes
VideoRecipe22:
	db VideoRecipe22End - VideoRecipe22Data
VideoRecipe22Data:
	db SE_LIGHT_SCREEN_PALETTE, $48
	db $08,$00,$01
	db $03,$FF,$21
	db $03,$FF,$22
	db SE_DARK_SCREEN_FLASH, $FF
	db SE_RESET_SCREEN_PALETTE, $FF
	db $ff
VideoRecipe22End:
	ASSERT VideoRecipe22End - VideoRecipe22Data <= 30

; PLAY ROUGH / Deluxe move #222, 13 bytes
VideoRecipe23:
	db VideoRecipe23End - VideoRecipe23Data
VideoRecipe23Data:
	db SE_LIGHT_SCREEN_PALETTE, $ff
	db $08,$00,$01
	db SE_DARK_SCREEN_PALETTE, $ff
	db $02,$14,$02
	db SE_RESET_SCREEN_PALETTE, $FF
	db $ff
VideoRecipe23End:
	ASSERT VideoRecipe23End - VideoRecipe23Data <= 30

; MOONBLAST / Deluxe move #223, 11 bytes
VideoRecipe24:
	db VideoRecipe24End - VideoRecipe24Data
VideoRecipe24Data:
	db SE_SHOOT_BALLS_UPWARD, $FF
	db SE_LIGHT_SCREEN_PALETTE, $48
	db SE_SHAKE_SCREEN, $88
	db SE_SHAKE_SCREEN, $88
	db SE_RESET_SCREEN_PALETTE, $FF
	db $ff
VideoRecipe24End:
	ASSERT VideoRecipe24End - VideoRecipe24Data <= 30

; GUNK SHOT / Deluxe move #224, 13 bytes
VideoRecipe25:
	db VideoRecipe25End - VideoRecipe25Data
VideoRecipe25Data:
	db SE_DARK_SCREEN_PALETTE, $ff
	db SE_SPIRAL_BALLS_INWARD, $38
	db SE_RESET_SCREEN_PALETTE, $FF
	db $46,$90,$35
	db $46,$32,$14
	db $ff
VideoRecipe25End:
	ASSERT VideoRecipe25End - VideoRecipe25Data <= 30

; WOOD HAMMER / Deluxe move #225, 10 bytes
VideoRecipe26:
	db VideoRecipe26End - VideoRecipe26Data
VideoRecipe26Data:
	db $48,$16,$05
	db SE_SHAKE_SCREEN, $FF
	db SE_DARK_SCREEN_FLASH, $FF
	db SE_DARK_SCREEN_FLASH, $FF
	db $ff
VideoRecipe26End:
	ASSERT VideoRecipe26End - VideoRecipe26Data <= 30

; POISON JAB / Deluxe move #226, 7 bytes
VideoRecipe27:
	db VideoRecipe27End - VideoRecipe27Data
VideoRecipe27Data:
	db $06,$27,$00
	db $46,$7B,$14
	db $ff
VideoRecipe27End:
	ASSERT VideoRecipe27End - VideoRecipe27Data <= 30

; SLUDGE WAVE / Deluxe move #227, 9 bytes
VideoRecipe28:
	db VideoRecipe28End - VideoRecipe28Data
VideoRecipe28Data:
	db $46,$7B,$13
	db $46,$7B,$14
	db SE_WAVY_SCREEN, $FF
	db $ff
VideoRecipe28End:
	ASSERT VideoRecipe28End - VideoRecipe28Data <= 30

; BUG BUZZ / Deluxe move #228, 12 bytes
VideoRecipe29:
	db VideoRecipe29End - VideoRecipe29Data
VideoRecipe29Data:
	db SE_DARK_SCREEN_FLASH, $FF
	db SE_LIGHT_SCREEN_PALETTE, $60
	db $06,$2F,$31
	db SE_RESET_SCREEN_PALETTE, $FF
	db SE_DARK_SCREEN_FLASH, $FF
	db $ff
VideoRecipe29End:
	ASSERT VideoRecipe29End - VideoRecipe29Data <= 30

; MEGAHORN / Deluxe move #229, 13 bytes
VideoRecipe30:
	db VideoRecipe30End - VideoRecipe30Data
VideoRecipe30Data:
	db SE_MOVE_MON_HORIZONTALLY, $48
	db $06,$1D,$45
	db SE_DARK_SCREEN_FLASH, $FF
	db $46,$FF,$05
	db SE_RESET_MON_POSITION, $FF
	db $ff
VideoRecipe30End:
	ASSERT VideoRecipe30End - VideoRecipe30Data <= 30

; PSYCHO CUT / Deluxe move #230, 13 bytes
VideoRecipe31:
	db VideoRecipe31End - VideoRecipe31Data
VideoRecipe31Data:
	db $06,$2F,$31
	db SE_LIGHT_SCREEN_PALETTE, $FF
	db SE_DARK_SCREEN_FLASH, $0E
	db $04,$FF,$16
	db SE_RESET_SCREEN_PALETTE, $FF
	db $ff
VideoRecipe31End:
	ASSERT VideoRecipe31End - VideoRecipe31Data <= 30

; X SCISSOR / Deluxe move #231, 9 bytes
VideoRecipe32:
	db VideoRecipe32End - VideoRecipe32Data
VideoRecipe32Data:
	db SE_DARK_SCREEN_FLASH, $0E
	db $02,$FF,$16
	db $02,$FF,$16
	db $ff
VideoRecipe32End:
	ASSERT VideoRecipe32End - VideoRecipe32Data <= 30

; SHADOW PUNCH / Deluxe move #232, 15 bytes
VideoRecipe33:
	db VideoRecipe33End - VideoRecipe33Data
VideoRecipe33Data:
	db SE_DARK_SCREEN_PALETTE, $ff
	db SE_MOVE_MON_HORIZONTALLY, $48
	db $46,$04,$04
	db $05,$FF,$55
	db SE_RESET_MON_POSITION, $FF
	db SE_RESET_SCREEN_PALETTE, $FF
	db $ff
VideoRecipe33End:
	ASSERT VideoRecipe33End - VideoRecipe33Data <= 30

; EXTREMESPEED / Deluxe move #233, 12 bytes
VideoRecipe34:
	db VideoRecipe34End - VideoRecipe34Data
VideoRecipe34Data:
	db SE_SQUISH_MON_PIC, $63
	db SE_SHOOT_BALLS_UPWARD, $FF
	db $04,$0C,$16
	db SE_DARK_SCREEN_FLASH, $FF
	db SE_SHOW_MON_PIC, $FF
	db $ff
VideoRecipe34End:
	ASSERT VideoRecipe34End - VideoRecipe34Data <= 30

; ROCK POLISH / Deluxe move #234, 8 bytes
VideoRecipe35:
	db VideoRecipe35End - VideoRecipe35Data
VideoRecipe35Data:
	db SE_DARK_SCREEN_PALETTE, $6E
	db $06,$FF,$43
	db SE_RESET_SCREEN_PALETTE, $FF
	db $FF
VideoRecipe35End:
	ASSERT VideoRecipe35End - VideoRecipe35Data <= 30

; OMINOUS WIND / Deluxe move #235, 7 bytes
VideoRecipe36:
	db VideoRecipe36End - VideoRecipe36Data
VideoRecipe36Data:
	db SE_DARK_SCREEN_PALETTE, $FF
	db SE_WAVY_SCREEN, $5C
	db SE_RESET_SCREEN_PALETTE, $FF
	db $ff
VideoRecipe36End:
	ASSERT VideoRecipe36End - VideoRecipe36Data <= 30

; CROSS CHOP / Deluxe move #236, 6 bytes
VideoRecipe37:
	db VideoRecipe37End - VideoRecipe37Data
VideoRecipe37Data:
	db $08,$7F,$2A
	db SE_DARK_SCREEN_FLASH, $0E
	db $FF
VideoRecipe37End:
	ASSERT VideoRecipe37End - VideoRecipe37Data <= 30

; HURRICANE / Deluxe move #237, 14 bytes
VideoRecipe38:
	db VideoRecipe38End - VideoRecipe38Data
VideoRecipe38Data:
	db SE_DARK_SCREEN_FLASH, $10
	db $46,$11,$10
	db SE_SLIDE_ENEMY_MON_OFF, $FF
	db SE_DARK_SCREEN_FLASH, $10
	db SE_WAVY_SCREEN, $FF
	db SE_SHOW_ENEMY_MON_PIC, $FF
	db $FF
VideoRecipe38End:
	ASSERT VideoRecipe38End - VideoRecipe38Data <= 30

; ANCIENT POWER / Deluxe move #238, 8 bytes
VideoRecipe39:
	db VideoRecipe39End - VideoRecipe39Data
VideoRecipe39Data:
	db SE_WAVY_SCREEN, $FF
	db SE_DARK_SCREEN_FLASH, $0E
	db $04,$57,$30
	db $FF
VideoRecipe39End:
	ASSERT VideoRecipe39End - VideoRecipe39Data <= 30

; GEAR GRIND / Deluxe move #239, 8 bytes
VideoRecipe40:
	db VideoRecipe40End - VideoRecipe40Data
VideoRecipe40Data:
	db SE_LIGHT_SCREEN_PALETTE, $FF
	db $06,$9A,$02
	db SE_RESET_SCREEN_PALETTE, $FF
	db $ff
VideoRecipe40End:
	ASSERT VideoRecipe40End - VideoRecipe40Data <= 30

; SHIFT GEAR / Deluxe move #240, 12 bytes
VideoRecipe41:
	db VideoRecipe41End - VideoRecipe41Data
VideoRecipe41Data:
	db SE_LIGHT_SCREEN_PALETTE, $60
	db SE_DARK_SCREEN_FLASH, $FF
	db $46,$FF,$43
	db SE_DARK_SCREEN_FLASH, $FF
	db SE_RESET_SCREEN_PALETTE, $FF
	db $ff
VideoRecipe41End:
	ASSERT VideoRecipe41End - VideoRecipe41Data <= 30

; AQUA JET / Deluxe move #241, 14 bytes
VideoRecipe42:
	db VideoRecipe42End - VideoRecipe42Data
VideoRecipe42Data:
	db SE_SLIDE_MON_OFF, $61
	db $46,$FF,$04
	db $06,$37,$1A
	db $08,$FF,$02
	db SE_SHOW_MON_PIC, $FF
	db $ff
VideoRecipe42End:
	ASSERT VideoRecipe42End - VideoRecipe42Data <= 30

; BOOMBURST / Deluxe move #242, 11 bytes
VideoRecipe43:
	db VideoRecipe43End - VideoRecipe43Data
VideoRecipe43Data:
	db $46,$2D,$15
	db SE_SHAKE_SCREEN, $58
	db $46,$2D,$15
	db SE_SHAKE_SCREEN, $58
	db $FF
VideoRecipe43End:
	ASSERT VideoRecipe43End - VideoRecipe43Data <= 30

; AIR SLASH / Deluxe move #243, 4 bytes
VideoRecipe44:
	db VideoRecipe44End - VideoRecipe44Data
VideoRecipe44Data:
	db $06,$FF,$16
	db $ff
VideoRecipe44End:
	ASSERT VideoRecipe44End - VideoRecipe44Data <= 30

; ROOST / Deluxe move #244, 11 bytes
VideoRecipe45:
	db VideoRecipe45End - VideoRecipe45Data
VideoRecipe45Data:
	db SE_SLIDE_MON_DOWN, $FF
	db SE_LIGHT_SCREEN_PALETTE, $6E
	db SE_SPIRAL_BALLS_INWARD, $FF
	db SE_RESET_SCREEN_PALETTE, $FF
	db SE_SLIDE_MON_UP, $FF
	db $ff
VideoRecipe45End:
	ASSERT VideoRecipe45End - VideoRecipe45Data <= 30

; MUD SHOT / Deluxe move #245, 7 bytes
VideoRecipe46:
	db VideoRecipe46End - VideoRecipe46Data
VideoRecipe46Data:
	db $46,$6B,$28
	db $04,$FF,$0A
	db $ff
VideoRecipe46End:
	ASSERT VideoRecipe46End - VideoRecipe46Data <= 30

; ROCK WRECKER / Deluxe move #246, 18 bytes
VideoRecipe47:
	db VideoRecipe47End - VideoRecipe47Data
VideoRecipe47Data:
	db SE_DARK_SCREEN_PALETTE, $48
	db $04,$9C,$1D
	db SE_SHAKE_SCREEN, $58
	db $03,$9C,$1E
	db $46,$9D,$04
	db SE_SHAKE_SCREEN, $58
	db SE_RESET_SCREEN_PALETTE, $FF
	db $FF
VideoRecipe47End:
	ASSERT VideoRecipe47End - VideoRecipe47Data <= 30

; ZAP CANNON / Deluxe move #247, 13 bytes
VideoRecipe48:
	db VideoRecipe48End - VideoRecipe48Data
VideoRecipe48Data:
	db $02,$22,$23
	db $41,$54,$29
	db $41,$54,$29
	db $02,$22,$23
	db $ff
VideoRecipe48End:
	ASSERT VideoRecipe48End - VideoRecipe48Data <= 30

; WILL O WISP / Deluxe move #248, 8 bytes
VideoRecipe49:
	db VideoRecipe49End - VideoRecipe49Data
VideoRecipe49Data:
	db SE_DARK_SCREEN_PALETTE, $56
	db $46,$33,$11
	db SE_RESET_SCREEN_PALETTE, $FF
	db $FF
VideoRecipe49End:
	ASSERT VideoRecipe49End - VideoRecipe49Data <= 30

; DRAGON RUSH / Deluxe move #249, 8 bytes
VideoRecipe50:
	db VideoRecipe50End - VideoRecipe50Data
VideoRecipe50Data:
	db SE_DARK_SCREEN_PALETTE, $FF
	db $06,$14,$02
	db SE_RESET_SCREEN_PALETTE, $FF
	db $FF
VideoRecipe50End:
	ASSERT VideoRecipe50End - VideoRecipe50Data <= 30

; METAL SOUND / Deluxe move #250, 8 bytes
VideoRecipe51:
	db VideoRecipe51End - VideoRecipe51Data
VideoRecipe51Data:
	db SE_DARK_SCREEN_PALETTE, $FF
	db $46,$66,$12
	db SE_RESET_SCREEN_PALETTE, $FF
	db $FF
VideoRecipe51End:
	ASSERT VideoRecipe51End - VideoRecipe51Data <= 30

; POWER WHIP / Deluxe move #252, 11 bytes
VideoRecipe52:
	db VideoRecipe52End - VideoRecipe52Data
VideoRecipe52Data:
	db SE_DARK_SCREEN_PALETTE, $FF
	db $01,$15,$16
	db $08,$FF,$01
	db SE_RESET_SCREEN_PALETTE, $FF
	db $FF
VideoRecipe52End:
	ASSERT VideoRecipe52End - VideoRecipe52Data <= 30

; STONE EDGE / Deluxe move #253, 13 bytes
VideoRecipe53:
	db VideoRecipe53End - VideoRecipe53Data
VideoRecipe53Data:
	db SE_DARK_SCREEN_FLASH, $59
	db $03,$9C,$1E
	db SE_DARK_SCREEN_FLASH, $59
	db $44,$9D,$04
	db SE_DARK_SCREEN_FLASH, $59
	db $FF
VideoRecipe53End:
	ASSERT VideoRecipe53End - VideoRecipe53Data <= 30

; DRILL RUN / Deluxe move #254, 23 bytes
VideoRecipe54:
	db VideoRecipe54End - VideoRecipe54Data
VideoRecipe54Data:
	db $46,$40,$04
	db $42,$1F,$05
	db SE_DARK_SCREEN_PALETTE, $FF
	db $42,$FF,$05
	db $42,$FF,$05
	db $42,$FF,$05
	db $42,$FF,$05
	db SE_RESET_SCREEN_PALETTE, $FF
	db $FF
VideoRecipe54End:
	ASSERT VideoRecipe54End - VideoRecipe54Data <= 30
