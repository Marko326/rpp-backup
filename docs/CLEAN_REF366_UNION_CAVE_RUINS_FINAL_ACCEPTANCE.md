# CLEAN REF-366｜联合洞穴 B1F → 阿露福遗迹双侧洞口正式清理记录

> **状态**：正式源码清理与提交材料已准备，**不是 Git Commit/Push 已执行，也不是 ROM / MAP / 全设备验收**。基线来自用户上传 `REF-365.zip` 的干净 HEAD，分支 `常规功能备份`，`62a851e72ca00db23d4e7ac95aec83ee4d046804`。本轮开发候选从此前交付的 REF-366A 开发补丁在该 HEAD 上重建；没有用户最新手机 Worktree 导出，补丁前置状态必须由用户 `git apply --check` 核实。

## 一、功能收口范围

- 正式版本 `REF-365@ → REF-366@`。地图活动数 **65** 不变；Johto 注册方向 Warp **168 → 172**。不新增地图和游戏资源，不改动本批 REF-366A 已验收的运行 ASM；正式收口仅把 `REF-366A@` 标签去字母并整理文档。
- 联合洞穴 B1F ID114 Gold #1 `(3,3)` ↔ 阿露福遗迹外部 ID20 Gold #7 `(6,19)`；B1F Gold #2 `(3,11)` ↔ 遗迹外部 Gold #8 `(6,27)`。RPP B1F 源 ordinal `0/1` 与遗迹外部源 ordinal `3/4` 保留 0 基编号，不合并、不交换两个不同外围区域入口。
- 遗迹外部 CAVE 格要**从下侧朝上踩入**，进入 B1F 地毯停留；从 B1F 地毯**朝下碰撞**出洞，落到遗迹 CAVE 格后自动再朝下迈到 `(6,20)` / `(6,28)`，避免卡洞口；不能把这条额外迈步加到 B1F 到达地毯上。
- 不改旧 1F/B1F/B2F 楼梯、Surf、Bike、黑暗洞穴等已验收功能；不新增 Rock Smash、NPC、野外遭遇、剧情、物品。

## 二、为什么之前的检查可能漏掉问题

- 早期 Warp 检查只看方向路由/源 Object ordinal，**没有从公共入洞碰撞入口跟踪到换图后 `JohtoPilotGateArrivalStep` 自动迈步**，因此曾出现 Warp 可达却站在 CAVE 洞口不动。
- 旧版历史审计冻结了 168 条 Warp、以前封闭的 B1F 侧口及不同版本的活动地图和门口样本，这些合同不能当作 REF-366 新需求的正向通过证明。
- 本轮通过扩展 `tools/johto_warp_field_entry_gate.py` 和相关测试校验遗迹外部 `(6,19)/(6,27)` 两侧 CAVE 入口、B1F DOWN 地毯、两个独立 ordinal、两处安全自动迈步及错误方向，使用故障注入确保不正确的入口 Y、方向、ordinal、落点动作会失败。

## 三、执行过的源码检查及结果（本轮隔离副本）

| 命令 | 结果与边界 |
|---|---|
| `python tools/asm_symbol_preflight.py` | **PASS：1,852 个 ASM 文件**，仅局部跳转符号检查，非 RGBDS |
| `python tools/johto_table_assert_preflight.py --root .` | **PASS**：65 地图相关表长 |
| `python tools/johto_warp_field_entry_gate.py --root .` | **PASS：82 项**，源码执行链和 Warp/Field Moves 静态门禁 |
| `python tools/johto_union_cave_warp_trigger_342_audit.py --project .` | **PASS：13 项**，触发方向与 Gold 洞口静态合同（本轮未提供 Gold 原目录参数） |
| `python -m pytest -q tools/tests/test_union_cave_ruins_portals_366.py tools/tests/test_johto_union_cave_warp_trigger_342.py tools/tests/test_johto_warp_field_entry_gate.py` | **27 passed**，包含源路由/落点与故障注入 |
| `python -m pytest -q tools/tests/test_union_cave_ruins_portals_366.py tools/tests/test_union_cave_260.py tools/tests/test_johto_union_cave_warp_trigger_342.py tools/tests/test_johto_warp_field_entry_gate.py` | **32 passed / 1 failed**；1 项旧 `test_current_migration_contract_passes` 把全仓库过期合同当成正向门槛 |
| `python tools/validate_current_project.py --skip-pytest` | **FAIL**：前 4 项通过，`current migration audit` 失败，未继续以全绿声明 |
| 直接调用 `johto_pilot_migration_audit.audit_project` | **FAIL：21 条迁移合同错误记录**，含历史版本、168 Warp 冻结和旧门口数据样本，不等于 21 处新运行故障 |
| `python -m pytest -q tools/tests` | **915 passed、73 failed、189 skipped、95 subtests passed**；许多为之前里程碑冻结断言及其派生失败，不能宣称全仓库 PASS |

项目禁止 AI 自行 RGBDS 编译与 ROM 链接；未使用用户手机模拟器。本轮没有新 REF-366 Red/Blue/TEST ROM，也没有对应的四版 MAP，更不能拿 REF-365 Red MAP 的 ROM0 余量代表 REF-366 的空间验收。

## 四、已经获得和仍缺少的设备证据

- 用户反馈**现在已经能够进入**本批联合洞穴侧口，且需要从联合洞穴 1F 的正确楼梯到达 B1F。此反馈支持先前“进不去”定位已解除，但**没有提供两处洞口全部四个方向、错误方向、自动迈步和存档的逐项通过记录**。
- 用户提交前须重新确认：北口 `(6,19)↔(3,3)` 和南口 `(6,27)↔(3,11)` 各独立双向；B1F DOWN 出洞后遗迹外自动向下迈、遗迹 UP 踩入后 B1F 地毯保持；不能即时回弹或串错目的地。南北外围不必互相步行连通。
- 旧 1F/B1F/B2F 楼梯、冲浪、Bike、Save→Continue；四种 ROM 构建及对应 MAP、ROM0≥64B 与紧张 Bank，均保留用户验收步骤。Rock Smash 继续延期。

## 五、按项目模式 A 交付和恢复顺序

- `01`：**REF-366A 开发候选工作区 → REF-366 CLEAN**。仅适用于用户此前装入的相同开发候选，不能依据版本显示就假设本地另有未导出的改动不存在。
- `03`：**干净 REF-365 HEAD → REF-366 CLEAN**。`01` 和 `03` 是互斥起点，禁止叠加。
- `02`：**CLEAN 完整状态 → 仅功能提交状态**，将累计的 `tools/` 和配套文档撤离；这时游戏 ASM、地图 Warp、正式版本号仍应保持。用户按功能日志提交。再执行 `git apply -R 02` 恢复审计工具和配套文档，按工具日志提交。
- 所有补丁必须在实际手机 Worktree 先 `git apply --check`，不强制覆盖未知修改。清理包只是提交准备，AI 没有在用户仓库 Commit/Push。
