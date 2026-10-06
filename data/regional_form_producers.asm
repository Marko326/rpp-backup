; STR-5.62.22: explicit Oak Lab Starter forms. Species remains the existing
; story/rival identity; Form is resolved only when previewing or materializing
; the selected Starter instance.
StarterFormTable::
	db STARTER1, STARTER1_FORM
	db STARTER2, STARTER2_FORM
	db STARTER3, STARTER3_FORM
	db 0

; FORM-5.62.20: location-specific evolution form overrides.
; Row layout: map, source Species, source form, target Species, target form.
; Keep production data empty until a map/story explicitly opts into a rule.
RegionalFormEvolutionOverrides::
	db $ff
