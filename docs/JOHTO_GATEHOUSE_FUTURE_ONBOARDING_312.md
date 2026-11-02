# DEV-312｜未来城都门房接入模板（Route43 预备）

## 目标与边界

本轮把 REF-303～310 建立的门房共用成果整理成**后续门房可直接复用的接入合同**。不再要求用户重复测试已经完成的门房，也不重做既有六座门房。

用户已明确：此前六座门房已经完成；此前要求复测的门房也都已测试，未发现问题。现有门房按稳定基线保留。

## 首批未来对象

Gold 已为后续两座门房预留稳定 ID：

| 稳定 ID | Gold 地图 | 形状 | 碰撞后端 | 特殊事件 |
|---:|---|---|---|---|
| 65 | `Route43MahoganyGate` | 纵向 5×4 | `JOHTO_GATE` / `Gate_Coll` | 1 名 Officer，无 scene/callback |
| 66 | `Route43Gate` | 纵向 5×4 | `JOHTO_GATE` / `Gate_Coll` | Rocket 收费事件、2 个 scene、1 个 callback、3 个对象 |

两张 Gold 地图都使用 `NorthSouthGate.blk`，80 个 8×8 碰撞格的分布相同：56 FLOOR、12 COUNTER、8 WALL、2 DOOR、2 WARP_CARPET_DOWN。它们不应套用圆朱的横向地毯 helper，也不应套用公园掩码。

## 运行逻辑复用

- 两座未来门房使用已存在的通用路径：`JohtoOverworldSouthLandDecision` 返回 `E=2` → `CollisionCheckOnLand` → `CheckForJumpingAndTilePairCollisions` → `CheckTilePassable` → `wTilesetCollisionPtr` 指向的 `Gate_Coll`。
- 运行图块集为 `JOHTO_GATE`。5×4 紧凑运行布局可沿用已验收的 ID19 `Route36RuinsOfAlphGate` 表示；本轮源级执行器以该布局为只读夹具，Gold 碰撞期望仍分别从两个候选 Gold 地图解码。
- 通用 Gate_Coll 执行器已取消 6/19/102 的硬编码 stable-ID 白名单。调用方必须先在 profile 中明确选择 `legacy_gate_tilecoll`，然后才可用同一执行器检查任意 stable ID。这让未来符合该后端的门房不需要再改一遍执行器。
- 本轮分别对 ID65 和 ID66 执行 218 条 ASM 相邻步进轨迹，均与各自 Gold 可走格一致。

## 必须分层的部分

- ID65 的 Officer 对话及 `EVENT_CLEARED_ROCKET_HIDEOUT` 条件留在 ID65 自己的 map script/text/object 数据。
- ID66 的 Rocket 收费、1000 元处理、scene/callback、`EVENT_ROUTE_43_GATE_ROCKETS` 和火箭队对象留在 ID66 自己的 map script/event 数据。
- 两座门房可以共享碰撞后端和同一 5×4 地图布局，但不能共享 NPC 列表、文字指针、剧情状态或 Warp 目标。

## Warp 合同

两张门房各有 4 个 Gold Warp。上端 DOOR 向 UP 踏入，目标地图的 WARP_CARPET_DOWN 决定到达后不自动迈步；下端 WARP_CARPET_DOWN 只在 DOWN 碰撞时触发，目标地图为 DOOR 时按 Gold 规则自动 D_DOWN。

Gold 一基 Warp 序号必须在未来 runtime Warp 表压缩后重新映射；不得直接把 Gold 序号当作 RPP 零基 ordinal。Route43、Route44 和未审计的室外入口保持关闭，直到路线本身的资源、Warp、边界、音乐、地点、NPC/事件及 ROM Bank 合同独立通过。

## 自动审计

`tools/johto_gatehouse_future_profiles_312.json` 保存候选配置；`tools/johto_gatehouse_onboarding_312.py` 校验：

1. Gold 地图名、Tileset、GATE 环境、5×4 尺寸和 NorthSouthGate 来源。
2. 四个阈值格的碰撞角色、触发类型、方向、目标 Warp 和到达自动步进。
3. ID65/66 的独立 scene/callback/object 事件数量及关键事件标志。
4. `JOHTO_GATE` → `Gate_Coll` 的通用运行路径及 218 条源码级步进。
5. ID65/66/67/69 仍未注册到活动槽，活动地图数仍为 38；新门房不能因加入候选合同而提前开放。

该审计已接入 `johto_pilot_migration_audit.py`，Gold 参考可用时会随综合迁移审计运行。它是静态/源码级验证，不是 RGBDS 编译、ROM CPU 模拟或实机验收。

## 版本说明

DEV-311 是 tools/tests/docs-only，因此按项目规则保留游戏内 `REF-310`，不应为了工具脚本变化虚增 ROM 版本。DEV-312 同样只建立未来门房接入合同，开发包编号为 `DEV-312`，游戏内仍为 `REF-310`。等 ID65/66 的实际运行地图、Warp 或 ASM 被激活并修改时，再统一提升游戏版本为 `REF-311`，并由用户本机生成新 MAP 验证。


## DEV-314：纵向门房共享运行逻辑

REF-312 将 ID65 原先按地图写的五类阈值/落点/边界判断抽成 Bank $53 的数据驱动公共函数。

- `JohtoPilotIsVerticalGatePairMap314` 是唯一 stable-ID allowlist；兼容门房只在这里登记一次。
- `data/johto_vertical_gate_runtime_314.asm` 保存 before-step、after-step、arrival 和 bounds 配置。
- `JohtoVerticalGateBeforeStep314`、`AfterStep314`、`CollisionExit314`、`ArrivalStep314`、`ClosedEdge314` 由 ID64/65 共用。
- 新增同布局门房时，先按 Gold 原版确认尺寸、门槛坐标、方向和落点，再增加配置行；不得复制整套 ASM。Warp 目标、地图 Header、NPC 和剧情仍分别登记。
- ID66、Route43 室外和愤怒之湖仍关闭。本轮没有打开它们。
- 本轮只做源码/静态验证，未编译 ROM；新 MAP 的 Bank/ROM0 余量和设备行为尚未确认。
