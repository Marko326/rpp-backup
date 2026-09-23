; FORM-5.21.03 table-driven regional-form engine.
;
; Public battle/status/storage paths only deal with Species + Form. Concrete
; species, maps, stats, types, graphics, palettes and learnsets live in
; data/regional_forms.asm. Adding another supported form must not require a new
; species-specific branch in this file.

RF_DESC_SPECIES       EQU 0
RF_DESC_FORM          EQU 1
RF_DESC_MARKER        EQU 2
RF_DESC_HEADER        EQU 3
RF_DESC_LEARNSET      EQU 5
RF_DESC_EVOLUTION     EQU 7
RF_DESC_PALETTE       EQU 9
RF_DESC_SHINY_PALETTE EQU 11
RF_DESC_DEX_METRICS_BANK EQU 13
RF_DESC_DEX_METRICS_PTR  EQU 14
RF_DESC_SIZE          EQU 16

RF_WILD_MAP     EQU 0
RF_WILD_SPECIES EQU 1
RF_WILD_FORM    EQU 2
RF_WILD_SIZE    EQU 3

; -----------------------------------------------------------------------------
; Descriptor lookup
; -----------------------------------------------------------------------------

; D = species, E = runtime form id
; Returns HL = descriptor and carry set when found.
RegionalFormFindBySpeciesForm:
	ld hl,RegionalFormDescriptors
.loop
	ld a,[hl]
	and a
	jr z,.notFound
	cp d
	jr nz,.next
	inc hl
	ld a,[hl]
	dec hl
	cp e
	jr z,.found
.next
	ld bc,RF_DESC_SIZE
	add hl,bc
	jr .loop
.found
	scf
	ret
.notFound
	and a
	ret

; D = species, E = persistent marker byte
; Returns HL = descriptor and carry set when found.
RegionalFormFindBySpeciesMarker:
	ld hl,RegionalFormDescriptors
.loop
	ld a,[hl]
	and a
	jr z,.notFound
	cp d
	jr nz,.next
	push hl
	inc hl
	inc hl
	ld a,[hl]
	pop hl
	cp e
	jr z,.found
.next
	ld bc,RF_DESC_SIZE
	add hl,bc
	jr .loop
.found
	scf
	ret
.notFound
	and a
	ret

; D = species, E = current Pokédex view form.
; Return A = next registered form and carry set when this species has any
; regional form. FORM_NORMAL wraps to the first descriptor; the last descriptor
; wraps back to FORM_NORMAL. Descriptors do not need to be contiguous.
RegionalFormGetNextPokedexForm:
	ld a,e
	and a
	jr z,.fromNormal
	ld hl,RegionalFormDescriptors
	ld b,0 ; 0 until the current form has been encountered
	ld c,0 ; nonzero once this species has at least one descriptor
.loop
	ld a,[hl]
	and a
	jr z,.wrap
	cp d
	jr nz,.next
	ld c,1
	push hl
	inc hl
	ld a,[hl]
	pop hl
	push af
	ld a,b
	and a
	jr z,.checkCurrent
	pop af
	scf
	ret
.checkCurrent
	pop af
	cp e
	jr nz,.next
	ld b,1
.next
	push bc
	ld bc,RF_DESC_SIZE
	add hl,bc
	pop bc
	jr .loop
.wrap
	ld a,c
	and a
	jr z,.none
	xor a ; after the last regional form, return to NORMAL
	scf
	ret
.fromNormal
	ld hl,RegionalFormDescriptors
.firstLoop
	ld a,[hl]
	and a
	jr z,.none
	cp d
	jr z,.firstFound
	ld bc,RF_DESC_SIZE
	add hl,bc
	jr .firstLoop
.firstFound
	inc hl
	ld a,[hl]
	scf
	ret
.none
	and a
	ret

; D = species, E = current Pokédex view form.
; Return A = previous registered form and carry set when this species has any
; regional form. FORM_NORMAL wraps to the last descriptor; the first descriptor
; wraps back to FORM_NORMAL.
RegionalFormGetPreviousPokedexForm:
	ld a,e
	and a
	jr z,.fromNormal
	ld hl,RegionalFormDescriptors
	ld b,FORM_NORMAL ; previous matching form
	ld c,0 ; has at least one descriptor for species
.loop
	ld a,[hl]
	and a
	jr z,.missingCurrent
	cp d
	jr nz,.next
	ld c,1
	push hl
	inc hl
	ld a,[hl]
	pop hl
	cp e
	jr z,.foundCurrent
	ld b,a
.next
	push bc
	ld bc,RF_DESC_SIZE
	add hl,bc
	pop bc
	jr .loop
.foundCurrent
	ld a,b
	scf
	ret
.missingCurrent
	ld a,c
	and a
	jr z,.none
	xor a
	scf
	ret
.fromNormal
	ld hl,RegionalFormDescriptors
	ld b,FORM_NORMAL
	ld c,0
.lastLoop
	ld a,[hl]
	and a
	jr z,.lastDone
	cp d
	jr nz,.lastNext
	ld c,1
	push hl
	inc hl
	ld a,[hl]
	pop hl
	ld b,a
.lastNext
	push bc
	ld bc,RF_DESC_SIZE
	add hl,bc
	pop bc
	jr .lastLoop
.lastDone
	ld a,c
	and a
	jr z,.none
	ld a,b
	scf
	ret
.none
	and a
	ret

; D = species, E = Pokédex view form. Load the stock header first and replace it
; with the descriptor header only when that exact form exists. This means callers
; can safely request the current view form for a pre-evolution that may not have
; the same regional form; such cases automatically fall back to NORMAL.
RegionalFormLoadPokedexHeader:
	push de
	ld a,d
	ld [wd0b5],a
	call GetMonHeader
	pop de
	ld a,e
	and a
	ret z
	call RegionalFormFindBySpeciesForm
	ret nc
	call RegionalFormApplyDescriptorHeader
	scf
	ret

; D = species, E = Pokédex view form. RunPaletteCommand has already prepared the
; normal species palette; replace only palette slot 0 for a registered form.
RegionalFormOverridePokedexPalette:
	ld a,e
	and a
	ret z
	call RegionalFormFindBySpeciesForm
	ret nc
	call RegionalFormGetPalettePointer
	ld e,0
	jp RegionalFormCopyPaletteFromHL

; D = map id, E = species
; Returns A = runtime form id and carry set when this wild encounter has a form.
RegionalFormFindWildForm:
	ld hl,RegionalFormWildEncounters
.loop
	ld a,[hl]
	cp $ff
	jr z,.notFound
	cp d
	jr nz,.next
	inc hl
	ld a,[hl]
	dec hl
	cp e
	jr nz,.next
	inc hl
	inc hl
	ld a,[hl]
	scf
	ret
.next
	ld bc,RF_WILD_SIZE
	add hl,bc
	jr .loop
.notFound
	and a
	ret

; HL = descriptor. Returns HL = 16-bit pointer at descriptor field BC.
RegionalFormGetDescriptorPointer:
	add hl,bc
	ld a,[hli]
	ld h,[hl]
	ld l,a
	ret

; HL = descriptor. Copy its complete MonBaseStats-compatible record into
; wMonHeader, then restore the internal species index expected by callers.
RegionalFormApplyDescriptorHeader:
	; FORM-5.21.02: descriptor lookup/copy is an internal header override. Keep
	; BC/DE/HL stable so callers do not inherit CopyData's advanced pointers.
	push bc
	push de
	push hl
	ld a,[hl]
	push af
	ld bc,RF_DESC_HEADER
	call RegionalFormGetDescriptorPointer
	ld de,wMonHeader
	; FORM-5.27.00: regional headers intentionally remain independent legacy
	; 28-byte records; do not reuse the 24-byte stock ROM record size here.
	ld bc,wMonHPicBank + 1 - wMonHeader
	call CopyData
	pop af
	ld [wMonHIndex],a
	pop hl
	pop de
	pop bc
	ret

; HL = descriptor -> HL = level-up learnset.
RegionalFormGetLearnsetPointer:
	ld bc,RF_DESC_LEARNSET
	jp RegionalFormGetDescriptorPointer

; HL = descriptor -> HL = evolution data.
RegionalFormGetEvolutionPointer:
	ld bc,RF_DESC_EVOLUTION
	jp RegionalFormGetDescriptorPointer

; HL = descriptor -> HL = normal palette.
RegionalFormGetPalettePointer:
	ld bc,RF_DESC_PALETTE
	jp RegionalFormGetDescriptorPointer

; HL = descriptor -> HL = shiny palette.
RegionalFormGetShinyPalettePointer:
	ld bc,RF_DESC_SHINY_PALETTE
	jp RegionalFormGetDescriptorPointer


; D = species, E = form. Return carry set with A = metrics ROM bank and
; HL = metrics pointer when this form has height/weight overrides. NORMAL and
; descriptors with a null metrics field return carry clear.
RegionalFormGetPokedexMetricsPointer:
	ld a,e
	and a
	ret z
	call RegionalFormFindBySpeciesForm
	ret nc
	ld bc,RF_DESC_DEX_METRICS_BANK
	add hl,bc
	ld a,[hli]
	and a
	ret z
	ld b,a
	ld a,[hli]
	ld h,[hl]
	ld l,a
	ld a,b
	scf
	ret

; -----------------------------------------------------------------------------
; Header resolution for the different Pokémon storage/runtime representations
; -----------------------------------------------------------------------------

; Wild encounters get their form from the data table. Trainer/link/stored
; Pokémon do not use this path; they resolve from their persistent marker.
RegionalFormPrepareWildEnemyHeader:
	xor a
	ld [wEnemyMonForm],a
	ld a,[wIsInBattle]
	cp 1 ; wild battle only
	ret nz
	ld a,[wCurMap]
	ld d,a
	ld a,[wEnemyMonSpecies2]
	ld e,a
	call RegionalFormFindWildForm
	ret nc
	ld [wEnemyMonForm],a
	ld e,a
	ld a,[wEnemyMonSpecies2]
	ld d,a
	call RegionalFormFindBySpeciesForm
	ret nc
	call RegionalFormApplyDescriptorHeader
	scf
	ret

; Enemy party/link Pokémon already contain the persistent marker.
RegionalFormPrepareStoredEnemyHeader:
	xor a
	ld [wEnemyMonForm],a
	ld a,[wEnemyMonSpecies]
	ld d,a
	ld a,[wEnemyMonCatchRate_NotReferenced]
	ld e,a
	call RegionalFormFindBySpeciesMarker
	ret nc
	push hl
	inc hl
	ld a,[hl] ; descriptor form id
	ld [wEnemyMonForm],a
	pop hl
	call RegionalFormApplyDescriptorHeader
	scf
	ret

; Party stat recalculation must rebuild the form-aware header before CalcStats.
; Callers that replace a direct GetMonHeader with CALLBA must save their own
; BC/HL before CALLBA because the far-call macro consumes those registers.
RegionalFormLoadPartyMonHeader:
	call GetMonHeader
	push bc
	push de
	push hl
	ld a,[wd0b5]
	ld d,a
	ld a,[wWhichPokemon]
	ld hl,wPartyMon1CatchRate
	ld bc,wPartyMon2 - wPartyMon1
	call AddNTimes
	ld a,[hl]
	ld e,a
	call RegionalFormFindBySpeciesMarker
	jr nc,.done
	call RegionalFormApplyDescriptorHeader
.done
	pop hl
	pop de
	pop bc
	ret

; Player battle mon already copied the stored marker into wBattleMon.
RegionalFormPrepareBattleMonHeader:
	ld a,[wBattleMonSpecies]
	ld d,a
	ld a,[wBattleMonCatchRate]
	ld e,a
	call RegionalFormFindBySpeciesMarker
	ret nc
	call RegionalFormApplyDescriptorHeader
	scf
	ret

; LoadMonData copies party/box/day-care data into wLoadedMon first.
RegionalFormPrepareLoadedMonHeader:
	ld a,[wLoadedMonSpecies]
	ld d,a
	ld a,[wLoadedMonCatchRate]
	ld e,a
	call RegionalFormFindBySpeciesMarker
	ret nc
	call RegionalFormApplyDescriptorHeader
	scf
	ret

; Materialize the current wild form into persistent storage. Party insertion
; copies wMonHCatchRate; full-party SendNewMonToBox copies the parallel byte in
; wEnemyMon, so both storage sources receive the descriptor marker.
RegionalFormPrepareCaughtMonHeader:
	; FORM-5.21.02: CALLBA preserves DE, and AddPartyMon keeps its new-mon
	; destination there across this API. Preserve that public far-call contract.
	push de
	ld a,[wIsInBattle]
	cp 1
	jr nz,.done
	ld a,[wEnemyMonForm]
	and a
	jr z,.done
	ld e,a
	ld a,[wcf91]
	ld d,a
	call RegionalFormFindBySpeciesForm
	jr nc,.done
	push hl
	inc hl
	inc hl
	ld a,[hl] ; persistent marker
	pop hl
	push af
	call RegionalFormApplyDescriptorHeader
	pop af
	ld [wMonHCatchRate],a
	ld [wEnemyMonCatchRate_NotReferenced],a
.done
	pop de
	ret

; -----------------------------------------------------------------------------
; Independent level-up learnsets
; -----------------------------------------------------------------------------

; DE = first move slot. Carry set when a stored regional form was handled.
; The byte immediately before the move array is the stored form marker.
RegionalFormTryWriteStoredMonMoves:
	push de
	dec de
	ld a,[de]
	ld e,a
	ld a,[wcf91]
	ld d,a
	call RegionalFormFindBySpeciesMarker
	jr nc,.notHandled
	call RegionalFormGetLearnsetPointer
	pop de
	call RegionalFormWriteMovesFromLearnset
	scf
	ret
.notHandled
	pop de
	and a
	ret

; DE = first enemy move slot. Carry set when the current wild enemy has a
; descriptor-backed regional form.
RegionalFormTryWriteEnemyMonMoves:
	push de
	ld a,[wcf91]
	ld d,a
	ld a,[wEnemyMonForm]
	ld e,a
	and a
	jr z,.notHandled
	call RegionalFormFindBySpeciesForm
	jr nc,.notHandled
	call RegionalFormGetLearnsetPointer
	pop de
	call RegionalFormWriteMovesFromLearnset
	scf
	ret
.notHandled
	pop de
	and a
	ret

; HL = form-specific level-up learnset, DE = first move slot.
; Preserves stock day-care behavior: only moves learned after the start level
; are considered and PP is initialized for moves learned while in day care.
RegionalFormWriteMovesFromLearnset:
	push hl
	push de
	push bc
	jr .firstMove
.nextMove
	pop de
.nextMove2
	inc hl
.firstMove
	ld a,[hli]
	and a
	jp z,.done
	ld b,a
	ld a,[wCurEnemyLVL]
	cp b
	jp c,.done
	ld a,[wLearningMovesFromDayCare]
	and a
	jr z,.skipMinLevelCheck
	ld a,[wDayCareStartLevel]
	cp b
	jr nc,.nextMove2
.skipMinLevelCheck

	push de
	ld c,NUM_MOVES
.alreadyKnowsCheckLoop
	ld a,[de]
	inc de
	cp [hl]
	jr z,.nextMove
	dec c
	jr nz,.alreadyKnowsCheckLoop

	pop de
	push de
	ld c,NUM_MOVES
.findEmptySlotLoop
	ld a,[de]
	and a
	jr z,.writeMoveToSlot2
	inc de
	dec c
	jr nz,.findEmptySlotLoop

	pop de
	push de
	push hl
	ld h,d
	ld l,e
	call RegionalFormShiftMoveData
	ld a,[wLearningMovesFromDayCare]
	and a
	jr z,.writeMoveToSlot

	push de
	ld bc,wPartyMon1PP - (wPartyMon1Moves + 3)
	add hl,bc
	ld d,h
	ld e,l
	call RegionalFormShiftMoveData
	pop de

.writeMoveToSlot
	pop hl
.writeMoveToSlot2
	ld a,[hl]
	ld [de],a
	ld a,[wLearningMovesFromDayCare]
	and a
	jr z,.nextMove

	push hl
	ld a,[hl]
	ld hl,wPartyMon1PP - wPartyMon1Moves
	add hl,de
	push hl
	dec a
	ld hl,Moves
	ld bc,MoveEnd - Moves
	call AddNTimes
	ld de,wBuffer
	ld a,BANK(Moves)
	call FarCopyData
	ld a,[wBuffer + 5]
	pop hl
	ld [hl],a
	pop hl
	jr .nextMove

.done
	pop bc
	pop de
	pop hl
	ret

RegionalFormShiftMoveData:
	ld c,NUM_MOVES - 1
.loop
	inc de
	ld a,[de]
	ld [hli],a
	dec c
	jr nz,.loop
	ret

; Carry set for every stored regional form with a dedicated learnset, even when
; there is no move at the current level. This suppresses the stock species table.
RegionalFormTryLearnLevelMove:
	ld a,[wWhichPokemon]
	ld hl,wPartyMon1Species
	ld bc,wPartyMon2 - wPartyMon1
	call AddNTimes
	ld a,[hl]
	push af ; preserve species across LearnMove and other predefs
	ld d,a
	ld bc,wPartyMon1CatchRate - wPartyMon1Species
	add hl,bc
	ld a,[hl]
	ld e,a
	call RegionalFormFindBySpeciesMarker
	jr nc,.notHandled
	call RegionalFormGetLearnsetPointer
.loop
	ld a,[hli]
	and a
	jr z,.handled
	ld b,a
	ld a,[hli]
	ld d,a
	ld a,[wCurEnemyLVL]
	cp b
	jr nz,.loop

	push hl
	ld hl,wPartyMon1Moves
	ld a,[wWhichPokemon]
	ld bc,wPartyMon2 - wPartyMon1
	call AddNTimes
	ld b,NUM_MOVES
.checkCurrentMovesLoop
	ld a,[hli]
	cp d
	jr z,.hasMove
	dec b
	jr nz,.checkCurrentMovesLoop
	ld a,d
	ld [wMoveNum],a
	ld [wd11e],a
	call GetMoveName
	call CopyStringToCF4B
	predef LearnMove
.hasMove
	pop hl
	jr .loop

.handled
	pop af
	ld [wd11e],a
	scf
	ret
.notHandled
	pop af
	and a
	ret

; -----------------------------------------------------------------------------
; Evolution / relearn helpers
; -----------------------------------------------------------------------------
RegionalFormTryGetLoadedMonEvolutionPointer:
	ld a,[wLoadedMonSpecies]
	ld d,a
	ld a,[wLoadedMonCatchRate]
	ld e,a
	call RegionalFormFindBySpeciesMarker
	jr nc,.notFound
	call RegionalFormGetEvolutionPointer
	ld a,l
	ld [wRegionalFormEvolutionReadPointer],a
	ld a,h
	ld [wRegionalFormEvolutionReadPointer + 1],a
	scf
	ret
.notFound
	xor a
	ld [wRegionalFormEvolutionReadPointer],a
	ld [wRegionalFormEvolutionReadPointer + 1],a
	and a
	ret

; FORM-5.21.06: bank-$E's evolution parser consumes regional evolution data as a
; byte stream. Keeping only the ROM pointer in WRAM removes the old wEnemyMon
; table copy and therefore has no table-length/WRAM-boundary limit.
;
; IMPORTANT: callba/Bankswitch does not preserve A on return; it restores the
; caller ROM bank through A. Return the data byte in E instead, matching the
; project's existing far-call adapter convention (for example BattleRandomFar).
RegionalFormReadEvolutionByte:
	push hl
	ld a,[wRegionalFormEvolutionReadPointer]
	ld l,a
	ld a,[wRegionalFormEvolutionReadPointer + 1]
	ld h,a
	ld e,[hl]
	inc hl
	ld a,l
	ld [wRegionalFormEvolutionReadPointer],a
	ld a,h
	ld [wRegionalFormEvolutionReadPointer + 1],a
	pop hl
	ret

; Same stream access without advancing. Return E, not A, for the same far-call
; reason as RegionalFormReadEvolutionByte.
RegionalFormPeekEvolutionByte:
	push hl
	ld a,[wRegionalFormEvolutionReadPointer]
	ld l,a
	ld a,[wRegionalFormEvolutionReadPointer + 1]
	ld h,a
	ld e,[hl]
	pop hl
	ret

; A = evolution type. Returns C = bytes after the type byte in one stock entry.
; Keep one definition of the format so EV_ITEM / EV_RAND / EV_TYROGUE cannot
; drift between the generic regional parsers.
RegionalFormGetEvolutionPayloadLength:
	ld c,2
	cp EV_ITEM
	jr z,.long
	cp EV_RAND
	jr z,.long
	cp EV_TYROGUE
	ret nz
.long
	inc c
	ret

RegionalFormGetEvolutionStoneMenuText:
	ld a,[wLoadedMonSpecies]
	ld d,a
	ld a,[wLoadedMonCatchRate]
	ld e,a
	call RegionalFormFindBySpeciesMarker
	jr nc,.notRegional
	call RegionalFormGetEvolutionPointer
.loop
	ld a,[hli]
	and a
	jr z,.notAble
	cp EV_ITEM
	jr z,.item
	call RegionalFormGetEvolutionPayloadLength
.skipPayload
	inc hl
	dec c
	jr nz,.skipPayload
	jr .loop
.item
	; EV_ITEM = item, minimum level, target species. Consume all three bytes even
	; when the stone does not match, so the next iteration starts on an entry type.
	; FORM-5.22.00: regional item evolutions may have a real minimum level (the
	; first such production case is Alolan Vulpix). Match both item and level so
	; the Party menu does not claim "Able" when TryEvolvingMon will reject it.
	ld a,[hli]
	ld b,a ; required item
	ld a,[hli]
	ld c,a ; minimum level
	inc hl ; target species
	ld a,[wEvoStoneItemID]
	cp b
	jr nz,.loop
	ld a,[wLoadedMonLevel]
	cp c
	jr c,.loop
	ld de,PartyMenuAbleToEvolveText
	scf
	ret
.notAble
	ld de,PartyMenuNotAbleToEvolveText
	scf
	ret
.notRegional
	and a
	ret

; Build wRelearnableMoves entirely while bank $34 is active. The old helper
; copied the complete learnset into wEnemyMon and could cross the $CFFF WRAM0
; boundary for ordinary 30+ byte learnsets. Carry set means the regional form
; was handled; carry clear lets the caller use the stock species table.
RegionalFormPrepareRelearnableMoveList:
	ld a,[wWhichPokemon]
	ld hl,wPartyMon1Species
	ld bc,wPartyMon2 - wPartyMon1
	call AddNTimes
	ld a,[hl]
	ld d,a
	ld bc,wPartyMon1CatchRate - wPartyMon1Species
	add hl,bc
	ld a,[hl]
	ld e,a
	call RegionalFormFindBySpeciesMarker
	jp nc,.notFound
	call RegionalFormGetLearnsetPointer
	push hl ; regional learnset pointer
	ld a,[wWhichPokemon]
	ld hl,wPartyMon1Level
	ld bc,wPartyMon2 - wPartyMon1
	call AddNTimes
	ld a,[hl]
	ld b,a ; current level
	push bc ; preserve B=current level while AddNTimes needs BC as the party stride
	ld a,[wWhichPokemon]
	ld hl,wPartyMon1Moves
	ld bc,wPartyMon2 - wPartyMon1
	call AddNTimes
	ld d,h
	ld e,l ; DE = current moves
	pop bc ; restore B=current level
	pop hl ; HL = regional learnset
	ld c,0 ; relearnable count
.loop
	ld a,[hli]
	and a
	jp z,.done
	cp b
	jr c,.candidate
	jp nz,.done
.candidate
	ld a,[hli]
	push af ; candidate move
	push bc ; B = current level, C = relearnable count
	ld b,a
	push de
	ld c,NUM_MOVES
.checkKnown
	ld a,[de]
	cp b
	jr z,.known
	inc de
	dec c
	jr nz,.checkKnown
	pop de
	pop bc
	; wRelearnableMoves is 10 bytes total: count + up to 8 moves + $ff.
	ld a,c
	cp 8
	jr nc,.discardCandidate
	pop af ; candidate move
	push hl
	; B must remain the current Pokémon level across list indexing.
	; FORM-5.21.08 zeroed B here and therefore stopped after the first
	; relearnable move on the next level comparison.
	push bc
	ld hl,wRelearnableMoves + 1
	ld b,0
	add hl,bc
	ld [hl],a
	pop bc
	pop hl
	inc c
	jp .loop
.discardCandidate
	pop af
	jp .loop
.known
	pop de
	pop bc
	pop af
	jp .loop
.done
	ld b,0
	ld hl,wRelearnableMoves + 1
	add hl,bc
	ld [hl],$ff
	ld hl,wRelearnableMoves
	ld [hl],c
	scf
	ret
.notFound
	and a
	ret

RegionalFormResolveEvolutionTargetForm:
	xor a
	ld [wRegionalFormEvolutionTargetForm],a
	ld a,[wEvoOldSpecies]
	ld d,a
	ld a,[wLoadedMonCatchRate]
	ld e,a
	call RegionalFormFindBySpeciesMarker
	ret nc
	inc hl
	ld a,[hl]
	ld e,a
	ld a,[wEvoNewSpecies]
	ld d,a
	call RegionalFormFindBySpeciesForm
	ret nc
	inc hl
	ld a,[hl]
	ld [wRegionalFormEvolutionTargetForm],a
	scf
	ret

RegionalFormLoadEvolutionSourceHeader:
	push de
	ld a,[wEvoOldSpecies]
	ld [wd0b5],a
	call GetMonHeader
	ld a,[wEvoOldSpecies]
	ld d,a
	ld a,[wLoadedMonCatchRate]
	ld e,a
	call RegionalFormFindBySpeciesMarker
	jr nc,.done
	call RegionalFormApplyDescriptorHeader
.done
	pop de
	ret

RegionalFormLoadEvolutionTargetHeader:
	push de
	ld a,[wEvoNewSpecies]
	ld [wd0b5],a
	call GetMonHeader
	ld a,[wEvoNewSpecies]
	ld d,a
	ld a,[wRegionalFormEvolutionTargetForm]
	and a
	jr z,.done
	ld e,a
	call RegionalFormFindBySpeciesForm
	jr nc,.done
	call RegionalFormApplyDescriptorHeader
.done
	pop de
	ret

RegionalFormCommitEvolutionTargetHeader:
	push de
	ld a,[wEvoNewSpecies]
	ld [wd0b5],a
	call GetMonHeader
	ld a,[wEvoOldSpecies]
	ld d,a
	ld a,[wLoadedMonCatchRate]
	ld e,a
	call RegionalFormFindBySpeciesMarker
	jr nc,.done
	ld a,[wRegionalFormEvolutionTargetForm]
	and a
	jr z,.clearMarker
	ld e,a
	ld a,[wEvoNewSpecies]
	ld d,a
	call RegionalFormFindBySpeciesForm
	jr nc,.clearMarker
	call RegionalFormApplyDescriptorHeader
	inc hl
	inc hl
	ld a,[hl]
	ld [wLoadedMonCatchRate],a
	jr .done
.clearMarker
	ld a,[wMonHCatchRate]
	ld [wLoadedMonCatchRate],a
.done
	pop de
	ret

; -----------------------------------------------------------------------------
; Palette helpers
; -----------------------------------------------------------------------------

RegionalFormOverrideEvolutionPalette:
	push de
	ld a,[wWholeScreenPaletteMonSpecies]
	ld b,a
	ld a,[wEvoOldSpecies]
	cp b
	jr z,.source
	ld a,[wEvoNewSpecies]
	cp b
	jr nz,.done
	ld d,b
	ld a,[wRegionalFormEvolutionTargetForm]
	and a
	jr z,.done
	ld e,a
	call RegionalFormFindBySpeciesForm
	jr nc,.done
	jr .descriptorReady
.source
	ld d,b
	ld a,[wLoadedMonCatchRate]
	ld e,a
	call RegionalFormFindBySpeciesMarker
	jr nc,.done
.descriptorReady
	ld a,[wShinyMonFlag]
	bit 0,a
	jr nz,.shiny
	call RegionalFormGetPalettePointer
	jr .copy
.shiny
	call RegionalFormGetShinyPalettePointer
.copy
	ld e,0
	call RegionalFormCopyPaletteFromHL
.done
	pop de
	ret

; HL = two middle CGB colors (4 bytes), E = BG palette slot.
RegionalFormCopyPaletteFromHL:
	ld a,[rSVBK]
	ld b,a
	ld a,2
	ld [rSVBK],a
	push bc
	ld a,e
	add a
	add a
	add a
	ld e,a
	ld d,HIGH(W2_BgPaletteData)
	ld a,LOW(W2_BgPaletteData)
	add e
	ld e,a
	jr nc,.destReady
	inc d
.destReady
	ld a,$ff
	ld [de],a
	inc de
	ld a,$7f
	ld [de],a
	inc de
	ld c,4
.copyMiddle
	ld a,[hli]
	ld [de],a
	inc de
	dec c
	jr nz,.copyMiddle
	xor a
	ld [de],a
	inc de
	ld [de],a
	pop bc
	ld a,b
	ld [rSVBK],a
	ret

; E = 0 player, E = 1 enemy. Returns descriptor in HL with carry set.
; Battle form bytes live in WRAM bank 1; palette callers can enter with bank 2.
RegionalFormFindBattleSlotDescriptor:
	ld a,e
	cp 2
	jr nc,.no
	ld b,a
	ld a,[rSVBK]
	ld c,a
	ld a,1
	ld [rSVBK],a
	ld a,b
	and a
	jr z,.player
.enemy
	ld a,[wEnemyMonSpecies2]
	ld d,a
	ld a,[wEnemyMonForm]
	ld e,a
	ld a,c
	ld [rSVBK],a
	ld a,e
	and a
	jr z,.no
	jp RegionalFormFindBySpeciesForm
.player
	ld a,[wBattleMonSpecies]
	ld d,a
	ld a,[wBattleMonCatchRate]
	ld e,a
	ld a,c
	ld [rSVBK],a
	jp RegionalFormFindBySpeciesMarker
.no
	and a
	ret

RegionalFormLoadBattlePokemonPalette:
	push de
	callba LoadPokemonPalette
	pop de
	push de
	call RegionalFormFindBattleSlotDescriptor
	pop de
	ret nc
	call RegionalFormGetPalettePointer
	jp RegionalFormCopyPaletteFromHL

RegionalFormLoadBattleShinyPokemonPalette:
	push de
	callba LoadShinyPokemonPalette
	pop de
	push de
	call RegionalFormFindBattleSlotDescriptor
	pop de
	ret nc
	call RegionalFormGetShinyPalettePointer
	jp RegionalFormCopyPaletteFromHL

RegionalFormLoadStatusPokemonPalette:
	push de
	callba LoadPokemonPalette
	pop de
	push de
	ld a,[wLoadedMonSpecies]
	ld d,a
	ld a,[wLoadedMonCatchRate]
	ld e,a
	call RegionalFormFindBySpeciesMarker
	pop de
	ret nc
	call RegionalFormGetPalettePointer
	jp RegionalFormCopyPaletteFromHL

RegionalFormLoadStatusShinyPokemonPalette:
	push de
	callba LoadShinyPokemonPalette
	pop de
	push de
	ld a,[wLoadedMonSpecies]
	ld d,a
	ld a,[wLoadedMonCatchRate]
	ld e,a
	call RegionalFormFindBySpeciesMarker
	pop de
	ret nc
	call RegionalFormGetShinyPalettePointer
	jp RegionalFormCopyPaletteFromHL

; -----------------------------------------------------------------------------
; Public form-aware header wrappers
; -----------------------------------------------------------------------------
; FORM-5.21.02 ABI: CALLBA itself consumes A/BC/HL, but DE survives Bankswitch.
; These public header APIs therefore preserve DE so callers may safely keep a
; party/storage/tile destination there, matching the stock GetMonHeader behavior.

; Rebuild the currently active enemy header from the already-resolved runtime
; form. Used by battle refresh/stat paths that must not rediscover the encounter.
RegionalFormLoadCurrentEnemyHeader:
	push de
	ld a,[wEnemyMonSpecies]
	ld [wd0b5],a
	call GetMonHeader
	ld a,[wEnemyMonForm]
	and a
	jr z,.done
	ld e,a
	ld a,[wEnemyMonSpecies]
	ld d,a
	call RegionalFormFindBySpeciesForm
	jr nc,.done
	call RegionalFormApplyDescriptorHeader
	scf
.done
	pop de
	ret

RegionalFormLoadWildEnemyHeader:
	push de
	call GetMonHeader
	call RegionalFormPrepareWildEnemyHeader
	pop de
	ret

RegionalFormLoadStoredEnemyHeader:
	push de
	call GetMonHeader
	call RegionalFormPrepareStoredEnemyHeader
	pop de
	ret

RegionalFormLoadBattleMonHeader:
	push de
	ld a,[wBattleMonSpecies]
	ld [wd0b5],a
	call GetMonHeader
	call RegionalFormPrepareBattleMonHeader
	pop de
	ret

; Returns carry set when wLoadedMon resolved to a registered regional form.
RegionalFormLoadLoadedMonHeader:
	push de
	ld a,[wLoadedMonSpecies]
	ld [wd0b5],a
	call GetMonHeader
	call RegionalFormPrepareLoadedMonHeader
	pop de
	ret
