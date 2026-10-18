# P17｜桐树林从已提交 P16G 重新开发（不建立专用解析流水线）

基线：用户上传的 `GATE-5.62.202` / `057e9fbf` 源码快照（无 `.git` 历史）。原始 P17 候选版本 `ILEX-5.62.203`；手机故障修订版标记 `ILEX-5.62.204`，**不是 ROM 构建版本证明**。未修改 P16G 已验收的桧皮镇、南门房东侧行为、专属 Gold 门房图片/ RGB。

## 强制复用证明

从工程根运行现成通用命令，Gold 为用户上传的完整源码：

```sh
PYTHONDONTWRITEBYTECODE=1 python3 tools/johto_rpp_pipeline.py \
  --project . --gold-root /PATH/pokegold-master \
  --gold-map IlexForest --output /tmp/rpp-p17-ilex-stage
PYTHONDONTWRITEBYTECODE=1 python3 tools/johto_map_release_audit.py \
  --rpp . --gold /PATH/pokegold-master --expect-version ILEX-5.62.204
```

实测流水线退出 0：405 `.blk` 项、40 个 metatile 原始数据、39 种图形 block、59 种已用 8×8 图，Gold collision 原始 64 项，216B / 30×54 障碍图。地图、区块、PNG 完全一致；**仅对 7 个 Gold HOP 待审核位置强制封闭**，测试复跑同一通用流水线，逐字节证明该差异。工具原有报告 `OFFLINE_REVIEW_REQUIRED` 保留，不伪称通用转换器可以自动登记运行时。转换、Gold tileset、碰撞解析全部沿用原工具，没有新建森林解析器。

复用运行时：`home/overworld.asm` 的 `CheckWarpsNoCollisionLoop` / `CheckWarpsCollision`，`engine/overworld/player_state.asm` 的 `.route31LeftGate` 参考方向边界；复用 `engine/overworld/johto_route33_collision.asm` 的 `JohtoModernMaskedStep`，仅修正该共用函数对新地图 54 格高度的读取，不复制位图寻路算法。`engine/overworld/johto_ilex_forest_collision.asm` **只是地图专用碰撞例外与 mask 数据接线**，没有实现任何 Gold 新解析器或新 Warp 引擎。

## 两格出口合同

| 来源 | 目标 | 触发 | 状态 |
|---|---|---|---|
| 桧皮镇 `(2,10)/(2,11)` | 南门房 `(9,4)/(9,5)` | 保持 P16G 原有触发 | 不改 |
| 南门房 `(9,4)/(9,5)` | 桧皮镇 | 向右撞门 | 不改 |
| 南门房 `(0,4)/(0,5)` | 森林 `(3,42)/(3,43)` | 向左撞门 | 新增，手机待测 |
| 森林 `(3,42)/(3,43)` | 南门房西口 | 向右撞门 | 新增，手机待测 |
| 森林 `(1,5)` | Route34 北门房 | **关闭** | 未实现 |

两个西侧 Warp 都保留踩格不立即传送、上下切换、侧向非对应方向不传送。`IsJohtoSouthGatePortal` 是单一 `(region,local)` 精确标识判断，并非所有 `REGION_NATIVE_MAP_SLOT` 都允许传送。Forest `TILESET_FOREST` 资源使用 Gold 原图和独立 tileset32，禁止无证据复用 Kanto FOREST。Forest 使用原版 `CAVE` 类型和兼容洞穴音乐；Palette 运行时颜色是否足够接近 Gold，仍待截图验收。

## 原版对象与保守封锁表

全部事件证据来自原版 `maps/IlexForest.asm`，不是虚构的 NPC 或脚本。Gold **3 Warp、5 BG、14 object、0 coord**；本阶段仅激活南口双格，禁用事件行为。

- 北口 Warp `(1,5)`：Route34 未接，封闭。
- BG `(3,17)` 牌子；`(27,1)` 隐藏 Ether、`(17,7)` 隐藏 Super Potion、`(9,17)` 隐藏 Full Heal；`(8,22)` 祠堂：均未放行。
- 大葱鸭十位置：`(14,31)`、`(15,25)`、`(20,24)`、`(29,22)`、`(28,31)`、`(24,35)`、`(22,31)`、`(15,29)`、`(10,35)`、`(6,28)`：脚本阶段性对象均未加入 RPP。
- 其他 NPC：学徒 `(7,28)`、炭工 `(5,28)`、Headbutt 人员 `(15,14)`；地上 Revive `(20,32)`：未加入。
- Cut 树、Water、Headbutt、跳崖均不得因图片出现而自动获得 RPP Field Moves 许可；7 处可疑 HOP (`22,2` / `24,2` / `25,2` / `15,14` / `15,15` / `23,22` / `24,22`) 保守阻挡，不提供跳崖动画。

## ROM Bank 与验证边界

上一个 `.202` MAP 的 ROM0 余量约 198 B，但项目具有大量浮动 Section；不要将这份旧 MAP 当作本次链接结果。当前源码声明 Forest 图块/地图 Bank `$44`，Forest mask Bank `$43`（与 `JohtoModernMaskedStep` 相同 Bank，保留 `jp` 直接跳转语义）。**未编译、未链接，Bank 空间、跨 Bank 访问和宏展开依然由用户的 Termux 构建确认。**

新增测试 `tools/tests/test_johto_ilex_forest_p17.py` 真正再次运行 `johto_rpp_pipeline.py`、比较原版二进制/PNG/Mask，并注入门口方向、Warp 编号、双向表、北口、旧18格边界、原版图块、跳崖和踩格自动传送故障。原已验收的 31号道路门房及南门房东侧原有测试全部继续执行。完整 Gold 统一静态门禁：**432 PASS / 0 FAIL / 0 SKIP**（静态，不代表实机）。

## 用户最小 Termux + 手机测试（代码候选已涉及运行行为）

- 在最新工程上**二选一**应用本轮增量或全量补丁；先用 Termux 编译/链接。如提示 Section 太大，请提供**此轮新产生的 MAP 和构建日志**；不要根据旧 MAP 乱搬 Bank。
- 在已验收南门房内试 x0/y4 和 x0/y5，各向左撞门，确认 Forest x3/y42 与 x3/y43 的对应；两格上下移动且踩上不自动传送、立即右撞回门房，无需后退。
- 在森林南口反向多次、侧擦不误传；第一次画面、颜色/VRAM、音乐、碰撞、存读档、Town Map。尝试不能无意进入北侧 Route34，不能走穿未实现的 Cut、Water、跳崖路线。
- 验收东口双格桧皮镇往返、Route31－桔梗市第一座门房左出口、旧 Kanto 门房；若运行不符合，保留 ROM 构建日志和屏幕截图定位。

**状态：通过静态门禁的开发候选，手机待验；禁止提前声明游戏实机已通过。**

## P17 手机首报后静态修正：Tileset32 装载偏移

用户实机反馈左门进入后花屏且无法回程，因此 **原先 432 PASS 的静态候选未通过手机验收**。源码复核确认原 RPP 两处 8 位偏移溢出：`engine/overworld/tileset_header.asm` 的 12B/项索引将 ID32 的 `$180` 计算为 `$080`；`color/loadpalettes.asm` 的 8B/项调色索引将 ID32 的 `$100` 计算为 `$000`。修正为保留高字节的计算，使用原有图块资源和通用流水线，未修改任何 Gold 解析算法。两项新增错误注入必须在统一 Gold 静态门禁中拦截。回程仍待手机实测确认。

### P17 回程前置门禁遗漏（实机回不去的独立原因）

原森林 (3,42)/(3,43) 两格虽然已注册到 native Warp 表、仅朝 RIGHT 才会命中 `CheckWarpsCollision`，但碰撞后实际先执行 `ExtraWarpCheck → IsPlayerFacingEdgeOfMap.facingRight`。该函数原先仅允许地图最右边缘，森林 `x=3` 在内部，故从来无法执行回程碰撞 Warp。经查旧 MAP 固定 Bank $03 只有 1 B 余量，因此不能直接增长 `player_state.asm`；现依照已验收门房的精确方向合同，在 ROM0 已有 `home/overworld.asm:ExtraWarpCheck` 入口对 `(region, local, x=3, y=42/43, RIGHT)` 增设准入，其他情况仍走原 `IsPlayerFacingEdgeOfMap` 路径，并给统一门禁加入故障注入。**实机必须重新验证回程，静态通过不等于手机通过。**
