## 当前最新状态：MAP-5.62.268 南线六图已登记运行时（待本机验收）

本目录最初的 `source_manifest.json` 和 `runtime_geometry_manifest.json` 是先前资源／几何准备阶段的**历史快照**，其 `SOURCE_ONLY_NOT_PLAYABLE` 等字段描述的是当时的阶段，不代表本次 `.268` 整批激活后的状态。当前实际运行登记以 `constants/region_map_constants.asm`（21张）、`data/johto_south_runtime.asm`、`engine/johto_south_portals.asm`、`engine/johto_south_geometry.asm`、Gold 独立审计及两份互斥完整开发补丁为准。

已经新增的六图：桧皮镇／桐树林南门房／桐树林／桐树林北门房／34号道路／满金市。内部15条传送记录已与 Gold 双向核对，另外33号路→桧皮镇、34号路→满金市的外景相邻关系分开登记。新增342格水域与桐树林Cut树、定向跳崖均已加入静态规则。未知建筑/地下层/剧情遭遇继续关闭。实机 ROM 尚未验收；不能仅凭静态测试宣称完全可玩。

图形源只追踪 PNG，生成的 `.2bpp` 必须由项目 Makefile 自动生成，不纳入补丁。用户此前修改过的 `jp` 指令保留。`TEST-231` 不变。

---

# 南线六图｜运行时几何候选（还未激活）

此包是 `.268` Gold 源资源阶段的下一步：按原版 Gold 检查了六图在对应 tileset 上的每个 16×16 四象限，并将可直接传入后续运行时 Header 的区块候选独立存放在 `maps/johto_pilot/candidates268/*.candidate.blk`。此外保留每格碰撞遮罩和全部 Warp 的 Gold 一基序号与来源目标表。

**严禁把 `.candidate.blk` / `.walk_mask_review.bin` 当成已经注册的游戏数据**：目前没有增加活动地图槽位，也没有添加图块集、接缝/传送、冲浪、砍树、跳崖或 Fly 代码；`FIX-5.62.267` 的正式版本与原有15张地图保持不变。项目禁止 AI 自行编译 ROM。

### 数据边界

- 3张 `JOHTO_MODERN` 地图（桧皮镇、34号路、满金市）使用既有 PNG/BST 的相同 Gold ID，不需再造 `.2bpp`。
- 两座 `GATE` 和 `IlexForest` 必须作为独立 Gold 图块集，等专属 ROM0 碰撞指针、palette 和 `Warp` 方向均落实后才能激活。
- 出现于 Gold 事件文件但指向未接入民宅/商店/其他道路的 Warp 仍然关闭；Gold 的 Warp 序号 **从1开始**，RPP 现有注册序号从0开始，不允许混用。
- 横向及纵向地图接缝 **不等于 Warp**，33→桧皮镇、34→满金市必须分别验证 Gold 室外连接表、可视接缝及屏幕缓冲区。现有工具没有自动证明这些边界可玩。
- `*.walk_mask_review.bin` 是每行紧缩位图，**不是**现有 `JohtoRoute33BlockedCells` 使用的每格1字节阻挡表。正式接入前必须再做对应转换与正反校验，否则会出现人物穿墙。
- 路线34和满金市水域、桐树林的 Cut 与 Surf、两张有 HOP 的地图等仍需分地图/方位的实际场地技能分发和误触发故障注入。

所有成果都只是离线候选；不要编译本包去测试六张新图，因为六图仍然没有活动登记。下一个实施步骤是先统一开发图块集/Gate 的加载合同以及数据尺寸，然后一次注册六图并集中测试。
