# FIX-263｜联合洞穴1F洞口和骑行合同（静态开发候选）

## 参考数据（已对照用户交接包）

| Gold / RPP | 位置 `(X,Y)` | Gold 碰撞 | 开放状态与运行触发 |
|---|---|---|---|
| Route32 | `(6,79)` | `CAVE` | 从 `(6,80)` 朝上进入到1F北口 |
| UnionCave1F 北口 | `(17,3)` | `WARP_CARPET_DOWN` | 到达停留原位；站在这里按 DOWN 撞南侧墙才回 Route32 |
| UnionCave1F 南邻格 | `(17,4)` | `WALL` | 不可随意通行或作为 STEP_ON 洞口 |
| Route32 回程安全格 | `(6,80)` | `HOP_DOWN` | 从洞口 `(6,79)` 安全向南走一步 |
| UnionCave1F 南口 | `(17,31)` | `WARP_CARPET_DOWN` | 暂时未开放，Route33 未激活 |
| UnionCave1F 的 B1F 楼梯 | Gold 原版 | `STAIRCASE` | 未开放，不能误 Warp |

Gold 输入：`REFERENCES/Gold/pokegold-master`，
旧参考：`REFERENCES/NPC/NPC-5.62.243` 的
`engine/overworld/region_map_lookup.asm` / `engine/overworld/npc_movement.asm` /
`data/bike_riding_tilesets.asm`。旧实现保留洞内 Warp 格并用 DOWN 碰壁触发，
只在回到 Route32 时自动安全南移。洞穴专用 Tileset 允许自行车；
不因此为 Gold `INDOOR` 建筑、一般门房或其它新 Tileset 开放。

## 与之前错误的区别

旧 `.260` 在 `JohtoPilotGateArrivalStep` 误给洞内 `(17,3)` 设置 `D_DOWN`，
而同一位置的回程 `JohtoPilotGateCollisionExitAllowed` 又要求 `PLAYER_DIR_UP`，
两者自相矛盾；`JohtoPilotGateDoorApproachAllowed` 和 `JohtoPilotGateDoorWarpMatched`
也将这个碰壁式地毯错处理成 `DOOR`。原有的 Gold 坐标与双向 Warp 表正确，
但方向和到达策略错误。新代码限定洞内上下左右和撞墙来源，不更改其他门房。

## 自动检查／验收边界

```sh
python tools/johto_union_cave_portal_audit.py --root . --gold-root /path/to/pokegold-master
python tools/johto_pilot_migration_audit.py --project . --gold-root /path/to/pokegold-master
python -m unittest discover -s tools/tests -p 'test_johto_union_cave_portal_263.py'
```

专用门禁验证精确入洞坐标、碰撞方向、保留原地/室外安全步、Bike 白名单、
唯一双向 Warp 以及 Gold 实际碰撞；故意破坏这些条件时必须报错。
尚无新 `.263` Red/Blue 链接或设备实测证据；强烈建议先验收
入洞朝向、北口返回、非北口无误传送、骑车、Surf、Continue、南北门房回归。
