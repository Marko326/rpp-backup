; Gold east corridor common engine policy, ROMX bank $47.
; Closed by default. A=0 blocked edge, 1 reviewed reciprocal seam, 2 interior.
; The source/landing collision roles are verified against both original Gold maps.
JohtoEastEdgeDecision::
 ld a,[wCurLocalMapID]
 cp JOHTO_ROUTE_44_LOCAL_ID
 jp z,.route44
 cp JOHTO_BLACKTHORN_CITY_LOCAL_ID
 jp z,.blackthorncity
 cp JOHTO_ROUTE_45_LOCAL_ID
 jp z,.route45
 cp JOHTO_ROUTE_46_LOCAL_ID
 jp z,.route46
 jp .edgeBlock
.route44
 ld a,[wPlayerDirection]
 cp PLAYER_DIR_LEFT
 jp z,.route44left
 cp PLAYER_DIR_RIGHT
 jp z,.route44right
 cp PLAYER_DIR_UP
 jp z,.route44up
 cp PLAYER_DIR_DOWN
 jp z,.route44down
 jp .edgeBlock
.route44left
 ld a,[wXCoord]
 and a
 jp nz,.interior
 ld a,[wYCoord]
 ld hl,.route44leftlist
 jp .lookup
.route44right
 ld a,[wXCoord]
 cp 59
 jp nz,.interior
 ld a,[wYCoord]
 ld hl,.route44rightlist
 jp .lookup
.route44up
 ld a,[wYCoord]
 and a
 jp nz,.interior
 ld a,[wXCoord]
 jp .edgeBlock
.route44down
 ld a,[wYCoord]
 cp 17
 jp nz,.interior
 ld a,[wXCoord]
 jp .edgeBlock
.blackthorncity
 ld a,[wPlayerDirection]
 cp PLAYER_DIR_LEFT
 jp z,.blackthorncityleft
 cp PLAYER_DIR_RIGHT
 jp z,.blackthorncityright
 cp PLAYER_DIR_UP
 jp z,.blackthorncityup
 cp PLAYER_DIR_DOWN
 jp z,.blackthorncitydown
 jp .edgeBlock
.blackthorncityleft
 ld a,[wXCoord]
 and a
 jp nz,.interior
 ld a,[wYCoord]
 ld hl,.blackthorncityleftlist
 jp .lookup
.blackthorncityright
 ld a,[wXCoord]
 cp 39
 jp nz,.interior
 ld a,[wYCoord]
 jp .edgeBlock
.blackthorncityup
 ld a,[wYCoord]
 and a
 jp nz,.interior
 ld a,[wXCoord]
 jp .edgeBlock
.blackthorncitydown
 ld a,[wYCoord]
 cp 35
 jp nz,.interior
 ld a,[wXCoord]
 ld hl,.blackthorncitydownlist
 jp .lookup
.route45
 ld a,[wPlayerDirection]
 cp PLAYER_DIR_LEFT
 jp z,.route45left
 cp PLAYER_DIR_RIGHT
 jp z,.route45right
 cp PLAYER_DIR_UP
 jp z,.route45up
 cp PLAYER_DIR_DOWN
 jp z,.route45down
 jp .edgeBlock
.route45left
 ld a,[wXCoord]
 and a
 jp nz,.interior
 ld a,[wYCoord]
 ld hl,.route45leftlist
 jp .lookup
.route45right
 ld a,[wXCoord]
 cp 19
 jp nz,.interior
 ld a,[wYCoord]
 jp .edgeBlock
.route45up
 ld a,[wYCoord]
 and a
 jp nz,.interior
 ld a,[wXCoord]
 ld hl,.route45uplist
 jp .lookup
.route45down
 ld a,[wYCoord]
 cp 89
 jp nz,.interior
 ld a,[wXCoord]
 jp .edgeBlock
.route46
 ld a,[wPlayerDirection]
 cp PLAYER_DIR_LEFT
 jp z,.route46left
 cp PLAYER_DIR_RIGHT
 jp z,.route46right
 cp PLAYER_DIR_UP
 jp z,.route46up
 cp PLAYER_DIR_DOWN
 jp z,.route46down
 jp .edgeBlock
.route46left
 ld a,[wXCoord]
 and a
 jp nz,.interior
 ld a,[wYCoord]
 jp .edgeBlock
.route46right
 ld a,[wXCoord]
 cp 19
 jp nz,.interior
 ld a,[wYCoord]
 ld hl,.route46rightlist
 jp .lookup
.route46up
 ld a,[wYCoord]
 and a
 jp nz,.interior
 ld a,[wXCoord]
 jp .edgeBlock
.route46down
 ld a,[wYCoord]
 cp 35
 jp nz,.interior
 ld a,[wXCoord]
 jp .edgeBlock
; Exact source coordinate whitelist; no orientation-wide permission.
.lookup
 ld c,a
.loop
 ld a,[hli]
 cp $ff
 jp z,.edgeBlock
 cp c
 jr nz,.loop
 ld a,1
 ret
.edgeBlock
 xor a
 ret
.interior
 ld a,2
 ret
.route44leftlist
 db 8, 9, 16, 17, $ff
.route44rightlist
 db 0, 1, 2, 3, 4, 5, 6, 16, 17, $ff
.blackthorncityleftlist
 db 18, 19, 20, 21, 22, 23, 24, 34, 35, $ff
.blackthorncitydownlist
 db 0, 1, 8, 9, 10, 11, 12, 13, $ff
.route45uplist
 db 0, 1, 8, 9, 10, 11, 12, 13, $ff
.route45leftlist
 db 72, 73, 74, 76, 77, 78, 79, 80, 81, 83, 84, 85, 86, 87, 88, 89, $ff
.route46rightlist
 db 0, 1, 2, 4, 5, 6, 7, 8, 9, 11, 12, 13, 14, 15, 16, 17, $ff

; Carry ABI for the ROM0 border interceptor.
JohtoEastEdgeFence::
 call JohtoEastEdgeDecision
 and a
 jr z,.blocked
 and a
 ret
.blocked
 scf
 ret

; E=0 if passable, E=1 if blocked. The caller restores real carry state.
JohtoEastCanStepAhead::
 call JohtoEastEdgeDecision
 cp 1
 jr z,.allowed
 and a
 jr z,.blocked
 ld a,[wCurLocalMapID]
 cp JOHTO_ROUTE_44_LOCAL_ID
 jp z,.maskRoute44
 cp JOHTO_BLACKTHORN_CITY_LOCAL_ID
 jp z,.maskBlackthornCity
 cp JOHTO_ROUTE_45_LOCAL_ID
 jp z,.maskRoute45
 cp JOHTO_ROUTE_46_LOCAL_ID
 jp z,.maskRoute46
 jp .blocked
.maskRoute44
 ld hl,JohtoRoute44BlockedRows
 ld d,60
 ld e,8
 jp JohtoEastMaskedStep
.maskBlackthornCity
 ld hl,JohtoBlackthornCityBlockedRows
 ld d,40
 ld e,5
 jp JohtoEastMaskedStep
.maskRoute45
 ld hl,JohtoRoute45BlockedRows
 ld d,20
 ld e,3
 jp JohtoEastMaskedStep
.maskRoute46
 ld hl,JohtoRoute46BlockedRows
 ld d,20
 ld e,3
 jp JohtoEastMaskedStep
.allowed
 xor a
 ld e,a
 ret
.blocked
 ld e,1
 ret

; Gold half-block 16x16 position mask. 1 = solid. Full bounds checks.
JohtoEastMaskedStep::
 ld a,[wXCoord]
 ld c,a
 ld a,[wYCoord]
 ld b,a
 ld a,[wPlayerDirection]
 cp PLAYER_DIR_UP
 jr z,.up
 cp PLAYER_DIR_DOWN
 jr z,.down
 cp PLAYER_DIR_LEFT
 jr z,.left
 cp PLAYER_DIR_RIGHT
 jr nz,.block
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
 ld a,[wCurrentMapHeight2]
 cp b
 jr z,.block
 jr c,.block
 ld a,c
 cp d
 jr nc,.block
 ld a,b
 ld d,0
 and a
 jr z,.column
.row
 add hl,de
 dec a
 jr nz,.row
.column
 ld a,c
 ld b,a
 srl a
 srl a
 srl a
 ld e,a
 ld d,0
 add hl,de
 ld c,[hl]
 ld a,b
 and 7
 ld b,a
 ld a,1
 jr z,.ready
.shift
 add a
 dec b
 jr nz,.shift
.ready
 and c
 jr nz,.block
 xor a
 ld e,a
 ret
.block
 ld e,1
 ret
JohtoRoute44BlockedRows:: INCBIN "maps/JohtoRoute44.blocked_mask.bin"
JohtoBlackthornCityBlockedRows:: INCBIN "maps/JohtoBlackthornCity.blocked_mask.bin"
JohtoRoute45BlockedRows:: INCBIN "maps/JohtoRoute45.blocked_mask.bin"
JohtoRoute46BlockedRows:: INCBIN "maps/JohtoRoute46.blocked_mask.bin"

; Called from original HandleLedges; E contains original joypad direction or zero.
JohtoEastHopDirection::
 ld e,0
 ld a,[wCurLocalMapID]
 cp JOHTO_ROUTE_44_LOCAL_ID
 jp z,.hopsRoute44
 cp JOHTO_BLACKTHORN_CITY_LOCAL_ID
 jp z,.hopsBlackthornCity
 cp JOHTO_ROUTE_45_LOCAL_ID
 jp z,.hopsRoute45
 cp JOHTO_ROUTE_46_LOCAL_ID
 jp z,.hopsRoute46
 ret
.hopsRoute44
 ld hl,JohtoRoute44HopList
 jp .look
.hopsBlackthornCity
 ld hl,JohtoBlackthornCityHopList
 jp .look
.hopsRoute45
 ld hl,JohtoRoute45HopList
 jp .look
.hopsRoute46
 ld hl,JohtoRoute46HopList
 jp .look
.look
 ld a,[wXCoord]
 ld b,a
 ld a,[wYCoord]
 ld c,a
 ld a,[wPlayerDirection]
 ld d,a
.loop
 ld a,[hli]
 cp $ff
 jr z,.miss
 cp b
 jr nz,.skipY
 ld a,[hli]
 cp c
 jr nz,.skipDir
 ld a,[hl]
 cp d
 jr z,.hit
 inc hl
 jr .loop
.skipY
 inc hl
.skipDir
 inc hl
 jr .loop
.hit
 ld a,d
 cp PLAYER_DIR_DOWN
 jr z,.hitDown
 cp PLAYER_DIR_LEFT
 jr z,.hitLeft
 cp PLAYER_DIR_RIGHT
 jr nz,.miss
 ld e,D_RIGHT
 ret
.hitLeft
 ld e,D_LEFT
 ret
.hitDown
 ld e,D_DOWN
 ret
.miss
 ld e,0
 ret
JohtoRoute44HopList::
 db 47, 6, PLAYER_DIR_LEFT
 db 47, 7, PLAYER_DIR_LEFT
 db 47, 8, PLAYER_DIR_LEFT
 db 51, 8, PLAYER_DIR_DOWN
 db 51, 8, PLAYER_DIR_LEFT
 db 52, 8, PLAYER_DIR_DOWN
 db 53, 8, PLAYER_DIR_DOWN
 db 54, 8, PLAYER_DIR_DOWN
 db 55, 8, PLAYER_DIR_DOWN
 db 56, 8, PLAYER_DIR_DOWN
 db 57, 8, PLAYER_DIR_DOWN
 db 47, 9, PLAYER_DIR_LEFT
 db 47, 10, PLAYER_DIR_LEFT
 db 47, 11, PLAYER_DIR_LEFT
 db 47, 12, PLAYER_DIR_DOWN
 db 47, 12, PLAYER_DIR_LEFT
 db 48, 12, PLAYER_DIR_DOWN
 db 50, 12, PLAYER_DIR_DOWN
 db 51, 12, PLAYER_DIR_DOWN
 db 52, 12, PLAYER_DIR_DOWN
 db 53, 12, PLAYER_DIR_DOWN
 db $ff
JohtoBlackthornCityHopList::
 db 34, 10, PLAYER_DIR_DOWN
 db 36, 10, PLAYER_DIR_DOWN
 db 37, 10, PLAYER_DIR_DOWN
 db 34, 14, PLAYER_DIR_DOWN
 db 36, 14, PLAYER_DIR_DOWN
 db 37, 14, PLAYER_DIR_DOWN
 db 10, 16, PLAYER_DIR_DOWN
 db 11, 16, PLAYER_DIR_DOWN
 db 12, 16, PLAYER_DIR_DOWN
 db 14, 16, PLAYER_DIR_DOWN
 db 15, 16, PLAYER_DIR_DOWN
 db 24, 16, PLAYER_DIR_DOWN
 db 25, 16, PLAYER_DIR_DOWN
 db 6, 20, PLAYER_DIR_DOWN
 db 7, 20, PLAYER_DIR_DOWN
 db 8, 20, PLAYER_DIR_DOWN
 db 10, 20, PLAYER_DIR_DOWN
 db 11, 20, PLAYER_DIR_DOWN
 db 16, 20, PLAYER_DIR_DOWN
 db 17, 20, PLAYER_DIR_DOWN
 db 18, 20, PLAYER_DIR_DOWN
 db 22, 20, PLAYER_DIR_DOWN
 db 23, 20, PLAYER_DIR_DOWN
 db 24, 20, PLAYER_DIR_DOWN
 db 25, 20, PLAYER_DIR_DOWN
 db 32, 20, PLAYER_DIR_DOWN
 db 34, 20, PLAYER_DIR_DOWN
 db 35, 20, PLAYER_DIR_DOWN
 db 6, 22, PLAYER_DIR_DOWN
 db 7, 22, PLAYER_DIR_DOWN
 db 8, 22, PLAYER_DIR_DOWN
 db 9, 22, PLAYER_DIR_DOWN
 db 10, 22, PLAYER_DIR_DOWN
 db 11, 22, PLAYER_DIR_DOWN
 db 12, 22, PLAYER_DIR_DOWN
 db 14, 22, PLAYER_DIR_DOWN
 db 15, 22, PLAYER_DIR_DOWN
 db 16, 22, PLAYER_DIR_DOWN
 db 17, 22, PLAYER_DIR_DOWN
 db 18, 22, PLAYER_DIR_DOWN
 db 19, 22, PLAYER_DIR_DOWN
 db 20, 22, PLAYER_DIR_DOWN
 db 21, 22, PLAYER_DIR_DOWN
 db 22, 22, PLAYER_DIR_DOWN
 db 23, 22, PLAYER_DIR_DOWN
 db 24, 22, PLAYER_DIR_DOWN
 db 25, 22, PLAYER_DIR_DOWN
 db $ff
JohtoRoute45HopList::
 db 10, 8, PLAYER_DIR_DOWN
 db 11, 8, PLAYER_DIR_DOWN
 db 12, 8, PLAYER_DIR_DOWN
 db 13, 8, PLAYER_DIR_DOWN
 db 14, 8, PLAYER_DIR_DOWN
 db 15, 8, PLAYER_DIR_DOWN
 db 10, 12, PLAYER_DIR_DOWN
 db 11, 12, PLAYER_DIR_DOWN
 db 16, 12, PLAYER_DIR_DOWN
 db 17, 12, PLAYER_DIR_DOWN
 db 10, 16, PLAYER_DIR_DOWN
 db 11, 16, PLAYER_DIR_DOWN
 db 16, 18, PLAYER_DIR_DOWN
 db 17, 18, PLAYER_DIR_DOWN
 db 6, 20, PLAYER_DIR_RIGHT
 db 6, 21, PLAYER_DIR_RIGHT
 db 2, 22, PLAYER_DIR_DOWN
 db 3, 22, PLAYER_DIR_DOWN
 db 4, 22, PLAYER_DIR_DOWN
 db 5, 22, PLAYER_DIR_DOWN
 db 6, 22, PLAYER_DIR_DOWN
 db 6, 22, PLAYER_DIR_RIGHT
 db 12, 24, PLAYER_DIR_DOWN
 db 13, 24, PLAYER_DIR_DOWN
 db 2, 28, PLAYER_DIR_DOWN
 db 3, 28, PLAYER_DIR_DOWN
 db 4, 28, PLAYER_DIR_DOWN
 db 5, 28, PLAYER_DIR_DOWN
 db 12, 28, PLAYER_DIR_DOWN
 db 13, 28, PLAYER_DIR_DOWN
 db 7, 32, PLAYER_DIR_LEFT
 db 7, 33, PLAYER_DIR_LEFT
 db 7, 34, PLAYER_DIR_DOWN
 db 7, 34, PLAYER_DIR_LEFT
 db 8, 34, PLAYER_DIR_DOWN
 db 9, 34, PLAYER_DIR_DOWN
 db 10, 34, PLAYER_DIR_DOWN
 db 11, 34, PLAYER_DIR_DOWN
 db 4, 40, PLAYER_DIR_DOWN
 db 5, 40, PLAYER_DIR_DOWN
 db 10, 44, PLAYER_DIR_DOWN
 db 11, 44, PLAYER_DIR_DOWN
 db 12, 44, PLAYER_DIR_DOWN
 db 13, 44, PLAYER_DIR_DOWN
 db 10, 46, PLAYER_DIR_DOWN
 db 11, 46, PLAYER_DIR_DOWN
 db 12, 46, PLAYER_DIR_DOWN
 db 13, 46, PLAYER_DIR_DOWN
 db 9, 50, PLAYER_DIR_LEFT
 db 9, 51, PLAYER_DIR_LEFT
 db 9, 52, PLAYER_DIR_DOWN
 db 9, 52, PLAYER_DIR_LEFT
 db 10, 52, PLAYER_DIR_DOWN
 db 11, 52, PLAYER_DIR_DOWN
 db 12, 52, PLAYER_DIR_DOWN
 db 13, 52, PLAYER_DIR_DOWN
 db 14, 52, PLAYER_DIR_DOWN
 db 15, 52, PLAYER_DIR_DOWN
 db 2, 54, PLAYER_DIR_DOWN
 db 3, 54, PLAYER_DIR_DOWN
 db 8, 58, PLAYER_DIR_DOWN
 db 9, 58, PLAYER_DIR_DOWN
 db 16, 58, PLAYER_DIR_DOWN
 db 17, 58, PLAYER_DIR_DOWN
 db 8, 60, PLAYER_DIR_DOWN
 db 9, 60, PLAYER_DIR_DOWN
 db 2, 62, PLAYER_DIR_DOWN
 db 3, 62, PLAYER_DIR_DOWN
 db 6, 64, PLAYER_DIR_RIGHT
 db 6, 65, PLAYER_DIR_RIGHT
 db 2, 66, PLAYER_DIR_DOWN
 db 3, 66, PLAYER_DIR_DOWN
 db 4, 66, PLAYER_DIR_DOWN
 db 5, 66, PLAYER_DIR_DOWN
 db 6, 66, PLAYER_DIR_DOWN
 db 6, 66, PLAYER_DIR_RIGHT
 db 14, 66, PLAYER_DIR_DOWN
 db 15, 66, PLAYER_DIR_DOWN
 db 16, 66, PLAYER_DIR_DOWN
 db 17, 66, PLAYER_DIR_DOWN
 db 12, 70, PLAYER_DIR_DOWN
 db 13, 70, PLAYER_DIR_DOWN
 db 3, 76, PLAYER_DIR_DOWN
 db 3, 76, PLAYER_DIR_LEFT
 db 4, 76, PLAYER_DIR_DOWN
 db 5, 76, PLAYER_DIR_DOWN
 db 10, 84, PLAYER_DIR_DOWN
 db 11, 84, PLAYER_DIR_DOWN
 db $ff
JohtoRoute46HopList::
 db 12, 10, PLAYER_DIR_DOWN
 db 13, 10, PLAYER_DIR_DOWN
 db 14, 10, PLAYER_DIR_DOWN
 db 15, 10, PLAYER_DIR_DOWN
 db 9, 12, PLAYER_DIR_LEFT
 db 9, 13, PLAYER_DIR_LEFT
 db 10, 14, PLAYER_DIR_DOWN
 db 11, 14, PLAYER_DIR_DOWN
 db 2, 18, PLAYER_DIR_DOWN
 db 3, 18, PLAYER_DIR_DOWN
 db 7, 20, PLAYER_DIR_LEFT
 db 7, 21, PLAYER_DIR_LEFT
 db 7, 22, PLAYER_DIR_DOWN
 db 7, 22, PLAYER_DIR_LEFT
 db 8, 22, PLAYER_DIR_DOWN
 db 9, 22, PLAYER_DIR_DOWN
 db 10, 22, PLAYER_DIR_DOWN
 db 11, 22, PLAYER_DIR_DOWN
 db 12, 22, PLAYER_DIR_DOWN
 db 13, 22, PLAYER_DIR_DOWN
 db $ff
