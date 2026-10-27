# REG-5.62.215 / TEST-222 — P2-004 若叶镇与 29 号道路原始地图资源预接入

## 本轮范围

- 使用用户提供的 `pokegold-master(1).zip`，逐字节导入原始若叶镇（10×9）、29 号道路（30×9）块地图，及原始 Johto 2048B metatiles 数据。
- Bank `$42` 中登记两张地图的**稳定地区 ID**（若叶镇 0 / 29 号道路 1）与东西连接源表，不依赖参考分支 `$E7`／`$F4` 旧编号。
- 将源资源固定放置在独立扩展 ROMX Bank `$42`，为后续 Header、瓦片、碰撞、边缘连接、事件和实际 Warp 引擎集成做准备。
- **仍有 0 张活动城都地图**：`JohtoHeaderDescriptors` 为空、稳定 ID 查表返回 `$FF`；不修改关都地图加载、Warp、Fly、NPC、保存区和战斗代码。
- 原版 Gold 的地图内容与 NPC 参考项目已有**有意差异**（如下），因此不能简单用 Gold 原始地图覆盖经过改造的参考版，也不能直接复制参考版的旧地图常量。后续接入必须逐项审阅差异。

## Gold 与参考版的 .blk 差异（0-based 字节偏移）

- maps/NewBarkTown.blk: Gold 90B SHA256 41a1012a051d22ade1b6cdb14577c4b6ad3e195be7024d6f3a020a9f7f5fedd3; NPC reference 90B SHA256 b210de4425e931debf49253868cb0e35ddf4c8bf8a4e3881f7f040f819f251e8; changed cells 1 (0-index): 39:$54->$01
- maps/Route29.blk: Gold 270B SHA256 c64074bce43b16b161497c18245b52bf5e660eb34d0cb3b717b606aa01f735e9; NPC reference 270B SHA256 458b83be91980e911c3fb8f53ff59f7b15c484eadc4647257f8a9093b956acd8; changed cells 19 (0-index): 37:$4f->$83, 65:$4b->$81, 66:$57->$82, 67:$53->$84, 124:$52->$80, 125:$4b->$81, 126:$57->$82, 132:$57->$82, 133:$57->$82, 141:$4f->$83, 171:$4f->$83, 187:$57->$82, 188:$57->$82, 194:$52->$80, 195:$4b->$81, 196:$57->$82, 199:$57->$82, 200:$57->$82, 201:$53->$84

## 后续活动地图启用门槛

1. 将地图头、Tileset/GFX、Blockset、NPC/文本和碰撞实现转成双地区+稳定 local ID 机制。
2. 先解决若叶镇↔29 号道路真实东西连接；不接入 Route46、吉花市、房屋和 Ferry 前封闭其他可越界入口。
3. 补齐 Header 描述符、活动槽位及地图数据 Bank，一次性解除 `NUM_JOHTO_ACTIVE_MAPS == 0` 门禁，并检查 Wram/SRAM 身份一致性。
4. 必须用户本地编译红蓝与测试构建，实测新旧档/正常关都地图，再在专用测试入口验证进出地图、东西两方向、边缘走路和存档恢复。

## 验收边界

当前仅预接入原版字节数据及源描述记录，并未开放进入若叶镇。成功链接不代表地图已可玩。
本环境不编译 ROM、不执行 Git 提交。

## P2-005B / REG-5.62.217 / TEST-224 — 图块集表和加载器迁移

- 实测前置 MAP（`all_maps(7).zip`）：正式红蓝 ROM0 各 824B，Bank $03 只剩 6B；Bank $43 包含 4192B 地图运行资源且剩余 12192B。
- 原 `LoadTilesetHeader` + `DungeonTilesets` + `Tilesets` 原位于 Bank $03，一并迁入 Bank $43 固定 ROMX SECTION。调用方仅通过 `predef LoadTilesetHeader`，`PredefPointers` 使用 `BANK(LoadTilesetHeader)` 自动取正确 Bank；不变更关都现有调用路径。
- 保留原 28 项关都图块集记录及 ID 不变，新增 `JOHTO_PILOT` ID 28 的 12B 行；GFX、Blockset、Collision 指针同在 Bank $43，Collision 对照表 7B，并在运行描述符登记新 Tileset ID。
- 这是**图块集资源注册**，不是地图接入：`NUM_JOHTO_ACTIVE_MAPS` 仍为 0，Header 描述符仍空，关都地图身份及旧地图表、Warp、地图碰撞、存档不改。
- 本阶段风险：通用 `predef LoadTilesetHeader` 的 Bank 改为 $43。请用户在本地红蓝编译查看 Bank $03 / $43 和 ROM0 空闲，进入关都室外、PC 中心、房屋、山洞各一次，验证 tileset/进出地图无异常。
- 仍不可进入城都；下一阶段为 Region map loader/可控入口/边缘连接与围栏，需要成套实现并单独游戏实测。当前环境未编译 ROM，也未 Git Commit。

## P2-005C / REG-5.62.218 / TEST-225 — 地区 Header 分派与候选头

- P2-005B 通用图块集搬迁已由用户实测验证：普通房屋、PC 中心、山洞进出及存读档均正常。
- 在 `LoadMapHeader` 及 `SwitchToMapRomBank` 增加**仅对 `$FC` 且地区/稳定 ID 有效**的分派逻辑；其它全部关都地图沿原 P1b 查表执行。
- `$FC` 调用 P2-002 `ResolveJohtoHeaderDescriptor`，从 D/HL 读取实际 Header Bank/地址，不依赖跨 Bank 返回 A/标志位。解析失败立即 SoftReset，绝不能读 Bank0 的零地址。关都路径不调用地区新逻辑。
- 对 `$FC` 不执行仅适用于旧地图编号的 `MarkTownVisitedAndLoadMissableObjects`，避免越界索引；真正的城都访问标记稍后独立实现。
- 两张 Gen1 结构的 Header 候选数据、空事件表均存入与地图块一致的 Bank `$43`。连接/建筑入口/NPC 等仍暂禁用。`JohtoHeaderDescriptors` **仍为空**、222 ID 表仍全部无效、`NUM_JOHTO_ACTIVE_MAPS` 仍为 0；因此候选 Header 不能从游戏中加载或进入。
- 这批只是加载入口与 Header 格式的底座，不代表城都已可玩。后续需成套补齐东西双向连接、门房/河边防越界、Music/Wild/TownMap 分派、Sprites/Objects，以及用 `$FC` 替代所有旧编号后，才激活地图槽位。
- 涉及 ROM0 的地图 Header/Bank 分派，因此本批需检查新 MAP 中 ROM0 空闲和 Bank `$43` 的两张 Header，建议用户复测一次常规关都地图切换和存读档。禁止将 `$FC` 写入旧地图存档尝试强行进入。
- 本批未自行编译 ROM，未执行 Git Commit/Push。

## P2-006 / PAL-5.62.219 — 城都图块集调色板越界修复（待构建与实机验收）

- 在 `color/data/map_palette_sets.asm` 为已注册的 ID 28 添加对应的 8B 户外配色组合；原有 28 行不变。
- 从参考分支原样导入 `color/tilesets/johto.asm` 的 96 项图块配色，并登记进 `MapPaletteAssignments` 第 29 行；修复之前读到相邻 `RoofPalettes` 的越界行为。
- 新增两张表的编译期长度断言，预防后续注册图块集却遗漏调色板数据。
- 只修配色表，不启用城都地图，不恢复 B+SELECT 临时入口，不变更稳定 ID、Warp、存档或原始 Gold/运行地图块。
- P2-005D 截图中的花屏现象尚不能仅凭静态修正宣称全部消失；待首次可安全进入若叶镇时实机复查图形、碰撞和边界。
- 本轮不由 AI 编译 ROM 或执行 Git Commit/Push。

## P2-006 清理边界 / PAL-5.62.219 / TEST-226（2026-10-27）

- 本次用户新上传的主项目源码中已经有 P2-006 的 8B `MapPaletteSets`、96B `MapPaletteAssignments` 城都行与两处编译期表长断言；不得重复叠加交接包中的 P2-006 增量或 P1→P2-006 累计补丁。
- 导出记录的 HEAD 为 `7c3040b601a221419a50c9bcf572ab2446b6385c`，工作区仍累计 P2-001～P2-006。导出附带正式 Red/Blue TEST-226 MAP；两图 ROM0 均余 753B，Bank $43 均余 11690B，P2-005C 候选 Header 符号仍存在；不把自动导出 MAP 当成本轮自行编译实测。
- 当前 `NUM_JOHTO_ACTIVE_MAPS` 仍为 0，稳定槽位表与 Header 描述符仍拒绝进入城都。P2-005D 的花屏入口和 B+SELECT 临时方案已经撤销；P2-006 仅修 Palette 表越界，尚未对可进入地图做实机验收。
- 下阶段**先做好完整可运行的若叶镇和 29 号道路双向链路**（地图连接条带/视野、碰撞、Warp、NPC/Objects、地区/存读档、Music/Wild/TownMap）。成套审核后再增加活动槽位并交给用户实际进入测试；不要在仅有候选 Header 时强行激活地图。
- 本轮是单提交文档收口，不改 ASM、资源或游戏内版本；用户最小验收以正式红蓝编译及新 MAP 核对为主，四目标 ROM、首次城都实机及 P2-006 花屏修复效果未在本轮确认。
