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

