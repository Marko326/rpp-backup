# DEV-339｜REF-332 登记契约与全仓库回归修复

本轮基于用户上传的 REF-332 当前工作区与 Gold 原版参考源码。确认 Git HEAD 为 `300e0a4c4afece275db40a09558b5810d7deb8f4`，原 ZIP 附带的累计 `current_worktree.patch` 可反向还原到 HEAD 并重新应用。**没有修改游戏 ASM、地图资源、存档或游戏版本 REF-332。**

## 修复范围
- `johto_rpp_pipeline.py` 的活动 Header/Gold/stable ID 清单由47增加到48，末尾添加 `JohtoSharedPokecenterRuntimeHeader`（`CherrygrovePokecenter1F`，ID123，slot47），前47项不重排。
- `johto_indoor_registration_generator.py` 按 JSON 独立契约验证三条中心 Warp，准确插在 Guide Gent's House 三条路由之后，严格验证来源、目标、ordinal 与 Gold 坐标，107条必须逐条相符。
- `johto_pilot_door_contracts.json` 与 `johto_warp_arrival_audit.py` 同步总数107，保留原来三条 house Warp 和13个活动门房的严格检查。
- 更新 FieldMove、Indoor、MapScriptBank、SaveLocation、Surf 旧清单。中心无水，明确为 `NO_WATER`。
- 新增故障注入：移除中心 Header、破坏 slot47、改坏中心 Warp ordinal 与门毯坐标均应使审计失败。

## 实际验证
- `python tools/validate_current_project.py --gold-root <Gold> --skip-pytest`：2104 ASM 文件检查、48图3表 ASSERT、Gold 综合审计 **1518/1518 通过**。
- `tools/tests/test_*.py` 按维护入口的每19文件分组、设置 Gold 环境变量后逐组运行：123/2、181/10、219/36、159/0、45/1（各组为 passed/skipped）。合计 **727 passed，49 skipped，0 failed**，另有子测试通过。
- 统一入口连同 pytest 整批执行在当前环境超时，不将其算作全量命令执行成功；上述为五组实际完成的测试。
- 仅源码工具验收，不替代 Red/Blue/TEST 新 MAP、ROM0≥64字节或设备 Pokémon→Fly START 验证。

## 补丁交付
开发阶段提供两份互斥正向补丁：从用户 REF-332 工作区应用增量，或从已核实的干净 HEAD 应用累计全量。不得叠加。不进行 ROM 构建、Git Commit 或 Push。
