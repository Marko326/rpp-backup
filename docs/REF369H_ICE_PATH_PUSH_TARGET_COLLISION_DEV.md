# REF-369H@｜冰之通路 B1F 怪力推石目标格碰撞修复（开发候选）

## 用户实测与根因
用户 REF-369G 实机截图 `67707.png` 显示可推动黄色石头可以挤入不可推动的岩石/固定墙。玩家踩 B1F PIT 不能下落，是项目已知未开放的独立问题，本轮保持未开放。

`engine/overworld/player_state.asm` 的 `GetTileTwoStepsInFrontOfPlayer` 会查阅玩家前方 **两格**的画面 tile（`aCoord`），但返回的 D/E **只前进一格地图坐标**，即当前待推石头所在位置。REF-369B `JohtoIcePathB1FCheckPush369B` 直接将 D/E 送给 Gold B1F `JohtoIcePathB1FRoleAt367K`，因此检查了石头当前的 FLOOR，而没有检查推后目标。四块初始石头都处于 FLOOR，沿至少一个方向紧邻 Gold WALL：例如 (11,7) 向左是 (10,7) WALL，原路径错误放行。

## 本轮运行代码修改
仅修改 ROMX `data/johto_ice_path_stage/ice_path_b1f_runtime_367k.asm` 中的推石检查：

1. 仍调用 stock `predef GetTileTwoStepsInFrontOfPlayer`，保留现有可视 tile 预取和 `$ffdb` 朝向标志。
2. D/E 仍为一格前方的石头当前位置；再按 `$ffdb` 位 0/1/2/3 对应下/上/左/右，把 B/C 目标 Y/X 再前进一格，然后交 Gold 原始 20×36 `.roles.bin` 判断。
3. 只接受 FLOOR、ICE、尚未占据的原版四处 PIT；WALL、方向墙、楼梯、非四处 PIT、地图外、已填坑不允许推入。沿用 `CheckForBoulderCollisionWithSprites` 的跨 Bank carry ABI 拒绝其他对象/石头重叠，未改其他地图的通用怪力算法。
4. 未知朝向直接 fail closed；保留原 `wTileInFrontOfBoulderAndBoulderCollisionResult` 0/$FF 接口。四石头、落洞动画/事件位、B2F 落石、存档迁移、保存花屏修复、外围岩石边界、滑冰和楼梯均不改。玩家自己踩洞仍未实现。
5. ROM0/BANK0 代码、WRAM/SRAM 长度、地图 `.blk`、Gold role bytes 均没有修改。因不能自行编译 ROM，ROMX 空间及各版本 MAP 状态必须由用户构建后确认。

## 审计与负向用例
新增 `tools/johto_ice_path_boulder_target_369h_audit.py`，接入 `tools/validate_current_project.py` 在旧历史迁移审计之前运行；并加入 `tools/tests/test_johto_ice_path_boulder_target_369h.py`。

- 核对真实 `CheckForCollisionWhenPushingBoulder` → Ice Path runtime 入口、`GetTileTwoSteps...` 的 DE 一格 ABI、朝向位与二次 Y/X 位移、后置 Gold role lookup、sprite 及 PIT 状态阻挡。
- 对四块初始石头分别回归紧邻固定墙方向；另查合法 FLOOR 推动、四 PIT 初次/二次占据、边界、`20×36×4` 次参考规则判定。
- 故障注入覆盖丢失二次位移、上下/左右朝向位交换、四个方向位移颠倒、未知方向放行、漏 Gold role、漏精灵碰撞、相反 carry 判断和已填坑反向判定；每项必须被审计器拒绝。
- 原 REF-369B 检查只见 `predef` 后接 `JohtoIcePathB1FRoleAt367K`，未验证 D/E 实际语义以及目标位置。因此此前静态门禁通过却漏掉了现场穿墙。

## 手机最小验收与未解决项
从 REF-369G 开发工作区打 01 增量，或从已确认 REF-368 Git HEAD `935b3fa738dce42f22768e94c92c920bb5b86d89` 打 02 全量；两个补丁互斥不可叠加。验证 Options 显示 REF-369H。

1. 在 B1F 推石头贴向固定灰岩石、普通墙壁、地图边界：必须停在前一格且不重叠。
2. 四个方向试推至少一次；可行的 FLOOR/ICE 格仍能推；两个可推动石头互相顶住时不能合并。
3. 把一块石头推进未填 PIT：应执行原 REF-369G 落洞演出，B2F 对应位置显示石头；已填 PIT 不得再吞石。
4. 保存、退出、读档及 B2F 保存返回花屏、外围岩石边界做轻量回归；使用备份 SAV，不要沿用已被错误推入墙里的坏现场状态。

**待办：** 玩家自身 PIT 下落、四块全部实际推动与四 PIT 全部存读档、ROM/MAP 空间及四 ROM 构建、历史总审计旧 35 项失败等，仍需下一阶段处理。静态测试不等于手机验收。

## 基线、交付
正式分支来自用户交接记录 `常规功能备份`，最近一次可重建正式 REF-368 HEAD `935b3fa738dce42f22768e94c92c920bb5b86d89`；本轮没有新的 Git 项目 ZIP，因此不把开发包推定为新 HEAD。REF-369G@ → REF-369H@；开发阶段只交一个 ZIP/两份互斥正向补丁，不制作清理日志、不自行编译或提交 Git。
