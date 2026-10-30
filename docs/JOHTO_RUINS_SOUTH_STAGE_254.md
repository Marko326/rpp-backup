# ALPH-SOUTH-001｜阿露福遗迹南侧入口准备阶段（非游戏激活）

## 本轮确定做到哪里

以用户新上传 `MAP-5.62.253.zip` 为基础、交接包的 Gold `pokegold-master` 与旧 `NPC-5.62.243` 为参考，先准备 **32号道路→东西向遗迹门房→阿露福遗迹外围** 的原版地图块与后续 Warp 合同，顺手冻结北侧36号路及南北门房的 Gold 原始布局。**只完成资源/落点审计；不把这四张图加入运行中的9个活动地图。**

| Gold 地图 | 稳定 ID | 块尺寸 | 本轮成果 | 本轮是否可进入 |
|---|---:|---:|---|---|
| Route32RuinsOfAlphGate | 102 | 5×4 | Gold 原图、复用已验证 EastWestGate 的 compact 候选块 | 否 |
| RuinsOfAlphOutside | 20 | 10×18 | Gold 原图、旧 NPC-5.62.243 的 compact 候选块，九处块号转译复核 | 否 |
| Route36RuinsOfAlphGate | 19 | 5×4 | 原版 NorthSouthGate 数据 | 否 |
| Route36 | 16 | 30×9 | 原版道路数据 | 否 |

所有地图原始 `.gold.blk` 与 `.candidate.blk` 放在 `maps/johto_staged/`，因此当前游戏根本不会 INCBIN 新图块，减少 Bank/碰撞回归风险。候选不是批准的运行图块；特别是遗迹的共享 tile 仍需按 Gold 碰撞审计出口、楼梯和围栏。后续正式启用时，还要处理场景音乐、地点栏、骑车许可、边缘阻挡、Source/Runtime/Header/Slot/Profile/Fly-Town Map 同步注册。

## 后续通道与关闭口

原版 Warp 由 `tools/johto_ruins_stage_contract.json` 逐条记录（0 起算）。32号路两个入口 `(x4,y2/3)` ↔ 门房东侧 `(x9,y4/5)`，门房西侧 `(x0,y4/5)` ↔ 遗迹外围 `(x13,y20/21)`。注意门房地毯出门要按 **左右方向** 校验，不能复制自然公园南北门房的方向判断。旧的 Route32 提示牌“Entrance closed for now”此次保持，后续真正开放时同步更新。

遗迹外围其他 **8 个内部门口**（四间拼图房、遗迹内室、研究中心、联合洞穴 B1F 两个出口）暂时不登记传送。北门 `(x7,y5)`、北侧36号路门房与36号道路均留在下一批，严禁触发没有反向返回路的传送。36号路的胡说树、自然公园与37/35号路连接同样未开放，不能当普通 CUT_TREE 直接移除。

## 静态检查与后续门禁

```sh
python tools/johto_ruins_stage_audit.py --gold-root /path/to/pokegold-master
python -m unittest tools.tests.test_ruins_stage_254
```

以上只证明资源来源、Gold Warp 目标和“不会误激活”，**不证明可玩/ROM 编译成功**。下批将激活 32号路门房及遗迹外围作为完整的双向闭环，需先完成原版碰撞和出入口合同、游戏运行层登记、新 MAP、Red/Blue 与 TEST Red/Blue 本机构建，以及设备往返/Continue 实测。当前正式游戏版本 `MAP-5.62.253` 与 `TEST-231` 均保持不变；无 Git Commit/Push。
