# DEV-329｜Route29/Route46 门房入口阈值修复

**阶段**：开发测试候选；游戏版本 `REF-5.62.325`；活动地图47张，不新增地图。

## 用户反馈与定位

1. Route46 外部两格门毯 `(7,33)`、`(8,33)` 可以从上方向下进入，但左右互换时有空气墙。Gold 碰撞索引确认两格都是 `WARP_CARPET_DOWN`；DEV-328 只登记 DOWN 入毯阈值，缺少两格间的横向 BeforeStep/AfterStep。
2. 从 Route29 南侧门口进入 ID74 时，朝上走到门口被空气墙挡住。Gold Route29 的 `(27,1)` 是 `DOOR`，必须从 `(27,2)` 朝 UP 触发 STEP_ON；DEV-328 的纵向地图 allowlist 已含 Route29，但 BeforeStep/AfterStep 配置缺少这条门口阈值。

## 源码修改

- `data/johto_vertical_gate_runtime_314.asm`：
  - Route46 `(7,33)` RIGHT → `(8,33)`、`(8,33)` LEFT → `(7,33)` 的 BeforeStep 放行；对应 AfterStep 返回 `E=3`。
  - `E=3` 是双格门毯横向换道，不是出口 Warp；`JohtoVerticalGateCollisionExit314` 仍只接受 `E=1`。
  - Route29 `(27,2)` UP → `(27,1)` 增加 BeforeStep；目标 DOOR 的 AfterStep 返回 `E=2`，走原生 STEP_ON Warp。
  - 表长度 ASSERT 随新增记录更新；未修改地图、Warp 目标顺序、门房室内布局或边界。
- 游戏标签升为 `REF-5.62.325`，以区分这次实际运行阈值变化。

## 审计修正

- `johto_vertical_gate_runtime_314.py`：检查精确阈值、E=3 不可误作碰撞出口、Route29 DOOR STEP_ON、门房闭边界，以及5个实际 Overworld/NPC movement hook 是否连到共享运行时。
- `johto_warp_arrival_audit.py`：核对ID74七条Gold Warp、源/目标坐标、角色、方向和到达自动步进；总路由行数104、活动门房13。
- `johto_gatehouse_behavior_audit.py`：把ID74列入 legacy `Gate_Coll` 活动门房；13座门房、38格地毯。
- `johto_pilot_migration_audit.py`：提供Gold源码时强制调用完整门房行为/到达审计，不再让专项审计只在单独命令中运行。
- `johto_field_move_coverage_audit.py`：Route45/46的合法跳崖方向除与Gold精确匹配外，还要求 `JohtoSouthHopLandingGuard` 分别分派到对应表。

## 跳崖核对结果

Gold 静态枚举：

| 地图 | Gold HOP 格 | 合法方向/安全落点 | 结果 |
|---|---:|---:|---|
| Route45 | 83 | 88 | 与运行表完全一致，落地保护已登记 |
| Route46 | 19 | 20 | 与运行表完全一致，落地保护已登记 |

这覆盖全部 Gold 合法跳崖方向，不需要用户逐个手测108个方向；但它不是设备帧级验证。用户设备只建议抽查连续两层、侧向跳崖和普通下坡各一处。

## 验证边界

- Gold 主迁移审计、门房行为审计、Warp 到达审计、Field Moves 覆盖审计和相关故障注入均为源码/参考数据检查。
- 本环境未安装 RGBDS，未编译/链接 ROM，未生成新 MAP，未进行手机实测。用户需本地构建 Red/Blue/TEST，确认 ROM0 至少64B及 Bank `$53` 余量。

## 用户本机复测

1. 关闭穿墙金手指。
2. 在 Route46 从 `(7,32)` 或 `(8,32)` 向下踩入外部门毯；左右互换两格，确认不会传送。
3. 从 Route29 `(27,2)` 朝 UP 进入 ID74。
4. 在门房内朝 UP 从顶部 DOOR 出到 Route46；再返回门房，从底部门毯向 DOWN 出到 Route29。
5. 检查边界仍封闭，门房两侧 Warp 没有错位。
