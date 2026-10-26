# 城都 NPC 行走半径：关东引擎兼容补丁（NPC-5.62.243 DEV）

基底：用户已报告能正常持续行走的 `JSON-5.62.242_NPC地板判定修复_源码.zip`。
参考：`pokegold-master(1)(1).zip` 的 `maps/*.asm` 和 `engine/overworld/npc_movement.asm`。

## 范围与实现

* 原有 `TryWalking` / `CanWalkOntoTile` 的方向选择、地板白名单、屏幕边界、人物碰撞、帧动画全部沿用关东逻辑。
* 在 `CanWalkOntoTile` **非脚本移动** 分支加一个 9 字节调用（保存 BC / `callab` / 恢复 BC / `ret c`），城都专用代码放在 ROMX 的 `engine/overworld/johto_npc_patrol_bounds.asm`。Bank 1 本来只剩极少空间，不能直接内联表。
* 仅 `wCurMap=$fc` **且** `wCurRegion=JOHTO` **且** `wCurLocalMapID` 命中六个室内图 **且** 行走轴为 WALK 1/2 **且** `c2x6=WALK($fe)` 才执行半径判定。若改动后出现一个房间两个 WALK NPC，现有审计会直接失败，需重做识别机制。
* 移动目标通过 `c2x4/c2x5+delta` 检查，关东地图内坐标是 Gold 坐标加 4。被边界拒绝时，和关东原 `.impassable` 相同：状态转延迟、清零运动向量、随机等待，再尝试下一步。不修改 `.tilecoll` 和玩家的阻挡数据。
* `Bankswitch` 的 `rst $18` 会改变 BC/HL，所以调用方保存 BC；返回后将重新读取碰撞表到 HL。ROM0 的 `Random` 可从 ROMX helper 直接调用。ROM0 银行切换返回过程不修改 Carry 标志。

## 六名已启用 WALK NPC 与 Gold 同源数据

| 地点 | Gold 初始坐标 | Gold 类型 | Gold 半径 (X,Y) | 范围 | 关东原行走轴 |
|---|---|---|---|---|---|
| 吉花 MART 男性 | (7,6) | WALK_LEFT_RIGHT | (2,0) | X=5..9，Y=6 | WALK,2 |
| 浅葱 MART 女性 | (6,2) | WALK_LEFT_RIGHT | (2,0) | X=4..8，Y=2 | WALK,2 |
| 浅葱 PC 渔夫 | (8,4) | WALK_LEFT_RIGHT | (1,0) | X=7..9，Y=4 | WALK,2 |
| 浅葱餐厅渔夫 | (1,5) | WALK_UP_DOWN | (0,1) | X=1，Y=4..6 | WALK,1 |
| 浅葱 Punishment Speech House 女孩 | (5,5) | WALK_LEFT_RIGHT | (2,0) | X=3..7，Y=5 | WALK,2 |
| 吉花 Gym Speech House 捕虫少年 | (5,5) | WALK_LEFT_RIGHT | (1,0) | X=4..6，Y=5 | WALK,2 |

范围为最多可到达的坐标包络，不保证 NPC 一定走满；关东的碰撞与屏幕边界仍可阻止移动。保留关东随机间隔，不追求 Gold 逐帧动画节奏。

## 哪些没有移植？不要误报成完整 Gold 等价

* 29 号道路有 2 个原版 WALK NPC、一个 `SPINRANDOM_SLOW`、一个 `STANDING_UP`，当前为原项目明确的 `STAY` 临时占位：全量审计依旧有 **6 条已知差异**，均在 `JohtoRoute29.asm`。
* Gold `object_event` 还包含小时条件（这六位全是 -1/-1）、调色板、对象类型、脚本、事件标志等；它们不是 WALK 轴/活动半径。这次不会假装那些事件或商店服务都已移植。
* 金版的移动节奏、动画、运行时判定优先级没有整套复制；按用户要求继续使用关东引擎。六名 NPC 的行走方向和**活动坐标上限**已按 Gold 校对，但 ROM 实机运行未在此环境完成验收。

## 源码回归与测试

```sh
JOHTO_GOLD_SOURCE=/path/to/pokegold-master python -m unittest \
  tools.tests.test_johto_npc_movement_audit \
  tools.tests.test_johto_public_npc_foot_tiles_242fix \
  tools.tests.test_johto_olivine_public_runtime_241dev \
  tools.tests.test_johto_olivine_public_batch_241dev \
  tools.tests.test_johto_olivine_house_npc_floor_240dev \
  tools.tests.test_johto_cherrygrove_public_244dev
```

审计（Route29 占位导致整体 FAIL，属于已知功能缺口，不应关闭警报）：

```sh
python tools/johto_npc_movement_audit.py --rpp . --gold /path/to/pokegold-master
```

## 游戏内建议

优先观察吉花 MART 男性在 x=5 和 x=9 两个端点是否转向/等待、能否往回走，不应越界；然后浅葱 MART 女性 x=4..8、PC 渔夫 x=7..9、餐厅渔夫 y=4..6，最后对照两间民房。不要把撞玩家、柜台/家具或屏幕边缘导致的暂停误判为半径失败。

本交付只含源代码、数据审计、测试和补丁；本机没有 RGBDS，不声称编译 ROM 成功或完成手机实机测试。

## .243 DEV 独立审查后审计补强（2026-10-26）

独立窗口的 `NPC_5.62.243_DEV_独立审查报告_MAP复核版` 发现：旧版
`johto_npc_movement_audit.py` 对 `.compare` 分支反转不报错。
本次保留 Gold 六人表、ROMX helper、Bank 1 挂钩、关东 NPC 引擎及地板资源**字节不变**，只增强离线审计、负向测试与开发说明：

* 审计从实际 ASM 中读取 `.compare` 至 `.allow` 之间的指令，只支持明确审核过的 LR35902 `cp`/`jr`/`jp` 子集；对每个已配置上下界，逐一模拟 `$00..$ff` 的目标坐标，验证分支确实实现 `min <= next <= max`（含端点）。不是用 Python 凭空计算正确答案、忽略 ASM。无法识别的指令会判 FAIL。
* 复核 `main.asm` 的 ROMX Section/INCLUDE、Bank 1 `push bc / callab / pop bc / ret c` 顺序，城都区域/地图 ID/WALK 门禁、水平/垂直步进分支、延迟重试及 Carry 返回合同。
* 增加故障注入：反转下界/上界/等于边界跳转、错取寄存器、删 helper INCLUDE、修改地图/区域/WALK 门禁、破坏 `ret c` 或 `push bc`、删延迟/Carry 标志、同一地图加第二名 WALK 等，均应有审计错误。
* **未来新增 NPC 的限制：** 当前 ROMX helper 仍仅按 local map ID 匹配，六张登记地图当前各一名 WALK。静态审计要求每张登记地图**恰好一名 WALK**；第二名会导致审计 FAIL。正式增加多名 WALK 前，必须设计并审核地图+人物身份索引及独立范围，不能直接绕开审计。

本轮新检查仍属**静态汇编分支与源码合同验证**，不是完整 CPU 仿真、ROM 二进制回归、动态 Bank 现场轨迹或旧存档验收。可见 `patches/rppred.map` 属已有构建证据；本轮仅改离线工具，没有重新编译 ROM/更新 MAP。Route29 六项旧差异、Route32 旧发布门禁问题继续如实保留。


## 清理提交状态（2026-10-26）

本轮根据用户在游戏中的粗略观察与 Gold 源码比对，进入正式**提交准备**；没有进一步改动运行时、半径、地图或工具审计代码。正式功能提交将游戏内版本由 `JSON-5.62.242` 更新为 `NPC-5.62.243`；第二笔工具提交沿用 `NPC-5.62.243`。原版方向／活动包络已静态核对，金版随机移动节奏未复制；用户没有逐人逐格数完所有边界，故不得写成逐格手机验收完成。

独立 R2 复审已复现并证明 `.compare` 边界反转现在能被审计拦截，同时指出 `_ordered_ops` 允许危险指令插入与缺少 `main.asm`/`movement.asm` 时未失败的两个测试盲区。它们尚未构成**现有 helper 已发生这些错误**的证据。用户明确要求先收口功能，不继续以工具完美为目标；遗留问题保留记录，后续单独处理。

清理使用模式 A（累计游戏与离线工具均有改动），交付 3 补丁 + 2 提交日志。01 仅用于已应用 R2 的当前开发状态；03 仅用于归档记录的 Git HEAD `5e08e4d9250e2650486da4f9a39fb14165a1481e`。两者互斥；02 是最终状态临时反向隔离工具后依次提交两笔的专用补丁。当前源码导出无 `.git`，只能从归档补丁重建对应文件树；用户提交前应在自己真实仓库核对 HEAD 与工作区。
