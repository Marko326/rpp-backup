; STR-5.61.58: explicit-form producer for Oak's Lab starters.
; Keep wPlayerStarter as the existing Species-only story/rival selector; the
; form is resolved from this table only at the two points that materialize the
; starter: Pokédex preview and Party insertion.

StarterFormTable::
	db STARTER1, STARTER1_FORM
	db STARTER2, STARTER2_FORM
	db STARTER3, STARTER3_FORM
	db 0

; wcf91 = selected starter Species. Return E = configured runtime Form.
; Unknown Species intentionally fall back to NORMAL rather than inheriting any
; previous staged form state.
RegionalFormGetStarterForm::
	ld a,[wcf91]
	ld d,a
	ld hl,StarterFormTable
.loop
	ld a,[hli]
	and a
	jr z,.normal
	cp d
	jr z,.found
	inc hl
	jr .loop
.found
	ld e,[hl]
	ret
.normal
	ld e,FORM_NORMAL
	ret

; Seed the external Pokédex one-shot with the same explicit Form that will be
; used for insertion, then clear the transient view state on return.
RegionalFormShowStarterDex::
	call RegionalFormGetStarterForm
	ld a,e
	ld [wPokedexViewForm],a
	predef StarterDex
	xor a
	ld [wPokedexViewForm],a
	ret

; Add the selected starter through the shared explicit-form insertion bridge.
; RegionalFormAddPartyMonWithForm validates Species + Form and materializes the
; persistent marker without changing the Party/Box Pokémon structure.
RegionalFormAddStarter::
	call RegionalFormGetStarterForm
	callba RegionalFormAddPartyMonWithForm
	ret
