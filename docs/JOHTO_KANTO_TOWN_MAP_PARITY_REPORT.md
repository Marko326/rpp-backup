# DEV-330｜Town Map 菜单功能差异矩阵（REF-5.62.325 源码调查）

> **状态：开发阶段静态研究，不是修改菜单操作，也不是设备验收。** 游戏版本仍为 `REF-5.62.325`。本页对比 RPP 原生关都 Town Map 与当前城都扩展菜单；Gold 只用来核对城都 45 项地标的顺序和坐标。没有重做 47 张野外地图的碰撞、Warp、Surf、剧情或开放地图。

## DEV-331 更新：名称复制的运行时保护（REF-5.62.326）

- 在不改变三个待产品决定的菜单操作前提下，`engine/johto_pilot_town_map_browse.asm:LoadJohtoBrowseEntry` 新增明确的 **29 字符上限 + 末尾 `@`**，总写入不超过 30 字节 `wBuffer`；正常 45 个地标的文字字节与显示结果不变。额外保存/恢复 `BC`，维持直接调用者原本的寄存器状态；`DE` 继续恢复为坐标。
- 原 DEV-330 检查仅能阻挡静态地标名称超长，现由 `johto_town_map_name_buffer_capacity` 同时检查实际 ASM 截断/终止/栈恢复路径，并新增越界计数、无条件回环、错条件跳转、终止符越界、栈恢复丢失等负向故障注入。
- 这是**运行时容错修补，不是 Town Map 交互规范变更**：普通 START、Fly START/左右轴、图鉴 Nest 的产品选择依旧待定；不能据此声称所有菜单在 ROM/手机中已验收。版本文字只从 `REF-325` 更新为等长 `REF-326`，不新增 ROM0 逻辑。

## 证据范围与判定口径

- 源码基线：用户 `REF-325.zip`，导出声明分支 `常规功能备份`，干净 HEAD `300e0a4c4afece275db40a09558b5810d7deb8f4`。ZIP 不含完整 `.git`，这里不声称联网核对 Push。
- 核对范围：`engine/town_map.asm`、`engine/johto_pilot_town_map_browse.asm`、`engine/johto_pilot_fly_map.asm`、`engine/fly_town_map_helpers.asm`、`data/town_map_order.asm`、`engine/menu/pokedex.asm`、`engine/items/items.asm`、`wram.asm`、当前静态审计，以及交接包 `Gold/pokegold-master/data/maps/landmarks.asm`。
- 下表“静态通过”只证明特定源码表或分支满足约束，不代表 ROM 链接或手机/模拟器画面通过。没有本轮手机录像，**所有 ROM/手机证据均为“未取得”**。
- 分类约定：`已对齐` 仅用于存在对应源码实现且合同可证明的局部语义；`设计上不同` 是已查出的交互分歧，不自动是 Bug；`已确认的功能缺口` 需要产品目标明确后才能给出；`尚未验证` 表示源码存在但尚不足以认定等价。

## 逐入口／逐操作差异矩阵

| 菜单／入口 | 关都行为／代码位置 | 城都行为／代码位置 | 产品期望 | 静态证据 | ROM／手机证据 | 分类 | 优先级 |
| --- | --- | --- | --- | --- | --- | --- | --- |
| TOWN_MAP 道具入口 | `engine/items/items.asm:ItemUseTownMap` 进入 `DisplayTownMap`；关都图形 | 相同入口；`town_map.asm:DisplayTownMap` 按 `$FC` + `MAP_REGION_JOHTO` 选择城都 | 两个地区均可进入／退出；美术按地区不同 | 已核对地区条件与 `LoadTownMap` 两组图形指针 | 未取得 | 尚未验证 | P0 |
| 初始位置与玩家标记 | `GetFlyTownMapPlayerMap`、`DrawPlayerOrBirdSprite` | `JohtoPilotGetTownMapLandmark` → `LoadJohtoBrowseEntry` → `DrawJohtoPilotFlyPlayerMarker` | 显示所在区域而不误用稳定 ID／密集槽／Gold 序号 | 47 活动槽地标映射、坐标与名称由主审计核对；附录逐项列出 | 未取得 | 已对齐（静态映射） | P0 |
| 地标上下滚动／回卷 | `TownMapOrder` 和 `LoadTownMapEntry`，按表长回卷 | Gold 45 条独立 `JohtoBrowseEntries` 和 `LoadJohtoBrowseEntry`，按 45 回卷 | 城都是否允许浏览未开放地标？需维持或决定更改 | Gold 45 地标顺序、坐标逐项匹配（Gold `x+8`/`y+16` → RPP `Y,X`）；开放活动槽数不是地标数 | 未取得 | 设计上不同（资料表） | P0 |
| 普通地图 START | 使用 `wLastBlackoutMap` 定位上次恢复地；Route4/Route10 有特殊锚点：`town_map.asm:.kantoStartShortcut` | `town_map.asm:.pressedStart` 在 Johto 分支直接设索引 0（若叶镇） | **待产品确定**：按关都最近恢复地语义，还是保留若叶镇 | 实际指令分流已确认，非模拟推断 | 未取得 | 设计上不同 | P0／待决策 |
| 普通地图 SELECT | `town_map.asm:.pressedSelect` 返回真新镇表首 | 同一 `.pressedSelect` 返回若叶镇表首 | SELECT 回地区表首 | 共用一处处理，索引清零 | 未取得 | 已对齐（语义） | P1 |
| 光标、地名和画面 | 本 Bank 名称通过 `CopyTownMapDisplayName` 复制至 `wcd6d` | 跨 Bank 调用 `LoadJohtoBrowseEntry`，在原 Bank 内复制到 `wBuffer`，再绘制光标和名称 | 名称、箭头和 OAM 不乱码、不串台、不越界 | 主审计保护 FIX-298 初始分支；DEV-330 增强 30B 字符串与拷贝目标静态守卫；最长实际名称 17B（含 `@`） | 未取得（需圆朱／浅葱长名复测） | 已对齐（有限静态合同） | P0 |
| Fly 入口 | `town_map.asm:LoadTownMap_Fly` → Kanto `BuildFlyLocationsList` | `$FC` + Johto 分派到 `LoadJohtoPilotFlyTownMap` | 已访问且活动的城都目的地可选 | 城都表长 11，`GetJohtoActiveSlot` + `wEventFlags` 解锁双重守卫 | 未取得 | 已对齐（存在可选功能） | P1 |
| Fly 上下选择／取消 | 关都列表 `wBuffer`，上下略过 `$fe` 未访问项，A 确认、B 取消 | 11 行城都表内上下寻找已解锁项；A 写 `JOHTO_PILOT_FLY_SELECTOR`，B 退出 | 保留目的地约束，退出后不得误飞 | `johto_pilot_fly_map.asm:.next/.previous/.isUnlocked/.accept/.cancel` 已查 | 未取得 | 尚未验证 | P1 |
| Fly START | `town_map.asm:.pressedStart` → `FindFlyTeleportShortcut`，尝试 last-heal/Teleport 对应目的地 | `johto_pilot_fly_map.asm:.input` 分支将索引设 0，再找第一个已解锁点 | **待产品确定**是否实现 Teleport 快捷定位 | 城都无使用 `FindFlyTeleportShortcut` 的分支 | 未取得 | 设计上不同 | P1／待决策 |
| Fly SELECT | 关都回城市轴并找第一个可用城市 | 城都和 START 一样找第一个已访问城都项 | 城都是否保留统一的首可用点动作？ | `JohtoPilotFlyTownMap:.input/.findForward` | 未取得 | 设计上不同（快捷键差异） | P1／待决策 |
| Fly LEFT/RIGHT 特殊目的地轴 | `town_map.asm:.pressedLeftOrRight` 和 `BuildSpecialFlyLocationsListFromCityAnchor` | 城都输入掩码仅 `A/B/UP/DOWN`，无左右特殊轴 | **待产品确定**：复用关都特殊目的地、建设城都特殊轴，或明确不支持 | 两侧输入掩码和分派已核对 | 未取得 | 设计上不同 | P1／待决策 |
| 图鉴栖息地 Nest | `town_map.asm:LoadTownMap_Nest` → `DisplayWildLocations`，Kanto 底图 | 进入同一 `LoadTownMap_Nest` 时总是把 `wFlyLocationsAxis` 设为 0，故当前仍绘制 Kanto 底图 | **待产品确定**：维持关都图鉴分布；或单独支持城都／双区域；须先确定遇敌数据需求 | 有明确 `xor a`／`ld [wFlyLocationsAxis],a`，没有 Nest Johto 分支 | 未取得 | 设计上不同 | P1／待决策 |
| 菜单退出和共享 WRAM | `ExitTownMap` 白屏、恢复人物图块、地图数据和调色板 | 普通城都地图复用 `ExitTownMap`；Fly／Nest 另有返回路径，涉及 `wFlyLocationsAxis` 与 scratch WRAM | B 退出后移动正常、重复进入、Fly/Nest 前后无残影 | 代码入口和恢复调用已定位；无法仅凭路径存在证明视频帧/WRAM 安全 | 未取得 | 尚未验证 | P0 |

## Gold 原版地标逐项核对

Gold `data/maps/landmarks.asm` 以 `landmark x,y,name` 填充坐标，宏会把 x 加 8、y 加 16。RPP 的城都表是 `db Y,X; dw name`。本轮用原版 `Landmarks:` 中 SpecialMapName 后的前 45 项逐项计算，与 `JohtoBrowseEntries` 的 45 对 `(Y,X)` 全部相等；这些地标可在普通地图中浏览，**不能**直接当成 47 张已开放地图或 11 个可飞地点。

`wBuffer` 当前声明为 30 字节共用 scratch（`wram.asm:wBuffer`），`LoadJohtoBrowseEntry` 以 `@` 为停止条件而无独立长度判断。当前 45 条名字最长 17 字节，静态满足容量。新的主审计 `johto_town_map_name_buffer_capacity` 阻止今后增加超过 30 字节或缺少 `@` 的名字，并确保依旧向 `wBuffer` 复制；仍须注意 **30 字节是全局共享暂存区，不保证其他调用路径的生命周期安全**。

## 11 个 Fly 候选城市／地点

`JohtoPilotFlyDestinations` 的实际顺序：若叶镇、吉花市、桔梗市、桧皮镇、满金市、圆朱市、浅葱市、卡吉镇、湛蓝市、愤怒之湖、烟墨市。这里的“11 项”既含城镇，也含愤怒之湖，且只有 stable ID 活动、访问事件位有效时才可选；不意味着 11 项都已由同一份存档解锁。

## 下一步操作决策与最小实测

1. **先明确三项菜单语义**：普通 Town Map 的 START 是最近恢复地还是若叶镇；Fly START 是否尝试最近恢复地，以及 Johto 是否开放 LEFT/RIGHT 特殊轴；Nest 是否需要城都栖息地支持。此三项不应在缺乏产品选择时直接更改游戏逻辑。
2. **设备最小复测**：先用同一存档在 Kanto 与 Johto 打开道具地图，验证初始标记、UP/DOWN 45 条回卷、START/SELECT、B 退出；城都圆朱/浅葱/烟墨反复开关，包含长地名；然后在可用 Fly 页上下选择、取消与确认一次，最后从图鉴进入 Nest 并退出。无需重复 47 张野外地图通行验收。
3. **如果决定改交互**：另开独立 Town Map 功能版本与测试补丁，修改 ROMX 为主；本版本 ROM0 仅有 64B 的附带红版 MAP 下限，任何新增运行时代码须经 Red/Blue/TEST 本机构建与新 MAP 验证。此轮不编译 ROM、不执行 Git Commit/Push。

## 附录：47 活动槽 → Gold 45 地标索引

本表以 `tools/johto_surf_coverage_audit.py:read_active_maps` 提取的稳定 ID、地图名和 `engine/fly_town_map_helpers.asm:JohtoPilotTownMapBrowseIndexBySlot` 原始索引拼接；编号从 0 起。室内／门房继承邻近地标不是额外地图点。

| 活动槽 | 稳定 ID | 当前地图 | 地标索引 | 地标名 |
| ---: | ---: | --- | ---: | --- |
| 0 | 0 | `NewBarkTown` | 0 | New Bark Town |
| 1 | 1 | `Route29` | 1 | Route 29 |
| 2 | 2 | `CherrygroveCity` | 2 | Cherrygrove City |
| 3 | 3 | `Route30` | 3 | Route 30 |
| 4 | 4 | `Route31` | 4 | Route 31 |
| 5 | 125 | `GuideGentsHouse` | 2 | Cherrygrove City |
| 6 | 5 | `VioletCity` | 5 | Violet City |
| 7 | 6 | `Route31VioletGate` | 4 | Route 31 |
| 8 | 7 | `Route32` | 7 | Route 32 |
| 9 | 102 | `Route32RuinsOfAlphGate` | 7 | Route 32 |
| 10 | 20 | `RuinsOfAlphOutside` | 8 | Ruins Of Alph |
| 11 | 19 | `Route36RuinsOfAlphGate` | 19 | Route 36 |
| 12 | 16 | `Route36` | 19 | Route 36 |
| 13 | 8 | `UnionCave1F` | 9 | Union Cave |
| 14 | 9 | `Route33` | 10 | Route 33 |
| 15 | 10 | `AzaleaTown` | 11 | Azalea Town |
| 16 | 11 | `IlexForestAzaleaGate` | 11 | Azalea Town |
| 17 | 12 | `IlexForest` | 13 | Ilex Forest |
| 18 | 13 | `Route34IlexForestGate` | 14 | Route 34 |
| 19 | 14 | `Route34` | 14 | Route 34 |
| 20 | 15 | `GoldenrodCity` | 15 | Goldenrod City |
| 21 | 18 | `Route35GoldenrodGate` | 17 | Route 35 |
| 22 | 17 | `Route35` | 17 | Route 35 |
| 23 | 103 | `NationalPark` | 18 | National Park |
| 24 | 104 | `Route35NationalParkGate` | 17 | Route 35 |
| 25 | 105 | `Route36NationalParkGate` | 19 | Route 36 |
| 26 | 21 | `Route37` | 20 | Route 37 |
| 27 | 22 | `EcruteakCity` | 21 | Ecruteak City |
| 28 | 23 | `Route38EcruteakGate` | 24 | Route 38 |
| 29 | 24 | `Route38` | 24 | Route 38 |
| 30 | 25 | `Route39` | 25 | Route 39 |
| 31 | 26 | `OlivineCity` | 26 | Olivine City |
| 32 | 27 | `Route40` | 28 | Route 40 |
| 33 | 28 | `Route41` | 30 | Route 41 |
| 34 | 29 | `CianwoodCity` | 31 | Cianwood City |
| 35 | 62 | `Route42EcruteakGate` | 32 | Route 42 |
| 36 | 63 | `Route42` | 32 | Route 42 |
| 37 | 64 | `MahoganyTown` | 34 | Mahogany Town |
| 38 | 65 | `Route43MahoganyGate` | 34 | Mahogany Town |
| 39 | 67 | `Route43` | 35 | Route 43 |
| 40 | 66 | `Route43Gate` | 35 | Route 43 |
| 41 | 68 | `LakeOfRage` | 36 | Lake of Rage |
| 42 | 69 | `Route44` | 37 | Route 44 |
| 43 | 71 | `BlackthornCity` | 39 | Blackthorn City |
| 44 | 72 | `Route45` | 41 | Route 45 |
| 45 | 73 | `Route46` | 43 | Route 46 |
| 46 | 74 | `Route29Route46Gate` | 1 | Route 29 |
