# DOC-218 — TRF-5.62.210 / TEST-217 最终验收边界（2026-10-25）

正式功能与此前已验收的同回合续招、第二次菜单 B 无效、画面缓存更新保持不变；此次收口**没有重新修改战斗 ASM**。在已提交 TRF-5.62.209 的基础上，本轮唯一正式算法差异是在共享 `TransformEffect_` 成功复制完成后、提示／续招之前按当前执行方清零旧 Disable 的**槽位／计时与招式编号两个字段**；失败路径不清理。成功后再次命中 Disable 仍按原有规则生效，目标侧字段不被新代码清除。

- **实测已观察**：`TEST-216.mp4` 场景 16/17 成功路径双向表现符合旧禁用解除；18 失败后旧禁用仍可见。`TEST217.mp4` 场景 19/20 的**正常第一槽单招**由原引擎回退 Struggle；21 敌方成功 Transform 后玩家真实 Disable 命中，选中禁用的是 `Disable`，不是 `Tackle`，故不能宣称 Tackle 被禁用后的选招行为实测通过。
- **测试可靠性改进**：TEST-217 场景 16/17 的测试夹具同时检查两个 Disable 字段，弥补 TEST-216 只检查一个字段而后续注入覆盖另一个字段的假阳性风险。此修正是测试设施而非正式战斗规则。
- **自动 Imposter**：共享内核静态覆盖成功清理；正常首发、换人、昏厥补位路径一般在登场阶段就重置旧 Disable，所以不专门人为制造携带旧状态的非法换入测试。该判断不代表全部异常状态已实测。
- **剩余证据边界**：没有本环境 ROM 编译／MAP／联机双端、全部 PP/KO/异常状态专项验证。已知 05/09 及可能的 07/14 野生敌方 PP=0 非空招式测试夹具问题保留；不因此修改正式 AI。不再要求无原因重复测试已录过的简单场景。
- **版本与基线**：干净 TEST-215 / HEAD `92ac347531c3fe2f72597a60d91d24b7dd2e9aa2` → 正式 `TRF-5.62.210`、测试 `TEST-217`；DOC-218 为文档收口标识，不修改 ROM 字符串。以下各 TEST-212～217 小节为历史开发／设计记录，含“待验”文字属于当时状态，以本节最新录像分级为准。

---

## TEST-217 追加审查（2026-10-25，待 ROM 验收）

- 成功 Transform 同回合续招前清理旧 Disable 两字段的 TRF-5.62.210 正式实现不变。对手在同一次行动的中途没有正常可执行的 Disable 窗口。
- 16/17 测试夹具之前只判断禁用计时字节，随后直接覆盖招式编号，可能造成假阳性；TEST-217 现在要求两个字段均为 0，部分清理会走可观察失败路径。
- 场景 19/20 专测**双方原生的唯一第 1 槽被禁用后的 Struggle**；场景 21 用真实 Disable 招式验证敌方 Transform 之后仍能被禁用。与原来的 16/17 注入新状态不同，不应互相冒充通过。
- 第 1 槽为空而后面留一格被禁用的异常排列不属于正常单招场景。现有敌方 AI 对该异常状态存在死循环风险，留待可达性审查；不要因之改动已经验收的 Transform/Disable 主算法。

# TRF-5.62.210 — 手动 Transform 同回合续招与 Disable 状态修复（TEST-216 开发候选）

## TEST-216：Disable 状态生命周期

- 成功 Transform 后，清除**施术者自身**的 `wPlayerDisabledMove` / `wPlayerDisabledMoveNumber` 或 `wEnemyDisabledMove` / `wEnemyDisabledMoveNumber`。Disable 记录的是招式槽与剩余回合；成功复制新招式后，旧槽位标记不能继续限制新招式。
- Transform 失败时不清除 Disable，原状态按旧逻辑继续生效。
- Transform 成功之后，若新招式槽后来被 Disable，照常按新状态禁用；清理只发生在成功 Transform 的那一刻，不会让变身者对后续 Disable 免疫。
- 清理只清施术者，不清目标身上的 Disable。共享 `TransformEffect_` 成功复制路径处理玩家、敌方和自动 Imposter；自动换入本来会清理换出者状态，此处保持共享逻辑一致。
- TEST-216 新增 16 `P-DIS-CLEAR`、17 `E-DIS-CLEAR` 双向场景，以及 18 `P-DIS-FAIL` 失败对照。16/17 用测试夹具直接写入旧 Disable 状态，再在下一回合注入不同槽位的新状态，避免随机 Disable 选槽／命中率干扰。该夹具验证的是状态生命周期，不代表 Disable 招式的准确率或随机选择经过测试。

## 目标行为

同回合续招只改变**手动根行动 Transform 成功后**的后续流程，不改变复制内容或失败条件。TEST-216 另将成功 Transform 清除施术者旧 Disable 状态放入共享成功复制内核；自动 Imposter 仍不追加招式行动。

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
- **历史记录（TEST-215 时）**：当时尚未清除 Transform 前的 Disable 状态；该行为已由 TEST-216 的新规则取代。保留此行仅用于解释 TEST-215 的范围，不代表当前候选仍保留旧行为。
- 测试 ROM 标签改为 `TEST-215`，正式 ROM 更新至 `TRF-5.62.209`。用户已运行 TEST-215 并确认：手动 Transform 成功后的复制招式菜单按 B 没有反应；普通选招菜单的 B 仍可正常响应。此反馈确认键位隔离主路径；A 选招、PP/Disable 极端边界及正式 Red/Blue 双构建、MAP/Bank、Link 仍不能据此认定全部实测。


## TRF-5.62.209 收口约束（2026-10-25）

- 本轮清理不再修改已验收的第二次选招 `type 3` 逻辑，也不改变普通菜单／Mimic 的原按键规则。用户反馈 B 在复制招式菜单无效，普通选招 B 正常响应；这属于已验证的操作范围。
- **TEST-215 的收口结论（历史）**：当时决定暂不修改 Disable。TEST-216 已重新审查并实施成功 Transform 清除施术者旧状态的候选；失败保留、后续新 Disable 正常生效。TEST-216 相关实测尚待用户完成。
- TEST-214 独立审查与录像记录共同指出：野生敌方可随机选中 PP=0 的非空招式；05 原定 Splash 却见 Power Whip，09 原定 Substitute 却见 Tackle。**这是测试夹具对旧 AI 的错误假设，不是 Transform 或旧 AI 的新故障。** 07、14 存在同类稳定性风险。此次保留现状并标注未验，不悄悄修改正式 AI 或重写测试场景。
- 未完整实测：03 Dig 第二段/图像恢复、PP/RESTORE 精确值、两侧 KO 结算、完整联机随机同步、动画开关、正式及测试 Red/Blue 构建与新 MAP。用户不要求无原因重录已测场景；未来遇到专项需求再验证。
- 收口所依据的最近可重建提交为 `eae3e430690fcc798083887b09d44e891717cead`（TEST-209 / IMP-5.62.207）；后续 TRF-209 与 TEST-215 均仍属于待用户自行 Git 提交的差异。
