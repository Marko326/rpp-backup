# CHERRY-249｜吉花市冲浪接入（PAL-5.62.249）

## 范围

- 仅为当前活动地图 `CherrygroveCity` 接入 Gold 原版 Surf 水面。
- 若叶镇东侧 8 个水格继续按用户要求暂缓；本轮不开放 Route30、Route31、Route32 或未激活的联合洞穴。
- 不改变全局 `johto.tilecoll`、关都 `WaterTilesets`、徽章门禁、SRAM 布局或地图活动槽位。

## Gold 来源与坐标

Gold 原版 `maps/CherrygroveCity.blk` 为 20×9 Blocks，对应 40×18 个碰撞格。通过 `data/tilesets/johto_collision.asm` 解码得到 142 个 `WATER` 格，源码表位于 `engine/johto_violet_field_skills.asm::JohtoCherrygroveGoldWaterCells`，格式为 `(y, x)`，以 `$ff` 终止。

`tools/johto_surf_preflight.py --gold /Gold根目录` 会逐格比较源码表与 Gold 原始 `.blk` / collision 数据。共享的 8×8 图形 ID 不作为水面判据。

## 运行路径

- `engine/overworld/field_moves.asm::IsSurfTile`：面对水面使用 Surf 时检查地图专用水格。
- `engine/items/items.asm::IsNextTileShoreOrWater`：Surfboard 复用同一水格查询。
- `home/overworld.asm::CollisionCheckOnWater`：水面继续冲浪；非水格将 `wTileInFrontOfPlayer` 恢复到 `C` 后，继续使用原有陆地通行表扫描，以支持上岸。
- `JohtoCherrygroveIsActive` 同时检查运行时地图句柄 `$FC`、Johto 区域和 `JOHTO_CHERRYGROVE_LOCAL_ID`。其他地图不受此表影响。

## 静态检查

- `tools/johto_surf_contracts.json` 登记吉花市 142 格与尺寸。
- `tools/johto_surf_coverage_audit.py --gold /Gold根目录 --require-map CherrygroveCity` 必须返回成功；下一轮覆盖盘点仍应显示 Route30、Route31、Route32 为 `MISSING_SURF`。
- `tools/tests/test_cherrygrove_surf_249.py` 检查三个入口、地图作用域、Gold 水格一致性，以及不把 Gold 水面变成无 Surf 可步行格。

## 验收边界

静态测试不等于 RGBDS 链接或实机验收。用户本机应编译正式 Red/Blue、TEST Red/Blue 并检查新 MAP；手机上测试吉花市面对水面使用 Surf、Surfboard、四向游泳、从合法岸边上岸、上岸后继续行走、重新入水、存档/Continue；回归桔梗市 Surf 上岸、Cut、跳崖以及关都冲浪。

## CHERRY-250 验收清理及后续交接边界

- 新增 Surf 后经用户截图识别吉花市西南岩石平台无法登岸；CHERRY-250 专项按 Gold 原版 `(x4..7,y12..13)` 的8个 `FLOOR` 格修复水中登陆和岸上移动，避免全局放行共享 Tile `$3C`。
- 用户本轮要求按项目清理三件套正式准备提交；**这代表本阶段进入收口，不是本环境亲自模拟或链接**。源码审计和反例测试仍作为独立证据。
- 后续工具用 `MISSING_SHORE_PASSABILITY` 检查每个新增 Surf 地图的可登陆 FLOOR，不能仅检查 WATER 142格；若叶镇东水域继续排除，Route30/31/32 仍待接入。
- 新交接时以 `.250` 两笔实际提交完成后的 HEAD 为准；未收到手机 Git 新 HEAD 前，不用临时工作目录或本次打包物推断项目已提交。
