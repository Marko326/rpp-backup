; Pokédex Info browsing helpers.
; This file is included from bank $34 so the capacity-constrained ROM0 and
; bank $10 sections do not grow. Far-call inputs use DE because Bankswitch
; overwrites A/BC/HL before entering the target routine.

; Input: D = final Pokédex number, E = preferred visible row (0..6).
; Keep the current Pokémon on the same row when possible, clamping only near
; the beginning/end of the list so no rows extend beyond wDexMaxSeenMon.
PokedexData_SelectCurrentListEntry:
	ld a,d
	ld [wd11e],a
	dec a
	ld c,a ; zero-based absolute list index
	ld a,[wDexMaxSeenMon]
	cp 7
	jr c,.firstPage
	sub 7
	ld d,a ; maximum legal scroll offset
	ld a,c
	sub e
	jr nc,.havePreferredOffset
	xor a
.havePreferredOffset
	cp d
	jr c,.storeOffset
	ld a,d
.storeOffset
	ld [wListScrollOffset],a
	ld d,a
	ld a,c
	sub d
	ld [wCurrentMenuItem],a
	ld [wLastMenuItem],a
	ret
.firstPage
	xor a
	ld [wListScrollOffset],a
	ld a,c
	ld [wCurrentMenuItem],a
	ld [wLastMenuItem],a
	ret

PokedexData_BeginSessionVolume:
	; Every Info session starts on the normal form. START/SELECT only changes this
	; transient view byte after the stock first render has completed.
	xor a
	ld [wPokedexViewForm],a
	; Info owns its description-arrow animation. Start from an inactive state so a
	; blinking arrow left by the Pokédex list cannot leak into a Seen-only entry.
	ld [hDownArrowBlinkActive],a
	; UpdateSound writes Volume back to NR50 every audio tick. Store the reduced
	; value in Volume itself so it persists for the whole Info session. Music Off
	; and BGM Volume 0 stay untouched to avoid changing silent routed DACs.
	ld a,[wOptions]
	bit 5,a
	ret nz
	ld a,[wBGMVolume]
	cp $a0
	ret z
	ld a,$33
	ld [Volume],a
	ret

PokedexData_EndSession:
	xor a
	ld [hDownArrowBlinkActive],a
	call GBPalWhiteOut
	; Internal Info swaps between the two Window BG maps so a prepared text page can
	; appear atomically. Restore the project's normal map 1 ownership while the
	; screen is white before rebuilding the caller's menu.
	call DelayFrame
	callba WaitForVBlank
	ld a,[rLCDC]
	set 6,a
	ld [rLCDC],a
	xor a
	ld [H_AUTOBGTRANSFERDEST],a
	ld a,vBGMap1 / $100
	ld [H_AUTOBGTRANSFERDEST + 1],a
	ld a,1
	ld [H_AUTOBGTRANSFERENABLED],a
	call ClearScreen
	call RunDefaultPaletteCommand
	call LoadTextBoxTilePatterns
	call GBPalNormal
	ld hl,wd72c
	res 1,[hl]
	ld a,[wOptions]
	bit 5,a
	ret nz
	ld a,[wBGMVolume]
	cp $a0 ; BGM Volume 0 keeps the silent master-volume state
	ret z
	ld a,$77 ; restore the audio engine's normal master volume
	ld [Volume],a
	ret

PokedexData_WaitForVerticalRelease:
	call DelayFrame
	call PokedexData_TickDescriptionArrow
	call Joypad
	ld a,[hJoyHeld]
	and D_UP | D_DOWN
	jr nz,PokedexData_WaitForVerticalRelease
	ret

; Poll one internal Info input. SUMMARY26 only enters the stock down-arrow timing
; loop after Char49 has explicitly produced a valid description-page arrow. Keep
; the same ownership model here: a stale ▼ tile can never start blinking by itself.
; E survives the callba trampoline, so return the fresh button state there.
PokedexData_ReadInternalInput:
	; Match WaitForTextScrollButtonPress: advance the arrow before polling input.
	call PokedexData_TickDescriptionArrow
	ldh a,[hJoyHeld]
	and D_UP | D_DOWN
	jr z,.poll
	call PokedexData_WaitForVerticalRelease
	jr .haveInput
.poll
	call JoypadLowSensitivity
.haveInput
	ldh a,[hJoyPressed]
	ld e,a
	ret

; Run the complete internal Info category/subpage loop in roomy bank $34. The
; bank-$10 caller only distinguishes external state 0 from internal nonzero, so
; the local state consumes no WRAM. State 1/2 are Details subpages; states 3/4
; are Base Stats / evolution-change subpages. B exits, A stays inside the current
; category, LEFT/RIGHT switches category, and UP/DOWN changes species.
PokedexData_RunInternalInputLoop:
	ld a,1
	push af
.loop
	; This helper returns hJoyPressed, so only a fresh press reaches this loop.
	; Holding LEFT/RIGHT cannot repeatedly bounce between categories.
	call PokedexData_ReadInternalInput
	ld a,e
	ld b,a
	and B_BUTTON
	jp nz,.exit

	; START/SELECT are form navigation only for species that actually have at
	; least one registered regional descriptor. Species with no regional forms
	; receive carry clear from the generic lookup and these buttons do nothing.
	ld a,b
	and START
	jr nz,.nextForm
	ld a,b
	and SELECT
	jr nz,.previousForm

	ld a,b
	and A_BUTTON
	jr nz,.advanceSubpage

	ld a,b
	and D_LEFT | D_RIGHT
	jp nz,.switchCategory

	ld a,b
	and D_UP | D_DOWN
	jp z,.loop
	ld e,a
	call PokedexData_TryStepSeen
	jp nc,.loop
	; A different species always starts from its normal form. This prevents a form
	; selected on one Pokédex entry from leaking into the next species.
	xor a
	ld [wPokedexViewForm],a
	; Species changes preserve the category but return to that category's home.
	; Details 1/2 normalize to state 1; Base Stats 3/4 normalize to state 3.
	; Seen-only targets keep the category remembered while rendering the limited page.
	pop af
	cp 3
	jr c,.browseDetails
	ld a,3
	jr .keepBrowseCategory
.browseDetails
	ld a,1
.keepBrowseCategory
	push af
	ld e,a
	call PokedexData_RenderSwitchedEntry
	jp .loop

.nextForm
	ld a,[wcf91]
	ld d,a
	ld a,[wPokedexViewForm]
	ld e,a
	call RegionalFormGetNextPokedexForm
	jp nc,.loop
	ld [wPokedexViewForm],a
	jr .redrawForm

.previousForm
	ld a,[wcf91]
	ld d,a
	ld a,[wPokedexViewForm]
	ld e,a
	call RegionalFormGetPreviousPokedexForm
	jp nc,.loop
	ld [wPokedexViewForm],a

.redrawForm
	; Keep the selected category, but normalize to that category's home page just
	; like an UP/DOWN species change.
	pop af
	cp 3
	jr c,.formDetails
	ld a,3
	jr .formStateReady
.formDetails
	ld a,1
.formStateReady
	push af
	ld e,a
	call PokedexData_RenderSwitchedEntry
	jp .loop

.advanceSubpage
	; A only moves inside the current category. Details toggles 1 <-> 2. Base Stats
	; toggles 3 <-> 4, but a basic-stage Pokémon has no evolution delta to display.
	call PokedexData_CurrentMonOwned
	jp z,.loop
	pop af
	cp 3
	jr z,.showBaseStatsDelta
	cp 4
	jr z,.showBaseStatsHome
	cp 1
	jr z,.showDescription2
	; State 2 -> Details home (description Page 1).
	ld a,1
	push af
	ld e,0
	call PokedexData_DrawDescriptionPage
	jp .loop
.showBaseStatsDelta
	call PokedexData_GetPreEvolution
	and a
	jr z,.keepBaseStats
	ld a,4
	push af
	call PokedexData_DrawBaseStatsDeltaPage
	jp .loop
.keepBaseStats
	ld a,3
	push af
	jp .loop
.showBaseStatsHome
	ld a,3
	push af
	call PokedexData_DrawBaseStatsPage
	jp .loop
.showDescription2
	ld a,2
	push af
	ld e,1
	call PokedexData_DrawDescriptionPage
	jp .loop

.switchCategory
	; With two categories, LEFT and RIGHT both select the other category. Crossing
	; a category boundary always lands on that category's home page.
	call PokedexData_CurrentMonOwned
	jp z,.loop
	pop af
	cp 3
	jr nc,.showDescription1
	ld a,3
	push af
	call PokedexData_DrawBaseStatsPage
	jp .loop
.showDescription1
	ld a,1
	push af
	ld e,0
	call PokedexData_DrawDescriptionPage
	jp .loop

.exit
	pop af
	ret

PokedexData_TickDescriptionArrow:
	; $FF8B/$FF8C are shared scratch HRAM. Rendering code must reset Active after its
	; last scratch user, and only an Owned Page 1 may arm it before entering this loop.
	; Once input begins, the same narrow ownership window as SUMMARY26 is safe.
	ld a,[hDownArrowBlinkActive]
	and a
	ret z
	coord hl,18,16
	jp HandleDownArrowBlinkTiming

PokedexData_ArmDescriptionArrow:
	; SUMMARY26 initializes the visible ▼ with the shared 42-frame interval and marks
	; the current VBlank as already processed, so the first decrement starts on the
	; next displayed frame. Reproduce that timing exactly for internal Info.
	ld a,1
	ld [hDownArrowBlinkActive],a
	ld [hDownArrowBlinkFrameProcessed],a
	ld a,DOWN_ARROW_BLINK_INTERVAL_FRAMES
	ld [hDownArrowBlinkTimer],a
	ret

; Refresh only the Pokédex fields that belong to the selected Pokémon. The frame,
; divider, fixed labels and session state stay visible. Palette 0 is temporarily
; made white so the frontpic alone disappears in one palette commit. The complete
; new text page is transferred to the hidden Window BG map and exposed with one
; LCDC map flip, then the final Pokémon palette reveals the complete new picture.
; Input: wd11e = newly selected internal species, E = desired internal page state
; (1 = description page 1, 3 = Base Stats home). Seen-only entries keep the category
; but render the stock limited page because detailed data is Owned-only.
PokedexData_RenderSwitchedEntry:
	ld a,e
	ld [wBuffer + 18],a ; preserve page state across the refresh helpers
	; Stop the previous page's ▼ phase while a new entry is prepared. Owned Page 1
	; will re-arm it after the coherent page has been committed; Seen-only stays off.
	xor a
	ld [hDownArrowBlinkActive],a
	; Hide only the frontpic through palette 0. Keeping its 7x7 tilemap references
	; intact avoids the two AutoBG thirds that otherwise reveal the new picture in
	; separate frames. Wait until the white palette is really resident in hardware
	; before any vFrontPic tile is replaced.
	call PokedexData_HideFrontPicPalette0
	callba StatusScreen_WaitForBgPaletteCommit
	xor a
	ld [H_AUTOBGTRANSFERENABLED],a

	ld a,[wd11e]
	ld [wcf91],a
	ld [wd0b5],a
	push af
	ld b,SET_PAL_POKEDEX
	call RunPaletteCommand
	pop af
	ld [wd11e],a
	ld a,[wcf91]
	ld d,a
	ld a,[wPokedexViewForm]
	ld e,a
	call RegionalFormOverridePokedexPalette

	; Name and species are the only variable strings above the divider. Clear their
	; exact 10-column fields in WRAM so shorter replacements cannot leave old glyphs.
	coord hl,9,2
	lb bc,1,10
	call ClearScreenArea
	coord hl,9,4
	lb bc,1,10
	call ClearScreenArea

	ld a,[wcf91]
	ld [wd11e],a
	call GetMonName
	coord hl,9,2
	call PlaceString

	call PokedexData_GetCategoryPointer
	push af
	ld d,h
	ld e,l
	coord hl,9,4
	pop af
	call MoveDexPlaceStringFar

	; The No. label itself is fixed; only replace its three digits.
	ld a,[wcf91]
	ld [wd11e],a
	predef IndexToPokedex
	coord hl,4,8
	ld de,wd11e
	lb bc,LEADING_ZEROES | 1,3
	call PrintNumber
	ld a,[wcf91]
	ld [wd11e],a

	; Always restore the stock Ht/Wt placeholders first. This also erases data when
	; moving from an Owned entry to a Seen-but-not-Owned one.
	coord hl,9,6
	ld de,HeightWeightText
	ld a,BANK(HeightWeightText)
	call MoveDexPlaceStringFar

	call PokedexData_CurrentMonOwned
	jr z,.notOwned

	; Load stock feet/inches/weight, then selectively apply numeric regional
	; overrides. Equal fields inherit the Species entry and cost no extra record.
	call PokedexData_CopyHeightWeightFields

	ld de,wBuffer + 14
	coord hl,12,6
	lb bc,1,2
	call PrintNumber
	ld a,$60
	ld [hl],a
	ld de,wBuffer + 15
	coord hl,15,6
	lb bc,LEADING_ZEROES | 1,2
	call PrintNumber
	ld a,$61
	ld [hl],a

	; PrintNumber expects big-endian input. Reverse the stored little-endian weight
	; into unused low scratch bytes instead of borrowing hDexWeight.
	ld a,[wBuffer + 17]
	ld [wBuffer + 12],a
	ld a,[wBuffer + 16]
	ld [wBuffer + 13],a
	ld de,wBuffer + 12
	coord hl,11,8
	lb bc,2,5
	call PrintNumber
	coord hl,14,8
	ld a,[wBuffer + 13]
	sub 10
	ld a,[wBuffer + 12]
	sbc 0
	jr nc,.weightAtLeastTen
	ld [hl],"0"
.weightAtLeastTen
	inc hl
	ld a,[hli]
	ld [hld],a
	ld [hl],"⠄"

	ld a,[wBuffer + 18]
	cp 3
	jr nc,.renderBaseStats
	ld e,0
	call PokedexData_DrawDescriptionPageNoWait
	; SUMMARY26 does not show the page arrow until after the picture/cry path has
	; completed. Keep the prepared Page 1 text, but expose the ▼ separately later.
	coord hl,18,16
	ld [hl]," "
	jr .commitText

.renderBaseStats
	call PokedexData_DrawBaseStatsPageNoWait
	jr .commitText

.notOwned
	; Seen-only entries must erase an Owned predecessor's description completely.
	coord hl,1,10
	lb bc,7,18
	call ClearScreenArea

.commitText
	; Transfer the completely prepared page to the currently hidden Window BG map,
	; then flip maps in VBlank. This makes name/number/Ht/Wt and all description lines
	; change on the same displayed frame instead of leaking AutoBG's three thirds.
	call PokedexData_CommitPreparedInfoPage

	; Hide palette 0 while the stock loader copies its 49 graphics tiles over seven
	; VBlanks. Its final tilemap write is the same 0..48 layout already resident on
	; screen, so AutoBG can stay disabled and no partial picture is ever exposed.
	xor a
	ld [H_AUTOBGTRANSFERENABLED],a
	ld a,[wcf91]
	ld d,a
	ld a,[wPokedexViewForm]
	ld e,a
	call RegionalFormLoadPokedexHeader
	coord hl,1,1
	call LoadFlippedFrontSpriteByMonIndex

	; SetPal_Pokedex prepared the new source palette before the graphics upload.
	; Commit it only now: changing palette 0 from all-white to the new Pokémon's
	; colors reveals the fully resident frontpic in one hardware palette update.
	call PokedexData_ForceBgPaletteUpdate
	callba StatusScreen_WaitForBgPaletteCommit
	ld a,1
	ld [H_AUTOBGTRANSFERENABLED],a
	ld a,[wcf91]
	call PlayCry

	; LoadFlippedFrontSpriteByMonIndex uses H_SPRITEWIDTH/H_SPRITEHEIGHT, which are
	; the same physical $FF8B/$FF8C bytes as the stock arrow Active/Timer. Discard
	; those scratch values now, after the last renderer that can overwrite them.
	xor a
	ld [hDownArrowBlinkActive],a

	; The original SUMMARY26 path reaches Char49 only for an Owned description. Its
	; ▼ is transferred by ProtectedDelay3 before the 42-frame timer is armed. Base
	; Stats has no description arrow, and Seen-only entries never expose Page 1 text.
	ld a,[wBuffer + 18]
	cp 1
	ret nz
	call PokedexData_CurrentMonOwned
	ret z
	ld a,"▼"
	Coorda 18,16
	call ProtectedDelay3
	jp PokedexData_ArmDescriptionArrow

PokedexData_CommitPreparedInfoPage:
	; Pick the Window BG map that is not currently visible. StatusScreen's proven
	; prepared-map helper performs the three hidden transfers plus the palette-map
	; producer/consumer wait, so no third of the new text becomes visible early.
	ld a,[rLCDC]
	bit 6,a
	jr z,.visibleMap0
	; map 1 visible -> prepare map 0
	xor a
	ld [H_AUTOBGTRANSFERDEST],a
	ld a,vBGMap0 / $100
	ld [H_AUTOBGTRANSFERDEST + 1],a
	jr .transfer
.visibleMap0
	xor a
	ld [H_AUTOBGTRANSFERDEST],a
	ld a,vBGMap1 / $100
	ld [H_AUTOBGTRANSFERDEST + 1],a
.transfer
	callba StatusScreen_TransferPreparedMap

	; The hidden map now contains one coherent page. Flip only during VBlank, then
	; point future AutoBG updates (including the blinking ▼) at the new visible map.
	callba WaitForVBlank
	ld a,[rLCDC]
	xor %01000000
	ld [rLCDC],a
	bit 6,a
	jr z,.nowMap0
	xor a
	ld [H_AUTOBGTRANSFERDEST],a
	ld a,vBGMap1 / $100
	ld [H_AUTOBGTRANSFERDEST + 1],a
	ret
.nowMap0
	xor a
	ld [H_AUTOBGTRANSFERDEST],a
	ld a,vBGMap0 / $100
	ld [H_AUTOBGTRANSFERDEST + 1],a
	ret

PokedexData_HideFrontPicPalette0:
	; The Pokédex attribute map assigns palette 0 only to the 7x7 picture area (plus
	; one blank column). Make all four colors white without touching palette 1, so
	; the frame and text stay visible while the picture graphics are replaced.
	ld a,[rSVBK]
	ld b,a
	ld a,2
	ld [rSVBK],a
	ld hl,W2_BgPaletteData
	ld c,4
.loop
	ld a,$ff
	ld [hli],a
	ld a,$7f
	ld [hli],a
	dec c
	jr nz,.loop
	ld a,1
	ld [W2_ForceBGPUpdate],a
	ld a,b
	ld [rSVBK],a
	ret

PokedexData_ForceBgPaletteUpdate:
	ld a,[rSVBK]
	ld b,a
	ld a,2
	ld [rSVBK],a
	ld a,1
	ld [W2_ForceBGPUpdate],a
	ld a,b
	ld [rSVBK],a
	ret

; Return Z when the current Pokédex entry is Seen but not Owned, matching the
; original detail-screen rule that hides height/weight/description until caught.
PokedexData_CurrentMonOwned:
	ld a,[wcf91]
	ld [wd11e],a
	predef IndexToPokedex
	ld hl,wPokedexOwned
	call PokedexData_TestPokemonBit
	push af
	ld a,[wcf91]
	ld [wd11e],a
	pop af
	and a
	ret

; Input: E = 0 for the first description half, 1 for the second.
; The text is rendered directly from its far-ROM bytes into wTileMap. This keeps
; the global ROM0 text engine untouched: `next`, `page` and `dex` are consumed
; here instead of teaching Char49 a Pokédex-only behavior.
PokedexData_DrawDescriptionPage:
	; Prepare the next description page only in WRAM. If AutoBG stays enabled here, a
	; VBlank can expose one unfinished third of wTileMap before the hidden-map flip.
	xor a
	ld [H_AUTOBGTRANSFERENABLED],a
	call PokedexData_DrawDescriptionPageNoWait
	call PokedexData_CommitPreparedInfoPage
	ld a,1
	ld [H_AUTOBGTRANSFERENABLED],a
	; Page 1 is the only custom description page that leaves a visible ▼ in wTileMap.
	; Arm it explicitly after the coherent page is on screen; Page 2 remains disabled.
	coord hl,18,16
	ld a,[hl]
	cp "▼"
	ret nz
	jp PokedexData_ArmDescriptionArrow

PokedexData_DrawDescriptionPageNoWait:
	; Changing description pages always disables the previous arrow first. Page 1
	; may draw a new ▼ below; the public wrapper explicitly arms its timer only after
	; the complete hidden BG page has been committed. Seen-only never enters here.
	xor a
	ld [hDownArrowBlinkActive],a
	ld a,e
	ld [wBuffer + 20],a
	coord hl,1,10
	lb bc,7,18
	call ClearScreenArea

	call PokedexData_GetDescriptionPointer
	jp nc,.finish
	ld [wBuffer + 29],a ; description ROM bank
	inc hl ; skip the leading `text` command byte

	ld a,[wBuffer + 20]
	and a
	jr z,.beginRender
.skipFirstHalf
	call PokedexData_ReadDescriptionLine
	jp nc,.finish
	cp $49 ; `page`
	jr z,.beginRender
	cp $5f ; `dex`: malformed/no second half
	jp z,.finish
	jr .skipFirstHalf

.beginRender
	coord de,1,11
	ld a,e
	ld [wBuffer + 22],a
	ld a,d
	ld [wBuffer + 23],a
.renderLine
	call PokedexData_ReadDescriptionLine
	jr nc,.finish
	ld [wBuffer + 21],a ; terminating command for this line
	push hl ; next far-ROM line pointer

	ld a,c
	and a
	jr z,.lineCopied
	; Terminate the buffered source line and let the normal PlaceString decoder
	; expand dictionary tokens such as # -> "Poké". The command byte itself was
	; not copied, so `next`/`page`/`dex` remain owned by this page renderer.
	ld b,0
	ld hl,wBuffer
	add hl,bc
	ld [hl],"@"
	ld de,wBuffer
	ld a,[wBuffer + 22]
	ld l,a
	ld a,[wBuffer + 23]
	ld h,a
	call PlaceString
	; Original Char5F writes the final period when `dex` ends an entry. Recreate
	; that one visible side effect after PlaceString returns BC = output endpoint.
	ld a,[wBuffer + 21]
	cp $5f
	jr nz,.lineCopied
	ld a,"."
	ld [bc],a
.lineCopied
	pop hl
	ld a,[wBuffer + 21]
	cp $4e ; `next`
	jr nz,.endPage
	; Pokédex description lines are intentionally double-spaced: the original
	; PlaceString `next` command advances by 2 * SCREEN_WIDTH, not one row.
	ld a,[wBuffer + 22]
	add 2 * SCREEN_WIDTH
	ld [wBuffer + 22],a
	jr nc,.renderLine
	ld a,[wBuffer + 23]
	inc a
	ld [wBuffer + 23],a
	jr .renderLine

.endPage
	cp $49 ; first half ended at `page`
	jr nz,.finish
	ld a,[wBuffer + 20]
	and a
	jr nz,.finish
	ld a,"▼"
	Coorda 18,16
.finish
	ret

; Input: A = internal species ID. Load the header for the Pokédex's currently
; selected form. If that species does not implement the same form ID (for example
; a predecessor without a regional counterpart), the regional helper safely leaves
; the normal header resident.
PokedexData_LoadViewHeaderForSpecies:
	ld d,a
	ld a,[wPokedexViewForm]
	ld e,a
	jp RegionalFormLoadPokedexHeader

; Render the Base Stats category home. It deliberately reuses the same lower 18x7
; content area as the two description halves, so the existing hidden-BG commit path
; keeps A-page changes flicker-free. This page is only reachable for Owned Pokémon;
; callers keep Seen-only entries on the limited stock display.
PokedexData_DrawBaseStatsPage:
	xor a
	ld [H_AUTOBGTRANSFERENABLED],a
	call PokedexData_DrawBaseStatsPageNoWait
	call PokedexData_CommitPreparedInfoPage
	ld a,1
	ld [H_AUTOBGTRANSFERENABLED],a
	ret

PokedexData_DrawBaseStatsPageNoWait:
	; Base Stats never owns the blinking description arrow.
	xor a
	ld [hDownArrowBlinkActive],a
	coord hl,1,10
	lb bc,7,18
	call ClearScreenArea

	; Refresh the current base-stat header explicitly so this renderer is independent
	; of which picture/text helper happened to run immediately before it.
	ld a,[wcf91]
	call PokedexData_LoadViewHeaderForSpecies

	; Keep PureRGB's compact layout: types on the left, five base stats plus total
	; on the right. Do not call stock PrintMonType here: it calls GetMonHeader and
	; would replace the selected regional header with the normal Species header.
	call PokedexData_DrawViewTypes

	coord hl,9,10
	ld de,PokedexBaseStatsTitle
	call PlaceString
	coord hl,12,11
	ld de,PokedexBaseStatsHPText
	call PlaceString
	ld de,wMonHBaseHP
	coord hl,15,11
	lb bc,1,3
	call PrintNumber
	coord hl,11,12
	ld de,PokedexBaseStatsATKText
	call PlaceString
	ld de,wMonHBaseAttack
	coord hl,15,12
	lb bc,1,3
	call PrintNumber
	coord hl,11,13
	ld de,PokedexBaseStatsDEFText
	call PlaceString
	ld de,wMonHBaseDefense
	coord hl,15,13
	lb bc,1,3
	call PrintNumber
	coord hl,11,14
	ld de,PokedexBaseStatsSPDText
	call PlaceString
	ld de,wMonHBaseSpeed
	coord hl,15,14
	lb bc,1,3
	call PrintNumber
	coord hl,11,15
	ld de,PokedexBaseStatsSPCText
	call PlaceString
	ld de,wMonHBaseSpecial
	coord hl,15,15
	lb bc,1,3
	call PrintNumber

	; The five one-byte stats can total more than 255, so accumulate in HL and feed
	; PrintNumber a temporary big-endian two-byte value. wBuffer+12/+13 are free once
	; the height/weight refresh has completed and do not overlap the saved page state.
	ld b,0
	ld hl,0
	ld a,[wMonHBaseHP]
	ld c,a
	add hl,bc
	ld a,[wMonHBaseAttack]
	ld c,a
	add hl,bc
	ld a,[wMonHBaseDefense]
	ld c,a
	add hl,bc
	ld a,[wMonHBaseSpeed]
	ld c,a
	add hl,bc
	ld a,[wMonHBaseSpecial]
	ld c,a
	add hl,bc
	ld a,h
	ld [wBuffer + 12],a
	ld a,l
	ld [wBuffer + 13],a
	coord hl,9,16
	ld de,PokedexBaseStatsTotalText
	call PlaceString
	ld de,wBuffer + 12
	coord hl,15,16
	lb bc,2,3
	call PrintNumber
	ret

; Draw the two type rows from the already resolved wMonHeader without calling
; stock PrintMonType. The stock predef reloads the normal Species header, which was
; the reason regional Base Stats pages appeared to keep normal-form values.
PokedexData_DrawViewTypes:
	coord hl,1,11
	ld de,PokedexBaseStatsType1Text
	call PlaceString
	coord hl,1,13
	ld de,PokedexBaseStatsType2Text
	call PlaceString

	coord de,2,12
	ld a,[wMonHType1]
	ld [wRegionalFormPrintTypeArgument],a
	callba PrintTypeAtDE

	ld a,[wMonHType1]
	ld b,a
	ld a,[wMonHType2]
	cp b
	jr z,.singleType
	coord de,2,14
	ld [wRegionalFormPrintTypeArgument],a
	jpba PrintTypeAtDE

.singleType
	; Remove the TYPE2 label/value for single-type forms. This area is isolated from
	; the stat column at x=9, so clearing eight columns is safe.
	coord hl,1,13
	lb bc,2,8
	jp ClearScreenArea

; Render the second Base Stats subpage. The five values show the signed change from
; the current Pokémon's direct pre-evolution. The predecessor relation is a compact
; bank-$34 reverse index generated from data/evos_moves.asm; no runtime scan or bank
; $0E parser is needed. Basic-stage Pokémon never enter this page.
PokedexData_DrawBaseStatsDeltaPage:
	xor a
	ld [H_AUTOBGTRANSFERENABLED],a
	call PokedexData_DrawBaseStatsDeltaPageNoWait
	call PokedexData_CommitPreparedInfoPage
	ld a,1
	ld [H_AUTOBGTRANSFERENABLED],a
	ret

PokedexData_DrawBaseStatsDeltaPageNoWait:
	; Base Stats subpages never own the blinking description arrow.
	xor a
	ld [hDownArrowBlinkActive],a
	coord hl,1,10
	lb bc,7,18
	call ClearScreenArea

	; Load the direct predecessor first and retain only its five one-byte base stats.
	; If this routine is ever called for a basic-stage Pokémon, fall back to the home
	; page rather than exposing an empty comparison screen.
	call PokedexData_GetPreEvolution
	and a
	jp z,PokedexData_DrawBaseStatsPageNoWait
	call PokedexData_LoadViewHeaderForSpecies
	ld hl,wMonHBaseStats
	ld de,wBuffer + 12
	ld bc,5
	call CopyData

	; Preserve the predecessor total before GetMonHeader replaces wMonHeader with the
	; current Pokémon. Store it big-endian for the signed TOTAL subtraction below.
	ld hl,wMonHBaseStats
	call PokedexData_SumFiveBaseStats
	ld a,d
	ld [wBuffer + 17],a
	ld a,e
	ld [wBuffer + 18],a

	; Finish with the current header resident in wMonHeader so type printing and any
	; later caller observe the same species as on the normal Base Stats page.
	ld a,[wcf91]
	call PokedexData_LoadViewHeaderForSpecies

	call PokedexData_DrawViewTypes

	coord hl,9,10
	ld de,PokedexBaseStatsTitle
	call PlaceString
	coord hl,12,11
	ld de,PokedexBaseStatsHPText
	call PlaceString
	ld a,[wBuffer + 12]
	ld b,a
	ld a,[wMonHBaseHP]
	coord hl,15,11
	call PokedexData_PrintBaseStatDelta

	coord hl,11,12
	ld de,PokedexBaseStatsATKText
	call PlaceString
	ld a,[wBuffer + 13]
	ld b,a
	ld a,[wMonHBaseAttack]
	coord hl,15,12
	call PokedexData_PrintBaseStatDelta

	coord hl,11,13
	ld de,PokedexBaseStatsDEFText
	call PlaceString
	ld a,[wBuffer + 14]
	ld b,a
	ld a,[wMonHBaseDefense]
	coord hl,15,13
	call PokedexData_PrintBaseStatDelta

	coord hl,11,14
	ld de,PokedexBaseStatsSPDText
	call PlaceString
	ld a,[wBuffer + 15]
	ld b,a
	ld a,[wMonHBaseSpeed]
	coord hl,15,14
	call PokedexData_PrintBaseStatDelta

	coord hl,11,15
	ld de,PokedexBaseStatsSPCText
	call PlaceString
	ld a,[wBuffer + 16]
	ld b,a
	ld a,[wMonHBaseSpecial]
	coord hl,15,15
	call PokedexData_PrintBaseStatDelta

	; TOTAL uses a signed 16-bit difference. Individual stats are one byte, but the
	; sum can exceed 255. Current project data fits the same three displayed digits.
	coord hl,9,16
	ld de,PokedexBaseStatsTotalText
	call PlaceString
	ld hl,wMonHBaseStats
	call PokedexData_SumFiveBaseStats ; DE = current total
	ld a,[wBuffer + 18]
	ld c,a
	ld a,e
	sub c
	ld e,a
	ld a,[wBuffer + 17]
	ld c,a
	ld a,d
	sbc c
	ld d,a
	coord hl,15,16
	jp PokedexData_PrintBaseStatTotalDelta

; Input: A = current one-byte stat, B = predecessor stat, HL = first digit tile.
; Output is one fixed sign column plus a right-aligned three-digit magnitude.
PokedexData_PrintBaseStatDelta:
	sub b
	jr nc,.nonnegative
	cpl
	inc a
	ld b,a
	ld a,"-"
	jr .placeSign
.nonnegative
	ld b,a
	and a
	ld a,"+"
	jr nz,.placeSign
	ld a," "
.placeSign
	dec hl
	ld [hli],a
	ld a,b
	ld [wBuffer + 28],a
	ld de,wBuffer + 28
	lb bc,1,3
	jp PrintNumber

; Input: HL = five consecutive one-byte base stats. Output: DE = 16-bit sum.
PokedexData_SumFiveBaseStats:
	ld de,0
	ld b,5
.loop
	ld a,[hli]
	add e
	ld e,a
	jr nc,.noCarry
	inc d
.noCarry
	dec b
	jr nz,.loop
	ret

; Input: DE = signed 16-bit total delta, HL = first digit tile.
PokedexData_PrintBaseStatTotalDelta:
	bit 7,d
	jr z,.nonnegative
	ld a,e
	cpl
	ld e,a
	ld a,d
	cpl
	ld d,a
	inc de
	ld a,"-"
	jr .placeSign
.nonnegative
	ld a,d
	or e
	ld a,"+"
	jr nz,.placeSign
	ld a," "
.placeSign
	dec hl
	ld [hli],a
	ld a,d
	ld [wBuffer + 26],a
	ld a,e
	ld [wBuffer + 27],a
	ld de,wBuffer + 26
	lb bc,2,3
	jp PrintNumber

; Return the current Pokémon's direct predecessor as an internal species ID.
; Zero means there is no predecessor and therefore no Base Stats delta subpage.
PokedexData_GetPreEvolution:
	ld a,[wcf91]
	and a
	ret z
	dec a
	ld e,a
	ld d,0
	ld hl,PokedexPreEvolutionTable
	add hl,de
	ld a,[hl]
	ret

PokedexBaseStatsTitle:
	db "BASE STATS@"
PokedexBaseStatsType1Text:
	db "TYPE1@"
PokedexBaseStatsType2Text:
	db "TYPE2@"
PokedexBaseStatsHPText:
	db "HP@"
PokedexBaseStatsATKText:
	db "ATK@"
PokedexBaseStatsDEFText:
	db "DEF@"
PokedexBaseStatsSPDText:
	db "SPD@"
PokedexBaseStatsSPCText:
	db "SPE@"
PokedexBaseStatsTotalText:
	db "TOTAL@"

; Resolve the current internal species (wcf91) to the bank-$10 entry pointer.
; Output: HL = entry start.
PokedexData_GetEntryPointer:
	ld a,[wcf91]
	dec a
	ld e,a
	ld d,0
	ld hl,PokedexEntryPointers
	add hl,de
	add hl,de
	ld de,wBuffer
	ld bc,2
	ld a,BANK(PokedexEntryPointers)
	call FarCopyData
	ld a,[wBuffer]
	ld l,a
	ld a,[wBuffer + 1]
	ld h,a
	ret

; Return the active regional form's optional height/weight metric record.
; Output: carry set, A = metrics bank, HL = metrics pointer.
PokedexData_GetRegionalDexMetricsPointer:
	ld a,[wcf91]
	ld d,a
	ld a,[wPokedexViewForm]
	ld e,a
	jp RegionalFormGetPokedexMetricsPointer

; Category/species text is intentionally shared across forms.
; Output: A = source bank, HL = category/species string.
PokedexData_GetCategoryPointer:
	call PokedexData_GetEntryPointer
	ld a,BANK(PokedexEntryPointers)
	ret

; Output: HL = first byte after the species-string terminator (feet).
PokedexData_GetEntryFieldsPointer:
	call PokedexData_GetEntryPointer
.findSpeciesEnd
	ld de,wBuffer + 28
	ld bc,1
	ld a,BANK(PokedexEntryPointers)
	call FarCopyData
	ld a,[wBuffer + 28]
	cp "@"
	jr nz,.findSpeciesEnd
	ret

; Fill wBuffer+14..17 with feet, inches and little-endian tenths-of-a-pound.
; Start from the stock Species entry. A metric record uses 0,0 height and/or
; weight 0 as "inherit", so identical values consume no duplicate data.
PokedexData_CopyHeightWeightFields:
	call PokedexData_GetEntryFieldsPointer
	ld de,wBuffer + 14
	ld bc,4
	ld a,BANK(PokedexEntryPointers)
	call FarCopyData

	call PokedexData_GetRegionalDexMetricsPointer
	ret nc
	ld de,wBuffer + 3
	ld bc,RF_DEX_SIZE
	call FarCopyData

	; Height overrides only when either feet or inches is nonzero.
	ld a,[wBuffer + 3]
	ld b,a
	ld a,[wBuffer + 4]
	or b
	jr z,.weight
	ld a,[wBuffer + 3]
	ld [wBuffer + 14],a
	ld a,[wBuffer + 4]
	ld [wBuffer + 15],a
.weight
	; Weight 0 means inherit.
	ld a,[wBuffer + 5]
	ld b,a
	ld a,[wBuffer + 6]
	or b
	ret z
	ld a,[wBuffer + 5]
	ld [wBuffer + 16],a
	ld a,[wBuffer + 6]
	ld [wBuffer + 17],a
	ret

; Long Pokédex descriptions are Species-level data and are deliberately shared
; across forms to avoid duplicating large, rarely viewed text blocks.
; Output: carry set, A = text bank, HL = far pointer to the leading `text` byte.
PokedexData_GetDescriptionPointer:
	call PokedexData_GetEntryFieldsPointer
	; HL is now just after the species terminator. Skip height (2), weight (2)
	; and the TX_FAR opcode, then read pointer low/high and bank.
	ld de,5
	add hl,de
	ld de,wBuffer
	ld bc,3
	ld a,BANK(PokedexEntryPointers)
	call FarCopyData
	ld a,[wBuffer]
	ld l,a
	ld a,[wBuffer + 1]
	ld h,a
	ld a,[wBuffer + 2]
	scf
	ret

; Read one encoded description line without crossing the source bank boundary.
; Input: HL = far source line, wBuffer+29 = source bank.
; Output: carry set, A = terminator (`next`/`page`/`dex`), C = character count,
;         HL = source immediately after the terminator, wBuffer = line bytes.
;         carry clear if no terminator is found within the 18-column line limit.
PokedexData_ReadDescriptionLine:
	push hl ; original line start
	xor a
	ld [wBuffer + 27],a ; character count
.scan
	ld de,wBuffer + 28
	ld bc,1
	ld a,[wBuffer + 29]
	call FarCopyData ; advances HL by one source byte
	ld a,[wBuffer + 28]
	cp $4e ; `next`
	jr z,.found
	cp $49 ; `page`
	jr z,.found
	cp $5f ; `dex`
	jr z,.found
	ld a,[wBuffer + 27]
	inc a
	ld [wBuffer + 27],a
	cp 19 ; source data is constrained to the 18-column Pokédex text area
	jr c,.scan
	pop de ; discard original line start
	and a
	ret
.found
	ld [wBuffer + 26],a
	ld a,l
	ld [wBuffer + 24],a
	ld a,h
	ld [wBuffer + 25],a
	pop hl ; restore original line start for an exact-length copy
	ld a,[wBuffer + 27]
	and a
	jr z,.restoreNext
	ld c,a
	ld b,0
	ld de,wBuffer
	ld a,[wBuffer + 29]
	call FarCopyData
.restoreNext
	ld a,[wBuffer + 24]
	ld l,a
	ld a,[wBuffer + 25]
	ld h,a
	ld a,[wBuffer + 27]
	ld c,a
	ld a,[wBuffer + 26]
	scf
	ret

; Input: E = fresh D_UP or D_DOWN press; wcf91 = current internal species.
; Output: carry set with wd11e changed to the previous/next Seen species;
; carry clear with the original internal species restored when no target exists.
; Navigation stops at the first/last Seen boundary and never wraps. Unseen
; entries between Seen Pokémon are still skipped in the selected direction.
PokedexData_TryStepSeen:
	ld a,e
	ld [wBuffer + 20],a
	; PlayCry uses wd11e as scratch, so wcf91 is the authoritative current species.
	ld a,[wcf91]
	ld [wd11e],a
	push af
	predef IndexToPokedex
.search
	ld a,[wBuffer + 20]
	bit BIT_D_UP,a
	jr z,.down
.up
	ld a,[wd11e]
	cp 1
	jr z,.noChange
	dec a
	jr .candidate
.down
	ld a,[wDexMaxSeenMon]
	ld c,a
	ld a,[wd11e]
	cp c
	jr nc,.noChange
	inc a
.candidate
	ld [wd11e],a
	ld hl,wPokedexSeen
	call PokedexData_TestPokemonBit
	jr z,.search
	callba PokedexToIndex
	pop af ; discard saved original internal index
	scf
	ret
.noChange
	pop af
	ld [wd11e],a
	and a
	ret

; Same bit-test primitive used by bank $10's IsPokemonBitSet, kept local so a
; far call never needs to pass HL/BC through Bankswitch (which overwrites them).
PokedexData_TestPokemonBit:
	ld a,[wd11e]
	dec a
	ld c,a
	ld b,FLAG_TEST
	predef FlagActionPredef
	ld a,c
	and a
	ret
