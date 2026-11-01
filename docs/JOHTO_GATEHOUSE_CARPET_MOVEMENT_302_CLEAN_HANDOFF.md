# CLEAN-5.62.302｜门房地毯入毯修复清理交接

## 1. Git 基线与最终状态

- 项目：RPP Mobile；项目导出记录分支 `常规功能备份`。
- 最近正式 Git HEAD：`ba5544bcf730e1f17ce2ae62a6c7c6d9b01bc9c7`。
- HEAD 对应版本：`MAP-5.62.299`；测试版本 `TEST-231`。
- 当前开发工作区累计包含 MAP-300、FIX-301、FIX-302，最终版本 `FIX-5.62.302`、测试版本 `TEST-233`。
- 用户已确认 FIX-302 工作区补丁可以进入清理；没有本轮 Red／Blue／TEST 新 MAP 或手机实测反馈。
- 本轮有游戏运行差异及独立工具／审计／测试差异，必须按模式 A 双提交；用户自行 Commit／Push。

## 2. 第一笔：游戏功能 `feat(johto)`

- 活动地图从 35 张扩展到 38 张，新增稳定 ID 62–64：`Route42EcruteakGate`、`Route42`、`MahoganyTown`。
- 建立圆朱市东侧门房与 Route42 的双向门房 Warp，以及 Ecruteak City ↔ Route42 ↔ Mahogany Town 的双向地图连接；保留 Route42 的 Gold CUT 点、Mahogany 的 12 个安全 HOP 点、Town Map／地点名／Fly／音乐／屋顶配置。
- Route43、Route44、Mt. Mortar 洞口与 Mahogany 室内入口保持关闭；Route43 只用作 Mahogany 北侧显示预览来源，不激活该地图，不开放碰撞或 Warp。
- FIX-301 在 ID62 东门房为成熟掩码中的上下门毯换道增加精确例外。
- FIX-302 将例外修正为目标格驱动，并同时补齐 ID23 西门房：从 Y3 向 DOWN 进入上门毯、从 Y6 向 UP 进入下门毯、从室内侧方进入登记门毯，以及上下门毯之间换道。只有目标为注册门毯、来源相邻且方向匹配时放行；其余目标继续成熟碰撞判定。
- 门房外向 Warp 仍由原来的方向与成对门毯碰撞守卫触发。步行与自行车共用相同移动判定。
- Gold 原始 `.blk`、成熟 role／blocked mask、门毯 Warp 注册、存档结构、Kanto 碰撞及其它八座门房的碰撞策略不因 FIX-302 改写。

## 3. 第二笔：工具／审计 `test(tool)`

- `tools/johto_gatehouse_behavior_audit.py`：覆盖全部 10 座活动门房、32 个登记地毯格，逐一核验 Gate_Coll 实际探测图块、Gold role grid、West helper、Park East mature helper、East helper 等策略；对 ID23／62 的真实 ASM 分支作有限指令模拟，各枚举 172 条地图内相邻移动。
- `tools/johto_east_runtime_gate_300.py`：加入 ID62 实际入毯移动扫描，锁定上／下普通地面进入和方向，保留 Route42／Mahogany 的闭合边界、Warp、预览来源与宽度合同。
- `tools/tests/test_johto_gatehouse_carpet_302.py`：新增上／下／侧向入毯及两座门房移动模拟；删掉任一合法分支或改错方向必须被负向注入捕获。
- `tools/tests/test_johto_east_runtime_gate_300.py`：更新原先错误的 Y3／Y6 “必须阻挡”假设。
- 同步维护 10 座门房合同、MAP-300 门禁、门房音乐／骑车、Field Moves、Surf、Gold 综合迁移及历史阶段测试。
- 旧检查器的根本缺口：只核对 Warp 注册、目标地图、方向守卫和地毯格身份；FIX-301 又只测当前位置已经在地毯时的上下换道，并把普通地面进入当作负例。因此它没有执行“普通地面一步进入门毯”的实际碰撞路径，产生假阳性。FIX-302 将检查改为按下一格目标与来源方向解释 ASM。

## 4. 本轮实际执行结果

以下均为源码／静态审计，不代表 ROM 或手机验收：

| 检查 | 结果 |
|---|---|
| `johto_gatehouse_behavior_audit.py` | 14/14 `PASS_REFERENCE_ONLY`；10 门房／32 地毯；ID23、ID62 各 172 步模拟 |
| `johto_east_runtime_gate_300.py` | 83 项 `PASS_STATIC_ONLY`；14 项负向故障注入全部通过 |
| `johto_gate_music_bike_audit.py` | 386 项通过 |
| `johto_pilot_migration_audit.py` | 1013/1013 `PASS_STATIC_ONLY` |
| `johto_surf_build_gate_296.py` | 38 活动图／18 含水图通过；2 项负向注入通过 |
| `johto_field_move_coverage_audit.py` | 38 图／4360 WATER／10 CUT／176 HOP |
| `asm_symbol_preflight.py` | 2092 ASM 文件通过 |
| `johto_table_assert_preflight.py` | 3 张活动表 ASSERT 通过；self-test 通过 |
| `python -m pytest -q tools/tests -rs` | 480 passed、21 skipped、90 subtests passed、0 failed |

pytest 的 21 项跳过：1 项缺少生成 RGBDS MAP；1 项缺少独立 MAP-300 stage-77 身份参考；3 项为已由后续运行审计接管的 MAP-293 staged corridor 旧测试；15 项为已被当前累计运行门禁接管的旧 Route35 source-contract 测试；1 项缺少独立 MAP-299 mature NPC 参考。不得将跳过项记作通过。

本轮另外直接运行 MAP-300 专项审计时，使用 Gold 原版树与现有 NPC-5.62.243 参考目录完成 83 项源码检查；这不替代缺失的独立 stage-77 身份参考测试。

## 5. 未验证事项与风险

- 未运行 RGBDS 编译／链接；未生成 FIX-302 Red、Blue、TEST MAP。
- 用户提供的旧 MAP-300 ROM0 slack 64B、Bank `$53` slack 12,878B 不包含 FIX-301／FIX-302 最终 helper，不能作为最终容量证明。须以新编译 MAP 检查 ROM0 至少 64B 余量及 Bank `$53` 实际容量。
- 未做手机实测；用户确认“工作区补丁可以”只代表同意进入清理，不等于设备验收。
- 独立 MAP-300 stage-77 来源缺失，依赖它的身份测试仍跳过。不可用当前候选资源自证来源身份。
- 静态审计覆盖 10 座门房，但本轮运行代码只改 ID23／62；其余八座需最小烟测确认没有间接影响。

## 6. 用户本机最小验收

1. Red、Blue、TEST 分别重新编译并生成最新 MAP；确认 ROM0 ≥64B，检查 Bank `$53` 余量。
2. ID23 西门房和 ID62 东门房分别测试：Y3 DOWN 进入上门毯、Y6 UP 进入下门毯、室内侧方进入、上／下门毯换道、再反向返回普通地面。
3. 在门毯上只朝登记的外向方向触发 Warp；错误方向不得传送，普通墙格不得通过。
4. 步行与自行车各测一次；其余 ID6、11、13、18、19、102、104、105 做最小双向进出烟测。
5. 保留 Route43／44、Mt. Mortar 洞口与 Mahogany 室内入口关闭状态。

## 7. 清理三件套使用顺序

1. 已经应用 FIX-302 的当前工作区：只应用清理增量补丁。
2. 从 `ba5544bc...` 干净 HEAD 重建：只应用基线累计全量补丁。以上两份互斥，不能叠加。
3. 完整最终状态应用工具／审计反向隔离补丁，暂时撤回第二笔工具、测试及维护文档，只保留游戏功能；按功能日志提交第一笔。
4. 对同一隔离补丁执行 `git apply -R`，恢复工具／测试及维护文档；Git 的反向应用不会恢复本次新增脚本的可执行位，因此再执行 `chmod +x tools/johto_east_runtime_gate_300.py`（该文件应为 100755），核对文件模式后按工具日志提交第二笔。
5. 两笔 Commit／Push 由用户自行决定并执行；AI 不代提交。
