# MAP-5.62.253｜当前活动城都地图 Field Moves 收口

## 最终功能范围

- Git 基线：`PAL-5.62.250` / `HEAD 722b449ab8ab3a4cf62d905dee6265870e8935ad`。本轮将此前的 `.251`、`.252` 开发候选累计收口为 `MAP-5.62.253`；`TEST-231` 未变。
- 仅覆盖 9 张已启用地图。联合洞穴、33号道路、桧皮镇等 staged 资源仍未激活；不新增 Warp、稳定地图 ID、存档字段或剧情。
- Surf 继续复用原有三个入口（Surf 招式、Surfboard、水中移动／上岸），不改关都既有 Surf 和徽章门槛，不扩大全局水面图块白名单。

## Gold 原版覆盖清单

| 地图 | Gold WATER | CUT_TREE | HOP 碰撞格 | 最终状态 |
|---|---:|---:|---:|---|
| NewBarkTown（若叶镇） | 8 | 0 | 0 | Surf 已启用 |
| Route29（29号道路） | 0 | 2 | 35 | Cut／跳崖已启用 |
| CherrygroveCity（吉花市） | 142 | 0 | 0 | Surf 已启用，西南平台保留专属岸线例外 |
| Route30（30号道路） | 32 | 1 | 21 | Surf／Cut／跳崖已启用 |
| Route31（31号道路） | 44 | 2 | 13 | Surf／Cut／跳崖已启用 |
| GuideGentsHouse（向导家） | 0 | 0 | 0 | 不需要上述地形能力 |
| VioletCity（桔梗市） | 140 | 1 | 3 | Surf／Cut／跳崖已启用 |
| Route31VioletGate（31号路门房） | 0 | 0 | 0 | 骑车规则单点启用；不放开所有门房 |
| Route32（32号道路） | 278 | 1 | 6 | Surf／Cut／跳崖已启用；地点栏显示 `Route 32` |
| **合计** | **644** | **7** | **78** | **9 张活动地图的相关能力已登记** |

## 关键实现与限制

1. **New Bark Town Surf**：恢复运行地图 `.blk` 偏移 39 的原版水面块 `$54`（此前暂缓期间被替换为草地 `$01`），并只允许该地图精确的 8 个 Gold WATER 格使用 Surf。非水目标仍进入原有陆地通行检查。
2. **Cut**：只按 Gold 地图身份、坐标与原始块匹配。七棵树分别为 Route29 两棵 `(30,9)`、`(21,11)`；Route30 `(8,6)`；Route31 `(13,5)`、`(25,10)`；VioletCity `(36,19)`；Route32 `(10,19)`。仅清除目标象限，保留邻接 Headbutt 树与复砍保护。
3. **Ledges**：Route29、Route30、Route31、VioletCity 的既有跳崖行为保留；Route32 的 6 个 Gold HOP 碰撞格现在按稳定 ID 7 单独派发，复用经审核的 Route31 tile-pair 表，不全局开放跳崖。
4. **Bike gate**：只对当前活动的 Route31VioletGate（稳定 ID 6）作地区、运行句柄和稳定 ID 限定。Gold 的 `GATE` 环境可骑车，但 `Route35NationalParkGate` 与 `Route36NationalParkGate` 是 `INDOOR`；不得按建筑名字或图块集全局放行。
5. **Route32 地点栏**：地图名称解析为稳定 ID 7 增加 `Route 32` 分支，修复此前回退显示通用 `Johto` 的问题，不改地图 ID、Town Map landmark 或存档布局。
6. **容量与兼容**：城都 Field Skills 代码位于扩展 Bank `$48`，不增加 Bank `$03` 的远调用数量；关都规则、地图连接、Warp、存档结构和活动地图数量保持不变。

## 用户验收记录

2026-10-29，用户确认本轮本机测试全部通过，覆盖正式／测试红蓝构建、新 MAP 检查，以及新增和既有地图的 Surf、Cut、跳崖、门房骑车、Route32 地点栏、Continue 和关都回归。此处是用户反馈记录；助手未自行编译／链接 ROM，也未执行手机模拟。

后续只在新增活动地图时扩展本清单。未启用地图必须先完成独立资源、地图连接、Warp、碰撞和 Field Moves 审核，不能仅因资源存在就宣称可玩。
