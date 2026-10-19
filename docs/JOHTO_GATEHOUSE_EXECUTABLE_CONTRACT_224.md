# .224 城都门房运行合同：不允许凭“看过规范”放行

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
- 已登记的四座城都门房中，31 号道路—桔梗市使用旧版 RPP 的 `LEGACY_COLLISION`；桧皮镇—桐树林南门房使用横向 `COLLISION_ONLY`；桐树林北门房使用经 .215 确认的竖向踏格分支；**35 号道路外侧门毯只能先站上去，再向下碰撞入门**，不能复原曾经错误的 `.224` 踏格立即 Warp。不能为统一代码而随意合并不同类别。
- `tools/johto_map_release_audit.py` 直接运行上述门房审核，并强制收集本轮关键反向测试，缺门房配置、漏 Warp、错误方向、错路由、越界/墙中落点、删两条刷新路径中的一条、改走步表，均不得 PASS。

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
