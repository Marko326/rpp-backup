; Passive NPC interaction for the first Olivine batch.
; Input: hSpriteIndexOrTextID is nonzero (could also be a sign text ID).
; Output: carry iff sprite #1 in one of these two native indoor maps.
; Never touches script text pointers, items, flags, battle or dialogue state.
IsDeferredOlivineHouseNPC::
	ld a, [wCurRegion]
	cp MAP_REGION_JOHTO
	jr nz, .notPassive
	ld a, [wCurLocalMapID]
	cp JOHTO_OLIVINE_TIMS_HOUSE_LOCAL_ID
	jr z, .inHouse
	cp JOHTO_OLIVINE_GOOD_ROD_HOUSE_LOCAL_ID
	jr nz, .notPassive
.inHouse
	ld a, [hSpriteIndexOrTextID]
	cp 1
	jr nz, .notPassive
	; Signs in Tim's house also use text ID #1. Check the tile in
	; front of the player so bookshelf A still opens its normal text.
	predef GetTileAndCoordsInFrontOfPlayer ; D = Y, E = X
	ld a, d
	cp 3
	jr nz, .notPassive
	ld a, e
	cp 2
	jr nz, .notPassive
	scf
	ret
.notPassive
	and a ; clear carry
	ret
