# MAP-5.62.192｜联合洞穴双向洞口修复与按来源 Dig/逃洞绳

**源码前置**：原始用户上传的已提交 `DIG-5.62.188` ZIP（导出 HEAD `b99710c1`），接 `.189～.191` 交付候选；完整 pokegold-master 同时在场。此轮在 `.191` 上只处理洞口和返程，不重复转换 Gold Route33 地形。游戏显示版本升级到 `MAP-5.62.192`。

## Gold 原版及 RPP 启用映射

| 方向 | Gold 坐标/目的 | RPP 实际对象及目标 Warp (0-based) |
|---|---|---|
| Route32 → Union Cave | Route32 `(6,79)` → Gold cave Warp4 `(17,3)` | `JohtoRoute32` Warp 0 → RPP Cave Warp 0 `(17,3)` |
| Union Cave → Route32 | Cave `(17,3)` → Gold Route32 Warp4 `(6,79)` | RPP Cave Warp 0 → Route32 Warp 0 `(6,79)` |
| Route33 → Union Cave | Route33 `(11,9)` → Gold cave Warp3 `(17,31)` | Route33 Warp 0 → RPP Cave Warp 1 `(17,31)` |
| Union Cave → Route33 | Cave `(17,31)` → Gold Route33 Warp1 `(11,9)` | RPP Cave Warp 1 → Route33 Warp 0 `(11,9)` |

RPP 仅启用 Gold 洞穴第3/4 Warp，所以目标索引从 Gold 2/3 重新编号为 RPP 1/0，`REGION_WARP_ESCAPE` `$FE` 保留并解析为双部分物理 key。

## 入口与防卡门

- `JOHTO_MODERN` Route33 的 `CAVE` 格 `(11,9)` 在原 Gold 16×16 碰撞里非普通地板；只允许玩家在 `(11,10)` 朝上迈一步进入真正的 Warp 格；其它像素相同的墙不解锁。前方被阻挡的地图碰撞仍不能向其它方向穿墙。
- 洞内 `(17,3)` 和 `(17,31)` 都是 RPP 认可的可站 Warp 格；使用旧版已验收的向下碰撞 Warp，不启用对整个洞穴地板自动 Warp。旁边经过不传送。
- 返回 Route33 `(11,9)` 后才模拟向南走一步至 `(11,10)`；返回 Route32 仍由现存 `(6,79)` 向南走一步 `(6,80)`。进洞停在洞内对应 Warp，不做额外模拟动作。
- Route33 西边桧皮镇、Union Cave B1F `(5,19)`／`(3,33)` 保持关闭。32↔33道路边界 x=0..14 的既有连接不改。

## Dig／逃洞绳来源与边界

- 捕获来源只发生在已匹配的 `$FE` 室外→联合洞穴 1F Warp，并且在 `StoreNativeWarpTarget` 覆盖 `wCurLocalMapID` **之前**。核对来源地是否 Route32 local7 / Route33 native local9、原 Warp 索引以及目标 cave local8 的合法性。使用现存可保存的 `wLastMap`、`wLastRegion`、`wLastLocalMapID`，不扩存档。
- 使用 Dig／逃洞绳时，仍必须经过 `.188` 洞穴地区、地图、tileset、magic 与技能许可检查。返回来源为 Route33 则安全落在 `(11,10)`，否则以已审计 Route32 `(6,80)` 作为旧档或来源未知回退。关东旧 Dig/Teleport，黑屏 `wLastBlackoutMap` 与其他洞穴未开放权限不改。
- 仅支持**两张道路各一个已开放洞口**的来源地图选路，并未增加原版 Gold 的通用 `wDigWarpNumber` 任意入口记录。日后同一张地图开启多洞口时需要再设计。旧存档边界状态需实机核对。

## 验证与用户最小操作

`PYTHONDONTWRITEBYTECODE=1 python3 tools/johto_map_release_audit.py --rpp . --gold /path/to/pokegold-master --expect-version MAP-5.62.192` → **337 PASS / 0 fail / 0 skip**，包括 12 个新增逆向反例。这里只是静态源代码检查，未编译 ROM、未验证 Bank/链接布局，也未收到手机验收。

建议：①32号道路进联合洞穴、走到底从 `(17,31)` 朝下出到 Route33，再从 `(11,10)` 朝上重新入洞；②分别从32／33道路进洞，在洞内用 Dig、逃洞绳，核对各自返回原入口外并只消费一根绳；③在南口横向走/反向朝上，不应误出洞，洞口墙不穿透；④抽测旧 Route32 北口进出、Surf、继续存档后返程以及关东原 Dig／逃洞绳。若 Termux 编译失败只反馈第一条真正错误和 MAP，不自行删旧代码。

**当前验收状态：STATIC_PASS／BUILD_PENDING／PHONE_PENDING。** 禁止冒称构建通过或已实机验收；无 Git Commit/Push。
