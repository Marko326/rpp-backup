EnterMapAnim:
	call InitFacingDirectionList
	ld a, $ec
	ld [wSpriteStateData1 + 4], a ; player's sprite Y screen position
	call Delay3
	push hl
	call GBFadeInFromWhite
	ld hl, wFlags_D733
	bit 7, [hl] ; used fly out of battle?
	res 7, [hl]
	jr nz, .flyAnimation
	ld a, SFX_TELEPORT_ENTER_1
	call PlaySound
	ld hl, wd732
	bit 4, [hl] ; used dungeon warp?
	res 4, [hl]
	pop hl
	jr nz, .dungeonWarpAnimation
	call PlayerSpinWhileMovingDown
	ld a, SFX_TELEPORT_ENTER_2
	call PlaySound
	call IsPlayerStandingOnWarpPadOrHole
	ld a, b
	and a
	jr nz, .done
; if the player is not standing on a warp pad or hole
	ld hl, wPlayerSpinInPlaceAnimFrameDelay
	xor a
	ld [hli], a ; wPlayerSpinInPlaceAnimFrameDelay
	inc a
	ld [hli], a ; wPlayerSpinInPlaceAnimFrameDelayDelta
	ld a, $8
	ld [hli], a ; wPlayerSpinInPlaceAnimFrameDelayEndValue
	ld [hl], $ff ; wPlayerSpinInPlaceAnimSoundID
	ld hl, wFacingDirectionList
	call PlayerSpinInPlace
.restoreDefaultMusic
	call PlayDefaultMusic
.done
	jp RestoreFacingDirectionAndYScreenPos
.dungeonWarpAnimation
	ld c, 50
	call DelayFrames
	call PlayerSpinWhileMovingDown
	jr .done
.flyAnimation
	pop hl
	ld de, BirdSprite
	ld hl, vNPCSprites
	lb bc, BANK(BirdSprite), $0c
	call CopyVideoData
	call LoadBirdSpriteGraphics
	ld a, SFX_FLY
	call PlaySound
	ld hl, wFlyAnimUsingCoordList
	xor a ; is using coord list
	ld [hli], a ; wFlyAnimUsingCoordList
	; 60FPS: the interpolated entry animation contains 36 coordinate pairs.
	ld a, 36
	ld [hli], a ; wFlyAnimCounter
	ld [hl], $8 ; wFlyAnimBirdSpriteImageIndex (facing right)
	ld de, FlyAnimationEnterScreenCoords
	call DoFlyAnimation
	call LoadPlayerSpriteGraphics
	jr .restoreDefaultMusic

FlyAnimationEnterScreenCoords:
; y, x pairs
; This is the sequence of screen coordinates used by the overworld
; Fly animation when the player is entering a map.
; 60FPS: interpolated coordinates provide one position update per rendered frame.
	db $05, $98
	db $08, $95
	db $0B, $92
	db $0F, $90
	db $12, $8D
	db $15, $8A
	db $18, $88
	db $1B, $85
	db $1E, $82
	db $20, $80
	db $22, $7D
	db $25, $7A
	db $27, $78
	db $29, $75
	db $2B, $72
	db $2D, $70
	db $2F, $6D
	db $30, $6A
	db $32, $68
	db $33, $65
	db $35, $62
	db $36, $60
	db $37, $5D
	db $38, $5A
	db $39, $58
	db $3A, $55
	db $3A, $52
	db $3B, $50
	db $3B, $4D
	db $3B, $4A
	db $3C, $48
	db $3C, $45
	db $3C, $42
	db $3C, $40
	db $3C, $40
	db $3C, $40

PlayerSpinWhileMovingDown:
	ld hl, wPlayerSpinWhileMovingUpOrDownAnimDeltaY
	ld a, $10
	ld [hli], a ; wPlayerSpinWhileMovingUpOrDownAnimDeltaY
	ld a, $3c
	ld [hli], a ; wPlayerSpinWhileMovingUpOrDownAnimMaxY
	call GetPlayerTeleportAnimFrameDelay
	ld [hl], a ; wPlayerSpinWhileMovingUpOrDownAnimFrameDelay
	jp PlayerSpinWhileMovingUpOrDown

_LeaveMapAnim:
	call InitFacingDirectionList
	call IsPlayerStandingOnWarpPadOrHole
	ld a, b
	and a
	jr z, .playerNotStandingOnWarpPadOrHole
	dec a
	jp nz, LeaveMapThroughHoleAnim
.spinWhileMovingUp
	ld a, SFX_TELEPORT_EXIT_1
	call PlaySound
	ld hl, wPlayerSpinWhileMovingUpOrDownAnimDeltaY
	ld a, -$10
	ld [hli], a ; wPlayerSpinWhileMovingUpOrDownAnimDeltaY
	ld a, $ec
	ld [hli], a ; wPlayerSpinWhileMovingUpOrDownAnimMaxY
	call GetPlayerTeleportAnimFrameDelay
	ld [hl], a ; wPlayerSpinWhileMovingUpOrDownAnimFrameDelay
	call PlayerSpinWhileMovingUpOrDown
	call IsPlayerStandingOnWarpPadOrHole
	ld a, b
	dec a
	jr z, .playerStandingOnWarpPad
; if not standing on a warp pad, there is an extra delay
	ld c, 10
	call DelayFrames
.playerStandingOnWarpPad
	call GBFadeOutToWhite
	jp RestoreFacingDirectionAndYScreenPos
.playerNotStandingOnWarpPadOrHole
	ld a, $4
	call StopMusic
	ld a, [wd732]
	bit 6, a ; is the last used pokemon center the destination?
	jr z, .flyAnimation
; if going to the last used pokemon center
	ld hl, wPlayerSpinInPlaceAnimFrameDelay
	ld a, 16
	ld [hli], a ; wPlayerSpinInPlaceAnimFrameDelay
	ld a, -1
	ld [hli], a ; wPlayerSpinInPlaceAnimFrameDelayDelta
	xor a
	ld [hli], a ; wPlayerSpinInPlaceAnimFrameDelayEndValue
	ld [hl], SFX_TELEPORT_EXIT_2 ; wPlayerSpinInPlaceAnimSoundID
	ld hl, wFacingDirectionList
	call PlayerSpinInPlace
	jr .spinWhileMovingUp
.flyAnimation
	call LoadBirdSpriteGraphics
	ld hl, wFlyAnimUsingCoordList
	ld a, $ff ; is not using coord list (flap in place)
	ld [hli], a ; wFlyAnimUsingCoordList
	; 60FPS: keep the original in-place duration while updating every frame.
	ld a, 24
	ld [hli], a ; wFlyAnimCounter
	ld [hl], $c ; wFlyAnimBirdSpriteImageIndex
	call DoFlyAnimation
	ld a, SFX_FLY
	call PlaySound
	ld hl, wFlyAnimUsingCoordList
	xor a ; is using coord list
	ld [hli], a ; wFlyAnimUsingCoordList
	; 60FPS: the interpolated first flight path contains 36 coordinate pairs.
	ld a, 36
	ld [hli], a ; wFlyAnimCounter
	ld [hl], $c ; wFlyAnimBirdSpriteImageIndex (facing right)
	ld de, FlyAnimationScreenCoords1
	call DoFlyAnimation
	ld c, 40
	call DelayFrames
	ld hl, wFlyAnimCounter
	; 60FPS: the interpolated second flight path contains 33 coordinate pairs.
	ld a, 33
	ld [hli], a ; wFlyAnimCounter
	ld [hl], $8 ; wFlyAnimBirdSpriteImageIndex (facing left)
	ld de, FlyAnimationScreenCoords2
	call DoFlyAnimation
	call GBFadeOutToWhite
	jp RestoreFacingDirectionAndYScreenPos

FlyAnimationScreenCoords1:
; y, x pairs
; This is the sequence of screen coordinates used by the first part
; of the Fly overworld animation.
; 60FPS: interpolated coordinates provide one position update per rendered frame.
	db $3C, $48
	db $3C, $4B
	db $3C, $4E
	db $3C, $50
	db $3C, $52
	db $3C, $55
	db $3B, $58
	db $3B, $5B
	db $3B, $5E
	db $3A, $60
	db $3A, $62
	db $3A, $65
	db $39, $68
	db $39, $6B
	db $38, $6E
	db $37, $70
	db $37, $73
	db $37, $76
	db $37, $78
	db $35, $7B
	db $34, $7E
	db $33, $80
	db $32, $82
	db $31, $85
	db $30, $88
	db $2F, $8B
	db $2E, $8E
	db $2D, $90
	db $2C, $92
	db $2B, $95
	db $2A, $98
	db $29, $9B
	db $28, $9E
	db $27, $A0
	db $26, $A3
	db $25, $A6

FlyAnimationScreenCoords2:
; y, x pairs
; This is the sequence of screen coordinates used by the second part
; of the Fly overworld animation.
; 60FPS: interpolated coordinates provide one position update per rendered frame.
	db $1A, $90
	db $1A, $8B
	db $1A, $86
	db $19, $80
	db $18, $79
	db $18, $74
	db $17, $70
	db $17, $6B
	db $16, $66
	db $15, $60
	db $14, $5B
	db $13, $56
	db $12, $50
	db $11, $4B
	db $10, $46
	db $0F, $40
	db $0E, $3B
	db $0D, $36
	db $0C, $30
	db $0B, $2B
	db $0A, $26
	db $09, $20
	db $08, $1B
	db $06, $16
	db $05, $10
	db $03, $0B
	db $01, $06
	db $00, $00
	db $00, $00
	db $FA, $00
	db $F0, $00
	db $EB, $00
	db $E6, $00

LeaveMapThroughHoleAnim:
	ld a, $ff
	ld [wUpdateSpritesEnabled], a ; disable UpdateSprites
	; shift upper half of player's sprite down 8 pixels and hide lower half
	ld a, [wOAMBuffer + 0 * 4 + 2]
	ld [wOAMBuffer + 2 * 4 + 2], a
	ld a, [wOAMBuffer + 1 * 4 + 2]
	ld [wOAMBuffer + 3 * 4 + 2], a
	ld a, $a0
	ld [wOAMBuffer + 0 * 4], a
	ld [wOAMBuffer + 1 * 4], a
	ld c, 2
	call DelayFrames
	; hide upper half of player's sprite
	ld a, $a0
	ld [wOAMBuffer + 2 * 4], a
	ld [wOAMBuffer + 3 * 4], a
	call GBFadeOutToWhite
	ld a, $1
	ld [wUpdateSpritesEnabled], a ; enable UpdateSprites
	jp RestoreFacingDirectionAndYScreenPos

DoFlyAnimation:
	; 60FPS: coordinates update every frame, while wing flapping remains at
	; the original once-per-three-frames cadence.
	ld a, 2
	push af
.loop
	pop af
	push af
	and a
	jr nz, .noFlapYet
	ld a, [wFlyAnimBirdSpriteImageIndex]
	xor $1 ; make the bird flap its wings
	ld [wFlyAnimBirdSpriteImageIndex], a
	ld [wSpriteStateData1 + 2], a
.noFlapYet
	call DelayFrame
	ld a, [wFlyAnimUsingCoordList]
	cp $ff
	jr z, .skipCopyingCoords ; if the bird is flapping its wings in place
	ld hl, wSpriteStateData1 + 4
	ld a, [de]
	inc de
	ld [hli], a
	inc hl
	ld a, [de]
	inc de
	ld [hl], a
.skipCopyingCoords
	pop af
	dec a
	cp $ff
	jr nz, .keepFlapCounter
	ld a, 2
.keepFlapCounter
	push af
	ld hl, wFlyAnimCounter
	dec [hl]
	jr nz, .loop
	pop af
	ret

LoadBirdSpriteGraphics:
	ld de, BirdSprite
	ld hl, vNPCSprites
	lb bc, BANK(BirdSprite), $0c
	call CopyVideoData
	ld de, BirdSprite + $c0 ; moving animation sprite
	ld hl, vNPCSprites2
	lb bc, BANK(BirdSprite), $0c
	jp CopyVideoData

InitFacingDirectionList:
	ld a, [wSpriteStateData1 + 2] ; player's sprite facing direction (image index is locked to standing images)
	ld [wSavedPlayerFacingDirection], a
	ld a, [wSpriteStateData1 + 4] ; player's sprite Y screen position
	ld [wSavedPlayerScreenY], a
	ld hl, PlayerSpinningFacingOrder
	ld de, wFacingDirectionList
	ld bc, 4
	call CopyData
	ld a, [wSpriteStateData1 + 2] ; player's sprite facing direction (image index is locked to standing images)
	ld hl, wFacingDirectionList
; find the place in the list that matches the current facing direction
.loop
	cp [hl]
	inc hl
	jr nz, .loop
	dec hl
	ret

PlayerSpinningFacingOrder:
; The order of the direction the player's sprite is facing when teleporting
; away. Creates a spinning effect.
	db SPRITE_FACING_DOWN, SPRITE_FACING_LEFT, SPRITE_FACING_UP, SPRITE_FACING_RIGHT

SpinPlayerSprite:
; copy the current value from the list into the sprite data and rotate the list
	ld a, [hl]
	ld [wSpriteStateData1 + 2], a ; player's sprite facing direction (image index is locked to standing images)
	push hl
	ld hl, wFacingDirectionList
	ld de, wFacingDirectionList - 1
	ld bc, 4
	call CopyData
	ld a, [wFacingDirectionList - 1]
	ld [wFacingDirectionList + 3], a
	pop hl
	ret

PlayerSpinInPlace:
	call SpinPlayerSprite
	ld a, [wPlayerSpinInPlaceAnimFrameDelay]
	ld c, a
	and $3
	jr nz, .skipPlayingSound
; when the last delay was a multiple of 4, play a sound if there is one
	ld a, [wPlayerSpinInPlaceAnimSoundID]
	cp $ff
	call nz, PlaySound
.skipPlayingSound
	ld a, [wPlayerSpinInPlaceAnimFrameDelayDelta]
	add c
	ld [wPlayerSpinInPlaceAnimFrameDelay], a
	ld c, a
	ld a, [wPlayerSpinInPlaceAnimFrameDelayEndValue]
	cp c
	ret z
	call DelayFrames
	jr PlayerSpinInPlace

PlayerSpinWhileMovingUpOrDown:
	call SpinPlayerSprite
	ld a, [wPlayerSpinWhileMovingUpOrDownAnimDeltaY]
	ld c, a
	ld a, [wSpriteStateData1 + 4] ; player's sprite Y screen position
	add c
	ld [wSpriteStateData1 + 4], a
	ld c, a
	ld a, [wPlayerSpinWhileMovingUpOrDownAnimMaxY]
	cp c
	ret z
	ld a, [wPlayerSpinWhileMovingUpOrDownAnimFrameDelay]
	ld c, a
	call DelayFrames
	jr PlayerSpinWhileMovingUpOrDown

RestoreFacingDirectionAndYScreenPos:
	ld a, [wSavedPlayerScreenY]
	ld [wSpriteStateData1 + 4], a
	ld a, [wSavedPlayerFacingDirection]
	ld [wSpriteStateData1 + 2], a
	ret

; if SGB, 2 frames, else 3 frames
GetPlayerTeleportAnimFrameDelay:
	ld a, [wOnSGB]
	xor $1
	inc a
	inc a
	ret

IsPlayerStandingOnWarpPadOrHole:
	ld b, 0
	ld hl, .warpPadAndHoleData
	ld a, [wCurMapTileset]
	ld c, a
.loop
	ld a, [hli]
	cp $ff
	jr z, .done
	cp c
	jr nz, .nextEntry
	aCoord 8, 9
	cp [hl]
	jr z, .foundMatch
.nextEntry
	inc hl
	inc hl
	jr .loop
.foundMatch
	inc hl
	ld b, [hl]
.done
	ld a, b
	ld [wStandingOnWarpPadOrHole], a
	ret

; format: db tileset id, tile id, value to be put in [wStandingOnWarpPadOrHole]
.warpPadAndHoleData:
	db FACILITY,   $20, 1 ; warp pad
	db FACILITY,   $11, 2 ; hole
	db CAVERN,     $22, 2 ; hole
	db INTERIOR,   $55, 1 ; warp pad
	db ICE_CAVERN, $22, 2 ; hole
	db $FF

FishingAnim:
	ld c, 10
	call DelayFrames
	ld hl, wd736
	set 6, [hl] ; reserve the last 4 OAM entries
	ld a, [wPlayerGender] ; added gender check
	and a      ; added gender check
	jr z, .BoySpriteLoad
	ld de, LeafSprite
	ld hl, vNPCSprites
	ld bc, (BANK(LeafSprite) << 8) + $0c
	jr .KeepLoadingSpriteStuff
.BoySpriteLoad
	ld de, RedSprite
	ld hl, vNPCSprites
	lb bc, BANK(RedSprite), $c
.KeepLoadingSpriteStuff
	call CopyVideoData
	ld a, [wPlayerGender] ; added gender check
	and a      ; added gender check
	jr z, .BoyTiles ; skip loading Leaf's stuff if you're Red
	ld a, $4
	ld hl, LeafFishingTiles
	jr .ContinueRoutine ; go back to main routine after loading Leaf's stuff
.BoyTiles ; alternately, load Red's stuff
	ld a, $4
	ld hl, RedFishingTiles
.ContinueRoutine
	call LoadAnimSpriteGfx
	ld a, [wSpriteStateData1 + 2]
	ld c, a
	ld b, $0
	ld hl, FishingRodOAM
	add hl, bc
	ld de, wOAMBuffer + $9c
	ld bc, $4
	call CopyData
	ld c, 100
	call DelayFrames
	ld a, [wRodResponse]
	and a
	ld hl, NoNibbleText
	jr z, .done
	cp $2
	ld hl, NothingHereText
	jr z, .done

; there was a bite

; shake the player's sprite vertically
	ld b, 10
.loop
	ld hl, wSpriteStateData1 + 4 ; player's sprite Y screen position
	call .ShakePlayerSprite
	ld hl, wOAMBuffer + $9c
	call .ShakePlayerSprite
	call Delay3
	dec b
	jr nz, .loop

; If the player is facing up, hide the fishing rod so it doesn't overlap with
; the exclamation bubble that will be shown next.
	ld a, [wSpriteStateData1 + 2] ; player's sprite facing direction
	cp SPRITE_FACING_UP
	jr nz, .skipHidingFishingRod
	ld a, $a0
	ld [wOAMBuffer + $9c], a

.skipHidingFishingRod
	ld hl, wEmotionBubbleSpriteIndex
	xor a
	ld [hli], a ; player's sprite
	ld [hl], a ; EXCLAMATION_BUBBLE
	predef EmotionBubble

; If the player is facing up, unhide the fishing rod.
	ld a, [wSpriteStateData1 + 2] ; player's sprite facing direction
	cp SPRITE_FACING_UP
	jr nz, .skipUnhidingFishingRod
	ld a, $44
	ld [wOAMBuffer + $9c], a

.skipUnhidingFishingRod
	ld hl, ItsABiteText

.done
	call PrintText
	ld hl, wd736
	res 6, [hl] ; unreserve the last 4 OAM entries
	call LoadFontTilePatterns
	ret

.ShakePlayerSprite
	ld a, [hl]
	xor $1
	ld [hl], a
	ret

NoNibbleText:
	TX_FAR _NoNibbleText
	db "@"

NothingHereText:
	TX_FAR _NothingHereText
	db "@"

ItsABiteText:
	TX_FAR _ItsABiteText
	db "@"

FishingRodOAM:
; specifies how the fishing rod should be drawn on the screen
; first byte = screen y coordinate
; second byte = screen x coordinate
; third byte = tile number
; fourth byte = sprite properties
	db $5B, $4C, $FD, $00 ; player facing down
	db $44, $4C, $FD, $00 ; player facing up
	db $50, $40, $FE, $00 ; player facing left
	db $50, $58, $FE, $20 ; player facing right ($20 means "horizontally flip the tile")

RedFishingTiles:
	dw RedFishingTilesFront
	db 2, BANK(RedFishingTilesFront)
	dw vNPCSprites + $20

	dw RedFishingTilesBack
	db 2, BANK(RedFishingTilesBack)
	dw vNPCSprites + $60

	dw RedFishingTilesSide
	db 2, BANK(RedFishingTilesSide)
	dw vNPCSprites + $a0

	dw RedFishingRodTiles
	db 3, BANK(RedFishingRodTiles)
	dw vNPCSprites2 + $7d0
	
LeafFishingTiles: ; newly added table of Leaf's sprites
	dw LeafFishingTilesFront
	db 2, BANK(LeafFishingTilesFront)
	dw vNPCSprites + $20

	dw LeafFishingTilesBack
	db 2, BANK(LeafFishingTilesBack)
	dw vNPCSprites + $60

	dw LeafFishingTilesSide
	db 2, BANK(LeafFishingTilesSide)
	dw vNPCSprites + $a0

	dw RedFishingRodTiles
	db 3, BANK(RedFishingRodTiles)
	dw vNPCSprites2 + $7d0

_HandleMidJump:
	ld a, [wPlayerJumpingYScreenCoordsIndex]
	ld c, a
	inc a
	; 60FPS: repeat each ledge Y coordinate for one extra rendered frame.
	call Ledge60FPS
	cp $10
	jr nc, .finishedJump
	ld [wPlayerJumpingYScreenCoordsIndex], a
	ld b, 0
	ld hl, PlayerJumpingYScreenCoords
	add hl, bc
	ld a, [hl]
	ld [wSpriteStateData1 + 4], a ; player's sprite y coordinate
	ret
.finishedJump
	ld a, [wWalkCounter]
	cp 0
	ret nz
	call UpdateSprites
	call Delay3
	xor a
	ld [hJoyHeld], a
	ld [hJoyPressed], a
	ld [hJoyReleased], a
	ld [wPlayerJumpingYScreenCoordsIndex], a
	ld hl, wd736
	res 6, [hl] ; not jumping down a ledge any more
	ld hl, wd730
	res 7, [hl] ; not simulating joypad states any more
	xor a
	ld [wJoyIgnore], a
	ret

; Adjust the ledge animation index using the player sprite's current 60 FPS phase.
; c2xA is toggled by ToggleSprite60FPSPhase while UpdateSprites runs.
Ledge60FPS:
	push hl
	ld hl, wSpriteStateData2 + $0a
	sub [hl]
	pop hl
	ret

PlayerJumpingYScreenCoords:
; Sequence of y screen coordinates for player's sprite when jumping over a ledge.
	db $38, $36, $34, $32, $31, $30, $30, $30, $31, $32, $33, $34, $36, $38, $3C, $3C
