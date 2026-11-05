# REF-339｜联合洞穴1F / B1F固定夜间色调修正（开发候选）

## 根因

此前误将 Gold 的洞穴调色资源随早／日／夜的四套颜色，理解为联合洞穴会按时钟动态切换。Gold `data/maps/maps.asm` 中 `UnionCave1F`、`UnionCaveB1F`、`UnionCaveB2F` 实际都选择 `PALETTE_NITE`。Gold `engine/tilesets/timeofday_pals.asm` 的 `PALETTE_NITE` 在所有时段固定映射到 `NITE_F`。该配置不同于需要 Flash 的 `PALETTE_DARK`。

## 修复

- `JOHTO_UNION_CAVE` 仅更换背景调色组，从 `INDOOR_*` 改为 `CAVE_*`（使用项目既有的七组金版NITE RGB5数据）。
- Gold `gfx/tilesets/bg_tiles.pal` 的 NITE 行 0–6 与项目既有 `CAVE_GRAY/RED/GREEN/BLUE/YELLOW/BROWN/LIGHT_BLUE` 四色参数逐项一致；第7组继续使用项目通用 `CRYS_TEXTBOX`。
- 不引入昼夜时钟、不增加新调色槽位、不变更关都图块或现有其它地图调色组。
- 保留已验收的联合洞穴1F/B1F外边框、楼梯图块与传送、Surf、碰撞、地图尺寸和B2F未开放状态。版本仍为 REF-339。

## 增量基线和验收范围

本次增量以用户最后**明确验收的** 1F/B1F 边缘修复状态为基线。先前派发的“Gold白天调色”补丁属于错误候选，不应与本次修复叠加；如果已安装，请先按其原增量补丁执行反向撤回，恢复到已验收边缘版本，再应用本次增量。全量补丁则是原本项目确认的REF-338 Git HEAD起点的替代安装路径。

需要用户自行进行 Red/Blue/TEST 与 MAP 检查，以及手机内1F/B1F颜色、水面、墙体、楼梯、边缘、上下楼、旧存档测试；本次仅执行静态检查和补丁重放，不自行编译 ROM。
