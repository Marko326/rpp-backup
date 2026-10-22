# SPID-5.62.239：东线四张室外地图源码与工具正式收口

本文件只记录本轮**收口**，不是交接文件、未来开发规划或新版本发版承诺。

## 边界

- 以用户上传的 `.239` 完整工程导出快照和上一份针对该快照实测能应用的东线补丁组合为清理前置状态；没有 `.git`，不虚构本地 HEAD。
- 保持 45 张城都活动图、56 条有向连接、烟墨市 Fly 落点、44号道路/45号道路/46号道路的 Town Map 普通位置。`data/game_version.asm` 一直是 `SPID-5.62.239@`，不带 A/B。
- 本轮发现并修复 Gold Route45 四处真实 HOP_RIGHT 起跳点 `(6,20/21)` 和 `(6,64/65)` 被步行 mask 错封；原版 Gold `.blk`、`docs/gold_east_source_239/` 离线快照均不改动。
- 为避免“新增测试绿、旧测试红”的情况，已将 Bank47 东线跳崖列表逐坐标/方向入统一 Gold 审计，补足旧临时目录缺失的新源文件，更新旧地图/连接数量硬编码，保留负向故障注入。

## 验证证据

- 重新执行 `python tools/johto_map_release_audit.py --rpp . --gold <完整 pokegold-master> --expect-version SPID-5.62.239`：**PASS，927/927 项 Python 单测通过、0 skipped、56/56 活动连接 PASS；Gold 368 登记／367 扫描／367 来源 PASS／0 来源错误，SafariZoneBeta 唯一按项目白名单排除；masked-step 源码模拟 0 failures（非 ROM/手机证明）**。
- 功能与工具分拆的三份补丁在隔离目录测试 `git apply --check`、正向和逆向实际应用，再逐文件校验最终态；日志见包内 `VERIFY.json`。不能把源码比对算作 ROM/CPU trace。
- 用户反馈本轮已体验东线室外未发现明显问题，不据此虚构逐格旧档、所有跳崖和全部冰道验收。

## 持续封闭

冰雪通路 1F/B1F 的真实冰面/多层 Warp，未开发的城市室内、训练家/物品/剧情不属于本次运行时接通。当前环境没有最新版 ROM/MAP、Bank 空间测量，本助手没有编译/链接 ROM，也没有执行 Git Commit/Push。本轮按用户要求**暂不做交接**。
