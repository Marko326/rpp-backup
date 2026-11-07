> **后续正式清理状态（2026-11-07）**：本文件记录历史 REF-351C 开发候选。用户审阅 `351C.mp4` 表示满意后，按项目正式版本规则收口为 **REF-352**，核心游戏路径保持候选行为；正式基线、录像量化、补丁回放和未验证边界以 [`CLEAN_REF352_DOORWAY_FAST_COPY_ACCEPTANCE.md`](CLEAN_REF352_DOORWAY_FAST_COPY_ACCEPTANCE.md) 为准。用户本轮特别指定第一批将功能、版号与全部三份工具测试脚本一起提交，第二批仅提交文档。以下“未验收”是候选阶段的历史状态，不等于用户未认可当前录像表现。

# REF-351C 开发候选 1：普通房门图形上传缩短等待（未实机验收）

## 唯一输入基线与交付状态

- 用户于 2026-11-07 上传的 `REF-351B.zip`，导出记录显示干净 HEAD `2d3942cfddfb22e7568e842bc29d800b5c4ac8b3`（不含 `.git`，该 HEAD 仅以导出信息核实）。
- 现有版本 `REF-351B@`；本开发候选游戏内版本等长升级至 `REF-351C@`。
- **开发候选，不是已达到 13/14 帧的产品成果；未编译 ROM、未链接、未实机验收，也不提交 Git。**
- 当前基线未有未提交改动，故增量和 HEAD 累计补丁的有效前置代码相同；两份补丁为**互斥替代安装方式**，不能叠加。

## 与旧对话记录对应的任务

- 目标是缩短普通房门转场纯黑屏；历史录制约进门 23 帧 / 出门 27 帧；用户选择方案 B，目标约 13/14 帧，不能牺牲 REF-351B RGB555 彩色渐暗，不能恢复 LCD-off 白闪。
- REF-350 已在 `color/refreshmaps.asm` 内提供 CGB 地图 HBlank DMA（每行 16B + CPU 安全尾 4B）；**本轮不再叠加第二套地图 DMA**，不恢复失败的双格四写试验。
- 之前报告过的 351C “已新增数百行代码”已被上一轮对话纠正为未形成有效提交；此候选从用户真正提交的 351B 源码重新实现。

## 本轮实际源码修改

1. `home/copy2.asm` 的 `CopyVideoData`：仅 `hMapLoadVRAMSafeFlag != 0` 且 LCD 已开启时，将原 `B:DE` ROM 源、`HL` VRAM 目标、`C` 图块（16B/块）换算为 `FarCopyData2` 使用的 `A:HL`、`DE`、`BC` 字节数。调用已有 `CopyData` 的双字节 STAT 安全模式，而不是原来每帧仅装 8 图块的 `H_VBCOPY` 队列。保存/恢复 BC、DE、HL、ROM Bank，禁止改 SP 或独立创建 HDMA。其余调用原 VBlank 队列逻辑保持原样。
2. `home/overworld.asm` 的 `LoadMapData`：普通房门保持 `hMapLoadVRAMSafeFlag` 直到 `LoadPlayerSpriteGraphics` 完成后再清除。BG/属性装载和玩家图形都完成才恢复旧地图 BG/OAM 写入。LCD-off、特殊洞穴/战斗等未置 guard 的路径不变。
3. `data/game_version.asm` 和有关版本断言改为 `REF-351C@`；新增独立防回归测试和本说明。

正常文本框 32 块原需 4 次 `DelayFrame`；主角两次 12 块原需约 2+2 次 `DelayFrame`：合计最多**8 个固定 VBlank 上传等待点改成同步 LCD-safe copy**。这不等于实机黑屏必减少 8 帧：safe copy 仍需等待 LCD 可写时段，且 Tileset 1536B、地图 NPC 等仍会用到显存写入窗口。

## 必须保留的合同

- 继续使用 REF-351A 的每次安全窗口最多两连续字节；DMA、VBK/SVBK、ROM bank、中断恢复和原 Map VRAM BG/Attribute 分层上传均不改。
- 只有普通门口先完成彩色渐暗后才置 guard；其他调用没有 guard 时绝不使用快速传输。LCD 本来关闭时仍留给原上传路径。
- `CopyVideoDataDouble`、菜单/战斗的 `CopyVideoData`、Rock Tunnel/Dark Cave/Flash/warp pad/战斗回图和存档兼容不在本轮变更范围。
- ROM0 剩余 **252B** 只是用户交接的旧 REF-351B Red MAP，**不可**用它声称 REF-351C 已满足下限 64B；新增 `CopyVideoData` 指令需要新 MAP 才能确认容量。

## 验证与后续工作

本轮只执行静态回归、迁移审计、ASM 局部标签预检、Johto 表预检与旧 MAP 对照；没有安装 RGBDS 0.5.2、没有编译/链接或实机测试。对比 351B/351C 时需要：

1. 本机 `make red`、`make blue`、`make test-red`、`make test-blue`，新 MAP 确认 ROM0 >=64B，检查 Blue 与 TEST 的各银行是否链接。
2. My OldBoy 或实际 CGB/DMG：普通室内外门往返（含多 NPC 的 Johto 户外、Snowy、骑车/冲浪），确认无白闪、地图/人物/文字图块不乱码，音乐/音效不中断。
3. 特殊 cave/Flash/warp pad/战斗回图、旧档 Continue，以及菜单/战斗 `CopyVideoData` 仍按老行为运行。
4. 相同门、相同设备录 351B/351C 视频，逐帧量“完全黑屏至首帧地图”；仅达标且安全后再继续优化 Tileset/NPC；否则回退此候选，不为了 13/14 帧而跳过准备环节。
