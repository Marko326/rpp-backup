# UNION-CAVE-260｜联合洞穴首次接入前底座盘点（仅准备，未激活）

## 当前材料

- 已有：固定城都稳定 ID 框架；`JOHTO_UNION_CAVE_1F_LOCAL_ID = 8`，`maps/johto_staged/JohtoUnionCave1F.blk` 为 180 字节离线候选；活动地图 Header/Bank、Warp 方向与到达落点、Town Map/存档地点名、音乐继承、Surf/地形审计器均可作为扩展入口。
- Gold 参考已有 `maps/UnionCave1F.blk/.asm`、`UnionCaveB1F.blk/.asm`、`UnionCaveB2F.blk/.asm`（每层 `.blk` 为 180B），各层原版 Warp 清单可用：1F 有4个（到 B1F 两个、到 Route33 一个、到 Route32 一个）；B1F 有5个（到遗迹外围两个、到1F两个、到B2F一个）；B2F 有1个返回B1F。参考根目录使用用户交接包中的 `REFERENCES/Gold/pokegold-master/`。
- NPC 参考 `NPC-5.62.243` 内有1F运行地图、专用 `johto_union_cave.bst`、`johto_union_cave.png`、`johto_union_cave.tilecoll`、相关 palette、1F Warp/NPC/Surf 实现。该旧实现只可作代码参考，不可直接复用旧物理地图句柄／Bank。

## 尚未铺成的运行时部分

1. **洞穴专用 Tileset/Blockset/碰撞**：主工程只有普通 `cavern` 与户外 `johto` 图块资源，没有已登记的活动 `johto_union_cave` Tileset；需逐像素块映射、Gold 属性与 ROM0 可读碰撞表和 Bank 指针校验。
2. **实际地图激活**：稳定 ID8 已保留，但1F尚不在活动 Slot/Header。Gold B1F/B2F 的运行地图也尚未移植；不能把资源暂存误称成可玩。
3. **楼梯与洞口 Warp**：只应先开放 Route32 ↔ Union Cave 1F 双向闭环。1F 到 Route33 和 B1F 两处入口、遗迹到 B1F 两处入口保持 fail-closed；必须明确触发方向、落点及回程，不能让角色卡入禁用楼层。
4. **洞穴独有规则**：Gold CAVE 骑车按脚下地形判断；洞内 WATER/上岸逐格核验；地名弹窗／Save/Continue／Fly 地标、场景音乐缓存、遭遇与 NPC/剧情与洞内调色分别登记，禁止全局开关替代地图专属合同。
5. **内存／连接空间**：新增资源时审查 ROM0 和浮动 Bank 的 MAP 实际空间、Tileset pointer 可访问性、存档恢复后的指针；原有道路跨 Bank 连接经历过杂图问题，不能直接照搬。

## 下一开发批次建议

先以1F为独立单元：Gold 原始块→运行图块和碰撞→独立 Tileset/Bank→受控 Route32 入口和返回→完整离线审计与负向故障注入。完成本地 Red/Blue/TEST 与 MAP 编译、1F 入口及返回实测后，才讨论 B1F/B2F、Route33、NPC、物品与野怪。此文档只盘点，不开放任何洞穴入口。
