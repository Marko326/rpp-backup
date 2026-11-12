# REF-367B｜冰之通路 Gold 地形执行规格与安全落洞机制（尚未接入游戏 ROM）

> 本批基线是用户上传 `REF-366.zip`，`常规功能备份`，HEAD `a95ac8d1ddaf47575bc4f08935033d014bfa58cf`。以 REF-367A 资源前置包为当前**可复现**开发状态；**尚未收到用户已应用 REF-367A 的工作区导出**，不能默认手机已安装。

## 本批已落地

- 新增 `maps/johto_ice_path_stage/*.runtime.blk` 五份准备供专用 tileset 使用的运行块数据，逐字节与原始 Gold 块相等，不套用旧 `ICE_CAVERN` 的不兼容 metatile ID。
- 新增 `data/johto_ice_path_stage/ice_path_role_runtime_367b.asm`：五地图独立宽度/高度、越界 WALL、Gold 角色字节读取的 **LR35902 ASM 候选**。故意**不在 main.asm INCLUDE**，没有分配 Bank、没有增加 ROM0，也不宣称已通过 RGBDS。
- 新增 `tools/johto_ice_path_367_movement.py`：实际数据驱动的单次方向输入／冰上连续运动模型，墙停、方向墙、Gold 22 个 Warp 点的触发区别、四处 B1F PIT 到四个 B2F ICE 目的落点（**不允许从 ICE 上逆向穿回**），以及四个 Strength 石头的推移／落洞状态；含边界及穷举检查。
- 新增 `tools/tests/test_johto_ice_path_367_movement.py` 的正向/负向检查，并接入 `tools/validate_current_project.py`。检测缺失运行块、错误索引、非法 LR35902 指令、反向落洞、未实现时提前链接等问题。

## 已固定、不得修改的设计

| 机制 | 行为合同 | 后续 ROM 任务 |
|---|---|---|
| ICE | 一旦踏上冰面，沿当前方向逐格继续，直到遇障碍或到达非 ICE 格；中途方向输入不得改变滑动 | 接到真实玩家输入／逐帧动画，测试墙停后转向、B 键、菜单与脚本 |
| PIT | B1F 四处是**主动**落洞；落地的 B2F 四点是 ICE 仅到达点 | 接坠落动画、同步地图加载、检查非重复传送 |
| Strength | B1F 初始石头 (11,7)/(7,8)/(8,9)/(17,7)，可以推入 PIT，消失后在 B2F 创建落石物件 | 接旧版 Strength、对象/保存状态、四块石头对应落地物件、完整解谜路线 |
| HOP/UP_WALL | Gold 8 个跳崖、78 处方向墙均保留角色与方向条件 | 连接 HandleLedges 两步落地和错误方向阻挡 |
| 两端出入口 | Route44 / BlackthornCity，Gold 22 个洞内 Warp 保持原 ordinal；地毯只朝下出洞 | 接完整入口触发、到达自动迈步、Dig/离洞绳 |
| 色板和画面 | 使用 Gold ice_path 专用 .png + 64 块 .bst；`PALETTE_NITE` 无 Flash | 设计 RPP 正确的 tileset 动画/调色后再注册 |

当前 `REF-366@`、65 张活动地图、172 条注册 Warp 全不变。还**不能进入**冰之通路，不能 ROM 或手机验收。这不是 R2 完成声明。模型测试是方向状态规则验证，并非真实 GB CPU/图形/事件模拟器，不能把它冒充真实玩家可通行测试。

本期继续排除 NPC、野怪、道具、剧情与 B3F Rock Smash。**Strength 石头不延期**，这一套仍必须随五图开放一起实现。下一施工批需要将已审查的 ASM 角色读取接入 ROMX，在真实移动入口实现冰面滑行和落洞/推石，联动五图/两室外口后再开放地图并用 RGBDS 和四版 ROM/MAP/手机回归验收。

## 本轮离线验证（2026-11-10）

- Gold 原图静态审计 `johto_ice_path_367_stage_audit.py`：PASS，3,060 格／22 Warp／4 PIT／4 arrival-only ICE。
- 新 `johto_ice_path_367_movement.py`：PASS，五图运行块字节一致、673 ICE 格的方向模拟与落洞单向性。
- 本批模型 + 原有相关回归 pytest：42 passed（包含负向损坏注入）；ASM 局部符号扫描 1,855 文件通过。
- 静态扫描**没有**检查未链接文件在 RGBDS 下的最终 Bank 布局，未编译四版本 ROM；不可据此说 ASM 已汇编或 Ice Path 已通。
