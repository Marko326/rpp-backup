## MUS-259｜用户验收后正式清理（本轮）

- [x] 核对用户提供的干净 `FIX-5.62.256.zip`：分支 `常规功能备份`，实际 HEAD `403e41e5ba763b4d747a7bbc6a03d6da161ab1be`，无未提交 Worktree Patch。
- [x] 用户反馈本轮门房音乐继承、进出及骑车修改“没问题”，据此收口 `.257`～`.259` 最终净变更，不把中间试修按正式历史写入 Git 提交日志。
- [x] 三座活动 GATE 音乐来源、骑车、neutral 地名牌审计已接入迁移总工具；遗迹北门房和36号路已在本轮定稿中启用。
- [x] 下一阶段 Union Cave 资源与底座缺口盘点；洞穴地图本轮不激活。
- [ ] 用户按清理包两笔日志核对实际本地 Git HEAD/index，再自行 Commit；本环境不 Commit/Push，不构建 ROM。

## UNION-CAVE-260｜下一批：首次洞穴地图接入（尚未开发）

- [ ] 以用户下次上传的最新正式 ZIP 为新基线，核对 Gold `UnionCave1F` 原版 180B block、Warp #3/#4 到 Route32、1F→B1F 两条楼梯及 B1F/B2F、Route33出口；先只开放 Route32 ↔ 1F 可往返闭环。
- [ ] 建立洞穴专属 Tileset／blockset／碰撞、ROM Bank 与地图 Header 契约；逐格核对 Gold WALL/FLOOR/WATER，不能复用户外 JOHTO_PILOT 的碰撞表来硬放行。
- [ ] 检查洞穴内是否允许骑车（Gold CAVE 环境＋脚下 FLOOR，不能按名称判定）、地名/Save/Continue、原曲／场景缓存、视野与调色。
- [ ] 为洞穴内 Surf（如有水域）、楼梯方向／自动步进、存档、未完成出口 fail-closed 建立专项正向和负向测试；B1F/B2F、遭遇和剧情暂不激活。
- [ ] 在本机正式/测试红蓝及 MAP 编译通过后逐入口、楼梯边界、撞墙、冲浪岸线、继续游戏实测；AI 不自行编译。

## MUS-259｜城都门房继承音乐、骑车与统一审计（开发待验）

- [x] 三座已激活 Gold GATE 按 Warp 实际来源继承 RBY/GSC 曲目，不在同场景主动重启；不可信门房 Continue 来源回退 Gold 原版门房默认曲。
- [x] 北门房稳定 ID19 加入自行车许可；不放行 Gold INDOOR 自然公园门房或关都建筑。
- [x] 全量活动门房音乐／骑车审计及负向故障注入，纳入迁移总审计。
- [ ] 本机编译正式／TEST 红蓝、检查 MAP、从遗迹／36号路双向测试北门房音乐延续与骑车，并回归南门房、31号门房、存档及自动步进。
- [ ] 用户验收后按 Git 基线净差异生成清理三件套。

## FIX-258｜北门房地点栏与可扩展名称审计（开发待验收）

- [x] `Route36RuinsOfAlphGate` 加入中立门房判断，避免显示 `Johto` 兜底名称。
- [x] 新增动态按当前活动地图登记的地名合同，核对稳定 ID、所有门房中立权限、活动道路的地点弹窗、Town Map／Save/Continue 名称及地区／运行句柄守卫。
- [x] 故障注入：删除北／南门房、删 Route36 跳转、错误 `Johto` 文本、旧合同缺项及 Town Map 名称错配均必须被审计发现。
- [ ] 用户本机编译正式红蓝／TEST，并检查新 MAP；实测遗迹北门房两向进出不出现 `Johto`，出门分别显示 `Route 36` 和 `Ruins Of Alph`，继续确认自动行走、南门房与 Continue 正常。
- [ ] 本机通过后再根据实际 Git HEAD 收口提交；本阶段不 Commit/Push、不附提交日志。

## ALPH-NORTH-001｜遗迹北门房与36号路（开发待验收）

- [x] Gold NorthSouthGate/Route36 原始地图块与紧凑图块逐像素匹配，接入活动 slot11/12。
- [x] 登记 Gold 7条单向北侧 Warp 记录；仅顶端／遗迹 DOOR 落点向下自动走一步，地毯落点不自动行走；南侧双车道回归。
- [x] 封闭36号路未完成的自然公园／35号路／37号路／桔梗市连接，不造假的胡说树 NPC。
- [x] 13张地图的静态表、音乐、Town Map 地标（Route36 原版索引19、Y76/X72）、门房与 Gold 审计更新。
- [ ] 用户本地正式红蓝／TEST ROM 编译并检查 MAP，重点测北门房上下、两车道、DOOR 自动走一步、南门房和旧存档回归。
- [ ] 实机验收通过后再做清理三件套及按真实 Git HEAD 的两笔提交日志；AI 不 Commit/Push。

## FIX-256｜遗迹 Gold 方向跳崖与 Select 修复（用户实机验收通过）

- [x] 遗迹改用 Gold 坐标＋面向方向白名单，登记16条安全有向跳崖；复合转角按 DOWN/LEFT、DOWN/RIGHT 分别处理。
- [x] 排除 `(9,30,DOWN)`：Gold 落点 `(9,32)` 是 WALL，不允许向下跳。
- [x] Select 快捷功能后保留原始按键掩码与 carry，单按 Select 不再误开 Start。
- [x] 用户反馈 FIX-256 实机测试通过；遗迹南侧通路与横向门房也已测试，没有发现问题。
- [x] 完成验收清理：从已提交 `MAP-5.62.253` HEAD `3b163292e7fcedef584c469af3dd744add3f573e` 起整理功能与工具两笔提交。

## ALPH-NORTH-001｜下一阶段：遗迹北门房与 Route36（计划，尚未开发）

- [ ] 接入 Route36（稳定 ID16）与 Route36RuinsOfAlphGate（稳定 ID19），连接当前遗迹外围北门；预计活动地图11→13。
- [ ] 按 Gold 核对上门 `DOOR` 的 STEP_ON/UP、落到 DOOR 后自动 D_DOWN 一步；下门 `WARP_CARPET_DOWN` 仅 DOWN 碰撞触发。
- [ ] 单独实现“依据目标落点碰撞角色”的自动步进合同；验证只走一步、不二次触发 Warp、落点可通行、Continue 不误走。
- [ ] Route36 的 National Park Gate 两个 Warp 与 Route35/37 等未完成出口继续关闭。
- [ ] 完成逐 Warp Gold 合同、负向测试、完整静态审计和补丁正反向验证后，再交给用户本机编译及实机验收。

## FIX-255｜Select 按键修复（跳崖部分已由 FIX-256 替代）

- [x] Select 快捷功能后恢复原始按键掩码，保留返回 carry；阻断 Select 被误判成 Start。
- [x] 原始左端跳崖图块配对试修；此实现已被 FIX-256 的 Gold 坐标／方向白名单替代。

## ALPH-SOUTH-002｜遗迹南侧通路运行时接入（用户已验收）

- 从 ALPH-SOUTH-001 离线候选接入两张新图：Route32RuinsOfAlphGate 稳定 ID102→slot9、RuinsOfAlphOutside ID20→slot10；活动地图9→11，正式版改为 `MAP-5.62.254`，测试版仍 `TEST-231`。
- Gold 原版南侧四对入口按两车道双向登记：32号路 x4,y2/3 ↔ 南门房东侧 x9,y4/5 ↔ 南门房西侧 x0,y4/5 ↔ 遗迹外围 x13,y20/21；保留既有 Route31/Violet 门房与 Route32 冲浪。
- 遗迹外围 Gold 48 格 WATER 接入原有 Surf 三入口及上岸；14格 Gold HOP 在 254 初版曾复用 Route31 图块配对；该触发方式已由 FIX-256 的 Gold 坐标／方向白名单替代；无 Cut 树。门房允许骑车、地点栏/存档名与音乐表同步。
- **关闭范围：** 遗迹内拼图、研究中心、联合洞穴、北门房、Route36、36号路后续出口均未开放；不新增 SAV 字段、不修改关都逻辑。
- 用户已报告南侧门房与遗迹通路测试正常。静态工具也已更新为11张活动地图、19条登记 Warp 的当前合同；用户设备验收与静态报告分开记录。详见 `docs/JOHTO_RUINS_SOUTH_RUNTIME_254.md`。

## ALPH-SOUTH-001 — 阿露福遗迹南侧入口离线准备（历史阶段，已由 ALPH-SOUTH-002 完成激活）

- [x] 对照 Gold 和旧 NPC 工程，冻结遗迹外围、32号路遗迹门房、36号路门房及36号路的原版块数据。
- [x] 保存32号路门房与遗迹外围的 compact 候选布局；登记两端入口和所有待关闭的其他 Warp，新增 Gold 审计和反向测试。
- [x] 本阶段只负责资源准备；运行时激活随后由 ALPH-SOUTH-002 完成。
- [x] Gold 原版资源与后续南侧闭环已按 `docs/JOHTO_RUINS_SOUTH_STAGE_254.md`、`docs/JOHTO_RUINS_SOUTH_RUNTIME_254.md` 接续。

---

## ROUTES-253 / MAP-5.62.253 — 当前活动地图 Field Moves 全覆盖（正式清理，用户已验收）

- [x] **版本前缀校正**：地图及野外地形功能使用 `MAP-5.62.253`，不是误沿用的 `PAL`；旧 `.250` 等历史版本记录不回写，`TEST-231` 不改。仅改版本显示与现行交付文档，不修改已验收功能指令。
- [x] Gold 原版与活动地图清单逐格核对：9 张活动地图、644 个 WATER、7 棵 CUT_TREE、78 个 HOP 碰撞格；未启用的联合洞穴、33号道路、桧皮镇继续保持 staged。
- [x] Surf：NewBarkTown 8、CherrygroveCity 142、Route30 32、Route31 44、VioletCity 140、Route32 278；全部复用既有 Surf 招式／Surfboard／水中移动与上岸入口，未扩大共享图块白名单。
- [x] Cut：Route29 两棵、Route30 一棵、Route31 两棵、VioletCity 一棵、Route32 一棵；按 Gold 地图、坐标、原始块精确处理，只替换目标象限并保留邻接 Headbutt 树。
- [x] 跳崖：Route29 35、Route30 21、Route31 13、VioletCity 3、Route32 6 个 HOP 碰撞格；Route32 按稳定 ID 7 单独派发，不全局放开。
- [x] Route31VioletGate 仅按地区、运行句柄与稳定 ID 6 单点允许骑车；普通室内与关都旧规则不变。Route32 地点栏显示 `Route 32`。
- [x] 用户于 2026-10-29 确认本轮所有本机测试通过：正式／测试红蓝构建、新 MAP、Field Moves、门房、Continue 与关都回归。此为用户反馈；助手没有自行编译／链接 ROM 或运行设备。
- [x] 静态回归：Python 测试 175 项全部通过，无跳过；Surf preflight／Gold WATER 逐格对照 PASS；活动地图覆盖 9/9 PASS；ASM 2,067 文件 PASS；迁移 69/69、门房 12/12、Warp 17/17 PASS。
- [x] 正式清理按模式 A 拆为 `feat(johto)` 与 `test(tool)` 两笔；本轮游戏版本 `PAL-5.62.250 -> MAP-5.62.253`，不改 `TEST-231`。交付 ZIP 含 3 份补丁与 2 份中文日志。
- [ ] 用户核对本地真实 HEAD、工作区及暂存区后自行 Git Commit；AI 不代 Commit／Push。

---

## GATE-ROUTES-252 / PAL-5.62.252 — Gold 门房骑车、29号道路砍树和32号道路冲浪（历史阶段，已由 .253 接替）

- [x] Gold `GATE` 环境允许骑车，但自然公园35／36门房实际为 `INDOOR`；只对当前活动 Route31VioletGate 稳定 ID6 单点放行，不按名称或图块集全局开放。
- [x] Route29 两棵 Cut 与 Route32 278 WATER／1 棵 Cut 按 Gold 坐标登记；Route32 复用原有 Surf 入口及限定岸线检查；Field Skills 代码移入 Bank `$48`，不增加 Bank `$03` 远调用。
- [x] `.252` 阶段静态测试为 153 项运行、151 通过、2 项条件跳过；该数字仅是 `.252` 历史阶段记录，当前完整静态回归见上方 `.253`。
- [x] 本阶段的未验收状态已由用户对 `.253` 的“都测通过了”反馈取代；当前最终功能清单见 `docs/JOHTO_FIELD_MOVES_253.md`。

## ROUTES-251 / PAL-5.62.251 — 30、31号道路 Surf/Cut（历史阶段，已由 .253 接替）

- [x] Route30 32 格水域＋1 棵 Cut、Route31 44 格水域＋2 棵 Cut 接入；使用地图专属水域合同和单象限树木替换，邻接 Headbutt 树保留。
- [x] `.251` 阶段静态测试为 145 项运行、143 通过、2 项条件跳过；其待验状态已由用户对 `.253` 的最终验收反馈取代。
- [x] Route29 Cut、Route32 Surf/Cut/跳崖及 NewBarkTown Surf 已在后续 `.252/.253` 累计候选接入；当前不再按 `.251` TODO 另行推进。

---

## CHERRY-250-ACC-001 / PAL-5.62.250 — 吉花市 Surf 阶段记录（历史，已由 ROUTES-253 累计收口）

- [x] 核对 `.248` 用户上传的干净基线 HEAD `d1d833b6`，恢复 CHERRY-249 + CHERRY-250 的累计差异，复用 Gold 与旧 NPC 金银分支资料。
- [x] 吉花市原版 142 WATER 接入现有 Surf 三路径；西南平台8格 FLOOR 增加限定为吉花市稳定 ID2 的水上登岸／陆上行走判定；保留 `$3C` 墙壁碰撞。
- [x] 将用户反馈的先前登陆失败与修复后要求提交清理记录为本阶段验收反馈；将补丁、反例审计及操作说明整理为功能提交与工具文档提交两笔，不夸大为逐格全地图用户复测。
- [x] 新增的 Surf 合同及 Git 源 JSON 跟踪规则保留；`MISSING_SHORE_PASSABILITY` 需要同时检查水上、陆上执行路径。
- [x] 原 `.250` 两笔提交计划已由顶部 ROUTES-253 的累计双提交清理替代；当前仍由用户自行执行 Git Commit/Push，不再单独提交旧 `.248` 工作区。
- [x] 原 `.250` 两色构建、MAP、岸线与 Continue 验收要求已由用户对 `.253` 的完整测试通过反馈覆盖；这是用户反馈，不代表 AI 独立构建。
- [x] 原计划中的 Route30、Route31、Route32 和 NewBark 水域已在后续 `.251/.252/.253` 接入；未启用联合洞穴、Route33、桧皮镇继续保持 staged。

## CHERRY-250 / PAL-5.62.250 — 吉花市西南岩石平台登陆及 Gold FLOOR 审计（历史故障记录，已由 .253 验收覆盖）

- **故障证据**：用户截图显示在吉花市西南岩石平台南边水域无法登岸。Gold `CherrygroveCity` 地图碰撞定义平台 `(x4..7,y12..13)` 共 8 个格为 `FLOOR`；紧凑运行 Block `$71` 绘制的是 8×8 图块 `$3C`，但 `johto.tilecoll` 不允许 `$3C`。同一图块 `$3C` 在本图还用于 `WALL`，绝不能全局放行，否则穿墙。
- **最小修复**：不改 Gold 水格 142 条、不改 Blockset／碰撞白名单、不改存档、门房和其他地图。新增 `JohtoCherrygroveShoreFloorAhead`，仅允许吉花市稳定 ID2 的这 8 个 Gold `FLOOR` 坐标，水上经 `CollisionCheckOnWater` 停止 Surf 上岸、陆地经 `CheckTilePassable` 放行平台内部的连续走动。其余 `$3C` 仍碰撞。复用原版已有 Surf 状态恢复函数，不另造状态机。
- **工具改进**：`tools/johto_surf_preflight.py --gold` 现在除对照 Gold WATER，还会从 Gold FLOOR／当前 compact `.blk`／Blockset／tilecoll 动态检测“海岸边属于可走 FLOOR，但运行白名单不放行”的连通区域。CHERRY-249 原代码会报 `MISSING_SHORE_PASSABILITY`；只有水陆两条执行路径都正确接入有范围限定的例外，且坐标与 Gold 完全一致，才通过。`tools/tests/test_cherrygrove_shore_250.py` 包含故障反例。
- **当时验收边界（历史记录）**：在 `.250` 阶段，正式 Red/Blue 与 TEST 编译、最新 MAP 空间及平台四周上下岸、步行、回水、存读档仍待用户本机确认；后续用户已反馈 `.253` 的完整构建／MAP／手机回归通过。

## CHERRY-249 / PAL-5.62.249 — 吉花市冲浪接入（历史阶段，已由 .253 验收覆盖）

- [x] 以最新用户上传的 `PAL-5.62.248.zip` 为基线；保留既有未提交累计改动，正式标签更新至 `.249`，`TEST-231` 不变。
- [x] 从 Gold 原版 `CherrygroveCity.blk` 与 Johto collision 表逐格生成 142 个 WATER 坐标（40×18 collision cells）；不使用共享美术 ID 作为全局冲浪白名单。
- [x] 将吉花市专用判断接入 A 键 Surf、Surfboard 和水中移动/上岸三个现有入口；非水分支恢复 `wTileInFrontOfPlayer` 到 `C` 后复用现有陆地通行扫描。
- [x] 更新 Surf 合同、覆盖盘点与故障注入测试；若叶镇东侧水域继续按用户要求跳过。
- [x] 静态检查：122 项测试运行，120 通过、2 跳过；Gold 水格逐格比对通过；ASM 标签 2,067 文件通过；地图迁移 69/69、门房 12/12、Warp 17/17。
- [x] 本阶段的待验要求已由用户对 `.253` 的完整本机测试通过反馈覆盖，包含吉花市岸线、桔梗市与关都回归。
- [x] Route30、Route31、Route32 与 NewBarkTown 水域已在后续候选接入；联合洞穴仍未激活，不计入当前活动地图。

## VIOLET-248-ACC-001｜用户验收及分三笔提交收口（历史计划，已由 ROUTES-253 两笔累计清理替代，2026-10-29）

- [x] 用户提供最新 `.248` 工作区 Patch，基线为已提交的 `.243 / b6102175`；补丁累计包含 SAV-244、Route32-245/246、VIOLET-247/248 和 Surf 审计。
- [x] 用户反馈“测过了，没问题”；此前分别确认 Route32 进出、Cut、跳崖及 Surf 能上岸。按**用户反馈**收录，不称助手已执行模拟器或真实编译。
- [x] 交付三笔独立提交的精确暂存补丁：先 SAV 指针恢复，再地图／地形运行代码，最后测试脚本和文档。功能版本保持 `PAL-5.62.248`、`TEST-231` 不变。
- [x] 原三笔提交计划已由顶部 ROUTES-253 的两笔累计清理替代；用户仍需执行当前两笔 Git Commit，勿重复提交旧 `.248` 补丁。
- [ ] SAV-244 最初故障的具体旧 `.sav` 样本尚无单独的修复前后复测证据；今后遇到历史存档再单独验证，不能无限扩大兼容承诺。
- [ ] 后续开放联合洞穴、Route33、桧皮镇前，先依最新地图和 Surf 合同审计登记新场景，禁止直接打开未验证 Warp。

## VIOLET-248 / PAL-5.62.248 — 修复桔梗市冲浪无法上岸（待本机编译与实测）

- **故障原因**：`home/overworld.asm::CollisionCheckOnWater` 对桔梗市先调用 `JohtoVioletWaterAhead`。当目标不是 Gold WATER 时，旧分支直接进入 `.checkIfNextTileIsPassable`，没有把 `wTileInFrontOfPlayer` 重新装入 `C`；该扫描因此可能使用旧的/无效的 C 值，将岸上可走图块判成碰撞。用户实测确认可以下水但无法上岸。
- **参考逻辑**：旧 NPC 金银分支在 `CollisionCheckOnWater` 的城都水面查询返回非水后，明确执行 `ld a, [wTileInFrontOfPlayer]` / `ld c, a`，再进入原通行表扫描。本修复补回这一步；继续复用现有通用上岸/恢复步行状态代码，不另造 Surf 状态机。
- **范围**：只改桔梗市地图专用非水分支，保留 140 格 Gold 水面表、入水检查、砍树和跳崖、关都 Surf 与徽章逻辑不变。新增 `tools/tests/test_violet_surf_shore_248.py`，包含正向检查与移除两条指令的故障注入反例。
- **状态**：静态回归及补丁回放可通过不代表 RGBDS 已链接；项目规则禁止助手自行编译 ROM。用户需重新编译红蓝／测试版本并在桔梗市实际测试：从不同岸边上岸、继续走动、重新入水；同时复测关都与 Route32 Surf。未获用户实测前保持开发候选，不生成提交日志、不 Commit/Push。


## VIOLET-247 / PAL-5.62.247 — 桔梗市原版地形能力（开发候选）

- 仅限**桔梗市稳定 ID5**。以提供的 MUS Gold `VioletCity.blk`（20×18 Blocks）和 `johto_collision.asm` 全量解码为依据：3 个 `HOP_DOWN`（X26、28、29，Y22），140 个 `WATER` 象限，1 个 `CUT_TREE`（X36,Y19）；另有 68 个 `HEADBUTT_TREE` 象限。摇树、门房、普通障碍等不在本轮解锁范围。
- 跳崖使用既有 `JohtoPilotRoute29LedgeTiles` + 原共享动画，不改跳跃步数；Surf 采用按 Gold 16×16 坐标登记的地图专用查询，覆盖 A 键、Surfboard/道具与游泳中继续移动/上岸，其他地图默认不开放；Cut 只对桔梗市 Gold 原始唯一格启用，$63→$8D 克隆块只替换可砍格，隔壁 Headbutt 树保持。`johto.bst` 原始 141 块逐字节保留，运行时只追加第 142 块。
- 当前阶段**不改徽章系统**：Cut 仍遵从既有 Cascade Badge、Surf 仍遵从 Soul Badge 的入口门禁（原版 Gold 的 Hive/Fog Badge 剧情尚未建立）；验收时应使用符合现有条件的存档和会相应招式的宝可梦。不把受徽章门禁拒绝误判为地图不支持。
- 保留 SAV-244、Route32-245/246 的未提交累计修改、现有 ID、连接、存档格式和关都 Field Move 行为。新增 `tools/tests/test_violet_field_247.py`；严禁跳过源资产严格对照和 ASM 预检。
- 交付仍为**互斥增量/全量开发补丁**，不附提前拟提交日志，AI 不自行编译 ROM、不提交 Git。新版本的 ROM0、Bank $03、联接与红蓝 MAP、手机游泳/下水/上岸/砍树后通行/跳崖/Continue 仍须用户本机验收，静态测试不能替代。

## ROUTE32-246 / PAL-5.62.246 — 修正城都活动地图 Town Map 表并加入交付前强制核验（待用户构建）

- **真实故障证据**：用户 2026-10-29 的 `make test-red` 日志在 `engine/fly_town_map_helpers.asm:844/851` 报两次 `Assertion failed`。ROUTE32-245 将 `NUM_JOHTO_ACTIVE_MAPS` 增至9，但旧 Fly/Town Map 条目与槽位→地标索引表各停留在8；这是上一轮开发遗漏，不是 RGBDS／设备问题。
- **最小修复**：补入槽位8（Route32，稳定ID7）Town Map 条目 `(Y108,X92)`、`Route 32` 名字及 Gold 地标索引7；名称实体与 Fly Helper 放在同 Bank `$35`，不从不可直接读取的浮动 Bank 返回名字指针。保持现有 8 张槽位顺序和 Route32 地图/碰撞/Warp/音乐逻辑不变。
- **防止复发**：`tools/johto_pilot_migration_audit.py` 新增 `active_slot_town_map_tables`，随 `NUM_JOHTO_ACTIVE_MAPS` 动态对照 Fly/Town Map 记录、浏览索引、地图 profile 的地标编号与真实地标坐标／名称；对缺表、错索引、错坐标、错名称均 FAIL。新增5项反例测试，**地图增减时必须执行这项审计和 ASM 预检**。只过 ASM 符号预检、碰撞测试或补丁回放不足以宣称可构建。
- **交付/限制**：仅两份互斥开发补丁 ZIP（已打245的增量、干净 `.243` HEAD `b6102175` 的累计全量，后者含 SAV-244、245、246），不含 Git 提交日志；AI 不编译/链接 ROM、不 Commit/Push。新版红蓝、测试两色、MAP 与实机走动仍由用户本机构建／验收；没有编译证据不称已编译成功。

## ROUTE32-245 / PAL-5.62.245 — 城都南下批量资源准备与首张道路开放（开发待验）

- **准确工作区前提**：本批以新上传的 `.243` / `b610217566cedf3ed8f9138d126ab40d56ed41a6` 干净 HEAD 以及 SAV-244 开发补丁已应用状态为增量起点；`.243` 原项目全量包含 SAV-244 + 本批。用户未明确确认 SAV-244 手机实测或 Git Commit，不把它写成已验收/已提交。
- **实际开放仅 Route32**：稳定 ID `7` 新增活动槽位 `8`（9 张活动地图）。原 Gold `.blk` 与已实现的旧 NPC 金银分支 compact `.blk` 分开保存；复用经逐字节核对的 Johto blockset 与图形，不移植旧的物理地图句柄。
- **双向连接与防卡控制**：桔梗市南 ↔ Route32 北，Gold offset=0，严格只开放人物 tile `x=14/15`。Violet 原 EAST 门房屏幕预览及 Warp 不改。Route32 北边预览保留参考项目多三列可视缓冲；Route32 南、西、东边界保持关闭。两端 Header、资源和预览 Block 都在 `$43` 同一 ROM Bank，防止跨 Bank 直接复制错误。
- **音乐与地点**：Route32 使用原版 Gold `MUSIC_ROUTE_30`（GSC 模式）和项目现有 RBY 道路曲族；Gold 地标索引 7 与 Save/Continue、Town Map 复用，不额外增加游戏存档字段。新地图保持已验收的 30↔31 同曲续播规则，不改关都音乐与门房。
- **只暂存不开放**：联合洞穴 1F（ID8）、33号道路（ID9）、桧皮镇（ID10）的旧 Compact `.blk` 已作为 `maps/johto_staged/` 离线来源归档并固化 SHA-256；**没有**登记到活动槽位、Header、Warp 或地图连接。洞穴另需独立 Tileset、ROM0 可读碰撞、洞口正确落点/出口方向与返回路径；33号路后续还需 modern Tileset。绝不把资源文件存在当作可玩开放。
- **验收重点**：用户本机正式红/蓝编译和 MAP 空间检查；从桔梗市 `(Y35,X14/15)` 向南一步进入 Route32、双向正常走动；返回桔梗市后继续能动，步行和骑行方向完整；在 Route32 保存／Continue 仍能动，边界未开放区域不应误传送、残影或卡死；关都和既有门房/音乐不回归。本轮静态审计与未编译源码不能冒充 ROM/手机实测。
- **交付规则**：只交两份互斥补丁的开发合集 ZIP，不含 Git 提交日志，AI 不自行编译 ROM、Commit/Push。增量仅适用于 SAV-244 已打而未提交；全量仅适用于 `.243` HEAD `b6102175` 干净工程，两份严禁叠加。下一批先收用户运行反馈，再开放洞穴，不因为用户想加快进度而打开未核实 Warp。

## SAV-244 / PAL-5.62.244 — 旧存档读档后卡住的图块指针修复（开发待验）

- [x] 核对用户提供的第三包历史提交 `1d7c62e5`（SAV-1.2）：旧存档加载后刷新 Tileset 指针、临时使用 `$FF` 阻止 Warp 改坐标；历史记录是用户曾对一个故障旧档验收通过，并非所有地图/版本。
- [x] `LoadSAV0` 对存档 Continue 设置 `wCurMapTileset` bit7（包括新版存档），旧 `LoadMapHeader` 在此标志下直接返回，未刷新 `wTilesetBank`/图块/碰撞等指针。恢复图块集 Header 的 11 字节数据，保存/恢复 `wDestinationWarpID`，保留 Kanto/Johto 现有地图身份和 SRAM 格式。
- [x] 补充无 ROM 构建的静态契约/故障注入测试；跨版本允许原 MUS-243 音乐测试的最低版本检查。
- [ ] **待用户本地红/蓝正式编译和手机实际验收**：先备份 SAV，分别在关都、若叶镇、30/31号路、向导家与门房，以原先可能卡住的旧档 Continue→四向走动→出入门→存档→退出→再读；检查坐标、方向、Warp、碰撞、音乐/地点、关都旧档。失败不得视为修好。该修复不保证兼容所有已改变 SRAM 布局的历史版本。
- 本轮只交开发增量/从最新干净 HEAD 全量的互斥补丁合集；不由 AI 编译 ROM 或 Git Commit/Push。正式版本 `.243→.244`，TEST-231 不变。

---

## MUS-243-DOC-001 / PAL-5.62.243 — 用户实机验收后正式收口（提交准备，尚未 Git Commit）

- [x] 用户在 MUS-243 交付后确认：**已按上一轮所列项目实际测试，均未发现问题**。本轮将此作为用户实测反馈，涵盖 Route30↔Route31 双向无缝同曲续播、步行/骑行、GSC/RBY/RND 等模式、不同地点应正常换曲，以及已要求的门房和既有功能回归；这不是 AI 自行运行游戏的结果。
- [x] LOC-240 地点乱码修复已有用户实际确认：存档和 Continue 地点名称正确，门房内保存显示 Route31；门房在 Gold 原始地图资料中归属 `LANDMARK_ROUTE_31`，原版 Gold Continue 本身没有 PAL 的地点显示扩展，现行显示保留。
- [x] JSON-TRACK-002 已应用：根目录取消全局 `*.json`，仅指定生成/缓存目录忽略 JSON，源合同默认可被 Git 发现；门房合同 JSON 不覆盖、不重复创建。用户尚未确认新的 Git Commit。
- [x] MUS-241→242→243 音乐修正保留：已开放 8 张城都活动地图的 Gold 曲目、门房按来源继承、同曲缓存与无缝续播，修复 `.rbyFamily` 未定义标签并加入离线预检。**仅8个已激活槽位有运行时音乐映射，不是222个城都稳定ID全部完成。**
- [x] 本轮仅整理收口文档及按项目要求重新生成开发状态→收口状态增量、`.239` 已确认 HEAD→收口状态全量、工具反向隔离和两笔拟提交日志；**不修改已验收游戏 ASM、地图/音乐数据或版本 `PAL-5.62.243`**。
- [ ] **提交前用户侧最终确认**：如有可用的最新正式 Red/Blue MAP，可据实际产物核对 Bank 空间；当前对话没有提供 `.243` 新 MAP，不能凭旧 MAP 写“空间已审计通过”。用户自行按下述双提交顺序 Git Commit/Push 并确认新 HEAD。
- [ ] 下一批未开放地图/室内音乐仍待逐图接入及独立验收；门房全部变体、老存档与所有平台兼容不由本次反馈自动推定全覆盖。

---

## MUS-243 / PAL-5.62.243 — 30/31号道路无缝同曲播放位置保持（历史开发条目；最新验收见上方 DOC-001）

- [x] 金版原版 `home/audio.asm` 与 Route30/Route31 的同曲规则对照；确认当前仅映射 8 个已激活槽位，不是所有 Gold 地图。
- [x] 进入新 Header 前快照上一 Gold 场景 + RBY ID，同曲且当前缓存正常时跳过无缝连接的重播入口；步行/骑行开关/Surf 单独判断。
- [x] 增加 9 项不编译 ROM 的场景与故障注入检查，执行 ASM 预检及既有审计。
- [ ] 用户在本机编译正式红蓝与 MAP，验证双向无缝走路/骑行续播、不同曲正常换曲、门房、战斗、存读档和关都回归。
- [ ] 用户决定验收与 Git 提交；前轮 JSON、LOC、MUS-241/242 都未有新的已确认提交点。

## MUS-242 / PAL-5.62.242 — 修复 MUS-241 缺失的汇编局部符号并建立交付前预检（待用户构建，2026-10-29）

- **用户构建失败证据**：用户应用 MUS-241 后 `main.asm(3068) -> engine/menu/options_menu.asm(968): Unknown symbol "ResolveMusicStyle.rbyFamily"`；因此 MUS-241 不可按“成功编译”或“游戏已验收”表述。前轮 Python 60 项场景静态测试没有验证局部标签实际存在。
- **精准修复**：原 `ResolveMusicStyle` 中 `jr .rbyFamily` 引用不存在的局部标签，改为 `jp .legacyStyle`，对 RBY/RBY+C 仍走既存基础风格路径；不动 Gold 稳定 ID、门房来源、JSON 追踪、LOC-240 地点或存档布局。正式版本 `.241 -> .242`；测试版不变。
- **持续防回归**：新增 `tools/asm_symbol_preflight.py`，默认全工程检查 `jr`/`jp`/`call` 引用的局部点标签是否在同一 RGBDS 全局作用域定义；兼容无冒号局部标签、宏定义与行内宏标签。`tools/tests/test_asm_symbol_preflight_242.py` 使用真实 MUS-241 故障注入、跨作用域和宏用例校验检查器。**后续任何修改 ASM 的窗口，交付前必须运行** `python tools/asm_symbol_preflight.py` 及相关工具测试；失败不得交付。
- **强制边界**：静态 PASS 不涵盖绝对/跨文件符号、条件编译、`JR` 距离、Bank/SECTION 超额或 RGBDS 链接；本项目禁止 AI 编译 ROM，故用户本机应运行 `python tools/asm_symbol_preflight.py --build`（可用 `--rgbds-prefix` 指定工具路径），触发 Red/Blue 正式和 TEST 两色及正式 MAP 的真实构建。构建失败不能验收，成功也需实机音乐回归。只交本轮增量与从最后确认 HEAD `2b0d2607` 起的累计全量；用户 JSON/LOC/MUS-241 均已应用但未提交。AI 不 Commit/Push。

## MUS-241 / PAL-5.62.241 — 城都 8 张已激活地图的音乐场景与中立门房（开发待验，2026-10-29）

- **前置工作区**：用户确认已应用 JSON-TRACK-002、LOC-240（地点显示实机已正常），尚未 Git Commit。此次只追加 MUSIC-241 增量；不重复添加/覆盖之前 JSON、Save/Continue 名称修复。正式版本 `.240 -> .241`，`TEST-231` 不变。
- **原版核对**：MUS Gold `data/maps/maps.asm`：若叶镇 New Bark、29 号路 Route29、吉花市 Cherrygrove、30/31号路同为 Route30、向导家 Cherrygrove、桔梗市 Violet、31号路门房 Route30（但中立门房按进入来源继承，不固定开一段歌曲）。旧 `NPC-5.62.243` 的 `LookupJohtoMapGSCMusic` / `CheckJohtoMusicSceneTransition` 仅作五模式与场景缓存参考，绝不直接使用旧物理地图号。
- **新工程映射**：以 `(wCurMap=$FC, region=Johto, stable local ID)` 经 `GetJohtoActiveSlot` 查找 8 条活动槽位的 Gold 主题；状态/表 `0,1,2,3,4,125,5,6` 对应 8 槽。只有当前地图默认 BGM 才参与 Gold 场景映射，战斗、Surf、飞行、GB Player 直选曲继续走现有全局风格路径；Bike Song Off 的骑行仍使用当前地点主题。
- **门房音乐**：进入门房的已登记 Warp 在源 ID 被覆盖前，写入原来闲置的 `$D7C9` `wJohtoGateMusicSourceLocalID`。来自 Route31 ID4 时保留道路 RBY/GSC/RND 已在播曲，来自 Violet ID5 时保留城市曲；旧存档或非法来源退回 Route31 主题，不能从共享句柄 `$FC`、`wWarpedFromWhichMap` 或陈旧 `wLastMap` 猜来源。返回同侧尽量不重启，跨到另一侧选目标地点曲。门房仍**不额外显示地点牌**，地点显示独立。
- **缓存与存档**：`$D7CA` 由旧未用字节记录最近 Gold 场景，不变更后续 WRAM/SRAM 地址或存档长度；跨不同 Gold 场景（即使同 RBY ID）仅在 GSC/GSC+C/RND 且播放地图 BGM 时清除旧原曲缓存。RND **不在进门/地图载入时主动抽曲**，只在真正启动新曲时重抽；RBY/RBY+C 不被强制切换。切回关都清除场景标识并在相应模式下恢复正常选曲。
- **交付和验收边界**：本轮静态测试与补丁回放不等于 ROM 通过。AI 不编译 ROM、Commit 或 Push；等待用户本机红蓝 ROM 构建、新 MAP、五种模式、门房两侧进出、Bike Song On/Off、Surf、存读档、关都与渡轮回归。详情 `docs/JOHTO_MUSIC_SCENES_241.md`。

## P6-LOC-240｜PAL-5.62.240 — 城都存档／Continue 当前地点乱码修复（开发待本机验收）

- 本轮以用户已应用、**尚未提交**的 JSON-TRACK-002 作为增量前置；用户主 ZIP 的已提交 HEAD 仍为 `2b0d260729dbf28bc72dd9a739e646b1bfaf35e8`，不是新 Git 提交。全量补丁从原 `.239` ZIP 累计包括 JSON-TRACK-002 和 LOC-240，不能和增量叠加。
- **静态根因**：`DisplayContinueGameInfo` 与 `PrintSaveScreenText` 原本都 `callba GetMapNameForSaveScreen`。城都的 `$FC` 经 Bank `$35` 特殊入口可返回名称指针；若文本在 `$35`（桔梗市 `JohtoPilotVioletName`），随后 Bank `$1C` 的拷贝循环会从错误 ROM Bank 读取。部分旧地名位于 `$1C`，因此不是所有城市都必然乱码。
- **修复**：两个菜单统一改走浮动 ROMX 的 `GetCurrentMapNameForSaveScreen`；仅对 `(wCurMap=$FC, region=Johto)` 按稳定 ID 的活动地图 profile 求 Gold Town Map 地标，在城都浏览代码所在 Bank 直接复制名称到 `wBuffer`，将 `_` 换成空格。其余关都路线继续调用旧 `GetMapNameForSaveScreen`，保留关都菜单逻辑。GuideGent 室内归吉花市，Route31VioletGate 归 Route31；不改变场景地图切换地名牌、Fly、Warp、存档结构或音乐。
- Bank `$1C` 近满，新增代码全在浮动 ROMX；正式版本升到 `.240`，TEST 仍 `.231`；附静态回归工具，但**未在本环境编译 ROM 或手机实测**。用户需本机红蓝正式编译、核对新 MAP 并测试城都 8 个活动槽位的存档／Continue；尤其桔梗市、向导家、门房；再检查关都存档页面和 Continue、地图切换提示牌、存档后实际读档。测试通过后才可清理并准备 Git 提交。
- 音乐问题暂不合并到本轮：城都场景选曲和门房来源继承 BGM 为另一个专项，避免一个补丁同时改变显示和音频导致定位困难；已有 JSON 规则修改也不应丢失。

## P6-DOC-001｜PAL-5.62.239 — 当前 Worktree 清理与门房合同追踪（提交准备）

- **真实基线**：用户 2026-10-28 22:39 导出，`常规功能备份`，HEAD `5c41a6960556732d8364eb7ec87594e330784969`（P5 / `.233`）；当前为 `.239` Worktree，尚未获本轮 Git Commit 确认。本次只整理源文件追踪和记录，不改游戏 ASM、图块、Warp、音乐设置或版本。
- **JSON 处理**：手机本地 `tools/johto_pilot_door_contracts.json` 先前未被 Git 追踪，补丁中的新增文件与现有同名文件冲突。现用户用包含忽略项的 ZIP 提供了完整 8,702B 合同；SHA256 `714507d2a49dd299d9b0a1bdef7f8497d7a230a9f75b42e665f8f934ad4815e5`。只调整 `.gitignore` 对此精确文件例外，不修改合同内容。清理增量**不得再次添加 JSON**；正式工具提交时须由用户把现有文件纳入 Git 索引。
- **运行证据分级**：用户反馈门房左右进出已未观察到卡门或按键异常，属于用户实测反馈，但并非八条 Warp 各场景、Red/Blue 全矩阵验收；向导家曾有实机进出通过。包内正式 Red/Blue `.239` MAP 已附带，符号可见 `Map Name Sign` 和 `Menu Shortcut Helpers`，本轮不由 AI 重新链接 ROM。
- **本轮静态复核**：使用 MUS-1.0.1 + NPC-5.62.243 参考，城都专项静态审计 66/66，门房合同审计 12/12，Python 测试 59/59；这些不是手机结果。地图与工具的累计未提交差异依项目规则拆成功能与工具两笔，避免重复把同一个 JSON 当作新增补丁覆盖现有文件。
- **延期**：门房继承进入来源的 BGM、各城都场景的 GSC 选曲/缓存和 Options 音乐设置尚待专项开发；不得借本次清理把音乐错误写为验收。还有室内存读档和关都综合回归待补充。

## P6-BANK-001｜PAL-5.62.239 — P5 干净工程累计恢复与 Bank $3D 容量修复（待红蓝链接验证）

- [x] 以用户 2026-10-28 新导出的干净 P5 / HEAD `5c41a696` 为唯一源码基线，回放 GATE-005 累计功能源码（P6 室内、GATE/地图、工具和地名牌），不覆盖导出元数据与旧红蓝 MAP。
- [x] 原 P5 红蓝 MAP 均记录 Bank `$3D` 只余 `$006c`（108B）；GATE-005 地名牌增加城都名称和解析代码，`Menu Shortcut Helpers` 仍固定 `$3D`，因此出现无法放置该节的链接报错。现将两段仅经 `callba` 从 ROM0 调用的 `Menu Shortcut Helpers` 和 `Map Name Sign` 改为浮动 ROMX，保留内部名称指针在同一段，免再次挤占固定 Bank `$3D`。
- [x] 检查代码位置与调用约定，新增只读的 Bank 布局静态回归检查；不修改原关都门口、门毯及门房运行逻辑。
- [ ] **必须用户本机重新编译 Red/Blue 并提供本轮新 MAP**，确认 `$3D` 容量及新分配 Bank，无其它链接断言或溢出；ZIP 自带 MAP 为 P5 旧版，不能作为 `.239` 新链接证据。
- [ ] GATE-005 之前门房左侧 A/B 失控及名称牌问题仍按用户实机反馈再验收，不能因补丁恢复、静态检查而宣布修复成功。

## P6-GATE-005 / PAL-5.62.239 — Route31/Violet 左侧回程与地点牌候选修复（实机未验）

- [x] 用户手机反馈 `.238` 从门房往桔梗市左口出来后，会出现下方空白地点提示框、控制短暂异常，需要多次按 A/B；用户还要求门房内部**不弹出地名牌**。`GATE-004` 静态完成不代表手机验收；不得继续称之为通过。
- [x] 以用户 2026-10-28 20:28 导出的 **实际 PAL-5.62.238 Worktree ZIP** 为唯一增量基线；部分先前补丁没有应用，不能再要求叠加旧 GATE-004。
- [x] 对照旧 `NPC-5.62.243/docs/JOHTO_GATEHOUSE_READ_FIRST.md` 的中立门房规则，在 `engine/overworld/map_name_sign.asm` 使用共享地图句柄 `$FC` + 城都地区 + stable ID6 精确屏蔽过渡门房的名称牌；不会屏蔽关都门房或整个城都。
- [x] 同时修复共享 `$FC` 被当成关都真实地图号读取 MapNames 的风险：已启用城都 ID0..5 及 ID125 的地名从当前 stable ID 解析到 map-sign 自身 Bank `$3D` 的本地字符串；门房直接继承前一地点，不触发空白框；不增加已拥挤 Bank `$1C` 的文字数据。游戏自身 Town Map/Fly 名称表不变。
- [x] 新增源码静态预检与错误注入测试，拦截“漏屏蔽门房 / 错区域 / 回退关都 $FC / 使用错误文本 Bank”等回归。保留目前 `.238` 的门毯碰撞-only、无强制左右迈步及关都原始控制状态路径。
- [x] 这次上传的 ZIP 中缺少 `tools/johto_pilot_door_contracts.json`；依据此前**已向用户交付**的 GATE-004 全量补丁原样恢复，并使用 MUS 审计 12/12 通过；不复用 GATE-004 其它未应用的代码。
- [ ] **待用户编译及手机实测**：红蓝 ROM/MAP；31 路、门房、桔梗市两条 Lane 反复出入；左口第一次出去无空白框、不需 A/B 解锁；门房内部无地名牌；进入桔梗市显示正确名称、相邻预览不花屏，旧向导家及关都门房正常。
- [ ] 如果左口控制异常仍存在，需获取 `.239` 新 ROM 对应的视频或逐帧记录，继续查 `wd730/wd736`、Joypad/map script 时序；本轮**没有证据证明**空白框就是无法移动的唯一原因，不强制清除脚本标志以免破坏关都。

## P6-GATE-002 / PAL-5.62.237 — 修复本机 RGBDS 活动槽位 ASSERT（编译待重验）

- [x] 用户本机 `main_red.o` 报 `data/johto_stable_id_slots.asm:25 Assertion failed`。已定位原版 GATE-001 将 `NUM_JOHTO_ACTIVE_MAPS` 扩至 8，却遗留 `ASSERT ... == 6`；此前 59 项静态审计没有覆盖汇编中的字面断言，这是交付漏检，不能称上一版编译通过。
- [x] 同步改为 `ASSERT NUM_JOHTO_ACTIVE_MAPS == 8`，不改 stable-ID 到活动槽的路由字节、地图 Header、Warp、地图资源、游戏版本或已经能进出的旧房屋。
- [x] 迁移审计新增 `rgbds_literal_active_count_asserts`：扫描实际 ASM 的硬编码活动槽位断言，检查所有值与常量一致，要求稳定槽位表必须保有断言；加入故意恢复 `==6`、其它 ASM `==6` 和删除断言的负向测试。
- [ ] 用户重新执行 Red/Blue 正式构建并查看此错误是否消失、是否出现后续汇编/链接问题；提供真实新 MAP 后再审核 Bank 空间。未进行 AI 编译或手机验收，不写成 PASS_BUILD。

## P6-GATE-001 / PAL-5.62.237 — 桔梗市 ID5 + 31号道路门房 ID6（地图功能开发待本机验收）

- [x] **实际移植**：在已应用 P6-TOOLS-002 的 PAL-5.62.236 主项目上，依据用户 MUS-1.0.1 Gold 主参考和 NPC-5.62.243 成熟 RPP 运行素材，新增桔梗市 20×18 与东西门房 5×4；金版原始 `.gold.blk` 独立保存，运行版采用旧分支紧凑图块。逐像素复核：城市 368,640 像素、门房 20,480 像素与 MUS 底图零差异。不是整批自动导入其它地图。
- [x] **稳定编号与资源**：激活 stable ID5=VioletCity、ID6=Route31VioletGate；原 ID0–4 / ID125 不变，活动槽 6/7；独立门房 Tileset30/Bank `$47`，户外资源进入已存在 Bank `$43`，城都源资源保持 Bank `$42`；新增 Header、两张运行 `.blk`、纹理与 Blockset、地图属性和 Town Map/飞行地标查表，未改关都物理 ID、存档结构或旧五图连接。
- [x] **八条门房 Warp**：31号路 (X4,Y6/7) 左入门房右侧 (X9,Y4/5)；桔梗市 (X39,Y24/25) 右入门房左侧 (X0,Y4/5)；门房两侧在朝外 LEFT/RIGHT 撞边界时分别返回原城市和道路。目标 map 与 ordinal 全部按零基重登记，不照搬 Gold/旧 RPP 旧地图号；未开放的室外边界、桔梗市其余室内依旧封闭。
- [x] **防止卡门及错误出门**：仅已登记门口、对应方向绕过地形双砖碰撞；踏上实体门格的同一步触发 Warp。门房内门毯只按指定 LEFT/RIGHT 碰边界触发；额外检查避免站在毯上向上/向下撞墙时误传送。非门房、非城都地图继续走旧 RPP 碰撞代码，不强制自动步出门格。
- [x] **离线检查**：MUS 地图布局底图像素一致；当前静态迁移审计 59/59 通过；MUS 环境下 Python 单测与负向测试 44/44 通过；门房 ID6 已登记明示的八条入口/出口合同，取消旧工具“无门房已开放”的错误固定假设。没有 AI 编译 ROM，既有 MAP 并非 `.237` 构建产物。
- [ ] **本机必测**：Red/Blue 正式编译和最新 MAP，查 ROM0、Banks `$41/$42/$43/$47` 空间；31号路两格朝 LEFT 单次入门房、桔梗市两格朝 RIGHT 入门房，进门落点、四格方向门毯按外侧方向出门、反向立即返回、侧向撞墙不误出、读档后继续往返；原向导家自动下迈、五张户外地图连接、渡轮、Town Map/Fly、关都房屋回归。只有实机通过才能标记 P6-GATE-001 已验收/准备提交。

## P6-TOOLS-002 / PAL-5.62.236 — MUS 主参考的室内转换、Warp 到达与门房方向审计（工具-only，开发待验）

- [x] 按用户最新要求，`MUS-1.0.1.zip` 是唯一主 Gold 参考；不要求同时上传 pret。当前 PAL `.236` 工程是转换目标，NPC-5.62.243 旧 RPP 只作为实现经验来源，不混作 Gold 数据源。
- [x] 修复 `johto_indoor_collision_adapter.py`：支持明确指定 `--gold-map/--gold-tileset/--rpp-tileset`，并能从 `home.asm` 解析当前 ROM0 `JohtoHouse_Coll`，不再错误地只查 `data/collision.asm` 或默认比较旧 `gate` Tileset。
- [x] 适配 `johto_indoor_registration_generator.py` 到当前 stable-ID 架构：核对 ID125→slot5、Header 指针/Bank、资源描述符、source record、4×4 runtime/reference layout、三条 `$FB` Warp、ROM0 碰撞表断言；未知地图 fail-closed，不自动写 ASM。
- [x] 新增 `johto_pilot_door_contracts.json`、`johto_warp_arrival_audit.py` 和 `johto_gatehouse_behavior_audit.py`：对比 MUS 原始 Gold `DOOR` / `WARP_CARPET_DOWN`、Gold 一基 Warp 号、RPP 零基登记序号、进门单次 UP、室内双 DOWN 出口、户外自动 DOWN 到 `(25,10)`；统计 MUS 24 个门房地图/100 个 Warp，并要求未来门房先有明确合同。
- [x] 新增 `johto_indoor_pipeline.py`：一条命令在隔离目录产出候选 `.blk`、像素映射、碰撞复核、注册审计、到达合同、Gold 门房库存和输入 SHA-256；不会改 RPP 项目、不会编译 ROM、不会自动启用新地图。
- [x] 使用 MUS 单独执行完整管线：当前 PAL 静态审计 51/51 PASS；Gold 门/Warp 清单 PASS；房间像素候选为 `PIXEL_CANDIDATE_ONLY`；注册审计 `PRESENT_STATIC_ONLY`（14项）；到达审计 17/17；Gold 门房审计 10/10；碰撞审计 14 项需人工/运行时复核，符合 DOOR 与方向门毯不能自动等同的安全策略。
- [x] Python 单元/负向测试 32/32 通过，含错误出口坐标、错误自动迈步方向、删 Header descriptor、未注册地图、未有合同就激活门房 ID 等故障注入。
- [ ] **强制未验项**：没有编译正式 Red/Blue ROM、没有新 MAP、没有手机运行证据。当前输出必须保持 `OFFLINE_REVIEW_REQUIRED`、`runtime_verified=false`、`rom_built=false`、`phone_accepted=false`；不可把 32 项测试通过当作游戏验收。
- [ ] 运行命令：`python tools/johto_indoor_pipeline.py --project . --gold-root <MUS-1.0.1解压目录> --output <项目和MUS目录之外的全新空目录>`。Pillow 用于像素转换；若缺少则 `python -m pip install Pillow`。本轮未修改游戏 ASM、地图、ROM 版本号或测试版本号。

## P6-TOOLS-COMPAT-002 / pret 与 MUS 双参考源码二次审计（待用户应用验证）

- [x] 本轮 002 取代尚未应用/未验收的 COMPAT-001 包；以当前 PAL-5.62.236 + P6-TOOLS-001 导出工作区为增量基线，不需要先应用 COMPAT-001。
- [x] 除原地图、Warp、连接与碰撞源码语义比较之外，加入引用的 Gold `.blk` 原始字节 SHA256 和 `data/tilesets`、`gfx/tilesets` 所有资源字节 SHA256，缺失引用文件直接报错；不允许因文件同名而错误批准变化后的地图。
- [x] 完整审核两份用户参考源码：pret、MUS 均 368 张注册地图、1241 个 Warp、142 条连接，239 个 `.blk` 与 tileset 资源的实际内容一致；门/Warp 审计与当前 `.236` 试点审计两边均通过。
- [x] 另列 MUS 与 pret 7 个不同的 `maps/*.asm` 事件脚本；即使 Warp 表一致，也不声称完整脚本行为相同。两边分别通过 5 项室内/30、31 号道路离线 Smoke 测试；更新后的 Python 单测 27 个测试，26 个通过、1 个在无环境变量时跳过，另对两个真实 Gold 根单独补跑全部 Smoke。
- [ ] 仅证明离线迁移工具双参考源码兼容；未由 AI 编译 pret/MUS ROM，也未执行游戏手机测试。MUS 的地图连接宏结构不同，工具解析的是有效连接数据而不是要求源码文本一致。两份 `.rgbds-version` 分别为 1.0.0、1.0.4；用户本机如需分别构建 ROM，应使用各自规定版本。

## P6-TOOLS-COMPAT-001 / pret 与 MUS Gold 源码双项目兼容（工具开发待验）

- [x] 新增只读 `tools/johto_gold_compat.py`：自动识别 pret `pokegold-master/` 嵌套目录和 MUS 平铺目录；支持 `--gold-profile auto|pret|mus` 严格校验，遇到缺文件、多个候选根或 profile 不符时 fail-closed，不自动改源码或解压 ZIP。
- [x] 将 Gold 根目录解析接入门碰撞审计、室内候选转换、资源审计、连接基线、离线候选管线、批处理与迁移审计；默认自动识别，既有单独工具也能显式指定 profile。
- [x] 对本轮两份真实源码实测：pret 与 MUS 均为 368 张注册地图、368 份属性、417 个共享 Block 布局别名、1241 个 Warp、142 条直接连接和 28 份碰撞表；地图名、尺寸、布局引用、连接、Warp 与碰撞表的语义清单一致。门/Warp 审计两边均 PASS；向导家图形转换两边均得到 12 个已使用区块、0 个未映射区块（仍只是像素候选，不等于碰撞/ROM 验收）。
- [x] 新增 `tools/tests/test_johto_gold_compat.py`，覆盖平铺/嵌套根目录、MUS/pret profile、profile 不符、重复根目录拒绝，以及语义差异必须报警。
- [ ] **边界**：这证明当前离线迁移工具可兼容两份参考源码，不代表两个 ROM 已编译或运行。pret 声明 RGBDS 1.0.0，MUS 声明 1.0.4；本环境没有 RGBDS，按项目要求不编译/链接 ROM。用户本机应按各自 `.rgbds-version` / `INSTALL.md` 的对应工具链分别构建；如果两份文档/版本声明冲突，先核对工具版本，不自动改 `.rgbds-version`。

## P6-TOOLS-001 / PAL-5.62.236 — 迁移 NPC-5.62.243 首批离线 Python 工具（工具补丁待验）

- [x] 只迁移经过选择的工具模块，不整包复制 185 个 `.py`：Gold 源地图解析、离线候选转换/验证、Gold 142 条直接连接基线、Gold 门碰撞/ Warp 语义，以及适配当前稳定 ID / `$FC` 运行句柄 / `$FB` 登记 Warp 的 `johto_pilot_migration_audit.py`。
- [x] 将 `johto_rpp_pipeline.py` 的当前项目接入检查从旧 `data/mapHeaders` / `johto_native_maps.json` 适配到 `data/johto_pilot_map_headers.asm`、活动槽位和当前室内登记表；`--adjacent-pair` 使用独立 Gold 源拓扑校验，不把旧 RPP Header ABI 审计误用在当前工程。
- [x] 当前源码专项静态审计：52/52 项通过（包括 Gold 368 图/ Warp 来源、142 条 Gold 连接基线、Route30↔31 条带、六个活动资源槽、ID125 稀疏映射、向导家实体门、两格 DOWN 门毯、ROM0 碰撞表和自动迈步控制流）。
- [x] 工具测试 21/21 通过；含故意删除反向连接、删除 Route30 SOUTH Header 首字段、错门坐标、误把 `$12` 门毯加入 STEP_ON 表、自动步进方向反转、碰撞 `$37` 缺失、Warp 路由缺一条、ID125 错映射等负向用例。离线候选管线成功生成 Route30↔Route31 配对及 GuideGentsHouse 候选。
- [ ] **边界**：以上均为静态/离线工具验证；没有编译 ROM、没有生成当前游戏的新 MAP、没有手机验收，也没有把候选地图自动导入游戏。报告中的 `runtime_approved/build_performed/phone_accepted` 必须保持 false。
- [ ] 本机可运行：`python tools/johto_pilot_migration_audit.py --project . --gold-root <pokegold-master路径> --reference-root <NPC-5.62.243源码路径>`；离线候选转换和房间像素比较依赖 Pillow（缺失时执行 `python -m pip install Pillow`）；候选输出必须放在项目和 Gold 源码目录之外，例如 `python tools/johto_rpp_pipeline.py --gold-root <Gold路径> --project . --output /tmp/johto-route30-31 --adjacent-pair Route30 Route31`。
- [ ] 第二批室内转换、到达落点/自动迈步合同及门房方向审计已在 P6-TOOLS-002 实现；不要直接启用旧版 `johto_map_release_audit.py` 或 `johto_rpp_connection_guard.py` 的旧运行时 ABI 模式。当前审计已覆盖向导家和现有 30↔31；后续新房屋需增加明确合同与负向测试。

## P6-INDOOR-006 / PAL-5.62.236 — 对齐用户提供的已实测 RPP 金银旧分支门禁（卡门复修，待手机验收）

- [x] **用户反馈**：应用上轮 P6-005 后，吉花市向导家门口依然像障碍物，按上无法踏入；故 P6-005 没有获得运行验收。此前“将 `$37` 加入白名单、移动表到 ROM0 就能进入”的判断不能冒称已证实。
- [x] **以旧 RPP 分支而非 Gold 图块为执行基准**：对照用户附带 `参考源码/NPC-5.62.243_金银分支` 的 `home/overworld.asm::CollisionCheckOnLand`、`CheckWarpsNoCollisionLoop` 和 `engine/overworld/johto_route33_collision.asm::JohtoCherrygroveHouseDoorStepAllowed`。旧分支在精灵阻挡检查后、通用 tile-pair/passability 前按吉花市地点/方向/玩家坐标放行，然后在实际登记的门格踏格时优先直达 `WarpFound1`。此前新工程漏了两层受限入口逻辑。
- [x] **第一层：单门精确放行**：`home/overworld.asm` 的 `CollisionCheckOnLand` 新增条件 `wCurMap=$FC / wCurRegion=Johto / wCurLocalMapID=2 / UP / (Y10,X25)`，从现有 sprite/edge 检查后直达 `.noCollision`；其它位置仍执行原 tile-pair 和 `CheckTilePassable`。不为所有 `$37` 增加特殊通行权限，也不修改跳崖。
- [x] **第二层：门格直接 Warp**：`CheckWarpsNoCollisionLoop` 已核对 `wWarpEntries` 的位置 `(Y9,X25)` 后，且相同地区/地图/方向满足时，恢复栈中的 HL/BC 并跳 `WarpFound1`，复制旧分支做法但只作用于唯一开放的向导家；其它地图和触发类别继续原通用门砖/毯处理。
- [x] **保留 P6-005 双向修复**：仍从室外门 `(9,25)` 入室、室内落 `(7,2)` 无自动步进；两个 `(7,2/3)` 的方向门毯朝下碰边缘出屋，返回室外 `(9,25)` 再 `PlayerStepOutFromDoor` 自动 DOWN 到 `(10,25)`。房间图块、Header、固定 ID125、Warp 表、ROM0 碰撞数据、已验五张户外图/关都图均不改。
- [ ] **未验收**：本环境不执行 ROM 编译/链接和手机实测；请本机重新编译正式红蓝、检查 ROM0/Bank 空间，并使用新启动 ROM 测真正的单次 UP 进门、入室第一按 DOWN、双出口、返回自动迈步和立即反向再入；不得使用旧即时存档假装加载新代码。

## P6-INDOOR-005 / PAL-5.62.235 — 吉花市实体门 / 室内方向门毯往返联合修复（开发待验）

- [x] 参考 Gold 的 `GuideGentsHouse (2/3,7)` 两格 `WARP_CARPET_DOWN` 与吉花市 `(25,9)` `DOOR` 及旧分支 `JOHTO_GOLD_DOOR_GATE_POLICY.md`；原房间运行块还原的底图与 Gold 像素一致，不修改 `.blk`、尺寸或固定 ID125。
- [x] 根因 1：`JOHTO_PILOT / JOHTO_HOUSE` 碰撞白名单原在 ROMX `$43/$46`，多个调用者按 `wTilesetCollisionPtr` 直接读未切 Bank 地址；不依赖“刚好当前 Bank 正确”，将两份总计 12B 的列表迁到 ROM0，保持 GFX/Block 和旧关都资料不变。
- [x] 根因 2：将 `$12` 当作普通 STEP_ON Warp 会在走上 (7,2)/(7,3) 时立即传送。改为可站立，普通走到出口时不传送；只有从 y7 朝 DOWN 撞边界才通过现有 `CheckWarpsCollision` 触发，向上离开/左右换 Lane 不触发。不改变已验收的户外实体 DOOR 踏格机制。
- [x] 保留入口 `(9,25)` 到室内 `(7,2)`、室内两条出口到户外 `(9,25)` 的登记式 Warp，确认目的地 tileset 变化会在 `LoadTilesetHeader` 重定位；入屋/室内读档后由 `IsPlayerStandingOnWarp` 重新设置目标门毯站立标志，不依赖室外遗留状态；落回户外的 `$39` 被 `IsPlayerStandingOnDoorTile` 识别，`wd736 bit0 -> PlayerStepOutFromDoor` 自动 DOWN 到 `(10,25)`；室内毯不在 DoorTileIDPointers 内，因此入室不自动迈步。
- [ ] 按原项目规则，AI 不编译链接 ROM。本机正式红/蓝编译/MAP 查 ROM0 与 Bank43/46 空间；手机逐条验收单格 STEP_ON 入室、双 Lane 踏毯不传送、从毯再 DOWN 传送、返回自动 DOWN 一格、立即反向再进、左右擦边、存读档/旧五图/渡轮/关都房屋。未提供用户实测前不得标记为 PHONE PASS。
- [ ] 当前室内仅启用两条 DOWN 毯；将来扩展 JOHTO_HOUSE 其它类型 Warp 时不得直接沿用本轮“整 tileset 跳过无碰撞触发”分支，需先拆分同图的 DOOR/STAIR/方向门毯检测并回归测试。

## P6-INDOOR-003 / PAL-5.62.234 — 向导家实体门卡住修复（开发待验）

- [ ] 参考源码前置核验：P4 含 Gold/旧分支交接 ZIP 存在且完整；须沿实际 Gold `DOOR` / `WARP_CARPET` 行为核对，不照搬旧 mapconst。
- [x] 根因定位：吉花市 Gold block `$14` 的入口 `(Y9,X25)`，朝上移动时碰撞测试检测 8×8 图块 `$37`，现有 `JOHTO_PILOT` 允许列表无 `$37`，故玩家无法踩上已登记的 Warp。门下半图块 `$39` 原本已在 Warp 检测表，但只有 `$39` 不足以触发。
- [x] 在独立城都户外碰撞白名单加入 `$37`，保留其它图块；在已存在的原生门框表登记 `JOHTO_PILOT / $39`，让进入/返回复用原 `PlayerStepOutFromDoor`，从 Gold DOOR 落点向下自动离门。室内 Gold 门毯在该旧版曾被错误列为 `$12` 踏格触发；现已被上方 P6-005 的 DOWN 碰撞触发方案取代，不得恢复。未增加 ROM0 功能入口，最终空间需新 MAP 确认。
- [ ] 用户本机编译正式红蓝、提供新 MAP（确认 ROM0 和 Bank），在 `(10,25)` 朝上走入 `GuideGentsHouse`；内部 `(7,2)/(7,3)` 走出、出门自动向下走、立刻反向重进；两格分别往返、室内存读档和原 P5 户外/渡轮/关都房屋回归。
- [ ] 首批新城都室内底层仅在上述场景用户实机确认后可进入正式清理。其它城都房门无登记 Warp，仍不能进入；$37 同形普通门砖现在可走上，后续接入其它房屋时应评估其闭门表现。

## 城都 P6-001 第一张室内（PAL-5.62.234，开发待验）

- [ ] 用户本机编译正式红蓝 ROM 并提供最新 MAP：核对 ROM0 未增长、新增 Bank `$46`、旧存档区地址不变。
- [ ] 吉花市 `(9,25)` 向导家进门、房内 `(7,2)/(7,3)` 双出口返回；核对房屋图形/碰撞/音乐/地名。
- [ ] 在室内存档、读档，再出门；Town Map 高 ID125、渡轮、旧户外地图/关都室内回归。
- [ ] 若测试失败先局部修复，不把 P6-001 和下一张房屋一起提交；用户要求验收清理时按项目规范交三件套。
- [ ] 后续门房、洞穴、水域、多 Tileset、跨区域与通用边界逐类真实场景验证。长期技术记录见 `docs/JOHTO_MIGRATION.md`。

## P5-DOC-008 / PAL-5.62.233 — 五张城都户外地图累计验收及提交收口（2026-10-28）

- [x] **底层通用化**：四方向使用地区/稳定 ID 路由；地图属性驱动室外、Town Map 地标和音乐，地名牌完整 ID 比较；登记式 Warp 为 fail-closed 空路由，渡轮保留旧行为。
- [x] **Route30 / ID3**：Gold 原始10×27，运行版11处跳崖碰撞兼容，吉花市↔30号道路双向连接。
- [x] **Route31 / ID4**：Gold 原始20×9，运行版8处兼容，30↔31有边界的10列×3行连接条带；未开放门房与洞穴入口保持关闭。
- [x] **Header 编译断言修复**：Route30 NORTH+SOUTH 曾少写 SOUTH 首字段，造成33B!=34B；最终补回 `$FC`，保留34B断言，并逐字段静态核对五张地图 Header。
- [x] **用户实测**：用户报告五张地图均跑过，30↔31树林显示、双向行走和跳崖未发现问题。此前 `.231` 的基础场景回归也已报告正常；不扩大为未测路径全通过。
- [x] **红蓝 MAP**：最新 `all_maps.zip` 正式红蓝 MAP 有五张城都 Header、资源及八条有向连接符号；ROM0 各余594B，Bank `$1C` 红版0B、蓝版39B，`$3D` 各余108B；后续优先 ROMX。
- [ ] **待后续实际触发验证**：真正城都室内/门房/洞穴 Warp、不同 Tileset、较大/非连续 ID 显示、详细存读档与关都全量回归、未开放217张地图。
- **本批正式提交**：按最新版模式 B 单提交，累计 P4 已确认 HEAD `6e65ad26…` 的 `.230` 到 `.233`；此前 `.231/.232/.233` 都没有单独提交记录，故不能只写两条道路。清理增量与 HEAD 全量二选一。下一批实测通过就及时收口，不再长时间叠功能。提交及 Push 由用户执行。

# P4-DOC-007 / PAL-5.62.230 — 城都阶段2收口（已获用户主路径验收）

- [x] **新编号保持不变**：若叶镇 0、29号道路 1、吉花市 2；阶段2新增吉花市与29号道路西口东西往返，北侧30号道路仍安全封闭；不启用旧城都地图编号。用户确认可步行进出吉花市，未报告明显异常。
- [x] 城都骑车：在当前3张活动城都室外地图骑车/跨图；与旧式 RBY/GSC/Random 的自行车音乐选择分开处理，不改变游戏角色骑行状态。
- [x] 城都飞行：预登记11个城都飞行地标，落点依赖已激活地图/有效Header及到访标记；当前只有若叶镇、吉花市可解锁并实际飞入。P4-002 因 Fly 地标局部标签作用域而链接失败、P4-003 修标签；P4-002 登记挂错 Kanto 地图加载入口、P4-004 改到 Johto 加载入口。用户确认修复后飞行正常、普通地图位置正常。
- [x] Bike Song Options 第3页：On 沿用原骑行音乐，Off 上车/下车跳过重播音乐的入口，当前播放 BGM 不重置；原音乐模式、地图切换音乐路径保留。用户实测 P4-006 表示正常。
- [x] 整理城都8份旧分阶段文档至长期 `docs/JOHTO_MIGRATION.md`，不为各开发版重复新建说明文档。
- [ ] **正式提交前**：用户以清理版源码编译正式 Red/Blue、核对新 MAP（含 Bank 空间）；此前项目包内旧 MAP 不是 P4-006 的新链接结果。未在本环境编译/链接或进行所有存读档/关都回归。
- [ ] 后续：30号道路/31号道路/桔梗市分小批新增；正式 NPC、剧情、宝可梦、草地遇敌、昼夜、未激活 Fly 目的地暂缓。
- **交付**：P4-001～P4-006 全部属 HEAD `8c1789757f529de6eeb43de17b9b2d3e3eb8646a` 之后未提交开发。模式B：本版已应用 P4-006→清理版增量、已确认 HEAD→清理版累计全量、`commit-message.txt`，择一使用补丁。版本 `PAL-5.62.224 → PAL-5.62.230`；未改变任何测试功能或测试版本号。

---

# P4-001 / PAL-5.62.225 — 吉花市地图第一轮（开发待验）

- [x] 从最新已提交 HEAD `8c178975` 实际源码开始，按总计划只接吉花市 ID2 与29号道路西口；原 Gold `.blk` 保留，运行图北口对未开放 ID3 设阻挡；地图名字、音乐及标牌登记。未修改 TEST-231。
- [ ] 用户本机红蓝编译、检查 Bank / MAP；验证29号道路↔吉花市、北口不可越界、Town Map 当前地点、原轮船／跳崖／人物无回归。
- [ ] 下轮独立讨论城都骑行、参考分支通用 Fly 到访解锁；吉花市室内、原版 NPC、事件、野怪、昼夜、宝可梦暂不做。

---

# P3-DOC-006 / PAL-5.62.224 / TEST-231 — 若叶镇＋29号道路第一批地图验收收口（2026-10-27）

- [x] **本轮基线**：用户最新确认的正式 Git 提交是 `PAL-5.62.219 / TEST-226`、HEAD `495b7dc86ff6cbed5ed80483d1e8488dcb0e70bf`，其干净源码来自本轮项目 ZIP；P3-001～005（TEST-227～231）是累计未提交开发补丁。本轮仅清理文档，不改变 ASM、资源、图像、游戏内版本或工具脚本。
- [x] **地图可进入**：启用仅两个新的城都稳定 local ID（若叶镇 0，29号道路 1），其余 220 个稳定 ID 暂不可达；关都旧编号及地图规则保留，不使用 `$E7/$F4` 等旧城都地图编号别名。若叶镇↔29号道路双向连接、渡轮进出、跳崖、人物跨图显示由用户逐轮反馈正常；本次未重新在手机复测全部路径。
- [x] **参考分支表现**：渡轮菜单文字恢复 `New Bark`（不是超框的 `New Bark Pass`）；恢复岸边水手和原参考分支船进出场景及相关对白，若叶镇三个贴图测试 NPC 已删除；29号道路现有四名角色是旧参考分支的占位人物/普通文本，非真正 Gold 捕捉教学或剧情移植。
- [x] **Town Map / Fly**：浏览旧分支 45 个城都地标；只有实际已激活的若叶镇是当前合法的城都飞行落点。用户在 TEST-230 报告飞行可用，TEST-231 提供了 Route29 普通地图配色画面并确认没有问题。TEST-231 从旧分支恢复 Johto Town Map RGB 调色板与 64 项图块调色板分配，并迁移加载代码到扩容 ROMX，关都原调色板表保留。**Fly 地图专门的最终版配色、关都飞行回归、旧/新存档及多 ROM 版本不是本次独立重测结论。**
- [ ] **有意推迟**：城都自行车白名单／骑车跨图、其他 220 张地图与全目的地到访解锁 Fly、真实 Gold 人物和捕捉教学、宝可梦／野生遇敌／昼夜／剧情。未激活城镇不能仅因存在地标便允许飞入；未来一次性复用参考分支的通用解锁逻辑，并以实际活动 ID / Header / 安全落点作门禁。
- [ ] **工程验证边界**：不由 AI 编译/链接 ROM；随源码保留的 `patches/rppred.map`、`patches/rppblue.map` 来自旧 TEST-226 导出，**不可**当成 TEST-231 新链接 MAP。请用户在本机使用本清理后的源码重建正式 Red、Blue（以及需要时的测试 ROM），检查新 MAP ROM0、Bank $03/$05/$1C/$35/$38/$41/$42/$43/$45、符号和长度；有条件再确认关都地图、Fly 与存读档。项目原有脚本/工具没有针对本阶段地图连接的独立强制审计入口；本次使用只读结构核验与补丁正反应用验证，不能声称全量地图运行审计通过。
- **清理交付**：模式 B，单笔拟提交；清理增量以已应用 TEST-231（P3-005）为前置，累计全量从 HEAD `495b7dc8` 干净项目 → 本次收口状态。两份补丁互斥，ZIP 内另附一份 `commit-message.txt`。由用户完成 Git Commit／Push，本环境不自行执行。
- **Version**：`PAL-5.62.219 / TEST-226` → `PAL-5.62.224 / TEST-231`（收口无额外升版）。

---

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

## P3-003 / PAL-5.62.222 / TEST-229 — outdoor NPC sprite reload, first pair (awaiting user Red/Blue build and phone check)

- [x] Adapt reference `FLY-5.62.144` shared Johto outdoor sprite set to *tileset* `JOHTO_PILOT` 28 (current new local map IDs 0 / 1 only); add 11-slot set $0b, no old map ID aliases.
- [x] Remove 3 New Bark diagnostic sprite stand-ins; preserve ferry sailor, its dialog, and all P3-002 warp/ledge/navigation behaviour.
- [ ] Gold New Bark teacher/fisher/rival artwork and events, plus Route 29 real Gold sprites, remain unported; Route 29 characters are RPP stand-ins from reference branch, not Gold original art.
- [ ] User must rebuild official Red/Blue and inspect MAP (Bank $05, ROM0). Test New Bark / Route 29 repeated transitions, NPC animation and ferry, save/Continue, Kanto outside; cycling follow-up requires separate Johto bike whitelist activation (not enabled here). No AI compilation or Git commit.

# PAL-5.62.220 / TEST-227 — P3-001 若叶镇＋29 号道路首批运行候选（待编译／手机验收）

- [x] 本轮从用户新上传的 P2 干净提交 HEAD `495b7dc86ff6cbed5ed80483d1e8488dcb0e70bf` 出发；只开放稳定 local ID 0/1，原 222 个城都编号不变，关都地图常量不改。
- [x] 增加首两图 Header/双向连接、渡轮菜单与显式地区 Warp、野怪安全门禁、音乐/Town Map/Name Sign；解决 Johto Tile 28 的 Warp 索引遗漏，并将拥挤 Bank `$03` 的相关处理一同迁移至 `$41`。
- [ ] **未在本环境链接 ROM 或手机实测**。本轮 MAP 与 ROM0/Bank 空间需用户重新构建确认；P2-005D 历史花屏必须以首次若叶镇实机画面确认。
- [ ] 用户最小测试：红蓝分别从枯叶轮船到若叶镇、若叶镇西↔29 号道路东、回船返回关都、旧档/新档存读、Town Map、边缘树林与碰撞。Wild/NPC/其他路口暂未移植。
- 见 `docs/JOHTO_MIGRATION.md`；开发阶段只交付两种互斥补丁，不生成正式提交日志，不自行 Commit/Push。

---

# PAL-5.62.219 / TEST-226 — 城都 P2-001～P2-006 基础底座清理（待用户构建复核，2026-10-27）

- [x] 已提交基线按导出记录为 `ROM-5.62.211 / TEST-218`、HEAD `7c3040b601a221419a50c9bcf572ab2446b6385c`；当前 Worktree 已累计 P2-001～P2-006，尚无新的 Git 提交证据。
- [x] 保留 222 个固定城都 ID、地区/活动槽位安全解析、地区存档兼容、若叶镇与 29 号道路 Gold 源资源及运行资源、Tileset 加载迁移、候选 Header 与 P2-006 调色板两表补齐/长度断言。
- [x] 最新导出附带 `patches/rppred.map`、`patches/rppblue.map`（TEST-226），均可定位城都候选 Header；两图仍未激活，`NUM_JOHTO_ACTIVE_MAPS == 0`。当前 MAP 的 ROM0 余量均为 753B，Bank $43 余量均为 11690B。此处只表示导出中附带的链接产物，不等于本轮重新编译或实机运行。
- [x] 历史用户实测：P2-003 旧/新档保存重读、P2-005B 关都普通房屋/PC/山洞进出与存读档，按当时反馈记录；P2-005D 临时强行激活+B+SELECT 入口造成花屏，已撤销，没有进入本次正式源码。
- [ ] **尚未验收**：P2-006 对花屏的修复效果、首次真实进入城都、四目标独立 ROM/MAP（导出仅有正式红/蓝 MAP）、ROM 文件容量/头字段及 Link/极端跨图边界。不把“MAP 存在”写成这些场景通过。
- [ ] **用户最小验收**：用清理补丁得到当前 226 状态后，在设备上编译正式 Red/Blue 并检查对应新 MAP 的 ROM0 空间、Bank $41/$42/$43、调色板表/候选 Header；有条件再构建 test-red/test-blue。P2-006 的画面行为在将来安全开放若叶镇后验证，此时不要求测试不可进入的城都地图。
- [ ] **下一阶段**：完成统一地图运行链、若叶镇↔29 号道路双向连接/碰撞/边界/事件及真实 Warp，再登记活动槽位；补齐音乐、Town Map、Wild、NPC 与存档跨地区恢复。底座清理可单独准备一次 Git 提交，但**不是宣称地图移植完成**。
- **本次清理**：模式 B，一笔拟提交；清理只改项目文档，ASM/资源/ROM 内版本保持 `PAL-5.62.219 / TEST-226`，不自行编译、Commit 或 Push。旧版本条目保留作为过程历史，其待验记录以本节最新边界为准。

---

# REG-5.62.215 / TEST-222 — P2-004 Gold 若叶镇／29 号道路源资源预接入（开发待验）

- [x] `all_maps(5).zip` 正式红蓝 MAP：ROM0 `$0338` (824B)；Bank `$41` 地区保存、旧档验证与 Header 解析代码已链接；WRAM 基址没有变动。
- [x] 用户已测试旧档、新档保存后重读均正常；P2-003 的此部分验收通过。四目标 MAP 尚未齐备。
- [x] 从用户 Gold 源码中逐字节导入 New Bark 10×9、Route 29 30×9 原始 .blk 和 Johto 2048B metatiles；在 Bank `$42` 定义仅供后续移植的源记录/东西连接稳定 ID (0/1)。
- [x] 参考分支的 .blk 与 Gold 不完全一致，差异位置见 `docs/JOHTO_MIGRATION.md`；后续逐项合并，不直接照抄旧编号 Header/Warp。
- [ ] 用户编译并提供 P2-004 MAP，检查 Bank `$42` 资源、Bank `$41` 活动数 0、ROM0 824B。此轮无可进入的城都地图，暂不要求在游戏里测试城都场景。
- [ ] P2-005：实现真正的地区地图入口、头/块集/碰撞与连接分派，按安全门禁同时激活若叶镇和 29 号道路，再做用户实机验收。
- **版本**：正式 `REG-5.62.215`、测试 `TEST-222`；本轮仅开发补丁，不提交 Git。

---

# REG-5.62.213 / TEST-220 — P2-002 Header/Bank 安全解析（开发待验）

- [x] `all_maps(2).zip` 正式红蓝 MAP：ROM0 824B；Bank `$41` 登记 256B 稳定 ID 表和 P2-001 安全槽位函数，链接通过。
- [x] Bank `$41` 新增城都地区+稳定 ID → 活动槽位 → Header 指针/Bank 解析接口；统一 3B 描述符和表长断言，未知/未激活目标返回 `$FF`、零指针与零 bank。
- [x] **存档冲突已确认**：参考分支的 `$D7A4–$D7AB` 地区身份占位与主项目的地区图鉴状态冲突；本轮禁止复用这些字节，无 WRAM/SRAM 改动，不挂接旧 Kanto 的 Header/Warp/存读档流程。
- [ ] 用户重新编译正式/测试红蓝构建，并发最新 MAP；本轮还未引入任何活动城都地图，无需做城都行走/存档运行测试。
- [ ] P2-003：安全地区身份存档设计和运行时状态载体（不得与图鉴冲突）；P3 起逐图启用新编号地图。
- **版本**：正式 `REG-5.62.213`，测试 `TEST-220`；仅开发补丁，不准备提交日志或清理三件套。

---

# REG-5.62.212 / TEST-219 — P2-001 城都稳定编号（开发待验）

- [x] 从 P1 清理后源码出发，移植并锁定城都 0–221 共 222 个稳定 local ID；保留关都旧 `mapconst` 不变。
- [x] Bank `$41` 增加 256B 稳定 ID→活动槽位表及安全查表入口；活动地图为 **0**，所有 ID fail closed，不创建旧城都 mapconst/别名，不开放新 Warp。
- [x] 无新 WRAM／存档分配，不修改原有关都运行链；源码新增独立文档 `docs/JOHTO_MIGRATION.md`。
- [ ] 四目标 ROM/MAP 和实际运行回归需用户在本地验证；静态检查不能替代链接或游戏内验收。
- [ ] P2-002：地区运行身份及安全 Header/Bank 查表，确认 RAM 生命周期和存档策略；P3 才逐段接地图运行链。
- **当前版本**：正式 `REG-5.62.212`，测试 `TEST-219`；未完成验收前不准备 Git 提交日志。

---

# ROM-5.62.211 / TEST-218 — 城都移植 P1：2MB 与 ROM0 迁表（核心验收收口）

- [x] **ROM 容量**：`main.asm` 增加 Bank `$7F:$7FFF` 锚点，保留原 MBC3、SRAM、Makefile 与地图/战斗运行机制；扩展 Bank `$40` 起预留给后续地区移植。
- [x] **ROM0 地图表搬迁**：将 248 项关都 Header 指针表迁入 Bank `$40`，通过 `E=wCurMap` 跨 Bank 查表、返回 `HL`；不改原地图编号、Header 内容、Warp 或存档结构。
- [x] **正式红蓝 MAP**：`patches/rppred.map`、`patches/rppblue.map` 均显示 ROM0 空闲 `$0338`（824B），相比原 319B 净增 505B；Bank `$40` 表 `$4000–$41EF`，查表例程 `$41F0–$41FB`，Bank `$7F` 容量锚点存在。ROM0 ≥800B 的首阶段目标达成。
- [x] **运行回归已报告范围**：宝可梦中心、山洞、普通房屋进出及存读档未发现问题；这些结果不等于 Fly、地图连接或所有游戏场景已验收。
- [x] **静态回归**：地图表 248 项原数据逐字节不变，调用约定和唯一 INCLUDE 已复核；增量、全量补丁做正反向及文件权限校验。
- [ ] **未覆盖的验收**：Fly、跨地图边界、道馆/港口、独立测试 Red/Blue MAP，四 ROM 的真实文件长度与头部容量码尚无完整核对材料；后续按需补测。`buildRB/pokered.map` 与 `buildRB/pokeblue.map` 不作为 P1 合并后的 MAP 验收依据。
- [ ] **P2 约束**：当前正式红蓝 MAP 显示 WRAM0 剩余 0B、WRAMX #1 剩余 1B；城都新编号/活动槽位需要 RAM 生命周期与空间方案，不能直接追加常驻变量。
- **补丁边界**：清理增量以已应用 `P1-001` 的文件状态为前置；累计全量以 `TEST-217.zip` 干净导出 HEAD `486c89c4a032473306267e95d5865149fc0b12a6` 为起点；两份互斥，只用其一。
- **游戏版本**：正式 `ROM-5.62.211`，测试 `TEST-218`。本次清理不改变 ASM、地图数据或 ROM 内的版本文本，不由 AI 执行 ROM 编译或 Git Commit/Push。

---

# TRF-5.62.210 / TEST-217 — DOC-218 验收清理记录（2026-10-25）

- [x] **正式功能**：成功 Transform 清除**施术者自己的** `wPlayerDisabledMove`／`wPlayerDisabledMoveNumber` 或对应敌方两字段；失败不清。清理是成功瞬间一次性发生，后来真正的 Disable 可重新施加；无需修改原有 Disable、Struggle 或 AI 算法。自动 Imposter 通过相同复制内核，正常换入路径通常已先清除旧状态。
- [x] **TEST-216 录像主路径**：用户 `TEST-216.mp4` 中 16 玩家成功清除旧 Disable 且后续新状态生效，17 敌方成功后续 Tackle，18 同种变身失败仍保留旧禁用。结果按画面可见内容标记为主路径符合，不宣称内部所有临时字段均逐帧观测。
- [x] **TEST-217 夹具**：16/17 的新判定要求 `w*DisabledMove` 与 `w*DisabledMoveNumber` **同时为零**，否则不把旧状态残留当作通过；旧 18 对照仍保留。视频未针对新注入反例做额外运行，不将静态防假阳性检查冒充实机故障注入验证。
- [x] **TEST-217 录像**：用户 `TEST217.mp4` 已观察 19 玩家唯一第一槽招式被禁用后原生使用 Struggle，20 敌方同类情况原生 Struggle，均未卡死；21 敌方 Mew 先 Transform 续用 Tackle，随后玩家**真正使用 Disable**，显示 `Enemy Mew's Disable was disabled!`。该项证实可重新施加 Disable，但**禁用的是 Disable，不是 Tackle**，不能写成 Tackle 被禁用回归已过。
- [x] **验收去重**：此前 TEST-215 的 B 键操作已用户验过，TEST-214 的 01/02/06/10 主路径已有对应录屏；本轮不重复要求 01–18 全量复测，不将 05/09 不成立的前置条件写成通过。
- [ ] **保留而不臆测已过**：正式与测试 Red/Blue 本地编译和 MAP/Bank、联机双端同步、动画开关及极端异常退出；TEST-214 的 05/09 野生敌方 PP=0 非空槽选招不稳定，07/14 同类潜在风险，仍未修。
- [ ] **非正常排列边界**：敌方第一槽为空、唯一非空后槽又被禁用时旧 AI 随机重选可能循环；19/20 测的是正常第一槽单招，不能替代异常排列验证。无自然可达证据，本轮不改引擎。
- **真实提交基线**：用户上传干净 `TEST-215.zip` 的 HEAD `92ac347531c3fe2f72597a60d91d24b7dd2e9aa2`（分支 `常规功能备份`）。已提交的 TRF-209/TEST-215 不再写入这次拟提交日志。正式版本 `TRF-5.62.210`，测试版本 `TEST-217`，DOC-218 仅记录清理、不升 ROM 标签。
- **交付与提交**：本次为清理三件套；将新正式功能和独立测试夹具分为两笔拟提交日志。用户自行在本地验证、Commit/Push；助手没有编译 ROM 或执行提交。

---

# TEST-217 — Disable 双字段检查 + 单招 Struggle 兜底 + 真实 Disable（开发候选）

- [x] 从 `TEST-215.zip` / HEAD `92ac347531c3fe2f72597a60d91d24b7dd2e9aa2` 和用户提供 TEST-216 增量补丁重建基线。
- [x] 16/17 改为 **`w*DisabledMove` 和 `w*DisabledMoveNumber` 都为 0** 才判成功并注入新的槽 1 禁用；部分清除时测试专用分支制造可观察的槽 2 失败，不污染正式 ROM。
- [x] 新增 19 玩家仅一招被禁用 → 原生 Struggle；20 敌方仅一招被禁用 → 原生 Struggle；21 敌方先变身续招，玩家之后真实使用 Disable。
- [ ] 由用户编译检查测试/正式 Red、Blue ROM 和 MAP；仅补测 19–21，不重复录制已验收的 16–18。
- [ ] 原生 Disable 命中率／槽位随机不固定；21 未命中时重试，不把一次未命中判成 BUG。
- [ ] **风险备忘：** 敌方“第一槽为空而其他唯一槽被禁用”的畸形数据可能触发旧 `SelectEnemyMove` 不停随机，属于非正常压紧招式列表的旧引擎边界；本轮不改正式引擎，若未来可达需单独定点审查。
- [ ] TEST-214 的 05/09 敌方 0 PP 招式仍可能被使用，07/14 同类问题仍在，本轮不混入新功能修复。
- **版本：** 正式 `TRF-5.62.210`（指令不变）；测试 `TEST-217`。本轮仅开发补丁，未 Commit/Push。

---

# TRF-5.62.210 / TEST-216 — 成功 Transform 清理旧 Disable（开发候选，待用户验收）

- [x] 成功 Transform 后清除施术者自己的 `w*DisabledMove` 与 `w*DisabledMoveNumber`；目标侧状态不变。失败路径不触碰 Disable；新 Disable 仍按原规则生效。
- [x] 新增双向测试场景 16 `P-DIS-CLEAR`、17 `E-DIS-CLEAR`，以及失败保留对照 18 `P-DIS-FAIL`。夹具直接注入槽位状态，避开 Disable 招式的随机选槽和命中率；仅在 `BATTLE_TEST_BUILD`。
- [ ] 用户运行 TEST-216 的 16、17、18；重点确认玩家复制招式菜单槽位和敌方下一回合实际选招与文档预期一致。
- [ ] 正式/测试 Red/Blue 构建、MAP/Bank、Link 双端仍未由本环境验证；AI 不编译／链接 ROM，不执行 Git Commit/Push。
- **基线：** 用户本轮上传的 `TEST-215.zip` 导出 HEAD `92ac347531c3fe2f72597a60d91d24b7dd2e9aa2`；目标正式版本 `TRF-5.62.210`，测试版本 `TEST-216`。开发阶段只交付增量与 HEAD 全量补丁，两者二选一。

## TRF-5.62.209 / TEST-215 — 手动 Transform 续招验收收口（2026-10-25）

- [x] 调用现有四招战斗选招菜单的专用 type 3，保留上下移动、A 确认、PP/Disable 过滤，只有本菜单的 B 无效；不改变 Mimic、普通战斗菜单及自动 Imposter。
- [x] 更新测试版 `TEST-215` 与专项说明；正式可见版本更新为 `TRF-5.62.209`。
- [x] 用户 TEST-215 定点反馈：成功手动 Transform 后第二次菜单按 B 无效，普通选招菜单 B 仍正常响应。
- [ ] 正式/测试 Red/Blue 构建与新 Bank/MAP、Link 双端、Disable 槽位延续极端路径仍缺专项证据。
- [ ] 独立问题：TEST-214 的 05/09 以及 07/14 零 PP 野生敌方随机选择问题本轮**未修**，不可视为已验收。

## TEST-212 — Transform 双向场景重排（本轮重建候选，待用户验收）

- [x] **按新交接规格重建源码候选**：从用户提供的 TEST-211 实际工作区重新配置十五项：先/后手玩家与敌方、双方失败、Fly/Dig、双向蓄力/KO/EXT、PP/RESTORE、同回合双向换入；测试版标识 `TEST-212`，正式 `TRF-5.62.208` 不变。旧未交付的九文件草稿并非本轮源码来源。
- [x] **测试代码条件隔离**：测试固定敌方续招槽只在 `BATTLE_TEST_BUILD`，第 15 项敌方换人仅在 TrainerAI 行动槽执行并返回 Carry；第 13 项在回合边界准备玩家侧 EXT 身份。未修改 `engine/battle/core.asm` 与正式 Imposter 入口。
- [ ] **本地用户构建/验收**：`red`/`blue`/`test-red`/`test-blue` 四目标、MAP/Bank，十五项场景（尤其后手、半无敌、蓄力、EXT、双换人），异常战斗退出及 Link 两端同步均待验证；不得把静态审查当作通过。
- [ ] **正式收口**：只有用户明确确认功能和测试 ROM 后才准备提交／清理资料；保留准确 `eae3e430690fcc798083887b09d44e891717cead` HEAD 基线。

## TEST-211 — 复用历史测试场景，专项验证手动 Transform（待用户验收）

- [x] **已改测试夹具、未动正式战斗**：把原 IMP 场景 $40..$4E 改成 10 项手动 Transform + 5 项自动变身回归，`IMPOSTER TEST` 改名 `TRANSFORM TEST`，测试版升 `TEST-211`，正式仍 `TRF-5.62.208`。Substitute 3 项、两级菜单／PAGE 默认光标／B 逐级返回与 BG 恢复不变。
- [x] **自动准备动作**：玩家使用非 Ditto 梦幻手动 Transform，敌方可固定只使用 Transform/Fly/Dig；另有四招、Power Whip 身份位、充能招式、1HP KO、原 PP/离场恢复，以及双方同种失败。15、13 等老夹具位置已按本轮目的替换或合并，旧场景不视为永久冻结。
- [ ] **待用户最小验收**：优先 01 玩家同回合、02 敌方同回合、03 半无敌失败、06 EXT、07 两回合招式、08 KO、11 自动 Imposter 不追加攻击；若异常再测相邻边界。Red/Blue 链接/MAP 与联机仍待本地专项验证；AI 不编译 ROM/Commit/Push。
- **精确基线**：已提交 `TEST-209` / HEAD `eae3e430690fcc798083887b09d44e891717cead`，当前上轮功能补丁 `TRF-5.62.208 / TEST-210` 尚未由用户报告 Git 提交。本轮增量以 **已应用 208/210 的源码状态** 为前置，全量从本次用户提供的 **TEST-209 HEAD** 累计 208 功能及 211 场景调整；两份二选一。

## TEST-209 / T15 — 变身者测试 UI 状态恢复（待设备验收）

- [x] **T14 审查 FINDING-01 的源码修复**：`TestSuite_ChooseGroup` 保存原 `H_AUTOBGTRANSFERENABLED`，在统一的“取消/确定叶子场景”退出路径恢复地图、等待一帧完成 BG 传输，再恢复原值；原有 `wd730`、`hFlags_0xFFF6` 和选/取消 Carry 语义继续成对维护。
- [x] **风险调查，无证据不修改核心**：普通 `MoveAnimation` 结束时自行清除 `wMoveAnimScriptLoaded`；每次玩家真实登场都会先清除 `wImposterEntryFlags`，双倒对方就位后才消费挂起标记。没有把静态潜在风险写成实机故障，联机与异常退出仍待专项验证。
- [x] **菜单和场景范围**：TEST `TEST-208 -> TEST-209`；正式仍为 `IMP-5.62.207`。旧 3 + 15 个场景、两类菜单、PAGE 和返回路径全部保留，不修改战斗算法/Party/SRAM/WRAM 布局。细节见 `docs/IMPOSTER_TEST_REVIEW_T15.md`。
- [ ] **最小用户验收**：确认 Pokey 直接进入两分类、子菜单与顶层 B 逐级退出、PAGE 翻页与取消时地图显示正常、确定场景照常开始；若有调试器，再测 BG 原值 0/1 恢复。需要本地 ROM 构建与 MAP 验证，AI 没有执行编译/实机测试/Commit/Push。

## IMP-5.62.206 — 百变怪「变身者」自动入场（功能候选，待手机实测）

- [ ] **首发双向**：野生／训练师百变怪和玩家首发百变怪在双方有效目标上场后自动尝试 Transform；成功后首回合可正常选复制招式，不消耗 Transform PP。
- [ ] **双方换人／昏厥补位**：玩家主动换入仍消耗换人行动，变身本身不增加行动；敌方 AI／训练师换入也触发；双方同时昏厥时玩家百变怪等待新对手登场再尝试一次，普通对手单独换人不让己方百变怪重新变身。
- [ ] **失败与恢复**：沿用手动 Transform 的己方已变身、同物种同形态、目标 Fly/Dig 等检查；失败静默且原 Transform 可继续手动选择；退场重进重新触发。不会为自动版引入后世代 Substitute/Illusion 的额外判定。
- [ ] **实现边界**：`TransformEffect_` 复制内核移动到浮动 ROMX，两个低频战斗例程移出饱和的 Bank `$0F`，同一份复制逻辑保留地区形态／EXT 身份。仅使用原 WRAMX 预留临时字节；不修改 Party/SRAM 或新增整套特性系统。
- [ ] **工程验收**：此阶段只完成静态代码和补丁检查；由用户编译链接 Red/Blue、测试版（如需）、查看新 MAP 并做最小运行验证。联机双机同步／敌我替身特殊效果须单独专项检查。基线为干净 HEAD `54b4eb5f00d83eca8ea518b8d8b2ea93320fbc7b` / `TEXT-5.62.205`；未执行 Git Commit/Push。

## BATTLE-5.62.204 — 可选独立测试 ROM 收口（拟提交）

- [x] **正式／测试构建隔离**：默认 `make red/blue` 不编入测试 Hook/NPC/WRAM 测试别名，`make test-red/test-blue` 使用独立对象和输出；正式战斗算法未新增规则，参考 `docs/BATTLE_TEST_BUILD.md`。
- [x] **地图功能不覆盖**：玉虹大厦原老太太、三位导师保持正式对话，Pokey 仅出现在测试 ROM；其 **`($00,$0A)`** 为用户自行调整的最终位置，不能恢复旧候选坐标。Route 7 和正常存档布局未改。
- [x] **版本与文档**：正式 `BATTLE-5.62.204`、测试 `B-5.62.204-T09`，移除已经失效的逐窗口旧菜单操作说明，保留长期防回归约束。
- [x] **用户旧版反馈**：T07 的原生三选一 A/B 与文本退出已被用户确认正常；此后独立 NPC 与 Pokey 位置由用户在测试工作区运行和调整，不把它写成 204 两种 ROM 已全面验收。
- [ ] **本地最小验收**：由用户在清理源码上完成 Red/Blue 正式构建及至少需要的测试构建，检查链接/MAP；正式版无 Pokey、老太太正常，测试版 Pokey 位置正确、A/B 可退出/启动，测试 ROM 使用独立 SAV。此前已验证的三组战斗不再重跑。
- **Git 基线**：已确认提交 `BATTLE-5.62.203` / `71d78a1a4a80949e4ec903212991a4726ed24f9c`；目标正式版 `BATTLE-5.62.204`，用户自行提交。

## BATTLE-5.62.203 — 已提交的历史战斗修复与验收范围

- [x] **正式源码**：玩家／敌方混乱自伤改为自身真实 HP 扣血，40 威力自身攻防不变；两侧进入 `.realHP` 前重建 `HL=wDamage+1`，避免旧版零伤害/异常秒杀。
- [x] **跳踢反伤**：Jump Kick 与 Hi Jump Kick 落空沿浮动 ROMX Helper 走行动者本人 HP，不再误扣目标替身；恢复远调用后的伤害指针。
- [x] **多段替身文字**：共享 `AttackSubstitute` 只在实际末击或即将破裂时显示承伤；破裂先承伤后提示；玩家与敌方的 Spike Cannon 第二击破裂镜像、Double Kick/Twineedle 双向效果组合已有本轮录像。
- [x] **证据整理**：早期录像交接记录中的两侧有/无替身混乱自伤及先/后手濒死、Tackle 破替身、首击破裂；本轮视频中双向跳踢与多段攻击实际三击。`211T.mp4` 曾出现 15 击，为测试夹具跨 Bank 返回错误，后续录像已观察到 3 击；正式版删除整个夹具。详细受测条件、可达执行路径、限制与静态复核见 `docs/BATTLE_203_FINAL_REVIEW.md`。
- [x] **测试源码清理**：恢复玉虹大厦 NPC/导师/告示牌、Route 7 Normal/Hard 原始野生表、`InitWildBattle` 地区形态清理调用；删除全部夹具 Hook、脚本、临时 WRAM 别名和测试文档；保留正式伤害及多段文字功能，版本号最终为 `BATTLE-5.62.203`。
- [ ] **提交前仅剩工程验证**：用户在清理后的最终源码上编译/链接 Normal 与 Hard、查看新 MAP，简短确认普通 NPC/7 号道路流程恢复。不要重测已有充分证据的对战。没有本轮 AI 编译 ROM 或 Git Commit/Push。
- [ ] **非阻塞、未穷举**：自然混乱解除/有后备换人、全部随机击次与极端高伤边界等未逐项录像，不写成全面通过，也不为此追加本轮测试。
- **准确基线**：已提交 `BATTLE-5.62.202` / HEAD `3595661a0c6857a583e74738293156f12cfac25f` → 已提交 `BATTLE-5.62.203`（其后导出记录 HEAD `71d78a1a…`）；当时中间开发候选不是新的 Git 提交。

## BATTLE-5.62.202 — Dynamic 下限、混乱自伤、伤害除数与 Counter 幽灵免疫（正式清理，待用户提交）

- [x] **Spark 最低能力边界**：烧伤状态下的 Dynamic 分类重算同样遵守能力值最低为 1；用户确认已成功降攻 6 次，最后显示不能再降低，Spark 仍显示 Physical。
- [x] **混乱自伤**：统一使用自方 Attack 对自方 Defense、40 威力、无属性、不能会心；不再依赖当前选择的招式分类。用户视频中 Spark 与 Tackle 两种选择各扣 16 HP。
- [x] **极低防御／特殊除数保护**：公共伤害计算在能力缩放（以及 Explosion 防御折半）后将除数下限保护为 1，避免缩放成 0 时除零卡死。205T 测试反馈物理与特殊两个入口均未见死机。
- [x] **Counter 对幽灵免疫**：Counter 命中幽灵目标时走项目的属性无效提示，不造成 HP 伤害。TEST 04 视频中 Snorlax 使用 Counter 后显示 `It doesn't affect Gastly!`，Gastly HP 保持 999/999。
- [x] **本轮定性回归**：TEST 03 固定伤害与 Counter、TEST 05 Mirror Move 派生 Counter 未报告新异常；不要求重新测试替身、多段、换人、真实未命中，也不要求精确核算敌方 HP。
- [x] **正式测试设施清理**：恢复玉虹大厦 1F 原 NPC 对话／三位招式导师，恢复 Route 7 原始 Normal／Hard 野生遭遇表；移除五个测试入口、测试短标签、Route 7 临时敌人配置、`InitWildBattle` 临时远调用及 WRAM 测试别名，并删除临时测试指南。保留正式战斗功能。
- [ ] **仍由项目所有者完成**：本环境不编译／链接 ROM，不生成新的 MAP，不执行 Git Commit／Push。需在清理后的正式源码本地构建 Normal／Hard 并查看新 MAP；本轮视频已确认 TEST 04 运行表现。
- **拟提交跨度**：已提交 `BATTLE-5.62.201` / HEAD `eba1a803a7791a74bd2706982345d2894e3f93e2` → 正式 `BATTLE-5.62.202`。清理后游戏版本字符串为 `BATTLE-5.62.202`；本环境未执行 Git Commit／Push。

## BATTLE-5.62.201 — 能力等级与 Counter 提示（历史版本记录）

- [x] **能力等级与数值分开限制**：能力阶段在 -6～+6 内正常增减；数值即使已达到 999／1，也不阻止合法的阶段变化；重算后能力值限于 1～999。影响普通技能和 Dynamic 公共战斗属性。
- [x] **Counter 失败文字**：没有有效物理本体受击时显示 `But it failed!`；通过资格检查却未命中时仍显示 `Attack missed!`。保留 -5 优先级、命中／闪避和最后一笔真实 HP 伤害×2 的原规则。
- [x] **用户本轮三项回归**：01 入场防御预置 +6／999，敌人瞪眼降一级、我方变硬成功恢复一级，玩家反馈符合预期；02 对特殊 Ember 使用 Counter 显示正确失败文字；03 Attack=Special=200 时 Spark 判物理且敌方 Counter 成功。01 没有在画面单独显示数值 999，限幅结论依赖源码静态检查。
- [x] **201T 临时设施清除**：恢复玉虹大厦告示牌、Route 7 原野怪、`InitWildBattle` 测试远调用、临时 WRAM 别名和测试文本，删除 201T 专用说明。测试前的 SAV 必须另行恢复，源代码清理不会还原存档。
- [ ] **未额外验证**：Normal／Hard 新 ROM 编译与链接、新 MAP、极端能力值精确数值及更多派生／对战边界。未发现需为本次收口增加常规场景的证据；仅在遇到具体异常时另开测试。
- **拟提交跨度**：用户最新确认已提交 `BATTLE-5.62.200`，导出 HEAD `8030b0f2f162eeb9c2a39e8ca5e7205eacaf8ff9` → 清理后的 `BATTLE-5.62.201`。本环境不编译 ROM、不执行 Commit／Push。

## BATTLE-5.62.200 — Dynamic／Counter／状态重算正式清理（准备用户 Git 提交）

- [x] **规则冻结**：Spark 在 MoveDex 固定 `DYNAMIC`；当前阶段能力修正后 **Attack >= Special 归 Physical（相等也物理）**，Attack < Special 归 Special；烧伤不影响判类，实际物理伤害仍受烧伤。Fight 只预览，出招时重新判定。其他固定类别招式不变。
- [x] **公共 Counter 修复保留**：当前回合双方真实本体 HP 受击记录；只认对方有基础威力、实际 Physical 的直接伤害，反击最近一笔实际扣血×2。多段按最后一次真实命中而非总和；仍有命中／闪避判定；不显示假会心。
- [x] **公共状态修复保留**：攻击／速度确实重算时才对应重新施加烧伤／麻痹折半；非相关能力变化不重复惩罚。
- [x] **临时场景源码剥离**：撤销玉虹大厦、7 号道路、200T 战斗 hook、临时 WRAM 别名和测试信息，保留 `BATTLE-5.62.200` 游戏版本及真正的战斗修复。
- [x] **用户受测范围**：01～08、10～17 主路径的玩家反馈总体符合预期；06／14 原先秒杀及 07～09 FIGHT 死机在修订版反馈中不再报告。多段 Counter 精确 HP 值未得到数值证据；相等归物理的 200T-004 TEST 09 未收到独立重测确认。
- [ ] **第二轮专项**：平局实际执行与 Counter；999 极值；多段 HP 精测；替身／换人／跨回合；敌方对称；Counter 真实未命中；派生招式与扩展身份；烧伤多槽菜单；Normal／Hard ROM 链接和 MAP。详见 `docs/BATTLE_200_FINAL_RULES_AND_ROUND2.md`。第二轮尚未开始，不把测试计划写成已修复。
- [ ] **需要用户先决定的体验规则**：不满足 Counter 条件时是否改为 `But it failed!`、固定伤害是否可反击；200 保留当前行为。
- **提交基线**：用户导出干净 `MOVE-5.62.199` 已提交 HEAD `66c9b058aa4558ec9d0712cd7349ee877f8996f0` → 此次正式清理后的 200；助手未编译 ROM、未 Commit／Push。提交日志跨度为 **199 → 200**。

## MOVE-5.62.199 — Dynamic 类别与 Spark（准备正式提交）

- [x] Spark 固定元数据为 Dynamic；MoveDex 使用原有字模／黑底的四图块标签；选招菜单预测显示完整 Physical 或 Special。
- [x] 用户反馈：199C 标签样式满意，第二槽 Spark 可以选中，未再观察到上下切换花屏；攻击高于 Special 时显示物理，攻击阶段降到低于 Special 后显示特殊。
- [x] 每次实际执行 Spark 时重新比较当前阶段修正后的 Attack／Special；攻击大于或等于 Special 选物理，仅低于 Special 选特殊（平局物理规则于 200T-004 修正）。烧伤不影响分类；烧伤重算攻击按 999 封顶。
- [x] 保留 Spark 65 威力／100 命中／20 PP、麻痹追加效果和原动画；没有加入 Counter 专属缓存、ROM0 桥接、WRAM 状态或 T1/T2 测试数据。
- [ ] 未单独实测：选择后到执行前能力变化、双方特殊边界、烧伤 999 极端值、派生出招／会心及双 ROM 新 MAP；Counter 与 Dynamic 的配合单列以后版本。
- **提交基线**：已提交 198（用户确认）；本环境可重建正式 198 源码，但没有提交后的新 HEAD；本次拟提交范围为 198 → 199，不等于已执行 Git Commit。

## ANIM-5.62.198 — Power Gem 八石头动画（正式验收收口）

- [x] 采用 PC 的八颗岩石出生、上升、悬停与依次斜飞时序；图形全部复用本项目 Rock Throw／Earth Power 16×16 石头，不导入 PC 宝石图。
- [x] 己方使用保持连续向右上飞行（每帧 X+8／Y-4）；敌方使用恢复较高的石头升起位置（X'=180-X／Y'=Y-40），随后连续向左下发射。
- [x] 用户提供 198A／198B／198C 录像并确认 198C 视觉效果满意，可正式定稿；验收范围是录像中的双方向演出，不代表逐像素复刻 PC。
- [ ] Red/Hard 两种 ROM 独立链接、新 MAP、密集 OAM 同扫描线和复杂派生／后续动画状态恢复仍未逐项验证。
- **基线**：分支 `常规功能备份`，干净 197 HEAD `b795cba9fb756fb6449244201a8718192074453f`；正式收口为 198，不代表 AI 已执行 Git Commit／Push。

## ANIM-5.62.197 — EXT02 嬉闹双独立追加效果（正式收口）

- [x] 成功命中后分别以 26/256（约 10.16%）判定目标攻击下降 1 级与混乱，两者互不排斥，可同次触发。使用现有能力／混乱系统，限定活动 EXT02。
- [x] 保留 196 慢速动画及原命中反馈，不使普通 Karate Chop 或其他使用攻击下降效果的招式获得额外混乱。
- [x] 用户实机确认两种追加效果均能单独触发，也能同时触发；自然概率较低，未做正式统计。
- [ ] 双 ROM 独立链接／新 MAP、替身破裂、免疫、能力下限／已混乱、Mirror Move 等边界未逐项专项验证。
- **拟提交基线**：先提交正式 196，再单独提交 197；旧 195 HEAD 为核实来源，不能预设 196 已产生 Git SHA。

## ANIM-5.62.196 — EXT02 嬉闹慢速动画（正式收口）

- [x] 嬉闹主体沿用 Gunk Shot 的 3/4 逻辑帧推进：73 逻辑帧映射至 98 VBlank，粒子轨迹插值，音效仅按逻辑事件播放一次；开场突进与返回不变。
- [x] 保留 194C 星星、爱心、HIT、OAM 次序、横震和 195 原音效，不恢复 194D 额外命中反馈；不修改 Gunk Shot。
- [x] 用户提供 195A／196A 双方向录像用于对照，196A 的慢速动画已进入后续 196B 实机测试；无新的异常反馈。
- [ ] Red/Hard 独立链接、新 MAP、极端 OAM/同扫描线与复杂派生使用仍未逐项核实。
- **拟提交基线**：已导出干净 HEAD `550e6cd5`（195）；196 与后续双追加效果分开提交，AI 未执行 Git 操作。

## ANIM-5.62.195 — EXT02 嬉闹复用 Polished Crystal 对应音效（正式收口）

- [x] **原音效资料复用**：`crysaudio/sfx.asm` 已有 `Sfx_ThrowBall`、`Sfx_BoneClub`、`Sfx_Doubleslap`，此次只新增 `constants/music_constants.asm` 可播放 GSSFX 编号和 `crysaudio/rbsfx.asm` 指针，不重复制作音轨。两表条目必须保持相同顺序。
- [x] **仅作用于嬉闹 EXT02**：共享快速突进的开场音由 Menu 换为 Throw Ball 时检查活动扩展身份；其他使用 Quick Attack 突进的招式保持原音。嬉闹两轮连击在相对帧 `0/9/18/24` 与 `30/39/48/54` 使用 Bone Club、Double Slap、Sludge Bomb、Karate Chop。194 的星星、爱心、HIT、OAM、横震、伤害、PP 以及学招机制不变。
- [x] **用户录屏范围**：已提供《195A嬉闹.mp4》与《PC版嬉闹.mp4》并进行了视频／音轨对照，说明 195A 在受测游戏中能正常播放对应流程；用户此轮要求单独收口。**不宣称** PC 原版立体声声像及逐声道混音已经等价，也不宣称全平台、Red/Hard 双 ROM 或更多派生路径完成专项验收。
- [x] **最终定稿**：开发版本 `ANIM-5.62.195A` 去掉字母，正式版本为 `ANIM-5.62.195`。本次收口只整理版本文本、文档与源码注释，不改变已经录像确认能执行的 195A 音效调用指令。没有新增／遗留临时授招或测试入口。
- [ ] **记录但不阻断本轮**：PC `anim_sound`／`PlayStereoSFX` 含声像控制，而此处仍为 Red++ `PlaySound`；录像中的双声道一致不能单独判定全局引擎没有立体声。开场听感略快不等于 60 帧主连击事件表需要修改；如以后专项调音，另起版本。链接器对新增 9 字节音效指针的实际 Bank 布局与新 MAP 尚未由本环境独立核验。
- **正式 Git 基线**：最新 RPP 导出记录为分支 `常规功能备份`、干净 HEAD `73aad942ddf339a9b7739edd2c15b4bb8110fd13`（`ANIM-5.62.194`）。本轮三件套为 194→195 的拟提交内容；不代表已经 Git Commit 或 Push。

## ANIM-5.62.194 — EXT02 嬉闹专属战斗动画（正式收口）

- [x] **EXT 身份专用动画**：EXT02 Play Rough 根据当次活动扩展序号走 `PlayRoughExtAnim`；普通同低字节 Karate Chop 保持原动画。复用现有 Quick Attack 突进／返回、FrameBlock/OAM、跨 Bank 入口及 Cross Chop 横震机制，不改招式威力、PP 或永久四槽。
- [x] **画面组成**：沿用 Polished Crystal 的星星、爱心、HIT 图块及两轮连击事件表，星星／爱心连续飞散、HIT 按 6 帧生命周期出现；194C 以新生粒子 → HIT → 旧粒子的顺序显示，保留已验收的动画时序与图形。
- [x] **本轮游戏反馈**：用户提供 194、194A、194B、194C 对照录像，并表示 194C 效果已经足够接近参考版本，不要求逐帧一致；撤销 194D 命中后横震更改，以 194C 作为最终版本。受测画面未发现需继续调整的明显问题；不扩大为所有硬件、全部画面限制与所有派生路径均通过。
- [x] **正式测试来源清理**：移除 `data/evos_moves.asm` 小拉达 6 级 EXT02 和 7 级 Pound 两条临时学招；正式版仍不配置普通物种的 EXT 升级来源。保留 194C 的现有动画文件、入口、素材与版本文本；不纳入 194D 的命中反馈修改。
- [ ] **以后按需回归**：双 ROM 独立链接与新 MAP、极端 OAM 同扫描线拥挤、复杂派生嵌套等没有因为本次视觉验收被全面验证；不作为此动画收口阻断项。
- **当前提交基线**：RPP 导出 `常规功能备份` HEAD `103679501f794b420b7b3ad3ccd3ed355ef230db`（`MOVE-5.62.193`），收口目标 `ANIM-5.62.194`；导出资料不含 `.git`，不得误认为已执行手机侧提交或远端推送。

## MOVE-5.62.193 — 普通物种 EXT 等级学习／回忆来源（已提交基线）

- [x] **正式接口**：`data/evos_moves.asm` 原普通物种表内可写 `level_ext_move 等级,EXT_MOVE_*`，宏登记独立 `(species,level,ordinal)`，不改 packed 普通表读取格式；升级走 `TryLearnPartyLevelMove`，回忆师按完整身份加入／过滤 EXT 候选。保留四槽、32 行回忆预算与 Party/PC/SRAM 布局。正式版仍未给任何物种分配 EXT 升级招式。
- [x] **编译报错收口**：用户首轮编译遇到 `Section already defined`；后续修复将多次展开宏和源码读取例程统一为 `SECTION FRAGMENT "Extended Level-Up Lookup", ROMX`，并调整两处潜在跨距跳转。用户其后已在游戏内使用该功能；没有收集独立 Red/Hard 双模式完整链接日志和新 MAP。
- [x] **用户游戏内反馈（最小验收完成）**：EXT01 升级学会、遗忘、回忆、战斗释放均正常；同批测试的普通 Pound 和其他原技能也能学习、正常使用。未反馈异常。对“同低字节”仅认定这批实际学招和释放场景，不扩大解释为所有混排、满槽替换／取消或来源均已测试。
- [x] **测试配置撤销**：用户明确说明已撤销 193T，当前只保留正式功能；源码重建的收口目标未包含小拉达 6 级 EXT01、7 级 Pound 和 `193T` 版本文字。测试存档是否恢复、测试补丁撤销后正式 ROM 是否重新构建未作独立确认。
- [ ] **以后按需做，不阻断提交**：实际给普通物种安排 EXT 学习等级；其他高等级初始招式、地区形态专属等级表、培育屋／敌方来源；满槽取消和全部四槽排列；Red／Hard 独立构建、MAP 链接空间以及更多物种组合。别把功能接口完成误写成所有来源正式投放。
- **提交记录更新**：后续 RPP 项目 ZIP 已记录 `MOVE-5.62.193` 提交 HEAD `103679501f794b420b7b3ad3ccd3ed355ef230db`（分支 `常规功能备份`）；该导出不包含 `.git`，不能据此声称远端已 Push。

## MOVE-5.62.192 — 训练师 AI 扩展候选基础正确性（本轮收口；用户自行提交）

- [x] 正式保留候选四槽 EXT 标记识别，以及 `Moves`／`ExtendedMoves` 六字节数据读取；按真实候选槽评估威力、属性和效果，普通招式专属偏好不误套到 EXT。
- [x] 修复两项静态确认的基础错误：`IsEnemyAIExtendedCandidate` 恢复输入 A 中的招式编号、使用 Carry 传回身份结果；`AIMoveChoiceModification3` 中性倍率判断采用十进制 `10`（`$0a`），不再误写 `$10`。`wTypeEffectiveness`／`wd11e` 只是同址别名，不当作第三个 Bug。
- [x] Hard 模式用户测试：8 号道路 Markus 第一只 EXT02／普通 Karate Chop 对照已测；第二只是三合一磁怪（Magneton），多次选用草系 EXT01 Power Whip，少量回合出现换人；用户后续反馈整体未见明显异常。仅认定**基础读取和受测战斗路径可用**，不宣称 AI 所有评分或策略完全正确。
- [x] **192T 已在本轮拟提交源码状态清理**：移除 `TrainerNativeExtendedMoveSources` 的两条 Markus 测试来源，撤销 Route 8 的临时复战脚本。野生／训练师两张正式扩展来源表均仅有 `$ff`；不将测试档、临时学习来源带入正式版本。使用清理增量后请单独恢复测试前 SAV，并重新生成不含 192T 的 Hard ROM。
- [ ] **专项 AI 后续开发（不在 192 修）**：换人决策、道具使用、预测实际伤害、状态／回复／强化技能的更合理评分、战术和随机选择策略；当前 Hard 训练师偶发换人属于此类，不直接作为 192 缺陷。
- [ ] **尚未逐项实测的基础边界（记录，不作为本轮阻断）**：全部四槽排列、普通招式评分清单、中性／单属性／双属性／克制／抵抗／免疫全组合、状态效果和 AI 修正器 3（Hard 默认不走）、无测试来源时普通训练师行为、红蓝／Hard 各 ROM 链接及新 MAP。用户反馈与静态审查不能替代全部运行覆盖。
- [ ] **扩展招式后续事项**：正式敌方原生 EXT 来源尚未配表；EXT03～40 是容量占位；新增特殊／变化类时要审查物理／特殊／变化分类；模仿／鹦鹉学舌／挥指嵌套与保存、联机、培育屋等生命周期未全测；三重攻击约 20% 异常状态为独立既有 TODO。Lv.1 精神波仅是当前无实际一级遭遇的理论边界，不提升到近期优先级。
- **提交边界**：最近导出已提交基线 `8f9265ccba58f3e307a1246363ab1cf1ee88f6e9`（191）；本轮为 191→192 的拟提交收口，**本环境未执行 Git Commit／Push，也未编译／链接 ROM**。只维护 `docs/MOVE_EXPANSION.md` 和本 TODO 的长期记录，不新增独立计划文档。

# MOVE-5.62.191 — 扩展招式身份撞号的隐藏战斗规则（已提交 HEAD 8f9265cc，以下为历史验收记录）

- [x] **F02 会心身份**：正式代码在 `CriticalHitTest_` 的普通高会心／必会心列表前检查 `wExtendedActiveMoveOrdinal`。EXT02 Play Rough 不再因为低字节 `$02` 而继承 Karate Chop 的高会心；**正式版仍按常规随机会心概率**判定，并非永不暴击。普通 Karate Chop 的高会心规则保留。
- [x] **F05 半无敌相互作用**：`GetSemiInvulnerableMoveInteraction` 在普通招式列表前排除活动 EXT；EXT16 不再继承普通 Gust 的 Fly 特殊命中／倍伤规则。普通 Gust 规则保持原样。
- [x] **191T 四场专项反馈**：用户明确反馈小拉达 EXT02（无强制会心）、喵喵普通 Karate Chop（测试中必定会心）、波波 EXT16（目标在 Fly 空中时不能命中）、六尾普通 Gust（同状态仍能命中）**四项全部通过**。这些确定性会心结果来自独立 191T 临时阈值设置；**不等于正式概率的统计实测**，也不构成普通 Gust 2 倍伤害的数值核验。
- [x] **测试补丁撤销**：用户明确报告已撤销 191T。本次用于生成正式补丁的 191 工作副本与 190 基线相比，没有 7 号道路测试野生分配、敌方来源表测试项或强制会心代码差异。用户本地 SAV 恢复／不带 191T 的新 ROM 构建未收到单独证明，保留为运行前自行确认事项。
- [ ] **未逐项覆盖**：正式随机会心概率统计、Gust 对 Fly 的伤害数值倍率、Dig 对照、玩家侧对等组合、Mimic／Mirror Move／Metronome 多层派生、Red/Hard 双构建／链接与 MAP 空间确认。用户本次反馈不延伸覆盖这些边界。
- **提交状态更新**：后续用户项目导出已记录 191 为 HEAD `8f9265ccba58f3e307a1246363ab1cf1ee88f6e9`。本段其余内容均为 191 当时验收范围的历史记录。
- **后续（192）**：扩展 AI 候选读表和基础评分修复已在上方 192 收口条目更新；主文档为 `docs/MOVE_EXPANSION.md`。

## MOVE-5.62.190 — 追加异常状态跨 Bank 传参修复（专项录像通过；用户已确认 Git 提交）

- [x] **正式修复**：`RollStatusSideEffect` 在 `callab` 前执行 `ld e,a` 保存效果编号，`RollStatusSideEffectFar` 入口执行 `ld a,e` 恢复；保留 Carry、E 的归一化结果与既有概率算法。不改招式表、EXT 身份、189 来源表、Party/PC/SRAM、旧调试入口和游戏版本之外的数据。
- [x] **190T 三拳专项验收**：用户上传《190三拳.mp4》，在独立强制追加效果测试条件下，普通 Fire Punch 产生 BRN（约 9 秒）、Ice Punch 产生 FRZ（约 19 秒）、ThunderPunch 产生 PAR（约 30 秒），三项受测表现均正确。此测试只证明效果类别，不证明正式概率的统计分布、所有免疫／替身等边界。
- [x] **临时补丁清理**：用户明确反馈已反向撤销 190T；其后上传的项目 ZIP 未发现 190T 工作区差异，只有 190 正式代码／版本／待验文档四处未提交修改。测试前 SAV 是否恢复、正式无 190T ROM 是否重新构建，尚未收到独立确认。
- [ ] **未验收范围**：全部追加效果、玩家与敌方所有组合、正式随机概率统计、替身／免疫边界，以及 Red／Hard 双模式的分别构建与链接，均不因三拳录像而算通过。191 EXT02 会心低字节撞号、EXT16/Fly、训练师 AI 错表等继续独立处理；Lv.1 Psywave 仅作当前游戏不可达条件下的理论边界记录。
- **Git 状态更新**：历史 ZIP 导出 HEAD 为 `60e8832b8b08283bf135518ef79af7f847098f30`（189 已提交），当时 190 仍在 Worktree；**用户后来明确告知 190 已本地 Git 提交**，但尚无新的提交 SHA／Push 记录可核实，不以旧导出 HEAD 冒充最新 HEAD。

## MOVE-5.62.189 — 敌方 EXT 身份／MoveDex 正式验收（已本地 Git 提交）

- [x] **188 MoveDex 敌方 Seen 身份保护**：根据当前 `wExtendedActiveMoveOrdinal` 区分 EXT01～40 与普通同低字节招式，不错误点亮普通招式 Seen；不在既有 254 位 MoveDex 内登记 EXT 身份。用户《188T-004 Dex.mp4》验证：敌方 EXT07 后普通 Fire Punch 为 `NOT SEEN`，敌方普通 Fire Punch 后为 `SEEN`，两种招式均实际执行。只针对录像中的两组对照验收。
- [x] **189 野生／训练家原生技能来源**：在 `LoadEnemyMonData` 技能生成后，按野生物种＋形态或训练家类别＋编号＋零起始队伍位置匹配完整四槽记录；同时写入敌方技能字节与高四位 EXT 标记，并从第二表修正被标记槽位的 PP。普通同号槽保留普通身份；未列来源保持原招，Transform／链接旧路径不变。189F-003 已保护 PP 远调用中被覆盖的 BC。
- [x] **189T 受测主路径**：用户《189测试.mp4》展示野生小拉达原生使用 EXT07、训练家 Markus 的首发原生使用 EXT07；用户随后反馈训练家 EXT07 的动画与实际伤害正常。录像另见训练家普通 Fire Punch 使目标出现 PAR，这与独立审查确定的共用异常状态跨 Bank 传参缺陷 F01 一致，**不是本版已修复项目**，不得将普通 Fire Punch 异常状态当作通过。
- [x] **正式测试代码清理**：撤销 7 号道路全小拉达野生表、Rattata／Super Nerd 强制技能分配、8 号道路 Markus 复战脚本与额外 INCLUDE；正式两张来源表仅保留 `$ff` 结束符，**框架完成不等于已安排正式敌方 EXT 学招来源**。当前清理补丁不包含 189D 诊断和独立火焰拳传参修复；游戏版本保留 `MOVE-5.62.189`。测试 SAV 如已改变，需由用户恢复备份。
- [ ] **下一轮独立修复**：F01 火焰拳／冰冻拳／雷电拳等共用追加异常状态 `RollStatusSideEffect` 跨 Bank 传参；F02 EXT02／Karate Chop 高会心低字节碰撞；F03 敌方 AI 读取 EXT 槽位时仍用普通 `Moves` 表；F05 EXT16／Gust 对 Fly 的特殊交互碰撞。F04 Lv.1 Psywave 随机死循环属于基础招式独立问题。上述静态缺陷已记入审查，不随 188～189 验收偷渡修改。
- [ ] **仍未专项验收**：正式来源内容设计、完整的换人再次装载、不同 ROM 模式及新 MAP、完整保存／捕获后 Party/PC 身份、Daycare、联机与 AI EXT 评分、嵌套派生／其余 EXT 数据效果。静态补丁校验不是 ROM 编译或全链路验收。
- **Git 状态补记（2026-10-18）**：用户最新项目导出显示 189 已本地提交，HEAD `9cfd1f689ef9c886d2d65f3be46986e70551d3a5`，工作区干净，尚未 Push；上一提交 HEAD 为 `ea163ba9a4ec8b96d20e761c833aef3f5c9e6713`。本条只更新提交状态，不改变 188～189 的验收范围。

## MOVE-5.62.187 — 185～187 双向派生／复制招式完整身份（已在 HEAD ea163ba9 提交；历史记录）

- [x] **185 Mimic**：玩家与敌方从目标真实四槽复制技能低字节与 EXT 身份，只更改使用者的临时战斗槽／身份位；用户《185MIMIC.mp4》确认双方 Mimic 复制 EXT07 后实际使用。《交换Mimic.mp4》追加确认 Mimic 后以 SELECT 调换普通 Fire Punch 与 EXT07，仍能正确出招，战后原 Party 技能恢复；仅限录像覆盖的顺序。
- [x] **186 Mirror Move**：双方根招记录单字节技能及临时 EXT 身份，复制上次根招时按照记录加载子招；用户《186Mirror.mp4》与《MIMIC1.mp4》分别确认玩家、敌方复制并实际执行 EXT07。旧 186T 花屏来自测试脚本在固定地图块中插入独立 SECTION；测试修复后地图恢复正常，正式代码无测试脚本。
- [x] **187 Metronome**：双方从普通 1～250 中除去 Metronome/Struggle 的 248 个身份与 EXT01～40 的 40 个身份中抽取完整身份；普通／扩展数据与名称按对应表加载，临时 ordinal 不回写技能槽。用户《187摇手指.mp4》确认固定 EXT07 的 187T 条件下，玩家和敌方挥指均实际执行并造成伤害。此录像**不**验证正式版真实随机概率或其余 39 项效果。
- [x] **提交边界**：本次上传 `MOVE-5.62.187.patch` 从用户原始 ZIP 的实际 `184G3` 源码可完整回放，10 个工作区差异文件与已交付正式 187 一致；不含 185T／186T／187T 的 NPC、地图、野生百变怪、测试帮助例程。正式清理只更新项目文档与本组新代码段的最终 187 注释，不更改 ASM 指令、游戏版本或 Party/PC/SRAM 布局。用户自行 Git Commit/Push。
- [ ] **仍未覆盖**：Mimic/Mirror Move/Metronome 多层间接调用与递归、Mirror Move 对方换人旧记忆、同低字节普通／EXT 所有排列、正式挥指随机分布、所有 EXT 效果、PP/MoveDex 极端路径、保存重开／联机 PRNG、红蓝独立链接与新 MAP。下一轮另开版本逐项处理，不为收口改已实测主路径。

## MOVE-5.62.184G3 — 变身状态 SELECT 换位保护（待用户本地提交）

- 正式保留 113 的最小 `Transformed` 判断：`SwapMovesInMenu` 发现已变身即清空待交换标记并返回技能菜单。未变身仍使用既有 SELECT 流程；未加入 112 的物种、四招、PP、身份位多重比较。
- 用户《184G变身.mp4》实测未变身时技能可交换；变身后按 SELECT 不再交换，可正常选招。菜单会短暂闪烁、光标回第一格：当前确有此表现，但未证明是原版行为；不作为本轮阻断问题。
- 清理正式源码中的 111/184GT 测试 NPC、独立助手与 Route 7 临时百变怪。测试源码撤销和测试存档恢复必须分别完成。原先技能变为横杠的异常存档不能通过 ROM 补丁恢复。
- 当前仅能据受测录像认定 SELECT 保护主路径有效；184G3 **清理后 ROM** 尚未在红、蓝逐版独立编译与实机复测，未覆盖所有强制行动、失败变身、联机/PC/SRAM 边界。

## MOVE-5.62.184 — Transform 双向完整身份复制（受测主路径通过）

- 变身成功复制目标四个技能字节后，同步复制被复制方的四槽扩展身份 mask；玩家低四位、敌方高四位，只更新变身者半字节，不更改目标或永久 Party 数据、原 PP=5 规则与失败条件。
- 用户《184变身.mp4》展示敌方百变怪变身后正确使用 EXT 07，玩家可达鸭反向变身后菜单出现跃起＋三格 EXT 07 且实际用出 EXT 07；录像展示战斗后原队伍技能仍在。此证据仅支持录像覆盖的双向主路径，非全部变身边界。
- SELECT 禁换位单独收口在 184G3；184T/109 与 184GT/111 的临时测试来源不得进入正式提交。
- Mimic 敌方完整复制、Mirror Move 与 Metronome 身份传播、其余强制行动、红蓝逐版构建和保存边界仍需独立工作。

## MOVE-5.62.183 — 敌我扩展招伤害分类公共基础（用户报告编译通过）

- `PhysicalSpecialSplit` 经公共 banked 分类器检查当前行动方、技能字节和有效 ordinal，按完整扩展身份读取 40 项分类表；普通招与 `$ff` 路径保留，非当前招查询不直接借用 sidecar。
- 为保持 183 以前的原型行为，当前 40 项仍为物理占位；后续新增特殊/变化招必须同步维护分类表及战斗数据表，不能直接按重用低字节推断分类。
- 用户报告 183 功能补丁可以正常应用和编译。**没有独立的红蓝 ROM 分别构建凭证**，也没有对全部伤害公式、Counter/Sucker Punch 和未来特殊/变化扩展招做动态专项验收。
- 不变更 Party/PC/SRAM；不把双向 Transform、敌方技能正式获取和其他派生招式错误记为 183 已完成。

## MOVE-5.62.182B — 公共执行层 + 098 槽位修正（已完成定向动态测试，其他路径待验）

- 已实现 182A：`wExtendedBattleMoveFlags` 低 4 位为玩家、 高 4 位为敌方，提供双方 4-bit mask 读写；换人、玩家变身、战斗中学习更新玩家半字节；新敌方上场清高半字节。不新增 WRAM／SRAM。
- 已实现 182B：按当前行动方、真实槽位、技能低字节与侧边身份位重新解析 `wExtendedActiveMoveOrdinal`，再覆盖对应扩展技能的六字节记录及名称；普通派生子招重载清除残留 ordinal。
- 098 修正两个已证实的调用问题：战斗菜单预览临时使用光标槽；不听指挥随机出招临时使用实际随机槽加载数据，恢复原正式选招／PP 索引。
- 用户《182BT测试补丁.mp4》在 100 临时补丁下，对普通火焰拳／扩展 07 同低字节的两种排列各测两次：强制换招正确；菜单名称未见串槽；视频有一例原选槽 PP 15→14。仅此范围动态通过。
- 181 Mimic 玩家侧可复制普通火焰拳、正确替换模仿本槽、保留其他扩展身份；**敌方 Mimic、双方完整 Transform、Mirror Move 扩展身份传播尚未实现**，不宣称双向完成。
- 100 临时授招及强制不服从测试脚本**不得进入正式 Commit**；测试源码恢复和测试存档恢复是两回事。
- 尚未完成红／蓝独立编译、链接与新 MAP 证明；未覆盖正常服从机制完整流程、更多 PP 边界、所有强制／持续出招、敌方扩展来源与伤害物理／特殊分类。F-03 仍是启用敌方扩展招前的阻断项，放在后续独立版本处理。

# MOVE-5.62.180 正式收口：玩家变身后的战斗扩展身份同步（受测核心场景通过）

- [x] **保留代码**：玩家 Transform 成功复制敌方普通技能字节后，清零 `wExtendedBattleMoveFlags` 和 `wExtendedActiveMoveOrdinal`；不修改 `wExtendedPartyMoveFlags`、原 Party 技能或保存布局。变身期间当前成员发生学招时，`SetPartyExtendedMoveSlot` 不把 Party 标志重新灌入临时战斗四槽；失败路径不执行新增清零。
- [x] **视频可确认**：用户《180变身.mp4》（28 秒）显示喷火龙原持普通 Transform＋扩展 07，成功变身为野生猴怪后，技能菜单显示 Mega Punch／Cross Chop／Storm Throw／Feint Attack 四个普通技能，并实际使用复制后的 Mega Punch，未出现扩展 07 的错误显示。用户反馈本轮已测试，并确认已撤销 180T 临时授招补丁。
- [x] **测试与提交隔离**：用户确认 079（上一版残留 179T 清理）已经合入上一个 Git 提交；本次 180 单独提交不得再次带入 079，也不得包含 082/180T 地图授招脚本或测试存档内容。现有用户 179 ZIP 仍是 079 合入前的旧导出，尚未收到含 079 的实际新 HEAD 哈希；不虚构 Git 基线。
- [ ] **未由视频覆盖**：战斗结束／换人后的原 Party 扩展身份恢复、变身失败路径、变身中战斗经验升级学招、敌方变身复制玩家扩展招、红蓝双版链接与新 MAP。已有代码按这些生命周期设计，但不能写成游戏内 PASS。模仿、挥指、PC、SRAM 仍分开做。
- [ ] **Git 状态**：本项已准备 180 独立收口材料；用户本地完成 Commit／Push 后再凭真实导出记录更新 HEAD，不将临时测试或准备补丁视为提交。

# MOVE-5.62.179 正式收口：TM/HM／教学师按完整身份判重（准备单独提交）

- [x] **179 代码定稿**：`engine/items/tmhm.asm` 的共用 `CheckIfMoveIsKnown` 按 Party 四槽 sidecar 逐位判定；低字节相同但扩展位为 1 时继续向后搜索，仅普通身份真正匹配才提示已学。TM/HM 和教学师复用这一入口。保留 178 共享升级学招、177 地区回忆判重，以及既有存档、兼容性与计费流程。
- [x] **用户核心实测**：`179教学.mp4` 中，扩展 ordinal 14 不阻止 TM03 普通剑舞，成功学习后再次使用 TM03 被正确拦截；扩展 ordinal 7 不阻止火焰拳教学师。用户随后提供小拳石技能详情截图，确认同一只宝可梦可同时持有扩展 ordinal 7 与普通火焰拳，并反馈复测正常。以上是受测场景通过，不等于完整技能排列或所有教学条件通过。
- [x] **临时测试入口已撤销（用户反馈）**：179T 仅作测试工具，正式提交不得包含 `scripts/CeladonMansion1.asm` 的临时老太太／告示牌授招脚本，不保留额外 TM03、改招或测试地图修改。截图中测试存档经验值的人工改动不属于此次源码问题。
- [ ] **仍待单独验证，不阻断本次限定收口**：HM 实机对照、红／蓝分别构建与新 MAP、四槽全部顺序／取消边界、教学师完整扣费和可学性，以及 PC 全 12 盒、Transform／Mimic／Metronome 等外围身份传播。Bank `$0B` 的旧 178 MAP 记为 0 slack，但存在可移动 ROMX SECTION，不能用此单值推断 179 链接成败。
- [ ] **Git 状态**：已知干净 178 HEAD 为 `f54c194013b1ebb3ed73c3951bb656171f22b5b1`。本次仅准备 178→179 独立提交材料，不将生成补丁视为真实 Git Commit／Push。变身、模仿、挥指及其他后续内容按单独版本／单独提交处理。

# MOVE-5.62.178 正式收口：普通／地区形态共享升级授招（拟提交）

- [x] **共享升级学习入口**：普通压缩学习表和地区形态学习表保留各自解析逻辑，均通过 `TryLearnPartyLevelMove` 完成完整技能身份判重、名称准备及 `LearnMove`；扩展招式名称复制前重置来源指针，跨 Bank 保留有效寄存器状态。177 地区回忆判重与 176 已验收修复保留；未修改四槽、存档／PC 格式与 40 招容量。
- [x] **双形态对照与回忆试验（清理前用户实测）**：普通小拉达／阿罗拉小拉达在 178T2 获得相同的临时 6 级 Power Whip、7 级普通 Pound 来源，用户反馈升级、遗忘正常；178T3 回忆视频触发名称乱码，随后 073 保护回忆师临时远调用的 BC，用户确认 178T3F 的回忆、详情、战斗及 Party↔PC 存取读回正常。用户还已反馈战斗升级、学招完整名称正常。以上不等于所有物种／全部盒子或红蓝逐版验收。
- [x] **正式测试来源全部撤销**：移除 1 号道路的临时全小拉达遭遇、6／7 级普通和地区测试分配、回忆师临时候选及 073 对其添加的 BC 包装；仅保留经过测试的正式共享授招和 177 地区回忆身份判重。`MOVE-5.62.178` 游戏版本号不带 T，Power Whip／Play Rough 静态原型保留，正式学习来源仍未分配。
- [ ] **最终清理后最小回归（用户本地 ROM）**：正常普通宝可梦神奇糖果／战斗升级学原技能、地区形态升级及回忆旧技能、已学普通招过滤、普通+扩展混合技能可正确读取并进出 PC；1 号道路不再全是小拉达，6／7 级不再自动发放测试招。当前暂未拿到清理后的红／蓝 ROM 链接结果和新版 MAP。
- [ ] **后续独立专项**：特殊／变化扩展招式的物理／特殊分类、Day Care、Link、Transform／Mimic／Metronome、MoveDex、新旧 `$FF` 档迁移、全 12 盒和回忆师满 32 条上限。非本轮阻断项，不为清理修改这些代码。
- [ ] **提交状态**：基线是用户导出的已提交 `MOVE-5.62.176` HEAD `23858fc8b513d2d0800c193b6e58249bf5f9c45a`。178 正式补丁及日志供用户自行 Git Commit/Push；提交前不得宣称已经出现 178 HEAD。

# 当前扩容专项（MOVE-5.62.176；旧功能回归通过受测场景，准备正式提交）

- [x] **176 SELECT 换位 P0 的针对性复测通过（清理前测试 ROM）**：用户《176测试.mp4》展示小磁怪 31/32、可达鸭 21/22、口呆花 Power Whip/Play Rough、玛瑙水母 39/40 与普通招混合换位，战斗返回 Party 详情显示的名称、技能顺序、PP 未见 175 的 Play Rough→Karate Chop 错位。保留 175 的菜单 1-based 索引修复及 176 的 `D=0` WRAM 地址修复。不据此声称全部四槽组合、40 招、盒子和保存边界均覆盖。
- [x] **174 普通升级学习的用户回归证据**：用户确认糖果升级、技能槽已满替换新普通技能正常；《176测试.mp4》另可见部分普通招学习／替换／拒绝场景。战斗经验升级与所有等级表未逐项单独验证。历史 171 曾误删普通 `GetMoveName → LearnMove` 代码；174 已恢复，后续必须以旧功能回归为阻断项，不再允许因清测试数据而误删。
- [x] **175 Struggle 与 TM、存档/PC 的受测主路径**：用户《175挣扎1.mp4》看到 Struggle 和反伤；用户报告 TM 学习、队伍／PC 存取、保存重启的受测技能身份正常。175 战斗中强制挣扎时清理扩展 ordinal、当前技能字节不匹配时恢复普通读表的修复保留；尚无完整所有盒子及特殊派生技验证。
- [x] **176 清理后最小回归（用户反馈）**：用户已在撤销临时获取入口后的 176 游戏中复测，反馈普通技能升级学习正常，战斗中技能交换也抽查未见异常。此反馈与先前《176测试.mp4》混合身份换位、用户糖果升级／满槽替换、Struggle 及 TM／PC 部分场景的结果合并记录，但不声称红蓝分别完成构建、战斗经验升级、全部 19／20 级物种或四槽六对位置均逐项验收。源码已移除 053 的 20 家族学习和回忆测试分配，保留 40 项数据／身份与 174～176 三轮正式修复。
- [x] **176 正式清理与交接准备**：用户上传 `MOVE-5.62.176.patch`，标记 RPP-BASE `60b3970b`；与上一轮 058 的七文件最终代码和文档差异逐项吻合。最终清理仅同步验收文字、统一本轮修改代码段的 176 注释，不改变 ROM 指令、40 招表、学习表或存档。正式增量 059 针对已应用 057／058 或用户上传的 176 工作区，全量 060 针对 173 干净 HEAD；两者不叠加。准备由用户自行 Git Commit，尚无新的 176 HEAD；交接文件放仓库外。
- [ ] **后续仍需按需补验**：战斗经验升级、红蓝双版链接与新 MAP、19／20 级所有旧测试家族无额外发放、全部六种技能换位与保存重启组合、PC 12 盒及 Transform／Mimic／Metronome 等特殊技能行为，均不能由本次抽查直接推定通过。

## 173 已提交功能基线（保留）

- [x] **40 个独立扩展技能身份已接入**：`$0100～$0127`，保持原 `$01～$FE` 254 招及四个一字节技能槽不变；Power Whip、Play Rough 保留原型，03～40 仍是可供未来替换的数据／名称／PP 占位，不是已完成的真实新招式设计。
- [x] **173 用户主路径验收（清理前测试 ROM）**：视频《173扩充到40技能.mp4》可见喇叭芽、可达鸭、小磁怪、玛瑙水母的扩展升级学习、技能显示、遗忘及回忆过程，包含末项 `Ext Move 40`；用户另行报告普通与扩展技能对战成功、已持有的扩展技能在回忆列表中被过滤。仅记录已测试场景，不推导 40 招全部逐项或保存／PC 全盒通过。
- [x] **正式清理取消所有 01～40 临时升级发放**：删除 173 的 20 个家族 × 19／20 级测试分配表及对应学习、回忆候选代码；不恢复 172 的口呆花集中测试。40 项身份、名称／战斗数据、四槽 sidecar、战斗／菜单通用读取继续保留。清理后的正式 ROM **不会**再由升级／回忆师自动发放任何尚未分配正式学习来源的扩展招式；旧测试档中已持有者仍可能存在，建议留备份。
- [x] **编译期容量保护已做负向测试**：208 份普通、42 份地区学习表的 RGBDS `ASSERT` 保护仍在；九尾与洗翠风速狗临时加至第 33 条时用户编译得到预期三处断言错误。19 条负向测试临时记录不属于最终源码，普通／地区每表继续保守预留至多 2 条未来扩展候选，总预算 32。
- [~] **清理后尚需最小回归**：红／蓝两版由用户编译／链接、确认新游戏 19／20 级无测试招、普通升级／回忆正常；旧测试档已持有扩展招的详情与战斗行为可选验证。原 173 录像不等于清理后的 ROM 已运行验收；AI 未编译／链接，最新空间布局和 MAP 仍须用户侧确认。
- [ ] **下一阶段独立设计真实学习分配**：按目标物种与等级增加真实招式来源，并让普通＋地区／扩展候选按物种进行编译期合计检查；若单只超过两条扩展候选，应先修订保留预算。培育屋、联机、变身／派生招式、MoveDex、旧存档迁移仍另案，不在本次收口内。

---

## ANIM-5.62.146 — Volt Tackle 双向横震定版（用户确认满意；提交收口）

- [x] **Fly 游戏侧 PASS／模拟器专项另查**：同一 143 ROM 在 My OldBoy 与另一款 GB/GBA 模拟器未听到起飞、落地尾部 click，GBPocket 的现场与录屏均有 click。已撤销 144/145 两次游戏音频试验的运行时代码；Game Fly 恢复 143 实现。模拟器根因尚未锁定，保留研究于 `docs/FLY_CLICK_PLATFORM_DIAGNOSIS.md`，不将有限平台测试外推为所有硬件均正常。
- [x] **Volt Tackle 敌方命中横震定版**：146 在 `engine/battle/volt_tackle_animation.asm` 去掉两处 `H_WHOSETURN` 限制，敌我双方共用命中阶段前 18 帧 WX=5/9（±2px）高频横震，后 6 帧回到 WX=7 并关闭 latch。用户提供《145伏特攻击.mp4》和《146伏特攻击高频短横震.mp4》比较敌方施放效果，明确表示“这版满意了”，决定保留 146；玩家侧原动画及普通受击反馈未修改。见 `docs/VOLT_TACKLE_146_ACCEPTANCE.md`。
- [ ] **尚未逐项覆盖的边界**：敌方连续施放两次、全部对战显示模式／ROM 变体、异常中断时的画面复位，以及更多技能的敌我视角反馈审计。本轮用户已批准当前观感，不把这些补充回归写成必须完成才能定版的阻断项。未由 AI 编译 ROM，无 MAP 链接空间结果。
- [-] **后续可选优化留到新版本**：146 的 WX 影响整幅战斗画面（含 HUD），不等同于《绿宝石》针对 `ANIM_TARGET` 宝可梦的局部晃动。若将来尝试目标局部横震，必须在 146 已验收基础上开新编号，提供独立可撤销补丁；不倒改此版。

## SFX-5.62.143 — 训练师战斗倒下声衔接（用户提供录像，基础场景验收收口）

- [x] **清理 FAINT_FALL → FAINT_THUD 之间的旧声道等待**：`engine/battle/core.asm` 不再读取旧 `wChannelSoundIDs + Ch4` 标志；浮动 ROMX `WaitForTrainerFaintFallSFX` 仅在 Crysaudio CH5 实际播放 `SFX_FAINT_FALL` 时逐帧等待，最长 180 帧。原 `PlaySoundWaitForCurrent`、`SFX_FAINT_THUD` 和后续 `WaitForSoundToFinish` 不变；不改玩家倒下叫声、胜负／换人流程及全局音频引擎。这属于兼容等待清理，不宣称已复现并修好某个可辨认的旧版听觉缺陷。
- [x] **有限范围视频验收**：用户上传《143音效.mp4》，表示已尽量覆盖建议场景，但下降声／落地声差异不易听辨。录像可观察敌方连续击倒、己方被击倒、红血状态击倒敌方、训练师战胜后续，以及伏特攻击导致双方同时倒下；未发现显著的倒下流程异常或音效提前抢断，不能仅凭此证明 142→143 在听感上有明显改善。
- [x] **双方同时倒下现有行为维持原样**：反伤导致先处理敌方倒下时，己方可能直接退场并跳过己方叫声和倒下文字；该旧分支不属于本次音效等待清理。用户明确仅询问原因，**不要求修复**，不要纳入下一轮修改。
- [ ] **未逐项验证边界**：Link Battle、Music Off／BGM Volume 0、特殊连续倒下组合、180 帧上限及不同 ROM／模拟器；当前项目没有 MAP，本环境不编译 ROM。清理后版本仍为 `SFX-5.62.143`，后续新功能须另起版本。

## 后续音频待办（143 提交准备后，下一轮另立新版本）

- [ ] **先复现再修改**：宝可梦中心治疗完成提示音、地图 SFX 切战斗 BGM、飞行／传送音效过渡。部分跨 BGM 音效属于原设计，禁止因为猜测而全局静音。
- [ ] **独立功能需求**：低 HP Danger 警报三响后渐弱到一半音量（原 TODO 仍保留）。它与 141 命中声衔接、142／143 旧等待清理分开评估。
- 本阶段交接与验收边界见 `docs/AUDIO_HANDOFF_143.md`。正式提交须覆盖已记录的 141 HEAD `7a89953c` → 143（包括 142 的工作区改动），不能只提交清理文档。

## SFX-5.62.142 — 电梯旧音效等待清理（用户测试：原无明确异常）

- [x] **维护性清理，而非已复现缺陷修复**：保留 `engine/overworld/elevator.asm` 的旧 `wChannelSoundIDs + Ch4` 等待替换，使用浮动 ROMX 轮询 `SFX_SAFARI_ZONE_PA` 所对应的 CH5 活动位、最多 180 帧。原有 40 次震动、结束提示音和 `PlayDefaultMusic` 不改；后者自己的等待不在 180 帧上限之内。
- [x] **用户的有限范围对照反馈**：用户上传 141／142 的电梯录像并表示已测试，认为新版影响不大、旧版本本身没有可辨认的问题；因此 142 只归类为残留代码清理，不宣称修好了实际报告的听觉缺陷。彩虹百货／火箭队基地／希尔夫三处逐项回归、游轮／渡船、Music Off、BGM Volume 0 尚无分别确认。

## SFX-5.62.140 — 开场按 A／START 跳过残留音效（用户反馈通过）

- [x] **流星与对战跳过音效收尾**：对照用户的原版／RPP 开场录屏与源码，发现 RPP `PlayMusic` 只切换 BGM，不像原版 `PlaySound` 在启动下段音乐前清理 CH5～CH8。因此仅在 GAME FREAK 流星与耿鬼／尼多力诺动画提前被打断时调用浮动 ROMX 的 `StopInterruptedIntroSFX`，停止仍活动的效果通道并立即关闭对应 APU DAC，避免尾音进入下一段；正常演出完成不额外截断音效。
- [x] **不改变已提交 139**：Mateo 每次显示、完整标题宝可梦叫声、标题轮播、菜单白屏优化及 Continue B 返回无闪均保持。未改 Crysaudio 全局 `PlayMusic`／`PlaySFX`、BGM 音量或存档格式。中断检查保留正常 carry 分支与原 40 帧等待。
- [x] **140 核心验收反馈**：用户在比较原版与 RPP 后确认流星按 A 提前跳过的残留音效问题已解决，并在进入下一轮时明确反馈 140“没问题”。未分别提供 A／START、两段自然播放、静音与 BGM 音量 0 等完整测试结果，不扩大验收范围；AI 未编译 ROM，未确认链接空间。

# Todo List

This file is the working roadmap for the current RPP branch.
Implementation details, ABI/bank constraints, test history, and handoff notes belong in the current handoff document; this file tracks what is finished, what is next, and what remains from the original upstream wishlist.
Reusable development failures and prevention rules are kept in `RPP_DEVELOPMENT_PITFALLS.md`; read it before changing related engine paths.
补丁交付长期规则见根目录 `PROJECT_DELIVERY_RULES.md`：**开发待验时先交补丁三件套、不擅自提前写日志；用户要求验收清理三件套时必须附可复制的 Git 提交日志（合集 ZIP 内也应带日志）**；未经用户确认 Git 提交，不更新已提交基线。

Status legend:

- `[x]` implemented / already present; **runtime test is confirmed only when the entry explicitly says so**
- `[~]` imported but still awaiting runtime validation, or partially present / pending audit
- `[ ]` not imported / not implemented / planned
- `[?]` undecided, or the task needs a more precise definition
- `[-]` intentionally deferred / not planned after an explicit user decision

## TEXT-5.62.165 — PP 战斗回合、连续道具升级界面及结果文字速度正式验收（163～165 累计提交）

- [x] **163：战斗 PP 恢复一次成功使用即结束道具动作**：`ItemUsePPRestore .done` 已扣除一件并写入 `wActionResultOrTookBattleTurn = 1` 后，先看 `wIsInBattle`；战斗中走既有完成出口，不再在库存有余量时重入队伍／技能列表，避免后续取消把已成功使用的回合标志清零。场外库存充足时仍允许连续使用。用户在 164 回归反馈中确认先前要求的相关战斗 PP 场景没有问题；并非所有道具／物种边界均逐项有独立测试报告。
- [x] **164：升级后能力值窗口边框不再残留**：在 `ItemUseMedicine .returnToParty` 通过既有 `GoBackToPartyMenuClean` 重新绘制被升级能力值窗口覆盖的队伍背景，保留场外连续使用。用户确认修复有效，并测试了返回、取消及后续道具使用场景，反馈无异常。底部 `Use item on which Pokémon?` 是正常提示，不能误删。
- [x] **165：结果文字按所选速度逐字显示**：`RedrawPartyMenu_` 只对 `$F0`～`$F8` 道具结果消息清除 `wd730` bit6 的无延迟标志，并在 `PrintText` 前启用 `H_AUTOBGTRANSFERENABLED`；普通菜单固定提示仍即时绘制，公共退出恢复原 `wd730` 值。用户明确在 Fast／Normal／Slow 三档测试成功，结果先逐字出现，然后正常弹出升级能力值面板，观感正常。
- [~] **验收边界／静态检查**：尚未收到所有回复 HP／解除异常道具在三档速度下、所有满 PP／连续取消边界逐项测试的报告。无 MAP，本环境禁止编译／链接 ROM；静态源码与补丁回放不能证明所有运行路径。163～165 清理仅改注释与项目文档，执行指令维持用户已测状态。完整结论在 `docs/ITEM_MENU_TEXT_165_ACCEPTANCE.md`。
- [ ] **后续独立事项**：MoveDex 映射 Rock Polish 对 AGILITY Seen／Use 的过滤（用户已决定方案 B）、旧 `$F0` 是否回收、重复名称格式化的去重优化等均继续另案；不要在本次已验收的菜单功能上为优化冒险重构。

## MOVE-5.62.162 — 岩石打磨 PP 道具名称显示（用户已测正常；战斗 PP 道具回合问题另案）

- [x] **162 名称显示实测反馈**：PP Up、Ether、Max Ether、Leppa Berry 共用的单招选择列表按当前队伍物种把 AGILITY `$61` 显示为 `Rock Polish`；普通 Agility 保持原名。Elixir／Max Elixir 继续走原全招式恢复入口。用户反馈 162 已测试，目前没有观察到异常；这并不等于每种道具与全部边界都分别实测。
- [x] **提示文字的实际覆盖范围**：`text.asm` 的 `_PPIncreasedText` 与 `_PPMaxedOutText` 读取 `wcf4b`，会显示具体招式名，162 已在 PP Up 结果文字装载前进行物种名称映射。`_PPRestoredText` 仅提示 “PP was restored.”，`_PPNoEffectText` 也不含技能名；Ether／Elixir 的成功／无效提示无需改名。这一差异已从源码核对，不应误记为“全部 PP 道具提示都包含招式名称”。
- [x] **162 当时记录的战斗 PP 回合问题已于 163 单独修复**：原先成功使用后仍可按库存进入下一轮选择，取消又可能清零已成功使用的回合标志；最终在 163 的成功出口加入战斗状态判断，用户随后确认相关回归未见问题。162 本身没有实施这一修复，历史版本边界保持不变。
- [x] **162 当时记录的升级能力值框残留已于 164 单独修复**，之后 165 让道具结果文字依设置逐字显示；本段保留为 162 的历史问题来源，不再把它们标成当前未解决的 TODO。

## MOVE-5.62.161 — 岩石打磨战斗外名称显示（用户实测验收；准备 Git 提交）

- [x] **本专项已通过的显示入口**：`159` 修复 Party 详情、Bill's PC 存入与取出详情的 `Rock Polish` 名称；`160` 覆盖战斗／经验道具升级的直接学习、已有四招时的替换列表及相关学习文本；`161` 覆盖遗忘师、回忆师的候选列表和流程文字。用户在 `161` 明确复测回忆／遗忘流程及列表，并复测两种升级来源、直接习得与四招替换，均反馈正常。此前失败的 `157` 实验与 `158` 详情页分流均不是当前最终实现。
- [x] **161 验收清理审查**：逐点复核 `wLoadedMonSpecies`（详情）、`wPartySpecies` + `wWhichPokemon`（学习）、NPC 列表临时借用且恢复的 `wMoveMenuType`、列表的 `wListPointer` 作用域、`CopyString` 的 `DE` 来源／`HL` 目标、绘制前 `HL` 保存，以及 `wMovesString` 缓冲长度。当前受测路径未发现必须立即修复的确定性逻辑错误；不存在可安全断言为死代码的 157/158 实验分支。清理时只将两处 ASM 文件中三行 159/160 版本注释归一为最终 161，不改任何指令。`FormatRockPolishStatusMovesString` 和 `FormatRockPolishLearningMovesString` 存在重复格式化循环，因用户要求暂停功能变更，本次不冒险合并或改动 ASM。详见 `docs/ROCK_POLISH_161_ACCEPTANCE.md`。
- [~] **仍需区分的回归边界**：不同物种的普通 `Agility` 与特殊复制／变身、特殊取消／滚动组合、大岩蛇→大钢蛇等未获得与上述场景同级别的逐项实测；静态条件设计不等于全部场景用户已验证。`161` 的游戏源码状态已实测，不等于 Git Commit/Push 已确认。
- [ ] **161 时的后续规划（按最新 162 状态更新）**：PP 回复／PP Up 的名称已在 162 独立实现并获用户总体测试反馈，项目无独立 PP Max 道具 ID；战斗 PP 恢复类道具的回合问题另列上方 TODO。升级／道具连续使用后的对话框残留仍需独立复现；MoveDex 对映射后 Rock Polish 不记录 AGILITY Seen/Use（已选方案 B），必须再另立版本。原 `$F0` `ROCK_POLISH` 与地区形态表不回收、不修改。

## MOVE-5.62.156 — 岩石打磨复用高速移动 ID（战斗核心收口；显示另案）

- [x] **精简映射**：普通升级表仅调整小拳石、隆隆石、隆隆岩、大岩蛇的 4 条 `ROCK_POLISH` 为 `AGILITY`；大钢蛇按物种规则继承岩石打磨的战斗表现。指定家族战斗时显示 `Rock Polish`、播放原 `RockPolishExtAnim`、实际属性为 ROCK；底层 ID 仍为 `AGILITY` `$61`，速度 +2、30 PP。敌我双方当前招式与敌方 AI 候选属性使用相同的岩石属性覆盖。普通高速移动的名称、动画及超能力属性不变。
- [x] **已知实测范围**：用户验证 156 小拳石进化后仍显示 Rock Polish；157 试验中确认战斗名称、岩石属性、独立动画、速度 +2、30 PP 正确。本次以干净 156 重新组装上述已验证的战斗实现，**干净 156 的 ROCK 属性及战斗核心随后获得用户明确实测通过**；大岩蛇／大钢蛇和敌方专项未获用户逐项确认。助手不编译 ROM，ZIP 未附 MAP。
- [-] **156 当时战斗外名称尚未实现（历史记录）**：157 曾尝试统一详情、升级学习、遗忘／回忆和 PP 道具名称，用户反馈升级学习名称错误、回忆／遗忘空白、PP 提升剂显示不正确；这些试验代码**没有进入本次干净 156**。156 当时的战斗外菜单仍显示原 Agility；之后 159～161 仅在已列明的入口增加映射，MoveDex Seen/Use 未修改。
- [ ] **当时规划（已由上方 161 进度更新）**：战斗外名称的部分入口已完成；仍须单独调查连续使用／学习流程中的对话框残留；MoveDex 对映射后的 Rock Polish 不登记 AGILITY 的 Seen/Use 为后续独立专项，本版仍维持现有记录；地区形态学习表及旧 `ROCK_POLISH` `$F0` 仍保留，暂不宣布编号已回收。

## MOVE-5.62.155 — 虫咬家族战斗映射（收口准备；运行待验）

- [x] **家族映射已接入源码**：绿毛虫／铁甲蛹／巴大蝶、独角虫／铁壳蛹／大针蜂、派拉斯／派拉斯特共八只，战斗中按实际 `BITE` ID 和当前使用者物种解释为 `Bug Bite`；不追踪学习来源。真实伤害为虫属性、物理、威力 60、命中 100%、25 PP，移除畏缩；普通物种的 Bite 仍是恶属性并保留原效果。未新增招式 ID 或修改存档、升级学习表（包括九级／十七级安排）。
- [x] **显示与受击反馈按简化方案实现**：只映射战斗 Fight 菜单和实际出招名称；升级学习／回忆／Party／PC 等战斗外入口继续显示 Bite。MoveDex 的 Bite 条目增加特殊说明而不新增图鉴编号。复用 `DamageFeedbackOverrides` 中的 `BITE, 5, 2`，预期玩家横向轻震、敌方横向重震，且不恢复畏缩；复制招式按当前使用者重新解释。
- [~] **Bank 与静态检查**：152 曾报 `Fly Icon Runtime Helpers` 无法放入 `$3D`，后续将 `Primary-Type Move Overrides` 改为浮动 ROMX；155 的补丁已做正反回放与符号／调用路径静态检查。**尚未收到 153～155 链接成功、MAP 或 155 ROM 游戏实测反馈**；本轮清理不表示链接与运行已通过。用户要求准备提交日志，不等于 Git Commit／Push 已完成。
- [ ] **最小运行回归**：八只映射宝可梦中至少分别覆盖派拉斯与派拉斯特、一个旧家族及敌我双方；检查战斗选招／出招文本、虫属性克制与 STAB、无畏缩、横向轻／重震；用普通 Bite 确认恶属性和畏缩不变；核对 MoveDex、战斗外 Bite 显示，以及模仿／挥指等派生招式。通信战、变身及特殊反馈边界未有单独实测记录。

## MENU-5.62.139 — 启动 Mateo 首页与主菜单优化（用户确认已提交）

- [x] **Mateo Presents 每次启动显示**：按用户最新决定，无论是否存在 Continue 存档，都显示 Mateo 首页约 180 帧；之后沿用 GAME FREAK 流星、耿鬼／尼多力诺开场、标题动画与主菜单流程。不再在开场读取 SRAM 来决定跳过 Mateo，移除无用 `IntroHasContinueSave`、ROMX 包含段；不修改存档格式。
- [x] **138 的主菜单加载优化保留**：不缩短／删除标题按 A 的完整宝可梦叫声，只压缩其后白屏；用户提供 138 视频并表示加载体验明显变轻。前次同口径视频估算：137 约 1.25 秒、138 约 0.83 秒（仅白屏，非按键到完成的全程；录屏近似值）。
- [~] **Continue 存档信息页按 B 防闪烁处理保留**：仍采用主菜单 TileMap 缓存恢复，主菜单退回标题仍走原 `DisplayTitleScreen`。本次未更改该代码，未收到该路径在 139 的单独实测反馈。
- [ ] **139 的最小回归**：有／无 Continue 启动均能看到 Mateo，后续流星／对战／标题和完整叫声正常；有存档标题→主菜单仍快，Continue 信息页按 B 返回无闪，读档和 Options 正常。其余 ROM 模式、损坏存档／软复位仍待专项检查。本环境不编译／链接 ROM。
- [x] **开场按 A 跳过时音效残留**：139 阶段留给后续音频专项，已在 `SFX-5.62.140` 用局部声道清理修复；用户确认 140 的异常已消失。此记录只说明 139 不修改该问题，不是 139 自身已包含修复。

## 标题叫声结束后的白屏时间（`MENU-5.62.138`，待实测）

- [~] **只减少正常存档载入的重复图形传输**：`LoadSAV` 成功路径不再预先清屏、重复传送字体及文本框图块；损坏存档路径保留原有清屏、字体和错误提示，主菜单继续负责最终图形装载。无需改存档校验、SRAM、音频或 TITLE 轮播代码。
- [~] **优化计时口径**：从标题完整 `PlayCry` 结束到主菜单真正出现；宝可梦叫声不计入加载等待。本次静态分析预计有效存档路径省去一次 3 帧清屏、约 17 帧字体上传和约 5 帧文本框上传；实际秒数以用户视频／ROM 测试为准。
- [ ] **待实测**：有 Continue 的标题→主菜单白屏、无 Continue 的 New Game 主菜单、Continue 信息页 B 无闪、损坏存档提示、Options B 返回和主菜单 B 返回标题。未编译 ROM，也未作链接空间验证。

## 主菜单白屏等待与 Continue 信息页退出（`MENU-5.62.137`，待实测）

- [~] **标题轮播完全保留 133**：不改 `engine/titlescreen.asm`；宝可梦叫声、LOGO、首只宝可梦轮播、调色板、标题音乐与主菜单按 B 回到标题的原路径均保持此前已验收 `INT-5.62.133` 的实现。
- [~] **仅优化菜单层**：主菜单初始化先稳定白色遮罩、关闭自动 BG 传输，完成菜单绘制后一次显示，去掉主菜单入口固定 20 帧等待；进入 Continue 信息页前缓存 TileMap，按 B 恢复缓存并等待 A/B 松键，避免重绘时闪烁。
- [ ] **待游戏实测**：有存档、无存档时按 A 后叫声及进入菜单正常；Continue 信息页按 B 无闪、按 A 读档；主菜单按 B 返回标题轮播外观、节奏和音乐保持原样；Options 返回稳定。源码和补丁已静态核对，不代表 ROM 已编译或测试。

## 钓鱼与赠竿教学（`FIS-5.62.90`）

- [x] **背包连续投竿**：水域未咬钩时显示“Use the rod again?”，Yes 可以连续投竿，No 结束本次投竿；上钩进入战斗、无鱼地点直接退出。通过 `wRepeatFishingRod` bit7 防止重试时重绘地图导致文字窗口闪烁；用户在 `FUI-5.62.82` 连续测试约 20～30 次未见原有闪帧。
- [x] **岸边 SELECT 快捷钓鱼**：面向可钓水域时使用最近一次从 BAG 主动使用且仍持有的钓竿；使用两个存档预留字节记录钓竿和有效标记，兼容旧存档。无记录或未持有时显示 A/B 确认提示；非水面 SELECT 仍为自行车。BAG 和 SELECT 的未咬钩 Yes/No 询问共用非递归循环；用户反馈四组岸边回归测试正常。
- [x] **冲浪钓鱼及换竿**：冲浪时可从 BAG 使用三种钓竿或按 SELECT 使用最近一次选择的钓竿；BAG 用竿允许 `wPseudoItemID=0`，SELECT／重复投竿要求 ID 对应。冲浪投竿不使用陆地甩竿图像，保持 94 帧结果等待；用户反馈冲浪换竿、SELECT、连续询问、战斗返回及陆地回归测试正常。
- [x] **赠竿者重复教学**：三位 Fishing Guru 仅在送竿后重复交谈时教授岸边 SELECT、BAG 用竿和换竿；狩猎地带秘密小屋 HM03 赠送者仅在已获 HM03 后增加冲浪用竿提示。首次领取及拒绝分支不变；三位送竿 NPC 的领取、拒绝和重复对话已按用户反馈测试，满背包分支未单独测试。
- [x] **冲浪上钩反馈**：上钩时以 10 次、每次 3 帧的屏幕 Y 坐标切换表现轻微上下抖动，再显示感叹号；用户反馈观感符合预期。尚无皮卡丘／拉普拉斯／普通坐骑逐个专项及极端 OAM 场景的完整结果。
- [x] **连续钓鱼窗口复用**：已减少连续 Yes 的窗口关闭／重复初始化，并删除首轮多余的 `DisplayTextIDInit` 调用。该源码更改不代表下面的 A/B 衔接停顿已解决。
- [ ] **未咬钩提示确认后的停顿**：“Not even a nibble!” 按 A/B 到“Use the rod again?”之间仍有可感知的延迟；用户比较版本后保留 `FIS-5.62.90`，未确认此问题已修复。
- [ ] **成功钓到鱼后的自动续钓**：目前上钩后进入战斗并结束本次投竿；战斗返回后不会自动询问是否继续，需要重新从 BAG 或 SELECT 投竿。
- [ ] **赠竿者满背包测试**：尚未单独确认背包满时不能领取、腾出空间后可以正常领取以及随后的重复教学。
- [ ] **野外战斗转场偶发异常单帧**：普通野外／钓鱼入战的报告需与既有调色板闪屏区分；当前未对战斗转场源码进行修复。
- [?] **开局提前取得首根钓竿**：尚未决定事件位置、领取方式及与原三位赠竿者的关系；当前未改动游戏逻辑。
- [ ] **按累计钓鱼次数判断赠竿资格**：尚未决定统计口径和各 NPC 门槛；需要避免尚未获得第一根竿时无法累计的情况，当前未实现。

## Party 小图标新增类别：静态核查完成，待实测

- [~] **`ICO-5.62.81` — PureRGB `HUMANOID_INSECT` 双帧图标定向移植**：在此前已验收的38类／208只分类方案上，独立新增第39类图标，仅将飞天螳螂 Scyther、凯罗斯 Pinsir、镰刀盔 Kabutops 的 Party 小图标映射至该类，其余205只保持既有映射。使用 pureRGB OG+ 的两帧原图（重排为本项目 16×32 双帧布局，转换为既有四色灰阶），保留现有逐队员 VRAM 加载、HP 速度分档、SELECT 换位无白闪和命名／交换界面流程。**源码与静态检查完成，仍待用户实机确认**：当前 39 类／208只映射，新增的 3 只改用新类、其他 205 只不变；新 PNG 为 16×32、4 色且两帧不同，按现有流程生成每类 8 Tile／$80 字节素材，指针表为 39×3 字节。清理未发现临时调试代码或需要撤销的测试资源；没有改动旧有图标动态加载与换位引擎，也不在未收到实测反馈时冒称验收通过。仍需验证三只的两帧外观、混合队伍、正常／SELECT 换位、不同 HP 档和菜单／命名返回；通信交换若未测试须单独保留未验证边界。素材来源：Vortyne/pureRGB，`gfx/icons/menusprites2.png` 中 `HUMANOID_INSECT`。

## 地图快捷定位：已验收

- [x] **飞行地图 START／SELECT 快捷定位（FLY-5.62.79）**：SELECT 定位真新镇，START 按 Teleport／黑屏返回共用的 `wLastBlackoutMap` 定位最近登记的恢复地点；只切换地图选中项，不立即传送。用户已在普通城市及特殊地点的宝可梦中心恢复后验证 START 定位正常；按一下或持续按住 START／SELECT 均只响应一次；在当前位置或其他目的地按 A 可正常飞行，按 B 可正常返回，未观察到花屏；通关后的恢复点处理也已测试。恢复地点必须通过宝可梦中心恢复等现有事件更新，不以最近路过的城镇为准。未解锁和异常存档标记不计入本次实测通过范围。
- [x] **普通 Town Map START／SELECT 快捷定位（MAP-5.62.80，已实测）**：与飞行地图统一按键语义：SELECT 定位真新镇，START 按 Teleport／黑屏返回共用的 `wLastBlackoutMap` 定位最近登记的恢复地点，只移动浏览光标，不执行传送。普通城市按对应城市定位；4 号道路宝可梦中心映射月见山、10 号道路宝可梦中心映射岩山隧道在普通地图中的位置；未知恢复地图保持当前选中项。用户已按飞行地图同类场景实测，普通城市与特殊恢复地点定位正常；按下或长按 START／SELECT 均仅触发一次，方向切换及 A/B 退出正常，未观察到花屏或其他异常。最后恢复地点只有经宝可梦中心恢复等原有事件才更新，不记录单纯路过的城镇；未知／异常恢复记录的保护分支未单独列入本次实测范围。飞行地图（FLY-5.62.79）保持原有已验收实现。

## 游戏功能状态与后续计划

> 本节集中记录当前分支各项游戏功能的现状和后续处理方式。`[x]` 包括已实现及采用当前简化方案的项目；未特别注明的条目不代表所有场景均已实机验证。与下方历史看板、Legacy Wishlist 重合的事项，以这里写明的具体目标和剩余工作为准，避免重复开发。

### 已实现／暂时验收（20）

- [x] **切换地点／读取存档后左上角提示当前位置**：地点名称会短暂出现并自动消失；已具备相应显示流程。
- [x] **飞行地图按邻近地点切换**：方向切换以当前选中位置为起点，跳到对应方向的邻近可选地点，而非每次从列表开头查找；普通 Town Map 的额外交互不包含在此项。
- [x] **饮料机快速购买和连续购买**：缩短购买演出，购买后留在商品选择窗口，可继续购买；数量和等待限制另列待办。
- [x] **野外宝可梦之笛唤醒队伍**：在野外使用时可唤醒队伍中所有睡眠的宝可梦。
- [x] **电梯运行等待及光标记忆**：统一使用固定 40 次循环的简化方案，不按楼层差动态计时；楼层菜单保留光标位置。
- [x] **毒粉／催眠粉／麻痹粉不同 PAL**：代码分别按毒／草／电属性选择颜色，麻痹粉有明确的黄色配色覆盖；粒子实际显示颜色尚需在游戏中单独验证。
- [x] **玩家房间电脑使用宝可梦盒子**：取得宝可梦图鉴后，房间电脑提供与普通 PC 一致的存取盒子入口。
- [x] **连续撞墙音效限频**：抑制音效尚在播放时的重复触发，避免短时间内频繁响起。
- [x] **Town Map 的 Start 单次触发**：长按 Start 只响应一次，不会连续触发切换。
- [x] **商店购买后记忆菜单光标**：购买完成后恢复先前的商品选择位置，不重置到首项。
- [x] **宝可梦删除／存取后的列表光标处理**：主要列表上移和光标位置修正已完成，暂未发现可复现的剩余异常；如后续出现具体场景，再单独修复。
- [x] **战斗中从宝可梦选择菜单退回时不闪烁**：下方对话框返回流程的闪烁问题已修复，按完成记录。
- [x] **骨头类招式命中飞行属性目标**：Bone Club、Bonemerang 保留针对飞行属性的特殊命中／属性处理。
- [x] **掉血动画速度按伤害比例分档**：根据单次伤害占最大 HP 的比例调整 HP 减少速度，不再全程采用统一速度。
- [x] **MoveDex 连续切换时光标延迟显示**：切换描述时避免第一下闪现光标，减少未使用招式与已使用招式间切换的视觉差异。
- [x] **首次与后续通关的结尾流程区分**：首次通关播放完整人员名单；再次通关缩短名单环节，直接进入结尾。
- [x] **四天王结束后的队伍恢复**：进入名人堂登记前恢复队伍 HP 等状态，避免保留最后一战的残余血量。
- [x] **红／蓝版本开场宝可梦及叫声区分**：红版显示尼多力诺、蓝版显示尼多利娜，并播放对应叫声。
- [x] **开场性别选择与名字返回逻辑**：先选性别再选名字；名字列表直接取消可返回性别选择，具体名字确认时选“否”仍停留在名字流程。
- [x] **交换宝可梦的服从规则**：按训练家 ID、徽章和等级规则判定，不为新游戏交换的宝可梦设置无条件听话豁免；触发不服从判定不代表必定不行动。

### 部分实现（2）

- [~] **户外连续钓鱼**：BAG／岸边 SELECT／冲浪 SELECT 未咬钩后均可连续选择 Yes，选 No 后重新投竿仍正常询问；上钩入战和无鱼地点不继续询问。战斗结束后不会自动续钓，需要再次从 BAG 或 SELECT 投竿。
- [~] **TM/HM 口袋 Start 快速定位秘传机**：按 Start 可跳到已持有的 HM01；没有 HM01 时不跳转，也不会自动定位其他 HM。待明确是否按当前光标继续循环切换已持有的 HM，以及缺少 HM01 时的回退规则。

### 尚未实现（8）

- [ ] **食梦大叔赠送道具增加展示条件**：赠送前需确认玩家携带／展示指定宝可梦；待确定目标物种及触发检查的交互方式。
- [ ] **饮料机限购与等待机制**：在快速购买、连续留在菜单的现有基础上，新增购买数量上限和等待／重置条件；待确定限额与计时参数。
- [ ] **捕获后提示切换存储箱**：在需要换箱时给出明确提示，可考虑当前盒子已满的情况；待确定触发条件及是否允许在提示时直接选择新箱子。
- [ ] **定点宝可梦捕获后降为指定低等级**：野外定点对战（包括梦幻等）保持各自既定战斗等级；捕获成功后，无论进入队伍还是转存 PC，按该物种的指定低等级保存，不强制全部为 5 级。另有“捕获后统一降至 30 级”的备选旧想法，目前决定暂缓，不据此覆盖按物种设置等级的既有方向。待确定适用物种及目标等级；实现时须同步处理经验值、HP、能力值与直接存箱路径。
- [ ] **Teleport 和 Disable 效果优化**：Disable 改为只能禁用目标上一回合实际使用的招式，不再从其他招式中随机选择；Teleport 的具体优化行为尚待定稿。不要把旧的 Mimic／Disable 通用问题审查误当作此项已完成。
- [ ] **特殊招式的行动顺序判定**：使用特殊招式时，施放方以 Speed 与 Special 中较高值参与同优先级下的行动先后判定；若施放方处于麻痹状态，则只以 Speed 判定。实现前需检查优先度、双方速度比较和其他速度相关交互。
- [ ] **类似火红／叶绿的重复对战器（VS Seeker）**：增加可触发训练家复战的完整道具、使用条件和复战流程；可与现有训练家复战长期规划合并维护，避免重复创建功能。
- [ ] **火焰踢（Blaze Kick）动画素材**：准备火焰踢专用技能动画素材；当前尚无完整的 Blaze Kick 技能实现。待确定视觉参考与本次是否包含招式本体移植；此项不是火焰徽章图案。

### 规则与分布待定（2）

- [?] **丰富摇树遭遇宝可梦种类**：当前树木遭遇表有较多重复物种；需重新设计各区域可遇到的物种、等级和概率。重复表项可能代表权重，调整时必须保留清楚的概率分配，不可直接删重。
- [?] **Snowy 状态下的特殊宝可梦遭遇**：需明确特殊宝可梦种类、可遭遇地点、Snowy 生效条件、出现概率以及版本差异，确定后再实现。

### 暂时搁置／保留原行为（3）

- [-] **摇树动画**：已有尝试，现阶段不继续增加树木摇晃动画；保留现有摇树遭遇功能。
- [-] **杰尼龟叫声尾声爆破音**：原版也有尾声爆音，暂未找到可靠且必要的修复方案，不作为当前待修复缺陷。
- [-] **希尔夫公司顶层楼梯／电梯出口卡位**：维持原版的出口落点行为，不修改。

## 已验收功能与专项后续事项

> 本节用于维护当前游戏功能的验收结论和明确剩余工作。以实际体验反馈决定是否继续开发；源码静态检查只能辅助定位。与下方旧版看板或遗留愿望清单出现不一致时，以本节的具体行为和最新验收结果为准；本节不改变任何游戏实现。

### 当前可接受的功能行为

**战斗规则与 PC**

- [x] 大闹一番等连续攻击在无效／失败时解除锁定。
- [x] 烧伤每回合按当前接受的 1/16、中毒按 1/8 扣血；不再按旧方案统一改为 1/8。
- [x] 训练师战禁用背包道具；战斗方式固定 SET。
- [x] 睡眠首回合必定睡眠；冻结目前按约 20% 自然解冻且不设置回合上限，保留现有可接受方案。
- [x] PC 存取列表的窗口与光标位置保持；满队可进入取出列表，实际取出时才检查。
- [x] 已去除徽章能力加成。

**菜单、文字与操作**

- [x] 使用道具后返回菜单的白屏优化，按当前体验验收。
- [x] Fast 模式瞬时打印、学习装置经验提示仅出现一次、存档显示地图名称。
- [x] 宝可梦中心简化对话、升级学习技能名称显示位置、PC 宝可梦列表翻页。
- [x] 快速保存按现有实际使用方式验收；野外砍树／冲浪／撞树／怪力对话加速。

**画面、音效与地图**

- [x] 电梯固定 40 次等待；撞树闪烁修复与短暂白框修复。
- [x] 精神强念类动画顶部覆盖；指定技能音效已验收。
- [x] 皮卡丘野外冲浪动画、扩展飞行目的地与鬼斯家族 Party 图标。

**技能、道具与其他**

- [x] 龙星群独立动画；分类背包与道具列表翻页。
- [x] 御三家终极招式教学按当前项目实际方案验收，不按旧参数再改。
- [x] TM 背包显示技能名称；START 菜单打开速度优化。
- [x] 设置中可切换金银风格音乐；HP 掉血速度分档。
- [x] 进化石等级不足提示按现有更优方案验收。
- [x] 多段攻击最后一击提示克制关系；Continue 页显示版本号。

### 仍需处理／核查的专项

- [?] **训练师 AI 对非伤害状态招式的识别**：检查早期 AI 的招式效果分类／未知效果处理，确认是否误将催眠、麻痹等变化招式按攻击招式评分；与总体 AI 优化分开核对，不再按 MoveDex 的未知字段处理。
- [ ] **烧伤专属状态动画**：目前与其他异常共享骷髅头表现；调整为可区分的烧伤专属动画／图案，具体视觉方案另定。
- [ ] **训练师 AI 后续强化**：现有评分框架继续保留；换人、道具与招式行动排序及更智能决策等问题，在游戏基本成型后统一处理。候选方向包括某些训练师宝可梦以限定概率在速度较低时抢先行动，以及审查 AI 是否提前读取玩家本回合的换人选择；目前均不实施，未来先明确公平性、优先度和概率。
- [ ] **TM 使用时的冗余文本**：精简使用 TM 时过长的确认与提示流程；不重新改造已经验收的技能名显示。
- [ ] **丢弃道具数量的左右 ±10**：商店和 PC 数量选择已共用快速增减逻辑；普通背包丢弃使用非标价菜单，`DisplayChooseQuantityMenu_` 仅对 `PRICEDITEMLISTMENU` 允许 Left/Right，需为丢弃场景补齐 ±10 并保留 1～最大值夹取。
- [ ] **闪光宝可梦入场采用金银风格闪烁**：现有闪光入场特效不等于已达到目标；按用户实际视觉反馈，仍需专门修改并验收。
- [ ] **圣安奴号增加恢复宝可梦的护士**：在合适船舱新增护士 NPC、对话和恢复队伍的脚本；目前未加入。
- [?] **进化后立即学习指定招式的机制**：参考 Evolution Moves 的专用学习规则；当前未发现 `EVOLUTION_MOVE`／`LearnEvolutionMoves` 实现。需要先决定是否移植、哪些宝可梦使用，不把普通等级学招式表当作已完成。
- [ ] **非战斗场景更换招式顺序**：战斗技能菜单已有 SELECT 交换位置与 PP；用户想增加类似金银版的非战斗招式排序交互，尚未完成。
- [ ] **游戏大厅／对战设施的挥指大赛**：以后新增独立活动、参与入口与专用规则；目前没有相应赛事流程。
- [~] **Transform 手动招式同回合使用复制招式（TRF-5.62.209，按已测范围收口）**：当前具备玩家选复制招式／敌方续执行主路径，TEST-214 视频记录了部分复杂镜像与画面缓存修复；TEST-215 用户确认 B 在第二菜单无效、普通菜单 B 正常。未完成全量 Red/Blue/MAP、Link 双端、精确 PP／全部异常边界，不把有限实测写成全面通过。
- [ ] **TM 学习列表增加 Learned 标签**：在 Able／Not able 之外，对已经学过目标招式的宝可梦显示 Learned；当前只有已学判断，未见这一标签的完整显示分支。
- [ ] **吼叫／瞬间移动／吹飞的对战效果与 -6 优先度**：保留已有多档优先度框架，补齐三招的 -6 行动顺序、训练师战效果及相关失败／换人边界。
- [ ] **怪力推动岩石的局部视觉反馈**：目前岩石推动没有专用局部烟尘／闪烁演出；目标是仅被推动的那一块岩石播放反馈，不影响同场景其他岩石。
- [?] **持续束缚攻击后续回合的克制音效**：核实火焰旋涡等每次后续伤害是否保留“效果拔群／不太有效”对应音效；用户不确定以前是否修过，应先复现再决定是否修改。
- [?] **部分宝可梦在特殊半屏画面下被裁切**：用户描述部分宝可梦（如小火龙）移动到屏幕一侧后出现图像缺失；原记录提到孵蛋，但现象来源可能是其他半屏战斗演出。先确认触发动作与复现方法，再定位 OAM／背景裁切。
- [ ] **战斗中宝可梦被击倒后的状态查看**：强制换人界面目前只能选择下一只上场，无法查看候选宝可梦状态；需要新增状态入口，并确保返回后仍处于强制换人流程。

### 暂缓／候选方向

- [-] **愤怒 Rage 招式重设计**：现有机制较弱；未来可能替换整个招式并移除复杂的增攻特殊效果，当前不动。
- [-] **三重攻击效果整理**：不再以“解冻目标”为目标；正确意图是约 20% 概率在烧伤／冻结／麻痹中触发一种状态，当前暂不改。
- [-] **START 一键整理背包**：分类背包已完成；以后可考虑增加专门整理快捷键，现在不做。
- [-] **文字自动滚动**：已有若干个别窗口修正；以后发现具体遗漏场景时再单独修改，不进行一次性全量改造。
- [-] **玩家宝可梦 DV 提升至最大值的剧情机制**：不要求所有宝可梦出生时就是最大 DV；可能通过 NPC 或剧情给予提升到最大值的机会，是否增加待定。
- [-] **特殊训练师专属道具攻击加成**：将来再研究电珠／金珠／骨棒与指定训练师皮卡丘／喵喵／嘎啦嘎啦攻击加成，现阶段不改。
- [-] **候选新招式：重磅冲撞与剧毒种子**：两招目前没有加入，暂不排期。
- [-] **候选新招式：钛晶技能、硬撑、钢拳双击**：尚未决定是否加入；如决定加入，需另定效果、动画及学习范围。
- [-] **训练师 DV 与按等级分配努力值**：原有训练师 DV 框架存在；按等级分档 Stat Exp 等强化规划统一纳入训练师增强专项，规则未定。
- [-] **ROM 扩展与金银地区地图**：扩展到 2MB 并加入额外地图属于长期可行性方案，不纳入近期开发。
- [ ] **宝可梦图鉴／信息页的正背面切换（旧暂缓已由新要求取代）**：2026-10-13 用户改为要求图鉴详情内 START 向后切换已发现地区形态、SELECT 显示当前宝可梦背面；具体设计与验收见下方地区形态图鉴专项 TODO。不是已实现功能。
- [-] **不明确的上下翻页旧构想**：目前没有可验收的独立定义，不实施。
- [-] **学习装置获得难度**：暂时沿用现行获得条件；未来确定更高门槛后再安排。
- [-] **新游戏优先打开 Options**：用户明确暂不修改。

## 补充功能验收与后续专项

> 本节仅记录新增的游戏功能结论、现有专项的新边界及仍需完成的具体工作。已有功能按实际验收为准；未实现与暂缓事项不混用。与前面已有专项重复的要求，优先在原专项中补充，不重复排期。未注明实机覆盖范围的 `[x]` 只表示该功能按当前反馈接受。

### 已完成／当前方案已接受

- [x] **训练师派出宝可梦提示自动继续**：`Send out` 等提示后自动滚动至对方宝可梦名称，不再要求额外按键继续；按现有体验验收。
- [x] **打雷／地震对飞空、挖洞状态的特殊判定**：打雷可命中飞空目标；地震可命中挖洞目标并按现有加伤规则处理，保留目前类似金银世代的实际行为。
- [x] **临时调用的招式仅记录为见过**：Mimic、Mirror Move、Metronome 临时调用的招式按当前 MoveDex 的 Seen／Use 规则验收，不把临时使用等同于永久学会；本项已确认符合预期，不因旧静态核查中的实现路径差异重复开启待办。
- [x] **阻止已经变身的宝可梦再次成功变身**：Transform 检查已有变身标志并转入失败路径；与“变身同回合使用复制招式”属于不同事项。
- [x] **支持删除 HM 招式**：现有遗忘招式流程允许移除 HM，不再额外禁止；保留原有删除交互。
- [x] **战斗外招式用途的描述**：MoveDex 已覆盖居合斩、飞行、冲浪、怪力等野外用途说明，无须另起一套重复页面。
- [x] **背包道具与技能的简短说明**：道具及对应 TM/HM 均已有描述显示，按现状验收；学习技能界面的详情快捷入口另列。
- [x] **真新镇向南通行的既有路线**：初始地区能够向南进入 21 号水路并通往红莲方向，按用户当前体验验收；与“另增居合斩解锁的草地”不是同一要求。
- [x] **START 菜单保留上次光标位置**：关闭／重新打开菜单时恢复之前的选择位置，不与商店购买光标记忆混为一项。
- [x] **高音招式表现沿用已定版方案**：现有独立动画和音效方案已取代旧“三声”构想，不再按旧方案修改。
- [x] **Normal Patch 发布方案已处理**：按现有发布流程的用户验收结论保留，不再单独安排移除工作；不将其误写成删去全部 Normal 游戏构建。
- [x] **MoveDex 字母／数字字模已推送 GitHub**：字模同步由项目维护者明确确认完成；无需再列为待上传项目。

### 待完成／待确定的游戏功能

**战斗与招式**

- [ ] **被击倒后显示正在等待的对方宝可梦**：强制换人时除了允许查看己方候选宝可梦状态，还希望提示当前对手的宝可梦名称／等待对象；尚未确定文字位置、出现顺序与取消返回方式。与“被击倒后查看状态”是两项独立交互。
- [?] **战斗选招与学习招式时显示更多信息**：MoveDex 已能查看招式数据，但希望在战斗和学习招式时直接查看威力、命中率、属性、效果等；入口与布局尚未定案。目前未实现该目标交互。
- [?] **强力 TM 的最低学习等级**：现有学习资格主要由兼容表决定；是否增加强力 TM 的等级门槛尚未决定，需先定义 TM 名单、等级要求及失败提示，再进入开发。
- [ ] **宝可梦／招式的金银风格搜索**：为图鉴或 MoveDex 设计搜索或筛选入口，支持找到指定物种／招式；输入方式、未发现时反馈以及排序需要设计，目前尚未加入。
- [ ] **技能学习界面直接查看当前招式的 MoveBox 详情**：学习招式过程中按 START 打开当前招式详情或 MoveBox，返回时保持原来的学习选择与光标；这是同一个交互需求，不拆成两个重复待办。

**菜单与操作**

- [x] **冲浪状态下按 SELECT 钓鱼**：使用最近一次从 BAG 主动选择且仍持有的钓竿，支持在冲浪状态从 BAG 直接换竿；沿用原文字、音效与遭遇表，省略陆地甩竿图像。用户反馈 BAG、SELECT、连续询问、入战返回及陆地回归测试正常。
- [-] **历史方案 `INT-5.62.133` — 有 Continue 时自动跳过 Mateo**：曾按旧要求实现并测试，现被 `MENU-5.62.139` 的“每次启动均显示 Mateo”正式取代；启动 SRAM 只读判断已移除。历史审查见 `docs/INTRO_MATEO_CONTINUE.md`，以本文件顶部最新定稿记录为准。
- [ ] **开场多个画面按 START 直接进入 Continue**：在允许的开场／标题阶段按一次 START 可直接进入已有存档的 Continue 页面；需明确可跳过的画面、无存档时的回退规则及输入防重复处理。

**图像与音效**

- [x] **`ANIM-5.62.113` — 恢复旧版已验证的宝可梦普通／异色 PAL（用户已确认视觉效果）**：按旧版 `704ddd0`、`071a26d` 的配套 PNG／PAL 关系，恢复仙子伊布、多边兽Ⅱ、波克基古、自爆磁怪四种普通物种，以及洗翠卡蒂狗／风速狗／霹雳电球／顽皮雷弹、伽勒尔蛇纹熊／直冲熊／双弹瓦斯、帕底亚肯泰罗火炽种八种地区形态，共 **12 种、21 组普通／异色 PAL**；只有与旧版不同的颜色被替换。普通蛇纹熊／直冲熊保留既有棕色系；PC18 追加的 18 种形态及伽勒尔呆呆王未改。用户已检查并认可本轮配色结果，**不等于本轮已独立完成 ROM 编译、战斗全部场景或存读档测试**。此次收口不再修改图片或 PAL 数值。

- [~] **`ANIM-5.62.110` — 从 RPP EXPN 1.0 恢复所选宝可梦正背战斗图**：按用户导出的 57 种选择清单，只对选择“替换普通图”的 45 种按正／背独立选择恢复旧项目素材；逐像素相同的面不重复覆盖。磁怪和狃拉旧正面由 6×6 改为 7×7，物种头通过 `pic/bmon/*.pic` 首字节获取图像尺寸，保留原获取方式，不写死当前尺寸。其余技能／属性／进化／遭遇及已有阿罗拉形态不动。**状态**：已执行静态图片规格和文件映射检查；尚未编译 ROM，也未在合并后实机验收战斗图位置与配色。
- [~] **`ANIM-5.62.110` — 独立保存 9 种地区形态正背素材（未接入游戏）**：洗翠卡蒂狗／风速狗／霹雳电球／顽皮雷弹、伽勒尔蛇纹熊／直冲熊／双弹瓦斯／呆呆王、帕底亚肯泰罗火炽种候选，共九组独立 PNG，均不覆盖普通图、不修改既有地区形态引擎或 ROM 引用。旧项目的地鼠、三地鼠和隆隆岩已经与当前阿罗拉正背图逐像素一致，故不复制。**下一项独立工作**：确认新增形态的名称／属性／进化／技能／调色板和获取方式后，再单独接入表驱动地区形态数据与战斗／图鉴图像，并实机验收；本版本只是图片素材预置，不能作为新地区形态已经可在游戏里使用的证据。

- [ ] **部分宝可梦背面图的垂直位置校正**：使全身可见、特别是初级形态的背图在战斗背景中更协调；优先查看超音蝠等案例。需逐物种决定偏移，不直接批量移动，参考截图尚未提供。
- [ ] **低 HP Danger 警报三声后渐弱**：希望低血量警报鸣响三声后，声音逐渐降至原音量的一半；警报节奏、渐弱时长及与 BGM／命中音效的共存应统一验收。它不同于现有的低血量最后命中音效异常问题。
- [ ] **Sucker Punch 施放者前倾与归位**：现有出招动画已经完成，尚未加入施放方宝可梦在攻击前前移、命中结束后回到原位的本体姿态反馈；应先明确双方图像的位移方向和失败时是否播放。

**地区形态专项（`ANIM-5.62.111`）**

**地区形态图鉴专项（当前 `DEX-5.62.121`，按新存档推进可见解锁）**

- [~] **第一阶段 S1：形态位表与读写底座已接入，用户已做初步测试**：当前 `DEX-5.62.114` 固定 80 个独立形态身份（38 个涉及地区形态的物种的普通形态 + 42 条地区形态），Seen／Owned 各占 10 字节；新游戏清零，在现有保存区复用 20 字节；208 个物种图鉴计数维持原状。当前尚未把遇敌、捕获、赠送、进化或交换事件接入新状态，也未改变图鉴形态切换和精灵球显示，所以用户测试时观察到与旧版几乎一致是符合本阶段范围的。用户仅反馈已测试、外观未见明显差别；不据此宣称所有内部读写、存档边界已经逐项实测。**当时的 S1 验收清理仅补维护文档，不改功能 ASM／游戏版本。**
- [x] **S1.5 地区形态存储容量扩展（`DEX-5.62.115`，用户完成基础回归）**：Seen／Owned 保存容量由 80 个身份扩为 128 个，0–79 编号不变，实际登记仍为 38 普通 + 42 地区；复用主存档空闲的 12 字节，没有已用字段移位，不考虑旧存档迁移。用户用新游戏测试了常规战斗、野外遇敌、打开 PC、地区形态小拉达存入 PC、重启读档取出保持形态及彩色显示，均未发现异常。**这只证明这些游戏路径没有观察到问题，不代表尚未调用的 80–127 位读写、地区 Seen／Owned 登记经过实机验收。**
- [~] **S2-A 实际战斗的地区形态 Seen 登记（`DEX-5.62.116`，用户已做基础测试）**：在 LoadEnemyMonData 已完成敌方原始形态解析并设置物种 Seen 后，为实际野外或训练家战斗的 Species + Form 设置独立 Seen 位；不在预览、非战斗赠送建档等路径置位；链接对战沿用原有跳过入口。保持原 208 物种计数及所有形态 Owned 不变，不修改图鉴 UI。重复载入同一敌方形态可重复置位但不会重复计数。用户已经测试该版，未报告可见问题；后续 DEX-5.62.117 的小拉达图鉴实测已覆盖形态 Seen 在界面中的解锁行为，其他物种／获得入口不能据此视为全量验收。
- [x] **S2-B + S3 首个可见闭环（`DEX-5.62.117`，本阶段主要场景已实测验收）**：成功捕获野生宝可梦时为实际形态记录 Owned（并设置 Seen），代码路径覆盖入队与满队直接入箱；后者在 117 当时尚未专项实测，119 阶段用户已补测成功。图鉴首次选择已见形态，START／SELECT 跳过未见形态，身高、体重、描述和基础能力按当前形态 Owned 解锁。用户已实测：只捕获阿罗拉小拉达仅解锁阿罗拉形态；随后遇见普通小拉达先显示已见，捕获后再解锁普通形态；普通形态已见时默认优先显示普通形态，用户认为稍显奇怪但**没有要求修改**。用户又实测波波 ↔ 阿罗拉小拉达、阿罗拉小拉达 ↔ 伽勒尔蛇纹熊两组详情上下切换，未见形态／资料残留；对未见普通形态按 START 不能预览。代码复核的三个疑点（原有 ret 控制流、跨物种 wPokedexViewForm 清零、形态遍历的 D 寄存器）均未发现确定错误；这不等于所有隐藏路径均已实测。保留 208 物种计数和原图鉴精灵球图标；不迁移旧存档。
- [~] **S4 列表形态收集精灵球（`DEX-5.62.119`，用户已完成核心实测，部分边界待验）**：图鉴列表按当前物种全部已登记固定形态身份检查 Owned；没有形态捕获不画球，只捕获部分显示独立的中性灰球，全部捕获使用现有彩球；没有地区形态的物种保持物种 Owned 判定。逐行重绘只设置球所在 BG 属性格（Red++／Blue++ 都复用现有 `$72` 球图块，Blue++ 其他 UI 仍保持原有蓝色主题）。`DEX-5.62.118/S4-001` 曾由用户编译到链接阶段，因新增全局标签改变 `.missing` 作用域而报 Unknown symbol；`DEX-5.62.119/S4-002` 改为作用域内的 `.slot`，同时修复无地区形态物种的跨 Bank 位表指针传参。**119 用户已能进入游戏并实测主要行为**：普通波波捕获后彩球、阿罗拉小拉达单独捕获后灰球、普通和伽勒尔蛇纹熊都捕获后彩球；队伍满 6 只后的成功捕获直接入 PC，图鉴能够更新；图鉴上下切换未发现异常。119 当时第二种蛇纹熊捕获后没有再次自动弹出图鉴页；此问题已在 121 修复，新增形态首次捕获弹出已获用户核心实测确认。**尚未专项验收**：多于两形态的喵喵／肯泰罗、图鉴多个刷新入口、另一游戏版本／非 CGB、在 119 环境保存读档；野外 HUD 的逐形态已捕获标记已在 120 由用户验证，不再列作 S4 未测。不推定用户已提供完整 ROM 构建日志。
- [ ] **后续完善／未覆盖验收**：赠送、进化、交换的独立 Seen／Owned 登记；地区形态研究统计。新形态名单与玩法资料均未定稿。满队**直接捕获入箱**已由用户在 `DEX-5.62.119` 新档实测能够更新图鉴，非当前报告范围的其他获得入口、更多地区形态组合仍未覆盖；下阶段按涉及路径做针对性测试，不重复要求无关 PC／彩色回归。
- [x] **S5 野外敌方 HUD 逐形态小灰球（`DEX-5.62.120`，用户已验证普通／地区形态球状态）**：`color/draw_hud_pokeball_gfx.asm` / `EnemyHUDHAX` 改为向浮动 ROMX 的 `RegionalDexWildHUDOwnedTest` 询问**本次野外敌方真实 Species + Form** 的 Owned；已 Owned 仍显示原 `$E9` 小灰球，未 Owned 明确清除旧球图块；无独立地区身份的普通物种回退到原物种位，其他战斗类型不使用此标记。按 `wEnemyMonSpecies2` + `wWildEncounterFormMarker` 解码原始形态，不以变身后的 `wEnemyMonForm` 判断；无效非零标记不当作普通形态。**图鉴列表三态、球尺寸／颜色和现有 PAL 均不改**。用户反馈 120 的实际普通／地区形态小球独立判定正常；旧版变身专项已测，121 不改变身实现，因此不重复要求变身回归。
- [x] **S6 首次捕获新形态自动展示该形态图鉴（`DEX-5.62.121`，用户确认核心行为通过）**：用户要求普通／地区形态不论捕获顺序，每个形态首次捕获均弹出对应详情，重复捕获同形态不弹。新代码在捕获专用重载之前读取原始 Species+遭遇形态标记的 Owned，暂存到 `wPokedexViewForm` 临时字节，仍按原时机登记形态 Owned；再将 208 物种级 Owned 置位，并以暂存的独立形态捕获前状态决定是否弹出。图鉴原有外部入口已经从重载后的 `wEnemyMonForm` 选择本次形态，不更改默认形态排序。**用户已实测确认：此前尚未 Owned 的另一形态在成功捕获后会进入图鉴，核心缺口已修复。** 本轮反馈没有单独说明重复捕获已 Owned 形态是否不弹窗，也没有逐一确认不同形态详情内容及全部捕获顺序，保留为有条件再检的边界，不要求为此重复整套回归。此前已验收的变身、HUD 小灰球、PC 入箱无需重测。
- [ ] **S6 边界留存（非本轮必测）**：若后续恰好再次捕获已 Owned 的同一形态，可确认是否不重复弹出；如出现弹窗显示不是本次实际捕获的形态，再针对性定位。当前无反例，不要求额外准备变身或重复捕获的整套测试。
- [ ] **图鉴详情 START／SELECT 新按键方案**：按用户 2026-10-13 新要求，将 **START 设为向后／下一个已 Seen 的地区形态循环切换**，不得预览未 Seen 形态；将 **SELECT 设为查看当前 Species + Form 的背面图**，可在正面／背面间返回。现有 `engine/menu/pokedex_info.asm` 是 START 后一形态、SELECT 前一形态，此项需要回收 SELECT 绑定，并确认图鉴详情的内部／外部调用、不同形态素材、异色和翻页显示互不残留；不能影响图鉴列表本身 SELECT 叫声和 START 地区入口。尚未修改 ASM，也未实测。
- [ ] **S4 余下最小验收**：同物种普通／地区形态分别捕获前后确认图鉴独立资料权限、两形态完整收集状态；图鉴列表滚动、进入详情后返回、退出重开及保存读档，确认灰／彩球刷新无串色；未来有条件再验喵喵／肯泰罗多形态与 Blue++／非 CGB。野外 HUD 逐形态捕获球已在 120 完成用户核心实测，不再作为此项待验。
- [ ] **新增形态必须易于维护**：当前 42 条只是阶段性规模。固定 `Species + Form` 对应持久槽位，不以描述符表的排列位置或某次代码重排确定存档位号；增补时审查正常与地区身份的唯一性、位容量、初始化、统计边界、存读档和描述符覆盖范围。具体说明见 `docs/REGIONAL_DEX_114_STAGES.md`。

- [~] **洗翠／伽勒尔／帕底亚 9 种地区形态框架（源码已接入，尚待验证）**：沿用既有 Species + Form 机制，为洗翠卡蒂狗／风速狗／霹雳电球／顽皮雷弹、伽勒尔蛇纹熊／直冲熊／双弹瓦斯／呆呆王及帕底亚肯泰罗火炽种登记 9 条描述符、独立完整头数据、升级／进化表、调色板、正背图及 BANK 引用；复用 `ANIM-5.62.110` 已保存的 18 张 PNG。8 个野生入口按地图／遭遇槽位分配，没有替换整个物种，其他槽位仍可生成普通形态；已有 15 种阿罗拉形态不动。当前仅完成源码接入及静态引用／补丁回放检查，**未完成 Red／Hard ROM 链接或实机验收，不能视为已正式完成**。
- [ ] **九种新增地区形态的剩余占位资料统一定稿**：`ANIM-5.62.111` 首次接入时的玩法资料均为占位；后续已在 `5.62.112` 校正 Special 总和与图鉴体型，并在 `5.62.113` 用旧版已验证 PAL 恢复其中八种形态的普通／异色配色（**伽勒尔呆呆王未改 PAL**）。这些已核对字段不再笼统标为待修；**其余属性／四项种族值分配、捕获率／经验／成长曲线、升级招式、TM／HM／导师兼容、进化条件及形态继承、图鉴分类与描述、野外地图／等级／遭遇槽位／出现率仍为占位**，须后续逐项确定。补齐的 9 个 `*_CATCH_RATE` 只是沿用普通物种数值的符号别名，不代表地区捕获率已定稿。
- [ ] **进化链与获得方式后续补齐**：当前只有既有物种可表示的地区形态进化规则，伽勒尔直冲熊缺少堵拦熊物种，暂不新增不存在的进化目标；九种形态的野外产出地点和概率均为临时安排，实际分布、获得渠道和同地图普通形态共存比例以后统一确认。
- [ ] **ROM、BANK 与游戏路径验收（仍未完成）**：此前链接器报 `Slot Machine Tiles 2` 无法放进 `$34`，参考旧 `rppred.map` 已把原本可跨 bank 访问的类型相克段、老虎机第二组图块、宝可梦笛唤醒与 Route20 分类器迁到 `$30`，地区形态描述符与同 bank 数据仍放 `$34`；又按已有阿罗拉写法补齐 9 个未定义的 `*_CATCH_RATE` 常量。**迁移后尚无新的成功链接结果**，应在用户环境用匹配 RGBDS 的 `make map` 检查 Red／Hard 两版并复查新 map；再测野外普通／地区形态同场出现、捕获、队伍／PC 存取、读档、进化、图鉴、正背图与异色调色板。以上均不标记为已通过。

**地图与剧情**

- [ ] **黄版火箭队剧情融入主线**：在现有火箭队事件基础上补入黄版特色故事；需先确定追加 NPC、地图、章节、对话和事件触发条件。
- [ ] **模仿少女镜像队伍对战**：以后新增与模仿少女对战并使用玩家相同宝可梦的功能；对战触发条件、复制范围、队伍顺序／等级等规则尚未确定。
- [ ] **真新镇南侧增加居合斩解锁的草地**：新增可供较早获得宝可梦的草地区域，使用居合斩障碍控制到达时机；不要与现有向南通往红莲方向的道路重复理解。
- [?] **红莲岛早期抵达后的道馆／建筑进入与难度控制**：若玩家从真新镇南行提早抵达红莲岛，需要确定道馆及相关建筑的进入条件、所需徽章，以及是否使用低等级队伍；当前尚无明确的等级切换规则，先制定设计再开发。

### 暂缓／保留候选设计

- [-] **统一招式威力、命中率和其他特殊效果的平衡**：待招式全集确定后集中调整，不对未指定的招式擅自修改。
- [-] **降低 Special 能力的附加效果概率**：这里特指初代单一 `Special` 能力被降低的附加概率，不泛指攻击、防御或所有能力下降效果；曾考虑降至 10%，但适用招式及当前值仍待确定，按用户决定暂缓，不将旧概率表的其他能力条目当成此项错误。
- [-] **训练师 AI 的额外先手能力及换人预判审查**：未来可能允许部分训练师宝可梦以一定概率不按常规速度顺序先攻，或检查 AI 是否读取玩家当回合换人信息；当前全部 AI 相关增量不排期。
- [-] **MoveDex 属性图标分层合成**：未来可考虑底图圆框与属性形状独立组合，现有完整图标方案继续使用。
- [-] **按当前场景重排背包可用道具**：保留隐藏不可用道具或将其移到末尾的想法；当前分类背包和常规光标逻辑不改。
- [-] **通过事件切换 Normal／Snowy World**：现有世界状态可用于显示和模式切换，但尚无明确的剧情事件方案，暂缓设计。
- [-] **常磐森林北侧独立草地区域**：专属地图／遭遇分布尚未定案，现阶段不添加。

> ROM 空间清理和删除低价值功能的原计划已取消：当前空间不是瓶颈，无需再追加瘦身任务。网页存档编辑辅助工具属于独立工具，不加入本项目开发待办。

## 分类任务看板（从 HUR-5.62.32 开始逐补丁维护）

> 用途：以后新窗口先看这里，就能按**类型 + 状态 + 顺序**判断哪些已移植、哪些还没改。下面的 `Current RPP Roadmap` 和 `Legacy Upstream Wishlist` 保留原来的详细背景；旧条目的 `[x]` 仅表示原文所述功能已存在，不自动代表本次用户实机测试过。
>
> **固定流程：一次只处理一条补丁 → 静态审查 → 用户运行测试 → 单独交付该补丁的验收 TODO 和提交日志 → 用户确认并提交 → 再单独交付下一项功能。** **不得把上一项验收与下一项功能补丁打包交付。** 分类用于查找，合并仍按①～⑩执行，不能按分类随意调整依赖顺序。
>
> 当前情况：**①～⑩已依照用户反馈完成本轮移植与验收；⑩最终保留 `VTC-5.62.51`（原始移植 `c0cf8a93`，从 `SUB-5.62.42` 进入伏特攻击动画专项），保留5×5／6×6／7×7动态目标中心、第一道中心释放、中间三道全屏横扫、第五道中心收束以及双方镜像高度。用户提供51版与52版对比视频，认为延长首尾停顿改善不明显，明确选择51版并确认已撤销52版；52版仅是临时对照，不纳入正式版本或本次补丁。⑦缩小 +2 回避仍保持，Stomp／Body Slam 反制另列长期待办；⑧电推麻痹概率等少见边界未逐项确认；⑤部分数据项目仍只有静态核对。低血量 `Danger` 报警后最后命中音效异常已由用户指出，可能影响多个技能，保留后续公共音效专项，本次不修复。此次仅更新 TODO 和准备提交日志，不改动画代码／版本、不编译 ROM；Git 提交由用户自行完成。**

> **动画逐次移植（第 5 次，正式定版）**：基于 `ANIM-5.62.77`，独立合入 `d825f292`（原 `DK-5.62.66`）的 Draining Kiss 七锚点、双波浪、妖精属性色与 Absorb 吸收／返回衔接。正式版本号 `ANIM-5.62.78`；此前高音、Lovely Kiss、伏特攻击、飞天／冲浪／队伍图标不回退。源分支用户明确选用 66 版外观，64／65／67／68 试验方案不纳入现行实现；如有具体画面反馈，另行修订。

### 动画类（Animation）
- [x] **`ANIM-5.62.151` — 毒击 Quick Attack 独立动画移植收口**：从 GUNK `74e3492c` 移植消失／速度线／回场、Shadow Punch 式预加载；独立 `$61` 灰白 16×16 小 HIT、`SFX_BATTLE_1B` 刺击音效及 **8 帧 HIT＋1 帧清场＋10 帧过渡**，保留 `$46,$5B,$14` 毒液与 Acid／Sludge 轨迹。**用户确认本次已进行 151 动画游戏测试，随后要求收口；未逐项说明双方朝向、低血量音效以及 Quick Attack／Shadow Punch、Acid／Sludge 回归结果，故不写作全部场景通过。** 150 已经独立审查的毒击 `77/256` 普通中毒概率本次代码未修改，用户不再重复抽样；概率未获新的实机专项验证。本环境只做静态及补丁回放检查，未编译／链接 ROM 或核实 MAP；本项不新建专项验收文档。
- [x] **`ANIM-5.62.109` — 双针（Twineedle）双向对称粗针与独立双轨动画**：在 `ANIM-5.62.98` 主线上为双针增加专用浮动 ROMX 动画，使用独立 `gfx/twineedle_projectiles.png` 生成 8 个 OBJ 图块，两套 16×16 粗针分别朝右上、左下，沿金银版式 2:1 斜线对称布置两条相距约 13.4px 的轨道；飞行 20 帧，命中时在两条轨道各绘制一个亮点（4 帧）。我方按敌方 5×5／6×6／7×7 前图尺寸分别选取命中中心，敌方使用反向轨迹命中我方后图。Twineedle 仅替换技能本体动画调用，继续走通用逐击受击反馈；保留 `ANIM-5.62.97` 敌方多段短横震、`ANIM-5.62.98` 双针逐击中毒／替身保护及其他招式素材与音效。**用户反馈**：此双针方案的相关场景已经实测；本次从独立补丁移植到主线后完成源码和资源静态核对，未额外编译 ROM 或重新运行模拟器，不把移植后的独立验证写作已完成。
- [x] **`ANIM-5.62.92` — 聚宝功金币旋转投掷与音效正式定稿（延续 ANIM-5.62.85）**：复用 RPP 原金币 `$4B/$4C` 生成的旋转素材，双方沿同一路径正向／倒序进行 18 帧斜向投掷，每 2 帧切换姿态；按敌方 5×5／6×6／7×7 尺寸定位中心，保留 6 帧 HIT 及 `$52` 原 7 段／35 帧平滑旋转弹跳。飞行改用金银版 `GSSFX_PAY_DAY_RAZOR_WIND`，命中改用 `GSSFX_PAY_DAY_COIN` 双脉冲金币音效，不再叠加 Pound；命中前恢复共用 OBJ `$6D/$6E` 图块，不新增 WRAM 或复制音效序列。用户已明确确认现有演出与音效定稿，撤销原“命中后弹跳衔接”和“抛出及命中音效”两项后续优化 TODO；不采用 3 帧 HIT 试验。
- [x] **`ANIM-5.62.96` — 种子机关枪（Bullet Seed）动画移植**：从 GUNK `81554630`（源分支 `ANIM-5.62.92`）适配至聚宝功主线，在原 Barrage `$8C` 槽改为草系 2～5 次连击；每段独立发射十颗绿色种子，间隔 5 帧、飞行 20 帧、飞散 16 帧，沿用现有 Energy Ball 圆环图块与敌我方向锚点。保留聚宝功专属 PAY_DAY 入口／金币音效和原有其他动画。多段受击短横震单独在 `ANIM-5.62.97` 移植，种子本身轨迹和命中音效未改；**待回归**：Substitute 特殊场景；本主线未进行模拟器验收。
- [x] **`ANIM-5.62.97` — 全局多段攻击逐击短横震**：移植 GUNK `b470046a`（源 `ANIM-5.62.93`），在通用 `PlayApplyingAttackAnimation` 路径按敌方多段招式效果和 `AttackingMultipleTimes` 判断每击短横震（B=2），含 Double Kick、Twineedle、Bullet Seed 等；原招式覆盖表搬到浮动 ROMX，保持普通招式与聚宝功自身震动／音效。**证据范围**：源分支用户曾观察多招式正常，本主线未执行模拟器复测；Substitute 被击破后的反馈待专项确认。
- [x] **`ANIM-5.62.78` — Draining Kiss 七锚点双波浪及吸收定版**：来源 `d825f292`／`DK-5.62.66`，专用 `$39` 七锚点、我方与敌方独立末三段 OAM 轨迹、妖精属性调色板，衔接原有 Absorb `$21` 收缩与 `$22` 返回；末端帧采用两帧停留而非额外曲线移动。保留普通 Lovely Kiss 的 `$12` 九锚点双波浪，高音及其他招式不改。源分支比较后选用66版效果，本次对照源提交指令、位移数据、动画入口和配色恢复，按正式版本记录；出现问题再按反馈另行修改。
- [x] **`ANIM-5.62.77` — Lovely Kiss 近大远小双波浪定版**：来源 `d8ee44ec`／`LK-5.62.62`。9个原X锚点和8段原时序保持；专用OAM逐关键点Y偏移 `0,0,-3,-1,-2,0,+4,+4,+1`，近波由约32px加深至35px、远波从32px收敛至26px，末端Y=49；保留查表变速、远侧波峰浅弧与末端离场。已核对源码、动画入口和原提交说明，按正式版本定稿；后续发现具体问题再调整。
- [x] **`ANIM-5.62.76` — Lovely Kiss 位移节奏迭代**：来源 `6cfbb95a`／`LK-5.62.61`，6对(Y,X)位移查表、波峰浅弧、速度分配已引入；作为第4次定版的前置提交保留，不是单独的最终视觉方案。
- [x] **`ANIM-5.62.75` — Lovely Kiss 逐帧轨迹基础**：来源 `b145d3e5`／`LK-5.62.58`，专用OAM轨迹和9个原锚点保留；作为历史可回溯的独立增量提交。
- [x] **`ANIM-5.62.74` — Hyper Voice 双环**：来源 `5c2cc45e`／`HV-5.62.54`，金橙双圆环、延迟回声、独立ROMX渲染器已接入，原主线功能维持。

- [x] **① `HUR-5.62.32` / `32b5022c` — Hurricane（暴风）**：独立风柱、持续风线、Thunder 音效、双向演出和受击反馈已移植；**用户反馈已运行测试，暂未发现明显问题**（2026-10-08）。尚无逐项测试清单，不把各测试场景写成分别通过；以后若复现异常再重开。
- [x] **② `SP-5.62.33` / `2c3b12a8` — Sucker Punch 专属动画与 Dark 命中配色**：仅动画、音效与配色的独立移植；**用户反馈已运行测试，暂未发现明显问题**（2026-10-08），未提供逐场景测试清单，不推定各项均独立通过。② 提交日志已准备；是否完成 Git 提交，以用户自己的仓库为准。现代失败判定仍属于③。
- [x] **⑥ `SW-5.62.37` / `75ac4ff2` — Steel Wing（金属翼）金银版动画**：已单独移植并完成本轮用户验收（2026-10-08）。复用 Iron Tail 的 Gold/Crystal Metallic 开场，跳过铁尾 Wobble/HIT_BIG 后半段，恢复场景后接 Wing Attack 的三组 closing pairs；使用钢系配色。增加敌方出招后的竖震反馈及 BG0 顶行预清理；保留原铁尾、翅膀攻击及招式数据。**用户反馈三组建议场景均已测试、暂未发现异常**：我方金属翼演出，敌方金属翼受击竖震与顶部残影，连续使用金属翼／铁尾／翅膀攻击后的画面恢复；未提供额外的逐帧或全部边界条件验证，不扩大实测结论。⑥提交日志已准备，正式 Git 提交由用户完成。
- [x] **⑩ `VTC-5.62.51` / `c0cf8a93` — Volt Tackle 五道电流、三档动态中心及受击反馈**：在⑨ `SUB-5.62.42` 之上独立移植伏特攻击专属动画。复用 Spark 的 Thunder Wave 充电演出及 Quick Attack 速度线消失，接5道电流（每道8姿态、通常每姿态2帧）：**第一道由施放者中心向外扫出；第二～四道保持全屏交替横扫；第五道收束在对方中心**，随后显示电击爆发与受击反馈并恢复宝可梦。敌方前图按5×5／6×6／7×7尺寸选择几何中心，电流五道高度依次在88～52／88～48／88～44之间均匀分布，双方用同一高度组正序／倒序、X方向镜像；5×5／6×6／7×7的敌方中心分别为OAM `(132,52)`／`(136,48)`／`(132,44)`，我方后图使用 `(48,88)`。**用户已提供51版双方演出视频并核对起点、全屏扫线、末端收束；与52版视频比较后认为额外首尾停留效果不明显，明确选择保留51版且已撤销52版**。早期50版“全部五道中心到中心”方案已否决，49版三档中心思路保留在51实现中。原⑧反伤／麻痹和⑨替身逻辑未改；正常攻击受击反馈、Bank `$3E` 渲染器继续保留。**验收范围**：视频检查与用户选择支持本次动画方案，不代表已逐项验证所有姿态的视觉中心、地区形态、连续使用／颜色恢复、低血量声音及全部结算边界。低血量报警音效问题转后续独立专项；本次仅改 TODO，不修改动画或游戏版本，不编译 ROM。

### 战斗功能 / 结算类（Battle logic）

- [x] **`MOVE-5.62.148` — GUNK 007 第一批招式效果移植（源码审查收口）**：基于已提交 `ANIM-5.62.146`，完成吸取之吻 75% 回血、暗影爪高暴击、龙息／放电 77/256 麻痹、水之波动 51/256 混乱、暴风 70% 基础命中及 77/256 混乱、蹭蹭脸颊电属性免疫／替身阻断和替身恰好破裂修复；保留 146 伏特攻击动画。用户确认蹭蹭脸颊打替身不麻痹、原动画正常；独立审查对吸取之吻替身结算进行了 261,120 组数值模拟。**148 修复后替身及其余概率未完整实机专项复测，本环境未编译／链接 ROM，也未确认 MAP 空间。** Git Commit/Push 由用户执行。

- [x] **`ANIM-5.62.98` — 双针（Twineedle）每击独立中毒判定**：移植 GUNK `2ddc8ddb`（源 `ANIM-5.62.94`），在敌我共同的每击伤害结算后独立进行 `$34/256`（20.3125%）中毒抽取；保留两击与首击已中毒的继续攻击，取消原整招末尾多余的第三次中毒判定。用命中前替身状态阻断穿透（包括本击刚好击破替身），沿用原有目标倒下与状态免疫判断，保留 `ANIM-5.62.97` 短横震。**测试范围**：原 GUNK 分支用户曾观察首击或次击中毒；当前聚宝功主线尚未实机验证，替身击破、属性免疫、已有异常状态、提前击倒及双方交互仍需最小回归。
- [ ] **Roar / Whirlwind 的 -6 行动优先度**：当前多级优先度框架仍将这两招按 0 处理；另立招式优先度修复任务，和下方既有的“训练家战吼叫／吹飞强制换人”任务分别核对，不在这里重复新增强制换人待办。
- [ ] **训练家 AI 道具／换人与技能行动的统一排序**：检查旧框架“先按所选技能排序，后决定道具或换人”的时序；统一行动意图和优先度结算，并回归 Sucker Punch 成功判定及一般同优先度速度比较。
- [~] **Nuzzle（蹭蹭脸颊）麻痹与 Substitute**：已在 `MOVE-5.62.147` 移植电属性免疫、命中前替身标记、取消第二次命中判定及恰好击破替身修复；用户反馈实际测试命中替身时不会麻痹，未提供敌我／逐个边界的完整记录。其他 Substitute 异常状态由专项任务另行处理。
- [ ] **Bide 与 Substitute 的特殊结算**：核对储存伤害、蓄力期间受击和反击落点；Bind／Wrap 的束缚回合规则与 Counter 替身／OHKO 边界已在下方 legacy 候选表列出，不重复新建。

- [x] **③ `SP-5.62.34` / `5ca3afb3` — Sucker Punch 现代失败判定**：先手且目标选择伤害招式时方能成功；变化招式、后手、Recharge、换人及道具行为有专门失败检查；失败显示 `But it failed!`，我方进入判定前扣 PP。包含 Trainer AI 单次提前判定、Mirror Move 实际招式 ID、MoveDex 和 `$CCE0` WRAM 状态。**用户反馈已实机测试，暂未发现明显问题（2026-10-08）**；进一步代码逻辑复审未发现明确阻断问题。未提供各边界场景逐项结果；Trainer 道具/换人的全局排序仍为旧架构限制。③提交日志已准备，实际提交由用户完成。④已移植并获用户测试反馈。
- [x] **④ `PRI-5.62.35` / `ddddb20e` — 多级技能优先度及 ExtremeSpeed 区分**：源码已单独移植；**用户反馈已运行测试，暂未发现明显问题（2026-10-08），后续源码逻辑复审未发现明确阻断问题**。优先度以 `+7` 偏移编码：ExtremeSpeed `+2`、Sucker Punch/Baby-Doll Eyes/Ice Shard/Bullet Punch/Quick Attack `+1`、普通 `0`、Counter `-5`；同优先度仍按 Speed / 同速随机决定顺序。Roar、Whirlwind、Teleport、Bide 暂保持 `0`，不提前升级效果机制。未提供逐项边界测试记录，不将联机、AI 道具/换人等特殊场景标记为全部通过；旧架构中训练家道具/换人决策时序仍待以后复查。**未调整③失败判定或已验收动画，④验收提交日志已单独准备；是否 Git 提交以用户仓库为准。**
- [x] **⑦ `BSE-5.62.38` / `ff4fec55` — 伤害型能力副作用、Gen I Special 平衡**：已单独移植；**用户反馈已运行测试，其他效果暂未发现明显异常（2026-10-08），但未逐项提交所有概率、双侧、替身／击倒、能力极限等边界测试结果**。共享 Move ID 概率表统一伤害附加能力变化（10% / 20% / 30% / 命中后必定）；Metal Claw / Meteor Mash / Steel Wing / Silver Wind / AncientPower / Mind Blast 的自身能力提升及 Draco Meteor 的自身 Special 下降在目标被击倒前处理。Gen I 共用 Special 平衡及 MoveDex 说明保持本次移植内容；吐丝降速度2级、瞬间失忆提升 Special 1级、**缩小每次提升回避2级（10 PP）**。经讨论确认维持缩小 +2，不应用此前尚未验收的 `BSE-5.62.39`（+1）试验修正。⑦验收只更新 TODO，不再改游戏代码；实际提交由用户完成。
- [x] **⑧ `RCL-5.62.41` / `7ecf21ce` — 反伤比例及 Flare Blitz / Volt Tackle 状态效果**：已独立移植并按用户反馈完成本轮验收（2026-10-08），**目前所测场景未发现明显异常**。按真实 Move ID 分配反伤：Struggle 1/2，Flare Blitz／Volt Tackle／Wood Hammer 1/3，原有其他 RECOIL_EFFECT 招式保持 1/4；火推约10%烧伤、电推约10%麻痹接入普通状态副作用路径。目标直接被击倒时先结算使用者反伤，目标 HP 归零后不再附加异常状态；替身不能被附加状态穿透（源码路径已检查，边界待实测）。**用户实测记录**：己方、敌方分别使用闪焰冲锋，均观察到对方至少一次烧伤；约十余次共观察到两次烧伤，样本不足以验证精确触发率。**未逐项确认**：伏特攻击麻痹概率、各招式反伤数值、直接击倒后反伤、未命中／属性免疫、替身及双倒等特殊场景。⑧附带链接空间修复：首次构建遇到 Bank `$34` 的 `Red Bedroom PC` 无法放置，将该独立区段迁至 Bank `$3E`，入口仍通过 `BANK(OpenRedBedroomPC)` 动态选择 Bank；用户随后继续运行测试，但未报告卧室 PC 专项检查／新版 MAP 数据。⑨替身多段结算另在 SUB-5.62.42 实现，⑩电推专属动画仍未移植；本段保留⑧验收记录。
- [x] **⑨ `SUB-5.62.42` / `d41f0048` — Substitute 多段攻击与反伤结算时序**：已在⑧验收后源码上独立移植；**用户已运行测试并反馈可以继续，暂未报告明显问题（2026-10-08）**。多段攻击击破目标替身时，本次命中只作用于替身，其余段数可继续命中本体；攻击者自身替身在多段攻击期间避免每段重复切换，目标承伤与反伤结算后再恢复，反伤致使用者濒死则不重画替身。反伤继续使用⑧的比例及状态结算规则。**验收范围限制**：用户未提供双方替身、多段击破、双倒、替身状态穿透等场景的逐项结果，不将这些情况分别记为通过；源码已静态检查双方入口、跨 Bank helper 与 KO 返回路径，仍需遇到问题时再复查。本轮仅更新 TODO 和⑨提交日志，不改游戏代码／版本、不自行编译 ROM、不包含⑩。
- [ ] **缩小的后世代反制（后续独立专项，非下一版）**：以后再考虑为 Stomp（踩踏）和 Body Slam（泰山压顶）增加“目标实际使用过 Minimize 时，跳过一般命中／回避判定并使伤害×2”的特殊规则；Fly / Dig 无敌阶段和正常属性免疫仍应保留，单纯 Double Team 不触发。需单独审查双方判定、状态清除和伤害结算。**当前未实现，后续独立处理；下一项⑨也不加入。**

### 招式 / 数据类（Moves & data）

- [x] **`MOVE-5.62.149` — 三牙双追加效果源码审查收口**：Fire Fang／Ice Fang／Thunder Fang 的畏缩均为 `51/256`（约 19.92%），原有约 10% 灼伤／冰冻／麻痹分别独立抽取，两种效果可同时触发；原有替身、击倒和属性免疫处理不变。**独立源码审查反馈未发现明确逻辑错误；149 尚无本分支 ROM 编译与实机回归证据**，不视为概率大样本或全部边界场景实测通过。
- [~] **追加混乱概率核对**：`MOVE-5.62.147` 已对 Water Pulse／Hurricane 分别移植约 20%／30% 混乱和暴风 70% 命中，并阻断命中替身的追加混乱；待主分支验收，其他混乱招式维持既有规则。
- [x] **`MOVE-5.62.149` — 恶之波动／龙卷风／意念头锤源码审查收口**：Dark Pulse／Twister／Zen Headbutt 畏缩均为 `51/256`（约 19.92%），Zen Headbutt 基础命中率调整为 90%；按实际 Move ID（含派生招式）选择概率，Bite／Headbutt／Stomp 等原规则不变，MoveDex 已同步。**独立审查认为源码符合目标，尚待本分支编译和实机回归**，不以审查代替运行验收。
- [x] **`POISON-5.62.150` — 第三批中毒／剧毒效果源码审查收口**：从 GUNK `2f5a9796` 迁移 Poison Jab／Gunk Shot 的普通中毒 `77/256`（30.078125%）、Poison Fang 的剧毒 `128/256`（50%）；按实际 Move ID 兼容派生招式并同步 MoveDex，保留 Poison Sting／Twineedle、Smog／Sludge、Sludge Bomb 与 Toxic 的原有规则。**用户转述的独立源码审查结论为逻辑符合需求，未发现须立即修复的问题；用户未单独实机测试 150**。本环境未编译／链接 ROM、未核实 MAP；敌我双方、替身、属性免疫、已有异常、直接击倒和派生招式的运行边界均未独立验收。
- [~] **Draining Kiss（吸取之吻）替身吸血修复**：148 已在源码中修正未破、恰好击破、超额击破替身时的吸血基数，按 `max(1, floor(min(计算伤害, 替身受击前 HP) × 75%))` 计算；击破替身仍能回血，其他吸收招式维持 50%。数值模拟通过，但**148 修复后仍待用户实机复测**。
- [-] **迷唇姐（Jynx）专属吸取之吻：待定，暂不实现**：候选需求为迷唇姐使用时威力翻倍、回复比例改为 100%。**148 和下一版（GUNK 008）都不修改**；等用户决定后再单独立项，不影响其他宝可梦的通用规则。
- [ ] **Skull Bash（火箭头锤）蓄力与物防强化，后续独立实现**：按用户指定，在开始蓄力时立即提升使用者的物理防御，蓄力回合结束后再发动撞击；后续实现前核对两回合时序、物防提升时点、蓄力中断、再次出招及敌我双方流程。**149 仅明确需求并更新 TODO，不修改现有招式行为；不并入下一项 009。**
- [ ] **Sky Attack 现代追加效果**：审查神鸟猛击的畏缩及高暴击等目标规则、触发率与两回合蓄力／释放时机；明确规范后独立修改，不捎带其他两回合招式。

- [x] **⑤ `AUR-5.62.36` / `e630f377` — Rolling Kick → Aura Sphere（波导弹）**：源码已移植并完成本轮用户验收（2026-10-08），用户分别测试了我方/敌方使用、目标处于无敌状态时使用，以及动画结束后的画面残留，反馈**暂未发现明显问题**。招式沿用 `$1B` ID，威力80／格斗系／特殊／20 PP，使用 Swift 必中效果；Fly/Dig 无敌交互沿用当前战斗机制。特殊攻击的实机伤害数值、6处升级学习表及对高闪避目标的普通必中场景**未由用户实测**；对应招式数据、分类表和学习条目已静态核对，不将其写为运行通过。⑤提交日志已准备，正式 Git 提交由用户完成。

### 菜单 / UI 类（Menu & UI）

- [ ] **MoveDex「Anim」动画预览**：将主列表当前的 Anim 占位入口接入所选招式动画预览，正确保存／恢复菜单与地图资源，不把技能真实战斗效果当作预览执行。
- [ ] **MoveDex「Effe」机制详情**：将 Effe 占位入口接入技能效果／追加概率说明；文字必须跟随当前 RPP 实际规则而非照抄后世官方描述。
- [ ] **MoveDex SELECT 编号／ABC 排序**：支持按 SELECT 在招式编号顺序与字母顺序间切换，并保留 Seen / Use 状态、光标定位和菜单返回行为。
- [?] **MoveDex Steel / Dark / Fairy 类型图标最终美术选择**：当前图标可用，交接文档仍有多组候选稿未获明确选定；仅在用户决定后替换素材，不作为程序缺陷自动修改。

- [x] **`ICO-5.62.73` — Party 小图标性别主题色（用户验收）**：队伍图标在菜单加载时按玩家性别显示男红／女绿；正确读取 WRAM Bank 1 中的性别并恢复调用方 Bank，OBJ palette 0 不影响 HP 血条独立的 BG 绿／黄／红调色板。保留 38 类图标、208 只物种映射、双帧动画和普通／SELECT 换位流程；用户测试最终方案未报告问题。

- [x] **`ICO-5.62.63` — 208只宝可梦队伍小图标分类最终定稿（38类，用户确认）**：以已验收的 `ICO-5.62.62`（36类）为基线，依用户修订的208只宝可梦图鉴 XLSX 逐行确认，D/E 多列均读取，**E列的具体图标指令优先于D列旧 ✓／×**，即使某行已有 ✓，后列的新选择也必须落实；无明确更换指令的物种不擅自改。最终仅调整25只宝可梦，其他183只保持原样。新增金版原始16×32双帧 `FOX`（六尾／九尾、喵喵／猫老大、卡蒂狗／风速狗、伊布及8种进化形态，共15只）和 `HUMANSHAPE`（凯西／勇基拉／胡地3只），类别36→38；复用原有 `SHELL_GS` 给大钳蟹／巨钳蟹／化石盔／镰刀盔4只，`BALL_M` 给多边兽1只，`BLOB_GS` 给熔岩虫／熔岩蜗牛2只。化石盔／镰刀盔虽在 D 列标 ✓，仍以 E 列“二代shell”为准；菊石兽／多刺菊石兽继续使用一代 `HELIX`。保持黄版皮卡丘、一代与金版先前验收分类、动态加载引擎、正常／SELECT 换位无白闪机制、208只映射及固定列对齐。**用户最终反馈**：“都看过了，没问题，定稿吧，这是最后一版”；据此将本轮图标专项标记为定稿，后续不再以待选类别继续开新批次；不将笼统反馈夸大为每个 HP、命名／通信交换等边界逐项通过。此验收清理**仅修改 `TODO.md`**，不改图像、引擎、源码映射、Bank、文件权限或游戏版本号（仍为 `ICO-5.62.63`）；AI未编译 ROM 或执行 Git 提交。


- [x] **`ICO-5.62.62` — 第六批一代／二代队伍小图标去重与精选细分（最终36类，用户反馈后收口）**：以已验收的 `ICO-5.62.61`（34类）为基线，本版最终仅新增金版 `ODDISH`、`FISH` 两种16×32双帧模板，合计**36类**。`ODDISH` 只分配给走路草／臭臭花／霸王花／美丽花；喇叭芽家族仍用一代 `GRASS`。`FISH` 只分配给角金鱼／金鱼王／鲤鱼王；墨海马／海刺龙／刺龙王改用一代 `SNAKE`，灯笼鱼／电灯怪仍用 `WATER`。波克比、皮皮、皮可西、皮宝宝继续使用一代 `FAIRY`，正式撤销此前尝试加入的金版 `CLEFAIRY`；撤销金版 `EQUINE`，小火马／烈焰马保留一代 `QUADRUPED`。相对5.62.61仅调整**10只**宝可梦映射，其他**198只**不变。此前38类初稿、37类修订稿均已被最终36类方案取代，不作为提交内容。**核查依据**：一代 RPP 实际显示双帧与金版38张素材的对照显示 `MON/MONSTER`（两帧顺序互换）、`SNAKE/SERPENT`、`QUADRUPED/EQUINE` 两帧逐像素重复；`FAIRY/CLEFAIRY` 有一帧完全一致，另一帧相近，故不为微小差异再建类别。去重规则和检查步骤已写入根目录 `RPP_DEVELOPMENT_PITFALLS.md`，包含实际OAM镜像显示、两帧及其先后、调色板差异、已导入素材复用、208只映射与列对齐检查。**本轮验收**：用户在最终去除波克比专用妖精图标后反馈“没问题”，并要求清理提交；此处如实记载用户认可最终修订版，不夸大为每个场景都有单独录像。命名与通信交换无本版单项测试记录。**本次清理仅修改 `TODO.md` 和根目录开发踩坑文档**，不改图标素材／引擎／映射表／权限或游戏版本号（仍为 `ICO-5.62.62`）；AI未编译ROM或执行Git提交。

- [x] **`ICO-5.62.61` — 第五批队伍小图标细分类：SHELL／CATERPILLAR／MOTH／BLOB（用户测试后收口）**：在已验收 `ICO-5.62.60`（30类）上新增4种金版16×32双帧模板，合计34类、涉及14只宝可梦。保留一代 `HELIX` 给菊石兽／菊石多刺／化石盔／镰刀盔，仅将大舌贝／刺甲贝改为 `SHELL`；`CATERPILLAR` 对应绿毛虫／铁甲蛹／独角虫／铁壳蛹／毛球，`MOTH` 对应巴大蝶／末入蛾，`BLOB` 对应臭泥／臭臭泥／瓦斯弹／双弹瓦斯／百变怪。其余194只物种映射不变；不替换原有 `HELIX` 素材，不修改动态加载、无白闪换位和特殊动画引擎。四张原始素材来自用户提供的 `pokegold-master(1).zip`；新增映射遵守根目录 `RPP_DEVELOPMENT_PITFALLS.md` 的固定列对齐。**用户本轮反馈**：按本版建议完成三组测试（四类图标双帧及 HELIX／SHELL 区分、新旧六人混搭和普通／SELECT 换位、摘要／菜单返回及不同 HP 下的切帧），随后回复“都测过了”并要求按惯例验收收口，本轮未报告明显异常；此处记录用户反馈，不声称每种极端排列均有独立实测证据。**命名与通信交换没有单独报告**，不记作已通过，不要求每批素材更新重复通信专项。此次验收清理**只更新 `TODO.md`**；`data/mon_party_sprites.asm` 已满足根目录列对齐规则，208只的映射、图像、动态加载／无白闪换位引擎、Bank 和游戏版本（仍为 `ICO-5.62.61`）均不变。AI未编译ROM或执行Git提交。

- [x] **`ICO-5.62.60` — 第四批金版队伍小图标：胖丁、地鼠、水母与格斗类（用户测试后收口）**：以已验收 `ICO-5.62.59` 的26类动态加载引擎为基线，新增4类（JIGGLYPUFF、DIGLETT、JELLYFISH、FIGHTER），合计30类；覆盖16只宝可梦：Jigglypuff／Wigglytuff／Igglybuff，Diglett／Dugtrio，Tentacool／Tentacruel，以及 Mankey／Primeape／Machop／Machoke／Machamp／Hitmonlee／Hitmonchan／Hitmontop／Tyrogue。四张均取自用户提供的金版源码 `gfx/icons/`，使用原始16×32双帧素材；核对现存队伍图标 PNG 无同图可直接复用，现有宝可梦战斗立绘不作为队伍双帧图标使用。其余192只的类别不改，动态引擎、无白闪换位逻辑、已验收的旧素材均不改；`data/mon_party_sprites.asm` 新行遵守根目录 `RPP_DEVELOPMENT_PITFALLS.md` 的逗号、第二列与备注列对齐规范。**用户本轮反馈**：已按本版建议完成四组测试（新图标双帧、六只新旧混搭、普通／SELECT 换位、摘要／菜单往返及 HP 动画），用户回复“都测了”并要求按既定流程收口，未反馈明显异常；此处仅依据用户反馈，不声称提供了逐项测试录像。**通信交换和命名入口没有单独测试记录**，不能记为已独立验收；后续仅在相关路径改动或出现问题时有针对性复测。此次验收清理**仅更新 `TODO.md`**：不改映射表（已满足根目录列对齐规则）、素材、动态加载与无白闪换位引擎、Bank 或游戏版本号（仍为 `ICO-5.62.60`）；AI未编译ROM或执行Git提交。

- [x] **`ICO-5.62.59` — 第三批金版队伍图标：高辨识度模板（用户实测后收口）**：在已验收的 `ICO-5.62.58` 动态加载引擎上新增10类、覆盖24只宝可梦，总类别由16增至26，保持208只映射完整。按金版原始物种归类，三条初代御三家中 Bulbasaur／Ivysaur／Venusaur 用 BULBASAUR，Charmander／Charmeleon 用 CHARMANDER，Charizard 和 Dragonite 用 BIGMON，Squirtle／Wartortle／Blastoise 用 SQUIRTLE；另加入 GYARADOS、SNORLAX（含RPP额外的小卡比兽）、SLOWPOKE（含呆呆王）、LAPRAS（仅乘龙）、GEODUDE、POLIWAG（含蚊香蛙皇）。所有新素材均为上传金版源码的原始16×32双帧PNG，不镜像，不修改旧素材、引擎／换位映射；普通鸟／虫／鱼／四足等广覆盖模板暂缓。**用户本轮反馈**：已检查前四组（御三家、六只混搭、普通／SELECT换位、摘要及菜单返回），第五组的血量动画也已查看／测试，未报告明显异常；**通信交换明确未测试**，命名入口及其他未单独报告的细节不记为逐项通过。此次按反馈验收收口；清理仅修正 `data/mon_party_sprites.asm` 的列间排版、更新 `TODO.md` 和根目录 `RPP_DEVELOPMENT_PITFALLS.md` 的永久规则，不改任何图标映射、素材、动态引擎或游戏版本号（仍为 `ICO-5.62.59`）；AI未编译ROM或执行Git提交。

- [x] **`ICO-5.62.58` — 第二批金版队伍小图标：洛奇亚／凤王（用户测试后收口）**：沿用 `ICO-5.62.57` 已验收的动态加载引擎，为 Lugia、Ho-Oh 各增加 1 类图标（`$0E`、`$0F`），使现有图标从 14 类增至 **16 类**；使用金版原始 16×32 双帧 PNG、跨 Bank 素材指针，仅改变洛奇亚与凤王两只的图标映射。其他物种、原 14 类、无白闪的普通／SELECT 换位引擎均保持不变；两张新素材以非镜像四图块显示。**用户实测反馈**：“测过了，没什么问题”，据此完成本轮验收；反馈未逐项列出独立动画、混搭队伍、普通／快捷换位、摘要返回、命名／通信交换和黄／红 HP 帧速的逐项结果，不能写为这些边界全部分别通过。**验收清理仅更新 `TODO.md`**，不修改引擎、映射、PNG、ROM Bank 或游戏版本（仍为 `ICO-5.62.58`）；AI 不编译 ROM、不执行 Git 提交。

- [x] **`ICO-5.62.57` — 动态图标引擎换位白闪修复（用户复测收口）**：在 `ICO-5.62.56` 实机测试中，普通换位和 SELECT 快捷换位均出现旧版 `5.62.55` 没有的短暂白闪；原因为换位后重载队伍图标时关闭 LCD。最终 `5.62.57` 在换位时只交换六项“队伍位置 → VRAM 原图块槽位”的 WRAM 映射，OAM 通过映射选图，取消这两条换位路径上的 LCD 关闭与重复 VRAM 加载；首次进菜单／摘要返回仍沿原入口正确刷新图块及映射。**用户已对修复补丁复测并反馈“没问题”，本轮据此收口**；没有逐场景视频或子项测量，不将所有极端边界写成分别通过。验收清理仅改 `TODO.md`，保持 `ICO-5.62.57` 游戏版本、源码与素材不变，AI 未编译 ROM 或执行 Git 提交。

- [x] **`ICO-5.62.56` — 队伍小图标按成员动态加载框架（已并入 `ICO-5.62.57` 验收）**：借鉴 Yellow Legacy 的按队伍成员加载机制，以每物种 1 字节图标类别映射和 ROM 内 3 字节跨 Bank 素材指针替代固定 4-bit 类别槽位；队伍最多六只，每只两帧共 8 Tile，按队伍位置加载到 VRAM，而非预载所有类别。保留原 14 类与全部物种映射、双帧外观以及精灵球／螺旋特殊抖动、黄版皮卡丘绘制；原始 PNG 不改，只新增运行图集和交换圆圈素材。用户表示已测试此前要求的五组主要场景，`5.62.56` 唯一明确报告的回归是普通／快捷换位白闪，已在 `5.62.57` 修复并获复测反馈；**最终采用 `5.62.57`，不单独验收含闪白的 `5.62.56`**。当前仍只含 14 类，约 28～30 类是后续逐批规划，并非本轮已实现。

- [x] **`ICO-5.62.55` — 第一批4类队伍小图标融合（本轮用户测试后收口）**：以 `VTC-5.62.51` 为功能基线，`ICO-5.62.53` 首次导入4类、覆盖13只宝可梦：黄版 Pikachu（Pikachu／Raichu／Pichu）、金银 Staryu（Staryu／Starmie）、Ghost（Gastly／Haunter／Gengar／Misdreavus／Mismagius）、Bat（Zubat／Golbat／Crobat）；保留原10类及其余物种映射，总计14类，仍在4-bit类别上限内。沿用既有HP切帧速度，四类图标均加载16×16双帧（每帧4 Tile），继续使用现有VRAM布局空位；原10类及导入素材安置于 Bank `$38` 以缓解 Bank `$1C` 空间压力。**最终修正**：`ICO-5.62.55` 恢复皮卡丘家族按黄版原始方式水平镜像左侧图块，身体与尾巴在两帧中一同变化；Staryu／Ghost／Bat 和既有 Helix 继续采用非对称四图块绘制。`ICO-5.62.54` 的仅微调第二帧图案方案已被55版取代，**不是正式验收版本**。**已确认范围**：用户此前反馈另三类图标已测试、未见明显异常；皮卡丘家族最初有踏步感，后提供黄版和55版运行录像，对照后两帧轮廓与切换节奏相符，本轮决定收口。**未逐项报告**：红血／黄血各档速度、命名、交换、混搭队伍全部排列、连续进入／返回及残留等场景，不能写成全部实测通过。本次验收仅修改 `TODO.md`，不再改图像、OAM逻辑、Bank布局或游戏版本号（仍为 `ICO-5.62.55`）；AI未编译ROM或执行Git提交。

- [x] **队伍小图标专项分类定稿与后续维护边界（`ICO-5.62.63`）**：208只宝可梦的图标映射已按用户最终表格确定，采用10种一代原图、黄版皮卡丘及27种金版模板，合计**38类**，全部208只均有类别映射；本轮不再规划新的图标类别或改用 Yellow Legacy 的写实图标。分类判定结合两代实际双帧、帧序、OAM水平镜像与配色去重，遵守根目录 `RPP_DEVELOPMENT_PITFALLS.md` 的列对齐／去重规则。以后若出现独立缺陷可专项修复，但**不得在定稿清理中重新分配类别、重绘PNG或重构已验收引擎**。**这里的38类是 `ICO-5.62.63` 历史验收基线，不是当前类别总数；`ICO-5.62.81` 作为后续独立专项仅为 Scyther／Pinsir／Kabutops 新增第39类，其余205只维持定稿映射，实机验收另见本文件顶部。**已知皮卡丘源 PNG 右半与 OAM 镜像后的屏幕呈现不同，属可选独立素材维护事项，不视为本次阻塞；命名／通信交换在本轮无单独验证记录，不得写成全部通过。

- [~] **`MENU-5.62.31` 菜单显示与返回流程**：源码已记录完成与静态检查；原 TODO 中仍有运行验证事项，不能因暴风通过而自动关闭。
- [ ] **PP 道具招式列表显示 `当前PP/最大PP`**：原 TODO 明确列为后续任务，暂不改。

### 地图 / 移动类（Overworld & traversal）

- [x] **`SRF-5.62.64` — 冲浪坐骑图像分流：皮卡丘／拉普拉斯／普通图像（用户核心场景验收）**：基于 `ICO-5.62.63` 增加会冲浪的拉普拉斯作为第三种坐骑外观：对水面交互时依次优先选择会冲浪的皮卡丘、会冲浪的拉普拉斯，否则沿用其他会冲浪宝可梦的普通图像（`SeelSprite`）；通过队伍菜单指定冲浪时保留用户实际选中的宝可梦外观，不受队伍中皮卡丘优先级覆盖。地图、队伍界面返回涉及的贴图加载共用图像选择入口，复用已有拉普拉斯地图素材，不改飞天。**用户测试反馈**：用户描述五组关键场景无异常——队伍菜单分别指定三类冲浪宝可梦时图像正确；三者都有且都能冲浪时对水面交互显示皮卡丘；皮卡丘不能冲浪、拉普拉斯能冲浪时显示拉普拉斯；皮卡丘与拉普拉斯都不能冲浪、其他宝可梦能冲浪时显示普通图像；全队没有可冲浪宝可梦时水面提示平静。以上只代表用户列出的覆盖范围，不等于所有队伍排列组合均已逐项测试。**边界**：地图切换、进入队伍／摘要界面后返回的持续图像，未获得独立明确的实机复测记录，保留出现问题时的针对性回归；没有另行测试移除队员后的图像降级等特殊状态。**WRAM／空间**：`wSurfingLaprasFlag` 复用原本未命名的 `$D7AD` 字节，未增加 WRAM 总长度；保留 `wd728` bit 2 的皮卡丘标志，不将它与其他功能 bit 混用。**验收清理只更新 `TODO.md`**，不改变已测试的汇编、素材、Bank 布局、文件权限和游戏版本字符串（仍是 `SRF-5.62.64`）；完成静态符号与补丁正反向核验，但没有编译 ROM 或代替用户执行 Git 提交。
- [x] **`ICO-5.62.73` — 飞天图标分流与性别主题色（用户验收）**：飞行地图显示所选宝可梦的 16×16 Party 图标，实际飞行动画按类别选择图像；鸟类沿用原版方向／振翅贴图，其他类别使用现有金版双帧图标。飞行地图光标、实际飞行动画与 Party 小图标统一按性别显示男红／女绿，普通地图鸟 NPC 配色不变。保留原飞行路径，不新增素材、不修改图标类别映射；用户测试最终方案未报告问题。

### 道具 / 进化类（Items & evolution）

- [x] **`EVO-5.62.27`**：进化石等级门槛提示和冰之石；沿用原 TODO 的已实现记录，本次未重新测试。
- [x] **`ITEM-5.62.28`**：队伍消耗道具连续使用；沿用原 TODO 的已实现记录，本次未重新测试。

### 形态 / 培育 / 系统类（Forms, breeding & systems）

- [x] **`FORM-5.62.13`～`FORM-5.62.25`、`BRD-5.62.26`**：沿用原 TODO 已实现记录，本次未重新测试。
- [ ] **Day Care 增设 PC、满队伍时转存到 PC**：原 TODO 的待办，暂不改。

### 修复 / 审核类（Bugfix & audit）

- [x] **低血量 `Danger`／通用命中音效衔接（`SFX-5.62.141`，核心场景已实测通过）**：公共 `WaitForSoundToFinish` 遇 `Danger` 提前返回，已仅在 `MoveAnimation` 开始／结束及 `PlayApplyingAttackSound` 前的三个等待入口改为 `WaitForBattleAnimationSFX`，红血按实际 CH5～CH8 状态等待，上限 180 帧并保留 `wSFXDontWait`；正常 HP 使用原有等待，不修改 Crysaudio 全局音频接口。**用户实测**：与上一版对照确认此前确有尾音残留，141 中伏特攻击、电光和撞击等普通招式音效已恢复正常，且玩家和敌方均测过；不虚构测试次数或逐条命中结果。**仍未专项确认**：十万伏特、连续多段招式、命中／未命中／免疫、战斗动画关闭、静音与 BGM 音量 0、180 帧上限触发等。与三声渐弱低 HP 警报 TODO 不同。详见 `docs/BATTLE_DANGER_SFX.md` 和 `docs/AUDIO_HANDOFF_141.md`。
- [ ] **Leech Seed/Toxic、OHKO/Counter、连续攻击等遗留问题**：原 TODO 的候选修复；具体范围详见下方 `Legacy bugfix candidates still worth auditing`，本次不改动。
- [~] **Mimic/Disable 与 Substitute 状态防护**：沿用旧综合条目的部分实现／待审查状态；**Disable 仍未限制为只禁用目标上一回合实际使用的招式**，不应将整体的部分审查状态视为这一机制已经完成。

### 长期规划 / 待决定（Backlog & design）

- [?] **TM 是否恢复消耗制**：仍待设计决定，不因本次提交改变。
- [ ] **地区扩展、天气、特性、性格、长期 UI/引擎计划等**：见下方 `Legacy Upstream Wishlist — Audited Against Current Project`，保留原始状态和细节，暂不集中修改。

## Current RPP Roadmap

### Completed

- [x] FORM-5.62.13 through FORM-5.62.25 — regional-form instance identity work: Link Trade, Hall of Fame, Transform, Capture, Trainer/Gift/NPC Trade/Evolution, random wild encounters, Starter, Fishing, Headbutt, Static Wild/Ghost Marowak, and persistent-marker compile-time guards.
- [x] BRD-5.62.26 — Day Care / Breeding producer uses the stored parent's persistent form marker and gives the baby the same registered runtime Form when supported; otherwise it explicitly falls back to `FORM_NORMAL`.

### User-tested — Independently imported battle animations

- [x] SP-5.62.33 — Sucker Punch animation-only: two purple punch passes, Dark HIT_BIG palette and new sound events, integrated without the separate modern success/failure gate. User reports testing the move without noticing obvious problems (2026-10-08); do not interpret this as confirmation of each player/enemy/repeated-use case. The ③ battle-logic patch is still pending, and the actual Git commit remains user-controlled.
- [x] HUR-5.62.32 — Hurricane: Polished Crystal wind-column renderer, five persistent high-speed streak sets, Thunder timing, bilateral animation support and normal post-hit feedback imported in isolation from Energy Ball branch `32b5022c`. The user reports having tested this move and observed no obvious problem (2026-10-08). This closes the previously pending general runtime check based on user feedback; individual player/enemy, palette/WX restoration and follow-up move/menu cases were **not separately documented as passed**. Reopen if a reproducible issue appears. Commit message prepared; actual Git commit must be made in the user's repository.

### User-tested — Battle logic

- [x] SP-5.62.34 — Sucker Punch modern failure gate from `5ca3afb3`. Source audit of turn order, damaging-move type, action intent, failure/PP flow, Mirror Move ID, AI early decision and `$CCE0` WRAM found no definite blocking issue. **User reports runtime testing without obvious problems (2026-10-08)**; individual edge cases not separately certified. Existing general Trainer item/switch priority timing is a broader architectural limitation. ③ commit message prepared; actual Git commit remains user-controlled. Does not include ④ priority tiers.

### User-tested — Priority / Battle logic

- [x] PRI-5.62.35 — Move priority tiers imported independently from `ddddb20e`: +7 offset, ExtremeSpeed +2 > priority +1 moves > normal 0 > Counter -5. Same-tier Speed/tie logic unchanged; Roar/Whirlwind/Teleport/Bide keep priority 0 pending a full action/mechanics review. **User reports runtime testing without obvious problems (2026-10-08)**; individual edge cases are not separately certified. Source review found no definite blocking issue; Trainer AI item/switch decision timing remains a broader architectural limitation. ④ acceptance log prepared; no ROM build or Git commit by assistant.

### User-tested — Steel Wing animation

- [x] SW-5.62.37 — Steel Wing Gold/Crystal animation from `75ac4ff2`; reuse Iron Tail Metallic intro, restore display and call Wing Attack closing pairs; Steel type palette; enemy-side vertical shake and BG0 top-row cleanup. **User reports all three requested test scenarios completed without obvious problems (2026-10-08): player use, enemy use including vertical shake/top-row residue, and alternating Steel Wing / Iron Tail / Wing Attack with display restoration.** No additional frame-by-frame or rare edge-case certification is implied; acceptance log prepared, no assistant ROM build or Git commit.

### User-tested — Battle stat effects

- [x] BSE-5.62.38 — damage-triggered stat side effects and Gen I Special balance from `ff4fec55`. User reports runtime testing with no obvious issues in the tested scenarios (2026-10-08); individual edge cases were not independently certified. **Minimize remains +2 evasion / 10 PP** by user balance decision; String Shot remains -2 Speed, Amnesia +1 Special. The experimental BSE-5.62.39 +1 change is **not** applied. Future, not-next-version standalone task: Stomp and Body Slam deal 2× damage and bypass ordinary accuracy/evasion against a target that used Minimize, while keeping Fly/Dig and type-immunity exceptions; not implemented here. ⑦ acceptance log prepared; no assistant ROM build or Git commit.

### User-tested — Recoil and secondary status

- [x] RCL-5.62.41 — imported `7ecf21ce` as ⑧ recoil and Flare Blitz / Volt Tackle side effects, plus isolated Bank $34 placement repair. **User reports testing Flare Blitz from both sides and observing burn once on each side without obvious problems (2026-10-08)**. Approximately two burns across a dozen-plus attempts is observational only, not an accuracy test for the roughly 10% status chance. Recoil fraction values, Volt Tackle paralysis, direct-KO and Substitute boundaries, and Red bedroom PC interaction have no separately reported complete runtime verification. The Bank move retains the dynamic `BANK(OpenRedBedroomPC)` lookup; no new MAP/ROM build was performed by the assistant. Recoil logic and game version remain unchanged during this TODO-only acceptance. Commit message prepared; actual Git commit belongs to the user.

### User-tested — Substitute / multi-hit / recoil timing

- [x] SUB-5.62.42 — imported ⑨ (`d41f0048`) after RCL-5.62.41. **User reports having tested the feature and asks to proceed (2026-10-08), without reporting obvious problems.** No itemized pass report was supplied for both-side Substitute, multi-hit break, recoil double-KO or status penetration; do not infer that every edge case was verified. Source audit covered substitute restoration, post-damage recoil timing, both actor branches, and Bank helper symbols. ⑦/⑧ acceptance status has been reconciled in the category board; Minimize remains +2, and the Stomp / Body Slam counterplay is a future standalone item. No assistant ROM build or Git commit. ⑨ acceptance message prepared; ⑩ remains unported.

### User-tested — Volt Tackle animation / dynamic impact center

- [x] VTC-5.62.51 — ⑩ Volt Tackle animation from `c0cf8a93` plus three-size target center, first sweep from user center, middle three screen-wide alternate sweeps, and fifth sweep ending at the target center. User supplied runtime videos of both actor directions and a 51-versus-52 comparison; 52 only increased dwell by six frames (~0.1 s), with little visible gain, and user reports reverting it. **51 is the selected acceptance baseline; 52 is not included.** No new ROM build or Git commit by the assistant. Low-HP hit SFX conflict remains a separate unresolved issue, possibly cross-move; not every size/form/recoil or audio edge case has an individual pass result.

### User-confirmed — Final 208-species Party icon classification (ICO-5.62.63)

- [x] ICO-5.62.63 — final user-approved Party icon classification: 38 icon classes, 208 species mappings. The user-edited 208-row XLSX supplied the decisions across D and E columns, with a specific E-column instruction overriding an older D-column checkmark/cross. Relative to the accepted 36-class ICO-5.62.62, exactly 25 species mappings were changed and 183 were preserved; new Gold FOX (15 species) and HUMANSHAPE (Abra/Kadabra/Alakazam) two-frame assets were added. Existing SHELL, BALL and BLOB templates were reused for the other seven changes, including Kabuto/Kabutops per the specific E-column SHELL instruction while Omanyte/Omastar remain HELIX. The user reported having reviewed the result with no issues and explicitly declared this the last/final icon version; close out this icon-classification project without planning more import batches. This is feedback-based acceptance, not independent per-case proof for every HP, nickname or link-trade boundary. The closeout changes **TODO.md only**, keeping source, icon art, icon engine, permissions and in-game version ICO-5.62.63 unchanged. No assistant ROM build or Git commit.

### User-tested — Gen I / Gold Party icon refinement and deduplication (sixth batch)

- [x] ICO-5.62.62 — accepted the final 36-class revision based on ICO-5.62.61 (34 classes): import only Gold ODDISH for the Oddish/Belossom family and Gold FISH for Goldeen, Seaking, Magikarp (10 species mappings changed; other 198 unchanged). Keep Gen I FAIRY for Togepi and Clefairy family; do not retain proposed CLEFAIRY. Keep Gen I QUADRUPED for Ponyta/Rapidash; do not import EQUINE. Use legacy SNAKE for Horsea/Seadra/Kingdra; retain WATER for Chinchou/Lanturn. Earlier 38-class and 37-class drafts were superseded, not part of the accepted version. A source-and-rendered two-frame comparison identified exact duplicate pairs MON/MONSTER (frames swapped), SNAKE/SERPENT and QUADRUPED/EQUINE, and one identical FAIRY/CLEFAIRY frame. The durable cross-generation duplicate-screening procedure is recorded in root RPP_DEVELOPMENT_PITFALLS.md. User reported “没问题” after the final Togepi-to-FAIRY correction and requested formal closeout; that feedback does not establish independent test results for every animation and menu edge. **Link trading and naming have no separately documented pass.** Closeout changes only TODO.md and the root pitfalls note, not sprite mappings, PNGs, icon engine, file modes or version ICO-5.62.62. No assistant ROM build or Git commit.

### User-tested — Gen I / Gold Party icon category refinement (fifth batch)

- [x] ICO-5.62.61 — accepted four Gold 16×32 two-frame Party icon classes (SHELL, CATERPILLAR, MOTH, BLOB), refining 14 of the 208 species mappings and increasing the current class count from 30 to 34. Original Gen I HELIX stays assigned to the fossil family, while Shellder/Cloyster use the distinct Gold SHELL art; Caterpillar, Moth and Blob split select species out of broader legacy groups. The user reported having tested the three requested categories of cases: the new two-frame icons and HELIX/SHELL distinction, a mixed party with normal/SELECT slot swaps, and summary/menu returns with HP animation; no visible issue was reported and the user requested routine closeout. This records user feedback rather than independent full coverage of every extreme arrangement. **Link trading and naming have no separately documented test result.** Closeout changes TODO.md only, preserves existing 104-row / 208-species icon mapping and column alignment, icon assets, dynamic engine, swap behavior and game version ICO-5.62.61. No assistant ROM compilation or Git commit.

### User-tested — Curated Gold Party icon imports (fourth batch)

- [x] ICO-5.62.60 — accepted four Gold 16×32 two-frame Party icon templates (JIGGLYPUFF, DIGLETT, JELLYFISH, FIGHTER), covering 16 mapped Pokémon; total class count increased from 26 to 30, with the other 192 Pokémon mappings unchanged. The user reported completing the four requested test groups, including new-frame appearance, six-member mixing, normal/SELECT swaps without reported flash, menu/summary returns and HP-related animation, and asked to proceed to routine closeout. This records user feedback without asserting independently supplied frame-by-frame evidence. **Link trading and naming have no separate test report.** Closeout changes TODO.md only: the source mapping already meets the durable root alignment rules, and code, PNGs, Bank layout and game version ICO-5.62.60 remain unchanged. No assistant ROM compilation or Git commit.

### User-tested — Curated Gold Party icon imports (third batch)

- [x] ICO-5.62.59 — ten additional distinct Gold two-frame Party icon classes for 24 Pokémon (26 total classes across the project), preserving the remaining 184 species mappings and the dynamic-load/no-flash swap engine. User reports testing scenarios 1–4 (starter families, mixed six-member party, normal/SELECT swaps, and summary/menu returns) and checking the HP-related animation subset of scenario 5 without an apparent issue. **Link trading was explicitly not tested**; do not imply naming and every other edge case were independently validated. Closeout changes only TODO.md, column whitespace in data/mon_party_sprites.asm, and the durable root development pitfalls note; unchanged icon IDs, art, engine and game version ICO-5.62.59. No AI ROM build or Git commit.

### User-tested — Gold legendary Party icon imports (second batch)

- [x] ICO-5.62.58 — imported separate Gold two-frame Party icons for Lugia and Ho-Oh, extending the existing dynamic-load icon table from 14 to 16 classes. Only these two species mappings changed; existing atlas, Pikachu/Gold icon assets and the 5.62.57 swap-no-flash engine remained unchanged. After applying and testing 5.62.58, the user reported “测过了，没什么问题” (tested; no obvious issues), so this batch is closed on that feedback. Individual pass reports were not supplied for both animations, party mixes, ordinary/SELECT swaps, summary returns, naming/trade or yellow/red HP animation speeds; do not imply independent full coverage. The acceptance cleanup changes **TODO.md only**, keeps game version `ICO-5.62.58`, and involves no assistant ROM build or Git commit. Later optional icon batches and PNG normalization remain separate.

### User-tested — Dynamic Party icon engine and swap regression

- [x] ICO-5.62.57 — accepted the 5.62.56 → 5.62.57 Party icon engine refactor after user runtime tests. 5.62.56 introduced one-byte icon class IDs, ROM banked pointer lookup and per-member (up to six) two-frame tile loading, retaining the existing 14 templates and special Ball/Helix/Pikachu behavior. The user stated the requested five primary test groups had been exercised and reported a visible LCD white flash on both ordinary and SELECT party swaps. 5.62.57 retains loaded tiles in VRAM and swaps six slot-to-tile mapping bytes instead of disabling LCD; after applying the fix, the user reported the tests were fine and requested closeout. This is user feedback, not independent frame-by-frame confirmation of every edge case. No Lugia/Ho-Oh/starter icons are imported yet, and the planned approximately 28–30 types remain future work. **The closeout patch changes TODO only**, leaves game version `ICO-5.62.57`, executable source, assets and layout unchanged; no assistant ROM build or Git commit.

### User-tested — Party menu icon imports (first batch)

- [x] ICO-5.62.55 — accepted first batch of four icon templates mapped to 13 Pokémon species: Yellow Pikachu for Pikachu, Raichu, Pichu; Gold/Crystal Staryu, Ghost, and Bat for the mapped species. The user reported the three non-Pikachu templates looked fine in runtime tests. Pikachu initially looked like walking in ICO-5.62.53; the interim ICO-5.62.54 frame-only adjustment was superseded. ICO-5.62.55 restores Yellow's mirrored-left-half OAM composition while keeping Staryu/Ghost/Bat/Helix asymmetric; later Yellow and 55 runtime videos were compared for both poses and animation rhythm. This acceptance is limited to the observed footage and prior feedback; low-HP speed, trade, nickname, repeated menu transitions, sprite residue and all mixed-party cases have no separately documented complete pass. **Cleanup changes TODO only**, leaves game version `ICO-5.62.55` and source/assets untouched, with no assistant ROM build or Git commit. Later batches remain undecided; all-species icon replacement is not planned.

### User-tested — Moves / animation

- [x] AUR-5.62.36 — Aura Sphere from `e630f377`; replaced Rolling Kick at ID $1B, Special Fighting 80 power, 20 PP, Swift-style hit effect, MoveDex, six level-up entries, and separate animation/SFX. **User reports having tested both sides using the move, use against an invulnerable target, and post-animation visual residue, with no obvious problems (2026-10-08).** Special damage output, level-up learnset in gameplay, and a high-evasion accuracy case were **not tested at runtime**; source data/classification/learnset entries were statically reviewed. ⑤ acceptance log prepared; no assistant ROM compilation or Git commit.

### Completed — Evolution / Items

- [x] EVO-5.62.27 — evolution-stone Party UI reads the matching evolution entry's minimum level dynamically: below the requirement it shows `LvXX+`, at/above the requirement it shows `Able`, and actual use below the requirement gives a short level-specific no-effect message. Failed selections do not play the use sound or consume the stone and return to the same Party selector. This already covers cases such as a Lv28 Pokémon whose stone evolution requires Lv30; no separate Lv28 reminder is needed.
- [x] EVO-5.62.27 — add `ICE_STONE` in the former `$1B` unused slot, make it a normal purchasable item, and migrate Alolan Vulpix from the temporary `SUN_STONE` substitute to `ICE_STONE` at level 30.

### Completed — Party Consumables

- [x] ITEM-5.62.28 — repeatable out-of-battle Party consumables stay in the Party workflow while stock remains. HP/status medicine, vitamins/Rare Candy, PP Up, Ether/Max Ether/Elixir/Max Elixir and their berry equivalents allow another valid target after success; failed field use does not consume the item or force a return to the Bag. Single-move PP items reopen the move submenu on the previously selected move, while Elixir/Max Elixir return to the Party selector. Explicit cancel, zero remaining quantity, battle medicine use, evolution-stone success, and TM/HM teaching keep their existing exit rules. Existing class-specific success/denial audio is preserved.

### Completed in source — Party Item Menu Polish

- [x] MENU-5.62.31 — use a light Party redraw on PP-move-menu cancellation and TM/HM target retry, without the repeated palette whiteout. Clear overlaid menu tiles with BG transfer paused; keep initial Bag-to-Party graphics initialization and normal Party-to-Bag restoration.
- [x] MENU-5.62.31 — place only the PP-item move window at row 6 (lower border row 11, just above the message frame at row 12); preserve the selected move on repeat use, leave success/no-effect result text visible, and reopen the move list without replaying the question. Battle and other move-selection menus are unchanged.
- [x] MENU-5.62.31 — play `SFX_HEAL_AILMENT` on successful PP Up, sharing the existing PP-restore success path; no-effect and PP-Up-at-limit choices do not consume stock or play the success sound. PP Up continues to set its one-use flag through the `wUsingPPUp` / `wd11e` shared WRAM address.
- [~] MENU-5.62.31 — source cleanup and static patch checks completed; emulator/device verification remains for menu no-flash/complete-border cleanup, text legibility, cursor and cancellation handling, TM/HM retries, and normal PP Up counts. Do not mark runtime behavior as user-tested until these checks are performed.
- [ ] MENU-5.62.31 — when using PP Up or a PP-restoring item, show the target move's current PP and maximum PP (e.g. `current/max`) in the move-selection/confirmation UI, so the actual available PP and full PP are visible.

### Planned — Day Care

- [ ] Add a usable PC inside the Day Care.
- [ ] Allow Pokémon received from the Day Care to be sent to the PC instead of being blocked solely because the party is full. Confirm the exact receive paths (baby, withdrawn deposited Pokémon, or both) when implementing.

### Future design decisions

- [?] TM consumption model — the upstream final source already leaves TMs in the Bag after successful teaching, and the current fork retains that behavior. Reconsider later whether this project should restore consumable, single-use TMs or keep infinite-use TMs.

### Legacy bugfix candidates still worth auditing

- [ ] Leech Seed / Toxic shared damage counter interaction.
- [ ] Toxic becoming normal poison after switching.
- [ ] OHKO move behavior still tied to Speed.
- [ ] Counter edge cases involving Substitute / OHKO moves.
- [ ] Partial-trapping move turn-lock behavior.
- [ ] Whirlwind / Roar behavior in trainer battles.
- [ ] Rest interaction with stat changes caused by status conditions.
- [?] Rage issues — define the exact remaining bugs before changing behavior.
- [~] Mimic / Disable random-selection behavior — some paths were modernized, others still need a focused audit; **Disable still needs to be restricted to the opponent’s move actually used on the previous turn**.
- [ ] Multi-hit moves currently calculate damage/accuracy only for the first hit.
- [ ] Poké Ball zero-shake failure still uses the old "You missed the Pokémon!" behavior/text.
- [~] Substitute protection against status — several paths have explicit checks, but the behavior is not yet fully unified.

## Legacy Upstream Wishlist — Audited Against Current Project

This section preserves the original author's roadmap. Status markers reflect the current branch as of the BRD-5.62.26 closeout; unchecked entries are not promises that they will be implemented.

### Engine updates and New Features

- [ ] Cleanup pokered-gbc code (optimizations)
- [ ] Add support for larger tileset images, like Polished Crystal
- [ ] Add support for setting XY Flip/Palette Attributes as part of block data?
- [ ] Real-Time Clock, with Day and Night
- [ ] More modern Berry System, allowing you to plant and grow new ones instead of the Gen 2-like current system
- [ ] Expand Pokédex beyond 255 (mimic ShantyTown's "expand-dex" branch)
- [ ] Allow for more than one proper region, so Johto can happen
- [ ] Individual menu sprites for all Pokémon
- [ ] Pokégear/Pokénav equivalent
- [ ] Rematches with Trainers and Gym Leaders, no annoying phone calls
- [x] Bag has multiple pockets and more storage space
- [ ] Held items
- [ ] Special split into two stats
- [x] New available move pool, with a lot more thought put into it this time
- [ ] Weather effects in-battle
- [ ] Abilities (can enable or disable during intro)
- [ ] Natures (can enable or disable during intro)
- [x] Infinite-Use TMs — already present in the upstream final source; the current fork retains it for now, but the TM consumption model may be reconsidered later.
- [~] New Pokéball types
- [ ] Dive areas
- [ ] Battle Tower
- [ ] Battle Factory
- [ ] Battle Tent
- [ ] Pokémon World Tournement
- [~] Player customization options
- [~] Rewritten Trainer AI
- [ ] Secret Bases
- [ ] Surfing Pikachu minigame (ported from Pokeyellow)
- [ ] Ruins of Alph puzzles (waiting for PR from ShantyTown)
- [ ] Bug Catching Contest
- [x] Possibly add Forms
- [ ] Use IVs and EVs instead of DVs and Stat EXP, old DVs become a mini Personality ID
- [ ] Gain EXP on catching a Pokémon

### Bugfixes from Vanilla RB

- [ ] Leech Seed/Toxic shared damage counter
- [ ] Toxic becomes normal poison if you swap
- [ ] OHKO moves based on speed
- [x] Crits ignore stat-ups from both Pokémon
- [x] Agility negates speed-loss before boosting
- [ ] Using Counter on moves used against your Substitute
- [ ] Using Counter against OHKO moves to instakill
- [ ] Trapping moves prevent opponent doing anything
- [ ] Whirlwind and Roar do not work in trainer battles
- [ ] Rest does not undo stat changes from status afflictions you had, such as Burn
- [?] Rage issues
- [~] Mimic and Disable choosing moves at random
- [ ] Multi-hit moves deal same damage for each blow
- [ ] Make Pokéball break with zero shakes instead of "You missed the Pokémon!"
- [x] Stat-up too high making your stat roll over to ultra low values
- [~] Substitute not protecting against status
- [x] Remove badge boosts, to be more modern

### Unsorted Notes

- [ ] Pokégear/Pokénav would replace Town Map, have a VS Seeker option, a radio, etc.
- [ ] Several things in WRAM could stand to be optimized, such as event flags and map script bytes
- [ ] Hide/Show routine needs work. Probably better to redo it based on normal flags somehow, like Gen 2
- [ ] IndexToPokedex and PokedexToIndex are pointless now, and can be removed
- [ ] Remove the weird TM Name Generation routine, TM Case will work differently.
- [ ] Add even more trainer classes and cameo trainers
- [ ] Johto needs songs from Crystal, of course
- [ ] Johto should include areas that were in Polished Crystal/Christmas
- [ ] Battle Tower will be in Johto
- [ ] Pokémon World Tournement will be where Pokéathalon was in HGSS
- [ ] Battle Tent will be in Celadon
- [ ] Battle Factory will be in Johto with the Battle Tower
- [ ] Instead of CheckForHex and CheckForElectroBall, there should be one routine to calculate variable BP moves
- [ ] Once Held Items are a thing, Acrobatics needs to be variable BP, too
- [ ] Any checks for hard-coded map IDs need to also check wCurRegion when the time comes
- [~] New trainer AI will be more modular, and AI_BASIC will be at least be generically intelligent
- [ ] Pull Swimmer F data out of Beauty class list
- [ ] Consolidate Leader classes and Elite Four classes
- [ ] Maybe change Trainer DVs back to checking AI Number, instead of Trainer Class, once those are consolidated
- [ ] If Natures are disabled in intro, do not display on status screens, and use a neutral nature always
- [ ] If Abilities are disabled in intro, do not display on status screens, and use a blank ability for everyone
- [ ] EXP on catch is annoying, since a lot of variables are reused during the EXP Gain process. Will require a lot of testing.

### 地区形态追加移植（Polished Crystal）
- [~] **Polished Crystal 地区形态追加移植 18 项（5.62.112 已提交，待 ROM／实机验收）**：以 5.62.111 为基础，为 16 条原已存在 Species 的缺失地区形态与 2 条自定义进化映射登记数据、正背图、指针及进化形态继承；提交记录可见 `9030352f`，但提交不等于运行验收。完整清单在 `docs/REGIONAL_FORMS_111_INTEGRATION.md` 的“Polished Crystal 18 项追加移植”章节。
- [ ] **地区形态其余占位资料后续统一定稿**：42 条形态的 Special 五项总和与身高体重已静态复核；`5.62.113` 的 8 种首批地区形态恢复旧版验证 PAL，PC18 的 18 种形态继续保留来自 Polished Crystal 的普通／异色 PAL，伽勒尔呆呆王 PAL 尚无本轮旧版验证依据，不擅自替换。仍需定稿的包括属性、四项能力分配、捕获率／经验／成长率、升级／TM／HM／导师招式、进化条件、图鉴分类与描述、野外分布；保留伽勒尔猫老大=喵头目、洗翠玛狃拉=大狃拉的自定义进化映射，后续验证运行行为。
- [ ] **缺失 Species / 专属进化后续规划**：`CORSOLA`、`TYPHLOSION`、`QWILFISH`、`WOOPER` 基础物种不存在；`SIRFETCH_D`、`MR__RIME`、`CURSOLA`、`OVERQWIL`、`CLODSIRE` 无可复用的普通进化型，暂不移植，绝不只放图片冒充可用物种。

### 地区形态 Special 与图鉴体型校正（当前 42 条；等待 ROM 验收）
- [~] **地区形态五项总和守恒（静态完成）**：42 条中修正 18 条 Special、保留原本合规的 24 条，均遵守 `普通五项总和 - 地区形态 HP/攻击/防御/速度`；尚待游戏实际链接及对战／存档验收，不得标为运行测试通过。
- [~] **地区形态体型数据完成源码收口（Bulbapedia × Polished Crystal）**：本次实际工作区补丁包含 42 条形态，逐项重新比对其最终显示值：40 条符合 Polished Crystal 原始公制值，伽勒尔蛇纹熊／直冲熊按 Bulbapedia 验证。36 条独立体型记录各字段只覆盖与普通形态不同的值；六尾、九尾、阿罗拉喵喵、伽勒尔呆呆兽、伽勒尔蛇纹熊／直冲熊 6 条完整继承。原有六尾、九尾、喵喵、呆呆兽、直冲熊及肯泰罗共六份普通图鉴重量已精准修订；没有重复体型字段需要再次删除。静态数据校核完成，ROM／实机显示仍待验收。
- [ ] **后续验收**：运行与项目匹配的 RGBDS `make map`，检查 `$34` 描述符和 `$3E` 体型表 ROMX 容量；在 Pokédex 逐条确认 42 条地区身高／体重、Special 与形态标记、存取档及进化路径。
- [ ] **其他占位数据仍需统一定稿**：属性、捕获率／经验、成长曲线、招式／TM／导师、进化和获取方式本轮均未改动，不能因本次修正 Special/体型而视为已完成。

### S7 验收收口：图鉴详情 START／SELECT 与背图跨物种刷新（DEX-5.62.124；122/123 为未提交中间版）

- [x] **图鉴内部 Info 已实测通过（124）**：SELECT 在当前真实 Species + Form 正/背面之间切换；上下换物种时保留当前正/背方向；START 循环切换已发现形态，且在背面状态下仍能正确切换。用户本轮明确报告三种切换正常、图片区域未再出现所反馈的花屏／图块破碎。122、123 是修复过程中的中间版本，不另列为未完成的待验收功能。
- [x] **源码复核／不重复造轮子**：三种切换调用同一个 `PokedexData_RenderSwitchedEntry`；背面图复用 `UncompressMonSprite`、`LoadUncompressedSpriteData` 及既有 `vFrontPic`，只补必要的背图 7×7 tilemap 排布。124 在 49 个图块全部上传后才重新发布 PAL0；先等待白色图片 PAL 实际生效。未发现有必要在本轮重写/合并的并行渲染路径，故验收收口不改 ASM。
- [~] **朝向会话偏好（已实现、未单独获得本轮测试反馈）**：`wPokedexFacingPreference` 复用栈前空闲的 WRAMX Bank1 一个字节，bit0 为正/背，bit7 只限定内部 Info 初始图像拦截；图鉴退出后保留朝向，新开游戏／返回主菜单清为正面，不加入 SRAM。用户本轮已确认跨物种／跨形态维持朝向，未明确专项报告退出图鉴再进入或重启边界，不在此处冒称已测。
- [ ] **非阻塞边界**：日后需要时确认退出/重进图鉴的朝向偏好、返回主菜单/重启后默认正面；其他 ROM/显示模式与极端菜单跳转未逐项确认。允许正常的短暂白色遮罩，不将它与破碎图块混为一谈。无需重新做已通过的变身、捕获、PC、野外 HUD 及列表灰／彩球回归。
- [ ] **下一功能阶段**：赠送／领取、进化、通信交换等真正获得地区形态的独立 Seen／Owned 登记；大木博士地区形态研究统计；以及当前 42 条地区形态的后续玩法资料定稿和更多多形态组合边界。
- **提交状态**：上一次已提交基线依据用户 121 ZIP 导出记录为 `DEX-5.62.121 / 0ce0b967`；124 实测通过不等于本环境已执行 Commit。此次是验收清理三件套，正式日志累计跨度 `DEX-5.62.121 → DEX-5.62.124`，代码游戏版本仍为 124。

### S8 最终收口：DEX-5.62.128 / S8-004（124 后续 Party／PC 功能与捕获弹窗回退）

- [~] **Party／PC 状态页 SELECT 临时正背切换保留 126 的实现**：普通 Party、战斗 Party 与 Bill's PC 存取详情共用 `StatusScreen`；按 SELECT 使用当前物种／形态背图，UP/DOWN 换宝可梦保持朝向，退出并再次进入恢复正面。START 不新增实时动作，入场按住 START／SELECT 查看原特殊数值的入口不改。复用已有 SRAM 49-tile 缓冲／双 PAL 刷新与固定 tilemap；背图的七列在 SRAM 中预先调序，无第二套 VRAM 上传系统。
- [~] **验证范围须严格区分**：用户在 125 已实测 Party、战斗 Party、PC 存取详情的 SELECT 可以切换正背，但报告撕裂。126 针对不同图块排列加入修复；之后用户没有明确反馈“126/127 Party／PC 撕裂已消失”，因此不能标为完全验收通过。现阶段依用户要求**保留原样**，不再为了捕获弹窗修改 StatusScreen。PC「丢弃」不进入详情页，不属于正背切换测试入口。
- [x] **首次捕获自动弹出的图鉴恢复旧规则（128 源码回退）**：放弃 125 SELECT、126 自定义文本输入与 127 “A 翻页同步换背”三个实验方案，恢复 124 图鉴外部单次页面的 `TextCommandProcessor` 与原 A/B 等待，**仅显示正面，不新增 SELECT／START 正背切换**。保留 121 已实测的“每个未 Owned 的新形态首次捕获仍弹图鉴”、真实形态/资料权限与原有 208 物种计数。不是撤销 121 首次形态捕获功能。
- [x] **删除多余的捕获弹窗专用代码**：移除 `PokedexData_ExternalPageInput`、`PokedexData_ExternalAdvanceToBack`、`PokedexData_DrawExternalDescription`，还原 HOME 只接受内部图鉴的图像加载拦截；临时 WRAM 字节仅服务 Party／PC，未引入 SRAM 迁移。内部图鉴 124 的 SELECT、START、上下换物种及跨会话朝向逻辑不变。
- [ ] **后续仅在相关问题出现时专项复核**：Party／PC 在 126 更新后是否仍出现旧撕裂；另有 124 内部图鉴退出再进与重启边界尚未明确专项反馈。不要求重复旧变身、满队入箱、野外 HUD 小球和图鉴列表灰／彩球整套测试。
- [ ] **后续功能**：赠送／领取、进化、通信交换来源的地区形态 Seen／Owned 登记；大木博士地区形态研究统计；当前形态名单及属性招式进化获得方式定稿。
- **提交基线**：目前可核实最新干净 ZIP 仍为 `DEX-5.62.121 / HEAD 0ce0b96768ce88911828c0973fb8641eee84adde`；尚无更晚 Git Commit 的确认。正式本次清理日志和累计补丁按 **121→128**，增量按实际 **127→128**；若用户已经自行提交 124，应在新 ZIP／HEAD 下重建累计基线，不能伪称该提交已经确认。


### S9：DEX-5.62.129 / S9-001 — 真实获得来源的独立地区形态登记（核心实测通过）

- [x] **赠送／领取**：普通 `GivePokemon` 与显式地区形态赠送均在成功入队或直接入箱后读取实际持有形态 marker，再登记独立 Owned（同时 Seen）；箱满失败及实验室预览不登记。Starter 实际入队桥也只在加入成功后登记。
- [x] **成功进化**：继承现有最终目标形态解析／写入流程，完成 Party 记录后在同一浮动入口处理物种级图鉴标记与对应地区形态 Owned；取消进化不登记。地区目标可与原物种或原形态不同，依最终 Species 和 marker 判断。
- [x] **NPC 交换**：实测收到宝可梦后更新独立 Seen／Owned，发送及预览不登记。
- [~] **通信交换**：代码已接成功接收路径并保留通信进化入口；缺少双端实测，不将 NPC 交换结果外推。
- [x] **129 核心验收**：用户已分别验证赠送地区形态、成功进化、NPC 交换收到地区形态；三项正常。两份可撤销测试补丁均已撤销，不包含在正式源码或本次累计补丁中。
- [ ] **剩余边界**：通信交换双端、赠送失败／箱满特殊情况与更多形态组合按需专项测试；此前已通过的捕获、变身、PC、HUD 不重复要求回归。
- [ ] **仍待完成**：大木博士地区形态研究统计和地区形态数据定稿；涉及其它来源时继续基于实际成功加入的 Species + marker 扩展，禁止借预览入口自动解锁。


### S10：DEX-5.62.130 / S10-001 — 大木博士地区形态研究统计（待专项实测）

- [~] **新增地区形态研究页**：在大木博士本人和博士 PC 原有物种图鉴评价结束后，显示 `Seen / 实际登记地区形态总数` 与 `Owned / 实际登记地区形态总数`。扫描 `RegionalDexSlots` 实际条目，排除 `FORM_NORMAL`，当前预期分母 42；新登记的地区形态无需手工修改分母。
- [~] **保护原有评价**：保留 208 物种 Seen/Owned、原评价分档、名人堂专用评价缓存；Seen 与 Owned 从已经保存的独立形态位表动态读取，不新增存档字段，不重复累计同一身份。
- [ ] **最小专项测试**：新存档博士评价为 0/42、0/42；首次遇到地区形态仅 Seen 增加；成功获得后 Owned 增加，重复遇见/捕获不重复增加；普通形态不增加地区数量；博士本人和博士 PC 显示一致。名人堂保留旧流程（静态分支已保留，按需验证）。
- [ ] **仍待独立收尾**：通信交换双端实测、地区形态名单与属性/招式/进化/分布等玩法资料定稿；129 已实测的获得渠道与旧图鉴/变身/PC 功能无须整套重测。
- **状态**：130 已制作源码补丁，未执行 ROM 编译、游戏实测、Git Commit/Push；待专项验收，不提前生成提交日志。


### S10：DEX-5.62.131 / S10-002 — 地区研究页数字后死机修复（待专项实测）

- [~] **修复显示中断**：130 版显示 `Seen: 0/42` 后，`TX_NUM` 后的 `para` 被当成文本命令解析；研究页两处数字命令结束后补 `text ""`，让 `Owned` 分段和结尾 `done` 都按字符串控制码处理。不修改计数逻辑、ROM Bank 规划、形态身份或存档。
- [ ] **最小复测**：新档分别通过大木博士本人和 PC 打开评价，确认 `Seen: 0/42` 后能翻至 `Owned: 0/42` 并正常关闭；随后使地区形态 Seen/Owned 各增加一次，再确认数字正确、重复不加，普通形态不改变地区计数。名人堂旧路径按需检查。
- **状态**：131 仅完成源码修复与静态/补丁检查；ROM 链接和游戏实测仍由用户完成，不将此次修复提前标为通过，不生成提交日志。


### S10：DEX-5.62.131 / S10-DOC-003 — 地区研究页定版清理（本轮仅维护文档）

- [x] **用户确认以现有 131 方案定稿**：保留大木博士原 208 物种评价后追加的地区研究页；研究数量依据形态身份表中排除普通形态后的 42 条地区形态动态统计。131 仅在两处 `TX_NUM` 后补 `text ""`，不改变统计、固定身份、存档、名人堂与既有交换／捕获流程。**这里的“定稿”是版本方案收口，并非用户已确认 131 能正常运行。**
- [~] **研究页实际运行状态**：130 的 `REGIONAL FORMS / Seen: 0/42` 后卡住已有用户截图；131 已做文本命令层面的修复与静态／补丁检查，但尚未收到 131 编译、实际翻到 `Owned` 或完整退出的反馈；博士本人、博士 PC 与独立计数仍为待验。不得把 130 的出错现场当作 131 修复通过的证据。
- [ ] **最小后续验证**：新档在博士本人和博士 PC 两个入口分别确认原评价正常、`Seen: 0/42`、`Owned: 0/42`、退出对话；地区形态仅见过时 Seen 增加、获得时 Owned 增加、重复不加，普通形态不加。ROM 链接、地图 Bank 空间、另一游戏版本及名人堂边界未获本轮新验收；已有 129 赠送／进化／NPC 交换与旧功能无须无故重测。
- [ ] **与本版定稿分开的后续专项**：通信交换双端及部分 Party／PC 显示边界测试；42 种地区形态属性、招式、进化、野外分布、获得方式与图鉴资料仍按各自旧 TODO 继续，不写成已经完成。
- **交付／Git 基线**：本次 S10-DOC-003 仅改 4 份维护文档，游戏版本仍 `DEX-5.62.131`；增量基于已交付 S10-002 的 131 文件状态，全量基于用户本轮上传的实际 130 工作区 ZIP。导出记录显示最新 Git HEAD 为 `88853cab`／`DEX-5.62.129`，因此拟提交日志覆盖 **129→131** 而非 131→131；未自行编译 ROM、Commit 或 Push。

## BATTLE-5.62.200T — 临时测试历史已于正式 200 清理

- 200T-001～004 的过程、用户受测证据与未覆盖边界已合并至 `docs/BATTLE_200_FINAL_RULES_AND_ROUND2.md`；测试源代码与 7 号道路特殊遭遇均不属正式版本。
- 200T-004 的平局归物理不是“只改测试数据”：它已成为正式 200 Dynamic Spark 判类规则；而其他尚未确认的反击体验改动仍留第二轮讨论。

## TEXT-5.62.205 — 逐字显示优先刷新（205 验收清理）

- [x] **保留 205 局部刷新优化**：`PrintLetterDelay` 仅在当前图块指针位于下方六行且 BG 自动传输开启时提出一次性请求；`GbcPrepareVBlank` 在预备窗口调色板之前选择下方区域，遇到待消费的调色板批次、静态全屏调色板重建或传输关闭则使用原刷新次序。没有导入 Polished Crystal 字库，也没有重写 `ScrollTextUpOneLine`。
- [x] **文字速度与存档不变**：Fast=即时、Normal=1 帧、Slow=3 帧（沿用项目现有选项），未改变 `wOptions`、字库、滚行等待、SRAM。此前仅调整 Slow 为 2 帧的候选已由用户撤销，不属于正式 205。
- [x] **用户实际录像范围**：用户提供 205 NPC 对话录像，并将 204 和 PC 的录屏用作观感对照；205 Normal 的逐字显示更连续，205 Slow 仍为原 3 帧节奏。录像未见明显 NPC 对话花屏；这不是战斗、菜单、两种 ROM 或全部显示场景的全面验收。
- [x] **独立构建版本管理**：正式 Red/Blue 显示 `TEXT-5.62.205`；编译期可选战斗测试 ROM 仍显示 `B-5.62.204-T09`。常规功能版本升级不自动修改测试设施代号；`Makefile` 的独立测试对象和入口不变。
- [ ] **本地剩余最小测试**：正式 Red/Blue 构建与链接、查看新 MAP；Normal/Slow 的普通 NPC 长对话，战斗文字与 HP/HUD 更新、对话结束返回地图时的调色板，以及必要时独立测试 ROM 的旧标签检查。特别观察其他屏幕区域短暂延后刷新的可能。AI 未构建 ROM、未进行 Git Commit/Push。
- **准确 Git 基线**：最新用户提供的干净 `BATTLE-5.62.204` HEAD `6d87cab1c761adae4ff58d4fcaa997fd4a502296` → 当前清理 `TEXT-5.62.205`；清理增量以前次已应用的 `TEXT-205-001` 为前置，基线全量从 204 HEAD 出发，两者互斥。详见 `docs/TEXT_REFRESH_205_REVIEW.md`。

## IMP-5.62.206 / 独立测试模式 T10（待编译／待实机验收）
- 在已交付 `IMP-5.62.206` 变身者功能上，向测试 ROM 保留的 Pokey 菜单增加 `IMPOSTER TEST` 子菜单，共 15 个选场景；原 01 SPIKE／02 2-HIT／03 RECOIL 保留。只在 `BATTLE_TEST_BUILD` 生效；正式 ROM 仍为 `IMP-5.62.206`，测试 ROM 标记 `I-5.62.206-T10`。
- 覆盖玩家／敌方首发，玩家中途换入、昏厥补位，训练师敌方主动换出／昏厥补位，Fly／Dig 失败，百变怪对百变怪，离场重新入场，双倒延迟，替身、敌方换目标不重触发、阿罗拉形态、扩展技能身份和失败后手动 Transform。具体操作与预期详见 `docs/BATTLE_TEST_BUILD.md`。
- 待验：用户本地 `make red/blue/test-red/test-blue` 编译与 MAP/Bank、Pokey 四选一及五页菜单的 A/B 行为、15 场景逐项录像。场景 05 的主动换人是脚本在回合边界调用真正的 SwitchEnemyMon，不证明 AI 回合决策；双倒必须自然发生才证明延迟变身。
- 本轮没有修改正式 ROM 战斗逻辑、存档结构或地图对象。禁止把静态审查／补丁回放写为 ROM／手机 PASS；正式验收清理和 Git 日志等用户要求后再进行。


## IMP-5.62.206 / 独立测试模式 T11 — 修复敌方换人及合并场景（待验）
- 用户实机指出 T10-05 在回合边界插入 `SwitchEnemyMon`，使敌方该回合可能再次行动。修正仅在测试 ROM 的原生 `TrainerAI` 行动槽进行一次性强制换人，以 Carry 标志结束敌方行动；**没有修改正式版训练师换人后手优先级，也没有修改变身核心或旧三组测试**。
- **合并**：03 玩家换入+原 09 离场再入场；06 Fly 自动失败+原 15 失败后手动 Transform；12 原不重触发+双方同回合换人。合并后仍保留五页共 15 个菜单位置。
- **新增/替换**：09 敌方百变怪在训练师首发倒下后补位；12 双方同回合换人、变成换人前目标并不重复触发；15 Juggler 的原生随机 `SwitchOutAI` 对照场景。05 第二回合在敌方行动槽执行换人，不再于 round boundary 直接换；06 第三回合把敌方 Fly 改为 Splash 以方便可靠的手动重试。
- 测试版标记 `I-5.62.206-T11`；正式 ROM 仍为 `IMP-5.62.206`。具体操作、可重复与随机测试的区分见 `docs/BATTLE_TEST_BUILD.md` 的 T11 节。开发期未编译/未实机回测/未生成 Git 提交日志。新增补丁须由用户选择增量或基线全量之一应用，不能叠加。


## IMP-5.62.207 / TEST-207-T12（开发待验，2026-10-24）

- 测试场景菜单改为 `PAGE x/5`：仅在 PAGE 行左右切页，翻页后光标固定在该行；A 不触发，B 取消；仍是 15 项测试，不改队伍/场景配置与旧三组。
- 入场自动变身在 Battle Animation ON 时播放原版 Transform 的完整动画（包括图形替换），并恢复此前保存的动画 ID/type；动画 OFF 仍直接重绘。手动 Transform、失败判定、出招/换人行动优先级、Party 永久技能数据不变。
- 正式 ROM 版本 `IMP-5.62.207`；测试 ROM 缩短为 `TEST-207-T12`；仍需要用户本地构建及 ROM 实测。
- 用户已反馈 T11 重点抽查约四项没有观察到异常；15 原生 AI 换人通过快速存读档看到了概率触发，无需反复重复；本反馈不能扩大为全部 15 项及 T12 已验收。
- 最小后续测试：菜单跨页与取消、01 入场新动画、05 或 12 的换入回合、按需动画关闭路径。更多历史场景无回归信号不强制重测。


## TEST-207-T13 — Pokey 精简对话与测试二级菜单（待用户快速验收）

- [~] **Pokey 单条提示**：从公共 `GameVersionText` 获取版本并显示 `Ver: TEST-207-T13` / `Start test?`，保留 YES/NO，删除第二段操作提示与旧 RUN-009 警告；测试版以外的 NPC 和菜单均不改变。
- [~] **按用途分成两大类**：一级仅有 `SUBSTITUTE TEST`（二级为原 01 SPIKE、02 2-HIT、03 RECOIL）和 `IMPOSTER TEST`（原 15 场景五页）。保留所有 18 项测试的队伍/触发设置与既有 PAGE 左右翻页行为。
- [ ] **最小设备复测**：YES/NO、两个子菜单选择和取消、替身一项入场、IMPOSTER 首/末页翻页与退出。既有变身者场景已由用户专项观察且无新异常，本轮不要求再逐一重跑 15 项。
- **交付状态**：相对于用户上传的准确 T12 Worktree 生成增量；经 ZIP 内 `current_worktree.patch` 反向还原的干净 `TEXT-5.62.205 / HEAD 54b4eb5f` 生成累计全量。无 ROM 编译/链接/手机实测，无 Git Commit/Push；本轮不生成提交日志。正式 ROM 仍 `IMP-5.62.207`。


## TEST-208 / T14 测试入口优化（待用户验收）

- Pokey 去掉旧的 `Start test?` YES/NO；对话直接进入两个分类。删除 `TX_RAM wBuffer` 显示版本的脆弱路径，菜单底部以 ROM0 的 GameVersionText 绘制简短 `TEST-208`。
- 重构菜单的屏幕缓存与退栈：`SUBSTITUTE TEST` / `IMPOSTER TEST` 按 B 回 `SELECT TEST`，顶层 B 才退出；首次进入无 PAGE 菜单选第 1 项，有 PAGE 菜单选 PAGE，左右翻页保留 PAGE 光标。
- 新增 `docs/IMPOSTER_TEST_REVIEW_T14.md`，归档变身者规则、原 3 项替身交互、15 个当前场景、用户测试范围与独立审查要点。所有战斗夹具和正式 ROM 的变身核心保持不变。
- 本轮未由 AI 编译 / 链接 ROM，也没有运行设备验证。用户已反馈原有场景未发现明显问题，本次只需最小菜单回归，尤其取消与版本显示。不得提前视为 Git Commit。

## IMP-5.62.207 / 变身者入场自动变身功能（正式收口，2026-10-24）

- [x] **入场触发**：玩家与敌方百变怪在首发、主动换入及昏厥补位时自动尝试变身；双方同时昏厥时等待新敌方目标装载后再消费一次性挂起标志。
- [x] **复用原 Transform 核心**：沿用当前项目对 Fly/Dig 半无敌目标、施术者已变身、同物种且同运行时形态的失败判定；自动失败静默返回，不额外消耗行动或 Transform PP。成功复制战斗临时数据与扩展招式身份，不覆写 Party 永久四招或目标 HP。
- [x] **动画**：Battle Animation 开启时播放原生 Transform 动画；关闭时直接重绘。手动 Transform 保留原执行路径。
- [x] **用户验收反馈**：用户确认本轮相关功能与测试场景均已测过，未发现问题。该记录是用户反馈，不代表本环境另行编译／链接 ROM 或完成联机验收。
- [ ] **独立边界**：联机双端同步、异常战斗终止后再开战、全部地区形态组合及正式／测试 Red/Blue 的新 MAP 尚无本环境构建证据；只在出现相关需求或风险时专项复核，不重复要求已验收的 18 个场景。
- **提交拆分**：本功能单独作为第一笔 `feat(battle)`；测试 ROM、NPC、场景夹具和分页菜单属于第二笔测试工具提交。正式 ROM 版本 `TEXT-5.62.205 -> IMP-5.62.207`。

## TEST-209 / T15 测试工具与菜单验收收口（2026-10-24）

- [x] **测试菜单**：Pokey 直接进入 `SELECT TEST`；主菜单为 `SUBSTITUTE TEST` 与 `IMPOSTER TEST` 两类；子菜单 B 返回上层，根菜单 B 返回地图。IMPOSTER 五页各三项，进入时默认 PAGE，左右翻页保持 PAGE 光标，边界不循环；底部版本直接显示 `TEST-209`。
- [x] **BG 状态恢复**：进入时保存 `H_AUTOBGTRANSFERENABLED` 原值；退出或确认场景时恢复地图、等待一帧完成图块传输，再恢复原开关值，避免原值为 0 时遗留菜单图块。
- [x] **场景与用户反馈**：保留 3 项 Substitute + 15 项 Imposter 场景。用户确认相关功能与测试场景均已测过、未发现问题；无需再次逐项重跑。
- [x] **风险复核**：动画脚本标志由原生 `MoveAnimation` 结束流程清理；双倒挂起标志有玩家新入场重置及敌方有效补位消费。没有静态证据要求改动正式战斗核心。
- [ ] **工程验证边界**：本环境未执行 ROM 编译／链接或生成新 MAP；联机双端、异常战斗终止后的新战斗仍需有针对性时再专项检查。
- **提交拆分**：测试 NPC、场景夹具、分页菜单、测试版本标签及相关说明独立作为第二笔 `test(battle)`；依赖第一笔 `feat(battle)` 的正式变身者运行时功能。


## TRF-5.62.208 / TEST-210 — 手动 Transform 成功后同回合执行复制招式（开发待验）

- [x] **续执行入口**：`TransformEffect` 改为短 `callab` 网关，浮动 ROMX 的 `TransformMoveFollowup_` 调用共享 `TransformEffect_`。成功结果通过 Carry 明确返回；网关按 Mimic 的 HL continuation 约定清理 `JumpMoveEffect` 临时返回地址，再进入 `CheckIfPlayerNeedsToChargeUp` / `CheckIfEnemyNeedsToChargeUp`，不重跑行动前状态检查，也不新建第二个回合。
- [x] **玩家选招**：直接手动使用 Transform 并成功时，打开普通四招菜单；选择复制招式后重载当前招式数据，执行该招的正常 PP、EXT 身份、蓄力、命中、MoveDex 与伤害流程。该早期版本原本按 B 会错误执行高亮槽，已由 TEST-215/type 3 修复（按 B 无效）。Link 不能二次交换招式槽，因此沿用 Mimic 的同步方式，从复制槽随机选择。
- [x] **敌方选招**：敌方直接手动使用 Transform 并成功后，从新复制的敌方四槽随机选取一个非空招式；若列表异常全空则回退 Struggle。失败、已经变身、同物种同运行时形态、Fly/Dig 半无敌目标均不进入续执行。
- [x] **边界隔离**：只对根行动本身为 Transform 的成功分支追加复制招式；由 Mirror Move／Metronome 等派生出来的 Transform 不额外生成第二层行动。自动 Imposter 继续直接调用 `TransformEffect_`，不会弹出手动选招菜单或额外攻击。
- [x] **版本／文档**：正式 ROM 标记 `TRF-5.62.208`，测试 ROM 标记 `TEST-210`。既有 3 项 Substitute + 15 项 Imposter 测试夹具不变；本轮不新增菜单场景。详细规则与最小测试步骤见 `docs/TRANSFORM_SAME_TURN_FOLLOWUP.md`。
- [ ] **用户最小验收**：玩家侧成功 Transform 后选择复制招式并在同一行动中执行；敌方可用 Transform 的非 Ditto 使用者成功后会随机执行复制招式；Fly/Dig 失败不追加招式；确认 Transform PP 与复制招式临时 PP 各扣一次、扩展招式身份正确。Battle Animation ON/OFF、红蓝双构建、Link 双端同步与新 MAP 尚未由本环境验证。
- **Git 基线**：本轮用户上传 ZIP 声明分支 `常规功能备份`、干净 HEAD `eae3e430690fcc798083887b09d44e891717cead` / `TEST-209`；本阶段只制作开发补丁，不 Commit/Push、不生成正式提交日志。

## TEST-213 / TRF-5.62.208 — 手动 Transform 续招菜单旧屏缓存修补（待用户 ROM 验证）

- [x] 已阅读用户 `06测三次.mp4`；录像显示在 06 后续回合玩家成功 Transform 并选择复制招式时，已落地的敌方精灵图像可能被异常抹除。这与 Fly/Dig 正常隐藏**施招者自身**的动画不同。
- [x] 静态定位：回合开头 `SaveScreenTilesToBuffer1` 可能保存敌方升空后的隐藏图；原 `TransformMoveFollowup_` 第二选招菜单结束后无条件恢复旧 `wTileMapBackup`。候选改为第二选招前刷新当前画面缓存，不改 Fly/Dig 状态和战斗行动。
- [x] 测试版本 `TEST-212 → TEST-213`；15 项测试矩阵不变，正式 `TRF-5.62.208` 不变。
- [ ] TEST-213 ROM 尚未由项目所有者本地编译/验证。优先重跑 06 后续成功 Transform→Fly 并看比雕图像、01 普通续招、08 正常蓄力；必要时 07 的 Dig 恢复。检查正式/测试 Red/Blue MAP/Bank 和动画开关。
- [ ] 本轮不代表 15 项均完成验收；不执行 Git Commit/Push。
- **增量基线**：准确已交付 `TEST-212` 开发候选；累计全量基线：`eae3e430690fcc798083887b09d44e891717cead`（此前 ZIP 导出的 HEAD），不得互叠补丁。


## TEST-214 / TRF-5.62.208 — 复杂交互优先的双向 Transform 矩阵（开发待验）

- [x] **以实际 TEST-213 工作区为起点重排测试菜单**：保留 TEST-213 玩家第二次选招菜单前刷新画面缓存的修复；15 个槽位改为玩家／敌方后手 Fly、Dig、EXT、KO、Substitute 镜像，另保留 PP/RESTORE、真实双方同回合换入、双方同物种变身失败及两项先手蓄力对照。简单的先手／后手 Tackle 场景不再占用主菜单。
- [x] **组合时序**：01–04 串联第一次对半无敌目标变身失败、下一回合目标完成 Fly/Dig、后手 Transform 成功并执行复制的 Fly/Dig；05/06、07/08、09/10 分别覆盖 EXT、KO、Substitute 的玩家／敌方镜像。
- [x] **测试构建隔离**：敌方固定槽 1 仅用于 `$41/$43/$45/$47/$49/$4e`，并要求 `wTestSuiteGuard == $5a`；玩家 EXT 身份只在 `$45` 回合边界注入。正式 Transform／Imposter 算法、正式版本 `TRF-5.62.208`、Party/SRAM/WRAM 布局与原 3 项 Substitute 测试不改。测试标签为 `TEST-214`。
- [ ] **最小验收顺序**：先测 01 的敌方图像缓存问题，再测 02 镜像；之后 03/04 Dig、05/06 EXT、09/10 Substitute；最后检查 07/08 KO、11 PP/RESTORE、12 AUTO-BIDIR、13 BOTH-FAIL 和 14/15 蓄力对照。所有结果仍待用户本地编译／实测。
- **基线与交付**：用户上传 `TEST-213.zip` 的导出 HEAD 为 `eae3e430690fcc798083887b09d44e891717cead`，源码为包含未提交 Worktree Patch 的实际工作区。增量补丁以该 ZIP 的 TEST-213 工作区为前置；累计全量从该 HEAD 重建并包含此前工作区差异与 TEST-214。两份补丁只择一应用，不叠加。
- **验证边界**：AI 不编译／链接 ROM、不生成 MAP、不执行 Git Commit/Push。静态源码与补丁回放不等于 TEST-214 游戏通过；15 项均未验收。


## 城都 P2-003（REG-5.62.214 / TEST-221，待构建及实机）

- [x] 已在旧保存块复用六个未引用地址，建立地区+稳定 local ID 当前/前一地图身份和双 magic 校验；不占地区图鉴 $D7A4–$D7AB。
- [x] 新游戏初始化、旧存档读档归一化、存档前同步地区身份；当前仍 0 张已激活城都地图。
- [ ] 用户四目标可用构建及 MAP 验证，重点 ROM0、Bank $41、存档块地址不变。
- [ ] 最小实机：既有旧档继续→存档→读档；新游戏初始化→存档→读档。
- [ ] 首次城都地图正式接入前增加地图切换的地区身份提交点及失效回退；不得用旧城都编号别名。
