; IMP-T14: battle-test-build-only Imposter encounter fixtures.
; The test-only suite changes only menu navigation/fixtures; the shared
; Imposter animation is implemented in TransformEffect_, not here.
; Scenario codes $40..$4e are one-shot NPC selections. $a5 arms the next
; NPC-launched encounter; $5a means that encounter has been initialized.
; This module is never included in the ordinary red/blue ROM.

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
    db "IMPOSTER TEST@"
TestSuiteImposterMenuChoices:
    dw .s01, .s02, .s03, .p1
    dw .s04, .s05, .s06, .p2
    dw .s07, .s08, .s09, .p3
    dw .s10, .s11, .s12, .p4
    dw .s13, .s14, .s15, .p5
.s01:
    db "01 P-LEAD@"
.s02:
    db "02 E-LEAD@"
.s03:
    db "03 SW/RE-ENTER@"
.s04:
    db "04 P-FAINT@"
.s05:
    db "05 E-SWITCH@"
.s06:
    db "06 FLY/RETRY@"
.s07:
    db "07 DIG@"
.s08:
    db "08 DITTO/DITTO@"
.s09:
    db "09 E-FAINT@"
.s10:
    db "10 DOUBLE KO@"
.s11:
    db "11 SUBSTITUTE@"
.s12:
    db "12 DUAL/NO-RE@"
.s13:
    db "13 ALOLA FORM@"
.s14:
    db "14 EXT MOVE@"
.s15:
    db "15 NATIVE AI@"
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

; The first party member is used for the initial send-out, so switch and
; replacement cases add Ditto second. All edits are on disposable TEST saves.
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
    ld a, $10 ; player's party, suppress nickname dialog
    ld [wMonDataLocation], a
    ld a, [wTestSuitePhase]
    cp $49
    jr z, .explosionLead
    cp $40
    jr z, .dittoLead
    cp $47
    jr z, .dittoLead
    cp $4c
    jr z, .dittoLead
    cp $4d
    jr z, .dittoLead
    ld a, SNORLAX
    jr .addFirst
.explosionLead
    ld a, ELECTRODE
    jr .addFirst
.dittoLead
    ld a, DITTO
.addFirst
    ld [wcf91], a
    call AddPartyMon
    ; Test-only AddPartyMon suppresses the naming prompt, so explicitly
    ; replace the old save's nickname (as in the three legacy test groups).
    ld a, [wcf91]
    ld [wd11e], a
    call GetMonName
    ld hl, wcd6d
    ld de, wPartyMonNicks
    ld bc, NAME_LENGTH
    call CopyData
    ; Prepare Splash/Tackle for Snorlax scenarios and Explosion for double KO.
    ld a, [wTestSuitePhase]
    cp $49
    jr nz, .notExplosion
    ld a, SELFDESTRUCT
    ld [wPartyMon1Moves], a
    ld a, 5
    ld [wPartyMon1PP], a
    jr .selectReserve
.notExplosion
    ld a, [wPartyMon1Species]
    cp SNORLAX
    jr nz, .selectReserve
    ld a, SPLASH
    ld [wPartyMon1Moves], a
    ld a, 40
    ld [wPartyMon1PP], a
    ld a, TACKLE
    ld [wPartyMon1Moves + 1], a
    ld a, 35
    ld [wPartyMon1PP + 1], a
.selectReserve
    ld a, [wTestSuitePhase]
    cp $42 ; SWITCH + RE-ENTER
    jr z, .addDittoReserve
    cp $43 ; P-FAINT
    jr z, .addDittoReserve
    cp $45 ; FLY
    jr z, .addDittoReserve
    cp $46 ; DIG
    jr z, .addDittoReserve
    cp $4b ; DUAL-SWITCH needs Ditto in reserve
    jr z, .addDittoReserve
    cp $49 ; DOUBLE KO
    jr z, .addDittoReserve
    cp $4a ; SUBSTITUTE
    jr z, .addDittoReserve
    jr .finishParty
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
    cp $43 ; player's active Snorlax starts at 1 HP
    jr nz, .selectEnemy
    xor a
    ld [wPartyMon1HP], a
    inc a
    ld [wPartyMon1HP + 1], a
.selectEnemy
    ld a, [wTestSuitePhase]
    cp $44 ; scripted AI-action switch, not a free boundary action
    jp z, .trainer
    cp $48 ; enemy Ditto replaces a fainted trainer lead
    jp z, .trainer
    cp $49 ; real double-KO trainer replacement
    jp z, .trainer
    cp $4b ; both sides switch in the same turn
    jp z, .trainer
    cp $4c ; regional trainer target
    jp z, .trainer
    cp $4e ; native randomized trainer AI switch
    jp z, .trainer
    xor a
    ld [wIsTrainerBattle], a
    ld a, SNORLAX
    ld b, a
    ld a, [wTestSuitePhase]
    cp $41
    jr z, .dittoEnemy
    cp $47
    jr z, .dittoEnemy
    cp $45
    jr z, .flyEnemy
    cp $46
    jr z, .digEnemy
    ld a, b
    jr .arm
.dittoEnemy
    ld a, DITTO
    jr .arm
.flyEnemy
    ld a, PIDGEOT
    jr .arm
.digEnemy
    ld a, DUGTRIO
.arm
    ld [wCurOpponent], a
    jr .ready
.trainer
    ld a, 1
    ld [wIsTrainerBattle], a
    ld [wTrainerNo], a ; party replaced by our test loader
    ld a, [wTestSuitePhase]
    cp $4e
    jr z, .nativeAITrainer
    ld a, 200 + YOUNGSTER
    jr .setTrainer
.nativeAITrainer
    ; Juggler has the stock SwitchOutAI in both normal and hard modes.
    ld a, 200 + JUGGLER
.setTrainer
    ld [wCurOpponent], a
.ready
    ld a, 50
    ld [wCurEnemyLVL], a
    ld a, $a5
    ld [wTestSuiteGuard], a
    ret

; The wild loader calls here AFTER the enemy's normal header/data are ready.
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
    cp $4f
    jp nc, TestSuite_Disarm
    ; One move, deterministic intent; the engine still resolves its
    ; actual charge, accuracy, damage and Substitute effects.
    ld a, SPLASH
    ld b, 40
    ld a, [wTestSuitePhase]
    cp $43
    jr z, .tackle
    cp $45
    jr z, .fly
    cp $46
    jr z, .dig
    cp $4a
    jr z, .substitute
    cp $4d
    jr z, .extended
    ld a, SPLASH
    jr .store
.tackle
    ld a, TACKLE
    ld b, 35
    jr .store
.fly
    ld a, FLY
    ld b, 15
    jr .store
.dig
    ld a, DIG
    ld b, 10
    jr .store
.substitute
    ld a, SUBSTITUTE
    ld b, 10
    jr .store
.extended
    ; Ordinal 1 corresponds to EXT_MOVE_POWER_WHIP, NOT legacy POUND.
    ; Sidecar high nibble belongs to the live enemy. CopyTransformBattleMoveMask
    ; must copy this to the player when Ditto leads.
    ld a, [wExtendedBattleMoveFlags]
    and $0f
    or $10
    ld [wExtendedBattleMoveFlags], a
    ld a, 1
    ld b, 5
.store
    ld [wEnemyMonMoves], a
    ld a, b
    ld [wEnemyMonPP], a
    xor a
    ld [wEnemyMonMoves + 1], a
    ld [wEnemyMonMoves + 2], a
    ld [wEnemyMonMoves + 3], a
    ld [wEnemyMonPP + 1], a
    ld [wEnemyMonPP + 2], a
    ld [wEnemyMonPP + 3], a
    ld a, $5a
    ld [wTestSuiteGuard], a
    ret

; Test build swaps the existing ReadTrainer banked call for this wrapper;
; there is no byte cost in the saturated battle core or trainer AI bank.
TestSuiteImposter_ReadTrainerWrapper::
    callab ReadTrainer
    jp TestSuiteImposter_TrainerPartyReady

; Called AFTER the ordinary trainer party load.
; Build actual enemy-party entries, so enemy switches and faint replacements
; run through the native EnemySendOut paths (not synthetic battle-slot swaps).
TestSuiteImposter_TrainerPartyReady::
    ld a, [wTestSuiteGuard]
    cp $a5
    ret nz
    ld a, [wCurMap]
    cp CELADON_MANSION_1
    ret nz
    ld a, [wTestSuitePhase]
    cp $44
    jr z, .build
    cp $48
    jr z, .build
    cp $49
    jr z, .build
    cp $4b
    jr z, .build
    cp $4c
    jr z, .build
    cp $4e
    ret nz
.build
    ld hl, wEnemyPartyCount
    xor a
    ld [hli], a
    dec a
    ld [hl], a
    ld a, 50
    ld [wCurEnemyLVL], a
    ld a, ENEMY_PARTY_DATA
    ld [wMonDataLocation], a
    ld a, [wTestSuitePhase]
    cp $4c
    jr nz, .firstSnorlax
    ld a, RATTATA
    ld [wcf91], a
    ld e, FORM_ALOLA
    callba RegionalFormAddPartyMonWithForm
    jp .ready
.firstSnorlax
    ld a, SNORLAX
    ld [wcf91], a
    call AddPartyMon
    ld a, [wTestSuitePhase]
    cp $44 ; 05: switch the intact lead to Ditto
    jr z, .keepHealthy
    cp $4b ; 12: player and enemy switch in the same turn
    jr z, .keepHealthy
    cp $4e ; 15: real AI decides whether to withdraw
    jr z, .keepHealthy
    ; 09 E-FAINT and 10 DOUBLE KO need a real 1-HP enemy lead.
    xor a
    ld [wEnemyMon1HP], a
    inc a
    ld [wEnemyMon1HP + 1], a
.keepHealthy
    ; Only Splash on the lead: its attack must not disturb the switch test.
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
    ld a, [wTestSuitePhase]
    cp $44 ; scripted switch into Ditto
    jr z, .addDitto
    cp $48 ; faint replacement is Ditto
    jr z, .addDitto
    cp $4e ; native Juggler AI switches into Ditto
    jr z, .addDitto
    ld a, PIDGEOT
    jr .addSecond
.addDitto
    ld a, DITTO
.addSecond
    ld [wcf91], a
    ld a, ENEMY_PARTY_DATA
    ld [wMonDataLocation], a
    call AddPartyMon
.ready
    ld a, $5a
    ld [wTestSuiteGuard], a
    ret

; The script must NOT call SwitchEnemyMon at a round boundary. It may
; mark a scenario as ready there; the actual switch must occupy the native
; TrainerAI action slot so that the engine skips ExecuteEnemyMove this turn.
TestSuiteImposter_AtRoundBoundary::
    ld a, [wTestSuiteGuard]
    cp $5a
    ret nz
    ld a, [wTestSuitePhase]
    cp $45 ; 06: Fly + failed entry + later manual Transform
    jr z, .flyRound1
    cp $95
    jr z, .flyRound2
    cp $96
    jr z, .flyRound3
    ld a, [wIsInBattle]
    cp 2
    ret nz
    ld a, [wTestSuitePhase]
    cp $44 ; first round: no forced switch
    jr z, .switchRound1
    cp $74 ; second round: AI action must perform the switch
    ret nz
    ld a, $84
    ld [wTestSuitePhase], a
    ret
.switchRound1
    ld a, $74
    ld [wTestSuitePhase], a
    ret
.flyRound1
    ld a, $95
    ld [wTestSuitePhase], a
    ret
.flyRound2
    ld a, $96
    ld [wTestSuitePhase], a
    ret
.flyRound3
    ; After Fly resolves on round 2, make its next move Splash.
    ; This keeps the actual midair failure, but gives manual Transform
    ; a grounded target on the following turn without relying on speed RNG.
    ld a, SPLASH
    ld [wEnemyMonMoves], a
    ld a, 40
    ld [wEnemyMonPP], a
    ld a, $97 ; consumed; never reset the move on later rounds
    ld [wTestSuitePhase], a
    ret

; Called ONLY at the two existing TrainerAI actions in MainInBattleLoop.
; No third trainer action is added: a scripted switch returns Carry just like
; native SwitchEnemyMon, so the caller skips the enemy's ordinary attack.
TestSuiteImposter_TrainerAIWrapper::
    ld a, [wTestSuiteGuard]
    cp $5a
    jr nz, .native
    ld a, [wIsInBattle]
    cp 2
    jr nz, .native
    ld a, [wTestSuitePhase]
    cp $84 ; 05: round 2, scripted enemy Ditto switch
    jr z, .force
    cp $4b ; 12: same-turn switch, only after the player's Ditto entered
    jr nz, .native
    ld a, [wBattleMonSpecies2]
    cp DITTO
    jr nz, .native
    ld a, $8b ; DUAL-SWITCH consumed
    jr .doSwitch
.force
    ld a, $85 ; E-SWITCH consumed
.doSwitch
    ld [wTestSuitePhase], a ; one-shot BEFORE animations
    callab SwitchEnemyMon
    scf ; explicitly consume the enemy action
    ret
.native
    jpab TrainerAI ; preserves normal AI's Carry result
