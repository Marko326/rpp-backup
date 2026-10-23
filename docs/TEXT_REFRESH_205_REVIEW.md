# TEXT-5.62.205 — 对话逐字显示刷新优化：收口与后续回归

## 目标与确定范围

- **只改对话文字上屏的刷新时机**，不移植 Polished Crystal 字体，不更换 RPP 已有逐字速度、文字控制码、对话滚行动画或 A/B 等待流程。
- 204 原来按上、中、下三块轮换传输 BG；文字即使按 1 帧计时写入 WRAM Tilemap，也可能要等到下方区域轮到传输才出现在 LCD。205 保持三段刷新结构，在允许时优先把对话框所在的下方六行传到 VRAM。
- 这里的“更流畅”来自实际可见字符刷新的节奏，**不是**对 `ScrollTextUpOneLine` 平滑动画的替换，也不能据此推断更高的 ROM 性能。

## 实际保留的源码实现

| 文件 | 205 最终变更 |
|---|---|
| `home.asm` | `PrintLetterDelay` 限定 `HL` 在 Tilemap 的底部六行且自动 BG 传输开启时，设置 `hTextBottomRefreshRequest=1`；否则不插队。 |
| `hram.asm` | 在 `$FFFC` 新增单帧一次性请求标志，不更改 SRAM／持久存档。 |
| `color/vblank.asm` | `GbcPrepareVBlank` 在 `RefreshWindowPalettesPreVBlank` 前消费请求；检查自动 BG 传输、上一批调色板状态、静态调色板重建／窗口目标变化，符合条件才选择 `TRANSFERBOTTOM`，其余情况沿用原轮换。 |
| `data/game_version.asm` | 普通 Red/Blue：`TEXT-5.62.205`；独立战斗测试版仍为 `B-5.62.204-T09`。 |

- `color/refreshmaps.asm` 的原三段 `RefreshWindow` 不修改；`ScrollTextUpOneLine` 仍是现有两次移动、每次五帧的算法。
- `engine/menu/options_menu.asm`、`wram.asm`、字体资源、`Makefile`、测试工具代码均不修改。保存的 Slow 值保持 **3 帧**；Normal=1 帧；Fast 仍遵循原瞬时机制。
- `BATTLE_TEST_BUILD` 的构建隔离保持原样，文字优化源码是共用代码，但测试构建的 *版本标签* 单独维护，不随普通版本号增长。

## 用户观察与剩余风险

- 用户提供过 204、205 及 Polished Crystal 的文字对话录像。205 的 **Normal** 在用户可见测试中更连续；205 的 **Slow** 仍接近每字 3 帧，其观感与更快的 Normal 不同，这是原设置节奏，而非额外确认的显示故障。用户决定保留原慢速，不采用改变等待帧数的候选。
- 录像范围主要是 **NPC 对话**，观察时未报告明显花屏、调色板异常；**没有获得** 205 的战斗文字／HP 条／菜单和 Red、Blue 及独立测试 ROM 的完整实机验收。用户提出清理定稿，并不等于这些未测分支全部通过。
- 优先刷新对话框可能令其它屏幕区域短暂后移；今后若出现地图、战斗 HUD、窗口切换或调色板更新异常，首先检查 `hTextBottomRefreshRequest` 的生命周期和前置调色板保护，不要直接换成 PC 的二分屏系统。

## 后续最小构建和测试

1. 用户本地分别构建正式 Red/Blue，并按项目方法核对新 ROM MAP 和 ROM0/ROMX 空间；旧 204 MAP（ROM0 可用约 349B）不是 205 已链接证明。
2. 手机实测 NPC Normal／Slow 连续长对话、滚行结束返回地图；观察文字与颜色是否稳定。
3. 实测战斗文字打印与 HP/HUD 更新、菜单开关和调色板变化；按需核对独立测试 ROM 仍显示 `B-5.62.204-T09` 且测试入口隔离正常（注意单独存档）。
4. 本次只做源码与补丁静态检查；无 AI 侧 ROM 构建、链接、实机运行、Git Commit 或 Push。

## 提交与交付

- 用户 ZIP 导出确认的已提交基线：`BATTLE-5.62.204` / HEAD `6d87cab1c761adae4ff58d4fcaa997fd4a502296`（分支 `常规功能备份`，本环境未运行 `git status`，不宣称 205 已提交）。
- 本次清理模式 **B**：增量由已打 `TEXT-205-001` → 当前正式 205 清理状态，全量由 204 HEAD → 当前状态；两份只能择一应用。ZIP 内含独立 `commit-message.txt`，由用户自行提交。
