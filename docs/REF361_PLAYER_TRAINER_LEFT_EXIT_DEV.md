# REF-361 开发候选｜玩家训练师向左退场 7 行同步刷新（仅 #012 子功能）

> **历史记录提示：** 本文前述实现描述的是 REF-361 初版。用户随后在 `361女性.mp4` 中发现玩家左退场时训练师及对方 Pokémon 的局部颜色异常；REF-362 已将下方提到的普通属性复制路径改为 tile-only，当前正确实现与原因见 [`REF362_PLAYER_TRAINER_EXIT_PALETTE_DEV.md`](REF362_PLAYER_TRAINER_EXIT_PALETTE_DEV.md)。

## 输入依据与边界

- 中文历史提交 #012 `c6685bf5` 在 `ROM-1.44` 的 `src/engine/battle/core.asm::SlideTrainerPicOffScreen`：按玩家 `A=9` 与敌人 `A=8` 分流。玩家左退场前保存并暂停自动分三次 BG 刷新，每个移动步完成后在一个 VBlank 提交完整 7 行；敌人右退场保留原 `DelayFrames(2)`。
- 英文基线取**已经准备 CLEAN、用户确认已经提交**的 REF-360 源码快照 (`ref360_verify_01`)，而不是历史 CHS 提交导出的英文仓库，也不假装拥有用户提交后的新 HEAD 哈希。若本机工作区另有改动，必须先 `git apply --check`，不允许强行覆盖。
- 这次只实现 **#012 的玩家左移撕裂子项**。历史 #012 的背影 OAM 头部属性、Battle Window 揭屏顺序属于独立差异；REF 已有 `LoadBlackPalettesWhileLCDOff` 入战白闪处理，均不触碰。

## 运行代码变动

1. `engine/battle/core.asm::SlideTrainerPicOffScreen` 原入口名称、两个调用处和旧指令的注释历史保留。在原来接近塞满的 ROMX Bank `$0F` 中只保留远跳转桥接：先将输入 `A` 存入现有 `hSlideAmount`，输入 `HL` 放入 `DE`，再 `jpab SlideTrainerPicOffScreen_Impl`。**不能直接裸用 `jpab`**：`Bankswitch` 会占用 `A/BC/HL`，否则源 TileMap 指针和方向都会损坏。
2. 在 `main.asm` 添加浮动 ROMX Section `Player Trainer Slide Atomic 361`，包含新文件 `engine/battle/trainer_slide_atomic_361.asm`；不增加固定 Bank `$0F` 代码体积。新实现恢复 `HL=DE`，从 `hSlideAmount` 读取左右判断，继续使用原 7 行、9/8 列的逐格移动算法。
3. 仅 `A=9` 的玩家路径，在开始前保存 `H_AUTOBGTRANSFERENABLED` 并置零。每步图块修改结束后，对 `coord hl,0,5` 的 `wTileMap` 行 5～11 通过项目已有的 `H_VBCOPYBGSRC` / `H_VBCOPYBGDEST` / `H_VBCOPYBGNUMROWS=7` 排队，在 **下一次 VBlank 一次完成**。先将源 LOW 清零，填写源高位、目标和行数，最后填写源 LOW 使能；然后 `DelayFrame + DelayFrames(1)`，总计维持原每步 2 帧。
4. REF-361 初版的 `A=8` 敌人路径保持原普通两帧等待；玩家完成 9 步后恢复原 BG 值。初版曾保留 `H_VBCOPYBGNUMROWS` 正常复制模式；这条路径后来被证明会用 Tile ID 查找屏幕坐标调色板图，已在 REF-362 改为 tile-only 并补齐跨页进位。此处仅记录 REF-361 的历史实现，不作为当前复制模式说明。
5. `data/game_version.asm` 等长升到 `REF-361@`。既有 `home/vblank.asm`、`home/vcopy.asm`、`hram.asm`、`wram.asm`、CGB 颜色、HP 动画和其他战斗路径均未改动。

## 回归校验 / 证据限制

- 静态测试 `tools/tests/test_ref361_player_trainer_atomic_exit.py` 核对桥接 ABI、玩家/敌人分流、VBlank 全 7 行使能顺序、2 帧步长、BG 状态保存恢复、原 8/9 调用方和相邻颜色/HP 路径；包含错误行数/使能顺序故障注入。`tools/tests/test_ref360_player_pc_sprite_clipping.py` 的旧版本号断言改为“当前版本不低于360”，其余 PC 契约不变。
- **这是源码候选，不是设备实测通过，也不是 RGBDS 编译通过。** 遵循项目规则，本助手不编译 ROM、不过账新 MAP、也不 Commit/Push。本次不提前做 CLEAN 三件套；用户实测后再收口。
- 手机须重编 Red / Blue / TEST Red / TEST Blue、检查 MAP 的 ROM0≥64B 及固定 Bank `$0F`、浮动 ROMX 空间；使用训练家战斗和野外战斗分别观察首次玩家向左退出画面，**逐帧确认 7 行头/身一起移动、不被切割**。确认敌方右退场仍然正常、每步节奏一致，进入战斗不出现旧白闪，战斗 HUD 和地图退出恢复正常；尽量覆盖 CGB/DMG 与旧存档。无需测试完全无关的菜单或战斗伤害改变。

## REF-362 后续修正说明
- 用户明确指出中文版历史 #012 的调色板系统与 REF 当前实现不同，不能直接移植颜色表、Palette ID 或缓存同步逻辑。
- `361女性.mp4` 在玩家开始左退场时出现女训练师局部粉红/绿色跳色，并伴随对方 Pokémon 局部绿色。静态源码核对发现 REF-361 的普通 `WindowTransferBgRowsAndColors` 会按 Tile ID 索引 `W2_TilesetPaletteMap`，而战斗使用 `W2_TileBasedPalettes=0` 的屏幕坐标 palette map。
- REF-362 改为 tile-only 7 行复制，只更新 tile ID，不碰 VBK 1 属性；同时给 bit7 tile-only 服务加 32-byte VRAM row stride 跨页进位。版本升为 `REF-362@`。这是一项 REF 内部颜色属性保护，不是移植中文版调色板实现。
