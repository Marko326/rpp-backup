# CLEAN REF-367｜冰之通路 1F / B1F 正式收口与验收边界

> 状态：**正式源码清理与 Git 提交材料准备**，不代表已在用户手机 Commit、Push，或已完成四版 ROM / MAP / 设备全验收。

## 一、版本及基线

- 分支：`常规功能备份`；最后已核实正式 Git HEAD：`a95ac8d1ddaf47575bc4f08935033d014bfa58cf`（REF-366）。
- 开发态：REF-367M@，本次目标 REF-367@。没有重新设计运行 ASM；只将字母去掉，属于需要用户重新链接并验空间的正式版本变更。
- 当前清理的直接输入是用户最新上传的 `REF-367M.patch`（RPP Mobile 从 `a95ac8d1…` 导出的 Worktree 差异），已在重建的 REF-366 原始文件上通过 `git apply --check` 和反向检查。与此前 AI 所交付的 REF-367M 全量补丁对比，用户补丁多保留 `engine/johto_land_collision_gateway_272.asm` 的 `jr nz, .allowJump` → `jp nz, .allowJump`，正式版本必须保留该更正。仍无法从纯 PATCH 独立读取用户设备即时 `git status`，若存在导出后新增修改，必须先核对。

## 二、已纳入此次提交的功能（不宣称超范围）

- 1F stable ID70 与 B1F stable ID95，Gold 原版独立 tileset、图块、调色、碰撞角色、入口 Header、城都地图名称、1F/B1F 楼层地点牌；室外 44 号道路与烟墨市可分别进洞并原路退出。
- 1F 两组楼梯与 B1F 两组 Gold 目标 ordinal 相对应，可双向传送；注册 180 条方向 Warp，67 张活动图。
- 1F 与 B1F 允许在可骑车的 Gold FLOOR/洞口地毯上使用自行车，冰面目前仅普通步行，不自动连续滑动。
- B1F 四块固定石头 (11,7)/(7,8)/(8,9)/(17,7) 保持可见并阻挡，按 A 触发合法同 Bank 简短文本，禁止指针越界打开宝可梦中心菜单；本版本不能推动。
- B1F 的 PIT、通往 B2F 的两处楼梯暂时封闭，B2F 分区及 B3F 未激活；不增加 Rock Smash、NPC、遭遇、剧情。

## 三、缺陷成因、强制审计和负向验证

- 初次 1F 运行遗漏 CGB tileset ID41 调色板及地点牌分派，导致画面不正常和 `Johto` 默认名称；现在检查器验证 96 项 Gold palette、两张 palette 表长度与 ID70 的地点牌分派。
- `tilepal` 宏缩进、游离英文注释和非法 `jr` 目标未由最初的纯标签预检覆盖；现在 ASM 预检和冰洞代码专项加入负向故障注入。**静态预检不是 RGBDS 汇编证明**。
- B1F 石头早期只有阻挡无对象，后来有对象无文本指针，分别导致空气墙和误入宝可梦中心菜单。当前专项强制检查四个坐标的可见对象与碰撞一致、文本索引、同 Bank、文本结束符、未提前启用怪力移动；删除对象/指针、错 Bank/缺终止符的负向测试应失败。
- 旧 `johto_dark_cave_365_audit.py` 一直把全局数量冻结在 REF-366 以前的 65 图／172 Warp，现修正为本次 67 图／180 Warp，保留所有原有 Dark Cave 专项检查，新增误写 66 图／删一 Warp 的故障注入。
- 主迁移审计和历史专项测试还有多个冻结的早期版本断言，不因本次清理擅自删除；下方记录真实失败。

## 四、实际执行的静态测试

以下检查是在独立源码工作副本执行，**没有调用 RGBDS 编译或链接**。

| 实际命令 | 结果 |
|---|---|
| `PYTHONDONTWRITEBYTECODE=1 python -m pytest -q -p no:cacheprovider tools/tests/test_johto_dark_cave_365.py tools/tests/test_johto_ice_path_b1f_367k.py tools/tests/test_johto_ice_path_1f_367e.py tools/tests/test_johto_warp_field_entry_gate.py tools/tests/test_johto_map_name_sign_258.py tools/tests/test_johto_ice_path_367_stage.py tools/tests/test_johto_ice_path_367_movement.py tools/tests/test_johto_ice_path_367_slide.py tools/tests/test_johto_ice_path_367_native.py` | **106 passed**；包括全局地图数、注册 Warp、石头对象/文本越界等故障注入 |
| `PYTHONDONTWRITEBYTECODE=1 python tools/validate_current_project.py --skip-pytest` | ASM 标签、表长、Warp/Field Moves、1F/B1F、地点牌、Dark Cave Gold、Gold 资源、ICE/PIT/Strength 离线模型与 native 分支等前 **11 项 PASS**；第 12 项主迁移审计 FAIL |
| `PYTHONDONTWRITEBYTECODE=1 python tools/johto_pilot_migration_audit.py --project .` | **1515 pass / 35 fail**：旧城都版本冻结断言、早期医疗中心路线、65 图/168 Warp、早期 Surf 脚本、旧门房等；不是“全通过” |
| `PYTHONDONTWRITEBYTECODE=1 python -m pytest -q tools/tests` | **978 passed / 80 failed / 189 skipped / 95 subtests passed**，历史静态断言与 Surf Build Gate 数量冻结等遗留失败未自动修复 |

完整主迁移与完整 pytest 失败均保留：不要在下轮开启新地图时误当作通过或自动跳过。主迁移审计曾在 REF-366 时已有旧断言失败；本次依具体项目当前状态更新 **Dark Cave Gold 专项的两个全局计数**，并没有重写其余老合同。

本次还修复 `tools/johto_surf_coverage_audit.py` 作为 `tools.*` 包导入时的兄弟模块路径兼容性，使新冰洞 Surf 清单的独立测试能实际运行；工具修复不改变游戏运行字节。

## 五、用户已报告／仍未完成的设备验证

- 用户此前展示了 1F 乱码与默认 Johto 地点牌、B1F 石头空气墙及对石头按 A 误弹出 Heal/Cancel 的截图，开发候选已分别修正源代码。
- 用户最近反馈：石头当前不可推动；使用穿墙金手指检查其他区域，暂时未发现问题。**不能由此确认正常状态下石头可推动、落洞完成或所有未到达区域通行**。
- 旧模拟器即时存档可能包含未重载的地图对象/Warp；每次更换 ROM 应由室外正常存档重新入洞或退出/重新进入地图，并验证两组楼梯的双向传送、石头正常提示与洞口退出。
- 当前没有 REF-367 正式版四套 RGBDS 0.5.2 新 ROM 与 MAP，ROM0 是否至少余 64 B、Bank 安全、Red/Blue/两种 TEST 链接均**未验证**；本助手不编译、不链接、不执行手机测试。

## 六、模式 A 的三件套与正确执行顺序

1. 先核对 `git rev-parse HEAD` 与 `git status --short`，确认无额外未记录修改。
2. 已完整安装 REF-367M 的工作区，选 `01_REF367M_开发态_到_CLEAN_REF367_清理增量.patch`；只有正式 REF-366 干净 HEAD 时选 `03_HEAD_a95ac8d1_REF366_到_CLEAN_REF367_累计全量.patch`；**01 与 03 互斥，不叠加**。
3. `git apply --check 所选.patch` 后 `git apply 所选.patch`。
4. 对最终完整状态，先 `git apply --check 02_CLEAN_REF367_到_仅游戏功能_工具反向隔离.patch`，再 `git apply 02_CLEAN_REF367_到_仅游戏功能_工具反向隔离.patch`，用功能日志自行执行第一笔 Commit。
5. 第一笔完成后使用 `git apply -R --check 02_CLEAN_REF367_到_仅游戏功能_工具反向隔离.patch`、`git apply -R ...` 恢复工具+文档，检查 `git status` 后用工具日志自行执行第二笔 Commit/可选 Push。
6. 验证两条起点最终文件字节和 Git 可执行权限一致、反向撤销后回到各自起点。`02` 不得碰游戏运行代码、资源或 `data/game_version.asm`。
