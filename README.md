## CLEAN-267｜联合洞窟与33号道路用户反馈收口（不改变游戏行为）

- 用户从手机实测反馈：联合洞窟南北口进出和朝向正常；从南口进入 Route33 已不再花屏；骑自行车与 Fly 可用。上述均为用户报告，不代表助手编译或逐项测试全部地图边界。
- 仍需单独确认用户提及但尚未描述完整的“出去的时候……”后续问题；不将本次清理扩大为新地图连接、剧情或未开放出口的验收。
- 本次清理只更新源码库文档及提交准备材料，不改 ROM 运行脚本、测试版号或保存格式。正式版本保持 `FIX-5.62.267`。
- 图形**只提交 PNG 源资源**：`gfx/tilesets/johto_modern.png` 由 Makefile 的 `%.2bpp: %.png` 自动生成 `johto_modern.2bpp` 供 `INCBIN` 使用；生成物符合现有 `.gitignore` 的 `*.2bpp` 忽略规则，不得为补齐累计补丁擅自纳入 Git。
- 用户实际工作区 `home/overworld.asm` 已将相关越界风险跳转 `jr nz,.noCollision` 改为 `jp nz,.noCollision` 并完成本机运行确认；清理阶段必须原样保留，不以旧窗口的 `jr` 覆盖。

## FIX-5.62.267｜33号道路图块集加载溢出修复（开发候选）

- 症状：联合洞窟南出口进入 Route33 后整屏花屏；并非 Gold 33号路 `.blk`、PNG 或落点写反。
- 根因：`engine/overworld/tileset_header.asm` 原先以8位移位/加法拼出 `tileset * 12`，`JOHTO_MODERN=32` 时中间进位丢失，实际 `$0080` 而非 `$0180`；读取到错误的 ROM Bank/图块指针。`color/loadpalettes.asm` 又以8位 `sla e`×3 求 `tileset * 8`，ID32 时 `$0000` 而非 `$0100`。**旧回归检查没有把新 Tileset ID 32 送过这两段运行时地址计算。**
- 修复：仅将两处索引改用16位 HL 算术，保留 `.266` 地图资源、Gold碰撞、双向 Warp 和 `.265` 朝向。无新 Bank、新 SRAM、无大范围图形替换。
- 防回归：新增 `tools/tileset_index_preflight_267.py`、`tools/tests/test_tileset_index_267.py`，检查 ID 0–32 及故障注入；注意该检查不模拟 ROM VRAM，不能代替手机验收。
- 交付：增量严格从 `.266` 实际开发候选生成，累计全量从 `.266` 原来声明的干净 HEAD `438046a6ae6a709b656b8f712eeeecefc6259dda` 生成，两份互斥；不编译 ROM、不提交 Git、不更新 `TEST-231`。须由用户本机编译并检查新 MAP／南北口和 Route33 显示。

## MAP-5.62.266｜联合洞窟南出口与33号道路（开发候选）

Gold Union Cave 1F 南 Warp `(17,31)` ↔ Route33 `(11,9)` 已按独立 `JOHTO_MODERN` 资源登记。Route33 采用原版 Gold 10x9 地图、完整现代图块与逐坐标碰撞，不扩大全局道路通行白名单；洞穴进入时保留方向，返回道路自动南移一格。Route33 西侧桧皮镇、32号路南北接壤、洞穴 B1F/B2F、人物与遭遇仍保持关闭。正式编译和手机验收待用户完成。

## FIX-5.62.265｜联合洞穴进洞朝向回归修复（待实机验收）

- 32号道路向北进入1F后，保留引擎现有 UP 朝向，不自动步进，不再强制设置 DOWN。
- 洞内仅在 `(17,3)` 玩家主动朝下碰撞时才出洞；回到32号道路后依旧自动南移一格。
- 保留 `.264` 的 `ExtraWarpCheck`／Carry／`wd736` 出洞前置修复；纠正原有静态审计对错误朝向的要求并增加负例。
- 未开放 Route33、B1F/B2F；不修改其他门房、骑车、Surf 或关都行为。开发补丁待用户本机编译及手机验收。

## FIX-5.62.264｜联合洞穴出洞前置检查漏登记（待实机复测）

用户 FIX-263 视频确认人物在 Union Cave 1F (17,3) 尝试出洞仍失败。根因不在 Gold 方向/落点，而是 `home/overworld.asm::ExtraWarpCheck` 先询问 ROMX `JohtoPilotGateExteriorCollisionAllowed`，该函数漏掉 Union Cave；因此永远不进入已正确登记的 `JohtoPilotGateCollisionExitAllowed`。本版仅在前置判定按洞穴稳定 ID 转交已存在的最终坐标/方向检查，避免复制两套规则；新增针对执行路径、Carry 交接及负向测试的审计。出洞应站 (17,3) 朝 DOWN 碰撞，洞内不自动下移；32号路回程仍自动至 (6,80)。不改地下楼梯/Route33。静态通过不表示本机已出洞；未自行编译 ROM。详见 `docs/JOHTO_UNION_CAVE_EXIT_PREFLIGHT_264.md`。

## FIX-263R｜工作区补丁兼容性修正（2026-10-30）

修复首次 `.263` 补丁应用失败的交付问题：用户实际 `FIX-5.62.262.patch` 是
从 `438046a6...` Git HEAD 导出的完整工作区差异，而此前增量取自本地
旧 `.262` 快照。两者仅在 `engine/johto_pilot_runtime.asm` 的31号路门房
分支有四条 `jr` / `jp` 指令差异，旧补丁因此在833行拒绝应用。
本次保留用户 `jp` 长跳转，仅修洞穴1F碰撞 Warp/到达步进和骑车。
补丁针对真实用户 `.262` 工作区重建；先撤销未完整应用的旧 `.263`，
再使用本包的增量。文件权限与原 Git HEAD 相符，绝不忽略补丁失败继续玩。

## FIX-5.62.263｜联合洞穴北口方向回归修复与自行车许可（待实机验收）

以已交付 `.262` 工程为增量基线，严格按 Gold 和 NPC-5.62.243 参考纠正 Union Cave 1F：
Gold 洞内 `(17,3)` 是 `WARP_CARPET_DOWN`，南侧 `(17,4)` 是墙，**不是 DOOR**。
进洞停在 `(17,3)`，不模拟一步撞墙；站在该格**朝下碰撞**才出洞。
出洞落到 Route32 `(6,79)` 后，仍向南自动一步至安全 `(6,80)`。
洞内 `JOHTO_UNION_CAVE` 图块集允许自行车（已对照旧分支），不改变普通房屋／门房权限。
B1F、B2F、通往 Route33 的南口继续未开放。新增 `johto_union_cave_portal_audit.py`
自动核对 Gold 碰撞、入洞无自动步、出洞 DOWN 碰撞、来回 Warp、骑车及失败注入。
测试只是静态检查；仍需用户编译 Red/Blue 并实机检验进出、碰壁、骑行与 Save/Continue。
详见 `docs/JOHTO_UNION_CAVE_PORTAL_BIKE_263.md`。

## FIX-5.62.262｜ROM0 空间保护：城都 Surf 分派外迁（待本机重新链接）

用户 `rgblink` 报 `Unable to place "Home Clear Sprites" (ROM0 section) anywhere`。
已对照交接包旧 NPC-5.62.243：旧分支 ROM0 余468字节、当前旧 MAP 只余31字节。
本批借鉴旧分支把城都地形判定迁到 ROMX 的方案，只把 `CollisionCheckOnWater`
里的逐图水域分派迁到现有 Bank `$48`，ROM0 保留单次远调用、关都和岸线判断。
碰撞表仍留 ROM0，没有移动 ClearSprites、中断、菜单或改存档。
新增 ROM0 源码预算审计与独立新 MAP 检查：
`python tools/johto_rom0_space_preflight.py --root . --require-fresh-map`。
旧 MAP 无法证明这轮已链接；必须由用户本机构建验收。
详见 `docs/JOHTO_ROM0_BUDGET_REFERENCE_262.md`。

## FIX-5.62.261｜联合洞穴音乐表空间 ASSERT 热修复（待本机编译）

修复 CAV-260 首次将 Union Cave 1F 纳入活动槽位时遗漏 `JohtoActiveGSCMusic` 第14项、导致 `engine/menu/options_menu.asm:1232` 汇编 ASSERT 失败的问题。Gold 原版 1F 使用 `MUSIC_UNION_CAVE`，对应本工程 `MUSIC_GBP_GSC_UNION_CAVE`。原有 ASSERT 保留；独立的 `johto_table_assert_preflight.py` 已合并进 `tools/` 并接入总迁移审计，无需再单独安装上一份工具 ZIP。测试版仍为 `TEST-231`；未自行编译 ROM，详见 `docs/JOHTO_TABLE_ASSERT_PREFLIGHT_261.md`。

## UNION-260｜联合洞穴1F首批可玩候选（待本机验证）

从用户最新完整 `MUS-5.62.259.zip` 接入 Route32 ⇄ Union Cave 1F 的唯一双向洞口，洞内使用独立图块、碰撞、64格 Gold 水域和方向限定的自动离门一步。B1F/B2F、Route33、NPC与遭遇仍关闭。正式开发标记 `CAV-5.62.260`，`TEST-231` 保持。静态审计不等于构建或手机验收；详情见 `docs/JOHTO_UNION_CAVE_1F_260.md`。

## MUS-5.62.259｜城都门房音乐、骑车与北侧道路正式验收

本版相对已提交 `FIX-5.62.256`，开放遗迹北门房与36号路的安全通路，按 Gold DOOR/地毯方向处理自动走一步，修正北门房地点栏为中立门房，并统一三座活动城都门房的进入侧音乐继承与 Gold GATE 骑车许可。用户报告本轮实机测试没有问题；本环境静态检查与设备验收分别记载。下一阶段预计接入联合洞穴1F，现有1F仅有 staged 地图块，不可直接当作已激活洞穴。

## MUS-259｜城都门房音乐继承＋Gold 骑车许可（待用户验收）

三座已激活城都 GATE 按真实入侧保持 RBY/GSC/RND 音乐与播放缓存，并补齐遗迹北门房骑车权限；不能骑车的 Gold INDOOR 门房不会被误放行。新增动态门房音乐／骑车静态审计和故障注入测试。详见 `docs/JOHTO_GATE_MUSIC_BIKE_259.md`。

## FIX-5.62.258｜北门房地点栏与全活动地图名称审计（开发待验）

- 修复北门房 `Route36RuinsOfAlphGate` 的 map-name sign 中立过渡判断：进门继承先前地区名称，不会弹出通用 `Johto`；离开门房进入 Route36 / RuinsOfAlphOutside 时正常显示真实地点。
- 新增 `tools/johto_map_name_sign_audit.py` 与被 Git 跟踪的 `tools/johto_map_name_sign_contracts.json`。按活动地图稳定 ID 全覆盖核对中立门房、地名弹窗、Town Map／Save/Continue 文本；漏登记新道路、漏登记门房或标签不一致会 FAIL。与迁移主审计集成，并加入故障注入测试。
- 仅源码及静态验证；不改北门房 Warp／自动行走、南门房、Field Moves 或存档布局。用户需重新编译并验证 ROM；本阶段不生成 Git 提交日志。

## ALPH-NORTH-001｜MAP-5.62.257 开发候选（待本机构建与实机测试）

- 以用户上传 `FIX-5.62.256.zip` 为唯一基线；已接入阿露福遗迹北门房（稳定 ID19，slot11）与36号路（稳定 ID16，slot12），当前13张活动地图。Gold 北门房 `DOOR` 面向上进入、向下地毯面向下进入，自动走一步仅限北门房顶端和遗迹北门真实 `DOOR` 落点。
- 保留遗迹南门房、32号路等已验收功能；36号路其他外边缘、自然公园门房、胡说树事件及未完成室内入口继续关闭。不复制旧参考分支跨 Bank 邻接或占位 NPC。
- Gold 图块精确映射、地图与 Warp 审计、方向安全测试通过；本阶段仍未编译 ROM，也无本机实测，故不制作正式 Git 提交日志。完整说明见 `docs/JOHTO_ALPH_NORTH_257_DEV.md`。

## FIX-256｜遗迹南侧通路与 Gold 方向跳崖（用户实机验收通过）

用户已反馈 FIX-5.62.256 实机测试通过：Select 不再误开 Start；遗迹跳崖恢复 Gold 坐标＋方向白名单，左／右复合转角按各自方向处理，并禁止 Gold `(9,30)` 向下落入墙体。阿露福遗迹南侧通路与横向门房也已由用户测试，未报告问题。助手未自行编译 ROM 或运行设备。

当前城都活动地图共 11 张：若叶镇、29/30/31/32 号道路、吉花市、桔梗市、向导家、31号路门房、32号路遗迹门房、阿露福遗迹外围。遗迹北门房和 Route36 仍未激活；下一阶段按 `docs/JOHTO_ALPH_NORTH_GATE_PLAN.md` 单独处理竖向门房的 DOOR 到达自动下行一步。

# Pokémon Red++ v3

> **本分支项目协作约定：**交付每轮补丁时，固定提供增量补丁、基于项目 ZIP 的全量补丁、包含两者的合集 ZIP，**并同时附上可直接使用的 Git 提交日志**。详细要求、基线确认及校验规则见 [PROJECT_DELIVERY_RULES.md](PROJECT_DELIVERY_RULES.md)。该要求跨新会话持续生效，Git Commit/Push 由项目所有者操作。

This is based on the [**Pokémon Red Disassembly**][pokered]

Red++ serves as an updated version of Pokémon Red.

It fixes a lot of bugs leftover from original Red and Blue, as well as adding new features.

# You can download IPS patch files [**here**](patches/). Apply them to a normal Red Version rom. Just apply whichever patch you want.

The source code builds two versions, a "Normal" version and a "Hard" version. The only difference is the level curve.
"pokered.gbc" is the Normal version, "pokeblue.gbc" is the Hard version. There is also the option to build either version with snowy graphics.

For a list of features, check out [**FEATURES.md**](FEATURES.md).

* To see a list of all Pokémon included, look [**here**](constants/pokemon_constants.asm).
* To see Pokémon skill sets and evolutions, look [**here**](data/evos_moves.asm).
* To see what the TMs/HMs teach, and where to find them, look [**here**](data/tms.asm).
* To see a list of Move Tutor moves, and where to find them, look [**here**](data/move_tutors.asm)
* To see Pokémon base stats, which TMs and which Move Tutors they learn, look [**here**](data/baseStats/).
* To see which Pokémon are found in the wild in each area, look [**here**](data/wildPokemon/).
* To see a list of Pokémon you can find via Headbutting trees, look [**here**](data/wildPokemon/tree_mons.asm).
* To see all the In-Game Trades and where they are found, look [**here**](data/trades.asm).



## Frequently Asked Questions

### Q: Are all Pokémon available?
A: Yes, all 208 Pokémon that are included in the game are available without needing to trade with another person.

### Q: How do you get Dive?
A: Dive is not available because the functionality hasn't been added yet. It will be in v4.

### Q: Where is the Move Deleter?
A: The house between Fuchsia City's Gym and Pokémon Center.

### Q: Where is the Move Relearner?
A: Same house as the Move Deleter.

### Q: Where do I find Shiny Pokémon?
A: The only "Event Shiny" for now is the Magikarp you buy in the Mt. Moon Pokécenter, but all other Pokémon have the same chance to be shiny as in [**Polished Crystal v2**][polished]. Also, breeding at the Daycare is slightly more likely, due to the Day Care Man's Ditto being shiny.

### Q: Is Fairy type in this?
A: Yes, Dark Steel and Fairy are all in, and type strengths/weaknesses match Gen 6.

### Q: Can I go to Johto?
A: This branch now includes a limited Johto pilot area. The current development source registers fifteen Johto pilot maps, including both Ruins of Alph gates, Route36, Union Cave 1F, and Route33. Underground cave floors, Azalea Town, the Route32/33 overworld seam, and other unfinished connections remain disabled. The cave candidate still requires a successful link and device verification.

### Q: Will you add so-and-so feature?
A: Maybe!


For help, questions, or to generally keep up with development, check out the [**Lunaverse Discord**][lunaverse].



## Setting up your own version

To set up the repository, see [**INSTALL.md**](INSTALL.md). This way you can build the latest dev version for yourself, or use it as a starting point for your own hack.
It is advisable to check the main Pokered repository as well for more info.

After setting up the repository, you'll want to download the current release of [**Polished Map**][polishedmap] by Rangi if you want to edit maps.



## See also

* [**Pokémon Polished Crystal**][polished] by Rangi.
* [**Pokémon RedStar/BlueStar**][redstarbluestar] by Rangi.
* [**Pokémon Orange**][orange] by Pia Carrot.



[polished]: http://github.com/rangi42/polishedcrystal
[polishedmap]: https://github.com/rangi42/polished-map
[redstarbluestar]: https://github.com/Rangi42/redstarbluestar
[orange]: https://github.com/PiaCarrot/pokeorange
[pokered]: https://github.com/pret/pokered
[lunaverse]: https://discord.gg/SQwkd7r
