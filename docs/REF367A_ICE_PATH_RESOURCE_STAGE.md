# REF-367A｜冰之通路 Gold 原始地图/碰撞/机关前置阶段（不可进入的资源暂存）

> 基线：`REF-366@`，`常规功能备份`，HEAD `a95ac8d1ddaf47575bc4f08935033d014bfa58cf`。本开发批只准备并审计 Gold 原版资源，没有注册任何新活动地图，没有加入游戏运行 ASM，没有更新游戏内版本，也不表示冰之通路已经可以游玩。

## 已实际完成

- 使用 REF-332 交接 Gold `pokegold-master`，按原始 `data/maps/blocks.asm` / `gfx/tilesets.asm` 引用解析并复制 **五张 `.blk`**、原始 `ice_path.png`、64 个 metatile 的二进制、Gold `ice_path_collision.asm` 与调色索引参考文件。
- 由真实 `.blk` 和 Gold 4 象限碰撞定义逐格计算 **3,060 个 8×8 角色格**，写为五份固定字节词表的 `.roles.bin`。保留 Gold 布局原始字节，不将 Gold 块 ID 直接误用为 RPP Kanto `ICE_CAVERN` 的块 ID。
- `docs/REF367A_ICE_PATH_GOLD_SOURCE_CONTRACT.json` 固化：地图 stable IDs 70/95/96/97/98，尺寸、原版边框 `$09/$19`、夜间调色、每个地形格的分类数、22 个洞内 `warp_event` 的 1 基和 0 基序号、源触发方式和目标序号，以及 Route44 `(56,7)` / Blackthorn City `(36,9)` 两个室外 `CAVE` 入口。
- 在本项目中新增 `tools/johto_ice_path_367_stage_audit.py`：本地无需 Gold 工程也能重算 3,060 个地形角色、验证 staged 文件哈希、22 条 Warp 语义及目标配对。`tools/tests/test_johto_ice_path_367_stage.py` 包含篡改块、角色、冰面到达 Warp、目标序号、室外门坐标和错误激活地图的负向检查。

## Gold 正确机制（下次实现时不能遗漏）

| 地图 | Blocks | Cell | ICE | PIT | Warp 点 | 附注 |
|---|---|---|---:|---:|---:|---|
| IcePath1F, ID70 | 20×18 | 40×36 | 234 | 0 | 4 | Route44 与烟墨城的 DOWN-only 出口；2 个 B1F 楼梯 |
| IcePathB1F, ID95 | 10×18 | 20×36 | 44 | 4 | 8 | 四块 Gold Strength 石头，四个**主动 PIT**，不是 Rock Smash |
| IcePathB2FMahoganySide, ID96 | 10×9 | 20×18 | 304 | 0 | 6 | 4 个 PIT 目的 Warp 在 `ICE` 上；它们**不能主动逆传** |
| IcePathB2FBlackthornSide, ID97 | 5×9 | 10×18 | 91 | 0 | 2 | 有 5 格单向 HOP，需按方向移动 |
| IcePathB3F, ID98 | 10×9 | 20×18 | 0 | 0 | 2 | Gold 原版有一块 Rock Smash 石头；本阶段不放置 |

- 合计 **673 ICE、4 PIT、8 HOP、78 方向墙**。Gold 的 `PALETTE_NITE` 是固定夜色，并不是使用 Flash 的黑洞。
- B1F 四个 Strength 石头（Gold 初始位置 11,7 / 7,8 / 8,9 / 17,7）是未来 R2 路线的关键玩法；**Rock Smash 延期不等于可以把 Strength 也延期**。将来实现需正确落洞、B2F 对应石头落点、持久事件状态、冰面滑行和切图续动；不能只加普通走路。
- 原版 `ICE` 上的 B2F #3..#6 是源事件登记的到达目标，不得当成踏格 Warp；普通 LADDER 和 B1F PIT 的触发规则也不能混为一谈。
- 必须在后续激活时实现/验证：独立 Gold 图块显示和 palette、合法冰面滑行/停墙、下落动画/四个目标、Strength 石头推入对应 PIT、所有楼梯、室外双出口、出洞安全迈步、Dig/离洞绳回程、Bike 及存档和旧地图回归。还需四版 ROM + MAP，ROM0≥64 B 与手机实测。
- NPC、剧情、物品球、野生遭遇、Rock Smash 石头与技能继续不做。

## 为什么不能马上把地图标为完成

RPP 旧 `ICE_CAVERN` 图块不等于 Gold `TILESET_ICE_PATH`。直接启用五张 `.blk` 会出现错误画面/碰撞；当前 ICE 连续滑行和 B1F→B2F 石头落洞尚未实现。为防止出现“进入地图但无法离开”或绕过机关，本资源暂存阶段**不会改** `NUM_JOHTO_ACTIVE_MAPS=65`、`JohtoHeaderDescriptors`、`JohtoRegisteredWarpRoutes=172` 或现有出入口。静态审计主动验证这些仍处于未启用状态。

## 本批测试边界

- `python tools/johto_dungeon_batch_preflight.py --gold-root <REF332 Gold 根目录>`：核 Gold 原版，包含 Ice Path 源表。
- `python tools/johto_ice_path_367_stage_audit.py --root .`：纯本地 staged 资源 3,060 格、22 Warp 检查。
- `python -m pytest -q tools/tests/test_johto_ice_path_367_stage.py`：正向及篡改负向测试。
- `python tools/validate_current_project.py --skip-pytest`：既有全项目强制审计，历史固定旧版本失败另记，不能当作当前游戏 R2 完成验收。
- 不做 `make`、不修改 ROM0、`git commit` 或 `git push`；不将离线通过等同于已编译 ROM/模拟器实测。

## 本次实际执行结果

- Gold 源码洞穴预审：`tools/johto_dungeon_batch_preflight.py` PASS。
- 新 Ice Path 本地源数据门禁：PASS，逐格 3,060 格，22 个 Warp、4 个 PIT、4 个 arrival-only ICE。
- 定向测试：`python -m pytest -q tools/tests/test_johto_ice_path_367_stage.py tools/tests/test_johto_dungeon_batch_preflight.py tools/tests/test_johto_warp_field_entry_gate.py tools/tests/test_union_cave_ruins_portals_366.py` → **32 passed**。
- `validate_current_project.py --skip-pytest --gold-root <Gold>` 中 ASM 局部符号、活动地图表长、Warp/Field Entry 和 Dark Cave 专项以及新 Ice Path 门禁均通过；主迁移审计为 **1,698 通过、23 失败**。在未经本轮修改的 REF-366 基线独立执行相同命令，结果也是 **1,698 通过、23 失败**，错误条目逐项相同。**这 23 项不是本批新增失败**，也不能说全项目测试全部通过。
- 无用户 ROM/手机反馈；本批不提供游戏运行功能，因此没有新的 ROM/MAP 测试条件。
