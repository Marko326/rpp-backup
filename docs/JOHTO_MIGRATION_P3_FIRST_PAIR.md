## P3-DOC-006 / TEST-231 — 第一批地图正式收口（用户反馈已验收）

- 收口对象为 P3-001～P3-005，最新功能源码继续 `PAL-5.62.224 / TEST-231`。用户反馈若叶镇与29号道路正常进入，轮船进出、地图连接、跳崖、人物跨图显示正常；TEST-230 飞行成功，TEST-231 普通城都 Town Map 的截图/配色得到用户明确认可。**仅记录这些反馈，不能把截图解释成红蓝、所有飞行/UI、存读档逐项复测。**
- 新城都编号只激活 0/1；原分支 Ferry/UI/ledge/sprite/Town Map palette 行为适配新地区身份，不恢复旧 Johto 编号别名。45 个地标仅用于查看，当前城都 Fly 仅安全落地已激活若叶镇。
- 29号道路四名人物仍是参考分支替代 NPC（非 Gold 正式剧情），若叶镇三个测试贴图 NPC 已清理，渡轮水手保留。Wild、宝可梦、昼夜、剧情/捕捉教学和自行车仍故意不在本阶段启用，其他城都目的地未激活。
- 没有新增测试工具或审计脚本；保留 P3 运行 ASM 和地图数据原样，仅整理项目文档。基于 HEAD `495b7dc86ff6cbed5ed80483d1e8488dcb0e70bf` 的累计补丁覆盖 TEST-227～231；清理增量基于 TEST-231 已应用工作区。项目附带 MAP 仍为旧版，正式 Red/Blue 新编译/MAP 需要用户本地重做，不由 AI 构建 ROM。
- 下一批优先：接入下一张真实城都地图时复用通用到访解锁 Fly 方案、规范 NPC/野外事件的数据来源；不要为扩大列表先激活不存在的 Header。具体非地图机制继续后置。Git Commit/Push 由用户负责。

## P3-005 / PAL-5.62.224 / TEST-231 — 城都 Town Map 原分支配色修复（待验）

- [x] 从用户提供的 `NPC-5.62.243_金银分支` 原样恢复 `JohtoTownMapPals` 与 `JohtoTownMapPalAssignments`；此前地图使用关都调色板，故 Johto 图片绿／橙／蓝不协调。现在普通地图与 Fly 共用地区选择器，加载匹配的 RGB 颜色和 64 项 tile palette ID。
- [x] 原 `SetPal_TownMap` 银行 `$1C` 的表调用接口不变，但把完整调色板加载程序及两地区颜色数据迁到扩容 `ROMX`，不继续挤占 `$1C`。关都颜色字节未修改。地图 PNG、45 地标、飞行手段、地面物理地图新编号、轮船、跳崖、NPC 都不变。
- [ ] 用户实测 TEST-230 飞行若叶镇成功；此版仅修配色，红蓝实际 ROM/MAP 和手机截图仍需验收。优先测城都普通地图／Fly 色彩，再测关都地图显示、Fly 和一次轮船。AI 不编译 ROM。
- [ ] 暂不新增其它 Fly 目标：未激活的城镇不可安全飞入。未来应一次性迁移参考分支 11 个目的地的登记与到访解锁机制，同时新增目标必须检查已激活的 stable ID / Header / Warp，不能每张地图靠临时列表开放，更不能解锁未移植地图。此事项不作为首批 2 地图提交的前置条件。
- [ ] 城都自行车白名单尚未开放，本轮不扩围。暂不涉及野生遭遇、宝可梦、昼夜或剧情。
- 本轮开发补丁增量 TEST-230→231、全量 Git 导出 HEAD `495b7dc86ff6cbed5ed80483d1e8488dcb0e70bf`→231 互斥使用。若用户验收色彩 OK，应开始首批地图正式清理三件套，不再加新功能。

## P3-004 / PAL-5.62.223 / TEST-230 — 城都地图浏览与若叶镇飞行（开发待验）

- [x] 读取旧 NPC-5.62.243 的 Gold 45 个城都地标表与名称，放入扩容 ROMX；普通城都 Town Map 可遍历全部地标，无需将其错误映射成活动地图 ID。
- [x] 保留若叶镇=稳定 local ID 0、29 号道路=稳定 local ID 1 的玩家位置；只给已开放的若叶镇开放 Fly 目标，Fly 选择与物理地图身份分离，使用 Fly-only `$FD`，不采用旧城都地图编号。
- [x] 复用现有 Johto 地图图形、Kanto Fly 用户图标及 Fly 动画交接；关都 Fly 选择逻辑不变。金版其它地点可看地图，但未开放 Fly／Warp。
- [x] 不修改 NPC/剧情、野生遇敌、宝可梦、昼夜及骑行规则；29 号道路的替代 NPC 保持原样，留待后续正式 NPC 批次。
- [ ] 用户须编译正式红蓝和对应 MAP；验证城都地图 45 个地点上下翻页、若叶镇/29 号道路玩家标记、Kanto 地图未改、持有飞行宝可梦且有徽章时从29号道路飞回若叶镇，并确认存读档/渡轮不回归。AI 未编译、未在手机实测。
- [ ] 本版仅开发补丁（增量 TEST-229→230；全量 Git HEAD `495b7dc8`→230），不生成正式清理三件套、不 Commit/Push。

# P3-003 / PAL-5.62.222 / TEST-229 — Johto outdoor NPC tile cache repair (pending user test)

- Development increment based on **P3-002 / TEST-228** (not the clean Git HEAD). Full patch remains based on confirmed `495b7dc86ff6cbed5ed80483d1e8488dcb0e70bf` P2 HEAD. Apply exactly one patch.
- Restores the reference branch's `FLY-5.62.144` outdoor NPC sprite-set strategy, but triggers on current Johto tileset `JOHTO_PILOT` (28), **not** old map numbers `$E7/$F4`: both current active new local IDs 0/1 share sprite set $0b across seamless east/west connection. No old Johto map IDs or aliases are re-enabled. Kanto sprite sets / old map numbering remain unchanged.
- `SpriteSets` appends the exact 11-sprite outdoor set from the reference (last two are four-tile items). The engine's existing `wSpriteSetID` cache and `wFontLoaded` forced reload remain unchanged. The current two maps' people sprite IDs are covered by the set; unlike the prior per-map indoor-style dynamic loading, the same outdoor VRAM layout is retained on both connected maps.
- **Temporary sprite diagnostics**: remove the three `GAMBLER/BUG_CATCHER/LASS` visual test NPCs in New Bark. Keep ferry sailor and all ferry warp coordinates and logic exactly as P3-002. Route 29 still uses reference's Gen 1 visual stand-ins at Gold NPC coordinates; these are not final Gold sprites/scripts; don't describe them as Gold-faithful NPCs. Text for future town NPCs is retained as non-reachable placeholder until real Gold art/events are migrated.
- Bike availability has **not** been newly enabled by this patch (`BikeRidingTilesets` is unchanged). Do not claim cycling boundary tested until a later separate enablement/verification. No changes to event scripts, ledges, sprite graphics files or Gold source data.
- No AI ROM compile/link and no phone test performed. User should build Red and Blue, check newly generated MAP for bank $05 and ROM0 free space, and re-enter New Bark→Route 29→New Bark several times on foot, including NPC facing animation, ferry, save/Continue; compare ordinary Kanto outside sprites. If biking was already externally enabled, additionally repeat the transition on bike. If the MAP/link or VRAM display fails, stop and return the exact error and screenshot.

---

# P3-001 / PAL-5.62.220 / TEST-227 — 首批若叶镇、29 号道路运行候选（待用户验收）

## 准确基线

- 用户提供的 2026-10-27 主项目 ZIP 是 **干净 HEAD `495b7dc86ff6cbed5ed80483d1e8488dcb0e70bf`**，`PAL-5.62.219 / TEST-226`；本轮不从旧 P1/P2 补丁重新开始。
- 原有 222 个 Johto 稳定 local ID 不重编号；本轮仅将 0（若叶镇）和 1（29 号道路）映射为有效活动槽位。关都全部地图常量不变；不启用 `$E7/$F4` 老编号别名。

## 运行改动

- 活动槽位与 Header 描述符一一对应，Bank `$43` 的两张 Header/运行块/对象数据一起开放；Bank `$42` 的 Gold 原始块与连接表仍原样保存。
- 共用引擎 handle `$FC` 只用于运行时，`wCurRegion + wCurLocalMapID` 是唯一可靠物理身份；东西双向连接由稳定 ID + 方向查询，不把 `$FC` 存作真实城都 ID。
- 若叶镇西门→29 号道路东门，及反向连接启用；其余未登记邻居保持封闭。两张地图先用零 NPC、最少标牌，未导入旧分支多余的旧号脚本。
- 增加轮船的 New Bark / Go Home 菜单选择和明确地区目标，配合若叶镇码头踏板入口，尝试达成关都↔若叶镇双向往返。
- 防止原野怪遇敌表以 `$FC` 越界索引。新地图载入时经独立 ROMX 助手处理音乐/保存地区身份/Name Sign/Town Map；Johto Fly 与 Teleport 暂不开放。
- **必要的拥挤 Bank 调整**：将原本 Bank `$03` 的 `IsPlayerStandingOnDoorTileOrWarpTile` 和其同 bank WarpTileID 表**一起**移至扩容 Bank `$41`（原有调用点均是 `callab/callba`）；新增 Johto Tileset 28 的 Warp tile `$06` 表项，避免越界表读取。将 Kanto 原版 Town Map 360 字节 tilemap 单独迁至 Bank `$45`，复用现有 `FarCopyData2`，为 Bank `$1C` 新的城都浏览分支腾空间。
- 两个区域使用 Gold 派生的 runtime blocks / 同一个 Johto Tileset 28。Town Map 新图像/双条目仅在来自城都的普通地图浏览模式下使用，Fly 仍沿用关都旧列表。

## 验证和风险

- 本轮只做源码/引用/数据结构/地图长度/补丁正反和文件字节检查，不编译/链接 ROM，不进行手机实机测试，也不运行 Git Commit/Push。
- **重要**：用户必须本地编译正式红蓝，再查看新 MAP 中 ROM0、Bank `$03`、`$1C`、`$35`、`$38`、`$41`、`$42`、`$43`、`$45` 是否可链接；基线 MAP 空间不是本次目标版 MAP。若编译失败，必须停止进行实机验证，回传准确报错和新 MAP。
- **最小手机验收**：旧关都正常开档/存档，枯叶市轮船 → 若叶镇正常显示/不花屏，进入 29 号道路后原路返回；若叶镇轮船返回枯叶，再回来；分别在城都和关都存读档，试 Town Map/标牌/显示音乐/脚下碰撞，并尝试边缘逐格行走确认树林残留；红蓝都应测。
- 29 号道路其他邻居、门房、建筑室内、NPC/训练师、遇敌、Fly/Teleport 及全城都地图并未实现。首次手机跑图前，**不能宣称双向渡轮、连接或乱码问题已经解决**；出现黑屏/花屏或存档异常请提供画面、具体位置、目标 ROM 的 MAP 和错误日志。

## 开发交付说明

- 用户未要求正式清理三件套：仅交付两个等价起点的补丁（从当前干净 HEAD 到 P3-001 的增量、从本次确认 HEAD 到 P3-001 的全量），**二选一**，勿叠加。
- 只有用户明确验收后要求清理时才做提交记录；本轮无独立工具/审计脚本改动。


## P3-002 / PAL-5.62.221 / TEST-228 — 恢复旧参考分支表现（待用户验收）

- 已收到用户视频：TEST-227 若叶镇、29 号道路能进入、基本行走无明显问题；用户指出菜单 `New Bark Pass` 超框、船岸场景和 Route29 跳崖缺失。视频和口述不代表所有回归通过。
- **名称按 NPC-5.62.243 恢复**：`text/item_names.asm` 的渡轮目标可见文字从 `New Bark Pass` 恢复为 `New Bark`，保留仅供渡轮菜单使用的伪物品 ID `NEW_BARK_PASS`，不新增或改动背包道具。
- **船的进出位置保持与旧参考分支一致**：若叶镇地图对象恢复原始渡轮 Warp `(y=$08,x=$11) -> INSIDE_FERRY warp 0`，原来的水手 NPC `(x=$10,y=$07)` 和三名角色、四块标牌及原文逐条移入。原有 InsideFerry 的两条船出口仍由原脚本更新；跨地区目的地只把旧 `$E7` 改为稳定 `(JOHTO, local 0)`，并保留现有显式返回枯叶码头分派。旧分支对应 Warp 坐标与 P3-001 原本相同，本次修复的主要是缺失的场景 NPC、标牌与对白，不伪称修改了本来相同的坐标。
- **29 号道路**：迁移旧分支 4 名 NPC、2 个路牌及原文，并在稳定 local ID 1 的 `JOHTO_PILOT` 图块集开启旧版 `Route29` 跳崖 tile-pair 判定（左/右/下），不修改原 `HandleLedges` 的动画、声音或手感。图块集、tile collision 和 runtime map blocks 与参考分支逐字节一致；仅地图身份的判定改为 `(MAP_REGION_JOHTO, JOHTO_ROUTE_29_LOCAL_ID)`。
- **Bank 安全**：旧 Bank $06 的 MAP 仅剩 1B，完整 `HandleLedges`（包含阴影动画数据）整体迁到扩容 Bank $43；现有 HOME 调用 `callba HandleLedges` 不变，不新增 ROM0 代码。
- **阶段限制**：Route29 北门的门房尚未激活，原参考分支那条 Warp 不可盲目接回；保留 0 个北门 Warp，待该地图激活后一并迁移。若叶镇四栋屋子的门仍关闭；旧分支导游文本提及吉花市开放，但该相邻地图本期未接入。禁止为了还原旧编号去启用 `$E7/$F4` 别名。
- **交付范围**：开发测试补丁两份（上一轮已应用 TEST-227 的增量、已确认 HEAD 495b7dc8 的累计全量）以及仅含两补丁的 ZIP。不编译 ROM／不造测试 MAP／不执行 Git Commit 或 Push。用户验收重点：渡轮菜单文字不超框、若叶镇原水手/入口与进出船、29 号道路正确的跳崖动作及地图连接。
