TypeEffects:
; Readable source macros still emit the compact one-byte matchup format.
; A group header has bit 7 set; matchup bytes keep bit 7 clear.
; $ff terminates the whole table.

	type_effect_group WATER
	super_effective FIRE
	super_effective ROCK
	not_very_effective WATER
	not_very_effective GRASS
	super_effective GROUND
	not_very_effective DRAGON

	type_effect_group FIRE
	super_effective GRASS
	super_effective ICE
	not_very_effective FIRE
	not_very_effective WATER
	super_effective BUG
	not_very_effective ROCK
	not_very_effective DRAGON
	super_effective STEEL

	type_effect_group GRASS
	super_effective WATER
	not_very_effective GRASS
	not_very_effective FIRE
	super_effective GROUND
	not_very_effective BUG
	not_very_effective POISON
	super_effective ROCK
	not_very_effective FLYING
	not_very_effective DRAGON
	not_very_effective STEEL

	type_effect_group ELECTRIC
	super_effective WATER
	not_very_effective ELECTRIC
	not_very_effective GRASS
	no_effect GROUND
	super_effective FLYING
	not_very_effective DRAGON

	type_effect_group GROUND
	no_effect FLYING
	super_effective FIRE
	super_effective ELECTRIC
	not_very_effective GRASS
	not_very_effective BUG
	super_effective ROCK
	super_effective POISON
	super_effective STEEL

	type_effect_group ICE
	not_very_effective ICE
	not_very_effective WATER
	super_effective GRASS
	super_effective GROUND
	super_effective FLYING
	super_effective DRAGON
	not_very_effective STEEL
	not_very_effective FIRE

	type_effect_group PSYCHIC
	not_very_effective PSYCHIC
	super_effective FIGHTING
	super_effective POISON
	no_effect DARK
	not_very_effective STEEL

	type_effect_group NORMAL
	not_very_effective ROCK
	no_effect GHOST
	not_very_effective STEEL

	type_effect_group GHOST
	super_effective GHOST
	no_effect NORMAL
	super_effective PSYCHIC
	not_very_effective DARK

	type_effect_group FIGHTING
	super_effective NORMAL
	not_very_effective POISON
	not_very_effective FLYING
	not_very_effective PSYCHIC
	not_very_effective BUG
	super_effective ROCK
	super_effective ICE
	no_effect GHOST
	super_effective DARK
	not_very_effective FAIRY
	super_effective STEEL

	type_effect_group POISON
	super_effective GRASS
	not_very_effective POISON
	not_very_effective GROUND
	not_very_effective ROCK
	not_very_effective GHOST
	super_effective FAIRY
	no_effect STEEL

	type_effect_group FLYING
	not_very_effective ELECTRIC
	super_effective FIGHTING
	super_effective BUG
	super_effective GRASS
	not_very_effective ROCK
	not_very_effective STEEL

	type_effect_group BUG
	not_very_effective FIRE
	super_effective GRASS
	not_very_effective FIGHTING
	not_very_effective FLYING
	super_effective PSYCHIC
	not_very_effective GHOST
	not_very_effective POISON
	super_effective DARK
	not_very_effective FAIRY
	not_very_effective STEEL

	type_effect_group ROCK
	super_effective FIRE
	not_very_effective FIGHTING
	not_very_effective GROUND
	super_effective FLYING
	super_effective BUG
	super_effective ICE
	not_very_effective STEEL

	type_effect_group DRAGON
	super_effective DRAGON
	no_effect FAIRY
	not_very_effective STEEL

	type_effect_group DARK
	not_very_effective FIGHTING
	super_effective GHOST
	super_effective PSYCHIC
	not_very_effective FAIRY
	not_very_effective DARK

	type_effect_group FAIRY
	super_effective DARK
	super_effective FIGHTING
	not_very_effective POISON
	not_very_effective STEEL
	not_very_effective FIRE
	super_effective DRAGON

	type_effect_group STEEL
	super_effective ROCK
	not_very_effective STEEL
	not_very_effective FIRE
	not_very_effective WATER
	not_very_effective ELECTRIC
	super_effective ICE
	super_effective FAIRY

	db $ff

; Move-specific exceptions are intentionally separate from the global type chart.
; Entries are: move ID, defending type, final multiplier (0/5/10/20).
MoveTypeEffectOverrides:
	neutral_type_override BONE_CLUB, FLYING
	neutral_type_override BONEMERANG, FLYING
	db 0
