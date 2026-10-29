# ROUTES-251｜30、31号道路 Surf／Cut 两图开发候选

## 基线与范围

- 用户上传的 `PAL-5.62.250` 导出记载干净 HEAD 为 `722b449ab8ab3a4cf62d905dee6265870e8935ad`，分支 `常规功能备份`。ZIP 不带 `.git`；本轮不猜测后续实际提交。
- 正式版本调整为 `PAL-5.62.251`，`TEST-231` 不变。不增加活动地图：仍是 9 张；既有地形、航路连接、音乐、SRAM、徽章门槛不变。
- 本轮只为 **Route30 稳定 ID3** 和 **Route31 稳定 ID4** 开启冲浪及精确砍树。Route32 的 278 个水格暂不登记；若叶镇东侧继续 `DEFERRED`；Route29 的2棵 Cut 树另作后续候选。未开放洞穴及新剧情。

## Gold 数据与游戏行为

| 地图 | 尺寸（Gold 碰撞格） | WATER | CUT_TREE（x,y） | 保留跳崖 |
|---|---|---:|---|---|
| Route30 | 20×54 | 32（两组，24+8） | (8,6) | 21 个 HOP_DOWN 继续走原 `ledges.asm` |
| Route31 | 40×18 | 44 | (13,5)、(25,10) | 既有 HOP_DOWN／HOP_RIGHT |

- 水格来自用户提供的 Gold `.blk` 和 `data/tilesets/johto_collision.asm`。`JohtoRoute30GoldWaterCells` 和 `JohtoRoute31GoldWaterCells` 分别精确登记 32、44 个 `(y,x)`，只在共享句柄 `$FC`、Johto 区域以及对应稳定 ID 中返回真。
- 保留既有三条入口（Surf 招式、Surfboard、水中续行与上岸）。Bank `$03` 在 `.250` MAP 仅余约 **6 B**，因此道具入口不增加调用，继续调用 `JohtoVioletWaterAhead`，由同一 ROMX Bank 中的 `JohtoRoute30WaterAhead`／`JohtoRoute31WaterAhead` 做 carry 保留的逐图派发；移动中的 `CollisionCheckOnWater` 仍精确区分地图，并在非水面目标前恢复 `wTileInFrontOfPlayer → C`，走原陆地碰撞扫描。
- Gold 两图的靠水 FLOOR 未发现吉花市式的 `MISSING_SHORE_PASSABILITY`；不扩大 `johto.tilecoll`，不把水/墙共享的美术 TILE 作为判据。
- Cut 通过 `JohtoPilotCutTreeAhead` 复用既有 Field Move 和动画。`JohtoRoutesGoldCutCells` 限定两图的3棵树，且运行时必须是原始 Block ID 才可以再次执行。追加三块独立的单象限替代：Route30 `$67→$8E`、Route31 `$5F→$8F`／`$5B→$90`；原有桔梗市 `$63→$8D` 不变，周围 HEADBUTT_TREE 不受影响。原始 `gfx/blocksets/johto.bst` 保留141块不改，额外三块在运行时 ROMX 图块表追加。
- 仍沿用当前暂时的关都徽章许可：Cut 需 Cascade Badge、Surf 需 Soul Badge；不在此轮更改到 Gold 原作的徽章流程。

## 已执行的**静态**验证（不等于 ROM／手机）

- `python tools/johto_surf_preflight.py --gold <用户 Gold 目录>`：PASS；76 个新水格与 Gold 完全一致，三入口和岸线 `C` 还原覆盖。
- `python tools/johto_surf_coverage_audit.py --gold <用户 Gold 目录> --require-map Route30 --require-map Route31`：两图 `REGISTERED`；Route32 `MISSING_SURF`；NewBarkTown `DEFERRED`。
- `GOLD_SOURCE_ROOT=<用户 Gold 目录> python -m unittest discover -s tools/tests -p 'test_*.py'`：145 项执行，通过 143 项、跳过 2 项（依运行条件），无失败；包含 Surf helper 缺派发、Cut 坐标、替换块修改的反例与 Gold 原始水域不可步行核对。
- `tools/asm_symbol_preflight.py`：2067 文件静态局部符号通过；`johto_pilot_migration_audit.py`：69/69；`johto_gatehouse_behavior_audit.py`：12/12；`johto_warp_arrival_audit.py`：17/17。
- **未由本环境进行 RGBDS 编译／链接、四种 ROM、最新红蓝 MAP、模拟器或手机实测**。精确 Bank 空间只据 `.250` 旧 MAP 推断，不作为 `.251` 已链接证明。

## 用户本机验收优先级

1. 正式 Red、Blue 以及 TEST Red、Blue 依本地项目流程编译，检查**新** MAP：ROM0、Bank `$03` 和新增块的 `$43` Bank，尤其 Bank `$03` 本轮恰好增加3组2字节的 Cut 映射，理论上会用完旧 MAP 的6字节可用量。
2. Route30：两片水域分别用 Surf 招式和 Surfboard，四向游泳、至少各一处合法上岸，岸上走动后再次入水；对 `(8,6)` Cut，从合法可达一侧砍下后能走，第二次不得再次砍树，邻接摇树保留。
3. Route31：多处岸线尝试下水、四向行进、上岸后行走；对 `(13,5)`、`(25,10)` 分别砍树，测试重复砍树与相邻摇树不受损；跳崖右跳/下跳照旧。
4. 回归：Route30↔Route31↔吉花市、Route31 门房↔桔梗市、Route32 原有往返；音乐同曲不重播；骑行、存档／Continue 后四向可动；吉花市西南平台、桔梗市上岸/Cut/跳崖、关都冲浪和砍树不能回归。若失败提供具体地图、方向、坐标、ROM 构建日志和现象。

本轮处于开发候选，按项目规范只交两个互斥补丁合一 ZIP；不制作 Git Commit 日志，不自行 Commit/Push。
