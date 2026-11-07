# REF-354｜Spark / 扩展动画身份修复（开发候选）

## 基线与范围
- 起点是 REF-353 正式清理源码；用户反馈已经自行应用与提交，工作树干净，但本轮无新的 Git 提交哈希文件。仅修改战斗逻辑、版本、TEST-only 测试夹具和相关文档/静态测试。
- 参考来源：`MOVE_CLASSIFICATION_REVIEW_LOG_v2.md`、`SPARK_REVIEW_LOG.md`，两份原始审查都针对较早的 REF-351A；本轮在 REF-353 的相关 ASM 上确认调用链后修复。

## 根因与修正
1. **Spark 的 Dynamic 伤害 ABI**：`GetDamageVarsForPlayerAttack` 与 `GetDamageVarsForEnemyAttack` 在 `D` 放入基础威力后调用 `PhysicalSpecialSplit`；分类器旧实现把 DE 用作能力地址，返回前未恢复 D。`ResolveDynamicMoveCategory` 现在入栈保存 DE，在 Physical 和 Special 两个返回分支恢复。原 `A` 分类结果、Attack≥Special 为 Physical、烧伤时未折半 Attack 比较、等级和伤害计算不变。
2. **扩展动画身份**：`PrepareCurrentMoveAnimation` 保留现有 EXT02 的 `PlayRoughExtAnim`。对其他非零 `wExtendedActiveMoveOrdinal`，不调用 `GetCurrentMoveID` 做普通动画专用覆盖查找，而使用扩展招式六字节记录的第1字节（已经装入 `wPlayerMoveNum`/`wEnemyMoveNum`）作为原生兼容动画 ID。EXT13 则播放 WING_ATTACK，而非由于 `$0d` 与 Spark 碰撞触发 Spark 专用动画；EXT04/06/07/08/09/17/27 同类处理。
3. **分类表保护**：增加 `.MovesTableEnd` 与 `ASSERT .MovesTableEnd - .MovesTable == NUM_ATTACKS`，不改255字节内容和任何招式元数据。

## 测试模式
- `BATTLE_TEST_BUILD` 保留原 TEST-217 菜单/夹具，新增9页27场景中的22–27。逐场操作和可见验收标准见 `docs/REF354_TEST_SCENE_ACCEPTANCE_GUIDE.md`，旧测试历史仍见 `docs/BATTLE_TEST_BUILD.md`。默认只对测试ROM额外编入 `test_suite_run001.asm` 和 `test_suite_imposter.asm`。
- 测试入口：玉虹大厦 1F 的 Pokey → SELECT TEST → TRANSFORM TEST → 第8/9页。22/23玩家、24/25敌方的 Spark 均使用卡比兽测试队伍：Attack/Special 为 170/65 或 65/170，受击方相应 Defense/Special=100、HP=120/120。**原开发候选存在队伍分支接线错误**，六个新场景未正确进入 Snorlax 配置分支；本复核修正版已修复。26/27在 battle slot0 设置扩展身份位及低字节 ordinal，阻断通常的普通 ID 解释。
- 测试不能仅凭动画判断 Spark 威力；修正版首击非暴击理论约损失42～50 HP，120 HP 的目标应**存活**，而旧 D 被地址高字节覆盖时可能一击 KO。实际范围需 TEST ROM 验证，玩家操作与动画对照详见验收手册。烧伤、能力等级极值、平局及玩家/敌方 Metronome/Mirror Move 仍是下一轮动态回归项。

## 明确未改的内容
- REF-352/353 的门口、黑洞/Flash、CGB LCD-on 载图、地图 DMA、RGB555 渐暗、音效、存档和场地逻辑全部不动。
- 不触碰 Counter 固定伤害/Bide 的未冻结资格规则；Sucker Punch 目标方扩展身份查询和未来扩展招式 DYNAMIC 分类仍是后续扩展前置项，不能当作本版已解决。
- 扩展 EXT03..40 仍是容量占位实验；普通 Spark 专用动画与 EXT02 Play Rough 动画保留。

## 验收与构建限制
- 现有 Python 测试、ASM 局部标签检查、Gold/Johto 表和迁移审计均是**静态预检**。当前没有编译/链接新的 Red、Blue、TEST Red、TEST Blue，也未生成新 MAP；ROM0≥64B、Bank 容量、`jr` 跳转范围、真机/模拟器动作和音频都须用户本机再验证。
- REF-354 是开发候选；用户确认 TEST 录像和构建后再正式清理。按此前用户要求，正式提交时功能、工具、测试、文档一笔提交，没有隔离第二批。

## CLEAN REF-354 收口补记（2026-11-07）

- 用户已提供 REF354.mp4：22 玩家 Physical、23 玩家 Special、24 敌方 Physical、26 EXT13、27 EXT04 的录像表现符合预期；其中场景24可见 120→71 HP，属于49点受击。场景25仅出现于菜单，尚无敌方 Special Spark 的实际出招证明。其余未录像覆盖边界仍未验收。
- 当前版本按最初的设计保持**扩展动画兼容 ID → 原生基础播放器**，不会自动复用普通招式的专用配方（如 `WingAttackDedicatedAnim`）。这不是本版新发现的已确认故障，日后要实现“完全复用专用配方”须先明确设计需求。
- 延后修复项、源码路径、风险可达性、所需测试及优先级见 [`REF354_BATTLE_FOLLOWUP_BACKLOG.md`](REF354_BATTLE_FOLLOWUP_BACKLOG.md)。本次 CLEAN 不再改动已通过录像的运行 ASM、TEST 场景或测试脚本。
- 注意：本文件顶部“开发候选、无新 MAP”的描述保留作为**开发阶段历史记录**。后续审查曾发现一个与 REF-354 符号相符的 Red MAP，但缺少可独立核对的完整四种构建日志、ROM 和 MAP；不能据此认为四种 ROM 全部通过。最终收口状态与证据范围以 `CLEAN_REF354_BATTLE_FINAL_ACCEPTANCE.md` 为准。
