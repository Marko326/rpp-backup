# 桧皮镇 Gold 地形候选｜P11 静态前置

**准确基线：** `MAP-5.62.194`、导出 HEAD `118d5e38`，工作区干净。本阶段不修改游戏版本、不接入新地图运行逻辑、不开放33号道路西口，也不编译 ROM。

## 本轮已完成

- 在上一笔工具提交之后发现 `tools/johto_gold_geometry_contracts.json` 缺失：原 `.gitignore` 的 `*.json` 规则忽略了它，导致干净工程不能独立通过静态门禁。本阶段保留经过 Gold 对照的审计合同，并加入 `.gitignore` 精确例外，作为后续工具可重现性的修复。
- 使用现有 `tools/johto_rpp_pipeline.py --gold-map AzaleaTown` 从完整 Gold 源码独立读取，生成 `maps/JohtoAzaleaTown.blk`。该文件 180 字节，逐字节对应 Gold `maps/AzaleaTown.blk`，SHA-256 `a1bb573967204e3385b731b4e3c2aaa9ecd0f26bb85d701c096d35b69559476a`。
- 桧皮镇使用 `TILESET_JOHTO_MODERN`，现有 `gfx/blocksets/johto_modern.bst` 和 `gfx/tilesets/johto_modern.png` 与 Gold 原版素材一致，因此 **不重复复制图块集及图片**。

## Gold 结构证据（未批准运行）

| 项目 | 来源与数量 |
|---|---|
| 地图 | 20×9 个 32×32 区块／40×18 个 16×16 碰撞格 |
| 逐格候选 | 90 字节阻挡掩码（未接入 ROM），447 阻挡／273 可走 |
| 已通过通用跳崖几何候选 | 9 处向下跳崖 |
| 需人工审核 | `(10,6)` 向下跳崖：落点 `(10,8)` 可站，但下一格 `(10,9)` 是墙；通用安全策略不自动允许 |
| Gold 原版事件 | 8 Warp、9 路牌、11 对象、2 坐标事件 |
| 原版入口 | 5 DOOR、1 CAVE；建筑内部、呆呆兽之井、触发条件尚未接入 |
| 水面 | 0 WATER 水格；不应因此给本镇全局 Surf 许可 |
| 室外连接 | 东接 Route33（Gold 偏移 0），西接 Route34（Gold 偏移 -18）；当前 RPP 两侧仍保持原有封路状态 |

## 下一个**独立**功能阶段的准入

1. 先核对 `(10,6)` 的跳崖行为及落点后方墙体，不凭图像或测试数目直接放行。
2. 使用现有原生地图 ID、Header、音乐、色板及跨图块集安全机制注册桧皮镇；复用 `JOHTO_MODERN`，避免复制新转换器或同内容素材。
3. 必须逐项确认 Route33↔桧皮镇连接条带和反向边缘；Route34 仍未接入，因此西口不开放。
4. Gold 的8个 Warp 需对照目标地图是否已经接入，建筑／井入口未就绪不得开放；城镇 Fly 使用许可与 Fly 目的地记录分开审核。
5. 骑行、剧情事件、野外遭遇、音乐及 Continue 是独立审核项；当前本阶段只含**地形离线候选**，不可宣称桧皮镇可玩。

**验证分层：** `GOLD_SOURCE_MATCH`、`PROJECT_STATIC_PASS`（工具依赖恢复后）／`GAME_BUILD_NOT_RUN`／`PHONE_NOT_RUN`；用户之前对 `.194` 33号道路的实际反馈仍有效，不需要重新重复该地图的手机测试。
