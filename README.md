# Pokémon Red++ v3

> **RPP 金银地图开发必读**：新增或修改门房之前，先读 [门房专用防重犯清单](docs/JOHTO_GATEHOUSE_READ_FIRST.md)；入口合同由 `tools/johto_door_onboarding_audit.py` 强制检查。项目总规范见实际 ZIP 的 `RPP_PROJECT_CONTEXT/03_PROJECT_REQUIREMENTS.txt`（自动导出资料可能不入 Git）。

> **城都东西双线固定编号（必读）**：游戏源码 `constants/region_map_constants.asm` 已 `INCLUDE "constants/johto_fixed_map_ids.asm"`，在源码中预留 ID `21～221`，既有 `0～20` 不改。编号／Gold 对照／归属清单：`tools/johto_fixed_ids.csv`、`tools/johto_gold_map_reference.csv`；实施规范：`docs/JOHTO_FIXED_IDS_AND_BRANCH_POLICY_zh.md`。A/B 不得改公用编号文件；激活任何地图前执行 `make johto-id-preflight`，构建前也有自动门禁。**预留 ≠ 地图上线；高 ID 目前仍不能跳号启用。**

This is based the [**Pokémon Red Disassembly**][pokered]

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
A: There is only Kanto for now. Johto is part of the ongoing copy of v4 in the main repo.

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
