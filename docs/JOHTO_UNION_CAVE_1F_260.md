## FIX-261 编译阻断修复补充（待本机确认）

CAV-260 虽在活动注册中包含 UnionCave1F 槽位13，但 `JohtoActiveGSCMusic` 表曾漏掉相应第14字节，因此主工程在 `engine/menu/options_menu.asm:1232` 因表长 ASSERT 中止。FIX-261 按 Gold `data/maps/maps.asm` 中 `UnionCave1F ... MUSIC_UNION_CAVE` 补上 `MUSIC_GBP_GSC_UNION_CAVE`，保留原来的表长 ASSERT。独立 `johto_table_assert_preflight.py` 已正式纳入项目的迁移审计，之后新增地图若遗漏音乐表应在静态测试阶段失败；本轮仍未本机编译／验收。详见 `docs/JOHTO_TABLE_ASSERT_PREFLIGHT_261.md`。

# UNION-260：联合洞穴 1F 南北闭环首批开发审计

**源码基线**：用户最新完整 `MUS-5.62.259.zip`（不是旧的 `.256` 或 `.253`），正式开发候选 `CAV-5.62.260`；`TEST-231` 不变。

## 本次开放范围

- Gold 原版 `Route32` 洞口 `(x6,y79)` ↔ `UnionCave1F` 洞内出口 `(x17,y3)`；旧 Route32 的南侧遗迹双车道及冲浪保留。
- 洞内地图使用稳定 ID `8`，新增活动槽位 `13`（总计14张），不改前13张编号；原版 Gold 的 `UnionCave1F.gold.blk` 与运行 `UnionCave1F.runtime.blk` 分别保存，不能误把旧 NPC compact 图作为原版 Gold 数据。
- 采用旧参考分支专属洞穴图块 `johto_union_cave`，独立 Blockset、PNG、ROM0 tilecoll 和 palette，不能套用城都野外或关都洞穴的图块白名单。
- 玩家向上进入 DOOR，传送到目标入口后向下自动行走一格。必须严格限定地图、坐标、方向；不能让其他洞穴瓦片自动跳转。
- Gold `UnionCave1F` 的64个 WATER碰撞坐标逐格登记；新洞穴 Tileset 的游泳中继续移动／上岸必须继续走 Gold 水格与真实岸线判定。野外的 Surf、Cut、跳崖不重写。
- 地点名称使用 `Union Cave`，Town Map 金版地标索引9，坐标 `(Y140,X92)`；预留名称弹窗及 Continue 兼容校验。

## 本轮保持关闭

洞穴 `B1F/B2F` 楼梯、1F 南侧通往 Route33 的出口、野怪、训练师、道具、剧情及 Escape Rope 新逻辑本轮不启用；未完成场景必须保持 fail-closed，而不是传到不存在的地图。

## 对照与风险

- Gold `.blk` / 事件 Warp 来源：`REFERENCES/Gold/pokegold-master/maps/UnionCave1F.asm`、`maps/UnionCave1F.blk`、`maps/Route32.asm`。
- 旧 NPC 实现：`REFERENCES/NPC/NPC-5.62.243` 的洞穴图块及 `docs/JOHTO_CAVE_ESCAPE_188.md`（只吸收资源和有效落点约束，拒绝旧地图句柄和 Bank 处理的潜在副作用）。
- 本轮审计：`tools/tests/test_union_cave_260.py`、`tools/johto_pilot_migration_audit.py`、`tools/johto_surf_preflight.py` 以及原有地图／Warp 回归。新增活动地图时要同步更新资源、Header、Town Map 浏览索引、地点栏合同、调色板表和 Warp 路由。
- **静态审核不等于 ROM 链接或手机实测**。用户本机需要确认真实 Bank MAP 空间，正式／TEST 红蓝构建，洞口进出自动一步、洞内 FLOOR 不穿墙、水面上下岸，旧的南北门房与 Continue。

**本阶段仅交付开发补丁**，不生成正式 Git 提交日志，不执行 Git Commit／Push，不自行编译 ROM。
