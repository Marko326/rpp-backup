# REF-359 开发候选｜玩家道具 PC 三种旧提问完整注释

## 录像与原因
- 用户 `358.mp4` 约23～24秒显示：重新进入 Toss 时，旧问题 `What do you want to toss away?` 在列表出现前短暂打印。
- `engine/menu/players_pc.asm` 的 Deposit / Withdraw / Toss `.loop` 每次均执行对应 `PrintText`，不区分首次还是再次进入；当前的两行道具说明已接管下方文本区，旧提问不仅重复，还增加绘制及切换延迟。

## 实施边界
- 在三个 `.loop` **原位置**将 `ld hl,WhatTo...Text` + `call PrintText` 共六条指令逐行变成 `;` 注释。
- 同一 ASM 文件中三组 FAR 包装器（标签/TX_FAR/db）全部注释；`text.asm` 中三组正文（标签/text/line/done）全部注释。不删除历史调用链，也不把它们编入 ROM。
- 仅保留动态道具说明；父菜单 `What do you want to do?`、数量确认 `How many?`、空库存、HMs 限制、存取结果与 B 返回、光标、购买/SELL 功能不改。
- 按项目版本规则，实际运行 ASM 有变化，即使仍为开发测试候选也从 `REF-358@` 升到 `REF-359@`。

## 本机验证
1. 打开 Player's PC 的 Withdraw／Deposit／Toss，分别首次进入、取消(B)、再次进入、取消数量框、成功存取后再进入；旧问题不再出现，不应卡顿或闪一下。
2. 首项、上下滚动、TM/普通道具说明正常；缺道具时保留原空列表提示。
3. 使用 B 返回父菜单一次仅退一层，父菜单光标、底部固定 `What do you want to do?` 仍正常；Bill's PC 的宝可梦 Deposit/Withdraw/Release 不受影响。
4. 确认 SELL、BUY 余额上限、REF-356 数量框、REF-357 卧室 PC／博士提示与 Flash 均无回归。
5. 本机重新编译四种 ROM、核对 MAP，并在手机上录制验证；静态测试和正反向补丁检查不能代替 RGBDS 链接或设备表现。
