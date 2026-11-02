# DEV-326｜烟墨市室外地图（REF-5.62.322）测试阶段交接

- 基线：已经应用 DEV-325 的工作区；累计补丁起点为原始 Git HEAD `a167b2ad2bc8b12d3cb777c7120c008f7fdf8a5b`。
- **只新增一张活动地图**：Blackthorn City，稳定 ID71，slot43，活动总数 44。
- **不做**：Ice Path 冰洞内部、龙穴、城市室内、Route45/46 实际通行、剧情、NPC、战斗、训练师。
- Gold 20×18 block 原图与上一轮 Route44 东侧预览共用同一份 360B `.blk`；角色网格 40×36，WATER 80 格；地图跳崖 47 处。
- Route44 东端 ↔ Blackthorn 西端按 Gold `+9/-9` 块偏移接入可走接缝。城市南缘使用 Gold Route45 原图 **仅作为画面预览**，由运行时物理守卫阻挡；北缘和东缘不开放。
- 防树墙：`tools/johto_route44_324_audit.py` 与 `tools/johto_blackthorn_326_audit.py` 已接入当前主审计，不提供 Gold 时仍用固定哈希检查两张原版预览 `.blk`；附 Gold 源码时由主审计额外强制运行 `tools/johto_historic_visual_seam_guard_318.py` 全量历史视觉核对。**没有 Gold 参考时，全量历史核对不可声称通过**。
- 游戏版本显示 `REF-322`。本阶段只交工作区增量和干净 HEAD 累计全量 **两份互斥正向补丁**；不要双打，不做 AI Git 提交。
- GameShark `010138CD` 写内存 `$CD38=wSimulatedJoypadStatesIndex`，不是官方的穿墙配置；之前 FIX-274 修复了利用陈旧脚本按键状态绕过陆地碰撞的问题，因此此旧码可能失效。**本次不改正常碰撞以恢复金手指**；如需测试专用穿墙，后续应隔离为独立的 debug 构建开关，不影响正常 ROM/存档。

## 用户验收事项

1. 在手机本地重建 Red/Blue（以及项目要求的 TEST）ROM，并检查最新 MAP 的 ROM0 剩余不少于 64B、Bank $53 空间不溢出；这里没有编译或生成新 MAP。
2. 从卡吉镇进入 Route44，沿 Gold 东侧边界进入 Blackthorn；再从 Blackthorn 西侧返回 Route44，观察两侧地形、岩壁、坐标是否正常。
3. Blackthorn 南侧只显示 Route45 Gold 地形，**不允许穿越**；Ice Path 洞口和城市建筑同样不能进入。巡视水域和跳崖，核对城市名称及音乐占位。
4. 如 Gold 接缝视图或任何物理阻挡与参考不一致，带截图反馈。源码级静态检查不替代手机实机验收。
