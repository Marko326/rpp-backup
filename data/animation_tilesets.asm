; Raw battle-animation tile graphics.
;
; Keep both tilesets in the same ROM bank: LoadAnimationTileset stores only
; 16-bit addresses in AnimationTilesetPointers and supplies
; BANK(AnimationTileset1) to CopyVideoData for every entry.
; The assets are intentionally kept raw and readable; this relocation only
; removes graphics pressure from the fixed battle-animation code/data bank.

AnimationTileset1:
	INCBIN "gfx/attack_anim_1.2bpp"
AnimationTileset1End:
	ASSERT AnimationTileset1End - AnimationTileset1 == 79 * 16

AnimationTileset2:
	INCBIN "gfx/attack_anim_2.2bpp"
AnimationTileset2End:
	ASSERT AnimationTileset2End - AnimationTileset2 == 79 * 16

; AnimationTilesetPointers stores only 16-bit addresses and the loader uses
; BANK(AnimationTileset1) for every entry, so both resources must stay together.
ASSERT BANK(AnimationTileset1) == BANK(AnimationTileset2)
