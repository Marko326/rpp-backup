LoadTilesetHeader:
	call GetPredefRegisters
	push hl
	; The tileset header is 12 bytes. Use a full 16-bit index:
	; tileset 32 begins at $180, not $080 (8-bit carry was lost).
	ld a, [wCurMapTileset]
	ld l, a
	ld h, 0
	add hl, hl ; id * 2
	add hl, hl ; id * 4
	ld d, h
	ld e, l
	add hl, hl ; id * 8
	add hl, de ; id * 12
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
