; Snowy runtime resources.
; Normal graphics/blocksets remain the base data. Only the bytes that differ
; in the original Snowy build are stored here and applied when wOptions bit 4 is set.

SECTION "Snowy Runtime", ROMX, BANK[$35]

ApplySnowTilesetGfxPatch::
	ld a,[wOptions]
	bit 4,a
	ret z
	ld a,[wCurMapTileset]
	cp OVERWORLD
	ld hl,SnowOverworldGfxPatchTable
	jr z,.apply
	cp FOREST
	ld hl,SnowForestGfxPatchTable
	jr z,.apply
	cp SAFARI
	ld hl,SnowSafariGfxPatchTable
	jr z,.apply
	cp PLATEAU
	ld hl,SnowPlateauGfxPatchTable
	ret nz
.apply
	jp ApplySnowGfxPatchTable

ApplySnowGfxPatchTable:
; Table format: tile ID, tile count, data pointer. $ff terminates.
.loop
	ld a,[hli]
	cp $ff
	ret z
	ld d,a
	ld a,[hli]
	ld [wBuffer],a
	ld a,[hli]
	ld c,a
	ld a,[hli]
	ld b,a
	push hl

	; Convert tile ID to its destination address under vTileset.
	ld a,d
	and $0f
	swap a
	ld e,a
	ld a,d
	swap a
	and $0f
	add $90 ; HIGH(vTileset)
	ld d,a

	ld h,b
	ld l,c
	ld a,[wBuffer]
	swap a ; each entry contains fewer than 16 tiles
	ld c,a
	ld b,0
	ld a,BANK(SnowOverworldGfxPatchTable)
	call FarCopyData2
	pop hl
	jr .loop

LoadSnowCutTreeTiles::
; Cut 动画会直接从 ROM 读取树图块；这里复用 Snowy 差分中的同一份数据。
	ld de,SnowOverworldGfxPatch05 + $90 ; tile $2d-$2e
	ld hl,vChars1 + $7c0
	lb bc,BANK(SnowOverworldGfxPatch05),2
	call CopyVideoData
	ld de,SnowOverworldGfxPatch09 ; tile $3d-$3e
	ld hl,vChars1 + $7e0
	lb bc,BANK(SnowOverworldGfxPatch09),2
	jp CopyVideoData

LoadSnowTextBoxTilePatterns::
; 直接把最终正确的 Normal/Snowy 混合图块写入 VRAM。
; Snowy 与普通版只有 0-2、4-7 号图块不同；其余图块继续复用普通 TextBoxGraphics。
; 这样 LCD 开启时不会先出现几帧普通屋顶再被 Snowy 图块覆盖。
	ld a,[rLCDC]
	bit 7,a
	jr nz,.lcdOn

	ld hl,SnowTextBoxTiles0
	ld de,vChars2 + $600
	ld bc,3 * $10
	ld a,BANK(SnowTextBoxTiles0)
	call FarCopyData2
	ld hl,TextBoxGraphics + $30
	ld de,vChars2 + $630
	ld bc,$10
	ld a,BANK(TextBoxGraphics)
	call FarCopyData2
	ld hl,SnowTextBoxTiles4
	ld de,vChars2 + $640
	ld bc,4 * $10
	ld a,BANK(SnowTextBoxTiles4)
	call FarCopyData2
	ld hl,TextBoxGraphics + $80
	ld de,vChars2 + $680
	ld bc,(TextBoxGraphicsEnd - TextBoxGraphics) - $80
	ld a,BANK(TextBoxGraphics)
	jp FarCopyData2

.lcdOn
	ld de,SnowTextBoxTiles0
	ld hl,vChars2 + $600
	lb bc,BANK(SnowTextBoxTiles0),3
	call CopyVideoData
	ld de,TextBoxGraphics + $30
	ld hl,vChars2 + $630
	lb bc,BANK(TextBoxGraphics),1
	call CopyVideoData
	ld de,SnowTextBoxTiles4
	ld hl,vChars2 + $640
	lb bc,BANK(SnowTextBoxTiles4),4
	call CopyVideoData
	ld de,TextBoxGraphics + $80
	ld hl,vChars2 + $680
	lb bc,BANK(TextBoxGraphics),(TextBoxGraphicsEnd - TextBoxGraphics) / $10 - 8
	jp CopyVideoData

ApplySnowPaletteOverrides::
; Called after the normal map/sprite palettes have been prepared in WRAM.
; Snowy replaces only the palette data and tile assignments that differ.
; 注意：游戏栈位于 WRAM Bank 1 ($df00-$dfff)。切换 rSVBK 后不能直接
; pop 切换前压入的值，否则会从另一个物理 WRAM bank 取栈并破坏返回地址。
	ld a,[rSVBK]
	ld d,a ; remember the caller's WRAM bank in a register first
	xor a
	ld [rSVBK],a ; bank 0 maps to WRAM Bank 1, where wOptions/wCurMapTileset live
	ld a,[wOptions]
	bit 4,a
	jp z,.restoreWRAMBank
	ld a,[wCurMapTileset]
	ld c,a
	ld a,2
	ld [rSVBK],a
	; Any temporary stack data must be pushed after switching to Bank 2 and
	; popped before switching back, so each push/pop pair uses the same WRAM bank.
	push de

	ld a,c
	cp OVERWORLD
	ld hl,SnowOverworldPaletteAssignment
	jr z,.copyAssignment
	cp FOREST
	ld hl,SnowForestPaletteAssignment
	jr z,.copyAssignment
	cp PLATEAU
	ld hl,SnowPlateauPaletteAssignment
	jr z,.copyAssignment
	cp SAFARI
	ld hl,SnowSafariPaletteAssignment
	jr nz,.skipAssignment
.copyAssignment
	; CopyData consumes BC, but C holds the current tileset for the later palette choices.
	; Save/restore it while the stack is safely in WRAM Bank 2.
	push bc
	ld de,W2_TilesetPaletteMap
	ld bc,$60
	call CopyData
	pop bc
.skipAssignment

	; OUTDOOR_GREEN/CAVE_GREEN occupy palette slot 2 in the affected sets.
	ld a,c
	cp OVERWORLD
	jr z,.outdoorGreen
	cp PLATEAU
	jr z,.outdoorGreen
	cp SAFARI
	jr z,.outdoorGreen
	cp FOREST
	jr z,.caveGreen
	cp CAVERN
	jr z,.caveGreen
	cp ICE_CAVERN
	jr nz,.skipBgGreen
.caveGreen
	ld hl,SnowCaveGreenPalette
	jr .copyBgGreen
.outdoorGreen
	ld hl,SnowOutdoorGreenPalette
.copyBgGreen
	push bc
	ld de,W2_BgPaletteData + 2 * 8
	ld bc,8
	call CopyData
	pop bc
.skipBgGreen

	; PAL_OW_TREE changes in the normal/night overworld sprite palettes.
	; POKECENTER uses its own sprite palette table and was not changed by _SNOW.
	ld a,c
	cp POKECENTER
	jr z,.skipTree
	cp FOREST
	jr z,.nightTree
	cp CAVERN
	jr z,.nightTree
	cp ICE_CAVERN
	ld hl,SnowOutdoorGreenPalette
	jr nz,.copyTree
.nightTree
	ld hl,SnowCaveGreenPalette
.copyTree
	ld de,W2_SprPaletteData + PAL_OW_TREE * 8
	ld bc,8
	call CopyData
.skipTree

	pop de
.restoreWRAMBank
	ld a,d
	ld [rSVBK],a
	ret

SnowOutdoorGreenPalette:
	RGB 27,31,27
	RGB 1,27,27
	RGB 5,17,31
	RGB 7,7,7

SnowCaveGreenPalette:
	RGB 15,14,24
	RGB 0,10,22
	RGB 0,7,15
	RGB 0,0,0

SnowOverworldPaletteAssignment:
	INCLUDE "color/tilesets/overworld_snow.asm"
SnowForestPaletteAssignment:
	INCLUDE "color/tilesets/forest_snow.asm"
SnowPlateauPaletteAssignment:
	INCLUDE "color/tilesets/plateau_snow.asm"
SnowSafariPaletteAssignment:
	INCLUDE "color/tilesets/safari_snow.asm"

SnowOverworldGfxPatchTable:
	db $01,2
	dw SnowOverworldGfxPatch00
	db $05,5
	dw SnowOverworldGfxPatch01
	db $11,3
	dw SnowOverworldGfxPatch02
	db $15,5
	dw SnowOverworldGfxPatch03
	db $1d,2
	dw SnowOverworldGfxPatch04
	db $24,11
	dw SnowOverworldGfxPatch05
	db $32,1
	dw SnowOverworldGfxPatch06
	db $34,1
	dw SnowOverworldGfxPatch07
	db $36,3
	dw SnowOverworldGfxPatch08
	db $3d,2
	dw SnowOverworldGfxPatch09
	db $40,2
	dw SnowOverworldGfxPatch10
	db $46,4
	dw SnowOverworldGfxPatch11
	db $4c,2
	dw SnowOverworldGfxPatch12
	db $50,2
	dw SnowOverworldGfxPatch13
	db $53,1
	dw SnowOverworldGfxPatch14
	db $56,4
	dw SnowOverworldGfxPatch15
	db $5c,2
	dw SnowOverworldGfxPatch16
	db $ff

SnowForestGfxPatchTable:
	db $02,3
	dw SnowForestGfxPatch00
	db $07,3
	dw SnowForestGfxPatch01
	db $0c,1
	dw SnowForestGfxPatch02
	db $10,4
	dw SnowForestGfxPatch03
	db $18,2
	dw SnowForestGfxPatch04
	db $1c,4
	dw SnowForestGfxPatch05
	db $21,2
	dw SnowForestGfxPatch06
	db $27,1
	dw SnowForestGfxPatch07
	db $2d,6
	dw SnowForestGfxPatch08
	db $34,1
	dw SnowForestGfxPatch09
	db $3d,3
	dw SnowForestGfxPatch10
	db $54,2
	dw SnowForestGfxPatch11
	db $ff

SnowSafariGfxPatchTable:
	db $04,1
	dw SnowSafariGfxPatch00
	db $07,3
	dw SnowSafariGfxPatch01
	db $0c,1
	dw SnowSafariGfxPatch02
	db $10,2
	dw SnowSafariGfxPatch03
	db $18,2
	dw SnowSafariGfxPatch04
	db $1c,4
	dw SnowSafariGfxPatch05
	db $21,2
	dw SnowSafariGfxPatch06
	db $2d,3
	dw SnowSafariGfxPatch07
	db $31,2
	dw SnowSafariGfxPatch08
	db $34,1
	dw SnowSafariGfxPatch09
	db $3d,3
	dw SnowSafariGfxPatch10
	db $ff

SnowPlateauGfxPatchTable:
	db $01,2
	dw SnowPlateauGfxPatch00
	db $07,4
	dw SnowPlateauGfxPatch01
	db $11,1
	dw SnowPlateauGfxPatch02
	db $17,4
	dw SnowPlateauGfxPatch03
	db $1d,2
	dw SnowPlateauGfxPatch04
	db $22,1
	dw SnowPlateauGfxPatch05
	db $24,1
	dw SnowPlateauGfxPatch06
	db $27,1
	dw SnowPlateauGfxPatch07
	db $2a,3
	dw SnowPlateauGfxPatch08
	db $34,1
	dw SnowPlateauGfxPatch09
	db $36,2
	dw SnowPlateauGfxPatch10
	db $39,6
	dw SnowPlateauGfxPatch11
	db $40,4
	dw SnowPlateauGfxPatch12
	db $54,1
	dw SnowPlateauGfxPatch13
	db $5d,1
	dw SnowPlateauGfxPatch14
	db $ff

SnowOverworldGfxPatch00:
	INCBIN "gfx/tilesets/overworld_snow.2bpp", $10, $20
SnowOverworldGfxPatch01:
	INCBIN "gfx/tilesets/overworld_snow.2bpp", $50, $50
SnowOverworldGfxPatch02:
	INCBIN "gfx/tilesets/overworld_snow.2bpp", $110, $30
SnowOverworldGfxPatch03:
	INCBIN "gfx/tilesets/overworld_snow.2bpp", $150, $50
SnowOverworldGfxPatch04:
	INCBIN "gfx/tilesets/overworld_snow.2bpp", $1d0, $20
SnowOverworldGfxPatch05:
	INCBIN "gfx/tilesets/overworld_snow.2bpp", $240, $b0
SnowOverworldGfxPatch06:
	INCBIN "gfx/tilesets/overworld_snow.2bpp", $320, $10
SnowOverworldGfxPatch07:
	INCBIN "gfx/tilesets/overworld_snow.2bpp", $340, $10
SnowOverworldGfxPatch08:
	INCBIN "gfx/tilesets/overworld_snow.2bpp", $360, $30
SnowOverworldGfxPatch09:
	INCBIN "gfx/tilesets/overworld_snow.2bpp", $3d0, $20
SnowOverworldGfxPatch10:
	INCBIN "gfx/tilesets/overworld_snow.2bpp", $400, $20
SnowOverworldGfxPatch11:
	INCBIN "gfx/tilesets/overworld_snow.2bpp", $460, $40
SnowOverworldGfxPatch12:
	INCBIN "gfx/tilesets/overworld_snow.2bpp", $4c0, $20
SnowOverworldGfxPatch13:
	INCBIN "gfx/tilesets/overworld_snow.2bpp", $500, $20
SnowOverworldGfxPatch14:
	INCBIN "gfx/tilesets/overworld_snow.2bpp", $530, $10
SnowOverworldGfxPatch15:
	INCBIN "gfx/tilesets/overworld_snow.2bpp", $560, $40
SnowOverworldGfxPatch16:
	INCBIN "gfx/tilesets/overworld_snow.2bpp", $5c0, $20

SnowForestGfxPatch00:
	INCBIN "gfx/tilesets/forest_snow.2bpp", $20, $30
SnowForestGfxPatch01:
	INCBIN "gfx/tilesets/forest_snow.2bpp", $70, $30
SnowForestGfxPatch02:
	INCBIN "gfx/tilesets/forest_snow.2bpp", $c0, $10
SnowForestGfxPatch03:
	INCBIN "gfx/tilesets/forest_snow.2bpp", $100, $40
SnowForestGfxPatch04:
	INCBIN "gfx/tilesets/forest_snow.2bpp", $180, $20
SnowForestGfxPatch05:
	INCBIN "gfx/tilesets/forest_snow.2bpp", $1c0, $40
SnowForestGfxPatch06:
	INCBIN "gfx/tilesets/forest_snow.2bpp", $210, $20
SnowForestGfxPatch07:
	INCBIN "gfx/tilesets/forest_snow.2bpp", $270, $10
SnowForestGfxPatch08:
	INCBIN "gfx/tilesets/forest_snow.2bpp", $2d0, $60
SnowForestGfxPatch09:
	INCBIN "gfx/tilesets/forest_snow.2bpp", $340, $10
SnowForestGfxPatch10:
	INCBIN "gfx/tilesets/forest_snow.2bpp", $3d0, $30
SnowForestGfxPatch11:
	INCBIN "gfx/tilesets/forest_snow.2bpp", $540, $20

SnowSafariGfxPatch00:
	INCBIN "gfx/tilesets/safari_snow.2bpp", $40, $10
SnowSafariGfxPatch01:
	INCBIN "gfx/tilesets/safari_snow.2bpp", $70, $30
SnowSafariGfxPatch02:
	INCBIN "gfx/tilesets/safari_snow.2bpp", $c0, $10
SnowSafariGfxPatch03:
	INCBIN "gfx/tilesets/safari_snow.2bpp", $100, $20
SnowSafariGfxPatch04:
	INCBIN "gfx/tilesets/safari_snow.2bpp", $180, $20
SnowSafariGfxPatch05:
	INCBIN "gfx/tilesets/safari_snow.2bpp", $1c0, $40
SnowSafariGfxPatch06:
	INCBIN "gfx/tilesets/safari_snow.2bpp", $210, $20
SnowSafariGfxPatch07:
	INCBIN "gfx/tilesets/safari_snow.2bpp", $2d0, $30
SnowSafariGfxPatch08:
	INCBIN "gfx/tilesets/safari_snow.2bpp", $310, $20
SnowSafariGfxPatch09:
	INCBIN "gfx/tilesets/safari_snow.2bpp", $340, $10
SnowSafariGfxPatch10:
	INCBIN "gfx/tilesets/safari_snow.2bpp", $3d0, $30

SnowPlateauGfxPatch00:
	INCBIN "gfx/tilesets/plateau_snow.t6.2bpp", $10, $20
SnowPlateauGfxPatch01:
	INCBIN "gfx/tilesets/plateau_snow.t6.2bpp", $70, $40
SnowPlateauGfxPatch02:
	INCBIN "gfx/tilesets/plateau_snow.t6.2bpp", $110, $10
SnowPlateauGfxPatch03:
	INCBIN "gfx/tilesets/plateau_snow.t6.2bpp", $170, $40
SnowPlateauGfxPatch04:
	INCBIN "gfx/tilesets/plateau_snow.t6.2bpp", $1d0, $20
SnowPlateauGfxPatch05:
	INCBIN "gfx/tilesets/plateau_snow.t6.2bpp", $220, $10
SnowPlateauGfxPatch06:
	INCBIN "gfx/tilesets/plateau_snow.t6.2bpp", $240, $10
SnowPlateauGfxPatch07:
	INCBIN "gfx/tilesets/plateau_snow.t6.2bpp", $270, $10
SnowPlateauGfxPatch08:
	INCBIN "gfx/tilesets/plateau_snow.t6.2bpp", $2a0, $30
SnowPlateauGfxPatch09:
	INCBIN "gfx/tilesets/plateau_snow.t6.2bpp", $340, $10
SnowPlateauGfxPatch10:
	INCBIN "gfx/tilesets/plateau_snow.t6.2bpp", $360, $20
SnowPlateauGfxPatch11:
	INCBIN "gfx/tilesets/plateau_snow.t6.2bpp", $390, $60
SnowPlateauGfxPatch12:
	INCBIN "gfx/tilesets/plateau_snow.t6.2bpp", $400, $40
SnowPlateauGfxPatch13:
	INCBIN "gfx/blocksets/plateau_snow.bst", $a0, $10
SnowPlateauGfxPatch14:
	INCBIN "gfx/blocksets/plateau_snow.bst", $130, $10

SnowTextBoxTiles0:
	INCBIN "gfx/text_box_snow.2bpp", $00, $30
SnowTextBoxTiles4:
	INCBIN "gfx/text_box_snow.2bpp", $40, $40

ApplySnowCurrentMapViewBlockPatches::
; LoadCurrentMapView 当前处于 tileset ROM bank，因此不能直接从 ROM0 的 DrawTileBlock
; 读取位于其他 bank 的 Snowy 差分表。这里在 30 个普通 block 都绘制完成以后只跨
; bank 一次，再对 wTileMapBackup 的 5x6 block 区域应用原 Snowy blockset 的差异。
	ld a,[wOptions]
	bit 4,a
	ret z
	ld a,[wCurMapTileset]
	cp OVERWORLD
	jr z,.supported
	cp FOREST
	jr z,.supported
	cp SAFARI
	jr z,.supported
	cp PLATEAU
	ret nz
.supported
	ld a,[wCurrentTileBlockMapViewPointer]
	ld e,a
	ld a,[wCurrentTileBlockMapViewPointer + 1]
	ld d,a
	ld hl,wTileMapBackup
	ld b,5
.rowLoop
	push bc
	push de
	push hl
	ld b,6
.columnLoop
	push bc
	push de
	push hl
	ld a,[de]
	ld c,a
	call .applyBlock
	pop hl
	pop de
	pop bc
	inc de
	inc hl
	inc hl
	inc hl
	inc hl
	dec b
	jr nz,.columnLoop
	pop hl
	ld bc,$0060
	add hl,bc
	pop de
	ld a,[wCurMapWidth]
	add MAP_BORDER * 2
	add e
	ld e,a
	jr nc,.nextRow
	inc d
.nextRow
	pop bc
	dec b
	jr nz,.rowLoop
	ret

.applyBlock
; Input: c = block ID, hl = upper-left tile of the already-drawn 4x4 block.
; 旧实现会对每个可见 block 线性扫描最多 44 条稀疏表；60fps 下滚屏时开销明显。
; 现在按 block ID 直接索引 16-bit mask，查找固定为 O(1)，Snowy 画面结果不变。
	ld a,[wCurMapTileset]
	cp OVERWORLD
	jr z,.overworld
	cp FOREST
	jr z,.forest
	cp SAFARI
	jr z,.safari
	; Plateau
	ld a,c
	ld de,SnowPlateauBlockMasks
	ld b,SNOW_PLATEAU_BLOCK_MASK_COUNT
	call .loadMask
	ret nc
	ld d,3
	jr .applyMask

.overworld
	ld a,c
	ld de,SnowOverworldBlockMasks
	ld b,SNOW_OVERWORLD_BLOCK_MASK_COUNT
	call .loadMask
	ret nc
	ld d,0
	jr .applyMask
.forest
	ld a,c
	ld de,SnowForestBlockMasks
	ld b,SNOW_FOREST_BLOCK_MASK_COUNT
	call .loadMask
	ret nc
	ld d,1
	jr .applyMask
.safari
	ld a,c
	ld de,SnowSafariBlockMasks
	ld b,SNOW_SAFARI_BLOCK_MASK_COUNT
	call .loadMask
	ret nc
	ld d,2

.applyMask
	ld e,16
.nextTile
	srl b
	rr c
	jr nc,.advance
	ld a,d
	and a
	jr z,.patchOverworld
	dec a
	jr z,.patchForest
	dec a
	jr z,.patchSafari
	; Plateau: $2c -> $2d
	ld a,[hl]
	cp $2c
	jr nz,.advance
	ld [hl],$2d
	jr .advance
.patchOverworld
	ld a,[hl]
	cp $2c
	jr z,.overworldSnowTile
	cp $03
	jr z,.overworldPathTile
	cp $13
	jr nz,.advance
.overworldSnowTile
	ld [hl],$39
	jr .advance
.overworldPathTile
	ld [hl],$30
	jr .advance
.patchForest
	ld a,[hl]
	cp $30
	jr nz,.advance
	ld [hl],$5e
	jr .advance
.patchSafari
	ld a,[hl]
	cp $5e
	jr nz,.advance
	ld [hl],$30
.advance
	inc hl
	dec e
	ld a,e
	and 3
	jr nz,.nextTile
	ld a,e
	and a
	ret z
	; wTileMapBackup 中每个 4x4 block 行的步长为 24，已前进 4，所以再加 20。
	ld a,20
	add l
	ld l,a
	jr nc,.nextTile
	inc h
	jr .nextTile

.loadMask
; Input: a = block ID, de = dense mask table, b = number of table entries.
; Output: BC = 16-bit mask, carry set only when the mask is non-zero.
	cp b
	jr nc,.noMask
	ld c,a
	ld b,0
	sla c
	rl b
	push hl
	ld h,d
	ld l,e
	add hl,bc
	ld a,[hli]
	ld c,a
	ld a,[hl]
	ld b,a
	pop hl
	ld a,b
	or c
	jr z,.noMask
	scf
	ret
.noMask
	and a
	ret

; Dense block-ID -> 16-bit patch mask tables.
; 以少量 ROM 空间换掉每次滚屏时的线性搜索，避免 Snowy 在 60fps 模式下拖慢。
SNOW_FOREST_BLOCK_MASK_COUNT EQU $66
SnowForestBlockMasks::
	; $00-$07
	dw $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000
	; $08-$0f
	dw $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000
	; $10-$17
	dw $0000, $0000, $0000, $0000, $0049, $0000, $0000, $0081
	; $18-$1f
	dw $1800, $0000, $0000, $912d, $0000, $0000, $0005, $0500
	; $20-$27
	dw $0000, $4908, $0040, $0002, $4000, $0200, $0009, $0041
	; $28-$2f
	dw $0000, $912d, $0409, $1208, $4804, $0000, $2109, $0000
	; $30-$37
	dw $0000, $0000, $0000, $1092, $112d, $0014, $048d, $0404
	; $38-$3f
	dw $2501, $0500, $6d04, $0101, $0000, $0000, $0000, $0000
	; $40-$47
	dw $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000
	; $48-$4f
	dw $0400, $0100, $0000, $0000, $0004, $0001, $0000, $0000
	; $50-$57
	dw $0000, $0000, $0000, $0000, $0000, $0000, $feef, $f77f
	; $58-$5f
	dw $fff9, $9fff, $0000, $0000, $0000, $0000, $0000, $0000
	; $60-$65
	dw $0000, $0000, $0000, $0000, $ccc4, $0032
SNOW_SAFARI_BLOCK_MASK_COUNT EQU $29
SnowSafariBlockMasks::
	; $00-$07
	dw $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000
	; $08-$0f
	dw $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000
	; $10-$17
	dw $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000
	; $18-$1f
	dw $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000
	; $20-$27
	dw $3109, $0000, $0000, $0000, $0000, $0000, $0000, $0000
	; $28-$28
	dw $912d
SNOW_OVERWORLD_BLOCK_MASK_COUNT EQU $9a
SnowOverworldBlockMasks::
	; $00-$07
	dw $0000, $0000, $0000, $0000, $0000, $0000, $0000, $00a1
	; $08-$0f
	dw $0000, $0000, $912d, $0000, $0000, $0000, $0000, $0000
	; $10-$17
	dw $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000
	; $18-$1f
	dw $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000
	; $20-$27
	dw $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000
	; $28-$2f
	dw $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0c09
	; $30-$37
	dw $0000, $0000, $0400, $0100, $0004, $0401, $0100, $0000
	; $38-$3f
	dw $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000
	; $40-$47
	dw $4904, $4081, $0021, $0000, $0000, $0000, $0000, $0000
	; $48-$4f
	dw $0000, $0000, $0000, $0000, $0401, $0101, $0804, $0001
	; $50-$57
	dw $0008, $6100, $0081, $2501, $0000, $0000, $0000, $0000
	; $58-$5f
	dw $4084, $0102, $0204, $0001, $0000, $0000, $0000, $0000
	; $60-$67
	dw $0001, $0000, $0400, $0200, $0000, $0000, $0000, $0000
	; $68-$6f
	dw $0000, $0000, $0000, $0000, $0500, $0404, $0101, $0005
	; $70-$77
	dw $0000, $0000, $0000, $0000, $95ad, $0000, $0000, $0000
	; $78-$7f
	dw $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000
	; $80-$87
	dw $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000
	; $88-$8f
	dw $0000, $0000, $0000, $0028, $0000, $8200, $1200, $0000
	; $90-$97
	dw $0020, $4100, $0014, $0422, $2502, $0028, $2082, $2025
	; $98-$99
	dw $2040, $0214
SNOW_PLATEAU_BLOCK_MASK_COUNT EQU $2b
SnowPlateauBlockMasks::
	; $00-$07
	dw $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000
	; $08-$0f
	dw $0000, $0000, $912d, $0000, $0000, $0000, $0000, $0000
	; $10-$17
	dw $0000, $0000, $0000, $0102, $0000, $0000, $0804, $0000
	; $18-$1f
	dw $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000
	; $20-$27
	dw $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000
	; $28-$2a
	dw $0000, $802d, $112d
