# Route34／桐树林北口门房：P18 离线资源准入（尚未开放）

**工作区基线**：用户最新 `test(tool)__固化桐树林转换审计与_Cut_防回归规范.zip`，
`HEAD 287522e503a009d40d353f8fff5086238a900f95`，游戏版本 `ILEX-5.62.212`。
本次只优化**原有** `johto_indoor_pipeline.py` 和 `johto_indoor_collision_adapter.py`，
修正已经提交的桐树林静态审计旧合同；**不修改 ASM、游戏版本、PNG、地图、有效 Warp**。
Gold 参照 `pokegold-master(1)(1).zip`，与此前提供的 `pokegold-master(1).zip`
SHA-256 一致：`06c3724bb859b6c7946a528ab0b19ef03ae688959b3761e65cac8f633ed87d0c`。

## 现成工具如何复用

```sh
PYTHONDONTWRITEBYTECODE=1 python3 tools/johto_indoor_pipeline.py \
  --rpp . --gold /PATH/pokegold-master --output /tmp/rpp-route34-north-prestage \
  --gold-room Route34IlexForestGate \
  --rpp-room JohtoRoute34IlexForestGate \
  --gold-tileset gate --rpp-tileset johto_gate \
  --prestage-unregistered
```

`--prestage-unregistered` **仅适用于未注册房间**，沿用现有图块匹配、Gold Warp 读取、
碰撞、资源预算与 palette/VRAM 检查，输出在游戏源码**外部**；已注册房间被该模式拒绝，
必须走原有完整 Warp 流水线。未注册目标绝不通过猜测写入运行时对象表。
通过 `data/tileset_headers.asm → data/collision.asm` 查找真实碰撞源；`JOHTO_GATE`
引用 `Gate_Coll`，实际列表为 `gfx/tilesets/gate.tilecoll`，并不是同名 `johto_gate.tilecoll`。

## Gold 原版北口特殊形状，严禁照搬南门房

| Gold 来源坐标 (x,y) | 原版目标 | 以后接入时的注意点 |
| --- | --- | --- |
| Forest `(1,5)` | Gate `#3` | **室外单口**，向 UP 撞门；不能按南口 RIGHT 特判 |
| Gate `(4,7)` 和 `(5,7)` | Forest `#1`（两口汇聚） | 两边必须都能立即返回同一个落点 |
| Gate `(4,0)` 和 `(5,0)` | Route34 `#1/#2` | 朝 UP 出门；外部连接未注册，**目前不得启用** |
| Route34 `(13,37)` 和 `(14,37)` | Gate `#1/#2` | 朝 DOWN 撞门，须先接完整 Route34 才可打开 |

以上是 **Gold 1-based** 目标编号；RPP 数据表顺序为 `Y,X,0-based`，转换时必须重新核对。
Gold `NorthSouthGate.blk` 为 5×4 blocks、9 种已用 32×32 图块；使用现成
`JOHTO_GATE` 作基线时，逐像素匹配到 4 种，另外 5 种需要通过现有图块映射工具
补齐并核对 palette 与真实 RGB；不允许按 Gold 源 tile ID 排序直接覆盖旧 compact ID。
离线工具生成的独立 Gold 资源**不是**可直接导入的游戏资源，不能拿独立候选的
`gate.bst` 替换现有 `johto_gate.bst`。

## 仍未获准开放的条件

- 路线注册：Forest 北口与 Route34 原版地图、北门房四口需一起完成 RPP local ID、header、object、地图读取和音乐对应；当前不能单独打开北门房造成空出口。
- 碰撞：`CheckWarpsNoCollisionLoop` 保留门垫站立无自动传送；`CheckWarpsCollision`、`ExtraWarpCheck` 严格按地区+local ID+位置+方向过滤；立即反向复入不需要先退一步。
- 准入：新增地图必须登记 `johto_door_contracts.json` 及八类 `gatehouse_proof_ids`，全部实际执行；室内 `phone_door_status`/`phone_visual_status` 只能先标 `PHONE_PENDING`。
- 视觉：Gold→compact 图块四象限逐格像素对应，`tilepal` 标签和实际 RGB 分别审计；检查首次载入与相邻连接快速切图两条边界路径，门房不弹 Route34 地点牌，关东原门房颜色不变。
- 实机：林北单口进／室内南侧双格立即出、室内北侧双格进／Route34 南侧双格立即返、门口侧移不自传、从南门房来回、两座历史门房与关东门房回归、存读档。

## 静态审计与真实阻断

现有 Gold 审计曾把旧 `.205～.208` 跳崖**启用**当成通过条件，
并漏掉 `.210+` 唯一 Cut 树的额外克隆区块。本次仅修这些过时的**测试/审计预期**：
`ILEX-LEDGE-001` 仍保持禁用，Cut 的克隆只准改变目标左下四块 8×8 图形，
HEADBUTT 象限不得受影响，故障注入仍须 FAIL。

源码专项通过不代表 ROM／实机通过；**禁止编译/链接本项目**的协作规则保持。
完整 Gold 原始资料仍有 `SafariZoneBeta` 超出图形运行窗口的旧全量门禁报错；
这和本轮北门房/Forest 审计不一致修正是不同事项，未删规则、未静默跳过。

**状态**：`OFFLINE_STAGED / RUNTIME_UNCHANGED / ROUTE34_NOT_CONNECTED / PHONE_PENDING`。
下一实现阶段先以本文固定的四组 Warp 与候选图块记录做完整 Route34/北门房接入；
不是在当前工程中提前开放不完整的入口。
