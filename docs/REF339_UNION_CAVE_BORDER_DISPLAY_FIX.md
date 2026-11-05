# REF-339 联合洞穴 1F / B1F 地图外边框显示修复（待实机验收）

- 用户两张游戏截图显示黑色地图外空白与 Gold 洞穴背景不一致；现有地图布局本身 10×18 未缩小。
- Gold `data/maps/attributes.asm` 两层 `UnionCave1F/UnionCaveB1F` 的 Border 都是 `$09`；Gold `cave_metatiles.bin` 的 `$09` 块由16个 tile `$16` 组成，呈重复洞穴地面纹理。
- RPP 两层 `RuntimeObjects` 用 `$21` 作为边框，在 `johto_union_cave.bst` 对应16个黑色 tile `$1f`，因此摄像机看到图外时误显黑区。
- 运行时 RPP tile `$05` 与 Gold tile `$16` **像素完全相同**，且 RPP `$05` 不在 tilecoll 可通行白名单，故**只改** `johto_union_cave.bst` 的边框块 `$21` 的16个tile索引为 `$05`。保持图外阻挡、图内1F/B1F区块、Warp、调色、活动地图数及碰撞规则不变。
- 更新 B1F 静态审计，检查两层 `$21` 对象边框、边框块像素匹配、不可通行白名单和 Gold `$09` 来源；此验收是静态验证，不代表 ROM 编译和手机动态验收。
- **配色是另一个独立问题，未在本批修复。** Gold CAVE 环境 `data/maps/environment_colors.asm` 为早/日/夜分别选调色组；RPP 当前联合洞穴使用固定的 `INDOOR_*` 调色。本工程 `data/regional_forms.asm` 明确尚无通用日夜系统。禁止简单将所有时段强制改成 Gold NIGHT 紫色调冒充完整还原。后续需要单独确定时段来源，再实现仅洞穴的 Gold palette 映射。
- 本阶段仅修地图外视觉，不新增楼层、训练师、野怪、NPC，也不进入清理阶段。
- 本机验收：红蓝/TEST ROM及新 MAP 余量、1F/B1F 靠地图四边移动、图外纹理是否连续、无穿墙、两组楼梯来回、保存/Continue。B2F 仍不开放。
