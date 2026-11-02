# DEV-313（REF-311）｜卡吉镇北门房 ID65 分段开放（运行候选）

- **本轮实际激活**：Gold `Route43MahoganyGate`，稳定 ID65，活动地图 38→39，原版 `NorthSouthGate.blk`（5×4）。卡吉镇原版北门 `(9,1)` ↔ 门房南侧地毯 `(4,7)/(5,7)` 双向通行，仍复用 Gold 门房底层 `Gate_Coll`，没有改旧十座门房运行数据。
- **本轮没有开放**：Route43 地图本体（ID67）、Route43Gate 收费门房（ID66）、愤怒之湖（ID68），也没有迁移火箭队事件和新地图 NPC。门房北侧出口维持关闭，卡吉镇剩余四处室内入口继续封闭，不允许提前进入未审核的后续区域。
- **配置**：Map Header、source/runtime 描述、稳定槽 38、城镇地图名称及浏览项、Gold 自行车 GATE 环境、双音乐风格入口继承、三条注册 Warp、北出口安全边界、无水 Surf manifest、旧门房及 Gold 行走回归同时登记。
- **版本**：正式项目显示 `REF-5.62.311`，ROM 内统一 `REF-311`，Red / Blue / BATTLE_TEST 同一标签。
- **审计**：综合 Gold 迁移审计与门房、Surf、地图名称、音乐骑车、符号等静态审计必须全通过；没有执行 AI ROM 编译/链接。**静态通过不代表 ROM 能成功链接或手机可往返。**
- **空间**：新 Bank $53 数据及 Bank $41/$4E 分派、ROM0 骑车白名单均有新增。没有 REF-311 Red/Blue/BATTLE MAP，旧 REF-309 ROM0 69B 仅供背景，绝不能视作新版本 >=64B 的容量证据。
- **下一段**：接入 Route43 与收费门房时先审核完整南北链接、Rocket 收费状态、Surf 和边缘预览，再开启 ID65 北出口。后续新增地图原则上复用既有碰撞机制，而非改掉经过手机验收的十座门房。


## DEV-314 / REF-312 维护更新

ID65 的地图资源与 Warp 没有改变。原先放在本地图文件里的五个门槛/落点/边界专用函数已移入 `data/johto_vertical_gate_runtime_314.asm`，改为按 stable map ID 查询配置表。Town ID64 与 Gate ID65 共用该实现；Route43 北出口仍未登记，ID66 仍未激活。
