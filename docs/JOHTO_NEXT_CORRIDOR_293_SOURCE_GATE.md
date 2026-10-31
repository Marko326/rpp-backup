# MAP-5.62.293 — 37号路 / 圆朱市共用基线与38号路西线资源准入

## 本批真实交付边界

这是 **Gold 原始地图源资产 + 旧 NPC 成熟碰撞参考 + fail-closed 迁移审计**。这是下一批运行开发的可复现准备，不是已经开放的地图。当前游戏 **FIX-5.62.290 / TEST-231**、26张活动地图、原有20条有向连接、全部运行时 Warp 和所有 ROM Bank 均未修改。37号路北接圆朱、36号路北上37、圆朱西门以及38号路仍未在运行系统中开放；没有生成ROM/MAP，也没有修改玩家本机的Git仓库。

### Gold 与成熟参考来源

| 地图 | 固定ID | 原图大小 | Gold图块集 | Gold候选阻挡 | NPC成熟掩码 | 准入结论 |
| --- | ---: | ---: | --- | --- | --- | --- |
| Route37 / 37号路 | 21 | 10×9 = 90B | JOHTO | 54B | 54B | 逐位一致 |
| EcruteakCity / 圆朱市 | 22 | 20×18 = 360B | JOHTO | 180B | 180B | **2格不同** |
| Route38EcruteakGate / 圆朱西门房 | 23 | 5×4 = 20B | GATE | 16B | 交接包未提供同名成熟掩码 | 保留为审查项 |
| Route38 / 38号路 | 24 | 20×9 = 180B | JOHTO | 90B | 90B | **4格不同** |

- 圆朱市两种掩码的不同角色格坐标是 `(36,26)`、`(36,27)`；38号路是 `(1,10)`～`(1,13)`，坐标以每个16×16角色格为单位。**不可擅自假设Gold原始阻挡比成熟版正确**，必须结合实际地形/门房及旧验收记录审查后才进入运行碰撞。
- 圆朱市有Gold原版15个 Warp 和20个水格，未来启用城区时必须对未接入的建筑保持关闭，并完整审核Surf及Fly到访/安全落点；37号路有6个跳崖候选；38号路有24个跳崖候选、2个Warp；其故事/NPC等尚未移植。
- Gold `Route38EcruteakGate` 复用 `maps/EastWestGate.blk`，不可虚构一个名为 `Route38EcruteakGate.blk` 的原版文件。门房西侧路口不是通常的地图最外缘，旧成熟分支 `.230` 明确指出必须由 `ExtraWarpCheck` 实际调用精确方向出口检查，否则可能出现只能出不能回。

### 经 Gold 批量工具验证的连接

| 有向连接 | Gold偏移（块） | 运行状态 |
| --- | ---: | --- |
| Route36 NORTH → Route37 | +10 | 关闭，待双向执行/屏幕预览审计 |
| Route37 SOUTH → Route36 | −10 | 关闭 |
| Route37 NORTH → EcruteakCity | −5 | 关闭，**窄图接宽图的可视条带风险** |
| EcruteakCity SOUTH → Route37 | +5 | 关闭 |
| EcruteakCity WEST → Route38 | +5 | 关闭，必须先验证西门房和行走边界 |
| Route38 EAST → EcruteakCity | −5 | 关闭，必须先验证门房的方向性Warp |

参考 `REFERENCES/NPC/NPC-5.62.243/docs/JOHTO_FIXED_IDS_AND_BRANCH_POLICY_zh.md`：先完成 Route37/圆朱市（ID21/22）的共用基线，再分西线 Route38门房/Route38（ID23/24）。**地图可见范围与玩家真正可通过的范围必须独立审计**，不因Gold连接存在就提前放行。

### 后续真正激活前必须完成的代码审查（不能省略）

1. 真实活动表按原序追加，不能重排已有26槽；`NUM_JOHTO_ACTIVE_MAPS`、稳定ID映射、Header/BANK/script/object、源/运行资源和四向连接注册必须同步，并有错误注入。
2. Route36北口以及 Route37/圆朱南口逐方向确认精确可过的格子、相反方向、Gold连接偏移和窄宽显示条带的源行/目标/WRAM上限，不得跨ROM Bank直接解引用错误地址。
3. 新地图必须实际进入ROM0→ROMX碰撞入口与图外边界、跳崖过程和骑车共用判定；成熟阻挡掩码不一致的格子先逐格核对。角色踩进地图外缘必须由合法连接/Warp接受，否则停止。
4. 圆朱市正式Fly落点、到访标记、Town Map、地名牌、音乐延续、屋顶和昼夜调色、Surf上岸及未开放房门单独验证；38号路西门房出入左右/骑车/返程必须对准目标0-based Warp编号，旧分支 `.229/.230` 的历史回程缺陷必须能被回归测试发现。
5. 对全部新连接调用 `johto_active_seam_coverage_gate_291.py` 加入**独立审查合同**，包括N/S窄接宽、E/W矮接高。新连接出现但未审核必须FAIL，不许为绿灯删除旧测试。
6. 本机新Red/Blue/TEST的RGBDS链接成功、新MAP的ROM0至少64B、相关ROMX剩余空间及实际手机正反方向/步行/骑行/四角滚屏/保存恢复通过，才可标为设备验收。

### 可复现脚本

```
python tools/johto_next_corridor_source_gate_293.py --project .
python tools/johto_next_corridor_source_gate_293.py --project . --gold-root /path/to/pokegold-master
python tools/johto_rpp_pipeline.py --gold-root /path/to/pokegold-master --project . --output /tmp/next-corridor --adjacent-chain Route36 Route37 EcruteakCity --preview-limit 0
python -m unittest discover -s tools/tests -p 'test_johto_next_corridor_source_gate_293.py'
```

脚本不自动修图，也不能证明脚本执行时已具有运行时安全。它在候选原图、稳定ID、Gold偏移、候选掩码或“未经批准提前注册活动地图/连接”被破坏时直接报错。完整迁移总审计会调用这个源资产门禁；未来真正要开放地图时，必须以新的运行时审计替换“保持未开放”的断言，**不能只删除禁用检查**。
