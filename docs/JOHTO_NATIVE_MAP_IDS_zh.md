# 城都原生地图键扩容（REG-5.62.170）

> **截至 CLN-5.62.178 的状态提示（文档补记）**：下方“本次只接入地图编号兼容层、不开放 Route32 Warp”描述的是 `.170` 当时的独立功能边界，**不是当前 `.178` 工作区状态**。目前联合洞穴1F已登记为城都局部地图 ID 8，并通过32号道路入口实现经用户录像确认的双向 Warp；B1F、Route33和其他未完成入口继续封闭。新增地图仍须执行 TODO/踩坑记录的普通 Town Map、Fly 和 Field Moves 全功能接入检查。本轮仍不修改地区编号、存档或引擎指令；只调整当前版本可见字串与未提交阶段的过时备注。

这份说明描述引擎的数据接口，不是用户手机验收结果。本次只接入地图编号兼容层，**不新增可游玩的地图、不开放 Route32 未完成的 Warp**。

## 基本约束

- 旧地图 ID `$00..$FB` 保留不变；`$FC` 仅作为所有新城都地图的共享运行时句柄，**不是第 253 张地图**；`$FD` 不分配，`$FE` 仍为显式地区 Warp 转义，`$FF` 仍保留室内 `LAST_MAP`。
- 物理地图身份由 `wCurRegion/wCurLocalMapID` 和 `wLastRegion/wLastLocalMapID` 保存。位于之前未使用的保存区 `d7a4..d7a9`，不改变存档长度或其后地址；旧版存档用 `wCurMap/wLastMap` 重建地区键，只有标记有效时才信任 `$FC` 的局部编号。
- 引擎地图头、Bank、区域歌曲、Town Map 和地图名称统一按局部编号读取；旧 Kanto / Johto 的已有别名仍按原单字节逻辑进入，未改建旧编号表次序。
- 普通 `db $FE` Warp：入口表项与目标 Warp ID 必须有明确路由，不能让未实现的入口直接进入 `$FC`。对于原来的枯叶渡轮，既有四条路由保持不变。
- 新图的连接头可把邻图 ID 设为 `REGION_NATIVE_MAP_SLOT`，同时**必须**向 `NativeRegionConnectionTargets` 添加 `(源局部ID、方向索引、目标地区、目标局部ID)`；方向 `0=NORTH, 1=SOUTH, 2=WEST, 3=EAST`。连接条带、对侧 header、边缘放行仍需独立审核。
- `JohtoNativeCollisionFence` 默认四边不可越界。为了避免无地图时走进黑边，今后只对核验过的相邻入口单独放行。

## 后续新增一张城都地图的最低登记清单

1. 在 `constants/region_map_constants.asm` 增加下一个 `JOHTO_..._LOCAL_ID` 并更新 `NUM_JOHTO_MAPS`，**不再添加任何新 `mapconst` 旧编号**。
2. 在 `data/johto_map_headers.asm` 的 Header 指针、Bank、`JohtoMapLegacyAliases`、RBY 音乐中增加同行。其中新地图别名行统一写 `REGION_NATIVE_MAP_SLOT`；不要使用 `$FD` 或已有关都地图 ID。
3. 在 `engine/menu/options_menu.asm` 的 `JohtoNativeGSCMusic` 增加实际场景歌曲，在 `engine/town_map.asm` 的两个局部表中增加地图名称与地标坐标（必须使用已审计的 Gold 原版坐标）。
4. 按实际交通关系在 `engine/overworld/region_map_lookup.asm` 增加单独核验的连接与显式 Warp 表项。地图对象、脚本、地形、音乐、飞空解锁、室内门口及原版障碍仍按地图专题完成。
5. 若某个新地图要开边缘，在 `main.asm` 先核验 Gold 对应可走格，再实现局部的精确边缘策略；`JohtoNativeCollisionFence` 默认禁行不应全局取消。
6. 运行 `python tools/johto_region_id_audit.py` 及 `JOHTO_GOLD_SOURCE=... python -m unittest discover -s tools/tests -p 'test_*.py' -q`。审计器失败时不能提交候选地图；通过仍不能替代用户 ROM 构建 / 手机实际测试。

## 已知尚未自动移植的玩法

新城都地图的 NPC、野生遇敌、隐藏物件、剧情、特殊行走、飞空目标、战斗场景、洞穴入口都需要另案加地区感知数据或安全禁用。当前这轮**没有验证真实 `$FC` 地图的手机进入／继续存档**，因为没有添加任何新的物理地图，不能把离线工具 PASS 宣布为实测成功。
