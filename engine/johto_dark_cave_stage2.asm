; REF-349 stage2. Each Gold collision quadrant maps to a byte in 40x36.
; Role bytes: floor0 wall1 water2 up-wall3 hop-down4 hop-left5 carpet6 cave7.
; Always use stable ID190 in dispatching; other Johto maps stay unchanged.
; Input B=Y, C=X; result A=role (out of bounds => 1 WALL). BC/DE unchanged.
JohtoDarkCaveRoleAt::
    ld a, [wCurLocalMapID]
    cp JOHTO_DARK_CAVE_BLACKTHORN_ENTRANCE_LOCAL_ID
    jp z, .blackthorn
    ld a, b
    cp 36
    jr nc, .wall
    ld a, c
    cp 40
    jr nc, .wall
    push de
    ld l, b
    ld h, 0
    add hl, hl
    add hl, hl
    add hl, hl ; y*8
    ld d, h
    ld e, l
    add hl, hl
    add hl, hl ; y*32
    add hl, de ; y*40
    ld d, 0
    ld e, c
    add hl, de
    ld de, JohtoDarkCaveGoldRoles
    add hl, de
    ld a, [hl]
    pop de
    ret
.blackthorn
    ld a, b
    cp 36
    jr nc, .wall
    ld a, c
    cp 30
    jr nc, .wall
    push de
    ld l, b
    ld h, 0
    add hl, hl ; 2y
    ld d, h
    ld e, l
    add hl, hl ; 4y
    add hl, de ; 6y
    ld d, h
    ld e, l ; preserve 6y
    add hl, hl ; 12y
    add hl, hl ; 24y
    add hl, de ; 30y (LR35902 has no SBC HL,DE)
    ld d, 0
    ld e, c
    add hl, de
    ld de, JohtoDarkCaveBlackthornGoldRoles
    add hl, de
    ld a, [hl]
    pop de
    ret
.wall
    ld a, 1
    ret

; Look at target cell of current facing, including guarded bounds.
; Preserves BC, DE, HL (the caller may be in a different ROM Bank).
JohtoDarkCaveRoleAhead::
    push bc
    push hl
    ld a, [wYCoord]
    ld b, a
    ld a, [wXCoord]
    ld c, a
    ld a, [wPlayerDirection]
    cp PLAYER_DIR_UP
    jr z, .up
    cp PLAYER_DIR_DOWN
    jr z, .down
    cp PLAYER_DIR_LEFT
    jr z, .left
    cp PLAYER_DIR_RIGHT
    jr nz, .invalid
    inc c
    jr .probe
.up
    dec b
    jr .probe
.down
    inc b
    jr .probe
.left
    dec c
.probe
    call JohtoDarkCaveRoleAt
    jr .done
.invalid
    ld a, 1
.done
    pop hl
    pop bc
    ret

; Gold BikeFunction allows CAVE + FLOOR_TILE permission. The Gold
; collision low nibble is FLOOR for both FLOOR ($00) and WARP_CARPET_DOWN
; ($70), but not WATER, WALL, HOP, UP_WALL or the open CAVE transfer tile (role 7).
; Carry=allowed, A/BC/HL preserved only as needed by the caller; the ROMX
; bank trampoline preserves flags so IsBikeRidingAllowed can return Carry.
JohtoDarkCaveBikeFloorAllowed349::
    ld a, [wCurMap]
    cp JOHTO_RUNTIME_MAP_HANDLE
    jr nz, .deny
    ld a, [wCurRegion]
    cp MAP_REGION_JOHTO
    jr nz, .deny
    ld a, [wCurLocalMapID]
    cp JOHTO_DARK_CAVE_VIOLET_ENTRANCE_LOCAL_ID
    jr z, .supported365
    cp JOHTO_DARK_CAVE_BLACKTHORN_ENTRANCE_LOCAL_ID
    jr nz, .deny
.supported365
    push bc
    push hl
    ld a, [wYCoord]
    ld b, a
    ld a, [wXCoord]
    ld c, a
    call JohtoDarkCaveRoleAt
    pop hl
    pop bc
    and a ; role 0 = Gold FLOOR
    jr z, .allowed
    cp 6 ; WARP_CARPET_DOWN ($70) is also Gold FLOOR permission
    jr z, .allowed
.deny
    and a ; carry clear
    ret
.allowed
    scf
    ret

; Facing north FROM an UP_WALL is forbidden; entering it from above
; (DOWN) is also forbidden. HOPs work only via HandleLedges on takeoff.
; Output E=0 pass / 1 block; preserve BC and HL through callab.
JohtoDarkCaveLandDecision::
    ld e, 1
    ld a, [wPlayerDirection]
    cp PLAYER_DIR_UP
    jr nz, .target
    push bc
    push hl
    ld a, [wYCoord]
    ld b, a
    ld a, [wXCoord]
    ld c, a
    call JohtoDarkCaveRoleAt
    pop hl
    pop bc
    cp 3
    ret z
.target
    call JohtoDarkCaveRoleAhead
    cp 1 ; wall
    ret z
    ; REF-365: Gold role7 is the exact Violet->Blackthorn STEP_IN cave door.
    cp 2 ; water must be entered through Surf field move
    jr nz, .directional
    ld a, [wWalkBikeSurfState]
    cp 2
    ret nz
    jr .pass
.directional
    cp 3 ; UP_WALL: cannot enter from north
    jr nz, .downHop
    ld a, [wPlayerDirection]
    cp PLAYER_DIR_DOWN
    ret z
    jr .pass
.downHop
    cp 4
    jr nz, .leftHop
    ld a, [wPlayerDirection]
    cp PLAYER_DIR_UP
    ret z
    jr .pass
.leftHop
    cp 5
    jr nz, .pass
    ld a, [wPlayerDirection]
    cp PLAYER_DIR_RIGHT
    ret z
.pass
    ld e, 0
    ret

; Carry = water immediately ahead. IsSurfTile can safely invoke this from
; any map; the identity check prevents broadening Kanto or other caves.
JohtoDarkCaveWaterAhead::
    ld a, [wCurMap]
    cp JOHTO_RUNTIME_MAP_HANDLE
    jr nz, .no
    ld a, [wCurRegion]
    cp MAP_REGION_JOHTO
    jr nz, .no
    ld a, [wCurLocalMapID]
    cp JOHTO_DARK_CAVE_VIOLET_ENTRANCE_LOCAL_ID
    jr z, .supported365
    cp JOHTO_DARK_CAVE_BLACKTHORN_ENTRANCE_LOCAL_ID
    jr nz, .no
.supported365
    call JohtoDarkCaveRoleAhead
    cp 2
    jr nz, .no
    scf
    ret
.no
    and a
    ret

; Surf movement enters here only for the Dark Cave tileset. Keep it
; stable-map-scoped: a future Blackthorn-side map has a DIFFERENT 15x18
; role grid and must never read Violet's 40x36 table by accident.
; E=2 WATER, E=0 Gold-legal LAND shore, E=1 blocked.
JohtoDarkCaveSurfDecision::
    ld e, 1
    ld a, [wCurMap]
    cp JOHTO_RUNTIME_MAP_HANDLE
    ret nz
    ld a, [wCurRegion]
    cp MAP_REGION_JOHTO
    ret nz
    ld a, [wCurLocalMapID]
    cp JOHTO_DARK_CAVE_VIOLET_ENTRANCE_LOCAL_ID
    jr z, .supported365
    cp JOHTO_DARK_CAVE_BLACKTHORN_ENTRANCE_LOCAL_ID
    ret nz
.supported365
    call JohtoDarkCaveRoleAhead
    cp 2
    jr nz, .shore
    ld e, 2
    ret
.shore
    cp 0 ; FLOOR is LAND_TILE in Gold
    jr z, .land
    cp 6 ; the exit carpet is passable land, but not WATER
    jr z, .land
    cp 3 ; UP_WALL is land only from permitted directions
    jr z, .upWall
    cp 4 ; HOP_DOWN is land unless moving against the ledge
    jr z, .hopDown
    cp 5 ; HOP_LEFT is land unless moving against the ledge
    jr z, .hopLeft
    ret ; WALL and open CAVE transfer tile are not shoreline
.upWall
    ld a, [wPlayerDirection]
    cp PLAYER_DIR_DOWN
    ret z
    jr .land
.hopDown
    ld a, [wPlayerDirection]
    cp PLAYER_DIR_UP
    ret z
    jr .land
.hopLeft
    ld a, [wPlayerDirection]
    cp PLAYER_DIR_RIGHT
    ret z
.land
    ld e, 0
    ret


; Carry=1: party Surf is badge-authorized. Carry=0: denied.
; Gold requires Fog Badge (Johto bit3); Soul Badge remains a documented
; temporary compatibility fallback for existing RPP saves without Johto gyms.
; All non-Dark-Cave maps retain their original Soul Badge requirement.
; The RST $18/callab trampoline preserves Carry through bank restoration.
JohtoSurfBadgeAllowed349::
    ld a, [wCurMap]
    cp JOHTO_RUNTIME_MAP_HANDLE
    jr nz, .legacy
    ld a, [wCurRegion]
    cp MAP_REGION_JOHTO
    jr nz, .legacy
    ld a, [wCurLocalMapID]
    cp JOHTO_DARK_CAVE_VIOLET_ENTRANCE_LOCAL_ID
    jr z, .supported365
    cp JOHTO_DARK_CAVE_BLACKTHORN_ENTRANCE_LOCAL_ID
    jr nz, .legacy
.supported365
    ld a, [wObtainedJohtoBadges]
    bit 3, a ; Fog Badge
    jr nz, .allowed
.legacy
    ld a, [wObtainedKantoBadges]
    bit 4, a ; Soul Badge
    jr nz, .allowed
    and a ; carry clear
    ret
.allowed
    scf
    ret


; Field Flash eligibility shared by Johto and Kanto.
; Only unlit caves can use Flash. Region-specific badge rules are unchanged:
; Johto Violet Dark Cave: Zephyr Badge or legacy Boulder fallback;
; Kanto Rock Tunnel 1F/B1F: Boulder Badge only.
; Checking both the cave identity and its dark palette avoids consuming Flash
; on a normal map, in an already-lit cave, or on another palette effect.
; This is in ROMX because the Bank $04 START menu Flash caller is tight.
; E=0 usable; E=1 blocked, with failure text already printed.
JohtoFlashEligibility349::
    ld a, [wCurMap]
    cp JOHTO_RUNTIME_MAP_HANDLE
    jr nz, .checkKantoCave
    ld a, [wCurRegion]
    cp MAP_REGION_JOHTO
    jr nz, .checkKantoCave
    ld a, [wCurLocalMapID]
    cp JOHTO_DARK_CAVE_VIOLET_ENTRANCE_LOCAL_ID
    jr z, .supported365
    cp JOHTO_DARK_CAVE_BLACKTHORN_ENTRANCE_LOCAL_ID
    jr nz, .notDark
.supported365
    ld a, [wMapPalOffset]
    cp 12 ; Johto unlit Dark Cave BG / visible OBJ
    jr nz, .notDark
    ; Gold requires Zephyr Badge. Keep the original Boulder fallback for
    ; existing saves until Johto Gyms become fully available.
    ld a, [wObtainedJohtoBadges]
    bit 0, a ; Zephyr Badge
    jr nz, .allowed
    jr .legacyBadge
.checkKantoCave
    ld a, [wCurMap]
    cp ROCK_TUNNEL_1
    jr z, .checkKantoDarkPalette
    cp ROCK_TUNNEL_2
    jr nz, .notDark
.checkKantoDarkPalette
    ld a, [wMapPalOffset]
    cp 6 ; Kanto unlit Rock Tunnel BG / OBJ
    jr nz, .notDark
.legacyBadge
    ld a, [wObtainedKantoBadges]
    bit 0, a ; original RBY Boulder Badge
    jr z, .missingBadge
.allowed
    ld e, 0
    ret
.missingBadge
    ld hl, .badgeText
    call PrintText
    ld e, 1
    ret
.notDark
    ld hl, .notDarkText
    call PrintText
    ; Do not return to the Party menu until the player acknowledges the
    ; failure with a fresh A press.  The text's plain @@ terminator does
    ; not wait by itself, so Party would otherwise replace it immediately.
    call WaitForFlashAOnly349
    ld e, 1
    ret
.badgeText
    TX_FAR _NewBadgeRequiredText
    db "@"
.notDarkText
    text "It's not dark here.@@"

; Requiring release first prevents the A used to select FLASH from also
; dismissing the error.  Unlike the standard A/B text prompt this is A-only.
; Keep this in ROMX rather than growing the near-full Bank $04 field menu.
WaitForFlashAOnly349::
    ld a, "▼"
    Coorda 18, 16
.waitForRelease
    call DelayFrame
    call Joypad
    ld a, [hJoyHeld]
    and A_BUTTON
    jr nz, .waitForRelease
.waitForNewA
    call DelayFrame
    call Joypad
    ld a, [hJoyPressed]
    and A_BUTTON
    jr z, .waitForNewA
    ld a, " "
    Coorda 18, 16
    ret

; Called by LoadMapData after the destination tile/palette upload. An unlit
; Dark Cave exit holds offset 12 through the old scene's fade, then clears it.
; With LCD-on safe loading, keep the target hidden (black) until player sprite
; graphics finish; OverworldLoop restores BGP/OBP from the final offset.
; LCD-off callers retain the original immediate palette restore.
JohtoDarkCavePreLCDPalette349::
    ld a, [wCurMap]
    cp JOHTO_RUNTIME_MAP_HANDLE
    ret nz
    ld a, [wCurRegion]
    cp MAP_REGION_JOHTO
    ret nz
    ld a, [wMapPalOffset]
    cp 12 ; FadePalJohtoDark349
    ret nz
    ld a, [wCurLocalMapID]
    cp JOHTO_DARK_CAVE_VIOLET_ENTRANCE_LOCAL_ID
    jr z, .apply
    cp JOHTO_DARK_CAVE_BLACKTHORN_ENTRANCE_LOCAL_ID
    jr z, .apply
    ; Deferred exit clear: the new Route31 map is now in VRAM, LCD still off.
    xor a
    ld [wMapPalOffset], a
.apply
    ldh a, [hMapLoadVRAMSafeFlag]
    and a
    ret nz ; stay black until LoadPlayerSpriteGraphics completes
    jp LoadGBPal

; REF-365 safe Dig/Escape Rope uses two SAVE-BACKED unused event bits.
; 00 means uninitialized (deny old saves), 01 Route31, 10 Route46, 11 Route45.
; No WRAM layout change and no modification to other event bits.
DEF JOHTO_DARK_CAVE_ANCHOR_BYTE EQU EVENT_9D6 / 8
ASSERT (EVENT_9D6 % 8) == 6
ASSERT (EVENT_9D7 % 8) == 7
JohtoDarkCaveRememberOutdoorSource365::
    ; E = source stable ID, preserve BC/HL at the calling side.
    ld a, e
    cp JOHTO_ROUTE_31_LOCAL_ID
    jr z, .route31
    cp JOHTO_ROUTE_46_LOCAL_ID
    jr z, .route46
    cp JOHTO_ROUTE_45_LOCAL_ID
    ret nz ; interior transfer MUST NOT rewrite the outdoor anchor
    ld b, $c0
    jr .save
.route31
    ld b, $40
    jr .save
.route46
    ld b, $80
.save
    ld hl, wEventFlags + JOHTO_DARK_CAVE_ANCHOR_BYTE
    ld a, [hl]
    and $3f
    or b
    ld [hl], a
    ret

JohtoDarkCaveEscapeAllowed365::
    ld a, [wCurMap]
    cp JOHTO_RUNTIME_MAP_HANDLE
    jr nz, .deny
    ld a, [wCurRegion]
    cp MAP_REGION_JOHTO
    jr nz, .deny
    ld a, [wCurLocalMapID]
    cp JOHTO_DARK_CAVE_VIOLET_ENTRANCE_LOCAL_ID
    jr z, .checkAnchor
    cp JOHTO_DARK_CAVE_BLACKTHORN_ENTRANCE_LOCAL_ID
    jr nz, .deny
.checkAnchor
    ld a, [wEventFlags + JOHTO_DARK_CAVE_ANCHOR_BYTE]
    and $c0
    jr z, .deny ; old save/invalid origin, never silently heal-center teleport
    scf
    ret
.deny
    and a
    ret

JohtoDarkCaveApplyEscape365::
    ; Called from the SPECIAL Warp resolver after CanUseEscapeRope approved.
    ; Preserve the original exterior entry even after both internal Warps.
    ld a, [wEventFlags + JOHTO_DARK_CAVE_ANCHOR_BYTE]
    and $c0
    cp $40
    jr z, .route31
    cp $80
    jr z, .route46
    ; Valid caller + 2-bit encoding => Route45.
    ld a, JOHTO_ROUTE_45_LOCAL_ID
    ld hl, .route45Data
    jr .land
.route31
    ld a, JOHTO_ROUTE_31_LOCAL_ID
    ld hl, .route31Data
    jr .land
.route46
    ld a, JOHTO_ROUTE_46_LOCAL_ID
    ld hl, .route46Data
.land
    ld [wCurLocalMapID], a
    ld a, JOHTO_RUNTIME_MAP_HANDLE
    ld [wCurMap], a
    ld [wDestinationMap], a
    ld a, MAP_REGION_JOHTO
    ld [wCurRegion], a
    ld de, wCurrentTileBlockMapViewPointer
    ld c, 6
.copy
    ld a, [hli]
    ld [de], a
    inc de
    dec c
    jr nz, .copy
    ret
.route31Data
    FLYWARP_DATA JOHTO_ROUTE_31_WIDTH, 6, 34
.route46Data
    FLYWARP_DATA JOHTO_ROUTE_46_WIDTH, 6, 14
.route45Data
    FLYWARP_DATA JOHTO_ROUTE_45_WIDTH, 6, 2
