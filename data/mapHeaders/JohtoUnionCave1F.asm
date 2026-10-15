; Gold UnionCave1F is 10x18 32x32 blocks. No outdoor connections.
JohtoUnionCave1F_h:
	db JOHTO_UNION_CAVE
	db JOHTO_UNION_CAVE_1F_HEIGHT, JOHTO_UNION_CAVE_1F_WIDTH
	dw JohtoUnionCave1FBlocks, JohtoUnionCave1FTextPointers, EnableAutoTextBoxDrawing
	db $00
	dw JohtoUnionCave1FObject
