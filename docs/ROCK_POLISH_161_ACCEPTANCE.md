# MOVE-5.62.161 — Rock Polish 战斗外名称映射验收与代码审查

**日期：**2026-10-15
**项目／分支：** `rpp-backup`／`常规功能备份`
**最新可核实的已提交起点：** `MOVE-5.62.156`／`710dbf8ceb7691922e2b6e72e0bd9f1e1f61e116`（用户原始 ZIP 导出记录；不等于 161 已提交）
**当前用户已实测版本：** `MOVE-5.62.161`
**验收清理性质：**项目文档及三处 ASM 注释归一化；汇编指令、游戏版本号、存档、MoveDex 和战斗行为不变。

## 一、最后生效的实现及用户反馈

| 版本 | 最终生效内容 | 用户确认与边界 |
| --- | --- | --- |
| 156 | 战斗中按实际 `AGILITY` 和使用者物种显示 `Rock Polish`，ROCK 属性、专属动画、速度 +2、PP 30 | 战斗核心与 ROCK 属性曾由用户明确确认通过；大岩蛇／大钢蛇、AI 所有路径、变身／通信等未逐项确认 |
| 159 | Party／宝可梦详情、Bill’s PC 存入详情与取出详情 | 用户逐处确认均显示新名称；158 的外层分流未达到这一结果，不能保留为有效版本 |
| 160 | 战斗及经验道具升级后的直接学习和四招遗忘替换列表、提示文字 | 用户在 161 的反馈中明确确认两种升级来源、直接习得及四招替换均正常 |
| 161 | 遗忘师／回忆师选择列表，遗忘结果和回忆学习提示 | 用户额外测试多种场景并确认回忆、遗忘完整流程及列表均正常 |

这组反馈不等于对任意宝可梦普通 `Agility`、阿罗拉形态、全部取消／滚动组合、所有敌方／复制／变身场景做了逐项回归。`157` 的大范围显示试验曾出现升级学习名称错、回忆／遗忘列表空白及 PP Up 名称错；最终源码不包含该试验方案。

## 二、最终源码调用路径检查

- `engine/menu/status_screen.asm` → `FormatRockPolishStatusMovesString`：详情页以当前 `wLoadedMonSpecies` 匹配五种物种，逐条生成 `wMovesString`；普通物种保留基础名称。原先 158 的外部条件分流已被 159 的内部判断取代。
- `engine/evos_moves.asm` 和 `engine/learn_move.asm` → `MaybeRenameRockPolishLearningMoveName`：`GetMoveName` 后只在 `wd11e == AGILITY` 且 `wPartySpecies[wWhichPokemon]` 属于名单时，按正确 `CopyString` ABI (`DE` 来源、`HL` 目标) 覆写名称；学习待显示字符串 `wcf4b` 与遗忘旧招式的 `wcd6d` 分别处理。
- `engine/learn_move.asm` → `FormatRockPolishLearningMovesString`：完整重建升级四招替换列表，以免 `Rock Polish` 长于 `Agility` 时覆盖后续行。`wMovesString` 为 56 字节；本别名 11 字符，四个相同别名加四个分隔和结束符最多 49 字节，不超过缓冲区。
- `scripts/move_deleter.asm`、`scripts/move_relearner.asm` → `SetRockPolishNPCMoveListSpecies` → `PrintListMenuEntries_` → `MaybeRenameRockPolishNPCListMoveName`：NPC 菜单在 `wWhichPokemon` 被列表行索引复用前保存所选物种于 `wMoveMenuType`，在菜单返回后恢复原值；列表只对 `wListPointer` 指向 `wRelearnableMoves` 时允许别名。`PlaceString` 使用的 `HL` 在跨 Bank 调用前后保存。返回时恢复原 `wMoveMenuType` 的 `pop bc`、`ld a,b`、`ld [wMoveMenuType],a` 不会修改 Carry，故保留取消分支标志。
- `engine/battle/primary_type_move.asm` 是已存在 156 战斗映射的同一浮动 ROMX 功能区，本轮不合并或修改战斗分支。`ROCK_POLISH` `$F0` 继续保留，`AGILITY` `$61` 仍为存档中的真实 ID，不释放新编号。

## 三、冗余与风险审查结果

1. **确认存在维护性重复**：详情页与升级四招替换各有一段约 60～70 行的文本缓冲格式化循环；NPC 文本别名判定也有与升级文本相似的 `CopyString`。这是潜在去重机会，但两个调用点的物种来源与菜单现场不同，提取共用例程会改变寄存器保存、ROM 调用或循环结构；在已完成用户验收后，本次不为优化而更改 ASM 指令。
2. **共享暂存字节需要严格限域**：`wMoveMenuType` 原本还用于 Mimic／PP 相关路径，161 必须维持 NPC 调用现场的先保存／后恢复；`wWhichPokemon` 在滚动列表中不是稳定 Party 槽。静态核查与用户受测场景均未指向当前必修的溢出、未恢复标志或数据覆盖问题。
3. **未查出可证实的遗留试验执行路径**：157 的反向 `CopyString` 与破坏绘制坐标的代码、158 的失败外层分流都没有出现在当前 161 差异中；当前源码只有 159／160／161 的保留路径。不能据此宣称所有边界没有隐藏 bug。
4. **不在 161 混入新功能**：PP 恢复与 PP Up／PP Max 道具、MoveDex `Seen/Use` 对映射 `AGILITY` 的过滤（用户已选择方案 B）、升级／连续使用后的对话框残留、地区形态区分与旧 `$F0` 回收都保持独立待办；本次不修改。

## 四、清理交付与 Git 状态

- 清理增量修改 `TODO.md`、`PROJECT_DELIVERY_RULES.md`、`RPP_DEVELOPMENT_PITFALLS.md` 并新增本文件，同时只在 `engine/battle/primary_type_move.asm` 和 `engine/menu/status_screen.asm` 将三处历史 159/160 注释统一为最终 161；汇编指令逐字节不变。当前游戏版本仍为 `MOVE-5.62.161`，不新增虚构的 162。
- 本次拟提交说明采用从用户提供的**最近确定已提交 156 HEAD 到最终 161** 的累计差异：159/160/161 有用户运行反馈，但未收到单独真实 Git Commit 确认。若本地实际已经把它们分别提交，须以本地真实 Git 历史修正提交跨度；本文不声称用户当前远端 Push 状态。
- 不编译／链接 ROM，ZIP 无 MAP，不能证明实际 Bank/ROM 空间余量。静态符号检查、补丁正反向回放、逐文件内容／权限核验只能说明交付一致性，不能替代用户侧 ROM 验证。
