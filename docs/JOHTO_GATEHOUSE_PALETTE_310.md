# REF-5.62.310 / DEV-310 — Gold 原版门房绿色／棕色核对与公园门房配色修正

## 用户提供的 MAP 与本机观察边界

- `MAP_20261101_221655.zip`：Red/Blue 均标记 `REF-309`；ROM0 均剩 69B（合规线 >=64B）；Bank `$4E` 各剩 162B。REF-306 旧 Red MAP 的该 Bank 为 143B，新 MAP 确认 DEV-309 的 19B Bank `$4E` 压缩收益（与两份地图完整对照）。Bank `$05` 11B，`$1C` Red21B/Blue20B，`$53` 均为12703B。这些是旧版本 REF-309 实际链接的空间，不可当成尚未构建的 REF-310 MAP。
- 用户实测了 ID23/62 圆朱东西门房，以及 ID104/105 自然公园南／东门房；反馈地毯行走和横纵换道正常、公园门房禁骑车正常。设备反馈限这四座与上述场景，不能扩大到其余六座或夜间／存档。
- 用户发现公园门房柜台颜色与普通门房有别。本轮找到了确切的源代码颜色映射差异，但没有 REF-309 实机截图作为颜色像素的二次测量。

## Gold 源逐格逐颜色分析

- Gold：`gfx/tilesets/gate_palette_map.asm`：96 个 8×8 tiles 对应颜色标签；`gfx/tilesets/gate.png`：96 个 tile；`gfx/tilesets/bg_tiles.pal`：室内色条。
- 活动八座普通门房使用 `JOHTO_GATE`（ID30）；其 96 个紧凑重排 tile 的像素逐一与 Gold 原图匹配，且其颜色标签与每个匹配 Gold 源 tile 一致。它们映射的 GREEN/BROWN 已专用 `JOHTO_GATE_GOLD_GREEN/BROWN`，使用 Gold 室内绿色 (18,24,9)/(15,20,1)/(9,13,0)/(7,7,7)，棕色 (26,24,17)/(21,17,7)/(16,13,3)/(7,7,7)。
- 活动两座公园门房 ID104/105 使用 `JOHTO_PARK_GATE`（ID36），图块 PNG 与 Gold 原图字节一致，96 个 palette tags 与 Gold 原始顺序一致。但原 `color/data/map_palette_sets.asm` 的这一 tileset 行使用 `INDOOR_GREEN` 和 `INDOOR_BROWN`。它们各自前景 3 色一致，背景第 0 色却是 (30,28,26)，不是 Gold 的 (18,24,9)/(26,24,17)，导致柜台及附近绿色、棕色像素的底色可能偏亮、偏米白。
- 本轮仅将 `JOHTO_PARK_GATE` 这一 palette-set 行的 GREEN/BROWN 槽指向已经存在的 `JOHTO_GATE_GOLD_GREEN/BROWN`。JOHTO_GATE、关都 INDOOR、Gold 原图、两个公园不对称房间布局、角色网格、东门 mature mask、Warp、NPC、禁骑车规则一律不改。`JOHTO_SOUTH_GATE` 是预留 tileset；十座活动门房目前均不使用该 ID，不在本轮扩大修改范围。
- 共享现存调色板而非新增 RGB 色表，MapPaletteSets 每个 tileset 仍为 8 字节，RGB 数组、ROM0 程序、地图和存档结构均保持原大小；更改的只有两个值和等长游戏内版本文本 `REF-309@` → `REF-310@`。实际链接与调色效果仍须用户构建确认。

## 审计与交付要求

- 新增 `tools/johto_gate_palette_audit_310.py` 和 `tools/tests/test_johto_gate_palette_310.py`：读取活动十座门房合同／tile set／palette sets／RGB 定义，Gold 路径可用时对照原版全部 96 个 tag、原图像素、重排 tile 和 Gold 室内 RGB。故障注入把 Park GREEN 或 BROWN 退回旧通用映射须 FAIL。
- 旧游戏版本断言统一更新到 REF-310，保持普通版和 Battle Test Build 的**一个**版本文本。
- DEV-310 增量前置是**已应用 DEV-309**、还未有新提交证明的工作区；累计全量前置是用户最初上传的干净 REF-306 / 导出 HEAD `c4890820e06b5bb361ab663f40680117c59c2e70`。两个补丁互斥不可叠加。项目规则：AI 不自行 RGBDS 编译/链接、不 Commit/Push；用户本机另跑 Red／Blue／battle-test 的 REF-310 与新 MAP 才能确认链接、ROM0 不低于64B和显示颜色。

## 用户下一次重点验收

- 两座公园门房同昼间比较 Gold 原版：柜台和其旁边绿色／棕色墙饰的底色，尤其是靠柜台上的亮色区域；仍保持 ID104/105 不同外观与独立空间规则。
- 圆朱两座及普通门房的色调不应改变；仍能地毯上下左右换道、正确双向 Warp、隔柜台警员 A 键交互；公园内继续禁止骑车。
- 再看夜间（Gold 原版昼夜室内颜色处理与本项目原有时间系统不完全等价，不能用单次白天静态审计断言所有夜间画面完全相同），并检查 Red/Blue 与关都既有室内地形的配色不回归。
