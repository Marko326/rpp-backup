# FIX-5.62.288 | 自然公园及双门房运行回归修复（开发候选）

## 用户实机反馈（.287 阻断）
1. 35号路南门房／公园东门房在进出及返回时可能走进黑色边界，游戏死机。
2. 普通步行与骑车时，公园长草没有遮住角色下半身。
3. 公园东门房内可走区域出现空气墙。
4. 公园外围围栏附近骑行时，部分边缘可以越界并死机。

## 本批运行修复
- `JohtoPilotIsClosedOutdoorEdge` 原先未列入 NationalPark 和两座 ParkGate。现在三个稳定ID全部使用 `JohtoSouthIsKnownClosedEdge` 边界检查：任何超出地图宽高的移动必须阻挡。已有已注册 `WARP_CARPET` 的外向碰撞仍经 ExtraWarpCheck/CheckWarpsCollision 转场；不允许普通行走直接跨入黑色 MAP_BORDER。
- `Route36NationalParkGate` 的 Gold角色原转换图将若干成熟门房走廊格错误分类为阻挡（如 x1/y5, x2/y5, x3/y5）。本批单独恢复 NPC-243 的16字节两行/格阻挡掩码，保留两侧4个合法门毯的横向进出，其他封闭。
- `engine/overworld/movement.asm` 按NPC-243已经验证的 `GetGrassSpritePriority` 复用 Player/NPC 共同接口。仅在 `JOHTO_PARK` 额外判断长草图块 `$3A/$3B/$4A/$4B`，给角色下半身 OAM 设背景优先级；对应 `data/tileset_headers.asm` 的 Park 常规草标记 `$04`。
- 保留 Gold原版 `.blk`、已验收35号路栏杆、遗迹门房、音乐源、活动26图、Fly和 TEST-231，不更改Warp目的索引、ROM0调用数量或SRAM。

## 强制脚本
- `tools/johto_park_runtime_regression_audit_288.py` 并入城都主审计。检查三图实际边界入口、Portal与 CheckWarpsCollision 契约、成熟门房阻挡掩码（SHA256固定）、合法4格出口、长草脚部遮挡和骑车/步行共同边界。
- `tools/tests/test_johto_park_runtime_regression_288.py` 进行边界/遮挡/数据坏字节/门房目的槽位错误注入。旧版 `.287` 不能通过该检查。
- 修复临时小工程测试夹具没有复制新Park图块与掩码的问题；旧 Route35 静态审计支持目前的真实版本，并保留老 `.282` 资源预备脚本的历史基线限制。

## 未验收
不得把静态通过当作实机结果。项目规范不由AI自行链接ROM。用户需本机重新编译Red/Blue/TEST并核对新MAP ROM0≥64B及Bank $4E容量。特别测试：
- 35号路→南门房→公园及四个方向的返程；公园→东门房→36号路及全部返程，两格地毯之间横移；
- 步行、骑车、关闭/开启Bike Song、长草下半身遮挡（Player与NPC）；
- 东门房 x0..9、y4/5 通道，公园外围任何可抵达的围栏/边缘，骑车连续压边；
- 36号路原遗迹门房、音乐续播、存档恢复；不可把黑色边界当作可走区域。

本批是 FIX-5.62.288 开发候选，不生成正式提交日志、不替用户Git Commit/Push。增量基线应为已应用FIX-287的实际工作区；全量基线以已确认 CLEAN-282 HEAD `2b171bcdcfa8a08570d19af136f9ee6d02f5cb0b` 为准，两者互斥。
