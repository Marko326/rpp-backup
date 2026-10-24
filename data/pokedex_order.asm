; MAP-5.30.03: keep Species ID and Pokédex number logically independent without
; paying 208 bytes for an identity table. Each declaration is compared at
; assembly time; only non-identity pairs emit ROM data and increment the count.
; Current 208/208 identity ordering therefore costs 0 bytes. If either constant
; order diverges later, sparse overrides and the generic conversion path activate
; automatically without restoring the full table.

PokedexOrderDeclarationCount = 0
PokedexOrderOverrideCount = 0

pokedex_order_override: MACRO
PokedexOrderDeclarationCount = PokedexOrderDeclarationCount + 1
IF \1 != \2
	db \1, \2
PokedexOrderOverrideCount = PokedexOrderOverrideCount + 1
ENDC
ENDM

PokedexOrderOverrides:
	pokedex_order_override BULBASAUR, DEX_BULBASAUR
	pokedex_order_override IVYSAUR, DEX_IVYSAUR
	pokedex_order_override VENUSAUR, DEX_VENUSAUR
	pokedex_order_override CHARMANDER, DEX_CHARMANDER
	pokedex_order_override CHARMELEON, DEX_CHARMELEON
	pokedex_order_override CHARIZARD, DEX_CHARIZARD
	pokedex_order_override SQUIRTLE, DEX_SQUIRTLE
	pokedex_order_override WARTORTLE, DEX_WARTORTLE
	pokedex_order_override BLASTOISE, DEX_BLASTOISE
	pokedex_order_override CATERPIE, DEX_CATERPIE
	pokedex_order_override METAPOD, DEX_METAPOD
	pokedex_order_override BUTTERFREE, DEX_BUTTERFREE
	pokedex_order_override WEEDLE, DEX_WEEDLE
	pokedex_order_override KAKUNA, DEX_KAKUNA
	pokedex_order_override BEEDRILL, DEX_BEEDRILL
	pokedex_order_override PIDGEY, DEX_PIDGEY
	pokedex_order_override PIDGEOTTO, DEX_PIDGEOTTO
	pokedex_order_override PIDGEOT, DEX_PIDGEOT
	pokedex_order_override RATTATA, DEX_RATTATA
	pokedex_order_override RATICATE, DEX_RATICATE
	pokedex_order_override SPEAROW, DEX_SPEAROW
	pokedex_order_override FEAROW, DEX_FEAROW
	pokedex_order_override EKANS, DEX_EKANS
	pokedex_order_override ARBOK, DEX_ARBOK
	pokedex_order_override PIKACHU, DEX_PIKACHU
	pokedex_order_override RAICHU, DEX_RAICHU
	pokedex_order_override SANDSHREW, DEX_SANDSHREW
	pokedex_order_override SANDSLASH, DEX_SANDSLASH
	pokedex_order_override NIDORAN_F, DEX_NIDORAN_F
	pokedex_order_override NIDORINA, DEX_NIDORINA
	pokedex_order_override NIDOQUEEN, DEX_NIDOQUEEN
	pokedex_order_override NIDORAN_M, DEX_NIDORAN_M
	pokedex_order_override NIDORINO, DEX_NIDORINO
	pokedex_order_override NIDOKING, DEX_NIDOKING
	pokedex_order_override CLEFAIRY, DEX_CLEFAIRY
	pokedex_order_override CLEFABLE, DEX_CLEFABLE
	pokedex_order_override VULPIX, DEX_VULPIX
	pokedex_order_override NINETALES, DEX_NINETALES
	pokedex_order_override JIGGLYPUFF, DEX_JIGGLYPUFF
	pokedex_order_override WIGGLYTUFF, DEX_WIGGLYTUFF
	pokedex_order_override ZUBAT, DEX_ZUBAT
	pokedex_order_override GOLBAT, DEX_GOLBAT
	pokedex_order_override ODDISH, DEX_ODDISH
	pokedex_order_override GLOOM, DEX_GLOOM
	pokedex_order_override VILEPLUME, DEX_VILEPLUME
	pokedex_order_override PARAS, DEX_PARAS
	pokedex_order_override PARASECT, DEX_PARASECT
	pokedex_order_override VENONAT, DEX_VENONAT
	pokedex_order_override VENOMOTH, DEX_VENOMOTH
	pokedex_order_override DIGLETT, DEX_DIGLETT
	pokedex_order_override DUGTRIO, DEX_DUGTRIO
	pokedex_order_override MEOWTH, DEX_MEOWTH
	pokedex_order_override PERSIAN, DEX_PERSIAN
	pokedex_order_override PSYDUCK, DEX_PSYDUCK
	pokedex_order_override GOLDUCK, DEX_GOLDUCK
	pokedex_order_override MANKEY, DEX_MANKEY
	pokedex_order_override PRIMEAPE, DEX_PRIMEAPE
	pokedex_order_override GROWLITHE, DEX_GROWLITHE
	pokedex_order_override ARCANINE, DEX_ARCANINE
	pokedex_order_override POLIWAG, DEX_POLIWAG
	pokedex_order_override POLIWHIRL, DEX_POLIWHIRL
	pokedex_order_override POLIWRATH, DEX_POLIWRATH
	pokedex_order_override ABRA, DEX_ABRA
	pokedex_order_override KADABRA, DEX_KADABRA
	pokedex_order_override ALAKAZAM, DEX_ALAKAZAM
	pokedex_order_override MACHOP, DEX_MACHOP
	pokedex_order_override MACHOKE, DEX_MACHOKE
	pokedex_order_override MACHAMP, DEX_MACHAMP
	pokedex_order_override BELLSPROUT, DEX_BELLSPROUT
	pokedex_order_override WEEPINBELL, DEX_WEEPINBELL
	pokedex_order_override VICTREEBEL, DEX_VICTREEBEL
	pokedex_order_override TENTACOOL, DEX_TENTACOOL
	pokedex_order_override TENTACRUEL, DEX_TENTACRUEL
	pokedex_order_override GEODUDE, DEX_GEODUDE
	pokedex_order_override GRAVELER, DEX_GRAVELER
	pokedex_order_override GOLEM, DEX_GOLEM
	pokedex_order_override PONYTA, DEX_PONYTA
	pokedex_order_override RAPIDASH, DEX_RAPIDASH
	pokedex_order_override SLOWPOKE, DEX_SLOWPOKE
	pokedex_order_override SLOWBRO, DEX_SLOWBRO
	pokedex_order_override MAGNEMITE, DEX_MAGNEMITE
	pokedex_order_override MAGNETON, DEX_MAGNETON
	pokedex_order_override FARFETCHD, DEX_FARFETCHD
	pokedex_order_override DODUO, DEX_DODUO
	pokedex_order_override DODRIO, DEX_DODRIO
	pokedex_order_override SEEL, DEX_SEEL
	pokedex_order_override DEWGONG, DEX_DEWGONG
	pokedex_order_override GRIMER, DEX_GRIMER
	pokedex_order_override MUK, DEX_MUK
	pokedex_order_override SHELLDER, DEX_SHELLDER
	pokedex_order_override CLOYSTER, DEX_CLOYSTER
	pokedex_order_override GASTLY, DEX_GASTLY
	pokedex_order_override HAUNTER, DEX_HAUNTER
	pokedex_order_override GENGAR, DEX_GENGAR
	pokedex_order_override ONIX, DEX_ONIX
	pokedex_order_override DROWZEE, DEX_DROWZEE
	pokedex_order_override HYPNO, DEX_HYPNO
	pokedex_order_override KRABBY, DEX_KRABBY
	pokedex_order_override KINGLER, DEX_KINGLER
	pokedex_order_override VOLTORB, DEX_VOLTORB
	pokedex_order_override ELECTRODE, DEX_ELECTRODE
	pokedex_order_override EXEGGCUTE, DEX_EXEGGCUTE
	pokedex_order_override EXEGGUTOR, DEX_EXEGGUTOR
	pokedex_order_override CUBONE, DEX_CUBONE
	pokedex_order_override MAROWAK, DEX_MAROWAK
	pokedex_order_override HITMONLEE, DEX_HITMONLEE
	pokedex_order_override HITMONCHAN, DEX_HITMONCHAN
	pokedex_order_override LICKITUNG, DEX_LICKITUNG
	pokedex_order_override KOFFING, DEX_KOFFING
	pokedex_order_override WEEZING, DEX_WEEZING
	pokedex_order_override RHYHORN, DEX_RHYHORN
	pokedex_order_override RHYDON, DEX_RHYDON
	pokedex_order_override CHANSEY, DEX_CHANSEY
	pokedex_order_override TANGELA, DEX_TANGELA
	pokedex_order_override KANGASKHAN, DEX_KANGASKHAN
	pokedex_order_override HORSEA, DEX_HORSEA
	pokedex_order_override SEADRA, DEX_SEADRA
	pokedex_order_override GOLDEEN, DEX_GOLDEEN
	pokedex_order_override SEAKING, DEX_SEAKING
	pokedex_order_override STARYU, DEX_STARYU
	pokedex_order_override STARMIE, DEX_STARMIE
	pokedex_order_override MR_MIME, DEX_MR_MIME
	pokedex_order_override SCYTHER, DEX_SCYTHER
	pokedex_order_override JYNX, DEX_JYNX
	pokedex_order_override ELECTABUZZ, DEX_ELECTABUZZ
	pokedex_order_override MAGMAR, DEX_MAGMAR
	pokedex_order_override PINSIR, DEX_PINSIR
	pokedex_order_override TAUROS, DEX_TAUROS
	pokedex_order_override MAGIKARP, DEX_MAGIKARP
	pokedex_order_override GYARADOS, DEX_GYARADOS
	pokedex_order_override LAPRAS, DEX_LAPRAS
	pokedex_order_override DITTO, DEX_DITTO
	pokedex_order_override EEVEE, DEX_EEVEE
	pokedex_order_override VAPOREON, DEX_VAPOREON
	pokedex_order_override JOLTEON, DEX_JOLTEON
	pokedex_order_override FLAREON, DEX_FLAREON
	pokedex_order_override PORYGON, DEX_PORYGON
	pokedex_order_override OMANYTE, DEX_OMANYTE
	pokedex_order_override OMASTAR, DEX_OMASTAR
	pokedex_order_override KABUTO, DEX_KABUTO
	pokedex_order_override KABUTOPS, DEX_KABUTOPS
	pokedex_order_override AERODACTYL, DEX_AERODACTYL
	pokedex_order_override SNORLAX, DEX_SNORLAX
	pokedex_order_override ARTICUNO, DEX_ARTICUNO
	pokedex_order_override ZAPDOS, DEX_ZAPDOS
	pokedex_order_override MOLTRES, DEX_MOLTRES
	pokedex_order_override DRATINI, DEX_DRATINI
	pokedex_order_override DRAGONAIR, DEX_DRAGONAIR
	pokedex_order_override DRAGONITE, DEX_DRAGONITE
	pokedex_order_override MEWTWO, DEX_MEWTWO
	pokedex_order_override MEW, DEX_MEW
	pokedex_order_override LUGIA, DEX_LUGIA
	pokedex_order_override HOUNDOUR, DEX_HOUNDOUR
	pokedex_order_override HOUNDOOM, DEX_HOUNDOOM
	pokedex_order_override MURKROW, DEX_MURKROW
	pokedex_order_override HONCHKROW, DEX_HONCHKROW
	pokedex_order_override HERACROSS, DEX_HERACROSS
	pokedex_order_override ESPEON, DEX_ESPEON
	pokedex_order_override UMBREON, DEX_UMBREON
	pokedex_order_override GLACEON, DEX_GLACEON
	pokedex_order_override LEAFEON, DEX_LEAFEON
	pokedex_order_override SYLVEON, DEX_SYLVEON
	pokedex_order_override SCIZOR, DEX_SCIZOR
	pokedex_order_override STEELIX, DEX_STEELIX
	pokedex_order_override CROBAT, DEX_CROBAT
	pokedex_order_override POLITOED, DEX_POLITOED
	pokedex_order_override SLOWKING, DEX_SLOWKING
	pokedex_order_override BELLOSSOM, DEX_BELLOSSOM
	pokedex_order_override KINGDRA, DEX_KINGDRA
	pokedex_order_override BLISSEY, DEX_BLISSEY
	pokedex_order_override PORYGON2, DEX_PORYGON2
	pokedex_order_override PORYGONZ, DEX_PORYGONZ
	pokedex_order_override MAGMORTAR, DEX_MAGMORTAR
	pokedex_order_override ELECTIVIRE, DEX_ELECTIVIRE
	pokedex_order_override MAGNEZONE, DEX_MAGNEZONE
	pokedex_order_override RHYPERIOR, DEX_RHYPERIOR
	pokedex_order_override TANGROWTH, DEX_TANGROWTH
	pokedex_order_override LICKILICKY, DEX_LICKILICKY
	pokedex_order_override TOGEPI, DEX_TOGEPI
	pokedex_order_override TOGETIC, DEX_TOGETIC
	pokedex_order_override TOGEKISS, DEX_TOGEKISS
	pokedex_order_override SNEASEL, DEX_SNEASEL
	pokedex_order_override WEAVILE, DEX_WEAVILE
	pokedex_order_override SKARMORY, DEX_SKARMORY
	pokedex_order_override MISDREAVUS, DEX_MISDREAVUS
	pokedex_order_override MISMAGIUS, DEX_MISMAGIUS
	pokedex_order_override MILTANK, DEX_MILTANK
	pokedex_order_override CHINCHOU, DEX_CHINCHOU
	pokedex_order_override LANTURN, DEX_LANTURN
	pokedex_order_override SLUGMA, DEX_SLUGMA
	pokedex_order_override MAGCARGO, DEX_MAGCARGO
	pokedex_order_override TORKOAL, DEX_TORKOAL
	pokedex_order_override LATIAS, DEX_LATIAS
	pokedex_order_override LATIOS, DEX_LATIOS
	pokedex_order_override HITMONTOP, DEX_HITMONTOP
	pokedex_order_override TYROGUE, DEX_TYROGUE
	pokedex_order_override PICHU, DEX_PICHU
	pokedex_order_override CLEFFA, DEX_CLEFFA
	pokedex_order_override IGGLYBUFF, DEX_IGGLYBUFF
	pokedex_order_override SMOOCHUM, DEX_SMOOCHUM
	pokedex_order_override ELEKID, DEX_ELEKID
	pokedex_order_override MAGBY, DEX_MAGBY
	pokedex_order_override MIME_JR, DEX_MIME_JR
	pokedex_order_override HAPPINY, DEX_HAPPINY
	pokedex_order_override MUNCHLAX, DEX_MUNCHLAX
	pokedex_order_override ZIGZAGOON, DEX_ZIGZAGOON
	pokedex_order_override LINOONE, DEX_LINOONE
	pokedex_order_override HO_OH, DEX_HO_OH
ASSERT PokedexOrderDeclarationCount == NUM_POKEMON
IF PokedexOrderOverrideCount != 0
	db 0 ; end
ENDC
PokedexOrderOverridesEnd:
IF PokedexOrderOverrideCount == 0
ASSERT PokedexOrderOverridesEnd - PokedexOrderOverrides == 0
ELSE
ASSERT PokedexOrderOverridesEnd - PokedexOrderOverrides == PokedexOrderOverrideCount * 2 + 1
ENDC
