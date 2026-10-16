> **收口说明（SRF-5.62.187）**：以下 `.185/.186` 属于开发过程记录。当前有效规则已经扩大为联合洞穴 1F＋32号道路两个 Surf 场景，这两处暂不需要城都徽章，关东原 Soul Badge 条件维持不变；最终水面适配见 `docs/JOHTO_ROUTE32_SURF_187.md`。用户报告洞穴、32号道路的冲浪正常。旧候选文字不得作为现行使用说明。

# SRF-5.62.186｜徽章条件的阶段性覆盖（当前有效规则）

`.185` 源码中曾要求联合洞穴 Fog Badge，但城都徽章领取剧情尚未接入，暂无法在正常游戏流程中获得该徽章。经用户决定，**仅联合洞穴 1F 暂时不检查徽章**；面向水面、队伍菜单和 Surfboard 伪道具均按 Gold 64 格水面与现有碰撞规则使用 Surf。其他地区维持原有关东 Soul Badge 检查。此举不是发放徽章或开放其他城都地图的 Surf。

待城都剧情与双地区技能许可统一设计后，再独立讨论两套徽章如何控制 Surf 等野外技能，不能默认 Fog 与 Soul 互认。本阶段仍须玩家有会 Surf 的宝可梦，并在实际 ROM 上检查三入口、上下岸和旧关东功能。**下文 `.185` 为保留的旧候选说明，其中关于 Fog Badge 的限制、测试要求已被 `.186` 覆盖。**

---

# SRF-5.62.185｜联合洞穴 1F Surf 运行适配（候选）

**基线：** FMP-002（游戏版本 RBK-5.62.184），本阶段候选版本 `SRF-5.62.185`。

**验收级别：** `STATIC_PASS / BUILD_PENDING / PHONE_PENDING`。尚未编译或链接 ROM，也没有游戏内冲浪录像。Game Boy 汇编语法与 Bank 布局仍需实际构建确认。

## 数据合同

- Gold `maps/UnionCave1F.blk` × `data/tilesets/cave_collision.asm` 提供 **64 个 WATER 16×16 象限**，共四个互不相连的水池，各 16 格。
- RPP 在图块 `$03/$08/$0A/$0C/$0D/$14` 绘制水面，但前五个图块也用在 WALL。只靠 `WaterTilesets2`、`WaterTilesets` 或 `CollisionCheckOnWater` 中的 `$14` 无法完整表达水面，因此**禁止将本洞穴加进公共水面图块白名单**。
- 本次把 Gold 64 个坐标以 `(y,x)` 保存到 `engine/overworld/johto_union_cave_surf.asm`，在 ROMX Bank `$42` 中由 `IsJohtoUnionCaveWaterAhead` 依当前角色坐标、面朝方向和城都本地地图 ID 决定水面。地图外和非本洞穴一律返回非水面。

## 游戏入口与安全边界

1. `engine/overworld/field_moves.asm` 的 `IsSurfTile` 在专用洞穴图块集上调用同一查询，否则保留关都判定。`TrySurf` 检查 `JohtoSurfBadgeAllowed`。
2. `engine/items/items.asm` 的 `IsNextTileShoreOrWater` 在洞穴调用 `JohtoSurfStartOnWater`，一次完成 Fog Badge 和水面检查，并按原 RPP `carry clear = water/allowed` 返回。`ItemUseSurfboard` 原始流程不改；关都伪道具处理保持原样。
3. `home/overworld.asm` 的 `CollisionCheckOnWater` 在本洞穴以 Gold 水格判断继续游泳，非水格继续由原通行列表决定能否靠岸、自动下船。其它图块集继续运行原版 RPP 的 `$14/$32/$48` 路径。
4. 在联合洞穴，队伍 Surf 和地图交互两条常规入口都要求城都 Fog Badge（`wObtainedJohtoBadges` bit 3）；其它地图维持关都 Soul Badge（`wObtainedKantoBadges` bit 4）。此阶段没有新增徽章领取剧情，也没有给测试档自动发徽章。
5. **不碰** Route32／联合洞穴 Warp、未开放的 B1F 和 Route33 入口、门房自动下车、Dig／Escape Rope、Gold 音效实验、Town Map 和关都水面规则。

## 静态审计与已知限制

`tools/johto_surf_runtime_audit.py` 验证 Gold 64 水格全量一致、三条路径与分支方向、跨区边界、徽章检查、无全局水面白名单扩大；同时加了独立反例。`tools/johto_map_release_audit.py` 的强制用例清单已纳入新增测试，避免新测试被删仍 PASS。

仅凭这些无法证明真正的 ROM 运行、Bank `$03` 链接容量、音频恢复和存档 Continue 路径。旧 `.184` MAP 的 Bank `$03` 余量仅 22B，新增调用估计约 11B，**高风险紧空间，需要真实链接验收**。

## 最小手机验收

- 没有 Fog Badge 时，从岸边尝试 Surf 应被拒绝；即便持有 Soul Badge 也不能替代。
- 有 Fog Badge 且队伍中宝可梦会 Surf：水面交互和队伍菜单两种入口都能登船；在四个水池中从不同方向试入水／移动／上岸（可以分场景执行）。
- 在水池边界连续按方向键，不得穿墙、走进未开放地图或卡住；靠岸后正常步行，重新入水，切换骑行和步行，音乐正常。
- 离开/进入洞穴、保存后 Continue，旧关东 Surf 和门房仍正常。

**不执行 ROM 构建和 Git Commit/Push。**
