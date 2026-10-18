> **后续状态：`.208` 同样被用户实机否决；`.209` 选择暂时封闭森林跳崖、转回 CUT。参见 [`ISSUE_ILEX_FOREST_LEDGE_DEFERRED_209.md`](ISSUE_ILEX_FOREST_LEDGE_DEFERRED_209.md)。**

> **历史文件：.207 已被实机录像判 FAIL。当前候选方案为 [`LEDGE_RUNTIME_CONTRACT_208.md`](LEDGE_RUNTIME_CONTRACT_208.md)，请勿沿用本文件中的 .207 成功预期。**

# LEDGE-5.62.207｜全工程跳崖复盘与防复发检查合同

**状态：源码修复候选／静态审计，通过不代表 ROM、模拟器或手机实测成功。**

## 1. 根因假设与保留边界

- 历史 `MAP-5.62.134` 的成熟实现是 `HandleLedges` 图块配对，由前向图块身份+角色朝向判断；不要因某张地图需要两格落地而另建坐标解释器。
- Ilex Gold HOP 起跳格 8 个、允许正交方向 10 条。障碍为相邻格，下一格即有效 FLOOR，故移动总量 **2 格**，而传统 RPP 跳崖为 **3 格**。森林 10 条中有 7 条的第三格恰是摇树区，不得盲目复用三格距离。
- `.206` 已将触发改回 `.134` 风格图块配对，并保持 `初次移动+1次强制移动` 和 B 键禁加速，但未专门等待原生 60FPS 跳跃动画完毕就可能进入 `JoypadOverworld` 的模拟输入收尾，故存在“模拟输入停止与动画结束不同帧”风险。视频证明 `.206` 运行异常，但**没有 RAM/CPU 轨迹证明这就是唯一故障原因**。
- `.207` 在 `home/overworld.asm:OverworldLoopLessDelay` 同时检查跳跃位、Forest tileset+region+local map 与 `wSimulatedJoypadStatesIndex==0`；强制移动完成后暂停普通按键派发而推进精灵动画；待原动画关闭 `wd736.6` 后才清空 Forest 模拟输入队列尾部，避免模拟状态遗留。现成 `_HandleMidJump`、旧地图动画、正常前进/加速均不改变。

## 2. 按实现类型清点（扫描实际 `.206` 工作区经本次修改后的资源）

| 实现族 | 数据范围 | 当前静态枚举 | 本轮行为修改 | 后续风险 |
| --- | --- | --- | --- | --- |
| RPP 原生 Kanto OVERWORLD | `engine/overworld/ledges.asm:LedgeTiles` / `gfx/blocksets/overworld.bst` | 检索 120 张对应贴图资产，2,084 条**未经运行时确认的图块配对候选** | 无 | 切记不是 2,084 条已证明的真实可跳位置；缺专门 ROM/玩家回归 |
| Johto Route29 | `JohtoRoute29LedgeTiles` | 39 条 tile-pair/方向匹配 | 无 | 三格老规则抽查 |
| Route30 | 同上 | 21 | 无 | 南下落点／地图边缘 |
| Route31 | `JohtoRoute31LedgeTiles` | 14 | 无 | 与 Route30 连接边缘 |
| Route32 | 同上 | 8 | 无 | 联合洞穴与连接边缘 |
| VioletCity | `JohtoRoute29LedgeTiles` | 3 | 无 | 原三个朝下 HOP |
| IlexForest | `JohtoIlexForestLedgeTiles` | 10（8 处起跳格） | **新增专用输入/动画收尾门禁** | 必须先 ROM/手机验证 |
| Route33 | `.route33Hops` 坐标表 | 7 | 无 | 使用两次附加模拟输入，需与 Gold 两格落点实测核对 |
| AzaleaTown | `.azaleaHops` 坐标表 | 9 | 无 | 同上；不能未经用户测试直接改变 |

Johto 原生合计 **95** 条图块+方向配对，另有 **16** 条坐标式 HOP 规则。原生统计来自当前 `.blk`/`.bst` 展开为 8×8 图块后的枚举，不是玩家通过次数。Kanto 的 OVERWORLD 检索可能包含室内复用地形和 1 张块集异常文件，**只能用作候选风险面清单**。

## 3. 此次精确修改及 Bank 安全策略

- `home/overworld.asm`：唯一修改的运行时汇编；Forest 跳崖完成强制移动后，禁止过早落入 `JoypadOverworld`；真实动画结束时清空模拟队列 index / End[0] / End[1] / scratch。
- `engine/overworld/player_animations.asm`：**逐字节不改**。导出 `.206` MAP 中 ROMX Bank28 余量为 0，不得向动画 Bank 添汇编导致潜在溢出。
- 导出 `.206` MAP 的 ROM0 余量 `$0069`，静态估算 HOME 增量约 76 字节；这只是静态证据而非重新生成 `.207` MAP。
- `tools/ledge_regression_audit.py`：独立只读全图资产清单和 Gold 目标落点合同；新增地图路由、新的原生图块表或坐标 HOP 表若未登记，审计必须失败，迫使同步设计测试；`tools/tests/test_ledge_regression_207.py`：定位修复是否还在、原动画文件字节锁定、B 键状态与错误注入。

## 4. 审核命令和解读

```sh
python3 tools/ledge_regression_audit.py
python3 -m unittest tools.tests.test_ledge_regression_207 -v
```

以上命令不需要 Gold 源码；要补齐双源码严格门禁仍需用户完整 Gold 源树。本轮不运行 ROM 编译／链接。项目完整 Gold 源缺失时，旧 `tools/tests/test_johto_ilex_forest_p17.py` 等测试在 setUpClass 中失败，**不得记作通过，也不应把这些测试在预发布脚本中 silent skip**。

## 5. ROM／手机最小验收矩阵（所有未验）

1. 在 `.207` 真正编译的 ROM 上分别验证 Forest A 北栏向下的三处、B 左侧栏向左两处、C 南侧复合栏向下/向左/向右五条（总10条）；每条都测松开方向、持续按住方向、按住 B。检查起跳标识格只触发一次、完整拋物线影子、精确落在第二格，第三格树不能被误穿越。
2. 连续跳两次、落地瞬间切方向、立刻反向撞墙；检验 `wd736.6`、`wd730.7` 复位后普通碰撞恢复，不产生一步“幽灵移动”。能读取模拟器调试内存时额外记录 `wWalkCounter`、`wSimulatedJoypadStatesIndex`、`wPlayerJumpingYScreenCoordsIndex`。
3. Route29、Route31 原生三格跳崖（各 1 处，含 B）、Route33 坐标式 7 规则和桧皮镇 9 规则至少选左右/下向各一处，对比实际落地距离与 Gold 原版；第三格虽当前几何掩码允许通过，**不等于该落点正确**。
4. 复测 Forest 南口双格往返、Route32/33 连接边缘、保持未开放 Forest 北口封闭；保存/继续游戏一次，确认跳跃状态没有污染存档或后续地图。
5. 只有以上记录完备且新 `.207` 构建的 ROM/link/MAP 通过，才可进行正式“问题已修完”签收；若失败按最早异常帧回传 `.207` 视频和模拟器 RAM 快照，禁止仅靠更改模拟次数继续试错。
