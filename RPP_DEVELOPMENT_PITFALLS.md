## JSON-5.62.242｜桐树林合同 JSON 与原版素材 fixture 必须一起跟踪（2026-10-25）

- `tools/johto_ilex_gold_staging_manifest.json` 与 `tools/johto_ilex_west_contract.json` 曾只存在于未提交 Worktree 补丁，最新源码 ZIP 没有这两个文件；单靠地图 ASM/PNG 仍能看见功能代码，却无法在新环境中重现 Gold 来源与双格门口合同。
- 旧 staging manifest 的 fixture 路径不存在，碰撞数量与 mask SHA-256 已过期，而且把已接入源码写成 `runtime_enabled=false`。现在固定原版 Gold 405B `IlexForest.blk` 与通用转换器产生的 216B 碰撞遮罩 fixture，并分别记录 Gold 源文件和 RPP 运行时资源 SHA-256；图块、PNG、palette 经过原生适配，不能宣称逐字节等于 Gold。
- `runtime_open=true` 只表示南侧两条门口通道已接入源码，不代表 ROM 已链接或手机已验收。必须同时保留 `ROM NOT_VERIFIED`、`PHONE_PENDING` 和 Route34 北口 `SEALED` 状态，禁止把静态审计误写成实机 PASS。
- `johto_ilex_gate_runtime_audit.py` 已检查合同 JSON、来源哈希、fixture、运行时资源哈希、RPP Warp 槽位/方向和北口阻挡；负向测试必须证明错误哈希、错通道坐标和缺失 fixture 会失败。流水线生成的临时报告 JSON 不作为源文件提交。

## OLIV-5.62.241｜公共建筑批量导入与稳定版守护（2026-10-25）

- **MART SoftReset 真正危险点**：源端 `data/mapObjects/JohtoOlivineCity.asm` 和 `engine/overworld/region_map_lookup.asm` 的目标 Warp 必须精确一致；曾因只改目标查询或盲目将稳定版 0→0 迁移为 1 而出现跳标题。当前已被用户确认可用的 0→0 路径作为实机兼容基准保护，不能仅凭 Gold 原始编号替换。未来变更需同时核对回程、Gold 目标和实机，而不是为绿测试捏造编号。
- **咖啡馆与 NPC 回归**：Gold 出口方向地毯是 COLLISION_ONLY/向下触发，站在上面与左右横移不得立刻出门；新的 Cafe local ID 必须经过原方向分派。Clerk 默认绿、Sailor 默认蓝、Fishing Guru 蓝色变体的指针/VRAM、调色、角色实际加载必须一起核对，禁止只改注释或只改 `color/sprites.asm`。
- **转换链漏检**：生成器与审核不能采用同一个错误预期；必须对比 Gold 独立 Warp/NPC 原始数据并注入错误，防止城市源端 Warp 与目标表不同步。当前导出 ZIP 因全局 `*.json` 忽略，缺少公共建筑两份生成清单和 4 份 `provenance.json`；专项会报 FileNotFoundError，应由后续单独工具修复处理成可复现受控输入，而不是把缺文件当 PASS，也不可在清理包中盲目新增会与用户忽略文件冲突的 JSON。
- **证据级别**：用户回复「没问题了」仅支持稳定版候选所覆盖的实机操作；该清理未重新编译 ROM。定向 30/30 PASS；另 12 测试 2 ERROR（缺 JSON）；统一发布门禁本轮没有完整通过证据时须登记真实状态，不能以局部通过替代。

## 2026-10-24｜浅葱公共建筑批量预备：多目的地 Warp 不等于普通民宅双出口

> OLIVINE-5.62.241 DEV：公共建筑 NPC 的普通 tile-collision whitelist 不能直接使用 Gold 的原图 ID；同一 8x8 图像可能同时出现在可走地面与阻挡家具。运行时生成器会为可走脚下图块复制像素、复制对应 block，并只改可走 cell 的左下图块 ID；玩家仍使用精确 Gold blocked-mask。两条碰撞路径需分别审计。Pokecenter 2F 楼梯目前刻意保持阻挡且不注册 Warp。


- Gold `OlivinePokecenter1F` 有两条回浅葱市的 Warp `(3,7)/(4,7)`，以及第三条 `(0,7)` 通往 `POKECENTER_2F`。普通 House1 的“两条室内 Warp 全都返回同一室外”断言不适用；不能因此放宽现有全项目 Warp 规则。`--allow-nonlocal-warps` / v2 manifest 仅能生成离线预备报告，把第三条列为**需注册真实目的地或实际阻断**，不得生成启用的虚假 Warp。
- Gold `OlivineMart` 使用 `mart`，`OlivineCafe` 使用 `game_corner`，`OlivinePokecenter1F` 使用 `pokecenter` 图块集；与现有 RPP Kanto 图集逐像素匹配均为 0。`tools/olivine_public_candidates/` 的 96 槽原图 PNG、压缩 `.bst`、`.blk`、palette 和遮罩目前为**未接入的候选素材**，需要独立 Tileset 编号、精灵加载、人物 NPC 图像、实际碰撞/音效调色和 ROM/MAP 容量检查。绝不能直接把 Gold 的原始 `.blk` 编号放进 RPP 现用 Mart/Pokecenter/House 图集。
- 本批次 Gold 9 NPC 的位置清单和 8 种共享原版人物 PNG 已准备；静态 PNG 文件存在不等于显存中的精灵可见，更不等于 A 键特殊脚本安全。不要误将仅能读取 `hSpriteIndexOrTextID` 的人物对话指针当作可空数据，以免误触发或空指针。
- 离线 v2 批处理不可创建地图/开放城市房门。**先把候选图形转成真正可链接资源，接通每个返回 Warp + step，并覆盖成功和错误路线的负向测试，再交用户手机验收。**本轮未触动三间用户已验收民宅的 ASM。

- **被忽略的 `.2bpp` 不能代替正式 PNG 源文件**：`.gitignore` 忽略 `*.2bpp`，本地已有生成物时可能让编译成功，但干净源码包无法重建。每个被 `INCBIN` 的 `.2bpp`／`.1bpp` 都要有同路径 PNG 源，普通资源走通用 PNG 转换规则；使用绝对图块 ID 的稀疏图集必须像 `johto_house` 一样声明专用无裁剪规则，并校验固定槽位与输出字节数。不要把生成的 `.2bpp` 误当成唯一源，也不要因源文件存在就声称 ROM／手机已验收。
## OLIV-5.62.241｜浅葱市民宅首座室内正式收口（2026-10-23）

- **不可只按 `bg_event` 判断家具无反馈**：Gold 的 `House1` 家具 TV、Town Map、WINDOW、RADIO 是 Tileset 碰撞标准互动，与书架的显式背景事件不同。RPP 采用限定地图 ID34 + `JOHTO_HOUSE` + 玩家正前方 Gold 格子的家具查询；地图复用既有城都地图显示，电视／窗户复用普通文字，收音机当前仅普通文本，不得虚称已完整实现 Gold `MapRadio` 频道／音频。
- **NPC 只转头不走的根因**：玩家位置遮罩与 NPC 图块通行名单不同，初始 JOHTO_HOUSE NPC 表只有 `$FF` 导致女儿 `WALK, 2` 不移动；恢复严格白名单并继续阻挡家具，新增反向测试。父亲 `STAY, NONE` 不应为可行走；原版右书架被父亲阻挡不得为达成测试强开。
- **统一发布检查器必须认识真正已建的唯一民宅**：原 Route39/Olivine 相邻审核禁止所有城内 Warp，需改为只容许 Gold `(29,11)` 的一个真实 Warp、其余10个保持封闭；旧源码 `BGEVENT_READ` 工具假设所有房间书架文本从 #1 开始，漏考虑两名 NPC 文本优先，所以该房的两个书架是 Text IDs 3/4。两个违规情况都有反向检测。
- **室内能力不应被错报**：local ID34 的 Surf 明确 `FORBIDDEN`，比未审核 `DEFERRED` 更严格；更新老 Field Moves／Surf 工具的精确预期，不得将禁用室内 Surf 改成全局允许。新增两条 BUILDING Warp 合同分别核对城市一个入口和屋内两条出口。
- **历史错误的可复现教训**：曾漏随新地图补屋顶调色和屋顶图形分组；曾将尚不存在的 docs 计划文件写成修改而非新增；曾在 ROM0 新分支引起 `JR` 超范围。正式打包必须从真正的干净 HEAD 重建开发候选，再验证增量／全量及二进制资源、文件权限，不能用已存在文件的开发目录冒充干净基线。
- **证据边界**：用户于最终第七轮确认操作无问题，不能代替助手执行 RGBDS 汇编／链接或全量 Gold 静态发布门禁。此次完整静态门禁运行超时，专项检查通过但不能写成完整 PASS。正式版本升级为 `OLIV-5.62.241`，保留其它房屋／冰雪通路入口封闭；提交拆分仅供用户执行 Git Commit／Push。

## SPID-5.62.240｜门房正式清理与下一阶段旧/新地图执行链标准化（2026-10-23）

- **失败记录不能被 944 PASS 掩盖**：`.240` 注册 Gold Warp、方向、门房合同却漏掉 legacy `$F4` 在通用 `CollisionCheckOnLand` 的真实行走放行；同时只核对 Header 连接，漏掉 29 号道路 `Bank $40` 预览 46 号道路 `Bank $47` 的 ROM Bank 选择，造成玩家卡在门前及北屏大面积粉红图块。后续 `.240A` 只修这两条入口与预览路径，保留真实障碍、Gold `.blk` 和 Route46 双门毯。原 Gold `DOOR` 从门前 `(27,2)` 向上踏入 `(27,1)` 应一次按键 STEP_ON，而非门框上再碰一次。
- **审计补强必须解释失败的执行分支**：新增 legacy 入口调用与条件、跨 Bank 连接 Bank 选择的 4 项正/反例并加入发布门禁，保证故意错改门格坐标/UP/调用点、邻图 Bank/方向会失败。它们守护这次缺陷，不等于所有旧地图已完成统一审计；不能将 `johto_door_contracts.json` 的自我一致性当成 Gold 或真实 CPU 执行证据。
- **用户手机反馈的边界**：`.240A` 实测视频与用户“没看出什么问题”支持所示门房进出/重进及 29 号道路上缘可见画面无明显异常。本门房 Door/Visual 标记只针对所见范围；独立精确颜色核对、其它门房、全部时段与旧存档仍待测。正式 `.240` 仅收口、版本标签与证据整理，不改行为；不声称 AI 已编译 ROM 或完成用户 Git 提交。
- **先建立迁移对照再共享化**：所有已做旧道路/城镇按 `legacy map alias` vs `native region/local ID`、ROM Bank、Warp 类型、到达步进、实际碰撞入口、邻图两种加载路径、地区地标/Fly/音乐分组做可执行对照。先守护已验收实际路径，再针对一个最小重复点引入适配层；严禁把旧 `$F4/$FB` 统一硬改成 `$FC`、全图放行墙体、硬编码错误 Bank，或为新增地图无条件扩大所有邻图预览宽度。
- **本次正式静态证据**：本次正式 `.240` 在实际用户 `.240.patch` + `.240A` 补丁复放后的源码上完整执行 `tools/johto_map_release_audit.py --expect-version SPID-5.62.240`：退出码 0、status=PASS、944/944 Python 测试通过、0 skipped，56/56 有向活动连接 PASS；Gold 368 张登记、367 张扫描、367 张来源 PASS、0 失败，`SafariZoneBeta` 按原白名单排除。masked-step 为源码级 21 图/162 移动边、139 条要求放行、0 failures；ROM 编译/链接和真实手机全部状态均不由此证明。
- **清理提交纪律**：相对用户导出 HEAD `2df68ee3` 累计有运行时和 `tools/` 变更，模式 A 两笔。只在工具反向隔离时撤第二笔（含本 TODO、踩坑、提交索引、测试/JSON）；游戏功能和 `data/game_version.asm` 完整保留。反向隔离 `git apply -R` 可还原；未核对用户最新真实工作树时先 `git apply --check`，JSON 已存在冲突不能强制覆盖。

## SPID-5.62.240A｜手机截图揭露 Route29 单格门与跨 Bank 顶栏假绿（PHONE_PENDING）

- `.240` 在 `JOHTO_ROUTE_29_LOCAL_ID` 的方向 Warp 和 `STEP_ON` 静态合同上 PASS，却遗漏玩家真正的 `CheckTilePassable` 路径：Route29 旧别名 `$F4` 不走 `$FC` 的 `JohtoNativeCanStepAhead`。从 `(27,2)` 朝上进入 Gold `DOOR(27,1)` 被原 RBY 泛用墙碰撞拦住，因此未进入踏格执行器。只在精灵/ledge/tile-pair 检查后给准确 Route29 位置、方向放行，不改通用分派或把实体门改成 `COLLISION_ONLY`。
- Route29 和 Route46 虽有正确的 NORTH Header 连接，`ResolveNativeConnectionPreviewBank` 当时只识别 native `$FC`，漏掉源图 `$F4`，导致把 BANK `$47` 的 Route46Blocks 指针用于 BANK `$40` 当前源图读取，产生上方整片粉红墙砖。强制审计必须校验跨 Bank 选择器的真实分支并注入错误 Bank 负例，不能只检查连接字段/`.blk`。
- 新增运行分支解释执行及负向测试纳入统一门禁，原完整静态 PASS 不能作为手机行为证据。正式视觉与双向进出验收仍待用户用新 ROM 验证；不重新绘制 `.blk`，不更改已通过的 Route46 双格门毯。

## SPID-5.62.239｜东线四图收口：Gold HOP_RIGHT 遮罩误封与旧测试硬编码（2026-10-22）

- **门禁必须完整跑一遍**：仅 12 项新增专项测试通过并不代表完成。真实完整门禁首次返回 924 单测、11 FAIL／18 ERROR；多数由旧代码假定 41 活动图、46 条连接、临时拷贝不包含新 `engine/overworld/johto_east_exterior.asm` 导致，且 Gold 全量遮罩源证据当时尚未跑完。必须保留失败、逐个定位根因，不能用删除旧负向用例或只改数字绕过。
- **真实漏接：HOP 起跳点不一定等同源碰撞遮罩中的普通 FLOOR**：Gold Route45 的 `(6,20/21)`、`(6,64/65)` 角色为 `HOP_RIGHT`；离线 blocked mask 将其置 1，运行时会阻止踏上起跳格。**仅修 `maps/JohtoRoute45.blocked_mask.bin` 的四个确定 bit**，原版 Gold `.blk` 和隔离的 Gold 审查 mask 维持逐字节原样。运行时审计用 Gold `plan_gold_quadrant_collision()` 独立证据核对确切四格，再从预审 mask 按这四格生成唯一合法的实时 mask；阻断任意第五格放行或四格再次封闭。Gold 实墙 `(7,20/21/64/65)` 仍必须 blocked、落点 `(8,...)` 不可 blocked。
- **完整地图跳崖审计要跨 Bank47**：`HandleLedges` 的 `.eastHops` 分派调用 `JohtoEastHopDirection`；新路每张的列表位于 `johto_east_exterior.asm`，旧 `ledge_regression_audit.py` 只识别 `.route43Hops` 等老列表，所以新增合法地图会触发“未审计 Gold HOP”的硬阻断。修复时同时验证四图 21／47／88／20 个 Gold 精确坐标与方向、重复位置、实体墙、两格安全落点，并将四图登记为已审计；不能仅把新地图加入白名单。
- **旧测试副本也有依赖**：Ruins、Forest、Route33 的故障注入会按旧文件清单构造临时源码树，ROM0 检查已依赖 Bank47 新文件后出现 `FileNotFoundError`。正确做法是同步临时镜像/符号链接文件，并继续验证被注入错误确实命中原有独立断言，不是为测试设置“缺文件即不检查”。Route42—卡吉镇西门 Gold 走廊不能被东门 Route44 合法 y16/17 造成的 `cp 16` 文本误伤；断言按真实分支执行路径限制范围。
- **版本与提交**：用户正式展示 `SPID-5.62.239`，本轮不增加 A/B 字母。使用其实际导出快照而不是推测 HEAD，采用模式 A 两笔分别准备运行时功能和工具测试，反向隔离补丁只能去掉第二笔；本轮只收口，不提交、不推送、不另做交接。

## 东线 SPID-5.62.239：预审通过不等于室外地图已接入

- 原导出图 `Route44 / BlackthornCity / Route45 / Route46` 的 `.blk` 仅是离线材料。开启地图必须同时登记 active slot、原生头/Bank、Gold 定向连接、ROM0→Bank47 前缘 fence、位置遮罩、Surf 与跳崖 runtime，以及普通地图与 Fly 两套独立名字/坐标表。
- 真实缺陷：初版普通地图表 `JohtoNativeTownMapIndices` 误把 Gold 索引写成 38/40/42/44，实际对应 Ice Path、Dragon's Den、Dark Cave、Silver Cave；正确索引为 37/39/41/43，且 `engine/town_map.asm::JohtoNativeTownMapEntries` 还必须增加同等数量的 4-byte 条目，否则索引越界。
- Fly 菜单原有 10 个条目，Blackthorn 新增第 11 个后，`.next/.previous/.findForward/.findBackward` 循环上界应一致，并保障已访问 `$44D` 位及 Fly `$FE` 选择器跨动画实体 ID。修改菜单数量也必须同步保留历史前十条的反例测试。
- Route45 北端 Gold 可穿行 X 区域是 `[0,1,8..13]`，不是一个统一矩形；Route46/Route29 边缘虽然有 Gold 视觉连接，但对应接缝实际撞墙，绝不可统一按方向放行。
- Route44 Gold 有 22 个 `HEADBUTT_TREE` 检测位置，技能暂不启用时必须记录精确 Gold deferred 坐标；放宽 Field Moves 审计的所有地图白名单不可替代这个证据。
- 遗迹、公园旧测试的固定活动图数 `41`、连接数 `46`、屋顶组 `10` 需要随新增地图改为 `45/56/11`，但原有实体目的地与负向篡改断言都要保留。Gold Ice Path 1F 未实现冰面与 B1F，缺其中任何一环不得启用洞口或宣布东线洞穴可玩。
- 发布静态 `PASS` 不等于链接成功，银行容量/`JR` 距离和手机显示/进出仍须按项目纪律由用户编译及实机测试；禁止将未编译写为通过。

## SPID-5.62.239｜正式版本订正与东线 Gold 先行审计（2026-10-22）

- **正式版本纪律**：用户明确要求 `.239A` 仅作为当时测试候选标记，游戏最终版本为 `SPID-5.62.239`。只改 `data/game_version.asm` 的可见版本字串，已验收运行时函数不动；旧记录保留后缀用于准确指认曾交付的测试补丁。
- **Gold 图块集审阅范围**：既有 RPP Johto `.bst` 曾为可走楼梯 `$06`、崖边等扩容/重映射，不能将整份 RPP 文件和 Gold 原版 2048 字节做全文件哈希等价检验；正确检查新地图实际用到的每个 metatile ID 16 字节定义。当前 Route44、BlackthornCity、Route45、Route46 使用到的 ID 定义逐项一致，未证明其他未来室内 tileset 可共用。
- **地图连接与入口不能提前打开**：Gold 44 号道路向西连卡吉镇、向东连烟墨市，且 `(56,7)` 洞口通往 IcePath1F，后者 `(4,19)` 返回 44 号道路。不能只看到地形和 Gold 四方向边界匹配就加入活动图；应先完成本地图 Mask、Surf、水岸、21 条跳崖、封闭未开放洞口和实际出入来源的 Warp 解析。未接入的烟墨市 Fly 与所有室内入口不可提前启用。
- **静态合同故障注入**：`johto_east_corridor_source_audit.py` 复用项目现有 Gold 事件/连接/区块解码器，检查稳定 ID、五张原始 `.blk` 哈希、8 条有向连接、Warp 双端及共享户外可见区块。单测错误注入覆盖改错冰雪通路门口目的地、改错连通偏移、损坏图块字节、伪造 source 摘要、擅自将 OFFLINE 改为 RUNTIME_APPROVED；这些均必须 FAIL。源码级 PASS 不替代屏幕图像、地图接缝、ROM Bank 或手机验收。

## SPID-5.62.239｜正式收口：公园草丛、Field Move 与遗迹右口（2026-10-22）

- **用户验收状态**：用户收到修订包后反馈“没问题了”并要求收口。此反馈覆盖本轮提出的公园草／长草遮挡、骑行与野外 Fly、普通地图地标及遗迹门房右侧入口；不代表未提及的旧存档、全部按键边界和全部地图都完成逐项实测。
- **真实入口与遮挡修复已保留**：Route32 旧 `$FB` 句柄必须同时登记到实际被调用的 `ExplicitWarpRegionTargets`，不能只看 `NativeRegionWarpTargets`；公园普通草 `$04` 与长草 `$3A/$3B/$4A/$4B` 的脚部遮挡要分开核对；野外 Fly 使用许可和 Fly 落点名单是两套不同合同。
- **统一静态证据与复测范围**：候选最终功能代码在收口前的完整门禁报告为 `PASS`，902/902 unittest、0 skipped、46/46 活动连接；Gold 登记 368、扫描 367、源错误 0，`SafariZoneBeta` 仍按既有许可唯一排除。收口后将三座门房的合同状态更新为 `PHONE_ACCEPTED`，重新运行源码级 Gold 审计仍为 `PASS`、0 errors，相关准入／公园门房／遗迹门房定向测试 37/37 通过。完整 unittest suite 的收口后复跑超过执行时限，不能将候选期 902/902 写成一次新的收口后运行。Masked-step 审计 21 张地图／162 条边：139 PASS、23 `REVIEW_REQUIRED`、0 failures；不能把 REVIEW_REQUIRED 当成逐边验收。36/36 图块集 ID 索引形状检查通过。
- **功能状态与构建状态分开**：用户反馈已登记为本轮范围的 PHONE_ACCEPTED；这不等于本助手已编译／链接 ROM。当前没有对应 ROM/MAP 哈希或最新 Bank／VRAM 余量证据，本项目继续禁止 AI 自行编译／链接 ROM。
- **三件套与双提交纪律**：正式收口同步 TODO、踩坑、`commit-message.txt` 索引；运行时 ASM、地图资源与 `data/game_version.asm` 属第一笔 `feat(johto)`，工具／测试／合同 JSON／收口文档及提交索引属第二笔 `test(tool)`。清理增量基于已应用 `.239A` 候选，全量基于 `.237` 导出快照；工具反向隔离仅用于分离提交，绝不撤回 `scripts/*.asm` 等游戏运行时逻辑。Git Commit／Push 由用户执行。

## SPID-5.62.239｜字母候选期故障记录（历史）

- **入口真因**：旧句柄 `JOHTO_ROUTE_32` 与新 native 室内门房不能只检查 `NativeRegionWarpTargets`；从 Route32 右口进门的 `REGION_WARP_ESCAPE` 必经 `ResolveExplicitRegionWarp` 的 `ExplicitWarpRegionTargets`。`.239` 漏了源槽位 1/2，错误分支退到 Vermilion Ferry fallback；旧单元测试只断言 native 表映射，造成假绿。修订按 Gold 和现有 RPP Object 的真实编号补两条 legacy-source 显式映射，保留洞口槽位0。负向测试删除或错改任一入口必须 FAIL。
- **草丛根因**：新 Park 图块集把 `wGrassTile` 设成 `$FF`，与 `.193` Route33 错误相同；还不能把 Gold Park 的 `LONG_GRASS` 简化为 `$04`，其真实四张图块是 `$3A,$3B,$4A,$4B`。只在 Park 限定实际人物/NPC 的下半身 OAM priority；原 Gold 176 格普通草及 176 格长草均必须交叉核验，不碰野怪概率。
- **技能与地标解耦**：Park 加 `BikeRidingTilesets` 和 `.fly` 野外许可，但 Fly 目的地仍 `FORBIDDEN`（Gold 无 Flypoint）；新门房不可骑车或 Fly。Town Map 的四个 Gold 地标 18/17/19/7 属普通浏览项；门房 neutral 地名牌与普通地图索引并不冲突，不得将它们变成 Fly 菜单项。默认独立室外精灵集也需登记 Park，不然图块切换后的角色资源可能残留。
- **实测边界**：本次可从原版 Gold 证明入口/图块和源码分支；未经 ROM 编译、链接 MAP、手机画面/逐帧输入复核不得声称用户报告的问题已经全部实际消失。按项目规范 `.239` 尚未正式用户验收时修订后缀为 `.239A`，不提前递增 `.240`。

## SPID-5.62.237｜正式清理收口：Gold 门房合同、审计误报与双提交边界

- **功能合同**：Gold 实体 `DOOR` 是 STEP_ON；`WARP_CARPET_<DIR>` 可站立，仅在对应方向碰撞时 Warp。切图后自动步进由目的地格的 Gold 碰撞类型决定，不能由入口方向或门房朝向推导。Gold 24 座门房共 100 个 Warp（26 个实体门、74 个方向门毯）；当前 9 座活动门房的 67 个入口与 55 个到达点逐项核对。
- **Route35 检查器的漏检／误报根因**：实际 `.route35South` 使用 `jp z, .down`，旧检查器只匹配 `jr z, .down`，把等价且正确的汇编分支误判为失败。修复后同时接受 `jp`／`jr`，但仍严格要求 y=33、x=9/10、DOWN 分支与拒绝回退；不能通过放宽整个门房规则来消除误报。
- **负向测试曾经失效的根因**：Route35 测试替换不存在的旧 `jr` 文本，未改变源码；ROM0 地图分派和 Route43／Lake 接缝也存在相同的过期指令锚点。现有测试先断言锚点恰好命中一次，再验证源码确实改变，并断言错误分支被审计器拒绝；关键用例已加入统一门禁的 `REQUIRED_TEST_IDS`。
- **实测测试证据**：Route35、ROM0 分派、Route43／Lake 三个专项模块组合 53/53 PASS。统一 `johto_map_release_audit.py` 实际退出码 0、`status=PASS`：867/867 unittest、0 skipped、46/46 活动连接 PASS；Gold 登记 368、扫描 367、`source_failed=0`，`SafariZoneBeta` 按既有许可唯一排除。
- **不得误读静态报告**：masked-step source audit 覆盖 17 张地图／106 条移动边，`failures=[]`，但有 18 条 `REVIEW_REQUIRED`，这些边不是逐边 PASS。Gold 报告为 `SOURCE_ONLY_RUNTIME_UNVERIFIED`；ROM Bank／VRAM 预算未验证。本项目禁止 AI 自行编译／链接 ROM。
- **用户功能验收范围**：用户确认当前候选的门房功能已经实测。本次只清理工具、测试和收口记录，不改运行时门房逻辑，因此不要求重复测试。未取得本轮 ROM/MAP SHA-256 或链接报告，不据此声称二进制配对及空间余量已核实。
- **提交隔离**：从金银分支正式基线 `2442898bed3a28be9f9009eb4703c456b7ec3d65`（`SPID-5.62.234`）到 `SPID-5.62.237` 同时存在游戏运行时／地图资源和离线工具／测试改动，必须按模式 A 双提交。第一笔只含运行时 ASM、地图／图块／碰撞／水格资源、注册与版本；第二笔含 `tools/`、测试、门房审计合同文档、TODO、踩坑与提交索引。反向隔离不得撤回 `scripts/*.asm` 游戏运行时脚本或 `data/game_version.asm`。

## SPID-5.62.235D 候选｜卡吉镇单格实体门 STEP_ON 漏检与修复

- **手机视频 .235C 真实失败**：卡吉镇 (9,1) 单格 Gold `DOOR` 只走到门砖后停留，再按一次 UP 才进门。源码的门房合同把它误写为 `COLLISION_ONLY`，实际 `JohtoNorthGateStepWarpAllowed` 漏登记卡吉镇；故 849/849 只证明同一个错误合同在脚本、ASM 两边自洽。Gold 原版 `DOOR` 与 Route43 (9/10,51) 的双格 `WARP_CARPET_DOWN` 不是一类。
- **游戏修复**：只在现有 `JohtoNorthGateStepWarpAllowed` 中加入卡吉镇精确 (9,1)/UP 的 STEP_ON 分支；保留从 (9,2) 进入门格的既有最小 mask 例外、Gold 房顶不可走、出门到卡吉镇后的 `D_DOWN`、Route43 双门毯 `COLLISION_ONLY` 与 `NONE` 落点。HOME `IsJohtoSouthGatePortal` 原有门房分流仍承担通用入口，不另造传送器。
- **审计修复**：既有 `johto_gatehouse_behavior_audit.py` 现在直接以 Gold `.blk`、图块集 metatiles、collision table 独立核对一格北向实体 `DOOR` 必须是 `STEP_ON`；双格 carpet 不同规则。`test_johto_route43_lake_235.py` 额外执行单次按上路径与负向故障注入（同时把 ASM/JSON 改回 `.235C` 错误值仍必须 FAIL）。不得再靠同一个 JSON 自证功能。继续保持 ROM 与手机状态独立于 STATIC_PASS。

## SPID-5.62.235C 候选｜脚本、树林补绘与门房步进一体修复

- **根因一（视野）**：Route43 的原版 Gold 北接缝虽有 x0 与 x8..11 两组可行走出口，但旧 `.235B` 仅复制愤怒湖 x5..14 的 10 列，左侧 x0 通道从镜头看向湖时西侧 WRAM 三列保持默认树图。只扩大**显示用**的北向加载条带为 Gold 湖 x2..14 共 13 列，写入 WRAM x0..12；真实接缝 10 列、5 条合法可走格、南向返回和 Gold `.blk` 都不动。`johto_rpp_connection_guard.py` 将 Gold 真实 FLOOR/FLOOR、边缘执行器、左/右预览宽度、三行拷贝源码作共同 fail-closed 审计，不能只检查 JSON。
- **根因二（门房）**：门房返回 Route43 的双格 COLLISION_ONLY 门毯 `(9,51)/(10,51)` 不能追加 `D_UP`，否则刚出门人物被自动带离门垫，原地反向 DOWN 无法立即复入。删除这两条 Profile（实际 NONE 默认值），更新 `johto_door_contracts.json` 和到达审计；门房北侧入门后的 `D_DOWN`、卡吉镇实体门出口 `D_DOWN` 保留。执行器/门砖 fallback 和两个门垫各自双向规则仍由现有审计与故障注入守护。
- **共同交付与静态验收**：必须同包修改游戏 Header/到达表、脚本检查器、登记表、单测。发布前实际运行统一 Gold 门禁，保留其返回码和 0 skipped 证据。ROM `make`、同版本新 MAP、运行时输入/镜头与旧存档必须由用户检查，静态 PASS 不等于 PHONE_ACCEPTED。Route43Gate 中段和愤怒湖两间室内仍为延期内容，不能为消除树林而开放它们。

## SPID-5.62.235B 候选｜卡吉镇北门口与 Route43↔愤怒之湖左侧空气墙

- **玩家反馈的两处真实故障（手机尚待重测）**：在卡吉镇北部实际 Gold 门口 `(9,1)`，虽然 Warp 表正确，但 `JohtoMahoganyTownCanStepAhead` 没有让 `(9,2)` 向上进入这格 DOOR（静态掩码 BLOCK）；ROM0 的 `IsJohtoSouthGatePortal` 也漏掉稳定 ID64，无法保证撞墙第二次按 UP 走 collision-only 路线。现两处一起修复：只放行 `(9,2)→(9,1)`，并让 ID64 进入已有碰撞方向检查；从 `(9,1)` 再次向上才传送，北侧其余 DOOR/墙维持封闭。
- **重复的 Gold 多走廊空气墙**：Route43 北缘 `(x=0,y=0)` ↔ LakeOfRage 南缘 `(x=10,y=35)` **另有第 5 个合法 FLOOR/FLOOR 出口**；以 Gold `Route43.blk`/`LakeOfRage.blk` + 两张独立碰撞表为真相，它与原已开放 x8..11 ↔ x18..21 **不是同一个连续 4 格门**。旧 `.235A` 仅放行中间四格，左右两端各自的 `EdgeFence` 与 `CanStepAhead` 合计 4 层封死左侧出口，造成穿墙金手指才通。现四层只加左侧单格，不开放 x1↔x11（Route43 一侧是 HEADBUTT_TREE），也不开放其他无路的树墙。
- **脚本全绿但实机空气墙的缺口**：`.235A` 的 831/831、46/46 只覆盖相邻方向/链接字段与部分 Warp 方向，不实际执行整个 Gold FLOOR/FLOOR 多组件出口和“走上门口”前一步。`.235B` 测试从 Gold 独立计算 5 格应开集合，遍历两端每格的 EdgeFence + CanStepAhead、Gold 内侧路径与南门两次输入，还按每一层和 HOME selector 故障注入。以前相同的五格海路修复教训必须延用到所有新直接接缝，禁止将 x8..11 单通道的通过等同于整个 Route43↔湖岸正确。
- **静态验收边界**：本轮不改 Gold `.blk`、Surf、Cut、Headbutt 延期项，不自动开放 `Route43Gate`（Gold `Route43` 另有三个 Warp，目标门房尚未注册）及愤怒湖两幢未开发房屋。脚本解释执行部分 ASM 而不运行 ROM；是否真实解除用户截图处阻挡、链接预算、门房原地掉头与左侧走到湖畔仍必须由用户 `make` 和手机确认。

## SPID-5.62.234（`.234B` 已获用户实机认可）｜浅葱市→Route40 步行空气墙的真实根因

- **问题不在 Surf**：`.234A` 只拦 Surf 地图外误上岸，用户重测“冲浪正常、陆地空气墙仍在”，不能再据此认定修好。
- **Gold 同一条西/东接缝包含不同地形**：Olivine 西缘 x0 的 y20、22–25 与 Route40 东缘 x19 的 y2、4–7 是 **5 格 FLOOR/FLOOR 陆地出口**；y26–31 ↔ y8–13 是 6 格 WATER/WATER Surf 出口；y21 与 y32 及以外不能强开。`.234` 仅在 `JohtoOlivineCityEdgeFence`/`JohtoRoute40EdgeFence` 放行水路，并在两侧 `CanStepAhead` 的边界外查询中把陆地挡住。双重拦截导致步行空气墙。
- **修法**：两边 EdgeFence 和两边 CanStepAhead 同时开 5 格 Gold 陆地边界，水路仍由 Surf 处理，其余边界硬阻；不改 Gold `.blk`、掩码或扩大整条海岸。`tools/johto_rpp_connection_guard.py` 的 `check_olivine_route40_walk_seam` 读取 Gold 真实原图并按窄指令集执行 4 个运行时谓词，验证 FLOOR/WATER/WALL/BUOY 各角色及往返，未知指令硬失败。负例故意漏开任一侧或开放浮标/步行水格，必须报错。
- **以后相邻图发布门禁**：不能把“连接表存在”“水格相等”“42/42 边线静态 PASS”误作步行闭环；所有 Gold FLOOR/FLOOR 边界必须分别验证边缘 fence 与 land mask，两侧各走一次；WATER/WATER 单独 Surf，其他保持封闭。ROM 编译和用户操作验证独立留待实测。

## SPID-5.62.234A（历史修订，未解决陆地空气墙）｜本窗口重复错误与海路边界的硬性检查

- **临时版本用字母，不用连续数字**：上一个实际正式提交是 `.233`，下一批功能候选是 `.234`；在用户验收并正式清理 `.234` 之前，后续修复按 `.234A`、`.234B`、`.234C`…递进。定稿恢复 `.234`，提交后下轮才使用 `.235`。版本末尾的 `@` 是游戏文本结束符，字母必须写在 `@` 前；这不是另一次 Git 提交，也不能据此推断新 HEAD。
- **`.234` Unknown symbol 重犯 `.231` 教训**：Route40/41 音乐 ASM 与 JSON 同时写了未声明的 `MUSIC_GBP_GSC_ROUTE_36`，正确是 `MUSIC_GBP_GSC_ROUTE36`；一份错误不能由另一份同样错误的登记文件“相互印证”。已在 `johto_region_id_audit.py` 增加真实常量声明检查与删定义／双边错名负例。所有新增汇编引用均要查已定义符号，再由用户实际 make 链接。
- **`.234` 邻图乱码重犯 `.121` 的寄存器陷阱**：跨 Bank 预览向 `callab` 传方向时使用 A，而 Bankswitch 会覆盖 A。修正为 E 保存方向；`johto_rpp_connection_guard.py` 已加入调用端／被调用端协议负例。以后检查所有远调用输入、返回值、Carry、当前 Bank，不能只看到调用标签存在就 PASS。
- **本次录像与“空气墙”证据范围**：约 7.4s 手机录像在浅葱市港口牌附近 Surf，随后角色回到陆地，画面仍是 Olivine City；录像无按键方向或 WRAM XY，不能断言某个格子属于运行时错误。Gold 原版 Olivine 只有西向 Route40 与北向 Route39 的直接连接；南侧没有连接。港口东侧水域与西侧 Route40 的合法 WATER 接缝不属于同一水格连通分量，不得简单连通南界／放行墙格来伪修。真实西侧出海条带为 Olivine (x=0,y=26..31) ↔ Route40 (x=19,y=8..13)，必须从两端实际 Surf 往返并提供 ROM/MAP、坐标或输入实测才能标 USER_ACCEPTED。
- **已证实的运行时防护缺口（`.234A` 候选）**：`CollisionCheckOnWater` 在 Gold 水格查询失败后直接检查 8×8 预览图块是否可上岸，未先拒绝越过已注册地图范围的 Surf 目标；屏幕外的可走图块可能被错误当成岸边，造成异常下水／地图边缘假通路。现在对 Olivine、Route40、Route41、Cianwood 的越界 Surf 目标先硬阻断，合法水格接缝继续由 Gold 水格查询放行，地图内真实岸边仍走原生下水逻辑。工具要注入缺守卫、反转返回 Carry、允许无南侧连接的故障负例；**静态检查不等于视频中所有阻挡已经实际消失**。
- **开发交付与提交日志的两项流程失误**：`.233` 之前曾交过只有双图素材与转换器、没有运行时接线的预制包，让用户拿到后仍无法从 Route38 走进新图；以后以“本批相邻地图能从已开放地图实际进出＋适用技能可执行＋原有脚本改进同包”为开发候选交付门槛，不能将素材 PASS 冒充完成。正式 Git 日志曾写成几百上千字的复盘，用户明确要求短且只写本提交真实改动：标题、实际游戏功能/修复项、必要的结果与 `Version:`；长背景及坑点只记在本踩坑文档，**不要复制进 Git 日志**。工具提交也仅写实际新增检查或修正，不重复描述游戏提交内容。
- **重复“单测全绿却上线出错”并非偶然**：`.231` 常量漏定义、`.232` 旧分支 slot 冲突、`.233` 历史断言写死末项、`.234` 跨 Bank ABI 错误，以及 `.152/.157` 门口即时复入卡死／`.166` 阶梯空气墙，都已经有项目记录。新图批次最低门禁要串起 Gold 转换、可达入口、撞墙行为、Surf/下水、真实双向切图、跨 Bank 传参、Unknown symbol 检查、ROM Bank 余量与用户 make／手机复测；仅 `.blk` 对照或 42/42 静态边线不够。

## SPID-5.62.233：Route39＋浅葱市脚本与运行时功能同批交付（用户手机总体认可，ROM/MAP 待核）

- **不能把安全链路误判为危崖**：`plan_gold_quadrant_collision` 旧逻辑只沿下跳方向多看一次跳崖，最多支持两级。Gold Route39 在 y22→24→26→28 有三级连续跳崖，其中 5 条首级下跳被旧工具标为 unsafe，虽然每级之间均有墙、最终为可落地 FLOOR。改为按 Gold 实际宽高逐级前进，强制每一级前方墙存在、最后着陆点在界内且为 FLOOR/TALL_GRASS。遇断墙、墙中落点、出界或非向下链路须拒绝。已知 RuinsOfAlphOutside (9,30) 仍是 unsafe，不能随修复打开。
- **源地图连在一起 ≠ RPP 已能走通**：原管线逐张产物只证明图块/碰撞；若随意选 Route38+OlivineCity 会跨越尚未开发的 Route39。新增 `--adjacent-pair` 以冻结 142 条 Gold 双向邻接为唯一源级判据，在创建候选前拒绝跳图；同批生成两图并汇总 Gold offset、尺寸、Warp/Surf/HOP 审查证据，不能自动创建头文件、运行时连接或 Fly/Surf 权限。
- **脚本不单独交付**：`.233` 已将 Route38↔Route39↔浅葱市的真实双向连接、stable ID25/26→slot28/29、Gold 地图/掩码/跳崖、Fly/Surf、路标与屋顶合进同一开发候选。原版 Gold 的 13 个未开发室内 Warp 入口在碰撞掩码中全部封闭，没有无效 Header。本轮统一 Gold 静态发布审计最终退出码 0：802/802 单测、0 skipped、36/36 活动连接 PASS；Gold 367/368 扫描，唯一排除 SafariZoneBeta，source_failed=0。用户实测走动、跳崖及绕城未见异常，但 RGBDS 编译日志/同版 MAP 与其余手机场景仍需独立验证。

- **历史测试不能假定最新注册项永远位于表尾**：本轮首次统一门禁为 802 项中 15 FAIL，根因是早期测试仍假定 28 个 active slot、卡吉镇位于最后一行、Route38 只连接东侧，以及屋顶表固定 28 项；Route42 技能测试更错误地按 `maps[-2]` 定位，随地图新增落到了 Route39。正式清理时改为按 stable ID63 查 Route42、把 Route38 的东西双向连接一起证明，并扩展 Gold 屋顶及固定槽位负例；地域 ID 的未来地图故障注入改为按实际注册计数选择下一个 slot。不得为消除失败删掉负向断言或仅改测试总数。

## SPID-5.62.232｜旧东线 `.227` 直接合入 `.231` 会撞 active slot；Town Map 镜像不能自证正确

- **注册冲突**：旧 `金币` 卡吉镇分支假设 slot 25 仍空；`金银` 的 `.231` 已分配 slot 25/26 给东门房 ID62 与 Route42 ID63。不能复制旧共享代码或把 stable ID64 当 slot64；本次以主干 27 张为起点接入卡吉镇 ID64→slot27，保留现有两侧门房/旧存档/关东。
- **漏检的地标与屏幕预览**：仅将 `tools/johto_native_maps.json` 和 ASM 的 Town Map 索引对齐，两者若同时写错仍会全绿。卡吉镇新增单测以真正 45 项浏览地标验证索引（Route35 门房17、Route42 32、卡吉镇34）并注入同时篡改索引/登记的负例。Route42 ↔ 卡吉镇不可只验 y16/17 两格，Gold 西东边线可走廊含 y4–7 与 y9–17；在碰撞判断、边缘围栏及实图连通性中逐个证明。头顶树墙来自卡吉镇北边界没有绘制 Gold Route43 最南 3 行：只向现有 Bank `$43` 边框入口添加第四个局部显示条带，在完整加载/普通邻图切换两处钩子生效，不改已注册图块、不开 Route43。
- **审计和验收分离**：严格四项屋顶顺序、缺钩子/错屋顶、错误地标、空气墙少开入口、Gold 12 跳崖与 Headbutt 延期均由专属正反例守护。用户对 `.232` 候选反馈“没啥问题”，不能推断覆盖了两种加载路径、全部 Fly 存读档及 ROM/MAP 精确配对。正式清理的统一静态发布门禁已 `PASS`（789/789、0 skipped，32/32 活动连接，Gold 367/368；`SafariZoneBeta` 排除）；这是源码证据，非 RGBDS 编译或手机全场景证明。AI 不编译 ROM。

## EAST-42 / SPID-5.62.227｜新增 JSON 合同的 Git 交付坑（B 95666d35）

## SPID-5.62.231｜合并时符号声明也属于硬门禁

- **实际漏检**：初版 `.231` 虽通过 Gold/Python 静态审计，但 `engine/overworld/johto_route33_collision.asm` 引用 `JOHTO_ROUTE_42_ECRUTEAK_GATE_WIDTH` 时，尺寸常量未定义，用户编译出现 `Unknown symbol`。东门房 Header 最初直接写尺寸数字，无法替碰撞例程提供同名常量。最终补齐 5×4 宽高常量、Header 统一引用，并给缺声明增加负向测试。**静态 PASS 不能代替 RGBDS 汇编/链接**；交付前无编译条件时必须标明缺口。
- **双线合并不能整表覆盖**：共同城市两侧 Warp 编号、稀疏 stable ID→active slot、东西向门房的真实 HOME/ExtraWarp 路径需合并验证，西门房 `.230` 的立即复入保持回归基线；Route42 未启用 Headbutt，只准保留精确延期坐标。用户反馈 `.231` 在旧/新窗口测试未见问题，不等于完整 ROM/MAP 关联验证。

## SPID-5.62.231｜双线门房合并避免再卡门

- 双线不能直接覆盖公共 Header/连接/缘朱市 Warp；西门房原回程要保留，东门房在城市里的目的 Warp 必须指向新槽位 2/3。
- 仅碰撞规则正确不等于能进门：HOME 的 `IsJohtoSouthGatePortal` 和 ROMX `ExtraWarpCheck` 都要包含正确地图身份、入口坐标和按键方向；静态测试应对入口条件做删改负例。
- ROM0 紧张：新身份判断不可直接累加代码，应抵消冗余指令；ROM/MAP 关联由用户编译后验收。

## SPID-5.62.230｜Route38 两次卡门：门毯通行、碰撞 Warp 和非边缘 ExtraWarp 三关缺一不可

- **事故真实过程**：`.228` 在东西向门房把门毯上下换格错误设为 `BLOCK`，因为审核把「错误方向不得传送」等同于「错误方向不得移动」，造成上下被卡；`.229` 修正移动和双向 Warp 表后，用户发现「从左门出去到 Route38 再朝右无法复入」；原因是 `(35,8)/(35,9)` 虽可作为碰撞门口，却不处于 Route38 最右图边，`ExtraWarpCheck` 实际调用的 `JohtoInternalDoorFacingCheck` 没放行它们。`.230` 在该独立门槛中按 ID、坐标和朝向精确放行右向动作，禁止错误方向、侧擦与旁边格子触发。
- **为什么 `.228/.229` 全绿仍失败**：早期新测试只检查 mask 允许/阻挡、Warp 目标表、HOME 地图身份或「无自动步进」，没有验证每一次 `ExtraWarpCheck` 实际调用路径。不得把脚本之间分别 PASS 当作完整玩家输入序列 PASS，更不能为了全绿调反预期结果。
- **门房分类不是全门套同一规则**：东西向 COLLISION_ONLY 门房允许门毯正常上下换格，仅向外左右碰撞触发传送；南北向 STEP_ON 与混合门房仍按照各自的 `johto_door_contracts.json` 运行合同验证。新门房必须双格分别做出门、立刻反向复入、侧擦和地毯上下通行检查；真实 HOME 分流、ROMX 碰撞方向和 ExtraWarp 判定分别具备负向故障注入。
- **工具隔离与审计纪律**：地图专属注册/Gold 几何/跳崖/延后 Headbutt 与通用门房合同分两笔工具提交，游戏 `scripts/` 始终属于功能提交。本轮三笔合规拆分对应 4 Patch + 3 日志（比默认双提交规范多一份隔离补丁和一份日志），但不得依此修改已验收运行时；两个隔离补丁只撤回各自工具/文档，反向恢复后须与最终候选逐字节一致。ROM/MAP 链接和全面模拟器键控时序仍需用户或独立 ROM 测试佐证；用户反馈 `.230` 问题解决只按实际反馈范围记账。

## SPID-5.62.227｜稀疏 ID 与 Town Map ROM0 占用回归（新布局待用户 ROM/MAP/手机验收）

- **2026-10-21 共用 C 维护正式收口（纯离线，模式 B 单提交）**：修复 `tools/tests/test_johto_region_id170.py` 中 Town Map 索引迁到 `engine/overworld/johto_town_map_helpers.asm` 后旧测试仍改 `engine/town_map.asm` 的问题，并对迁移表缺项增加负向用例；其余为四份项目说明更新。没有 ASM/游戏资源/显示版本/存档结构改动，ROM0/ROMX 机器码新增 **0 B**，不要求仅为此补丁再次编译 ROM 或重跑手机游戏。随附 MAP 的 ROM0 829 B 是已有 `.227` 布局证据，不能写为本轮新回收。
- **手机验收应按已实现能力决定 N/A**：用户报告已应用最新修订开发包，关都与 Fly 已测，现有城都主要可玩路径及其它已实现功能基本测过，未见明显问题；未提供逐项完整清单。**城都训练家对战与城都夜间当前未实现，均为 N/A**，不能列为本轮必测、测试失败或实测通过。真正待确认的仍包括同版 ROM/MAP 对应、部分特殊取消/旧存档/无效 ID 真实运行；首次 A/B 门房开发另走双向、门毯与首次视野专项。

- 老引擎把 `wCurLocalMapID` 直接当 Header、Bank、音乐、Town Map、屋顶数组行号。固定 ID62 虽已在 CSV/ASM 冻结，但不能在只有 23 项的运行表上当第 62 行。共用 C 候选加了 256B 显式稳定 ID→紧凑槽位，所有未启用目标一律 `$FF`；A/B 不能单独修改该映射表、公共 Header 或旧缘朱市。
- 旧的 `cp NUM_JOHTO_MAPS` 比较不能挡未来合法跳号；不要改成 `cp 222` 造成越界。Far-call ABI 中 A/BC/HL 可能丢失，`GetJohtoActiveSlot` 的返回值通过 E 传递。音乐两个字节步长和 Town Map 四字节步长须用 16 位 `HL`，否则 slot64/128 有 8-bit 回绕。
- **注意 `.227` 曾有两个不同布局**：第一次把两段 Town Map 例程放在 ROM0，旧候选 MAP 见 ROM0 704B；最终 `.227` 已改为 ROMX Bank `$40` 的 `engine/overworld/johto_town_map_helpers.asm`，Bank `$1C` 的包装层须保护 DE 并以 E 回传，ROM0 和 `$1C` 的闪烁调用均须 `callab`。当前 ZIP 随附同版本 MAP 显示 ROM0 829B（最大连续 829B）、Bank `$01` 5B、`$1C` 2B、`$40` 2443B；这是 MAP 文件证据，不是本次独立重新链接或手机验收。用户先前手机简测是旧布局，不能继承为当前布局 PASS。非法 native Warp/连接及坏档 SoftReset 目前仍以静态合同为主，异常场景实机待测。
- 历史 ECRU 段落对 Fly 的旧暂存 index=5 说法已经过期：当前提交版在菜单确认时冻结稳定目的地，Fly 不能再读取容易复用的 `$cd3d` 来区分同 `$FE` 的满金与缘朱。

- **ECRU-5.62.226 防复发（缘朱市功能阶段最终版本；原为 BANK-5.62.225）**：Gold EcruteakCity 20×18 与 Route37 北邻。两条运行时选择表必须精确对应北(0)/南(1)，实际边缘仅放行已验收的南口两格。第一轮把 Fly 标为 `DEFERRED`、遗漏全部 7 个原版标志、未开放实际 20 水格 Surf、左门口直接树林外观；本轮改为访问城市解锁 Fly、精确 Surf/50 Headbutt、不存在 Cut 树不得乱开放、7 标志并恢复 Gold 城市主体；未接入的 Route38 邻图仍会在西侧呈现临时树林，不能冒充真实门房。特别注意 `$FE` 飞空选择器由 Goldenrod 与 Ecruteak 共享，必须在菜单确认时冻结目标稳定 ID 并按其分流，不能依赖易被覆盖的菜单 index 5；门房未开发不能伪造可达性。现有发布审计对新图检查 Gold 事件牌及适用 Field Moves，但测试 PASS 不等于 ROM 可链接、Fly/Headbutt 实机已通过。Gold 旧 SafariZoneBeta 按用户指令仅从全量源码扫描精确排除，汇总必须注明 367/368，不能伪称全查。
## ROUTE37-5.62.225｜地图条带审计 PASS 不等于运行时目的地正确

- **用户真实遇到过的故障**：初版 Route37 的 `NativeRegionConnectionTargets` 将向南（编号 1）误填为向北（编号 0）；Gold 图块连接几何和边界都可通过，却因运行时选择表没有正确命中，回退到了 Route32。用户手机视频确认走错地图且人物动作异常。最后修复的记录为 `JOHTO_ROUTE_37_LOCAL_ID, 1, MAP_REGION_JOHTO, JOHTO_ROUTE_36_LOCAL_ID`。不能把初版 24/24 静态 PASS 记录成手机通过。
- **原检查器盲点与修正**：过去只审计从 Header 发现的现有边；漏登记的边可能不被发现，且未交叉校验运行时选择表。现在以 Gold 368 张图/142 条有向直接连接作为固定参考，检查当前已注册地图的必需连接、方向、offset、目标和选择表的多余/重复/缺失，并对错误方向做负向测试。不得为强行通过改掉 Gold 原始邻接或把门房 Warp 当成直连。
- **未解决的安全域**：运行时无效连接分支仍有回退 Route32 的历史行为；本轮只强化静态准入，不声称对所有非法运行时状态进行安全拒绝。门房/室内 Warp、剧情、跨 tileset、玩家屏幕可视边缘须走既有专项检查并在手机复核。
- **相邻地图切换短暂停顿**：用户 `BANK-5.62.225.mp4` 显示步行／骑行跨地图时有轻微停顿；本轮只记录在 `TODO.md`，不优化切图引擎、未测 CPU 帧数或新 MAP；不得写成已经修好。

## BANK-5.62.225｜ROM0 第二轮主列表迁 Bank `$01`：HOME 回收 705 B 不等于另一个 Bank 安全

- **动机与有效收益**：在 ROM0 第一轮碰撞分派回收 100 B 后，`home.asm` 的 `DisplayListMenuID` 及主输入循环仍占 HOME 大段指令。第二轮把菜单主体放入本来就运行物品交换代码的 ROMX Bank `$01`，HOME 留银行入口和固定返回跳板。用户提供的审查日志对比新旧 MAP：ROM0 空余 **127 → 832 B（净增 705 B）**，但本轮没有可供 AI 独立解析的新 MAP 原件，也没有新版 `BANK-5.62.225` 的 RGBDS 链接证据。
- **跨 Bank 指令流必须正确落回 HOME**：成功选择经 `jp BankswitchBack`，取消先 `jp ExitListMenuReturnHome`（ROM0）再返回原调用 Bank；绝不能恢复其他 Bank 后继续执行原来属于 Bank `$01` 的指令。沿用 `BankswitchHome` 保存调用方原 Bank，保留菜单返回 Carry/取消语义、物品 SELECT 交换后的 `$01` 同 Bank 回跳和 PC/分类背包列表边界。迁移的 12 项故障注入必须能打断错 Bank、漏保存、坏取消与缺失回跳；第一轮 10 项碰撞审计仍必须通过。仅比较函数存在/文本相似不等于真正 CPU 逐帧执行。
- **释放 HOME 可能压满 ROMX**：虽然 ROM0 多出 705 B，审查日志显示 Bank `$01` 只剩 **11 B**；任何后续改动若继续占用该 Bank，可能触发错误链接或音乐数据重新分配。后续新扩图不继续往 `$01` 堆菜单/音频代码；检查各 Bank 最大连续块、已分配固定 Section 与音乐指针/Bank 指针，而非只看 ROM0 总余量。
- **音乐是本轮非预期触及的风险域**：审查日志记录 `Music_JohtoTrainerBattle` 移到 Bank `$03`，`PlayBattleMusic` 在 `$04`，Bank `$01` 包含 `Music_RBYTitleScreen`。MAP 无地址冲突不是播放正常的充分证据；用户最低实机复测须包含标题、城都训练家战斗音效/音乐以及退出战斗恢复，不能只测试背包打开无死机。
- **手机反馈的粒度不能升级**：用户仅反馈“在游戏里面大致看了一下，没有看特别细，没有看出什么问题”；必须继续标记菜单交换/合并、空口袋 START、PC 删除后 Cancel 边界、商店存售、战斗道具取消和 SELECT 禁止交换为**专项待确认**，不得拿第一轮全图走动、门房/碰撞手机 PASS 自动充当第二轮菜单 PASS。
- **清理与版本要求**：本次因用户允许更改版本前缀，在正式清理中将 `ILEX-5.62.224` 改为 `BANK-5.62.225`；字符总长度相同，仅更换 `data/game_version.asm` 的显示字符串，不改游戏菜单机器指令和原有地图。新版本仍需用户编译生成 MAP 并确认。功能 ASM/版本归第一笔，`tools/` 新检查与配套 TODO、踩坑、提交索引归第二笔，反向隔离只撤第二笔；AI 不执行用户仓库 Git Commit/Push。
- **审计独立性与遗留**：本轮完整 Gold 源下 `python -m unittest discover -s tools/tests -p "test*.py" -q` 实跑 **676/676 PASS、0 skipped**；原强制入口 `python tools/johto_map_release_audit.py --rpp . --gold <Gold路径> --expect-version BANK-5.62.225` 实跑 **status=FAIL、tests=676、skipped=0、active connections=22/22 PASS**，唯一错误 `GOLD_FULL_CORPUS: SafariZoneBeta: Gold map references graphics beyond runtime window`。不能只报审查日志的 22 项子集或将该旧失败屏蔽。未验证的未来地图、旧档、全部战斗菜单/音乐组合继续留为明确风险。

## ROM0-5.62.224｜固定 Bank 碰撞分派外迁：回收 100 B 也必须手机测

- **历史空间优化仍在，不是重做旧优化**：`CalcStats`、菜单辅助、Bill's PC、分段 HOME 与数字格式化拆分等旧优化已存在于本轮金银源码。新的 ROM0 压力来自持续积累的地图专用 HOME 派发，不可把整套 Gold Bank 布局复制到当前红版底座。
- **精确 ID 与 ABI 优先**：本轮把 HOME `CheckTilePassable` 的 11 个城都原生地图特例迁到 ROMX Bank `$43` 的 `JohtoNativeCanStepAhead`，HOME 留一次远调用；分派必须保持 region `$FC` + Johto + local ID 的原有约束，不扩大到未知地图。`callba` 涉及寄存器，`E=0` 必须回退通用碰撞，`E=1` 返回原判定；`bit 0,e` 不改 Carry，原碰撞谓词也不可在优化中被覆写。
- **空间证据与运行证据独立**：用户此次全量链接 MAP 确认 ROM0 27→127 B（+100 B），连续空隙约 113 B；Bank `$43` 剩余 8547 B。Python 664/664、门房与连接专项通过是静态证据；用户另在手机把已开发地图基本跑过，门房/卡门/素材/步行/骑行/跳崖未见异常，才可标记本批次手机回归通过。不能把 MAP 或脚本 PASS 单独等于稳定。
- **新增工具合同必须能拦故障**：`tools/johto_rom0_collision_audit.py` 与相关旧检查器、新测试要覆盖 256 个 local ID 的路由等价性、未登记 ID 默认回退、Route32 原 seam、Carry 标志、错误目标函数和游戏入口确实调用分派器；不要只搜标签存在。上一轮检查器曾写死“HOME 必须直接调用每个碰撞函数”，结构优化时需改为真实的 HOME→ROMX→原函数路径验证，不得放宽 fail-closed。
- **空间目标不是发布保证**：建议目标≥256 B 连续可用只是工程目标；目前不足，后续继续按小批次迁移并逐批实机复测，不应将后续边界逻辑工作夹进已手机验收的第一批。
- **清理交付条件判断**：相对本轮已核实 Git HEAD 有游戏 ASM + `tools/` 审计测试累计修改，所以本轮用模式 A（3 patch+2 logs）。若未来仅有游戏功能或仅有工具，按正式规则模式 B 单提交（2 patch+1 log），严禁为凑文件制造空提交。`scripts/` 下游戏事件脚本始终是游戏功能，不是离线 `tools/`。
- **遗留如实保留**：本次正式清理统一发布审计已完整执行，`status=FAIL`，唯一错误仍为历史 `SafariZoneBeta` 图形窗口问题，未关闭。用户未提供每个存档/昼夜/完整 NPC/CPU trace 的新覆盖，不得扩大 PHONE_ACCEPTED。

## RUINS-5.62.224 正式收口｜门房 PASS 不能代替地图全部功能验收

- **跨分支移植最易遗漏的非门房依赖**：本轮第五座门房方向／Warp 强制合同通过后，仍漏带备用分支已经写好的 Surf，后又发现遗迹 `.blk` 使用 `$8A` 而 JOHTO blockset 少了最后 16 字节，造成手机画面乱码；旧执行器正确与图块范围正确不是同一门禁。以后每张新地图必须对照源分支和 Gold 独立盘点 Field Moves、地图最大引用 metatile 与 `.bst` 范围、现有脚本／NPC 缺项，不以门房通过代替地图验收。
- **共用跳崖的安全边界**：Gold 17 个方向 HOP 中 16 个两格落点有效，4 个上崖第一跳到达下层崖顶可继续跳；`(9,30)` 的两格落点是真墙。审计既不能要求所有落点是普通 FLOOR，也不能为全绿把 17 个全部启用。运行代码复用 `.217` `HandleLedges` 且必须精确地图、坐标和方向匹配；测试必须故障注入漏跳、错方向和危险放行。
- **ROM0 不能拿静态节省量替代 MAP**：用户经历过 `Home Pokedex Overworld Restore` 安放失败；最后修复移走 ROM0 的冗余入口地图判断，精确准入留在 ROMX，用户手机已能运行当前候选。上次用户空间界面显示目标 ROM0 27 B，相对 44 B 基准少 17 B，仍不够新地图预算。下一项目单独做 ROM0 专项；此收口不动机器码，不声称获得 256 B 空间。
- **收口证据如实分层**：用户明确反馈遗迹修正实机正常，保留 `USER_ACCEPTED`／门房 `PHONE_ACCEPTED` 作为范围有限的用户报告；不提升遗迹 NPC 剧情、全色板时段、所有存读档及逐帧输入为已测。统一 Gold 的 SafariZoneBeta 遗留失败照旧存在。
- **提交隔离**：游戏功能（含 `scripts/` 的运行时汇编）作为第一笔，整个本轮累计 `tools/` 修改和相关 TODO／踩坑／正式说明作为第二笔；隔离补丁只撤第二笔，恢复后测试并提交。不能把“功能 vs 文档”当作“功能 vs 脚本”。

## RUINS-5.62.224：连续两层 Gold HOP 不能被“第二格必须 FLOOR”的旧模型误删

- Gold `RuinsOfAlphOutside` 的 HOP 候选为 17 条方向；旧通用 `plan_gold_quadrant_collision` 只认普通地面落点，误报 5 条“unsafe”。逐格分辨后其中 4 条是 y30→y32 **落在下一层合法 HOP 起跳格**，该层 y33 为墙、y34 为普通安全落点；(9,30)→(9,32) 却确实落墙，必须永久禁止跳跃而非把 17 条全开。
- **改变安全识别不是放宽所有 HOP**：只有同方向下一层实际还有阻挡和合法第二次落点，才允许把 HOP 当作第一次安全落点。Gold 源级危险例外必须 exact-match `(9,30,0,1)`；数量不符/坐标变化即报错。RPP 运行时按全地图精确坐标与方向配对，沿用 `.217` 共同 `HandleLedges` 而不按共用图块 `$06/$4c` 放行整张地图。
- 新地图注册后 `ledge_regression_audit` 必须发现所有 Gold HOP 并核对实际 ASM 表、阻挡 mask、两格落点和危险例外；新增负向测试纳入统一门禁。静态通过不等于手机实际连跳已确认；本轮 ROM0 不增加指令。旧 Kanto/Johto 跳崖规则、已有失败史与 Safari 旧错误均保留。

## SRF-5.62.224｜跨分支门房功能 PASS 不等于整张地图的 Field Moves 还在

- 备用分支曾实现阿鲁夫遗迹水域 48 格 Surf，合入金银主线时只复制门房 Warp、陆地碰撞与图像，漏了 `johto_union_cave_surf.asm` 的遗迹路由与徽章准入。门房行为脚本仍会 PASS；`johto_rpp_pipeline.py` 明确只输出 `REVIEW_REQUIRED` 清单，不自动导入 Field Moves。这不是脚本实际删除技能，是移植时漏带已有运行代码。
- 新增地图后必须源分支对比 Surf/Cut/Fly/Strength/Headbutt/Dig 等独立特性，并把 `DEFERRED` 与源代码运行行为互相核对；原版 WATER 按 16×16 碰撞格建掩码，绝不能把共享 `JOHTO` 的 8×8 图块 ID 一股脑变成通用水域。
- 修改位于 ROMX 的 Surf/审计不得声称解决 ROM0 空间；务必实编 ROM、看 Bank42 与 ROM0 MAP，并手机检查上水、下水和旧地图。遗迹室外跳崖仍未收口。

## RUINS-5.62.224（候选）：门房审计通过 ≠ 新室外地图可以发布

- 分支冲突：金银主线 local ID 18 已是 Route35GoldenrodGate；金币备用的遗迹门房也使用 18。必须在主线保持老 ID 不变，为 Route36RuinsGate 和 RuinsOfAlphOutside 分别登记新 local ID 19、20，并同步音乐、屋顶、Town Map、Warp 反向目标及运行时派发。
- 强制门房审计真正执行门房方向分支与 Warp、到达后步进和 Gold 独立图块来源。刻意把 Route36 碰撞派发指向错误的 `.ruinsOutside` 分支，或修改 Warp 目标、方向、步进，必须报错；不能仅统计 Warp 数量。
- 门房之外，遗迹室外 Gold 原始 HOP 包含 12 条常规合法候选及 5 条障碍/落点争议，旧 ledge 门禁故意拒绝登记未验收的运行时路径。**禁止为清除两条单测失败，删除遗迹地图的注册或关闭 ledge 审计。** 先独立核对跳崖执行器、掩码与 Gold，再申请释放。
- ROM0 预算仍紧，主线已有成功 `.map` 只证明先前 `.224`，新候选必须单独 `make red`/MAP 后报告实际余量。Python 静态 PASS 不构成链接 PASS，更不构成手机验收。

## GATE-5.62.224 正式收口：将门房事故固定成自动拒绝的运行合同

- 用户对 `.224` 终态明确反馈手机测试无异常，`224定稿.mp4` 展示满金市—门房—35号道路往返及室外/室内画面。**这只代表本次已报告的路径通过**；不把无视频逐帧证据的复杂按键、存读档和全部 NPC 写成逐项完成。
- 先前失败反复出现的根因不是缺少旧案例，而是脚本没有将**STEP_ON 与 COLLISION_ONLY 的触发时点、目的地 D_DOWN/NONE、室外两种缓冲加载路径、图块来源和 ROM0 链接**同时作为硬合同。新增 `johto_gatehouse_behavior_audit.py` 已对四座已开放门房按合同解释实际 ASM 四方向分支、实物 Warp/Gold 图块/落点及完整边界钩子；不识别的新指令直接失败。`johto_door_onboarding_audit.py` 继续阻止实际登记了 Warp 却不建合同的新城都门房。
- `.224` 不应通过修复某一个受测对象来“假全绿”；错误注入须至少包括再次启用 Route35 踏毯即传送、缺一侧自动步进、错 Warp 目标、落点撞墙、删任一地图加载路径补绘、旧北门房方向回归以及错误 Gold 图块布局。源码审计是**强制静态门禁**，不是 Game Boy CPU 模拟器。任何新 ROM 候选须编译链接并取得新的 MAP/实际运行证据。
- 用户先前 `rppred(1).map` 已显示 ROM0 总计已用 `$3fe0`（约 32 B 空余），可证某次 `.224` ROM 确实成功完成链接；但 HOME 余量仍极低，下一批扩图前应独立瘦身，不能继续向 HOME 叠加地图专用逻辑。
- **历史照录**：首版的树林残留、南出口少一步、初次链接失败、Route35 门毯误触发，以及旧测试一度 586/592 项全绿都是真实事故；不得删改这些记录制造“第一次就完全正确”的历史。


## GATE-5.62.224 二次门毯纠错：Warp 触发过早 ≠ 到达后自动走步

- 用户 `.224` 录像和后续解释明确区分：Route35 外门口 `(9/10,33)` 的地毯应能停留，左右移动不进门；应从毯子再按 DOWN 碰到 `(9/10,34)` 的墙才触发进入。旧实现将 Route35 放进 `JohtoNorthGateStepWarpAllowed` 的 `.route35SouthDoor`，即使仍按方向限制，也会在从 y32 走到 y33 时**立即** Warp。此前测试只核对方向匹配，却把“正确方向踩毯立即 Warp”当成正常合同；与用户这次明确的碰撞入门需求不符。
- 新候选**只移除 Route35 室外的 step-on 分支**，保留站在 Warp 上时的 `wd736.2`、`ExtraWarpCheck` 精确朝向判定、`JohtoGateCollisionDirectionAllowed` 和 y34 的阻挡 mask。原 Route34/桐树林北门房的已验收 step-on 入口、室内南口及北口、各目的地 `D_DOWN` 到达自动走步都不改；不添加 ROM0 指令，也不让其它建筑/自然公园入口开放。
- 原测试漏检必须留史：更新 `johto_route35_goldenrod_gate_audit.py` 和负向测试，强制拒绝未来给 Route35 重新加入即踏触发、错误放开 y34 碰撞、反转 collision-only 方向；静态脚本不能代替实机验证。尤其不要把“进门后往下走一步”与“走上地毯就进入”混为一谈。

## HOME-5.62.224：ROM0 不允许靠 Python 全绿“通过”链接验收

- `.223` 参考 MAP 中 ROM0 剩余空间仅数十字节，`.224` 新门房的 ROM0 地图判定和三条边界 `callba` 在两个装载路径重复增加占用；用户真实 `rgblink` 报 `Unable to place "Home Copy Data" (ROM0 section) anywhere`。该错误说明空间/装箱失败，并非 CopyData 本身的功能错误。任何源码预算必须注明不是实际链接结果。
- 两处 `LoadTileBlockMap` 后的 **Azalea 西边界、Goldenrod 北边界、Route35 南边界** 本来都在 `main.asm` 固定 Bank `$43`，可用一条 `callba PatchJohtoMapBordersAfterBlockLoad` 调入同 Bank 内 3 次普通直接调用，保留顺序；`callba` 宏为 6 字节，两条路径共减少 4 个调用即 ROM0 24 B，新增 ROMX 9 B。屋顶更新的位置/VRAM 时序保持原样。静态覆盖包括两条路径、函数顺序、Bank 共址和故障注入，但必须另做真实构建和运行验收。
- 未来新门房严禁仅因静态单测通过就向用户保证 ROM 可编译。取得成功 `.map` 后单独瘦身 HOME：每步比较 Bank 0 连续余量、浮动段地址、调用寄存器约定，并复测关东老门房/城都门房、Fly、存读档、室外快速连接；避开 `CanWalkOntoTile` 不带 Bank 的碰撞表等 ROM0 固定资源。不要在当前门房尚待实机时大迁移。

## GATE-5.62.224 视频纠错：门房 Warp 正确不等于两侧显示、出门动作正确

- **上一候选真实回归**：用户 `.224` 手机视频显示 35 号道路南端下方一整条树林，而 Gold 原版不是。原 `PatchJohtoGoldenrodNorthBorder` 只修了城市北侧，忽略 Gold Route35 `connection south, GoldenrodCity, ... -5` 的反向可视数据。RPP 此阶段继续使用门房 Warp，不应为了去掉树把尚未审核的整个地图边缘开放；只补 Route35 的 WRAM 南侧 3 行显示缓存，且两条 `LoadTileBlockMap` 入口都需要调用补绘。
- **不同图块集不能同编号乱拷**：Route35 为 `JOHTO`、城市为 `JOHTO_MODERN`，两套 `.bst` 里同一个块 ID 可能是不同建筑/树林。跨地图显示预览优先找完全相同的 4×4 块，无法映射的城市 $06 地面和 $67 建筑边采用经标注的安全近似值；必须用新 ROM 实机检查，源码 PASS 不能证明像素/色阶相同。
- **自动向下一格以目的地而非入口判断**：首版只给到达门房上缘 y0 加 `D_DOWN`，却把返回满金市 `(19,1)` 错记为 `NONE`。已验收桐树林北门房从门房抵达森林后也使用目的地 `D_DOWN`。此次照样通过 `GetJohtoWarpArrivalStep → PlayerStepOutFromDoor` 增加满金目的地一步，不允许通过全局执行器改所有门房。
- **审计自己的盲点必须留史**：首版 586/586 项 Python 测试全绿却未检查这两种情形。本轮新增真实 Gold 南向边界、tile crosswalk、两个地图加载路径、WRAM 偏移、目的地 `(19,1)` 且落点可走的强制测试，并故意删除/反向变更证明 fail-closed。测试阶段功能与脚本保持一份补丁，不要求提前做两次 Git 提交，也不能称已手机验收。

## GATE-5.62.224（候选）：Route35 ↔ 满金市门房，防止单格入口误复制与注册表漏项

- **Gold 双口合流是设计，不是数据丢失**：Route35 `(9,33)/(10,33)` 分别进门房北侧 `(4,0)/(5,0)`；门房南侧 `(4,7)/(5,7)` 都应回到 GoldenrodCity 唯一北门 `(19,1)`。RPP Warp dest slot 是 **0-based**，不同来源不能强行假定双口对双口。
- **同一个已验收门房执行器可以复用，不代表只登记 Warp 表就够**：需要精确 Region + local ID、朝向、室内地面 collision mask、到达后单步策略；门房北侧 DOWN 一步，南侧不能猜测向上一步。新 local ID `18` 必须同步 Town Map indices/entries、两套屋顶组表（室内 `$ff`）、原生 GSC 音乐、mapheader/bank/alias、门房 onboarding 登记与负向测试。
- **旧测试写死 18 张地图不等于门房不能上线**：必须修正旧 fixture 中的扩展目标 ID 和带宽表的尾项，再通过真实 Gold 源资料核对；不能跳过旧测试掩盖冲突。公共遮罩审计对复用 Gate caller 的新增 local ID 也要逐分支解释，不能仅查图块数量。
- **验收边界**：`.224` 目前仅源码与静态对照通过，手机进出两 Lane、连续反向、关东旧门房颜色、存读档和 ROM Bank MAP 尚未验收。`SafariZoneBeta` 为既存独立错误，保留原审计不屏蔽。详见 `docs/JOHTO_ROUTE35_GOLDENROD_GATE_224.md`。

## ILEX-5.62.223｜跨分支引入 Route35/36 与连接可见缓冲：防复发要点

- **保留金银主线**：以已确认的 `.217 / ccd944b3` 为基线移植金币 `.223 / 6678cf4f`，金币的历史测试数 534/连接数 20 不等于当前合并态。满金 local ID 15 必须不变；36、35 号道路分别用 16、17；屋顶表与银行配对、112 条有向跳崖合同继续有效。
- **三种独立问题**：36 号路与桔梗市跨 Bank 曾造成错图，必须保持相同 `JOHTO_ROM_BANK`；Route30→吉花市旧宏错误复制 15 列，Gold 合法连接只复制 10 列；Route35→36 和 Route32→桔梗市地理重叠 10 列，但可达出口能看到右侧额外 3 列，必须填真实 Gold 可见预览缓存。显示预览加宽不等于人物可以穿越额外列。
- **强制真实门禁**：原 `johto_rpp_connection_guard.py --all-active` 必须从实际 Header 自动枚举所有 22 条连接；在统一审计运行测试之前检查 Gold 偏移、条带源/WRAM、同 Bank、入口 fence、可达位置与北向可见列，失败即阻断。不得只用检查器合成单测冒充真实地图全部验证。新地图必须补登记并增加故障注入。
- **边界不可夸大**：当前可达视野专项集中在北向右侧的窄图→宽图；其它朝向、镜头与 Warp 并无永久保证。Gold `SafariZoneBeta` 是用户要求本轮不处理的历史独立失败，不关掉检查；当前静态单测 574 PASS 和 22 条连接 PASS 不等于合并后 ROM/实机验收，Bank MAP 尚无。
- **历史资料保留但不复活旧状态**：金币分支早期“森林跳崖禁用”“Route35 尚未连接”、以及两笔功能/审计提交的说明，只反映对应原分支阶段。金银 `.217` 跳崖已通过用户手机测试，不得在新工具、TODO 或收口文档中再次写成当前禁用。相反，旧 `.205～.209` 失败证据必须保留供后人理解错误。

> 以下 `.217`、`.216` 等均是金银主线历史阶段，早期待办和“未接入”表述不代表整合后的现况。

## ILEX-5.62.217｜跳崖终于收口：两格落点≠输入队列；静态计数全绿也可能漏跳

- **共享执行器而非森林特例**：桐树林 Gold 10 条（8 个起跳格，含多方向 `HOP_DOWN_LEFT/RIGHT`）与普通跳崖同样是「起跳 → 跨第一格崖 → 第二格落地」。原 RPP 队列 `wSimulatedJoypadStatesIndex=$2` 不是“最终实际走三格”的证据；`.205～.208` 失败后曾误将树林队列减一，并在 `.209` 禁用入口。`.217` 复用 `HandleLedges → .checkPairs → .foundMatch`，仅保留树林图块配对表及 B 键跳跃保护。用户确认所有树林跳崖已手机测试无异常；旧失败文档保留用于定位历史，而不作为当前禁用状态。
- **桧皮镇标牌旁漏跳的根因**：Gold 起跳 `(10,6)`、墙 `(10,7)`、正确落点 `(10,8)`，而 `(10,9)` 又是墙。旧 Gold 转换器误把落点以后的**第三格**也必须能走当成条件，静默删除合法 HOP；别把障碍之后的额外一格与真正的第二格落点混淆。`.217` 精确恢复该方向，不改公共移动器、墙掩码和其它地图行为；用户已手机复测。
- **只比总数会掩盖错位**：旧 Route31 宽度误写 10（实际 20），数量仍能“恰好 14”。通用 `ledge_regression_audit.py` 必须从完整 Gold 原版逐格按真实长宽解码；校验全部已开放 Johto Gold 112 条有向跳跃动作与运行时表**集合相等**，检查图块配对/城市地图派发、新地图登记，使用删除坐标、改方向、破坏 Route31 配对、改派发等负向测试。无 Gold 原版数据立即 FAIL；不能只按数量或已有表反查自己。
- **证据范围与回归维护**：`.217` 视频及用户明确反馈支持树林全路线、桧皮镇标牌位置和关东已选路线的游戏端验收；静态 112/112 是源码覆盖，不等于 112 条都逐条手机录制。新增城都户外 Gold HOP 地图必须继续自动审计、实际抽测一处多方向和第三格墙/树、长按 B 与方向键、至少一处旧关东路径。`SafariZoneBeta` 是允许忽略的独立历史门禁 FAIL，不得为凑 PASS 删除测试。官方 ROM 链接/空间及未覆盖输入时序不能冒认。
- **提交纪律**：在用户确认 Git HEAD/已应用补丁之前，不把上传导出 `79d64d41` 自动当作本机现状。纯收口保持 `ILEX-5.62.217`，有效汇编仅清理本轮候选备注不改指令；先功能 `fix(move)`，后脚本/三件套 `test(tool)`，用经过正反向字节/权限校验的工具屏蔽补丁隔离暂存；不重写 `.205～.209` 失败历史。

## ILEX-5.62.216｜有脚本时必须按反向补丁分两次提交（P19 正式收口）

- **两次提交不可混交**：以原始 `.215` 干净 HEAD 为 Git 实际基线。第一笔 `feat(johto)` 只收地图/引擎/资源等运行时功能；第二笔 `test(tool)` 收**整个本轮尚未提交的** `tools/`、测试、工具配置、`TODO.md`、本踩坑记录、专项 `docs/` 以及项目根目录 `commit-message.txt`。不能只排除最后新增的一两个脚本，而遗漏此前几轮累计工具差异。
- **反向补丁要独立交付**：工作树达到本轮最终 `.216` 状态后，在真实完整目录执行 `git apply --check <第二笔反向屏蔽补丁>`，再 `git apply <第二笔反向屏蔽补丁>`；这会把第二笔全部内容**暂时还原到已提交 .215 基线**，保留第一笔运行时差异。先核对 `git status` 与 staged 文件，提交 `feat(johto)`。
- **第一笔提交后撤销屏蔽**：执行 `git apply --reverse --check <第二笔反向屏蔽补丁>` 和 `git apply --reverse <第二笔反向屏蔽补丁>`，恢复第二笔脚本和文档到最终版；核对差异后再单独提交 `test(tool)`。不能把屏蔽补丁的应用称作永久删除工具，也不能把补丁作者临时 Git 验证提交 Hash 冒充用户仓库 Commit。
- **校验要求**：反向屏蔽以及随后反向恢复均需完整工程执行 `git apply --check`、实际 apply、SHA-256 字节/可执行权限恢复；还要验证完成两次本地模拟提交的最终文件等于目标终态。此前 P19C 基线错用已修改目录的事故不得重犯。原始工程有额外手工改动或 HEAD 不同则先停止核对，不加 `--reject` 硬打补丁。

## ILEX-5.62.216｜城都道路屋顶色防回归：转换数据正确≠游戏运行时正确（已手机视觉巡检）

- 本项目 `johto_rpp_pipeline.py` 转换出的 Gold `.blk`、`JOHTO_MODERN` 源图像与 tilepal 标签没有证据显示转换错误。真正遗漏的是 Gold `data/maps/roofs.asm` 根据 **mapgroup** 选择 9 个屋顶图块，`gfx/tilesets/roofs.pal` 按 **mapgroup** 选择屋顶 RGB5；城镇和同组道路必须一致。P19C 只对满金市局部 ID 生效，导致 Route34 的房屋仍绿；P19D 才按全部已开放 11 张室外地图恢复原版色与图案。
- **不可**仅用 `wCurMap == $FC` 判断具体城市；必须结合 Johto region + local ID 反查 Gold mapgroup。两处 local ID 表（`color/loadpalettes.asm` 和 `engine/overworld/johto_goldenrod_roof_gfx.asm`）及 `NUM_JOHTO_MAPS` 数量必须吻合，不得给新道路默认继承绿色屋顶。新地图 full-load 与 seamless connection 两条素材装载路径都需要覆盖。
- 新工具 `tools/johto_roof_reference_audit.py` 从当前 Gold `data/maps/maps.asm` 分组注册、`roofs.asm` 屋顶图案、`roofs.pal` 精确白天 RGB5、Gold PNG 到 RPP 的实际 2bpp 与两张本地组表逐项验证；当新增室外本地地图遗漏一项时 fail-closed。已经加入统一 Gold 发布审计，并在地图转换入口增加单独屋顶复核项。`tools/tests/test_johto_roof_reference_audit.py` 负例针对新增地图漏登记、Route34 错组、RGB 变化、屋顶像素损坏和切图钩子删除；禁止删测试换全绿。
- 用户视频 `216房屋颜色.mp4` 和用户巡检反馈只支持当时已显示屋顶外观认可；原版 Gold **昼间** RGB、像素与注册表匹配为静态证据，不代表晨/夜动态光照规则、全部地图边缘、ROM 编译或 Bank 已验收。新增 P19/P19C/P19D 不得顺手修改旧关东颜色、W2/VRAM 时序或既有 Cut/Surf/Fly/骑行。
- **交付教训**：早期 P19C 误把已被热修改过的开发树当原始 `.216` 做反向补丁测试，用户真实工程无法应用。未来增量补丁必须从上轮**真实可复现**的完整 Worktree 重建；全量以原始上传 ZIP 文件字节为准；两者各自正向、反向并核对二进制/文件权限，不能只在干净的试验目录自我验证。

## ILEX-5.62.215｜P18 北门房及未来所有 Gold Gate 的防复发规则（当前有效）

- **同为竖向门房，Warp 触发与落点自动步行也不可混为一谈**：`.213` 踏门后仍需补按方向是遗漏 `PlayerStepOutFromDoor` 目的地规则；`.214` 把 `D_UP/D_DOWN` 全部放开又产生用户不接受的双向自动行走。最终 `.215` **向上抵达不追加步行**，**向下抵达**仅按精确目标增加一步。执行仍复用 `CheckWarpsNoCollisionLoop`、`GetJohtoWarpArrivalStep`、`PlayerStepOutFromDoor`，不新增通用“所有竖门房自动走”的引擎。
- **按目的地独立验两端**：Route34 北门房顶部 `(4/5,0)` 目的地补 `D_DOWN`，桐树林单格北口 `(1,5)` 目的地补 `D_DOWN`；向上到门房南端 `(4/5,7)` 和 Route34 `(13/14,37)` 不补步。严格检查方向、来源三元组、站位、一步后的 Gold 地形、持续按方向键与 B、立刻反向；不能拿 `.213` 和 `.214` 候选文档替代最终状态。
- **接入原则是复用历史工具**：`johto_indoor_pipeline.py`、`johto_indoor_tiles_converter.py` 负责原版图块及 compact 映射；原 `JOHTO_GATE` 旧 4 组区块可复用、扩 5 组，Route34 继续用 `JOHTO_MODERN`；按真实 Gold source→compact、CGB 色值、两条地图加载路径审计，禁止重写门房转换器、放开关东碰撞或改全局 palette。
- **24 座门房普查不是通用自动行动推断**：Gold `warp_event` 只能证明位置和目标，不能直接决定 RPP `PlayerStepOutFromDoor` 是否补一步。现有 `johto_warp_reference_profiles.py --inventory-gold-gates` 只读列出 11 东西、12 南北、1 多出口 Gate，其中 11 个尚未登记的城都候选。`tools/johto_door_contracts.json` 的每个 `GATE_INDOOR` 必填按门侧独立的 `arrival_step_review`，缺项/无依据由 `johto_door_onboarding_audit.py` 强制 FAIL。两格汇一格、多出口、剧情（自行车/捕虫大会/火箭队）要先标专用异常，不能强行当普通一一对应门房。
- **实机与测试边界**：玩家对 `.215` 北门房往返和道路通行反馈正常；`.213`、`.214` 两轮失效是实际反例。源码 508 项（功能候选）/513 项（含门房普查）通过并不证明 ROM 构建或所有门房可玩；旧 `SafariZoneBeta` Gold 全量图形窗口问题仍属独立未解项。保留 `ILEX-LEDGE-001` 森林跳崖禁用/未修复；剧情开发不在当前扩图交付内。
- **提交规则**：基线 `287522e5` (`ILEX-5.62.212`)，最终功能版 `ILEX-5.62.215`。`feat(johto)` 先提交功能与地图资源，`test(tool)` 后提交脚本、审计、文档和三件套；在 Git 确认前仍属未提交。代码段内本轮 P18 实质修改备注统一 `.215`，不修改已经提交的无关旧注释。

## ILEX-5.62.212｜桐树林地图与 Cut 的长期维护约定（已收口）

- **切分项目阶段**：P17 当前只扩展 Gold 桐树林地图与地形技能，不接入大葱鸭追逐、HM01 发放或城都徽章剧情。当时后续开发顺序为北口门房 → Route34 → 后续地图（已由上方 `.215` 记录取代）；新门房必须先遵守 `docs/JOHTO_GATEHOUSE_READ_FIRST.md`。不能用“剧情没做”否决本阶段的 Cut 可用性。
- **地形图块与技能授权是两层约束**：Gold 原版桐树林 `(8,25)` `CUT_TREE` 位于 32×32 metatile `$0f` 左下象限；`(9,25)` 是 `HEADBUTT_TREE`。复用 RPP `Cut2/AnimCut` 时只替换左下四块 8×8 图形成 `$2d`，再由 live block 和 Gold 阻挡 mask 配合放行；不能把整个 32×32 block 清空。A 键和宝可梦菜单都用 `JohtoCutBadgeAllowed`：仅精确 JOHTO Ilex Forest 免 Hive Badge、队伍仍须会 Cut；关东保留 Cascade Badge。离图恢复原树，不创设额外剧情/存档标志。
- **图形相同≠颜色相同**：关东 Cut 动画的四块 8×8 树图与 Gold 桐树林树图像素一致，但 Cut OBJ palette 6 与 BG palette 互不等同。新 `JOHTO_ILEX_FOREST` 必须加入 `LoadOverworldSpritePalettes` 的 `SpritePalettesNite` 分支，不能改全局 OBJ palette 6；用户 `.212` 视频与反馈确认突兀亮绿色已改善。菜单 Cut、更多 OBJ 组合仍按独立场景核对。
- **禁止用静态模型掩盖失败 HOP**：`.205～.208` 的 Forest 两格 HOP 跳崖均未获手机通过。RPP 旧三格跳跃与 Gold 原版 `STEP_LEDGE` 不同，不能靠缩减模拟步数或动画等待模型证明真实移动成功。最终 `HandleLedges:.ilexForest` 立即返回并保持 Gold 墙壁 mask，编号 `ILEX-LEDGE-001` 保留 DEFERRED；原关东/Route29～32 执行器不动。以后重启必须 CPU/RAM 逐帧和其它地图回归，不能把 `95` 静态匹配当作实机通过。
- **收口纪律与证据分层**：本轮最近已确认 HEAD 为 `057e9fbf / GATE-5.62.202`，最终候选 `ILEX-5.62.212`；中间 `.203～.211` 仅为未提交开发轨迹，正式修改段版本注释统一 `.212`，旧历史证据仍保留在 `docs/`。用户 `.212` 视频支持 A 键动画与底色改善，不自动代表菜单 Cut、所有碰撞/Warp/关东回归逐项通过；AI 不编译/链接、不替用户 Git Commit/Push。完整提交与后续界限见 `docs/ILEX_212_CLOSEOUT_AND_ROUTE34_HANDOVER.md`。


## 门房开发永久入口｜正式收口 GATE-5.62.202

**以后新增／改造任何门房，先读 `docs/JOHTO_GATEHOUSE_READ_FIRST.md`，不能只读这份踩坑记录。** 该专项文档强制列出已验收的老门房参考、两格 Warp 的站位与碰撞、立即回程、地图边框普通/快速两条路径、neutral 地点名、source→compact 的真实图块排列、实际 RGB 与关东隔离、反向审计和手机最小验收。`tools/johto_door_contracts.json` 现必须为每个室外/室内 Gate 登记必读文件，并为 `GATE_INDOOR` 登记 8 类实际执行的证明 ID，并保留手机验收状态；新门房缺项或专项手册遗失时 Gold 严格门禁 FAIL。此规则适用于今后的桐树林北口、34号道路等门房，而不只是本次南门房。

用户对 GATE-5.62.202 南门房已反馈：双格进出修复、色彩正常、半圆过亮消失；Gold 对照截图背景可接受。之前 P16D 的排序误判导致整房变绿属错误方案，已由 P16E/F 纠正。**不得以现有旧门房通过代替新门房手机验收，不得把 Gold RGB 静态一致推导成全部 ROM 链接与显示行为验证。**


## GATE-5.62.202｜半圆装饰亮纹的真正原因：Gold GREEN/BROWN 第0色未隔离

- 用户 P16E 实机验收：房间整体颜色恢复，但半圆下沿浅色竖纹仍与 Gold 原版不一致。原图块像素、tilepal 标签和 source↔compact 映射原本均正确；P16D 错乱颜色标签的处理是误修，应避免再次出现。
- 原版 `gfx/tilesets/bg_tiles.pal` 的 indoor GREEN palette[0]=(18,24,9)、BROWN palette[0]=(26,24,17)，而 RPP `color/data/map_palettes.asm` 的通用室内两组第0色都是 (30,28,26)。离线按真实 `.blk`/`.bst`/图块/颜色重建，Gold/RPP 门房画面差异仅为 GREEN 第0色666像素、BROWN 第0色24像素；原版中半圆底部是深绿色，RPP 之前呈浅色。
- 不能修改全局 `INDOOR_GREEN`/`INDOOR_BROWN`，关东已有房间也会变色。应只为 `JOHTO_GATE` 从预留 `0x28/0x29` 索引使用两组 Gold 室内色，其它 tileset（特别 `GATE`）的 palette slot 不变，palette 表仍维持64组。覆盖源颜色值、palette set 索引、关东未污染、破坏注入测试，静态通过不算用户 ROM 实机验收。

## GATE-5.62.201｜门房调色排序误判事故：禁止按已用 Gold Tile ID 排序套目标索引

- P16D 的静态调色检查 `sorted(set(Gold_tile_IDs))` 再按序枚举 compact RPP tile，**忽略了压缩图块重编号顺序**。具体 Gold tile 1→RPP 2、Gold 7→RPP 0；它把 22 项中 10 项正确 palette label 改错，让此前正常的门房地板、顶栏整体变成亮绿色。用户 P16D 手机视频证实画面异常。
- **必须从两侧 `maps/*.blk`、源 `gate_metatiles.bin`、目标 `johto_gate.bst` 的同一个 metatile/cell 恢复图块的实际双向映射**，然后核对 palette label；不得用排序、集合或位置推测顺序。强制失败注入使用 P16D 的错误排列复现，证明会被审计阻止。
- 静态像素/标签相同不代表 CGB 实机调色完全相同；新贴图必须先与旧实测画面、Gold 对照验证全房重点位置后再宣称视觉已验收。**一个审计新规则改变已有验收资源时，它本身也要接受画面回归**。修完测试应同时检查第一座共享 JOHTO_GATE 门房；本轮不修改稳定的双向 Warp、地点名修复。

## GATE-5.62.198｜重复卡门根因：代码复用不完整且测试证明了错误行为

- P16A 静态 391 PASS 后用户报告桧皮镇外侧入口踩格自动传送、两格上下走不动、门内外需要先退一步才能重新触发。原因是新增的 `JohtoAzaleaGateWarpTileCheck` 只按站位返回 carry，**违反已实测的 .157 Route15 风格碰撞入门约定**；又因原延迟 Warp 对 `JOHTO_ROUTE31_VIOLET_GATE` 只按单字节目的地图判断，新 `$FC` 门房未被涵盖。不能因 Gold 坐标对就称操作正确。
- P16B 在旧引擎 `CheckWarpsNoCollisionLoop` 中用来源三元组精确跳过两端门房 Warp 的即刻传送，只置站立位；碰撞路径在方向、来源地区、local ID 均正确时才走旧 `WarpFound2`。室外 `(2,10)/(2,11)` 虽是 Gold Warp carpet，但旧 mask 视为不可进入；特许门格互相纵向移动，不放开真正的上下墙。保留 Route31 已实测路径。
- 外观独立：Gold 原版地图和相关 metatile 正确，但 RPP 西边界统一树林 `$05`，门房紧靠左边界造成看似半屋半树林。不能改全图 border fill 解决局部外观。P16B 在 `LoadTileBlockMap` 后仅针对 `(JOHTO, Azalea local 10)` 的西侧两处屏外缓存块补绘同源屋顶 `$09` 与墙体 `$1e`，不改 `.blk` 或碰撞。静态像素预览通过，`STATIC_CANDIDATE_PHONE_PENDING`，尚未手机确认实际图像。
- 通用审计必须有**负向触发、步行方向、立刻反向、共享 `$FC` 来源 map key、垂直门格与边界视觉**的准入/留档，不能把自造的异常 Warp 检查函数“存在”当作验收通过。

## GATE-5.62.197｜Ilex 南门房两格 Warp 不可只改对象表

- 桧皮镇西门 Gold 原版有 `(2,10)/(2,11)` 两格 Warp；此前城市的碰撞掩码严格封锁所有未接建筑。单纯在对象表写 Warp 而不在精确 `(3,10)/(3,11)` 左向移动前放行，会出现「地图有 Warp，玩家却走不到」。且 Warp 站位识别曾有仅朝墙碰撞才触发的分支，新门应同时核实移动放行、精确站位 Warp 识别以及目的地别名地区/局部 ID。
- 当前 `$FC` 在多张城都地图间共享；Warp 必须带地图地区+local ID，不能把 `$FC` 用作全局唯一身份。门房东口 Gold Warp #3/#4 在 RPP 保留为 0-based slot 0/1；西口通往尚未登记的 Ilex Forest 的 Warp #1/#2 暂不写入，防止非法跳图。
- 复用已审核的 `JOHTO_GATE` 资源不代表能复用旧门房对象、内部脚本或地图 ID。新门房虽注册运行时，但**森林仍未注册**。门房 Bike、Fly、Surf、Dig 和逃洞绳与城市 outdoor 功能分开审核。
- `patches/rppred.map` 是上一次已构建版本留下的 MAP，不是这次 P16 ROM 链接结果。源审计 391 项通过后仍必须由用户 Termux 构建并在手机验证两门入口、两门出口、封闭森林西口、存读档和原 Fly；禁止把静态通过写成用户实机通过。

## ILEX-P15｜Gold 图形区块数与碰撞定义数不能假设相等

- 完整 Gold 桐树林 `forest_metatiles.bin` 是 **40 个图形区块**，但 `forest_collision.asm` 提供 **64 条碰撞定义**。原 `stage_preserved_gold_tileset` 与 `plan_gold_quadrant_collision` 都曾错误要求两表等长，新地图离线候选因此在实际开发时失败，尽管此前统一 380 项门禁全绿。应允许原版多出的碰撞定义，**但每个图形区块仍必须有碰撞项**；回归测试故意把 64 条截为 39 条，必须拒绝。
- 桧皮镇到桐树林中间是 Gold `IlexForestAzaleaGate` 门房，不是地图连接条带。它可复用现有 `JOHTO_GATE` 13/13 个像素匹配区块，但不等于能直接复用已注册的门房 ID/Warp；森林 RPP 原有 `forest` 图块集对 Gold 使用区块只有 0/39 精确映射，不可错用关东森林资源。
- 森林的 `WARP_CARPET_RIGHT`、Cut/Headbutt、水面、危险跳崖和赶鸭剧情须分开审核。Gold 本身为 CAVE 环境并使用 Union Cave 音乐，但不能据此自动把 RPP 的 Dig／逃洞绳/Surf 或 Fly 等技能对整套 tileset 开绿灯。北侧 Route34 未接入时务必维持封闭。
- 本轮仅补正通用 Gold 离线审计及 Gold 来源两端事件索引验证，不修改 RPP 运行地图或游戏版本，不宣称新地图可玩。见 `docs/JOHTO_ILEX_P15_GOLD_STAGING.md`。

## FLY-5.62.196｜新地图“全绿但漏功能”的根源和强制对照

- P12 已将桧皮镇地形与地图入口接通，但静态门禁只检查已有 Fly 野外资格/图块与既有 3 城目的地，没有以 Gold `data/maps/flypoints.asm` **反查每个已注册的新城镇** 的到访位、菜单、原版落点。365 PASS 仍可漏整项功能，属于测试覆盖空白，不等于当时的 Fly 已实现。
- 新增统一 `tools/johto_fly_destination_audit.py` 并接 `johto_map_release_audit.py` 严格发现列表；登记每张 native 城都地图时明确 Gold Fly landmark (没有为 null)，不能以 `feature_status: DEFERRED` 冒充已完成。对应原版 Fly 点的地图必须有 ALLOWED + 实际读取/写入持久位、菜单前后循环、特殊 warp 落位、地区/局部 ID 与图块恢复。未接的道路和洞穴不得强行允许。
- 新的 `$FC` 只是一条共享句柄，Fly 使用独立 `$FD` selector，只有特殊 Warp 将它变成 (JOHTO, Azalea local 10)，不能用 `$FC` 判断任何城市已到访。特殊落地切换 tileset 后必须清除屏幕偏移，不能把 `JOHTO_MODERN` 枚举值当作 X/Y 偏移。
- Fly 使用许可、目的地是否已到访、普通 Town Map 地标浏览和 Teleport/Dig/黑屏治疗点是不同逻辑。强制静态 PASS 不证明 ROM 链接容量、Continue/存档迁移的全部极端路径及用户实机效果；用户反馈 P13「看过了，没啥问题」后进行了提交收口，但没有逐项手机测试记录，仍保留最小 Fly 回归清单。
- **P13 正式收口基线教训**：有未提交 P11R/P12 的工程 ZIP，必须以其实际 Worktree 做全量补丁；不能因为 ZIP 报告 HEAD 是 `118d5e38` 就从 HEAD 制作全量。增量可针对已经安装的 P13 候选，二者最终字节内容及文件模式必须一致。

## TOOL-LAYOUT-P10｜正式地图运行资源不得藏在工具阶段暂存目录

- `tools/` 放转换、审计、生成器与配置；`tools/tests/` 放反向测试；`maps/` 放地图相关运行时数据，`gfx/` 放图像/图块，`engine/` 放汇编执行逻辑。
- 以前 Route33 的54字节掩码被 ASM `INCBIN` 引用却存于 `tools/johto_route33_staging/geometry190/`。已迁到 `maps/JohtoRoute33.blocked_mask.bin`，不能误删或恢复旧路径；改动需同时核查 ASM 的引用。
- 地图碰撞和跳崖转换应复用 `johto_indoor_collision_adapter.py`，地图审核差异存在 `tools/johto_gold_geometry_contracts.json`，不得再按地图编号复制 `geometryXXX.py` 算法。
- 移动/删除测试模块时同步调整 `johto_map_release_audit.py` 的强制发现清单及最少负向测试；不要因为删了测试让门禁假绿。
- 这属于源文件依赖关系及静态审计变更，不代表编译/链接已验证，也不改变游戏版本 `MAP-5.62.194`。

## MAP-5.62.193｜小地图转换后必须检查草地标记和 Fly 野外许可

- `.192` 的 Route33 `JOHTO_MODERN` 虽标记 `OUTDOOR`，却在 `data/tileset_headers.asm` 把草地 ID 设成 `$FF`，而 Gold Route33 的 12 个 `TALL_GRASS` 16×16 象限四张 8×8 图像均为 `$04`。RPP `UpdatePlayerSprite` / `UpdateNPCSprite` 原本按 `wGrassTile` 设置下半身 OAM 优先级；只要登记 `$04` 就能复用，**不必重画图像或另造草地特效**。这不会自动导入野怪概率/遭遇数据。
- RPP `.fly` 使用者判断只识别 `JOHTO`/关东 `OVERWORLD`，遗漏新 `JOHTO_MODERN`。为独立 Johto 室外 tileset 新增精确分支即可，不能把 `CheckIfInOutsideMap` 全局宽放，更不能把所有 Johto 地标注册为可飞目的地。飞空许可、目的地到访和两地区恢复是独立问题。
- 下次接新的 Gold 地图先运行现成 pipeline，并检查最低限度运行时清单：可走/阻挡、草地精灵遮挡及野怪标志、Fly 使用许可与 Fly 目的地、骑行、Surf、Warp 正反、门口落点、音乐及 Continue。**地图规模小不代表可省略这些既有功能对照。**

## MAP-5.62.192｜Route33 第二洞口必须同时核对 Warp 配对和技能返程

- 不能因存在 Route33 运行时地图就默认联合洞穴南口能出：`.191` 曾在 `JohtoUnionCave1FObject` 留 1 个 Warp、`JohtoRoute33Object` 留 0 个 Warp，而静态门禁把「保持关闭」当正确，用户实测实际出不了洞。**开放双向入口要先核对 Gold Warp 坐标与 RPP 重编号后的索引**，再核对落点、方向、反向出入和 Dig／逃洞绳回去的来源。
- Gold Union Cave1F 第三个原版 Warp `(17,31)` 与 Route33 第一个 Warp `(11,9)` 对应，RPP 仅启用原版洞穴 Warp 3、4，因而 RPP 目标索引为南口 1、北口 0；不可照搬 Gold 原始索引 2、3，也不可全局开放 `$FC`。
- Gold `JOHTO_MODERN` CAVE 碰撞 `(11,9)` 为不可走，进入前必须在精确 `(11,10)` 朝北放行，并在 Warp 格识别精确 native 位置。洞内返回 Route33 的模拟步仅作用在 `(11,9)` 且来自洞穴 `$FC`，其他普通 Warp 不要多走一步；洞内出口仍为站在 Warp 格朝下碰撞，不能改成通用地板踩格 Warp。
- 动态 Dig／逃洞绳入口来源必须在 `$FE` 的 `StoreNativeWarpTarget` 改写 `wCurLocalMapID` **之前**捕获。只在核对来源 Warp index+目的地图 key 后写已有 `wLastMap/wLastRegion/wLastLocalMapID` 三元组；不借 `wLastBlackoutMap`，不改关东黑屏。当前特例是一侧道路一个入口，并不存储 Gold 任意 Warp 编号。
- 门禁必须在旧测试仍然执行的前提下，把已过时的封锁断言升级为双向合同，同时新增负向用例；静态门禁仍不是 ROM 编译和手机验收。


## DIG-5.62.188｜单入口洞穴 Dig／逃洞绳的安全返回与未来多入口陷阱（已用户验收）

- **当前真实能力界限**：只允许 Johto `Union Cave 1F` 的 Dig／逃洞绳专用路径，安全落点是 `Route32 (X=6,Y=80)`。玩家确认实际能从洞内回洞口，其他测试反馈未列出逐项记录；Gold/RPP 双源码严格门禁 `298 PASS / 0 skip`。不可因为用户验收一个入口就写成 Gold 动态返回已整体移植。
- **Gold 与当前项目差异**：Gold 原版用 `wDigWarpNumber/wDigMapGroup/wDigMapNumber` 记住室外进入室内的来源 Warp；RPP 关东旧 Dig／逃洞绳使用 `wLastBlackoutMap` 治疗点。本阶段选择固定返回 Route32，是**当前只有一个开放入口**的可验证特例，刻意不更改关东旧行为与 SRAM/WRAM 布局。黑屏返回必须继续走治疗点，不得错误复用 Dig 落点。
- **第二入口是升级门槛**：未来开 `Route33`、`Union Cave B1F` 或新增洞穴入口时，`JOHTO_UNION_CAVE_1F_LOCAL_ID` 的单点资格与固定 `FLYWARP_DATA ...80,6` 必须先评估并迁移至地区/局部 ID/来源 Warp 的动态保存机制。新洞口双向 Warp、Continue、旧档、黑屏后恢复、靠岸、坐标／方向、音乐及防回洞循环要分别审查和实机抽测；不得直接把 Route33 登记成可进入便宣布逃洞完成。
- **固定 Bank 空间仍须真实 MAP**：`.188` 在 `engine/special_warps.asm` 使用 `jp c`（分支距离不能用短 `jr`）及 `ld a,0` 到 `xor a` 的等价替换；这些属于已验收候选的实际源码。新增专用回程在 Johto ROMX，原有紧张 bank `$01`／`$03` 仍必须凭用户构建 MAP／链接输出确认；AI 没有编译。后续修其他区域，别把全 `JOHTO_UNION_CAVE` tileset 全局放入 `EscapeRopeTilesets`，也不要把固定入口或治疗点混作通用返回。
- **版本与验收分离**：`DIG-5.62.188` 的静态 298 项通过不等于全存档／全路径／空间安全；用户反馈支持当前已测试场景的 `USER_ACCEPTED`。正式收口不应顺手改变关东 Teleport／黑屏、已验收 Surf、骑行、门房与其它未开放入口；功能和工具提交仍由用户分开执行。

## SRF-5.62.187｜城都室外河流与洞穴 Surf 的共用图块陷阱（阶段验收收口）
- **用户验收与证据界限**：`.186` 联合洞穴冲浪已报告可用，`.187` 32号道路河流冲浪经用户报告“测过了，没问题”；这是已报告场景的手机验收，不意味着 342 个水格全部逐格、所有上下岸方向、关东徽章回归或 ROM 空间已经重新独立验证。上一轮 289 项严格静态审计与实机证据分开记录。
- **反复踩坑的防线**：同一水面合同必须覆盖 facing Surf、队伍／道具与游泳移动三个入口；`WaterTilesets`、`WaterTilesets2` 和公共碰撞规则不能为修一个地图而全局放行 JOHTO 图块集。两份 JSON 合同必须随工具提交纳入 Git，防止下一次导出时门禁缺文件。

- 原 RPP Surf 三入口分别涉及 `IsSurfTile`、`IsNextTileShoreOrWater`、`CollisionCheckOnWater`，缺少其中任意一个会出现“能下水但不能游／不能上岸”。新地图务必检查全部入口和反向负例。
- Gold Route32 278 个 WATER 是**16×16 碰撞象限**，RPP 绘图 ID 会与墙体共享，不能直接放开 `JOHTO` 图块集的全局水表。审核用 Gold 原数据重新算出水格；位图应同时检查 Y×3 的 16 位计算及越界掩码。
- 联合洞穴 1F 的 64 格和 32号道路的 278 格都属于已审计阶段，不代表其他 `JOHTO` 地图可冲浪。剧情徽章未接入前两图暂免城都徽章，关东旧徽章规则不应被顺便修改。
- 本阶段只有源码及负例审计；实际 ROM 编译、入水／上岸和边界需用户实测。测试通过不得直接记为已验收。

### RBK-5.62.184：地标／骑行／审计双提交的防重犯规则

- **普通地图不等于 Fly**：Gold `data/maps/landmarks.asm` 的 45 个城都地标自始可被普通 Town Map 浏览，不要求到访；金银地标宏将 `(X,Y)` 加 `(8,16)`，RPP 则用 `db Y,X` 存储。先逐项核对名称、顺序、坐标与独立地理底图，再测试玩家标记/浏览光标；不要把道路、洞穴列入 Fly 解锁。未开放路线出现在普通地图上不等于允许进入。
- **空间重叠不能直接判错**：部分原版地标位于相邻建筑/道路，其光标区域可能相近，但当前 45 组最终坐标均不重复。旧审计只验证已接入地图数量会漏掉未开放地点；新增地标必须将 Gold 全 45 项和底图地理图块一起审计。本轮通过静态 Gold 对照；用户短视频显示多个地点浏览正常，不代表每一个位置都逐帧实测。
- **新 Tileset 同时查骑行和脱车**：`JOHTO_UNION_CAVE` 新增到 `BikeRidingTilesets`，让洞内骑行可用；门房原本的下车规则继续生效，用户已实测两者正常。不要因为洞穴允许骑车而放开所有门房或扩展 Surf/Dig/Escape Rope；三者仍需先保证双地区返回地点及音乐恢复正确。
- **漏检不能靠堆计数解决**：`.178` 基线会漏检被封死的入口分支及等长 Header 错指；后续测试加入独立期望、受限控制流检查与错误注入。统一 `johto-map-audit` 要强制 Gold、0 skipped、固定关键模块/用例清单；撤掉整份测试仍通过属于门禁失败。`tools/JOHTO_MAP_AUDIT_README.md` 的版本示例必须随有效基线更新，禁止冻结为历史 `.179` 后误导使用者。
- **选项菜单汇编标签问题**：`.182` 曾出现重复 `.showPage2`，`SYS-5.62.182` 的试验性 SFX 在 `.184` 全部撤回。重复 RGBDS 局部标签审计仍保留；工具静态 PASS 不等于 RGBDS 汇编/链接 PASS。以后如重开音效专项，单独验证跨 Bank、菜单/存档布局及所有音效资源，不与新地图合开发。
- **阶段性提交**：源代码和用户手机反馈来自 `.178→.184` 连续补丁，但正式只保留当前有效行为。按功能和纯工具拆成两笔，不把撤销的 SFX 实验作为功能提交。清理三件套为 TODO、踩坑记录、独立 Git 日志；没有原仓库 `.git` 时只能准备提交材料，不制造真实 Commit Hash。

### CLN-5.62.178：未提交备注边界、过时测试与不可删的 Warp 安全机制

- **范围规则（用户明确限定）**：仅处理 `.169` 已提交基线之后、`.170～.177` 尚未提交工作中的**过时源码版本备注**；不批量擦除其他年份、旧版本、历史事故说明、测试文件名，也不修改已经提交的 `.169` 或更早功能注释。正式提交日志列出已提交基线→当前定稿版本，游戏版本字串按项目约定提升为 `CLN-5.62.178@`。
- **本轮证据**：对照 Gold `maps/Route32.asm` 的 `(6,79)`、`maps/UnionCave1F.asm` 的 `(17,3)` 和 RPP 现有表，确认当前洞口坐标已对齐；`.177` 手机录像的进/出与侧向保护已通过。Gold 地图 Warp 与 RPP 引擎触发方式不同，不能因为坐标对齐便删除关都式碰撞触发或洞外安全落位。
- **实际清理**：有效 `.asm` 中旧 `CAVE-5.62.173`、`CAVE-5.62.174`、本阶段 `WARP-5.62.177` 的*注释*改为无版本的稳定功能描述。运行时除可见版本字串外，不更改任何汇编指令、标签、数据、资源或宏。修正 `test_johto_union_cave171.py` 仍断言已被废弃的 `db 0,$FF` 的旧检查，改为验证碰撞式洞口白名单为空；当前版本断言同步。测试文件名及历史失败案例保持以便追溯。
- **不因代码行数少就擅删**：`GetJohtoWarpArrivalStep` 的方向表是扩展点，`JohtoRoute32CaveEntranceCheck`、`JohtoRoute32CaveWarpTileCheck`、洞穴向下碰撞判断与 `GetJohtoCaveMapChangeSFX` 均仍有代码调用，不属于已证实的死代码；等新增第二个洞穴样本并实测后再考虑公共配置表或移除特例。
- **回归纪律**：在 Gold ZIP 真实存在的测试环境运行，跳过不能作为成功；使用真实 `.176` ZIP 重建到 `.178` 的全量补丁，及 `.177`+地图规则的增量补丁，均验证应用、撤销、文件内容、执行权限。没有 ROM 编译、硬件 `.178` 实测、Git Commit/Push，后续继续跟进自行车、水域/冲浪、挖洞/逃洞绳、普通地图以及飞行地点能力。

## JOHTO-MAP-ONBOARDING｜每张新地图的全功能接入关卡（待各功能逐项验收）

这是一套**长期防重犯规则**，不是宣布所有城都地图与野外技能已完成。适用新城镇、道路、洞穴、门房、建筑、水域，以及**每一种新图块集**。每次开发必须先打开实际工作区与 Gold 原版源码；当前只读静态审核可以先做，但缺 Gold 对照或手机实测时，不得将图像、技能或进出行为记为已验收。

1. **建立每张地图的接入矩阵，逐项标出 `ALLOWED / FORBIDDEN / DEFERRED / NOT_APPLICABLE` 及对应 Gold 证据**：地区+本地地图 ID、Header/Bank、对象及脚本、地图连接／边界护栏、地图音乐及场景恢复、图块/动画/碰撞/调色、NPC/事件、路牌/存档、普通 Town Map、飞空、门房/洞穴 Warp，以及骑车、冲浪、砍树、怪力、撞树、挖洞、逃洞绳。没有填表≠原版禁止；未开放场景应显式登记 deferred，并设置安全阻断。
2. **地图索引不是单一登记**：新增城都局部地图，核对 `constants/region_map_constants.asm`、`data/johto_map_headers.asm`、`data/mapHeaders`/`data/mapObjects`、`engine/town_map.asm` 的 `JohtoNativeTownMapIndices` 和 `JohtoNativeTownMapEntries`、`engine/menu/options_menu.asm` 音乐、地图名称及 `JohtoNativeCollisionFence`。`REGION_NATIVE_MAP_SLOT` 是句柄，不能拿它当全球唯一 Map ID；老地图/旧存档、`$FE/$FF` 语义和表长保持不变。地图和飞空不能只凭名称“已注册”判定完成。
3. **普通 Town Map 要同时检查地标数据和静态底图**：`engine/town_map.asm` 的名称/坐标/当前地图索引与 `gfx/tilemaps/johto_map.kmp`、`gfx/town_map_johto.png` 属于不同层。新增路线、洞口、城市后，要用**真实 Gold 地标与地图画面**逐点复核，不能只加 `dw Name` 就宣布地图上已经画出道路。`data/town_map_entries.asm` 的老 Kanto/兼容映射也不能用增删条目试修。普通地图允许道路/洞穴地标；**只有城市类符合设计的地点**才考虑 Johto Fly 解锁。
4. **飞空是单独的功能合同**：对新飞行城市核对 `engine/johto_fly_town_map.asm` 目的地、解锁事件位及进城置位、`engine/fly_town_map_helpers.asm` 的 `SpecialFlyWarpData`（Y/X 顺序）、`engine/special_warps.asm` 直接切图的 tileset 恢复、旧存档及 Kanto Fly；道路和洞穴不得因出现在普通 Town Map 就自动变成可飞空地点。未接城市、空格落点和事件位冲突必须阻断。
5. **入口行为优先复用关东共享机制，分开审核四层**：①地图对象 Warp 的起点/目标/方向，②碰撞与 `DoorTileIDPointers` / `WarpTileIDPointers`，③到达落点及 `PlayerStepOutFromDoor` 模拟按键，④声音及地图场景。胜利之路、已验收 31 号道路门房是回归样板。不得为每个新山洞再复制一套“站上去就传送/自动多迈一步”的坐标补丁；也不得全局删除原生门房出门步。至少测试进、出、立即反向、侧向擦过、连走、Continue、音效。`.177` 联合洞穴进出已获用户手机反馈修复，不能由此推定所有洞穴通用。
6. **新图块集必须审核各能力表，不能只登记 `DungeonTilesets`**：骑车 `data/bike_riding_tilesets.asm` / `IsBikeRidingAllowed`；逃洞绳/挖洞 `engine/items/items.asm` 中 `EscapeRopeTilesets` / `CanUseEscapeRope`；冲浪 `engine/overworld/field_moves.asm` 中 `WaterTilesets2` / `IsSurfTile`、前方水块及 `TilePairCollisionsWater`；地形类别、`data/force_bike_surf.asm` 与骑行/冲浪 Sprite/音效。每张地图的期望许可必须对照 Gold 明确为允许或不允许；**不能为了修一个地图而把所有洞穴、室内或水面全局放行**。
7. **Field Moves 的前置条件和返回地点必须与图块许可分别验收**：当前 Surf/Cut/Strength 复用关都已有队伍招式/徽章条件，不等同城都徽章事件已适配；新增城都冲浪要查训练师能否用、岸边上下水、状态与坐骑、切图/存读档、音乐、边缘护栏和是否有有效水上碰撞。Dig/Escape Rope 与 Teleport/blackout 的返回地点及地区状态特别敏感，`engine/menu/start_sub_menus.asm` 已明确警告不要随意拓宽 `CheckIfInOutsideMap`；在双地区入口/回退已静态和实机验证前，不可仅加图块集白名单就开放，避免返回关都错误地点或卡死。
8. **把历史失误变成自动测试，不以清理代码为前提**：新增/修改图块集后扫描能力表与地图能力矩阵的漏项；新增地标后检查每个局部 ID 的 Town Map 对应、真实底图审计状态；新增城市后检查 Fly 三方数据和事件位；新增门/洞口检查 Warp 对称、碰撞、落点/模拟步与侧向负例。测试必须区分 `STATIC_PASS / GOLD_REFERENCE_PENDING / PHONE_PENDING / USER_ACCEPTED`，并在新增地图提交前阻断“未知却声称已完成”。旧 `.138` 城都骑车、`.157` 门房、`.177` 联合洞穴这三类回归应保留。
9. **顺序与提交纪律**：先接功能→各自源码与手机回归→再考虑共享化、重复代码与 ROM 空间优化→用户确认后再做 TODO、开发踩坑记录、Git 提交日志“三件套”正式收口。不可把未验收的 Field Moves、未来地图或工具测试写成已完成，不擅自编译 ROM、Commit/Push；每个正式功能补丁独立验证增量/全量应用撤销和文件权限。

**截至 `WARP-5.62.177` 的专门待核对项目（不是许可声明）**：`JOHTO_UNION_CAVE` 已在 `DungeonTilesets`，但不在 `BikeRidingTilesets`、`EscapeRopeTilesets`、`WaterTilesets2`；联合洞穴的水面/骑车、逃洞绳、挖洞必须按原版行为与双地区返回链路分别论证。普通 Johto Town Map 已有 Route 29～32、Union Cave 地标索引，但静态背景图的道路形状/地标匹配仍需对照原版复核；城都 Fly 当前为若叶镇、吉花市、桔梗市三个城市。**这些项目没有随本文档自动修复，旧许可和地图显示保持原状。**

### WARP-5.62.177：联合洞穴定稿边界与中间版本备注清理纪律

- **当前有效功能与证据等级**：联合洞穴1F双向洞口在用户 `.177` 录像中可正常进、出、再次进入；不强制洞内 `D_UP`，朝出口方向碰撞出洞，侧向路过不触发。与 Route31 门房、关东胜利之路共享的 Warp 处理优先复用；现存针对 Route32/Union Cave 的坐标适配不等于所有洞穴都自动获得通用支持。仅限上述手机实测范围，不扩大到旧档、其余楼层、Field Moves 和全部关东地图回归。
- **当前不能误删的功能**：保留 Route32 洞外安全迈步、洞口碰撞方向/站位、已审核入口与进出音效；洞内不能恢复 `.175/.176` 的自动 `D_UP` 或踩格侧向误触发。运行时代码删除必须另行实证；本次 `.178` 只做有效备注与旧断言清理，不更改已验收的 Warp 汇编指令。
- **正式定稿与版本备注**：`RPP_PROJECT_CONTEXT/03_PROJECT_REQUIREMENTS.txt` 规定增量开发不反复改源码版本注释，游戏内有效版本必须可见；正式提交日志写明有效起始→最终版本，不能把 `.171～.176` 试验节点当作正式代码版本。最终有效源码中若有已过时中间版标签（已发现 `CAVE-5.62.173`、`CAVE-5.62.174`），已在 `.178` 限定范围内替换为稳定说明；有历史价值的 TODO/踩坑文档及 Git 版本沿革不应被抹除。
- **本次三件套边界**：TODO、踩坑、障碍登记和独立提交日志只记录已验收、未完成与提交范围；当时只提交文档，不改变 `.177` 的地图与游戏行为；随后 `.178` 已另行清理未提交备注和过时断言。`.170` 地区编号扩容与洞穴/入口是不同的逻辑提交，不能用一次 `git add -A` 混交。截至该历史文档草案时缺 Gold；`.178` 已获得 Gold 完整 ZIP 并重新执行静态验证，不等于 ROM 构建或手机验收。

### MUS-5.62.163：第三阶段音乐防回归工具的审计边界

- 七张现有城都地图（门房算一张）的 RBY/GSC 对应必须使用**独立期望表**核对，不能只数 `JohtoSceneGSCMap` 条目或检查音乐常量是否合法；关键 `MUSIC_GBP_GSC_*` 必须同时检查 `tbp Music_*` 指针身份。
- 审计 `PlayDefaultMusicCommon` 的骑车／冲浪分支极性和 `CheckJohtoMusicSceneTransition` 的实际清零写回指令；只搜索 `wLastMusicSoundID` 字符串或标签名不能证明缓存真的清除。保留五种已复现的负向变异测试：GSC 选错合法歌曲、RBY 选错合法歌曲、骑车/冲浪分支反转、缓存写回缺失、音乐指针替换。
- 当前工具是静态、只读、**针对既有地图与已知汇编写法**的安全检查，不是 GB 汇编语义解释器。等价重构可能触发误报；新增地图或金银曲目必须同步扩展审计表。独立复审工具 15/15 通过，其他测试可能因 Gold 原始源码缺失跳过；不能将跳过写作通过。
- 用户实测通过的是已开发的普通地图选曲、随机、门房继承、设置切歌、骑车/下车和存读档；城都战斗与冲浪对应玩法尚未实现，相关音乐恢复留到玩法接入后测试。不因本轮工具补丁称 ROM 构建、所有场景声音或旧存档已全面验收。
- 该提交只改两个 `tools/` 文件、`TODO.md` 与本文件；游戏音乐与存档逻辑保持 `MUS-5.62.163`。禁止叠加不同前置状态的完整/增量补丁，不收录 `.2bpp` 构建产物。

### MUS-5.62.163：城都跨地图音乐缓存必须比较实际场景

- `wLastMusicSoundID` 记录的是初代 RBY 曲目编号；两座城都城镇可能同为 `MUSIC_CITIES1`，但金银原曲不同。不能只比较初代歌曲编号来决定是否切歌。
- `CheckJohtoMusicSceneTransition` 在载入地图音乐后根据 `LookupJohtoMapGSCMusic` 更新场景状态；仅在 GSC/GSC+C/RND 且步行、金银场景变化时刷新旧歌曲缓存。RBY/RBY+C 和相同 GSC 曲目连续地图不应无故重播；RND 只在正常播放流程抽取，不在检查函数重新随机。
- 31号道路—桔梗市门房继续沿用 `.162` 的 `GetJohtoGateMusicSourceMap`，按普通 Warp 实际来源继承入口音乐，不能退回历史 `wLastMap`。用户已实测城镇→门房→道路及反方向的音乐衔接正常；普通 RBY/GSC/RND 切换、随机、骑车/下车与存读档也已有正向反馈。
- `.163` 的静态/工具回归、独立源码复审与用户场景实测是不同证据；未在本轮完成 RGBDS ROM 编译。城都战斗结束与冲浪上岸功能尚未接入，保留第三阶段 TODO，不作为第二阶段阻断，也不得标成已实测。

### MUS-5.62.161–162：双地区场景音乐不能只根据 RBY 曲目编号或 `wLastMap` 选曲

- 关都不同地点可共享 RBY 曲目 ID，但对应的金银城都原曲不同。城都普通地图音乐应由**实际地图场景 + 现有 RBY/GSC/RND 风格**解析；C 自定义只在有对应曲目时启用，RND 从有效候选中抽取。骑车、冲浪、战斗和事件音乐保留原先优先级，不硬套普通地图映射。
- 新增地图后必须同时补 `data/map_songs.asm`，检查地图 ID 是否在表内，并断言条目总数；`.161` 补齐 `$F8～$FA`，`LoadMapHeader` 保护越界索引。仅仅在地图 Header 登记并不能保证地图歌曲表完整。
- `wLastMap` 只在被旧引擎识别的室外 Tileset 更新；城都 `JOHTO` 室外地图不一定刷新它。门房 RBY 基础曲目与 GSC 场景曲目**必须使用同一个 Warp 来源函数**，优先 `wWarpedFromWhichMap`，且未知来源要有确定回退，不得无条件改写历史 `wLastMap`。
- 静态测试和补丁正反应用≠声音验收。`.162` 复审确认已修复 `.161` 的入口侧错误，但读档、异常传送、相同 RBY ID 跨场景音乐重播、RND/C 和战斗/骑车/冲浪恢复仍需 ROM 构建与游戏内复测；不能据此声称第二阶段完成。

## TOOL-JOHTO-INDOOR-006-CLEAN：工具测试跳过不能算“提交审核通过”

- **复现条件**：原脚本 `johto_indoor_release_audit.py` 接受独立 `--gold`，但 `tools/tests/test_johto*.py` 中的 Gold 集成测试硬编码读取 `RPP/pokegold-master`。当两份源码按要求分别解压时，实际复现 `Ran 84 tests ... OK (skipped=22)`，即使跳过集成测试仍能显示 `TOOL_ONLY_READY_FOR_GIT_REVIEW`。此前“112 项测试”结论依赖临时将 Gold 提供在测试约定位置，**不能等同于独立 Gold 布局下本次审核已经全覆盖**。
- **修补边界**：仅在 `tools/` 的审核器、七个集成测试文件传递/读取环境变量 `JOHTO_GOLD_SOURCE`；审核器新增 `skipped_count` 判定，有跳过就拒绝提交闸门通过。新增负向测试覆盖“退出码为 0 但有 skip”的伪 PASS。两套真实源码分开存放时，复测 `113 tests, OK, skipped_count=0`，源码指纹前后保持不变。
- **正确解释工具报告**：`warp_graph=PASS` 仅表示静态目的地／回门编号配对，不证明门口停留、反向出入与碰撞/方向；两种 Route 15/11 参考均是同一张 Gold Gate 的对照。Gold 已使用 13 个区块、22 个 8×8 图块只能生成隔离候选；`ART_UNMAPPED`、`COLLISION_NOT_PROVEN`、`RESOURCE_BUDGET_UNVERIFIED`、`PALETTE_VRAM_UNVERIFIED`、`GAMEPLAY_NOT_TESTED` 等阻断仍在。未经实机测试不允许正式导入或标成修复完成。
- **补丁/提交范围**：用户提供的 `.156` 工作区补丁只新增 22 个 `tools/` 文件；清理修补只更新工具审核相关文件与 `TODO.md`、本文件。游戏代码、地图、Warp、飞空、图块、ROM 版本、室外安全护栏及历史 `.154/.155` 都不触碰。补丁须按真实前置状态二选一应用、正反校验，权限维持原值；不得代用户 Commit/Push。

## GT-5.62.156：飞空单独收口；禁止夹带关卡与室内试验（尚待用户实测）

- **基线纪律**：`.155` 已被用户否决，不在其上继续叠补丁；`.156` 只从完整 ZIP 的 `GT-5.62.153@` 还原并单独加入飞空功能。若本地仍是 `.155`，须先核对并回退到 `.153` 再应用 `.156`；不能将 `.155` 的门口 Warp 方向补丁、室内图块或调色资产混回。`RPP_PROJECT_CONTEXT/` 为导出资料，不应作为 Git 补丁的必要文件。
- **目的地与落点不能混淆**：普通 Town Map 有桔梗市不代表 Johto Fly 已解锁。飞空目的地必须同时具备存档事件位 `$455`、城市进入时置位、独立 Fly 菜单三项索引／已访问筛选、对应 `SpecialFlyWarpData`。Gold 原版 `spawn VIOLET_CITY, 31, 26` 为 **X=31、Y=26**；RPP `FLYWARP_DATA JOHTO_VIOLET_CITY_WIDTH, 26, 31` 为先 Y 后 X，切勿颠倒。地图 18×20 是 32×32 块维度，不可拿来直接检查 16×16 落点范围。
- **直飞图块集**：飞空特殊 Warp 不完全等同于步行切图；`engine/special_warps.asm` 必须对 Violet 选择 `JOHTO`，不能落到默认 `OVERWORLD`，也不能为了飞行改动室外地图块、Gate Warp、地图连接或全局图块配置。
- **验证不能越级**：`.156` 已有静态 Gold/RPP 落点、事件位、菜单索引和图块集检查，48 项既有工具测试及补丁正反应用检查通过；这不证明汇编链接 Bank 空间、存档旧档兼容或用户实际飞行画面。等待用户运行反馈后再决定是否把专项标为“已验收”；文档清理本身不构成验收。
- **遗留的两个独立故障**：`.153` 的关卡入口 `$40` 图块／Warp 坐标与方向可能存在误触发，室内返回落点也不稳定；室内为临时手工布局，不是 Gold 最终样式。先从 Route15 的既有门进出逻辑审查，最终室内要对照 Gold `EastWestGate` 素材，RPP 只有完全相同的资源才复用。`.154/.155` 失败方案不能当作可回归的稳定基线。这两项不随飞行专项的文档清理而关闭。
- **收口文件边界**：本轮只加 `TODO.md` 与 `RPP_DEVELOPMENT_PITFALLS.md` 两处 Git 跟踪文档及独立提交日志。`docs/JOHTO_OUTDOOR_BLOCKER_REGISTER_zh.md` 和对应 CSV 保持原样，因为无地图边界变更；以后修门时再定点更新登记并核对 Gold/RPP 原始入口与安全 Fence。保持文件权限、不编译 ROM、不代用户提交或推送。

## SRC-PREFLIGHT-151：RPP＋Gold 双源码强制准入（最高优先级）

- **每次开始修改前**，实际打开本窗口/工作区的完整 RPP 工程压缩包和 pokegold 原版参考工程压缩包（或解压出的完整源码树），核对版本、必要 map/warp/tileset/引擎文件都可读。必须两套都在、不能仅根据文件名猜测内容。
- **只要任意一套源码缺失、不可读、内容残缺、版本不符或必要文件不存在，立即告知用户具体缺项并停止涉及该项目的代码、补丁、转换、核验。** 不从旧窗口摘要、失效链接、GitHub 网页或历史补丁猜测替代；不得声称已经通过核验。
- 原版地图数据与 RPP 引擎语义分别核查，不能把 Gold 宏参数、地图块编号或脚本命令直接照搬。明确区分 Gold 对照一致的部分与有意简化的 NPC/美术；没有 ROM 构建和游戏实测不得宣称可运行已验收。
- 修改必须以**实际收到的可读完整工程 ZIP 的文件内容**生成并检验补丁；提供明确前置版本和文件哈希检查、正反应用检查。严格保留原有 100755/100644 权限，不额外执行 Commit/Push。

## TOOL-R31-148：连接条带检查应自动拒绝越界，不能只检查素材

- **检查器职责**：`tools/johto_rpp_connection_guard.py` 从Gold `attributes.asm`和RPP尺寸/地图Header构造并比对北/南连接的实际3行条带，检查源地图边界、目标缓存边界、重叠宽度、地图方向标志与角色落点。以只读/显式失败方式对使用者选择的两向连接逐条审计；不能仅靠宏拼写或渲染静态截图。
- **必须保留的回归**：旧 `.147` 北向负目标偏移/23格复制要FAIL；`.148` 的北/南双向校验要PASS；连接宽度/源起点/Gold offset/方向位被破坏时也要FAIL。本轮新增10项用例、已有33项工具测试已通过，但未编译/链接ROM，也没证明未覆盖的连接不会出现新问题。
- **禁止虚假覆盖**：工具暂时只支持NORTH/SOUTH；EAST/WEST连接（如未来桔梗市）必须先有独立数学模型和测试，否则直接报不支持；工具不负责Gold完整剧情、Warp或RPP碰撞判定。不要因守卫通过就取消手机实测。
- **提交隔离**：脚本、测试和`tools/`说明在第二次`test(tool)`提交，与前一次`feat(map)`已验收功能分开。游戏版本字串不随只读脚本变更。本助手没有实际Git提交/Push。

## R31-5.62.148：Gold 连接偏移 ≠ RPP 旧宏复制参数（`.147` 漏检教训）

- **事实和责任边界**：`.147` 制作时把Gold `connection north, Route31, ROUTE_31, -10` 中的**空间偏移**直接手工写入RPP `NORTH_MAP_CONNECTION` 参数。Gold地图地形/跳崖转换器 `johto_rpp_batch.py` 的 `convert_one()` 不负责生成这段RPP地图Header连接，因此错误发生在**整合与审计连接代码**阶段，不能笼统归咎于素材转换器。
- **可以复核的越界**：Route30地图宽10块、Route31宽20块。旧宏产生源/目标条带不匹配，写入目标起点 `wOverworldMap - 7`、行宽23块，超出合法的边缘复制范围；玩家看到不属于该处的树，移动后画面恢复。不要只凭“地图180/180块像素一致”“Header注册了连接”“补丁可应用”认定运行时连接安全。
- **已采取的定点修复**：`.148` 改为显式10列×3行北向边界记录，选Route31末三行第10至19列写到Route30有效北边界，保持玩家16×16坐标平移；原Route31回程使用经核对的SOUTH连接。用户确认树残留消失，报告已走过的往返、跳崖与边缘场景未见异常。这是**报告过的场景验收**，不是逐字节运行轨迹或ROM编译/全存档证明。
- **今后预防**：接入地图时必须计算Gold的实际重叠列/行、RPP连接宏或显式记录展开后的每行源读取和目标写入区间、进入后的玩家坐标，并验证两个方向。尺寸不同或偏移为负值时绝不直接拷贝Gold offset。保留未接图的安全Fence，不能用全局清屏或删树掩盖内存复制错误。
- **提交边界**：`.147`新路+`.148`修正可作为一次`feat(map)`提交；防错脚本是另一个`test(tool)`提交。文档与登记更新不得顺便改动用户已验收的 `.148` 游戏源码或 `FLY144`、`FIX139` 旧功能。本助手不编译、不提交、不Push。

## FLY-5.62.144：旧 `.143` 选择性回接的实测收口与防回归（已用户验收）

- **版本与基线**：本次是从已提交的 `FIX-5.62.139` 接回 `.140` Johto Fly、`.141` Fly 菜单音效和城都共用 11 槽室外 SpriteSet、`.142` 浮动 `Warp Destination Helpers`，最终为 `FLY-5.62.144@`。旧 `SIGN-5.62.143.patch` 是叠加多个版本甚至无关战斗变更的工作树导出，绝不能整包用于 `FIX139` 或 `.144`。
- **已经覆盖的回归**：用户分别测试了城都两城飞空目的地和菜单/确认音效、城镇和道路之间步行与骑车切换、地点栏、NPC 贴图、关都原 Fly，以及保存/Continue 后城都飞行解锁持续有效，反馈全部正常。将历史 `.132` “城都室外 NPC 贴图异常”标记为**在当前已接入城都室外地图上暂已解决**；后续新引入 NPC、图形集或地图仍需单独检查，不能据此保证所有未接入区域。
- **保护 `FIX139` 修复**：下方地点栏读取地图名时使用 `BANK(MapNames)`（Bank `$1C`），29／30 号道路应继续使用该 Bank 中的既有名称指针。已测 `.144` 期间 `data/town_map_entries.asm`、`engine/overworld/map_name_sign.asm`、`color/refreshmaps.asm` 均不发生变化；尤其不合并旧 `.141` WY 取消判断或 `.143` `$9C00` VBlank 自动覆盖试验。
- **Fly 目的地与地图身份分离**：城都飞空只在 `JOHTO` 地区启用独立界面，现阶段仅有若叶镇、吉花市。解锁使用已有保存事件数组中确认的两个闲置位；普通 Town Map 道路定位、关都飞空地点及 Teleport/Dig 是不同系统。扩展每个城市时先审计事件位冲突、落点地形、地图别名和 `wCurMapTileset` 的恢复。
- **室外 NPC 图形集**：RPP 旧 `InitOutsideMapSprites` 用关都旧 Map ID 范围判断室外，不适用于城都 `$E7/$F4/$CE/$0B` 等非连续别名；按 `wCurMapTileset == JOHTO` 选共享固定 SpriteSet，避免相邻切图中逐个重载错图。新增城都 NPC 时核对图形是否在 11 槽之内，预留球/树果槽，不要盲目改图块和运行中 VRAM 上传时序。
- **Bank $35 空间与验证边界**：`Warp Destination Helpers` 不必强制绑 `$35`；它由远调用访问，改成浮动 `ROMX` 后避免单点 bank 装箱失败。未来仍须在实际工程编译链接时复核 ROMX 总容量和 `jpba` 的 bank/寄存器约束。静态工具测试、补丁正反应用与用户 ROM 实测应分别记录；本轮 AI 未编译 ROM、未执行用户手机仓库 Git commit/Push。
- **严格排除范围**：旧 `.143` 累积导出里的 Transform 调色板缓存、区域形态小拉达 `TRANSFORM`、铁尾／钢翼动画改动，以及旧地点栏和 `$0B` 特判均不属于当前提交。历史 `InternalMapEntries` 里非升序 `IMAP JOHTO_ROUTE_30` 尚未独立审计，禁止顺手增删或重排。

## FIX-5.62.139: 城都道路地点栏不能混用 ROM0 名称指针与 Bank $1C 读取路径

- **用户实测定位（从 `.138` 正常与 `.139` 回归开始）**：最初 `.139` 在若叶镇／29 号道路／吉花市的无缝切换中会出现地点栏不显示或一闪而过；30 号道路一度错显关都 Saffron City。此前只修 Window/计时的后续实验未解决首个回归；不可把那些试验性版本的代码当作本次基线。
- **真正的数据读取约束**：`engine/overworld/map_name_sign.asm` 的 `.CopyMapNameToBuffer` 通过 `ld a, BANK(MapNames)` + `FarCopyData2` 复制名称，期待收到与 `MapNames` 一样位于 ROMX Bank `$1C` 的有效指针。旧 `.139` 的两条道路使用 `main.asm` 浮动 ROM0 的 `JohtoRoute29Name`／`JohtoRoute30Name` 或 `$0B` 的错误 Saffron 名称；仅改变地名指针目标后，用户确认原本异常的边界切换恢复。可验证的修复措施是**改用已存在于 Bank `$1C` 的 `JohtoRoute29TownMapName` 与 `JohtoRoute30TownMapName`**，无需新增字符串、Bank、ROM0 代码或运行时特判。
- **严禁再犯：地点表不能靠增删条目“试修”**。`ExternalMapEntries[$0B]` 只把旧占位 `SaffronCityName` 指针改成 `JohtoRoute30TownMapName`；`InternalMapEntries` 中 `JOHTO_ROUTE_29` 只把 `JohtoRoute29Name` 改成 `JohtoRoute29TownMapName`。不改原坐标和 4 字节 EMAP / IMAP 项格式、不更改条目数量、不移动后续索引、不碰相邻地图连接/地图名牌计时与 Window 刷新。先前试验性补丁曾删掉 Route 30 的内部表项，用户回报原本正常的吉花市 ↔ Route 30 因此异常；不得再套用它。
- **根因证据边界**：用户在 `.139` + 两处指针替换后实测若叶镇 ↔ Route 29 ↔ 吉花市 ↔ Route 30 的主要双向切换通过，录像中 Route 29、吉花市、Route 30 正确显示。地点栏源码另以 `wMapNameSignNamePtr + 1 == 0` 判断未初始化，这是一个脆弱设计；目前 `139.zip` 两份 `.sym` 只显示 `MapNames` 等主标签，不足以证明旧 ROM0 字符串的确切链接地址，因此**不能断言 `$00xx` 是唯一根因**。
- **留下单独审计的历史表项**：`.139` 新加的 `IMAP JOHTO_ROUTE_30` 仍位于 `InternalMapEntries` 中非升序的位置，且仍含旧 ROM0 指针；这次用户验证的是两处定点改动。不要为了“顺便清理”重新排列内部表或删除条目；另开兼容性审计后再处理。普通 Town Map、存档显示、地点栏与飞行目的地虽然共用一些名称/数据，也不代表各自已全面验收。
- **收口边界**：仅修改两处名称指针（加一个 `FIX-5.62.139` 注释）、`data/game_version.asm` 前缀和清理文档。用户实测不等于本助手重新编译 ROM；所有新增地图、飞行、NPC 贴图和其它分支后续实验都不包含在本次提交中。避免把已提交 `MAP-5.62.139` 的地图内容重复提交。

## TOOL-5.62.135 → TOOL-5.62.136: Gold 离线地图索引和提交边界

- **离线资源解析不等于地图移植完成**：`tools/johto_rpp_batch.py`、`tools/johto_rpp_pipeline.py`、`tools/johto_rpp_validate.py` 为候选生成和静态检查器，不写回项目 `maps/`/`data/`/`engine/`。工具可单独阶段性提交、后续逐步迭代；`OFFLINE_REVIEW_ONLY` 不是 ROM 可用、碰撞正确或游戏实测通过的含义。
- **不能用地图名推导 `.blk` 文件名**：Gold 大量商店、宝可梦中心和民居共用布局；必须解析 `data/maps/blocks.asm` 中连续 `*_Blocks:` 标签到 `INCBIN` 的真实来源（`tools/johto_gold_sources.py`）。共享 `.blk` 并不意味着共享 NPC、事件、Warp、Header 或 RPP 的素材/碰撞。文件缺失、非法路径、尺寸不匹配应报错，不得猜测补齐或因共享关系误报缺失。
- **静态报告的界限**：本轮在用户提供的 Gold 源码上识别 368 张注册地图、239 份布局（22 组共享、151 张地图参与共享）；20 张静态通过、348 张待适配、0 张确定性静态失败。数字只适用于本次输入与当前转换器；不能由此声称剩余 348 张已经转换好，非 Johto 图块集的视觉、碰撞、调色板及剧情仍须单独审查。
- **回归及交付纪律**：保持已验收若叶镇、29 号道路与 `.134` RPP 原生跳崖不变；29 张既有候选输出应维持逐字节一致。运行 `python -m unittest discover -s tools/tests -v`，真实 Gold 源码下运行只读 pipeline，并确保输出目录位于 RPP/Gold 两套源码之外。不要将生成报告、Gold 参考源码、RPP_PROJECT_CONTEXT 导出上下文、测试缓存纳入 Git。提交日志需注明 `.134→.136` 和“工具静态验证通过，未编译/未实机”。

## MAP-5.62.134: Convert Gold HOP art to native RPP tile pairs, no coordinate ledge interpreter

- For Gold Johto Route 29, the original tile graphics alone are insufficient for rightward cliffs: the front tile is `$05`, indistinguishable from ordinary walkable floor, and the down cliff `$4c` also occurs where no hop is allowed. Do **not** match `($05,$05)` globally or add an in-game per-coordinate hop table to compensate.
- Reuse RPP's established `HandleLedges` table comparison, action animation, sound, `wSimulatedJoypadStatesIndex=2` and `TilePairCollisionsLand` / `CheckTilePassable`. Generate dedicated *pixel-identical, blocked* Johto tile IDs `$20` (copy `$05`) / `$21` (copy `$4c`) in previously unused image slots; copy tile palettes and clone only the affected route block variants, not shared Johto blocks used by New Bark. Hop pairs are left `$05,$3b`, right `$05,$20`, down `$05,$21`.
- The old Route 29 coordinate ledge/anti-reverse collision engine and `.133` Johto-only movement count override were experimental, not validated, and have been removed. Below historical `.131`–`.133` notes describe retired implementations; do not reintroduce them. Validate generated map collisions against both ordinary transitions and Gold HOP source cells. Do not make a runtime claim from static checks alone.

# RPP Development Pitfalls

## TOOL-5.62.169：离线图块转换／最终碰撞审计和 Gold 入口标签（工具提交，不升游戏版）

- **脚本职能边界**：`tools/johto_rpp_batch.py` 等工具产出离线候选和复核信息，不自动注册地图、生成有效 Warp 或移植 NPC/剧情；“候选静态通过”不能当作玩家可走遍所有格的证据。
- **`LADDER` 兼容契约**：Gold 原版阶梯可通，而 RPP `$07` 是共用墙砖。允许经过像素、颜色、应用区块验证的 `$5B` 适配；其它共享图块变化应拒绝，以防下张地图因前缀逐字节断言或无条件放行再次失败。
- **必须审计最终数据**：不能先 `convert_one()` 后仍拿转换前的 `.blk` 和区块集作碰撞审计；应核对转换后及文件落盘后的最终布局、块变体和运行时可走白名单，并保留人为破坏阶梯输出的负向测试。
- **`DOOR/CAVE` 单独记录**：原版标签与RPP `DoorTileIDPointers`、`WarpTileIDPointers`和真实 Warp 对象不是同一层；Route32 含1处 `DOOR`、2处 `CAVE`、4个原版 Warp，应当作为待人工接入风险清单，任何静态通过不得直接解锁游戏门口。
- **回归/隔离**：已记录 `.169` 双源码192项测试通过、368张原版地图登记无静态错误，尚不等于全图可玩或ROM编译通过。第二笔 `test(tool)` 限 `tools/` 及这两份维护文档，游戏版本继续为 `MAP-5.62.169`；Git提交/推送由用户执行。

## MAP-5.62.169：Route32 32号道路／桔梗市南向连接（地图功能单独提交）

- **地图范围**：Gold `Route32` 10×45地形、`$FB` 地图别名、音乐与名称、桔梗市南侧双向10列×3行条带、精确入口列及未接图边界护栏同时登记；Gold 地形通行不自动授予未开发室内 Warp。
- **阶梯原版语义**：Gold `LADDER` 使用的 `$07` 图块也可作墙面；RPP 不能全局放行 `$07`。定点复用相同像素／调色的 `$5B` 专用砖，令阶梯可通、墙面保持不可通；跳崖副本 `$30` 的颜色需与来源一致。用户确认阶梯可走，但其它格/入口未逐项实测。
- **障碍同步与提交隔离**：Route32 的 Markdown 和 CSV 封路登记必须同步。首笔 `feat(map)` 提交只含 `tools/` 之外的游戏源码、地形资源、登记和当时的 TODO／踩坑记录；离线转换器及测试单独走第二笔 `test(tool)`，不重复改游戏版本。
- **保留后续边界**：PC、遗迹、联合洞穴四个 Gold Warp 还没有 RPP 目标，必须等对应室内地图、目标站位、反向 Warp 验证再解封；地图扩容以及关都与旧存档回归不因地图能进入而视为完成。

**MAP-5.62.134 提交清理边界（用户反馈后补记，文档-only）**：用户已体验 `.134`，明确认为原生 RPP 跳崖比先前城都专用运行时代码更好；并未逐个证明全部交叉角/边界回归完成。下方 `.131`～`.133` 的模拟计数、坐标判定结论是历史实验记录，不得当成当前有效实现。`.129` Continue 重读碰撞表及原有高草遮挡已由用户实测，必须保留。若叶镇临时 NPC 对照与野外 NPC 花屏仍待独立专项；城都批量生成器 V1 不属于 `.134` 的提交内容。下一轮只调整数据生成，不要再次重写 `HandleLedges`。

This file is the persistent, Git-tracked record of repeatable development failures and prevention rules for this branch.

`RPP_PROJECT_CONTEXT/` is generated by RPP Mobile during export. Do not store durable project history only in that generated directory: a later export can replace it. When a reusable failure mode is discovered, add it here and summarize any version-specific details in the current handoff.

## Johto Route 29 regression guards (MAP-5.62.129 / .130)

- **User-confirmed save fix**: `.129` Continue refreshes the tileset header, including `wTilesetCollisionPtr`, even when `wCurMapTileset` bit7 requests reuse. Saved WRAM ROM pointers become stale after ROM relink; flying remakes these pointers. Do not remove the refresh or move the collision table to ROMX.
- **Two different directional bitfields**: `hJoyHeld` uses `D_LEFT=$20`, `D_RIGHT=$10`, `D_UP=$40`, `D_DOWN=$80` whereas `wPlayerDirection` uses `PLAYER_DIR_LEFT=$02`, `PLAYER_DIR_RIGHT=$01`, `PLAYER_DIR_UP=$08`, `PLAYER_DIR_DOWN=$04`. Jump initiation checks the former; reverse-ledge blocking must compare the latter. Data generator must reflect this.
- **No-map-connection edge fence**: Route 29 has only an eastward connection. Its original Gold grass may be passable on the outermost map row, so stop walking off north/south/west edges even if normal tile collision passes. Do so before `wd736` jumping / simulated input bypasses ordinary collision.
- **Sprite diagnostic is temporary**: `.130` replaces only three town-side NPC graphics for comparing same Route 29 graphic under different background conditions. Revert once inspected; no raw sprite art or palette colors were modified.
- Original Gold collision semantics cannot be inferred just from a rendered `$05` tile. Four diagonal ledge cells in Route 29 remain unsupported. A two-step simulated jump skips ordinary collisions: validate landing and border safety when generalizing generator. Do not label this a full Johto ledge engine port.

## Cross-bank calls and register lifetime

- `CALLBA`/bank-switch wrappers must not be assumed to preserve `A`, `BC`, or `HL` unless the exact adapter proves it. Bank restore can consume `A`, and `CALLBA` itself uses `HL` for the far target address.
- `EVO-5.62.271` passed a Party-menu tilemap pointer through `HL` across `CALLBA`. The helper then treated the far target address as the UI destination, so `Able`/`Not able`/`LvXX+` disappeared and writes could hit ROM/MBC control addresses, disturbing the active bank. Pass such pointers in a verified register or save/restore them explicitly.
- The wild/fishing producer work already proved the same class of ABI issue: do not return critical form/source identity through `A` across `CALLBA`; protect live `BC`/`HL` when required.

- **HOME-5.62.121（失败版本，勿提交）**：将 `MapHeaderPointers` 搬到 ROMX 后，`LoadMapHeader` 先把旧地图 ID 装入 `A` 再 `callab GetKantoMapHeaderPointer`；实际上 `Bankswitch` 会用目标 Bank 和原 Bank 覆盖 `A`，导致指针索引错乱。用户报告进入房屋以及 Fly 后乱码／死机。**HOME-5.62.122 修复约定**：旧地图 ID 放入 `E`，远调用目标从 `E` 查表；原地图 ROM Bank 由 `Bankswitch` 恢复，`HL` 作为返回指针使用。修改此类路径必须同时检查每一个远调用的参数寄存器、返回寄存器与读表时激活的 ROM Bank；静态检查不等于运行验证。
- **HOME-5.62.122 验收与空间边界**：用户已对关都主流城镇、进出房屋、宝可梦中心、港口、山洞、道馆、Fly、城都入口及存读档复测，未发现 `.121` 的死机；不是逐张全地图测试。用户红版 MAP 报告 ROM0 余量从 375 B 升至 879 B（+504 B），Bank `$40` 余量相应降低约 503 B。后续 Home 瘦身不要只看源代码行数或忘记查 `RPP_PROJECT_CONTEXT/03_PROJECT_REQUIREMENTS.txt` 和本文件的既有 `callab` ABI 规则；优化数据表时保持索引顺序、固定表长和未来新增条目的可维护性。

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
- If changing vertical shake behavior, review `.StageBlankBG0TopRowForEnemyFeedback`; Iron Tail/Steel Wing previously left display residue around this path.

## Johto map and Town Map integration (MAP-5.62.116)

- `CanWalkOntoTile` reads the collision-table pointer without switching ROM Bank. Do not put a new map's `.tilecoll` list into a floating ROMX section when that read path expects ROM0: New Bark initially treated walkable tiles as walls until `NewBark_Coll` was moved beside the other ROM0 collision tables. Keep the outdoor block graphics in ROMX; distinguish their loading path from the collision lookup path.
- The Gold Town Map graphics, per-tile palette assignments, and actual RGB palettes must be migrated as a set. The RPP inset corner is a grey UI tile rather than an interchangeable Gold terrain tile. Misusing a Kanto coast tile under the grey UI palette can appear as a white semicircle. Compare the final 8x8 source tile, tilemap index, and palette together before changing frame art.
- The Kanto map-name scratch buffer is shorter than some Johto location names. Display long Johto names directly from the ROM strings with explicit line breaks, and bound the new Johto selection index to its 10-entry table; do not write unbounded names into the legacy short buffer.
- Keep the region-aware Town Map selector separate from the existing Fly and Pokédex nest pages until those screens receive explicit region support; no early 2MB migration is implied by completing the first Johto page. Static patch checks do not substitute for movement and menu exit tests.

## Johto 2MB ROM layout (ROM-5.62.117)

- The Makefile links source sections without `-l pokered.link`; editing that legacy layout file alone does not constrain the current ROMX allocator. Explicit `BANK[...]` in the actual `main.asm` sections is required to pin Johto data into `$40` and above.
- Putting any data only in Bank `$40` would require padding past 65 banks to obtain a valid power-of-two ROM size; a single byte at `$7F:$7FFF` establishes a full 128-bank 2MB boundary. Keep the existing `rgbfix -p 0`, MBC3 type and SRAM configuration. The user-supplied red ROM is 2,097,152 bytes and has header $0147=$13, $0148=$06; the blue ROM and emulator/save tests remain unverified.
- Use `BANK(symbol)` banked loaders for Johto's map graphics, Town Map graphics and map headers; preserve unbanked `NewBark_Coll` in ROM0. Floating sections elsewhere are not automatically restricted to the original 1MB, and the user-supplied red MAP confirms the present Johto assets in bank $40, boundary in $7F. It also shows only 6 bytes of slack in fixed bank $1C (Town Map code) and $01C4 bytes in ROM0; do not extend those hot sections casually.

## Region-map key rollout (REG-5.62.118)

- The first region resolver accepts `DE = (region, local_map_id)` and returns `D = map header ROM bank`, `HL = map header pointer` plus carry status. `callab`/`callba` destroys `A`/`BC` and initially reuses `HL`, so callers must not pass the map key in those registers or expect its return bank in `A`. The resolver does not leave the target bank selected.
- A ROMX routine cannot directly switch to Bank `$03` and keep executing ROMX instructions. Use the tiny ROM0 adapter to perform the switch/read/restore entirely while executing ROM0, then resume the resolver in Bank `$40`. Save the old bank on the stack rather than overwriting the shared `BankswitchHome` scratch; preserve the caller's stack bank.
- `NEW_BARK_TOWN=$E7` remains a legacy one-byte save/Warp alias and the original Kanto tables retain every old index. The new `(JOHTO, $00)` Header path is opt-in until `wCurRegion`, old-save migration, and cross-region Warp semantics are implemented. Do not reinterpret `$FF` special Warp targets or use the temporary Town Map selection scratch as persisted region state.

## Saved region-state compatibility (REG-5.62.119)

- Region state currently occupies reserved bytes `$D7A4`–`$D7A7` in the **existing saved main-data block**: `wCurRegion`, `wLastRegion`, and two magic bytes. Neither `wMainDataEnd` nor any downstream WRAM/SRAM address moves. Do **not** reuse `wUnusedD71F` (`$D7A3`): despite its name, the item-use code writes there.
- As long as legacy one-byte map IDs are the active Warp format, `LoadMapHeader` synchronizes both regions from `wCurMap`/`wLastMap` via Bank `$40`. This initializes compatible region bytes even for older saves on the first map load: `$E7` is Johto, all other existing IDs Kanto. The two magic bytes are written but not checked on load; this is **not** independent region-state save migration. The header resolver for New Bark now takes `wCurRegion`, but other maps keep their original lookup behavior.
- This synchronization deliberately **overwrites** the persisted regions on each map entry. Before permitting a Johto-local ID that overlaps a Kanto ID, replace this compatibility-only projection with explicit region-aware warp/connection assignment and save-load validation; otherwise a real region key would be lost on transition. No new Fly, Teleport, blackout, indoor, or `$FF` destination semantics are implemented in this step.
- `engine/save.asm` resides in essentially full fixed Bank `$1C`; do not insert migration code there just because it copies the save. The first actual `LoadMapHeader` provides a small ROM0 far-call hook, with all synchronization logic in Bank `$40`. Without a fresh MAP/ROM, linker free space and runtime compatibility remain unverified.

## Explicit region-key ferry Warp (REG-5.62.120)

- **REG-5.62.123 bidirectional escape**: the ferry menu now emits `$FE` for both New Bark and `GO_HOME`. Never distinguish these targets by the escape byte alone: the selected destination warp ID is `0` for New Bark and `2` for Vermilion, distinct from `wWarpedFromWhichWarp` (zero-based source tile 0/1). Match `(source map, source warp slot, destination warp ID)` in Bank `$40`, compare the warp ID in the ferry menu's AlreadyThere branch, and let the cursor recognize `$FE + warp 0` as New Bark only. Old ferry saves may still contain `$E7` or `VERMILION_FERRY_DOCK` directly; both remain valid and require compatibility checks when this path changes. The user has tested the REG-5.62.123 suggested ferry/menu scenarios with no reported issue, but has not supplied separate per-byte memory evidence or an exhaustive special-Warp edge-case report. This avoids new Home code or any change to the 4-byte map-object Warp structure.

- `$FE` 是显式 Warp **目的地转义值**，只允许已在 Bank `$40` 的 `ExplicitWarpRegionTargets` 登记的来源地图和零基 Warp 槽使用。渡轮两出口槽指向 `(JOHTO, local $00)`；普通 Warp 在写入 `wCurMap` 前解析，仍回写 `$E7` 兼容旧代码。不能把 `$FE` 直接塞到未登记的地图对象中。
- 远调用 `callab` 破坏 `A/BC/HL`，因此必须先将零基 Warp 槽保存到 `wWarpedFromWhichWarp`，目标别名从 `E` 读取，不从 `A` 读取。找不到映射时安全回退枯叶渡轮码头，绝不能将 `$FE` 写入 `wCurMap`。
- 渡轮 UI 的目的地读取同样要兼容旧存档 `$E7` 和新 `$FE`。本版仍通过旧地图别名工作，`.119` 的地区字段在 LoadMapHeader 时照旧同步；这不是无需别名的原生双地区系统。
- `.120` 在 `home/overworld.asm` 的 `WarpFound2` 新增了目的地转义判断和跨 Bank 调用；该版已由用户运行基本场景，未报告明显问题，本次提交前不改变其游戏逻辑。用户报告目前 ROM0/Home 只剩约 300 余字节，尚无本次 ROM/MAP 实测文件可量化新增字节开销。下一版需专项审计 Bank0 空间、优先搬迁可迁移逻辑到 Bank `$40` 等扩展 Bank，并在不破坏跨 Bank ABI、Warp 返回值及后续扩展性的条件下压缩 Home；不要把“代码行数”误当作“字节占用”。

- **UI-5.62.124 Johto name alias**: `InternalMapEntries` lives in fixed Bank `$1C` and provides `HL` pointers that both the save/continue formatter and the map-name sign dereference while Bank `$1C` is active (the sign uses a far copy). The existing `JohtoNewBarkName` is already in the same bank; map `NEW_BARK_TOWN` to that pointer rather than `AreaUnknownText`. Do not point this entry directly to a label stored only in Bank `$40`; such a pointer would look valid but dereference data from the wrong bank. Keep Bank `$1C` nearly full section unchanged in size and avoid extra Home logic. User runtime feedback for UI-5.62.124: location names appear on Save/Continue pages; the lower name sign appears when the location changes but not immediately on Continue, consistent with Kanto. No change was made to that timing behavior. This confirms the tested name-display paths, not every map entry or every loading edge case.

## ROM bank placement

- Treat fixed Bank `$03` and `$34` as effectively frozen for new body logic. Keep only minimal hooks there and place larger new helpers in floating/roomy ROMX sections.
- A linker error naming the section that finally fails to place does not prove that section caused the growth. Find the section that actually expanded first.
- MAP slack is advisory, especially with floating sections; the linker result is the final authority.

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

## P1-3: Gold shared tileset sources and RPP .bst trailing-byte traps (2026-10-13)

- **Gold resource aliases are defined by ASM labels, not file names.** In `gfx/tilesets.asm`, `TilesetCaveMeta::` and `TilesetDarkCaveMeta::` share `data/tilesets/cave_metatiles.bin`; similarly both Coll labels refer to `cave_collision.asm`. Resolve these from consecutive labels + `INCBIN`/`INCLUDE` rather than constructing `<tileset>_metatiles.bin` unconditionally. Keep the original Gold file read-only and expose the source path in reports.
- **RPP blocksets can have odd trailing bytes**: the uploaded `gfx/blocksets/facility.bst` has 2049 bytes, specifically 128 complete blocks plus a terminal `00`. For P1-3 off-line audit only, accept this *exact* identified case while recording `trailing_partial_bytes=1`; fail on other tails. Do not edit the file or claim the ROM ignores that byte without independent engine review.
- **Rendered-source audit is not game/runtime verification.** This scan has 94 Gold metatiles with no verifiable rendered graphic due to missing/out-of-range PNG indexing, and 15 RPP blocksets with no same-named PNG. `PIXEL_EXACT` validates only currently parsed source 32x32 RGBA art. Colour palettes/bank loading, run-time 8x8 index mapping, blockset capacity, Gold tilecoll vs RPP tile collision, ledge actions and area connections must each be checked. Never auto-register maps from generated candidates, and preserve New Bark/Route29, ferry and Continue behaviour.

## P2-1: Map connection exists but a temporary terrain blocker remained (2026-10-13)

- **Root cause**: The P2-1 Cherrygrove map registration/Route 29 west connection was applied while deliberately preserving the entire older `maps/JohtoRoute29.blk`. Its previously documented west-edge temporary forest blocker at **32x32 block `(x=0,y=3)`**, Gold `$01` / RPP `$05` (byte offset 90), was therefore retained and blocked the player's approach. This was a missed map-transition cleanup, not a reason to delete all trees.
- **Mandatory future prevention**: Before every outdoor map registration, read `docs/JOHTO_OUTDOOR_BLOCKER_REGISTER_zh.md` and its CSV, diff Gold/RPP terrain **and** inspect static edge guards, Warp/event objects, and temporary test NPCs. Each modified block/object must be labeled as `TEMP_TERRAIN`, `TEMP_EDGE_GUARD`, `TEMP_NOTICE`, `ORIGINAL_OBSTACLE`, `ENGINE_REQUIRED`, `FUNCTIONAL_MAP_EDIT`, or `UNKNOWN`, with an explicit unblocking dependency. Only `CONFIRMED_REMOVE` may be removed after the dependency is active; anything unclear remains untouched until reviewed.
- **Critical non-removal rule (updated to MAP-5.62.138)**: In the older *blocked* Route 29 build there were 20 differing bytes versus Gold: one artificial west blocker `(x=0,y=3)` plus **19** required native-RPP ledge block variants `$80..$84`. In the uploaded `.138` patch `JohtoRoute29.blk[90]` has already been restored from `$05` to `$01`, leaving only the 19 intentional ledge variants. Do not restore the entire original Gold `.blk`, delete all `$05` tiles, or rewrite `HandleLedges`. The user reports Cherrygrove is accessible, but exhaustive border, Continue, ledge and ferry regressions have not been individually reported.


## P2-1 closeout: Town Map and bike capability are independent feature registries (MAP-5.62.138)

- **Route vs city in ordinary Town Map**: Merely adding a Johto city or connection does not produce a distinct route marker. `engine/town_map.asm` must register a `Route 29` landmark and map `wCurMap=JOHTO_ROUTE_29` to its own browse/player-marker index, rather than defaulting to New Bark. The user confirmed that Route 29 now displays its own place. Every newly connected outdoor road requires an explicit Town Map location review; do not confuse ordinary Town Map with Fly destination selection.
- **Bike riding tileset whitelist**: `data/bike_riding_tilesets.asm` initially omitted `JOHTO` although existing Johto town/road/city maps all use this tileset. Adding `JOHTO` before `$FF` restores both bag and shortcut bike permissions without granting riding to interiors. User specifically verified New Bark / Route 29 / Cherrygrove mounting and dismounting, Kanto rules intact, and interiors blocked. Bike support is **not** evidence that Fly, Teleport, Surf or other field moves work.
- **Legacy map identities remain transitional**: Cherrygrove uses legacy alias `$CE` and local Johto map ID 2 only as a pilot. Do not infer unused-looking Kanto aliases or expand through `$F1/$F2/$F3` without tracing existing references. Fly menu, `CheckIfInOutsideMap`, map-to-region sync, Warp and Continue each need separate audit, especially cross-region state. This closeout does not approve runtime shortcut fixes in those systems.
- **Commit hygiene**: The user-uploaded `MAP-5.62.138.patch` is a cumulative selected-worktree export based on `.136` and includes **three new P1-3 tool files as well as P2-1 feature changes**. This does not prove their Git submission status. If uncommitted, stage tools separately from the `feat(map)` files; avoid `git add -A`, binary `.blk` omissions, generated `RPP_PROJECT_CONTEXT/`, Gold reference sources and audit outputs. `TODO.md`, this file and `docs/JOHTO_OUTDOOR_BLOCKER_REGISTER_zh.md` / CSV are reconciled to the observed `.138` worktree; game logic and version string are unchanged by documentation closeout.

## P2-2: Route 30 Gold visual equivalence versus event equivalence (MAP-5.62.139 closeout)

- **Source-level terrain art was independently compared after user testing** against the uploaded `pokegold-master(1).zip`: Gold `johto_metatiles.bin` (128 × 16 bytes) matches the original 128 RPP `johto.bst` blocks byte-for-byte. The only 8×8 Johto PNG differences are `$20/$21`, both unused by all original Gold metatiles; RPP repurposes them as pixel-identical ledge collision clones. Across Cherrygrove (180 blocks), Route 29 (270) and Route 30 (270), *every rendered 8×8 static terrain tile position* matches Gold source pixel data. This is not a palette/VRAM/ROM equivalence or a full event parity claim.
- **Do not bulk-restore the Gold `.blk` after collision adaptation**: Route 29 has 19 intentional block-ID changes, Route 30 has 11 (using `$82`, new `$85/$86`); each preserves the original appearance. Route 30's 21 Gold `HOP_DOWN` positions match 21 native RPP downward-ledge tile pairs exactly, with no extras; Route 29's 25 Gold downward-ledge positions remain matched. The RPP collision check is semantic, not Gold's engine; source pixel equality alone is not permission to delete guard code.
- **Exact Gold placement, but deferred objects**: Route 30's four outdoor sign triggers match Gold `(9,43),(13,29),(15,5),(3,21)`; Cherrygrove's four sign coordinates match too. Gold Route 30 additionally has two building warps `(7,39),(17,5)`, ten outdoor object events (including two berry-tree sprites) and a hidden Potion bg event `(14,9)`; the current outdoor-only RPP has no such active events. The four RPP signs have temporary text that is not verbatim Gold text. So “trees/buildings/roads match” covers static tilemap artwork; “every placed object matches” is **false until events are ported**. Gold Cherrygrove exterior border-block field is `$35` while RPP uses `$05`; that field is separate from the 180 in-map `.blk` bytes and is **not** covered by the pixel match (rendering beyond map extents remains to audit).
- **Connections and protections**: Gold Cherrygrove↔Route 30 has `+5/-5` connection offsets. RPP mirrors this and narrows the open north/south crossing with safety fences. The Route 30 north exit remains intentionally blocked pending Route 31. Keep unopened side borders closed and record releases by exact edge ID in the blocker register.
- **Acceptance and commit hygiene**: The user reports testing the suggested `.139` game scenarios without seeing obvious issues; this is general reported runtime acceptance, not a complete per-tile, per-ROM-bank or all-save edge-case proof. The `.138` export already reports `e9aefd60` (P1-3 tools) and `0fb87348` (P2-1 feature) committed (not pushed at export). This `.139` closeout updates docs, blocker Markdown/CSV and provides a commit message; it must not alter game code/version, re-run old `.138` patches or claim the assistant performed a real Git commit or ROM build.

## Formal closeout discipline

- Test-only data, re-arm logic, temporary species/evolution edits, and intermediate version suffixes must be removed before a formal version.
- Keep the real game version changing in test builds so the user can confirm the patch is applied, but keep source comments on the formal feature version rather than rewriting comments for every test suffix.
- Before delivery: static symbol/label/bank/register review, `git diff --check`, incremental `git apply --check`, actual apply, reverse-check, and file-mode comparison. Do not compile the user's project unless explicitly requested.

### MAP-5.62.126: Gold blocksets and Red tile passability are different layers

- Original Gold Route 29 is 30×9 bytes and shares the exact 2048-byte `johto_metatiles.bin` with this branch's `gfx/blocksets/johto.bst`; copy the actual `.blk`, never draw a guessed 18×9 section. The only Route 29 edited block is `(x=0,y=3)` for an absent Cherrygrove City connection. Restore its original `$01` once the city exists.
- A visually correct Gold grass metatile `$03` contains 8×8 tile `$04`, which was **not** in the Red engine's `johto.tilecoll` passable list. Add `$04` or the player cannot traverse the grass. That table is an unbanked ROM0 list, not the 128-entry Gold collision map; it does **not** itself implement Gen 2 field encounters.
- Gen 1 ledges are tested via tile-ID pairs in `HandleLedges`, only for tileset OVERWORLD before this version. The two new JOHTO pairs cover Gold's Route 29 cliff-edge `$4C` (down) and `$3B` (left) when approached from tile `$05`; broader Gold metatile collision semantics remain for later testing. Do not assume every Gold `HOP_*`, headbutt or cut-tree event is implemented from its original block art.
- Restoring New Bark `(x=4,y=4)` to Gold original `$01` alone did not produce a walkable link from the ferry in the Red engine. New Bark `(x=3,y=4)` also becomes `$01` instead of original `$54` to provide the minimal continuous ground-level approach. Check a reachability flood-fill instead of trusting a visually open map boundary.
- Keep Route 29 and New Bark map blocks in the same switched ROM bank `$40` for Red's connection-strip reader. The legacy `$F4` map alias and local `$01` must be entered in Johto and Kanto-compatible headers, region sync, sound, and map-name tables together.

### MAP-5.62.131: Gold HOP_* is the launch cell, not the barrier

Gold's original `HOP_DOWN`, `HOP_LEFT`, `HOP_RIGHT` marks the SAFE 16x16 cliff-lip cell where the player stands before hopping. Kanto's `HandleLedges` takes the *front tile* and simulates two steps. Route 29 bridge must convert `(x,y,HOP_*)` into the barrier `(x+dx,y+dy)`. Never check the Gold label itself as the barrier and never allow ordinary entry into the intermediate barrier, including from the reverse or perpendicular side. For the right-facing ledges, the intermediate tile renders as `$05` (walkable floor) so this guard is essential. Validate the two-step landing tile and map borders when extending this adapter. Existing Kanto action/animation should remain unchanged.

### MAP-5.62.132: Gold compound HOP_* is a direction mask, NOT diagonal movement

In pokegold `engine/overworld/player_movement.asm` `.ledge_table`, `HOP_DOWN_LEFT` is `FACE_DOWN | FACE_LEFT` and `HOP_DOWN_RIGHT` is `FACE_RIGHT | FACE_DOWN` (likewise up corners). One 16x16 Gold launch cell permits either of two separate cardinal hops; RPP's two-step jump handles each action already. Generate BOTH `source + delta` intermediate barrier records, so normal travel cannot enter either one. Do NOT drop compounds as unsupported diagonals or simulate an (x±1,y+1) move. The 4 Route 29 compound corners expand to 8 RPP cardinal rules; all 31 simple rules remain unchanged. Confirm map-corner collisions at runtime, and preserve tested Continue/grass behavior.

### MAP-5.62.133: RPP ledge input count includes the first physical step

`CollisionCheckOnLand` calls `CheckForJumpingAndTilePairCollisions`, which invokes `HandleLedges`, **then** on no collision immediately starts the current physical movement (`wWalkCounter=$10`). `HandleLedges`'s `StartSimulatingJoypadStates` only schedules *additional* movements for subsequent overworld loops. Therefore `wSimulatedJoypadStatesIndex=$02` means **one physical step plus two extra simulated steps = three map cells total** (not two). Previous `.131/.132` Gold converter assumed a two-cell route (launch -> front barrier -> landing), explaining the overshoot observed at a right compound corner; the old static checks never tested actual three-step movement. Set extra count to 1 **only for JOHTO** in `HandleLedges`, preserving Kanto's original count of 2. Validate total jump movement and destination from actual input flow when changing these tables. Do not confuse a continued physical direction hold *after* the forced hop with the internal forced step count. User-visible runtime confirmation still pending.


### GT-5.62.152：31号道路关卡入口双层拦截（用户视频复现）

- `.151` 虽登记正确门口 Warp 坐标，但城都室外关卡通道图块 `$40` 既不在 `gfx/tilesets/johto.tilecoll` 可通行表，又不在 `data/warp_tile_ids.asm` 的 `NewBarkWarpTileIDs`，导致不能踏上入口／踏上后不一定切图。`.152` 两处同时增加 `$40`，而不删除 `JohtoRoute31CollisionFence` 的未开放边缘保护；门口在 x=4，不是被保护的西边界 x=0。
- `$40` 的安全范围已核对：RPP 城都块集仅4个门口块含 `$40`；本阶段实际用到该块的只有 Route31 和 VioletCity 各1处，其他现有城都室外图不使用。后续增加地图时必须重新检查该范围，不可假设全地图所有 `$40` 都应通行。
- 上版 `.151` 补丁包含 `RPP_PROJECT_CONTEXT/03_PROJECT_REQUIREMENTS.txt` 变更，导致目标 Git 工作树不跟踪该导出上下文文件时 `git apply` 失败。**导出 ZIP 有文件，不代表当前仓库管理它**；以后正式增量补丁不得强行修改 `RPP_PROJECT_CONTEXT/` 导出目录。以仓库 `RPP_DEVELOPMENT_PITFALLS.md` 作为长期规则载体；RPP/GOLD 完整源码文件检查依旧强制，但不把导出上下文目录当成必需代码。
- `.152` 仅静态校验；未编译 ROM / 未确认 Bank 容量 / 未在游戏内测试。需重点验证 Route31→关卡→VioletCity 双向往返、门口上下擦过、撞墙声、区域地点显示及继续存档。

### GT-5.62.157–158：Gold 关卡应复用 RPP 原生门口机制；过渡房间不冒充城镇（用户实测）

- **根因与修复边界**：`.152/.153` 将城都门口 `$40` 加进 `NewBarkWarpTileIDs`，导致“踩上门口格就传送”，且与 `wd736 bit 2` 的 Warp 站位状态、`ExtraWarpCheck` 的方向／门框判断互相冲突，出现立即反向卡门。`.157` 保留 `$40` 的地面通行性质、移除无条件 Warp 白名单登记；先在门口站稳，再按 RPP Route15 风格朝门框碰撞进入原生 Warp。31号道路非地图边界处要做有明确坐标与方向范围的适配，不能直接把整个 JOHTO 判成边界，也不能只删 `$40` 后不补入口触发。
- **实测范围与结论**：用户确认 `.157` 的两侧上下入口对应正确，进门立即反向能出去、出门立即反向能再进去、门外上下移动不误进门，表现与关东门房一致。以上是用户明确反馈的实际操作通过；不得扩大为所有房屋、所有旧存档、所有地图的自动验收。
- **地点栏独立于地图注册**：`.158` 在 `engine/overworld/map_name_sign.asm` 的中性 Gate 名单中追加 `JOHTO_ROUTE31_VIOLET_GATE`，不删除地图 ID，不通过修改 `data/town_map_entries.asm` 或 Warp 目的地来“假装”过渡。用户确认最终显示与关东一致。以后新增过渡房屋先对照 Route15 等已成熟的 Gate 屏蔽规则，避免门房误显示新的城镇。
- **防回归约束**：室内 Gold 美术／碰撞／调色转换与门口行为分阶段提交；新素材不得把 `$40` 再放回自动 Warp 列表，也不能删除 `.158` 的过渡房间屏蔽项。最小运行复测仍应覆盖门外停留、两侧双入口、立即反向双向、进入真正室外地图后的地点名称。旧 `johto_gate_audit.py` 如带有 `.152` 的 `$40` 强制预期应视为历史测试，不能恢复为合格条件。
- **清理版本边界**：正式代码为 `GT-5.62.158@`；这次收口只更新根目录 TODO／踩坑记录及独立 Git 日志，不改任何 `.asm`、`.blk`、`.png`、图块、版本号或导出用 `RPP_PROJECT_CONTEXT/`。`.157` 工具报告为 119 项、`.158` 为 123 项静态／工具测试通过；并不代替 ROM 链接、Bank 空间或真实游戏的额外全量验证。Gold 原版关卡室内仍待后续专项。

### GATE-5.62.159–160：室内外填充区块要独立转换（用户实测外围通过）

- **失败原因**：Gold 关卡室内的 `.blk` 只有 5×4 的有效区块，但 RPP `data/mapObjects/JohtoRoute31VioletGate.asm` 的首个 `db` 是独立的地图边界填充 metatile ID。旧 RPP `GATE` 的 `$0A` 并不能直接沿用于重编号后的 `JOHTO_GATE`：新 `$0A` 已是房间内部合法墙/地板区块，故地图有效范围外出现重复素材。只检查 `.blk` 室内像素、碰撞不可通行不足以发现问题。
- **工具层修复**：`johto_indoor_tiles_converter.py` 预留独立的黑色外围区块及图块编号；`johto_indoor_border_adapter.py` 检查占用槽、不可通行白名单、调色、源图像与完整外围预览，并只向外部隔离目录生成源素材候选。后续新房间必须同时核对 `.blk` 布局和 `mapObjects` 边界 ID，不能复用旧 Tileset 的数字编号。
- **功能层修复**：`.160` 保留原 13 个室内区块及 5×4 布局不变，在 `johto_gate.bst` 尾部追加 `$0D` 黑色不可通行区块（使用 8×8 图块槽位 21，GRAY 调色），对象表外围 ID 改成 `$0D`；`johto_gate.png` 是源码，`*.2bpp` 是被 Git 忽略的构建产物，必须由专用 Makefile 规则生成完整 96 槽图集，禁止放进补丁。
- **验收证据严格分层**：离线测试记录为脚本阶段 138 项、完整功能候选阶段 139 项（均 0 skip），双源码静态审计与补丁正反应用通过；**用户实测确认黑区杂图消失、房间显示正常**。这不代表每格碰撞、所有调色环境、完整存档/飞空链路或其他室内地图全部通过。此次没有编译 ROM、没有执行 Git Commit/Push。
- **已稳定逻辑不回退**：`.157/.158` 的 Route15 风格双向 Warp、立即反向进出和过渡房间地点提示已有用户实测通过，外围/室内美术改动不得再次接入 `$40` 踩格自动 Warp，也不得移除中性门房地点屏蔽。
- **音乐后续独立处理**：项目已有金银音乐资料，但地图音乐绑定与室内外切曲需要对照 `data/map_songs.asm` 和地图元数据另开功能专项；本次 `.160` 不包含音乐文件或映射修改。
- **提交与补丁基线**：用户 `.160` 工作区导出相对已提交 `.158`，不是脚本 A/B 两批均已 Git 提交。清理只追加根目录 TODO/踩坑记录和独立 Git 日志；工作区已应用 `.160` 时只能用文档增量，**不要再叠加 .160 功能补丁**。若按纯脚本与功能分两次 Git 提交，应先暂存 `tools/` 更改，再暂存非工具功能与清理文档，并在合并后执行完整回归；脚本单独暂存时仍可能依赖随后才注册的 `JOHTO_GATE`。


### P16C 地图西侧边界绘制二路径遗漏和复制右半栋

P16B 只在 Warp 完整加载 `LoadMapData` 后补边；从 33 号道路直接进镇走 `.ordinaryConnection`，只调用 `LoadTileBlockMap`，因此左侧第一次仍是全局树背景。且原补边错误复制 `$09/$1e` 右半栋，正确应取同一 Gold 图块集的 `$08/$1c` 左半栋。今后凡补绘 WRAM 地图缓存，须审核所有实际 `LoadTileBlockMap` 路径（至少全图与快速连接），验证图形拼接方向而不只比较块 ID；故障注入须能抓漏任一路径和左右半用错。

### P16D 门房视觉/地点两种重复遗漏（GATE-5.62.200，手机待验）

- **不能将 Gold `EastWestGate` 的 13/13 block、22/22 像素一致等同于 CGB 调色一致**。原 `JOHTO_GATE` 紧凑图块 `tilepal` 中 11 个标签与 Gold `gfx/tilesets/gate_palette_map.asm` 不同。导入图块时先确认原始 tile ID -> 紧凑 tile ID 的重映射，再逐个比较 palette tag 与实际 `map_palette_sets`、RGB；静态源归属匹配也不等于模拟器 VRAM palette 已验收。
- **门房可能复用 `$FC`，地图名中性判断必须同时检查原生地区+局部 ID**：Route31 第一门房早用旧地图 ID 检查，而新南门房之前未加入 `engine/overworld/map_name_sign.asm` 的中性注册，错误弹 Route34。保留原版 Route34 Town Map 地标供地图定位，不靠篡改 landmark 或广泛屏蔽 `$FC` 掩盖弹窗。
- **新增 Gate 最低准入条件是行为链，而非文件存在**：`tools/johto_door_contracts.json` 的每个 `GATE_INDOOR` 必须登记真实执行的 `(1) neutral_name_sign_test_id`、`(2) gold_palette_test_id`、`(3) runtime_palette_status`（PHONE_PENDING 或 PHONE_ACCEPTED）；缺项硬失败。配套测试故意去除属性或执行测试登记必须失败。室外相邻边框、门内两格步行、朝向、反向 Warp、地图加载两路径及调色表现仍有独立验收要求。
- **本轮截图差异并非实机已解决**：截图里拱形装饰仅颜色0从 Gold 米白偏到 RPP 黄绿，其他深色接近；源码逐图块标签修正不证明现场调色索引或加载路径正确。手机仍出现差异时，优先检查 CGB palette slot 和 attr 映射，再做局部修复，禁止盲改整套室内绿色 RGB。


## LEDGE-5.62.208：强制移动队列和落地动画必须共同收尾

`.207` 实机显示 Ilex Forest 跳跃可能停在障碍格。根因候选是 `_HandleMidJump` 在一格走完的 `wWalkCounter=0` 边界，未检查 `wSimulatedJoypadStatesIndex>0` 就清掉 `wd730.7`，使下一格模拟输入无法执行。`.208` 已在 ROM0 公共 `HandleMidJump` 包装器补“队列尚有输入则不得落地”，并为所有跳崖统一补“队列耗尽但动画未完则不接受新方向”，撤销 `.207` 的 Forest 专用队列清零。森林还是两格，旧 Route29 等还是三格。新增 `tools/tests/test_ledge_regression_208.py` 测试格间零计数与强制输入的不同帧时序。状态仅源码候选／静态测试通过，ROM/实机仍未验收；严禁把其称作已修复。详见 `docs/LEDGE_RUNTIME_CONTRACT_208.md`。


### ILEX-5.62.217：Gold HOP 的第三格不是落点，数量相等不能证明跳崖齐全

- 桧皮镇 `(10,6)` 的 Gold `HOP_DOWN` 是正常跳崖：第一格 `(10,7)` 墙，第二格 `(10,8)` 地面，**第三格 `(10,9)` 墙**。旧 `.195` 安全预筛错误要求第三格可走，因此 `.azaleaHops` 缺一条，视频中标志牌附近跳不下去。Gold/RPP 统一跳崖应核对第二格合法落点；第三格墙/树不应令起跳点被剔除。修改游戏公共模拟输入次数前务必验证真实落点和动画边界，切勿把队列长度等同于实际跳过格数。
- 原 `ledge_regression_audit.py` 把 Route31 误按宽度 10 解码，真实地图 20 个 block 宽；统计仍显示 14 条而不报错。以后必须同时校验地图注册尺寸、Gold 源 `HOP_*` 每个方向与 RPP 实际触发的 **(x,y,dx,dy) 集合**，不能只查 `len(...)`；新增 Johto 户外地图时即使表面没有问题也要查 Gold 是否有 HOP。
- 当前含 HOP 的 8 张城都地图对照 112 条方向；关东只做 RPP 图块配对库存扫描，不可宣称已做原版角色碰撞全域校验。`.216` 森林视频支持观察路径的改善，但桧皮镇 `.217` 等新补丁仍待玩家实机确认；静态检查不是 ROM/手机逐帧测试。旧 `.133/.208` 的“三格必然落地”等说法是各自历史假说，不可拿来替代新版本的实测证据。


### .224 门房重复事故的防线（行为/画面/空间是不同门禁）

- 已有 `johto_door_contracts.json` 的八类证明 ID 仍可能掩盖“脚本只跑了，但脚本自己没有真正执行 ASM 判断”的漏洞。现新增 `gatehouse_runtime` 和 `johto_gatehouse_behavior_audit.py`，解析实际 `Warp/目标槽位`，逐条模拟现有三套方向 selector 的受限指令并比对 Gold。未知指令必须 FAIL，不能用 `in` 断言代替语义测试。
- EAST_WEST 南门房为碰撞式、原 Route31 为 legacy collision；NORTH_SOUTH 北门房的踏格规则与 .224 Route35 室外门毯的 collision-only 不同；到达后 `D_*` 是第三个独立机制。写错其中任何一个，单测的故障注入必须直接 FAIL。
- 从 `.224` 两段新旧视频不能得出全部逐帧操作等价。室内图块布局可以比 Gold、到达步进 mask 可静态检查，角色是否偶发卡门仍要真实 ROM/模拟器按键测试。
- 顶部/底部树林残留发生在外部 map border 的 **full load + ordinary connection** 两条路径；缺任何一条必须失败，不能只检查图块素材存在。
- ROM0 新增需求是独立硬限制；门房开发不得凭 Python 绿灯直接发 ROM 候选，RGBDS 链接与 MAP 证据必须有，缺少构建环境则明确标记未编译。本轮门房审计工具只修改 Python/JSON/文档，游戏指令没有变化。

### 城都固定 ID 预留与活跃地图切勿混用（ASM 硬合同）

- `constants/johto_fixed_map_ids.asm` 已由 `constants/region_map_constants.asm` INCLUDED，集中声明 21..221 的 **永久预留** local ID。原来 0..20 的 `JOHTO_*_LOCAL_ID` 保持原定义；不要在区域支线或另一文件重复 DEF，也不要按照开发顺序重排。
- `DEF JOHTO_ROUTE_42_ECRUTEAK_GATE_LOCAL_ID EQU 62` 只表示编号属东线，并不表示地图已经安装。`NUM_JOHTO_MAPS`、Johto Header/Bank/别名/音乐表当前仍是紧凑 21 行；只改 ID 常量绝不能直接允许跳号进地图。任何新增 Warp、Save/Continue 或 Town Map 行都必须走 C 的正式登记与稀疏映射审计。
- 正常 `make` ROM 对象编译前依赖 `johto-id-preflight`；离线可执行 `make johto-id-preflight`。Gold 368 项对照在 `tools/johto_gold_map_reference.csv`；不能把 Gold (mapgroup,map number) 或 `$FC` 兼容句柄拿来做固定 local ID。
- 动态读取 active table 的 `LoadTownMapEntry` (4-byte stride) 和 `GetJohtoNativeMapSong` (2-byte stride) 在未来活跃槽达到 64/128 时分别有 8 位偏移回绕风险；完成稀疏映射的前置任务时统一处理。当前变更没有迁移任何运行时数组，不是实机验收报告。


### 固定 ID 清理后的防误报约定（BANK-5.62.225）

- `johto_fixed_id_audit.py` 未提供 `--gold` 时只验证仓库内 Gold 368 项 CSV 的冻结完整性，绝不写“外部 Gold 源码已再次核对”。正式原版复核带 `--gold`。两条路径有不同成功输出和负向测试。
- 固定 ID 常量属于编译源码，但不是注册表项；不要为了让 Route42(ID62) 被加载而把未开发 23..61 伪装成空 Header，也不得擅改 `$FC/$FE/$FF` 兼容句柄。所有 runtime 稀疏索引改造须先做独立功能补丁和手机回归。
- A/B 文件白名单校验要对实际改动清单显式运行；正常 Makefile 预检只保证编号合同，不会自动检测 Git 分支角色。提交前由 C 验证每次增量的文件归属。

### 缘朱西门图块与 Fly 错图：同值 selector 不等于相同实体地图

- Gold 缘朱原版西端是平面道路出口，真正的 `Route38EcruteakGate` 是一张尚未接入的独立地图。强行把西边 2×2 block 改成别的城市房屋屋顶会显示成错位叠楼；当前必须保持 Gold `.blk` 和边界拦截，不能以假建筑代替门房。
- 满金与缘朱共同用 Fly-only `$FE` 并不意味着物理地图身份相同。旧版菜单项编号保存在 `$cd3d` 共用 scratch，飞行中可能被覆盖。Fly 确认时应冻结 `(region, local ID)` 的 local ID 到独立 `$d7ab`，落点选择/物理地图恢复均从该稳定标记读取。原审计只核对落点数据存在而漏掉传递过程；新增丢失标记、回退读取 `$cd3d` 的负向测试。ROM/手机验收仍由用户完成。


### ECRUTEAK-5.62.225 阶段收口：邻图外观不是城市内部图块，Fly 目的地必须沿途保持物理 ID

- 用户 Gold/RPP 截图指出缘朱市西口一度为拼错建筑，随后还原原版城市 `.blk` 后又显示默认树林。**原因层次不同**：拼楼是曾把城市西侧 2×2 区块当作门房并误用其他建筑 tile；树林来自尚未登记 Route38 邻图区块的屏幕边界预览。右侧看起来正常不能推出西侧已经达到 Gold 视觉一致。用户接受西侧树林暂留到 Route38/门房施工，届时必须检查普通连接和全图加载两路径的邻图预览，不能再次用假房屋填充。
- 上轮 Fly 选择缘朱后曾飞错城市：原逻辑对共用 `$FE` Fly-only 选择器复用 `$cd3d` 暂存菜单项，长期跨越 Fly 执行流程不安全。最新源码在确认时将目标 Johto local ID 保存到 `$d7ab`，由此决定实际 Warp 和落点；项目现有 `johto_fly_destination_audit.py` 检查菜单到实际目标的来源链，并含错误目标/旧暂存读取的负向用例。用户反馈“这些飞行地点对了”，仅代表观察到的飞行目标已恢复，非全部 Fly/Continue 组合的实机覆盖。
- **分线仍有前置条件**：23 张现存地图 0–22 的静态登记不等于支持 ID62 跳号运行；先完成共享 stable-ID→active-slot 映射、ROM/MAP、用户运行回归，再由用户从真实新 Git HEAD 启动 A/B。地图开发第 1 阶段的 Surf/Fly/骑行/可见边缘必须逐项记录，NPC、可选 Headbutt/事件可以留到后续阶段，但不能把延期记成 `PASS`。


### OLIV-5.62.241：双民宅批量移植与被动 NPC 收口

- Gold `OlivineTimsHouse` 和 `OlivineGoodRodHouse` 都有一名 Fishing Guru，原版坐标 `(2,3)`；Tim 慢速原地随机转头、红色调色；Good Rod Guru 固定朝下、绿色调色。RPP 不可复用一个 Sprite ID 再假设对象层的调色参数自动生效，应共用素材并用独立图像 ID／PaletteAssignment 映射。
- NPC `object` 记录使用 RPP 引擎格式，不要把 Gold `object_event` 参数原样贴入；地图碰撞、精灵 12-tile VRAM 判定与两种调色均需审计。共享 House1 图块不代表共享剧情。
- “人物按 A 无响应”必须在文字窗／Script Dispatch **之前**跳过，仅限定 Gold 两张已开放的民宅和目标 NPC。不能用坏指针、`db 0`、空对话文字冒充无响应。尤其 Tim 房书架 sign text ID `1` 与 NPC 的 sprite index `1` 同值：还必须核验面前的目标格 `(2,3)`，保留原书架互动。
- **初版双房漏登记到达自动步进**：第一间民宅 `(29,11)` 已有 `D_DOWN`，首轮新增 Tim `(25,11)` 与 Good Rod `(13,15)` 时只登记了 Warp，却漏了到达后的向下步进，角色停在室外门砖上。修复两条精确 arrival-step，并在现有审核里同时检查 Gold 门砖、回程目的地、玩家落点／马上反向复入；“能够传送”不能等同于完整出门行为。
- **旧测试随活动地图扩张失效**：本次最初完整门禁运行 994 项、12 FAIL／2 ERROR，原因是历史测试写死 46／47 地图、最后一个门房／地图条目、旧 `.gateVertical` 的 `jr` 分支、`SPID` 版本前缀和稀疏映射表尾注释。只修复这些工具测试的真实锚点，保留删除／错误注入必须 FAIL 的负向行为，不修改已经验收的运行时 ASM。重新完整执行发布门禁 994/994、0 skipped、56/56 连接 PASS，Gold 来源 367/367 PASS；源码级 23 图、171 边、0 failures，仍非 ROM 编译或手机全路径证据。
- **用户反馈边界**：用户先确认两间新民宅出门自动行走修复正常，随后视频及文字确认两名 NPC 可见、面对玩家按 A 后转向且无文字，并表示没问题。只登记上述可见场景验收；不声称所有昼夜调色、存读档、长期随机转向或特殊事件已通过。Tim 交换与好钓竿赠送仍延期；用户新 ROM/MAP 原件未提供，本轮助手没有编译／链接 ROM。
