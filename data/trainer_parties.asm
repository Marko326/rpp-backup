; TRN-5.33.02: trainer_party_name scopes packed_names to the name field.
; Runtime decoding preserves the original wCurTrainerName representation.

TrainerDataPointers:
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
	
	db 12,GEODUDE
	moveset TACKLE, DEFENSE_CURL, 0, 0
	
	db 14,ONIX
	moveset TACKLE, BIND, HARDEN, ROCK_TOMB
	db $FF
	
MistyData:
	trainer_party_name "Misty"
	db SPECIAL_TRAINER
	
	db 18,STARYU
	moveset TACKLE, HARDEN, RECOVER, WATER_PULSE
	
	db 21,STARMIE
	moveset TACKLE, SWIFT, RECOVER, WATER_PULSE
	db $FF
	
LtSurgeData:
	trainer_party_name "Lt.Surge"
	db SPECIAL_TRAINER
	
	db 21,VOLTORB
	moveset THUNDERBOLT, TACKLE, SCREECH, SONICBOOM
	
	db 18,PIKACHU
	moveset THUNDERBOLT, THUNDER_WAVE, QUICK_ATTACK, DOUBLE_TEAM
	
	db 24,RAICHU
	moveset THUNDERBOLT, THUNDER_WAVE, QUICK_ATTACK, DOUBLE_TEAM
	db $FF
	
ErikaData:
	trainer_party_name "Erika"
	db SPECIAL_TRAINER
	
	db 29,VICTREEBEL
	moveset STUN_SPORE, ACID, POISONPOWDER, GIGA_DRAIN
	
	db 24,TANGELA
	moveset POISONPOWDER, CONSTRICT, VINE_WHIP, GIGA_DRAIN
	
	db 29,BELLOSSOM
	moveset SLEEP_POWDER, SOLARBEAM, GIGA_DRAIN, PETAL_DANCE
	db $FF
	
KogaData:
	trainer_party_name "Koga"
	db SPECIAL_TRAINER
	
	db 37,VENOMOTH
	moveset CONFUSION, GUST, SUPERSONIC, TOXIC
	
	db 39,MUK
	moveset MINIMIZE, SLUDGE, ACID_ARMOR, TOXIC
	
	db 37,CROBAT
	moveset DOUBLE_TEAM, QUICK_ATTACK, WING_ATTACK, POISON_FANG
	
	db 43,WEEZING
	moveset TACKLE, SLUDGE, SMOKESCREEN, TOXIC
	db $FF
	
SabrinaData:
	trainer_party_name "Sabrina"
	db SPECIAL_TRAINER
	
	db 38,KADABRA
	moveset DISABLE, PSYBEAM, RECOVER, PSYCHIC_M
	
	db 37,MR_MIME
	moveset CONFUSION, BARRIER, LIGHT_SCREEN, DOUBLESLAP
	
	db 38,ESPEON
	moveset SAND_ATTACK, QUICK_ATTACK, SWIFT, PSYCHIC_M
	
	db 43,ALAKAZAM
	moveset SHADOW_BALL, RECOVER, PSYWAVE, REFLECT
	db $FF
	
BlaineData:
	trainer_party_name "Blaine"
	db SPECIAL_TRAINER
	
	db 42,GROWLITHE
	moveset BITE, ROAR, TAKE_DOWN, FIRE_BLAST
	
	db 40,PONYTA
	moveset STOMP, AGILITY, FIRE_SPIN, FIRE_BLAST
	
	db 42,RAPIDASH
	moveset STOMP, AGILITY, FIRE_SPIN, FIRE_BLAST
	
	db 45,ARCANINE
	moveset BITE, ROAR, EXTREMESPEED, FIRE_BLAST
	
	db 47,MAGMAR
	moveset FIRE_PUNCH, CONFUSE_RAY, FIRE_BLAST, SMOG
	db $FF
	
; Giovanni Gym Battle
	trainer_party_name "Giovanni"
	db SPECIAL_TRAINER2
	db GIOVANNI_2 ; pic
	db AI_HYPER_POTION ; AI
	
	db 45,RHYDON
	moveset TAKE_DOWN, ROCK_BLAST, LEER, EARTHQUAKE
	
	db 42,STEELIX
	moveset IRON_TAIL, ROCK_BLAST, RAGE, IRON_DEFENSE
	
	db 44,NIDOQUEEN
	moveset DOUBLE_KICK, EARTHQUAKE, POISON_STING, BODY_SLAM
	
	db 45,NIDOKING
	moveset DOUBLE_KICK, EARTHQUAKE, POISON_STING, THRASH
	
	db 50,RHYPERIOR
	moveset TAKE_DOWN, ANCIENTPOWER, ROCK_BLAST, EARTHQUAKE
	db $FF
	
GiovanniData:
	; Hideout
	trainer_party_name "Giovanni"
	db SPECIAL_TRAINER
	
	db 25,ONIX
	moveset ROCK_THROW, BIND, RAGE, HARDEN
	
	db 24,RHYHORN
	moveset STOMP, FURY_ATTACK, LEER, TAIL_WHIP
	
	db 29,KANGASKHAN
	moveset SUCKER_PUNCH, MEGA_PUNCH, BITE, TAIL_WHIP
	db $FF
	
	
	; Silph Co
	trainer_party_name "Giovanni"
	db SPECIAL_TRAINER
	
	db 35,ONIX
	moveset IRON_TAIL, BIND, RAGE, ROCK_THROW
	
	db 37,RHYHORN
	moveset FURY_ATTACK, LEER, STOMP, ROCK_BLAST
	
	db 37,NIDORINO
	moveset HORN_ATTACK, POISON_STING, DOUBLE_KICK, FURY_ATTACK
	
	db 41,NIDOQUEEN
	moveset DOUBLE_KICK, TAIL_WHIP, POISON_STING, BODY_SLAM
	db $FF
	
LoreleiData:
	trainer_party_name "Lorelei"
	db SPECIAL_TRAINER
	
	db 54,DEWGONG
	moveset SURF, ICE_BEAM, AURORA_BEAM, REST
	
	db 53,CLOYSTER
	moveset CLAMP, SPIKE_CANNON, ICE_BEAM, BLIZZARD
	
	db 54,SLOWKING
	moveset ICE_BEAM, AMNESIA, SURF, PSYCHIC_M
	
	db 56,JYNX
	moveset DOUBLESLAP, ICE_PUNCH, DRAININGKISS, LOVELY_KISS
	
	db 56,LAPRAS
	moveset BODY_SLAM, CONFUSE_RAY, SURF, ICE_BEAM
	db $FF
	
BrunoData:
	trainer_party_name "Bruno"
	db SPECIAL_TRAINER
	
	db 53,ONIX
	moveset EARTHQUAKE, ROCK_TOMB, IRON_TAIL, ROAR
	
	db 55,HITMONCHAN
	moveset SHADOW_PUNCH, ICE_PUNCH, THUNDERPUNCH, FIRE_PUNCH
	
	db 55,HITMONLEE
	moveset MEGA_KICK, HI_JUMP_KICK, DOUBLE_KICK, DOUBLE_TEAM
	
	db 56,STEELIX
	moveset DOUBLE_EDGE, IRON_TAIL, IRON_DEFENSE, ROCK_TOMB
	
	db 58,MACHAMP
	moveset CROSS_CHOP, ROCK_TOMB, STRENGTH, SUBMISSION
	db $FF	
	
AgathaData:
	trainer_party_name "Agatha"
	db SPECIAL_TRAINER
	
	db 56,MISDREAVUS
	moveset POWER_GEM, SHADOW_BALL, HEX, PSYBEAM
	
	db 56,HONCHKROW
	moveset NIGHT_SLASH, HEX, HEALINGLIGHT, ACROBATICS
	
	db 55,HOUNDOOM
	moveset FLAMETHROWER, SHADOW_BALL, HEX, BITE
	
	db 58,MISMAGIUS
	moveset DARK_PULSE, NIGHT_SHADE, HEX, GLARE
	
	db 60,GENGAR
	moveset HYPNOSIS, DREAM_EATER, HEX, HEALINGLIGHT
	db $FF
	
LanceData:
	trainer_party_name "Lance"
	db SPECIAL_TRAINER
	
	db 58,GYARADOS
	moveset DRAGONBREATH, TWISTER, HYPER_BEAM, ICE_FANG
	
	db 56,CHARIZARD
	moveset FLAMETHROWER, DRAGONBREATH, EARTHQUAKE, METAL_CLAW
	
	db 56,KINGDRA
	moveset WHIRLPOOL, DRAGONBREATH, DRAGON_PULSE, FOCUS_ENERGY
	
	db 60,AERODACTYL
	moveset AERIAL_ACE, DRAGONBREATH, ANCIENTPOWER, STEEL_WING
	
	db 62,DRAGONITE
	moveset AMNESIA, DRAGONBREATH, DRACO_METEOR, THUNDER_WAVE
	db $FF	
	
Green1Data:
	; Oak's Lab
	trainer_party_name "[RIVAL]",5,SQUIRTLE,$FF
	trainer_party_name "[RIVAL]",5,BULBASAUR,$FF
	trainer_party_name "[RIVAL]",5,CHARMANDER,$FF
	
	
	; Beside Viridian
	trainer_party_name "[RIVAL]",SPECIAL_LEVELS,9,PIDGEY,8,SQUIRTLE,$FF
	trainer_party_name "[RIVAL]",SPECIAL_LEVELS,9,PIDGEY,8,BULBASAUR,$FF
	trainer_party_name "[RIVAL]",SPECIAL_LEVELS,9,PIDGEY,8,CHARMANDER,$FF
	
	
	; Cerulean
	trainer_party_name "[RIVAL]"
	db SPECIAL_TRAINER
	
	db 18,PIDGEOTTO
	moveset TACKLE, GUST, SAND_ATTACK, QUICK_ATTACK
	
	db 15,ABRA
	moveset TELEPORT, 0, 0, 0
	
	db 15,RATTATA
	moveset TACKLE, TAIL_WHIP, QUICK_ATTACK, 0
	
	db 17,SQUIRTLE
	moveset TACKLE, TAIL_WHIP, BUBBLE, WATER_GUN
	db $FF
	
	
	
	trainer_party_name "[RIVAL]"
	db SPECIAL_TRAINER
	
	db 18,PIDGEOTTO
	moveset TACKLE, GUST, SAND_ATTACK, QUICK_ATTACK
	
	db 15,ABRA
	moveset TELEPORT, 0, 0, 0
	
	db 15,RATTATA
	moveset TACKLE, TAIL_WHIP, QUICK_ATTACK, 0
	
	db 17,BULBASAUR
	moveset SLEEP_POWDER, POISONPOWDER, LEECH_SEED, VINE_WHIP
	db $FF
	
	
	
	trainer_party_name "[RIVAL]"
	db SPECIAL_TRAINER
	
	db 18,PIDGEOTTO
	moveset TACKLE, GUST, SAND_ATTACK, QUICK_ATTACK
	
	db 15,ABRA
	moveset TELEPORT, 0, 0, 0
	
	db 15,RATTATA
	moveset TACKLE, TAIL_WHIP, QUICK_ATTACK, 0
	
	db 17,CHARMANDER
	moveset SCRATCH, GROWL, EMBER, METAL_CLAW
	db $FF
	
	
	
Green2Data:
	; SS Anne
	trainer_party_name "[RIVAL]"
	db SPECIAL_TRAINER
	
	db 19,PIDGEOTTO
	moveset TACKLE, GUST, SAND_ATTACK, QUICK_ATTACK
	
	db 16,RATICATE
	moveset TACKLE, TAIL_WHIP, QUICK_ATTACK, HYPER_FANG
	
	db 18,KADABRA
	moveset TELEPORT, CONFUSION, DISABLE, KINESIS
	
	db 20,WARTORTLE
	moveset WITHDRAW, BITE, BUBBLE, WATER_GUN
	db $FF
	
	
	
	trainer_party_name "[RIVAL]"
	db SPECIAL_TRAINER
	
	db 19,PIDGEOTTO
	moveset TACKLE, GUST, SAND_ATTACK, QUICK_ATTACK
	
	db 16,RATICATE
	moveset TACKLE, TAIL_WHIP, QUICK_ATTACK, HYPER_FANG
	
	db 18,KADABRA
	moveset TELEPORT, CONFUSION, DISABLE, KINESIS
	
	db 20,IVYSAUR
	moveset TACKLE, GROWL, LEECH_SEED, VINE_WHIP
	db $FF
	
	
	
	trainer_party_name "[RIVAL]"
	db SPECIAL_TRAINER
	
	db 19,PIDGEOTTO
	moveset TACKLE, GUST, SAND_ATTACK, QUICK_ATTACK
	
	db 16,RATICATE
	moveset TACKLE, TAIL_WHIP, QUICK_ATTACK, HYPER_FANG
	
	db 18,KADABRA
	moveset TELEPORT, CONFUSION, DISABLE, KINESIS
	
	db 20,CHARMELEON
	moveset SMOKESCREEN, GROWL, EMBER, METAL_CLAW
	db $FF
	
	
	
	; Pokemon Tower
	
	trainer_party_name "[RIVAL]"
	db SPECIAL_TRAINER
	
	db 25,PIDGEOTTO
	moveset GUST, SAND_ATTACK, QUICK_ATTACK, WHIRLWIND
	
	db 23,GROWLITHE
	moveset BITE, ROAR, EMBER, LEER
	
	db 22,EXEGGCUTE
	moveset BARRAGE, HYPNOSIS, LEECH_SEED, 0
	
	db 20,KADABRA
	moveset TELEPORT, CONFUSION, DISABLE, KINESIS
	
	db 25,WARTORTLE
	moveset TAIL_WHIP, BUBBLE, WATER_GUN, BITE
	db $FF
	
	
	
	trainer_party_name "[RIVAL]"
	db SPECIAL_TRAINER
	
	db 25,PIDGEOTTO
	moveset GUST, SAND_ATTACK, QUICK_ATTACK, WHIRLWIND
	
	db 23,GYARADOS
	moveset THRASH, TACKLE, BITE, 0
	
	db 22,GROWLITHE
	moveset BITE, ROAR, EMBER, LEER
	
	db 20,KADABRA
	moveset TELEPORT, CONFUSION, DISABLE, KINESIS
	
	db 25,IVYSAUR
	moveset GROWL, LEECH_SEED, VINE_WHIP, POISONPOWDER
	db $FF
	
	
	
	trainer_party_name "[RIVAL]"
	db SPECIAL_TRAINER
	
	db 25,PIDGEOTTO
	moveset GUST, SAND_ATTACK, QUICK_ATTACK, WHIRLWIND
	
	db 23,EXEGGCUTE
	moveset BARRAGE, HYPNOSIS, LEECH_SEED, 0
	
	db 22,GYARADOS
	moveset THRASH, TACKLE, BITE, 0
	
	db 20,KADABRA
	moveset TELEPORT, CONFUSION, DISABLE, KINESIS
	
	db 25,CHARMELEON
	moveset SMOKESCREEN, EMBER, LEER, RAGE
	db $FF
	
	
	
	; Silph Co
	
	trainer_party_name "[RIVAL]"
	db SPECIAL_TRAINER
	
	db 37,PIDGEOT
	moveset WING_ATTACK, ACROBATICS, QUICK_ATTACK, WHIRLWIND
	
	db 38,GROWLITHE
	moveset ROAR, EMBER, LEER, TAKE_DOWN
	
	db 35,EXEGGCUTE
	moveset REFLECT, HYPNOSIS, LEECH_SEED, STUN_SPORE
	
	db 35,ALAKAZAM
	moveset SHADOW_BALL, AMNESIA, REFLECT, RECOVER
	
	db 40,BLASTOISE
	moveset BUBBLE, WATER_GUN, BITE, WITHDRAW
	db $FF
	
	
	
	trainer_party_name "[RIVAL]"
	db SPECIAL_TRAINER
	
	db 37,PIDGEOT
	moveset WING_ATTACK, ACROBATICS, QUICK_ATTACK, WHIRLWIND
	
	db 38,GYARADOS
	moveset DRAGON_RAGE, TACKLE, BITE, LEER
	
	db 38,GROWLITHE
	moveset ROAR, EMBER, LEER, TAKE_DOWN
	
	db 35,ALAKAZAM
	moveset SHADOW_BALL, AMNESIA, REFLECT, RECOVER
	
	db 40,VENUSAUR
	moveset LEECH_SEED, VINE_WHIP, POISONPOWDER, RAZOR_LEAF
	db $FF
	
	
	
	trainer_party_name "[RIVAL]"
	db SPECIAL_TRAINER
	
	db 37,PIDGEOT
	moveset WING_ATTACK, ACROBATICS, QUICK_ATTACK, WHIRLWIND
	
	db 35,EXEGGCUTE
	moveset REFLECT, HYPNOSIS, LEECH_SEED, STUN_SPORE
	
	db 38,GYARADOS
	moveset DRAGON_RAGE, TACKLE, BITE, LEER
	
	db 35,ALAKAZAM
	moveset SHADOW_BALL, AMNESIA, REFLECT, RECOVER
	
	db 40,CHARIZARD
	moveset LEER, FLAMETHROWER, SMOKESCREEN, WING_ATTACK
	db $FF
	
	
	
	; Before Pokemon Leage
	
	trainer_party_name "[RIVAL]"
	db SPECIAL_TRAINER
	
	db 47,PIDGEOT
	moveset WING_ATTACK, ACROBATICS, QUICK_ATTACK, GUST
	
	db 45,RHYHORN
	moveset ROCK_BLAST, TAKE_DOWN, FURY_ATTACK, HORN_DRILL
	
	db 45,GROWLITHE
	moveset FLAME_WHEEL, TAKE_DOWN, LEER, AGILITY
	
	db 47,EXEGGCUTE
	moveset SOLARBEAM, POISONPOWDER, SLEEP_POWDER, STUN_SPORE
	
	db 50,ALAKAZAM
	moveset PSYCHIC_M, AMNESIA, SHADOW_BALL, DISABLE
	
	db 53,BLASTOISE
	moveset HYDRO_PUMP, WITHDRAW, SKULL_BASH, BITE
	db $FF
	
	
	
	trainer_party_name "[RIVAL]"
	db SPECIAL_TRAINER
	
	db 47,PIDGEOT
	moveset WING_ATTACK, ACROBATICS, QUICK_ATTACK, GUST
	
	db 45,RHYHORN
	moveset ROCK_BLAST, TAKE_DOWN, FURY_ATTACK, HORN_DRILL
	
	db 45,GYARADOS
	moveset THRASH, TWISTER, HYDRO_PUMP, LEER
	
	db 47,GROWLITHE
	moveset FLAME_WHEEL, TAKE_DOWN, LEER, AGILITY
	
	db 50,ALAKAZAM
	moveset PSYCHIC_M, AMNESIA, SHADOW_BALL, DISABLE
	
	db 53,VENUSAUR
	moveset POISONPOWDER, RECOVER, RAZOR_LEAF, GROWTH
	db $FF
	
	
	
	trainer_party_name "[RIVAL]"
	db SPECIAL_TRAINER
	
	db 47,PIDGEOT
	moveset WING_ATTACK, ACROBATICS, QUICK_ATTACK, GUST
	
	db 45,RHYHORN
	moveset ROCK_BLAST, TAKE_DOWN, FURY_ATTACK, HORN_DRILL
	
	db 45,EXEGGCUTE
	moveset SOLARBEAM, POISONPOWDER, SLEEP_POWDER, STUN_SPORE
	
	db 47,GYARADOS
	moveset THRASH, TWISTER, HYDRO_PUMP, LEER
	
	db 50,ALAKAZAM
	moveset PSYCHIC_M, AMNESIA, SHADOW_BALL, DISABLE
	
	db 53,CHARIZARD
	moveset FLAMETHROWER, WING_ATTACK, SLASH, LEER
	db $FF
	
	
	
Green3Data:
	; Champion
	trainer_party_name "[RIVAL]"
	db SPECIAL_TRAINER
	
	db 61,PIDGEOT
	moveset AERIAL_ACE, ACROBATICS, SAND_ATTACK, WHIRLWIND
	
	db 59,ALAKAZAM
	moveset PSYCHIC_M, SHADOW_BALL, RECOVER, REFLECT
	
	db 61,RHYDON
	moveset TAKE_DOWN, EARTHQUAKE, ROCK_TOMB, LEER
	
	db 61,ARCANINE
	moveset EXTREMESPEED, FLAMETHROWER, ROAR, BITE
	
	db 63,EXEGGUTOR
	moveset GIGA_DRAIN, EGG_BOMB, SLEEP_POWDER, LIGHT_SCREEN
	
	db 65,BLASTOISE
	moveset HYDRO_PUMP, WITHDRAW, SKULL_BASH, BITE
	db $FF
	
	
	
	trainer_party_name "[RIVAL]"
	db SPECIAL_TRAINER
	
	db 61,PIDGEOT
	moveset AERIAL_ACE, ACROBATICS, SAND_ATTACK, WHIRLWIND
	
	db 59,ALAKAZAM
	moveset PSYCHIC_M, SHADOW_BALL, RECOVER, REFLECT
	
	db 61,RHYDON
	moveset TAKE_DOWN, EARTHQUAKE, ROCK_TOMB, LEER
	
	db 61,GYARADOS
	moveset HYDRO_PUMP, DRAGON_RAGE, BITE, THRASH
	
	db 63,ARCANINE
	moveset EXTREMESPEED, FLAMETHROWER, ROAR, BITE
	
	db 65,VENUSAUR
	moveset SOLARBEAM, RECOVER, GIGA_DRAIN, GROWTH
	db $FF
	
	
	
	trainer_party_name "[RIVAL]"
	db SPECIAL_TRAINER
	
	db 61,PIDGEOT
	moveset AERIAL_ACE, ACROBATICS, SAND_ATTACK, WHIRLWIND
	
	db 59,ALAKAZAM
	moveset PSYCHIC_M, SHADOW_BALL, RECOVER, REFLECT
	
	db 61,RHYDON
	moveset TAKE_DOWN, EARTHQUAKE, ROCK_TOMB, LEER
	
	db 63,EXEGGUTOR
	moveset GIGA_DRAIN, EGG_BOMB, SLEEP_POWDER, LIGHT_SCREEN
	
	db 61,GYARADOS
	moveset HYDRO_PUMP, DRAGON_RAGE, BITE, THRASH
	
	db 65,CHARIZARD
	moveset FIRE_BLAST, AERIAL_ACE, SLASH, FLARE_BLITZ
	db $FF
	
YoungsterData:
	trainer_party_name "Ben",11,ZIGZAGOON,RATTATA,$FF
	trainer_party_name "Arnold",14,SPEAROW,$FF
	trainer_party_name "Anthony",10,RATTATA,RATTATA,ZUBAT,$FF
	trainer_party_name "Samuel",14,RATTATA,EKANS,ZUBAT,$FF
	trainer_party_name "Adam",15,RATTATA,SPEAROW,$FF
	trainer_party_name "Ben",17,SLOWPOKE,$FF
	trainer_party_name "Calvin",14,EKANS,SANDSHREW,$FF
	trainer_party_name "Chad",21,NIDORAN_M,$FF
	trainer_party_name "Dan",21,EKANS,$FF
	trainer_party_name "Dave",19,SANDSHREW,ZUBAT,$FF
	trainer_party_name "Josh",17,ZIGZAGOON,ZIGZAGOON,LINOONE,$FF
	trainer_party_name "Timmy",18,NIDORAN_M,NIDORINO,$FF
	trainer_party_name "Nash",17,SPEAROW,RATTATA,RATTATA,SPEAROW,$FF
	
BugCatcherData:
	trainer_party_name "Luke",6,WEEDLE,CATERPIE,$FF
	trainer_party_name "Finn",7,WEEDLE,KAKUNA,WEEDLE,$FF
	trainer_party_name "Jake",9,WEEDLE,$FF
	trainer_party_name "David",10,CATERPIE,WEEDLE,CATERPIE,$FF
	trainer_party_name "Lou",9,WEEDLE,KAKUNA,CATERPIE,METAPOD,$FF
	trainer_party_name "Larry",11,CATERPIE,METAPOD,$FF
	trainer_party_name "Chuck",11,WEEDLE,KAKUNA,$FF
	trainer_party_name "Zach",10,CATERPIE,METAPOD,CATERPIE,$FF
	trainer_party_name "Chris",14,CATERPIE,WEEDLE,$FF
	trainer_party_name "Rick",16,WEEDLE,CATERPIE,WEEDLE,$FF
	trainer_party_name "Bob",20,BUTTERFREE,$FF
	trainer_party_name "Gray",18,METAPOD,CATERPIE,VENONAT,$FF
	trainer_party_name "Matt",19,BEEDRILL,BEEDRILL,$FF
	trainer_party_name "Ed",20,CATERPIE,WEEDLE,VENONAT,$FF
	
LassData:
	trainer_party_name "Nicole",9,PIDGEY,PIDGEY,$FF
	trainer_party_name "Jennifer",10,ZIGZAGOON,NIDORAN_M,$FF
	trainer_party_name "Hillary",14,JIGGLYPUFF,$FF
	trainer_party_name "Rachel",31,PARAS,PARAS,PARASECT,$FF
	trainer_party_name "Christy",11,ODDISH,BELLSPROUT,$FF
	trainer_party_name "Jessica",14,CLEFAIRY,$FF
	trainer_party_name "Trish",16,PIDGEY,NIDORAN_F,$FF
	trainer_party_name "Monica",14,PIDGEY,NIDORAN_F,$FF
	trainer_party_name "Lulu",15,NIDORAN_M,NIDORAN_F,$FF
	trainer_party_name "Brooke",13,ODDISH,PIDGEY,ODDISH,$FF
	trainer_party_name "Rose",18,TOGETIC,ESPEON,$FF
	trainer_party_name "Martha",18,RATTATA,PIKACHU,$FF
	trainer_party_name "Amanda",23,NIDORAN_F,NIDORINA,$FF
	trainer_party_name "Meadow",24,MEOWTH,MEOWTH,MEOWTH,$FF
	trainer_party_name "Whitney",19,PIDGEY,RATTATA,NIDORAN_M,MEOWTH,PIKACHU,$FF
	trainer_party_name "Samantha",22,CLEFAIRY,CLEFAIRY,$FF
	trainer_party_name "Katie",23,BELLSPROUT,WEEPINBELL,$FF
	trainer_party_name "Bella",23,ODDISH,GLOOM,$FF
	
SailorData:
	trainer_party_name "Jack",18,MACHOP,SHELLDER,$FF
	trainer_party_name "Will",17,MACHOP,TENTACOOL,$FF
	trainer_party_name "Lewis",21,SHELLDER,$FF
	trainer_party_name "Huey",17,HORSEA,SHELLDER,TENTACOOL,$FF
	trainer_party_name "Dave",18,TENTACOOL,STARYU,$FF
	trainer_party_name "Eugene",17,HORSEA,HORSEA,HORSEA,$FF
	trainer_party_name "Flynn",20,MACHOP,$FF
	trainer_party_name "Hans",21,PIKACHU,PIKACHU,$FF
	
CamperData:
	trainer_party_name "Daniel",9,DIGLETT,SANDSHREW,$FF
	trainer_party_name "Craig",14,POLIWAG,GOLDEEN,$FF
	trainer_party_name "Harry",18,MANKEY,$FF
	trainer_party_name "Ronald",20,SQUIRTLE,$FF
	trainer_party_name "Mark",16,SPEAROW,RATICATE,$FF
	trainer_party_name "Mike",18,DIGLETT,DIGLETT,SANDSHREW,$FF
	trainer_party_name "Nick",21,GROWLITHE,HOUNDOUR,$FF
	trainer_party_name "Robert",19,RATTATA,DIGLETT,EKANS,SANDSHREW,$FF
	trainer_party_name "Ian",29,NIDORAN_M,NIDORINO,$FF
	trainer_party_name "Flint",14,ZIGZAGOON,EKANS,$FF
	
PicnickerData:
	trainer_party_name "Cindy",19,GOLDEEN,$FF
	trainer_party_name "Debra",16,RATTATA,PIKACHU,$FF
	trainer_party_name "Heidi",16,PIDGEY,PIDGEY,PIDGEY,$FF
	trainer_party_name "Brooke",22,BULBASAUR,$FF
	trainer_party_name "Liz",18,ODDISH,BELLSPROUT,ODDISH,BELLSPROUT,$FF
	trainer_party_name "Hope",23,MEOWTH,$FF
	trainer_party_name "Kim",20,PIKACHU,CLEFAIRY,$FF
	trainer_party_name "Alice",21,PIDGEY,PIDGEOTTO,$FF
	trainer_party_name "Becky",21,JIGGLYPUFF,PIDGEY,MEOWTH,$FF
	trainer_party_name "Carol",22,ODDISH,BULBASAUR,$FF
	trainer_party_name "Diana",24,BULBASAUR,IVYSAUR,$FF
	trainer_party_name "Gina",24,PIDGEY,MEOWTH,RATTATA,PIKACHU,MEOWTH,$FF
	trainer_party_name "Jenny",30,POLIWAG,POLIWAG,$FF
	trainer_party_name "Clara",27,PIDGEY,MEOWTH,PIDGEY,PIDGEOTTO,$FF
	trainer_party_name "Kelsey",28,GOLDEEN,POLIWAG,HORSEA,$FF
	trainer_party_name "Missy",31,GOLDEEN,SEAKING,$FF
	trainer_party_name "Donna",22,BELLSPROUT,CLEFAIRY,$FF
	trainer_party_name "Susan",20,MEOWTH,ODDISH,PIDGEY,$FF
	trainer_party_name "Nanci",19,PIDGEY,RATTATA,RATTATA,BELLSPROUT,$FF
	trainer_party_name "Tina",28,GLOOM,ODDISH,ODDISH,$FF
	trainer_party_name "Julie",29,PIKACHU,RAICHU,$FF
	trainer_party_name "Connie",33,CLEFAIRY,$FF
	trainer_party_name "Wendy",29,BELLSPROUT,ODDISH,TANGELA,$FF
	trainer_party_name "Rei",30,TENTACOOL,HORSEA,SEEL,$FF
	
PokemaniacData:
	trainer_party_name "Terry",30,RHYHORN,LICKITUNG,$FF
	trainer_party_name "Ben",20,CUBONE,SLOWPOKE,$FF
	trainer_party_name "Scott",20,SLOWPOKE,SLOWPOKE,SLOWPOKE,$FF
	trainer_party_name "Jessy",CUSTOM_PIC,COSPLAY_GIRL,22,PIKACHU,CUBONE,$FF
	trainer_party_name "Andy",25,SLOWPOKE,$FF
	trainer_party_name "Jerry",40,CHARMELEON,LAPRAS,LICKITUNG,$FF
	trainer_party_name "Bruce",23,CUBONE,SLOWPOKE,$FF
	
SuperNerdData:
	trainer_party_name "Teru",11,VOLTORB,VOLTORB,$FF
	trainer_party_name "Eric",16,PIKACHU,UMBREON,$FF
	trainer_party_name "Markus",20,VOLTORB,KOFFING,VOLTORB,MAGNEMITE,$FF
	trainer_party_name "Alan",22,GRIMER,MUK,GRIMER,$FF
	trainer_party_name "Derek",26,KOFFING,$FF
	trainer_party_name "Clif",22,KOFFING,MAGNEMITE,WEEZING,$FF
	trainer_party_name "Owen",20,MAGNEMITE,MAGNEMITE,KOFFING,MAGNEMITE,$FF
	trainer_party_name "Ben",24,MAGNEMITE,VOLTORB,$FF
	trainer_party_name "Rick",36,VULPIX,VULPIX,NINETALES,$FF
	trainer_party_name "Marty",34,PONYTA,CHARMANDER,VULPIX,GROWLITHE,$FF
	trainer_party_name "Vince",41,RAPIDASH,$FF
	trainer_party_name "Avery",37,GROWLITHE,VULPIX,$FF
	
HikerData:
	trainer_party_name "Jeff",10,GEODUDE,MACHOP,ONIX,$FF
	trainer_party_name "Dillon",15,MACHOP,GEODUDE,$FF
	trainer_party_name "Russel",13,GEODUDE,MANKEY,MACHOP,$FF
	trainer_party_name "Michael",17,DIGLETT,ONIX,$FF
	trainer_party_name "Trent",21,GEODUDE,ONIX,$FF
	trainer_party_name "Clark",20,GEODUDE,MACHOP,GEODUDE,$FF
	trainer_party_name "Lenny",21,MACHOP,ONIX,$FF
	trainer_party_name "Jay",19,ONIX,GRAVELER,$FF
	trainer_party_name "Bryan",21,GEODUDE,GEODUDE,GRAVELER,$FF
	trainer_party_name "Lucas",25,SKARMORY,$FF
	trainer_party_name "George",20,MACHOP,ONIX,$FF
	trainer_party_name "Devan",19,GEODUDE,MACHOP,GEODUDE,GEODUDE,$FF
	trainer_party_name "Steve",20,ONIX,ONIX,GEODUDE,$FF
	trainer_party_name "Kurt",21,GEODUDE,GRAVELER,$FF
	
BikerData:
	trainer_party_name "Charles",28,KOFFING,GRIMER,EKANS,$FF
	trainer_party_name "Glenn",29,RHYHORN,RHYHORN,$FF
	trainer_party_name "Dwayne",25,KOFFING,GRIMER,$FF
	trainer_party_name "Joel",28,GRIMER,SLUGMA,$FF
	trainer_party_name "Kyle",29,GRIMER,KOFFING,$FF
	trainer_party_name "Billy",33,DITTO,$FF
	trainer_party_name "Alex",26,GRIMER,GRIMER,GRIMER,GRIMER,$FF
	trainer_party_name "Isaac",28,WEEZING,KOFFING,WEEZING,$FF
	trainer_party_name "Jacob",33,MUK,$FF
	trainer_party_name "Wesley",29,VOLTORB,MAGNEMITE,$FF
	trainer_party_name "Logan",29,HOUNDOUR,MURKROW,$FF
	trainer_party_name "Jared",25,KOFFING,WEEZING,KOFFING,KOFFING,WEEZING,$FF
	trainer_party_name "Rick",26,KOFFING,KOFFING,GRIMER,KOFFING,$FF
	trainer_party_name "Jimmy",28,SLUGMA,SLUGMA,KOFFING,$FF
	trainer_party_name "Reggie",29,MURKROW,MUK,$FF
	
BurglarData:
	trainer_party_name "Arnie",29,GROWLITHE,VULPIX,$FF
	trainer_party_name "Dusty",33,GROWLITHE,$FF
	trainer_party_name "Paul",28,VULPIX,CHARMANDER,PONYTA,$FF
	trainer_party_name "Simon",36,GROWLITHE,VULPIX,NINETALES,$FF
	trainer_party_name "Darryl",41,TORKOAL,$FF
	trainer_party_name "Corey",37,VULPIX,GROWLITHE,$FF
	trainer_party_name "Eddie",34,CHARMANDER,CHARMELEON,$FF
	trainer_party_name "Duncan",38,NINETALES,$FF
	trainer_party_name "Isaiah",34,HOUNDOUR,PONYTA,$FF
	
EngineerData:
	trainer_party_name "Bernie",21,MAGNEMITE,PIKACHU,$FF
	trainer_party_name "Flint",21,MAGNEMITE,CHINCHOU,$FF
	trainer_party_name "Jack",18,MAGNEMITE,PIKACHU,$FF

CoupleData: 
	trainer_party_name "Mike & Nat",20,CUBONE,WEEPINBELL,$FF

FisherData:
	trainer_party_name "Walt",17,GOLDEEN,TENTACOOL,GOLDEEN,$FF
	trainer_party_name "Chris",17,TENTACOOL,STARYU,SHELLDER,$FF
	trainer_party_name "Craig",22,GOLDEEN,POLIWAG,GOLDEEN,$FF
	trainer_party_name "Bill",24,TENTACOOL,GOLDEEN,$FF
	trainer_party_name "Hank",27,GOLDEEN,$FF
	trainer_party_name "Brad",21,POLIWAG,SHELLDER,GOLDEEN,HORSEA,$FF
	trainer_party_name "Jimmy",28,SEAKING,GOLDEEN,SEAKING,SEAKING,$FF
	trainer_party_name "Ralph",31,SHELLDER,CLOYSTER,$FF
	trainer_party_name "Bob",27,MAGIKARP,MAGIKARP,MAGIKARP,MAGIKARP,MAGIKARP,MAGIKARP,$FF
	trainer_party_name "Joe",33,SEAKING,GOLDEEN,$FF
	trainer_party_name "Wilton",24,MAGIKARP,MAGIKARP,$FF
	
SwimmerData:
	trainer_party_name "George",16,HORSEA,SHELLDER,$FF
	trainer_party_name "Bruno",30,TENTACOOL,SHELLDER,$FF
	trainer_party_name "Charlie",29,GOLDEEN,HORSEA,STARYU,$FF
	trainer_party_name "Robert",30,POLIWAG,POLIWHIRL,$FF
	trainer_party_name "Chris",27,HORSEA,TENTACOOL,TENTACOOL,GOLDEEN,$FF
	trainer_party_name "Riley",29,GOLDEEN,SHELLDER,SEAKING,$FF
	trainer_party_name "John",30,HORSEA,HORSEA,$FF
	trainer_party_name "Abe",27,TENTACOOL,TENTACOOL,STARYU,HORSEA,TENTACRUEL,$FF
	trainer_party_name "Matthew",31,SHELLDER,CLOYSTER,$FF
	trainer_party_name "Kirk",35,STARYU,$FF
	trainer_party_name "Parker",28,HORSEA,HORSEA,SEADRA,HORSEA,$FF
	trainer_party_name "Ross",33,SEADRA,TENTACRUEL,$FF
	trainer_party_name "Perry",37,STARMIE,$FF
	trainer_party_name "Ryan",33,STARYU,WARTORTLE,$FF
	trainer_party_name "Ben",32,CHINCHOU,LANTURN,STARMIE,$FF
	trainer_party_name "Josiah",31,TENTACOOL,TENTACOOL,TENTACRUEL,$FF
	
CueBallData:
	trainer_party_name "Chance",28,MACHOP,MANKEY,MACHOP,$FF
	trainer_party_name "Dave",29,MANKEY,MACHOP,$FF
	trainer_party_name "Chad",33,MACHOP,$FF
	trainer_party_name "Scott",29,MANKEY,PRIMEAPE,$FF
	trainer_party_name "Nick",29,MACHOP,MACHOKE,$FF
	trainer_party_name "Reese",33,MACHOKE,$FF
	trainer_party_name "Kenny",26,MANKEY,MANKEY,MACHOKE,MACHOP,$FF
	trainer_party_name "Bruce",29,PRIMEAPE,MACHOKE,$FF
	
GamblerData:
	trainer_party_name "Stan",18,POLIWAG,HORSEA,$FF
	trainer_party_name "Rich",18,BELLSPROUT,ODDISH,$FF
	trainer_party_name "Dirk",18,VOLTORB,MAGNEMITE,$FF
	trainer_party_name "Jasper",18,GROWLITHE,VULPIX,$FF
	trainer_party_name "Phil",22,POLIWAG,POLIWAG,POLIWHIRL,$FF
	trainer_party_name "Biff",22,ONIX,GEODUDE,GRAVELER,$FF
	trainer_party_name "Joel",24,GROWLITHE,VULPIX,$FF
	
SwimmerFData:
BeautyData:
	trainer_party_name "Charlotte",24,ODDISH,GLOOM,BELLOSSOM,$FF
	trainer_party_name "Beth",24,BELLSPROUT,WEEPINBELL,$FF
	trainer_party_name "Selena",26,EXEGGCUTE,$FF
	trainer_party_name "Ariana",27,RATTATA,PIKACHU,RATTATA,$FF
	trainer_party_name "Callie",29,CLEFAIRY,MEOWTH,$FF
	trainer_party_name "Malena",35,SEAKING,$FF
	trainer_party_name "Brea",30,SHELLDER,SHELLDER,CLOYSTER,$FF
	trainer_party_name "Kaylee",31,POLIWAG,SEAKING,$FF
	trainer_party_name "Lynn",29,PIDGEOTTO,WIGGLYTUFF,$FF
	trainer_party_name "Holly",29,BULBASAUR,IVYSAUR,$FF
	trainer_party_name "Carly",33,WEEPINBELL,BELLSPROUT,WEEPINBELL,$FF
	trainer_party_name "Kiera",27,POLIWAG,GOLDEEN,SEAKING,GOLDEEN,POLIWAG,$FF
	trainer_party_name "Mandy",30,GOLDEEN,SEAKING,$FF
	trainer_party_name "Anna",29,STARYU,STARYU,STARYU,$FF
	trainer_party_name "Caitlyn",30,SEADRA,HORSEA,SEADRA,$FF
	trainer_party_name "Colby",19,GOLDEEN,$FF ; Misty's Gym, Trainer # 0x10
	trainer_party_name "Callie",30,TENTACOOL,HORSEA,SEEL,$FF ; Route 20, Trainer # 0x11
	trainer_party_name "Marie",31,GOLDEEN,SEAKING,$FF ; Route 20, Trainer # 0x12
	
PsychicData:
	trainer_party_name "Yuri",31,KADABRA,SLOWPOKE,MR_MIME,KADABRA,$FF
	trainer_party_name "Teru",34,MR_MIME,KADABRA,$FF
	trainer_party_name "Kio",33,SLOWPOKE,SLOWBRO,SLOWKING,$FF
	trainer_party_name "Rhen",38,SLOWKING,$FF
	
RockerData:
	trainer_party_name "Debbie",CUSTOM_PIC,ROCKER_F,20,VOLTORB,VOLTORB,VOLTORB,$FF
	trainer_party_name "C.C.",29,EKANS,ARBOK,$FF
	
JugglerData:
	trainer_party_name "Irwin",29,KADABRA,MR_MIME,$FF
	trainer_party_name "Horton",41,DROWZEE,HYPNO,KADABRA,KADABRA,$FF
	trainer_party_name "Fritz",31,GRIMER,MUK,KOFFING,$FF
	trainer_party_name "Liam",34,GRIMER,MUK,TENTACRUEL,$FF
	trainer_party_name "Cloyd",48,MR_MIME,$FF
	trainer_party_name "Derek",33,HYPNO,$FF
	trainer_party_name "Will",38,CROBAT,MUK,$FF
	trainer_party_name "Shawn",34,GOLBAT,WEEZING,MUK,$FF
	
TamerData:
	trainer_party_name "Cole",34,NIDORINO,ARBOK,$FF
	trainer_party_name "Edgar",33,ARBOK,NIDORINO,ARBOK,$FF
	trainer_party_name "Evan",43,RHYHORN,$FF
	trainer_party_name "Jason",39,ARBOK,TAUROS,$FF
	trainer_party_name "Phil",44,PERSIAN,GOLDUCK,$FF
	trainer_party_name "Vince",42,RHYHORN,PRIMEAPE,ARBOK,TAUROS,$FF
	
BirdKeeperData:
	trainer_party_name "Rod",29,PIDGEY,PIDGEOTTO,$FF
	trainer_party_name "Abe",25,SPEAROW,PIDGEY,PIDGEY,SPEAROW,SPEAROW,$FF
	trainer_party_name "Bob",26,PIDGEY,PIDGEOTTO,SPEAROW,FEAROW,$FF
	trainer_party_name "Hank",33,FARFETCHD,$FF
	trainer_party_name "Bret",29,SPEAROW,FEAROW,$FF
	trainer_party_name "Roy",26,PIDGEOTTO,FARFETCHD,DODUO,PIDGEY,$FF
	trainer_party_name "Toby",28,DODRIO,DODUO,DODUO,$FF
	trainer_party_name "Chad",29,SPEAROW,FEAROW,$FF
	trainer_party_name "Mike",34,DODRIO,$FF
	trainer_party_name "Kyle",26,SPEAROW,SPEAROW,FEAROW,SPEAROW,$FF
	trainer_party_name "Willy",30,FEAROW,FEAROW,PIDGEOTTO,$FF
	trainer_party_name "Jeff",39,PIDGEOTTO,PIDGEOTTO,PIDGEY,PIDGEOTTO,$FF
	trainer_party_name "Troy",42,FARFETCHD,FEAROW,$FF
	trainer_party_name "Kevin",28,PIDGEY,DODUO,PIDGEOTTO,$FF
	trainer_party_name "Jim",26,MURKROW,SPEAROW,MURKROW,FEAROW,$FF
	trainer_party_name "Eric",29,PIDGEOTTO,FEAROW,$FF
	trainer_party_name "Chris",28,SPEAROW,MURKROW,FEAROW,$FF
	
BlackbeltData:
	trainer_party_name "Kenji",37,HITMONLEE,HITMONCHAN,$FF
	trainer_party_name "Lao",31,MANKEY,MANKEY,PRIMEAPE,$FF
	trainer_party_name "Hung",32,MACHOP,MACHOKE,$FF
	trainer_party_name "Chang",36,PRIMEAPE,$FF
	trainer_party_name "Toru",31,MACHOP,MANKEY,PRIMEAPE,$FF
	trainer_party_name "Yoshi",40,MACHOP,MACHOKE,$FF
	trainer_party_name "Wang",43,MACHOKE,$FF
	trainer_party_name "Nob",38,MACHOKE,MACHOP,MACHOKE,$FF
	trainer_party_name "Wai",43,MACHOKE,MACHOP,MACHOKE,$FF
	
GentlemanData:
	trainer_party_name "Alfred",18,GROWLITHE,GROWLITHE,$FF
	trainer_party_name "Edward",19,NIDORAN_M,NIDORAN_F,$FF
	trainer_party_name "Preston",23,PIKACHU,$FF
	trainer_party_name "Gregory",48,PRIMEAPE,$FF
	trainer_party_name "Howard",17,GROWLITHE,PONYTA,$FF
	trainer_party_name "Nathan",18,HOUNDOUR,$FF
	
ChannelerData:
	trainer_party_name "Amelia",22,GASTLY,$FF
	trainer_party_name "Selene",24,GASTLY,$FF
	trainer_party_name "Karina",23,MISDREAVUS,GASTLY,$FF
	trainer_party_name "Hope",24,HAUNTER,$FF
	trainer_party_name "Stacy",23,GASTLY,$FF
	trainer_party_name "Gwen",24,GASTLY,$FF
	trainer_party_name "Mary",24,HAUNTER,$FF
	trainer_party_name "Jane",22,GASTLY,$FF
	trainer_party_name "Carly",24,GASTLY,$FF
	trainer_party_name "Trixie",23,GASTLY,MISDREAVUS,$FF
	trainer_party_name "Jodie",24,HAUNTER,$FF
	trainer_party_name "Faith",22,GASTLY,$FF
	trainer_party_name "Alice",24,GASTLY,$FF
	trainer_party_name "Ashe",23,HAUNTER,$FF
	trainer_party_name "Holly",24,GASTLY,$FF
	trainer_party_name "Cindy",22,GASTLY,$FF
	trainer_party_name "Grace",24,GASTLY,$FF
	trainer_party_name "Rei",22,MISDREAVUS,$FF
	trainer_party_name "Leah",22,GASTLY,GASTLY,GASTLY,$FF
	trainer_party_name "Eve",24,GASTLY,$FF
	trainer_party_name "Cassie",24,GASTLY,$FF
	
ScientistData:
	trainer_party_name "Sheldon",34,KOFFING,VOLTORB,$FF
	trainer_party_name "Ross",26,GRIMER,WEEZING,KOFFING,WEEZING,$FF
	trainer_party_name "Mitch",28,MAGNEMITE,VOLTORB,MAGNETON,$FF
	trainer_party_name "Jed",29,ELECTRODE,WEEZING,$FF
	trainer_party_name "Marc",33,ELECTRODE,$FF
	trainer_party_name "Taylor",26,MAGNETON,KOFFING,WEEZING,MAGNEMITE,$FF
	trainer_party_name "Nick",25,VOLTORB,KOFFING,MAGNETON,MAGNEMITE,KOFFING,$FF
	trainer_party_name "Kevin",29,ELECTRODE,MUK,$FF
	trainer_party_name "Howie",29,GRIMER,ELECTRODE,$FF
	trainer_party_name "Brian",28,VOLTORB,KOFFING,MAGNETON,$FF
	trainer_party_name "Alex",29,MAGNEMITE,KOFFING,$FF
	trainer_party_name "Justin",33,MAGNEMITE,MAGNETON,VOLTORB,$FF
	trainer_party_name "Chris",34,MAGNEMITE,ELECTRODE,$FF
	
RocketFData:
RocketData:
	trainer_party_name "Executive"
	db SPECIAL_TRAINER2
	db EXECUTIVE_F
	db AI_POTION
	
	db 15,RATTATA
	moveset BITE, QUICK_ATTACK, FOCUS_ENERGY, IRON_TAIL
	
	db 16,MURKROW
	moveset PECK, QUICK_ATTACK, WING_ATTACK, GROWL
	db $FF

	trainer_party_name "James",CUSTOM_PIC,JAMES,13,KOFFING,$FF
	trainer_party_name "Jessie",CUSTOM_PIC,JESSIE,13,EKANS,$FF
	trainer_party_name "Grunt",14,RATICATE,$FF
	trainer_party_name "Grunt",17,MACHOP,DROWZEE,$FF
	trainer_party_name "Grunt",CUSTOM_PIC,PI_TRAINER,15,EKANS,ZUBAT,$FF ; Nugget Bridge "Boss"
	trainer_party_name "Grunt",20,RATICATE,ZUBAT,$FF
	trainer_party_name "Grunt",21,DROWZEE,MACHOP,$FF
	trainer_party_name "Grunt",21,RATICATE,RATICATE,$FF
	trainer_party_name "Grunt",20,GRIMER,KOFFING,KOFFING,$FF
	trainer_party_name "Grunt",19,RATTATA,RATICATE,RATICATE,RATTATA,$FF
	trainer_party_name "Grunt",22,GRIMER,KOFFING,$FF
	trainer_party_name "Grunt",17,ZUBAT,KOFFING,GRIMER,ZUBAT,RATICATE,$FF
	trainer_party_name "Grunt",20,RATTATA,RATICATE,DROWZEE,$FF
	trainer_party_name "Grunt",21,MACHOP,MACHOP,$FF
	trainer_party_name "James",CUSTOM_PIC,JAMES,23,WEEZING,WEEPINBELL,$FF ; James in Game Corner
	trainer_party_name "Jessie",CUSTOM_PIC,JESSIE,23,ARBOK,LICKITUNG,$FF ; Jessie in Game Corner
	trainer_party_name "Grunt",21,KOFFING,ZUBAT,$FF
	trainer_party_name "Grunt",25,ZUBAT,ZUBAT,GOLBAT,$FF
	trainer_party_name "Grunt",26,KOFFING,DROWZEE,$FF
	trainer_party_name "Executive",CUSTOM_PIC,EXECUTIVE_M,23,HOUNDOUR,HONCHKROW,KOFFING,$FF
	trainer_party_name "Grunt",26,DROWZEE,KOFFING,$FF
	trainer_party_name "Grunt",29,CUBONE,ZUBAT,$FF
	trainer_party_name "Grunt",25,GOLBAT,ZUBAT,ZUBAT,RATICATE,ZUBAT,$FF
	trainer_party_name "Grunt",28,RATICATE,HYPNO,RATICATE,$FF
	trainer_party_name "Grunt",29,MACHOP,DROWZEE,$FF
	trainer_party_name "Grunt",28,EKANS,ZUBAT,CUBONE,$FF
	trainer_party_name "Grunt",33,ARBOK,$FF
	trainer_party_name "Grunt",33,HYPNO,$FF
	trainer_party_name "Grunt",29,MACHOP,MACHOKE,$FF
	trainer_party_name "Grunt",28,ZUBAT,ZUBAT,GOLBAT,$FF
	trainer_party_name "Grunt",26,RATICATE,ARBOK,KOFFING,GOLBAT,$FF
	trainer_party_name "Grunt",29,CUBONE,CUBONE,$FF
	trainer_party_name "Grunt",29,SANDSHREW,SANDSLASH,$FF
	trainer_party_name "Grunt",26,RATICATE,ZUBAT,GOLBAT,RATTATA,$FF
	trainer_party_name "Grunt",28,WEEZING,GOLBAT,KOFFING,$FF
	trainer_party_name "Grunt",28,DROWZEE,GRIMER,MACHOP,$FF
	trainer_party_name "Grunt",28,GOLBAT,DROWZEE,HYPNO,$FF
	trainer_party_name "Grunt",33,MACHOKE,$FF
	trainer_party_name "Grunt",25,RATTATA,RATTATA,ZUBAT,RATTATA,EKANS,$FF
	trainer_party_name "Executive",CUSTOM_PIC,EXECUTIVE_M,34,CUBONE,DROWZEE,MAROWAK,$FF
	
AceTrainerMData:
	trainer_party_name "Aaron",39,NIDORINO,NIDOKING,$FF
	trainer_party_name "Blake",43,EXEGGUTOR,CLOYSTER,ARCANINE,$FF
	trainer_party_name "Brian",43,KINGLER,TENTACRUEL,BLASTOISE,$FF
	trainer_party_name "Cody",45,KINGLER,STARMIE,$FF
	trainer_party_name "Gaven",42,IVYSAUR,WARTORTLE,CHARMELEON,CHARIZARD,$FF
	trainer_party_name "Jake",44,IVYSAUR,WARTORTLE,CHARMELEON,$FF
	trainer_party_name "Danny",49,NIDOKING,$FF
	trainer_party_name "Mike",44,KINGLER,CLOYSTER,$FF
	trainer_party_name "Nick",39,SANDSLASH,DUGTRIO,$FF
	trainer_party_name "Zoro",43,RHYHORN,$FF
	
AceTrainerFData:
	trainer_party_name "Beth",24,WEEPINBELL,GLOOM,IVYSAUR,$FF
	trainer_party_name "Lola",43,BELLSPROUT,WEEPINBELL,VICTREEBEL,$FF
	trainer_party_name "Megan",43,PARASECT,DEWGONG,CHANSEY,$FF
	trainer_party_name "Quinn",46,VILEPLUME,BUTTERFREE,$FF
	trainer_party_name "Irene",44,PERSIAN,NINETALES,$FF
	trainer_party_name "Sara",45,IVYSAUR,VENUSAUR,$FF
	trainer_party_name "Lisa",45,NIDORINA,NIDOQUEEN,$FF
	trainer_party_name "Anna",43,PERSIAN,NINETALES,RAICHU,$FF
	
HexManiacData:
	trainer_party_name "Alice",34,GASTLY,HAUNTER,$FF
	trainer_party_name "Luna",38,HAUNTER,$FF
	trainer_party_name "Carrie",33,GASTLY,GASTLY,HAUNTER,$FF

PkmnTrainerData:
    trainer_party_name "Flannery"
	db SPECIAL_TRAINER2
	db FLANNERY ; pic
	db AI_FULL_RESTORE ; AI
	
	db 33,SLUGMA
	moveset FLAME_WHEEL, SMOG, LIGHT_SCREEN, HAZE
	
	db 33,SLUGMA
	moveset FLAMETHROWER, ROCK_SLIDE, LIGHT_SCREEN, HARDEN
	
	db 36,TORKOAL
	moveset FLAMETHROWER, BODY_SLAM, WITHDRAW, HEX
	db $FF
	
	
	
	trainer_party_name "Janine"
	db SPECIAL_TRAINER2
	db JANINE ; pic
	db AI_X_ATTACK ; AI
	
	db 44,CROBAT
	moveset WING_ATTACK, CONFUSE_RAY, SUPERSONIC, SCREECH
	
	db 44,WEEZING
	moveset SLUDGE, SMOG, TOXIC, EXPLOSION
	
	db 45,VENOMOTH
	moveset TOXIC, PSYCHIC_M, DOUBLE_TEAM, SUPERSONIC
	db $FF
