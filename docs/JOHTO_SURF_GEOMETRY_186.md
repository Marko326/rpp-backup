> **SRF-5.62.187 阶段更新**：此文是 FMP-002 的 Gold 水格审计过程记录。当前 64 个洞穴水格已经接入 Surf 运行时，32号道路另有 278 个水格。仍不能把共用图块 ID 的墙面放进公共冲浪白名单。

# 城都 Surf 第一阶段：联合洞穴 1F 的水面碰撞合同（FMP-002）

**状态：STATIC_PASS / RUNTIME_DEFERRED / PHONE_PENDING。** 纯工具更新；游戏版本仍为 `RBK-5.62.184`，不开放 Surf / Dig / Escape Rope。

## 双源码核对结果

`pokegold` 的 `maps/UnionCave1F.blk` 与 `data/tilesets/cave_collision.asm` 定义水面；RPP 对应 `maps/JohtoUnionCave1F.blk` 与独立 `gfx/blocksets/johto_union_cave.bst`、`gfx/tilesets/johto_union_cave.tilecoll`。

- Gold 联合洞穴 1F 存在 **64 个 16×16 水面碰撞象限**。
- RPP 对应的 8×8 图块 ID 是 `$03/$08/$0A/$0C/$0D/$14`，**不是只有 `$14`**。
- `$03/$08/$0A/$0C/$0D` 同时用于 **WALL 与 WATER**；它们不能直接加入一个不分地图／位置的“可游泳 ID”列表，否则有可能把墙当水。
- `$14` 在当前 1F 的使用范围中只见于 WATER，但只识别 `$14` 又不足以覆盖所有 Gold 水象限。
- 当前洞穴水面图块均不在陆地通行白名单；不改变此条约束。

## 接下来开放 Surf 前必须完成

1. **水面独立图块/分类**：为墙／水共用的图形建立无歧义的运行时类别（可以用同像素不同 ID 的专用克隆），并核对 Gold 与 RPP 每一格图像、调色及碰撞一致；不可直接全局放行 `$03` 等 ID。
2. **全路径一致**：`IsSurfTile`、`IsNextTileShoreOrWater`、`CollisionCheckOnWater` 以及上岸逻辑必须使用相同的水面判据；只修改 `WaterTilesets2` 或 `WaterTilesets` 之一属于危险的半接入。
3. **徽章与地区**：当前 Surf 的菜单和水面交互仍复用关都 Soul Badge；Gold 则使用城都 Fog Badge。城都徽章当前尚未具备完整剧情发放及验证，不能跳过该前置条件。
4. **返程与安全**：边界、骑车切换、进出洞、音乐、保存/Continue 都要覆盖；联合洞穴的 B1F 与 33 号道路入口保持封闭。Dig/Escape Rope 的双地区返程另做，不因 Surf 的通过而开放。

## 审计与验收

通过 `make johto-map-audit JOHTO_GOLD_SOURCE=绝对Gold根目录` 或独立运行：

```sh
python3 tools/johto_surf_geometry_audit.py --rpp . --gold /真实的pokegold路径
```

审计输出 `water_quadrants`、`water_tiles`、`also_used_by_walls` 和 `surf_enabled: false`。工具静态 PASS **不代表 Surf 可以使用，也不代表 ROM 已完成编译、容量检查或手机实测**。
