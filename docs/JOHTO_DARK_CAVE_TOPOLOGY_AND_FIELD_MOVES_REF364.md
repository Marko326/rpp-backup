> **REF-365 更新 / 计划修订（2026-11-09）：本文件是 REF-364 历史施工计划，已被 `docs/REF365_DARK_CAVE_BLACKTHORN_DEV.md` 覆盖。用户明确决定 Rock Smash 尚不存在，因此四块可碎岩石头、技能、破坏事件和遭遇全部推迟；不属于当前阶段验收条件。ID99 与洞内双向口、Route45、Flash、Surf、Bike、跳崖、Dig/离洞绳已经在 REF-365 开发候选中接入；尚未 ROM/手机验收。以下原文“本期必须 Rock Smash”“REF-364 未开放”只表示历史决策，不可作为当前指令。**

# Johto Dark Cave｜Gold 双区域洞口拓扑与 Field Moves 项目要求（REF-364 后续任务）

> **状态：已核对原版与 REF-364 源码；这是需求与验收合同，不是功能完成声明。** 2026-11-09。输入为用户的 `REF-364.zip`、`JOHTO_HANDOFF_REF306_FLAT_REFERENCES_交接文档.zip` 中 Gold `pokegold-master` 源码。**本次不改运行 ASM、ROM、图块或存档结构；游戏版本仍为 `REF-364@`。**
>
> 用户本阶段范围：**完成所有真实地形通路和 Field Moves；不做野生遭遇/钓鱼、训练师、普通 NPC、剧情、道具球、隐藏物品。** Rock Smash 石头虽然在 Gold 被归为 object_event，仍须作为场地技能障碍实现；其随机遇敌分支不做。

## A. 必须保留的地图身份（不是 B1F/B2F）

| Gold 地图 | RPP 固定 Stable ID | Gold block / 8×8 cell | REF-364 运行状态 |
|---|---:|---|---|
| `DarkCaveVioletEntrance`（桔梗侧） | **190** | 20×18 blocks / **40×36 cells** | 已激活；Route31、Route46 双室外出口可用；内部洞口仍封闭 |
| `DarkCaveBlackthornEntrance`（烟墨侧） | **99** | 15×18 blocks / **30×36 cells** | **未激活**，不能因存在固定 ID 而视为可进入 |

Gold 黑暗洞穴由 **两张同一洞穴、同一楼层但不同地图的区域**构成，洞内通过跨区域洞口相连；不存在应为此洞穴补建的 `B1F`、`B2F`。两块地图必须独立保留宽高、碰撞角色、Header/Bank、音乐、调色、出口表、资源和缓存，不得让 ID99 读取 ID190 的 40×36 角色表。

## B. 真实五个洞内 Warp（位置为 8×8 cell 的 x,y）

| 所在区域 | Gold 源 Warp（1 基） | 坐标 | Gold 目标（1 基） | 砖碰撞类型 / 触发方式 | REF-364 状态 |
|---|---:|---|---|---|---|
| 桔梗 ID190 | **#1** | **(3,15)** | `ROUTE_31` **#3** | `WARP_CARPET_DOWN`；站在毯格朝 **DOWN** 碰撞退出 | 已开放，RPP 源 ordinal **0** |
| 桔梗 ID190 | **#2** | **(17,1)** | **烟墨 ID99 #2** `(3,25)` | **`CAVE`；从相邻格踏入即触发 `STEP_IN`** | **未开放；RPP 源 ordinal 1 必须保留** |
| 桔梗 ID190 | **#3** | **(35,33)** | `ROUTE_46` **#3** | `WARP_CARPET_DOWN`；朝 **DOWN** 碰撞退出 | 已开放，RPP 源 ordinal **2** |
| 烟墨 ID99 | **#1** | **(23,3)** | `ROUTE_45` **#1** | `WARP_CARPET_DOWN`；朝 **DOWN** 碰撞退出 | 未开放，未来 RPP ordinal **0** |
| 烟墨 ID99 | **#2** | **(3,25)** | **桔梗 ID190 #2** `(17,1)` | **`WARP_CARPET_DOWN`；朝 DOWN 碰撞返回** | 未开放，未来 RPP ordinal **1** |

与上述对应的三个**室外入口**是 Gold `Route31 (34,5) → Violet #1`，`Route46 (14,5) → Violet #3`，`Route45 (2,5) → Blackthorn #1`。未来启用 Route45 时不得改变 Route31/46 已验证的输入方向及出洞自动向下迈步。

**需要特别注意：内部配对两端触发语义不同。** ID190 的 `(17,1)` 是真正 `CAVE` 踏格型；ID99 的 `(3,25)` 是 `DOWN` 方向门毯。踏入型的目的地又恰是原本的 CAVE 格，必须防止到达时立即重复传送、落地后失控或原地反复循环。不得简单把双向通道都设成 DOWN 地毯，也不得用“站到格上立即 Warp”的统一实现覆盖已开放的两个室外出口。

### 当前 RPP 5-byte Warp 注册映射与未来增量

- REF-364 的 `engine/johto_pilot_runtime.asm::JohtoRegisteredWarpRoutes` 当前只注册 **四个方向记录**：`Route31 ordinal2 → ID190`、`ID190 ordinal0 → Route31`、`Route46 ordinal2 → ID190`、`ID190 ordinal2 → Route46`。这是**两对**双向通路，不是全部洞穴完成。
- **现在** ID190 ordinal1 不在运行表，`engine/johto_dark_cave_stage2.asm::JohtoDarkCaveLandDecision` 会拒绝 role `7` (`CAVE`)；Surf shore 同样不能进入该格。不得先删除阻挡，后忘了注册目标地图与回程。
- **以后**仅在 ID99 完成地图资源、完整 Field Moves、回程与验证后，同时增开：`ID190 ordinal1 ↔ ID99 ordinal1`、`Route45 ordinal0 ↔ ID99 ordinal0`。这将新增**四条方向路由**（若注册结构不变，则 164→**168**），但该数量只是计划公式，**未实现，不能先改当前数量断言**。
- 原版 Gold 的 1 基 `warp_event` 编号与 RPP 的 0 基 source ordinal 必须分别转换；中间 ordinal1 不可压缩。运行目标、到达格、入洞触发和回程状态都必须实测。

## C. 本批必须做与明确不做

| 内容 | ID190 桔梗侧 | ID99 烟墨侧 | 本期决定 |
|---|---|---|---|
| Flash 黑暗／照亮 | 已实现（当前仍含旧存档徽章兼容） | 未实现 | **必须**：明暗、切区后状态、跨区域反复进出及存读档 |
| Surf／上岸／水上移动 | 64 水格；现有实现 | Gold 120 水格；未运行接入 | **必须**：两图分别按 Gold 格子判定，封口不得从水上误穿 |
| 方向跳崖及墙体 | 12 DOWN + 14 LEFT；41 UP_WALL | 10 DOWN + 4 LEFT；49 UP_WALL | **必须**：正确的两步越墙、单向限制、落点保护及 B 键 |
| Bike 洞内骑车 | 已有仅 ID190 的专用判定 | 未实现 | **必须**：仅 Gold 合法 FLOOR／门毯上车，冲浪与危险格拒绝 |
| Rock Smash 碎岩 | Gold **4 块**：`(16,14)`、`(27,6)`、`(7,14)`、`(36,31)`；未实现 | Gold **0 块** | **必须**：独立 Rock Smash 身份、技能检查、目标碰撞、动画与移除；**不触发碎岩野怪** |
| Dig／Escape Rope | 不支持本洞安全出洞 | 未实现 | **必须**：返回本次从户外进入洞穴的原入口；跨洞内区域不能改写入口来源 |
| Strength 推石 | Gold 无推石对象 | Gold 无推石对象 | **不新增**，不得拿 Strength 代替 Rock Smash |
| Cut／Whirlpool／Waterfall | Gold 无相应对象／障碍 | Gold 无相应对象／障碍 | **不新增**虚构障碍 |
| NPC、道具、隐藏物品、普通剧情、训练师、野怪／钓鱼 | 未完整实现 | 未实现 | **明确排除本阶段** |

**Dig/Escape Rope 原版依据**：Gold `home/map.asm::EnterMapWarp.SaveDigWarp` 从室外进入室内/CAVE 类地图时保存 `wPrevWarp/wPrevMapGroup/wPrevMapNumber` 到 `wDigWarpNumber/wDigMapGroup/wDigMapNumber`；Gold `engine/events/overworld.asm::EscapeRopeOrDig` 在 CAVE/DUNGEON 中消费该回程锚点。RPP 不能直接放开 `EscapeRopeTilesets`：它目前的旧 `SpecialWarpIn` 分支会转向上次治疗点，**不等于 Gold 入洞来源**。必须覆盖 31、46、45 三种入洞、洞内双向切区后使用、离洞再入洞更新、旧存档及 Continue，确保返回不是治疗中心且不会卡在门格。

Rock Smash 属独立招式/场地技能，不能用 Strength 冒名。现有旧招式编号空间到 `$FE`、`$FF` 保留，不得直接新增冲突的 8-bit move ID；先选通过审核的扩展招式身份方案，再接党伍技能菜单、面向石头判定及对象状态。对象应可碎后通行、离开地图再次进入按 Gold 重置；禁止把底层 FLOOR 直接改为永久墙或引入随机遭遇。

## D. 分批交付与验收门槛

- [x] **审计完成（本次）**：Gold 两个 `.asm` warp_event、两个 `.blk` 原始 block、`data/tilesets/cave_collision.asm` 每个 Warp 的四分区碰撞类型，对照 RPP ID190+ID99 常量和现有四条运行路由。
- [ ] **阶段 1｜保持已验收 ID190，不破坏运行代码**：先做四块 Rock Smash 与 Dig／Escape Rope 的完整正/负向测试；Route31/46、水边上岸、26 HOP、Flash、Bike、黑暗与出洞稳定性重新回归。
- [ ] **阶段 2｜同层 ID99 开放**：独立 30×36 角色表、120 WATER、49 UP_WALL、14 HOP、Flash、Bike；同时注册两条洞内方向路由和 Route45 双向路由。封闭所有尚未接入的其他分支。
- [ ] **跨洞完整回归**：31→190→99→45、45→99→190→46，及 46→190→99→45；两个内部洞口分别测踩入/向下碰撞、方向错误/重复按键、立即掉头、防连环 Warp、涉水/跳崖后换图。
- [ ] **脱困回归**：从 Route31/46/45 任一入口进入、切过 ID190/99 后 Dig/离洞绳返回原入口；物品消耗/技能不可用的负向路径、旧档、洞内 Save→Continue、暗场已 Flash／未 Flash 状态均覆盖。
- [ ] **正式验收**：Gold 原图与碰撞逐格对照、Warp 0/1 基编号和各表长静态审计、专项/负向测试；用户本机 Red/Blue/TEST Red/TEST Blue 新 ROM+MAP（ROM0≥64B、紧张 Bank 空间）及 My OldBoy 双向往返，才能从“待做”改成 R2/Field Moves 验收。

当前 `docs/REF349_DARK_CAVE_VIOLET_STAGE1.json`、`maps/johto_pilot/DarkCaveVioletEntrance.special_cells.json` 属**REF-349 当时的阶段快照**；其中 Route46 `INACTIVE` 是历史字段，**不是 REF-364 实时状态**。本文件和新增的 `docs/JOHTO_DARK_CAVE_TOPOLOGY_REF364.json` 明确记录最新已开放/未开放边界，不修改历史快照防止静态审计的冻结资产被误写。

## E. 一手证据索引

**Gold 参考包**：`maps/DarkCaveVioletEntrance.asm`、`maps/DarkCaveBlackthornEntrance.asm`、`maps/DarkCaveVioletEntrance.blk`、`maps/DarkCaveBlackthornEntrance.blk`、`maps/Route31.asm`、`maps/Route46.asm`、`maps/Route45.asm`、`data/tilesets/cave_collision.asm`、`home/map.asm`、`engine/events/overworld.asm`。本次独立验证每个洞内 Warp 的 Gold block、碰撞：桔梗 `(3,15)=WARP_CARPET_DOWN`、`(17,1)=CAVE`、`(35,33)=WARP_CARPET_DOWN`；烟墨 `(23,3)=WARP_CARPET_DOWN`、`(3,25)=WARP_CARPET_DOWN`。

**REF-364 活动工程**：`constants/johto_fixed_map_ids.asm`（ID99/190）、`data/johto_header_descriptors.asm`、`data/johto_stable_id_slots.asm`（只含 ID190）、`engine/johto_pilot_runtime.asm`（四路注册、两室外出口碰撞）、`engine/johto_dark_cave_stage2.asm`（role7/Surf 被封）、`data/johto_dark_cave_stage/DarkCaveVioletEntrance.events.gold.asm`、`docs/REF349_DARK_CAVE_VIOLET_STAGE1.md`、`docs/REF349_DARK_CAVE_VIOLET_STAGE2.md`。

**验证边界**：本次只做源数据/原版格子核对和项目待办维护，没有修改任何游戏功能代码，没有模拟器执行、ROM 构建或手机验收，不代 Git Commit/Push。
