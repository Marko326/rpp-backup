# FIX-5.62.279｜Route34／Goldenrod 三项实机故障与修复合同

## 现场证据

用户五张截图中前三张是当前故障：①北森林门房外道路右侧树墙变空白；②北上 Goldenrod 连接部分列被空气墙阻挡；③市北端门房上方出现紫色背景缺图。后两张为相应的正确树墙和门房上方画面。上轮 TOOL-278 只做静态检查，漏掉了三处运行时合同。

## 源码差异与最小改动

1. `data/johto_south_runtime.asm`: Route34 Object border `$00`→Gold 原版 `$05`（Gold `data/maps/attributes.asm`, mature NPC `data/mapObjects/JohtoRoute34.asm`）；保留 Route34 gold/runtime 原始270字节和所有 Warp。
2. `engine/johto_south_geometry.asm`: 两端 `JohtoSouthIsKnownClosedEdge` 原来分别仅允许 x8/9 和 x18/19；改为金银成熟 NPC-243 同款半开范围 `[8,12)` 与 `[18,22)`，必须只在 Route34 Y0/UP 及 Goldenrod Y35/DOWN 放行，其他边仍关闭。Gold角色网格在四列均是可行走陆地。
3. `engine/johto_ilex_mature_runtime_275.asm`: 移植旧 NPC `PatchJohtoGoldenrodNorthBorder`，从Gold Route35尾部取固定3行×10块的预览，写 WRAM blockmap 上方外围，三行分别从 `(x=5,y=-3/-2/-1)` 开始，不更改任何实际可走 Goldenrod blocks。新增统一 dispatcher 先调用既有 `PatchJohtoAzaleaWestGateBorder`，再进入 Goldenrod 只绘制的北端预览；`home/overworld.asm` 的原有一条远调用替换目标，不增加ROM0调用条数。
4. 修正 TOOL-278 将双列误认为正确的断言，增加空白边框、缩水通行、30字节图块、渲染调用链的独立负向测试；维持尚未开放的 Route35/建筑/NPC 限制。

## 本机验收要求（尚未通过）

- 用新ROM从森林北门房双 Warp 出至34号路，视角左右/骑车/走动看右侧树墙无空白，往返不触发坏Warp；桧皮镇西外墙原补图不得回归。
- 从 Route34 北端 x8/9/10/11 四条行走列逐列进入 Goldenrod，并从 Goldenrod 南端 x18/19/20/21 四条列逐列返回；检查画面滚动不花屏、无空气墙，边框以外不可穿行。
- 满金市往北走到仍封闭的 Route35 接缝前，确认上方门房完整显示、紫色空白消失，同时不得走进未开放的35号道路或门房。
- 正式 Red/Blue 全量编译，检查新 MAP 的 ROM0 剩余≥64B，昼夜屋顶、森林 Cut/Surf 与存档/读取回归。静态检查/源逻辑校验**不等于已在手机验证成功**。
