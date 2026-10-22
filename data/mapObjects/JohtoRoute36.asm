; R36-5.62.218: retain Gold sign coordinates, defer four gate Warps.
; Sudowoodo event and all NPCs remain absent to leave Route36 traversable.
JohtoRoute36Object:
	db $05 ; Gold original outdoor border block
	db $04 ; Gold park east two lanes plus existing ruins two lanes
	db 13, 47, 0, REGION_WARP_ESCAPE ; retain ruins door source index #0
	db 13, 48, 1, REGION_WARP_ESCAPE ; retain ruins door source index #1
	db 8, 18, 2, REGION_WARP_ESCAPE ; park door source index #2
	db 9, 18, 3, REGION_WARP_ESCAPE ; park door source index #3
	db $04 ; original Gold sign coordinates (Y,X,text ID)
	db  1, 29, 1 ; Trainer Tips
	db 11, 45, 2 ; Ruins of Alph
	db  7, 55, 3 ; Route36
	db  7, 21, 4 ; Trainer Tips
	db $00 ; no NPC objects; Sudowoodo event deferred for free passage
