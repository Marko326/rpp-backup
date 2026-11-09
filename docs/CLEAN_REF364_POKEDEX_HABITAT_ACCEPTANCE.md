# CLEAN REF-364｜图鉴出现地点 #054 正式清理及地区形态 AREA 独立调查

## 一、来源和边界

- 上传 `REF-363(2).zip` 的 `RPP_PROJECT_CONTEXT/02_EXPORT_INFO.txt` 记载分支 `常规功能备份`，干净 HEAD `bf682c5ca1e7b67c2d0d21a949b86a72b6a08378`、版本 `REF-363@`，无未提交 Patch。ZIP 不含 `.git`，不冒充手机真实 Git 查询。
- `REF-363A@` 是从上述 HEAD 干净源码应用 #054 开发补丁得到的工作区候选。用户上传 Tentacool、Dugtrio、Slowpoke 三张 AREA 截图，显示正常；这不能证明全部 Species/Form 和所有设备无回归。
- 正式版号为 `REF-364@`。清理过程保留候选 `CheckMapForMon` 的有效指令，不改遇敌数据、形态代码、WRAM／HRAM；仅升正式版号、同步工具和文档。

## 二、游戏功能：只修重复写入

- `engine/items/items.asm::FindWildLocationsOfMon` 对每张 `WildDataTable` 地图扫描陆地、水面两组，每组最多 10 个遭遇槽。原来每个同种槽位都往 30 字节 `wBuffer` 追加相同 MapID，待 `DisplayWildLocations` 调用 `ZeroOutDuplicatesInList` 才消重；**消重之前**可能挤占缓冲区。
- 新 `CheckMapForMon` 每个组匹配首个槽位后，仅写一次 MapID，并跳过本组剩余槽位；仍由原调用方扫描第二组。地图顺序、最终地图编号集合、逻辑 Route20／Seafoam 节点与结尾 `$ff` 不变。当前源码普通模式去重后最大 13 条、困难模式最大 15 条；预算按最多再加两个逻辑地点和一个结束符，均小于 30 字节。旧 REF 数据最大 28 条本来能存放终止符，不能称旧 REF 已发生真实溢出。
- 原有 `main.asm::BuildPokedexTownMapLocations` 在追加逻辑地点前检查剩余空间，但无法保护最早的逐槽写入。新增测试检查当前遭遇表支持的条件语法、两个分组/10个槽、两种难度的所有物种去重前后地图集合及字节预算。负向注入虚构 28 张地图 + 2 个逻辑点 + `$ff`，31>30，要求检查器拒绝。这是静态容量检查，不是模拟器故障复现。

## 三、地区形态出现地点：发现未解耦，但本版不修

- **生产端已解耦**：`data/wild_form_producers.asm::RegionalFormWildEncounters` 通过精确 `(MapID, source|slotIndex)` 指派 Form；`engine/wild_form_producers.asm::RegionalFormGetWildFormBySlot`、`engine/regional_form_producers.asm::RegionalFormStageWildEncounter` 根据选中的野外槽位保存原始遭遇形态。当前表列出 13 条地区形态草地槽位，分布于 10 种物种；其它未匹配槽位为普通形态。不代表全部 42 个登记形态都有随机野外出处。
- **Info 与 AREA 路径不一致**：`engine/menu/pokedex_info.asm` 的图鉴详情保存 `wPokedexViewForm`，但 `engine/menu/pokedex.asm::HandlePokedexSideMenu.choseArea` 直接调用 `LoadTownMap_Nest`。`engine/town_map.asm::DisplayWildLocations` 通过 `main.asm::BuildPokedexTownMapLocations` 调用 `FindWildLocationsOfMon`；后者仅用 `wd11e` 物种编号比较遭遇表，未读取 `wPokedexViewForm`，也不查地图+槽位的地区形态表。普通／地区形态 AREA 因而汇总相同的物种地点，#054 去重并不能修正形态语义。
- **普通难度实例如下**：阿罗拉小拉达指定 `ROUTE_1` 槽 1/2/9，普通小拉达另见 `ROUTE_2/3/4`；阿罗拉六尾指定 `ROUTE_7` 槽 4/6，但普通六尾分布 `ROUTE_8` 及宝可梦屋 1–4F；洗翠霹雳电球指定 `POWER_PLANT` 槽 0，普通霹雳电球另见 `ROUTE_10`。目前 AREA 仍显示物种并集。
- **同地图并存**：`ROUTE_1` 蛇纹熊含普通槽位和伽勒尔槽 3；`SAFARI_ZONE_WEST` 肯泰罗含普通槽位和帕底亚火炽种槽 1。按整张地图判断形态同样会误判，未来必须在**精确槽位**层面过滤。
- **独立后续需求**：定义用户如何在图鉴选择某一 Form 再查看 AREA；过滤必须覆盖 `Species + Form + MapID + 来源 + 槽位`，保留旧有逻辑地图节点、30B 缓冲预算、普通/困难及红蓝差异。没有自然遭遇的形态应明确是 Area unknown 还是显示进化/礼物/固定事件来源；钓鱼、Headbutt、静态野生入口可能不属于目前 `WildDataTable`，不可仅改草地表就宣称完全解耦。此项仅调查记录，无运行 ASM 变更。

## 四、验证边界、版本与空间

- 实际定向回归：`python -m pytest -q tools/tests/test_ref364_pokedex_habitat_buffer.py tools/tests/test_ref363_both_trainer_atomic_exit.py tools/tests/test_ref360_player_pc_sprite_clipping.py tools/tests/test_ref359_pc_item_prompt_removal.py tools/tests/test_doorway_lcdon_copy_pair_351a.py tools/tests/test_doorway_fast_copy_351c.py tools/tests/test_doorway_cgb_rgb555_fade_351b.py tools/tests/test_ref354_spark_ext_identity.py tools/tests/test_johto_route43_pair_316.py`：**57 passed, 1 skipped, 5 subtests passed**。另运行 `python tools/johto_south_geometry_preflight_268.py --root .`：`PASS`，六张候选地图几何合同通过，不扩写为所有城都地图全绿。
- 全库测试按 `tools/tests` 中 130 个 `test_*.py` 文件字母序切成 `[0:44]`、`[44:88]`、`[88:130]` 三组，分别执行 `python -m pytest -q <该组文件清单>`，合计 **906 passed, 34 failed, 205 skipped, 98 subtests passed**。34 项失败的测试 ID 集合与 `REF-363A` 候选全库测试一致（均可识别的 26 个失败测试 ID，含参数化失败项）；**没有新增失败测试 ID，但不能写成全绿**。
- 收口过程中曾发现正式版号 `REF-364@` 与 `data/game_version.asm` 顶部 `Canonical project version` 注释不匹配，触发旧版审计的额外失败；已同步改成 `REF-5.62.364`，并用上述三组测试重新核对。此前尚未修正注释的一次单命令全库运行结果**不是最终状态**，不得当成当前失败数。
- 本次 #054 审计有容量负向用例，人工虚构超过 30B 的 31B 列表并检查失败；只覆盖当前解析的 `WildDataTable` 与 `_HARD` 分支语法，未来改格式必须扩展数据审核。
- 版本：`REF-363@`（HEAD）→ `REF-363A@`（开发候选）→ `REF-364@`（正式提交）。正式候选和新正式版的 #054 指令逐字相同。
- 上传旧 Red/Blue MAP 只对应 REF-363；旧 Bank `$03` 余量约 8B，而此次 #054 静态增量估约 7B，空间极其接近上限。**没有此次正式版新 ROM/MAP，所以不能声称已通过链接。** 项目要求 ROM0 至少 64B、银行余量由用户编译的最新 Red MAP 为主核对。必要时单独查 Blue/TEST；本助手不编译／链接 ROM、不执行 Git Commit/Push。

## 五、模式 A 清理三件套（3 补丁 + 2 日志）

1. `01`：只用于用户已应用本次 `REF-363A` 开发候选的工作区，获得最终 CLEAN 状态。
2. `03`：仅用于当前确在上述 `bf682c5c...` 干净 HEAD 且尚未应用候选的仓库，直接获得同一最终状态。**01 与 03 二选一，不可叠加。**
3. 到达最终态后应用 `02` 工具部分反向隔离补丁，留下游戏功能及版号，由用户提交第一笔功能 Commit。
4. 再 `git apply -R 02_...patch` 恢复原本的工具／测试／文档，按第二份日志提交工具审计 Commit。整个过程中保持运行功能不变；用户先用 `git apply --check` 和 `git status` 检查状态。
