# REF-303｜门房共享引擎开发说明

基线：`27a2086219b56238e26844676f3a5328e5b567ee`，干净已提交的 FIX-302/TEST-233。

本次实际 ROM 显示版本：**`REF-5.62.303`（正式）／`TEST-234`（测试）**。这两个版本必须与旧 `FIX-5.62.302`／`TEST-233` 区分，禁止使用旧生成 MAP 验收新 Bank 空间。

## 合并内容

- **运行时共享**：ID23 和 ID62 的横向入毯判定合并为 Bank `$53` 的 `JohtoGateHorizontalCarpetInbound303`；同 Bank 的东门房 `call`，Bank `$4E` 的西门房 `callab`。使用两个5字节坐标记录（stable ID、左右X、上下Y），通过下一步目标格验证。在表外地图、墙壁目标或未登记的地毯位置一律不获得放行例外。
- **未改动**：全部活动门房的原 Gold `.gold.blk`、`.runtime.blk`、`roles.bin`、成熟阻挡掩码、Warp/连接、方向出口、音乐和骑车许可；没有增加 ROM0 指令或更改存档布局、地图 ID、活动地图数。
- **不同后端**：ID6/19/102 继续使用 `Gate_Coll`；ID11/13/18/104 使用 Gold role grid；ID105 公园东门房使用成熟掩码；ID23/62 使用新的共享入毯判定+各自成熟掩码。两座公园门房维持原版 INDOOR 禁止骑车，而其他8座 GATE 可以骑车。

## 共用配置登记

统一审计源为 `tools/johto_gatehouse_profiles_303.json`，记录10座门房的 stable ID、Gold名称、横/纵向布局、碰撞后端、`GATE`/`INDOOR` 与自行车许可；审计逐条与已激活门房 Warp 合同、原版 Gold 环境及既有音乐/骑车合同交叉验证，不允许通过修改配置绕开原版差异。新增门房若没有登记或出现策略漂移必须失败。

这份 JSON 是离线开发审计的统一配置，不会被游戏动态加载；只有 ID23/62 的横向门毯坐标在 ROM 中采用共享数据表。其余8座保持原版行为，不能冒充“ROM 已全部数据驱动”。

## DEV-311｜原生 Gate_Coll 路径也纳入源码级追踪

- ID6／19／102 没有改用 REF-303 的圆朱门毯 helper，但并非三份独立代码；它们共用 `JohtoOverworldSouthLandDecision` 的 E=2 fallback、RPP `CheckTilePassable` 和 `Gate_Coll` 列表。十座门房现在共计 1,925 条受限源码级相邻步进轨迹；这不是完整 ROM CPU 仿真。
- DEV-311 扩展 `tools/johto_gatehouse_step_trace_308.py`，执行实际 dispatcher 和 `CheckTilePassable` 指令循环。目标 tile 从当前 runtime block map 与 `johto_gate.bst` 计算，Gold 逐格 walkable roles 作期望值；步数为 ID6=172、ID19=218、ID102=172。
- 通过负向注入检查错误分派、错误寄存器比较和 GetTileAndCoordsInFrontOfPlayer 的方向采样偏移。
- **保留原生 Gate_Coll 后端**：它已经是共享通用实现，不为“看起来统一”而改成 role-grid；ID19 顶部 DOOR 和 ID6／102 的方向门毯触发继续走现有 Warp guard。
- 此为有限源级追踪，不代表 ROM CPU 执行或实机验收；完整移动帧、sprite collision、Bank、Warp、存档和 bike/music 仍由本机回归覆盖。

## 必须回归

1. ID23/62 各172条地图内相邻移动，包括从上方/下方普通地面入毯、室内侧面入毯、地毯上下换道、逆向返回、墙壁阻断。
2. 两个 profile 任一坐标漂移/方向分支变更必须被共享 ASM 源级解释器报错；跨图不允许命中。
3. `johto_gatehouse_behavior_audit.py` 10门房32地毯；`johto_gate_music_bike_audit.py` 校验 GATE/INDOOR 与来源续播；Gold 来源和各专门回归依旧强制。
4. 用户本机 Red/Blue/TEST 编译后检查最新 MAP ROM0≥64B，尤其 Bank `$4E`/`$53`；步行/骑车重复两座圆朱门房四方向，回归公园两门房禁骑车和正确 Warp。

边界：只做**共用入毯引擎的第一阶段**，不声称十座门房已经在 ROM 中使用同一套完整 Warp/碰撞后端；不同的 Gold DOOR/地毯触发模式不可直接合并。
