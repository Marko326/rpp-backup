**CLEAN-306 最新验收说明**：REF-306 用户实机视频已证实圆朱东西门房红色警员在柜台南侧面朝上按 A 可分别触发不同对话，两人保留为正式 NPC；REF-304 的北侧对话站位、REF-305 的 `$00` 柜台取样均是历史错误，以 `docs/JOHTO_GATEHOUSE_COUNTER_TALK_FIX_306.md` 的 `$0E` 和最终清理结论为准。其余八座门房 NPC 仍待恢复。
> **历史审计更正（REF-305）**：本文件中的 REF-304 试点审计曾错误地把玩家北侧 `(5,1)` 当成唯一对话站位，并把全局 `SPRITE_GUARD` 的蓝色调色板当成 Gold 原版颜色。这两项假设均已废止。Gold 原版警员面朝 DOWN，正确柜台对话站位是南侧 `(5,4)` 面朝 UP，隔着 `(5,3)` 柜台格；Gold 对象使用 `PAL_NPC_RED`。请以 `JOHTO_GATEHOUSE_NPC_PILOT_305.md` 和 REF-305 审计为准。

# REF-304｜圆朱东西门房 NPC 独立运行试点

## 基线与范围

- 分支：`常规功能备份`
- Git HEAD：`27a2086219b56238e26844676f3a5328e5b567ee`
- 前置：先应用用户上传的 `正式_REF-5.62.303___测试_TEST-234.patch`
- 本轮：只在 ID23／ID62 两张门房加入一个 Gold 来源警员；不恢复其它门房 NPC，不修改碰撞、Warp、地图资源、存档布局或剧情旗标。
- 项目正式版本：`REF-5.62.304`；ROM 内统一短标签：`REF-304`。正式与 `BATTLE_TEST_BUILD` 构建的字符串完全相同，且比原 TEST 标签更短，不增加测试 ROM 的 ROM0 占用；测试构建宏和测试功能仍保留。

## Gold 来源

Gold 原版 `maps/Route38EcruteakGate.asm` 和 `maps/Route42EcruteakGate.asm` 各有一个 `object_event`：

- `(x=5, y=2)`
- `SPRITE_OFFICER`
- `SPRITEMOVEDATA_STANDING_DOWN`
- `OBJECTTYPE_SCRIPT`
- `jumptextfaceplayer`，无 scene script、无 callback、无事件旗标条件。

西门房对话询问玩家来自哪里，并提及 NEW BARK TOWN 与 PROF.ELM；东门房提醒 MOUNT MORTAR 像迷宫。

## RPP 实现

两座地图分别保留自己的：

- Runtime Header
- RuntimeObjects
- TextPointers
- Officer 对话文本

各自 RuntimeObjects 的 Sprite 数量从 0 改为 1，并追加：

`object SPRITE_GUARD, 5, 2, STAY, DOWN, $1`

Gold `SPRITE_OFFICER` 的原始像素外观与 RBY 工程已有的男性 `SPRITE_GUARD` 对应；`SPRITE_OFFICER_JENNY` 是女性 Jenny，不能误用。对象坐标、站立状态、朝向及文本 ID 由现有 `object` 宏编码。对象格 `(5,2)` 与警员朝下时玩家应站立交谈的北侧格 `(5,1)` 均已核对为可通行地面。

门房碰撞共享例程仍只处理 ID23／62 的地毯入格判定；不参与 NPC 选择或对话。地图 Header 根据稳定 ID 分别解析到不同运行时 Header，A 键对话通过各自 TextPointers 读取 text ID 1。

`JOHTO_GATE` 走现有室内式对象精灵装载路径，`SPRITE_GUARD` 已有 SpriteSheetPointerTable 图像记录。新增 Bank ASSERT，确保 Header、对象表、文字指针与对话文本同 Bank。

## 测试

新增 `tools/johto_gatehouse_npc_pilot_304.py` 与 `tools/tests/test_johto_gatehouse_npc_pilot_304.py`：

- 核对 Gold 原版对象位置、精灵类型、朝向及简单对话脚本。
- 核对 RPP 每座门房恰好一个警员、坐标 `(5,2)`、朝下、文本 ID 1。
- 核对两张地图的 TextPointers 与对话独立，防止西／东门房串台。
- 核对对象加载器、DisplayTextID、Guard sprite sheet 和 Bank ASSERT。
- 负向故障注入：错误精灵、错误坐标、跨门房文字指针、错误东门房对话、丢失 Sprite 数量、重新引入 TEST-NNN 版本字符串。

所有 PASS 均为源码静态审计，不是 RGBDS 链接、ROM 实测或手机实测。

## 必须由用户本机完成

1. 重新编译 Red、Blue 与 `BATTLE_TEST_BUILD`。
2. 确认三种构建的游戏内版本显示都为 `REF-5.62.304`；确认测试专用行为仍只存在于测试构建。
3. 检查最新 MAP：ROM0 ≥64B，并核对 Bank `$51`、`$53`。
4. ID23：从 Route38 进入西门房，找到警员，面对警员按 A，核对完整西门房文本；离开再进入。
5. ID62：从 Route42 进入东门房，找到警员，面对警员按 A，核对完整东门房文本；离开再进入。
6. 在两座门房之间往返，确认 NPC 与对话不会串台；同时回归原门毯步行／骑车通行与 Warp。

## 未包含

- 其余 6 座普通门房 NPC。
- ID104／105 公园门房比赛日／非比赛日对象、捕虫大会参赛者和事件回调。
- ROM 编译、链接、最新 MAP 生成、Git Commit／Push。
