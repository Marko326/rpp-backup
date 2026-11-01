**CLEAN-306 最新验收说明**：REF-306 用户实机视频已证实圆朱东西门房红色警员在柜台南侧面朝上按 A 可分别触发不同对话，两人保留为正式 NPC；REF-304 的北侧对话站位、REF-305 的 `$00` 柜台取样均是历史错误，以 `docs/JOHTO_GATEHOUSE_COUNTER_TALK_FIX_306.md` 的 `$0E` 和最终清理结论为准。其余八座门房 NPC 仍待恢复。
> **REF-306 纠错（优先适用）**：本文件 REF-305 所说柜台实际采样 tile `$00` 错误。玩家面朝上时读取的是左下 tile `$0E`；修复已在 REF-306 完成。以下 REF-305 记录仅供追溯，不再作为当前验收依据。

# REF-305｜圆朱东西门房警员隔柜台对话与 Gold 红色配色修复

## Gold 原版依据

- `Route38EcruteakGate.asm` 与 `Route42EcruteakGate.asm` 各有一个 `SPRITE_OFFICER` 对象，坐标 `(5,2)`，`SPRITEMOVEDATA_STANDING_DOWN`，调色板 `PAL_NPC_RED`。
- 两张地图的警员脚本都是 `jumptextfaceplayer`，不需要剧情旗标、scene script 或 callback。
- Gold 的日间 `PAL_NPC_RED` RGB 为 `(27,31,27)`、`(31,19,10)`、`(31,7,1)`、`(0,0,0)`；RPP `PAL_OW_RED` 日间调色板逐项一致。
- RPP `gfx/sprites/guard.png` 与 Gold `gfx/sprites/officer.png` 的 16×96 灰度像素一致；新对象复用 GuardSprite 图像，但使用独立 sprite ID 和红色调色板。

## 隔柜台交互坐标

- 警员：`(5,2)`，初始朝下。
- 柜台：`(5,3)`，仍为阻挡格，实际 `wTileMap` tile ID 是 `$00`。
- 玩家站位：`(5,4)`，可通行；玩家面朝 UP。
- `GetTileAndCoordsInFrontOfPlayer` 读取 `(5,3)` 的实际 tile ID `$00`。
- `JohtoGate` tileset 将 `$00` 登记到 `wTilesetTalkingOverTiles` 第一槽；原版 `IsSpriteOrSignInFrontOfPlayer` 因而把查找范围设为 `$20`（32px），匹配与玩家相隔 32px 的警员。
- 找到警员后，原版代码设置 sprite face-player 标志；`jumptextfaceplayer` 的对话由各自地图本地 TextPointers 分派。
- 不把 block ID 3 错当成 tile ID；talk-over 表读取的是当前前方 8×8 `wTileMap` tile ID `$00`。

## 颜色与 sprite ID

- 不直接把全局 `SPRITE_GUARD` 改成红色，因为关都现有 NPC 使用该 ID 并依赖蓝色。
- 新增 `SPRITE_JOHTO_OFFICER = $64`，sprite sheet 指向 `GuardSprite`，palette assignment 指向 `PAL_OW_RED`。
- `$63` 位于 `SPRITE_BALL` 之后，原 loader 默认会将该范围按 4-tile 静态对象处理；`engine/overworld/map_sprites.asm` 为 `SPRITE_JOHTO_OFFICER` 添加例外，使其按普通 12-tile 双帧人物加载。
- ID23 与 ID62 继续保留各自独立的对象表和对话，不共享剧情指针。

## 验证范围

- `tools/johto_gatehouse_npc_pilot_305.py` 计算 runtime block map 中 `(5,3)` 的实际 tile ID，检查南侧站位、counter talk-over 32px 路径、sprite sheet、palette assignment 和 map-local dialogue。
- 故障注入覆盖：错误柜台 tile、错误玩家站位、全局 Guard 被误改红、Johto Officer 误用蓝色、错误 sprite sheet、$63 被误分类成 4-tile 对象、错误 facing／坐标／text ID／跨门房文本指针。
- 以上是源码和资源静态审计，不等同于 RGBDS 链接或设备实测。

## 用户实机验收

1. 编译 REF-305 Red／Blue／battle-test，确认游戏内统一显示 `REF-305`。
2. ID23：站在 `(5,4)` 面朝 UP，按 A；警员应隔着柜台回应并转向玩家，显示 Gold 西门房对话。
3. ID62：重复同一站位和操作，显示 Gold 东门房独立对话。
4. 两门房警员应呈 Gold 原版红色；关都其他 `SPRITE_GUARD` 保持原蓝色。
5. 离开重进和东西门房互换后，对话不串台。
6. 检查最新 MAP 的 ROM0 至少 64B 和 Bank `$51`／`$53` 余量。
