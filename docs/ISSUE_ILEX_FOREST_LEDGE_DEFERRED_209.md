> **截至 ILEX-5.62.212 仍为 DEFERRED**：仅禁用 Forest HOP，未修复跳崖执行器；本轮 Cut 收口不解冻此问题。最新地图开发交接见 [`ILEX_212_CLOSEOUT_AND_ROUTE34_HANDOVER.md`](ILEX_212_CLOSEOUT_AND_ROUTE34_HANDOVER.md)。

# ILEX-LEDGE-001｜桐树林 HOP 跳崖暂缓（CUT 优先）

**状态：DEFERRED / KNOWN BUG / BLOCKED IN FOREST（源码候选，ROM 和实机待验）**
**工程候选：ILEX-5.62.209**；原用户工作区累计补丁为 `ILEX-5.62.208.patch`。
**优先级：不阻塞下一阶段 Cut；但禁止将异常跳崖保留为可触发功能。**

## 已观察事实与证据边界

- `.205`、`.206` 已有用户视频失败反馈；`.207` 视频出现起跳后人物停在崖壁上；用户确认 `.208` 同样失败。
- `.208` 工作区累计补丁确实含版本标记和公共 `HandleMidJump`/主循环更改，但版本字符串不能单独证明 ROM 机器码、游戏状态或手机实测通过。
- 旧两格方案依赖 RPP 模拟方向输入；原 Gold `STEP_LEDGE` 的实现不同。具体运行时根因尚未经 CPU/RAM 逐帧跟踪证实。不要把早期“动画/队列提前清理”假说当成已证实根因。
- Gold 桐树林 HOP：8 处起跳格／10 个合法方向，第二格为目标落点；7 条方向第三格是树。不能直接套用 RPP 3 格位移。

## 本次最小隔离（拟用于 CUT 前的安全清理）

1. `home/overworld.asm` 与已上传的 `.206` 工程该文件**逐字节一致**，撤销 `.207`/`.208` 在 ROM0 添加的专用及共享动画收尾代码，关东与 29～32 号道路回归原执行链。其他地图行为仍需实际 ROM 抽测。
2. `engine/overworld/ledges.asm` 仅在 `.ilexForest` 分支 `ret`，使森林不再进入失败的 HOP 执行器；图块配对表仍保留作证据、以后研究复用。
3. 不修改桐树林 Gold 16×16 通行掩码、地图 .blk/.bst、南门房 Warp、PNG/调色、Cut 引擎、Gold 原版源码和其他路段 HOP 表。普通前方 WALL 格仍由原 `JohtoIlexForestCanStepAhead` 的 mask 拦截。
4. 旧 `.208` 静态“模拟器”测试移入 `docs/archive/`，作为失败假设的历史证据；新增暂缓门禁测试，避免下次有人未经真实验收就重新打开森林跳崖。

**重要：只代表源码级隔离方案完成。未编译 ROM、没有 `.209` 手机验证、没有在用户手机工作区自动应用。**

## Cut 是下一阶段主线

- 优先参考 Gold 原版 `maps/IlexForest.asm` 和现有 RPP `engine/overworld/field_moves.asm:TryCut`、`engine/overworld/cut.asm:Cut2`、`engine/overworld/cut2.asm:AnimCut`，复用原有 Cut 行为。
- 首先识别 Gold `CUT_TREE` 所在位置与阻挡身份，明确取得/使用条件和故事状态；不要把摇树 `HEADBUTT_TREE` 误当 Cut 树。
- **剧情依赖**：Gold 原版 `maps/IlexForest.asm` 中，HM01 Cut 的取得与 `EVENT_HERDED_FARFETCHD` 大葱鸭事件衔接。可以先独立技术验证砍树，但正式获取 HM01 的通关流程不能跳过该剧情依赖。
- 开树前阻挡、满足条件后施放 Cut、树被清除/地图恢复通行、往返门房、存档/读取和已建立的关东 Cut 行为都须单独测试。
- 如 Cut 的任务路线必须依赖目前冻结的 HOP 跳崖，立刻重新评估该缺陷是否仍可延期；此前静态地图检查显示现阶段从南口可抵达大葱鸭初始区域，但**不等于未来完整剧情一定无需跳崖**。

## 跳崖重新开工的准入

只有 Cut 主链或路线验证证明跳崖为必要功能，或项目正常回到该专项时，才重新开启。需要实际 ROM 构建、CPU/RAM 轨迹（`wXCoord/wYCoord`、`wWalkCounter`、`wSimulatedJoypadStatesIndex`、`wd736.6`、`wd730.7`）、Gold 的第二格落点逐帧对照、10 条森林方向验证，以及 Route29/31、Route33/桧皮镇和关东回归。静态测试通过不可视为实机通过。

## 版本与回退原则

- **不要整版回滚 `.205`～`.208`**：会丢失地图、门房、图形和通行等与跳崖无关的工作。
- `.205`～`.208` 的跳崖实现统一记为 **失败/未验收**；本 `.209` 仅冻结森林 HOP，恢复公共旧运行时，尚未提供实际游戏可玩性验收。
- 本补丁只基于已核对的 `.208` 源码候选，用户工作区必须先 `git apply --check`，不可无条件应用，更不能在旧的 `.206`/`.207` 基线上强行打补丁。
