# REF-349｜Dark Cave 桔梗侧第一批：Gold 数据冻结（尚未开放）

- 游戏源码基准：已应用 REF-348 主审计修复的工作区。本轮只增加候选资源、核验程序和维护文档，**不改游戏执行 ASM**，不修改现有 63 图／160 Warp、不修改 REF-348 游戏标签。`JOHTO_DARK_CAVE_VIOLET_ENTRANCE_LOCAL_ID=190` 是已有的保留 ID，**并未激活**。
- Gold 原版地图：`DarkCaveVioletEntrance`，20×18 block = 40×36 cell，边框 `$09`，`TILESET_DARK_CAVE`，`PALETTE_DARK`（非联合洞穴 `PALETTE_NITE`）。
- 原版 `Dark Cave` 专用 96 tile 图像已冻结；共享 `cave_metatiles.bin` 和 `cave_collision.asm` 已原样备份。Gold 20×18 区块数据与同名 `.runtime.blk` 候选字节一致，但尚未导入活动地图表、图块系统或音频切换。
- 另附 `DarkCaveVioletEntrance.special_cells.json`：按 Gold 的 40×36 cell 坐标冻结全部水域、方向墙、跳崖和跨洞触发格，供下一批按坐标生成运行表。
- 共三个 Gold Warp：`(3,15) → Route31#3` 为向下地毯；`(17,1) → 黑暗洞穴烟墨侧#2` 为踏入即换图的 `CAVE`；`(35,33) → Route46#3` 为向下地毯。后两条必须保持封闭。**第一条也暂不开放**，因为 Flash／冲浪／方向墙／方向跳崖尚未完成运行级验证。
- Gold 逐格：41 `UP_WALL`、12 `HOP_DOWN`、14 `HOP_LEFT`、64 `WATER`；无瀑布、漩涡、PIT。第一批只冻结精确语义，不将方向墙/跳崖降级成普通墙或地板。

## 为什么分批
1. **已完成本批**：冻结 Gold 地图/贴图/共享区块/碰撞/事件/调色来源，添加可独立执行的逐格、Warp、冻结激活状态核验与故障注入。不会影响已验收功能、ROM0，也不需要运行期实机验收。
2. **第二批**：实现 `PALETTE_DARK` 的未 Flash 黑暗/使用 Flash 点亮，复用现有场地 Flash 菜单但限制地图身份，接入64格水域 Surf、41方向墙与26方向跳崖，注册桔梗侧活动地图和 Route31 双向入口。必须通过按键碰撞、Flash前后、旧存档、Red/Blue/TEST MAP 和手机往返后才算开放。
3. **第三批**：在烟墨侧地图验证后开放 `(17,1)`；再独立验收 Route46 出口和新增剧情／岩石等事项，不提前登记 destination-only 触发。NPC、道具、遭遇不在前两批。

## 检验
在项目根目录：`python tools/johto_dark_cave_stage_349.py --project . --gold-root /path/to/pokegold --check`。
仅验证本地冻结资产也可以省略 `--gold-root`，但此时**不能声称与外部 Gold 原版实时比对**。随后运行 `python -m pytest tools/tests/test_johto_dark_cave_stage_349.py -q`。

本轮不编译/链接 ROM、不执行 Git Commit/Push。开发期交付两个互斥补丁：01 相对已应用主审计修复的工作区；02 相对上一笔已提交 REF-348 工程快照并包含主审计改动。两者不可叠加。由于用户尚未提供提交后的新 HEAD Hash，02 只标明**历史源码快照前置**，不得冒充最新 Git HEAD。
