# REF-348 Gold / 手机视频对照：落洞音效热修（不升版）

- 参考：用户 Gold版.mp4 / REF348.mp4；Gold 原版 `engine/overworld/events.asm` 的 `FallIntoMapScript` / `LandAfterPitfallScript`，及 `engine/overworld/map_objects.asm` 的 Skyfall/ScreenShake。
- Gold 流程是 MAPSETUP_FALL → SFX_KINESIS → skyfall(16等待＋16下落) → SFX_STRENGTH → earthquake16（16帧震动＋16帧静止）。不把跳崖影子误认为落洞生成的特效。
- REF348现有 `SkyfallOffsets` 已近似 Gold 的 d=96 四分之一正弦轨迹；新录屏再次对照：Gold的16个震动对象步以每2个显示帧换向；旧RPP 16次SCY换向每显示帧一次，速度偏快。现在仍复用SCY振幅，但每步保持2帧，Skyfall每个位移也保持2帧；震后等待对应延长到32显示帧。
- 明确音效缺陷：旧版分别调用 RBY `SFX_FAINT_FALL` / `SFX_BATTLE_26`，不是 Gold 独立音轨。修为 `GSSFX_BURNED_TOWER_KINESIS` / `GSSFX_BURNED_TOWER_STRENGTH`，仅在现有 RPP SFX pointer 表新增指向 `Sfx_Kinesis` / `Sfx_Strength` 的引用，不拷贝音效数据。
- 影子属于既有 `HandleLedges` → `LoadHoppingShadowOAM` 的跳崖动画。不能根据同屏黑影臆断是 PIT 造成；需要手机再测试两类不同动作，尤其关闭金手指/加速。
- 仅有静态源码核验，无 Red/Blue/TEST 编译、MAP 或机上实测证据；用户实测后再决定是否细调过渡和跳崖阴影停留。

## 最新逐帧测量（2026-11-05）
- 参考素材：Gold版.mp4（约59.7fps）、348RPP.mp4（约58.9fps）。
- Gold落地震动的背景纵向位移约 -2/+2 像素，非左右；换向出现在第160、162、164……帧。RPP同样纵向约 -2/+2 像素，但第172、173、174……帧逐帧换向。
- 角色位置：Gold可见下落时，红色衣物位置约每两帧更新一档（录屏帧126～150）；RPP每一帧更新一档（帧157～171）。视觉上的“落得快”不是正弦表错，而是播放节奏不一致。
- 改动只触及REF348_B1F落下/震动的DelayFrames参数，不扩大其它地图或引擎动画。不等于已手机验收。
