# ANIM-5.62.111 地区形态接入说明（占位数据，未验收）

这次不是只保存图片。当前运行路径：精确野生槽位 → RegionalFormStageWildEncounter → 新增 Form ID/marker → RegionalFormDescriptors（匹配 Species + Form）→ 独立 BaseStats（含 `.pic` 第一字节尺寸、图指针、图片 bank）→ battle / Pokédex / party / PC 的既有引擎。形态随 catch-rate marker 存储并由现有存读档体系识别。

## 9 套已登记形态（资料均为临时占位）

- 洗翠 Growlithe / Arcanine：火／岩石。洗翠 Growlithe 火之石 Lv30 → 洗翠 Arcanine。
- 洗翠 Voltorb / Electrode：电／草。洗翠 Voltorb Lv30 → 洗翠 Electrode。
- 伽勒尔 Zigzagoon / Linoone：恶／一般。伽勒尔 Zigzagoon Lv20 → 伽勒尔 Linoone。当前项目不包含 Obstagoon，不添加不存在的进化。
- 伽勒尔 Weezing：毒／妖精。
- 伽勒尔 Slowking：毒／超能力。
- 帕底亚 Tauros Blaze：格斗／火。

## 资源和数据边界

**本轮九种新增地区形态的全部游戏数据均为占位，后续须统一修改。** 当前表中的属性、数值、捕获率／经验／成长曲线、升级招式、进化、TM／导师、调色板、图鉴资料与野外槽位只是可供框架引用的暂定内容，不代表原作或最终平衡已核定。普通物种中的 9 个 `*_CATCH_RATE` 是保持原值的常量别名，仅用于现有 `regional_form_guard` 防冲突检查；不能据此把新形态的捕获率标记为定稿。

- `pic/bmon/*_{hisui,galar,paldea_blaze}.png` / `pic/monback/*...b.png` 为之前提交的独立原图，没有覆盖或重复编辑。`data/regional_forms_expansion.asm` 现直接 `INCBIN` 对应 `.pic` 压缩产物，头数据引用地址和 BANK，构建脚本依赖规则从 PNG 生成 `.pic`。
- 形态独立基本属性保留当前项目的既有种族值作为适配起点，除洗翠风速狗、伽勒尔呆呆王和帕底亚火炽种肯泰罗的地域能力分配外，不宣称完整复刻旧项目的未附源码数值；属性更正为对应形态。每种形态采用当前主线已有的合法升级招式生成独立升级表，尚未复刻旧版的全部地区专属技能。TM/HM、导师、经验类型直接继承当前对应物种，防止无效编号和 ABI 改动。
- 每种形态都有独立前／后战斗图、普通／异色调色板；异色调色板尚未经实机确认。
- 8 个新增野生配置（肯泰罗位于狩猎地带西区而非东区）沿用原槽位的等级、物种与概率，所有未显式配置的槽位保持普通形态。野生槽位种类／难度差异已静态检查。
- 阿罗拉 15 种、普通图、其他动画、存档格式和公共形态引擎未修改。

## 仍需项目构建、实机验证和后续数据统一修订

- 此批为源码引用完整接入后的未提交工作区版本，正式提交仍需用户确认。**未编译 ROM、未链接或执行模拟器，因此没有实测证明 ROM bank 余量、颜色及捕获／存储路径已验收。**
- 需要检查普通／困难 ROM bank 容量，九种野生遇敌、捕获、PC 存取、存读档、升级进化、图鉴切换、异色表现。全部九种形态的现行参数和野外槽位须在后续统一核定；完整地区专属招式、独立图鉴资料和 Obstagoon 需单独迭代。

## ROM bank $34 / $30 map-guided correction (pending build)

- Start from the **reverted ANIM-5.62.110 source**, then apply this patch as an ordinary working-tree change. No release commit has been created.
- Baseline `patches/rppred.map` places `Slot Machine Tiles 2` and form engine/data in packed ROMX bank #52 (`$34`), with just `$0037` free. The name in the linker error was the last section that did not fit; its graphics were not defective.
- Relocate only existing bank-aware sections to `$30`: type-effectiveness ($274), slot tiles ($180), Poké Flute ($68), Route20 classifier + Pokédex location selector ($DA). Their original entry points are accessed through `callab`, `callba` or `BANK(label)` and their internal direct accesses remain in the same moved section. All related graphics bytes and algorithms stay unchanged.
- Expansion descriptors, full headers, learnsets, evolution streams and palettes remain together in bank `$34` because the regional engine reads 16-bit in-bank data pointers; the 18 sprite resources remain in their separate graphics section with explicit `BANK(...)` references.
- Estimated old-map occupancy: 55 free + 1334 moved out - 808 new data/descriptor = **581 bytes projected in `$34`**. Bank `$30` starts with `$2bab` slack and would retain `$2875` after placing those old sections. These are **static projections**, not an updated linker map.
- `regional_form_guard` requires nine regular-species `*_CATCH_RATE` definitions; they have now been added without changing ordinary catch rates, but no subsequent successful RGBASM/linker result is available. RGBDS 0.5.2 (`.rgbds-version`) is required for real proof. Run `make map` from the project root, inspect both `patches/rppred.map` and `patches/rppblue.map`, and then test game scenes. In this workspace `make tools` passed but `make map` stopped at `rgbasm: No such file or directory`; **no ROM compilation or emulation result is claimed**.

---

## Polished Crystal 18 项追加移植：地区形态与进化链全量审计

# Polished Crystal → ANIM 地区形态/独立进化 全量审计（42 + 7）

## 审计口径和移植边界

- 基准是之前的 **ANIM-5.62.111 未提交工作区**，不是用户手机上可能更新过的 Git HEAD；原有 15 阿罗拉 + 9 占位形态均计入“已有”。新文件是普通源码补丁，不代表已经通过 ROM 链接。
- 参考项目 `data/pokemon/variant_forms.asm` 有 42 条**地区形态**；不包括外观型异色暴鲤龙、装甲超梦、血月月月熊等非本轮地区形态。下面逐条核对有无基础物种和有无对应描述符。
- 本轮在 **不新增 Species 编号** 的前提下登记 16 条缺失地区形态，另外将参考项目的 2 个独立进化物种映射为已有 Species 的形态，总数 **18**；无法复用的 5 个独立进化物种、缺基础物种的 4 条地区形态继续留档，不强行塞进现有进化链。
- 图片保留 Polished Crystal 的正面**首帧**（裁切为单张方图）及对应背面；不移植动画多帧数据。当前 18 条战斗参数仍为占位：捕获率与经验产出继承 ANIM 普通物种，旧项目的六维能力折成 ANIM 单一 Special，升级招式仅保留当前项目合法的招式，TM 学习范围沿用普通物种。**后续统一重制**，不据此宣称还原官方数值。
- 对存在地区专属进化的形态：引擎现有规则会在目标物种登记了相同 Form 的情况下继承形态。本轮 `MEOWTH + GALAR → PERSIAN + GALAR` 读取参考项目喵头目图；`SNEASEL + HISUI → WEAVILE + HISUI` 读取参考项目大狃拉图。它们都是本项目自定义映射，非官方 Species 关系。没有实现独立的新图鉴编号、原名或独立物种生态。
- `PALDEA_COMBAT` 与 `PALDEA_AQUA` 独立于之前的 `PALDEA_BLAZE`，不得互相覆盖。新形态本轮没有编造野生配置，获取渠道仍待设计与实机检查。
- 固定 BANK `$34` 的描述符继续在 `$34` 中访问数据；为容量腾挪把 `MoveDex Descriptions C` 从 `$34` 移到 `$30`（该表通过带 BANK 的跨 bank 指针访问）。这是**待链接确认**的布局变更；编译前不得宣称无容量问题。

**统计（当前工作区）：** 来源 42 个地区形态：原项目已登记 22、本轮新增 16、仍因基础物种缺失而未登记 4；另有 7 个地区专属独立进化物种，其中 2 个本轮做自定义映射，5 个不纳入。

## Ⅰ. 参考项目全部 42 个地区形态

| 来源基础 Species | 目标 ANIM Species | 地区形态 | ANIM 基础物种 | 结果 |
|---|---|---|---|---|
| `RATTATA` | `RATTATA` | `ALOLA` | 存在 | 原项目已登记 |
| `RATICATE` | `RATICATE` | `ALOLA` | 存在 | 原项目已登记 |
| `RAICHU` | `RAICHU` | `ALOLA` | 存在 | 原项目已登记 |
| `SANDSHREW` | `SANDSHREW` | `ALOLA` | 存在 | 原项目已登记 |
| `SANDSLASH` | `SANDSLASH` | `ALOLA` | 存在 | 原项目已登记 |
| `VULPIX` | `VULPIX` | `ALOLA` | 存在 | 原项目已登记 |
| `NINETALES` | `NINETALES` | `ALOLA` | 存在 | 原项目已登记 |
| `DIGLETT` | `DIGLETT` | `ALOLA` | 存在 | 原项目已登记 |
| `DUGTRIO` | `DUGTRIO` | `ALOLA` | 存在 | 原项目已登记 |
| `MEOWTH` | `MEOWTH` | `ALOLA` | 存在 | 本轮新增，未编译验收 |
| `PERSIAN` | `PERSIAN` | `ALOLA` | 存在 | 本轮新增，未编译验收 |
| `GEODUDE` | `GEODUDE` | `ALOLA` | 存在 | 原项目已登记 |
| `GRAVELER` | `GRAVELER` | `ALOLA` | 存在 | 原项目已登记 |
| `GOLEM` | `GOLEM` | `ALOLA` | 存在 | 原项目已登记 |
| `GRIMER` | `GRIMER` | `ALOLA` | 存在 | 原项目已登记 |
| `MUK` | `MUK` | `ALOLA` | 存在 | 原项目已登记 |
| `EXEGGUTOR` | `EXEGGUTOR` | `ALOLA` | 存在 | 本轮新增，未编译验收 |
| `MAROWAK` | `MAROWAK` | `ALOLA` | 存在 | 原项目已登记 |
| `MEOWTH` | `MEOWTH` | `GALAR` | 存在 | 本轮新增，未编译验收 |
| `PONYTA` | `PONYTA` | `GALAR` | 存在 | 本轮新增，未编译验收 |
| `RAPIDASH` | `RAPIDASH` | `GALAR` | 存在 | 本轮新增，未编译验收 |
| `SLOWPOKE` | `SLOWPOKE` | `GALAR` | 存在 | 本轮新增，未编译验收 |
| `SLOWBRO` | `SLOWBRO` | `GALAR` | 存在 | 本轮新增，未编译验收 |
| `FARFETCH_D` | `FARFETCHD` | `GALAR` | 存在 | 本轮新增，未编译验收 |
| `WEEZING` | `WEEZING` | `GALAR` | 存在 | 原项目已登记 |
| `MR__MIME` | `MR_MIME` | `GALAR` | 存在 | 本轮新增，未编译验收 |
| `ARTICUNO` | `ARTICUNO` | `GALAR` | 存在 | 本轮新增，未编译验收 |
| `ZAPDOS` | `ZAPDOS` | `GALAR` | 存在 | 本轮新增，未编译验收 |
| `MOLTRES` | `MOLTRES` | `GALAR` | 存在 | 本轮新增，未编译验收 |
| `SLOWKING` | `SLOWKING` | `GALAR` | 存在 | 原项目已登记 |
| `CORSOLA` | `CORSOLA` | `GALAR` | **不存在** | 缺基础物种（无法直接登记） |
| `GROWLITHE` | `GROWLITHE` | `HISUI` | 存在 | 原项目已登记 |
| `ARCANINE` | `ARCANINE` | `HISUI` | 存在 | 原项目已登记 |
| `VOLTORB` | `VOLTORB` | `HISUI` | 存在 | 原项目已登记 |
| `ELECTRODE` | `ELECTRODE` | `HISUI` | 存在 | 原项目已登记 |
| `TYPHLOSION` | `TYPHLOSION` | `HISUI` | **不存在** | 缺基础物种（无法直接登记） |
| `QWILFISH` | `QWILFISH` | `HISUI` | **不存在** | 缺基础物种（无法直接登记） |
| `SNEASEL` | `SNEASEL` | `HISUI` | 存在 | 本轮新增，未编译验收 |
| `WOOPER` | `WOOPER` | `PALDEA` | **不存在** | 缺基础物种（无法直接登记） |
| `TAUROS` | `TAUROS` | `PALDEA_COMBAT` | 存在 | 本轮新增，未编译验收 |
| `TAUROS` | `TAUROS` | `PALDEA_BLAZE` | 存在 | 原项目已登记 |
| `TAUROS` | `TAUROS` | `PALDEA_AQUA` | 存在 | 本轮新增，未编译验收 |

## Ⅱ. 参考项目地区专属独立进化物种：全部 7 种

| 参考项目独立物种 | 来源形态基础物种 | ANIM 是否有基础 | 复用已有进化型 | 处理结果 |
|---|---|---|---|---|
| `PERRSERKER` | `MEOWTH` | 是 | `PERSIAN` | 本轮映射到 PERSIAN + GALAR（自定义） |
| `SNEASLER` | `SNEASEL` | 是 | `WEAVILE` | 本轮映射到 WEAVILE + HISUI（自定义） |
| `SIRFETCH_D` | `FARFETCHD` | 是 | 无 | 缺进化槽位；本轮不纳入 |
| `MR__RIME` | `MR_MIME` | 是 | 无 | 缺进化槽位；本轮不纳入 |
| `CURSOLA` | `CORSOLA` | **否** | 无 | 缺基础物种和进化槽位；不纳入 |
| `OVERQWIL` | `QWILFISH` | **否** | 无 | 缺基础物种和进化槽位；不纳入 |
| `CLODSIRE` | `WOOPER` | **否** | 无 | 缺基础物种与普通进化型；不纳入 |

## Ⅲ. 反向核对：ANIM 工作区里已有但参考项目地区形态表没有的条目

- `ZIGZAGOON + FORM_GALAR`：ANIM 已有，参考项目的地区形态表无同名记录（可能是当前项目自定义 / 标签不同），不删除。
- `LINOONE + FORM_GALAR`：ANIM 已有，参考项目的地区形态表无同名记录（可能是当前项目自定义 / 标签不同），不删除。
- `PERSIAN + FORM_GALAR`：ANIM 已有，参考项目的地区形态表无同名记录（可能是当前项目自定义 / 标签不同），不删除。
- `WEAVILE + FORM_HISUI`：ANIM 已有，参考项目的地区形态表无同名记录（可能是当前项目自定义 / 标签不同），不删除。

## Ⅳ. 必须后续完成的工作

- [ ] 全部新增形态（包括之前 9 种）的**属性、种族值、捕获/经验、成长曲线、TM/HM/导师、专属招式、进化条件、异色调色板、图鉴参数、野外分布与获得方式**统一核对、修订，不把占位数值标为定稿。
- [ ] 决定是否增加缺基础物种：`CORSOLA`、`TYPHLOSION`、`QWILFISH`、`WOOPER`；原项目没有它们的普通物种，因此无法仅凭地区形态图独立运行。
- [ ] 决定是否增加无可复用进化槽位的 `SIRFETCH_D`、`MR__RIME`、`CURSOLA`、`OVERQWIL`、`CLODSIRE`；目前只在报告记档。
- [ ] 用 RGBDS 0.5.2 完整执行 Red/Blue `make map`，核对 `$34/$30` 和每个浮动图块 section 的容量；再跑战斗、进化、捕捉、PC 存取、图鉴、异色等场景。
- [ ] 等测试完成后再做项目要求的清理补丁、TODO 和提交日志三件套；本轮不提交、不推送。


## 地区形态身高体重/图鉴字段审计（追加）

见 `docs/PC_REGIONAL_METADATA_GAPS_AUDIT.md`。此文件已按官方顺序整理帕底亚 Tauros 斗战→火炽→水澜并补其独立体重；这项说明是修订前的历史记录；本轮已按下方 42 条 Special 与体型专项完成更新，图鉴分类/长说明仍继承普通 Species。此前 9+18 的玩法数据仍为占位，尚未编译实机验收。


## ANIM-5.62.111 42 形态种族值总和与图鉴体型数据修订（WIP）


- 范围：当前项目全部 42 条地区形态描述符；依据本项目普通物种五项及地区形态现有 HP／攻击／防御／速度计算 `Special = 普通物种五项之和 - 地区形态其余四项`。不是直接照搬后世六维总和。
- 已计算并写入 18 条需要调整的 `Special`，其余 24 条原本已守恒，保持不动；42 条的目标值均处于 1～255。
- 体型按公开图鉴公制参考值转换成项目的 `英尺,英寸` 以及 `0.1 磅`，新增 25 组独立覆盖，原先已有的 16 组保留；仅 1 组（伽勒尔蛇纹熊）仍完全继承，因该项目内普通资料与地区资料一致。
- 身高体重和 Special 与其他占位参数严格区分：捕获率、经验、TM／导师、进化规则及遭遇分布仍需另行核对，不因此宣称已整体定稿。
- 特别映射：`PERSIAN + FORM_GALAR` 身高体重使用**喵头目**参考值，`WEAVILE + FORM_HISUI` 使用**大狃拉**参考值；普通猫老大／玛狃拉的数据未变。
- 保持 Species/Form 编号、形态描述符顺序、BANK 布局和野外配置不变；原有 13 条阿罗拉覆盖及肯泰罗三条数据保留。新增 metrics 记录都位于已有 `Regional Form Pokedex Metrics` (`BANK[$3E]`) 区段。
- 验收状态：生成补丁后重新回放并做逐项静态检查；尚未完成 RGBDS 编译、Red/Blue ROM link 和图鉴实机展示，不能据此视为验收通过。
- 尺寸参考来源：[Pokémon Database 身高体重总表](https://pokemondb.net/pokedex/stats/height-weight)；原有各形态数值基于 `ANIM_42地区形态_逐项数据.csv` 的上一轮审计。

### Special 变更逐项表

| 物种 | 地区形态 | 当前 | 目标 | 普通五项总和 |
|---|---|---:|---:|---:|
| `GROWLITHE` | `FORM_HISUI` | 65 | **45** | 280 |
| `ARCANINE` | `FORM_HISUI` | 80 | **75** | 455 |
| `SLOWKING` | `FORM_GALAR` | 110 | **120** | 390 |
| `MEOWTH` | `FORM_ALOLA` | 45 | **50** | 250 |
| `PERSIAN` | `FORM_ALOLA` | 70 | **75** | 375 |
| `EXEGGUTOR` | `FORM_ALOLA` | 100 | **125** | 455 |
| `SLOWBRO` | `FORM_GALAR` | 85 | **70** | 390 |
| `FARFETCHD` | `FORM_GALAR` | 60 | **58** | 315 |
| `MR_MIME` | `FORM_GALAR` | 90 | **60** | 340 |
| `ARTICUNO` | `FORM_GALAR` | 112 | **130** | 485 |
| `ZAPDOS` | `FORM_GALAR` | 87 | **85** | 490 |
| `MOLTRES` | `FORM_GALAR` | 112 | **140** | 495 |
| `SNEASEL` | `FORM_HISUI` | 55 | **75** | 395 |
| `TAUROS` | `FORM_PALDEA_COMBAT` | 50 | **60** | 450 |
| `TAUROS` | `FORM_PALDEA_BLAZE` | 70 | **60** | 450 |
| `TAUROS` | `FORM_PALDEA_AQUA` | 50 | **60** | 450 |
| `PERSIAN` | `FORM_GALAR` | 55 | **45** | 375 |
| `WEAVILE` | `FORM_HISUI` | 60 | **75** | 465 |

### 新增的地区形态图鉴体型覆盖

| 物种 | 地区形态 | 身高（m → 游戏） | 体重（kg → 游戏磅） |
|---|---|---|---|
| `VULPIX` | `FORM_ALOLA` | 0.6 → 2′00″ | 9.9 → 21.8 lb |
| `NINETALES` | `FORM_ALOLA` | 1.1 → 3′07″ | 19.9 → 43.9 lb |
| `GROWLITHE` | `FORM_HISUI` | 0.8 → 2′07″ | 22.7 → 50.0 lb |
| `ARCANINE` | `FORM_HISUI` | 2.0 → 6′07″ | 168.0 → 370.4 lb |
| `VOLTORB` | `FORM_HISUI` | 0.5 → 1′08″ | 13.0 → 28.7 lb |
| `ELECTRODE` | `FORM_HISUI` | 1.2 → 3′11″ | 71.0 → 156.5 lb |
| `LINOONE` | `FORM_GALAR` | 0.5 → 1′08″ | 32.5 → 71.7 lb |
| `WEEZING` | `FORM_GALAR` | 3.0 → 9′10″ | 16.0 → 35.3 lb |
| `SLOWKING` | `FORM_GALAR` | 1.8 → 5′11″ | 79.5 → 175.3 lb |
| `MEOWTH` | `FORM_ALOLA` | 0.4 → 1′04″ | 4.2 → 9.3 lb |
| `PERSIAN` | `FORM_ALOLA` | 1.1 → 3′07″ | 33.0 → 72.8 lb |
| `EXEGGUTOR` | `FORM_ALOLA` | 10.9 → 35′09″ | 415.6 → 916.2 lb |
| `MEOWTH` | `FORM_GALAR` | 0.4 → 1′04″ | 7.5 → 16.5 lb |
| `PONYTA` | `FORM_GALAR` | 0.8 → 2′07″ | 24.0 → 52.9 lb |
| `RAPIDASH` | `FORM_GALAR` | 1.7 → 5′07″ | 80.0 → 176.4 lb |
| `SLOWPOKE` | `FORM_GALAR` | 1.2 → 3′11″ | 36.0 → 79.4 lb |
| `SLOWBRO` | `FORM_GALAR` | 1.6 → 5′03″ | 70.5 → 155.4 lb |
| `FARFETCHD` | `FORM_GALAR` | 0.8 → 2′07″ | 42.0 → 92.6 lb |
| `MR_MIME` | `FORM_GALAR` | 1.4 → 4′07″ | 56.8 → 125.2 lb |
| `ARTICUNO` | `FORM_GALAR` | 1.7 → 5′07″ | 50.9 → 112.2 lb |
| `ZAPDOS` | `FORM_GALAR` | 1.6 → 5′03″ | 58.2 → 128.3 lb |
| `MOLTRES` | `FORM_GALAR` | 2.0 → 6′07″ | 66.0 → 145.5 lb |
| `SNEASEL` | `FORM_HISUI` | 0.9 → 2′11″ | 27.0 → 59.5 lb |
| `PERSIAN` | `FORM_GALAR` | 0.8 → 2′07″ | 28.0 → 61.7 lb |
| `WEAVILE` | `FORM_HISUI` | 1.3 → 4′03″ | 43.0 → 94.8 lb |

### 保留已有尺寸记录及无需另设覆盖的数据

- 原有 13 条阿罗拉身高体重记录及 3 条帕底亚肯泰罗种类体重记录保留。
- `ZIGZAGOON + FORM_GALAR` 当前完整继承普通形态，资料数值一致，不另建重复记录。
- 原来图鉴普通 Species 数据中的小幅磅数偏差未修改；六尾、九尾、阿罗拉喵喵、伽勒尔呆呆兽等通过形态专用重量覆盖单独校正显示。

## 地区形态身高体重：Polished Crystal × Bulbapedia 核对及精确继承修订（ANIM-5.62.112）

> 本节优先于上面的 5.62.111 历史体型覆盖清单。上轮“25 条新增独立覆盖／仅蛇纹熊继承”是**更新前**状态，不再作为当前计数。游戏 ASM 中的历史注释不为了改动版本而统一重写。

- **项目交付规则**：本轮只提供增量、基于用户项目 ZIP 的全量补丁和双补丁 ZIP；不提供整项目 ZIP，不编译、不提交。
- **来源区分**：Polished Crystal `data/pokemon/body_data.asm` 以 0.1 米 / 0.1 千克存 40 条对应物种/地区形态；这 40 条同项目上轮公制参考值全部一致。该参考项目没有伽勒尔蛇纹熊/伽勒尔直冲熊的对应体型条目，直接以 Bulbapedia 为准。
- **英制最终值**：查对 Bulbapedia 的 [按体重](https://bulbapedia.bulbagarden.net/wiki/List_of_Pok%C3%A9mon_by_weight) / [按身高](https://bulbapedia.bulbagarden.net/wiki/List_of_Pok%C3%A9mon_by_height) 名录，以其中显示的英尺/英寸与 0.1 磅为准，不把由米和千克推导的未核查结果当作原始英制数据。
- **共享体型去重**：`VULPIX`、`NINETALES`、`MEOWTH`（阿罗拉）、`SLOWPOKE`（伽勒尔）、`LINOONE`（伽勒尔）五对普通与地区体型完全相同；修正普通 Species 图鉴原重量（22.0→21.8、44.0→43.9、9.0→9.3、79.0→79.4、71.6→71.7 磅），地区描述符改为继承并删除冗余 5 组 4 字节的独立体型记录。伽勒尔蛇纹熊原本就继承且正确。
- **顺手校准已知问题**：普通 `TAUROS` 重量 195.0→194.9 磅（88.4 kg），地区斗战/火炽/水澜三种原本已正确，均不重改。
- **直冲熊特别说明**：Bulbapedia 记载 Linoone 在《Sword/Shield》以前曾以不正确的方式将英制 71.7 磅向下取整为 71.6 磅。如今普通与伽勒尔形态均为 **71.7 磅、32.5 千克、1′08″、0.5 米**，后者直接继承普通图鉴。
- **代码状态**：42 条地区形态保留；其中 36 条有独立图鉴记录、6 条完整继承。18 条已修正 Special 和其余形态当前五项数值一律保留不变。没有改动形态 ID、进化、野外配置、Bank 选择或普通物种战斗数据。
- **验收状态**：仅补丁回放与静态汇编符号／数据引用检查；按 `03_PROJECT_REQUIREMENTS.txt` 不编译 ROM。Red/Hard ROM 及游戏图鉴显示留给用户测试。

### 全部 42 条地区形态对照

| 物种 + Form | 来源（公制） | 身高 | 体重 | 本项目存储方式 |
|---|---|---|---|---|
| `RATTATA + FORM_ALOLA` | Polished Crystal：0.3 m / 3.8 kg | 1′00″ | 8.4 lb | 独立覆盖或按字段继承 |
| `RATICATE + FORM_ALOLA` | Polished Crystal：0.7 m / 25.5 kg | 2′04″ | 56.2 lb | 独立覆盖或按字段继承 |
| `VULPIX + FORM_ALOLA` | Polished Crystal：0.6 m / 9.9 kg | 2′00″ | 21.8 lb | 完整继承普通 Species |
| `NINETALES + FORM_ALOLA` | Polished Crystal：1.1 m / 19.9 kg | 3′07″ | 43.9 lb | 完整继承普通 Species |
| `RAICHU + FORM_ALOLA` | Polished Crystal：0.7 m / 21.0 kg | 2′04″ | 46.3 lb | 独立覆盖或按字段继承 |
| `SANDSHREW + FORM_ALOLA` | Polished Crystal：0.7 m / 40.0 kg | 2′04″ | 88.2 lb | 独立覆盖或按字段继承 |
| `SANDSLASH + FORM_ALOLA` | Polished Crystal：1.2 m / 55.0 kg | 3′11″ | 121.3 lb | 独立覆盖或按字段继承 |
| `DIGLETT + FORM_ALOLA` | Polished Crystal：0.2 m / 1.0 kg | 0′08″ | 2.2 lb | 独立覆盖或按字段继承 |
| `DUGTRIO + FORM_ALOLA` | Polished Crystal：0.7 m / 66.6 kg | 2′04″ | 146.8 lb | 独立覆盖或按字段继承 |
| `GEODUDE + FORM_ALOLA` | Polished Crystal：0.4 m / 20.3 kg | 1′04″ | 44.8 lb | 独立覆盖或按字段继承 |
| `GRAVELER + FORM_ALOLA` | Polished Crystal：1.0 m / 110.0 kg | 3′03″ | 242.5 lb | 独立覆盖或按字段继承 |
| `GOLEM + FORM_ALOLA` | Polished Crystal：1.7 m / 316.0 kg | 5′07″ | 696.7 lb | 独立覆盖或按字段继承 |
| `GRIMER + FORM_ALOLA` | Polished Crystal：0.7 m / 42.0 kg | 2′04″ | 92.6 lb | 独立覆盖或按字段继承 |
| `MUK + FORM_ALOLA` | Polished Crystal：1.0 m / 52.0 kg | 3′03″ | 114.6 lb | 独立覆盖或按字段继承 |
| `MAROWAK + FORM_ALOLA` | Polished Crystal：1.0 m / 34.0 kg | 3′03″ | 75.0 lb | 独立覆盖或按字段继承 |
| `GROWLITHE + FORM_HISUI` | Polished Crystal：0.8 m / 22.7 kg | 2′07″ | 50.0 lb | 独立覆盖或按字段继承 |
| `ARCANINE + FORM_HISUI` | Polished Crystal：2.0 m / 168.0 kg | 6′07″ | 370.4 lb | 独立覆盖或按字段继承 |
| `VOLTORB + FORM_HISUI` | Polished Crystal：0.5 m / 13.0 kg | 1′08″ | 28.7 lb | 独立覆盖或按字段继承 |
| `ELECTRODE + FORM_HISUI` | Polished Crystal：1.2 m / 71.0 kg | 3′11″ | 156.5 lb | 独立覆盖或按字段继承 |
| `ZIGZAGOON + FORM_GALAR` | Bulbapedia（参考项目无此形态）：0.4 m / 17.5 kg | 1′04″ | 38.6 lb | 完整继承普通 Species |
| `LINOONE + FORM_GALAR` | Bulbapedia（参考项目无此形态）：0.5 m / 32.5 kg | 1′08″ | 71.7 lb | 完整继承普通 Species |
| `WEEZING + FORM_GALAR` | Polished Crystal：3.0 m / 16.0 kg | 9′10″ | 35.3 lb | 独立覆盖或按字段继承 |
| `SLOWKING + FORM_GALAR` | Polished Crystal：1.8 m / 79.5 kg | 5′11″ | 175.3 lb | 独立覆盖或按字段继承 |
| `MEOWTH + FORM_ALOLA` | Polished Crystal：0.4 m / 4.2 kg | 1′04″ | 9.3 lb | 完整继承普通 Species |
| `PERSIAN + FORM_ALOLA` | Polished Crystal：1.1 m / 33.0 kg | 3′07″ | 72.8 lb | 独立覆盖或按字段继承 |
| `EXEGGUTOR + FORM_ALOLA` | Polished Crystal：10.9 m / 415.6 kg | 35′09″ | 916.2 lb | 独立覆盖或按字段继承 |
| `MEOWTH + FORM_GALAR` | Polished Crystal：0.4 m / 7.5 kg | 1′04″ | 16.5 lb | 独立覆盖或按字段继承 |
| `PONYTA + FORM_GALAR` | Polished Crystal：0.8 m / 24.0 kg | 2′07″ | 52.9 lb | 独立覆盖或按字段继承 |
| `RAPIDASH + FORM_GALAR` | Polished Crystal：1.7 m / 80.0 kg | 5′07″ | 176.4 lb | 独立覆盖或按字段继承 |
| `SLOWPOKE + FORM_GALAR` | Polished Crystal：1.2 m / 36.0 kg | 3′11″ | 79.4 lb | 完整继承普通 Species |
| `SLOWBRO + FORM_GALAR` | Polished Crystal：1.6 m / 70.5 kg | 5′03″ | 155.4 lb | 独立覆盖或按字段继承 |
| `FARFETCHD + FORM_GALAR` | Polished Crystal：0.8 m / 42.0 kg | 2′07″ | 92.6 lb | 独立覆盖或按字段继承 |
| `MR_MIME + FORM_GALAR` | Polished Crystal：1.4 m / 56.8 kg | 4′07″ | 125.2 lb | 独立覆盖或按字段继承 |
| `ARTICUNO + FORM_GALAR` | Polished Crystal：1.7 m / 50.9 kg | 5′07″ | 112.2 lb | 独立覆盖或按字段继承 |
| `ZAPDOS + FORM_GALAR` | Polished Crystal：1.6 m / 58.2 kg | 5′03″ | 128.3 lb | 独立覆盖或按字段继承 |
| `MOLTRES + FORM_GALAR` | Polished Crystal：2.0 m / 66.0 kg | 6′07″ | 145.5 lb | 独立覆盖或按字段继承 |
| `SNEASEL + FORM_HISUI` | Polished Crystal：0.9 m / 27.0 kg | 2′11″ | 59.5 lb | 独立覆盖或按字段继承 |
| `TAUROS + FORM_PALDEA_COMBAT` | Polished Crystal：1.4 m / 115.0 kg | 4′07″ | 253.5 lb | 独立覆盖或按字段继承 |
| `TAUROS + FORM_PALDEA_BLAZE` | Polished Crystal：1.4 m / 85.0 kg | 4′07″ | 187.4 lb | 独立覆盖或按字段继承 |
| `TAUROS + FORM_PALDEA_AQUA` | Polished Crystal：1.4 m / 110.0 kg | 4′07″ | 242.5 lb | 独立覆盖或按字段继承 |
| `PERSIAN + FORM_GALAR` | Polished Crystal：0.8 m / 28.0 kg | 2′07″ | 61.7 lb | 独立覆盖或按字段继承 |
| `WEAVILE + FORM_HISUI` | Polished Crystal：1.3 m / 43.0 kg | 4′03″ | 94.8 lb | 独立覆盖或按字段继承 |

### 本轮普通物种图鉴重量修正（单位：0.1 lb）

| 普通物种 | 旧值 | Bulbapedia 精确值 | 地区形态处理 |
|---|---:|---:|---|
| `VulpixDexEntry` | 22.0 lb | **21.8 lb** | 对应相同体型的地区形态继承 |
| `NinetalesDexEntry` | 44.0 lb | **43.9 lb** | 对应相同体型的地区形态继承 |
| `MeowthDexEntry` | 9.0 lb | **9.3 lb** | 对应相同体型的地区形态继承 |
| `SlowpokeDexEntry` | 79.0 lb | **79.4 lb** | 对应相同体型的地区形态继承 |
| `LinooneDexEntry` | 71.6 lb | **71.7 lb** | 对应相同体型的地区形态继承 |
| `TaurosDexEntry` | 195.0 lb | **194.9 lb** | 三种帕底亚肯泰罗独立重量不变 |


## ANIM-5.62.112 工作区正式收口审计（仅对应本次补丁）

- 审计边界：基于用户提供的 `ANIM-5.62.112_地区形态数据.patch`，以已提交 `00e8568f`（`ANIM-5.62.111`）为基线回放；不将 Polished Crystal 其他缺失物种或特殊变体并入此轮。
- 42 条 `Species + Form` 已登记；其中原有阿罗拉 15 条、前批九条、PC18 追加 18 条。18 条 Special 已按普通物种五项种族值总和重算，另外 24 条已有相同总和；不更动其它四项。
- 对照 Polished Crystal `data/pokemon/body_data.asm` 的 40 条实际形态／专属进化对应数据，身高、体重与本次项目记录完全相符；该来源不含伽勒尔蛇纹熊、直冲熊，它们使用 Bulbapedia 记录作为对照。对喵头目／大狃拉分别使用本项目伽勒尔猫老大／洗翠玛狃拉的自定义进化映射。
- **数据相同即继承**：阿罗拉六尾、阿罗拉九尾、伽勒尔蛇纹熊、伽勒尔直冲熊、阿罗拉喵喵、伽勒尔呆呆兽六条的身高体重完全继承。其余 36 条有地区体型记录；记录中的 `db 0,0` 或 `dw 0` 分别仅继承普通物种身高或体重，只有确有差异的字段写独立英尺／英寸或 0.1 磅值。对本补丁全部 42 条记录检查，没有重复存储与普通字段相同的体型值，也没有数据显示值与审计参考表不一致。
- 前述六条普通物种图鉴体重校正（六尾、九尾、喵喵、呆呆兽、直冲熊、肯泰罗）保留，避免英制体重精度引起普通／地区形态虚假差异；特别是普通与伽勒尔直冲熊均为 71.7 lb。
- 原文中的“其他数据均为占位”现在专指**尚未定稿的玩法相关数据**，不能把已核对的 Special 总和／体型又当作未设数据，也不能反过来宣称捕获率、招式、进化与遭遇已经正式平衡。
- 验证范围：原始工作区补丁基于已提交基线回放；清理增量与完整补丁分别作正反向及文件模式检查，源码级体型指针、常量与总和作静态审计。依项目规定本次**不编译 ROM**，不宣称 `$34`／`$3E` 已通过链接或图鉴／存读档已通过实机测试。
