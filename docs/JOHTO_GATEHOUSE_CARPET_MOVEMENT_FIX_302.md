# FIX-5.62.302｜圆朱东／西门房地毯入毯通行修复

## 用户报告与根因

FIX-301 已允许站在地毯上下两格之间换道，但**从上方／下方普通地面反向踏入地毯**仍然碰墙。原因是 ID62 新 helper 只检查**玩家当前位置**在地毯而非**下一格目标是否是地毯**，并且原 .301 审计错误地把来自 Y3/Y6 的入毯动作定义为“不应放宽”，因此假阳性通过。对照项目 ID23 圆朱西门房，发现其 WestCarpetSpatialStep 也只放行站在 y4/y5 的纵向换道，缺少 y3 DOWN / y6 UP 的两条入毯判定。两个门房均采用成熟角色掩码：边缘地毯在掩码中均为 1（阻挡），但经过注册的方向 Warp 与室内普通脚步并不应该把它们变成单向不可踏入地面。

## 净修改

- `data/johto_east_runtime_300.asm`：保留 `JohtoEastGateCarpetLaneStep300` ABI，改为严格检查**下一步目标**的十二种方向性入毯动作：X0/9，Y4/5；来自上方 Y3、下方 Y6、室内侧方 X1/X8、以及地毯另一格。只在地图 ID62 使用，返回 Carry=1/E=0；所有非入毯动作继续成熟角色表。外向碰撞 Warp 仍走 `JohtoEastPortalCollisionExit`，未改入城/出路 Warp 表。
- `engine/johto_south_geometry.asm`：ID23 门房沿用旧 .gateLane 逻辑，额外允许 y3 DOWN 和 y6 UP 且 X0/9 的入毯动作；其他城镇／道路分支保持原状。
- 不变：全部原 Gold `.blk`、成熟 role/block mask、Warp 登记、音乐、门房骑车许可、Surf、Cut、跳崖、存档结构、ROM0 和 Kanto 碰撞。
- 最终版本 `FIX-5.62.302` / `TEST-233`。本轮累计差异从 `MAP-5.62.299` / `TEST-231` 收口，游戏功能与工具审计按模式 A 分两笔提交。

## 强制防回归

- `tools/johto_gatehouse_behavior_audit.py`：在现有十座活动门房/32 地毯全面登记审计之外，对西门房 `JohtoWestCarpetSpatialStep` 与东门房 `JohtoEastGateCarpetLaneStep300` 逐指令解释并与真实 10×8 成熟角色数组比较，每座枚举 172 条有效地图内相邻方向，涵盖地面→地毯、地毯→地毯、地毯→普通地面、墙禁止通行。
- `tools/johto_east_runtime_gate_300.py`：原“y3/y6 入毯必须失败”反向断言已替换为允许入毯的检查；故障注入分别破坏上下进毯分支均应失败。
- `tools/tests/test_johto_gatehouse_carpet_302.py`：独立运行 ASM 方向扫描与负向故障注入，令上／下／侧方任一合法入口缺失都会失败。
- 其余八座活动门房继续原 Gold/legacy/South/Park 策略，并在综合门房检查中验证角色网格、方向 Warp、登记契约；静态比对和模拟不等于已经在手机上逐座复测。

## 本机最小验收

1. 东西门房分别站在 X0/X9、Y3 按 DOWN 进入上地毯；站在 Y6 按 UP 进入下地毯。
2. 两格地毯之间向上下换道；从室内 X1 左移及 X8 右移进入对应地毯；再反向走回普通地面。
3. 在左右最外地毯仅朝注册的外侧方向触发 Warp；其余方向不应触发 Warp。步行、骑车分别测；普通墙仍不得通过。
4. Red/Blue/TEST 重新在本机编译后核对**最新** ROM0/BANK 空间与手机表现；此前提供的 MAP-300 不能视作 FIX-302 产物。

## 清理前最终静态复核

- 全门房行为审计：`14/14 PASS_REFERENCE_ONLY`；覆盖 10 座活动门房、32 个登记地毯格；ID23 与 ID62 分别模拟 172 条地图内相邻移动。
- MAP-300 专项审计：`83/83 PASS_STATIC_ONLY`；14 项负向故障注入全部拒绝错误，包括上下入毯方向、门毯例外调用、Warp 配对、Y=8 封闭与 Route43 预览来源／宽度。
- 门房音乐／骑车审计：`386/386 PASS_STATIC_ONLY`。
- Gold 综合迁移审计：`1013/1013 PASS_STATIC_ONLY`。
- Surf 开发门禁：38 张活动图／18 张含水图通过；2 项负向故障注入通过。
- Field Moves：38 张活动图、4360 WATER、10 CUT、176 HOP。
- ASM 局部符号预检：2092 个 ASM 文件通过；活动表 ASSERT 检查 3 张表通过，自测通过。
- 完整 Python 回归：`480 passed, 21 skipped, 90 subtests passed, 0 failed`。跳过项包含缺少独立 MAP-300 stage-77 身份参考、缺少生成 MAP、已退役历史阶段合同及缺少独立 MAP-299 mature NPC 参考；详见正式交接。

## 最终验收边界

本轮没有运行 RGBDS 编译／链接，没有生成 FIX-302 Red／Blue／TEST MAP，也没有手机实测或 Git Commit／Push。旧 MAP-300 的 ROM0／Bank `$53` 余量不是 FIX-302 容量证据。用户需按正式交接在本机重建三种 ROM、检查最新 MAP，并复测 ID23／62 的普通地面入毯、侧向入毯、上下换道、反向返回、正确外向 Warp、错误方向不传送、墙格阻挡及步行／自行车；其余八座门房做最小进出烟测。

最终三件套及两份中文日志按项目模式 A 交付；本环境不执行 Git Commit／Push。
