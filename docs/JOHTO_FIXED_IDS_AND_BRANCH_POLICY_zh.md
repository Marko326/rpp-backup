# 城都东西双线开发：全量固定地图ID、统一入口和无冲突合并规范（v1.1；已核 Gold 源码）

> **SPID-5.62.227 本轮清理状态（2026-10-20）**：共用 C 已在未提交工作区实现 `JohtoStableIDToActiveSlot` 256B 表、调用点判活和索引迁移。Gold 源下 744 项测试及主要静态审计已有通过记录；用户确认热修复后可编译、手机简测未发现问题，尚未提供此次链接的 MAP 和逐项手机回归明细。**运行地图仍仅激活 ID0–22；A/B 不得自行上线 ID23/62，分叉点须待用户完成 Git 提交并核实新 HEAD 后登记。** 本文后续原 `.225/.226` 时间线及“尚未实现”表述是历史基线，不代表 `.227` 当前源码。


> **文档类型：固定编号的审计合同与分线规范。`.227` 工作区已具备稀疏映射基础；本文件不是 ROM 链接、MAP 空间或逐项手机验收报告。**
>
> **历史核对基线（`.225` 阶段，非本轮 HEAD）：** 金银分支，Git HEAD `47915e4e3a536e7cfefee870254feefbaede99ac`，显示版本 `BANK-5.62.225`，当时用户 ZIP 表明源码干净、无未提交 Patch。依据：ZIP 的 `RPP_PROJECT_CONTEXT/03_PROJECT_REQUIREMENTS.txt`、`02_EXPORT_INFO.txt`、当前 ASM/工具 JSON、`patches/rppred.map`，以及随附 `BANK-5.62.225_Johto_Handoff(1).md` 和用户新提供的 `pokegold-master(1).zip`。
>
**Gold 源码交叉核验已完成：** 上传 `pokegold-master(1).zip` 的 SHA-256 为 `06c3724bb859b6f7946a528ab0b19ef03ae688959b3761e65cac8f633ed87d0c`；读取 `data/maps/maps.asm` 的 MapGroupPointers / MapGroup 表和 `constants/map_constants.asm` 的原版组号、组内号、宽高，得到 26 个组、368 张原始地图；与本规范 222 张 RPP 城都计划逐项对照，地图名及组名均相符，新增 Gold 原始编号和尺寸无错配。原版所有地形、Warp、脚本、碰撞及技能逻辑仍必须按地图单项审查，不能因此声称全部移植完成。

## 0. 直接执行的决定（先读）

**编号区别**：RPP `stable_local_id` 为城都地图永久身份，**不是** Gold 原版 `GROUP_*` / `MAP_*` 二元组。项目原有 Kanto 地图不得重新分配 RPP local ID。Gold 一共 368 张，其中 222 张纳入当前城都新增/已有计划，另外 146 张未纳入本次 Johto local ID 池（包括 9 张交接文档的关都参考）。完整原版 368 张在 `tools/johto_gold_map_reference.csv`，其余地图保留原有系统，不自动启用。

**源码实施状态（新增硬固化）**：固定编号已同时写入 `tools/johto_fixed_ids.csv` 与 `constants/johto_fixed_map_ids.asm`（后者已由 `constants/region_map_constants.asm` 正式 INCLUDE 到实际汇编入口），覆盖未来 201 张地图，已有 0–20 仍由原 ASM 常量维护；`Makefile` 的正常 ROM 对象编译带 `johto-id-preflight` 顺序门禁，统一发布审计同样强制检查。常量预留本身**不会扩容地图表、Warp 或存档**；现阶段 Route37 和 EcruteakCity 均已接入源码候选，`NUM_JOHTO_MAPS=23`；需用户编译和手机验收，其它未开发地图仍未激活。**稀疏 ID 运行时映射层尚未实施，东线 62 等跳号 ID 仍不得上线。**

**缘朱市 ID22 当前收口边界（ECRU-5.62.226，基线 BANK-5.62.225）：**用户反馈最新 Fly 目的地已正确；源码中 Fly 确认使用稳定目标 local ID，西口恢复 Gold 城市本体图块。但尚未接入 Route38 邻图及其门房，屏幕西缘暂显默认树林，不是原版门房外观验收通过；Surf、骑行、标志牌、存档及最新 MAP 仍需逐项用户复测。`SafariZoneBeta` 仅按用户指定从 Gold 素材扫描中明确排除（367/368 扫描），不能误报其已通过审计。稀疏 ID62 映射仍未实现，**本轮清理不等于东西线已经可以独立激活地图**。

1. **从现在到分线之前：只由共用 C 推进。`Route37` 固定 local ID `21 ($15)` 已接入候选并待用户完整实机验收；`EcruteakCity` 固定 local ID `22 ($16)` 也已接入源码候选，双方仍需用户 ROM/MAP 和实机验收。完成 **36↔37↔缘朱市** 双向通行、审计、用户编译及手机验收后，才创建东西两条线。不是等到浅葱、卡吉或烟墨才分。**
2. **冻结 222 个可纳入城都计划的地图 ID**：现有 21 + 共同起步 2 + 西线 39 + 东线 40 + 共用剩余 90 + 后期 30；9 个纯关都参考不挤占城都 ID。每个地图唯一、永久固定，详见第 9 节完整表；还额外划出 222～254 未分配保留位，`$FF` 禁止作为地图 ID。
3. **不能仅靠划号段就直接运行**：现在 ASM 是连续 local ID 索引表；为了允许东线 ID `62` 在西线 `23～61` 尚未上线时独立启用，分线前 C 必须落地第 2 节规定的“稳定 ID→紧凑活跃槽位”兼容层，连同越界保护/静态工具/实机测试全部验收。**此项当前未实现，不许在未改代码时直接启用高 ID。**
4. **合并频率按验收单元，不按攒够多少天**：A/B 每完成 **1 张户外地图或 1 座门房/1 个洞穴楼层** 就向 C 提交一次；每线最多留 **1 个可测试且未集成的任务**，超过 **2 个工作日**仍未集成必须同步并说明阻塞。公共修复当天可独立推送到两线；要不要正式 Git Commit/Push 始终由用户决定。
5. **公用代码只有 C 有最终写入权**。 A/B 不能为自己的地图自行补写共享表后互相覆盖。每次从相同验收过的 HEAD 创建短分支；集成顺序：公共修复 → 私有资源 → C 注册/开放接口 → 用户链接/MAP/手机。
6. **ID 永远区分四件事**：Gold MapGroup/地图名、城都物理 local ID、RPP 的旧版兼容单字节地图句柄、Town Map 地标/Fly/Warp 槽位。不能拿其中任意一种冒充另一种。

## 1. 源码已确认的硬边界

| 事项 | 当前证据 | 固定政策 |
|---|---|---|
| 既有地图 | `constants/region_map_constants.asm` 和 `tools/johto_native_maps.json` 都有 0–20 的 21 个实体 | 原编号与符号绝不重排、绝不复用 |
| 真正物理键 | `(wCurRegion,wCurLocalMapID)`；新城都共享旧引擎句柄 `REGION_NATIVE_MAP_SLOT=$FC` | 稳定 ID 保存在 local 字节，不能把 `$FC` 当物理 ID |
| 旧别名/转义 | `$FD` 当前作特定 Fly selector；`$FE` 为 `REGION_WARP_ESCAPE` 且在 Fly 选择场景复用；`$FF` 为 `LAST_MAP`/表结束标记 | **不**从 `$FC/$FD/$FE/$FF` 单字节句柄里分配新物理地图 |
| 当前登记结构 | `JohtoMapHeaderPointers/Banks/LegacyAliases/NativeMapSongBanks`、`JohtoNativeTownMapIndices/Entries`、`JohtoNativeGSCMusic`、屋顶组以及多种按 local ID 比较的流程 | 引入活跃槽位后必须同步调整所有调用者，不可只改一张表 |
| 已观察到的索引风险 | `LoadTownMapEntry` 原生 4 字节条目用 8 位 `add a; add a`；`GetJohtoNativeMapSong` 2 字节条目用 8 位 `add a` | 活跃槽位达到 64/128 时会有溢出风险；分线前一并改为正确 16 位偏移，并搜索其它同类路径 |
| 地标编号 | `NUM_JOHTO_TOWNMAP_ENTRIES=45`；浏览地标表已有 45 项 | **45 不是地图 ID 上限**；新增室内不直接扩充 45 个浏览地标，按 Gold 地标映射 |
| 容量 | 随附 MAP：ROM0 余量约 832B、最大连续约 818B；Bank `$01` 仅 11B；Bank `$40` 约 `$0E68`=3688B | Bank 不是永久固定编号池，新增 ROM 段需逐轮核 MAP；禁止向 `$01` 增代码 |
| 现有审计 | 导出日志写 676/676 单测和 22/22 活动连接；统一审计历史状态 `FAIL`，既存 `SafariZoneBeta` | 不写成本次重跑 PASS；不能屏蔽该已知失败 |

## 2. 一次性技术底座：让“不同固定 ID”真正可并行

### 2.1 为何直接分配 A=23、B=62 现在不能用

当前 `ResolveRegionMapHeader` 用 `cp NUM_JOHTO_MAPS` 判断 local ID 是否在已登记连续表中，接着直接 `ID×2` 查 Header；Town Map、音乐、屋顶等也有直接以 local ID 取行的路径。现有 `NUM_JOHTO_MAPS=23`。给 B 写成 ID=62 而中间没有实际 23..61 表项，会被拒绝或者读错行；把空位虚构成“已注册地图”又可能使 Warp、读档指向无效 ROM 地址。

### 2.2 **固定采用：物理 stable ID + 运行时紧凑 active_slot**

1. **物理 stable ID：**第 9 节 v1 登记的数字是玩家存档、Warp 目标、连接目标、区域碰撞和地图私有资源使用的永久身份。`wCurLocalMapID`/`wLastLocalMapID` 一律保存它；不改旧版 Kanto 编号/存档长度。
2. **运行时 active_slot：**内部分别登记当前真实已接入地图的紧凑槽位 `0…active_count−1`。现有 0～20 对应槽位 0～20；以后 **C 按真正集成成功的次序分配新槽位，不回收也不重排**，例如若 A 的 Route38EcruteakGate(ID23) 先上线，它可占 23 号槽位，B 的 Route42EcruteakGate(ID62) 下轮上线时占 24 号槽位。数字是示例，前提是 21、22 均先上线；固定 ID 永远仍是 62。
3. **256 字节 ID→槽位路由表（建议实现为 256 项）：**已启用 ID 映射到真实槽位；尚未做的合法保留 ID、未知 ID 一律 `$FF=INACTIVE`。不能将 `$FF` 当合法槽位。**不创建指向假 Header 的占位运行地图。**
4. **所有下游基于 local ID 的数组访问先过统一判活/映射接口**：Header 指针/Bank、legacy alias、RBY/GSC 音乐、Town Map 映射/4 字节条目、roof mapgroup、地图名称、Fly、连接/Warp 的目标合法性、存档恢复、地图碰撞及任何 local ID 连续性假设。能使用物理 ID 的定点相等判断继续保留稳定符号；必须转换的是“数组行索引”。
5. **区分数量常量**：例如 `NUM_JOHTO_ACTIVE_MAPS` 为紧凑表行数，`JOHTO_STABLE_ID_TABLE_SIZE=256` 为查找表范围；迁移旧 `NUM_JOHTO_MAPS` 的所有调用者与现有工具后，再定它的兼容定义。**不要只把 21 改成 222。** 旧审计若硬编码 ID=表行号，必须随结构更新，并新增错号故障注入。
6. **16 位偏移安全**：所有 2/4/N 字节步长计算及超界路径都重检；新 `ID=62`、`active_slot=64`、`128`、`221`、`254`、`255`、未启用 23/62、坏 Warp、坏存档、关都旧图等必须注入测试。判活失败严格 fail closed，避免错误进入任意地图或播放垃圾音乐。
7. **激活不能自动解锁游戏功能**：C 登记地图可用，并不代表 Cut/Surf/Fly、剧本、道馆、道具、NPC、屋顶和门口都开放；按现有 feature_status 与 Gold 合同逐项准入。

**实现顺序（不可跳）**：先保持旧 0～20 地图行为完全等价 → C 做映射层及对应所有调用点审计 → 用户构建 ROM/MAP、手机回归旧地图 → 37 号路/缘朱市共同基线（或者先接入 21/22 后再做映射层并一并回归）→ 双线分叉。推荐日常执行次序是先接 21、22，再在分叉前完成映射层的独立小变更，避免正在开发 Route37 时同时大改所有引擎入口。

**技术界限**：本文件是要实现的强制设计，不声称 ZIP 现有源码已经支持 sparse ID。实际改造须以真实源码审计和用户 ROM 测试来验收；如对存档兼容构成障碍，不得绕过检验直接采用虚假预留条目。

## 3. 编号池、维护权与新增地图原则

| 物理 ID 十进制 | 十六进制 | 固定责任 | 条目数 | 使用说明 |
|---:|---|---|---:|---|
| 0–20 | `$00–$14` | 已有基线，C 保护 | 21 | 已登记，不重排、禁止 A/B 私改原有入口 |
| **21–22** | **`$15–$16`** | **共用 C** | **2** | Route37、EcruteakCity，分叉前必做 |
| **23–61** | **`$17–$3D`** | **西线 A** | **39** | 西线地图及私有场景 |
| **62–101** | **`$3E–$65`** | **东线 B** | **40** | 东线 39 项 + Route29Route46Gate 1 项（改旧图入口由 C） |
| **102–191** | **`$66–$BF`** | **共用 C** | **90** | 旧城区房屋、自然公园、遗迹、跨区旧入口等 |
| **192–221** | **`$C0–$DD`** | **后期 C** | **30** | 联盟、通关及跨地区后期地图 |
| 222–254 | `$DE–$FE` | 统一保留，C 审批 | 33 | Gold 清单之外真实新增时走变更申请，默认未分配 |
| 255 | `$FF` | **禁止** | 1 | 现有列表终止/无效标记语义，不能作为运行地图 ID |

**冻结规则**：

- **同名唯一、编号唯一**：ID 不因路线提前/推迟、版本递增、提交顺序、场景未完成而变；某地图取消也保留弃用槽位，不立刻分给别的地图。
- 分配表以 Gold 原版英文地图名作为外部稳定键；源文件建议使用 `Johto<GoldMapName>`，实际 Header/脚本标签对照现有源码。对于已登记 0–20，保留源码原有 symbol，不按表格名称机械重命名。
- 西线 ID 不能给东线地图使用，反之亦然；C 旧图入口、门房连接两侧、共用全局引擎的唯一写入权不随 ID 所有权转移。
- 未来地图新增若不在 222 条计划内，由 C 先核 Gold/项目实际需求，再从 222–254 分配，增量更新规范版本，并通知两线。**不允许开发者任取 102 以上的“看着没用”编号。**
- 稳定 local ID 与 GSC 原版 MapGroup/MapNumber 不保证数值相等；用户遇到“同一个 Warp 0”不视为冲突，因为 Warp slot 是每张源地图的局部索引。

## 4. 公共冲突源一次性登记（谁能改什么）

| 冲突类别 | 具体文件或对象 | 唯一所有者/规则 | 验收触发 |
|---|---|---|---|
| **地图身份/指针/Bank** | `constants/region_map_constants.asm`、`data/johto_map_headers.asm`、`engine/overworld/region_map_lookup.asm`、StableID→active_slot 转换 | **C 独占**，A/B 只填地图资产登记申请；保留 0–20 | ID 唯一、存在位、连续活跃表、错误 ID fail-closed |
| **源码装配/Bank 安放** | `main.asm`、`home.asm`、`home/overworld.asm`、`home/region_map_bank.asm`、Section/BANK/INCLUDE、ABI | **C 独占**，A/B 不自行占公共固定 Bank，按每轮 MAP 判定 | 无 ROM0/ROMX 放置错误；Bank/HL/BC/Carry/返回合同保留 |
| **地图私有文件** | `maps/Johto<Name>.blk`、`data/mapHeaders/Johto<Name>.asm`、`data/mapObjects/Johto<Name>.asm`、`scripts/Johto<Name>.asm`、专属文本/图像 | **地图所有线**，不得触碰另一线名字；符号、路径全局不重名 | Gold 几何/Warps/事件/碰撞对照 |
| **旧图接口/缘朱东西门** | `JohtoEcruteakCity`、Route36 等已上线 mapObjects/连接/边缘、`Route29` 西端东线回流 | **C 独占**；A/B 提接口请求不私改旧图 | 双向、门毯 lane、自动一步、取消/掉头、视野补绘 |
| **门房/Warp** | `NativeRegionWarpTargets`、`ExplicitWarpRegionTargets`、门房入口和 `tools/johto_door_contracts.json` | **C 最终登记**；私有门房素材属于线路 | Gold 原坐标 x,y 与 RPP y,x、源 warp 0-based、目的 warp、错误方向 |
| **道路连接** | `NativeRegionConnectionTargets`、Header 东西南北邻接、边缘安全围栏 | **C 最终开放**；方向 0=N/1=S/2=W/3=E 与实际 Gold 一致 | 两端连接、屏幕可见边缘、WRAM コピー范围、骑行与碰撞 |
| **Town Map/Fly** | `engine/town_map.asm`、`engine/johto_fly_town_map.asm`、`engine/fly_town_map_helpers.asm`、地标 45 项与候选目的地 | **C 独占**；Fly destination、Fly use permission 分别审核 | 列表、地点坐标、落点、旧城兼容 |
| **歌曲/调色/屋顶** | `engine/menu/options_menu.asm`、`data/johto_map_headers.asm`、`color/loadpalettes.asm`、`engine/overworld/johto_goldenrod_roof_gfx.asm` | **C 独占**；禁止复用音乐/色板 ID 造成跨城串色/串曲 | Gold mapgroup、RBY/GSC/RND、门房来源歌曲、昼夜 |
| **共享图块/TileSet** | `gfx/blocksets/johto.bst`、`data/tileset_headers.asm`、颜色和共用 metatile 序号 | **C 独占**；已用索引不得重排；A/B 可提交自己的未冲突私有资产 | 图块 bounds、32×32 metatile、碰撞、可见边缘 |
| **移动/碰撞/逃洞** | `engine/overworld/ledges.asm`、`johto_route33_collision.asm`、Surf/Cut/Fly/Strength/Dig/Escape Rope 及引擎调用 | **C 独占**；A/B 只交地图局部能力清单 | 旧图不退化、未授权技能入口仍受保护、Save/Continue |
| **故事/徽章/旗标** | 全局剧情 flags、火箭队线、道馆、捕虫大会、旧城广播塔 | **C 建登记簿并分配唯一符号/位**；A/B 无权复用未核实名额 | 存档兼容、剧情先后、重入、跨线条件检查 |
| **局部 Warp/NPC/文本槽** | 源地图内 warp 0-based、object slot、text pointer、隐藏道具、训练家实例 | **所属线**在本地图内独立编号；映射到全局角色/物品 ID 的部分由 C 审批 | 双 lane、脚本重入、同地图内互异，跨地图同 slot 合法 |
| **工具与注册合同** | `tools/johto_native_maps.json`、`tools/johto_door_contracts.json`、新稳定 ID 检查器、`tools/tests/`、发布审计 | **C 合入**，A/B 可提交独立命名的候选测试；不能绕过现有检查器 | 正向+反向故障注入、历史 SafariZoneBeta 保留 |
| **版本/待办/日志** | `data/game_version.asm`、`TODO.md`、`RPP_DEVELOPMENT_PITFALLS.md`、`commit-message.txt`、正式 Patch | **C 或用户统一收口**；A/B 写各自 `A_HANDOFF.md`/`B_HANDOFF.md` | 实际 HEAD、补丁基线、作用范围、测试/未测事实一致 |

**明确不能预先“锁死”的数字**：ROM Bank 物理放置、Warp 目标槽序（取决于原版对象顺序和实际新增对象）、剧情事件 flag 的数值位、Tileset 元件索引、音乐扩展 ID。它们有共享约束，但这份 ZIP 未提供所有未实现剧情的完整符号分配表，不能凭想象制造最终数字。应在 C 登记簿中**一次定名，首次实际核对后分号并冻结**，禁止开发线私下发明。冻结 222 张地图 ID 不等于上述每一类都已原型验证。

## 5. 工程节奏、分叉点和具体合并制度

| 轮次 | 谁做 | 唯一验收出口/条件 |
|---|---|---|
| **T0**（目前 `.225`） | C | 核 ZIP/HEAD/历史 Patch；完成 Bank `$01` 列表菜单与音乐手机专项（未验证的不冒充完成），复核 ROM0/目标 Bank MAP |
| **T1：Route37 / ID21** | C | Route36↔Route37 双向、碰撞、跳崖、视野、Gold 几何、场景切换、存读档、关都旧图回归；不误开放 38/42 号路 |
| **T2：EcruteakCity / ID22** | C | 37↔缘朱市双向；地标与音乐/屋顶；东西两门可独立封闭；外部剧情未做不标完成 |
| **T3：固定 ID 底座** | C | 第 2 节的 stable ID→active_slot、所有表迁移和越界保护通过负例/强制审计、用户 ROM/MAP/手机回归，形成可继承的版本 |
| **T4：正式分叉** | 用户确认后 C/A/B | 从同一个真实、已实测的 `ECRUTEAK_SPLIT_HEAD` 建 `johto-integration`/`johto-west`/`johto-east`，记录完整 hash，不凭空写 HEAD |
| **T5：东西首轮** | A: ID23 `Route38EcruteakGate`；B: ID62 `Route42EcruteakGate` | 线路私有 map/gate 资产各自完成 → C 注册实际 active_slot/缘朱出口 → 用户双向验收；随后 A ID24 Route38，B ID63 Route42 |
| **T6：后续** | A/B/C | 每轮 1 张图或 1 门房/洞穴层，已启用路径双向闭环；普通公园/遗迹补口由 C 并行穿插（编号见表） |

### 合并频率：必须执行的精确定义

- **触发条件**：每完工 1 张户外地图、1 座门房或 1 层洞穴就提交一次 *小型集成申请*；城市主体与建筑/道馆是不同工单，不能“一座城市”积攒十几张地图才合。
- **积压上限**：每线最多 1 个未集成可测试单元；若已达到上限不得开下一张。任一任务卡超过 **2 个工作日**没被 C 集成，先同步当前文件清单、阻塞原因和依赖，不能继续悄悄叠加。这个上限是流程门禁，不是承诺开发将在 2 天完成。
- **C 公共修复**：`C-FIX-xxx` 单独小变更；优先回归并同时同步 A/B，先公共后私有。公用 Bug 不允许只修西线版本然后把整套工程复制到东线。
- **C 集成**：C 只从单条线收一张图资产，核 stable ID 和文件所有权，在最新集成主干分配下一个 active_slot，插入各表/Bank INCLUDE、打开两端真实连接。不能先虚构“已上线”。
- **验收先后**：静态检查 → 用户编译/链接 ROM 并提供 MAP → 最小手机双向测试 → 写 `PHONE_ACCEPTED`。测试前最多称 `INTEGRATED_PENDING_PHONE`。失败回退此单元，不污染另一线已通过地图。
- **用户 Git Commit**：工程交付小合并/候选测试与正式提交是两回事；Git Commit/Push 只有用户决定。正式基线只承认用户新导出里真实可验证的 HEAD。

### 一份地图级集成申请（A/B 同格式）

```text
WORK_ID: A-ROUTE38-GATE / B-ROUTE42-GATE / C-...
OWNER: A | B | C
GOLD_MAP: <唯一 Gold 名>
STABLE_LOCAL_ID: <本表固定数字/十六进制>
BASE_HEAD: <用户最近确认的完整真实 HEAD>
COMMON_PATCHES_APPLIED: <C-FIX list + SHA256；没有填 NONE>
PRIVATE_FILES: <确切独占文件>
C_REGISTRATION_REQUEST: <Header/Bank/TownMap/Roof/Song/Warp/Connection/Field Moves>
SOURCE_WARP_AND_TARGET: <Gold x,y；RPP y,x；0-based warp slot；两端对应>
DEFERRED_OR_BLOCKED: <未开放的门/NPC/能力/剧情>
STATIC: <实际命令/结果/已知 FAIL>
ROM_AND_MAP: <用户新 MAP，ROM0 总空余/最大连续/目标 Bank 或 PENDING>
PHONE: <用户实测条目/结论或 PENDING>
CHANGED_FILES_SHA256: <实际生成后计算>
```

## 6. 专项任务与剧情依赖：不要被双线遗漏

- **C 的早期补口**：`Route32RuinsOfAlphGate`(ID102)、`NationalPark`(103)、`Route35NationalParkGate`(104)、`Route36NationalParkGate`(105)、`Route32Pokecenter1F`(106)、`NationalParkBugContest`(107)。这些是 **本版规划固定号码**，原先尚未注册；普通公园 35↔公园↔36 与捕虫大会独立验收，不因普通地图通了就宣布活动完成。
- **西线**：缘朱西门/Route38→39→浅葱→40/41→湛蓝；灯塔多层/药品、漩涡列岛、水路技能和码头独立排期。地形可先，但 Surf/Whirlpool/剧情解锁不可由 A 擅自全局放开。
- **东线**：缘朱东门/Route42→卡吉→43/湖区，及 44→冰雪小径→烟墨→45/46；擂钵山、火箭队基地、龙穴独立工单；冰雪小径必须按洞穴链真实 Warp，不直接接 44→烟墨。Route46→既有 Route29/门房的旧图一侧由 C 施工。
- **跨线剧情和共享旗标**：浅葱灯塔用药、卡吉火箭队与满金广播塔、徽章和城都后期进度统归 C 定义旗标及依赖合同；A/B 只能申报需求，不得复用未知存档位。
- **已有路网缺口**：Route32 遗迹东门、Route35/36 自然公园两门和普通公园、遗迹四石室/内室、联合洞穴 B1F 等不要因地图主体存在就误标“已有可通”。

## 7. 验收红线与正确命令

1. 检查强制入口并且必须用 **实际 Gold 原版完整目录**，本轮收到的 `pokegold-master(1).zip` 已可用于真正源代码交叉核验；后续同样必须提供可用 Gold 源码。
2. ZIP 里 `tools/johto_rpp_connection_guard.py` 实际要求两个必填参数；交接文档原来的单独 `--all-active` 命令不完整。

```bash
export JOHTO_GOLD_SOURCE=/actual/path/to/pokegold-master
export JOHTO_GOLD_ROOT="$JOHTO_GOLD_SOURCE"
# Gold 原始组号/编号/尺寸，222 张城都 ID，全量校验
python tools/johto_fixed_id_audit.py --project . --gold "$JOHTO_GOLD_SOURCE"
# A/B 提交合并申请时，用其真实变更文件逐项校验
python tools/johto_branch_file_guard.py --owner A --changed maps/JohtoRoute38.blk
python -m unittest discover -s tools/tests -p 'test*.py' -q
python tools/johto_rpp_connection_guard.py --project . --gold-root "$JOHTO_GOLD_SOURCE" --all-active
python tools/johto_map_release_audit.py --rpp . --gold "$JOHTO_GOLD_SOURCE" --expect-version ECRU-5.62.226
```

版本递增后要同步调整 `--expect-version`。上面是应执行命令，**不是声称已在此轮运行**。新增 ID 架构时必须扩展 `tools/johto_region_id_audit.py` 和 `tools/johto_map_release_audit.py`，使其确实能拦截重复 stable ID、重复 active_slot、错误所有者、错误索引、跨线公用文件写入、假激活地图和 stale save。

3. 每轮用户最小手机：新图两侧往返/门毯两 lane/反向马上出门/自动一步/碰撞与可见边缘/骑行/昼夜音乐/存档继续 + 至少一条关都旧图回归；技能、楼层、剧情根据任务另测。
4. 每轮真实新 MAP 核 ROM0 **总空余与最大连续空余**、目标 ROMX Bank/Section 安放、Bank `$01` 布局、跨 Bank ABI。禁止 AI 自行编译或链接 ROM；用户未给 MAP 时明确 PENDING。
5. 保留既存 `GOLD_FULL_CORPUS: SafariZoneBeta`，除非后续用户明确要修并有新证据；整体审计 `FAIL` 不得因其它项目 PASS 而被篡改。

## 8. 项目正式补丁交付要求（适用于以后所有线）

- **开发候选（未验收）**：默认只提供 **一个 ZIP，内部恰好 2 份 `.patch`**；①从用户当前实际开发状态到候选的增量 Patch；②从本轮**已核实的 Git HEAD**到候选的基线全量 Patch。两个是 **二选一**，不能叠加。此规划文档本身不是开发候选，不等同 Patch。
- **用户明确要求“清理”才进入正式清理**：有独立 `tools/` 审计工具/测试修改，**3 Patch + 2 日志**，功能先提交、工具后提交；没有工具独立修改则 **2 Patch + 1 日志**，不凑空提交。`scripts/Johto*.asm` 是游戏代码，不算工具脚本。
- 每次收到新 ZIP 先重新核分支、完整 HEAD、版本、Worktree、已应用历史 Patch；不因相同游戏版本猜 HEAD，也不把工作树冒充干净 HEAD。
- C-FIX、A/B 小型资产包只是内部协作和验证变更，**不替代**上述用户正式 Patch 格式。补丁 SHA-256、文件差异、基线和重放结果都要真实可核。

## 9. 完整固定 ID 登记表（222 张，唯一权威表 v1.1）

**表中“已登记”仅代表 ZIP 当前运行地图表已存在，并不代表 NPC/剧情/楼层完整。 “规划”一律尚未入运行时。**序号是物理 stable local ID，不是 Gold mapgroup、不等于 active_slot，也不是 Town Map 45 地标索引。

| RPP 固定 ID | 十六进制 | Gold 地图名 | 责任线 | Gold 组号 | Gold 组内编号 | 原版尺寸（blocks） | 状态 |
|---:|---|---|---|---:|---:|---:|---|
| 0 | `$00` | `NewBarkTown` | 既有 | NewBark (24) | 4 | 10 × 9 | 已登记 |
| 1 | `$01` | `Route29` | 既有 | NewBark (24) | 3 | 30 × 9 | 已登记 |
| 2 | `$02` | `CherrygroveCity` | 既有 | Cherrygrove (26) | 3 | 20 × 9 | 已登记 |
| 3 | `$03` | `Route30` | 既有 | Cherrygrove (26) | 1 | 10 × 27 | 已登记 |
| 4 | `$04` | `Route31` | 既有 | Cherrygrove (26) | 2 | 20 × 9 | 已登记 |
| 5 | `$05` | `VioletCity` | 既有 | Violet (10) | 5 | 20 × 18 | 已登记 |
| 6 | `$06` | `Route31VioletGate` | 既有 | Cherrygrove (26) | 11 | 5 × 4 | 已登记 |
| 7 | `$07` | `Route32` | 既有 | Violet (10) | 1 | 10 × 45 | 已登记 |
| 8 | `$08` | `UnionCave1F` | 既有 | Dungeons (3) | 29 | 10 × 18 | 已登记 |
| 9 | `$09` | `Route33` | 既有 | Azalea (8) | 6 | 10 × 9 | 已登记 |
| 10 | `$0A` | `AzaleaTown` | 既有 | Azalea (8) | 7 | 20 × 9 | 已登记 |
| 11 | `$0B` | `IlexForestAzaleaGate` | 既有 | Goldenrod (11) | 20 | 5 × 4 | 已登记 |
| 12 | `$0C` | `IlexForest` | 既有 | Dungeons (3) | 44 | 15 × 27 | 已登记 |
| 13 | `$0D` | `Route34IlexForestGate` | 既有 | Goldenrod (11) | 21 | 5 × 4 | 已登记 |
| 14 | `$0E` | `Route34` | 既有 | Goldenrod (11) | 1 | 10 × 27 | 已登记 |
| 15 | `$0F` | `GoldenrodCity` | 既有 | Goldenrod (11) | 2 | 20 × 18 | 已登记 |
| 16 | `$10` | `Route36` | 既有 | Violet (10) | 3 | 30 × 9 | 已登记 |
| 17 | `$11` | `Route35` | 既有 | Violet (10) | 2 | 10 × 18 | 已登记 |
| 18 | `$12` | `Route35GoldenrodGate` | 既有 | Violet (10) | 14 | 5 × 4 | 已登记 |
| 19 | `$13` | `Route36RuinsOfAlphGate` | 既有 | Violet (10) | 16 | 5 × 4 | 已登记 |
| 20 | `$14` | `RuinsOfAlphOutside` | 既有 | Dungeons (3) | 22 | 10 × 18 | 已登记 |
| 21 | `$15` | `Route37` | 共同起步 | Violet (10) | 4 | 10 × 9 | 已接入候选，待用户最终验收 |
| 22 | `$16` | `EcruteakCity` | 共同起步 | Ecruteak (4) | 9 | 20 × 18 | 已接入候选，待用户 ROM/MAP 和手机验收 |
| 23 | `$17` | `Route38EcruteakGate` | 西线A | Olivine (1) | 9 | 5 × 4 | 规划 |
| 24 | `$18` | `Route38` | 西线A | Olivine (1) | 12 | 20 × 9 | 规划 |
| 25 | `$19` | `Route39` | 西线A | Olivine (1) | 13 | 10 × 18 | 规划 |
| 26 | `$1A` | `OlivineCity` | 西线A | Olivine (1) | 14 | 20 × 18 | 规划 |
| 27 | `$1B` | `Route40` | 西线A | Cianwood (22) | 1 | 10 × 18 | 规划 |
| 28 | `$1C` | `Route41` | 西线A | Cianwood (22) | 2 | 25 × 27 | 规划 |
| 29 | `$1D` | `CianwoodCity` | 西线A | Cianwood (22) | 3 | 15 × 27 | 规划 |
| 30 | `$1E` | `OlivinePokecenter1F` | 西线A | Olivine (1) | 1 | 5 × 4 | 规划 |
| 31 | `$1F` | `OlivineGym` | 西线A | Olivine (1) | 2 | 5 × 8 | 规划 |
| 32 | `$20` | `OlivineTimsHouse` | 西线A | Olivine (1) | 3 | 4 × 4 | 规划 |
| 33 | `$21` | `OlivineHouseBeta` | 西线A | Olivine (1) | 4 | 4 × 4 | 规划 |
| 34 | `$22` | `OlivinePunishmentSpeechHouse` | 西线A | Olivine (1) | 5 | 4 × 4 | 规划 |
| 35 | `$23` | `OlivineGoodRodHouse` | 西线A | Olivine (1) | 6 | 4 × 4 | 规划 |
| 36 | `$24` | `OlivineCafe` | 西线A | Olivine (1) | 7 | 4 × 4 | 规划 |
| 37 | `$25` | `OlivineMart` | 西线A | Olivine (1) | 8 | 6 × 4 | 规划 |
| 38 | `$26` | `Route39Barn` | 西线A | Olivine (1) | 10 | 4 × 4 | 规划 |
| 39 | `$27` | `Route39Farmhouse` | 西线A | Olivine (1) | 11 | 4 × 4 | 规划 |
| 40 | `$28` | `ManiasHouse` | 西线A | Cianwood (22) | 4 | 4 × 4 | 规划 |
| 41 | `$29` | `CianwoodGym` | 西线A | Cianwood (22) | 5 | 5 × 9 | 规划 |
| 42 | `$2A` | `CianwoodPokecenter1F` | 西线A | Cianwood (22) | 6 | 5 × 4 | 规划 |
| 43 | `$2B` | `CianwoodPharmacy` | 西线A | Cianwood (22) | 7 | 4 × 4 | 规划 |
| 44 | `$2C` | `CianwoodPhotoStudio` | 西线A | Cianwood (22) | 8 | 4 × 4 | 规划 |
| 45 | `$2D` | `CianwoodLugiaSpeechHouse` | 西线A | Cianwood (22) | 9 | 4 × 4 | 规划 |
| 46 | `$2E` | `OlivineLighthouse1F` | 西线A | Dungeons (3) | 34 | 10 × 9 | 规划 |
| 47 | `$2F` | `OlivineLighthouse2F` | 西线A | Dungeons (3) | 35 | 10 × 9 | 规划 |
| 48 | `$30` | `OlivineLighthouse3F` | 西线A | Dungeons (3) | 36 | 10 × 9 | 规划 |
| 49 | `$31` | `OlivineLighthouse4F` | 西线A | Dungeons (3) | 37 | 10 × 9 | 规划 |
| 50 | `$32` | `OlivineLighthouse5F` | 西线A | Dungeons (3) | 38 | 10 × 9 | 规划 |
| 51 | `$33` | `OlivineLighthouse6F` | 西线A | Dungeons (3) | 39 | 10 × 9 | 规划 |
| 52 | `$34` | `WhirlIslandNW` | 西线A | Dungeons (3) | 58 | 5 × 9 | 规划 |
| 53 | `$35` | `WhirlIslandNE` | 西线A | Dungeons (3) | 59 | 10 × 9 | 规划 |
| 54 | `$36` | `WhirlIslandSW` | 西线A | Dungeons (3) | 60 | 10 × 9 | 规划 |
| 55 | `$37` | `WhirlIslandCave` | 西线A | Dungeons (3) | 61 | 5 × 9 | 规划 |
| 56 | `$38` | `WhirlIslandSE` | 西线A | Dungeons (3) | 62 | 5 × 9 | 规划 |
| 57 | `$39` | `WhirlIslandB1F` | 西线A | Dungeons (3) | 63 | 20 × 18 | 规划 |
| 58 | `$3A` | `WhirlIslandB2F` | 西线A | Dungeons (3) | 64 | 10 × 18 | 规划 |
| 59 | `$3B` | `WhirlIslandLugiaChamber` | 西线A | Dungeons (3) | 65 | 10 × 9 | 规划 |
| 60 | `$3C` | `OlivinePort` | 西线A | FastShip (15) | 1 | 10 × 18 | 规划 |
| 61 | `$3D` | `OlivinePortPassage` | 西线A | FastShip (15) | 8 | 10 × 9 | 规划 |
| 62 | `$3E` | `Route42EcruteakGate` | 东线B | Mahogany (2) | 4 | 5 × 4 | 规划 |
| 63 | `$3F` | `Route42` | 东线B | Mahogany (2) | 5 | 30 × 9 | 规划 |
| 64 | `$40` | `MahoganyTown` | 东线B | Mahogany (2) | 7 | 10 × 9 | 规划 |
| 65 | `$41` | `Route43MahoganyGate` | 东线B | LakeOfRage (9) | 3 | 5 × 4 | 规划 |
| 66 | `$42` | `Route43Gate` | 东线B | LakeOfRage (9) | 4 | 5 × 4 | 规划 |
| 67 | `$43` | `Route43` | 东线B | LakeOfRage (9) | 5 | 10 × 27 | 规划 |
| 68 | `$44` | `LakeOfRage` | 东线B | LakeOfRage (9) | 6 | 20 × 18 | 规划 |
| 69 | `$45` | `Route44` | 东线B | Mahogany (2) | 6 | 30 × 9 | 规划 |
| 70 | `$46` | `IcePath1F` | 东线B | Dungeons (3) | 53 | 20 × 18 | 规划 |
| 71 | `$47` | `BlackthornCity` | 东线B | Blackthorn (5) | 10 | 20 × 18 | 规划 |
| 72 | `$48` | `Route45` | 东线B | Blackthorn (5) | 8 | 10 × 45 | 规划 |
| 73 | `$49` | `Route46` | 东线B | Blackthorn (5) | 9 | 10 × 18 | 规划 |
| 74 | `$4A` | `Route29Route46Gate` | 东线B | NewBark (24) | 13 | 5 × 4 | 规划 |
| 75 | `$4B` | `MahoganyRedGyaradosSpeechHouse` | 东线B | Mahogany (2) | 1 | 4 × 4 | 规划 |
| 76 | `$4C` | `MahoganyGym` | 东线B | Mahogany (2) | 2 | 5 × 9 | 规划 |
| 77 | `$4D` | `MahoganyPokecenter1F` | 东线B | Mahogany (2) | 3 | 5 × 4 | 规划 |
| 78 | `$4E` | `LakeOfRageHiddenPowerHouse` | 东线B | LakeOfRage (9) | 1 | 4 × 4 | 规划 |
| 79 | `$4F` | `LakeOfRageMagikarpHouse` | 东线B | LakeOfRage (9) | 2 | 4 × 4 | 规划 |
| 80 | `$50` | `BlackthornGym1F` | 东线B | Blackthorn (5) | 1 | 5 × 9 | 规划 |
| 81 | `$51` | `BlackthornGym2F` | 东线B | Blackthorn (5) | 2 | 5 × 9 | 规划 |
| 82 | `$52` | `BlackthornDragonSpeechHouse` | 东线B | Blackthorn (5) | 3 | 4 × 4 | 规划 |
| 83 | `$53` | `BlackthornEmysHouse` | 东线B | Blackthorn (5) | 4 | 4 × 4 | 规划 |
| 84 | `$54` | `BlackthornMart` | 东线B | Blackthorn (5) | 5 | 6 × 4 | 规划 |
| 85 | `$55` | `BlackthornPokecenter1F` | 东线B | Blackthorn (5) | 6 | 5 × 4 | 规划 |
| 86 | `$56` | `MoveDeletersHouse` | 东线B | Blackthorn (5) | 7 | 4 × 4 | 规划 |
| 87 | `$57` | `MahoganyMart1F` | 东线B | Dungeons (3) | 40 | 4 × 4 | 规划 |
| 88 | `$58` | `TeamRocketBaseB1F` | 东线B | Dungeons (3) | 41 | 15 × 9 | 规划 |
| 89 | `$59` | `TeamRocketBaseB2F` | 东线B | Dungeons (3) | 42 | 15 × 9 | 规划 |
| 90 | `$5A` | `TeamRocketBaseB3F` | 东线B | Dungeons (3) | 43 | 15 × 9 | 规划 |
| 91 | `$5B` | `MountMortar1FOutside` | 东线B | Dungeons (3) | 49 | 20 × 18 | 规划 |
| 92 | `$5C` | `MountMortar1FInside` | 东线B | Dungeons (3) | 50 | 20 × 27 | 规划 |
| 93 | `$5D` | `MountMortar2FInside` | 东线B | Dungeons (3) | 51 | 20 × 18 | 规划 |
| 94 | `$5E` | `MountMortarB1F` | 东线B | Dungeons (3) | 52 | 20 × 18 | 规划 |
| 95 | `$5F` | `IcePathB1F` | 东线B | Dungeons (3) | 54 | 10 × 18 | 规划 |
| 96 | `$60` | `IcePathB2FMahoganySide` | 东线B | Dungeons (3) | 55 | 10 × 9 | 规划 |
| 97 | `$61` | `IcePathB2FBlackthornSide` | 东线B | Dungeons (3) | 56 | 5 × 9 | 规划 |
| 98 | `$62` | `IcePathB3F` | 东线B | Dungeons (3) | 57 | 10 × 9 | 规划 |
| 99 | `$63` | `DarkCaveBlackthornEntrance` | 东线B | Dungeons (3) | 71 | 15 × 18 | 规划 |
| 100 | `$64` | `DragonsDen1F` | 东线B | Dungeons (3) | 72 | 5 × 9 | 规划 |
| 101 | `$65` | `DragonsDenB1F` | 东线B | Dungeons (3) | 73 | 20 × 18 | 规划 |
| 102 | `$66` | `Route32RuinsOfAlphGate` | 共用C | Violet (10) | 12 | 5 × 4 | 规划 |
| 103 | `$67` | `NationalPark` | 共用C | Dungeons (3) | 15 | 20 × 27 | 规划 |
| 104 | `$68` | `Route35NationalParkGate` | 共用C | Violet (10) | 15 | 4 × 4 | 规划 |
| 105 | `$69` | `Route36NationalParkGate` | 共用C | Violet (10) | 17 | 5 × 4 | 规划 |
| 106 | `$6A` | `Route32Pokecenter1F` | 共用C | Violet (10) | 13 | 5 × 4 | 规划 |
| 107 | `$6B` | `NationalParkBugContest` | 共用C | Dungeons (3) | 16 | 20 × 27 | 规划 |
| 108 | `$6C` | `RuinsOfAlphResearchCenter` | 共用C | Dungeons (3) | 28 | 4 × 4 | 规划 |
| 109 | `$6D` | `RuinsOfAlphKabutoChamber` | 共用C | Dungeons (3) | 24 | 4 × 5 | 规划 |
| 110 | `$6E` | `RuinsOfAlphOmanyteChamber` | 共用C | Dungeons (3) | 25 | 4 × 5 | 规划 |
| 111 | `$6F` | `RuinsOfAlphAerodactylChamber` | 共用C | Dungeons (3) | 26 | 4 × 5 | 规划 |
| 112 | `$70` | `RuinsOfAlphHoOhChamber` | 共用C | Dungeons (3) | 23 | 4 × 5 | 规划 |
| 113 | `$71` | `RuinsOfAlphInnerChamber` | 共用C | Dungeons (3) | 27 | 10 × 14 | 规划 |
| 114 | `$72` | `UnionCaveB1F` | 共用C | Dungeons (3) | 30 | 10 × 18 | 规划 |
| 115 | `$73` | `UnionCaveB2F` | 共用C | Dungeons (3) | 31 | 10 × 18 | 规划 |
| 116 | `$74` | `SproutTower1F` | 共用C | Dungeons (3) | 1 | 10 × 8 | 规划 |
| 117 | `$75` | `ElmsLab` | 共用C | NewBark (24) | 5 | 5 × 6 | 规划 |
| 118 | `$76` | `PlayersHouse1F` | 共用C | NewBark (24) | 6 | 5 × 4 | 规划 |
| 119 | `$77` | `PlayersHouse2F` | 共用C | NewBark (24) | 7 | 4 × 3 | 规划 |
| 120 | `$78` | `PlayersNeighborsHouse` | 共用C | NewBark (24) | 8 | 4 × 4 | 规划 |
| 121 | `$79` | `ElmsHouse` | 共用C | NewBark (24) | 9 | 4 × 4 | 规划 |
| 122 | `$7A` | `CherrygroveMart` | 共用C | Cherrygrove (26) | 4 | 6 × 4 | 规划 |
| 123 | `$7B` | `CherrygrovePokecenter1F` | 共用C | Cherrygrove (26) | 5 | 5 × 4 | 规划 |
| 124 | `$7C` | `CherrygroveGymSpeechHouse` | 共用C | Cherrygrove (26) | 6 | 4 × 4 | 规划 |
| 125 | `$7D` | `GuideGentsHouse` | 共用C | Cherrygrove (26) | 7 | 4 × 4 | 规划 |
| 126 | `$7E` | `CherrygroveEvolutionSpeechHouse` | 共用C | Cherrygrove (26) | 8 | 4 × 4 | 规划 |
| 127 | `$7F` | `Route30BerryHouse` | 共用C | Cherrygrove (26) | 9 | 4 × 4 | 规划 |
| 128 | `$80` | `MrPokemonsHouse` | 共用C | Cherrygrove (26) | 10 | 4 × 4 | 规划 |
| 129 | `$81` | `VioletMart` | 共用C | Violet (10) | 6 | 6 × 4 | 规划 |
| 130 | `$82` | `VioletGym` | 共用C | Violet (10) | 7 | 5 × 8 | 规划 |
| 131 | `$83` | `EarlsPokemonAcademy` | 共用C | Violet (10) | 8 | 4 × 8 | 规划 |
| 132 | `$84` | `VioletNicknameSpeechHouse` | 共用C | Violet (10) | 9 | 4 × 4 | 规划 |
| 133 | `$85` | `VioletPokecenter1F` | 共用C | Violet (10) | 10 | 5 × 4 | 规划 |
| 134 | `$86` | `VioletKylesHouse` | 共用C | Violet (10) | 11 | 4 × 4 | 规划 |
| 135 | `$87` | `AzaleaPokecenter1F` | 共用C | Azalea (8) | 1 | 5 × 4 | 规划 |
| 136 | `$88` | `CharcoalKiln` | 共用C | Azalea (8) | 2 | 4 × 4 | 规划 |
| 137 | `$89` | `AzaleaMart` | 共用C | Azalea (8) | 3 | 6 × 4 | 规划 |
| 138 | `$8A` | `KurtsHouse` | 共用C | Azalea (8) | 4 | 8 × 4 | 规划 |
| 139 | `$8B` | `AzaleaGym` | 共用C | Azalea (8) | 5 | 5 × 8 | 规划 |
| 140 | `$8C` | `GoldenrodGym` | 共用C | Goldenrod (11) | 3 | 10 × 9 | 规划 |
| 141 | `$8D` | `GoldenrodBikeShop` | 共用C | Goldenrod (11) | 4 | 4 × 4 | 规划 |
| 142 | `$8E` | `GoldenrodHappinessRater` | 共用C | Goldenrod (11) | 5 | 4 × 4 | 规划 |
| 143 | `$8F` | `BillsFamilysHouse` | 共用C | Goldenrod (11) | 6 | 4 × 4 | 规划 |
| 144 | `$90` | `GoldenrodMagnetTrainStation` | 共用C | Goldenrod (11) | 7 | 10 × 9 | 规划 |
| 145 | `$91` | `GoldenrodFlowerShop` | 共用C | Goldenrod (11) | 8 | 4 × 4 | 规划 |
| 146 | `$92` | `GoldenrodPokecenter1F` | 共用C | Goldenrod (11) | 9 | 5 × 4 | 规划 |
| 147 | `$93` | `GoldenrodPPSpeechHouse` | 共用C | Goldenrod (11) | 10 | 4 × 4 | 规划 |
| 148 | `$94` | `GoldenrodNameRater` | 共用C | Goldenrod (11) | 11 | 4 × 4 | 规划 |
| 149 | `$95` | `GoldenrodDeptStore1F` | 共用C | Goldenrod (11) | 12 | 8 × 4 | 规划 |
| 150 | `$96` | `GoldenrodDeptStore2F` | 共用C | Goldenrod (11) | 13 | 8 × 4 | 规划 |
| 151 | `$97` | `GoldenrodDeptStore3F` | 共用C | Goldenrod (11) | 14 | 8 × 4 | 规划 |
| 152 | `$98` | `GoldenrodDeptStore4F` | 共用C | Goldenrod (11) | 15 | 8 × 4 | 规划 |
| 153 | `$99` | `GoldenrodDeptStore5F` | 共用C | Goldenrod (11) | 16 | 8 × 4 | 规划 |
| 154 | `$9A` | `GoldenrodDeptStore6F` | 共用C | Goldenrod (11) | 17 | 8 × 4 | 规划 |
| 155 | `$9B` | `GoldenrodDeptStoreElevator` | 共用C | Goldenrod (11) | 18 | 2 × 2 | 规划 |
| 156 | `$9C` | `GoldenrodGameCorner` | 共用C | Goldenrod (11) | 19 | 10 × 7 | 规划 |
| 157 | `$9D` | `DayCare` | 共用C | Goldenrod (11) | 22 | 5 × 4 | 规划 |
| 158 | `$9E` | `EcruteakTinTowerEntrance` | 共用C | Ecruteak (4) | 1 | 10 × 9 | 规划 |
| 159 | `$9F` | `EcruteakTinTowerBackEntrance` | 共用C | Ecruteak (4) | 2 | 4 × 4 | 规划 |
| 160 | `$A0` | `EcruteakPokecenter1F` | 共用C | Ecruteak (4) | 3 | 5 × 4 | 规划 |
| 161 | `$A1` | `EcruteakLugiaSpeechHouse` | 共用C | Ecruteak (4) | 4 | 4 × 4 | 规划 |
| 162 | `$A2` | `DanceTheater` | 共用C | Ecruteak (4) | 5 | 6 × 7 | 规划 |
| 163 | `$A3` | `EcruteakMart` | 共用C | Ecruteak (4) | 6 | 6 × 4 | 规划 |
| 164 | `$A4` | `EcruteakGym` | 共用C | Ecruteak (4) | 7 | 5 × 9 | 规划 |
| 165 | `$A5` | `EcruteakItemfinderHouse` | 共用C | Ecruteak (4) | 8 | 4 × 4 | 规划 |
| 166 | `$A6` | `SproutTower2F` | 共用C | Dungeons (3) | 2 | 10 × 8 | 规划 |
| 167 | `$A7` | `SproutTower3F` | 共用C | Dungeons (3) | 3 | 10 × 8 | 规划 |
| 168 | `$A8` | `TinTower1F` | 共用C | Dungeons (3) | 4 | 10 × 9 | 规划 |
| 169 | `$A9` | `TinTower2F` | 共用C | Dungeons (3) | 5 | 10 × 9 | 规划 |
| 170 | `$AA` | `TinTower3F` | 共用C | Dungeons (3) | 6 | 10 × 9 | 规划 |
| 171 | `$AB` | `TinTower4F` | 共用C | Dungeons (3) | 7 | 10 × 9 | 规划 |
| 172 | `$AC` | `TinTower5F` | 共用C | Dungeons (3) | 8 | 10 × 9 | 规划 |
| 173 | `$AD` | `TinTower6F` | 共用C | Dungeons (3) | 9 | 10 × 9 | 规划 |
| 174 | `$AE` | `TinTower7F` | 共用C | Dungeons (3) | 10 | 10 × 9 | 规划 |
| 175 | `$AF` | `TinTower8F` | 共用C | Dungeons (3) | 11 | 10 × 9 | 规划 |
| 176 | `$B0` | `TinTower9F` | 共用C | Dungeons (3) | 12 | 10 × 9 | 规划 |
| 177 | `$B1` | `BurnedTower1F` | 共用C | Dungeons (3) | 13 | 10 × 9 | 规划 |
| 178 | `$B2` | `BurnedTowerB1F` | 共用C | Dungeons (3) | 14 | 10 × 9 | 规划 |
| 179 | `$B3` | `RadioTower1F` | 共用C | Dungeons (3) | 17 | 9 × 4 | 规划 |
| 180 | `$B4` | `RadioTower2F` | 共用C | Dungeons (3) | 18 | 9 × 4 | 规划 |
| 181 | `$B5` | `RadioTower3F` | 共用C | Dungeons (3) | 19 | 9 × 4 | 规划 |
| 182 | `$B6` | `RadioTower4F` | 共用C | Dungeons (3) | 20 | 9 × 4 | 规划 |
| 183 | `$B7` | `RadioTower5F` | 共用C | Dungeons (3) | 21 | 9 × 4 | 规划 |
| 184 | `$B8` | `SlowpokeWellB1F` | 共用C | Dungeons (3) | 32 | 10 × 9 | 规划 |
| 185 | `$B9` | `SlowpokeWellB2F` | 共用C | Dungeons (3) | 33 | 10 × 9 | 规划 |
| 186 | `$BA` | `GoldenrodUnderground` | 共用C | Dungeons (3) | 45 | 15 × 18 | 规划 |
| 187 | `$BB` | `GoldenrodUndergroundSwitchRoomEntrances` | 共用C | Dungeons (3) | 46 | 15 × 18 | 规划 |
| 188 | `$BC` | `GoldenrodDeptStoreB1F` | 共用C | Dungeons (3) | 47 | 10 × 9 | 规划 |
| 189 | `$BD` | `GoldenrodUndergroundWarehouse` | 共用C | Dungeons (3) | 48 | 10 × 9 | 规划 |
| 190 | `$BE` | `DarkCaveVioletEntrance` | 共用C | Dungeons (3) | 70 | 20 × 18 | 规划 |
| 191 | `$BF` | `TinTowerRoof` | 共用C | FastShip (15) | 12 | 10 × 9 | 规划 |
| 192 | `$C0` | `Route26` | 后期C | NewBark (24) | 1 | 10 × 54 | 规划 |
| 193 | `$C1` | `Route27` | 后期C | NewBark (24) | 2 | 40 × 9 | 规划 |
| 194 | `$C2` | `Route26HealHouse` | 后期C | NewBark (24) | 10 | 4 × 4 | 规划 |
| 195 | `$C3` | `DayOfWeekSiblingsHouse` | 后期C | NewBark (24) | 11 | 4 × 4 | 规划 |
| 196 | `$C4` | `Route27SandstormHouse` | 后期C | NewBark (24) | 12 | 4 × 4 | 规划 |
| 197 | `$C5` | `Route28` | 后期C | Silver (19) | 1 | 20 × 9 | 规划 |
| 198 | `$C6` | `SilverCaveOutside` | 后期C | Silver (19) | 2 | 20 × 18 | 规划 |
| 199 | `$C7` | `SilverCavePokecenter1F` | 后期C | Silver (19) | 3 | 5 × 4 | 规划 |
| 200 | `$C8` | `Route28SteelWingHouse` | 后期C | Silver (19) | 4 | 4 × 4 | 规划 |
| 201 | `$C9` | `SilverCaveRoom1` | 后期C | Dungeons (3) | 66 | 10 × 18 | 规划 |
| 202 | `$CA` | `SilverCaveRoom2` | 后期C | Dungeons (3) | 67 | 15 × 18 | 规划 |
| 203 | `$CB` | `SilverCaveRoom3` | 后期C | Dungeons (3) | 68 | 10 × 18 | 规划 |
| 204 | `$CC` | `SilverCaveItemRooms` | 后期C | Dungeons (3) | 69 | 10 × 9 | 规划 |
| 205 | `$CD` | `TohjoFalls` | 后期C | Dungeons (3) | 74 | 15 × 9 | 规划 |
| 206 | `$CE` | `VictoryRoad` | 后期C | Dungeons (3) | 82 | 10 × 36 | 规划 |
| 207 | `$CF` | `VermilionPort` | 后期C | FastShip (15) | 2 | 10 × 18 | 规划 |
| 208 | `$D0` | `FastShip1F` | 后期C | FastShip (15) | 3 | 16 × 9 | 规划 |
| 209 | `$D1` | `FastShipCabins_NNW_NNE_NE` | 后期C | FastShip (15) | 4 | 4 × 16 | 规划 |
| 210 | `$D2` | `FastShipCabins_SW_SSW_NW` | 后期C | FastShip (15) | 5 | 4 × 16 | 规划 |
| 211 | `$D3` | `FastShipCabins_SE_SSE_CaptainsCabin` | 后期C | FastShip (15) | 6 | 5 × 17 | 规划 |
| 212 | `$D4` | `FastShipB1F` | 后期C | FastShip (15) | 7 | 16 × 8 | 规划 |
| 213 | `$D5` | `VermilionPortPassage` | 后期C | FastShip (15) | 9 | 10 × 9 | 规划 |
| 214 | `$D6` | `Route23` | 后期C | Indigo (16) | 1 | 10 × 9 | 规划 |
| 215 | `$D7` | `IndigoPlateauPokecenter1F` | 后期C | Indigo (16) | 2 | 9 × 7 | 规划 |
| 216 | `$D8` | `WillsRoom` | 后期C | Indigo (16) | 3 | 5 × 9 | 规划 |
| 217 | `$D9` | `KogasRoom` | 后期C | Indigo (16) | 4 | 5 × 9 | 规划 |
| 218 | `$DA` | `BrunosRoom` | 后期C | Indigo (16) | 5 | 5 × 9 | 规划 |
| 219 | `$DB` | `KarensRoom` | 后期C | Indigo (16) | 6 | 5 × 9 | 规划 |
| 220 | `$DC` | `LancesRoom` | 后期C | Indigo (16) | 7 | 5 × 12 | 规划 |
| 221 | `$DD` | `HallOfFame` | 后期C | Indigo (16) | 8 | 5 × 7 | 规划 |

### 不占用城都编号的 Gold 关都参考（9 项）

`DiglettsCave`, `MountMoon`, `UndergroundPath`, `RockTunnel1F`, `RockTunnelB1F`, `SafariZoneFuchsiaGateBeta`, `SafariZoneBeta`, `MountMoonSquare`, `MountMoonGiftShop`。这些不是 RPP 的城都缺图证明，不能拿新城都 local ID 覆盖旧关都物理地图。

## 10. 自查和下一次开工移交卡

- **文档自检**：231 个 Gold 索引条目唯一；关都参考 9；城都稳定 ID `0..221` 无缺口、无重复；分布 21/2/39/40/90/30；旧 21 个数字和 `tools/johto_native_maps.json` 一致。**现已同时以原版 Gold 两个权威表独立验证 222 项原始组号/组内号和尺寸；仍未验证各图的 Warp/剧情或 sparse ID 引擎代码。**
- **Route37 (stable ID21)** 已开发候选，当前 `NUM_JOHTO_MAPS=23`；缘朱市已接入候选，不能提前扩容到 222。用户验收前仍不得分叉；下阶段修复稀疏 ID 映射及进行手机回归。
- 第二单元 **EcruteakCity (ID22)** 已静态接入；分叉前完成 stable ID 兼容层及用户验收；只有拿到实际新 `ECRUTEAK_SPLIT_HEAD` 才启动 A/B。

```text
PLAN_VERSION: Johto-DualLine-StableIDs-v1.0
CURRENT_SOURCE_HEAD: ef651561163ff9502469444a2edcf050f70cf5c5 (last verified formal HEAD; Ecruteak ID22 is a new uncommitted candidate)
CURRENT_VERSION: ECRU-5.62.226
NEXT_TASK: C / EcruteakCity (ID22) candidate -> user ROM/MAP and phone acceptance
SECOND_TASK: C / sparse stable-ID -> active-slot runtime migration (only after current city acceptance)
PRE_FORK_GATE: 0..20 phone regression; stable ID -> active_slot support; safe invalid IDs; fresh MAP; Route37/Ecruteak phone acceptance
SPLIT_HEAD: NOT_YET_CREATED
WEST_FIRST: Route38EcruteakGate / ID 23 ($17)
EAST_FIRST: Route42EcruteakGate / ID 62 ($3E)
COMMON_NEXT_BACKLOG: Route32RuinsOfAlphGate / ID 102 ($66)
MERGE_FREQUENCY: once per map/gate/floor; max one outstanding unit per branch; 2-working-day blocking escalation
KNOWN_GLOBAL_AUDIT_FAIL: GOLD_FULL_CORPUS: SafariZoneBeta
CODE_CHANGE_THIS_TURN: YES (ASM preallocation + audit/build/ownership gate; no new runtime maps)
```

---
**冻结声明**：此 v1.1 固定的是已知 222 张地图的 stable local ID 与区域代码责任。新 Gold 源出现额外地图、合并地图或原清单错误时必须发起显式变更审查并记录迁移影响；已经进入真实 ROM/存档的 ID 不得暗改。这是一套可核验的冲突预防制度，不是“未来任何程序错误都不会发生”的保证。


## 11. 本轮源数据与上线判定

- **唯一可机器读取的 RPP ID 分配表**：`tools/johto_fixed_ids.csv`，固定 0–221 的实体身份；变更需 C 显式修订文档、冻结哈希并回归检查。
- **Gold 原版编号全图**：`tools/johto_gold_map_reference.csv`，原版 368 条的 `gold_group_id`、`gold_map_id`、原版符号和块尺寸；不是 368 个 RPP 城都新 ID。
- **阻断器**：`tools/johto_fixed_id_audit.py --project . --gold "$JOHTO_GOLD_SOURCE"` 可重新解析 Gold 原版并逐行核对；不提供 Gold 时可进行本地冻结保护，但不声明这轮验证了外部源码。
- **分线文件门禁**：`tools/johto_branch_file_guard.py --owner A|B --changed-list changed_paths.txt`；禁止 A/B 改公共表、私自修改另一线地图。某地图确实需要新公共素材时，由 C 审核并执行，不绕开白名单。
- **当前运行状态**：`NUM_JOHTO_MAPS=23`，0–20 不变，Route37 ID21 和 EcruteakCity ID22 已注册为源码候选，23 及以后仍未激活。Route37 与缘朱市尚待最终实机验收；完成 sparse ID 兼容、ROM/MAP 与用户手机回归前不得开放 62 等跳号运行。
- **固定编号阶段历史测试结果**（当时实际重跑，Gold 路径 `/mnt/data/goldsrc/pokegold-master`）：
  - `JOHTO_GOLD_ROOT=<Gold目录> JOHTO_GOLD_SOURCE=<Gold目录> python -m unittest discover -s tools/tests -p 'test*.py' -q`：**703/703 PASS，0 skipped**，其中固定 ID / Gold 来源 / 分线文件专项见本次完整测试清单。
  - `python tools/johto_rpp_connection_guard.py --project . --gold-root <Gold目录> --all-active`：已启用连接 **22/22 PASS**。
  - `python tools/johto_fixed_id_audit.py --project . --gold <Gold目录>`：**PASS，222 张 RPP 固定 ID + 368 张原版 Gold 地图完整对照**。
  - `python tools/johto_map_release_audit.py --rpp . --gold <Gold目录> --expect-version BANK-5.62.225`：**status=FAIL，tests=703，skipped=0，connections=22 PASS；仅 `GOLD_FULL_CORPUS: SafariZoneBeta: Gold map references graphics beyond runtime window`**（沿用历史已知问题，没有屏蔽）。
  - AI 未编译/链接 ROM，未修改运行时代码，MAP/手机验收均 PENDING；文件检查结果不代表运行时 sparse ID 已完成。


## 12. 固定编号清理收口（上一阶段历史记录，BANK-5.62.225）

- **保留并纳入游戏常量提交**：`constants/johto_fixed_map_ids.asm` 和 `constants/region_map_constants.asm` 的单次 INCLUDE；只定义 21～221，不移动旧 0～20，不扩大 `NUM_JOHTO_MAPS`，不创建假地图。
- **保留并纳入工具审计提交**：`tools/johto_fixed_ids.csv`（唯一分配表）、`tools/johto_gold_map_reference.csv`（原版对照）、`tools/johto_fixed_id_audit.py`、`tools/johto_branch_file_guard.py`、固定编号专项测试、统一发布审计接入、Makefile 前置门禁、README/TODO/踩坑及本规范。工具文件检查和分线白名单应在开发提交流程中执行，`make` 只自动执行编号门禁，不会凭空知道当前开发支线角色。
- **不纳入正式补丁**：聊天导出用的外部 CSV/MD 副本、临时生成器、`__pycache__`、历史候选 ZIP、旧工作区日志与 MAP 重编产物；此类文件不属于源码累计差异。
- **固定编号阶段未实现的部分（历史收口说明）**：当时 Route37 尚未开发；本次 Route37 和 EcruteakCity 均已接入源码候选。稀疏 ID/active-slot 映射、Town Map 未来扩容、ROM 编译/MAP 更新及完整用户手机验收仍未完成。
- **正式提交方法**：先做游戏源码常量提交，再做工具/审计/文档提交；正式增量以已经应用上一版固定编号候选的工作区为前置，全量以导出的干净 HEAD `47915e4e3a536e7cfefee870254feefbaede99ac` 为前置。Git Commit/Push 用户自行执行。项目规则以原始 RPP 项目要求为准，`RPP_PROJECT_CONTEXT/03_PROJECT_REQUIREMENTS.txt` 是自动导出资料，不打补丁。
- **审计提示已消歧**：独立运行 `make johto-id-preflight` 只核查已冻结的 Gold 参考 CSV，不能宣称重新解析外部 Gold 源码；只有显式 `--gold <Gold根目录>` 并检查 PASS 时才能宣称原版 368 条再次比对成功。
