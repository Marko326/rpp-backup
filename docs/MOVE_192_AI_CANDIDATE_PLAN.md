# MOVE-5.62.192 — 训练师 AI EXT 候选招式评价：下一阶段准备资料（尚未开发）

## 当前已确认的事实

- 191 的 F02（EXT02 与普通 Karate Chop 会心撞号）和 F05（EXT16 与普通 Gust/Fly 特判撞号）已获用户 191T 四项测试反馈通过，191T 已由用户撤销；**不能将 191 视为已 Git 提交**。
- `engine/battle/trainer_ai.asm` 的各个 AI 评分循环从 `wEnemyMonMoves` 按槽取低字节，并调用 `ReadMove`。现有 `ReadMove` 保存 HL/DE/BC 后 `dec a; ld e,a; callba _ReadMove`。
- `engine/battle/ai_read_move.asm` 的 `_ReadMove` 仍对 `Moves` 做六字节表项索引与 `CopyData`，并调用 `ApplyEnemyCandidatePrimaryTypeOverride`。在该函数中没有按候选槽 EXT 身份选择 `ExtendedMoves` 的现有分支。
- `engine/battle/extended_move_loader.asm` 已有执行期间的扩展数据加载，不等于 AI 候选读表阶段已正确选择 EXT。正式两张原生敌方来源表仍为空，当前正式训练师队伍未普遍分配 EXT；191T 的野生／敌方 EXT 分配不应永久留下。

## 192 目标与边界

1. AI 在评估**敌方四槽的第 N 个候选**时，同时获得低字节与该槽的扩展身份，不应把临时的 `wExtendedActiveMoveOrdinal` 当成任意候选槽的身份；须区分当前实际使用的招式和正在比较的未选招式。
2. 根据完整身份选择普通 `Moves` 或 `ExtendedMoves` 六字节表项，保持 `wEnemyMoveNum`、威力、属性、效果等候选评分字段一致；与既有 `ApplyEnemyCandidatePrimaryTypeOverride` 的覆写顺序核对，确保覆盖只作用于正确候选。
3. 确保 Trainer AI 的各层评分函数对候选槽的指针、循环计数、暂存寄存器保持一致，并覆盖候选中“EXT02／普通同低字节招式”的混用；避免远调用改坏 B/C/D/E 而影响下一个槽位。
4. 不在这一批改动训练师换人／使用道具策略、招式本身的伤害执行、PP、永久学习来源、SAV/Party/PC 格式，也不扩充 40 个测试占位技能的正式发放配置。

## 192T 测试补丁的准备要求

- 必须是**单独可撤销补丁**，与 192 正式功能补丁区分，测试结束只撤销 192T。
- 测试环境使用明确指定的训练师、队伍第 1 只／第 2 只、各候选四槽招式和固定战斗条件；避免需要刷随机遭遇或依赖 AI 随机选招才能确认候选属性。先核对训练师复战入口，再确定地图位置；不提前声称已经制作了该补丁。
- 对照必须包含 EXT 与普通招式同低字节混合、招式属性／威力／效果会改变评分的情形、非 EXT 普通训练师保持原行为；正反撤销后检查测试训练师／来源表／概率辅助代码无残留。
- **给用户的测试说明必须按回合写清**：去哪里、己方第几只上场、敌方第几只、选择哪个招式、期望看到什么、未命中或更换目标怎么办。训练师 AI 的内部评分通常不可直接从前台观测，因此如需可重复的判定，应在 192T 中增加仅测试版可见反馈，正式代码不得留调试显示。

## 继续开发前的基线要求

- 用户先应用／提交 191 正式收口并保留新 HEAD 信息；收到新项目 ZIP 时按 `data/game_version.asm`、`RPP_PROJECT_CONTEXT/02_EXPORT_INFO.txt` 与 `current_worktree.patch` 核对，不能假定此前 189 HEAD 仍是当前项目。
- 仅对真实 191 提交后工作区开始 192 正式改动；不能将本计划书误标记成已完成的 192 代码。
