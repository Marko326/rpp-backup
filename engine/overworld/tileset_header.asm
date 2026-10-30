LoadTilesetHeader:
	call GetPredefRegisters
	push hl
	; FIX-267: full 16-bit offset for each 12-byte tileset record.
	; Previous 8-bit multiplication lost an intermediate carry at ID $20:
	; $20 * 12 must be $0180, not $0080.
	ld a, [wCurMapTileset]
	ld l, a
	ld h, 0
	add hl, hl ; 2 * tileset ID
	add hl, hl ; 4 * tileset ID
	ld d, h
	ld e, l
	add hl, hl ; 8 * tileset ID
	add hl, de ; 12 * tileset ID, preserving high byte
	ld de, Tilesets
	add hl, de
	ld de, wTilesetBank
	ld c, $b
.copyTilesetHeaderLoop
	ld a, [hli]
	ld [de], a
	inc de
	dec c
	jr nz, .copyTilesetHeaderLoop
	ld a, [hl]
	ld [hTilesetType], a
	xor a
	ld [$ffd8], a
	pop hl
	ld a, [wCurMapTileset]
	push hl
	push de
	ld hl, DungeonTilesets
	ld de, $1
	call IsInArray
	pop de
	pop hl
	jr c, .asm_c797
	ld a, [wCurMapTileset]
	ld b, a
	ld a, [hPreviousTileset]
	cp b
	jr z, .done
.asm_c797
	ld a, [wDestinationWarpID]
	cp $ff
	jr z, .done
	call LoadDestinationWarpPosition
	ld a, [wYCoord]
	and $1
	ld [wYBlockCoord], a
	ld a, [wXCoord]
	and $1
	ld [wXBlockCoord], a
.done
	ret

INCLUDE "data/dungeon_tilesets.asm"

INCLUDE "data/tileset_headers.asm"
