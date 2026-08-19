; Phase-1 dedicated animation recipes for selected expanded moves.
;
; Expanded move data still keeps a legacy animation byte for compatibility.
; PrepareCurrentMoveAnimation asks this bank for a dedicated recipe by REAL move
; ID. If no entry exists yet, the move safely falls back to its legacy animation.
;
; Each recipe starts with its byte length (including the $FF terminator). The
; command stream itself is copied into the existing 30-byte wBuffer.

LoadExtendedMoveAnimation:
; input: e = real move ID
; output: wMoveAnimScriptLoaded = 1 only if a dedicated recipe was found/staged
; callab/Bankswitch overwrites BC with its return trampoline, so DE carries the
; argument and is preserved across the bank switch.
	ld hl, ExtendedMoveAnimationTable
.search
	ld a, [hli]
	and a
	ret z
	cp e
	jr z, .found
	inc hl
	inc hl
	jr .search
.found
	ld a, [hli]
	ld h, [hl]
	ld l, a
	ld a, [hli] ; recipe byte length, including terminator
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

; Sparse on purpose: phase 1 validates the engine with representative aliases
; before enabling the remaining expanded moves.
ExtendedMoveAnimationTable:
	db METAL_CLAW
	dw MetalClawExtAnim
	db MOONBLAST
	dw MoonblastExtAnim
	db FLASH_CANNON
	dw FlashCannonExtAnim
	db DRACO_METEOR
	dw DracoMeteorExtAnim
	db GUNK_SHOT
	dw GunkShotExtAnim
	db POISON_FANG
	dw PoisonFangExtAnim
	db HYPER_VOICE
	dw HyperVoiceExtAnim
	db 0

MetalClawExtAnim:
	db MetalClawExtAnimEnd - MetalClawExtAnimData
MetalClawExtAnimData:
	; Metal sheen -> crossing claw cuts -> impact shake.
	db SE_LIGHT_SCREEN_PALETTE,$FF
	db $04,$09,$0F ; Scratch-style claw
	db SE_DARK_SCREEN_FLASH,$FF
	db $04,$FF,$16 ; Cut-style crossing slash
	db SE_SHAKE_SCREEN,$FF
	db SE_RESET_SCREEN_PALETTE,$FF
	db $FF
MetalClawExtAnimEnd:
	IF MetalClawExtAnimEnd - MetalClawExtAnimData > 30
		fail "Metal Claw animation recipe exceeds wBuffer"
	ENDC

MoonblastExtAnim:
	db MoonblastExtAnimEnd - MoonblastExtAnimData
MoonblastExtAnimData:
	; Gather light, scatter star-like sparks, then release a bright beam.
	db SE_LIGHT_SCREEN_PALETTE,$FF
	db SE_SPIRAL_BALLS_INWARD,$FF
	db $43,$80,$3F ; Swift-style stars
	db $04,$4B,$2E ; Solar Beam-style ray
	db SE_FLASH_SCREEN_LONG,$FF
	db SE_RESET_SCREEN_PALETTE,$FF
	db $FF
MoonblastExtAnimEnd:
	IF MoonblastExtAnimEnd - MoonblastExtAnimData > 30
		fail "Moonblast animation recipe exceeds wBuffer"
	ENDC

FlashCannonExtAnim:
	db FlashCannonExtAnimEnd - FlashCannonExtAnimData
FlashCannonExtAnimData:
	; Explicitly opt into Hyper Beam's per-frame flash behavior without using
	; HYPER_BEAM as this move's animation identity.
	db SE_LIGHT_SCREEN_PALETTE,$FF
	db SE_SPIRAL_BALLS_INWARD,$FF
	db EXT_ANIM_SET_FRAME_EFFECT,EXT_FRAME_FLASH_4
	db $02,$3E,$2E
	db EXT_ANIM_SET_FRAME_EFFECT,EXT_FRAME_NONE
	db SE_FLASH_SCREEN_LONG,$FF
	db SE_SHAKE_SCREEN,$FF
	db SE_RESET_SCREEN_PALETTE,$FF
	db $FF
FlashCannonExtAnimEnd:
	IF FlashCannonExtAnimEnd - FlashCannonExtAnimData > 30
		fail "Flash Cannon animation recipe exceeds wBuffer"
	ENDC

DracoMeteorExtAnim:
	db DracoMeteorExtAnimEnd - DracoMeteorExtAnimData
DracoMeteorExtAnimData:
	db SE_DARK_SCREEN_PALETTE,$FF
	db $04,$9C,$1D
	db $03,$9C,$1E
	db SE_SHAKE_SCREEN,$FF
	db SE_RESET_SCREEN_PALETTE,$FF
	db $FF
DracoMeteorExtAnimEnd:
	IF DracoMeteorExtAnimEnd - DracoMeteorExtAnimData > 30
		fail "Draco Meteor animation recipe exceeds wBuffer"
	ENDC

GunkShotExtAnim:
	db GunkShotExtAnimEnd - GunkShotExtAnimData
GunkShotExtAnimData:
	db $46,$7B,$13
	db $43,$8B,$41
	db $46,$7B,$14
	db $FF
GunkShotExtAnimEnd:
	IF GunkShotExtAnimEnd - GunkShotExtAnimData > 30
		fail "Gunk Shot animation recipe exceeds wBuffer"
	ENDC

PoisonFangExtAnim:
	db PoisonFangExtAnimEnd - PoisonFangExtAnimData
PoisonFangExtAnimData:
	db $08,$2B,$02
	db $46,$32,$13
	db $46,$32,$14
	db $FF
PoisonFangExtAnimEnd:
	IF PoisonFangExtAnimEnd - PoisonFangExtAnimData > 30
		fail "Poison Fang animation recipe exceeds wBuffer"
	ENDC

HyperVoiceExtAnim:
	db HyperVoiceExtAnimEnd - HyperVoiceExtAnimData
HyperVoiceExtAnimData:
	; Play the attacker's actual cry using ROAR's pitch/tempo profile, then layer
	; the old sound-wave components without relying on wAnimationID == ROAR.
	db EXT_ANIM_PLAY_USER_CRY,ROAR
	db $46,$FF,$12
	db $46,$2D,$15
	db $50,$FF,$40
	db $FF
HyperVoiceExtAnimEnd:
	IF HyperVoiceExtAnimEnd - HyperVoiceExtAnimData > 30
		fail "Hyper Voice animation recipe exceeds wBuffer"
	ENDC
