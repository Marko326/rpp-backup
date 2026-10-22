# Gold 全门房预检（地图开发前使用）

来源：Gold 原版 `maps/*Gate*.asm`，与项目当前 `GATE_INDOOR` 登记对照。
**不根据南北/东西方向猜测触发或自动步进。** 每个 Warp 坐标的 Gold collision role、入口触发、方向和活动合同到达步进均逐格核对；ROM 链接及手机输入行为仍需另行验收。

Gold 门房：24；横向：11；纵向：12；复杂：1；未注册城都候选：5。

Gold Warp 碰撞角色：`{"DOOR": 26, "WARP_CARPET_DOWN": 30, "WARP_CARPET_LEFT": 22, "WARP_CARPET_RIGHT": 22}`。

当前已接入门房入口逐格对照：**PASS**，检查 67 个入口；到达格自动步进对照：**PASS**，检查 55 个落点。

| Gold 门房 | 地图形态 | 状态 | 特殊风险 |
|---|---|---|---|
| `IlexForestAzaleaGate` | 东西双格 | ALREADY_REGISTERED_JOHTO | 普通 Warp 结构（Gold 碰撞角色已盘点）；现有到达配置 {'west': 'NONE', 'east': 'NONE'} |
| `Route15FuchsiaGate` | 东西双格 | KANTO_GOLD_REFERENCE_NOT_RPP_EQUIVALENCE | 普通 Warp 结构（Gold 碰撞角色已盘点） |
| `Route16Gate` | 东西双格 | KANTO_GOLD_REFERENCE_NOT_RPP_EQUIVALENCE | SCRIPTED_ACCESS_OR_MOVEMENT |
| `Route17Route18Gate` | 东西双格 | KANTO_GOLD_REFERENCE_NOT_RPP_EQUIVALENCE | SCRIPTED_ACCESS_OR_MOVEMENT |
| `Route19FuchsiaGate` | 南北双格 | KANTO_GOLD_REFERENCE_NOT_RPP_EQUIVALENCE | TWO_LANES_TO_ONE_DESTINATION |
| `Route29Route46Gate` | 南北双格 | NOT_REGISTERED_JOHTO_CANDIDATE | TWO_LANES_TO_ONE_DESTINATION |
| `Route2Gate` | 南北双格 | KANTO_GOLD_REFERENCE_NOT_RPP_EQUIVALENCE | TWO_LANES_TO_ONE_DESTINATION |
| `Route31VioletGate` | 东西双格 | ALREADY_REGISTERED_JOHTO | 普通 Warp 结构（Gold 碰撞角色已盘点）；现有到达配置 {'west': 'NONE', 'east': 'NONE'} |
| `Route32RuinsOfAlphGate` | 东西双格 | NOT_REGISTERED_JOHTO_CANDIDATE | 普通 Warp 结构（Gold 碰撞角色已盘点） |
| `Route34IlexForestGate` | 南北双格 | ALREADY_REGISTERED_JOHTO | TWO_LANES_TO_ONE_DESTINATION；现有到达配置 {'north': 'D_DOWN', 'south': 'NONE'} |
| `Route35GoldenrodGate` | 南北双格 | ALREADY_REGISTERED_JOHTO | TWO_LANES_TO_ONE_DESTINATION；现有到达配置 {'north': 'D_DOWN', 'south': 'NONE'} |
| `Route35NationalParkGate` | 南北双格 | NOT_REGISTERED_JOHTO_CANDIDATE | TWO_LANES_TO_ONE_DESTINATION, SCRIPTED_ACCESS_OR_MOVEMENT |
| `Route36NationalParkGate` | 东西双格 | NOT_REGISTERED_JOHTO_CANDIDATE | SCRIPTED_ACCESS_OR_MOVEMENT |
| `Route36RuinsOfAlphGate` | 南北双格 | ALREADY_REGISTERED_JOHTO | TWO_LANES_TO_ONE_DESTINATION；现有到达配置 {'north': 'D_DOWN', 'south': 'NONE'} |
| `Route38EcruteakGate` | 东西双格 | ALREADY_REGISTERED_JOHTO | 普通 Warp 结构（Gold 碰撞角色已盘点）；现有到达配置 {'west': 'NONE', 'east': 'NONE'} |
| `Route42EcruteakGate` | 东西双格 | ALREADY_REGISTERED_JOHTO | 普通 Warp 结构（Gold 碰撞角色已盘点）；现有到达配置 {'west': 'NONE', 'east': 'NONE'} |
| `Route43Gate` | 南北双格 | ALREADY_REGISTERED_JOHTO | TWO_LANES_TO_ONE_DESTINATION, SCRIPTED_ACCESS_OR_MOVEMENT；现有到达配置 {'north': 'D_DOWN', 'south': 'NONE'} |
| `Route43MahoganyGate` | 南北双格 | ALREADY_REGISTERED_JOHTO | TWO_LANES_TO_ONE_DESTINATION；现有到达配置 {'north': 'D_DOWN', 'south': 'NONE'} |
| `Route5SaffronGate` | 南北双格 | KANTO_GOLD_REFERENCE_NOT_RPP_EQUIVALENCE | TWO_LANES_TO_ONE_DESTINATION |
| `Route6SaffronGate` | 南北双格 | KANTO_GOLD_REFERENCE_NOT_RPP_EQUIVALENCE | TWO_LANES_TO_ONE_DESTINATION, SCRIPTED_ACCESS_OR_MOVEMENT |
| `Route7SaffronGate` | 东西双格 | KANTO_GOLD_REFERENCE_NOT_RPP_EQUIVALENCE | 普通 Warp 结构（Gold 碰撞角色已盘点） |
| `Route8SaffronGate` | 东西双格 | KANTO_GOLD_REFERENCE_NOT_RPP_EQUIVALENCE | 普通 Warp 结构（Gold 碰撞角色已盘点） |
| `SafariZoneFuchsiaGateBeta` | 南北双格 | GOLD_BETA_REFERENCE_ONLY | TWO_LANES_TO_ONE_DESTINATION, UNRELEASED_GOLD_BETA |
| `VictoryRoadGate` | 多方向特殊 | NOT_REGISTERED_JOHTO_CANDIDATE | MULTI_EXIT_CUSTOM_ROUTING, SCRIPTED_ACCESS_OR_MOVEMENT |

## Gold 原版每个 Warp 的碰撞规则

| Gold 门房 | 坐标 | 原版碰撞 | 预期触发 | 目标地图 | 目标 Warp |
|---|---:|---|---|---|---:|
| `IlexForestAzaleaGate` | (0,4) | `WARP_CARPET_LEFT` | `COLLISION_ONLY` | `ILEX_FOREST` | 2 |
| `IlexForestAzaleaGate` | (0,5) | `WARP_CARPET_LEFT` | `COLLISION_ONLY` | `ILEX_FOREST` | 3 |
| `IlexForestAzaleaGate` | (9,4) | `WARP_CARPET_RIGHT` | `COLLISION_ONLY` | `AZALEA_TOWN` | 7 |
| `IlexForestAzaleaGate` | (9,5) | `WARP_CARPET_RIGHT` | `COLLISION_ONLY` | `AZALEA_TOWN` | 8 |
| `Route15FuchsiaGate` | (0,4) | `WARP_CARPET_LEFT` | `COLLISION_ONLY` | `FUCHSIA_CITY` | 8 |
| `Route15FuchsiaGate` | (0,5) | `WARP_CARPET_LEFT` | `COLLISION_ONLY` | `FUCHSIA_CITY` | 9 |
| `Route15FuchsiaGate` | (9,4) | `WARP_CARPET_RIGHT` | `COLLISION_ONLY` | `ROUTE_15` | 1 |
| `Route15FuchsiaGate` | (9,5) | `WARP_CARPET_RIGHT` | `COLLISION_ONLY` | `ROUTE_15` | 2 |
| `Route16Gate` | (0,4) | `WARP_CARPET_LEFT` | `COLLISION_ONLY` | `ROUTE_16` | 4 |
| `Route16Gate` | (0,5) | `WARP_CARPET_LEFT` | `COLLISION_ONLY` | `ROUTE_16` | 5 |
| `Route16Gate` | (9,4) | `WARP_CARPET_RIGHT` | `COLLISION_ONLY` | `ROUTE_16` | 2 |
| `Route16Gate` | (9,5) | `WARP_CARPET_RIGHT` | `COLLISION_ONLY` | `ROUTE_16` | 3 |
| `Route17Route18Gate` | (0,4) | `WARP_CARPET_LEFT` | `COLLISION_ONLY` | `ROUTE_17` | 1 |
| `Route17Route18Gate` | (0,5) | `WARP_CARPET_LEFT` | `COLLISION_ONLY` | `ROUTE_17` | 2 |
| `Route17Route18Gate` | (9,4) | `WARP_CARPET_RIGHT` | `COLLISION_ONLY` | `ROUTE_18` | 1 |
| `Route17Route18Gate` | (9,5) | `WARP_CARPET_RIGHT` | `COLLISION_ONLY` | `ROUTE_18` | 2 |
| `Route19FuchsiaGate` | (4,0) | `DOOR` | `STEP_ON` | `FUCHSIA_CITY` | 10 |
| `Route19FuchsiaGate` | (5,0) | `DOOR` | `STEP_ON` | `FUCHSIA_CITY` | 11 |
| `Route19FuchsiaGate` | (4,7) | `WARP_CARPET_DOWN` | `COLLISION_ONLY` | `ROUTE_19` | 1 |
| `Route19FuchsiaGate` | (5,7) | `WARP_CARPET_DOWN` | `COLLISION_ONLY` | `ROUTE_19` | 1 |
| `Route29Route46Gate` | (4,0) | `DOOR` | `STEP_ON` | `ROUTE_46` | 1 |
| `Route29Route46Gate` | (5,0) | `DOOR` | `STEP_ON` | `ROUTE_46` | 2 |
| `Route29Route46Gate` | (4,7) | `WARP_CARPET_DOWN` | `COLLISION_ONLY` | `ROUTE_29` | 1 |
| `Route29Route46Gate` | (5,7) | `WARP_CARPET_DOWN` | `COLLISION_ONLY` | `ROUTE_29` | 1 |
| `Route2Gate` | (4,0) | `DOOR` | `STEP_ON` | `ROUTE_2` | 3 |
| `Route2Gate` | (5,0) | `DOOR` | `STEP_ON` | `ROUTE_2` | 4 |
| `Route2Gate` | (4,7) | `WARP_CARPET_DOWN` | `COLLISION_ONLY` | `ROUTE_2` | 2 |
| `Route2Gate` | (5,7) | `WARP_CARPET_DOWN` | `COLLISION_ONLY` | `ROUTE_2` | 2 |
| `Route31VioletGate` | (0,4) | `WARP_CARPET_LEFT` | `COLLISION_ONLY` | `VIOLET_CITY` | 8 |
| `Route31VioletGate` | (0,5) | `WARP_CARPET_LEFT` | `COLLISION_ONLY` | `VIOLET_CITY` | 9 |
| `Route31VioletGate` | (9,4) | `WARP_CARPET_RIGHT` | `COLLISION_ONLY` | `ROUTE_31` | 1 |
| `Route31VioletGate` | (9,5) | `WARP_CARPET_RIGHT` | `COLLISION_ONLY` | `ROUTE_31` | 2 |
| `Route32RuinsOfAlphGate` | (0,4) | `WARP_CARPET_LEFT` | `COLLISION_ONLY` | `RUINS_OF_ALPH_OUTSIDE` | 10 |
| `Route32RuinsOfAlphGate` | (0,5) | `WARP_CARPET_LEFT` | `COLLISION_ONLY` | `RUINS_OF_ALPH_OUTSIDE` | 11 |
| `Route32RuinsOfAlphGate` | (9,4) | `WARP_CARPET_RIGHT` | `COLLISION_ONLY` | `ROUTE_32` | 2 |
| `Route32RuinsOfAlphGate` | (9,5) | `WARP_CARPET_RIGHT` | `COLLISION_ONLY` | `ROUTE_32` | 3 |
| `Route34IlexForestGate` | (4,0) | `DOOR` | `STEP_ON` | `ROUTE_34` | 1 |
| `Route34IlexForestGate` | (5,0) | `DOOR` | `STEP_ON` | `ROUTE_34` | 2 |
| `Route34IlexForestGate` | (4,7) | `WARP_CARPET_DOWN` | `COLLISION_ONLY` | `ILEX_FOREST` | 1 |
| `Route34IlexForestGate` | (5,7) | `WARP_CARPET_DOWN` | `COLLISION_ONLY` | `ILEX_FOREST` | 1 |
| `Route35GoldenrodGate` | (4,0) | `DOOR` | `STEP_ON` | `ROUTE_35` | 1 |
| `Route35GoldenrodGate` | (5,0) | `DOOR` | `STEP_ON` | `ROUTE_35` | 2 |
| `Route35GoldenrodGate` | (4,7) | `WARP_CARPET_DOWN` | `COLLISION_ONLY` | `GOLDENROD_CITY` | 13 |
| `Route35GoldenrodGate` | (5,7) | `WARP_CARPET_DOWN` | `COLLISION_ONLY` | `GOLDENROD_CITY` | 13 |
| `Route35NationalParkGate` | (3,0) | `DOOR` | `STEP_ON` | `NATIONAL_PARK` | 3 |
| `Route35NationalParkGate` | (4,0) | `DOOR` | `STEP_ON` | `NATIONAL_PARK` | 4 |
| `Route35NationalParkGate` | (3,7) | `WARP_CARPET_DOWN` | `COLLISION_ONLY` | `ROUTE_35` | 3 |
| `Route35NationalParkGate` | (4,7) | `WARP_CARPET_DOWN` | `COLLISION_ONLY` | `ROUTE_35` | 3 |
| `Route36NationalParkGate` | (0,4) | `WARP_CARPET_LEFT` | `COLLISION_ONLY` | `NATIONAL_PARK` | 1 |
| `Route36NationalParkGate` | (0,5) | `WARP_CARPET_LEFT` | `COLLISION_ONLY` | `NATIONAL_PARK` | 2 |
| `Route36NationalParkGate` | (9,4) | `WARP_CARPET_RIGHT` | `COLLISION_ONLY` | `ROUTE_36` | 1 |
| `Route36NationalParkGate` | (9,5) | `WARP_CARPET_RIGHT` | `COLLISION_ONLY` | `ROUTE_36` | 2 |
| `Route36RuinsOfAlphGate` | (4,0) | `DOOR` | `STEP_ON` | `ROUTE_36` | 3 |
| `Route36RuinsOfAlphGate` | (5,0) | `DOOR` | `STEP_ON` | `ROUTE_36` | 4 |
| `Route36RuinsOfAlphGate` | (4,7) | `WARP_CARPET_DOWN` | `COLLISION_ONLY` | `RUINS_OF_ALPH_OUTSIDE` | 9 |
| `Route36RuinsOfAlphGate` | (5,7) | `WARP_CARPET_DOWN` | `COLLISION_ONLY` | `RUINS_OF_ALPH_OUTSIDE` | 9 |
| `Route38EcruteakGate` | (0,4) | `WARP_CARPET_LEFT` | `COLLISION_ONLY` | `ROUTE_38` | 1 |
| `Route38EcruteakGate` | (0,5) | `WARP_CARPET_LEFT` | `COLLISION_ONLY` | `ROUTE_38` | 2 |
| `Route38EcruteakGate` | (9,4) | `WARP_CARPET_RIGHT` | `COLLISION_ONLY` | `ECRUTEAK_CITY` | 14 |
| `Route38EcruteakGate` | (9,5) | `WARP_CARPET_RIGHT` | `COLLISION_ONLY` | `ECRUTEAK_CITY` | 15 |
| `Route42EcruteakGate` | (0,4) | `WARP_CARPET_LEFT` | `COLLISION_ONLY` | `ECRUTEAK_CITY` | 1 |
| `Route42EcruteakGate` | (0,5) | `WARP_CARPET_LEFT` | `COLLISION_ONLY` | `ECRUTEAK_CITY` | 2 |
| `Route42EcruteakGate` | (9,4) | `WARP_CARPET_RIGHT` | `COLLISION_ONLY` | `ROUTE_42` | 1 |
| `Route42EcruteakGate` | (9,5) | `WARP_CARPET_RIGHT` | `COLLISION_ONLY` | `ROUTE_42` | 2 |
| `Route43Gate` | (4,0) | `DOOR` | `STEP_ON` | `ROUTE_43` | 4 |
| `Route43Gate` | (5,0) | `DOOR` | `STEP_ON` | `ROUTE_43` | 5 |
| `Route43Gate` | (4,7) | `WARP_CARPET_DOWN` | `COLLISION_ONLY` | `ROUTE_43` | 3 |
| `Route43Gate` | (5,7) | `WARP_CARPET_DOWN` | `COLLISION_ONLY` | `ROUTE_43` | 3 |
| `Route43MahoganyGate` | (4,0) | `DOOR` | `STEP_ON` | `ROUTE_43` | 1 |
| `Route43MahoganyGate` | (5,0) | `DOOR` | `STEP_ON` | `ROUTE_43` | 2 |
| `Route43MahoganyGate` | (4,7) | `WARP_CARPET_DOWN` | `COLLISION_ONLY` | `MAHOGANY_TOWN` | 5 |
| `Route43MahoganyGate` | (5,7) | `WARP_CARPET_DOWN` | `COLLISION_ONLY` | `MAHOGANY_TOWN` | 5 |
| `Route5SaffronGate` | (4,0) | `DOOR` | `STEP_ON` | `ROUTE_5` | 2 |
| `Route5SaffronGate` | (5,0) | `DOOR` | `STEP_ON` | `ROUTE_5` | 3 |
| `Route5SaffronGate` | (4,7) | `WARP_CARPET_DOWN` | `COLLISION_ONLY` | `SAFFRON_CITY` | 9 |
| `Route5SaffronGate` | (5,7) | `WARP_CARPET_DOWN` | `COLLISION_ONLY` | `SAFFRON_CITY` | 9 |
| `Route6SaffronGate` | (4,0) | `DOOR` | `STEP_ON` | `SAFFRON_CITY` | 12 |
| `Route6SaffronGate` | (5,0) | `DOOR` | `STEP_ON` | `SAFFRON_CITY` | 13 |
| `Route6SaffronGate` | (4,7) | `WARP_CARPET_DOWN` | `COLLISION_ONLY` | `ROUTE_6` | 2 |
| `Route6SaffronGate` | (5,7) | `WARP_CARPET_DOWN` | `COLLISION_ONLY` | `ROUTE_6` | 2 |
| `Route7SaffronGate` | (0,4) | `WARP_CARPET_LEFT` | `COLLISION_ONLY` | `ROUTE_7` | 1 |
| `Route7SaffronGate` | (0,5) | `WARP_CARPET_LEFT` | `COLLISION_ONLY` | `ROUTE_7` | 2 |
| `Route7SaffronGate` | (9,4) | `WARP_CARPET_RIGHT` | `COLLISION_ONLY` | `SAFFRON_CITY` | 10 |
| `Route7SaffronGate` | (9,5) | `WARP_CARPET_RIGHT` | `COLLISION_ONLY` | `SAFFRON_CITY` | 11 |
| `Route8SaffronGate` | (0,4) | `WARP_CARPET_LEFT` | `COLLISION_ONLY` | `SAFFRON_CITY` | 14 |
| `Route8SaffronGate` | (0,5) | `WARP_CARPET_LEFT` | `COLLISION_ONLY` | `SAFFRON_CITY` | 15 |
| `Route8SaffronGate` | (9,4) | `WARP_CARPET_RIGHT` | `COLLISION_ONLY` | `ROUTE_8` | 1 |
| `Route8SaffronGate` | (9,5) | `WARP_CARPET_RIGHT` | `COLLISION_ONLY` | `ROUTE_8` | 2 |
| `SafariZoneFuchsiaGateBeta` | (4,0) | `DOOR` | `STEP_ON` | `SAFARI_ZONE_BETA` | 1 |
| `SafariZoneFuchsiaGateBeta` | (5,0) | `DOOR` | `STEP_ON` | `SAFARI_ZONE_BETA` | 2 |
| `SafariZoneFuchsiaGateBeta` | (4,7) | `WARP_CARPET_DOWN` | `COLLISION_ONLY` | `FUCHSIA_CITY` | 7 |
| `SafariZoneFuchsiaGateBeta` | (5,7) | `WARP_CARPET_DOWN` | `COLLISION_ONLY` | `FUCHSIA_CITY` | 7 |
| `VictoryRoadGate` | (17,7) | `WARP_CARPET_DOWN` | `COLLISION_ONLY` | `ROUTE_22` | 1 |
| `VictoryRoadGate` | (18,7) | `WARP_CARPET_DOWN` | `COLLISION_ONLY` | `ROUTE_22` | 1 |
| `VictoryRoadGate` | (9,17) | `WARP_CARPET_DOWN` | `COLLISION_ONLY` | `ROUTE_26` | 1 |
| `VictoryRoadGate` | (10,17) | `WARP_CARPET_DOWN` | `COLLISION_ONLY` | `ROUTE_26` | 1 |
| `VictoryRoadGate` | (9,0) | `DOOR` | `STEP_ON` | `VICTORY_ROAD` | 1 |
| `VictoryRoadGate` | (10,0) | `DOOR` | `STEP_ON` | `VICTORY_ROAD` | 1 |
| `VictoryRoadGate` | (1,7) | `WARP_CARPET_DOWN` | `COLLISION_ONLY` | `ROUTE_28` | 2 |
| `VictoryRoadGate` | (2,7) | `WARP_CARPET_DOWN` | `COLLISION_ONLY` | `ROUTE_28` | 2 |

## 新门房必须先登记的动作合同

每条入口单独核对：来源地图、出入口坐标与面向、Gold Warp 目标编号、RPP 0-based 目标编号、落点格以及前后两格 Gold 碰撞，切图后 `NONE`还是 `D_UP/D_DOWN/D_LEFT/D_RIGHT` 自动一步，错误方向和立即反向行为。
非对称合流必须列出 2→1 对应；剧情/场景脚本与门房到达步行**分开登记**。
已有的 `GetJohtoWarpArrivalStep` / `PlayerStepOutFromDoor` 只在有证据的目的地增加精确规则，不可因 `NORTH_SOUTH_PAIR` 就为上下两端都追加一步。
此审计不修改 ROM、Gold 源码，也不能代替编译和手机实机测试。
