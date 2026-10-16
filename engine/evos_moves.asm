; try to evolve the mon in [wWhichPokemon]
TryEvolvingMon:
	ld hl, wCanEvolveFlags
	xor a
	ld [hl], a
	ld a, [wWhichPokemon]
	ld c, a
	ld b, FLAG_SET
	call Evolution_FlagAction

; this is only called after battle
; it is supposed to do level up evolutions, though there is a bug that allows item evolutions to occur
EvolutionAfterBattle:
	ld a, [hTilesetType]
	push af
	xor a
	ld [wEvolutionOccurred], a
	dec a
	ld [wWhichPokemon], a
	push hl
	push bc
	push de
	ld hl, wPartyCount
	push hl

Evolution_PartyMonLoop: ; loop over party mons
	ld hl, wWhichPokemon
	inc [hl]
	pop hl
	inc hl
	ld a, [hl]
	cp $ff ; have we reached the end of the party?
	jp z, .done
	ld [wEvoOldSpecies], a
	push hl
	ld a, [wWhichPokemon]
	ld c, a
	ld hl, wCanEvolveFlags
	ld b, FLAG_TEST
	call Evolution_FlagAction
	ld a, c
	and a ; is the mon's bit set?
	jp z, Evolution_PartyMonLoop ; if not, go to the next mon
	ld a, [wcf91]
	push af
	xor a ; PLAYER_PARTY_DATA
	ld [wMonDataLocation], a
	call LoadMonData
	pop af
	ld [wcf91], a
	callba RegionalFormTryGetLoadedMonEvolutionPointer
	jr c,.evolutionDataReady
	ld a, [wEvoOldSpecies]
	dec a
	ld b, 0
	ld hl, EvosMovesPointerTable
	add a
	rl b
	ld c, a
	add hl, bc
	ld a, [hli]
	ld h, [hl]
	ld l, a
	jr .evolutionDataReady
.evolutionDataReady

.evoEntryLoop ; loop over evolution entries
	call .readDataByte
	and a ; have we reached the end of the evolution data?
	jr z, Evolution_PartyMonLoop
	ld b, a ; evolution type
	cp EV_TRADE
	jr z, .checkTradeEvo
; not trade evolution
	ld a, [wLinkState]
	cp LINK_STATE_TRADING
	jr z, Evolution_PartyMonLoop ; if trading, go the next mon
	ld a, b
	cp EV_ITEM
	jp z, .checkItemEvo
	ld a, [wForceEvolution]
	and a
	jr nz, Evolution_PartyMonLoop
	ld a, b
	cp EV_LEVEL
	jp z, .checkLevel
	cp EV_MAP
	jp z, .checkMapEvo
	cp EV_MOVE
	jp z, .checkMoveEvo
	cp EV_RAND
	jp z, .checkRandomEvo
    cp EV_TYROGUE
    jp z, .checkTyrogueEvo
	
.checkTradeEvo
	ld a, [wLinkState]
	cp LINK_STATE_TRADING
	jp nz, .nextEvoEntry1 ; if not trading, go to the next evolution entry
	call .readDataByte ; level requirement
	ld b, a
	ld a, [wLoadedMonLevel]
	cp b ; is the mon's level greater than the evolution requirement?
	jp c, Evolution_PartyMonLoop ; if so, go the next mon
	jp .doEvolution
	
.checkMapEvo
	call .readDataByte
	ld b, a ; Map to evolve on
	ld a, [wCurMap]
	cp b ; Are we on the right map?
	jp nz, .nextEvoEntry2
	ld a, [wLoadedMonLevel] ; This has to be in "a" for the evolution to work properly
	jp .doEvolution; Do evolution
	
.checkMoveEvo
	call .readDataByte ; get the move number
	ld [wMoveNum],a ; store it here to hang onto it
	push hl ; We don't want to lose our place
	call CheckForMove ; New routine based on the one used by TMs
	pop hl ; Get our place back
	jp nc, .nextEvoEntry2 ; If they didn't know the move, go to next evolution
	ld a, [wLoadedMonLevel] ; This has to be in "a" for the evolution to work properly
	jp .doEvolution; If they did know it, do the evolution
	
.checkRandomEvo
	call .readDataByte ; get level to evolve
	ld b, a
	ld a, [wLoadedMonLevel]
	cp b
	jp c, .nextEvoEntry1 ; if too low, go to next evolution
	call .readDataByte ; which method is this?
	dec a ; is it RAND_1?
	jr z, .rand1
;rand2
	push hl
	call GetMonDVs
	pop hl
	jp c, .nextEvoEntry2
	jp z, .nextEvoEntry2
	jr .randDone	
.rand1
	push hl
	call GetMonDVs
	pop hl
	jp nc, .nextEvoEntry2
.randDone
	ld a, [wLoadedMonLevel] ; This has to be in "a" for the evolution to work properly
	jr .doEvolution ; Do evolution
	
.checkTyrogueEvo
    call .readDataByte ; level to evolve
    ld b, a
    ld a, [wLoadedMonLevel] ; current level
    cp b
    jp c, .nextEvoEntry1 ; if too low, go to next evo
    call .readDataByte ; which method is this?
    cp ATK_HIGHER
    jp z, .AtkHigher
    cp BOTH_EQUAL
    jp z, .AtkDefEqual
    cp DEF_HIGHER
    jp z, .DefHigher
.AtkHigher
    push hl ; Don't lose your place in the evolution data
    call GetTyrogueAtkDef
    pop hl ; Get our place back
    jp c, .nextEvoEntry2
    jp z, .nextEvoEntry2
    jr .TyrogueDone
.AtkDefEqual
    push hl ; Don't lose your place in the evolution data
    call GetTyrogueAtkDef
    pop hl ; Get our place back
    jp nz, .nextEvoEntry2
    jr .TyrogueDone
.DefHigher
    push hl ; Don't lose your place in the evolution data
    call GetTyrogueAtkDef
    pop hl ; Get our place back
    jp z, .nextEvoEntry2
    jp nc, .nextEvoEntry2
.TyrogueDone
    ld a, [wLoadedMonLevel]
    jr .doEvolution ; Do first Pokemon if Def is higher
	
.checkItemEvo
	call .readDataByte
	ld b, a ; evolution item
    ld a,[wIsInBattle] ; check if we're in a battle
	and a
	jp nz, .nextEvoEntry1 ; If we are, skip ahead
	ld a, [wcf91] ; this is supposed to be the last item used, but it is also used to hold species numbers
	cp b ; was the evolution item in this entry used?
	jp nz, .nextEvoEntry1 ; if not, go to the next evolution entry
	; fallthrough
	
.checkLevel
	call .readDataByte ; level requirement
	ld b, a
	ld a, [wLoadedMonLevel]
	cp b ; is the mon's level greater than the evolution requirement?
	jp c, .nextEvoEntry2 ; if so, go the next evolution entry
	; fallthrough
	
.doEvolution
	ld [wCurEnemyLVL], a
	ld a, 1
	ld [wEvolutionOccurred], a
	push hl
	call .peekDataByte
	ld [wEvoNewSpecies], a
	callba RegionalFormResolveEvolutionTargetForm
	ld a, [wWhichPokemon]
	ld hl, wPartyMonNicks
	call GetPartyMonName
	call CopyStringToCF4B
	ld hl, IsEvolvingText
	call PrintText
	ld c, 50
	call DelayFrames
	xor a
	ld [H_AUTOBGTRANSFERENABLED], a
	coord hl, 0, 0
	lb bc, 12, 20
	call ClearScreenArea
	ld a, $1
	ld [H_AUTOBGTRANSFERENABLED], a
	ld a, $ff
	ld [wUpdateSpritesEnabled], a
	call ClearSprites
	callab EvolveMon
	jp c, CancelledEvolution
	ld hl, EvolvedText
	call PrintText
	pop hl
	ld a, [wEvoNewSpecies]
	ld [wd0b5], a
	ld [wLoadedMonSpecies], a
	ld a, MONSTER_NAME
	ld [wNameListType], a
	ld a, BANK(TrainerNames) ; bank is not used for monster names
	ld [wPredefBank], a
	call GetName
	push hl
	ld hl, IntoText
	call PrintText_NoCreatingTextBox
	ld a, SFX_GET_ITEM_2
	call PlaySoundWaitForCurrent
	call WaitForSoundToFinish
	ld c, 40
	call DelayFrames
	call ClearScreen
	call RenameEvolvedMon
	ld a, [wd11e]
	push af
	callba RegionalFormCommitEvolutionTargetHeader
	pop af
	ld [wd11e], a
	ld hl, wLoadedMonHPExp - 1
	ld de, wLoadedMonStats
	ld b, $1
	call CalcStats
	ld a, [wWhichPokemon]
	ld hl, wPartyMon1
	ld bc, wPartyMon2 - wPartyMon1
	call AddNTimes
	ld e, l
	ld d, h
	push hl
	push bc
	ld bc, wPartyMon1MaxHP - wPartyMon1
	add hl, bc
	ld a, [hli]
	ld b, a
	ld c, [hl]
	ld hl, wLoadedMonMaxHP + 1
	ld a, [hld]
	sub c
	ld c, a
	ld a, [hl]
	sbc b
	ld b, a
	ld hl, wLoadedMonHP + 1
	ld a, [hl]
	add c
	ld [hld], a
	ld a, [hl]
	adc b
	ld [hl], a
	dec hl
	pop bc
	call CopyData
	ld a, [wd0b5]
	ld [wd11e], a
	xor a
	ld [wMonDataLocation], a
	callba RegionalFormTryLearnLevelMove
	jr c,.evolutionLevelMoveHandled
	call LearnMoveFromLevelUp
.evolutionLevelMoveHandled
	pop hl
	predef SetPartyMonTypes
	ld a, [wIsInBattle]
	and a
	call z, Evolution_ReloadTilesetTilePatterns
	; Species flags and exact newly evolved form now share one success-only hook.
	callba RegionalDexMarkEvolvedMonOwned
	pop de
	pop hl
	ld a, [wLoadedMonSpecies]
	ld [hl], a
	push hl
	ld l, e
	ld h, d
	jr .nextEvoEntry2
   
.nextEvoEntry1
	call .skipDataByte

.nextEvoEntry2
	call .skipDataByte
	jp .evoEntryLoop

; FORM-5.21.06: normal species keep using HL directly. A non-zero high byte in
; wRegionalFormEvolutionReadPointer switches the same parser to bank-$34 data.
; The far helpers return their byte in E because Bankswitch overwrites A while
; restoring the caller ROM bank. Preserve the parser's DE around the adapter.
.readDataByte:
	ld a,[wRegionalFormEvolutionReadPointer + 1]
	and a
	jr z,.readNormal
	push de
	callba RegionalFormReadEvolutionByte
	ld a,e
	pop de
	ret
.readNormal
	ld a,[hli]
	ret

.peekDataByte:
	ld a,[wRegionalFormEvolutionReadPointer + 1]
	and a
	jr z,.peekNormal
	push de
	callba RegionalFormPeekEvolutionByte
	ld a,e
	pop de
	ret
.peekNormal
	ld a,[hl]
	ret

.skipDataByte:
	ld a,[wRegionalFormEvolutionReadPointer + 1]
	and a
	jr z,.skipNormal
	ld hl,wRegionalFormEvolutionReadPointer
	inc [hl]
	ret nz
	inc hl
	inc [hl]
	ret
.skipNormal
	inc hl
	ret

.done
	pop de
	pop bc
	pop hl
	pop af
	ld [hTilesetType], a
	ld a, [wLinkState]
	cp LINK_STATE_TRADING
	ret z
	ld a, [wIsInBattle]
	and a
	ret nz
	ld a, [wEvolutionOccurred]
	and a
	call nz, PlayDefaultMusic
	ret

RenameEvolvedMon:
; Renames the mon to its new, evolved form's standard name unless it had a
; nickname, in which case the nickname is kept.
	ld a, [wd0b5]
	push af
	ld a, [wMonHIndex]
	ld [wd0b5], a
	call GetName
	pop af
	ld [wd0b5], a
	ld hl, wcd6d
	ld de, wcf4b
.compareNamesLoop
	ld a, [de]
	inc de
	cp [hl]
	inc hl
	ret nz
	cp "@"
	jr nz, .compareNamesLoop
	ld a, [wWhichPokemon]
	ld bc, NAME_LENGTH
	ld hl, wPartyMonNicks
	call AddNTimes
	push hl
	call GetName
	ld hl, wcd6d
	pop de
	jp CopyData

CancelledEvolution:
	ld hl, StoppedEvolvingText
	call PrintText
	call ClearScreen
	pop hl
	call Evolution_ReloadTilesetTilePatterns
	jp Evolution_PartyMonLoop

EvolvedText:
	TX_FAR _EvolvedText
	db "@"

IntoText:
	TX_FAR _IntoText
	db "@"

StoppedEvolvingText:
	TX_FAR _StoppedEvolvingText
	db "@"

IsEvolvingText:
	TX_FAR _IsEvolvingText
	db "@"

Evolution_ReloadTilesetTilePatterns:
	ld a, [wLinkState]
	cp LINK_STATE_TRADING
	ret z
	jp ReloadTilesetTilePatterns

ReadPackedLevelMove:
; LEARN-5.31.01 packed level-up learnset iterator.
; Input:
;   HL = packed learnset cursor
;   B  = previous absolute learn level (0 before the first entry)
;   C  = iterator state (0 before the first entry)
; Output when carry is set:
;   A  = move ID
;   B  = absolute learn level
;   C  = updated iterator state
;   HL = cursor for the next entry
; Carry clear means end of learnset. DE is preserved.
	push de
	bit 7,c
	jr nz,.secondEntry

	ld a,[hli] ; first move, or 0 for an even-length terminator
	and a
	jr z,.done
	ld e,a
	ld a,[hli] ; packed delta header
	ld d,a
	and $f
	or $80
	ld c,a ; remember second delta and mark it pending
	ld a,d
	swap a
	and $f
	ld d,a ; first delta code
	jr .applyDelta

.secondEntry
	ld d,c
	res 7,c ; consuming the pending second entry
	ld a,[hli] ; second move, or 0 for an odd-length terminator
	and a
	jr z,.done
	ld e,a
	ld a,d
	and $f
	ld d,a ; second delta code

.applyDelta
	ld a,d
	cp $f
	jr nz,.deltaReady
	ld a,[hli] ; escaped full 8-bit delta
.deltaReady
	add b
	ld b,a
	ld a,e
	pop de
	scf
	ret

.done
	pop de
	and a ; clear carry
	ret

LearnMoveFromLevelUp:
	; The extended-learning ordinal is local to this synchronous level-up.
	xor a
	ld [wExtendedLearningMoveOrdinal], a
	ld a, [wd11e] ; species
	ld [wcf91], a
	dec a
	ld b, 0
	ld c, a
	ld hl, EvosMovesPointerTable
	add hl, bc
	add hl, bc
	ld a, [hli]
	ld h, [hl]
	ld l, a
	
.skipEvolutionDataLoop ; loop to skip past the evolution data, which comes before the move data
	ld a, [hli]
	and a ; have we reached the end of the evolution data?
	jr nz, .skipEvolutionDataLoop ; if not, jump back up

	ld b,0 ; previous absolute learn level
	ld c,0 ; packed iterator state
.learnSetLoop ; loop over the packed learnset until the current level is found
	call ReadPackedLevelMove
	jr nc,.done
	ld d,a ; move ID
	ld a,[wCurEnemyLVL]
	cp b ; is the move learnt at the mon's current level?
	jr nz,.learnSetLoop

	push hl
	push bc ; preserve packed iterator state across move-learning code

	push de ; preserve the packed move ID while loading the party flag mask
	ld a, [wWhichPokemon]
	ld e, a
	ld d, 0
	ld hl, wExtendedPartyMoveFlags
	add hl, de
	ld a, [hl]
	ld [wExtendedMoveFlagsScratch], a
	ld hl, wPartyMon1Moves
	ld a, [wWhichPokemon]
	ld bc, wPartyMon2 - wPartyMon1
	call AddNTimes
	pop de
	ld b, NUM_MOVES
	ld c, 0
.checkCurrentMovesLoop ; check if the move to learn is already known
	ld a, [hli]
	cp d
	jr nz, .nextKnownMove
	ld a, [wExtendedLearningMoveOrdinal]
	and a
	jr z, .has_move ; ordinary learnset move matches an ordinary slot
	; Extended learning is a distinct identity. A matching low byte in an
	; already-flagged slot is NOT the same ordinary move.
	push bc
	ld b, c ; current zero-based move slot
	ld a, [wExtendedMoveFlagsScratch]
.extendedKnownFlagShift:
	inc b
	dec b
	jr z, .extendedKnownFlagBit
	srl a
	dec b
	jr .extendedKnownFlagShift
.extendedKnownFlagBit:
	and 1
	pop bc
	jr nz, .nextKnownMove
	jr .has_move
.nextKnownMove:
	inc c
	dec b
	jr nz, .checkCurrentMovesLoop
.has_move
	pop bc
	pop hl
	jr .learnSetLoop
	
.done
	; MOVE-5.62.173: capacity-test level 19/20 assignments are removed.
	; Keep the expanded identity machinery; future real level-up sources
	; must explicitly supply a valid extended ordinal for LearnMove.
	xor a
	ld [wExtendedLearningMoveOrdinal], a
	ld a, [wcf91]
	ld [wd11e], a
	ret

; writes the moves a mon has at level [wCurEnemyLVL] to [de]
; move slots are being filled up sequentially and shifted if all slots are full
WriteMonMoves:
	call GetPredefRegisters
	push hl
	push de
	push bc
	ld hl, EvosMovesPointerTable
	ld b, 0
	ld a, [wcf91]  ; cur mon ID
	dec a
	add a
	rl b
	ld c, a
	add hl, bc
	ld a, [hli]
	ld h, [hl]
	ld l, a
.skipEvoEntriesLoop
	ld a, [hli]
	and a
	jr nz, .skipEvoEntriesLoop

	ld b,0 ; previous absolute learn level
	ld c,0 ; packed iterator state
.learnSetLoop
	call ReadPackedLevelMove
	jp nc,.done
	push af ; keep move ID while checking the level filters
	ld a,[wCurEnemyLVL]
	cp b
	jr c,.pastCurrentLevel ; learnsets are sorted by level
	ld a,[wLearningMovesFromDayCare]
	and a
	jr z,.processMove
	ld a,[wDayCareStartLevel]
	cp b
	jr nc,.skipPackedMove ; min level >= move level

.processMove
	pop af
	push hl ; packed cursor
	push bc ; packed iterator state
	ld b,a ; current move ID

; check if the move is already known
	push de
	ld c, NUM_MOVES
.alreadyKnowsCheckLoop
	ld a, [de]
	inc de
	cp b
	jr z, .finishEntryWithDE
	dec c
	jr nz, .alreadyKnowsCheckLoop

; try to find an empty move slot
	pop de
	push de
	ld c, NUM_MOVES
.findEmptySlotLoop
	ld a, [de]
	and a
	jr z, .writeMoveToSlot
	inc de
	dec c
	jr nz, .findEmptySlotLoop

; no empty move slots found
	pop de
	push de
	ld h, d
	ld l, e
	call WriteMonMoves_ShiftMoveData ; shift all moves one up (deleting move 1)
	ld a, [wLearningMovesFromDayCare]
	and a
	jr z, .writeMoveToSlot

; shift PP as well if learning moves from day care
	ld a,b
	push af ; preserve current move ID while BC is used for the PP offset
	push de
	ld bc, wPartyMon1PP - (wPartyMon1Moves + 3)
	add hl, bc
	ld d, h
	ld e, l
	call WriteMonMoves_ShiftMoveData ; shift all move PP data one up
	pop de
	pop af
	ld b,a

.writeMoveToSlot
	ld a,b
	ld [de], a
	ld a, [wLearningMovesFromDayCare]
	and a
	jr z, .finishEntryWithDE

; write move PP value if learning moves from day care
	ld a,b
	ld hl, wPartyMon1PP - wPartyMon1Moves
	add hl, de
	push hl
	dec a
	ld hl, Moves
	ld bc, MoveEnd - Moves
	call AddNTimes
	ld de, wBuffer
	ld a, BANK(Moves)
	call FarCopyData
	ld a, [wBuffer + 5]
	pop hl
	ld [hl], a

.finishEntryWithDE
	pop de
.finishEntry
	pop bc
	pop hl
	jr .learnSetLoop

.skipPackedMove
	pop af
	jr .learnSetLoop

.pastCurrentLevel
	pop af
.done
	pop bc
	pop de
	pop hl
	ret

; shifts all move data one up (freeing 4th move slot)
WriteMonMoves_ShiftMoveData:
	ld c, NUM_MOVES - 1
.loop
	inc de
	ld a, [de]
	ld [hli], a
	dec c
	jr nz, .loop
	ret

Evolution_FlagAction:
	predef_jump FlagActionPredef
	
CheckForMove: ; New routine used by EV_MOVE
	ld a, [wWhichPokemon]
	ld hl, wPartyMon1Moves
	ld bc, wPartyMon2 - wPartyMon1
	call AddNTimes
	ld a, [wMoveNum]
	ld b, a
	ld c, NUM_MOVES
.loop
	ld a, [hli]
	cp b
	jr z, .known
	dec c
	jr nz, .loop
	and a
	ret
.known
	scf
	ret

GetTyrogueAtkDef:
; new routine for Tyrogue evolution
; stores his Atk location in de
; stores his Def location in hl
    ld a, [wWhichPokemon]
    ld hl, wPartyMon1Attack
    ld bc, wPartyMon2 - wPartyMon1
    call AddNTimes
    ld d,h
    ld e,l
; de now points to his Atk
    inc hl
    inc hl
; hl now points to his Def
    ld c, $2 ; data length
    call StringCmp ; compare his attack and defense
    ret
	
GetMonDVs:
; new routine for EV_RAND which isn't really random
; this reads the DVs of the partymon and compares the two bytes
	ld a, [wWhichPokemon]
	ld hl, wPartyMon1DVs
	ld bc, wPartyMon2 - wPartyMon1
	call AddNTimes
	ld a, [hli]
	ld b, a
	ld a, [hl]
	cp b
	ret

PrepareRelearnableMoveList:
; Loads relearnable move list to wRelearnableMoves.
; Input: party mon index = [wWhichPokemon]
	; Clear the parallel extended identities before either ordinary or
	; regional list construction. The item list is not active in this NPC.
	xor a
	ld hl, wExtendedNPCListMoveOrdinals
	ld bc, MOVE_RELEARNER_MAX_MOVES
	call FillMemory
	callba RegionalFormPrepareRelearnableMoveList
	ret c
	ld a, [wWhichPokemon]
	ld c, a
	ld b, 0
	ld hl, wPartySpecies
	add hl, bc
	ld a, [hl]
	dec a
	ld c, a
	ld b, 0
	ld hl, EvosMovesPointerTable
	add hl, bc
	add hl, bc
	ld a, [hli]
	ld h, [hl]
	ld l, a
.skipEvoEntriesLoop
	ld a, [hli]
	and a
	jr nz, .skipEvoEntriesLoop
	push hl
	; Cache the mon's current level in the existing generic scratch buffer.
	ld a, [wWhichPokemon]
	ld hl, wPartyMon1Level
	ld bc, wPartyMon2 - wPartyMon1
	call AddNTimes
	ld a, [hl]
	ld [wBuffer],a
	; Get pointer to mon's currently-known moves.
	ld a, [wWhichPokemon]
	ld hl, wPartyMon1Moves
	ld bc, wPartyMon2 - wPartyMon1
	call AddNTimes
	ld d, h
	ld e, l
	; MOVE-5.62.169: the learnset cursor was ALREADY pushed before loading the
	; party move pointer. Only DE needs temporary protection here.
	; A second push hl left an extra word on the stack, so the final ret
	; jumped into packed learnset data instead of returning to the NPC.
	push de
	ld a, [wWhichPokemon]
	ld e, a
	ld d, 0
	ld hl, wExtendedPartyMoveFlags
	add hl, de
	ld a, [hl]
	ld [wExtendedMoveFlagsScratch], a
	pop de
	pop hl
	xor a
	ld [wRelearnableMoves],a ; running output count
	ld b,0 ; previous absolute learn level
	ld c,0 ; packed iterator state
.loop
	call ReadPackedLevelMove
	jr nc,.done
	push af ; current move ID
	ld a,[wBuffer]
	cp b
	jr c,.pastCurrentLevel ; sorted learnset: no later move can qualify
	pop af
	push hl
	push bc ; preserve packed iterator state
	ld b,a ; move ID
	; Check if move is already known by our mon.
	push de
	ld a, [wExtendedMoveFlagsScratch]
	ld [wExtendedActiveMoveOrdinal], a ; synchronous NPC-only bit iterator
	ld c, NUM_MOVES
.knowsMoveLoop
	ld a,[de]
	inc de
	cp b
	jr nz, .nextKnownSlot
	ld a, [wExtendedActiveMoveOrdinal]
	and 1
	jr z, .knowsMove ; same old-table identity, not an expanded slot
.nextKnownSlot
	ld a, [wExtendedActiveMoveOrdinal]
	srl a
	ld [wExtendedActiveMoveOrdinal], a
	dec c
	jr nz,.knowsMoveLoop
	pop de

	; MOVE-5.62.171: bound the *ordinary* learnset too; it previously
	; appended without checking the fixed 8-row WRAM scratch and could
	; overwrite unrelated state before extended candidates were considered.
	ld a, [wRelearnableMoves]
	cp MOVE_RELEARNER_MAX_MOVES
	jr nc, .nextEntry
	ld c,a
	ld a,b
	ld b,0
	ld hl,wRelearnableMoves + 1
	add hl,bc
	ld [hl],a
	ld hl,wRelearnableMoves
	inc [hl]
	jr .nextEntry

.knowsMove
	pop de
.nextEntry
	pop bc
	pop hl
	jr .loop

.pastCurrentLevel
	pop af
.done
	; MOVE-5.62.173: no extended relearn candidates are assigned in the
	; accepted build. The 1-40 family table was test-only and is removed.
	; Ordinary and regional relearner behavior remains unchanged.

.terminateList
	ld a,[wRelearnableMoves]
	ld c,a
	ld b,0
	ld hl,wRelearnableMoves + 1
	add hl,bc
	ld [hl],$ff
	ret

INCLUDE "data/evos_moves.asm"
