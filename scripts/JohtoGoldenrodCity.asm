; ILEX-5.62.216: one Gold exterior sign grants the necessary Bicycle
; without entering the unfinished Bike Shop building. Existing owners keep
; their item; full bags may retry. The Kanto receipt event stays consistent.
JohtoGoldenrodCityTextPointers:
	dw JohtoGoldenrodBikeSignText

JohtoGoldenrodBikeSignText:
	TX_ASM
	ld b, BICYCLE
	call IsItemInBag
	jr nz, .owned
	lb bc, BICYCLE, 1
	call GiveItem
	jr nc, .bagFull
	SetEvent EVENT_GOT_BICYCLE
	ld hl, .received
	jp PrintTextAndTextScriptEnd
.owned
	ld hl, .alreadyOwn
	jp PrintTextAndTextScriptEnd
.bagFull
	ld hl, .noRoom
	jp PrintTextAndTextScriptEnd
.received
	text "BIKE SHOP"
	line "Take this BICYCLE!"
	done
	db "@"
.alreadyOwn
	text "BIKE SHOP"
	line "Ride your BICYCLE!"
	done
	db "@"
.noRoom
	text "Your BAG is full."
	line "Come back later."
	done
	db "@"
