# REF-319｜当前统一验收与历史脚本基线修复交接（2026-11-02）

> **DEV-323 补充（仍是开发测试阶段，不是正式清理／提交）**：用户最新 `REF-319.patch` 经从干净 `a167b2ad...` 上正向应用并反向检验，构成当前未提交工作区。后续 DEV-323 仅补强 tools/tests 版本真实指令及 Lake 运动入口顺序的负向故障注入，删除误导“解压覆盖”的 `APPLY_PATCH_README.txt`；不追加新地图、人物、剧情，也不改变 ROM 版本 `REF-319` 或游戏 ASM。开发包只交**两份互斥的正向补丁**（当前用户工作区→DEV-323；已确认干净 HEAD→DEV-323），无需工具隔离反向补丁、中文 Git 提交日志。用户**只应用其中一份**，不能把用户已有 `REF-319.patch` 再与累计全量补丁叠加。

> **本文件为本次维护修复的最新验收入口。** 旧 README、DEV-312 交接与 `RPP_PROJECT_CONTEXT/02_EXPORT_INFO.txt` 记录的是各自时期的历史或原始导出，不能代表此修复包已经 Git 提交，也不能用旧阶段的地图数/版本号否定 REF-319。原始导出 HEAD 为 `a167b2ad2bc8b12d3cb777c7120c008f7fdf8a5b`；本包是此基础上的工作副本，**未创建 Git 提交、未 Push**。

## 当前源码状态和本次改动范围

- 游戏仍是 `REF-5.62.319`，正式活动地图基线 **42 张**；Route43、ID65、ID66 和 Lake of Rage 室外通行逻辑保持不变。Lake 两座房屋、暴鲤龙、渡及剧情仍然**未实现**。
- 唯一涉及现有游戏 ASM 的调整：`engine/johto_pilot_town_map_browse.asm` 的 Lake 名称从 `Lake Of_Rage@` 统一为 `Lake of_Rage@`，与正式 Town Map 名称大小写一致，**字符总长度不变**。没有修改任何地图地形、角色碰撞、战斗或运行时 Warp 数据。
- 修复 `tools/johto_pilot_migration_audit.py` 旧阶段 Warp 预期：把已批准的 Route43 与 ID65/ID66 的 11 条新增 Warp 纳入精确审批清单；检查相同 map+ordinal 入口唯一，所有 map 级 Warp 联系必须存在反向关系。
- 修复旧工具：Gate 配色审计从当前活跃门房清单计算；RPP 当前地图 reviewer 覆盖至 ID68；室内登记生成器修正 ID65 已批准 Warp 的排列顺序；南部/公园/西部历史检查不再要求全项目地图数量永远停在旧阶段。
- 新增 `tools/johto_audit_phase.py`，旧专项审计验证 **至少达到自身阶段**，拒绝版本回退、TEST 类版本及低于阶段的地图数；不会把“当年只开了 26/39 图”当作未来版本的绝对上限。
- `tools/johto_audit_phase.py` 新增检查：**只接受一条实际 `db "REF-NNN@"` 标签指令**，防止历史注释骗过版本检查；若源码含 canonical 项目版本注释，其编号必须与实际指令一致；活动地图数量声明也不能重复。
- Lake 的移动分支增加“Carpet fast path → `ret c` → Gold role 调用 → 读取 E → 放行/阻挡”执行前缀顺序检查，注入提前 `ret` 或丢弃 E 返回值都必须失败；这仍是源码级门禁而非 CPU 模拟。
- `tools/johto_lake_of_rage_321_audit.py` 增加源码级分支终点校验：`.allow` 应返回 `E=0`、`.block` 应返回 `E=1`，同时断言实际跳转可进入这些出口。对应负向故障注入测试现在可捕获返回值反转和入口分支写反。Lake 当前第 41 槽保护不限制未来追加新地图。
- 旧 pytest 夹具、版本号和历史阶段检测基线同步更新；负向测试改为从当前源代码读取真实版本标识再实施故障注入，以免将来换版本后因为找不到旧字符串而假失败。
- 新增统一入口 `tools/validate_current_project.py`：执行 ASM 符号预检、活动表长度断言、当前综合迁移审计、以及仓库 76 个 pytest 文件的完整测试（分组并行）；只要任一步失败，整个命令非零退出，**不会把失败静默跳过**。

## 必须使用的验收命令

在项目根目录执行：

```bash
# 原版 Gold 参考项目可用时（优先）
python tools/validate_current_project.py --gold-root /path/to/pokegold-master

# 未持有 Gold 参考源码时，执行当前静态及能运行的 pytest；
# Gold 专项可能被跳过，不能当作原版精确比对已通过。
python tools/validate_current_project.py

# 修改运行时代码后，在配备 RGBDS 的本机额外执行：
python tools/asm_symbol_preflight.py --build
python tools/johto_rom0_space_preflight.py --root . --require-fresh-map
```

**严禁**只执行某一个历史 `DEV-xxx` 检查就宣称当前版本整体验收。旧脚本可用于特定功能追责，但当前接收工程时先执行上面的统一入口。未来新增地图或 Warp，必须在当前严格审计的批准清单、活动表及其测试里同步登记；不能为了全绿而放宽拒绝未知入口的规则。

## 实测证据

在本次打包前，对修复后的工作副本执行：

| 项目 | 结果 |
|---|---|
| 统一验收入口（含 Gold 参考） | PASS，全部 7 组检查通过 |
| 当前迁移综合审计（含 Gold 源文件对比） | **1220 / 1220** PASS，0 FAIL，`gold_reference=PASS` |
| 所有 76 个 pytest 测试文件 | **542 passed，81 skipped，101 subtests passed，0 failed** |
| ASM 局部跳转符号预检 | **2097** 个 ASM 文件 PASS |
| 活动数据表长度 | 3 表 PASS；42 张活动地图，168 字节 Town Map 条目、42 字节浏览索引、42 字节音乐表 |
| 移动和 Warp 负向故障注入 | 可检测 Lake 允许/阻挡返回值反转及 Warp 重复入口、缺失反向路径等样本 |

`81 skipped` 的项目不可解释为 81 项测试通过；其中包含历史阶段快照或依赖环境的跳过。实际覆盖情况以 pytest 具体报告为准。

## 没有完成、仍需本机验收的事项

1. **没有 RGBDS 编译器／链接器**，因此本包没有重新构建 Red、Blue、两种 TEST ROM 或重新生成 MAP；测试结果均为静态源码及 Python 检验，不等于游戏正常运行。
2. 随工程附带的 `patches/*.map` 是**原始 REF-319 导出文件**，不是本次源码修复后重新链接的产物。原先 ROM0 仅剩 64B（项目最低要求），应在真实编译后检查最新 Red/Blue MAP 的 ROM0/ROMX 余量。
3. Lake 接缝和地图移动仍需在实体设备/仿真器上重新验收；源码分支断言 + Python 模型 **不是 Z80/Game Boy 指令级模拟器**，不能替代实机测试。
4. 旧 `tools/gfx.py`、`tools/pokemontools/gfx.py`、`tools/pokemontools/lz.py` 属于早期 Python 2 风格/混合缩进工具，直接用 Python 3 `compileall tools` 仍会报语法或缩进错误；它们不属于本次当前验收入口。若要迁移这些历史工具到 Python 3，请单独开工作项及针对性测试，避免无必要地动旧图形处理链。
5. 交接包中旧 DEV-312 “ID66 未开放”、旧 README 顶部“未提交”的描述是历史快照；请以原始导出记录和本文件区分历史与本次修复。**本包未提交、未推送**，由工程负责人自行 Git diff / commit。

## 后续维护原则：防止再出现“新窗口指出上个窗口测试坏了”

- 旧阶段单元测试：检查特定阶段实现的功能和最低条件；不要把当时的地图数量、ROM 版本、门房数量写成永久的精确值。
- 当前 release gate：保持明确的批准清单（当前 42 图、已注册 Warp、地图数据和空间要求），新功能接入时必须**同时**扩展当前门禁和负向测试。
- 新的检验条件必须有至少一个故意破坏源码或测试数据会使检查变红的样例。禁止只确认文件存在或字符串存在就称“行为已验证”。
- 下一次提交前必须运行统一验收入口；有工具不在环境或检查被跳过，必须明确列出，不可写成全绿；真实 ROM、MAP 和设备验证需另列证据。
