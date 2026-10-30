# ALPH-NORTH-001 — Route36 / 遗迹北门房接入计划

## 范围

下一阶段只开放 Gold 原版的 `Route36` 与 `Route36RuinsOfAlphGate`，并把它们接到当前已验收的 `RuinsOfAlphOutside` 北侧门口。沿用已预留稳定 ID：`Route36` = 16，`Route36RuinsOfAlphGate` = 19；遗迹外围继续使用 ID20。预期活动地图从 11 增至 13。

不开放 `Route36NationalParkGate`、National Park、Route35/37 的其他出口、遗迹拼图室、研究中心、联合洞穴或未知图腾剧情。Route36 的 National Park 两个 Warp 必须保持 fail-closed。

## Gold 原版 Warp 与碰撞合同

坐标均为 Gold 原版地图局部 `(x,y)`，Warp 编号为 Gold `warp_event` 的一基编号：

| Gold 地图 | 位置 | Gold 碰撞角色 | 触发方式 | 方向 | 目标 |
|---|---:|---|---|---|---|
| `Route36` | `(47,13)` | `WARP_CARPET_DOWN` | `COLLISION_ONLY` | DOWN | 北门房 Warp #1 |
| `Route36` | `(48,13)` | `WARP_CARPET_DOWN` | `COLLISION_ONLY` | DOWN | 北门房 Warp #2 |
| `Route36RuinsOfAlphGate` | `(4,0)` | `DOOR` | `STEP_ON` | UP | Route36 Warp #3 |
| `Route36RuinsOfAlphGate` | `(5,0)` | `DOOR` | `STEP_ON` | UP | Route36 Warp #4 |
| `Route36RuinsOfAlphGate` | `(4,7)` | `WARP_CARPET_DOWN` | `COLLISION_ONLY` | DOWN | 遗迹外围 Warp #9 |
| `Route36RuinsOfAlphGate` | `(5,7)` | `WARP_CARPET_DOWN` | `COLLISION_ONLY` | DOWN | 遗迹外围 Warp #9 |
| `RuinsOfAlphOutside` | `(7,5)` | `DOOR` | `STEP_ON` | UP | 北门房 Warp #3 |

Gold 的 Route36 入口是 Warp #3/#4（前两个 Warp 属于 National Park Gate，不能误接）。遗迹外围北门是 Gold Warp #9；当前运行时地图只登记南侧两个 Warp，接入北门时必须重新核对压缩后的 runtime Warp ordinal，不能直接把 Gold ordinal 当运行时 ordinal。

## 自动行走是本门房的核心差异

这不是南侧 `EastWestGate` 的横向门房，不能复用它当前只检查 `x=0/9`、`y=4/5`、LEFT/RIGHT 的方向守卫。

- 竖向门房上端 `(4/5,0)` 是 `DOOR`：玩家向 UP 踏入时按 `STEP_ON` 触发；从 Route36 到达这两个目标格时，Gold 的门口到达行为是自动 `D_DOWN` 一格。
- 竖向门房下端 `(4/5,7)` 是 `WARP_CARPET_DOWN`：只有面向 DOWN 的碰撞才触发；它本身不自动迈步。
- 遗迹外围北门 `(7,5)` 是 `DOOR`：向 UP 踏入后到达门房下端地毯，不自动迈步；从门房下端返回遗迹时，落在该 DOOR 后 Gold 要自动 `D_DOWN` 一格。
- 因此自动迈步必须依据**目标地图的落点碰撞角色**判断，而不能只依据源 Warp 地毯类型；横向南门房四边都是地毯，恰好没有这个复杂性。

必须沿用／核对现有 `PlayerStepOutFromDoor` 与 Warp arrival 的真实调用顺序，确认 D_DOWN 只执行一次、最终落点可走、不会立即再次触发 Warp；读档落在 DOOR 或 carpet 时也不能误自动迈步。

## 接入门禁

1. 先生成 Gold `Route36`、北门房的 source/runtime 布局与碰撞角色清单；与旧 NPC 分支只作对照，Gold 原始地图为坐标依据。
2. 为 ID16/19 增加显式活动地图、Header、资源、Town Map 地标、音乐、地图名称、稳定 ID 槽位与门房合同；不得覆盖 ID18 等已有稳定 ID。
3. 扩展 Warp 审计，逐项检查 Gold 源 Warp 编号、runtime ordinal 映射、方向、目标落点与反向路径；目标 DOOR 的自动 D_DOWN 单独建合同。
4. 增加负向测试：从侧面撞地毯、反方向碰撞、错误车道、误开 National Park Warp、自动步进二次触发、到达后第一按键、存档 Continue。
5. 复用当前已验收的南侧通路；不改南门房的 LEFT/RIGHT 规则，不重写 Surf、Cut 或遗迹方向跳崖。
6. 只有 Gold 逐格审计、ASM 预检、完整测试、补丁正反向回放通过后，才交开发补丁；最终仍由用户本机编译四种 ROM、检查最新 MAP 并实机测试。

## 本轮不做

不提前开放 National Park 门房、Route35/37、遗迹内部房间或剧情；不添加新的存档字段；不把静态 Gold 合同通过写成实机门房验收。
