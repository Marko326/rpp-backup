# 城都门房开发必读｜JOHTO_GATEHOUSE_READ_FIRST

> **强制入口**：以后只要新增、开放、修改门房／双格关卡出入口（含外侧边界、室内图块、显示地点名），必须在修改源码前读本文件，然后对照已实机验收的 **31号道路—桔梗市门房** 与 **桧皮镇—桐树林南门房**。登记 `tools/johto_door_contracts.json` 的 `gatehouse_guide` 与八项 `gatehouse_proof_ids`；工具自动要求每项证明对应的 unittest 真正执行。不能以「Warp 坐标对、静态全绿」代替游戏表现。

## A. 两格门口的行为合同：禁止反复卡门

1. **先读来源**：Gold `maps/*Gate.asm` 的入口对、Gold 入口碰撞类型、RPP `data/mapObjects/` 的 0-based Warp 索引。室外、室内、未开放的另一侧逐一列出；未开放出口不能留误触发的空 Warp。
2. **地图身份**：原生城都地图复用 `$FC`，所以判断地图必须是 `REGION_NATIVE_MAP_SLOT + MAP_REGION_JOHTO + local ID`，不能只按 `$FC`、图块集或城镇地标判断。
3. **Warp 触发与到达步行分开审核**：已验收的 31 号道路和桐树林南门房使用碰撞触发，门垫上站立或上下切换不自动 Warp；**北口 `.215` 是另一个已验收的“正确方向走上门口格触发”类型**，不能强迫新门房都按前者套用。每座门房必须按 Gold 原版门垫与 RPP 已有处理分支登记触发类型；错误方向/侧擦不可传送。切图后是否走一步独立登记，绝不由触发方式推断。
4. **立即反向复入**：两格分别反复“进→立刻出→再进”，不准要求先退一步；跨图后角色控制、落点、方向、步进状态必须正确。对照现有 `CheckWarpsNoCollisionLoop`、`CheckWarpsCollision`、`IsPlayerFacingEdgeOfMap`，不得新造专用踩格自动传送。
5. **旧地图保全**：31号道路—桔梗市门房、关东 Route15 等原有门房、已开放洞穴、Fly、保存/读取不能因新的门房坐标特判回退；门房和洞穴的碰撞机制不能混用。

### A2. 竖向门房到达步行不能靠方向默认（ILEX-5.62.215 后强制）

- 门房 Warp **触发方式** 和 **切图后自动走一步** 是两项不同设置。不能把“禁止踩格传送”理解成“禁止切图后一步”，也不能以“南北门房”为理由让上下两边都走一步。
- 每个新增 `GATE_INDOOR` 必须在 `tools/johto_door_contracts.json` 记录 `arrival_step_review`：`layout`、每侧 `by_gate_side`（`NONE` / `D_UP` / `D_DOWN` / `D_LEFT` / `D_RIGHT`）及 `basis`。`johto_door_onboarding_audit.py` 缺少字段必须失败。复杂的 VictoryRoadGate 先走人工专项，不能伪装普通双格门房。
- Gold 原版 `warp_event` 只证明位置/目标，**不能证明** RPP 自动模拟移动。运行时继续用 `GetJohtoWarpArrivalStep` / `PlayerStepOutFromDoor`，必须先核对目标格及一步后碰撞与可回程性。独立检查起始侧两条 Lane、四个方向、错误来源、菜单/读档状态。
- `.215` 北门房：**抵达北侧 y0，自动向下 1 格；抵达南侧 y7，不额外走**；森林 `(1,5)` 作为目的地的向下 1 格仍由精确规则控制。不要恢复 `.214` 的双向自动步行。
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
