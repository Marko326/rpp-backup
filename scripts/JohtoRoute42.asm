; B-ID63: Gold-visible BG_EVENT_READ texts. No global trainers/flags claimed.
JohtoRoute42TextPointers:
	dw JohtoRoute42SignWestText
	dw JohtoRoute42MtMortarSignWestText
	dw JohtoRoute42MtMortarSignEastText
	dw JohtoRoute42SignEastText

JohtoRoute42SignWestText:
JohtoRoute42SignEastText:
	text "ROUTE 42"
	para "ECRUTEAK CITY -"
	line "MAHOGANY TOWN"
	done
	db "@"

JohtoRoute42MtMortarSignWestText:
JohtoRoute42MtMortarSignEastText:
	text "MOUNT MORTAR"
	para "WATERFALL CAVE"
	line "Inside"
	done
	db "@"

; FIELD MOVES (C runtime integration required; NO global engine edited by B):
; Route42 Surf: 120 precise Gold WATER cells in 60x18 16x16 coordinate
; grid, low bit = leftmost cell, 8 bytes per row (high four bits unused).
; C: hook ONLY this local ID into IsJohtoNativeOutdoorWaterAhead,
; the A-button and Surfboard item paths, badge permission, coast landing,
; outdoor->gate crossing, collision mask and Surf music; run negative tests.
; Headbutt: 40 Gold HEADBUTT_TREE quadrants, intentionally NO permission.
; Cut: 1 Gold CUT_TREE at (x=24,y=13), source block $63 quadrant BL.
; C must implement reviewed local Cut permission and exact in-view block
; replacement with a unique harmless target block, not a global tile whitelist.
; Surf runtime water bitmask now in Bank $42 via maps/JohtoRoute42.water_mask.bin.

; Gold-specific move target metadata only (NOT a live runtime handler).
JohtoRoute42CutTreeCell::
	db 13, 24 ; y,x
JohtoRoute42CutSourceBlock::
	db $63 ; RPP/Gold source block, BL quadrant CUT_TREE
