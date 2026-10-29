# 城都 Surf 源码预检与覆盖合同

## MAP-5.62.253 当前覆盖（此前 NewBark 暂缓规则已被本轮要求取代）

- 用户本轮要求把**当前已激活的地图**中缺少的冲浪、砍树和跳崖一次性补齐。因此此前 `NewBarkTown` 东侧水域 `DEFERRED` 的范围限制不再适用；8 个 Gold WATER 已正式加入 Surf 合同。
- 当前 9 张活动地图的 Surf 覆盖：NewBarkTown 8、CherrygroveCity 142、Route30 32、Route31 44、VioletCity 140、Route32 278 格，全部 `REGISTERED`；Route29、GuideGentsHouse、Route31VioletGate 没有 Gold WATER。
- 当前 Gold Cut 共 7 棵：Route29 两棵、Route30 一棵、Route31 两棵、VioletCity 一棵、Route32 一棵；全部与地图专属坐标／原始块检查匹配。Headbutt 树不计入 Cut。
- 当前 Gold HOP 碰撞格共 78：Route29 35、Route30 21、Route31 13、VioletCity 3、Route32 6。Route32 现在使用已验证的 Route31 跳崖 tile-pair 表；其他活动地图没有 Gold HOP。
- 32 号道路底部的地图名称曾显示通用 `Johto`，根因是 `engine/overworld/map_name_sign.asm::ResolvePhysicalLandmark` 没有处理稳定地图 ID 7。本轮补入 `Route 32` 分支与名称字符串。
- 完整静态清单：`python tools/johto_field_move_coverage_audit.py --gold <Gold源码根目录>`。当前静态结果为 9 张活动地图、644 个 WATER、7 棵 CUT_TREE、78 个 HOP 碰撞格全部登记。此结果**不等于** ROM 链接或手机验收。
- 用户在 2026-10-29 报告本轮本机正式／测试红蓝构建、新 MAP 与手机回归均已通过；这属于用户验收反馈，工具本身仍只做静态审计。

---

## CHERRY-250：检查可登陆的非水图块是否被紧凑碰撞表错误阻止

工具不只对照 `WATER` 坐标，还须检查与水相邻的 Gold `FLOOR` 连通分量。当运行时图块（compact `johto.bst` + `.blk`）不在 `johto.tilecoll` 的白名单内时，判定存在无法登岸／无法继续走动的风险。若未注册精确地图／坐标例外，返回 `MISSING_SHORE_PASSABILITY`。不得把图块 `$3C` 全局放行：它也表示墙。对于新的城都水域，每次必须携带 Gold 源运行专项检查。

## 验收与提交安排（ACC-248）

用户已确认桔梗市上岸修复正常，当前 `.248` 补丁已测试无异常。本工具及 Gold 数据审计属于第三笔 `test(tool)` 提交，不得和旧存档指针刷新、地图地形运行代码混为同一笔。工具仍不自动运行 Game Boy ROM，Route32 及洞穴水面合同需以后逐图登记。

# SURF-AUD-001｜城都水域复用与交付前强制检查（工具专项，无 ROM 行为修改）

## 现成方案来源与边界

- 旧 NPC 参考工程的 `docs/JOHTO_ROUTE32_SURF_187.md`、`docs/JOHTO_SURF_RUNTIME_187.md` 记载过 `johto_route32_surf_geometry.py`、`johto_surf_runtime_audit.py` 和负向测试；**本次上传的旧参考包没有这些脚本实体**，不能声称已经直接复用了它们的文件。
- 旧分支的 `home/overworld.asm::CollisionCheckOnWater` 确实先用地图特定的 Gold 水格识别前方水面；若前方不是水，再恢复 `wTileInFrontOfPlayer` 到 `C`，走项目原有陆地通行扫描。`VIOLET-247` 复制水格思路时遗漏了这一细节，`.248` 才补齐。用户已反馈该次桔梗市无法上岸问题实机解除。
- 当前 `tools/johto_rpp_pipeline.py` 的 `onboarding` 已经计算水格并生成包含上岸的审查清单，但**不会验证运行时分支**。本工具补足这一关，不重写冲浪状态机、不替代游戏内测试。

## 交付前执行（主要供下个窗口／AI 使用）

```
python tools/johto_surf_preflight.py
python tools/johto_surf_preflight.py --gold /实际解压的pokegold根目录
python -m unittest discover -s tools/tests -p test_johto_surf_preflight.py
```

必须以用户提供的 Gold 参考资产执行 `--gold` 的逐格严格比较；没有源码时只能运行非 Gold 的代码静态检查，**不能标记源数据验收通过**。调用返回非 0 即停止生成开发补丁，不要删断言。

本工具检查：

1. `IsSurfTile`（面对水面按 A/宝可梦 Surf）、`IsNextTileShoreOrWater`（Surfboard）、`CollisionCheckOnWater`（水中持续移动／上岸）三个入口全部调用已登记的同一地图水面判断；新水面 helper 未登记即失败。
2. 只在城都共享句柄、正确地区、指定稳定地图 ID 下启用，不把共享美术图块加入全局水面白名单。
3. 从 Gold `.blk` 与原版 tilecoll 完整解码真实 WATER 坐标，并对照源码的水面坐标表（现有桔梗市 140 格）。发现漏格、多格、重复或越界立即失败。
4. 在 `CollisionCheckOnWater` 中，水面为真时继续冲浪；非水面必须先 `ld a,[wTileInFrontOfPlayer]`／`ld c,a` 再调用原来陆地可通行扫描；不因无法确认水面就直接宣告岸上可走。
5. 故障注入：删除 `ld c,a`、翻转水面分支、遗漏三个入口之一、添加未登记水面 helper、错误地图 ID、错水格等必须使审计失败。

## 下一张带河流地图如何接入

1. 先从旧项目确认相关 ASM 与当前 RPP 编号／Bank 是否兼容；优先复用三个引擎入口和现有陆地通行扫描，不另起新 Surf 状态机。
2. 使用当前 `johto_rpp_pipeline.py` 的接入审查读取 Gold 水格；明确哪些墙和水共用 8×8 图块，**禁止**把该 Johto Tileset 全局设为可冲浪／可步行。
3. 在 `tools/johto_surf_contracts.json` 登记地图名、稳定 ID、helper、源水格与尺寸；扩展审计解析器后再支持旧项目 Route32 的位图编码（现有 `yx_db` 格式之外的编码**尚未实现，不能声称支持**）。
4. 执行 Gold 严格几何比对、三个入口与上岸分支审计、负向用例、ASM 符号检查、现有地图迁移/门房/Warp 审计、补丁正反向回放。若修改了 JR、Bank、ROM0 或寄存器保存，静态检查不能代替 RGBDS 链接。
5. 用户在手机上分别验证：从各岸边入水、四向移动、靠合法岸上岸并继续行走、非法墙不出水、重新入水、冲浪音乐/切图/存读档，以及关都正常。

**限制**：本工具不是 Game Boy CPU 仿真器，不执行 ROM 链接或音频与玩家操作。它能拦截这次遗漏的代码模式，不能保证未来所有地图自动一次成功。

## 活动地图的缺失水域盘点（新增 Surf coverage audit）

`johto_surf_preflight.py` 只检查合同中**已经登记**的 helper，不能发现其他
已开放地图里尚未实现的 Gold WATER。新增只读
`tools/johto_surf_coverage_audit.py` 专门补上这一点：

```bash
python tools/johto_surf_coverage_audit.py --gold /Gold源码根目录
python tools/johto_surf_coverage_audit.py --gold /Gold源码根目录 --require-map CherrygroveCity
```

它直接读取当前活动 Source + Runtime Descriptor，而不把 `maps/johto_staged/`
中的尚未开放素材算作运行地图；用 Gold `.blk` + `*_collision.asm` 逐格计算
`WATER` 数量，并验证当前 `.gold.blk` 与 Gold 原始文件字节一致。
历史记录：旧版默认将 `NewBarkTown` 标记 `DEFERRED`；此规则已由 MAP-5.62.253 用户要求补齐所有活动地图的决定取代。
`REGISTERED` 只表示存在合格的源码合同，不代表 ROM 编译或手机实测。

2026-10-29 的 PAL-5.62.248 基线：吉花市 142、30 号路 32、31 号路 44、
32 号路 278 格 `MISSING_SURF`；桔梗市 140 格 `REGISTERED`；若叶镇
8 格 `DEFERRED`。

## CHERRY-249｜吉花市 Gold 原版水域接入（待本机编译与实测）

- 本轮只新增吉花市冲浪，若叶镇东侧 8 格按用户要求继续 `DEFERRED`；不开放联合洞穴，也不修改 Route30/31/32 的水域。
- Gold 原版 `CherrygroveCity.blk` + Johto collision 表解码得到 142 个 `WATER` 碰撞格，地图是 20×9 Blocks，即 40×18 个碰撞格。源码表 `JohtoCherrygroveGoldWaterCells` 必须与 Gold 逐格相同，且不能按共享美术 ID 全局放开。
- 新增 `JohtoCherrygroveIsActive` / `JohtoCherrygroveWaterAhead`，只在共享运行时句柄 `$FC`、Johto 区域、稳定 ID `JOHTO_CHERRYGROVE_LOCAL_ID` 下生效；复用现有 `IsSurfTile`、`IsNextTileShoreOrWater`、`CollisionCheckOnWater` 三个入口和陆地岸边通行扫描。
- 上岸的非水分支必须恢复 `wTileInFrontOfPlayer` 到 `C`，防止重现 VIOLET-247 的下水正常但无法上岸问题。工具合同、覆盖盘点和负向测试已同步增加吉花市。
- 静态合同状态 `REGISTERED` 不等于已链接或手机验收。仍需用户本机红/蓝正式与 TEST 构建、MAP 检查，并在吉花市测试面对水面使用 Surf、Surfboard、四向游泳、多个岸边上岸、上岸后行走、重新入水、存档 Continue；同时回归桔梗市与关都。

历史覆盖状态（PAL-5.62.249）：当时 NewBarkTown 被暂缓，Route30/31/32 尚未接入；当前状态以本文件开头的 MAP-5.62.253 清单为准。

交付新水域代码前，先运行覆盖盘点（目标地图必须从 `MISSING_SURF` 转为 `REGISTERED`），再运行原有 `johto_surf_preflight.py --gold`、专项负向测试与 ASM 预检；用户的 RGBDS 编译和实机上/下岸验收仍是独立关卡。
