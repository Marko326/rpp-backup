# DEV-333 | Kanto Town Map 功能清单与 Johto 安全移植（REF-327）

> 基线：用户提供的 REF-325 干净 HEAD `300e0a4c...` + DEV-330 / DEV-331 / DEV-332 累计补丁。本阶段只修改 Town Map 相关游戏 ASM、版本字串、审计/测试和维护文档；不构建 ROM，不执行 Git Commit/Push。
>
> 游戏内地名和用户测试指引 **只使用英文**；没有要求汉化。用户提供的蓝版 REF-326 MAP：Bank ROMX `$17` 余量由39B变29B；这不是本轮 REF-327 的构建空间证据。

## 关都已有功能与本轮处理

| Kanto 原生能力 | 现有 Johto 状态 | DEV-333 移植与边界 |
| --- | --- | --- |
| 道具 `TOWN_MAP` 打开世界地图、玩家当前位置标记 | 已有 Johto 素材和活动47槽→Gold 45地标映射 | 继续复用，不改贴图 |
| UP/DOWN 遍历地名、边缘回卷、SELECT 到地图第一项、B 退出 | 已有同等功能 | 保留45地标回卷与原退出路径 |
| START 定位上次恢复/治疗点 | Johto 无已开放 Gold Pokécenter/last-heal 数据，Kanto `wLastBlackoutMap` 不可混用 | **可移植的“快速定位”部分**：Johto START 回当前玩家所属Gold地标；不是上次治疗点；Kanto原样保留 |
| Fly 目的地列表、已访问判定、选中鸟图标与光标、A确认/B取消 | 现有11候选，活动稳定ID＋到访flag双门禁，动画后再检查 | 保留全部门禁、11项与原目标；没有把45地标全设成可飞 |
| Fly START 定位上次治疗点，SELECT回第一可用城市 | Johto START/SELECT均重置第一解锁地点 | Johto START 只在**当前地图本身**是活动且已到访Fly候选时定位；否则保持原光标和轴。SELECT仍回第一已解锁城市轴。Kanto START仍是 last-heal |
| Fly LEFT/RIGHT 切特殊地点轴，UP/DOWN 返回城市轴 | Johto 仅有列在11候选中的非城镇Fly点 `Lake of Rage`，没有其它已接入落点 | 增加 Johto LEFT/RIGHT：仅在Lake已活动且到访时进入`Lake of Rage`特殊轴；否则原光标不动；从该轴 UP 朝 `Blackthorn City` 一侧回城市轴，DOWN 朝 `Mahogany Town` 一侧回城市轴，均继续跳过未解锁地点。原有竖向11候选仍保留，避免破坏旧习惯 |
| Pokédex Nest 遭遇地点标记、Area unknown、退出 | 实际野生遭遇查找是Kanto表；Johto运行 `LoadWildData` 直接 NoMons | **暂不可真实移植到Johto底图**。继续使用 Kanto Nest，避免在城都图上显示关都坐标造成错误。待后续城都野生遭遇数据进入后单独增加 Johto Nest。 |
| 跨Bank的名称读取、菜单精灵/图块恢复 | DEV-331 29字符上限+`@`，已有恢复 | 不回退 bounded-copy 与退出恢复 |

## 本轮实际改动

- `engine/town_map.asm`：普通城都 Town Map START 使用 `JohtoPilotGetTownMapLandmark`，保持Kanto START语义不变。
- `engine/johto_pilot_fly_map.asm`：把 Johto Fly 的START与SELECT分开；START只定位真实活动且到访的当前Fly地点；LEFT/RIGHT切唯一已登记非城镇 `Lake of Rage` 的独立轴；UP/DOWN从特殊轴返回实际可用的城市候选；不改Kanto流程。
- `tools/johto_town_map_menu_audit_332.py`与测试：使三路径的新实现进入统一Gold迁移审计，新增回归与故障注入；继续锁定取消与动画后双重校验。
- `data/game_version.asm`：`REF-326` → `REF-327`（等长文本，ROM0不引入新指令）。

## REF-327 设备重点检查（英文就是实际游戏显示文本）

1. 在 `Ecruteak City` 打开 `TOWN_MAP`，滚到 `Route 46` 后按 START，应回到 `Ecruteak City`；SELECT 应回到 `New Bark Town`。在 `Route 45`、`Route 46` 和 `Lake of Rage` 同样检查 START 的所属地标；在Kanto按START仍按最近Pokécenter的定位规则。连续退出/重入后可以行走。
2. 在 `Ecruteak City` 打开Fly，滚到其它已解锁目的地按START，应回到 `Ecruteak City`；在 `Route 45` 使用Fly时按START，应该保持现有选择，**不会**自动飞往 `Ecruteak City` 或把道路当作可飞地点；SELECT仍回第一已解锁目的地。
3. **没到过 `Lake of Rage` 时**：Fly界面 LEFT/RIGHT 不应切换到未解锁的 `Lake of Rage`，B可正常取消。**已到过时**：LEFT/RIGHT 应切到 `Lake of Rage`，UP从特殊轴寻向 `Blackthorn City` 的已到访候选，DOWN寻向 `Mahogany Town` 的已到访候选，未到访城市必须跳过。A确认Fly只在解锁后有效，B取消不会飞行。
4. Kanto Fly LEFT/RIGHT特殊地点、Pokédex Nest进入/退出，以及Johto 45地标回卷仍按原逻辑工作。
5. 本机编译Red/Blue/TEST后分别核对最新版MAP：ROM0≥64B；重点检查ROMX `$1C`（普通Town Map）、Johto Fly Map新放置Bank及用户蓝版已近满的`$17`。源码静态审计不等于链接及设备验收。

## 明确暂不做

- 不伪造Johto治疗点、`wLastBlackoutMap`、存档字段或Teleport流程；因此“START跳上次治疗点”的Johto完整等价**尚未实现**。
- 不给Gold洞穴新增可飞落点（例如 `Ice Path`、`Dark Cave`），也不删除已有 `Lake of Rage` 竖向Fly兼容项。
- 不把Kanto野生遭遇画在Johto Nest图上；不修改地图碰撞、Warp、野外NPC、道具或剧情。
