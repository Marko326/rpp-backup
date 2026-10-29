# ROUTE32-245：由旧金银参考分支迁移城都南下路线（开发验收合同）

## 来源与编号

- 当前主项目：`PAL-5.62.243`，HEAD `b6102175`，再叠加 SAV-244，保留读取旧存档时 Tileset Header 重新装载的修复。
- 旧 NPC-5.62.243 金银分支：`maps/JohtoRoute32.blk`，10×45 Block（450B）；块集 `gfx/blocksets/johto.bst` 与当前项目逐字节相同。
- Gold 原版：`maps/Route32.blk`，也是 10×45 Block，但原始块编号不是运行时的紧凑编号，不能直接作为 JohtoPilot 地图运行。
- 本轮只激活稳定 ID **7** / 活动槽位 **8**。新增活动表条目数 9，不更改固定 222 个稳定 ID。

## 连接与边界

| 方向 | 实际行为 | 依据/风险控制 |
|---|---|---|
| 桔梗市南向 | `(Y35,X14/15)` → Route32 北口 | Gold 连接 offset 0；其它列封闭 |
| Route32 北向 | `(Y0,X14/15)` → 桔梗市南口 | 同步返回，不要求额外走一格 |
| Route32 南向 | 暂时关闭 | 33号道路资源已暂存但未开放 |
| Route32 西向 | 暂时关闭 | 阿露福遗迹门房未激活 |
| Route32 东向 | 暂时关闭 | 未核验其它跨区出口 |
| Route32 洞穴／中心入口 | 暂时不登记 Warp | 不能把未审碰撞或落点直接开放 |

Route32 的原 Gold 行走方位和 Header 均参考交接包的 `NPC-5.62.243_金银分支`，但使用本工程 `$FC` 运行句柄和稳定 ID 路由。两地图的连接预览数据与 Map Header/Blocks 处于同一 `$43` Bank。没有新增 ROM0 代码。

## 下批资源（只暂存）

- `maps/johto_staged/JohtoUnionCave1F.blk`（180B）：需独立 cave tileset + 碰撞 + 双向洞口 Warp + 旧档落点检验。
- `maps/johto_staged/JohtoRoute33.blk`（90B）：原参考分支使用独立 modern tileset，不能套 JohtoPilot 的块集。
- `maps/johto_staged/JohtoAzaleaTown.blk`（180B）：与 Route33 用 modern tileset，暂不允许连接。

三者均有静态 SHA-256 合同测试，`GetJohtoActiveSlot` 对 ID8、9、10 必须返回 `$FF`；只看到 `.blk` 不代表已经开放。

## 先做最小手机验收

1. 红、蓝正式版能正常构建，检查最新 `.map` 的 ROM0 与新增 Bank 空间。
2. 在桔梗市南口 x14 或 x15 向下，进入 Route32 后人物能继续上下左右移动；原路返回桔梗市也能移动。
3. 走完全段可达陆地，地图边界不能误过图；靠近 Union Cave、中心和遗迹入口不能错误传送/卡死。
4. Route32 存档→退出→Continue → 四个方向移动正常；留意 SAV-244 的旧档恢复逻辑。
5. 骑行双向跨图、原地图 31↔门房↔桔梗市回归，Route32 GSC 曲目与 Route30 相同但不无故重启。
6. 如果任一项失败，停止开放洞穴，反馈精确坐标/方向、模式和实际编译错误。

静态测试与补丁回放不能替代上述验收；本阶段没有 Git Commit 或 ROM 编译。
