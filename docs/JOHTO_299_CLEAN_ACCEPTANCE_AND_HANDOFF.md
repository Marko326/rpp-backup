# CLEAN-5.62.299 — 40号路→41号水路→湛蓝市室外正式收口

## 基线与提交模式

- 项目分支：`常规功能备份`。
- 本轮确认的最近正式 Git HEAD：`c7acd823340b298637acec9042f5524cec1e014e`。
- 基线游戏版本：`FIX-5.62.298`；最终游戏版本：`MAP-5.62.299`。
- 本轮没有使用新的测试 ROM 功能，测试版本保持 `TEST-231`；提交日志不把未变化的测试版本当作版本变更。
- 从该 HEAD 到最终状态同时存在游戏运行差异和 `tools/` / 测试 / 维护文档差异，正式清理采用模式 A 两笔提交。

## 第一笔：游戏功能

活动地图由 32 张扩展到 35 张，启用稳定 ID 27–29：Route40、Route41、Cianwood City。新增室外主路线：

`Olivine City WEST ↔ Route40 EAST ↔ Route41 ↔ Cianwood City EAST`

其中 Route40↔Route41 使用 NORTH/SOUTH 互逆连接，Route41↔Cianwood 使用 WEST/EAST 互逆连接；浅葱原有北侧 Route39 通路继续保留，避免新西海边界处理把既有通路误封。

三张地图运行资源来自 Gold 原始地图和交接包中的成熟 `NPC-5.62.243` 参考。Gold `.blk`、成熟 runtime、blocked/water mask 与当前角色网格经过字节/坐标审计。Gold WATER 数量为：

- Route40：466。
- Route41：1699。
- Cianwood City：519。

本轮接入这些水格的 Surf 下水、持续移动、安全上岸与越界保护；接入 Route40 路牌、湛蓝 5 个室外牌子、Town Map 名称/坐标、湛蓝 Fly、GSC 音乐及湛蓝屋顶。新增主体运行层放在 ROMX Bank `$52`，没有继续向 ROM0 填入大块逻辑。

Route41 四个漩涡岛洞口、Whirlpool 机制、未审计训练师/剧情，以及湛蓝六个室内入口仍保持关闭。本轮只收口室外主路线，不把这些后续内容偷跑进提交。

## 第二笔：工具、测试与维护文档

累计合同由 32 张活动地图升级到 35 张、由 14 张含水地图升级到 17 张。新增 `tools/johto_west_sea_runtime_gate_299.py` 与对应测试，强制核对：

- Route40/41/Cianwood 的稳定 ID、尺寸、Header、资源描述符与 Bank `$52`。
- Gold `.blk` 与成熟参考资源一致性。
- 6 条连接记录组成 3 组互逆连接。
- 浅葱北侧 Route39 回归保护及浅葱西侧 Route40 合法通路。
- 三张地图的水域边界、Surf 分派、岸边处理与非法越界阻断。
- Route40/41/Cianwood 的未开放 Warp 继续为 0。
- Route40 / Cianwood 室外路牌文本、地点名、Fly、音乐与屋顶登记。

历史阶段审计中原先把 32 张活动地图写死为永久条件的部分已改为继续保护各自历史能力，同时允许后续合法扩图。Surf manifest 同步冻结三张新增地图的 Gold WATER 坐标和源 `.blk` SHA，避免后续只改一格水域却静默通过。

清理前重新执行：

- `python tools/johto_west_sea_runtime_gate_299.py --project . --gold-root <Gold> --reference-root <NPC-243>`：68 项通过；缺 Surf 越界保护、角色网格漂移、缺互逆连接三类负向故障均被拒绝。
- `python tools/johto_surf_build_gate_296.py --root . --gold-root <Gold>`：35 张活动地图 / 17 张含 WATER 地图通过。
- `python tools/johto_field_move_coverage_audit.py --root . --gold <Gold>`：35 图 / 4240 WATER / 9 Cut / 165 HOP，PASS。
- `python tools/asm_symbol_preflight.py`：2091 个 ASM 文件局部符号通过。
- `python tools/johto_pilot_migration_audit.py --project . --gold-root <Gold> --reference-root <NPC-243>`：`934/934 PASS_STATIC_ONLY`。
- `python -m pytest -q tools/tests`（带 Gold/NPC 环境变量）：`469 passed, 18 skipped, 82 subtests passed, 0 failed`。

这些工具仍属于开发者离线门禁，不加入用户 Makefile/RGBDS 构建流程。

## 用户 MAP 与设备反馈

用户提供 `MAP_20261101_084042.zip`，其中 Red/Blue MAP 都明确记录正式版本 `MAP-5.62.299`、测试版本 `TEST-231`，未发现版本不一致。

MAP 空间结果：

| Bank | Red | Blue | 结论 |
|---|---:|---:|---|
| ROM0 `$00` | 64 B | 64 B | 恰好达到项目最低 64 B |
| ROMX `$4E` | 74 B | 74 B | 仍很紧 |
| ROMX `$51` | 11,578 B | 11,578 B | 旧 Johto Bank 仍有余量 |
| ROMX `$52` | 8,695 B | 8,695 B | 本轮西海运行层余量充足 |

用户在正式清理前报告：实际走过新增水路未见明显问题，能够正常下水和上岸，音乐正确，Fly 能解锁，普通 Town Map 能看到更新。该反馈足以把本轮主通行、Surf、音乐、Fly 与普通地图更新记录为已观察通过。

仍不能据此宣称 Red/Blue 两个色版的所有像素边界、所有旧存档、所有未开放入口、Route41 漩涡岛/Whirlpool 或湛蓝室内都已逐项测试；这些范围本轮本来也保持关闭。

## 清理包应用顺序

1. 如果当前工作区已经应用 `MAP-5.62.299` 开发候选，只应用“清理增量补丁”得到最终清理状态。
2. 如果从已确认干净 HEAD `c7acd823...` 开始恢复，则使用“基线全量补丁”；它和清理增量互斥，不能叠加。
3. 在完整最终状态应用“工具/审计反向隔离补丁”，临时撤回第二笔工具、测试及维护文档，只保留第一笔游戏功能。
4. 按功能中文日志提交第一笔。
5. 对同一反向隔离补丁执行 `git apply -R`，恢复工具、测试及维护文档。
6. 按工具中文日志提交第二笔。
7. Git Commit/Push 由用户自行执行。

## 后续最小回归建议

本轮已经有用户水路设备正向反馈。提交前或下一批扩图前建议只做最小回归：

- 浅葱北口↔Route39 往返一次，确认 `.297/.298` 旧主线未被新边界破坏。
- 浅葱西口→Route40→Route41→湛蓝，再原路返回一次。
- 在 Route40、Route41、湛蓝各做一次水→陆和陆→水。
- 湛蓝使用一次 Fly；打开普通 Town Map 确认玩家标记和新增地图名称仍正常。
- 确认 Route41 漩涡岛洞口、Whirlpool 与湛蓝室内仍保持未开放。

本环境没有自行编译、链接 ROM，也没有操作用户 Git Commit/Push；用户提供的新 MAP 与实机反馈作为本轮链接/设备证据记录。
