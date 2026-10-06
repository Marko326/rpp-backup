; FORM-5.62.20 explicit regional-form producers. This code is intentionally kept
; in a floating ROMX section so fixed bank $34 only owns descriptor/header logic.

RF_EVO_OVERRIDE_SIZE EQU 5

; D = species, E = runtime form. Stage one explicit-form insertion. The tested
; producer lifetime reuses the HP-bar phase byte only while no HP animation can run;
; bit 7 of wHPBarDamageSpeed is the validity flag, so stale phase data is ignored.
RegionalFormStageNewMonForm:
	callba RegionalFormGetMarkerBySpeciesForm
	jr nc,RegionalFormClearNewMonForm
	ld a,e
	ld [wRegionalFormNewMonMarker],a
	ld hl,wHPBarDamageSpeed
	set BIT_REGIONAL_FORM_NEW_MON_OVERRIDE,[hl]
	scf
	ret

; D = species, E = persistent marker. Validate before staging so malformed data
; cannot be mistaken for a regional identity.
RegionalFormStageNewMonMarker:
	ld a,e
	and a
	jr z,RegionalFormClearNewMonForm
	push de
	callba RegionalFormGetFormBySpeciesMarker
	pop de
	jr nc,RegionalFormClearNewMonForm
	ld a,e
	ld [wRegionalFormNewMonMarker],a
	ld hl,wHPBarDamageSpeed
	set BIT_REGIONAL_FORM_NEW_MON_OVERRIDE,[hl]
	scf
	ret

RegionalFormClearNewMonForm:
	ld hl,wHPBarDamageSpeed
	res BIT_REGIONAL_FORM_NEW_MON_OVERRIDE,[hl]
	xor a
	ld [wRegionalFormNewMonMarker],a
	ret

; WLD-5.62.21: D = map id, E = grass/water + exact slot. Convert the selected
; random encounter into the same validated transient marker used by other producers.
; A normal slot clears staging explicitly so a previous producer cannot leak.
RegionalFormStageWildEncounter:
	; CALLBA overwrites A while restoring the previous ROM bank, so use the
	; far-call-safe byte-return wrapper and receive the runtime form in E.
	callba RegionalFormGetWildFormBySlot
	jr nc,RegionalFormClearNewMonForm
	ld a,[wEnemyMonSpecies2]
	ld d,a
	jp RegionalFormStageNewMonForm

; WLD-5.62.21: latch the producer-selected identity before the first wild header
; load. Keep staging active for that first LoadEnemyMonData; the header consumer
; clears it only after materializing the regional header, matching the tested 025 flow.
RegionalFormLatchWildEnemyMarker:
	xor a
	ld [wWildEncounterFormMarker],a
	ld hl,wHPBarDamageSpeed
	bit BIT_REGIONAL_FORM_NEW_MON_OVERRIDE,[hl]
	ret z
	ld a,[wRegionalFormNewMonMarker]
	ld [wWildEncounterFormMarker],a
	ret

; Rebuild the original wild enemy from its latched marker. Capture and Pokémon
; Tower reloads must not rediscover identity from Map + Species or runtime Form.
RegionalFormReloadWildEnemyMonData:
	ld a,[wEnemyMonSpecies2]
	ld d,a
	ld a,[wWildEncounterFormMarker]
	ld e,a
	call RegionalFormStageNewMonMarker
	callab LoadEnemyMonData
	call RegionalFormClearNewMonForm
	ret

; wcf91 = species, E = runtime form. Match the tested branch contract so
; ReadTrainer and script producers do not depend on D surviving unrelated setup.
RegionalFormAddPartyMonWithForm:
	ld a,[wcf91]
	ld d,a
	call RegionalFormStageNewMonForm
	call AddPartyMon
	push af
	call RegionalFormClearNewMonForm
	pop af
	ret

; D = species, E = persistent marker; wcf91 already contains the same species.
; NPC trades use the same validated staging contract as the tested branch.
RegionalFormAddPartyMonWithMarker:
	call RegionalFormStageNewMonMarker
	call AddPartyMon
	push af
	call RegionalFormClearNewMonForm
	pop af
	ret

; Explicit-form gift API. Caller supplies wcf91 = species, E = runtime form and
; wCurEnemyLVL = level. Party and full-party-to-Box paths share the same staging.
RegionalFormGivePokemon:
	ld a,[wcf91]
	ld d,a
	call RegionalFormStageNewMonForm
	ld a,[wcf91]
	ld b,a
	ld a,[wCurEnemyLVL]
	ld c,a
	call GivePokemon
	push af
	call RegionalFormClearNewMonForm
	pop af
	ret

; STR-5.62.22: resolve the selected Oak Lab Starter's explicit runtime Form.
; Unknown Species intentionally returns NORMAL so stale producer state cannot
; turn an unrelated Starter into a regional instance.
RegionalFormGetStarterForm:
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

; Preview the same Species/Form identity that insertion will use. The current
; one-shot Pokédex renderer already understands captured Species + enemy Form;
; borrow that handoff only for this synchronous call, then restore both bytes.
RegionalFormShowStarterDex:
	call RegionalFormGetStarterForm
	ld a,[wcf91]
	ld [wCapturedMonSpecies],a
	ld a,e
	ld [wEnemyMonForm],a
	predef StarterDex
	; Oak Lab runs before any capture battle; leave both transient battle bytes
	; in their normal overworld state rather than holding stack data across CGB
	; Pokédex palette code that may switch WRAM banks internally.
	xor a
	ld [wCapturedMonSpecies],a
	ld [wEnemyMonForm],a
	ret

; Materialize the selected Starter through the same validated explicit-form
; bridge used by other producers. wPlayerStarter remains Species-only.
RegionalFormAddStarter:
	call RegionalFormGetStarterForm
	call RegionalFormAddPartyMonWithForm
	ret

; Resolve source form, then apply the first exact location/source/target override.
; If no override matches, inherit the source runtime form only when the target
; species has that descriptor. FORM_NORMAL remains the stock fallback.
RegionalFormResolveEvolutionTargetForm:
	xor a
	ld [wRegionalFormEvolutionTargetForm],a

	ld a,[wEvoOldSpecies]
	ld d,a
	ld a,[wLoadedMonCatchRate]
	ld e,a
	callba RegionalFormGetFormBySpeciesMarker
	jr nc,.normalSource
	ld a,d
	jr .sourceFormReady
.normalSource
	xor a
.sourceFormReady
	ld b,a

	ld hl,RegionalFormEvolutionOverrides
.overrideLoop
	ld a,[hl]
	cp $ff
	jr z,.inheritSourceForm
	push hl
	ld c,a
	ld a,[wCurMap]
	cp c
	jr nz,.nextOverride
	inc hl
	ld a,[hl]
	ld c,a
	ld a,[wEvoOldSpecies]
	cp c
	jr nz,.nextOverride
	inc hl
	ld a,[hl]
	cp b
	jr nz,.nextOverride
	inc hl
	ld a,[hl]
	ld c,a
	ld a,[wEvoNewSpecies]
	cp c
	jr nz,.nextOverride
	inc hl
	ld c,[hl]
	pop hl

	; FORM_NORMAL is a valid explicit target override. Non-normal targets must
	; have a registered descriptor before the override is accepted.
	ld a,c
	and a
	jr z,.storeOverride
	push bc
	ld a,[wEvoNewSpecies]
	ld d,a
	ld e,c
	callba RegionalFormGetMarkerBySpeciesForm
	pop bc
	jr nc,.inheritSourceForm
.storeOverride
	ld a,c
	ld [wRegionalFormEvolutionTargetForm],a
	scf
	ret

.nextOverride
	pop hl
	ld de,RF_EVO_OVERRIDE_SIZE
	add hl,de
	jr .overrideLoop

.inheritSourceForm
	ld a,b
	and a
	ret z
	push bc
	ld a,[wEvoNewSpecies]
	ld d,a
	ld e,b
	callba RegionalFormGetMarkerBySpeciesForm
	pop bc
	ret nc
	ld a,b
	ld [wRegionalFormEvolutionTargetForm],a
	scf
	ret
