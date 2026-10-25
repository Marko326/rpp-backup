# TRF-5.62.209 — 手动 Transform 同回合续招（TEST-215 用户验收收口）

## 目标行为

本功能只改变**手动根行动 Transform 成功后**的后续流程，不改 Transform 的复制内容、失败条件或百变怪入场自动变身。

- 玩家直接使用 Transform 并成功：变身动画／提示结束后打开四招菜单；仅 A 确认当前复制招式并在同一次行动中执行。B 在这个第二次选招界面无效（不取消 Transform、不执行高亮招式、不退出菜单）；上下键照常移动，仍执行原有 PP/Disable 检查。普通战斗选招菜单的 B 取消功能与 Mimic 的目标选择菜单均不受影响。
- 敌方直接使用 Transform 并成功：从刚复制的四槽中随机选择一个非空招式，并在同一次行动中执行。
- Link 战斗不打开本地第二次选招菜单；沿用 Mimic 的共享 PRNG 随机选槽方式，避免第二次交换动作槽位。双机同步仍待实机验证。
- Transform 失败：不打开复制招式菜单，不追加攻击；本次手动 Transform 仍正常消耗原行动及其 PP。
- 入场 Imposter：继续直接调用共享 `TransformEffect_`，只完成免费自动变身，不选择或执行复制招式。

## 保留的现有规则

- 目标处于 Fly/Dig 半无敌状态、施术者已经变身、同物种且同运行时地区形态时，沿用当前 RPP Transform 的失败判定。没有额外加入后世代的 Substitute 等失败规则。
- Transform 复制的是战斗临时数据与扩展招式身份，不复制目标当前／最大 HP，不永久改写 Party 招式或 SRAM。复制招式 PP 沿用现有 Transform 的 5 PP 设置。
- Transform 自身先按普通招式流程扣一次 PP；成功后所选复制招式再按普通执行流程扣临时 PP。两个扣减分别属于根招与本回合的子招，不代表多获得一个回合。
- 不重跑睡眠、麻痹、混乱、服从等根行动前置检查；子招从 `CheckIfPlayerNeedsToChargeUp` / `CheckIfEnemyNeedsToChargeUp` 继续，照常执行蓄力、命中、伤害、效果与 MoveDex 记录。
- 只给根行动本身为 Transform 的成功分支追加子招。Mirror Move／Metronome 等派生出的 Transform 不会额外生成一个第二层行动。

## 实现路径

1. `engine/battle/core.asm` 的 `TransformEffect` 保持短 Bank-F 网关，远调用 `TransformMoveFollowup_`，取回 `HL` continuation 后清理 `JumpMoveEffect` 的临时返回地址，再跳转到对应续执行入口。
2. `engine/battle/moveEffects/transform_effect.asm` 的 `TransformEffect_` 以 Carry 明确返回成功／失败。手动失败文本由可返回的远调用完成；自动入场失败仍静默返回。
3. 成功后，玩家单机打开 `MoveSelectionMenu`，恢复战斗画面并通过 `GetCurrentMove` 重新装载选中槽；敌方／Link 使用 `BattleRandomFar` 从复制槽中选一个非空招式，设置对应侧的 move slot index 和 selected move，再调用 `GetCurrentMove`。异常全空列表回退 Struggle。
4. `wPlayerLastSelectedMove` / `wEnemyLastSelectedMove` 保留根招记录，不被复制子招覆盖。测试构建额外同步 `wTestBattlePlayerSelectedMove`，以适配测试 ROM 对当前招式的既有覆写。

## TEST-212：旧矩阵历史记录

TEST-212 的先后手、半无敌、蓄力、KO、EXT、PP 和双向换人矩阵已由当前 TEST-214 重排替代。不要再把旧编号 01–15 当作当前菜单定义；当前有效场景、逐步操作与预期见 `docs/BATTLE_TEST_BUILD.md` 顶部 TEST-214 表。

## TEST-213：后手续招菜单旧画面缓存修复（在 TEST-214 视频中已做定点回归）

用户提供 `06测三次.mp4`，复现：对手先 Fly 并进入半无敌，玩家 Transform 失败；下一回合对手完成 Fly 落地后，玩家后手 Transform 成功，选择复制的 Fly 时，已落地对手图像异常消失。Fly/Dig 隐藏**正在施招的宝可梦自身**属于正常机制；错误是菜单恢复旧回合画面，把已落地对手抹掉。

静态根因：`MainInBattleLoop` 回合开始的 `SaveScreenTilesToBuffer1` 可能保存对手升空后的隐藏图；`TransformMoveFollowup_` 打开复制招式菜单后，旧 `LoadScreenTilesFromBuffer1` 恢复这张旧画面。候选修复在玩家成功 Transform、打开第二次菜单之前重新保存当前画面，不改 Fly/Dig 状态、动画脚本或行动顺序。测试 ROM 标签为 `TEST-213`，正式版本仍 `TRF-5.62.208`。

## TEST-214：复杂场景双向覆盖（历史验证与未覆盖事项）

当前矩阵将简单的先手／后手 Tackle 测试移出主要验收路径，改为：玩家／敌方后手 Fly、Dig、EXT、KO、Substitute 镜像；另保留 PP/RESTORE、真实双方换入、双方变身失败和先手蓄力对照。01–04 特别串联“半无敌状态第一次变身失败 → 下一回合完成 Fly/Dig → 后手变身成功 → 复制招式再次蓄力”，用于同时验证失败判定、后手续招、画面缓存与两回合招式状态。

- 敌方确定性复制槽只在 `BATTLE_TEST_BUILD` 下，对场景 `$41/$43/$45/$47/$49/$4e` 固定复制后的槽 1；正式 ROM 与其他情况仍沿用原随机非空槽规则。
- `$45` 的玩家 EXT 身份只在测试 ROM 的回合边界注入，保证敌方后手 Transform 前能复制到正确 sidecar；不写 Party/SRAM。
- 详细配置与逐回合操作以 `docs/BATTLE_TEST_BUILD.md` 顶部为准。TEST-214 的 `214.mp4` 记录了 01、02、03、05、06、09、10；01 画面清除错误未再复现，02/06/10 的主路径可见，03 仅覆盖 Dig 第一段，05/09 的预设敌方动作未发生，均不能记为完整场景通过。其余场景不因本次未重录就否定旧证据；双 ROM/MAP 与 Link 仍待验证。

## 功能规则和验收边界（记录，不要求重复全部测试）

- [ ] 玩家使用 Transform 成功后出现复制招式菜单；选中攻击招式后，该招式在本次行动中执行，对手按正常回合顺序行动。
- [ ] Transform PP 只扣一次；选中的复制招式从 5 PP 扣至 4 PP；战后 Party 原始招式／PP 未被永久覆盖。
- [ ] 敌方使用 Transform 成功后随机执行一个复制招式，不会只变身后空过行动。
- [ ] 目标处于 Fly/Dig 时失败，不出现 follow-up 菜单或追加攻击；失败提示与 Transform 自身 PP 保持原规则。
- [ ] 复制 EXT 招式时菜单名称、身份与实际效果正确；普通招式仍正常。
- [ ] 复制两回合招式时正常进入蓄力流程；复制 Transform 再次尝试时按“已变身”规则失败。
- [ ] Battle Animation ON/OFF 均正常；Link 双端选招／PRNG 同步需要单独实测。

## 静态与动态证据边界

本轮没有修改自动 Imposter 的入口规则、SRAM 或 Party 数据布局。静态检查与补丁回放不等于 ROM 编译／链接或游戏实测；Red/Blue、MAP/Bank、动画开关、EXT 子招和 Link 双端仍待本地验收。

## TEST-215：Transform 第二次选招菜单 B 键修复（用户定点验收通过）

- TEST-214 用户反馈：在手动 Transform 成功后的第二次选招菜单，B 和 A 一样会结束菜单并出招。这是新增续招流程使用普通战斗菜单（type 0）时保留 B 取消键，却忽略了返回结果导致的。
- TEST-215 仅针对该续招菜单使用 type 3：显示、指针更新、PP/Disable 检查沿用普通战斗选招，监视键只包含上、下、A。B 无效，按 A 才能确认；Mimic type 1、普通 type 0、relearn type 2 不变；正式续招算法、入场 Imposter、Link 选槽不变。
- Disable 仍沿用项目旧规则：禁用标记包含槽号及剩余回合，Transform 复制招式时并不清除此标记；因此刚复制到同槽的招式在菜单中可能仍被禁用。此次不改变此规则，不将 B 禁止逻辑当作 Disable 修复。
- 测试 ROM 标签改为 `TEST-215`，正式 ROM 更新至 `TRF-5.62.209`。用户已运行 TEST-215 并确认：手动 Transform 成功后的复制招式菜单按 B 没有反应；普通选招菜单的 B 仍可正常响应。此反馈确认键位隔离主路径；A 选招、PP/Disable 极端边界及正式 Red/Blue 双构建、MAP/Bank、Link 仍不能据此认定全部实测。


## TRF-5.62.209 收口约束（2026-10-25）

- 本轮清理不再修改已验收的第二次选招 `type 3` 逻辑，也不改变普通菜单／Mimic 的原按键规则。用户反馈 B 在复制招式菜单无效，普通选招 B 正常响应；这属于已验证的操作范围。
- **Disable 是旧规则，不作为本轮缺陷修复。** 当前 Disable 保存被禁用槽位与持续回合；Transform 会替换槽内招式而不重置禁用标记，所以旧禁用状态可能继续限制对应的新槽。该可达路径的具体游戏实测并未完成，保留为独立规则／风险，不应把它说成刚复制招式在同一回合被对手重新 Disable。
- TEST-214 独立审查与录像记录共同指出：野生敌方可随机选中 PP=0 的非空招式；05 原定 Splash 却见 Power Whip，09 原定 Substitute 却见 Tackle。**这是测试夹具对旧 AI 的错误假设，不是 Transform 或旧 AI 的新故障。** 07、14 存在同类稳定性风险。此次保留现状并标注未验，不悄悄修改正式 AI 或重写测试场景。
- 未完整实测：03 Dig 第二段/图像恢复、PP/RESTORE 精确值、两侧 KO 结算、完整联机随机同步、动画开关、正式及测试 Red/Blue 构建与新 MAP。用户不要求无原因重录已测场景；未来遇到专项需求再验证。
- 收口所依据的最近可重建提交为 `eae3e430690fcc798083887b09d44e891717cead`（TEST-209 / IMP-5.62.207）；后续 TRF-209 与 TEST-215 均仍属于待用户自行 Git 提交的差异。
