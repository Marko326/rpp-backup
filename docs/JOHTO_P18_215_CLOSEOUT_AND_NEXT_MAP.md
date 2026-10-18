# ILEX-5.62.215｜P18 北门房／Route34 收口与下一地图交接

**当前阶段：游戏 `.215` 候选已获用户所测进出门房和道路通行的认可；本文件只写已获得的证据。** 当前最新确认 Git HEAD `287522e5` 是 `.212`，`.215` 功能及后续门房审计工具仍待按两笔提交。

## 最终有效规则

- Gold `Route34IlexForestGate` 复用项目已有门房转换/运行时：北侧双格 ↔ Route34 南侧双格；南侧双格 ↔ 桐树林北口单格；共享 `$FC` 按地区+局部 ID 判断，正常方向触发，错误方向不能传送。
- `.215` 由既有 `GetJohtoWarpArrivalStep` 控制**下向到达才补一格**；上向到达保持原落点。`.213` 要多按一下、`.214` 两侧都补一步均属失败候选，不能恢复。`PlayerStepOutFromDoor`、旧南门房与关东现成 Warp 程序不重写。
- Route34 用 `JOHTO_MODERN`，北门房扩 `JOHTO_GATE`，不改旧门房已有图块槽或关东 palette。森林 Cut 保留 `.212` 实装，`ILEX-LEDGE-001` 跳崖保持禁用。

## 证据和未完成项

- 用户已经反馈 `.215` 进出门房和道路走动正常、无明显异常；不代表所有旧门房、存档、菜单、脚本或全部墙格逐项通过。
- 功能候选 508 项，后续门房普查增强版本 513 项单元测试通过；辅助 Gold 全量审核还有旧 `SafariZoneBeta` 图形窗口问题。AI 未编译或链接本次 ROM，不声称 MAP Bank 空间验收。
- 后续启用其它门房时先读 `docs/JOHTO_GATEHOUSE_READ_FIRST.md`、本文件和 `docs/JOHTO_ALL_FUTURE_GATE_INVENTORY_215.md`，运行 `johto_indoor_pipeline.py`、门房准入审计；Gold 原版 Warp 与实际到达步行必须分开登记。

## 下一阶段

只继续地图扩展：从 Route34 北侧尚未开放的满金市接口开始核实下一张地图、碰撞、连接与资源，再沿原版连接推进。不要把大葱鸭、HM01 发放、道馆徽章和冻结跳崖当作本轮提交的阻塞项。

## 提交说明

按用户老规则：先提交功能 `feat(johto)`，再提交工具/审计/三件套 `test(tool)`。提交日志分别放在交付 ZIP 内；Git Commit/Push 在用户工作区执行，提交前须核对真实 `git status` 和当前 Git HEAD。
