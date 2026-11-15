; REF-369L: Gold-style Strength dust on all Johto maps, not the original
; blocking RPP SS Anne dust with global OBP1 palette flashing.
; Gold source: engine/overworld/map_objects.asm (SpawnStrengthBoulderDust,
; MovementFunction_BoulderDust), map_object_action.asm (SetFacingBoulderDust).
; REF-369N: Gold's FacingBoulderDust1/2 are FOUR 8x8 OAM entries
; showing the same $fe or $ff tile in a 2x2 square. REF-369L/M only drew
; one entry, which made ordinary pushing and the pit's post-hide puff
; look like a tiny dot. Keep the non-saved CD56-CD58 state / Johto-only path.

PlayStrengthPushSFX369L::
    ld a, [wCurMap]
    cp JOHTO_RUNTIME_MAP_HANDLE
    ld a, SFX_PUSH_BOULDER ; original RPP Kanto push sound
    jr nz, .play
    ld a, GSSFX_BURNED_TOWER_STRENGTH ; Gold's Strength sound
.play
    jp PlaySound

; REF-369R: two independent ephemeral 4-byte dust slots. Each contains
; cached screen Y, X, remaining display frames, and packed source/facing.
; Packed source bits: 7..4 = 1-based stone index, bit 2 = stone hidden and
; post-hide lifetime armed, bits 1..0 = accepted push direction.
; Slot A: CD56..CD59. Slot B: CD51..CD54, reused ONLY while overworld
; Strength smoke is active (the legacy animation scratch at CD50..CD55).
; Entering START and reloading maps clear BOTH timers. No save layout change.

BeginJohtoGoldStrengthDust369L::
    ld a, [wBoulderSpriteIndex]
    and a
    ret z
    cp 16
    ret nc
    swap a
    ld b, a
    ld a, [wSpriteStateData1 + 9]
    and $0c
    srl a
    srl a
    or b
    ld b, a ; source + accepted facing, not live player input
    ; Reuse an expired slot first. When both are active, evict the slot
    ; with the shorter remaining life; do not overwrite the other puff.
    ld hl, wJohtoGoldDustDirection
    ld a, [wJohtoGoldDustFrames]
    and a
    jr z, .selected
    ld a, [wJohtoGoldDustSlot2Frames369R]
    and a
    jr z, .second
    ld c, a
    ld a, [wJohtoGoldDustFrames]
    cp c
    jr c, .selected
.second
    ld hl, wJohtoGoldDustSlot2Y369R
.selected
    inc hl
    inc hl ; frame counter
    ld [hl], 64 ; original pre-hide duration, no blocking waits
    inc hl ; source + facing
    ld [hl], b
    ; Take the first anchor from the actual stone; subsequent overworld
    ; frames track it. 60 frames after hiding are guaranteed separately.
    call UpdateJohtoGoldDustAnchor369Q
    ld hl, vChars1 + $7c0 ; OBJ $FC/$FD
    ld de, JohtoGoldStrengthDustGFX369L
    lb bc, BANK(JohtoGoldStrengthDustGFX369L), 2
    call CopyVideoData
    ret

; Track both puffs on each overworld frame, regardless of OAM capacity.
; A puff never rereads player input and stops tracking when its own source
; stone is hidden. On the FIRST hidden frame, extend it for 60 display
; frames (the ~1 second white smoke visible after the pit drop in Gold).
UpdateJohtoGoldDustAnchor369Q::
    ld hl, wJohtoGoldDustDirection
    call .updateOne
    ld hl, wJohtoGoldDustSlot2Y369R
    call .updateOne
    ret
.updateOne
    push hl
    inc hl
    inc hl ; frames
    ld a, [hl]
    and a
    jp z, .done
    inc hl ; packed source
    ld a, [hl]
    bit 2, a
    jp nz, .done ; already hidden: keep last anchor and lifetime
    and $f0
    swap a
    and a
    jp z, .done
    cp 16
    jp nc, .done
    swap a
    add 2 ; stone's C1x2: facing / $ff when hidden
    ld e, a
    ld d, HIGH(wSpriteStateData1)
    ld a, [de]
    cp $ff
    jr z, .hidden
    inc e
    inc e ; C1x4, live stone screen Y
    ld a, [de]
    add 16
    ld b, a
    inc e
    inc e ; C1x6, live stone screen X
    ld a, [de]
    add 8
    push af
    ld a, [hl]
    and $03
    add a
    ld e, a
    ld d, 0
    push hl
    ld hl, .dustOffsets
    add hl, de
    ld a, [hli]
    add b
    ld b, a
    ld a, [hl]
    ld c, a
    pop hl
    pop af
    add c
    ld c, a
    dec hl
    dec hl
    dec hl ; cached Y
    ld [hl], b
    inc hl ; cached X
    ld [hl], c
    jr .done
.hidden
    set 2, [hl] ; arm post-hide period ONCE for this puff only
    dec hl ; remaining lifetime
    ld [hl], 60
.done
    pop hl
    ret
.dustOffsets
    db -4, 0 ; DOWN
    db 8, 0 ; UP
    db 2, 6 ; LEFT
    db 2, -6 ; RIGHT

; Draw up to two independent Gold 2x2 puffs, each at its own cached
; position. Count down even when OAM is full, preventing stale sprites.
; The original last four OAM entries remain reserved for ledges/fishing.
DrawJohtoGoldStrengthDust369L::
    ld a, [wCurMap]
    cp JOHTO_RUNTIME_MAP_HANDLE
    jr z, .johto
    xor a
    ld [wJohtoGoldDustFrames], a
    ld [wJohtoGoldDustSlot2Frames369R], a
    ret
.johto
    call UpdateJohtoGoldDustAnchor369Q
    ld hl, wJohtoGoldDustDirection
    call .drawSlot
    ld hl, wJohtoGoldDustSlot2Y369R
    call .drawSlot
    ret
.drawSlot
    push hl
    inc hl
    inc hl ; lifetime
    ld a, [hl]
    and a
    jp z, .done
    dec [hl] ; lifetime is NOT dependent on OAM capacity
    ld a, [wd736]
    bit 6, a
    jp nz, .done
    ld a, [hOAMBufferOffset]
    cp $84 ; need 16 bytes; last $10 OAM bytes are reserved
    jp nc, .done
    ld a, [hl]
    cpl
    and 4
    srl a
    srl a
    add $fc ; Gold's two OBJ tile phases
    ld h, a
    ld a, $10 | PAL_OW_EMOJI ; Gold PAL_OW_EMOTE = 5
    ld l, a
    ; HL now holds palette/tile, recover this slot's screen anchor.
    pop de ; DE = slot Y address
    push de
    ld a, [de]
    ld b, a ; Y
    inc e
    ld a, [de]
    ld c, a ; X
    ld a, [hOAMBufferOffset]
    ld e, a
    ld d, HIGH(wOAMBuffer)
    call .writeQuadrant
    ld a, c
    add 8
    ld c, a
    call .writeQuadrant
    ld a, c
    sub 8
    ld c, a
    ld a, b
    add 8
    ld b, a
    call .writeQuadrant
    ld a, c
    add 8
    ld c, a
    call .writeQuadrant
    ld a, e
    ld [hOAMBufferOffset], a
.done
    pop hl
    ret

.writeQuadrant
    ld a, b
    ld [de], a ; screen Y
    inc e
    ld a, c
    ld [de], a ; screen X
    inc e
    ld a, h
    ld [de], a ; same tile in all four quadrants
    inc e
    ld a, l
    ld [de], a ; same palette in all four quadrants
    inc e
    ret

; This exact two-frame 8x16 graphic is from the bundled Gold reference.
JohtoGoldStrengthDustGFX369L:
    INCBIN "gfx/overworld/johto_gold_boulder_dust.2bpp"
