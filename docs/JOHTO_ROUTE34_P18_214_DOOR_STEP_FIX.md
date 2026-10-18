> **历史 .214 候选：双向自动一步已经被用户实机否决。** .215 改为仅向下到达自动一步，向上到达保持 Warp 落点。参见 `JOHTO_ROUTE34_P18_215_DIRECTIONAL_STEP.md`。

# P18 · ILEX-5.62.214｜北门房竖向进出门修正（候选）

**状态：基于用户 `.213` 实机视频修正源码；RGBDS 构建及 `.214` 手机验收未完成。禁止提前 Git 提交。**

## 实机纠错

三段视频：用户 `.213` 新门房、Gold 北门房、RPP Route6–SaffronCity 竖向门房。`.213` 能切换地图，但进入/退出后停留在门口，常需额外按一个方向键。正确的行为是：沿入口方向踏进 Warp 即切图，加载目标地图后**自动向内部走恰好一格**，然后释放输入。正常左右换列、站立不自动切图，禁止自动连走和重复传送。此前文档“门垫不自动行走”指不能无限自动行走/踩上就无条件传送，不能理解为禁止合法离门一步。

## 严格复用历史程序

- `home/overworld.asm:CheckWarpsNoCollisionLoop`：原 `IsJohtoSouthGatePortal` 已区分历史门房；在它认定的本项目门房中，**只对新北门房/Route34/Forest 北出口**借 `JohtoNorthGateStepWarpAllowed` 判断走向，并交给**已有** `WarpFound1`，无需再在阻挡门口多按一次键。其它地图仍沿既有 `CheckWarpsCollision`，不改变 P16 已验收南门房。
- `engine/overworld/johto_route33_collision.asm`：在**已有**城都地图碰撞模块增加小型方向白名单；只接受 Forest 单北门 `(1,5) UP`、北门房 `(4/5,0) UP` 与 `(4/5,7) DOWN`、Route34 `(13/14,37) DOWN`。函数只在主循环精确匹配当前 Warp 记录后调用，其他坐标不可能误触发。切换图之后不再进入普通 Warp 入口，避免无限循环。
- `engine/overworld/region_map_lookup.asm:GetJohtoWarpArrivalStep`：在**现有到达规则表**追加 7 条；新北门房底部 y7→y6 (UP)，顶部 y0→y1 (DOWN)，Forest (1,5)→(1,6) (DOWN)，Route34 (13/14,37)→(13/14,36) (UP)。由既有 `engine/overworld/npc_movement.asm:PlayerStepOutFromDoor` 执行 **1 个模拟方向键**，不重新开发剧情/动画脚本。
- 新增 source-branch 负例测试：上下/侧向、旧南门房、错误方向，不能绕过方向白名单；原有 `johto_warp_arrival_audit` 严格限定七个新到达配置并检查目标 mask 为 FLOOR。

## 严禁扩大影响

不改 Gold 原版图块、地图、音色调色、地图碰撞 mask、Route31、桐树林南口、Kanto 门房、Cut 和已冻结 `ILEX-LEDGE-001`。B 键、普通行走、场景切换依旧采用现成 RPP 引擎。

## 必须实机确认

1. 从 Forest 北侧向上走到门口，**一次进入** Gate 底部，然后自动上移一格；立即朝下退出，自动下移一格。
2. Gate 两个顶部出口各自向上进入 Route34，自动上移一格；Route34 两个南口各向下进入 Gate，自动下移一格。
3. 每个出口松方向键/长按方向键/B 加速重复，确保仅一步自动离门，无二次自动传送；左右横向换列不触发；左右墙与邻树不能穿。
4. 原森林南门、Route31 Gate、Route6–SaffronCity Gate 两边往返；关东配色、Cut 和冻结跳崖不回归。普通/快速地图加载、存档继续也抽查。
5. 实际 RGBDS 构建/链接与 MAP Bank 容量；这一轮静态回归 **不等于** ROM 编译或实机验收。
