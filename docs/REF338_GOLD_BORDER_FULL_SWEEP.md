# REF-338 环境热修｜Gold 城都边框全量扫描（第一批可修复问题）

## 用户截图与结论边界

- 用户截图 `GBPocket-20261104-144747.png` 和 `GBPocket-20261104-144754.png` 来自吉花市西侧冲浪海域。岩壁位置基本一致，海水以外的左侧和南侧有时显示不应出现的密集树墙。
- 当前工程 `CherrygroveCity.runtime.blk` 和 Gold 源 `.blk` 180 字节完全相等，因而仅检查原版地图块或碰撞格会漏检：**对象表首字节 `wMapBackgroundTile` 会填充地图范围外的三块边框**。
- 独立 Gold `data/maps/attributes.asm` 明确：`CherrygroveCity` 的 Border 是 `$35`（海水）；项目误写为 `$05`（树林）。这足以解释“树木出现在不应是树木的海域”的静态数据来源；但两张静态截图不能证明每次切换发生的 CPU/VRAM 时序。

## 全量扫描结果

以 `data/johto_header_descriptors.asm` 的 **57张活动地图**为遍历依据，取各地图的真实 RuntimeHeader → RuntimeObjects → 背景块登记；再和独立 Gold 原版 `data/maps/attributes.asm` 对照，而不使用项目内 `.gold.blk` 作为自身基准。

1. **共26张使用共享 `JOHTO_PILOT` 原版户外块集**，6张错用树墙边框，按 Gold 修复：
   - 吉花市 CherrygroveCity `$05 -> $35`
   - 浅葱市 OlivineCity `$05 -> $35`
   - 40号道路 Route40 `$05 -> $35`
   - 41号道路 Route41 `$05 -> $35`
   - 湛蓝市 CianwoodCity `$05 -> $35`
   - 卡吉镇 MahoganyTown `$05 -> $71`（Gold 原版岩石块）
2. 其余31张使用其它室内、门房、洞穴、桐树林等 tileset：**不做机械数字替换**，保留各自的重映射边框。桐树林 `JOHTO_ILEX_FOREST $00` 是独立成熟运行时块集，不能直接照搬原版 `$05`。工具对所有这些例外仍输出供审阅的名单。
3. 地图加载器确实从 `RuntimeObjects` 读取 `wMapBackgroundTile`，先填充图外背景再复制地图和连接。`gfx/blocksets/johto.bst` 原版共享块集里 `$05` 是树、`$35` 为水、`$71` 为岩石；错误不仅是调色板。
4. 吉花市142个原版 WATER 碰撞格的5行×6列摄像机地图块窗口，共核查4260个块引用，其中746个为图外边框引用；均处于1300B WRAM 地图块缓冲区地址内。
5. 活动地图数、稳定 ID、134条 Warp、中心治疗、Fly、Gold `.blk`、Surf/Cut/HOP 运行表、门房和 ROM0 代码不变；仅改六个户外边框元数据，以及测试、文档。游戏版本仍为 `REF-338`，作为同版显示修复，不扩大原功能。

## 防回归与验收

`tools/johto_gold_outdoor_border_audit_339.py` 对全部57张地图逐一审计、报告异块集例外，并验证 Gold 和共用块集、屏幕边框加载逻辑。`tools/tests/test_johto_gold_outdoor_border_audit_339.py` 对六个旧值逐个注入故障，要求测试失败，另外防护桐树林重映射与地图边框填充调用。

修复是**源码静态热修**，不能凭此断言动态显示完全正常。下一阶段如果同一位置仍然在树墙／海水间跳变，需抓一段包含进入 Surf、移动、打开／关闭菜单或读档的连续视频，或提供出现差异时的 WRAM/VRAM 快照，进一步区分地图重建与 BG tile/attribute 传输。

**设备测试（尤其两张截图相同位置）**：吉花市左侧冲浪，向四个方向移动、出入水、菜单关闭、存档 Continue；再检查浅葱市、40/41道路、湛蓝市海岸，卡吉镇地图边缘及既有门房。不要求重新逐个治疗九家旧中心，但应在 RED/BLUE/TEST 的新 MAP 中确认 ROM0≥64B 和有关 ROMX 余量。

按正式项目规则，AI 不编译/链接 ROM，不 Commit/Push；单 ZIP 提供两份互斥补丁：REF-338当前工程→同版修复，以及 REF-337正式HEAD→同版修复累计全量。两份二选一。
