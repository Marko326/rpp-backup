; R33-5.62.191: Route33 Gold 16x16 collision per coordinate, not per 8x8 art.
; Cave (11,9) has exact northward approach exception; Azalea remains fenced.
; Direct call from JohtoNativeCollisionFence, returns carry=blocked.
JohtoRoute33EdgeFence::
	ld a, [wPlayerDirection]
	cp PLAYER_DIR_UP
	jr z, .north
	cp PLAYER_DIR_DOWN
	jr z, .south
	cp PLAYER_DIR_LEFT
	jr z, .west
	cp PLAYER_DIR_RIGHT
	jr nz, .clear
	ld a, [wXCoord]
	cp JOHTO_ROUTE_33_WIDTH * 2 - 1
	jr nc, .block
	jr .clear
.north
	ld a, [wYCoord]
	and a
	jr nz, .clear
	ld a, [wXCoord]
	cp 15
	jr c, .clear
	jr .block
.west
	ld a, [wXCoord]
	and a
	jr nz, .clear
	ld a, [wYCoord]
	cp 14
	jr c, .block
	cp 16
	jr c, .clear
	jr .block
.south
	ld a, [wYCoord]
	cp JOHTO_ROUTE_33_HEIGHT * 2 - 1
	jr c, .clear
.block
	scf
	ret
.clear
	and a
	ret

; MAP-5.62.195: all Azalea borders closed except Gold's Route33 east road.
JohtoAzaleaEdgeFence::
	ld a, [wPlayerDirection]
	cp PLAYER_DIR_RIGHT
	jr z, .east
	cp PLAYER_DIR_LEFT
	jr z, .west
	cp PLAYER_DIR_UP
	jr z, .north
	cp PLAYER_DIR_DOWN
	jr nz, .clear
	ld a, [wYCoord]
	cp JOHTO_AZALEA_TOWN_HEIGHT * 2 - 1
	jr nc, .block
	jr .clear
.north
	ld a, [wYCoord]
	and a
	jr z, .block
	jr .clear
.west
	ld a, [wXCoord]
	and a
	jr z, .block ; Route34 remains closed
	jr .clear
.east
	ld a, [wXCoord]
	cp JOHTO_AZALEA_TOWN_WIDTH * 2 - 1
	jr c, .clear
	ld a, [wYCoord]
	cp 14
	jr c, .block
	cp 16
	jr nc, .block
	jr .clear
.block
	scf
	ret
.clear
	and a
	ret

; R35-5.62.223: Route36 east y8/9 remains open, south x17 reaches Route35.
; Route37 north only x25..32; all other unbuilt borders sealed.
JohtoRoute36EdgeFence::
	ld a, [wPlayerDirection]
	cp PLAYER_DIR_RIGHT
	jr z, .east
	cp PLAYER_DIR_LEFT
	jr z, .west
	cp PLAYER_DIR_UP
	jr z, .north
	cp PLAYER_DIR_DOWN
	jr nz, .clear
	ld a, [wYCoord]
	cp JOHTO_ROUTE_36_HEIGHT * 2 - 1
	jr c, .clear
	ld a, [wXCoord]
	cp 17
	jr z, .clear
	jr .block
.north
	ld a, [wYCoord]
	and a
	jr nz, .clear
	ld a, [wXCoord]
	cp 25
	jr c, .block
	cp 33
	jr nc, .block
	jr .clear
.west
	ld a, [wXCoord]
	and a
	jr z, .block
	jr .clear
.east
	ld a, [wXCoord]
	cp JOHTO_ROUTE_36_WIDTH * 2 - 1
	jr c, .clear
	ld a, [wYCoord]
	cp 8
	jr z, .clear
	cp 9
	jr z, .clear
.block
	scf
	ret
.clear
	and a
	ret

; R36-5.62.218: reuse Gold 16x16 masked-step executor for Route36.
; Entrance carpets stay blocked pending gate implementations; no Sudowoodo
; object is spawned in this open-passage map stage (Gold battle deferred).
JohtoRoute36CanStepAhead::
	ld a, [wCurRegion]
	cp MAP_REGION_JOHTO
	jp nz, .blocked
	ld a, [wCurLocalMapID]
	cp JOHTO_ROUTE_36_LOCAL_ID
	jp nz, .blocked
	ld a, [wPlayerDirection]
	cp PLAYER_DIR_UP
	jr nz, .checkDown
	ld a, [wYCoord]
	and a
	jr nz, .normal
	ld a, [wXCoord]
	cp 25
	jr c, .normal
	cp 33
	jr c, .allowed
	jr .normal
.checkDown
	cp PLAYER_DIR_DOWN
	jr nz, .checkEast
	ld a, [wYCoord]
	cp JOHTO_ROUTE_36_HEIGHT * 2 - 1
	jr nz, .normal
	ld a, [wXCoord]
	cp 17
	jr z, .allowed
.checkEast
	ld a, [wPlayerDirection]
	cp PLAYER_DIR_RIGHT
	jr nz, .normal
	ld a, [wXCoord]
	cp JOHTO_ROUTE_36_WIDTH * 2 - 1
	jr nz, .normal
	ld a, [wYCoord]
	cp 8
	jr z, .allowed
	cp 9
	jr z, .allowed
.normal
	; Open Gold's Route36->Ruins double downward carpets, not NPC gates.
	ld a, [wXCoord]
	cp 47
	jr z, .gateX
	cp 48
	jr nz, .maskRoute36
.gateX
	ld a, [wYCoord]
	cp 12
	jr nz, .gateLane
	ld a, [wPlayerDirection]
	cp PLAYER_DIR_DOWN
	jr z, .allowed
.gateLane
	ld a, [wYCoord]
	cp 13
	jr nz, .maskRoute36
	ld a, [wPlayerDirection]
	cp PLAYER_DIR_LEFT
	jr nz, .rightGateLane
	ld a, [wXCoord]
	cp 48
	jr z, .allowed
	jr .maskRoute36
.rightGateLane
	cp PLAYER_DIR_RIGHT
	jr nz, .maskRoute36
	ld a, [wXCoord]
	cp 47
	jr z, .allowed
.maskRoute36
	ld hl, JohtoRoute36BlockedRows
	ld d, JOHTO_ROUTE_36_WIDTH * 2
	ld e, 8
	jp JohtoModernMaskedStep
.allowed
	and a
	ret
.blocked
	scf
	ret

JohtoRoute36BlockedRows::
	INCBIN "maps/JohtoRoute36.blocked_mask.bin"


; EAST-Route42: west gate uses interior collision Warps; east seamless
; connection to MahoganyTown (ID64) is active only on verified Gold corridors.
; Other unimplemented exits remain fail-closed.
; B-East: MahoganyTown west seam / Route42 east seam share Gold offset 0.
; Gold Route42 east / MahoganyTown west has TWO interior-reachable seam
; components: y4..7 (upper path into central town) and y9..17 (lower
; path along town x0 to y16/17). Prior y14..17-only fence passed a
; border-only test yet blocked both natural approaches on hardware.
; y0..2 are disconnected border fragments; y8 is an actual Gold wall.
; Do not open the unrelated north/east/south edges.
JohtoMahoganyTownEdgeFence::
 ld a, [wPlayerDirection]
 cp PLAYER_DIR_LEFT
 jr z, .west
 cp PLAYER_DIR_RIGHT
 jr z, .east
 cp PLAYER_DIR_UP
 jr z, .north
 cp PLAYER_DIR_DOWN
 jr nz, .clear
 ld a, [wYCoord]
 cp JOHTO_MAHOGANY_TOWN_HEIGHT * 2 - 1
 jr nc, .block
 jr .clear
.north
 ld a, [wYCoord]
 and a
 jr z, .block
 jr .clear
.east
 ld a, [wXCoord]
 cp JOHTO_MAHOGANY_TOWN_WIDTH * 2 - 1
 jr nc, .block
 jr .clear
.west
 ld a, [wXCoord]
 and a
 jr nz, .clear
 ld a, [wYCoord]
 cp 4
 jr c, .block
 cp 8
 jr c, .clear
 cp 9
 jr c, .block
 cp 18
 jr c, .clear
.block
 scf
 ret
.clear
 and a
 ret

JohtoMahoganyTownCanStepAhead::
 ld a, [wCurRegion]
 cp MAP_REGION_JOHTO
 jr nz, .block
 ld a, [wCurLocalMapID]
 cp JOHTO_MAHOGANY_TOWN_LOCAL_ID
 jr nz, .block
 ; .235D: Gold (9,1) is a DOOR with step-on Warp activation; allow
 ; the approach from (9,2) despite the preserved solid-door mask.
 ; The wall beyond the door remains blocked; do not open the whole roof.
 ld a, [wPlayerDirection]
 cp PLAYER_DIR_UP
 jr nz, .westSeam
 ld a, [wXCoord]
 cp 9
 jr nz, .westSeam
 ld a, [wYCoord]
 cp 2
 jr z, .clear
.westSeam
 ld a, [wPlayerDirection]
 cp PLAYER_DIR_LEFT
 jr nz, .mask
 ld a, [wXCoord]
 and a
 jr nz, .mask
 ld a, [wYCoord]
 cp 4
 jr c, .mask
 cp 8
 jr c, .clear
 cp 9
 jr c, .mask
 cp 18
 jr c, .clear
.mask
 ld hl, JohtoMahoganyTownBlockedRows
 ld d, JOHTO_MAHOGANY_TOWN_WIDTH * 2
 ld e, 3
 jp JohtoModernMaskedStep
.clear
 and a
 ret
.block
 scf
 ret

JohtoMahoganyTownBlockedRows::
 INCBIN "maps/JohtoMahoganyTown.blocked_mask.bin"

JohtoRoute42EdgeFence::
	ld a, [wPlayerDirection]
	cp PLAYER_DIR_LEFT
	jr z, .west
	cp PLAYER_DIR_RIGHT
	jr z, .east
	cp PLAYER_DIR_UP
	jr z, .north
	cp PLAYER_DIR_DOWN
	jr nz, .clear
	ld a, [wYCoord]
	cp JOHTO_ROUTE_42_HEIGHT * 2 - 1
	jr nc, .block
	jr .clear
.north
	ld a, [wYCoord]
	and a
	jr z, .block
	jr .clear
.west
	ld a, [wXCoord]
	and a
	jr z, .block
	jr .clear
.east
	ld a, [wXCoord]
	cp JOHTO_ROUTE_42_WIDTH * 2 - 1
	jr c, .clear
	ld a, [wYCoord]
	cp 4
	jr c, .block
	cp 8
	jr c, .clear
	cp 9
	jr c, .block
	cp 18
	jr c, .clear
	jr .block
.clear
	and a
	ret
.block
	scf
	ret

JohtoRoute42CanStepAhead::
	ld a, [wCurRegion]
	cp MAP_REGION_JOHTO
	jr nz, .block
	ld a, [wCurLocalMapID]
	cp JOHTO_ROUTE_42_LOCAL_ID
	jr nz, .block
	; Both Gold floor corridors must cross: y4..7 or y9..17.
	ld a, [wPlayerDirection]
	cp PLAYER_DIR_RIGHT
	jr nz, .cutTree
	ld a, [wXCoord]
	cp JOHTO_ROUTE_42_WIDTH * 2 - 1
	jr nz, .cutTree
	ld a, [wYCoord]
	cp 4
	jr c, .cutTree
	cp 8
	jr c, .clear
	cp 9
	jr c, .cutTree
	cp 18
	jr c, .clear
.cutTree
	call JohtoRoute42CutTreeCleared
	jr c, .clear
	ld hl, JohtoRoute42BlockedRows
	ld d, JOHTO_ROUTE_42_WIDTH * 2
	ld e, 8
	jp JohtoModernMaskedStep
.clear
	and a
	ret
.block
	scf
	ret

JohtoRoute42BlockedRows::
	INCBIN "maps/JohtoRoute42.blocked_mask.bin"

; A single Gold CUT_TREE quadrant at (24,13), inside source $63 BL.
; The runtime replacement $8b preserves all other block graphics.
JohtoRoute42CutTreeInFront::
	call JohtoRoute42CutTreeFacing
	ret nc
	call JohtoCutFacingBlockPointer
	ld a, [hl]
	cp $63
	jr z, .yes
	and a
	ret
.yes
	scf
	ret
JohtoRoute42CutTreeCleared::
	call JohtoRoute42CutTreeFacing
	ret nc
	call JohtoCutFacingBlockPointer
	ld a, [hl]
	cp $8b
	jr z, .yes
	and a
	ret
.yes
	scf
	ret
JohtoRoute42RemoveCutTree::
	call JohtoRoute42CutTreeFacing
	ret nc
	call JohtoCutFacingBlockPointer
	ld a, [hl]
	cp $63
	ret nz
	ld a, $8b
	ld [hl], a
	ret
JohtoRoute42CutTreeFacing:
	ld a, [wCurMap]
	cp REGION_NATIVE_MAP_SLOT
	jr nz, .no
	ld a, [wCurRegion]
	cp MAP_REGION_JOHTO
	jr nz, .no
	ld a, [wCurLocalMapID]
	cp JOHTO_ROUTE_42_LOCAL_ID
	jr nz, .no
	ld a, [wXCoord]
	cp 24
	jr z, .sameX
	cp 23
	jr z, .left
	cp 25
	jr z, .right
	jr .no
.sameX
	ld a, [wYCoord]
	cp 12
	jr z, .above
	cp 14
	jr z, .below
	jr .no
.above
	ld a, [wPlayerDirection]
	cp PLAYER_DIR_DOWN
	jr z, .yes
	jr .no
.below
	ld a, [wPlayerDirection]
	cp PLAYER_DIR_UP
	jr z, .yes
	jr .no
.left
	ld a, [wYCoord]
	cp 13
	jr nz, .no
	ld a, [wPlayerDirection]
	cp PLAYER_DIR_RIGHT
	jr z, .yes
	jr .no
.right
	ld a, [wYCoord]
	cp 13
	jr nz, .no
	ld a, [wPlayerDirection]
	cp PLAYER_DIR_LEFT
	jr z, .yes
.no
	and a
	ret
.yes
	scf
	ret

; EcruteakCity Gold 40x36 quadrants. Only the two physical south road
; tiles (x17,18) can cross into Route37 (x7,8). West/east gates use paired Warp carpets.
JohtoEcruteakCityEdgeFence::
	ld a, [wPlayerDirection]
	cp PLAYER_DIR_DOWN
	jr z, .south
	cp PLAYER_DIR_UP
	jr z, .north
	cp PLAYER_DIR_LEFT
	jr z, .west
	cp PLAYER_DIR_RIGHT
	jr nz, .clear
	ld a, [wXCoord]
	cp JOHTO_ECRUTEAK_CITY_WIDTH * 2 - 1
	jr nc, .block
	jr .clear
.north
	ld a, [wYCoord]
	and a
	jr z, .block
	jr .clear
.west
	ld a, [wXCoord]
	and a
	jr nz, .clear
	; Only the two Gold west gate tiles lead to Route38 gate.
	ld a, [wYCoord]
	cp 18
	jr z, .clear
	cp 19
	jr z, .clear
	jr .block
.south
	ld a, [wYCoord]
	cp JOHTO_ECRUTEAK_CITY_HEIGHT * 2 - 1
	jr c, .clear
	ld a, [wXCoord]
	cp 17
	jr z, .clear
	cp 18
	jr z, .clear
.block
	scf
	ret
.clear
	and a
	ret

JohtoEcruteakCityCanStepAhead::
	ld a, [wCurRegion]
	cp MAP_REGION_JOHTO
	jr nz, .blocked
	ld a, [wCurLocalMapID]
	cp JOHTO_ECRUTEAK_CITY_LOCAL_ID
	jr nz, .blocked
	ld a, [wPlayerDirection]
	cp PLAYER_DIR_DOWN
	jr nz, .normal
	ld a, [wYCoord]
	cp JOHTO_ECRUTEAK_CITY_HEIGHT * 2 - 1
	jr nz, .normal
	ld a, [wXCoord]
	cp 17
	jr z, .allowed
	cp 18
	jr z, .allowed
.normal
	; Gold west doorway at x0,y18/19 is a WARP_CARPET_LEFT,
	; not generic walkable FLOOR. Permit approaching from x1 only.
	ld a, [wPlayerDirection]
	cp PLAYER_DIR_LEFT
	jr nz, .checkMatVertical
	ld a, [wXCoord]
	cp 1
	jr nz, .checkMatVertical
	ld a, [wYCoord]
	cp 18
	jr z, .allowed
	cp 19
	jr z, .allowed
	; An east-west gate's two stacked carpet cells are ordinary floor for
	; vertical movement. Only facing LEFT from the carpet is a Warp attempt.
	; The Gold collision bitmap marks warp carpets blocked by default.
.checkMatVertical
	ld a, [wXCoord]
	and a
	jr nz, .maskEcruteak
	ld a, [wPlayerDirection]
	cp PLAYER_DIR_DOWN
	jr z, .cityMatDown
	cp PLAYER_DIR_UP
	jr nz, .maskEcruteak
	ld a, [wYCoord]
	cp 19
	jr z, .allowed
	jr .maskEcruteak
.cityMatDown
	ld a, [wYCoord]
	cp 18
	jr z, .allowed
.maskEcruteak
	ld hl, JohtoEcruteakCityBlockedRows
	ld d, JOHTO_ECRUTEAK_CITY_WIDTH * 2
	ld e, 5
	jp JohtoModernMaskedStep
.allowed
	and a
	ret
.blocked
	scf
	ret

JohtoEcruteakCityBlockedRows::
	INCBIN "maps/JohtoEcruteakCity.blocked_mask.bin"

; SPID.233 Gold exact physical seam permissions, not a generic open edge.
JohtoRoute39EdgeFence::
 ld a, [wPlayerDirection]
 cp PLAYER_DIR_RIGHT
 jr z,.east
 cp PLAYER_DIR_DOWN
 jr z,.south
 cp PLAYER_DIR_LEFT
 jr z,.west
 cp PLAYER_DIR_UP
 jr nz,.clear
 ld a, [wYCoord]
 and a
 jr z,.block
 jr .clear
.west
 ld a, [wXCoord]
 and a
 jr z,.block
 jr .clear
.east
 ld a, [wXCoord]
 cp JOHTO_ROUTE_39_WIDTH * 2 - 1
 jr c,.clear
 ld a, [wYCoord]
 cp 8
 jr c,.block
 cp 12
 jr c,.clear
 jr .block
.south
 ld a, [wYCoord]
 cp JOHTO_ROUTE_39_HEIGHT * 2 - 1
 jr c,.clear
 ld a, [wXCoord]
 cp 8
 jr c,.block
 cp 12
 jr c,.clear
.block
 scf
 ret
.clear
 and a
 ret

JohtoRoute39CanStepAhead::
 ld a,[wCurRegion]
 cp MAP_REGION_JOHTO
 jr nz,.block
 ld a,[wCurLocalMapID]
 cp JOHTO_ROUTE_39_LOCAL_ID
 jr nz,.block
 ld a, [wPlayerDirection]
 cp PLAYER_DIR_RIGHT
 jr nz,.south
 ld a, [wXCoord]
 cp JOHTO_ROUTE_39_WIDTH * 2 - 1
 jr nz,.mask
 ld a, [wYCoord]
 cp 8
 jr c,.mask
 cp 12
 jr c,.clear
.south
 ld a, [wPlayerDirection]
 cp PLAYER_DIR_DOWN
 jr nz,.mask
 ld a, [wYCoord]
 cp JOHTO_ROUTE_39_HEIGHT * 2 - 1
 jr nz,.mask
 ld a, [wXCoord]
 cp 8
 jr c,.mask
 cp 12
 jr c,.clear
.mask
 ld hl,JohtoRoute39BlockedRows
 ld d,JOHTO_ROUTE_39_WIDTH * 2
 ld e,3
 jp JohtoModernMaskedStep
.clear
 and a
 ret
.block
 scf
 ret
JohtoRoute39BlockedRows::
 INCBIN "maps/JohtoRoute39.blocked_mask.bin"

JohtoOlivineCityEdgeFence::
 ld a, [wPlayerDirection]
 cp PLAYER_DIR_UP
 jr z,.north
 cp PLAYER_DIR_DOWN
 jr z,.south
 cp PLAYER_DIR_LEFT
 jr z,.west
 cp PLAYER_DIR_RIGHT
 jr nz,.clear
 ld a, [wXCoord]
 cp JOHTO_OLIVINE_CITY_WIDTH * 2 - 1
 jr nc,.block
 jr .clear
.west
 ld a, [wXCoord]
 and a
 jr nz,.clear
 ld a, [wYCoord]
 cp 20
 jr z,.clear ; Gold paired FLOOR land lane
 cp 22
 jr c,.block
 cp 32
 jr c,.clear ; y22..25 FLOOR plus y26..31 WATER
 jr .block ; buoy/wall on the remaining shared sea border
.south
 ld a, [wYCoord]
 cp JOHTO_OLIVINE_CITY_HEIGHT * 2 - 1
 jr nc,.block ; route south remains unconnected
 jr .clear
.north
 ld a, [wYCoord]
 and a
 jr nz,.clear
 ld a, [wXCoord]
 cp 18
 jr c,.block
 cp 22
 jr c,.clear
.block
 scf
 ret
.clear
 and a
 ret

JohtoOlivineCityCanStepAhead::
 ld a,[wCurRegion]
 cp MAP_REGION_JOHTO
 jr nz,.block
 ld a,[wCurLocalMapID]
 cp JOHTO_OLIVINE_CITY_LOCAL_ID
 jr nz,.block
 ; West connection: land y20 and y22..25 in both Gold maps.
 ; Do not open WATER y26..31 to walking; Surf owns those lanes.
 ld a, [wPlayerDirection]
 cp PLAYER_DIR_LEFT
 jr nz,.northRoad
 ld a, [wXCoord]
 and a
 jr nz,.northRoad
 ld a, [wYCoord]
 cp 20
 jr z,.clear
 cp 22
 jr c,.northRoad
 cp 26
 jr c,.clear
.northRoad
 ; The north connection can enter from the four Gold road cells only.
 ld a, [wPlayerDirection]
 cp PLAYER_DIR_UP
 jr nz,.mask
 ld a, [wYCoord]
 and a
 jr nz,.mask
 ld a, [wXCoord]
 cp 18
 jr c,.mask
 cp 22
 jr c,.clear
.mask
 ld hl,JohtoOlivineCityBlockedRows
 ld d,JOHTO_OLIVINE_CITY_WIDTH * 2
 ld e,5
 jp JohtoModernMaskedStep
.clear
 and a
 ret
.block
 scf
 ret
JohtoOlivineCityBlockedRows::
 INCBIN "maps/JohtoOlivineCity.blocked_mask.bin"

; West-line A: Gold Route38 40x18 quadrant mask, no Surf/Cut to open.
; Route39 is unregistered; the west edge is physically closed.
; City side is visible but the road must pass through the paired gate Warp.
; SPID.234 source-verified ocean connections. Only shared WATER seam cells
; open; BUOY / wall and all unbuilt edges stay blocked.
JohtoRoute40EdgeFence::
 ld a, [wPlayerDirection]
 cp PLAYER_DIR_DOWN
 jr z,.south
 cp PLAYER_DIR_RIGHT
 jr z,.east
 cp PLAYER_DIR_UP
 jr z,.north
 ld a, [wXCoord]
 and a
 jr z,.block
 jr .clear
.north
 ld a, [wYCoord]
 and a
 jr z,.block
 jr .clear
.east
 ld a, [wXCoord]
 cp JOHTO_ROUTE_40_WIDTH * 2 - 1
 jr c,.clear
 ld a, [wYCoord]
 cp 2
 jr z,.clear ; Gold land pair y2
 cp 4
 jr c,.block
 cp 14
 jr c,.clear ; land y4..7 and water y8..13
 jr .block
.south
 ld a, [wYCoord]
 cp JOHTO_ROUTE_40_HEIGHT * 2 - 1
 jr c,.clear
 ld a, [wXCoord]
 cp 2
 jr c,.block
 cp 19
 jr c,.clear
.block
 scf
 ret
.clear
 and a
 ret

JohtoRoute41EdgeFence::
 ld a, [wPlayerDirection]
 cp PLAYER_DIR_UP
 jr z,.north
 cp PLAYER_DIR_LEFT
 jr z,.west
 cp PLAYER_DIR_DOWN
 jr z,.south
 ld a, [wXCoord]
 cp JOHTO_ROUTE_41_WIDTH * 2 - 1
 jr nc,.block
 jr .clear
.south
 ld a, [wYCoord]
 cp JOHTO_ROUTE_41_HEIGHT * 2 - 1
 jr nc,.block
 jr .clear
.north
 ld a, [wYCoord]
 and a
 jr nz,.clear
 ld a, [wXCoord]
 cp 32
 jr c,.block
 cp 49
 jr c,.clear
 jr .block
.west
 ld a, [wXCoord]
 and a
 jr nz,.clear
 ld a, [wYCoord]
 and a
 jr z,.block
 cp 46
 jr c,.clear
.block
 scf
 ret
.clear
 and a
 ret

JohtoCianwoodCityEdgeFence::
 ld a, [wPlayerDirection]
 cp PLAYER_DIR_RIGHT
 jr z,.east
 cp PLAYER_DIR_UP
 jr z,.north
 cp PLAYER_DIR_DOWN
 jr z,.south
 ld a, [wXCoord]
 and a
 jr z,.block
 jr .clear
.north
 ld a, [wYCoord]
 and a
 jr z,.block
 jr .clear
.south
 ld a, [wYCoord]
 cp JOHTO_CIANWOOD_CITY_HEIGHT * 2 - 1
 jr nc,.block
 jr .clear
.east
 ld a, [wXCoord]
 cp JOHTO_CIANWOOD_CITY_WIDTH * 2 - 1
 jr c,.clear
 ld a, [wYCoord]
 and a
 jr z,.block
 cp 46
 jr c,.clear
.block
 scf
 ret
.clear
 and a
 ret

JohtoRoute38EdgeFence::
	ld a, [wPlayerDirection]
	cp PLAYER_DIR_LEFT
	jr z, .west
	cp PLAYER_DIR_RIGHT
	jr z, .east
	cp PLAYER_DIR_UP
	jr z, .north
	cp PLAYER_DIR_DOWN
	jr nz, .allowed
	ld a, [wYCoord]
	cp JOHTO_ROUTE_38_HEIGHT * 2 - 1
	jr nc, .blocked
	jr .allowed
.north
	ld a, [wYCoord]
	and a
	jr z, .blocked
	jr .allowed
.west
	ld a, [wXCoord]
 and a
 jr nz, .allowed
 ld a, [wYCoord]
 cp 8
 jr c, .blocked
 cp 12
 jr nc, .blocked
 jr .allowed
.east
	ld a, [wXCoord]
	cp JOHTO_ROUTE_38_WIDTH * 2 - 1
	jr nc, .blocked
.allowed
	and a
	ret
.blocked
	scf
	ret

JohtoRoute38CanStepAhead::
	ld a, [wCurRegion]
	cp MAP_REGION_JOHTO
	jr nz, .blocked
	ld a, [wCurLocalMapID]
	cp JOHTO_ROUTE_38_LOCAL_ID
	jr nz, .blocked
 ; West boundary is an open 4-tile Gold lane into Route39.
 ld a, [wPlayerDirection]
 cp PLAYER_DIR_LEFT
 jr nz, .checkRightGate
 ld a, [wXCoord]
 and a
 jr nz, .checkRightGate
 ld a, [wYCoord]
 cp 8
 jr c, .checkRightGate
 cp 12
 jp c, .allowed
.checkRightGate
	; Gold RIGHT_WARP_CARPET: enter from x34 y8/9 and then exit
	; toward x36 through existing collision-based warp check.
	ld a, [wPlayerDirection]
	cp PLAYER_DIR_RIGHT
	jr nz, .normal
	ld a, [wXCoord]
	cp 34
	jr nz, .normal
	ld a, [wYCoord]
	cp 8
	jr z, .allowed
	cp 9
	jr z, .allowed
.normal
	; The paired outside door mats permit y8 <-> y9 travel. Their
	; outward RIGHT collision still enters the gate, never STEP_ON.
	ld a, [wXCoord]
	cp 35
	jr nz, .maskRoute38
	ld a, [wPlayerDirection]
	cp PLAYER_DIR_DOWN
	jr z, .matDown
	cp PLAYER_DIR_UP
	jr nz, .maskRoute38
	ld a, [wYCoord]
	cp 9
	jr z, .allowed
	jr .maskRoute38
.matDown
	ld a, [wYCoord]
	cp 8
	jr z, .allowed
	; Gold's floor above the upper carpet must be able to step DOWN
	; onto the carpet without triggering a Warp.
	cp 7
	jr z, .allowed
.maskRoute38
	ld hl, JohtoRoute38BlockedRows
	ld d, JOHTO_ROUTE_38_WIDTH * 2
	ld e, 5
	jp JohtoModernMaskedStep
.allowed
	and a
	ret
.blocked
	scf
	ret

JohtoRoute38BlockedRows::
	INCBIN "maps/JohtoRoute38.blocked_mask.bin"

; Same Gold EastWestGate 10x8 collision geometry as the accepted Violet gate.
JohtoRoute38EcruteakGateCanStepAhead::
	ld a, [wCurRegion]
	cp MAP_REGION_JOHTO
	jr nz, .blocked
	ld a, [wCurLocalMapID]
	cp JOHTO_ROUTE_38_ECRUTEAK_GATE_LOCAL_ID
	jr nz, .blocked
	ld a, [wYCoord]
	cp 4
	jr z, .lane
	cp 5
	jr nz, .normal
.lane
	ld a, [wPlayerDirection]
	cp PLAYER_DIR_LEFT
	jr z, .left
	cp PLAYER_DIR_RIGHT
	jr nz, .normal
	ld a, [wXCoord]
	cp 8
	jr z, .allowed
	jr .normal
.left
	ld a, [wXCoord]
	cp 1
	jr z, .allowed
.normal
	; Gold EastWestGate: both carpet lanes are walkable UP/DOWN. They
	; trigger a Warp ONLY on the corresponding blocked LEFT/RIGHT exit.
	ld a, [wXCoord]
	and a
	jr z, .matVertical
	cp 9
	jr nz, .maskGate
.matVertical
	ld a, [wPlayerDirection]
	cp PLAYER_DIR_DOWN
	jr z, .matDown
	cp PLAYER_DIR_UP
	jr nz, .maskGate
	ld a, [wYCoord]
	cp 5
	jr z, .allowed
	; The Gold floor below the carpet is not a wall.
	cp 6
	jr z, .allowed
	jr .maskGate
.matDown
	ld a, [wYCoord]
	cp 4
	jr z, .allowed
	; Same for the floor immediately above the upper carpet.
	cp 3
	jr z, .allowed
.maskGate
	ld hl, JohtoRoute38EcruteakGateBlockedRows
	ld d, JOHTO_ROUTE_38_ECRUTEAK_GATE_WIDTH * 2
	ld e, 2
	jp JohtoModernMaskedStep
.allowed
	and a
	ret
.blocked
	scf
	ret

JohtoRoute38EcruteakGateBlockedRows::
	INCBIN "maps/JohtoRoute38EcruteakGate.blocked_mask.bin"

; Same Gold EastWestGate 10x8 collision geometry as the accepted Violet gate.
JohtoRoute42EcruteakGateCanStepAhead::
	ld a, [wCurRegion]
	cp MAP_REGION_JOHTO
	jr nz, .blocked
	ld a, [wCurLocalMapID]
	cp JOHTO_ROUTE_42_ECRUTEAK_GATE_LOCAL_ID
	jr nz, .blocked
	ld a, [wYCoord]
	cp 4
	jr z, .lane
	cp 5
	jr nz, .normal
.lane
	ld a, [wPlayerDirection]
	cp PLAYER_DIR_LEFT
	jr z, .left
	cp PLAYER_DIR_RIGHT
	jr nz, .normal
	ld a, [wXCoord]
	cp 8
	jr z, .allowed
	jr .normal
.left
	ld a, [wXCoord]
	cp 1
	jr z, .allowed
.normal
	; Gold EastWestGate: both carpet lanes are walkable UP/DOWN. They
	; trigger a Warp ONLY on the corresponding blocked LEFT/RIGHT exit.
	ld a, [wXCoord]
	and a
	jr z, .matVertical
	cp 9
	jr nz, .maskGate
.matVertical
	ld a, [wPlayerDirection]
	cp PLAYER_DIR_DOWN
	jr z, .matDown
	cp PLAYER_DIR_UP
	jr nz, .maskGate
	ld a, [wYCoord]
	cp 5
	jr z, .allowed
	; The Gold floor below the carpet is not a wall.
	cp 6
	jr z, .allowed
	jr .maskGate
.matDown
	ld a, [wYCoord]
	cp 4
	jr z, .allowed
	; Same for the floor immediately above the upper carpet.
	cp 3
	jr z, .allowed
.maskGate
	ld hl, JohtoRoute42EcruteakGateBlockedRows
	ld d, JOHTO_ROUTE_42_ECRUTEAK_GATE_WIDTH * 2
	ld e, 2
	jp JohtoModernMaskedStep
.allowed
	and a
	ret
.blocked
	scf
	ret

JohtoRoute42EcruteakGateBlockedRows::
	INCBIN "maps/JohtoRoute42EcruteakGate.blocked_mask.bin"

; Route37 Gold 20x18 per-quadrant mask; north to Ecruteak only x7/8.
JohtoRoute37EdgeFence::
	ld a, [wPlayerDirection]
	cp PLAYER_DIR_DOWN
	jr z, .south
	cp PLAYER_DIR_UP
	jr z, .north
	cp PLAYER_DIR_LEFT
	jr z, .west
	cp PLAYER_DIR_RIGHT
	jr nz, .clear
	ld a, [wXCoord]
	cp JOHTO_ROUTE_37_WIDTH * 2 - 1
	jr nc, .blocked
	jr .clear
.north
	ld a, [wYCoord]
	and a
	jr nz, .clear
	ld a, [wXCoord]
	cp 7
	jr c, .blocked
	cp 9
	jr nc, .blocked
	jr .clear
.west
	ld a, [wXCoord]
	and a
	jr z, .blocked
	jr .clear
.south
	ld a, [wYCoord]
	cp JOHTO_ROUTE_37_HEIGHT * 2 - 1
	jr c, .clear
	ld a, [wXCoord]
	cp 5
	jr c, .blocked
	cp 13
	jr nc, .blocked
.clear
	and a
	ret
.blocked
	scf
	ret

JohtoRoute37CanStepAhead::
	ld a, [wCurRegion]
	cp MAP_REGION_JOHTO
	jr nz, .blocked
	ld a, [wCurLocalMapID]
	cp JOHTO_ROUTE_37_LOCAL_ID
	jr nz, .blocked
	ld a, [wPlayerDirection]
	cp PLAYER_DIR_UP
	jr nz, .checkDown
	ld a, [wYCoord]
	and a
	jr nz, .normal
	ld a, [wXCoord]
	cp 7
	jr z, .allowed
	cp 8
	jr z, .allowed
.checkDown
	ld a, [wPlayerDirection]
	cp PLAYER_DIR_DOWN
	jr nz, .normal
	ld a, [wYCoord]
	cp JOHTO_ROUTE_37_HEIGHT * 2 - 1
	jr nz, .normal
	ld a, [wXCoord]
	cp 5
	jr c, .normal
	cp 13
	jr c, .allowed
.normal
	ld hl, JohtoRoute37BlockedRows
	ld d, JOHTO_ROUTE_37_WIDTH * 2
	ld e, 3
	jp JohtoModernMaskedStep
.allowed
	and a
	ret
.blocked
	scf
	ret

JohtoRoute37BlockedRows::
	INCBIN "maps/JohtoRoute37.blocked_mask.bin"

; R35-5.62.223: Gold 20x36 collision mask, no HOP cells.
; North x17 is the only active border; unfinished gates are sealed.
JohtoRoute35EdgeFence::
	ld a, [wPlayerDirection]
	cp PLAYER_DIR_UP
	jr z, .north
	cp PLAYER_DIR_DOWN
	jr z, .south
	cp PLAYER_DIR_LEFT
	jr z, .west
	cp PLAYER_DIR_RIGHT
	jr nz, .clear
	ld a, [wXCoord]
	cp JOHTO_ROUTE_35_WIDTH * 2 - 1
	jr nc, .block
	jr .clear
.north
	ld a, [wYCoord]
	and a
	jr nz, .clear
	ld a, [wXCoord]
	cp 17
	jr z, .clear
	jr .block
.south
	ld a, [wYCoord]
	cp JOHTO_ROUTE_35_HEIGHT * 2 - 1
	jr nc, .block
	jr .clear
.west
	ld a, [wXCoord]
	and a
	jr z, .block
.clear
	and a
	ret
.block
	scf
	ret

JohtoRoute35CanStepAhead::
	ld a, [wCurRegion]
	cp MAP_REGION_JOHTO
	jp nz, .blocked
	ld a, [wCurLocalMapID]
	cp JOHTO_ROUTE_35_LOCAL_ID
	jp nz, .blocked
	ld a, [wPlayerDirection]
	cp PLAYER_DIR_UP
	jr nz, .checkSouthGate
	ld a, [wYCoord]
	and a
	jr nz, .checkSouthGate
	ld a, [wXCoord]
	cp 17
	jr z, .allowed
.checkSouthGate
	; GATE-5.62.224: only the two Gold south gate carpet cells are
	; permitted from the north (and permit lane changing on the carpet).
	; Do not unblock the National Park entrance (3,5).
	ld a, [wYCoord]
	cp 32
	jr z, .southGateApproach
	cp 33
	jr nz, .normal
	ld a, [wXCoord]
	cp 9
	jr z, .southGateLaneLeft
	cp 10
	jr nz, .normal
	ld a, [wPlayerDirection]
	cp PLAYER_DIR_LEFT
	jr z, .allowed
	jr .normal
.southGateLaneLeft
	ld a, [wPlayerDirection]
	cp PLAYER_DIR_RIGHT
	jr z, .allowed
	jr .normal
.southGateApproach
	ld a, [wPlayerDirection]
	cp PLAYER_DIR_DOWN
	jr nz, .normal
	ld a, [wXCoord]
	cp 9
	jr z, .allowed
	cp 10
	jr z, .allowed
.normal
	; R35-5.62.223: the one CUT_TREE cell opens only after its live
	; metatile was replaced; the Gold mask remains unchanged on disk.
	call JohtoRoute35CutTreeCleared
	jr c, .allowed
	ld hl, JohtoRoute35BlockedRows
	ld d, JOHTO_ROUTE_35_WIDTH * 2
	ld e, 3
	jp JohtoModernMaskedStep
.allowed
	and a
	ret
.blocked
	scf
	ret

JohtoRoute35BlockedRows::
	INCBIN "maps/JohtoRoute35.blocked_mask.bin"

; R35-5.62.223: Gold Route35 CUT_TREE is the TOP-RIGHT quadrant
; (17,6) of metatile $5b at block coordinate (8,3).  New block $89 is
; $5b with only that 16x16 quadrant rendered as FLOOR ($05).
; Other quadrants, source .blk, headbutt trees and map connections persist.
; This uses the established Ilex Forest live-view Cut pointer (bank $43).
JohtoRoute35CutTreeInFront::
	call JohtoRoute35CutTreeFacing
	ret nc
	call JohtoCutFacingBlockPointer
	ld a, [hl]
	cp $5b
	jr z, .yes
	and a
	ret
.yes
	scf
	ret

JohtoRoute35CutTreeCleared::
	call JohtoRoute35CutTreeFacing
	ret nc
	call JohtoCutFacingBlockPointer
	ld a, [hl]
	cp $89
	jr z, .yes
	and a
	ret
.yes
	scf
	ret

JohtoRoute35RemoveCutTree::
	call JohtoRoute35CutTreeFacing
	ret nc
	call JohtoCutFacingBlockPointer
	ld a, [hl]
	cp $5b
	ret nz
	ld a, $89
	ld [hl], a
	ret

JohtoRoute35CutTreeFacing:
	ld a, [wCurMap]
	cp REGION_NATIVE_MAP_SLOT
	jp nz, .no
	ld a, [wCurRegion]
	cp MAP_REGION_JOHTO
	jp nz, .no
	ld a, [wCurLocalMapID]
	cp JOHTO_ROUTE_35_LOCAL_ID
	jp nz, .no
	ld a, [wXCoord]
	cp 17
	jr z, .sameX
	cp 16
	jr z, .left
	cp 18
	jr z, .right
	jr .no
.sameX
	ld a, [wYCoord]
	cp 5
	jr z, .fromAbove
	cp 7
	jr z, .fromBelow
	jr .no
.fromAbove
	ld a, [wPlayerDirection]
	cp PLAYER_DIR_DOWN
	jr z, .yes
	jr .no
.fromBelow
	ld a, [wPlayerDirection]
	cp PLAYER_DIR_UP
	jr z, .yes
	jr .no
.left
	ld a, [wYCoord]
	cp 6
	jr nz, .no
	ld a, [wPlayerDirection]
	cp PLAYER_DIR_RIGHT
	jr z, .yes
	jr .no
.right
	ld a, [wYCoord]
	cp 6
	jr nz, .no
	ld a, [wPlayerDirection]
	cp PLAYER_DIR_LEFT
	jr z, .yes
.no
	and a
	ret
.yes
	scf
	ret

; R33-5.62.191: can enter the precise Gold collision quadrant ahead.
; Input: wCurMap $FC / Johto local 9. Result: carry=blocked, clear=allowed.
; Call via callba; do not enter if not on the exact native Route33 map.
JohtoRoute33CanStepAhead::
	ld a, [wCurRegion]
	cp MAP_REGION_JOHTO
	jp nz, .blocked
	ld a, [wCurLocalMapID]
	cp JOHTO_ROUTE_33_LOCAL_ID
	jp nz, .blocked
	; Preserve the already accepted Gold cave mouth and north connection.
	ld a, [wXCoord]
	cp 11
	jr nz, .normalStep
	ld a, [wYCoord]
	cp 10
	jr nz, .normalStep
	ld a, [wPlayerDirection]
	cp PLAYER_DIR_UP
	jp z, .allowed
.normalStep
	ld a, [wPlayerDirection]
	cp PLAYER_DIR_LEFT
	jr nz, .northSeam
	ld a, [wXCoord]
	and a
	jr nz, .normal
	ld a, [wYCoord]
	cp 14
	jr c, .normal
	cp 16
	jr c, .allowed
.northSeam
	ld a, [wPlayerDirection]
	cp PLAYER_DIR_UP
	jr nz, .normal
	ld a, [wYCoord]
	and a
	jr nz, .normal
	ld a, [wXCoord]
	cp 15
	jr c, .allowed
.normal
	ld hl, JohtoRoute33BlockedRows
	ld d, JOHTO_ROUTE_33_WIDTH * 2
	ld e, 3
	jp JohtoModernMaskedStep
.allowed
	and a
	ret
.blocked
	scf
	ret

; The second map reuses exactly the same Gold position-mask logic.
; Its six DOOR/CAVE cells remain blocked because destination interiors are absent.
JohtoAzaleaCanStepAhead::
	ld a, [wCurRegion]
	cp MAP_REGION_JOHTO
	jr nz, .blocked
	ld a, [wCurLocalMapID]
	cp JOHTO_AZALEA_TOWN_LOCAL_ID
	jr nz, .blocked
	; GATE-5.62.202: the two Gold doorway carpet cells are a single
	; vertically walkable pair, although their Gold collision role is WARP.
	; Do not open north of y=10 or south of y=11 (both remain WALL).
	ld a, [wXCoord]
	cp 2
	jr nz, .enterGate
	ld a, [wYCoord]
	cp 10
	jr z, .upperCarpet
	cp 11
	jr nz, .enterGate
	ld a, [wPlayerDirection]
	cp PLAYER_DIR_UP
	jr z, .allowed
	jr .enterGate
.upperCarpet
	ld a, [wPlayerDirection]
	cp PLAYER_DIR_DOWN
	jr z, .allowed
.enterGate
	; Reuse the existing Gold path from x=3 towards the west doorway.
	; Other Gold doors/well remain blocked by the unchanged binary mask.
	ld a, [wPlayerDirection]
	cp PLAYER_DIR_LEFT
	jr nz, .eastConnection
	ld a, [wXCoord]
	cp 3
	jr nz, .eastConnection
	ld a, [wYCoord]
	cp 10
	jr z, .allowed
	cp 11
	jr z, .allowed
.eastConnection
	ld a, [wPlayerDirection]
	cp PLAYER_DIR_RIGHT
	jr nz, .normal
	ld a, [wXCoord]
	cp JOHTO_AZALEA_TOWN_WIDTH * 2 - 1
	jr nz, .normal
	ld a, [wYCoord]
	cp 14
	jr c, .normal
	cp 16
	jr c, .allowed
.normal
	ld hl, JohtoAzaleaBlockedRows
	ld d, JOHTO_AZALEA_TOWN_WIDTH * 2
	ld e, 5
	jp JohtoModernMaskedStep
.allowed
	and a
	ret
.blocked
	scf
	ret

 ; ROM0 relief (.224): all three previews live in the SAME ROMX Bank $43.
; One far-call from either map-load path replaces three far-calls, while
; preserving exactly their original order. Do not fold roof updates into
; this entry: connected-map roof graphics have a separate VRAM timing path.
PatchJohtoMapBordersAfterBlockLoad::
	call PatchJohtoAzaleaWestGateBorder
	call PatchJohtoGoldenrodNorthBorder
	call PatchJohtoMahoganyNorthBorder
	jp PatchJohtoRoute35SouthBorder

; GATE-5.62.202: render-only Azalea west border continuation. The Gold
; 20x9 in-map layout is untouched, as are collision and Warp coordinates.
; LoadTileBlockMap has filled the 3-block border. Only the west neighbor
; of Gold blocks (0,4) and (0,5) needs LEFT roof/wall halves, not clones.
; If the map header or dimensions change, revisit both offsets.
PatchJohtoAzaleaWestGateBorder::
	ld a, [wCurMap]
	cp REGION_NATIVE_MAP_SLOT
	ret nz
	ld a, [wCurRegion]
	cp MAP_REGION_JOHTO
	ret nz
	ld a, [wCurLocalMapID]
	cp JOHTO_AZALEA_TOWN_LOCAL_ID
	ret nz
	ld hl, wOverworldMap + (MAP_BORDER + 4) * (JOHTO_AZALEA_TOWN_WIDTH + 2 * MAP_BORDER) + MAP_BORDER - 1
	ld [hl], $08 ; Gold LEFT roof half, paired with (0,4) $09
	ld hl, wOverworldMap + (MAP_BORDER + 5) * (JOHTO_AZALEA_TOWN_WIDTH + 2 * MAP_BORDER) + MAP_BORDER - 1
	ld [hl], $1c ; Gold LEFT facade half, paired with (0,5) $1e
	ret

; ILEX-5.62.216: Gold Goldenrod north edge preview from original
; Route35 bottom three block rows. Display ONLY: Route35 remains unopened.
PatchJohtoGoldenrodNorthBorder::
	ld a, [wCurMap]
	cp REGION_NATIVE_MAP_SLOT
	ret nz
	ld a, [wCurRegion]
	cp MAP_REGION_JOHTO
	ret nz
	ld a, [wCurLocalMapID]
	cp JOHTO_GOLDENROD_CITY_LOCAL_ID
	ret nz
	ld de, .row0
	ld hl, wOverworldMap + MAP_BORDER + 5
	call .copyRow
	ld de, .row1
	ld hl, wOverworldMap + (JOHTO_GOLDENROD_CITY_WIDTH + 2 * MAP_BORDER) + MAP_BORDER + 5
	call .copyRow
	ld de, .row2
	ld hl, wOverworldMap + 2 * (JOHTO_GOLDENROD_CITY_WIDTH + 2 * MAP_BORDER) + MAP_BORDER + 5
.copyRow
	ld b, 10
.loop
	ld a, [de]
	inc de
	ld [hli], a
	dec b
	jr nz, .loop
	ret
.row0
	db $05, $05, $58, $59, $01, $78, $44, $05, $05, $05
.row1
	db $41, $41, $41, $42, $0c, $0d, $40, $41, $41, $41
.row2
	db $01, $01, $01, $46, $08, $09, $44, $01, $01, $01

; EAST ID64 north display-only preview: Gold Route43 last three block rows.
; Gold MahoganyTown <-> Route43 north/south offset 0 and shared JOHTO tileset.
; Route43/ID67 and the ID65 indoor gate are enabled by the .235 chain.
; The border buffer is outside the 10x9 city .blk: no new collision/Warp.
; Both LoadMapData and .ordinaryConnection call the shared border hook.
PatchJohtoMahoganyNorthBorder::
	ld a, [wCurMap]
	cp REGION_NATIVE_MAP_SLOT
	ret nz
	ld a, [wCurRegion]
	cp MAP_REGION_JOHTO
	ret nz
	ld a, [wCurLocalMapID]
	cp JOHTO_MAHOGANY_TOWN_LOCAL_ID
	ret nz
	ld de, .row0
	ld hl, wOverworldMap + MAP_BORDER
	call .copyRow
	ld de, .row1
	ld hl, wOverworldMap + (JOHTO_MAHOGANY_TOWN_WIDTH + 2 * MAP_BORDER) + MAP_BORDER
	call .copyRow
	ld de, .row2
	ld hl, wOverworldMap + 2 * (JOHTO_MAHOGANY_TOWN_WIDTH + 2 * MAP_BORDER) + MAP_BORDER
.copyRow
	ld b, JOHTO_MAHOGANY_TOWN_WIDTH
.loop
	ld a, [de]
	inc de
	ld [hli], a
	dec b
	jr nz, .loop
	ret
.row0
	db $71, $71, $71, $69, $01, $78, $05, $05, $6a, $71
.row1
	db $71, $71, $71, $69, $0c, $0d, $05, $05, $68, $71
.row2
	db $71, $71, $71, $69, $08, $09, $05, $05, $68, $71

; GATE-5.62.224 video correction: Gold Route35 has a SOUTH connection to
; GoldenrodCity at offset -5. The playable edge remains Warp-only here, but
; its three south OUT-OF-BOUNDS display rows must show the adjacent town, not
; Route35's default $05 forest border. The original city tileset is
; JOHTO_MODERN, whereas Route35 uses JOHTO: crosswalk their exact matching
; metatile layouts; the two unavailable modern-only IDs ($06 pavement and
; $67 building edge) use benign JOHTO ground/$12 roof approximations, never
; unsafe same-number JOHTO metatiles. This changes display WRAM ONLY; no
; in-map .blk, collision, connections, or Warp is changed.
PatchJohtoRoute35SouthBorder::
	ld a, [wCurMap]
	cp REGION_NATIVE_MAP_SLOT
	ret nz
	ld a, [wCurRegion]
	cp MAP_REGION_JOHTO
	ret nz
	ld a, [wCurLocalMapID]
	cp JOHTO_ROUTE_35_LOCAL_ID
	ret nz
	ld de, .row0
	ld hl, wOverworldMap + (MAP_BORDER + JOHTO_ROUTE_35_HEIGHT) * (JOHTO_ROUTE_35_WIDTH + 2 * MAP_BORDER) + MAP_BORDER
	call .copyRow
	ld de, .row1
	ld hl, wOverworldMap + (MAP_BORDER + JOHTO_ROUTE_35_HEIGHT + 1) * (JOHTO_ROUTE_35_WIDTH + 2 * MAP_BORDER) + MAP_BORDER
	call .copyRow
	ld de, .row2
	ld hl, wOverworldMap + (MAP_BORDER + JOHTO_ROUTE_35_HEIGHT + 2) * (JOHTO_ROUTE_35_WIDTH + 2 * MAP_BORDER) + MAP_BORDER
.copyRow
	ld b, JOHTO_ROUTE_35_WIDTH
.loop
	ld a, [de]
	inc de
	ld [hli], a
	dec b
	jr nz, .loop
	ret
.row0
	db $12, $15, $01, $46, $16, $1e, $44, $01, $01, $12
.row1
	db $01, $12, $15, $46, $01, $01, $44, $01, $01, $04
.row2
	db $15, $12, $18, $19, $01, $01, $18, $1f, $19, $02

; Shared 16x16 Gold block mask lookup; HL=mask, D=width cells, E=row bytes.
; Both current maps are 9 blocks (18 quadrants) high. The caller verifies map key.
JohtoModernMaskedStep::
	ld a, [wXCoord]
	ld c, a
	ld a, [wYCoord]
	ld b, a
	ld a, [wPlayerDirection]
	cp PLAYER_DIR_UP
	jr z, .up
	cp PLAYER_DIR_DOWN
	jr z, .down
	cp PLAYER_DIR_LEFT
	jr z, .left
	cp PLAYER_DIR_RIGHT
	jr nz, .blocked
	inc c
	jr .position
.left
	dec c
	jr .position
.down
	inc b
	jr .position
.up
	dec b
.position
	; ILEX-5.62.212: shared mask lookup takes the loaded map's actual cell height.
	; Route33/Azalea are 18 cells; Ilex Forest is 54 cells.
	ld a, [wCurrentMapHeight2]
	cp b
	jr z, .blocked
	jr c, .blocked
	ld a, c
	cp d
	jr nc, .blocked
	ld a, b
	ld d, 0
	and a
	jr z, .column
.row
	add hl, de
	dec a
	jr nz, .row
.column
	ld a, c
	ld b, a
	srl a
	srl a
	srl a
	ld e, a
	ld d, 0
	add hl, de
	ld c, [hl]
	ld a, b
	and 7
	ld b, a
	ld a, 1
	jr z, .maskReady
.shift
	add a
	dec b
	jr nz, .shift
.maskReady
	and c
	jr nz, .blocked
	and a
	ret
.blocked
	scf
	ret

; Audited against Gold Route33 20x18 16x16 collision map.
JohtoRoute33BlockedRows::
	INCBIN "maps/JohtoRoute33.blocked_mask.bin"

; MAP-5.62.195: same Gold modern data-driven collision, 40x18 cells.
JohtoAzaleaBlockedRows::
	INCBIN "maps/JohtoAzaleaTown.blocked_mask.bin"

; ILEX-5.62.216: only central four Gold FLOOR columns have a safe
; two-way Route34 <-> Goldenrod boundary. Every other outdoor edge is closed.
JohtoRoute34NorthEdgeFence::
	ld a, [wPlayerDirection]
	cp PLAYER_DIR_UP
	jr nz, .otherEdges
	ld a, [wYCoord]
	and a
	jr nz, .clear
	ld a, [wXCoord]
	cp 8
	jr c, .blocked
	cp 12
	jr nc, .blocked
	jr .clear
.otherEdges
	cp PLAYER_DIR_DOWN
	jr z, .south
	cp PLAYER_DIR_LEFT
	jr z, .west
	cp PLAYER_DIR_RIGHT
	jr nz, .clear
	ld a, [wXCoord]
	cp JOHTO_ROUTE_34_WIDTH * 2 - 1
	jr nc, .blocked
	jr .clear
.south
	ld a, [wYCoord]
	cp JOHTO_ROUTE_34_HEIGHT * 2 - 1
	jr nc, .blocked
	jr .clear
.west
	ld a, [wXCoord]
	and a
	jr z, .blocked
.clear
	and a
	ret
.blocked
	scf
	ret

JohtoGoldenrodEdgeFence::
	ld a, [wPlayerDirection]
	cp PLAYER_DIR_DOWN
	jr z, .south
	cp PLAYER_DIR_UP
	jr z, .north
	cp PLAYER_DIR_LEFT
	jr z, .west
	cp PLAYER_DIR_RIGHT
	jr nz, .clear
	ld a, [wXCoord]
	cp JOHTO_GOLDENROD_CITY_WIDTH * 2 - 1
	jr nc, .blocked
	jr .clear
.south
	ld a, [wYCoord]
	cp JOHTO_GOLDENROD_CITY_HEIGHT * 2 - 1
	jr c, .clear
	ld a, [wXCoord]
	cp 18
	jr c, .blocked
	cp 22
	jr nc, .blocked
	jr .clear
.north
	ld a, [wYCoord]
	and a
	jr z, .blocked
	jr .clear
.west
	ld a, [wXCoord]
	and a
	jr z, .blocked
.clear
	and a
	ret
.blocked
	scf
	ret

; ILEX-5.62.215: Route34 only uses the existing Gold 16x16 masked-step engine.
; Nonexistent Goldenrod and unfinished Azalea west-side connections stay closed.
JohtoRoute34CanStepAhead::
	ld a, [wCurRegion]
	cp MAP_REGION_JOHTO
	jp nz, .blocked
	ld a, [wCurLocalMapID]
	cp JOHTO_ROUTE_34_LOCAL_ID
	jp nz, .blocked
	; ILEX-5.62.216: central north seam uses the approved Gold floor
	; cells, despite the mask lookup seeing one step outside the map.
	ld a, [wYCoord]
	and a
	jr nz, .gate
	ld a, [wPlayerDirection]
	cp PLAYER_DIR_UP
	jr nz, .gate
	ld a, [wXCoord]
	cp 8
	jr c, .gate
	cp 12
	jp c, .allowed
.gate
	; Gold (13,37)/(14,37) are WARP_CARPET_DOWN (blocked in mask).
	; Admit just the two approaches from the north, and lateral lane shift.
	ld a, [wYCoord]
	cp 36
	jp nz, .atCarpet
	ld a, [wPlayerDirection]
	cp PLAYER_DIR_DOWN
	jp nz, .normal
	ld a, [wXCoord]
	cp 13
	jp z, .allowed
	cp 14
	jp z, .allowed
	jp .normal
.atCarpet
	cp 37
	jp nz, .normal
	ld a, [wXCoord]
	cp 13
	jp z, .leftLane
	cp 14
	jp nz, .normal
	ld a, [wPlayerDirection]
	cp PLAYER_DIR_LEFT
	jp z, .allowed
	jp .normal
.leftLane
	ld a, [wPlayerDirection]
	cp PLAYER_DIR_RIGHT
	jp z, .allowed
.normal
	ld hl, JohtoRoute34BlockedRows
	ld d, JOHTO_ROUTE_34_WIDTH * 2
	ld e, 3
	jp JohtoModernMaskedStep
.allowed
	and a
	ret
.blocked
	scf
	ret

; ILEX-5.62.216: exact Gold city blocked positions, 40x36 cells.
; Keep its 15 unimplemented door tiles solid; do not import their Warps.
JohtoGoldenrodCanStepAhead::
	ld a, [wCurRegion]
	cp MAP_REGION_JOHTO
	jr nz, .blocked
	ld a, [wCurLocalMapID]
	cp JOHTO_GOLDENROD_CITY_LOCAL_ID
	jr nz, .blocked
	; City warp #13 is the ONLY open north building door at (19,1).
	ld a, [wXCoord]
	cp 19
	jr nz, .southEdge
	ld a, [wYCoord]
	cp 2
	jr nz, .northCarpet
	ld a, [wPlayerDirection]
	cp PLAYER_DIR_UP
	jr z, .allowed
	jr .southEdge
.northCarpet
	cp 1
	jr nz, .southEdge
	ld a, [wPlayerDirection]
	cp PLAYER_DIR_DOWN
	jr z, .allowed
.southEdge
	ld a, [wYCoord]
	cp JOHTO_GOLDENROD_CITY_HEIGHT * 2 - 1
	jr nz, .normal
	ld a, [wPlayerDirection]
	cp PLAYER_DIR_DOWN
	jr nz, .normal
	ld a, [wXCoord]
	cp 18
	jr c, .normal
	cp 22
	jr c, .allowed
.normal
	ld hl, JohtoGoldenrodBlockedRows
	ld d, JOHTO_GOLDENROD_CITY_WIDTH * 2
	ld e, 5
	jp JohtoModernMaskedStep
.allowed
	and a
	ret
.blocked
	scf
	ret

JohtoGoldenrodBlockedRows::
	INCBIN "maps/JohtoGoldenrodCity.blocked_mask.bin"

JohtoRoute34BlockedRows::
	INCBIN "maps/JohtoRoute34.blocked_mask.bin"

; ILEX-5.62.215: only the new NorthSouthGate uses this Gold 16x16 role mask.
; Existing JOHTO_GATE / Kanto Gate_Coll and two accepted gate rooms unchanged.
JohtoRoute34GateCanStepAhead::
	ld a, [wCurRegion]
	cp MAP_REGION_JOHTO
	jp nz, .blocked
	ld a, [wCurLocalMapID]
	cp JOHTO_ROUTE34_ILEX_GATE_LOCAL_ID
	jr z, .gateOk
	cp JOHTO_ROUTE_43_MAHOGANY_GATE_LOCAL_ID
	jr z, .gateOk
	cp JOHTO_ROUTE_43_GATE_LOCAL_ID
	jr z, .gateOk
	cp JOHTO_ROUTE35_GOLDENROD_GATE_LOCAL_ID
	jp nz, .blocked
.gateOk
	; Gold lower warp carpet permits entry from the left/right floor cells
	; as well as moving between the two carpet lanes. Upper DOOR is stricter.
	ld a, [wYCoord]
	cp 7
	jp z, .bottomCarpet
	ld a, [wXCoord]
	cp 4
	jp z, .lane
	cp 5
	jp nz, .normal
.lane
	ld a, [wYCoord]
	cp 1
	jp nz, .bottomApproach
	ld a, [wPlayerDirection]
	cp PLAYER_DIR_UP
	jp z, .allowed
	jp .normal
.bottomApproach
	cp 6
	jp nz, .edgeLanes
	ld a, [wPlayerDirection]
	cp PLAYER_DIR_DOWN
	jp z, .allowed
	jp .normal
.edgeLanes
	and a
	jp nz, .normal
	; Upper door: lane change only, no sideways entry through its walls.
	ld a, [wPlayerDirection]
	cp PLAYER_DIR_LEFT
	jp nz, .topRight
	ld a, [wXCoord]
	cp 5
	jp z, .allowed
	jp .normal
.topRight
	cp PLAYER_DIR_RIGHT
	jp nz, .normal
	ld a, [wXCoord]
	cp 4
	jp z, .allowed
	jp .normal
.bottomCarpet
	ld a, [wPlayerDirection]
	cp PLAYER_DIR_LEFT
	jp nz, .bottomRight
	ld a, [wXCoord]
	cp 5
	jp z, .allowed
	cp 6
	jp z, .allowed
	jp .normal
.bottomRight
	cp PLAYER_DIR_RIGHT
	jp nz, .normal
	ld a, [wXCoord]
	cp 3
	jp z, .allowed
	cp 4
	jp z, .allowed
.normal
	ld hl, JohtoRoute34GateBlockedRows
	ld d, 10
	ld e, 2
	jp JohtoModernMaskedStep
.allowed
	and a
	ret
.blocked
	scf
	ret

JohtoRoute34GateBlockedRows::
	INCBIN "maps/JohtoRoute34IlexForestGate.blocked_mask.bin"
; New gate uses the byte-identical Gold NorthSouthGate collision role bitmap.

; Gold collision audit: only a solid DOOR is STEP_ON. A WARP_CARPET_* cell is
; standable and must wait for a correctly directed collision. Called ONLY after
; CheckWarpsNoCollisionLoop matched an actual Warp record and armed the
; standing bit. East/west gates remain collision-only. Carry = valid approach.
JohtoNorthGateStepWarpAllowed::
	ld a, [wCurRegion]
	cp MAP_REGION_JOHTO
	jp nz, .deny
	ld a, [wCurLocalMapID]
	cp JOHTO_ILEX_FOREST_LOCAL_ID
	jr z, .forest
	cp JOHTO_ROUTE34_ILEX_GATE_LOCAL_ID
	jr z, .gateVertical
	cp JOHTO_ROUTE35_GOLDENROD_GATE_LOCAL_ID
	jr z, .gateVertical
	cp JOHTO_ROUTE36_RUINS_GATE_LOCAL_ID
	jr z, .gateVertical
	cp JOHTO_ROUTE_43_MAHOGANY_GATE_LOCAL_ID
	jr z, .gateVertical
	cp JOHTO_ROUTE_43_GATE_LOCAL_ID
	jr z, .gateVertical
	cp JOHTO_RUINS_OF_ALPH_LOCAL_ID
	jr z, .ruinsOutside
	cp JOHTO_GOLDENROD_CITY_LOCAL_ID
	jr z, .cityNorthDoor
	; .235D: Gold's one-cell Mahogany DOOR behaves like Goldenrod's
	; north-facing solid door: stepping onto the Warp enters immediately.
	; Route43's paired WARP_CARPET_DOWN stays collision-only.
	cp JOHTO_MAHOGANY_TOWN_LOCAL_ID
	jr z, .mahoganyNorthDoor
	cp JOHTO_ROUTE_43_LOCAL_ID
	jr z, .route43MiddleDoor
	; All remaining directional carpets (including Route34's Gold y37
	; WARP_CARPET_DOWN and Route35's south mat) are collision-only.
	jp .deny
.ruinsOutside
	ld a, [wXCoord]
	cp 7
	jp nz, .deny
	ld a, [wYCoord]
	cp 5
	jr z, .up
	jp .deny
.gateVertical
	ld a, [wYCoord]
	and a
	jr z, .up
	jp .deny
.cityNorthDoor
	ld a, [wXCoord]
	cp 19
	jp nz, .deny
	ld a, [wYCoord]
	cp 1
	jr z, .up
	jp .deny
; Gold Route43 single north-facing DOOR at (17,35) must STEP_ON.
.route43MiddleDoor
 ld a, [wXCoord]
 cp 17
 jp nz, .deny
 ld a, [wYCoord]
 cp 35
 jr z, .up
 jp .deny
.mahoganyNorthDoor
	ld a, [wXCoord]
	cp 9
	jp nz, .deny
	ld a, [wYCoord]
	cp 1
	jr z, .up
	jp .deny
.forest
	ld a, [wYCoord]
	cp 5
	jr z, .up
	jp .deny
.up
	ld a, PLAYER_DIR_UP
	jr .match
.match
	ld b, a
	ld a, [wPlayerDirection]
	cp b
	jp nz, .deny
	scf
	ret
.deny
	and a
	ret

; ILEX-5.62.215: share one collision-only Warp rule across accepted old
; south gate and new north/south gate. Called only for registered Warp cells,
; with preserved region-local identity. carry = correct approach.
JohtoGateCollisionDirectionAllowed::
	ld a, [wCurLocalMapID]
	cp JOHTO_AZALEA_TOWN_LOCAL_ID
	jp z, .left
	cp JOHTO_ILEX_FOREST_LOCAL_ID
	jp z, .forest
	cp JOHTO_ROUTE_34_LOCAL_ID
	jp z, .route34Carpet
	cp JOHTO_ROUTE34_ILEX_GATE_LOCAL_ID
	jp z, .northGate
	cp JOHTO_ROUTE35_GOLDENROD_GATE_LOCAL_ID
	jp z, .northGate
	cp JOHTO_ROUTE36_RUINS_GATE_LOCAL_ID
	jp z, .northGate
	cp JOHTO_ROUTE_43_MAHOGANY_GATE_LOCAL_ID
	jp z, .northGate
	cp JOHTO_ROUTE_43_GATE_LOCAL_ID
	jp z, .northGate
	cp JOHTO_ROUTE_43_LOCAL_ID
	jp z, .route43South
	cp JOHTO_MAHOGANY_TOWN_LOCAL_ID
	jp z, .mahoganyNorth
	cp JOHTO_ROUTE_36_LOCAL_ID
	jp z, .ruinsRoute36
	cp JOHTO_RUINS_OF_ALPH_LOCAL_ID
	jp z, .ruinsOutside
	cp JOHTO_GOLDENROD_CITY_LOCAL_ID
	jp z, .cityNorth
	cp JOHTO_ROUTE_35_LOCAL_ID
	jp z, .route35South
	; Both Ecruteak gates share one city ID; dispatch by exact portal lane.
	cp JOHTO_ECRUTEAK_CITY_LOCAL_ID
	jp z, .ecruteakCityDoor
	cp JOHTO_ROUTE_38_LOCAL_ID
	jp z, .right
	cp JOHTO_ROUTE_38_ECRUTEAK_GATE_LOCAL_ID
	jp z, .ecruteakGate
	cp JOHTO_ROUTE_42_ECRUTEAK_GATE_LOCAL_ID
	jp z, .eastGate
	cp JOHTO_ROUTE_42_LOCAL_ID
	jp z, .route42WestDoor
	; Historical south gate west x0, east x9.
	ld a, [wXCoord]
	and a
	jp z, .left
	jp .right
.ecruteakCityDoor
	ld a, [wXCoord]
	and a
	jr z, .ecruteakCityWest
	cp 35
	jp nz, .denied
	ld a, [wYCoord]
	cp 26
	jp z, .right
	cp 27
	jp z, .right
	jp .denied
.ecruteakCityWest
	ld a, [wYCoord]
	cp 18
	jp z, .left
	cp 19
	jp z, .left
	jp .denied
.ecruteakGate
	ld a, [wXCoord]
	and a
	jp z, .left
	jp .right
.route42WestDoor
	ld a, [wXCoord]
	and a
	jp nz, .denied
	ld a, [wYCoord]
	cp 8
	jp z, .left
	cp 9
	jp z, .left
	jp .denied
.eastGate
	ld a, [wYCoord]
	cp 4
	jr z, .eastGateY
	cp 5
	jp nz, .denied
.eastGateY
	ld a, [wXCoord]
	and a
	jp z, .left
	cp 9
	jp z, .right
	jp .denied
.forest
	ld a, [wYCoord]
	cp 5
	jp z, .up
	jp .right
.cityNorth
	ld a, [wYCoord]
	cp 1
	jp nz, .denied
	ld a, [wXCoord]
	cp 19
	jp nz, .denied
	jp .up
.route35South
	ld a, [wYCoord]
	cp 33
	jp nz, .denied
	ld a, [wXCoord]
	cp 9
	jp z, .down
	cp 10
	jp z, .down
	jp .denied
.route34Carpet
	ld a, [wYCoord]
	cp 37
	jp nz, .denied
	ld a, [wXCoord]
	cp 13
	jp z, .down
	cp 14
	jp z, .down
	jp .denied
.route43South
 ld a, [wYCoord]
 cp 35
 jr z,.route43MiddleSouth
 cp 31
 jr z,.route43MiddleNorth
 cp 51
 jp nz,.denied
 ld a, [wXCoord]
 cp 9
 jr z,.down
 cp 10
 jr z,.down
 jp .denied
.route43MiddleSouth
 ld a, [wXCoord]
 cp 17
 jp nz,.denied
 jp .up
.route43MiddleNorth
 ld a, [wXCoord]
 cp 17
 jp z,.down
 cp 18
 jp z,.down
 jp .denied
.mahoganyNorth
 ld a, [wXCoord]
 cp 9
 jp nz,.denied
 ld a, [wYCoord]
 cp 1
 jp z,.up
 jp .denied
.northGate
	ld a, [wYCoord]
	and a
	jr z, .up
	jr .down
.ruinsRoute36
	ld a, [wYCoord]
	cp 13
	jp nz, .denied
	ld a, [wXCoord]
	cp 47
	jr z, .down
	cp 48
	jr z, .down
	jp .denied
.ruinsOutside
	ld a, [wYCoord]
	cp 5
	jp nz, .denied
	ld a, [wXCoord]
	cp 7
	jr z, .up
	jp .denied
.left
	ld a, PLAYER_DIR_LEFT
	jr .compare
.right
	ld a, PLAYER_DIR_RIGHT
	jr .compare
.up
	ld a, PLAYER_DIR_UP
	jr .compare
.down
	ld a, PLAYER_DIR_DOWN
.compare
	ld b, a
	ld a, [wPlayerDirection]
	cp b
	jp nz, .denied
	scf
	ret
.denied
	and a
	ret

; Gold Forest x1/y5 is one north door, unlike the historical south double
; mouth x3/y42-43. Route34 bottom entrance x13/14/y37 is also interior.
JohtoInternalDoorFacingCheck::
	ld a, [wCurLocalMapID]
	cp JOHTO_ILEX_FOREST_LOCAL_ID
	jp z, .forest
	cp JOHTO_ROUTE_34_LOCAL_ID
	jp z, .route34Interior
	cp JOHTO_GOLDENROD_CITY_LOCAL_ID
	jp z, .cityNorthInterior
	cp JOHTO_ROUTE_35_LOCAL_ID
	jp z, .route35SouthInterior
	cp JOHTO_ROUTE_36_LOCAL_ID
	jp z, .ruinsRoute36
	cp JOHTO_RUINS_OF_ALPH_LOCAL_ID
	jp z, .ruinsOutside
	; Keep west non-edge Route38 return exact as in .230.
	cp JOHTO_ROUTE_38_LOCAL_ID
	jp z, .route38Door
	; New east door in city, and west edge of Route42.
	cp JOHTO_ECRUTEAK_CITY_LOCAL_ID
	jp z, .ecruteakRight
	cp JOHTO_ROUTE_42_LOCAL_ID
	jp z, .route42Left
	cp JOHTO_MAHOGANY_TOWN_LOCAL_ID
	jp z, .mahoganyDoor
	cp JOHTO_ROUTE_43_LOCAL_ID
	jp z, .route43Door
	jp .denied
.mahoganyDoor
 ld a, [wXCoord]
 cp 9
 jp nz,.denied
 ld a, [wYCoord]
 cp 1
 jp nz,.denied
 ld a, [wPlayerDirection]
 cp PLAYER_DIR_UP
 jp z,.allowed
 jp .denied
.route43Door
 ld a, [wYCoord]
 cp 35
 jr z,.route43MiddleSouthDoor
 cp 31
 jr z,.route43MiddleNorthMat
 cp 51
 jp nz,.denied
 ld a, [wXCoord]
 cp 9
 jr z,.route43Down
 cp 10
 jp nz,.denied
.route43Down
 ld a, [wPlayerDirection]
 cp PLAYER_DIR_DOWN
 jp z,.allowed
 jp .denied
.route43MiddleSouthDoor
 ld a, [wXCoord]
 cp 17
 jp nz,.denied
 ld a, [wPlayerDirection]
 cp PLAYER_DIR_UP
 jp z,.allowed
 jp .denied
.route43MiddleNorthMat
 ld a, [wXCoord]
 cp 17
 jr z,.route43MiddleNorthDown
 cp 18
 jp nz,.denied
.route43MiddleNorthDown
 ld a, [wPlayerDirection]
 cp PLAYER_DIR_DOWN
 jp z,.allowed
 jp .denied
.route38Door
	ld a, [wXCoord]
	cp 35
	jp nz, .denied
	ld a, [wYCoord]
	cp 8
	jr z, .route38Right
	cp 9
	jp nz, .denied
.route38Right
	ld a, [wPlayerDirection]
	cp PLAYER_DIR_RIGHT
	jp z, .allowed
	jp .denied
.ecruteakRight
	ld a, [wXCoord]
	cp 35
	jp nz, .denied
	ld a, [wYCoord]
	cp 26
	jr z, .checkRight
	cp 27
	jp nz, .denied
.checkRight
	ld a, [wPlayerDirection]
	cp PLAYER_DIR_RIGHT
	jp z, .allowed
	jp .denied
.route42Left
	ld a, [wXCoord]
	and a
	jp nz, .denied
	ld a, [wYCoord]
	cp 8
	jr z, .checkLeft
	cp 9
	jp nz, .denied
.checkLeft
	ld a, [wPlayerDirection]
	cp PLAYER_DIR_LEFT
	jp z, .allowed
	jp .denied
.ruinsRoute36
	ld a, [wYCoord]
	cp 13
	jp nz, .denied
	ld a, [wXCoord]
	cp 47
	jr z, .ruinsDown
	cp 48
	jp nz, .denied
.ruinsDown
	ld a, [wPlayerDirection]
	cp PLAYER_DIR_DOWN
	jp z, .allowed
	jp .denied
.ruinsOutside
	ld a, [wXCoord]
	cp 7
	jp nz, .denied
	ld a, [wYCoord]
	cp 5
	jp nz, .denied
	ld a, [wPlayerDirection]
	cp PLAYER_DIR_UP
	jp z, .allowed
	jp .denied
.cityNorthInterior
	ld a, [wXCoord]
	cp 19
	jp nz, .denied
	ld a, [wYCoord]
	cp 1
	jp nz, .denied
	ld a, [wPlayerDirection]
	cp PLAYER_DIR_UP
	jr z, .allowed
	jp .denied
.route35SouthInterior
	ld a, [wYCoord]
	cp 33
	jp nz, .denied
	ld a, [wXCoord]
	cp 9
	jr z, .route35Down
	cp 10
	jp nz, .denied
.route35Down
	ld a, [wPlayerDirection]
	cp PLAYER_DIR_DOWN
	jr z, .allowed
	jp .denied
.route34Interior
	ld a, [wYCoord]
	cp 37
	jp nz, .denied
	ld a, [wXCoord]
	cp 13
	jr z, .routeDirection
	cp 14
	jp nz, .denied
.routeDirection
	ld a, [wPlayerDirection]
	cp PLAYER_DIR_DOWN
	jr z, .allowed
	jp .denied
.forest
	ld a, [wXCoord]
	cp 1
	jr nz, .southForest
	ld a, [wYCoord]
	cp 5
	jr nz, .southForest
	ld a, [wPlayerDirection]
	cp PLAYER_DIR_UP
	jr z, .allowed
	jp .denied
.southForest
	ld a, [wXCoord]
	cp 3
	jp nz, .denied
	ld a, [wYCoord]
	cp 42
	jr z, .southDirection
	cp 43
	jp nz, .denied
.southDirection
	ld a, [wPlayerDirection]
	cp PLAYER_DIR_RIGHT
	jp nz, .denied
.allowed
	scf
	ret
.denied
	and a
	ret

; RUINS-5.62.224: dispatch both new map masks inside ROMX.
JohtoRuinsCanStepAhead::
	ld a, [wCurLocalMapID]
	cp JOHTO_RUINS_OF_ALPH_LOCAL_ID
	jp z, JohtoRuinsOfAlphCanStepAhead
	jp JohtoRuinsGateCanStepAhead

; RUINS-5.62.224: dedicated Gold 20x36 spatial collision mask.
; Water remains mask-blocked on LAND; position-based Surf checks govern water.
; All ten unopened chamber/cave/research/east-gate doors remain blocked.
JohtoRuinsOfAlphCanStepAhead::
	ld a, [wCurRegion]
	cp MAP_REGION_JOHTO
	jr nz, .blocked
	ld a, [wCurLocalMapID]
	cp JOHTO_RUINS_OF_ALPH_LOCAL_ID
	jr nz, .blocked
	; The unique northern DOOR tile (x7,y5) must be entered from
	; (7,6) facing UP. Afterwards next UP collision initiates Warp.
	ld a, [wXCoord]
	cp 7
	jr nz, .mask
	ld a, [wYCoord]
	cp 6
	jr nz, .exitDoor
	ld a, [wPlayerDirection]
	cp PLAYER_DIR_UP
	jr z, .allowed
	jr .mask
.exitDoor
	cp 5
	jr nz, .mask
	ld a, [wPlayerDirection]
	cp PLAYER_DIR_DOWN
	jr z, .allowed
.mask
	ld hl, JohtoRuinsOfAlphBlockedRows
	ld d, JOHTO_RUINS_OF_ALPH_WIDTH * 2
	ld e, 3
	jp JohtoModernMaskedStep
.allowed
	and a
	ret
.blocked
	scf
	ret
JohtoRuinsOfAlphBlockedRows::
	INCBIN "maps/JohtoRuinsOfAlphOutside.blocked_mask.bin"

; Exact duplicate Gold NorthSouthGate collision mask, with its own map key.
; Route36 gate and Route34 gate share the same approved art and topology.
JohtoRuinsGateCanStepAhead::
	ld a, [wCurRegion]
	cp MAP_REGION_JOHTO
	jp nz, .blocked
	ld a, [wCurLocalMapID]
	cp JOHTO_ROUTE36_RUINS_GATE_LOCAL_ID
	jp nz, .blocked
	; Gold lower warp carpet permits entry from the left/right floor cells
	; as well as moving between the two carpet lanes. Upper DOOR is stricter.
	ld a, [wYCoord]
	cp 7
	jp z, .bottomCarpet
	ld a, [wXCoord]
	cp 4
	jp z, .lane
	cp 5
	jp nz, .normal
.lane
	ld a, [wYCoord]
	cp 1
	jp nz, .bottomApproach
	ld a, [wPlayerDirection]
	cp PLAYER_DIR_UP
	jp z, .allowed
	jp .normal
.bottomApproach
	cp 6
	jp nz, .edgeLanes
	ld a, [wPlayerDirection]
	cp PLAYER_DIR_DOWN
	jp z, .allowed
	jp .normal
.edgeLanes
	and a
	jp nz, .normal
	; Upper door: lane change only, no sideways entry through its walls.
	ld a, [wPlayerDirection]
	cp PLAYER_DIR_LEFT
	jp nz, .topRight
	ld a, [wXCoord]
	cp 5
	jp z, .allowed
	jp .normal
.topRight
	cp PLAYER_DIR_RIGHT
	jp nz, .normal
	ld a, [wXCoord]
	cp 4
	jp z, .allowed
	jp .normal
.bottomCarpet
	ld a, [wPlayerDirection]
	cp PLAYER_DIR_LEFT
	jp nz, .bottomRight
	ld a, [wXCoord]
	cp 5
	jp z, .allowed
	cp 6
	jp z, .allowed
	jp .normal
.bottomRight
	cp PLAYER_DIR_RIGHT
	jp nz, .normal
	ld a, [wXCoord]
	cp 3
	jp z, .allowed
	cp 4
	jp z, .allowed
.normal
	ld hl, JohtoRuinsGateBlockedRows
	ld d, 10
	ld e, 2
	jp JohtoModernMaskedStep
.allowed
	and a
	ret
.blocked
	scf
	ret

JohtoRuinsGateBlockedRows::
	INCBIN "maps/JohtoRoute36RuinsGate.blocked_mask.bin"

; ROM0-5.62.224: one banked entry for every native Johto land mask.
; Called from HOME only for (wCurMap=$FC, wCurRegion=Johto).
; E=1 for an exact recognized local ID; Carry=blocked, Carry clear=walkable.
; E=0 for an unrecognized local ID; HOME must run its unchanged generic mask.
; Each branch calls the ORIGINAL predicate (do not broaden its region/ID test).
; The last LD E does not change flags, so Carry survives through Bankswitch.
; Data-driven land collision for the new continuous sea maps.
JohtoRoute40CanStepAhead::
 ld a,[wCurRegion]
 cp MAP_REGION_JOHTO
 jr nz,.blocked
 ld a,[wCurLocalMapID]
 cp JOHTO_ROUTE_40_LOCAL_ID
 jr nz,.blocked
 ; EAST x19 has real Gold FLOOR lanes y2 and y4..7 toward Olivine.
 ; Else use the converted mask, including WATER/B UOY and walls.
 ld a, [wPlayerDirection]
 cp PLAYER_DIR_RIGHT
 jr nz,.mask
 ld a, [wXCoord]
 cp JOHTO_ROUTE_40_WIDTH * 2 - 1
 jr nz,.mask
 ld a, [wYCoord]
 cp 2
 jr z,.allowed
 cp 4
 jr c,.mask
 cp 8
 jr c,.allowed
.mask
 ld hl,JohtoRoute40BlockedRows
 ld d,JOHTO_ROUTE_40_WIDTH * 2
 ld e,3
 jp JohtoModernMaskedStep
.allowed
 and a
 ret
.blocked
 scf
 ret
JohtoRoute40BlockedRows::
 INCBIN "maps/JohtoRoute40.blocked_mask.bin"

JohtoRoute41CanStepAhead::
 ld a,[wCurRegion]
 cp MAP_REGION_JOHTO
 jr nz,.blocked
 ld a,[wCurLocalMapID]
 cp JOHTO_ROUTE_41_LOCAL_ID
 jr nz,.blocked
 ld hl,JohtoRoute41BlockedRows
 ld d,JOHTO_ROUTE_41_WIDTH * 2
 ld e,7
 jp JohtoModernMaskedStep
.blocked
 scf
 ret
JohtoRoute41BlockedRows::
 INCBIN "maps/JohtoRoute41.blocked_mask.bin"

JohtoCianwoodCityCanStepAhead::
 ld a,[wCurRegion]
 cp MAP_REGION_JOHTO
 jr nz,.blocked
 ld a,[wCurLocalMapID]
 cp JOHTO_CIANWOOD_CITY_LOCAL_ID
 jr nz,.blocked
 ld hl,JohtoCianwoodCityBlockedRows
 ld d,JOHTO_CIANWOOD_CITY_WIDTH * 2
 ld e,4
 jp JohtoModernMaskedStep
.blocked
 scf
 ret
JohtoCianwoodCityBlockedRows::
 INCBIN "maps/JohtoCianwoodCity.blocked_mask.bin"

; .235: Gold northbound chain, fail closed on every non-connecting edge.
; Native Gold Route43/Lake of Rage trees share one exact Cut implementation.
; Source cells: Route43 (2,28); Lake (23,4), (18,9), (11,12),
; (5,14), (6,21).  Metatiles $5b/$63 already have reviewed
; position-preserving clones $89/$8b.  New $67->$8c changes only
; its top-left Cut quadrant, retaining all neighboring Gold graphics.
JohtoRoute43LakeCutTreeInFront::
 call JohtoRoute43LakeCutTreeFacing
 ret nc
 ld a,[hl]
 cp d
 jr z,.yes
 and a
 ret
.yes
 scf
 ret

JohtoRoute43LakeCutTreeCleared::
 call JohtoRoute43LakeCutTreeFacing
 ret nc
 ld a,[hl]
 cp e
 jr z,.yes
 and a
 ret
.yes
 scf
 ret

JohtoRoute43LakeRemoveCutTree::
 call JohtoRoute43LakeCutTreeFacing
 ret nc
 ld a,[hl]
 cp d
 ret nz
 ld a,e
 ld [hl],a
 ret

; carry=1 exact Gold Cut quadrant ahead; HL=live metatile pointer,
; D=Gold original metatile, E=precise cleared metatile.
JohtoRoute43LakeCutTreeFacing:
 ld a,[wCurMap]
 cp REGION_NATIVE_MAP_SLOT
 jr nz,.no
 ld a,[wCurRegion]
 cp MAP_REGION_JOHTO
 jr nz,.no
 ld a,[wCurLocalMapID]
 cp JOHTO_ROUTE_43_LOCAL_ID
 jr z,.calculate
 cp JOHTO_LAKE_OF_RAGE_LOCAL_ID
 jr nz,.no
.calculate
 ld a, [wXCoord]
 ld b,a
 ld a, [wYCoord]
 ld c,a
 ld a, [wPlayerDirection]
 cp PLAYER_DIR_UP
 jr nz,.tryDown
 dec c
 jr .scan
.tryDown
 cp PLAYER_DIR_DOWN
 jr nz,.tryLeft
 inc c
 jr .scan
.tryLeft
 cp PLAYER_DIR_LEFT
 jr nz,.tryRight
 dec b
 jr .scan
.tryRight
 cp PLAYER_DIR_RIGHT
 jr nz,.no
 inc b
.scan
 ld hl,.goldCutTreeCells
.loop
 ld a,[hli]
 cp $ff
 jr z,.no
 ld d,a
 ld a,[wCurLocalMapID]
 cp d
 jr nz,.skip
 ld a,[hli]
 cp b
 jr nz,.skipThree
 ld a,[hli]
 cp c
 jr nz,.skipTwo
 ld a,[hli]
 ld d,a
 ld a,[hli]
 ld e,a
 push de
 call JohtoCutFacingBlockPointer
 pop de
 scf
 ret
.skip
 inc hl
.skipThree
 inc hl
.skipTwo
 inc hl
 inc hl
 jr .loop
.no
 and a
 ret
.goldCutTreeCells
 db JOHTO_ROUTE_43_LOCAL_ID, 2, 28, $67, $8c
 db JOHTO_LAKE_OF_RAGE_LOCAL_ID, 23, 4, $5b, $89
 db JOHTO_LAKE_OF_RAGE_LOCAL_ID, 18, 9, $63, $8b
 db JOHTO_LAKE_OF_RAGE_LOCAL_ID, 11, 12, $5b, $89
 db JOHTO_LAKE_OF_RAGE_LOCAL_ID, 5, 14, $5b, $89
 db JOHTO_LAKE_OF_RAGE_LOCAL_ID, 6, 21, $63, $8b
 db $ff

JohtoRoute43EdgeFence::
 ld a, [wPlayerDirection]
 cp PLAYER_DIR_UP
 jr z,.north
 cp PLAYER_DIR_DOWN
 jr z,.south
 cp PLAYER_DIR_LEFT
 jr z,.west
 ld a, [wXCoord]
 cp JOHTO_ROUTE_43_WIDTH * 2 - 1
 jr nc,.block
 jr .clear
.west
 ld a, [wXCoord]
 and a
 jr z,.block
 jr .clear
.north
 ld a, [wYCoord]
 and a
 jr nz,.clear
 ld a, [wXCoord]
 ; Gold has two separate walkable seams: west x0 and center x8..11.
 ; The west branch is the sole entrance to Lake of Rage's west shore.
 and a
 jr z, .clear
 cp 8
 jr c, .blocked
 cp 12
 jr nc, .blocked
 jr .clear
.south
 ld a, [wYCoord]
 cp JOHTO_ROUTE_43_HEIGHT * 2 - 1
 jr nc,.block ; Southern Gold row is a gate carpet, NOT seamless walking.
 jr .clear
.blocked
.block
 scf
 ret
.clear
 and a
 ret

JohtoLakeOfRageEdgeFence::
 ld a, [wPlayerDirection]
 cp PLAYER_DIR_DOWN
 jr z,.south
 cp PLAYER_DIR_LEFT
 jr z,.west
 cp PLAYER_DIR_UP
 jr z,.north
 ld a, [wXCoord]
 cp JOHTO_LAKE_OF_RAGE_WIDTH * 2 - 1
 jr nc,.block
 jr .clear
.west
 ld a, [wXCoord]
 and a
 jr z,.block
 jr .clear
.north
 ld a, [wYCoord]
 and a
 jr z,.block
 jr .clear
.south
 ld a, [wYCoord]
 cp JOHTO_LAKE_OF_RAGE_HEIGHT * 2 - 1
 jr c,.clear
 ld a, [wXCoord]
 ; Lake Gold south x10 joins Route43 north x0; x18..21 form the
 ; separate four-wide center exit. x11 faces a Headbutt tree: keep shut.
 cp 10
 jr z,.clear
 cp 18
 jr c,.block
 cp 22
 jr c,.clear
.block
 scf
 ret
.clear
 and a
 ret

JohtoRoute43CanStepAhead::
 ld a,[wCurRegion]
 cp MAP_REGION_JOHTO
 jp nz,.blocked
 ld a,[wCurLocalMapID]
 cp JOHTO_ROUTE_43_LOCAL_ID
 jp nz,.blocked
 ; North seam: exact four reciprocal Gold FLOOR cells.
 ld a, [wPlayerDirection]
 cp PLAYER_DIR_UP
 jr nz,.warpLane
 ld a, [wYCoord]
 and a
 jr nz,.warpLane
 ld a, [wXCoord]
 ; Both Gold FLOOR/FLOOR exits must bypass the off-map mask boundary.
 and a
 jp z,.allowed
 cp 8
 jr c,.warpLane
 cp 12
 jp c,.allowed
.warpLane
 ; Gold middle gate: single DOOR at (17,35) requires one UP step,
 ; paired WARP_CARPET_DOWN at (17/18,31) must allow stepping ON first.
 ld a,[wYCoord]
 cp 36
 jr nz,.middleCarpetApproach
 ld a,[wXCoord]
 cp 17
 jr nz,.middleCarpetApproach
 ld a, [wPlayerDirection]
 cp PLAYER_DIR_UP
 jp z,.allowed
.middleCarpetApproach
 ld a,[wYCoord]
 cp 30
 jr nz,.middleCarpetSide
 ld a,[wXCoord]
 cp 17
 jr z,.middleCarpetDown
 cp 18
 jr nz,.middleCarpetSide
.middleCarpetDown
 ld a, [wPlayerDirection]
 cp PLAYER_DIR_DOWN
 jr z,.allowed
.middleCarpetSide
 ld a,[wYCoord]
 cp 31
 jr nz,.middleCarpetDone
 ld a,[wXCoord]
 cp 17
 jr z,.middleCarpetRight
 cp 18
 jr nz,.middleCarpetDone
 ld a, [wPlayerDirection]
 cp PLAYER_DIR_LEFT
 jr z,.allowed
 jr .middleCarpetDone
.middleCarpetRight
 ld a, [wPlayerDirection]
 cp PLAYER_DIR_RIGHT
 jr z,.allowed
.middleCarpetDone
 ; Paired Gold warp carpets at y51 permit lateral movement, but
 ; southward edge exit remains a collision-only Warp into the gate.
 ld a, [wYCoord]
 cp 51
 jr nz, .enterCarpet
 ld a, [wXCoord]
 cp 9
 jr z, .carpetRight
 cp 10
 jr nz, .enterCarpet
 ld a, [wPlayerDirection]
 cp PLAYER_DIR_LEFT
 jr z, .allowed
 jr .enterCarpet
.carpetRight
 ld a, [wPlayerDirection]
 cp PLAYER_DIR_RIGHT
 jr z, .allowed
.enterCarpet
 ; Gold carpets have blocked mask bits; entering from y50 is safe.
 ld a, [wPlayerDirection]
 cp PLAYER_DIR_DOWN
 jr nz, .mask
 ld a, [wYCoord]
 cp 50
 jr nz, .mask
 ld a, [wXCoord]
 cp 9
 jr z, .allowed
 cp 10
 jr z, .allowed
.mask
 call JohtoRoute43LakeCutTreeCleared
 jr c,.allowed
 ld hl,JohtoRoute43BlockedRows
 ld d,JOHTO_ROUTE_43_WIDTH * 2
 ld e,3
 jp JohtoModernMaskedStep
.allowed
 and a
 ret
.blocked
 scf
 ret
JohtoRoute43BlockedRows::
 INCBIN "maps/JohtoRoute43.blocked_mask.bin"

JohtoLakeOfRageCanStepAhead::
 ld a,[wCurRegion]
 cp MAP_REGION_JOHTO
 jr nz,.blocked
 ld a,[wCurLocalMapID]
 cp JOHTO_LAKE_OF_RAGE_LOCAL_ID
 jr nz,.blocked
 ld a, [wPlayerDirection]
 cp PLAYER_DIR_DOWN
 jr nz,.mask
 ld a, [wYCoord]
 cp JOHTO_LAKE_OF_RAGE_HEIGHT * 2 - 1
 jr nz,.mask
 ld a, [wXCoord]
 cp 10
 jr z,.allowed
 cp 18
 jr c,.mask
 cp 22
 jr c,.allowed
.mask
 call JohtoRoute43LakeCutTreeCleared
 jr c,.allowed
 ld hl,JohtoLakeOfRageBlockedRows
 ld d,JOHTO_LAKE_OF_RAGE_WIDTH * 2
 ld e,5
 jp JohtoModernMaskedStep
.allowed
 and a
 ret
.blocked
 scf
 ret
JohtoLakeOfRageBlockedRows::
 INCBIN "maps/JohtoLakeOfRage.blocked_mask.bin"

JohtoNativeCanStepAhead::
	ld a, [wCurLocalMapID]
	cp JOHTO_ROUTE_35_LOCAL_ID
	jp z, .route35
	cp JOHTO_ROUTE_36_LOCAL_ID
	jp z, .route36
	cp JOHTO_ROUTE_37_LOCAL_ID
	jp z, .route37
	cp JOHTO_ROUTE_38_LOCAL_ID
 jp z, .route38
 cp JOHTO_ROUTE_39_LOCAL_ID
 jp z, .route39
 cp JOHTO_OLIVINE_CITY_LOCAL_ID
 jp z, .olivine
	cp JOHTO_ROUTE_38_ECRUTEAK_GATE_LOCAL_ID
	jp z, .route38Gate
	cp JOHTO_ROUTE_42_ECRUTEAK_GATE_LOCAL_ID
	jp z, .route42Gate
	cp JOHTO_ECRUTEAK_CITY_LOCAL_ID
	jp z, .ecruteak
	cp JOHTO_ROUTE_42_LOCAL_ID
	jp z, .route42
	cp JOHTO_MAHOGANY_TOWN_LOCAL_ID
	jp z, .mahogany
	cp JOHTO_ROUTE_33_LOCAL_ID
	jp z, .route33
	cp JOHTO_AZALEA_TOWN_LOCAL_ID
	jp z, .azalea
	cp JOHTO_ILEX_FOREST_LOCAL_ID
	jp z, .forest
	cp JOHTO_ROUTE34_ILEX_GATE_LOCAL_ID
	jp z, .gate
	cp JOHTO_ROUTE35_GOLDENROD_GATE_LOCAL_ID
	jp z, .gate
	cp JOHTO_ROUTE36_RUINS_GATE_LOCAL_ID
	jp z, .ruins
	cp JOHTO_RUINS_OF_ALPH_LOCAL_ID
	jp z, .ruins
	cp JOHTO_ROUTE_34_LOCAL_ID
	jp z, .route34
	cp JOHTO_GOLDENROD_CITY_LOCAL_ID
	jp z, .goldenrod
 cp JOHTO_ROUTE_40_LOCAL_ID
 jp z,.route40
 cp JOHTO_ROUTE_41_LOCAL_ID
 jp z,.route41
 cp JOHTO_CIANWOOD_CITY_LOCAL_ID
 jp z,.cianwood
 cp JOHTO_ROUTE_43_MAHOGANY_GATE_LOCAL_ID
 jp z,.gate
 cp JOHTO_ROUTE_43_GATE_LOCAL_ID
 jp z,.gate
 cp JOHTO_ROUTE_43_LOCAL_ID
 jp z,.route43
 cp JOHTO_LAKE_OF_RAGE_LOCAL_ID
 jp z,.lake
 ld e, 0
 ret
.route35
	call JohtoRoute35CanStepAhead
	jp .handled
.route36
	call JohtoRoute36CanStepAhead
	jp .handled
.route37
	call JohtoRoute37CanStepAhead
	jp .handled
.route38
 call JohtoRoute38CanStepAhead
 jp .handled
.route39
 call JohtoRoute39CanStepAhead
 jp .handled
.olivine
 call JohtoOlivineCityCanStepAhead
 jp .handled
.route38Gate
	call JohtoRoute38EcruteakGateCanStepAhead
	jp .handled
.route42Gate
	call JohtoRoute42EcruteakGateCanStepAhead
	jp .handled
.ecruteak
	call JohtoEcruteakCityCanStepAhead
	jp .handled
.route42
	call JohtoRoute42CanStepAhead
	jp .handled
.mahogany
	call JohtoMahoganyTownCanStepAhead
	jp .handled
.route33
	call JohtoRoute33CanStepAhead
	jp .handled
.azalea
	call JohtoAzaleaCanStepAhead
	jp .handled
.forest
	call JohtoIlexForestCanStepAhead
	jp .handled
.gate
	call JohtoRoute34GateCanStepAhead
	jp .handled
.ruins
	call JohtoRuinsCanStepAhead
	jp .handled
.route34
	call JohtoRoute34CanStepAhead
	jp .handled
.goldenrod
	call JohtoGoldenrodCanStepAhead
 jp .handled
.route40
 call JohtoRoute40CanStepAhead
 jp .handled
.route41
 call JohtoRoute41CanStepAhead
 jp .handled
.cianwood
 call JohtoCianwoodCityCanStepAhead
 jp .handled
.route43
 call JohtoRoute43CanStepAhead
 jp .handled
.lake
 call JohtoLakeOfRageCanStepAhead
 jp .handled
.handled
 ld e, 1
 ret

