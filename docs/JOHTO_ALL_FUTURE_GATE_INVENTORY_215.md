# Gold 全门房预检（地图开发前使用）

来源：Gold 原版 `maps/*Gate*.asm`，与项目当前 `GATE_INDOOR` 登记对照。
**不会根据南北/东西方向猜测自动走一步。** 下表的危险标志仅用于规划，真实 Warp 落点和自动步行仍需逐端审核。

Gold 门房：24；横向：11；纵向：12；复杂：1；未注册城都候选：11。

| Gold 门房 | 地图形态 | 状态 | 特殊风险 |
|---|---|---|---|
| `IlexForestAzaleaGate` | 东西双格 | ALREADY_REGISTERED_JOHTO | 普通 Warp 结构（仍需逐端核对）；现有到达配置 {'west': 'NONE', 'east': 'NONE'} |
| `Route15FuchsiaGate` | 东西双格 | KANTO_GOLD_REFERENCE_NOT_RPP_EQUIVALENCE | 普通 Warp 结构（仍需逐端核对） |
| `Route16Gate` | 东西双格 | KANTO_GOLD_REFERENCE_NOT_RPP_EQUIVALENCE | SCRIPTED_ACCESS_OR_MOVEMENT |
| `Route17Route18Gate` | 东西双格 | KANTO_GOLD_REFERENCE_NOT_RPP_EQUIVALENCE | SCRIPTED_ACCESS_OR_MOVEMENT |
| `Route19FuchsiaGate` | 南北双格 | KANTO_GOLD_REFERENCE_NOT_RPP_EQUIVALENCE | TWO_LANES_TO_ONE_DESTINATION |
| `Route29Route46Gate` | 南北双格 | NOT_REGISTERED_JOHTO_CANDIDATE | TWO_LANES_TO_ONE_DESTINATION |
| `Route2Gate` | 南北双格 | KANTO_GOLD_REFERENCE_NOT_RPP_EQUIVALENCE | TWO_LANES_TO_ONE_DESTINATION |
| `Route31VioletGate` | 东西双格 | ALREADY_REGISTERED_JOHTO | 普通 Warp 结构（仍需逐端核对）；现有到达配置 {'west': 'NONE', 'east': 'NONE'} |
| `Route32RuinsOfAlphGate` | 东西双格 | NOT_REGISTERED_JOHTO_CANDIDATE | 普通 Warp 结构（仍需逐端核对） |
| `Route34IlexForestGate` | 南北双格 | ALREADY_REGISTERED_JOHTO | TWO_LANES_TO_ONE_DESTINATION；现有到达配置 {'north': 'D_DOWN', 'south': 'NONE'} |
| `Route35GoldenrodGate` | 南北双格 | NOT_REGISTERED_JOHTO_CANDIDATE | TWO_LANES_TO_ONE_DESTINATION |
| `Route35NationalParkGate` | 南北双格 | NOT_REGISTERED_JOHTO_CANDIDATE | TWO_LANES_TO_ONE_DESTINATION, SCRIPTED_ACCESS_OR_MOVEMENT |
| `Route36NationalParkGate` | 东西双格 | NOT_REGISTERED_JOHTO_CANDIDATE | SCRIPTED_ACCESS_OR_MOVEMENT |
| `Route36RuinsOfAlphGate` | 南北双格 | NOT_REGISTERED_JOHTO_CANDIDATE | TWO_LANES_TO_ONE_DESTINATION |
| `Route38EcruteakGate` | 东西双格 | NOT_REGISTERED_JOHTO_CANDIDATE | 普通 Warp 结构（仍需逐端核对） |
| `Route42EcruteakGate` | 东西双格 | NOT_REGISTERED_JOHTO_CANDIDATE | 普通 Warp 结构（仍需逐端核对） |
| `Route43Gate` | 南北双格 | NOT_REGISTERED_JOHTO_CANDIDATE | TWO_LANES_TO_ONE_DESTINATION, SCRIPTED_ACCESS_OR_MOVEMENT |
| `Route43MahoganyGate` | 南北双格 | NOT_REGISTERED_JOHTO_CANDIDATE | TWO_LANES_TO_ONE_DESTINATION |
| `Route5SaffronGate` | 南北双格 | KANTO_GOLD_REFERENCE_NOT_RPP_EQUIVALENCE | TWO_LANES_TO_ONE_DESTINATION |
| `Route6SaffronGate` | 南北双格 | KANTO_GOLD_REFERENCE_NOT_RPP_EQUIVALENCE | TWO_LANES_TO_ONE_DESTINATION, SCRIPTED_ACCESS_OR_MOVEMENT |
| `Route7SaffronGate` | 东西双格 | KANTO_GOLD_REFERENCE_NOT_RPP_EQUIVALENCE | 普通 Warp 结构（仍需逐端核对） |
| `Route8SaffronGate` | 东西双格 | KANTO_GOLD_REFERENCE_NOT_RPP_EQUIVALENCE | 普通 Warp 结构（仍需逐端核对） |
| `SafariZoneFuchsiaGateBeta` | 南北双格 | GOLD_BETA_REFERENCE_ONLY | TWO_LANES_TO_ONE_DESTINATION, UNRELEASED_GOLD_BETA |
| `VictoryRoadGate` | 多方向特殊 | NOT_REGISTERED_JOHTO_CANDIDATE | MULTI_EXIT_CUSTOM_ROUTING, SCRIPTED_ACCESS_OR_MOVEMENT |

## 新门房必须先登记的动作合同

每条入口单独核对：来源地图、出入口坐标与面向、Gold Warp 目标编号、RPP 0-based 目标编号、落点格以及前后两格 Gold 碰撞，切图后 `NONE`还是 `D_UP/D_DOWN/D_LEFT/D_RIGHT` 自动一步，错误方向和立即反向行为。
非对称合流必须列出 2→1 对应；剧情/场景脚本与门房到达步行**分开登记**。
已有的 `GetJohtoWarpArrivalStep` / `PlayerStepOutFromDoor` 只在有证据的目的地增加精确规则，不可因 `NORTH_SOUTH_PAIR` 就为上下两端都追加一步。
此审计不修改 ROM、Gold 源码，也不能代替编译和手机实机测试。
