## 本轮验收补记（VIOLET-248-ACC-001）

用户已反馈 VIOLET-248 修复后在手机上能够正常上岸；后续上传的 `.248` 工作区也报告测试无异常。此结论仅代表用户反馈的场景。源代码继续使用原引擎通行检查，没有修改 Surf 状态机；本文前面“待用户本机确认”的描述是修复当时的历史状态，最新验收状态以本节为准。

# VIOLET-248｜桔梗市冲浪上岸修复

## 根因

当前 PAL-5.62.247 在 `home/overworld.asm::CollisionCheckOnWater` 的桔梗市分支中，先调用 `JohtoVioletWaterAhead`。返回 Carry 时目标是 Gold WATER，保持冲浪正确；返回非 Carry 时表示岸、墙或地图外，随后必须走现有 `wTilesetCollisionPtr` 通行表判断。

原分支直接跳到 `.checkIfNextTileIsPassable`，没有保证 `C` 是 `wTileInFrontOfPlayer`。通行扫描比较的是 `C`，因此会拿到旧值，岸上本来可走的格子也可能被当成碰撞。

## 与旧 NPC 金银参考实现的比较

旧参考工程在 `home/overworld.asm::CollisionCheckOnWater` 对城都专用 Surf 查询执行后，先判断是否为 WATER；若不是水，则执行：

```asm
ld a, [wTileInFrontOfPlayer]
ld c, a
```

再进入原通行表扫描。VIOLET-248 将这两条指令补回当前 PAL 的桔梗市专用分支。它没有直接复制旧工程的地图编号或整个 Surf 子系统，而是沿用当前项目的稳定 ID/精确 Gold 水格查询，并复用现有的通用上岸状态清理、玩家图形和音乐恢复逻辑。

## 变更与测试

- `home/overworld.asm`：非水分支恢复前方图块 ID 到 C。
- `data/game_version.asm`：正式标签更新为 `PAL-5.62.248`；`TEST-231` 不变。
- `tools/tests/test_violet_surf_shore_248.py`：验证指令顺序，并移除指令做负向故障注入。

本助手不编译/链接 ROM。RGBDS 真实构建、ROM0/Bank MAP 空间、手机上岸与重新入水测试均待用户本机确认。
