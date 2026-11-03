# DEV-336 / REF-330 — Cherrygrove City Gold Pokémon Center 运行时故障修复

## 范围与设备反馈

用户在 REF-329 实机确认 Gold 5×4 室内外观已正确，但护士隔柜台按 A 没有响应、室内行走卡顿、两格地毯横移误出门，以及能从地毯向下走入黑白区域导致死机／重启。前一轮纯静态验收未覆盖这些入口；不能把其通过视作设备正常。

## Kanto 对照和复用的门房机制

- Kanto 护士坐标也是 `(3,1)`，不是护士站错位置；Gold 的护士仍保持 `(3,1)`，玩家在 `(3,3)` 朝 `UP` 面对 `(3,2)` 的柜台。Kanto `home/overworld.asm` 检测 tile header `wTilesetTalkingOverTiles` 决定是否使用 32px 的隔柜台 A 对话范围，Gold 室内运行图块在此前方视角实际是 `$15`。因此在 `JOHTO_POKECENTER` 的 tileset header 登记 `$15`，而不是把护士移到柜台前。
- 旧图块集的 WarpTile 索引 `WarpTileIDPointers` 长度只有37，而 Gold 中心 tileset ID 为37（第38项）。原生 warp 检查通过 tileset ID 无条件查该表；新增 `JohtoPokecenterWarpTileIDs: db $ff`，保留 Gold 地毯 **不是 STEP_ON** 的行为，修复缺项的越界读取风险。
- 复用已验收门房的两种独立判断：有效 Warp `(X=3/4,Y=7)` **站上不传送**；只有朝 `DOWN` 发生物理碰撞时才允许按登记 Warp 返回。左右换位不会触发 Warp；房间宽10、高8个玩家格，四边都在移动前拦截越界。
- 进入房间可能直接落在底行地毯；利用已存在的进入地图后的 `UpdateSeafoamEntranceSource` ROMX 回调，仅针对 Johto Center 重新清除旧 standing 标志并调用 `IsPlayerStandingOnWarp`。保证入门位置向下出门可用，而不在 ROM0 新增调用或破坏 Kanto Seafoam 入口标记。

## 本轮仍未改变

Gold 像素/5×4 布局、护士坐标与治疗脚本、Johto 治疗记录与 Town Map START、Kanto 中心、其它13座门房和地图槽、现有107条 Warp 均保持既有定义。Teleport/战败、二楼、PC 物品系统没有在此轮开放。版本从 `REF-329` 升为 `REF-330`。

## 设备验收（须关闭穿墙金手指）

1. 在 `Cherrygrove City` 入 Center，玩家应站在两格地毯之一；按 `DOWN` 必须返回城市；重新进门测试另一格。
2. 重新进门，站在左地毯 `(3,7)` 向 `RIGHT` 走到右地毯 `(4,7)`，再向 `LEFT` 回来：**都不应出门**。只有向 `DOWN` 碰撞室内下边界才出门。
3. 尝试室内四边界，尤其底行非地毯部分，应被挡住，不能进入黑白区域，也不能软重启。
4. 在柜台下方 `(3,3)` 朝 `UP` 按 `A`，护士应正常出现 Yes/No；选择 `No` 不治疗，选择 `Yes` 完成治疗动画。
5. 治疗后走到 `Route 29`，打开普通 Town Map，先移动光标再按 `START`，应回到 `Cherrygrove City`。保存/重载后再试。
6. 检查 `Guide Gent's House` 和原有 Johto 门房方向、Kanto Pokémon Center 护士/出口，以及室内来回走动是否还会出现明显卡顿。

## 证据边界

静态审计、故障注入和 ASM label 预检仅证明源码符合指定路径；无法证明真实 Game Boy 链接、显示、帧率、内存状态或手机稳定性。项目禁止 AI 自行编译 ROM；Red/Blue/TEST 本机新 MAP 要核实 ROM0≥64B、各固定 Bank 容量。若仍卡顿，需要设备模拟器性能日志／内存 dump，不能仅以新增 Warp 指针项推断性能问题已解决。
