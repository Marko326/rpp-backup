# CLEAN REF-364 TOOL-CLEANUP-1｜Python 工具入口去重与历史测试归档

**基准**：用户本轮上传的 `REF-364.zip` 完整源码快照。ZIP 不含 `.git`；本记录只说明从该源码快照产生的工具清理增量，不声称读取了 Termux 实时 HEAD 或手机工作区。

## 1. 本批范围

只改离线 Python 工具、测试和维护文档；不改游戏 ASM、地图/图块资源、ROM 构建配置、存档结构或游戏显示版本。正式游戏版本继续为 `REF-364@`。

### 1.1 合并重复预检查器入口

- 原根目录 `johto_table_assert_preflight.py` 与 `tools/johto_table_assert_preflight.py` 都是 175 行，SHA-256 完全相同：`da1c982fd3790574789fd26eb6455643cf2f7849aa68aea6d698dabe33ab466b`。
- 删除根目录副本，只保留 `tools/johto_table_assert_preflight.py`。
- 当前唯一命令为 `python tools/johto_table_assert_preflight.py --root .`；`tools/johto_pilot_migration_audit.py` 的脚本执行和包导入两种 fallback 均保留。
- 更新 `test_johto_table_assert_preflight_261.py`：改为检查导入模块来自 `tools/`，并确认根目录副本不存在。

### 1.2 删除过时的 Gatehouse 304 转发入口

- `tools/johto_gatehouse_npc_pilot_304.py` 只有 6 行，只把 `audit`、`fault_tests`、`main` 转发到 `johto_gatehouse_npc_pilot_305.py`。
- 删除该 shim；`tools/johto_gatehouse_npc_pilot_305.py` 和 REF-305 专项测试保持原样。
- 在 REF-305 测试中加入结构断言，防止重新引入第二个 304 转发入口。
- REF-304 文档作为历史记录保留，不把历史阶段的命名改写成当前实现。

### 1.3 归档永久跳过的 DEV-312 测试

- `tools/tests/test_johto_gatehouse_onboarding_312.py` 的测试类带无条件 `@unittest.skip(...)`，整类始终不会执行。
- 原文件按字节保留并移至 `tools/archive/historical_tests/test_johto_gatehouse_onboarding_312.py.disabled`；`.disabled` 后缀使它退出 pytest / `tools/tests` 活跃发现范围，同时保留日后人工恢复的完整源文。
- **不删除** `tools/johto_gatehouse_onboarding_312.py`：它仍由 `tools/johto_pilot_migration_audit.py` 调用，仍是当前迁移审计的一部分。

### 1.4 暂不删除的审计工具

`tools/johto_union_b1f_339_audit.py`（126 行）和 `tools/johto_union_cave_collision_340_audit.py`（176 行）原样保留。它们需要先与现行 Union Cave / collision 审计覆盖范围逐项比较，不能仅因没有静态调用就直接删除。

## 2. 数量变化

| 项目 | 清理前 | 清理后 | 说明 |
|---|---:|---:|---|
| 项目内活跃 `.py` 文件 | 237 | 234 | 删除两个冗余入口，归档一个 `.py` 测试 |
| `tools/` 直接 Python 工具 | 101 | 100 | 删除 304 shim |
| `tools/tests/` 活跃测试文件 | 131 | 130 | DEV-312 测试移出活跃目录 |
| 根目录重复预检查器 | 1 | 0 | 唯一实现保留在 `tools/` |
| `tools/pokemontools/` 依赖文件 | 4 | 4 | 不变 |

归档测试内容仍保存在 ZIP 内，但扩展名为 `.py.disabled`，不计入活跃 `.py` 文件数。B1F-339 与 Collision-340 审计工具仍计入活跃工具数量。

## 3. 验证结果

- 定向 pytest：`15 passed, 5 skipped, 10 subtests passed`，覆盖表长预检查、REF-305 NPC 审计和 Gatehouse 311 轨迹测试。
- `python tools/validate_current_project.py --skip-pytest`：通过。
  - ASM local-symbol preflight：`1851` 个 ASM 文件通过。
  - 活动表长预检查：`NUM_JOHTO_ACTIVE_MAPS=64`；Town Map `256/256`、Browse Index `64/64`、GSC Music `64/64`。
  - 当前迁移审计：`PASS_STATIC_ONLY`，`1538/1538` 检查通过。
- 未运行完整 pytest 全套；本记录不把定向测试结果表述为全仓库全绿。
- 未执行 RGBDS 汇编/链接，未生成新的 Red/Blue/TEST MAP，未进行 ROM 或设备实测；静态通过不代表构建空间或游戏内行为已验收。
- 未在用户手机/Termux 工作区执行 `git apply`、Git Commit 或 Push。

## 4. 交付和应用边界

本批是**基于本轮上传 `REF-364.zip` 的独立工具清理增量**。原 ZIP 不含 `.git`，本轮没有新的真实 HEAD 哈希或用户当前未提交补丁，因此不伪造 HEAD 累计补丁，也不把本批增量冒充 CLEAN REF-364 原始模式 A 三件套。应用前请在实际仓库执行 `git apply --check`；如本地已有同路径改动，应先备份并核对冲突。

游戏版本不升版：继续保持 `REF-364@`。


## 5. TOOL-CLEANUP-2：Union Cave 历史审计收口

- `tools/johto_union_b1f_339_audit.py` 已按字节归档至 `tools/archive/historical_audits/johto_union_b1f_339_audit.py.disabled`。该 339 阶段脚本含 REF-339 / 58 张活动地图等旧基线断言，不适合继续作为 REF-364 现役审计入口。
- `tools/johto_union_cave_collision_340_audit.py` 继续保留：它涉及移动碰撞和负向检查，不能仅凭阶段编号判断已失效。
- 活跃 Python 文件数由第一批后的 234 降至 233；本批不新增 `.py`，不修改 ASM、游戏版本 `REF-364@`、地图、ROM 构建。
- 未清理 340/341 的旧断言；它们应在后续专项审计中修正，而不是通过删测试制造全绿。
