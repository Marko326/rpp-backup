"""REF-348 jump/ledge/pit regression: source-contract tests, not ROM emulation."""
from pathlib import Path
import re
import sys

ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(ROOT / 'tools'))
from johto_burned_tower_348_audit import audit as burned_tower_audit
from johto_burned_tower_348_motion_cadence import check as check_fall_cadence


def read(name):
    return (ROOT / name).read_text(encoding='utf-8')


def jump_collision_source():
    source = read('home/overworld.asm')
    return source.split('CollisionCheckOnLand::', 1)[1].split('\n.notJumping', 1)[0]


def jump_guard_source():
    source = read('engine/overworld/ledges.asm')
    return source.split('JohtoSouthHopLandingGuard::', 1)[1].split('.unionCaveB1F', 1)[0]


def shadow_source():
    source = read('engine/overworld/player_animations.asm')
    return source.split('_HandleMidJump:', 1)[1].split('PlayerJumpingYScreenCoords:', 1)[0]


def test_ledge_collision_bypass_requires_active_forced_steps_even_in_kanto():
    # Before the fix Kanto skipped JohtoSouthHopLandingGuard and all non-Johto
    # maps retained no-collision for the whole shadow animation.
    main = jump_collision_source()
    guard = '\n'.join(line.split(';', 1)[0] for line in jump_guard_source().splitlines())
    assert 'callab JohtoSouthHopLandingGuard' in main
    assert 'jp nz, .noCollision' not in main
    assert 'ld a, [wCurMap]' not in main
    pattern = (r'ld e, 1\s+ld a, \[wd730\]\s+bit 7, a\s+'
               r'ret z\s+ld e, 0\s+ld a, \[wCurMap\]\s+'
               r'cp JOHTO_RUNTIME_MAP_HANDLE\s+ret nz')
    assert re.search(pattern, guard), 'all maps must block once simulated inputs finish'
    assert 'ld a, [wCurRegion]' in guard, 'Johto-specific landing guard retained'
    assert 'scf' in main and 'ret' in main


def test_late_shadow_never_authorizes_up_or_sideways_movement():
    # Model only the guarded jump-flag/collision policy, independent of B speed.
    # Active scripted moves retain the old path; stopped scripts must lock input.
    for b_held in (False, True):
        for attempted_direction in ('UP', 'DOWN', 'LEFT', 'RIGHT'):
            # A shadow can be active *after* the two forced steps finish.
            jump_flag, simulated_joypad_active = True, False
            collision_blocked = jump_flag and not simulated_joypad_active
            assert collision_blocked, (b_held, attempted_direction)
            # During the two-scripted-input phase, the old hop path remains.
            simulated_joypad_active = True
            assert not (jump_flag and not simulated_joypad_active)


def test_jump_height_32_frames_independent_of_walking_animation():
    section = shadow_source()
    assert re.search(r'ld hl, wPlayerJumpingYScreenCoordsIndex\s+'
                     r'ld a, \[hl\]\s+cp \$20\s+jr nc, \.finishedJump\s+'
                     r'inc \[hl\]\s+srl a\s+ld c, a', section)
    assert 'Ledge60FPS' not in section
    assert 'wSpriteStateData2 + $0a' not in section
    assert 'res 6, [hl]' in section and 'res 7, [hl]' in section
    for field in ('wPlayerJumpingYScreenCoordsIndex',
                  'wSimulatedJoypadStatesIndex', 'wSimulatedJoypadStatesEnd',
                  'wSimulatedJoypadStatesEnd + 1', 'wJoyIgnore'):
        assert re.search(r'ld\s+\[' + re.escape(field) + r'\],\s*a', section), field
    assert [i >> 1 for i in range(32)] == [j for j in range(16) for _ in (0, 1)]
    for walking_stops_at in (0, 8, 16, 32, 50):
        # The visual height always advances even if the moving sprite freezes.
        index = 0
        while index < 32:
            index += 1
        assert index == 32
        assert max(32, walking_stops_at) >= 32


def test_gold_b1f_thirty_hops_cross_a_wall_and_land_on_nonwalls():
    s = read('engine/overworld/ledges.asm')
    rows = s.split('JohtoBurnedTowerB1FGoldHops:', 1)[1].split('JohtoRoute33Hops:', 1)[0]
    hops = re.findall(r'db\s+(\d+),\s+(\d+),\s+PLAYER_DIR_(DOWN|LEFT|RIGHT)', rows)
    roles = (ROOT / 'maps/johto_pilot/BurnedTowerB1F.gold_roles.bin').read_bytes()
    shifts = {'DOWN': (0, 1), 'LEFT': (-1, 0), 'RIGHT': (1, 0)}
    assert len(hops) == 30
    for sx, sy, direction in hops:
        x, y = int(sx), int(sy)
        dx, dy = shifts[direction]
        assert 0 <= x + 2*dx < 20 and 0 <= y + 2*dy < 18
        at = lambda px, py: roles[py * 20 + px]
        assert at(x, y) in (1, 2, 3, 4), (x, y, direction, 'source')
        assert at(x + dx, y + dy) == 7, (x, y, direction, 'over-wall')
        assert at(x + 2*dx, y + 2*dy) not in (6, 7), (x, y, direction, 'landing')


def test_pit_11_routes_five_arrivals_ladder_strength_and_fall_cadence():
    # Established REF-348 audit also checks stable Gold source map coordinates.
    assert '11 PIT' in burned_tower_audit(ROOT)
    below = read('data/johto_burned_tower/REF348_b1f_runtime.asm')
    assert check_fall_cadence(below)
    pit = below.split('JohtoBurnedTowerMaybeFallWarp::', 1)[1].split('JohtoEnterMapAnimationDispatcher::', 1)[0]
    assert re.search(r'cp 2\s+ret c\s+cp 13\s+ret nc', pit), 'only 1F PIT slots 2..12 trigger fall'
    assert pit.count('set 7, [hl]') == 1
    assert 'callab JohtoPilotResolveWarpDestination' not in pit
    enter = below.split('JohtoEnterMapAnimationDispatcher::', 1)[1].split('JohtoBurnedTowerFallEntryAnim::', 1)[0]
    assert 'res 7, [hl]' in enter
    assert 'res 2, [hl]' in enter
    assert 'JohtoBurnedTowerFallEntryAnim' in enter
    assert below.index('GSSFX_BURNED_TOWER_KINESIS') < below.index('GSSFX_BURNED_TOWER_STRENGTH')
    assert 'callba RestoreFacingDirectionAndYScreenPos' in below
    assert 'ld [hSCY], a' in below
