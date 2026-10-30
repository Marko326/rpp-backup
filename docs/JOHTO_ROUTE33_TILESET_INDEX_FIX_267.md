## CLEAN-267｜验收与资源源码边界

用户报告 `.267` 编译后的手机运行：Route33 花屏已消失、联合洞窟进出正常，且自行车与 Fly 正常。这是用户实测反馈；不是助手独立运行 ROM。用户另提到“出去的时候……”但尚未完整说明，不在此文档推定已解决。

Route33 Gold 离线审计与对应单元测试现直接读取并验证 PNG 源文件，不再依赖忽略的 `.2bpp` 生成物；负向测试还会改坏 PNG 像素以验证检查器确实会失败。

`gfx/tilesets/johto_modern.png` 是须 Git 追踪的源文件；`gfx/tilesets/johto_modern.2bpp` 由工程 `Makefile` 的通用规则在本地转换，不能因 `INCBIN` 引用就强制追踪被忽略的二进制中间物。清理也必须保留用户工作区 `home/overworld.asm` 的 `jp nz,.noCollision`，避免回退为可能越界的短跳。

## FIX-5.62.267｜33号道路图块集加载溢出修复（开发候选）

- 症状：联合洞窟南出口进入 Route33 后整屏花屏；并非 Gold 33号路 `.blk`、PNG 或落点写反。
- 根因：`engine/overworld/tileset_header.asm` 原先以8位移位/加法拼出 `tileset * 12`，`JOHTO_MODERN=32` 时中间进位丢失，实际 `$0080` 而非 `$0180`；读取到错误的 ROM Bank/图块指针。`color/loadpalettes.asm` 又以8位 `sla e`×3 求 `tileset * 8`，ID32 时 `$0000` 而非 `$0100`。**旧回归检查没有把新 Tileset ID 32 送过这两段运行时地址计算。**
- 修复：仅将两处索引改用16位 HL 算术，保留 `.266` 地图资源、Gold碰撞、双向 Warp 和 `.265` 朝向。无新 Bank、新 SRAM、无大范围图形替换。
- 防回归：新增 `tools/tileset_index_preflight_267.py`、`tools/tests/test_tileset_index_267.py`，检查 ID 0–32 及故障注入；注意该检查不模拟 ROM VRAM，不能代替手机验收。
- 交付：增量严格从 `.266` 实际开发候选生成，累计全量从 `.266` 原来声明的干净 HEAD `438046a6ae6a709b656b8f712eeeecefc6259dda` 生成，两份互斥；不编译 ROM、不提交 Git、不更新 `TEST-231`。须由用户本机编译并检查新 MAP／南北口和 Route33 显示。
