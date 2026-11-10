- 扩展回归补充：`test_johto_bike_route29_route32_252.py` 旧正则把 ID190 与 Route31 Gate 写成相邻指令，REF-365C 中插入合法的 ID99 分派后误失败；现要求两个精确 ID 分派后才进入原 gate 检查，不开放其他室内图。主迁移审计冻结 REF-338/349 旧地图数和旧封口仍有失败，不能当新代码全绿。
## REF-365C@ 设备反馈修复｜洞内返程自动迈步与烟墨侧自行车（开发测试）
- 用户在 REF-365B 实机确认室外 Route45 进出正常，但同层洞内返程落点不会自动迈步；源码根因是 `JohtoPilotGateArrivalStep` 对 ID190/ID99 一律直接返回，漏判洞内返回目标。现在仅 **ID99 `(3,25)` → ID190 `(17,1)`** 的到达格在 Gold `CAVE` 上自动向下走到安全 `FLOOR (17,2)`；ID190 的 Route31/46 室外入口地毯和 ID99 的 `(3,25)` / `(23,3)` 都不额外移动（ID99 `(3,26)` 是墙，不能照搬）。保留方向限定和不连环 Warp。
- 用户反馈 ID99 无法使用自行车；根因是 `IsBikeRidingAllowed` 外层只分派 ID190，尽管 ROMX `JohtoDarkCaveBikeFloorAllowed349` 已兼容两张地图。已将 **ID99** 加到相同分派；仍仅 Gold FLOOR/合法地毯能上车，水、墙、跳崖和洞口不放行。ROM0/Bank0 未修改；场景走现有洞穴动画保护。
- 维护 `tools/johto_dark_cave_365_audit.py` 的两条实际调用链检查和错误注入测试，原 `test_rom0_relief_349.py` 的旧哈希比对通过剥离两张图专用新增分派恢复历史不变体，避免旧合同误报。使用 `jp z, .gateTop` 避免到达函数增长后潜在 JR 跳转过长。
- **保持不变**：65 张地图／168 条 Warp、31/46/45 室外路由、两个洞内方向触发、Surf/Flash/跳崖/Dig/离洞绳、Rock Smash 技能与碎岩物件延期；无遭遇、NPC、剧情。需要手机重新构建四版、审查 MAP、实测洞内返程和骑车，才可验收。未自行 ROM 编译／Commit／Push。

# REF-365｜Gold 黑暗洞穴双区域同层及 Field Moves（开发候选）

**性质**：2026-11-09 开发期源码及 Gold 静态审计记录；**未执行 RGBDS ROM 链接／GBC 模拟器手机实测，尚未 CLEAN。** 输入：用户上传 `REF-364.zip`。全量补丁从该干净 Git HEAD 基线生成；增量补丁从上次已交付的 REF-365@ 开发候选生成，只有用户实际应用过才适用。两者互斥；不代表已读取真实手机工作区。

## 需求与排除边界

完成黑暗洞穴两张**同一层**地图的地形、洞内/室外入口和已有 Field Moves：Surf（水上、上岸）、Flash（切图后持续）、Bike、跳崖、UP_WALL、Dig、Escape Rope；不做遭遇/钓鱼/NPC/训练家/剧情/道具球/隐藏物品。

**Rock Smash 技能尚不存在，按用户本次要求明确推迟**：不生成 ID190 原版四块石头对象、不替代成 Strength、不实现破石动画和碎岩战斗，不计入本轮验收。不在不具备技能时增加不可通行的伪岩石。原版 `(16,14)/(27,6)/(7,14)/(36,31)` 只保留为将来参考。

## 地图资源与 Warp 触发

- 目前 Gold `DarkCaveVioletEntrance` = Stable ID190 / 40×36 cell / 64 WATER / 26 HOP（12 DOWN、14 LEFT）/ 41 UP_WALL。原有 Route31 与 Route46 外部洞口及现有用户实测行为不改。
- 新增 Gold `DarkCaveBlackthornEntrance` = Stable ID99 / 30×36 cell / **120 WATER、14 HOP、49 UP_WALL**。原 Gold `.blk` 和 role 表按原版逐格重建；这不是 B1F/B2F。显示名与 Town Map 位置独立登记，GFX 共用现有洞穴 tileset，区块源互不共用。
- Gold 1 基 Warp #2：ID190 `(17,1)` CAVE **踩格 STEP_IN** → ID99 `(3,25)`；ID99 `(3,25)` DOWN **地毯朝下碰撞** → ID190 `(17,1)`。到达不能立即反复循环换图。
- Gold 1 基 Warp #1：ID99 `(23,3)` DOWN 地毯 ↔ Route45 `(2,5)` 朝北 **撞门入洞**，出洞自动向南一步到 `(2,6)`。Route31、Route46 同类通路保持。
- Gold 5 个内部 Warp 以及三条外部口，现行注册为总 **168 条方向路由**（原 164 + 4）；活动 **65** 张（原 64 + 1）。RPP 运行 0 基 ordinal 不得压缩：ID190 0/1/2；ID99 0/1。

## 场地技能与存档

- 按 `wCurLocalMapID` 选择 40×36 或 30×36 role-grid；水域/上岸/向左、向下两步跳崖/方向墙等均按各自 Gold 格子。现有移动/Surf/场景精灵路径不应受到另一图的尺寸影响。
- Flash 暗场与被照亮状态切图保留 `wMapPalOffset`，进入任一侧户外新入口初始黑暗；旧 Kanto Rock Tunnel 不变。骑车允许已有洞穴地板/门毯，其他地形拒绝。
- Dig／Escape Rope：从 Route31／46／45 **户外入口**进入后写入 `wEventFlags` 原本未使用的 EVENT_9D6/9D7 两位，洞内互换不改来源；使用后将 SPECIAL Warp 的地图、坐标、视口数据送回相应的户外安全格 `(34,6)/(14,6)/(2,6)`，而不是旧版上次治疗中心。旧存档无有效入口锚点拒绝使用；保留已有其他地图与关都的路线；不新增 WRAM/存档字节。

## 验证现状与限制

- **源码静态已验证**：`python tools/johto_dark_cave_365_audit.py --root .`；若有原版 Gold 目录可传 `--gold-root <pokegold-master>` 逐格重新对照 `.blk`，黑暗洞穴 5 个 Gold Warp/8 个方向记录、65 图/168 Warp、两图 Water/HOP、Flash/Bike/出洞锚点检查。
- 另使用 `python tools/johto_table_assert_preflight.py --root .` 核对三张按 slot 的活动表，以及 `python tools/johto_map_name_sign_audit.py --project .` 检查地图名称。
- `python tools/validate_current_project.py --skip-pytest` 中 ASM 局部符号检查已通过，但后续**旧版主迁移审计仍固定 64／164、封闭第三入口等历史合同，会报失败**，未将其隐藏或假称通过。旧 Stage2/Surf Manifest 测试也需另起审计维护，独立 REF-365 审计不等于它们通过。
- **无 RGBDS 0.5.2，不能声明 ROM 构建/链接、MAP 空间、Red/Blue/TEST Red/TEST Blue 或手机已通过。** 尤其 ROM0 旧 MAP 只剩 126B，REF-365 有新 ASM，不得沿用旧 MAP 的余量。

## 用户手机验收清单（必须实际操作）

1. 确认 `git status`，选与工作区匹配的**唯一**补丁，先 `git apply --check`；安装后检查 `REF-365A@`。开发包外层 ZIP 严格只有两份补丁，不附完整源码 ZIP、安装文档或正式提交日志。不先 Commit。
2. 用要求的 RGBDS 0.5.2 编译 Red/Blue/TEST Red/TEST Blue 四种配置，保留新 MAP；逐一检查 ROM0≥64B、Bank `$03/$04/$0F` 等余量、跨 Bank 标签及文件长度 ASSERT。
3. 分别 Route31、Route46、Route45 朝北进洞，朝南出洞，确认出生点/出洞自动迈步；每条外口至少进出两轮。
4. Violet `(17,1)` 朝上踩入 ID99 `(3,25)`，返回时在 ID99 地毯按下才退出 ID190；不得左右一碰就飞、落地即循环、按住上方向回弹。再从 Route45 反向走到 Route31/46。
5. ID99 的 120 水格、14 个 HOP 起点、49 个方向墙抽查可达场景；ID190 的原 64 水格、26 HOP、两个入口再回归。水中上岸→跳崖、B 跑动／骑车、未 Flash→Flash→切图→继续与保存继续都测。
6. 从 31／46／45 三入口分别进洞，在没有／有穿越内部入口时使用 Dig 与 Escape Rope，应返回**最初进入的路口**而非治疗中心；出洞重新从另一口进入必须更新来源。旧存档无锚点，技能应安全拒绝，不得写坏存档。
7. **本版不检查破石头**：任何 Rock Smash 石头或事件均不应新增。只有设备确认后才能按项目正式 CLEAN 验收/自提交。

## 主要修改点

`constants/region_map_constants.asm`、`data/johto_stable_id_slots.asm`、`data/johto_header_descriptors.asm`、`data/johto_pilot_runtime_assets.asm`、`data/johto_pilot_source_resources.asm`、`data/johto_dark_cave_stage/*`、`maps/johto_pilot/DarkCaveBlackthornEntrance.*`、`engine/johto_dark_cave_stage2.asm`、`engine/overworld/ledges.asm`、`engine/johto_land_collision_gateway_272.asm`、`engine/johto_pilot_runtime.asm`、`data/johto_south_chain_runtime_328.asm`、`data/johto_vertical_gate_runtime_314.asm`、`engine/items/items.asm`、`engine/fly_town_map_helpers.asm`、`engine/menu/options_menu.asm`、`data/game_version.asm`、相关地图名称、静态工具和测试、维护文档。游戏 ASM 与版本均有变化，绝不能当作文档补丁。

## REF-365B 编译失败修复（2026-11-10）

用户在 Termux RGBDS 0.5.2 的 `make red` 实际报错：`engine/johto_dark_cave_stage2.asm(52): syntax error, unexpected hl`。根因是上一版烟墨侧 role-grid 行偏移 `30*y` 使用了 LR35902 不支持的 `sbc hl, de`（只支持 `sbc a, r` 8 位系列）。已改成 `2y -> 4y -> 6y -> 12y -> 24y -> 30y` 的合法 `add hl,hl` / `add hl,de` 指令组合。保留坐标计算结果，不改变两图资源、Warp、Surf、Flash、Dig／离洞绳及 Rock Smash 延期边界。游戏开发版更新为 `REF-365B@`。

**漏检原因与措施**：旧 `tools/johto_dark_cave_365_audit.py` 的 `two_independent_role_tables` 反而要求源码中包含非法 `sbc hl, de`，所以静态审计会错报通过。现替换该要求，新增对源码实际算术指令的白名单解释，枚举所有 30×36 坐标断言偏移为 `30*y+x`；通过错误注入测试验证把非法 `sbc hl, de` 放回去会被拒绝。仍不能替代用户手机 RGBDS 构建／链接、MAP 和设备验证。

**用户下轮复测**：以最新 `REF-365A.patch` 工作区使用 REF-365B 增量补丁，运行 `make red`；若继续发现新汇编／链接错误，请完整导出新日志与当前工作区补丁。不要因为本轮静态 PASS 就跳过四版 ROM／MAP 与黑暗洞穴实际往返。
