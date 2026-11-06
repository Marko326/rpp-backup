; P2-002: region-aware physical map key -> compact slot -> header descriptor.
; D = region, E = stable local map ID. Only MAP_REGION_JOHTO is accepted.
; Return on success: E = dense active slot, D = header ROM bank, HL = header address.
; Return on failure: E = $FF, D = 0, HL = 0. A/flags are volatile.
;
; callab restores the caller's ROM bank; use E/D/HL, never A or carry, as
; output across the far-call boundary. Do not dereference HL until the caller
; explicitly switches to the returned header bank D. In particular, calling
; this routine NEVER makes a still-inactive map playable.
;
; Header pointer and bank live in one descriptor to prevent skew between two
; independent parallel arrays. Slot n corresponds to bytes [3*n .. 3*n+2].
; A row MUST be added only alongside all other map runtime resources, a
; stable-ID map entry, and an increment of NUM_JOHTO_ACTIVE_MAPS.
; P3-001 registers New Bark Town (stable ID 0) and Route 29 (stable ID 1).
JohtoHeaderDescriptors::
    dw JohtoPilotNewBarkRuntimeHeader
    db BANK(JohtoPilotNewBarkRuntimeHeader)
    dw JohtoPilotRoute29RuntimeHeader
    db BANK(JohtoPilotRoute29RuntimeHeader)
    dw JohtoPilotCherrygroveRuntimeHeader
    db BANK(JohtoPilotCherrygroveRuntimeHeader)
    dw JohtoPilotRoute30RuntimeHeader
    db BANK(JohtoPilotRoute30RuntimeHeader)
    dw JohtoPilotRoute31RuntimeHeader
    db BANK(JohtoPilotRoute31RuntimeHeader)
    dw JohtoGuideGentsHouseRuntimeHeader
    db BANK(JohtoGuideGentsHouseRuntimeHeader)
    dw JohtoPilotVioletRuntimeHeader
    db BANK(JohtoPilotVioletRuntimeHeader)
    dw JohtoPilotVioletGateRuntimeHeader
    db BANK(JohtoPilotVioletGateRuntimeHeader)
    dw JohtoPilotRoute32RuntimeHeader
    db BANK(JohtoPilotRoute32RuntimeHeader)
    dw JohtoPilotAlphSouthGateRuntimeHeader
    db BANK(JohtoPilotAlphSouthGateRuntimeHeader)
    dw JohtoPilotAlphOutsideRuntimeHeader
    db BANK(JohtoPilotAlphOutsideRuntimeHeader)
    dw JohtoPilotAlphNorthGateRuntimeHeader
    db BANK(JohtoPilotAlphNorthGateRuntimeHeader)
    dw JohtoPilotRoute36RuntimeHeader
    db BANK(JohtoPilotRoute36RuntimeHeader)
    dw JohtoUnionCave1FRuntimeHeader
    db BANK(JohtoUnionCave1FRuntimeHeader)
    dw JohtoRoute33RuntimeHeader
    db BANK(JohtoRoute33RuntimeHeader)
    dw JohtoSouthAzaleaTownRuntimeHeader
    db BANK(JohtoSouthAzaleaTownRuntimeHeader)
    dw JohtoSouthIlexForestAzaleaGateRuntimeHeader
    db BANK(JohtoSouthIlexForestAzaleaGateRuntimeHeader)
    dw JohtoSouthIlexForestRuntimeHeader
    db BANK(JohtoSouthIlexForestRuntimeHeader)
    dw JohtoSouthRoute34IlexForestGateRuntimeHeader
    db BANK(JohtoSouthRoute34IlexForestGateRuntimeHeader)
    dw JohtoSouthRoute34RuntimeHeader
    db BANK(JohtoSouthRoute34RuntimeHeader)
    dw JohtoSouthGoldenrodCityRuntimeHeader
    db BANK(JohtoSouthGoldenrodCityRuntimeHeader)
    dw JohtoNorthRoute35GoldenrodGateRuntimeHeader
    db BANK(JohtoNorthRoute35GoldenrodGateRuntimeHeader)
    dw JohtoNorthRoute35RuntimeHeader
    db BANK(JohtoNorthRoute35RuntimeHeader)
    dw JohtoParkRuntimeHeader
    db BANK(JohtoParkRuntimeHeader)
    dw JohtoParkSouthGateRuntimeHeader
    db BANK(JohtoParkSouthGateRuntimeHeader)
    dw JohtoParkEastGateRuntimeHeader
    db BANK(JohtoParkEastGateRuntimeHeader)
    dw JohtoRoute37RuntimeHeader
    db BANK(JohtoRoute37RuntimeHeader)
    dw JohtoEcruteakRuntimeHeader
    db BANK(JohtoEcruteakRuntimeHeader)
    dw JohtoRoute38EcruteakGateRuntimeHeader
    db BANK(JohtoRoute38EcruteakGateRuntimeHeader)
    dw JohtoRoute38RuntimeHeader
    db BANK(JohtoRoute38RuntimeHeader)
    dw JohtoRoute39RuntimeHeader
    db BANK(JohtoRoute39RuntimeHeader)
    dw JohtoOlivineRuntimeHeader
    db BANK(JohtoOlivineRuntimeHeader)
    dw JohtoRoute40RuntimeHeader
    db BANK(JohtoRoute40RuntimeHeader)
    dw JohtoRoute41RuntimeHeader
    db BANK(JohtoRoute41RuntimeHeader)
    dw JohtoCianwoodRuntimeHeader
    db BANK(JohtoCianwoodRuntimeHeader)
    dw JohtoRoute42EcruteakGateRuntimeHeader
    db BANK(JohtoRoute42EcruteakGateRuntimeHeader)
    dw JohtoRoute42RuntimeHeader
    db BANK(JohtoRoute42RuntimeHeader)
    dw JohtoMahoganyRuntimeHeader
    db BANK(JohtoMahoganyRuntimeHeader)
    dw JohtoRoute43MahoganyGateRuntimeHeader
    db BANK(JohtoRoute43MahoganyGateRuntimeHeader)
    dw JohtoRoute43RuntimeHeader
    db BANK(JohtoRoute43RuntimeHeader)
    dw JohtoRoute43GateRuntimeHeader
    db BANK(JohtoRoute43GateRuntimeHeader)
    dw JohtoLakeOfRageRuntimeHeader
    db BANK(JohtoLakeOfRageRuntimeHeader)
    dw JohtoRoute44RuntimeHeader
    db BANK(JohtoRoute44RuntimeHeader)
    dw JohtoBlackthornRuntimeHeader
    db BANK(JohtoBlackthornRuntimeHeader)
    dw JohtoRoute45RuntimeHeader
    db BANK(JohtoRoute45RuntimeHeader)
    dw JohtoRoute46RuntimeHeader
    db BANK(JohtoRoute46RuntimeHeader)
    dw JohtoRoute29Route46GateRuntimeHeader
    db BANK(JohtoRoute29Route46GateRuntimeHeader)
    ; DEV-334: shared reusable Pokemon Center interior, slot 47 / Gold ID 123.
    dw JohtoSharedPokecenterRuntimeHeader
    db BANK(JohtoSharedPokecenterRuntimeHeader)
    dw JohtoRoute32PokecenterRuntimeHeader
    db BANK(JohtoRoute32PokecenterRuntimeHeader)
    ; REF-334: Azalea Town Gold Center, slot49 / stable ID135 (append only).
    dw JohtoAzaleaPokecenterRuntimeHeader
    db BANK(JohtoAzaleaPokecenterRuntimeHeader)
    dw JohtoVioletPokecenterRuntimeHeader
    db BANK(JohtoVioletPokecenterRuntimeHeader)
    dw JohtoGoldenrodPokecenterRuntimeHeader
    db BANK(JohtoGoldenrodPokecenterRuntimeHeader)
    dw JohtoEcruteakPokecenterRuntimeHeader
    db BANK(JohtoEcruteakPokecenterRuntimeHeader)
    dw JohtoOlivinePokecenterRuntimeHeader
    db BANK(JohtoOlivinePokecenterRuntimeHeader)
    dw JohtoCianwoodPokecenterRuntimeHeader
    db BANK(JohtoCianwoodPokecenterRuntimeHeader)
    dw JohtoMahoganyPokecenterRuntimeHeader
    db BANK(JohtoMahoganyPokecenterRuntimeHeader)
    dw JohtoBlackthornPokecenterRuntimeHeader
    db BANK(JohtoBlackthornPokecenterRuntimeHeader)
    dw JohtoUnionCaveB1FRuntimeHeader
    db BANK(JohtoUnionCaveB1FRuntimeHeader)
    dw JohtoUnionCaveB2FRuntimeHeader
    db BANK(JohtoUnionCaveB2FRuntimeHeader)
    dw JohtoSlowpokeWellB1FRuntimeHeader
    db BANK(JohtoSlowpokeWellB1FRuntimeHeader)
    dw JohtoSlowpokeWellB2FRuntimeHeader
    db BANK(JohtoSlowpokeWellB2FRuntimeHeader)
    dw JohtoBurnedTower1FRuntimeHeader
    db BANK(JohtoBurnedTower1FRuntimeHeader)
    dw JohtoBurnedTowerB1FRuntimeHeader
    db BANK(JohtoBurnedTowerB1FRuntimeHeader)
    dw JohtoDarkCaveRuntimeHeader
    db BANK(JohtoDarkCaveRuntimeHeader)
JohtoHeaderDescriptorsEnd::
ASSERT JohtoHeaderDescriptorsEnd - JohtoHeaderDescriptors == NUM_JOHTO_ACTIVE_MAPS * JOHTO_HEADER_DESCRIPTOR_BYTES
ASSERT JOHTO_HEADER_DESCRIPTOR_BYTES == 3

ResolveJohtoHeaderDescriptor::
	ld a, d
	cp MAP_REGION_JOHTO
	jr nz, .invalid
	call GetJohtoActiveSlot ; E=slot / $ff, BC/HL/D preserved
	ld a, e
	cp JOHTO_INVALID_ACTIVE_SLOT
	jr z, .invalid
	; Guard against any malformed non-dense slot even if the mapper changes.
	cp NUM_JOHTO_ACTIVE_MAPS
	jr nc, .invalid

	push bc
	ld l, e
	ld h, 0
	ld c, e
	ld b, 0
	add hl, hl ; 2 * slot (16-bit)
	add hl, bc ; 3 * slot (16-bit, safe above slot 85)
	ld bc, JohtoHeaderDescriptors
	add hl, bc
	; Combined 3B descriptor: [lo, hi, bank].
	ld a, [hli]
	push af ; low byte of header pointer
	ld a, [hli] ; high byte of header pointer
	ld d, [hl] ; ROM bank of header
	ld h, a
	pop af
	ld l, a
	pop bc
	ret
.invalid
	ld e, JOHTO_INVALID_ACTIVE_SLOT
	ld d, 0
	ld hl, 0
	ret
