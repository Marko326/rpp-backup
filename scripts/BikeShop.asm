BikeShopTextPointers:
	dw BikeShopText1
	dw BikeShopText2
	dw BikeShopText3

BikeShopText1:
	TX_ASM
	CheckEvent EVENT_GOT_BICYCLE
	jr z, .checkVoucher
	ld hl, BikeShopText_1d82f
	call PrintText
	jr .Done

.checkVoucher
	ld b, BIKE_VOUCHER
	call IsItemInBag
	jr z, .NoVoucher
	ld hl, BikeShopText_1d81f
	call PrintText
	lb bc, BICYCLE, 1
	call GiveItem
	jr nc, .BagFull
	ld a, BIKE_VOUCHER
	ld [$ffdb], a
	callba RemoveItemByID
	SetEvent EVENT_GOT_BICYCLE
	ld hl, BikeShopText_1d824
	call PrintText
	jr .Done

.BagFull
	ld hl, BikeShopText_1d834
	call PrintText
	jr .Done

.NoVoucher
; BIK-5.35.00: the 3-byte BCD wallet cannot reach the old ¥1,000,000
; menu price. Keep that price and the Voucher clue in dialogue instead of
; presenting a purchase branch that can never succeed.
	ld hl, BikeShopText_1d810
	call PrintText
.Done
	jp TextScriptEnd

BikeShopText_1d810:
	TX_FAR _BikeShopText_1d810
	db "@"

BikeShopText_1d81f:
	TX_FAR _BikeShopText_1d81f
	db "@"

BikeShopText_1d824:
	TX_FAR _BikeShopText_1d824
	TX_SFX_KEY_ITEM
	db "@"

BikeShopText_1d82f:
	TX_FAR _BikeShopText_1d82f
	db "@"

BikeShopText_1d834:
	TX_FAR _BikeShopText_1d834
	db "@"

BikeShopText2:
	TX_ASM
	ld hl, BikeShopText_1d843
	call PrintText
	jp TextScriptEnd

BikeShopText_1d843:
	TX_FAR _BikeShopText_1d843
	db "@"

BikeShopText3:
	TX_ASM
	CheckEvent EVENT_GOT_BICYCLE
	ld hl, BikeShopText_1d861
	jr nz, .asm_34d2d
	ld hl, BikeShopText_1d85c
.asm_34d2d
	call PrintText
	jp TextScriptEnd

BikeShopText_1d85c:
	TX_FAR _BikeShopText_1d85c
	db "@"

BikeShopText_1d861:
	TX_FAR _BikeShopText_1d861
	db "@"
