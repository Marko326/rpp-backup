# CLEAN REF-364 TOOL-CLEANUP-2｜Union Cave 与 REF-364 现行审计收口

**基准：** 用户本轮重新上传的 `REF-364.zip`。该快照已经包含第一轮工具去重与 B1F-339 历史审计归档；活跃 Python 文件为 **233 个**。本轮没有重复第一轮，也没有新增 Python 脚本。

## 1. 本轮处理

### 1.1 Union Cave / B2F 旧合同

- `tools/johto_union_b2f_340_audit.py` 移除 REF-343、60 张地图、60 个 source、142 条 Warp 等冻结快照断言。
- 改为验证当前活动地图数与 source count 一致、运行资源描述符长度由活动地图数推导、Warp 记录为 5 字节且汇编 ASSERT 检查记录整除和数量上限。
- 保留 B2F header、stable slot、1F/B1F/B2F 路由、水面坐标、边框块与 NITE palette 等真实功能检查。
- UNION-260 测试更新为三层洞穴：核对 10 条洞穴路由、到达不自动迈步、LADDER 与 DOWN 地毯按楼层/槽位触发，以及 B1F/B2F/Slowpoke Well 内部楼梯不允许碰撞触发。
- 修正 REF-341、REF-263 两处负向故障注入锚点，不再依赖某个 token 紧邻 `$FF` 或两个地图分支相邻。

### 1.2 REF-364 现行 64 地图 / 164 Warp 合同

- RPP active Gold/header registry 补齐 7 个现役地图：Union Cave B1F/B2F、Slowpoke Well B1F/B2F、Burned Tower 1F/B1F、Dark Cave；当前 header registry 与活动表均为 **64 张地图**。
- Warp 合同数量从旧的 160 更新为 **164**。主迁移审计仍逐条验证完整 164 条批准路由；室内注册生成器验证它负责的已审阅路由作为有序子序列存在，并核对声明数量与运行时表行数一致。
- Surf 覆盖与构建门检查更新为 64 张活动地图、28 张含水地图、5,372 个水面格；覆盖清单纳入 Dark Cave。
- Town Map、Browse Index、音乐表、Map Name Sign、Map Script Bank 与 REF-348 Burned Tower 审计同步到 64 张活动地图；Burned Tower 保持 slot 62，Dark Cave 为 slot 63。
- 调色板审计按当前 `data/tileset_headers.asm` 的实际 tileset 数计算每组 8 项，不再固定旧的 38 组；Burned Tower / Dark Cave 调色板与 Warp 指针检查改为核对当前实际表结构。

### 1.3 现行源码路径的回归测试

- Bike 测试纳入 Dark Cave 的专用例外，同时保留 Johto region 与 Route31 gate 检查。
- Burned Tower 到达测试明确核对 Dark Cave 和 Ecruteak Tower 两个已审阅的自动步进分支。
- Pokecenter 负向测试锚定当前 Dark Cave、Burned Tower 分支之后的 carpet dispatch。
- 南部跳跃测试核对 map/region guard 位于共享 `JohtoSouthHopLandingGuard`，不再要求它重复出现在 `CollisionCheckOnLand`。
- ROM0 Surf 故障注入、64 地图迁移审计 fixture、室内注册故障注入等测试更新到当前源码结构。
- REF-348 审计现在验证 slot 62/63 的 Town Map、Browse Index、音乐、palette rows 与 B1F Warp pointer。

## 2. 保留项与未完成输入

- `tools/johto_union_cave_collision_340_audit.py` **保留**。它独有逐格 Gold collision role、四方向陆地/Surf 移动、UP_WALL/HOP_RIGHT 规则和负向控制；主迁移审计没有等价覆盖。
- Collision-340 需要外部 Gold 源码目录。本轮环境缺少 `/mnt/data/gold_reference/data/tilesets/cave_collision.asm`，因此没有运行 Gold 对照；保留不等于宣称已通过。
- 本 ZIP 的 `data/wild_mons.asm` 引用了 `data/wildPokemon/` 下 **60 个 ASM 文件**，但该目录和 60 个文件均未包含在上传 ZIP 中。图鉴地点测试因此有 3 项无法运行；不创建空文件、不跳过、不伪报通过。需要用户补齐原目录后才能验证这部分数据。

## 3. 验证结果

- Union Cave 定向测试：**17 passed，16 subtests passed**。
- 本轮受影响测试集合（不含缺少野外数据的图鉴测试）：**128 passed，31 skipped，36 subtests passed**。
- B2F 静态审计：**23 passed / 0 failed**。
- `python tools/validate_current_project.py --skip-pytest`：通过。
  - ASM local-symbol preflight：1,851 个 ASM 文件。
  - 活动表长：Town Map 256/256、Browse Index 64/64、GSC Music 64/64。
  - 主迁移审计：**1,538/1,538，PASS_STATIC_ONLY**。
- 全仓库 pytest：**939 passed、3 failed、189 skipped、106 subtests passed**。3 项失败全部来自缺失的 `data/wildPokemon/*.asm` 输入，不是本轮修改后的断言失败。
- `git diff --check` 与本轮 Python 文件 `py_compile`：通过。

## 4. 交付边界

- 本轮改动限于 Python 审计、测试、JSON 合同与维护文档；**没有修改 ASM、地图/图块资源、游戏版本 `REF-364@`、ROM 构建配置或存档结构**。
- 活跃 Python 文件仍为 233；没有新增脚本，也没有继续删除 340 碰撞审计。
- 补丁不包含 `RPP_PROJECT_CONTEXT/` 或 `RPP_COMMIT_RESTORE/`；它们是导出工具附加资料，不属于 Git 源码。
- 未编译/链接 ROM、未生成 MAP、未进行设备验收、未执行 Git Commit/Push。

**轮次结论：** 第一轮完成工具去重，第二轮完成现行审计合同收口；两轮未提交工具变更一次 Git 提交。这是离线工具/测试清理，**本次不要求新 ROM、MAP 或游戏内验收**；缺失野外 encounter 数据与外部 Gold 参考仅限制对应测试，不能当作本次脚本清理失败，也不宣称全项目测试通过。后续游戏功能验收单独安排，不再为此开启第三轮工具清理。


## 5. 单次提交基线与补丁选择

- Termux 导出 `REF-364.patch` 标注分支 `常规功能备份`、Git 基线 `d4e06edc1cd8d7c76b030c87fd34bc47a5237d24`。本次累计差异按该导出记录，不声称已读取手机实时 Git HEAD。
- 正式交付 `01_工作区到CLEAN.patch` 与 `02_HEAD到CLEAN_累计.patch` **互斥**；另附 `03_commit-message.txt`。已经应用导出工作区改动的项目使用 01；真正处于导出所述干净 HEAD 的项目使用 02；不可叠加。
- 不进行双提交工具隔离；用户在 Termux 核对 `git status` 后一次 Commit。游戏版本继续 `REF-364@`，不作 Git Push。
