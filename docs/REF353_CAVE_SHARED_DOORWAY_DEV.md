> **状态更新（2026-11-07）**：本页保留开发阶段分析及此前“待验收”的历史条款。最新 `REF-353.patch` 已含 `FadePalDarkBG353 + 11` 和 `FadePalAlreadyDark353 + 11` 热修；用户 `353修复.mp4` 已覆盖 Rock Tunnel 开/未开 Flash 出洞且画面表现正常，正式收口与剩余测试请以 [`CLEAN REF-353 验收记录`](CLEAN_REF353_CAVE_SHARED_DOORWAY_ACCEPTANCE.md) 为准。游戏运行 ASM 在正式清理时不变。

# REF-353 开发过程记录｜山洞与房门共用黑色转场 / LCD-on 加载

## 用户目标
- 岩山隧道（Kanto Rock Tunnel）和城都 Dark Cave 的正常进出，与 REF-352 普通房门相同：黑色渐暗、保持 LCD 开启安全上传新地图，不允许黑→白→黑。
- Flash 仅改变洞内明暗，不再控制是否关闭 LCD；无 Flash 时不能在过渡中短暂露出全亮洞穴。
- 保留 REF-352 的地图 HBlank DMA、VRAM 安全双字节图形复制、主角图块 guard、音频、特殊 Warp/战斗回归旧路径。

## 本次修改
1. `home/overworld.asm`：Route 10 进 Rock Tunnel 不再先单独淡黑一次；`PlayMapChangeSound` 对所有正常 Warp 同样完成黑色渐暗并启用 `hMapLoadVRAMSafeFlag`。不再根据 `wMapPalOffset` 切换 LCD-off。
2. `home/fade.asm`：已暗的旧画面（BGP=FE）在渐暗阶段不能先回到明亮 E4。若 OBJ 已暗，使用暗 BG/OBJ→全黑；若 OBJ 仍亮（Johto），使用暗 BG+逐步变暗 OBJ→全黑。两条路径都是原来的 4×8 帧；普通明亮房门继续使用 REF-351B RGB555 原路径。
3. `engine/johto_pilot_runtime.asm`：出未照亮暗洞时不再在 Warp 解析阶段直接设 BGP/OBP=0（白屏）；保留 offset12，到地图加载完成后恢复目的地图 offset。
4. `engine/johto_dark_cave_stage2.asm`：普通洞口 LCD-on 加载时清理延迟的 offset，但**不立刻执行 `LoadGBPal`**；继续保持黑屏直到主角图形加载完成，回到 OverworldLoop 时恢复洞内或室外调色板。其他 LCD-off 入口依旧立即刷新。
5. 仅开发候选版号更新 `REF-352@` → `REF-353@`；同步修正旧测试／审计合同，增加 7 项专项负向风险相关静态检查。

## 验证边界与必须实测的路径
- 静态源码检查、专项测试和补丁回放可以执行；**没有 RGBDS 0.5.2、没有新 ROM/MAP、没有手机实测时，不得声称白闪完全消失或者四种 ROM 已通过构建**。
- 本机需先编译 Red、Blue、TEST Red、TEST Blue，确认 ROM0≥64B；然后在 My OldBoy 同设备同路线录进洞/出洞，无 Flash 与使用 Flash 后各一遍。
- 必须逐帧检查 Route10↔Rock Tunnel 1F，以及 Route31/Route46↔Johto Dark Cave。注意出洞不露出亮紫洞、无整屏白色、洞内角色清晰、音频连续；普通房门对照 REF-352 无退化。
- 暂不改变剧情洞穴 Fall/Warp Pad、战斗返回、初始菜单和仍未开放的 Gold 内容。
- **本轮为开发补丁，不是清理三件套；未在用户 Git 仓库 Commit/Push。**

## REF-353 开发候选热修：暗洞出门过渡期人物残影
- 用户 `353.mp4` 在未开 Flash 出岩山隧道时约帧 279–285 出现未遮住的旧／新 BG 图块和黑色人物轮廓，开 Flash 后出洞不出现。
- 根因：两条新增暗洞渐暗例程误从 `FadePal...353+2` 开始 `GBFadeDecCommon` 的逆向三字节读取；每组 3B、共4组，正确起点必须是表内第4组末字节 `+11`。原先第一阶段读取最终全黑、后续却倒退到前一个无关的 FadePal 表；岩山隧道专用分支的最后一阶段落在 `$FE`，导致 LCD-on 显存写入期画面泄漏，表现出拼接／残影。
- 本热修只改 `home/fade.asm` 两个表游标并增强 `test_cave_doorway_unified_353.py` 的指针校验；不改 Flash 成功后的普通 RGB555 黑色渐暗、REF-352 普通房门安全复制及显示版本 `REF-353@`。
- 已做静态定向检查；仍需用户本机 ROM 构建和录像验收，尤其检查未开 Flash 出洞整段纯黑，以及城都暗洞未开 Flash 出洞无白色反闪。
