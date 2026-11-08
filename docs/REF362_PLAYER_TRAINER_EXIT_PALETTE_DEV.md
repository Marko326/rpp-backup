# REF-362 中间开发阶段记录（独立提交已撤回）｜玩家训练师左退场 CGB 属性保护

> 历史边界：REF-362 只覆盖玩家向左退场；对方训练师向右退场仍使用旧的 AutoBG 分批刷新。REF-363 最终合并版本也已将对方路径改为 7 行 tile-only 原子刷新，见 `docs/REF363_BOTH_TRAINER_EXIT_DEV.md`。

## 输入与边界

- 基线：`REF-361_完整工程_开发候选.zip`。用户上传 `361女性.mp4`，并指出玩家左退场时披风/头部和对方 Pokémon 局部出现绿色、粉红色异常。
- 中文历史 #012 `c6685bf5` 只用于了解问题由哪些子功能构成。用户明确要求不直接移植中文工程的调色板方案，因为它与 REF 的颜色体系不同。本次不复制中文工程的 Palette ID、颜色表、缓存同步或 loader。
- 只修 REF-361 退场时的 CGB 属性覆盖问题。保留 REF-361 已实现的玩家左退场 7 行单 VBlank 图块更新、每步 2 帧、9 步移动、敌方右移原路径及 BG 自动刷新状态恢复。

## 源码根因

1. `color/color.asm::SetPal_Battle_Common` 将 `W2_TileBasedPalettes` 置 0，并对 `W2_TilesetPaletteMap` 按战斗屏幕坐标填充：玩家 Pokémon 区域 palette 0、敌方 Pokémon 区域 palette 1、双方 HP/文本区各自使用固定 palette。该模式不是 tile-ID 查表。
2. `color/refreshmaps.asm::WindowTransferBgRowsAndColors` 的 palette 复制逻辑会从源 TileMap 取 Tile ID，再用 Tile ID 作为索引读取 `W2_TilesetPaletteMap`。这与战斗的屏幕坐标 palette map 不兼容。
3. REF-361 的玩家退场原子刷新使用 `VBlankCopyBgMap` 普通行复制模式，最终进入 `WindowTransferBgRowsAndColors`，因此除了复制 7 行 tile ID，还可能把错误的 palette index 写入 VRAM 的 VBK 1 属性图。用户视频中的颜色跳变发生在玩家开始退场时，时间点与这次额外属性复制吻合。
4. 该退场操作只改变 `wTileMap` 的 tile ID，不改变 palette 区域归属；正确做法是保留已经建立的 CGB 属性图，只上传 tile ID。

## 实现

- `engine/battle/trainer_slide_atomic_361.asm`：玩家路径将 `H_VBCOPYBGNUMROWS` 设为 `$87`（7 行 + bit7 tile-only），仍然先清空源 LOW enable，再填源高位/目标/行数，最后写源 LOW 使能。
- `home/vcopy.asm`：扩展既有 bit7 tile-only 分支。每行复制 20 个可见 tile，按 VRAM 的 32-byte row stride 跳过 12 个屏外 tile；当 `L + 12` 溢出时 `inc h`，支持玩家从 row5 开始复制 row5..11 时跨 `$xxFF->$xx00`（目标高字节可为 `$98` 或 `$9c`）。不切换到 VBK 1、不调用 `WindowTransferBgRowsAndColors`，因此不会覆盖 CGB 属性图。
- 既有 HP 动画 tile-only 使用 row2/9/10，不跨页；新增进位只在发生低字节溢出时生效，不改变旧调用地址序列。
- 不修改 `LoadPlayerBackPic` 的 OAM 属性字节，不修改 `LoadBlackPalettesWhileLCDOff`、`SetPal_Battle_Common`、RGB555 表或 palette loader；敌人右退场仍使用原路径。
- `data/game_version.asm` 升级为 `REF-362@`。源码、专项测试、FEATURES/TODO、PROJECT_DELIVERY_RULES、DEVELOPMENT_PITFALLS 与本文件一并交付。

## 回归与验收

- 静态测试检查：战斗 palette map 采用 screen-coordinate 模式；退场必须使用 `$87` tile-only；bit7 分支不访问 VBK 1/不调用普通属性复制 helper；7 行跨页时必须给目标高字节进位；错误行数和移除进位的故障注入应失败。相关定向测试 `40 passed, 1 skipped`。
- 完整 pytest：`908 passed, 35 failed, 196 skipped, 98 subtests passed`。REF-361 基线为 `881 passed, 60 failed, 196 skipped, 98 subtests passed`；失败节点集合新增 0、旧失败解除 25（主要是当前 REF 版本号/规范注释同步），但仍有 35 项历史失败，不能宣称全仓库全绿。
- 静态测试不等于 RGBDS 汇编/链接、MAP 空间或实机颜色验收。助手不编译 ROM、不 Commit/Push。
- 用户已提供 `362.mp4`，并确认男主角、女主角均已实测；本轮录像观察未再发现此前的绿色/粉红局部跳色，玩家左退场流畅度保持。该结果仅覆盖录像实际展示的设备、战斗与精灵组合。
- Red/Blue/TEST Red/TEST Blue 最新 ROM/MAP、ROM0≥64B、Bank `$0F` 与浮动 ROMX 空间仍需维护者在真实工作区归档；本轮没有收到这些构建产物，不将其标记为通过。
- 正式 CLEAN 三件套已按项目规则制作；用户自行在真实工作区 `git apply --check`、应用并 Commit/可选 Push，助手不代执行 Git 操作。
