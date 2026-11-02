# REF-5.62.319｜Route43—Lake of Rage 正式收口交接

## 最终保留行为

- 活动地图：42；LakeOfRage stable ID68，20×18 Gold 原图。
- Route43 北侧与 Lake 南侧为真实双向接缝，只开放 Gold 实际可走的五条 lane：`x=0,8,9,10,11`；其余预览边缘 fail-closed。
- Lake role grid 为 40×36；300 WATER、5 Cut、6 HOP。ID68 普通陆地移动必须进入精确 role-grid 分派，不能退回通用 tile passability。
- `(4,28)` 与 `(6,28)` 是两层连续 `HOP_DOWN` 的上层起点；第一次跳后落在 `(4,30)` / `(6,30)`，第二次输入再跳到 y=32。其它四个登记跳崖按 Gold 落普通 FLOOR。
- ID66 北侧两格 `WARP_CARPET_DOWN` 允许从上方回踩和地毯间横移；横移状态 E=3 不能触发出口，真正 DOWN 碰撞出口仍只接受 E=1。
- Lake 两栋房屋、红色暴鲤龙、渡、训练师/道具、Rocket 相关剧情未接入，禁止用占位对白/事件提前开放。

## 用户设备反馈

- REF-317：用户确认 ID66 北侧门毯修复“可以了，没问题”。
- REF-319：用户检查愤怒之湖/跳崖后反馈“没什么问题”，并要求跑本次相关工作区脚本后正式清理。

## 正式清理前的本轮相关验证

- `johto_lake_of_rage_321_audit.py`：32/32。
- Route43 return：28/28；ID66 gate：46/46；historic visual seam：37/37。
- Field Moves：42 maps / 4732 WATER / 16 Cut / 190 HOP；Lake = 300 WATER / 5 Cut / 6 HOP。
- Surf coverage：42 active maps / 20 water maps，Lake 300/300 REGISTERED。
- Map name：132 项；gate music/bike：508 项；活动表 ASSERT：3 项。
- 本轮相关 ASM 局部符号：10 文件通过。
- 相关 pytest：137 passed + 5 subtests passed，0 failed。
- 按用户要求没有重跑与本次工作区无关的全部历史地图测试。

以上都是源码/静态门禁；项目规则禁止 AI 自行编译/链接 ROM。用户已经完成本轮关键实机观察，但最新 REF-319 MAP 容量文件未提供，所以 ROM0/ROMX 最终余量仍待下一次用户导出核对。

## Git 与提交边界

- 分支：`常规功能备份`。
- 最近可核实正式 HEAD：`c4890820e06b5bb361ab663f40680117c59c2e70`。
- REF-307～319 均属于该 HEAD 之后的累计未提交 Worktree；不得把版本号当新 HEAD。
- 累计差异含游戏功能与工具/测试，正式清理采用模式 A：先功能提交，再工具/审计提交。

## 下一阶段

优先处理 Lake of Rage 房屋和剧情事件。所有剧情来源继续只用用户提供的 Gold/参考分支；缺失文件直接向用户索取。
