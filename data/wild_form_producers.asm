; WLD-5.62.24: wild producer configuration lives with the producer bridge in
; roomy bank $3B instead of consuming packed banks $03/$34. Each row is
; map, source + exact 0-based slot, runtime form.

regional_wild_slot: MACRO
	assert ((\2) & REGIONAL_WILD_SLOT_MASK) == 0
	assert (\2) <= REGIONAL_WILD_STATIC_SCRIPT
	assert (\3) <= REGIONAL_WILD_SLOT_MASK
	db \1, (\2) | (\3), \4
ENDM

RegionalFormWildEncounters::
	; WLD-5.62.21 production random-wild placements.
	regional_wild_slot ROUTE_1, REGIONAL_WILD_GRASS, 1, FORM_ALOLA
	regional_wild_slot ROUTE_1, REGIONAL_WILD_GRASS, 2, FORM_ALOLA
	regional_wild_slot ROUTE_1, REGIONAL_WILD_GRASS, 9, FORM_ALOLA
	regional_wild_slot ROUTE_7, REGIONAL_WILD_GRASS, 4, FORM_ALOLA
	regional_wild_slot ROUTE_7, REGIONAL_WILD_GRASS, 6, FORM_ALOLA

	; ANIM-5.62.111: only selected existing wild slots create regional instances.
	regional_wild_slot ROUTE_8, REGIONAL_WILD_GRASS, 6, FORM_HISUI ; GROWLITHE
	regional_wild_slot MANSION_3, REGIONAL_WILD_GRASS, 8, FORM_HISUI ; ARCANINE
	regional_wild_slot POWER_PLANT, REGIONAL_WILD_GRASS, 0, FORM_HISUI ; VOLTORB
	regional_wild_slot POWER_PLANT, REGIONAL_WILD_GRASS, 4, FORM_HISUI ; ELECTRODE
	regional_wild_slot ROUTE_1, REGIONAL_WILD_GRASS, 3, FORM_GALAR ; ZIGZAGOON
	regional_wild_slot MANSION_3, REGIONAL_WILD_GRASS, 5, FORM_GALAR ; WEEZING
	regional_wild_slot SEAFOAM_ISLANDS_3, REGIONAL_WILD_GRASS, 9, FORM_GALAR ; SLOWKING
	regional_wild_slot SAFARI_ZONE_WEST, REGIONAL_WILD_GRASS, 1, FORM_PALDEA_BLAZE ; TAUROS
	db $ff
