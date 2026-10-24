const_value = 0

; EVC-5.46.00: event annotations below follow the current active const order
; and the linked wEventFlags base. Commented-out consts consume no event bit.

	const EVENT_FOLLOWED_OAK_INTO_LAB                ; current 000, (D7CB, bit 0)
	const EVENT_001                                  ; current 001, (D7CB, bit 1)
	const EVENT_002                                  ; current 002, (D7CB, bit 2)
	const EVENT_HALL_OF_FAME_DEX_RATING              ; current 003, (D7CB, bit 3)
	const EVENT_004                                  ; current 004, (D7CB, bit 4)
	const EVENT_005                                  ; current 005, (D7CB, bit 5)
	const EVENT_PALLET_AFTER_GETTING_POKEBALLS       ; current 006, (D7CB, bit 6)
	const EVENT_007                                  ; current 007, (D7CB, bit 7)
	const EVENT_008                                  ; current 008, (D7CC, bit 0)
	const EVENT_009                                  ; current 009, (D7CC, bit 1)
	const EVENT_00A                                  ; current 00A, (D7CC, bit 2)
	const EVENT_00B                                  ; current 00B, (D7CC, bit 3)
	const EVENT_00C                                  ; current 00C, (D7CC, bit 4)
	const EVENT_00D                                  ; current 00D, (D7CC, bit 5)
	const EVENT_00E                                  ; current 00E, (D7CC, bit 6)
	const EVENT_00F                                  ; current 00F, (D7CC, bit 7)
	const EVENT_010                                  ; current 010, (D7CD, bit 0)
	const EVENT_011                                  ; current 011, (D7CD, bit 1)
	const EVENT_012                                  ; current 012, (D7CD, bit 2)
	const EVENT_013                                  ; current 013, (D7CD, bit 3)
	const EVENT_014                                  ; current 014, (D7CD, bit 4)
	const EVENT_015                                  ; current 015, (D7CD, bit 5)
	const EVENT_016                                  ; current 016, (D7CD, bit 6)
	const EVENT_017                                  ; current 017, (D7CD, bit 7)
	const EVENT_GOT_TOWN_MAP                         ; current 018, (D7CE, bit 0)
	const EVENT_ENTERED_BLUES_HOUSE                  ; current 019, (D7CE, bit 1)
	const EVENT_DAISY_WALKING                        ; current 01A, (D7CE, bit 2)
	const EVENT_01B                                  ; current 01B, (D7CE, bit 3)
	const EVENT_01C                                  ; current 01C, (D7CE, bit 4)
	const EVENT_01D                                  ; current 01D, (D7CE, bit 5)
	const EVENT_01E                                  ; current 01E, (D7CE, bit 6)
	const EVENT_01F                                  ; current 01F, (D7CE, bit 7)
	const EVENT_FOLLOWED_OAK_INTO_LAB_2              ; current 020, (D7CF, bit 0)
	const EVENT_OAK_ASKED_TO_CHOOSE_MON              ; current 021, (D7CF, bit 1)
	const EVENT_GOT_STARTER                          ; current 022, (D7CF, bit 2)
	const EVENT_BATTLED_RIVAL_IN_OAKS_LAB            ; current 023, (D7CF, bit 3)
	const EVENT_GOT_POKEBALLS_FROM_OAK               ; current 024, (D7CF, bit 4)
	const EVENT_GOT_POKEDEX                          ; current 025, (D7CF, bit 5)
	const EVENT_PALLET_AFTER_GETTING_POKEBALLS_2     ; current 026, (D7CF, bit 6)
	const EVENT_OAK_APPEARED_IN_PALLET               ; current 027, (D7CF, bit 7)
	const EVENT_VIRIDIAN_GYM_OPEN                    ; current 028, (D7D0, bit 0)
	const EVENT_GOT_TM42                             ; current 029, (D7D0, bit 1)
	const EVENT_02A                                  ; current 02A, (D7D0, bit 2)
	const EVENT_02B                                  ; current 02B, (D7D0, bit 3)
	const EVENT_02C                                  ; current 02C, (D7D0, bit 4)
	const EVENT_02D                                  ; current 02D, (D7D0, bit 5)
	const EVENT_02E                                  ; current 02E, (D7D0, bit 6)
	const EVENT_02F                                  ; current 02F, (D7D0, bit 7)
	;const EVENT_030                                  ; inactive legacy 030; no current event slot
	;const EVENT_031                                  ; inactive legacy 031; no current event slot
	;const EVENT_032                                  ; inactive legacy 032; no current event slot
	;const EVENT_033                                  ; inactive legacy 033; no current event slot
	;const EVENT_034                                  ; inactive legacy 034; no current event slot
	;const EVENT_035                                  ; inactive legacy 035; no current event slot
	;const EVENT_036                                  ; inactive legacy 036; no current event slot
	;const EVENT_037                                  ; inactive legacy 037; no current event slot
	const EVENT_OAK_GOT_PARCEL                       ; current 030, (D7D1, bit 0)
	const EVENT_GOT_OAKS_PARCEL                      ; current 031, (D7D1, bit 1)
	const EVENT_03A                                  ; current 032, (D7D1, bit 2)
	const EVENT_03B                                  ; current 033, (D7D1, bit 3)
	const EVENT_03C                                  ; current 034, (D7D1, bit 4)
	const EVENT_03D                                  ; current 035, (D7D1, bit 5)
	const EVENT_03E                                  ; current 036, (D7D1, bit 6)
	const EVENT_03F                                  ; current 037, (D7D1, bit 7)
	;const EVENT_040                                  ; inactive legacy 040; no current event slot
	;const EVENT_041                                  ; inactive legacy 041; no current event slot
	;const EVENT_042                                  ; inactive legacy 042; no current event slot
	;const EVENT_043                                  ; inactive legacy 043; no current event slot
	;const EVENT_044                                  ; inactive legacy 044; no current event slot
	;const EVENT_045                                  ; inactive legacy 045; no current event slot
	;const EVENT_046                                  ; inactive legacy 046; no current event slot
	;const EVENT_047                                  ; inactive legacy 047; no current event slot
	;const EVENT_048                                  ; inactive legacy 048; no current event slot
	;const EVENT_049                                  ; inactive legacy 049; no current event slot
	;const EVENT_04A                                  ; inactive legacy 04A; no current event slot
	;const EVENT_04B                                  ; inactive legacy 04B; no current event slot
	;const EVENT_04C                                  ; inactive legacy 04C; no current event slot
	;const EVENT_04D                                  ; inactive legacy 04D; no current event slot
	;const EVENT_04E                                  ; inactive legacy 04E; no current event slot
	;const EVENT_04F                                  ; inactive legacy 04F; no current event slot
	const EVENT_GOT_TM27                             ; current 038, (D7D2, bit 0)
	const EVENT_BEAT_VIRIDIAN_GYM_GIOVANNI           ; current 039, (D7D2, bit 1)
	const EVENT_BEAT_VIRIDIAN_GYM_TRAINER_0          ; current 03A, (D7D2, bit 2)
	const EVENT_BEAT_VIRIDIAN_GYM_TRAINER_1          ; current 03B, (D7D2, bit 3)
	const EVENT_BEAT_VIRIDIAN_GYM_TRAINER_2          ; current 03C, (D7D2, bit 4)
	const EVENT_BEAT_VIRIDIAN_GYM_TRAINER_3          ; current 03D, (D7D2, bit 5)
	const EVENT_BEAT_VIRIDIAN_GYM_TRAINER_4          ; current 03E, (D7D2, bit 6)
	const EVENT_BEAT_VIRIDIAN_GYM_TRAINER_5          ; current 03F, (D7D2, bit 7)
	const EVENT_BEAT_VIRIDIAN_GYM_TRAINER_6          ; current 040, (D7D3, bit 0)
	const EVENT_BEAT_VIRIDIAN_GYM_TRAINER_7          ; current 041, (D7D3, bit 1)
	const EVENT_05A                                  ; current 042, (D7D3, bit 2)
	const EVENT_05B                                  ; current 043, (D7D3, bit 3)
	const EVENT_05C                                  ; current 044, (D7D3, bit 4)
	const EVENT_05D                                  ; current 045, (D7D3, bit 5)
	const EVENT_05E                                  ; current 046, (D7D3, bit 6)
	const EVENT_05F                                  ; current 047, (D7D3, bit 7)
	;const EVENT_060                                  ; inactive legacy 060; no current event slot
	;const EVENT_061                                  ; inactive legacy 061; no current event slot
	;const EVENT_062                                  ; inactive legacy 062; no current event slot
	;const EVENT_063                                  ; inactive legacy 063; no current event slot
	;const EVENT_064                                  ; inactive legacy 064; no current event slot
	;const EVENT_065                                  ; inactive legacy 065; no current event slot
	;const EVENT_066                                  ; inactive legacy 066; no current event slot
	;const EVENT_067                                  ; inactive legacy 067; no current event slot
	const EVENT_BOUGHT_MUSEUM_TICKET                 ; current 048, (D7D4, bit 0)
	const EVENT_GOT_OLD_AMBER                        ; current 049, (D7D4, bit 1)
	const EVENT_06A                                  ; current 04A, (D7D4, bit 2)
	const EVENT_06B                                  ; current 04B, (D7D4, bit 3)
	const EVENT_06C                                  ; current 04C, (D7D4, bit 4)
	const EVENT_06D                                  ; current 04D, (D7D4, bit 5)
	const EVENT_06E                                  ; current 04E, (D7D4, bit 6)
	const EVENT_06F                                  ; current 04F, (D7D4, bit 7)
	const EVENT_070                                  ; current 050, (D7D5, bit 0)
	const EVENT_071                                  ; current 051, (D7D5, bit 1)
	const EVENT_BEAT_PEWTER_GYM_TRAINER_0            ; current 052, (D7D5, bit 2)
	const EVENT_073                                  ; current 053, (D7D5, bit 3)
	const EVENT_074                                  ; current 054, (D7D5, bit 4)
	const EVENT_075                                  ; current 055, (D7D5, bit 5)
	const EVENT_GOT_TM34                             ; current 056, (D7D5, bit 6)
	const EVENT_BEAT_BROCK                           ; current 057, (D7D5, bit 7)
	;const EVENT_078                                  ; inactive legacy 078; no current event slot
	;const EVENT_079                                  ; inactive legacy 079; no current event slot
	;const EVENT_07A                                  ; inactive legacy 07A; no current event slot
	;const EVENT_07B                                  ; inactive legacy 07B; no current event slot
	;const EVENT_07C                                  ; inactive legacy 07C; no current event slot
	;const EVENT_07D                                  ; inactive legacy 07D; no current event slot
	;const EVENT_07E                                  ; inactive legacy 07E; no current event slot
	;const EVENT_07F                                  ; inactive legacy 07F; no current event slot
	;const EVENT_080                                  ; inactive legacy 080; no current event slot
	;const EVENT_081                                  ; inactive legacy 081; no current event slot
	;const EVENT_082                                  ; inactive legacy 082; no current event slot
	;const EVENT_083                                  ; inactive legacy 083; no current event slot
	;const EVENT_084                                  ; inactive legacy 084; no current event slot
	;const EVENT_085                                  ; inactive legacy 085; no current event slot
	;const EVENT_086                                  ; inactive legacy 086; no current event slot
	;const EVENT_087                                  ; inactive legacy 087; no current event slot
	;const EVENT_088                                  ; inactive legacy 088; no current event slot
	;const EVENT_089                                  ; inactive legacy 089; no current event slot
	;const EVENT_08A                                  ; inactive legacy 08A; no current event slot
	;const EVENT_08B                                  ; inactive legacy 08B; no current event slot
	;const EVENT_08C                                  ; inactive legacy 08C; no current event slot
	;const EVENT_08D                                  ; inactive legacy 08D; no current event slot
	;const EVENT_08E                                  ; inactive legacy 08E; no current event slot
	;const EVENT_08F                                  ; inactive legacy 08F; no current event slot
	;const EVENT_090                                  ; inactive legacy 090; no current event slot
	;const EVENT_091                                  ; inactive legacy 091; no current event slot
	;const EVENT_092                                  ; inactive legacy 092; no current event slot
	;const EVENT_093                                  ; inactive legacy 093; no current event slot
	;const EVENT_094                                  ; inactive legacy 094; no current event slot
	;const EVENT_095                                  ; inactive legacy 095; no current event slot
	;const EVENT_096                                  ; inactive legacy 096; no current event slot
	;const EVENT_097                                  ; inactive legacy 097; no current event slot
	const EVENT_BEAT_CERULEAN_RIVAL                  ; current 058, (D7D6, bit 0)
	const EVENT_099                                  ; current 059, (D7D6, bit 1)
	const EVENT_09A                                  ; current 05A, (D7D6, bit 2)
	const EVENT_09B                                  ; current 05B, (D7D6, bit 3)
	const EVENT_09C                                  ; current 05C, (D7D6, bit 4)
	const EVENT_09D                                  ; current 05D, (D7D6, bit 5)
	const EVENT_09E                                  ; current 05E, (D7D6, bit 6)
	const EVENT_09F                                  ; current 05F, (D7D6, bit 7)
	const EVENT_0A0                                  ; current 060, (D7D7, bit 0)
	const EVENT_0A1                                  ; current 061, (D7D7, bit 1)
	const EVENT_0A2                                  ; current 062, (D7D7, bit 2)
	const EVENT_0A3                                  ; current 063, (D7D7, bit 3)
	const EVENT_0A4                                  ; current 064, (D7D7, bit 4)
	const EVENT_0A5                                  ; current 065, (D7D7, bit 5)
	const EVENT_0A6                                  ; current 066, (D7D7, bit 6)
	const EVENT_BEAT_CERULEAN_ROCKET_THIEF           ; current 067, (D7D7, bit 7)
	;const EVENT_0A8                                  ; inactive legacy 0A8; no current event slot
	;const EVENT_0A9                                  ; inactive legacy 0A9; no current event slot
	;const EVENT_0AA                                  ; inactive legacy 0AA; no current event slot
	;const EVENT_0AB                                  ; inactive legacy 0AB; no current event slot
	;const EVENT_0AC                                  ; inactive legacy 0AC; no current event slot
	;const EVENT_0AD                                  ; inactive legacy 0AD; no current event slot
	;const EVENT_0AE                                  ; inactive legacy 0AE; no current event slot
	;const EVENT_0AF                                  ; inactive legacy 0AF; no current event slot
	;const EVENT_0B0                                  ; inactive legacy 0B0; no current event slot
	;const EVENT_0B1                                  ; inactive legacy 0B1; no current event slot
	;const EVENT_0B2                                  ; inactive legacy 0B2; no current event slot
	;const EVENT_0B3                                  ; inactive legacy 0B3; no current event slot
	;const EVENT_0B4                                  ; inactive legacy 0B4; no current event slot
	;const EVENT_0B5                                  ; inactive legacy 0B5; no current event slot
	;const EVENT_0B6                                  ; inactive legacy 0B6; no current event slot
	;const EVENT_0B7                                  ; inactive legacy 0B7; no current event slot
	const EVENT_0B8                                  ; current 068, (D7D8, bit 0)
	const EVENT_0B9                                  ; current 069, (D7D8, bit 1)
	const EVENT_BEAT_CERULEAN_GYM_TRAINER_0          ; current 06A, (D7D8, bit 2)
	const EVENT_BEAT_CERULEAN_GYM_TRAINER_1          ; current 06B, (D7D8, bit 3)
	const EVENT_0BC                                  ; current 06C, (D7D8, bit 4)
	const EVENT_0BD                                  ; current 06D, (D7D8, bit 5)
	const EVENT_GOT_TM11                             ; current 06E, (D7D8, bit 6)
	const EVENT_BEAT_MISTY                           ; current 06F, (D7D8, bit 7)
	const EVENT_GOT_BICYCLE                          ; current 070, (D7D9, bit 0)
	const EVENT_0C1                                  ; current 071, (D7D9, bit 1)
	const EVENT_0C2                                  ; current 072, (D7D9, bit 2)
	const EVENT_0C3                                  ; current 073, (D7D9, bit 3)
	const EVENT_0C4                                  ; current 074, (D7D9, bit 4)
	const EVENT_0C5                                  ; current 075, (D7D9, bit 5)
	const EVENT_0C6                                  ; current 076, (D7D9, bit 6)
	const EVENT_0C7                                  ; current 077, (D7D9, bit 7)
	;const EVENT_0C8                                  ; inactive legacy 0C8; no current event slot
	;const EVENT_0C9                                  ; inactive legacy 0C9; no current event slot
	;const EVENT_0CA                                  ; inactive legacy 0CA; no current event slot
	;const EVENT_0CB                                  ; inactive legacy 0CB; no current event slot
	;const EVENT_0CC                                  ; inactive legacy 0CC; no current event slot
	;const EVENT_0CD                                  ; inactive legacy 0CD; no current event slot
	;const EVENT_0CE                                  ; inactive legacy 0CE; no current event slot
	;const EVENT_0CF                                  ; inactive legacy 0CF; no current event slot
	;const EVENT_0D0                                  ; inactive legacy 0D0; no current event slot
	;const EVENT_0D1                                  ; inactive legacy 0D1; no current event slot
	;const EVENT_0D2                                  ; inactive legacy 0D2; no current event slot
	;const EVENT_0D3                                  ; inactive legacy 0D3; no current event slot
	;const EVENT_0D4                                  ; inactive legacy 0D4; no current event slot
	;const EVENT_0D5                                  ; inactive legacy 0D5; no current event slot
	;const EVENT_0D6                                  ; inactive legacy 0D6; no current event slot
	;const EVENT_0D7                                  ; inactive legacy 0D7; no current event slot
	;const EVENT_0D8                                  ; inactive legacy 0D8; no current event slot
	;const EVENT_0D9                                  ; inactive legacy 0D9; no current event slot
	;const EVENT_0DA                                  ; inactive legacy 0DA; no current event slot
	;const EVENT_0DB                                  ; inactive legacy 0DB; no current event slot
	;const EVENT_0DC                                  ; inactive legacy 0DC; no current event slot
	;const EVENT_0DD                                  ; inactive legacy 0DD; no current event slot
	;const EVENT_0DE                                  ; inactive legacy 0DE; no current event slot
	;const EVENT_0DF                                  ; inactive legacy 0DF; no current event slot
	;const EVENT_0E0                                  ; inactive legacy 0E0; no current event slot
	;const EVENT_0E1                                  ; inactive legacy 0E1; no current event slot
	;const EVENT_0E2                                  ; inactive legacy 0E2; no current event slot
	;const EVENT_0E3                                  ; inactive legacy 0E3; no current event slot
	;const EVENT_0E4                                  ; inactive legacy 0E4; no current event slot
	;const EVENT_0E5                                  ; inactive legacy 0E5; no current event slot
	;const EVENT_0E6                                  ; inactive legacy 0E6; no current event slot
	;const EVENT_0E7                                  ; inactive legacy 0E7; no current event slot
	const EVENT_0E8                                  ; current 078, (D7DA, bit 0)
	const EVENT_0E9                                  ; current 079, (D7DA, bit 1)
	const EVENT_0EA                                  ; current 07A, (D7DA, bit 2)
	const EVENT_0EB                                  ; current 07B, (D7DA, bit 3)
	const EVENT_0EC                                  ; current 07C, (D7DA, bit 4)
	const EVENT_0ED                                  ; current 07D, (D7DA, bit 5)
	const EVENT_POKEMON_TOWER_RIVAL_ON_LEFT          ; current 07E, (D7DA, bit 6)
	const EVENT_BEAT_POKEMON_TOWER_RIVAL             ; current 07F, (D7DA, bit 7)
	const EVENT_0F0                                  ; current 080, (D7DB, bit 0)
	const EVENT_BEAT_POKEMONTOWER_3_TRAINER_0        ; current 081, (D7DB, bit 1)
	const EVENT_BEAT_POKEMONTOWER_3_TRAINER_1        ; current 082, (D7DB, bit 2)
	const EVENT_BEAT_POKEMONTOWER_3_TRAINER_2        ; current 083, (D7DB, bit 3)
	const EVENT_0F4                                  ; current 084, (D7DB, bit 4)
	const EVENT_0F5                                  ; current 085, (D7DB, bit 5)
	const EVENT_0F6                                  ; current 086, (D7DB, bit 6)
	const EVENT_0F7                                  ; current 087, (D7DB, bit 7)
	const EVENT_0F8                                  ; current 088, (D7DC, bit 0)
	const EVENT_BEAT_POKEMONTOWER_4_TRAINER_0        ; current 089, (D7DC, bit 1)
	const EVENT_BEAT_POKEMONTOWER_4_TRAINER_1        ; current 08A, (D7DC, bit 2)
	const EVENT_BEAT_POKEMONTOWER_4_TRAINER_2        ; current 08B, (D7DC, bit 3)
	const EVENT_0FC                                  ; current 08C, (D7DC, bit 4)
	const EVENT_0FD                                  ; current 08D, (D7DC, bit 5)
	const EVENT_0FE                                  ; current 08E, (D7DC, bit 6)
	const EVENT_0FF                                  ; current 08F, (D7DC, bit 7)
	const EVENT_100                                  ; current 090, (D7DD, bit 0)
	const EVENT_101                                  ; current 091, (D7DD, bit 1)
	const EVENT_BEAT_POKEMONTOWER_5_TRAINER_0        ; current 092, (D7DD, bit 2)
	const EVENT_BEAT_POKEMONTOWER_5_TRAINER_1        ; current 093, (D7DD, bit 3)
	const EVENT_BEAT_POKEMONTOWER_5_TRAINER_2        ; current 094, (D7DD, bit 4)
	const EVENT_BEAT_POKEMONTOWER_5_TRAINER_3        ; current 095, (D7DD, bit 5)
	const EVENT_106                                  ; current 096, (D7DD, bit 6)
	const EVENT_IN_PURIFIED_ZONE                     ; current 097, (D7DD, bit 7)
	const EVENT_108                                  ; current 098, (D7DE, bit 0)
	const EVENT_BEAT_POKEMONTOWER_6_TRAINER_0        ; current 099, (D7DE, bit 1)
	const EVENT_BEAT_POKEMONTOWER_6_TRAINER_1        ; current 09A, (D7DE, bit 2)
	const EVENT_BEAT_POKEMONTOWER_6_TRAINER_2        ; current 09B, (D7DE, bit 3)
	const EVENT_10C                                  ; current 09C, (D7DE, bit 4)
	const EVENT_10D                                  ; current 09D, (D7DE, bit 5)
	const EVENT_10E                                  ; current 09E, (D7DE, bit 6)
	const EVENT_BEAT_GHOST_MAROWAK                   ; current 09F, (D7DE, bit 7)
	const EVENT_110                                  ; current 0A0, (D7DF, bit 0)
	const EVENT_BEAT_POKEMONTOWER_7_TRAINER_0        ; current 0A1, (D7DF, bit 1)
	const EVENT_BEAT_POKEMONTOWER_7_TRAINER_1        ; current 0A2, (D7DF, bit 2)
	const EVENT_BEAT_POKEMONTOWER_7_TRAINER_2        ; current 0A3, (D7DF, bit 3)
	const EVENT_114                                  ; current 0A4, (D7DF, bit 4)
	const EVENT_115                                  ; current 0A5, (D7DF, bit 5)
	const EVENT_116                                  ; current 0A6, (D7DF, bit 6)
	const EVENT_RESCUED_MR_FUJI_2                    ; current 0A7, (D7DF, bit 7)
	;const EVENT_118                                  ; inactive legacy 118; no current event slot
	;const EVENT_119                                  ; inactive legacy 119; no current event slot
	;const EVENT_11A                                  ; inactive legacy 11A; no current event slot
	;const EVENT_11B                                  ; inactive legacy 11B; no current event slot
	;const EVENT_11C                                  ; inactive legacy 11C; no current event slot
	;const EVENT_11D                                  ; inactive legacy 11D; no current event slot
	;const EVENT_11E                                  ; inactive legacy 11E; no current event slot
	;const EVENT_11F                                  ; inactive legacy 11F; no current event slot
	;const EVENT_120                                  ; inactive legacy 120; no current event slot
	;const EVENT_121                                  ; inactive legacy 121; no current event slot
	;const EVENT_122                                  ; inactive legacy 122; no current event slot
	;const EVENT_123                                  ; inactive legacy 123; no current event slot
	;const EVENT_124                                  ; inactive legacy 124; no current event slot
	;const EVENT_125                                  ; inactive legacy 125; no current event slot
	;const EVENT_126                                  ; inactive legacy 126; no current event slot
	;const EVENT_127                                  ; inactive legacy 127; no current event slot
	const EVENT_GOT_POKE_FLUTE                       ; current 0A8, (D7E0, bit 0)
	const EVENT_129                                  ; current 0A9, (D7E0, bit 1)
	const EVENT_12A                                  ; current 0AA, (D7E0, bit 2)
	const EVENT_12B                                  ; current 0AB, (D7E0, bit 3)
	const EVENT_12C                                  ; current 0AC, (D7E0, bit 4)
	const EVENT_12D                                  ; current 0AD, (D7E0, bit 5)
	const EVENT_12E                                  ; current 0AE, (D7E0, bit 6)
	const EVENT_12F                                  ; current 0AF, (D7E0, bit 7)
	;const EVENT_130                                  ; inactive legacy 130; no current event slot
	;const EVENT_131                                  ; inactive legacy 131; no current event slot
	;const EVENT_132                                  ; inactive legacy 132; no current event slot
	;const EVENT_133                                  ; inactive legacy 133; no current event slot
	;const EVENT_134                                  ; inactive legacy 134; no current event slot
	;const EVENT_135                                  ; inactive legacy 135; no current event slot
	;const EVENT_136                                  ; inactive legacy 136; no current event slot
	;const EVENT_137                                  ; inactive legacy 137; no current event slot
	;const EVENT_138                                  ; inactive legacy 138; no current event slot
	;const EVENT_139                                  ; inactive legacy 139; no current event slot
	;const EVENT_13A                                  ; inactive legacy 13A; no current event slot
	;const EVENT_13B                                  ; inactive legacy 13B; no current event slot
	;const EVENT_13C                                  ; inactive legacy 13C; no current event slot
	;const EVENT_13D                                  ; inactive legacy 13D; no current event slot
	;const EVENT_13E                                  ; inactive legacy 13E; no current event slot
	;const EVENT_13F                                  ; inactive legacy 13F; no current event slot
	;const EVENT_140                                  ; inactive legacy 140; no current event slot
	;const EVENT_141                                  ; inactive legacy 141; no current event slot
	;const EVENT_142                                  ; inactive legacy 142; no current event slot
	;const EVENT_143                                  ; inactive legacy 143; no current event slot
	;const EVENT_144                                  ; inactive legacy 144; no current event slot
	;const EVENT_145                                  ; inactive legacy 145; no current event slot
	;const EVENT_146                                  ; inactive legacy 146; no current event slot
	;const EVENT_147                                  ; inactive legacy 147; no current event slot
	;const EVENT_148                                  ; inactive legacy 148; no current event slot
	;const EVENT_149                                  ; inactive legacy 149; no current event slot
	;const EVENT_14A                                  ; inactive legacy 14A; no current event slot
	;const EVENT_14B                                  ; inactive legacy 14B; no current event slot
	;const EVENT_14C                                  ; inactive legacy 14C; no current event slot
	;const EVENT_14D                                  ; inactive legacy 14D; no current event slot
	;const EVENT_14E                                  ; inactive legacy 14E; no current event slot
	;const EVENT_14F                                  ; inactive legacy 14F; no current event slot
	const EVENT_150                                  ; current 0B0, (D7E1, bit 0)
	const EVENT_GOT_BIKE_VOUCHER                     ; current 0B1, (D7E1, bit 1)
	const EVENT_152                                  ; current 0B2, (D7E1, bit 2)
	const EVENT_153                                  ; current 0B3, (D7E1, bit 3)
	const EVENT_154                                  ; current 0B4, (D7E1, bit 4)
	const EVENT_155                                  ; current 0B5, (D7E1, bit 5)
	const EVENT_SEEL_FAN_BOAST                       ; current 0B6, (D7E1, bit 6)
	const EVENT_PIKACHU_FAN_BOAST                    ; current 0B7, (D7E1, bit 7)
	;const EVENT_158                                  ; inactive legacy 158; no current event slot
	;const EVENT_159                                  ; inactive legacy 159; no current event slot
	;const EVENT_15A                                  ; inactive legacy 15A; no current event slot
	;const EVENT_15B                                  ; inactive legacy 15B; no current event slot
	;const EVENT_15C                                  ; inactive legacy 15C; no current event slot
	;const EVENT_15D                                  ; inactive legacy 15D; no current event slot
	;const EVENT_15E                                  ; inactive legacy 15E; no current event slot
	;const EVENT_15F                                  ; inactive legacy 15F; no current event slot
	const EVENT_2ND_LOCK_OPENED                      ; current 0B8, (D7E2, bit 0)
	const EVENT_1ST_LOCK_OPENED                      ; current 0B9, (D7E2, bit 1)
	const EVENT_BEAT_VERMILION_GYM_TRAINER_0         ; current 0BA, (D7E2, bit 2)
	const EVENT_BEAT_VERMILION_GYM_TRAINER_1         ; current 0BB, (D7E2, bit 3)
	const EVENT_BEAT_VERMILION_GYM_TRAINER_2         ; current 0BC, (D7E2, bit 4)
	const EVENT_165                                  ; current 0BD, (D7E2, bit 5)
	const EVENT_GOT_TM24                             ; current 0BE, (D7E2, bit 6)
	const EVENT_BEAT_LT_SURGE                        ; current 0BF, (D7E2, bit 7)
	;const EVENT_168                                  ; inactive legacy 168; no current event slot
	;const EVENT_169                                  ; inactive legacy 169; no current event slot
	;const EVENT_16A                                  ; inactive legacy 16A; no current event slot
	;const EVENT_16B                                  ; inactive legacy 16B; no current event slot
	;const EVENT_16C                                  ; inactive legacy 16C; no current event slot
	;const EVENT_16D                                  ; inactive legacy 16D; no current event slot
	;const EVENT_16E                                  ; inactive legacy 16E; no current event slot
	;const EVENT_16F                                  ; inactive legacy 16F; no current event slot
	;const EVENT_170                                  ; inactive legacy 170; no current event slot
	;const EVENT_171                                  ; inactive legacy 171; no current event slot
	;const EVENT_172                                  ; inactive legacy 172; no current event slot
	;const EVENT_173                                  ; inactive legacy 173; no current event slot
	;const EVENT_174                                  ; inactive legacy 174; no current event slot
	;const EVENT_175                                  ; inactive legacy 175; no current event slot
	;const EVENT_176                                  ; inactive legacy 176; no current event slot
	;const EVENT_177                                  ; inactive legacy 177; no current event slot
	;const EVENT_178                                  ; inactive legacy 178; no current event slot
	;const EVENT_179                                  ; inactive legacy 179; no current event slot
	;const EVENT_17A                                  ; inactive legacy 17A; no current event slot
	;const EVENT_17B                                  ; inactive legacy 17B; no current event slot
	;const EVENT_17C                                  ; inactive legacy 17C; no current event slot
	;const EVENT_17D                                  ; inactive legacy 17D; no current event slot
	;const EVENT_17E                                  ; inactive legacy 17E; no current event slot
	;const EVENT_17F                                  ; inactive legacy 17F; no current event slot
	const EVENT_GOT_TM41                             ; current 0C0, (D7E3, bit 0)
	const EVENT_181                                  ; current 0C1, (D7E3, bit 1)
	const EVENT_182                                  ; current 0C2, (D7E3, bit 2)
	const EVENT_183                                  ; current 0C3, (D7E3, bit 3)
	const EVENT_184                                  ; current 0C4, (D7E3, bit 4)
	const EVENT_185                                  ; current 0C5, (D7E3, bit 5)
	const EVENT_186                                  ; current 0C6, (D7E3, bit 6)
	const EVENT_187                                  ; current 0C7, (D7E3, bit 7)
	const EVENT_188                                  ; current 0C8, (D7E4, bit 0)
	const EVENT_189                                  ; current 0C9, (D7E4, bit 1)
	const EVENT_18A                                  ; current 0CA, (D7E4, bit 2)
	const EVENT_18B                                  ; current 0CB, (D7E4, bit 3)
	const EVENT_GOT_TM13                             ; current 0CC, (D7E4, bit 4)
	const EVENT_GOT_TM48                             ; current 0CD, (D7E4, bit 5)
	const EVENT_GOT_TM49                             ; current 0CE, (D7E4, bit 6)
	const EVENT_GOT_TM18                             ; current 0CF, (D7E4, bit 7)
	;const EVENT_190                                  ; inactive legacy 190; no current event slot
	;const EVENT_191                                  ; inactive legacy 191; no current event slot
	;const EVENT_192                                  ; inactive legacy 192; no current event slot
	;const EVENT_193                                  ; inactive legacy 193; no current event slot
	;const EVENT_194                                  ; inactive legacy 194; no current event slot
	;const EVENT_195                                  ; inactive legacy 195; no current event slot
	;const EVENT_196                                  ; inactive legacy 196; no current event slot
	;const EVENT_197                                  ; inactive legacy 197; no current event slot
	;const EVENT_198                                  ; inactive legacy 198; no current event slot
	;const EVENT_199                                  ; inactive legacy 199; no current event slot
	;const EVENT_19A                                  ; inactive legacy 19A; no current event slot
	;const EVENT_19B                                  ; inactive legacy 19B; no current event slot
	;const EVENT_19C                                  ; inactive legacy 19C; no current event slot
	;const EVENT_19D                                  ; inactive legacy 19D; no current event slot
	;const EVENT_19E                                  ; inactive legacy 19E; no current event slot
	;const EVENT_19F                                  ; inactive legacy 19F; no current event slot
	;const EVENT_1A0                                  ; inactive legacy 1A0; no current event slot
	;const EVENT_1A1                                  ; inactive legacy 1A1; no current event slot
	;const EVENT_1A2                                  ; inactive legacy 1A2; no current event slot
	;const EVENT_1A3                                  ; inactive legacy 1A3; no current event slot
	;const EVENT_1A4                                  ; inactive legacy 1A4; no current event slot
	;const EVENT_1A5                                  ; inactive legacy 1A5; no current event slot
	;const EVENT_1A6                                  ; inactive legacy 1A6; no current event slot
	;const EVENT_1A7                                  ; inactive legacy 1A7; no current event slot
	const EVENT_GOT_TM21                             ; current 0D0, (D7E5, bit 0)
	const EVENT_BEAT_ERIKA                           ; current 0D1, (D7E5, bit 1)
	const EVENT_BEAT_CELADON_GYM_TRAINER_0           ; current 0D2, (D7E5, bit 2)
	const EVENT_BEAT_CELADON_GYM_TRAINER_1           ; current 0D3, (D7E5, bit 3)
	const EVENT_BEAT_CELADON_GYM_TRAINER_2           ; current 0D4, (D7E5, bit 4)
	const EVENT_BEAT_CELADON_GYM_TRAINER_3           ; current 0D5, (D7E5, bit 5)
	const EVENT_BEAT_CELADON_GYM_TRAINER_4           ; current 0D6, (D7E5, bit 6)
	const EVENT_BEAT_CELADON_GYM_TRAINER_5           ; current 0D7, (D7E5, bit 7)
	const EVENT_BEAT_CELADON_GYM_TRAINER_6           ; current 0D8, (D7E6, bit 0)
	const EVENT_1B1                                  ; current 0D9, (D7E6, bit 1)
	const EVENT_1B2                                  ; current 0DA, (D7E6, bit 2)
	const EVENT_1B3                                  ; current 0DB, (D7E6, bit 3)
	const EVENT_1B4                                  ; current 0DC, (D7E6, bit 4)
	const EVENT_1B5                                  ; current 0DD, (D7E6, bit 5)
	const EVENT_1B6                                  ; current 0DE, (D7E6, bit 6)
	const EVENT_1B7                                  ; current 0DF, (D7E6, bit 7)
	const EVENT_1B8                                  ; current 0E0, (D7E7, bit 0)
	const EVENT_FOUND_ROCKET_HIDEOUT                 ; current 0E1, (D7E7, bit 1)
	const EVENT_GOT_10_COINS                         ; current 0E2, (D7E7, bit 2)
	const EVENT_GOT_20_COINS                         ; current 0E3, (D7E7, bit 3)
	const EVENT_GOT_20_COINS_2                       ; current 0E4, (D7E7, bit 4)
	const EVENT_1BD                                  ; current 0E5, (D7E7, bit 5)
	const EVENT_1BE                                  ; current 0E6, (D7E7, bit 6)
	const EVENT_1BF                                  ; current 0E7, (D7E7, bit 7)
	;const EVENT_1C0                                  ; inactive legacy 1C0; no current event slot
	;const EVENT_1C1                                  ; inactive legacy 1C1; no current event slot
	;const EVENT_1C2                                  ; inactive legacy 1C2; no current event slot
	;const EVENT_1C3                                  ; inactive legacy 1C3; no current event slot
	;const EVENT_1C4                                  ; inactive legacy 1C4; no current event slot
	;const EVENT_1C5                                  ; inactive legacy 1C5; no current event slot
	;const EVENT_1C6                                  ; inactive legacy 1C6; no current event slot
	;const EVENT_1C7                                  ; inactive legacy 1C7; no current event slot
	;const EVENT_1C8                                  ; inactive legacy 1C8; no current event slot
	;const EVENT_1C9                                  ; inactive legacy 1C9; no current event slot
	;const EVENT_1CA                                  ; inactive legacy 1CA; no current event slot
	;const EVENT_1CB                                  ; inactive legacy 1CB; no current event slot
	;const EVENT_1CC                                  ; inactive legacy 1CC; no current event slot
	;const EVENT_1CD                                  ; inactive legacy 1CD; no current event slot
	;const EVENT_1CE                                  ; inactive legacy 1CE; no current event slot
	;const EVENT_1CF                                  ; inactive legacy 1CF; no current event slot
	;const EVENT_1D0                                  ; inactive legacy 1D0; no current event slot
	;const EVENT_1D1                                  ; inactive legacy 1D1; no current event slot
	;const EVENT_1D2                                  ; inactive legacy 1D2; no current event slot
	;const EVENT_1D3                                  ; inactive legacy 1D3; no current event slot
	;const EVENT_1D4                                  ; inactive legacy 1D4; no current event slot
	;const EVENT_1D5                                  ; inactive legacy 1D5; no current event slot
	;const EVENT_1D6                                  ; inactive legacy 1D6; no current event slot
	;const EVENT_1D7                                  ; inactive legacy 1D7; no current event slot
	;const EVENT_1D8                                  ; inactive legacy 1D8; no current event slot
	;const EVENT_1D9                                  ; inactive legacy 1D9; no current event slot
	;const EVENT_1DA                                  ; inactive legacy 1DA; no current event slot
	;const EVENT_1DB                                  ; inactive legacy 1DB; no current event slot
	;const EVENT_1DC                                  ; inactive legacy 1DC; no current event slot
	;const EVENT_1DD                                  ; inactive legacy 1DD; no current event slot
	;const EVENT_1DE                                  ; inactive legacy 1DE; no current event slot
	;const EVENT_1DF                                  ; inactive legacy 1DF; no current event slot
	const EVENT_GOT_COIN_CASE                        ; current 0E8, (D7E8, bit 0)
	const EVENT_1E1                                  ; current 0E9, (D7E8, bit 1)
	const EVENT_1E2                                  ; current 0EA, (D7E8, bit 2)
	const EVENT_1E3                                  ; current 0EB, (D7E8, bit 3)
	const EVENT_1E4                                  ; current 0EC, (D7E8, bit 4)
	const EVENT_1E5                                  ; current 0ED, (D7E8, bit 5)
	const EVENT_1E6                                  ; current 0EE, (D7E8, bit 6)
	const EVENT_1E7                                  ; current 0EF, (D7E8, bit 7)
	;const EVENT_1E8                                  ; inactive legacy 1E8; no current event slot
	;const EVENT_1E9                                  ; inactive legacy 1E9; no current event slot
	;const EVENT_1EA                                  ; inactive legacy 1EA; no current event slot
	;const EVENT_1EB                                  ; inactive legacy 1EB; no current event slot
	;const EVENT_1EC                                  ; inactive legacy 1EC; no current event slot
	;const EVENT_1ED                                  ; inactive legacy 1ED; no current event slot
	;const EVENT_1EE                                  ; inactive legacy 1EE; no current event slot
	;const EVENT_1EF                                  ; inactive legacy 1EF; no current event slot
	;const EVENT_1F0                                  ; inactive legacy 1F0; no current event slot
	;const EVENT_1F1                                  ; inactive legacy 1F1; no current event slot
	;const EVENT_1F2                                  ; inactive legacy 1F2; no current event slot
	;const EVENT_1F3                                  ; inactive legacy 1F3; no current event slot
	;const EVENT_1F4                                  ; inactive legacy 1F4; no current event slot
	;const EVENT_1F5                                  ; inactive legacy 1F5; no current event slot
	;const EVENT_1F6                                  ; inactive legacy 1F6; no current event slot
	;const EVENT_1F7                                  ; inactive legacy 1F7; no current event slot
	;const EVENT_1F8                                  ; inactive legacy 1F8; no current event slot
	;const EVENT_1F9                                  ; inactive legacy 1F9; no current event slot
	;const EVENT_1FA                                  ; inactive legacy 1FA; no current event slot
	;const EVENT_1FB                                  ; inactive legacy 1FB; no current event slot
	;const EVENT_1FC                                  ; inactive legacy 1FC; no current event slot
	;const EVENT_1FD                                  ; inactive legacy 1FD; no current event slot
	;const EVENT_1FE                                  ; inactive legacy 1FE; no current event slot
	;const EVENT_1FF                                  ; inactive legacy 1FF; no current event slot
	;const EVENT_200                                  ; inactive legacy 200; no current event slot
	;const EVENT_201                                  ; inactive legacy 201; no current event slot
	;const EVENT_202                                  ; inactive legacy 202; no current event slot
	;const EVENT_203                                  ; inactive legacy 203; no current event slot
	;const EVENT_204                                  ; inactive legacy 204; no current event slot
	;const EVENT_205                                  ; inactive legacy 205; no current event slot
	;const EVENT_206                                  ; inactive legacy 206; no current event slot
	;const EVENT_207                                  ; inactive legacy 207; no current event slot
	;const EVENT_208                                  ; inactive legacy 208; no current event slot
	;const EVENT_209                                  ; inactive legacy 209; no current event slot
	;const EVENT_20A                                  ; inactive legacy 20A; no current event slot
	;const EVENT_20B                                  ; inactive legacy 20B; no current event slot
	;const EVENT_20C                                  ; inactive legacy 20C; no current event slot
	;const EVENT_20D                                  ; inactive legacy 20D; no current event slot
	;const EVENT_20E                                  ; inactive legacy 20E; no current event slot
	;const EVENT_20F                                  ; inactive legacy 20F; no current event slot
	;const EVENT_210                                  ; inactive legacy 210; no current event slot
	;const EVENT_211                                  ; inactive legacy 211; no current event slot
	;const EVENT_212                                  ; inactive legacy 212; no current event slot
	;const EVENT_213                                  ; inactive legacy 213; no current event slot
	;const EVENT_214                                  ; inactive legacy 214; no current event slot
	;const EVENT_215                                  ; inactive legacy 215; no current event slot
	;const EVENT_216                                  ; inactive legacy 216; no current event slot
	;const EVENT_217                                  ; inactive legacy 217; no current event slot
	;const EVENT_218                                  ; inactive legacy 218; no current event slot
	;const EVENT_219                                  ; inactive legacy 219; no current event slot
	;const EVENT_21A                                  ; inactive legacy 21A; no current event slot
	;const EVENT_21B                                  ; inactive legacy 21B; no current event slot
	;const EVENT_21C                                  ; inactive legacy 21C; no current event slot
	;const EVENT_21D                                  ; inactive legacy 21D; no current event slot
	;const EVENT_21E                                  ; inactive legacy 21E; no current event slot
	;const EVENT_21F                                  ; inactive legacy 21F; no current event slot
	;const EVENT_220                                  ; inactive legacy 220; no current event slot
	;const EVENT_221                                  ; inactive legacy 221; no current event slot
	;const EVENT_222                                  ; inactive legacy 222; no current event slot
	;const EVENT_223                                  ; inactive legacy 223; no current event slot
	;const EVENT_224                                  ; inactive legacy 224; no current event slot
	;const EVENT_225                                  ; inactive legacy 225; no current event slot
	;const EVENT_226                                  ; inactive legacy 226; no current event slot
	;const EVENT_227                                  ; inactive legacy 227; no current event slot
	;const EVENT_228                                  ; inactive legacy 228; no current event slot
	;const EVENT_229                                  ; inactive legacy 229; no current event slot
	;const EVENT_22A                                  ; inactive legacy 22A; no current event slot
	;const EVENT_22B                                  ; inactive legacy 22B; no current event slot
	;const EVENT_22C                                  ; inactive legacy 22C; no current event slot
	;const EVENT_22D                                  ; inactive legacy 22D; no current event slot
	;const EVENT_22E                                  ; inactive legacy 22E; no current event slot
	;const EVENT_22F                                  ; inactive legacy 22F; no current event slot
	;const EVENT_230                                  ; inactive legacy 230; no current event slot
	;const EVENT_231                                  ; inactive legacy 231; no current event slot
	;const EVENT_232                                  ; inactive legacy 232; no current event slot
	;const EVENT_233                                  ; inactive legacy 233; no current event slot
	;const EVENT_234                                  ; inactive legacy 234; no current event slot
	;const EVENT_235                                  ; inactive legacy 235; no current event slot
	;const EVENT_236                                  ; inactive legacy 236; no current event slot
	;const EVENT_237                                  ; inactive legacy 237; no current event slot
	const EVENT_GOT_HM04                             ; current 0F0, (D7E9, bit 0)
	const EVENT_GAVE_GOLD_TEETH                      ; current 0F1, (D7E9, bit 1) ; HM4-5.38.00: legacy/reserved, keep event numbering stable
	const EVENT_23A                                  ; current 0F2, (D7E9, bit 2)
	const EVENT_23B                                  ; current 0F3, (D7E9, bit 3)
	const EVENT_23C                                  ; current 0F4, (D7E9, bit 4)
	const EVENT_23D                                  ; current 0F5, (D7E9, bit 5)
	const EVENT_23E                                  ; current 0F6, (D7E9, bit 6)
	const EVENT_23F                                  ; current 0F7, (D7E9, bit 7)
	;const EVENT_240                                  ; inactive legacy 240; no current event slot
	;const EVENT_241                                  ; inactive legacy 241; no current event slot
	;const EVENT_242                                  ; inactive legacy 242; no current event slot
	;const EVENT_243                                  ; inactive legacy 243; no current event slot
	;const EVENT_244                                  ; inactive legacy 244; no current event slot
	;const EVENT_245                                  ; inactive legacy 245; no current event slot
	;const EVENT_246                                  ; inactive legacy 246; no current event slot
	;const EVENT_247                                  ; inactive legacy 247; no current event slot
	const EVENT_248                                  ; current 0F8, (D7EA, bit 0)
	const EVENT_249                                  ; current 0F9, (D7EA, bit 1)
	const EVENT_24A                                  ; current 0FA, (D7EA, bit 2)
	const EVENT_24B                                  ; current 0FB, (D7EA, bit 3)
	const EVENT_24C                                  ; current 0FC, (D7EA, bit 4)
	const EVENT_24D                                  ; current 0FD, (D7EA, bit 5)
	const EVENT_SAFARI_GAME_OVER                     ; current 0FE, (D7EA, bit 6)
	const EVENT_IN_SAFARI_ZONE                       ; current 0FF, (D7EA, bit 7)
	;const EVENT_250                                  ; inactive legacy 250; no current event slot
	;const EVENT_251                                  ; inactive legacy 251; no current event slot
	;const EVENT_252                                  ; inactive legacy 252; no current event slot
	;const EVENT_253                                  ; inactive legacy 253; no current event slot
	;const EVENT_254                                  ; inactive legacy 254; no current event slot
	;const EVENT_255                                  ; inactive legacy 255; no current event slot
	;const EVENT_256                                  ; inactive legacy 256; no current event slot
	;const EVENT_257                                  ; inactive legacy 257; no current event slot
	const EVENT_GOT_TM06                             ; current 100, (D7EB, bit 0)
	const EVENT_BEAT_KOGA                            ; current 101, (D7EB, bit 1)
	const EVENT_BEAT_FUCHSIA_GYM_TRAINER_0           ; current 102, (D7EB, bit 2)
	const EVENT_BEAT_FUCHSIA_GYM_TRAINER_1           ; current 103, (D7EB, bit 3)
	const EVENT_BEAT_FUCHSIA_GYM_TRAINER_2           ; current 104, (D7EB, bit 4)
	const EVENT_BEAT_FUCHSIA_GYM_TRAINER_3           ; current 105, (D7EB, bit 5)
	const EVENT_BEAT_FUCHSIA_GYM_TRAINER_4           ; current 106, (D7EB, bit 6)
	const EVENT_BEAT_FUCHSIA_GYM_TRAINER_5           ; current 107, (D7EB, bit 7)
	;const EVENT_260                                  ; inactive legacy 260; no current event slot
	;const EVENT_261                                  ; inactive legacy 261; no current event slot
	;const EVENT_262                                  ; inactive legacy 262; no current event slot
	;const EVENT_263                                  ; inactive legacy 263; no current event slot
	;const EVENT_264                                  ; inactive legacy 264; no current event slot
	;const EVENT_265                                  ; inactive legacy 265; no current event slot
	;const EVENT_266                                  ; inactive legacy 266; no current event slot
	;const EVENT_267                                  ; inactive legacy 267; no current event slot
	;const EVENT_268                                  ; inactive legacy 268; no current event slot
	;const EVENT_269                                  ; inactive legacy 269; no current event slot
	;const EVENT_26A                                  ; inactive legacy 26A; no current event slot
	;const EVENT_26B                                  ; inactive legacy 26B; no current event slot
	;const EVENT_26C                                  ; inactive legacy 26C; no current event slot
	;const EVENT_26D                                  ; inactive legacy 26D; no current event slot
	;const EVENT_26E                                  ; inactive legacy 26E; no current event slot
	;const EVENT_26F                                  ; inactive legacy 26F; no current event slot
	;const EVENT_270                                  ; inactive legacy 270; no current event slot
	;const EVENT_271                                  ; inactive legacy 271; no current event slot
	;const EVENT_272                                  ; inactive legacy 272; no current event slot
	;const EVENT_273                                  ; inactive legacy 273; no current event slot
	;const EVENT_274                                  ; inactive legacy 274; no current event slot
	;const EVENT_275                                  ; inactive legacy 275; no current event slot
	;const EVENT_276                                  ; inactive legacy 276; no current event slot
	;const EVENT_277                                  ; inactive legacy 277; no current event slot
	const EVENT_MANSION_SWITCH_ON                    ; current 108, (D7EC, bit 0)
	const EVENT_279                                  ; current 109, (D7EC, bit 1)
	const EVENT_27A                                  ; current 10A, (D7EC, bit 2)
	const EVENT_27B                                  ; current 10B, (D7EC, bit 3)
	const EVENT_27C                                  ; current 10C, (D7EC, bit 4)
	const EVENT_27D                                  ; current 10D, (D7EC, bit 5)
	const EVENT_27E                                  ; current 10E, (D7EC, bit 6)
	const EVENT_27F                                  ; current 10F, (D7EC, bit 7)
	;const EVENT_280                                  ; inactive legacy 280; no current event slot
	;const EVENT_281                                  ; inactive legacy 281; no current event slot
	;const EVENT_282                                  ; inactive legacy 282; no current event slot
	;const EVENT_283                                  ; inactive legacy 283; no current event slot
	;const EVENT_284                                  ; inactive legacy 284; no current event slot
	;const EVENT_285                                  ; inactive legacy 285; no current event slot
	;const EVENT_286                                  ; inactive legacy 286; no current event slot
	;const EVENT_287                                  ; inactive legacy 287; no current event slot
	const EVENT_288                                  ; current 110, (D7ED, bit 0)
	const EVENT_BEAT_MANSION_1_TRAINER_0             ; current 111, (D7ED, bit 1)
	const EVENT_28A                                  ; current 112, (D7ED, bit 2)
	const EVENT_28B                                  ; current 113, (D7ED, bit 3)
	const EVENT_28C                                  ; current 114, (D7ED, bit 4)
	const EVENT_28D                                  ; current 115, (D7ED, bit 5)
	const EVENT_28E                                  ; current 116, (D7ED, bit 6)
	const EVENT_28F                                  ; current 117, (D7ED, bit 7)
	;const EVENT_290                                  ; inactive legacy 290; no current event slot
	;const EVENT_291                                  ; inactive legacy 291; no current event slot
	;const EVENT_292                                  ; inactive legacy 292; no current event slot
	;const EVENT_293                                  ; inactive legacy 293; no current event slot
	;const EVENT_294                                  ; inactive legacy 294; no current event slot
	;const EVENT_295                                  ; inactive legacy 295; no current event slot
	;const EVENT_296                                  ; inactive legacy 296; no current event slot
	;const EVENT_297                                  ; inactive legacy 297; no current event slot
	const EVENT_GOT_TM38                             ; current 118, (D7EE, bit 0)
	const EVENT_BEAT_BLAINE                          ; current 119, (D7EE, bit 1)
	const EVENT_BEAT_CINNABAR_GYM_TRAINER_0          ; current 11A, (D7EE, bit 2)
	const EVENT_BEAT_CINNABAR_GYM_TRAINER_1          ; current 11B, (D7EE, bit 3)
	const EVENT_BEAT_CINNABAR_GYM_TRAINER_2          ; current 11C, (D7EE, bit 4)
	const EVENT_BEAT_CINNABAR_GYM_TRAINER_3          ; current 11D, (D7EE, bit 5)
	const EVENT_BEAT_CINNABAR_GYM_TRAINER_4          ; current 11E, (D7EE, bit 6)
	const EVENT_BEAT_CINNABAR_GYM_TRAINER_5          ; current 11F, (D7EE, bit 7)
	const EVENT_BEAT_CINNABAR_GYM_TRAINER_6          ; current 120, (D7EF, bit 0)
	const EVENT_2A1                                  ; current 121, (D7EF, bit 1)
	const EVENT_2A2                                  ; current 122, (D7EF, bit 2)
	const EVENT_2A3                                  ; current 123, (D7EF, bit 3)
	const EVENT_2A4                                  ; current 124, (D7EF, bit 4)
	const EVENT_2A5                                  ; current 125, (D7EF, bit 5)
	const EVENT_2A6                                  ; current 126, (D7EF, bit 6)
	const EVENT_2A7                                  ; current 127, (D7EF, bit 7)
	const EVENT_CINNABAR_GYM_GATE0_UNLOCKED          ; current 128, (D7F0, bit 0) doesn't exist, but the bit is set
	const EVENT_CINNABAR_GYM_GATE1_UNLOCKED          ; current 129, (D7F0, bit 1)
	const EVENT_CINNABAR_GYM_GATE2_UNLOCKED          ; current 12A, (D7F0, bit 2)
	const EVENT_CINNABAR_GYM_GATE3_UNLOCKED          ; current 12B, (D7F0, bit 3)
	const EVENT_CINNABAR_GYM_GATE4_UNLOCKED          ; current 12C, (D7F0, bit 4)
	const EVENT_CINNABAR_GYM_GATE5_UNLOCKED          ; current 12D, (D7F0, bit 5)
	const EVENT_CINNABAR_GYM_GATE6_UNLOCKED          ; current 12E, (D7F0, bit 6)
	const EVENT_2AF                                  ; current 12F, (D7F0, bit 7)
	;const EVENT_2B0                                  ; inactive legacy 2B0; no current event slot
	;const EVENT_2B1                                  ; inactive legacy 2B1; no current event slot
	;const EVENT_2B2                                  ; inactive legacy 2B2; no current event slot
	;const EVENT_2B3                                  ; inactive legacy 2B3; no current event slot
	;const EVENT_2B4                                  ; inactive legacy 2B4; no current event slot
	;const EVENT_2B5                                  ; inactive legacy 2B5; no current event slot
	;const EVENT_2B6                                  ; inactive legacy 2B6; no current event slot
	;const EVENT_2B7                                  ; inactive legacy 2B7; no current event slot
	;const EVENT_2B8                                  ; inactive legacy 2B8; no current event slot
	;const EVENT_2B9                                  ; inactive legacy 2B9; no current event slot
	;const EVENT_2BA                                  ; inactive legacy 2BA; no current event slot
	;const EVENT_2BB                                  ; inactive legacy 2BB; no current event slot
	;const EVENT_2BC                                  ; inactive legacy 2BC; no current event slot
	;const EVENT_2BD                                  ; inactive legacy 2BD; no current event slot
	;const EVENT_2BE                                  ; inactive legacy 2BE; no current event slot
	;const EVENT_2BF                                  ; inactive legacy 2BF; no current event slot
	;const EVENT_2C0                                  ; inactive legacy 2C0; no current event slot
	;const EVENT_2C1                                  ; inactive legacy 2C1; no current event slot
	;const EVENT_2C2                                  ; inactive legacy 2C2; no current event slot
	;const EVENT_2C3                                  ; inactive legacy 2C3; no current event slot
	;const EVENT_2C4                                  ; inactive legacy 2C4; no current event slot
	;const EVENT_2C5                                  ; inactive legacy 2C5; no current event slot
	;const EVENT_2C6                                  ; inactive legacy 2C6; no current event slot
	;const EVENT_2C7                                  ; inactive legacy 2C7; no current event slot
	;const EVENT_2C8                                  ; inactive legacy 2C8; no current event slot
	;const EVENT_2C9                                  ; inactive legacy 2C9; no current event slot
	;const EVENT_2CA                                  ; inactive legacy 2CA; no current event slot
	;const EVENT_2CB                                  ; inactive legacy 2CB; no current event slot
	;const EVENT_2CC                                  ; inactive legacy 2CC; no current event slot
	;const EVENT_2CD                                  ; inactive legacy 2CD; no current event slot
	;const EVENT_2CE                                  ; inactive legacy 2CE; no current event slot
	;const EVENT_2CF                                  ; inactive legacy 2CF; no current event slot
	const EVENT_2D0                                  ; current 130, (D7F1, bit 0)
	const EVENT_2D1                                  ; current 131, (D7F1, bit 1)
	const EVENT_2D2                                  ; current 132, (D7F1, bit 2)
	const EVENT_2D3                                  ; current 133, (D7F1, bit 3)
	const EVENT_2D4                                  ; current 134, (D7F1, bit 4)
	const EVENT_2D5                                  ; current 135, (D7F1, bit 5)
	const EVENT_2D6                                  ; current 136, (D7F1, bit 6)
	const EVENT_GOT_TM35                             ; current 137, (D7F1, bit 7)
	;const EVENT_2D8                                  ; inactive legacy 2D8; no current event slot
	;const EVENT_2D9                                  ; inactive legacy 2D9; no current event slot
	;const EVENT_2DA                                  ; inactive legacy 2DA; no current event slot
	;const EVENT_2DB                                  ; inactive legacy 2DB; no current event slot
	;const EVENT_2DC                                  ; inactive legacy 2DC; no current event slot
	;const EVENT_2DD                                  ; inactive legacy 2DD; no current event slot
	;const EVENT_2DE                                  ; inactive legacy 2DE; no current event slot
	;const EVENT_2DF                                  ; inactive legacy 2DF; no current event slot
	const EVENT_GAVE_FOSSIL_TO_LAB                   ; current 138, (D7F2, bit 0) ; FSL-5.42.01: legacy/reserved, keep numbering stable
	const EVENT_LAB_STILL_REVIVING_FOSSIL            ; current 139, (D7F2, bit 1) ; FSL-5.42.01: legacy/reserved, keep numbering stable
	const EVENT_LAB_HANDING_OVER_FOSSIL_MON          ; current 13A, (D7F2, bit 2) ; FSL-5.42.01: legacy/reserved, keep numbering stable
	const EVENT_2E3                                  ; current 13B, (D7F2, bit 3)
	const EVENT_2E4                                  ; current 13C, (D7F2, bit 4)
	const EVENT_2E5                                  ; current 13D, (D7F2, bit 5)
	const EVENT_2E6                                  ; current 13E, (D7F2, bit 6)
	const EVENT_2E7                                  ; current 13F, (D7F2, bit 7)
	;const EVENT_2E8                                  ; inactive legacy 2E8; no current event slot
	;const EVENT_2E9                                  ; inactive legacy 2E9; no current event slot
	;const EVENT_2EA                                  ; inactive legacy 2EA; no current event slot
	;const EVENT_2EB                                  ; inactive legacy 2EB; no current event slot
	;const EVENT_2EC                                  ; inactive legacy 2EC; no current event slot
	;const EVENT_2ED                                  ; inactive legacy 2ED; no current event slot
	;const EVENT_2EE                                  ; inactive legacy 2EE; no current event slot
	;const EVENT_2EF                                  ; inactive legacy 2EF; no current event slot
	;const EVENT_2F0                                  ; inactive legacy 2F0; no current event slot
	;const EVENT_2F1                                  ; inactive legacy 2F1; no current event slot
	;const EVENT_2F2                                  ; inactive legacy 2F2; no current event slot
	;const EVENT_2F3                                  ; inactive legacy 2F3; no current event slot
	;const EVENT_2F4                                  ; inactive legacy 2F4; no current event slot
	;const EVENT_2F5                                  ; inactive legacy 2F5; no current event slot
	;const EVENT_2F6                                  ; inactive legacy 2F6; no current event slot
	;const EVENT_2F7                                  ; inactive legacy 2F7; no current event slot
	;const EVENT_2F8                                  ; inactive legacy 2F8; no current event slot
	;const EVENT_2F9                                  ; inactive legacy 2F9; no current event slot
	;const EVENT_2FA                                  ; inactive legacy 2FA; no current event slot
	;const EVENT_2FB                                  ; inactive legacy 2FB; no current event slot
	;const EVENT_2FC                                  ; inactive legacy 2FC; no current event slot
	;const EVENT_2FD                                  ; inactive legacy 2FD; no current event slot
	;const EVENT_2FE                                  ; inactive legacy 2FE; no current event slot
	;const EVENT_2FF                                  ; inactive legacy 2FF; no current event slot
	;const EVENT_300                                  ; inactive legacy 300; no current event slot
	;const EVENT_301                                  ; inactive legacy 301; no current event slot
	;const EVENT_302                                  ; inactive legacy 302; no current event slot
	;const EVENT_303                                  ; inactive legacy 303; no current event slot
	;const EVENT_304                                  ; inactive legacy 304; no current event slot
	;const EVENT_305                                  ; inactive legacy 305; no current event slot
	;const EVENT_306                                  ; inactive legacy 306; no current event slot
	;const EVENT_307                                  ; inactive legacy 307; no current event slot
	;const EVENT_308                                  ; inactive legacy 308; no current event slot
	;const EVENT_309                                  ; inactive legacy 309; no current event slot
	;const EVENT_30A                                  ; inactive legacy 30A; no current event slot
	;const EVENT_30B                                  ; inactive legacy 30B; no current event slot
	;const EVENT_30C                                  ; inactive legacy 30C; no current event slot
	;const EVENT_30D                                  ; inactive legacy 30D; no current event slot
	;const EVENT_30E                                  ; inactive legacy 30E; no current event slot
	;const EVENT_30F                                  ; inactive legacy 30F; no current event slot
	;const EVENT_310                                  ; inactive legacy 310; no current event slot
	;const EVENT_311                                  ; inactive legacy 311; no current event slot
	;const EVENT_312                                  ; inactive legacy 312; no current event slot
	;const EVENT_313                                  ; inactive legacy 313; no current event slot
	;const EVENT_314                                  ; inactive legacy 314; no current event slot
	;const EVENT_315                                  ; inactive legacy 315; no current event slot
	;const EVENT_316                                  ; inactive legacy 316; no current event slot
	;const EVENT_317                                  ; inactive legacy 317; no current event slot
	;const EVENT_318                                  ; inactive legacy 318; no current event slot
	;const EVENT_319                                  ; inactive legacy 319; no current event slot
	;const EVENT_31A                                  ; inactive legacy 31A; no current event slot
	;const EVENT_31B                                  ; inactive legacy 31B; no current event slot
	;const EVENT_31C                                  ; inactive legacy 31C; no current event slot
	;const EVENT_31D                                  ; inactive legacy 31D; no current event slot
	;const EVENT_31E                                  ; inactive legacy 31E; no current event slot
	;const EVENT_31F                                  ; inactive legacy 31F; no current event slot
	;const EVENT_320                                  ; inactive legacy 320; no current event slot
	;const EVENT_321                                  ; inactive legacy 321; no current event slot
	;const EVENT_322                                  ; inactive legacy 322; no current event slot
	;const EVENT_323                                  ; inactive legacy 323; no current event slot
	;const EVENT_324                                  ; inactive legacy 324; no current event slot
	;const EVENT_325                                  ; inactive legacy 325; no current event slot
	;const EVENT_326                                  ; inactive legacy 326; no current event slot
	;const EVENT_327                                  ; inactive legacy 327; no current event slot
	;const EVENT_328                                  ; inactive legacy 328; no current event slot
	;const EVENT_329                                  ; inactive legacy 329; no current event slot
	;const EVENT_32A                                  ; inactive legacy 32A; no current event slot
	;const EVENT_32B                                  ; inactive legacy 32B; no current event slot
	;const EVENT_32C                                  ; inactive legacy 32C; no current event slot
	;const EVENT_32D                                  ; inactive legacy 32D; no current event slot
	;const EVENT_32E                                  ; inactive legacy 32E; no current event slot
	;const EVENT_32F                                  ; inactive legacy 32F; no current event slot
	;const EVENT_330                                  ; inactive legacy 330; no current event slot
	;const EVENT_331                                  ; inactive legacy 331; no current event slot
	;const EVENT_332                                  ; inactive legacy 332; no current event slot
	;const EVENT_333                                  ; inactive legacy 333; no current event slot
	;const EVENT_334                                  ; inactive legacy 334; no current event slot
	;const EVENT_335                                  ; inactive legacy 335; no current event slot
	;const EVENT_336                                  ; inactive legacy 336; no current event slot
	;const EVENT_337                                  ; inactive legacy 337; no current event slot
	;const EVENT_338                                  ; inactive legacy 338; no current event slot
	;const EVENT_339                                  ; inactive legacy 339; no current event slot
	;const EVENT_33A                                  ; inactive legacy 33A; no current event slot
	;const EVENT_33B                                  ; inactive legacy 33B; no current event slot
	;const EVENT_33C                                  ; inactive legacy 33C; no current event slot
	;const EVENT_33D                                  ; inactive legacy 33D; no current event slot
	;const EVENT_33E                                  ; inactive legacy 33E; no current event slot
	;const EVENT_33F                                  ; inactive legacy 33F; no current event slot
	const EVENT_GOT_TM31                             ; current 140, (D7F3, bit 0)
	const EVENT_341                                  ; current 141, (D7F3, bit 1)
	const EVENT_342                                  ; current 142, (D7F3, bit 2)
	const EVENT_343                                  ; current 143, (D7F3, bit 3)
	const EVENT_344                                  ; current 144, (D7F3, bit 4)
	const EVENT_345                                  ; current 145, (D7F3, bit 5)
	const EVENT_346                                  ; current 146, (D7F3, bit 6)
	const EVENT_347                                  ; current 147, (D7F3, bit 7)
	;const EVENT_348                                  ; inactive legacy 348; no current event slot
	;const EVENT_349                                  ; inactive legacy 349; no current event slot
	;const EVENT_34A                                  ; inactive legacy 34A; no current event slot
	;const EVENT_34B                                  ; inactive legacy 34B; no current event slot
	;const EVENT_34C                                  ; inactive legacy 34C; no current event slot
	;const EVENT_34D                                  ; inactive legacy 34D; no current event slot
	;const EVENT_34E                                  ; inactive legacy 34E; no current event slot
	;const EVENT_34F                                  ; inactive legacy 34F; no current event slot
	const EVENT_DEFEATED_FIGHTING_DOJO               ; current 148, (D7F4, bit 0)
	const EVENT_BEAT_KARATE_MASTER                   ; current 149, (D7F4, bit 1)
	const EVENT_BEAT_FIGHTING_DOJO_TRAINER_0         ; current 14A, (D7F4, bit 2)
	const EVENT_BEAT_FIGHTING_DOJO_TRAINER_1         ; current 14B, (D7F4, bit 3)
	const EVENT_BEAT_FIGHTING_DOJO_TRAINER_2         ; current 14C, (D7F4, bit 4)
	const EVENT_BEAT_FIGHTING_DOJO_TRAINER_3         ; current 14D, (D7F4, bit 5)
	const EVENT_GOT_HITMONLEE                        ; current 14E, (D7F4, bit 6)
	const EVENT_GOT_HITMONCHAN                       ; current 14F, (D7F4, bit 7)
	;const EVENT_358                                  ; inactive legacy 358; no current event slot
	;const EVENT_359                                  ; inactive legacy 359; no current event slot
	;const EVENT_35A                                  ; inactive legacy 35A; no current event slot
	;const EVENT_35B                                  ; inactive legacy 35B; no current event slot
	;const EVENT_35C                                  ; inactive legacy 35C; no current event slot
	;const EVENT_35D                                  ; inactive legacy 35D; no current event slot
	;const EVENT_35E                                  ; inactive legacy 35E; no current event slot
	;const EVENT_35F                                  ; inactive legacy 35F; no current event slot
	const EVENT_GOT_TM46                             ; current 150, (D7F5, bit 0)
	const EVENT_BEAT_SABRINA                         ; current 151, (D7F5, bit 1)
	const EVENT_BEAT_SAFFRON_GYM_TRAINER_0           ; current 152, (D7F5, bit 2)
	const EVENT_BEAT_SAFFRON_GYM_TRAINER_1           ; current 153, (D7F5, bit 3)
	const EVENT_BEAT_SAFFRON_GYM_TRAINER_2           ; current 154, (D7F5, bit 4)
	const EVENT_BEAT_SAFFRON_GYM_TRAINER_3           ; current 155, (D7F5, bit 5)
	const EVENT_BEAT_SAFFRON_GYM_TRAINER_4           ; current 156, (D7F5, bit 6)
	const EVENT_BEAT_SAFFRON_GYM_TRAINER_5           ; current 157, (D7F5, bit 7)
	const EVENT_BEAT_SAFFRON_GYM_TRAINER_6           ; current 158, (D7F6, bit 0)
	const EVENT_369                                  ; current 159, (D7F6, bit 1)
	const EVENT_36A                                  ; current 15A, (D7F6, bit 2)
	const EVENT_36B                                  ; current 15B, (D7F6, bit 3)
	const EVENT_36C                                  ; current 15C, (D7F6, bit 4)
	const EVENT_36D                                  ; current 15D, (D7F6, bit 5)
	const EVENT_36E                                  ; current 15E, (D7F6, bit 6)
	const EVENT_36F                                  ; current 15F, (D7F6, bit 7)
	;const EVENT_370                                  ; inactive legacy 370; no current event slot
	;const EVENT_371                                  ; inactive legacy 371; no current event slot
	;const EVENT_372                                  ; inactive legacy 372; no current event slot
	;const EVENT_373                                  ; inactive legacy 373; no current event slot
	;const EVENT_374                                  ; inactive legacy 374; no current event slot
	;const EVENT_375                                  ; inactive legacy 375; no current event slot
	;const EVENT_376                                  ; inactive legacy 376; no current event slot
	;const EVENT_377                                  ; inactive legacy 377; no current event slot
	;const EVENT_378                                  ; inactive legacy 378; no current event slot
	;const EVENT_379                                  ; inactive legacy 379; no current event slot
	;const EVENT_37A                                  ; inactive legacy 37A; no current event slot
	;const EVENT_37B                                  ; inactive legacy 37B; no current event slot
	;const EVENT_37C                                  ; inactive legacy 37C; no current event slot
	;const EVENT_37D                                  ; inactive legacy 37D; no current event slot
	;const EVENT_37E                                  ; inactive legacy 37E; no current event slot
	;const EVENT_37F                                  ; inactive legacy 37F; no current event slot
	;const EVENT_380                                  ; inactive legacy 380; no current event slot
	;const EVENT_381                                  ; inactive legacy 381; no current event slot
	;const EVENT_382                                  ; inactive legacy 382; no current event slot
	;const EVENT_383                                  ; inactive legacy 383; no current event slot
	;const EVENT_384                                  ; inactive legacy 384; no current event slot
	;const EVENT_385                                  ; inactive legacy 385; no current event slot
	;const EVENT_386                                  ; inactive legacy 386; no current event slot
	;const EVENT_387                                  ; inactive legacy 387; no current event slot
	;const EVENT_388                                  ; inactive legacy 388; no current event slot
	;const EVENT_389                                  ; inactive legacy 389; no current event slot
	;const EVENT_38A                                  ; inactive legacy 38A; no current event slot
	;const EVENT_38B                                  ; inactive legacy 38B; no current event slot
	;const EVENT_38C                                  ; inactive legacy 38C; no current event slot
	;const EVENT_38D                                  ; inactive legacy 38D; no current event slot
	;const EVENT_38E                                  ; inactive legacy 38E; no current event slot
	;const EVENT_38F                                  ; inactive legacy 38F; no current event slot
	const EVENT_390                                  ; current 160, (D7F7, bit 0)
	const EVENT_391                                  ; current 161, (D7F7, bit 1)
	const EVENT_392                                  ; current 162, (D7F7, bit 2)
	const EVENT_393                                  ; current 163, (D7F7, bit 3)
	const EVENT_394                                  ; current 164, (D7F7, bit 4)
	const EVENT_395                                  ; current 165, (D7F7, bit 5)
	const EVENT_396                                  ; current 166, (D7F7, bit 6)
	const EVENT_SILPH_CO_RECEPTIONIST_AT_DESK        ; current 167, (D7F7, bit 7)
	;const EVENT_398                                  ; inactive legacy 398; no current event slot
	;const EVENT_399                                  ; inactive legacy 399; no current event slot
	;const EVENT_39A                                  ; inactive legacy 39A; no current event slot
	;const EVENT_39B                                  ; inactive legacy 39B; no current event slot
	;const EVENT_39C                                  ; inactive legacy 39C; no current event slot
	;const EVENT_39D                                  ; inactive legacy 39D; no current event slot
	;const EVENT_39E                                  ; inactive legacy 39E; no current event slot
	;const EVENT_39F                                  ; inactive legacy 39F; no current event slot
	;const EVENT_3A0                                  ; inactive legacy 3A0; no current event slot
	;const EVENT_3A1                                  ; inactive legacy 3A1; no current event slot
	;const EVENT_3A2                                  ; inactive legacy 3A2; no current event slot
	;const EVENT_3A3                                  ; inactive legacy 3A3; no current event slot
	;const EVENT_3A4                                  ; inactive legacy 3A4; no current event slot
	;const EVENT_3A5                                  ; inactive legacy 3A5; no current event slot
	;const EVENT_3A6                                  ; inactive legacy 3A6; no current event slot
	;const EVENT_3A7                                  ; inactive legacy 3A7; no current event slot
	;const EVENT_3A8                                  ; inactive legacy 3A8; no current event slot
	;const EVENT_3A9                                  ; inactive legacy 3A9; no current event slot
	;const EVENT_3AA                                  ; inactive legacy 3AA; no current event slot
	;const EVENT_3AB                                  ; inactive legacy 3AB; no current event slot
	;const EVENT_3AC                                  ; inactive legacy 3AC; no current event slot
	;const EVENT_3AD                                  ; inactive legacy 3AD; no current event slot
	;const EVENT_3AE                                  ; inactive legacy 3AE; no current event slot
	;const EVENT_3AF                                  ; inactive legacy 3AF; no current event slot
	const EVENT_GOT_TM29                             ; current 168, (D7F8, bit 0)
	const EVENT_3B1                                  ; current 169, (D7F8, bit 1)
	const EVENT_3B2                                  ; current 16A, (D7F8, bit 2)
	const EVENT_3B3                                  ; current 16B, (D7F8, bit 3)
	const EVENT_3B4                                  ; current 16C, (D7F8, bit 4)
	const EVENT_3B5                                  ; current 16D, (D7F8, bit 5)
	const EVENT_3B6                                  ; current 16E, (D7F8, bit 6)
	const EVENT_3B7                                  ; current 16F, (D7F8, bit 7)
	;const EVENT_3B8                                  ; inactive legacy 3B8; no current event slot
	;const EVENT_3B9                                  ; inactive legacy 3B9; no current event slot
	;const EVENT_3BA                                  ; inactive legacy 3BA; no current event slot
	;const EVENT_3BB                                  ; inactive legacy 3BB; no current event slot
	;const EVENT_3BC                                  ; inactive legacy 3BC; no current event slot
	;const EVENT_3BD                                  ; inactive legacy 3BD; no current event slot
	;const EVENT_3BE                                  ; inactive legacy 3BE; no current event slot
	;const EVENT_3BF                                  ; inactive legacy 3BF; no current event slot
	const EVENT_GOT_POTION_SAMPLE                    ; current 170, (D7F9, bit 0)
	const EVENT_3C1                                  ; current 171, (D7F9, bit 1)
	const EVENT_3C2                                  ; current 172, (D7F9, bit 2)
	const EVENT_3C3                                  ; current 173, (D7F9, bit 3)
	const EVENT_3C4                                  ; current 174, (D7F9, bit 4)
	const EVENT_3C5                                  ; current 175, (D7F9, bit 5)
	const EVENT_3C6                                  ; current 176, (D7F9, bit 6)
	const EVENT_3C7                                  ; current 177, (D7F9, bit 7)
	;const EVENT_3C8                                  ; inactive legacy 3C8; no current event slot
	;const EVENT_3C9                                  ; inactive legacy 3C9; no current event slot
	;const EVENT_3CA                                  ; inactive legacy 3CA; no current event slot
	;const EVENT_3CB                                  ; inactive legacy 3CB; no current event slot
	;const EVENT_3CC                                  ; inactive legacy 3CC; no current event slot
	;const EVENT_3CD                                  ; inactive legacy 3CD; no current event slot
	;const EVENT_3CE                                  ; inactive legacy 3CE; no current event slot
	;const EVENT_3CF                                  ; inactive legacy 3CF; no current event slot
	;const EVENT_3D0                                  ; inactive legacy 3D0; no current event slot
	;const EVENT_3D1                                  ; inactive legacy 3D1; no current event slot
	;const EVENT_3D2                                  ; inactive legacy 3D2; no current event slot
	;const EVENT_3D3                                  ; inactive legacy 3D3; no current event slot
	;const EVENT_3D4                                  ; inactive legacy 3D4; no current event slot
	;const EVENT_3D5                                  ; inactive legacy 3D5; no current event slot
	;const EVENT_3D6                                  ; inactive legacy 3D6; no current event slot
	;const EVENT_3D7                                  ; inactive legacy 3D7; no current event slot
	const EVENT_GOT_HM05                             ; current 178, (D7FA, bit 0)
	const EVENT_3D9                                  ; current 179, (D7FA, bit 1)
	const EVENT_3DA                                  ; current 17A, (D7FA, bit 2)
	const EVENT_3DB                                  ; current 17B, (D7FA, bit 3)
	const EVENT_3DC                                  ; current 17C, (D7FA, bit 4)
	const EVENT_3DD                                  ; current 17D, (D7FA, bit 5)
	const EVENT_3DE                                  ; current 17E, (D7FA, bit 6)
	const EVENT_3DF                                  ; current 17F, (D7FA, bit 7)
	const EVENT_3E0                                  ; current 180, (D7FB, bit 0)
	const EVENT_3E1                                  ; current 181, (D7FB, bit 1)
	const EVENT_BEAT_ROUTE_3_TRAINER_0               ; current 182, (D7FB, bit 2)
	const EVENT_BEAT_ROUTE_3_TRAINER_1               ; current 183, (D7FB, bit 3)
	const EVENT_BEAT_ROUTE_3_TRAINER_2               ; current 184, (D7FB, bit 4)
	const EVENT_BEAT_ROUTE_3_TRAINER_3               ; current 185, (D7FB, bit 5)
	const EVENT_BEAT_ROUTE_3_TRAINER_4               ; current 186, (D7FB, bit 6)
	const EVENT_BEAT_ROUTE_3_TRAINER_5               ; current 187, (D7FB, bit 7)
	;const EVENT_BEAT_ROUTE_3_TRAINER_6               ; inactive legacy 3E8; no current event slot
	;const EVENT_BEAT_ROUTE_3_TRAINER_7               ; inactive legacy 3E9; no current event slot
	;const EVENT_3EA                                  ; inactive legacy 3EA; no current event slot
	;const EVENT_3EB                                  ; inactive legacy 3EB; no current event slot
	;const EVENT_3EC                                  ; inactive legacy 3EC; no current event slot
	;const EVENT_3ED                                  ; inactive legacy 3ED; no current event slot
	;const EVENT_3EE                                  ; inactive legacy 3EE; no current event slot
	;const EVENT_3EF                                  ; inactive legacy 3EF; no current event slot
	const EVENT_BEAT_ROUTE_3_TRAINER_6               ; current 188, (D7FC, bit 0) XXX
	const EVENT_BEAT_ROUTE_3_TRAINER_7               ; current 189, (D7FC, bit 1) XXX
	const EVENT_BEAT_ROUTE_4_TRAINER_0               ; current 18A, (D7FC, bit 2)
	const EVENT_3F3                                  ; current 18B, (D7FC, bit 3)
	const EVENT_3F4                                  ; current 18C, (D7FC, bit 4)
	const EVENT_3F5                                  ; current 18D, (D7FC, bit 5)
	const EVENT_3F6                                  ; current 18E, (D7FC, bit 6)
	const EVENT_3F7                                  ; current 18F, (D7FC, bit 7)
	const EVENT_3F8                                  ; current 190, (D7FD, bit 0)
	const EVENT_3F9                                  ; current 191, (D7FD, bit 1)
	const EVENT_3FA                                  ; current 192, (D7FD, bit 2)
	const EVENT_3FB                                  ; current 193, (D7FD, bit 3)
	const EVENT_3FC                                  ; current 194, (D7FD, bit 4)
	const EVENT_3FD                                  ; current 195, (D7FD, bit 5)
	const EVENT_3FE                                  ; current 196, (D7FD, bit 6)
	const EVENT_BOUGHT_MAGIKARP                      ; current 197, (D7FD, bit 7)
	;const EVENT_400                                  ; inactive legacy 400; no current event slot
	;const EVENT_401                                  ; inactive legacy 401; no current event slot
	;const EVENT_402                                  ; inactive legacy 402; no current event slot
	;const EVENT_403                                  ; inactive legacy 403; no current event slot
	;const EVENT_404                                  ; inactive legacy 404; no current event slot
	;const EVENT_405                                  ; inactive legacy 405; no current event slot
	;const EVENT_406                                  ; inactive legacy 406; no current event slot
	;const EVENT_407                                  ; inactive legacy 407; no current event slot
	;const EVENT_408                                  ; inactive legacy 408; no current event slot
	;const EVENT_409                                  ; inactive legacy 409; no current event slot
	;const EVENT_40A                                  ; inactive legacy 40A; no current event slot
	;const EVENT_40B                                  ; inactive legacy 40B; no current event slot
	;const EVENT_40C                                  ; inactive legacy 40C; no current event slot
	;const EVENT_40D                                  ; inactive legacy 40D; no current event slot
	;const EVENT_40E                                  ; inactive legacy 40E; no current event slot
	;const EVENT_40F                                  ; inactive legacy 40F; no current event slot
	const EVENT_410                                  ; current 198, (D7FE, bit 0)
	const EVENT_BEAT_ROUTE_6_TRAINER_0               ; current 199, (D7FE, bit 1)
	const EVENT_BEAT_ROUTE_6_TRAINER_1               ; current 19A, (D7FE, bit 2)
	const EVENT_BEAT_ROUTE_6_TRAINER_2               ; current 19B, (D7FE, bit 3)
	const EVENT_BEAT_ROUTE_6_TRAINER_3               ; current 19C, (D7FE, bit 4)
	const EVENT_BEAT_ROUTE_6_TRAINER_4               ; current 19D, (D7FE, bit 5)
	const EVENT_BEAT_ROUTE_6_TRAINER_5               ; current 19E, (D7FE, bit 6)
	const EVENT_417                                  ; current 19F, (D7FE, bit 7)
	;const EVENT_418                                  ; inactive legacy 418; no current event slot
	;const EVENT_419                                  ; inactive legacy 419; no current event slot
	;const EVENT_41A                                  ; inactive legacy 41A; no current event slot
	;const EVENT_41B                                  ; inactive legacy 41B; no current event slot
	;const EVENT_41C                                  ; inactive legacy 41C; no current event slot
	;const EVENT_41D                                  ; inactive legacy 41D; no current event slot
	;const EVENT_41E                                  ; inactive legacy 41E; no current event slot
	;const EVENT_41F                                  ; inactive legacy 41F; no current event slot
	;const EVENT_420                                  ; inactive legacy 420; no current event slot
	;const EVENT_421                                  ; inactive legacy 421; no current event slot
	;const EVENT_422                                  ; inactive legacy 422; no current event slot
	;const EVENT_423                                  ; inactive legacy 423; no current event slot
	;const EVENT_424                                  ; inactive legacy 424; no current event slot
	;const EVENT_425                                  ; inactive legacy 425; no current event slot
	;const EVENT_426                                  ; inactive legacy 426; no current event slot
	;const EVENT_427                                  ; inactive legacy 427; no current event slot
	;const EVENT_428                                  ; inactive legacy 428; no current event slot
	;const EVENT_429                                  ; inactive legacy 429; no current event slot
	;const EVENT_42A                                  ; inactive legacy 42A; no current event slot
	;const EVENT_42B                                  ; inactive legacy 42B; no current event slot
	;const EVENT_42C                                  ; inactive legacy 42C; no current event slot
	;const EVENT_42D                                  ; inactive legacy 42D; no current event slot
	;const EVENT_42E                                  ; inactive legacy 42E; no current event slot
	;const EVENT_42F                                  ; inactive legacy 42F; no current event slot
	const EVENT_430                                  ; current 1A0, (D7FF, bit 0)
	const EVENT_BEAT_ROUTE_8_TRAINER_0               ; current 1A1, (D7FF, bit 1)
	const EVENT_BEAT_ROUTE_8_TRAINER_1               ; current 1A2, (D7FF, bit 2)
	const EVENT_BEAT_ROUTE_8_TRAINER_2               ; current 1A3, (D7FF, bit 3)
	const EVENT_BEAT_ROUTE_8_TRAINER_3               ; current 1A4, (D7FF, bit 4)
	const EVENT_BEAT_ROUTE_8_TRAINER_4               ; current 1A5, (D7FF, bit 5)
	const EVENT_BEAT_ROUTE_8_TRAINER_5               ; current 1A6, (D7FF, bit 6)
	const EVENT_BEAT_ROUTE_8_TRAINER_6               ; current 1A7, (D7FF, bit 7)
	const EVENT_BEAT_ROUTE_8_TRAINER_7               ; current 1A8, (D800, bit 0)
	const EVENT_BEAT_ROUTE_8_TRAINER_8               ; current 1A9, (D800, bit 1)
	const EVENT_43A                                  ; current 1AA, (D800, bit 2)
	const EVENT_43B                                  ; current 1AB, (D800, bit 3)
	const EVENT_43C                                  ; current 1AC, (D800, bit 4)
	const EVENT_43D                                  ; current 1AD, (D800, bit 5)
	const EVENT_43E                                  ; current 1AE, (D800, bit 6)
	const EVENT_43F                                  ; current 1AF, (D800, bit 7)
	const EVENT_440                                  ; current 1B0, (D801, bit 0)
	const EVENT_BEAT_ROUTE_9_TRAINER_0               ; current 1B1, (D801, bit 1)
	const EVENT_BEAT_ROUTE_9_TRAINER_1               ; current 1B2, (D801, bit 2)
	const EVENT_BEAT_ROUTE_9_TRAINER_2               ; current 1B3, (D801, bit 3)
	const EVENT_BEAT_ROUTE_9_TRAINER_3               ; current 1B4, (D801, bit 4)
	const EVENT_BEAT_ROUTE_9_TRAINER_4               ; current 1B5, (D801, bit 5)
	const EVENT_BEAT_ROUTE_9_TRAINER_5               ; current 1B6, (D801, bit 6)
	const EVENT_BEAT_ROUTE_9_TRAINER_6               ; current 1B7, (D801, bit 7)
	const EVENT_BEAT_ROUTE_9_TRAINER_7               ; current 1B8, (D802, bit 0)
	const EVENT_BEAT_ROUTE_9_TRAINER_8               ; current 1B9, (D802, bit 1)
	const EVENT_44A                                  ; current 1BA, (D802, bit 2)
	const EVENT_44B                                  ; current 1BB, (D802, bit 3)
	const EVENT_44C                                  ; current 1BC, (D802, bit 4)
	const EVENT_44D                                  ; current 1BD, (D802, bit 5)
	const EVENT_44E                                  ; current 1BE, (D802, bit 6)
	const EVENT_44F                                  ; current 1BF, (D802, bit 7)
	const EVENT_450                                  ; current 1C0, (D803, bit 0)
	const EVENT_BEAT_ROUTE_10_TRAINER_0              ; current 1C1, (D803, bit 1)
	const EVENT_BEAT_ROUTE_10_TRAINER_1              ; current 1C2, (D803, bit 2)
	const EVENT_BEAT_ROUTE_10_TRAINER_2              ; current 1C3, (D803, bit 3)
	const EVENT_BEAT_ROUTE_10_TRAINER_3              ; current 1C4, (D803, bit 4)
	const EVENT_BEAT_ROUTE_10_TRAINER_4              ; current 1C5, (D803, bit 5)
	const EVENT_BEAT_ROUTE_10_TRAINER_5              ; current 1C6, (D803, bit 6)
	const EVENT_457                                  ; current 1C7, (D803, bit 7)
	const EVENT_458                                  ; current 1C8, (D804, bit 0)
	const EVENT_BEAT_ROCK_TUNNEL_1_TRAINER_0         ; current 1C9, (D804, bit 1)
	const EVENT_BEAT_ROCK_TUNNEL_1_TRAINER_1         ; current 1CA, (D804, bit 2)
	const EVENT_BEAT_ROCK_TUNNEL_1_TRAINER_2         ; current 1CB, (D804, bit 3)
	const EVENT_BEAT_ROCK_TUNNEL_1_TRAINER_3         ; current 1CC, (D804, bit 4)
	const EVENT_BEAT_ROCK_TUNNEL_1_TRAINER_4         ; current 1CD, (D804, bit 5)
	const EVENT_BEAT_ROCK_TUNNEL_1_TRAINER_5         ; current 1CE, (D804, bit 6)
	const EVENT_BEAT_ROCK_TUNNEL_1_TRAINER_6         ; current 1CF, (D804, bit 7)
	const EVENT_460                                  ; current 1D0, (D805, bit 0)
	const EVENT_BEAT_POWER_PLANT_VOLTORB_0           ; current 1D1, (D805, bit 1)
	const EVENT_BEAT_POWER_PLANT_VOLTORB_1           ; current 1D2, (D805, bit 2)
	const EVENT_BEAT_POWER_PLANT_VOLTORB_2           ; current 1D3, (D805, bit 3)
	const EVENT_BEAT_POWER_PLANT_VOLTORB_3           ; current 1D4, (D805, bit 4)
	const EVENT_BEAT_POWER_PLANT_VOLTORB_4           ; current 1D5, (D805, bit 5)
	const EVENT_BEAT_POWER_PLANT_VOLTORB_5           ; current 1D6, (D805, bit 6)
	const EVENT_BEAT_POWER_PLANT_VOLTORB_6           ; current 1D7, (D805, bit 7)
	const EVENT_BEAT_POWER_PLANT_VOLTORB_7           ; current 1D8, (D806, bit 0)
	const EVENT_BEAT_ZAPDOS                          ; current 1D9, (D806, bit 1)
	const EVENT_46A                                  ; current 1DA, (D806, bit 2)
	const EVENT_46B                                  ; current 1DB, (D806, bit 3)
	const EVENT_46C                                  ; current 1DC, (D806, bit 4)
	const EVENT_46D                                  ; current 1DD, (D806, bit 5)
	const EVENT_46E                                  ; current 1DE, (D806, bit 6)
	const EVENT_46F                                  ; current 1DF, (D806, bit 7)
	const EVENT_470                                  ; current 1E0, (D807, bit 0)
	const EVENT_BEAT_ROUTE_11_TRAINER_0              ; current 1E1, (D807, bit 1)
	const EVENT_BEAT_ROUTE_11_TRAINER_1              ; current 1E2, (D807, bit 2)
	const EVENT_BEAT_ROUTE_11_TRAINER_2              ; current 1E3, (D807, bit 3)
	const EVENT_BEAT_ROUTE_11_TRAINER_3              ; current 1E4, (D807, bit 4)
	const EVENT_BEAT_ROUTE_11_TRAINER_4              ; current 1E5, (D807, bit 5)
	const EVENT_BEAT_ROUTE_11_TRAINER_5              ; current 1E6, (D807, bit 6)
	const EVENT_BEAT_ROUTE_11_TRAINER_6              ; current 1E7, (D807, bit 7)
	const EVENT_BEAT_ROUTE_11_TRAINER_7              ; current 1E8, (D808, bit 0)
	const EVENT_BEAT_ROUTE_11_TRAINER_8              ; current 1E9, (D808, bit 1)
	const EVENT_BEAT_ROUTE_11_TRAINER_9              ; current 1EA, (D808, bit 2)
	const EVENT_47B                                  ; current 1EB, (D808, bit 3)
	const EVENT_47C                                  ; current 1EC, (D808, bit 4)
	const EVENT_47D                                  ; current 1ED, (D808, bit 5)
	const EVENT_47E                                  ; current 1EE, (D808, bit 6)
	const EVENT_GOT_ITEMFINDER                       ; current 1EF, (D808, bit 7)
	const EVENT_GOT_TM39                             ; current 1F0, (D809, bit 0)
	const EVENT_481                                  ; current 1F1, (D809, bit 1)
	const EVENT_BEAT_ROUTE_12_TRAINER_0              ; current 1F2, (D809, bit 2)
	const EVENT_BEAT_ROUTE_12_TRAINER_1              ; current 1F3, (D809, bit 3)
	const EVENT_BEAT_ROUTE_12_TRAINER_2              ; current 1F4, (D809, bit 4)
	const EVENT_BEAT_ROUTE_12_TRAINER_3              ; current 1F5, (D809, bit 5)
	const EVENT_BEAT_ROUTE_12_TRAINER_4              ; current 1F6, (D809, bit 6)
	const EVENT_BEAT_ROUTE_12_TRAINER_5              ; current 1F7, (D809, bit 7)
	const EVENT_BEAT_ROUTE_12_TRAINER_6              ; current 1F8, (D80A, bit 0)
	const EVENT_489                                  ; current 1F9, (D80A, bit 1)
	const EVENT_48A                                  ; current 1FA, (D80A, bit 2)
	const EVENT_48B                                  ; current 1FB, (D80A, bit 3)
	const EVENT_48C                                  ; current 1FC, (D80A, bit 4)
	const EVENT_48D                                  ; current 1FD, (D80A, bit 5)
	const EVENT_FIGHT_ROUTE12_SNORLAX                ; current 1FE, (D80A, bit 6)
	const EVENT_BEAT_ROUTE12_SNORLAX                 ; current 1FF, (D80A, bit 7)
	const EVENT_490                                  ; current 200, (D80B, bit 0)
	const EVENT_BEAT_ROUTE_13_TRAINER_0              ; current 201, (D80B, bit 1)
	const EVENT_BEAT_ROUTE_13_TRAINER_1              ; current 202, (D80B, bit 2)
	const EVENT_BEAT_ROUTE_13_TRAINER_2              ; current 203, (D80B, bit 3)
	const EVENT_BEAT_ROUTE_13_TRAINER_3              ; current 204, (D80B, bit 4)
	const EVENT_BEAT_ROUTE_13_TRAINER_4              ; current 205, (D80B, bit 5)
	const EVENT_BEAT_ROUTE_13_TRAINER_5              ; current 206, (D80B, bit 6)
	const EVENT_BEAT_ROUTE_13_TRAINER_6              ; current 207, (D80B, bit 7)
	const EVENT_BEAT_ROUTE_13_TRAINER_7              ; current 208, (D80C, bit 0)
	const EVENT_BEAT_ROUTE_13_TRAINER_8              ; current 209, (D80C, bit 1)
	const EVENT_BEAT_ROUTE_13_TRAINER_9              ; current 20A, (D80C, bit 2)
	const EVENT_49B                                  ; current 20B, (D80C, bit 3)
	const EVENT_49C                                  ; current 20C, (D80C, bit 4)
	const EVENT_49D                                  ; current 20D, (D80C, bit 5)
	const EVENT_49E                                  ; current 20E, (D80C, bit 6)
	const EVENT_49F                                  ; current 20F, (D80C, bit 7)
	const EVENT_4A0                                  ; current 210, (D80D, bit 0)
	const EVENT_BEAT_ROUTE_14_TRAINER_0              ; current 211, (D80D, bit 1)
	const EVENT_BEAT_ROUTE_14_TRAINER_1              ; current 212, (D80D, bit 2)
	const EVENT_BEAT_ROUTE_14_TRAINER_2              ; current 213, (D80D, bit 3)
	const EVENT_BEAT_ROUTE_14_TRAINER_3              ; current 214, (D80D, bit 4)
	const EVENT_BEAT_ROUTE_14_TRAINER_4              ; current 215, (D80D, bit 5)
	const EVENT_BEAT_ROUTE_14_TRAINER_5              ; current 216, (D80D, bit 6)
	const EVENT_BEAT_ROUTE_14_TRAINER_6              ; current 217, (D80D, bit 7)
	const EVENT_BEAT_ROUTE_14_TRAINER_7              ; current 218, (D80E, bit 0)
	const EVENT_BEAT_ROUTE_14_TRAINER_8              ; current 219, (D80E, bit 1)
	const EVENT_BEAT_ROUTE_14_TRAINER_9              ; current 21A, (D80E, bit 2)
	const EVENT_4AB                                  ; current 21B, (D80E, bit 3)
	const EVENT_4AC                                  ; current 21C, (D80E, bit 4)
	const EVENT_4AD                                  ; current 21D, (D80E, bit 5)
	const EVENT_4AE                                  ; current 21E, (D80E, bit 6)
	const EVENT_4AF                                  ; current 21F, (D80E, bit 7)
	const EVENT_GOT_EXP_ALL                          ; current 220, (D80F, bit 0)
	const EVENT_BEAT_ROUTE_15_TRAINER_0              ; current 221, (D80F, bit 1)
	const EVENT_BEAT_ROUTE_15_TRAINER_1              ; current 222, (D80F, bit 2)
	const EVENT_BEAT_ROUTE_15_TRAINER_2              ; current 223, (D80F, bit 3)
	const EVENT_BEAT_ROUTE_15_TRAINER_3              ; current 224, (D80F, bit 4)
	const EVENT_BEAT_ROUTE_15_TRAINER_4              ; current 225, (D80F, bit 5)
	const EVENT_BEAT_ROUTE_15_TRAINER_5              ; current 226, (D80F, bit 6)
	const EVENT_BEAT_ROUTE_15_TRAINER_6              ; current 227, (D80F, bit 7)
	const EVENT_BEAT_ROUTE_15_TRAINER_7              ; current 228, (D810, bit 0)
	const EVENT_BEAT_ROUTE_15_TRAINER_8              ; current 229, (D810, bit 1)
	const EVENT_BEAT_ROUTE_15_TRAINER_9              ; current 22A, (D810, bit 2)
	const EVENT_4BB                                  ; current 22B, (D810, bit 3)
	const EVENT_4BC                                  ; current 22C, (D810, bit 4)
	const EVENT_4BD                                  ; current 22D, (D810, bit 5)
	const EVENT_4BE                                  ; current 22E, (D810, bit 6)
	const EVENT_4BF                                  ; current 22F, (D810, bit 7)
	const EVENT_4C0                                  ; current 230, (D811, bit 0)
	const EVENT_BEAT_ROUTE_16_TRAINER_0              ; current 231, (D811, bit 1)
	const EVENT_BEAT_ROUTE_16_TRAINER_1              ; current 232, (D811, bit 2)
	const EVENT_BEAT_ROUTE_16_TRAINER_2              ; current 233, (D811, bit 3)
	const EVENT_BEAT_ROUTE_16_TRAINER_3              ; current 234, (D811, bit 4)
	const EVENT_BEAT_ROUTE_16_TRAINER_4              ; current 235, (D811, bit 5)
	const EVENT_BEAT_ROUTE_16_TRAINER_5              ; current 236, (D811, bit 6)
	const EVENT_4C7                                  ; current 237, (D811, bit 7)
	const EVENT_FIGHT_ROUTE16_SNORLAX                ; current 238, (D812, bit 0)
	const EVENT_BEAT_ROUTE16_SNORLAX                 ; current 239, (D812, bit 1)
	const EVENT_4CA                                  ; current 23A, (D812, bit 2)
	const EVENT_4CB                                  ; current 23B, (D812, bit 3)
	const EVENT_4CC                                  ; current 23C, (D812, bit 4)
	const EVENT_4CD                                  ; current 23D, (D812, bit 5)
	const EVENT_GOT_HM02                             ; current 23E, (D812, bit 6)
	const EVENT_RESCUED_MR_FUJI                      ; current 23F, (D812, bit 7)
	const EVENT_4D0                                  ; current 240, (D813, bit 0)
	const EVENT_BEAT_ROUTE_17_TRAINER_0              ; current 241, (D813, bit 1)
	const EVENT_BEAT_ROUTE_17_TRAINER_1              ; current 242, (D813, bit 2)
	const EVENT_BEAT_ROUTE_17_TRAINER_2              ; current 243, (D813, bit 3)
	const EVENT_BEAT_ROUTE_17_TRAINER_3              ; current 244, (D813, bit 4)
	const EVENT_BEAT_ROUTE_17_TRAINER_4              ; current 245, (D813, bit 5)
	const EVENT_BEAT_ROUTE_17_TRAINER_5              ; current 246, (D813, bit 6)
	const EVENT_BEAT_ROUTE_17_TRAINER_6              ; current 247, (D813, bit 7)
	const EVENT_BEAT_ROUTE_17_TRAINER_7              ; current 248, (D814, bit 0)
	const EVENT_BEAT_ROUTE_17_TRAINER_8              ; current 249, (D814, bit 1)
	const EVENT_BEAT_ROUTE_17_TRAINER_9              ; current 24A, (D814, bit 2)
	const EVENT_4DB                                  ; current 24B, (D814, bit 3)
	const EVENT_4DC                                  ; current 24C, (D814, bit 4)
	const EVENT_4DD                                  ; current 24D, (D814, bit 5)
	const EVENT_4DE                                  ; current 24E, (D814, bit 6)
	const EVENT_4DF                                  ; current 24F, (D814, bit 7)
	const EVENT_4E0                                  ; current 250, (D815, bit 0)
	const EVENT_BEAT_ROUTE_18_TRAINER_0              ; current 251, (D815, bit 1)
	const EVENT_BEAT_ROUTE_18_TRAINER_1              ; current 252, (D815, bit 2)
	const EVENT_BEAT_ROUTE_18_TRAINER_2              ; current 253, (D815, bit 3)
	const EVENT_4E4                                  ; current 254, (D815, bit 4)
	const EVENT_4E5                                  ; current 255, (D815, bit 5)
	const EVENT_4E6                                  ; current 256, (D815, bit 6)
	const EVENT_4E7                                  ; current 257, (D815, bit 7)
	;const EVENT_4E8                                  ; inactive legacy 4E8; no current event slot
	;const EVENT_4E9                                  ; inactive legacy 4E9; no current event slot
	;const EVENT_4EA                                  ; inactive legacy 4EA; no current event slot
	;const EVENT_4EB                                  ; inactive legacy 4EB; no current event slot
	;const EVENT_4EC                                  ; inactive legacy 4EC; no current event slot
	;const EVENT_4ED                                  ; inactive legacy 4ED; no current event slot
	;const EVENT_4EE                                  ; inactive legacy 4EE; no current event slot
	;const EVENT_4EF                                  ; inactive legacy 4EF; no current event slot
	const EVENT_4F0                                  ; current 258, (D816, bit 0)
	const EVENT_BEAT_ROUTE_19_TRAINER_0              ; current 259, (D816, bit 1)
	const EVENT_BEAT_ROUTE_19_TRAINER_1              ; current 25A, (D816, bit 2)
	const EVENT_BEAT_ROUTE_19_TRAINER_2              ; current 25B, (D816, bit 3)
	const EVENT_BEAT_ROUTE_19_TRAINER_3              ; current 25C, (D816, bit 4)
	const EVENT_BEAT_ROUTE_19_TRAINER_4              ; current 25D, (D816, bit 5)
	const EVENT_BEAT_ROUTE_19_TRAINER_5              ; current 25E, (D816, bit 6)
	const EVENT_BEAT_ROUTE_19_TRAINER_6              ; current 25F, (D816, bit 7)
	const EVENT_BEAT_ROUTE_19_TRAINER_7              ; current 260, (D817, bit 0)
	const EVENT_BEAT_ROUTE_19_TRAINER_8              ; current 261, (D817, bit 1)
	const EVENT_BEAT_ROUTE_19_TRAINER_9              ; current 262, (D817, bit 2)
	const EVENT_4FB                                  ; current 263, (D817, bit 3)
	const EVENT_4FC                                  ; current 264, (D817, bit 4)
	const EVENT_4FD                                  ; current 265, (D817, bit 5)
	const EVENT_4FE                                  ; current 266, (D817, bit 6)
	const EVENT_4FF                                  ; current 267, (D817, bit 7)
	const EVENT_IN_SEAFOAM_ISLANDS                   ; current 268, (D818, bit 0)
	const EVENT_BEAT_ROUTE_20_TRAINER_0              ; current 269, (D818, bit 1)
	const EVENT_BEAT_ROUTE_20_TRAINER_1              ; current 26A, (D818, bit 2)
	const EVENT_BEAT_ROUTE_20_TRAINER_2              ; current 26B, (D818, bit 3)
	const EVENT_BEAT_ROUTE_20_TRAINER_3              ; current 26C, (D818, bit 4)
	const EVENT_BEAT_ROUTE_20_TRAINER_4              ; current 26D, (D818, bit 5)
	const EVENT_BEAT_ROUTE_20_TRAINER_5              ; current 26E, (D818, bit 6)
	const EVENT_BEAT_ROUTE_20_TRAINER_6              ; current 26F, (D818, bit 7)
	const EVENT_BEAT_ROUTE_20_TRAINER_7              ; current 270, (D819, bit 0)
	const EVENT_BEAT_ROUTE_20_TRAINER_8              ; current 271, (D819, bit 1)
	const EVENT_BEAT_ROUTE_20_TRAINER_9              ; current 272, (D819, bit 2)
	const EVENT_50B                                  ; current 273, (D819, bit 3)
	const EVENT_50C                                  ; current 274, (D819, bit 4)
	const EVENT_50D                                  ; current 275, (D819, bit 5)
	const EVENT_SEAFOAM1_BOULDER1_DOWN_HOLE          ; current 276, (D819, bit 6)
	const EVENT_SEAFOAM1_BOULDER2_DOWN_HOLE          ; current 277, (D819, bit 7)
	const EVENT_510                                  ; current 278, (D81A, bit 0)
	const EVENT_BEAT_ROUTE_21_TRAINER_0              ; current 279, (D81A, bit 1)
	const EVENT_BEAT_ROUTE_21_TRAINER_1              ; current 27A, (D81A, bit 2)
	const EVENT_BEAT_ROUTE_21_TRAINER_2              ; current 27B, (D81A, bit 3)
	const EVENT_BEAT_ROUTE_21_TRAINER_3              ; current 27C, (D81A, bit 4)
	const EVENT_BEAT_ROUTE_21_TRAINER_4              ; current 27D, (D81A, bit 5)
	const EVENT_BEAT_ROUTE_21_TRAINER_5              ; current 27E, (D81A, bit 6)
	const EVENT_BEAT_ROUTE_21_TRAINER_6              ; current 27F, (D81A, bit 7)
	const EVENT_BEAT_ROUTE_21_TRAINER_7              ; current 280, (D81B, bit 0)
	const EVENT_BEAT_ROUTE_21_TRAINER_8              ; current 281, (D81B, bit 1)
	const EVENT_51A                                  ; current 282, (D81B, bit 2)
	const EVENT_51B                                  ; current 283, (D81B, bit 3)
	const EVENT_51C                                  ; current 284, (D81B, bit 4)
	const EVENT_51D                                  ; current 285, (D81B, bit 5)
	const EVENT_51E                                  ; current 286, (D81B, bit 6)
	const EVENT_51F                                  ; current 287, (D81B, bit 7)
	const EVENT_1ST_ROUTE22_RIVAL_BATTLE             ; current 288, (D81C, bit 0)
	const EVENT_2ND_ROUTE22_RIVAL_BATTLE             ; current 289, (D81C, bit 1)
	const EVENT_522                                  ; current 28A, (D81C, bit 2)
	const EVENT_523                                  ; current 28B, (D81C, bit 3)
	const EVENT_524                                  ; current 28C, (D81C, bit 4)
	const EVENT_BEAT_ROUTE22_RIVAL_1ST_BATTLE        ; current 28D, (D81C, bit 5)
	const EVENT_BEAT_ROUTE22_RIVAL_2ND_BATTLE        ; current 28E, (D81C, bit 6)
	const EVENT_ROUTE22_RIVAL_WANTS_BATTLE           ; current 28F, (D81C, bit 7)
	;const EVENT_528                                  ; inactive legacy 528; no current event slot
	;const EVENT_529                                  ; inactive legacy 529; no current event slot
	;const EVENT_52A                                  ; inactive legacy 52A; no current event slot
	;const EVENT_52B                                  ; inactive legacy 52B; no current event slot
	;const EVENT_52C                                  ; inactive legacy 52C; no current event slot
	;const EVENT_52D                                  ; inactive legacy 52D; no current event slot
	;const EVENT_52E                                  ; inactive legacy 52E; no current event slot
	;const EVENT_52F                                  ; inactive legacy 52F; no current event slot
	const EVENT_PASSED_CASCADEBADGE_CHECK            ; current 290, (D81D, bit 0)
	const EVENT_PASSED_THUNDERBADGE_CHECK            ; current 291, (D81D, bit 1)
	const EVENT_PASSED_RAINBOWBADGE_CHECK            ; current 292, (D81D, bit 2)
	const EVENT_PASSED_SOULBADGE_CHECK               ; current 293, (D81D, bit 3)
	const EVENT_PASSED_MARSHBADGE_CHECK              ; current 294, (D81D, bit 4)
	const EVENT_PASSED_VOLCANOBADGE_CHECK            ; current 295, (D81D, bit 5)
	const EVENT_PASSED_EARTHBADGE_CHECK              ; current 296, (D81D, bit 6)
	const EVENT_537                                  ; current 297, (D81D, bit 7)
	const EVENT_VICTORY_ROAD_2_BOULDER_ON_SWITCH1    ; current 298, (D81E, bit 0)
	const EVENT_BEAT_VICTORY_ROAD_2_TRAINER_0        ; current 299, (D81E, bit 1)
	const EVENT_BEAT_VICTORY_ROAD_2_TRAINER_1        ; current 29A, (D81E, bit 2)
	const EVENT_BEAT_VICTORY_ROAD_2_TRAINER_2        ; current 29B, (D81E, bit 3)
	const EVENT_BEAT_VICTORY_ROAD_2_TRAINER_3        ; current 29C, (D81E, bit 4)
	const EVENT_BEAT_VICTORY_ROAD_2_TRAINER_4        ; current 29D, (D81E, bit 5)
	const EVENT_BEAT_MOLTRES                         ; current 29E, (D81E, bit 6)
	const EVENT_VICTORY_ROAD_2_BOULDER_ON_SWITCH2    ; current 29F, (D81E, bit 7)
	const EVENT_GOT_NUGGET                           ; current 2A0, (D81F, bit 0)
	const EVENT_BEAT_ROUTE24_ROCKET                  ; current 2A1, (D81F, bit 1)
	const EVENT_BEAT_ROUTE_24_TRAINER_0              ; current 2A2, (D81F, bit 2)
	const EVENT_BEAT_ROUTE_24_TRAINER_1              ; current 2A3, (D81F, bit 3)
	const EVENT_BEAT_ROUTE_24_TRAINER_2              ; current 2A4, (D81F, bit 4)
	const EVENT_BEAT_ROUTE_24_TRAINER_3              ; current 2A5, (D81F, bit 5)
	const EVENT_BEAT_ROUTE_24_TRAINER_4              ; current 2A6, (D81F, bit 6)
	const EVENT_BEAT_ROUTE_24_TRAINER_5              ; current 2A7, (D81F, bit 7)
	const EVENT_548                                  ; current 2A8, (D820, bit 0)
	const EVENT_NUGGET_REWARD_AVAILABLE              ; current 2A9, (D820, bit 1)
	const EVENT_54A                                  ; current 2AA, (D820, bit 2)
	const EVENT_54B                                  ; current 2AB, (D820, bit 3)
	const EVENT_54C                                  ; current 2AC, (D820, bit 4)
	const EVENT_54D                                  ; current 2AD, (D820, bit 5)
	const EVENT_54E                                  ; current 2AE, (D820, bit 6)
	const EVENT_54F                                  ; current 2AF, (D820, bit 7)
	const EVENT_MET_BILL                             ; current 2B0, (D821, bit 0)
	const EVENT_BEAT_ROUTE_25_TRAINER_0              ; current 2B1, (D821, bit 1)
	const EVENT_BEAT_ROUTE_25_TRAINER_1              ; current 2B2, (D821, bit 2)
	const EVENT_BEAT_ROUTE_25_TRAINER_2              ; current 2B3, (D821, bit 3)
	const EVENT_BEAT_ROUTE_25_TRAINER_3              ; current 2B4, (D821, bit 4)
	const EVENT_BEAT_ROUTE_25_TRAINER_4              ; current 2B5, (D821, bit 5)
	const EVENT_BEAT_ROUTE_25_TRAINER_5              ; current 2B6, (D821, bit 6)
	const EVENT_BEAT_ROUTE_25_TRAINER_6              ; current 2B7, (D821, bit 7)
	const EVENT_BEAT_ROUTE_25_TRAINER_7              ; current 2B8, (D822, bit 0)
	const EVENT_BEAT_ROUTE_25_TRAINER_8              ; current 2B9, (D822, bit 1)
	const EVENT_55A                                  ; current 2BA, (D822, bit 2)
	const EVENT_USED_CELL_SEPARATOR_ON_BILL          ; current 2BB, (D822, bit 3)
	const EVENT_GOT_SS_TICKET                        ; current 2BC, (D822, bit 4)
	const EVENT_MET_BILL_2                           ; current 2BD, (D822, bit 5)
	const EVENT_BILL_SAID_USE_CELL_SEPARATOR         ; current 2BE, (D822, bit 6)
	const EVENT_LEFT_BILLS_HOUSE_AFTER_HELPING       ; current 2BF, (D822, bit 7)
	const EVENT_560                                  ; current 2C0, (D823, bit 0)
	const EVENT_561                                  ; current 2C1, (D823, bit 1)
	const EVENT_BEAT_VIRIDIAN_FOREST_TRAINER_0       ; current 2C2, (D823, bit 2)
	const EVENT_BEAT_VIRIDIAN_FOREST_TRAINER_1       ; current 2C3, (D823, bit 3)
	const EVENT_BEAT_VIRIDIAN_FOREST_TRAINER_2       ; current 2C4, (D823, bit 4)
	const EVENT_565                                  ; current 2C5, (D823, bit 5)
	const EVENT_566                                  ; current 2C6, (D823, bit 6)
	const EVENT_567                                  ; current 2C7, (D823, bit 7)
	;const EVENT_568                                  ; inactive legacy 568; no current event slot
	;const EVENT_569                                  ; inactive legacy 569; no current event slot
	;const EVENT_56A                                  ; inactive legacy 56A; no current event slot
	;const EVENT_56B                                  ; inactive legacy 56B; no current event slot
	;const EVENT_56C                                  ; inactive legacy 56C; no current event slot
	;const EVENT_56D                                  ; inactive legacy 56D; no current event slot
	;const EVENT_56E                                  ; inactive legacy 56E; no current event slot
	;const EVENT_56F                                  ; inactive legacy 56F; no current event slot
	const EVENT_570                                  ; current 2C8, (D824, bit 0)
	const EVENT_BEAT_MT_MOON_1_TRAINER_0             ; current 2C9, (D824, bit 1)
	const EVENT_BEAT_MT_MOON_1_TRAINER_1             ; current 2CA, (D824, bit 2)
	const EVENT_BEAT_MT_MOON_1_TRAINER_2             ; current 2CB, (D824, bit 3)
	const EVENT_BEAT_MT_MOON_1_TRAINER_3             ; current 2CC, (D824, bit 4)
	const EVENT_BEAT_MT_MOON_1_TRAINER_4             ; current 2CD, (D824, bit 5)
	const EVENT_BEAT_MT_MOON_1_TRAINER_5             ; current 2CE, (D824, bit 6)
	const EVENT_BEAT_MT_MOON_1_TRAINER_6             ; current 2CF, (D824, bit 7)
	const EVENT_578                                  ; current 2D0, (D825, bit 0)
	const EVENT_BEAT_MT_MOON_EXIT_SUPER_NERD         ; current 2D1, (D825, bit 1)
	const EVENT_BEAT_MT_MOON_3_TRAINER_0             ; current 2D2, (D825, bit 2)
	const EVENT_BEAT_MT_MOON_3_TRAINER_1             ; current 2D3, (D825, bit 3)
	const EVENT_BEAT_MT_MOON_3_TRAINER_2             ; current 2D4, (D825, bit 4)
	const EVENT_BEAT_MT_MOON_3_TRAINER_3             ; current 2D5, (D825, bit 5)
	const EVENT_GOT_DOME_FOSSIL                      ; current 2D6, (D825, bit 6)
	const EVENT_GOT_HELIX_FOSSIL                     ; current 2D7, (D825, bit 7)
	;const EVENT_580                                  ; inactive legacy 580; no current event slot
	;const EVENT_581                                  ; inactive legacy 581; no current event slot
	;const EVENT_582                                  ; inactive legacy 582; no current event slot
	;const EVENT_583                                  ; inactive legacy 583; no current event slot
	;const EVENT_584                                  ; inactive legacy 584; no current event slot
	;const EVENT_585                                  ; inactive legacy 585; no current event slot
	;const EVENT_586                                  ; inactive legacy 586; no current event slot
	;const EVENT_587                                  ; inactive legacy 587; no current event slot
	;const EVENT_588                                  ; inactive legacy 588; no current event slot
	;const EVENT_589                                  ; inactive legacy 589; no current event slot
	;const EVENT_58A                                  ; inactive legacy 58A; no current event slot
	;const EVENT_58B                                  ; inactive legacy 58B; no current event slot
	;const EVENT_58C                                  ; inactive legacy 58C; no current event slot
	;const EVENT_58D                                  ; inactive legacy 58D; no current event slot
	;const EVENT_58E                                  ; inactive legacy 58E; no current event slot
	;const EVENT_58F                                  ; inactive legacy 58F; no current event slot
	;const EVENT_590                                  ; inactive legacy 590; no current event slot
	;const EVENT_591                                  ; inactive legacy 591; no current event slot
	;const EVENT_592                                  ; inactive legacy 592; no current event slot
	;const EVENT_593                                  ; inactive legacy 593; no current event slot
	;const EVENT_594                                  ; inactive legacy 594; no current event slot
	;const EVENT_595                                  ; inactive legacy 595; no current event slot
	;const EVENT_596                                  ; inactive legacy 596; no current event slot
	;const EVENT_597                                  ; inactive legacy 597; no current event slot
	;const EVENT_598                                  ; inactive legacy 598; no current event slot
	;const EVENT_599                                  ; inactive legacy 599; no current event slot
	;const EVENT_59A                                  ; inactive legacy 59A; no current event slot
	;const EVENT_59B                                  ; inactive legacy 59B; no current event slot
	;const EVENT_59C                                  ; inactive legacy 59C; no current event slot
	;const EVENT_59D                                  ; inactive legacy 59D; no current event slot
	;const EVENT_59E                                  ; inactive legacy 59E; no current event slot
	;const EVENT_59F                                  ; inactive legacy 59F; no current event slot
	;const EVENT_5A0                                  ; inactive legacy 5A0; no current event slot
	;const EVENT_5A1                                  ; inactive legacy 5A1; no current event slot
	;const EVENT_5A2                                  ; inactive legacy 5A2; no current event slot
	;const EVENT_5A3                                  ; inactive legacy 5A3; no current event slot
	;const EVENT_5A4                                  ; inactive legacy 5A4; no current event slot
	;const EVENT_5A5                                  ; inactive legacy 5A5; no current event slot
	;const EVENT_5A6                                  ; inactive legacy 5A6; no current event slot
	;const EVENT_5A7                                  ; inactive legacy 5A7; no current event slot
	;const EVENT_5A8                                  ; inactive legacy 5A8; no current event slot
	;const EVENT_5A9                                  ; inactive legacy 5A9; no current event slot
	;const EVENT_5AA                                  ; inactive legacy 5AA; no current event slot
	;const EVENT_5AB                                  ; inactive legacy 5AB; no current event slot
	;const EVENT_5AC                                  ; inactive legacy 5AC; no current event slot
	;const EVENT_5AD                                  ; inactive legacy 5AD; no current event slot
	;const EVENT_5AE                                  ; inactive legacy 5AE; no current event slot
	;const EVENT_5AF                                  ; inactive legacy 5AF; no current event slot
	;const EVENT_5B0                                  ; inactive legacy 5B0; no current event slot
	;const EVENT_5B1                                  ; inactive legacy 5B1; no current event slot
	;const EVENT_5B2                                  ; inactive legacy 5B2; no current event slot
	;const EVENT_5B3                                  ; inactive legacy 5B3; no current event slot
	;const EVENT_5B4                                  ; inactive legacy 5B4; no current event slot
	;const EVENT_5B5                                  ; inactive legacy 5B5; no current event slot
	;const EVENT_5B6                                  ; inactive legacy 5B6; no current event slot
	;const EVENT_5B7                                  ; inactive legacy 5B7; no current event slot
	;const EVENT_5B8                                  ; inactive legacy 5B8; no current event slot
	;const EVENT_5B9                                  ; inactive legacy 5B9; no current event slot
	;const EVENT_5BA                                  ; inactive legacy 5BA; no current event slot
	;const EVENT_5BB                                  ; inactive legacy 5BB; no current event slot
	;const EVENT_5BC                                  ; inactive legacy 5BC; no current event slot
	;const EVENT_5BD                                  ; inactive legacy 5BD; no current event slot
	;const EVENT_5BE                                  ; inactive legacy 5BE; no current event slot
	;const EVENT_5BF                                  ; inactive legacy 5BF; no current event slot
	const EVENT_5C0                                  ; current 2D8, (D826, bit 0)
	const EVENT_5C1                                  ; current 2D9, (D826, bit 1)
	const EVENT_5C2                                  ; current 2DA, (D826, bit 2)
	const EVENT_5C3                                  ; current 2DB, (D826, bit 3)
	const EVENT_BEAT_SS_ANNE_5_TRAINER_0             ; current 2DC, (D826, bit 4)
	const EVENT_BEAT_SS_ANNE_5_TRAINER_1             ; current 2DD, (D826, bit 5)
	const EVENT_5C6                                  ; current 2DE, (D826, bit 6)
	const EVENT_5C7                                  ; current 2DF, (D826, bit 7)
	;const EVENT_5C8                                  ; inactive legacy 5C8; no current event slot
	;const EVENT_5C9                                  ; inactive legacy 5C9; no current event slot
	;const EVENT_5CA                                  ; inactive legacy 5CA; no current event slot
	;const EVENT_5CB                                  ; inactive legacy 5CB; no current event slot
	;const EVENT_5CC                                  ; inactive legacy 5CC; no current event slot
	;const EVENT_5CD                                  ; inactive legacy 5CD; no current event slot
	;const EVENT_5CE                                  ; inactive legacy 5CE; no current event slot
	;const EVENT_5CF                                  ; inactive legacy 5CF; no current event slot
	;const EVENT_5D0                                  ; inactive legacy 5D0; no current event slot
	;const EVENT_5D1                                  ; inactive legacy 5D1; no current event slot
	;const EVENT_5D2                                  ; inactive legacy 5D2; no current event slot
	;const EVENT_5D3                                  ; inactive legacy 5D3; no current event slot
	;const EVENT_5D4                                  ; inactive legacy 5D4; no current event slot
	;const EVENT_5D5                                  ; inactive legacy 5D5; no current event slot
	;const EVENT_5D6                                  ; inactive legacy 5D6; no current event slot
	;const EVENT_5D7                                  ; inactive legacy 5D7; no current event slot
	;const EVENT_5D8                                  ; inactive legacy 5D8; no current event slot
	;const EVENT_5D9                                  ; inactive legacy 5D9; no current event slot
	;const EVENT_5DA                                  ; inactive legacy 5DA; no current event slot
	;const EVENT_5DB                                  ; inactive legacy 5DB; no current event slot
	;const EVENT_5DC                                  ; inactive legacy 5DC; no current event slot
	;const EVENT_5DD                                  ; inactive legacy 5DD; no current event slot
	;const EVENT_5DE                                  ; inactive legacy 5DE; no current event slot
	;const EVENT_5DF                                  ; inactive legacy 5DF; no current event slot
	const EVENT_GOT_HM01                             ; current 2E0, (D827, bit 0)
	const EVENT_RUBBED_CAPTAINS_BACK                 ; current 2E1, (D827, bit 1)
	const EVENT_SS_ANNE_LEFT                         ; current 2E2, (D827, bit 2)
	const EVENT_WALKED_PAST_GUARD_AFTER_SS_ANNE_LEFT ; current 2E3, (D827, bit 3)
	const EVENT_STARTED_WALKING_OUT_OF_DOCK          ; current 2E4, (D827, bit 4)
	const EVENT_WALKED_OUT_OF_DOCK                   ; current 2E5, (D827, bit 5)
	const EVENT_5E6                                  ; current 2E6, (D827, bit 6)
	const EVENT_5E7                                  ; current 2E7, (D827, bit 7)
	;const EVENT_5E8                                  ; inactive legacy 5E8; no current event slot
	;const EVENT_5E9                                  ; inactive legacy 5E9; no current event slot
	;const EVENT_5EA                                  ; inactive legacy 5EA; no current event slot
	;const EVENT_5EB                                  ; inactive legacy 5EB; no current event slot
	;const EVENT_5EC                                  ; inactive legacy 5EC; no current event slot
	;const EVENT_5ED                                  ; inactive legacy 5ED; no current event slot
	;const EVENT_5EE                                  ; inactive legacy 5EE; no current event slot
	;const EVENT_5EF                                  ; inactive legacy 5EF; no current event slot
	const EVENT_5F0                                  ; current 2E8, (D828, bit 0)
	const EVENT_BEAT_SS_ANNE_8_TRAINER_0             ; current 2E9, (D828, bit 1)
	const EVENT_BEAT_SS_ANNE_8_TRAINER_1             ; current 2EA, (D828, bit 2)
	const EVENT_BEAT_SS_ANNE_8_TRAINER_2             ; current 2EB, (D828, bit 3)
	const EVENT_BEAT_SS_ANNE_8_TRAINER_3             ; current 2EC, (D828, bit 4)
	const EVENT_5F5                                  ; current 2ED, (D828, bit 5)
	const EVENT_5F6                                  ; current 2EE, (D828, bit 6)
	const EVENT_5F7                                  ; current 2EF, (D828, bit 7)
	;const EVENT_5F8                                  ; inactive legacy 5F8; no current event slot
	;const EVENT_5F9                                  ; inactive legacy 5F9; no current event slot
	;const EVENT_5FA                                  ; inactive legacy 5FA; no current event slot
	;const EVENT_5FB                                  ; inactive legacy 5FB; no current event slot
	;const EVENT_5FC                                  ; inactive legacy 5FC; no current event slot
	;const EVENT_5FD                                  ; inactive legacy 5FD; no current event slot
	;const EVENT_5FE                                  ; inactive legacy 5FE; no current event slot
	;const EVENT_5FF                                  ; inactive legacy 5FF; no current event slot
	const EVENT_600                                  ; current 2F0, (D829, bit 0)
	const EVENT_BEAT_SS_ANNE_9_TRAINER_0             ; current 2F1, (D829, bit 1)
	const EVENT_BEAT_SS_ANNE_9_TRAINER_1             ; current 2F2, (D829, bit 2)
	const EVENT_BEAT_SS_ANNE_9_TRAINER_2             ; current 2F3, (D829, bit 3)
	const EVENT_BEAT_SS_ANNE_9_TRAINER_3             ; current 2F4, (D829, bit 4)
	const EVENT_605                                  ; current 2F5, (D829, bit 5)
	const EVENT_606                                  ; current 2F6, (D829, bit 6)
	const EVENT_607                                  ; current 2F7, (D829, bit 7)
	;const EVENT_608                                  ; inactive legacy 608; no current event slot
	;const EVENT_609                                  ; inactive legacy 609; no current event slot
	;const EVENT_60A                                  ; inactive legacy 60A; no current event slot
	;const EVENT_60B                                  ; inactive legacy 60B; no current event slot
	;const EVENT_60C                                  ; inactive legacy 60C; no current event slot
	;const EVENT_60D                                  ; inactive legacy 60D; no current event slot
	;const EVENT_60E                                  ; inactive legacy 60E; no current event slot
	;const EVENT_60F                                  ; inactive legacy 60F; no current event slot
	const EVENT_610                                  ; current 2F8, (D82A, bit 0)
	const EVENT_BEAT_SS_ANNE_10_TRAINER_0            ; current 2F9, (D82A, bit 1)
	const EVENT_BEAT_SS_ANNE_10_TRAINER_1            ; current 2FA, (D82A, bit 2)
	const EVENT_BEAT_SS_ANNE_10_TRAINER_2            ; current 2FB, (D82A, bit 3)
	const EVENT_BEAT_SS_ANNE_10_TRAINER_3            ; current 2FC, (D82A, bit 4)
	const EVENT_BEAT_SS_ANNE_10_TRAINER_4            ; current 2FD, (D82A, bit 5)
	const EVENT_BEAT_SS_ANNE_10_TRAINER_5            ; current 2FE, (D82A, bit 6)
	const EVENT_617                                  ; current 2FF, (D82A, bit 7)
	;const EVENT_618                                  ; inactive legacy 618; no current event slot
	;const EVENT_619                                  ; inactive legacy 619; no current event slot
	;const EVENT_61A                                  ; inactive legacy 61A; no current event slot
	;const EVENT_61B                                  ; inactive legacy 61B; no current event slot
	;const EVENT_61C                                  ; inactive legacy 61C; no current event slot
	;const EVENT_61D                                  ; inactive legacy 61D; no current event slot
	;const EVENT_61E                                  ; inactive legacy 61E; no current event slot
	;const EVENT_61F                                  ; inactive legacy 61F; no current event slot
	;const EVENT_620                                  ; inactive legacy 620; no current event slot
	;const EVENT_621                                  ; inactive legacy 621; no current event slot
	;const EVENT_622                                  ; inactive legacy 622; no current event slot
	;const EVENT_623                                  ; inactive legacy 623; no current event slot
	;const EVENT_624                                  ; inactive legacy 624; no current event slot
	;const EVENT_625                                  ; inactive legacy 625; no current event slot
	;const EVENT_626                                  ; inactive legacy 626; no current event slot
	;const EVENT_627                                  ; inactive legacy 627; no current event slot
	;const EVENT_628                                  ; inactive legacy 628; no current event slot
	;const EVENT_629                                  ; inactive legacy 629; no current event slot
	;const EVENT_62A                                  ; inactive legacy 62A; no current event slot
	;const EVENT_62B                                  ; inactive legacy 62B; no current event slot
	;const EVENT_62C                                  ; inactive legacy 62C; no current event slot
	;const EVENT_62D                                  ; inactive legacy 62D; no current event slot
	;const EVENT_62E                                  ; inactive legacy 62E; no current event slot
	;const EVENT_62F                                  ; inactive legacy 62F; no current event slot
	;const EVENT_630                                  ; inactive legacy 630; no current event slot
	;const EVENT_631                                  ; inactive legacy 631; no current event slot
	;const EVENT_632                                  ; inactive legacy 632; no current event slot
	;const EVENT_633                                  ; inactive legacy 633; no current event slot
	;const EVENT_634                                  ; inactive legacy 634; no current event slot
	;const EVENT_635                                  ; inactive legacy 635; no current event slot
	;const EVENT_636                                  ; inactive legacy 636; no current event slot
	;const EVENT_637                                  ; inactive legacy 637; no current event slot
	;const EVENT_638                                  ; inactive legacy 638; no current event slot
	;const EVENT_639                                  ; inactive legacy 639; no current event slot
	;const EVENT_63A                                  ; inactive legacy 63A; no current event slot
	;const EVENT_63B                                  ; inactive legacy 63B; no current event slot
	;const EVENT_63C                                  ; inactive legacy 63C; no current event slot
	;const EVENT_63D                                  ; inactive legacy 63D; no current event slot
	;const EVENT_63E                                  ; inactive legacy 63E; no current event slot
	;const EVENT_63F                                  ; inactive legacy 63F; no current event slot
	;const EVENT_640                                  ; inactive legacy 640; no current event slot
	;const EVENT_641                                  ; inactive legacy 641; no current event slot
	;const EVENT_642                                  ; inactive legacy 642; no current event slot
	;const EVENT_643                                  ; inactive legacy 643; no current event slot
	;const EVENT_644                                  ; inactive legacy 644; no current event slot
	;const EVENT_645                                  ; inactive legacy 645; no current event slot
	;const EVENT_646                                  ; inactive legacy 646; no current event slot
	;const EVENT_647                                  ; inactive legacy 647; no current event slot
	;const EVENT_648                                  ; inactive legacy 648; no current event slot
	;const EVENT_649                                  ; inactive legacy 649; no current event slot
	;const EVENT_64A                                  ; inactive legacy 64A; no current event slot
	;const EVENT_64B                                  ; inactive legacy 64B; no current event slot
	;const EVENT_64C                                  ; inactive legacy 64C; no current event slot
	;const EVENT_64D                                  ; inactive legacy 64D; no current event slot
	;const EVENT_64E                                  ; inactive legacy 64E; no current event slot
	;const EVENT_64F                                  ; inactive legacy 64F; no current event slot
	;const EVENT_650                                  ; inactive legacy 650; no current event slot
	;const EVENT_651                                  ; inactive legacy 651; no current event slot
	;const EVENT_652                                  ; inactive legacy 652; no current event slot
	;const EVENT_653                                  ; inactive legacy 653; no current event slot
	;const EVENT_654                                  ; inactive legacy 654; no current event slot
	;const EVENT_655                                  ; inactive legacy 655; no current event slot
	;const EVENT_656                                  ; inactive legacy 656; no current event slot
	;const EVENT_657                                  ; inactive legacy 657; no current event slot
	;const EVENT_658                                  ; inactive legacy 658; no current event slot
	;const EVENT_659                                  ; inactive legacy 659; no current event slot
	;const EVENT_65A                                  ; inactive legacy 65A; no current event slot
	;const EVENT_65B                                  ; inactive legacy 65B; no current event slot
	;const EVENT_65C                                  ; inactive legacy 65C; no current event slot
	;const EVENT_65D                                  ; inactive legacy 65D; no current event slot
	;const EVENT_65E                                  ; inactive legacy 65E; no current event slot
	;const EVENT_65F                                  ; inactive legacy 65F; no current event slot
	const EVENT_VICTORY_ROAD_3_BOULDER_ON_SWITCH1    ; current 300, (D82B, bit 0)
	const EVENT_BEAT_VICTORY_ROAD_3_TRAINER_0        ; current 301, (D82B, bit 1)
	const EVENT_BEAT_VICTORY_ROAD_3_TRAINER_1        ; current 302, (D82B, bit 2)
	const EVENT_BEAT_VICTORY_ROAD_3_TRAINER_2        ; current 303, (D82B, bit 3)
	const EVENT_BEAT_VICTORY_ROAD_3_TRAINER_3        ; current 304, (D82B, bit 4)
	const EVENT_665                                  ; current 305, (D82B, bit 5)
	const EVENT_VICTORY_ROAD_3_BOULDER_ON_SWITCH2    ; current 306, (D82B, bit 6)
	const EVENT_667                                  ; current 307, (D82B, bit 7)
	;const EVENT_668                                  ; inactive legacy 668; no current event slot
	;const EVENT_669                                  ; inactive legacy 669; no current event slot
	;const EVENT_66A                                  ; inactive legacy 66A; no current event slot
	;const EVENT_66B                                  ; inactive legacy 66B; no current event slot
	;const EVENT_66C                                  ; inactive legacy 66C; no current event slot
	;const EVENT_66D                                  ; inactive legacy 66D; no current event slot
	;const EVENT_66E                                  ; inactive legacy 66E; no current event slot
	;const EVENT_66F                                  ; inactive legacy 66F; no current event slot
	const EVENT_670                                  ; current 308, (D82C, bit 0)
	const EVENT_BEAT_ROCKET_HIDEOUT_1_TRAINER_0      ; current 309, (D82C, bit 1)
	const EVENT_BEAT_ROCKET_HIDEOUT_1_TRAINER_1      ; current 30A, (D82C, bit 2)
	const EVENT_BEAT_ROCKET_HIDEOUT_1_TRAINER_2      ; current 30B, (D82C, bit 3)
	const EVENT_BEAT_ROCKET_HIDEOUT_1_TRAINER_3      ; current 30C, (D82C, bit 4)
	const EVENT_BEAT_ROCKET_HIDEOUT_1_TRAINER_4      ; current 30D, (D82C, bit 5)
	const EVENT_676                                  ; current 30E, (D82C, bit 6)
	const EVENT_677                                  ; current 30F, (D82C, bit 7)
	const EVENT_678                                  ; current 310, (D82D, bit 0)
	const EVENT_679                                  ; current 311, (D82D, bit 1)
	const EVENT_67A                                  ; current 312, (D82D, bit 2)
	const EVENT_67B                                  ; current 313, (D82D, bit 3)
	const EVENT_67C                                  ; current 314, (D82D, bit 4)
	const EVENT_67D                                  ; current 315, (D82D, bit 5)
	const EVENT_67E                                  ; current 316, (D82D, bit 6)
	const EVENT_67F                                  ; current 317, (D82D, bit 7)
	const EVENT_680                                  ; current 318, (D82E, bit 0)
	const EVENT_BEAT_ROCKET_HIDEOUT_2_TRAINER_0      ; current 319, (D82E, bit 1)
	const EVENT_682                                  ; current 31A, (D82E, bit 2)
	const EVENT_683                                  ; current 31B, (D82E, bit 3)
	const EVENT_684                                  ; current 31C, (D82E, bit 4)
	const EVENT_685                                  ; current 31D, (D82E, bit 5)
	const EVENT_686                                  ; current 31E, (D82E, bit 6)
	const EVENT_687                                  ; current 31F, (D82E, bit 7)
	;const EVENT_688                                  ; inactive legacy 688; no current event slot
	;const EVENT_689                                  ; inactive legacy 689; no current event slot
	;const EVENT_68A                                  ; inactive legacy 68A; no current event slot
	;const EVENT_68B                                  ; inactive legacy 68B; no current event slot
	;const EVENT_68C                                  ; inactive legacy 68C; no current event slot
	;const EVENT_68D                                  ; inactive legacy 68D; no current event slot
	;const EVENT_68E                                  ; inactive legacy 68E; no current event slot
	;const EVENT_68F                                  ; inactive legacy 68F; no current event slot
	const EVENT_690                                  ; current 320, (D82F, bit 0)
	const EVENT_BEAT_ROCKET_HIDEOUT_3_TRAINER_0      ; current 321, (D82F, bit 1)
	const EVENT_BEAT_ROCKET_HIDEOUT_3_TRAINER_1      ; current 322, (D82F, bit 2)
	const EVENT_693                                  ; current 323, (D82F, bit 3)
	const EVENT_694                                  ; current 324, (D82F, bit 4)
	const EVENT_695                                  ; current 325, (D82F, bit 5)
	const EVENT_696                                  ; current 326, (D82F, bit 6)
	const EVENT_697                                  ; current 327, (D82F, bit 7)
	;const EVENT_698                                  ; inactive legacy 698; no current event slot
	;const EVENT_699                                  ; inactive legacy 699; no current event slot
	;const EVENT_69A                                  ; inactive legacy 69A; no current event slot
	;const EVENT_69B                                  ; inactive legacy 69B; no current event slot
	;const EVENT_69C                                  ; inactive legacy 69C; no current event slot
	;const EVENT_69D                                  ; inactive legacy 69D; no current event slot
	;const EVENT_69E                                  ; inactive legacy 69E; no current event slot
	;const EVENT_69F                                  ; inactive legacy 69F; no current event slot
	const EVENT_6A0                                  ; current 328, (D830, bit 0)
	const EVENT_6A1                                  ; current 329, (D830, bit 1)
	const EVENT_BEAT_ROCKET_HIDEOUT_4_TRAINER_0      ; current 32A, (D830, bit 2)
	const EVENT_BEAT_ROCKET_HIDEOUT_4_TRAINER_1      ; current 32B, (D830, bit 3)
	const EVENT_BEAT_ROCKET_HIDEOUT_4_TRAINER_2      ; current 32C, (D830, bit 4)
	const EVENT_ROCKET_HIDEOUT_4_DOOR_UNLOCKED       ; current 32D, (D830, bit 5)
	const EVENT_ROCKET_DROPPED_LIFT_KEY              ; current 32E, (D830, bit 6)
	const EVENT_BEAT_ROCKET_HIDEOUT_GIOVANNI         ; current 32F, (D830, bit 7)
	;const EVENT_6A8                                  ; inactive legacy 6A8; no current event slot
	;const EVENT_6A9                                  ; inactive legacy 6A9; no current event slot
	;const EVENT_6AA                                  ; inactive legacy 6AA; no current event slot
	;const EVENT_6AB                                  ; inactive legacy 6AB; no current event slot
	;const EVENT_6AC                                  ; inactive legacy 6AC; no current event slot
	;const EVENT_6AD                                  ; inactive legacy 6AD; no current event slot
	;const EVENT_6AE                                  ; inactive legacy 6AE; no current event slot
	;const EVENT_6AF                                  ; inactive legacy 6AF; no current event slot
	;const EVENT_6B0                                  ; inactive legacy 6B0; no current event slot
	;const EVENT_6B1                                  ; inactive legacy 6B1; no current event slot
	;const EVENT_6B2                                  ; inactive legacy 6B2; no current event slot
	;const EVENT_6B3                                  ; inactive legacy 6B3; no current event slot
	;const EVENT_6B4                                  ; inactive legacy 6B4; no current event slot
	;const EVENT_6B5                                  ; inactive legacy 6B5; no current event slot
	;const EVENT_6B6                                  ; inactive legacy 6B6; no current event slot
	;const EVENT_6B7                                  ; inactive legacy 6B7; no current event slot
	;const EVENT_6B8                                  ; inactive legacy 6B8; no current event slot
	;const EVENT_6B9                                  ; inactive legacy 6B9; no current event slot
	;const EVENT_6BA                                  ; inactive legacy 6BA; no current event slot
	;const EVENT_6BB                                  ; inactive legacy 6BB; no current event slot
	;const EVENT_6BC                                  ; inactive legacy 6BC; no current event slot
	;const EVENT_6BD                                  ; inactive legacy 6BD; no current event slot
	;const EVENT_6BE                                  ; inactive legacy 6BE; no current event slot
	;const EVENT_6BF                                  ; inactive legacy 6BF; no current event slot
	;const EVENT_6C0                                  ; inactive legacy 6C0; no current event slot
	;const EVENT_6C1                                  ; inactive legacy 6C1; no current event slot
	;const EVENT_6C2                                  ; inactive legacy 6C2; no current event slot
	;const EVENT_6C3                                  ; inactive legacy 6C3; no current event slot
	;const EVENT_6C4                                  ; inactive legacy 6C4; no current event slot
	;const EVENT_6C5                                  ; inactive legacy 6C5; no current event slot
	;const EVENT_6C6                                  ; inactive legacy 6C6; no current event slot
	;const EVENT_6C7                                  ; inactive legacy 6C7; no current event slot
	;const EVENT_6C8                                  ; inactive legacy 6C8; no current event slot
	;const EVENT_6C9                                  ; inactive legacy 6C9; no current event slot
	;const EVENT_6CA                                  ; inactive legacy 6CA; no current event slot
	;const EVENT_6CB                                  ; inactive legacy 6CB; no current event slot
	;const EVENT_6CC                                  ; inactive legacy 6CC; no current event slot
	;const EVENT_6CD                                  ; inactive legacy 6CD; no current event slot
	;const EVENT_6CE                                  ; inactive legacy 6CE; no current event slot
	;const EVENT_6CF                                  ; inactive legacy 6CF; no current event slot
	;const EVENT_6D0                                  ; inactive legacy 6D0; no current event slot
	;const EVENT_6D1                                  ; inactive legacy 6D1; no current event slot
	;const EVENT_6D2                                  ; inactive legacy 6D2; no current event slot
	;const EVENT_6D3                                  ; inactive legacy 6D3; no current event slot
	;const EVENT_6D4                                  ; inactive legacy 6D4; no current event slot
	;const EVENT_6D5                                  ; inactive legacy 6D5; no current event slot
	;const EVENT_6D6                                  ; inactive legacy 6D6; no current event slot
	;const EVENT_6D7                                  ; inactive legacy 6D7; no current event slot
	;const EVENT_6D8                                  ; inactive legacy 6D8; no current event slot
	;const EVENT_6D9                                  ; inactive legacy 6D9; no current event slot
	;const EVENT_6DA                                  ; inactive legacy 6DA; no current event slot
	;const EVENT_6DB                                  ; inactive legacy 6DB; no current event slot
	;const EVENT_6DC                                  ; inactive legacy 6DC; no current event slot
	;const EVENT_6DD                                  ; inactive legacy 6DD; no current event slot
	;const EVENT_6DE                                  ; inactive legacy 6DE; no current event slot
	;const EVENT_6DF                                  ; inactive legacy 6DF; no current event slot
	;const EVENT_6E0                                  ; inactive legacy 6E0; no current event slot
	;const EVENT_6E1                                  ; inactive legacy 6E1; no current event slot
	;const EVENT_6E2                                  ; inactive legacy 6E2; no current event slot
	;const EVENT_6E3                                  ; inactive legacy 6E3; no current event slot
	;const EVENT_6E4                                  ; inactive legacy 6E4; no current event slot
	;const EVENT_6E5                                  ; inactive legacy 6E5; no current event slot
	;const EVENT_6E6                                  ; inactive legacy 6E6; no current event slot
	;const EVENT_6E7                                  ; inactive legacy 6E7; no current event slot
	;const EVENT_6E8                                  ; inactive legacy 6E8; no current event slot
	;const EVENT_6E9                                  ; inactive legacy 6E9; no current event slot
	;const EVENT_6EA                                  ; inactive legacy 6EA; no current event slot
	;const EVENT_6EB                                  ; inactive legacy 6EB; no current event slot
	;const EVENT_6EC                                  ; inactive legacy 6EC; no current event slot
	;const EVENT_6ED                                  ; inactive legacy 6ED; no current event slot
	;const EVENT_6EE                                  ; inactive legacy 6EE; no current event slot
	;const EVENT_6EF                                  ; inactive legacy 6EF; no current event slot
	const EVENT_6F0                                  ; current 330, (D831, bit 0)
	const EVENT_6F1                                  ; current 331, (D831, bit 1)
	const EVENT_BEAT_SILPH_CO_2F_TRAINER_0           ; current 332, (D831, bit 2)
	const EVENT_BEAT_SILPH_CO_2F_TRAINER_1           ; current 333, (D831, bit 3)
	const EVENT_BEAT_SILPH_CO_2F_TRAINER_2           ; current 334, (D831, bit 4)
	const EVENT_BEAT_SILPH_CO_2F_TRAINER_3           ; current 335, (D831, bit 5)
	const EVENT_6F6                                  ; current 336, (D831, bit 6)
	const EVENT_6F7                                  ; current 337, (D831, bit 7)
	const EVENT_6F8                                  ; current 338, (D832, bit 0)
	const EVENT_6F9                                  ; current 339, (D832, bit 1)
	const EVENT_6FA                                  ; current 33A, (D832, bit 2)
	const EVENT_6FB                                  ; current 33B, (D832, bit 3)
	const EVENT_6FC                                  ; current 33C, (D832, bit 4)
	const EVENT_SILPH_CO_2_UNLOCKED_DOOR1            ; current 33D, (D832, bit 5)
	const EVENT_SILPH_CO_2_UNLOCKED_DOOR2            ; current 33E, (D832, bit 6)
	const EVENT_GOT_TM36                             ; current 33F, (D832, bit 7)
	const EVENT_700                                  ; current 340, (D833, bit 0)
	const EVENT_701                                  ; current 341, (D833, bit 1)
	const EVENT_BEAT_SILPH_CO_3F_TRAINER_0           ; current 342, (D833, bit 2)
	const EVENT_BEAT_SILPH_CO_3F_TRAINER_1           ; current 343, (D833, bit 3)
	const EVENT_704                                  ; current 344, (D833, bit 4)
	const EVENT_705                                  ; current 345, (D833, bit 5)
	const EVENT_706                                  ; current 346, (D833, bit 6)
	const EVENT_707                                  ; current 347, (D833, bit 7)
	const EVENT_SILPH_CO_3_UNLOCKED_DOOR1            ; current 348, (D834, bit 0)
	const EVENT_SILPH_CO_3_UNLOCKED_DOOR2            ; current 349, (D834, bit 1)
	const EVENT_70A                                  ; current 34A, (D834, bit 2)
	const EVENT_70B                                  ; current 34B, (D834, bit 3)
	const EVENT_70C                                  ; current 34C, (D834, bit 4)
	const EVENT_70D                                  ; current 34D, (D834, bit 5)
	const EVENT_70E                                  ; current 34E, (D834, bit 6)
	const EVENT_70F                                  ; current 34F, (D834, bit 7)
	const EVENT_710                                  ; current 350, (D835, bit 0)
	const EVENT_711                                  ; current 351, (D835, bit 1)
	const EVENT_BEAT_SILPH_CO_4F_TRAINER_0           ; current 352, (D835, bit 2)
	const EVENT_BEAT_SILPH_CO_4F_TRAINER_1           ; current 353, (D835, bit 3)
	const EVENT_BEAT_SILPH_CO_4F_TRAINER_2           ; current 354, (D835, bit 4)
	const EVENT_715                                  ; current 355, (D835, bit 5)
	const EVENT_716                                  ; current 356, (D835, bit 6)
	const EVENT_717                                  ; current 357, (D835, bit 7)
	const EVENT_SILPH_CO_4_UNLOCKED_DOOR1            ; current 358, (D836, bit 0)
	const EVENT_SILPH_CO_4_UNLOCKED_DOOR2            ; current 359, (D836, bit 1)
	const EVENT_71A                                  ; current 35A, (D836, bit 2)
	const EVENT_71B                                  ; current 35B, (D836, bit 3)
	const EVENT_71C                                  ; current 35C, (D836, bit 4)
	const EVENT_71D                                  ; current 35D, (D836, bit 5)
	const EVENT_71E                                  ; current 35E, (D836, bit 6)
	const EVENT_71F                                  ; current 35F, (D836, bit 7)
	const EVENT_720                                  ; current 360, (D837, bit 0)
	const EVENT_721                                  ; current 361, (D837, bit 1)
	const EVENT_BEAT_SILPH_CO_5F_TRAINER_0           ; current 362, (D837, bit 2)
	const EVENT_BEAT_SILPH_CO_5F_TRAINER_1           ; current 363, (D837, bit 3)
	const EVENT_BEAT_SILPH_CO_5F_TRAINER_2           ; current 364, (D837, bit 4)
	const EVENT_BEAT_SILPH_CO_5F_TRAINER_3           ; current 365, (D837, bit 5)
	const EVENT_726                                  ; current 366, (D837, bit 6)
	const EVENT_727                                  ; current 367, (D837, bit 7)
	const EVENT_SILPH_CO_5_UNLOCKED_DOOR1            ; current 368, (D838, bit 0)
	const EVENT_SILPH_CO_5_UNLOCKED_DOOR2            ; current 369, (D838, bit 1)
	const EVENT_SILPH_CO_5_UNLOCKED_DOOR3            ; current 36A, (D838, bit 2)
	const EVENT_72B                                  ; current 36B, (D838, bit 3)
	const EVENT_72C                                  ; current 36C, (D838, bit 4)
	const EVENT_72D                                  ; current 36D, (D838, bit 5)
	const EVENT_72E                                  ; current 36E, (D838, bit 6)
	const EVENT_72F                                  ; current 36F, (D838, bit 7)
	const EVENT_730                                  ; current 370, (D839, bit 0)
	const EVENT_731                                  ; current 371, (D839, bit 1)
	const EVENT_732                                  ; current 372, (D839, bit 2)
	const EVENT_733                                  ; current 373, (D839, bit 3)
	const EVENT_734                                  ; current 374, (D839, bit 4)
	const EVENT_735                                  ; current 375, (D839, bit 5)
	const EVENT_BEAT_SILPH_CO_6F_TRAINER_0           ; current 376, (D839, bit 6)
	const EVENT_BEAT_SILPH_CO_6F_TRAINER_1           ; current 377, (D839, bit 7)
	const EVENT_BEAT_SILPH_CO_6F_TRAINER_2           ; current 378, (D83A, bit 0)
	const EVENT_739                                  ; current 379, (D83A, bit 1)
	const EVENT_73A                                  ; current 37A, (D83A, bit 2)
	const EVENT_73B                                  ; current 37B, (D83A, bit 3)
	const EVENT_73C                                  ; current 37C, (D83A, bit 4)
	const EVENT_73D                                  ; current 37D, (D83A, bit 5)
	const EVENT_73E                                  ; current 37E, (D83A, bit 6)
	const EVENT_SILPH_CO_6_UNLOCKED_DOOR             ; current 37F, (D83A, bit 7)
	const EVENT_BEAT_SILPH_CO_RIVAL                  ; current 380, (D83B, bit 0)
	const EVENT_741                                  ; current 381, (D83B, bit 1)
	const EVENT_742                                  ; current 382, (D83B, bit 2)
	const EVENT_743                                  ; current 383, (D83B, bit 3)
	const EVENT_744                                  ; current 384, (D83B, bit 4)
	const EVENT_BEAT_SILPH_CO_7F_TRAINER_0           ; current 385, (D83B, bit 5)
	const EVENT_BEAT_SILPH_CO_7F_TRAINER_1           ; current 386, (D83B, bit 6)
	const EVENT_BEAT_SILPH_CO_7F_TRAINER_2           ; current 387, (D83B, bit 7)
	const EVENT_BEAT_SILPH_CO_7F_TRAINER_3           ; current 388, (D83C, bit 0)
	const EVENT_749                                  ; current 389, (D83C, bit 1)
	const EVENT_74A                                  ; current 38A, (D83C, bit 2)
	const EVENT_74B                                  ; current 38B, (D83C, bit 3)
	const EVENT_SILPH_CO_7_UNLOCKED_DOOR1            ; current 38C, (D83C, bit 4)
	const EVENT_SILPH_CO_7_UNLOCKED_DOOR2            ; current 38D, (D83C, bit 5)
	const EVENT_SILPH_CO_7_UNLOCKED_DOOR3            ; current 38E, (D83C, bit 6)
	const EVENT_74F                                  ; current 38F, (D83C, bit 7)
	const EVENT_750                                  ; current 390, (D83D, bit 0)
	const EVENT_751                                  ; current 391, (D83D, bit 1)
	const EVENT_BEAT_SILPH_CO_8F_TRAINER_0           ; current 392, (D83D, bit 2)
	const EVENT_BEAT_SILPH_CO_8F_TRAINER_1           ; current 393, (D83D, bit 3)
	const EVENT_BEAT_SILPH_CO_8F_TRAINER_2           ; current 394, (D83D, bit 4)
	const EVENT_755                                  ; current 395, (D83D, bit 5)
	const EVENT_756                                  ; current 396, (D83D, bit 6)
	const EVENT_757                                  ; current 397, (D83D, bit 7)
	const EVENT_SILPH_CO_8_UNLOCKED_DOOR             ; current 398, (D83E, bit 0)
	const EVENT_759                                  ; current 399, (D83E, bit 1)
	const EVENT_75A                                  ; current 39A, (D83E, bit 2)
	const EVENT_75B                                  ; current 39B, (D83E, bit 3)
	const EVENT_75C                                  ; current 39C, (D83E, bit 4)
	const EVENT_75D                                  ; current 39D, (D83E, bit 5)
	const EVENT_75E                                  ; current 39E, (D83E, bit 6)
	const EVENT_75F                                  ; current 39F, (D83E, bit 7)
	const EVENT_760                                  ; current 3A0, (D83F, bit 0)
	const EVENT_761                                  ; current 3A1, (D83F, bit 1)
	const EVENT_BEAT_SILPH_CO_9F_TRAINER_0           ; current 3A2, (D83F, bit 2)
	const EVENT_BEAT_SILPH_CO_9F_TRAINER_1           ; current 3A3, (D83F, bit 3)
	const EVENT_BEAT_SILPH_CO_9F_TRAINER_2           ; current 3A4, (D83F, bit 4)
	const EVENT_765                                  ; current 3A5, (D83F, bit 5)
	const EVENT_766                                  ; current 3A6, (D83F, bit 6)
	const EVENT_767                                  ; current 3A7, (D83F, bit 7)
	const EVENT_SILPH_CO_9_UNLOCKED_DOOR1            ; current 3A8, (D840, bit 0)
	const EVENT_SILPH_CO_9_UNLOCKED_DOOR2            ; current 3A9, (D840, bit 1)
	const EVENT_SILPH_CO_9_UNLOCKED_DOOR3            ; current 3AA, (D840, bit 2)
	const EVENT_SILPH_CO_9_UNLOCKED_DOOR4            ; current 3AB, (D840, bit 3)
	const EVENT_76C                                  ; current 3AC, (D840, bit 4)
	const EVENT_76D                                  ; current 3AD, (D840, bit 5)
	const EVENT_76E                                  ; current 3AE, (D840, bit 6)
	const EVENT_76F                                  ; current 3AF, (D840, bit 7)
	const EVENT_770                                  ; current 3B0, (D841, bit 0)
	const EVENT_BEAT_SILPH_CO_10F_TRAINER_0          ; current 3B1, (D841, bit 1)
	const EVENT_BEAT_SILPH_CO_10F_TRAINER_1          ; current 3B2, (D841, bit 2)
	const EVENT_773                                  ; current 3B3, (D841, bit 3)
	const EVENT_774                                  ; current 3B4, (D841, bit 4)
	const EVENT_775                                  ; current 3B5, (D841, bit 5)
	const EVENT_776                                  ; current 3B6, (D841, bit 6)
	const EVENT_777                                  ; current 3B7, (D841, bit 7)
	const EVENT_SILPH_CO_10_UNLOCKED_DOOR            ; current 3B8, (D842, bit 0)
	const EVENT_779                                  ; current 3B9, (D842, bit 1)
	const EVENT_77A                                  ; current 3BA, (D842, bit 2)
	const EVENT_77B                                  ; current 3BB, (D842, bit 3)
	const EVENT_77C                                  ; current 3BC, (D842, bit 4)
	const EVENT_77D                                  ; current 3BD, (D842, bit 5)
	const EVENT_77E                                  ; current 3BE, (D842, bit 6)
	const EVENT_77F                                  ; current 3BF, (D842, bit 7)
	const EVENT_780                                  ; current 3C0, (D843, bit 0)
	const EVENT_781                                  ; current 3C1, (D843, bit 1)
	const EVENT_782                                  ; current 3C2, (D843, bit 2)
	const EVENT_783                                  ; current 3C3, (D843, bit 3)
	const EVENT_BEAT_SILPH_CO_11F_TRAINER_0          ; current 3C4, (D843, bit 4)
	const EVENT_BEAT_SILPH_CO_11F_TRAINER_1          ; current 3C5, (D843, bit 5)
	const EVENT_786                                  ; current 3C6, (D843, bit 6)
	const EVENT_787                                  ; current 3C7, (D843, bit 7)
	const EVENT_SILPH_CO_11_UNLOCKED_DOOR            ; current 3C8, (D844, bit 0)
	const EVENT_789                                  ; current 3C9, (D844, bit 1)
	const EVENT_78A                                  ; current 3CA, (D844, bit 2)
	const EVENT_78B                                  ; current 3CB, (D844, bit 3)
	const EVENT_78C                                  ; current 3CC, (D844, bit 4)
	const EVENT_GOT_MASTER_BALL                      ; current 3CD, (D844, bit 5)
	const EVENT_78E                                  ; current 3CE, (D844, bit 6)
	const EVENT_BEAT_SILPH_CO_GIOVANNI               ; current 3CF, (D844, bit 7)
	;const EVENT_790                                  ; inactive legacy 790; no current event slot
	;const EVENT_791                                  ; inactive legacy 791; no current event slot
	;const EVENT_792                                  ; inactive legacy 792; no current event slot
	;const EVENT_793                                  ; inactive legacy 793; no current event slot
	;const EVENT_794                                  ; inactive legacy 794; no current event slot
	;const EVENT_795                                  ; inactive legacy 795; no current event slot
	;const EVENT_796                                  ; inactive legacy 796; no current event slot
	;const EVENT_797                                  ; inactive legacy 797; no current event slot
	;const EVENT_798                                  ; inactive legacy 798; no current event slot
	;const EVENT_799                                  ; inactive legacy 799; no current event slot
	;const EVENT_79A                                  ; inactive legacy 79A; no current event slot
	;const EVENT_79B                                  ; inactive legacy 79B; no current event slot
	;const EVENT_79C                                  ; inactive legacy 79C; no current event slot
	;const EVENT_79D                                  ; inactive legacy 79D; no current event slot
	;const EVENT_79E                                  ; inactive legacy 79E; no current event slot
	;const EVENT_79F                                  ; inactive legacy 79F; no current event slot
	;const EVENT_7A0                                  ; inactive legacy 7A0; no current event slot
	;const EVENT_7A1                                  ; inactive legacy 7A1; no current event slot
	;const EVENT_7A2                                  ; inactive legacy 7A2; no current event slot
	;const EVENT_7A3                                  ; inactive legacy 7A3; no current event slot
	;const EVENT_7A4                                  ; inactive legacy 7A4; no current event slot
	;const EVENT_7A5                                  ; inactive legacy 7A5; no current event slot
	;const EVENT_7A6                                  ; inactive legacy 7A6; no current event slot
	;const EVENT_7A7                                  ; inactive legacy 7A7; no current event slot
	;const EVENT_7A8                                  ; inactive legacy 7A8; no current event slot
	;const EVENT_7A9                                  ; inactive legacy 7A9; no current event slot
	;const EVENT_7AA                                  ; inactive legacy 7AA; no current event slot
	;const EVENT_7AB                                  ; inactive legacy 7AB; no current event slot
	;const EVENT_7AC                                  ; inactive legacy 7AC; no current event slot
	;const EVENT_7AD                                  ; inactive legacy 7AD; no current event slot
	;const EVENT_7AE                                  ; inactive legacy 7AE; no current event slot
	;const EVENT_7AF                                  ; inactive legacy 7AF; no current event slot
	;const EVENT_7B0                                  ; inactive legacy 7B0; no current event slot
	;const EVENT_7B1                                  ; inactive legacy 7B1; no current event slot
	;const EVENT_7B2                                  ; inactive legacy 7B2; no current event slot
	;const EVENT_7B3                                  ; inactive legacy 7B3; no current event slot
	;const EVENT_7B4                                  ; inactive legacy 7B4; no current event slot
	;const EVENT_7B5                                  ; inactive legacy 7B5; no current event slot
	;const EVENT_7B6                                  ; inactive legacy 7B6; no current event slot
	;const EVENT_7B7                                  ; inactive legacy 7B7; no current event slot
	;const EVENT_7B8                                  ; inactive legacy 7B8; no current event slot
	;const EVENT_7B9                                  ; inactive legacy 7B9; no current event slot
	;const EVENT_7BA                                  ; inactive legacy 7BA; no current event slot
	;const EVENT_7BB                                  ; inactive legacy 7BB; no current event slot
	;const EVENT_7BC                                  ; inactive legacy 7BC; no current event slot
	;const EVENT_7BD                                  ; inactive legacy 7BD; no current event slot
	;const EVENT_7BE                                  ; inactive legacy 7BE; no current event slot
	;const EVENT_7BF                                  ; inactive legacy 7BF; no current event slot
	;const EVENT_7C0                                  ; inactive legacy 7C0; no current event slot
	;const EVENT_7C1                                  ; inactive legacy 7C1; no current event slot
	;const EVENT_7C2                                  ; inactive legacy 7C2; no current event slot
	;const EVENT_7C3                                  ; inactive legacy 7C3; no current event slot
	;const EVENT_7C4                                  ; inactive legacy 7C4; no current event slot
	;const EVENT_7C5                                  ; inactive legacy 7C5; no current event slot
	;const EVENT_7C6                                  ; inactive legacy 7C6; no current event slot
	;const EVENT_7C7                                  ; inactive legacy 7C7; no current event slot
	;const EVENT_7C8                                  ; inactive legacy 7C8; no current event slot
	;const EVENT_7C9                                  ; inactive legacy 7C9; no current event slot
	;const EVENT_7CA                                  ; inactive legacy 7CA; no current event slot
	;const EVENT_7CB                                  ; inactive legacy 7CB; no current event slot
	;const EVENT_7CC                                  ; inactive legacy 7CC; no current event slot
	;const EVENT_7CD                                  ; inactive legacy 7CD; no current event slot
	;const EVENT_7CE                                  ; inactive legacy 7CE; no current event slot
	;const EVENT_7CF                                  ; inactive legacy 7CF; no current event slot
	;const EVENT_7D0                                  ; inactive legacy 7D0; no current event slot
	;const EVENT_7D1                                  ; inactive legacy 7D1; no current event slot
	;const EVENT_7D2                                  ; inactive legacy 7D2; no current event slot
	;const EVENT_7D3                                  ; inactive legacy 7D3; no current event slot
	;const EVENT_7D4                                  ; inactive legacy 7D4; no current event slot
	;const EVENT_7D5                                  ; inactive legacy 7D5; no current event slot
	;const EVENT_7D6                                  ; inactive legacy 7D6; no current event slot
	;const EVENT_7D7                                  ; inactive legacy 7D7; no current event slot
	;const EVENT_7D8                                  ; inactive legacy 7D8; no current event slot
	;const EVENT_7D9                                  ; inactive legacy 7D9; no current event slot
	;const EVENT_7DA                                  ; inactive legacy 7DA; no current event slot
	;const EVENT_7DB                                  ; inactive legacy 7DB; no current event slot
	;const EVENT_7DC                                  ; inactive legacy 7DC; no current event slot
	;const EVENT_7DD                                  ; inactive legacy 7DD; no current event slot
	;const EVENT_7DE                                  ; inactive legacy 7DE; no current event slot
	;const EVENT_7DF                                  ; inactive legacy 7DF; no current event slot
	;const EVENT_7E0                                  ; inactive legacy 7E0; no current event slot
	;const EVENT_7E1                                  ; inactive legacy 7E1; no current event slot
	;const EVENT_7E2                                  ; inactive legacy 7E2; no current event slot
	;const EVENT_7E3                                  ; inactive legacy 7E3; no current event slot
	;const EVENT_7E4                                  ; inactive legacy 7E4; no current event slot
	;const EVENT_7E5                                  ; inactive legacy 7E5; no current event slot
	;const EVENT_7E6                                  ; inactive legacy 7E6; no current event slot
	;const EVENT_7E7                                  ; inactive legacy 7E7; no current event slot
	;const EVENT_7E8                                  ; inactive legacy 7E8; no current event slot
	;const EVENT_7E9                                  ; inactive legacy 7E9; no current event slot
	;const EVENT_7EA                                  ; inactive legacy 7EA; no current event slot
	;const EVENT_7EB                                  ; inactive legacy 7EB; no current event slot
	;const EVENT_7EC                                  ; inactive legacy 7EC; no current event slot
	;const EVENT_7ED                                  ; inactive legacy 7ED; no current event slot
	;const EVENT_7EE                                  ; inactive legacy 7EE; no current event slot
	;const EVENT_7EF                                  ; inactive legacy 7EF; no current event slot
	;const EVENT_7F0                                  ; inactive legacy 7F0; no current event slot
	;const EVENT_7F1                                  ; inactive legacy 7F1; no current event slot
	;const EVENT_7F2                                  ; inactive legacy 7F2; no current event slot
	;const EVENT_7F3                                  ; inactive legacy 7F3; no current event slot
	;const EVENT_7F4                                  ; inactive legacy 7F4; no current event slot
	;const EVENT_7F5                                  ; inactive legacy 7F5; no current event slot
	;const EVENT_7F6                                  ; inactive legacy 7F6; no current event slot
	;const EVENT_7F7                                  ; inactive legacy 7F7; no current event slot
	;const EVENT_7F8                                  ; inactive legacy 7F8; no current event slot
	;const EVENT_7F9                                  ; inactive legacy 7F9; no current event slot
	;const EVENT_7FA                                  ; inactive legacy 7FA; no current event slot
	;const EVENT_7FB                                  ; inactive legacy 7FB; no current event slot
	;const EVENT_7FC                                  ; inactive legacy 7FC; no current event slot
	;const EVENT_7FD                                  ; inactive legacy 7FD; no current event slot
	;const EVENT_7FE                                  ; inactive legacy 7FE; no current event slot
	;const EVENT_7FF                                  ; inactive legacy 7FF; no current event slot
	const EVENT_800                                  ; current 3D0, (D845, bit 0)
	const EVENT_BEAT_MANSION_2_TRAINER_0             ; current 3D1, (D845, bit 1)
	const EVENT_802                                  ; current 3D2, (D845, bit 2)
	const EVENT_803                                  ; current 3D3, (D845, bit 3)
	const EVENT_804                                  ; current 3D4, (D845, bit 4)
	const EVENT_805                                  ; current 3D5, (D845, bit 5)
	const EVENT_806                                  ; current 3D6, (D845, bit 6)
	const EVENT_807                                  ; current 3D7, (D845, bit 7)
	;const EVENT_808                                  ; inactive legacy 808; no current event slot
	;const EVENT_809                                  ; inactive legacy 809; no current event slot
	;const EVENT_80A                                  ; inactive legacy 80A; no current event slot
	;const EVENT_80B                                  ; inactive legacy 80B; no current event slot
	;const EVENT_80C                                  ; inactive legacy 80C; no current event slot
	;const EVENT_80D                                  ; inactive legacy 80D; no current event slot
	;const EVENT_80E                                  ; inactive legacy 80E; no current event slot
	;const EVENT_80F                                  ; inactive legacy 80F; no current event slot
	const EVENT_810                                  ; current 3D8, (D846, bit 0)
	const EVENT_BEAT_MANSION_3_TRAINER_0             ; current 3D9, (D846, bit 1)
	const EVENT_BEAT_MANSION_3_TRAINER_1             ; current 3DA, (D846, bit 2)
	const EVENT_813                                  ; current 3DB, (D846, bit 3)
	const EVENT_814                                  ; current 3DC, (D846, bit 4)
	const EVENT_815                                  ; current 3DD, (D846, bit 5)
	const EVENT_816                                  ; current 3DE, (D846, bit 6)
	const EVENT_817                                  ; current 3DF, (D846, bit 7)
	;const EVENT_818                                  ; inactive legacy 818; no current event slot
	;const EVENT_819                                  ; inactive legacy 819; no current event slot
	;const EVENT_81A                                  ; inactive legacy 81A; no current event slot
	;const EVENT_81B                                  ; inactive legacy 81B; no current event slot
	;const EVENT_81C                                  ; inactive legacy 81C; no current event slot
	;const EVENT_81D                                  ; inactive legacy 81D; no current event slot
	;const EVENT_81E                                  ; inactive legacy 81E; no current event slot
	;const EVENT_81F                                  ; inactive legacy 81F; no current event slot
	const EVENT_820                                  ; current 3E0, (D847, bit 0)
	const EVENT_BEAT_MANSION_4_TRAINER_0             ; current 3E1, (D847, bit 1)
	const EVENT_BEAT_MANSION_4_TRAINER_1             ; current 3E2, (D847, bit 2)
	const EVENT_823                                  ; current 3E3, (D847, bit 3)
	const EVENT_824                                  ; current 3E4, (D847, bit 4)
	const EVENT_825                                  ; current 3E5, (D847, bit 5)
	const EVENT_826                                  ; current 3E6, (D847, bit 6)
	const EVENT_827                                  ; current 3E7, (D847, bit 7)
	;const EVENT_828                                  ; inactive legacy 828; no current event slot
	;const EVENT_829                                  ; inactive legacy 829; no current event slot
	;const EVENT_82A                                  ; inactive legacy 82A; no current event slot
	;const EVENT_82B                                  ; inactive legacy 82B; no current event slot
	;const EVENT_82C                                  ; inactive legacy 82C; no current event slot
	;const EVENT_82D                                  ; inactive legacy 82D; no current event slot
	;const EVENT_82E                                  ; inactive legacy 82E; no current event slot
	;const EVENT_82F                                  ; inactive legacy 82F; no current event slot
	;const EVENT_830                                  ; inactive legacy 830; no current event slot
	;const EVENT_831                                  ; inactive legacy 831; no current event slot
	;const EVENT_832                                  ; inactive legacy 832; no current event slot
	;const EVENT_833                                  ; inactive legacy 833; no current event slot
	;const EVENT_834                                  ; inactive legacy 834; no current event slot
	;const EVENT_835                                  ; inactive legacy 835; no current event slot
	;const EVENT_836                                  ; inactive legacy 836; no current event slot
	;const EVENT_837                                  ; inactive legacy 837; no current event slot
	;const EVENT_838                                  ; inactive legacy 838; no current event slot
	;const EVENT_839                                  ; inactive legacy 839; no current event slot
	;const EVENT_83A                                  ; inactive legacy 83A; no current event slot
	;const EVENT_83B                                  ; inactive legacy 83B; no current event slot
	;const EVENT_83C                                  ; inactive legacy 83C; no current event slot
	;const EVENT_83D                                  ; inactive legacy 83D; no current event slot
	;const EVENT_83E                                  ; inactive legacy 83E; no current event slot
	;const EVENT_83F                                  ; inactive legacy 83F; no current event slot
	;const EVENT_840                                  ; inactive legacy 840; no current event slot
	;const EVENT_841                                  ; inactive legacy 841; no current event slot
	;const EVENT_842                                  ; inactive legacy 842; no current event slot
	;const EVENT_843                                  ; inactive legacy 843; no current event slot
	;const EVENT_844                                  ; inactive legacy 844; no current event slot
	;const EVENT_845                                  ; inactive legacy 845; no current event slot
	;const EVENT_846                                  ; inactive legacy 846; no current event slot
	;const EVENT_847                                  ; inactive legacy 847; no current event slot
	;const EVENT_848                                  ; inactive legacy 848; no current event slot
	;const EVENT_849                                  ; inactive legacy 849; no current event slot
	;const EVENT_84A                                  ; inactive legacy 84A; no current event slot
	;const EVENT_84B                                  ; inactive legacy 84B; no current event slot
	;const EVENT_84C                                  ; inactive legacy 84C; no current event slot
	;const EVENT_84D                                  ; inactive legacy 84D; no current event slot
	;const EVENT_84E                                  ; inactive legacy 84E; no current event slot
	;const EVENT_84F                                  ; inactive legacy 84F; no current event slot
	;const EVENT_850                                  ; inactive legacy 850; no current event slot
	;const EVENT_851                                  ; inactive legacy 851; no current event slot
	;const EVENT_852                                  ; inactive legacy 852; no current event slot
	;const EVENT_853                                  ; inactive legacy 853; no current event slot
	;const EVENT_854                                  ; inactive legacy 854; no current event slot
	;const EVENT_855                                  ; inactive legacy 855; no current event slot
	;const EVENT_856                                  ; inactive legacy 856; no current event slot
	;const EVENT_857                                  ; inactive legacy 857; no current event slot
	;const EVENT_858                                  ; inactive legacy 858; no current event slot
	;const EVENT_859                                  ; inactive legacy 859; no current event slot
	;const EVENT_85A                                  ; inactive legacy 85A; no current event slot
	;const EVENT_85B                                  ; inactive legacy 85B; no current event slot
	;const EVENT_85C                                  ; inactive legacy 85C; no current event slot
	;const EVENT_85D                                  ; inactive legacy 85D; no current event slot
	;const EVENT_85E                                  ; inactive legacy 85E; no current event slot
	;const EVENT_85F                                  ; inactive legacy 85F; no current event slot
	;const EVENT_860                                  ; inactive legacy 860; no current event slot
	;const EVENT_861                                  ; inactive legacy 861; no current event slot
	;const EVENT_862                                  ; inactive legacy 862; no current event slot
	;const EVENT_863                                  ; inactive legacy 863; no current event slot
	;const EVENT_864                                  ; inactive legacy 864; no current event slot
	;const EVENT_865                                  ; inactive legacy 865; no current event slot
	;const EVENT_866                                  ; inactive legacy 866; no current event slot
	;const EVENT_867                                  ; inactive legacy 867; no current event slot
	;const EVENT_868                                  ; inactive legacy 868; no current event slot
	;const EVENT_869                                  ; inactive legacy 869; no current event slot
	;const EVENT_86A                                  ; inactive legacy 86A; no current event slot
	;const EVENT_86B                                  ; inactive legacy 86B; no current event slot
	;const EVENT_86C                                  ; inactive legacy 86C; no current event slot
	;const EVENT_86D                                  ; inactive legacy 86D; no current event slot
	;const EVENT_86E                                  ; inactive legacy 86E; no current event slot
	;const EVENT_86F                                  ; inactive legacy 86F; no current event slot
	;const EVENT_870                                  ; inactive legacy 870; no current event slot
	;const EVENT_871                                  ; inactive legacy 871; no current event slot
	;const EVENT_872                                  ; inactive legacy 872; no current event slot
	;const EVENT_873                                  ; inactive legacy 873; no current event slot
	;const EVENT_874                                  ; inactive legacy 874; no current event slot
	;const EVENT_875                                  ; inactive legacy 875; no current event slot
	;const EVENT_876                                  ; inactive legacy 876; no current event slot
	;const EVENT_877                                  ; inactive legacy 877; no current event slot
	;const EVENT_878                                  ; inactive legacy 878; no current event slot
	;const EVENT_879                                  ; inactive legacy 879; no current event slot
	;const EVENT_87A                                  ; inactive legacy 87A; no current event slot
	;const EVENT_87B                                  ; inactive legacy 87B; no current event slot
	;const EVENT_87C                                  ; inactive legacy 87C; no current event slot
	;const EVENT_87D                                  ; inactive legacy 87D; no current event slot
	;const EVENT_87E                                  ; inactive legacy 87E; no current event slot
	;const EVENT_87F                                  ; inactive legacy 87F; no current event slot
	const EVENT_GOT_TM15                             ; current 3E8, (D848, bit 0)
	const EVENT_GOT_HM03                             ; current 3E9, (D848, bit 1)
	const EVENT_882                                  ; current 3EA, (D848, bit 2)
	const EVENT_883                                  ; current 3EB, (D848, bit 3)
	const EVENT_884                                  ; current 3EC, (D848, bit 4)
	const EVENT_885                                  ; current 3ED, (D848, bit 5)
	const EVENT_886                                  ; current 3EE, (D848, bit 6)
	const EVENT_887                                  ; current 3EF, (D848, bit 7)
	;const EVENT_888                                  ; inactive legacy 888; no current event slot
	;const EVENT_889                                  ; inactive legacy 889; no current event slot
	;const EVENT_88A                                  ; inactive legacy 88A; no current event slot
	;const EVENT_88B                                  ; inactive legacy 88B; no current event slot
	;const EVENT_88C                                  ; inactive legacy 88C; no current event slot
	;const EVENT_88D                                  ; inactive legacy 88D; no current event slot
	;const EVENT_88E                                  ; inactive legacy 88E; no current event slot
	;const EVENT_88F                                  ; inactive legacy 88F; no current event slot
	;const EVENT_890                                  ; inactive legacy 890; no current event slot
	;const EVENT_891                                  ; inactive legacy 891; no current event slot
	;const EVENT_892                                  ; inactive legacy 892; no current event slot
	;const EVENT_893                                  ; inactive legacy 893; no current event slot
	;const EVENT_894                                  ; inactive legacy 894; no current event slot
	;const EVENT_895                                  ; inactive legacy 895; no current event slot
	;const EVENT_896                                  ; inactive legacy 896; no current event slot
	;const EVENT_897                                  ; inactive legacy 897; no current event slot
	;const EVENT_898                                  ; inactive legacy 898; no current event slot
	;const EVENT_899                                  ; inactive legacy 899; no current event slot
	;const EVENT_89A                                  ; inactive legacy 89A; no current event slot
	;const EVENT_89B                                  ; inactive legacy 89B; no current event slot
	;const EVENT_89C                                  ; inactive legacy 89C; no current event slot
	;const EVENT_89D                                  ; inactive legacy 89D; no current event slot
	;const EVENT_89E                                  ; inactive legacy 89E; no current event slot
	;const EVENT_89F                                  ; inactive legacy 89F; no current event slot
	;const EVENT_8A0                                  ; inactive legacy 8A0; no current event slot
	;const EVENT_8A1                                  ; inactive legacy 8A1; no current event slot
	;const EVENT_8A2                                  ; inactive legacy 8A2; no current event slot
	;const EVENT_8A3                                  ; inactive legacy 8A3; no current event slot
	;const EVENT_8A4                                  ; inactive legacy 8A4; no current event slot
	;const EVENT_8A5                                  ; inactive legacy 8A5; no current event slot
	;const EVENT_8A6                                  ; inactive legacy 8A6; no current event slot
	;const EVENT_8A7                                  ; inactive legacy 8A7; no current event slot
	;const EVENT_8A8                                  ; inactive legacy 8A8; no current event slot
	;const EVENT_8A9                                  ; inactive legacy 8A9; no current event slot
	;const EVENT_8AA                                  ; inactive legacy 8AA; no current event slot
	;const EVENT_8AB                                  ; inactive legacy 8AB; no current event slot
	;const EVENT_8AC                                  ; inactive legacy 8AC; no current event slot
	;const EVENT_8AD                                  ; inactive legacy 8AD; no current event slot
	;const EVENT_8AE                                  ; inactive legacy 8AE; no current event slot
	;const EVENT_8AF                                  ; inactive legacy 8AF; no current event slot
	;const EVENT_8B0                                  ; inactive legacy 8B0; no current event slot
	;const EVENT_8B1                                  ; inactive legacy 8B1; no current event slot
	;const EVENT_8B2                                  ; inactive legacy 8B2; no current event slot
	;const EVENT_8B3                                  ; inactive legacy 8B3; no current event slot
	;const EVENT_8B4                                  ; inactive legacy 8B4; no current event slot
	;const EVENT_8B5                                  ; inactive legacy 8B5; no current event slot
	;const EVENT_8B6                                  ; inactive legacy 8B6; no current event slot
	;const EVENT_8B7                                  ; inactive legacy 8B7; no current event slot
	;const EVENT_8B8                                  ; inactive legacy 8B8; no current event slot
	;const EVENT_8B9                                  ; inactive legacy 8B9; no current event slot
	;const EVENT_8BA                                  ; inactive legacy 8BA; no current event slot
	;const EVENT_8BB                                  ; inactive legacy 8BB; no current event slot
	;const EVENT_8BC                                  ; inactive legacy 8BC; no current event slot
	;const EVENT_8BD                                  ; inactive legacy 8BD; no current event slot
	;const EVENT_8BE                                  ; inactive legacy 8BE; no current event slot
	;const EVENT_8BF                                  ; inactive legacy 8BF; no current event slot
	const EVENT_8C0                                  ; current 3F0, (D849, bit 0)
	const EVENT_BEAT_MEWTWO                          ; current 3F1, (D849, bit 1)
	const EVENT_BEAT_FARAWAY_INSIDE_TRAINER_0        ; current 3F2, (D849, bit 2)
	const EVENT_BEAT_SOUTHERN_INSIDE_TRAINER_0       ; current 3F3, (D849, bit 3)
	const EVENT_BEAT_SOUTHERN_INSIDE_TRAINER_1       ; current 3F4, (D849, bit 4)
	const EVENT_BEAT_LUGIA                           ; current 3F5, (D849, bit 5)
	const EVENT_BEAT_HO_OH                           ; current 3F6, (D849, bit 6)
	const EVENT_8C7                                  ; current 3F7, (D849, bit 7)
	;const EVENT_8C8                                  ; inactive legacy 8C8; no current event slot
	;const EVENT_8C9                                  ; inactive legacy 8C9; no current event slot
	;const EVENT_8CA                                  ; inactive legacy 8CA; no current event slot
	;const EVENT_8CB                                  ; inactive legacy 8CB; no current event slot
	;const EVENT_8CC                                  ; inactive legacy 8CC; no current event slot
	;const EVENT_8CD                                  ; inactive legacy 8CD; no current event slot
	;const EVENT_8CE                                  ; inactive legacy 8CE; no current event slot
	;const EVENT_8CF                                  ; inactive legacy 8CF; no current event slot
	;const EVENT_8D0                                  ; inactive legacy 8D0; no current event slot
	;const EVENT_8D1                                  ; inactive legacy 8D1; no current event slot
	;const EVENT_8D2                                  ; inactive legacy 8D2; no current event slot
	;const EVENT_8D3                                  ; inactive legacy 8D3; no current event slot
	;const EVENT_8D4                                  ; inactive legacy 8D4; no current event slot
	;const EVENT_8D5                                  ; inactive legacy 8D5; no current event slot
	;const EVENT_8D6                                  ; inactive legacy 8D6; no current event slot
	;const EVENT_8D7                                  ; inactive legacy 8D7; no current event slot
	;const EVENT_8D8                                  ; inactive legacy 8D8; no current event slot
	;const EVENT_8D9                                  ; inactive legacy 8D9; no current event slot
	;const EVENT_8DA                                  ; inactive legacy 8DA; no current event slot
	;const EVENT_8DB                                  ; inactive legacy 8DB; no current event slot
	;const EVENT_8DC                                  ; inactive legacy 8DC; no current event slot
	;const EVENT_8DD                                  ; inactive legacy 8DD; no current event slot
	;const EVENT_8DE                                  ; inactive legacy 8DE; no current event slot
	;const EVENT_8DF                                  ; inactive legacy 8DF; no current event slot
	const ELITE4_EVENTS_START                        ; current 3F8, (D84A, bit 0)
	const EVENT_BEAT_LORELEIS_ROOM_TRAINER_0         ; current 3F9, (D84A, bit 1)
	const EVENT_8E2                                  ; current 3FA, (D84A, bit 2)
	const EVENT_8E3                                  ; current 3FB, (D84A, bit 3)
	const EVENT_8E4                                  ; current 3FC, (D84A, bit 4)
	const EVENT_8E5                                  ; current 3FD, (D84A, bit 5)
	const EVENT_AUTOWALKED_INTO_LORELEIS_ROOM        ; current 3FE, (D84A, bit 6)
	const EVENT_8E7                                  ; current 3FF, (D84A, bit 7)
	const EVENT_8E8                                  ; current 400, (D84B, bit 0)
	const EVENT_BEAT_BRUNOS_ROOM_TRAINER_0           ; current 401, (D84B, bit 1)
	const EVENT_8EA                                  ; current 402, (D84B, bit 2)
	const EVENT_8EB                                  ; current 403, (D84B, bit 3)
	const EVENT_8EC                                  ; current 404, (D84B, bit 4)
	const EVENT_8ED                                  ; current 405, (D84B, bit 5)
	const EVENT_AUTOWALKED_INTO_BRUNOS_ROOM          ; current 406, (D84B, bit 6)
	const EVENT_8EF                                  ; current 407, (D84B, bit 7)
	const EVENT_8F0                                  ; current 408, (D84C, bit 0)
	const EVENT_BEAT_AGATHAS_ROOM_TRAINER_0          ; current 409, (D84C, bit 1)
	const EVENT_8F2                                  ; current 40A, (D84C, bit 2)
	const EVENT_8F3                                  ; current 40B, (D84C, bit 3)
	const EVENT_8F4                                  ; current 40C, (D84C, bit 4)
	const EVENT_8F5                                  ; current 40D, (D84C, bit 5)
	const EVENT_AUTOWALKED_INTO_AGATHAS_ROOM         ; current 40E, (D84C, bit 6)
	const EVENT_8F7                                  ; current 40F, (D84C, bit 7)
	const EVENT_8F8                                  ; current 410, (D84D, bit 0)
	const EVENT_BEAT_LANCES_ROOM_TRAINER_0           ; current 411, (D84D, bit 1)
	const EVENT_8FA                                  ; current 412, (D84D, bit 2)
	const EVENT_8FB                                  ; current 413, (D84D, bit 3)
	const EVENT_8FC                                  ; current 414, (D84D, bit 4)
	const EVENT_8FD                                  ; current 415, (D84D, bit 5)
	const EVENT_BEAT_LANCE                           ; current 416, (D84D, bit 6)
	const EVENT_LANCES_ROOM_LOCK_DOOR                ; current 417, (D84D, bit 7)
	const EVENT_900                                  ; current 418, (D84E, bit 0)
	const EVENT_BEAT_CHAMPION_RIVAL                  ; current 419, (D84E, bit 1)
	const EVENT_902                                  ; current 41A, (D84E, bit 2)
	const EVENT_903                                  ; current 41B, (D84E, bit 3)
	const EVENT_904                                  ; current 41C, (D84E, bit 4)
	const EVENT_905                                  ; current 41D, (D84E, bit 5)
	const EVENT_906                                  ; current 41E, (D84E, bit 6)
	const ELITE4_CHAMPION_EVENTS_END                 ; current 41F, (D84E, bit 7)
	;const EVENT_908                                  ; inactive legacy 908; no current event slot
	;const EVENT_909                                  ; inactive legacy 909; no current event slot
	;const EVENT_90A                                  ; inactive legacy 90A; no current event slot
	;const EVENT_90B                                  ; inactive legacy 90B; no current event slot
	;const EVENT_90C                                  ; inactive legacy 90C; no current event slot
	;const EVENT_90D                                  ; inactive legacy 90D; no current event slot
	;const EVENT_90E                                  ; inactive legacy 90E; no current event slot
	;const EVENT_90F                                  ; inactive legacy 90F; no current event slot
	const EVENT_910                                  ; current 420, (D84F, bit 0)
	const EVENT_BEAT_VICTORY_ROAD_1_TRAINER_0        ; current 421, (D84F, bit 1)
	const EVENT_BEAT_VICTORY_ROAD_1_TRAINER_1        ; current 422, (D84F, bit 2)
	const EVENT_913                                  ; current 423, (D84F, bit 3)
	const EVENT_914                                  ; current 424, (D84F, bit 4)
	const EVENT_915                                  ; current 425, (D84F, bit 5)
	const EVENT_916                                  ; current 426, (D84F, bit 6)
	const EVENT_VICTORY_ROAD_1_BOULDER_ON_SWITCH     ; current 427, (D84F, bit 7)
	;const EVENT_918                                  ; inactive legacy 918; no current event slot
	;const EVENT_919                                  ; inactive legacy 919; no current event slot
	;const EVENT_91A                                  ; inactive legacy 91A; no current event slot
	;const EVENT_91B                                  ; inactive legacy 91B; no current event slot
	;const EVENT_91C                                  ; inactive legacy 91C; no current event slot
	;const EVENT_91D                                  ; inactive legacy 91D; no current event slot
	;const EVENT_91E                                  ; inactive legacy 91E; no current event slot
	;const EVENT_91F                                  ; inactive legacy 91F; no current event slot
	;const EVENT_920                                  ; inactive legacy 920; no current event slot
	;const EVENT_921                                  ; inactive legacy 921; no current event slot
	;const EVENT_922                                  ; inactive legacy 922; no current event slot
	;const EVENT_923                                  ; inactive legacy 923; no current event slot
	;const EVENT_924                                  ; inactive legacy 924; no current event slot
	;const EVENT_925                                  ; inactive legacy 925; no current event slot
	;const EVENT_926                                  ; inactive legacy 926; no current event slot
	;const EVENT_927                                  ; inactive legacy 927; no current event slot
	;const EVENT_928                                  ; inactive legacy 928; no current event slot
	;const EVENT_929                                  ; inactive legacy 929; no current event slot
	;const EVENT_92A                                  ; inactive legacy 92A; no current event slot
	;const EVENT_92B                                  ; inactive legacy 92B; no current event slot
	;const EVENT_92C                                  ; inactive legacy 92C; no current event slot
	;const EVENT_92D                                  ; inactive legacy 92D; no current event slot
	;const EVENT_92E                                  ; inactive legacy 92E; no current event slot
	;const EVENT_92F                                  ; inactive legacy 92F; no current event slot
	;const EVENT_930                                  ; inactive legacy 930; no current event slot
	;const EVENT_931                                  ; inactive legacy 931; no current event slot
	;const EVENT_932                                  ; inactive legacy 932; no current event slot
	;const EVENT_933                                  ; inactive legacy 933; no current event slot
	;const EVENT_934                                  ; inactive legacy 934; no current event slot
	;const EVENT_935                                  ; inactive legacy 935; no current event slot
	;const EVENT_936                                  ; inactive legacy 936; no current event slot
	;const EVENT_937                                  ; inactive legacy 937; no current event slot
	;const EVENT_938                                  ; inactive legacy 938; no current event slot
	;const EVENT_939                                  ; inactive legacy 939; no current event slot
	;const EVENT_93A                                  ; inactive legacy 93A; no current event slot
	;const EVENT_93B                                  ; inactive legacy 93B; no current event slot
	;const EVENT_93C                                  ; inactive legacy 93C; no current event slot
	;const EVENT_93D                                  ; inactive legacy 93D; no current event slot
	;const EVENT_93E                                  ; inactive legacy 93E; no current event slot
	;const EVENT_93F                                  ; inactive legacy 93F; no current event slot
	;const EVENT_940                                  ; inactive legacy 940; no current event slot
	;const EVENT_941                                  ; inactive legacy 941; no current event slot
	;const EVENT_942                                  ; inactive legacy 942; no current event slot
	;const EVENT_943                                  ; inactive legacy 943; no current event slot
	;const EVENT_944                                  ; inactive legacy 944; no current event slot
	;const EVENT_945                                  ; inactive legacy 945; no current event slot
	;const EVENT_946                                  ; inactive legacy 946; no current event slot
	;const EVENT_947                                  ; inactive legacy 947; no current event slot
	;const EVENT_948                                  ; inactive legacy 948; no current event slot
	;const EVENT_949                                  ; inactive legacy 949; no current event slot
	;const EVENT_94A                                  ; inactive legacy 94A; no current event slot
	;const EVENT_94B                                  ; inactive legacy 94B; no current event slot
	;const EVENT_94C                                  ; inactive legacy 94C; no current event slot
	;const EVENT_94D                                  ; inactive legacy 94D; no current event slot
	;const EVENT_94E                                  ; inactive legacy 94E; no current event slot
	;const EVENT_94F                                  ; inactive legacy 94F; no current event slot
	;const EVENT_950                                  ; inactive legacy 950; no current event slot
	;const EVENT_951                                  ; inactive legacy 951; no current event slot
	;const EVENT_952                                  ; inactive legacy 952; no current event slot
	;const EVENT_953                                  ; inactive legacy 953; no current event slot
	;const EVENT_954                                  ; inactive legacy 954; no current event slot
	;const EVENT_955                                  ; inactive legacy 955; no current event slot
	;const EVENT_956                                  ; inactive legacy 956; no current event slot
	;const EVENT_957                                  ; inactive legacy 957; no current event slot
	;const EVENT_958                                  ; inactive legacy 958; no current event slot
	;const EVENT_959                                  ; inactive legacy 959; no current event slot
	;const EVENT_95A                                  ; inactive legacy 95A; no current event slot
	;const EVENT_95B                                  ; inactive legacy 95B; no current event slot
	;const EVENT_95C                                  ; inactive legacy 95C; no current event slot
	;const EVENT_95D                                  ; inactive legacy 95D; no current event slot
	;const EVENT_95E                                  ; inactive legacy 95E; no current event slot
	;const EVENT_95F                                  ; inactive legacy 95F; no current event slot
	;const EVENT_960                                  ; inactive legacy 960; no current event slot
	;const EVENT_961                                  ; inactive legacy 961; no current event slot
	;const EVENT_962                                  ; inactive legacy 962; no current event slot
	;const EVENT_963                                  ; inactive legacy 963; no current event slot
	;const EVENT_964                                  ; inactive legacy 964; no current event slot
	;const EVENT_965                                  ; inactive legacy 965; no current event slot
	;const EVENT_966                                  ; inactive legacy 966; no current event slot
	;const EVENT_967                                  ; inactive legacy 967; no current event slot
	;const EVENT_968                                  ; inactive legacy 968; no current event slot
	;const EVENT_969                                  ; inactive legacy 969; no current event slot
	;const EVENT_96A                                  ; inactive legacy 96A; no current event slot
	;const EVENT_96B                                  ; inactive legacy 96B; no current event slot
	;const EVENT_96C                                  ; inactive legacy 96C; no current event slot
	;const EVENT_96D                                  ; inactive legacy 96D; no current event slot
	;const EVENT_96E                                  ; inactive legacy 96E; no current event slot
	;const EVENT_96F                                  ; inactive legacy 96F; no current event slot
	;const EVENT_970                                  ; inactive legacy 970; no current event slot
	;const EVENT_971                                  ; inactive legacy 971; no current event slot
	;const EVENT_972                                  ; inactive legacy 972; no current event slot
	;const EVENT_973                                  ; inactive legacy 973; no current event slot
	;const EVENT_974                                  ; inactive legacy 974; no current event slot
	;const EVENT_975                                  ; inactive legacy 975; no current event slot
	;const EVENT_976                                  ; inactive legacy 976; no current event slot
	;const EVENT_977                                  ; inactive legacy 977; no current event slot
	;const EVENT_978                                  ; inactive legacy 978; no current event slot
	;const EVENT_979                                  ; inactive legacy 979; no current event slot
	;const EVENT_97A                                  ; inactive legacy 97A; no current event slot
	;const EVENT_97B                                  ; inactive legacy 97B; no current event slot
	;const EVENT_97C                                  ; inactive legacy 97C; no current event slot
	;const EVENT_97D                                  ; inactive legacy 97D; no current event slot
	;const EVENT_97E                                  ; inactive legacy 97E; no current event slot
	;const EVENT_97F                                  ; inactive legacy 97F; no current event slot
	;const EVENT_980                                  ; inactive legacy 980; no current event slot
	;const EVENT_981                                  ; inactive legacy 981; no current event slot
	;const EVENT_982                                  ; inactive legacy 982; no current event slot
	;const EVENT_983                                  ; inactive legacy 983; no current event slot
	;const EVENT_984                                  ; inactive legacy 984; no current event slot
	;const EVENT_985                                  ; inactive legacy 985; no current event slot
	;const EVENT_986                                  ; inactive legacy 986; no current event slot
	;const EVENT_987                                  ; inactive legacy 987; no current event slot
	;const EVENT_988                                  ; inactive legacy 988; no current event slot
	;const EVENT_989                                  ; inactive legacy 989; no current event slot
	;const EVENT_98A                                  ; inactive legacy 98A; no current event slot
	;const EVENT_98B                                  ; inactive legacy 98B; no current event slot
	;const EVENT_98C                                  ; inactive legacy 98C; no current event slot
	;const EVENT_98D                                  ; inactive legacy 98D; no current event slot
	;const EVENT_98E                                  ; inactive legacy 98E; no current event slot
	;const EVENT_98F                                  ; inactive legacy 98F; no current event slot
	;const EVENT_990                                  ; inactive legacy 990; no current event slot
	;const EVENT_991                                  ; inactive legacy 991; no current event slot
	;const EVENT_992                                  ; inactive legacy 992; no current event slot
	;const EVENT_993                                  ; inactive legacy 993; no current event slot
	;const EVENT_994                                  ; inactive legacy 994; no current event slot
	;const EVENT_995                                  ; inactive legacy 995; no current event slot
	;const EVENT_996                                  ; inactive legacy 996; no current event slot
	;const EVENT_997                                  ; inactive legacy 997; no current event slot
	;const EVENT_998                                  ; inactive legacy 998; no current event slot
	;const EVENT_999                                  ; inactive legacy 999; no current event slot
	;const EVENT_99A                                  ; inactive legacy 99A; no current event slot
	;const EVENT_99B                                  ; inactive legacy 99B; no current event slot
	;const EVENT_99C                                  ; inactive legacy 99C; no current event slot
	;const EVENT_99D                                  ; inactive legacy 99D; no current event slot
	;const EVENT_99E                                  ; inactive legacy 99E; no current event slot
	;const EVENT_99F                                  ; inactive legacy 99F; no current event slot
	;const EVENT_9A0                                  ; inactive legacy 9A0; no current event slot
	;const EVENT_9A1                                  ; inactive legacy 9A1; no current event slot
	;const EVENT_9A2                                  ; inactive legacy 9A2; no current event slot
	;const EVENT_9A3                                  ; inactive legacy 9A3; no current event slot
	;const EVENT_9A4                                  ; inactive legacy 9A4; no current event slot
	;const EVENT_9A5                                  ; inactive legacy 9A5; no current event slot
	;const EVENT_9A6                                  ; inactive legacy 9A6; no current event slot
	;const EVENT_9A7                                  ; inactive legacy 9A7; no current event slot
	;const EVENT_9A8                                  ; inactive legacy 9A8; no current event slot
	;const EVENT_9A9                                  ; inactive legacy 9A9; no current event slot
	;const EVENT_9AA                                  ; inactive legacy 9AA; no current event slot
	;const EVENT_9AB                                  ; inactive legacy 9AB; no current event slot
	;const EVENT_9AC                                  ; inactive legacy 9AC; no current event slot
	;const EVENT_9AD                                  ; inactive legacy 9AD; no current event slot
	;const EVENT_9AE                                  ; inactive legacy 9AE; no current event slot
	;const EVENT_9AF                                  ; inactive legacy 9AF; no current event slot
	const EVENT_9B0                                  ; current 428, (D850, bit 0)
	const EVENT_BEAT_ROCK_TUNNEL_2_TRAINER_0         ; current 429, (D850, bit 1)
	const EVENT_BEAT_ROCK_TUNNEL_2_TRAINER_1         ; current 42A, (D850, bit 2)
	const EVENT_BEAT_ROCK_TUNNEL_2_TRAINER_2         ; current 42B, (D850, bit 3)
	const EVENT_BEAT_ROCK_TUNNEL_2_TRAINER_3         ; current 42C, (D850, bit 4)
	const EVENT_BEAT_ROCK_TUNNEL_2_TRAINER_4         ; current 42D, (D850, bit 5)
	const EVENT_BEAT_ROCK_TUNNEL_2_TRAINER_5         ; current 42E, (D850, bit 6)
	const EVENT_BEAT_ROCK_TUNNEL_2_TRAINER_6         ; current 42F, (D850, bit 7)
	const EVENT_BEAT_ROCK_TUNNEL_2_TRAINER_7         ; current 430, (D851, bit 0)
	const EVENT_9B9                                  ; current 431, (D851, bit 1)
	const EVENT_9BA                                  ; current 432, (D851, bit 2)
	const EVENT_9BB                                  ; current 433, (D851, bit 3)
	const EVENT_9BC                                  ; current 434, (D851, bit 4)
	const EVENT_9BD                                  ; current 435, (D851, bit 5)
	const EVENT_9BE                                  ; current 436, (D851, bit 6)
	const EVENT_9BF                                  ; current 437, (D851, bit 7)
	const EVENT_SEAFOAM2_BOULDER1_DOWN_HOLE          ; current 438, (D852, bit 0)
	const EVENT_SEAFOAM2_BOULDER2_DOWN_HOLE          ; current 439, (D852, bit 1)
	const EVENT_9C2                                  ; current 43A, (D852, bit 2)
	const EVENT_9C3                                  ; current 43B, (D852, bit 3)
	const EVENT_9C4                                  ; current 43C, (D852, bit 4)
	const EVENT_9C5                                  ; current 43D, (D852, bit 5)
	const EVENT_9C6                                  ; current 43E, (D852, bit 6)
	const EVENT_9C7                                  ; current 43F, (D852, bit 7)
	const EVENT_SEAFOAM3_BOULDER1_DOWN_HOLE          ; current 440, (D853, bit 0)
	const EVENT_SEAFOAM3_BOULDER2_DOWN_HOLE          ; current 441, (D853, bit 1)
	const EVENT_9CA                                  ; current 442, (D853, bit 2)
	const EVENT_9CB                                  ; current 443, (D853, bit 3)
	const EVENT_9CC                                  ; current 444, (D853, bit 4)
	const EVENT_9CD                                  ; current 445, (D853, bit 5)
	const EVENT_9CE                                  ; current 446, (D853, bit 6)
	const EVENT_9CF                                  ; current 447, (D853, bit 7)
	const EVENT_SEAFOAM4_BOULDER1_DOWN_HOLE          ; current 448, (D854, bit 0)
	const EVENT_SEAFOAM4_BOULDER2_DOWN_HOLE          ; current 449, (D854, bit 1)
	const EVENT_9D2                                  ; current 44A, (D854, bit 2)
	const EVENT_9D3                                  ; current 44B, (D854, bit 3)
	const EVENT_9D4                                  ; current 44C, (D854, bit 4)
	const EVENT_9D5                                  ; current 44D, (D854, bit 5)
	const EVENT_9D6                                  ; current 44E, (D854, bit 6)
	const EVENT_9D7                                  ; current 44F, (D854, bit 7)
	const EVENT_9D8                                  ; current 450, (D855, bit 0)
	const EVENT_9D9                                  ; current 451, (D855, bit 1)
	const EVENT_BEAT_ARTICUNO                        ; current 452, (D855, bit 2)
	const EVENT_9DB                                  ; current 453, (D855, bit 3)
	const EVENT_9DC                                  ; current 454, (D855, bit 4)
	const EVENT_9DD                                  ; current 455, (D855, bit 5)
	const EVENT_9DE                                  ; current 456, (D855, bit 6)
	const EVENT_9DF                                  ; current 457, (D855, bit 7)
	;const EVENT_9E0                                  ; inactive legacy 9E0; no current event slot
	;const EVENT_9E1                                  ; inactive legacy 9E1; no current event slot
	;const EVENT_9E2                                  ; inactive legacy 9E2; no current event slot
	;const EVENT_9E3                                  ; inactive legacy 9E3; no current event slot
	;const EVENT_9E4                                  ; inactive legacy 9E4; no current event slot
	;const EVENT_9E5                                  ; inactive legacy 9E5; no current event slot
	;const EVENT_9E6                                  ; inactive legacy 9E6; no current event slot
	;const EVENT_9E7                                  ; inactive legacy 9E7; no current event slot
	;const EVENT_9E8                                  ; inactive legacy 9E8; no current event slot
	;const EVENT_9E9                                  ; inactive legacy 9E9; no current event slot
	;const EVENT_9EA                                  ; inactive legacy 9EA; no current event slot
	;const EVENT_9EB                                  ; inactive legacy 9EB; no current event slot
	;const EVENT_9EC                                  ; inactive legacy 9EC; no current event slot
	;const EVENT_9ED                                  ; inactive legacy 9ED; no current event slot
	;const EVENT_9EE                                  ; inactive legacy 9EE; no current event slot
	;const EVENT_9EF                                  ; inactive legacy 9EF; no current event slot
	;const EVENT_9F0                                  ; inactive legacy 9F0; no current event slot
	;const EVENT_9F1                                  ; inactive legacy 9F1; no current event slot
	;const EVENT_9F2                                  ; inactive legacy 9F2; no current event slot
	;const EVENT_9F3                                  ; inactive legacy 9F3; no current event slot
	;const EVENT_9F4                                  ; inactive legacy 9F4; no current event slot
	;const EVENT_9F5                                  ; inactive legacy 9F5; no current event slot
	;const EVENT_9F6                                  ; inactive legacy 9F6; no current event slot
	;const EVENT_9F7                                  ; inactive legacy 9F7; no current event slot
	;const EVENT_9F8                                  ; inactive legacy 9F8; no current event slot
	;const EVENT_9F9                                  ; inactive legacy 9F9; no current event slot
	;const EVENT_9FA                                  ; inactive legacy 9FA; no current event slot
	;const EVENT_9FB                                  ; inactive legacy 9FB; no current event slot
	;const EVENT_9FC                                  ; inactive legacy 9FC; no current event slot
	;const EVENT_9FD                                  ; inactive legacy 9FD; no current event slot
	;const EVENT_9FE                                  ; inactive legacy 9FE; no current event slot
	;const EVENT_9FF                                  ; inactive legacy 9FF; no current event slot
