; VIDEO-ONLY recording gallery, selectable at the player bedroom PC.
; Native Gen-1 text commands respect the player's configured text speed.
; 55 Deluxe differences, alphabetically once; or 5 sample moves once.
; Every preview is ALLY -> FOE, unchanged HP/PP, native hit feedback.
; No actual battle turn is executed.

VIDEO_MOVE_COUNT EQU 55
VIDEO_TEST_COUNT EQU 5
VIDEO_GALLERY_MAGIC EQU $a7
VIDEO_GALLERY_RETURN_PENDING EQU $a8 ; menu return -> overworld full EnterMap
; Two unused gym-puzzle scratch bytes already exposed in the test ROM.
; No WRAM layout / SRAM format change.
; wVideoGalleryGuard ($d7c7) and wVideoGalleryPhase ($d7c8) are reused
; Recording branch only (standard Red/Blue): WRAM layout is unchanged.

; One-shot gallery launched from Red's own 2F PC; B cancels without a battle.
; Do not alter the storage PC in normal builds.
VideoBedroomPCMenu::
	ld hl, VideoPCPromptText
	call PrintText
	call SaveScreenTilesToBuffer1
	ld a, [hFlags_0xFFF6]
	push af
	res 1, a
	ld [hFlags_0xFFF6], a
	ld a, [wd730]
	push af
	set 6, a ; fast rendering ONLY for selector menu labels
	ld [wd730], a
	xor a
	ld [wCurrentMenuItem], a
	ld [wLastMenuItem], a
	ld [wMenuWatchMovingOutOfBounds], a
	ld [wMenuWrappingEnabled], a
	ld [wMenuJoypadPollCount], a
	ld a, 1
	ld [wTopMenuItemX], a
	ld a, 4
	ld [wTopMenuItemY], a
	ld a, 2 ; A-Z / Test / Cancel
	ld [wMaxMenuItem], a
	ld a, A_BUTTON | B_BUTTON
	ld [wMenuWatchedKeys], a
	coord hl, 0, 2
	ld b, 8
	ld c, 17
	call TextBoxBorder
	coord hl, 2, 3
	ld de, VideoPCMenuTitle
	call PlaceString
	coord hl, 3, 4
	ld de, VideoPCAZOption
	call PlaceString
	coord hl, 3, 6
	ld de, VideoPCTestOption
	call PlaceString
	coord hl, 3, 8
	ld de, VideoPCCancelOption
	call PlaceString
	pop af
	ld [wd730], a
	call UpdateSprites
	ld a, 1
	ld [H_AUTOBGTRANSFERENABLED], a
	call Delay3
.menu
	call HandleMenuInput
	bit 1, a
	jr nz, .cancel
	bit 0, a
	jr z, .menu
	ld a, [wCurrentMenuItem]
	cp 2
	jr z, .cancel
	inc a ; 1 = A-Z (55), 2 = short test (5)
	ld [wVideoGalleryPhase], a
	jr .chosen
.cancel
	xor a
	ld [wVideoGalleryPhase], a
.chosen
	pop af
	ld [hFlags_0xFFF6], a
	call LoadScreenTilesFromBuffer1
	ld a, [wVideoGalleryPhase]
	and a
	ret z

	; Prepare a disposable mon only if the player has no party. The
	; high bit-6 of the video mode records that ownership for cleanup.
	; IMPORTANT: do not call InitOpponent inside the PC text callback:
	; the normal overworld must own the battle so its .battleOccurred
	; path performs the complete map/VRAM/palette restoration.
	ld a, [wPartyCount]
	and a
	jr nz, .existingParty
	ld hl, wPartyCount
	ld [hli], a
	dec a
	ld [hl], a
	ld a, PIKACHU
	ld [wcf91], a
	ld a, 20
	ld [wCurEnemyLVL], a
	xor a
	ld [wMonDataLocation], a
	call AddPartyMon
	ld a, PIKACHU
	ld [wd11e], a
	call GetMonName
	ld hl, wcd6d
	ld de, wPartyMonNicks
	ld bc, NAME_LENGTH
	call CopyData
	ld hl, wVideoGalleryPhase
	set 6, [hl] ; temporary Pikachu, remove AFTER AnyPartyAlive
.existingParty
	; Stage only encounter parameters. DisplayTextID returns first;
	; OverworldLoop.checkForOpponent will detect wCurOpponent and call
	; NewBattle, then run its normal battleOccurred -> EnterMap route.
	ld a, $a7 ; VIDEO_GALLERY_MAGIC, not the NPC test suite magic
	ld [wVideoGalleryGuard], a
	ld a, PIDGEY
	ld [wCurOpponent], a
	ld a, 10
	ld [wCurEnemyLVL], a
	xor a
	ld [wIsTrainerBattle], a
	ret

; Called only from the normal OverworldLoop.battleOccurred branch.
; At this point AnyPartyAlive has run and EndOfBattle has completed.
VideoCleanupAfterBattle::
	ld a, [wVideoGalleryGuard]
	cp $a7
	ret nz
	ld a, [wVideoGalleryPhase]
	bit 6, a
	jr z, .noTempParty
	xor a
	ld [wPartyCount], a
	dec a
	ld [wPartySpecies], a
.noTempParty
	xor a
	ld [wVideoGalleryGuard], a
	ld [wVideoGalleryPhase], a
	ld [wMoveAnimScriptLoaded], a
	ld [wExtendedAnimFrameEffect], a
	ld [wExtendedAnimPaletteMode], a
	ret

VideoPCPromptText:
	text "ANIM DEMO"
	line "Choose a mode."
	done
VideoPCMenuTitle: db "ANIM DEMO@"
VideoPCAZOption: db "A-Z 55 MOVES@"
VideoPCTestOption: db "TEST 5 MOVES@"
VideoPCCancelOption: db "CANCEL@"

; A = index (0..54). Stage the selected Deluxe byte stream in the normal
; 30-byte dedicated animation buffer. The animation interpreter consumes it.
VideoStageByIndex:
	add a
	ld l, a
	ld h, 0
	ld de, VideoRecipePointers
	add hl, de
	ld a, [hli]
	ld h, [hl]
	ld l, a
	ld a, [hli]
	ld b, a
	ld de, wBuffer
.copy
	ld a, [hli]
	ld [de], a
	inc de
	dec b
	jr nz, .copy
	ld a, 1
	ld [wMoveAnimScriptLoaded], a
	ret

; Called only from a bedroom-PC-started demo battle. Returns after its last
; move, instead of swallowing input / reopening the battle menu forever.
VideoPlayAllDeluxeAnimations::
	ld a, [wOptions]
	push af
	res 7, a ; force native animations on just for this preview
	ld [wOptions], a
	ld a, [H_WHOSETURN]
	push af
	xor a
	ld [wExtendedAnimFrameEffect], a
	ld [wExtendedAnimPaletteMode], a
	ld [wMoveAnimScriptLoaded], a
	; The high bit of wVideoGalleryPhase is a video-only B cancel latch.
	; Ignore buttons held during the battle intro; arm it at the first move.
	ld a, [wVideoGalleryPhase]
	and $43 ; preserve bit 6: temporary party ownership; clear B latch
	ld [wVideoGalleryPhase], a
	and $03 ; select A-Z / short test, ignoring temporary-party flag
	cp 2
	ld hl, VideoAlphabeticalOrder
	jr nz, .nextMove
	ld hl, VideoTestOrder
.nextMove
	ld a, [hli]
	cp $ff
	jr z, .finished
	push hl ; full next-entry pointer, never trust renderer registers
	ld c, a
	push bc
	xor a
	call VideoShowOneSide
	pop bc
	jr c, .cancelWithPointerOnStack
	push bc
	ld a, 1
	call VideoShowOneSide
	pop bc
	jr c, .cancelWithPointerOnStack
	pop hl
	jr .nextMove
.cancelWithPointerOnStack
	pop hl ; matched push hl above: B only exits at a safe boundary
	jr .restore
.finished
	ld hl, VideoFinishedText
	call PrintText
	ld c, 90
	call DelayFrames
.restore
	xor a
	ld [wMoveAnimScriptLoaded], a
	ld [wExtendedAnimFrameEffect], a
	ld [wExtendedAnimPaletteMode], a
	pop af
	ld [H_WHOSETURN], a
	pop af
	ld [wOptions], a
	ret

; Input: C is a 0-based catalogue index, A is 0 (ally) / 1 (foe).
; Every run uses the SAME pointer pair for the scripted name and animation.
VideoShowOneSide:
	push bc
	push af
	; C is the catalogue index, but LoadScreenTilesFromBuffer1 (CopyData)
	; is not BC-preserving. Look up the name *before* that operation.
	; This also keeps the name/script index aligned on both sides.
	ld a, c
	call VideoPrepareName
	call LoadScreenTilesFromBuffer1
	pop af
	ld [H_WHOSETURN], a
	and a
	ld hl, VideoAllyMoveText
	jr z, .print
	ld hl, VideoFoeMoveText
.print
	; Unlike PlaceString, this runs the normal TextCommandProcessor,
	; honoring the player's slow/medium/fast text speed in Options.
	call PrintText
	pop bc
	push bc
	ld a, c
	call VideoStageByIndex
	pop bc
	push bc
	ld a, c
	call VideoHitFeedbackByIndex
	ld [wAnimationType], a
	; Using the catalogue index as wAnimationID triggered special handlers:
	; Gear Grind at index 40 collided with TWINEEDLE ($29).
	; The staged bytecode is the real recipe; POUND is a safe carrier ID.
	ld a, POUND
	ld [wAnimationID], a
	callab PlayBattleAnimationGotID
	xor a
	ld [wMoveAnimScriptLoaded], a
	ld [wExtendedAnimFrameEffect], a
	ld [wExtendedAnimPaletteMode], a
	; No mid-animation teardown: the ROM0 DelayFrameHook captures a
	; single B press into phase bit 7, even during the animation itself.
	; Act on it only after PlayBattleAnimationGotID has returned, and
	; continue polling each frame during the short pause between sides.
	ld b, 34
.waitForNextSide
	push bc
	call DelayFrame
	pop bc
	ld a, [wVideoGalleryPhase]
	bit 7, a
	jr nz, .cancel
	dec b
	jr nz, .waitForNextSide
	pop bc
	and a ; clear carry on normal return
	ret
.cancel
	pop bc
	scf
	ret

; A=index. Copy the ROM move name to the game's 16-byte temporary name
; buffer so the normal TX_RAM text engine can print it character by character.
VideoPrepareName:
	add a
	ld l, a
	ld h, 0
	ld de, VideoNamePointers
	add hl, de
	ld a, [hli]
	ld d, [hl]
	ld e, a
	ld hl, wTempMoveNameBuffer
	jp CopyString

; Unlike ordinary inline strings, TX_RAM and TX_LINE are separate TEXT
; COMMANDS. Every inline text command must end with @ first; using
; line "" after TX_RAM feeds $4f to the *command* interpreter, and
; text "" feeds $00 into PlaceString (the 48 ERROR fallback).
VideoAllyMoveText:
	text "ALLY: @"
	TX_RAM wBattleMonNick
	TX_LINE
	TX_RAM wTempMoveNameBuffer
	db "@"

VideoFoeMoveText:
	text "FOE: @"
	TX_RAM wEnemyMonNick
	TX_LINE
	TX_RAM wTempMoveNameBuffer
	db "@"

VideoFinishedText:
	text "Animation demo"
	line "finished!"
	done

; 55 unique Deluxe preview scripts, sorted by displayed English name.
VideoAlphabeticalOrder:
	db 44 ; AIR SLASH
	db 39 ; ANCIENT POWER
	db 42 ; AQUA JET
	db 43 ; BOOMBURST
	db 29 ; BUG BUZZ
	db 16 ; BULLET PUNCH
	db  4 ; COSMIC POWER
	db 37 ; CROSS CHOP
	db 12 ; CRUNCH
	db 13 ; DARK PULSE
	db 21 ; DAZZLING GLEAM
	db  3 ; DOOM DESIRE
	db  7 ; DRAGON PULSE
	db 50 ; DRAGON RUSH
	db  5 ; DRAIN PUNCH
	db 22 ; DRAINING KISS
	db 54 ; DRILL RUN
	db 34 ; EXTREMESPEED
	db 15 ; FAKE TEARS
	db 17 ; FLASH CANNON
	db 40 ; GEAR GRIND
	db 25 ; GUNK SHOT
	db  2 ; HEAT WAVE
	db 38 ; HURRICANE
	db 11 ; ICE SHARD
	db 18 ; IRON HEAD
	db 20 ; LEAF BLADE
	db 30 ; MEGAHORN
	db 51 ; METAL SOUND
	db 24 ; MOONBLAST
	db  9 ; MOONLIGHT
	db 46 ; MUD SHOT
	db 14 ; NIGHT SLASH
	db 36 ; OMINOUS WIND
	db 23 ; PLAY ROUGH
	db 27 ; POISON JAB
	db 52 ; POWER WHIP
	db 31 ; PSYCHO CUT
	db 35 ; ROCK POLISH
	db 47 ; ROCK WRECKER
	db 45 ; ROOST
	db  0 ; SAND TOMB
	db 33 ; SHADOW PUNCH
	db 41 ; SHIFT GEAR
	db 28 ; SLUDGE WAVE
	db 19 ; STEEL WING
	db 53 ; STONE EDGE
	db  8 ; SUCKER PUNCH
	db  1 ; SUPERPOWER
	db  6 ; VACUUM WAVE
	db 10 ; VOLT TACKLE
	db 49 ; WILL O WISP
	db 26 ; WOOD HAMMER
	db 32 ; X SCISSOR
	db 48 ; ZAP CANNON
	db $ff
ASSERT @ - VideoAlphabeticalOrder == VIDEO_MOVE_COUNT + 1

; Fast QA: Gear Grind, Power Whip, Play Rough, Sand Tomb, Drill Run.
VideoTestOrder:
	db 40 ; GEAR GRIND
	db 52 ; POWER WHIP
	db 23 ; PLAY ROUGH
	db  0 ; SAND TOMB
	db 54 ; DRILL RUN
	db $ff
ASSERT @ - VideoTestOrder == VIDEO_TEST_COUNT + 1

; A = 0..54, the SAME index used by VideoNamePointers/VideoRecipePointers.
; Return wAnimationType (0 for status, 4 for ally damage, 1 for foe damage).
; The engine's PlayApplyingAttackAnimation consumes this after the recipe.
; HP/PP/AI/damage routines are never called from the footage loop.
VideoHitFeedbackByIndex:
	ld l, a
	ld h, 0
	ld de, VideoIsDamaging
	add hl, de
	ld a, [hl]
	and a
	ret z
	ld a, [H_WHOSETURN]
	and a
	ld a, 4                    ; ally: blink enemy picture
	ret z
	ld a, 1                    ; foe: shake player view
	ret

; Each byte is aligned to the same 55-entry animation/name list.
; Zero: self-buff/heal, debuff or status, no damaging hit.
; One: damaging attack, show the engine's normal impact reaction.
VideoIsDamaging:
	db 1,1,1,1,0, 1,1,1,1,0, 1,1,1,1,1, 0,1,1,1,1
	db 1,1,1,1,1, 1,1,1,1,1, 1,1,1,1,1, 0,1,1,1,1
	db 1,0,1,1,1, 0,1,1,1,0, 1,0,1,1,1
ASSERT @ - VideoIsDamaging == VIDEO_MOVE_COUNT

; The 55 immutable animation scripts and names are independently committed.
; Keep this include in the same ROMX section (near pointers use 16-bit addresses).
INCLUDE "engine/battle/deluxe_video_anim_data.asm"
