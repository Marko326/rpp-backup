> **跨分支历史说明**：以下为金币分支 `.218` 首次接入 Route36 的原始阶段记录。该阶段“Route35 尚封闭”“下一步开发 35 号路”与现在的金银整合 `.223` **不同**：Route35 已接入、Route36 南口 x17 已双向开放，满金 local ID 15 已保留。用户原金币 `.218` 手机反馈不等于本合并 ROM 的实机验证。项目当前状态请先读 `docs/JOHTO_CONNECTION_VISUAL_223_CLOSEOUT.md` 和 `TODO.md`。

# ILEX-5.62.218｜36号道路 Gold 对照、问题收口与后续交接

本文件记录从原始干净 `.215` ZIP（RPP 导出 HEAD `030081058a94f95fccf35c57f9c9301725c565c5`）到正式 `.218` 的累计未提交差异；这不是已提交或可直接用来证明实机完整验收的记录。本轮用户要求只做 36号路，未开始其它地图；应用正式收口补丁后由用户自行决定 Git 提交。

## Gold 核对与代码有效状态

- Gold `Route36.blk`：30×9=270 字节，RPP `maps/JohtoRoute36.blk` 逐字节相同；地图使用 Gold `TILESET_JOHTO`，RPP 复用已有 `JOHTO`，不新建图形表。27 种实际使用的 32×32 metatile，其 Gold 和 RPP *相同 ID* 的原始16字节定义、由双方各自 PNG 8×8 组装的 32×32 RGBA 像素全部一致（27/27）。完整 `johto.bst` 因其它地图扩展而比 Gold metatile 表更长，**整份文件不相同**；不可据此否定这条路的已用27种图块匹配，也不可宣称通用全图块集字节相同。
- Gold 地格 collision 经已有 `johto_indoor_collision_adapter.plan_gold_quadrant_collision` 计算为 60×18、144 字节 mask，阻挡810、可走270；RPP mask 字节相同；此地图 Gold 没有跳崖候选。门房 carpet 对应 special cells `(18,8),(18,9),(47,13),(48,13),(47,17)` 保留隔离。
- 唯一正式打开的双向连接为 Route36 东缘 ↔ 桔梗市西缘 y8/9，Gold 偏移0、条带长9。`tools/johto_rpp_connection_guard.py` 两向审核通过。两张相邻地图保持在 `JOHTO_ROM_BANK`，因为旧引擎 `LoadTileBlockMap` 的邻边条带依赖当前 Bank；`.216` 把 Route36 单独放 Bank `$44` 曾导致玩家看到建筑/水面杂图，`.217` 修复，正式 `.218` 保留并在原测试文件防回归。
- Gold Route36 原有四个 warp 格指向两座门房；因为门房尚未独立移植与方向审计，当前对象 Warp 数为0，并保留地形封口。Route35/37 北南连接也封口，不添加不能回程的 Warp。
- Gold 原版有7个 object，包括 `(35,9)` 的 `SPRITE_WEIRD_TREE`（带 Squirtbottle/战斗/事件标志），并非静态 `SPRITE_SUDOWOODO`。`.216/.217` 的错误替身在手机上显示为胖人；`.218` 根据用户要求将其移除、对象数改为0、清理悬空说明文本，原地格在 Gold 碰撞中本可走，现在不再有 NPC 挡住，供走图/金手指。保留4处 Gold 路牌坐标，**文案不是逐句原版**。未移植训练家、树果、星期 NPC、怪物对战、完整剧情及野生分布。
- 保留 Gold 36号路音乐归属和 Town Map 地标；不改变 Route32、Route33、Ilex Forest 的跳崖/Surf/Cut、已验收门房或关东逻辑；不以原 `SPRITE_SUDOWOODO` 或替身恢复障碍。

## 玩家反馈及静态证据边界

- `.216`：玩家 Gold/RPP 截图发现左侧杂图；修正到 `.217` 同 Bank 后，玩家随后反馈胡说树图形不对。
- `.218`：玩家最新称“感觉没啥问题”，并要求重新与 Gold 核对及清理。保守记录为**用户已观察到的正常走图与画面没有明显问题**，不外推两行出口反复切换、每一格边界、所有菜单与旧存档等逐项均已测过。
- 完整 Gold 源码下原项目 unittest **518 项通过、0 失败、0 跳过**；统一 `johto_map_release_audit.py` 仅在已知 `SafariZoneBeta` Gold 全语料素材窗口报 FAIL（Gold 367/368 通过），该历史项按用户要求不作为 Route36 阻塞。静态符号／指针及补丁正反应用、字节/权限核对由本次交付独立检查；**AI 不编译、不链接 ROM**，没有最新 `.218` MAP／空间证明、完整所有剧情的手机验收。`SafariZoneBeta` 是本轮明确排除的历史独立问题，不阻拦 Route36 本阶段收口，也不写成全量 release audit PASS。

## 最小手机回归与下一阶段

1. 桔梗市西侧 y8/9 两格往返各两次；从两个方向进入的树林边缘、音乐和加载后图像均无串图。
2. 走到 `(35,9)` 原胡说树所在区域确认不会显示胖人／自动战斗／无法通过；南北其余封闭道路和自然公园／阿露福遗迹门房 carpet 不会误入空地图。
3. 抽查桔梗市南口 Route32、旧 Route31 门房以及森林北门房的进出未回退；旧存档 Continue、走路/骑车与地标音乐按需抽查。

后续若要做门房，必须先读 `docs/JOHTO_GATEHOUSE_READ_FIRST.md` 并使用原有 `johto_indoor_pipeline.py`、方向合同、落点检查与现成审计；按用户“一次一条路或一个城镇”单独开发，不在本次收口里提前开放。
