# REF-369U@｜烧焦塔与冰之通路共用黑色玩家落洞过渡、Gold 岩石色及 B2F 首帧落石

## 源码定位

- 对照用户 Gold 与 RPP 两段玩家落洞录像。Gold 下层首次淡入时已经看得到先前推落的灰紫色石头；REF-369T 则在玩家落地后才出现黄褐色石头。Gold 的该段录像没有证明 Seafoam Islands 的每个洞都使用相同到达方案。
- `data/johto_burned_tower/REF348_b1f_runtime.asm` 原来 Burned Tower 走 `GBFadeOutToWhite`/`GBFadeInFromWhite`，Ice Path 走 `PlayMapChangeSound`/`GBFadeInFromBlack`。REF-369U 统一为现有普通洞穴黑色过渡，仍只用既有 `wd732` bit7 区分普通换层与 Skyfall 动作，不引入新的 Fade 变量；音效与坠落运动保持。
- `color/sprites.asm:LoadOverworldSpritePalettes` 原来未识别 `JOHTO_ICE_PATH`，导致 Cave 的 `SPRITE_BOULDER` 在 Gold ICE 洞内使用白天黄色 `PAL_OW_ROCK`。现在同已存在的 ICE_CAVERN/CAVERN 分支选择 `SpritePalettesNite` 的灰紫色 ROCK，不改 `SpritePaletteAssignments` 的全局映射，不改变关东野外／Seafoam 图形逻辑。
- 仅对于进入 `JOHTO_ICE_PATH_B2F_MAHOGANY_SIDE_LOCAL_ID` 的地图，保留先 `InitializePitState` 再 `SyncLanded`，随后在淡入前调用已有 `UpdateSprites`，使已推入洞中的石头尽早产生正确显示坐标，同时未落下的四块石头继续隐藏，合法 Sprite Picture ID 不得清零。不要把该预刷新加入 Seafoam 或通用 Render Loop。

## Seafoam Islands 差异

Red++ 的关东双子岛通过 `scripts/SeafoamIslands[1-4].asm` 内的事件 `HideObject` / `ShowObject` 与 `wSeafoamIslands4/5CurScript` 管理石头和水流，不复用 Johto `JohtoIcePathB2FMahoganySyncLanded369B`。本轮没有证据能断言 Seafoam 的所有实际到达帧与 Gold 一样；没有实机运行之前只报告源码机制和不修改事实。

## 验证与验收边界

- 新 `tools/johto_ice_path_pit_arrival_visual_369u_audit.py` 进入项目统一源码门禁，配合负向测试检查共享黑屏、Gold 洞穴精灵色板、B2F 预刷新次序，以及关东 Seafoam 独立路径。
- 这不是 ROM 编译或视频验收。用户需重建 Red/Blue/TEST Red/TEST Blue，核对 MAP/ROM0 和实际手机效果；特别查看 Burned Tower 玩家洞、B1F 四洞首次落地、四个坑位的石头显示与保存读档。保留 REF-369A 旧 SAV 风险。
- 不修改已基本验收的落石震动、Strength 音效、提示文字或烟尘算法。本轮不执行 ROM 构建、Commit 或 Push，版本仍为开发态 `REF-369U@`。
