# GATE-5.62.224 — Route35 ↔ 满金市门房（正式收口）

## .224 视频回归修正（历史候选失败与修复）

- 用户对照 `RPP224 金黄市和35号门房.mp4` 与原版 Gold 视频指出两处明确问题：35 号道路南端越过可视区显示默认树林边框；门房南侧 Warp 返回满金市北口时缺少向下一格的离门动作。此前 586 项 PASS 没有检测这两项，是审计覆盖缺陷，不是用户误操作。
- Gold `data/maps/attributes.asm` 中 Route35 原有 `connection south, GoldenrodCity, GOLDENROD_CITY, -5`；RPP 当前仍通过门房 Warp 通行，**只补显示边框，不打开未审核的道路直通边缘**。为旧 `JOHTO` 画面单独映射相邻 `JOHTO_MODERN` 城市前三行图块：完全相同的 4×4 图块优先使用对应 ID，无法匹配的 $06/$67 降级到中性地面/兼容屋顶。后续以手机画面对照为准，不能宣称色彩与像素完全相同。
- `GetJohtoWarpArrivalStep` 增加目标满金市 `(19,1)` 从门房转入后的 `D_DOWN`；已正确的门房北口 `y=0` 保持 `D_DOWN`；不对门房南口 `y=7`、道路其他坐标乱补步进。依赖通用 `PlayerStepOutFromDoor`，不新造执行器。
- 对关键两种回归补入原版相邻边界核对、两条加载路径钩子、WRAM 行偏移、图块错配和自动步进朝向的负向故障注入，登记为统一门禁的强制测试。功能和审计**同一个测试候选补丁**，不拆 Git 提交。保持版本 `ILEX-5.62.224`（本轮仍在 .224 试验阶段）。
- 仅静态验证；这条历史候选当时仍需用户重新 ROM 编译后确认 35 号道路南侧不再出现树林带、门房两端向下步进、连续往返及旧门房回归。既有 SafariZoneBeta 与本问题无关。


- 基线：用户最新 `.223` 完整工程导出；以原版 `pokegold` `Route35GoldenrodGate.asm`、`NorthSouthGate.blk` 对照。
- Gold Route35 warp (9,33) / (10,33) → 门房顶端 (4,0)/(5,0)；Gold GoldenrodCity warp (19,1) → 门房底端 (4,7)；门房底端两格都到城市同一 Warp。
- RPP 0-based：Route35 #0/#1 → 新 Gate #0/#1；城市 #0 → Gate #2；Gate #2/#3 → 城市 #0。Native local ID 新增 #18，旧 #0..#17（含满金市 #15）一律不动。
- 复用已验证的 `JOHTO_GATE` 图像/调色、Gold `NorthSouthGate` 5x4 映射、`JohtoRoute34GateCanStepAhead` 与 `IsJohtoSouthGatePortal`。新地图不新增剧情 NPC、不复活未开放的自然公园门房。
- 到达动作按端区分：抵达 Gate 北缘 y0，`D_DOWN` 一步；抵达 Gate 南缘 y7，`NONE`；抵达 City (19,1) 为 `D_DOWN`（视频纠错）；Route35 (9/10,33) 为 `NONE`。Gold Warp 坐标并不自动证明后续行走时序，须实机核验。
- 触发只允许正确入口与方向；站立在门口、侧擦、错误方向不应自动传送，两个 lane 必须能来回快速复入。
- 室外边缘建筑由 Gold 原始 `.blk` 的现有图像表示，不改两边户外地图布局/方框。金银旧门房、关东 Gate 和旧屋顶/跳崖仍列回归。
- **收口状态：STATIC_CONTRACT_PASS + 用户确认的 PHONE_ACCEPTED**。`224定稿.mp4`（约 25.6 秒）可见双向进出、门房内外与相邻地图外观，用户明确报告最新版已测试无异常；额外的输入时序、每条 Lane 的逐帧按键、旧存档、其它门房完整回归没有新的独立记录，不可据此全部标绿。用户先前 `rppred(1).map` 对应一次 ROM0 已用 `$3fe0` 的成功链接，但不代表本轮每次改动都已链接。旧 SafariZoneBeta 是独立遗留项，不属于本次门房修复。
