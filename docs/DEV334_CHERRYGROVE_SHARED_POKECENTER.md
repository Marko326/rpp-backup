# DEV-334 | Cherrygrove City 第一座共用 Pokémon Center（REF-328）

> 开发示范；只验证源码和 Gold 原版数据，不视为 ROM 已构建/实机已通过。后续地点说明采用游戏中实际显示的英文名称。

## 功能范围和复用结构

- 活动地图 47 → **48**，稳定本地 ID **123**（`CherrygrovePokecenter1F`）固定绑定活动槽 **47**。原 47 个槽和稳定 ID 均不重排。
- `Cherrygrove City` 原有 `Guide Gent's House` 门口 `(Y9,X25)` 独立保留；从 `Cherrygrove City` `(Y4,X29)` 朝 UP 可进入中心原版门口 `(Y3,X29)`。
- 共用 `engine/johto_shared_pokecenter.asm` 的 **7×4 RPP/Kanto Pokémon Center 室内模板**、现有 `POKECENTER` 图块、护士 `TX_POKECENTER_NURSE` 脚本/治疗动画、音乐，不重写专用引擎。Gold 源 `CherrygrovePokecenter1F` 原始 **5×4** 布局以单独资源保存用于核对；本开发示范室内外观采用共享 RPP 模板，**不是**逐像素 Gold 复刻。
- 室内 `(Y7,X3)/(Y7,X4)` 两格出口均返回城市门口，注册 Warp 总数 **104 → 107**（入门1条、出门2条）；复用原有“稳定ID→槽→header→共用Warp表→精准外门碰撞/踏入”流程。
- 护士治疗 Yes 走 RPP 原有治愈逻辑。治疗记录以保存区两个原先未使用的字节 `wJohtoLastHealMagic`（`$a6` 哨兵）和 `wJohtoLastHealLocalID`（123）保存，不改 Kanto `wLastBlackoutMap`；关东普通中心保留原来“上次复活点/Safari Rest House”逻辑。旧存档没有有效组合时不得把任意字节解释成城都治疗地点。
- 只有治疗成功后，**Johto 普通 Town Map START** 才定位到 `Cherrygrove City`；否则仍定位玩家当前地标。Kanto START 仍按 Kanto 治疗点定位。
- 暂不开放 Teleport、战败返回 Johto、二楼、PC 存取或其它城市中心；这些需要独立安全路线和保存语义。

## 新增中心时怎样复用

后续 `Violet City`、`Azalea Town` 等中心不用各自复制这套脚本和 `.blk`：复用 `JohtoSharedPokecenterRuntimeHeader` 的室内视觉和护士逻辑，增加各城市的稳定 ID→槽、精准入口/返回 Warp，以及该中心真实恢复地点的登记。**不要**把未来不同尺寸/出口位置直接套入统一 Warp：需逐个对照 Gold 来源，再引用共用入口。

目前恢复地点仅批准 ID123，新增下一家之前必须把 `SetLastBlackoutMapRegional` 和 Town Map START 的 allowlist 扩展为真正的统一中心目的地表（以及各中心回程/恢复入口），而不是复制 `if` 分支和覆盖 Kanto 记录。

## 交付边界与设备检查

- 游戏版本：`REF-328`，Red/Blue/TEST 同名；只交两份互斥正向补丁（已应用 DEV-333 的增量，或从 REF-325 干净 HEAD `300e0a4c...` 的累计），**不能叠加**。
- 用户本机重新链接 Red/Blue/TEST ROM 并保留新版 MAP：ROM0 剩余 ≥ **64 B**，确认新浮动 ROMX Section 可放置、Bank `$17` 与 `$1C` 等热点无溢出。旧 Blue REF-326 `$17` 余 29B，**不能代表本轮**。
- 关闭穿墙金手指。在 `Cherrygrove City` 从 `(Y4,X29)` 向上走进中心，再从室内底部门口的 **左右两格** 分别向下离开；返回原城市，不应进入 `Guide Gent's House`。
- 与护士交谈：选 **No** 不应写恢复地点；选 **Yes** 正常治疗、播动画。先在 `Route 29` 看 Town Map START（回当前地标）；治愈后重新打开 Town Map START 应跳 `Cherrygrove City`。保存→关机重进→再次检查 START；再进入 Kanto Pokémon Center 治疗后验证 Kanto START 行为仍正常。
- 暂不以此结果验收 Teleport/战败传送、其它中心或 Nest 数据，任何地方显示墙壁或按 UP 不进入请反馈**当前英文地名＋坐标＋操作方向**。

## 静态审计

`python tools/johto_pokecenter_334_audit.py --project .` 与带 Gold 的 `tools/johto_pilot_migration_audit.py` 独立验证映射、门坐标、3条 Warp、护士、恢复区哨兵、ROM0 外门进入 E=2、Kanto 隔离与源码资源；`tools/tests/test_johto_pokecenter_334.py` 有有效样例和13种故障注入。这里不是 Game Boy 模拟器；所有 ROM 空间和实际触发仍等待设备证明。
