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
