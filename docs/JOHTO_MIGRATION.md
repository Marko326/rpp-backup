# 城都地图移植：阶段计划与长期技术记录

> **唯一维护入口（从 P4-005 起）**：后续阶段、规则补充和验收记录均追加或更新在此文件，不再按 PAL / P4 子版本新建文档。历史 8 份 `JOHTO_MIGRATION_P*.md` 原文收录在下方归档，原文件删除；历史文字是**当时状态**，不覆盖本文件的最新结论。

## 最新进度与范围（P4-DOC-007 / PAL-5.62.230 验收收口）

- 主分支导出 Git 基线：`8c1789757f529de6eeb43de17b9b2d3e3eb8646a`，分支 `常规功能备份`。该 HEAD 提交了 P3 首批地图；P4-001～P4-006 均为此 HEAD 之后尚未提交的累计开发修改。已应用 P4-006 的源码是清理增量前置状态；没有新的已提交项目 ZIP，不能推断新 HEAD。
- 固定新编号 **0 若叶镇 / 1 号道路29 / 2 吉花市** 已激活；其他已预分配城都 ID 暂未激活。绝不启用旧城都 `$E7/$F4/$CE` 地图号兼容路径。
- **用户已验收**：吉花市经29号道路往返可走，P4-004 后飞行及普通地图当前位置显示正常，P4-006 Bike Song Off 上下车音乐不重播；此前已反馈轮船、跳崖、人物和 Town Map 配色正常。**待本机独立复核**：清理后正式 Red/Blue 新构建/MAP、完整存读档及关都回归；不把旧 MAP 当成最新构建证明。
- **P4-006 仅修骑车音乐行为**：Bike Song = Off 时，不论 RBY / GSC / Random 音乐模式，从背包或 SELECT 上车、下车均不调用 `PlayDefaultMusic`，当前曲目及播放进度继续保持。Bike Song = On 时保留原有骑行曲切换；实际换地图、飞行、冲浪等仍走原系统。P4-005 已加入的 Bike Song 选项保留原存档 bit4，不加新状态字段。`TEST-231` 不变。
- 此项目仍**只做地图**：不主动接入 Gold 剧情、真正 NPC 脚本、草地遇敌、宝可梦或昼夜。29号道路四名占位 NPC 仍非金版原角色。

## 后续固定小批次

1. **本次 P4 收口**：用户已确认 Bike Song 修复与飞行、吉花市主路径；仅收口文档，不改已验收的 ASM/资源及游戏版本。提交前需用户对清理后源码重新构建正式红蓝并检查对应新 MAP；其余音乐模式组合和存读档／关都回归保留为必要时的后续抽查。
2. **P5 地表路线**：30号道路（ID3）—31号道路（ID4）—桔梗市（ID5），按真实地图连接分成 1～3 张相邻地图的小批次；开放北口前移除吉花市临时封闭地块，验证连接/视野条带/可飞落点安全门禁。
3. **P6 后续路径**：向 32号道路、联合洞窟、33号道路、桧皮镇、桐树林、34号道路及满金市延伸；必要门房/洞穴随道路接入，非必要内部地图可后置。
4. **P7 其余区域**：按可走路线继续拓展其它城镇、道路、水域与关键通路，每次只接可安全往返的少量地图。
5. **P8 地图专项验收**：逐一核对 222 个固定 ID 的资源/Header/连接/碰撞/音乐/Town Map/Fly/存档，不把“已分配编号”当作“已可玩”。NPC、剧情和野怪属于独立后续阶段。

## 长期项目红线

- 新图必须使用 `region + stable local ID`，并验证活动槽位、Bank/Header/尺寸、连接偏移、碰撞、Warp、玩家可达边界及画面预览；`ID ≥ 8` 的名字牌临时编码限制必须先解决。
- ROM0 紧张，新增较大逻辑优先 ROMX；每批检查实际重新链接的红蓝 MAP。助手只做静态审查与补丁验证，不自行编译或提交。
- 飞行目标须同时满足**正式活动地图已启用、可落地、到访已解锁**，不可因为地图上可浏览而开放未接入城镇。
- 开发阶段只有增量/HEAD 全量两份互斥补丁（单 ZIP），不写 Git 日志；用户明确验收并要求清理时才按是否修改离线工具选三件套或五件套。只有更改测试功能才升 TEST 版本号。
- 一切后续 Johto 开发记录只维护本文件的“最新进度、待办和必要原理”；**不再创建每版独立的阶段 MD**。需永久保存的历史附录保留，但不复制同一段验收说明到多个地方。

---

## 历史资料附录（原文保留，仅供追溯；里面的待验结论不代表当前状态）

### 归档：`JOHTO_MIGRATION_P1_ROM0.md`

# ROM-5.62.211 / TEST-218：P1 ROM 扩容与 ROM0 迁表收口

## 功能范围

- `main.asm` 在 Bank `$7F:$7FFF` 设置容量锚点，扩展 ROM 至 2MB；保持原 MBC3、SRAM 与 Makefile 设置。
- 关都 `MapHeaderPointers` 的 248 项（496B）从 ROM0 移至 Bank `$40`，`GetKantoMapHeaderPointer` 使用 `E` 传地图编号，返回地图 Header 地址 `HL`。此处不能改用 `A` 传参，因为跨 Bank 调用会覆盖 `A`。
- 关都指针表的顺序与内容保持不变；原 Warp、地图连接、地区身份、存档与战斗逻辑不变。本阶段尚未引入城都地图。
- 正式/测试版本已分别更新为 `ROM-5.62.211`、`TEST-218`；此次清理仅更新维护文档，不再修改 ASM。

## MAP 验收

| 项目 | 改动前 | 正式红版 | 正式蓝版 |
|---|---:|---:|---:|
| ROM0 空闲 | 319B (`$013F`) | 824B (`$0338`) | 824B (`$0338`) |
| `MapHeaderPointers` | ROM0 | Bank `$40:$4000–$41EF` | Bank `$40:$4000–$41EF` |
| 跨 Bank 查表例程 | 无 | Bank `$40:$41F0–$41FB` | Bank `$40:$41F0–$41FB` |
| Bank `$7F:$7FFF` 容量锚点 | 无 | 存在 | 存在 |

- 本次数据来自后续提供的 `all_maps(1).zip` 中 `patches/rppred.map` 与 `patches/rppblue.map`，不是根据历史版本推算。
- 同包内 `buildRB/pokered.map`、`buildRB/pokeblue.map` 是另一组布局，不作为 P1 合并后的验收对象。
- 正式红蓝 MAP 对应 ROM0 空闲净增 **505B**，≥800B 的第一阶段目标达到。
- 当前 MAP 同时显示 WRAM0 余量 0B、WRAMX #1 余量 1B；新增城都运行态字段前必须另外规划 RAM。

## 运行验证与保留边界

- 已收到的运行确认：宝可梦中心、山洞、普通房屋的进出和存读档正常。仅记录这些已确认的路径。
- 尚未单独收到 Fly、跨地图边界、道馆/港口及独立测试 Red/Blue 对应 MAP 的完整验收；没有 ROM 二进制供独立核对文件长度/头部容量码。不能将正式红蓝 MAP 合格扩大为四构建全部验收。
- 项目源码的迁表 248 项内容不变，`MapHeaderPointers` 唯一 INCLUDE、Bank 切换 ABI 和补丁回放由静态审查确认，不等于运行全部路径通过。
- 本环境不执行 RGBDS 编译、ROM 链接、模拟器实测或 Git Commit/Push。

## 清理补丁前置

- 开发版：`TEST217_ROM0_P1_001_incremental_from_TEST217.patch`，对 `TEST-217.zip` 的干净导出 HEAD `486c89c4a032473306267e95d5865149fc0b12a6` 应用后即为清理增量的前置状态。
- 正式清理增量：在上述 P1-001 已应用的状态上更新本项目维护文档。
- 累计全量：从上述干净 HEAD 直接到 P1 清理最终状态；**全量与增量不能叠加应用**。
- 后续 P2 才开始城都稳定 ID、活动槽位与地图功能移植；P1 不引入金版地图数据。

---

### 归档：`JOHTO_MIGRATION_P2_HEADER_RESOLVER.md`

# P2-002 — 地区 Header/Bank 安全解析接口（开发候选）

## 本轮实现

- Bank `$41` 新增 `ResolveJohtoHeaderDescriptor`：输入 `D=region` 与 `E=stable_local_id`；先验证地区是城都，再以 P2-001 稳定 ID→活动槽位查表，之后通过 **16 位** `slot×3` 访问 `[Header 低字节, 高字节, ROM Bank]` 单一描述符。
- 查询有效时返回 `E=active_slot`、`D=header_bank`、`HL=header_ptr`；非法地区、未知编号、未激活编号或无效槽位返回 `E=$FF, D=0, HL=0`。`callab` 会覆盖 A/标志，因此调用方只使用 D/E/HL，且需在访问 `[HL]` 前自行切换到 D 指定的 ROM Bank。
- 描述符表目前 **0 项**，`NUM_JOHTO_ACTIVE_MAPS=0`，与 P2-001 的活动槽位表严格一致。编译期断言：表长必须等于 `活动地图数×3`；任何地图登记都应一次性补齐指针/Bank、活动槽位、地图 Header 与其它运行资源。
- 不挂接现有 `LoadMapHeader`、Warp、Fly 或存档读写路径；关都 Header 和 P1 的跨 Bank 查表未修改；不增加 WRAM、SRAM 或存档字段。

## 不得照搬的地区存档地址冲突

在金银参考分支，`wCurRegion`～`wJohtoFlySelectedLocalID` 用 `$D7A4–$D7AB` 等字节。但 **TEST-217** 在同一范围已有 `wRegionalDexSeenExtra` (6B, `$D7A4–$D7A9`) 和 `wRegionalDexOwnedLast` (2B, `$D7AA–$D7AB`)，且这些数据处于主存档块。不得改别名、覆盖原数据或增加 `ds` 挤压 WRAM 布局。

另外主项目原有 WRAM0 空闲为 0B、WRAMX bank 1 只余 1B，因此不能直接新增 4–8B 持久地区字段。首次启用城都地图之前必须设计不冲突的 RAM 生命周期/备用 bank 和版本化存档方案（含老存档辨别和异常恢复），并单独验收。当前不引入或读写无效的地区 magic marker。

## 后续接入门禁

1. 安全的地区身份与存档载体先独立审核，不能将稳定 local ID 当作 `wCurMap` 旧地图编号，也不能使用旧城都 `$E7/$F4/$0B` 别名。
2. 第一张城都地图导入时同时登记完整 Header、Bank、Tileset、Object、Warp、连接、脚本、音乐、Town Map 等；描述符行和活动槽位更新必须保持一致。
3. 只有注册地图准备就绪后，才允许将当前未调用的解析接口接入实际 `LoadMapHeader`。对 `$FF` 的失败回退必须发生在数据解引用前。

## 当前验证范围

静态源代码检查与补丁正反应用由交付方完成。主项目正常运行链仍与 P2-001 一致。`all_maps(2).zip` 两份正式红蓝 MAP 证明的是 **P2-001** 的 ROM0 824B、Bank `$41` 表布局，**不是本轮 P2-002 的链接结果**。新增例程需用户重新编译链接、查看 MAP；尚没有新的地图可进行专项游戏测试。

---

### 归档：`JOHTO_MIGRATION_P2_IDS.md`

# REG-5.62.212 / TEST-219 — P2-001: 城都稳定 ID 底座（历史开发阶段）

## 本轮完成

- 以 P1 已提交的 ROM 扩容/关都 Header 迁移源码为起点，登记 `(region, stable_local_id)` 的两个地区和全部 **222 个**城都地图稳定 local ID（0–221）。编号与金银参考项目后期冻结表、Gold 原始组号交叉核对；Kanto `mapconst` 完全保留。
- 新建 Bank `$41` 的 256B `JohtoStableIDToActiveSlot`、`GetJohtoActiveSlot`。16 位寻址，不因 8 位左移越界；未激活／非法 ID 一律返回 `$FF`。
- **当前活动地图数为 0**，并带编译期 ASSERT；本轮没有导入任何城都地图，未使用 `$E7`、`$F4`、`$0B` 等旧编号作城都身份，也没有设置 `$FC` 共享句柄或修改 Warp。
- 无新增 WRAM、存档字段或原有运行入口；不会改变关都原始地图查表、战斗、存读档与港口流程。正式标识 `REG-5.62.212`，测试 `TEST-219`。

## 查表 ABI 与门禁

`GetJohtoActiveSlot`: 输入 `E=stable_local_id`，输出 `E=active_slot / $FF`；保留 `BC/HL/D`，`A/flags` 不保证。通过 `callab` 跨 Bank 调用时只能读取 `E` 的结果。任何消费者必须先检查 `$FF`，然后才允许 2B/4B 表的 16 位偏移计算；不能把稳定 ID 当作密集数组下标。

| 输入 ID | 身份登记 | 当前活动槽位 | 本轮结果 |
|---|---|---|---|
| 0 / 1 / 2 | 若叶镇 / 29号路 / 吉花市 | 未启用 | `$FF` |
| 21 / 22 | 37号路 / 缘朱市 | 未启用 | `$FF` |
| 62 / 221 | 东线门房 / 殿堂 | 未启用 | `$FF` |
| 222 / 254 / 255 | 未分配或非法 | 无 | `$FF` |

## 下一阶段 P2-002 / P3

1. 将地图运行身份、存档预留字节、`$FC` 引擎句柄及失败回退统一设计；先核对现有 RAM 镜像和存档兼容；禁止直接复制参考分支早期 `LegacyMapIDToRegionKey` 的旧城都别名。
2. 先建 `region+local`→Header/Bank 的稳定接口及坏目标防护，再逐一打通 Warp、连接、音乐、Town Map、Fly 和存档恢复。
3. 首次接地图时，只有地图的完整运行资源和所有下游表项一起登记后，才移除 `NUM_JOHTO_ACTIVE_MAPS == 0` 门禁、将映射中的单个 `$FF` 换成新活跃槽位。

## 验证边界

已做源码静态检查、编号连续性核对、生成的补丁正反应用/逐字节检查；**本环境没有编译 ROM**。请在本地构建正式红蓝、测试红蓝四目标并提供 MAP，确认 ROM0 不倒退、Bank `$41` 表存在、其他固定 Bank 未溢出。地图进出/Fly/存读档沿用 P1 已报告范围，不可视为对 P2 新 ROM 的独立实测。

---

### 归档：`JOHTO_MIGRATION_P2_PILOT_RESOURCES.md`

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

---

### 归档：`JOHTO_MIGRATION_P2_REGION_STATE.md`

# P2-003 — 地区运行身份与旧存档兼容（开发待验）

## 本轮落地

- 地区身份采用 `(region, stable local ID)`，关都 `region=0`、城都 `region=1`。城都引擎句柄 `$FC` 只代表未来的载入通道，不作为地图身份存档，也没有为 `$E7/$F4/$0B` 建立旧城都别名。
- 从 `wMainDataStart..wMainDataEnd` 中六个未命名、源码未引用的已有保存字节复用：`$D79A`、`$D7B3`、`$D7B5`、`$D7C2`、`$D7C5`、`$D7C6`，分别存 magic0、magic1、current region、current ID、last region、last ID。此前旧注释称 unused，本轮静态检索未发现其它显式引用。源数据长度不变，其他 WRAM 地址不移动。
- **严格不碰** `$D7A4–$D7AB` 的地区图鉴资料，也不占用 `$D7A3`（道具例程用作临时字节）。
- 新游戏通过 `InitPlayerData` 初始化地区键为关都；读取主存档并通过原校验和后，验证两个标记、当前地区、城都运行句柄及已登记地图；缺标记／无效映射统一将身份校正为关都当前地图。关都 ID 按原 `wCurMap` 同步；上张地图为关都时按 `wLastMap` 同步。
- 存档前先校正 WRAM 地区键，再通过原有 `wMainData` 拷贝与校验和流程保存。不添加并行 SRAM 保存文件，也不修改原有 checksum 算法、SRAM Bank 或游戏存档长度。
- 在 Bank `$41` 实现 `JohtoResetRegionStateToKanto`、`JohtoValidateSavedRegionState`、`JohtoPrepareRegionStateForSave`、`JohtoGetPhysicalMapKey`。读取当前物理键时同步关都原有 `wCurMap`（以及关都前一地图 `wLastMap`），避免仅在存读档时更新造成中途切图返回旧值。跨 Bank 调用的地区键结果是 D/E，不依赖 A/进位标志。

## 当前限制与门禁

- 本阶段仍 **0 张已激活城都地图**。所有城都 local ID 在活动表里是 `$FF`，即便旧存档中碰巧有伪造的有效 magic，也不能激活城都。未修改 `LoadMapHeader`、Warp、Fly、Town Map、Sprite 或关都 `wCurMap` 的工作机制。
- 地区键已经在新游戏初始化、读档和存档时进行初始化／归一化；**这轮涉及存读档路径，应做最小旧档继续游戏→存档→读档、以及新开档初始化测试**，不能像 P2-001/002 一样完全省去实机验证。
- 城都首图接入前，必须补上显式的地区切换提交点（完整 Warp/地图 Header 资源成功解析后才更新地区身份），同步 LastRegion/LastLocalMapID，并验证 `$FC` 句柄切换和在城都存读档的落点；本轮不存在这些操作。
- 如果未来需要跨地区 `wLastMap` 镜像或存档故障回退，必须单独审计，而不是假设当前对旧关都状态的兼容逻辑已经覆盖将来城都的所有场景。

## 待用户构建检查

正式红、蓝以及能生成的测试 MAP：Bank `$41` 地区状态例程链接；ROM0 空闲与上轮 824B 对照；WRAMX/保存块边界不变。AI 未编译 ROM。补丁只能选增量或累计全量其中一份。

---

### 归档：`JOHTO_MIGRATION_P3_FIRST_PAIR.md`

## P3-DOC-006 / TEST-231 — 第一批地图正式收口（用户反馈已验收）

- 收口对象为 P3-001～P3-005，最新功能源码继续 `PAL-5.62.224 / TEST-231`。用户反馈若叶镇与29号道路正常进入，轮船进出、地图连接、跳崖、人物跨图显示正常；TEST-230 飞行成功，TEST-231 普通城都 Town Map 的截图/配色得到用户明确认可。**仅记录这些反馈，不能把截图解释成红蓝、所有飞行/UI、存读档逐项复测。**
- 新城都编号只激活 0/1；原分支 Ferry/UI/ledge/sprite/Town Map palette 行为适配新地区身份，不恢复旧 Johto 编号别名。45 个地标仅用于查看，当前城都 Fly 仅安全落地已激活若叶镇。
- 29号道路四名人物仍是参考分支替代 NPC（非 Gold 正式剧情），若叶镇三个测试贴图 NPC 已清理，渡轮水手保留。Wild、宝可梦、昼夜、剧情/捕捉教学和自行车仍故意不在本阶段启用，其他城都目的地未激活。
- 没有新增测试工具或审计脚本；保留 P3 运行 ASM 和地图数据原样，仅整理项目文档。基于 HEAD `495b7dc86ff6cbed5ed80483d1e8488dcb0e70bf` 的累计补丁覆盖 TEST-227～231；清理增量基于 TEST-231 已应用工作区。项目附带 MAP 仍为旧版，正式 Red/Blue 新编译/MAP 需要用户本地重做，不由 AI 构建 ROM。
- 下一批优先：接入下一张真实城都地图时复用通用到访解锁 Fly 方案、规范 NPC/野外事件的数据来源；不要为扩大列表先激活不存在的 Header。具体非地图机制继续后置。Git Commit/Push 由用户负责。

## P3-005 / PAL-5.62.224 / TEST-231 — 城都 Town Map 原分支配色修复（待验）

- [x] 从用户提供的 `NPC-5.62.243_金银分支` 原样恢复 `JohtoTownMapPals` 与 `JohtoTownMapPalAssignments`；此前地图使用关都调色板，故 Johto 图片绿／橙／蓝不协调。现在普通地图与 Fly 共用地区选择器，加载匹配的 RGB 颜色和 64 项 tile palette ID。
- [x] 原 `SetPal_TownMap` 银行 `$1C` 的表调用接口不变，但把完整调色板加载程序及两地区颜色数据迁到扩容 `ROMX`，不继续挤占 `$1C`。关都颜色字节未修改。地图 PNG、45 地标、飞行手段、地面物理地图新编号、轮船、跳崖、NPC 都不变。
- [ ] 用户实测 TEST-230 飞行若叶镇成功；此版仅修配色，红蓝实际 ROM/MAP 和手机截图仍需验收。优先测城都普通地图／Fly 色彩，再测关都地图显示、Fly 和一次轮船。AI 不编译 ROM。
- [ ] 暂不新增其它 Fly 目标：未激活的城镇不可安全飞入。未来应一次性迁移参考分支 11 个目的地的登记与到访解锁机制，同时新增目标必须检查已激活的 stable ID / Header / Warp，不能每张地图靠临时列表开放，更不能解锁未移植地图。此事项不作为首批 2 地图提交的前置条件。
- [ ] 城都自行车白名单尚未开放，本轮不扩围。暂不涉及野生遭遇、宝可梦、昼夜或剧情。
- 本轮开发补丁增量 TEST-230→231、全量 Git 导出 HEAD `495b7dc86ff6cbed5ed80483d1e8488dcb0e70bf`→231 互斥使用。若用户验收色彩 OK，应开始首批地图正式清理三件套，不再加新功能。

## P3-004 / PAL-5.62.223 / TEST-230 — 城都地图浏览与若叶镇飞行（开发待验）

- [x] 读取旧 NPC-5.62.243 的 Gold 45 个城都地标表与名称，放入扩容 ROMX；普通城都 Town Map 可遍历全部地标，无需将其错误映射成活动地图 ID。
- [x] 保留若叶镇=稳定 local ID 0、29 号道路=稳定 local ID 1 的玩家位置；只给已开放的若叶镇开放 Fly 目标，Fly 选择与物理地图身份分离，使用 Fly-only `$FD`，不采用旧城都地图编号。
- [x] 复用现有 Johto 地图图形、Kanto Fly 用户图标及 Fly 动画交接；关都 Fly 选择逻辑不变。金版其它地点可看地图，但未开放 Fly／Warp。
- [x] 不修改 NPC/剧情、野生遇敌、宝可梦、昼夜及骑行规则；29 号道路的替代 NPC 保持原样，留待后续正式 NPC 批次。
- [ ] 用户须编译正式红蓝和对应 MAP；验证城都地图 45 个地点上下翻页、若叶镇/29 号道路玩家标记、Kanto 地图未改、持有飞行宝可梦且有徽章时从29号道路飞回若叶镇，并确认存读档/渡轮不回归。AI 未编译、未在手机实测。
- [ ] 本版仅开发补丁（增量 TEST-229→230；全量 Git HEAD `495b7dc8`→230），不生成正式清理三件套、不 Commit/Push。

# P3-003 / PAL-5.62.222 / TEST-229 — Johto outdoor NPC tile cache repair (pending user test)

- Development increment based on **P3-002 / TEST-228** (not the clean Git HEAD). Full patch remains based on confirmed `495b7dc86ff6cbed5ed80483d1e8488dcb0e70bf` P2 HEAD. Apply exactly one patch.
- Restores the reference branch's `FLY-5.62.144` outdoor NPC sprite-set strategy, but triggers on current Johto tileset `JOHTO_PILOT` (28), **not** old map numbers `$E7/$F4`: both current active new local IDs 0/1 share sprite set $0b across seamless east/west connection. No old Johto map IDs or aliases are re-enabled. Kanto sprite sets / old map numbering remain unchanged.
- `SpriteSets` appends the exact 11-sprite outdoor set from the reference (last two are four-tile items). The engine's existing `wSpriteSetID` cache and `wFontLoaded` forced reload remain unchanged. The current two maps' people sprite IDs are covered by the set; unlike the prior per-map indoor-style dynamic loading, the same outdoor VRAM layout is retained on both connected maps.
- **Temporary sprite diagnostics**: remove the three `GAMBLER/BUG_CATCHER/LASS` visual test NPCs in New Bark. Keep ferry sailor and all ferry warp coordinates and logic exactly as P3-002. Route 29 still uses reference's Gen 1 visual stand-ins at Gold NPC coordinates; these are not final Gold sprites/scripts; don't describe them as Gold-faithful NPCs. Text for future town NPCs is retained as non-reachable placeholder until real Gold art/events are migrated.
- Bike availability has **not** been newly enabled by this patch (`BikeRidingTilesets` is unchanged). Do not claim cycling boundary tested until a later separate enablement/verification. No changes to event scripts, ledges, sprite graphics files or Gold source data.
- No AI ROM compile/link and no phone test performed. User should build Red and Blue, check newly generated MAP for bank $05 and ROM0 free space, and re-enter New Bark→Route 29→New Bark several times on foot, including NPC facing animation, ferry, save/Continue; compare ordinary Kanto outside sprites. If biking was already externally enabled, additionally repeat the transition on bike. If the MAP/link or VRAM display fails, stop and return the exact error and screenshot.

---

# P3-001 / PAL-5.62.220 / TEST-227 — 首批若叶镇、29 号道路运行候选（待用户验收）

## 准确基线

- 用户提供的 2026-10-27 主项目 ZIP 是 **干净 HEAD `495b7dc86ff6cbed5ed80483d1e8488dcb0e70bf`**，`PAL-5.62.219 / TEST-226`；本轮不从旧 P1/P2 补丁重新开始。
- 原有 222 个 Johto 稳定 local ID 不重编号；本轮仅将 0（若叶镇）和 1（29 号道路）映射为有效活动槽位。关都全部地图常量不变；不启用 `$E7/$F4` 老编号别名。

## 运行改动

- 活动槽位与 Header 描述符一一对应，Bank `$43` 的两张 Header/运行块/对象数据一起开放；Bank `$42` 的 Gold 原始块与连接表仍原样保存。
- 共用引擎 handle `$FC` 只用于运行时，`wCurRegion + wCurLocalMapID` 是唯一可靠物理身份；东西双向连接由稳定 ID + 方向查询，不把 `$FC` 存作真实城都 ID。
- 若叶镇西门→29 号道路东门，及反向连接启用；其余未登记邻居保持封闭。两张地图先用零 NPC、最少标牌，未导入旧分支多余的旧号脚本。
- 增加轮船的 New Bark / Go Home 菜单选择和明确地区目标，配合若叶镇码头踏板入口，尝试达成关都↔若叶镇双向往返。
- 防止原野怪遇敌表以 `$FC` 越界索引。新地图载入时经独立 ROMX 助手处理音乐/保存地区身份/Name Sign/Town Map；Johto Fly 与 Teleport 暂不开放。
- **必要的拥挤 Bank 调整**：将原本 Bank `$03` 的 `IsPlayerStandingOnDoorTileOrWarpTile` 和其同 bank WarpTileID 表**一起**移至扩容 Bank `$41`（原有调用点均是 `callab/callba`）；新增 Johto Tileset 28 的 Warp tile `$06` 表项，避免越界表读取。将 Kanto 原版 Town Map 360 字节 tilemap 单独迁至 Bank `$45`，复用现有 `FarCopyData2`，为 Bank `$1C` 新的城都浏览分支腾空间。
- 两个区域使用 Gold 派生的 runtime blocks / 同一个 Johto Tileset 28。Town Map 新图像/双条目仅在来自城都的普通地图浏览模式下使用，Fly 仍沿用关都旧列表。

## 验证和风险

- 本轮只做源码/引用/数据结构/地图长度/补丁正反和文件字节检查，不编译/链接 ROM，不进行手机实机测试，也不运行 Git Commit/Push。
- **重要**：用户必须本地编译正式红蓝，再查看新 MAP 中 ROM0、Bank `$03`、`$1C`、`$35`、`$38`、`$41`、`$42`、`$43`、`$45` 是否可链接；基线 MAP 空间不是本次目标版 MAP。若编译失败，必须停止进行实机验证，回传准确报错和新 MAP。
- **最小手机验收**：旧关都正常开档/存档，枯叶市轮船 → 若叶镇正常显示/不花屏，进入 29 号道路后原路返回；若叶镇轮船返回枯叶，再回来；分别在城都和关都存读档，试 Town Map/标牌/显示音乐/脚下碰撞，并尝试边缘逐格行走确认树林残留；红蓝都应测。
- 29 号道路其他邻居、门房、建筑室内、NPC/训练师、遇敌、Fly/Teleport 及全城都地图并未实现。首次手机跑图前，**不能宣称双向渡轮、连接或乱码问题已经解决**；出现黑屏/花屏或存档异常请提供画面、具体位置、目标 ROM 的 MAP 和错误日志。

## 开发交付说明

- 用户未要求正式清理三件套：仅交付两个等价起点的补丁（从当前干净 HEAD 到 P3-001 的增量、从本次确认 HEAD 到 P3-001 的全量），**二选一**，勿叠加。
- 只有用户明确验收后要求清理时才做提交记录；本轮无独立工具/审计脚本改动。


## P3-002 / PAL-5.62.221 / TEST-228 — 恢复旧参考分支表现（待用户验收）

- 已收到用户视频：TEST-227 若叶镇、29 号道路能进入、基本行走无明显问题；用户指出菜单 `New Bark Pass` 超框、船岸场景和 Route29 跳崖缺失。视频和口述不代表所有回归通过。
- **名称按 NPC-5.62.243 恢复**：`text/item_names.asm` 的渡轮目标可见文字从 `New Bark Pass` 恢复为 `New Bark`，保留仅供渡轮菜单使用的伪物品 ID `NEW_BARK_PASS`，不新增或改动背包道具。
- **船的进出位置保持与旧参考分支一致**：若叶镇地图对象恢复原始渡轮 Warp `(y=$08,x=$11) -> INSIDE_FERRY warp 0`，原来的水手 NPC `(x=$10,y=$07)` 和三名角色、四块标牌及原文逐条移入。原有 InsideFerry 的两条船出口仍由原脚本更新；跨地区目的地只把旧 `$E7` 改为稳定 `(JOHTO, local 0)`，并保留现有显式返回枯叶码头分派。旧分支对应 Warp 坐标与 P3-001 原本相同，本次修复的主要是缺失的场景 NPC、标牌与对白，不伪称修改了本来相同的坐标。
- **29 号道路**：迁移旧分支 4 名 NPC、2 个路牌及原文，并在稳定 local ID 1 的 `JOHTO_PILOT` 图块集开启旧版 `Route29` 跳崖 tile-pair 判定（左/右/下），不修改原 `HandleLedges` 的动画、声音或手感。图块集、tile collision 和 runtime map blocks 与参考分支逐字节一致；仅地图身份的判定改为 `(MAP_REGION_JOHTO, JOHTO_ROUTE_29_LOCAL_ID)`。
- **Bank 安全**：旧 Bank $06 的 MAP 仅剩 1B，完整 `HandleLedges`（包含阴影动画数据）整体迁到扩容 Bank $43；现有 HOME 调用 `callba HandleLedges` 不变，不新增 ROM0 代码。
- **阶段限制**：Route29 北门的门房尚未激活，原参考分支那条 Warp 不可盲目接回；保留 0 个北门 Warp，待该地图激活后一并迁移。若叶镇四栋屋子的门仍关闭；旧分支导游文本提及吉花市开放，但该相邻地图本期未接入。禁止为了还原旧编号去启用 `$E7/$F4` 别名。
- **交付范围**：开发测试补丁两份（上一轮已应用 TEST-227 的增量、已确认 HEAD 495b7dc8 的累计全量）以及仅含两补丁的 ZIP。不编译 ROM／不造测试 MAP／不执行 Git Commit 或 Push。用户验收重点：渡轮菜单文字不超框、若叶镇原水手/入口与进出船、29 号道路正确的跳崖动作及地图连接。

---

### 归档：`JOHTO_MIGRATION_P4_CHERRYGROVE.md`

# P4-001 — 吉花市（Cherrygrove City）第一张扩展地图（开发待验）

- 基线：用户上传的干净 Git HEAD `8c1789757f529de6eeb43de17b9b2d3e3eb8646a`，正式 `PAL-5.62.224`，测试 `TEST-231`。
- 本版仅改正式地图功能，目标 `PAL-5.62.225`，**TEST 保持 TEST-231**。
- 新激活 stable local ID `2`，活动数从 2 到 3；未启用任何旧城都 mapconst 或旧 `$CE` 地图号。
- 从用户提供 Gold/旧参考分支完整复制吉花市 20×9 源图，原始资源不修改。运行地图仅将北边通 Route30 的首行通路 `(x=8,y=0)` 原道路块 `$01` 替换成森林边界块 `$05`，防止走进尚未激活的 ID3；开放 ID3 时必须恢复并另加 NORTH 连接。
- 29号道路新加 WEST → 吉花市（ID2），吉花市 EAST → 29号道路（ID1）；两个 Header 使用原 RBY 的 11B 连接记录，并由 `(region, stable local ID)` 动态分派。若叶镇原有两方向及轮船保持。
- 室外标牌保持旧参考坐标与无剧情文字；不开放房屋 Warp、NPC、教学、野怪、宝可梦、昼夜、携带物品或剧情。
- 城都普通 Town Map、Fly 地图玩家位置识别吉花市，但不会新增飞行目的地或可飞到未激活地图。骑行和通用到访 Fly 解锁按总计划下一小批处理。
- **未在本环境编译／链接／实机验收**。用户最小核验：正式红蓝编译、MAP/Bank、从枯叶船→若叶镇→29号道路→吉花市，东西往返、北口阻挡、四个标牌、Town Map 的 Cherrygrove City 玩家位置和旧城都两地图及轮船无回归。

---

### 归档：`JOHTO_MIGRATION_P4_FLY_BIKE.md`

# P4-002 / PAL-5.62.226 — Johto bike + stable-ID Fly registry (development candidate)

- Based on uncommitted P4-001 / PAL-5.62.225 applied after exported HEAD `8c1789757f529de6eeb43de17b9b2d3e3eb8646a`. TEST-231 remains unchanged; no test-specific functionality was edited.
- From NPC-5.62.243 reference: enables the existing RBY Bicycle permission for the single currently registered Johto outdoor tileset 28. Reuses the existing bike state, sprite and music paths; **does not** add bike items, event scripts or permission for indoor gates/caves.
- Predefines **11 Johto Fly destinations** in Gold/reference order with stable local IDs, original coordinates, landings and previously unused saved event bits. Entering a physically active Johto town (including Continue) marks its own visited event; other maps do not unlock cities. Fly menu additionally requires the ID in the current active-slot registry. No legacy `$E7/$F4/$CE` map ID is ever treated as a destination. New Bark=0 and Cherrygrove=2 are currently valid city destinations. The other nine become eligible only after their own physical map, walkable Fly landing, and bank/header/region identity have all been activated and verified.
- Uses existing saved event flag array for visited bits and renames exactly the former unused scratch byte after wBeatLorelei to persist selection across Fly transition; does not shift WRAM/SRAM data, and does not conflict with regional dex bytes at D7A4-D7AB. Fly selector `$FD` is never stored as a physical map ID.
- The native Johto town-visit record is written from `LoadMapHeader` when `wCurMap == JOHTO_RUNTIME_MAP_HANDLE`, independently of Kanto missable objects. The general Fly registry/controller stays in floating ROMX; Kanto Fly and the normal Town Map remain unchanged.
- NOT included: wild encounters, Pokemon species, capture tutorial/plot, day-night, new NPCs or map interiors. **No standalone map scripts from the old branch were copied** because no such script is necessary for biking or city visit flagging; old story scripts often depend on retired map IDs and must be adapted when that actual map is activated.
- Development candidate only. AI did not compile ROM, link or produce new MAP. User should compile Red/Blue and check bank slack and ROM0. On the phone: cycle on each of New Bark, Route29, Cherrygrove; bike across both transitions in each direction, dismount and save/Continue; enter New Bark and Cherrygrove and Fly from each to both towns, including after Continue; Kanto Fly/ordinary maps and ferry unchanged. Check that unregistered Fly destinations never appear. On compile/link or runtime failure stop and return complete errors/MAP.

## P4-003 / PAL-5.62.227 — Fly destination label-scope compile fix

- Corrected the table-end marker to a **local** `.end` label so all 11 `.name*` / `.warp*` labels remain scoped under `JohtoPilotFlyDestinations`. The previous global `JohtoPilotFlyDestinationsEnd:` caused 22 missing-symbol errors during compilation.
- No changes to the 11 registered destinations, physical local IDs, event bits, landing coordinates, biking, maps, or TEST-231. Still requires user-side Red/Blue build, MAP, and runtime acceptance; do not treat the structural check as a build.

## P4-004 / PAL-5.62.228 — Native Johto Fly visit-hook fix

- **Runtime root cause:** `home/overworld.asm` `LoadMapHeader` intentionally skips `MarkTownVisitedAndLoadMissableObjects` when the physical map is the Johto runtime handle `$FC`, to avoid indexing the Kanto missable object table with that selector. But P4-002 recorded Johto town visits only inside `MarkSpecialFlyLocationVisited`, called from that bypassed Kanto routine. Thus New Bark/Cherrygrove visit bits were never set, the Fly map could display a location, and `A` was silently rejected by `.isUnlocked`. P4-003 fixed only a separate label compile error; it did not fix the skipped hook.
- **Fix:** on the existing native Johto branch of `LoadMapHeader`, far-call `JohtoPilotRecordFlyVisit` immediately after region/ID validation. The original Kanto call remains on its own branch and is not invoked with `$FC`. This adds a small ROM0 branch/call; no data or ROMX tables are duplicated. The existing registered town/visited bit gate and 11-entry Fly registry are preserved without old mapconst aliases.
- **Current effective destinations:** New Bark (stable ID 0) and Cherrygrove (stable ID 2) can become selectable on map entry/reentry. Route 29 (stable ID 1) is not a Fly city. Inactive destinations remain blocked until fully activated and visited. `TEST-231` unchanged. No new tests, event scripts, wild encounters or day/night code.
- **Verification scope:** static control-flow audit confirms the old bypass and the repaired native hook, confirms preserved Kanto branch and 11-entry registry. This candidate has not been compiled/linked or tested in-game by the AI. User should apply only the incremental patch after P4-003, compile both Red/Blue and verify MAP/ROM0; walk across a Johto map boundary (or load a saved game) to trigger header load before attempting Fly, then fly between New Bark and Cherrygrove, save/reload and repeat, and verify Kanto Fly and ferry are unchanged.

---
