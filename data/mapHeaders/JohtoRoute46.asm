; Gold Route46 E Route45 (offset -36); Route29 southern seam deferred.
JohtoRoute46_h:
 db JOHTO
 db JOHTO_ROUTE_46_HEIGHT, JOHTO_ROUTE_46_WIDTH
 dw JohtoRoute46Blocks, JohtoRoute46TextPointers, EnableAutoTextBoxDrawing
 db SOUTH | EAST
 ; Gold Route46 -> Route29, -10 blocks: 20 tile X offset, all wall.
 db JOHTO_ROUTE_29
 dw JohtoRoute29Blocks + 10
 dw wOverworldMap + (JOHTO_ROUTE_46_HEIGHT + 3) * (JOHTO_ROUTE_46_WIDTH + 6) + 3
 db JOHTO_ROUTE_46_WIDTH
 db JOHTO_ROUTE_29_WIDTH
 db 0
 db 20
 dw wOverworldMap + 7 + JOHTO_ROUTE_29_WIDTH
 db REGION_NATIVE_MAP_SLOT
 dw JohtoRoute45Blocks + JOHTO_ROUTE_45_WIDTH * 36
 dw wOverworldMap + 3 * (JOHTO_ROUTE_46_WIDTH + 6) + JOHTO_ROUTE_46_WIDTH + 3
 db JOHTO_ROUTE_45_HEIGHT - 36
 db JOHTO_ROUTE_45_WIDTH
 db 72
 db 0
 dw wOverworldMap + 7 + JOHTO_ROUTE_45_WIDTH
 dw JohtoRoute46Object
