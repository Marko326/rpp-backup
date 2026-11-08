# REF-360｜Player PC 主菜单人物精灵遮挡时序修正（实施与验收记录）

## 项目规则与本次基线

- 从用户实际上传的 `REF-359.zip` **完整源码**继续开发。提交历史包的导出 HEAD 停在 REF-356，不能据此冒充用户当前 Git HEAD。
- 遵守 `PROJECT_DELIVERY_RULES.md`：运行 ASM 改动即升版本 `REF-359@` → `REF-360@`；同时交付源码、专项测试和维护文档，**待用户验收后一次 Commit**；本次不自行 Commit/Push，不自行编译 ROM。
- 用户复核：仅 Player PC 父菜单图片中有地图人物压在底部提示框；Withdraw、Deposit、Toss、数量确认，以及 Bill's PC 的主菜单与二级菜单均无此问题。不得擅改这些已正常的入口。

## 静态根因与相邻正常路径

- `PlayerPCMenu` 先 `LoadScreenTilesFromBuffer2DisableBGTransfer`、绘制上方列表，再绘制底部 `What do you want / to do?` 的 `TextBoxBorder` 与 `PlaceString`。
- REF-358 把原标准 `PrintText` 改为直接绘制下方固定提示，但 `UpdateSprites` 依旧位于**上方菜单框之后**，底部文本框创建前就已刷新。`CheckSpriteAvailability` 会读取 `wTileMap` 以遮挡站在文本框上的地图人物；使用不完整 TileMap 可能保留地图精灵 OAM。
- Bill's PC 仍使用 `PrintText` 在下方文本框完成后更新精灵；道具二级列表通过 `DisplayListMenuID` 在列表完成后更新遮挡；背包 `PrintBagPocketName` 已有“下方说明框后重新调用 UpdateSprites”的注释，印证遮挡时序的重要性。

## 最小修复

在 `engine/menu/players_pc.asm::PlayerPCMenu` 中将**已有的唯一一次** `call UpdateSprites` 后移至底部固定提示的 `call PlaceString` 后、`H_AUTOBGTRANSFERENABLED` 恢复前：

1. 不增加 `UpdateSprites` 调用次数，尽量保留 REF-358 的返回速度。
2. 不改 `TextBoxBorder` 坐标 (0,0; 0,12)、菜单文本、`PlaceString`、B-release gate、父菜单选择与其他流程。
3. 不修改 `BillsPCMenu`、`DisplayListMenuID`、`UpdatePlayerPCItemDescription` 或全局 `UpdateSprites`，不触碰道具/宝可梦数据和存档。
4. `data/game_version.asm` 升到 `REF-360@`，历史 REF-357/358/359 注释、弃用提问调用/包装器/正文继续留存。

## 静态检查 / 实机验收

- 专项测试确保调用恰好一次、严格处于底部提示绘制后且 BG 传输开启前，并保留 B-release gate / 子菜单 / Bill's PC 契约。这是**静态校验**，不替代设备实际渲染。
- 设备实测至少覆盖：从地图打开道具 PC；在 Withdraw/Deposit/Toss 按 B 逐个返回父菜单（含按住 B）；主菜单和底部提示的边框没有人物压上来、两框之间没有异常浮层；退出 PC 后地图人物正常；光标、道具说明、数量框均保持原行为。
- 实际构建需 Red/Blue/TEST Red/TEST Blue 和各自新 MAP，检查 ROM0 与 ROMX 空间；先 `git apply --check` 再应用候选补丁。旧 MAP、源码单元测试及补丁回放都不能证明四种构建和实机通过。
## 最终验收更新（2026-11-08）

- 用户明确确认上传的 `360.mp4` 是 REF-360 ROM 实测录像，并要求按当前工作区正式清理。录像覆盖的 Player PC 父菜单人物遮挡已消失；用户此前已确认 Withdraw、Deposit、Toss、数量确认及 Bill's PC 菜单不是本次异常页面。
- 本次 REF-360 清理不再修改运行 ASM、测试逻辑或 `REF-360@` 版本号，只补维护文档、验收记录和待办状态。
- 完整 pytest 与四种 ROM/MAP 的剩余边界见 `docs/CLEAN_REF360_PLAYER_PC_MENU_ACCEPTANCE.md`。
