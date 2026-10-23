> **2026-10-23 正式验收更新**：第七轮家具互动补丁经用户实机复测，反馈“都试过了，没问题”。此文档前文各轮的“尚待手机确认”是当时阶段性记录，现以本条为当前民宅功能验收状态。仅收音机 Gold `MapRadio` 动态频道／音频属于后续工程；不将其它未建房屋和冰雪通路标为完成。正式版本更新为 `OLIV-5.62.241`，AI 未编译/链接 ROM，完整静态发布门禁本次超时。

# OLIV-5.62.241｜城都室内开发路线与首间民宅实施计划（开发阶段）

> 日期：2026-10-23；工程：金银；本轮起点：完整工程 ZIP 的干净 HEAD `54d97bf2d86f3a081af10066ed765df1b6b74839`。本文件是 **开发计划**，不是提交日志、正式清理包或已验收报告。
>
> **开发约束**：只以最新确认的源码作为补丁基准；不应用既往三批未确认重构，不自行编译 ROM / Commit / Push，不在资源、Warp 与动态验收完成前开放入口。

## 1. 为什么从室内样板开始

目前 46 张已登记地图以及道路／门房能够形成一条室外路网，但很多城镇建筑入口保持关闭，冰雪通路和部分洞穴楼层尚未接入。继续做“旧／新地图写法统一”收益很小。实际目标应是建立 **Gold 室内资源 → RPP 地图身份和图块 → 碰撞和 Warp → NPC／文本 → 进出及存读档 → 回归测试** 的可重用闭环。该闭环先用于一间简单民宅，再用于冰雪通路五张地图和其余建筑。

## 2. 已存在的工具：哪些可以复用、哪些不能自动安装

| 位置 | 已实现的能力 | 此时的限制 |
|---|---|---|
| `tools/johto_indoor_pipeline.py` | Gold→RPP 室内统一离线候选流水线，调用 Warp、图块、碰撞、资源、VRAM、登记审核 | 已登记目标才可走完整路径；并非运行时移植器；没有 NPC 自动移植 |
| `tools/johto_indoor_tiles_converter.py` | Gold `.blk` 逐像素区块对照；不能复用时制作隔离新 tileset 候选 | 不能把原版 block ID 或像素吻合等同可直接拷贝到游戏 |
| `tools/johto_indoor_collision_adapter.py` | Gold 四象限碰撞与 RPP 通行图块核对 | 特殊门砖／地毯仍需运行时方向规则与动态验证 |
| `tools/johto_indoor_registration_generator.py` | 检查已登记目标 Header、Bank、地图宽高、include | 不负责分配稳定 ID、写 Warp 或补齐引擎 |
| `tools/johto_indoor_batch.py`／`johto_indoor_manifest.py` | 批量预审核和来源指纹 | 批量模式要求目标已注册，不能生成未注册民宅 |
| `tools/johto_indoor_release_audit.py` | 离线工具回归门禁 | 工具 PASS 不代表新房屋可以进出，也不代表 ROM 已编译 |
| 已有运行时 `CheckWarpsNoCollisionLoop`、`CheckWarpsCollision`、`GetJohtoWarpArrivalStep` 等 | 已支撑多张已开放门房及联合洞穴一层 | 民宅是否可复用须按 Gold 实体 DOOR、实际踏格与到达落点逐项复核 |

文档入口：`tools/JOHTO_INDOOR_TOOLCHAIN_zh.md`、`docs/JOHTO_GATEHOUSE_READ_FIRST.md`、根目录 `TODO.md` 与 `RPP_DEVELOPMENT_PITFALLS.md`。

## 3. 首个样板：浅葱市 OlivinePunishmentSpeechHouse（运行时代码已接入 DEV，未实机验收）

**Gold 原始证据（来自用户提供的 `pokegold-master`）：**

- `data/maps/maps.asm`：房屋使用 `TILESET_HOUSE`；`constants/map_constants.asm`：4×4 个 32×32 区块。
- `data/maps/blocks.asm`：本房屋重用 `maps/House1.blk`，不是名为房屋的独立 `.blk`。
- `maps/OlivineCity.asm`：室外实体门位置 `(x=29,y=11)`，该建筑是 **第 5 条** Gold Warp；其它十个城镇入口仍封闭。
- `maps/OlivinePunishmentSpeechHouse.asm`：室内两条出口 `(2,7)` 与 `(3,7)`，都指向 `OLIVINE_CITY` 的 Gold Warp #5；两名 NPC 在 `(1,2)` 与 `(5,5)`，书架互动在 `(0,1)`、`(1,1)`。
- 正式 `.240` 基线的 `data/mapObjects/JohtoOlivineCity.asm`：**零条**开放 Warp，未在 `data/mapHeaders/` 登记对应民宅。禁止只把室外 Warp 打开并指向空地图。
- RPP 旧有 Kanto `HOUSE` 与 Gold `TILESET_HOUSE` 是**不同来源**；图形名称、碰撞、调色与行为不能默认为同一资源。RPP 图集命名是 `gfx/tilesets/house.t2.png`（此轮工具应能识别），而非 `house.png`。

## 4. 分阶段实施（每一阶段都可单独回退）

### 阶段 A：用现有室内工具制作可审计的“未注册民宅”预备包（本轮开始）

1. 让预备流程支持 **普通房屋**，报告根据 Gold 原版动态列出室内 → 室外对应 Warp，且明确 Gold `1-based` / RPP `0-based` 的差别；不能保留误导性的“34号道路未连接”固定文案。
2. 根据 RPP 真实存在的图集文件选择 `house.t2.png`，不把未知候选或其他 tileset 当成可复用图形。
3. 原有图块、碰撞、色板、固定 VRAM 窗口、资源预算全部运行，输出隔离文件与 JSON；新结果注明 `import_allowed=false`、`runtime_warp_enabled=false`。
4. 增加对应的回归测试：目标未注册、两条原版出口与城市 Warp #5、图集选择、已注册门房不得绕过全面审核、原始室外门保持关闭。

**交付准则**：计划文档、可复现的命令与离线候选；不得声称已经生成可玩的房屋。

### 阶段 B：民宅运行时真实接入（阶段 A 通过后）

1. 审阅预备包的 `art_missing`、碰撞差异与图块集预算；确定是否需新增**独立**城都房屋 Tileset，而不是覆盖 Kanto `HOUSE` 或已验收的 `JOHTO_GATE`。
2. 审查并分配稳定 local ID、active slot、Header 与 ROM Bank；同步地图登记及审计合同；不重新排列已有 46 张地图的 ID。
3. 在 `main.asm`、对应地图 Header/Objects/Scripts、`.blk`、图像和色板中接入真实资源；按原版踏格/出门触发和自动步进设置室外城镇 Warp #5 和室内双出口。
4. 开放这座房屋的真实 NPC／台词与两个书架互动（若 RPP 现有引擎暂时不支持，要明确记录阻断并最小化扩展）；其它城镇入口保持关闭。
5. 不扩大其他地图的碰撞、Warp 和 Bank 重构面积。

**验收**：Header/Bank/tileset/碰撞/Palette 均可审核，房内两格出口回同一城市门口，任何未分配资源不得有“假 Warp”。

### 阶段 C：退房与旧地图回归

- 玩家在 `(29,11)` 从室外进入；房内两个门格都可正常退出，回到原室外；离开后原地反向重进；门旁不会误触发。
- 两名 NPC 与书架可互动，互动后菜单和移动不被锁住；出门前后音乐、地图名与配色正确。
- 用户使用实际 ROM 在手机上核对，另行检查游戏允许情况下的室内存档／读档／Continue。
- 29↔46 门房、Route32↔联合洞穴、Route38 西门房、Route43 门房、相邻道路的跨 Bank 预览均不退化。

**状态门槛**：离线脚本/静态测试为 `STATIC_ONLY`，ROM/link 检验与手机确认均须用户提供，不冒称通过。

### 阶段 D：复制流程到冰雪通路和其余建筑

1. 冰雪通路五图：先核清每层 Gold 图块/碰撞/Warp，单独处理冰面滑行、推石落穴、跨层回程和道具；五张图全部互通后再打开 Route44／烟墨市的洞口。
2. 龙穴、黑暗洞穴、联合洞穴后续楼层；简单民宅／商店优先按复用流程逐个开门，复杂道馆与剧情最后按依赖加入。
3. 每一张图复用阶段 A/B/C 证明链，不靠一次性批量开放未登记入口。

## 5. 本轮完成项／下一次闸门

- [x] 阅读 `.240` 实际源码与室内脚本，确认已有完整离线工具链及其“只读候选”性质。
- [x] 确认 Gold 首间民宅的地图、图块来源、两格出口、NPC、书架和原始室外门。
- [x] 修正普通民宅离线预备入口，生成单房候选并完成 22 项室内工具链定向测试；**不代表运行时已接入**。
- [x] 首轮报告：Gold 使用 12 种 32×32 区块、51 种 8×8 图块；现有 RPP `HOUSE` 对照仅 **0/12 像素精确匹配**。离线生成 4×4 `.blk`、含黑边的隔离 `.bst` 和 96-tile 2bpp（1,536 字节）候选。图块候选可用**不等于**碰撞、调色、ROM Bank、NPC 或动态进出已通过。
- [x] DEV 运行时源码已登记独立 House Tileset、地图 ID34→slot46、Gold DOOR 精确碰撞和双出口；资源空间仍需用户 ROM/link 验证。
- [ ] 新房屋正式接入与 ROM/手机回归（未验收前不视为完成）。

**补丁规范**：本轮若进入工具或功能代码改动，按项目要求提供基于当前干净 `.240` HEAD 的增量/全量替代补丁，并在一个 ZIP 中交付。开发阶段不提供正式清理三件套或 Git 提交日志。由于目前当前开发状态＝干净 HEAD，两份补丁可能字节完全相同；严禁叠加应用。

## 8. 2026-10-23 第四轮：用户报错后的纠正（源码和补丁，不编译）

- **补丁基线纠正**：最初上传的正式工程 ZIP 中并无本计划文件。此前本地副本先生成了该文件，再拿副本生成“全量补丁”，导致错误地输出“修改已有 docs 文件”补丁。新全量补丁必须从原始 ZIP 内容生成，并在 diff 中以 `/dev/null -> docs/JOHTO_INDOOR_HOUSE_PLAN_240_DEV.md` 创建文件；不再把本地已生成文档误当成原始 HEAD 内容。
- **屋顶表两处断言**：新增的民宅为第 47 张活动地图；`color/loadpalettes.asm` 的 `JohtoGoldDayRoofGroups` 和 `engine/overworld/johto_goldenrod_roof_gfx.asm` 的 `JohtoRoofGroupForLocalMap` 原先各仅 46 字节，导致 `== NUM_JOHTO_MAPS` 两处汇编断言失败。现在在各表结尾追加 `$ff`：新室内地图没有屋顶分组；不改变原有 46 张地图的值。
- **静态回归**：屋顶 Gold 参考审核与定向测试覆盖 47 项长度、最后两项 `$ff`，并通过故障注入确认删掉追加的末尾项会失败。源码检查不替代 RGBDS 编译、Bank 空间或手机实测。
- **应用原则**：增量修复补丁只适用于先前运行时代码已应用、地图计数为 47、但本计划文件仍缺失的工作树；全量修复补丁只适用于最初干净 `.240` ZIP。两者二选一，不能叠加；从第一阶段到第三阶段的历史错误补丁不要继续重复应用。


## 第五轮：Gold NPC 外观与移动开发候选（2026-10-23）

- 来源：用户金版与 RPP 实机视频对照；Gold `maps/OlivinePunishmentSpeechHouse.asm`。
- Gold 实际事件：父亲 `(1,2)` 为 `SPRITE_POKEFAN_M` + `SPINRANDOM_SLOW`；女儿 `(5,5)` 为 `SPRITE_LASS` + `WALK_LEFT_RIGHT`、横向范围 2；背景事件仅两个书架 `(0,1)` 和 `(1,1)`。先前视频中提到的镜子／收音机／地图不属于这张 Gold 房屋的注册事件，不能凭其他场景片段加入。
- 两名 Gold 原版精灵 PNG 逐字节隔离放在 `gfx/sprites/johto_pokefan_m.png`、`johto_lass.png`。保留老 0x01～0x63 人物图形 ID（原文件尾部注释有一位偏差，以 const 实际递增值为准），不替换关东共用精灵。新增 0x64／0x65，并将其作为 **12-tile** 人物处理。
- 新的室内专用 sprite set `$0c`，城都其它室外地图继续用 `$0b`。Gold 父亲棕色、女儿红色，采用显式调色分配。女儿使用 RPP 原生 `WALK, 2`（左右移动）。
- 父亲保持原位置，RPP `STAY, NONE` 在引擎中允许随机改变面向但禁止位移；Gold 的 `SPINRANDOM_SLOW` 时间节奏仍须实机对照，尚未承诺完全一致。
- 不更改 47 张地图数、34 号本地地图 ID、入口、双出口、碰撞、文本、书架及旧道路功能。
- 离线检查：`python tools/johto_olivine_house_sprite_audit.py --rpp . --gold "$JOHTO_GOLD_SOURCE"`，并跑 `tools/tests/test_johto_olivine_house_sprite_parity_240dev.py`。审核不等于 RGBDS 汇编／链接、手机验证。
- 实机下一步：确认两位 NPC 图形与颜色、女儿只左右移动、对话后贴图恢复、原有两处书架、两条出口均可返回街道且立即反向重进。

## 第六轮（2026-10-23）：女孩能转头但不能走动——NPC 与玩家碰撞分流修复

用户手机录像反馈：Gold Lass 在房间里只左右张望、不迈步。确认为**两条碰撞路径不同**：Gold 地图的 8x8 位置遮罩已允许玩家走在粉色地板上；但 `engine/overworld/movement.asm:CanWalkOntoTile` 的 NPC 走动使用的是 `wTilesetCollisionPtr`，而 `gfx/tilesets/johto_house.tilecoll` 原本只有 `$ff`，意味着 NPC 无任何可走目标。`WALK, 2` 仅将 NPC 的随机尝试限制为左右方向，不自动放行碰撞。

- 只对隔离的 `JOHTO_HOUSE` 的 `.tilecoll` 增加 `$01,$10,$12,$ff`。从民宅的 4x4 `.blk`、16-byte/block `.bst`、8x8 Gold 格子遮罩对照，这三个 **NPC 脚下左下 8x8 graphic IDs** 均只位于当前未阻挡格，桌子、墙、花盆等阻挡格没有白名单图块；女儿 `(5,5)` 左右相邻格落脚均为 `$01`。
- `WALK, 2`、女儿身份／位置、父亲不走动、双出口、四段文本及入口／Bank 保持原样；室外图块碰撞白名单完全不动。
- 新增 `tools/johto_olivine_house_npc_floor_audit.py` 和 6 项正反向测试。手机真实走动、走动范围是否完全等价 Gold 的 `range_x=2` **仍待用户验证**；RPP 旧引擎的 `2` 表示水平走动，不是完全等价于 Gold 的步行范围半径，因此不能声称逐帧一致。
- **地图、镜子、收音机的互动说明**：此房屋的 Gold `maps/OlivinePunishmentSpeechHouse.asm` 只有 `(0,1)` 杂志书架、`(1,1)` 绘本书架两处 `bg_event`；蓝色壁饰并没有 Town Map 的事件。这里不随意加入不存在的原版互动；其它房屋的地图／收音机需按各自原版脚本单独开发。
- 开发状态：源码与静态检查候选。按照用户要求不由 AI 编译 ROM，不自动 Git 提交；手机走动行为需用户在正确应用本轮修复后确认。

## 第七轮（2026-10-23）：Gold House1 普通家具碰撞互动接入（纠正第六轮结论）

**第六轮报告里“蓝色画框是装饰、没有 Town Map 事件”的判断不准确。** Gold `maps/OlivinePunishmentSpeechHouse.asm` 只声明两处**显式背景事件**，但 `data/tilesets/house_collision.asm` + `data/collision/collision_stdscripts.asm` 还声明了**通过家具格碰撞语义自动触发的通用事件**，不能只看房间脚本。

Gold `maps/House1.blk`（4x4 block、对应 8x8 Gold 16x16 格）逐格计算：墙上地图 `(x3,y0)`、窗户 `(x5,y0)`、电视 `(x2,y1)`、收音机 `(x7,y1)`，另外两个书架 `(x0,y1)`、`(x1,y1)` 是原版显式背景事件。原版父亲固定 `(1,2)`，会挡住右侧书架的正常正面访问；保留这种限制，不穿 NPC、不强开事件。左侧书架从 `(0,2)` 朝上可以交互。

本轮执行：

- `engine/overworld/johto_indoor_furniture.asm` 是**可复用的室内家具 A 键查询核心**（独立可重定位 ROMX 节），只在 `wCurMap=$FC`、`wCurRegion=Johto`、本地地图编号 `34`、图块集 `JOHTO_HOUSE` 同时满足时，才按玩家面前一个 16x16 Gold 格匹配独立房间表。不是全图任何同形花纹都可激活；其他室外、门房、关东 HOUSE 不改。
- 原 `PrintBookshelfText` 在旧通用书架识别前尝试室内家具，正确返回“已处理／未处理”，保留 hidden object 优先级、NPC／背景事件及其它 Tileset 原有行为。墙上地图复用已有 `DisplayTownMap`（这间房在索引表中映射 Olivine City）。窗口复用 `MyReflectionText`，电视显示普通短文字。
- 收音机提供按 A 的**普通文本回应**（暂未移植 Gold `MapRadio` 的频道、时间、随剧情变化的广播内容或实际广播音频），不能标成完整 Gold 收音机等价；这条留作后续室内系统专项。没有新增剧情旗标、广播塔剧情，也没有猜造节目。
- 两个书架文本、父亲女儿位置和行走配置、双门 Warp、屋内碰撞、独立图块、地图编号、音乐均不改。完整广播和其它室内扩展继续作为后续工作。
- 新增 `tools/johto_house_furniture_audit.py` 和 `tools/tests/test_johto_house_furniture_240dev.py`：来源是 Gold 实际 `House1.blk` 与 64 条 collision 四象限，加上原版人物／书架事件。包含误写位置、删地图界面、误移父亲及覆盖书架的故障注入测试。

**交付范围／验收**：本轮是源码补丁与源级验证，不包含 ROM 编译、链接、手机实机及动态广播。测试手机时分别站在地图正下方 `(3,1)`、窗户正下方 `(5,1)`、电视正下方 `(2,2)`、收音机正下方 `(7,2)`，朝上按 A；也可在 `(6,1)` 朝右检查收音机。左书架 `(0,2)` 朝上；右书架 `(1,2)` 由 NPC 挡住不应绕过。地图检查退回后仍能移动、NPC 和两个出口不受影响。
