; Gold Route43 10x27: North LakeOfRage offset -5; south Mahogany offset 0.
JohtoRoute43_h:
 db JOHTO
 db JOHTO_ROUTE_43_HEIGHT, JOHTO_ROUTE_43_WIDTH
 dw JohtoRoute43Blocks, JohtoRoute43TextPointers, EnableAutoTextBoxDrawing
 db NORTH | SOUTH
 ; Gold offset -5: copy three extra Lake columns (x2..4) into the
 ; west WRAM border so walking the separate x0 footpath shows lake art,
 ; not stale default-tree blocks. The extra columns are display-only.
 db REGION_NATIVE_MAP_SLOT
 dw JohtoLakeOfRageBlocks + 2 + JOHTO_LAKE_OF_RAGE_WIDTH * (JOHTO_LAKE_OF_RAGE_HEIGHT - 3)
 dw wOverworldMap
 db JOHTO_ROUTE_43_WIDTH + 3
 db JOHTO_LAKE_OF_RAGE_WIDTH
 db JOHTO_LAKE_OF_RAGE_HEIGHT * 2 - 1
 db 10
 dw wOverworldMap + 1 + JOHTO_LAKE_OF_RAGE_HEIGHT * (JOHTO_LAKE_OF_RAGE_WIDTH + 6)
 db REGION_NATIVE_MAP_SLOT
 dw JohtoMahoganyTownBlocks
 dw wOverworldMap + (JOHTO_ROUTE_43_HEIGHT + 3) * (JOHTO_ROUTE_43_WIDTH + 6) + 3
 db JOHTO_ROUTE_43_WIDTH
 db JOHTO_MAHOGANY_TOWN_WIDTH
 db 0
 db 0
 dw wOverworldMap + 7 + JOHTO_MAHOGANY_TOWN_WIDTH
 dw JohtoRoute43Object
