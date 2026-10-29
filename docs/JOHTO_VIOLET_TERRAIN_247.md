# VIOLET-247 — 桔梗市单图地形能力验收合同（开发候选）

## 来源、覆盖与不做的事项

- 参考：用户交接包的 MUS Gold `maps/VioletCity.blk`、`data/tilesets/johto_collision.asm`；地图 20×18 个 32×32 Block = 40×36 个 16×16 碰撞格。
- `HOP_DOWN`: `(X26,Y22)`、`(X28,Y22)`、`(X29,Y22)`，共3。沿用现有 `$06→$21` 跳崖配对与 RPP 共用跳跃引擎，不新建动画。
- `WATER`: 140 个，仅 Gold 原始水格允许；来源逐格表在 `engine/johto_violet_field_skills.asm`。包括 A 键、Surfboard 与水中移动/上岸。
- `CUT_TREE`: 唯一 `(X36,Y19)`；邻格 `(X37,Y19)` 是 `HEADBUTT_TREE`，不能误砍。Cut 完成后，源块 `$63` 被局部替换为新块 `$8D`，仅一个碰撞象限的四个 8×8 贴图变普通地面；源块与原有其他地图保持不变。
- Gold 还有 68 个 `HEADBUTT_TREE` 碰撞格与多处门/墙，但本轮**不开放摇树、剧情、NPC、封闭建筑或新地图**。不把整张图的墙、河流都打开。

## 能力、徽章和实际验收

- **未改变阶段性徽章逻辑**。需要会 Cut/Surf 的宝可梦和项目现有 Cascade/Soul Badge 条件；原版 Gold 的 Hive/Fog Badge 与城都徽章获取剧情不在本轮开发。没有徽章时动作被拒绝是当前明确门禁，不等于地形格识别失败。
- 在桔梗市，逐一检查 3 处跳崖方向和落点；普通地面不能穿树或爬崖。
- 在城区水岸，验证 A 键与背包 Surfboard 进入水面，水上能转向、继续移动、上岸及重新入水；无水的墙边不触发 Surf。检查骑车切换后与地图音乐正常。
- 在 `(36,19)` 砍树一次后可以通过；第二次不能再砍；旁边 `(37,19)` 的摇树图形与碰撞保留；重新加载地图时原始树恢复，保持既有 Cut 的非持久处理方式。
- 在桔梗市与31号路门房、32号道路间往返和存档 Continue 后正常移动；其他城都、关都 Cut/Surf/跳崖行为不变。

## 开发门禁与证据边界

执行 `python tools/asm_symbol_preflight.py` 和 `GOLD_SOURCE_ROOT=/path/to/gold python -m unittest discover -s tools/tests -p test_violet_field_247.py`。另外保留已有所有 Python、地图、门房与 Warp 审计。单图水格/树格静态对照通过不是 RGBDS 编译或手机实测。用户在 Termux 需重新做正式红蓝与测试版本的编译及两色 MAP 容量核验；不得把旧 `.243` MAP 当作 `.247` 链接证据。
