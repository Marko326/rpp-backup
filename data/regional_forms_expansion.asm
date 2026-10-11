; ANIM-5.62.111: additional regional forms.
; Full separate headers, level-up tables, evolution and palettes.
; Learnsets start from existing branch definitions; unsupported external moves are not invented.

SECTION "Regional Expansion Data", ROMX, BANK[$34]

; HisuiGrowlithe: registered hisui form. Header uses current project ABI.
HisuiGrowlitheBaseStats::
	db DEX_GROWLITHE
	db 60
	db 75
	db 45
	db 55
	db 65
	db FIRE
	db ROCK
	db 190 ; stock catch rate
	db 91 ; stock base EXP
	INCBIN "pic/bmon/growlithe_hisui.pic",0,1 ; private sprite dimensions
	dw HisuiGrowlithePicFront
	dw HisuiGrowlithePicBack
	m_tutor 0
	m_tutor 0
	m_tutor 0
	m_tutor 0
	db 5 ; stock growth rate
	tmlearn 6,8
	tmlearn 9,10,16
	tmlearn 18,22,23
	tmlearn 28,32,33
	tmlearn 34,37,38,39,40
	tmlearn 41,44
	tmlearn 54
	db BANK(HisuiGrowlithePicFront)

HisuiGrowlitheLevelMoves::
	db 1,BITE
	db 1,GROWL
	db 1,ROAR
	db 6,EMBER
	db 8,LEER
	db 10,HEADBUTT
	db 12,DOUBLE_TEAM
	db 17,FLAME_WHEEL
	db 19,DOUBLE_KICK
	db 21,FIRE_FANG
	db 23,TAKE_DOWN
	db 28,FIRE_SPIN
	db 30,AGILITY
	db 32,THRASH
	db 34,FLAMETHROWER
	db 39,CRUNCH
	db 41,FIRE_BLAST
	db 43,OUTRAGE
	db 45,FLARE_BLITZ
	db 0

HisuiGrowlitheEvolutions::
	db EV_ITEM,FIRE_STONE,30,ARCANINE
	db 0

HisuiGrowlithePreviewPalette::
	RGB 24, 13, 9
	RGB 11, 7, 5
HisuiGrowlitheShinyPalette::
	RGB 18, 19, 22
	RGB 9, 11, 15

; HisuiArcanine: registered hisui form. Header uses current project ABI.
HisuiArcanineBaseStats::
	db DEX_ARCANINE
	db 95
	db 115
	db 80
	db 90
	db 80
	db FIRE
	db ROCK
	db 75 ; stock catch rate
	db 213 ; stock base EXP
	INCBIN "pic/bmon/arcanine_hisui.pic",0,1 ; private sprite dimensions
	dw HisuiArcaninePicFront
	dw HisuiArcaninePicBack
	m_tutor 0
	m_tutor 0
	m_tutor 0
	m_tutor 0
	db 5 ; stock growth rate
	tmlearn 6,8
	tmlearn 9,10,15,16
	tmlearn 18,22,23
	tmlearn 28,32
	tmlearn 33,34,37,38,39,40
	tmlearn 41,44
	tmlearn 54
	db BANK(HisuiArcaninePicFront)

HisuiArcanineLevelMoves::
	db 1,BITE
	db 1,FLAME_WHEEL
	db 1,TAKE_DOWN
	db 1,EXTREMESPEED
	db 6,EMBER
	db 8,LEER
	db 10,HEADBUTT
	db 12,DOUBLE_TEAM
	db 17,FLAME_WHEEL
	db 19,DOUBLE_KICK
	db 21,FIRE_FANG
	db 23,TAKE_DOWN
	db 28,FIRE_SPIN
	db 30,AGILITY
	db 32,THRASH
	db 34,FLAMETHROWER
	db 39,CRUNCH
	db 40,EXTREMESPEED
	db 41,FIRE_BLAST
	db 43,OUTRAGE
	db 45,FLARE_BLITZ
	db 0

HisuiArcanineEvolutions::
	db 0

HisuiArcaninePreviewPalette::
	RGB 25, 14, 11
	RGB 10, 8, 7
HisuiArcanineShinyPalette::
	RGB 19, 21, 22
	RGB 9, 11, 12

; HisuiVoltorb: registered hisui form. Header uses current project ABI.
HisuiVoltorbBaseStats::
	db DEX_VOLTORB
	db 40
	db 30
	db 50
	db 100
	db 55
	db ELECTRIC
	db GRASS
	db 190 ; stock catch rate
	db 103 ; stock base EXP
	INCBIN "pic/bmon/voltorb_hisui.pic",0,1 ; private sprite dimensions
	dw HisuiVoltorbPicFront
	dw HisuiVoltorbPicBack
	m_tutor 0
	m_tutor 0
	m_tutor 0
	m_tutor 0
	db 0 ; stock growth rate
	tmlearn 6
	tmlearn 9
	tmlearn 24
	tmlearn 25,31,32
	tmlearn 33,34,39,40
	tmlearn 44,45,47
	tmlearn 50
	db BANK(HisuiVoltorbPicFront)

HisuiVoltorbLevelMoves::
	db 1,TACKLE
	db 4,SONICBOOM
	db 6,AGILITY
	db 9,SPARK
	db 11,MIMIC
	db 13,SCREECH
	db 16,SIGNAL_BEAM
	db 20,SWIFT
	db 22,ELECTRO_BALL
	db 26,SELFDESTRUCT
	db 29,LIGHT_SCREEN
	db 34,REFLECT
	db 37,DISCHARGE
	db 39,EGG_BOMB
	db 41,EXPLOSION
	db 46,THUNDER
	db 48,SUBSTITUTE
	db 0

HisuiVoltorbEvolutions::
	db EV_LEVEL,30,ELECTRODE
	db 0

HisuiVoltorbPreviewPalette::
	RGB 24, 18, 10
	RGB 10, 13, 7
HisuiVoltorbShinyPalette::
	RGB 12, 19, 24
	RGB 8, 11, 16

; HisuiElectrode: registered hisui form. Header uses current project ABI.
HisuiElectrodeBaseStats::
	db DEX_ELECTRODE
	db 60
	db 50
	db 70
	db 150
	db 80
	db ELECTRIC
	db GRASS
	db 60 ; stock catch rate
	db 150 ; stock base EXP
	INCBIN "pic/bmon/electrode_hisui.pic",0,1 ; private sprite dimensions
	dw HisuiElectrodePicFront
	dw HisuiElectrodePicBack
	m_tutor 0
	m_tutor 0
	m_tutor 0
	m_tutor 0
	db 0 ; stock growth rate
	tmlearn 6
	tmlearn 9,15
	tmlearn 24
	tmlearn 25,31,32
	tmlearn 33,34,39,40
	tmlearn 44,45,47
	tmlearn 50
	db BANK(HisuiElectrodePicFront)

HisuiElectrodeLevelMoves::
	db 1,TACKLE
	db 4,SONICBOOM
	db 6,AGILITY
	db 9,SPARK
	db 11,MIMIC
	db 13,SCREECH
	db 16,SIGNAL_BEAM
	db 20,SWIFT
	db 22,ELECTRO_BALL
	db 26,SELFDESTRUCT
	db 29,LIGHT_SCREEN
	db 36,REFLECT
	db 41,DISCHARGE
	db 44,EGG_BOMB
	db 47,EXPLOSION
	db 54,THUNDER
	db 58,SUBSTITUTE
	db 0

HisuiElectrodeEvolutions::
	db 0

HisuiElectrodePreviewPalette::
	RGB 23, 18, 12
	RGB 11, 12, 6
HisuiElectrodeShinyPalette::
	RGB 12, 21, 25
	RGB 6, 12, 16

; GalarZigzagoon: registered galar form. Header uses current project ABI.
GalarZigzagoonBaseStats::
	db DEX_ZIGZAGOON
	db 38
	db 30
	db 41
	db 60
	db 41
	db DARK
	db NORMAL
	db 255 ; stock catch rate
	db 60 ; stock base EXP
	INCBIN "pic/bmon/zigzagoon_galar.pic",0,1 ; private sprite dimensions
	dw GalarZigzagoonPicFront
	dw GalarZigzagoonPicBack
	m_tutor 0
	m_tutor 0
	m_tutor 0
	m_tutor 0
	db 0 ; stock growth rate
	tmlearn 2,3,5,6,8
	tmlearn 9,10,11,12,13,14,16
	tmlearn 17,18,19,20,24
	tmlearn 25,28,30,31,32
	tmlearn 34,39,40
	tmlearn 44,45
	tmlearn 51,53,54
	db BANK(GalarZigzagoonPicFront)

GalarZigzagoonLevelMoves::
	db 1,TACKLE
	db 1,GROWL
	db 5,TAIL_WHIP
	db 7,SAND_ATTACK
	db 11,HEADBUTT
	db 12,BABYDOLLEYES
	db 13,BITE
	db 17,HYPER_VOICE
	db 19,PAY_DAY
	db 23,PIN_MISSILE
	db 25,SUPER_FANG
	db 29,BIDE
	db 31,TAKE_DOWN
	db 35,REST
	db 37,SUBSTITUTE
	db 41,EXTREMESPEED
	db 0

GalarZigzagoonEvolutions::
	db EV_LEVEL,20,LINOONE
	db 0

GalarZigzagoonPreviewPalette::
	RGB 23, 23, 23
	RGB 6, 6, 6
GalarZigzagoonShinyPalette::
	RGB 22, 12, 17
	RGB 11, 6, 9

; GalarLinoone: registered galar form. Header uses current project ABI.
GalarLinooneBaseStats::
	db DEX_LINOONE
	db 78
	db 70
	db 61
	db 100
	db 61
	db DARK
	db NORMAL
	db 90 ; stock catch rate
	db 147 ; stock base EXP
	INCBIN "pic/bmon/linoone_galar.pic",0,1 ; private sprite dimensions
	dw GalarLinoonePicFront
	dw GalarLinoonePicBack
	m_tutor 0
	m_tutor 0
	m_tutor 0
	m_tutor 0
	db 0 ; stock growth rate
	tmlearn 2,3,5,6,8
	tmlearn 9,10,11,12,13,14,15,16
	tmlearn 17,18,19,20,24
	tmlearn 25,28,30,31,32
	tmlearn 34,39,40
	tmlearn 44,45
	tmlearn 51,53,54
	db BANK(GalarLinoonePicFront)

GalarLinooneLevelMoves::
	db 1,TACKLE
	db 1,GROWL
	db 5,TAIL_WHIP
	db 7,SAND_ATTACK
	db 11,HEADBUTT
	db 12,BABYDOLLEYES
	db 13,BITE
	db 17,HYPER_VOICE
	db 19,PAY_DAY
	db 24,FURY_SWIPES
	db 27,SUPER_FANG
	db 32,SLASH
	db 35,DOUBLE_EDGE
	db 40,REST
	db 43,SUBSTITUTE
	db 48,EXTREMESPEED
	db 0

GalarLinooneEvolutions::
	db 0

GalarLinoonePreviewPalette::
	RGB 24, 24, 24
	RGB 7, 7, 7
GalarLinooneShinyPalette::
	RGB 23, 13, 18
	RGB 9, 6, 9

; GalarWeezing: registered galar form. Header uses current project ABI.
GalarWeezingBaseStats::
	db DEX_WEEZING
	db 65
	db 90
	db 120
	db 60
	db 85
	db POISON
	db FAIRY
	db 60 ; stock catch rate
	db 173 ; stock base EXP
	INCBIN "pic/bmon/weezing_galar.pic",0,1 ; private sprite dimensions
	dw GalarWeezingPicFront
	dw GalarWeezingPicBack
	m_tutor 5
	m_tutor 0
	m_tutor 0
	m_tutor 0
	db 0 ; stock growth rate
	tmlearn 6
	tmlearn 9,10,15
	tmlearn 24
	tmlearn 25,30,31,32
	tmlearn 34,37,38
	tmlearn 43,44,47
	tmlearn 50,54
	db BANK(GalarWeezingPicFront)

GalarWeezingLevelMoves::
	db 1,TACKLE
	db 1,POISON_GAS
	db 4,SMOG
	db 7,SMOKESCREEN
	db 12,ACID
	db 15,DOUBLE_TEAM
	db 18,SLUDGE
	db 23,TOXIC
	db 26,HAZE
	db 29,SELFDESTRUCT
	db 34,SLUDGE_BOMB
	db 40,SHADOW_BALL
	db 43,EGG_BOMB
	db 46,TAKE_DOWN
	db 51,GUNK_SHOT
	db 57,EXPLOSION
	db 0

GalarWeezingEvolutions::
	db 0

GalarWeezingPreviewPalette::
	RGB 23, 22, 21
	RGB 9, 10, 12
GalarWeezingShinyPalette::
	RGB 17, 22, 15
	RGB 8, 13, 9

; GalarSlowking: registered galar form. Header uses current project ABI.
GalarSlowkingBaseStats::
	db DEX_SLOWKING
	db 95
	db 65
	db 80
	db 30
	db 110
	db POISON
	db PSYCHIC
	db 70 ; stock catch rate
	db 164 ; stock base EXP
	INCBIN "pic/bmon/slowking_galar.pic",0,1 ; private sprite dimensions
	dw GalarSlowkingPicFront
	dw GalarSlowkingPicBack
	m_tutor 8
	m_tutor 11
	m_tutor 0
	m_tutor 0
	db 0 ; stock growth rate
	tmlearn 1,5,6,8
	tmlearn 9,10,11,12,13,14,15,16
	tmlearn 17,18,19
	tmlearn 26,27,28,29,30,31,32
	tmlearn 33,34,37,38,39,40
	tmlearn 41,43,44,45,46
	tmlearn 49,50,53,54,55
	db BANK(GalarSlowkingPicFront)

GalarSlowkingLevelMoves::
	db 1,SIGNAL_BEAM
	db 1,RECOVER
	db 1,POWER_GEM
	db 1,STOMP
	db 1,TACKLE
	db 5,GROWL
	db 9,WATER_GUN
	db 14,CONFUSION
	db 19,DISABLE
	db 23,HEADBUTT
	db 28,WATER_PULSE
	db 32,ZEN_HEADBUTT
	db 36,AMNESIA
	db 41,POWER_GEM
	db 45,PSYCHIC_M
	db 49,AQUA_TAIL
	db 54,HEX
	db 58,RECOVER
	db 0

GalarSlowkingEvolutions::
	db 0

GalarSlowkingPreviewPalette::
	RGB 22, 16, 21
	RGB 11, 7, 12
GalarSlowkingShinyPalette::
	RGB 16, 21, 24
	RGB 6, 12, 14

; PaldeaBlazeTauros: registered paldea_blaze form. Header uses current project ABI.
PaldeaBlazeTaurosBaseStats::
	db DEX_TAUROS
	db 75
	db 110
	db 105
	db 100
	db 70
	db FIGHTING
	db FIRE
	db 45 ; stock catch rate
	db 211 ; stock base EXP
	INCBIN "pic/bmon/tauros_paldea_blaze.pic",0,1 ; private sprite dimensions
	dw PaldeaBlazeTaurosPicFront
	dw PaldeaBlazeTaurosPicBack
	m_tutor 0
	m_tutor 0
	m_tutor 0
	m_tutor 0
	db 5 ; stock growth rate
	tmlearn 1,5,6,7,8
	tmlearn 9,10,11,13,14,15,16
	tmlearn 22,24
	tmlearn 25,26,27,30,31,32
	tmlearn 34,36,40
	tmlearn 44,45
	tmlearn 53,54
	db BANK(PaldeaBlazeTaurosPicFront)

PaldeaBlazeTaurosLevelMoves::
	db 1,TACKLE
	db 3,TAIL_WHIP
	db 5,RAGE
	db 8,HORN_ATTACK
	db 11,BIDE
	db 15,HEADBUTT
	db 19,REST
	db 24,STOMP
	db 29,FOCUS_ENERGY
	db 35,TAKE_DOWN
	db 41,ZEN_HEADBUTT
	db 48,SLAM
	db 55,THRASH
	db 63,DOUBLE_EDGE
	db 71,GIGA_IMPACT
	db 80,OUTRAGE
	db 0

PaldeaBlazeTaurosEvolutions::
	db 0

PaldeaBlazeTaurosPreviewPalette::
	RGB 23, 13, 10
	RGB 8, 7, 7
PaldeaBlazeTaurosShinyPalette::
	RGB 22, 22, 16
	RGB 10, 11, 7


SECTION "Regional Expansion Sprite Graphics", ROMX
HisuiGrowlithePicFront:: INCBIN "pic/bmon/growlithe_hisui.pic"
HisuiGrowlithePicBack::  INCBIN "pic/monback/growlithe_hisuib.pic"
HisuiArcaninePicFront:: INCBIN "pic/bmon/arcanine_hisui.pic"
HisuiArcaninePicBack::  INCBIN "pic/monback/arcanine_hisuib.pic"
HisuiVoltorbPicFront:: INCBIN "pic/bmon/voltorb_hisui.pic"
HisuiVoltorbPicBack::  INCBIN "pic/monback/voltorb_hisuib.pic"
HisuiElectrodePicFront:: INCBIN "pic/bmon/electrode_hisui.pic"
HisuiElectrodePicBack::  INCBIN "pic/monback/electrode_hisuib.pic"
GalarZigzagoonPicFront:: INCBIN "pic/bmon/zigzagoon_galar.pic"
GalarZigzagoonPicBack::  INCBIN "pic/monback/zigzagoon_galarb.pic"
GalarLinoonePicFront:: INCBIN "pic/bmon/linoone_galar.pic"
GalarLinoonePicBack::  INCBIN "pic/monback/linoone_galarb.pic"
GalarWeezingPicFront:: INCBIN "pic/bmon/weezing_galar.pic"
GalarWeezingPicBack::  INCBIN "pic/monback/weezing_galarb.pic"
GalarSlowkingPicFront:: INCBIN "pic/bmon/slowking_galar.pic"
GalarSlowkingPicBack::  INCBIN "pic/monback/slowking_galarb.pic"
PaldeaBlazeTaurosPicFront:: INCBIN "pic/bmon/tauros_paldea_blaze.pic"
PaldeaBlazeTaurosPicBack::  INCBIN "pic/monback/tauros_paldea_blazeb.pic"
