; $60 bytes for each tileset. Each byte is the palette number for a tile.
; Remaining $a0 tiles aren't part of the tileset and are set to 7 (text palette).
; Refer to MapPaletteSets for clarification on specific colors
; Each row of entries corresponds to a row of tiles on the tileset image
MapPaletteAssignments:
	; 运行时雪景以普通版调色板分配为基础，再按需覆盖差分。
	INCLUDE "color/tilesets/overworld.asm" ; OVERWORLD

INCLUDE "color/tilesets/reds_house.asm" ; REDS_HOUSE_1
INCLUDE "color/tilesets/mart.asm" ; MART

	INCLUDE "color/tilesets/forest.asm" ; FOREST

INCLUDE "color/tilesets/reds_house.asm" ; REDS_HOUSE_2
INCLUDE "color/tilesets/oakts.asm" ; OAK_TS
INCLUDE "color/tilesets/pokecenter.asm" ; POKECENTER
INCLUDE "color/tilesets/gym.asm" ; GYM
INCLUDE "color/tilesets/house.asm" ; HOUSE
INCLUDE "color/tilesets/forest_gate.asm" ; FOREST_GATE
INCLUDE "color/tilesets/museum.asm" ; MUSEUM
INCLUDE "color/tilesets/underground.asm" ; UNDERGROUND
INCLUDE "color/tilesets/gate.asm" ; GATE
INCLUDE "color/tilesets/ship.asm" ; SHIP
INCLUDE "color/tilesets/ship_port.asm" ; SHIP_PORT
INCLUDE "color/tilesets/cemetery.asm" ; CEMETERY
INCLUDE "color/tilesets/interior.asm" ; INTERIOR
INCLUDE "color/tilesets/cavern.asm" ; CAVERN
INCLUDE "color/tilesets/lobby.asm" ; LOBBY
INCLUDE "color/tilesets/mansion.asm" ; MANSION
INCLUDE "color/tilesets/lab.asm" ; LAB
INCLUDE "color/tilesets/club.asm" ; CLUB
INCLUDE "color/tilesets/facility.asm" ; FACILITY

	INCLUDE "color/tilesets/plateau.asm" ; PLATEAU
	INCLUDE "color/tilesets/safari.asm" ; SAFARI

INCLUDE "color/tilesets/ferry.asm" ; FERRY
INCLUDE "color/tilesets/ice_cavern.asm" ; ICE_CAVERN
INCLUDE "color/tilesets/museum2.asm" ; MUSEUM_2
INCLUDE "color/tilesets/johto.asm" ; JOHTO
INCLUDE "color/tilesets/johto_gate.asm" ; JOHTO_GATE
INCLUDE "color/tilesets/johto_union_cave.asm" ; JOHTO_UNION_CAVE
INCLUDE "color/tilesets/johto_modern.asm" ; JOHTO_MODERN
INCLUDE "color/tilesets/johto_ilex_forest.asm" ; JOHTO_ILEX_FOREST
INCLUDE "color/tilesets/johto_park.asm" ; JOHTO_PARK
INCLUDE "color/tilesets/johto_park_gate.asm" ; JOHTO_PARK_GATE
INCLUDE "color/tilesets/johto_ruins_gate.asm" ; JOHTO_RUINS_GATE
INCLUDE "color/tilesets/johto_house.asm" ; JOHTO_HOUSE
INCLUDE "color/tilesets/johto_olivine_pokecenter.asm" ; JOHTO_OLIVINE_POKECENTER
INCLUDE "color/tilesets/johto_olivine_mart.asm" ; JOHTO_OLIVINE_MART
INCLUDE "color/tilesets/johto_olivine_cafe.asm" ; JOHTO_OLIVINE_CAFE
