# MUS-243 验收收口记录（2026-10-29；最新状态优先）

- **版本／基线**：`PAL-5.62.239 / HEAD 2b0d260729dbf28bc72dd9a739e646b1bfaf35e8` → 已应用但尚未 Git 提交的 `PAL-5.62.243`。`TEST-231` 未改动。
- **用户实测反馈**：本轮收到“测过了，没问题，你说的这些东西我都测过了”，按前一轮 MUS-243 指定的双向 Route30↔Route31、步行及骑行状态、GSC/RBY/RND 等模式、真实不同曲换曲、门房和既有回归项目记录为用户所述范围的通过；没有独立收到按版本标注的设备录像或最新 Red/Blue MAP，不能虚构产物细节。
- **地点验证**：此前用户明确确认 LOC-240 的存档／Continue 地址已显示正确；Route31VioletGate 在存档显示 Route31 符合 Gold 地标归属，而存档菜单的地名行是 PAL 扩展。
- **音乐实现边界**：仅当前已注册的 8 个城都活动槽位具备 Gold 场景映射；222 个稳定 ID 并未全部完成。Route30 和 Route31 使用同一首 `MUSIC_GBP_GSC_ROUTE30`，普通无缝连接在两侧场景、RBY ID 与播放缓存均一致时保持播放进度；不同曲、异常缓存、首次载入、Warp 或战斗后恢复不强行跳过选曲。
- **本次 DOC-001 清理**：游戏 ASM、WRAM、歌曲数据、地图及 `PAL-5.62.243` 版本号不动，仅同步项目文档和交付状态。仍需用户自行确认实际 Git 变更并按模式 A 的功能/工具两笔提交。未来其它地图的音乐匹配和独立设备测试为后续任务。

---

> **MUS-243 补充**：Route30↔Route31 无缝过图会在加载目标 Header 之前快照 Gold 场景与原始 RBY 歌曲；两侧同曲且当前缓存有效时保持音轨进度。此项尚未获得用户红蓝 ROM 编译或手机实测通过证据。之前 MUS-241 的静态设计本意就是不重播，但此前只验证了映射和缓存源码，不代表运行已经满足。

> **MUS-242 更正（2026-10-29）**：上一版 MUS-241 包含 `ResolveMusicStyle.rbyFamily` 不存在的汇编局部标签，用户真实构建已失败。当前源码改为 `jp .legacyStyle`，并增加完整 ASM 局部标签预检与错误注入测试。音乐场景逻辑仍待用户本地 `.242` 红蓝构建、最新 MAP 和手机实测；本文件以下 MUS-241 场景设计保持为设计依据，不代表 `.241` 已编译成功。

# PAL-5.62.241：城都原版音乐场景与首座中立门房（待手机验收）

## 资料与代码来源

- MUS-1.0.1 Gold（用户交接包）：`data/maps/maps.asm` 是地图 BGM 的主参考；其八张相关地图为 NewBarkTown、Route29、CherrygroveCity、Route30、Route31、GuideGentsHouse、VioletCity、Route31VioletGate。
- 旧 RPP `NPC-5.62.243_金银分支` 的 `engine/menu/options_menu.asm` / `home/overworld.asm` 提供既有 RBY、RBY+C、GSC、GSC+C、RND、音乐缓存与中立门房思路。旧物理地图编号及 wWarpedFromWhichMap 不得直接复制到新项目。
- 当前工程只有 8 个活动槽位；本次没有扩展其余 222 个保留的稳定编号，也没有移植新的音乐文件。

| 当前稳定 ID | 活动槽位 | Gold 原图 BGM | 当前 GSC 直选曲 |
|---:|---:|---|---|
| 0 | 0 | MUSIC_NEW_BARK_TOWN | MUSIC_GBP_GSC_NEW_BARK_TOWN |
| 1 | 1 | MUSIC_ROUTE_29 | MUSIC_GBP_GSC_ROUTE29 |
| 2 | 2 | MUSIC_CHERRYGROVE_CITY | MUSIC_GBP_GSC_CHERRYGROVE_CITY |
| 3 | 3 | MUSIC_ROUTE_30 | MUSIC_GBP_GSC_ROUTE30 |
| 4 | 4 | MUSIC_ROUTE_30 | MUSIC_GBP_GSC_ROUTE30 |
| 125 | 5 | MUSIC_CHERRYGROVE_CITY | MUSIC_GBP_GSC_CHERRYGROVE_CITY |
| 5 | 6 | MUSIC_VIOLET_CITY | MUSIC_GBP_GSC_VIOLET_CITY |
| 6 | 7 | MUSIC_ROUTE_30 (Gold 原始记录) | 中立门房：继承来源 31 号路或桔梗市 |

## 关键路径与约束

1. 31 号路／桔梗市进入门房：在 `JohtoPilotResolveRegisteredWarp` 仍持有源 `C` 时，将稳定 ID 写入 `wJohtoGateMusicSourceLocalID`，仅目标是门房 ID6 时写入。此步骤在 `wCurLocalMapID` 更新之前。不能用 `wWarpedFromWhichMap`（共享 `$FC`）或 `wLastMap`（可能陈旧）来猜来源。
2. `JohtoPilotLoadMapMusic` 默认按照 8 个已验证活动槽位的 profile 设置 RBY 曲目；只有门房才按来源改成 Route31 的 `MUSIC_ROUTES1` 或桔梗市的 `MUSIC_CITIES1`。新/旧存档来源未知时退回 Route31，不跳到未注册歌曲。
3. 仅请求当前地图的 `wMapMusicSoundID` 才经过 `LookupJohtoMapGSCMusic`：经稳定 ID → 当前活动槽位查表；门房单独读取真实来源。Gold 原曲不同但 RBY ID 相同的跨图必须经场景缓存更新触发换曲。
4. `CheckJohtoMusicSceneTransition` 不抽 RND，只在加载地图时决定是否清除 `wLastMusicSoundID`。同主题的 Route30↔Route31、吉花市↔向导家及来源→门房不中断原曲；不同主题如吉花市↔桔梗市必须换到新 Gold 歌曲。
5. RBY/RBY+C、GSC/GSC+C、RND 仍使用原 Options 格式。Bike Song On 有独立骑行曲；Off 不触发骑行重播，继续选地点音乐。Surf、Battle、GB Player 直选 ID 保留全局现行映射，不改变存档长度和 ROM 编译责任。

## 必须由用户完成的 ROM/手机验收

- 同一张地图内切换五种音乐模式并再次存读档；RBY、RBY+C 不因城都场景缓存强制重启。
- Route31→门房→原路退回（曲目不断、RND 不重抽）；Violet→门房→原路退回（同理）；Route31→门房→Violet 与反向都应换为目标曲。
- 吉花市→向导家→返回；Route30↔Route31 同 Gold 曲不无故重播；吉花市↔桔梗市使用不同 GSC 歌曲（即便 RBY 基础 ID 相同）。
- Bike Song On、Off 切换与地图切换；Surf/飞行/渡轮；门房内部存档/Continue 及读取后两侧行走；关都普通屋子、Options、随机选择；正式红蓝版构建与 `.241` MAP 空间。
- 本次静态审计和测试不能代替上述游戏运行证据。正式/测试构建及 Git Commit、Push 均由用户自行操作。
