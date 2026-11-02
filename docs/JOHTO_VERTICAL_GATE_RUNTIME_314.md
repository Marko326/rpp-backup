# DEV-314 / REF-5.62.317：纵向门房共享运行逻辑

## 当前范围

这套 Bank `$53` 数据驱动运行逻辑服务于 Mahogany Town、ID65 `Route43MahoganyGate`、ID66 `Route43Gate` 与 Route43 的纵向门房入口。地图 Header、Gold Warp 对象、NPC、文本、音乐/骑车规则和剧情事件仍按地图独立登记；不能因为共用门房逻辑就把门房外观或剧情合并。

ID66 已作为门房通行骨架启用，但 Rocket 1000 元收费剧情、Officer 后期 TM36 奖励仍未移植；Lake of Rage 物理连接仍保持关闭。

## 共享运行入口

`engine/johto_pilot_runtime.asm` 中的 `JohtoPilotIsVerticalGatePairMap314` 是唯一 stable-ID allowlist。五个移动/落点 hook 调用共享函数：

- `JohtoVerticalGateBeforeStep314`
- `JohtoVerticalGateAfterStep314`
- `JohtoVerticalGateCollisionExit314`
- `JohtoVerticalGateArrivalStep314`
- `JohtoVerticalGateClosedEdge314`

配置集中在 `data/johto_vertical_gate_runtime_314.asm`。同一套函数读取地图 ID、方向、坐标和 profile result，不复制每座门房的分支代码。

## Route43 两端门毯的不同合同

两组室外门毯在 Gold 中都是 `WARP_CARPET_DOWN`，碰撞权限为 `LAND_TILE`，但 RPP 的粗粒度角色网格和 Warp 调度不能简单把它们混成一个规则。

| 位置 | Gold / RPP 规则 | 允许动作 | Warp 触发 |
|---|---|---|---|
| ID65 南端 `(9/10,51)` | 角色网格值为 0 | 正常走到门毯；不增加 BeforeStep 放行 | 站在门毯上继续向下，撞到 y=52 森林边界，由 E=1 collision exit 返回 ID65 |
| ID66 北端 `(17/18,31)` | 粗角色网格保持值 1，fail-closed | 精确 BeforeStep：从 `(17/18,30)` 向下进入；在 `(17,31)` 向右换到 x18；在 `(18,31)` 向左换到 x17 | 向下进入门毯后 AfterStep E=1；站在门毯继续向下发生碰撞时才触发 ID66 Warp |

ID66 横向换道后的 AfterStep 使用 **E=3**。`CheckWarpsNoCollision` 对非 E=0/2 的 profile 结果跳过通用 step-on Warp；`JohtoVerticalGateCollisionExit314` 只接受 **E=1**。因此 E=3 只表示横向换道，不是碰撞出口，不会误把左右移动变成 Warp。

北侧角色网格故意保持墙值，不是把 Gold 地毯判成墙：Gold 的 `WARP_CARPET_DOWN` 仍是 `LAND_TILE`。BeforeStep hook 在 `JohtoEastSpatialStep` 角色网格碰撞之前运行，只开放四个精确移动起点/方向；x16/x19 侧墙、y32 下方边界和 Route43 的 DOOR `(17,35)` 继续阻挡。不要把 `(17/18,31)` 全局改成可走角色值，否则会绕过精确方向约束。

## ID65 / ID66 室内门房配置

两座室内地图均复用 Gold `NorthSouthGate.blk` 的 5×4 布局：

- 下端两格 WARP_CARPET_DOWN：从室内地面向下进入；AfterStep E=1，碰撞方向触发。
- 上端两格 DOOR：向上进入；AfterStep E=2，走原生 DOOR/STEP_ON 路径。
- 到达上端 DOOR 时按 Arrival profile 向下自动迈一步；到达门毯时不自动迈步。
- ID65 和 ID66 均为 10×8 个 16×16 角色格；未登记的边缘方向保持 fail-closed。

## 防回归测试

开发者内部审计必须覆盖完整移动序列，而不只是检查 Warp 表：

1. 从 ID66 出门落在北侧地毯。
2. 两格地毯之间左右换道，并能换回。
3. 从地毯向上离开，再向下回踩地毯。
4. 站在地毯上继续向下，确认只在 E=1 碰撞路径触发 Warp。
5. 向外侧墙和 y32 边界移动仍被阻挡。
6. 故意删掉 BeforeStep、把 E=3 改成 E=1、把北侧角色网格全局打开或把视觉 tile `$40` 加入通用 step-on warp 列表，审计必须失败。

`tools/johto_route43_gate_319_audit.py`、`tools/johto_vertical_gate_runtime_314.py` 与对应 pytest 是开发者内部工具，由开发流程运行，不需要用户操作。它们是源代码/数据级合同和有限移动模型，不是 RGBDS CPU 仿真或实机验收。

## 构建与验收边界

REF-317 更新了等长游戏版本标签，并调整 Bank `$53` profile 数据；没有新增 ROM0 运行指令。当前未执行 RGBDS 汇编/链接，未生成 REF-317 Red/Blue/Battle-test MAP，也未进行手机实测。因此 ROM0 是否仍至少保留 64 B、Bank `$53` 最终余量和设备上的实际移动效果，仍需新构建后确认。
