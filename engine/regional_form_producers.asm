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
