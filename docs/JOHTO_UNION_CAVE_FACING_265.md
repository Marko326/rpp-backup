# FIX-5.62.265｜联合洞窟北口进洞朝向回归修正（开发候选）

## 现象与成因

用户确认正确预期：Route32 `(6,80)` 向北进入洞口 `(6,79)`，到达 Union Cave 1F `(17,3)` 仍然面向 **UP**；玩家想出洞时主动按 **DOWN**（南边 `(17,4)` 为 WALL）触发 Warp，再从 Route32 `(6,79)` 自动向南一格至 `(6,80)`，最终朝 DOWN。

`FIX-264` 文档和运行时代码把 Gold `WARP_CARPET_DOWN` 的触发方向误解释为进洞应面向 DOWN，于是 `JohtoPilotGateArrivalStep::.caveFacing` 写入 `wPlayerDirection`、`wPlayerMovingDirection`、Sprite facing；工具也错误地将这种覆盖固定为 PASS 条件。旧 NPC-5.62.243 的到达步骤对洞内地毯没有方向覆盖，Gold `(17,2)` 为 FLOOR，`(17,4)` 为 WALL。需要保留玩家的正常朝北进入方向，而不是编写新的预测器或强制转为 UP。

## 最小改动及保留机制

- `JohtoPilotGateArrivalStep` 在 `JOHTO_UNION_CAVE_1F_LOCAL_ID` 直接返回 `E=0`：不执行模拟方向键，不强制重写三个朝向状态。
- `PlayerStepOutFromDoor` 在该地毯上不执行 DOOR 自动移步；继续复用移动引擎的原生方向。
- `.264` 的出洞前置链 `wd736` / `ExtraWarpCheck` / ROMX 判定 / Carry / `CheckWarpsCollision` / 精确 `DOWN` 碰撞判断全部不变。回到 Route32 自动 `D_DOWN` 一步规则不变。
- 修正 `johto_union_cave_portal_audit.py`、`test_union_cave_260.py`、`test_johto_union_cave_portal_263.py` 的错误验收；故障注入覆盖任意到达强转方向和错误自动步进。
- 维持 `TEST-231`、活动地图数量、存档、Surf、骑车、金银遗迹门房与关都所有代码路径。Route33、B1F/B2F 不开放。

## 本机验收清单

1. 本地构建正式红／蓝与 TEST 红／蓝，检查新的 MAP 空间，不使用旧 `.264` MAP 证明 `.265` 链接成功。
2. 32号道路朝北进入：在洞内 `(17,3)` 原地朝上，下一次按 UP 能正常走向洞内 `(17,2)`，不是自动转身或自动走一步。
3. 回到 `(17,3)` 主动按 DOWN，碰南墙触发回程；落到 Route32 后只朝下自动走一格到 `(6,80)`。
4. 立即重新入洞、单按 UP/LEFT/RIGHT 不应直接出洞；骑行、Surf、Continue 与门房回归。

以上静态验证不代表实机成功；未经用户验收不得制作正式提交日志。
