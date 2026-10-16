# RBK-5.62.184 正式收口补充（不覆盖历史 `.181` 开发记录）

- 普通城都 Town Map 在 `.182` 扩展为 Gold 原版 45 个地标；`.184` 保留该功能并撤销 SFX 试验。对照 Gold `data/maps/landmarks.asm`，45 项名称、顺序和 (Y,X) 光标坐标全部一致；各项位置唯一。Gold 地标宏先加 X+8、Y+16，RPP 逐项存为 `db Y,X`。
- `gfx/tilemaps/johto_map.kmp` 的非 UI 地理图块与 Gold `gfx/pokegear/johto.bin` 对照无差异；顶部标题和右下标签区域属于特意保留的 RPP 界面差异。光标、玩家标记、普通 Town Map、Fly 目的地必须独立区分。
- 用户 `184地图光标.mp4` 显示光标在多种城都地标间正常切换，包含未开放地点；录像约 14.5 秒，不等于逐帧实测了全部 45 个光标。用户另确认联合洞穴骑行及门房自动下车正常；没有因此开放 Surf、Dig、Escape Rope。
- 严格双源码静态门禁 `263 tests, 0 failures, 0 skips`（本次提交收口重新运行）；不能以此代替本机 ROM 编译/链接和所有输入时机实测。
- 此补充仅供提交说明，不更改已验收的进出门/Warp 汇编及地图碰撞。

---

# MAP-5.62.181 — 城都普通地图地标与联合洞穴骑行

范围：游戏版本标识、普通 Town Map 地标、联合洞穴骑行许可、独立 Gold 静态审核及其负例。**不修改** Warp、出口到达步进、地形、碰撞、地图图块、美术、关都门房或野外技能。

## Gold 坐标规则

`pokegold/data/maps/landmarks.asm` 中的 `landmark x, y, Name` 宏实际输出 `x + 8, y + 16`；RPP `JohtoTownMapEntries` 存储顺序为 `db y, x`。本版修复三项：

| 地标 | 旧 (X,Y) | 正确 Gold (X,Y) |
| --- | --- | --- |
| Route 31 | (100,76) | (104,76) |
| Route 32 | (84,92) | (92,108) |
| Union Cave | (84,124) | (92,140) |

Route 32 的旧别名地点表和 local 7/8 native 地图记录一并保持一致，独立身份表同时校准。道路/山洞**不是** Fly 目的地。未开放的 B1F、33 号道路出口继续封闭。

## Town Map 底图差异边界

RPP `gfx/tilemaps/johto_map.kmp` 为 20×18=360 字节。Gold `gfx/pokegear/johto.bin` 为 360 图块索引 + `$FF` 结尾。逐格比较有 44 个索引不同：上方左侧 `y=0..2, x=0..12` 共 39 格（RPP 标题区）；底部 `y=16, x=14..18` 共 5 格（RPP 地区标签）。其余 316 个图块**索引**一致。本版不改既有美术。该对照不证明 PNG 图块像素及手机呈现完全一致。

`tools/johto_town_map_bike_audit.py` 强制检查所有 15 个普通城都地标的 Gold 宏坐标，并保护非 UI 图块区域；任意非 UI 区块索引改变，工具会失败。

## 自行车（仅联合洞穴 1F）

Gold `engine/events/overworld.asm` 的 `BikeFunction.CheckEnvironment` 允许 `CAVE`，但只允许 `GetPlayerTilePermission & $0f == 0` 的 `FLOOR_TILE`。RPP 当前通过 `IsBikeRidingAllowed` 扫描 `BikeRidingTilesets`；联合洞穴的 Header 使用 `JOHTO_UNION_CAVE` 专用 Tileset，而该值先前缺失。现在仅在许可表 `$FF` 之前增补该一项，不添加门房 `JOHTO_GATE`，不放宽既有碰撞。

`tools/johto_native_maps.json` 对联合洞穴 `bike` 标记 `ALLOWED`，含义为代码当前允许骑行，**不是**手机已验收；骑行状态、进出洞音乐、存档恢复仍需手机实测。冲浪、挖洞、逃洞绳继续 `DEFERRED`，不顺便开放。

## 审计与验收

```
python tools/johto_map_release_audit.py --rpp . --gold /path/to/pokegold-master --expect-version MAP-5.62.181
```

静态门禁必须发现新增专用测试模块及其负例，同时继续保留 `.180` 原有 35+ 个门禁模块。正确工程应通过，故意移除洞穴许可、误改地标或普通底图非 UI 字节应失败。自动审核不会编译 ROM 或替代手机实测。

本阶段没有申请 Git 提交，待用户手机验收后建议再按功能/工具分别整理 Git 提交范围；旧历史代码备注、TODO 与踩坑清理三件套暂时不动。
