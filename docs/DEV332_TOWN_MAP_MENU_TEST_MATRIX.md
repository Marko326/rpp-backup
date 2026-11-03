# DEV-332｜Town Map 菜单专项：可执行合同与实机测试矩阵（REF-326，工具-only）

> **阶段**：从 DEV-331 / REF-326 源码继续。本批不修改游戏 ASM、地图、地名字串、图片、版本标签、ROM Bank 或游戏手感。现有三个交互差异暂时只记录事实，不擅自改成另一个方案。
>
> **地名口径**：以下测试场景、后续汇报一律采用游戏里显示的英文地名。不要把中文译名当成游戏 UI 的文字，也不做游戏内汉化。

## 用户反馈与空间证据

- 蓝版 **REF-326** 的用户设备检查反馈“测过了没问题”，仅认定其实际覆盖的菜单路径正常；不外推 Red、TEST、所有菜单入口。
- 用户提交的蓝版 MAP 差异摘要：整体约 `1.01 MB` 空闲；ROMX `$17`（Bank十六进制编号）剩余 `39 B -> 29 B`，本次减少 `10 B`，只有一个 Bank 发生变化。**这是用户提交的比较数值**，本环境没有新的 Blue `.map` 文件；不拿这组数字推断 ROM0 容量。
- 工具-only 的 DEV-332 不改变 ROM 链接内容，游戏标签继续 **REF-326**。项目继续执行 ROM0 `>= 64 B` 的构建门槛，任何未来 ASM 修改需重新导出 Red/Blue/TEST MAP。

## 菜单的三个独立边界（不是同一个“地图数量”）

| 入口 | 源码当前行为 | 自动化保护范围 | 待产品决定 |
| --- | --- | --- | --- |
| **Item Town Map** | Johto `$FC` 且地区=Johto 才画 Johto 图，按 Gold 的 **45** 个地标浏览；UP/DOWN 回卷；START/SELECT 指向第一项 **New Bark Town**；Kanto START 仍按最近恢复地点定位 | 地区分派、跨 Bank 名称、B/A 退出、边缘回卷、现有快捷键 | Johto START 是否应改成 Kanto 的最近恢复地行为 |
| **Fly Town Map** | Johto 预登记 **11** 个候选目的地，但只允许稳定 ID 活动、且到访事件已解锁的项目进入选择；UP/DOWN 过滤锁定项、A 校验、B 取消；START/SELECT 返回第一个已开放点；无 Johto LEFT/RIGHT 特殊地点轴 | 初始化、双重解锁、上下两方向、A/B 和真正飞行分派后再校验、11行长度、Kanto 左右轴不回归 | Johto START 是否定位最近恢复地；Johto LEFT/RIGHT 是否要特殊目的地轴 |
| **Pokédex Nest** | 仍画 **Kanto** 地图，未提供 Johto 野生分布；按 B/文本退出与原有 UI 恢复 | 保持 Kanto-only 现状，防止没栖息地数据却错误切到 Johto 图 | 是否引入 Johto 的栖息地数据与地区切换 |

DEV-332 `tools/johto_town_map_menu_audit_332.py` 新增15项源码级行为合同，挂入 `tools/johto_pilot_migration_audit.py`，`tools/tests/test_johto_town_map_menu_audit_332.py` 配套17个测试（含16项故障注入）。源级检查不能取代 GBC CPU、图块/OAM、实际 A/B/按键重复和 ROM 链接行为的设备验收。

## 设备最小抽查（显示名称均为英文）

**一、Item Town Map（Johto）**

1. 在 `New Bark Town` 打开地图：玩家图标应显示当前位置，浏览初始文字为 **New Bark Town**；UP/DOWN 能滚到 **Route 29** 等相邻地标。
2. 在 `Ecruteak City` 打开地图：当前位置标记和显示名称对应 **Ecruteak City**；按 START/SELECT 应跳到 **New Bark Town**（当前 REF-326 规则，不是最近宝可梦中心）。B 退出后可正常移动，再打开不乱码。
3. 在 `Olivine City` 打开地图：检查显示 **Olivine City**，连续快速 UP/DOWN，45项回卷后按 B 退出，重新进入不串字。
4. 在 `Blackthorn City` 打开地图：玩家标记应指向 **Blackthorn City**，可浏览 **Ice Path**、**Dragon's Den**、**Route 45** 等尚未开放的地标；**地图能浏览不代表这些地点物理可进入或可 Fly**。
5. 在 `Lake of Rage` 打开地图：名称应为 **Lake of Rage**，而不是占位的 Route 编号；B 退出正常。

**二、Fly（Johto）**

1. 从 `New Bark Town` 或 `Cherrygrove City` 用一个已会 Fly 的队伍成员打开 Fly 地图；UP/DOWN 应只选中当前存档实际到访且可飞的项目。
2. 尝试选一个仅能在 Town Map 浏览、**但未实际活动或未到访**的城镇：Fly 不应将其当作可飞目标，也不应允许按 A 飞到错误地图。
3. B 取消后原地保留，不启动 Fly 动画；已解锁的可选地点按 A 可以飞抵已登记落点。
4. START/SELECT 依照当前行为回第一个已开放的 Johto Fly 目的地；Johto LEFT/RIGHT 目前无特殊轴，不要误报成失效。

**三、Kanto 和 Pokédex Nest 回归**

1. 在 Kanto 打开 Item Town Map，START 仍按最近恢复地定位，SELECT 仍按 `Pallet Town` 定位，退出后地图正常。
2. 在 Kanto Fly 菜单，已解锁的特殊地点 LEFT/RIGHT 轴仍可工作；按 B 取消不飞。
3. 从 Pokédex Nest 入口进入仍看到 Kanto 分布地图；退出并进入 Item Town Map 后不残留图块或输入状态。

## 之后真正修改运行逻辑的门槛

- **必须先选定操作规范**。本批拒绝“为了两边看起来一样”就改 Johto START、Fly 方向键或 Nest 底图。
- 修改 Fly 时需核对稳定 ID / 活动槽、到访 flags、真实落点，不能因为11项候选表存在就全开。
- 显示/菜单修复应优先选择有空间的 ROMX，避免占满 ROM0；新构建验 Red/Blue/TEST 的 ROM0、Bank `$17` 与目标 Bank。
- 对变更形成新版本、新负向测试和两份互斥开发补丁；未选目标前可继续工具/审计阶段，REF-326 不升号。
