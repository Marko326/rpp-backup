# REF-357｜图鉴前开放卧室 Player's PC（#45 开发候选）

对照 ROM-1.42H #045 `fb3d1051` 的**非汉化**部分。只移植卧室入口分流与取得图鉴后的博士英文提示；不复制对照工程 Bill's PC 改写、中文资源或其他菜单配置。

- **图鉴前**：`OpenRedBedroomPC` → `SaveScreenTilesToBuffer2` → 清除 `wFlags_0xcd60` bit3（独立 PC 模式）→ `PlayerPC`。保留原有开/关机音效、Withdraw/Deposit/Toss/Log off、REF-355 两行道具说明和 REF-356 数量框行为。先保存 Buffer2 是为了退出后还原卧室画面。
- **图鉴后**：仍走 `callba ActivatePC`，不改共用完整 PC 的 Bill's、Player's、Oak's 与既有 League 选项门控。
- **图鉴领取提示**：博士研究所 `OaksLabText25` 原图鉴获得文本及 `TX_SFX_KEY_ITEM` 后追加 `TX_FAR _OaksLabHomePCUpdatedText`，新英文正文放在 `text/maps/OaksLab.asm`。以 `text ""` + `para` 独立起段，告诉玩家家中 PC 已升级、可以存取宝可梦；随后继续原本的博士对白。新增提示只在取得图鉴剧情时播放，不在每次使用卧室 PC 时重复。
- **历史保留**：旧 `.temporarilyUnavailable` 的 `ld hl`/`call PrintText`/`ret`，以及 `RedBedroomPCUnavailableText` 的全部文字和结束码，逐行变为 `;` 注释；不占用 ROM 文本数据。
- **数据**：不增加 SRAM/WRAM，不改道具、宝可梦存储或剧情事件；只补原有剧情文本链。版本 `REF-357@`。

## 手机验收（新游戏与旧档）

1. 刚开始、尚无图鉴时，在二楼卧室 PC 按 A：应直接打开四项 Player's PC 菜单，不出现旧的 `The PC can't be used right now.`。从 Log off 或 B 退出，卧室地图和人物不花屏。
2. 图鉴前准备可存物品：Deposit、Withdraw、Toss 三项，分别测试无物品、正常物品、TM、HM（仍不允许存 HM）、数量选择、Cancel 和 Log off；仍显示两行道具说明。
3. 领取图鉴的音效结束后，检查博士新增英文提示独立起段：家中 PC 升级，能存取宝可梦。按键翻页后应继续博士原有剧情，不能把提示连在 `got #dex` 后半行，也不能重复触发。
4. 获得图鉴后重进卧室 PC：应出现原完整 PC 主菜单（Someone's/Bill's、Player's、Oak's，League 是否出现仍遵循原先条件），能返回地图；宝可梦中心 PC 不受影响。
5. 使用图鉴前/后旧存档测试，不应新增永久标志位或改变背包与 PC 库存。

## 证据边界

开发阶段仅执行针对性源码和分支测试、补丁正反向回放；本环境未执行 RGBDS Red/Blue/TEST ROM 构建、MAP 余量核验或设备实测。
