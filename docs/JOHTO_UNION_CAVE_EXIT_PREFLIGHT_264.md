# FIX-264｜联合洞穴1F不能返回32号路：前置 Warp 判定漏接

## 复现与正确 Gold 行为

用户 `62623.mp4` 展示 FIX-263 已进入 Union Cave，但在北入口无法回到32号路。Gold 原版的洞内 `(X=17,Y=3)` 是 `WARP_CARPET_DOWN`，南方 `(17,4)` 是墙；需要原地朝 DOWN 碰撞传送。南出口 Route33 及 B1F/B2F 尚未开放。

## 确切调用链

1. `CollisionCheckOnLand` 对南墙返回 carry，并由已登记 Warp 的 `wd736` bit2 走 `ExtraWarpCheck`。
2. `ExtraWarpCheck` 先调用 ROMX `JohtoPilotGateExteriorCollisionAllowed`。原 `.263` **未对联合洞穴登记**，按旧一般室内地图执行 `IsPlayerFacingEdgeOfMap`，入口不在边缘，因此不设置 carry。
3. `CheckWarpsCollision` 只在 ExtraWarpCheck carry=1 时执行；`.263` 的后置 `JohtoPilotGateCollisionExitAllowed` 虽已检查 `(17,3,DOWN)`，但从未抵达。
4. 本版在前置函数看到 Union Cave ID8 时 `jp z, JohtoPilotGateCollisionExitAllowed`，重用同一个 `(17,3,DOWN)` 判定；前置返回 e=1 才由 `ExtraWarpCheck` 设置 carry，再由后置 guard 二次过滤。

## 参考分支

旧 NPC `docs/JOHTO_GATEHOUSE_READ_FIRST.md` 与 `RPP_DEVELOPMENT_PITFALLS.md` 曾记载 Route38 等非边缘门口漏登记 ExtraWarpCheck 导致不能进入。采取同一条成熟原则：**两个层次同时开放且共享同一个坐标/方向合同**，不直接复制旧分支完整 Map/Bank 结构。

## 入洞朝向，不是自动行走

视频显示人物到达洞口后仍朝向来时的出口（UP）。该问题不同于不能 Warp：`JohtoPilotGateArrivalStep` 对 Cave 原先立即返回0，没有新方向也没有自动移动。本版在目的地恰为 `(17,3)` 时只写角色朝向为 DOWN（`wPlayerDirection`、`wPlayerMovingDirection`、`SPRITE_FACING_DOWN`），**不写坐标，也不设置模拟方向键**。因此人物在洞口原地朝向洞内，玩家下一次自己按 DOWN 才撞墙离开。

## Warp 状态初始化（第三个门槛）

`EnterMap` 原来只给 `JOHTO_HOUSE` 和 `JOHTO_GATE` 执行 `IsPlayerStandingOnWarp`，联合洞穴从 Route32 传送落到 `(17,3)` 时也可能没能置位 `wd736` 的站在 Warp 标志，主循环在碰撞后会先检查 bit2，没置位则直接回循环，连 `ExtraWarpCheck` 也进不去。本版把 `JOHTO_UNION_CAVE` 加入这一**按地图装载时**的精准 rearm 路径，先清陈旧 bit2，再仅由已登记的洞口 Warp 重置；这与踩到地毯立即传送完全不同。

## 冲突路径保护（这次同步修复）

把洞穴加入 `ExtraWarpCheck` 后，会让此前默认失败的 `CheckWarpsNoCollision` 回退判定也成功：玩家**无碰撞**踩到洞穴地毯时可能被立即传走。因此 `home/overworld.asm::CheckWarpsNoCollision` 必须与 `JOHTO_HOUSE`/`JOHTO_GATE` 一样跳过 `JOHTO_UNION_CAVE` 的无碰撞远检查，同时**保留先前设置的 `wd736` bit2**；真正朝下撞墙时才沿 ExtraWarpCheck/CheckWarpsCollision 触发。新增逆向测试防止这条保护丢失。

## 新防回归

`tools/johto_union_cave_portal_audit.py` 不再只确认最终 guard 的文本，而要验证 ROM0 `ExtraWarpCheck` 前置调用及 carry、`CheckWarpsCollision` 最终调用，并解释执行前置+最终 ROMX 子程序，遍历正向 (17,3,DOWN) 与错误方向、邻近坐标、错误地图的拒绝结果。测试故障注入会删除洞穴前置分派、破坏 Carry 或调换最终调用，并要求 FAIL。

验证运行：

```sh
python tools/johto_union_cave_portal_audit.py --root .
python -m unittest discover -s tools/tests -p 'test_*.py'
python tools/johto_pilot_migration_audit.py --project . --gold-root /path/to/pokegold-master
```

本阶段只有源码和静态回归；手机复测/正式 RGBDS 构建没有执行。开发补丁基线以已应用 FIX-263-R1 为增量起点；实际用户 Worktree 未再次上传，若新增工作区修改必须先对照/验补丁，不能忽略失败。
