# TOOL-5.62.292｜历史残留回归与四方向窄／短地图连接准入

本批只增强 `tools/johto_active_seam_coverage_gate_291.py`、测试和复盘文档，不改游戏 ASM、地图块、Gold 原图、Warp、ROM 版本 `FIX-5.62.290` 或 `TEST-231`。

## 旧分支可核验来源

交接包 `REFERENCES/HISTORY_NPC/104_commits/053_commit_fix(map)__校正_Route30_南口偏移和_Route32_35_北口可视缓冲_d5b2c172.patch` 明确记载三处历史回归：

- `Route30 SOUTH → CherrygroveCity`：旧宏错误复制15列；应从吉花市第5列读取10列。
- `Route32 NORTH → VioletCity`：曾只复制10列，实际需要10列重叠区 + 3列右侧显示预览（13列），不扩大原来的 x14/15 通路。
- `Route35 NORTH → Route36`：同样要13列预览，但只允许原有 x17 通路；不同 Gold 偏移不能机械复用同一个计算式。

旧 `docs/JOHTO_CONNECTION_VISUAL_223_CLOSEOUT.md` 还说明，曾要求 `--all-active` 真实连接门禁；当前交接包没有对应旧工具的可执行本体，所以没有把旧实现当作已运行测试。

## 本轮真实检查

- 从当前 `JohtoPilotSourceConnections` 读取 **20条已登记有向连接**，检查双向、唯一、准入登记。
- 从当前已登记地图的长宽找出两类风险：`N/S` 窄图进宽图 **5处**，`E/W` 矮图进高图 **2处**。后者此前未进入宽差风险检查。
- 七处均检查已审查的连接Header中的精确显示复制维度和源图偏移；以后新增任一类高风险连接却没提供合同，直接 FAIL；所有新增连接不论形状也必须先审查，不能仅登记后放行。
- 额外做故障注入：Route32北口由13列退回10列必须 FAIL；Route30南口改回15列必须 FAIL；Route30源图偏移丢失必须 FAIL；Route31西口和Route36东口源码条带被改坏必须 FAIL；人工新增东西向矮接高连接也必须 FAIL。

## 风险地图（当前连接，无新静态异常）

| 风险方向 | 源地图→目标地图 | 已审查的关键点 |
|---|---|---|
| NORTH | Route30→Route31 | 源列偏移+10，当前10列 |
| SOUTH | Route30→吉花市 | 源列+5、复制10列 |
| NORTH | Route32→桔梗市 | 10+3列显示预览 |
| NORTH | Route34→满金市 | Gold +5连接及Header合同 |
| NORTH | Route35→Route36 | 10+3列显示预览，不放宽出口 |
| WEST | Route31→桔梗市 | 纵向9行与源行9的偏移 |
| EAST | Route36→桔梗市 | 纵向9行和同Bank邻图镜像 |

以上为静态审计结果，不等于真实ROM画面、移动与Bank链接验收，也不保证所有未来无宽高差的接缝没有图角残留。准入原则是 **新增连接先计算和登记视野／偏移合同、通过故障注入，再进入源码合并候选**，不可通过简单添加白名单绕开检查。缺失关键Gold／旧成熟资料时，应立即向用户索取。

## 运行

```sh
python tools/johto_active_seam_coverage_gate_291.py --project .
python tools/johto_pilot_migration_audit.py --project . --gold-root /path/to/pokegold-master
PYTHONPATH=tools:. python -m unittest tools.tests.test_johto_active_seam_coverage_gate_291
```

此批为 TOOL-292，**并非 FIX-5.62.292**。新ROM重新编译和MAP剩余64B门槛仍按项目规则在游戏运行修改后执行。
