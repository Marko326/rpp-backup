# REF-342｜城都地牢批量转换预检与交班

## 目的

本交班用于后续批量转换城都山洞/地牢。联合洞穴 REF-339～342 暴露出：地图像素一致不等于运行语义一致；Gold 的 Warp 类型、方向墙、跳崖、边框、固定调色、Flash、冰面、落洞、瀑布/漩涡都必须在激活地图前独立审计。

本轮**不修改游戏运行 ASM、地图或版本号**，只加固离线转换/审计工具并记录后续施工规则。

## 已横向检查的 Gold 地牢

共 8 组、28 张地图：

| 地牢 | Gold tileset / palette / 边框要点 | 主要语义 | 批量风险 |
|---|---|---|---|
| Union Cave 1F/B1F/B2F | `CAVE` / `PALETTE_NITE` / `$09` | LADDER、DOWN carpet、UP_WALL、水、B1F HOP_RIGHT | 已作为基准验证 |
| Slowpoke Well B1F/B2F | `CAVE` / `PALETTE_NITE` / `$09` | LADDER、UP_WALL、水 | **与联合洞穴最接近，推荐下一验证组** |
| Mount Mortar 4层 | `DARK_CAVE` / `PALETTE_DARK` / `$09` | LADDER、CAVE、carpet、UP_WALL、大量 HOP、水、瀑布 | 需要 Flash-aware DARK + 瀑布 |
| Ice Path 5层 | `ICE_PATH` / `PALETTE_NITE`；边框 `$09/$19` 混用 | LADDER、ICE、PIT、UP_WALL、少量 HOP | 必须有滑冰与落洞语义，不能套普通洞穴 |
| Whirl Islands 8张 | `DARK_CAVE` / `PALETTE_DARK`；边框 `$09/$0F/$2E` 混用 | LADDER、CAVE、carpet、UP_WALL、HOP、水、瀑布 | Flash + 多边框 + 多层复杂连接 |
| Dark Cave 2张 | `DARK_CAVE` / `PALETTE_DARK` / `$09` | CAVE/carpet、UP_WALL、HOP、水 | Flash-aware DARK；不要只换暗色调 |
| Dragon's Den 1F/B1F | 1F=`CAVE/$09`；B1F=`JOHTO/$71`；均 `PALETTE_NITE` | LADDER/carpet/CAVE、UP_WALL、大量水、B1F WHIRLPOOL | **同一地牢混 tileset/边框**，漩涡独立机制 |
| Burned Tower 1F/B1F | 1F=`TOWER/DAY/$00`；B1F=`CAVE/DAY/$09` | PIT、LADDER、HOP；B1F有 destination-only/special Warp 记录 | 证明“洞穴=固定暗色”是错误假设 |

### 关键数量例子

- SlowpokeWellB1F：29 个 `UP_WALL`、32 个水格、2 个 LADDER。
- MountMortar1FOutside：67 个 `UP_WALL`、268 个水格、48 个瀑布格。
- IcePathB1F：44 个 ICE、4 个 PIT、4 个 LADDER。
- DragonsDenB1F：437 个水格、1 个 WHIRLPOOL，且 tileset 为 `JOHTO`、边框 `$71`。
- WhirlIslandB2F：156 个水格、24 个瀑布格，边框 `$2E`，不能硬编码 `$09`。

## 联合洞穴暴露出的错误，后续必须通用规避

1. **不能按 `TILESET_*` 名字猜 Gold 文件名。** `TILESET_DARK_CAVE` 实际与 `TILESET_CAVE` 共用 `cave_metatiles.bin` / `cave_collision.asm`。本轮工具已改为解析 Gold `gfx/tilesets.asm` 的真实 `Tileset*Meta/Coll` 别名。
2. **Warp event 不等于统一触发方式。** `LADDER/PIT/CAVE/STAIRCASE` 是走入格立即 Warp；`WARP_CARPET_*` 是站在格上按指定方向；普通 `FLOOR/HOP_*` 上的 Warp 可能只是目标落点，不能自动变成源触发器。
3. **同 tileset 跨层也必须重建目标 XY。** 否则来源坐标会原样带到目标层。新增地牢 tileset 接入 RPP 时必须进入 `DungeonTilesets` 或等价目标落点重建路径。
4. **`UP_WALL` 等是“边”而不是“整格墙”。** 只做 passable/solid 二值转换会制造空气墙或错误穿墙。
5. **`HOP_*` 是方向行为。** 必须核方向和安全落点；不能因为视觉 tile 可走就当 FLOOR。
6. **边框按地图属性读取。** Cave 常见 `$09` 不是统一值；Ice Path、Whirl Islands、Dragon's Den、Burned Tower 都有反例。
7. **`PALETTE_NITE` 与 `PALETTE_DARK` 不同。** 前者固定使用夜间亮度；后者在 Gold `ReplaceTimeOfDayPals` 中走 Flash-aware darkness：未使用 Flash 是 `DARKNESS_PALSET`，使用后才进入 NITE 亮度。不能只把颜色永久涂暗。
8. **场地技能必须分开。** WATER/Surf、WATERFALL、WHIRLPOOL、ICE、PIT 都是独立运行机制；缺一个就不能把地图标成“已完成”。

## 本轮工具改动

### `tools/johto_gold_tileset_semantics.py`

新增 Gold tileset 真实资源解析器：从 `gfx/tilesets.asm` 的标签解析 Meta/Coll，支持别名与共享文件，失败时 fail-closed。

### `tools/johto_gold_door_audit.py`

`GoldCollisionIndex` 不再假设 `<tileset>_collision.asm`；统一通过上述解析器读取真实碰撞表。因此 `TILESET_DARK_CAVE` 等共享碰撞表的地图可以被正确逐格解码。

### `tools/johto_dungeon_batch_preflight.py`

新增只读地牢预检：一次盘点上述 8 组/28 张地图的：

- tileset / palette / border；
- Warp 坐标、Gold collision role、触发类型；
- 同 tileset 目标落点重建风险；
- 方向墙、跳崖、水、瀑布、漩涡、冰面、落洞数量；
- `PALETTE_DARK` Flash-aware 标记；
- 标准洞穴 / 黑暗洞穴 / 冰与落洞 / 混合 tileset 等 profile。

### `tools/johto_rpp_batch.py`

全 Gold 库存也改用真实 Meta/Coll 资源解析；批处理会生成 `johto_dungeon_preflight.json`。该预检失败时，批处理直接停止，不能继续生成“可接入”结论。

### `tools/johto_pilot_migration_audit.py`

提供 Gold root 时，主迁移审计新增 `gold_johto_dungeon_batch_semantics_preflight`；以后改坏地牢来源解析或关键 Gold 分类时，主审计会直接失败。

## 后续地牢接入流程（强制）

每一张/每一层按以下顺序，不能先批量激活后再找问题：

1. 跑 `johto_dungeon_batch_preflight.py`，确认该地图 Gold profile。
2. 转换像素/metatile 后做逐像素对照。
3. 读取**该地图自己的** border/palette，不继承上一座洞穴。
4. 解码全图 collision role，并生成坐标语义表；方向墙/ledge 不准降级成整格 passability。
5. 按 Warp 坐标上的 Gold role 决定触发语义；同时区分 source trigger 与 arrival-only Warp。
6. 同 tileset 跨层确认目标 XY 重建路径。
7. 有 WATER/WATERFALL/WHIRLPOOL/ICE/PIT 时必须有对应专项运行支持和负向测试。
8. 一次只激活一层/一小组，手机验收通过再继续下一层。

## 推荐下一张

优先 `SlowpokeWellB1F`。它与联合洞穴同为 `TILESET_CAVE + PALETTE_NITE + border $09`，有 LADDER、UP_WALL、水，但暂时没有瀑布、漩涡、ICE/PIT。若它能只“填数据/表”而不再改核心引擎，说明普通 Cave 兼容层才真正可复用。

之后建议顺序：Slowpoke Well B2F → Burned Tower（验证 DAY/PIT 例外）→ Dark Cave（验证 Flash-aware DARK）→ Mount Mortar/Whirl Islands → Dragon's Den → Ice Path。

## 验收边界

本交班与工具是**静态来源/转换预检**，不代表 ROM 已编译、MAP 容量通过或手机实机正常。任何激活地图仍需用户按项目要求构建 Red/Blue/TEST、检查 ROM0>=64B，并按层实际走动测试。
