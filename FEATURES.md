## CLEAN-267｜联合洞窟南口与 Route33 用户验收反馈

- 用户确认进出洞正常、33号路不再花屏、骑车和 Fly 可用；不把未说明完整的“出洞时”反馈解释为已验收全部路线。
- 保留 `FIX-5.62.267` 运行功能、PNG→2bpp 构建规则和用户工作区的 `jp` 指令；本次清理不改变 ROM，未新增地图与剧情。

## FIX-5.62.267｜33号道路图块集加载溢出修复（开发候选）

- 症状：联合洞窟南出口进入 Route33 后整屏花屏；并非 Gold 33号路 `.blk`、PNG 或落点写反。
- 根因：`engine/overworld/tileset_header.asm` 原先以8位移位/加法拼出 `tileset * 12`，`JOHTO_MODERN=32` 时中间进位丢失，实际 `$0080` 而非 `$0180`；读取到错误的 ROM Bank/图块指针。`color/loadpalettes.asm` 又以8位 `sla e`×3 求 `tileset * 8`，ID32 时 `$0000` 而非 `$0100`。**旧回归检查没有把新 Tileset ID 32 送过这两段运行时地址计算。**
- 修复：仅将两处索引改用16位 HL 算术，保留 `.266` 地图资源、Gold碰撞、双向 Warp 和 `.265` 朝向。无新 Bank、新 SRAM、无大范围图形替换。
- 防回归：新增 `tools/tileset_index_preflight_267.py`、`tools/tests/test_tileset_index_267.py`，检查 ID 0–32 及故障注入；注意该检查不模拟 ROM VRAM，不能代替手机验收。
- 交付：增量严格从 `.266` 实际开发候选生成，累计全量从 `.266` 原来声明的干净 HEAD `438046a6ae6a709b656b8f712eeeecefc6259dda` 生成，两份互斥；不编译 ROM、不提交 Git、不更新 `TEST-231`。须由用户本机编译并检查新 MAP／南北口和 Route33 显示。

## MAP-5.62.266｜联合洞窟南出口与33号道路（开发候选）

Gold Union Cave 1F 南 Warp `(17,31)` ↔ Route33 `(11,9)` 已按独立 `JOHTO_MODERN` 资源登记。Route33 采用原版 Gold 10x9 地图、完整现代图块与逐坐标碰撞，不扩大全局道路通行白名单；洞穴进入时保留方向，返回道路自动南移一格。Route33 西侧桧皮镇、32号路南北接壤、洞穴 B1F/B2F、人物与遭遇仍保持关闭。正式编译和手机验收待用户完成。

## FIX-5.62.265｜联合洞穴进洞朝向回归修复（待实机验收）

- 32号道路向北进入1F后，保留引擎现有 UP 朝向，不自动步进，不再强制设置 DOWN。
- 洞内仅在 `(17,3)` 玩家主动朝下碰撞时才出洞；回到32号道路后依旧自动南移一格。
- 保留 `.264` 的 `ExtraWarpCheck`／Carry／`wd736` 出洞前置修复；纠正原有静态审计对错误朝向的要求并增加负例。
- 未开放 Route33、B1F/B2F；不修改其他门房、骑车、Surf 或关都行为。开发补丁待用户本机编译及手机验收。

## FIX-5.62.264｜联合洞穴1F北口前置 Warp 资格检查

- 修复 `.263` 虽已限定向下碰撞出口，却在 `ExtraWarpCheck` 的上游前置判定遗漏洞穴地图、导致始终无法出洞的问题。
- 复用已有 Gold 坐标、方向、地图 ID 的最终检查，不引入额外可触发 Warp 的格子；洞内原地转为朝下且无自动步、洞外安全落点/骑车保持。
- 新增全链路静态轨迹与前置漏项故障注入；用户手机复测仍待完成。

## FIX-5.62.263｜联合洞穴1F 出入口与骑车修复（待用户实机验收）

- Gold 洞内 `(17,3)` 为 **WARP_CARPET_DOWN**，进洞后站在原 Warp 格，不再误作 DOOR 自动走一步。
- 朝下碰洞壁 `(17,4)` 才从该格出到32号路；走上、侧向碰撞或非 Warp 墙不触发。
- 32号路洞口 `(6,79)` 回程后只自动南移到 `(6,80)` 一步；底部 Route33 和 B1F/B2F 仍关闭。
- 恢复旧 NPC 分支已经验证的联合洞穴自行车图块许可，不放宽普通室内门房。
- 新洞穴入口／骑行专项静态审计接入迁移总门禁并通过失败注入。正式版本 FIX-5.62.263，TEST-231 不变。

## FIX-5.62.262｜ROM0 预算与 Gold Surf 运行期分派

- 借鉴旧 NPC 分支的 ROMX 原生地图判定，将8图运动时 Surf 判定由 ROM0 重复分派迁至扩展 Bank `$48`；保留关都原分支、吉花市 Gold FLOOR 岸线例外和洞穴 ROM0 碰撞表。
- 新增 ROM0/Bank `$48` 源码预算及标志 ABI 审计、旧 MAP 过时提示、独立新 MAP 64B 安全余量门禁与故障注入。没有 ROM 编译，不以静态预算替代链接结果。
- 游戏版本 `FIX-5.62.262`，测试版本未改。

## FIX-261｜联合洞穴1F编译断言修复与预检合并（待编译）

- 补齐活动槽位13的原版 Union Cave 音乐项，不更改前13张地图、门房继承音乐、Warp或碰撞。
- 将独立表长 ASSERT 工具并入主工程和地图迁移审计，对 Town Map 项目表、浏览索引表、GSC音乐表进行字节计数与反向故障注入；正式版本 `FIX-5.62.261`，测试版仍为 `TEST-231`。
- 这只是静态修复，不代表已经成功运行 RGBDS/ROM、MAP 空间已更新或手机实测通过。

## UNION-260 (development candidate, not yet device-accepted)

* Union Cave 1F: Route32 ↔ 1F door-only warp, dedicated cave blockset/tileset/collision, Gold 64-cell Surf and exact arrival step. Lower floors and Route33 remain closed.

## MUS-5.62.259｜城都北侧地图、门房音乐与骑车（用户已验收）

- 新增36号道路和遗迹北门房运行地图、原版上下门毯/实体门及单步到达；三座城都活动 GATE 依据真实进入侧继承正在播放的音乐，不主动重启同曲，遗迹北门房允许骑车。
- 北门房的中立地点弹窗修正；自动检测新活动地图地点名称、门房音乐／骑车合同，错误配置会阻止静态审计通过。
- Gold INDOOR 自然公园门房、36号路尚未开放的出口与剧情仍封闭；联合洞穴仅暂存资源，尚未激活。

## MUS-259 — Active Johto gate music/bike preflight (development)

- All three active Johto Gold GATEs inherit the entering side's RBY/GSC music scene without intentionally resetting the live song; north gate now allows bike use, while Gold INDOOR gates and Kanto keep their old restrictions. New migration preflight checks every active gate's policy and has mutation tests. Device verification pending.

## FIX-5.62.258（开发候选）

- 修复遗迹北门房误显示 `Johto` 的地点弹窗；扩充按活动地图自动审计所有道路名称、过渡门房及 Town Map／存档名称的防回归脚本。不改门房 Warp 和自动行走机制。

## MAP-5.62.257（开发候选，未实机验收）

- 新增阿露福遗迹北门房与36号路（安全范围），保持北门房 DOOR 与向下地毯的方向／自动走一步规则，外部未开发道路和胡说树事件暂不开放。

## FIX-256｜阿露福遗迹南侧通路与 Gold 方向跳崖（用户实机验收通过）

- 遗迹外围跳崖使用 Gold 坐标＋面向方向白名单，共16条物理安全的有向跳崖；复合转角保留 DOWN/LEFT 与 DOWN/RIGHT 的不同方向。
- Gold `(9,30)` 虽标记 `HOP_DOWN`，但落点 `(9,32)` 是 WALL，因此明确禁止向下跳；公共跳跃动画和执行器不变。
- 修复 Select 快捷功能调用后误开 Start 菜单的问题；用户报告 FIX-256 实机测试通过。
- 当前活动城都地图增至11张，新增 Route32 遗迹南门房与遗迹外围；南侧双向通路和横向门房已由用户测试。北门房与 Route36 仍未激活。
- 正式游戏版本 `FIX-5.62.256`，测试版本 `TEST-231` 保持。下一阶段竖向北门房需独立实现 Gold DOOR 自动 `D_DOWN` 到达规则，不可照搬横向门房。

## ALPH-SOUTH-002｜遗迹南侧通路运行时接入（已验收）

- Route32 ↔ 南门房 ↔ 阿露福遗迹外围双向通路已激活；稳定 ID102→slot9、ID20→slot10，活动地图共11张。
- 遗迹外围 Gold 48格 WATER 已接入 Surf，14个 HOP 碰撞格按16条安全方向登记；无 Cut 树。保留现有路线 Surf、门房骑车、地点栏、存档名与音乐映射。
- 遗迹拼图、研究中心、联合洞穴、北门房、Route36、National Park 及其他未完成出口继续关闭；不新增 SAV 字段，不改变关都行为。
- 用户已确认南侧门房与本轮 FIX-256 测试没有问题。详细地图与碰撞合同见 `docs/JOHTO_RUINS_SOUTH_RUNTIME_254.md` 和 `docs/JOHTO_RUINS_LEDGE_FIX_256.md`。

# FEATURES
There are a number of different types of updates that have been included so far.
This list is not necessarily complete, but it gives a good list and will be updated semi-regularly

## BUGFIXES
These are notable bugs from original Red that have been fixed

* Frozen Pokémon can thaw naturally, or if they use a move that thaws the user as part of its effect
* Waking up does not waste your entire turn
* Critical Hit and Focus Energy code ported from Pokémon Crystal
* Fixed Missingno. Glitch
* Counter can hit any Physical attack, not just any Normal or Fighting attack
* All attacks should have their Gen 6 typing and Base Power, almost all have Gen 6 effect
* Fixed type strength/weakness issues
* Fixed-Damage moves no longer ignore type immunity
* Swift can no longer hit during the "invulnerable" turn of an attack
* No more "Gen 1 Missing" (aka 100% Accuracy moves no longer accidentally have a 1/256 chance of missing)
* Pokémon do not skip learning a move if they gain enough EXP to skip over that level
* Pokémon can be assigned to learn more than one move per level
* Not necessarily a bug, but Old Rod can catch more than just Magikarp
* No NPCs making impossible claims about Pokémon evolving
* Fixed the bug where Item Evolutions can happen accidentally by level-up
* Changed Struggle to be ???-Type so nothing can be immune to it
* Player turns to face an enemy trainer, like in every game except Red and FireRed
* Defeating a Pokémon does not negate the need for HyperBeam to recharge
* Breaking a substitute doesn't negate HyperBeam, SelfDestruct/Explosion effects
* Dual-Type Pokemon do not display an incorrect message if hit by a move that is Super Effective against one type and Not Very Effective against the other
* Some Bide issues
* Sleep moves do not ignore accuracy and other status conditions when opponent needs to recharge
* Fixed Psywave desync glitch in link battles
* No healing moves failing on 255 or 511 HP
* No more permanent invincibility if fully paralyzed/hurt by confusion while using Dig or Fly
* Fixed Reflect/Lightscreen stat overflow bug
* Rest gets rid of Bad Poison
* Defense cannot become 0 after stat scaling
* Mirror Move/Partial Trapping move desync glitch fixed
* Substitute no longer kills the user if they have exactly 25% HP
* More


## NEW FEATURES
These are notable features which have been added

* Gender selection (Red or Leaf)
* Running Shoes (2x faster than walking)
* Faster Surfing(2x faster than walking)
* Faster Bicycle(4x faster than walking)
* Full Color
* Updated graphics
* Replaced audio engine with Pokémon Crystal's
* Physical/Special Split
* Dark, Steel, and Fairy types
* Several new Pokémon (NO FAKEMON)
* Several new moves from newer generations
* Manual Transform can immediately execute one copied move in the same action after a successful transformation (TRF-5.62.210; player confirms with A, B is ignored; enemy/Link paths choose a copied move automatically). A successful Transform now clears the acting side's stale Disable slot/timer state; failed Transform preserves it, and later Disable still works normally.
* New evolution methods added
* Updated move pools for all Pokémon, inspired by XY/ORAS (not exact)
* Berry Trees (working off of a step counter)
* New trainer classes added
* Trainers have individual names
* Animated EXP Bar in battle
* Caught indicator icon for Wild Pokémon
* EXP Share functions like Gen 6 (But is NOT given at the start of the game)
* BW/2 Repel System
* Pack holds 30 items instead of 20
* HM Moves usable without manually selecting them from the party menu
* Ability to use Headbutt outside of Battle, like GSC or HGSS
* Flash is a TM instead of an HM
* New areas in Kanto
* Limited Johto pilot area: 11 active maps including New Bark Town, Routes 29–32, Cherrygrove City, Violet City, Guide Gent's House, Route 31 Gate, Route32 Ruins Gate, and Ruins of Alph outside. Active Surf, Cut, ledges, and gate behavior follow Gold-scoped map rules; the north gate, Route36, caves and unfinished story rooms remain disabled.
* Navel Rock, Faraway Island, and Southern Island from Pokémon Emerald are all included
* Breeding at the Day-Care
* Smarter AI for Boss trainers (Normal Patch) or All Trainers (Hard Patch)
* Item Descriptions in Mart and bag menus
* Move Relearner
* Move Tutors
* Move Deleter
* Shiny Pokémon (1/1024 wild Pokémon are shiny)
* Pokémon have genders
* Chain-Fishing for Shinies
* More


## BEHIND-THE-SCENES FEATURES
These are probably only interesting to people wanting to use this as a baserom

* Pokémon IDs sorted by Pokédex Number internally
* Trainer sprite and AI no longer forced to be the same for every trainer within a class
* Trainer classes do not all have the same DVs
* Trainers can have individually assigned DVs for certain Pokemon, ie Lance has a shiny Dragonite
* New more flexible (and more readable) format for giving trainers' Pokémon custom movesets
* Variable overworld sprite IDs, like Gen 2 has
* Trainer sprites can be stored in any Rombank
* Town Map is no longer RLE encoded, uses the more flexible Gen 2 format (a standard tilemap)
* Removed this weird unnecessary duplicate check causing some trainer class names to be listed twice
* Fixed an oversight causing things that weren't Items to accidentally show up with a TM/HM name 
* More
