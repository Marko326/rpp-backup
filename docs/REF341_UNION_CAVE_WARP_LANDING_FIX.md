# REF-341｜联合洞穴同 Tileset 楼层 Warp 落点修复

## 用户现象
从 B1F `(17,31)` 下到 B2F 后，人物没有落在 Gold B2F 唯一楼梯 `(5,3)`，而是保留源坐标并出现在 B2F 下方水池边。

## 根因
`LoadTilesetHeader` 只有在 Tileset 改变或当前 Tileset 位于 `DungeonTilesets` 时才调用 `LoadDestinationWarpPosition`。联合洞穴 1F/B1F/B2F 共用 `JOHTO_UNION_CAVE`，但该 Tileset 未列入 `DungeonTilesets`，因此跨楼层时跳过目标 Warp 坐标重建，保留来源地图坐标。B1F `(17,31)` 恰好在 B2F 对应水池边，造成实机现象。

## 修复
把 `JOHTO_UNION_CAVE` 加入 `data/dungeon_tilesets.asm`。不修改 Warp 事件坐标、注册路由、地图块、碰撞、Surf、调色或边框。

这同时修复 1F `(5,19)` ↔ B1F `(7,19)` 那组原本会保留来源坐标的两格偏移；1F `(3,33)` ↔ B1F `(3,33)` 因源/目标坐标相同，旧实现只是碰巧看起来正常。

## 验收边界
静态检查只能证明同 Tileset 楼层进入目标坐标重建路径，不能代替手机实机。请重建 Red/Blue/TEST，并验证 1F↔B1F 两组楼梯、B1F↔B2F、旧档 Continue/Save/Reload 与 MAP 空间。
