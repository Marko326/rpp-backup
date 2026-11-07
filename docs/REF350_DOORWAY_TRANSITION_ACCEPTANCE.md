# REF-350｜普通房门 CGB 黑屏转场与 HBlank DMA 阶段验收

## 版本与基线

- 分支：`常规功能备份`
- 本轮确认的正式 Git HEAD：`8858c3a14a8b428fa33d44c64d10e5a3f4d57301`（REF-349）
- 本轮开发候选：`REF-350G`
- 正式提交版本：`REF-350`（按项目要求去掉开发字母，并相对上一正式版本 REF-349 递增）
- 本文记录的是阶段性提交，不表示普通房门转场已经最终定版。

## 最终运行逻辑

1. 普通房门按 DOR-1.18 CGB 节奏渐黑。
2. 目标地图加载期间 LCD 保持开启；旧地图的 BG/行列/OAM 更新在安全标志有效时暂停。
3. 地图 20×18 BG Tile 与 CGB Attribute 两平面先暂存到 WRAM Bank 2；每行前16字节使用一块 CGB HBlank DMA，末尾4字节逐次等待可写 VRAM 的 mode 0/1。
4. 每行后12个非显示列不写入，保持原有32字节 BG Map 行跨度。
5. 每次切换 SVBK/VBK 后，在恢复中断前还原到 Bank 0 / VBK 0。
6. 保留 ROM Bank shadow 同步；LCD-off 的原快速加载路径仍供洞穴特殊转场、Warp Pad、战斗回图及其他非普通门加载调用。

## 本轮修改范围

- 游戏运行代码：`color/refreshmaps.asm`、`color/vblank.asm`、`color/wram.asm`、`home.asm`、`home/copy.asm`、`home/overworld.asm`、`home/vblank.asm`、`hram.asm`。
- 游戏版本：`data/game_version.asm` 从开发候选 `REF-350G` 收口为正式候选 `REF-350`。
- 工具/测试：以 `tools/tests/test_doorway_lcdon_upload_350.py` 替换开发阶段测试文件名；覆盖双平面暂存、16字节 HBlank DMA、末尾4字节安全写入、WRAM/VBK 恢复、缓冲区边界及旧 LCD-off / 洞穴路径保留。

## 实际执行的静态检查

命令（使用用户提供的 `pokegold_1.01.zip` 解压后的 Gold 源码目录）：

```bash
GOLD_SOURCE_ROOT=/path/to/pokegold python -m pytest -q -rs tools/tests/test_doorway_lcdon_upload_350.py tools/tests/test_johto_dark_cave_stage2.py tools/tests/test_johto_dark_cave_stage_349.py tools/tests/test_johto_gate_music_bike_259.py
python tools/asm_symbol_preflight.py
python tools/johto_pilot_migration_audit.py --project . --gold-root /path/to/pokegold
```

结果：

- 专项 pytest：`68 passed, 0 skipped`。
- ASM 局部符号预检：`1850 ASM files checked`，PASS。
- 主 Gold 综合审计：`1707/1715 PASS`，状态仍为 `FAIL`，有8项历史合同失败。与 REF-350F 基线比较，基线为 `1700/1715`、15项失败；本轮没有新增失败项，版本统一后有7项旧版本断言恢复通过。剩余8项涉及旧 Route34/Goldenrod 接缝、中心/门房版本锁定及旧地牢批次合同，不属于本轮房门上传改动；不能宣称主审计全绿。
- 增量补丁、HEAD 累计补丁及工具反向隔离补丁分别独立回放，逐文件 SHA-256 与预期状态一致；ZIP CRC 通过。

## 用户视频证据

用户提供的 `350G.mp4` 中，普通进出门画面可恢复；录屏未观察到此前出现的白闪、Tile/Attribute 乱码或黑屏死机。录像逐帧统计约为进门25帧、出门30帧。与此前汉化版录像约23帧/27帧相比仍略长，后续可继续优化。

该视频仅证明录像所覆盖的普通门路线，不等于所有地图、所有构建目标或旧存档都已完整验收。

## 尚未验证与风险边界

- 助手未运行 RGBDS 编译或链接；项目要求由用户本机执行 Red、Blue、TEST Red、TEST Blue 及 MAP 构建。
- 当前上传项目附带 MAP 版本仍为 REF-350F，不是 REF-350；不得用它证明新增代码后的 ROM0/ROMX 空间。用户需提供新 MAP，核实 ROM0 至少64B及相关 Bank 余量。
- 用户视频未覆盖 Dark Cave、Rock Tunnel、Warp Pad、战斗回图、旧存档、Save/Continue 等所有回归场景；这些路径在本轮源码中保留原分支，但仍需用户实机抽查。
- 目前不把 350G 标记为最终版；后续黑屏等待优化应先定位剩余加载阶段，不得放松 VRAM 安全检查或破坏 CGB Attribute 对应关系。
