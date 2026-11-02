# TODO｜城都 Town Map（城镇地图菜单）与关都原版 Town Map 功能对齐

**范围纠正（CLEAN-5.62.325）**：这里的“城镇地图”专指玩家通过 `TOWN_MAP` 道具看到的**地图菜单**，并延伸核对与它共享图形/坐标/状态的 Fly 选点页、图鉴栖息地页。**不是**47 张野外地图的碰撞、门房、Surf、跳崖或剧情功能对比。现阶段只查差异、列证据、必要时另开修复任务；这次 CLEAN 不改游戏 ASM。

**当前事实**：REF-5.62.325、城都活动地图 47 张；**Gold 地标浏览表 45 项**，它与活动地图槽不是一回事；Fly 候选城市表为 **11 项**，且必须活动、已访问才可选。不能把这三个数字混为“缺少的地图数量”。以下结论为当前源码对照，未完成手机端功能全场景验收。

## A. 已由当前源码确认的实现差别（不自动判定为 Bug）

| 功能 | 关都原生逻辑 | 城都现有逻辑 | 初步结论与核查入口 |
|---|---|---|---|
| 地图资源/进入菜单 | `DisplayTownMap` → `LoadTownMap` 使用 Kanto 图块、tilemap | 根据 `wCurMap == $FC` 与 `wCurRegion` 选择 Johto 图块及 tilemap | **有实现，待核 UI 一致性**；`engine/town_map.asm:DisplayTownMap,LoadTownMap` |
| 地图浏览表与名称 | `TownMapOrder` + `LoadTownMapEntry`，并有 `InternalMapEntries`/`ExternalMapEntries` | `JohtoBrowseEntries` 的 Gold 45 地标，`LoadJohtoBrowseEntry` 将名称拷入 `wBuffer`，上下循环浏览 | **有实现，菜单数据体系不同**；`engine/johto_pilot_town_map_browse.asm` |
| 当前玩家标记 | `GetFlyTownMapPlayerMap` + `DrawPlayerOrBirdSprite` | `JohtoPilotGetTownMapLandmark` + `DrawJohtoPilotFlyPlayerMarker`，映射稳定 ID/活动槽 | **有实现，但返回/Bank 路径不同**；`engine/town_map.asm`、`engine/fly_town_map_helpers.asm` |
| 普通 Town Map 的 START | 按 `wLastBlackoutMap` 跳到上次恢复地点对应的浏览位置（含特殊中心） | 直接将浏览索引清零，跳到**若叶镇** | **确认不等价**；须决定是否按关都 START 行为补齐；`engine/town_map.asm:.pressedStart` |
| 普通 Town Map 的 SELECT | 复位到关都浏览表开头（真新镇） | 复位到城都 45 地标表开头（若叶镇） | **语义基本对应**，核验提示/边界 |
| 普通 Town Map 的上下浏览 | `TownMapOrder` 长度内循环 | Gold 45 地标内循环，允许浏览尚未开放的地标 | **设计差异，未必是缺陷**；须确认这是你要的 Gold 风格 |
| Fly 选点与访问 | `BuildFlyLocationsList`、城市访问标志，左右可切换已解锁的特殊目的地轴 | `LoadJohtoPilotFlyTownMap` 使用 11 行城都城市表+活跃/访问事件判断，主要按上下选择；START/SELECT 回第一个已访问城市 | **确定不同交互模型**；是否需要与关都左右特殊轴/START 上次恢复地等价待定义 |
| 图鉴栖息地 Town Map | `LoadTownMap_Nest` 加载 Kanto Town Map 并标记分布 | 现有入口将 `wFlyLocationsAxis` 清零并加载 Kanto Town Map，未看到 Johto 栖息地地图分支 | **已发现显式未对齐入口**；但野生遭遇/图鉴分布是否计划扩城都需另核需求，不能直接当 Bug |
| 开关菜单与名称 Bank | 名称指针与绘制在关都既有路径 | Johto 用跨 Bank 安全拷贝到 `wBuffer`；历史曾出现乱码/退菜单死机，FIX-298 修复 | **需要设备回归**；重点连续打开、浏览、退出、重新移动与存读档 |

## B. 下一轮 Town Map 专项排查清单（按照菜单功能，不扩展到野外走图）

- [ ] **P0：画面/控件清单**：同一存档分别在关都、城都打开 `TOWN_MAP`；对比版图、地区标签、当前玩家标记、指针、地名折行/截断、箭头、闪烁节奏、音效。分别录制进入、连续上下滚动、边界回卷、退出。
- [ ] **P0：START / SELECT 行为**：固定测试关都 last blackout 特殊落点、城都若叶镇及其它已访问城市。明确期望是“与关都快捷定位等价”还是“保留 Gold 的城都语义”。**不要未经决定擅自修改游戏操作**。
- [ ] **P0：跨 Bank 名称读写与菜单退出**：特别在圆朱、浅葱、烟墨、Lake、Route44/45/46 打开地图，浏览长名、反复开关、B 返回后移动、再进入 Fly，避免历史 `wBuffer`/`wcd6d` 串用及乱码/死机复发；检查名字字符串长度/终止符与 WRAM 容量。
- [ ] **P0：地图光标和初始地标归属**：建立 47 个活动槽 → Gold 地标 45 项的映射矩阵；门房/建筑应继承邻近地标，不应把 stable ID、active slot、Gold 浏览序号混用。检查进入新区域后的当前标记、玩家标记与浏览光标是否一致。
- [ ] **P1：Fly 城市页**：列举城都 11 项候选目的地与已激活项，逐个测试未到访/已到访/未开放城市、目的地名称、指针位置、成功/取消、飞到后当前地图、菜单返回。关都的左右特殊目的地轴与城都当前无对应入口的差异须列为明确产品选择。
- [ ] **P1：Fly 快捷键语义**：Kanto START last-heal/Teleport shortcut、SELECT 首项、上下左右轴；Johto START/SELECT 第一已访问城市、上下移动。逐一说明功能差异、是否有必要补齐、是否会破坏现有 Fly 游戏语义。
- [ ] **P1：图鉴栖息地 Town Map**：记录目前 `LoadTownMap_Nest` 总是选择关都底图；确认城都野生资料/图鉴需求后再决定支持城都位置、双地区切换或维持 Kanto-only；不凭 Gold 原版有此菜单便直接新增遭遇数据。
- [ ] **P1：入口兼容**：普通道具 Town Map、Fly Town Map、图鉴 Nest Town Map 的共同资源与各自 `wFlyLocationsAxis`、`hTilesetType`、OAM、wBuffer 清理关系；覆盖异常退出、关都↔城都往返及 Continue。
- [ ] **P1：审计强制性**：现有主审计已核对 47 槽坐标/名称一致性与 FIX-298 跨 Bank 初始分流，但还没有证明 START、Fly 特殊轴、图鉴底图与 Kanto 行为等价。为已确定需要等价的项目补针对源码执行路径的检查与故障注入；不以“表长正确”作为 UI 全部功能正确。

## C. 输出物与判定标准

每项交付一行差异矩阵：`菜单/入口 | Kanto 行为/代码位置 | Johto 行为/代码位置 | 产品期望 | 静态证据 | ROM/手机证据 | 分类 | 优先级`。分类限定为：`已对齐`／`设计上不同`／`已确认的功能缺口`／`尚未验证`。

**已知明确差异至少有三类**：START 快捷定位、Fly 的左右特殊目的地轴、图鉴 Nest 地图入口；它们是否需要修复取决于本项目希望城都 Town Map 对齐哪套交互规范。其他功能如 45 地标浏览、坐标、玩家标记、名称与基本 Fly 已有源码实现，不能笼统说“全都没做”。

检查完成后新增或更新一份 `docs/JOHTO_KANTO_TOWN_MAP_PARITY_REPORT.md`，再决定**单独的 Town Map 功能修复**。不能把此 TODO 混作野外剧情、洞穴地图、地图碰撞、门房或 Field Moves 的需求。

**验证边界**：本页是基于当前源码的差异初查与下一步 TODO，不是全功能实机验收结论；CLEAN-325 ROM 版本与当前运行逻辑不变。
