# REF-369V@｜玩家 PIT 去门音效与无效首帧预刷新回滚（开发候选）

## REF-369U 手机反馈与判定
- REF-369U 实测视频 369U.mp4 仍显示：Ice Path B2F 的已落石头在玩家落地后才进入可见画面。REF-369U 新增的 `call UpdateSprites` 没有达到“落地前已可见”，故本轮撤销这条预刷新；保留 `InitializePitState` + `SyncLanded` 对未落石头的隐藏保护。**首帧显示问题仍未修复，不要标记已通过。**
- REF-369U 的 Burned Tower/ICE 共用黑屏过渡和 ICE 洞穴灰紫色岩石已在用户录像／截图中出现，本轮保留。
- 用户指出踩洞时 Gold 不播放进出门声。源码证实：REF-369U 的 `PlayMapChangeSound` 会在淡出前播放 SFX_GO_INSIDE/OUTSIDE；Gold `FallIntoMapScript` 在加载地图后播放 KINESIS 和 STRENGTH，非门声音效。不能把 Gold 的完整下落过程概括成“完全无声”。

## 修正
- 在 HOME `PlayMapChangeSound` 的 `call PlaySound` **之后**新增 `PlaySilentMapChange369V::` 入口；这是纯标签，不增加 ROM0 机器码。原普通门入口仍先播放门声，再落入同一安全黑屏淡出流程。
- Burned Tower 与 Ice Path 的玩家 PIT 统一跳到这个无门声入口，沿用 `hMapLoadVRAMSafeFlag`、CGB 色阶和原有 Fade，保留两图的坠落/落地声音和震动。不会影响普通楼梯、房门或 Seafoam 脚本。
- 撤销 REF-369U 在 B2F 首帧前多余的 `UpdateSprites`，不另加新刷新或新状态变量，避免未验证的多余调用；真正首帧落石问题另行处理。
- 增加专项源码及负向用例，更新旧审计中与 U 无效预刷新和门声冲突的断言。静态测试不能替代 ROM、Gold 音视频和手机验收。

## 验收
1. Burned Tower 和 Ice Path 踩洞不播放普通进出门声，仍走黑屏，落下后保留 KINESIS/STRENGTH 与震动。
2. 正常房门／楼梯的音效和淡入淡出不变；Ice Path 石头仍灰紫色。
3. Ice Path B2F 未落石头仍隐藏，已落石头可能仍在落地后出现（本轮未修复）。
4. Seafoam 的 HideObject/ShowObject 逻辑不改；其首帧显示行为尚未通过设备验证，不应宣称与 Gold 或 Ice Path 一致。
5. 不自行编译 ROM，不 Commit/Push。开发 ZIP 按规则只含两份互斥正向补丁。
