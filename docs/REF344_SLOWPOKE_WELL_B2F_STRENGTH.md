# REF-344｜呆呆兽之井 B2F + B1F 怪力石头

- **基线**：用户所给 REF-343 未提交工作区（正式 HEAD `0a676cb4722728c990ff5340527c7762d66d245d`）。本轮改源码，不编译、不 Git Commit/Push。
- **复用**：现有联合洞穴 `JOHTO_UNION_CAVE` 图块集、地图 Header、注册 Warp、Gold 方向墙/冲浪/落点分派；不引入另一套 Cave 引擎。
- **B2F**：10×9 Gold 地图，稳定ID185→slot60；原 Gold 90 个图块均可通过已验证旧洞穴映射转换（15 种图块类型）；独立 100 WATER + 31 UP_WALL 坐标表；Gold 等价静态核对 644 次方向行走、400 次冲浪/上岸相邻转移均无差异；B1F Gold `(7,11)` 进 B2F `(9,11)`，反向可通行；活动图61，注册Warp144。
- **怪力**：Gold B1F `(3,2)` 才有石头，B2F 没有。直接登记 `SPRITE_BOULDER`，其行为复用已有 `HandleBoulderInteraction`、`TryPushingBoulder`、`CheckForCollisionWhenPushingBoulder`。没有写新技能引擎。当前 Kanto Strength 的可用门槛是会 Strength 并有 **Rainbow Badge**；尚未迁移为 Gold Plain Badge。石头起点相邻四格的 Gold/现有 RBY Strength 碰撞逐格核对；沿用旧推石头碰撞引擎，远距离推动及 UP_WALL 推石头语义仍需手机实测，不冒充已完整移植 Gold 怪力。
- **留空**：Gold 的 Rocket、Slowpoke、Kurt、Gym Guide、Rain Dance TM 等 NPC / 剧情 / 道具事件仍不开放；这不是地图漏接。
- **静态审核**：`python tools/johto_slowpoke_well_344_audit.py --project . --gold-root <Gold root>`；Surf 和 Map Sign 强制审计；测试在 `tools/tests/test_johto_slowpoke_well_344.py`（运行时设置 `JOHTO_GOLD_ROOT=<Gold root>`）。旧 REF-338/旧 Union Cave 单层审计若仍锁死旧地图/路由数量不可当成本阶段新失败。
- **待用户验收**：Red/Blue/TEST 新 ROM + MAP；ROM0 至少64字节余量，新增 ROMX bank 余量；旧存档进入 B1F/B2F，四向移动/Surf/方向墙/楼梯/石头（含推向实体墙禁止穿墙）与离开洞穴。静态通过不能替代动态检查。

## CLEAN-REF344 用户反馈
用户确认已在手机上正常使用怪力推动 B1F 石头；此反馈仅覆盖怪力基本推动，不自动覆盖整张 B2F 楼梯/Surf、旧档和 Red/Blue/TEST 三版 MAP。ASM/游戏标签没有为清理再次修改。
