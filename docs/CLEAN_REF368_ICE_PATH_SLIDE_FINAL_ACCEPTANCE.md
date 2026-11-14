# CLEAN REF-368｜冰之通路五层与滑行动画正式收口（2026-11-14 07:54 北京时间）

> **状态**：已准备正式提交材料；本助手没有在用户手机仓库执行 Git Commit/Push，也没有编译或链接 ROM。

## 1. 真实来源与版本

- 用户手机导出：`REF-368G.patch`，声明分支 `常规功能备份`、工作树 `/data/data/com.termux/files/home/rpp-backup`、正式基线 `cd88452a05e9399b469f12fe2c6c89dd532dfcfb`（上次正式 REF-367）。当前补丁没有 `.git` 元信息，不能代替实时的 `git rev-parse HEAD`、`git status --short`。
- 以 REF-368B 源码包及 REF-368B 的全量差异反向重建正式 REF-367，保留 REF-368B 源码相对于早期 AI 差异的一处 JP 热修；全部 **62 个**本次用户差异的旧 Git blob ID 与重建正式基线完全一致。对该基线应用用户完整 PATCH 成功。
- 相对上一份 AI REF-368G 全量补丁，用户最新工作区额外保留 **5 处 JR→JP**：两处 Route32/33 跳崖放行、两处 `HandleLedges` 路由短跳、一次 B3F 立即楼梯处理。五处原样保留在最终功能提交。
- 清理前：`REF-368G@`；正式显示：`REF-368@`，相对正式 REF-367 数字 +1。仅替换版本标签、维护审计及过期代码注释，不重写已经手机体验确认的移动指令。

## 2. 本次累计功能与保留的例外

- 五张 Gold 冰之通路地图活动：1F ID70、B1F ID95、B2F 卡吉侧 ID96、B2F 烟墨侧 ID97、B3F ID98；全局活动地图 **70** 张、方向 Warp **188** 条。
- 双向楼梯、合法出入口、1F 与 B2F 烟墨侧跳崖、洞穴逃洞绳／挖洞的室外来源，地图音乐、牌子、Town Map 和存档索引均保留。
- ICE 上实际自动按原方向移动；普通步行滑行保持脚部朝向帧，撞墙停止后恢复正常动作。骑行状态使用自行车帧，不冻结其动画。
- **骑车规则的精确定义**：五张地图都允许在 Gold FLOOR（1F 还允许 3 格洞口 CARPET）新上车，ICE 不允许新上车；但已经骑车时，进入 ICE **不会自动下车**，跨楼层也保留骑行状态。这是目前源码明确的既定政策，非隐藏的状态错误：`IsBikeRidingAllowed` 在五层均先判断 `wWalkBikeSurfState == 1`，滑行控制器也仅禁止 Surf，未自动清 Bike 状态。用户这轮亲自反馈了该行为。**这不等同于“冰面上绝对禁止存在自行车”**；若日后要强制下车，须作为新的功能修改并重测精灵、音乐、地图切换及连续滑行动画，不应混入清理改版。
- 与 Gold 原版有差异：Gold 的 `map_setup.asm` 在 `DUNGEON` 环境会重置 Bike，而当前项目有意支持洞内普通地面骑车，因此不能将现有策略宣称为 Gold 原样复刻。
- 未实现：B1F 四块怪力石头的推动／四个 PIT 落洞及 B2F 到达处理、Rock Smash、道具、NPC、部分剧情；这些均不属于此次完成范围。

## 3. 本轮修复的验证盲区与负向注入

- 以前 `tools/johto_ice_path_b3f_368b_audit.py` 仅接受 `jr z, .unionCaveLadder342`，错误地拒绝用户当前手机工作区的 `jp z`；只在工具检查器中将合法期望改为实际的 `jp`，不动手机已验证的游戏路由。
- 在 `tools/johto_ice_path_stair_ledge_368d_audit.py` 补齐上述五处热修检查，负向测试逐一将 `jp` 改回 `jr` 并确认检查器能拒绝。现有 ASM 符号预检只覆盖标签存在性，并不计算 RGBDS 相对跳转距离，**本轮未运行汇编／链接**，对真实字节距离仍依赖用户构建。
- 隔离工具补丁只撤回 `tools/`、测试及相关维护文档，不碰功能代码、五处 JP、地图、资源、`data/game_version.asm`。

## 4. 审计与设备范围

（本节的计数以最终清理源码执行的命令输出为准；本轮产生的测试日志由交付者留档，提交日志仅描述功能和工具变动。）

- 已实测（用户口头反馈）：B1F 楼梯正常、冰面滑行正常、普通走路正常、骑车仍有骑行动画且可接受；骑车进入冰面不会主动下车。**未提供四个目标 ROM/MAP 或所有楼梯、道具、存档状态的逐项录像。**
- 本助手依据项目要求不编译 ROM；因此没有 RGBDS 四版本结果、最新 MAP、ROM0 ≥64B 的证明，亦不能把静态脚本 PASS 当成手机 PASS。
- 实际执行 `PYTHONDONTWRITEBYTECODE=1 python -m pytest -q -p no:cacheprovider tools/tests`：**1076 passed、81 failed、189 skipped、95 subtests passed**。失败集中在早期冻结的 ROM 版号/地图数/旧 Surf 合同、缺少的 `data/wildPokemon/nomons.asm` 和其它既有历史依赖；**不称全绿**。
- 实际执行 `python -m pytest -q tools/tests/test_johto_ice_path*`：**166 passed**，包含五处用户长跳的故意短跳错误注入；本轮没有由测试修改游戏行为。
- 实际执行 `PYTHONDONTWRITEBYTECODE=1 python tools/validate_current_project.py --gold-root ../gold --skip-pytest`：**前 16 项源检查 PASS**（包含 152/152 Warp/Field、1865 个 ASM 本地符号、70 地图表长、Gold 五层骑车逐格检查及 ICE 控制器）。第 17 项 `current migration audit` 在持续高 CPU 运行约 5 分钟未产生结果时人工终止，统一入口最终 **FAIL / 未完成全量审计**；不能称第 17 项通过或虚报本轮迁移总通过/失败条数。上轮已报告的约 35 条历史冻结失败仅属历史参考，非本轮完整 Gold 审计结果。
- 主迁移全量审计有历史冻结断言失败，不能把它写成通过；全量 pytest 与单项源检查的实际结果需分别报告。

## 5. 正式模式 A：三份补丁 + 两份日志

1. 用户先在手机执行 `git rev-parse --abbrev-ref HEAD`、`git rev-parse HEAD`、`git status --short`，核对 `常规功能备份` / `cd88452a05e9399b469f12fe2c6c89dd532dfcfb` 及是否已经安装完整用户 `REF-368G.patch`。若不一致，先停止，不能硬打。
2. **已安装用户 REF-368G.patch 的未提交工作树**：`git apply --check 01_*` 后 `git apply 01_*` 进入完整 CLEAN；**仅干净 REF-367 HEAD**：选 `03_*` 全量补丁直接进入相同 CLEAN。**01 与 03 二选一，绝对不叠加**。
3. 在完整 CLEAN 上 `git apply --check 02_*`、`git apply 02_*`，暂时撤回工具／测试／文档部分；保留五层地图与运行 ASM、五处热修及 REF-368@ 版号；按功能日志自行 Git Commit。
4. 第一笔提交完成后，`git apply -R --check 02_*`、`git apply -R 02_*` 恢复工具与文档；再按工具日志执行第二笔 Git Commit，之后是否 Push 由用户决定。
5. 若仍有旧迁移失败，依据本文件记录并单独处理，不可删除测试以假装通过。以上补丁的字节一致、逆向可还原验证由本轮打包脚本执行并报告。
