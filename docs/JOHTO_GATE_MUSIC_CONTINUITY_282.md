## CLEAN-282｜用户反馈与最新 MAP 收口（2026-10-31）

- 用户确认：进入门房普通步行音乐原本正常；此前实机漏洞是**骑自行车且关闭自行车专属音乐**时重复开始来源曲，应用 `.282` 后这一漏洞已解决。该反馈限定于这条复现路径；其它模式/所有门房方向未获得完整逐项验收。
- .281 北门房两格Warp地毯横向步行/骑行问题也已由用户确认解决。旧章节“仍需用户新MAP”的叙述是开发时历史记录，不应覆盖以下新证据。
- 新上传 `MAP_20261031_131234.zip`：`rppred.map` 和 `rppblue.map` 均列 ROM0 Slack `$0054`=84B，达到项目64B下限；附带版本说明为正式 `FIX-5.62.282`、测试 `TEST-231`。本轮清理未改游戏可执行源码，无需提升版本。
- 下一步独立开发 `Route35GoldenrodGate` + `Route35` 时，继续使用 `johto_gate_music_bike_audit.py` 验证来源、RBY/GSC分支、Bike Song Off 的 Carry 清理、Warp不强制同曲重播及门毯骑行；不能把普通步行表现当作自行车路径通过的证据。

# FIX-5.62.282｜城都5座活动门房音乐续播防回归

## 发现

1. 既有 `MUS-259` 审计检查5座活动门房的音乐来源、骑车许可、场景缓存，但主要验证源码中出现的 CP 稳定 ID 与分支片段。它无法发现桔梗市 → Route31VioletGate 的合法来源比较通过后仍继续执行 `.southForestGate` 的落空分支。
2. `PlayDefaultMusicCommon` 的普通步行/骑车关音乐路径共用 `CompareMapMusicBankWithCurrentBank`。该存根为一条 `ret`，无法保证 Carry。`wWalkBikeSurfState=1` 且 Bike Song Off 时，前面的 `cp $2` 设置 Carry，随后的 `bit` 保留 Carry，返回后 `jr c,.next4` 会跳过 `wLastMusicSoundID==目标曲` 的缓存判断。新门房因此可能把同一首背景音乐从头请求，骑车比步行容易触发。

## 净修改

- `home/audio.asm`: 存根中使用 `and a` 清理 Carry；保持入口、返回形式和既有“不同歌曲才启动”的 `ret z` 机制，不改变歌曲数据。
- `engine/johto_pilot_runtime.asm`: 桔梗市合法来源通过后显式 `jp .sourceValid`；Route31 另一侧、遗迹两座门房、桐树林两座门房的实际来源规则不更改。
- `tools/johto_gate_music_bike_audit.py`: 解析当前激活地图/显式门房合同后，逐个解释 RBY 与 GSC 两个门房分支，检查全部合法及非法来源最后选到的稳定 ID。检查触发器会在 Carry 清理删除、强行重启 Warp、某侧错选另一来源或错误落空时失败。
- `tools/tests/test_johto_gate_music_continuity_282.py`: 8项专项测试覆盖上述负向注入。Gold 原版环境、骑车许可与已登记的5座门房仍由既有 `MUS-259` 审计复检。

## 完整验收仍需用户

- Route31/Violet 双向、Route32/Ruins 双向、Route36/Ruins 双向、Azalea/Ilex 双向、Ilex/Route34 双向；分别在步行、骑车、Bike Song On/Off 及 RBY/RBY+C/GSC/GSC+C/RND 模式测试：**同一进入来源音乐不中断且不从头开始，穿过门房到不同歌曲地区才换曲**。
- 补测在门房内保存并 Continue，及出门骑车落地后保持正确音轨；继续测试自行车快捷键和原有森林碰撞，关都旧门房不变。
- 未生成新版 ROM/MAP；若新 ROM0 MAP 余量不足64B，须先修容量再交付正式运行验收。本报告仅证明离线源代码审计，不等于播放光标实测。
