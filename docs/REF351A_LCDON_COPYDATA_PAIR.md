# REF-351A｜LCD 开启期间的双字节安全 VRAM 复制

## 基线与目标

- 正式 Git 基线：`30bbe52a96ffe8d8238159a855fa1b1002d7fee3`（REF-350，干净 HEAD）。
- 本轮候选：`REF-351A`。
- 参考：用户提供的 REF-350G 双字节安全复制补丁及其视频测试日志。
- 目标：把 350G 已实测观察到收益的 `CopyData` 双字节安全窗口方案移植到当前 REF-350；不直接应用旧 HEAD 全量补丁。

## 实现范围

- `home/copy.asm`：仅当 `hMapLoadVRAMSafeFlag` 生效且目标起始地址位于 `$8000-$9fff` 时进入 LCD-on VRAM 安全路径。奇数长度先单字节处理，剩余长度按两个连续字节计数；每个 STAT mode 0/1 窗口最多写两个相邻字节。非 VRAM 目标与 LCD-off 路径保持原单字节快速复制。
- 保留 `FarCopyData` / `FarCopyData2` 的 ROM Bank 保存和恢复入口；不改 SP，不改调用者寄存器/栈合同。
- `color/refreshmaps.asm`：只将 HBlank DMA 末尾4字节安全写入轮询改为 `ldh a,[rSTAT]`，保留现有双平面暂存、16字节 HDMA、末尾4字节逐个等待及12列不写的结构。
- `data/game_version.asm`：开发候选标记 `REF-351A@`。

## 安全前置条件

- `InitGbcMode` 在进入普通地图游戏循环前请求并切换 CGB double speed；普通房门淡黑后才设置 `hMapLoadVRAMSafeFlag`。
- 双字节写入仅在 STAT mode 0/1 后进行；两个相邻字节写入总共为两组 `LD A,[HL+]`、`LD [DE],A`、`INC DE`，不包含 SP 改写。
- 在 CGB double speed 下，两个字节的读/写/地址递增指令预算约24 dots；加上 STAT 判定仍低于最短 HBlank 的保守窗口预算。此为指令周期静态估算，必须由目标模拟器/设备确认。
- 该优化不改变 `LoadMapVramAndColors` 的 CGB Attribute + Tile 配对逻辑，不恢复 350E 的双格四写试验。

## 预期收益与边界

- REF-350G 日志记录，普通门加载中 `$600` 字节 Tileset 图形复制的安全窗口等待由最多1536次降至768次；视频黑屏驻留时间观察到进门24帧、出门28帧，较350F分别减少2/3帧。
- 这些是 REF-350G 的历史视频证据，不是本轮 REF-351A 的实测结果。
- 本轮尚未改变属性地图缓冲区生成方式；该项作为后续独立优化，先避免把两类性能变化混在同一轮。

## 验证边界

- 新增源级合同测试覆盖 VRAM 目标门控、奇数/偶数长度、双字节写入窗口、FarCopy Bank wrapper、现有行 DMA/属性配对不变、CGB double-speed 前置及版本标记。
- 当前 REF-350 MAP 的 ROM0 剩余313B；350G 同一 `CopyData` 变更的指令长度静态估算净增约26B；版本字符串另增加1B，因此本轮 ROM0 余量估算约286B，仍高于64B门槛。`color/refreshmaps.asm` 的 `ldh` 替换位于 ROMX，预计减少1B。以上不是新链接 MAP 结果。
- 不编译/链接 ROM，不生成新 MAP，不执行 Git Commit/Push。
- 必须由用户本机 Red/Blue/TEST 构建新 ROM/MAP，确认 ROM0 至少64B及相关 ROMX Bank 余量；本轮 ROM0 增量是静态指令长度估算，不可替代新 MAP。
- 实机复测普通门进出、同/跨 Tileset、Snowy/Gold 屋顶、玩家精灵、音乐连续性、旧存档，以及 Dark Cave / Rock Tunnel / Warp Pad / 战斗回图的原路径。

## 本轮实际执行记录（静态）

- `python tools/asm_symbol_preflight.py`：1850 个 ASM 文件局部符号预检通过；不代表 RGBDS 编译或链接。
- `python tools/johto_table_assert_preflight.py`：`NUM_JOHTO_ACTIVE_MAPS=64`，3张 Town Map / Browse / Music 表长度 ASSERT 全部通过。
- Gold 源码可用时的相关回归组：187 passed、2 deselected、4 subtests passed。两项 deselected 是旧 Route43 正向审计门；当前基线和本轮都保留同样的3项旧失败（`ID66_closed_NSEW_bounds`、`profile_bytes_accounted`、`gate_music_source_record_and_validation`），本轮 `version_label_keeps_fixed_width` 已修正并通过。
- `tools/johto_pilot_migration_audit.py --project . --gold-root <Gold root>`：1711/1715。相对当前 REF-350 基线的1707/1715，4个旧版本号锁已改为接受当前带单字母测试后缀的 REF 标签；仍有4项与本轮无关的既有失败：Route34/Goldenrod边界、Route44边界、Blackthorn City边界，以及Gold地下城批次资源语义登记不完整。
- `test_alph_south_runtime_254.py` 的全局迁移审计包装测试仍会因上述4项全局审计失败而失败；它不是本轮 CopyData 变化的专项失败。没有将此包装测试伪报为通过。
- REF-350G 参考日志与旧增量补丁均已核对；把旧增量补丁应用到 REF-350F 后，`CopyData` 的指令主体与本轮移植结果逐条一致（忽略版本注释），确认移植的是双字节安全窗口实现，而不是重新设计的另一套循环。
- 没有编译/链接 ROM，没有生成新 MAP，没有执行 Git Commit/Push，也没有设备视频。本轮所有性能收益仍需用户本机编译与同设备/同帧率录像验证。
