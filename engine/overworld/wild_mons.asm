LoadWildData:
	ld hl, WildDataTable
	ld a, [wCurMap]
	ld c, a

.findMap
	ld a, [hli]
	cp $ff
	jr z, .noMons
	cp c
	jr z, .foundMap
	inc hl
	inc hl
	jr .findMap

.foundMap
	ld a, [hli]
	ld h, [hl]
	ld l, a
	jr .load

.noMons
	ld hl, NoMons

.load
	ld a, [hli]
	ld [wGrassRate], a
	and a
	jr z, .noGrassData
	push hl
	ld de, wGrassMons
	ld bc, $0014
	call CopyData
	pop hl
	ld bc, $0014
	add hl, bc
.noGrassData
	ld a, [hli]
	ld [wWaterRate], a
	and a
	ret z
	ld de, wWaterMons
	ld bc, $0014
	jp CopyData

INCLUDE "data/wild_mons.asm"
