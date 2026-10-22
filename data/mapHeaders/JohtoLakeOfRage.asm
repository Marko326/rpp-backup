; Gold LakeOfRage 20x18: South Route43 offset +5.
JohtoLakeOfRage_h:
 db JOHTO
 db JOHTO_LAKE_OF_RAGE_HEIGHT, JOHTO_LAKE_OF_RAGE_WIDTH
 dw JohtoLakeOfRageBlocks, JohtoLakeOfRageTextPointers, EnableAutoTextBoxDrawing
 db SOUTH
 db REGION_NATIVE_MAP_SLOT
 dw JohtoRoute43Blocks
 dw wOverworldMap + (JOHTO_LAKE_OF_RAGE_HEIGHT + 3) * (JOHTO_LAKE_OF_RAGE_WIDTH + 6) + 3 + 5
 db JOHTO_ROUTE_43_WIDTH
 db JOHTO_ROUTE_43_WIDTH
 db 0
 db -10
 dw wOverworldMap + 7 + JOHTO_ROUTE_43_WIDTH
 dw JohtoLakeOfRageObject
