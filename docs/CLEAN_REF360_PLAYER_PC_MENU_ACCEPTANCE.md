# CLEAN REF-360｜Player PC 主菜单人物遮挡修复与 REF-357～360 PC 菜单收口

## 1. 基线与版本

- 分支：`常规功能备份`。
- 干净提交基线：`e8da25d149f2afdf8df0f550668d16807fcb171c`（历史提交 #514，`REF-356`）。
- 用户提供的当前工作区补丁：`REF-360.patch`，头部明确声明上述 `RPP-BASE`；不将未提交工作区冒充新的 Git HEAD。
- 游戏内版本：`REF-360@`。本次正式清理只更新维护文档与待办，不再改变 ASM、测试逻辑或游戏版本。

## 2. 本次累计收口内容

- **REF-357**：图鉴前卧室 PC 进入 Player's item PC；图鉴后继续使用原完整 PC 路径，并保留独立的博士升级提示。
- **REF-358**：Player PC 父菜单先显示，再等待上一轮 B 松开，避免长按 B 连退并改善返回反馈。
- **REF-359**：Withdraw／Deposit／Toss 旧重复提问停止执行；原调用、包装器和正文保留为注释，实时道具说明继续使用。
- **REF-360**：将 `PlayerPCMenu` 原有唯一一次 `UpdateSprites` 移到下方固定提示框 `TextBoxBorder`/`PlaceString` 后、BG 自动传输开启前。没有增加调用次数，不修改 Bill's PC、公共列表、道具二级菜单、数量框、存档或全局精灵函数。

## 3. 用户实机反馈

- 用户明确确认：`360.mp4` 是 REF-360 ROM 的实测录像。
- 录像所覆盖的 Player PC 四选项父菜单不再出现人物压住底部 `What do you want to do?` 提示框的现象。
- 用户补充确认 Withdraw、Deposit、Toss、数量确认页面均没有该人物残留问题；宝可梦 PC 主菜单与二级菜单也不是本次异常页面。已按最小范围处理，没有扩大修改这些正常路径。
- 以上只证明用户录像和明确反馈覆盖的路径，不扩写为所有旧存档、设备、输入组合和菜单场景都已穷尽验收。

## 4. 自动化验证

### 定向回归

REF-354～REF-360 相关 14 个测试模块：**128 passed**。

### 完整 pytest 对比

| 状态 | Passed | Failed | Skipped | Subtests passed |
|---|---:|---:|---:|---:|
| 反向重建 REF-356 基线 | 837 | 61 | 196 | 98 |
| REF-360 当前工程 | 873 | 60 | 196 | 98 |

- 失败项 ID 集合没有新增失败；基线中唯一多出的失败是 `test_ref354_spark_ext_identity.py::test_spark_damage_abi_and_player_enemy_calls` 的过期固定版本断言，REF-360 已将其改为兼容后续版本的检查。
- 完整 pytest 仍有历史失败，因此**不能**标记为全仓库全绿，也不应在本次清理中顺手放宽无关 Johto 历史测试。

### 补丁核验

- `REF-360.patch` 共涉及 25 个文件（843 additions / 56 deletions）。
- 从 REF-360 完整工程反向应用该补丁，重建到 `REF-356` 基线；25 个变更文件的旧 Git blob ID 全部吻合。
- 将该补丁从重建基线正向应用，25 个变更文件的新 Git blob ID 全部吻合。
- 正向 `git apply --check` 与反向 `git apply --reverse --check` 均通过。打包时保留 `scripts/OaksLab.asm`、`text/maps/OaksLab.asm`、`engine/menu/players_pc.asm` 的 `100755` 权限。

## 5. 尚未独立归档的证据

- 本次助手没有运行 RGBDS 汇编/链接，没有生成 Red、Blue、TEST Red、TEST Blue 的新 ROM/MAP，也没有核验 ROM0/ROMX 空间余量。
- 用户确认 360.mp4 为 REF-360 ROM 实测；但本次未收到四种构建及其 MAP 文件，故仍将构建空间归档列为维护者待办。
- REF-357 图鉴前新游戏/旧存档、博士剧情提示等更广泛组合，不因本次 Player PC 菜单录像而宣称全部覆盖；历史 TODO 中的独立验收项继续保留。

## 6. 清理三件套与提交规则

本次按项目单次提交规则交付：

1. `01_REF360_当前工作区到CLEAN.patch`：只适用于用户上传 `REF-360.patch` 所代表的当前 REF-360 工作区，内容为文档/待办清理增量。
2. `02_REF356_HEAD到CLEAN_REF360.patch`：从干净 HEAD `e8da25d149f2afdf8df0f550668d16807fcb171c` 累计到 CLEAN REF-360 的完整补丁。
3. `commit-message.txt`：中文单次提交日志。

01 与 02 **互斥二选一，不可叠加**。不制作工具反向隔离补丁；功能、游戏版本、专项测试、工具与文档一次 Git Commit。由用户在真实 Termux 仓库执行 `git apply --check`、应用补丁、核对后 Commit/可选 Push；助手不代 Commit/Push。
