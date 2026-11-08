# REF-363 开发过程记录（已并入 CLEAN REF-363）｜双方训练师退场统一为 7 行 tile-only 原子刷新

## 输入与范围

- 开发时曾按 CLEAN REF-362 源码设计增量；用户随后撤回 REF-362 的单独提交，并上传 `REF-363.patch`，该最终工作区补丁明确从已提交的 REF-360 HEAD `ab52a4620d5b262ede727d1a663995cf41192677` 累计至 REF-363。本轮只按上传补丁的真实基线制作合并 CLEAN。
- 用户指出：上一版提交日志中明确写了“敌方训练师向右退场保持原路径”，这意味着对方训练师退场没有获得 REF-361/362 的 7 行原子刷新。本版把同一保护扩展到对方训练师。
- 仅修改 `SlideTrainerPicOffScreen_Impl` 的退场刷新策略和相应静态测试/维护文档。保留玩家 A=9 向左 9 步、敌方 A=8 向右 8 步、每步 2 帧、原跨 Bank ABI 和浮动 ROMX 位置。

## 代码实现

- 两个方向在循环开始前都保存 `H_AUTOBGTRANSFERENABLED` 原值并置 0，避免 AutoBG 的分批刷新与逐步滑动竞争；循环结束后恢复保存值，不假设原值必定为 1。
- 每次 tilemap 水平移动后，双方都排队 `H_VBCOPYBGNUMROWS=$87`，即 7 行 + bit7 tile-only；source LOW byte 最后写入，作为 VBlank copy 的使能动作。
- 玩家训练师位于 BG row 5..11：从 `coord(0,5)` 读取，VRAM 目标 low offset 为 `5 * BG_MAP_WIDTH`。
- 对方训练师位于 BG row 0..6：从 `coord(0,0)` 读取，VRAM 目标 low offset 为 `0`。
- 两方向都只复制 BG Tile ID，不走 `WindowTransferBgRowsAndColors`，不写 VBK 1，保留战斗已建立的屏幕坐标 CGB 属性图。
- 玩家 row 5..11 的 tile-only 目标行仍依赖 REF-362 已加入的 `$xxFF->$xx00` 高字节进位；敌方 row 0..6 不跨页。现有 HP tile-only row2/9/10 行为不变。
- 不新增 HRAM/WRAM，不修改 VBlank 服务、调色板体系、训练师图形/OAM、入场动画、战斗 HUD、敌方移动方向/步数或其他菜单。

## 静态测试

- `tools/tests/test_ref363_both_trainer_atomic_exit.py` 已扩展为双方路径合同检查：方向调用 A=9/A=8、源/目标行、`$87` tile-only、source enable-last、双方 AutoBG 保存/恢复、每步两帧、玩家跨页进位及敌方 row0..6 目标地址。
- 双方退场专项测试：**10 passed**；加上 3 个历史门口 RGB555 / LCD-on copy 版本回归测试，相关测试合计 **30 passed**。三个历史测试只同步更新 `REF-363@` 版本断言，没有改运行逻辑。
- 完整 pytest：**908 passed, 35 failed, 196 skipped, 98 subtests passed**。与 REF-362 基线比较，失败测试标识集合相同，没有新增失败。
- 静态 pytest 不等于 RGBDS 汇编/链接，也不能证明真实 CGB 设备逐帧无撕裂/无跳色。

## 用户录像验收与剩余边界

- `363.mp4` 的三次对方训练师右退场已复核：可见位置约每 33 毫秒右移 8 像素，未见明显头身不同步或局部绿色/粉红色异常。先前玩家左退场的 `362.mp4` 男女录像验收结果保留。
- 这段录像只覆盖所录的对方训练师及对方宝可梦组合，不把其他性别、其他训练师或全部战斗 HUD 情形自动标记通过。
- 维护者仍需在真实 Termux 仓库构建 Red / Blue / TEST Red / TEST Blue，归档最新 MAP，检查 ROM0≥64B、固定 Bank `$0F` 与浮动 ROMX 空间。
- 用户录像检查后已制作 CLEAN REF-363 三件套；助手不代编译/链接 ROM，也不 Commit/Push。
