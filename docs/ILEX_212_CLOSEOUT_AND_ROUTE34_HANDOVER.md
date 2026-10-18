# ILEX-5.62.212｜桐树林地图与 Cut 正式收口、Route34 扩图交接

**工作区基线**：最近已确认金银分支 HEAD `057e9fbf5dfa146e0d0da9025840ddc30583da4e` (`GATE-5.62.202`)，当前累计修改最终版本 `ILEX-5.62.212`。此前 `.203～.211` 是未提交的中间开发版本；不等于独立 Git 提交。

**收口性质**：只清理注释及文档、提交日志；不修改 `.212` 已反馈可接受的任何运行时代码或资源。本助手不编译/链接 ROM，不执行 Git Commit/Push；用户需在自己工作区核对应用后再提交。

## 已完成及证据范围

- **地图**：接入 Gold Ilex Forest 独立图块、调色、碰撞掩码与桧皮镇南门房双格双向进出，北口仍封闭；不接 NPC/剧情。
- **Cut**：精确处理 `(8,25)` 的 Gold Cut 树，仅替换 block `$0f` 左下象限为 `$2d`， `(9,25)` Headbutt 树不作为 Cut 目标；借用 RPP Cut 动画。A 键和菜单共用 `JohtoCutBadgeAllowed`：Forest 仅要求会 Cut 的宝可梦，开发阶段不需 Hive Badge；Kanto 保持 Cascade Badge，不更改 HM/徽章存档。
- **画面**：森林 OBJ 树 palette 6 采用 `SpritePalettesNite`；`212砍树(1).mp4` 能看到版本 `.212`、A 键 Cut 和树木可视移除，用户报告“试过了，没有明显异常底色”，因此按用户反馈接受本轮视觉表现；录像不能证明全部其他场景逐项通过。
- **跳崖**：`ILEX-LEDGE-001` 长期保留 DEFERRED；`.205～.208` 的修复均失败， `.209` 起只关闭森林 HOP 入口，恢复 RPP 公共旧逻辑；不把禁用等同于修复。

## 当前未被单项证实的回归与风险

- 菜单 Cut、没有会 Cut 的宝可梦时拒绝、没有 Hive Badge 时仍可用；(8,25) 精确通行及 (9,25) 摇树阻挡；离图返回树复原。
- 南门房两格往返、关东原 Cut 与 Route29/31 的跳崖正常、Forest HOP 确实不触发；跨图后存档/读档。
- 本轮没有新的 RGBDS/MAP 记录，禁止把静态审计通过写成 ROM Bank 链接余量已证明。正式 Git 提交前用户应核实分支、未提交文件与编译后的实际游戏版本。

## 下阶段唯一首要工作：继续地图扩展

1. **桐树林北口门房**：优先阅读 `docs/JOHTO_GATEHOUSE_READ_FIRST.md`，精确接入 Gold 双向门口，核对 tileset、调色、二格朝向/碰撞、立即反向回程、地点提示、存读档和旧门房隔离。
2. **34号道路**：按已有通用 Gold→RPP 转换与强制审计，接入原图块、Block、地图尺寸、局部碰撞、Warp/边界、音乐、地点/Town Map 与旧路线连接；实机正常回程后再继续向前扩展。
3. **不作为下阶段前置**：大葱鸭剧情、HM01 发放、Hive Badge 剧情、Headbutt NPC 及已冻结的 Forest HOP。只有地图路线证明 HOP 必需时才重新立项验证。

## 下一窗口入口

`RPP_PROJECT_CONTEXT/00_READ_FIRST.txt` → `RPP_PROJECT_CONTEXT/03_PROJECT_REQUIREMENTS.txt` → 本文 → `docs/ILEX_CUT_211_MAP_EXPANSION_CONTRACT.md` → `docs/ISSUE_ILEX_FOREST_LEDGE_DEFERRED_209.md` → `docs/JOHTO_GATEHOUSE_READ_FIRST.md`。

**提交纪律**：正式增量补丁基于当前已安装 `.212`；全量补丁基于本轮指定原始 `.206` 工程 ZIP 的实际 Worktree，二选一。合集内附两个补丁及独立 `commit-message.txt`；没有当前 `.git` 状态时不宣称已提交。
