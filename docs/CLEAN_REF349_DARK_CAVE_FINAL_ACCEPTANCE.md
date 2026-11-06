# CLEAN REF-349｜Dark Cave R2 与骑车功能收口（提交准备，游戏显示 REF-349）

## 一、真实输入与提交边界

- 用户输入：`REF-348.patch`（RPP Mobile Worktree export）；分支 `常规功能备份`，`RPP-BASE` 为 `3a53f2d3a38e9b0c1ae89d5f4f722a00369d0ad4`。使用 `REF-348(2).zip` 自带的 `current_worktree.patch` 反向恢复同一 HEAD，随后用户本次上传的 `REF-348.patch` 成功正向应用；清理未将未提交状态误称为 Git HEAD，也没有加入旧的补丁包作为新的前置版本。
- 用户上传的 MAP：`MAP_20261106_192350.zip`，2026-11-06 19:23，内含 Red `rppred.map`、Blue `rppblue.map`，版本说明标记的是修改前的 `REF-348`；**没有 TEST MAP 或 ROM 文件**。本次升级为 `REF-349` 后尚无相同版号的新 MAP，以下余量仅作历史构建参照，不能称为 REF-349 构建通过。AI 没有自行链接 ROM。
- 本次重做清理仅修改游戏运行资源中的 `data/game_version.asm`，将统一显示版本等长更新 `REF-348@` → `REF-349@`；其余 `home/`、`engine/`、地图、图块、调色资源与实际游戏行为均不改。保持64活动地图、164条登记 Warp及存档布局。
- 项目采用**模式 A**：第一笔仅累计未提交游戏功能源码和资源；第二笔工具、审计、负向测试及维护文档。用户自行 Git Commit/Push。

## 二、已覆盖功能与用户真实反馈

- 本次累积未提交功能：Gold DarkCaveVioletEntrance（稳定ID190，活动槽63），40×36角色表（20×18 blocks），64处水格、26处方向跳崖；31号道路与46号道路双向洞口，回程自动向下迈步；未开放烟墨侧洞穴及其原始 ordinal1 Warp 继续封闭。
- 暗态保留可见主角、Gold风格白色入洞淡出、Flash照明、进出洞调色、合法冲浪/上岸、Gold HOP 起跳和墙后落点；自行车只在当前活动的ID190合法地面放行，保留其他室内的规则。Gold 地形数据与原版路径作为静态对照。
- **用户已明确反馈**：冲浪正常（“冲浪对了”）、最终跳崖无问题（“没问题了”）。31号道路进出曾在视频中观测出洞迈步改善。46号道路双向出口及新自行车规则本次没有独立的完整手机录屏/逐项反馈，**不能据“做清理三件套”自动升级为设备全覆盖验收**。
- 当前地图完成度是 **R2 通行能力候选**，不是Gold R3/R4：Gold的4块碎岩、3个道具球、隐藏Elixer、野生/钓鱼遭遇、事件及专用洞穴动画未全部运行接入。Dig/Escape Rope 仍不安全：不能单纯解开Tileset白名单，否则可能使用旧治愈中心回程。烟墨侧 ID99 保持未开放。

## 三、上传 MAP（REF-348）、空间门槛与未验收范围

| ROM区域 | Red剩余 | Blue剩余 | 说明 |
|---|---:|---:|---|
| ROM0 | 386B | 386B | 两者均≥项目最低64B；较历史420B减少34B |
| ROMX `$01` | 4B | 4B | 紧张，保护原近调用 |
| ROMX `$04` | 23B | 23B | 紧张，勿直接在Bank4扩代码 |
| ROMX `$29` | 5,318B | 5,318B | 与本轮 MAP 对应 |
| ROMX `$2A` | 15,001B | 15,001B | 与本轮 MAP 对应 |

- 以上为用户升级版本号**之前**生成的 REF-348 Red/Blue MAP 的 Bank `SLACK` 记录，仅供空间风险参考；即使 `REF-348@` 与 `REF-349@` 等长，也必须由用户本机构建 REF-349 Red/Blue/TEST 并更新 MAP，才可以确认新版本最终 Bank 余量。未提供 TEST MAP、ROM文件或可重现链接日志。
- 尚待手机确认：Route46双向循环、双洞口自行车进入/退出/SELECT、水边禁骑、禁行格、Flash后再进、冲浪上岸与跳崖联动、保存/继续/旧档、Kanto及普通门房回归。特别是 Bank1仅4B、Bank4仅23B，下一轮修改必须再取新 MAP。

## 四、静态审计清理（工具提交）

- 核实 Gold 综合审计原先4项FAIL都出自旧 Pokémon Center 独立审计将总注册 Warp 锁为162，虽然本批已合法新增 Route46 ↔ Dark Cave 2条，总数应为164。本轮仅更新这四处**总量比较**到164；保持各中心准确三向Warp、门房连通和原版资源校验不变，并同步把当前游戏显示版本审计更新为 `REF-349@`（历史测试夹具保留旧版本模拟）、增加删去Route46 Warp 的负向测试，避免仅改数字而让审计失效。历史 check 名称继续保留供既有负向测试匹配。
- **上一轮清理时、版本仍为 REF-348 的实际执行记录（历史证据，版本修订后重新验证结果见下）**：`python tools/validate_current_project.py --gold-root /mnt/data/route46_gold_ref --skip-pytest`：ASM 局部符号1850文件通过、三表长度64槽通过、Gold主综合审计1715/1715通过（Gold参考PASS）。`tools/johto_dark_cave_stage2_audit.py`及Surf门禁通过；相关专项pytest为111通过、5跳过及8项负向子测试通过。
- **版本修改前**完整 `tools/validate_current_project.py --gold-root ... --jobs 4` 的六组pytest实测汇总：**846通过、69跳过、54失败，另113项子测试通过**。失败包含历史阶段的63地图、BurnedTower、Route33、UnionCave、临时夹具缺新楼层等过期断言；不能宣称全部54项均经独立基线复核，也不能称全量测试通过。清理不擅自改写其运行语义或删除旧检查。
- 静态PASS不等于 RGBDS链接和GBC手机运行结果。新 `REF-349@` 版本号源级预检、专项测试及补丁回放的结果在本节下面另行记录；旧的全仓库54失败不应冒称为新版本完整复测。
- `PROJECT_DELIVERY_RULES.md`、`RPP_DEVELOPMENT_PITFALLS.md`、`TODO.md`、`README.md`、`docs/REF349_DARK_CAVE_VIOLET_STAGE2.md`、`docs/JOHTO_CONTENT_BACKLOG.md` 同步本批定版事实与遗留任务。下列旧文档中的 REF-349 Stage1/2 开发记录均属于时间线，不覆盖本清理结论。

## 五、模式 A 三份补丁 / 两份中文提交日志

1. `01_REF349_WORKTREE_to_CLEAN.patch`：**已应用用户本次 `REF-348.patch` 的工作区 → 本次修订清理完整状态**；新增单处 `data/game_version.asm` 版本号改动、相应审计/文档整理。不是从旧 CLEAN 补丁状态继续打。
2. `02_REF349_CLEAN_to_FEATURE_ONLY.patch`：**完整清理状态 → 暂时只保留第一笔功能差异**；要先打这一份并提交功能，之后 `git apply -R` 撤回这份隔离补丁，恢复第二笔的工具与文档，再提交工具。
3. `03_HEAD_3a53f2d3_to_REF349_CLEAN.patch`：从**干净 HEAD `3a53f2d3`** → 最终完整清理状态的累计全量；与01互斥，不能叠加。
4. `commit-message.txt`：中文功能提交日志，覆盖上述 HEAD 后所有未提交运行功能（不是只写最后骑车）。
5. `commit-message-tool.txt`：中文工具审计/维护提交说明，只写修改内容；全部执行结果和历史失败明细保留在本验收文档。

操作前务必核对 `git rev-parse HEAD`，并用 `git apply --check` 验证对应补丁；用户本机自行执行Commit/Push。AI不编译/链接ROM、也不进行Git提交。

## 六、REF-349 版本修订与执行记录（清理三件套重做）

- 游戏内 `GameVersionText` 由 `REF-348@` 等长更新为 `REF-349@`；Red/Blue/TEST 共用该字面量，不增添独立测试版号。版本文本位于 ROM0；**未改变指令、地图、Warp、Bank 分派或存档结构**。
- `tools/` 内与运行版本相关的审计和历史故障注入夹具同步识别 `REF-349@`；仅保留旧阶段断言作为历史范围验证，不把旧测试无关失败改写成通过。
- 本节保留最新源码检查及补丁回放的可复核结果；用户之前提供的 MAP 仍是 `REF-348` 版，**升级后的新 ROM/MAP 和设备版本画面仍待用户本机构建确认**。
- **本次重做后实跑记录（2026-11-06，REF-349@ 源码）**：`python tools/validate_current_project.py --gold-root /mnt/data/route46_gold_ref --skip-pytest` 退出码0，ASM局部符号1850文件通过，活动64地图对应三表长度通过，Gold主综合静态审计 **1715/1715通过，Gold参考PASS**。没有进行ROM编译链接。
- 另运行 `python -m pytest -q tools/tests/test_johto_batch_centers_336.py tools/tests/test_clean_ref349_legacy_center_counts.py tools/tests/test_johto_dark_cave_stage2.py`，得到 **64通过、1跳过、8项子测试通过**。这是本轮针对版本、Warp与洞穴的专项结果，不是全仓库结果。
- 上一轮版本修改前的全仓库记录为 **846通过、69跳过、54失败**（另113项子测试通过）；本次未重新运行全仓库 pytest，故不宣称该数值已因版号变更得到改善。历史失败须另批核查。用户 Red/Blue MAP 仍为 REF-348，修改版号后的完整Red/Blue/TEST MAP与My OldBoy实机版本标识仍待用户提供。
