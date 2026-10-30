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
