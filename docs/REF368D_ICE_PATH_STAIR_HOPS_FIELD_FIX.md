# REF-368D@｜冰之通路楼梯、跃崖与山洞 Field Move 回归修正（开发测试）

## 复现与根因

用户在手机看到 B1F 楼梯却无法向其移动，像撞墙。REF-368C B1F Gold 第八个 Warp 误登记 `(5,25)`，与第七个 Warp 同格；真实 Gold 第八个 LADDER 是 `(11,27)`。除此之外 B1F 的 `LandDecision` 没放行真实第八梯。两处必须一起修，不准修改 Warp ordinal（第七梯通 1F，第八梯通 B2F Blackthorn），也不得混淆坐标的 `.asm` `db Y,X` 与源 Gold 的 `(X,Y)`。

1F 的 Gold 一向跳崖（(35,16) 同时向左/下、(36,16)/(37,16) 向下）原有地形但未接入玩家移动的 `HandleLedges` 公共入口。现按联合洞穴、黑暗洞穴方式在 1F 地面网关先判断跳跃，再执行 1F 角色碰撞。Gold Blackthorn B2F 的 `(5,8)` 左/下、`(6..9,8)` 向下六个方向组合保持。五张地图共有 **10 个方向跳跃**，无其它 Gold HOP 源格。

## 新地图 Field Move 与普通洞穴对照

- **自行车**：五张地图均在 `IsBikeRidingAllowed` 公共分派中，各按 Gold role 判断是否能在 FLOOR 处新上车；不是仅有未被调用的内部函数。ICE 不能新上车，已骑车状态按原流程保留。对照联合洞穴、黑暗洞穴的地图专用判定，未全局开放 JOHTO_ICE_PATH 骑车。
- **Dig / 逃洞绳**：原 REF-368C 不含 `CanUseEscapeRope` 的 Ice Path 分派，会显示不能使用。仿照 Dark Cave，在进入 1F 时仅对 Route44、Blackthorn City 两个**室外入口**保存来源到 `EVENT_9CA/9CB` 预留 bit，不被地下楼梯改写。若来源可识别，`CanUseEscapeRope` 和特殊 Warp 解析进入相同安全分支，分别回到 Route44 `(56,8)` 或 Blackthorn `(36,10)` Gold 地面（而不是撞到洞口墙格/返回最后治疗中心）。旧存档若尚无合法来源，不允许错误地返回外部；需要先从地表重新进洞记录。此处尚未 ROM/手机实测。
- **地图登记**：五张活动 Ice Path、地图牌、存档、Town Map、音乐依旧保留；总 70 活动地图、188 条方向 Warp；B1F 四条可通楼梯、五图共十二个活动源楼梯格及四个额外室外门口/地毯到达过程由原有门禁覆盖。
- **不应开通的机关**：Gold ICE 673 格仍普通走路，不自动滑行；四个 B1F PIT 目标 B2F ICE 目前**到达专用、不可反向踩上触发**；四个怪力石头仍仅可见/阻挡/安全对话、不可推动。碎岩、道具、NPC、野怪及剧情仍在后续阶段。没有因新增地图而提前开放 Surf/Flash 等无关场地动作。

## 项目验证（只有源码级）

- `python tools/johto_ice_path_stair_ledge_368d_audit.py --root .`：Gold 五图 12 个活动梯、10 方向跳崖、两图公共跳崖入口、五图自行车及 Dig/逃洞绳来源和出口。
- `python tools/johto_warp_field_entry_gate.py --root .`：152/152。
- `python tools/asm_symbol_preflight.py`：源码静态符号检查。
- `python tools/johto_table_assert_preflight.py --root .`：70 张图三张表长度吻合。
- `python -m pytest -q tools/tests/test_johto_ice_path_stair_ledge_368d.py`：15/15（含错误注入），并跑已有五图相关回归。
- `python tools/validate_current_project.py --skip-pytest`：以最终结果为准，历史 `johto_pilot_migration_audit.py` 有过期冻结规则失败；不可宣称全绿。

## 未验收与手机必测

**本轮不调用 RGBDS 编译/链接，不出 ROM/MAP，不执行 Git Commit/Push。** 需用户在最新版 ROM 重新从室外进洞（避免旧 WRAM 缓存）：

1. B1F `(11,27)` 第八梯踩入 Blackthorn B2F `(3,15)`，原第七梯 `(5,25)` 仍正确回 1F；两处双向反复往返。
2. 1F 四个方向跳崖、Blackthorn B2F 六个方向跳崖；边沿不能逆跳，两格落点无卡墙。
3. 五层普通 FLOOR 上自行车，ICE 上禁止新骑；从两侧入口分别进洞、下楼后 Dig/逃洞绳返回正确室外 FLOOR；旧存档未重新进洞时拒绝过期来源。
4. 四个石头文本与碰撞、地图牌、Town Map、转场淡入淡出、存档读档；四款 ROM 的编译和 MAP ROM0 剩余至少 64B。

本轮基线：`01` 是用户 REF-368C 实际开发工作区；`02` 是已经核实的正式 REF-367 HEAD `cd88452a05e9399b469f12fe2c6c89dd532dfcfb` 累计至 REF-368D。两份补丁**二选一，严禁叠加**。只交一个 ZIP 内含两份 `.patch`。
