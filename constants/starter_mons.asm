STARTER1 EQU CHARMANDER
STARTER2 EQU SQUIRTLE
STARTER3 EQU BULBASAUR

; STR-5.61.58: starter Species and runtime Form are configured independently.
; Current production starters remain normal; changing a starter to a regional
; form only requires updating the matching *_FORM constant as long as that
; Species + Form has a registered regional-form descriptor.
STARTER1_FORM EQU FORM_NORMAL
STARTER2_FORM EQU FORM_NORMAL
STARTER3_FORM EQU FORM_NORMAL
