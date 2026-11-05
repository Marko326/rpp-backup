# REF-346｜烧焦塔两层运行资源候选（未开放）

**基线**：用户最新 `REF-344.zip` 干净 HEAD `02a65db8`；也支持已应用 REF-345 资源包的工作区。此批继续开发，不是清理三件套，游戏内版本仍 `REF-344`。

**本次新增**：把 REF-345 已核实的 Gold 资源进一步转换为两份可独立接入的 RPP `tilepal`（96 tile 全量，原始 Gold BROWN/RED/GRAY），生成两层运行 Header、尺寸、原版贴图/Blockset 引用、所有 Warp 对象及 B1F 原版怪力石头的 ASM 候选。候选文件路径：`data/johto_burned_tower/REF346_runtime_candidate.asm`（**还没有 include/编译进游戏**）。没有复制联合洞穴的 NITE 图块或改关都。

**核心落洞保护**：Gold 1F 14个 Warp 槽：2个 DOWN-only 出口、11个 PIT、1个 LADDER；B1F 6个槽：前5个只是坑洞的落点（不得登记为发起 Warp），最后1个才是 LADDER。11 个 PIT 映射到 B1F 5个原版 Gold落点，无一落在回程楼梯。外部圆朱市入口规划追加至原有5个 Warp 之后，不能覆盖旧 ordinal。`docs/REF346_BURNED_TOWER_ROUTE_PLAN.json` 冻结零基/一基换算及坐标；`REF346_routes_candidate.asm` 只含16条将来可登记路由。B1F 怪力石头采用 REF-344 原生机制所用 `SPRITE_BOULDER + BOULDER_MOVEMENT_BYTE_2`，Gold位置 `(17,4)`。

**仍未开放的原因**：1F `PIT` 踏入后必须接入真正即时坠落传送（连同表现动画）；B1F `UP_WALL`（26）与方向 HOP（29）需要接入当前地图特定的碰撞/跳崖表，并检查石头四向推行；两座图需要在正式 tileset 注册时使用 Gold `PALETTE_DAY`，不得继承联合洞穴的 `PALETTE_NITE`。未完成这些运行路径前，地图 ID177/178 必须保持无活动槽，入口必须封闭，不能对外声称可玩。

**静态验证**：`RPP_GOLD_ROOT=/path/to/pokegold python -m unittest discover -s tools/tests -p test_johto_burned_tower_runtime_346.py -v`；候选生成检查 `python tools/johto_burned_tower_runtime_346.py --gold-root /path/to/pokegold`。分别检查 Gold源字节、14+6 Warp、11坑→5落点、DAY 调色、误注册与错误图块等。未编译 ROM、未生成最新 MAP、未 Commit/Push。
