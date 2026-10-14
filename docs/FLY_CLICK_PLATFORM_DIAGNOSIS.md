# Fly click — 游戏与模拟器边界、144/145 试验归档（2026-10-14）

## 结论与验收范围

- 当前游戏基线来自用户提供的 `SFX-5.62.145` 工作区导出，记录 Git HEAD 为 `79f1f6b4730b4ebbb2ac1a2d2bb520e77861511f`（已提交的 143）；144/145 为工作区试验而非新的确认提交点。
- 用户在 My OldBoy 和另一款 GB/GBA 模拟器上实测：同一 143 ROM 的 Fly 起飞／降落未听到末尾 click；GBPocket 的现场播放与内置 MP4 录像均可听到 click，且 144 录像显示 Music On/Off 均可出现。**本项目 Fly 游戏侧标记为 PASS（上述跨模拟器场景），不等于证明任何游戏／设备组合都绝对无 click。**
- 飞行过程中播放流程本来就会暂停 BGM；开启／关闭音乐在该段听感差别不大，不能靠音乐开关推断音效数据有错。当前更合理的处理是把 GBPocket 平台差异归入模拟器专项，**不继续为了这一模拟器的异常修改游戏 Fly 音效**。

## 保留的技术观察（不把假设写成已证明根因）

- `EnterMapAnim` 与 `_LeaveMapAnim` 均播放 `SFX_FLY`，Crysaudio 使用 CH8／硬件噪声 CH4；音效本身的最后已有静音 noise 指令。143 与 144 录屏在正常最后一声结束后仍出现附加短脉冲，提示需观察 APU/模拟器尾声处理。
- **FLY-020 / 144 已试且未解决**：增加 `PlayFlySFX` 包装器，`MusicResumeMask |= $88` 保留 NR51 噪声输出路由；用户的 144 视频仍有 click，因此不能视为已验收修复。
- **FLY-021 / 145 未证明有效**：在 Crysaudio CH8 `endchannel` 检测 `SFX_FLY` 后，跳过额外 `Rest/ClearChannel`，模拟原版 Audio2 噪声尾声处理。这是有意义的引擎行为差异，但没有证明它是 GBPocket click 的起因。
- 模拟器专项的可检验嫌疑：GBPocket 的 SameBoy 音频生成率由核心默认较高采样率改为 48 kHz，以及 `accurate` 高通滤波、共享 PCM 生成／采样路径；现场播放与内部录制都存在 click，优先验证两者共同的上游。Android `AudioTrack.WRITE_NON_BLOCKING` 未处理部分写入也有独立风险，但**单独的播放端缓冲问题不足以解释内部录制中的相同声音**。这些均为待 A/B 验证的候选，不是定论。

## 这次撤销的运行时代码（ANIM-5.62.146）

- 完整撤销 144 的 `PlayFlySFX` 与 NR51 `$88` 保持：`engine/overworld/player_animations.asm` 起飞和降落恢复 `ld a, SFX_FLY / call PlaySound`。
- 完整撤销 145 的 `SFX_FLY` 专用 `endchannel` 绕过：`crysaudio/engine.asm` 恢复 143 的普通 CH8 收尾分支。
- 仅撤销这两轮试验新增的游戏行为；之前的 140–143 音频清理、游戏音效原始数据、动画时长与音乐恢复机制均保留。原 144、145 handoff 的有效观察汇总在本文件，废弃的待验文档移除。

## 后续处理

- GBPocket 异常由独立的模拟器工程排查，不在本游戏工程里通过音量淡出、额外静音、全局 CH8 修改掩盖。
- 如以后发现同一游戏 ROM 在非 GBPocket 的可信模拟器或实机上稳定复现，请重新打开游戏侧 Fly 问题，附准确 ROM 版本、模拟器、录音和复现步骤；不得将这里的 PASS 扩大解读。
