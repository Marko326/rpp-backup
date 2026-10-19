## ILEX-5.62.223 正式工具交接｜连接条带与可达视野必须同时审核

本轮完整说明见 `docs/JOHTO_CONNECTION_VISUAL_223_CLOSEOUT.md`。以项目最新被确认的 `.218/396d2ce1` 为 Git 基线，本次 `.219～.223` 仍待用户提交；当前工具仅做离线验证，不编译 ROM。

**正式门禁命令（从项目根目录执行，并指向完整原版 Gold）：**

```sh
python3 tools/johto_rpp_connection_guard.py --project . --gold-root /path/to/pokegold-master --all-active
JOHTO_GOLD_SOURCE=/path/to/pokegold-master JOHTO_GOLD_ROOT=/path/to/pokegold-master python3 tools/johto_map_release_audit.py --rpp . --gold /path/to/pokegold-master --expect-version ILEX-5.62.223
```

**不能只跑连接检查器的 unittest，也不能只指定一条 `--edge`**。当前真实激活 Header 20 个连接方向全量检查：Gold 方向和 offset、3行条带实际源/WRAM读写范围、落点、Bank。未解析/未登记/越界一律 FAIL。单测中的负向注入只是证明检查器会拒绝坏配置，不替代实际工程的 `--all-active`。

**本次最重要的误区**：Gold 通行重叠的10列正确，仍可能因为玩家在窄地图右边可达的入口看到邻图第11～13列而显示默认 `$05` 树林。只有真实可到达的出口+Gold碰撞+RPP边界fence支持的北向右侧视野缺口，才登记 `north_connection_visual_right_border`（0～3）；多复制的列纯显示、不放开碰撞。Route35 north→Route36、Route32 north→Violet City 各需要3列；对其它连接不要机械添加。

**覆盖边界**：当前北向右侧显示合同不是南向／东西向／左侧／镜头偏移／特殊 Warp 的完整证明；对未来 Route37 等新图仍须重新计算合法入口与屏幕可见范围。Gold 全量素材 `SafariZoneBeta` 的旧失败按用户指示保留，不能误称发布门禁 PASS。此次重跑 `534/534 unittest PASS, 0 skip`、启用连接 `20/20 PASS`，用户视频反馈仅支持已观察范围的画面改善，没有 .223 ROM/MAP 空间安全证明。

---

## CONN-5.62.222｜南北地图交界画面额外列

`--all-active` 除可通行 Gold 重叠外，还从 `tools/johto_native_maps.json` 读取每图可选的 `north_connection_visual_right_border`（0～3）。当窄图合法出口靠近右边、视野能看到宽邻图的右侧额外图块时，允许在现成 WRAM 右侧三列缓存补绘真实来源，**不增加可走的边界格**。工具逐行验证来源、目标均在各自范围，少拷贝、过度扩宽或漏登记都会 FAIL。Route35 north → Route36 本轮检查 10+3=13；其它已启用连接按原合同保留。

## CONN-5.62.221｜地图连接全量强制门禁（开发候选）

**必须运行** `python tools/johto_rpp_connection_guard.py --project . --gold-root /path/to/pokegold-master --all-active`。它由当前 `tools/johto_native_maps.json` 注册地图 Header 自动发现全部启用的方向，不再依赖人工枚举 `--edge`。Gold offset 与 RPP 的宏/自定义连接记录分别还原实际读写，验证每条记录、边界、双向已启用的方向和运行时相邻地图的 ROM Bank；发现遗漏、解析失败或任意 FAIL 时退出码为 2。`--edge` 只用于局部定位，不可替代全量检查。

`make johto-map-audit JOHTO_GOLD_SOURCE=/path/to/pokegold-master` / `tools/johto_map_release_audit.py` 同样在执行测试前强制调用 `audit_all_active()`；测试正确不代表实际工程连接正确。此检查**不编译 ROM、不证明上下滚屏 VRAM 逐帧效果**。`.220` 用户视频所示 35↔36 纵向残影仍须实机验证及进一步定位。

## Gold 全编号图块集资源索引前置审核（P3 工具候选，未收口）

在现有 `johto_map_release_audit.py` 中接入 `johto_tileset_index_audit.py`：
从 `constants/tilesets.asm` 和真实 `tileset` 宏审查所有已登记图块集（本阶段 33 个 ID）。
确认 Header 12B、MapPaletteSets 8B、MapPaletteAssignments 96B 三种表项数量及宏展开宽度，
并对相应 `LoadTilesetHeader` / `LoadTilesetPalette` 汇编的受支持指令逐步模拟索引。
所有当前 ID 0–32 均须与预期偏移一致，额外计算较高 ID 63/127/255 的**纯算术**，
以拦截高字节进位丢失，不假定这些未来编号存在实际美术资源。

此审计会在删除表项、意外更改宏展开长度、破坏索引进位或 96B 调色布局时 FAIL；
遇到不支持的新汇编指令会拒绝，而非默认通过。当前完整 Gold 全集仍有
`SafariZoneBeta` `$FF` 图形问题，所以**457 项 unittest PASS，整体门禁 FAIL**。
这只是源码算术和数据形状检查，**不证明运行时 VRAM/Bank 余量、ROM 链接或手机画面**。
工具层改动不改变游戏版本 `ILEX-5.62.204`、地图素材及玩家行为；
待完整准入与必要的用户验收后再进行 TODO/踩坑/提交日志“三件套”正式收口。

## 新做门房的强制入口（GATE-5.62.202 正式收口）

**先读 `docs/JOHTO_GATEHOUSE_READ_FIRST.md`**，再维护 `tools/johto_door_contracts.json`。`GATE_INDOOR` 必须登记 8 类实际执行的源码回归测试、地点提示/Gold RGB/关东隔离，以及手机进出与视觉状态；缺项门禁 FAIL。已验收图块不得因错误的排序来源测试误改。详见 `docs/JOHTO_GOLD_DOOR_GATE_POLICY.md`。


## ILEX-P15｜Gold Collision 长表处理与桐树林离线候选

Gold 图形区块数量与碰撞条目数量不必相等（`TILESET_FOREST` 是 40 个 metatile / 64 条碰撞规则）。`johto_rpp_pipeline.py --gold-map IlexForest` 已使用通用转换器处理这一合法输入，仍然对缺失碰撞规则、图块索引越界和超过96图像槽位保持失败；这不产生可玩地图，也不会自动放行 Forest 特殊 Warp、Jump、Cut、Surf 或剧情。新强制 Gold 测试中包含将 64 条截成 39 条的错误注入；Gold 南门房与桧皮镇/森林两端原版 Warp 编号的精确核对见 `docs/JOHTO_ILEX_P15_GOLD_STAGING.md`。

## MAP-5.62.194 工具收口 P10｜当前有效目录与通用几何检查

- 游戏用的 Route33 54 字节逐格碰撞掩码现在位于 `maps/JohtoRoute33.blocked_mask.bin`，
  `engine/overworld/johto_route33_collision.asm` 的 `INCBIN` 已同步迁移；不再依赖 `tools/` 下的阶段暂存目录。
- `tools/johto_route33_geometry190.py` 及其专用测试、过时的 `Route33.geometry.json`
  已撤下。使用原有 `johto_indoor_collision_adapter.plan_gold_quadrant_collision`
  和 `audit_reviewed_geometry`，地图差异放在 `tools/johto_gold_geometry_contracts.json`。
  严格门禁仍验证 Gold 精确掩码、碰撞角色、混用图像 ID、洞口阻挡、七处跳崖及负向注入。
- `johto_route33_runtime191.py` 与 `johto_union_cave_exit192_audit.py` 仍检查跨图块集切换、
  白闪、Warp 触发、Dig/逃洞绳来源返程等真实调用合同；当前通用转换工具尚不能替代。
- 本文下方 `.189/.190/.191/P03/P07` 文字是阶段历史；包含已移走路径的旧段落
  不再作为当前构建路径或待执行命令。当前目录审查见 `docs/JOHTO_TOOL_LAYOUT_P10.md`。

## P03 audit simplification after MAP-5.62.194 (tool-only candidate)

- Retire the standalone `johto_route33_staging_audit.py` and its nine
  `test_johto_route33_staging189.py` tests. The reviewed Route33 sources are
  already checked by `johto_route33_runtime191.py`, the Gold 16x16 geometry
  gate, the Gold door inventory and the Union Cave exit192 gate. Unique Gold
  map metadata and sign assertions now live in the existing runtime191 audit
  with negative tests. No active negative safeguard is intentionally dropped.
- The old `.189` source-stage files remain for historical traceability, but
  are not separately re-audited against Gold on every release. Runtime assets
  still undergo exact Gold comparisons. The Route33 54-byte collision mask is a real ASM `INCBIN` dependency; the P10 current path is `maps/JohtoRoute33.blocked_mask.bin`.
- The `.189` historical documentation farther below describes the audit as it
  ran **at that time**; it is superseded by this P03 maintenance note. The
  aggregate suite count is expected to decrease when duplicate tests retire;
  rely on the manifest + zero skips + negative tests, not a historical count.

## MAP-5.62.194 tool refactor candidate (no game behavior changes)

- `johto_gold_cells.py` is a **shared source decoder**, not a new runtime
  collision engine or another parallel gate. The Route33 staging, geometry,
  and runtime audits reuse its Gold 16x16 quadrant/graphic parsing. Map-specific
  alias, grass, hops, door and return assertions remain in their original gates.
- `johto_native_maps.json` records Route33 `warp=ALLOWED` because its reviewed
  cave mouth is currently active. This flag does **not** approve new exits.
  `fly` describes a destination rather than ability to start Fly outdoors.
  The door gate rejects a `FORBIDDEN` capability with an actual enabled Warp.
- The geometry190 JSON is a historical **offline phase snapshot**. Its
  `runtime_registered=false` and closed route assertions do not describe the
  current `.194` feature state. The P10 layout moved the still-required 54-byte `INCBIN` mask into `maps/`.
- The newly added decoder/contract unit tests can run without Gold, but the
  strict release gate still requires independent full Gold, no skips, and a
  later user Termux build/phone test. No new game version or ROM logic change.

## MAP-5.62.192｜Union Cave 第二洞口已开放的门禁合同

当前实际游戏版本 `MAP-5.62.192`，用完整 Gold 参考树从 RPP 根运行：

```sh
PYTHONDONTWRITEBYTECODE=1 python3 tools/johto_map_release_audit.py --rpp . --gold /path/to/pokegold-master --expect-version MAP-5.62.192
```

严格要求 337 项、0 fail、0 skip。新 `johto_union_cave_exit192_audit.py` 及 `test_johto_union_cave_exit192.py` 覆盖 Gold 原始 Warp、RPP 两张地图的双向索引、精确洞口入口碰撞、洞内朝下碰撞出口、单步安全落点、保存地区来源三元组、黑屏隔离及故意破坏的反例。不能把 `.191` 阶段“第二洞口必须关闭”的测试恢复。**该门禁不编译 ROM，不证明 Bank 安全，也不代表手机验收。** 以下 `.188` 等旧版命令示例为阶段历史记录。


# Native Johto map audit — DIG-5.62.188 cave escape accepted stage

## Run (no ROM build)

From the RPP project root, with a complete Gold source tree:

```sh
make johto-map-audit JOHTO_GOLD_SOURCE=/path/to/pokegold-master
# equivalent:
python3 tools/johto_map_release_audit.py --rpp . --gold /path/to/pokegold-master --expect-version DIG-5.62.188
```

Exit 0 means: explicit per-local map identity, Route32/Union Cave static Warp
contracts, the 45 Gold Johto landmarks and bike source contracts, required-test
manifest and negative regressions, and zero skipped tests all passed.
**This is not ROM compilation, a frame-accurate engine interpreter, or phone acceptance.**
If Gold is missing, any test is skipped, the suite fails or returns no tests,
the gate fails closed. Run it before applying a new map patch for review.

## Required source contracts and Field Moves preflight

`tools/johto_native_maps.json` and `tools/johto_door_contracts.json` must be
tracked in Git and included in any clean source export. The root `.gitignore`
now exempts these two specific files from its general `*.json` rule. Verify
with `git ls-files -- tools/johto_native_maps.json tools/johto_door_contracts.json`;
if either is missing from Git, explicitly stage the reviewed original with
`git add -f`, then inspect its diff before a separate tool commit.

The strict map gate also runs `tools/johto_field_moves_preflight.py`. Its PASS
means **only** Union Cave 1F and Route32 Surf have reviewed runtime water classification, **and only Union Cave 1F** has reviewed Dig/Escape Rope eligibility. Other Johto cave escapes and water remain **DEFERRED**. The
preflight rejects unexpected allow-list insertions or cave-return widening. Gold
source auditing and phone acceptance are independent: current `.188` has user-reported
Union Cave return acceptance, not a claim of exhaustive all-map runtime coverage. See
`docs/JOHTO_FIELD_MOVES_PREFLIGHT_zh.md`.

## Adding a native map

1. Update `constants/region_map_constants.asm` and all standard mapping tables.
2. Register the new local ID in `tools/johto_native_maps.json` with
   the exact Header pointer/bank, old alias, RBY/GSC music, ordinary Town Map
   marker/name/coordinates, and every `feature_status` field.
3. Use `DEFERRED` (not `ALLOWED`) for unimplemented or unverified features.
   Capability states are **review metadata**, not runtime checks or proof of
   eligibility. Add corresponding behavioral audits for every new enabled
   Warp/bike/field move/Fly path, then verify on hardware.
4. Check Gold asset source, collision/entrance semantics and the ordinary
   Town Map **background** separately. Passing the native Town Map *index*
   check does not prove the static background graphic is correct.
5. Keep new locations unsafe to enter closed until their engine flows pass
   static audit and handset regression.

Fields use `ALLOWED`, `FORBIDDEN`, `DEFERRED`, `NOT_APPLICABLE`; identity evidence
uses `STATIC_PASS`, `GOLD_REFERENCE_PENDING`, `PHONE_PENDING`, `USER_ACCEPTED`.
The 9 native-map identity records originated from `.178`; the `.188` Dig/Rope
routing is a narrow *new* runtime exception for Union Cave 1F only. The
identity registry is reviewed audit metadata, **not** an engine permission gate or
proof that every map geometry has been independently tested on a phone.

## Deliberately retained tools

`johto_rpp_*` tile/connection and `johto_indoor_*` interior tools have distinct
roles and are not deleted. Historical `johto_rpp_ledge_converter.py` remains a
manual/legacy utility; do not run it against an already-converted tileset.
This audit also includes the Gold-backed `.188` single-entrance cave escape
contract and mutation regressions (`test_johto_cave_escape188.py`). The `.188`
strict gate expects **298 tests, 0 errors, 0 skips** with complete Gold sources;
no build is performed and the report does not itself verify phone behavior.
It does not claim all future field-move hooks or maps have executable coverage.

## Route33 Gold-source staging (R33S-5.62.189, not yet playable)

Nine Gold-backed tests (`test_johto_route33_staging189`) and
`tools/johto_route33_staging_audit.py` verify the original 10x9 Route33 layout,
independent `JOHTO_MODERN` art/metatiles, its Gold collision ambiguity, and
fail-closed Route32 south/Union Cave second exit. Exact staging assets are in
`tools/johto_route33_staging/`. The `.189` art snapshots remain offline references, but `geometry190/Route33.blocked_mask.bin` is a **build-time INCBIN dependency** of `engine/overworld/johto_route33_collision.asm`. Do not delete it as unused staging data.
The candidate strict gate runs **307 tests, 0 skips**, provided complete Gold.
The game version intentionally remains `DIG-5.62.188`; this is a preparation
patch, not a released Route33 map. Before registering any Route33 runtime map,
upgrade these staging-only gates to checked new map and connection contracts.

## Route33 Gold 16x16 collision preflight (R33C-5.62.190, OFFLINE ONLY)

`tools/johto_route33_geometry190.py` emits a deterministic 54-byte blocked-cell bitset and seven reviewed directional hops for Gold Route33. It deliberately does **not** add a runtime tileset, graphics/palette loader, map header, new Warp, or map connection. `test_johto_route33_geometry190.py` supplies eight mutation-sensitive checks to the strict gate. See `docs/JOHTO_ROUTE33_GEOMETRY_STAGE_190.md`. A patch containing these artifacts is **NOT playable and requires NO phone test**.

## Route33 grass/Fly regression — MAP-5.62.193

`johto_route33_runtime191.py` also requires Gold Route33's 12 grass quadrants to use 8x8 image `$04` and checks that `JOHTO_MODERN` registers `$04` as `wGrassTile` without adding global collision permissions. It checks the party-menu Fly allowance for `JOHTO_MODERN` while retaining the generic outside-map guard. Three mutation tests detect wrong grass IDs, missing modern Fly permission, and an unsafe universal Fly bypass. This does not enable native Route33 encounters or a Route33 Fly destination.

## 通用新地图接入复核（P07 工具候选，不修改 ROM）

开发新的道路、城镇、洞穴、水域时先运行已有 `johto_rpp_pipeline.py`，
不为地图名称/版本号复制新的 Gold 区块解析或碰撞计算脚本：

```sh
# Gold-only：还没有把地图接进 RPP 时，只生成独立候选及待核对清单
python3 tools/johto_rpp_pipeline.py --project . --gold-root /path/to/pokegold-master \
  --gold-map Route34 --output /tmp/rpp-route34-review

# 已接入地图：再核对真实的 RPP 登记、地区/局部 ID、Warp 数量与既有门口合同
python3 tools/johto_rpp_pipeline.py --project . --gold-root /path/to/pokegold-master \
  --gold-map Route33 --rpp-map JohtoRoute33 --output /tmp/rpp-route33-review
```

新输出 `rpp_integration_review.json` 只证明 **静态登记结构及现有门口合同**，
不会将 `feature_status`（尤其 `fly` 目的地状态）误当成引擎运行许可。
`REGISTRATION_REQUIRED` / `STRUCTURAL_ERRORS` 需先纠正；即使显示
`STATIC_STRUCTURE_PRESENT_REVIEW_RUNTIME` 也仍须跑原有 Surf、Dig／逃洞绳、
Warp、地图连接与 Field Moves 的专门审计和错误注入。`--rpp-map` 必须是
真实 RPP 地图名，不是统一的 `$FC` 兼容句柄。Gold-only 清单始终是候选，
不能自动授权技能、开放道路、生成可直接包含的 ASM 或声称构建通过。

### 33号道路专用工具的保留和去重边界

- 原有 `johto_indoor_collision_adapter.plan_gold_quadrant_collision` 现由
  `johto_route33_geometry190.generate` 复用；后者只保留已验收的 Route33
  精确数量/坐标/碰撞角色及错误注入合同，不再自写掩码/跳崖计算循环。
  将来新地图应直接使用公共转换器，而不是复制 `geometry190.py`。
- `johto_route33_runtime191.py`、`johto_union_cave_exit192_audit.py` 仍检查
  跨 tileset 切换、白闪回归、两个洞口的方向/落点/技能返回等**特有的运行时约束**。
  在原有统一门禁拥有等价的通用错误注入之前不可删除。
- `tools/johto_route33_staging/` 中原先重复存放的 Route33 `.blk`、现代
  `.bst` 和 PNG 源文件副本已清理，正式地图资源和 Gold 原版是审计依据。
  P10 将真实 `INCBIN` 数据迁至 `maps/JohtoRoute33.blocked_mask.bin`；旧暂存路径已经删除。
- 没有 `PROJECT_DELIVERY_RULES.md` 的本次 ZIP 以实际提供的
  `RPP_PROJECT_CONTEXT/03_PROJECT_REQUIREMENTS.txt` 为交付规范依据，
  不补造不存在的规则文件。

## Gold 飞空目的地通用强制准入（FLY-5.62.196 / P13）

统一 `make johto-map-audit JOHTO_GOLD_SOURCE=/完整/pokegold-master` 现包括
`johto_fly_destination_audit.py` 和对应 15 个反向/正向用例。它同时读取
Gold `data/maps/flypoints.asm`、`data/maps/spawn_points.asm`、`data/maps/landmarks.asm`，
不再只认 Fly 的室外使用许可或 Town Map 地标。`tools/johto_native_maps.json`
每张地图有 `gold_fly_landmark` 字段（不能遗漏），Gold 提供飞空点的已注册
实体需要 `fly=ALLOWED` 及真实菜单、wEventFlags 到访、目标 selector/地区与
局部地图编号、实际落点和图块集恢复。城市局部 ID 扩充后必须扩展统一审计的
`REVIEWED` 合同，不能在新城市图块完成后仍靠老测试的 PASS 视作功能齐全。
独立运行：

```sh
python3 tools/johto_fly_destination_audit.py --rpp . --gold /完整/pokegold-master
```

这属于静态、按当前引擎写法检查的合同，不是模拟器/链接器。P13 收口重跑
380 PASS / 0 FAIL / 0 SKIP，15 项 Fly 独立反向测试全通过。用户仅提供
「看过了，没啥问题」整体反馈，尚无逐项游戏测试记录；未执行 ROM 构建或
Git 提交，跨地区异常、旧档全量恢复等仍需实测时保留观察。

## Reconstructed full-source coverage gate (source-only; no ROM build)

`python3 tools/johto_rpp_pipeline.py --project . --gold-root /path/to/pokegold-master --output /tmp/gold-full-check --full-gold-corpus` enumerates **all** registered Gold maps and portal-adjacent candidate movement edges. A returned `SOURCE_GEOMETRY_OK_RUNTIME_UNVERIFIED` status is not gameplay approval. The strict `johto_map_release_audit.py` now refuses release while any Gold map has an unresolved source data conversion failure.

### Reconstructed P2: masked movement source-branch check

`tools/johto_masked_step_audit.py` executes a small, explicitly supported subset of the existing RPP ASM caller branch operations and checks their shared bit mask. Unknown opcodes fail. Only 3 already connected native maps and 11 source movement edges are currently in scope; the other maps are **not tested**. The known Forest `(3,41) DOWN -> (3,42)` is blocked and correctly makes the strict gate fail. The special directional cave requires review rather than forced bidirectional passage. This is source-level branch tracing, **not** an RGBDS/GB runtime interpreter or actual gameplay proof.
