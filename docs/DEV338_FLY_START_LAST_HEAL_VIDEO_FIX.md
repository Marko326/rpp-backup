# DEV-338 / REF-332 — Johto Fly START 真正读取最近治疗地点

## 实机证据

用户 REF331.mp4（约35秒，160x144）显示：Cherrygrove City 治疗后，从 Pokémon 菜单使用 Fly；再次在 Mahogany Town 的 Pokémon→Fly 地图中按 START，光标/地名仍指向 Mahogany Town。视频没有演示普通道具 Town Map 的 START。用户还确认 REF-330 已修复中心室内地毯与步行卡顿；DEV-337 没有这些问题的新增验收功劳。

## 根因

`engine/town_map.asm` 的普通 Town Map `.pressedStart` 在 DEV-334 就已读取 `JohtoPilotGetLastHealLandmarkOrPlayer`，但 `engine/johto_pilot_fly_map.asm` `.startShortcut` 一直沿用 DEV-333 的“遍历当前地图 `wCurLocalMapID` 并匹配已解锁 Fly 城镇”。这导致道路无匹配时 START 不移动、在 Mahogany Town 则定位 Mahogany Town，和视频现象完全吻合。之前连续修改护士记录，但没有改 Fly START 的实际入口。

## 修正

- Johto Fly `.startShortcut` 检验 `wJohtoLastHealMagic` 与 `wJohtoLastHealLocalID`，目前仅支持已接入的 CherrygrovePokecenter1F (stable ID 123)，映射到 Cherrygrove City Fly 表行1。
- 在选择前核对表项确实是 `JOHTO_CHERRYGROVE_LOCAL_ID`，再复用 `.isUnlocked` 双门禁：必须活动槽登记且到访事件已置位。
- 如果保存的治疗记录无效、活动槽关闭或未到访：不改当前 Fly 光标与特殊轴。A/B、SELECT、左右特殊地点、Kanto Fly 与普通 Town Map 均不动；不会把道路变成可飞地点。
- 不碰护士治疗动画、已验收室内 Warp/碰撞，也不再改室内所谓的卡顿优化。
- `data/game_version.asm` 游戏号等长升级 `REF-332`。

## REF-331 卡顿分流的准确范围

旧版 `JohtoPilotIsClosedOutdoorEdge` 把 ID123 提前跳入室内有限边界处理；`JohtoPilotGateDoorApproachAllowed` 对 ID123 提前 `ret z`；`JohtoOverworldSouthLandDecision` 对 ID123 提前返回 `E=2`，继续使用旧式室内碰撞。没有改步进帧率、VBlank、精灵行走或地图重绘，也没有 profiler 证据表明改变玩家感知的卡顿。用户确认问题在 REF-330 已恢复，此项不作为 DEV-338 结果或继续优化理由。

## 本机验收要求

1. 从 Cherrygrove City Pokémon Center 的护士选择 Yes 并完整治疗，然后在 Route 29 使用 Pokémon→Fly，浏览别的已解锁地名后按 START，应选中 `Cherrygrove City`，不是无响应，也不是当前地图。
2. Fly 到 `Mahogany Town`，再次从 Pokémon→Fly 打开，先将光标移到别的城市，再按 START，应回 `Cherrygrove City`（不执行飞行）。
3. 在有效治疗记录不存在时，Fly START 保留原光标，不能自动飞到当前城市；未到访的 Cherrygrove City 不可被跳过解锁门禁。
4. 验证 Fly 的 B 取消、SELECT、Lake of Rage 左右轴、普通 Town Map START 和 Kanto Fly START 均不受影响。
5. 如果第1或2项仍不符合，**必须分开读取 WRAM**：治疗后 `$D795/$D796` 预期 `A6/7B`，Fly 前后相同；若值正确但不能定位，调查菜单分派／对应 ROM 是否真的为 REF-332。切勿继续盲改治疗写入函数。
6. 用户自行 Red/Blue/TEST 构建并查看新 MAP，ROM0 必须 ≥64B、Johto Fly ROMX Bank 不能溢出；静态通过不等于链接/实机通过。

## 交付

开发阶段两份互斥正向补丁：①已应用 DEV-337/REF-331 → DEV-338/REF-332 增量；②确认干净 HEAD `300e0a4c4afece275db40a09558b5810d7deb8f4` → DEV-338/REF-332 累计全量。二选一；AI 不编译 ROM，不替用户 Commit/Push。
