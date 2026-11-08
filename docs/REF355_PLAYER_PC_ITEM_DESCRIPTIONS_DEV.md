# REF-355｜玩家 PC 道具列表实时说明（正式归档）

## 功能目标与来源
- 参考对照项目 ROM-1.42H 第 059 次提交 `04324e16` 的**非汉化**部分：Player's PC 道具浏览时动态显示简短说明。仅借鉴行为，不直接复制该项目 `src/` 代码及汉字资源。
- 主项目已在 `engine/menu/bag_pockets.asm` / `engine/menu/item_descriptions.asm` 提供 English 两行说明（含 TM/HM 动态招式名）。本次仅在传统 Player PC ITEMLISTMENU 接入相同绘制逻辑。

## 具体改动（不改存档和道具规则）
- `home.asm`：`DisplayListMenuIDLoop` 每次在“打印列表、绘制光标”之后、BG tilemap 转送之前，调用只读 PC 说明刷新门控；`HandleMenuInput` 消费上下按键且不立即返回列表，所以也在它的光标变化点刷新。只有 `wBagPocketActive==0`、`wListMenuID==ITEMLISTMENU`、`wFlags_0xcd60` bit5、**`wMenuWatchMovingOutOfBounds` 为1（真实列表正在运行）**才远调用专用助手；返回 Player PC 父菜单时此标志为0，不覆盖父菜单文本。
- `engine/menu/bag_pockets.asm`：新增 `UpdatePlayerPCItemDescription`，再次核对列表指针必须准确等于 `wNumBagItems`（Deposit）或 `wNumBoxItems`（Withdraw/Toss）；绝对索引 = `wListScrollOffset + wCurrentMenuItem`；索引大于等于 `wListCount` 时使用 `$ff`（Cancel → 清空）。其余读取 count 后 `1+2*index` 的 ID 字节。
- 调用已有 `UpdateBagPocketDescriptionFromItem`：直接重用普通物品 `ItemDescriptionPointers_Mart`、机器物品 `DrawMachineItemDescription`、短文本绘制和 BG-transfer 暂停。复用未打开 Bag 时的说明 cache scratch；不新增、挪用任何持续保存字段。
- `engine/menu/players_pc.asm` 原有库存增减、选项、关键物品规则、数量框、SELECT 交换和光标恢复不变。商店、Bill's PC、战斗列表以及五分类背包保留旧逻辑。
- `data/game_version.asm` 的等长显示字符串从 `REF-354@` 改为 `REF-355@`。

## TEST ROM 与普通 ROM 的手动验收
1. 用新构建的 Red/Blue 或 TEST Red/Blue、使用一份副本存档，前往任意可用 Player PC（卧室 PC / 宝可梦中心 PC 的 `PLAYER's PC`）。不要用 Bill's PC 代替。
2. **Deposit**：背包至少包含两种普通物品及一张 TM。进列表就应出现首项说明；上下移动时，文字跟着换；用左右翻页选择不同物品，说明也应换；选择 `Cancel` 时旧说明应清空。选普通物品进入数量框再取消，返回列表应重新显示正确的说明。
3. **Withdraw**：先把普通道具放进 PC 存储箱。浏览 PC 取出列表应按箱内的物品编号和顺序更新说明；取出一项后，下一次列表不应继续显示旧物品说明。
4. **Toss**：同一个 PC 箱内物品列表也应实时显示说明；B/Cancel 返回父菜单不出现旧说明残留；关键物品的原有丢弃限制不变。
5. **TM/HM**：如库存里有 TM，说明区应显示 `TMxx` 及对应招式名，不应显示占位文本；HM 在 Deposit 的原有禁止存储规则不变。别为了测试改存档格式。
6. **负向**：进入 Bill's PC、START 五分类背包、商店买卖、普通道具使用菜单与战斗背包，确认界面、文字刷新、SELECT 操作、精灵覆盖及音效与 REF-354 一致，且不会出现 PC 说明浮层。

## 检查与证据边界
- 本轮只运行 `python -m pytest -q tools/tests/test_ref355_player_pc_descriptions.py`，静态 7 项覆盖门控、索引、Cancel、共用绘制和 PC 三入口，**不是运行 ROM**。
- 本环境未执行 RGBDS 0.5.2 汇编/链接，未生成当前 REF-355 MAP；旧 REF-354 Red MAP 不能证明本轮 Bank / ROM0 仍安全。需用户本机构建四种 ROM、确认 ROM0 ≥64B，并测试上述操作。
- 用户已反馈 Player PC 三种操作在 ROM 中正常。正式交付与 SELL、Flash、测试和维护文档一次提交；本环境未执行 Git Commit/Push 或四版本 RGBDS 构建。
