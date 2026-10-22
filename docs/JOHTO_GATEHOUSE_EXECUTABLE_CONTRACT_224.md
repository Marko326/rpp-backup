# .224 城都门房运行合同：不允许凭“看过规范”放行

> **当前规则以 `.237 Gold Collision Matrix` 为准，覆盖本文件中较早的 `.215 Route34` 踏格例外记录。** 原始事故记录保留历史，但不能再作为当前规则：Gold Route34 `(13/14,37)` 是 `WARP_CARPET_DOWN`，必须 collision-only；所有 Gold `WARP_CARPET_<DIR>` 都可站立并按方向碰撞，只有 Gold 实体 `DOOR` 走 STEP_ON。到达后步进由目标格碰撞类型单独决定。

该合同已在 **`.224` 用户实机认可后正式收口**。加固补丁本身仅修改工具／测试／文档，不修改门房游戏 ASM、ROM0 或 ROM 版本。用户报告的门房场景已验收，但脚本仍只构成静态执行路径证明，不冒称完整逐帧 CPU 验收。

## 要解决的重复事故

1. 踏上门毯就自动传送，无法站定或横移（Route35 .224、早期 P16）。
2. 上下/左右混用触发器；面向错误方向也触发、立即掉头卡门。
3. 把门房到达后 `D_DOWN` 当作“踩毯即传送”；上下两个出口盲目加步进；提前或过度走动。
4. 只更新 `LoadMapData`，漏掉连接快速切图 `.ordinaryConnection`，屏幕顶部/底部退化成默认树林边框。
5. 独立 RGB/图块/紧凑 blockset 映射漏检，误用另一图块集相同编号。
6. Python PASS 不等于 `rgbasm/rgblink` PASS，更不等于 ROM 实机输入/动画 PASS。

## 现在强制执行的规则

- `tools/johto_door_contracts.json` 中每个已开放的 `GATE_INDOOR` 必须声明 `gatehouse_runtime`：布局两侧、**每侧两条 Warp 的坐标+目标 slot**、与 Gold 比对的实际图块布局、是否使用原 RPP 旧碰撞引擎、全部入口的 `map_local`/坐标/正确方向/`STEP_ON` 或 `COLLISION_ONLY`、完整原生双向索引（可含双入口合流）、入门后按目的地精确匹配的每格 `NONE`/`D_*`、室外 border 策略。
- `johto_gatehouse_behavior_audit.py` 对每处原生入口的 **四个方向实际解释执行** `JohtoNorthGateStepWarpAllowed`、`JohtoGateCollisionDirectionAllowed`，有需要的入口同时执行 `JohtoInternalDoorFacingCheck`。**识别不了的 ASM 指令、未知跳转、没落到返回路径一律 FAIL**，不会自动作“安全假设”。
- 按真实 `data/mapObjects` 读取运行时的 Warp，核对 Gold 源地图的独立坐标，以及 `NativeRegionWarpTargets` 的所有源/目标/0-based slot；方向合同不能漏掉任何已登记室内门口或门房来源的室外门口。保留两个入口汇入一个单格出口的有效模型。
- `GetJohtoWarpArrivalStep` 切图后步进表必须与 `arrival_step_review` 两侧结论及全部目的地实际相符；**NONE 是缺少表项，不是伪造一条 `D_DOWN`**。存在 `D_*` 的真实落点必须在图内且碰撞 mask 中可行走。
- 既有已开放门房必须继续经过 Gold 的真实 metatile 来源转紧凑布局对照、Gold RGB 和 Kanto 资源隔离检查；ROM0 `home/overworld.asm` 的共享入口必须真的调用方向、碰撞和走步判断，防止只剩无用函数空壳。
- 屋顶/门外背景在 `LoadMapData` 与 `.ordinaryConnection` 两条加载路径都必须调用 ROMX border dispatcher，且顺序为 Azalea 西边、Goldenrod 北边、Route35 南边。**不允许把 Render-only 边框误当可穿越地图连接**。
- 当前 Gold-derived 规则：31 号道路—桔梗市保留旧版 RPP `LEGACY_COLLISION` 执行器（语义仍为碰撞触发）；桧皮镇—桐树林南门房使用横向 `COLLISION_ONLY`；所有方向门毯都可站立并只在编码方向碰撞时 Warp；只有 Gold 实体 `DOOR` 使用 `STEP_ON`。**35 号道路外侧、Route34 外侧和所有南北门房室内南侧门毯均不能踏格立即 Warp**。历史 `.215` Route34 例外已由 `.237` Gold 源数据覆盖，不再是当前规则。
- `tools/johto_map_release_audit.py` 直接运行上述门房审核，并强制收集本轮关键反向测试，缺门房配置、漏 Warp、错误方向、错路由、越界/墙中落点、删两条刷新路径中的一条、改走步表，均不得 PASS。

### .237 Gold 全门房统一矩阵

- Gold 原版共盘点 24 个 `*Gate*.asm` 地图、100 个 Warp 坐标：26 个 `DOOR`，30 个 `WARP_CARPET_DOWN`，22 个 `WARP_CARPET_LEFT`，22 个 `WARP_CARPET_RIGHT`。`tools/johto_gold_door_audit.py::GoldCollisionIndex` 由 Gold `.blk` 和原始 `tilecoll` 解出角色；`johto_warp_reference_profiles.py --inventory-gold-gates` 逐个输出坐标、角色、预期触发、目标 Warp。
- 当前 9 座 RPP 门房的 67 个入口、55 个到达点都独立对照 Gold；门毯触发方向必须与 `WARP_CARPET_<DIR>` 后缀相同。所有当前活动门房均按单格/双格每一条 Warp 逐个登记，2→1 合流不可被压成假对称。
- `DOOR` 的 STEP_ON 和门毯的 COLLISION_ONLY 是入口规则；目标格的 `D_DOWN` / `NONE` 是到达规则。Gold 的 DOOR 目标（包括进入北侧门房落在室内北门砖、或从南门毯退出落在室外实体门砖）可触发目标侧向下离开；门毯目标必须 NONE。不能在源门毯上执行自动步进。

## 开发与运行

```sh
# 在 RPP 工程根目录，必须提供完整的 Gold 原版工程：
export JOHTO_GOLD_SOURCE=/path/to/pokegold-master
export JOHTO_GOLD_ROOT=$JOHTO_GOLD_SOURCE
python tools/johto_gatehouse_behavior_audit.py --rpp . --gold "$JOHTO_GOLD_SOURCE"
python -m unittest discover -s tools/tests -p 'test_johto_gatehouse_behavior_hardening224.py' -v
python tools/johto_map_release_audit.py --rpp . --gold "$JOHTO_GOLD_SOURCE"
```

截至本轮收口，统一门禁还有已登记的 **SafariZoneBeta** 旧素材窗口问题；它不属于门房，不为测试绿灯删除它。**没有独立真实 ROM 构建、时序轨迹和实机视频的功能验收时，只能说 `STATIC_CONTRACT_PASS`。**

新增的关卡必须把运行规则填进合同，实际源码符合后再通过门房审计；如果以后合法重构 ASM，先更新受限解释器或改用真正 ROM 模拟测试，不能简单删断言。

## 与本轮视频的关系

`224金黄门房.mp4`、`金版金黄市和35道路的门房(1).mp4` 表明两边场景具有相近的屋内布局和两侧出入口；Gold 原版室内可见门房 NPC，而 RPP 的阶段开发里尚未实装。另在本次截取的室外对照帧，RPP 约 14s 有 `Route 35` 地点名条，Gold 约 11s 对照帧没有；两段录像切图时刻不同，不能仅凭该帧差异就判定它违反 Gold 规则，此项保留待实机确认，不能强行收口成“完全相同”。录像也不能独立证明每个按键释放、四向擦边与逐帧动画状态，因此新测试固定的是**源码级实际执行分支与独立 Gold 资源**，不是视频已证明所有运行行为完全一致。
