# NPC-KANTO-5.62.242｜公共建筑 NPC 左右走动碰撞转换修复（源码候选）

## 根因（2026-10-26）

`tools/johto_olivine_public_runtime.py` 以前使用 `subcell*4+2` 判定 16x16 地板格的「左下 8x8 图块」，但 RPP `home/overworld.asm:DrawTileBlock` 对 `.bst` 是 **4 行 × 每行 4 字节的行优先排列**，不是连续四个 2×2 象限。正确索引为 `(2*(y%2)+1)*4 + 2*(x%2)`，依次为 4、6、12、14。

旧转换器算出的 NPC 白名单和真正渲染时 `GetTileSpriteStandsOn` 所读图块不一致。旧产物按正确排列复算，浅葱 PC 渔夫 `(8,4)` 左侧 `(7,4)` 的脚下 ID `$39` 在白名单中，但 `(6,4)` 与 `(8,4)` 的脚下 ID `$09` 不在名单中，符合“进门偶尔往左走一步，然后左右张望无法继续”的现象。吉花 MART 男 `(7,6)` 的左右相邻格、浅葱 MART 女 `(6,2)` 的部分返程格也因这种错误被拒绝。

**修复：**只改转换器的脚下图块索引，重新生成 3 套浅葱公共建筑 `PNG/.bst/.blk/.tilecoll`、调色文件、manifest。吉花市 MART 共享浅葱 MART 图块资源，同步受益。保留关东 `engine/overworld/movement.asm` 的 `WALK,2`、`TryWalking`、`CanWalkOntoTile` 与屏幕边界、人物碰撞。没有引入 Gold 引擎或取消家具阻挡。

## 源码验证和防回归

1. 新增 `tools/tests/test_johto_public_npc_foot_tiles_242fix.py`：真实脚下偏移 4、6、12、14；三间公共建筑 **每个 16x16 格** 的 NPC 图块通行结果与 Gold 玩家精确阻挡遮罩一致（仅对这三间屋的地板类别作对照，不代表全部 Gold 行为等价）。
2. 核对 PC 渔夫横向连续四格、浅葱 MART 女和吉花 MART 男各连续五格，以及餐厅渔夫上下三格均允许进入；旧脚本生成的资源会使此检查失败。
3. 用原始 Gold 候选资源分别渲染每间屋的整张地图，确认新 `.blk + .bst + PNG` **像素逐点不变**；复制图块保留原调色角色。
4. `python tools/johto_olivine_public_runtime.py --rpp . --check` 可字节复现。
5. 玩家 Gold `blocked_mask.bin` 没有变化；第一间民房 `JOHTO_HOUSE` 和关东原有 `.tilecoll` 都没变化。

## 交付与验收

此包是针对用户最新 `JSON-5.62.242.zip` 的源码补丁，不是 ROM。没有进行 RGBDS 编译/链接或手机实机验证。应用后请由项目构建流程重新导出 ROM，**不能在旧 ROM 上判定补丁**。

需要复验的仅 4 项：浅葱 PC 渔夫能往左连续走超过一格且可以返程；吉花 MART 男连续左右移动；浅葱 MART 绿发女性连续左右移动；浅葱餐厅渔夫仍可上下移动。若任何一项不符，应读取运行时当前 NPC 目标 BG ID 与 `wTilesetCollisionPtr`，不凭新一轮无依据的全局引擎改动重试。
