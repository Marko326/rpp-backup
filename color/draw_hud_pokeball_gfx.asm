; Hooks for engine/battle/draw_hud_pokeball_gfx.asm


; Called whenever the pokeball graphics for listing your party are loaded.
; Also need to load the palettes for them.
; Note: this uses overworld palette 0, but palette 2 of the attack palettes would also be
; suitable.
LoadPartyPokeballGfx:
	CALL_INDIRECT LoadOverworldSpritePalettes

	ld a,2
	ld [rSVBK],a

	; Set the palette the pokeball sprite uses
	ld hl,W2_SpritePaletteMap+$31
	xor a ; PAL_OW_RED
	ld [hli],a
	ld [hli],a
	ld [hli],a
	ld [hli],a

	xor a
	ld [rSVBK],a

	jp LoadPartyPokeballGfx_orig


PlayerHUDHAX:
	ld hl, PlayerHUDTileMap
	jp PlayerHUDUpdateDone
	
PlayerHUDTileMap:
	db $73, $75, $6F

EnemyHUDHAX:
	ld [hl], $72
	ld a, [wIsInBattle]
	dec a
	jr nz, .notWildBattle
	push hl
	; Test the original encounter identity, not the displayed Transform form.
	; The far call preserves Z but does not preserve A as its return value.
	callab RegionalDexWildHUDOwnedTest
	ld a, " " ; always clear the previous wild opponent's marker
	jr z, .writeOwnedMarker
	ld a, $E9 ; same existing small gray HUD ball
.writeOwnedMarker
	coord hl, 1, 1
	ld [hl], a
	pop hl
.notWildBattle
	ld de, $0001
	jp HealthBarUpdateDone ; EnemyHUDUpdateDone
