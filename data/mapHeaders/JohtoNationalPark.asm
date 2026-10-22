; Gold NationalPark 20x27; no direct joins, only two verified double gate exits.
JohtoNationalPark_h:
	db JOHTO_PARK
	db JOHTO_NATIONAL_PARK_HEIGHT, JOHTO_NATIONAL_PARK_WIDTH
	dw JohtoNationalParkBlocks, JohtoNationalParkTextPointers, EnableAutoTextBoxDrawing
	db 0
	dw JohtoNationalParkObject
