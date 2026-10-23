> 历史候选记录：`.240A` 用户视频反馈无明显问题后已于正式 `.240` 收口；当前验收范围见 `docs/JOHTO_ROUTE29_ROUTE46_GATE_240.md`，不要将下方旧 `PHONE_PENDING` 当作最新状态。

# SPID-5.62.240A｜29号道路—46号道路门房：手机反馈修复候选

## 现场证据与结论

2026-10-23 用户上传三张 160×144 实机截图和 `SPID-5.62.240.patch`，反馈：

- Route29 南侧门房出入口附近，原上边缘树林/房顶瑕疵扩大成整行粉红墙砖。
- Route29 `(27,2)` 对着单格实体门 `(27,1)` 朝 UP 无法进入；开金手指改变位置才可到门框。
- Route46 侧 `(7/8,33)` 双格门毯进出和附近房屋画面正常。

上传的工作区 `.240.patch` 与交付 `.240` 的游戏改动一致；另外的 `.gitignore` 修改为已交付的 JSON 冲突修复例外。**这属于 `.240` 漏检，而不是用户按键或金手指错误。**

## 修复（仅两条运行时路径）

1. Route29 仍为 legacy `$F4`，不能进入只处理 `$FC` 的 `JohtoNativeCanStepAhead`。在已有 `CollisionCheckOnLand` 精灵、ledge、tile-pair 检查完成后，针对 `$F4` 调用 Bank `$43` 的 `JohtoRoute29GateStepAllowed`，精确检查城都 Region/local 1、位置 `(27,2)`、朝 `UP`，仅放行走到 Gold 实体门 `(27,1)`。随后由原来已接好的 `CheckWarpsNoCollisionLoop -> JohtoNorthGateStepWarpAllowed` 踏格 Warp 完成切图。玩家只需要**从门前走上门格时按一次 UP**，不是站在门框后再额外碰撞一次；其它周边屋顶、树墙继续阻挡。
2. Route29 的 Header 在 Bank `$40`，Gold 北邻 Route46 `JohtoRoute46Blocks` 位于 Bank `$47`。原 `ResolveNativeConnectionPreviewBank` 只按 `$FC` 识别原生地图，对 legacy `$F4` 直接 `$ff`，令 `LoadTileBlockMap` 在当前 Bank `$40` 按另一张图在 `$47` 的地址读取错误图块。仅给 Route29 (Johto local ID 1) 的 NORTH 连接序号 0 精确返回 `BANK(JohtoRoute46Blocks)`。这条选择在整图加载及相邻地图快速连接的公共 BlockMap 入口生效。**不修改 `.blk` 或通过大量填树林来遮挡症状**。

## 审计补强

新增 `tools/tests/test_johto_route29_gate_runtime_240a.py` 四项，覆盖真实 HOME `CollisionCheckOnLand` 调用位置、ROMX 放行分支、从 `(27,2)` 向上走与其它坐标/方向拒绝、旧版 `$F4` 到跨 Bank `$47` 的邻图来源，以及错误门口坐标/方向、删除调用、错误源 Bank/方向的负向故障注入。绑定 `tools/johto_map_release_audit.py` 固定必运行模块/测试 ID，及 `tools/johto_door_contracts.json` 新门房的强制测试 ID。

`.240` 旧静态审计只验证 Warp / 朝向 / Gold 角色和 Header 连接关系，没有按真实 HOME 的老地图行走执行器走通“跨过实体门格”，也没有验证 legacy `$F4` 图块连接的**物理 ROM Bank**。此次新增的是这两个遗漏的独立门槛。

## 实机待复测

优先使用重新编译出的 `.240A` ROM，不混用旧 ROM：Route29 按 UP 一次踏门并进入，回到 `(27,2)` 后立即 UP 重进；观察刚靠近门房和从门房返回 Route29 时上沿所有树木/屋顶是否一致；Route46 左右两毯逐个复测。旧门房、边界连接和 Save/Continue 作抽检。

仅源码/单元/统一静态审计不代表 ROM 链接或手机已验收。保持 `PHONE_PENDING`，不擅自 Git Commit/Push，不在此环境编译 ROM。
