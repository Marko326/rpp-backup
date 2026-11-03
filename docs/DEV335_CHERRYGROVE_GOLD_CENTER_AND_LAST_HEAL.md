# DEV-335 | REF-329 — `Cherrygrove City` Pokémon Center 实机反馈修复

状态：**源码级开发候选，尚未获得 ROM 链接／新 MAP／实机复验**。

## 本轮问题

- 用户反馈：在 `Cherrygrove City` Pokémon Center 与护士治疗后，离开并前往其它地点，普通 Town Map 按 START 仍定位当前玩家位置，没有定位最近治疗地点。
- 用户反馈：DEV-334 的室内与关东 Pokémon Center 相同；目标是 Gold 风格，并优先复用参考分支 `NPC-5.62.243` 已有的 Johto 室内，而不是每个城市重新制作。

## 修复设计

1. **治疗记录时机**：护士 Yes 选择后，现有 `predef HealParty`、`AnimateHealingMachine` 走完才通过 `engine/overworld/healing_machine.asm` 的成功动画出口调用 `JohtoRecordSuccessfulCenterHeal335`。No 分支不会播放动画，也不会进入这个出口。`SetLastBlackoutMapRegional` 对 Johto `wCurMap=$FC` 直接返回，避免原先治疗动画前的条件写入与两个时机竞态。仅当 `$FC` 且本地稳定 ID `123` 时写入 `wJohtoLastHealLocalID=123` 和 magic `$a6`。Kanto 原有 `wLastBlackoutMap` 仍只按原来的 Safari/LastMap 规则更新；Teleport/战败返回依旧不开放。
2. **START 读取**：`JohtoPilotGetLastHealLandmarkOrPlayer` 读取 magic+ID 双字节有效记录，返回 Gold 45 地标表中的 `Cherrygrove City` 序号2；不再做与单个已登记常量无关的第二次活动槽查询。无记录或记录不合法仍定位玩家当前地标。旧存档无此双字节组合时保持兼容。
3. **Gold 5×4 内部**：从交接包 `NPC-5.62.243` 的 `JohtoOlivinePokecenter1F` 复用 64×96 像素图、16-block blockset、20B 室内布局与 96 项逐 tile 调色板；本项目共用运行名为 `JohtoSharedPokecenter`，让以后可复用。护士和两格出口脚本及 48 图、107 Warp 登记不重排。
4. **ROM0 完全不新增碰撞表**：参考室内 passable tile 为 `$09`/`$2e`，现有常驻 Kanto `Pokecenter_Coll` 包含 `$10/$11/$32`。将 tileset 的三个图块编号两两交换：`$09↔$10`、`$2e↔$11`、`$32↔$34`。**同步**交换 PNG tile 位图、blockset 指针和 96 项 palette；新地图所有实际引用图块的可通行性与参考逐格等价，原画面像素逐 tile 不变。原参考四种文件在 `maps/johto_pilot/reference/` 下单独留档，后续无需依赖用户旧 ZIP。只新增独立的 tileset ID 37 `JOHTO_POKECENTER`，保留关东 ID6 不动；专用图块和脚本都在 ROMX。
5. **配色与护士动画**：新增独立调色板组，按旧分支现成 Gold palette 标签，`color/sprites.asm` 让 ID37 与 Kanto ID6 共用治疗球闪烁用 OBJ palette。原 Kanto 贴图、代码及对话保持不变。
6. **游戏版本**：`REF-328 → REF-329`；正式与 TEST 共用原有版本文本入口，不额外引入独立测试版本。

## 静态审计与证据边界

- `python tools/johto_pokecenter_335_audit.py --project .`：使用 Python 标准库解析 PNG 灰度图，逐 tile 验证像素重映射，比较 16×16 blockset 指针/20 格地图、所有引用 tile 的新旧碰撞结果，核对 palette、tileset/descriptor/header、Kanto 隔离及护士 Yes 后写记录实际源码顺序。对应 `tools/tests/test_johto_pokecenter_335.py` 故障注入会人为破坏上述边界，应触发失败。
- DEV-334 原审计与测试已更新到最新 Gold 5×4 实现，不把旧 Kanto 7×4 作为正确结果；Gold 综合审计统一包含 DEV-334 继承合同和 DEV-335 新合同。
- 新资源在 ROMX 中，但**不等于**确认 RGBDS 链接成功、没有 BANK 溢出或游戏内像素表现完全相同；请用 Red、Blue、TEST 新构建 MAP 确认 ROM0 至少剩64B及色彩图块数据所在 BANK 的可用空间。项目规定 AI 不编译/链接 ROM、不 Commit/Push。

## 设备验证顺序（英文地名）

1. 从 `Cherrygrove City` Center 门进入，检查室内为 Gold 5×4 格局，左右出口都正常返回城市；护士脚下、柜台、治疗机器、出入口无空气墙或穿墙。
2. 首先在 `Route 29` 打开普通 Town Map，START 应定位 `Route 29`（如果尚未治疗且无有效旧记录）。
3. 到 `Cherrygrove City`，护士 **No**，离开并到 `Route 29`，START 不应被 No 改成 `Cherrygrove City`。
4. 再到护士选 **Yes**，完成动画后去 `Route 29`、`Route 30` 或 `Violet City`，Town Map 按 START 均应定位 `Cherrygrove City`，而不是当前地点。
5. 保存→退出→重启 Continue，START 仍定位 `Cherrygrove City`。再去 Kanto 普通中心治疗，Kanto START 应仍使用原 Kanto 治疗地点；Johto 记录应独立保留。
6. 检查 `Guide Gent's House` 入口未变；普通 Town Map B 退出、Fly 取消未受影响。**Teleport、战败返回、PC 电脑和中心二楼尚未开放，不能算已验收。**

如果第4项仍不对，应记录 Yes 是否确实播放完整动画、离开后当前英文地名及 START 显示位置；下一步需要设备上记录 WRAM `$d795/$d796` 实值（Johto magic `$a6`、local ID `$7b`），才能区分写入失败和菜单读取失败。不要在静态结果上宣称设备已修复。
