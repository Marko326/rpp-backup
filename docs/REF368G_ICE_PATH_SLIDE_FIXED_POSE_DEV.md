# REF-368G@｜冰之通路滑行固定脚步姿势（开发测试）

## 本轮基线与范围

- 从 REF-368B 用户上传源码依次应用 REF-368C、D、E、F 的 `01` 增量补丁重建 REF-368F；本轮版本由 `REF-368F@` 提升为 `REF-368G@`。
- 地图不变：70 张活动地图、188 条方向 Warp。五张 Ice Path 地图仍为 1F ID70、B1F ID95、B2F Mahogany ID96、B2F Blackthorn ID97、B3F ID98。
- 本轮只修正步行状态下的滑行视觉帧；不改变 ICE 角色、方向输入、普通碰撞、地图坐标推进、Warp、Bike 许可或滑行方向逻辑。

## 原版行为对照

Gold/Silver 冰面滑行时，人物仍沿格移动，但脚部不做普通走路的交替迈步；这是固定脚步姿势的滑行，不是角色和镜头都静止。资料对 Gold/Silver 冰面与未使用 Skateboard 动画作了明确区分，冰面 Animation 一项为 feet don't move while sliding：

- `https://glitterberri.com/pokemon-gold-silver/the-case-of-the-missing-skateboard/`，页面 2013-04-29；对照表及说明见页面第 93–102 行。
- 页面还区分了普通站在冰上顶墙时的步行动画与实际滑行状态；本轮仅固定真实自动滑行期间的脚步帧，撞停并清除滑行状态后恢复普通行为。

## 代码修正

`engine/overworld/movement.asm` 的 `UpdatePlayerSprite`：

1. 保留原有朝向计算与 `wSpriteStateData1+9` 写入。
2. 在 `.moving` 处优先检查 `wWalkBikeSurfState`。非步行状态直接进入原有动画分支，避免冻结自行车帧。
3. 仅当 `wWalkBikeSurfState == 0` 且 `wIcePathSlideHeading != 0` 时，把 `wSpriteStateData1+7`（步行动画帧延迟）与 `wSpriteStateData1+8`（帧索引）清零，然后跳到 `.calcImageIndex`。
4. 位置、镜头滚动、碰撞、NPC 阻挡与楼层 Warp 仍由原有 `AdvancePlayerSprite`／`CollisionCheckOnLand` 管线处理；没有直接写玩家坐标。
5. 撞墙或其他阻挡清除 `wIcePathSlideHeading` 后，固定姿势分支退出，原站立/行走动画恢复。

## 五层自行车复核

所有五张活动楼层均有 `IsBikeRidingAllowed` 的公共分派，覆盖 Bag、SELECT 与地图切换时的骑车精灵重载。新上车要求脚下 Gold role 为 FLOOR；不能直接在 ICE 格新上车。已骑车状态允许跨楼层保留。

| 楼层 | Gold FLOOR 可新上车格 | Gold ICE 格不可直接新上车 |
|---|---:|---:|
| 1F ID70 | 818 | 234 |
| B1F ID95 | 251 | 44 |
| B2F Mahogany ID96 | 44 | 304 |
| B2F Blackthorn ID97 | 36 | 91 |
| B3F ID98 | 75 | 0 |
| 合计 | 1,224 | 673 |

B3F Gold role 没有 ICE 格；其 75 个可新上车格均为 FLOOR。这里的“支持自行车”表示该楼层存在合法 FLOOR 上车位置，不表示整层每个格子都能上车。

## 实际执行的检查

```sh
python tools/johto_ice_path_bicycle_368e_audit.py --root .
python tools/johto_ice_path_slide_368f_audit.py --root .
python -m pytest -q tools/tests/test_johto_ice_path_slide_368f.py tools/tests/test_johto_ice_path_bicycle_368e.py
```

本轮测试：47 passed（滑行与自行车相关测试合并）。自行车地图审计五层全部通过；滑行审计检查真实步进、输入注入、跨 Bank role 查询、碰撞清除与本轮固定脚步帧。新增错误注入覆盖：移除固定脚步分支、破坏自行车动画保护、取消中性帧重置都会失败。

这些是源码静态测试，不是 RGBDS 汇编/链接、ROM0 空间检查或手机实机结果。本轮没有编译 ROM、没有 MAP，未验证目标 Bank 实际链接空间；也没有设备录像。

## 最小手机复测

1. 步行踏上 1F 或 B2F 长 ICE 直道：进入自动滑行后，人物应保持朝向、脚部不交替迈步，地图仍连续滚动。
2. 改按垂直/反向方向：滑行继续保持原方向；撞墙后停下，人物回到正常可操作状态。
3. 骑车状态进入洞穴并滑过 ICE：应保留自行车动画，不应被步行固定帧逻辑冻结。
4. 在 FLOOR 格分别用 Bag 与 SELECT 上车；在 ICE 格尝试新上车应被拒绝；检查五层楼梯骑乘状态保持。

## 尚未完成

- B1F 四块 Strength 石头的推动与四个 PIT 落洞、落点转换仍未完成。
- Rock Smash、道具、NPC、野怪、剧情仍按既定范围延期。
- 历史迁移审计已有 35 项冻结规则失败，未宣称全量通过。
- 四版本 Red/Blue/TEST ROM、MAP 与 ROM0 ≥64B 尚未验证；手机实测待用户完成。
- 本轮没有 Git Commit/Push。

## 开发期交付

本轮相对 REF-368F 修改游戏运行 ASM，也更新 `tools/` 审计与测试。开发阶段仍按上位规范仅交一个 ZIP，包含两份互斥 `.patch`：`01` 从 REF-368F 当前状态增量应用，`02` 从已确认 REF-367 HEAD `cd88452a05e9399b469f12fe2c6c89dd532dfcfb` 累计应用。两者二选一，不可叠加；没有正式提交日志或工具隔离补丁。
