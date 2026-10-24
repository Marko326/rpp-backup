MtMoonShop_h:
	db HOUSE ; tileset
	db MT_MOON_SHOP_HEIGHT, MT_MOON_SHOP_WIDTH ; dimensions (y, x)
	; MSP-5.43.00: use the shared text-box routine directly; redundant local MapScript wrapper removed.
	dw MtMoonShopBlocks, MtMoonShopTextPointers, EnableAutoTextBoxDrawing ; blocks, texts, scripts
	db $00 ; connections
	dw MtMoonShopObject ; objects
