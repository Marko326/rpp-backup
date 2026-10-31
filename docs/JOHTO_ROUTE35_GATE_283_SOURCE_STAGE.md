# MAP-5.62.283｜满金北门房＋35号路：原版资源、激活与回归审计

## 当前工程和参考来源

- 最新用户源码：`FIX-5.62.282.zip`，干净 Git HEAD `2b171bcdcfa8a08570d19af136f9ee6d02f5cb0b`，分支“常规功能备份”。本开发候选实际显示版本提升为 `FIX-5.62.283`，测试版本 `TEST-231` 不变。
- 用户已补传完整 `JOHTO_HANDOFF_276_TOOL277_20261031_FLAT.zip`，其中有 Gold `pokegold-master` 和旧 NPC-243 成熟参考。已逐字节取得 Gold `maps/Route35.blk`（180B，10×18块）和共用 `maps/NorthSouthGate.blk`（20B，5×4块）。不得用满金市北侧3行预览冒充180字节原图。
- 原 `.282` 活动地图21张；本批注册35号路＋满金北门房后为23张。新地图数据归属原版 Johto 图块集、门房使用已验收 `JOHTO_GATE` 成熟室内图块。正式版本字符串写入 `data/game_version.asm`。
- 此项**已接入运行时源码但尚未 ROM 编译或手机实机验收**。脚本验证全部为静态证据。

## 本批真正开放的内容

- 满金市外部 `(19,1)` 的北门房 DOOR 进入，门房内北端两格 `(4,0)/(5,0)` 去35号路、南端 `(4,7)/(5,7)` 回满金市。35号路南部两格 `(9,33)/(10,33)` 回北门房；所有注册 Warp 的准确起点和返回列需吻合原版Gold。
- 登记独立的音乐来源，保留进入门房的道路或城镇歌曲及播放进度，特别保持 `Bike Song Off` 的 Carry 修复；两格地毯允许横向步行和骑车，不将合法 Warp 加入未开放门口黑名单。
- 35号路 Gold 角色图包含32个 WATER 单元及一棵 `(17,6)` Cut树。只有已经完成 Cut 后切换到 `$90` 的动态块才可穿过原 `$5B` 阻挡；Surf 必须遵循 Gold 水格角色判定，不能把水格当陆地。
- 新图块 `Route35.runtime.blk` 与 Gold 原版 `Route35.blk` 一致；共用门房成熟室内块与已经验收的桐树林北门房一致。门房 `$0d` 外框、35号路 `$05` 树墙边框、普通 Johto 图块集分别受审计。
- Gold 原地图还包括35号路北接36号路及国家公园门房。**本轮不开放这两处连接与尚未移植的训练师、建筑或剧情**；它们应作为下一轮单独核对屏幕边框、走路宽度和移动判定后的任务。不要自动恢复 Gold 的全部 Warp。

## 生成脚本和审计脚本的边界

- `tools/johto_rpp_pipeline.py` 的工作区审阅由最早6张扩到现有23张活动图，与稳定ID、实际Header和槽位逐项交叉比对；不再将合法的34号路、满金市、35号路误判为未登记。
- `tools/johto_route35_source_contract_283.py` 是**专为 `.282` 未激活源工作区准备的历史准入工具**，用于给出 Gold 原图一致性及离线候选；它明确要求 `.282` 源码为21张，故在已经激活地图的 `.283` 工程运行会主动拒绝。不能用它的退出码判断 `.283` 是否正常。
- 已激活 `.283` 应使用 `tools/johto_route35_runtime_audit_283.py`，该工具逐项核对实际 ROMX Header、Gold原图字节、4个门房 Warp／2个道路 Warp、禁用的北边界与园区入口、Cut前后碰撞、Surf角色、音乐来源及入口可步行性；定向负向注入会故意破坏图块、Warp方向、地毯位置、音乐与Cut坐标，要求返回失败。此入口已经接入城都综合迁移审计。

## 可重复的静态检查（不链接 ROM）

```sh
python tools/johto_route35_runtime_audit_283.py --project . --gold-root /path/to/pokegold-master
python tools/johto_pilot_migration_audit.py --project . --gold-root /path/to/pokegold-master
GOLD_SOURCE_ROOT=/path/to/pokegold-master JOHTO_GOLD_ROOT=/path/to/pokegold-master python -m unittest discover -s tools/tests
python tools/asm_symbol_preflight.py
```

以上不代替手机实机验收。用户本机必须重新编译 Red/Blue 和 TEST ROM，提供最新MAP确认ROM0安全余量至少64B；手机逐项测试满金市北入口、门房双方、35号路返回、两格地毯横移与骑车、音乐无重启、昼夜、Surf/Cut、存档读写及35号路北边框。没有这些证据不得声称已正式验收或制作清理三件套。
