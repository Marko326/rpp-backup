; PC regional form batch. All gameplay parameters provisional until coordinated pass.
SECTION "Regional PC Batch Data", ROMX, BANK[$34]

; alola_meowth: Polished Crystal meowth_alolan; data is provisional until unified form balance pass.
; Special = ANIM normal five-stat total - regional HP/Attack/Defense/Speed (BST conserved).
AlolaMeowthBaseStats::
	db DEX_MEOWTH
	db 40, 35, 35, 90, 50 ; provisional stats (single-Special adaptation)
	db DARK, DARK ; source regional typing
	db MEOWTH_CATCH_RATE ; inherit normal species catch rate (provisional)
	db 69 ; inherit normal species base experience (provisional)
	INCBIN "pic/bmon/meowth_alola.pic",0,1 ; packed front picture dimensions
	dw AlolaMeowthPicFront
	dw AlolaMeowthPicBack
	m_tutor 0
	m_tutor 0
	m_tutor 0
	m_tutor 0
	db 0 ; growth rate provisional
	tmlearn 6,8
	tmlearn 9,10,11,12,16
	tmlearn 20,24
	tmlearn 25,28,30,31,32
	tmlearn 34,39,40
	tmlearn 41,42,43,44
	tmlearn 50,51
	db BANK(AlolaMeowthPicFront)

AlolaMeowthLevelMoves::
	db 1,SCRATCH
	db 1,GROWL
	db 6,BITE
	db 17,SCREECH
	db 22,FEINT_ATTACK
	db 30,PAY_DAY
	db 33,SLASH
	db 49,NIGHT_SLASH
	db 55,DARK_PULSE
	db 0

AlolaMeowthEvolutions::
	db EV_LEVEL,28,PERSIAN
	db 0

AlolaMeowthPreviewPalette::
		RGB 23, 23, 26
		RGB 11, 11, 13
AlolaMeowthShinyPalette::
		RGB 14, 16, 22
		RGB 11, 09, 15

; alola_persian: Polished Crystal persian_alolan; data is provisional until unified form balance pass.
; Special = ANIM normal five-stat total - regional HP/Attack/Defense/Speed (BST conserved).
AlolaPersianBaseStats::
	db DEX_PERSIAN
	db 65, 60, 60, 115, 75 ; provisional stats (single-Special adaptation)
	db DARK, DARK ; source regional typing
	db PERSIAN_CATCH_RATE ; inherit normal species catch rate (provisional)
	db 148 ; inherit normal species base experience (provisional)
	INCBIN "pic/bmon/persian_alola.pic",0,1 ; packed front picture dimensions
	dw AlolaPersianPicFront
	dw AlolaPersianPicBack
	m_tutor 0
	m_tutor 0
	m_tutor 0
	m_tutor 0
	db 0 ; growth rate provisional
	tmlearn 6,8
	tmlearn 9,10,11,12,15,16
	tmlearn 20,24
	tmlearn 25,28,30,31,32
	tmlearn 34,39,40
	tmlearn 41,42,43,44
	tmlearn 50,51,54
	db BANK(AlolaPersianPicFront)

AlolaPersianLevelMoves::
	db 1,SWIFT
	db 1,SCRATCH
	db 1,GROWL
	db 6,BITE
	db 17,SCREECH
	db 22,FEINT_ATTACK
	db 32,POWER_GEM
	db 37,SLASH
	db 61,NIGHT_SLASH
	db 65,DARK_PULSE
	db 0

AlolaPersianEvolutions::
	db 0

AlolaPersianPreviewPalette::
		RGB 23, 23, 26
		RGB 11, 11, 13
AlolaPersianShinyPalette::
		RGB 14, 16, 22
		RGB 11, 09, 15

; alola_exeggutor: Polished Crystal exeggutor_alolan; data is provisional until unified form balance pass.
; Special = ANIM normal five-stat total - regional HP/Attack/Defense/Speed (BST conserved).
AlolaExeggutorBaseStats::
	db DEX_EXEGGUTOR
	db 95, 105, 85, 45, 125 ; provisional stats (single-Special adaptation)
	db GRASS, DRAGON ; source regional typing
	db EXEGGUTOR_CATCH_RATE ; inherit normal species catch rate (provisional)
	db 212 ; inherit normal species base experience (provisional)
	INCBIN "pic/bmon/exeggutor_alola.pic",0,1 ; packed front picture dimensions
	dw AlolaExeggutorPicFront
	dw AlolaExeggutorPicBack
	m_tutor 0
	m_tutor 0
	m_tutor 0
	m_tutor 0
	db 0 ; growth rate provisional
	tmlearn 3,5,6
	tmlearn 9,10,15
	tmlearn 21,22
	tmlearn 29,31,32
	tmlearn 33,34,40
	tmlearn 42,44,46,47
	tmlearn 50,54
	db BANK(AlolaExeggutorPicFront)

AlolaExeggutorLevelMoves::
	db 1,TACKLE
	db 1,HYPNOSIS
	db 1,CONFUSION
	db 1,DRAGON_PULSE
	db 17,DRAGON_RAGE
	db 27,ZEN_HEADBUTT
	db 47,OUTRAGE
	db 0

AlolaExeggutorEvolutions::
	db 0

AlolaExeggutorPreviewPalette::
		RGB 22, 15, 09
		RGB 05, 16, 07
AlolaExeggutorShinyPalette::
		RGB 27, 23, 10
		RGB 27, 18, 10

; galar_meowth: Polished Crystal meowth_galarian; data is provisional until unified form balance pass.
; Special = ANIM normal five-stat total - regional HP/Attack/Defense/Speed (BST conserved).
GalarMeowthBaseStats::
	db DEX_MEOWTH
	db 50, 65, 55, 40, 40 ; provisional stats (single-Special adaptation)
	db STEEL, STEEL ; source regional typing
	db MEOWTH_CATCH_RATE ; inherit normal species catch rate (provisional)
	db 69 ; inherit normal species base experience (provisional)
	INCBIN "pic/bmon/meowth_galar.pic",0,1 ; packed front picture dimensions
	dw GalarMeowthPicFront
	dw GalarMeowthPicBack
	m_tutor 0
	m_tutor 0
	m_tutor 0
	m_tutor 0
	db 0 ; growth rate provisional
	tmlearn 6,8
	tmlearn 9,10,11,12,16
	tmlearn 20,24
	tmlearn 25,28,30,31,32
	tmlearn 34,39,40
	tmlearn 41,42,43,44
	tmlearn 50,51
	db BANK(GalarMeowthPicFront)

GalarMeowthLevelMoves::
	db 1,GROWL
	db 4,HONE_CLAWS
	db 8,SCRATCH
	db 12,PAY_DAY
	db 16,METAL_CLAW
	db 32,SCREECH
	db 36,SLASH
	db 40,CRUNCH
	db 44,THRASH
	db 0

GalarMeowthEvolutions::
	db EV_LEVEL,28,PERSIAN
	db 0

GalarMeowthPreviewPalette::
		RGB 20, 18, 14
		RGB 04, 07, 05
GalarMeowthShinyPalette::
		RGB 29, 28, 19
		RGB 25, 21, 13

; galar_ponyta: Polished Crystal ponyta_galarian; data is provisional until unified form balance pass.
; Special = ANIM normal five-stat total - regional HP/Attack/Defense/Speed (BST conserved).
GalarPonytaBaseStats::
	db DEX_PONYTA
	db 50, 85, 55, 90, 65 ; provisional stats (single-Special adaptation)
	db PSYCHIC, PSYCHIC ; source regional typing
	db PONYTA_CATCH_RATE ; inherit normal species catch rate (provisional)
	db 152 ; inherit normal species base experience (provisional)
	INCBIN "pic/bmon/ponyta_galar.pic",0,1 ; packed front picture dimensions
	dw GalarPonytaPicFront
	dw GalarPonytaPicBack
	m_tutor 0
	m_tutor 0
	m_tutor 0
	m_tutor 0
	db 0 ; growth rate provisional
	tmlearn 5,6,7,8
	tmlearn 9,10,16
	tmlearn 22
	tmlearn 31,32
	tmlearn 33,34,37,38,39,40
	tmlearn 44
	tmlearn 54
	db BANK(GalarPonytaPicFront)

GalarPonytaLevelMoves::
	db 1,GROWL
	db 1,TACKLE
	db 4,LEER
	db 9,CONFUSION
	db 13,DISARM_VOICE
	db 17,STOMP
	db 21,HEALINGLIGHT
	db 25,PSYBEAM
	db 29,TAKE_DOWN
	db 33,DAZZLINGLEAM
	db 37,AGILITY
	db 41,PSYCHIC_M
	db 45,EXTREMESPEED
	db 49,MOONBLAST
	db 0

GalarPonytaEvolutions::
	db EV_LEVEL,40,RAPIDASH
	db 0

GalarPonytaPreviewPalette::
		RGB 10, 26, 27
		RGB 20, 14, 27
GalarPonytaShinyPalette::
		RGB 27, 26, 25
		RGB 10, 26, 27

; galar_rapidash: Polished Crystal rapidash_galarian; data is provisional until unified form balance pass.
; Special = ANIM normal five-stat total - regional HP/Attack/Defense/Speed (BST conserved).
GalarRapidashBaseStats::
	db DEX_RAPIDASH
	db 65, 100, 70, 105, 80 ; provisional stats (single-Special adaptation)
	db PSYCHIC, FAIRY ; source regional typing
	db RAPIDASH_CATCH_RATE ; inherit normal species catch rate (provisional)
	db 192 ; inherit normal species base experience (provisional)
	INCBIN "pic/bmon/rapidash_galar.pic",0,1 ; packed front picture dimensions
	dw GalarRapidashPicFront
	dw GalarRapidashPicBack
	m_tutor 0
	m_tutor 0
	m_tutor 0
	m_tutor 0
	db 0 ; growth rate provisional
	tmlearn 5,6,7,8
	tmlearn 9,10,15,16
	tmlearn 22
	tmlearn 31,32
	tmlearn 33,34,37,38,39,40
	tmlearn 44
	tmlearn 54
	db BANK(GalarRapidashPicFront)

GalarRapidashLevelMoves::
	db 1,MEGAHORN
	db 1,GROWL
	db 1,TACKLE
	db 4,LEER
	db 9,CONFUSION
	db 13,DISARM_VOICE
	db 17,STOMP
	db 21,HEALINGLIGHT
	db 25,PSYBEAM
	db 29,TAKE_DOWN
	db 33,DAZZLINGLEAM
	db 37,AGILITY
	db 41,PSYCHIC_M
	db 45,EXTREMESPEED
	db 49,MOONBLAST
	db 0

GalarRapidashEvolutions::
	db 0

GalarRapidashPreviewPalette::
		RGB 10, 26, 27
		RGB 20, 14, 27
GalarRapidashShinyPalette::
		RGB 27, 26, 25
		RGB 10, 26, 27

; galar_slowpoke: Polished Crystal slowpoke_galarian; data is provisional until unified form balance pass.
; Special = ANIM normal five-stat total - regional HP/Attack/Defense/Speed (BST conserved).
GalarSlowpokeBaseStats::
	db DEX_SLOWPOKE
	db 90, 65, 65, 15, 40 ; provisional stats (single-Special adaptation)
	db PSYCHIC, PSYCHIC ; source regional typing
	db SLOWPOKE_CATCH_RATE ; inherit normal species catch rate (provisional)
	db 99 ; inherit normal species base experience (provisional)
	INCBIN "pic/bmon/slowpoke_galar.pic",0,1 ; packed front picture dimensions
	dw GalarSlowpokePicFront
	dw GalarSlowpokePicBack
	m_tutor 0
	m_tutor 0
	m_tutor 0
	m_tutor 0
	db 0 ; growth rate provisional
	tmlearn 1,5,6,8
	tmlearn 9,10,11,12,13,14,16
	tmlearn 17,18,19
	tmlearn 26,27,28,29,30,31,32
	tmlearn 33,34,37,38,39,40
	tmlearn 41,43,44,45,46
	tmlearn 49,50,53,54,55
	db BANK(GalarSlowpokePicFront)

GalarSlowpokeLevelMoves::
	db 1,TACKLE
	db 5,GROWL
	db 9,ACID
	db 14,CONFUSION
	db 19,DISABLE
	db 23,HEADBUTT
	db 28,WATER_PULSE
	db 32,ZEN_HEADBUTT
	db 41,AMNESIA
	db 45,PSYCHIC_M
	db 58,RECOVER
	db 0

GalarSlowpokeEvolutions::
	db EV_ITEM,MOON_STONE,1,SLOWKING
	db EV_LEVEL,37,SLOWBRO
	db 0

GalarSlowpokePreviewPalette::
		RGB 31, 10, 17
		RGB 29, 27, 02
GalarSlowpokeShinyPalette::
		RGB 29, 28, 01
		RGB 22, 19, 00

; galar_slowbro: Polished Crystal slowbro_galarian; data is provisional until unified form balance pass.
; Special = ANIM normal five-stat total - regional HP/Attack/Defense/Speed (BST conserved).
GalarSlowbroBaseStats::
	db DEX_SLOWBRO
	db 95, 100, 95, 30, 70 ; provisional stats (single-Special adaptation)
	db POISON, PSYCHIC ; source regional typing
	db SLOWBRO_CATCH_RATE ; inherit normal species catch rate (provisional)
	db 164 ; inherit normal species base experience (provisional)
	INCBIN "pic/bmon/slowbro_galar.pic",0,1 ; packed front picture dimensions
	dw GalarSlowbroPicFront
	dw GalarSlowbroPicBack
	m_tutor 0
	m_tutor 0
	m_tutor 0
	m_tutor 0
	db 0 ; growth rate provisional
	tmlearn 1,5,6,8
	tmlearn 9,10,11,12,13,14,15,16
	tmlearn 17,18,19
	tmlearn 26,27,28,29,30,31,32
	tmlearn 33,34,37,38,39,40
	tmlearn 41,43,44,45,46
	tmlearn 49,50,53,54,55
	db BANK(GalarSlowbroPicFront)

GalarSlowbroLevelMoves::
	db 1,GUNK_SHOT
	db 1,TACKLE
	db 5,GROWL
	db 9,ACID
	db 14,CONFUSION
	db 19,DISABLE
	db 23,HEADBUTT
	db 28,WATER_PULSE
	db 32,ZEN_HEADBUTT
	db 43,AMNESIA
	db 49,PSYCHIC_M
	db 68,RECOVER
	db 0

GalarSlowbroEvolutions::
	db 0

GalarSlowbroPreviewPalette::
		RGB 31, 10, 17
		RGB 16, 14, 21
GalarSlowbroShinyPalette::
		RGB 30, 25, 11
		RGB 27, 14, 31

; galar_farfetchd: Polished Crystal farfetch_d_galarian; data is provisional until unified form balance pass.
; Special = ANIM normal five-stat total - regional HP/Attack/Defense/Speed (BST conserved).
GalarFarfetchdBaseStats::
	db DEX_FARFETCHD
	db 52, 95, 55, 55, 58 ; provisional stats (single-Special adaptation)
	db FIGHTING, FIGHTING ; source regional typing
	db FARFETCHD_CATCH_RATE ; inherit normal species catch rate (provisional)
	db 94 ; inherit normal species base experience (provisional)
	INCBIN "pic/bmon/farfetchd_galar.pic",0,1 ; packed front picture dimensions
	dw GalarFarfetchdPicFront
	dw GalarFarfetchdPicBack
	m_tutor 0
	m_tutor 0
	m_tutor 0
	m_tutor 0
	db 0 ; growth rate provisional
	tmlearn 3,4,6,8
	tmlearn 9,10,16
	tmlearn 0
	tmlearn 31,32
	tmlearn 33,34,39,40
	tmlearn 41,44
	tmlearn 51,52
	db BANK(GalarFarfetchdPicFront)

GalarFarfetchdLevelMoves::
	db 1,PECK
	db 1,MUD_SLAP
	db 5,LEER
	db 10,QUICK_ATTACK
	db 20,FEINT_ATTACK
	db 35,STEEL_WING
	db 40,NIGHT_SLASH
	db 45,SWORDS_DANCE
	db 50,BODY_SLAM
	db 55,POISON_JAB
	db 0

GalarFarfetchdEvolutions::
	db 0

GalarFarfetchdPreviewPalette::
		RGB 11, 22, 08
		RGB 15, 10, 06
GalarFarfetchdShinyPalette::
		RGB 13, 11, 11
		RGB 06, 14, 07

; galar_mrmime: Polished Crystal mr__mime_galarian; data is provisional until unified form balance pass.
; Special = ANIM normal five-stat total - regional HP/Attack/Defense/Speed (BST conserved).
GalarMrmimeBaseStats::
	db DEX_MR_MIME
	db 50, 65, 65, 100, 60 ; provisional stats (single-Special adaptation)
	db ICE, PSYCHIC ; source regional typing
	db MR_MIME_CATCH_RATE ; inherit normal species catch rate (provisional)
	db 136 ; inherit normal species base experience (provisional)
	INCBIN "pic/bmon/mr_mime_galar.pic",0,1 ; packed front picture dimensions
	dw GalarMrmimePicFront
	dw GalarMrmimePicBack
	m_tutor 0
	m_tutor 0
	m_tutor 0
	m_tutor 0
	db 0 ; growth rate provisional
	tmlearn 1,5,6,8
	tmlearn 9,10,15
	tmlearn 17,18,19,22,24
	tmlearn 25,29,30,31,32
	tmlearn 33,34,40
	tmlearn 41,42,44,45,46
	tmlearn 49,50
	db BANK(GalarMrmimePicFront)

GalarMrmimeLevelMoves::
	db 1,RECOVER
	db 1,LIGHT_SCREEN
	db 1,REFLECT
	db 1,DAZZLINGLEAM
	db 1,TACKLE
	db 1,ICE_SHARD
	db 12,CONFUSION
	db 16,METRONOME
	db 20,ICY_WIND
	db 24,DOUBLE_KICK
	db 28,PSYBEAM
	db 32,HYPNOSIS
	db 40,SUCKER_PUNCH
	db 44,ICE_BEAM
	db 48,PSYCHIC_M
	db 52,CONFUSE_RAY
	db 0

GalarMrmimeEvolutions::
	db 0

GalarMrmimePreviewPalette::
		RGB 31, 23, 24
		RGB 09, 16, 27
GalarMrmimeShinyPalette::
		RGB 31, 25, 26
		RGB 12, 12, 17

; galar_articuno: Polished Crystal articuno_galarian; data is provisional until unified form balance pass.
; Special = ANIM normal five-stat total - regional HP/Attack/Defense/Speed (BST conserved).
GalarArticunoBaseStats::
	db DEX_ARTICUNO
	db 90, 85, 85, 95, 130 ; provisional stats (single-Special adaptation)
	db PSYCHIC, FLYING ; source regional typing
	db ARTICUNO_CATCH_RATE ; inherit normal species catch rate (provisional)
	db 215 ; inherit normal species base experience (provisional)
	INCBIN "pic/bmon/articuno_galar.pic",0,1 ; packed front picture dimensions
	dw GalarArticunoPicFront
	dw GalarArticunoPicBack
	m_tutor 0
	m_tutor 0
	m_tutor 0
	m_tutor 0
	db 0 ; growth rate provisional
	tmlearn 4,6
	tmlearn 9,10,11,13,14,15
	tmlearn 0
	tmlearn 31,32,33,34
	tmlearn 39
	tmlearn 41,44,46
	tmlearn 52
	db BANK(GalarArticunoPicFront)

GalarArticunoLevelMoves::
	db 1,GUST
	db 1,CONFUSION
	db 1,LEER
	db 15,HYPNOSIS
	db 22,EXTRASENSORY
	db 29,ANCIENTPOWER
	db 36,AGILITY
	db 43,PSYCHIC_M
	db 50,AIR_SLASH
	db 57,DREAM_EATER
	db 64,REFLECT
	db 85,RECOVER
	db 92,HURRICANE
	db 99,AEROBLAST
	db 0

GalarArticunoEvolutions::
	db 0

GalarArticunoPreviewPalette::
		RGB 23, 18, 25
		RGB 03, 02, 05
GalarArticunoShinyPalette::
		RGB 13, 23, 27
		RGB 26, 28, 31

; galar_zapdos: Polished Crystal zapdos_galarian; data is provisional until unified form balance pass.
; Special = ANIM normal five-stat total - regional HP/Attack/Defense/Speed (BST conserved).
GalarZapdosBaseStats::
	db DEX_ZAPDOS
	db 90, 125, 90, 100, 85 ; provisional stats (single-Special adaptation)
	db FIGHTING, FLYING ; source regional typing
	db ZAPDOS_CATCH_RATE ; inherit normal species catch rate (provisional)
	db 216 ; inherit normal species base experience (provisional)
	INCBIN "pic/bmon/zapdos_galar.pic",0,1 ; packed front picture dimensions
	dw GalarZapdosPicFront
	dw GalarZapdosPicBack
	m_tutor 0
	m_tutor 0
	m_tutor 0
	m_tutor 0
	db 0 ; growth rate provisional
	tmlearn 4,6
	tmlearn 9,10,15
	tmlearn 24
	tmlearn 25,31,32
	tmlearn 33,34,39
	tmlearn 41,44,45
	tmlearn 49,50,52
	db BANK(GalarZapdosPicFront)

GalarZapdosLevelMoves::
	db 1,PECK
	db 1,LOW_KICK
	db 1,LEER
	db 8,FOCUS_ENERGY
	db 22,COUNTER
	db 29,ANCIENTPOWER
	db 36,AGILITY
	db 50,DRILL_PECK
	db 64,LIGHT_SCREEN
	db 85,HI_JUMP_KICK
	db 92,HURRICANE
	db 0

GalarZapdosEvolutions::
	db 0

GalarZapdosPreviewPalette::
		RGB 29, 12, 07
		RGB 04, 02, 03
GalarZapdosShinyPalette::
		RGB 31, 28, 00
		RGB 26, 13, 06

; galar_moltres: Polished Crystal moltres_galarian; data is provisional until unified form balance pass.
; Special = ANIM normal five-stat total - regional HP/Attack/Defense/Speed (BST conserved).
GalarMoltresBaseStats::
	db DEX_MOLTRES
	db 90, 85, 90, 90, 140 ; provisional stats (single-Special adaptation)
	db DARK, FLYING ; source regional typing
	db MOLTRES_CATCH_RATE ; inherit normal species catch rate (provisional)
	db 217 ; inherit normal species base experience (provisional)
	INCBIN "pic/bmon/moltres_galar.pic",0,1 ; packed front picture dimensions
	dw GalarMoltresPicFront
	dw GalarMoltresPicBack
	m_tutor 0
	m_tutor 0
	m_tutor 0
	m_tutor 0
	db 0 ; growth rate provisional
	tmlearn 4,6
	tmlearn 9,10,15
	tmlearn 22,23
	tmlearn 31,32
	tmlearn 33,34,37,38,39
	tmlearn 41,44
	tmlearn 50,52
	db BANK(GalarMoltresPicFront)

GalarMoltresLevelMoves::
	db 1,GUST
	db 1,LEER
	db 8,FEINT_ATTACK
	db 22,WING_ATTACK
	db 29,ANCIENTPOWER
	db 36,AGILITY
	db 43,SUCKER_PUNCH
	db 50,AIR_SLASH
	db 64,DARK_PULSE
	db 71,HEX
	db 92,HURRICANE
	db 99,NIGHT_SLASH
	db 0

GalarMoltresEvolutions::
	db 0

GalarMoltresPreviewPalette::
		RGB 29, 01, 09
		RGB 04, 03, 03
GalarMoltresShinyPalette::
		RGB 31, 12, 03
		RGB 31, 22, 00

; hisui_sneasel: Polished Crystal sneasel_hisuian; data is provisional until unified form balance pass.
; Special = ANIM normal five-stat total - regional HP/Attack/Defense/Speed (BST conserved).
HisuiSneaselBaseStats::
	db DEX_SNEASEL
	db 55, 95, 55, 115, 75 ; provisional stats (single-Special adaptation)
	db POISON, FIGHTING ; source regional typing
	db SNEASEL_CATCH_RATE ; inherit normal species catch rate (provisional)
	db 132 ; inherit normal species base experience (provisional)
	INCBIN "pic/bmon/sneasel_hisui.pic",0,1 ; packed front picture dimensions
	dw HisuiSneaselPicFront
	dw HisuiSneaselPicBack
	m_tutor 0
	m_tutor 0
	m_tutor 0
	m_tutor 0
	db 0 ; growth rate provisional
	tmlearn 1,3,5,6,8
	tmlearn 9,10,13,14,16
	tmlearn 20
	tmlearn 28,30,31,32
	tmlearn 34,39,40
	tmlearn 41,43,44,46
	tmlearn 51,53,54
	db BANK(HisuiSneaselPicFront)

HisuiSneaselLevelMoves::
	db 1,SCRATCH
	db 1,LEER
	db 1,BITE
	db 8,QUICK_ATTACK
	db 10,FEINT_ATTACK
	db 14,LOW_KICK
	db 20,AGILITY
	db 22,METAL_CLAW
	db 25,HONE_CLAWS
	db 28,POISON_JAB
	db 32,SCREECH
	db 35,SLASH
	db 40,SWORDS_DANCE
	db 44,X_SCISSOR
	db 50,GUNK_SHOT
	db 0

HisuiSneaselEvolutions::
	db EV_ITEM,MOON_STONE,1,WEAVILE
	db 0

HisuiSneaselPreviewPalette::
		RGB 21, 22, 23
		RGB 15, 13, 20
HisuiSneaselShinyPalette::
		RGB 14, 16, 17
		RGB 28, 24, 10

; paldea_tauros_combat: Polished Crystal tauros_paldean; data is provisional until unified form balance pass.
; Special = ANIM normal five-stat total - regional HP/Attack/Defense/Speed (BST conserved).
PaldeaTaurosCombatBaseStats::
	db DEX_TAUROS
	db 75, 110, 105, 100, 60 ; provisional stats (single-Special adaptation)
	db FIGHTING, FIGHTING ; source regional typing
	db TAUROS_CATCH_RATE ; inherit normal species catch rate (provisional)
	db 211 ; inherit normal species base experience (provisional)
	INCBIN "pic/bmon/tauros_paldea_combat.pic",0,1 ; packed front picture dimensions
	dw PaldeaTaurosCombatPicFront
	dw PaldeaTaurosCombatPicBack
	m_tutor 0
	m_tutor 0
	m_tutor 0
	m_tutor 0
	db 0 ; growth rate provisional
	tmlearn 1,5,6,7,8
	tmlearn 9,10,11,13,14,15,16
	tmlearn 22,24
	tmlearn 25,26,27,30,31,32
	tmlearn 34,36,40
	tmlearn 44,45
	tmlearn 53,54
	db BANK(PaldeaTaurosCombatPicFront)

PaldeaTaurosCombatLevelMoves::
	db 1,TACKLE
	db 3,LEER
	db 5,RAGE
	db 8,HEADBUTT
	db 19,REST
	db 24,DOUBLE_KICK
	db 29,FOCUS_ENERGY
	db 35,TAKE_DOWN
	db 41,ZEN_HEADBUTT
	db 55,THRASH
	db 63,DOUBLE_EDGE
	db 80,OUTRAGE
	db 0

PaldeaTaurosCombatEvolutions::
	db 0

PaldeaTaurosCombatPreviewPalette::
		RGB 11, 11, 11
		RGB 05, 05, 05
PaldeaTaurosCombatShinyPalette::
		RGB 25, 25, 25
		RGB 15, 15, 15

; paldea_tauros_aqua: Polished Crystal tauros_paldean_water; data is provisional until unified form balance pass.
; Special = ANIM normal five-stat total - regional HP/Attack/Defense/Speed (BST conserved).
PaldeaTaurosAquaBaseStats::
	db DEX_TAUROS
	db 75, 110, 105, 100, 60 ; provisional stats (single-Special adaptation)
	db FIGHTING, WATER ; source regional typing
	db TAUROS_CATCH_RATE ; inherit normal species catch rate (provisional)
	db 211 ; inherit normal species base experience (provisional)
	INCBIN "pic/bmon/tauros_paldea_aqua.pic",0,1 ; packed front picture dimensions
	dw PaldeaTaurosAquaPicFront
	dw PaldeaTaurosAquaPicBack
	m_tutor 0
	m_tutor 0
	m_tutor 0
	m_tutor 0
	db 0 ; growth rate provisional
	tmlearn 1,5,6,7,8
	tmlearn 9,10,11,13,14,15,16
	tmlearn 22,24
	tmlearn 25,26,27,30,31,32
	tmlearn 34,36,40
	tmlearn 44,45
	tmlearn 53,54
	db BANK(PaldeaTaurosAquaPicFront)

PaldeaTaurosAquaLevelMoves::
	db 1,TACKLE
	db 3,LEER
	db 5,RAGE
	db 8,HEADBUTT
	db 19,REST
	db 24,DOUBLE_KICK
	db 29,FOCUS_ENERGY
	db 35,TAKE_DOWN
	db 41,ZEN_HEADBUTT
	db 55,THRASH
	db 63,AQUA_TAIL
	db 80,OUTRAGE
	db 0

PaldeaTaurosAquaEvolutions::
	db 0

PaldeaTaurosAquaPreviewPalette::
		RGB 02, 10, 17
		RGB 09, 09, 09
PaldeaTaurosAquaShinyPalette::
		RGB 20, 07, 25
		RGB 02, 07, 15

; galar_persian_perrserker: Polished Crystal perrserker; data is provisional until unified form balance pass.
; Special = ANIM normal five-stat total - regional HP/Attack/Defense/Speed (BST conserved).
GalarPersianPerrserkerBaseStats::
	db DEX_PERSIAN
	db 70, 110, 100, 50, 45 ; provisional stats (single-Special adaptation)
	db STEEL, STEEL ; source regional typing
	db PERSIAN_CATCH_RATE ; inherit normal species catch rate (provisional)
	db 148 ; inherit normal species base experience (provisional)
	INCBIN "pic/bmon/persian_galar.pic",0,1 ; packed front picture dimensions
	dw GalarPersianPerrserkerPicFront
	dw GalarPersianPerrserkerPicBack
	m_tutor 0
	m_tutor 0
	m_tutor 0
	m_tutor 0
	db 0 ; growth rate provisional
	tmlearn 6,8
	tmlearn 9,10,11,12,15,16
	tmlearn 20,24
	tmlearn 25,28,30,31,32
	tmlearn 34,39,40
	tmlearn 41,42,43,44
	tmlearn 50,51,54
	db BANK(GalarPersianPerrserkerPicFront)

GalarPersianPerrserkerLevelMoves::
	db 1,IRON_HEAD
	db 1,COUNTER
	db 1,GROWL
	db 1,HONE_CLAWS
	db 1,SCRATCH
	db 12,PAY_DAY
	db 16,METAL_CLAW
	db 36,SCREECH
	db 42,SLASH
	db 48,CRUNCH
	db 54,THRASH
	db 0

GalarPersianPerrserkerEvolutions::
	db 0

GalarPersianPerrserkerPreviewPalette::
		RGB 20, 18, 14
		RGB 22, 10, 09
GalarPersianPerrserkerShinyPalette::
		RGB 29, 23, 14
		RGB 27, 11, 13

; hisui_weavile_sneasler: Polished Crystal sneasler; data is provisional until unified form balance pass.
; Special = ANIM normal five-stat total - regional HP/Attack/Defense/Speed (BST conserved).
HisuiWeavileSneaslerBaseStats::
	db DEX_WEAVILE
	db 80, 130, 60, 120, 75 ; provisional stats (single-Special adaptation)
	db POISON, FIGHTING ; source regional typing
	db WEAVILE_CATCH_RATE ; inherit normal species catch rate (provisional)
	db 199 ; inherit normal species base experience (provisional)
	INCBIN "pic/bmon/weavile_hisui.pic",0,1 ; packed front picture dimensions
	dw HisuiWeavileSneaslerPicFront
	dw HisuiWeavileSneaslerPicBack
	m_tutor 0
	m_tutor 0
	m_tutor 0
	m_tutor 0
	db 0 ; growth rate provisional
	tmlearn 1,3,5,6,8
	tmlearn 9,10,13,14,15,16
	tmlearn 20
	tmlearn 28,30,31,32
	tmlearn 34,39,40
	tmlearn 41,43,44,46
	tmlearn 51,53,54
	db BANK(HisuiWeavileSneaslerPicFront)

HisuiWeavileSneaslerLevelMoves::
	db 1,SCRATCH
	db 1,LEER
	db 1,BITE
	db 8,QUICK_ATTACK
	db 10,FEINT_ATTACK
	db 14,LOW_KICK
	db 20,AGILITY
	db 22,METAL_CLAW
	db 25,HONE_CLAWS
	db 28,POISON_JAB
	db 32,SCREECH
	db 35,SLASH
	db 40,SWORDS_DANCE
	db 44,X_SCISSOR
	db 50,GUNK_SHOT
	db 0

HisuiWeavileSneaslerEvolutions::
	db 0

HisuiWeavileSneaslerPreviewPalette::
		RGB 21, 22, 23
		RGB 13, 11, 19
HisuiWeavileSneaslerShinyPalette::
		RGB 24, 25, 13
		RGB 23, 22, 07
