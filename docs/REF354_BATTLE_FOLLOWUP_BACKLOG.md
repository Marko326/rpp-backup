# REF-354｜战斗遗留问题登记簿（下一次修复从这里开始）

**登记时间：2026-11-07｜状态：仅记录；本次 REF-354 CLEAN 不改动待修功能。**

本表来自两份 REF-351A 审查日志及 `REF354_WORKSPACE_PATCH_REVIEW_LOG.md` 的后续核查，并结合 REF-354 修正版源码与用户 `REF354.mp4` 的可见测试。审查日志不是全部真机证据。这里把“已修复”“未来扩展前置”“规则待定”“当前有意设计”和“测试缺口”明确区分，**不得将下面未触发的架构限制写成当前正式游戏已经发生的故障**。

## 已修复，勿重复修复

| 编号 | 状态与实际实现 | 来源/代码 |
|---|---|---|
| SPARK-001 / MCLS-001 | **已修复**：Dynamic 分类 `push de`，Physical/Special 两个出口 `pop de`，不再破坏基础威力 D；Spark 数据仍为65威力。 | `engine/battle/physical_special_split.asm::ResolveDynamicMoveCategory`、`engine/battle/core.asm` |
| SPARK-002 / MCLS-002 | **已修复核心身份误配**：普通 Spark 的专用动画不变，EXT02 Play Rough 专用动画不变；其他非零 EXT ordinal 不进普通动画专用表，使用扩展数据中的基础兼容动画字节。 | `data/extended_move_animations.asm::PrepareCurrentMoveAnimation`、`data/extended_moves.asm` |
| MCLS-006 | **已修复**：普通招式255字节分类表增加 `.MovesTableEnd`/`ASSERT`。 | `engine/battle/physical_special_split.asm` |

## OPEN-001 / MCLS-003｜扩展 Dynamic 类别未解析（P2，**新增此类前**）

- **现状**：`engine/battle/physical_special_split.asm::_BattlePhysicalSpecialSplit` 对扩展身份直接读 `.extendedClasses` 并返回，不调用普通分支的 `ResolveDynamicMoveCategory`；伤害入口主要区分 Special 与其余类别，未来可能把未解析的 `DYNAMIC` 错走 Physical。
- **可达性**：当前40项扩展分类均为 `PHYSICAL`，没有已启用的扩展 Dynamic 招式；这是**前置架构限制，不是已证实当前玩家伤害故障**。
- **未来修复条件**：新增任何扩展 Dynamic 前，让扩展分支共用动态解析，确保真实攻击方能力、平局 Physical、烧伤用未折半 Attack、DE ABI、菜单与最终伤害类别一致；新增 TEST-only 双方/等级/烧伤/派生场景。

## OPEN-002 / MCLS-004｜Sucker Punch 缺目标方扩展完整身份（P2，**启用来源前**）

- **现状**：`engine/battle/core.asm::CheckSuckerPunchSuccess` 从 `wEnemySelectedMove` / `wPlayerSelectedMove` 获取目标招式低字节后调用 `PhysicalSpecialSplit`，但扩展活动 ordinal 只对应**当前行动方**，不能替代目标方的槽位 sidecar 完整身份。
- **可构造风险**：扩展 EXT14/EXT18/EXT28/EXT39 的类别现为 Physical；相同低字节的普通 ID 依次为 Swords Dance / Whirlwind / Sand Attack / Tail Whip（Status）。若目标实际选择这些扩展招式，错误的普通分类可能使 Sucker Punch 被判失败。
- **可达性**：这四项目前是占位数据；没有足够证据证明正式遭遇已发生上述误判。不要擅自给它们开放正式获取或敌方来源。
- **未来修复条件**：按目标方选招槽位与 sidecar 读取完整身份，再查扩展类别；不要复用当前行动方 active ordinal。TEST-only 验证玩家与敌方的普通 Physical/Status、扩展 Physical/Status/Special 与 Metronome 派生，以及失败提示/优先级。

## OPEN-003 / MCLS-005｜Counter 固定伤害及 Bide 资格（**产品规则待定**）

- **现有机制**：按本体实际扣 HP、基础威力非零、实际 Physical 分类、非 Counter 自身等筛选，最后一次有效扣血×2。**不要仅凭 effect 名称把招式当成 Special**。
- **待用户明确**：Seismic Toss、Super Fang、Bide 释放是否可 Counter；Night Shade、Dragon Rage、Sonic Boom、Psywave 等 Special 固定伤害是否排除。原冻结规则文档 `docs/BATTLE_200_FINAL_RULES_AND_ROUND2.md` 还含命中/文案边界。
- **处理方式**：用户先决定规则，再设计对应效果过滤和 TEST-only 数值回归，不能本轮偷偷改 Counter。

## REF354-ANIM-001｜Wing Attack 专用动画兼容语义（**设计选择，非已证实 Bug**）

- EXT13、EXT27、EXT36 的扩展数据兼容动画字节是 `WING_ATTACK`，但 REF-354 主动绕过普通 `LegacyMoveAnimationOverrides`，因此播放的是原生基础 Wing Attack 动画，不是 `WingAttackDedicatedAnim`。EXT13/EXT04 本版测试只要求**不误播 Spark/Comet Punch**；该判断符合现在的兼容定义。
- **本版沿用方案A**：兼容字节仅指基础动画，不自动复用普通专用配方。未来若用户明确要求表现与普通 Wing Attack 的全部专用配方一致，再单独采用方案B：先确认 EXT 完整身份，再以**兼容动画 ID** 查询专用配方（绝不能以 EXT ordinal 做普通 ID 查询），配合 EXT13/27/36 与普通 Wing Attack 对照测试。

## REF-354 剩余验证清单（请不要写成已实机全过）

- [x] 录像中场景 **22、23、24、26、27** 可见行为符合本版预期；24 玩家受 Spark 后 HP **120→71**（49伤害）。
- [ ] **25 `E-SPARK-S`**：敌方 Special Spark 尚无本版完整出招录像；TEST ROM 选场景25、玩家 Splash，期望无暴击受击约42～50 HP、120 HP 目标不被秒杀。
- [ ] Spark 的 Attack=Special、烧伤下分类与伤害、玩家/敌方 Metronome/Mirror Move、Counter 交互及极端能力等级需专项运行验证。
- [ ] 剩下六组扩展 ordinal 动画碰撞 EXT06/07/08/09/17/27 未逐一实机测；扩展基础/专用动画差异需遵从上方方案A。
- [ ] 四种完整构建：Red、Blue、TEST Red、TEST Blue，检查 ROM0≥64B、相关 ROMX Bank 空间、测试入口只在 TEST ROM、ROM 与 MAP/生成命令对应。当前工程里的单份 Red MAP 不足以证明四种全过。
- [ ] 正式普通战斗烟雾测试及必要音效、存档回归。已完成的 REF-352/353 房门和山洞功能本轮不重做、不改运行逻辑。

**开发顺序建议**：先完成25号录像/构建证据；以后若正式扩展系统要启用更多类别或来源，再优先处理 OPEN-001、OPEN-002；Counter 先等用户定规则。新的任务使用独立版本与可回退补丁，不要重新打旧 REF-354 候选。
