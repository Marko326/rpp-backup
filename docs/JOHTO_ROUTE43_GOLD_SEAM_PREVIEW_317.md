# REF-5.62.315 / DEV-317｜Route43 Gold 原版邻接画面修复

## 根因

DEV-315/316 的 `JohtoRoute43RuntimeHeader` 将连接字节写成 `db 0`，并直接指向 RuntimeObjects。这样地图加载器没有 north/south connection strips，屏幕缓冲区边缘只能显示默认 border block。Route43 自身 `Route43.blk` 的 270 字节确实与 Gold 相同，但这并不包括相邻地图的显示缓冲区，因此“原图字节一致”不能证明完整画面一致。

参考分支 `JohtoRoute43_h` 使用 `NORTH | SOUTH`：北侧从 Lake of Rage 拷贝 Gold 预览条带，南侧从 Mahogany Town 拷贝 Gold 预览条带。缺失南侧记录正是玩家截图中门房建筑消失、下方被树林填充的原因。

## 修复

- 加入 Gold `LakeOfRage.blk` 的 20×18 预览镜像 `LakeOfRage.preview.blk`，不注册/激活 Lake of Rage 地图。
- Route43 地图头恢复 Gold 原版 north/south 预览条带的宽度、stride、offset 和 WRAM 目标地址。
- 南侧直接复用同 Bank `$53` 已有的 `JohtoMahoganyBlocks`，不重复复制 MahoganyTown 地图资源。
- `JohtoEastIsKnownClosedEdge` / `JohtoPilotIsClosedOutdoorEdge` 继续封锁 Route43 北、南边界；没有向 `JohtoPilotSourceConnections` 添加 Route43↔Lake/Mahogany 的物理 seam。南端真实通路仍为两格 Gold Warp → ID65。

## 新增审计

- Route43 north/south header preview records 与 Gold 参考尺寸/偏移一致。
- LakeOfRage preview bytes 与 Gold 原版 360B 一致；MahoganyTown runtime bytes 与 Gold 原版 90B 一致。
- 预览数据与 Header 指针均留在 ROMX Bank `$53`。
- 物理边界仍 fail-closed，Lake/ID66 不会因显示预览而开放。
- 对删除北/南预览、修改镜像数据、误开放物理连接做负向故障注入。

## 验收边界

源码审计只能证明地图头/源数据/边界合同；本轮未编译或链接 ROM，也未取得新 MAP，因此不声称 ROM0/Bank 实际余量或手机画面已通过。用户本机重建 Red、Blue、battle-test 后，应重点确认 Route43 南端能看到 Gold 门房建筑、树林边界消失，并检查 Route43↔ID65 双向 Warp 与其他边界仍正常。
