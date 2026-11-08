# REF-355｜商店 SELL 道具说明与废弃提示注释保留（正式归档）

## 本轮目标
用户已确认 Player PC 道具说明在实机正常；但商店 SELL 列表仍没有短说明，进入列表前又展示 “What would you like to sell?”，切换到说明区时发生二次文字刷新。旧提示的调用、包装器、正文均逐行改为 `;` 注释（不参与汇编），而非留着占 ROM 的无用文字资源；让 SELL 列表沿用已有说明渲染器，避免改写买入列表或库存/价格代码。

## 运行改动
- `engine/overworld/pokemart.asm`：在 `.sellMenu` 不再打印 `PokemonSellingGreetingText`；保存干净画面后直接进入 SELL 列表。每次调用原 `DisplayListMenuID` 之前临时置位 `wFlags_0xcd60` bit2，返回时 `push af`/`pop af` 保留 Cancel 的 Carry，清除 bit2。取消数量选择、无法出售、继续卖出都会重新进入同一个受保护的列表。
- `home.asm`：在现有 `RefreshPlayerPCItemDescription` 中允许 Player PC bit5 **或** SELL bit2 的两种短暂使用范围；仍须 `wBagPocketActive==0`、`wListMenuID==ITEMLISTMENU`、真实列表 `wMenuWatchMovingOutOfBounds != 0`。ROMX `UpdatePlayerPCItemDescription` 继续用 `wNumBagItems/wNumBoxItems` 精确校验指针、2字节 ID/数量索引和 Cancel；不会将普通买入列表误判为 SELL。
- `wram.asm`：只补注释说明临时 bit2，不增加 SRAM/WRAM 字节，也不修改存取、换序或价格算法。显示版本维持 `REF-355@`。

## 源码中的完整废弃路径（不编入 ROM）
- `engine/overworld/pokemart.asm` `.sellMenu`：注释保留 `ld hl,PokemonSellingGreetingText` 与 `call PrintText` 两条旧指令。
- 同一文件文本包装区域：注释保留 `PokemonSellingGreetingText:`、`TX_FAR _PokemonSellingGreetingText`、`db "@"` 三行。
- `text.asm`：注释保留 `_PokemonSellingGreetingText::`、`text "What would you"`、`line "like to sell?"`、`done` 四行。
- **没有有效指令、有效标签、链接指针或 ROM 文本数据**；其他 SELL 价格、提示、交易代码不注释。

## 游戏内测试步骤与预期结果
1. 进入商店选择 **SELL**：不再出现 “What would you like to sell?”；直接出现背包可卖道具列表，首项两行说明应立即显示。预期无旧提示文本短暂闪现。
2. 包内准备至少5种不同道具及一张 TM。上下移动、左右翻4格：描述和光标同步，不能把“数量字节”当道具编号；Cancel 不再显示上一项文字。
3. 按 SELECT 选择两种道具换序：交换正确且新光标说明对应最新顺序；不触发购买菜单或价格丢失。
4. 选普通道具→数量框→按 B 取消：回到 SELL 列表并立即显示当前道具描述。真正卖出1件后金币和背包数量仍正确、说明按新列表刷新。
5. 尝试不可卖道具/HM，维持原有拒绝行为；空背包仍显示“没有东西可卖”的原提示，不进入说明列表。
6. 回到 BUY、Player PC 三种列表、START 背包及 Bill's PC：行为和之前验收结果一致，没有多余说明。退出商店再开任何菜单，SELL 的临时 bit2 不残留。

## Flash 后续变更
关都非黑暗室外 Flash 仍成功的问题已在之后的 `REF355_FLASH_DARK_CAVE_ELIGIBILITY_DEV.md` 开发候选中单独处理；当前主工程同时包含该候选的地图+暗场门控。此处保留 SELL 变更记录。

## 证据与边界
- 针对 `tools/tests/test_ref355_mart_sell_descriptions.py` 及现有 `test_ref355_player_pc_descriptions.py` 执行源码契约测试，只验证调用接线、条件门控、索引及 UI 所需流程，不是 ROM 执行。
- 用户反馈 PC／SELL 候选日常使用正常；本轮仅执行相关专项静态测试，不运行无关的城都地图全量审计。四种构建/MAP 与完整交易、输入边界组合仍需额外验证。正式清理将功能、工具、测试、文档一起提交，Git Commit/Push 由用户执行。
