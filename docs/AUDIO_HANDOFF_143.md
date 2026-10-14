# 音频专项交接 — SFX-5.62.143 收口（2026-10-14）

> 分支：`常规功能备份`。此文档记录拟提交工作区和受测范围，**不是实际 Git Commit／Push 或 ROM 编译证明**。

## 基线与交付

- 当前上传项目 ZIP：`fix(audio)__修复开场跳过音效残留与低血量招式命中声衔接.zip`。ZIP 的 `RPP_PROJECT_CONTEXT/02_EXPORT_INFO.txt` 指示最新 HEAD 为 `7a89953cdc83b083dcf1be962f428c650fdcc405`，对应已提交的 **`SFX-5.62.141`**；ZIP 的**实际工作树**已经包含未提交的 `SFX-5.62.142` 电梯清理。因此 **Git 提交跨度 141 → 143**，但本次“基于上传 ZIP 的全量补丁”起点是实际 142 工作树，两种基线不可混称。
- 143 功能补丁：`AUDIO-018`（142 工作树 → 143）。本次收口：`AUDIO-DOC-019`，纯文档增量（已应用 018 的 143 → 收口 143），不增游戏版本号；两份应用方案：从已应用 018 的版本使用文档增量，或从**此上传 ZIP 的实际 142 工作树**使用累计全量；**不可叠加**。
- 交付合集包含增量、累计全量与 `commit-message.txt`；拟提交日志覆盖 142 的电梯处理和 143 的训练师倒下处理，用户需在本地自行 Git Commit／Push。未收到 143 完成 Commit 的明确确认前，不将 143 视作已提交的后续基线。

## 最终保留的代码与验收

### 142：电梯音效旧等待清理

- `engine/overworld/elevator.asm` 用 `callba WaitForElevatorSFX` 替换旧 `wChannelSoundIDs + Ch4` 等待，新增 `engine/overworld/elevator_sfx_wait.asm` 浮动 ROMX 例程按 `SFX_SAFARI_ZONE_PA` 的 Crysaudio CH5 标志及对应 SFX 身份逐帧等待，最多 180 帧。原 40 次电梯震动及 `PlayDefaultMusic` 保留；后者的额外等待不包含在 180 帧上限中。
- 用户提供《141电梯.mp4》《142电梯.mp4》，明确表示差异不大、141 本来也没有能辨认的问题；**只作为旧代码兼容清理**，不是修复已复现的电梯声音故障。电梯全部位置、游轮／渡船、静音／BGM Volume 0 未分别确认。

### 143：训练师战倒下声旧等待清理

- `engine/battle/core.asm` 训练师战 `SFX_FAINT_FALL` 与 `SFX_FAINT_THUD` 之间改为 `callba WaitForTrainerFaintFallSFX`；新增 `engine/battle/trainer_faint_sfx_wait.asm` 浮动 ROMX，检查 CH5 活动位和实际 `SFX_FAINT_FALL` 身份（最多 180 帧）。`main.asm` 增加浮动 ROMX INCLUDE。其余玩家倒下、野外战斗、胜利音乐、战斗音效与全局 Crysaudio 没有被此轮代码改动。
- 用户提供《143音效.mp4》并表示试过建议场景但不容易听辨。录像记录中可观察敌方与己方普通倒下、红血状态击倒敌方、训练师战胜后续，以及伏特攻击双方同时倒下；基础流程未见明显异常、下降声／落地声未发现明显抢断，但**不能用单份录像证明 142 旧版必定听得出抢断**，也不扩展为所有设置／声道通过。
- 反伤造成双方同时倒下且敌方先处理时，己方可能立即退场、不播放自身叫声／倒下文字，这是 `engine/battle/core.asm` 旧的特殊流程分支。用户只问原因并明确**不修改**；143 没有触碰该分支。

## 未完成与下一阶段

1. **先验证是否真实存在问题**：宝可梦中心治疗完成的提示音、地图 SFX 与战斗 BGM 切换、飞行／传送时的音乐衔接。不要把跨音乐的合法 SFX 当成异常，也不要统一清空 CH5～CH8。
2. **独立新需求**：低 HP Danger 警报“三响后渐弱至半音量”。此功能**尚未实现**，与 141 的招式命中尾音衔接、142／143 的旧等待清理无关。
3. **未逐项验收**：Link Battle、Music Off、BGM 音量 0、特殊连续倒下、180 帧上限、不同 ROM 变体；如未来有问题再按录屏时间、HP、哪方、招式、BGM/SFX 配置针对性复现。

## 开发限制与下一版起点

- 不由 AI 编译 ROM；检查远调用、标签、SFX ID／CH5 的匹配及相应 Bank 约束。项目 ZIP 没有 MAP，不能宣称实际链接空间足够。正式补丁按真实文件模式 `100644/100755`、文件内容、正反向回放分别验证。
- 本次收口只改 `TODO.md`、`PROJECT_DELIVERY_RULES.md`、`RPP_DEVELOPMENT_PITFALLS.md`、`docs/BATTLE_DANGER_SFX.md`，并新增本交接记录；`data/game_version.asm` 继续显示 **`SFX-5.62.143`**，不改任何 ASM 或玩法。
- 用户完成 143 Git Commit 并明确确认后，下一版功能可从干净的 `SFX-5.62.143` 工作树起步，下一次需要修改游戏版本时再进入 144；未确认前保留已记录的 141 HEAD 与 142／143 未提交修改的区别。
