# CLEAN REF-348 ROM0｜最终工作区清理及验收记录

## 基线与交付

- 最新输入：`REF-348(1).zip`，导出为实际 Worktree，带 `RPP_PROJECT_CONTEXT/patches/current_worktree.patch`。分支 `常规功能备份`；正式 HEAD `239ff32653c9087da8786532e36c189366ff209e`。并非清洁 HEAD。
- 使用此前 `REF-348.zip` 所附的相同 HEAD 干净源码校验：新 ZIP 的原工作区补丁可正向应用到该基线，结果与最新 ZIP 的代码和维护文件字节一致（不包括生成 MAP 及 RPP 自动导出上下文）。
- 版本 `REF-348 -> REF-348`，没有更新游戏版本、地图数或 Warp 合同；该 HEAD 既有 63 张活动地图与 160 条登记 Warp。本轮正式清理没有进一步修改 ASM、游戏资源及存档结构。
- REF-332 参考压缩包仅用于历史组织方式与来源核对，不参与本次源码补丁构造，不能覆盖最新 Worktree 事实。

## 本次累计未提交功能差异（功能提交）

- 跳崖：`_HandleMidJump` 使用独立32显示帧（Gold 16高度坐标×2帧）推进阴影；`CollisionCheckOnLand` 与 `JohtoSouthHopLandingGuard` 在两步脚本完成后禁止实际按键趁阴影未结束时绕过碰撞，覆盖 Kanto/Johto、普通/B键。落洞原有路由、音效和震动逻辑未在这次修复中重写。
- ROM0-RELIEF-349：骑车判断、室外地图判断、队伍菜单状态初始化、TM/HM 名称拼接、训练师音乐选择连同相关表迁往 ROMX `$2A`，保留 far-call 的标志位/寄存器合同。
- ROM0-RELIEF-350：`ResetPlayerSpriteData` 主体迁往 ROMX `$2A`，ROM0 留小入口并保留原 A=1，Bank `$01` 两个原始 near-call 不变。

## MAP 与实机证据

- 曾用的旧阶段 Red/Blue ROM0 余量为 67B；REF-349 后报告 393B；用户最新 Red/Blue MAP ROM0 **各421B**，当前 ZIP 自带 Red MAP 也为 **421B**；Bank `$2A` 余 15,020B，Bank `$01` 余 4B。以新 MAP 为准，累计自67B增加354B。421B 已经实测，不能再表述为预计。
- 用户反馈 REF-349 六项通过：骑车及门房规则、Fly/Teleport 室内外限制、队伍菜单与战斗切换、TM/HM 名称及教学、不同训练师音乐及战后恢复、旧存档重复操作。
- 用户反馈 REF-350 三项通过：旧档进出建筑与门房后精灵正常、新游戏出场坐标/精灵正常、菜单与战斗来回后精灵正常。之前跳崖黑影及反向回走两项按普通/B键复测未再复现，仍不声称所有随机时机永久无故障。
- 当前 ZIP 仅自带 Red MAP。Blue 421B 来自用户先前提供的独立 Red/Blue MAP；**本轮没有单独的 TEST 构建/空间证据**，也没有11个 PIT/5落点的穷尽手机回归证明。

## 工具/测试与遗留风险（工具审计提交）

- 纳入 `tools/johto_east_runtime_gate_300.py`、`tools/johto_gate_music_bike_audit.py` 的现役结构适配，旧骑车/门房测试更新，以及跳崖/落洞保护和 ROM0-349/350 的专项测试；`README.md`、`TODO.md`、`PROJECT_DELIVERY_RULES.md`、`RPP_DEVELOPMENT_PITFALLS.md`、两篇 ROM0 迁移记录与本文同步为已验收的时间线。
- 保留旧主综合审计中已经确认的历史版地图/Warp/跳崖断言未清、需要额外 Gold/NPC 环境的跳过项。不得把本次专项 PASS 宣称为全量测试、三版 ROM 构建或全部 Gold 功能的证明。
- 未修改 `GetItemPrice`、`LoadStartupMusicOption`、`GetTrainerInformation`；它们内部会切 ROM 或 SRAM Bank。Bank `$01` 余量极小，后续开发尤其应保护近调用代码体积。
- 本次实际执行 `python tools/validate_current_project.py --gold-root <完整Gold目录> --skip-pytest`：ASM局部标签 **1844文件通过**、63图对应三表 ASSERT 通过；综合迁移审计 **1691项中1657通过、34失败**，并非全绿。与输入Worktree对照后，34项失败名称及详情相同，本次仅文档清理没有引入新失败。主要涉及旧地图标牌策略、57图/134Warp、旧阶段封闭门禁/连接审计与跳崖兼容假设，后续专项升级，不在此次定版清理中擅自删除断言。
- `tools/johto_gate_music_bike_audit.py --project .`：563项静态检查通过；原版 Gold `johto_burned_tower_348_audit.py --gold` 通过11 PIT/5落点/30跳崖等，落洞帧节奏工具PASS+3项负向测试。所选 `pytest` 为**36通过、5跳过、0失败**；故意破坏骑车许可 ID 会让审计器失败，证明该门禁被现有检查拦截。
- 静态审计通过不等于手机无缺陷；仍需用户自行安排 TEST 和烧焦塔全路线补充验收。

## 模式 A 双提交边界（清理三件套）

1. `01`：当前这次用户提供的 Worktree → 清理后的完整状态。仅清理文档、历史状态和删除临时 `REF350_先读_验收说明.txt`，不改 ASM。
2. `02`：完整状态 → 只剩游戏运行代码的状态；第二笔工具/测试/维护文档暂时全部撤回。
3. 第一笔由用户提交功能；然后 `git apply -R 02` 恢复工具/测试/维护文档，用户自行提交第二笔。
4. `03`：与01互斥，直接从干净 HEAD `239ff326...` → 同一个完整清理状态。**不能和01叠加**。
5. 本轮 AI 不构建/链接 ROM，不运行用户仓库 Git Commit/Push。
