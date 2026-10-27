; P3-001 runtime bridge for the first two stable Johto map IDs.
; The legacy Kanto mapconst table remains untouched; $FC is only the live handle.

JohtoPilotSyncMapIdentity::
    ld a, [wCurMap]
    cp JOHTO_RUNTIME_MAP_HANDLE
    jr z, .nativeJohto

    ; A legacy map is physically Kanto. Keep the last native key while on the
    ; ferry, so its dynamic return warp can restore the Johto stable ID.
    xor a
    ld [wCurRegion], a
    ld a, [wCurMap]
    ld [wCurLocalMapID], a
    ld a, [wLastMap]
    cp JOHTO_RUNTIME_MAP_HANDLE
    ret z
    xor a
    ld [wLastRegion], a
    ld a, [wLastMap]
    ld [wLastLocalMapID], a
    ret

.nativeJohto
    ld a, [wRegionStateMagic0]
    cp JOHTO_REGION_MAGIC_0
    jp nz, SoftReset
    ld a, [wRegionStateMagic1]
    cp JOHTO_REGION_MAGIC_1
    jp nz, SoftReset
    ld a, [wCurRegion]
    cp MAP_REGION_JOHTO
    jp nz, SoftReset
    ld a, [wCurLocalMapID]
    ld e, a
    call GetJohtoActiveSlot
    ld a, e
    cp JOHTO_INVALID_ACTIVE_SLOT
    jp z, SoftReset
    ret

; Resolve a warp target after the source/last-map identity has been recorded.
; Ordinary Kanto IDs pass through unchanged. $FE is the explicit ferry selector:
; destination warp 0 = New Bark; destination warp 2 = Vermilion Ferry Dock.
; $FC is reserved here for the ferry's dynamic return-to-last-native-map warp.
JohtoPilotResolveWarpDestination::
    ld a, [hWarpDestinationMap]
    cp JOHTO_REGION_WARP_ESCAPE
    jr z, .explicitRegionWarp
    cp JOHTO_RUNTIME_MAP_HANDLE
    jr z, .lastNativeMap
    ld e, a
    ret

.explicitRegionWarp
    ld a, [wDestinationWarpID]
    and a
    jr z, .newBark
    cp 2
    jr z, .vermilion
    jp SoftReset

.newBark
    ld e, JOHTO_NEW_BARK_LOCAL_ID
    call GetJohtoActiveSlot
    ld a, e
    cp JOHTO_INVALID_ACTIVE_SLOT
    jp z, SoftReset
    ld a, MAP_REGION_JOHTO
    ld [wCurRegion], a
    ld a, JOHTO_NEW_BARK_LOCAL_ID
    ld [wCurLocalMapID], a
    ld e, JOHTO_RUNTIME_MAP_HANDLE
    ret

.vermilion
    xor a
    ld [wCurRegion], a
    ld a, VERMILION_FERRY_DOCK
    ld [wCurLocalMapID], a
    ld e, VERMILION_FERRY_DOCK
    ret

.lastNativeMap
    ld a, [wLastMap]
    cp JOHTO_RUNTIME_MAP_HANDLE
    jp nz, SoftReset
    ld a, [wLastRegion]
    cp MAP_REGION_JOHTO
    jp nz, SoftReset
    ld a, [wLastLocalMapID]
    ld e, a
    call GetJohtoActiveSlot
    ld a, e
    cp JOHTO_INVALID_ACTIVE_SLOT
    jp z, SoftReset
    ld a, [wLastRegion]
    ld [wCurRegion], a
    ld a, [wLastLocalMapID]
    ld [wCurLocalMapID], a
    ld e, JOHTO_RUNTIME_MAP_HANDLE
    ret

JohtoPilotLoadMapMusic::
    ld a, [wCurRegion]
    cp MAP_REGION_JOHTO
    jp nz, SoftReset
    ld a, [wCurLocalMapID]
    cp JOHTO_NEW_BARK_LOCAL_ID
    jr z, .newBark
    cp JOHTO_ROUTE_29_LOCAL_ID
    jr z, .route29
    cp JOHTO_CHERRYGROVE_LOCAL_ID
    jr z, .cherrygrove
    jp SoftReset
.newBark
    ld a, MUSIC_PALLET_TOWN
    jr .storeMusic
.route29
    ld a, MUSIC_ROUTES1
    jr .storeMusic
.cherrygrove
    ld a, MUSIC_CITIES1
.storeMusic
    ld [wMapMusicSoundID], a
    xor a ; both base RBY map songs are in music bank 0; music style remaps them
    ld [wMapMusicROMBank], a
    ret
