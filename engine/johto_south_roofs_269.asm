; MAP-269: Gold map-group roof sprites for the active Johto outdoor maps.
; Gold 24x24 PNG source -> nine 8x8 tiles, generated .2bpp by Makefile.
; Keep these banked and never commit generated .2bpp outputs.
JohtoNewBarkRoofs_GFX:: INCBIN "gfx/tilesets/johto_new_bark_roofs.2bpp"
JohtoVioletRoofs_GFX:: INCBIN "gfx/tilesets/johto_violet_roofs.2bpp"
JohtoAzaleaRoofs_GFX:: INCBIN "gfx/tilesets/johto_azalea_roofs.2bpp"
JohtoGoldenrodRoofs_GFX:: INCBIN "gfx/tilesets/johto_goldenrod_roofs.2bpp"

 ; FIX-270: reuse the two ROM0 farcalls that already existed before .269.
 ; Do not call extra banked roof code from Home: that made ROM0 run out
 ; of space (linker complained about "Home Copy Data").
 ; This wrapper is invoked where ApplySnowTilesetGfxPatch used to be:
 ; normal/snowy tileset copy first, then Gold roof tiles.  Thus it works
 ; on initial load AND ReloadMapData/ReloadTilesetTilePatterns.
JohtoSouthTilesetGfxFinalizer270::
    callba ApplySnowTilesetGfxPatch
    jp JohtoSouthRoofAfterTilesetLoad

 ; The seamless path already called InitMapSprites via callba.  Keep the
 ; existing ROM0 LoadTileBlockMap next; its map-bank side effects must still
 ; happen from the Home bank.  VRAM roof copy is independent of blockmap WRAM.
JohtoSouthConnectionSpritesAndRoofs270::
    callba InitMapSprites
    jp JohtoSouthRoofOnConnection

JohtoSouthRoofAfterTilesetLoad::
    call SelectJohtoSouthRoofSource269
    ret nc
    ld d,h
    ld e,l
    ld hl,vTileset + $0a * $10
    push hl
    ld h,d
    ld l,e
    pop de
    ld bc,9 * $10
    jp FarCopyData2

JohtoSouthRoofOnConnection::
    call SelectJohtoSouthRoofSource269
    ret nc
    ld d,h
    ld e,l
    ld hl,vTileset + $0a * $10
    ld b,a
    ld c,9
    jp CopyVideoData

; Selection is shared by reload and seamless connections (the latter otherwise
; inherit the previous town's nine roof tiles). Do not touch Kanto or indoors.
SelectJohtoSouthRoofSource269::
    ld a,[wCurMap]
    cp JOHTO_RUNTIME_MAP_HANDLE
    jp nz,.no
    ld a,[wCurRegion]
    cp MAP_REGION_JOHTO
    jp nz,.no
    ld a,[wCurMapTileset]
    cp JOHTO_PILOT
    jp z,.id
    cp JOHTO_MODERN
    jp nz,.no
.id
    ld a,[wCurLocalMapID]
    cp JOHTO_ROUTE_33_LOCAL_ID
    jp z,.azalea
    cp JOHTO_AZALEA_TOWN_LOCAL_ID
    jp z,.azalea
    cp JOHTO_ROUTE_34_LOCAL_ID
    jp z,.goldenrod
    cp JOHTO_GOLDENROD_CITY_LOCAL_ID
    jp z,.goldenrod
    cp JOHTO_VIOLET_CITY_LOCAL_ID
    jp z,.violet
    cp JOHTO_ROUTE_32_LOCAL_ID
    jp z,.violet
    cp JOHTO_ROUTE_36_LOCAL_ID
    jp z,.violet
    cp JOHTO_NEW_BARK_LOCAL_ID
    jp z,.newbark
    cp JOHTO_ROUTE_29_LOCAL_ID
    jp z,.newbark
    cp JOHTO_CHERRYGROVE_LOCAL_ID
    jp z,.newbark
    cp JOHTO_ROUTE_30_LOCAL_ID
    jp z,.newbark
    cp JOHTO_ROUTE_31_LOCAL_ID
    jp nz,.no
.newbark
    ld hl,JohtoNewBarkRoofs_GFX
    ld a,BANK(JohtoNewBarkRoofs_GFX)
    jp .yes
.violet
    ld hl,JohtoVioletRoofs_GFX
    ld a,BANK(JohtoVioletRoofs_GFX)
    jp .yes
.azalea
    ld hl,JohtoAzaleaRoofs_GFX
    ld a,BANK(JohtoAzaleaRoofs_GFX)
    jp .yes
.goldenrod
    ld hl,JohtoGoldenrodRoofs_GFX
    ld a,BANK(JohtoGoldenrodRoofs_GFX)
.yes
    scf
    ret
.no
    and a
    ret
