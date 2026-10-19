> **后续状态（ILEX-5.62.217）：已按共用执行器定稿并获得用户手机验收。** 用户报告桐树林所有跳崖均已测试无异常；桧皮镇标牌旁另处漏跳由 Gold 几何审计第三格误判修复。下面保留 `.216` 候选当时真实的未验结论与风险分析，仅供追溯；正式验收见 `JOHTO_LEDGE_GOLD_COVERAGE_217.md`。

# ILEX-LEDGE-001 · Forest HOP shared-path trial (.216 source candidate)

**Status: STATIC CANDIDATE / ROM LINK & PHONE NOT VERIFIED.** This does not
supersede the observed .205-.208 phone failures, nor claim they were diagnosed.
The .209 suspension is preserved in `ISSUE_ILEX_FOREST_LEDGE_DEFERRED_209.md`
for historical context.

## Change

- Reopen `.ilexForest` in `engine/overworld/ledges.asm` through the same
  `.checkPairs` and `.foundMatch` path as normal Kanto/Johto ledges, using the
  already-authored `JohtoIlexForestLedgeTiles` table and its 3 directional pairs.
- Remove Forest's special `dec a` simulated-input count; use the unchanged
  shared `ld a,$2` queue setup. **Two queued inputs are not proof of three
  completed tile moves.** Existing normal-jump visual distance must be checked
  against RAM/ROM movement traces; the older 3-vs-2 conclusion was unverified.
- Do not change the Gold 10 HOP approaches, cloned barrier tiles, 216-byte
  blocked mask, shared animator, CUT, map assets or non-Forest route tables.
- Keep the existing B-acceleration guard active for Forest jump animations.
- Update existing suspended-state tests and the Gold source-backed P17 audit;
  negative mutations must catch a disabled dispatch, tile mismatch, or divergent
  simulated-input count.

## Risk and acceptance

The Gold geometry is **two cells** from takeoff to destination. The first
cell is WALL and the second is FLOOR; for **7 of 10** actions the third cell
is a HEADBUTT_TREE. The runtime must land precisely at `(x+2dx,y+2dy)` and
never move into the third cell; static source checks alone cannot guarantee
this. `wd736.6` bypasses ordinary collision while jumping, so a lingering
third simulated move could go into a wall/tree. Do **not** call the candidate
fixed, safe to ship, or accepted from a green Python audit alone.

Recommended phone/CPU trace: check all ten Gold actions (including the two
multi-direction takeoffs), hold/release D-pad, B held, landing into tree,
repeat, immediately turn, reload a save, Kanto legacy/Route29/31, Route33,
Azalea. Record `wXCoord/wYCoord`, `wWalkCounter`, `wd736.6`, `wd730.7`,
`wSimulatedJoypadStatesIndex` at each step boundary; confirm exact landing,
normal collision restoration and no phantom third move.

`SafariZoneBeta` remains an unrelated, user-accepted existing audit warning;
no Safari code or release gate has been disabled or altered by this trial.
