#!/usr/bin/env python3
"""Source-level fail-closed check for the ledge input-state teardown.

FIX-274: animation completion and JoypadOverworld may finish on different
frames. Neither the old simulated-input counter alone nor the animation flag
alone is a safe authorization to bypass normal collision. This audit does not
execute a ROM or claim the video freeze is reproduced at an instruction.
"""
from __future__ import annotations

import re
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]


def audit(root=ROOT):
    root = Path(root)
    problems = []
    try:
        home = (root / 'home/overworld.asm').read_text()
        animations = (root / 'engine/overworld/player_animations.asm').read_text()
        ledges = (root / 'engine/overworld/ledges.asm').read_text()
        segment = home.split('CollisionCheckOnLand::', 1)[1].split('.checkedJohtoEdge', 1)[0]
        normal = segment.split('\n.notJumping\n', 1)[1].split('ld a,[wCurMap]', 1)[0]
        # LD A,(a16) [3B] + RLCA [1B] + JP C,a16 [3B] = 7B, exactly
        # the old index-only LD/AND/JP NZ budget in fixed ROM0.
        instructions = [line.split(';', 1)[0].strip().lower() for line in normal.splitlines()
                        if line.strip() and not line.lstrip().startswith(';')]
        if instructions != ['ld a,[wd730]', 'rlca', 'jp c,.nocollision']:
            problems.append('ROM0 land collision must require active wd730.7, not a stale simulated index; 7B budget')
        finish = animations.split('_HandleMidJump:', 1)[1].split('; Adjust the ledge animation index', 1)[0]
        finish_code = '\n'.join(line.split(';', 1)[0] for line in finish.splitlines())
        # A jump can finish visually only after the walk counter completes;
        # all active simulation state must be cleared together at that point.
        if not re.search(r'\.finishedJump\s+ld a,\s*\[wWalkCounter\]\s+cp 0\s+ret nz', finish_code):
            problems.append('mid-jump finalizer must wait for both walking steps')
        if not re.search(r'ld hl,\s*wd736\s+res 6,\s*\[hl\]\s+'
                         r'ld hl,\s*wd730\s+res 7,\s*\[hl\]', finish_code):
            problems.append('mid-jump finalizer must release jump and scripted-input flags')
        after_flags = finish.split('res 7, [hl]', 1)[-1]
        required = ('wSimulatedJoypadStatesIndex', 'wSimulatedJoypadStatesEnd',
                    'wSimulatedJoypadStatesEnd + 1', 'wJoyIgnore')
        for name in required:
            if not re.search(r'ld\s*\[\s*' + re.escape(name) + r'\s*\],\s*a', after_flags):
                problems.append('finalizer did not clear '+name)
        if 'xor a' not in after_flags:
            problems.append('finalizer must zero A before clearing scripted-input state')
        if not re.search(r'ld a,\s*\$2\s+ld\s*\[wSimulatedJoypadStatesIndex\],\s*a', ledges):
            problems.append('approved two-step jump queue unexpectedly changed')
        if 'JohtoSouthHopLandingGuard::' not in ledges or 'callab JohtoSouthHopLandingGuard' not in segment:
            problems.append('approved south landing guard disconnected')
    except (OSError, IndexError) as exc:
        problems.append(str(exc))
    return problems


if __name__ == '__main__':
    p = audit()
    if p:
        print('FAIL: ' + '\n- '.join(p))
        raise SystemExit(1)
    print('PASS: 7-byte ROM0 active-script gate, complete two-step finalizer, south landing guard')
