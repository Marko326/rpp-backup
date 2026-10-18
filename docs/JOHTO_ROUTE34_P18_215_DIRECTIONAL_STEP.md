# P18 · ILEX-5.62.215｜北门房单向自动离门（用户已反馈当前进出正常，收口）

用户 `.214` 手机视频确认：门房双向触发正常，但所有到达方向都自动移动一步不符合需求。
本次执行合同：**向下移动穿过门房后自动离门一步；向上移动穿过门房后停在传送落点，不执行模拟方向输入**。

- 复用 `engine/overworld/region_map_lookup.asm:GetJohtoWarpArrivalStep` 和旧 `PlayerStepOutFromDoor`，仅删除 `.214` 的四条 `D_UP` 到达规则，保留 `D_DOWN` 三条：Gate 北沿 `(4/5,0)`→`(4/5,1)`，Forest 北口 `(1,5)`→`(1,6)`。
- 向上：Forest→Gate 落点 `(4/5,7)` 不追加一步；Gate→Route34 落点 `(13/14,37)` 不追加一步。两张目标地图 tileset `JOHTO_GATE`/`JOHTO_MODERN` 均未注册为旧 `DoorTileIDPointers`，因此无规则命中后不应通过原始门图块 fallback 再走一步。
- 入口 Warp 的朝向匹配仍由 `.214` `JohtoNorthGateStepWarpAllowed` 管理，**本轮不改入口触发逻辑**；其它门房、南口、Cut、Surf、地图、阻挡掩码、背景图形和配色均不变。
- 单元和静态审计约束三条 DOWN 及零条 UP；另防止未来误新增 UP 自动步。源码静态通过不等于 CPU/ROM 或手机行为证据。
- 实机重点确认双向进出：向上停原位置，向下自动走一格；松键、持续按键和 B 均不造成卡门或连走。`.215` 用户反馈本次进出与道路步行未见明显问题；其它列出的极端回归仍未逐项取得实机证据。本次文档收口不改运行时。
