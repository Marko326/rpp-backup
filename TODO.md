# Todo List

This file is the working roadmap for the current RPP branch.
Implementation details, ABI/bank constraints, test history, and handoff notes belong in the current handoff document; this file tracks what is finished, what is next, and what remains from the original upstream wishlist.
Reusable development failures and prevention rules are kept in `RPP_DEVELOPMENT_PITFALLS.md`; read it before changing related engine paths.

Status legend:

- `[x]` implemented / already present; **runtime test is confirmed only when the entry explicitly says so**
- `[~]` imported but still awaiting runtime validation, or partially present / pending audit
- `[ ]` not imported / not implemented / planned
- `[?]` undecided, or the task needs a more precise definition

## 分类任务看板（从 HUR-5.62.32 开始逐补丁维护）

> 用途：以后新窗口先看这里，就能按**类型 + 状态 + 顺序**判断哪些已移植、哪些还没改。下面的 `Current RPP Roadmap` 和 `Legacy Upstream Wishlist` 保留原来的详细背景；旧条目的 `[x]` 仅表示原文所述功能已存在，不自动代表本次用户实机测试过。
>
> **固定流程：一次只处理一条补丁 → 静态审查 → 用户运行测试 → 单独交付该补丁的验收 TODO 和提交日志 → 用户确认并提交 → 再单独交付下一项功能。** **不得把上一项验收与下一项功能补丁打包交付。** 分类用于查找，合并仍按①～⑩执行，不能按分类随意调整依赖顺序。
>
> 当前情况：**①～⑨已根据用户反馈完成本轮验收；⑨ `SUB-5.62.42` 替身／多段攻击及反伤时序已由用户运行测试，暂未反馈明显异常，未提供每一项边界场景的逐项结果；⑩ Volt Tackle 专属动画仍未移植。⑦ `BSE-5.62.38` 缩小 +2 回避保持不变，Stomp / Body Slam 对缩小的反制是后续独立专项，不在下一项⑩内实现。⑧ `RCL-5.62.41` 已补记验收，双方闪焰冲锋烧伤曾触发，但伏特攻击麻痹、反伤比例及少见边界未获完整逐项实测记录；Bank `$34` → `$3E` 的 Red Bedroom PC 区段迁移仍保留。⑤特殊伤害数值与升级学习表未实测（源码已核对）。⑨正式日志已准备，实际 Git 提交由用户自行完成。**

### 动画类（Animation）

- [x] **① `HUR-5.62.32` / `32b5022c` — Hurricane（暴风）**：独立风柱、持续风线、Thunder 音效、双向演出和受击反馈已移植；**用户反馈已运行测试，暂未发现明显问题**（2026-10-08）。尚无逐项测试清单，不把各测试场景写成分别通过；以后若复现异常再重开。
- [x] **② `SP-5.62.33` / `2c3b12a8` — Sucker Punch 专属动画与 Dark 命中配色**：仅动画、音效与配色的独立移植；**用户反馈已运行测试，暂未发现明显问题**（2026-10-08），未提供逐场景测试清单，不推定各项均独立通过。② 提交日志已准备；是否完成 Git 提交，以用户自己的仓库为准。现代失败判定仍属于③。
- [x] **⑥ `SW-5.62.37` / `75ac4ff2` — Steel Wing（金属翼）金银版动画**：已单独移植并完成本轮用户验收（2026-10-08）。复用 Iron Tail 的 Gold/Crystal Metallic 开场，跳过铁尾 Wobble/HIT_BIG 后半段，恢复场景后接 Wing Attack 的三组 closing pairs；使用钢系配色。增加敌方出招后的竖震反馈及 BG0 顶行预清理；保留原铁尾、翅膀攻击及招式数据。**用户反馈三组建议场景均已测试、暂未发现异常**：我方金属翼演出，敌方金属翼受击竖震与顶部残影，连续使用金属翼／铁尾／翅膀攻击后的画面恢复；未提供额外的逐帧或全部边界条件验证，不扩大实测结论。⑥提交日志已准备，正式 Git 提交由用户完成。
- [ ] **⑩ `c0cf8a93` — Volt Tackle 五道电流及受击反馈**：未移植；最后处理共享动画/音效入口，低血量音效遗留问题需另行核查。

### 战斗功能 / 结算类（Battle logic）

- [x] **③ `SP-5.62.34` / `5ca3afb3` — Sucker Punch 现代失败判定**：先手且目标选择伤害招式时方能成功；变化招式、后手、Recharge、换人及道具行为有专门失败检查；失败显示 `But it failed!`，我方进入判定前扣 PP。包含 Trainer AI 单次提前判定、Mirror Move 实际招式 ID、MoveDex 和 `$CCE0` WRAM 状态。**用户反馈已实机测试，暂未发现明显问题（2026-10-08）**；进一步代码逻辑复审未发现明确阻断问题。未提供各边界场景逐项结果；Trainer 道具/换人的全局排序仍为旧架构限制。③提交日志已准备，实际提交由用户完成。④已移植并获用户测试反馈。
- [x] **④ `PRI-5.62.35` / `ddddb20e` — 多级技能优先度及 ExtremeSpeed 区分**：源码已单独移植；**用户反馈已运行测试，暂未发现明显问题（2026-10-08），后续源码逻辑复审未发现明确阻断问题**。优先度以 `+7` 偏移编码：ExtremeSpeed `+2`、Sucker Punch/Baby-Doll Eyes/Ice Shard/Bullet Punch/Quick Attack `+1`、普通 `0`、Counter `-5`；同优先度仍按 Speed / 同速随机决定顺序。Roar、Whirlwind、Teleport、Bide 暂保持 `0`，不提前升级效果机制。未提供逐项边界测试记录，不将联机、AI 道具/换人等特殊场景标记为全部通过；旧架构中训练家道具/换人决策时序仍待以后复查。**未调整③失败判定或已验收动画，④验收提交日志已单独准备；是否 Git 提交以用户仓库为准。**
- [x] **⑦ `BSE-5.62.38` / `ff4fec55` — 伤害型能力副作用、Gen I Special 平衡**：已单独移植；**用户反馈已运行测试，其他效果暂未发现明显异常（2026-10-08），但未逐项提交所有概率、双侧、替身／击倒、能力极限等边界测试结果**。共享 Move ID 概率表统一伤害附加能力变化（10% / 20% / 30% / 命中后必定）；Metal Claw / Meteor Mash / Steel Wing / Silver Wind / AncientPower / Mind Blast 的自身能力提升及 Draco Meteor 的自身 Special 下降在目标被击倒前处理。Gen I 共用 Special 平衡及 MoveDex 说明保持本次移植内容；吐丝降速度2级、瞬间失忆提升 Special 1级、**缩小每次提升回避2级（10 PP）**。经讨论确认维持缩小 +2，不应用此前尚未验收的 `BSE-5.62.39`（+1）试验修正。⑦验收只更新 TODO，不再改游戏代码；实际提交由用户完成。
- [x] **⑧ `RCL-5.62.41` / `7ecf21ce` — 反伤比例及 Flare Blitz / Volt Tackle 状态效果**：已独立移植并按用户反馈完成本轮验收（2026-10-08），**目前所测场景未发现明显异常**。按真实 Move ID 分配反伤：Struggle 1/2，Flare Blitz／Volt Tackle／Wood Hammer 1/3，原有其他 RECOIL_EFFECT 招式保持 1/4；火推约10%烧伤、电推约10%麻痹接入普通状态副作用路径。目标直接被击倒时先结算使用者反伤，目标 HP 归零后不再附加异常状态；替身不能被附加状态穿透（源码路径已检查，边界待实测）。**用户实测记录**：己方、敌方分别使用闪焰冲锋，均观察到对方至少一次烧伤；约十余次共观察到两次烧伤，样本不足以验证精确触发率。**未逐项确认**：伏特攻击麻痹概率、各招式反伤数值、直接击倒后反伤、未命中／属性免疫、替身及双倒等特殊场景。⑧附带链接空间修复：首次构建遇到 Bank `$34` 的 `Red Bedroom PC` 无法放置，将该独立区段迁至 Bank `$3E`，入口仍通过 `BANK(OpenRedBedroomPC)` 动态选择 Bank；用户随后继续运行测试，但未报告卧室 PC 专项检查／新版 MAP 数据。⑨替身多段结算另在 SUB-5.62.42 实现，⑩电推专属动画仍未移植；本段保留⑧验收记录。
- [x] **⑨ `SUB-5.62.42` / `d41f0048` — Substitute 多段攻击与反伤结算时序**：已在⑧验收后源码上独立移植；**用户已运行测试并反馈可以继续，暂未报告明显问题（2026-10-08）**。多段攻击击破目标替身时，本次命中只作用于替身，其余段数可继续命中本体；攻击者自身替身在多段攻击期间避免每段重复切换，目标承伤与反伤结算后再恢复，反伤致使用者濒死则不重画替身。反伤继续使用⑧的比例及状态结算规则。**验收范围限制**：用户未提供双方替身、多段击破、双倒、替身状态穿透等场景的逐项结果，不将这些情况分别记为通过；源码已静态检查双方入口、跨 Bank helper 与 KO 返回路径，仍需遇到问题时再复查。本轮仅更新 TODO 和⑨提交日志，不改游戏代码／版本、不自行编译 ROM、不包含⑩。
- [ ] **缩小的后世代反制（后续独立专项，非下一版）**：以后再考虑为 Stomp（踩踏）和 Body Slam（泰山压顶）增加“目标实际使用过 Minimize 时，跳过一般命中／回避判定并使伤害×2”的特殊规则；Fly / Dig 无敌阶段和正常属性免疫仍应保留，单纯 Double Team 不触发。需单独审查双方判定、状态清除和伤害结算。**当前未实现，后续独立处理；下一项⑨也不加入。**

### 招式 / 数据类（Moves & data）

- [x] **⑤ `AUR-5.62.36` / `e630f377` — Rolling Kick → Aura Sphere（波导弹）**：源码已移植并完成本轮用户验收（2026-10-08），用户分别测试了我方/敌方使用、目标处于无敌状态时使用，以及动画结束后的画面残留，反馈**暂未发现明显问题**。招式沿用 `$1B` ID，威力80／格斗系／特殊／20 PP，使用 Swift 必中效果；Fly/Dig 无敌交互沿用当前战斗机制。特殊攻击的实机伤害数值、6处升级学习表及对高闪避目标的普通必中场景**未由用户实测**；对应招式数据、分类表和学习条目已静态核对，不将其写为运行通过。⑤提交日志已准备，正式 Git 提交由用户完成。

### 菜单 / UI 类（Menu & UI）

- [~] **`MENU-5.62.31` 菜单显示与返回流程**：源码已记录完成与静态检查；原 TODO 中仍有运行验证事项，不能因暴风通过而自动关闭。
- [ ] **PP 道具招式列表显示 `当前PP/最大PP`**：原 TODO 明确列为后续任务，暂不改。

### 道具 / 进化类（Items & evolution）

- [x] **`EVO-5.62.27`**：进化石等级门槛提示和冰之石；沿用原 TODO 的已实现记录，本次未重新测试。
- [x] **`ITEM-5.62.28`**：队伍消耗道具连续使用；沿用原 TODO 的已实现记录，本次未重新测试。

### 形态 / 培育 / 系统类（Forms, breeding & systems）

- [x] **`FORM-5.62.13`～`FORM-5.62.25`、`BRD-5.62.26`**：沿用原 TODO 已实现记录，本次未重新测试。
- [ ] **Day Care 增设 PC、满队伍时转存到 PC**：原 TODO 的待办，暂不改。

### 修复 / 审核类（Bugfix & audit）

- [ ] **Leech Seed/Toxic、OHKO/Counter、连续攻击等遗留问题**：原 TODO 的候选修复；具体范围详见下方 `Legacy bugfix candidates still worth auditing`，本次不改动。
- [~] **Mimic/Disable 与 Substitute 状态防护**：原 TODO 为部分实现/待审查，本次不更改结论。

### 长期规划 / 待决定（Backlog & design）

- [?] **TM 是否恢复消耗制**：仍待设计决定，不因本次提交改变。
- [ ] **地区扩展、天气、特性、性格、长期 UI/引擎计划等**：见下方 `Legacy Upstream Wishlist — Audited Against Current Project`，保留原始状态和细节，暂不集中修改。

## Current RPP Roadmap

### Completed

- [x] FORM-5.62.13 through FORM-5.62.25 — regional-form instance identity work: Link Trade, Hall of Fame, Transform, Capture, Trainer/Gift/NPC Trade/Evolution, random wild encounters, Starter, Fishing, Headbutt, Static Wild/Ghost Marowak, and persistent-marker compile-time guards.
- [x] BRD-5.62.26 — Day Care / Breeding producer uses the stored parent's persistent form marker and gives the baby the same registered runtime Form when supported; otherwise it explicitly falls back to `FORM_NORMAL`.

### User-tested — Independently imported battle animations

- [x] SP-5.62.33 — Sucker Punch animation-only: two purple punch passes, Dark HIT_BIG palette and new sound events, integrated without the separate modern success/failure gate. User reports testing the move without noticing obvious problems (2026-10-08); do not interpret this as confirmation of each player/enemy/repeated-use case. The ③ battle-logic patch is still pending, and the actual Git commit remains user-controlled.
- [x] HUR-5.62.32 — Hurricane: Polished Crystal wind-column renderer, five persistent high-speed streak sets, Thunder timing, bilateral animation support and normal post-hit feedback imported in isolation from Energy Ball branch `32b5022c`. The user reports having tested this move and observed no obvious problem (2026-10-08). This closes the previously pending general runtime check based on user feedback; individual player/enemy, palette/WX restoration and follow-up move/menu cases were **not separately documented as passed**. Reopen if a reproducible issue appears. Commit message prepared; actual Git commit must be made in the user's repository.

### User-tested — Battle logic

- [x] SP-5.62.34 — Sucker Punch modern failure gate from `5ca3afb3`. Source audit of turn order, damaging-move type, action intent, failure/PP flow, Mirror Move ID, AI early decision and `$CCE0` WRAM found no definite blocking issue. **User reports runtime testing without obvious problems (2026-10-08)**; individual edge cases not separately certified. Existing general Trainer item/switch priority timing is a broader architectural limitation. ③ commit message prepared; actual Git commit remains user-controlled. Does not include ④ priority tiers.

### User-tested — Priority / Battle logic

- [x] PRI-5.62.35 — Move priority tiers imported independently from `ddddb20e`: +7 offset, ExtremeSpeed +2 > priority +1 moves > normal 0 > Counter -5. Same-tier Speed/tie logic unchanged; Roar/Whirlwind/Teleport/Bide keep priority 0 pending a full action/mechanics review. **User reports runtime testing without obvious problems (2026-10-08)**; individual edge cases are not separately certified. Source review found no definite blocking issue; Trainer AI item/switch decision timing remains a broader architectural limitation. ④ acceptance log prepared; no ROM build or Git commit by assistant.

### User-tested — Steel Wing animation

- [x] SW-5.62.37 — Steel Wing Gold/Crystal animation from `75ac4ff2`; reuse Iron Tail Metallic intro, restore display and call Wing Attack closing pairs; Steel type palette; enemy-side vertical shake and BG0 top-row cleanup. **User reports all three requested test scenarios completed without obvious problems (2026-10-08): player use, enemy use including vertical shake/top-row residue, and alternating Steel Wing / Iron Tail / Wing Attack with display restoration.** No additional frame-by-frame or rare edge-case certification is implied; acceptance log prepared, no assistant ROM build or Git commit.

### User-tested — Battle stat effects

- [x] BSE-5.62.38 — damage-triggered stat side effects and Gen I Special balance from `ff4fec55`. User reports runtime testing with no obvious issues in the tested scenarios (2026-10-08); individual edge cases were not independently certified. **Minimize remains +2 evasion / 10 PP** by user balance decision; String Shot remains -2 Speed, Amnesia +1 Special. The experimental BSE-5.62.39 +1 change is **not** applied. Future, not-next-version standalone task: Stomp and Body Slam deal 2× damage and bypass ordinary accuracy/evasion against a target that used Minimize, while keeping Fly/Dig and type-immunity exceptions; not implemented here. ⑦ acceptance log prepared; no assistant ROM build or Git commit.

### User-tested — Recoil and secondary status

- [x] RCL-5.62.41 — imported `7ecf21ce` as ⑧ recoil and Flare Blitz / Volt Tackle side effects, plus isolated Bank $34 placement repair. **User reports testing Flare Blitz from both sides and observing burn once on each side without obvious problems (2026-10-08)**. Approximately two burns across a dozen-plus attempts is observational only, not an accuracy test for the roughly 10% status chance. Recoil fraction values, Volt Tackle paralysis, direct-KO and Substitute boundaries, and Red bedroom PC interaction have no separately reported complete runtime verification. The Bank move retains the dynamic `BANK(OpenRedBedroomPC)` lookup; no new MAP/ROM build was performed by the assistant. Recoil logic and game version remain unchanged during this TODO-only acceptance. Commit message prepared; actual Git commit belongs to the user.

### User-tested — Substitute / multi-hit / recoil timing

- [x] SUB-5.62.42 — imported ⑨ (`d41f0048`) after RCL-5.62.41. **User reports having tested the feature and asks to proceed (2026-10-08), without reporting obvious problems.** No itemized pass report was supplied for both-side Substitute, multi-hit break, recoil double-KO or status penetration; do not infer that every edge case was verified. Source audit covered substitute restoration, post-damage recoil timing, both actor branches, and Bank helper symbols. ⑦/⑧ acceptance status has been reconciled in the category board; Minimize remains +2, and the Stomp / Body Slam counterplay is a future standalone item. No assistant ROM build or Git commit. ⑨ acceptance message prepared; ⑩ remains unported.

### User-tested — Moves / animation

- [x] AUR-5.62.36 — Aura Sphere from `e630f377`; replaced Rolling Kick at ID $1B, Special Fighting 80 power, 20 PP, Swift-style hit effect, MoveDex, six level-up entries, and separate animation/SFX. **User reports having tested both sides using the move, use against an invulnerable target, and post-animation visual residue, with no obvious problems (2026-10-08).** Special damage output, level-up learnset in gameplay, and a high-evasion accuracy case were **not tested at runtime**; source data/classification/learnset entries were statically reviewed. ⑤ acceptance log prepared; no assistant ROM compilation or Git commit.

### Completed — Evolution / Items

- [x] EVO-5.62.27 — evolution-stone Party UI reads the matching evolution entry's minimum level dynamically: below the requirement it shows `LvXX+`, at/above the requirement it shows `Able`, and actual use below the requirement gives a short level-specific no-effect message. Failed selections do not play the use sound or consume the stone and return to the same Party selector. This already covers cases such as a Lv28 Pokémon whose stone evolution requires Lv30; no separate Lv28 reminder is needed.
- [x] EVO-5.62.27 — add `ICE_STONE` in the former `$1B` unused slot, make it a normal purchasable item, and migrate Alolan Vulpix from the temporary `SUN_STONE` substitute to `ICE_STONE` at level 30.

### Completed — Party Consumables

- [x] ITEM-5.62.28 — repeatable out-of-battle Party consumables stay in the Party workflow while stock remains. HP/status medicine, vitamins/Rare Candy, PP Up, Ether/Max Ether/Elixir/Max Elixir and their berry equivalents allow another valid target after success; failed field use does not consume the item or force a return to the Bag. Single-move PP items reopen the move submenu on the previously selected move, while Elixir/Max Elixir return to the Party selector. Explicit cancel, zero remaining quantity, battle medicine use, evolution-stone success, and TM/HM teaching keep their existing exit rules. Existing class-specific success/denial audio is preserved.

### Completed in source — Party Item Menu Polish

- [x] MENU-5.62.31 — use a light Party redraw on PP-move-menu cancellation and TM/HM target retry, without the repeated palette whiteout. Clear overlaid menu tiles with BG transfer paused; keep initial Bag-to-Party graphics initialization and normal Party-to-Bag restoration.
- [x] MENU-5.62.31 — place only the PP-item move window at row 6 (lower border row 11, just above the message frame at row 12); preserve the selected move on repeat use, leave success/no-effect result text visible, and reopen the move list without replaying the question. Battle and other move-selection menus are unchanged.
- [x] MENU-5.62.31 — play `SFX_HEAL_AILMENT` on successful PP Up, sharing the existing PP-restore success path; no-effect and PP-Up-at-limit choices do not consume stock or play the success sound. PP Up continues to set its one-use flag through the `wUsingPPUp` / `wd11e` shared WRAM address.
- [~] MENU-5.62.31 — source cleanup and static patch checks completed; emulator/device verification remains for menu no-flash/complete-border cleanup, text legibility, cursor and cancellation handling, TM/HM retries, and normal PP Up counts. Do not mark runtime behavior as user-tested until these checks are performed.
- [ ] MENU-5.62.31 — when using PP Up or a PP-restoring item, show the target move's current PP and maximum PP (e.g. `current/max`) in the move-selection/confirmation UI, so the actual available PP and full PP are visible.

### Planned — Day Care

- [ ] Add a usable PC inside the Day Care.
- [ ] Allow Pokémon received from the Day Care to be sent to the PC instead of being blocked solely because the party is full. Confirm the exact receive paths (baby, withdrawn deposited Pokémon, or both) when implementing.

### Future design decisions

- [?] TM consumption model — the upstream final source already leaves TMs in the Bag after successful teaching, and the current fork retains that behavior. Reconsider later whether this project should restore consumable, single-use TMs or keep infinite-use TMs.

### Legacy bugfix candidates still worth auditing

- [ ] Leech Seed / Toxic shared damage counter interaction.
- [ ] Toxic becoming normal poison after switching.
- [ ] OHKO move behavior still tied to Speed.
- [ ] Counter edge cases involving Substitute / OHKO moves.
- [ ] Partial-trapping move turn-lock behavior.
- [ ] Whirlwind / Roar behavior in trainer battles.
- [ ] Rest interaction with stat changes caused by status conditions.
- [?] Rage issues — define the exact remaining bugs before changing behavior.
- [~] Mimic / Disable random-selection behavior — some paths were modernized, others still need a focused audit.
- [ ] Multi-hit moves currently calculate damage/accuracy only for the first hit.
- [ ] Poké Ball zero-shake failure still uses the old "You missed the Pokémon!" behavior/text.
- [~] Substitute protection against status — several paths have explicit checks, but the behavior is not yet fully unified.

## Legacy Upstream Wishlist — Audited Against Current Project

This section preserves the original author's roadmap. Status markers reflect the current branch as of the BRD-5.62.26 closeout; unchecked entries are not promises that they will be implemented.

### Engine updates and New Features

- [ ] Cleanup pokered-gbc code (optimizations)
- [ ] Add support for larger tileset images, like Polished Crystal
- [ ] Add support for setting XY Flip/Palette Attributes as part of block data?
- [ ] Real-Time Clock, with Day and Night
- [ ] More modern Berry System, allowing you to plant and grow new ones instead of the Gen 2-like current system
- [ ] Expand Pokédex beyond 255 (mimic ShantyTown's "expand-dex" branch)
- [ ] Allow for more than one proper region, so Johto can happen
- [ ] Individual menu sprites for all Pokémon
- [ ] Pokégear/Pokénav equivalent
- [ ] Rematches with Trainers and Gym Leaders, no annoying phone calls
- [x] Bag has multiple pockets and more storage space
- [ ] Held items
- [ ] Special split into two stats
- [x] New available move pool, with a lot more thought put into it this time
- [ ] Weather effects in-battle
- [ ] Abilities (can enable or disable during intro)
- [ ] Natures (can enable or disable during intro)
- [x] Infinite-Use TMs — already present in the upstream final source; the current fork retains it for now, but the TM consumption model may be reconsidered later.
- [~] New Pokéball types
- [ ] Dive areas
- [ ] Battle Tower
- [ ] Battle Factory
- [ ] Battle Tent
- [ ] Pokémon World Tournement
- [~] Player customization options
- [~] Rewritten Trainer AI
- [ ] Secret Bases
- [ ] Surfing Pikachu minigame (ported from Pokeyellow)
- [ ] Ruins of Alph puzzles (waiting for PR from ShantyTown)
- [ ] Bug Catching Contest
- [x] Possibly add Forms
- [ ] Use IVs and EVs instead of DVs and Stat EXP, old DVs become a mini Personality ID
- [ ] Gain EXP on catching a Pokémon

### Bugfixes from Vanilla RB

- [ ] Leech Seed/Toxic shared damage counter
- [ ] Toxic becomes normal poison if you swap
- [ ] OHKO moves based on speed
- [x] Crits ignore stat-ups from both Pokémon
- [x] Agility negates speed-loss before boosting
- [ ] Using Counter on moves used against your Substitute
- [ ] Using Counter against OHKO moves to instakill
- [ ] Trapping moves prevent opponent doing anything
- [ ] Whirlwind and Roar do not work in trainer battles
- [ ] Rest does not undo stat changes from status afflictions you had, such as Burn
- [?] Rage issues
- [~] Mimic and Disable choosing moves at random
- [ ] Multi-hit moves deal same damage for each blow
- [ ] Make Pokéball break with zero shakes instead of "You missed the Pokémon!"
- [x] Stat-up too high making your stat roll over to ultra low values
- [~] Substitute not protecting against status
- [x] Remove badge boosts, to be more modern

### Unsorted Notes

- [ ] Pokégear/Pokénav would replace Town Map, have a VS Seeker option, a radio, etc.
- [ ] Several things in WRAM could stand to be optimized, such as event flags and map script bytes
- [ ] Hide/Show routine needs work. Probably better to redo it based on normal flags somehow, like Gen 2
- [ ] IndexToPokedex and PokedexToIndex are pointless now, and can be removed
- [ ] Remove the weird TM Name Generation routine, TM Case will work differently.
- [ ] Add even more trainer classes and cameo trainers
- [ ] Johto needs songs from Crystal, of course
- [ ] Johto should include areas that were in Polished Crystal/Christmas
- [ ] Battle Tower will be in Johto
- [ ] Pokémon World Tournement will be where Pokéathalon was in HGSS
- [ ] Battle Tent will be in Celadon
- [ ] Battle Factory will be in Johto with the Battle Tower
- [ ] Instead of CheckForHex and CheckForElectroBall, there should be one routine to calculate variable BP moves
- [ ] Once Held Items are a thing, Acrobatics needs to be variable BP, too
- [ ] Any checks for hard-coded map IDs need to also check wCurRegion when the time comes
- [~] New trainer AI will be more modular, and AI_BASIC will be at least be generically intelligent
- [ ] Pull Swimmer F data out of Beauty class list
- [ ] Consolidate Leader classes and Elite Four classes
- [ ] Maybe change Trainer DVs back to checking AI Number, instead of Trainer Class, once those are consolidated
- [ ] If Natures are disabled in intro, do not display on status screens, and use a neutral nature always
- [ ] If Abilities are disabled in intro, do not display on status screens, and use a blank ability for everyone
- [ ] EXP on catch is annoying, since a lot of variables are reused during the EXP Gain process. Will require a lot of testing.
