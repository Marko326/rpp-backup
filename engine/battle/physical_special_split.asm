; MOVE-5.62.183: battle-aware classification, shared by both acting sides.
; wTempMoveID contains the queried low-byte ID. The one-byte active ordinal
; is only valid for the currently acting move, NOT arbitrary target queries
; (Counter / Sucker Punch). Require that the queried ID is also the selected
; move on the acting side before using the extended class table.
; Output classification is returned in wTempMoveID (CALLBA clobbers A).
_BattlePhysicalSpecialSplit::
	ld a, [wTempMoveID]
	cp EXT_MOVE_SLOT_ESCAPE
	jr z, .escape
	ld c, a
	ld a, [wExtendedActiveMoveOrdinal]
	and a
	jr z, .ordinary
	cp NUM_EXTENDED_MOVES + 1
	jr nc, .ordinary
	cp c
	jr nz, .ordinary
	ldh a, [H_WHOSETURN]
	and a
	ld a, [wPlayerSelectedMove]
	jr z, .selected
	ld a, [wEnemySelectedMove]
.selected
	cp c
	jr nz, .ordinary
	ld a, [wExtendedActiveMoveOrdinal]
	dec a
	ld c, a
	ld b, 0
	ld hl, .extendedClasses
	add hl, bc
	ld a, [hl]
	ld [wTempMoveID], a
	ret
.escape
	ld a, PHYSICAL ; preserve pre-existing $ff escape classification
	ld [wTempMoveID], a
	ret
.ordinary
	call _PhysicalSpecialSplit
	ld a, [wTempMoveID]
	cp DYNAMIC
	ret nz
	call ResolveDynamicMoveCategory
	ld [wTempMoveID], a
	ret

; One class per complete extended identity (one-based ordinals 1..40).
; Current prototype moves are damaging physical moves as in the old player
; shortcut. Do NOT derive the class from the reused legacy low byte; future
; special/status extended moves must update their own entry here.
.extendedClasses
	db PHYSICAL ; EXT 01: Power Whip
	db PHYSICAL ; EXT 02: Play Rough
	db PHYSICAL ; EXT 03: POUND
	db PHYSICAL ; EXT 04: TACKLE
	db PHYSICAL ; EXT 05: MEGA_PUNCH
	db PHYSICAL ; EXT 06: CUT
	db PHYSICAL ; EXT 07: GUST
	db PHYSICAL ; EXT 08: PECK
	db PHYSICAL ; EXT 09: VICEGRIP
	db PHYSICAL ; EXT 10: STRENGTH
	db PHYSICAL ; EXT 11: SCRATCH
	db PHYSICAL ; EXT 12: HORN_ATTACK
	db PHYSICAL ; EXT 13: WING_ATTACK
	db PHYSICAL ; EXT 14: POUND
	db PHYSICAL ; EXT 15: VICEGRIP
	db PHYSICAL ; EXT 16: GUST
	db PHYSICAL ; EXT 17: PECK
	db PHYSICAL ; EXT 18: TACKLE
	db PHYSICAL ; EXT 19: MEGA_PUNCH
	db PHYSICAL ; EXT 20: STRENGTH
	db PHYSICAL ; EXT 21: SCRATCH
	db PHYSICAL ; EXT 22: HORN_ATTACK
	db PHYSICAL ; EXT 23: PECK
	db PHYSICAL ; EXT 24: GUST
	db PHYSICAL ; EXT 25: TACKLE
	db PHYSICAL ; EXT 26: VICEGRIP
	db PHYSICAL ; EXT 27: WING_ATTACK
	db PHYSICAL ; EXT 28: MEGA_PUNCH
	db PHYSICAL ; EXT 29: STRENGTH
	db PHYSICAL ; EXT 30: CUT
	db PHYSICAL ; EXT 31: POUND
	db PHYSICAL ; EXT 32: GUST
	db PHYSICAL ; EXT 33: PECK
	db PHYSICAL ; EXT 34: HORN_ATTACK
	db PHYSICAL ; EXT 35: TACKLE
	db PHYSICAL ; EXT 36: WING_ATTACK
	db PHYSICAL ; EXT 37: SCRATCH
	db PHYSICAL ; EXT 38: STRENGTH
	db PHYSICAL ; EXT 39: VICEGRIP
	db PHYSICAL ; EXT 40: MEGA_PUNCH
.extendedClassesEnd
ASSERT .extendedClassesEnd - .extendedClasses == NUM_EXTENDED_MOVES

_PhysicalSpecialSplit:: ;Determines if a move is Physical or Special
	ld a, [wTempMoveID]
	ld c,a
	ld b, $00
	ld hl,.MovesTable
	add hl,bc
	ld a,[hl]
	ld [wTempMoveID], a
	ret

	
.MovesTable
	db OTHER_M ;NOTHING      EQU $00
	db PHYSICAL;POUND        EQU $01
	db PHYSICAL;KARATE_CHOP  EQU $02
	db PHYSICAL;DOUBLESLAP   EQU $03
	db PHYSICAL;COMET_PUNCH  EQU $04
	db PHYSICAL;MEGA_PUNCH   EQU $05
	db PHYSICAL;PAY_DAY      EQU $06
	db PHYSICAL;FIRE_PUNCH   EQU $07
	db PHYSICAL;ICE_PUNCH    EQU $08
	db PHYSICAL;THUNDERPUNCH EQU $09
	db PHYSICAL;SCRATCH      EQU $0A
	db PHYSICAL;VICEGRIP     EQU $0B
	db PHYSICAL;GUILLOTINE   EQU $0C
	db DYNAMIC ;SPARK        EQU $0D
	db OTHER_M ;SWORDS_DANCE EQU $0E
	db PHYSICAL;CUT          EQU $0F
	db SPECIAL ;GUST         EQU $10
	db PHYSICAL;WING_ATTACK  EQU $11
	db OTHER_M ;WHIRLWIND    EQU $12
	db PHYSICAL;FLY          EQU $13
	db PHYSICAL;BIND         EQU $14
	db PHYSICAL;SLAM         EQU $15
	db PHYSICAL;VINE_WHIP    EQU $16
	db PHYSICAL;STOMP        EQU $17
	db PHYSICAL;DOUBLE_KICK  EQU $18
	db PHYSICAL;MEGA_KICK    EQU $19
	db PHYSICAL;JUMP_KICK    EQU $1A
	db SPECIAL ;AURA_SPHERE  EQU $1B
	db OTHER_M ;SAND_ATTACK  EQU $1C
	db PHYSICAL;HEADBUTT     EQU $1D
	db PHYSICAL;HORN_ATTACK  EQU $1E
	db PHYSICAL;FURY_ATTACK  EQU $1F
	db PHYSICAL;HORN_DRILL   EQU $20
	db PHYSICAL;TACKLE       EQU $21
	db PHYSICAL;BODY_SLAM    EQU $22
	db PHYSICAL;WRAP         EQU $23
	db PHYSICAL;TAKE_DOWN    EQU $24
	db PHYSICAL;THRASH       EQU $25
	db PHYSICAL;DOUBLE_EDGE  EQU $26
	db OTHER_M ;TAIL_WHIP    EQU $27
	db PHYSICAL;POISON_STING EQU $28
	db PHYSICAL;TWINEEDLE    EQU $29
	db PHYSICAL;PIN_MISSILE  EQU $2A
	db OTHER_M ;LEER         EQU $2B
	db PHYSICAL;BITE         EQU $2C
	db OTHER_M ;GROWL        EQU $2D
	db OTHER_M ;ROAR         EQU $2E
	db OTHER_M ;SING         EQU $2F
	db OTHER_M ;SUPERSONIC   EQU $30
	db SPECIAL ;SONICBOOM    EQU $31
	db OTHER_M ;DISABLE      EQU $32
	db SPECIAL ;ACID         EQU $33
	db SPECIAL ;EMBER        EQU $34
	db SPECIAL ;FLAMETHROWER EQU $35
	db OTHER_M ;MIST         EQU $36
	db SPECIAL ;WATER_GUN    EQU $37
	db SPECIAL ;HYDRO_PUMP   EQU $38
	db SPECIAL ;SURF         EQU $39
	db SPECIAL ;ICE_BEAM     EQU $3A
	db SPECIAL ;BLIZZARD     EQU $3B
	db SPECIAL ;PSYBEAM      EQU $3C
	db SPECIAL ;BUBBLEBEAM   EQU $3D
	db SPECIAL ;AURORA_BEAM  EQU $3E
	db SPECIAL ;HYPER_BEAM   EQU $3F
	db PHYSICAL;PECK         EQU $40
	db PHYSICAL;DRILL_PECK   EQU $41
	db PHYSICAL;SUBMISSION   EQU $42
	db PHYSICAL;LOW_KICK     EQU $43
	db PHYSICAL;COUNTER      EQU $44
	db PHYSICAL;SEISMIC_TOSS EQU $45
	db PHYSICAL;STRENGTH     EQU $46
	db SPECIAL ;ABSORB       EQU $47
	db SPECIAL ;MEGA_DRAIN   EQU $48
	db OTHER_M ;LEECH_SEED   EQU $49
	db OTHER_M ;GROWTH       EQU $4A
	db PHYSICAL;RAZOR_LEAF   EQU $4B
	db SPECIAL ;SOLARBEAM    EQU $4C
	db OTHER_M ;POISONPOWDER EQU $4D
	db OTHER_M ;STUN_SPORE   EQU $4E
	db OTHER_M ;SLEEP_POWDER EQU $4F
	db SPECIAL ;PETAL_DANCE  EQU $50
	db OTHER_M ;STRING_SHOT  EQU $51
	db SPECIAL ;DRAGON_RAGE  EQU $52
	db SPECIAL ;FIRE_SPIN    EQU $53
	db SPECIAL ;THUNDERSHOCK EQU $54
	db SPECIAL ;THUNDERBOLT  EQU $55
	db OTHER_M ;THUNDER_WAVE EQU $56
	db SPECIAL ;THUNDER      EQU $57
	db PHYSICAL;ROCK_THROW   EQU $58
	db PHYSICAL;EARTHQUAKE   EQU $59
	db PHYSICAL;FISSURE      EQU $5A
	db PHYSICAL;DIG          EQU $5B
	db OTHER_M ;TOXIC        EQU $5C
	db SPECIAL ;CONFUSION    EQU $5D
	db SPECIAL ;PSYCHIC_M    EQU $5E
	db OTHER_M ;HYPNOSIS     EQU $5F
	db OTHER_M ;MEDITATE     EQU $60
	db OTHER_M ;AGILITY      EQU $61
	db PHYSICAL;QUICK_ATTACK EQU $62
	db PHYSICAL;RAGE         EQU $63
	db OTHER_M ;TELEPORT     EQU $64
	db SPECIAL ;NIGHT_SHADE  EQU $65
	db OTHER_M ;MIMIC        EQU $66
	db OTHER_M ;SCREECH      EQU $67
	db OTHER_M ;DOUBLE_TEAM  EQU $68
	db OTHER_M ;RECOVER      EQU $69
	db OTHER_M ;HARDEN       EQU $6A
	db OTHER_M ;MINIMIZE     EQU $6B
	db OTHER_M ;SMOKESCREEN  EQU $6C
	db OTHER_M ;CONFUSE_RAY  EQU $6D
	db OTHER_M ;WITHDRAW     EQU $6E
	db OTHER_M ;DEFENSE_CURL EQU $6F
	db OTHER_M ;BARRIER      EQU $70
	db OTHER_M ;LIGHT_SCREEN EQU $71
	db OTHER_M ;HAZE         EQU $72
	db OTHER_M ;REFLECT      EQU $73
	db OTHER_M ;FOCUS_ENERGY EQU $74
	db PHYSICAL;BIDE         EQU $75
	db OTHER_M ;METRONOME    EQU $76
	db OTHER_M ;MIRROR_MOVE  EQU $77
	db PHYSICAL;SELFDESTRUCT EQU $78
	db SPECIAL ;EGG_BOMB     EQU $79
	db PHYSICAL;LICK         EQU $7A
	db SPECIAL ;SMOG         EQU $7B
	db SPECIAL ;SLUDGE       EQU $7C
	db PHYSICAL;BONE_CLUB    EQU $7D
	db SPECIAL ;FIRE_BLAST   EQU $7E
	db PHYSICAL;WATERFALL    EQU $7F
	db PHYSICAL;CLAMP        EQU $80
	db SPECIAL ;SWIFT        EQU $81
	db PHYSICAL;SKULL_BASH   EQU $82
	db PHYSICAL;SPIKE_CANNON EQU $83
	db PHYSICAL;CONSTRICT    EQU $84
	db OTHER_M ;AMNESIA      EQU $85
	db OTHER_M ;KINESIS      EQU $86
	db OTHER_M ;SOFTBOILED   EQU $87
	db PHYSICAL;HI_JUMP_KICK EQU $88
	db OTHER_M ;GLARE        EQU $89
	db SPECIAL ;DREAM_EATER  EQU $8A
	db OTHER_M ;POISON_GAS   EQU $8B
	db PHYSICAL;BULLET_SEED  EQU $8C
	db PHYSICAL;LEECH_LIFE   EQU $8D
	db OTHER_M ;LOVELY_KISS  EQU $8E
	db PHYSICAL;SKY_ATTACK   EQU $8F
	db OTHER_M ;TRANSFORM    EQU $90
	db SPECIAL ;BUBBLE       EQU $91
	db PHYSICAL;DIZZY_PUNCH  EQU $92
	db OTHER_M ;SPORE        EQU $93
	db OTHER_M ;FLASH        EQU $94
	db SPECIAL ;PSYWAVE      EQU $95
	db OTHER_M ;SPLASH       EQU $96
	db OTHER_M ;ACID_ARMOR   EQU $97
	db PHYSICAL;CRABHAMMER   EQU $98
	db PHYSICAL;EXPLOSION    EQU $99
	db PHYSICAL;FURY_SWIPES  EQU $9A
	db PHYSICAL;BONEMERANG   EQU $9B
	db OTHER_M ;REST         EQU $9C
	db PHYSICAL;ROCK_SLIDE   EQU $9D
	db PHYSICAL;HYPER_FANG   EQU $9E
	db OTHER_M ;HONE_CLAWS   EQU $9F
	db OTHER_M ;CONVERSION   EQU $A0
	db SPECIAL ;TRI_ATTACK   EQU $A1
	db PHYSICAL;SUPER_FANG   EQU $A2
	db PHYSICAL;SLASH        EQU $A3
	db OTHER_M ;SUBSTITUTE   EQU $A4
	db PHYSICAL;STRUGGLE     EQU $A5
	db PHYSICAL;METAL_CLAW   EQU $A6
	db PHYSICAL;BULLET_PUNCH EQU $A7
	db SPECIAL ;FLASH_CANNON EQU $A8
	db PHYSICAL;IRON_TAIL    EQU $A9
	db PHYSICAL;METEOR_MASH  EQU $AA
	db PHYSICAL;CRUNCH       EQU $AB
	db SPECIAL ;DARK_PULSE   EQU $AC
	db PHYSICAL;FEINT_ATTACK EQU $AD
	db PHYSICAL;NIGHT_SLASH  EQU $AE
	db SPECIAL ;MOONBLAST    EQU $AF
	db SPECIAL ;DRAININGKISS EQU $B0
	db SPECIAL ;DISARM_VOICE EQU $B1
	db SPECIAL ;DAZZLINGLEAM EQU $B2
	db SPECIAL ;DRACO_METEOR EQU $B3
	db SPECIAL ;DRAGONBREATH EQU $B4
	db PHYSICAL;DRAGON_CLAW  EQU $B5
	db SPECIAL ;DRAGON_PULSE EQU $B6
	db SPECIAL ;TWISTER      EQU $B7
	db PHYSICAL;OUTRAGE      EQU $B8
	db PHYSICAL;SHADOW_CLAW  EQU $B9
	db PHYSICAL;STEEL WING
	db OTHER_M ;Iron Defense
	db SPECIAL ;Air Slash
	db PHYSICAL;Fire Fang
	db PHYSICAL;Flare Blitz
	db SPECIAL ;Blast Burn
	db PHYSICAL;Ice Fang
	db PHYSICAL;Thunder Fang
	db SPECIAL ;Water Pulse
	db PHYSICAL;Aqua Tail
	db SPECIAL ;Hydro Cannon
	db SPECIAL ;Frenzy Plant
	db PHYSICAL;Sucker Punch
	db SPECIAL ;Shadow Ball
	db PHYSICAL;Flame Wheel
	db OTHER_M ;Moonlight
	db SPECIAL ;Hex
	db PHYSICAL;Shadow Punch
	db PHYSICAL;Aerial Ace
	db PHYSICAL;Acrobatics
	db SPECIAL ;Air Cutter
	db SPECIAL ;Icy Wind
	db PHYSICAL;Ice Shard
	db SPECIAL ;Sheer Cold
	db SPECIAL ;Electro Ball
	db PHYSICAL;Nuzzle
	db SPECIAL ;Discharge
	db PHYSICAL;Volt Tackle
	db SPECIAL ;Muddy Water
	db SPECIAL ;Whirlpool
	db SPECIAL ;Giga Drain
	db SPECIAL ;Energy Ball
	db PHYSICAL;Leaf Blade
	db PHYSICAL;Wood Hammer
	db PHYSICAL;Poison Jab
	db PHYSICAL;Gunk Shot
	db PHYSICAL;Poison Fang
	db SPECIAL ;Sludge Bomb
	db SPECIAL ;Silver Wind
	db SPECIAL ;Bug Buzz
	db PHYSICAL;Megahorn
	db PHYSICAL;X-Scissor
	db SPECIAL ;Signal Beam
	db SPECIAL ;Earth Power
	db SPECIAL ;Mud Slap
	db SPECIAL ;Mud Bomb
	db SPECIAL ;Extrasensory
	db PHYSICAL;Zen Headbutt
	db PHYSICAL;Psycho Cut
	db SPECIAL ;Hyper Voice
	db PHYSICAL;Extremespeed
	db PHYSICAL;Giga Impact
	db SPECIAL ;Power Gem
	db PHYSICAL;Rock Blast
	db OTHER_M ;Rock Polish
	db PHYSICAL;Rock Tomb
	db PHYSICAL;Dynamicpunch
	db PHYSICAL;Circle Throw
	db PHYSICAL;Cross Chop
	db PHYSICAL;Low Sweep
	db SPECIAL ;Hurricane
	db OTHER_M ;Baby Doll Eyes
	; MOV-5.61.53: Sacred Fire is a physical Fire attack.
	db PHYSICAL;Sacred Fire
	db SPECIAL ;Aeroblast
	db SPECIAL ;AncientPower
	db PHYSICAL;Dive (Unused)
    db SPECIAL ;Luster Purge
    db SPECIAL ;Psystrike
    ; MOV-5.61.31: Iron Head is a physical Steel attack.
    db PHYSICAL;Iron Head

; MOVE-5.62.199: Spark Dynamic category (not a Counter redesign).
; Fight menu only previews the category; the damage path resolves it again.
; Stage-adjusted battle Attack/Special are already available in WRAM.
; Burn must not influence category selection, so only burned Attack is
; reconstructed from the original stat and its stage, capped at 999.
; PHYSICAL when Attack >= Special (including ties), otherwise SPECIAL.
ResolveDynamicMoveCategory:
	ldh a, [H_WHOSETURN]
	and a
	jr nz, .enemyStats
.playerStats
	ld hl, wBattleMonAttack
	ld de, wBattleMonSpecial
	ld a, [wBattleMonStatus]
	bit BRN, a
	jr z, .compareLive
	ld a, [wPlayerMonAttackMod]
	ld de, wPlayerMonUnmodifiedAttack
	jr .rebuildBurnedAttack
.enemyStats
	ld hl, wEnemyMonAttack
	ld de, wEnemyMonSpecial
	ld a, [wEnemyMonStatus]
	bit BRN, a
	jr z, .compareLive
	ld a, [wEnemyMonAttackMod]
	ld de, wEnemyMonUnmodifiedAttack
.rebuildBurnedAttack
	; BATTLE-200.002: calculate the unburned stage-adjusted Attack
	; entirely in this ROM bank. The Fight menu can query this while the
	; player is burned; a nested ROM bank hop back into battle core used
	; to make that menu path unsafe. Keep the same ratio table and cap as
	; the normal stat calculator without writing live Attack.
	call ResolveDynamicCalcStageAttack
	; Match the core damage stat cap of 999 before class comparison.
	ld a, [H_DIVIDEND + 3]
	sub 999 % $100
	ld a, [H_DIVIDEND + 2]
	sbc 999 / $100
	jr c, .withinLimit
	lb bc, 999 / $100, 999 % $100
	jr .chooseSpecial
.withinLimit
	ld a, [H_DIVIDEND + 2]
	ld b, a
	ld a, [H_DIVIDEND + 3]
	ld c, a
	; BATTLE-5.62.202: Dynamic classification honors the minimum stat of 1, even when the -6 ratio rounds to 0.
	; The burned Dynamic preview must match core stat recalculation.
	or b
	jr nz, .chooseSpecial
	inc c
.chooseSpecial
	ldh a, [H_WHOSETURN]
	and a
	ld de, wBattleMonSpecial
	jr z, .compareBC
	ld de, wEnemyMonSpecial
	jr .compareBC
.compareLive
	ld a, [hli]
	ld b, a
	ld c, [hl]
.compareBC
	ld a, [de]
	cp b
	jr c, .physical
	jr nz, .special
	inc de
	ld a, [de]
	cp c
	jr c, .physical
	jr z, .physical ; tie: restore Spark's original physical class
.special
	ld a, SPECIAL
	ret
.physical
	ld a, PHYSICAL
	ret


; Exact local equivalent of RecalculateBattleStatFromModifier for Attack.
; Input A=stage (1..13), DE=unmodified Attack (big-endian).
; Output H_DIVIDEND+2/+3 = stage-adjusted value, before 999 cap.
; No mutable battle-stat writes or nested ROM-bank call.
ResolveDynamicCalcStageAttack:
	; The normal battle initializer sets each stage to 7. Clamp an
	; invalid test-save value to neutral rather than indexing outside ratios.
	cp 1
	jr nc, .atLeastOne
	ld a, 7
.atLeastOne
	cp 14
	jr c, .inRange
	ld a, 7
.inRange
	dec a
	add a
	ld c, a
	ld b, 0
	ld hl, .ratios
	add hl, bc
	ld a, [hli]
	ld b, a ; numerator
	ld c, [hl] ; denominator
	push bc
	xor a
	ld [H_MULTIPLICAND], a
	ld a, [de]
	ld [H_MULTIPLICAND + 1], a
	inc de
	ld a, [de]
	ld [H_MULTIPLICAND + 2], a
	pop bc
	ld a, b
	ld [H_MULTIPLIER], a
	push bc
	call Multiply
	pop bc
	ld a, c
	ld [H_DIVISOR], a
	ld b, 4
	call Divide
	ret
.ratios
	db 25, 100, 28, 100, 33, 100, 40, 100, 50, 100, 66, 100
	db 1, 1, 15, 10, 2, 1, 25, 10, 3, 1, 35, 10, 4, 1


; BATTLE-5.62.202 confusion self-hit setup, kept in this spare battle-helper bank
; because battle core bank $0f is already full. This is not a move and must
; not use PhysicalSpecialSplit, the target's defenses, screens or critical-hit
; stat overrides. Input: H_WHOSETURN identifies the self-hitting side.
; Output: H_PRODUCT+2=Attack, +3=own Defense, D=40 power, E=user level.
; Bankswitch clobbers BC, so battle core reloads B/C from scratch bytes.
; The caller sets the active move effect to 0 and the critical flag to 0.
GetConfusionSelfDamageVars::
	ldh a, [H_WHOSETURN]
	and a
	jr nz, .enemy
	ld hl, wBattleMonAttack
	ld de, wBattleMonDefense
	ld a, [wBattleMonLevel]
	jr .readStats
.enemy
	ld hl, wEnemyMonAttack
	ld de, wEnemyMonDefense
	ld a, [wEnemyMonLevel]
.readStats
	push af
	ld a, [de]
	ld b, a
	inc de
	ld a, [de]
	ld c, a ; BC = own Defense
	ld a, [hli]
	ld d, a
	ld e, [hl] ; DE = own Attack
	; Match the core's 10-bit stat handling: divide both by four
	; whenever either operand is wider than a byte.
	ld a, b
	or d
	jr z, .lowBytes
	srl b
	rr c
	srl b
	rr c
	srl d
	rr e
	srl d
	rr e
.lowBytes
	; Damage division must never use a zero Defense. Likewise,
	; the attacking stat is at least one after 10-bit scaling.
	ld a, c
	and a
	jr nz, .defenseNonzero
	inc c
.defenseNonzero
	ld a, e
	and a
	jr nz, .attackNonzero
	inc e
.attackNonzero
	ld a, e
	ld [H_PRODUCT + 2], a
	ld a, c
	ld [H_PRODUCT + 3], a
	pop af
	ld e, a ; user level, not doubled for a critical hit
	ld d, 40 ; confusion self-hit base power
	xor a
	ld [wDamage], a
	ld [wDamage + 1], a
	ret
