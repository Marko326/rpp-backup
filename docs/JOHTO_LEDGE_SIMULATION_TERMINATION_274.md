# FIX-5.62.274 跳崖输入状态收尾修复（仅源码候选）

## 手机证据与静态根因

用户视频显示某些跳崖落地后人物能进入树林阻挡区，随后白屏并重新进入启动画面。原版 `HandleLedges` 用两个方向输入跳过崖壁；当前 `_HandleMidJump` 在 `wWalkCounter=0` 后关掉 `wd736.6` 和 `wd730.7`，却未清空 `wSimulatedJoypadStatesIndex`。旧 `CollisionCheckOnLand` 在跳跃标志已清除后，仍以这个残留索引非零为由跳过常规碰撞。视频症状与此完全相容；重启的确切指令地址尚未捕获。

## 实施（不改成熟跳崖坐标）

- `_HandleMidJump` 仅在最后收尾动作中清零模拟索引、两个队列字节及临时字段，仍保持两步动画与移动序列。
- `CollisionCheckOnLand` 将原来 7 字节的 `LD A,[wSimulatedJoypadStatesIndex]; AND A; JP NZ,.noCollision` 改为等长的 `LD A,[wd730]; RLCA; JP C,.noCollision`。`RLCA` 将 bit7 写入 Carry，只允许真正活动中的模拟输入绕过普通碰撞。
- 脚本移动的 `wd730.7` 合同保留，关都也继续使用既有共享动画；没有扩大任何地图的碰撞白名单。
- `JohtoSouthHopLandingGuard` 原有的第二格保护保留。新的复位修的是其无法覆盖的“跳跃标志已落下、索引尚非零”窗口。

## 室外门房图形未解决范围

- 检查 `AzaleaTown.runtime.blk` 与 Gold `AzaleaTown.blk` 逐字节一致，`johto_modern.bst` 与 Gold `johto_modern_metatiles.bin` 也逐字节一致，`johto_modern.png` 与 Gold 一致。
- 成熟参考分支 `JohtoAzaleaTown_h` 同样采用 `JOHTO_MODERN`，室外地图块来自 Gold。
- 因而上一版修改室内 `IlexForestAzaleaGate.mature.blk` 并不能改变室外左侧。没有证据表明应该修改哪一个 Gold 室外区块，本轮不把这处图形问题当成已解决。

## 可重复检查与安全边界

执行 `python tools/johto_ledge_state_preflight_274.py`、`python -m unittest tools.tests.test_johto_ledge_state_274`、`python tools/asm_symbol_preflight.py` 以及整体单测/迁移审计。构建 ROM 和查看全新 MAP 按项目要求由用户完成；仅允许 PNG 源图，禁止把生成 `.2bpp`/MAP 加进补丁。不 Git Commit/Push。`TEST-231` 不变。
