; RUN-001: REFERENCE TEST-ROM SUITE -- never merge into the official ROM.
; Selectable groups, each isolated to this one NPC-launched wild battle:
; TEST 01: Substitute + player Spike Cannon / enemy Spike Cannon (3 rounds).
; TEST 02: player Double Kick / enemy Twineedle (2 rounds).
; TEST 03: player Jump Kick / enemy Hi Jump Kick forced misses (2 rounds).
; Guard: A5=NPC armed, 5A=only the scripted wild battle active. Zero=off.
; Phase: 1..3=selected group before battle; 11/21/31=waiting for two dolls;
; 12/22/32=group active; 13=enemy Spike turn; 14/23/33=group finished.
; The guard and phase occupy two former UNUSED Gym puzzle bytes; no WRAM
; addresses moved, no SRAM changes. Official ROM retains the original bytes.

TestSuite_Disarm::
    xor a
    ld [wTestSuiteGuard], a
    ld [wTestSuitePhase], a
    ret

; RUN-006: native menu with balanced A/B exit stack. Follow the native
; CeladonGameCornerPurchaseMenu / VendingMachineMenu / LinkCableHelp pattern:
; save the map tilemap, set cursor geometry before drawing, draw a box wholly
; above the message box, and let HandleMenuInput manage A/B/up/down.
; Unlike the old RUN-001 selector, do not open a second PrintText box, do not
; manually toggle BG transfer during a live menu, and do not rewrite menu input
; globals in a custom polling loop. Restore both cursor spacing and map tiles.
; Return carry set on B/cancel; no party changes until A confirms a group.
; RUN-007 lifecycle: the NPC first replaces its warning with control hints.
; Buffer1 therefore snapshots the CONTROL HINTS, not the stale warning.
; This helper restores the background only; the TX_ASM caller must finish with
; DisableWaitingAfterTextDisplay so the outer DisplayTextID hides the textbox.
TestSuite_ChooseGroup:
    call SaveScreenTilesToBuffer1
    ld a, [hFlags_0xFFF6]
    push af
    res 1, a ; native two-row menu spacing (choices at Y=4,6,8)
    ld [hFlags_0xFFF6], a
    ld a, [wd730]
    push af
    set 6, a ; no per-character delay while drawing menu labels
    ld [wd730], a

    xor a
    ld [wCurrentMenuItem], a
    ld [wLastMenuItem], a
    ld [wMenuWatchMovingOutOfBounds], a
    ld [wMenuWrappingEnabled], a
    ld [wMenuJoypadPollCount], a ; same native initialization as MainMenu
    ld a, 1
    ld [wTopMenuItemX], a
    ld a, 4
    ld [wTopMenuItemY], a
    ld a, 2 ; zero-based index: three choices
    ld [wMaxMenuItem], a
    ld a, A_BUTTON | B_BUTTON
    ld [wMenuWatchedKeys], a

    ; TextBoxBorder's c,b are INNER dimensions: x0 + 17 + 2 = 19 tiles;
    ; y2 + 8 + 2 = 12 tiles. Entire box is inside screen, above textbox Y12.
    coord hl, 0, 2
    ld b, 8
    ld c, 17
    call TextBoxBorder
    coord hl, 2, 3
    ld de, TestSuiteMenuTitle
    call PlaceString
    coord hl, 3, 4
    ld de, TestSuiteOption1Text
    call PlaceString
    coord hl, 3, 6
    ld de, TestSuiteOption2Text
    call PlaceString
    coord hl, 3, 8
    ld de, TestSuiteOption3Text
    call PlaceString

    pop af
    ld [wd730], a
    call UpdateSprites
    ld a, 1
    ld [H_AUTOBGTRANSFERENABLED], a
    call Delay3
.menuInput
    call HandleMenuInput ; same native cursor/input routine as Game Corner
    bit 1, a
    jr nz, .cancel
    bit 0, a
    jr z, .menuInput
    ld a, [wCurrentMenuItem]
    inc a ; group IDs 1,2,3
    ld [wTestSuitePhase], a
    jr .finish ; do NOT call a routine which pops a caller-owned AF
.cancel
    ; TestSuite_Disarm cleared the phase before opening this menu.
    ; Keep phase 0 and restore through the same straight-line exit.
.finish
    ; Balanced with the one saved hFlags AF above. The old "call .restore"
    ; pushed a return address which this POP treated as AF, corrupting SP;
    ; both A and B consequently returned into invalid code and froze.
    pop af
    ld [hFlags_0xFFF6], a
    call LoadScreenTilesFromBuffer1
    ld a, [wTestSuitePhase]
    and a ; nonzero group clears carry for successful selection
    ret nz
    scf ; phase 0 = B cancel; no party was edited
    ret

TestSuiteMenuTitle:
    db "SELECT TEST@"
TestSuiteOption1Text:
    db "TEST 01 SPIKE@"
TestSuiteOption2Text:
    db "TEST 02 2-HIT@"
TestSuiteOption3Text:
    db "TEST 03 RECOIL@"

TestSuite_StartFromNpc::
    ; Do not modify the disposable test party until a group is selected.
    call TestSuite_Disarm
    call TestSuite_ChooseGroup
    ret c
    ; Preserve the selected group across party-building helpers, which may use
    ; unrelated scratch bytes. Restore the ID immediately before configuring moves.
    ld a, [wTestSuitePhase]
    push af

    ld hl, wPartyCount
    xor a
    ld [hli], a
    dec a
    ld [hl], a
    ld a, SNORLAX
    ld [wcf91], a
    ld a, 50
    ld [wCurEnemyLVL], a
    ld a, $10
    ld [wMonDataLocation], a
    call AddPartyMon
    ld a, SNORLAX
    ld [wd11e], a
    call GetMonName
    ld hl, wcd6d
    ld de, wPartyMonNicks
    ld bc, NAME_LENGTH
    call CopyData
    ; Fixed battle-ready values in the disposable TEST SAVE only.
    xor a
    ld [wPartyMon1HP], a
    ld [wPartyMon1MaxHP], a
    ld [wPartyMon1Attack], a
    ld [wPartyMon1Defense], a
    ld [wPartyMon1Special], a
    ld [wPartyMon1Speed], a
    ld [wPartyMon1Status], a
    ld [wExtendedPartyMoveFlags], a
    ld a, 240
    ld [wPartyMon1HP + 1], a
    ld [wPartyMon1MaxHP + 1], a
    ld a, 85
    ld [wPartyMon1Attack + 1], a
    ld a, 145
    ld [wPartyMon1Defense + 1], a
    ld a, 120
    ld [wPartyMon1Special + 1], a
    ld a, 150 ; player acts before opponent
    ld [wPartyMon1Speed + 1], a

    ld hl, wPartyMon1Moves
    ld b, NUM_MOVES
    xor a
.clearMoves
    ld [hli], a
    dec b
    jr nz, .clearMoves
    ld hl, wPartyMon1PP
    ld b, NUM_MOVES
    xor a
.clearPP
    ld [hli], a
    dec b
    jr nz, .clearPP
    pop af
    ld [wTestSuitePhase], a
    ld a, SUBSTITUTE
    ld [wPartyMon1Moves], a
    ld a, [wTestSuitePhase]
    cp 1
    jr z, .spikeMove
    cp 2
    jr z, .doubleKickMove
    ld a, JUMP_KICK
    jr .storeSecondMove
.spikeMove
    ld a, SPIKE_CANNON
    jr .storeSecondMove
.doubleKickMove
    ld a, DOUBLE_KICK
.storeSecondMove
    ld [wPartyMon1Moves + 1], a
    ld a, SPLASH
    ld [wPartyMon1Moves + 2], a
    ld a, 10
    ld [wPartyMon1PP], a
    ld a, [wTestSuitePhase]
    cp 1
    jr z, .spikePP
    cp 2
    jr z, .doubleKickPP
    ld a, 10 ; Jump Kick
    jr .storeSecondPP
.spikePP
    ld a, 15 ; Spike Cannon
    jr .storeSecondPP
.doubleKickPP
    ld a, 30 ; Double Kick
.storeSecondPP
    ld [wPartyMon1PP + 1], a
    ld a, 40
    ld [wPartyMon1PP + 2], a
    ; Set battle trigger LAST. This NPC does not touch the wild encounter map.
    ld a, SNORLAX
    ld [wCurOpponent], a
    ld a, 50
    ld [wCurEnemyLVL], a
    xor a
    ld [wIsTrainerBattle], a
    ld a, $a5
    ld [wTestSuiteGuard], a
    ret

TestSuite_IsActive:
    ld a, [wTestSuiteGuard]
    cp $5a
    ret nz
    ld a, [wCurMap]
    cp CELADON_MANSION_1
    ret nz
    ld a, [wIsInBattle]
    cp 1
    ret

TestSuite_EnemyReady::
    ; This hook runs AFTER LoadEnemyMonData and only on the NPC's wild battle.
    ld a, [wTestSuiteGuard]
    cp $a5
    ret nz
    ld a, [wCurMap]
    cp CELADON_MANSION_1
    jp nz, TestSuite_Disarm
    ld a, [wIsInBattle]
    cp 1
    jp nz, TestSuite_Disarm
    ld a, [wCurOpponent]
    cp SNORLAX
    jp nz, TestSuite_Disarm
    ld a, [wTestSuitePhase]
    cp 1
    jr z, .group1
    cp 2
    jr z, .group2
    cp 3
    jp nz, TestSuite_Disarm
    ld a, $31
    jr .phaseReady
.group1
    ld a, $11
    jr .phaseReady
.group2
    ld a, $21
.phaseReady
    ld [wTestSuitePhase], a
    ld a, $5a
    ld [wTestSuiteGuard], a
    ld a, 50
    ld [wEnemyMonLevel], a
    xor a
    ld [wEnemyMonHP], a
    ld [wEnemyMonMaxHP], a
    ld [wEnemyMonAttack], a
    ld [wEnemyMonUnmodifiedAttack], a
    ld [wEnemyMonDefense], a
    ld [wEnemyMonUnmodifiedDefense], a
    ld [wEnemyMonSpeed], a
    ld [wEnemyMonUnmodifiedSpeed], a
    ld a, 240
    ld [wEnemyMonHP + 1], a
    ld [wEnemyMonMaxHP + 1], a
    ld a, 85
    ld [wEnemyMonAttack + 1], a
    ld [wEnemyMonUnmodifiedAttack + 1], a
    ld a, 145
    ld [wEnemyMonDefense + 1], a
    ld [wEnemyMonUnmodifiedDefense + 1], a
    ld a, 75
    ld [wEnemyMonSpeed + 1], a
    ld [wEnemyMonUnmodifiedSpeed + 1], a
    ld hl, wEnemyMonMoves
    ld b, NUM_MOVES
    xor a
.clearEnemyMoves
    ld [hli], a
    dec b
    jr nz, .clearEnemyMoves
    ld a, SUBSTITUTE
    ld [wEnemyMonMoves], a
    ld a, 10
    ld [wEnemyMonPP], a
    ret

TestSuite_AfterSubstituteCreated::
    call TestSuite_IsActive
    ret nz
    ld a, [wTestSuitePhase]
    cp $11
    jr z, .spike
    cp $21
    jr z, .doubleKick
    cp $31
    ret nz
.jumpKick
    ld a, 200
    ld [wPlayerSubstituteHP], a
    ld [wEnemySubstituteHP], a
    ld a, HI_JUMP_KICK
    ld [wEnemyMonMoves], a
    ld a, 20
    ld [wEnemyMonPP], a
    ld a, $32
    ld [wTestSuitePhase], a
    ret
.doubleKick
    ld a, 200
    ld [wPlayerSubstituteHP], a
    ld [wEnemySubstituteHP], a
    ld a, TWINEEDLE
    ld [wEnemyMonMoves], a
    ld a, 20
    ld [wEnemyMonPP], a
    ld a, $22
    ld [wTestSuitePhase], a
    ret
.spike
    ld a, 200
    ld [wPlayerSubstituteHP], a
    ld [wEnemySubstituteHP], a
    ld a, SPLASH
    ld [wEnemyMonMoves], a
    ld a, 40
    ld [wEnemyMonPP], a
    ld a, $12
    ld [wTestSuitePhase], a
    ret

TestSuite_OnRoundBoundary::
    call TestSuite_IsActive
    ret nz
    ld a, [wTestSuitePhase]
    cp $12
    jp z, .playerSpikeDoneCheck
    cp $13
    jp z, .enemySpikeDoneCheck
    cp $22
    jr z, .doubleKickDone
    cp $32
    jr z, .jumpKickDone
    ret
.doubleKickDone
    ; This is a complete round boundary, after both Double Kick/Twineedle actions.
    ; Leave Splash selected so a failed RUN attempt cannot repeat the test hit.
    ld a, SPLASH
    ld [wEnemyMonMoves], a
    ld a, 40
    ld [wEnemyMonPP], a
    ld a, $23
    ld [wTestSuitePhase], a
    ret
.jumpKickDone
    ; Both Jump Kick actions have resolved; no more accuracy overrides.
    ld a, SPLASH
    ld [wEnemyMonMoves], a
    ld a, 40
    ld [wEnemyMonPP], a
    ld a, $33
    ld [wTestSuitePhase], a
    ret
.playerSpikeDoneCheck
    ; Called at the next complete round, never once per individual hit.
    ld a, [wEnemyBattleStatus2]
    bit HasSubstituteUp, a
    ret nz
    ld a, [wPlayerBattleStatus2]
    bit HasSubstituteUp, a
    ret z
    ld a, SPIKE_CANNON
    ld [wEnemyMonMoves], a
    ld a, 15
    ld [wEnemyMonPP], a
    ld a, $13
    ld [wTestSuitePhase], a
    ret
.enemySpikeDoneCheck
    ld a, [wPlayerBattleStatus2]
    bit HasSubstituteUp, a
    ret nz
    ld a, $14
    ld [wTestSuitePhase], a
    ld a, SPLASH
    ld [wEnemyMonMoves], a
    ld a, 40
    ld [wEnemyMonPP], a
    ret

TestSuite_FixSpikeHitCount::
    ; E in/out -- A cannot be used as a far-call return value.
    call TestSuite_IsActive
    ret nz
    ld a, [wTestSuitePhase]
    cp $12
    jr z, .player
    cp $13
    ret nz
    ld a, [H_WHOSETURN]
    cp 1
    ret nz
    jr .force3
.player
    ld a, [H_WHOSETURN]
    and a
    ret nz
.force3
    ld e, 3
    ret

TestSuite_BeforeSubstituteHit::
    ; Set target doll to 1 at the selected second hit; formal AttackSubstitute
    ; still decides the damage, text order, break and remaining hit handling.
    call TestSuite_IsActive
    ret nz
    ld a, [wTestSuitePhase]
    cp $22
    jr z, .doubleKick
    cp $12
    jr z, .playerSpike
    cp $13
    jr z, .enemySpike
    ret
.doubleKick
    ld a, [H_WHOSETURN]
    and a
    ret nz ; only player's Double Kick breaks the enemy doll in TEST 02
    ld a, [wPlayerSelectedMove]
    cp DOUBLE_KICK
    ret nz
    ld a, [wPlayerBattleStatus1]
    bit AttackingMultipleTimes, a
    ret z
    ld a, [wPlayerNumAttacksLeft]
    cp 2
    ret nz
    ld a, 1
    ld [wEnemySubstituteHP], a
    ret
.playerSpike
    ld a, [H_WHOSETURN]
    and a
    ret nz
    ld a, [wPlayerSelectedMove]
    cp SPIKE_CANNON
    ret nz
    ld a, [wPlayerBattleStatus1]
    bit AttackingMultipleTimes, a
    ret z
    ld a, [wPlayerNumAttacksLeft]
    cp 2
    ret nz
    ld a, 1
    ld [wEnemySubstituteHP], a
    ret
.enemySpike
    ld a, [H_WHOSETURN]
    cp 1
    ret nz
    ld a, [wEnemySelectedMove]
    cp SPIKE_CANNON
    ret nz
    ld a, [wEnemyBattleStatus1]
    bit AttackingMultipleTimes, a
    ret z
    ld a, [wEnemyNumAttacksLeft]
    cp 2
    ret nz
    ld a, 1
    ld [wPlayerSubstituteHP], a
    ret

TestSuite_ResolveAccuracy::
    ; Return carry=1 if handled; E=0 means forced hit, E=1 means forced miss.
    call TestSuite_IsActive
    jp nz, .normal
    ld a, [wTestSuitePhase]
    cp $12
    jp z, .playerSpike
    cp $13
    jp z, .enemySpike
    cp $22
    jp z, .twoHit
    cp $32
    jp z, .jumpKick
    jp .normal
.playerSpike
    ld a, [H_WHOSETURN]
    and a
    jp nz, .normal
    ld a, [wPlayerSelectedMove]
    cp SPIKE_CANNON
    jp nz, .normal
    jp .forceHit
.enemySpike
    ld a, [H_WHOSETURN]
    cp 1
    jp nz, .normal
    ld a, [wEnemySelectedMove]
    cp SPIKE_CANNON
    jp nz, .normal
    jp .forceHit
.twoHit
    ld a, [H_WHOSETURN]
    and a
    jr nz, .enemyTwoHit
    ld a, [wPlayerSelectedMove]
    cp DOUBLE_KICK
    jp nz, .normal
    jp .forceHit
.enemyTwoHit
    ld a, [wEnemySelectedMove]
    cp TWINEEDLE
    jp nz, .normal
    jp .forceHit
.jumpKick
    ld a, [H_WHOSETURN]
    and a
    jr nz, .enemyJumpKick
    ld a, [wPlayerSelectedMove]
    cp JUMP_KICK
    jp nz, .normal
    jp .forceMiss
.enemyJumpKick
    ld a, [wEnemySelectedMove]
    cp HI_JUMP_KICK
    jp nz, .normal
    jp .forceMiss
.forceHit
    ld e, 0
    scf
    ret
.forceMiss
    ld e, 1
    scf
    ret
.normal
    and a
    ret
