> **后续更新：** REF-358 已将父菜单绘制移到 B 松开等待之前并提升版本，参见 `docs/REF358_PC_RETURN_RESPONSIVENESS_DEV.md`；下文只保留 REF-357 故障修复历史。

# REF-357 开发修复｜玩家 PC 光标乱位与 B 返回

## 依据

用户上传的 `REF-357.zip`（显示 `REF-357@`）和带按键信息的视频 `357.mp4`。录像约 7–8 秒、14–15 秒、19–21 秒的 Player’s PC 道具列表返回流程可见：关闭物品列表后，`What do you want to do?` 文本框左上边缘出现菜单箭头；主菜单位置、返回时机不稳定。视频里没有清晰展示 Bill’s PC 宝可梦存入列表，后者需单独在设备上重测，不将其断言为已修复。

## 已确认的根因

`wFilteredBagItems` 从 `$CC5B` 开始，START Bag scratch 在 `BAG_ITEM_CAPACITY=100`、`NUM_BAG_POCKETS=5` 时的 `BAG_POCKET_DESCRIPTION_CACHE_OFFSET=120`，结果落在 `$CCD3`。此字节同时是 `wParentMenuItem`：保存 Player’s PC / Bill’s PC 父菜单的选中项。REF-355 道具描述每次刷新写入 `$fe` 及道具编号，破坏了父菜单光标 ID，后续 `PlaceMenuCursor` 使用被污染的编号可能画出边框外箭头甚至访问越界的 tilemap。此问题在 REF-357 解锁图鉴前卧室 PC 后更容易发现，但并非新卧室开关自身导致。

## 修改

- `engine/menu/bag_pockets.asm`：Player PC 描述绘制改用已导出的 `wBattleBagDescriptionCache`；仍每次强制刷新、继续复用 REF-355 两行道具/TM 说明。START Bag 仍使用原专用缓存。
- `wram.asm`：直接复用全局标签 `wBattleBagDescriptionCache::`（`$CD0A`），不另建跨汇编模块不可见的本地 `EQU` 别名。玩家 PC 和战斗中的 Battle Bag 不会并行运行；不增加 WRAM/SRAM、不动存档布局。
- `engine/menu/players_pc.asm`：父菜单在接受下一次输入前等待上一轮 B 实际松开，防止一次长按 B 同时从道具列表返回并关闭玩家 PC 菜单。没有改变 Bill’s PC 的功能和按键规则。
- 更新 REF-355 源码断言，增加 REF-357 内存别名、三种道具列表返回层级与 B 释放门控专项测试。

## 链接错误补救（2026-11-08）

上一份补丁误用了 `wPlayerPCItemDescriptionCache EQU wBattleBagDescriptionCache`，普通 `EQU` 在单独的 WRAM 目标文件中未导出，导致 `Unknown symbol`。本版让 Player PC 直接引用原有 `wBattleBagDescriptionCache::` 导出标签，删掉无用别名；地址与运行逻辑均不变。专项源码测试已补充跨模块符号可见性约束；没有把静态测试伪称为 RGBDS 编译。

## 需要在设备上确认

1. Player’s PC（卧室图鉴前 / 图鉴后通用电脑）中，分别进入 Withdraw、Deposit、Toss，移动光标后**按一次 B**：应只返回四项 Player PC 菜单，原来所选的菜单项箭头在正确行；`What do you want to do?` 边框不出现箭头。持续按住 B 不应多退一级。
2. **松开 B 再按 B**：才应返回通用 PC 主菜单，或独立卧室 PC 返回地图。A 选择 Cancel 返回时也应在正确的父菜单行。
3. Bill’s PC 存入/取出/放生 Pokémon：先验证各自列表 B 仅退到 Bill’s PC 四项菜单，再验证上方/下方光标是否正确；这段录像未充分呈现，若仍异常，应单独录下此路径并继续排查，不擅改其存储与队伍数据。
4. SELECT 排序、列表翻页、TM/HM 说明、数量框与余额限购保持 REF-355/356 既有功能；不应在普通 Bag 或战斗 Bag 中产生额外残留。

## 证据边界

本轮根据录像与源码定位同字节覆盖，专项 Python 测试是静态地址/控制流验证。未进行新 ROM 编译、MAP 复核或新修正版的真实按键验收。版本仍是 `REF-357@`，用户确认后再制作正式清理三件套。
