InitPlayerData:
InitPlayerData2:
; Start by generating the player ID
	call Random
	ld a, [hRandomSub]
	ld [wPlayerID], a

	call Random
	ld a, [hRandomAdd]
	ld [wPlayerID + 1], a

; Not sure what this is for?
	ld a, $ff
	ld [wUnusedD71B], a

; MOVE-5.62.169: a new game has no extended move identities.
	xor a
	ld hl, wExtendedPartyMoveFlags
	ld bc, PARTY_LENGTH
	call FillMemory
	xor a
	ld [wExtendedLearningMoveOrdinal], a
	ld [wExtendedStatusMoveFlags], a
	ld [wExtendedActiveMoveOrdinal], a
	callba ResetExtendedCurrentBoxFlags

; Initialize the party, bag, PC, etc.
	ld hl, wPartyCount
	call InitializeEmptyList
	ld hl, wNumInBox
	call InitializeEmptyList
	ld hl, wNumBagItems
	call InitializeEmptyList
	ld hl, wNumBoxItems
	call InitializeEmptyList

	; GBP-5.57.01: keep the initial policy of making GB Player available on new saves.
	; The item ID is stable; a later patch can move acquisition to an NPC/reward
	; without changing save/item numbering.
	ld hl, wNumBagItems
	ld a, GB_PLAYER
	ld [wcf91], a
	ld a, 1
	ld [wItemQuantity], a
	call AddItemToInventory

START_MONEY EQU $3000
	ld hl, wPlayerMoney + 1
	ld a, START_MONEY / $100
	ld [hld], a
	xor a
	ld [hli], a
	inc hl
	ld [hl], a

	ld [wMonDataLocation], a
	; FIS-5.62.84: a new game has no Bag-selected fishing rod yet.
	ld [wLastUsedFishingRod], a
	ld [wLastUsedFishingRodMagic], a
	; DEX-5.62.115: clear all 128 capacity slots on a new game only.
	; Original Seen/Owned blocks are adjacent (10 + 8 bytes).
	xor a
	ld hl,wRegionalDexSeen
	ld bc,18
	call FillMemory
	xor a
	ld hl,wRegionalDexOwnedTail
	ld bc,6
	call FillMemory
	xor a
	ld hl,wRegionalDexSeenExtra
	ld bc,8 ; six Seen extension + two Owned extension bytes
	call FillMemory

; Obtained badges
	ld hl, wObtainedKantoBadges
	ld [hli], a
	; wObtainedJohtoBadges
	ld [hl], a

; Initialize player coins
	ld hl, wPlayerCoins
	ld [hli], a
	ld [hl], a

; Initialize Berry Tree flags and step counter
	ld hl, wBerryTreeFlags
	; assumption: only 2 bytes used for flags
	ld [hli], a
	ld [hli], a
	; assumption: step counter immediately follows berry tree flags
	ld [hli], a
	ld [hl], a

; Initialize the variable sprites
	ld hl, VarSpriteTable
	ld de, wVarSprites
	ld bc, VarSpriteTableEnd - VarSpriteTable
	call CopyData

; Initialize map script numbers
	xor a
	ld hl, wGameProgressFlags
	ld bc, wGameProgressFlagsEnd - wGameProgressFlags
	call FillMemory ; clear all game progress flags

	jp InitializeMissableObjectsFlags
	
INCLUDE "data/default_var_sprites.asm"

InitializeEmptyList:
	xor a ; count
	ld [hli], a
	dec a ; terminator
	ld [hl], a
	ret
