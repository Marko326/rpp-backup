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
