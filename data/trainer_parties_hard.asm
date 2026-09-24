; TRN-5.33.02: trainer_party_name scopes packed_names to the name field.
; Runtime decoding preserves the original wCurTrainerName representation.

TrainerDataPointers: ; Originally created 28/06/2015 by Neodymium / Free to use and change without crediting
	dw YoungsterData
	dw BugCatcherData
	dw LassData
	dw SailorData
	dw CamperData
	dw PicnickerData
	dw PokemaniacData
	dw SuperNerdData
	dw HikerData
	dw BikerData
	dw BurglarData
	dw EngineerData
	dw CoupleData
	dw FisherData
	dw SwimmerData
	dw CueBallData
	dw GamblerData
	dw BeautyData
	dw PsychicData
	dw RockerData
	dw JugglerData
	dw TamerData
	dw BirdKeeperData
	dw BlackbeltData
	dw Green1Data
	dw SwimmerFData ; Shared with Beauty
	dw RocketFData ; Shared with male Rocket
	dw ScientistData
	dw GiovanniData
	dw RocketData
	dw AceTrainerMData
	dw AceTrainerFData
	dw BrunoData
	dw BrockData
	dw MistyData
	dw LtSurgeData
	dw ErikaData
	dw KogaData
	dw BlaineData
	dw SabrinaData
	dw GentlemanData
	dw Green2Data
	dw Green3Data
	dw LoreleiData
	dw ChannelerData
	dw AgathaData
	dw LanceData
	dw HexManiacData
	dw PkmnTrainerData

; first is the name, followed by the first byte of the data

; if not a Special Trainer,
	; first byte is level (of all pokemon on this team)
	; all the next bytes are pokemon species
	; FF-terminated
; if first byte == SPECIAL_TRAINER, then
	; each Pokemon entry is Level, Species, Moveset
	; FF-terminated
; if first byte == SPECIAL_TRAINER2, then
	; second byte is custom sprite number
	; third byte is custom AI number
	; each Pokemon entry is Level, Species, Moveset
	; FF-terminated
; if first byte == CUSTOM_PIC, then
	; second byte is custom sprite number
	; third byte is level (of all pokemon on this team)
	; all the next bytes are pokemon species
	; FF-terminated
; if first byte == SPECIAL_LEVELS, then
	; each Pokemon entry is Level, Species
	; FF-terminated

	
BrockData:
	trainer_party_name "Brock"
	db SPECIAL_TRAINER
	db 12,AERODACTYL
	moveset WING_ATTACK, SAND_ATTACK, ROCK_TOMB, AGILITY
	
	db 13,OMASTAR
	moveset AURORA_BEAM, WATER_GUN, TACKLE, ROCK_TOMB
	
	db 15,KABUTOPS
	moveset ABSORB, WATER_GUN, SCRATCH, ROCK_TOMB
	
	db $FF
	
MistyData:
	trainer_party_name "Misty"
	db SPECIAL_TRAINER
	
	db 25,VAPOREON
	moveset AURORA_BEAM, BODY_SLAM, SAND_ATTACK, WATER_PULSE
	
	db 25,POLIWRATH
	moveset DOUBLESLAP, AURORA_BEAM, DIG, WATER_PULSE
	
	db 25,DEWGONG
	moveset HORN_ATTACK, AURORA_BEAM, BODY_SLAM, WATER_PULSE
	
	db 26,STARMIE
	moveset THUNDER_WAVE, WATER_PULSE, THUNDERBOLT, RECOVER
	
	db 25,LAPRAS
	moveset BODY_SLAM, CONFUSE_RAY, WATER_PULSE, AURORA_BEAM
	db $FF
	
LtSurgeData:
	trainer_party_name "Lt. Surge"
	db SPECIAL_TRAINER
	
	db 35,ELECTRODE
	moveset THUNDERBOLT, TACKLE, SCREECH, SONICBOOM
	
	db 34,MAGNETON
	moveset SUPERSONIC, DOUBLE_TEAM, THUNDERBOLT, FLASH_CANNON
	
	db 35,JOLTEON
	moveset PIN_MISSILE, SAND_ATTACK, THUNDERBOLT, HEADBUTT
	
	db 34,ELECTABUZZ
	moveset QUICK_ATTACK, THUNDERBOLT, LIGHT_SCREEN, LOW_KICK
	
	db 36,RAICHU
	moveset AGILITY, ELECTRO_BALL, THUNDER_WAVE, SWIFT
	db $FF
	
ErikaData:
	trainer_party_name "Erika"
	db SPECIAL_TRAINER
	
	db 45,VILEPLUME
	moveset PETALBLIZARD, GIGA_DRAIN, SLEEP_POWDER, ACID
	
	db 44,VENUSAUR
	moveset PETALBLIZARD, LIGHT_SCREEN, TOXIC, RECOVER
	
	db 44,TANGROWTH
	moveset ANCIENTPOWER, WOOD_HAMMER, EARTHQUAKE, SWORDS_DANCE
	
	db 45,VICTREEBEL
	moveset SUCKER_PUNCH, LEAF_BLADE, SWORDS_DANCE, REFLECT
	
	db 46,EXEGGUTOR
	moveset EXTRASENSORY, SOLARBEAM, HYPNOSIS, AMNESIA
	db $FF
	
KogaData:
	trainer_party_name "Koga"
	db SPECIAL_TRAINER
	
	db 60,VENOMOTH
	moveset PSYCHIC_M, SIGNAL_BEAM, AERIAL_ACE, TOXIC
	
	db 59,WEEZING
	moveset SHADOW_BALL, SLUDGE_WAVE, TOXIC, FLAMETHROWER
	
	db 60,NIDOKING
	moveset DOUBLE_KICK, EARTHQUAKE, TOXIC, MEGAHORN
	
	db 59,TENTACRUEL
	moveset TOXIC, ACID, WHIRLPOOL, SLUDGE_WAVE
	
	db 61,GENGAR
	moveset HEX, TOXIC, GUNK_SHOT, DARK_PULSE
	db $FF
	
SabrinaData:
	trainer_party_name "Sabrina"
	db SPECIAL_TRAINER
	
	db 55,JYNX
	moveset PSYCHIC_M, BLIZZARD, LOVELY_KISS, DREAM_EATER
	
	db 54,SLOWKING
	moveset PSYCHIC_M, ICE_BEAM, AMNESIA, SHADOW_BALL
	
	db 54,HYPNO
	moveset HYPNOSIS, HEX, PSYCHIC_M, AMNESIA
	
	db 55,ALAKAZAM
	moveset PSYCHIC_M, SHADOW_BALL, AMNESIA, DAZZLINGLEAM
	
	db 56,ESPEON
	moveset SHADOW_BALL, PSYCHIC_M, AMNESIA, SIGNAL_BEAM
	db $FF
	
BlaineData:
	trainer_party_name "Blaine"
	db SPECIAL_TRAINER
	
	db 65,CHARIZARD
	moveset ACROBATICS, FIRE_BLAST, DRAGONBREATH, EARTHQUAKE
	
	db 64,RAPIDASH
	moveset EXTREMESPEED, AGILITY, MEGAHORN, FIRE_BLAST
	
	db 64,FLAREON
	moveset FLARE_BLITZ, HEADBUTT, DOUBLE_EDGE, MUD_SLAP
	
	db 65,ARCANINE
	moveset EXTREMESPEED, BITE, FLARE_BLITZ, SWORDS_DANCE 
	
	db 66,MAGMORTAR
	moveset FOCUS_ENERGY, FIRE_BLAST, HYPER_BEAM, FIRE_SPIN
	db $FF
	
; Giovanni Gym Battle
	trainer_party_name "Giovanni"
	db SPECIAL_TRAINER2
	db GIOVANNI_2 ; pic
	db AI_HYPER_POTION ; AI
	
	db 66,GENGAR
	moveset GLARE, HEX, GUNK_SHOT, DARK_PULSE
	
	db 66,STEELIX
	moveset IRON_TAIL, ROCK_SLIDE, BIND, DRAGONBREATH
	
	db 67,NIDOQUEEN
	moveset DOUBLE_KICK, THUNDERBOLT, POISON_FANG, EARTHQUAKE
	
	db 68,NIDOKING
	moveset DOUBLE_KICK, EARTHQUAKE, POISON_JAB, ICE_BEAM
	
	db 67,RHYPERIOR
	moveset ROCK_SLIDE, MEGAHORN, SURF, EARTHQUAKE
	
	db 67,TAUROS
	moveset STOMP, ZEN_HEADBUTT, REST, EARTHQUAKE
	db $FF
	
GiovanniData:
	; Game Corner
	trainer_party_name "Giovanni"
	db SPECIAL_TRAINER
	
	db 47,STEELIX
	moveset IRON_TAIL, ROCK_SLIDE, BIND, DRAGONBREATH
	
	db 46,DUGTRIO
	moveset HONE_CLAWS, EARTHQUAKE, NIGHT_SLASH, MUD_BOMB
	
	db 47,NIDOQUEEN
	moveset DOUBLE_KICK, THUNDERBOLT, POISON_FANG, EARTHQUAKE
	
	db 46,NIDOKING
	moveset DOUBLE_KICK, EARTHQUAKE, POISON_JAB, ICE_BEAM
	
	db 47,RHYDON
	moveset ROCK_SLIDE, MEGAHORN, SURF, TAKE_DOWN
	
	db 48,TAUROS
	moveset STOMP, ZEN_HEADBUTT, REST, EARTHQUAKE
	db $FF
	
	
	; Silph Co
	trainer_party_name "Giovanni"
	db SPECIAL_TRAINER
	
	db 55,PERSIAN
	moveset CRUNCH, SLASH, POWER_GEM, SHADOW_CLAW
	
	db 54,STEELIX
	moveset IRON_TAIL, ROCK_SLIDE, BIND, DRAGONBREATH
	
	db 55,NIDOQUEEN
	moveset DOUBLE_KICK, THUNDERBOLT, POISON_FANG, EARTHQUAKE
	
	db 55,NIDOKING
	moveset DOUBLE_KICK, EARTHQUAKE, POISON_JAB, ICE_BEAM
	
	db 55,RHYDON
	moveset ROCK_SLIDE, MEGAHORN, SURF, TAKE_DOWN
	
	db 56,TAUROS
	moveset STOMP, ZEN_HEADBUTT, REST, EARTHQUAKE
	db $FF
	
LoreleiData:
	trainer_party_name "Lorelei"
	db SPECIAL_TRAINER
	
	db 77,CLOYSTER
	moveset WHIRLPOOL, ICE_BEAM, CLAMP, IRON_DEFENSE
	
	db 78,VAPOREON
	moveset SURF, AURORA_BEAM, ACID_ARMOR, MUD_SLAP
	
	db 76,SLOWKING
	moveset AMNESIA, POWER_GEM, PSYCHIC_M, ICE_BEAM
	
	db 77,JYNX
	moveset DOUBLESLAP, ICE_BEAM, LOVELY_KISS, PSYCHIC_M
	
	db 78,LAPRAS
	moveset BODY_SLAM, CONFUSE_RAY, SURF, ICE_BEAM
	db $FF
	
BrunoData:
	trainer_party_name "Bruno"
	db SPECIAL_TRAINER
	
	db 78,STEELIX
	moveset IRON_TAIL, ROCK_SLIDE, EARTHQUAKE, IRON_DEFENSE
	
	db 77,HITMONCHAN
	moveset SHADOW_PUNCH, SUCKER_PUNCH, FOCUS_ENERGY, DYNAMICPUNCH
	
	db 77,HITMONLEE
	moveset MEGA_KICK, HI_JUMP_KICK, FOCUS_ENERGY, DOUBLE_KICK
	
	db 78,PRIMEAPE
	moveset CROSS_CHOP, DYNAMICPUNCH, FOCUS_ENERGY, SWORDS_DANCE
	
	db 77,MACHAMP
	moveset STORM_THROW, SUBMISSION, COUNTER, FOCUS_ENERGY
	db $FF
	
AgathaData:
	trainer_party_name "Agatha"
	db SPECIAL_TRAINER
	
	db 79,MISDREAVUS
	moveset GLARE, HEX, THUNDERBOLT, AMNESIA
	
	db 78,HONCHKROW
	moveset ACROBATICS, HEX, FEINT_ATTACK, HEALINGLIGHT
	
	db 78,HOUNDOOM
	moveset SHADOW_BALL, FIRE_FANG, HEX, CRUNCH
	
	db 78,MISMAGIUS
	moveset GLARE, HEX, POWER_GEM, PSYCHIC_M
	
	db 77,GENGAR
	moveset MOONBLAST, HYPNOSIS, HEX, DREAM_EATER
	db $FF
	
LanceData:
	trainer_party_name "Lance"
	db SPECIAL_TRAINER
	
	db 80,GYARADOS
	moveset DRAGONBREATH, THRASH, SURF, HYPER_BEAM
	
	db 80,CHARIZARD
	moveset BLAST_BURN, DRAGONBREATH, AERIAL_ACE, METAL_CLAW
	
	db 79,KINGDRA
	moveset WHIRLPOOL, DRAGONBREATH, FOCUS_ENERGY, HYPER_BEAM
	
	db 80,AERODACTYL
	moveset ANCIENTPOWER, ACROBATICS, DRAGONBREATH, ROCK_SLIDE
	
	db 79,DRAGONITE
	moveset DRACO_METEOR, THUNDER_WAVE, HURRICANE, AMNESIA
	db $FF	
	
Green1Data:
	; Oak's Lab
	trainer_party_name "[RIVAL]",5,SQUIRTLE,$FF
	trainer_party_name "[RIVAL]",5,BULBASAUR,$FF
	trainer_party_name "[RIVAL]",5,CHARMANDER,$FF
	
	
	; Beside Viridian
	trainer_party_name "[RIVAL]",SPECIAL_LEVELS,10,EEVEE,9,RATTATA,9,PIDGEY,11,SQUIRTLE,$FF
	trainer_party_name "[RIVAL]",SPECIAL_LEVELS,10,EEVEE,9,RATTATA,9,PIDGEY,11,BULBASAUR,$FF
	trainer_party_name "[RIVAL]",SPECIAL_LEVELS,10,EEVEE,9,RATTATA,9,PIDGEY,11,CHARMANDER,$FF
	
	
	; Cerulean City
	trainer_party_name "[RIVAL]"
	db SPECIAL_TRAINER
	
	db 21,VAPOREON
	moveset HEADBUTT, MUDDY_WATER, TAIL_WHIP, QUICK_ATTACK
	
	db 20,PIDGEOTTO
	moveset SAND_ATTACK, GUST, QUICK_ATTACK, TACKLE
	
	db 21,KADABRA
	moveset TELEPORT, ZEN_HEADBUTT, KINESIS, 0
	
	db 20,RATICATE
	moveset QUICK_ATTACK, BITE, FEINT_ATTACK, FOCUS_ENERGY
	
	db 20,WARTORTLE
	moveset BITE, WITHDRAW, WHIRLPOOL, TACKLE
	db $FF
	
	
	
	trainer_party_name "[RIVAL]"
	db SPECIAL_TRAINER
	
	db 21,JOLTEON
	moveset HEADBUTT, THUNDER_FANG, TAIL_WHIP, QUICK_ATTACK
	
	db 20,PIDGEOTTO
	moveset SAND_ATTACK, GUST, QUICK_ATTACK, TACKLE
	
	db 21,KADABRA
	moveset TELEPORT, ZEN_HEADBUTT, KINESIS, 0
	
	db 20,RATICATE
	moveset QUICK_ATTACK, BITE, FEINT_ATTACK, FOCUS_ENERGY
	
	db 20,IVYSAUR
	moveset RAZOR_LEAF, LEECH_SEED, POISONPOWDER, TAKE_DOWN
	db $FF
	
	
	
	trainer_party_name "[RIVAL]"
	db SPECIAL_TRAINER
	
	db 21,FLAREON
	moveset HEADBUTT, FIRE_FANG, TAIL_WHIP, QUICK_ATTACK
	
	db 20,PIDGEOTTO
	moveset SAND_ATTACK, GUST, QUICK_ATTACK, TACKLE
	
	db 21,KADABRA
	moveset TELEPORT, ZEN_HEADBUTT, KINESIS, 0
	
	db 20,RATICATE
	moveset QUICK_ATTACK, BITE, FEINT_ATTACK, FOCUS_ENERGY
	
	db 20,CHARMELEON
	moveset EMBER, DRAGON_RAGE, LEER, METAL_CLAW
	db $FF
	
Green2Data:
	; SS ANNE
	trainer_party_name "[RIVAL]"
	db SPECIAL_TRAINER
	
	db 33,VAPOREON
	moveset HEADBUTT, AURORA_BEAM, MUD_SLAP, QUICK_ATTACK
	
	db 32,RATICATE
	moveset QUICK_ATTACK, BITE, FEINT_ATTACK, FOCUS_ENERGY
	
	db 32,KADABRA
	moveset TELEPORT, ZEN_HEADBUTT, KINESIS, SHADOW_BALL
	
	db 33,WARTORTLE
	moveset BITE, DOUBLE_TEAM, WHIRLPOOL, TACKLE
	
	db 31,GROWLITHE
	moveset BITE, ROAR, FLAME_WHEEL, QUICK_ATTACK
	db $FF
	
	
	
	trainer_party_name "[RIVAL]"
	db SPECIAL_TRAINER
	
	db 33,JOLTEON
	moveset HEADBUTT, THUNDERBOLT, MUD_SLAP, QUICK_ATTACK
	
	db 32,RATICATE
	moveset QUICK_ATTACK, BITE, FEINT_ATTACK, FOCUS_ENERGY
	
	db 32,KADABRA
	moveset TELEPORT, ZEN_HEADBUTT, KINESIS, SHADOW_BALL
	
	db 33,IVYSAUR
	moveset RAZOR_LEAF, LEECH_SEED, POISONPOWDER, TAKE_DOWN
	
	db 31,GROWLITHE
	moveset BITE, ROAR, FLAME_WHEEL, QUICK_ATTACK
	db $FF
	
	
	
	trainer_party_name "[RIVAL]"
	db SPECIAL_TRAINER
	
	db 33,FLAREON
	moveset HEADBUTT, FIRE_SPIN, MUD_SLAP, QUICK_ATTACK
	
	db 32,RATICATE
	moveset QUICK_ATTACK, BITE, FEINT_ATTACK, FOCUS_ENERGY
	
	db 32,KADABRA
	moveset TELEPORT, ZEN_HEADBUTT, KINESIS, SHADOW_BALL
	
	db 33,CHARMELEON
	moveset FLAME_WHEEL, DRAGON_RAGE, LEER, METAL_CLAW
	
	db 31,GROWLITHE
	moveset BITE, ROAR, FLAME_WHEEL, QUICK_ATTACK
	db $FF
	
	
	
	
	; Pokemon Tower
	trainer_party_name "[RIVAL]"
	db SPECIAL_TRAINER
	
	db 45,VAPOREON
	moveset HYDRO_PUMP, MUD_SLAP, DOUBLE_EDGE, ACID_ARMOR
	
	db 43,ARCANINE
	moveset EXTREMESPEED, CRUNCH, FLAMETHROWER, EARTHQUAKE
	
	db 42,EXEGGUTOR
	moveset WOOD_HAMMER, POISONPOWDER, CONFUSION, AMNESIA
	
	db 43,ALAKAZAM
	moveset PSYCHIC_M, SHADOW_BALL, REFLECT, RECOVER
	
	db 45,BLASTOISE
	moveset SKULL_BASH, WHIRLPOOL, BITE, DOUBLE_TEAM
	db $FF
	
	
	
	trainer_party_name "[RIVAL]"
	db SPECIAL_TRAINER
	
	db 45,JOLTEON
	moveset THUNDERBOLT, MUD_SLAP, DOUBLE_EDGE, AGILITY
	
	db 43,GYARADOS
	moveset BITE, THRASH, WATERFALL, DRAGON_RAGE
	
	db 43,ARCANINE
	moveset EXTREMESPEED, CRUNCH, FLAMETHROWER, EARTHQUAKE
	
	db 43,ALAKAZAM
	moveset PSYCHIC_M, SHADOW_BALL, REFLECT, RECOVER
	
	db 45,VENUSAUR
	moveset PETAL_DANCE, RECOVER, POISONPOWDER, TAKE_DOWN
	db $FF
	
	
	
	trainer_party_name "[RIVAL]"
	db SPECIAL_TRAINER
	
	db 45,FLAREON
	moveset FLAMETHROWER, MUD_SLAP, DOUBLE_EDGE, AGILITY
	
	db 42,EXEGGUTOR
	moveset WOOD_HAMMER, POISONPOWDER, CONFUSION, AMNESIA
	
	db 43,GYARADOS
	moveset BITE, THRASH, WATERFALL, DRAGON_RAGE
	
	db 43,ALAKAZAM
	moveset PSYCHIC_M, SHADOW_BALL, REFLECT, RECOVER
	
	db 45,CHARIZARD
	moveset FLAME_WHEEL, DRAGON_RAGE, WING_ATTACK, METAL_CLAW
	db $FF
	
	
	
	; Silph Co
	trainer_party_name "[RIVAL]"
	db SPECIAL_TRAINER
	
	db 52,VAPOREON
	moveset HYDRO_PUMP, MUD_SLAP, DOUBLE_EDGE, ACID_ARMOR
	
	db 53,ARCANINE
	moveset EXTREMESPEED, CRUNCH, FLAMETHROWER, EARTHQUAKE
	
	db 50,EXEGGUTOR
	moveset WOOD_HAMMER, POISONPOWDER, CONFUSION, AMNESIA
	
	db 50,ALAKAZAM
	moveset PSYCHIC_M, SHADOW_BALL, REFLECT, RECOVER
	
	db 55,BLASTOISE
	moveset SKULL_BASH, WHIRLPOOL, BITE, DOUBLE_TEAM
	db $FF
	
	
	
	trainer_party_name "[RIVAL]"
	db SPECIAL_TRAINER
	
	db 52,JOLTEON
	moveset THUNDERBOLT, MUD_SLAP, DOUBLE_EDGE, AGILITY
	
	db 53,GYARADOS
	moveset BITE, THRASH, WATERFALL, DRAGON_RAGE
	
	db 50,ARCANINE
	moveset EXTREMESPEED, CRUNCH, FLAMETHROWER, EARTHQUAKE
	
	db 50,ALAKAZAM
	moveset PSYCHIC_M, SHADOW_BALL, REFLECT, RECOVER
	
	db 55,VENUSAUR
	moveset PETAL_DANCE, RECOVER, POISONPOWDER, TAKE_DOWN
	db $FF
	
	
	
	trainer_party_name "[RIVAL]"
	db SPECIAL_TRAINER
	
	db 52,FLAREON
	moveset FLAMETHROWER, MUD_SLAP, DOUBLE_EDGE, AGILITY
	
	db 53,EXEGGUTOR
	moveset WOOD_HAMMER, POISONPOWDER, CONFUSION, AMNESIA
	
	db 50,GYARADOS
	moveset BITE, THRASH, WATERFALL, DRAGON_RAGE
	
	db 50,ALAKAZAM
	moveset PSYCHIC_M, SHADOW_BALL, REFLECT, RECOVER
	
	db 55,CHARIZARD
	moveset FLAME_WHEEL, DRAGON_RAGE, WING_ATTACK, METAL_CLAW
	db $FF
	
	
	
	; Before Elite Four
	trainer_party_name "[RIVAL]"
	db SPECIAL_TRAINER
	
	db 70,VAPOREON
	moveset HYDRO_PUMP, MUD_SLAP, DOUBLE_EDGE, ACID_ARMOR
	
	db 70,RHYDON
	moveset EARTHQUAKE, MEGAHORN, ROCK_BLAST, TAKE_DOWN
	
	db 70,ARCANINE
	moveset EXTREMESPEED, CRUNCH, FLAMETHROWER, EARTHQUAKE
	
	db 71,EXEGGUTOR
	moveset WOOD_HAMMER, EGG_BOMB, PSYCHIC_M, AMNESIA
	
	db 70,ALAKAZAM
	moveset PSYCHIC_M, SHADOW_BALL, REFLECT, RECOVER
	
	db 72,BLASTOISE
	moveset SKULL_BASH, HYDRO_CANNON, BITE, DOUBLE_TEAM
	db $FF
	
	
	
	trainer_party_name "[RIVAL]"
	db SPECIAL_TRAINER
	
	db 70,JOLTEON
	moveset THUNDERBOLT, MUD_SLAP, DOUBLE_EDGE, AGILITY
	
	db 70,RHYDON
	moveset EARTHQUAKE, MEGAHORN, ROCK_BLAST, TAKE_DOWN
	
	db 70,GYARADOS
	moveset BITE, THRASH, WATERFALL, DRAGON_RAGE
	
	db 71,ARCANINE
	moveset EXTREMESPEED, CRUNCH, FLAMETHROWER, EARTHQUAKE
	
	db 70,ALAKAZAM
	moveset PSYCHIC_M, SHADOW_BALL, REFLECT, RECOVER
	
	db 72,VENUSAUR
	moveset FRENZY_PLANT, RECOVER, POISONPOWDER, TAKE_DOWN
	db $FF
	
	
	
	trainer_party_name "[RIVAL]"
	db SPECIAL_TRAINER
	
	db 70,FLAREON
	moveset FLAMETHROWER, MUD_SLAP, DOUBLE_EDGE, AGILITY
	
	db 70,RHYDON
	moveset EARTHQUAKE, MEGAHORN, ROCK_BLAST, TAKE_DOWN
	
	db 70,EXEGGUTOR
	moveset WOOD_HAMMER, EGG_BOMB, PSYCHIC_M, AMNESIA
	
	db 71,GYARADOS
	moveset BITE, THRASH, WATERFALL, DRAGON_RAGE
	
	db 70,ALAKAZAM
	moveset PSYCHIC_M, SHADOW_BALL, REFLECT, RECOVER
	
	db 72,CHARIZARD
	moveset BLAST_BURN, DRAGON_RAGE, AERIAL_ACE, METAL_CLAW
	db $FF
	
Green3Data:
	; Champion
	trainer_party_name "[RIVAL]"
	db SPECIAL_TRAINER
	
	db 80,PIDGEOT
	moveset TWISTER, ACROBATICS, AGILITY, HURRICANE
	
	db 79,ALAKAZAM
	moveset PSYCHIC_M, SHADOW_BALL, REFLECT, RECOVER
	
	db 80,RHYPERIOR
	moveset EARTHQUAKE, MEGAHORN, ROCK_BLAST, TAKE_DOWN
	
	db 80,ARCANINE
	moveset EXTREMESPEED, CRUNCH, FLAMETHROWER, EARTHQUAKE
	
	db 80,EXEGGUTOR
	moveset WOOD_HAMMER, EGG_BOMB, PSYCHIC_M, AMNESIA
	
	db 80,BLASTOISE
	moveset SKULL_BASH, HYDRO_CANNON, BITE, DOUBLE_TEAM
	db $FF
	
	
	
	trainer_party_name "[RIVAL]"
	db SPECIAL_TRAINER
	
	db 80,PIDGEOT
	moveset TWISTER, ACROBATICS, AGILITY, HURRICANE
	
	db 79,ALAKAZAM
	moveset PSYCHIC_M, SHADOW_BALL, REFLECT, RECOVER
	
	db 80,RHYPERIOR
	moveset EARTHQUAKE, MEGAHORN, ROCK_BLAST, TAKE_DOWN
	
	db 80,ARCANINE
	moveset EXTREMESPEED, CRUNCH, FLAMETHROWER, EARTHQUAKE
	
	db 80,EXEGGUTOR
	moveset WOOD_HAMMER, EGG_BOMB, PSYCHIC_M, AMNESIA
	
	db 80,VENUSAUR
	moveset FRENZY_PLANT, RECOVER, EARTHQUAKE, TAKE_DOWN
	db $FF
	
	
	
	trainer_party_name "[RIVAL]"
	db SPECIAL_TRAINER
	
	db 80,PIDGEOT
	moveset TWISTER, ACROBATICS, AGILITY, HURRICANE
	
	db 79,ALAKAZAM
	moveset PSYCHIC_M, SHADOW_BALL, REFLECT, RECOVER
	
	db 80,RHYPERIOR
	moveset EARTHQUAKE, MEGAHORN, ROCK_BLAST, TAKE_DOWN
	
	db 80,ARCANINE
	moveset EXTREMESPEED, CRUNCH, FLAMETHROWER, EARTHQUAKE
	
	db 80,EXEGGUTOR
	moveset WOOD_HAMMER, EGG_BOMB, PSYCHIC_M, AMNESIA
	
	db 80,CHARIZARD
	moveset BLAST_BURN, DRAGON_RAGE, AERIAL_ACE, METAL_CLAW
	db $FF
	
YoungsterData: ; COMPLETED
	trainer_party_name "Ben",14,ZIGZAGOON,RATTATA,$FF ; ROUTE3 #3
	trainer_party_name "Arnold",14,SPEAROW,SANDSHREW,$FF ; ROUTE3 #5
	trainer_party_name "Anthony",16,RATTATA,MACHOP,ZUBAT,$FF ; #MTMOON #6
	trainer_party_name "Samuel",20,RATICATE,ARBOK,GOLBAT,$FF ; NUGGET BRIDGE #4
	trainer_party_name "Adam",23,RATTATA,SPEAROW,$FF ; ROUTE 25 2
	trainer_party_name "Ben",23,SLOWPOKE,SHELLDER,$FF ; Route 25 3u
	trainer_party_name "Calvin",23,EKANS,SANDSHREW,$FF ; Route 25 7
	trainer_party_name "Chad",25,NIDORINO,$FF ;  SS_ANNE
	trainer_party_name "Dan",25,EKANS,KOFFING,$FF ; Route 12 1
	trainer_party_name "Dave",26,SANDSHREW,ZUBAT,$FF ; Route 12 2u
	trainer_party_name "Josh",26,ZIGZAGOON,LINOONE,$FF ; Route 12 6u
	trainer_party_name "Timmy",26,NIDORAN_M,NIDORINO,$FF ; Route 12 2d
	trainer_party_name "Nash",23,SPEAROW,RATTATA,RATTATA,SPEAROW,$FF ; 					UNKNOWN
	
BugCatcherData: ; COMPLETED
	trainer_party_name "Luke",9,WEEDLE,CATERPIE,$FF ; VIRIDIAN FOREST #1
	trainer_party_name "Finn",11,KAKUNA,METAPOD,$FF ; VIRIDIAN FOREST #2
	trainer_party_name "Jake",13,BUTTERFREE,BEEDRILL,$FF ; VIRIDIAN FOREST #3
	trainer_party_name "David",15,WEEDLE,KAKUNA,$FF ; ROUTE3 #2
	trainer_party_name "Lou",15,CATERPIE,METAPOD,$FF ; ; ROUTE3 #4
	trainer_party_name "Larry",15,ODDISH,BELLSPROUT,VENONAT,$FF ; ROUTE3 6
	trainer_party_name "Chuck",17,BUTTERFREE,$FF ; MTMOON #2
	trainer_party_name "Zach",17,BEEDRILL,$FF ; MTMOON #4
	trainer_party_name "Chris",20,BUTTERFREE,SCYTHER,$FF ; NUGGET BRIDGE #1
	trainer_party_name "Rick",25,BUTTERFREE,TANGELA,$FF ; Route 6
	trainer_party_name "Bob",25,BUTTERFREE,$FF ; Route 6 3
	trainer_party_name "Gray",33,METAPOD,CATERPIE,VENONAT,$FF ; 							UNKNOWN
	trainer_party_name "Matt",32,BEEDRILL,BUTTERFREE,$FF ; Route9 4rt
	trainer_party_name "Ed",33,VENOMOTH,TANGELA,$FF ; Route9 3rt
	
LassData: ; COMPLETED
	trainer_party_name "Nicole",14,JIGGLYPUFF,JIGGLYPUFF,EEVEE,$FF ; ROUTE #3 #1
	trainer_party_name "Jennifer",15,JIGGLYPUFF,CLEFAIRY,$FF ; ROUTE #3 #5
	trainer_party_name "Hillary",15,WIGGLYTUFF,CLEFABLE,$FF ; ; ROUTE #3 #7
	trainer_party_name "Rachel",45,PARAS,PARAS,PARASECT,$FF ; Beside Cerulean Cave
	trainer_party_name "Christy",16,ODDISH,BELLSPROUT,$FF ; MTMOON #5
	trainer_party_name "Jessica",16,CLEFAIRY,$FF ; MTMOON #1
	trainer_party_name "Trish",20,NIDORINO,CLEFABLE,$FF ; Nuggetbridge 2
	trainer_party_name "Monica",20,NIDORINA,WIGGLYTUFF,$FF ; Nuggetbridge 4
	trainer_party_name "Lulu",23,NIDORINO,NIDORINA,$FF ; Route25 4
	trainer_party_name "Brooke",23,ODDISH,PIDGEOTTO,$FF ; Route25 8
	trainer_party_name "Rose",25,TOGETIC,ESPEON,$FF ; SSANNE
	trainer_party_name "Martha",25,RATTATA,PIKACHU,$FF ; 	SSANNE
	trainer_party_name "Amanda",36,NIDOQUEEN,$FF ; Route 8 4t
	trainer_party_name "Meadow",36,PERSIAN,PIDGEOT,$FF ; Route 8 4t
	trainer_party_name "Whitney",36,DRAGONAIR,NIDOKING,PERSIAN,$FF ; Route 8 4dwn
	trainer_party_name "Samantha",37,CLEFABLE,$FF ; ROUTE 8 1
	trainer_party_name "Katie",41,BELLSPROUT,WEEPINBELL,VICTREEBEL,$FF ; CELADON GYM 1
	trainer_party_name "Bella",43,VILEPLUME,$FF ; CELADON GYM right
	
SailorData: ; COMPLETED
	trainer_party_name "Jack",25,OMANYTE,KABUTO,$FF ; SSANNE 1
	trainer_party_name "Will",25,MACHOP,TENTACOOL,$FF ; SSANNE 2
	trainer_party_name "Lewis",25,SHELLDER,TENTACOOL,$FF ; SSANNE 3
	trainer_party_name "Huey",26,HORSEA,SHELLDER,TENTACOOL,$FF ; SSANNE BASEMENT
	trainer_party_name "Dave",26,TENTACOOL,STARYU,KABUTO,$FF ; SSANNE 4
	trainer_party_name "Eugene",25,SQUIRTLE,TENTACOOL,$FF ; SSANNE 4
	trainer_party_name "Flynn",25,MACHOP,MANKEY,HITMONCHAN,$FF ; SSANNE 5
	trainer_party_name "Hans",35,RAICHU,$FF ; VERMILLION GYM
	
CamperData: 
	trainer_party_name "Daniel",14,DIGLETT,SANDSHREW,$FF ; PEWTER GYM
	trainer_party_name "Craig",23,POLIWAG,GOLDEEN,$FF ; Route 25
	trainer_party_name "Harry",20,PRIMEAPE,MACHOKE,$FF ; Nugget bridge 5
	trainer_party_name "Ronald",25,DITTO,MEOWTH,$FF ; Route 6 1
	trainer_party_name "Mark",25,SPEAROW,DODUO,$FF ; Route 6 5
	trainer_party_name "Mike",26,DIGLETT,DIGLETT,SANDSHREW,$FF ;                          UNKNOWN
	trainer_party_name "Nick",32,GROWLITHE,HOUNDOUR,$FF ; Route 9 3u
	trainer_party_name "Robert",32,RATICATE,DUGTRIO,ARBOK,SANDSLASH,$FF ; Route 9 4rl
	trainer_party_name "Ian",53,NIDOKING,$FF ; Route 13 R4
	trainer_party_name "Flint",23,ZIGZAGOON,EKANS,$FF ; Route 24 1
	
PicnickerData: ; COMPLETED
	trainer_party_name "Cindy",25,GOLDEEN,$FF ; Cerulean City GYM
	trainer_party_name "Debra",25,RATTATA,PIKACHU,$FF ; Route 6 2
	trainer_party_name "Heidi",25,RATTATA,SPEAROW,$FF ; Route 6 4
	trainer_party_name "Brooke",33,IVYSAUR,$FF ;                                        	UNKNOWN
	trainer_party_name "Liz",32,GLOOM,WEEPINBELL,$FF ; Route 9 1
	trainer_party_name "Hope",33,PERSIAN,$FF ; Route 9 5
	trainer_party_name "Kim",36,RAICHU,CLEFABLE,$FF ; Rocktunnel Outside
	trainer_party_name "Alice",38,PERSIAN,PIDGEOT,$FF ; Rocktunnel Outside (end)
	trainer_party_name "Becky",37,WIGGLYTUFF,PIDGEOT,$FF ; Rocktunnel 9
	trainer_party_name "Carol",36,GLOOM,IVYSAUR,$FF ; Rocktunnel 3
	trainer_party_name "Diana",42,BULBASAUR,IVYSAUR,VENUSAUR,$FF ; Celadon City Gym r.
	trainer_party_name "Gina",52,PIDGEOT,RAICHU,PERSIAN,$FF ; Route 13 r1
	trainer_party_name "Jenny",52,POLIWRATH,$FF ; route 13 rtl
	trainer_party_name "Clara",52,PIDGEOT,PIDGEOT,$FF ; Route 13 rb
	trainer_party_name "Kelsey",52,SEAKING,SEADRA,$FF ; Route 13 r3
	trainer_party_name "Missy",56,SEAKING,SEAKING,$FF ; After Seafoam
	trainer_party_name "Donna",36,WEEPINBELL,CLEFABLE,$FF ; Rocktunnel 12
	trainer_party_name "Susan",36,VILEPLUME,PERSIAN,$FF ; Rocktunnel 14
	trainer_party_name "Nanci",36,PIDGEOT,RATICATE,$FF ; Rocktunnel 13
	trainer_party_name "Tina",54,VILEPLUME,$FF ; Route 15 4
	trainer_party_name "Julie",54,RAICHU,$FF ; Route 15 7t
	trainer_party_name "Connie",54,CLEFABLE,$FF ; Route 15 btl
	trainer_party_name "Wendy",54,VICTREEBEL,TANGELA,$FF ; Route 15 1
	trainer_party_name "Rei",56,TENTACRUEL,SEADRA,DEWGONG,$FF ; After seafoam
	
PokemaniacData: ; COMPLETED
	trainer_party_name "Terry",40,RHYHORN,LICKITUNG,$FF ;                         UNKNOWN
	trainer_party_name "Ben",37,MAROWAK,SANDSLASH,$FF ; ROCKTUNNEL OUTSIDE LOWER
	trainer_party_name "Scott",36,SLOWBRO,MAROWAK,$FF ; ROCKTUNNEL 11
	trainer_party_name "Jessy",CUSTOM_PIC,COSPLAY_GIRL,36,RAICHU,MAROWAK,$FF ; ROCKTUNNEL 4
	trainer_party_name "Andy",35,SLOWBRO,$FF ; ROCKTUNNEL 2
	trainer_party_name "Jerry",65,CHARIZARD,LAPRAS,LICKITUNG,$FF ; VICTORYROAD 2 5R
	trainer_party_name "Bruce",35,CUBONE,SLOWPOKE,$FF ; ROCKTUNNEL 1
	
SuperNerdData: ; COMPLETED
	trainer_party_name "Teru",17,MAGNEMITE,VOLTORB,$FF ; MT Moon RDL
	trainer_party_name "Eric",20,RAICHU,UMBREON,$FF ; MT MOON ENDBOSS
	trainer_party_name "Markus",36,ELECTRODE,MAGNETON,ELECTABUZZ,$FF ;	Route 8 6
	trainer_party_name "Alan",36,MUK,$FF ; Route 8 3
	trainer_party_name "Derek",36,WEEZING,$FF ; Route8 4t
	trainer_party_name "Clif",35,KOFFING,MAGNEMITE,WEEZING,$FF ;                            UNKNOWN
	trainer_party_name "Owen",36,MAGNEMITE,MAGNEMITE,KOFFING,MAGNEMITE,$FF ;                UNKNOWN
	trainer_party_name "Ben",37,MAGNEMITE,VOLTORB,$FF ;                                    UNKNOWN
	trainer_party_name "Rick",60,NINETALES,$FF ; CINNABAR GYM 2
	trainer_party_name "Marty",61,CHARIZARD,ARCANINE,$FF ; CINNABAR GYM 3
	trainer_party_name "Vince",61,RAPIDASH,$FF ; CINNABAR GYM 5
	trainer_party_name "Avery",62,ARCANINE,RAPIDASH,$FF ; CINNABAR GYM 7
	
HikerData: ; COMPLETED
	trainer_party_name "Jeff",17,GEODUDE,MACHOP,ONIX,$FF ; MT moon
	trainer_party_name "Dillon",22,GEODUDE,MACHOP,$FF ; Route 25 1
	trainer_party_name "Russel",23,GEODUDE,MANKEY,$FF ; Route 25 5
	trainer_party_name "Michael",23,GEODUDE,ONIX,$FF ; Route 25 2d
	trainer_party_name "Trent",33,GRAVELER,ONIX,$FF ; Route 9 3rb
	trainer_party_name "Clark",34,GRAVELER,MACHOKE,$FF ; Route 9 4ru
	trainer_party_name "Lenny",36,MACHOKE,STEELIX,$FF ; route 9 2
	trainer_party_name "Jay",36,STEELIX,GOLEM,$FF ; ROCKTUNNEL OUTSIDE
	trainer_party_name "Bryan",35,STEELIX,$FF ; Rocktunnel 6
	trainer_party_name "Lucas",35,SKARMORY,$FF ; rocktunnel 5l
	trainer_party_name "George",33,AERODACTYL,$FF ; rpcltunnel 5u
	trainer_party_name "Devan",36,MACHAMP,$FF ; Rocktunnel 6
	trainer_party_name "Steve",36,KABUTO,OMANYTE,$FF ; Rocktunnel 7
	trainer_party_name "Kurt",36,GOLEM,$FF ; Rocktunnel 8
	
BikerData: ; COMPLETED
	trainer_party_name "Charles",52,WEEZING,MUK,ARBOK,$FF ; Route 14
	trainer_party_name "Glenn",53,RHYHORN,RHYDON,$FF ; Route 14 2l
	trainer_party_name "Dwayne",54,WEEZING,MUK,$FF ; Route 15 6
	trainer_party_name "Joel",54,MUK,MAGCARGO,$FF ; Route 15 5
	trainer_party_name "Kyle",52,MUK,WEEZING,$FF ; Route 16 1
	trainer_party_name "Billy",53,DITTO,$FF ; Route 16 4b
	trainer_party_name "Alex",52,MUK,MUK,$FF ; Route 16 5
	trainer_party_name "Isaac",53,WEEZING,WEEZING,$FF ; Cyclingroad 1
	trainer_party_name "Jacob",53,MUK,$FF ; Cyclingroad 2
	trainer_party_name "Wesley",53,ELECTRODE,MAGNETON,$FF ; Cyclingroad 3
	trainer_party_name "Logan",54,HOUNDOOM,HONCHKROW,$FF ; Cyclingroad 4
	trainer_party_name "Jared",54,WEEZING,WEEZING,$FF ; Cyclingroad Bottom
	trainer_party_name "Rick",53,MUK,WEEZING,$FF ; Route 14 3l
	trainer_party_name "Jimmy",53,MAGCARGO,WEEZING,$FF ; Route 14 1l
	trainer_party_name "Reggie",53,MURKROW,MUK,$FF ; Route 14 2r
	
BurglarData: ; COMPLETED
	trainer_party_name "Arnie",29,GROWLITHE,VULPIX,$FF ;                                UNKNOWN
	trainer_party_name "Dusty",33,GROWLITHE,$FF ;                                       UNKNOWN
	trainer_party_name "Paul",28,VULPIX,CHARMANDER,PONYTA,$FF ;                        UNKNOWN
	trainer_party_name "Simon",60,ARCANINE,NINETALES,$FF ; CINNABAR GYM 1
	trainer_party_name "Darryl",61,TORKOAL,FLAREON,$FF ; CINNABAR GYM 4
	trainer_party_name "Corey",61,NINETALES,ARCANINE,$FF ; CINNABAR GYM 6
	trainer_party_name "Eddie",57,CHARIZARD,$FF ; PKMNMANSION 2 1
	trainer_party_name "Duncan",58,NINETALES,$FF ; PKMNMANSION 2 E
	trainer_party_name "Isaiah",58,HOUNDOOM,RAPIDASH,$FF ; PKMNMANSION B 1
	
EngineerData: ; COMPLETED
	trainer_party_name "Bernie",21,MAGNEMITE,PIKACHU,$FF ;                              UNKNOWN
	trainer_party_name "Flint",21,MAGNETON,LANTURN,$FF ; route 11 4u
	trainer_party_name "Jack",21,MAGNETON,RAICHU,$FF ; route 11 5

CoupleData: ; COMPLETED
	trainer_party_name "Mike & Nat",25,CUBONE,WEEPINBELL,$FF ; route 6

FisherData: ; COMPLETED
	trainer_party_name "Walt",26,GOLDEEN,TENTACOOL,VAPOREON,$FF ;                     UNKNOWN
	trainer_party_name "Chris",25,TENTACOOL,STARYU,SHELLDER,$FF ; SSANNE 5
	trainer_party_name "Craig",37,POLIWRATH,SEAKING,$FF ; Route 12 4
	trainer_party_name "Bill",38,TENTACRUEL,SEAKING,$FF ; ROUTE 12 3
	trainer_party_name "Hank",37,SEAKING,VAPOREON,$FF ; ROUTE 12 2
	trainer_party_name "Brad",37,POLIWRATH,SEAKING,SEADRA,$FF ; ROUTE 12 1
	trainer_party_name "Jimmy",55,SEAKING,SEAKING,$FF ; ROUTE 21 5T
	trainer_party_name "Ralph",56,CLOYSTER,$FF ; ROUTE 21 3L
	trainer_party_name "Bob",55,GYARADOS,GYARADOS,GYARADOS,$FF ; Route 21 5B
	trainer_party_name "Joe",56,SEAKING,$FF ; ROUTE 21 3R
	trainer_party_name "Wilton",52,GYARADOS,$FF ; ROUTE 13 R5
	
SwimmerData: ; COMPLETED
	trainer_party_name "George",24,HORSEA,SHELLDER,$FF ; CERULIAN GYM 1
	trainer_party_name "Bruno",54,TENTACRUEL,CLOYSTER,$FF ; Route 19 1L
	trainer_party_name "Charlie",54,SEADRA,STARMIE,$FF ; Route 19 1R
	trainer_party_name "Robert",54,POLIWRATH,$FF ; Route 19 2
	trainer_party_name "Chris",54,TENTACRUEL,SEADRA,$FF ; Route 19 3
	trainer_party_name "Riley",55,SEAKING,$FF ; Route 19 4
	trainer_party_name "John",54,SEADRA,$FF ; Route 19 1
	trainer_party_name "Abe",55,TENTACRUEL,$FF ; Route 19 5T
	trainer_party_name "Matthew",55,SHELLDER,CLOYSTER,$FF ; Route 19 1T
	trainer_party_name "Kirk",56,STARMIE,$FF ; Route 19 LEFT SEAFOAM
	trainer_party_name "Parker",55,SEADRA,SEADRA,$FF ; Route 19 L 1B
	trainer_party_name "Ross",56,SEADRA,TENTACRUEL,$FF ; Route 21 4B
	trainer_party_name "Perry",56,STARMIE,$FF ; Route 21 2R
	trainer_party_name "Ryan",55,STARMIE,BLASTOISE,$FF ; Route 21 1L
	trainer_party_name "Ben",55,CHINCHOU,LANTURN,STARMIE,$FF ; Route 21 1R
	trainer_party_name "Josiah",56,TENTACRUEL,TENTACRUEL,$FF ; Route 21 4T
	
CueBallData: ; COMPLETED
	trainer_party_name "Chance",52,MACHAMP,$FF ; Route 16 2
	trainer_party_name "Dave",52,PRIMEAPE,$FF ; Route 16 3
	trainer_party_name "Chad",52,MACHAMP,$FF ; Route 16 4T
	trainer_party_name "Scott",53,PRIMEAPE,$FF ; Route 17 R 2
	trainer_party_name "Nick",53,MACHAMP,$FF ; Route 17 R 1
	trainer_party_name "Reese",53,HITMONLEE,$FF ; Route 17 R 4
	trainer_party_name "Kenny",53,PRIMEAPE,MACHAMP,$FF ; Route 17 L 3
	trainer_party_name "Bruce",53,PRIMEAPE,HITMONCHAN,$FF ; Route 17 R 5
	
GamblerData: ; COMPLETED
	trainer_party_name "Stan",26,POLIWAG,HORSEA,$FF ; route 11 1d
	trainer_party_name "Rich",25,BELLSPROUT,ODDISH,$FF ; route 11 3
	trainer_party_name "Dirk",26,VOLTORB,MAGNEMITE,$FF ; route 11 6d
	trainer_party_name "Jasper",26,GROWLITHE,VULPIX,$FF; route 11 4u
	trainer_party_name "Phil",36,POLIWRATH,$FF ; route 8 5
	trainer_party_name "Biff",34,ONIX,GEODUDE,GRAVELER,$FF ;                        UNKNOWN
	trainer_party_name "Joel",36,ARCANINE,NINETALES,$FF ; route 8
	
SwimmerFData:
BeautyData: ; COMPLETED
	trainer_party_name "Charlotte",41,ODDISH,GLOOM,BELLOSSOM,$FF ; CELADON GYM 2
	trainer_party_name "Beth",42,VICTREEBEL,$FF ; CELADON GYM L
	trainer_party_name "Selena",42,EXEGGCUTE,EXEGGUTOR,$FF ; CELADON GYM LI
	trainer_party_name "Ariana",52,RATICATE,$FF ; Route 13 FRTR
	trainer_party_name "Callie",52,PERSIAN,$FF ; Route 13 FRTL
	trainer_party_name "Malena",55,SEAKING,$FF ; Route 19 Outside Cave
	trainer_party_name "Brea",53,CLOYSTER,SEAKING,$FF ; Route 19
	trainer_party_name "Kaylee",55,POLIWRATH,SEAKING,$FF ; Route 19 After Cave
	trainer_party_name "Lynn",54,PIDGEOT,WIGGLYTUFF,$FF ; Route 15 7B
	trainer_party_name "Holly",54,VENUSAUR,$FF ; Route 15 4T
	trainer_party_name "Carly",53,WEEPINBELL,BELLSPROUT,WEEPINBELL,$FF ;            UNKNOWN
	trainer_party_name "Kiera",54,POLIWRATH,SEAKING,$FF ; Route 19 5L
	trainer_party_name "Mandy",54,SEAKING,$FF ; Route 19 5R
	trainer_party_name "Anna",55,STARMIE,$FF ; Route 19 5B
	trainer_party_name "Caitlyn",55,SEADRA,$FF ; Route 19 L 2
	trainer_party_name "Colby",24,GOLDEEN,$FF ; CERULEAN GYM 2
	trainer_party_name "Callie",55,DEWGONG,$FF ; Route 20, Trainer # 0x11
	trainer_party_name "Marie",55,SEAKING,$FF ; Route 20, Trainer # 0x12
	
PsychicData: ; COMPLETED
	trainer_party_name "Yuri",51,ABRA,KADABRA,ALAKAZAM,$FF ; SAFFRON Gym RT
	trainer_party_name "Teru",51,MR_MIME,ALAKAZAM,$FF ; Saffron GYM RM
	trainer_party_name "Kio",50,SLOWPOKE,SLOWBRO,SLOWKING,$FF ; Saffron GYM 1
	trainer_party_name "Rhen",52,SLOWKING,$FF ; SAFFRON GYM LT
	
RockerData: ; COMPLETED
	trainer_party_name "Debbie",CUSTOM_PIC,ROCKER_F,35,VOLTORB,ELECTRODE,$FF ; LT LURGE GYM
	trainer_party_name "C.C.",52,ARBOK,$FF ; Route 13 R 6
	
JugglerData: ; COMPLETED
	trainer_party_name "Irwin",46,ALAKAZAM,MR_MIME,$FF ; SILPHCO 5 M
	trainer_party_name "Horton",63,HYPNO,ALAKAZAM,$FF ; VICTORYROAD 2 2
	trainer_party_name "Fritz",56,MUK,WEEZING,MUK,$FF ; FUSIA GYM 2R
	trainer_party_name "Liam",56,MUK,TENTACRUEL,WEEZING,$FF ; FUSIA GYM 4M
	trainer_party_name "Cloyd",64,MR_MIME,$FF ; VICTORYROAD 2 4
	trainer_party_name "Derek",53,HYPNO,$FF ;                                  UNKNOWN
	trainer_party_name "Will",55,CROBAT,MUK,$FF ; FUSIA GYM 1R
	trainer_party_name "Shawn",55,CROBAT,WEEZING,MUK,$FF ; FUSIA GYM 1L
	
TamerData: ; COMPLETED
	trainer_party_name "Cole",56,NIDOKING,ARBOK,$FF ; FUSIA GYM 4TL
	trainer_party_name "Edgar",56,ARBOK,NIDOKING,ARBOK,$FF ; FUSIA GYM 3R
	trainer_party_name "Evan",62,RHYDON,$FF ; VIRIDIAN GYM 3C
	trainer_party_name "Jason",61,ARBOK,TAUROS,$FF ; VIRIDIAN GYM BL
	trainer_party_name "Phil",63,PERSIAN,GOLDUCK,$FF ; VICTORYROAD 2 3
	trainer_party_name "Vince",62,RHYHORN,PRIMEAPE,ARBOK,TAUROS,$FF ;  		UNKNOWN
	
BirdKeeperData: ; COMPLETED
	trainer_party_name "Rod",53,PIDGEOT,$FF ; Route 13 R 2
	trainer_party_name "Abe",53,FEAROW,PIDGEOTTO,PIDGEOT,FEAROW,HONCHKROW,$FF  ;             UNKNOWN
	trainer_party_name "Bob",52,PIDGEOT,FEAROW,$FF ; Route 13 LB
	trainer_party_name "Hank",53,FARFETCHD,$FF ; Route 14 1R
	trainer_party_name "Bret",54,FEAROW,$FF ; Route 15 8
	trainer_party_name "Roy",54,PIDGEOT,FARFETCHD,DODRIO,$FF ; Route 15 2
	trainer_party_name "Toby",53,DODRIO,DODRIO,$FF ; Route 15 3
	trainer_party_name "Chad",54,FEAROW,$FF ; Route 18 L
	trainer_party_name "Mike",54,DODRIO,$FF ; Route 18 B
	trainer_party_name "Kyle",53,FEAROW,FEAROW,$FF ; Route 18 M
	trainer_party_name "Willy",55,FEAROW,FEAROW,PIDGEOT,$FF ; Route 19 After seafoam
	trainer_party_name "Jeff",39,PIDGEOTTO,PIDGEOTTO,PIDGEY,PIDGEOTTO,$FF ;             UNKNOWN
	trainer_party_name "Troy",52,FARFETCHD,FEAROW,$FF ;                                UNKNOWN
	trainer_party_name "Kevin",52,DODRIO,PIDGEOT,$FF ;                        UNKNOWN / somewhere on route 13
	trainer_party_name "Jim",52,MURKROW,FEAROW,$FF ; Route 13 LB
	trainer_party_name "Eric",53,PIDGEOT,FEAROW,$FF ; Route 14 4R
	trainer_party_name "Chris",53,MURKROW,FEAROW,$FF ; Route 14 3R
	
BlackbeltData: ; COMPLETED
	trainer_party_name "Kenji",50,HITMONLEE,HITMONCHAN,$FF ; Blackbelt leader
	trainer_party_name "Lao",45,PRIMEAPE,$FF ; 1st Blackbelt
	trainer_party_name "Hung",45,MACHAMP,$FF ;2nd Blackbelt
	trainer_party_name "Chang",45,PRIMEAPE,$FF ;3rd Blackbelt
	trainer_party_name "Toru",45,PRIMEAPE,$FF ; 4th Blackbelt
	trainer_party_name "Yoshi",61,MACHAMP,$FF ; VIDIAN GYM C2
	trainer_party_name "Wang",62,MACHAMP,$FF ; VIRIDIAN GYM LM
	trainer_party_name "Nob",61,MACHAMP,$FF ; VIRIDIAN GYM T
	trainer_party_name "Wai",63,MACHAMP,MACHAMP,$FF ; VICTORYROAD 2 1
	
GentlemanData: ; COMPLETED
	trainer_party_name "Alfred",26,GROWLITHE,PONYTA,CHARMANDER,$FF ; SSANNE 1r
	trainer_party_name "Edward",25,NIDORINA,NIDORINO,$FF ; SSANNE
	trainer_party_name "Preston",35,RAICHU,$FF ; VERMILLION GYM
	trainer_party_name "Gregory",48,PRIMEAPE,$FF ;                                         	UNKNOWN
	trainer_party_name "Howard",25,GROWLITHE,PONYTA,$FF ; SSANNE
	trainer_party_name "Nathan",25,HOUNDOUR,$FF ; SSANNE
	
ChannelerData: ; COMPLETED
	trainer_party_name "Amelia",38,GASTLY,$FF ; PKMNTOWER
	trainer_party_name "Selene",39,GASTLY,$FF
	trainer_party_name "Karina",38,MISDREAVUS,HAUNTER,$FF
	trainer_party_name "Hope",39,HAUNTER,$FF
	trainer_party_name "Stacy",38,HAUNTER,$FF
	trainer_party_name "Gwen",39,GASTLY,$FF
	trainer_party_name "Mary",38,HAUNTER,$FF ; PKMNTOWER
	trainer_party_name "Jane",39,GASTLY,$FF
	trainer_party_name "Carly",39,HAUNTER,$FF
	trainer_party_name "Trixie",40,GENGAR,MISDREAVUS,$FF
	trainer_party_name "Jodie",39,GENGAR,$FF
	trainer_party_name "Faith",38,GENGAR,$FF
	trainer_party_name "Alice",38,GENGAR,$FF
	trainer_party_name "Ashe",39,GENGAR,$FF
	trainer_party_name "Holly",39,GENGAR,$FF ; PKMNTOWER
	trainer_party_name "Cindy",39,GENGAR,$FF
	trainer_party_name "Grace",40,GENGAR,$FF
	trainer_party_name "Rei",40,MISDREAVUS,$FF
	trainer_party_name "Leah",39,GASTLY,HAUNTER,GENGAR,$FF
	trainer_party_name "Eve",40,GENGAR,$FF
	trainer_party_name "Cassie",40,GENGAR,$FF ; PKMNTOWER
	
ScientistData: ; COMPLETED
	trainer_party_name "Sheldon",50,WEEZING,ELECTRODE,$FF ; PKMNMANSION 1                  I AM NOT SURE ABOUT THIS...
	trainer_party_name "Ross",45,WEEZING,$FF ; SILPHCO 2 BL
	trainer_party_name "Mitch",45,MAGNETON,ELECTRODE,$FF ; SILPHCO 2 B
	trainer_party_name "Jed",45,ELECTRODE,WEEZING,$FF ; SILPHCO 3 L
	trainer_party_name "Marc",45,ELECTRODE,JOLTEON,$FF ; SILPHCO 4 M
	trainer_party_name "Taylor",46,MAGNETON,WEEZING,$FF ; SILPHCO 5 L
	trainer_party_name "Nick",46,ELECTRODE,MAGNETON,$FF ; SILPHCO 6 M
	trainer_party_name "Kevin",46,ELECTRODE,MUK,$FF ; SILPHCO 7 BL
	trainer_party_name "Howie",47,HONCHKROW,DRAGONITE,$FF ; SILPHCO 8 T
	trainer_party_name "Brian",47,ELECTRODE,MAGNETON,$FF ; SILPHCO 9 R
	trainer_party_name "Alex",47,MAGNETON,ELECTABUZZ,$FF ; SILPHCO 10 1
	trainer_party_name "Justin",57,MAGNETON,JOLTEON,$FF ; PKMNMANSION 3 R
	trainer_party_name "Chris",58,MAGNETON,ELECTRODE,$FF ; PKMNMANSION B 2
	
RocketFData:
RocketData: ; COMPLETED
	trainer_party_name "Executive"
	db SPECIAL_TRAINER2
	db EXECUTIVE_F
	db AI_POTION
	
	db 18,RATTATA
	moveset BITE, QUICK_ATTACK, FOCUS_ENERGY, HYPER_FANG
	
	db 19,MURKROW
	moveset WING_ATTACK, QUICK_ATTACK, STEEL_WING, SHADOW_BALL
	db $FF

	trainer_party_name "James",CUSTOM_PIC,JAMES,17,KOFFING,BELLSPROUT,$FF ; MT MOON
	trainer_party_name "Jessie",CUSTOM_PIC,JESSIE,17,EKANS,LICKITUNG,$FF ; MT MOON
	trainer_party_name "Grunt",17,RATTATA,ZUBAT,EKANS,$FF ; MT MOON
	trainer_party_name "Grunt",25,MACHOKE,DROWZEE,$FF ; CERULEAN BACK OF HOUSE
	trainer_party_name "Grunt",CUSTOM_PIC,PI_TRAINER,21,RATICATE,GOLBAT,ARBOK,$FF ; NUGGET BRIDGE FINALE
	trainer_party_name "Grunt",40,RATICATE,GOLBAT,$FF ; GC F1
	trainer_party_name "Grunt",40,HYPNO,MACHAMP,$FF ; GC B1
	trainer_party_name "Grunt",40,RATICATE,RATICATE,$FF ; GC B1
	trainer_party_name "Grunt",41,WEEZING,MUK,$FF ; GC B2
	trainer_party_name "Grunt",41,RATICATE,$FF ; GC B2
	trainer_party_name "Grunt",42,WEEZING,MUK,$FF ; GC EV
	trainer_party_name "Grunt",41,GOLBAT,RATICATE,$FF ; GC B2
	trainer_party_name "Grunt",42,RATICATE,HYPNO,$FF ; GC B3
	trainer_party_name "Grunt",42,MACHAMP,$FF ; GC B3
	trainer_party_name "James",CUSTOM_PIC,JAMES,43,WEEZING,VICTREEBEL,$FF ; GC B4 James Battle
	trainer_party_name "Jessie",CUSTOM_PIC,JESSIE,43,ARBOK,LICKITUNG,$FF ; GC B4 Jessie Battle
	trainer_party_name "Grunt",43,WEEZING,MUK,GOLBAT,$FF ; GC B4
	trainer_party_name "Grunt",50,CROBAT,$FF ; PKMNTOWER 1
	trainer_party_name "Grunt",50,WEEZING,HYPNO,$FF ; PKMNTOWER 2
	trainer_party_name "Executive",CUSTOM_PIC,EXECUTIVE_M,50,HOUNDOOM,HONCHKROW,WEEZING,$FF ; PKMNTOWER 3
	trainer_party_name "Grunt",46,HYPNO,WEEZING,$FF ;                                     UNKNOWN
	trainer_party_name "Grunt",45,MAROWAK,GOLBAT,$FF ; SILPH 2 C
	trainer_party_name "Grunt",45,GOLBAT,RATICATE,$FF ; SILPH 2 1
	trainer_party_name "Grunt",45,RATICATE,HYPNO,RATICATE,$FF ; SILPH 3 1
	trainer_party_name "Grunt",45,MACHAMP,HYPNO,$FF ; SILPH 4 L
	trainer_party_name "Grunt",45,ARBOK,SANDSLASH,$FF ; SILPH 4 R
	trainer_party_name "Grunt",46,ARBOK,$FF ; SILPH 5 B
	trainer_party_name "Grunt",46,HYPNO,$FF ; SILPH 5 R
	trainer_party_name "Grunt",46,MACHAMP,$FF ; SILPH 6 T
	trainer_party_name "Grunt",46,GOLBAT,$FF ; SILPH 6 B
	trainer_party_name "Grunt",46,RATICATE,WEEZING,$FF ; SILPH 6 L
	trainer_party_name "Grunt",46,MAROWAK,$FF ; SILPHCO 7 1
	trainer_party_name "Grunt",46,SANDSLASH,$FF ; SILPH 7 BR
	trainer_party_name "Grunt",46,RATICATE,GOLBAT,$FF ; SILPHCO 7 L
	trainer_party_name "Grunt",47,WEEZING,MUK,$FF ; SILPHCO 8 B
	trainer_party_name "Grunt",47,HYPNO,MUK,$FF ; SILPHCO 9 UL
	trainer_party_name "Grunt",47,GOLBAT,HYPNO,$FF ; SILPHCO 9 B
	trainer_party_name "Grunt",47,MACHAMP,$FF ; SILPHCO 10 2
	trainer_party_name "Grunt",47,RATICATE,ARBOK,GOLBAT,$FF ; SILPHCO 11 1
	trainer_party_name "Executive",CUSTOM_PIC,EXECUTIVE_M,50,HYPNO,MAROWAK,$FF ; SILPHCO 13 1
	
AceTrainerMData: ; COMPLETED
	trainer_party_name "Aaron",61,NIDOKING,$FF ; VIRIDIAN GYM C2T
	trainer_party_name "Blake",63,EXEGGUTOR,CLOYSTER,ARCANINE,$FF ; VICTORYROAD 3 BY ITEM
	trainer_party_name "Brian",63,KINGLER,TENTACRUEL,BLASTOISE,$FF ; VICTORYROAD 3 BL
	trainer_party_name "Cody",45,KINGLER,STARMIE,$FF ;                                     UNKNOWN
	trainer_party_name "Gaven",64,VENUSAUR,BLASTOISE,CHARIZARD,$FF ; VICTORYROAD 1 TC
	trainer_party_name "Jake",44,IVYSAUR,WARTORTLE,CHARMELEON,$FF ;                        UNKNOWN
	trainer_party_name "Danny",49,NIDOKING,$FF ;                                            UNKNOWN
	trainer_party_name "Mike",44,KINGLER,CLOYSTER,$FF ;                                    UNKNOWN
	trainer_party_name "Nick",60,SANDSLASH,DUGTRIO,$FF ; VIRIDIAN GYM C1
	trainer_party_name "Zoro",61,RHYDON,$FF ; VIRIDIAN GYM C1T
	
AceTrainerFData: ; COMPLETED
	trainer_party_name "Beth",41,VICTREEBEL,VILEPLUME,VENUSAUR,$FF ; CELADON GYM
	trainer_party_name "Lola",63,VENOMOTH,VILEPLUME,VICTREEBEL,$FF ; VICTORYROAD 3 BU
	trainer_party_name "Megan",63,PARASECT,DEWGONG,CHANSEY,$FF ; VICTORYROAD 3 C
	trainer_party_name "Quinn",46,VILEPLUME,BUTTERFREE,$FF ;                                UNKNOWN
	trainer_party_name "Irene",64,PERSIAN,NINETALES,$FF ; VICTORYROAD 1 M
	trainer_party_name "Sara",45,IVYSAUR,VENUSAUR,$FF ;                                    UNKNOWN
	trainer_party_name "Lisa",45,NIDORINA,NIDOQUEEN,$FF ;                                  UNKNOWN
	trainer_party_name "Anna",43,PERSIAN,NINETALES,RAICHU,$FF ;                            UNKNOWN
	
HexManiacData:
	trainer_party_name "Alice",51,GENGAR,MISDREAVUS,$FF ; SAFFRON GYM
	trainer_party_name "Luna",52,GENGAR,MISDREAVUS,$FF ; SAFFRON GYM
	trainer_party_name "Carrie",53,GENGAR,MISDREAVUS,$FF ; SAFFRON GYM

PkmnTrainerData:
    trainer_party_name "Flannery"
	db SPECIAL_TRAINER2
	db FLANNERY ; pic
	db AI_FULL_RESTORE ; AI
	
	db 54,SLUGMA
	moveset FLAME_WHEEL, SMOG, LIGHT_SCREEN, HAZE
	
	db 55,SLUGMA
	moveset FLAMETHROWER, ROCK_SLIDE, LIGHT_SCREEN, HARDEN
	
	db 57,TORKOAL
	moveset FLAMETHROWER, BODY_SLAM, WITHDRAW, HEX
	db $FF
	
	
	
	trainer_party_name "Janine"
	db SPECIAL_TRAINER2
	db JANINE ; pic
	db AI_X_ATTACK
	
	db 64,CROBAT
	moveset WING_ATTACK, CONFUSE_RAY, SUPERSONIC, SCREECH
	
	db 64,WEEZING
	moveset SLUDGE_WAVE, SMOG, TOXIC, EXPLOSION
	
	db 65,VENOMOTH
	moveset TOXIC, PSYCHIC_M, DOUBLE_TEAM, SUPERSONIC
	db $FF
