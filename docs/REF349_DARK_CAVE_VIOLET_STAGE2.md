> **REF-349 正式版本修订（覆盖下方历史“显示 REF-348”口径）**：本轮将 `data/game_version.asm` 游戏内标签升级到 `REF-349@`，Dark Cave 已接入的双出口、黑暗/Flash、Surf、26个跳崖、自行车源码保持不变。原 `REF-348` Red/Blue MAP 仅供上一构建空间参考；新版本构建及测试明细见 [`CLEAN REF-349`](CLEAN_REF349_DARK_CAVE_FINAL_ACCEPTANCE.md)。

> **2026-11-06 清理收口现况（覆盖下方各开发候选的状态口径）**：用户本轮上传 `REF-348.patch`（正式HEAD `3a53f2d3`）和同版 Red/Blue MAP，当前游戏 `REF-348`、64张活动地图、164条 Warp。31/46号道路双出口与骑车权限在运行源码已接好；用户 Surf 和26处跳崖反馈正常，但 Route46/自行车全路径及旧档仍待手机全面验收。ROM0 Red/Blue各386B，Bank1各4B、Bank4各23B，TEST MAP缺失。当前仍为Gold R2通行层，烟墨侧与R3/R4暂不开放。本轮仅工具/文档清理、模式A双提交，见 [`CLEAN REF-349`](CLEAN_REF349_DARK_CAVE_FINAL_ACCEPTANCE.md)。

## REF-349｜Dark Cave 新地点通用功能审查：Gold 骑车（开发候选）
- 当前基线：用户已确认跳崖/冲浪正常，最新 Route46 双向出口开发补丁已交付；正式 Git HEAD 无新证据，仍为 `3a53f2d3`。本次在双出口工作区之后增加**一项独立的骑车修正**，不更改活动64地图、164 Warp、显示版本 REF-348。
- Gold `data/maps/maps.asm:148` 指定 `DarkCaveVioletEntrance` 的环境是 `CAVE`；Gold `engine/events/overworld.asm:BikeFunction.CheckEnvironment` 允许 `CAVE`，但上车时要求脚下为 `FLOOR_TILE`。Gold `FLOOR` ($00) 与 `WARP_CARPET_DOWN` ($70) 均属于 FLOOR 权限；`WATER/WALL/HOP/UP_WALL/CAVE` 不是。
- RPP 特有的 `JOHTO_DARK_CAVE` 保持 `INDOOR` 图块动画标志防止洞内图像被通用 CAVE 动画写坏，但只对**现役稳定 ID190** 在 `IsBikeRidingAllowed` 里开放骑车：从步行上车时调用 Gold 40x36 角色表检查当前地面（0/6）；已在骑车状态跨图抵达时允许继续骑，符合 Gold 保留 CAVE 骑车状态的行为。未激活 ID99、其他室内、门房、关都规则及通用 BikeRidingTilesets 白名单不变；同一调用点覆盖背包自行车、SELECT 和骑车精灵重载。全程不改 Surf 状态与 Hop 规则。
- **常规功能对照**：31/46双向出口、暗场/Flash、Surf及合法上岸、26处定向HOP、地名和音乐已经有运行接线；Fly/Teleport在本洞不可用，Gold不要求 Cut/Strength；4块可碎岩、3个道具球、隐藏 Elixer 仍属R3；野生遭遇/FISHGROUP_LAKE 及后续事件属R4，不因R2地图通行自动开放；Gold `TilesetDarkCaveAnim` 仍待独立移植。
- **明确阻断**：Gold 的 Dig/Escape Rope 可从 CAVE 返回入口，但当前 RPP `CanUseEscapeRope` 白名单不含该洞，旧 `SpecialWarpIn` 的 bit6 走上次治愈中心（黑屏／Fly 表），不具备按31/46入口来源安全返回的城都实现。禁止仅追加 `EscapeRopeTilesets` 后宣布开放；未来需独立设计路线来源、两洞口回程、旧档及实机验收。
- 开发期按 `docs/JOHTO_CONTENT_BACKLOG.md` 第5节逐项检查：地图/资源/音乐/骑车/场地技能、完整负向审计、ROM0≥64B，Red/Blue/TEST 新链接 MAP、My OldBoy 从两入口骑车、禁骑格、SELECT、Flash、Surf、跳崖、Save/Continue 及旧档仍须用户验证。AI不编ROM、不Commit/Push；交付为一个ZIP内两份互斥的增量与HEAD累计正向补丁。

## REF-349｜Dark Cave 第二个室外出口（Route46，开发候选）
- 用户实机确认上一轮 Surf 与跳崖已正常；本轮只接通 Gold 第二个室外出口，保留此前动作与视觉代码。
- Gold 洞穴 Warp ordinal0 Route31、ordinal1 Blackthorn 独立洞穴、ordinal2 Route46；本轮仅开放0和2，保留ordinal1不可达占位，不压缩序号。
- Route46 Gold 入口 `(14,5)`，从 `(14,6)` 面向 UP 触发；洞穴 `(35,33)` 是 DOWN carpet。返回46号道路 `(14,5)` 后自动 DOWN 一步；31号道路不变。
- 活动仍64地图，登记Warp从162增至164；Blackthorn房间、NPC、道具、遭遇未接通。需本机Red/Blue/TEST编译/MAP与ROM0/ROMX、My OldBoy双向往返及旧存档验收。AI不代编ROM、不Commit/Push；只交开发期互斥增量/累计补丁。

## 2026-11-06｜设备反馈：Gold HOP 实际起跳全部被前置墙碰撞阻断（本轮修复候选）
- 用户确认上一轮 Surf 已正常，但所有跳崖不能触发。定位：`home/overworld.asm` 的 `CollisionCheckOnLand` 在 `JohtoOverworldSouthLandDecision` 之前先执行 `JohtoPilotIsClosedOutdoorEdge`，Dark Cave 早期守卫错用 `JohtoDarkCaveLandDecision`，使 HOP 紧邻的 WALL 提前拦截；共有26个 HOP，均有此结构。
- 本轮仅修改 `engine/johto_pilot_runtime.asm` 中 `.darkCaveClosedEdge`：只禁止四面越出 40×36 边界，真正的内部 WALL/方向墙、HOP 均交由后续 Gold 地形决策。已修好的 Surf、坐骑、26个 Gold HOP 原格坐标、2-step 着地守卫以及其他地图不改动。
- 下一轮设备验证：12个 DOWN / 14个 LEFT 起跳；对应 WALL 后的落点；反向不可穿越；尤其 Surf (8,12)/(8,13) 上岸到 (7,12)/(7,13) 后再左跳；B键、旧档及出洞。RED/BLUE/TEST ROM/MAP 和 Bank41 空间仍由用户本地验证。测试源码只证明静态条件。

## 2026-11-06｜REF-349 Dark Cave Surf／跳崖运行闭环修复候选（待设备验收）

- 输入：`REF-348(2).zip` 工作区＋已交付的 `REF349_DARK_CAVE_VIDEO_FLASH_HOTFIX_DEV.zip` 最终状态。可追溯正式 HEAD `3a53f2d3a38e9b0c1ae89d5f4f722a00369d0ad4`，**未出现新的 Git HEAD 证据**。游戏显示 `REF-348` 及活动 64 图 / 162 Warp 均不变。
- **Surf 主因**：Gold Dark Cave 运行图块动画为静态 `INDOOR`，原 `home/overworld.asm:LoadPlayerSpriteGraphics` 在 Surf 对话框关闭后把 `wWalkBikeSurfState=2` 错误重置为 0，坐骑精灵消失、不能游动。修复仅对 `wCurMapTileset=JOHTO_DARK_CAVE` 且冲浪状态 2 放行；`engine/menu/summary_return_helpers.asm` 的 LCD-off 返回走同一合同，其他室内/关都不放宽。
- **Surf 上/下岸**：`engine/items/items.asm:ItemUseSurfboard` 再次使用道具下船不再查只含 `$ff` 的旧 passable tile 表；仅在 Dark Cave 使用 `JohtoDarkCaveSurfDecision`，允许合法 Gold LAND（含定向 HOP/UP_WALL），拒绝 WATER/WALL/未开放口，仍按原脚本模拟上岸一步；方向键冲浪与现有 Surf/WATER 分派保持一致。
- **Surf 徽章**：Gold 原版使用 Fog Badge（Johto bit3）。新增 ROMX 共享 `JohtoSurfBadgeAllowed349`，按 A 和队伍菜单两个入口共用。已开启的 Dark Cave 接受 Fog；原有 Soul Badge（关都 bit4）暂作为旧存档兼容；其他地图继续原 Soul 规则。若日后 Johto Gym 正式开放，须移除/迁移兼容条件，不能标称当前徽章规则为严格 Gold。
- **26 个跳崖**：原表按 HOP 之前一个格登记，RPP 的两步模拟因此停在 WALL。现在每条表记录都是 Gold 实际 HOP 象限 `(x,y)`：第1步越过相邻 WALL，第2步落在 Gold 非墙地格。特别是水格 `(8,12)`、`(8,13)` LEFT 应先上岸到 `(7,12)`、`(7,13)`，下一次 LEFT 才启动跳崖，不能在水上提前跳。复用全项目的 `HandleLedges` 与 `JohtoSouthHopLandingGuard`，不改跳崖阴影计时、B 键保护和其他地图表。
- **审计**：升级 `tools/johto_dark_cave_stage2_audit.py` 由 Gold角色推导26个原始HOP坐标及真实两步路径，并检验两个 Surf 精灵加载入口、Surfboard 上岸、两个徽章入口；`tools/tests/test_johto_dark_cave_stage2.py` 增加错误注入。当前这些仅为源级静态合同和模拟的路径断言，未进行 RGBDS 链接/设备行为验证。
- **ROM预算及交付**：ROM0 新增小型静态动画例外，Bank `$04` 把旧 Surf bit 试验替换为 `callab` 跳转（容量非常紧）；旧 MAP 不能作为新 ROM 的空间证据。Red / Blue / TEST 新编译 MAP、ROM0≥64B、Bank `$04` 和其他 Bank 的实际剩余字节，以及 My OldBoy 手机上 Surf 坐骑/四向游动/合法上岸/26跳崖/反向输入/旧档/反复进出洞，全部**待用户验证**。本轮不由 AI 编 ROM／Commit／Push。
- **开发期补丁**：01 仅从上一轮 VIDEO_FLASH_HOTFIX 最终源码到本修复；02 从上述正式 HEAD 累计全部 REF-349 未提交改动至同一目标。互斥，不可叠加；交付 ZIP 只包含两份正向 `.patch`，不提前提交清理日志。

---

## 2026-11-06｜Gold / RPP 玩家视频：黑暗洞穴人物消失和进出洞紫色闪屏修复候选

- **证据**：用户提供约 24.76 秒 `黑暗洞穴.mp4`，Gold 在前、RPP 在后。Gold 暗洞里人物仍可见，Gold 进洞约 2.5 秒有正常**白色**门口淡出，之后洞穴变暗；RPP 约 14.5 秒换图时出现全亮紫色洞穴帧，14.7 秒后人物不可见。出洞时 RPP 也会先显示紫色洞穴。要消除的是**紫色洞穴闪屏**，不能误把 Gold 原本的白色淡出当作故障而完全删除。
- **精灵**：RPP `home/fade.asm` 的旧 `FadePal2=%11111110` 同时用于 BGP 和 OBP，令 GBC 背景、主角都变暗。增加只供城都 Dark Cave 使用的 3B `FadePalJohtoDark349 = FE/E4/E4`，位于 `FadePal4-12`；BGP 暗，两个 OBP 正常，保留旧 Kanto Rock Tunnel 的 `FadePal2` 和偏移6。Flash 设0后仍按 NITE 洞穴 RGB5 显示。
- **入洞**：`JohtoPilotResolveRegisteredWarp` 在目标 ID190 时用偏移12，`PlayMapChangeSound` 特判偏移12，**先对旧31号道路执行 Gold 风格的白色淡出**，不再因为非零偏移直接跳过淡出并露出整张紫色新地图；既有 Kanto 非零暗地图分支不变。
- **未照亮洞穴退出**：记录中的源 ID190 和当前暗偏移12共同标记该路径。为防通用白色淡出第一阶段把洞穴从 FE 拉回 E4 导致紫色闪屏，先直接把旧场景的 BGP／两个 OBP 全部置白（0），短暂保留偏移12，使通用淡出不重复执行；在新31号道路 `LoadMapData` 已完成、**LCD仍关闭**时由 `JohtoDarkCavePreLCDPalette349` 清零偏移并调用 `LoadGBPal`，再开启 LCD。闪光照亮过的洞穴离开则继续原有常规白色淡出，避免错误回到黑暗。
- **范围与兼容**：地图/Warp/出洞自动DOWN/Surf/Zephyr＋旧徽章兼容不改；64张活动图、162 Warp不变；游戏显示 `REF-348` 继续保持；更新 `tools/johto_dark_cave_stage2_audit.py`、专项负向回归（含玩家 OBJ、紫色闪帧、预 LCD 及 Kanto 隔离）。不编译 ROM、不执行 Git Commit/Push。
- **交付基线**：01 增量仅供已经应用 `REF349_DARK_CAVE_VIOLET_HOTFIX_DEV.zip` 中01修复补丁的当前 Worktree；02 从导出正式 HEAD `3a53f2d3a38e9b0c1ae89d5f4f722a00369d0ad4` 累计全部未提交 REF-349 改动与本修复。两份补丁互斥，不可叠加。
- **ROM0 预算**：HOME 新增约 21B（3B 调色记录、约 12B 播放换图判断、6B 预LCD `callab`），以前输入 MAP 显示 Red ROM0 剩420B，**新余量只是粗估，不能视作新 MAP 实测**。需用户本机 Red/Blue/TEST 新编译和 MAP 检查 ROM0≥64B、Bank04及其他Bank。
- **手机必须复测**：无 Flash 的 Gold/RPP 对照画面应当是暗背景＋仍可见主角、进洞白色淡出后不能露出全亮紫洞、出洞不反向亮闪并自动往下走一步、继续直接按上再次入洞；Flash后明洞、退出重新进入复暗；多次进出、旧档、31号道路/普通房间、Kanto Rock Tunnel、联合洞穴、烧焦塔。当前仅有源码级静态测试，不代表新的 ROM 设备验收。

---

## 2026-11-06｜用户实测问题的修复候选（覆盖下文旧“已接入”乐观判断）

- 真实输入为 `REF-348(2).zip` 当前 Worktree。RPP 导出记录：分支 `常规功能备份`、HEAD `3a53f2d3a38e9b0c1ae89d5f4f722a00369d0ad4`。本包附带 `current_worktree.patch` 可完整逆向还原并前向回放；当前 REF-349 第二批不是该 HEAD 上已提交的代码。游戏显示版本仍为 `REF-348`。
- Gold `data/maps/maps.asm`：Dark Cave `CAVE / PALETTE_DARK`。REF-349 初始实现只写 `OUTDOOR_*` DAY RGB5 基色，故闪光后尤其与 Gold 洞穴 NITE 色系不同。本修复只对 `JOHTO_DARK_CAVE` 调色组切到已存在、联合洞穴使用的 `CAVE_*` NITE RGB5。旧 `wMapPalOffset=6` 通过 `LoadGBPal`/`rBGP` 与 GBC 的 `color/vblank.asm` 色表转换产生暗态，Flash 将其清零；**不是**另造一套未经证明的新调色引擎，也不能因静态核对声称像素级与 Gold 实机一致。
- Route31 Gold Warp #3 落点 `(34,5)` 的门砖左下 8×8 tile `$56` 不在通用 Gold house `$39` Door 表中。仅在当前 ID Route31 且准确 `(34,5)` 时返回 `D_DOWN`，由既有 `PlayerStepOutFromDoor` 模拟一步；洞穴 `(3,15)` 属 DOWN carpet 到达，不自行移动，其他户外 Gate carpet 不改。
- Flash：新 `JohtoFlashEligibility349` 放在 Dark Cave 浮动 ROMX 内，Bank `$04` 的 START 调用只增加一个小型 `callab` 入口；原 MAP Bank `$04` 仅 11B 空间，本地扩展约 6B，**新 MAP 未构建，不可据此宣称一定能链接**。仅 ID190 且 `wMapPalOffset` 非零可用；先验 Zephyr Badge（Johto bit0），由于 Johto 道馆尚未提供该徽章，保留已有 Boulder Badge（Kanto bit0）作为暂时存档兼容。已亮洞穴及其他城都地图返回失败文案；旧 Kanto 分支保持原条件。此兼容例外有别于 Gold 只验 Zephyr 的严格规则，今后道馆正式开放时需专门迁移。
- Surf：依 Gold `CheckSurfable` / `LAND_TILE` 概念允许方向正确的 HOP/UP_WALL 岸边，特别是水边 `(7,12)` LEFT、`(7,13)` LEFT、`(9,11)` UP，仍阻挡逆向。`JohtoDarkCaveSurfDecision` 新增稳定 ID190 检查，避免未来 15×18 的烟墨侧误用桔梗侧 40×36 角色表。`data/dungeon_tilesets.asm` 预注册本洞 Tileset，确保未来同 Tileset 换洞时重新加载目标 Warp 坐标（不会提前开放未登记入口）。
- 扩展现有 `tools/johto_dark_cave_stage2_audit.py` 与 `tools/tests/test_johto_dark_cave_stage2.py`：重点检测颜色组、门口迈步、Flash 地图+徽章+暗态、HOP 岸边、同 Tileset 目标坐标，含故障注入。静态 PASS ≠ ROM/手机 PASS。
- **尚未实现**：Gold 专用 `TilesetDarkCaveAnim`、水/调色动画、Route46／烟墨侧、原版三处物品、四块碎岩、隐藏 Elixer、野生遭遇和完整 Gold 剧情；为了避免在 INDOOR 类型上误套旧 CAVERN 动画，本轮没有强制改变 `hTilesetType`。后续需独立实现并实际构建验收。
- 最小手机验收：Red/Blue/TEST 新 MAP（尤其 ROM0≥64B / Bank4）、从31号道路入洞／回程一步、GBC 无 Flash 暗色→Flash 明亮→退出恢复→再进重新暗；旧档、Flash 无徽章/已照亮/城都普通地图；水域三个 HOP 岸边、UP_WALL 方向、方向性跳崖反向保护；联合洞穴／烧焦塔／既有室内门口不能回归。

---

# REF-349 黑暗洞穴桔梗侧第二批：运行路径和验收

- 基线：已应用 `REF349_黑暗洞穴桔梗侧_第一批` 的工作区，第一批冻结的 Gold 地图/碰撞数据未改。
- 游戏显示版本：继续 REF-348；本轮未 Git 提交/推送，未 RGBDS 编译或手机实机验收。
- 激活：桔梗侧 `DarkCaveVioletEntrance`（stable ID190，active slot63，20×18 blocks），活动地图64张。
- Warp：31号道路 Gold `(34,5)` 入口 ↔ 洞内 `(3,15)` 下行出口，登记 Warp 从160→162；46号道路及烟墨侧不开放。
- 机制：Gold 逐象限角色表1440B；64个 WATER、41个 UP_WALL、26个定向 HOP；Flash 洞内暗调色、正常调色离洞清理；Surf上/下岸采用局部空间判断，其他地图沿用原判定。 图形源96个8×8 tile，Makefile的`--trim-whitespace`会去掉末尾31个空白tile，实际INCBIN为65个tile（1040B）；运行时ASSERT及地图所用tile ID按裁剪结果校验。
- 集成：地图/地点牌/Town Map（继承31号道路地标）/音乐/Palette/TilePalette/Graphics/Warp ID pointer表完整补到64槽及41 tilesets，避免表越界。
- 编译断言修正：Makefile 对该 tileset 执行 `--trim-whitespace`，96 个源 tile 中末尾 31 个为空，生成的 INCBIN 实际为 65×16=1040B；运行时 ASSERT 改为 65 tiles，Gold 地图使用的最大 tile ID 限制为 64 以下。此修正尚待用户重新 RGBDS 编译确认。
- 独立静态审计：`python tools/johto_dark_cave_stage2_audit.py --project .`；`python tools/johto_surf_build_gate_296.py --root .`；`python tools/johto_pilot_migration_audit.py --project . --gold-root /path/to/pokegold`；`python -m pytest tools/tests/test_johto_dark_cave_stage2.py -q`。
- 目前所有上述源级/Gold静态审计通过；不等于真ROM验收。用户端需按项目既有流程构建 Red/Blue/TEST 并检查新MAP容量、ROM0≥64B，随后手机逐项实测。

## 手机实测清单

1. 从31号道路 `(34,5)` 进入，确认黑暗、地图名称、方向、落点；在洞内 `(3,15)` 向下正确返回31号道路。
2. 进入后用 Flash，应亮起；离洞再进默认黑暗且不影响其他地图调色；旧存档也测。
3. 在64格Gold水域测试冲浪开始、持续移动、上下岸以及水/墙边界；非水不允许冲浪。
4. 26个定向跳崖测试合法方向、反方向阻挡、按B/反向操作、黑影和连续跳崖；未开放出口不能穿越。
5. 查看 Town Map、地图标牌、音乐、反复进出、存档读档；确认不影响原有联合洞穴、烧焦塔等地图。

## 后续范围

46号道路入口、烟墨侧 ID99、NPC、道具、野生遭遇均未在本阶段开放。
