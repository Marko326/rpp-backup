# PAL-5.62.252｜城都门房骑车、29号道路砍树、32号道路冲浪和砍树（历史阶段记录）

> 本文件记录 `.252` 阶段当时的实现与静态检查状态；之后 `.253` 已补齐若叶镇 Surf、Route32 跳崖派发与地点栏，并由用户反馈本轮构建／实机回归全部通过。当前功能与验收结论以 `docs/JOHTO_FIELD_MOVES_253.md` 为准。

## 真实输入、版本与边界

- 用户提供干净 `PAL-5.62.250(1).zip` + Gold 参考源，以及上一轮从该基线制作的 `.251` **开发补丁**。没有新的用户实际 HEAD 或 `.251` 本机编译/手机验收回报；本轮沿上一版候选继续，**不是已确认的 Git 提交**。
- 正式版本变为 `PAL-5.62.252`；测试仍为 `TEST-231`，地图活动数仍为9；不更动旧存档布局、徽章门槛、地图连接、NPC/Warp、原始141块 Gold blockset 和关都行为。
- `Route29` 原版无 WATER，本轮只接2棵 Cut；`Route32` 原版有278 WATER +1棵 Cut；新若叶镇东侧8格水仍由用户要求跳过。

## 原版金银的门房骑车规则（查源，不以名称猜环境）

证据在所附 `Gold/pokegold-master`：

1. `engine/events/overworld.asm` 的 `BikeFunction.CheckEnvironment`：`CheckOutdoorMap` 成功、或环境为 `CAVE`、或为 `GATE` 时，**仍需脚下地形低半字节为 FLOOR**，才能使用 Bike；普通 `INDOOR` 不允许。
2. `engine/overworld/map_setup.asm` 的 `CheckUpdatePlayerSprite.ResetSurfingOrBikingState`：地图切换遇 `INDOOR`／`ENVIRONMENT_5`／`DUNGEON` 才下车，`GATE` 不在强制下车清单。
3. `data/maps/maps.asm` 环境表：`Route31VioletGate`、`Route29Route46Gate`、`Route32RuinsOfAlphGate`、`Route35GoldenrodGate` 等为 `GATE`；**`Route35NationalParkGate`、`Route36NationalParkGate` 为 `INDOOR`**，尽管外形／名称是门房。不应做图块集全局白名单。另有不启用的 `SafariZoneFuchsiaGateBeta` 为 `INDOOR`。
4. 同一份 Gold 表中，部分**金银版关东门房**也为 `GATE`，不要将“初代红蓝版关东门房限制”误等同于第二世代金银版的关东地区。

目前活动的城都门房**只有** `Route31VioletGate`（稳定 ID6）；`home/overworld.asm::IsBikeRidingAllowed` 在 legacy tileset 规则前检查 `(wCurMap==$FC, wCurRegion=Johto, wCurLocalMapID==6)`，单点许可、统一作用于自行车道具、快捷键、地图载入、宝可梦摘要返回；不用 `JOHTO_GATE` 全局加白名单，也不放开城都屋内或任何关东建筑。其它尚未启用的门房到激活时再按 Gold 环境逐张登记，不在本轮伪称开放。

## 精确原版地形和实现

| 地图 / ID | Gold WATER | Gold CUT_TREE 坐标 (x,y) | 清除后块 |
|---|---:|---|---|
| Route29 / ID1 | 0 | (30,9)、(21,11) | `$63→$8D`、`$5F→$8F` |
| Route30 / ID3 | 32（保留 .251） | (8,6) | `$67→$8E` |
| Route31 / ID4 | 44（保留 .251） | (13,5)、(25,10) | `$5F→$8F`、`$5B→$90` |
| Route32 / ID7 | **278（本版新增）** | (10,19) | `$63→$8D` |

- `JohtoRoute32GoldWaterCells` 保持 278 个 Gold `.blk`/collision 16×16 WATER 坐标；`JohtoRoute32IsActive` 地图/地区/稳定ID fail-closed。`JohtoVioletWaterAhead` 在原有 Route30/31 之后继续银行内路由 Route32，使用原道具 Surfboard 与招式调用，不在 Bank `$03` 加一次 farcall。
- `home/overworld.asm::CollisionCheckOnWater` 单独按 Route32 ID 调用其 WATER helper；遇非水先还原 `wTileInFrontOfPlayer→C`，再走原岸线判定，避免可以下水而不能上岸。新开放水域逐格确认未被全局陆地白名单当作可行走普通地砖。Gold 靠水 FLOOR 动态审计当前未发现遗漏。
- `JohtoRoutesGoldCutCells` 扩展至当前四条道路共6棵；运行时精确校验 *面对树的 Gold 位置* 和 *原块仍在画面*，切下后保留其它象限（包括可摇树）与复砍保护。Route29/32 直接使用 .251 既有块 `$8D/$8F`，**无需在 Bank `$03` 扩张 Cut 映射或多加远调用**。
- `.251` 的 `Johto Violet Field Skills` 被自动排到近满 Bank。为了安全容纳 Route32 278格数据，整个原节（保持所有原有全局标签与调用接口不变）显式放进此前红蓝 MAP 均标记 `EMPTY` 的扩展 **Bank `$48`**；最终仍必须以用户重新链接生成的红蓝新 MAP 检验。ROM0 只有少量自行车身份判断和水中碰撞分派的增量，不能宣称无需链接也能确定 JR 距离与 Bank 使用。

## 静态检查与未完成验收

- `GOLD_SOURCE_ROOT=<交接包Gold目录> python -m unittest discover -s tools/tests -p 'test_*.py'`：153 项运行，151 通过，2 条条件跳过（不等于模拟器测试）；新增门房身份误放开、Gold 骑车环境、树木坐标/原始块/只清理目标象限、Route32 逐格 WATER 和 Bank `$48` 保护验证。
- `python tools/johto_surf_preflight.py --gold <Gold目录>`：三入口、受限 helper、278 WATER 和 Gold FLOOR 岸线预检 PASS；`johto_surf_coverage_audit.py`：已登记所有活动水面，仅 NewBarkTown 按用户要求 `DEFERRED`。
- `python tools/asm_symbol_preflight.py`：2,067 ASM 文件局部标签预检 PASS。门房、Warp、地图迁移审计亦分别需检查。
- **未做** RGBDS 编译／链接、正式红蓝/TEST红蓝 ROM、最新 `.map`、模拟器或手机实际验收。开发候选补丁不等于项目可合并成果，也不代用户 Git Commit/Push。

## 用户手机和构建验收顺序

1. 先以正确**唯一**补丁升级工作区；运行正式红蓝和测试红蓝编译；查看新 MAP ROM0、Bank `$03`（仍不增加字节）、`$43`、`$48` 和 `JR/ASSERT`。
2. 在31号道路骑车**连续穿过**门房到桔梗市并原路返回；门房内部上下车、快捷键、背包使用；Bike Song On／Off 的5种音乐模式；门房内保存／Continue、从宝可梦摘要返回；进入吉花市向导屋仍应自动下车，关东门房规则不能回归。
3. 在29号道路分别从合法可达位置砍 `(30,9)` 与 `(21,11)`，砍后能走、二次不重复，周围摇树/地图图块不消失；同样回归30、31号路已接的树。
4. 32号道路各段水域从不同合法岸边下水、上岸、岸上移动再下水；Surf 招式和 Surfboard、四方向游泳、Cut `(10,19)` 后通行、北侧桔梗市↔32号路往返、跳崖、存档／Continue；水上不可穿墙、陆上不能把水当普通地面。
5. 吉花市西南岩石平台／桔梗市 Surf Cut／关都冲浪和骑行回归；若失败返回具体位置、方向、完整编译错误和新 MAP。

**交付**：`.251→.252` 开发增量 和 `.250干净ZIP→.252` 累计全量二选一，**不能叠加**；用户当前实际 HEAD/dirty 状态未知。本轮只提供开发补丁，不制作 Commit 日志、不自行提交。
