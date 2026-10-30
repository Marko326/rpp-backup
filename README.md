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
A: This branch now includes a limited Johto pilot area. Only the eleven maps listed in the current Johto migration records are enabled. The Ruins of Alph south exterior and its horizontal Route32 gate are active; the north gate, Route36, Union Cave, Route 33, and Azalea Town remain disabled.

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
