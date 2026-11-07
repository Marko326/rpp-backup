# CLEAN REF-351B｜正式清理与稳定源码基底交接

## 1. 本轮真实输入与 Git 基线

- 用户输入：`REF-351B.zip`，导出类型为“当前 Worktree 源码 + 当前修改 Patch”。
- 项目：`rpp-backup`。
- 分支：`常规功能备份`。
- 本轮正式 Git HEAD：`30bbe52a96ffe8d8238159a855fa1b1002d7fee3`。
- HEAD 游戏版本：`REF-350`。
- 当前 Worktree 游戏版本：`REF-351B`。
- 当前导出记录包含 HEAD 及其前一笔历史提交；REF-350 普通房门 LCD-on/HBlank DMA 已在 HEAD 中，不在本轮重复提交。
- 导出的 `RPP_PROJECT_CONTEXT/patches/current_worktree.patch` 可在当前 Worktree 上反向检查并应用，成功重建该正式 HEAD 的文件内容。未将 Worktree 冒充正式 HEAD。
- 当前 Worktree 相对 HEAD 共41个文件差异：9个游戏运行源码文件、26个工具/测试文件、6个维护/技术文档文件。清理只整理文档和测试说明，不再改游戏运行代码。

## 2. 最终冻结的游戏功能

本次稳定基底固定为 `REF-351B`，游戏版本号不再改动。

### REF-350：普通房门 LCD-on 地图加载

- 普通房门加载期间保持 LCD 开启，避免 LCD 关闭造成白闪。
- BG Tile 与 CGB Attribute 暂存至 WRAM Bank 2。
- 每行前16字节使用 HBlank DMA，末尾4字节按 VRAM 可访问模式安全写入；12个非显示列保持不写。
- 保留 VBK/SVBK/ROM Bank 恢复顺序及旧地图 BG/OAM 更新保护。
- Dark Cave、Rock Tunnel、Flash、Warp Pad、战斗回图等特殊路径保持原有分支。

### REF-351A：双字节 LCD-safe VRAM 复制

- 仅在 `hMapLoadVRAMSafeFlag` 有效且目标起始地址位于 `$8000-$9fff` 时启用。
- 奇数长度先复制一个字节，剩余数据按两个连续字节成对复制。
- 每对写入使用同一次 STAT mode 0/1 检查及同一 DI 区间。
- 非 VRAM 目标和 LCD-off 快速路径保持原样；不改 FarCopy ROM Bank wrapper，不改 SP。

### REF-351B：CGB RGB555 普通门渐暗

- 只对普通 `wMapPalOffset == 0` 房门 Fade 启用。
- F9 阶段对 RGB555 三个5位通道分别按 `floor(x*2/3)` 缩放；FE 阶段按 `floor(x/3)` 缩放。
- BG/OBJ 使用独立双缓冲、身份索引和同一 VBlank 阶段提交。
- 原始调色板不被改写；4阶段×8帧 Fade 节奏不变。
- RGB555 查找表使用 WRAM2 中完整16位基址和 `add hl,de` 索引，不再依赖单体 `bank2C` Section 内的页对齐。

### 明确不在本次范围

- 不开发 REF-351C，不改变黑屏帧数目标。
- 不改普通房门音效、地图/Warp、SRAM/存档布局。
- 不改 Rock Tunnel、Dark Cave、Flash、Warp Pad、战斗回图等特殊路径。
- 不恢复历史双格 HBlank 四写试验，不新增第二套地图 DMA。

## 3. 正式清理模式与提交拆分

本轮相对正式 HEAD 同时存在游戏运行代码与工具/审计/测试变化，因此采用项目规范**模式 A 双提交**。

### 第一笔：游戏功能提交

只包含9个游戏运行源码文件：

- `color/init.asm`
- `color/refreshmaps.asm`
- `color/vblank.asm`
- `color/wram.asm`
- `data/game_version.asm`
- `home/copy.asm`
- `home/fade.asm`
- `home/overworld.asm`
- `hram.asm`

提交后游戏版本为 `REF-351B`。不包含 `tools/`、测试、README、TODO 或维护文档。

### 第二笔：工具／审计提交

包含本轮相对 HEAD 修改的：

- `tools/` 离线审计脚本。
- `tools/tests/` 回归测试与负向防回归用例。
- `README.md`、`FEATURES.md`、`TODO.md`、`RPP_DEVELOPMENT_PITFALLS.md`。
- `docs/` 中 REF-351A、REF-351B 技术说明及本清理交接文档。

`README`、`TODO` 等仅作维护记录；不更改游戏行为。

## 4. 三件套的定义与应用顺序

交付 ZIP 固定为3份补丁、2份中文提交日志，共5个文件：

1. `01` 清理增量补丁：本次上传的 REF-351B Worktree → 最终清理状态。
2. `02` 工具部分反向隔离补丁：最终完整清理状态 → 仅保留第一笔游戏功能的状态。
3. `03` 基线累计全量补丁：正式 HEAD `30bbe52a96ffe8d8238159a855fa1b1002d7fee3` → 最终完整清理状态。
4. 功能提交日志。
5. 工具／审计提交日志。

应用流程：

1. 当前工作区已与本次上传的 REF-351B Worktree 完全一致时，应用 `01`；从干净 HEAD 重建时，只应用 `03`。`01` 与 `03` 互斥，不可叠加。
2. 得到完整最终状态后，应用 `02`，临时撤回工具/测试/文档差异，只留下游戏功能文件。
3. 按功能日志由用户自行提交第一笔。
4. 第一笔提交后执行 `git apply -R 02`，恢复工具/测试/文档。
5. 按工具日志由用户自行提交第二笔。

助手不执行 Git Commit/Push。`02` 是隔离用补丁，不是单独的正向开发补丁。

## 5. 本轮实际执行的静态检查

### 门房与相关运行合同

`python -m pytest -q -rs`，指定7个门房/安全加载/特殊地图相关测试文件：**84 passed, 1 skipped**。唯一跳过项需要独立 Gold 源码根目录。

### 修改过的工具与审计测试

指定15个受本轮工具差异影响的测试文件：**131 passed, 6 skipped, 4 subtests passed**。跳过项均因未提供独立 Gold 源码。

### 项目强制预检

- `python tools/asm_symbol_preflight.py`：1850 个 ASM 文件局部符号检查通过。
- `python tools/johto_table_assert_preflight.py`：64张活动地图；3张表 ASSERT 通过（256/256、64/64、64/64）。
- `python tools/johto_pilot_migration_audit.py --project .`：`PASS_STATIC_ONLY`，1538/1538；没有独立 Gold 参考目录。
- `python tools/johto_rom0_space_preflight.py`：`PASS_STATIC_ONLY`，无静态问题；工具明确要求用户侧新构建/链接后再验 ROM0。

全仓库 pytest 本轮未完成，因此不声明全量测试全绿。

## 6. MAP 与空间证据

ZIP 附带 `patches/rppred.map`，导出记录标记为 `REF-351B` Red MAP：

| 项目 | 附带 MAP 结果 |
|---|---:|
| ROM0 剩余 | 252B |
| 项目最低要求 | 64B |
| ROMX `$2A` 剩余 | 15001B |
| ROMX `$2C` 剩余 | 771B |

该 MAP 只覆盖 Red。当前没有同版 Blue/TEST MAP；也没有由助手执行 RGBDS 汇编/链接。因此这份空间数据不能替代 Red/Blue/TEST 三种构建的本机验收。

## 7. 尚未完成的验收

- 用户本机 RGBDS 0.5.2 `make red`、`make blue` 及 TEST 构建。
- 三种构建均成功汇编/链接并生成对应 MAP。
- Red/Blue/TEST ROM0 均至少64B，相关 ROMX Bank 有足够余量。
- CGB 设备上 BG/OBJ 同步渐暗、无白闪/单帧跳色。
- 不同 Tileset、Gold/Snowy 屋顶、玩家/NPC 精灵、音乐与音效连续性。
- Rock Tunnel、Dark Cave、Flash、Warp Pad、战斗回图及旧存档回归。

之前用户报告的 `ALIGN $100` 和 `ALIGN 8` 汇编错误已在当前源码中通过移除内联页对齐依赖处理；**但当前源码仍需用户本机实际 RGBDS 汇编验证**。

## 8. 稳定基底结论

`REF-351B` 作为下一阶段开发的源码基底已经冻结：不混入 REF-351C 实验，不改游戏功能，不改版本号；工具、测试和文档按双提交方式隔离。

这表示源码与静态审计已完成清理准备，**不表示 ROM 已编译、三种构建已通过或设备验收已完成**。后续如继续优化转场，应以用户成功构建并验收后的 REF-351B 为新开发前置。
