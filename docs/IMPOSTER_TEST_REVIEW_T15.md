# RPP 变身者 · T15 菜单修复与独立审查回应

- 日期：2026-10-24
- 现有输入：用户提供的 **TEST-208 / T14 当前 Worktree ZIP**，ZIP 内 `RPP_PROJECT_CONTEXT/02_EXPORT_INFO.txt` 声明干净 Git 基线 `54b4eb5f00d83eca8ea518b8d8b2ea93320fbc7b`，并附带可反向重建该基线的 `current_worktree.patch`。
- 修改后的测试显示：**TEST-209**；正式 ROM 仍是 **IMP-5.62.207**。
- 外部输入：《RPP_变身者_T14_审查日志(1).md》；结论：一个源码确定问题，两个潜在风险和若干测试覆盖缺口。用户后续已反馈本轮相关功能与测试场景均已测过、未发现问题；本文件区分该用户反馈与本环境未执行的构建／链接／联机验证。

## 1. 本轮已修复：FINDING-01

**文件**：`engine/battle/test_suite_run001.asm` · `TestSuite_ChooseGroup`。

T14 的菜单入口只保存 `hFlags_0xFFF6`、`wd730`，`LoadScreenTilesFromBuffer1` 恢复地图时却将 `H_AUTOBGTRANSFERENABLED` 无条件设为 1。如果进入菜单前的值为 0，就不能成对恢复。

T15 的实现：

1. 单次地图备份后立即将 `H_AUTOBGTRANSFERENABLED` 原值压栈，再保存原 `hFlags_0xFFF6`、`wd730`。
2. 复用 T14 的唯一返回路径；保持 `A` / `F` 的选中结果和 Carry 位不受恢复操作影响。
3. 首先恢复 `wd730`、`hFlags_0xFFF6` 和地图备份；让 BG 传输保持开启，调用一次 `DelayFrame` 等待图块上传。
4. 最后从栈中弹出并还原原始 `H_AUTOBGTRANSFERENABLED`（包括 0），再按原有 Carry 语义返回。

由此 B（顶层取消）及 A（确认任意实际场景）均进入同一个恢复路径；子菜单 B 只回上级，不提前恢复全局状态。未引入新 WRAM/SRAM。

## 2. 风险调查（本次不改战斗核心）

### RISK-01 动画暂存

`engine/battle/imposter.asm` 的 `PlayImposterTransformAnimation` 在进入 Transform 动画前将 `wMoveAnimScriptLoaded` 置 0，且保存和恢复 `wAnimationID` / `wAnimationType`。`engine/battle/animations.asm:MoveAnimation` 的尾部会将 `wMoveAnimScriptLoaded` 置 0，并清理同类动画辅助状态。该标志表示是否有待使用的扩展配方，而非要求跨每次动画保留的永久战斗属性；盲目恢复非零值可能会让旧配方泄漏到后续动画。

**结论**：源码确认普通动画结束主动清除该标志，但尚不能由静态分析证明所有切换/中断时序。T15 不擅自更改保存方式，保留“开/关战斗动画、紧接普通与扩展招式”的专项设备测试。

### RISK-02 双倒挂起

`ImposterOnPlayerSendOut` 的开头无条件清空 `wImposterEntryFlags`；只有当玩家新上场的原物种是百变怪、对方 HP=0 时，才将 bit0 置 1。`ImposterOnEnemySendOut` 在双方有效目标装载后消费该 bit0（先清再执行变身）。非百变怪的真实上场也会清理旧状态。

**结论**：已经存在一次性消费及新入场重置，缺少异常退出留下持久状态的已证实触发路径。T15 不修改正式 ROM 战斗流程，仍保留战斗提前终止后再开战的增量验证建议。

## 3. 规则和 18 个现有场景保持不变

继续使用 `docs/IMPOSTER_TEST_REVIEW_T14.md` 作为**规则、15 项 Imposter 与 3 项 Substitute 场景的完整目录**。本轮未改 `test_suite_imposter.asm`、`TransformEffect_`、行动优先级、能力复制、失败条件或动画演出，也未新增后世代限制。

未直接覆盖但可后续专项补测的内容：训练师百变怪首发（IMP-16）、敌方失败（IMP-17）、变身离场后原始招式及 PP 核对（IMP-18）、同种不同形态（IMP-19）、已变身目标（IMP-20）及异常退出（IMP-21）。这些是测试缺口，**不是确认代码缺陷**；不要求用户重新打全部 18 场。

## 4. T15 用户验收结果与剩余边界

- [x] 用户确认测试版 Pokey 直接进入两类菜单，版本显示 `TEST-209`。
- [x] 用户确认 `SUBSTITUTE TEST` / `IMPOSTER TEST` 的层级返回、PAGE 光标与翻页行为符合预期。
- [x] 用户确认现有测试场景均已测过，未发现问题；无需再次逐项重跑已验收的 18 项。
- [x] T15 源码修复覆盖原 BG 传输开关为 0/1 的保存与恢复路径：保存入口值、恢复地图、等待一次图块传输，再恢复原值。用户实测未报告异常。
- [ ] 本环境未执行 `make red / blue / test-red / test-blue`，也未生成新 MAP；正式／测试双 ROM 构建与 ROMX 空间仍须以用户本地构建结果为准。
- [ ] Link 双机同步、异常战斗提前结束后再开战、动画 ON/OFF 后续普通／扩展招式的专门调试检查仍未由本环境独立验证。

## 5. 最终范围与提交拆分

- 正式战斗功能独立为第一笔 `feat(battle)`：入场自动变身、复用 Transform 判定／复制、原生变身动画和所需 ROMX/WRAM 接入；正式版本 `TEXT-5.62.205 -> IMP-5.62.207`。
- 测试工具独立为第二笔 `test(battle)`：TEST-only 场景、Pokey 两级菜单、`TEST-209` 版本显示、BG 状态恢复及测试说明；测试标签 `B-5.62.204-T09 -> TEST-209`。
- 本环境只做源码与补丁应用／撤销一致性检查；没有执行 Git Commit/Push 或 ROM 编译。
