> **MAP-5.62.192 更新**：以下 `.188` 固定返回32号道路是当时已验收的历史单入口行为；开放 Route33 第二入口后，联合洞穴 1F 改为根据上一次从32／33号道路进洞的来源地图选择安全返程；未知/旧存档回退32号道路。参见 `docs/JOHTO_ROUTE33_CAVE_EXIT_192.md`。

# DIG-5.62.188｜联合洞穴 1F Dig／逃洞绳首张地图正式收口

**基线**：本轮 ZIP `SRF-5.62.187`，导出 HEAD `9928eb3cf2b8c3327e774459400fd68424d286d9`；目标 `DIG-5.62.188`。**本版用户反馈能从洞穴成功返回洞口，按所报告场景完成手机验收；AI 没有编译/链接 ROM，也没有 Git Commit/Push。**

## 与原 Gold 的实际差异

- Gold `home/map.asm` 的 `EnterMapWarp/.SaveDigWarp` 只在从室外进入室内（CAVE/DUNGEON 等）时更新 `wDigWarpNumber`、`wDigMapGroup` 和 `wDigMapNumber`；Gold `engine/events/overworld.asm` 的 `.DoDig` 把它们复制为 `wNextWarp` 三字节，从洞穴回到对应的来源 Warp。并不是返回最近治疗点。
- RPP `.187` 的 Dig／逃洞绳原入口都通过 `CanUseEscapeRope`，成功后设置 `wd732` bit3、bit6；后者使 `LoadSpecialWarpData` 选择单字节 `wLastBlackoutMap`（最近治疗点）。本版只拦截**原生城都联合洞穴 1F 的 Dig／逃洞绳**，不改变 Kanto 的旧返回行为。
- Gold 32 号道路入口 `warp_event 6,79, UNION_CAVE_1F,4`；洞内返回出口 `warp_event 17,3,ROUTE_32,4`。本版 RPP 已开放的入口登记为 Route32 `(Y=79,X=6)` 与 Union Cave `(Y=3,X=17)`，其余洞口/B1F 未开放。RPP 已验收从洞内普通 Warp 回 Route32 时要在不通行的洞口砖 `(6,79)` 自动南移到 `(6,80)`。本版技能直接落到洞外**安全通行的 `(X=6,Y=80)`**，避免重入/多走步。

## 最小实现的不可扩权合同

1. 准入同时验证 `wCurMap == REGION_NATIVE_MAP_SLOT ($FC)`、Johto 地区、`JOHTO_UNION_CAVE_1F_LOCAL_ID`、当前洞穴 tileset 和两字节地区魔数；不能通过 `EscapeRopeTilesets` 整张 tileset 开放。
2. 仅当前单一开放入口允许使用固定出口目标 `(Johto,Route32 local 7, X=6,Y=80)`，不增加/平移 SRAM/WRAM 字段。当前有效入口唯一，旧档/Continue 不需要依赖可能污染的上次来源字节。**将来开放 Route33 出口或新洞穴入口前，这个固定目标必须重新设计**，不能继续声称 Gold 多入口语义被覆盖。
3. `wd732` bit3 + bit6 同时成立且身份匹配时专用处理；黑屏例程主动清 bit3，因此仍然走旧 `wLastBlackoutMap`；Teleport 仍因洞穴不属于普通外部地图而不可用。专用处理把 bit6 清除并写入 `(region,local)`、`wDestinationMap`、`wCurMap`、`wCurMapTileset` 及六字节 FLYWARP_DATA，沿用原特效和地图加载链路。
4. 不开放别的地区/地图和洞层，不更动骑行、Surf、B1F/Route33 封路、关东 Teleport/黑屏、Fly、音乐选择和旧 Warp 入口行为。`CanUseEscapeRope` 先执行旧版战斗与 Agatha 限制，新能力失败不进道具移除路径。
5. 新代码位于 Johto ROMX bank `$40`。紧张固定 bank `$01` 的新增调度通过删除一条未用的 `ld a,[wLastMap]` 并将 `ld a,0` 等价写为 `xor a`，以降低空间增量；由于 `.done` 位于短跳转距离之外，使用 `jp c`，原 MAP 显示 bank `$01` 空间依旧紧张，bank `$03` 资格钩子还会增加少量字节，能否由浮动段让位只能以真实链接结果判断。旧 MAP 非独立新构建证据，实际 Bank 重新分配和链接状态仍须由用户编译确认。

## 静态门禁与当前验收界限

- 基线 `.187`：289 PASS / 0 skip（完整 Gold）
- 正式 `.188`：298 PASS / 0 skip（完整 Gold；新增 9 项反向用例，包含地区、地图、黑屏分类、错误回程落点、错误源表和扩权）。
- 这只验证源代码结构、原版来源、负向合同；没有进行 RGBDS 汇编／ROM 构建、Bank 联结、模拟器或手机测试。已有按 Gold 显示的 Surf / 骑行/ Warp 实机反馈不可推论为新 Dig 已验收。

## 建议最小手机验收（先备份存档）

1. 由 32 号道路 `(6,80)` 北向进入联合洞穴 1F，队伍菜单 Dig → 确认 → 回到洞外 `(6,80)`；返回后四向移动、靠近洞口再次进洞正常，无自动额外迈步或黑屏。
2. 再入洞，用背包逃洞绳 → 同一出口，物品恰好消耗一根；失败/取消场景不消耗。
3. 进入洞内后先存档退出、Continue，再分别用 Dig 与逃洞绳，检查地图位置/状态/音乐；验证从洞穴不同位置（包括骑车及可安全靠岸后）技能行为一致。
4. **回归**：洞内普通双向 Warp、32号道路 Surf 与联合洞穴水面 Surf、31 号道路门房骑车下车；关东任选已知旧洞穴 Dig／逃洞绳、治疗点后的黑屏恢复和城外 Teleport。
5. 未开发的 B1F/Route33、其他城都地图仍不可意外逃出或解除封路。若编译提示 bank overflow、ROM 链接报错或实机 Dig 没有按预期传送，请停止应用后续补丁，提供终端完整构建输出和复现场景。

**补丁应用纪律**：增量和全量来自同一 `.187` 完整 ZIP 基线，二选一，不能叠加；通过用户构建及手机验收后才正式更新项目 TODO／开发陷阱及准备提交日志。

**文件权限提示**：从 ZIP 保留原文件 `0664` 权限时，使用 `umask 0002` 再运行 `git apply`；两种补丁都只应用一次。
