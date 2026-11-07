# CLEAN REF-352｜普通房门黑屏提速正式清理与提交交接

## 1. 核实的版本、来源与验收范围

- 用户源 `REF-351B.zip`：`rpp-backup`、分支 `常规功能备份`；自动导出记录报告干净 HEAD `2d3942cfddfb22e7568e842bc29d800b5c4ac8b3`，游戏内版本 `REF-351B@`。ZIP 没有 `.git`，本环境只能核对源码字节与导出记录，不能读取或修改用户实际 Git index。
- 已交付的开发候选 `REF-351C`：上一轮开发补丁的七个源文件差异能从上述基线独立回放。本轮正式收口没有修改该候选的运行逻辑，仅按项目“ABCD 为测试后缀，正式数字加一去字母”的规则将游戏内显示调整为 **`REF-352@`**，并更新其测试版本断言、长期交接与验收文档。
- 用户本轮原话“OK，把这一版提交吧，做清理三件套……我已经满意了”明确表示对已展示 351C 录像效果认可，并授权进入提交准备；**不等于**提供了新 REF-352 ROM、完整 Red/Blue/TEST MAP、全部手机场景验收或已经完成 Git Commit。
- 2026-11-07 接受范围录像：`351C.mp4` 的 5 次进门连续全黑均 16 帧，5 次出门为 20/19/19/19/20 帧；`汉化版和RPP.mp4` 汉化版两次进门23帧、两次出门27帧。RPP 参考录像黑屏分成 8+5（进）/8+6（出）帧，中间有5/6帧整白闪；从首次全黑到首帧新地图进门18帧、出门20帧。录像口径是约 60fps 的帧分析；场景、编码或机型差异不能推出全部设备性能保证。

## 2. 本轮从已提交 HEAD 到正式状态的游戏功能

- `home/copy2.asm`：在 `CopyVideoData` 入口仅有 `hMapLoadVRAMSafeFlag` 非零且 `LCDC.7` 已开时，按 `B:DE` 源 / `HL` 显存目标 / `C` 个16B 2bpp tiles，将图块量换算成 `BC` 字节，调用已存在的 `FarCopyData2` / REF-351A `CopyData` 安全双字节窗口。保留指针与 Bank wrapper，不改 SP、VBK 或原 VBlank 调度主体；不新增 DMA。
- `home/overworld.asm`：当前普通门口保护有效期覆盖 `LoadPlayerSpriteGraphics`，该调用返回后才清除 `hMapLoadVRAMSafeFlag`；既有旧地图更新保护不在主角图块上传期间提前撤销。
- `data/game_version.asm`：正式显示 `REF-352@`（从已提交的 REF-351B@ 升级）。不新增地图、Warp、音乐、存档结构，也不改变 REF-350 地图分层 HDMA / REF-351B RGB555 渐暗逻辑。
- 固定等待点分析：文字框32块旧路径4次 VBlank，主角两次12块旧路径约2+2次，合计最多8处固定 VBlank 等待改成 STAT 安全同步复制；**不等于**任何场景必然节省8帧，录像实际观察为相对汉化版缩短7–8帧。

## 3. 当前仍需遵守的兼容性合同

- REF-350：LCD-on 普通门 CGB Tile/Attribute 两层 HBlank DMA 与安全尾部写入原样；历史失败的“双格 HBlank 四写”不得恢复。
- REF-351A：safe VRAM copy 仅在正确 flag/VRAM 范围，STAT mode 0/1、奇数长度与双速前置合同继续有效；临界区、中断、ROM Bank 与原 SP 不变。
- REF-351B：普通零偏移房门 RGB555 BG/OBJ 同步阶段 F9/FE、WRAM2 缓冲与4×8帧 Fade 节奏不变。
- 菜单/战斗 `CopyVideoData`、`CopyVideoDataDouble`、LCD-off、Dark Cave、Rock Tunnel、Flash、Warp Pad、战斗回图保留旧安全加载分支；不能因单一视频看起来正常就将 flag 外溢到其他路径。

## 4. 正式清理：本轮用户特批一次提交，三文件一个 ZIP

**本次提交把全部 13 个修改文件一次提交**，不再分批、不隔离工具或文档：

- **运行代码与版本号（3）**：`data/game_version.asm`、`home/copy2.asm`、`home/overworld.asm`。
- **测试工具（3）**：`tools/tests/test_doorway_fast_copy_351c.py`、`tools/tests/test_doorway_lcdon_copy_pair_351a.py`、`tools/tests/test_doorway_cgb_rgb555_fade_351b.py`。
- **维护与交接文档（7）**：`README.md`、`FEATURES.md`、`TODO.md`、`RPP_DEVELOPMENT_PITFALLS.md`、`PROJECT_DELIVERY_RULES.md`、`docs/REF351C_DOORWAY_SAFE_BULK_COPY_DEV.md`、本文件。

用户最新明确要求“功能和工具一起提交”，并不希望再操作隔离补丁。本轮依项目要求“用户当前明确提出的新要求优先”作为特殊单提交交付，不修改其他版本的历史双提交记录。

ZIP 只包含以下三个文件：

1. `01_REF351C候选_到_REF352正式清理.patch`：仅用于已经安装上一轮 REF-351C 开发候选的工作区。
2. `02_HEAD_2d3942cf_到_REF352正式全量.patch`：仅用于仍在干净 HEAD `2d3942cfddfb22e7568e842bc29d800b5c4ac8b3` 的工作区。
3. `commit-message.txt`：本次一笔 Git Commit 的中文日志，功能、工具与文档均在同笔。

**01、02 互斥，只选择其中一份**。应用完成后直接检查 `git diff`、`git status`，再由用户在实际仓库执行一次 Commit／按需 Push。**本包没有反向隔离补丁，不执行 `git apply -R`，不要混用上一个 REF-352 五文件旧包**。源 ZIP 不含 `.git`，本环境不能代替用户验证真实 Git index 或执行 Commit。

## 5. 本轮实际检查与防回归检查门禁

- REF-351A/351B/351C 三套专项测试覆盖：flag+LCDC 双门控、tiles×16 计数换算、ROM Bank/寄存器保存、旧 VBlank 回退、玩家加载完成后的 guard 清理、RGB555 缓冲/查表及 HDMA 不变。
- 旧 REF-351B 版本审计只锁定已提交历史；本次将现役测试精确显示断言同步到 `REF-352@`，防止仅改标签、测试还认旧候选。
- 故障注入应至少覆盖：删掉门口 flag 检查、删掉 LCD-on 检查、提前取消 guard、破坏 tile 数量换算中的 mask。检测到这些源码被破坏时，对应已有专项断言必须失败，且注入结束不得污染正式源码。
- 强制入口：`python tools/asm_symbol_preflight.py`、`python johto_table_assert_preflight.py`、`python tools/johto_pilot_migration_audit.py --project .`、`python tools/johto_rom0_space_preflight.py`；运行结果在正式打包前复核并在此追加真实数据。
- 现役相关 pytest 及按需补丁正反回放、文件 SHA-256 和 Git 模式核查均需执行。**静态 PASS 不能代替真实 RGBDS 编译或手机 PASS**。

## 6. 容量、设备与未完成事项

- 附带的历史 `patches/rppred.map` 标记为 **REF-351B Red**：ROM0 仅可引用为旧基线余 252B（最低要求 64B），不能作为 REF-352 已通过链接的证据。REF-352 未有全新的 Red/Blue/TEST Red/TEST Blue MAP、ROM 二进制或空间确认。
- 用户本机应以最新源码构建四目标并核对真实 MAP、ROM0≥64B 与 ROMX 银行余量。最低设备回归：普通房门反复往返、文字框与玩家/NPC 图形、不同 Tileset、CGB BG/OBJ 渐暗无白闪，音乐/音效正常；菜单/战斗原队列、特殊洞穴/Flash/Warp Pad/战斗回图、旧存档 Continue 有余力时专项复测。
- 当前收口只冻结用户满意的 351C 视频实现，**不继续追求 13/14 帧纯黑**；任何新一轮 Tileset/NPC 提速应另建版本和单独验收。

## 7. 正式清理前实际执行结果（2026-11-07）

- `python -m pytest -q -rs tools/tests/test_doorway_fast_copy_351c.py tools/tests/test_doorway_lcdon_copy_pair_351a.py tools/tests/test_doorway_cgb_rgb555_fade_351b.py tools/tests/test_doorway_lcdon_upload_350.py`：**25 passed**。
- `python tools/asm_symbol_preflight.py`：**1850 个 ASM 文件通过**，仅检查局部跳转/符号，不替代 RGBDS。
- `python johto_table_assert_preflight.py`：**64 张活动地图**；三个表长度分别 **256/256、64/64、64/64**，均通过。
- `python tools/johto_pilot_migration_audit.py --project .`：**1538/1538 PASS_STATIC_ONLY**，无独立 Gold 参考根目录。
- `python tools/johto_rom0_space_preflight.py`：**PASS_STATIC_ONLY**；读取的 `map_rom0_slack_bytes=252` 来自旧 REF-351B Red MAP，不是 REF-352 新链接。
- 对 `tools/tests/test_doorway_fast_copy_351c.py` 的原有断言进行 **4 项内存中故障注入**：删掉 flag 分支、删掉 LCDC.7 分支、把 tile 换算低字节掩码 `$f0` 改成 `$0f`、把清除 guard 提前到 `LoadPlayerSpriteGraphics` 之前。四项均被对应现有测试拒绝；注入过程使用 Python mock，**没有改动源码文件**。
- 另试运行 `tools/tests/test_johto_indoor_pipeline.py`，该旧测试在清理树中出现 **2 failed, 5 passed, 20 skipped**；在用户原始干净 `REF-351B.zip` 上同样有这两项失败，且该测试文件及相关地图数据本轮未修改：一项原注册 Warp 行数合同失效，另一项仍将活动地图 ASSERT 写死为 57 而实际为 64。**没有**为本次门口优化修改该无关历史测试，不宣称全仓库 pytest 全绿。
- 以上结果均来自本轮实际执行，未运行 `make red/blue/test-red/test-blue`，没有 REF-352 新 MAP、ROM、设备音频与特殊转场全面验证。正反向补丁重放与字节校验结果按本次最终打包脚本执行结果为准。

## 8. 单提交三件套回放与一致性验证

- `01` 使用原始 `REF-351B.zip` 的干净源码加上上一轮实际交付的 REF-351C 增量补丁重建候选；补丁完成后应与 REF-352 终态逐字节一致，反向回放应恢复原候选。
- `02` 直接从上传的干净 REF-351B 基线重放完整累计差异；其正向／反向回放须精确还原 REF-352／REF-351B 全部源文件和可执行权限。
- 两种安装方式互斥，不可叠加。共计 13 个变化文件：3 运行代码、3 专项测试脚本、7 文档。ZIP 保留两份互斥正向补丁和一份中文单提交日志；新交付不包括工具／文档隔离补丁。
- **边界**：本环境没有用户真实 `.git` 仓库，以上验证只能证明补丁与上传的源码一致，不能声称已产生 Git Commit、Push 或新 ROM/MAP。
