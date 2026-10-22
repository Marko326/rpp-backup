# SPID-5.62.239｜东线后续五图 Gold 源码预审交接（非运行时开放）

## 状态与版本

- 游戏正式显示版本：**`SPID-5.62.239`**（不带 A/B 等测试候选字母）；已由用户确认上一版公园/遗迹门房工作正常。
- 当前已登记活动地图：**41 张**；本轮未添加地图头、活动槽位、运行时 Warp、Field Moves、飞空目的地，**没有开放新地点**。
- 本次完成的是五张地图的原版 Gold 源审查以及能防止错误数据混入的独立静态审计；不是 ROM 编译、链接、手机验收，也不是游戏功能提交。

## 核对后的开发顺序

| Gold 地图 | 冻结 local ID | 尺寸（区块） | Surf WATER 16×16格 | 安全跳崖候选 | Warp 数 | 当前阶段 |
|---|---:|---:|---:|---:|---:|---|
| Route44（44号道路） | 69 | 30×9 | 120 | 21 | 1 | 待接入 |
| IcePath1F（冰雪通路1F） | 70 | 20×18 | 0 | 0（另有4条需安全审阅的候选） | 4 | 待接入 |
| BlackthornCity（烟墨市） | 71 | 20×18 | 80 | 47 | 8 | 待接入 |
| Route45（45号道路） | 72 | 10×45 | 16 | 88 | 1 | 待接入 |
| Route46（46号道路） | 73 | 10×18 | 0 | 20 | 3 | 待接入 |

预审生成的五图 Gold `.blk` SHA-256、Warp（含具体格）、局部地图冻结编号与双向连接偏移，都记录在 `tools/johto_east_corridor_source_contract.json` 中，并由 `tools/johto_east_corridor_source_audit.py` 逐一对照 Gold 实际源码。此 JSON 不属于游戏运行时地图注册表。

Gold 原版有效双向边缘：卡吉镇 ⇄ 44号道路：EAST/WEST offset 0；44号道路 ⇄ 烟墨市：EAST/WEST offsets -9/+9；烟墨市 ⇄ 45号道路：SOUTH/NORTH offset 0；45号道路 ⇄ 46号道路：WEST/EAST offsets +36/-36。所有这八条*仅是原版地图关系*，RPP 本轮仍不得开放。

**最需要防止的传送回归**：Route44 的 `(56,7)` 不是普通道路边缘，而是通往 `ICE_PATH_1F` 目标 Warp 1 的洞口；IcePath1F 的 `(4,19)` 是其返回 Route44 Warp 1 的对口。Route44 未完整注册时不得只开放一边、不给返程路由，更不能让未命中的旧传送落到关都任意默认地图。IcePath1F 另有三个既有 Gold Warp，不能因审计了回程就宣称洞穴已经可玩。

## 本轮已经复核的资产

本轮随补丁保存在 `docs/gold_east_source_239/` 的五份 `.gold_source.blk`、五份 `.gold_collision_review_mask.bin` 和五份 `map_onboarding.md` 全都是**隔离的离线候选资源**，不会被游戏编译自动引用；源审计同时核验这些文件与 Gold、预审哈希及遮罩长度。

Gold 原版的四张户外地图 Route44、BlackthornCity、Route45、Route46 所**实际引用的全部原始 block ID**，与 RPP 现有扩容后 `gfx/blocksets/johto.bst` 同一 ID 的 16 字节区块定义均相符。**不能将两份完整 `.bst` 哈希不同解释为这四张图的画面错误**：RPP 对一些未被四图使用的 block 做过既有楼梯修复和扩容，另外还有额外 ID；也不能推导 IcePath1F 的冰雪专用图块集已入 ROM。脚部草丛、环境调色和地图边缘可见性仍需运行时代码与手机验收。

## 可回放的现成工具步骤

在 RPP 根目录，并把 `GOLD` 设置为解压后的完整 `pokegold-master` 路径：

```bash
PYTHONPATH=tools python tools/johto_rpp_pipeline.py --gold-root "$GOLD" --project . --output /tmp/route44_three --adjacent-chain MahoganyTown Route44 BlackthornCity --preview-limit 0
PYTHONPATH=tools python tools/johto_rpp_pipeline.py --gold-root "$GOLD" --project . --output /tmp/blackthorn_three --adjacent-chain BlackthornCity Route45 Route46 --preview-limit 0
PYTHONPATH=tools python tools/johto_rpp_pipeline.py --gold-root "$GOLD" --project . --output /tmp/icepath1f --gold-map IcePath1F --preview-limit 0
PYTHONPATH=tools python tools/johto_east_corridor_source_audit.py --project . --gold "$GOLD"
JOHTO_GOLD_SOURCE="$GOLD" PYTHONPATH=tools python -m unittest discover -s tools/tests -p 'test_johto_east_corridor_240.py' -v
```

源审计必须报告 `status=PASS`、`scope=OFFLINE_SOURCE_ONLY`、`gameplay_ready=false`；任何人都不能把这三个字段改写为运行时准入结论。整项目 `johto_map_release_audit.py` 长测试仍须单独执行；源审计不会代替。

## 建议下一次真正加入游戏的范围

1. **先单张 Route44 完整接入**：以 Gold 的30×9布局直接导入；为该图新增 Header/Bank/active slot 与 Town Map 普通地标，卡吉镇东侧 ↔ Route44 西侧按 offset 0 单独开放合法可走格；其它边缘保持明确封闭。对双方实际边缘可走格、3行邻图区块显示、WRAM拷贝范围、实际屏幕视野做动态负例。
2. **补齐 Route44 的游戏逻辑才宣称可游玩**：120 WATER 格 Surf 的上下岸、21 跳崖动作、16 TALL_GRASS 格脚部遮挡、Headbutt 默认延期、骑行和 Fly **使用许可**（不是目的地）、正常路牌及音乐恢复；IcePath 入口保持封闭直到有自己的图块/冰滑动/返回路由。运行时发版仍要核对顶层 ROM0/ROMX 分派和真实 Bank 空间。
3. **随后 BlackthornCity**：一次性处理 Gold 与 Route44 边缘偏移 -9/+9、南侧 Route45 未开放时必须封闭、城镇普通 Town Map 和到访 Fly 登记／安全坐标、80 WATER 与47跳崖、8个室内入口逐个明确延期或实现。不能只因为是 `TOWN` 就凭空给 Fly 目的地或继承已有城市的回程位置。
4. **最后 Route45→Route46、冰雪通路1F**：长地图/悬崖的摄像头边缘、88处跳崖、Route46 三个 Warp 与原32道路门房等历史接口，之后独立审核 IcePath1F 的 4 个不安全候选/滑冰、四个 Warp 与冰洞专用图块。

**保留待验**：运行中的存档 Continue、地图转场卡顿、昼夜及水面/草地颜色、NPC/剧情、ROM Bank/VRAM、路线全部实机按键都没有本轮新证据。项目禁止助手自行编译或链接 ROM。当前可复核的结论只限五图 Gold 源资产与连接拓扑。
