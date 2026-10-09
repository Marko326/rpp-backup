# Todo List

This file is the working roadmap for the current RPP branch.
Implementation details, ABI/bank constraints, test history, and handoff notes belong in the current handoff document; this file tracks what is finished, what is next, and what remains from the original upstream wishlist.
Reusable development failures and prevention rules are kept in `RPP_DEVELOPMENT_PITFALLS.md`; read it before changing related engine paths.

Status legend:

- `[x]` implemented / already present; **runtime test is confirmed only when the entry explicitly says so**
- `[~]` imported but still awaiting runtime validation, or partially present / pending audit
- `[ ]` not imported / not implemented / planned
- `[?]` undecided, or the task needs a more precise definition

## 分类任务看板（从 HUR-5.62.32 开始逐补丁维护）

> 用途：以后新窗口先看这里，就能按**类型 + 状态 + 顺序**判断哪些已移植、哪些还没改。下面的 `Current RPP Roadmap` 和 `Legacy Upstream Wishlist` 保留原来的详细背景；旧条目的 `[x]` 仅表示原文所述功能已存在，不自动代表本次用户实机测试过。
>
> **固定流程：一次只处理一条补丁 → 静态审查 → 用户运行测试 → 单独交付该补丁的验收 TODO 和提交日志 → 用户确认并提交 → 再单独交付下一项功能。** **不得把上一项验收与下一项功能补丁打包交付。** 分类用于查找，合并仍按①～⑩执行，不能按分类随意调整依赖顺序。
>
> 当前情况：**①～⑩已依照用户反馈完成本轮移植与验收；⑩最终保留 `VTC-5.62.51`（原始移植 `c0cf8a93`，从 `SUB-5.62.42` 进入伏特攻击动画专项），保留5×5／6×6／7×7动态目标中心、第一道中心释放、中间三道全屏横扫、第五道中心收束以及双方镜像高度。用户提供51版与52版对比视频，认为延长首尾停顿改善不明显，明确选择51版并确认已撤销52版；52版仅是临时对照，不纳入正式版本或本次补丁。⑦缩小 +2 回避仍保持，Stomp／Body Slam 反制另列长期待办；⑧电推麻痹概率等少见边界未逐项确认；⑤部分数据项目仍只有静态核对。低血量 `Danger` 报警后最后命中音效异常已由用户指出，可能影响多个技能，保留后续公共音效专项，本次不修复。此次仅更新 TODO 和准备提交日志，不改动画代码／版本、不编译 ROM；Git 提交由用户自行完成。**

> **动画逐次移植（第 2 次）**：以第 1 次 `ANIM-5.62.74` 高音补丁后的文件为基线，追加源提交 `b145d3e5` 的 Lovely Kiss 运动基础。源分支较早的伏特攻击 `c0cf8a93` 和旧快照同步 `0501c85b` 继续跳过；后续 Lovely Kiss 惯性/定版和 Draining Kiss **尚未应用**。此处 `[~]` 仅表示静态审查、待当前主线实测；第 1 次状态仍以用户实际验收结果为准。

### 动画类（Animation）
- [~] **`ANIM-5.62.75` — Lovely Kiss 九锚点逐帧轨迹（基础迭代）**：源 `b145d3e5`／`LK-5.62.58`；仅 `LOVELY_KISS` 普通 `$12` 动画按6帧表逐次平移既有4块爱心 OAM（X 每帧±2px，末端±3px；Y 依各节点查表）；9个原有基点、音效及原时长保持不变，通用 `$12` 不受影响。**并非运行时 Hermite 插值或视觉终版**，主线双方/连续演出待实测。
- [~] **`ANIM-5.62.74` — 高音 Hyper Voice 双环**：源 `5c2cc45e`／`HV-5.62.54`；独立金橙双环及延迟回声接入 ROMX `$38`，非全局命中效果修改。原分支录像选定，**主线合并后未实机复测**。

- [x] **① `HUR-5.62.32` / `32b5022c` — Hurricane（暴风）**：独立风柱、持续风线、Thunder 音效、双向演出和受击反馈已移植；**用户反馈已运行测试，暂未发现明显问题**（2026-10-08）。尚无逐项测试清单，不把各测试场景写成分别通过；以后若复现异常再重开。
- [x] **② `SP-5.62.33` / `2c3b12a8` — Sucker Punch 专属动画与 Dark 命中配色**：仅动画、音效与配色的独立移植；**用户反馈已运行测试，暂未发现明显问题**（2026-10-08），未提供逐场景测试清单，不推定各项均独立通过。② 提交日志已准备；是否完成 Git 提交，以用户自己的仓库为准。现代失败判定仍属于③。
- [x] **⑥ `SW-5.62.37` / `75ac4ff2` — Steel Wing（金属翼）金银版动画**：已单独移植并完成本轮用户验收（2026-10-08）。复用 Iron Tail 的 Gold/Crystal Metallic 开场，跳过铁尾 Wobble/HIT_BIG 后半段，恢复场景后接 Wing Attack 的三组 closing pairs；使用钢系配色。增加敌方出招后的竖震反馈及 BG0 顶行预清理；保留原铁尾、翅膀攻击及招式数据。**用户反馈三组建议场景均已测试、暂未发现异常**：我方金属翼演出，敌方金属翼受击竖震与顶部残影，连续使用金属翼／铁尾／翅膀攻击后的画面恢复；未提供额外的逐帧或全部边界条件验证，不扩大实测结论。⑥提交日志已准备，正式 Git 提交由用户完成。
- [x] **⑩ `VTC-5.62.51` / `c0cf8a93` — Volt Tackle 五道电流、三档动态中心及受击反馈**：在⑨ `SUB-5.62.42` 之上独立移植伏特攻击专属动画。复用 Spark 的 Thunder Wave 充电演出及 Quick Attack 速度线消失，接5道电流（每道8姿态、通常每姿态2帧）：**第一道由施放者中心向外扫出；第二～四道保持全屏交替横扫；第五道收束在对方中心**，随后显示电击爆发与受击反馈并恢复宝可梦。敌方前图按5×5／6×6／7×7尺寸选择几何中心，电流五道高度依次在88～52／88～48／88～44之间均匀分布，双方用同一高度组正序／倒序、X方向镜像；5×5／6×6／7×7的敌方中心分别为OAM `(132,52)`／`(136,48)`／`(132,44)`，我方后图使用 `(48,88)`。**用户已提供51版双方演出视频并核对起点、全屏扫线、末端收束；与52版视频比较后认为额外首尾停留效果不明显，明确选择保留51版且已撤销52版**。早期50版“全部五道中心到中心”方案已否决，49版三档中心思路保留在51实现中。原⑧反伤／麻痹和⑨替身逻辑未改；正常攻击受击反馈、Bank `$3E` 渲染器继续保留。**验收范围**：视频检查与用户选择支持本次动画方案，不代表已逐项验证所有姿态的视觉中心、地区形态、连续使用／颜色恢复、低血量声音及全部结算边界。低血量报警音效问题转后续独立专项；本次仅改 TODO，不修改动画或游戏版本，不编译 ROM。

### 战斗功能 / 结算类（Battle logic）

- [x] **③ `SP-5.62.34` / `5ca3afb3` — Sucker Punch 现代失败判定**：先手且目标选择伤害招式时方能成功；变化招式、后手、Recharge、换人及道具行为有专门失败检查；失败显示 `But it failed!`，我方进入判定前扣 PP。包含 Trainer AI 单次提前判定、Mirror Move 实际招式 ID、MoveDex 和 `$CCE0` WRAM 状态。**用户反馈已实机测试，暂未发现明显问题（2026-10-08）**；进一步代码逻辑复审未发现明确阻断问题。未提供各边界场景逐项结果；Trainer 道具/换人的全局排序仍为旧架构限制。③提交日志已准备，实际提交由用户完成。④已移植并获用户测试反馈。
- [x] **④ `PRI-5.62.35` / `ddddb20e` — 多级技能优先度及 ExtremeSpeed 区分**：源码已单独移植；**用户反馈已运行测试，暂未发现明显问题（2026-10-08），后续源码逻辑复审未发现明确阻断问题**。优先度以 `+7` 偏移编码：ExtremeSpeed `+2`、Sucker Punch/Baby-Doll Eyes/Ice Shard/Bullet Punch/Quick Attack `+1`、普通 `0`、Counter `-5`；同优先度仍按 Speed / 同速随机决定顺序。Roar、Whirlwind、Teleport、Bide 暂保持 `0`，不提前升级效果机制。未提供逐项边界测试记录，不将联机、AI 道具/换人等特殊场景标记为全部通过；旧架构中训练家道具/换人决策时序仍待以后复查。**未调整③失败判定或已验收动画，④验收提交日志已单独准备；是否 Git 提交以用户仓库为准。**
- [x] **⑦ `BSE-5.62.38` / `ff4fec55` — 伤害型能力副作用、Gen I Special 平衡**：已单独移植；**用户反馈已运行测试，其他效果暂未发现明显异常（2026-10-08），但未逐项提交所有概率、双侧、替身／击倒、能力极限等边界测试结果**。共享 Move ID 概率表统一伤害附加能力变化（10% / 20% / 30% / 命中后必定）；Metal Claw / Meteor Mash / Steel Wing / Silver Wind / AncientPower / Mind Blast 的自身能力提升及 Draco Meteor 的自身 Special 下降在目标被击倒前处理。Gen I 共用 Special 平衡及 MoveDex 说明保持本次移植内容；吐丝降速度2级、瞬间失忆提升 Special 1级、**缩小每次提升回避2级（10 PP）**。经讨论确认维持缩小 +2，不应用此前尚未验收的 `BSE-5.62.39`（+1）试验修正。⑦验收只更新 TODO，不再改游戏代码；实际提交由用户完成。
- [x] **⑧ `RCL-5.62.41` / `7ecf21ce` — 反伤比例及 Flare Blitz / Volt Tackle 状态效果**：已独立移植并按用户反馈完成本轮验收（2026-10-08），**目前所测场景未发现明显异常**。按真实 Move ID 分配反伤：Struggle 1/2，Flare Blitz／Volt Tackle／Wood Hammer 1/3，原有其他 RECOIL_EFFECT 招式保持 1/4；火推约10%烧伤、电推约10%麻痹接入普通状态副作用路径。目标直接被击倒时先结算使用者反伤，目标 HP 归零后不再附加异常状态；替身不能被附加状态穿透（源码路径已检查，边界待实测）。**用户实测记录**：己方、敌方分别使用闪焰冲锋，均观察到对方至少一次烧伤；约十余次共观察到两次烧伤，样本不足以验证精确触发率。**未逐项确认**：伏特攻击麻痹概率、各招式反伤数值、直接击倒后反伤、未命中／属性免疫、替身及双倒等特殊场景。⑧附带链接空间修复：首次构建遇到 Bank `$34` 的 `Red Bedroom PC` 无法放置，将该独立区段迁至 Bank `$3E`，入口仍通过 `BANK(OpenRedBedroomPC)` 动态选择 Bank；用户随后继续运行测试，但未报告卧室 PC 专项检查／新版 MAP 数据。⑨替身多段结算另在 SUB-5.62.42 实现，⑩电推专属动画仍未移植；本段保留⑧验收记录。
- [x] **⑨ `SUB-5.62.42` / `d41f0048` — Substitute 多段攻击与反伤结算时序**：已在⑧验收后源码上独立移植；**用户已运行测试并反馈可以继续，暂未报告明显问题（2026-10-08）**。多段攻击击破目标替身时，本次命中只作用于替身，其余段数可继续命中本体；攻击者自身替身在多段攻击期间避免每段重复切换，目标承伤与反伤结算后再恢复，反伤致使用者濒死则不重画替身。反伤继续使用⑧的比例及状态结算规则。**验收范围限制**：用户未提供双方替身、多段击破、双倒、替身状态穿透等场景的逐项结果，不将这些情况分别记为通过；源码已静态检查双方入口、跨 Bank helper 与 KO 返回路径，仍需遇到问题时再复查。本轮仅更新 TODO 和⑨提交日志，不改游戏代码／版本、不自行编译 ROM、不包含⑩。
- [ ] **缩小的后世代反制（后续独立专项，非下一版）**：以后再考虑为 Stomp（踩踏）和 Body Slam（泰山压顶）增加“目标实际使用过 Minimize 时，跳过一般命中／回避判定并使伤害×2”的特殊规则；Fly / Dig 无敌阶段和正常属性免疫仍应保留，单纯 Double Team 不触发。需单独审查双方判定、状态清除和伤害结算。**当前未实现，后续独立处理；下一项⑨也不加入。**

### 招式 / 数据类（Moves & data）

- [x] **⑤ `AUR-5.62.36` / `e630f377` — Rolling Kick → Aura Sphere（波导弹）**：源码已移植并完成本轮用户验收（2026-10-08），用户分别测试了我方/敌方使用、目标处于无敌状态时使用，以及动画结束后的画面残留，反馈**暂未发现明显问题**。招式沿用 `$1B` ID，威力80／格斗系／特殊／20 PP，使用 Swift 必中效果；Fly/Dig 无敌交互沿用当前战斗机制。特殊攻击的实机伤害数值、6处升级学习表及对高闪避目标的普通必中场景**未由用户实测**；对应招式数据、分类表和学习条目已静态核对，不将其写为运行通过。⑤提交日志已准备，正式 Git 提交由用户完成。

### 菜单 / UI 类（Menu & UI）

- [x] **`ICO-5.62.73` — Party 小图标性别主题色（用户验收）**：队伍图标在菜单加载时按玩家性别显示男红／女绿；正确读取 WRAM Bank 1 中的性别并恢复调用方 Bank，OBJ palette 0 不影响 HP 血条独立的 BG 绿／黄／红调色板。保留 38 类图标、208 只物种映射、双帧动画和普通／SELECT 换位流程；用户测试最终方案未报告问题。

- [x] **`ICO-5.62.63` — 208只宝可梦队伍小图标分类最终定稿（38类，用户确认）**：以已验收的 `ICO-5.62.62`（36类）为基线，依用户修订的208只宝可梦图鉴 XLSX 逐行确认，D/E 多列均读取，**E列的具体图标指令优先于D列旧 ✓／×**，即使某行已有 ✓，后列的新选择也必须落实；无明确更换指令的物种不擅自改。最终仅调整25只宝可梦，其他183只保持原样。新增金版原始16×32双帧 `FOX`（六尾／九尾、喵喵／猫老大、卡蒂狗／风速狗、伊布及8种进化形态，共15只）和 `HUMANSHAPE`（凯西／勇基拉／胡地3只），类别36→38；复用原有 `SHELL_GS` 给大钳蟹／巨钳蟹／化石盔／镰刀盔4只，`BALL_M` 给多边兽1只，`BLOB_GS` 给熔岩虫／熔岩蜗牛2只。化石盔／镰刀盔虽在 D 列标 ✓，仍以 E 列“二代shell”为准；菊石兽／多刺菊石兽继续使用一代 `HELIX`。保持黄版皮卡丘、一代与金版先前验收分类、动态加载引擎、正常／SELECT 换位无白闪机制、208只映射及固定列对齐。**用户最终反馈**：“都看过了，没问题，定稿吧，这是最后一版”；据此将本轮图标专项标记为定稿，后续不再以待选类别继续开新批次；不将笼统反馈夸大为每个 HP、命名／通信交换等边界逐项通过。此验收清理**仅修改 `TODO.md`**，不改图像、引擎、源码映射、Bank、文件权限或游戏版本号（仍为 `ICO-5.62.63`）；AI未编译 ROM 或执行 Git 提交。


- [x] **`ICO-5.62.62` — 第六批一代／二代队伍小图标去重与精选细分（最终36类，用户反馈后收口）**：以已验收的 `ICO-5.62.61`（34类）为基线，本版最终仅新增金版 `ODDISH`、`FISH` 两种16×32双帧模板，合计**36类**。`ODDISH` 只分配给走路草／臭臭花／霸王花／美丽花；喇叭芽家族仍用一代 `GRASS`。`FISH` 只分配给角金鱼／金鱼王／鲤鱼王；墨海马／海刺龙／刺龙王改用一代 `SNAKE`，灯笼鱼／电灯怪仍用 `WATER`。波克比、皮皮、皮可西、皮宝宝继续使用一代 `FAIRY`，正式撤销此前尝试加入的金版 `CLEFAIRY`；撤销金版 `EQUINE`，小火马／烈焰马保留一代 `QUADRUPED`。相对5.62.61仅调整**10只**宝可梦映射，其他**198只**不变。此前38类初稿、37类修订稿均已被最终36类方案取代，不作为提交内容。**核查依据**：一代 RPP 实际显示双帧与金版38张素材的对照显示 `MON/MONSTER`（两帧顺序互换）、`SNAKE/SERPENT`、`QUADRUPED/EQUINE` 两帧逐像素重复；`FAIRY/CLEFAIRY` 有一帧完全一致，另一帧相近，故不为微小差异再建类别。去重规则和检查步骤已写入根目录 `RPP_DEVELOPMENT_PITFALLS.md`，包含实际OAM镜像显示、两帧及其先后、调色板差异、已导入素材复用、208只映射与列对齐检查。**本轮验收**：用户在最终去除波克比专用妖精图标后反馈“没问题”，并要求清理提交；此处如实记载用户认可最终修订版，不夸大为每个场景都有单独录像。命名与通信交换无本版单项测试记录。**本次清理仅修改 `TODO.md` 和根目录开发踩坑文档**，不改图标素材／引擎／映射表／权限或游戏版本号（仍为 `ICO-5.62.62`）；AI未编译ROM或执行Git提交。

- [x] **`ICO-5.62.61` — 第五批队伍小图标细分类：SHELL／CATERPILLAR／MOTH／BLOB（用户测试后收口）**：在已验收 `ICO-5.62.60`（30类）上新增4种金版16×32双帧模板，合计34类、涉及14只宝可梦。保留一代 `HELIX` 给菊石兽／菊石多刺／化石盔／镰刀盔，仅将大舌贝／刺甲贝改为 `SHELL`；`CATERPILLAR` 对应绿毛虫／铁甲蛹／独角虫／铁壳蛹／毛球，`MOTH` 对应巴大蝶／末入蛾，`BLOB` 对应臭泥／臭臭泥／瓦斯弹／双弹瓦斯／百变怪。其余194只物种映射不变；不替换原有 `HELIX` 素材，不修改动态加载、无白闪换位和特殊动画引擎。四张原始素材来自用户提供的 `pokegold-master(1).zip`；新增映射遵守根目录 `RPP_DEVELOPMENT_PITFALLS.md` 的固定列对齐。**用户本轮反馈**：按本版建议完成三组测试（四类图标双帧及 HELIX／SHELL 区分、新旧六人混搭和普通／SELECT 换位、摘要／菜单返回及不同 HP 下的切帧），随后回复“都测过了”并要求按惯例验收收口，本轮未报告明显异常；此处记录用户反馈，不声称每种极端排列均有独立实测证据。**命名与通信交换没有单独报告**，不记作已通过，不要求每批素材更新重复通信专项。此次验收清理**只更新 `TODO.md`**；`data/mon_party_sprites.asm` 已满足根目录列对齐规则，208只的映射、图像、动态加载／无白闪换位引擎、Bank 和游戏版本（仍为 `ICO-5.62.61`）均不变。AI未编译ROM或执行Git提交。

- [x] **`ICO-5.62.60` — 第四批金版队伍小图标：胖丁、地鼠、水母与格斗类（用户测试后收口）**：以已验收 `ICO-5.62.59` 的26类动态加载引擎为基线，新增4类（JIGGLYPUFF、DIGLETT、JELLYFISH、FIGHTER），合计30类；覆盖16只宝可梦：Jigglypuff／Wigglytuff／Igglybuff，Diglett／Dugtrio，Tentacool／Tentacruel，以及 Mankey／Primeape／Machop／Machoke／Machamp／Hitmonlee／Hitmonchan／Hitmontop／Tyrogue。四张均取自用户提供的金版源码 `gfx/icons/`，使用原始16×32双帧素材；核对现存队伍图标 PNG 无同图可直接复用，现有宝可梦战斗立绘不作为队伍双帧图标使用。其余192只的类别不改，动态引擎、无白闪换位逻辑、已验收的旧素材均不改；`data/mon_party_sprites.asm` 新行遵守根目录 `RPP_DEVELOPMENT_PITFALLS.md` 的逗号、第二列与备注列对齐规范。**用户本轮反馈**：已按本版建议完成四组测试（新图标双帧、六只新旧混搭、普通／SELECT 换位、摘要／菜单往返及 HP 动画），用户回复“都测了”并要求按既定流程收口，未反馈明显异常；此处仅依据用户反馈，不声称提供了逐项测试录像。**通信交换和命名入口没有单独测试记录**，不能记为已独立验收；后续仅在相关路径改动或出现问题时有针对性复测。此次验收清理**仅更新 `TODO.md`**：不改映射表（已满足根目录列对齐规则）、素材、动态加载与无白闪换位引擎、Bank 或游戏版本号（仍为 `ICO-5.62.60`）；AI未编译ROM或执行Git提交。

- [x] **`ICO-5.62.59` — 第三批金版队伍图标：高辨识度模板（用户实测后收口）**：在已验收的 `ICO-5.62.58` 动态加载引擎上新增10类、覆盖24只宝可梦，总类别由16增至26，保持208只映射完整。按金版原始物种归类，三条初代御三家中 Bulbasaur／Ivysaur／Venusaur 用 BULBASAUR，Charmander／Charmeleon 用 CHARMANDER，Charizard 和 Dragonite 用 BIGMON，Squirtle／Wartortle／Blastoise 用 SQUIRTLE；另加入 GYARADOS、SNORLAX（含RPP额外的小卡比兽）、SLOWPOKE（含呆呆王）、LAPRAS（仅乘龙）、GEODUDE、POLIWAG（含蚊香蛙皇）。所有新素材均为上传金版源码的原始16×32双帧PNG，不镜像，不修改旧素材、引擎／换位映射；普通鸟／虫／鱼／四足等广覆盖模板暂缓。**用户本轮反馈**：已检查前四组（御三家、六只混搭、普通／SELECT换位、摘要及菜单返回），第五组的血量动画也已查看／测试，未报告明显异常；**通信交换明确未测试**，命名入口及其他未单独报告的细节不记为逐项通过。此次按反馈验收收口；清理仅修正 `data/mon_party_sprites.asm` 的列间排版、更新 `TODO.md` 和根目录 `RPP_DEVELOPMENT_PITFALLS.md` 的永久规则，不改任何图标映射、素材、动态引擎或游戏版本号（仍为 `ICO-5.62.59`）；AI未编译ROM或执行Git提交。

- [x] **`ICO-5.62.58` — 第二批金版队伍小图标：洛奇亚／凤王（用户测试后收口）**：沿用 `ICO-5.62.57` 已验收的动态加载引擎，为 Lugia、Ho-Oh 各增加 1 类图标（`$0E`、`$0F`），使现有图标从 14 类增至 **16 类**；使用金版原始 16×32 双帧 PNG、跨 Bank 素材指针，仅改变洛奇亚与凤王两只的图标映射。其他物种、原 14 类、无白闪的普通／SELECT 换位引擎均保持不变；两张新素材以非镜像四图块显示。**用户实测反馈**：“测过了，没什么问题”，据此完成本轮验收；反馈未逐项列出独立动画、混搭队伍、普通／快捷换位、摘要返回、命名／通信交换和黄／红 HP 帧速的逐项结果，不能写为这些边界全部分别通过。**验收清理仅更新 `TODO.md`**，不修改引擎、映射、PNG、ROM Bank 或游戏版本（仍为 `ICO-5.62.58`）；AI 不编译 ROM、不执行 Git 提交。

- [x] **`ICO-5.62.57` — 动态图标引擎换位白闪修复（用户复测收口）**：在 `ICO-5.62.56` 实机测试中，普通换位和 SELECT 快捷换位均出现旧版 `5.62.55` 没有的短暂白闪；原因为换位后重载队伍图标时关闭 LCD。最终 `5.62.57` 在换位时只交换六项“队伍位置 → VRAM 原图块槽位”的 WRAM 映射，OAM 通过映射选图，取消这两条换位路径上的 LCD 关闭与重复 VRAM 加载；首次进菜单／摘要返回仍沿原入口正确刷新图块及映射。**用户已对修复补丁复测并反馈“没问题”，本轮据此收口**；没有逐场景视频或子项测量，不将所有极端边界写成分别通过。验收清理仅改 `TODO.md`，保持 `ICO-5.62.57` 游戏版本、源码与素材不变，AI 未编译 ROM 或执行 Git 提交。

- [x] **`ICO-5.62.56` — 队伍小图标按成员动态加载框架（已并入 `ICO-5.62.57` 验收）**：借鉴 Yellow Legacy 的按队伍成员加载机制，以每物种 1 字节图标类别映射和 ROM 内 3 字节跨 Bank 素材指针替代固定 4-bit 类别槽位；队伍最多六只，每只两帧共 8 Tile，按队伍位置加载到 VRAM，而非预载所有类别。保留原 14 类与全部物种映射、双帧外观以及精灵球／螺旋特殊抖动、黄版皮卡丘绘制；原始 PNG 不改，只新增运行图集和交换圆圈素材。用户表示已测试此前要求的五组主要场景，`5.62.56` 唯一明确报告的回归是普通／快捷换位白闪，已在 `5.62.57` 修复并获复测反馈；**最终采用 `5.62.57`，不单独验收含闪白的 `5.62.56`**。当前仍只含 14 类，约 28～30 类是后续逐批规划，并非本轮已实现。

- [x] **`ICO-5.62.55` — 第一批4类队伍小图标融合（本轮用户测试后收口）**：以 `VTC-5.62.51` 为功能基线，`ICO-5.62.53` 首次导入4类、覆盖13只宝可梦：黄版 Pikachu（Pikachu／Raichu／Pichu）、金银 Staryu（Staryu／Starmie）、Ghost（Gastly／Haunter／Gengar／Misdreavus／Mismagius）、Bat（Zubat／Golbat／Crobat）；保留原10类及其余物种映射，总计14类，仍在4-bit类别上限内。沿用既有HP切帧速度，四类图标均加载16×16双帧（每帧4 Tile），继续使用现有VRAM布局空位；原10类及导入素材安置于 Bank `$38` 以缓解 Bank `$1C` 空间压力。**最终修正**：`ICO-5.62.55` 恢复皮卡丘家族按黄版原始方式水平镜像左侧图块，身体与尾巴在两帧中一同变化；Staryu／Ghost／Bat 和既有 Helix 继续采用非对称四图块绘制。`ICO-5.62.54` 的仅微调第二帧图案方案已被55版取代，**不是正式验收版本**。**已确认范围**：用户此前反馈另三类图标已测试、未见明显异常；皮卡丘家族最初有踏步感，后提供黄版和55版运行录像，对照后两帧轮廓与切换节奏相符，本轮决定收口。**未逐项报告**：红血／黄血各档速度、命名、交换、混搭队伍全部排列、连续进入／返回及残留等场景，不能写成全部实测通过。本次验收仅修改 `TODO.md`，不再改图像、OAM逻辑、Bank布局或游戏版本号（仍为 `ICO-5.62.55`）；AI未编译ROM或执行Git提交。

- [x] **队伍小图标专项分类定稿与后续维护边界（`ICO-5.62.63`）**：208只宝可梦的图标映射已按用户最终表格确定，采用10种一代原图、黄版皮卡丘及27种金版模板，合计**38类**，全部208只均有类别映射；本轮不再规划新的图标类别或改用 Yellow Legacy 的写实图标。分类判定结合两代实际双帧、帧序、OAM水平镜像与配色去重，遵守根目录 `RPP_DEVELOPMENT_PITFALLS.md` 的列对齐／去重规则。以后若出现独立缺陷可专项修复，但**不得在定稿清理中重新分配类别、重绘PNG或重构已验收引擎**。已知皮卡丘源 PNG 右半与 OAM 镜像后的屏幕呈现不同，属可选独立素材维护事项，不视为本次阻塞；命名／通信交换在本轮无单独验证记录，不得写成全部通过。

- [~] **`MENU-5.62.31` 菜单显示与返回流程**：源码已记录完成与静态检查；原 TODO 中仍有运行验证事项，不能因暴风通过而自动关闭。
- [ ] **PP 道具招式列表显示 `当前PP/最大PP`**：原 TODO 明确列为后续任务，暂不改。

### 地图 / 移动类（Overworld & traversal）

- [x] **`SRF-5.62.64` — 冲浪坐骑图像分流：皮卡丘／拉普拉斯／普通图像（用户核心场景验收）**：基于 `ICO-5.62.63` 增加会冲浪的拉普拉斯作为第三种坐骑外观：对水面交互时依次优先选择会冲浪的皮卡丘、会冲浪的拉普拉斯，否则沿用其他会冲浪宝可梦的普通图像（`SeelSprite`）；通过队伍菜单指定冲浪时保留用户实际选中的宝可梦外观，不受队伍中皮卡丘优先级覆盖。地图、队伍界面返回涉及的贴图加载共用图像选择入口，复用已有拉普拉斯地图素材，不改飞天。**用户测试反馈**：用户描述五组关键场景无异常——队伍菜单分别指定三类冲浪宝可梦时图像正确；三者都有且都能冲浪时对水面交互显示皮卡丘；皮卡丘不能冲浪、拉普拉斯能冲浪时显示拉普拉斯；皮卡丘与拉普拉斯都不能冲浪、其他宝可梦能冲浪时显示普通图像；全队没有可冲浪宝可梦时水面提示平静。以上只代表用户列出的覆盖范围，不等于所有队伍排列组合均已逐项测试。**边界**：地图切换、进入队伍／摘要界面后返回的持续图像，未获得独立明确的实机复测记录，保留出现问题时的针对性回归；没有另行测试移除队员后的图像降级等特殊状态。**WRAM／空间**：`wSurfingLaprasFlag` 复用原本未命名的 `$D7AD` 字节，未增加 WRAM 总长度；保留 `wd728` bit 2 的皮卡丘标志，不将它与其他功能 bit 混用。**验收清理只更新 `TODO.md`**，不改变已测试的汇编、素材、Bank 布局、文件权限和游戏版本字符串（仍是 `SRF-5.62.64`）；完成静态符号与补丁正反向核验，但没有编译 ROM 或代替用户执行 Git 提交。
- [x] **`ICO-5.62.73` — 飞天图标分流与性别主题色（用户验收）**：飞行地图显示所选宝可梦的 16×16 Party 图标，实际飞行动画按类别选择图像；鸟类沿用原版方向／振翅贴图，其他类别使用现有金版双帧图标。飞行地图光标、实际飞行动画与 Party 小图标统一按性别显示男红／女绿，普通地图鸟 NPC 配色不变。保留原飞行路径，不新增素材、不修改图标类别映射；用户测试最终方案未报告问题。

### 道具 / 进化类（Items & evolution）

- [x] **`EVO-5.62.27`**：进化石等级门槛提示和冰之石；沿用原 TODO 的已实现记录，本次未重新测试。
- [x] **`ITEM-5.62.28`**：队伍消耗道具连续使用；沿用原 TODO 的已实现记录，本次未重新测试。

### 形态 / 培育 / 系统类（Forms, breeding & systems）

- [x] **`FORM-5.62.13`～`FORM-5.62.25`、`BRD-5.62.26`**：沿用原 TODO 已实现记录，本次未重新测试。
- [ ] **Day Care 增设 PC、满队伍时转存到 PC**：原 TODO 的待办，暂不改。

### 修复 / 审核类（Bugfix & audit）

- [ ] **低血量 `Danger` 报警／通用命中音效异常（后续独立专项，非⑩验收修复）**：用户已观察到伏特攻击在低血量警报后**最后电击命中音效异常**，并指出其他招式也存在类似问题；其他具体技能和各触发条件尚未逐项复现。共享路径的 `WaitForSoundToFinish` 在 `Danger` 状态可能提前返回，`PlayApplyingAttackSound` 因而可能与自定义动画尾音重叠；该路径仅是待验证的源码线索，不应把所有技能或根因视为已确认。后续比较双方施放、正常／低血量、最后命中声、警报节奏及 Spark 等招式；不得直接静音警报或引入无界等待。本次保留问题，**不修改公共音频引擎、不声称已修复**。
- [ ] **Leech Seed/Toxic、OHKO/Counter、连续攻击等遗留问题**：原 TODO 的候选修复；具体范围详见下方 `Legacy bugfix candidates still worth auditing`，本次不改动。
- [~] **Mimic/Disable 与 Substitute 状态防护**：原 TODO 为部分实现/待审查，本次不更改结论。

### 长期规划 / 待决定（Backlog & design）

- [?] **TM 是否恢复消耗制**：仍待设计决定，不因本次提交改变。
- [ ] **地区扩展、天气、特性、性格、长期 UI/引擎计划等**：见下方 `Legacy Upstream Wishlist — Audited Against Current Project`，保留原始状态和细节，暂不集中修改。

## Current RPP Roadmap

### Completed

- [x] FORM-5.62.13 through FORM-5.62.25 — regional-form instance identity work: Link Trade, Hall of Fame, Transform, Capture, Trainer/Gift/NPC Trade/Evolution, random wild encounters, Starter, Fishing, Headbutt, Static Wild/Ghost Marowak, and persistent-marker compile-time guards.
- [x] BRD-5.62.26 — Day Care / Breeding producer uses the stored parent's persistent form marker and gives the baby the same registered runtime Form when supported; otherwise it explicitly falls back to `FORM_NORMAL`.

### User-tested — Independently imported battle animations

- [x] SP-5.62.33 — Sucker Punch animation-only: two purple punch passes, Dark HIT_BIG palette and new sound events, integrated without the separate modern success/failure gate. User reports testing the move without noticing obvious problems (2026-10-08); do not interpret this as confirmation of each player/enemy/repeated-use case. The ③ battle-logic patch is still pending, and the actual Git commit remains user-controlled.
- [x] HUR-5.62.32 — Hurricane: Polished Crystal wind-column renderer, five persistent high-speed streak sets, Thunder timing, bilateral animation support and normal post-hit feedback imported in isolation from Energy Ball branch `32b5022c`. The user reports having tested this move and observed no obvious problem (2026-10-08). This closes the previously pending general runtime check based on user feedback; individual player/enemy, palette/WX restoration and follow-up move/menu cases were **not separately documented as passed**. Reopen if a reproducible issue appears. Commit message prepared; actual Git commit must be made in the user's repository.

### User-tested — Battle logic

- [x] SP-5.62.34 — Sucker Punch modern failure gate from `5ca3afb3`. Source audit of turn order, damaging-move type, action intent, failure/PP flow, Mirror Move ID, AI early decision and `$CCE0` WRAM found no definite blocking issue. **User reports runtime testing without obvious problems (2026-10-08)**; individual edge cases not separately certified. Existing general Trainer item/switch priority timing is a broader architectural limitation. ③ commit message prepared; actual Git commit remains user-controlled. Does not include ④ priority tiers.

### User-tested — Priority / Battle logic

- [x] PRI-5.62.35 — Move priority tiers imported independently from `ddddb20e`: +7 offset, ExtremeSpeed +2 > priority +1 moves > normal 0 > Counter -5. Same-tier Speed/tie logic unchanged; Roar/Whirlwind/Teleport/Bide keep priority 0 pending a full action/mechanics review. **User reports runtime testing without obvious problems (2026-10-08)**; individual edge cases are not separately certified. Source review found no definite blocking issue; Trainer AI item/switch decision timing remains a broader architectural limitation. ④ acceptance log prepared; no ROM build or Git commit by assistant.

### User-tested — Steel Wing animation

- [x] SW-5.62.37 — Steel Wing Gold/Crystal animation from `75ac4ff2`; reuse Iron Tail Metallic intro, restore display and call Wing Attack closing pairs; Steel type palette; enemy-side vertical shake and BG0 top-row cleanup. **User reports all three requested test scenarios completed without obvious problems (2026-10-08): player use, enemy use including vertical shake/top-row residue, and alternating Steel Wing / Iron Tail / Wing Attack with display restoration.** No additional frame-by-frame or rare edge-case certification is implied; acceptance log prepared, no assistant ROM build or Git commit.

### User-tested — Battle stat effects

- [x] BSE-5.62.38 — damage-triggered stat side effects and Gen I Special balance from `ff4fec55`. User reports runtime testing with no obvious issues in the tested scenarios (2026-10-08); individual edge cases were not independently certified. **Minimize remains +2 evasion / 10 PP** by user balance decision; String Shot remains -2 Speed, Amnesia +1 Special. The experimental BSE-5.62.39 +1 change is **not** applied. Future, not-next-version standalone task: Stomp and Body Slam deal 2× damage and bypass ordinary accuracy/evasion against a target that used Minimize, while keeping Fly/Dig and type-immunity exceptions; not implemented here. ⑦ acceptance log prepared; no assistant ROM build or Git commit.

### User-tested — Recoil and secondary status

- [x] RCL-5.62.41 — imported `7ecf21ce` as ⑧ recoil and Flare Blitz / Volt Tackle side effects, plus isolated Bank $34 placement repair. **User reports testing Flare Blitz from both sides and observing burn once on each side without obvious problems (2026-10-08)**. Approximately two burns across a dozen-plus attempts is observational only, not an accuracy test for the roughly 10% status chance. Recoil fraction values, Volt Tackle paralysis, direct-KO and Substitute boundaries, and Red bedroom PC interaction have no separately reported complete runtime verification. The Bank move retains the dynamic `BANK(OpenRedBedroomPC)` lookup; no new MAP/ROM build was performed by the assistant. Recoil logic and game version remain unchanged during this TODO-only acceptance. Commit message prepared; actual Git commit belongs to the user.

### User-tested — Substitute / multi-hit / recoil timing

- [x] SUB-5.62.42 — imported ⑨ (`d41f0048`) after RCL-5.62.41. **User reports having tested the feature and asks to proceed (2026-10-08), without reporting obvious problems.** No itemized pass report was supplied for both-side Substitute, multi-hit break, recoil double-KO or status penetration; do not infer that every edge case was verified. Source audit covered substitute restoration, post-damage recoil timing, both actor branches, and Bank helper symbols. ⑦/⑧ acceptance status has been reconciled in the category board; Minimize remains +2, and the Stomp / Body Slam counterplay is a future standalone item. No assistant ROM build or Git commit. ⑨ acceptance message prepared; ⑩ remains unported.

### User-tested — Volt Tackle animation / dynamic impact center

- [x] VTC-5.62.51 — ⑩ Volt Tackle animation from `c0cf8a93` plus three-size target center, first sweep from user center, middle three screen-wide alternate sweeps, and fifth sweep ending at the target center. User supplied runtime videos of both actor directions and a 51-versus-52 comparison; 52 only increased dwell by six frames (~0.1 s), with little visible gain, and user reports reverting it. **51 is the selected acceptance baseline; 52 is not included.** No new ROM build or Git commit by the assistant. Low-HP hit SFX conflict remains a separate unresolved issue, possibly cross-move; not every size/form/recoil or audio edge case has an individual pass result.

### User-confirmed — Final 208-species Party icon classification (ICO-5.62.63)

- [x] ICO-5.62.63 — final user-approved Party icon classification: 38 icon classes, 208 species mappings. The user-edited 208-row XLSX supplied the decisions across D and E columns, with a specific E-column instruction overriding an older D-column checkmark/cross. Relative to the accepted 36-class ICO-5.62.62, exactly 25 species mappings were changed and 183 were preserved; new Gold FOX (15 species) and HUMANSHAPE (Abra/Kadabra/Alakazam) two-frame assets were added. Existing SHELL, BALL and BLOB templates were reused for the other seven changes, including Kabuto/Kabutops per the specific E-column SHELL instruction while Omanyte/Omastar remain HELIX. The user reported having reviewed the result with no issues and explicitly declared this the last/final icon version; close out this icon-classification project without planning more import batches. This is feedback-based acceptance, not independent per-case proof for every HP, nickname or link-trade boundary. The closeout changes **TODO.md only**, keeping source, icon art, icon engine, permissions and in-game version ICO-5.62.63 unchanged. No assistant ROM build or Git commit.

### User-tested — Gen I / Gold Party icon refinement and deduplication (sixth batch)

- [x] ICO-5.62.62 — accepted the final 36-class revision based on ICO-5.62.61 (34 classes): import only Gold ODDISH for the Oddish/Belossom family and Gold FISH for Goldeen, Seaking, Magikarp (10 species mappings changed; other 198 unchanged). Keep Gen I FAIRY for Togepi and Clefairy family; do not retain proposed CLEFAIRY. Keep Gen I QUADRUPED for Ponyta/Rapidash; do not import EQUINE. Use legacy SNAKE for Horsea/Seadra/Kingdra; retain WATER for Chinchou/Lanturn. Earlier 38-class and 37-class drafts were superseded, not part of the accepted version. A source-and-rendered two-frame comparison identified exact duplicate pairs MON/MONSTER (frames swapped), SNAKE/SERPENT and QUADRUPED/EQUINE, and one identical FAIRY/CLEFAIRY frame. The durable cross-generation duplicate-screening procedure is recorded in root RPP_DEVELOPMENT_PITFALLS.md. User reported “没问题” after the final Togepi-to-FAIRY correction and requested formal closeout; that feedback does not establish independent test results for every animation and menu edge. **Link trading and naming have no separately documented pass.** Closeout changes only TODO.md and the root pitfalls note, not sprite mappings, PNGs, icon engine, file modes or version ICO-5.62.62. No assistant ROM build or Git commit.

### User-tested — Gen I / Gold Party icon category refinement (fifth batch)

- [x] ICO-5.62.61 — accepted four Gold 16×32 two-frame Party icon classes (SHELL, CATERPILLAR, MOTH, BLOB), refining 14 of the 208 species mappings and increasing the current class count from 30 to 34. Original Gen I HELIX stays assigned to the fossil family, while Shellder/Cloyster use the distinct Gold SHELL art; Caterpillar, Moth and Blob split select species out of broader legacy groups. The user reported having tested the three requested categories of cases: the new two-frame icons and HELIX/SHELL distinction, a mixed party with normal/SELECT slot swaps, and summary/menu returns with HP animation; no visible issue was reported and the user requested routine closeout. This records user feedback rather than independent full coverage of every extreme arrangement. **Link trading and naming have no separately documented test result.** Closeout changes TODO.md only, preserves existing 104-row / 208-species icon mapping and column alignment, icon assets, dynamic engine, swap behavior and game version ICO-5.62.61. No assistant ROM compilation or Git commit.

### User-tested — Curated Gold Party icon imports (fourth batch)

- [x] ICO-5.62.60 — accepted four Gold 16×32 two-frame Party icon templates (JIGGLYPUFF, DIGLETT, JELLYFISH, FIGHTER), covering 16 mapped Pokémon; total class count increased from 26 to 30, with the other 192 Pokémon mappings unchanged. The user reported completing the four requested test groups, including new-frame appearance, six-member mixing, normal/SELECT swaps without reported flash, menu/summary returns and HP-related animation, and asked to proceed to routine closeout. This records user feedback without asserting independently supplied frame-by-frame evidence. **Link trading and naming have no separate test report.** Closeout changes TODO.md only: the source mapping already meets the durable root alignment rules, and code, PNGs, Bank layout and game version ICO-5.62.60 remain unchanged. No assistant ROM compilation or Git commit.

### User-tested — Curated Gold Party icon imports (third batch)

- [x] ICO-5.62.59 — ten additional distinct Gold two-frame Party icon classes for 24 Pokémon (26 total classes across the project), preserving the remaining 184 species mappings and the dynamic-load/no-flash swap engine. User reports testing scenarios 1–4 (starter families, mixed six-member party, normal/SELECT swaps, and summary/menu returns) and checking the HP-related animation subset of scenario 5 without an apparent issue. **Link trading was explicitly not tested**; do not imply naming and every other edge case were independently validated. Closeout changes only TODO.md, column whitespace in data/mon_party_sprites.asm, and the durable root development pitfalls note; unchanged icon IDs, art, engine and game version ICO-5.62.59. No AI ROM build or Git commit.

### User-tested — Gold legendary Party icon imports (second batch)

- [x] ICO-5.62.58 — imported separate Gold two-frame Party icons for Lugia and Ho-Oh, extending the existing dynamic-load icon table from 14 to 16 classes. Only these two species mappings changed; existing atlas, Pikachu/Gold icon assets and the 5.62.57 swap-no-flash engine remained unchanged. After applying and testing 5.62.58, the user reported “测过了，没什么问题” (tested; no obvious issues), so this batch is closed on that feedback. Individual pass reports were not supplied for both animations, party mixes, ordinary/SELECT swaps, summary returns, naming/trade or yellow/red HP animation speeds; do not imply independent full coverage. The acceptance cleanup changes **TODO.md only**, keeps game version `ICO-5.62.58`, and involves no assistant ROM build or Git commit. Later optional icon batches and PNG normalization remain separate.

### User-tested — Dynamic Party icon engine and swap regression

- [x] ICO-5.62.57 — accepted the 5.62.56 → 5.62.57 Party icon engine refactor after user runtime tests. 5.62.56 introduced one-byte icon class IDs, ROM banked pointer lookup and per-member (up to six) two-frame tile loading, retaining the existing 14 templates and special Ball/Helix/Pikachu behavior. The user stated the requested five primary test groups had been exercised and reported a visible LCD white flash on both ordinary and SELECT party swaps. 5.62.57 retains loaded tiles in VRAM and swaps six slot-to-tile mapping bytes instead of disabling LCD; after applying the fix, the user reported the tests were fine and requested closeout. This is user feedback, not independent frame-by-frame confirmation of every edge case. No Lugia/Ho-Oh/starter icons are imported yet, and the planned approximately 28–30 types remain future work. **The closeout patch changes TODO only**, leaves game version `ICO-5.62.57`, executable source, assets and layout unchanged; no assistant ROM build or Git commit.

### User-tested — Party menu icon imports (first batch)

- [x] ICO-5.62.55 — accepted first batch of four icon templates mapped to 13 Pokémon species: Yellow Pikachu for Pikachu, Raichu, Pichu; Gold/Crystal Staryu, Ghost, and Bat for the mapped species. The user reported the three non-Pikachu templates looked fine in runtime tests. Pikachu initially looked like walking in ICO-5.62.53; the interim ICO-5.62.54 frame-only adjustment was superseded. ICO-5.62.55 restores Yellow's mirrored-left-half OAM composition while keeping Staryu/Ghost/Bat/Helix asymmetric; later Yellow and 55 runtime videos were compared for both poses and animation rhythm. This acceptance is limited to the observed footage and prior feedback; low-HP speed, trade, nickname, repeated menu transitions, sprite residue and all mixed-party cases have no separately documented complete pass. **Cleanup changes TODO only**, leaves game version `ICO-5.62.55` and source/assets untouched, with no assistant ROM build or Git commit. Later batches remain undecided; all-species icon replacement is not planned.

### User-tested — Moves / animation

- [x] AUR-5.62.36 — Aura Sphere from `e630f377`; replaced Rolling Kick at ID $1B, Special Fighting 80 power, 20 PP, Swift-style hit effect, MoveDex, six level-up entries, and separate animation/SFX. **User reports having tested both sides using the move, use against an invulnerable target, and post-animation visual residue, with no obvious problems (2026-10-08).** Special damage output, level-up learnset in gameplay, and a high-evasion accuracy case were **not tested at runtime**; source data/classification/learnset entries were statically reviewed. ⑤ acceptance log prepared; no assistant ROM compilation or Git commit.

### Completed — Evolution / Items

- [x] EVO-5.62.27 — evolution-stone Party UI reads the matching evolution entry's minimum level dynamically: below the requirement it shows `LvXX+`, at/above the requirement it shows `Able`, and actual use below the requirement gives a short level-specific no-effect message. Failed selections do not play the use sound or consume the stone and return to the same Party selector. This already covers cases such as a Lv28 Pokémon whose stone evolution requires Lv30; no separate Lv28 reminder is needed.
- [x] EVO-5.62.27 — add `ICE_STONE` in the former `$1B` unused slot, make it a normal purchasable item, and migrate Alolan Vulpix from the temporary `SUN_STONE` substitute to `ICE_STONE` at level 30.

### Completed — Party Consumables

- [x] ITEM-5.62.28 — repeatable out-of-battle Party consumables stay in the Party workflow while stock remains. HP/status medicine, vitamins/Rare Candy, PP Up, Ether/Max Ether/Elixir/Max Elixir and their berry equivalents allow another valid target after success; failed field use does not consume the item or force a return to the Bag. Single-move PP items reopen the move submenu on the previously selected move, while Elixir/Max Elixir return to the Party selector. Explicit cancel, zero remaining quantity, battle medicine use, evolution-stone success, and TM/HM teaching keep their existing exit rules. Existing class-specific success/denial audio is preserved.

### Completed in source — Party Item Menu Polish

- [x] MENU-5.62.31 — use a light Party redraw on PP-move-menu cancellation and TM/HM target retry, without the repeated palette whiteout. Clear overlaid menu tiles with BG transfer paused; keep initial Bag-to-Party graphics initialization and normal Party-to-Bag restoration.
- [x] MENU-5.62.31 — place only the PP-item move window at row 6 (lower border row 11, just above the message frame at row 12); preserve the selected move on repeat use, leave success/no-effect result text visible, and reopen the move list without replaying the question. Battle and other move-selection menus are unchanged.
- [x] MENU-5.62.31 — play `SFX_HEAL_AILMENT` on successful PP Up, sharing the existing PP-restore success path; no-effect and PP-Up-at-limit choices do not consume stock or play the success sound. PP Up continues to set its one-use flag through the `wUsingPPUp` / `wd11e` shared WRAM address.
- [~] MENU-5.62.31 — source cleanup and static patch checks completed; emulator/device verification remains for menu no-flash/complete-border cleanup, text legibility, cursor and cancellation handling, TM/HM retries, and normal PP Up counts. Do not mark runtime behavior as user-tested until these checks are performed.
- [ ] MENU-5.62.31 — when using PP Up or a PP-restoring item, show the target move's current PP and maximum PP (e.g. `current/max`) in the move-selection/confirmation UI, so the actual available PP and full PP are visible.

### Planned — Day Care

- [ ] Add a usable PC inside the Day Care.
- [ ] Allow Pokémon received from the Day Care to be sent to the PC instead of being blocked solely because the party is full. Confirm the exact receive paths (baby, withdrawn deposited Pokémon, or both) when implementing.

### Future design decisions

- [?] TM consumption model — the upstream final source already leaves TMs in the Bag after successful teaching, and the current fork retains that behavior. Reconsider later whether this project should restore consumable, single-use TMs or keep infinite-use TMs.

### Legacy bugfix candidates still worth auditing

- [ ] Leech Seed / Toxic shared damage counter interaction.
- [ ] Toxic becoming normal poison after switching.
- [ ] OHKO move behavior still tied to Speed.
- [ ] Counter edge cases involving Substitute / OHKO moves.
- [ ] Partial-trapping move turn-lock behavior.
- [ ] Whirlwind / Roar behavior in trainer battles.
- [ ] Rest interaction with stat changes caused by status conditions.
- [?] Rage issues — define the exact remaining bugs before changing behavior.
- [~] Mimic / Disable random-selection behavior — some paths were modernized, others still need a focused audit.
- [ ] Multi-hit moves currently calculate damage/accuracy only for the first hit.
- [ ] Poké Ball zero-shake failure still uses the old "You missed the Pokémon!" behavior/text.
- [~] Substitute protection against status — several paths have explicit checks, but the behavior is not yet fully unified.

## Legacy Upstream Wishlist — Audited Against Current Project

This section preserves the original author's roadmap. Status markers reflect the current branch as of the BRD-5.62.26 closeout; unchecked entries are not promises that they will be implemented.

### Engine updates and New Features

- [ ] Cleanup pokered-gbc code (optimizations)
- [ ] Add support for larger tileset images, like Polished Crystal
- [ ] Add support for setting XY Flip/Palette Attributes as part of block data?
- [ ] Real-Time Clock, with Day and Night
- [ ] More modern Berry System, allowing you to plant and grow new ones instead of the Gen 2-like current system
- [ ] Expand Pokédex beyond 255 (mimic ShantyTown's "expand-dex" branch)
- [ ] Allow for more than one proper region, so Johto can happen
- [ ] Individual menu sprites for all Pokémon
- [ ] Pokégear/Pokénav equivalent
- [ ] Rematches with Trainers and Gym Leaders, no annoying phone calls
- [x] Bag has multiple pockets and more storage space
- [ ] Held items
- [ ] Special split into two stats
- [x] New available move pool, with a lot more thought put into it this time
- [ ] Weather effects in-battle
- [ ] Abilities (can enable or disable during intro)
- [ ] Natures (can enable or disable during intro)
- [x] Infinite-Use TMs — already present in the upstream final source; the current fork retains it for now, but the TM consumption model may be reconsidered later.
- [~] New Pokéball types
- [ ] Dive areas
- [ ] Battle Tower
- [ ] Battle Factory
- [ ] Battle Tent
- [ ] Pokémon World Tournement
- [~] Player customization options
- [~] Rewritten Trainer AI
- [ ] Secret Bases
- [ ] Surfing Pikachu minigame (ported from Pokeyellow)
- [ ] Ruins of Alph puzzles (waiting for PR from ShantyTown)
- [ ] Bug Catching Contest
- [x] Possibly add Forms
- [ ] Use IVs and EVs instead of DVs and Stat EXP, old DVs become a mini Personality ID
- [ ] Gain EXP on catching a Pokémon

### Bugfixes from Vanilla RB

- [ ] Leech Seed/Toxic shared damage counter
- [ ] Toxic becomes normal poison if you swap
- [ ] OHKO moves based on speed
- [x] Crits ignore stat-ups from both Pokémon
- [x] Agility negates speed-loss before boosting
- [ ] Using Counter on moves used against your Substitute
- [ ] Using Counter against OHKO moves to instakill
- [ ] Trapping moves prevent opponent doing anything
- [ ] Whirlwind and Roar do not work in trainer battles
- [ ] Rest does not undo stat changes from status afflictions you had, such as Burn
- [?] Rage issues
- [~] Mimic and Disable choosing moves at random
- [ ] Multi-hit moves deal same damage for each blow
- [ ] Make Pokéball break with zero shakes instead of "You missed the Pokémon!"
- [x] Stat-up too high making your stat roll over to ultra low values
- [~] Substitute not protecting against status
- [x] Remove badge boosts, to be more modern

### Unsorted Notes

- [ ] Pokégear/Pokénav would replace Town Map, have a VS Seeker option, a radio, etc.
- [ ] Several things in WRAM could stand to be optimized, such as event flags and map script bytes
- [ ] Hide/Show routine needs work. Probably better to redo it based on normal flags somehow, like Gen 2
- [ ] IndexToPokedex and PokedexToIndex are pointless now, and can be removed
- [ ] Remove the weird TM Name Generation routine, TM Case will work differently.
- [ ] Add even more trainer classes and cameo trainers
- [ ] Johto needs songs from Crystal, of course
- [ ] Johto should include areas that were in Polished Crystal/Christmas
- [ ] Battle Tower will be in Johto
- [ ] Pokémon World Tournement will be where Pokéathalon was in HGSS
- [ ] Battle Tent will be in Celadon
- [ ] Battle Factory will be in Johto with the Battle Tower
- [ ] Instead of CheckForHex and CheckForElectroBall, there should be one routine to calculate variable BP moves
- [ ] Once Held Items are a thing, Acrobatics needs to be variable BP, too
- [ ] Any checks for hard-coded map IDs need to also check wCurRegion when the time comes
- [~] New trainer AI will be more modular, and AI_BASIC will be at least be generically intelligent
- [ ] Pull Swimmer F data out of Beauty class list
- [ ] Consolidate Leader classes and Elite Four classes
- [ ] Maybe change Trainer DVs back to checking AI Number, instead of Trainer Class, once those are consolidated
- [ ] If Natures are disabled in intro, do not display on status screens, and use a neutral nature always
- [ ] If Abilities are disabled in intro, do not display on status screens, and use a blank ability for everyone
- [ ] EXP on catch is annoying, since a lot of variables are reused during the EXP Gain process. Will require a lot of testing.
