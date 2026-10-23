# SPID-5.62.240｜29号道路—46号道路门房正式收口（2026-10-23）

> 当前结论：`.240A` 的实机反馈修复已经由用户上传 `240A测试视频.mp4` 并表示“没看出什么问题”，本轮正式收口恢复游戏可见版本 `SPID-5.62.240`；不修改已修复的门房运行时机制。本页下方原 `.240` 开发阶段的 PHONE_PENDING 叙述是**历史记录**，不代表当前状态。

## 本轮明确的手机验收范围

- `Route29` 单格实体门 `(27,1)`：从 `(27,2)` 朝上一次踏门进入、门房返回、重复进出。用户视频所呈现的这些路径未再出现卡门。
- `Route46` 两个门毯 `(7/8,33)`：用户视频中可见门房另一侧切图及重复进出，未报告异常。不可把视频当作所有按键时序、所有存档与碰撞逐格实测。
- `Route29` 上缘原有大面积粉红错误图块：视频可见的稳定画面中未再复现；此前旧别名 `$F4` 对 Bank `$47` 邻图读取的修复保留。
- `tools/johto_door_contracts.json` 本座门房 `phone_door_status`、`phone_visual_status` 按**上述用户反馈可见范围**标为 `PHONE_ACCEPTED`；独立的精确调色、全部时段/存档和 `runtime_palette_status` 仍保留 `PHONE_PENDING`。

## .240→.240A 实际运行时缺陷（不能因为静态全绿忽略）

1. Route29 使用旧地图别名 `$F4`，仅登记 Warp 和 Gold `STEP_ON` 不会自动让玩家穿过旧引擎碰撞层。现有精确放行按 `(27,2)`, `UP` → Gold DOOR `(27,1)`，其它屋顶树林格继续封闭。
2. Route29 北邻 Route46 的区块位于 Bank `$47`，旧预览读取逻辑错误沿用当前 Bank `$40`。现有 `ResolveNativeConnectionPreviewBank` 对 `$F4` Route29 NORTH 序号 0 返回 `BANK(JohtoRoute46Blocks)`；不改动两条道路 `.blk`。
3. 旧门房审计只核对登记/碰撞规则与连接值，没有覆盖真实 `CollisionCheckOnLand` 和跨 Bank 邻图预览分支；新增 4 项专项包含坐标/方向/Bank 负向注入，已经纳入统一发布门禁。今后必须同时验证 Gold 角色、旧/新地图身份、行走碰撞、Warp 执行和两种图块加载路径。

本次正式 `.240` 在实际用户 `.240.patch` + `.240A` 补丁复放后的源码上完整执行 `tools/johto_map_release_audit.py --expect-version SPID-5.62.240`：退出码 0、status=PASS、944/944 Python 测试通过、0 skipped，56/56 有向活动连接 PASS；Gold 368 张登记、367 张扫描、367 张来源 PASS、0 失败，`SafariZoneBeta` 按原白名单排除。masked-step 为源码级 21 图/162 移动边、139 条要求放行、0 failures；ROM 编译/链接和真实手机全部状态均不由此证明。

## 证据层级与下一阶段

清理只改变候选版本展示、用户验收记录、工具中的版本期望以及提交整理；不修改任何门房机器指令、图块、地图连接或 Warp。用户已反馈范围以外的旧存档、深灰室内区域的精确 Gold RGB、所有旧门房和最新 ROM/MAP 配对未独立核实，保持待测。用户自行编译和 Git 提交。

规范化旧道路/城镇将在 `.240` 正式收口后**另立小批次**：先建旧 `$F4/$FB` 与原生 `$FC` 执行路径清单、ROM Bank/预览来源矩阵和真实碰撞/门房合同，再逐条迁移且每批单独手机验收，禁止为“统一”全局放开阻挡或改写已验收 Gold `.blk`。

---

## 以下保留 `.240` 首次开发候选的历史记录

# SPID-5.62.240｜29号道路—46号道路门房：待手机验收

## 本批边界

只接通 Gold `Route29Route46Gate`：保留现有 Route29/Route46 `.blk`、相邻道路预览、已验收 JOHTO_GATE 图块/调色，不启用 Dark Cave、门房 NPC 或其它 Gold 地图。固定地图 ID **74 / $4A**，active slot 45，仍在 Bank $47；Route29 保留旧 `$F4` 地图别名，Route46 与门房使用 native `$FC` + Johto region + local ID。

## Gold 原始 0-based Warp 合同

| 原图 | 入口 | Gold 碰撞 | 本项目门房目标 | 执行方式 | 目标格到达步进 |
| --- | --- | --- | --- | --- | --- |
| Route29 | (27,1) | DOOR | Gate 南侧 Warp #2 | STEP_ON, UP | gate (4,7): NONE |
| Route46 | (7/8,33) | WARP_CARPET_DOWN | Gate 北侧 Warp #0/#1 | COLLISION_ONLY, DOWN | gate (4/5,0): D_DOWN |
| Gate 北侧 | (4/5,0) | DOOR | Route46 Warp #0/#1 | STEP_ON, UP | Route46 毯 (7/8,33): NONE |
| Gate 南侧 | (4/5,7) | WARP_CARPET_DOWN | Route29 **同一** Warp #0 | COLLISION_ONLY, DOWN | Route29 门 (27,1): D_DOWN |

注意：外侧 Route46 `(7/8,33)` Gold mask 原样定义为边界阻挡；运行时只为从 y32 下行踏上毯和 y33 两毯横移放行，继续从 y33 向下才应碰撞并触发 Warp。室外上下接缝在 Gold 中是墙，**不开放通过普通地图连接直接穿墙进入另一道路**。

## 静态验证／负向回归

- `tools/tests/test_johto_route29_route46_gate_240.py`：真实 Gold 碰撞、双格 Warp 与单格汇入、HOME 地图区分、到达步进、运行 ASM 分支、Route46 carpet 真实掩码路径、原版素材、旧门房回归；故障注入覆盖错路线、错地毯、反方向、错步进、门毯不允许踏入。
- `tools/johto_gatehouse_behavior_audit.py` 和 `tools/johto_warp_arrival_audit.py`：由 Gold 碰撞角色独立校核，无匹配默认 NONE；Route29 外侧遗留别名的步进目的地用 Gold 原图碰撞验证。
- 恢复用户提供的基线 ZIP **缺失的** `tools/johto_east_corridor_source_contract.json`（从同包冻结图和所附 Gold 源重新生成）：这是使项目自身既有 `.239` 东线 Gold 来源/防漂移审计可独立运行所必须的资料，不启用额外地图。
- 静态 PASS ≠ ROM 编译 ≠ 手机验收。本批未编译、未 Git 提交，`phone_door_status`、`phone_visual_status` 和 `runtime_palette_status` 均保持 `PHONE_PENDING`。

## 手机验收最小清单（待用户）

逐条测试：Route29 单格进→立即回→立即重进；Route46 左/右两格分别向下踏毯、横移、再向下进入→北门原地立即返回；两个方向都不得双跳/卡门；进出前后外墙与树林边框一致；室内顶栏/地板/墙柱、颜色与已验收城都门房一致；无多余地点牌；抽测旧门房及关东门房。确认实际 ROM MAP 内存与手机录像前不可升级到 `PHONE_ACCEPTED`。
