# Gold → RPP 室内外转换工具链（离线 / 安全优先）

适用工程：RPP Mobile `GT-5.62.156` 源码与 Gold 原始源码。**工具代码不修改游戏版本，不会自动改动 ROM / ASM / PNG / .blk。**

## 为什么先写这些脚本

RPP 已有成熟的 Route15Gate1F 原生 Warp；城都关卡的室外门口不同，在 `NewBarkWarpTileIDs` 中添加 `$40` 会引入“踩格就触发”的风险。不能只复制 Gold 的 Warp 坐标，更不能把图块 ID 直接当成相同的碰撞行为。

## 五个阶段

1. `johto_native_warp_converter.py`：读取 Route15 原生样板、Gold Warp、RPP Warp、图块及引擎路径，生成门口移植方案；**不自行修改引擎**。
2. `johto_bidirectional_warp_validator.py`：静态检查目标编号/回路及越界，生成“门口停留、立即反向、两侧双入口”等最小实测清单；不把静态 PASS 当成实机 PASS。
3. `johto_indoor_tiles_converter.py`：仅将 Gold 室内 32×32 区块与 RPP 同一图块集做完整像素精确匹配；全部匹配时才可在输出目录生成候选 `.blk`。不匹配时另行尝试暂存**独立 Gold 专用图块集**（原图 PNG、缩紧的 `.bst`、重编号 `.blk`），从不覆盖现有 RPP `GATE`；后续仍需注册新 Tileset 以及解决碰撞、色板和 VRAM 预算。**不要直接复制 Gold 区块编号**。
4. `johto_indoor_collision_adapter.py`：逐四分块对比 Gold 的 16×16 碰撞标签与 RPP 8×8 通行白名单；DOOR/WARP_CARPET/混合标签不自动当作普通地面。
5. `johto_indoor_registration_generator.py`：校验地图尺寸、Header、Bank 指针、主文件引用，并列出未来新增地图的模板及人工接入项。

统一执行入口：`johto_indoor_pipeline.py`，依次调用五阶段并自动输出 JSON + 中文报告。共用解析器为 `johto_indoor_common.py`。

## 使用（把两个完整源码分别解压在不同目录）

```sh
python tools/johto_indoor_pipeline.py \
  --rpp /path/to/rpp \
  --gold /path/to/pokegold-master \
  --output /path/to/empty/external_review_folder
```

目标地图可通过 `--gold-room`、`--rpp-room`、`--outside-maps`、`--gold-tileset`、`--rpp-tileset` 更换。**目前引擎行为模板仍固定以 Route15Gate1F 为标准；其他门型应先核查参考样板的四口几何是否适用。**

报告：`00_summary.json`，`01_native_warps.json`，`02_bidirectional_warps.json`，`03_indoor_art.json`，`04_collision.json`，`05_registration.json`，可选的 `06_isolated_original_art.json` 和 `isolated_gold_art_candidate/`，以及 `REPORT_zh.md`。

## 对 `.156` 已知约束

- Gold 原版 `Route31VioletGate` 5×4 与 RPP 注册尺寸相符；Warp 双向编号结构可查。
- RPP 四个室外关卡 Warp 格的 8×8 图块均为 `$40`，并且 `$40` 出现在 `NewBarkWarpTileIDs` 中；自动触发存在风险。
- `ExtraWarpCheck` 没有明确的 `JOHTO` 与 Route15 同机制分支，不能据此声称已复制原生门逻辑。
- 室内现用 13 种 Gold 图块在所比对 RPP gate 图块集中没有严格像素匹配，禁止直接复用旧 GATE。脚本会为这 13 种图块生成**隔离的 Gold 原图候选图块集**；新 tileset 的注册、图形 VRAM、调色、碰撞和 ROM 空间仍必须另外审核。
- 曾有 `johto_gate_audit.py` 将 `.152` 的 `$40` 逻辑当成预期；那是历史基线检查，**不作为本工具链的门口行为验收依据**。

## 验收策略

静态：尺寸、文件解析、目标编号、相互映射、图块索引、证据分级、补丁正反应用、原脚本回归。

动态（需要未来游戏内实测）：两侧门外一格可停留；正确朝向进门；进门立即反向出门；出门立即反向进门；门旁误触发；旧地图/飞空回归。

**`import_allowed=false` 表示当前只生成审核材料，不能视为移植已经完成。**这份工具链不会抢先更改 `.156` 的进出门和室内样式。

## 工具链下一轮：门型参考、成对回门与报告防过期（仅脚本）

- `johto_warp_reference_profiles.py` 读取不同 RPP 室内/门房的边缘入口布局；不再把 Route15 的固定坐标当作所有房间的坐标。只比较入口形状，不证明游戏引擎行为相同。
- `johto_bidirectional_warp_validator.py` 默认要求双口 Gate **精确反向 Warp 编号**；仅检查传回原地图是不够的。普通房屋确实共用落点时可使用 `--allow-shared-landing`，但不适合双口 Gate，且永远不自动标记实机验收通过。
- `johto_indoor_manifest.py` 为离线报告及源文件生成 SHA-256 指纹。代码、布局、图块、碰撞或报告变化后，核验报错；不能继续使用过期检查结论。
- `johto_indoor_pipeline.py` 支持 `--reference-room` 选择已存在的 RPP 样板，统一输出 `07_source_manifest.json`。未匹配的室内图块、碰撞、注册和真实操控仍是独立阻断项。

示例（所有产物必须输出到**两套源码外**）：

```sh
python tools/johto_indoor_pipeline.py \
  --rpp /path/to/rpp --gold /path/to/pokegold-master \
  --output /tmp/johto-gate-audit --reference-room Route15Gate1F

python tools/johto_indoor_manifest.py \
  --rpp /path/to/rpp --gold /path/to/pokegold-master \
  --output /tmp/johto-gate-audit
```

与历史脚本 `johto_gate_audit.py` 的 `$40` 预期断开：旧规则属于历史问题复现，不能作为新工具的合格条件。未来游戏内修复与图像资源正式入库要另起功能补丁，**这份工具链不改变游戏运行表现**。

## TOOLS.003 · 碰撞、资源预算和地图登记审核（纯工具）

- `johto_indoor_collision_adapter.py` 不再只列出 `FLOOR/WALL` 标签，逐一对照 Gold 的 4 个 16×16 象限与 RPP 的 8×8 可通行白名单。输出 `MATCH / MISMATCH / MIXED_REVIEW / SPECIAL_REVIEW`，记录原生门框、地毯等特殊行为尚未证实。**像素匹配也不代表碰撞匹配。**
- `johto_indoor_resource_budget.py` 输出 Gold 使用的区块、独立 8×8 图块、候选块表大小、RPP 现有 Atlas 和调色配置证据。ROM Bank 剩余空间、VRAM 载入和游戏内调色无法从现有资料可靠推定，字段保留 `null`，阻止自动导入。
- `johto_indoor_registration_generator.py` 对实际 `.asm` include、块引用、对象表、尺寸、区域 ID、Header 指针和 Bank 做逐项静态检查。缺引用或布局尺寸错误都标为 `REGISTRATION_REQUIRED`，不会擅自分配新的 map ID。
- `johto_indoor_pipeline.py` 增加 `08_resource_budget.json` 和 `RESOURCE_BUDGET_UNVERIFIED` 阻断项；所有报告仍由 `07_source_manifest.json` 绑定源码指纹。
- 故意改坏映射/注册的负向用例要报错或 FAIL；不能用“没有触发异常”替代实际验收。游戏代码、Warp、碰撞运行路径和版本号一概不变。

**本阶段提交条件**：新增工具单元测试通过、原 70 项测试回归通过、产物可离线复现、补丁可正反应用且只触及 `tools/`。这些条件不意味着进出门功能已经修复；也不意味着允许自动导入 Gold 图块。

## TOOLS.004 · 图形压缩、VRAM 加载窗口与调色引用证据（纯工具）

- 独立 Gold 室内候选同时对 **32×32 区块**和 **8×8 原图图块 ID** 重编号。重新生成隔离 PNG、`.bst`、`.blk`，逐 tile 验证 RGBA 字节与 Gold 原图一致；仅在 Gold 使用严格四阶灰度时另产逐像素回读验证的、填充到既有加载窗口的 `.fixed96.2bpp`（无任何 ASM 引用）。不修改 RPP 的 `GATE` 文件。
- `johto_indoor_palette_vram_audit.py` 从 `home/overworld.asm` 实际 `LoadTilesetTilePatternData` 取得固定图形复制字节数，从 `constants/tilesets.asm`、`data/tileset_headers.asm`、`main.asm` 追溯现有图形和区块资源，再检查 `color/data/map_palette_assignments.asm` 的引用与 `tilepal` 表结构。证据冲突就明确失败。
- `09_palette_vram.json` 报告候选 8×8 图块是否能落在 **固定加载窗口**，并明确：可容纳 ≠ RPP 还有空闲 VRAM 或 ROM Bank，表项数对齐 ≠ Gold 色彩转换完成。**新 Tileset 注册、调色映射、碰撞、ROM Bank/图形编码及运行时验证仍为阻断项。**
- `07_source_manifest.json` 将上述解析器与关键 RPP 载入/调色源文件纳入指纹。报告源头变化，原验证不能复用。
- 所有这些文件都是离线脚本和产物，不改游戏代码、版本号、不编译 ROM。

## TOOLS.005 · 多房间批处理、逐格候选映射与人工配置证据（纯工具）

- 新增 `johto_indoor_batch.py`：读取严格 JSON manifest，每批 1～32 张地图，独立运行每个室内的完整工具链；名字只能包含英文数字和下划线，拒绝目录穿越、重复任务和含糊的配置。各房间离线输出互不覆盖。
- 新增 `johto_indoor_conversion_plan.py`：逐区块保留 Gold 原碰撞四象限、像素完全一致的 RPP 备选区块、普通碰撞完全匹配的子集；导出隔离 PNG 图块 ID 对应表及**未授权**的调色选择槽位。`selected_rpp_block_id` 只有属于已证实普通碰撞候选才通过结构检查；Gold 特殊门框一律需要人工映射。
- `10_conversion_plan.json`：可供后续人工审核的参数化方案；`11_conversion_plan_validation.json`：仅验证方案与来源一致、索引在范围内和调色符号已知。**结构检查通过绝不代表运行时正确或允许移植。**
- 新脚本纳入 `07_source_manifest.json` 源代码指纹；报告中的新 JSON 也绑定指纹，修改后必须重新验。
- 原 `.156` 游戏文件不修改；进门提前一格、立即反向出门、飞空回归都必须未来实机测试；`import_allowed=false` 是硬约束。

批量输入示例：

```json
{
  "schema": "johto-indoor-batch-v1",
  "jobs": [{
    "id": "gate31", "gold_room": "Route31VioletGate",
    "rpp_room": "JohtoRoute31VioletGate",
    "outdoor": ["JohtoVioletCity", "JohtoRoute31"],
    "gold_tileset": "gate", "rpp_tileset": "gate",
    "reference_room": "Route15Gate1F", "strict_pairs": true
  }]
}
```

```sh
python tools/johto_indoor_batch.py --rpp /path/to/rpp --gold /path/to/gold \
  --manifest /path/to/batch.json --output /path/to/new_empty_external_output
```

批处理模式要求目标 RPP 房间**已经注册**，不支持自动创造新的地图编号。尚缺引擎运行期碰撞、真正的 ROM 空间、彩色调色一致性、实际进出门验证；不得将配置校验误认为可直接装入 ROM。

## TOOLS.006 · 纯工具提交前离线回归闸门

- 新增 `johto_indoor_release_audit.py`，对**两套完整源码**执行全套 `tools/tests/test_johto*.py` 测试、两轮隔离的转换审核、输出 SHA-256 一致性核验、报告篡改负例、自有源码前后只读性检查。
- 默认以 `Route15Gate1F` 与 `Route11Gate1F` 分别作为 RPP 门型参照审核**同一张** Gold `Route31VioletGate`。另外静态对照 Route16、Route18 的门型。**这些并不是四张 Gold 室内都已移植，更不是对进出门手感的实机保证。**
- `release_audit.json` 中的 `tool_commit_candidate=true`（或 `status=TOOL_ONLY_READY_FOR_GIT_REVIEW`）只代表**可以审核一次只含工具的 Git 提交**；运行时 Warp、门外停留、立即反向进出、碰撞、调色、ROM Bank 等均未证实，`gameplay_integration_ready=false`、`import_allowed=false` 必须保持。
- 脚本与回归测试源码一并纳入转换结果指纹。只要修改来源或报告，需重新运行。`--skip-tests` 用于诊断，**永远不能通过提交闸门**。
- 全流程不写游戏源码、不编译 ROM、不执行 `git commit`。输出目录必须全新、与两套源码完全分离。

```sh
python -B tools/johto_indoor_release_audit.py \
  --rpp /path/to/rpp --gold /path/to/pokegold-master \
  --output /path/to/new_external_release_audit
```

提交前还须复核**补丁范围仅 tools/**、原文件权限、增量/全量正反应用，并确认游戏版本 `GT-5.62.156` 没变。通关后仅建议独立的**纯脚本提交**，不把现实关卡的问题标成修复完成。

## 重要：地图外围区块与室内 `.blk` 是两套编号（TOOLS.BORDER）

- 原 `JohtoRoute31VioletGateObject` 的 `db $0a` 来自旧 RPP GATE，不能在 Gold 区块重编号后继续沿用。否则地图边缘会重复显示墙面/地板。
- `johto_indoor_tiles_converter.py` 现在在隔离候选里额外分配纯黑背景 metatile 和独立 tile ID，报告 `reserved_black_border_block_id`、`reserved_black_border_tile_id`。原室内 `used_compacted_blocks` 统计不变，外围不计入 Gold 房间自身的区块数。
- 已注册的 RPP Tileset 须用 `johto_indoor_border_adapter.py` 执行二阶段适配；会检查目标 `tilecoll`、调色图块窗口、全部内部纹理/碰撞编号，并且将黑色填充块放在现有 `.bst` **末尾**，不重排室内已验收的区块。
- 工具只往隔离目录输出 3 个源文件和包含外围的预览/报告；不会直接修改 RPP、不会生成被 `.gitignore` 排除的 `.2bpp`，也不会声称游戏内已经验收。
- 用法：`python tools/johto_indoor_border_adapter.py --rpp /path/to/rpp159 --output /path/to/new_empty_output`
- 未来扩展到其他房间必须传对应 `--room`、`--tileset`、`--collision`、`--map-width`；不可假设所有房间的 border ID、白名单相同。
