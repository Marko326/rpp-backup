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
