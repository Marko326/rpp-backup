> **历史更正**：FIX-301 只覆盖门毯之间换道，并错误地把普通地面进入门毯定义为阻挡；该假设已由 FIX-302 修正。当前行为和验收要求以 `docs/JOHTO_GATEHOUSE_CARPET_MOVEMENT_FIX_302.md` 为准。

# FIX-5.62.301｜城都门房地毯换道碰撞专项修复（历史记录，已由 FIX-302 补全）

## 状态与范围

- 历史阶段记录：正式版本 `FIX-5.62.301`，测试版本 `TEST-232`；当前最终状态以 `FIX-5.62.302` 清理交接为准。
- 本轮覆盖全部 10 座活动门房：稳定 ID `6、11、13、18、19、23、62、102、104、105`，共 32 个已登记地毯格。
- 不改变 Gold 原始地图图块、Warp 注册表、活动地图数、存档布局、Surf/Cut/HOP、音乐、自行车规则或 Kanto 碰撞。
- 不编译／链接 ROM，不声称 Red/Blue MAP 或手机实测通过。

## 根因

MAP-300 新增的 `Route42EcruteakGate`（稳定 ID 62）使用 NPC-5.62.243 成熟阻挡掩码。四个地毯格 `(0,4)、(0,5)、(9,4)、(9,5)` 在角色网格中都标为阻挡。`JohtoEastSpatialStep` 只按目标格角色判断通行，没有为站在上、下地毯之间换道的玩家提供例外，因此从上格按 DOWN、从下格按 UP 都被挡住。

此前门房测试覆盖 Gold 地毯方向、Warp 表、双向连接、外向碰撞出口及角色网格身份，但没有执行“站在地毯上→按上下方向→目标格是否放行”的移动模拟。这解释了静态脚本通过、玩家实际被卡住的差异。

## 全部活动门房扫描

| 稳定 ID | 门房 | 碰撞策略 | 结果 |
|---:|---|---|---|
| 6 | Route31VioletGate | legacy Gate_Coll | 通过 |
| 11 | IlexForestAzaleaGate | South Gold role grid | 通过 |
| 13 | Route34IlexForestGate | South Gold role grid | 通过 |
| 18 | Route35GoldenrodGate | South Gold role grid | 通过 |
| 19 | Route36RuinsOfAlphGate | legacy Gate_Coll | 通过 |
| 23 | Route38EcruteakGate | West carpet lane helper | 通过 |
| 62 | Route42EcruteakGate | East carpet lane helper | 本轮修复 |
| 102 | Route32RuinsOfAlphGate | legacy Gate_Coll | 通过 |
| 104 | Route35NationalParkGate | South Gold role grid | 通过 |
| 105 | Route36NationalParkGate | Park East mature helper | 通过 |

ID 6/19/102 的 legacy Gate_Coll 探测图块逐一从运行时 blockset 解码并与 `Gate_Coll` passable list 比较；ID 11/13/18/104 的门房地毯在 Gold role grid 中为可通行，且未被 closed-door fence 黑名单覆盖；ID23 和 ID105 各自有专用成熟掩码通行例外。未发现另外 9 座门房存在与 ID62 相同的阻挡掩码遗漏。

## 代码修复

新增 `JohtoEastGateCarpetLaneStep300`，并在 `JohtoEastSpatialStep` 查询成熟角色网格之前调用：

- 仅适用于 `JOHTO_ROUTE_42_ECRUTEAK_GATE_LOCAL_ID`（稳定 ID 62）。
- 仅允许 X=0 或 X=9。
- 当前 Y=4 且方向 DOWN 时允许换到 Y=5。
- 当前 Y=5 且方向 UP 时允许换到 Y=4。
- 其他位置／方向清除 Carry 并继续走原成熟碰撞掩码；E=0 + Carry=1 只代表这次精确换道放行。
- LEFT/RIGHT 外向碰撞仍由 `JohtoEastPortalCollisionExit` 决定，不改变 Warp 方向和目标。

该判定位于 ROMX Bank `$53`，没有增加 ROM0 代码。步行与自行车共用同一个 `JohtoEastSpatialStep` 入口。

## 新增审计与负向测试

`tools/johto_gatehouse_behavior_audit.py` 增加 `active_gatehouse_carpet_walkability`，要求所有活动门房在显式策略表中登记，并逐格验证 32 个已登记地毯。新策略包括 legacy Gate_Coll 探测图块、South Gold role grid、West carpet lane helper、Park East mature helper 和 East carpet lane helper。新活动门房若没有策略，审计失败。

MAP-300 专项门禁在 FIX-301 阶段新增 ID62 地毯换道检查，覆盖四种地毯间换道。该阶段把从普通地面 Y=3 DOWN／Y=6 UP 进入门毯错误地定义为“不应放宽”；FIX-302 已证明这是错误的测试假设，并将检查改为要求合法入毯。此段仅保留 FIX-301 当时的历史实现，不得作为当前入毯规则。

## 验收边界

- 静态门禁只证明当前源码、碰撞表和审计合同一致；不等于 RGBDS 编译／链接、真实 ROM MAP 空间检查或设备移动验收。
- MAP-300 所需的独立 NPC stage-77 身份参考未随本轮输入提供；依赖该独立目录的完整身份测试仍应标记跳过，不能用当前候选资源或不同阶段参考冒充 stage-77。
- 用户本机需重建 Red、Blue 与 TEST ROM，检查最新 MAP 的 ROM0 安全余量及 Bank `$53`，再逐一复测 10 座门房：地毯换道、内部普通地面、墙格、步行／自行车、正确方向进出和反向返回。

## 本轮静态验证结果

- 全门房审计：`14/14 PASS_REFERENCE_ONLY`；10 座活动门房／32 个登记地毯格逐一通过。
- Gold 综合迁移审计：`1009/1009 PASS_STATIC_ONLY`。
- Surf 开发门禁：38 张活动地图、18 张含水地图通过；`new_map_unreviewed_rejected`、`broken_move_handoff_rejected` 两项负向注入通过。
- Field Moves 覆盖：38 张活动地图、4360 WATER、10 CUT、176 HOP。
- ASM 局部符号预检：2092 个 ASM 文件通过；Table ASSERT 预检自测通过。
- FIX-301 历史阶段完整 Python 回归：`475 passed, 21 skipped, 82 subtests passed, 0 failed`。该数字属于 FIX-301 当时状态；FIX-302 最终清理前回归见 `docs/JOHTO_GATEHOUSE_CARPET_MOVEMENT_302_CLEAN_HANDOFF.md`。

## MAP 空间证据与限制

用户提供的旧 `MAP-5.62.300 / TEST-231` Red、Blue MAP 均显示 ROM0 slack 64B、Bank `$53` slack 12,878B，且两版现有 East Runtime 符号位置一致。本轮新代码放在该 Bank `$53`，未触及 ROM0；但旧 MAP 没有包含 FIX-301 新增 helper，故它只能作为修改前的容量参考，不能证明新版本链接后仍有相同余量。最终 ROM0 与 Bank `$53` 余量必须以用户本机新编译生成的 Red/Blue MAP 为准。
