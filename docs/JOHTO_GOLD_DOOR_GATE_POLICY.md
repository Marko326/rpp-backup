# Gold 入口分类与防卡门门禁（GAT-5.62.180）

## GAT-5.62.180 — Gold 全入口语义与地图严格审计门禁

- 参考 Gold 的 `constants/collision_constants.asm`、`engine/overworld/tile_events.asm`、`engine/overworld/player_movement.asm`、`home/map.asm`、`engine/overworld/events.asm`、`engine/overworld/scripting.asm`，不要把 `DOOR`、`CAVE`、`LADDER/STAIRCASE`、四向 `WARP_CARPET`、`WARP_PANEL` 和 `PIT` 视为同一种自动踩格传送。
- 在 Gold 原版中，`warp_event` 坐标、目标 map/warp 索引与碰撞类型是三个独立信息源；再加上进门方向、地形可通行性、模拟迈步与出门后控制权，才构成可实测的完整入口行为。脚本 `warp`、电梯和边缘换图不要求每条都有严格反向 Warp，不能用全局“必须双向”规则误封正常机关。
- 门房与洞穴不可盲目复用：门房双口、对侧通过与方向过滤；洞穴入口到达位置、墙边退出的碰撞方向、进出后模拟迈步、侧向不触发，需要分别核验。未开放洞口保持禁止进入，不能为了让入口测试通过而顺带放开。
- `tools/johto_gold_door_audit.py` 扫描 Gold 的所有注册地图、Warp 事件和主要入口碰撞家族；检查目标索引、地图界限和基础引擎入口语义符号。它不执行 Game Boy 运行时代码，不能单独宣称真实操作无卡门。
- `tools/johto_map_release_audit.py` 现在固定必需测试模块与关键反例 test ID；删除测试或测试被跳过必须 FAIL。测试要能在任意解压目录搭配 `JOHTO_GOLD_SOURCE` 路径使用，禁止隐藏依赖本地目录结构。
- 新地图审核顺序：Gold 类型归类 → Gold 原始 Warp 与目标编号 → RPP 地图与实际 tile 碰撞 → 入口方向与侧向负例 → 出口落点 / 是否自动迈步 → 再进再出无卡门 → 旧门房及关东回归 → 手机实机录像验收。静态 PASS 不等于模拟器/手机完成验收。
- 后续不能只增加字符串断言，也不能为了减少重复删掉 `ExtraWarpCheck`、联合洞穴的特殊入口/出口检查或到达安全步进；如改动控制流，需要添加对应受限解释器或实际操作证据。要保留新地图扩展性。

### 新地图一律先登记入口合同

- `tools/johto_door_contracts.json` 记录每张**已开放 Warp** 的 Johto 地图、Gold 原地图、入口家族、Warp 数量和应执行的具体测试 ID。
- `tools/johto_door_onboarding_audit.py` 对 `data/mapObjects/Johto*.asm` 自动发现新开启的 Warp。新增门房、洞穴、楼梯等地图如果只写 `db` Warp 却不登记入口合同，门禁直接 FAIL；改动旧地图 Warp 数而不更新合同也会 FAIL。
- 新合同必须增加能覆盖入口正向通行、反向退出、横向擦边、Warp 落点、自动迈步的测试；门禁必须实际发现并执行登记的 test ID。未来从 `DEFERRED` 变为已开放不可只改能力登记字段。
- 此门禁只覆盖当前原生 `Johto*.asm` 入口对象布局；剧情脚本传送、Gold 所有碰撞动画、模拟器和手机输入仍需要分别验收，不能承诺“只要静态测试通过就绝不会卡门”。
