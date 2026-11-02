# DEV-325｜Route44 东缘树墙视觉回归修正（仅修一张地图）

## 设备证据及根因

用户截图：Gold 原版在 Route44 接近冰之通路洞口、东侧最边界的视野，右边显示岩壁；REF-320 测试 ROM 在相同位置显示重复树木。数据 `Route44.runtime.blk` 与 Gold 逐字节一致，问题不在 Route44 地形，而在 `data/johto_route44_runtime_324.asm` 只有 `WEST` Header，没有 EAST 的 **显示预览**。未连接的地图东缘被对象默认 border `$05`（树墙）填充。

参考 Gold `maps/BlackthornCity.blk` 和成熟 NPC `data/mapHeaders/JohtoRoute44.asm`：Route44 东边的邻接数据来自 BlackthornCity 20×18，连接 offset 为 -9，首行源块地址从 Blackthorn 的第9行开始。两张地图同为 `TILESET_JOHTO`。

## 修复范围

- 新增逐字节 Gold Blackthorn 预览源 `maps/johto_pilot/BlackthornCity.east_preview.blk`（360B），不登记为活动地图。
- Route44 Header 使用 `WEST | EAST`；东侧源指针 Blackthorn + 9×20、原版偏移、11B 连接记录，仅填充 WRAM 外围三列岩壁。保留既有卡吉镇 WEST 通行。
- **东侧物理通行维持封闭**：`JohtoEastIsKnownClosedEdge` 仍会在 Route44 最大 X 向右时返回 `E=1`；`JohtoPilotSourceConnections` 未登记 Blackthorn；冰之通路也未激活。无剧情、NPC、Warp 变更。
- Gold 原版源文件对照、新版独立哈希及 Header 语义加入 `tools/johto_route44_324_audit.py`，原 `tools/johto_historic_visual_seam_guard_318.py` 也对当前 Route44 强制检查。故障注入针对取消 EAST、错误源偏移、损坏预览、意外开放东边。
- 游戏内版本由 `REF-320` 升为等长 `REF-321`，活动地图数仍 43 张，修改限 Bank `$53`。未改变 ROM0 指令。

## 本机待测

仍需在用户本机重新编译 ROM、检查 MAP（ROM0剩余至少64B、Bank `$53` 余量足够），并在 Route44 冰之通路洞口附近向东走到最边缘：右侧应显示原版岩壁，不能越界进入烟墨市；卡吉镇↔Route44 西侧通道不变。静态检查不等于 VRAM/手机实机结果。

测试阶段只提供两份互斥**正向补丁**；不生成反向隔离补丁、Git 提交日志，不替用户执行 Git commit/push。
