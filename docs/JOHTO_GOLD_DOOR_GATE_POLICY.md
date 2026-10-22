## 门房专项必读（正式收口 GATE-5.62.202）

若开发对象是**门房/双格 Gate**，除本通用 Warp 分类文档外，还必须先阅读 **`docs/JOHTO_GATEHOUSE_READ_FIRST.md`**。新旧 `GATE_INDOOR` 的必读路径、8 类测试证明与手机验收级别由 `tools/johto_door_onboarding_audit.py` 按 `tools/johto_door_contracts.json` 强制审查；这不是可选建议。文件丢失、证据漏登记、测试未执行时统一门禁 FAIL。


# Gold 入口分类与防卡门门禁（GAT-5.62.180）

## GAT-5.62.180 — Gold 全入口语义与地图严格审计门禁

- 参考 Gold 的 `constants/collision_constants.asm`、`engine/overworld/tile_events.asm`、`engine/overworld/player_movement.asm`、`home/map.asm`、`engine/overworld/events.asm`、`engine/overworld/scripting.asm`，不要把 `DOOR`、`CAVE`、`LADDER/STAIRCASE`、四向 `WARP_CARPET`、`WARP_PANEL` 和 `PIT` 视为同一种自动踩格传送。
- 在 Gold 原版中，`warp_event` 坐标、目标 map/warp 索引与碰撞类型是三个独立信息源；再加上进门方向、地形可通行性、模拟迈步与出门后控制权，才构成可实测的完整入口行为。脚本 `warp`、电梯和边缘换图不要求每条都有严格反向 Warp，不能用全局“必须双向”规则误封正常机关。
- 门房与洞穴不可盲目复用：门房双口、对侧通过与方向过滤；洞穴入口到达位置、墙边退出的碰撞方向、进出后模拟迈步、侧向不触发，需要分别核验。未开放洞口保持禁止进入，不能为了让入口测试通过而顺带放开。
- `tools/johto_gold_door_audit.py` 扫描 Gold 的所有注册地图、Warp 事件和主要入口碰撞家族；检查目标索引、地图界限和基础引擎入口语义符号。它不执行 Game Boy 运行时代码，不能单独宣称真实操作无卡门。
- `tools/johto_map_release_audit.py` 现在固定必需测试模块与关键反例 test ID；删除测试或测试被跳过必须 FAIL。测试要能在任意解压目录搭配 `JOHTO_GOLD_SOURCE` 路径使用，禁止隐藏依赖本地目录结构。
- 新地图审核顺序：Gold 类型归类 → Gold 原始 Warp 与目标编号 → RPP 地图与实际 tile 碰撞 → 入口方向与侧向负例 → 出口落点 / 是否自动迈步 → 再进再出无卡门 → 旧门房及关东回归 → 手机实机录像验收。静态 PASS 不等于模拟器/手机完成验收。
- 后续不能只增加字符串断言，也不能为了减少重复删掉 `ExtraWarpCheck`、联合洞穴的特殊入口/出口检查或到达安全步进；如改动控制流，需要添加对应受限解释器或实际操作证据。要保留新地图扩展性。

## .237 Gold 全门房碰撞类型与 RPP 统一合同

`tools/johto_gold_door_audit.py::GoldCollisionIndex` 直接从 Gold `data/maps/attributes.asm`、`constants/map_constants.asm`、`data/maps/blocks.asm`、各地图 `.blk` 和 tileset `*_collision.asm` 解码每个 Warp 坐标所在的 8×8 碰撞象限。不能只看 `warp_event` 坐标，也不能只看 RPP 自己的 JSON。

对 Gold 原版 `maps/*Gate*.asm` 全量盘点结果为 **24 座 / 100 个 Warp 格**：26 个 `DOOR`、30 个 `WARP_CARPET_DOWN`、22 个 `WARP_CARPET_LEFT`、22 个 `WARP_CARPET_RIGHT`。11 座东西向双格、12 座南北向双格、1 座复杂多出口；`VictoryRoadGate` 等特殊结构仍按每个 Warp 单独处理。

当前统一合同：

- `DOOR` 是实体门格，入口用 `STEP_ON`，当前标准门房入口朝向为 `UP`。
- `WARP_CARPET_<DIR>` 是可站立门毯，入口只能用对应方向的 `COLLISION_ONLY`；Route31 仍用既有 `LEGACY_COLLISION` 执行器，但不可改成踏格触发。
- Warp 到达后的模拟移动依据**目的地碰撞类型**：Gold `DOOR` / `DOOR_79` / `STAIRCASE` / `CAVE` 需要 `D_DOWN`，方向门毯需要 `NONE`。触发门毯的输入方向与切图后的自动步进是两份独立规则。
- 现有 9 座 RPP 门房的 **67 个入口和 55 个到达点**已被 `--inventory-gold-gates` 独立核对。任一 Gold collision role、触发类型、方向或到达步进不匹配时，盘点脚本返回非零退出码。

这条规则覆盖旧 `.215` Route34 例外：Gold `Route34 (13/14,37)` 实际是 `WARP_CARPET_DOWN`，必须 collision-only；门房室内南侧 y7 也一样。实体 `DOOR` 的 step-on 规则不再扩展到方向门毯。

### 新地图一律先登记入口合同

- `tools/johto_door_contracts.json` 记录每张**已开放 Warp** 的 Johto 地图、Gold 原地图、入口家族、Warp 数量和应执行的具体测试 ID。
- `tools/johto_door_onboarding_audit.py` 对 `data/mapObjects/Johto*.asm` 自动发现新开启的 Warp。新增门房、洞穴、楼梯等地图如果只写 `db` Warp 却不登记入口合同，门禁直接 FAIL；改动旧地图 Warp 数而不更新合同也会 FAIL。
- 新合同必须增加能覆盖入口正向通行、反向退出、横向擦边、Warp 落点、自动迈步的测试；门禁必须实际发现并执行登记的 test ID。未来从 `DEFERRED` 变为已开放不可只改能力登记字段。
- 此门禁只覆盖当前原生 `Johto*.asm` 入口对象布局；剧情脚本传送、Gold 所有碰撞动画、模拟器和手机输入仍需要分别验收，不能承诺“只要静态测试通过就绝不会卡门”。
