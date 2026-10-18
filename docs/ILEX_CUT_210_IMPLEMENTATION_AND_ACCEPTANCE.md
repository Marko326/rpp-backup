> **历史候选：本文件中 Hive Badge 必需、剧情先于地图验收的条件已由 `.211` 纠正。当前执行合同见 `ILEX_CUT_211_MAP_EXPANSION_CONTRACT.md`。**

# ILEX-5.62.210｜Cut 实装候选与验收边界

> 状态：**Cut 的地图树木交互和图块/碰撞适配已写入源码，尚未完成 ROM 编译、手机实测和 Gold 大葱鸭/HM01 完整剧情**。不得标记为 Cut 玩法全部验收完成，不得提前执行清理三件套/Commit。

## 用户工作区基线

- 用户上传 `ILEX-5.62.209.patch` 累计补丁；先从之前 `.208` 整源加 `.208→.209` 隔离补丁还原候选，再核对累计补丁全部 **59/59 个修改文件的 Git blob 目标 SHA-1**：一致。
- `.209` 暂时关闭桐树林 HOP，保留 Route29/关东跳崖执行器、桐树林地形和南门房；本次 Cut 没有重启 HOP。

## Gold 的唯一 Cut 位置

- `pokegold-master(1).zip` 的 `maps/IlexForest.blk` 与 `data/tilesets/forest_collision.asm`：仅一个 CUT_TREE，为区块 `$0f` 在 block `(4,12)` 的**左下 16×16**格 `(8,25)`。
- **相邻右下格 `(9,25)` 为 HEADBUTT_TREE**，不能整块变普通地面，也不能使用旧关东 `$3d` 全局 tile 识别。
- Forest `.bst` 原始 `$0f` 的左下 8x8 tiles 为 `$28,$39,$38,$3a`；新增 `$2d` 克隆替换这四格为 Gold FLOOR `$05`，其他十二格逐字节保留（包括右下摇树）。不改地图 `.blk`。

## 代码连接

1. `engine/overworld/field_moves.asm:IsCutTile`：新增森林专用 `JohtoIlexForestCutTreeInFront`，要求面向 `(8,25)`、且 live block 仍是 `$0f`。前方其他树/栏杆不能误触发 Cut。
2. `engine/overworld/cut.asm:UsedCut`：宝可梦菜单直接使用 Cut 也识别森林树；`Cut2` 保留原动画和文字，用森林 `$0f→$2d` 专用替换替代 Kanto 的 `CutTreeBlockSwaps`；Kanto/Gym 保留原旧表。
3. `engine/overworld/johto_ilex_forest_collision.asm`：为森林提供前方目标判定、按原 RPP `ReplaceTreeTileBlock` 格子算法计算 live block 地址；仅 `$2d` 替换成功时，允许进入 `(8,25)`。其它全部走原 Gold `JohtoModernMaskedStep` 掩码，包括 `(9,25)` 摇树。
4. `engine/menu/start_sub_menus.asm` 与 `field_moves.asm`：桐树林按 **Johto Hive Badge bit1**，关东仍按 **Kanto Cascade Badge bit1**；需队伍宝可梦掌握 Cut。**目前工程里 Hive Badge 和 HM01 的 Gold 获取剧情尚未接入，因此玩家目前无法仅靠森林主线自然达到授权状态。**
5. 保持 `ILEX-LEDGE-001` 冻结；其它地图的 Cut、Surf、Warp 和碰撞不在本轮逻辑改造范围。

## 行为语义与待验

- Gold/RPP 剪树采用地图视图局部换块；本候选不创建永久存档事件，重新载入地图后恢复原 CUT_TREE。需要实测从不同方向砍树、进出门房、存档读档以及视觉树木回收。
- 技术调试：使用**仅供测试的**合法存档（掌握 Cut 的宝可梦，已获 Johto Hive Badge），不能误用 Kanto Cascade Badge 替代；按 A 触发确认文本→动画→树消失→`(8,25)` 通行、`(9,25)` 仍阻挡；宝可梦菜单 Cut 也测试同样行为。
- 负例：无 Cut、无 Hive Badge、误朝向、树已砍、其他 Headbutt 树、禁止的森林跳崖、Route29/关东原生跳崖、南门房双向回程，均须抽测。
- 工程限制：本轮当前执行环境没有 RGBDS 0.5.2；静态源码/asset 测试及补丁校验**不等于真正 ROM 构建或手机验收**，也不能证明 RAM live map 指针、Bank 及动态图块替换在实机中正确。

## 版本完成与清理三件套的门槛

- **尚待第二阶段**：Gold 原版大葱鸭引导事件、炭工 HM01 奖励、Hive Badge 获取和剧情触发条件；没有这些不能声明 Gold Cut 的正常通关玩法做完。
- 全量 RGBDS 构建、静态 Gold 审计、相关旧地图回归、游戏内 A 键和宝可梦菜单、门房来回、地图重进/读档、原版 Cut 树与 Headbutt 不串、用户手机实际验收全部通过。
- 符合条件后再一次性收口 `TODO.md`、`RPP_DEVELOPMENT_PITFALLS.md`、`commit-message.txt`，制作可核对的最终补丁和 Git commit；本候选不得提交。
