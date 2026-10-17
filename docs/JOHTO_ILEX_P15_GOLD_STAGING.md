# 桐树林 / Ilex Forest · P15 原版前置核对（离线候选，未接入游戏）

- **真实基线**：用户于 2026-10-17 上传的「金银」项目干净 HEAD `2f08f49a4f26249748a354d786929d830b1b9d54`，游戏 `FLY-5.62.196`；完整 Gold 原版 `pokegold-master`。
- **本轮范围**：修复通用 Gold 转换器对碰撞表长度的错误断言，验证原版森林与南门房素材、几何、Warp 原始拓扑，并锁定下一阶段准入条件。不修改 ASM 运行入口、ROM 素材、地图登记或开放边界，不编译/链接、不提交 Git、不作手机验收。

## Gold 真实地图及素材

| 地图 | 来源 | 尺寸 / 状态 |
|---|---|---|
| `IlexForestAzaleaGate` | `maps/EastWestGate.blk` | Gold 门房 5×4；与现有 `JohtoRoute31VioletGate.blk` 逐像素等价，13/13 个使用区块可复用 `JOHTO_GATE`，**但尚未注册新门房** |
| `IlexForest` | `maps/IlexForest.blk` | 15×27，405 字节；Gold `TILESET_FOREST`，CAVE 环境，原版用 `MUSIC_UNION_CAVE`，晚间调色 |

- Gold 森林 `forest_metatiles.bin` 为 **40 个图形区块（640 字节）**，`forest_collision.asm` 有 **64 条**合法碰撞定义；旧工具强制相等导致误报。通用检查改为：图形区块必须全部被碰撞表覆盖，超出的原版表项允许存在；图块 ID 越界、碰撞定义少于图形区块、无图像等仍失败。
- 当前 Forest 布局涉及 **39 种不同区块、59 种 8×8 图像**，在 Gold 96 个候选载入槽内。RPP 原有 `forest` 图块集对这39个 Gold 区块 **0/39 像素精确匹配**，`johto_modern` 为18/39、`johto` 为26/39，均不能不经审核直接替代原版森林；需要独立保留 Gold 资源、审核调色/ROM/VRAM/碰撞并登记专用的城都森林图块集。
- Gold 逐格候选为 **30×54 个16×16格**，当前保守行掩码 216 字节，1262 阻挡、358 候选通行。原版角色包括 `CUT_TREE` 1、`WARP_CARPET_RIGHT` 2、`WATER` 32、`HEADBUTT_TREE` 152 个格。**这些特殊格按未实现处理，不因 Gold 地格标签而宽放 RPP 通行或 Field Moves。**
- 方向跳崖：通用转换器筛出 **2 处保守安全候选、6 处需人工复核**；后续先复核 Gold 原动作和 RPP 旧原生跳崖触发规则，不自动把这六处当作开放/否定的最终决定。
- Gold 事件盘点：森林 3 个 Warp、5 个背景事件（含隐藏物品）、14 个对象（其中大葱鸭多段事件）、0 个 Coord 事件；门房 4 个 Warp 和 2 个 NPC。事件/脚本均未移植，特别不能误开放 Cut 树、赶鸭剧情、桐树林祠堂或北侧 Route34。

## 正确拓扑（Gold 源坐标按 X,Y，编号从 1 开始）

| 起点地图与 Warp | 目标地图及原版编号 |
|---|---|
| 桧皮镇 `(2,10)` #7 / `(2,11)` #8 | 南门房 #3 / #4 |
| 南门房 `(9,4)` #3 / `(9,5)` #4 | 桧皮镇 #7 / #8 |
| 南门房 `(0,4)` #1 / `(0,5)` #2 | 桐树林 #2 / #3 |
| 桐树林 `(3,42)` #2 / `(3,43)` #3 | 南门房 #1 / #2 |
| 桐树林 `(1,5)` #1 | Route34 北门房 #3，**目的地尚未开发：必须保留阻断** |

Gold 编号不是 RPP 0-based Warp 表的编号；必须在新的双向事件表中重新编号、按地区/局部 ID 转义 `$FE`，并独立验证入口触发方向、落点、返回后不多走一格、骑行下车及存读档。**不能因为现有 `JohtoRoute31VioletGate` 的 Gold 资源匹配就共享它的地图 ID 或 NPC 表。**

## 后续 P16 可玩首批地图的强制准入

1. 在不改已提交 P13 的前提下，为门房与森林分别登记新的 native 本地 ID、Header/Bank、tileset、音乐、Town Map；森林不注册为 Fly 目的地。新门房复用经审计的 `JOHTO_GATE` 素材；森林专用原版 art/collision 必须完成资源、palette/VRAM 及 MAP 空间检查（当前 ZIP 自带 `patches/rppred.map` 仅适用于 `.196` 基线，不能证明未来新增资源仍能链接）。
2. 定点开放桧皮镇 #7/#8 ↔ 南门房 ↔ 森林南口的四对准确 Warp，并同时审计 RPP 边界、朝向、Warp 阻挡、回程与 Gold 原版落点。未经注册的森林北侧 Route34 门房不得开放，更不能借用 `$FC` 当唯一 ID。
3. 用 30×54 的角色级 Gold 碰撞隔离 `CUT_TREE`、水面、`HEADBUTT_TREE` 与普通地板，按已审核的旧 RPP 原生跳崖机制处理，危险候选继续关闭；不因门房/森林复用图块而全局允许 Surf、Fly、Dig、Escape Rope、Cut 或 Bike。
4. 检查森林 CAVE 环境、Union Cave 音乐、晚间调色、门房下车、保存/Continue、退出后音乐恢复、回到桧皮镇 Fly 仍有效；新 native id 必须有相应能力登记，静态门禁必须覆盖正向 + 故意破坏的反向测试。
5. 第一批可玩地图可延期非关键 NPC、隐藏物品、祠堂剧情及赶鸭事件，但必须逐项登记并确保延期对象不会意外触发。**森林具有砍树与剧情进路条件，不能为赶着打通 Route34 直接删除 Gold 原版障碍。**

## 可复现离线候选命令

在 RPP 源码根目录，完整 Gold 源码另放在安全目录；产物必须在 RPP 之外：

```sh
PYTHONDONTWRITEBYTECODE=1 python3 tools/johto_rpp_pipeline.py \
  --project . --gold-root /path/to/pokegold-master \
  --gold-map IlexForest --output /tmp/rpp-ilex-p15-stage

PYTHONDONTWRITEBYTECODE=1 python3 tools/johto_map_release_audit.py \
  --rpp . --gold /path/to/pokegold-master --expect-version FLY-5.62.196
```

结果中的 `OFFLINE_REVIEW_REQUIRED` 是**正常的危险区域提醒**，不代表生成失败或获准游戏注册。额外的 Gold 对照/反向测试位于 `test_johto_gold_collision_cardinality.py` 与 `test_johto_ilex_gold_reference.py`，被正式门禁强制发现。没有 ROM、手机测试，也不需要用户在这一纯离线阶段重测已经验收的 Fly。
