# REF-362 阶段性验收记录（独立提交已撤回，合并至 CLEAN REF-363）

> 本记录保留 REF-362 当时的录像与源码核对事实；用户随后撤回 REF-362 的独立提交，本轮 REF-361～363 合并在 CLEAN REF-363 中提交。这里的旧清理方案不作为当前补丁应用指南。

## 1. 基线与版本

- 功能基线：CLEAN REF-360。
- REF-361：新增玩家训练师向左退出时 7 行图块单次 VBlank 更新；用户录像确认移动更流畅，但随后发现玩家及对方 Pokémon 局部颜色异常。
- REF-362：游戏版本 `REF-362@`，保留 REF-361 的移动刷新方式，修正其 CGB 属性复制路径。
- 本轮不直接移植中文历史 #012 的调色板表、Palette ID、缓存同步或 loader；只沿用 REF 自己的 RGB555、`W2_BgPaletteData`、`W2_SprPaletteData` 和 VBlank palette pipeline。

## 2. REF-361 回归原因

REF-361 为了让玩家训练师的 7 行图像在同一次 VBlank 完整更新，使用了普通 `WindowTransferBgRowsAndColors` 属性复制路径。该路径在本项目的战斗画面中并不适用：

1. `color/color.asm::SetPal_Battle_Common` 将 `W2_TileBasedPalettes=0`，并按屏幕坐标建立 20×18 palette map。
2. `color/refreshmaps.asm::WindowTransferBgRowsAndColors` 却把源 Tile ID 当作索引读取 `W2_TilesetPaletteMap`。
3. 两种数据语义不一致。REF-361 的普通复制会把错误 palette index 写入 BG 属性 VRAM（VBK 1），导致玩家披风/头部和对方 Pokémon 局部出现绿色或粉红色跳变。

这次问题是 REF-361 的复制路径选择错误；不是中文工程颜色方案的问题，也不是用户设备调色板需要改成中文版实现。

## 3. REF-362 代码修复

- `engine/battle/trainer_slide_atomic_361.asm`：玩家左退场将 `H_VBCOPYBGNUMROWS` 设为 `$87`（7 行 + bit7 tile-only），只更新 BG Tile ID，不重写已经建立的 CGB 属性图。
- `home/vcopy.asm`：tile-only 每行复制 20 个可见 Tile，VRAM row stride 为 32 字节；补充 `$xxFF->$xx00` 时目标高字节进位，支持从 row 5 开始的 7 行复制。
- 保留玩家左退场 9 步、每步 2 帧、BG 自动刷新状态保存/恢复；敌方训练师向右退场仍走原路径。
- 不修改 `LoadPlayerBackPic` 的 OAM 属性字节、入战白闪、Battle Window、RGB555 调色板 loader、其他菜单或宝可梦战斗逻辑。
- 游戏版本由 `REF-361@` 升为 `REF-362@`。

## 4. 自动化验证

- REF-362 定向静态测试：**40 passed, 1 skipped**。
- 完整 pytest：**908 passed, 35 failed, 196 skipped, 98 subtests passed**。
- REF-361 完整工程基线：881 passed, 60 failed, 196 skipped, 98 subtests passed；REF-362 未新增失败，解除 25 项旧失败。仍有 35 项历史失败，不得写成全仓库全绿。
- 静态测试检查 tile-only 模式、属性图不被写入、7 行跨页进位及故障注入；它不替代 RGBDS 编译/链接和设备测试。

## 5. 用户实机验收

- 用户提供 `362.mp4`，明确确认男主角和女主角均已测试。
- 对照此前 `361女性.mp4` 的绿色/粉红局部跳色，`362.mp4` 中未再观察到相同异常；玩家披风/头部及对方 Pokémon 的颜色在录像覆盖场景中保持正常。
- 玩家左退场的流畅度保持；没有观察到此次 tile-only 修复使 REF-361 的移动效果回退。
- 本结论只覆盖 `362.mp4` 中实际展示的设备、战斗与精灵组合，不外推为所有硬件、所有战斗组合均已穷尽验证。

## 6. 尚未归档的构建证据

- 本轮未由助手编译/链接 ROM，未生成新的 Red、Blue、TEST Red、TEST Blue ROM/MAP。
- 四种构建的 ROM0≥64B、固定 Bank `$0F` 和浮动 ROMX 空间仍需维护者在真实工作区归档。
- 用户自行应用补丁、检查 Git 状态并 Commit/可选 Push；助手不代执行 Git 操作。
