# ANIM-5.62.146 — Volt Tackle 双向高频横震验收记录（2026-10-14）

## 用户选择与效果

- 用户上传《145伏特攻击.mp4》和《146伏特攻击高频短横震.mp4》，比较的重点是**敌方使用 Volt Tackle 攻击本方**的命中段，并明确表示「这版满意了，提交吧」；因此 **146 视觉方案定版**，不再把 146 当作临时试验或删除当前新增横震。
- 代码仅去掉 `H_WHOSETURN` 对敌方施放的两处屏蔽：起始 `wBattleAnimWXEnabled` 现在双方均开启；`.SetImpactShake` 不再对敌方 `ret nz`。双方在命中前 18 帧交替 WX=5/9（基准 7、±2px）；最后 6 帧回复 WX=7，结束时重置并关闭 latch。
- 五段电流扫屏、粒子、攻击者回位、命中音效及 `PlayApplyingAttackAnimation` 的普通受击反馈维持原逻辑。未修改通用 VBlank、其他招式、WRAM/SRAM 布局或全局画面震动。

## 设计来源与保留差异

- 旧实现的注释明确写有 `Only player use keeps this horizontal impact shake; enemy use gets the standard vertical hit feedback after the move`。可确认以前的方向差异**是有意保留**，但未找到关于为何采用该观感取舍的独立美术理由；不要把「防止横竖震叠加」当作已有证据的作者原话。
- 先前对照《绿宝石》`Move_VOLT_TACKLE` / `AnimTask_ShakeMon2` 的分析表明，GBA 方案在受击目标 `ANIM_TARGET` 上摇动，未由这一命令限制攻击方向。本项目因 GB 显示机制改用 WX 改变整幅战斗画面横向偏移，连 HUD 也会受到影响。**146 是用户选定的项目表现，不声称像素级复刻绿宝石。**
- 其他招式的攻击方向反馈可能属于面向前图／背图的有意适配，不能因为 Volt Tackle 收口便自动成批去掉方向分支。后续若做局部目标震动，另起新版本／独立补丁，并保留 146 的可回退基线。

## 验收边界和交付

- 这次属于用户根据两段录像做出的**观感验收**；146 实机 ROM 构建、敌方连续使用、异步动画中断及所有画面模式未由本环境逐项确认。项目 ZIP 无 MAP，本环境遵照约束没有编译／链接 ROM，也没有执行 Git Commit／Push。
- 游戏内显示版本保留 `ANIM-5.62.146`。此次验收清理只更新项目文档，不再改 Volt Tackle ASM、飞行 ASM、Crysaudio 或其他功能代码。正式提交日志应覆盖最近已记录的真实 Git HEAD `79f1f6b4730b4ebbb2ac1a2d2bb520e77861511f`（143）至定稿 146，而不是仅写这次文档清理。
