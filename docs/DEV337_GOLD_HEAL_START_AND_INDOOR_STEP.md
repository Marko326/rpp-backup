# DEV-337 / REF-331 — Cherrygrove City Gold Pokémon Center

## 用户实际报告（REF-330）

1. Gold 柜台换了，但治疗动画沿用 Kanto 8×24／3图块以及错误的球坐标；参考截图 `65134.png`。
2. 在 `Cherrygrove City` 治疗后 Fly 到其他 Johto 地点，普通 Town Map 按 START 仍定位当前地标，而非最后一次治疗的 `Cherrygrove City`。
3. 在该中心室内“一走一步顿一下”，表现为移动明显不连续。此前门毯边界问题已修，不能将所有新问题当作同一种原因。

## 源码核对与本轮修复候选

- 原版 Gold `pokegold-master/engine/events/heal_machine_anim.asm` 使用 `gfx/overworld/heal_machine.png`，8×16／2 个 8×8 图块，8 个 OAM：机器 Y32 X34/38，球 Y38/43/48 X32/40。参考 PNG SHA256 为 `d62bad94c8ff93ae8c554df22d43b4f472696e5a3b1023d04fd16b030f4ff34f`。
- RPP Kanto `engine/overworld/healing_machine.asm` 用 8×24／3图块和固定 OAM。该函数、位于 Bank $01 的数据和 Kanto 的 `wLastBlackoutMap` 保持不动；护士 Yes 的单次 `callba` 改为 `AnimateHealingMachineRegional337`，Johto $FC/ID123 走 Gold 专用动画；其他地图无条件分派回 Kanto 原函数。新的 Gold 图块/代码放在浮动 ROMX；**ROM0 不新增执行指令**。
- Gold 分支完整播放并结束治疗音乐、恢复 OBJ palette 和 sprite 更新状态之后，直接写 `wJohtoLastHealLocalID=123` 与 `wJohtoLastHealMagic=$A6`，不在长动画后再次要求不稳定地图状态通过第二次判断。分派入口仍校验 $FC 和 ID123。Town Map START 仍使用既有的允许列表，Fly 不修改治疗记录。此处是静态设计修复，是否解决用户设备上的失忆必须查实际内存／实机。
- 室内逐格卡顿没有动态测量数据，**本轮不能宣称已经查明根因**。确认的多余工作是：同一个 $FC 室内仍经 `home/overworld.asm` 的城都室外碰撞检查，旧代码在 `JohtoPilotIsClosedOutdoorEdge` 中要扫过大串户外地图 ID 才抵达 10×8 Gold 有限室内边界；`JohtoPilotGateDoorApproachAllowed` 和 `JohtoOverworldSouthLandDecision` 也扫户外角色分派；这些分派的时间成本是确定存在的，但是否足以造成可感知的逐步卡顿尚无证据。本轮把 ID123 的封闭边界判断放在第一分支，另两者早退到原有室内/legacy collision。这保持原有墙界、格子与 DOWN-only 地毯语义；并非关闭碰撞来提速。
- 所有地图每次起步正常会经过 `AdvancePlayerSprite_` 的 `LoadCurrentMapView` 和一行/一列 redraw。其执行也可能与 VBlank/地图尺寸/图块数据造成延迟有关，但没有 frame trace **不能判定**为卡顿原因。

## 测试范围和实机分辨法

1. 查看 `Cherrygrove City` 治疗球位置与 Gold 柜台配对，确认动画恰好对应最多6只球、不会覆盖墙/柜台或遗留残影。Kanto 任意已开放 Pokémon Center 另抽查其老动画未变化。
2. 先在 `Cherrygrove City` 中心治疗，再离开到 `Route 29` 按 START，应去 `Cherrygrove City`；再 Fly 到 `Violet City` 或其他已解锁的 Johto Fly 地点重复；最后重新存读档再测。若失败，读取 WRAM `$D795/$D796`：治疗后预期 `A6/7B`，Fly 后仍应 `A6/7B`。治疗后即错误为写入路径；治疗后正确、Fly 后错误为覆盖/存储路径；两处都正确仍定位错误为菜单读/映射路径。
3. 测试该中心直线连续走4–6格、来回走、隔柜台按 A；再在 Kanto Pokémon Center 或已验收的 Gold 门房按同样节奏移动。如 Kanto 也卡，先查全局刷新/运行速度；仅 Johto Gold Center 卡则测地图边界与 per-step 的 ROMX farcall/VBlank。用户如能录 5–10秒带帧率的对照视频，有助区分 CPU 忙导致帧掉落与速度设置。
4. 两格门毯间左右换格应完全不 Warp，只有有效地毯朝 DOWN 撞边界才退出；不能再进黑白区域或死机。
5. 由用户本机构建 Red、Blue、TEST，最新 MAP 确认 ROM0≥64B 及 Gold 动画的浮动 ROMX 落点；我们在交付环境不运行 make/rgblink，不把源码审计当链接或实机验收。

## 交付规则

测试期单 ZIP、两份互斥**正向**补丁（① 已应用 DEV-336/REF-330 到本轮；② 干净 HEAD `300e0a4c4afece275db40a09558b5810d7deb8f4` 到本轮），只能选一种；不 Commit、Push 或编译 ROM。
