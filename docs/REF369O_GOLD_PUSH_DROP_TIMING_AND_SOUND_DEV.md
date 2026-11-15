# REF-369O@ — Gold 石头入洞立即消失、独立烟尘与额外音效（开发态）

## 本轮定位到的实际问题

1. RPP 推石引擎的 `MoveSprite` **只排队**一格 NPC 移动；`home/vblank.asm` 的 `DelayFrames` 通过 `DelayFrameHook` 更新 OAM，但 **并不更新** `engine/overworld/movement.asm` 的 NPC 地图移动。先前 `BeginJohtoGoldStrengthDust369L` 直接阻塞 16 帧，导致石头画面等待后才继续动作。单纯把 16 改成 32 会进一步延长冻结，是错误修复；本轮删除这段人工延时。
2. Gold 的 `IcePathB1F.StoneTable` 在石头进入坑后立即 `disappear`，**然后** `pause 30`、第二次 Strength 音效和 `earthquake 80`。本项目 B1F 地图脚本用 `wFlags_0xcd60` bit7 表示有待检查的推石动作，并在本地图重入通用推石入口时阻止 `wBoulderSpriteIndex` 被覆盖；改为等待 `wd730` bit0（NPC 移动脚本执行中标记）真正清零后再检查坑和立即隐藏。这样按引擎实际完成状态触发，不靠盲猜延迟帧数。
3. Gold `MovementFunction_BoulderDust` 使暂存烟尘持续石头逻辑移动步长的两倍。RPP 一格移动用 16 个 30Hz 逻辑步进（相当于 32 个 60FPS 显示帧），故烟尘保持 64 显示帧，并以 4 显示帧切换一次 Gold 两帧纹理。四象限、色板和 OAM 安全区仍与前版一致。
4. `DoBoulderDustAnimation` 原本在所有地区结束时额外播放 `SFX_CUT`。城都现在跳过这个旧版多余音效；关东仍执行原路径。Gold 推石时的 Strength 和掉落后第二次 Strength 保留。

## 范围与验证限制

- 保留原 REF-369E 保存花屏修复、H 撞墙安全、J 即时隐藏结构、M 2px 地震、N 四象限烟尘。
- 不更改关东原怪力动画／音效逻辑（除了此前已经关闭的闪白），不改存档格式、事件位、玩家踩洞、BANK0。
- 动作时序基于 Gold 源码与 RPP 引擎控制流程推导；仅静态审计不能证明在手机与原版逐帧一致。需用新 ROM 实测确认：推到洞口完成移动当帧消失、余烟尚在、仅有两次 Strength、之后震动、B2F 保存不花屏。
- 本轮不自行编译 ROM，不做 Git Commit/Push，仍是开发候选版本。
