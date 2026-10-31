## FIX-5.62.282｜CLEAN｜正式验收收口（2026-10-31）

- 用户上传 `FIX-5.62.282.patch`：RPP 分支 `常规功能备份`，记录的实际 Git HEAD `b4148ccb783bdf734d621d0b8e8419f24ffe72da`。用户 .282 累计工作区补丁经反向应用还原 HEAD；与已留存 HEAD 快照的**源码文件**一致。本轮清理增量以用户上传的 .282 工作区为准确前置；HEAD 累计补丁以该确认基线为前置，两者不可叠加。
- 用户明确确认：.281 桐树林北门房/34号路出口地毯横移及骑行问题已解决；.282 **骑车且关闭专属自行车音乐时**的门房同曲重播已解决。普通步行的门房音乐此前就正常，不能写成 .282 才修复。其余地图行为、五种音乐模式逐条件、Save/Continue、夜间 Cut/Surf 等没有取得新一轮完整设备验收，不能扩大结论。
- 本次 `MAP_20261031_131234.zip` 内红蓝两个 MAP 的 ROM0 `SLACK: $0054` 即84字节，均大于64字节底线；MAP 附带的版本记录为正式 `FIX-5.62.282`/测试 `TEST-231`。此为用户本机构建生成的 MAP 证据，不是 AI 自行编译 ROM；未见本轮新增 ROM 运行代码。
- 最新 MAP 揭示两项过时测试假设：原 `test_johto_bike_route29_route32_252` 假定 ROMX Bank $48 必为空，现已实际存放 Field Skills；原 `test_johto_rom0_budget_262` 写死旧 MAP 85B 而不能接受本次84B。工具提交仅改这两项测试的正确约束，仍强制注入32B ROM0负例；另修正 README 首行版本标题以适配现有一致性审计。
- **模式 A**：从 HEAD 到最终状态既含游戏 ASM/资源/版本，也含 `tools/` 审计及负向测试。清理包包含 3 份补丁（用户 .282 工作区→最终文档收口、最终→仅功能的工具/审计反向隔离、确认 HEAD→最终累计全量）和两份中文 Git 日志；第一笔功能，第二笔工具/审计。`scripts/` 下游戏运行脚本属于功能。功能/工具两笔均由用户自行决定 Commit/Push，AI 不执行。
- 不变：正式可见版本 `FIX-5.62.282`、测试版本 `TEST-231`、21张已接入活动地图、封闭的未开放建筑及 Route35、Gold 原始 `.blk`、森林成熟碰撞/场地技能、已验收 `jp`、禁止跟踪自动生成 `.2bpp`。清理仅更新维护文档和验收依据，不改变 ROM、存档字段或音频实现。
- 下一开发批目标为满金市北侧 `Route35GoldenrodGate` 与 `Route35`，不在本次清理激活。必须先核 Gold 尺寸/图块/连接/门槛/Warp/来源音乐/骑车/Field Moves/显示缓冲；继承现有 `johto_gate_music_bike_audit.py` 音乐续播检查、门毯横移/方向碰撞与飞行/地点名安全限制，不能仅登记路径便视为可运行。

## FIX-5.62.282｜五座活动门房音乐续播及 Bike Song Off 缓存修复（开发候选）

- 从 `.281` 已修复工作区继续，不重复修改森林门房地毯、34号路／满金市地形。用户反馈门房内应延续进入前道路／城镇的歌曲与播放进度，尤其是最近启用的两座桐树林门房。
- 实际运行问题一：`home/audio.asm` 中 `CompareMapMusicBankWithCurrentBank` 只是 `ret`；骑车并关闭 Bike Song 的路径此前执行 `cp $2`（Carry=1），随后 `bit` 不改变 Carry，导致“当前歌号已播放则直接返回”的检查被 `jr c` 跳过，每次重新发送音乐请求。该存根明确清除 Carry，且不得抑制不同歌曲正常换曲。
- 实际运行问题二：`JohtoPilotLoadMapMusic` 的桔梗市侧合法来源分支缺少 `jp .sourceValid`，落到桐树林南门房校验，结果错误回退31号路主题；仅补回合法分支，不改来源登记及其它地图。
- 扩充既有 `tools/johto_gate_music_bike_audit.py`，通过小型 ASM 条件跳转解释器验证全部5座活动门房的每一个合法来源与错误来源在 RBY、GSC 场景选路中的最终选择；增设 Warp→音乐加载→同曲缓存、Bike Song Off 时 Carry 清理检查与8项专项/反向测试。新门房遗漏来源或续播机制被删会让综合审计失败。
- Gold 原版／成熟 NPC 参考分支仅作为选曲与骑行条件依据，不直接使用旧项目的物理地图编号；旧交接快照没有完整 `tools/` 可执行代码，不能宣称旧审计可运行。
- 正式版本 `FIX-5.62.282`，`TEST-231` 不变。源码静态审计无法测量 ROM 中实际播放指针；未自行编译 ROM 或提交 Git，用户仍需本机重编 Red/Blue、核对新MAP ROM0≥64B，实测五座门房入出双方、步行/自行车 Bike Song On/Off 及五种音乐模式。

## FIX-5.62.281｜34号路桐树林北门房合法地毯横向移动修复（开发候选）

- 用户实机报告：从桐树林北门房出来，可以站上34号路两格入口地毯，但不能在两格之间左右行走，骑行同样受阻。源码定位 `.271` 的未开放建筑门槛黑名单仍包含 `(13,37)/(14,37)`，与现行已注册 `Route34 -> Route34IlexForestGate` 两条 `WARP_CARPET_DOWN` 冲突；原 `.278/.280` 路径审计起点用 y36，未检测 y37 地毯横向通行。
- 仅从 `JohtoSouthMatureDoorFence` 封锁表删除两处合法 Warp 地毯坐标，其余24个未开放房门继续封锁。Gold 地形角色、图块、门房转场、骑车标记和 Gold/关都规则不改。`JohtoSouthPortalCollisionExit` 保持站在门毯**向下撞墙**才返回门房；左右走两格地毯只是正常移动，不触发 Warp；恢复步行/骑车共用通路。
- 扩充既有成熟门槛和34号路专项审计：核对实际运行黑名单与注册 Warp 不相交、两格与邻近上侧地形可走、下撞方向准确；新增左右两格错误封锁和改坏出门方向的负向测试。已有 Cut、Surf、跳崖、飞行、配色、地名、边框不另行变更，防止为了修补门口改变成熟森林。
- 正式显示版本 `FIX-5.62.281`，`TEST-231` 不变；ROM0 只变更相同长度版本文本，门槛表减少6个 ROMX 字节。仅离线测试，Red/Blue 新链接 MAP≥64B 与手机两格横向/骑行/进出门验证仍待用户完成。开发阶段只交互斥增量与全量两份补丁，不操作原用户 Git。

## FIX-5.62.280｜合并工作区的全项目静态复核及正式版本校正（开发候选）

- **版本实际生效**：`data/game_version.asm` 普通版从 `FIX-5.62.276` 修正为 `FIX-5.62.280`，覆盖已经累积的 `.278` 工具及 `.279` 游戏修复；测试 ROM 专用 `TEST-231` 不变。字符串字节长度不变、无新 ROM0 指令，不以旧 MAP 宣称新构建验收。
- **完整开发候选**：以 `.276` 用户实际 Worktree ＋ `.278` ＋ `.279` 已交付内容逐层合并；森林成熟碰撞/Cut/Surf/昼夜配色、跳崖输入清理、桧皮镇西侧补图、34号路四列通行及满金市北部预览均保持原状。
- **飞行解锁防回归**：新增 `tools/johto_fly_visit_audit_280.py` 并接入原城都迁移总审计；交叉核对11个稳定飞行目的地的独立事件、实际地图注册、已访问事件位、飞行切换二次检查和 Gold 原始安全落点。当前五座活动城镇对应真实可走落点；另六座仍预留，不因为地名可浏览而自动解锁。加入错误注入和实际版本/项目标题一致性测试。
- **复核范围**：按 Gold 原图执行全部活动地图的 Surf/Cut/跳崖、南线空间水格、森林成熟模块和昼夜图色、门房音乐/骑车、地点名牌及 Town Map、Route34/Goldenrod 边界、原始编译前符号和三条表长 ASSERT。此处均为**离线审计**，不是模拟器执行或设备验证；未开放室内/Route35 不擅自解锁。
- **交付边界**：开发阶段只给两份互斥 `.patch`，增量以用户本轮上传的 `.276` **实际未提交 Worktree** 为前置，已累计包含 `.278`、`.279` 和本轮 `.280`（无需另外打旧补丁）；累计全量以导出记录确认且通过历史补丁逆推的 `b4148ccb783bdf734d621d0b8e8419f24ffe72da` 为前置。不得叠加；无 ROM 编译、链接、新 MAP 或 Git Commit/Push。ROM0 的 `.276` MAP 只作旧证据，本地正式新构建必须确认不少于64B。

## FIX-5.62.279｜34号路／满金市实机截图三项修复（开发候选）

- 用户实机截图确认：森林北门房外34号路右侧树海变空白；34号路往满金市有空气墙；满金市继续向北时门房上方缺失连接预览。此前 TOOL-278 **只看地图存在与可达性**，并错误地把仅两列通行写进了测试，不能再作为实机通过证据。
- Route34 对象 `db $00` 改回 Gold / NPC-243 的室外树墙 `$05`，不修改 Gold `.blk`、地图块集、森林碰撞或 Warp；原版 `data/maps/attributes.asm` 明确为 `$05`。
- 修正有向边界：Route34 `(x=8..11,y=0,UP)` 及 Goldenrod `(x=18..21,y=35,DOWN)` 对称放行四列，坐标与成熟 NPC-243 ILEX-216 一致；其他边界保持封闭、未开放建筑保持禁止进入。
- 满金市北侧图外 `MAP_BORDER` 的三行×十列预览，精确复用旧成熟 `PatchJohtoGoldenrodNorthBorder` 的30字节（来自 Gold Route35 底部三行），**只显示、不解锁 Route35**。在现有 `LoadTileBlockMap` 后置跨 Bank 调用点并入统一 ROMX 边框分发：先保留桧皮镇西墙，再补满金北缓冲，覆盖完整载图和无缝连接两种路径，ROM0 新增调用数为零。
- 扩展 `johto_route34_goldenrod_audit_278` 与负向注入，拒绝把4列缩回2列、使用空白边框、删掉后置调用/桧皮镇原补图、改坏30字节预览、擅自开放 Route35；旧 `johto_mature_reuse_275_audit` 同步检查新的共同钩子。
- 本批为 `FIX-5.62.279` 开发候选；`TEST-231` 不变。手机与最新 Red/Blue ROM、MAP 尚需用户重编并验收，不编译ROM、不提交 Git、不引入 `.2bpp`/MAP 二进制。增量以**已应用 TOOL-278 的实际 Worktree**为前置；累计全量以确认的 Git HEAD `b4148ccb783bdf734d621d0b8e8419f24ffe72da` 为前置。两份互斥，不叠加。

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

## FIX-5.62.275｜成熟分支森林行为复用（开发候选，待本机验收）

- 本轮以 `.274` 源码为开发基线；核心对照 NPC-5.62.243 的 ILEX-217、GATE-202。Gold 角色表仍作为未修改的来源数据，森林正常步行恢复旧版216字节压缩阻挡掩码与成熟 Cut 实际块状态判定，不再只靠重新生成的角色数组。相同稳定 ID、`$FC` 运行句柄可直接复用，但新工程仍需独立 ROMX 接口。
- 修正 `$0f` 与 `$2d` 的 CP/Carry 泄漏：未砍 Cut 树不得被识别为已清除；森林 Cut 动画及相邻摇树保持既有区块替换 `$0F→$2D`。
- 统一 Surf 登岸：南线水格先由 Gold 地图限定判断；非水格必须经同一地图的真实陆地碰撞判定才允许停止 Surf，禁用森林空 `.tilecoll` 的错误岸线回退。空地/墙/树分别验证，不新增全局可走图块白名单。
- 完整复用成熟 `color/tilesets/johto_ilex_forest.asm`（96项）、`JohtoIlexForest.blocked_mask.bin`（216B）和旧版 `JohtoIlexForestCanStepAhead`/Cut 执行语义。桐树林 PNG、已验收跳崖、门房与当前 `jp` 均不变；不提交 `.2bpp` 生成文件。
- 桧皮镇西侧门房室外缺图：旧分支 GATE-202 的 `PatchJohtoAzaleaWestGateBorder` 用于补两块左侧屋顶/墙面图块；从 `LoadTileBlockMap` 两种完成路径共用一次 ROMX 钩子，确保邻图与首次载图都执行。新增 ROM0 `callab` 预计约6字节，实际链接余量以用户新 MAP 为准，必须≥64B。
- Gold 原版批量转换器可用成熟 NPC 工程做源候选审计；新版因没有旧 `maps/JohtoRoute29.blk` 不能直接把旧工具当作新的运行时生成器。本轮保留并运行六图逐格 Gold 检查，新增`johto_mature_reuse_275_audit.py`及负向故障注入，迁移主审计挂钩。
- 开发阶段仅一个ZIP含两份互斥补丁（`.274→.275`及确认 HEAD→`.275`），不编译ROM、不Commit/Push、不声称手机已验收；现有7项旧断言失败需如实报告、不能删除。TEST-231不变。

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

## FIX-5.62.272｜ROM0 空间的长期治理（未链接验收）

- 不能再往 `home/overworld.asm` 重复追加城都地图私有的碰撞派发。将原ROM0 `.ordinaryGateApproach` 后的城都南线判定整体外迁到 Bank `$4F`，ROM0 短网关固定≤30字节；本轮按 RGBDS 宏和指令编码静态计算从124B减至25B、估算释放99B。核心移动／跳崖函数本身不改；前置地图边缘、Sprite 碰撞和门房例外顺序不改。
- 新增 `tools/johto_land_rom0_preflight_272.py` 固定检测 ROM0 网关上限、ROMX Bank 与三态 E 返回语义；保留现有 `tools/johto_rom0_space_preflight.py` 的新 MAP 64B 门槛，不许删除或把旧 MAP 当作新 `.272` 链接证据。
- 未经本机 Red/Blue 最新 `rgblink` 和 MAP，**不得声明 Home Copy Data 已实际链接或 ROM0 达标**。如果新 MAP 余量<64B，应继续把地区特定大型分派外迁，不能搬走必须常驻ROM0的 CopyData、碰撞表或中断。只交互斥两补丁ZIP，不先做正式日志；不编译 ROM/Commit/Push。

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

## CLEAN-267｜正式清理基线及 PNG／JP 保护

- 最新用户上传的 `FIX-5.62.267.patch` 为分支 `常规功能备份` 上的完整未提交 Worktree 导出，基线为 HEAD `438046a6ae6a709b656b8f712eeeecefc6259dda`。清理增量从该**用户实际工作区**出发，累计全量从可逆重建的对应 HEAD 出发；绝不能混用先前窗口生成但未含用户 `jp` 修复的旧累计补丁。
- 已修正 Route33 离线审计及负向测试的 PNG 源文件核对，不再要求 Git 包含被忽略的 `.2bpp`，ROM 游戏代码保持原状。
- 用户实测反馈：洞穴进出与朝向正常、Route33 花屏已消失、骑车及 Fly 可用。尚有一句未说完的“出去的时候……”反馈，其具体内容未获确认，不将所有出洞后的场景标为完整验收。
- `gfx/tilesets/johto_modern.png` 是图形源；`Makefile` 按 `%.2bpp: %.png` 自动生成并依旧被源码 `INCBIN` 引用。`*.2bpp` 被 `.gitignore` 忽略，清理包不得擅自纳入生成的 `johto_modern.2bpp`。PNG 必须在全量补丁中保留。
- 用户对 `home/overworld.asm` 的 `jr nz,.noCollision`→`jp nz,.noCollision` 属于已应用的真实工作区修复，避免短跳距离限制；本轮文档清理不改动或回退该指令。
- 从 HEAD 到 `.267` 的累计差异同时包含运行时及工具审计，按正式清理模式 A：单 ZIP 内 3 个补丁（清理增量、工具／审计反向隔离、HEAD 累计全量）＋两份中文 Git 日志，先功能后工具自行提交；禁止由助手编译 ROM、Commit／Push。TEST-231 不变。

## FIX-5.62.267｜33号道路图块集加载溢出修复（开发候选）

- 症状：联合洞窟南出口进入 Route33 后整屏花屏；并非 Gold 33号路 `.blk`、PNG 或落点写反。
- 根因：`engine/overworld/tileset_header.asm` 原先以8位移位/加法拼出 `tileset * 12`，`JOHTO_MODERN=32` 时中间进位丢失，实际 `$0080` 而非 `$0180`；读取到错误的 ROM Bank/图块指针。`color/loadpalettes.asm` 又以8位 `sla e`×3 求 `tileset * 8`，ID32 时 `$0000` 而非 `$0100`。**旧回归检查没有把新 Tileset ID 32 送过这两段运行时地址计算。**
- 修复：仅将两处索引改用16位 HL 算术，保留 `.266` 地图资源、Gold碰撞、双向 Warp 和 `.265` 朝向。无新 Bank、新 SRAM、无大范围图形替换。
- 防回归：新增 `tools/tileset_index_preflight_267.py`、`tools/tests/test_tileset_index_267.py`，检查 ID 0–32 及故障注入；注意该检查不模拟 ROM VRAM，不能代替手机验收。
- 交付：增量严格从 `.266` 实际开发候选生成，累计全量从 `.266` 原来声明的干净 HEAD `438046a6ae6a709b656b8f712eeeecefc6259dda` 生成，两份互斥；不编译 ROM、不提交 Git、不更新 `TEST-231`。须由用户本机编译并检查新 MAP／南北口和 Route33 显示。

## MAP-266｜联合洞窟南出口＋Route33 开发候选交付（待本机验收）

- 以用户最新完整 `.264` Worktree + 已交付 `.265` 开发修复为增量基线，绝不能误作 `.265` 已提交。累计全量从可验证的干净 HEAD `438046a6ae6a709b656b8f712eeeecefc6259dda` 生成；**互斥补丁二选一**，不叠加。不执行 Git Commit/Push。
- 按成熟 NPC-5.62.243 分支与 Gold `Route33` / `UnionCave1F` 源逐格核验，启用1F南口 `17,31` 与 Route33 `11,9` 双向 Warp 和外侧南移一步；进洞保留当前方向，不强制改向。Route33 独立 Gold 10×9地形／图块／碰撞、草丛视觉角色、音乐／地名／骑车、精确 Gold 跳崖；不改变关都与已验收北口。
- **负向保护：** Route33→AzaleaTown、Route32↔Route33 野外接壤、Union Cave 地下层与剧情遭遇保持关闭；不能因为本轮开南口顺带开放未经验收的地图连接／存档出口。
- 新增图必须保持活动地图数、Town Map、音乐等表长 ASSERT；运行完整单元测试、Gold 迁移／字段技能／门口／ASM 符号和故障注入审计。开发阶段仅两份互斥补丁 ZIP，不附正式 Git 日志，不编译 ROM。旧 MAP ROM0 空间测试异常要单独记录，不得为凑通过删除断言。正式 `MAP-5.62.266`，`TEST-231` 不变。

## FIX-265｜进入洞穴方向不可由出口碰撞方向倒推（待验收开发版）

- Route32 `(6,80)` 朝 UP 进入 Union Cave 1F `(17,3)` 后，默认保留原生 UP，不模拟步进、不强制设置面向 DOWN；出口 `WARP_CARPET_DOWN` 只意味着玩家主动按 DOWN、撞南墙 `(17,4)` 才触发回程。
- 保留 `.264` `ExtraWarpCheck`→ROMX→Carry→最终 guard 的全链路出洞修复和 `wd736` 重置，回到 Route32 `(6,79)` 后仅自动向南 `(6,80)` 一步。禁止修改已验收的门房与关都，不开放 Route33、B1F/B2F。
- 洞穴朝向审计必须拒绝任何到达阶段直接写 `wPlayerDirection`、`wPlayerMovingDirection` 或 Sprite facing（即使强制 UP 也不允许），并用故障注入拦截自动移步／强制朝向回归。以本次 `.264` Worktree 为增量、从可重建的当前 Git HEAD 为全量；仅两份互斥开发补丁 ZIP，不提供正式提交日志、不自行链接 ROM／提交 Git。

## FIX-264｜任何碰撞式 Warp 必须沿整条控制流审计

- **关键教训**：在 `JohtoPilotGateCollisionExitAllowed` 补了出洞方向还不够。玩家碰撞时先通过 `ExtraWarpCheck`，只有 Carry=1 才会进入 `CheckWarpsCollision`，最终 guard 才会运行。
- 新洞口必须同时验证：碰撞/`wd736` Warp 标志 → `ExtraWarpCheck` → ROMX前置资格 → Carry → `CheckWarpsCollision` → 精确方向/坐标 guard → 目标 Warp 表。需以真实代码分支轨迹及反向故障注入确认，不得仅搜索“DOWN”字符串或检查最后一个 guard。
- FIX-263 在视频中复现无法出洞，不能算用户验收。`.264` 只提供开发补丁；用户本机编译与手机复测前不生成正式清理提交日志。不改已验收南北门房和关都逻辑。

## FIX-263R｜补丁真实基线与失败处理

- 最新用户 `FIX-5.62.262.patch` 为 Worktree 差异，基础 HEAD `438046a6ae6a709b656b8f712eeeecefc6259dda`；与交付前本地 `.262` 唯一区别是 `engine/johto_pilot_runtime.asm` 的四条 `jr`→`jp`，不可把本地快照当用户实际状态。
- 从该完整用户差异还原 `.262` 后重新生成增量，保留必要的绝对分支；功能仍为 `.263` 的 Gold WARP_CARPET_DOWN 洞内不自走、向下碰壁出洞、Route32安全单步和骑车许可。若旧 `.263` 曾部分应用，先恢复 `.262`，不得对已污染工作区强打增量。
- 打包前须在 Git 暂存区模拟用户实际模式 `100755/100644`，跑 `git apply --index --check`、正反向逐字节复原和 Gold 回归。不能通过忽略报错或删除 ASSERT 解决。

## FIX-5.62.263 开发基线与验收边界（2026-10-30）

- 用户当前上传的最新完整源码为 `CAV-5.62.260.zip`；其后已提供 `.261` 音乐 ASSERT 修复与 `.262` ROM0 Surf 外迁。`all_maps.zip` 是 ROM MAP 产物，**不是**新的源码全包。本次修复增量以前述 `.262` 已应用的源码为基线；从完整 `.260` 出发则用包含 `.261`、`.262` 的替代累计全量补丁，二选一。
- 本版仅修联合洞穴1F洞口方向、洞内自动走一步和骑车许可，新增独立审计及负例测试。不得把 Gold `WARP_CARPET_DOWN` 当 `DOOR`，也不得从先前测试的结果推断已经验收。
- 本阶段尚未收到 `.263` 本机编译／手机验收；只交两份互斥开发补丁，不提前做 Git 提交日志或工具隔离提交。

## FIX-262｜ROM0 空间和跨 Bank 结果的强制预检

- Johto 活动水域扩展前运行 `python tools/johto_rom0_space_preflight.py --root .`，该项已接入迁移总审计；检查 ROM0 Surf 分流的紧凑入口、原始 Kanto 保留路径、Gold 逐地图水域、吉花市特殊岸线、Bank `$48`、`callab/Bankswitch` Carry/Zero 保持及 ROM0 碰撞表固定要求。
- MAP 容量必须只以**最新用户本机成功链接产生的新 MAP**为最终证据。旧 `.259` MAP 余31字节不能证明 `.262` 能链接；静态估算当前移出ROM0约173字节，也不能宣称新链接成功。项目仍禁止 AI 自行构建 ROM／Git Commit／Push。
- 本次基线为最新用户 `CAV-5.62.260.zip` Worktree + `FIX-5.62.261` 已交付修复；用户上传的 `.260` 带未提交源码，不能把它等同于纯净 Git HEAD。开发阶段仅交互斥补丁、不提前提交日志。

## FIX-261｜新活动地图交付前强制检查表长 ASSERT（2026-10-30）

- 新增任何 Johto 活动地图，除现有 `asm_symbol_preflight.py`、地图迁移、Warp、Gold、Field Moves 检查外，必须执行 `python tools/johto_table_assert_preflight.py --root .`；其结果已经嵌入 `johto_pilot_migration_audit.py`，删掉预检或相关 ASSERT 不得视为通过。
- 应核对 `NUM_JOHTO_ACTIVE_MAPS`、Town Map表、Town Map浏览索引和 `JohtoActiveGSCMusic` 的字节数与槽位一致。CAV-260 曾因第14张联合洞穴缺一条 GSC歌曲导致 `options_menu.asm:1232` 编译 ASSERT 报错。Gold 原始曲目须通过交接参考源码核实，不可以删除 ASM ASSERT 糊弄通过。
- 本次按最新用户 `CAV-5.62.260.zip` Worktree 精确出补丁；该导出 HEAD 是 `438046a6...` 且包含未提交修改，不等同于纯净 HEAD。用户仍需本地构建/MAP/手机复验，验收前不提交清理日志，AI 不编译 ROM/Commit/Push。

## UNION-260｜首张活动洞穴的迁移与交付边界

- 当前开发基线是用户最新 `MUS-5.62.259.zip`；新候选 `CAV-5.62.260`，不改 `TEST-231`。不能用旧 `.256` 或历史 HEAD 混算最新增量。
- 首批只开 Route32 ↔ Union Cave 1F 的双向洞口，B1F/B2F、Route33 全部 fail-closed。采用 Gold 原始块与 NPC compact 资源分别校验，洞穴独立 Tileset/ROM0 collision/Surf；不能将 `JOHTO_PILOT` 野外白名单扩到 cave。
- 入口必须按 Gold 方向、目标 DOOR 和落点后单步自动行走核验；注册新地图时同时检查稳定 ID、活动槽位、bank/headers、Town Map、地点弹窗、音乐、palette、warp、64格水域与岸线。
- 用户尚未本机编译／实测，本轮只交付互斥开发补丁及校验，不附 Git 日志、不执行 Git Commit/Push、不代编译 ROM。

## MUS-259｜门房音乐与骑车验收清理（2026-10-30）

- **本轮最新确认 Git 基线**：用户完整 `FIX-5.62.256.zip` 内 `RPP_PROJECT_CONTEXT/02_EXPORT_INFO.txt` 明确为分支 `常规功能备份`、干净 HEAD `403e41e5ba763b4d747a7bbc6a03d6da161ab1be`、正式版本 `FIX-5.62.256`。该 HEAD 已包含遗迹南侧和 FIX-256 的两笔提交；本次仅从该 HEAD 到最终 `MUS-5.62.259` 计算净差异，不能再重复归入旧功能。
- **用户验收**：用户于本轮明确反馈 `.259` 没有问题，可正式收口；之前确认北门房基本进出正常。本次测试反馈按用户报告记录，AI 没有自行编译／链接 ROM、查看最新 MAP 或执行手机音频检测。不推定每种 RBY/GSC/GSCC/RND 模式和所有旧 SAV 个别场景均已逐项验证。
- **最终功能**：激活 Route36、遗迹北门房并接通遗迹外围北口；保留 DOOR 到达时一次向下自动步进；补全三座已开放 Gold GATE 的真实进入侧曲目继承、同曲缓存不重启、北门房骑车权限；北门房中立地点栏不再显示 `Johto`。Gold INDOOR 自然公园门房、Route36 其他出口、胡说树事件与关都权限继续保持原有限制。游戏正式版本 `FIX-5.62.256 → MUS-5.62.259`，未修改 TEST 版本。
- **强制审计**：新增动态活动地图地点弹窗合同、三座门房 Gold 环境／音乐／骑车合同及故障注入。用户验收后的清理阶段须在 Gold 参考源环境下运行 Python 完整测试、地图迁移、门房音乐骑车专项、ASM 符号、Warp/地形和补丁正反向核对；静态结果独立记载。
- **模式 A 两笔提交**：① `feat(johto)` 游戏运行时 ASM、地图资源及正式版本；② `test(tool)` 工具、合同、负向测试、验收文档与下一批洞穴准入计划。清理包固定三份补丁（从已经应用 `.259` 开发状态到清理定稿的增量、从 `403e41e5...` 源码到定稿的累计全量、工具反向隔离）＋两份中文提交日志。增量／累计全量互斥；先反向隔离工具部分提交功能，再用 `git apply -R` 恢复工具部分提交测试。AI 不在用户仓库执行 Commit/Push。
- **下一阶段洞穴底座边界**：现有 Johto 222 stable ID、活动槽位、Header/Bank、Warp、音乐/地名/保存框架可复用；Union Cave 1F ID8 的 `.blk` 仅 staged，Gold 三层 `.blk/.asm`、旧 NPC 1F 专用 tileset/collision 资源已在用户交接包。当前未实现洞穴独立 Tileset 与 ROM0 碰撞、层间 Warp/返回、受控开放、洞内 Surf、遭遇及存档落点回归。先做1F与Route32双向安全闭环，B1F/B2F、Route33和剧情保持关闭，详见 `docs/JOHTO_UNION_CAVE_READINESS_260.md`。

## MUS-259｜三座活动城都门房的音乐与骑车权限必须逐地图核验（开发候选）

- 用户发现北遗迹门房进入时切错36号路音乐／重新播放；原因是此前仅给31号路门房做入侧音乐继承，其余两座使用固定 GSC 场景；北门房还漏放骑车。统一按注册 Warp 的真实来源稳定 ID 选择 RBY＋GSC，若旧存档来源不可用则回退到本门房 Gold 默认曲，不能继承陈旧 WRAM。相同场景时必须保留播放缓存。
- 三座已激活 Gold GATE（稳定 ID 6、102、19）均显式允许骑车；Gold 环境 INDOOR 的35／36号路自然公园门房不得按名称或贴图放行，关都和房屋白名单不改。
- `tools/johto_gate_music_bike_audit.py` 联合活动地图、neutral 地点栏、双向 Warp 合同、Gold 环境、RBY/GSC 源曲、播放缓存和自行车谓词做强制 FAIL 检查，集成 `johto_pilot_migration_audit.py` 并有故障注入。每次开放新门房必须填写音乐／骑行策略，不得遗漏。
- 基线为现有 `.258` 开发状态（可由用户最新完整 `.256`＋已交付 `.258` 累计补丁重建）；开发目标 `MUS-5.62.259`，`TEST-231` 不变。仅源码与静态验证，禁自行编译 ROM／Git Commit/Push；用户实测通过后再做清理三件套。参见 `docs/JOHTO_GATE_MUSIC_BIKE_259.md`。

## FIX-258｜城都地图地点栏与门房中立规则必须全覆盖（开发候选）

- 开发来源：用户最新完整 `FIX-5.62.256.zip` + 已确认的 `.257` 用户基线修正版增量，目标 `FIX-5.62.258`；`TEST-231` 不变。绝不从旧 Git HEAD 伪造本次增量。
- 每增加城都活动地图，必须先新增 `tools/johto_map_name_sign_contracts.json` 的稳定 ID 对应政策：GATE 门房为 neutral；普通道路／城市／已支持室内指定真实 popup 与 Town Map／Save/Continue 名字。`tools/johto_map_name_sign_audit.py` 必须对照实际活动资源描述表逐项核对，遇新地图漏签、门房缺中立分支、道路落入 `Johto` 默认值、异地名称、地区守卫缺失须 FAIL。
- 新的地图迁移审计 `tools/johto_pilot_migration_audit.py` 必须调用该完整名称审计，不能只检查31号门房；所有正式补丁交付前运行故障注入测试。静态名称检查不替代 ROM 构建和设备验收。
- 本轮只改北门房地点名牌判断及离线审计、合同、测试和维护文档，不改已验收的门房 Warp／自动行走、Surf/Cut/跳崖、存档结构或关都名称。无用户验收不出清理三件套日志、不自行 Git Commit/Push，不自行 RGBDS 编译。

## ALPH-NORTH-001｜北门房上下通行与 Gold 负向测试（开发候选）

- 当前开发基线为用户最新 `FIX-5.62.256.zip`，目标 `MAP-5.62.257`，`TEST-231` 不变。旧 Gold/NPC 分支只用于来源核对与避坑；不照抄其有跨 Bank 图块问题的道路边缘或胡说树 NPC 代用品。
- 本轮开放 Route36RuinsOfAlphGate 稳定 ID19 与 Route36 ID16；北门房顶端两个 UP DOOR，底部两个 DOWN carpet，遗迹北门 UP DOOR，36号路只开放 Gold #3/#4 DOWN carpets。仅真正 DOOR 落点自动向下走一步；绝不能把南门房右车道落入北门房判定。
- 保留旧版所有南侧门房／Surf／Cut／跳崖和存档行为；未完成出口与剧情一律关闭。须跑 Gold 地形、Warp 与负向测试再交增量补丁，ROM/手机验收由用户完成。未验收前无 Git 提交日志、不自行 Commit/Push。

## FIX-5.62.256｜验收清理模式 A（2026-10-30）

- **真实提交基线**：用户上传的 `MAP-5.62.253.zip` 导出记录显示干净 HEAD `3b163292e7fcedef584c469af3dd744add3f573e`。`.254` 南侧通路、`.255` Select 修复、`.256` Gold 方向跳崖均在此 HEAD 之后，尚无用户提供的新 Git Commit 证明；本次日志必须累计覆盖 `3b163292... → FIX-5.62.256`，不能只写最后一个补丁。
- **用户验收**：用户明确报告 FIX-256 已测试通过；遗迹南侧通路与横向门房也已测试、没有问题。按用户报告记录；助手没有自行 RGBDS 编译／链接 ROM、生成新 MAP 或运行手机。
- **正式版本**：`FIX-5.62.256`；`TEST-231` 不变。版本前缀按本版主要修复选择 `FIX`，不回写历史 `MAP-5.62.253` 等版本。
- **当前地图范围**：11 张活动地图；Gold 覆盖 692 WATER、7 CUT_TREE、92 HOP 碰撞格，遗迹跳崖表有16条物理安全方向。遗迹北门房与 Route36 仍未激活。
- **静态复核**：Python 193 项运行、192 通过、1 项跳过（源码导出不含生成的 `patches/rppred.map`，故 Bank MAP 检查按规则跳过）；Surf preflight/coverage、Field Moves、迁移审计75/75、门房参考审计13/13、Warp/落点17/17、ASM局部标签2,068文件均通过。所有 PASS 仅代表静态合同；用户的设备验收是独立证据。
- **模式 A 两笔提交**：① `feat(johto)` 包含南侧两张新地图、Warp/门房、Select、遗迹 Gold 坐标方向跳崖、正式版本及用户功能说明；② `test(tool)` 包含 Gold 门房合同、Field Moves/Surf/迁移审计、负向测试和维护文档。工具合同与测试必须留在第二笔，不能混入功能提交。
- **交付三件套**：一个 ZIP 固定包含清理增量、工具/测试反向隔离补丁、基线累计全量补丁和两份中文提交日志。增量以 FIX-256 开发工作区为前置；全量以 HEAD `3b163292...` 为基线；两者互斥。先反向隔离工具部分提交功能，再 `git apply -R` 恢复工具部分提交第二笔。用户自行核对本地 HEAD/index 并 Commit/Push；助手不执行 Git 操作。
- **下一阶段**：Route36（ID16）＋Route36RuinsOfAlphGate（ID19）＋遗迹外围北门。竖向门房 Gold 上端 DOOR 为 STEP_ON/UP，目标落点 DOOR 后自动 D_DOWN；下端 WARP_CARPET_DOWN 为 COLLISION_ONLY/DOWN；自动步进必须按目标落点角色判断，不能复用横向南门房的无自动步进逻辑。National Park Gate 与其他未完成出口继续关闭。详见 `docs/JOHTO_ALPH_NORTH_GATE_PLAN.md`。

---

## FIX-256｜遗迹跳崖必须按 Gold 坐标和方向登记

- Gold `RuinsOfAlphOutside` 的 HOP 碰撞角色不能直接转成一个通用 tile-pair whitelist。紧凑图块可能被多个 Gold 坐标复用，且 Gold HOP 标签本身不保证两格落点可通行。
- 必须保留 Gold 的 `(x,y,direction)` 白名单，并按 Gold 中间障碍与最终落点验证。当前安全表16条；`(9,30,DOWN)` 必须排除，因为 `(9,32)` 是 WALL。
- `HOP_DOWN_LEFT` / `HOP_DOWN_RIGHT` 是复合方向：分别按 Gold 原版允许 DOWN+LEFT、DOWN+RIGHT，不能将其统一映射为左跳或右跳。
- 复用公共 `HandleLedges → .foundMatch` 执行器；只替换遗迹触发判定。Route29/30/31/32、Violet 与关都的既有逻辑不得随意更改。
- Field Moves 审计必须逐方向比较 Gold 安全候选与运行时坐标表；仅确认存在一个地图专属表不算通过。参见 `docs/JOHTO_RUINS_LEDGE_FIX_256.md`。

## FIX-255｜Select→Start 误触发修复（原遗迹图块配对试修已由 FIX-256 替代）

- 用户实机报告 `.254` 两项缺陷：单独按 Select 偶发打开 Start 菜单；阿露福遗迹左下角左向跳崖不能触发，右侧与下侧功能正常。保留全部已验收地图/水域/门房行为。
- `home/overworld.asm` 的 `TryFishOrRideBike` 会覆盖 A；旧代码直接读取其返回 A 的 Start bit。用 `push af / pop bc / ld a,b` 保留原按钮掩码，`POP BC`、`LD A,B` 不修改标志位，继续使用快捷例程的 carry 表示按键被消费；同时兼容模拟按键路径。
- Gold `RuinsOfAlphOutside` 原始 `HOP_DOWN_LEFT` 转角 `(x5,y30)` 在紧凑图块中左向配对 `$06->$3B`，全图唯一。仅向遗迹专属 `JohtoAlphSouthLedgeTiles` 添加这对；Route29/30/31/32、桔梗市和关都跳崖表保持原样。不修改图块数据、Surf/ Cut、Warp、存档或剧情。
- 正式标记 `FIX-5.62.255`，`TEST-231` 保持。仅开发补丁，不附提交日志；静态检查不代替本机正式红蓝/测试构建及实机 Select/左向跳崖回归；不执行 Git Commit/Push、ROM 编译。

## ALPH-SOUTH-002｜遗迹南侧通路运行时接入（用户已验收）

- 从 ALPH-SOUTH-001 离线候选接入两张新图：Route32RuinsOfAlphGate 稳定 ID102→slot9、RuinsOfAlphOutside ID20→slot10；活动地图9→11，正式版改为 `MAP-5.62.254`，测试版仍 `TEST-231`。
- Gold 原版南侧四对入口按两车道双向登记：32号路 x4,y2/3 ↔ 南门房东侧 x9,y4/5 ↔ 南门房西侧 x0,y4/5 ↔ 遗迹外围 x13,y20/21；保留既有 Route31/Violet 门房与 Route32 冲浪。
- 遗迹外围 Gold 48 格 WATER 接入原有 Surf 三入口及上岸；14格 Gold HOP 在254初版曾 map-ID 独立复用 Route31 跳崖配对（该实现已由 FIX-256 的坐标／方向表替代）；无 Cut 树。门房允许骑车、地点栏/存档名与音乐表同步。
- **关闭范围：** 遗迹内拼图、研究中心、联合洞穴、北门房、Route36、36号路后续出口均未开放；不新增 SAV 字段、不修改关都逻辑。
- 用户后来明确报告南侧门房与遗迹通路实测正常。当前静态工具已更新为11张活动地图、19条登记 Warp 的合同；静态报告不代替用户验收记录。详见 `docs/JOHTO_RUINS_SOUTH_RUNTIME_254.md`。

## ALPH-SOUTH-001｜遗迹南侧资源准备阶段（尚未开放运行地图）

- 此次以用户新上传 `MAP-5.62.253.zip` 为基线，Gold + NPC 旧分支作为资源来源，**仅离线暂存**遗迹外围、32号路遗迹门房及北侧两张源布局；新增 `tools/johto_ruins_stage_contract.json`、独立校验与负例测试。
- 未新增游戏运行时 Header、Warp、活动地图槽位、存档字段；现有 9 张地图与 ROM 均无变化；正式版本 `MAP-5.62.253` 与 `TEST-231` 不动。**不能把 staged candidate 称为可玩激活。**
- 后续先激活 32号路⇄门房⇄遗迹外围，完整审计出入口方向、地毯碰撞与内部门口封闭；36号路与胡说树留后续。不自行 RGBDS 编译、Git Commit/Push。参见 `docs/JOHTO_RUINS_SOUTH_STAGE_254.md`。

## ROUTES-253｜当前活动地图 Field Moves 全覆盖与 Route32 地点栏（正式清理，2026-10-29）

- **本轮正式前缀纠正**：`MAP` 表示地图／野外地形（冲浪、砍树、跳崖、门房与地点栏）功能；旧 `PAL-5.62.250` 等已存在历史版本保持原样，不延续 `PAL` 到本次新功能。正式版本仅将 `PAL-5.62.253` 校正为 `MAP-5.62.253`，数字仍为 `.253`，`TEST-231` 保持不变；该更正不改变任何游戏行为。今后版本前缀须按当次主要功能选择，不机械沿用上轮缩写。
- **已确认基线**：最新可核实的干净 Git 导出仍为 `PAL-5.62.250` / HEAD `722b449ab8ab3a4cf62d905dee6265870e8935ad`。`.251`、`.252`、`.253` 都是开发候选的累计工作区状态，不能假定它们已成为 Git 提交。最终候选为 `MAP-5.62.253`；本轮只做清理，不再改游戏行为。
- **用户验收**：用户明确反馈本轮所有本机测试均通过，包括正式／测试红蓝构建、新 MAP 与手机回归。该项按用户报告记录；助手没有自行编译／链接 ROM，也没有自行运行手机或模拟器。
- **最终范围**：9 张活动地图共 644 个 Gold WATER、7 棵 CUT_TREE、78 个 HOP 碰撞格全部登记；若叶镇此前暂缓的 8 格已启用。Route32 地点栏已从通用 `Johto` 修正为 `Route 32`。当前未激活的联合洞穴、33号道路、桧皮镇仍不开放。
- **本轮重新执行的静态检查**：`GOLD_SOURCE_ROOT=<Gold根目录> JOHTO_GOLD_SOURCE=<Gold根目录> python -m unittest discover -s tools/tests -p 'test_*.py'`：175 项全部通过，无跳过；Surf preflight 与 Gold WATER 逐格核对 PASS；Surf 覆盖与 Field Moves 覆盖 PASS（9 张活动地图、644 WATER、7 CUT_TREE、78 HOP）；ASM 局部标签预检 2,067 个文件 PASS；Gold 迁移审计 69/69、门房审计 12/12、Warp/落点审计 17/17 PASS。静态结果与用户报告的设备验收分开记载。
- **正式清理模式 A**：累计差异包含新增／修改的离线审计工具、Gold 合同、负向回归测试，因此必须拆成两笔：① `feat(johto)` 游戏运行时代码、地图资源、正式版本及用户功能说明；② `test(tool)` 覆盖审计、合同、测试与配套维护文档。游戏版本在第一笔从 `PAL-5.62.250` 更新到 `MAP-5.62.253`；第二笔不改游戏版本，也不更新测试 ROM 版本。
- **交付内容**：单一 ZIP 固定包含 3 份补丁（清理增量、工具部分反向隔离、基线累计全量）和 2 份中文 Git 日志。增量以用户已应用 `.253` 开发状态为前置；累计全量以干净 `.250` HEAD 为基线；两者互斥。反向隔离补丁从完整最终状态中撤回第二笔工具／测试／配套文档，得到只含第一笔功能的状态；用户完成第一笔 Commit 后，用 `git apply -R` 恢复工具部分，再提交第二笔。
- **执行边界**：不自行 Git Commit/Push，不自行编译 ROM，不假设 `.253` 已经提交。用户应先核实本地 HEAD、工作区与 index，再按日志顺序自行执行提交。

## GATE-ROUTES-252｜Gold 骑车环境和 Route29/Route32 地形（历史阶段，已由 ROUTES-253 接替，2026-10-29）

- Gold `GATE` 是可骑车环境，但名字带 `Gate` 不是充分条件：`Route35NationalParkGate` 和 `Route36NationalParkGate` 属于 `INDOOR`，明确不放开。当前**仅**给 Johto 稳定 ID6 Route31VioletGate 的 Bike 检查加 `(map=$FC, region=Johto, stable ID)` 判定，关都原 Bike 白名单保持原状。更多门房在激活时按 Gold 环境逐图审核。
- Route29 精确两棵 Cut，Route32 278 WATER 和1棵 Cut。将 Route32 水格接入 Surf 原有三入口，Gold FLOOR 岸线不可被共享 tile 误判；Route29/32 Cut 使用已存在 `$63→$8D`、`$5F→$8F` 单象限图块交换，不增加 Bank `$03` 入口、映射或 ROM0 旧功能改写。
- `.251` Gold 技能节自动放在近满 ROMX bank，此轮指定原 MAP 空闲 Bank `$48` 保持远调用接口，需用户本地编译确认新 MAP，不能拿旧 MAP 充新验收。测试、合同与文档必须随游戏修改一起交付。
- 基线仍为用户 `.250` 干净导出 HEAD `722b449ab8ab3a4cf62d905dee6265870e8935ad`；`.251` 只知上一轮开发候选，不推断已合并到 Git。交付 `.251→.252` 增量／`.250→.252` 累计全量，严格二选一；AI 不自行 RGBDS 编译或 Git Commit/Push，未收到用户本机回归不生成提交日志。专项说明在 `docs/JOHTO_GATE_ROUTE29_ROUTE32_252.md`。

## CHERRY-250-ACC-001｜吉花市 Surf 用户验收后双笔提交收口（2026-10-29）

- **本次真实提交基线**：用户最近上传的 `PAL-5.62.248.zip` 是已提交且工作区干净的 `d1d833b69c681517102304221e813dd5aa76ff44`。CHERRY-249 与 CHERRY-250 均在此后作为开发补丁，尚未收到新的 Git Commit／HEAD，绝不能从 `.243` 或臆造 `.249` 的 Git 提交计算日志。
- **功能与用户反馈**：吉花市接入 Gold 原版 142 格 WATER，按地区与稳定 ID 限定 Surf 招式、Surfboard、游泳中续行和上岸；西南岩石平台 `(x4..7,y12..13)` Gold FLOOR 共8格，修复紧凑 TILE `$3C` 在水上登陆与陆上移动双路径的误挡，不将 `$3C` 全局放行。用户先报告该平台无法登岸，CHERRY-250 修补后明确要求进行本轮验收清理；这属于用户报告的收口决定，不得写成助手独立运行模拟器或四种 ROM 构建及所有岸线逐项测试均通过。
- **工具与长期约束**：`johto_surf_contracts.json`、`johto_surf_preflight.py` 和负向测试覆盖 Gold WATER 几何、Surf 三入口、登陆 FLOOR／绘图 TILE 复用、地形误判（`MISSING_SHORE_PASSABILITY`）。吉花市、桔梗市登记已实现；Route30／Route31／Route32 仍未开放 Surf；若叶镇东侧按用户要求继续跳过。源 JSON 必须继续 Git 追踪。
- **按项目模式 A 分两笔**：① `feat(johto)` 仅游戏代码及 `PAL-5.62.248 → PAL-5.62.250` 的版本变化；② `test(tool)` 才包含 Surf 合同、Python 测试、专项文档和长期规则，游戏版本保持 `.250`。不改 `TEST-231`、SRAM、门房、其他地图与 ROM 资源。
- **交付与提交安全**：本轮 ZIP 提供从用户已应用 `.250` 工作区出发的纯文档清理增量、从干净 `.248` ZIP 的累计全量，以及两份按真实差异拆分的 `git apply --cached` 暂存补丁与中文提交日志。增量／全量二选一，不重复套用；`--cached` 只用于暂存，不得普通 `git apply` 到工作区。用户自己核查实际 HEAD、工作区与 index 后执行两笔 Commit；AI 不自行 Git Commit／Push，也不自行编译 ROM。
- **未独立验收**：本环境没有对 `.250` 运行 RGBDS 正式／测试红蓝链接和最新 MAP；Gold 对照与 Python 静态审计不能替代这些构建。旧 SAV 全版本兼容、关都全部水域和所有可登陆岸线也不由此推定。下一版先准备跨窗口交接再开放 Route30 Surf。

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

## VIOLET-248-ACC-001｜三笔 Git 提交收口（2026-10-29）

- **实际依据**：用户提供 `PAL-5.62.248.patch`，RPP-BASE 为 `b610217566cedf3ed8f9138d126ab40d56ed41a6`（已提交 PAL-5.62.243）；该补丁累计 SAV-244、Route32-245/246、VIOLET-247/248 与 SURF-AUD-001。本轮以该工作区补丁还原最终文件，并保留 `.248` 游戏实现与 `TEST-231`，不更改 ASM 或存档结构。
- **用户验收**：用户反馈本轮工作区已测试且没有问题；此前明确确认 Route32 往返、桔梗市 Cut、跳崖和 VIOLET-248 Surf 上岸恢复。该反馈不等于助手运行 ROM，不自动证明所有历史旧存档样本和全部红蓝构建场景均被单独覆盖；尤其最初卡住的 SAV 原始样本仍需独立证据。
- **三笔独立提交（按顺序）**：① `fix(save)`：仅旧存档继续游戏时恢复 Tileset 指针和阶段版本 `.244`；② `feat(johto)`：Route32 接入、Fly/Town Map 表、桔梗市三种地形、Surf 上岸修复及最终 `.248` 版本；③ `test(tool)`：Surf 审计、地图与存档防回归测试、长期维护文档。`home/overworld.asm` 和 `data/game_version.asm` 在前两笔均有分阶段差异，**不可按完整文件路径粗暴暂存**。
- **交付执行**：当前用户工作树仅应用收口文档增量，然后在**暂存区保持干净且 HEAD 仍为上述 `.243`** 的前提下，依次 `git apply --cached --check`、`git apply --cached` 三份分笔暂存补丁；每一笔核对 `git diff --cached` 后自行 `git commit -F 中文日志.txt`，切勿对工作树直接应用分笔补丁或把恢复全量重复叠加。累计全量只允许在干净 `.243` 基线恢复时使用。三笔日志标题为英文 Conventional 前缀加中文说明，正文中文。
- **边界**：不由助手编译／链接 ROM，不代提交或 Push。静态审计／补丁回放与用户手机实测分开记录，日后需以用户提供的新 HEAD 更新基线。

## SURF-COVER-002 — 新水域接入前先盘点所有已开放地图

- 先执行 `python tools/johto_surf_coverage_audit.py --gold /Gold根目录`；它从活动 Source/Runtime 描述符发现水域缺口，不能仅凭已登记地图的 `johto_surf_preflight.py` PASS 就宣称所有水域已实现。
- 用户明确要求若叶镇右侧（NewBarkTown）水面先跳过；当前按地图推进顺序第一处待接入是吉花市。除非用户改变范围，不得把联合洞穴等未激活资源算作已经开放。
- 先有覆盖盘点，再为每张目标地图登记 Gold 精确水格、三入口与上岸分支，最后复跑完整 Surf 预检和负向测试。覆盖盘点和源码静态检查都不能替代 RGBDS 链接和用户实测。

## SURF-AUD-001（工具维护）— 城都水域新增前必须复用旧逻辑并静态预检

- 用户确认 VIOLET-248 桔梗市已可上岸。后续地图首先复用项目现有三条 Surf 入口及关都陆地通行扫描，不能只照抄 Gold 水格而忘记 `wTileInFrontOfPlayer -> C`。
- 新增任何城都水面，必须登记 `tools/johto_surf_contracts.json` 并运行 `python tools/johto_surf_preflight.py --gold /Gold根目录`、`python -m unittest discover -s tools/tests -p test_johto_surf_preflight.py`；失败不得打包。没有 Gold 资源时仅能完成非源数据审查，不能宣称逐格一致。
- 旧分支文档有 Surf runtime / geometry 专项脚本名称，但用户提供的旧参考包不含对应脚本文件；当前审计复用的是现有 RPP / Gold 解码库及源码行为合同，并非从旧脚本直接复制。详细边界见 `docs/JOHTO_SURF_PREFLIGHT.md`。
- 本次仅添加工具、合同与文档，**不改动游戏 ROM 源码和可见版本 PAL-5.62.248**；用户尚未提交 SAV-244 到 VIOLET-248 的累计功能修改，不推断新的 Git HEAD。

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

## 旧存档图块指针回放规则（SAV-244）

- 存档 `wCurMapTileset` 的 bit7 表示地图正文从存档恢复（新旧存档均如此）；这个分支允许跳过 ROM 地图 Header，但**不能**沿用可能已经过时的图块集指针。必须保留 `LoadMapHeader` 中旧存档刷新 `LoadTilesetHeader` 的路径。
- 刷新时保存/恢复 `wDestinationWarpID` 并临时设为 `$FF`，避免以刷新指针为由改变存档坐标。保护城都地区/稳定 ID 验证与既有关都读档兼容；不得改 SRAM 布局，不能宣称所有旧档都兼容。
- 后续改 ROM Bank、Tileset、存读档、碰撞或头数据时，交付前运行 `python -m unittest discover -s tools/tests -p test_save_tileset_reload_244.py`、ASM 预检和相关地图审计；仍须用户本机编译/实际旧存档回归才能验收。

## MUS-243-DOC-001 — 最新已报告验收与正式双提交基线（2026-10-29）

- **最近已确认提交基线**：用户上传的 `PAL-5.62.239` 主项目 ZIP，导出元数据记录分支 `常规功能备份`，完整 HEAD `2b0d260729dbf28bc72dd9a739e646b1bfaf35e8`。ZIP 未包含 `.git`，本环境没有手机实时 Git 状态。用户明确说后续 JSON、LOC、MUS-241 等补丁已应用但尚未提交；没有收到任何新的 HEAD，不能虚构中间提交。
- **验收与状态**：用户对 MUS-243 上轮所列音乐和回归项目给出“都测过、没问题”的实机反馈；LOC-240 地点乱码修复也获正确显示反馈。正式版保留 `PAL-5.62.243`，不再改动音乐 ASM。用户尚未提供可独立核验的 `.243` 两色 MAP 空间报告；不把用户的功能验收等同于本环境编译、MAP 审计或全222图完成。
- **按用户原始项目要求选择模式 A**：从 HEAD `.239` 到 `.243` 的累计未提交差异包含游戏运行代码，也包含 `.gitignore`、`tools/asm_symbol_preflight.py` 和工具测试，因此正式收口需**3份补丁+2份日志=一个ZIP**。第一笔仅包含游戏功能与版本文件；第二笔包含工具、测试、Git 忽略规则及配套文档。两份提交日志均从**实际累计差异**分工生成，不单纯记录本轮文档修改。
- **应用顺序**：先在用户已应用 `JSON-TRACK-002 + LOC-240 + MUS-241 + MUS-242 + MUS-243` 的未提交状态应用清理增量；再用工具反向隔离补丁暂时退回工具/文档到 HEAD，仅保留功能做第一笔 Git Commit；接着 `git apply -R` 撤回隔离，恢复工具/文档并做第二笔 Git Commit。全量补丁仅供从干净 `.239` HEAD 恢复使用，绝不能与增量叠加。AI 不自行 Commit/Push 或编译 ROM。
- **边界**：未来新增地图需同步配置 Gold 曲目、来源归属和连接同曲续播审计。用户本次确认的是当前已开放地图与所列回归场景，不代表未开放地图、所有平台或所有历史存档已验收。

## MUS-243 / PAL-5.62.243 — 无缝相邻地图同曲不重播（历史开发说明，用户验收见上方 DOC-001）

- **修复范围**：在 `home/overworld.asm` 的 `CheckMapConnections .loadNewMap` 中，在加载目标 Header 前保留上一地图的 Gold 场景及 RBY 原始 BGM；加载后仅当目的地仍是城都 `$FC`、Gold 场景相同、RBY BGM 相同、当前音乐缓存符合步行／Bike Song Off／Bike Song On／Surf 的预期时，跳过 `PlayDefaultMusicFadeOutCurrent`，保持播放位置。**音乐不同、缓存失效、首次加载、Warp、战斗返回、关都原逻辑均不跳过。** `wd72e` 的战斗后强制重播路径不在普通无缝同曲过图中误触发。
- **Gold 依据**：原版 `home/audio.asm` 的 `FadeToMapMusic` 与 `PlayMapMusic` 比较正在播放的 `wMapMusic` 与目标曲，匹配即返回；`Route30` 与 `Route31` 的地图资料均为 `MUSIC_ROUTE_30`。保留关都原有单曲缓存与正常音乐切换；地点牌是否显示是独立规则，不能拿地图名作歌曲是否变化的依据。
- **覆盖范围边界**：现有 Gold 原曲对照只覆盖 8 个已激活的城都槽位；222 个稳定 ID 并**未**全部完成运行时映射，不新增未开放地图和曲目。关都原有 RBY 音乐及模式映射不等于“222 张 Gold 地图已经适配”。
- **交付**：在 JSON-TRACK-002 + LOC-240 + MUS-241 + MUS-242 已应用、都未 Git Commit 的前提下，提供 MUS-243 增量；累计全量从已确认 `.239` / `HEAD 2b0d2607` 恢复。二者互斥，绝不叠加；用户自行编译红蓝 ROM、检查最新 MAP、手机实测并提交。`tools/tests/test_johto_connected_music_243.py` 提供不运行 ROM 的回归检查，AI 每次改 ASM 仍必须运行 `tools/asm_symbol_preflight.py`。
- **验收**：Route30↔Route31 双向，步行 + Bike Song Off／On + GSC、RBY、RND 连续播放不重头；在吉花市↔Route30、门房↔桔梗市等不同曲场景必须正常换曲；战斗恢复、Surf、存读档、地点牌、门房与关都回归。静态通过不冒充以上实际通过。

## 交付前 ASM 符号预检：每次新窗口必须执行（MUS-242）

- 2026-10-29 用户发现 MUS-241 实际链接错误 `ResolveMusicStyle.rbyFamily` 未定义；原 Python 音乐静态测试未检查分支符号。此类错误在交付前应当被拦截，**不是把“静态测试通过”当作汇编通过**。
- **任何窗口修改 `.asm` 后，交付前强制运行** `python tools/asm_symbol_preflight.py`，默认对完整工程 ASM 的 `JR/JP/CALL` 局部点标签进行作用域校验，并运行 `python -m unittest discover -s tools/tests -p 'test_asm_symbol_preflight_242.py'` 和相关既有审计。发现 undefined local label 即停止打包。新工具的负向故障注入必须持续通过。
- **真实链接仍是必须由用户执行的独立关卡**：`python tools/asm_symbol_preflight.py --build` 会在用户本地使用现有 RGBDS 调用 `make -B red blue test-red test-blue map`，产出正式 Red/Blue、TEST 两色及正式 MAP。AI 严格不自行编译/链接 ROM；没有用户报告的本机构建结果，不能宣称无 `JR` 越界、跨文件符号错误、Bank 溢出或运行正常。若用户提供最新编译错误，先修该错误再继续功能开发。
- 增量基于当前 JSON-TRACK-002 + LOC-240 + MUS-241 已应用、仍未 Git 提交的工作区；累计全量基于上次真正已确认的 `PAL-5.62.239 / HEAD 2b0d2607`。增量、全量二选一，不得叠加；不重复补丁，也不得修改游戏已有存档结构。

## MUS-241 / PAL-5.62.241 — 城都 8 张已激活地图的音乐场景与中立门房（开发待验，2026-10-29）

- **前置工作区**：用户确认已应用 JSON-TRACK-002、LOC-240（地点显示实机已正常），尚未 Git Commit。此次只追加 MUSIC-241 增量；不重复添加/覆盖之前 JSON、Save/Continue 名称修复。正式版本 `.240 -> .241`，`TEST-231` 不变。
- **原版核对**：MUS Gold `data/maps/maps.asm`：若叶镇 New Bark、29 号路 Route29、吉花市 Cherrygrove、30/31号路同为 Route30、向导家 Cherrygrove、桔梗市 Violet、31号路门房 Route30（但中立门房按进入来源继承，不固定开一段歌曲）。旧 `NPC-5.62.243` 的 `LookupJohtoMapGSCMusic` / `CheckJohtoMusicSceneTransition` 仅作五模式与场景缓存参考，绝不直接使用旧物理地图号。
- **新工程映射**：以 `(wCurMap=$FC, region=Johto, stable local ID)` 经 `GetJohtoActiveSlot` 查找 8 条活动槽位的 Gold 主题；状态/表 `0,1,2,3,4,125,5,6` 对应 8 槽。只有当前地图默认 BGM 才参与 Gold 场景映射，战斗、Surf、飞行、GB Player 直选曲继续走现有全局风格路径；Bike Song Off 的骑行仍使用当前地点主题。
- **门房音乐**：进入门房的已登记 Warp 在源 ID 被覆盖前，写入原来闲置的 `$D7C9` `wJohtoGateMusicSourceLocalID`。来自 Route31 ID4 时保留道路 RBY/GSC/RND 已在播曲，来自 Violet ID5 时保留城市曲；旧存档或非法来源退回 Route31 主题，不能从共享句柄 `$FC`、`wWarpedFromWhichMap` 或陈旧 `wLastMap` 猜来源。返回同侧尽量不重启，跨到另一侧选目标地点曲。门房仍**不额外显示地点牌**，地点显示独立。
- **缓存与存档**：`$D7CA` 由旧未用字节记录最近 Gold 场景，不变更后续 WRAM/SRAM 地址或存档长度；跨不同 Gold 场景（即使同 RBY ID）仅在 GSC/GSC+C/RND 且播放地图 BGM 时清除旧原曲缓存。RND **不在进门/地图载入时主动抽曲**，只在真正启动新曲时重抽；RBY/RBY+C 不被强制切换。切回关都清除场景标识并在相应模式下恢复正常选曲。
- **交付和验收边界**：本轮静态测试与补丁回放不等于 ROM 通过。AI 不编译 ROM、Commit 或 Push；等待用户本机红蓝 ROM 构建、新 MAP、五种模式、门房两侧进出、Bike Song On/Off、Surf、存读档、关都与渡轮回归。详情 `docs/JOHTO_MUSIC_SCENES_241.md`。

## JSON 合同及生成文件的长期 Git 管理规则（JSON-TRACK-002，2026-10-29）

- 遵循用户提供的旧 `NPC-5.62.243` 参考分支：**禁止使用根目录全局 `*.json` 忽略规则**，也不再依赖为每个源 JSON 单独写 `!path.json`。新地图合同、审计配置、可复现的资源清单等源 JSON 默认必须能被 Git 发现。
- 只对约定的临时输出目录进行目录级忽略：`extras/**/*.json`、`tools/generated_reports/**/*.json`、`tools/cache/**/*.json`；需保存到 Git 的来源文件、登记清单不得写进这些目录。其它转换输出优先放项目外隔离目录。
- 后续改工具或添加新的 JSON 时，运行 `python -m unittest discover -s tools/tests -p test_gitignore_json_policy.py`，并用 `git status --short`／`git check-ignore -v --no-index <path>` 核对新增源文件。Git 默认可发现不等于已加入索引，仍需由用户决定 Git Commit／Push。
- 已经存在的 `tools/johto_pilot_door_contracts.json` 原样保留，不重复以新增文件补丁创建。

## P6-DOC-001 / PAL-5.62.239 — 清理模式 A 的执行边界（2026-10-28）

- 最新用户 ZIP 真实 HEAD 为 P5 `5c41a696...`，当前 `.239` 源码带未提交修改。正式清理采用**模式 A，功能与工具两个 Git 提交**；用户自行检查真实 Git 状态并 Commit/Push。此次清理不修改游戏可运行 ASM、不改变版本及音乐设置。
- 当前 ZIP 包含原先因 `.gitignore` 忽略而没有进入 Worktree Patch 的门房合同 JSON；文件内容已核验。本次清理增量只调整 `.gitignore` 精确例外及维护文档、移除旧版临时修复文件，**不含新的 JSON 添加操作**。从 P5 HEAD 的完整恢复补丁仍包含 JSON 新建，以便干净仓库恢复。
- 按模式 A 交付增量、工具反向隔离、P5 基线全量三份补丁和功能/工具两份完整提交日志。工具隔离补丁会暂时撤回工具文件，包括已存在的 JSON；操作前应备份该 JSON，并且不能同时与全量补丁叠加。
- 用户反馈门房主路径已可进出，尚未逐项覆盖所有条件。音乐模式和门房来源继承的现存问题留到下一轮独立修复，不在本次提交日志中写成通过。

## P5-DOC-008 / PAL-5.62.233 — 城都底层与两条道路累计验收收口（2026-10-28）

- **本轮 Git 基线**：`常规功能备份`，用户 P4 导出 HEAD `6e65ad26b14822a53128aefd5a3307fc6faeb46d`，游戏正式版 `PAL-5.62.230`。ZIP 不含 `.git`；这是导出元数据，用户提交前应再检查本机 `git rev-parse HEAD`、分支及暂存区。
- **本轮未提交范围**：P5-FRAMEWORK-001（地区感知四方向连接、地图属性/Town Map/音乐映射、完整地图名牌 ID、fail-closed 登记式 Warp）及 Route30 ID3、Route31 ID4（Gold 原始块与运行块、资源/Header/连接条带、封闭边界、跳崖和路牌）；保留既有的五张户外地图和关都编号。此前 `.231`、`.232`、`.233` 均未获得独立 Git Commit 确认。
- **模式 B 单笔功能提交**：从最近已确认的 P4 HEAD 到最终 `.233` 收口，未更改 `tools/`、离线审计程序或工具测试；本轮交付仅一份 ZIP，内含清理增量（已应用 P5-ROUTE31-002 修复后的 `.233` → 收口状态）、累计全量（P4 HEAD → 收口状态）、一份完整拟提交日志。二补丁互斥，禁止叠加。
- **实际验收**：用户报告五张地图走过、30↔31 连接处未见树林残影、跳崖正常；正式红蓝 MAP 有对应活动 Header/资源/连接符号，ROM0 各余594B，Bank `$1C` 红版余0B／蓝版余39B。曾出现 Route30 双向 Header 33B 断言失败；已补漏字节、保留34B ASSERT，并据最终用户构建和跑图记录收口。
- **未覆盖**：城都室内 Warp 目前无实际登记；门房/洞穴多 Tileset、所有未激活地图、全部旧存档及关都综合回归不因本次五图验收自动通过。静态检查、用户 MAP、用户手机反馈分别记录，不互相冒充。
- **后续提交节奏**：这次把已经累积、未提交的 P5 框架和两条道路一次收口，是过渡性累计提交；今后优先每批一两张相邻地图，验收通过就及时提交，避免长期累积。正式版本 `PAL-5.62.230 -> PAL-5.62.233`；测试功能没有变化，不在本笔日志中列出测试版本。用户自行 Commit/Push。

---

## P4-DOC-007 / PAL-5.62.230 — 城都阶段2验收收口（2026-10-27）

- **最新项目 ZIP 基线**：分支 `常规功能备份`，导出 HEAD `8c1789757f529de6eeb43de17b9b2d3e3eb8646a`（已提交的 P3 / `PAL-5.62.224`）。P4-001～P4-006 为其后的累计未提交功能与文档修改。本次清理**只更改四份长期维护文档**，正式 PAL 仍 `PAL-5.62.230`；TEST 代码及版本未动。
- **验收证据**：用户先前确认吉花市↔29号道路可走、P4-004 城都飞行和普通地图位置正常、P4-006 Bike Song Off 上下车不重播音乐；既有渡轮、跳崖和显示反馈为此前阶段实测。未在本环境重新编译/链接 ROM，尚无 P4-006 新红蓝 MAP、各音乐模式的完整矩阵、全部存读档/关都回归证明。
- **模式 B 单提交**：相对该 HEAD 的累计差异无 `tools/`、离线脚本或独立审计工具变更；游戏内 `scripts/*.asm` 如有改动仍属于功能代码。清理增量基于已应用 P4-006 → 文档收口；累计全量基于已确认 HEAD → 收口，两份互斥。ZIP 内另附一份 `commit-message.txt`。
- **范围边界**：Johto 新稳定编号 0／1／2 已激活，剩余编号仅登记不开放。到访解锁 Fly 的11条预登记项不能绕过活动 Header 安全门禁；剧情/野怪/昼夜/原版 NPC 及后续地图留待下一批。用户自行 Git Commit/Push；下一阶段须用后续新导出重新核对 HEAD。

---

## P3-DOC-006 / TEST-231 — 首批城都两地图收口（2026-10-27）

- 当前确认基线为干净 P2 HEAD `495b7dc86ff6cbed5ed80483d1e8488dcb0e70bf`（`PAL-5.62.219 / TEST-226`）；P3-001～005 累计到 `PAL-5.62.224 / TEST-231`，尚无后续已提交新 HEAD 的资料。
- 收到用户 TEST-231 普通地图配色通过反馈；本次只收口 `TODO.md`、`docs/JOHTO_MIGRATION.md`、`PROJECT_DELIVERY_RULES.md` 和 `RPP_DEVELOPMENT_PITFALLS.md`。不改 ASM、图像、战斗、Wild、骑行、游戏显示版本与 tools/，采用模式 B 单提交。
- 清理增量从 TEST-231 已应用源码 → 文档收口后；累计全量从上述 P2 HEAD → P3-DOC-006，二者择一。ZIP 同时包含一份完整拟提交日志，不提交或推送 Git。
- TEST-231 本机截图支持当前 Route29 的 Town Map 颜色通过；用户先前反馈飞行、轮船、跳崖、人物正常。不冒称当前旧 MAP 是 TEST-231 重链接结果，不擅自升级其它测试范围。保留自行车／全部 Fly 解锁／剧情／遭遇有意后置。

---

## PAL-5.62.219 / TEST-226 — 城都 P2 底座验收清理与提交边界（2026-10-27）

- **准确基线**：本次用户主项目 ZIP 的导出记录为分支 `常规功能备份`、HEAD `7c3040b601a221419a50c9bcf572ab2446b6385c`（P1 已提交）+ 未提交的 P2-001～P2-006 Worktree；ZIP 不含 `.git`，不能视作本环境执行的 `git status`。
- **清理范围**：保留 222 固定城都 ID、安全活动槽位/Header/Bank 解析、地区保存兼容、Gold 若叶镇/29 号道路源资源及候选运行数据、Tileset 加载迁移、P2-006 palette 赋值表/集合补齐与长度断言。P2-005D 的 B+SELECT 临时入口与强制激活失败方案不纳入；城都活动地图数量仍为 0。
- **模式 B，单提交**：累计差异未涉及 `tools/` 或独立测试审计脚本。清理增量是当前 `PAL-5.62.219 / TEST-226` 工作区 → 文档收口后的同版状态；累计全量是 HEAD `7c3040b6...` → 收口状态。两份只能择一应用，ZIP 同带一份拟提交日志。
- **已有证据**：用户较早反馈 P2-003 存读档及 P2-005B 关都地图回归正常；当前导出附带正式红蓝 TEST-226 MAP，但本次清理未自行链接 ROM，未实机验证 P2-006 修复乱码或城都可进入。提交时如实注明该边界，并由用户按项目习惯自行编译/MAP 核验与 Git Commit/Push。
- **完成定义**：此笔最多作为 P2 地图底层架构阶段收口，不能声称整个城都通用运行框架、首两张地图双向连接及可玩验收完成。继续保留原项目所有空间、交接和地图审计门禁。

---

## ROM-5.62.211 / TEST-218 — P1 ROM0 清理与提交边界（2026-10-27）

- 清理基线：`TEST-217.zip` 的干净导出 HEAD `486c89c4a032473306267e95d5865149fc0b12a6`，无 `.git`；P1-001 已交付并有后续正式红蓝 MAP。未收到 Git Commit 成功确认，不能把这次清理当作已提交的新 HEAD。
- 变更内容：ROM 扩至 2MB；248 项关都 Header 指针表迁入 Bank `$40` 并增加跨 Bank 查表入口；未引入城都地图或新旧地图编号兼容代码。
- MAP 与回归：正式红蓝各 824B ROM0 空闲，已报告 PC 中心、山洞、普通房屋进出及存读档正常。Fly/跨图边界、测试红蓝 MAP 及 ROM 文件头仍未单独验收。
- 正式清理采用**模式 B**：P1-001 工作区 → 清理完成的文档增量、从上述干净 HEAD → 清理完成的累计全量以及一份精简功能提交日志，三文件单 ZIP。两份补丁互斥，不执行 Git Commit/Push。

---

## TRF-5.62.210 / TEST-217 — DOC-218 正式清理基线与提交边界（2026-10-25）

- **新确认的 Git 基线**：用户上传干净 `TEST-215.zip`，导出记录 HEAD `92ac347531c3fe2f72597a60d91d24b7dd2e9aa2`、分支 `常规功能备份`；包内历史显示 TEST-215 已提交。该导出不含 `.git`，不声称本环境执行 `git status`。此前 `eae3e430…` 是已提交的更早历史，不能重复纳入本次提交说明。
- **提交差异**：从 HEAD `92ac3475…` 到当前清理状态的正式 `TRF-5.62.210` 成功变身清理旧 Disable 两字段，以及独立 TEST-216～217 测试菜单新增 16–21、16/17 双字段判定、文档与验收记录。`DOC-218` 为纯文档清理，不再修改 ASM／正式或测试 ROM 版本。
- **验收范围**：TEST-216 用户 16/17/18 主路径可见符合；TEST217.mp4 的 19/20 正常单招 Struggle 通过，21 真实 Disable 施加后禁用的是敌方 `Disable`（不是 `Tackle`）。05/09 既有野生敌方 PP=0 夹具不稳定仍未修。严格区分录像观察、静态审查与未完成 ROM/Link/MAP。
- **三件套模式 A**：交付 `TEST217→DOC218` 文档清理增量、从干净 HEAD `92ac3475…` 到 DOC218 的累计全量及含两份拟提交日志的合集 ZIP；另提供测试工具反向隔离补丁，用户可先提交正式功能，再恢复测试工具提交第二笔。增量与累计全量不可叠加。所有日志按真实 HEAD 至最终状态写，不重复历史已提交 TRF-209/TEST-215。
- **禁止 AI 自行 Commit/Push/编译 ROM**：用户在本地确认准确 HEAD、源码状态、四目标构建／MAP 后自行提交；没有用户确认的新提交不能当成下一轮基线。

---

# 项目补丁交付与提交日志规范（常规功能备份分支）

> **长期适用，供以后每个新窗口直接读取。** 本文件属于项目源码目录，必须随正式补丁纳入仓库。用户随 ZIP 导出的 `RPP_PROJECT_CONTEXT/03_PROJECT_REQUIREMENTS.txt` 包含完整项目要求；该目录是自动生成的辅助资料，**不能只修改它来保存长期规则**。有其他项目约束时同时遵守原项目要求，不以本文件覆盖已有空间、编译、测试与 Git 规则。

## 项目资料优先级与缺失资料处理（用户新增长期要求）

- **修改本项目时，必须优先使用用户上传的项目 ZIP、准确基线补丁和用户提供的参考资料。若压缩包缺失、无法读取、版本不确定，或完成修改必需的参考资料不齐，立即暂停相关修改，直接向用户索取准确项目 ZIP／资料；不得擅自去 GitHub、网页、公开仓库或其他网络来源补找替代品。**
- 如果已有旧 ZIP + 用户提供且可验证的连续补丁能精确还原最新工作区，可以先使用，不必重复要求上传；如果无法证明一致性，必须询问，不猜基线。不因远端仓库存在而视其为最新本地代码。
- 这一条优先约束包括后续窗口、新人交接、审查和生成补丁的流程；资料不足时明确指出缺口，不提交未经核对源码的猜测补丁。

## 交付阶段区分：功能待验只出补丁；用户要求验收清理三件套时必须附提交日志

1. **增量补丁（`.patch`）**：基于上一轮已经交付的补丁状态；给出精确的前置补丁编号／版本。若上一轮是否应用不确定，写明依赖关系；**不能默认为 Git 已提交**。
2. **全量补丁（`.patch`）**：基于用户本轮提供的原始项目 ZIP，涵盖从该 ZIP 至当前目标状态的累计修改；写清 ZIP 的版本／HEAD。
3. **合集 ZIP（`.zip`）**：包含以上两份补丁；在用户要求验收清理三件套／准备提交时，**还必须包含 `commit-message.txt`**。文件名和补丁编号与交付链接一致。功能刚交付、尚待用户验收时，不要擅自写提交日志。
4. **提交日志（`.txt` + 聊天内可复制文本）**：当用户明确要求**验收清理三件套、提交收口、准备 Git 提交或直接写日志**时，必须完成；以最近实际已提交 HEAD 至最终清理状态的累计差异为依据，附独立链接、ZIP 内副本和聊天正文。不能把末轮纯文档增量的 121→121 当成正式日志跨度；尚未验收的功能开发阶段不得自行提前写日志。

## 用户要求验收清理三件套或提交时的日志写法与基线状态

- 参考 `RPP_PROJECT_CONTEXT/patches/individual/` 中的历史 Commit 标题及描述，格式如 `feat(dex): ...`、`docs(project): ...`，按本次实际修改主题选用；日志包含修改项、检验结论／未验收项及 `Version: 原版本 -> 新版本`。
- **用户现行提交习惯（2026-10-15 确认）：每个已收口版本均由用户自行 Git Commit；后续每版的清理提交日志只写该版本相对上版的内容，不重复前版已提交功能。仅在用户特别说明某一版未提交时，才累计包含那些未提交版本。**这个约定不等于核实远端 Push 或具体 HEAD；如后续 ZIP 的实际差异与所述基线冲突，先重新核对，不虚构提交哈希。
- 累积未提交的 S1、清理、规则补丁时，若用户尚未确认 Git 提交，**一份拟提交日志应覆盖从最近已确认 Git 基线到目标状态的全部未提交修改**，不能只写最后一次文档清理，也不能虚构中间提交。
- **仅用户明确告知已执行 Git Commit，并确认提交点后**，才把该提交作为后续日志及补丁的 Git 基线。交付、测试、生成日志 ≠ 已提交。禁止 AI 自行 Commit、Push。
- 即使只是维护文档、验收清理而没有 ROM 行为改动，也要提供三件套；**用户提出验收清理三件套时必须附提交日志**，但单纯开发中间版、尚待验收的功能补丁不主动预写。可保留游戏内版本不变；待用户明确要求时，再于提交日志中说明版本未变化。功能改动的游戏可见版本按项目现有约定更新，勿批量改旧注释以凑版本。

## 提交日志语言与历史风格（强制）

- Git 提交标题采用项目历史的 Conventional Commit 格式：类型／作用域前缀保留英文，例如 `feat(johto):`、`fix(johto):`、`test(tool):`；**标题的实际修改说明使用中文，提交正文也使用中文**。技术标识、文件名、命令、API、曲目名及测试工具名保留其原文。
- 不得擅自把提交标题和正文整体改成英文。生成日志前，必须先查看用户项目中 `RPP_PROJECT_CONTEXT/patches/individual/` 的真实历史提交；若历史提交标题为英文前缀加中文说明，应保持一致。
- 双提交的两份日志都遵守此规则；日志需简洁、准确地记录本笔真实差异、根因／修复、实际检查、用户实测范围和未验证边界。

## 交付前校验与最小测试

- 增量／全量各自从准确基线做正向和反向补丁检查，验证完整文件字节、路径、权限（含 `100644/100755`）及非预期改动。对 ASM 修改做符号完整性、保存区与 MAP 空间检查，遵守不由 AI 编译 ROM 的要求。
- 每次交付在聊天中写明本阶段实际完成、待完成及**最小测试范围**，不得把静态检查说成游戏运行验证；测试反馈只支持用户实际描述的场景。
- 补丁编号每轮不同，文件名以主题开头，不交付完整项目源码 ZIP。ZIP 中日志不是源码提交的一部分；项目长期规则必须体现在本项目可纳入 Git 的文件中。
- **功能测试完成后进入提交流程，必须先做验收收口清理**：核对用户实际反馈、代码审查结果与尚未测试的边界；更新项目 `TODO.md`、当前专项文档和项目基线记录；必要时整理可复用的开发陷阱；再以更新后的源码状态重新生成并校验增量、全量、合集 ZIP。**用户提出验收清理三件套，就视为已经明确要求提交日志**；此时根据届时真实 Git 基线生成累计提交日志，与两份重生补丁共同封装。**只改 ZIP 内的附带文本、不更新项目文档和两份补丁，不能算完成验收清理。** 即使游戏 ASM 与可见版本号不变，文档新增差异也必须进入正式补丁。

## 历史基线与验收记录（2026-10-12；以下为旧阶段归档，当前基线见最下方 121 记录）

- 本轮最初提供的原始项目 ZIP：`ANIM-5.62.113` / HEAD `a9440aca`；累计全量补丁始终从这份 ZIP 生成。旧版原始代码／文件不因仅更新提交日志而改变。
- 用户已明确确认 `DEX-5.62.114` 和 `DEX-5.62.115` **已 Git 提交**。最近一次**已确认提交的版本**为 `DEX-5.62.115`；未收到提交哈希，不虚构哈希。
- `DEX-5.62.116`：野外／训练师遭遇独立形态 Seen 登记，用户已测试，未独立确认 Git 提交。
- `DEX-5.62.117`：增加成功野外捕获形态 Owned、已见形态选择与切换、当前形态资料权限。用户已实测普通／阿罗拉小拉达分别发现与捕获、跨波波及伽勒尔蛇纹熊的详情切换，并未见形态串位。对审查提出的 `ret`、`wPokedexViewForm`、`D` 寄存器三个问题进行了静态复核，未发现确定错误。**只代表上述范围内的验收，不代表全部获得入口或直接入箱已实测。**
- 用户已要求为 `DEX-5.62.117` 走提交流程，但**尚未明确报告本次 Commit 已执行成功**；在收到这一确认前，Git 基线仍为 `DEX-5.62.115`。本次拟提交日志覆盖 `DEX-5.62.115 -> DEX-5.62.117`，包含 S2-A、可见解锁及本次验收文档清理。
- 本次清理增量是纯文档变更，前置是**已交付并应用的 DEX-5.62.117 功能补丁**；全量仍从 `ANIM-5.62.113` 累积至清理后的 5.62.117。游戏版本号、ASM、PAL、地图、物种总数均不改。
- 后续剩余：赠送／进化／交换独立获得记录、精灵球部分／全部形态收集显示、地区形态研究统计；目前登记 42 条地区形态并非最终名单，形态槽位容量 128、已分配身份位 80 个，未来新形态保持已分配编号不变。旧存档迁移不在项目修改阶段考虑范围内。


## 新项目 ZIP 基线补充（2026-10-13；不改写上方历史交付记录）

- 本次新导出 ZIP 为 `DEX-5.62.117` 干净 HEAD 源码；`RPP_PROJECT_CONTEXT/02_EXPORT_INFO.txt` 明示分支 `常规功能备份`，HEAD `5abf1cf0b57fa34a0d0de74279dfa973ce82c78d`，该条 117 Commit 记录为“未 Push”。ZIP 不含 `.git`，故这里记录的是导出元数据，**不是在本环境执行 `git status` 的证明**。
- `DEX-5.62.118` 的增量与本轮全量**都**以该新 ZIP 为基线；这是本轮新的独立原始 ZIP，不沿用先前 `5.62.113` 全量补丁起点。增量／全量仍各自独立验证。收到用户明确的新 Commit／Push 确认前，不把 118 写成已提交。
- 118 本次仅处理列表精灵球形态收集状态；赠送／进化／交换、地区研究统计以及未实测的满队入箱均保留其现有状态，不假定已验收。若用户随后反馈游戏实测成功，进入正式提交收口前仍需记录真实测试结果并按三件套同步更新文档。

## 119 修复补丁基线与验收状态（2026-10-13）

- `DEX-5.62.118/S4-001` 已交付、用户执行编译到链接阶段，但报 `RegionalDexOwnedAction.missing` 未定义；**118 未通过链接，不得声称本阶段编译成功或实机验收通过**。
- `DEX-5.62.119/S4-002` 的增量严格基于已经应用 S4-001 的 118 源码状态，全量以本次 `5abf1cf0` 的干净 117 ZIP 为起点并包含 S4-001 与 S4-002 两轮改动。两份补丁**不能叠加应用**。
- 本轮修复局部标签作用域及普通物种 Owned 回退检查传参，增加可复用的 RGBDS 标签／远调用寄存器陷阱；未变更形态身份、存档、配色设计与物种计数。只要用户尚未明确确认 119 Commit，就保持其为待提交状态。

## 119 用户实测与后续待办整理（2026-10-13；仅文档变更）

- 用户反馈 119 主要游戏功能可运行：普通波波彩球、单独捕获阿罗拉小拉达灰球、两种蛇纹熊全部捕获彩球；满队捕获并直接入 PC 后图鉴更新，上下切换正常。此反馈支持这些路径的实机验收，不自动代表全部刷新入口、更多地区形态或全部 ROM 版本通过。
- 野外遇敌 HUD 小灰球现依物种级 Owned，不符合用户新增的按**当前敌方具体形态是否已捕获**显示灰球／不显示球的要求；暂不更改小球尺寸、图块或颜色。第二种蛇纹熊捕获不再弹出完整图鉴，现有代码基于物种首次捕获判断，是否需要每个首次捕获形态均弹出尚未决定。
- 用户重新指定图鉴详情按键目标：START 向后切换已见地区形态、SELECT 查看当前宝可梦背面。此前正背图功能暂缓记录以新 TODO 为准；不能影响图鉴列表的现有 START／SELECT 功能。详见 `TODO.md` 与 `docs/REGIONAL_DEX_114_STAGES.md`。
- 本轮 **DOC-119-003** 只清理 119 验收记录与新增 TODO，不改 ASM／游戏可见版本。自 `S4-002` 应用后的 119 文件状态出发生成文档增量；自用户提供的 117/HEAD `5abf1cf0` 项目 ZIP 出发生成累计全量。两份只能择其一；尚无用户确认 119 Git Commit。

## 120 S5 敌方 HUD 形态捕获标记（2026-10-13；交付时待验，现已有用户核心实测）

- 源码继续以用户 ZIP `DEX-5.62.117 / HEAD 5abf1cf0` 及已交付 `S4-001`、`S4-002`、`DOC-003` 的精确状态作为本轮基线；未获新的 Git Commit 确认，不假定 119 已提交。
- `DEX-5.62.120/S5-004` 只调整野外遭遇 HUD 的已捕获小灰球是否显示：通过原始 Species2 + 锁定的野外形态 marker 检查具体形态 Owned；未捕获时清旧球；没有地区身份的普通物种仍回退物种级位。原 `$E9` 图块、尺寸、PAL、图鉴列表三态、208 物种计数和存档结构不变。
- 当时尚无最新项目 ZIP 的提交确认，曾按旧 117 基线规划未来提交日志；**该历史计划已被后续用户上传 ZIP 中的 119 HEAD `89694af4` 更新，不能再作为当前日志跨度**。增量补丁仅覆盖 `DEX-5.62.119 + DOC-003 → 120`。用户侧 ROM 编译与实机测试均未由 AI 执行。

## 121 S6 源码基线及验收边界（2026-10-13）

- 用户本次新传 ZIP 文件名含 `119`，但 `data/game_version.asm` 实际是 `DEX-5.62.120`。`RPP_PROJECT_CONTEXT/02_EXPORT_INFO.txt` 记录 HEAD `89694af4d11d3e7d706a2fd91fddc90030c7ecf4`（119 的 Git Commit），并有未提交 120 HUD 工作区修改。增量／基于此项目 ZIP 的全量必须以**实际 120 文件状态**为前置，不能重做或覆盖已经实测正确的 HUD 改动。
- 最新导出记录中最后一个实际 Git Commit 为 `DEX-5.62.119 / 89694af4`，后续 120 与 121 的代码交付、实机验证都不自动变为 Git 提交。**只有用户明确要求时**，才以届时确认的 HEAD 和累计差异制作正式提交日志，不能把功能待验或文档清理当成提交请求。
- 121 不改变身流程；120 野外 HUD 小球已由用户反馈通过独立形态测试。此次只要求首次捕获另一形态弹出正确图鉴及重复捕获不弹的最小实测，不重复要求旧版变身、PC 入箱、S4 彩球的整套回归。

## 121 S6 用户验收与 DOC-006 清理（2026-10-13；纯文档补丁）

- 用户已确认 `DEX-5.62.120/S5-004` 野外遇敌 HUD 的小灰球按实际普通／地区形态独立判断正确；`DEX-5.62.121/S6-005` 新增的“捕获此前未 Owned 的另一形态后，能够自动进入图鉴”也已由用户实际游戏验证通过。此次验收结论只覆盖用户明确反馈的核心场景，不能据此宣称**重复捕获已 Owned 的同形态一定不再弹窗**、所有捕获顺序／形态图鉴页面以及全部 ROM 版本已经逐一验证。
- 以前已确认的变身、图鉴灰／彩球、满队直接入箱等功能，此轮 121 没有修改它们的执行路径；没有回归信号时不重复要求用户专门实测。
- 本轮 `DOC-006` **只整理项目规则、TODO 和专项验收说明**，不修改任何 ASM、图像、PAL、存档位表、游戏版本或 Git 提交状态。游戏继续显示 `DEX-5.62.121`。
- 文档增量补丁从已应用 `S6-005` 的 121 文件状态开始；累计全量补丁从用户最近上传 ZIP 的**实际 `DEX-5.62.120` 工作区**开始，累计包括 `S6-005` 和本次 DOC-006 清理。该 ZIP 文件名含 119 不代表文件状态是 119。两份补丁择一应用，不能叠加。
- **最新澄清：功能未验收时不能擅自写日志；用户要求“清理三件套”就必须同时写完整 Git 提交日志并放入合集 ZIP，日志覆盖最近实际已提交 HEAD 至最终清理状态的全部未提交改动。** 上方含“每轮日志”字样的旧阶段说明是历史规则，均以本节和文件顶部的最新交付规范为准。

## 121 DOC-007 验收清理日志收口纠正（2026-10-13）

- 用户确认上一版 DOC-006 清理三件套遗漏提交日志，属于交付错误；**请求清理三件套本身即包含提交日志要求**，并不与“开发尚待验收时不可提前写日志”相矛盾。
- 本轮只修正项目交付规则和专项文档的错误描述、补齐日志及重新生成补丁，不改 ASM、游戏数据或版本。当前源代码状态仍为 `DEX-5.62.121`；提交日志基线为最新导出确认为已提交的 `DEX-5.62.119 / 89694af4`，而非 DOC-007 文档增量的 121→121。
- 主要文档增量基于已应用 S6-005、尚未应用 DOC-006 的 121 文件状态；如已经应用 DOC-006，则改用 DOC-006→DOC-007 的额外修正规则补丁。全量仍基于本轮用户上传 ZIP 的实际 120 Worktree；同时另附 119 HEAD→121 的累计补丁便于核对 Git 提交跨度。


## DEX-5.62.122 开发基线补充（S7-001；待实测，不是 Git 提交）

- 新上传项目 ZIP 内的 `data/game_version.asm` 为 `DEX-5.62.121`，`RPP_PROJECT_CONTEXT/02_EXPORT_INFO.txt` 明示干净 HEAD `0ce0b96768ce88911828c0973fb8641eee84adde`、无未提交 Patch。该基线**覆盖旧文档中“仅 119 已提交”的历史状态**；ZIP 没有 `.git`，不能将导出记录写作本环境执行 `git status` 的结果。
- 本阶段进行详情 START 后一已 Seen 形态、SELECT 当前形态正背切换，目标版本 `DEX-5.62.122`；同轮增量与本次 ZIP 全量都以其真实 121 文件状态为前置，不能重复覆盖已经提交的 120/121 功能。
- 用户此轮只说继续开发，**没有要求验收清理／提交日志**。只交付待验收补丁两份与合集 ZIP，不预写 Git Commit 日志。待用户实测并要求验收清理三件套时，再更新验收状态并正式提供日志。


## DEX-5.62.123 / S7-002 补修与当前有效约束（2026-10-13）

- DEX-5.62.122/S7-001 已被用户实测发现 SELECT 背图切换后偶发画面空白／花屏，不能写成验收通过或已提交。用户要求背面朝向在 START、上下物种切换和退出/重新进入图鉴之间保持，游戏重启默认为正面；122 与 123 应在修复并验收后统一提交。
- 123 的增量以已应用 S7-001 的 122 文件状态为准确前置；累计全量仍以最新用户确认的原始干净 121 / HEAD `0ce0b967` 项目 ZIP 为基线。日志只有在用户要求验收清理三件套时产生，当前不提前制作。
- 123 不改变存档字段/地区形态身份/配色资源、变身/捕获/PC/HUD 等既有功能。对旧版用户已验收路径，不无故要求重复整套回归。


## DEX-5.62.124 / S7-003 开发交付边界（2026-10-13）

- 基于尚未提交的 123 / S7-002 增量，或基于干净 121 / HEAD `0ce0b967` 的 122+123+124 累计全量；不可重复叠加两种补丁。124 仅改图鉴 PAL 与图片上传的先后次序以防止中途彩色 PAL 提前暴露半成品图块；没有改独立 Seen／Owned、变身、地区图鉴球和 PC。
- 未经 ROM 编译与实测，不能宣称花屏已经验收解决。图像重绘过程可能出现白色遮罩，而不应与残缺图块混为同一验收结论。开发阶段不生成 Git 提交日志，用户要求正式验收清理三件套时再生成累计日志。

## DEX-5.62.124 / S7 验收清理基线（2026-10-13）

- 用户本轮上传 `DEX-5.62.124.patch`，头部标注分支 `常规功能备份` 和 BASE `0ce0b96768ce88911828c0973fb8641eee84adde`。该文件包含 121→124 的完整工作区差异，共 10 个文件，能在此前用户上传的干净 121 ZIP 上正向回放，并能从实际 124 工作树反向回放。用户提供的是 Patch，不是新的 Git HEAD 提交证明。
- 用户实际确认 124 的 SELECT 正反、上下更换物种、START 切换地区形态均可正常使用，原先报告的图像花屏未在本轮反馈中再出现。此处不延伸宣称另一种 ROM 模式、重启偏好等未经专项测试的路径已通过。122/123 是同一轮功能中间版本，不需要独立 Git 提交。
- 自审发现前次 S7-003 交付中，名为“121→124 全量”的文件实际上只有 123→124 的 5 个文件改动，**不能再当作从 121 出发的完整补丁**。本次正式合集重新以用户上传的完整 10 文件 Patch 为依据制作累计全量，并通过正反向及字节/权限验证。严禁沿用旧误标的全量文件。
- 本次正式验收清理增量仅修改 `PROJECT_DELIVERY_RULES.md`、`TODO.md`、`docs/REGIONAL_DEX_114_STAGES.md`、`RPP_DEVELOPMENT_PITFALLS.md`；ASM、游戏版本 `DEX-5.62.124`、PAL、存档与固定地区形态 ID 不变。提交日志严格采用最新已提交的 121 HEAD → 清理后的 124，且在 ZIP 与聊天正文同时提供；AI 不替用户编译 ROM、Commit 或 Push。


## DEX-5.62.127 / S8-003（外部捕获图鉴 A 两页；开发阶段）

- 以前 126 的外部图鉴临时 SELECT 正反切换由本轮新需求替代：首次捕获页 1 正面，第一次 A 进入页 2 背面，第二次 A 退出；B 提前退出，SELECT／START 无额外动作。该版本只改外部图鉴输入及页面/背图切换，不修改 StatusScreen、内部图鉴已验收的正背和形态循环。
- 继续依照固定基线生成 126→127 增量、121/HEAD `0ce0b967` →127 累计全量与无日志合集。仅当用户要求验收清理三件套时再生成提交日志；本轮不得声称已链接或实测通过。


## DEX-5.62.128 / S8-004 用户最终范围与清理提交（2026-10-13）

- 用户明确取消 125～127 首次捕获自动图鉴的所有正／背面扩展，恢复 124 原外部描述 `TextCommandProcessor` / A/B 路径；**不能回退 121 的逐形态首次捕获弹出**，也不能触碰 124 内部图鉴的记忆式正背面浏览。
- Party、战斗 Party 和 Bill's PC 存取详情继续使用 126 修复后的共享 StatusScreen SELECT 临时正背切换及 UP/DOWN 保持状态；不要把这部分一并撤销，或为捕获弹窗重写它。临时 WRAM 仅用于 Party／PC。
- 用户要求“清理三件套”，**必须**附 Git 提交日志 TXT、ZIP 副本和可复制正文。127→128 增量只对准确 127 源码；累计全量和提交日志从最近可核实的干净 121/HEAD `0ce0b967` 到最终 128。未经提供新的已提交 HEAD，不自行声称 124/127 已 Commit；如果用户后来实际提交了 124，应据新确认的 HEAD 重建提交跨度。
- 静态检验和正反向补丁验证不等于 ROM 链接或 128 实机验收。用户曾证明 125 三个 Party／PC 入口能切换，126 修复后撕裂是否消失未收到独立确认；不得把“保留现状”写成“所有显示路径已经验收”。


## DEX-5.62.129 / S9-001 新提交基线（2026-10-13）

- 用户明确确认 128 已执行 Git 提交；新版本开发从 `DEX-5.62.128` 源码状态出发，不再将 121→128 的中间补丁列入下次提交说明。用户暂未提供 128 的提交哈希，不自行编造；本次增量从已验收清理的 128 文件状态出发，累计全量仍按本次可复原的最初干净项目 ZIP 121/HEAD `0ce0b967` 的准确内容生成，二者只应用一份。
- **正式 Git 提交日志必须简短、面向最终提交状态**：只写本次提交实际保留的代码／行为、必要边界及版本跨度。不要罗列本地试验、已撤销的中间版本与反复修正的临时过程；用户要求验收清理三件套后再生成日志，功能待验阶段不预写。
- S9 为赠送、进化、交换实际成功获得渠道的独立形态 Seen／Owned，复用原存档位与已有身份表，不改捕获、UI、配色或通信协议；不能把静态／补丁回放代替 ROM 链接和游戏实测。


## DEX-5.62.129 / S9 验收收口（2026-10-13）

- 用户确认赠送／领取、成功进化和 NPC 交换三个获得渠道的专项实测均正常，且 TEST-002／TEST-003 已全部反向撤销。通信交换双端、赠送箱满边界及其他来源未单独验收，不扩写结论。
- 本次 DOC-004 只清理维护记录，游戏版本保留 `DEX-5.62.129`；正式累计全量按 128 已提交基线 `584b1ba896dea5e2f630d9ebaf9b16399866b712` → 129，文档增量仅针对已应用 S9-001 的 129 工作区。
- 正式提交日志只写最终保留的获得登记功能、三项实测及尚未覆盖的通信交换，不罗列本地临时测试过程；不执行 ROM 编译、Git Commit 或 Push。


## S10 / DEX-5.62.130 源码交付基线

- 用户上传的最新项目 ZIP 的游戏版本为 `DEX-5.62.129`；`RPP_PROJECT_CONTEXT/02_EXPORT_INFO.txt` 记录干净 HEAD `88853cab9961eef6a37f08cfdfe8e898a52da14a`，无未提交 Patch；ZIP 不含 `.git`，这不是本环境运行 `git status` 的结果。130 的增量和本轮该 ZIP 的全量均从同一准确 129 状态产生，不能重复叠加。
- 130 开发阶段仅交付增量、全量、合集 ZIP 及应用/测试说明；用户要求验收清理三件套时才另附**简短、只写最终实际改动**的 Git 提交日志。AI 不执行 ROM 编译、Commit/Push；补丁回放不代表链接或实测成功。


## DEX-5.62.131 / S10-DOC-003 定版清理与提交基线（2026-10-13）

- 用户明确选择以 `DEX-5.62.131` 现有功能方案定稿并要求清理三件套；**这是定版／准备提交指示，不是对 131 修复后 ROM 运行成功的实测报告**。130 的 `Seen: 0/42` 后卡住是已报告的问题；131 的 `TX_NUM` 后两处 `text ""` 为源码修复，修复后的博士本人／PC 对话及 Seen／Owned 增减仍待用户验证。
- 本轮 `S10-DOC-003` **仅维护** `TODO.md`、`docs/REGIONAL_DEX_114_STAGES.md`、`PROJECT_DELIVERY_RULES.md`、`RPP_DEVELOPMENT_PITFALLS.md`；不改变 ASM、游戏可见版本 `DEX-5.62.131`、ROM Bank、身份表、存档或旧图鉴评价。S10-001／S10-002 的开发期记录作为历史保留，以本节的交付状态为准。
- 增量补丁从**上一轮已交付并应用 `S10-002` 的 131 工作区**出发，仅包含上述定版文档变化。累计全量从**本轮上传的真实 `DEX-5.62.130` Worktree ZIP** 出发，包括 130→131 的文本修复、版本号和 S10 文档记录，再加本轮清理。两者二选一，不叠加。
- 拟提交 Git 日志覆盖导出信息记录的最新 HEAD `88853cab9961eef6a37f08cfdfe8e898a52da14a`（`DEX-5.62.129`）到最终 `DEX-5.62.131`，包括 130 地区研究统计、131 文本修复及维护记录，而不只写 `131→131` 的文档增量。上传 ZIP 已含 130 未提交修改；**ZIP 基线与 Git HEAD 基线不同**。仅用户之后确认完成 Git Commit 并提供新提交点，才更新未来的 Git 基线。
- 合集 ZIP 必须包含本次增量补丁、累计全量补丁及 `commit-message.txt`，提交日志也提供独立文件和聊天内可复制正文；补丁需验证正反向、逐字节、路径、权限及差异范围。不由 AI 编译 ROM，不执行 Git Commit/Push，静态验证不能冒充 ROM 链接与实机验收。


## INT-5.62.133 / INTRO-DOC-003 定稿验收清理（2026-10-14）

- 以用户这次上传的 `DEX-5.62.131` 干净项目 ZIP／导出 HEAD `ac1612cea3ca0fb9e8c8383ee8ce4d9e4994f15f` 为本次累计全量及拟提交日志起点。先前的 `INT-5.62.132` 与 `INT-5.62.133` 补丁均未获“已 Git Commit”确认，不能擅自转移最近已提交基线。
- 用户明确实测：新游戏前（无 Continue）显示 Mateo 首页；已有 Continue 则跳过 Mateo 首页并保留其他开场。这两条主路径按测试反馈验收；损坏存档、软重启和其他 ROM 模式未经单独实测，不能越界称通过。
- 审查确认：`PlayShootingStar` 只跳过 Mateo 分支；只读存档判断复用玩家名标记和主存档校验和；音频更新期间使用 `wHaltAudio` 防止 SRAM Bank 0 切换，并恢复原值；Bank-switch 返回 Carry 供分支使用。未发现本次已验收主路径需要新增运行逻辑的确定性问题。用户测试不等于本环境执行 ROM 编译或链接。
- 本次 `INTRO-DOC-003` 只清理 `TODO.md`、`docs/INTRO_MATEO_CONTINUE.md`、`RPP_DEVELOPMENT_PITFALLS.md`、本文件及该功能两处 132→133 注释。**未改变功能指令、存档布局或游戏内版本 `INT-5.62.133`**。不顺带实现 START 直接 Continue。
- 正式增量从已应用 `intro-5.62.133-002` 的 133 文件状态出发；正式累计全量从本次 131 ZIP 出发包含 132／133 功能修复及本轮清理；两份择一应用，不叠加。合集 ZIP 内附两补丁及 `commit-message.txt`。拟提交日志覆盖已确认的 131 HEAD → 定稿 133，简述最终保留功能与实际验收／未覆盖边界。用户自行 Commit/Push。
- 补丁应分别正反回放并核验逐字节一致性、权限、路径、汇编符号及逻辑；ZIP 没有 MAP，因此没有实际链接空间结论。AI 不编译 ROM。


## MENU-5.62.137 / MENU-FULL-010 针对用户重新上传 131 ZIP 的基线说明（待游戏验收）

- 当前用户明确撤销旧工作区并重新上传干净 `DEX-5.62.131` 项目 ZIP／导出 HEAD `ac1612cea3ca0fb9e8c8383ee8ce4d9e4994f15f`；上轮 `009` 错误地从 `INT-5.62.133` 起算，不适用于本 ZIP。本次 `010` 累计全量直接从真实 131 文件状态到 `MENU-5.62.137`，补齐 133 Mateo 条件首页功能与 137 菜单优化；新建 `engine/intro_save_check.asm` 和 `docs/INTRO_MATEO_CONTINUE.md`。
- 完整还原 `engine/titlescreen.asm` 原样，保留完整叫声、标题音乐、调色板与轮播时序；菜单按 B 走原 `DisplayTitleScreen`。只加快菜单白屏阶段并缓存 Continue 信息页以减少按 B 闪烁，不加入意外的 `engine/battle/core.asm` 战斗转场试验或导出用的 `RPP_PROJECT_CONTEXT` 元数据。
- 本版只完成静态源码与补丁适用性验证，尚未编译、链接或实机测试 137。没有 MAP 文件，不能宣称链接空间验证通过；目前不生成待提交日志，不执行 Git Commit/Push。


## MENU-5.62.138 / MENU-012 功能开发补丁（待游戏验收）

- 用户将优化时间明确限定为宝可梦完整叫声结束后至主菜单出现的白屏，不要求缩短或删除音效。视频中 137 白屏约 1.25 秒只作为实测基准；代码节省帧数是静态估计，不得写成 138 已实测的秒数。
- 本轮只在 `engine/save.asm` 将 `LoadSAV` 的 `ClearScreen`、`LoadFontTilePatterns`、`LoadTextBoxTilePatterns` 移入 `.badsum`，避免正常有存档时在主菜单必然重载同一套 VRAM 资源。所有 SRAM 校验、加载路径和损坏数据告警保留。`engine/titlescreen.asm` 严格不变；`engine/menu/main_menu.asm` 的 137 Continue B 无闪缓存同样不变。
- 本轮增量以已应用 MENU-5.62.137（011／010，直接来自 131）的工作区为准确前置；累计全量来自用户 3476 文件 `DEX-5.62.131` ZIP／HEAD `ac1612ce`，包含 133 Mateo 与 137 菜单功能及 138 优化，两者择一、不叠加。仍不编译 ROM，不执行 Commit/Push，当前没有 MAP 文件；先待游戏验收，不提交日志。


## MENU-5.62.139 / INTRO-013 正式收口（2026-10-14；准备用户自行 Git 提交）

- 这次用户明确决定 **Mateo Presents 每次启动均显示**，不再针对有 Continue 的存档跳过。该最新选择覆盖 `INT-5.62.133` 的历史条件显示方案；撤销 `PlayShootingStar` 的 `IntroHasContinueSave` 远调用和条件标签，删除无人使用的 `engine/intro_save_check.asm`，同时删除 `main.asm` 对该 ROMX 例程的包含段。标题轮播 `engine/titlescreen.asm`、流星和耿鬼／尼多力诺音效／跳过按键、完整 `PlayCry` 均不更改；不新增 HOME、ROMX 或存档字段。
- 保留 `MENU-5.62.137` 主菜单后台绘制／Continue 信息页返回缓存、防 B 键穿透，和 `MENU-5.62.138` 正常存档路径去除重复图形传输的优化；用户对 138 的白屏加载表示明显改善，但本次 139 恢复 Mateo 尚待重新实测。此前视频对白屏约 1.25→0.83 秒的测量属录屏近似估计，不含宝可梦叫声。损坏存档警告、软复位、跨版本 ROM 等未单独验收。
- 用户指出 GAME FREAK 流星与耿鬼／尼多力诺对战按 A 时偶发音量／声音切换异常，本次**不猜测性修改音频**，仅列下一版单独排查。不得将先前 Crysaudio 通道重叠的静态推断写作已经复现并确认的根因。
- 上次 `138` 为尚未确认 Git 提交的工作区功能补丁；最新可核实干净提交基线仍是用户上传 `DEX-5.62.131` ZIP／HEAD `ac1612cea3ca0fb9e8c8383ee8ce4d9e4994f15f`。本次正式**增量从已应用 `MENU-5.62.138/012` 起**，**累计全量从该干净 131 项目 ZIP 起**；两者择一。ZIP 内应有两份补丁与 `commit-message.txt`，提交日志描述 131→139 的最终实际保留修改，而不是只写 138→139。
- 本轮按“验收清理三件套”更新原生 `TODO.md`、此文件和 `docs/INTRO_MATEO_CONTINUE.md` 后重生补丁并验证；源码 ZIP 无 MAP，本环境不编译、不执行 Commit/Push。139 的 Mateo 常驻及其与主菜单的组合仍须用户完成最小运行检查。


## SFX-5.62.140 / AUDIO-014 开场中断音效独立补丁（待验收）

- 用户明确报告已提交 MENU-5.62.139，此次开发以其完整 139 源码为增量基线；累计全量仍以本对话原始干净 `DEX-5.62.131` ZIP／导出 HEAD `ac1612ce` 为起点。根据要求不擅自 Commit/Push，不在开发待验阶段生成提交日志。
- 仅在 GAME FREAK 流星／耿鬼与尼多力诺开场返回 Carry（中断）时，停止仍活动的 CH5～CH8 音效及对应硬件 DAC，使用可浮动 ROMX 而非在 HOME 增加整段例程。正常播放、音乐总线、标题 `PlayCry`、Mateo、主菜单加载及 Continue B 返回缓存均保留。不在全局 `PlayMusic` 内加入停止所有 SFX 的行为，以免破坏音效叠加的其他场景。
- 符号、补丁正反应用、内容及权限由静态验证；项目无 MAP，不编译/链接，音频瞬断、Music Off/BGM Volume 0 和其他 ROM 变体需要游戏实测。


## SFX-5.62.141 / BATTLE-015 低 HP 战斗音效专项（用户已完成核心实测）

- 用户已确认 140 开场流星／对战按键中断音效问题修复，**未明确确认已 Git 提交 140**，因此 141 的增量基线是已应用 `audio-5.62.140-014` 的源码，不视作新的已提交 HEAD。累计全量仍以用户提供的干净 `DEX-5.62.131` ZIP／导出 HEAD `ac1612ce` 为起点；两份补丁二选一。
- `WaitForSoundToFinish` 的 `Danger` 提前返回会跳过战斗音效衔接。141 只处理 `MoveAnimation` 的两处等待及 `PlayApplyingAttackSound` 的一次等待，不更改全局音频引擎和其他等待。低 HP 路径有 180 帧上限，正常 HP 行为保持，Respect `wSFXDontWait`，不停止正在播放的声道。浮动 ROMX 例程降低紧 Bank `$1E` 的占用。
- **用户确认 141 已实测**：低血量条件下，旧版与新版对照；伏特攻击、电光、撞击和其他普通招式，玩家／敌方双方使用，旧版存在的音效尾音残留在 141 受测场景消失。140 开场按键跳过音效修复先前亦获用户反馈“没问题”。十万伏特、免疫／未命中／多段技能、静音、上限等未获专项实测，不扩大结论。
- **提交及交付**：用户明确表示 139 已提交，但未明确 140 已独立 Git 提交；本次清理日志按 **`MENU-5.62.139 -> SFX-5.62.141`** 覆盖 140 开场音效与 141 战斗音效两项。清理 `DOC-016` 增量以已应用 `SFX-5.62.141/BATTLE-015` 的源码为基线，累计全量以用户原始干净 `DEX-5.62.131` ZIP／HEAD `ac1612ce` 为基线；仅择其一。项目版本保持 141，清理只改 TODO、专项说明、维护规则和新交接文档。AI 不编译／运行 ROM，无 MAP 空间结论，不执行 Git Commit／Push。

## 142 电梯等待清理与 143 训练师倒下音效（2026-10-14；功能交付待验）

- 本轮用户 ZIP 包含 `SFX-5.62.142` 工作区（HEAD `7a89953cdc83b083dcf1be962f428c650fdcc405` 为已记录的 141 提交；142 的 5 文件改动仍为未提交）。不可把 142 当作新的 Git Commit。本轮增量与基于上传项目 ZIP 的全量均从真实的 142 工作区文件状态起算，两份只择其一，不叠加。
- 用户给出 141／142 电梯视频并说明已测试、旧版无明确缺陷且差异不大；142 仅记为旧标志等待的源码清理，不写为已复现问题修复或全场景通过。
- 143 仅在训练师战 `SFX_FAINT_FALL` 与 `SFX_FAINT_THUD` 之间替换旧声道 ID 忙等，浮动 ROMX 根据实际 CH5 活动状态和 SFX 身份有界等待，不改野外／己方倒下流程及全局 Crysaudio。用户未反馈 143 ROM 实测，不得将其记为已修复；没有 MAP，也不由 AI 编译。开发待验阶段不提前写提交日志；正式提交跨度仍应从已确认的 141 Git HEAD 起覆盖 142 + 143。

## SFX-5.62.143 / AUDIO-DOC-019 验收清理与拟提交收口（2026-10-14）

- 用户上传了《143音效.mp4》并表示已尽量测试建议场景，但音效变化很难靠听觉分辨；录像可观察常规敌方／己方倒下、红血击倒敌方、训练师战胜以及双方反伤倒下。受测基础流程未见明显异常，**不推断旧版一定听得出问题、不宣称全声道／全部条件验收**。此前 142 电梯对照仅支持“未见显著影响、作为旧代码清理”；两项源码改动均保留。
- 反伤双方倒下时己方可能跳过叫声／倒下文字，是原战斗特殊分支；用户明确不改，本轮没有触碰对应逻辑。只对 143 已有实现做**纯文档收口**，`data/game_version.asm` 保持 `SFX-5.62.143`，不更改任何 ASM、Crysaudio、存档、地图或招式素材。
- 最近已记录 Git HEAD：`7a89953cdc83b083dcf1be962f428c650fdcc405`（`SFX-5.62.141`），用户本轮要求“先提交／清理三件套”表示**准备提交**，并不等于本地 Git 已执行 Commit；正式日志覆盖 **141 → 143**（142 电梯 + 143 倒下声 + 文档），不能从未提交的 142 起算。
- 本次增量为已应用 AUDIO-018 的 143 → 清理后 143 **纯文档补丁**；累计全量从用户当前上传的含 142 未提交工作区的项目 ZIP → 清理后 143，包含 143 代码与本次文档。两份严格择一，不叠加；合集 ZIP 同时包含两补丁与 `commit-message.txt`，日志另行提供。上传项目 ZIP 的工作区文件状态与实际 HEAD 不同。
- 未逐项验证 Music Off／BGM Volume 0、游轮／渡船、Link Battle、特殊连续倒下、180 帧边界及其他 ROM 变体；项目没有 MAP，没有实际链接空间证明。AI 不编译 ROM，不自行 Git Commit／Push。下一轮新功能从**用户实际确认已提交的 143** 开始；若未提交，仍以 141 HEAD + 当前工作区为准。


## SFX-5.62.144 / FLY-020 开发基线（2026-10-14；待用户实测）

- 最新上传项目 ZIP 的导出记录明确是干净 HEAD `79f1f6b4730b4ebbb2ac1a2d2bb520e77861511f`（`SFX-5.62.143`，143 已被本地 Git 提交）；与上方从 141 准备 143 提交的历史记录不同。本轮新开发以**用户这份真实 143 ZIP**为增量和全量补丁的共同起点，修改后为 144，不能重复包含早期 142／143 差异或捏造另一个 Git 状态。
- 144 只在飞行动画两个入口使用共用的定向 SFX 播放包装器，保留静音噪声路由以尝试消除两个末尾 click。源码和录音对照支持这一假设，尚待用户以 ROM／模拟器录像验证；不能把静态核对和波形检查当成 144 已修复的证明。无 MAP、未由 AI 编译 ROM。
- 本轮是**功能待验**，按项目要求仅交付增量 `.patch`、基于上传 ZIP 的全量 `.patch` 和合集 `.zip`；它们都基于同一干净 143 ZIP，二选一应用，不能叠加。只有用户明确要求验收清理／提交日志时，才进行正式收口并提供日志；不执行 Git Commit／Push。


## SFX-5.62.145 / FLY-021（2026-10-14；144 click 未解决，145 待验）

- 用户《144Click.mp4》证明 144 Fly 末尾 click 尚在，Music On／Off 均可出现。144 的 NR51 保持不是已验收的修复。用户另提出 Volt Tackle 敌方施放缺少玩家施放时的高频横震；已查证 `H_WHOSETURN` 显式限制，先记 TODO，145 不混入动画代码变更。
- **增量基线**：先前交付并在用户 144 视频中使用的 FLY-020 / `SFX-5.62.144` 修改状态。**累计全量基线**：本对话提供的 143 干净项目 ZIP（导出 HEAD `79f1f6b4…`）；两份补丁严格二选一，不叠加。用户没有说明 144 已 Git Commit，不能擅自更新 Git HEAD。新包独立编号 FLY-021。
- 145 在现有 Crysaudio CH8 `endchannel` 上增加仅 `SFX_FLY` 的原版 Audio2 尾声兼容；用户测试之前不能宣称已修好。增量、全量、合集按项目要求交付，不生成提交日志，不编译 ROM，不执行 Git Commit/Push，继续检查符号与补丁回放、路径／权限。


## ANIM-5.62.146 / VOLT-022 开发记录（历史试验阶段；以末尾验收收口为准）

- 本次用户重新提供完整工程 ZIP，实际游戏版本 `SFX-5.62.145`，导出记录 Git HEAD `79f1f6b4730b4ebbb2ac1a2d2bb520e77861511f`（已提交的 143），`current_worktree.patch` 记载了 144/145 尚未提交的工作区修改。**增量与本次 ZIP 全量均从准确的 145 工作区出发**；不是从干净 143 文件直接打新的功能补丁。增量和全量择一应用，不叠加，不擅自改变 Git 提交基线。
- 144 (`FLY-020`) 和 145 (`FLY-021`) 只是针对特定模拟器症状的游戏侧实验，已按用户要求撤销其全部运行时代码；研究过程／潜在模拟器差异详见 `docs/FLY_CLICK_PLATFORM_DIAGNOSIS.md`。保留上方历史条目是为了可追踪性，**它们不是当前生效修复**。
- Fly 的游戏侧测试只按用户在 My OldBoy 与另一模拟器上的 143 对照标记 PASS；GBPocket 仍存在 click，归入独立模拟器问题。不得把模拟器根因当作已确定的游戏缺陷，也不把音效尾声研究记录当作无价值内容删除。
- 新功能只包括 `engine/battle/volt_tackle_animation.asm` 解除敌方命中横震的两处限制。游戏显示 `ANIM-5.62.146`；这是可撤回的观感试验、并非已验收决定。代码不改通用 VBlank、不增加 HOME/WRAM、不编译 ROM。参见本轮定稿的 `docs/VOLT_TACKLE_146_ACCEPTANCE.md`。
- 本次功能待验仅交付增量 patch、基于本次 145 ZIP 的全量 patch、两份补丁合集 ZIP；**不预写正式提交日志**，也不执行 Git Commit／Push。无 MAP 可证明具体 ROM 空间；仅提供静态、补丁回放与最小实测建议。


## ANIM-5.62.146 / VOLT-DOC-023 正式验收收口（2026-10-14；待用户本地执行 Git Commit）

- 用户对比 145、146 两段敌方 Volt Tackle 视频后明确表示 146 观感满意，批准本版提交。**定稿效果保持 146 已交付的两处方向判断删除**，不再改动画 ASM、游戏内版本或飞行与音频源代码。更新 `TODO.md`、验收专项文档及此规则文件，并记录后续可能尝试的目标局部震动只能另起版本。
- 145 ZIP 是真实上传的工作区文件状态；内含 144/145 尚未提交的 Fly 修改，导出记录确认最新实际 Git HEAD 仍为 `79f1f6b4730b4ebbb2ac1a2d2bb520e77861511f` / `SFX-5.62.143`。本次**清理增量**从已应用 `VOLT-022` 的 146 试验状态出发（文档收口），**基于 ZIP 的正式全量**从用户上传的 145 工作区出发（Fly 两次撤回 + Volt 146 改动 + 文档收口）。两份只能选一份，不叠加。
- 正式拟提交日志（另有 `.txt` 并装入合集 ZIP）以 143 已提交 HEAD → 146 定稿状态为跨度，**只概括最后保留的行为及边界**：撤销 Fly 144/145 游戏侧试验、保留平台诊断，敌方 Volt Tackle 恢复与玩家同节奏横震，补齐项目规范/验收记录。不把已撤销的试验当作生效功能，不把用户批准提交等同于 Git 已真实 Commit。
- 项目不包含 MAP，本环境不编译／链接 ROM，不执行 Git Commit／Push；补丁正反回放、文件内容/权限及静态符号检查完成才可交付。若用户完成本地 Git 提交，下轮须由用户确认新 HEAD 后再更新 Git 基线。


## MOVE-5.62.161 / ROCK-DOC-009 验收清理与拟提交记录（2026-10-15）

- **最新可精确验证的已提交源码**：用户上传的 `MOVE-5.62.156` 干净 ZIP／导出 HEAD `710dbf8ceb7691922e2b6e72e0bd9f1e1f61e116`，分支 `常规功能备份`。用户已确认 159 的 Party／PC 三处详情和 161 的回忆／遗忘列表及完整流程、战斗／经验道具升级直接学习和四招替换均正常；但对话中未提供 159／160／161 的独立 Git Commit 哈希。本次拟提交日志据此保守覆盖 **156 → 161** 的最终代码与清理文档；不得把实测通过写成已经 Git Commit/Push。
- **清理结论**：157 显示实验已排除，158 失败分流也不在最终 161；仅把两处 ASM 文件内共三处 159/160 历史版本注释统一为最终 161；未修改任何汇编指令、游戏内版本、MoveDex、PP 道具、存档或战斗核心。更新 `TODO.md`、本交付规则、`RPP_DEVELOPMENT_PITFALLS.md`，新增 `docs/ROCK_POLISH_161_ACCEPTANCE.md` 记录确证场景、调用协议、重复格式化循环与后续风险。重复代码不在已验收版本上冒险压缩。
- **清理增量 `ROCK-DOC-009`**：以前次已交付并应用的 `MOVE-5.62.161/S3-007`（或等价 `S3-008`）源码状态为输入，仅包含上述四个项目文档文件及两处 ASM 文件的三行历史版本注释。**累计全量 `ROCK-FULL-010`**：从用户上传的干净 `MOVE-5.62.156` ZIP 源码状态，累计包含 159／160／161 最终有效 ASM 与本次验收文档。两者只能二选一，不叠加。合集同时包含两份补丁和可直接复制的 `commit-message.txt`，提交日志只总结最终保留的实现，不把被撤销的 157/158 失败方案写成成功功能。
- 不在本环境编译或链接 ROM；原 ZIP 无 MAP，无法核实 ROM Bank 空间与运行时 SRAM 现场。清理只有文档及 ASM 注释差异，不需要声称新 ROM 实测；两条补丁正反回放、完整文件字节、路径与 `100644/100755` 权限需校验后交付。用户自行 Git Commit/Push；未来如确认独立提交过 159／160，以用户真实 HEAD 重新界定下次基线。


## TEXT-5.62.165 / ITEM-MENU-TEXT 验收清理与拟提交状态（2026-10-16）

- 用户新上传的项目 ZIP 实际 Worktree 为 `MENU-5.62.164`，导出 HEAD `c9d97b93df35f997ded375113ec83b2d6a621162` 是已提交的 `MOVE-5.62.162`；ZIP 自带 `RPP_PROJECT_CONTEXT/patches/current_worktree.patch` 记录 163/164 未提交差异，不得把 ZIP 的 164 文件状态称为 Git HEAD。
- 本次 165 功能补丁基于该 164 Worktree 应用；用户已验收 163 的战斗 PP 回合相关场景、164 升级能力值框残留及场外返回，并在 165 明确试过 Fast／Normal／Slow 三档文字速度和消息先于能力面板显示。未报告的其他道具边界按未专项验收记录。
- 此次正式提交日志累计 **`MOVE-5.62.162 -> TEXT-5.62.165`**，包含 163 战斗 PP 成功退出、164 队伍重绘、165 道具结果文字逐字延迟／背景传输，以及正式验收文档。本次清理只改三个涉及入口的版本注释／维护文档，不改变 ASM 指令或游戏可见版本；重复映射例程仍留待后续优化。
- **清理增量**从已交付的 `TEXT-5.62.165` 源码状态到本次正式清理结果；**基于本轮指定 ZIP 的全量**从用户上传的实际 164 Worktree 到清理后 165，严格二选一，不叠加。另附可下载的提交日志并放进合集，聊天正文也需完整提供。原始 ZIP 没有 MAP，不编译／链接 ROM，也不擅自执行 Git Commit/Push。


## MOVE-5.62.169 — 双招扩容阶段提交收口（2026-10-16，待用户 Git Commit）

- 本轮用户上传的 ZIP 是 **168 Worktree** 而非干净 165：导出 HEAD `8b41b7a139a88eff550a6826b3d922baf90771e2` 是最新已提交的 `TEXT-5.62.165`，`current_worktree.patch` 包含尚未提交的 166～168。169 P3-A～P3-F 同属本次待提交跨度。
- 用户已应用 169 P3-G，但明确要求不验收培育屋扩展身份、直接撤销；本次正式目标退回 P3-F 的所有执行指令，只更新当前有效的 169 源码备注和项目记录，**不把 P3-G 写成已验收功能**。
- 正式清理增量前置：已应用 P3-G 的文件状态 → `MOVE-5.62.169` 最终；全量前置：本轮上传的 **实际 168 Worktree** → 同一目标。两份只择一，合集还包含完整 `commit-message.txt`。
- 提交日志按**已确认 Git HEAD 165 → 当前 169** 累计总结 166～169 最终保留实现，不含已回退培育屋功能的贡献。用户确认 Git 提交前，169 仍不能称已提交；不推断 Push。未编译 ROM、无 MAP、只记用户实际反馈的有限验收。
- 下一独立阶段优先验证从 2 招扩到 10／20 招的通用能力，暂缓 Day Care、交换、变身／复制和扩展 MoveDex 等外围加固。详情以持续维护的 `docs/MOVE_EXPANSION.md` 为准。

## 专项文档精简原则（169 二次收口，持续适用）

- **不按版本号或 P3-A/P3-B 等每轮生成新 Docs**：同一持续开发的系统只维护一份当前有效的专项文档；已解决的阶段性待验记录由 Git Commit 和历史补丁追溯。遇到真正独立的新子系统或必须单独保留的完整研究数据时，才评估新建文档。
- `TODO.md` 只把当前待办、明确实测、当前风险放在最前面，避免旧版“未实现／待验”覆盖新事实；`RPP_DEVELOPMENT_PITFALLS.md` 留长期可复用 ABI、栈平衡与存储陷阱。正式清理可删除冗余阶段文档，但须把仍有效的技术边界与用户验收依据迁入唯一专项文档，不修改已验收执行指令。


## MOVE-5.62.171 — 十招扩容与回忆候选收口（2026-10-16）

- 最新用户项目 ZIP 为干净 `MOVE-5.62.169`，导出 HEAD `437b285e68046e9f3d8cca206385f9789ac3121c`；170 与 171 均在其后，用户未报告这两版已经 Git 提交。正式提交日志覆盖 **169 → 171**，不是只记录 171 文档收口。
- 170 将扩展表从 2 招增至 10 招（后八招为占位），用户视频验证 03～10 的升级学习提示及遗忘列表识别；170 初次链接报告 11 个局部标签问题，FIX-025 修正标签归属和恢复 PP 标志位循环。171 将普通、地区、扩展回忆候选统一为至多 32 行并同步逐行 ordinal；用户确认“可以回忆了”，截图显示 Ext Move 07/08 与 Cancel。**不推断 10 招全部战斗、PC、存档、32 行极限等已验收。**
- 本次正式清理增量从已应用 `move_171_relearner_INCREMENTAL_027_from_170_FIX025.patch` 的 171 工作区出发；全量从上述用户提交的干净 169 ZIP 出发，包含 170、FIX-025、171 与本轮清理。两种补丁二选一，合集含两补丁及 `commit-message.txt`。仅整理当前专项文档、待办、基线／陷阱及本次修改代码段的版本注释，不改变已实测的汇编执行指令或游戏版本 `MOVE-5.62.171`。
- 不开展扩容外围加固，不让助手编译／链接 ROM；无 MAP 空间结果。Commit／Push 由用户自行完成，实际新 HEAD 等下一次项目 ZIP 再核对。


## MOVE-5.62.172 — 二十招容量节点收口（2026-10-16）

- 最近已核实 Git HEAD：`ab20fd05673a1bcd00bdb4680d91be81f9bf6aa0`（干净 `MOVE-5.62.171` 项目 ZIP）；172 在其后尚未确认用户 Git 提交。本次正式提交日志覆盖 **171 → 172**，不能把用户要求提交等同于新 HEAD 已存在。
- 172 只将扩展序号由 10 增至 20、追加 `Ext Move 11～20` 的数据／名称，并延长口呆花／大食花 30～39 级容量测试入口。用户截图确认 20/11/15/03 的详情与 PP、遗忘列表、18/19 的回忆列表可见；这是**阶段容量主路径**验收，不是全部 11～20 战斗与存档边界验收。
- 清理增量以前次已交付／用户已应用的 `move_172_P4_INCREMENTAL_031_from_committed_171.patch` 工作区为前置；全量从本轮上传干净 171 / HEAD `ab20fd05` ZIP 文件状态到最终 172。两者二选一，合集含 `commit-message.txt`；交接说明作为项目外独立 Markdown，不在 `docs/` 再添一份。清理不改 ASM 执行指令，也不新编译／链接 ROM。


## MOVE-5.62.173 — 四十招容量阶段验收与测试学习入口清理（2026-10-17）

- 新上传 172 ZIP 的导出信息为 `MOVE-5.62.172` / HEAD `6b2e65496d8a28fe3678314b9aebace4ed269dd1`，**实际 Worktree 包含 035 静态容量保护与未撤销的 19 条负向测试记录**，不是干净 HEAD。最终 173 全量补丁必须以这份上传 ZIP 的实际源码状态为前置，不能擅自退回 HEAD。
- 已交付 `move_173_REPAIRED_40_FULL_046_from_uploaded_172_worktree.patch` 将上述 172 工作区修复到 173 的 40 招分散容量测试状态；本次正式清理增量以前一补丁 **046 已应用且未附加其他修改**的源码为前置，删除 20 家族在 19／20 级发放 01～40 的临时入口、对应 NPC 测试候选和测试家族表。40 项身份、数据、名字及 sidecar／存档支持仍保留，游戏可见版本继续 `MOVE-5.62.173`。
- 用户《173扩充到40技能.mp4》给出了受测主路径；用户还确认普通与扩展战斗正常、已持有扩展技能自动从回忆师列表过滤；33 条负向测试编译日志验证 RGBDS 容量断言工作。**不以用户对清理前测试 ROM 的验收代替清理后 ROM 的新构建与回归**，也不推断全部技能／PC／边界已测。
- 正式交付：`047` 清理增量（来自已应用 046 的 173 测试状态）、`048` 累计全量（来自上述上传的含负向测试 172 ZIP），二选一；合集 ZIP 含两补丁与同内容 `commit-message.txt`，日志在聊天正文也给出。提交日志覆盖已确认 Git **172 → 173** 所保留的全部最终变更，不重复临时试验的数据分配；用户自行 Commit／Push。未由 AI 编译或链接 ROM，MAP／空间结论仍待用户运行结果。


## MOVE-5.62.176 正式收口／拟提交基线（2026-10-17，项目外交接）

- 用户上传 `MOVE-5.62.176.patch` 的 RPP-BASE 为 `60b3970b5144deceb4cd3d2d16c075d70f3c8c3a`，对应已确认提交的 `MOVE-5.62.173`；该文件是相对 HEAD 的未提交工作区 Patch，不能视作新 Commit。与已交付 058 全量的七文件代码／文档增删内容完全一致，说明 053 临时 19／20 级测试分配已撤销，174～176 修复保持。
- 用户在清理后报告普通技能升级学习正常、战斗技能交换抽查未见问题；此前 176 视频包含 SELECT 混合身份换位与 Party 查看、175 视频包含 Struggle 反伤。上述属受测场景，不等于完整 40 招／12 盒／特殊复制／逐版链接验收。
- 本轮正式收口只更新验收记录和 174～176 所改代码段的最终版本注释，**不改变任何 ASM 执行指令、招式数据、学习测试入口、存档结构或游戏版本号**。正式增量 059 从已应用 057／058 的 176 工作区出发；正式全量 060 从用户已提供的干净 173 ZIP／HEAD `60b3970b` 出发，到本次全部最终修改。两份不可叠加；合集须附同一份 `commit-message.txt`，日志跨度为 `MOVE-5.62.173 -> MOVE-5.62.176`。
- 独立交接 MD／ZIP 不纳入仓库。用户完成 Git Commit 后须重新上传完整项目 ZIP，核对新的 HEAD、Worktree、MAP、Push 状态；**不能把本次拟提交状态写成已经 Commit/Push**。AI 未编译、链接 ROM，也不执行 Git Commit/Push。


## MOVE-5.62.178 / MOVE-DOC-074 正式清理与拟提交基线（2026-10-17）

- 用户新上传的完整项目 ZIP 实际包含干净 `MOVE-5.62.176`、HEAD `23858fc8b513d2d0800c193b6e58249bf5f9c45a`、分支 `常规功能备份`；177/178 后续补丁均未收到独立 Git Commit 证明。本次拟提交跨度为 **176 → 178**，包含 177 地区判重、178 共享升级学招入口以及最后文档清理，不包括 176 已提交的老修复。
- 用户在 178T2/T3F 临时测试版受测普通／阿罗拉小拉达同招式升级、遗忘和回忆、详情、战斗、Party/PC 存取读回，且报告战斗经验升级与名称完整；178T3 曾复现临时 NPC 远调用覆盖 B 导致回忆昵称乱码，073 临时修复后用户反馈正常。只按受测范围验收，不把实验逻辑保留在正式版。
- **074 清理增量**：前置必须是已应用 064+065+067+069+071+073（或等价）的准确 `178T3F` 测试工作区。它撤销所有 177T～178T3F 临时遭遇、授招、回忆来源及测试用 BC 包装，保留与受测版一致的 178 共享学习执行指令，并更新项目现有文档。
- **075 累计全量**：从上述用户上传的**干净 176 完整项目 ZIP**直接至 178 正式最终代码，累计含 177 地区身份判断、178 公共入口及正式文档；不需要先打 061～073。074 与 075 二选一，不得叠加。合集同时包含二者与完全一致的 `commit-message.txt`，独立日志和聊天正文同内容。
- 178 正式 ROM **不再**由 1 号道路两种测试小拉达、6／7 级临时学习及额外回忆候选分配 Power Whip。保留技能数据并不意味着仍有获得渠道；旧测试档遗忘后无法按临时规则回忆。提交前请先备份测试档并完成清理后最小回归。
- 禁止助手编译／链接 ROM、执行 Git Commit/Push。176 MAP 不能证明 178 的 Bank 链接空间；用户本地提交成功后的新 HEAD、Worktree、Push 状态只能由后续导出资料确认。


## MOVE-5.62.179 / TMHM-DOC-077 验收清理与单独拟提交（2026-10-17）

- 本轮准确基线为用户上传的干净 `MOVE-5.62.178` ZIP，导出 HEAD `f54c194013b1ebb3ed73c3951bb656171f22b5b1`（分支 `常规功能备份`，ZIP 不含 `.git`）。179 功能补丁是此前交付的 `075`（与 `076` 实际变更相同）；这次**清理增量 `077`** 从已应用 075/076 的 179 工作区出发，仅更新验收相关项目文档；**正式全量 `078`** 从上述干净 178 ZIP 出发，包含 179 行为、版本号和文档。两份严格二选一，不叠加。
- 本次保留的 ASM 行为仅为 TM/HM 和 Move Tutor 共享的 `CheckIfMoveIsKnown` 逐槽读取 Party sidecar，仅普通身份匹配才判定已学；其它流程、177/178 的代码及存档格式不动。用户《179教学.mp4》验证 TM03 剑舞在扩展 ordinal 14 碰撞情况下正常学习、重复 TM03 拦截、教学师普通火焰拳与扩展 ordinal 7 共字节时可学习；小拳石后续截图显示扩展 07 与普通火焰拳共存，用户反馈复测正常。
- 179T 临时教学测试脚本用户已撤销，本次正式补丁不允许包含地图 NPC／告示牌改招或赠送学习机的临时入口。用户测试存档的经验值调整与 179 的源码收口无关。没有据此推定 HM、红蓝链接、新 MAP、满槽取消、所有兼容性／扣费组合通过。
- 179 与后续 Transform、Mimic、Metronome 等派生／复制招式各走**独立版本、独立补丁、独立 Git 提交**，不得为“顺手加固”混到同一 Commit。合集附 `commit-message.txt`，日志跨度为已提交 `178 → 179`；由用户自行 Git Commit/Push，助手不编译、链接 ROM 或假装已有新的 HEAD。


## MOVE-5.62.180 / MOVE-DOC-083 Transform 正式收口与拟提交（2026-10-17）

- 最新实际上传的 179 ZIP 导出 HEAD `972abc2b878f4c680d490c5e3646c8eb1e9f638d`，但仍含旧 179T。用户明确反馈 **079 清理已合入上一个 Git 提交**，且已经撤销 180T/082；由于尚无该提交的新导出 HEAD，不可将旧 ZIP 的 HEAD 冒充当前 HEAD。
- 180 正式功能修复玩家成功 Transform 后复制对手普通技能时旧战斗扩展身份残留；不改 Party 持久掩码；变身状态下升级学招不反灌原 Party mask。游戏版本 `MOVE-5.62.180`。用户《180变身.mp4》受测变身后四个普通技能正确显示、复制招可实际使用；视频未展示战后／换人恢复、失败变身、战斗升级学招，红蓝链接和新 MAP 也未提供。
- 本次收口的 **文档增量 MOVE-DOC-083** 从已应用 080 的 180 工作区出发；**累计全量 MOVE-FULL-084** 仅从本轮上传的旧 179 ZIP 出发，故包含 079+080+180 验收文档；**当前含 079 的基线全量 MOVE-CLEAN-085** 从该旧 ZIP 经 079 反向撤销临时脚本后的精确文件状态出发，只含 080+180 文档。三份都不能叠加。用户已应用 080 时只使用 083，勿再应用 079/084/085。
- 082/180T 只用于本地临时授招，用户已撤销，正式 180 绝不纳入地图脚本；079 清理已在上一提交，也不应写进本次 180 独立 Git Commit 日志。日志只涵盖 180 的两个 ASM 修改、版本号及项目验收文档。当前不假装助手编译或提交，真实 Commit/Push 和红蓝 MAP 待用户确认。

## MOVE-5.62.187 / MOVE-DOC-188 同类派生招式身份验收清理（2026-10-18；准备用户 Git 提交）

- 用户把 185 Mimic、186 Mirror Move、187 Metronome 作为同一批次提交；用户《185MIMIC.mp4》《交换Mimic.mp4》《186Mirror.mp4》《MIMIC1.mp4》《187摇手指.mp4》支持双向 EXT07 执行以及 Mimic 后 SELECT 的**录像受测场景**。187T 固定抽 EXT07，不验证正式真随机分布及其余 39 招。用户已确认撤销 186T；本次用户工作区补丁不含 185T／186T／187T 临时逻辑，不能由此推定测试 SAV 已恢复。
- 用户上传 `MOVE-5.62.187.patch`（RPP-BASE `ebbac188...`）能够从先前原始 ZIP 的**实际 184G3 文件状态**回放，回放内容与此前正式 187 工作副本涉及的 10 个文件逐字节一致；没有 `scripts/186T_test_helper.asm`、`scripts/187T_test_helper.asm`、玉虹大厦临时 NPC 或 7 号道路临时野生分布。
- **清理增量 MOVE-DOC-188**：从上传的**已经应用 185～187 功能的 187 Worktree**出发，只更新受测状态、唯一扩展招式专项说明、可复用测试 SECTION 陷阱、规则／基线记录及本组三个功能新增注释版本；不更改功能指令、游戏版本 `MOVE-5.62.187` 或永久数据。
- **累计全量 MOVE-FULL-189**：从本轮原始 `fix(move)__183_...zip` 的**实际 `MOVE-5.62.184G3` 文件状态**出发，累计加入用户 187 补丁的 185～187 功能与本次收口；清理增量和累计全量二选一，严禁叠加。ZIP 同时放入两份补丁及 `commit-message.txt`，聊天内同样给出完整提交日志。原 ZIP 头记录 Git HEAD `ebbac188`（183），但实际源码已是 184G3；尚无 184G3 独立已提交 HEAD 证明，用户本地 Commit 前必须自行核对 Git diff 的真实跨度，本工具不虚构 HEAD／Commit。
- **检验边界**：代码主路径以用户游戏录像为证；本轮只执行静态审查与补丁正反校验，不编译／链接 ROM，旧 MAP 不是 187 的空间证据。联机、随机分布、嵌套派生、全部扩展招以及红蓝分别构建仍未验。AI 不自行 Commit/Push。


## MOVE-5.62.188～189 / DOC-190 验收清理及当前基线（2026-10-18）

- 本次准确基线是用户此前提供的干净 `MOVE-5.62.187` 项目 ZIP，导出 HEAD `ea163ba9a4ec8b96d20e761c833aef3f5c9e6713`；当前上传的 `MOVE-5.62.189(1).patch` 是从该已提交 HEAD 到 189 测试工作区的差异，**不是已提交 189**。189 工作区含 `189T` 野生／训练家测试分配及 Route 8 复战脚本，收口增量负责删除它们。
- 本次 DOC-190 **清理增量**准确前置为上述用户 189(1) 工作区（未应用独立 Fire Punch 修复及 189D 诊断）；**累计全量**从干净 187 项目 ZIP 到清理后 189 正式源码，包含 188 和 189 两阶段正式内容与文档清理。二选一，不得叠加。合集 ZIP 必须同时包含 `commit-message.txt`，正文日志跨度为 `187 → 189`。
- 188T 用户录像的 EXT07／普通 Fire Punch Seen 对照通过；189T 野生及训练家原生 EXT07 已在受测路径显示／执行，用户额外确认训练家 EXT07 动画和伤害。189T 中普通 Fire Punch 导致 PAR 暴露共用 `RollStatusSideEffect` 远调用错误；本轮**不**夹带外部火焰拳修复、189D 诊断、AI、会心、Fly 或 Psywave 改动，相关缺陷留待独立补丁／回归。
- 正式 189 的来源配置表故意为空，表示完成敌方来源协议而**不是正式招式分配**。本轮清理不改 188／189 正式战斗指令、存档、四槽 sidecar、游戏版本或已提交 185～187 功能；用户须本地进行清理后的新 ROM 编译／链接和最小回归。Git Commit／Push 仍由用户自行执行，未提交前不更新 HEAD 假定。

## 189 提交状态补记（2026-10-18；仅核正旧记录）

- 用户最新项目 ZIP 的导出信息显示 189 已本地 Git Commit：`9cfd1f689ef9c886d2d65f3be46986e70551d3a5`；工作区干净，尚未 Push。上方 188～189 DOC-190 节所述“准备提交”“尚未提交”保留为**当时的清理前历史背景**，不可再作为当前 HEAD 结论。
- 本次仅更新提交状态文本，不改 ROM 指令、测试环境、游戏可见版本或已验收范围。未来功能补丁以用户本次实际 189 文件状态为前置；若本地 amend 使 HEAD 改变，以用户随后提供的新真实 HEAD 为准。


## MOVE-5.62.190 / DOC-191 正式验收收口记录（2026-10-18）

- 用户最新原始项目 ZIP 为 `fix(move)__收口敌方扩展招式身份记录与原生来源(1).zip`；`RPP_PROJECT_CONTEXT/02_EXPORT_INFO.txt` 明确分支 `常规功能备份`，最近已提交 HEAD `60e8832b8b08283bf135518ef79af7f847098f30`（189），ZIP **实际源码是带 190 正式修复的未提交 Worktree**。附带 `current_worktree.patch` 可反向重建 189 HEAD 所涉及的四个文件，不得把 ZIP 的 190 版本字样当作 190 Git Commit。
- 本次用户提交的《190三拳.mp4》在 190T 强制追加效果条件下验证普通 Fire Punch→BRN、Ice Punch→FRZ、ThunderPunch→PAR 三项通过；用户反馈已撤销 190T。当前 ZIP 仅包含四个正式工作区改动文件，不见临时测试差异。录像没有证明正式随机概率统计、所有异常状态边界、双 ROM 构建／链接；SAV 与测试后 ROM 恢复也未经独立确认。
- **清理增量**以本轮用户 ZIP 的实际 **190 Worktree（190 正式补丁已应用、190T 已撤销）** 为前置，只含本次项目文档收口；**基线全量**以实际提交 HEAD `60e8832b` 的 189 四文件重建状态为起点，包含 190 的两处 ASM 修复、版本更新及所有收口文档。二者是替代方案，不能叠加。
- 本轮没有修改工具／审计脚本，使用单笔 `fix(move)` 提交准备（两份补丁＋一份 `commit-message.txt`）；不改游戏运行指令、测试配置、存档或游戏可见版本 `MOVE-5.62.190` 的当前工作区行为。190 仍**待用户自行 Git Commit/Push**，后续只有经用户提供新提交状态核实后才能更新 HEAD 基线。191 EXT02 高会心身份碰撞另起独立版本。


## 191 同类身份碰撞合并批次（待验，2026-10-19）

- 用户确认 190 已本地提交；本环境尚未收到提交后的新 HEAD/ZIP，不能编造 SHA。本轮把 F02（会心）和 F05（Fly/Dig 表）作为一组**扩展身份撞号**合并至游戏版本 `MOVE-5.62.191`，AI 错表另期。正式增量只针对上次 190 最终收口后的文件状态；另附从用户先前 190 ZIP 工作区出发的累计全量供对照，两者严格二选一，不叠加。
- 同批提供**191T 独立、可正反撤销**测试补丁；野生配置和确定性会心只在 191T，正式修复不加来源配置，也不动任何测试 SAV。提交日志只在用户实测并要求收口后生成；不编译 ROM／不替用户 Git Commit。


## MOVE-5.62.191 / MOVE-DOC-192 身份撞号合并批次验收收口（2026-10-19；准备用户自行 Git 提交）

- 190 已由用户报告自行 Git 提交，但本窗口没有新的 190 HEAD SHA/项目导出；先前用户提供的 190 ZIP 仍是 189 已提交 HEAD 加 190 Worktree 的历史文件，**不可当作当前 Git 提交状态**。本轮 191 **增量清理**基于已交付 `MOVE-5.62.191-001` 的正式工作副本（未含 191T），只增加验收文档与 192 阶段方案；**191 全量**以已收口 190 文件状态为准确前置，包含 191 正式修复及同一轮文档收口，二者择一应用，不能叠加。若本地文件与此 190 基线不一致，停止应用并重新核对。
- 用户反馈 191T 四组测试全部通过：小拉达 EXT02 无强制会心、喵喵普通 Karate Chop 强制会心、波波 EXT16 不命中 Fly 空中目标、六尾普通 Gust 可命中 Fly 空中目标。该强制概率属于临时测试逻辑，不等于正式随机会心概率。用户已明确撤销 191T；正式交付不得包含测试野生表、来源表、调试阈值或 SAV。
- 本次收口不改变 191 ASM 指令、游戏版本 `MOVE-5.62.191`、PP、Party/PC/SRAM 或训练师 AI 行为。双 ROM 链接、正式概率统计、Gust 对 Fly 的倍伤数值、Dig 对照和全部派生组合均未逐项确认。AI 不编译 ROM，也不执行 Commit/Push。提交日志写 **190（用户已提交）→191**，不重复描述 190 修复；由于新 SHA 未提供，日志不虚构 Commit 哈希。
- **下一批 192**：训练师 AI 的 EXT 候选读表和评分独立进行。190/191 既有战斗实际执行数据和测试用配置不改；根据可撤销 192T 验证方案专项测试，详见 `docs/MOVE_192_AI_CANDIDATE_PLAN.md`。191 若尚未提交，192 不能擅自假定出现了新 Git HEAD。


## MOVE-5.62.193 / MOVE-DOC-193 验收清理与拟提交基线（2026-10-19）

- 已核实原始项目 ZIP 为**干净 `MOVE-5.62.192`**：分支 `常规功能备份`，导出 HEAD `5fccba737114c5074433737b05b94d4933168aa1`，无 Worktree Patch；ZIP 不含 `.git`，不能声称本环境执行了真实 Git 状态检查。193 正式源码可由这份 192 基线依次应用「升级学习接口正式功能增量」与「Section 重复／跨 Bank 修复增量」精确重建。
- 用户实测确认 EXT01 能升级学会、遗忘、回忆、正常释放；普通 Pound 和其他正常招式也能学习和释放。这是本轮规定的最小受测范围，不额外要求整个升级系统重测。`193T` 临时 6 级 Power Whip、7 级 Pound 来源和版本后缀，用户明确已撤销；清理目标经静态对照不含这些来源。
- 本次清理仅更新 `TODO.md`、`docs/MOVE_EXPANSION.md`、本规则、`RPP_DEVELOPMENT_PITFALLS.md` 和新增功能文件的一行备注，**不改 ASM 执行指令、宏编码、正式数据或版本文本**。`SECTION FRAGMENT` 的定稿编译修复保留。
- 本轮相对已提交 192 HEAD 没有任何工具／审计脚本改动，按项目最新要求使用**模式 B：单笔 `feat(move)` 提交准备**。清理增量精确前置为「已应用 193 功能 + Section／Bank 修复、未应用 193T」状态；基线全量精确前置为上述 192 ZIP 干净 HEAD。两者二选一，不能叠加。统一 ZIP 仅放两份补丁和一份 `commit-message.txt`。
- 补丁正反回放与文件字节／权限验证属于静态核查；用户未另附撤销 193T 后的 ROM 双模式构建日志／新 MAP，本环境不自行编译、链接或执行 Git Commit／Push。最终新 HEAD 由用户提交后下次导出核实，不能提前填造。

## ANIM-5.62.196 嬉闹慢速动画独立提交准备（2026-10-20）

- 原始项目 ZIP 为干净 195 / HEAD `550e6cd5ce1a22c596e28fa2a6d49c5f782327f9`。196 仅包含 196A 慢速主体、正式无字母版本号和对应 TODO／专项文档，不包含 196B 的双效果。
- 196 清理增量以已应用 196B 的开发工作区为输入，剥离双效果并收口慢速；196 全量从干净 195 直接到正式 196。二者择一使用；合集附独立 196 提交日志。
- 用户提供 195A／196A 视频并在后续 196B 中继续实机测试；未验证双 ROM／新版 MAP。提交和 Push 由用户自行执行，不能凭清理文件认定已有 196 HEAD。

## ANIM-5.62.197 嬉闹双独立追加效果单独提交准备（2026-10-20）

- 196A 与 196B 为两项开发候选，正式拆为连续两笔：`ANIM-5.62.196` 慢速动画，再 `ANIM-5.62.197` 双 10% 效果。197 提交不重复 196 的动画改动。
- 197 清理增量从正式 196 文件状态出发；累计全量仍从用户上传的干净 195 / HEAD `550e6cd5` 出发，供一次性恢复最终状态，**不能用于第二笔独立提交**。二者择一使用；合集含 197 单独日志。
- 用户已实测两个追加效果能分别触发，也能同时触发；未完成正式概率统计、双 ROM／新 MAP 及全部边界验证。尚未核实用户已 Git Commit／Push，不虚构后续 HEAD。

## MOVE-5.62.199 — Dynamic Spark 不含 Counter 的独立提交收口（2026-10-21）

- 用户已说明 198 本地提交，本轮提交内容只覆盖 198→199 的 Dynamic Spark；导出源码可由此前用户上传的 197 ZIP + 198 正式清理全量补丁精确重建，不编造未知的 198 Git SHA。
- 199 正式版采用 199C 已实测满意的 MoveDex 原字模与稳定选招 UI，加上烧伤重算攻击 999 上限；MoveDex 固定 Dynamic，Fight 菜单当前预览 Physical/Special，实际执行时按最新阶段能力重新判定，相等特殊。Spark 数值、动画、追加效果不改。
- 清理剥离 199D/199E Counter 双侧缓存、ROM0 桥接、WRAM 保留字节改动及 T1/T2 测试数值。Counter 自身的旧行为与 Spark 联动留待后版研究，不宣称本次完成 Counter 兼容验收。
- 本次清理增量准确前置为已交付的标准 199E（未加 T1/T2）；累计全量准确前置为可重建的完整正式 198 源码。两者二选一，附一份提交日志；若用户仍在 199C／199D，不能误用 199E 增量。
- 用户反馈仅证实常规类别变化、标签、光标主路径；执行前同回合能力变化、烧伤 999 极值、Counter、派生招式、双 ROM 链接与新 MAP 没有经过独立验收。本环境不编译 ROM，不执行 Git Commit 或 Push。


## BATTLE-5.62.200T-004 / Spark Dynamic 平局归物理（2026-10-21）

- 上文 `MOVE-5.62.199` 的“相等特殊”是当时的历史规则；用户在 200T-003 之后明确更正为 **Attack >= Special 选 Physical，Attack < Special 选 Special**。Spark 原本是物理招式，平局恢复 Physical。
- MoveDex 仍固定标记 Dynamic；战斗菜单与实际伤害结算使用同一规则。200T-004 仅更新比较分支、TEST 09 显示对照和相应文档；不重配其他 16 项已测场景、不调整 Counter 或状态计算。
- 增量以准确 `BATTLE-5.62.200T-003` 工作区为基线；如尚停留在 002，使用单独的 002→004 增量；累计全量以用户上传的干净 `MOVE-5.62.199` 为基线。各路径只能选一份。未经用户 ROM 验收，不宣称完成实机测试。


## BATTLE-5.62.200 / 验收清理三件套提交准备（2026-10-21）

- **基线真实性**：用户最新 `BATTLE-5.62.200.zip` 是 13 个修改文件 + Worktree Patch，不是完整工程；已核对其 `modified_files/` 与 `200T-004` 重建工程对应文件逐字节一致。正式累计全量以用户上传的**干净 `MOVE-5.62.199` ZIP** 为准，其导出 HEAD `66c9b058aa4558ec9d0712cd7349ee877f8996f0`（199 已提交，200 未提交）。
- **最终定案的 Dynamic 规则**：普通 Spark 静态 `DYNAMIC`，MoveDex 永久显示该标签，Fight 预览／伤害执行时各自重新比较；Attack >= Special → Physical（平局物理），Attack < Special → Special；烧伤不参与分类，但物理伤害仍受烧伤影响。其他固定招式不变。旧199“相等特殊”是历史版本规则。
- **本批正式内容**：200 的真实 HP Counter 受击记录、最后一次物理命中×2、命中判定、假会心显示清理；烧伤／麻痹相关能力重算；烧伤 Dynamic 的同 Bank 重算与 999 上限；用户 200T-004 明确指定的平局物理分支。保持 `BATTLE-5.62.200` 游戏可见版本；不自作主张改 Counter 失败文字、固定伤害规则或优先级。
- **临时场景清理**：正式源码恢复玉虹大厦 NPC、7 号道路遭遇表、临时 WRAM 别名、野生战斗 200T hook、17 项场景台词／脚本及测试专用 `docs/BATTLE_200T_TEST_LAB.md`；仅保留正式战斗功能和可 Git 跟踪的规则／TODO／踩坑／专项记录。未完成、未精确复算的测试单列，不扩大验收范围。
- **交付三件套**：准确 `200T-004 Worktree → 正式200` 清理增量、准确 `已提交199 HEAD → 正式200` 全量补丁，以及包含两份补丁和同文独立 `commit-message.txt` 的 ZIP，二者只能择一应用；提交日志覆盖 199→200，不是 200T-004→200 的末次文档差异。第二轮（暂命名 201）另起独立开发／测试／提交，不并进这一笔。
- **本次静态审查不等于 ROM 验收**：用户本地需构建／链接 Normal 与 Hard 并检查 MAP，恢复测试前 SAV、实测去除测试场景后的正常互动／野生战斗、FIGHT 菜单和 Counter。助手不执行 ROM 构建、Git Commit 或 Push；新 HEAD 仅凭用户后续导出确认。

## BATTLE-5.62.201 / 正式收口与提交准备（2026-10-21）

- **准确基线**：用户最新上传已提交 `BATTLE-5.62.200` 项目 ZIP；导出干净 HEAD `8030b0f2f162eeb9c2a39e8ca5e7205eacaf8ff9`。201 开发补丁 `DEV-001` 在其上加入正式引擎修复和 201T 三项临时测试。用户未声明 201 已 Git 提交。
- **保留规则**：能力阶段仍在 -6～+6 内运作，即使能力数值已达 999／1 也允许合法阶段变化，重算输出钳位在 1～999；Counter 没有有效物理 HP 受击时显示 `But it failed!`，真正命中判定失败仍显示 `Attack missed!`。200 的 Spark Dynamic（相等物理）、Counter -5／两倍最后一次实际物理受伤以及烧伤／麻痹修复保持不变。
- **用户反馈**：201T 的三项中，防御预置 +6 后瞪眼、变硬交替可正常升回、Counter 条件失败文字符合、Spark 平局物理并可被敌方 Counter 反击；内部 999 具体数值未在游戏画面独立读数，双模式 ROM／MAP 尚未由助手验证。
- **收口动作**：移除 201T 告示牌、测试文字、Route 7 测试遇敌、进野战临时注入、WRAM 测试别名和专用测试说明，**保留全部 201 正式战斗修复**。测试存档另行恢复。
- **三件套**：准确 `BATTLE-5.62.201_DEV-001 → 正式201` 清理增量；准确 `已提交 200 HEAD → 正式201` 累计全量；合集 ZIP 含两份补丁和同文 `commit-message.txt`，另提供独立日志。二者择一，**不能叠加**。游戏可见版本 `BATTLE-5.62.201`；提交由用户自行执行。


## BATTLE-5.62.202 / Counter Ghost 免疫与临时测试清理（2026-10-22）

- **准确基线**：已提交 `BATTLE-5.62.201`，导出 HEAD `eba1a803a7791a74bd2706982345d2894e3f93e2`；本轮工作区在该基线上叠加 202T～206T 的临时测试与正式修复。最终正式目标为 `BATTLE-5.62.202`。
- **正式保留**：Dynamic Spark 最低能力值 1、混乱自伤固定自方 Attack/Defense、公共伤害除数最低 1、Counter 对 Ghost 属性免疫；保留 201 的能力阶段限幅与 Counter 失败提示规则。
- **用户测试依据**：TEST 21 到 -6 后 Spark 为 Physical；TEST 30 选择 Spark/Tackle 的混乱自伤各扣 16 HP；205T 物理／特殊极低除数与 TEST 03／05 未报告新异常；TEST 04 视频确认 Counter 对 Gastly 显示属性无效且 HP 不变。未要求复测精确多段 HP、替身、换人和真实未命中。
- **清理范围**：恢复玉虹大厦 NPC／导师对话、Route 7 Normal/Hard 野生遭遇表；删除临时 NPC 测试入口、短标签、`Battle203TConfigureWildEnemy` hook、WRAM 别名及两份临时测试指南。正式版本号从 201 更新为 202。
- **三件套**：清理增量以 `BATTLE-5.62.206T` 工作区为前置；累计全量以已提交 `BATTLE-5.62.201` / HEAD `eba1a803a7791a74bd2706982345d2894e3f93e2` 为基线。合集包含两份补丁与同文 `commit-message.txt`；二者只能择一应用。
- **验证边界**：补丁正反向与源码／临时符号检查可完成；本环境不编译 ROM、不生成新 MAP、不执行 Git Commit／Push。用户本地仍需构建 Normal/Hard 并核对新 MAP。

## BATTLE-5.62.203 正式收口基线、源码与验收边界（最终清理记录）

- 本轮导出工作区的最近确认 Git 提交仍是 `BATTLE-5.62.202` / `3595661a0c6857a583e74738293156f12cfac25f`，分支 `常规功能备份`。后续一系列后缀 T 开发候选均不视为提交；最终游戏对外只显示 **`BATTLE-5.62.203`**，不保留中间测试版号作为正式标签。
- 最终正式差异是：混乱自伤直扣自身本体且正确重建 `HL=wDamage+1`、Jump Kick/Hi Jump Kick 自身反伤（浮动 ROMX Helper）、多段击中替身的承伤/破裂提示顺序和次数。不要变更 202 已提交的 Dynamic Spark、Counter 幽灵免疫与公共伤害低除数保护。
- 历史早期录像及本窗口 `211T.mp4`/`212T测试视频.mp4` 的详细测试过程、双方覆盖、静态执行链、局限性和未覆盖项统一归档在 **`docs/BATTLE_203_FINAL_REVIEW.md`**，而**不是**反复复制到提交日志或把临时场景指南留在正式 ROM 项目中。`211T` 15 击属于已删除的测试夹具跨 Bank 返回错误；后续录像两侧均见 3 击，不要写成正式伤害错误。
- 清理后恢复正式 Celadon Mansion 老太太/三导师/告示牌、Route 7 Normal/Hard 野生表和 `InitWildBattle` 既有 `RegionalFormClearNewMonForm`；删除测试场景脚本与文本、固定命中/击数/替身 HP 注入、WRAM 别名、测试 helper 与 `main.asm` INCLUDE，保持 WRAM 布局不变。
- 最终验收的本地剩余工作只有 Normal/Hard 双构建、新 MAP 和清理后 NPC/普通野战简短烟雾检查；不再无理由重录已测战斗。旧 210T MAP 只是历史参考，不能当最终构建成功证据。本环境不编译 ROM、不 Git Commit/Push。
- 交付按本文件顶部规范及 `RPP_PROJECT_CONTEXT/03_PROJECT_REQUIREMENTS.txt` 模式 B：**清理增量**（当前已应用的 212T 测试状态→最终203）、**基线全量**（已提交 202 HEAD→最终203）、**一份简明 commit-message.txt**，合为一个 ZIP；只选择增量或全量应用，不叠加。充分的技术原理与逐条受测记录始终写在专项文档，提交日志只摘要当前这笔实际变更。


## BATTLE-5.62.204 — 可选战斗测试构建定版交付（2026-10-23）

- 新上传的工作区 ZIP 有未提交改动；已记录的最新已提交 HEAD 为 `71d78a1a4a80949e4ec903212991a4726ed24f9c`，正式版本 `BATTLE-5.62.203`，分支 `常规功能备份`。当前工作区中的测试 ROM 标记为 `B-5.62.203-T09`，Pokey 已由用户手工定位到 **`($00,$0A)`**；这不是新 Git HEAD。
- 此次累计差异只有编译期可选的战斗测试设施（独立对象、NPC、临时输入 Hook、测试说明）及正式可见版本升级，无新增正式战斗规则。正式版从 `BATTLE-5.62.203` 升到 `BATTLE-5.62.204`，测试版为 `B-5.62.204-T09`，原老太太和导师不被覆盖；不在源代码层面回滚用户定位。
- 依项目要求的特殊情形规则，本轮是**一个可选测试工具交付**，没有需单独提交的正式运行时功能变更；因此采用单提交模式 B（两份补丁 + 一份日志），不为只有版本字符串变化的正式 ROM 制造一笔空功能提交。实际提交由用户自行执行。
- 清理增量以**此轮新上传的实际 T09 工作区**为前置，全量补丁以准确重建的已提交 203 HEAD 为前置，互斥不可叠加。`RPP_PROJECT_CONTEXT/` 及导出 MAP 均为自动生成的资料，不手工纳入补丁。
- 测试交互和长期隔离边界只以 `docs/BATTLE_TEST_BUILD.md` 为当前说明。T01～T08 旧操作教程被清理，确定的栈/Bank 等维护经验保存在 `RPP_DEVELOPMENT_PITFALLS.md`。不把之前通过的旧战斗录屏当成本次构建实际验证。
- 用户本地还需执行正式 Red/Blue 和必要的测试构建，检查链接/MAP 与 Pokey 显示/操作；AI 不编译 ROM、不 Git Commit/Push。

## TEXT-5.62.205 — 对话区域刷新优化验收清理（2026-10-23）

- **版本基线**：最新用户上传的是干净 `BATTLE-5.62.204` / HEAD `6d87cab1c761adae4ff58d4fcaa997fd4a502296`，源码 ZIP 不含 `.git`，记录来自导出元数据，未由本环境执行仓库提交状态检测。没有新的 205 已提交 HEAD 证明。
- **收口功能**：保留 `TEXT-205-001` 的下方六行文字刷新请求和 LCD 预 VBlank 调色板同步防护；原始字体、Fast/Normal/Slow 速度值、滚行/按键、存档、测试工具和战斗测试设施均不改。用户撤销了后续 Slow=2 帧候选，最终 Slow 继续=3 帧，不能将撤销的修改合入。
- **普通／测试版号独立**：普通 `make red/blue` 可见 `TEXT-5.62.205`；`make test-red/test-blue` 仍可见原 `B-5.62.204-T09`。此次正式清理只变更正式可见版本号，不为文字优化同步提升测试 ROM 专用代号。更新 `docs/BATTLE_TEST_BUILD.md` 中普通版对应的说明，不修改专用测试代码。
- **验收边界**：用户上传了 205 的 NPC 对话运行录像，正常速度观感改善，慢速依旧是原速度；对画面其他区域、战斗文字、Red/Blue 双构建以及清理后链接/MAP 未获得用户明确完整验证；不能以视频观感外推全项目稳定性。
- **交付模式 B**：本阶段没有新增或修改需独立提交的 `tools/` 工具／离线审计脚本。清理增量 = 已应用 `TEXT-205-001` → 文档及版本恢复后的最终 205；基线全量 = 204 HEAD → 最终 205；ZIP 内固定两份互斥补丁和 `commit-message.txt` 一份，提供独立日志和正文。日志只覆盖 204→205 的最终保留差异；AI 不编译/链接 ROM，不 Commit/Push。

## IMP-5.62.207 / TEST-209 验收清理与双提交准备（2026-10-24）

- **准确基线**：用户上传的 TEST-208/T14 Worktree ZIP 声明最近已提交 Git HEAD 为 `54b4eb5f00d83eca8ea518b8d8b2ea93320fbc7b`（`TEXT-5.62.205`）；ZIP 附带的 `RPP_PROJECT_CONTEXT/patches/current_worktree.patch` 已反向应用并逐文件核对，能够准确重建该 HEAD。T14/T15 是其后的未提交 Worktree，不得将 `IMP-5.62.207` 或 `TEST-209` 当成已提交版本。
- **用户验收**：用户明确反馈当前相关功能与测试场景均已测试、未发现问题。此反馈不等同于本环境执行 ROM 编译／链接／MAP 或联机测试。
- **第一笔功能提交**：`feat(battle): 为百变怪加入入场自动变身`。只包含运行时入场钩子、共享 Transform 判定／复制、动画入口、必要 ROMX 迁移与 WRAM 标志、正式版本标签及对应功能 TODO。版本 `TEXT-5.62.205 -> IMP-5.62.207`。
- **第二笔测试工具提交**：`test(battle): 增加变身者专项场景并收口测试菜单`。包含测试 ROM 专用 15 个 Imposter 场景、原 3 个 Substitute 场景的菜单分组、Pokey 入口、测试版标签 `TEST-209`、菜单 BG 状态恢复、测试夹具及其说明／审查／收口记录。版本 `B-5.62.204-T09 -> TEST-209`。该测试工具依赖第一笔功能提交，必须先提交功能，再提交测试工具。
- **模式 A 交付**：合集内固定为清理增量、测试工具反向隔离、HEAD 基线全量、功能提交日志、测试工具提交日志，共 5 个文件。增量以前置 TEST-209/T15 当前 Worktree 为基线；反向隔离将最终状态退回“只保留第一笔功能”的状态；全量从已核实 HEAD `54b4eb5f` 到最终状态。三份补丁均为替代流程的一部分，必须按聊天说明应用，不能把增量和全量叠加。
- **检查与限制**：已对准确 HEAD 重建、补丁正向应用／反向撤销、文件内容、SHA-256、路径及 Git 可执行权限进行核对；用户报告测试通过。AI 未编译／链接 ROM、未生成新 MAP、未执行 Git Commit/Push。联机双端及异常退出状态仍列为未由本环境独立验证。


## TRF-5.62.208 / TEST-210 — 手动 Transform 同回合执行复制招式（开发候选）

- **基线**：用户本轮上传的干净 HEAD `eae3e430690fcc798083887b09d44e891717cead`，分支 `常规功能备份`，源码版本 `TEST-209` / 正式功能 `IMP-5.62.207`。本轮只交付开发增量、HEAD 全量与仅含两份补丁的 ZIP；不生成提交日志，不执行 Commit/Push。
- **功能差异**：成功的直接手动 Transform 立即继续当前行动，玩家选一个复制招式，敌方与 Link 使用 Mimic 风格的随机非空槽；失败按原手动 Transform 结束行动。自动 Imposter 入口不追加招式。正式版本标签 `TRF-5.62.208`，测试标签 `TEST-210`。
- **当前状态**：已完成源码修改、维护文档与静态差异检查；本环境未编译／链接 ROM、未生成新 MAP、未进行模拟器／实机／Link 测试。用户验收后再进入正式清理。

## TRF-5.62.208 / TEST-211 — 历史场景随功能迭代复用（开发中，未验收）

- 用户明确要求旧 Pokey 场景不是永久验收资产；本轮把 15 个 Imposter 场景位置重配为 10 项手动 Transform 同回合续招专项、5 项自动入场回归，保留原 3 项 Substitute 测试。TEST 构建独立、无新 SRAM，正式游戏版本继续 `TRF-5.62.208`，测试标签改为 `TEST-211`。
- 用户当前提供的工程干净 HEAD `eae3e430690fcc798083887b09d44e891717cead` / TEST-209，经上一轮功能补丁得到 `TRF-5.62.208 / TEST-210` 开发状态；**未确认 208 已提交**。本轮增量基于准确 208/210 状态，基线全量从该 HEAD 叠加功能与场景调整，不假设新的提交。
- 仅交付开发版增量/全量/一个 ZIP，不预写正式 Commit 日志，不自行 Git Commit/Push。用户仍需本地构建及按 TEST-211 场景表做少量复测，旧版录像与旧场景通过不代表 211 自动通过。

## TEST-212 — 新交接恢复开发候选（未验收）

- 源码来自用户上传 `TEST-211.zip`（带未提交 Worktree），并依据《RPP_TRF_TEST212_开发中断交接文档》重建 15 场景。原上轮 `/mnt/data/test211_work` 的九文件草稿没有附在本次上传中，不能宣称与其字节一致。
- 本轮开发仍在 `常规功能备份` 分支的导出 HEAD `eae3e430690fcc798083887b09d44e891717cead` 上累计。正式 `TRF-5.62.208`、测试 `TEST-212`。只交付**TEST-211 当前已应用状态 → 新候选**增量及**HEAD → 新候选**累计全量两份互斥补丁，单 ZIP；禁止叠加应用。
- TEST-212 只更新测试夹具、测试条件下的敌方续招槽和文档；现有正式战斗、自动 Imposter、SRAM/WRAM 布局与 Substitute 三项不作新的代码修改。
- AI 不编译、链接、执行 ROM、生成 MAP 或运行 Git Commit/Push。十五项新测试均须用户本地验收；静态核对、补丁应用、SHA-256 对照不等于 ROM 正确运行。


## TEST-214 / TRF-5.62.208 — 复杂交互优先测试矩阵（2026-10-25，开发候选）

- **基线**：用户上传 `TEST-213.zip`，导出记录分支 `常规功能备份`、HEAD `eae3e430690fcc798083887b09d44e891717cead`；源码为 HEAD 上带未提交 Worktree 的实际文件。随包 `current_worktree.patch` 已反向应用检查并可重建该 HEAD。不得把 TEST-213 当作 Git 提交。
- **目标**：保留 TEST-213 续招菜单画面缓存修复，把 15 项菜单改为复杂交互优先：玩家／敌方后手 Fly、Dig、EXT、KO、Substitute 镜像，PP/RESTORE、双向真实换入、双方变身失败及两项先手蓄力对照。场景步骤和预期以 `docs/BATTLE_TEST_BUILD.md` 顶部 TEST-214 表为准。
- **代码隔离**：只调整测试夹具、`BATTLE_TEST_BUILD` 下的敌方固定续招槽、测试标签与维护文档；正式 `TRF-5.62.208`、正式 Transform/Imposter 算法、SRAM/WRAM 布局及原 3 项 Substitute 测试不改。测试版标签 `TEST-214`。
- **开发交付**：增量补丁 = 上传 ZIP 中的 TEST-213 Worktree → TEST-214；全量补丁 = 可重建 HEAD `eae3e430…` → TEST-214（含原有 Worktree 差异）。两份只择一应用，ZIP 仅含两份补丁。
- **验证边界**：本轮做源码静态审查、基线重建和补丁正反回放；AI 不编译／链接 ROM、不生成 MAP、不执行 Git Commit/Push。所有 15 项均待用户本地 TEST Red/Blue 构建及游戏测试，不能将静态检查写成实测通过。

## TEST-215 — 续招菜单 B 键修复候选（未验收）

- 上轮实际候选为 `TEST-214`（正式 `TRF-5.62.208`），由本轮输入的 TEST-213 Worktree + 已交付 `TEST213_to_TEST214_complex_matrix.patch` 重建并核对。新候选仅为手动 Transform 成功后的第二次选招菜单增加 type 3，忽略 B，A 按原 PP/Disable 过滤确认。没有修改旧 Disable 状态继承、Mimic、原选招模式或敌方选招 AI；05/09 零 PP 测试夹具问题仍未修。
- 测试字符串为 `TEST-215`，正式为 `TRF-5.62.209`；累计 HEAD 仍采用导出记录的 `eae3e430690fcc798083887b09d44e891717cead`，不把 214/215 当作已提交。开发阶段仅交付 TEST-214→215 增量、HEAD→215 全量的互斥补丁单 ZIP，不预写 Commit。ROM/Bank/MAP/实机仍待用户本地验收。


## TRF-5.62.209 / TEST-215 — 用户定点验收后的提交收口（2026-10-25）

- **真实基线**：仍是已提交 `TEST-209 / IMP-5.62.207`，导出 HEAD `eae3e430690fcc798083887b09d44e891717cead`、分支 `常规功能备份`。208～215 全部是该 HEAD 以后的累计未提交源码状态；不能以 TEST-214、TEST-215 的版本字符串推定已 Git Commit。
- **当前候选**：正式 `TRF-5.62.209`，测试 `TEST-215`。用户已确认第二次选招菜单 B 无效，普通菜单 B 仍正常；`214.mp4` 对 01/02/06/10 主路径有观察记录，03 Dig 后段证据不足；05/09 野生敌方前置招式与设计不符，07/14 也可能不稳定。15 项不得写作全部通过。
- **保持旧逻辑**：Disable 槽号跨变身的既有状态不修改；野生敌方 PP=0 仍可抽选是旧规则，不作为正式 AI 故障修复。已通过的画面缓存刷新、Transform 续执行与 B 键修复保持 ASM 字节不变；已提交 Imposter 入场功能不重复纳入新增功能的实现。
- **本次清理方式**：当前 TEST-215 工作区 → 最终整理状态的文档清理增量；自准确已提交 `eae3e430…` → 最终状态的累计全量。由于累计差异还包含独立测试构建的场景夹具和菜单版本，此次按**模式 A**拆为功能提交与测试工具提交，并附反向隔离补丁和两份日志；执行前自行核对精确 Git HEAD 与工作区。
- **提交／验证边界**：用户自行 Commit/Push；本环境没有执行 ROM 编译、链接、MAP/Bank、正式/测试四目标或 Link 双端运行，不将静态差异回放视为这几项 PASS。TEST-214 的 05/09 测试设计缺口与未验边界留作未来独立测试维护，不混入本轮正式引擎修改。


## TEST-216 开发基线补充（2026-10-25）

- 用户本轮上传 `TEST-215.zip`，导出信息记录分支 `常规功能备份`、HEAD `92ac347531c3fe2f72597a60d91d24b7dd2e9aa2`，源码正式版本 `TRF-5.62.209`、测试版本 `TEST-215`。ZIP 不含 `.git`，该值来自导出记录，未在容器内执行 Git status。
- TEST-216 目标：正式 `TRF-5.62.210`、测试 `TEST-216`。成功 Transform 清除施术者旧 Disable 槽位／招式编号状态；失败 Transform 保留；之后新 Disable 正常运行。
- 新增测试场景 `$4f/$50/$51`：玩家清除、敌方清除、失败保留。测试状态只由 `BATTLE_TEST_BUILD` 注入，不改正式 AI、Disable 随机选择或 Link 规则。
- 开发阶段仅交付增量补丁和从本轮 HEAD 起的全量补丁，ZIP 仅包含这两份补丁。未编译 ROM、未生成 MAP、未执行 Commit/Push；用户需运行新场景 16–18。
