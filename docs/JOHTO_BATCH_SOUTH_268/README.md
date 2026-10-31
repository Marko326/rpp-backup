## 当前最新状态：MAP-5.62.268 南线六图已登记运行时（待本机验收）

本目录最初的 `source_manifest.json` 和 `runtime_geometry_manifest.json` 是先前资源／几何准备阶段的**历史快照**，其 `SOURCE_ONLY_NOT_PLAYABLE` 等字段描述的是当时的阶段，不代表本次 `.268` 整批激活后的状态。当前实际运行登记以 `constants/region_map_constants.asm`（21张）、`data/johto_south_runtime.asm`、`engine/johto_south_portals.asm`、`engine/johto_south_geometry.asm`、Gold 独立审计及两份互斥完整开发补丁为准。

已经新增的六图：桧皮镇／桐树林南门房／桐树林／桐树林北门房／34号道路／满金市。内部15条传送记录已与 Gold 双向核对，另外33号路→桧皮镇、34号路→满金市的外景相邻关系分开登记。新增342格水域与桐树林Cut树、定向跳崖均已加入静态规则。未知建筑/地下层/剧情遭遇继续关闭。实机 ROM 尚未验收；不能仅凭静态测试宣称完全可玩。

图形源只追踪 PNG，生成的 `.2bpp` 必须由项目 Makefile 自动生成，不纳入补丁。用户此前修改过的 `jp` 指令保留。`TEST-231` 不变。

---

# MAP-268 南线批量移植：六图 Gold 源资源准备（未激活）

> 此阶段只将 Gold 原版源布局/独立美术放入工程；**未接线，不可游玩。** 不能将资源核对通过写成六图已完成移植。

本轮核实来源：用户最新干净 HEAD `b4148ccb783bdf734d621d0b8e8419f24ffe72da`，`FIX-5.62.267`，分支“常规功能备份”。成熟参考 `NPC-5.62.243`、Gold `pokegold-master`。

路线实际名称：`Route33 -> AzaleaTown -> IlexForestAzaleaGate -> IlexForest -> Route34IlexForestGate -> Route34 -> GoldenrodCity`。两种 Gate 方向不同；`Route34IlexForestGate` 是 Gold 正确名称。

六图 Gold 布局暂存于 `maps/johto_pilot/<Map>.gold.blk`，**不创建 `<Map>.runtime.blk`**，以防误当成活动运行地图。新森林 PNG 是单独的 Gold 源图，绝不替换 RPP 原有 `forest.png`；Gold Gate PNG 和区块集均独立暂存，不要误用 RPP 的 Gate 图块。Johto modern PNG 和 BST 与 Gold 字节一致，可复用 `.267` 已修好的 ID32 运行资源。

脚本只通过现有 `tools/johto_rpp_pipeline.py --gold-map ...` 核验源资产和 16×16 原版碰撞的候选输出，未执行 ROM 连接。详细体检字段在 `source_manifest.json`。

后续真正运行时接入仍须：6个稳定 ID 10..15 对应 slots、扩展 Town Map/GSC Music/标签/profile/飞行；桐树林的独立 FOREST 图块与行走碰撞、南北横竖门房的 WARP_CARPET；Route33/Azalea、Route34/Goldenrod 边缘和深色树边预览；森林32格、34号路226格、满金市84格水域逐岸 Surf；Gold HOP 和 Cut 树、骑车；Bank0 预算；全部逆向错误注入、ROM 编译与实机验收。不得一口气开放其他室内 Warp、剧情或野怪。

地图 `IlexForest` Gold 环境为 CAVE，因此骑车、Dig/逃脱绳、Fly 的权限与普通户外不同，必须单独校核，不可用“Forest”视觉推断环境。
