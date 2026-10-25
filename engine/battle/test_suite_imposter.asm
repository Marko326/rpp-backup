; TEST-214: complex paired manual-Transform interaction matrix plus entry-Imposter fixture.
; The 15 slots are disposable test cases, not permanent regression assets.
; Scene IDs $40..$4e; battle guard $a5 / $5a; test ROM only.

TestSuiteImposter_ChooseScene::
    ld a, $e0 ; page 1/5 in transient menu-only phase
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
    ; Each page has three scenarios and a PAGE x/5 selector (Left/Right).
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
    jr z, .input ; do not wrap past PAGE 1/5
    dec a
    ld [wTestSuitePhase], a
    jr .changePage
.rightPage
    ld a, [wCurrentMenuItem]
    cp 3
    jr nz, .input
    ld a, [wTestSuitePhase]
    cp $e4
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
.p1:
    db "PAGE 1/5@"
.p2:
    db "PAGE 2/5@"
.p3:
    db "PAGE 3/5@"
.p4:
    db "PAGE 4/5@"
.p5:
    db "PAGE 5/5@"

; TEST-214: complex interaction matrix, not fifteen independent smoke tests.
; $40..$4e map to menu slots 01..15. All fixture hooks are test-ROM-only.
; $a5 = scenario setup active; $5a = battle fixture armed.
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
    cp $4f ; valid wild scenes resume at $4c after the trainer slot
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

; For E-LATE-EXT, inject the active player's sidecar after battle data load,
; before the enemy Transform copies it. This never touches Party/SRAM.
TestSuiteImposter_OnRoundBoundary::
    ld a, [wTestSuiteGuard]
    cp $5a
    ret nz
    ld a, [wTestSuitePhase]
    cp $45 ; E-LATE-EXT only
    ret nz
    ld a, [wExtendedBattleMoveFlags]
    or $0e ; player EXT01 is in slots 1, 2, 3
    ld [wExtendedBattleMoveFlags], a
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
