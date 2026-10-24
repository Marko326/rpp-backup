; DEX-5.62.115: storage for up to 128 independent form identities.
; Species Pokédex Seen/Owned still control 208-entry totals; nothing yet
; registers encounters or modifies Pokédex UI. D=species, E=runtime form.
; Carry indicates a registered identity, C=permanent ID (currently 0..79).
;
; DEX-5.62.116/S2A: call only after LoadEnemyMonData has resolved the
; untransformed encounter/party header. It is also called from non-battle
; materialization (e.g. direct-to-box gifts), which must NOT count as an
; actual encounter here; S2B will register successfully obtained gifts.
RegionalDexMarkBattleEnemySeen::
	ld a,[wIsInBattle]
	cp 1 ; wild encounter
	jr z,.register
	cp 2 ; trainer opponent
	ret nz ; previews, gifts, unrelated materializations
.register
	ld a,[wEnemyMonSpecies2] ; source identity, not Transform's display Species
	ld d,a
	ld a,[wEnemyMonForm] ; resolved original form from header
	ld e,a
	jp RegionalDexSeenSet ; no slot -> no mutation, flag set is idempotent

; DEX-5.62.117: a successful wild capture has already been confirmed by the
; ball handler. The original enemy Species2/Form are still resident here, even
; after Transform; gifts, previews and opponents must never call this entry.
RegionalDexMarkCapturedWildOwned::
	ld a,[wIsInBattle]
	cp 1
	ret nz
	ld a,[wEnemyMonSpecies2]
	ld d,a
	ld a,[wEnemyMonForm]
	ld e,a
	jp RegionalDexOwnedSet ; Owned also writes Seen; no extra species row

; Pokédex detail authorization for the selected Species + Form. Registered
; identities use ONLY their own Owned bit. Species without any regional slot
; retain the stock shared-species Pokédex behavior. Z = not owned.
; Input: D=internal species, E=view form. Both registers preserved.
RegionalDexPokedexOwnedTest::
	push de
	call RegionalDexFindSlot
	pop de
	jr c,.tracked
	ld a,d
	ld [wd11e],a
	predef IndexToPokedex
	ld a,[wd11e]
	dec a
	ld c,a
	ld b,FLAG_TEST
	ld hl,wPokedexOwned
	predef FlagActionPredef
	ld a,c
	and a
	ret
.tracked
	jp RegionalDexOwnedTest

; Wild battle HUD: the latched original marker survives Transform whereas
; wEnemyMonForm can become the transformed appearance. Z = not Owned.
; An invalid nonzero marker must not silently fall back to ordinary Owned.
RegionalDexWildHUDOwnedTest::
	ld a,[wEnemyMonSpecies2]
	ld d,a
	ld a,[wWildEncounterFormMarker]
	and a
	jr z,.normal
	ld e,a
	push de
	callba RegionalFormGetFormBySpeciesMarker ; D = resolved runtime form
	jr nc,.invalidMarker
	ld a,d
	pop de ; restore original species
	ld e,a
	jr .checkOwned
.invalidMarker
	pop de
	xor a
	ret
.normal
	ld e,FORM_NORMAL
.checkOwned
	jp RegionalDexPokedexOwnedTest ; untracked ordinary species use stock bit

; Real acquisitions only. D = final Species, E = persistent stored marker.
; The descriptor decoder returns runtime Form in D. Ordinary stored catch-rate
; bytes do not match a regional marker and retain FORM_NORMAL as intended.
RegionalDexMarkStoredMonOwned::
	push de
	callba RegionalFormGetFormBySpeciesMarker
	jr nc,.normal
	ld a,d
	pop de
	ld e,a
	jp RegionalDexOwnedSet
.normal
	pop de
	ld e,FORM_NORMAL
	jp RegionalDexOwnedSet

; Successful Party insertion (gift or starter). Read the LAST STORED party
; record rather than any preview or the current enemy's temporary header.
RegionalDexMarkNewestPartyOwned::
	ld a,[wPartyCount]
	and a
	ret z
	dec a
	ld hl,wPartyMon1
	ld bc,wPartyMon2 - wPartyMon1
	call AddNTimes
	ld a,[hl]
	ld d,a
	ld bc,wPartyMon1CatchRate - wPartyMon1
	add hl,bc
	ld e,[hl]
	jp RegionalDexMarkStoredMonOwned

; Full-party gift: only after SendNewMonToBox succeeds. The sender prepared
; this species/marker in the same header it copied to the new box record.
RegionalDexMarkGiftBoxOwned::
	ld a,[wEnemyMonSpecies2]
	ld d,a
	ld a,[wEnemyMonCatchRate_NotReferenced]
	ld e,a
	jp RegionalDexMarkStoredMonOwned

; Evolution: invoked only after the target has been committed and copied to
; Party. A cancellation never reaches this point.
RegionalDexMarkEvolvedMonOwned::
	; Retain the original Species-level Seen/Owned path for the 208 count.
	ld a,[wEvoNewSpecies]
	ld [wd11e],a
	predef IndexToPokedex
	ld a,[wd11e]
	dec a
	ld c,a
	ld b,FLAG_SET
	ld hl,wPokedexOwned
	push bc
	predef FlagActionPredef
	pop bc
	ld hl,wPokedexSeen
	predef FlagActionPredef
	; Read the materialized evolution target, not the source's temporary header.
	ld a,[wEvoNewSpecies]
	ld d,a
	ld a,[wLoadedMonCatchRate]
	ld e,a
	jp RegionalDexMarkStoredMonOwned

; NPC/link trade: only the RECEIVED instance, after successful insertion.
; Both trade paths already latch its marker before removing the outgoing mon.
RegionalDexMarkReceivedTradeOwned::
	ld a,[wTradedEnemyMonSpecies]
	ld d,a
	ld a,[wTradedEnemyMonFormMarker]
	ld e,a
	jp RegionalDexMarkStoredMonOwned

RegionalDexFindSlot::
	ld hl,RegionalDexSlots
	ld c,0
.loop
	ld a,[hli]
	cp d
	jr nz,.next
	ld a,[hl]
	cp e
	jr z,.found
.next
	inc hl
	inc c
	ld a,c
	cp REGIONAL_DEX_SLOT_COUNT
	jr nz,.loop
	and a
	ret
.found
	scf
	ret

; Read or set independent Seen. Return A = 0 when unset/unregistered,
; nonzero when set; Z reflects the returned state.
RegionalDexSeenTest::
	ld b,FLAG_TEST
	jr RegionalDexSeenAction
RegionalDexSeenSet::
	ld b,FLAG_SET
RegionalDexSeenAction:
	call RegionalDexFindSlot
	jr nc,.missing
.slot:
	ld a,c
	cp 80
	jr c,.first80
	sub 80
	ld c,a
	ld hl,wRegionalDexSeenExtra ; 80..127: 6 bytes at $D7A4
	jr RegionalDexRunFlag
.first80
	ld hl,wRegionalDexSeen ; 0..79: original 10 bytes
	jr RegionalDexRunFlag
.missing
	xor a
	ret

; Owned implies Seen. The fixed-address storage is 8 + 6 + 2 bytes.
; 0..63 remain in the original block; 64..111 use the expanded tail;
; 112..127 live after the Seen extension. All 0..79 bit IDs are unchanged.
RegionalDexOwnedTest::
	ld b,FLAG_TEST
	jr RegionalDexOwnedAction
RegionalDexOwnedSet::
	push de
	call RegionalDexSeenSet
	pop de
	ld b,FLAG_SET
RegionalDexOwnedAction:
	call RegionalDexFindSlot
	jr nc,.missing
.slot:
	ld a,c
	cp 112
	jr nc,.last16
	cp 64
	jr c,.first64
	sub 64
	ld c,a
	ld hl,wRegionalDexOwnedTail ; 64..111, 6 saved bytes
	jr RegionalDexRunFlag
.last16
	sub 112
	ld c,a
	ld hl,wRegionalDexOwnedLast ; 112..127, 2 saved bytes
	jr RegionalDexRunFlag
.first64
	ld hl,wRegionalDexOwned ; 0..63, original 8 bytes
	jr RegionalDexRunFlag
.missing
	xor a
	ret

RegionalDexRunFlag:
	predef FlagActionPredef
	ld a,c ; FlagAction returns its result in C, not in A.
	and a
	ret

; DEX-5.62.118: read a known persistent slot without searching the identity
; table again. C is the immutable slot number; only the list scanner calls this.
RegionalDexOwnedTestSlot:
	ld b,FLAG_TEST
	jr RegionalDexOwnedAction.slot

; Pokédex list marker state: 0 = no form Owned, 1 = some but not all,
; 2 = complete. Species not present in RegionalDexSlots retain the original
; shared-species Owned bit. The table is scanned by actual registered entries,
; never by capacity, so multiple regional forms and later appended IDs work.
RegionalDexPokedexListBallState:
	ld a,[wd11e]
	push af
	callba PokedexToIndex
	ld a,[wd11e]
	ld d,a
	pop af
	ld [wd11e],a
	ld hl,RegionalDexSlots
	ld c,0
	ld e,0 ; bit 0 matched, bit 1 any Owned, bit 2 any missing
.scan
	ld a,[hli]
	cp d
	jr nz,.next
	set 0,e
	push hl
	push bc
	push de
	call RegionalDexOwnedTestSlot
	pop de
	pop bc
	pop hl
	and a
	jr z,.unowned
	set 1,e
	jr .next
.unowned
	set 2,e
.next
	inc hl
	inc c
	ld a,c
	cp REGIONAL_DEX_SLOT_COUNT
	jr nz,.scan
	bit 0,e
	jr nz,.registered
	; Ordinary species: test the original dex-number bit directly.
	; callba would overwrite HL, which IsPokemonBitSet expects as data.
	ld a,[wd11e]
	dec a
	ld c,a
	ld b,FLAG_TEST
	ld hl,wPokedexOwned
	predef FlagActionPredef
	ld a,c
	and a
	jr z,.none
	jr .complete
.registered
	bit 1,e
	jr z,.none
	bit 2,e
	jr z,.complete
	ld a,1
	ret
.complete
	ld a,2
	ret
.none
	xor a
	ret

; Input DE = wTileMap address of this row's Poké Ball. This is the only
; position whose palette is changed; the tile remains the stock $72.
; A new attribute is written on every redraw, including empty/complete rows,
; so list scrolling and returns from Info cannot retain a stale gray marker.
RegionalDexDrawPokedexListBall::
	push de
	call RegionalDexPokedexListBallState
	pop de
	push af
	ld h,d
	ld l,e
	and a
	ld a," "
	jr z,.writeTile
	ld a,$72
.writeTile
	ld [hl],a
	pop af
	cp 1
	ld b,1 ; PAL_REDBAR in both Red++ and Blue++ generic menus
	jr nz,.writePalette
	inc b ; neutral palette 2 for partial form ownership
.writePalette
	ld hl,W2_TilesetPaletteMap - wTileMap
	add hl,de
	; Never push/call while WRAM bank 2 is selected: the stack is banked.
	ld a,[rSVBK]
	ld c,a
	ld a,2
	ld [rSVBK],a
	ld a,b
	ld [hl],a
	ld a,3
	ld [W2_StaticPaletteMapChanged],a
	ld a,c
	ld [rSVBK],a
	ret

; Palette 2 is local to Pokédex list sessions. Do not alter PAL_REDBAR or
; shared tile graphics: MoveDex and all other generic menus keep their colors.
RegionalDexLoadPartialBallPalette::
	ld a,[rSVBK]
	ld b,a
	ld a,2
	ld [rSVBK],a
	ld hl,.neutralGray
	ld de,W2_BgPaletteData + 2 * 8
	ld c,8
.copy
	ld a,[hli]
	ld [de],a
	inc de
	dec c
	jr nz,.copy
	ld a,1
	ld [W2_ForceBGPUpdate],a
	ld a,b
	ld [rSVBK],a
	ret
.neutralGray
	RGB 31,31,31
	RGB 23,23,23
	RGB 12,12,12
	RGB 0,0,0

; Successful ball capture: preserve stock 208-species Pokédex Owned counting,
; but decide the automatic one-shot by the pre-capture Species+Form Owned bit.
; The capture-only reload saved 0=first Owned / 1=already Owned in the view
; scratch; clear it before showing the one-shot, which initializes its own form.
; Z = new form (show); NZ = previously Owned (skip). The external Info page
; already chooses wEnemyMonForm from the reloaded ORIGINAL caught Pokémon.
RegionalDexFinalizeCapturedPokedexOwned::
	ld a,[wEnemyMonSpecies]
	ld [wd11e],a
	predef IndexToPokedex
	ld a,[wd11e]
	dec a
	ld c,a
	ld b,FLAG_SET
	ld hl,wPokedexOwned
	predef FlagActionPredef
	ld a,[wPokedexViewForm]
	push af
	xor a
	ld [wPokedexViewForm],a
	pop af
	and a
	ret
