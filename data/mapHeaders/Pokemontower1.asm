PokemonTower1_h:
	db CEMETERY ; tileset
	db POKEMONTOWER_1_HEIGHT, POKEMONTOWER_1_WIDTH ; dimensions (y, x)
	; MSP-5.43.00: use the shared text-box routine directly; redundant local MapScript wrapper removed.
	dw PokemonTower1Blocks, PokemonTower1TextPointers, EnableAutoTextBoxDrawing ; blocks, texts, scripts
	db $00 ; connections
	dw PokemonTower1Object ; objects
