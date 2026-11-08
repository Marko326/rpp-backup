# CLEAN REF-363｜双方训练师退场 7 行 tile-only 同步与颜色验收（合并 REF-361～363）

## 一、提交基线与本次范围

- 用户上传工作区补丁 `REF-363.patch`：`RPP-BASE=ab52a4620d5b262ede727d1a663995cf41192677`、分支 `常规功能备份`；它从已提交 CLEAN REF-360 累计至 REF-363。
- 用户确认撤回此前单独的 REF-362 提交，REF-361、REF-362、REF-363 的运行变化一笔 Commit 收口；不将中间开发版本虚构成两笔独立 Git 提交。
- `REF-363.patch` 共变更 18 个文件。对可复查的 CLEAN REF-360 源码核对，12 个已存在的变更文件的旧 Git Blob 与补丁一致；正向应用后 18 个新文件 Git Blob 与补丁一致。此核验不等于读取手机实际 Git HEAD；应用前仍需 `git apply --check`。

## 二、REF-360 → REF-363 的实际代码变更

1. `engine/battle/core.asm`：保留 `SlideTrainerPicOffScreen` 调用约定，通过 `hSlideAmount` 保存方向/步数、`DE` 保留原 HL 指针，将原入口桥接到浮动 ROMX `SlideTrainerPicOffScreen_Impl`。相关 Section 接入 `main.asm`。
2. `engine/battle/trainer_slide_atomic_361.asm`：玩家向左 9 步与对方向右 8 步，每步仍为 2 帧；每步完成图块移动后，各将 7 行 BG Tile ID 排队至同一次 VBlank。玩家处理 row 5～11，对方处理 row 0～6；两方向均在动画期间暂停 AutoBG 分三批刷新，并在函数退出时恢复原状态。
3. 两方向均用 `H_VBCOPYBGNUMROWS=$87`（7 行 + bit7 tile-only）保持 VBK 1 属性图不被覆盖。对方路径不再回退到旧分批刷新。
4. `home/vcopy.asm`：tile-only 每行复制 20 列、按 32-byte VRAM 行步进；低字节跨 `$xxFF->$xx00` 时向高字节进位。保留 HP 动画此前使用的 tile-only 分支。
5. `data/game_version.asm`：版本 `REF-360@` → `REF-363@`；不改 RGB555 调色板表、OAM 头部属性、入战白闪或战斗伤害流程。

## 三、REF-361 颜色回归原因（须长期保留）

REF-361 初版为 7 行原子更新使用了普通 `WindowTransferBgRowsAndColors`，该例程以源 Tile ID 索引 `W2_TilesetPaletteMap`。战斗 `SetPal_Battle_Common` 将 `W2_TileBasedPalettes=0`，本表此时对应屏幕坐标而非 Tile ID；因此普通例程可能将无关调色板索引写入 CGB VBK 1，出现玩家训练师或对方 Pokémon 局部绿色/粉红跳色。REF-362 改为 tile-only 并补跨页进位，REF-363 将相同保护扩展至对方训练师。不得直接套用中文工程另一套 Palette ID、颜色表、缓存同步或 loader。详见 `RPP_DEVELOPMENT_PITFALLS.md`。

## 四、录像与静态测试验收

- `363.mp4` 时长约 39.09 秒，录有三次对方训练师右退场，开始移动约在 10.77、21.01、32.37 秒。视频帧序列显示目标每次约右移 8 像素，间隔约 33 毫秒，三次均未见明显分行撕裂或训练师/对方 Pokémon 绿色、粉红色突变。
- `362.mp4` 已由用户测试男、女玩家的左退场及颜色；此前结论保留，但 REF-363 新录像没有重新穷尽所有男女玩家及对方训练师组合。
- 上传 REF-363 工作区全仓库 pytest：**908 passed, 35 failed, 196 skipped, 98 subtests passed**；35 项历史失败仍存在，不能报告全绿。REF-363 新增专项测试覆盖双方源/目标行、bit7 tile-only、队列使能顺序、步数、两帧间隔和 AutoBG 保存恢复。
- 录像与静态检查不能替代 ROM 编译/链接、MAP/Bank 空间或所有设备实机测试。

## 五、尚需由维护者归档

- Red、Blue、TEST Red、TEST Blue 四种 ROM/MAP 的最新构建记录；ROM0≥64B、固定 Bank `$0F` 与浮动 ROMX 空间检查。
- 用户自行依据真实 Termux 工作区状态选择 01 或 02 中唯一一份补丁，先 `git apply --check`，再应用并自行 Commit/可选 Push；助手不代操作。
