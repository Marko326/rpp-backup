; DEX-5.62.130: Professor Oak's regional research on registered identities.
; This runs only from the ordinary rating path, after its original text and
; species counts have been presented. The Hall of Fame path is untouched.
;
; Counter bytes: normal Oak ratings are finished when this routine runs,
; so their original HRAM display counters may be reused for this second page.
; The third counter occupies a runtime-only, non-saved WRAMX byte.
RegionalDexShowOakResearch::
	call RegionalDexCountResearch
	ld hl, RegionalDexOakResearchText
	call PrintText
	jp WaitForTextScrollButtonPress

; Scan the actual Species + Form registration pairs, not their capacity or
; a frozen denominator. Each non-NORMAL slot is counted once; Seen and Owned
; query the slot's existing save bit. A new appended form counts automatically.
RegionalDexCountResearch:
	xor a
	ld [hDexRatingNumMonsSeen],a
	ld [hDexRatingNumMonsOwned],a
	ld [wRegionalDexResearchTotal],a
	ld hl,RegionalDexSlots + 1 ; point at the form byte
	ld c,0                     ; immutable registered slot ID
.loop
	ld a,[hl]
	cp FORM_NORMAL
	jr z,.next
	push hl
	push bc
	ld hl,wRegionalDexResearchTotal
	inc [hl]
	; Slot-indexed bit tests avoid a second scan of RegionalDexSlots.
	call RegionalDexResearchSeenSlot
	and a
	jr z,.notSeen
	ld hl,hDexRatingNumMonsSeen
	inc [hl]
.notSeen
	pop bc
	push bc
	call RegionalDexOwnedTestSlot
	and a
	jr z,.notOwned
	ld hl,hDexRatingNumMonsOwned
	inc [hl]
.notOwned
	pop bc
	pop hl
.next
	inc hl
	inc hl
	inc c
	ld a,c
	cp REGIONAL_DEX_SLOT_COUNT
	jr nz,.loop
	ret

; C = permanent slot ID; reuse the existing Seen action after its lookup.
RegionalDexResearchSeenSlot:
	ld b,FLAG_TEST
	jp RegionalDexSeenAction.slot

; On-screen summary. No original 208-species counts are modified in storage.
RegionalDexOakResearchText:
	text "REGIONAL FORMS"
	line "Seen: @"
	TX_NUM hDexRatingNumMonsSeen, 1, 3
	text "/@"
	TX_NUM wRegionalDexResearchTotal, 1, 3
	; DEX-5.62.131: resume string parsing after the number commands.
	text ""
	para "Owned: @"
	TX_NUM hDexRatingNumMonsOwned, 1, 3
	text "/@"
	TX_NUM wRegionalDexResearchTotal, 1, 3
	text ""
	done
