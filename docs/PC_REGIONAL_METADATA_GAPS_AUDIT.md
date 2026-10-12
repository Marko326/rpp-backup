# Polished Crystal 地区形态元数据缺项审计（ANIM-5.62.111 WIP）

> **后续修订（2026-10）**：本文件为前一轮元数据缺项审计的历史快照，以下“24 条待核对／继承普通物种”反映的是**更新之前**的情况。最新源码已修正 18 条 Special，并对全部 42 条重新核对体型、补充 25 条独立记录。请以 `docs/REGIONAL_FORMS_111_INTEGRATION.md` 末尾「42 形态种族值总和与图鉴体型数据修订」和本轮《42_更新后逐项数值核对》为准；ROM 编译和实机仍待确认。

> 本文依据当前**未提交的 PC18 迁移工作区**，不是你的手机项目实时状态；仅静态查源码，尚无 RGBDS 链接或实机验收。

## 关键结论

1. **肯泰罗**：官方仅有普通、斗战（Combat）、火炽（Blaze）、水澜（Aqua）四种展示项，其中后三者是三种帕底亚品种。原描述符先放 Blaze，Combat/Aqua 排在后面；项目图鉴形态切换按**描述符物理顺序**遍历，不能只交换 EQU 的文字。修订仅移动描述符，把顺序变为 Combat → Blaze → Aqua，原 ID/存档 marker 原封不动。
2. **独立身高体重**：现有 `RF_DESC_DEX_METRICS_BANK`、`RF_DESC_DEX_METRICS_PTR` 和 `PokedexData_CopyHeightWeightFields` 可以覆盖单个形态的身高、体重；值为 0 表示继承普通物种。基线里 27 条新形态全部为 `db 0; dw 0`，并未做独立测量数据。此次仅据官方数据补全三种肯泰罗的体重：斗战 115 kg／253.5 lb，火炽 85 kg／187.4 lb，水澜 110 kg／242.5 lb，身高 1.4 m 与普通相同，继续继承。**其余 24 条新形态仍需逐项核对**，不能笼统视为与普通形态相同。
3. **普通肯泰罗现有资料也有 0.1 lb 差值**：项目 `data/pokedex_entries.asm` 的 `TaurosDexEntry` 是 `db 4,7 / dw 1950`（4′07″、195.0 lb），与官方的 194.9 lb 相差 0.1 lb。本次专注地区形态，**暂不擅自修改普通物种图鉴数据**，后续可以统一修订。
4. **图鉴分类、长说明**：`PokedexData_GetCategoryPointer` / `PokedexData_GetDescriptionPointer` 目前故意共用普通物种文本，形态描述符里**没有**独立分类/长图鉴说明指针。这是引擎功能缺口，不是只添文本就会显示。
5. **专有外观名称**：图鉴形态切换逻辑按描述符顺序提供图片和参数，但没有三种肯泰罗品种名的专有描述符字段；浏览顺序正确也不代表屏幕已显示“斗战种/火炽种/水澜种”文字。
6. **战斗数据仍占位**：本轮 18 条的 Special 由来源双特殊能力折算；捕获率、经验、成长、TM/导师、部分升级和进化没有完整还原。此前 9 条也标记为占位。不能仅凭独立头数据存在就宣称所有数值正式化。
7. **特殊变体不等于地区形态**：参考项目 `variant_forms.asm` 除 42 条地区形态，还有异色暴鲤龙、装甲超梦、三节土龙节节、血月月月熊四条其他独立变体，上一版“42 地区形态+7 专属进化”报告没逐项展示；应另列候选，不纳入这次 18 地区形态的移植数。

## 全部 42 条已登记地区形态的独立身高体重状况

| 物种 | Form | 批次 | 指标状态 |
|---|---|---|---|
| `RATTATA` | `ALOLA` | 原有阿罗拉 | 专用身高/体重记录 |
| `RATICATE` | `ALOLA` | 原有阿罗拉 | 专用身高/体重记录 |
| `VULPIX` | `ALOLA` | 原有阿罗拉 | 继承普通物种 |
| `NINETALES` | `ALOLA` | 原有阿罗拉 | 继承普通物种 |
| `RAICHU` | `ALOLA` | 原有阿罗拉 | 专用身高/体重记录 |
| `SANDSHREW` | `ALOLA` | 原有阿罗拉 | 专用身高/体重记录 |
| `SANDSLASH` | `ALOLA` | 原有阿罗拉 | 专用身高/体重记录 |
| `DIGLETT` | `ALOLA` | 原有阿罗拉 | 专用身高/体重记录 |
| `DUGTRIO` | `ALOLA` | 原有阿罗拉 | 专用身高/体重记录 |
| `GEODUDE` | `ALOLA` | 原有阿罗拉 | 专用身高/体重记录 |
| `GRAVELER` | `ALOLA` | 原有阿罗拉 | 专用身高/体重记录 |
| `GOLEM` | `ALOLA` | 原有阿罗拉 | 专用身高/体重记录 |
| `GRIMER` | `ALOLA` | 原有阿罗拉 | 专用身高/体重记录 |
| `MUK` | `ALOLA` | 原有阿罗拉 | 专用身高/体重记录 |
| `MAROWAK` | `ALOLA` | 原有阿罗拉 | 专用身高/体重记录 |
| `GROWLITHE` | `HISUI` | 上一批9种 | 继承普通物种 |
| `ARCANINE` | `HISUI` | 上一批9种 | 继承普通物种 |
| `VOLTORB` | `HISUI` | 上一批9种 | 继承普通物种 |
| `ELECTRODE` | `HISUI` | 上一批9种 | 继承普通物种 |
| `ZIGZAGOON` | `GALAR` | 上一批9种 | 继承普通物种 |
| `LINOONE` | `GALAR` | 上一批9种 | 继承普通物种 |
| `WEEZING` | `GALAR` | 上一批9种 | 继承普通物种 |
| `SLOWKING` | `GALAR` | 上一批9种 | 继承普通物种 |
| `MEOWTH` | `ALOLA` | PC追加18项 | 继承普通物种 |
| `PERSIAN` | `ALOLA` | PC追加18项 | 继承普通物种 |
| `EXEGGUTOR` | `ALOLA` | PC追加18项 | 继承普通物种 |
| `MEOWTH` | `GALAR` | PC追加18项 | 继承普通物种 |
| `PONYTA` | `GALAR` | PC追加18项 | 继承普通物种 |
| `RAPIDASH` | `GALAR` | PC追加18项 | 继承普通物种 |
| `SLOWPOKE` | `GALAR` | PC追加18项 | 继承普通物种 |
| `SLOWBRO` | `GALAR` | PC追加18项 | 继承普通物种 |
| `FARFETCHD` | `GALAR` | PC追加18项 | 继承普通物种 |
| `MR_MIME` | `GALAR` | PC追加18项 | 继承普通物种 |
| `ARTICUNO` | `GALAR` | PC追加18项 | 继承普通物种 |
| `ZAPDOS` | `GALAR` | PC追加18项 | 继承普通物种 |
| `MOLTRES` | `GALAR` | PC追加18项 | 继承普通物种 |
| `SNEASEL` | `HISUI` | PC追加18项 | 继承普通物种 |
| `TAUROS` | `PALDEA_COMBAT` | PC追加18项 | 专用身高/体重记录 |
| `TAUROS` | `PALDEA_BLAZE` | 上一批9种 | 专用身高/体重记录 |
| `TAUROS` | `PALDEA_AQUA` | PC追加18项 | 专用身高/体重记录 |
| `PERSIAN` | `GALAR` | PC追加18项 | 继承普通物种 |
| `WEAVILE` | `HISUI` | PC追加18项 | 继承普通物种 |


### 还没填的数据类别与后续动作

| 数据项目 | 当前引擎/迁移现状 | 处理建议 |
|---|---|---|
| 独立身高、体重 | 已有读取机制；此前 27 条新形态全继承普通物种，本次三条肯泰罗已补 | 另外 24 条逐只查官方指标，与普通一致才使用继承 |
| 独立图鉴类别、专用文字介绍 | 引擎明确复用普通物种，描述符无字段 | 未来需要扩展 ROM 银行指针／UI，不能仅新增文本 |
| 品种/形态名称文字 | 无独立文字名称字段 | 后续决定是否显示品种名，需另加数据/绘制 |
| 地区形态 ID、存档标记 | 已独立，Tauros 3 种各有 marker | **不得为了排序重编号**，保护旧存档 |
| 正背图、图形 Bank、配色 | 42 条均有独立头/指针，新增 18 项首帧转换，异色调色板未验证 | 编译链接+实机校验宽高、调色板、资源顺序 |
| 种族值/属性/捕获/基础经验/成长 | 头数据独立，但 9+18 仍有占位值 | 统一核对官方值并决定单 Special 适配规则 |
| 升级招式/进化/TM/导师 | 表存在，部分招式在当前工程不可用，部分映射为本项目自定义进化 | 重做合法表并实测升级、进化、存档 |
| 野生分布与获得 | 旧 9 项有部分遭遇槽，PC 新 18 项未新增 | 统一设计地点、时段、概率，确认普通/地区形态共存 |
| 图鉴专用描述/分支进化图鉴编号 | 当前 Species 级；Perrserker/Sneasler 使用自定义已有 Species 映射 | 若需参考项目完整表现，要明确拓展范围 |
| 全部图形、ROM bank 和存档 | RGBDS 链接和模拟器未完成 | Red/Blue `make map`、存读档、战斗及图鉴切换验收 |

## 参考项目被上一轮地区形态口径排除的四种变体

- `GYARADOS + GYARADOS_RED_FORM`（单独变体，**不是新的地区形态**）
- `MEWTWO + MEWTWO_ARMORED_FORM`（单独变体，**不是新的地区形态**）
- `DUDUNSPARCE + DUDUNSPARCE_THREE_SEGMENT_FORM`（单独变体，**不是新的地区形态**）
- `URSALUNA + URSALUNA_BLOODMOON_FORM`（单独变体，**不是新的地区形态**）


**非地区变体的目标基础物种核对：**

| 参考项目变体 | ANIM 基础物种 | 本轮处理 |
|---|---|---|
| 红色暴鲤龙 `GYARADOS_RED_FORM` | 存在 `GYARADOS` | 另行检查异色／外观机制，未迁移 |
| 装甲超梦 `MEWTWO_ARMORED_FORM` | 存在 `MEWTWO` | 需独立外观机制，未迁移 |
| 三节土龙节节 `DUDUNSPARCE_THREE_SEGMENT_FORM` | 未登记 `DUDUNSPARCE` | 先补物种，未迁移 |
| 血月月月熊 `URSALUNA_BLOODMOON_FORM` | 未登记 `URSALUNA` | 先补物种，未迁移 |

这些是参考项目独立变体，不属于此前 42 条地区形态，不能直接计入“漏移植的地区形态”。此外，参考项目的普通纯外观型（如未知图腾或鲤鱼王花纹）还有单独表格，不在此 42+4 的核查范围。

## 来源与验证边界

- 主项目：`constants/pokemon_constants.asm`，`data/regional_forms.asm`，`data/regional_forms_pc_batch.asm`，`data/regional_forms_expansion.asm`，`engine/regional_forms.asm`，`engine/menu/pokedex_info.asm`。
- 来源项目：上传的 `polishedcrystal-master.zip` → `data/pokemon/variant_forms.asm`、`data/pokemon/dex_entries.asm`。
- 官方肯泰罗体重：Pokémon 官方图鉴 [斗战](https://sg.portal-pokemon.com/pokedex/0128_1/)、[火炽](https://ph.portal-pokemon.com/pokedex/0128_2/)；水澜按 [Serebii](https://www.serebii.net/pokedex-sv/tauros/) 独立核对。
- 本次仅静态代码/单元文件验证；无 `rgbasm` 时不能声明完整 ROM 链接通过。
