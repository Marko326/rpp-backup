## FIX-5.62.282｜CLEAN｜已验收反馈及今后门房防漏检

- 以用户手机结论为准：.281 的34号路北门房两格合法Warp地毯横移/骑车误挡已解决；.282 的续播漏洞在**骑行且关闭 Bike Song**时出现并已由用户确认解决；普通步行原本正常，后续报告不得泛化成步行音乐重启。
- 门房审核必须同时检查：来源地图选曲、Warp 调用是否强制重开同曲、`CompareMapMusicBankWithCurrentBank` 返回 Carry、安全地毯 Warp 与封锁表不能重叠、两格横向骑行许可、合法向下进门、黑边/邻图预览、未开放边界。工具审计要有故障注入，真实音轨进度仍需设备验证。
- 2026-10-31 用户提供的 .282 Red/Blue MAP 显示 ROM0 各余84B；未来新增游戏 ROM0 内容后必须重新按新MAP确认余量≥64B。下一批从 Goldenrod 北门房/Route35 开始，不擅自提前开放。

## FIX-5.62.282｜城都五门房音乐继承与骑行不重播防回归

- `MUS-259` 已检查5座门房的有效来源及骑行，但仅核对比较指令的存在，无法发现桔梗市来源落入桐树林南门房分支；现新增实际分支流向的正反向检查。
- `home/audio.asm` 的空 `CompareMapMusicBankWithCurrentBank` 曾泄漏 Bike Song Off 时 `cp $2` 的 Carry，导致相同歌曲仍重新请求；此函数必须无条件清除 Carry，且保留 `wLastMusicSoundID` 同曲直接返回的缓存。
- 每新增一座活动门房，必须登记两侧源 ID 并经 `johto_gate_music_bike_audit.py` 逐一检查 RBY/GSC 最终选择、普通 Warp 不强制重播、Bike Song Off Carry 及骑车许可；不能只对照素材和歌号。
- 本版本仍需用户本机新 ROM/MAP 和播放进度实测，不能把离线审计记为音频设备验收。

## FIX-5.62.281｜34号路门房地毯横向通行与骑行回归

修复两格已注册 Warp 误列入未开放门槛黑名单；增加活动南线Warp与封锁坐标不相交的自动审计。待新Red/Blue ROM、MAP和手机左右横穿／骑行／出入门房验收。

## FIX-5.62.280｜合并工作区的全项目静态复核及正式版本校正（开发候选）

- **版本实际生效**：`data/game_version.asm` 普通版从 `FIX-5.62.276` 修正为 `FIX-5.62.280`，覆盖已经累积的 `.278` 工具及 `.279` 游戏修复；测试 ROM 专用 `TEST-231` 不变。字符串字节长度不变、无新 ROM0 指令，不以旧 MAP 宣称新构建验收。
- **完整开发候选**：以 `.276` 用户实际 Worktree ＋ `.278` ＋ `.279` 已交付内容逐层合并；森林成熟碰撞/Cut/Surf/昼夜配色、跳崖输入清理、桧皮镇西侧补图、34号路四列通行及满金市北部预览均保持原状。
- **飞行解锁防回归**：新增 `tools/johto_fly_visit_audit_280.py` 并接入原城都迁移总审计；交叉核对11个稳定飞行目的地的独立事件、实际地图注册、已访问事件位、飞行切换二次检查和 Gold 原始安全落点。当前五座活动城镇对应真实可走落点；另六座仍预留，不因为地名可浏览而自动解锁。加入错误注入和实际版本/项目标题一致性测试。
- **复核范围**：按 Gold 原图执行全部活动地图的 Surf/Cut/跳崖、南线空间水格、森林成熟模块和昼夜图色、门房音乐/骑车、地点名牌及 Town Map、Route34/Goldenrod 边界、原始编译前符号和三条表长 ASSERT。此处均为**离线审计**，不是模拟器执行或设备验证；未开放室内/Route35 不擅自解锁。
- **交付边界**：开发阶段只给两份互斥 `.patch`，增量以用户本轮上传的 `.276` **实际未提交 Worktree** 为前置，已累计包含 `.278`、`.279` 和本轮 `.280`（无需另外打旧补丁）；累计全量以导出记录确认且通过历史补丁逆推的 `b4148ccb783bdf734d621d0b8e8419f24ffe72da` 为前置。不得叠加；无 ROM 编译、链接、新 MAP 或 Git Commit/Push。ROM0 的 `.276` MAP 只作旧证据，本地正式新构建必须确认不少于64B。

## FIX-279｜有原版资源、静态连通不代表地图边缘正确显示／通行

- `Route34.runtime.blk` 与 Gold 逐字节相同仍可能缺树：地图**Object border** 写错 `$00`（原版 `$05`）会让屏外树墙空白，必须把对象边界块与 Gold map attributes 纳入审计。
- `BFS` 证明地图内路径存在，不等于真实过图通道开放：Route34→Goldenrod 旧边界仅放行2列，成熟版是相邻4列，双侧必须同步对照成熟分支及角色网格。
- 城市北端尚未开放 Route35，仍需三行 Gold 底部渲染**缓冲图**，边框修复必须走 `LoadTileBlockMap` 后置钩子，不可把预览图块当成新可走地图/连接；严禁为了新增补图再挤 ROM0 第二个远调用。
- 当前用户实机图片比 TOOL-278 的静态通过优先级更高；修好源码并补负例仍需用户 ROM/手机再次验收。

## TOOL-5.62.277｜根据当前项目修订过时审计（仅工具开发候选）

- 本轮仅更新 `tools/` 审计与测试，不修改游戏运行 ASM、Bank、地图、PNG、`jp`、正式版本 `FIX-5.62.276` 或 `TEST-231`。
- 地名：同一条件守卫允许 RGBDS 的 `jp nz` 或 `jr nz`；保留 `$FC` + Johto 地区 + stable ID 三重限制，并通过破坏条件跳转的负向测试。
- 门口：不再要求已迁到 ROMX 的吉花市 Y10/X25/UP 入口仍写在 ROM0；改为检查 `CollisionCheckOnLand` 到 `JohtoPilotGateDoorApproachAllowed` / `JohtoOverworldSouthLandDecision` 的调用、E 返回值和 ROMX 内的精确坐标／方向限制。负向测试修改 X25 必须失败。
- ROM0：随包 MAP 出自更早的 `.270`，26B 不能证明当前 `.276` 已完成链接；离线源码审计将不足64B作为**显式警告**，而 `--require-fresh-map` 必须继续失败，绝不降低64B安全阈值。整合审计输出保留容量警告，静态通过不代表 ROM 构建验收。
- 交付仅两份互斥开发补丁 ZIP（`.276` Worktree 增量、确认 `b4148ccb` 基线累计全量）；不自行链接 ROM，不 Commit/Push。用户实测森林和桧皮镇门房外景已正常，其他功能不借此扩大验收范围。

## FIX-5.62.276｜修复成熟森林运行脚本的链接符号（开发候选）

- 用户本机 Red 构建在 `rgblink` 阶段出现3处 `Unknown symbol`，都来自 `engine/johto_ilex_mature_runtime_275.asm`：`JOHTO_ILEX_FOREST_WIDTH` 一处、`JOHTO_AZALEA_TOWN_WIDTH` 两处；不是 ROM0 / JR 错误。
- 以项目实际定义的 `JOHTO_SOUTH_ILEXFOREST_WIDTH=15` 和 `JOHTO_SOUTH_AZALEATOWN_WIDTH=20` 替换引用，计算方式与运行地图大小不变；不新增 ROM0 逻辑、PNG、2bpp、Bank 或存档字段，不修改用户已验收的 `jp`。
- 扩展成熟复用审计：解析真正 `DEF/EQU` 宽度定义，拒绝缺失的全局常量；增加两种错误名故障注入测试。原有本地标签预检不检查这类全局符号，之前的“静态通过”不能替代链接。 同时把南线几何检查器的游戏版本硬编码白名单调整为按21张活动地图及ROMX屋顶阶段校验，避免每次升版本后误报。
- 本机须重新 `make red`，再跑蓝版及最新 MAP（ROM0 安全余量至少64B），同时复测森林 Cut/Surf 和桧皮镇左侧补图。按项目要求未由 AI 自行链接 ROM／提交 Git；`.275→.276` 增量和确认 HEAD→`.276` 累计全量互斥，二选一。

## FIX-275｜不要用 Gold 角色网格代替成熟森林运行状态机

- 旧NPC分支的地图与当前稳定ID相同，`JohtoIlexForestCanStepAhead`＋216字节掩码可以移植；但当前旧 Gold role table 的 0/1/2 只是地图数据证明，不能替代成熟碰撞引擎。
- `cp $2d / ret nz` 对原始 `$0f` 保留Carry=1，导致“未砍树”误判为清除状态；负向返回必须显式 `and a` 清除Carry。
- Surf 水格判断不等于能上岸；森林 `.tilecoll` 只有 `$ff`，安全岸线要复用森林真实陆地碰撞的 Carry 语义。若只开水格，不开放合法陆地，玩家会被困水面。
- 桧皮镇西侧房屋缺图属于地图外围3区块缓冲区，不是门房室内PNG。旧 GATE-202 直接提供 `PatchJohtoAzaleaWestGateBorder` 两个室外补图块，必须在 `LoadTileBlockMap` 完成之后调用。
- 不准将 `.2bpp` 生成物纳入补丁；无新 MAP 不能宣称ROM0≥64B。多批回归必须以成熟运行代码、用户已验收画面作为行为基线，而不只是转换脚本输出。

## FIX-5.62.274｜南线跳崖模拟输入结束后恢复碰撞（开发候选）

- 用户手机视频证实：部分跳崖落地后仍可走进树林，继而出现白屏／重启。定位两条未同步的生命周期：`_HandleMidJump` 结束时释放 `wd736.6` 和 `wd730.7`，但未清理 `wSimulatedJoypadStatesIndex`；`CollisionCheckOnLand` 又以残留的索引单独绕过碰撞。
- 修复：仅在跳跃动画且 `wWalkCounter=0` 之后同时清空两个模拟按键槽、索引、临时字段及忽略按键状态；ROM0 的普通陆地绕碰撞条件改查 `wd730.7` 活动标志（`LD A,[wd730]; RLCA; JP C`），不再看过期索引。这段调用仍占7字节，不增加 ROM0 使用量。保留两步跳崖队列、既有精确落点、Gold 源图与成熟森林图块、玩家修复的 `jp`。
- 33号道路／桧皮镇／桐树林共用跳崖动画，因此三者都需要实机回归；动画结束与额外碰撞跳过是源码可证实的错误路径，视频最后重启的精确 CPU 触发点尚不能从静态源码断言。
- 门房外侧：本次对照 Gold `AzaleaTown.blk`、`johto_modern_metatiles.bin` 与 `johto_modern.png` 后，当前运行图与原版字节一致。此前 `.273` 只改了室内门房资源，未解决室外画面；当前仍**不能宣称室外左侧缺图已修复**，须由用户在视频/标注中确认实际异常块坐标或通过显存截图进一步定位，不准任意删改 Gold 林地。
- 新增跳跃状态清理审计、负向故障注入，并接入城都迁移主审计。用户本机仍需编译正式 ROM、检查最新 MAP 的 ROM0 ≥64B，并验证持续按方向、B键、骑车、落地后树林阻挡与 Save/Continue；静态通过不等于手机验收。开发阶段只交一个 ZIP 两份互斥 `.patch`，不提交 Git、不替用户编译 ROM。

## FIX-5.62.273｜南线跳崖落点与桐树林门房成熟资源修复（开发候选）

- 参考 NPC-5.62.243 的 `ILEX-5.62.217`：保留共用 `HandleLedges`、两次模拟输入和 B 键跳跃保护，Route33／桧皮镇使用原有合法方向列表，桐树林使用已验收的图块对。
- 当前主线在 `CollisionCheckOnLand` 的 `wd736.6` 跳跃路径跳过通常碰撞；专门增加精确 Gold **第二格落点**保护，阻止跳跃状态尚未释放时再次启动第三格移动。三处地图的27个有向跳点纳入专项来源核对，不放宽正常走墙，也不改关都／旧路线的移动队列。
- 两座桐树林门房回用成熟的 `JOHTO_GATE` 图块集、压缩 5x4 地图区块和 `$0d` 黑色边框。原 Gold `.runtime.blk` 保留作审计源，新增 `.mature.blk` 仅供实际门房运行；不覆盖 Gold 原始地图，也不添加构建产物 `.2bpp`。
- 本轮只作静态源码修复和候选交付，不自行编译 ROM，不声称手机已解决多走一格／穿树冻结；必须验证持方向键、B、自行车及跳崖后立即转向，且查新 MAP ROM0 余量≥64B。
- 补丁以用户之前的 `.272` 候选为增量、确认的干净 Git `b4148ccb` 为累计全量，二者互斥；保留用户已修正的 `jp`，`TEST-231` 不变。

## FIX-272｜Home Copy Data 没有变坏，ROM0 总预算才是问题

- `.269` 两次新增 `callba` 挤爆 ROM0，`.270` 减12B后链接成功但随包 MAP 只余26B；`.271` 又把森林跳崖 B 键保护加回ROM0，用户再度报告 `Home Copy Data` 无法放置。以后不能只算某次修复的净增量。
- `.272` 保留全部通用ROM0关键例程，把城都私有的陆地碰撞分派合并为25B网关（旧124B），Bank `$4F` 嵌套调用原有 `HandleLedges` 和精确地形函数。所有外部返回只以 E=0/1/2 判断（BankSwitch 会改A）；先拦精灵与开放边缘，再走地区分派，最后保留关都回退。
- `tools/johto_land_rom0_preflight_272.py` 只是源码尺寸与ABI门禁；真正的可链接性、连续ROM0空间和安全余量必须以用户本机**新** MAP 为准。

## FIX-5.62.271｜南线成熟分支移动／边框回归修复（开发候选）

- 以用户 FIX-5.62.270 的实际 Worktree 为增量基线，参考 NPC-5.62.243 的 ILEX-217、Gold 边框与碰撞掩码。桧皮镇地图边框恢复 `$05`；满金市恢复 `$35`，不以 `$00` 代替未连接区域的外围填充。
- 桐树林保持 ILEX-217 的共享跳崖图块／两次输入，不改跳跃方向和步数；只恢复 `home/overworld.asm` 中跳崖期间禁止 B 键跑步加速的原生保护。
- 比对 Gold 角色阵列与成熟分支碰撞掩码，新增 `JohtoSouthMatureDoorFence`：保留 Gold 源角色阵列不变，仅封闭尚未开放的26处室内门槛；森林北 DOOR 与南部两格地毯只允许成熟版规定的方向。已开放的桧皮镇南门房两格保持原有 Warp 合同。未开放地图连接和关都行为不扩大放行。
- 新增成熟分支差异审计与故障注入，并接入主迁移审计；使用 PNG 源文件，不提交 `.2bpp`，保留用户已编译修正的 `jp nz,.noCollision`。
- `.270` 附带 MAP 的 ROM0 仅剩26B，低于要求的64B；本轮引入的小型跳跃保护占用 ROM0，**静态检查不代表可安全链接**。未编译 ROM、不提交 Git。用户必须使用新编译 MAP 核实容量，并用手机验证桐树林起跳/着地、按 B、桧皮镇边界、满金市上下滚动、未开放房门。

## FIX-5.62.270｜ROM0 屋顶调用容量修复（待本机链接验收）

- 用户本机 `.269` 链接失败：`Unable to place "Home Copy Data" (ROM0 section) anywhere`。根因是 `.269` 在几乎满的 ROM0 新加两次 `callba`（每次6字节、合计12字节），造成独立9字节 `Home Copy Data` 段无法放置；不是 `Home Copy Data` 自身被写坏。
- `.270` 在 ROMX Bank `$4F` 复用已存在的 `ApplySnowTilesetGfxPatch` 和 `InitMapSprites` 两处6B跨 Bank 调用：保留雪天和精灵处理、完整地图加载和无缝切换的屋顶更新，ROM0 比 `.269` 节省12字节。不挪动会改变 ROM Bank 的 `LoadTileBlockMap` 或 CopyData。
- `johto_rom0_roof_preflight_270.py` 已加故障注入与迁移总审计；不增生成 `.2bpp`，保持 PNG 源图、原有 `jp nz,.noCollision`、所有场地技能、Warp 和 `TEST-231` 不变。
- 只读静态检查不等于成功链接；`.269` 的失败版本新 MAP 尚未提供。用户应重新编译并检查 ROM0 MAP 至少64字节安全余量；未实机验收前交一个 ZIP 内两份互斥增量／全量补丁，不制作正式提交日志。见 `docs/JOHTO_ROM0_ROOF_BUDGET_270.md`。

## FIX-5.62.269｜南线视觉、森林跳崖与33号路接缝修复（开发候选）

- 以 `MAP-5.62.268` 六图运行版本为增量基线，以 `FIX-5.62.267` 干净 HEAD `b4148ccb783bdf734d621d0b8e8419f24ffe72da` 为累计全量基线；**只选两份互斥补丁之一**，不要叠加旧 `.268` 资源／几何阶段包。
- Route33 → 桧皮镇：固定 `x=0, y=14/15` 的 Gold 西向接缝，最先经过边界白名单后再由 `JohtoRoute33StepPolicy` 显式放行，避免 `dec x` 的 `$FF` 下溢造成空气墙。其他未开放边缘继续封闭。
- 桐树林：恢复成熟参考 `ILEX-5.62.217` 已验收 PNG（含3个克隆图块）、46块 `.bst`、6个指定跳崖图块替换位置及 `JohtoIlexForestLedgeTiles → .checkPairs → .foundMatch` 通用跳跃路径。Gold 原始 `.gold.blk` 永不改动；运行时只允许6个既定克隆差异。Cut 清树仅替换 `$0F → $2D`，保留相邻 Headbutt，森林使用独立 Gold collision 和 CAVE 背景／夜间 OBJ 调色板。
- 屋顶：依据 Gold 原图 24×24 PNG、`roofs.pal` 的 RGB5 以及成熟 `.216` 的地图组策略，按若叶、吉花、桔梗、桧皮、满金群组更换9个屋顶图块与第6号背景调色板。覆盖完整载图和无缝地图连接两条路径，不修改关都地图。PNG 是源文件，`.2bpp` 由 Makefile 生成，不得入 Git 补丁。
- 运行时代码保留已由用户本机修过的 `jp nz,.noCollision`，新增长距离条件分支也使用 `jp`，防止 RGBDS 的 `jr` 距离限制。
- 静态验证：Gold 克隆字节、MapSource/Surf/Cut/HOP 合同、颜色 PNG/RGB5 与两条屋顶执行路径、门房 Warp 和地图迁移均需通过。静态检测**不等于**成功编译 ROM、显存显示或者用户实机验收。禁止自行编译 ROM／执行 Git Commit、Push；TEST 继续为 `TEST-231`。
- 开发阶段只交一个 ZIP，内含从 `.268`→`.269` 的增量补丁和从 `.267` 干净 HEAD→`.269` 的累计全量补丁，二选一。实机验收后才按模式 A 生成正式清理三件套和中文提交日志。

## MAP-5.62.268｜城都南线六图批量运行接入（开发候选，待本机验收）

- 基线：用户最新干净 HEAD `b4148ccb783bdf734d621d0b8e8419f24ffe72da`、分支“常规功能备份”、正式版本 `FIX-5.62.267`；一份完整补丁直接覆盖从 `.267` 到 `.268` 的全部新增源码与资源，**不需要先安装曾交付的资源／几何中间包**。
- 新增六张活动地图：`AzaleaTown`（桧皮镇）、`IlexForestAzaleaGate`（南门房）、`IlexForest`（桐树林）、`Route34IlexForestGate`（北门房）、`Route34`（34号道路）、`GoldenrodCity`（满金市）。活动地图 15→21；与既有33号道路组成连续南线。按 Gold/成熟 NPC 分支核对图块源、区块、碰撞、地图接缝、15 条六图内部 Warp、来源方向、音乐、地点名称及骑车许可；原有北洞口及关都不变。
- 场地技能：新增三张图共342格 Surf 水域（桐树林32、34号路226、满金市84），加桐树林1棵 Cut 树及桐树林/桧皮镇的精确方向跳崖规则。城都21张活动地图合计水格1098、Cut树8、跳崖碰撞格116；一切以 Gold 静态参考审计为准，不代替 ROM 实测。
- 资源：仅跟踪 PNG 图形源以及 Gold `.blk`、`.bst`、碰撞/角色数据；`.2bpp` 由 Makefile 的 PNG 转换规则在本机构建时生成，**禁止放进 Git 补丁**。保留用户已编译修改过的 `jp`，不做 `jp→jr` 回退；TEST 版本 `TEST-231` 不变。
- 边界：通往仍未接入的建筑／房间、联合洞窟地下层、Route32/33 直连及剧情 NPC/遭遇仍封闭；本轮不擅自把全部 Gold Warp 开放，也不新增存档字段。
- 验证：含 Gold 来源的完整 Python 测试267项中266通过、1项因用户侧新 MAP 不在本 ZIP 而跳过、0失败；城都迁移237/237、Warp到达18/18、ASM标签2081文件、三张表长及南线空间 Surf／资源审计通过。**未运行 RGBDS 编译、链接、ROM、手机测试，不把开发候选写成实机验收通过。** 只有用户本机成功编译并跑通整条路线之后，才制作正式清理三件套／中文提交日志。
- 开发交付：单 ZIP 中仅两份互斥 `.patch`（`.267→.268` 增量、同一已确认干净 HEAD→`.268` 全量）。两份从同一干净基线生成，不能叠加。用户本地如已装旧 `.268` 中间包，必须先还原到 `.267`，不要直接叠加完整补丁。

## CLEAN-267｜切勿把图形中间文件当作缺失源码、或回退用户 JP

- 前版累计补丁多带了本地生成的 `gfx/tilesets/johto_modern.2bpp`，但实际用户工作区导出仅有 PNG，这是正确的：`Makefile` 会从 PNG 自动产出 `.2bpp`，而 `.gitignore` 忽略生成文件。收口必须以 Git 可追踪源资源为准，不用 `git add -f` 强行提交编译中间物。
- 正式清理还修正旧 `johto_route33_266_audit.py` 的过度依赖：旧审计直接读取被忽略的 `.2bpp`，干净 Git 检出后会 FAIL。现改为读取 PNG 源，经已有 `strict_2bpp` 仅在内存中转换后与 Gold 源作比较，配套测试改为复制 PNG 并注入 PNG 图像改动。运行时 ASM、Makefile 和资源内容均不变。
- 用户工作区有针对 `home/overworld.asm` 的 `jp nz,.noCollision` 长跳修复；以前窗口的旧 `jr` 作为清理源会造成编译范围回归。对有 `JR` 距离限制的情况须依据实际源码与用户构建反馈审查，避免凭静态符号预检就称能够链接。
- 用户反馈进出洞、Route33 显示、骑车、Fly 正常；后续未说明完整的“出去的时候……”仍需确认。不得把静态 PASS 冒充其它地图、地下层、与桧皮镇连接已验收。

## FIX-5.62.267｜33号道路图块集加载溢出修复（开发候选）

- 症状：联合洞窟南出口进入 Route33 后整屏花屏；并非 Gold 33号路 `.blk`、PNG 或落点写反。
- 根因：`engine/overworld/tileset_header.asm` 原先以8位移位/加法拼出 `tileset * 12`，`JOHTO_MODERN=32` 时中间进位丢失，实际 `$0080` 而非 `$0180`；读取到错误的 ROM Bank/图块指针。`color/loadpalettes.asm` 又以8位 `sla e`×3 求 `tileset * 8`，ID32 时 `$0000` 而非 `$0100`。**旧回归检查没有把新 Tileset ID 32 送过这两段运行时地址计算。**
- 修复：仅将两处索引改用16位 HL 算术，保留 `.266` 地图资源、Gold碰撞、双向 Warp 和 `.265` 朝向。无新 Bank、新 SRAM、无大范围图形替换。
- 防回归：新增 `tools/tileset_index_preflight_267.py`、`tools/tests/test_tileset_index_267.py`，检查 ID 0–32 及故障注入；注意该检查不模拟 ROM VRAM，不能代替手机验收。
- 交付：增量严格从 `.266` 实际开发候选生成，累计全量从 `.266` 原来声明的干净 HEAD `438046a6ae6a709b656b8f712eeeecefc6259dda` 生成，两份互斥；不编译 ROM、不提交 Git、不更新 `TEST-231`。须由用户本机编译并检查新 MAP／南北口和 Route33 显示。

## FIX-265：不能把 Warp 出口朝向误当作进入后的朝向

- `.264` 为了让 `WARP_CARPET_DOWN` 的出口“面向内部”，在到达 `.caveFacing` 中强写 DOWN；但北侧进入是 Route32 朝 UP，且洞内 Gold `(17,2)` 为 FLOOR、`(17,4)` 为 WALL。普通引擎已经保有按键方向，进入洞穴应不额外改朝向。
- `PlayerStepOutFromDoor` 的洞内 E=0 不模拟步进；出洞的 DOWN 仅由 `ExtraWarpCheck`＋最终碰撞 guard 在玩家主动朝南碰撞时判断。避免让静态测试硬编码错误的 DOWN 覆盖。
- 待用户本机正式 ROM/TEST ROM、最新 MAP 及手机走出／再次进入、存读档验证；静态审计不等于实机验收。

## FIX-264｜静态全绿但 Union Cave 1F 始终出不了：漏了 ExtraWarpCheck 的前置 Warp 资格

- `.263` 将 Gold `UnionCave1F (17,3)` 的最终 `JohtoPilotGateCollisionExitAllowed` 改成 DOWN，却未给更早运行的 `JohtoPilotGateExteriorCollisionAllowed` 登记该洞穴。玩家碰撞墙面时 `ExtraWarpCheck` 询问前置函数返回0，退回旧 `IsPlayerFacingEdgeOfMap`；洞穴入口在图内，不是地图边缘，所以 Carry=0，根本不会调用最后的 Warp 匹配。
- 旧 NPC 分支的门房踩坑文档已明确记载过类似“非地图边界入口未接入 ExtraWarpCheck”问题，这次没有沿完整调用链检查，重复了同类错误。
- 还有更上游的门槛：`EnterMap` 原只为 HOUSE/GATE 调用 `IsPlayerStandingOnWarp`；CAVE 到达格本身是 Warp，必须重建 `wd736 bit2` 才可能进入 collision path。
- 此外，新增前置资格后必须同步隔离 `CheckWarpsNoCollision` 的 fallback；否则洞穴 `WARP_CARPET_DOWN` 会在无碰撞踩格时被立即触发。只从碰撞路径回程，仍保留 warp 标志 bit2。
- 正确修复不是改第三遍 `PLAYER_DIR_UP/DOWN`：在 ROMX 前置函数按洞穴 ID 转发到同一个最终 guard，保留 `(17,3,DOWN)` 唯一放行、`(17,4)` 阻挡、未开放楼梯/南洞口继续关闭。
- `johto_union_cave_portal_audit.py` 必须解释执行 ROMX 两个关联谓词，并静态验证 ROM0 前置 Carry 与碰撞调用链；测试须在故意删除前置地图登记、断开调用、颠倒 Carry 跳转时 FAIL。ROM 编译与设备验收仍由用户完成。

## FIX-263｜联合洞穴 WARP_CARPET_DOWN 不等于 DOOR（Gold／旧 NPC 参考）

- **用户实测故障**：新 `.260`～`.262` 洞口虽然静态 Warp 表互通，但进洞后角色朝墙，不能回 Route32，且洞内不能骑车。不能把地图“有 Warp”视为双向可用。
- **来源核实**：Gold UnionCave1F `(17,3)` 是 `WARP_CARPET_DOWN`，下面 `(17,4)` 是 `WALL`；旧 NPC-5.62.243 已实现“进入洞内保持原 Warp 格、朝下撞墙才出洞；只有出洞至 Route32 `(6,79)` 需要自动往南一步”。
- **根因**：新代码把洞内 carpet 当 DOOR 设置 `D_DOWN` 自动步，把回程碰撞方向反设为 `PLAYER_DIR_UP`，还错误允许从 `(17,4)` 朝上进入 Warp。修法是删掉洞内 STEP_ON／DOOR 例外，只保留精确站位+朝下碰壁的 COLLISION_ONLY 出口；别修改已经验收的横向／竖向门房。
- **骑车**：旧分支 `BikeRidingTilesets` 显式包含 `JOHTO_UNION_CAVE`，新 Tileset 注册时遗漏了这项；只有洞穴专属 Tileset 恢复骑车，不靠名字含 CAVE/GATE 全局开放，不碰普通室内许可。
- **防回归**：`tools/johto_union_cave_portal_audit.py` 与 `tools/tests/test_johto_union_cave_portal_263.py` 被总迁移审计发现；故意把出口方向改上、把洞内 D_DOWN 自动步加回、放宽 STEP_ON、删骑车或反向 Warp，必须 FAIL。静态审计不能取代 ROM/手机验收。

## ROM0-262｜旧 NPC 已完成更多地图，为什么本工程先链接溢出？

- 旧 NPC-5.62.243 的 MAP：ROM0 15,916字节、剩余468字节，Main `$3C21`；当前旧 MAP：ROM0 16,353字节、剩余31字节，Main `$3DAE`。不能以地图数量推断 ROM0 空间，两个工程还有其它功能差异。
- 两边的联合洞穴碰撞都是 ROM0 可读，**切忌**为了腾空间将 `JohtoUnionCave_Coll` 放在裸 ROMX：移动、NPC、Surf 上岸使用 unbanked 的 `wTilesetCollisionPtr`。
- 旧分支把 Gold 水格和原生碰撞判定外迁 ROMX，也曾将菜单主循环迁 Bank `$01`；当前 Bank `$01` 几乎满，只借鉴前者的短入口/远谓词模式。
- 本批把行内逐图 Surf 判定转到 Bank `$48`，Carry/Zero 双标志编码 Gold WATER、吉花市 FLOOR、非水岸、关都兜底。Bankswitch 恢复 Bank 会污染 A，但不改 C/Z；岸线上岸前须恢复 `C=wTileInFrontOfPlayer`。
- 旧 MAP `$001F` 余量是**旧链接结果**，不是 `.262` 编译结果。预检输出23字节入口、估计减少173字节只是预算；新 ROM 必须用户重新 rgblink，且 `--require-fresh-map` 不得接受旧地图。

## FIX-261｜ASM 标签预检通过仍可能被 RGBDS 数据表长度 ASSERT 阻断

- CAV-260 将城都活动地图从13扩至14，但 `engine/menu/options_menu.asm::JohtoActiveGSCMusic` 仍只有13条 `db`。`ASSERT ... == NUM_JOHTO_ACTIVE_MAPS` 正确阻止了汇编，不能通过删除 ASSERT 或降低活动数绕过。
- 以后新增地图槽位时，地图注册、Town Map项目表（4字节/槽）、浏览索引（1字节/槽）及 GSC音乐表（1字节/槽）必须同步；缺一项也要阻止交付。
- 独立预检现在是 `python tools/johto_table_assert_preflight.py --root .`，同时已经作为 `johto_pilot_migration_audit.py` 的强制检查执行。测试还会注入漏项、重复项和 ASSERT 被删除，不能仅靠 ASM 局部标签检查宣称可编译。
- Gold原版 `UnionCave1F` 是 `MUSIC_UNION_CAVE`；主工程第14条选 `MUSIC_GBP_GSC_UNION_CAVE`，与现有 `MUSIC_DUNGEON2`运行场景对应。工具仍不取代 ROM/MAP/手机验证。

## UNION-260：洞穴与野外共享逻辑时的易漏项

1. `Gold UnionCave1F.blk` 和 NPC compact `JohtoUnionCave1F.blk` 含义不同；必须保存、单独验证，不能互相覆盖。
2. 新 Tileset 编号必须同时扩展 `data/tileset_headers.asm`、`data/warp_tile_ids.asm`、`color/data/map_palette_sets.asm` 和 `color/data/map_palette_assignments.asm`，遗漏会令颜色或指针错位。
3. 洞穴 Surf 不能只在 A 键或道具入口接水格判断；游泳中续行和岸边上岸也必须单独识别 `JOHTO_UNION_CAVE`，并恢复 `wTileInFrontOfPlayer` 到 `C`。
4. Gold DOOR 需要目标落点安全自动走一步，不能照搬门房地毯；B1F/B2F/Route33 的其它 Warp 必须关闭。
5. 历史脚本固定13张图时应保留真实回归意图，升级活动地图合同并加新地点名、田野能力、Gold逐格碰撞负向测试。

## MUS-259 验收经验｜门房与首次洞穴前的检查

- 活动门房不能仅有 Warp、音乐 profile 或 neutral 地名之一：新增 stable ID 后，必须分别登记方向与到达步进、Gold GATE/INDOOR 骑车、真实进入侧曲目、同曲缓存、地点弹窗、Town Map/Save 名称；运行 `johto_gate_music_bike_audit.py` 与 `johto_map_name_sign_audit.py` 故障注入，不能仅凭单元测试 PASS 宣称 ROM 音轨连续。
- Gold `GATE` 可以骑车但需 FLOOR；`INDOOR` 不因门房名称或图块开放。门房 Continue 无可信来源必须回退原版默认曲，不继承陈旧 WRAM。
- 联合洞穴是新 Tileset＋ROM Bank＋层间 Warp 场景：`maps/johto_staged/JohtoUnionCave1F.blk` 不是活动地图。旧 NPC 的洞穴图块、碰撞、1F参考实现需先逐块匹配 Gold，再加入 ROM0 可读取的碰撞和独立 Tileset；必须防止玩家从已开放1F进入未开放 B1F/Route33。不能把道路入口、Field Moves 或音乐检查的户外规则直接套入洞穴。

## MUS-259：新门房必须分别核查 BGM 来源、音乐缓存、Gold 骑车环境

- 北门房首次接入时只把新门房加入 Warp/地图表，遗留固定 GSC ROUTE36 曲目且忘记将稳定 ID19 加入 Bike 谓词。单独验证 Warp、地点栏和 ASM 标签都发现不了。
- 今后每个新活动门房都要在 `johto_gate_music_bike_contracts.json` 中提供 Gold 环境、双向来源、继承音乐和骑车许可，并运行 `johto_gate_music_bike_audit.py`；此审计已被总迁移审计调用。不能简单 `cp JOHTO_GATE` 全局放行，也不能把名字带 Gate 的 INDOOR 门房当作 GATE。
- GSC/RND 必须用进入侧稳定 ID，不是门房固定主题；同一曲维持缓存，不重复抽 RND。来源 WRAM 未知时回退自身 Gold 默认曲，不能使用非相邻地图的音乐。

## FIX-258｜新地图必须登记 map-name sign 的独立 neutral/landmark 路径

- 故障重现：`.257` 北门房 `Route36RuinsOfAlphGate` 已有 Town Map/Save 名字，但 `engine/overworld/map_name_sign.asm::.IsNeutralMap` 漏加此稳定 ID，转而走 `.JohtoUnknownName` 显示 `Johto`；Warp 和移动完全可以正常，这类缺项无法靠门房／Town Map 条目数量测试发现。
- 解决：按活跃资源描述表逐张检查 `map-name sign` 独立名称路径；Gate 必须用 `wCurMap=$FC` + Johto region + stable local ID 判断 neutral；户外图必须有非默认分支和真实名字，并与 Town Map/Save 对齐。故障注入覆盖旧门房丢失、未来新地图缺合同及错误文本。执行 `python tools/johto_map_name_sign_audit.py --project .` 或包含它的迁移总审计。
- 不要把整张 `$FC` 都当中立地图；不要通过让所有 unknown Johto 不显示来掩盖缺少道路名字的 bug。

## ALPH-NORTH-001｜竖向遗迹门房必须按目标落点处理自动迈步（下一阶段门禁）

- 当前已验收的 Route32 遗迹南门房是横向 EastWestGate：左右地毯均为 `WARP_CARPET_LEFT/RIGHT`，按 LEFT/RIGHT 碰撞触发，到达地毯没有自动迈步。它的 `JohtoPilotGateCollisionExitAllowed` 只检查 `x=0/9`、`y=4/5` 与 LEFT/RIGHT。
- Gold `Route36RuinsOfAlphGate` 是竖向门房，不能复制南门房守卫：上端 `(4/5,0)` 是 `DOOR`，STEP_ON/UP；下端 `(4/5,7)` 是 `WARP_CARPET_DOWN`，COLLISION_ONLY/DOWN。Route36 的入口 `(47/48,13)` 是 DOWN 地毯；遗迹外围北门 `(7,5)` 是 DOOR。
- **关键：到达自动迈步取决于目标落点角色，而非源地毯。** Route36 → 门房上端 DOOR、门房下端 → 遗迹北侧 DOOR 都需要 Gold `D_DOWN` 一步；门房上端 → Route36 地毯、遗迹北门 → 门房下端地毯则没有自动迈步。不得对所有 Warp 统一自动下行，也不得遗漏 DOOR 到达后的单步。
- 新合同须同时记录源触发类型／方向、Gold 源 Warp 编号、压缩 runtime ordinal、目标 Warp 编号／落点碰撞角色、arrival step 和最终落点。特别注意 Route36 的 Gold Warp #1/#2 属于 National Park Gate，遗迹门房入口是 Route36 Gold Warp #3/#4；Ruins 北门是 Gold Warp #9，不能将 Gold ordinal 直接当 runtime ordinal。
- 测试必须覆盖上下两条车道、四个进出方向、自动 D_DOWN 仅执行一次、最终格可走、不会立即二次 Warp、到达后第一按键、存档 Continue、侧向碰撞负例、骑车进出，以及 National Park/Route35/37 未完成出口 fail-closed。

## ROUTES-253｜活动地图 Field Moves 全覆盖与地点栏收口

- 新增活动地图时，不能只看已登记 Surf 合同的预检 PASS；必须同时跑 `johto_surf_coverage_audit.py` 与 `johto_field_move_coverage_audit.py --gold <Gold源码根目录>`，分别发现漏登水域及 Cut/HOP 缺口。当前已启用 9 张地图共 644 WATER、7 CUT_TREE、78 HOP；这不是 Gold 全 222 张地图均已适配。
- 若叶镇 Surf 通过恢复 runtime `.blk` 偏移39的 Gold 水面块 `$54` 接回，不要把显示图块或共享 tilecoll 当成水域真值。水域按 Gold 碰撞坐标限定，三个 Surf 入口与上岸陆地通行分支必须一起核对。
- Route32 的跳崖要按稳定 ID 7 独立派发；不能因复用 Route31 的 tile-pair 表就把 Route31 的地图身份判断删掉。地图地点栏也必须为稳定 ID 7 显式返回 `Route 32`，避免解析失败回退到通用 `Johto`。
- 当前用户已反馈正式／测试红蓝构建、新 MAP 与手机回归均通过；这属于用户验收。静态工具仍只证明源码合同与参考数据，后续新增地图必须重新做本地构建、MAP 和实机验收。

## GATE-ROUTES-252｜Gold 门房骑车不能按建筑名称或图块集“一刀切”

- Gold `BikeFunction.CheckEnvironment` 允许 `GATE`，地图切换不强制 `GATE` 下车；但 `Route35NationalParkGate` 与 `Route36NationalParkGate` 的环境恰是 `INDOOR`。别见 Gate 就开车，更不能把 `JOHTO_GATE` 塞进所有骑车图块集白名单。按 `wCurMap=$FC/region=Johto/稳定 local ID` 明确登记当前开放门房，继续让关都逻辑走原分支。
- 新路线 Surf 不光有 Gold WATER 还要逐岸 Gold FLOOR / compact 视觉 tile 预检，防止能下水不能上岸；Bank `$03` 没有空间时使用已有银行内 Surf 路由。城都 Field Skills 原自动 Bank 余量紧张，.252 改为显式未占用扩展 Bank `$48`，用户必须检查最新 MAP，不以静态通过代替 RGBDS。
- Cut 必须同时确认 Gold 碰撞象限与当前 runtime block，删除后只替换对应2×2 tile，邻近摇树不可抹掉；可复用既有 `$8D/$8F` 克隆而不新增 Bank `$03` Cut 映射。详见 `docs/JOHTO_GATE_ROUTE29_ROUTE32_252.md`。

## ROUTES-251：新地图 Surf/Cut 要守住 Bank `$03`、逐图作用域和单象限替换

- 道具 Surfboard 与 Cut 使用所在 Bank `$03` 在 `.250` MAP 只有6B剩余；新增道路时不能在 Bank `$03` 多加一组组 `callab`。已用现有 `JohtoVioletWaterAhead` 做同 ROMX Bank 的 Route30/31 carry 逐图转发，Cut 则用 `JohtoPilotCutTreeAhead` 保留原调用数，Bank03 只添三组2B Cut block swap。`.251` 实际剩余量须用户重新链接看新 MAP，不能用旧 MAP 代替。
- 水中 `CollisionCheckOnWater` 的分图链：原吉花市 helper 返回后 A 可能已被修改，因此 Route30/31 分支必须重新加载 `wCurLocalMapID`，并在目标非水时 `wTileInFrontOfPlayer → C`，否则会重现无法上岸／误地图的隐患。必须同时测试道具、招式、水中续行及上岸。
- Route30 `(8,6)` 对应 Block `$67` 左上 Cut；Route31 `(13,5)` 对应 `$5F` 右下、`(25,10)` 对应 `$5B` 右上。不能整块换为地面，会删除旁边 Gold HEADBUTT_TREE；原 `$63→$8D` 必须保留给桔梗市。
- 两图 Gold FLOOR 岸线无已知额外例外，但只属静态查表结论，用户要在手机验多个岸线。详见 `docs/JOHTO_ROUTE30_ROUTE31_FIELD_251.md`。

## CHERRY-250 收口要点：冲浪成功不等于所有 Gold FLOOR 可以上岸

- Gold WATER 几何合同即使完整，紧凑图块 `$3C` 同时被 WALL 与 FLOOR 复用，也可能让原版8个可登陆 FLOOR 被运行时白名单误判为墙。不可全局放行共享图块 ID；使用当前地图稳定 ID 和 Gold 精确地面格解决 Surf 上岸与陆地移动两条分支。
- 从 CHERRY-249 到 CHERRY-250，`johto_surf_preflight.py` 的 `MISSING_SHORE_PASSABILITY` 负例属于必须保留的回归关卡。新地图注册 Surf 时要让水面、可登陆岸线、上岸后步行及来源地图隔离同时通过，不能只验证水格计数和上岸寄存器。
- 用户已申请本轮清理提交，正式 Git 基线为 `.248 / d1d833b6`。功能运行源码与 Python/JSON/维护文档须拆两笔；历史 `.249`／`.250` 开发补丁不能伪称中间独立 Git Commit。

## CHERRY-250 / PAL-5.62.250 — 吉花市西南岩石平台登陆及 Gold FLOOR 审计（开发候选）

- **故障证据**：用户截图显示在吉花市西南岩石平台南边水域无法登岸。Gold `CherrygroveCity` 地图碰撞定义平台 `(x4..7,y12..13)` 共 8 个格为 `FLOOR`；紧凑运行 Block `$71` 绘制的是 8×8 图块 `$3C`，但 `johto.tilecoll` 不允许 `$3C`。同一图块 `$3C` 在本图还用于 `WALL`，绝不能全局放行，否则穿墙。
- **最小修复**：不改 Gold 水格 142 条、不改 Blockset／碰撞白名单、不改存档、门房和其他地图。新增 `JohtoCherrygroveShoreFloorAhead`，仅允许吉花市稳定 ID2 的这 8 个 Gold `FLOOR` 坐标，水上经 `CollisionCheckOnWater` 停止 Surf 上岸、陆地经 `CheckTilePassable` 放行平台内部的连续走动。其余 `$3C` 仍碰撞。复用原版已有 Surf 状态恢复函数，不另造状态机。
- **工具改进**：`tools/johto_surf_preflight.py --gold` 现在除对照 Gold WATER，还会从 Gold FLOOR／当前 compact `.blk`／Blockset／tilecoll 动态检测“海岸边属于可走 FLOOR，但运行白名单不放行”的连通区域。CHERRY-249 原代码会报 `MISSING_SHORE_PASSABILITY`；只有水陆两条执行路径都正确接入有范围限定的例外，且坐标与 Gold 完全一致，才通过。`tools/tests/test_cherrygrove_shore_250.py` 包含故障反例。
- **实际边界**：完成的是静态源码修复与审计。正式 Red/Blue 与 TEST 编译、最新 MAP 空间及该平台四周上下岸、步行、回水、存读档实测由用户本地确认。未确认之前不得标为运行验收通过，也不制作 Git 提交日志、不自行 Commit/Push。

## CHERRY-249 / PAL-5.62.249 — 吉花市冲浪接入（开发候选，待用户本机编译与实测）

- **基线**：用户上传 `PAL-5.62.248.zip`，本轮从该完整源码开始；保留 SAV-244、Route32-245/246、桔梗市 VIOLET-247/248 和 SURF-AUD/COVER 工具改动，不改变存档布局或活动地图数。正式标签升至 `PAL-5.62.249`，`TEST-231` 不变。
- **Gold 源数据**：`CherrygroveCity` 原版地图有 142 个 `WATER` 碰撞格，尺寸为 20×9 Blocks / 40×18 collision cells。坐标表从 Gold 原始 `.blk` 与 `johto_collision.asm` 逐格解码；水域表不通过共享 8×8 图块 ID 推断，也不改全局 tilecoll。
- **运行实现**：新增 `JohtoCherrygroveIsActive` 与 `JohtoCherrygroveWaterAhead`，限定共享地图句柄 `$FC`、Johto 区域、稳定 ID `JOHTO_CHERRYGROVE_LOCAL_ID`。把吉花市接入现有三个 Surf 入口：`IsSurfTile`、`IsNextTileShoreOrWater`、`CollisionCheckOnWater`；非水分支先恢复 `wTileInFrontOfPlayer` 到 `C`，再复用既有陆地通行扫描。桔梗市的 140 格合同和 Cut/跳崖实现保持不变；若叶镇东侧水域继续按用户要求跳过。
- **工具合同**：`tools/johto_surf_contracts.json` 加入吉花市，coverage audit 预期状态从 `MISSING_SURF` 变为 `REGISTERED`。仍未实现 Route30（32 格）、Route31（44 格）、Route32（278 格）；未激活联合洞穴不计入活动地图。
- **静态验证**：完整 Python 测试 122 项运行、120 通过、2 跳过；Surf 预检与 Gold 逐格比较通过；ASM 局部符号预检 2,067 个文件通过；地图迁移审计 69/69、门房 12/12、Warp 17/17。静态通过不是 RGBDS 链接或实机证明。
- **手机验收要求**：本机正式 Red/Blue、TEST Red/Blue 构建与 MAP；吉花市用 Surf 招式、Surfboard、四向游泳、从各合法岸边上岸、上岸后步行、重新入水、存档/Continue；回归桔梗市上岸、Cut、跳崖及关都冲浪。未通过不得再开放下一水域。
- **交付边界**：只生成开发补丁，不附 Git 提交日志、不代 Commit/Push、不自行 RGBDS 链接 ROM。覆盖审计 `REGISTERED` 不等于用户验收。

## ACC-248｜同一 ASM 涉及两笔提交时必须拆分补丁而非按文件名分类

- 真实 `.248` 工作区里，`home/overworld.asm` 既有 SAV-244 读档后指针刷新，也有 VIOLET-248 的 Surf 上岸修复；`data/game_version.asm` 同时承担 `.244`、`.248` 两个阶段版本变化。直接 `git add home/overworld.asm` 会把两类功能捆成一笔，违反三提交要求。
- 正确方式：以已核验的 `.243` HEAD 及工作区完整 Patch 重建 `BASE → SAV → GAME → TOOLS/DOC` 四个精确文件树，分别生成三份可 `git apply --cached` 的暂存补丁。每笔提交后再应用下一笔，不能把这三份暂存补丁当作工作区功能补丁重复执行。
- 旧存档具体故障样本、地图手机实测、静态回放和 ROM/MAP 构建证据需要明确区分；本轮用户仅确认所测场景正常。

## VIOLET-248 / PAL-5.62.248 — 修复桔梗市冲浪无法上岸（待本机编译与实测）

- **故障原因**：`home/overworld.asm::CollisionCheckOnWater` 对桔梗市先调用 `JohtoVioletWaterAhead`。当目标不是 Gold WATER 时，旧分支直接进入 `.checkIfNextTileIsPassable`，没有把 `wTileInFrontOfPlayer` 重新装入 `C`；该扫描因此可能使用旧的/无效的 C 值，将岸上可走图块判成碰撞。用户实测确认可以下水但无法上岸。
- **参考逻辑**：旧 NPC 金银分支在 `CollisionCheckOnWater` 的城都水面查询返回非水后，明确执行 `ld a, [wTileInFrontOfPlayer]` / `ld c, a`，再进入原通行表扫描。本修复补回这一步；继续复用现有通用上岸/恢复步行状态代码，不另造 Surf 状态机。
- **范围**：只改桔梗市地图专用非水分支，保留 140 格 Gold 水面表、入水检查、砍树和跳崖、关都 Surf 与徽章逻辑不变。新增 `tools/tests/test_violet_surf_shore_248.py`，包含正向检查与移除两条指令的故障注入反例。
- **状态**：静态回归及补丁回放可通过不代表 RGBDS 已链接；项目规则禁止助手自行编译 ROM。用户需重新编译红蓝／测试版本并在桔梗市实际测试：从不同岸边上岸、继续走动、重新入水；同时复测关都与 Route32 Surf。未获用户实测前保持开发候选，不生成提交日志、不 Commit/Push。

## VIOLET-247：原版地形角色不可用图形 Tile ID 代替（开发中）

- Gold 桔梗市存在 140 个 WATER 16×16 格、1 个 CUT_TREE 格和 3 个向下 HOP 格，另有 68 个 HEADBUTT_TREE 格。后者不是 CUT_TREE；已覆盖的建筑和树木保持原样，不应因“室外技能补齐”全局解锁。
- 同一紧凑绘图 Tile ID 可同时属于水、墙或摇树，直接把整个 `JOHTO_PILOT` 加入 `WaterTilesets` 或扩展 `johto.tilecoll` 会导致人物走水、穿墙。使用地图稳定 ID + Gold 精确水格，对 A 键 Surf、Surfboard 和水上移动三条路径一致判定。
- 唯一 Cut 树 `(36,19)` 与 `(37,19)` HEADBUTT 树共处源块 `$63`；只增设 `$8D` 运行时派生块，不能修改原始 141 块 `johto.bst`，也不能把整个 `$63` 改成普通地面。
- `.246` MAP 的 Bank `$03` 仅有 `$000F` 字节空间。此次在 Bank `$03` 放最小钩子，并移除 Cut 动画中无语义的旧 NOP 间隔来控制净字节差；全图位置表必须在浮动 Bank。静态预检不能发现 Bank 溢出，用户仍须完成红蓝真实链接／MAP 后才能验收。
- 本阶段不变更关都既有徽章规则，当前 Cut/Surf 仍依赖 Cascade/Soul Badge 以及会相应招式的宝可梦；Gold 城都徽章剧情之后另立专项统一。SAV-244、Route32-245/246 尚未 Git 提交，不改 SRAM 和地图激活编号。

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

## SAV-244：旧存档正常载入不等于碰撞指针正确

- 用户参考的 CHS 项目第005次历史提交 `1d7c62e5`（SAV-1.2）明确修复了旧存档 Continue 后四向不能走：地图状态从 SRAM 恢复时跳过 ROM Header，但 Tileset 指针可能已随新 ROM 位移。当前 PAL 原来在 `LoadMapHeader` 的 bit7 分支 `ret nz`，同样跳过 `LoadTilesetHeader`。
- 只在 bit7 的存档恢复路径（新旧存档均可能经过）重新调用 `predef LoadTilesetHeader`，调用时暂时令 `wDestinationWarpID=$ff` 并保存恢复原值，防止玩家坐标被重新定位。不得覆盖其它地图 Header、重编号城都 local ID、移动 SRAM 字段或擅自清空旧存档。
- 强制运行 `tools/tests/test_save_tileset_reload_244.py` 和 `tools/asm_symbol_preflight.py`。前者是静态源码合同，不能替代用户在旧 SAV 上的实际运行；ROM/Bank/MAP 与关都/城都兼容最终仍由用户编译实测。

## MUS-243-DOC-001 验收收口及跨窗口防回归（2026-10-29）

- 用户已在实际游戏中完成并确认 MUS-243 上轮要求的测试，30↔31 号路同曲双向跨图未再重播，相关模式及切换回归均报告正常。属于**用户报告的验收结果**，不能改写成 AI 自行编译／实测。最新 `.243` MAP 未随本轮对话提供，空间结论保持未独立核验。
- 上次 MUS-241 的 `ResolveMusicStyle.rbyFamily` 局部标签缺失曾令用户 RGBDS 链接失败；保留 `tools/asm_symbol_preflight.py` 与负向测试作为后续 AI 修改 ASM 时的必跑门禁。它只能检查局部引用，不能代替真正链接或运行时音乐播放接续。
- 旧 Gold 的 Route30/Route31 都使用 `MUSIC_ROUTE_30`；新实现对连接前后目标曲与缓存作比对，同曲跳过重播，换曲、Warp、战斗恢复等仍走原逻辑。新地图务必增加相邻同曲的双向检测，不能用相邻地图编号代替真实连接拓扑。
- JSON 源合同不能再被全局 `*.json` 忽略；按旧 NPC 项目经验，仅忽略指定生成目录。正式提交采用模式 A 分功能与工具两笔；第二笔带 `.gitignore`、`tools/`、测试和配套说明。不得把工具隔离补丁和从 `.239` HEAD 的累计全量同时套用，也不得重复添加已有门房合同。
- 后续 `222` 个城都稳定 ID 仍只有当前 8 个活动地图完成运行时音乐适配；其余需逐张映射并验收，避免将这一轮通过误写成全城都音乐已完成。

## MUS-243 相邻道路同曲仍重播：不能只检查曲目表

- Gold Route30/Route31 直接连通且 `MUSIC_ROUTE_30` 相同；关东也存在真正连通的同曲路段。`wCurMap=$FC` 是共享句柄，不能直接用旧物理地图号或地图名判定同曲。
- 即使两处曲目表相同，RBY 的 `PlayDefaultMusicFadeOutCurrent` 仍有战斗后强制重播分支，不能把源码里存在 `wLastMusicSoundID` 比较就算实机续播通过。
- 在无缝连接专用路径快照切换前 Gold 场景/RBY 音乐，加载后还要求实际缓存匹配对应移动模式，才跳过播放入口；若歌曲变更、缓存未建立或 Warp/战斗返回仍使用原规则。新窗口要跑 `test_johto_connected_music_243.py`、`asm_symbol_preflight.py` 和地图审计并等待用户正式 ROM/手机验证，禁止静态测试替代音轨续播验收。

## MUS-242：Python 业务测试通过仍可能留下 RGBDS 未定义局部标签（交付强制门禁）

- MUS-241 在 `engine/menu/options_menu.asm` 中引入 `jr .rbyFamily`，但 `ResolveMusicStyle` 内未定义 `.rbyFamily`。用户编译时报 `Unknown symbol "ResolveMusicStyle.rbyFamily"`，前轮宣称的 Python 业务测试和补丁回放均不能替代真实汇编/链接。
- 修复路径：将错误分支改到已有的 `.legacyStyle`，使用 `jp` 避免相对跳转距离问题；保留原 RBY/RBY+C 语义。**补丁发出前执行** `python tools/asm_symbol_preflight.py`，再运行局部符号错误注入测试；新 `.asm` 修改不能跳过此门禁。
- 检查器默认不编译 ROM，只检查 `jr`/`jp`/`call` 的本地点标签；其他未定义跨文件符号、宏和条件汇编、`jr` 位移超范围、ROM Bank 与 MAP 溢出必须交由用户本地 `python tools/asm_symbol_preflight.py --build` 的 RGBDS 完整四目标构建确认。AI 不能将静态 PASS 写成 RGBDS PASS，也不自行编译 ROM。

## MUS-241 / PAL-5.62.241 — 城都 8 张已激活地图的音乐场景与中立门房（开发待验，2026-10-29）

- **前置工作区**：用户确认已应用 JSON-TRACK-002、LOC-240（地点显示实机已正常），尚未 Git Commit。此次只追加 MUSIC-241 增量；不重复添加/覆盖之前 JSON、Save/Continue 名称修复。正式版本 `.240 -> .241`，`TEST-231` 不变。
- **原版核对**：MUS Gold `data/maps/maps.asm`：若叶镇 New Bark、29 号路 Route29、吉花市 Cherrygrove、30/31号路同为 Route30、向导家 Cherrygrove、桔梗市 Violet、31号路门房 Route30（但中立门房按进入来源继承，不固定开一段歌曲）。旧 `NPC-5.62.243` 的 `LookupJohtoMapGSCMusic` / `CheckJohtoMusicSceneTransition` 仅作五模式与场景缓存参考，绝不直接使用旧物理地图号。
- **新工程映射**：以 `(wCurMap=$FC, region=Johto, stable local ID)` 经 `GetJohtoActiveSlot` 查找 8 条活动槽位的 Gold 主题；状态/表 `0,1,2,3,4,125,5,6` 对应 8 槽。只有当前地图默认 BGM 才参与 Gold 场景映射，战斗、Surf、飞行、GB Player 直选曲继续走现有全局风格路径；Bike Song Off 的骑行仍使用当前地点主题。
- **门房音乐**：进入门房的已登记 Warp 在源 ID 被覆盖前，写入原来闲置的 `$D7C9` `wJohtoGateMusicSourceLocalID`。来自 Route31 ID4 时保留道路 RBY/GSC/RND 已在播曲，来自 Violet ID5 时保留城市曲；旧存档或非法来源退回 Route31 主题，不能从共享句柄 `$FC`、`wWarpedFromWhichMap` 或陈旧 `wLastMap` 猜来源。返回同侧尽量不重启，跨到另一侧选目标地点曲。门房仍**不额外显示地点牌**，地点显示独立。
- **缓存与存档**：`$D7CA` 由旧未用字节记录最近 Gold 场景，不变更后续 WRAM/SRAM 地址或存档长度；跨不同 Gold 场景（即使同 RBY ID）仅在 GSC/GSC+C/RND 且播放地图 BGM 时清除旧原曲缓存。RND **不在进门/地图载入时主动抽曲**，只在真正启动新曲时重抽；RBY/RBY+C 不被强制切换。切回关都清除场景标识并在相应模式下恢复正常选曲。
- **交付和验收边界**：本轮静态测试与补丁回放不等于 ROM 通过。AI 不编译 ROM、Commit 或 Push；等待用户本机红蓝 ROM 构建、新 MAP、五种模式、门房两侧进出、Bike Song On/Off、Surf、存读档、关都与渡轮回归。详情 `docs/JOHTO_MUSIC_SCENES_241.md`。

## JSON-TRACK-002｜按旧 NPC 金银分支的目录级忽略规则防止源 JSON 再度漏入 Git（2026-10-29）

- 参考用户交接包 `NPC-5.62.243_金银分支/.gitignore`：**不全局忽略 `*.json`**，而是只忽略 `extras/**/*.json`、`tools/generated_reports/**/*.json`、`tools/cache/**/*.json` 三类一次性输出。此规则已从旧分支核对，而不是单独为现有门房合同开白名单。
- 新增的地图定义、门房合同、资源清单、来源指纹与其他源 JSON **默认可被 Git 追踪**，无需每次维护 `!某个文件.json`。不要把需要入库的清单或来源记录放在上述生成输出目录。
- 离线工具生成的临时 JSON 应写到约定的生成目录，或写到项目外的隔离输出目录，不要因为临时输出存在就恢复全局 `*.json`。首次新增 JSON 时仍需查看 `git status --short` 并确认 `git add`，因为「未忽略」不等于「已提交」。
- 运行 `python -m unittest tools.tests.test_gitignore_json_policy`（或 `python -m unittest discover -s tools/tests`）检验未来源 JSON/生成 JSON 的 Git 行为；测试包含恢复全局忽略规则的反向故障注入。若重引入 `*.json` 则必须失败。
- 历史段 `P6-DOC-001` 记录的是当时的单文件例外紧急处理，不再代表当前长期忽略策略；本次不修改 `tools/johto_pilot_door_contracts.json` 内容。

## P6-DOC-001｜被忽略 JSON 合同与补丁重复创建冲突（2026-10-28）

- 根 `.gitignore` 中 `*.json` 会忽略新增的 `tools/johto_pilot_door_contracts.json`，即使手机本地与 RPP 导出 ZIP 里存在该文件，`current_worktree.patch` 仍不包含它；再执行带 `new file` 的累计补丁就报 `already exists in working directory`。
- 正确处理：先逐字节验证现有合同哈希、只添加 `!tools/johto_pilot_door_contracts.json` 精确忽略例外，清理增量**不复制、不覆盖 JSON**。用户进行工具 Git 提交时要明确 `git add tools/johto_pilot_door_contracts.json`；不要删除已有同名文件再赌补丁。
- 本轮 ZIP 的 JSON 为 8,702B，SHA-256 `714507d2a49dd299d9b0a1bdef7f8497d7a230a9f75b42e665f8f934ad4815e5`；未在本环境直接查看手机 Git index，因此不能宣称它已经被追踪。

## P6-BANK-001｜Bank `$3D` 满载与固定 ROMX 节复用（PAL-5.62.239，待链接）

- 用户本机 `rgblink`：`Unable to place "Menu Shortcut Helpers" (ROMX section) in bank $3d`。P5 红蓝 MAP `$3D` 都只有 `$006c` 剩余；恢复的 GATE-005 同 Bank 地名牌长度增长，旧预留空间不再足够。
- `home.asm` 对 `HandleBagStartShortcut` 与 `QuickSwapPartyMonWithFirst` 使用 `callba`；对 `LoadMapNameSignGFX`、`PrimeMapNameSignForWarpPad`、`UpdateMapNameSign` 也使用 `callab`，不依赖硬编码 `$3D`。因此将这两个整节移到 floating ROMX；名称指针保留在 `Map Name Sign` 同一节，不能只单独移动字符串。
- 旧 `patches/rppred.map`/`rppblue.map` 只能表示 P5 链接时空间，不能替代本次重链接后的空间核对。此轮禁止 AI 自行编译 ROM；交付前仍须做静态和补丁回放，用户本机实际链接结果待回报。

## P6-GATE-005｜门房过渡地点牌漏移植、共享 $FC 查错文字（待实机复验）

- 旧 RPP `JOHTO_GATEHOUSE_READ_FIRST.md` 规定：门房是 neutral map，不能显示单独地点牌，也不能通过物理 map id `$FC` 一刀切屏蔽所有城都。
- 当前导出中 `.IsNeutralMap` 只有 Kanto 旧 gate 清单，缺少城都 ID6。`ResolvePhysicalLandmark` 使用 `$FC` 调 Kanto 名称表，即使 Warp/地图布局检查全绿也会有空白 Window 或错误名称风险。必须先判 `region + stable ID`，把城都名称从同 Bank 本地文字取出（不能假设 Kanto MapNames bank 可以读新标签）。
- 上次 GATE-003 错误模拟 LEFT/RIGHT 单步；这次明确不恢复它。左出口 A/B 解锁症状只能通过新 ROM 实机判断是否与地名 Window 竞争一致；若未解决再查输入/脚本，不允许把静态预检当成实机 PASS。

## 城都地图扩容：必须静态核查 RGBDS 的旧字面 ASSERT（P6-GATE-002）

- 原因：从六张地图扩到八张时，`constants/region_map_constants.asm` 已定义 `NUM_JOHTO_ACTIVE_MAPS EQU 8`，但 `data/johto_stable_id_slots.asm` 仍写 `ASSERT NUM_JOHTO_ACTIVE_MAPS == 6`。表本身正确、迁移 Python 资产/几何审计全绿，也照样在 `main_red.o` 汇编阶段失败。
- 新增地图时要同时检查活动槽位常量、ROM0 稳定 ID 路由门禁、运行资源 Header/source/slot 表、字面 ASSERT 和相关注释；不能用 Python 静态审计通过替代 RGBDS 的实际汇编结果。
- 在 `johto_pilot_migration_audit.py` 的 `rgbds_literal_active_count_asserts` 检查及负向测试通过后，才允许交付静态候选。该检查仅识别 `ASSERT NUM_JOHTO_ACTIVE_MAPS == <整数>` 类型；不能覆盖 RGBDS 所有表达式、未定义标签、短跳转越界和 Bank 溢出。项目禁止 AI 自行编译 ROM，由用户本机验证最终汇编和链接。

## P6-GATE-001 — 城都东西向门房不仅是 Warp 坐标，还必须约束碰撞方向

- 旧 RPP `CheckWarpsCollision` 的匹配条件是当前站立 Y/X 和对应 Warp 项；如果直接给门房 x0/x9 边缘设置 Warp，即使玩家站在毯上向其它方向撞墙也可能错误离开。新门房额外在 `JohtoPilotGateCollisionExitAllowed` 核对当前地图为稳定 ID6、所在门毯 (x0/9,y4/5) 与朝向 LEFT/RIGHT，并在 `home/overworld.asm::CheckWarpsCollision` 的最终跳转前检查；其它地图保持原有语义。
- 门外实体门在普通碰撞判定之前仅按地图身份、严格来源站位与方向放行，并在确实匹配 Warp 格后进行同方向快捷传送。只改 8x8 可通行列表不足以解决旧卡门；也不允许全图放开同类型门砖。
- 新活动门房后必须同步扩展 `tools/johto_pilot_door_contracts.json` 和独立的落点/方向负向测试。室外与 Gold 门房图片相同并不能代表方向/自动步进已通过实测；ROM 编译与实机测试仍是最终验收门禁。

## P6-TOOLS-002 — 室内工具必须使用当前 stable-ID 结构，并把 Gold 触发语义和 RPP 资源分开

- MUS 是当前唯一 Gold 参考；不要要求用户同时提供 pret，也不要把手机里的备份路径当成上传压缩包的必需前提。目标 PAL 项目与 Gold 来源分开指定，所有候选输出必须在两个源树之外。
- 当前室内 Header/对象/登记不是旧版 `data/mapHeaders/Johto*.asm`：GuideGentsHouse 由 `data/johto_indoor_house.asm` 定义，Header descriptor 与 runtime resource descriptor 分离，稳定 ID125 映射到活动 slot5，`$FB` 路由用零基 ordinal。旧 registration generator 若只读取旧目录会错误报告缺失；未知地图必须 fail-closed，不能自动改 ASM。
- 当前 `JohtoHouse_Coll` 在 `home.asm`，而非传统 `data/collision.asm`。碰撞适配器必须解析 tileset header 实际引用的 `JohtoHouse_Coll`/INCBIN，不应假定碰撞表文件都在 `data/collision.asm`，也不应默认比较 `gate.tilecoll` 来审计 `johto_house`。
- Gold `DOOR` 与 `WARP_CARPET_DOWN/LEFT/RIGHT` 不是同一触发类型。候选图形像素完全相同不代表碰撞正确；当前房间入口应是踏格 DOOR，两个室内出口是方向门毯，出门目标 DOOR 才使用 RPP `PlayerStepOutFromDoor` 的 D_DOWN 一步。报告中的静态控制流、候选输出、门房库存不能冒充 RGBDS 编译或手机运行证据。
- 门房激活门禁：当前活动 stable IDs 里没有门房。任何未来 gate ID 激活前，必须添加明确合同（源/目标 Warp index、Gold collision role、方向、到达坐标、自动迈步最终格、反向重进与侧向负例）并通过新 MAP 和设备验收；未登记门房必须继续 fail-closed。

## P6-TOOLS-001 — 旧分支 Python 工具必须按当前登记 ABI 适配，且 Gold/旧 RPP 房间块编号不同

- `NPC-5.62.243` 的离线管线有价值，但其 `johto_map_release_audit.py` / `johto_rpp_connection_guard.py::audit_all_active` 默认读取旧 `data/mapHeaders/Johto*.asm`、旧 `tools/johto_native_maps.json` 和旧 Warp 合同。当前工程使用 `data/johto_pilot_map_headers.asm`、稳定 ID→活动槽位表和 `$FB` 登记 Warp；不能把旧全工程审计原样运行后把失败当成当前游戏错误，也不能把其 PASS 当成当前项目通过。
- 已拆出独立的 `johto_gold_connection_reference.py` 只核对 Gold 的冻结 142 条直接地表连接；它不证明当前 RPP 的连接 Header 正确。当前运行 Header、条带宽度、偏移、Warp、碰撞和自动步进由 `johto_pilot_migration_audit.py` 单独核对。新增地图后必须扩展当前审计和负向测试，不能仅依赖 Gold 源拓扑。
- Gold `maps/House1.blk` 和旧 RPP `maps/JohtoGuideGentsHouse.blk` 均是 16 字节但 block ID 编码不同。当前 `GuideGentsHouse.reference.blk` 与旧 RPP 文件一致，不与 Gold 原始 `House1.blk` 字节一致；对 Gold 的正确核对是尺寸、碰撞角色和映射/渲染，不得把“同尺寸”或“旧 RPP 字节一致”写成 Gold 原始块字节一致。
- 转换器只允许写入 Gold 与游戏项目目录之外的新空目录；输出中的 `OFFLINE_REVIEW_REQUIRED`、`runtime_approved=false`、`build_performed=false` 是强制边界，不可自动复制候选 `.blk` 到运行资源，也不可替代正式 Red/Blue MAP 和手机测试。

---

## P6-INDOOR-006 — 已验证参考 RPP 分支的门口运行时特例不能只看资源白名单（2026-10-28）

- 用户用真实手机指出 `.235` 的吉花市 `(9,25)` 实体 DOOR 仍如障碍物；即使房屋图块与 Gold 像素对齐、Warp 已注册、`$37` 在 `.tilecoll`、碰撞表搬 ROM0，仍不能据此宣称进门成功。对照 `NPC-5.62.243_金银分支` 真正使用的 `JohtoCherrygroveHouseDoorStepAllowed` 调用位置：在精灵碰撞后、tile-pair 和泛用白名单之前先对准前一格的方向放行，而不是仅调整图块、Warp 或版本。
- 此旧分支在 `CheckWarpsNoCollisionLoop` 还有独立的本地图已匹配 Warp 直接入场逻辑；须同时保留单次 UP 踏格、内部落点、室内 DOWN 门毯双出口、室外自动 DOWN 步进和立即反向复入。新项目只开放向导家，不应直接移植旧分支 5 座房门及 legacy ID，也不能扩大所有城都门砖通行范围。
- 局部源码特例只提供针对性修正，不是硬件证据。真实 ROM 是否包含新版补丁和引擎是否走到这条分支，必须用实际编译版本和设备操作确认；再报同类问题时优先核对运行 ROM 对应的源码，而不是连续交静态“通过”的新补丁。

## P6-INDOOR-005 — 不能只补门砖而不检查 Bank 与进/出门两种触发（2026-10-28）

- Passability 表不是普通可换 Bank 的 GFX：`wTilesetCollisionPtr` 在 `CheckTilePassable`、`CanWalkOntoTile`、`CollisionCheckOnWater`、`CheckForBoulderCollisionWhenPushingBoulder` 和冲浪登陆路径中多处被直接访问。户外/室内图块表放 ROMX 而未保证现场切 Bank，会导致“白名单新增门砖仍然不通”的不确定行为。P6-005 将 8B + 4B 的 Johto 列表移入 ROM0，Bank0 空间影响必须由用户新 MAP 实际确认。
- Gold `DOOR` 是 STEP_ON，`WARP_CARPET_DOWN` 是 collision-only；将室内 `$12` 放到 `JohtoHouseWarpTileIDs` 等于上毯即传送。仅仅删除 `$12` 也不充分：`ExtraWarpCheck` 在 y7 面向 DOWN 仍可走到无碰撞 Warp 分支；必须在 `CheckWarpsNoCollision` 分离方向毯，并确保位于 y7 的 `DOWN` 尝试产生真正碰撞才交给 `CheckWarpsCollision`。移动到室内 `(7,2)` 不应自动走出；回到户外门 `(9,25)` 必须识别 `$39` 后自动 DOWN 一格。
- **到达后第一按键也要测**：室内落点正好位于可用 Warp `(7,2)`，原引擎碰撞出口还依赖 `wd736 bit2`，不能只验证步行上毯。新版本在 `EnterMap` 处理完目的地图和清场后调用 `IsPlayerStandingOnWarp` 重新上锁，允许刚入室/读档立即按 DOWN 正常出屋；但不把这一步改成主动自动迈步。只有出屋返回的室外实体 DOOR 应走 `PlayerStepOutFromDoor` 的自动 DOWN。
- 静态落点/控制流、差异补丁双向验证 ≠ ROM 编译 ≠ 手机实测。后续扩增同 Tileset 时需要重新按 Gold 的入口类别逐格分流，不以本轮的两格房屋合同替代通用机制。

## P6-INDOOR-004 — 修改二进制碰撞白名单必须同步检查 ASSERT（2026-10-28）

- `gfx/tilesets/johto.tilecoll` 从 `[03,04,05,06,40,5B,FF]` 扩至 `[03,04,05,06,37,40,5B,FF]`，实际从7B变8B，`data/johto_pilot_runtime_assets.asm` 仍断言7B，造成 `main.asm -> data/johto_pilot_runtime_assets.asm(19)` 汇编中止。此前 P6-Fly 也曾漏加第6条4B地图记录；都说明正反向 git apply 通过不代表项目断言通过。
- 正确修复是保留 `$37` 和结束符 `$FF`，将字节长度断言更正为8；读取函数 `CheckTilePassable` 用 `$FF` 哨兵终止。交付前逐文件实际数 `INCBIN` 长度并检查配套断言，逐项检查活动图的索引表；不通过删除 ASSERT、取消哨兵或直接恢复旧资源逃避问题。AI 不自行链接/编译 ROM；静态结论不冒充红蓝构建成功。

## P5-DOC-008 — 已通过静态检查不等于真实地图验证

- 30号道路 Header 编译错误说明仅搜索 ASSERT 字符串不能证明连接记录确实完整；每条方向记录须按11B字段逐项核算并在真实地图跨越时检查视觉。31号道路树林残影还要检查屏幕可见预览条带，而非仅计算读写边界。
- 本次用户五张地图跑图、树林及跳崖的反馈支持当前已开放户外链；未来室内 Warp、不同 Tileset 和高 ID 地名牌仍必须在首次实际接入时单独验证。较拥挤的 Bank `$1C`、`$3D` 不应继续随意塞代码。

## P5-ROADS-001 — 连接 Header 与道路预览条带必须逐字段核对

- 每个方向连接记录是11B，首字段必须为 `db JOHTO_RUNTIME_MAP_HANDLE`。Route30 从单 SOUTH 扩展为 NORTH|SOUTH 时曾漏掉 SOUTH 的首字段，造成33B与34B断言不符；正确修复是补字段并保留 ASSERT。
- Route30 为10×27，Route31 为20×9，Gold 横向偏移10个地图块；连接只复制有效重叠的10列×3行。核对源读取索引、目标 padded-map 写入索引、两格通路和封闭边界；不能只看 ASSERT 或无条件加宽连接。
- 用户已实测30↔31往返、树林显示与跳崖正常；这是本次实际验收证据。未开放门房/洞穴、多 Tileset 与其余地图不随之自动验收。

## P5-FRAMEWORK-001 — 地图身份、显示地标和运行句柄不能混用

- `region + stable local ID` 是持久地图身份；Town Map 地标索引是另一套编号，不能直接把 stable ID 当浏览索引。
- `$FC` 是共用运行时载入句柄，不是城都地图 ID；`$FE` 保留渡轮目标语义，`$FB` 是登记式 Warp 的选择器。不要把这些控制值写进稳定地图身份或直接复制参考分支旧 Warp 目标。
- 名称牌不得再用 `$F8 + stable ID` 单字节临时键；必须比较完整地区与 ID，不能为了放开 ID 8 只删除断言。
- 登记式 Warp 当前没有真实路由。未知或未激活目标必须 fail-closed；首次接入室内图时要实测目标 Warp 序号、落点、返回和存读档。

## P4-DOC-007 — 城都 Fly 登记及 Bike Song 的跨功能入口陷阱

- **Fly 表汇编作用域**：RGBDS 中以点开头的局部标签绑定在最近的全局标签下。P4-002 在11组 `.nameX/.warpX` 之前误插全局结束符，导致22条未知符号；修复时保留同一作用域并对11条目的结构长度断言，不能仅靠补丁 apply 判断链接通过。
- **到访解锁时机**：Johto 运行链跳过 Kanto 原地图装载分支。到访事件位必须由 Johto 实际加载入口写入；否则 Fly 地标虽显示，按 A 却不能确认。合法飞行目标仍须同时满足已到访、已激活地图及有效落点。老 `$E7/$F4` 城都地图别名不可恢复。
- **Bike Song Off 保留播放进度**：从 SELECT/背包上下车时，不能调用 `PlayDefaultMusic` 试图“重播当前地图曲”，因为它会清音乐标记并从头开始。Off 的骑车状态切换应直接保留当前 BGM；On 与真正换地图的音乐切换仍走原流程。RBY/GSC/Random 共用这一门禁。
- 静态检查可以定位符号、范围与原接口，**不能替代正式 Red/Blue 链接及手机实测**；当前无 P4-006 新 MAP 证据。

## P3-DOC-006 — 城都 Town Map 调色板与飞行身份的防回归规则

- 切换地图图像并不等于切换调色板：旧 TEST-230 仅加载城都 Town Map 像素数据，却沿用 Kanto 的 RGB 颜色与 64 图块 palette ID 表，导致明显失色。接入新地区时必须成套迁移 RGB 表和 palette assignment 表，并在普通地图和 Fly 两个入口核对地区选择器；关都既有色表不能被覆盖。
- Fly 列表地标索引与物理地图身份不同；城都有效目的地必须以 `(region, stable local ID)`、已激活 Header 和安全 Warp 共同验证，不能拿旧 `$E7/$F4` 地图编号或未激活的可浏览地标当落点。目前 45 地标可浏览，但只有若叶镇是可落地城都点。
- 户外人物无缝跨图时应复用参考分支共享 sprite set，避免更换 tileset 图形槽位引起乱码；测试用贴图人不得作为 Gold 正式 NPC 提交。遇敌、捕捉教学、昼夜、自行车等是未来独立功能，不要为了地图收口开启。
- **验证限制**：TEST-231 用户认可 Route29 地图配色；并没有完整四 ROM/MAP、飞行地图专门的最终版配色、全部边界显示验收。旧导出 MAP 属 TEST-226，不能作为本轮空间证明。后续新增地图必须重复源码结构、连接可达边界、最新 MAP 及设备显示检查。

## P2-006 — 新增 Tileset 必须同时补齐两种 Palette 表（2026-10-27）

- 城都 Tileset ID 28 在 P2-005B 注册后，若 `MapPaletteSets` 少一行 8B 或 `MapPaletteAssignments` 少一行 96B，运行期可能越过表尾读到后续 `RoofPalettes` 等数据；图形显示异常不能只归咎于地图 Block 或 Header。
- P2-006 已给两表补齐对应城都行并加表长 `ASSERT`。这属于**确定的静态越界风险修复**，不是 P2-005D 花屏已经实机解决的证据。P2-005D 临时开启的 `$FC` 入口/B+SELECT 调试路径已撤销，禁止只为测试 Palette 将其直接恢复。
- 后续新增任意 Tileset 时，成套登记 Header/GFX/Blockset/Collision、Palette Sets、Tile Assignments 和 MAP 检查；城都第一次激活前先保证真实地图连接、碰撞、事件、Warp、存读档和 Fail-closed 活动槽位一致。

## ROM-5.62.211 / TEST-218 — 跨 Bank Kanto Header 指针迁移的调用约定

- `MapHeaderPointers` 原本在 ROM0，占 248 × 2 = 496B；移至扩展 Bank `$40` 时必须保持 248 项**次序、指针与地图 Header 所在原 Bank**不变。只搬运表的位置，不能连带改变 Kanto 地图编号、Warp/连接、存档镜像。
- `callab` 实际设置 `HL` 和 `B`，经 `Bankswitch` 后 `A` 用于切换新旧 ROM Bank，所以 **不能用 `A` 跨调用传入 wCurMap**。稳定传参是 `E=wCurMap`，目标例程读取 `E`，返回 `HL=HeaderPtr`；Farcall 返回后，`Bankswitch` 将 ROM Bank 恢复到 `SwitchToMapRomBank` 事先设置的地图 Bank，方可安全读取 `[HL]`。`BC` 不承诺保留。
- 104 提交参考包中的 `HOME-5.62.121` 曾因错误传 `A` 导致用户进入室内/Fly 花屏甚至死机；参考的是第 007 提交最终修正版 `HOME-5.62.122` 的 ABI 思路，不是失败试作。TEST-217 的 `LoadMapHeader` 尚无城都地区分支，不能原样照搬参考项目包含 `ResolveRegionMapHeader` 的调用点。
- 2MB 依赖 Bank `$7F:$7FFF` 的容量边界和 MBC3 可访问 Bank `$40`；不能仅凭 `BANK[$40]` 声称产物恰好为 2MB。扩 Bank 后可能改变浮动 ROMX 的排布。P1 正式红蓝 MAP 显示 ROM0 各余 824B，Bank `$40` 的表与查表例程位置均正确；独立测试红蓝 MAP 及 ROM 文件头仍待核验。

---

## TEST-217 / DOC-218 — Disable 旧状态与测试假阳性；不要错误扩大边界

- 成功 Transform 复制新招式后，原 Disable 以旧槽位标记继续存在会错误禁用新招式；正确的是仅在**成功路径**一次性清除**施术者** `w*DisabledMove` 与 `w*DisabledMoveNumber` 两字段，失败时保持状态，之后重新受到 Disable 仍生效。共享 Transform 内核同时覆盖手动与自动 Imposter；正常自动入场原本多已清状态，不必为不自然旧状态编造必要性。
- 测试程序若只检查 Disable 计时／槽位字段，然后马上写入新的被禁用招式编号，会覆盖编号残留而导致**假阳性**。TEST-217 16/17 两字段均为零才允许进入“旧状态清除成功”后续注入路径；用户录像主路径和故意破坏一字段的反例注入不是一回事。
- 正常宝可梦仅**第一槽**一招、且被禁用时，旧 `AnyMoveToSelect` / `SelectEnemyMove` 应回退 Struggle；TEST217.mp4 的 19、20 看到了双方 Struggle，未卡住。敌方异常数据“第 1 槽空、非空后槽唯一被禁用”的潜在无限重选不等于此项通过，也不是同回合 Transform 成功后的自然流程。
- TEST-217 21 使用真实 Disable 命中后，录像文字为 `Enemy Mew's Disable was disabled!`：它禁用的是复制后的 **Disable**，并没有禁用 Tackle。不能因为敌方随后能用 Tackle 就误判 Disable 失效，也不能宣称“禁用 Tackle 的后续选择”已实测。
- TEST-214 05/09 的 0 PP 非空招式仍可被野生敌人随机选中，07/14 同类风险未修；禁止为了稳定测试顺手改变正式敌方 AI。文档收口不得把此前待验条目自动全打勾，联机、MAP/Bank 和完整 ROM 构建证据分别保留。

---

# RPP Development Pitfalls

## TEST-216 — Transform 成功后必须清除施术者旧 Disable 槽位状态

- `Disable` 保存的是槽号与持续回合（`wPlayerDisabledMove` / `wEnemyDisabledMove`），另有 `w*DisabledMoveNumber` 供选中招式检查。Transform 会替换四个招式槽；如果成功后保留旧标记，旧槽里的新复制招式会被错误禁用。
- 只在 `TransformEffect_` 确认成功并完成复制后，清除 `H_WHOSETURN` 当前施术者的两个 Disable 字段。不要清目标侧状态；不要在失败分支清；不要在后续每回合清，以免后续新施加的 Disable 失效。
- 测试必须双向：玩家手动 Transform（第二次菜单路径）和敌方 Transform（自动续招路径）。敌方续招会绕过普通根行动状态检查，必须固定复制槽并观察下一回合 AI 对 Disable 槽的处理，不能只看当回合攻击动作。
- TEST-216 场景 16/17 直接注入确定的旧状态，并在成功后注入另一个槽位的新状态，隔离随机命中率；18 验证 Transform 失败时状态保留。夹具只在 `BATTLE_TEST_BUILD`，不改正式 AI 或 Disable 的随机选择规则。


## TEST-212 — 双向场景必须核实真实动作和身份位（待 ROM 验证）

- 只在测试 ROM 构造速度。玩家 `wPartyMon1Speed` 要先被 `LoadBattleMonFromParty` 复制，野战敌方 `wEnemyMonSpeed` 需在 `LoadEnemyMonData` 后、第一轮行动比较前设置。`03/04` 后手成功与 `06/07` 半无敌失败是独立测试，不能混为一种结果。
- 旧 TEST-212 以 Fly PP=0 + Splash 可用尝试避开双 Fly，**后续证据确认该假设不能保证野生 AI 不选 Fly**；参见下方 TEST-215 零 PP 测试夹具结论。
- EXT 复制按槽身份位操作：敌方槽 1 的高 nibble 是 `$20`；玩家槽 1～3 是低 nibble `0x0e`。玩家活动侧必须在载入战斗数据后再注入，否则 `LoadBattleMonFromParty` 可能覆盖。`13 E-EXT` 的回合边界 callback 先确认场景有效，再注入；是否在变身前保留必须用 ROM 复核。
- `15 AUTO-BIDIR` 使用真实训练师后备 Ditto 与 `SwitchEnemyMon`，只在本回合 TrainerAI 行动槽消费一次（Carry 跳过攻击），不在回合边界直接换人；这不代表 AI 自主决策换人。
- 敌方五个测试场景固定的复制槽号必须在 `IF DEF(BATTLE_TEST_BUILD)` 中，正式版及 Link 的随机非空槽逻辑不被影响。永远明确区分通过静态核对和用户实际运行验证。

This file is the persistent, Git-tracked record of repeatable development failures and prevention rules for this branch.

`RPP_PROJECT_CONTEXT/` is generated by RPP Mobile during export. Do not store durable project history only in that generated directory: a later export can replace it. When a reusable failure mode is discovered, add it here and summarize any version-specific details in the current handoff.

## ANIM-5.62.198 — Power Gem 轨迹、坐标与来源素材复用

- PC `PowerGemFunction3` 的 `BattleAnim_StepToTarget(A=8)` 为每帧 X+8/Y-4；198A 按固定目标 Y 钳位导致后段水平横飞，必须保持持续斜飞。PC 动画对象坐标已是 OAM 坐标域，不应再盲加 8/16 像素。
- 攻击方向的出生高度与发射向量要分别验收：198B 的敌方 `Y'=136-Y` 令石头升起过低；正式敌方使用 198A 的 `Y'=Y-40` 升起、悬停，再从同一点向左下发射；己方轨迹不受此修正影响。
- 复用图形须同时核对 Rock Throw 图块、四精灵拼接、VRAM 和 OBJ 调色板；图形一致不意味着坐标、运动与发射顺序自动一致。用户已认可 198C 录像的视觉效果，不能把源码检查冒充双 ROM 链接与 MAP 验证。

## ANIM-5.62.197 — EXT 多重追加效果与固定 Bank 余量

- 单一 `MoveEffectPointerTable` 效果字段不足以表达两个独立判定：EXT02 先复用攻击下降通用处理，再按完整 `wExtendedActiveMoveOrdinal` 执行独立混乱判定；保留效果字段，不允许普通低字节同号招式串入。
- Bank `$0F` 旧 195 MAP 仅余 7 字节，入口用 7 字节 `callab` 网关，主体在 `$3E`；**旧 MAP 不证明 197 已链接**。注意 `wMoveDidntMiss` 的替身命中标记及远调用可能改写 HL／A。
- 增加 stat-down 效果可能改变普通伤害反馈类型，EXT02 必须保留原动画的受击反馈和既有横震，不重引 194D。

# RPP Development Pitfalls

This file is the persistent, Git-tracked record of repeatable development failures and prevention rules for this branch.

`RPP_PROJECT_CONTEXT/` is generated by RPP Mobile during export. Do not store durable project history only in that generated directory: a later export can replace it. When a reusable failure mode is discovered, add it here and summarize any version-specific details in the current handoff.

## TRF-5.62.208 — Transform 同回合续执行必须沿用 Mimic 的返回约定

- `TransformEffect_` 本身负责判定与复制；只有**手动根行动**成功时，`TransformMoveFollowup_` 才安排一个复制招式。入场 Imposter 仍直接调用 `TransformEffect_`，不能走玩家选招或额外出招路径。
- `ResidualEffects1` 的 `JumpMoveEffect` 通过 `call _JumpMoveEffect` 留下临时返回地址。跨 Bank helper 要返回 `HL=CheckIfPlayerNeedsToChargeUp` / `CheckIfEnemyNeedsToChargeUp` 或对应 `Execute*MoveDone`；Bank-F 网关必须先 `pop bc` 丢弃该临时返回，再 `jp hl`。不要重新进入整段 ExecutePlayer/EnemyMove，否则会重跑状态检查、重复扣 PP 或制造第二个行动。
- `callab`/`Bankswitch` 不保证保留 `A` 与 flags，因此 `TransformEffect_` 成功/失败用 Carry 明确返回（共享自动入口会恢复调用前的 AF），follow-up 的续执行地址通过 `HL` 返回。任何新跨 Bank 路径都要复核实际 Bankswitch ABI，不能只看 `call` 外观。
- 玩家选招后必须用 `GetCurrentMove` 重新装载当前招式数据，使 `wPlayerMoveNum`、效果、威力和 EXT sidecar ordinal 对应新槽；测试构建还必须同步 `wTestBattlePlayerSelectedMove`。敌方/Link 路径设置正确的 `w*MoveListIndex` 与 `w*SelectedMove` 后再加载数据。根招历史 `wPlayerLastSelectedMove` / `wEnemyLastSelectedMove` 不应被子招覆盖；否则 Mirror Move/Metronome 语义会改变。
- 本版静态实现不代表 ROM 已链接或联机已验证。至少检查：成功选择并执行复制招式、失败不续执行、Transform PP 与子招临时 PP 分别扣一次、EXT 身份、目标 Fly/Dig、动画 ON/OFF 与异常全空招式列表回退。

## MOVE-5.62.187 派生招式身份与临时测试 SECTION 放置（185～187 同组）

- **Mimic 和 Mirror Move / Metronome 的身份生命周期不同**：前者复制后会替换使用者的战斗临时四槽及 sidecar；后两者只在当前执行子招的 `wExtendedActiveMoveOrdinal` 生效。绝不能仅凭子招低字节等于旧招 ID 就重解为普通招，也不能把 Mirror/Metronome 的临时身份写回 Party/SRAM。
- **记录根招与执行派生子招不能混用**：Mirror Move 需要对手最后一条可执行根招的低字节及对应扩展身份；记录时按当前行动方的真实槽验证，临时子招重载须走已解析 ordinal 的数据完成器，不能再调用根槽解析覆盖其身份。子招 PP、NZ 退出语义与 Mirror Move 伤害标志必须按现有调用约定保护。多层嵌套／换人旧记忆仍待独立游戏测试。
- **临时测试帮助例程必须放在安全 SECTION 边界**：原 186T 在 `main.asm` 的固定地图结构中途 `INCLUDE` 自带 `SECTION "...", ROMX` 的脚本，造成后续玉虹大厦地图数据可能进入错误 Bank，用户实际遇到满屏乱码；用户经 186T-003 修复后复测地图恢复。测试辅助 `SECTION` 应在 `main.asm` 末尾安全位置或明确独立段，禁止插入固定地图的头、对象、地块等连续数据之间。补丁 apply/check 通过**不能**证明 Bank 布局正确。
- **挥指池包含身份而不只是字节**：旧普通池 1..250 排除 Metronome/Struggle，新增 EXT01..40 必须作为独立身份抽样；187T 强制 EXT07 的双向实测证明执行主路径，不证明随机数均匀、链接战 PRNG、全部扩展效果或真随机概率。

## MOVE-5.62.179 TM/HM／教学师“已学”检查不能只比招式低字节

- 原 `CheckIfMoveIsKnown` 只逐槽比较 `wMoveNum` 与单字节 Move ID，会把扩展 ordinal 14 误判成普通剑舞、扩展 ordinal 7 误判成普通火焰拳。对普通招式的已学判断，必须同时核对当前 Party 成员的每槽 sidecar 位；扩展身份碰撞后**继续扫描其它槽**，不能立刻报告已学或直接结束。
- `wExtendedPartyMoveFlags` 为逐 Party 成员的四位 mask，每前进一槽同步右移一位；新代码取 Party 索引构造地址时不要破坏调用方寄存器，且要在「已学／未学」分支上保持原 Carry 协议。学招流程、收费及可学性判断各有自己的约束，修复共用判重不代表其它路径已验收。
- 临时授招 NPC／地图脚本只在可撤销的 T 测试补丁中存在；正式提交必须确认这些临时改动不在工作区里。浮动 ROMX SECTION 可能重排，MAP slack 为 0 既不能独立证明溢出，也不能代替重新链接。

## MOVE-5.62.178 学习提示名称需共用完整身份和确定的起始指针

- 177T 临时地区扩展学招实现单独复制了 172 的名称准备过程，漏写 `ld de,wcd6d`，导致学招提示显示 `t!`，而战斗／详情无异常。加载器返回时 `DE` 已移动到名称尾部，不能直接送 `CopyStringToCF4B`；普通招和扩展招统一将最终名称缓冲指针归一化。
- 普通压缩学习表和地区独立等级表格式不同，应分别解析后将候选 `(D=低字节,E=扩展序号)` 交给一个共享授招入口；已学比较同时检查槽内身份位。`callba` 会占用 `B/HL` 并破坏 `A`，调用方必须保护压缩迭代器、地区表游标及 `DE`；公共端要保存原寄存器并在任何返回（已学、无效、拒绝／完成）清理临时扩展 ordinal。
- 不要为临时测试入口在正式主路径上再次复制已学判断、提示名称和 `predef LearnMove`。共享函数是代码固化，不意味着未实测的特殊招式、回忆师或其他外围系统已验收。

## MOVE-5.62.177 地区形态普通招式判重也必须核对 sidecar

- 普通升级／回忆已在 176 读取 `wExtendedPartyMoveFlags`，但地区形态分别走 `RegionalFormTryLearnLevelMove`／`RegionalFormPrepareRelearnableMoveList` 的独立扫描。**不能因为候选来自普通一字节地区学习表，就只 `cp` 技能低字节来判断“已学会”**：扩展 ordinal 1 与普通 ID 1 同字节，必须额外确认对应槽的扩展位为零。
- 升级流程的 `D` 保存待学普通技能 ID，重新构造 `wExtendedPartyMoveFlags + wWhichPokemon` 地址时必须保护 DE；回忆流程在每个候选开始时重新初始化四槽 mask 位迭代，且保持当前等级、候选计数与 ROM 学习表指针原有的栈配平。不要把 `wExtendedActiveMoveOrdinal` 的 NPC 临时用途当成战斗状态迁移设计。
- 173 正式版清理了用于测试的技能获取／回忆来源；要验证同编号过滤必须单独创造可撤销测试条件，而不是把空列表当成通过。静态源码、逻辑枚举与 MAP 余量都不是实际 ROM/用户验收。

## 战斗 PP 道具成功退出与队伍菜单结果文字（TEXT-5.62.165）

- **不要让一次成功的战斗道具操作重入连续选择**：`ItemUsePPRestore` 成功时已经扣除道具并设置 `wActionResultOrTookBattleTurn`；如果因背包尚有库存进入下一轮选择，随后取消可能覆盖这个结果。保留场外连续使用，战斗中只在成功后走已存在的结束出口；未使用／无效果与取消仍按原失败路径处理。用户报告 163 相关回归无异常，但极端组合仍需按需验收。
- **连续使用升级道具返回队伍列表须重绘覆盖区域**：升级的 `PrintStatsBox` 覆盖了队伍图块；只用 `GoBackToPartyMenu` 可能遗留能力值窗口的两条竖边框。`ItemUseMedicine .returnToParty` 使用 `GoBackToPartyMenuClean` 重建底图，**不能错误地删除底部正常的 `Use item on which Pokémon?` 提示**。
- **文字延迟与画面传输是两个独立开关**：`RedrawPartyMenu_` 的 `wd730` bit6 会关闭逐字延迟，`H_AUTOBGTRANSFERENABLED = 0` 则可能让延迟执行后仍整句一次显示。只对 `$F0`～`$F8` 道具结果提示解除延迟并在 `PrintText` 前允许 BG 更新；固定菜单文字仍即时输出，退出时恢复 `wd730` 原值。用户已验证升级糖果的 Fast／Normal／Slow 三档及先消息后能力面板的顺序；不要外推成所有物品文本已专项实测。

## Cross-bank calls and register lifetime

- `CALLBA`/bank-switch wrappers must not be assumed to preserve `A`, `BC`, or `HL` unless the exact adapter proves it. Bank restore can consume `A`, and `CALLBA` itself uses `HL` for the far target address.
- `EVO-5.62.271` passed a Party-menu tilemap pointer through `HL` across `CALLBA`. The helper then treated the far target address as the UI destination, so `Able`/`Not able`/`LvXX+` disappeared and writes could hit ROM/MBC control addresses, disturbing the active bank. Pass such pointers in a verified register or save/restore them explicitly.
- The wild/fishing producer work already proved the same class of ABI issue: do not return critical form/source identity through `A` across `CALLBA`; protect live `BC`/`HL` when required.

## Intro SRAM checksum vs. VBlank audio SRAM bank switching (INT-5.62.133)

- At boot, `LoadStartupMusicOption` reads the saved settings using a short interrupt-disabled SRAM Bank 1 section; the later intro save gate scans thousands of bytes and can be interrupted. The audio update calls `OpenSRAMForSound`, selecting SRAM Bank 0. Checking Bank 1 without a guard can therefore falsely report no Continue despite a valid save.
- When reading Bank 1 over many frames, guard the whole name/checksum check with `wHaltAudio=1` and **restore its previous value on every exit**, as `IntroHasContinueSave` now does. Do not assume a single initial `MBC1SRamBank` write persists across VBlank. Ensure SRAM mode and enable are restored, and return Carry unchanged to the distant caller.
- Compare the intended Continue predicate with the main menu's `CheckForPlayerNameInSRAM` and `LoadSAV` path. The intro gate is read-only and does not replace actual save validation/loading at the menu. Code inspection and patch checks alone are not runtime validation.

## WRAM scratch and bank boundaries

- Unnamed WRAM is not automatically free. Check symbols, raw address spans, string/buffer copies, unions, stack use, and WRAM-bank lifetime before borrowing scratch.
- `wEnemyMon` begins at `$CFE5`; only 27 bytes remain before `$D000`. On CGB, `$D000+` is banked WRAM. Never copy an arbitrarily long evolution/learnset block into `wEnemyMon` just because battle code is inactive.
- `EVO-5.62.273` initially copied the 30-byte maximum stock evolution block into `wEnemyMon`. `EVO-5.62.27` replaced this with a byte-stream reader using the existing two-byte evolution stream pointer plus one-byte `wBuffer` scratch.
- Do not `push` values, change `rSVBK`, then `pop` unless the stack is proven to refer to the same physical WRAM bank throughout.
- Party gender palette bank-safety rule (ICO-5.62.73): `wPlayerGender` lives in WRAM bank 1, but `SetPal_PartyMenu` runs with bank 2 selected and the stack is at `$DFFF` in banked WRAM. Never `ret`/`pop`/`call` while bank 1 is temporarily selected; restore the caller's bank entirely through registers first, or the Party HP BG palette writes may go to the wrong bank (male screenshot: grey HP bars). Keep Party icon OBJ palette 0 distinct from BG HP color palettes 1/2/3.

## RGBDS labels, symbols, and old failures

- RGBDS local labels belong to the nearest preceding global label. Grepping only for a `.local` spelling does not prove scope correctness.
- **Hyper Voice 局部标签复核（ANIM-5.62.74）**：源分支早期曾把两个 `.draw` 放入 `PlayRubyHyperVoiceAnimation` 的同一全局作用域，导致 RGBDS `already defined`。当前以 `.drawWaveLayout`、`.drawImpactLayout` 区分；新改动须按全局标签作用域查重，同时检查 INCLUDE 路径，而不能只检查文件 INCLUDE 次数。
- Previously seen: `'UpdateMapNameSign.gameCorner' already defined at main.asm(2892)`. Check global/local ownership before introducing similarly named labels.
- Previously seen: `engine/menu/main_menu.asm(440): Unknown symbol "PrintNumOwnedMons"`. Run symbol/reference completeness checks after relocation or deletion.
- **DEX-5.62.118 / S4-001 failed link (`RegionalDexOwnedAction.missing`)**: inserting the global `RegionalDexOwnedSlotAction:` between `jr nc,.missing` and `.missing` silently changed the latter local label owner. S4-002 keeps the slot entry under `RegionalDexOwnedAction.slot` and calls it by a fully qualified local label. Before delivery, resolve every new/modified local branch against the *nearest global label*, including targets below the insertion point; token-presence grep and `git apply` replay are insufficient.
- **S4-001 additional static fault**: `callba IsPokemonBitSet` overwrote HL even though that function takes its bitfield pointer in HL. S4-002 invokes `FlagActionPredef` with the bitfield address and dex bit index explicitly. Review all `callab`/`callba` argument registers before a cross-bank call.
- If changing vertical shake behavior, review `.StageBlankBG0TopRowForEnemyFeedback`; Iron Tail/Steel Wing previously left display residue around this path.

## Text command boundaries after inline numbers (DEX-5.62.131)

- `TX_NUM` 是顶层文本命令（由 `TextCommandProcessor` 派发），结束后会回到“读取下一条顶层命令”的状态；`para`／`done` 的 `$51`／`$57` 则是正在进行的 `PlaceString` **字符串内**控制码。二者不能在 `TX_NUM` 后直接相接。
- `DEX-5.62.130` 地区研究页曾显示 `Seen: 0/42` 后卡住：紧随数字的 `para` 被误当作顶层命令；结尾的 `done` 也存在同样错误。`DEX-5.62.131` 在这两处先写 `text ""`（生成 `$00` 顶层文本入口）再写 `para`／`done`；它重新进入字符串解析，不需要改统计逻辑。静态修复已完成，但**该版本的修复后实机表现仍待用户确认**。
- 每次使用 `TX_NUM`、`TX_RAM` 等可结束字符串处理的宏时，核对后续是顶层命令还是字符串内控制符；使用已有原生文本宏写法，不把源码逐行顺序误认为解释器状态连续。字节增量及 MAP 余量最终以用户运行链接器结果为准。

## Regional sprites require live data references (FORM-5.62.111)

- Adding `pic/bmon/*_hisui.png` and matching back PNGs does not register a usable form. Verify the entire chain: `FORM_*` + marker → 16-byte `RegionalFormDescriptors` record → full `MonBaseStats` header (including `.pic` size, both sprite pointers and `BANK(...)`) → independent graphics `INCBIN` → form-producing encounter/party logic. Without this chain, the PNGs are inert files and must not be called an in-game feature.
- Bind wild forms by map and exact slot only after verifying both Normal/Hard encounter tables and `data/wild_mons.asm` map mapping (Safari West uses `ZoneMons3`, not East). Keep stock and Alolan assets and descriptors intact. A source-only review cannot certify bank capacity or runtime graphics.
- `regional_form_guard` 的第四参须引用该普通物种在 `data/baseStats/*.asm` 声明的 `*_CATCH_RATE` 常量。新增描述符前逐一核查符号是否已定义；未定义时保持原 `db` 数值，补同值 `EQU`，不可删掉防冲突断言。通过断言只说明 marker 与普通捕获率没有冲突，**不代表新地区形态捕获率已经定稿**。
- `ANIM-5.62.111` 新增九种地区形态的全部数值、招式、进化、调色板、图鉴及遭遇配置均为占位；正式调整须后续统一处理，不在没有 ROM／实机验收时把表驱动数据登记误称为正式定稿。


## 历史 PNG 与 PAL 成套恢复（ANIM-5.62.113）

- **先比对图片的真实身份，再迁移颜色**：正背 PNG 的文件名一致不代表像素相同。保留原始提交中的图片与 PAL 对应关系，按当前 PNG 的 Git Blob／像素证明它来自旧版的换图前或换图后，避免把另一版本验证过的 PAL 错套到已恢复的图片上；普通与地区形态独立核对。
- **逐组最小更新**：只有当前 RGB555 与匹配图片的旧版已验证 PAL 不一致时才修改；分别检查普通与异色，已相同的组原样保留。修复仙子伊布（普通／异色）、多边兽Ⅱ、波克基古、自爆磁怪（普通）及 8 种首批地区形态（普通／异色），累计 12 种、21 组 PAL；不复制未变的值，不动 PNG／Species/Form。
- **蛇纹熊特例**：旧版替换前四张普通 Zigzagoon／Linoone 图片配棕色系；旧版替换后的图片对应当前 Galar Zigzagoon／Linoone，配紫红／灰色系。只恢复**伽勒尔**形态旧 PAL，不改普通形态；PC18 的 18 组源 `.pal` 也不批量覆盖。伽勒尔呆呆王未找到该旧版同图成套 PAL，不凭相似配色臆造“已验证”。
- **审查边界**：用户确认配色观感可以标记视觉方案定版；源码／符号／补丁检查不等于已测试所有 ROM、前后图、异色战斗／图鉴或读取存档路径。需要代码变动时应另起版本并复核 PAL 表排列、RGB 0～31、原有 100755／100644 文件权限。

## Substitute boundary and derived move identity (MOVE-5.62.147)

- In shared `AttackSubstitute`, `SUB` sets the zero flag when damage exactly equals the Substitute HP; `ret nc` alone misses this break. Check both zero and borrow before retaining a Substitute. Regression-test both attackers and multi-hit moves.
- In automated Test Battles, `GetCurrentMoveID` can return the root test move while Metronome/Mirror Move have already selected a derived move. Use `GetStatSideEffectMoveID` consistently for derived-move probability and type-immunity decisions. That helper lives in Bank `$3E`; Bank `$0F` callers must use `callab` and preserve any return value in `DE`, since `Bankswitch` clobbers `A/BC/HL`.
- **MOVE-5.62.148 Draining Kiss Substitute 实伤**：共享 `AttackSubstitute` 击破替身后会清除吸血效果，且保留攻击预计算 `wDamage`。Draining Kiss 击破替身时通过余下的替身 HP 与 `wDamage` 还原替身受击前 HP，只为本招保留回复效果并将其回复依据设置为实际被替身吸收的伤害；未击破时原伤害本就小于替身 HP，无需额外处理。其他 Absorb/Mega Drain/Giga Drain 等吸收招式仍保持原规则。静态检查不代表 ROM 实测。
- **战斗多段替身承伤文本**：`AttackSubstitute` 会对每段分别执行，不能无条件打印 `SubstituteTookDamageText`。首击时 `AttackingMultipleTimes` 尚未设置，需按三种多段 effect 识别；后续用对应 `wPlayerNumAttacksLeft`／`wEnemyNumAttacksLeft` 判断最后一击。任何一段会击破替身时，先显示一次 `SubstituteTookDamageText`，再显示 `SubstituteBrokeText`；若替身整招未破，只在最后一击显示一次承伤文本。通用 Critical／效果相性与 Hit-X-Times 提示已由其他路径分别延迟／汇总；Rage 增攻与双针中毒属于逐击效果，不要一概延迟。回归需覆盖玩家与敌方调用方向，不要求精确 HP。

## ROM bank placement

- **ANIM-5.62.111 地区形态 bank $34 拥塞**：撤销地区形态提交后的 5.62.110 自带 `patches/rppred.map` 显示 bank #52（`$34`）仅剩 `$37` 字节。新增 9 组完整形态资料与 9 条描述符不可直接追加至 `$34`；链接器先报 `Slot Machine Tiles 2` 无法放置只是受害段。
- **按 map 迁移、保持 bank-aware ABI**：`Battle Type Effectiveness`（`$274`）、`Slot Machine Tiles 2`（`$180`）、`Poke Flute Party Wake`（`$68`）、`Fly Town Map Route20 Classifier`（`$DA`）已有 `callab`/`callba`/`BANK(...)` 调用约定，候选改为固定 `$30`；不要把 `RegionalFormDescriptors` 和扩展头数据拆开，现有描述符仅保存同 bank 16 位指针。
- **实际链接是最终验收**：旧 map 的空余字节和手工计算不能代替 `make map`，且 Red/Hard 都要复测。构建环境未安装 `.rgbds-version` 要求的 RGBDS 0.5.2 时必须标记为未编译，不能先做正式提交。


- Treat fixed Bank `$03` and `$34` as effectively frozen for new body logic. Keep only minimal hooks there and place larger new helpers in floating/roomy ROMX sections.
- A linker error naming the section that finally fails to place does not prove that section caused the growth. Find the section that actually expanded first.
- MAP slack is advisory, especially with floating sections; the linker result is the final authority.

- **自伤目标与 HL 前置条件**：`ApplyDamageToPlayerPokemon`/`ApplyDamageToEnemyPokemon` 的正常入口会检查目标替身，但混乱与跳踢落空反伤是行动者自身伤害，不应按对侧目标路由进入共享 `AttackSubstitute`。直接落入 `.realHP` 时，内部 `[hld]` 读取的是伤害低字节，**必须先设置 `HL=wDamage+1`**；错误的入口曾让自伤变成零伤害或错误秒杀。`callab/jpab` 后 A/BC/HL 的保存不能假定，需要在正确 Bank 内重设指针。与之无关的来袭伤害依旧走正常替身门控。静态证明不等于 Normal/Hard 构建通过。

## Substitute damage and drain effects (MOVE-5.62.148)

- `AttackSubstitute` treats exact-zero HP as a real Substitute break; check the equality boundary, not just overkill. The shared break path can clear the drain effect even when a move-specific rule must keep it.
- For Draining Kiss only, use `min(calculated_damage, substitute_hp_before_hit)` as actual Substitute HP loss, then apply its 75% drain (minimum 1 HP) even if Substitute breaks. Keep other drain moves on their existing 50% path; do not generalize move-specific behavior into the common routine.
- Review and numerical simulation are not ROM/link or in-game validation; preserve that distinction in `TODO.md`.

## Shared state and semantic aliases

- A historical status bit can have more than one meaning. `Transformed` was also borrowed by capture DV-preservation logic; treating it as proof that the Transform palette cache was valid caused the first-capture Pokédex/nickname black block. Cache validity now has its own state.
- Preserve established producer/consumer lifetime contracts unless a real bug is demonstrated. Do not replace proven scratch aliases merely to make the code look cleaner.

## Item-use eligibility and UI return flow

- Do not play a success/use sound or consume an item before all eligibility checks have passed. `EVO-5.62.27` now rejects both a non-matching evolution stone and a matching-but-under-level stone before `SFX_HEAL_AILMENT`.
- A failed evolution-stone selection is not an exit from the item workflow. After the failure text, return with `GoBackToPartyMenu` so the cursor/session stays in the Party selector; only explicit cancel or successful evolution leaves that selector.
- `wWhichPokemon` is not stable across Party redraws: `RedrawPartyMenu` iterates every Party member and leaves it on the last Party slot. During `ITEM-5.62.28` development, reusing that clobbered value as a Bag slot during repeat medicine use made later uses decrement an unrelated Bag entry and could exit when that unrelated stack reached zero. Preserve the Bag slot explicitly across redraws before calling `RemoveUsedItem` again.
- Do not add a long fixed post-animation delay to a repeatable Party-item loop unless the interaction truly needs it. Field medicine already has an explicit button wait after the HP/status animation; repeating the legacy 50-frame delay on every use made the continuous flow feel stalled.
- `MoveSelectionMenu` persists its zero-based cursor in `wPlayerMoveListIndex`, but persistence alone does not restore the cursor. The menu initializer must also load that value into `wCurrentMenuItem`; the PP-item move-menu path originally forced `wCurrentMenuItem` to 1 every time, so repeated PP use visibly jumped back to the first move despite preserving `wPlayerMoveListIndex`. Clear the saved index only when entering the move submenu for a newly selected Pokémon.
- For repeated one-move PP item use, display the question only on first opening a Pokémon's move submenu. After success/denial, print a non-blocking (`done`) result and reopen move selection directly; replaying the question immediately erases the result and visually flashes the textbox. The 4-move frame is six tiles high: with the bottom message frame starting at row 12, position it at row 6 (not the overlapping row 7 or the unnecessarily high row 5).
- Party move PP bytes store current PP in the lower six bits and the PP Up count in the upper two. Any full-PP/no-effect comparison must mask with `%00111111` first; `ITEM-5.62.28` applies this to Max Ether/Max Elixir so a full move with PP Ups is not falsely treated as restored.
- PP Up sets the one-use flag through `wUsingPPUp`, which is an exact WRAM alias of `wd11e` at `$D121` (see `wram.asm`); assigning either symbol writes the same byte. Do not flag the legacy `ld [wd11e],a` sequence as a missing flag without checking symbol aliases and the complete call path. `MENU-5.62.31` uses the semantic alias name in this one call site without changing the stored address or calculation.
- TM/HM `wTempMoveNameBuffer` aliases `wLearnMoveMonName` (`$D039`); `LearnMove` overwrites this temporary. When retrying the Party selector after abandoning teaching, reconstruct the original move name from `wMoveNum` rather than trusting the scratch buffer.
- `RedrawPartyMenu` does not erase overlaid move/TM window borders on its own. A light return from such a window should clear the tilemap while auto BG transfer is disabled, then redraw the Party before re-enabling transfer. Do not replace the initial Bag→Party icon-graphics load or Party→Bag graphics restore with a light return.

## Fishing entry, retry and dialogue contracts (FIS-5.62.90)

- **Result routing:** `wRodResponse=0` means no bite and may offer another cast; `1` enters battle; `2` reports no fish and exits. Keep the original rod encounter data, sounds and battle entry. Land setup waits 48 frames and retains the 84-frame fishing pose; Surf result uses a 94-frame delay without land fishing sprite/OAM.
- **Window lifetime:** the original fishing-result `prompt` handles the A/B confirmation. `CheckRepeatFishingRod` uses the existing visible textbox for `PrintTextAndYesNoChoice`, repeats Yes in a non-recursive loop, and closes once on No/bite/no retry/error. Do not reintroduce `Text2_EnterTheText` / `DisplayTextIDInit` into the first pass or close/recreate the textbox between consecutive Yes casts. The perceived delay between the no-bite A/B confirmation and the next question has not been proven eliminated.
- **Redraw guard:** a retry sets `wRepeatFishingRod` bit7 only while calling `UseItem`; `FishingInit` skips `ItemUseReloadOverworldData` for this synchronous handoff. Clear the marker on rejected uses. Ordinary BAG entry must still redraw, and the runtime-only marker is not the saved last-rod value.
- **SELECT routing:** land SELECT checks the refreshed facing tile via `GetTileAndCoordsInFrontOfPlayer` / `IsNextTileShoreOrWater`; a non-water tile still uses the bicycle path. Surf SELECT does not require a facing-tile test. Consume the shortcut's button state to prevent double actions. Persist the last deliberately used BAG rod in reserved save bytes `wLastUsedFishingRod` and `wLastUsedFishingRodMagic` (`$a7`); validate old-save data, rod ID and Bag ownership before casting.
- **BAG vs shortcut:** a deliberate Surf BAG item use normally has `wPseudoItemID=0`; SELECT and retry use the matching rod ID. `CheckFishingEligibleR2` accepts both legal values for Surf and keeps the original land-water validator. BAG switching updates the saved last rod, but repeated and SELECT casts do not.
- **Repeat dialogues:** the Vermilion, Route 12 and Fuchsia rod givers replace only the post-gift `TX_FAR` text with shared Bank $3B teaching. Safari Secret House HM03 uses a different post-gift `TX_FAR` target with the original Surf explanation and new fishing guidance. Leave first-gift, refusal, Bag-full and `EVENT_GOT_HM03` checks/award intact; never include `ResetEvent EVENT_GOT_HM03` test-only code.
- **Surf bite feedback:** only a bite applies 10 Y-coordinate toggles separated by 3-frame delays and then `predef EmotionBubble`, without loading a land rod pose, altering the Surf state or reserving fishing OAM slots. Even toggles restore the original Y. Missing fish and no-bite display only their result text.
- **Test boundaries:** user reports normal BAG/shore/Surf rod switching and retry behavior, and approves Surf bobbing. Full-Bag gift, individual Surf mounts, unusual saves, BG/OAM stress and the remaining A/B question-transition delay are not certified by these reports. Static source inspection does not replace ROM execution.

## Low-HP warning / battle SFX timing (VTA-5.62.43, unresolved)

- In the shared battle audio path, `WaitForSoundToFinish` may return early during low-HP `Danger`; `PlayApplyingAttackSound` can therefore begin a normal hit SFX while a custom animation tail is still sounding. Review Volt Tackle and Spark first, then other recently imported animations. This is a potential cross-move overlap, not independently confirmed runtime failure for each move.
- Compare normal vs red HP for both users and target-hit feedback. Keep the low-HP alarm audible; do not add unbounded waits or alter the audio engine during the VTA-5.62.43 animation-only integration.

## Party icon mapping columns and whitespace-only closeout (ICO-5.62.59)

- `data/mon_party_sprites.asm` is a two-Pokémon-per-row lookup (`db FIRST, SECOND ;SpeciesA/SpeciesB`). When adding or cleaning rows, follow a **single consistent column layout across the entire `MonPartyData` table**: start each first constant at the same column, align the first comma, start each second constant at the same column, and align the semicolon that starts each species comment. Use the established indentation and padding; do not let long `SPRITE_*` names shift separators or comments to new columns.
- Current table uses a tab before `db`, a 22-character field for each constant, one space after the comma, and two spaces before the aligned `;` comment. For example:

```asm
	db SPRITE_BULBASAUR_GS   , SPRITE_BULBASAUR_GS     ;Bulbasaur/Ivysaur
	db SPRITE_PIKACHU_YELLOW , SPRITE_PIKACHU_YELLOW   ;Pikachu/Raichu
```

- A formatting-only cleanup must not change the icon class names, order of the 208 one-byte mappings, `MonPartyData` length guard, or species-comment content. Verify parsed `(first, second, comment)` tuples before and after, and check that all first commas, second-column starts, and comment semicolons line up. Preserve the original `100755`/`100644` file modes. Do not blend whitespace cleanup with an untested icon feature.
- This rule exists because earlier icon import patches mixed compact legacy rows with increasingly padded imported rows, making the mapping hard to scan. Record the lasting prevention rule **here** rather than only in generated `RPP_PROJECT_CONTEXT/` handoff files.

## Gen I / Yellow / Gold Party icon deduplication before adding classes (ICO-5.62.62)

- **Do not import an icon just because the Gen I and Gen II labels or PNG colours differ.** Compare **both 16×16 animation frames** as the game actually renders them, not only the source sprite sheet, a name, or one screenshot. Reconstruct Gen I's horizontal OAM mirror (e.g., symmetric classes and Yellow Pikachu), preserve asymmetric tiles for special classes, and account for frame-order reversal. Separately compare grayscale source pixels, non-background silhouette, palette-only re-indexing and the active in-game palette; “same-looking” does not automatically mean pixel-identical.
- Confirmed with the user-supplied original RPP, Yellow, and Gold assets (11 Gen I/Yellow references × 38 Gold icons = 418 pair comparisons): **`MON` / Gold `MONSTER` are exact two-frame duplicates with their order reversed; `SNAKE` / Gold `SERPENT` are exact two-frame duplicates; `QUADRUPED` / Gold `EQUINE` are exact two-frame duplicates.** Reuse existing RPP classes instead of adding another class for these. Check frame order before switching assets or ID mappings.
- Gen I `FAIRY` and Gold `CLEFAIRY` **share exactly one rendered frame**, but their other frames are not identical. They should be classified as *near duplicates*, not as two-frame exact copies or purely a palette recolor. Unless an independently justified visual improvement is needed, reuse `FAIRY` for Clefairy-family and Togepi rather than recreating `CLEFAIRY`. This was the issue caught and corrected during the 5.62.62 drafts.
- Similar subjects are **not necessarily duplicates**: `HELIX` vs Gold `SHELL`, `GRASS` vs Gold `ODDISH`, and `WATER` vs Gold `FISH` differ in their graphics; they can coexist when species distribution clearly improves. Keep existing Gen I/Yellow categories where distinctive; avoid blanket remapping an entire broad family when only a narrow subset warrants a new icon.
- **Mandatory pre-import checklist:** (1) enumerate **all currently used** RPP icon IDs/assets, including previously imported Gen II classes, not only the first 10; (2) restore two *displayed* frames, their mirroring and order; (3) compare raw pixels, palette-normalized pixels and silhouettes; (4) label each candidate `two-frame duplicate`, `partial-frame reuse / visually close`, or `distinct`; (5) check the actual 208 species mapping and whether an icon is already usable without a new ROM class; (6) only if distinct and useful, add the two-frame PNG, constant, banked pointer, per-species mapping and minimum targeted runtime tests; (7) check ROM Bank placement, count of pointers, 104 mapping rows / 208 IDs, and the table's original fixed columns and file modes. **Never merge unverified graphics/layout changes into a closeout-only patch.**
- Keep the detailed review artifacts outside the game code as references (`一代二代队伍小图标_重复与近似核查.md`, `gen1_gold_icons_similarity.csv`, `gen1_gold_icon_side_by_side.png`). The durable checklist and confirmed examples belong in **this root file**, not only in generated `RPP_PROJECT_CONTEXT/` exports or an AI conversation.

## Formal closeout discipline

- Test-only data, re-arm logic, temporary species/evolution edits, and intermediate version suffixes must be removed before a formal version.
- Keep the real game version changing in test builds so the user can confirm the patch is applied, but keep source comments on the formal feature version rather than rewriting comments for every test suffix.
- Before delivery: static symbol/label/bank/register review, `git diff --check`, incremental `git apply --check`, actual apply, reverse-check, and file-mode comparison. Do not compile the user's project unless explicitly requested.


## Regional-form Pokédex metrics: inherit when identical (ANIM-5.62.112)

- Always compare a regional form against **the actual stock Pokédex feet/inches and tenths-of-pound values**, not just unrounded metric conversions. When public metric values match but the stored stock weight differs by 0.1 lb, first check whether the stock Pokédex value needs correction (notably Galarian Linoone versus regular Linoone).
- In `data/regional_forms.asm`, descriptor `db 0` / `dw 0` means full stock-data inheritance. An allocated metrics record uses `db 0,0` to inherit stock height and `dw 0` to inherit stock weight **independently**; only write a nonzero field when it actually differs. Do not allocate redundant 4-byte metric records for fully identical forms.
- Verify form identities via `Species + Form`, and treat special custom mappings (`PERSIAN + FORM_GALAR` for Perrserker; `WEAVILE + FORM_HISUI` for Sneasler) as their source Pokémon's measurements, not those of ordinary Persian / Weavile. Compare with Polished Crystal body data and Bulbapedia display values when the former lacks a form.
- Keep metric inheritance cleanup separate from unresolved battle-stats / evolution / learnset placeholder work. Validate all descriptors and in-bank symbols, all effective display values, patch apply/reverse checks and file modes. Runtime ROM/link/map/saves remain user-side acceptance work under the current project rules.

## Wild HUD Owned identity and far-call flags (DEX-5.62.120)

- For wild enemy HUD, `wEnemyMonForm` can change after Transform. Use unchanged `wEnemyMonSpecies2` plus the per-encounter latched `wWildEncounterFormMarker`; resolve a nonzero marker with `RegionalFormGetFormBySpeciesMarker`. Restore original D (species) after that descriptor lookup, which returns the form in D.
- Cross-bank `callab`/`callba` return through `Bankswitch`: the return A is replaced with the saved bank, but the Owned test's Z flag survives. Branch on Z **immediately after the far call** (before `ld`/`and` instructions that would change flags); do not interpret A as the boolean return.
- Repaint the small HUD marker cell on both outcomes so previously owned wild enemies cannot leave a stale ball when the next form is unowned. Do not replace the existing small `$E9` tile or borrow the list's three-state palette logic.


## Pokédex facing switch: do not publish a half-uploaded sprite (DEX-5.62.124)

- `vFrontPic` is overwritten in multiple VBlanks (49 tiles). Whitening BG palette 0 and then calling `RunPaletteCommand` / `RegionalFormOverridePokedexPalette` **before** tile upload completes can prematurely expose partially replaced tile graphics, seen as broken frames on SELECT/front-back and cross-species switching.
- Keep one `PokedexData_RenderSwitchedEntry` path for SELECT, START, UP/DOWN. Prepare text offscreen; white the picture-only palette and wait until the palette consumer has committed it; finish `PokedexData_LoadFacingPic`/tile upload; **only then** construct and commit the new PAL and prepared BG page. A brief white picture curtain is not the same as fragmented graphics, and is not evidence that VRAM double buffering was implemented.
- The facing preference is one runtime WRAMX byte (bit0 facing, bit7 internal-only initial-load gate). Never reuse shared CD37 or redirect ordinary battle/evolution/capture front-sprite loads. Record tested and untested transitions separately.


## External capture Pokédex input vs internal info viewer (DEX-5.62.128)

- The external one-shot `ShowPokedexData` description uses `TextCommandProcessor` and its embedded `page` A/B wait. Appending an extra SELECT loop *after* it cannot intercept input already consumed by that text engine. Redirecting its whole render entry on SELECT also clears/repaints the whole screen, as seen in the abandoned 125/126 capture-view prototypes.
- Per user decision, the 128 external first-capture page deliberately uses only the original description A/B/front-image path. **Never reintroduce** the external `PokedexData_ExternalPageInput` / `ExternalAdvanceToBack` helpers or a temporary facing hook in HOME unless a later explicit request changes the requirement. The separate 121 per-form first-capture unlock and real captured-form header must survive the rollback.
- Party and Box share a **different** `StatusScreen` with a private temporary facing flag and 49-tile staged upload; do not delete its state, copy loop or VBlank ordering when removing external capture-view experiments. The internal Pokédex uses its own persistent runtime preference. Keep these three lifecycles separate.


### SFX-5.62.141 — 低血量 Danger 不是战斗音效播放完成信号

- `WaitForSoundToFinish` 遇 `wDanger != 0` 会直接返回，因此即使 Crysaudio 的 SFX 活动标志仍为 1，也不能据此推定动画尾音播放完毕。新增／多段招式的尾音可能与之后的通用命中声在不同音效声道中叠加。
- 不要无差别删除 `Danger` 检查或把所有音乐切换改成强制停止效果通道；若只需修改战斗动画的声音衔接，在局部按 CH5～CH8 标志逐帧等待并设置上限，同时遵守 `wSFXDontWait`。等待期间需要 VBlank 正常更新声音，而不是在禁用中断的情况下忙等。
- 141 已由用户对照旧版完成伏特攻击、电光、撞击及双方招式的核心实测，确认低血量下的音效残留问题在测试范围内消失；十万伏特、动画关闭、免疫／未命中、静音与 180 帧上限等仍未专项确认。AI 未编译 ROM，没有 MAP／实际链接空间结论。


### SFX-5.62.142／143 — Crysaudio 的 SFX 状态不能用旧声道 ID 直接判定

- 电梯结束的 `SFX_SAFARI_ZONE_PA` 和训练师战 `SFX_FAINT_FALL` 均走 Crysaudio CH5；旧 `wChannelSoundIDs + Ch4` 等待不代表当前 CH5 活动状态。局部衔接应先确认实际声道映射，再按该声道的活动位／SFX 身份逐帧有界等待，避免高 HP、Danger、其他音效占用导致无限等待或误放行。
- 142 电梯和 143 训练师倒下场景已保留局部等待清理，但**没有对照实测证明旧版本存在可听辨的音效错误**。142 用户反馈差异不大；143 录像中的常规倒下、红血与战胜流程未见明显异常。不把兼容性清理包装成已修复的复现缺陷，也不要全局停音。
- 同时反伤倒下后己方省略叫声／文字属于原战斗特殊分支，不是 CH5 等待问题；用户要求保留现状。若未来另改倒下反馈，必须单独讨论胜负、换人和经验值逻辑，不能与音效清理混做。


### SFX-5.62.144 — 已静音的噪声 DAC 仍可能在 NR51 断路时发出 click

- `SFX_FLY` 在飞行起始和抵达时都通过 Crysaudio CH8（硬件噪声 CH4）播放；音符末尾有独立静音 `noise`，但音效软件声道结束后，下一帧 `SoundOutput` 可能撤掉 `$88` 左右路由。在 143 视频中多余脉冲晚于第八次噪声，位置与该声道退役时序相符。不要把末尾的 click 草率归咎于原样本数据或随意删除最后一声。
- 144 只在 `PlayFlySFX` 播放后向现有 `MusicResumeMask` 并入 `$88`，依靠 `ApplyHeldMusicRoutes` 在 CH8 不活动时维持已静音的 APU 输出路径，并由 `_PlayMusic` 在新 BGM 开始时恢复正常管理。该方案不修改全局 `ClearChannel`、`ParseMusic`、SFX 身份/声道分配或其他转场；由于没有 MAP/ROM 验证，避免写成已经实机确认修复。


### Fly 145 — 仅保持 NR51 不足以模拟 Audio2 的普通噪声尾声

- 144 运行录屏显示 Fly 在 Music On / Off 均有原先末尾 click；飞行入口 `StopMusic` 已使期间 BGM 静音，不能以音乐开关与听感无关作为否定 SFX 尾部清理的证据。
- 原版 Audio2 的 CH8 `sound_ret` 不执行额外硬件 Rest；Crysaudio 普通 CH8 到 `endchannel` 则在最后的零音量 noise 之后额外将硬件送入 `.ch4rest`/`ClearChannel`。145 在 `.readff` 仅识别当前 CH8 的 `SFX_FLY` ID 并跳过这次二次清理；不复用 Battle SFX Flags3 bit7，因为它还会改变音符时长／频率分支，不应该污染普通飞行音效。
- 这是可复核的代码路径差异，但是否独立解释用户录屏的尖峰仍需 ROM 测试；不要据此宣称 145 已实机修复或修改整个 SFX 系统。


### ANIM-5.62.146 — Fly 末尾 click：避免把模拟器音频表现强行归因于 ROM

- 144/145 的飞行声道策略为试验假设，不是经过跨模拟器确证的游戏修复。144 `NR51` 保持已被录像证明未解决；145 CH8 专用尾声绕过未获有效性证明。**两处运行时更改均已在 146 撤回**，旧条目仅用于记录探索过程，当前游戏逻辑恢复 143。
- 同一 143 游戏在 My OldBoy 和另一 GB/GBA 模拟器未观察到 click，而 GBPocket 的现场播放与内置录屏同时能听到，故优先怀疑模拟器共用的 SameBoy 核心／PCM 音频路径，而非通过给 ROM 音效删尾音、强制淡出等方式掩盖。模拟器 APU 48 kHz、`accurate` 高通、NR51/CH8 尾声都只是候选，未通过 A/B 定因；Android 播放端丢样不足以单独解释内录同症状。
- 必须区分“用户特定模拟器里可听到的 click”“游戏侧在指定平台对照 PASS”和“完全定位根因”。保留证据见 `docs/FLY_CLICK_PLATFORM_DIAGNOSIS.md`。项目 ZIP 或关键参考丢失时直接向用户索取，不通过互联网猜测性恢复未提交工作区。


### Volt Tackle 146 验收 — 区分故意的视角差异和缺失的动作阶段

- 旧 `engine/battle/volt_tackle_animation.asm` 的英文注释明确要求只在玩家施放时启用命中段横震，敌方留给通常的竖向命中反馈，因此是有意做出的方向差异；**缺少原作者进一步解释这种美术取舍的证据**。不能凭猜测写成「当初为了避免晃 HUD」等已知事实。
- 146 在用户对比 145/146 敌方攻击录像后选为最终观感，不应在“整理代码”时再次加回 `H_WHOSETURN` 限制。当前通用 WX 震动会影响完整画面与 HUD，不等于《绿宝石》`ANIM_TARGET` 局部摇动；可选目标局部震动须在后续新版本独立 A/B 试验，不污染已验收的 146。
- 全局命中反馈表中的玩家／敌方差异可能是 BG、背图及敌方前图各自显示方式造成的适配。审计其他招式时先区分「主体动画阶段被跳过」和「命中反应方式不同」，不得一概改成方向对称。


### MOVE-5.62.159～161 — 同一真实招式 ID 的战斗外别名必须携带物种上下文

- `AGILITY` `$61` 对指定物种在战斗中表现为 `Rock Polish`，不代表 `GetMoveName` 能在所有界面全局改名；MoveDex／普通 Agility 仍依赖原名。Party／PC 详情使用已载入的 `wLoadedMonSpecies`，升级及学习替换使用选中 Party 槽 `wWhichPokemon` 读取 `wPartySpecies`。**不要把战斗专用物种判断和没有物种上下文的菜单混为一谈。**
- `CopyString` 的参数为 `DE=来源`、`HL=目标`。`PrintListMenuEntries_` 的 `HL` 是 `PlaceString` 绘制坐标，任何 `callab` 名称助手前后必须按现场 ABI 保护；NPC 列表绘制会把 `wWhichPokemon` 改为行索引。161 仅在 NPC 列表绘制期间借用 `wMoveMenuType` 暂存所选物种，调用结束立即恢复旧值，防止影响通常代表普通／模仿／PP 文字类型的其他上下文；同时按 `wListPointer == wRelearnableMoves` 限制别名生效范围。
- `wMovesString` 有 56 字节，修改名称长度时需要重新格式化包含换行和终止符的四招列表，不能对既有短名称就地替换导致后续名称错位。当前 `FormatRockPolishStatusMovesString` 与 `FormatRockPolishLearningMovesString` 各复制了类似的四行格式化循环，**这是已识别的维护性重复，不是已复现功能错误**；未来若拟合并，必须先审查不同物种来源、跨 Bank ABI／寄存器、列表返回和最长名称长度，且作为新功能版本独立验证。本次验收清理不改已通过的 ASM 指令，仅统一三处源码注释中的中间版本号。
- 157 曾出现反向复制与空白列表，158 详情分流未生效，最终分别在 159、160、161 收口。用户实测范围见 `docs/ROCK_POLISH_161_ACCEPTANCE.md`。PP 道具与 MoveDex Seen/Use、旧 `$F0` 编号释放、学习后对话框残留均未在 161 实现或解决，不应在未来交接中写为已验收。

## MOVE-5.62.169 P3-D — 扩展身份的字节与远调用 ABI

- **低字节 0 永远不能表示一个可持有招式**：旧数据与列表用零表示空槽。扩展表从 `$0100` 起时，Party/Box 槽位编码须偏移 +1，再根据 sidecar 恢复完整 16 位身份。
- `callab/callba` 经 `Bankswitch` 会改写 A/B/HL；不能用 A 或 B 直接传入或返回动态技能槽下标／扩展序号。先写入明确的 WRAM 参数，结果也由被调方写入 WRAM；调用方重新读取。
- 只读原始技能字节 `1/2` 会把新招误认为 Pound/Karate Chop；每一个用于可见名称、战斗执行、PP、技能交换或存档的入口都必须获得该槽的 sidecar 位。未接通的 NPC、派生招式和联机路径不能默认为兼容。


## MOVE-5.62.169 — 遗忘／回忆列表身份与栈平衡；P3-G 撤销边界

- `PrepareRelearnableMoveList` 保留 packed learnset 指针到栈后，再经 `HL` 找 Party 招式和 sidecar；不能重复 `push hl` 再只 `pop` 一次。P3-E 的回忆师异常退回正是返回地址被旧数据指针覆盖，P3-F 删除多余压栈后用户反馈正常。查 NPC 流程必须核算每条分支 push/pop 成对数量。
- NPC 列表的低字节 `1/2` 既可能是真正 Pound／Karate Chop，也可能是在 sidecar 位标记下的 Power Whip／Play Rough。列表每行身份、删除时 PP 与 mask 压紧、回忆候选去重、`callba` 的返回寄存器必须一并核查；不能只修文字而不修删除行为。
- 用户决定**先验证扩容数量、后集中加固**，因此未实测的培育屋 P3-G 已撤回；当前 `wDayCareInUse` 高位不得当作已实现的扩展身份持久化机制。数量扩展以后再单独设计和验证寄养、交换、变身与派生招式。


## MOVE-5.62.170～171 — 扩展招式表的 RGBDS 标签域与回忆候选容量

- 在招式名称指针表前后添加全局标签（`::`）会改变其后 `.local` 的隶属范围；170 首个补丁曾报 10 个 `ExtendedMoveNamePointers.*` 未定义，`HealParty.extBit` 也漏定义。任何新技能批量扩表，都要对**全部新增局部符号**做完整域检查；PP 标记循环同时核对各槽位右移，而不是只补链接标签。
- `wRelearnableMoves` 原先仅按 8 条候选分配，旧普通学习表遍历还未检查容量；扩展到 10 招后需要让普通／地区／扩展候选遵守同一个计数、`$ff` 终止符和逐行 ordinal 的 32 条上限。NPC 操作期借用的 movement scratch 与 MoveDex 字体临时缓冲只能在生命周期互斥时复用；不能把物理容量修复等同于所有候选过滤错误的根因已经确定。171 用户测试扩展回忆主路径恢复，满 32 条及全部边界未专项实测。


## MOVE-5.62.173 — 容量占位数据与临时学习分配要分开收口

- 扩展 ROM 数据表的 40 个 ordinal、名称／战斗数据占位不等于任何物种应在 19／20 级学会它们。容量试验曾用 20 个家族的特殊学习／回忆映射；**正式定版须删除这些测试分配，不能只清理负向测试的 19 条学习记录**。旧测试档持有已学扩展技能时，清理后不再通过已删除的家族测试表回忆。
- 普通／地区表的 RGBDS `ASSERT` 使用最坏情况预留 `EXT_MOVE_MAX_PER_SPECIES = 2`，不是自动数出所有未来新技能来源。设计正式扩展学习配置时，须明确每只宝可梦的普通＋扩展回忆总候选不会超过 32；如改变分配上限，要连带更新静态保护。移除测试入口并不等于已经验证了永久保存、PC 盒子及特殊派生招式。


## MOVE-5.62.174 — 171 普通升级学习调用误删（历史补丁 008）

- 在 `LearnMoveFromLevelUp` 中增加“已持有技能身份／sidecar”判断时，**不能删除匹配失败后的原 `wMoveNum` → `GetMoveName` → `predef LearnMove` 调用**。171 历史补丁 008 曾把整段删掉，只剩下 `pop bc`／`pop hl` 返回学习表循环；因此普通招式在正确等级被找到后仍不会学习。173 用户通过升级糖果发现。修复时对照旧补丁的删除区块和最新循环，两条分支（已学会跳过／未学会调用学习）都必须保留。
- 同低字节的旧技能与扩展技能不是同一身份：若普通学习表 ID 匹配已持有技能槽，仍须检查该槽 sidecar 位，只有未标记的普通槽才算已经学会。未来修改循环应同时覆盖 1～40 普通招式与同低字节扩展身份共存；`ASSERT` 成功和 40 招测试学习成功并不能证明普通学习路径通过。


## MOVE-5.62.175 — 不能仅凭活动扩展 ordinal 判定当前招式身份

- `wExtendedActiveMoveOrdinal` 只对应玩家原本选中的扩展槽；Struggle、状态强制改招等路径会改写 `wPlayerSelectedMove`。使用该 ordinal 作为安全代理或名称选择前，必须至少验证它与当前选中 ID 一致；强制 Struggle 进入时应主动清零。此前 `GetCurrentMove` 仅判断 ordinal 非零，即使 `MaybeLoadExperimentalMoveBattleStats` 拒绝覆盖，仍可能保留藤鞭代理与旧扩展名称。
- 本次 175 仅修复明显的不一致身份和强制 Struggle；原 `$FF` 历史哨兵、派生技能恰好与扩展 ordinal 低字节相等、Link／Transform／Metronome 等不因本修复自动标记已验收。固定 `bankF` 173 MAP 余 14B，要留意补丁体积及最终链接，不用静态检查冒充 ROM PASS。

- 战斗 Fight 菜单 `wMenuItemToSwap` 和 `wCurrentMenuItem` **都是 1-based**。原字节/PP 的 `.swapBytes` 对二者均 `dec a`；扩展 sidecar 的 `SwapExtendedBattleMenuFlags` 曾错误地对前者 `sub 2`，造成首槽交换跳过、其他槽错位。修改并行身份时要与原数据路径逐条比对索引变换；不要仅测试四招会显示，要测试带同低字节旧招、扩展招的六种换位组合。


## MOVE-5.62.176 — 一次 `.swap` 调用复用 D 后，不得直接用 DE 计算 WRAM 地址

- `SwapExtendedBattleMenuFlags` 在计算 `wExtendedBattleMoveFlags` 的换位后，局部 `.swap` 会执行 `ld d, [hl]` 保存原 flags；紧接着再 `ld e, [wPlayerMonNumber]`、`add hl, de` 形成 `wExtendedPartyMoveFlags + index` 时若忘记 `ld d, 0`，会以原掩码作为地址高字节，写入错误 WRAM。此缺陷与菜单 `sub 2` 错一位不是同一问题，175 改对索引仍无法修复地址错误。176 补显式高字节清零；用户 176 视频已对受测混合换位和 Party 查看做针对性正向验证。
- **176 测试视频与最终回归边界**：用户《176测试.mp4》证实受测 SELECT 混合扩展／普通换位后，Party 详情不再将 Play Rough 当作 Karate Chop；撤销 053 临时家族等级入口后，又报告普通升级学习与战斗技能交换抽查正常。**这只是针对性回归，并非完整内存安全或各类升级／保存路径证明**。移除 053 仅限临时学习／回忆入口，不得再次破坏 174 普通 `LearnMove` 分支与 175/176 战斗读表、换位 WRAM 修复。
- 凡局部函数把 B/C/D/E 等寄存器当暂存变量，再用于 16 位地址偏移、指针或 Bank 参数时，必须重新建立寄存器不变量；要同时比较**战斗数据、Party 持久副本、sidecar 标记**三者在换位/回存后的关系，并用同低字节的旧新招式做回归。单独看到战斗菜单名称正确，不构成保存端正确的证据。


## MOVE-5.62.178T3F — NPC 远调用不能借走选中 Party 序号

- 178T3 在 `MoveRelearnerText1` 生成候选后，临时调用 `callba TestBothRattataPowerWhipRelearnCandidate`。此处原本寄存器 B 保存所选 Party 槽位；`callba` 会改写 B 以载入目标 ROM Bank。回忆列表仍可正常显示，但之后的 `wWhichPokemon` 读写使用了错误索引，出现昵称乱码与潜在错误成员写入风险。073 临时测试修复通过 `push bc`／`pop bc` 保护选中槽位；用户随后反馈测试版回忆、战斗、详情与 Party/PC 存取读回正常。
- **正式 178 已彻底移除上述临时远调用及临时回忆候选，不得为了保留 073 修改而重新引入它们。** 本例可复用的教训是：跨 Bank 调用前明确列出 B、HL 等寄存器的现场用途，逐条审查从候选生成到 LearnMove 的 Party 索引传递；标签、编译期容量和表结构检查不能代替动态数据索引验证。
- 双形态升级测试原先的 `Power Whip` 来自临时等级钩子、回忆候选来自独立测试追加，**获得来源与回忆来源不是同一张历史学习记录**。清理临时来源之后，旧存档持有的招式可继续显示／使用，但遗忘后无法用该临时候选找回；将来正式分配须同时设计学习与回忆规则。


## MOVE-5.62.180 — Transform 复制技能字节时必须同步“仅战斗中”的身份位

- 玩家用 Transform 复制敌方普通技能字节以后，`wBattleMonMoves` 已不是 Party 原来的四招。若继续保留 `wExtendedBattleMoveFlags`，同低字节技能就可能错误读取扩展表／名称；成功复制之后只清玩家的**战斗临时 mask 与 active ordinal**，不要清 `wExtendedPartyMoveFlags`，更不能把变身后的字节回存为 Party 原招。失败变身不执行该清理。
- `SetPartyExtendedMoveSlot` 在战斗升级学招时通常会把新 Party mask 同步给战斗四槽；但活跃对象如果已有 `wPlayerBattleStatus3.Transformed`，四槽是临时复制内容，必须阻止反灌。这是源码保护，并非用户已跑过的战斗升级场景。
- 用户《180变身.mp4》确认持扩展 07 的喷火龙变身成野生猴怪后正常显示／使用复制的普通技能；视频结束时仍在战斗，不能据此推定战斗结束、换人或失败分支已验。扩展身份后续进入 Mimic／Metronome 和敌方变身时要分别审计，不能只复用清零逻辑当成完整身份复制。


## MOVE-5.62.188～189 敌方原生 EXT 验收与清理陷阱（2026-10-18）

- 当训练家来源匹配器以 `wTrainerClass` 作键时，表项必须写内部 `SUPER_NERD` 等训练家类别，**不能**使用地图出场 ID `OPP_SUPER_NERD`。第二键 `wTrainerNo`、第三键 `wWhichPokemon` 是零起始队伍槽；已战败训练家能否复战与配置匹配是否成功是两件事，临时复战脚本不进入正式版本。
- 来源表中未标记的普通招和标记的 EXT 可以共享一个低字节，例如普通 Fire Punch `$07` 与 EXT07。匹配命中后同步写 `wEnemyMonMoves` 和敌方高四位标记；读取第二表 PP 的 `callba` 会覆盖 BC，须保护循环槽索引，不能把普通同号 PP 当作 EXT PP。
- **189T 清理检查清单**：恢复 `data/wildPokemon/route7.asm` 的正式野生表；将 `WildNativeExtendedMoveSources` 与 `TrainerNativeExtendedMoveSources` 清回仅 `$ff`；恢复 `scripts/Route8.asm` 原对话；移除 `scripts/189T_route8_rematch.asm` 与 `main.asm` 中的临时 INCLUDE。测试中改动的 SAV 由用户恢复，不是源码清理补丁能够撤销。
- 录屏里敌方 `Ext Move 07` 正常出现、动画／伤害正确只能说明**执行侧**载入成功，不能证明 `trainer_ai.asm` 的候选招式评分正确：AI `_ReadMove` 依候选低字节读取普通 `Moves` 表的缺口应在下一轮独立修复。188 的 `NOT SEEN/SEEN` 对照也不代表现有 MoveDex 有独立 EXT 收集位。
- 独立审查确证的 `RollStatusSideEffect` 远调用 A 参数丢失是共用战斗效果问题：189T 的普通 Fire Punch 出现麻痹曾暴露该缺陷，外部修复曾用于讨论但用户本次明确撤销；188～189 收口**不得**顺带改变效果函数，须未来独立修复并测试玩家／敌方 Fire Punch、Ice Punch、ThunderPunch 和相关状态效果。EXT02 会心、EXT16 对 Fly 特判、Lv.1 Psywave 边界亦另列待办。

## MOVE-5.62.190 共用追加状态远调用寄存器约定（2026-10-18 验收补记）

- `callab RollStatusSideEffectFar` 经 `Bankswitch` 会覆盖 A；仅依靠 Carry 或远端入口直接使用 A，会将 Fire Punch 的 `BURN_SIDE_EFFECT1` 误解释成麻痹等类别。输入效果先由 `ld e,a` 传递，在远端先执行 `ld a,e`；返回前既有 E 用于传回归一化类别、Carry 表示触发与否。后续修改跨 Bank 效果判定时，不得重新依赖 A 跨 `callab` 保值。
- 190T 强制判定仅证明 Fire Punch/BRN、Ice Punch/FRZ、ThunderPunch/PAR 三项效果归属；正式概率统计、免疫和替身边界不由该录像覆盖。用户已反馈撤销 190T，正式源码不保留临时测试场景；测试 SAV 与撤销后新 ROM 构建需用户自行确认。


## 191 低字节碰撞不能继承旧招式特判（四项专项反馈通过）

- 扩展槽仍存 1..40 ordinal，与普通技能低字节可能相同；`CriticalHitTest_` 的普通高会心／必会心表及 `GetSemiInvulnerableMoveInteraction` 的普通 Fly/Dig 相互作用表都必须先核对**当次主动攻击者**的 `wExtendedActiveMoveOrdinal`，不能把 EXT02 当 Karate Chop 或 EXT16 当 Gust。
- 191T 可用临时来源表创建 EXT02/普通 Karate Chop 与 EXT16/普通 Gust 对照，真正的 Fly 无敌回合需要受击者已进入空中状态。测试强制会心比较值和阈值不代表正式 6.25%／高会心等概率验证；测试结束须撤销野生数据及调试概率。

- **验收与概率区分**：用户反馈 191T 四组实测全部通过，并明确已撤销测试补丁。191T 使用 0%／100% 确定性会心只验证身份分流，**正式 EXT 仍有普通随机会心**。普通 Gust 在 Fly 空中命中只验证可命中，不代表其倍伤倍率已经数值验证。正式源码中绝不可遗留 191T 的草丛来源与会心固定值。

## MOVE-5.62.193 — 升级表宏重复 SECTION 与 ROM Bank 一致性

- `level_ext_move` 在每条实际学招来源处展开；在 `MACRO` 中用普通 `SECTION "...", ROMX` 会在第二次定义时触发 `Section already defined`，`PUSHS`／`POPS` 只能恢复之前的 Section 上下文，**不能把重复的 SECTION 声明变成合法定义**。可累积数据须用与 RGBDS 版本兼容的 `SECTION FRAGMENT` 并保证名称一致。
- 读取表使用 `ld hl,ExtendedLevelUpSources` 直接访问 ROM。即使符号可链接，只把来源表和读取函数各放入独立、可浮动的 ROMX Section，也可能因为 Bank 不同而读取错误数据。最终把 `ExtendedLevelUpSources`、全部宏展开的三字节表项、终止 `$ff`、读取函数统一放在 `SECTION FRAGMENT "Extended Level-Up Lookup", ROMX`，同时保留现有 far-call 接口。未来变更该 Section 时复查 Bank-aware ABI。
- 增加宏生成的数据和查询例程后，复查循环中 `jr` 的 8 位有符号距离；193 同批将两处有超距风险的 `jr` 改为 `jp`。仅通过 `git apply --check` 不代表 ASM 汇编、Bank 链接通过。用户反馈的正常学招、遗忘、回忆和战斗释放只支持对应受测主路径。
- 正式源中的 `data/evos_moves.asm` 不应留 `level_ext_move 6,EXT_MOVE_POWER_WHIP` 等仅供 193T 的临时小拉达分配，普通 Pound 对照也必须随 193T 撤销；真实投放需要未来另按物种／等级确认。

## 嬉闹专属动画：图块、OAM 与分帧复用（ANIM-5.62.194）

- `FrameBlock` 是图块编号／排列，不保证 VRAM 正好载入相应素材。复用帧块时同步核对 Tileset、复制槽位、完整 8×8 图块拼合、PAL 和 OAM 镜像，否则可能把星星／爱心误显示为冰块或碎片。
- 多对象动画优先复用本项目 Quick Attack、Energy Ball／Gunk Shot 飞散、DynamicPunch 生命周期、Cross Chop VBlank 横震和原生 `DrawFrameBlock`；HIT 要使用事件变换后的 X/Y（不是上次对象残留的 `wBaseCoordX/Y`）。同时检查每帧 OAM 上限和同扫描线优先级，不靠盲目更换素材修复遮挡。
- 改动局部标签和主循环前，检查同一全局标签下的重名、局部调用可达性、`ret` 分支及寄存器／栈保存。194C 已由用户选择为最终视觉版本；194D 的额外命中反馈被撤销，清理时不要带回。

## ANIM-5.62.195 — 已有原音效≠已注册为可播放音效；音色、事件节奏和声像要分层核对

- **先查项目全量音效库**：194 嬉闹起初用 Menu、Karate Chop、Comet Punch 近似替代 PC 的 Throw Ball、Bone Club、Double Slap，后来核实 `crysaudio/sfx.asm` 其实已有对应的 `Sfx_ThrowBall`、`Sfx_BoneClub`、`Sfx_Doubleslap` 轨道。今后迁移动画音效时，先同时检索原 SFX 数据、`GSSFX_*` 编号、`crysaudio/rbsfx.asm` 的 Bank+地址指针和现有播放例程；不要把“没有公共音效编号”误判成“没有素材”，也不要先选近似音效。
- **编号／指针同序**：新增 `GSSFX_*` 常量必须与音效指针表严格一一对应；多声道音效指针指向原始 Sfx 序列，不复制原音轨也不在播放时猜 Bank。加入 3 项会增加指针表 9 字节，不能仅根据旧版 MAP 推定可链接，需查实际新 MAP。不要为了腾位置重构无关代码。
- **共享阶段局部替换**：Gold Quick Attack 接近／返回被多个招式复用，改开场音需要按当前完整 EXT 身份限制到 EXT02；不应让普通 Quick Attack、其他扩展技能和普通同低字节招式跟着变音。变更前检查 `wExtendedActiveMoveOrdinal` 的来源和清理路径。
- **区分声音数据、节奏、混音**：PC 的 `anim_sound`/`PlayStereoSFX` 包含声像／立体声位置参数；Red++ 嬉闹现用 `PlaySound`，虽保留 `0/9/18/24`、`30/39/48/54` 的触发时刻和对应音效数据，**不保证**声道控制或声音重叠与 PC 一致。用户 195A/PC 录像提取音轨呈现不同左右声道结构，也可能受到录制路径影响，不能把单个录像的双声道相同误判为游戏全局无立体声。PC 听感略慢不意味着应擅自延长已验收的主动画帧表。
- **验收与收口**：195A 用户提供了游戏录屏并要求独立清理；正式 195 只保留原声音复用和时序，复用 194 画面定稿，不叠加已撤销的 194D 横震或新的声像实验。用户验收的音效可播放并不等价于全平台所有声道与 Red/Hard 双链接通过。

## MOVE-5.62.199B — INCLUDE 内禁止重复重建既有 SECTION

- `main.asm` 已声明 `SECTION "pokecenters", ROMX, BANK[$35]`，并在其中 INCLUDE `engine/menu/movedex.asm`。199A 为迁出图形而在包含文件中重新写 `SECTION "pokecenters"`，会在汇编时直接报 `Section already defined`；补丁正反向校验无法发现。
- 需要把图形移动到新 Bank 时，应在 `main.asm` 的独立位置声明新的 SECTION，保持包含文件处于原来的 SECTION。静态检查应展开父文件 INCLUDE 边界并检查 SECTION 重名、图形标签 BANK 及空间，不能把 git apply 视作汇编有效性验证。

## MOVE-5.62.199C — 分类读取在战斗光标频繁刷新路径的副作用

- 199B 的 `_BattlePhysicalSpecialSplit` 在 Spark 光标预览中执行两次跨 Bank 的 `RecalculateBattleStatFromModifier`，引入不必要的 Multiply/Divide 与共享 HRAM 工作区干扰风险；用户测试出现第二招跳选、上下移动花屏。该关联来自代码审查，仍须实机确认修复，不冒称已完全复现根因。
- 战斗当前的 Attack/Special 本来已经包含能力等级；正常路径直接读取。只有烧伤曾改变 Attack 时才额外按原始 Attack 与当前能力等级重算，避免把烧伤当成分类切换原因。
- MoveDex 的 `movedex_v1.0.1-v1.2.6` 历史提交提供现有分类黑底框与字模；不要用临时 3×5 字体替代。保持 4 个 8×8 tile、原宽度和来源标签图块边界。

## MOVE-5.62.199 — Dynamic 判类验收收口注意事项

- 动态类别的元数据、菜单预览和实际伤害结算分层：MoveDex 保留 `DYNAMIC`，Fight 菜单只预测，出招伤害入口重新判断；两阶段可以因先手能力下降产生不同类别。相等按 Physical（200T-004 用户明确要求，保留 Spark 原本物理分类）。
- 普通战斗 WRAM 的 Attack/Special 已计入能力等级；不要在每次选招刷新都调用跨 Bank 乘除重算。烧伤时重算未减半 Attack，并跟随项目现有能力值上限 999；否则极端提升可能把封顶后的比较结果判错。
- 199D／199E 的 Spark→Counter 两侧缓存与测试数据不属于正式 199。扩展序号可能与普通招式共用低字节；将来独立实现 Counter 前先追踪当次实际受击，不允许依赖长期缓存或只比较 `cp SPARK`。
- 制作从已提交基线出发的全量补丁必须包含新图像资源、`DYNAMIC` 常量、MoveDex UI 迁移和描述；只检查 `git apply` 不能发现遗漏 PNG、SECTION/标签重复。保留 199C 的原字模、四 tile 框和可撤销迁移实现。


## BATTLE-5.62.200 — Counter 本体真实受击和测试代码清理

- Counter 应读取**受击方本回合**的真实 HP 记录，而不是对手菜单／Counter 使用者能力或可被后续伤害覆盖的全局 `wDamage`。每段多段攻击若真正扣除本体 HP 应更新记录，反击只用最后一笔×2；替身和间接伤害的复杂路径必须专项验证，不要因主流程通过而标记所有边界通过。
- Counter 的资格判断与 `MoveHitTest` 是两件事。资格失败可能显示原 Gen1 的 `Attack missed!`，是否改文案需用户单独确定；Counter 固定伤害不应继承无意义的会心文本。
- 烧伤 Dynamic 菜单曾因高频刷新路径中的跨 Bank 计算触发死机反馈：不要在选招热路径无条件远调用能力重算。正常情形读已生效战斗能力；烧伤时使用同 Bank 能力等级重算并封顶999。平局归 **Physical** 是最新用户规则，不要回滚成199旧结论。
- **三件套收口必须剥离测试设施**：玉虹大厦 5 对象覆盖、7 号道路全卡比兽遭遇、`InitWildBattle` 的 `Dyn200TConfigureWildEnemy` 远调用、`wDyn200TestScenario` 临时别名及文本、测试专用文档。项目文档同步更新；清理是完整提交的组成部分，不能只在打包 ZIP 时藏掉测试文件。正式功能保留 6 字节未存档 Counter 记录。
- 当前没有由助手独立 ROM 编译/链接、MAP 检查或测试 SAV 恢复证据。第二轮复杂边界采用独立可撤销测试补丁先复现再定性，详见 `docs/BATTLE_200_FINAL_RULES_AND_ROUND2.md`。

## BATTLE-5.62.201 — 阶段值与属性值不可互相代替

- 能力阶段的合法性只由 -6～+6 判断；不能因已钳位到 999／1 就阻止继续合法升／降级。攻击、防御、速度、Special 的重算结果再统一限幅 1～999。避免能力从 +6 降到 +5 仍封顶 999 时无法升回 +6。
- Counter 资格不足的失败标记与真正命中判定失败须区分，改变失败文字时不要改动 `MoveHitTest`、-5 优先级或实际伤害记录。临时测试注入不得留在正式 ROM，验收后需成组撤销地图／战斗／WRAM／野怪改动。


## BATTLE-5.62.202 — 伤害除数保护、混乱自伤与 Counter 幽灵免疫

- 公共 `CalculateDamage` 在 Defense/Special 经高能力值缩放（或 Explosion 折半）后，必须再次确保 C 至少为 1；只在未缩放的能力计算路径做下限保护并不够，因为除数可能在后续右移后变成 0。
- 混乱自伤不是调用当前选择招式的普通伤害类别：必须使用自方 Attack 对自方 Defense、40 威力、无属性且不能会心。跨 Bank helper 要明确处理 10-bit 能力缩放，并将 B/C/D/E 恢复为 `CalculateDamage` 期望的输入。
- Counter 的目标属性判断要在应用已记录伤害前执行；玩家使用时检查敌方当前类型，敌方使用时检查玩家当前类型。Ghost 免疫应走正常的无效提示路径，不改变 Counter 的 2×记录伤害、优先级、命中／闪避或资格规则。TEST 04 用户录像已见 `It doesn't affect Gastly!` 且目标 HP 不变。
- 正式清理临时战斗测试时，必须成组恢复 Celadon Mansion NPC／导师脚本与文本、Route 7 Normal/Hard 野生表，删除 `InitWildBattle` 测试远调用和 WRAM 别名，并删除临时测试指南；不能只把测试文字隐藏起来。

## BATTLE-5.62.203 — 自伤／远调用／临时夹具清理经验

- 自伤致死后行动顺序取决于 `MainInBattleLoop` 首手动作结束后的 0 HP 检查；只有真实死亡（不是普通掉血）才能验证后手是否停止。现有录像交接记录覆盖双方先/后手且不必再次录制；一只宝可梦不能代表后备换人。
- 测试强制混乱必须等真实上场或 Substitute 已创建以后才注入；多段攻击的实际 2–5 次命中属于**同一招式**，不得把每一击误当新测试回合。人工将替身 HP 设为 200/1 或当次伤害仅是夹具，不是正式游戏规则。
- 跨 Bank `callab` 返回会覆盖 A/BC/HL；测试阶段发生过“固定三击→画面显示 15 hits”，原因是错误地把返回 A 视为击数。临时夹具后来修正为按 E 返回并经双向录像验证，但**已从最终版完全删除**，不要保留其 Hook 和保存字节。
- Jump Kick 自伤必须从 `PrintMoveFailureText` 进入使用者本人真实 HP 路径，并在目标 Bank 设置 `HL=wDamage+1`；固定 `$34` 放不下 helper 时改为浮动 ROMX，不是硬编码新 Bank。旧 MAP 不能代替新 Normal/Hard 链接结果。
- 测试夹具含 WRAM 临时别名、玉虹大厦 NPC 入口、7 号道路野怪和 `InitWildBattle` 配置 Hook，清理时必须整体撤销并**恢复原先的 `RegionalFormClearNewMonForm`**；不要只删除 Hook 而丢失正式地区形态清理逻辑。正式覆盖证据详见 `docs/BATTLE_203_FINAL_REVIEW.md`。


## BATTLE-5.62.204 — 常驻可选测试框架的隔离与菜单回归经验

- **两类产物必须独立**：仅 `-D BATTLE_TEST_BUILD` 才引入测试 helper、Hook、两字节 WRAM 别名及 Pokey NPC；正式默认构建不应靠运行时 guard 来关闭测试。正式和测试对象文件不能同名，测试 SAV 与正式 SAV 不能共用。不可把“测试结束 disarm”误当成自动恢复被测试夹具改过的队伍。
- **保留用户地图定稿**：测试 NPC 为工程确有常量/素材的 `SPRITE_POKEY`，测试版位置 `($00,$0A)`（用户手工调整）。不要恢复旧 `$5,$5`/`$4,$8` 候选，也不能在正式版增加这个 NPC；原老太太与三名导师始终保留。
- **原生菜单栈纪律**：曾出现三选一菜单显示正常，但 A/B 退出均死机。原因是 `call .restore` 先压入返回地址，随后 `.restore` 中的 `pop af` 却弹走返回地址，导致 SP 和返回地址损坏。退出采用直落共享收尾，且只恢复自己实际 push 的寄存器。
- **对话框生命周期**：NPC 的 `TX_ASM` 内调用 Yes/No 和三选一菜单后，外层 `DisplayTextID` 可能额外等待按键。按项目现成 `DisableWaitingAfterTextDisplay` 让外层负责关闭，并先用操作提示替换旧警告，避免菜单 A/B 结束后遗留旧文字框。
- **输入边界与 Bank**：菜单方框要按地图 20 tile 宽度（`TextBoxBorder` 有两侧边框）核对；连击测试固定次数的跨 Bank 回传用 E 等约定寄存器，不能假定 A 被 `callab` 保留。各多段内部打击不能推进完整回合计数。不要把人工命中、替身 HP、固定次数等测试输入当作正式随机流程的验证结果。
- **缺口说明**：静态 `.patch` 正反应用、可选编译条件和可用 MAP 不能证明当前 204 Normal/Hard/测试 ROM 都已经重建并运行；由项目所有者本地检查，不重复此前录过的旧战斗场景。

## TEXT-5.62.205 — 逐字显示与调色板预更新不能错帧

- `PrintLetterDelay` 里直接强制 `H_AUTOBGTRANSFERPORTION=TRANSFERBOTTOM` 会让 BG 窗口图块更新与已经准备的对应调色板批次错位；正确做法是仅设置一次性 `hTextBottomRefreshRequest`，由 `GbcPrepareVBlank` 在 `RefreshWindowPalettesPreVBlank` **之前**统一判断是否可以优先选择底部六行。
- 必须保留 `H_AUTOBGTRANSFERENABLED`、`W2_UpdatedWindowPortion`、`W2_StaticPaletteMapChanged` 和窗口目标变更保护；请求若不安全即回退原三段轮换。快速文字显示之外的菜单、战斗 HUD 和地图调色板仍需实测回归。
- 本优化**不更改文字实际等待帧数**、`ScrollTextUpOneLine`、字体资源、`wOptions` 或存档。正式构建 205 的文字显示优化不代表独立测试 ROM 的 T09 版本号需要随之更新。旧 204 MAP 仅供空间基线参考，新增长度仍需本地链接后确认。

## TEST-209 / 测试菜单恢复地图后必须恢复 BG 传输原值

- `LoadScreenTilesFromBuffer1` 会把 `H_AUTOBGTRANSFERENABLED` 无条件设为 1；调用它不等于恢复调用前状态。菜单入口若允许该值原本为 0，必须保存原值。
- 正确顺序：保存地图和原开关值 → 退出菜单 → 恢复地图 → 在传输开启时等待一次 `DelayFrame` 完成地图图块上传 → 恢复原开关值。不能在地图 VRAM 更新前就重新关闭传输，否则可能残留菜单图块。
- 多层菜单只在根入口备份一次地图；子菜单 B 仅回上级，只有根退出或确认具体测试场景才进入共享恢复路径。所有返回路径需同时保持 AF/Carry 语义与栈平衡。


## TEST-214 — Transform 续招必须组合覆盖先后手、半无敌与动画恢复

- 单独通过“后手 Transform + 普通 Tackle”和“先手 Transform + Fly”不能证明“对手先 Fly/Dig → 第一次后手 Transform 失败 → 下一回合对手完成招式 → 后手 Transform 成功 → 立即复制 Fly/Dig”路径正确。复杂回归应把这些状态串在同一场景里，并分别覆盖玩家与敌方执行者。
- Fly/Dig 正常隐藏的是当前进入蓄力的施招者；若选择复制招式时已落地的对手图像消失，优先检查第二次 `MoveSelectionMenu` 的 `LoadScreenTilesFromBuffer1` 是否恢复了回合开始的旧缓存。TEST-213 的 `SaveScreenTilesToBuffer1` 刷新保留在正式共用手动 Transform 路径中，需由用户复测确认。
- 敌方后手镜像要把复制招式放在确定的第 2 槽，并在 `BATTLE_TEST_BUILD` 中仅对列出的场景固定槽位；正式 ROM 继续随机非空槽策略。不要把测试确定性误当作正式 AI 行为覆盖。
- EXT 场景需分别验证目标侧 high nibble 复制到玩家，以及玩家侧 low nibble 在敌方 Transform 前被测试 Hook 正确注入；命中概率和身份复制是两个独立判据。
- Substitute 镜像的目标必须**真正**先建立替身；光把其他招式 PP 置 0 不能保证野生 AI 的选招时序（已在 09 复现前置失效）。KO／Fly 也不能用 PP=0 的非空槽限制旧 AI；需在测试构建内指定真正的选招行为。
- TEST-214 仍是待验候选；静态分支核对与补丁正反回放不等于 RGBDS 编译、MAP/Bank 检查、模拟器或手机实测。


## TRF-5.62.209 / TEST-215 — 续招菜单 B 与旧 Disable、零 PP 野生测试夹具的区分

- 普通 `MoveSelectionMenu` type 0 的 B 是合法返回；手动 Transform 成功后**第二次**菜单若继续使用 type 0 并忽略菜单的取消返回，B 会误作为确认并执行当前高亮招式。TEST-215 复用相同显示/PP/Disable 检查，新增 type 3，仅监听上下/A。用户报告第二次菜单 B 无效、普通菜单 B 正常；本收口不重改 ASM。Mimic 的目标选招菜单不改。
- Disable 标记包含旧的禁用槽位及持续时间；Transform 拷贝新四招时没有显式清除旧禁用标记。刚复制的同槽招式是否受到旧禁用限制是继承旧机制的潜在行为，不是敌方在同回合第二次施放 Disable；该边界未取得单独实测，清理阶段不改。
- **野生敌方招式 PP=0 不是禁止出招条件。** `SelectEnemyMove` 可从非空且未 Disable 的槽中随机抽取，非 Link 野生敌方沿用无限 PP 规则。TEST-214 05/09 误以 PP=0 能保证 Splash／Substitute，录像分别见 Power Whip／Tackle，前提失效。07/14 有同类不确定性；不要修改正式 AI，只能未来在 `BATTLE_TEST_BUILD` 且指定 guard/场景的敌方行动槽做专用确定性选择，并检查清理时机。
- 用户不愿重复已测场景：录像可支持当次已观察的画面与流程，未录到的 Dig 第二段、PP 精确数值、联机同步、新 MAP 等仅作为剩余风险；不得标记为已通过，也不因改文档强制所有场景重测。

## ROUTES-253：活动地图技能覆盖与地图名称回退

- Surf helper 清单必须与活动 Source/Runtime descriptors 一致。旧版 `johto_surf_coverage_audit.py` 默认跳过 NewBarkTown；用户明确要求补齐当前所有活动地图后，已移除默认跳过，8 个 Gold WATER 必须进入三个既有 Surf 入口和上岸分支。启用前还必须审查运行 `.blk`：NewBark 偏移 39 曾从 Gold `$54` 改成草地 `$01`，所以只登记 Surf 坐标会让草地可冲浪；当前 `.253` 将其恢复为 `$54`，并有视觉/碰撞防回归测试。
- Cut 不只看共享艺术图块：按 Gold 稳定地图 ID、坐标与原始 Block ID 核对。当前活动地图共 7 棵 Cut 树，不能把邻接 `HEADBUTT_TREE` 当作可砍树。
- 新地图有 `HOP_*` 碰撞不代表 `HandleLedges` 自动支持。Route32 以前有 6 个 Gold HOP 碰撞格但未进稳定 ID 派发；它们应复用已核验的 Route31 tile-pair 表，不得扩大为所有 Johto 地图可跳。
- `engine/overworld/map_name_sign.asm::ResolvePhysicalLandmark` 缺少活动地图 stable ID 时会落到 `.JohtoUnknownName`，显示 `Johto`。地图激活时要同时补齐地点提示名称分支；不能把 Town Map landmark 已登记误认为地图名称栏也已登记。
- 交付前运行 `python tools/johto_field_move_coverage_audit.py --gold <Gold源码根目录>`；它会输出 Surf/Cut/HOP 地图覆盖，但仍是静态检查，不替代正式/测试红蓝构建、新 MAP 和手机验收。
