; R35-5.62.223: Gold Route35 10x18, JOHTO terrain; north Route36 only.
; NOTE: visual-only right-border fill is addressed in subsequent fix(map) patch.
; South Goldenrod gate and National Park gate remain unregistered.
JohtoRoute35_h:
	db JOHTO
	db JOHTO_ROUTE_35_HEIGHT, JOHTO_ROUTE_35_WIDTH
	dw JohtoRoute35Blocks, JohtoRoute35TextPointers, EnableAutoTextBoxDrawing
	db NORTH
	; First port uses only the ten Gold-aligned walkable columns.
	; Extra right-side preview is a separate follow-up fix.
	db REGION_NATIVE_MAP_SLOT
	dw JohtoRoute36Blocks + JOHTO_ROUTE_36_WIDTH * (JOHTO_ROUTE_36_HEIGHT - 3)
	dw wOverworldMap + 3
	db JOHTO_ROUTE_35_WIDTH ; original 10-column overlap
	db JOHTO_ROUTE_36_WIDTH
	db JOHTO_ROUTE_36_HEIGHT * 2 - 1
	db 0
	dw wOverworldMap + 1 + JOHTO_ROUTE_36_HEIGHT * (JOHTO_ROUTE_36_WIDTH + 6)
	dw JohtoRoute35Object
