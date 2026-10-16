# Route33 源资源与封路审计第一阶段｜R33S-5.62.189（开发候选）

**基础版本**：`DIG-5.62.188@`；用户最新干净 ZIP 导出 HEAD `b99710c1`；本阶段仅增加**不参与 ROM 的 Gold 源资源与只读安全门禁**，不修改游戏显示版本。`R33S-5.62.189` 是本次阶段补丁编号，**不是已开放的游戏版本**。

## 已核对 Gold 原版（本次可复现）

- `maps/Route33.blk`：10×9 个 32×32 区块、90 字节。原版 Route33 使用 `TILESET_JOHTO_MODERN`，而 Route32 使用 `TILESET_JOHTO`。128 个原版区块中两套图块仅 69 个逐字节相同；**绝不能拿现有 `JOHTO` 块集直接解码 Route33 地形**。
- `data/tilesets/johto_modern_metatiles.bin`：128×16=2048 字节。`gfx/tilesets/johto_modern.png`：独立 128×48 的原版图像。三份 Gold 内容分别拷贝到 `tools/johto_route33_staging/`，不被 `main.asm`、Makefile 或图块索引引用。
- `data/tilesets/johto_modern_collision.asm`：必须使用 Gold 的 16×16 四象限语义。Route33 的 8×8 图块 ID `$3C` 同时用于 `FLOOR`、`WALL`、`UP_WALL`；`$05` 同时有 `FLOOR` 与多种 `HOP_*`。**不能**把这些图块 ID 直接加入现有 RPP 的全局可行走表；按位置或独立碰撞克隆／定向跳崖适配后再考虑开放。
- Gold Route33 Header：`NORTH|WEST`；北接 Route32（偏移0），西接 AzaleaTown（偏移0）。Gold 事件：洞穴入口 `(11,9)`→Union Cave 1F warp3；路牌 `(11,11)`；另有训练家和树果对象。本阶段均不移植事件，也不把未接入的桧皮镇错误指向其它地图。
- 联合洞穴内部 Gold Route33 出口 `(17,31)` 仍只属于未来实际第二入口工作；**不是**本阶段已经开启的 Warp。

## 已落地内容与不变量

1. 完整 Gold 参考源码与 `.188` RPP 下原始严格门禁 `298/298 PASS`，当前候选新增 `9` 项后为 `307/307 PASS`、`0 fail/skip`。仅静态/只读，不编译 ROM。
2. `tools/johto_route33_staging_audit.py` 校验暂存源图块、块表、图像与 Gold 逐字节一致；检查 Gold Header、入口和 16×16 碰撞语义；检查提前开放 Route32 南口、第二洞穴 Warp、错误增配本地地图 ID 与篡改 `.188` 固定返回点等行为。
3. `tools/tests/test_johto_route33_staging189.py` 提供 9 项正向与反向用例，已列入严格门禁发现清单；严格门禁缺完整 Gold 仍失败关闭。
4. **当前没有接入任何 Route33 运行时地图 Header／本地 ID／图块集／地图连接**。Route32 南边界、联合洞穴 Route33 洞口、AzaleaTown 边缘原样封闭。Town Map 原有 45/45 浏览不变；不解锁 Fly、Surf、Dig 或逃洞绳在其它地图的权限。
5. 游戏源码／版本 `DIG-5.62.188` 不变，因此此补丁没有新的手机可进入地图测试目标。用户已验收的 `.188` 不要求重复测试。不存在由本阶段提供的新 ROM/MAP 或 Bank 链接安全结论。

## 下一阶段实际可玩开发的强制门槛

- 为 Gold 的 `JOHTO_MODERN` 建立独立渲染与调色、8×8 可通行碰撞和必要定向跳崖等价转换；逐象限核对 Route33 原版的壁、草、路、洞口、墙上通道，不得依靠共享图像 ID 粗暴放行。优先复用可重定位 ROMX 资源。ROM0 导出布局余量很紧，不能保证有空间。
- 规划新 local ID（在 `$FC` 共享句柄下）并同步全部地区表、音乐、Town Map 当前标记、能力登记、地图边界/连接 Header；对 Route32 南口与 Route33 北口双向列/行/偏移逐字节核算。只有两侧入口站位、反向安全及 Continue 准入后，才**定点**解封 Route32 南口。
- Route33 西边是尚未接入的 AzaleaTown，一直安全阻断；洞穴侧按原版 `CAVE` 入口及碰撞/方向合同做正反核验。**在第二个洞穴入口正式放行之前**，必须把 `.188` 的 Dig／Escape Rope 从固定 Route32 位置升级为来源地区 + 局部地图 + 入口 Warp 的安全动态记忆；检查保存 Continue/旧档、黑屏、关东既有逻辑。不得将两个工作目标未经测试混成一次开放。
- Route33 Gold 的训练家、树果、野生遭遇和剧情仍按独立内容阶段接入；图片一致不等于 NPC/技能/音乐/实际地图运行已实现。

**项目纪律**：未作 Git Commit/Push；本阶段不收口 `.188` 既有提交，不修改已验收功能。增量/全量为同一干净 `.188` ZIP 上的二选一补丁。
