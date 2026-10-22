# 城都门房开发必读｜JOHTO_GATEHOUSE_READ_FIRST

> **强制入口**：以后只要新增、开放、修改门房／双格关卡出入口（含外侧边界、室内图块、显示地点名），必须在修改源码前读本文件，然后对照已实机验收的 **31号道路—桔梗市门房** 与 **桧皮镇—桐树林南门房**。登记 `tools/johto_door_contracts.json` 的 `gatehouse_guide` 与八项 `gatehouse_proof_ids`；工具自动要求每项证明对应的 unittest 真正执行。不能以「Warp 坐标对、静态全绿」代替游戏表现。

## A. 两格门口的行为合同：禁止反复卡门

1. **先读来源**：Gold `maps/*Gate.asm` 的入口对、Gold 入口碰撞类型、RPP `data/mapObjects/` 的 0-based Warp 索引。室外、室内、未开放的另一侧逐一列出；未开放出口不能留误触发的空 Warp。
2. **地图身份**：原生城都地图复用 `$FC`，所以判断地图必须是 `REGION_NATIVE_MAP_SLOT + MAP_REGION_JOHTO + local ID`，不能只按 `$FC`、图块集或城镇地标判断。
3. **Warp 触发与到达步行分开审核**：必须以 Gold 原始 `.blk` + `tilecoll` 的实际碰撞角色为准。`WARP_CARPET_DOWN/LEFT/UP/RIGHT` 都可站立，只有朝碰撞编码的方向尝试移动才 Warp；不得登记成 `STEP_ON`。Gold `DOOR` 是另一种实体门，按原版使用踏格触发。切图后是否走一步独立登记，按 **Warp 目标格** 的 Gold 碰撞类型审核，绝不能从源门毯或南北布局推断。
4. **立即反向复入**：两格分别反复“进→立刻出→再进”，不准要求先退一步；跨图后角色控制、落点、方向、步进状态必须正确。对照现有 `CheckWarpsNoCollisionLoop`、`CheckWarpsCollision`、`IsPlayerFacingEdgeOfMap`，不得新造专用踩格自动传送。
5. **旧地图保全**：31号道路—桔梗市门房、关东 Route15 等原有门房、已开放洞穴、Fly、保存/读取不能因新的门房坐标特判回退；门房和洞穴的碰撞机制不能混用。

### A2. 竖向门房到达步行不能靠方向默认（ILEX-5.62.215 后强制）

- 门房 Warp **触发方式** 和 **切图后自动走一步** 是两项不同设置。不能把“禁止踩格传送”理解成“禁止切图后一步”，也不能以“南北门房”为理由让上下两边都走一步。
- **35号道路南端入口（`.224` 用户验收的正式规则）**：外侧 Warp 位于 `(9/10,33)`，先从 `(9/10,32)` 向下走上门毯**必须允许停留**，毯上左右换 Lane 不能传送；再次朝下碰撞 `(9/10,34)` 时才通过既有 `ExtraWarpCheck → CheckWarpsCollision` 进入门房。Gold 全门房碰撞盘点还发现：Route34 `(13/14,37)` 原先保留的 `.215 STEP_ON` 例外实际是 `WARP_CARPET_DOWN`，与 Gold 原版矛盾，已由 `.237` 统一改为 collision-only。Route34 外侧与门房室内南侧 y7 都是方向门毯；只有室内北侧 y0 的 Gold `DOOR` 保持 STEP_ON。进门/出门后的自动一步仍独立按目标格规则处理，不能由门毯触发方式推断。
- 每个新增 `GATE_INDOOR` 必须在 `tools/johto_door_contracts.json` 记录 `arrival_step_review`：`layout`、每侧 `by_gate_side`（`NONE` / `D_UP` / `D_DOWN` / `D_LEFT` / `D_RIGHT`）及 `basis`。`johto_door_onboarding_audit.py` 缺少字段必须失败。复杂的 VictoryRoadGate 先走人工专项，不能伪装普通双格门房。
- Gold 原版 `warp_event` 只证明位置/目标，**不能证明** RPP 自动模拟移动。运行时继续用 `GetJohtoWarpArrivalStep` / `PlayerStepOutFromDoor`，必须先核对目标格及一步后碰撞与可回程性。独立检查起始侧两条 Lane、四个方向、错误来源、菜单/读档状态。
- `.215` 北门房：**抵达北侧 y0 的 Gold `DOOR`，自动向下 1 格；抵达南侧 y7 的 `WARP_CARPET_DOWN`，不额外走**；森林 `(1,5)` 作为目的地的 Gold 实体 `DOOR`，向下 1 格仍由精确规则控制。这里的旧 `.215` STEP_ON 例外只适用于实体门格，不适用于 Route34 外侧 `(13/14,37)` 地毯。不要恢复 `.214` 的双向自动步行。
- 未来门房开工先运行现有 `tools/johto_warp_reference_profiles.py --inventory-gold-gates`，查看 Gold 全门房拓扑及 `SCRIPTED_ACCESS_OR_MOVEMENT` / `TWO_LANES_TO_ONE_DESTINATION` 标记，不能机械照抄。

## B. 外面建筑完整：两条地图加载路径都要查

1. 核对 Gold `.blk` 和 blockset 的**左右半边图块**：不要把右半屋顶/墙壁复制到左边；桧皮镇西侧左半为 `$08/$1c`，右半为 `$09/$1e`。这个示例只适用于该图块集，不允许对别的地图照搬编号。
2. 若建筑贴着地图边缘，区分实际 `.blk` 与图外 border buffer；只能局部补绘，不能把全图树林填充改为房屋。
3. 至少检查 **Warp 完整加载 `LoadMapData`** 和 **从相邻道路连接快速进入 `.ordinaryConnection`** 这两条 `LoadTileBlockMap` 路径；必须在正确的地图身份下、VRAM 出图之前生效。
4. 视觉反例必须包括：首次从道路进入不会看到四棵树；门房回程后不会突然出现重复的另一半建筑；切换门房后外观不能改变。

## C. 室内素材与调色：四层来源不得互相替代

1. 源 Gold 图块像素、源 blockset `.blk`、目标 `JOHTO_GATE` compact `.bst` 必须**按真实格子逐项还原 source→compact 映射**；禁止把排序后的 Gold tile ID 当目标 compact ID（P16D 事故令 10 个图块错配、整房变绿）。
2. `tilepal` 标签、实际 palette-set 绑定、**四个真实 RGB 颜色值**，均须分别审计。标签同名≠颜色相同（P16F 半圆装饰问题）。比对 Gold `gfx/tilesets/bg_tiles.pal` 与 RPP `color/data/map_palettes.asm`。
3. 门房专属差异只能通过 `JOHTO_GATE` 的隔离 palette（已用独立编号 0x28/0x29）处理。不能修改关东 `GATE`、通用 `INDOOR_GREEN/BROWN` 或为视觉问题整体重排图块标签。
4. **凡修改图块/调色就必须保留旧截图基准**：至少看地板菱形、顶部蓝紫横条、绿色墙柱、半圆下沿、室内黑边，并回归第一座城都门房与关东门房。静态 Gold RGB 审计不等于 ROM 实际画面验收。

## D. 地图提示与其它安全规则

1. 过渡门房默认**不弹地点名称牌**；RPP `engine/overworld/map_name_sign.asm` 的 neutral gate 必须按地区+local ID 分辨，不能把共享 `$FC` 所有城都地图一概屏蔽。
2. Town Map 的原版地标（例如 Route34）与进入门房是否弹出 `Route 34` **不是同一功能**；禁止通过改原版地标解决弹窗。
3. 门房通常下车且不可擅自允许 Fly/Surf/Dig/逃洞绳。未开放的森林/北侧出口保留封闭，勿出现非法 Warp。
4. 门房音乐应使用现有已验收的来源判定，不拿 `wLastMap` 代替正确的进门来源；存档 Continue 后也要确认音乐和门房身份。

## E. 强制准入、证据与最小手机测试

- **工具登记**：每一个已启用的 `GATE_OUTDOOR` 和 `GATE_INDOOR` 都必须登记 `gatehouse_guide`；其中 `GATE_INDOOR` 还必须在 `tools/johto_door_contracts.json` 登记 `gatehouse_guide`、`gatehouse_proof_ids`（八类：双格 Warp、方向/碰撞、立即反向、边界加载、neutral 地点牌、真实素材标签、RGB 与关东隔离、旧门房回归），以及 `phone_door_status` 和 `phone_visual_status`。这些状态必须清楚区分 `PHONE_PENDING`/`PHONE_ACCEPTED`，不能冒称静态就是实机。
- **强制失败**：缺少本文件/登记字段/测试 ID、登记 ID 不在执行清单或测试未真正运行，统一 Gold 门禁 FAIL。新增专门反向测试验证这些失败路径。自动审计保证登记与静态依据，不保证人一定真正读过文档，也不代替玩家操作。
- **最小手机测试**：两格各进各出、立刻反向、门口上下走和侧向擦过；从相邻道路第一次进入和从门房返回的外观一致；入门无多余地点牌；室内主要颜色与原版可接受；抽测旧门房及关东门房；根据实际改动决定是否测试存读档、Fly 和音效。
- **验收等级**：`STATIC_PASS` 是静态代码检查；`PHONE_ACCEPTED` 只代表用户明确看过/测过的特定场景。**不得因旧阶段报告全部勾选就宣称链接空间、所有存档、剧情及未来门房已实测。**

## F. P16 的失败样本必须记住

- **P16A**：踩上两格门垫自动进门、出门不能立刻复入、两格上下不通；错误的测试反而把错误行为当成规范。
- **P16B**：未考虑地图西边框，外面半屋半树林；误用右半房屋区块。**P16C** 再确认从道路快速切图的路径漏补绘。
- **P16D**：进入南门房弹 `Route 34`；随后错误地用排序方式映射紧凑图块，使整间门房变绿。**P16E** 恢复正确编号但未解决半圆亮纹。
- **P16F**：按真实图块对应修正并隔离 Gold GREEN/BROWN 第0色；用户提供 P16F 实机截图与 Gold 同地点 160×144 比对，半圆亮纹及门房背景获视觉确认。允许其它不影响观感的小幅配色差异。

下一张门房动手前必读资料：`docs/JOHTO_GOLD_DOOR_GATE_POLICY.md`、`docs/JOHTO_ILEX_P16_SOUTH_GATE_RUNTIME.md`、`RPP_DEVELOPMENT_PITFALLS.md`；核心自动入口：`tools/johto_door_onboarding_audit.py`，统一静态门禁：`tools/johto_map_release_audit.py`。

## .235C 同包功能收口：禁止只交“会报错的脚本”

- 先升级固化的 `johto_rpp_connection_guard.py` / `johto_gatehouse_behavior_audit.py`，再按其逐格和双格门毯合同调整真实 Header、Profile、登记；专项必须做到合法数据 PASS、退回坏数据 FAIL。不要因为静态地图 `.blk` 一致就认定屏幕 WRAM 邻图已经填满。
- Route43 北口 `x0` 的左屏幕预览占用三列 WRAM border，不增加可通行区域；从外部进入门房返回 Route43 的 `(9/10,51)` 是碰撞门毯，目的地 NONE（不自动 UP），门房上口真正入内的 `(4/5,0)` 仍 D_DOWN。两类目的地不能因“上下门房”类别相同而合并动作。
- 每批给出功能＋审计一起修的可回放补丁与新的候选版本，统一静态审计真实退出码单独报告；ROM/MAP 和手机验收只按用户后续 `make`/视频证据报告。

## .235B 静态假绿审计补强（仅工具修复，不声称修复手机画面）

- **地图树木残留**：以前 `johto_rpp_connection_guard.py` 可检查所有 46 条连接的 Gold 偏移/复制登记，同时漏掉 `home/overworld.asm` 的**真实** BLK 三行/三列复制循环。实测故障注入 `ld c,MAP_BORDER → MAP_BORDER - 1` 后仍为 `46/46 PASS`。现在 `check_native_connection_copy_executor` 在所有连接总审计前检查两套执行内核的每条实际指令及 `MAP_BORDER=3`；复制写入丢失、少复制一行/列都必须 FAIL。该检查不能替代动态镜头/VRAM 截图对照。
- **真实预览道路发现**：过去 Route43 x0 的提前放行分支被原审计器的连续范围正则吞掉，人工 JSON 仅登记 x8..11 仍能放行。现在复用 `johto_masked_step_audit.py` 中原有逐格 ASM 执行器，从原版 Gold 两侧的 FLOOR/FLOOR 地形独立推导合法接缝，再和运行时边缘围栏、登记以及左右两侧的屏幕预览拷贝宽度交叉比对。原始 .235B 在 x0 和左补绘缺失时必须 FAIL。
- **双格门毯行为**：对于成对 `COLLISION_ONLY` 入口，实际自动迈离 Warp 毯将导致第一次按反方向只回到门毯、不能复入。原始 .235B Route43 `(9/10,51) D_UP` 必须被此通用规则拒绝；Mahogany 的单格实心外门依然按旧门房专门合同审核。
- **门房自动行走**：以前 `johto_gatehouse_behavior_audit.py` 只验证步进**数据行**，即使 `GetJohtoWarpArrivalStep` 把无匹配情况默认改成 `D_UP`，也会 `PASS`。现在检查完整到达查询器、`PlayerStepOutFromDoor` 回退分支与 `JOHTO_GATE` 是否被归入通用门砖自动 `D_DOWN` 表。`NONE` 必须是可证明的运行时默认不迈步，而不只是 JSON 自我声明。仍无法由源码静态审计证明逐帧输入的手感或视频中的具体自动走动。
- 这些规则必须经 `test_johto_audit_kernel_hardening_235b.py` 故障注入并在 `johto_map_release_audit.py` 中逐个绑定真实 unittest ID。合法 ASM 内核重构须同期改进审计器并通过新的故障注入，不能为了绿灯直接放宽断言；新图还需要检查可视边框完整覆盖与手机验收。

## G. 必须通过可执行分支合同门禁（ILEX-5.62.224）

本项目的门房行为不是靠“必须读懂说明”来保证，而是靠 `tools/johto_gatehouse_behavior_audit.py` 运行时规则静态执行检查：`tools/johto_door_contracts.json` 的每个 `GATE_INDOOR` 都需要填写 `gatehouse_runtime`，完整的入口坐标和四方向期望、每侧的 step-on/collision-only、真实的目标 Warp slot、上下/左右分组、入门步进与 `NONE`、以及边界补绘策略。脚本解释执行 ASM 的分支、独立比对 Gold 原始入口和图块、执行负向故障注入；缺项和陌生指令均拒绝通过。详见 `docs/JOHTO_GATEHOUSE_EXECUTABLE_CONTRACT_224.md`。

门房测试**只允许一次功能和审计合并补丁**，实机确认前不拆提交、不抹去旧失败历史；新 ROM 必须先确认真实链接和 ROM0 MAP，静态测试不能代替编译或手机录像。

### .229 东西向双格门毯：移动与 Warp 分流必须分别运行验证

- **按布局区别而非按 UP/DOWN 一刀切**：东西向双格门房的上、下两格门毯都属于可行走区域；合法的 `上格 DOWN→下格` / `下格 UP→上格`、从房间内走上门毯，以及 Gold 普通地板接近门毯的移动，均应 `ALLOW`。这与南北向 `STEP_ON` 门房的行为合同不同，不能互相套用。
- **碰撞才触发**：门房左口必须站在门毯上朝 `LEFT` 撞边界，右口必须朝 `RIGHT` 撞边界；这一步必须由位置碰撞产生 `BLOCK`，交给 `CheckWarpsCollision` 的 Warp 方向过滤处理。门毯上下/室内侧移不等于 Warp 触发；不得为通过测试把合法走动误写成预期 `BLOCK`，也不得把出门一侧误写成普通 `ALLOW` 导致撞不到 Warp。
- **室外也一样**：Route38 `(35,8/9)` 是 `RIGHT` 碰撞出口，缘朱市 `(0,18/19)` 是 `LEFT` 碰撞出口；两条上下相邻的 Warp 格必须互通，且只有实际向门外碰撞才进入。门毯相邻的普通 Gold FLOOR 移动也要实际逐格检查。
- **发布自动强制**：`tools/johto_masked_step_audit.py` 中的 `gate_mat_path_errors` 逐格解释执行当前地图真实 `CanStepAhead` ASM 和 mask；`tools/johto_gatehouse_behavior_audit.py` 还解释执行 ROM0 的 `IsJohtoSouthGatePortal` 地图身份及 ROMX 的四向 Warp 判断。新增脚本 `test_johto_gatehouse_carpet_229.py` 对逐格上下走、向外碰撞、两格往返、错 ID、坏 mask 做真实故障注入。`tools/johto_map_release_audit.py` 必须收集这些测试 ID。脚本静态验收仍不能代替用户编译、ROM0 新 MAP 和手机录像。
- **此处记录的是 `.228` 手机反馈的修复候选，不是 `.229` 的手机 PASS**；此前的 `.228` 卡门失败记录必须保留。


### .230 Route38 室外回程漏检（`.229` 手机失败，禁止虚报验收）

- **复现路径**：在 ID23 门房左口 (0,4/5) 朝 LEFT 出门，落到 Route38 `(35,8/9)`，原地朝 RIGHT 试图复入。`.229` 的 Gold 碰撞 mask 会在 `(36,8/9)` 阻挡，`CheckWarpsCollision` 的方向也正确；但真正的 `ExtraWarpCheck → JohtoInternalDoorFacingCheck` 没有登记 Route38 的这个非边界入口，因 x35 ≠ 最右边界 x39，旧 `IsPlayerFacingEdgeOfMap` 也不能触发 Warp。**这不是玩家操作问题，`.229` 不是实机 PASS。**
- **必须分别验证所有碰撞门**：一是 `CanStepAhead` 真正碰撞；二是 standing-on-warp bit 已就绪；三是 `ExtraWarpCheck` 对合法来源/落点/方向返回 carry；四是 `CheckWarpsCollision` 目标图和方向核验；五是抵达后立即反向能再次通过同样的五步。只看 `JohtoGateCollisionDirectionAllowed` 不构成“可复入”证明。
- **强制静态防回退**：`johto_gatehouse_behavior_audit.py` 为 Route38 的 `(35,8/9)` 强制 `outside_guard` + 解释执行 `JohtoInternalDoorFacingCheck` 四方向。`test_johto_gatehouse_carpet_229.py` 新增 Route38 两格具体判定和“删掉实际 ExtraWarpCheck 入口必须红灯”的负例。该检测不模拟真实按键时序和 ROM 执行，**手机测试仍为 PENDING**。

## .235D 新固定条款：Gold 单格实体 DOOR 与双格门毯不得混淆

- Gold `JOHTO`/`JOHTO_MODERN` 的**单格北向 DOOR**（例如金黄市 `(19,1)`、卡吉镇 `(9,1)`）从南侧走上门砖立即触发 Warp，使用已有 `JohtoNorthGateStepWarpAllowed`。不能把房顶阻挡 mask 错当成需要**第二次** UP 的依据。
- 双格 `WARP_CARPET_DOWN`（Route35、Route43 南端）可先站上毯，朝门口方向再碰撞 Warp，左右横移与立即反向按键不应误触发。两类行为分别审核出门一步与撞墙。
- `johto_gatehouse_behavior_audit.py` 必须用 Gold 原始 `.blk`、metatiles、tilecoll 对入口单格实体门分类，拒绝 JSON 和 ASM 一起把 STEP_ON 改为 COLLISION_ONLY 的自洽假绿。负向故障注入不能只变更其中一份。

## .237 全门房 Gold 碰撞规则定稿（覆盖旧的 `.215` Route34 例外）

- 对 Gold `maps/*Gate*.asm` 全量盘点 **24 座门房、100 个 Warp 落点**：26 个 Warp 位于 `DOOR`，其余 74 个分别为 `WARP_CARPET_DOWN` 30 个、`WARP_CARPET_LEFT` 22 个、`WARP_CARPET_RIGHT` 22 个。所有这 100 个 Warp 位的碰撞都能由 Gold 原始 `.blk` 和对应 tileset `tilecoll` 直接解出；没有必要靠门房名字或方向猜测。
- 规则固定为：`DOOR` → `STEP_ON/UP`；`WARP_CARPET_<DIR>` → `COLLISION_ONLY/<DIR>`（Route31 保留既有 `LEGACY_COLLISION` 执行器，但语义仍是碰撞触发）。方向必须与 Gold 碰撞后缀一致。单格/双格决定 Lane 数，不改变单格实体门与方向门毯的触发差异。
- 到达步进按**目标格**固定：Gold `DOOR`、`DOOR_79`、`STAIRCASE`、`CAVE` 由原版移动引擎向下离开目标格；方向门毯不自动迈步。当前已接入门房的目标点因此必须逐一符合 `D_DOWN` 或 `NONE`，而不是“上下门房都走一步”。
- 当前 9 座已接入 RPP 门房的 67 个入口、55 个到达点均由 `tools/johto_warp_reference_profiles.py --inventory-gold-gates` 独立对照 Gold。脚本现在输出每个 Gold Warp 的 collision role / trigger contract，并在任一入口类型、方向或到达步进不一致时以非零退出码结束。
- 旧记录 `.215` 将 Route34 `(13/14,37)` 当作踏格例外的说法已被原版碰撞证据推翻；保留它作为历史记录，但不得再作为当前规范或测试预期。
