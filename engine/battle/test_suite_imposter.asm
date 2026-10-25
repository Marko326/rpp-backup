; TEST-217: verify both Disable fields and native one-move Struggle fallbacks.
; The 21 slots are disposable test cases, not permanent regression assets.
; Scene IDs $40..$54; battle guard $a5 / $5a plus staged Disable states; test ROM only.

TestSuiteImposter_ChooseScene::
    ld a, $e0 ; page 1/7 in transient menu-only phase
    ld [wTestSuitePhase], a
    ld a, 3 ; PAGE is the default cursor on entering this submenu
    ld [wCurrentMenuItem], a
.page
    call TestSuite_SetMenuCommon
    ld a, A_BUTTON | B_BUTTON | D_LEFT | D_RIGHT
    ld [wMenuWatchedKeys], a
    ld a, 3
    ld [wMaxMenuItem], a
    call TestSuite_DrawMenuFrame
    coord hl, 2, 3
    ld de, TestSuiteImposterMenuTitle
    call PlaceString
    ; Each page has three scenarios and a PAGE x/7 selector (Left/Right).
    ld a, [wTestSuitePhase]
    sub $e0
    add a
    add a
    add a ; eight bytes per page, 4 x dw
    ld e, a
    ld d, 0
    ld hl, TestSuiteImposterMenuChoices
    add hl, de
    ld a, [hli]
    ld d, [hl]
    ld e, a
    inc hl
    push hl
    coord hl, 3, 4
    call PlaceString
    pop hl
    ld a, [hli]
    ld d, [hl]
    ld e, a
    inc hl
    push hl
    coord hl, 3, 6
    call PlaceString
    pop hl
    ld a, [hli]
    ld d, [hl]
    ld e, a
    inc hl
    push hl
    coord hl, 3, 8
    call PlaceString
    pop hl
    ld a, [hli]
    ld d, [hl]
    ld e, a
    coord hl, 3, 10
    call PlaceString
    call TestSuite_ShowMenu
.input
    call HandleMenuInput
    ld b, a
    bit 1, b
    jr nz, .cancelMenu
    bit 5, b ; Left: only while cursor is on PAGE
    jr nz, .leftPage
    bit 4, b ; Right: only while cursor is on PAGE
    jr nz, .rightPage
    bit 0, b
    jr z, .input
    ld a, [wCurrentMenuItem]
    cp 3
    jr z, .input ; just as in Options, A does not flip PAGE
    ld c, a
    jr .restore
.leftPage
    ld a, [wCurrentMenuItem]
    cp 3
    jr nz, .input
    ld a, [wTestSuitePhase]
    cp $e0
    jr z, .input ; do not wrap past PAGE 1/7
    dec a
    ld [wTestSuitePhase], a
    jr .changePage
.rightPage
    ld a, [wCurrentMenuItem]
    cp 3
    jr nz, .input
    ld a, [wTestSuitePhase]
    cp $e6
    jr z, .input
    inc a
    ld [wTestSuitePhase], a
.changePage
    ld a, 3
    ld [wCurrentMenuItem], a
    jp .page
.cancelMenu
    scf ; B returns to SELECT TEST, without touching the battle party
    ret
.restore
    ld a, c
    ld b, a ; 0..2 scenario slot
    ld a, [wTestSuitePhase]
    sub $e0
    ld c, a
    add a
    add c ; page * 3
    add b
    add $40
    ld [wTestSuitePhase], a
    and a ; selected scene
    ret

TestSuiteImposterMenuTitle:
    db "TRANSFORM TEST@"
TestSuiteImposterMenuChoices:
    dw .s01, .s02, .s03, .p1
    dw .s04, .s05, .s06, .p2
    dw .s07, .s08, .s09, .p3
    dw .s10, .s11, .s12, .p4
    dw .s13, .s14, .s15, .p5
    dw .s16, .s17, .s18, .p6
    dw .s19, .s20, .s21, .p7
.s01:
    db "01 P-LATE-FLY@"
.s02:
    db "02 E-LATE-FLY@"
.s03:
    db "03 P-LATE-DIG@"
.s04:
    db "04 E-LATE-DIG@"
.s05:
    db "05 P-LATE-EXT@"
.s06:
    db "06 E-LATE-EXT@"
.s07:
    db "07 P-LATE-KO@"
.s08:
    db "08 E-LATE-KO@"
.s09:
    db "09 P-LATE-SUB@"
.s10:
    db "10 E-LATE-SUB@"
.s11:
    db "11 PP/RESTORE@"
.s12:
    db "12 AUTO-BIDIR@"
.s13:
    db "13 BOTH-FAIL@"
.s14:
    db "14 P-CHARGE@"
.s15:
    db "15 E-CHARGE@"
.s16:
    db "16 P-DIS-CLEAR@"
.s17:
    db "17 E-DIS-CLEAR@"
.s18:
    db "18 P-DIS-FAIL@"
.s19:
    db "19 P-ONE-DIS@"
.s20:
    db "20 E-ONE-DIS@"
.s21:
    db "21 REAL-DIS@"
.p1:
    db "PAGE 1/7@"
.p2:
    db "PAGE 2/7@"
.p3:
    db "PAGE 3/7@"
.p4:
    db "PAGE 4/7@"
.p5:
    db "PAGE 5/7@"
.p6:
    db "PAGE 6/7@"
.p7:
    db "PAGE 7/7@"

; TEST-217: complex interaction matrix plus native Disable/Struggle edge tests.
; $40..$54 map to menu slots 01..21. All fixture hooks are test-ROM-only.
; $a5 = setup active; $5a = armed; $5c/$5d = Disable pre-state checks.
TestSuiteImposter_StartScenario::
    ld a, [wTestSuitePhase]
    push af
    ld hl, wPartyCount
    xor a
    ld [hli], a
    dec a
    ld [hl], a
    ld a, 50
    ld [wCurEnemyLVL], a
    ld a, $10 ; party data, no nickname prompt
    ld [wMonDataLocation], a
    ld a, [wTestSuitePhase]
    cp $41 ; E-LATE-FLY: player uses Fly before enemy Transform
    jr z, .snorlaxLead
    cp $43 ; E-LATE-DIG
    jr z, .snorlaxLead
    cp $45 ; E-LATE-EXT
    jr z, .snorlaxLead
    cp $47 ; E-LATE-KO
    jr z, .snorlaxLead
    cp $49 ; E-LATE-SUB
    jr z, .snorlaxLead
    cp $4b ; AUTO-BIDIR: real player switch to reserve Ditto
    jr z, .snorlaxLead
    cp $4e ; E-CHARGE baseline
    jr z, .snorlaxLead
    cp $52 ; one available player move is disabled
    jr z, .snorlaxLead
    cp $53 ; one enemy move is disabled
    jr z, .snorlaxLead
    cp $54 ; real Disable cast by player AFTER enemy Transform
    jr z, .snorlaxLead
    ld a, MEW
    jr .addFirst
.snorlaxLead
    ld a, SNORLAX
.addFirst
    ld [wcf91], a
    call AddPartyMon
    ld a, [wcf91]
    ld [wd11e], a
    call GetMonName
    ld hl, wcd6d
    ld de, wPartyMonNicks
    ld bc, NAME_LENGTH
    call CopyData

    ; Build explicit disposable test-party data; battle mechanics remain native.
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
    ld a, [wPartyMon1Species]
    cp MEW
    jr nz, .snorlaxMoves
    ld a, [wTestSuitePhase]
    cp $4f ; P-DIS-CLEAR: Transform slot 1, old disabled Tackle slot 2
    jr z, .playerDisableClearMoves
    cp $50 ; E-DIS-CLEAR: target's copied moves are Splash / Tackle
    jr z, .enemyDisableClearTargetMoves
    cp $51 ; P-DIS-FAIL: failed Transform must preserve old Disable
    jr z, .playerDisableClearMoves
    ld a, TRANSFORM
    ld [wPartyMon1Moves], a
    ld a, 10
    ld [wPartyMon1PP], a
    ld a, SPLASH
    ld [wPartyMon1Moves + 1], a
    ld a, 40
    ld [wPartyMon1PP + 1], a
    ld a, TACKLE
    ld [wPartyMon1Moves + 2], a
    ld a, 35
    ld [wPartyMon1PP + 2], a
    jp .setSpeed
.playerDisableClearMoves
    ld a, TRANSFORM
    ld [wPartyMon1Moves], a
    ld a, 10
    ld [wPartyMon1PP], a
    ld a, TACKLE
    ld [wPartyMon1Moves + 1], a
    ld a, 35
    ld [wPartyMon1PP + 1], a
    jp .setSpeed
.enemyDisableClearTargetMoves
    ld a, SPLASH
    ld [wPartyMon1Moves], a
    ld a, 40
    ld [wPartyMon1PP], a
    ld a, TACKLE
    ld [wPartyMon1Moves + 1], a
    ld a, 35
    ld [wPartyMon1PP + 1], a
    jp .setSpeed
.snorlaxMoves
    ld a, SPLASH
    ld [wPartyMon1Moves], a
    ld a, 40
    ld [wPartyMon1PP], a
    ld a, TACKLE
    ld [wPartyMon1Moves + 1], a
    ld a, 35
    ld [wPartyMon1PP + 1], a
    ld a, [wTestSuitePhase]
    cp $52 ; only Tackle; the round-boundary hook disables this one slot
    jr z, .soloPlayerTackle
    cp $53 ; only Splash, so the opponent's Struggle is visible
    jr z, .soloPlayerSplash
    cp $54 ; real Disable AFTER enemy Transform; target copies both moves
    jr z, .realDisablePlayerMoves
    jr .regularSnorlaxMovesDone
.soloPlayerTackle
    ld a, TACKLE
    ld [wPartyMon1Moves], a
    ld a, 35
    ld [wPartyMon1PP], a
    xor a
    ld [wPartyMon1Moves + 1], a
    ld [wPartyMon1PP + 1], a
    jp .setSpeed
.soloPlayerSplash
    xor a
    ld [wPartyMon1Moves + 1], a
    ld [wPartyMon1PP + 1], a
    jp .setSpeed
.realDisablePlayerMoves
    ld a, DISABLE
    ld [wPartyMon1Moves], a
    ld a, 20
    ld [wPartyMon1PP], a
    jp .setSpeed
.regularSnorlaxMovesDone
    ld a, [wTestSuitePhase]
    cp $41 ; player must start Fly; enemy Transform follows it
    jr nz, .notPlayerFly
    ld a, FLY
    ld [wPartyMon1Moves + 1], a
    ld a, 15
    ld [wPartyMon1PP + 1], a
.notPlayerFly
    ld a, [wTestSuitePhase]
    cp $43 ; player must start Dig; enemy Transform follows it
    jr nz, .notPlayerDig
    ld a, DIG
    ld [wPartyMon1Moves + 1], a
    ld a, 10
    ld [wPartyMon1PP + 1], a
.notPlayerDig
    ld a, [wTestSuitePhase]
    cp $45 ; E-LATE-EXT: player uses Splash; copied slot 1 is EXT01
    jr nz, .notPlayerExt
    ld a, 1 ; EXT ordinal 1 = Power Whip
    ld [wPartyMon1Moves + 1], a
    ld [wPartyMon1Moves + 2], a
    ld [wPartyMon1Moves + 3], a
    xor a ; only Splash is available to the player before Transform
    ld [wPartyMon1PP + 1], a
    ld [wPartyMon1PP + 2], a
    ld [wPartyMon1PP + 3], a
.notPlayerExt
    ld a, [wTestSuitePhase]
    cp $47 ; E-LATE-KO: Swift copied from slot 1, but not selected by player
    jr nz, .notPlayerKO
    ld a, SWIFT
    ld [wPartyMon1Moves + 1], a
    xor a
    ld [wPartyMon1PP + 1], a
    ld [wPartyMon1HP], a
    inc a
    ld [wPartyMon1HP + 1], a
.notPlayerKO
    ld a, [wTestSuitePhase]
    cp $49 ; E-LATE-SUB: player creates Substitute, enemy copies Tackle
    jr nz, .notPlayerSub
    ld a, SUBSTITUTE
    ld [wPartyMon1Moves], a
    ld a, 10
    ld [wPartyMon1PP], a
    ld a, TACKLE
    ld [wPartyMon1Moves + 1], a
    xor a
    ld [wPartyMon1PP + 1], a
.notPlayerSub
    ld a, [wTestSuitePhase]
    cp $4e ; E-CHARGE: copy Fly even though target PP is 0
    jr nz, .setSpeed
    ld a, FLY
    ld [wPartyMon1Moves + 1], a
    xor a
    ld [wPartyMon1PP + 1], a
.setSpeed
    ; Set active stats before LoadBattleMonFromParty reads them.
    xor a
    ld [wPartyMon1Speed], a
    ld a, [wTestSuitePhase]
    cp $40 ; player acts after the enemy starts Fly
    jr z, .slowPlayer
    cp $42 ; player acts after the enemy starts Dig
    jr z, .slowPlayer
    cp $44 ; player acts after the enemy's ordinary move before EXT copy
    jr z, .slowPlayer
    cp $46 ; player acts after the enemy Splash before KO follow-up
    jr z, .slowPlayer
    cp $48 ; player acts after the enemy Substitute
    jr z, .slowPlayer
    cp $4e ; E-CHARGE: enemy Transform acts before slow player Splash
    jr z, .slowPlayer
    cp $50 ; E-DIS-CLEAR: enemy Transform acts before player Splash
    jr z, .slowPlayer
    cp $54 ; real Disable: enemy Transform acts before player Disable
    jr z, .slowPlayer
    ld a, 250
    jr .storeSpeed
.slowPlayer
    ld a, 1
.storeSpeed
    ld [wPartyMon1Speed + 1], a
    ld a, [wTestSuitePhase]
    cp $4a ; PP/RESTORE: switch Mew out and back
    jr z, .addSnorlaxReserve
    cp $4b ; AUTO-BIDIR: player switches to Ditto in round one
    jr z, .addDittoReserve
    jr .finishParty
.addSnorlaxReserve
    ld a, SNORLAX
    jr .addReserve
.addDittoReserve
    ld a, DITTO
.addReserve
    ld [wcf91], a
    ld a, $10
    ld [wMonDataLocation], a
    call AddPartyMon
    ld a, [wcf91]
    ld [wd11e], a
    call GetMonName
    ld hl, wcd6d
    ld de, wPartyMonNicks + NAME_LENGTH
    ld bc, NAME_LENGTH
    call CopyData
.finishParty
    pop af
    ld [wTestSuitePhase], a
    cp $4b ; only AUTO-BIDIR uses the real trainer party/switch path
    jr z, .trainer
    xor a
    ld [wIsTrainerBattle], a
    ld a, [wTestSuitePhase]
    cp $40
    jr z, .wildPidgeot
    cp $41
    jr z, .wildMew
    cp $43
    jr z, .wildMew
    cp $45
    jr z, .wildMew
    cp $47
    jr z, .wildMew
    cp $49
    jr z, .wildMew
    cp $4c ; BOTH-FAIL
    jr z, .wildMew
    cp $4e ; E-CHARGE
    jr z, .wildMew
    cp $51 ; P-DIS-FAIL: same-species target keeps Transform failing
    jr z, .wildMew
    cp $54 ; enemy Mew has only Transform before copying the player
    jr z, .wildMew
    ld a, SNORLAX
    jr .arm
.wildMew
    ld a, MEW
    jr .arm
.wildPidgeot
    ld a, PIDGEOT
.arm
    ld [wCurOpponent], a
    jr .ready
.trainer
    ld a, 1
    ld [wIsTrainerBattle], a
    ld [wTrainerNo], a
    ld a, 200 + YOUNGSTER
    ld [wCurOpponent], a
.ready
    ld a, 50
    ld [wCurEnemyLVL], a
    ld a, $a5
    ld [wTestSuiteGuard], a
    ret

; Wild enemy data is loaded before this hook. It changes only test fixtures.
TestSuiteImposter_WildEnemyReady::
    ld a, [wTestSuiteGuard]
    cp $a5
    ret nz
    ld a, [wCurMap]
    cp CELADON_MANSION_1
    jp nz, TestSuite_Disarm
    ld a, [wIsInBattle]
    cp 1
    jp nz, TestSuite_Disarm
    ld a, [wTestSuitePhase]
    cp $40
    jp c, TestSuite_Disarm
    cp $4b ; $4b is the trainer fixture, not a wild battle
    jp z, TestSuite_Disarm
    cp $55 ; valid wild scenes are $40..$54 except trainer fixture $4b
    jp nc, TestSuite_Disarm
    ld hl, wEnemyMonMoves
    ld b, NUM_MOVES
    xor a
.clearMoves
    ld [hli], a
    dec b
    jr nz, .clearMoves
    ld hl, wEnemyMonPP
    ld b, NUM_MOVES
    xor a
.clearPP
    ld [hli], a
    dec b
    jr nz, .clearPP
    ld a, [wTestSuitePhase]
    cp $4f ; P-DIS-CLEAR: target provides Splash / Tackle to copy
    jp z, .disableTarget
    cp $50 ; E-DIS-CLEAR: enemy Transform is slot 1, Tackle is slot 2
    jp z, .disableEnemyTransform
    cp $51 ; P-DIS-FAIL: same-species Mew target, Transform always fails
    jp z, .disableTarget
    cp $52 ; single disabled player Tackle; wild opponent only Splash
    jp z, .soloEnemySplash
    cp $53 ; single disabled enemy Tackle; player only Splash
    jp z, .soloEnemyTackle
    cp $54 ; native enemy Transform, then player casts real Disable
    jp z, .enemyTransform
    cp $41 ; E-LATE-FLY
    jp z, .enemyTransform
    cp $43 ; E-LATE-DIG
    jp z, .enemyTransform
    cp $45 ; E-LATE-EXT
    jp z, .enemyTransform
    cp $47 ; E-LATE-KO
    jp z, .enemyTransform
    cp $49 ; E-LATE-SUB
    jp z, .enemyTransform
    cp $4c ; BOTH-FAIL
    jp z, .enemyTransform
    cp $4e ; E-CHARGE baseline
    jp z, .enemyTransform
    cp $40
    jp z, .fly
    cp $42
    jp z, .dig
    cp $44
    jp z, .extended
    cp $46
    jp z, .finishKO
    cp $48
    jp z, .substitute
    cp $4d
    jp z, .charge
    ; PP/RESTORE: a four-slot target for copying and later party restoration.
    ld a, TACKLE
    ld [wEnemyMonMoves], a
    ld a, 35
    ld [wEnemyMonPP], a
    ld a, SPLASH
    ld [wEnemyMonMoves + 1], a
    ld a, 40
    ld [wEnemyMonPP + 1], a
    ld a, DOUBLE_KICK
    ld [wEnemyMonMoves + 2], a
    ld a, 30
    ld [wEnemyMonPP + 2], a
    ld a, SWIFT
    ld [wEnemyMonMoves + 3], a
    ld a, 20
    ld [wEnemyMonPP + 3], a
    jp .setEnemySpeed
.enemyTransform
    ld a, TRANSFORM
    ld b, 10
    jp .oneMove
.disableTarget
    ld a, SPLASH
    ld [wEnemyMonMoves], a
    ld a, 40
    ld [wEnemyMonPP], a
    ld a, TACKLE
    ld [wEnemyMonMoves + 1], a
    ld a, 35
    ld [wEnemyMonPP + 1], a
    jp .setEnemySpeed
.soloEnemySplash
    ld a, SPLASH
    ld b, 40
    jp .oneMove
.soloEnemyTackle
    ld a, TACKLE
    ld b, 35
    jp .oneMove
.disableEnemyTransform
    ld a, TRANSFORM
    ld [wEnemyMonMoves], a
    ld a, 10
    ld [wEnemyMonPP], a
    ld a, TACKLE
    ld [wEnemyMonMoves + 1], a
    ld a, 35
    ld [wEnemyMonPP + 1], a
    jp .setEnemySpeed
.fly
    ld a, FLY
    ld b, 15
    jp .oneMove
.dig
    ld a, DIG
    ld b, 10
    jp .oneMove
.charge
    ; P-CHARGE: enemy can only act with Splash; Fly remains copyable in slot 1.
    ld a, SPLASH
    ld [wEnemyMonMoves], a
    ld a, 40
    ld [wEnemyMonPP], a
    ld a, FLY
    ld [wEnemyMonMoves + 1], a
    jp .setEnemySpeed
.finishKO
    ; Swift is copied with fresh 5 PP but unavailable to the target AI itself.
    xor a
    ld [wEnemyMonHP], a
    inc a
    ld [wEnemyMonHP + 1], a
    ld a, SPLASH
    ld [wEnemyMonMoves], a
    ld a, 40
    ld [wEnemyMonPP], a
    ld a, SWIFT
    ld [wEnemyMonMoves + 1], a
    xor a
    ld [wEnemyMonPP + 1], a
    jp .setEnemySpeed
.substitute
    ; Substitute must be the only move the enemy can select; Tackle is copied
    ; with fresh PP so the player can use it after a late Transform.
    ld a, SUBSTITUTE
    ld [wEnemyMonMoves], a
    ld a, 10
    ld [wEnemyMonPP], a
    ld a, TACKLE
    ld [wEnemyMonMoves + 1], a
    xor a
    ld [wEnemyMonPP + 1], a
    jp .setEnemySpeed
.extended
    ; EXT01 = Power Whip in slot 1. Its PP is 0 on the target so it cannot
    ; interfere with the first action, but Transform copies it with 5 PP.
    ld a, [wExtendedBattleMoveFlags]
    and $0f
    or $20
    ld [wExtendedBattleMoveFlags], a
    ld a, SPLASH
    ld [wEnemyMonMoves], a
    ld a, 40
    ld [wEnemyMonPP], a
    ld a, 1
    ld [wEnemyMonMoves + 1], a
    jp .setEnemySpeed
.oneMove
    ld [wEnemyMonMoves], a
    ld a, b
    ld [wEnemyMonPP], a
.setEnemySpeed
    xor a
    ld [wEnemyMonSpeed], a
    ld [wEnemyMonUnmodifiedSpeed], a
    ld a, [wTestSuitePhase]
    cp $40 ; P-LATE-FLY: target must act before player's Transform
    jr z, .fastEnemy
    cp $42 ; P-LATE-DIG
    jr z, .fastEnemy
    cp $44 ; P-LATE-EXT
    jr z, .fastEnemy
    cp $46 ; P-LATE-KO
    jr z, .fastEnemy
    cp $48 ; P-LATE-SUB
    jr z, .fastEnemy
    cp $4e ; E-CHARGE: enemy Transform acts before player
    jr z, .fastEnemy
    cp $50 ; E-DIS-CLEAR: enemy Transform acts before player Splash
    jr z, .fastEnemy
    cp $54 ; native real-Disable scene: enemy first Transforms
    jr z, .fastEnemy
    ld a, 1
    jr .storeSpeed
.fastEnemy
    ld a, 250
.storeSpeed
    ld [wEnemyMonSpeed + 1], a
    ld [wEnemyMonUnmodifiedSpeed + 1], a
    ld a, $5a
    ld [wTestSuiteGuard], a
    ret

; Keep the native trainer loader call size unchanged in its saturated bank.
TestSuiteImposter_ReadTrainerWrapper::
    callab ReadTrainer
    jp TestSuiteImposter_TrainerPartyReady

TestSuiteImposter_TrainerPartyReady::
    ld a, [wTestSuiteGuard]
    cp $a5
    ret nz
    ld a, [wCurMap]
    cp CELADON_MANSION_1
    ret nz
    ld a, [wTestSuitePhase]
    cp $4b ; AUTO-BIDIR only
    ret nz
    ; Real two-member trainer party: Pidgeot lead, Ditto reserve.
    ld hl, wEnemyPartyCount
    xor a
    ld [hli], a
    dec a
    ld [hl], a
    ld a, 50
    ld [wCurEnemyLVL], a
    ld a, ENEMY_PARTY_DATA
    ld [wMonDataLocation], a
    ld a, PIDGEOT
    ld [wcf91], a
    call AddPartyMon
    ld a, SPLASH
    ld [wEnemyMon1Moves], a
    ld a, 40
    ld [wEnemyMon1PP], a
    xor a
    ld [wEnemyMon1Moves + 1], a
    ld [wEnemyMon1Moves + 2], a
    ld [wEnemyMon1Moves + 3], a
    ld [wEnemyMon1PP + 1], a
    ld [wEnemyMon1PP + 2], a
    ld [wEnemyMon1PP + 3], a
    ld a, DITTO
    ld [wcf91], a
    ld a, ENEMY_PARTY_DATA
    ld [wMonDataLocation], a
    call AddPartyMon
    ld a, $5a
    ld [wTestSuiteGuard], a
    ret

; Round-boundary fixtures never touch Party/SRAM. Disable is injected directly
; with a deterministic slot/timer so these cases test Transform state handling,
; not Disable's random slot selection or accuracy.
TestSuiteImposter_OnRoundBoundary::
    ld a, [wTestSuiteGuard]
    cp $5a
    jr z, .initialFixture
    cp $5c
    jp z, .playerPostTransform
    cp $5d
    jp z, .enemyPostTransform
    ret
.initialFixture
    ld a, [wTestSuitePhase]
    cp $4f ; P-DIS-CLEAR: old player slot 2 is disabled before Transform
    jr z, .seedPlayerOldDisable
    cp $50 ; E-DIS-CLEAR: old enemy slot 2 is disabled before Transform
    jr z, .seedEnemyOldDisable
    cp $51 ; P-DIS-FAIL: failed Transform must not clear old Disable
    jr z, .seedPlayerFailureDisable
    cp $52 ; player has one Tackle, disabled: normal Struggle fallback
    jp z, .seedPlayerSingleDisabled
    cp $53 ; enemy has one Tackle, disabled: native enemy Struggle
    jp z, .seedEnemySingleDisabled
    cp $45 ; E-LATE-EXT only
    ret nz
    ld a, [wExtendedBattleMoveFlags]
    or $0e ; player EXT01 is in slots 1, 2, 3
    ld [wExtendedBattleMoveFlags], a
    ret
.seedPlayerOldDisable
    ld a, $25 ; slot 2, 5 turns
    ld [wPlayerDisabledMove], a
    ld a, TACKLE
    ld [wPlayerDisabledMoveNumber], a
    ld a, $5c ; armed for the post-Transform check
    ld [wTestSuiteGuard], a
    ret
.seedEnemyOldDisable
    ld a, $25 ; slot 2, 5 turns
    ld [wEnemyDisabledMove], a
    ld a, TACKLE
    ld [wEnemyDisabledMoveNumber], a
    ld a, $5d ; keep enemy follow-up fixture armed
    ld [wTestSuiteGuard], a
    ret
.seedPlayerFailureDisable
    ld a, $25 ; slot 2, 5 turns
    ld [wPlayerDisabledMove], a
    ld a, TACKLE
    ld [wPlayerDisabledMoveNumber], a
    ld a, $5b ; one-shot fixture; failure must leave this state alone
    ld [wTestSuiteGuard], a
    ret
.playerPostTransform
    ld a, [wPlayerBattleStatus3]
    bit Transformed, a
    ret z ; keep waiting if the player has not successfully transformed yet
    ld a, [wPlayerDisabledMove]
    and a
    jr nz, .playerOldDisableRemained
    ld a, [wPlayerDisabledMoveNumber]
    and a
    jr nz, .playerOldDisableRemained
    ; Both fields must be zero; checking only the timer hid a stale move ID.
    ; Correct clear: simulate a NEW Disable on slot 1 after Transform. Tackle
    ; (slot 2) should remain usable. If old Disable survived, leave slot 2 set.
    ld a, $15 ; slot 1, 5 turns
    ld [wPlayerDisabledMove], a
    ld a, SPLASH
    ld [wPlayerDisabledMoveNumber], a
    jr .playerDisableCheckDone
.playerOldDisableRemained
    ; Fail visibly if EITHER old field survived: force the old slot 2
    ; restriction so the player's Tackle is visibly marked Disabled.
    ; This is test-only instrumentation, never an official battle effect.
    ld a, $25
    ld [wPlayerDisabledMove], a
    ld a, TACKLE
    ld [wPlayerDisabledMoveNumber], a
    jr .playerDisableCheckDone
.playerDisableCheckDone
    ld a, $5b ; fixture complete
    ld [wTestSuiteGuard], a
    ret
.enemyPostTransform
    ld a, [wEnemyBattleStatus3]
    bit Transformed, a
    ret z ; keep waiting if the enemy has not successfully transformed yet
    ld a, [wEnemyDisabledMove]
    and a
    jr nz, .enemyOldDisableRemained
    ld a, [wEnemyDisabledMoveNumber]
    and a
    jr nz, .enemyOldDisableRemained
    ; Both fields must be zero; checking only the timer hid a stale move ID.
    ; Correct clear: simulate a NEW Disable on copied slot 1 after Transform.
    ; The enemy must now avoid Splash and choose Tackle in slot 2. If old Disable
    ; survived, leave slot 2 disabled and the enemy will instead choose Splash.
    ld a, $15 ; slot 1, 5 turns
    ld [wEnemyDisabledMove], a
    ld a, SPLASH
    ld [wEnemyDisabledMoveNumber], a
    jr .enemyDisableCheckDone
.enemyOldDisableRemained
    ; A partial clear must not be mistaken for a success by overwriting
    ; its stale ID. Force old slot 2 Disabled to make the failure visible.
    ld a, $25
    ld [wEnemyDisabledMove], a
    ld a, TACKLE
    ld [wEnemyDisabledMoveNumber], a
.enemyDisableCheckDone
    ld a, $5b ; fixture complete
    ld [wTestSuiteGuard], a
    ret

; 19/20: single normally packed move, explicitly disabled at round start.
; This exercises the STOCK player/enemy Struggle fallback; no fake input.
.seedPlayerSingleDisabled
    ld a, $15 ; first and only move, 5 turns
    ld [wPlayerDisabledMove], a
    ld a, TACKLE
    ld [wPlayerDisabledMoveNumber], a
    ld a, $5b
    ld [wTestSuiteGuard], a
    ret
.seedEnemySingleDisabled
    ld a, $15
    ld [wEnemyDisabledMove], a
    ld a, TACKLE
    ld [wEnemyDisabledMoveNumber], a
    ld a, $5b
    ld [wTestSuiteGuard], a
    ret

; AUTO-BIDIR forces the enemy's real switch only in its TrainerAI action slot.
TestSuiteImposter_TrainerAIWrapper::
    ld a, [wTestSuiteGuard]
    cp $5a
    jr nz, .native
    ld a, [wIsInBattle]
    cp 2
    jr nz, .native
    ld a, [wTestSuitePhase]
    cp $4b
    jr nz, .native
    ld a, $9e ; consume the fixture once, before the native switch
    ld [wTestSuitePhase], a
    callab SwitchEnemyMon
    scf ; enemy action is consumed, no follow-up attack
    ret
.native
    jpab TrainerAI
