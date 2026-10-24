# 音频专项交接记录 — SFX-5.62.141（2026-10-14）

> 分支：`常规功能备份`。这是本阶段的源码／测试交接说明，不是 ROM 编译日志或已执行的 Git 提交证明。

## 1. 可靠基线与交付

- 原始项目 ZIP：`feat(dex)__定版大木博士地区形态研究统计并修复文本翻页.zip`，`data/game_version.asm` = `DEX-5.62.131`，导出 HEAD `ac1612cea3ca0fb9e8c8383ee8ce4d9e4994f15f`，干净导出，无工作区补丁。
- **用户明确确认已 Git 提交的最近版本：`MENU-5.62.139`**。具体提交 hash 尚未收到，不要伪造；`SFX-5.62.140` 获测试反馈，但没有用户确认其独立提交，所以本次拟提交日志合并 140 和 141，跨度 **139 → 141**。
- 游戏可见版本：`SFX-5.62.141`，本次验收清理不再增加版本号。
- 交付物：从已应用 141 的工作树到验收清理后的**纯文档增量补丁**、从上述 131 项目 ZIP 到验收清理后的**累计全量补丁**、包含两者和 `commit-message.txt` 的合集 ZIP。增量与全量不能叠加；增量**不能直接用于仅有 139 或 140 的代码**。
- 代码未由本次清理改动；141 的音效修复在 `engine/battle/animations.asm` 三个调用入口，以及 `engine/battle/battle_sfx_wait.asm` 浮动 ROMX 例程中。

## 2. 本阶段实际实现

### 140：开场中断音效清理

- `engine/intro.asm` 中 GAME FREAK 流星、耿鬼／尼多力诺动画提前按 A/START 结束时，调用 `StopInterruptedIntroSFX` 清除 CH5～CH8 的 SFX 活动状态，并关闭对应 APU 硬件声音；自然播放的流程不强制截断。
- 浮动 ROMX 例程：`engine/intro_sfx_stop.asm`；不要在全局 `PlayMusic` 里统一关闭 SFX，以免破坏战斗多声道叠加。
- 用户对照原版红和 RPP 后反馈 140 修复“没问题”，只确认实际体验中之前报告的提前跳过尾音消失，不虚构全部按钮、所有音量配置分别验收。

### 141：低血量招式与通用命中声的等待衔接

- 旧 `WaitForSoundToFinish` 在 `wDanger != 0` 时直接返回，导致招式尾声尚未结束时就进入下一段命中声；Crysaudio 允许部分不同音效声道同时播放，会使现象更明显。
- `engine/battle/animations.asm` 中只替换 `MoveAnimation` 进／出与 `PlayApplyingAttackSound` 前的**三处**等待为 `callba WaitForBattleAnimationSFX`。
- 新例程 `engine/battle/battle_sfx_wait.asm`：普通 HP 走原 `WaitForSoundToFinish`；低 HP 轮询 CH5～CH8 活动位，按帧等待；尊重 `wSFXDontWait`，上限 180 帧，防止意外卡死。保留游戏原有合法的音效叠加，不静音警报。
- 浮动 ROMX 由 `main.asm` 包含；没有增添 SRAM 字段，也不更改存档布局、地图、招式素材或全局 Crysaudio。

## 3. 用户验收（请精确保留范围）

- **141 受测通过**：用户对比修复前后，修复前低血量时确有残留；修复后伏特攻击、Spark／电光、撞击及其他普通招式恢复正常，双方（玩家／敌方）都已测试。
- **140 受测通过**：之前流星按 A 提前跳过时的残留音效在 140 中已消失，用户反馈没有问题。
- **未逐项证明**：Thunderbolt、连续多段／替身、MISS／免疫、动画关闭、低 HP 危险警报的独立节奏、静音／BGM Volume 0、180 帧等待上限、不同 ROM 变体、长时间游戏回归。不要标作“全场景验收”。
- Mateo 常驻、标题叫声完整、标题轮播保留原行为、138 的主菜单白屏优化、Continue 信息页 B 返回防闪烁均属于前序功能，不属于此次音频补丁新增改动。

## 4. 后续音频缺陷与建议优先级

1. **电梯提示音**：`engine/overworld/elevator.asm` 旧 `wChannelSoundIDs` 等待与 Crysaudio 活动标志可能不一致；先确认切换 BGM 时是否提前放行，不要对所有地图一键静音。
2. **训练师战斗宝可梦倒下**：`engine/battle/core.asm` 中 `SFX_FAINT_FALL` → `SFX_FAINT_THUD` 的旧标志等待可能导致前者被提前覆盖；单独审查并双侧验证。
3. **需先复现的场景**：宝可梦中心治疗结束、地图音效接战斗 BGM、飞行／传送等。部分音效跨音乐保持是原设计，修复不应全局清除通道。
4. **另一个独立需求**：`TODO.md` 的低 HP Danger 警报“三响后渐弱到半音量”尚未实现，和 141 的招式尾音重叠不是同一个问题。

## 5. 开发与验收纪律

- 先读 `RPP_PROJECT_CONTEXT/03_PROJECT_REQUIREMENTS.txt`、`PROJECT_DELIVERY_RULES.md`、`RPP_DEVELOPMENT_PITFALLS.md`。
- 不由 AI 编译 ROM；每轮检查 RGBDS 汇编标签／远调用、HOME／Bank 空间和 MAP（若提供）；无 MAP 不能声称已实际链接。
- 补丁按精确版本、文件权限 `100644/100755` 和工作区状态分别正向与反向验证；清理三件套必须包含提交日志。
- 新一轮音频问题请先记录按键、HP、哪一方使用、招式、SFX／BGM 配置与视频的确切重现条件，再做小范围补丁；不要回滚或同时重写已验收的 139／140／141 功能。
- **用户需要在本地自行 Git Commit／Push**；本文件生成本身不代表已提交 141。若用户之后明确确认提交，再将 141 作为下一轮已确认的基线。
