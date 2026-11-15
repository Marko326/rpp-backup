TryPushingBoulder:
	; Ice Path B1F has a queued one-tile boulder movement. While its PIT
	; decision is pending, re-running this entry must NOT overwrite
	; wBoulderSpriteIndex (the 1-based source stone recorded on the push).
	; Other Johto maps and all Kanto maps still take the original path.
	ld a, [wCurMap]
	cp JOHTO_RUNTIME_MAP_HANDLE
	jr nz, .checkStrength
	ld a, [wCurLocalMapID]
	cp JOHTO_ICE_PATH_B1F_LOCAL_ID
	jr nz, .checkStrength
	ld a, [wFlags_0xcd60]
	bit 7, a
	ret nz
.checkStrength
	ld a, [wd728]
	bit 0, a ; using Strength?
	ret z
	ld a, [wFlags_0xcd60]
	bit 1, a ; has boulder dust animation from previous push played yet?
	ret nz
	xor a
	ld [hSpriteIndexOrTextID], a
	call IsSpriteInFrontOfPlayer
	ld a, [hSpriteIndexOrTextID]
	ld [wBoulderSpriteIndex], a
	and a
	jp z, ResetBoulderPushFlags
	ld hl, wSpriteStateData1 + 1
	ld d, $0
	ld a, [hSpriteIndexOrTextID]
	swap a
	ld e, a
	add hl, de
	res 7, [hl]
	call GetSpriteMovementByte2Pointer
	ld a, [hl]
	cp BOULDER_MOVEMENT_BYTE_2
	jp nz, ResetBoulderPushFlags
	ld hl, wFlags_0xcd60
	bit 6, [hl]
	set 6, [hl] ; indicate that the player has tried pushing
	ret z ; the player must try pushing twice before the boulder will move
	ld a, [hJoyHeld]
	and D_RIGHT | D_LEFT | D_UP | D_DOWN
	ret z
	predef CheckForCollisionWhenPushingBoulder
	ld a, [wTileInFrontOfBoulderAndBoulderCollisionResult]
	and a ; was there a collision?
	jp nz, ResetBoulderPushFlags
	ld a, [hJoyHeld]
	ld b, a
	ld a, [wSpriteStateData1 + 9] ; player's sprite facing direction
	cp SPRITE_FACING_UP
	jr z, .pushBoulderUp
	cp SPRITE_FACING_LEFT
	jr z, .pushBoulderLeft
	cp SPRITE_FACING_RIGHT
	jr z, .pushBoulderRight
.pushBoulderDown
	bit 7, b
	ret z
	ld de, PushBoulderDownMovementData
	jr .done
.pushBoulderUp
	bit 6, b
	ret z
	ld de, PushBoulderUpMovementData
	jr .done
.pushBoulderLeft
	bit 5, b
	ret z
	ld de, PushBoulderLeftMovementData
	jr .done
.pushBoulderRight
	bit 4, b
	ret z
	ld de, PushBoulderRightMovementData
.done
	call MoveSprite
	; Gold spawns its independent dust when a push is accepted, not
	; after the 32-display-frame scripted boulder movement finishes.
	ld a, [wCurMap]
	cp JOHTO_RUNTIME_MAP_HANDLE
	jr nz, .noJohtoDustBegin
	callab BeginJohtoGoldStrengthDust369L
.noJohtoDustBegin
	callab PlayStrengthPushSFX369L
	ld hl, wFlags_0xcd60
	set 1, [hl]
	ret

PushBoulderUpMovementData:
	db NPC_MOVEMENT_UP,$FF

PushBoulderDownMovementData:
	db NPC_MOVEMENT_DOWN,$FF

PushBoulderLeftMovementData:
	db NPC_MOVEMENT_LEFT,$FF

PushBoulderRightMovementData:
	db NPC_MOVEMENT_RIGHT,$FF

DoBoulderDustAnimation:
	ld a, [wd730]
	bit 0, a
	ret nz
	; All Johto Strength boulders use Gold's temporary, nonblocking dust.
	; Kanto keeps its RPP movement/animation but never cycles rOBP1.
	ld a, [wCurMap]
	cp JOHTO_RUNTIME_MAP_HANDLE
	jr nz, .kantoQuietDust
	; Gold smoke is already running independently from push acceptance.
	jr .dustFinished
.kantoQuietDust
	callab AnimateBoulderDustQuiet369K
.dustFinished
	call DiscardButtonPresses
	ld [wJoyIgnore], a
	call ResetBoulderPushFlags
	set 7, [hl]
	ld a, [wBoulderSpriteIndex]
	ld [H_SPRITEINDEX], a
	call GetSpriteMovementByte2Pointer
	ld [hl], $10
	; Gold Strength already sounds at push start and (if a PIT is filled)
	; again after the source stone disappears. The old RPP SFX_CUT
	; here was a third, unintended Johto sound. Kanto retains it.
	ld a, [wCurMap]
	cp JOHTO_RUNTIME_MAP_HANDLE
	ret z
	ld a, SFX_CUT
	jp PlaySound

ResetBoulderPushFlags:
	ld hl, wFlags_0xcd60
	res 1, [hl]
	res 6, [hl]
	ret
