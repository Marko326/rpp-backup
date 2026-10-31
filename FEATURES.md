## CLEAN-5.62.296｜37号路／圆朱市及开发者Surf门禁正式收口（2026-10-31）

- **已确认基线**：用户新上传的`FIX-5.62.290.zip`中`RPP_PROJECT_CONTEXT/02_EXPORT_INFO.txt`记录分支`常规功能备份`、干净HEAD `a6141c690bb7bf6fca128011498cac2526124666`，已完成此前`.290`双提交。`.293～.296`属其后累计开发状态，不能倒退用旧`.282`HEAD；当前游戏字符串为`FIX-5.62.295`，测试字符串`TEST-231`保持不变。
- **用户反馈范围**：`.295`圆朱市冲浪无法下水问题已由用户回复“没问题了”，其他所见暂无新问题；这不代表所有地图、所有ROM色版及所有Save/Continue路径都逐项完成验收。本轮清理只改说明与交接文档，不改游戏ASM／Makefile／ROM0／存档结构。
- **模式A两笔提交**：第一笔为37号路、圆朱市运行资源／Field Moves和`.295` Surf修复；第二笔为`.293～.296`的Gold/NPC来源准入、真实执行入口与水域清单、错误注入及长期文档。游戏运行`scripts/*.asm`只能在第一笔；开发者Surf审计绝不能绑到用户`make`中。
- **三件套**：①当前已打上`TOOL-5.62.296`的工作区→本轮清理文档增量，②最终状态→仅功能状态的工具/审计反向隔离，③该 `.290` 干净HEAD→完整最终状态的累计全量；①与③互斥。两份中文日志分别用于功能、工具提交；用户自行核对HEAD/index并Commit/Push，助手不操作用户Git。
- **下一批禁止偷跑**：Route38、圆朱西门房仍停留在`candidates293/`，没有运行Header/Warp；成熟NPC碰撞差异、内部门毯回程陷阱及Bank/边框必须先过审。最新`.295` ROM MAP未提供，ROM0≥64B和ROMX Bank空间仍待新MAP验证。完整交接包见`JOHTO_296_HANDOFF`，附Gold+NPC+当前源码与来源说明。

## TOOL-5.62.296｜开发者修改地图时主动执行的Surf运行链审计（不挂用户编译）

- 用户明确要求：风险必须由开发者在写图期间主动发现并修复，不允许把失败拖到玩家本机编译阶段。**禁止把Surf审计强行绑入Makefile、RGBASM或RGBLINK。**
- 每次新增或修改地图/水格/技能分派，开发者立即执行 `python tools/johto_surf_dev_check_296.py --project . --gold-root <完整Gold原版目录>`；根据原始Gold水格枚举活动地图，验证按A与道具下水、四方向步进、ROMX水上移动与安全上岸、ROM0返回标志及全部注册地图Bank/角色合同。
- 审计必须自行运行新活动图未登记与真实ROM0移动分派断开的故障注入；Fail就停在开发者本地修改，修好后重新跑。交付前还须完整Gold综合审计与全量测试、补丁回放；项目文件不依赖用户运行该脚本。
- 新增的 `tools/johto_surf_active_water_manifest_296.json` 锁定活动地图和Gold水坐标，`johto_surf_manifest_from_gold_296.py` 仅可在真实参考复核后更新，不能为消除告警盲目重生成。静态通过不等于ROM成功链接或真机实测。
- 本轮**仅工具/测试/文档变更**，不修改已验收的`FIX-5.62.295`游戏版本与`TEST-231`，不修改ROM0或游戏运行代码。

## FIX-5.62.295｜圆朱市冲浪运行入口修复（待实机验证）

- `.294` 圆朱市20格Gold水角色已登记，但 `JOHTO_PILOT` 冲浪移动分派缺失对应Map ID，错误回退旧图块；接上 `.southModern` 的Gold水与安全岸边探针，并新增全活动地图Gold水覆盖的真实执行路径门禁。`TEST-231`不变，ROM0不新增指令。

## MAP-5.62.294｜37号路与圆朱市运行资源、双向连接及审计

- 在已检验的 MAP-293 Gold 资源基础上，接入 Route37 与 EcruteakCity 运行 Header、双向 NORTH/SOUTH 邻图镜像、稳定 ID/28 活动槽、ROMX $51 同 Bank 脚本、陆地空间角色、边界分派、音乐／Town Map／地点名。保留 Route38 和圆朱西门房为尚未开放的来源候选。
- 新增 `tools/johto_corridor_runtime_gate_294.py` 并挂入综合审计，针对连接源偏移、显示宽度、碰撞实际分派、同 Bank 脚本和封闭入口设负向检查，不以资料来源检查替代真实运行层验证。
- 项目版本 `MAP-5.62.294`、`TEST-231`。此处为待链接与设备确认的运行候选；缺少用户最新 MAP，不证明 ROM0 剩余 ≥64B 或新 Bank 实际可以链接，也不声称手机验收。

## MAP-5.62.293｜下一段Gold原图及成熟参考准入（非运行地图）（游戏版本仍 FIX-5.62.290）

- 已校验完整交接包，利用既有转换脚本核对Gold Route36→Route37→EcruteakCity，旁路预备Route38西门房和Route38。4张源地图和候选阻挡资源只放在`maps/johto_pilot/candidates293/`，不启用Warp/地图Header、ROM Bank或新Fly目的地。
- 新增`tools/johto_next_corridor_source_gate_293.py`并接入总审计，保护源字节、稳定ID21～24、真实Gold连接偏移及26图未开放边界；新增10个故障注入。详见`docs/JOHTO_NEXT_CORRIDOR_293_SOURCE_GATE.md`。
- 当前游戏版本仍FIX-5.62.290/TEST-231；不把地图源预处理写成可玩ROM。

## FIX-5.62.290｜CLEAN｜35/36号路及自然公园阶段用户确认与工具准入收口

- 截至用户最新 `.290` 工作区，26张城都活动图，涵盖满金北门房、35号路、自然公园及两座公园门房、既有36号路南/东双向连接；37号路与公园剧情仍未开放。用户实机反馈35→36右上残树已解决、目前没有观察到其他问题，不扩大解释成每个功能全部手机验收。
- 本轮清理不改 ASM、图块、地图、ROM或测试版本；正式字符串仍 `FIX-5.62.290` / `TEST-231`，并完整保留用户最新3个ASM文件14处长跳转`jp`修正。
- 现有通用审计 `TOOL-291/292` 已包含在用户工作区：20条有向连接全量登记，7处宽高差风险需各自显示合同；Route30南、Route32北历史残留错误可故障注入触发失败。详见 `RPP_DEVELOPMENT_PITFALLS.md` 首章。以后新增连接未审查必须先报错，不允自动推断预览条带。

## FIX-5.62.290｜Route35北接Route36右上角树林残留（窄图接宽图可视条带）

- 用户 `.289` 手机截图及视频：35号路北向36号路时右上角残留树林；36号路向东桔梗市连接正常，不能重写其边界。旧NPC `.223` 资料 `docs/JOHTO_CONNECTION_VISUAL_223_CLOSEOUT.md` 明确记录同类问题并规定北向预览宽度为 **13列**。
- 根因：`JohtoNorthRoute35RuntimeHeader` 的 NORTH 条带仅从 Route36 复制10列，WRAM第13–15列继续显示默认`$05`，造成画面右上角的树残留。改为 `JOHTO_ROUTE35_WIDTH + MAP_BORDER`（10+3=13），只绘制多出的右侧3列；仍仅允许 Route35 x17 ↔ Route36 x17 越界，37号路继续封闭。
- 旧可执行脚本未随NPC交接包提供，但已在现有 `johto_route36_seam_audit_289.py` 中添加 Gold原始字节、3行×13列、源行偏移、WRAM3+13=16边界容量和负向注入；复制12、10列、超宽14列或错误源行/目标列必须失败。变更不增加ROM0指令，不修改Gold原图、碰撞、Warp、图块集或Bank分配。
- 版本 `FIX-5.62.290`；测试版本 `TEST-231` 不变。仅静态候选，仍需本机重新编译并核对新MAP ROM0≥64B，再重走35→36、36→35以及36↔桔梗，并检查骑车和画面滚动。

## FIX-5.62.289｜打通36号路南侧35号路、东侧桔梗市两条Gold原版无缝连接（开发候选）

- 对照Gold `data/maps/attributes.asm` 与NPC-243成熟阻挡掩码恢复 Route35北↔Route36南的单列x17通行、Route36东↔VioletCity西的y8/9双行通行；Route36北端37号路仍封闭。
- 三张运行地图分处不同ROMX Bank，连接屏幕图块复制先按现有Map Bank读取；因此通过同Bank不可变邻图镜像保证滚屏边界正确，不直接将跨Bank原始块指针放入连接Header。
- 保留Route36遗迹门房及公园东门房4条Warp槽位，不打开剧情、NPC/树、其它边界；脚本和测试增强到真实动态双向连接强制审计。
- 正式版FIX-5.62.289，TEST-231保持不变。当前仅静态候选；用户仍需本机编译Red/Blue，提供最新MAP确认ROM0≥64B，再实机验证步行/骑车往返与滚屏，无Git提交。

## FIX-5.62.288｜公园与两座门房运行回归修复（开发候选）

- 新活动地图在ROMX碰撞分派有注册，但外围移动守卫 `JohtoPilotIsClosedOutdoorEdge` 漏注册公园及两座门房，导致走/骑车可能越过边界到黑区。新增显式守卫，保留仅在注册门毯正方向才Warp。
- 东门房部分Gold原转换角色将成熟可走区标成墙，接入NPC-243独立阻挡掩码（16B）；Park长草按成熟分支恢复4图块下半身遮挡，玩家/NPC共用。全部项目功能仍待新ROM+实机复测。

## FIX-5.62.287｜公园两座门房进入死机修复（源码候选）

- `.286` 的3张公园地图 Header 在ROMX Bank `$50`，却引用 Bank `$4C` 的 `JohtoSouthScript`；`RunMapScript` 在地图Bank内以 `jp hl` 执行脚本，造成跨Bank错误跳转，进入门房后可能死机。改为3张 Header引用同Bank的 `JohtoParkLocalScript`，只执行 `EnableAutoTextBoxDrawing` 后返回，不改变 Warp/音乐/地形。
- 新增全体26张活动地图 Header与MapScript同ROMX Bank检查，验证 `RunMapScript` 必经 `SwitchToMapRomBank` 并原址跳转；故意把任一新地图改回旧脚本必须失败。正式版本 `FIX-5.62.287`，`TEST-231` 不变。
- 36号路稳定ID16一直是活动地图，`.286` 已在其运行对象中追加公园东门房两个Warp（保留原遗迹门房编号0/1），不是整条道路未解锁。此轮仅修死机源，门房及36号路完整实机通路仍需用户新ROM回归。
- 本轮不编译ROM、不做Git提交；需用户本地重新链接、核对ROM0不少于64B并验证南／东门房往返和旧36号路遗迹门房。

## FIX-5.62.286｜自然公园、35号路公园门房、36号路公园门房及道路贯通（离线开发候选）

- 依据Gold原版地图与旧NPC参考接入26张活动地图：公园独立图块与原始540B、两座共用门房分别16B和20B；35号路与36号路原有已验收功能保留。
- 启用南侧与东侧门房精确方向与目的槽的双向Warp；旧36号路遗迹门房的两个源Warp槽位不变。门房内音乐继承与骑车禁止、公园骑车许可、Gold地形阻挡、地点名称及Town Map同步维护。
- 公园NPC、捕虫大赛、北侧其他入口及35/36号路直接无缝连接暂不开放；不可把地图静态审计通过等同于ROM链接、边缘显示或手机验收。
- 版本FIX-5.62.286，TEST-231不变；不得将自动生成2bpp纳入提交；本机需新Red/Blue ROM和MAP，ROM0至少64B。

## FIX-5.62.285｜35号路栏杆碰撞真实入口修复（待实机验证）

- 实机视频 `62987.mp4` 证明：35号路从满金北门房出去，左侧视觉栏杆可被步行/骑车穿越，而右侧外观相近栏杆正常。`.284` 把国家公园入口 `(3,5)` 加入 `JohtoSouthMatureDoorFence`，却未验证这条函数能否在普通移动路径被调用；因此属于修错层级。
- 根因：`JohtoOverworldSouthLandDecision` 的地形分派只接收稳定ID10～15。新增 Route35(ID17) 与 Route35GoldenrodGate(ID18) 遭 `.route33` 回退，E=2 进入旧的 8×8 图块碰撞；因此 Gold 16×16 `Route35.roles.bin` / 门槛封锁和骑车通用规则均不能被可靠执行。
- 修复：在 ROMX Bank `$4F` 的入口显式检查 ID17、ID18，并汇入原 `.activeSouthMap` 的 `HandleLedges → JohtoSouthSpatialStep`；旧10～15和 Route33 继续原路径，**ID16 Route36 不纳入此范围**。不修改ROM0指令、不编辑Gold `.blk`、角色表、门槛和Warp、地毯、Surf/Cut、音频或存档结构。
- 新增强制审计及4项负向测试：删掉17、遗漏18、误把16接进分派、丢失公共执行入口必须失败。项目版本 `FIX-5.62.285`；测试版 `TEST-231` 保持不变。旧 `.284` MAP不能证明本次ROM链接余量，手机与新的Red/Blue ROM/MAP仍待验证（ROM0≥64B）。

## FIX-5.62.284｜35号路南边框、国家公园门槛及北门房行为审计（开发候选）

- 用户 `.283` 视频和截图暴露南侧树林补图、可横穿的未开放公园入口和门房落点疑问。Gold 原图及旧 NPC `GATE-224` 资料均齐全；发现 `.283` 实际对象的 DESTINATION ordinal 写错：满金→门房写0而应2，门房→满金写2/3而应都为0；已修正。不改原 Gold `.blk`、活动图数、原有双向 Warp 目标和存档。
- 从同 Bank `$4E` 后置缓冲分发补充 `PatchJohtoRoute35SouthBorder`，对 Route35 南缘补齐3×10个已经在 NPC-243 验收的 JOHTO 图块集安全预览字节；保留 Azalea 西墙、Goldenrod 北边框，加载后单次 ROM0 跨Bank钩子不增加调用。图块集不同，不盲目直接复制 JOHTO_MODERN 块号。
- 对照旧 NPC 原始阻挡掩码与 Gold 角色表：Route35 `(3,5)` 是未开放国家公园入口应封闭，外侧 `(9/10,33)` 为合法双车道地毯必须可停留、左右移动，仅在其上按 DOWN 碰撞时才 Warp。
- 保持已登记 Gold 0-based 目的槽与落点：城镇 `(19,1)` 到门房 `(4,7)` 不额外步进；室内北口出去到 Route35 `(9/10,33)` 不强制步进；从 Route35 进门房北口 `(4/5,0)` 自动向下1步；从门房南口回满金 `(19,1)` 再向下1步。加强运行审计确认合同与实际选择路径。
- 新增/强化失败注入防止漏掉南部预览、破坏任一行数据、误放开公园入口、缩窄合法地毯与改坏到达步进。所有静态结果都不代表手机实测；用户须本机编译链接并检查 ROM0 最新 MAP ≥64B。
- 游戏正式版升至 FIX-5.62.284，测试版 TEST-231 不动，不提交 Git，不生成 .2bpp / ROM 构建产物。基线为用户已打上 `.283` 的工作区，累计全量仅适用已确认 `.282` Git HEAD 2b171bcdcfa8a08570d19af136f9ee6d02f5cb0b，两者互斥。

## FIX-5.62.283｜满金市北门房与35号道路运行接入（静态开发候选）

- 基于已提交的 FIX-5.62.282（HEAD 2b171bcdcfa8a08570d19af136f9ee6d02f5cb0b）接入新地图两张：Route35GoldenrodGate 和 Route35；活动地图数 21→23。游戏显示版本提升至 FIX-5.62.283，测试版仍为 TEST-231。
- 使用交接 Gold `Route35.blk` 180B、`NorthSouthGate.blk` 20B、既有成熟 JOHTO_GATE 布局，精确注册满金市北门、门房两侧双向 Warp；Route35 → Route36 无缝连接及国家公园室内入口保持关闭。
- 按现有音乐继承与 Bike Song Off 同曲不重播策略接入第6座活动门房；重新核对中性地名牌、Town Map、两格门毯的左右移动、Route35 水格及单棵 Cut 树（$5B→$90）。
- 工具审计必须验证23张活动地图注册、Gold 资源逐字节、6座门房双向来源、合法 Warp 不与未开放门槛重叠、未开放出口保持关闭；原21图功能不可被弱化。
- 此版本仅是静态开发候选，需用户本机 Red/Blue ROM 构建及最新MAP（ROM0保留≥64B），再做门房、骑车/步行、音乐续播、Cut/Surf及地图滚屏实机验收；未自行链接ROM或修改用户Git。

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

## TOOL-5.62.278｜桐树林北出口至34号路、满金市通路强制复检（离线工具候选）

- 使用现有 `johto_rpp_pipeline.py --adjacent-pair Route34 GoldenrodCity` 验证 Gold 两图可批量预处理，原版无缝连接北 -5／南 +5；这两张图连同桐树林北门房已经是 `.276` 的21张活动地图之一，本次不重复新增地图。
- 新增 `tools/johto_route34_goldenrod_audit_278.py`，并并入城都总审计：同时核对 Gold 和 RPP 地图原始区块、ROMX 双向连接 Header 指针／复制宽度、北门房两条 Warp、边界精准放行列、关闭的建筑门与从门房到满金市城区的陆地实际连通性。验证仅静态，不能替代屏幕滚动、完整地图预览与手机运行。
- 更新已过时的吉花市门口 ROM0 单层断言和 Route33 直接 `callab` 形态断言，按现行 ROM0→ROMX/E 返回契约检查；ROM0 64B 负向测试改为显式注入 32B 旧MAP，不再将已链接的85B最新MAP误判失败。保留失败注入和全部64B安全门槛。
- 本批仅改离线 `tools/` 与文档，`FIX-5.62.276`、`TEST-231`、地图与森林 ASM/PNG、活动地图数量、ROM0及已验收 `jp` 均不变。开发态仅交两份互斥补丁，不生成正式 Git 日志，不构建ROM、不Commit/Push。用户设备仍需实测北门房进出、34号路北段连接/返程、满金市边缘滚动、Cut/Surf与昼夜。

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

## FIX-5.62.275｜桐树林成熟碰撞/Cut/Surf/配色与桧皮镇西门房外景

- 还原 NPC-243 ILEX-217 的完整96项森林调色板、216字节阻挡掩码与地图专属步行/Cut逻辑；修复未砍 `$0F` 错误继承 Carry 并误判 `$2D` 已清除。
- 在现有 Gold 水格分派之外添加安全登陆判定，利用森林成熟步行掩码而不是空的 `.tilecoll`；保持关都、已验收跳崖、北洞口与自行车规则不变。
- 复用 GATE-202 桧皮镇室外左侧屋顶/墙面边框补丁，作用在地图块完整加载之后，不改 Gold 原版 `.blk`。
- 全部新增行为和负向故障测试均为静态验证，尚未取得新 ROM/MAP/设备验收；ROM0 加载钩子需用户本机链接核对64B安全余量。

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

## FIX-5.62.272｜ROM0 城都陆地碰撞分派外迁（开发候选）

- `.271` 新增跳崖跑步保护后，用户本机再度链接失败：`Home Copy Data` 无法放入 ROM0。根本原因是 ROM0 长期接近满载，而非 `CopyData` 例程有错。
- 将 `CollisionCheckOnLand` 的樱桃市导览之家入口例外、南线六图与33号路跳崖／地形分派迁到 ROMX Bank `$4F`；ROM0 仍保留前置区域边界、精灵与城都外门守卫，并按 E=0允许、E=1阻挡、E=2回退原生图块规则决定结果。原 `HandleLedges`、`JohtoSouthSpatialStep`、`JohtoRoute33StepPolicy` 不改。
- 这段 ROM0 的指令编码预算由 124B 降为25B，**源码估算释放99B**；历史 `.270` MAP 的26B余量不能证明 `.272` 已能链接。原有新编译 MAP ROM0 至少64B 的安全门槛仍保留。未编译 ROM，不执行 Git Commit/Push。
- 保留用户的 `jp` 跳转、PNG 源文件／自动生成 `.2bpp` 流程，正式版本 `.272`，`TEST-231` 不变。专项门禁与故障注入覆盖 ROM0 预算和跨 Bank 的三态返回语义。

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
