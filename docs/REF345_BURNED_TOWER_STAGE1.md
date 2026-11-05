# REF-345｜烧焦塔 Gold 双层资源与落洞安全门禁（第一阶段，不开放）

**基线**：用户新包 `REF-344.zip` 的干净 Git HEAD `02a65db8343abb34cae9edbb2d23fe73d9da9578`，分支 `常规功能备份`。`REF-344` 已清理双提交，**不能再以旧的 REF-338 HEAD 制作本轮补丁**。

**本批实际完成**：从随附的 pret Gold 源码冻结烧焦塔 1F/B1F 的原版 10×9 `.blk`、16×16 cell 角色网格（每层 360 格）、原版 8×8 图像、64×16 metatile 表及 Gold 原始 palette map。素材存放在 `maps/johto_pilot/BurnedTower*.{gold,runtime}.blk`、`*.gold_roles.bin`、`gfx/tilesets/johto_burned_tower_*.png`、`gfx/blocksets/johto_burned_tower_*.bst` 与 `color/tilesets/*.gold_palette.asm`。这些是**待接入资源**，并未写入 `main.asm` 或 Tilesets/Header/Warp 表；palette 源文件还未变换为 RPP 运行颜色合同。

**原版语义，不可简单复制 Union Cave**：

- 1F `TILESET_TOWER / PALETTE_DAY / border $00`：14 条 Gold Warp，其中 2 个 DOWN-only 出口、11 个 `PIT`（踏入即坠层）、1 个 `LADDER`（踏入即换层）。
- B1F `TILESET_CAVE / PALETTE_DAY / border $09`：6 条 Gold Warp；前 5 条为**落点记录，不是可触发返回点**（FLOOR、HOP_LEFT、HOP_DOWN、FLOOR、FLOOR），只有第 6 条为真正的 LADDER 返回。B1F 另有 26 UP_WALL、29 HOP；Gold B1F `(17,4)` 还有怪力石头，后续直接复用 REF-344 已验收的 Strength 机制。
- 不能把 B1F 改成 Union Cave 固定 `NITE`，也不能把 1F 的 PIT 当普通 LADDER、WARP_CARPET_DOWN 或不可行走墙。Gold cave 原 metatile 表有不在图中使用的 `>=96` tile 索引：阶段素材原封保留；未来注册运行 tileset 前须只处理实际引用的 8×8 图块并校验 VRAM 容量。

**强制保持关闭**：稳定 ID 177/178 仍是 `JOHTO_INVALID_ACTIVE_SLOT`；活动地图 **61**，注册 Warp **144**，游戏显示 **REF-344**，没有新增游戏 ASM、ROM0 或 ROMX 代码。正式开塔至少还需：独立 DAY/TOWER 图块与调色、B1F DAY 洞穴图块、11 PIT → B1F 五个真实落点、安全落洞动画/音效、方向墙与 HOP、两层双向楼梯、圆朱市入口；剧情 NPC/敌人/道具独立延期。逐层验收，不在上层未完时开放入口。

**离线复核**（使用 Gold 源码的真实解压目录）：

```sh
python tools/johto_burned_tower_345.py --gold-root /path/to/pokegold-master
RPP_GOLD_ROOT=/path/to/pokegold-master python -m unittest discover -s tools/tests -p 'test_johto_burned_tower_345.py' -v
```

前者验证两张地图共 720 个角色格、20 个 Warp 以及全部冻结资源逐字节等同 Gold，并拒绝提前激活；后者含坏角色格、错误 PIT、错误 B1F 触发、提前开放、错误美术等故障注入。**静态 PASS 不等于已经能玩、ROM/手机通过**。未编译 ROM，未 Commit/Push。
