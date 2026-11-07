# REF-351B｜普通房门 CGB RGB555 统一渐暗

## 基线与范围

- 用户输入：最新 `REF-351B.zip`，源码模式为当前 Worktree。
- 分支：`常规功能备份`。
- 正式 Git HEAD：`30bbe52a96ffe8d8238159a855fa1b1002d7fee3`，HEAD 游戏版本为 `REF-350`。
- 当前游戏版本：`REF-351B`。
- 开发前置：REF-351A Worktree；本次清理冻结 REF-351B，不引入 REF-351C。
- 目标：只改善普通零偏移房门转场的 CGB BG/OBJ 渐暗观感；不改变原 Fade 阶段数与等待帧数。

## 实现

1. `PlayMapChangeSound` 只在普通 `wMapPalOffset == 0` 路径短暂置位 `hDoorwayCGBFadeActive`；Rock Tunnel offset 6、Johto Dark Cave offset 12 与其它 Fade 不启用。
2. `GBFadeDecCommon` 在发布下一组 BGP/OBP 寄存器值之前，先按目标 BGP 阶段准备对应 RGB555 缓冲区。随后用短暂 DI/EI 将 OBP1、OBP0、BGP 作为一个阶段原子提交。
3. RGB555 使用 Game Boy Color 的 5/5/5 通道布局：R 为 bits 0..4，G 为 bits 5..9，B 为 bits 10..14。F9 阶段每通道做 `floor(x*2/3)`，FE 阶段每通道做 `floor(x/3)`；E4 使用原调色板，FF 仍走既有全黑路径。
4. 2/3 与 1/3 使用两个互不重叠的 WRAM Bank 2 缓冲区。切换到 FE 时只写尚未显示的 1/3 缓冲区，当前 F9 帧继续读取 2/3 缓冲区，避免中断在预计算期间读到半成品。
5. F9/FE 阶段将 BG 与 OBJ 的软件灰度索引映射临时固定为 E4 身份顺序；否则“原 BGP/OBP 重映射 + RGB 缩放”会形成二次变暗和色相偏差。`SetColor` 按实际 BGP 阶段选择对应缩放缓冲区。原始 `W2_BgPaletteData` / `W2_SprPaletteData` 不修改。
6. 门房渐暗期间，VBlank 必须同时具备 BG 与 OBJ 的待提交标志，并在一次时间预算检查后连续提交两组64字节缓冲区，再一起清除标志，避免两个平面出现不同渐暗阶段。
7. RGB555 两张32项通道表位于单体 `bank2C` Section 内。最终实现不要求表页对齐：在 WRAM Bank 2 保存完整16位表基址，R/G/B 三通道分别设置索引偏移并通过 `add hl,de` 查表。

## 与 REF-350 / REF-351A 的组合关系

- REF-350：普通房门目标地图加载期间保持 LCD 开启；BG Tile 与 CGB Attribute 暂存到 WRAM Bank 2；每行前16字节使用 HBlank DMA，末尾4字节按 VRAM 可访问模式安全写入；保留12个非显示列及原有 Bank 恢复顺序。
- REF-351A：仅当 `hMapLoadVRAMSafeFlag` 生效且目标地址在 `$8000-$9fff` 时，`CopyData` 使用 LCD-safe 双字节窗口；奇数长度先处理单字节，剩余成对复制。非 VRAM 目标与 LCD-off 路径不变。
- REF-351B：在普通门 Fade 阶段对 CGB BG/OBJ RGB555 颜色做统一通道缩放。
- 不把 REF-351A 的双字节 CopyData 与 Attribute+Tile 两平面四写合并；不恢复历史双格 HBlank 四写试验。

## 保持不变

- `GBFadeOutToBlack` 仍为4阶段、每阶段8帧。
- 普通房门音效、LCD-on 安全加载、CGB Attribute/Tile 配对上传与旧地图刷新保护不变。
- DMG/非门房 Fade 不启用 RGB555 缩放。
- Rock Tunnel、Dark Cave、Flash、Warp Pad、战斗回图等特殊路径保持原实现。
- 不改 SRAM/存档布局。

## RGBDS 0.5.2 汇编阻塞记录

用户曾提供两次 `make red` 错误日志：

1. `ALIGN $100` 报 `Alignment must be between 0 and 16, not 256`。这是把字节数误当作 RGBDS 的对齐指数。
2. 改为 `ALIGN 8` 后，`color/vblank.asm` 在单体 `SECTION "bank2C"` 的偏移 `$1f6c` 报 `Section's alignment fails required alignment`。该 Section 已经在更早位置开始，不能在此处依靠内联 `ALIGN 8` 满足表页对齐。

最终源码处理方式：

- 删除两张表前的内联 `ALIGN` 和依赖页对齐的 `LOW(...) == 0` ASSERT。
- 在 WRAM Bank 2 `$D089-$D08A` 保存完整16位表基址。
- 三个 RGB 通道分别设置索引偏移，通过 `add hl,de` 查表。
- 缩放表数值、RGB555 算法、Fade 节奏和地图行为不变。

**当前源码已不再使用这两处查表页对齐；但本轮没有运行 RGBDS 0.5.2 汇编/链接，不能宣称上述错误已由实际构建验证消失。** 用户仍需在本机重新构建。

## 当前静态验证记录

### 门房与相关运行合同

执行：

```sh
python -m pytest -q -rs \
  tools/tests/test_doorway_cgb_rgb555_fade_351b.py \
  tools/tests/test_doorway_lcdon_copy_pair_351a.py \
  tools/tests/test_doorway_lcdon_upload_350.py \
  tools/tests/test_johto_dark_cave_stage2.py \
  tools/tests/test_johto_dark_cave_stage_349.py \
  tools/tests/test_johto_gate_music_bike_259.py \
  tools/tests/test_johto_audit_phase.py
```

结果：`84 passed, 1 skipped`。唯一 skip 需要独立 Gold 源码根目录。RGB555 专项测试穷举全部32768个有效颜色，并覆盖双缓冲误复用、Fade flag 未清除、索引映射错误等负向注入。

### 本轮修改过的工具/审计测试

执行：

```sh
python -m pytest -q -rs \
  tools/tests/test_alph_south_field_hotfix_256.py \
  tools/tests/test_alph_south_runtime_254.py \
  tools/tests/test_doorway_cgb_rgb555_fade_351b.py \
  tools/tests/test_doorway_lcdon_copy_pair_351a.py \
  tools/tests/test_johto_audit_phase.py \
  tools/tests/test_johto_batch_centers_336.py \
  tools/tests/test_johto_burned_tower_1f_347.py \
  tools/tests/test_johto_connected_music_243.py \
  tools/tests/test_johto_fly_visit_280.py \
  tools/tests/test_johto_lake_of_rage_321.py \
  tools/tests/test_johto_park_activation_286.py \
  tools/tests/test_johto_route35_runtime_audit_283.py \
  tools/tests/test_johto_save_location_name.py \
  tools/tests/test_johto_west_corridor_runtime_gate_297.py \
  tools/tests/test_save_tileset_reload_244.py
```

结果：`131 passed, 6 skipped, 4 subtests passed`。跳过项需要未随本 ZIP 提供的独立 Gold 源码。

### 强制静态预检

- `python tools/asm_symbol_preflight.py`：1850 个 ASM 文件局部符号预检通过。
- `python tools/johto_table_assert_preflight.py`：`NUM_JOHTO_ACTIVE_MAPS=64`；Town Map、Browse Index、GSC Music 三张表长度 ASSERT 通过（256/256、64/64、64/64）。
- `python tools/johto_pilot_migration_audit.py --project .`：`PASS_STATIC_ONLY`，1538/1538；当前没有独立 Gold 参考根目录，`gold_reference=null`。
- `python tools/johto_rom0_space_preflight.py`：`PASS_STATIC_ONLY`，无静态问题；明确要求用户侧新构建/链接后再验 ROM0。

### MAP 空间证据

- ZIP 附带 `patches/rppred.map`，导出记录标记 MAP 版本为 `REF-351B`，为 Red MAP。
- MAP 报告 ROM0 剩余 `252 B`，高于项目最低 `64 B`。
- ROMX Bank `$2A` 剩余 `15001 B`；Bank `$2C` 剩余 `771 B`。
- 以上仅为 ZIP 附带的 Red MAP 证据；本轮没有同版 Blue/TEST MAP，也没有助手执行 RGBDS 汇编/链接，因此不能推断 Blue/TEST 空间或完整构建成功。

### 未执行与未验收

- 全仓库 pytest 本轮未完成；不声明全量测试全绿。
- 未运行 `rgbasm` / `rgblink`，未执行 `make red` / `make blue` / TEST 构建。
- 未生成新的 Red/Blue/TEST ROM 与 MAP。
- 未做本轮手机/模拟器录像验收；RGB555 颜色观感、VBlank 实际时序、BG/OBJ 同步和音频连续性仍需用户设备确认。

## 用户最小复测范围

1. 用 RGBDS 0.5.2 分别构建 Red、Blue、TEST；确认汇编/链接成功并提供同版 MAP。
2. 确认三种构建 ROM0 均至少保留64B，并检查 `$2A`、`$2C` 等相关 ROMX Bank。
3. 普通室外→室内、室内→室外各至少3次；检查没有白闪、单帧跳色、BG/OBJ 不同步或地图残留。
4. 覆盖不同 Tileset、Gold/Snowy 屋顶、玩家与 NPC 精灵调色板。
5. 连续进出门检查音乐/音效；再覆盖 Rock Tunnel、Dark Cave、Flash、Warp Pad、战斗回图及旧存档。

**状态：** REF-351B 已整理为稳定源码基底，等待用户本机 RGBDS 构建与设备验收；这不等于 ROM 已正式验收。
