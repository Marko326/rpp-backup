"""REF-354: source-level contracts for Spark DE ABI + full EXT animation identity.

No ROM is executed here. Test-mode scenes enable subsequent real damage/animation
verification with TEST Red/Blue, while these checks catch destructive rewrites.
"""
from pathlib import Path
import re

ROOT = Path(__file__).resolve().parents[2]


def read(rel):
    return (ROOT / rel).read_text(encoding="utf-8")


def section(src, start, end):
    assert start in src and end in src
    return src.split(start, 1)[1].split(end, 1)[0]


def assert_dynamic_preserves_de(src):
    routine = section(src, "ResolveDynamicMoveCategory:", "; Exact local equivalent")
    assert "push de" in routine.split(".playerStats", 1)[0]
    assert routine.count("pop de") == 2
    for outcome in (".special", ".physical"):
        assert re.search(rf"^{re.escape(outcome)}\s*$\s*ld a, (?:SPECIAL|PHYSICAL)\s+pop de\s+ret", routine, re.M)
    assert "ld de, wBattleMonSpecial" in routine
    assert "ld de, wEnemyMonSpecial" in routine
    assert "call ResolveDynamicCalcStageAttack" in routine
    assert "jr z, .physical ; tie" in routine
    assert "cp 999" not in routine  # don't accidentally truncate 16-bit cap


def assert_extended_skips_legacy_override(src):
    prepare = section(src, "PrepareCurrentMoveAnimation::", "; Bank-$0F public entry")
    assert prepare.index("cp EXT_MOVE_LOW_PLAY_ROUGH") < prepare.index("ld hl, PlayRoughExtAnim")
    after = prepare.split(".notPlayRough", 1)[1]
    assert re.search(r"ld a, \[wExtendedActiveMoveOrdinal\]\s+and a\s+ret nz\s+call GetCurrentMoveID", after)
    assert after.index("ret nz") < after.index("call LoadDirectMoveAnimationOverride")
    assert after.index("ret nz") < after.index("call LoadLegacyMoveAnimationOverride")
    assert "PlayCurrentMoveAnimationFar::" in src  # legacy animation still runs


def test_spark_damage_abi_and_player_enemy_calls():
    src = read("engine/battle/physical_special_split.asm")
    assert_dynamic_preserves_de(src)
    core = read("engine/battle/core.asm")
    for start, end in (
        ("GetDamageVarsForPlayerAttack:", "GetDamageVarsForEnemyAttack:"),
        ("GetDamageVarsForEnemyAttack:", "CalculateDamage:"),
    ):
        damage = section(core, start, end)
        assert "ld d, a" in damage
        assert "call PhysicalSpecialSplit" in damage
        assert damage.index("ld d, a") < damage.index("call PhysicalSpecialSplit")
    assert "db DYNAMIC ;SPARK" in src
    assert 'db "REF-354@"' in read("data/game_version.asm")


def test_class_table_is_compile_time_guarded():
    split = read("engine/battle/physical_special_split.asm")
    table = section(split, ".MovesTable\n", ".MovesTableEnd")
    assert len(re.findall(r"^\s*db\s+(?:OTHER_M|PHYSICAL|SPECIAL|DYNAMIC)\b", table, re.M)) == 255
    assert "ASSERT .MovesTableEnd - .MovesTable == NUM_ATTACKS" in split
    assert "ASSERT .extendedClassesEnd - .extendedClasses == NUM_EXTENDED_MOVES" in split


def test_all_40_extended_ids_bypass_ordinary_animation_overrides():
    anim = read("data/extended_move_animations.asm")
    assert_extended_skips_legacy_override(anim)
    moves = section(read("data/extended_moves.asm"), "ExtendedMoves::", "ExtendedMovesEnd::")
    names = re.findall(r"^\s*move\s+(\w+)\s*,", moves, re.M)
    assert len(names) == 40
    # Eight ordinal=ordinary-move-ID collisions that used to trigger a
    # wrong dedicated normal-move recipe. They must all use their compatible
    # animation byte instead of GetCurrentMoveID's ordinal.
    expected = {4:"TACKLE", 6:"CUT", 7:"GUST", 8:"PECK", 9:"VICEGRIP",
                13:"WING_ATTACK", 17:"PECK", 27:"WING_ATTACK"}
    for ordinal, compat in expected.items():
        assert names[ordinal - 1] == compat
    assert "cp EXT_MOVE_LOW_PLAY_ROUGH" in anim  # EXT02 dedicated recipe kept


def test_ref354_test_rom_has_spark_and_ext_scenarios_without_official_hook():
    harness = read("engine/battle/test_suite_imposter.asm")
    menu = section(harness, "TestSuiteImposterMenuChoices:", "; TEST-217: complex")
    for i, name in ((22,"P-SPARK-P"), (23,"P-SPARK-S"), (24,"E-SPARK-P"),
                    (25,"E-SPARK-S"), (26,"EXT13-WING"), (27,"EXT04-TACK")):
        assert f"{i} {name}@" in menu
    assert "PAGE 9/9@" in menu
    assert "cp $5b ; valid wild scenes" in harness
    assert "cp $e8" in harness
    for token in ("ld a, SPARK", "ld a, 13", "ld a, 4",
                  "ld [wPartyMon1Attack + 1], a", "ld [wEnemyMonAttack + 1], a",
                  "or $01 ; player slot 0 is an EXT identity"):
        assert token in harness
    assert "IF DEF(BATTLE_TEST_BUILD)" in read("main.asm")
    mk = read("Makefile")
    assert "-D BATTLE_TEST_BUILD" in mk
    assert "pokered_test_obj" in mk
    assert "test-red:" in mk and "test-blue:" in mk


def test_negative_wrong_reg_or_anim_guard_detected():
    split = read("engine/battle/physical_special_split.asm")
    anim = read("data/extended_move_animations.asm")
    for bad in (
        split.replace("\tpush de\n\tldh a, [H_WHOSETURN]", "\tldh a, [H_WHOSETURN]", 1),
        split.replace("\tpop de\n\tret", "\tret", 1),
    ):
        try:
            assert_dynamic_preserves_de(bad)
        except AssertionError:
            pass
        else:
            raise AssertionError("DE ABI fault was not caught")
    bad = anim.replace("\tand a\n\tret nz\n\tcall GetCurrentMoveID", "\tand a\n\tcall GetCurrentMoveID", 1)
    try:
        assert_extended_skips_legacy_override(bad)
    except AssertionError:
        pass
    else:
        raise AssertionError("extended ordinal leak was not caught")



def test_review_fix_all_six_scenarios_reach_snorlax_fixture():
    """The initial candidate showed a menu but skipped its new move fixtures."""
    harness = read("engine/battle/test_suite_imposter.asm")
    lead = harness.split("TestSuiteImposter_StartScenario::", 1)[1].split("\n.addFirst\n", 1)[0]
    assert re.search(r"cp \$55\s+jr c, \.mewLead\s+cp \$5b\s+jr c, \.snorlaxLead", lead)
    assert ".mewLead\n    ld a, MEW" in lead
    assert ".snorlaxLead\n    ld a, SNORLAX" in lead
    snorlax = harness.split("\n.snorlaxMoves\n", 1)[1].split("\n.setSpeed\n", 1)[0]
    for clause in ("cp $55", "cp $56", "cp $59", "cp $5a", "ld a, SPARK", "ld a, 13", "ld a, 4"):
        assert clause in snorlax
    assert "cp $57 ; enemy Spark vs player's Splash only" in snorlax
    assert "cp $58\n    jr z, .soloPlayerSplash" in snorlax


def test_spark_scenes_have_visible_120hp_and_100_defense_controls():
    harness = read("engine/battle/test_suite_imposter.asm")
    party = harness.split("\n.setSpeed\n", 1)[1].split("\n.statsDone\n", 1)[0]
    for token in (
        "cp $55", "cp $56", "cp $57", "cp $58",
        ".playerSparkPhysical", ".playerSparkSpecial", ".enemySparkTarget",
        "ld [wPartyMon1Defense + 1], a", "ld [wPartyMon1Special + 1], a",
        "ld [wPartyMon1MaxHP + 1], a", "ld [wPartyMon1HP + 1], a",
        "ld a, 100", "ld a, 120",
    ):
        assert token in party
    enemy = harness.split("\n.setEnemySpeed\n", 1)[1].split("\n.enemyStatsDone\n", 1)[0]
    for token in (
        "cp $55", "cp $56", "cp $57", "cp $58",
        ".enemySparkPhysical", ".enemySparkSpecial", ".playerSparkTarget",
        "ld [wEnemyMonDefense + 1], a", "ld [wEnemyMonSpecial + 1], a",
        "ld [wEnemyMonHP + 1], a", "ld [wEnemyMonMaxHP + 1], a",
        "ld a, 100", "ld a, 120",
    ):
        assert token in enemy
    assert 'Ext Move 13@' in read('data/extended_moves.asm')
    assert 'Ext Move 04@' in read('data/extended_moves.asm')


def test_review_fix_really_detects_missing_six_scene_routing():
    harness = read("engine/battle/test_suite_imposter.asm")
    lead = harness.split("TestSuiteImposter_StartScenario::", 1)[1].split("\n.addFirst\n", 1)[0]
    bad = lead.replace("    cp $55\n    jr c, .mewLead\n    cp $5b\n    jr c, .snorlaxLead ; six scenes $55..$5a\n", "", 1)
    assert not re.search(r"cp \$55\s+jr c, \.mewLead\s+cp \$5b\s+jr c, \.snorlaxLead", bad)
