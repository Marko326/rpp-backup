# CLEAN-5.62.332｜DEV-330～339 Town Map 与 Cherrygrove City Pokémon Center 正式清理交接

**清理日期：2026-11-03。游戏内版本：`REF-332`，不升版；工作分支：`常规功能备份`；确认的最近正式 HEAD：`300e0a4c4afece275db40a09558b5810d7deb8f4`。** 此文件是本轮准备提交的**验收与边界记录**，不是已完成 Git Commit/Push 的证明。下一次收到新导出，应以新的导出 HEAD 为准。

## 1. 用户验收与范围

- 用户明确反馈：**Pokémon → Fly 菜单中 START 定位到最后一次成功治疗地点**，已在手机/实机测试正常。该入口与道具普通 Town Map START 不可混淆；之前 REF331.mp4 展示的就是 Pokémon → Fly，问题在 DEV-338/REF-332 修复。
- 用户较早确认 `Cherrygrove City` Pokémon Center 采用 Gold 风格后、护士可对话；且 **REF-330 的地毯左右移动、朝 DOWN 出门和室内一步一顿卡顿问题已经正常**。REF-331 三处提前返回仅为无 profiler 的分派短路，**不是卡顿修复的验收依据**。
- 现在用户要求停止反复追加修复，按项目模式 A 清理本版并准备 Git 两笔提交。此次清理只更新 README、TODO、规则和本交接文档，不修改任一 ASM、图片、地图资源、存档字段、工具检查逻辑或版本号。
- 该反馈并不意味着 Gold 精灵球动画逐帧、所有旧存档、Teleport、战败复活、Johto 其他城市中心、PC 存储、图鉴 Nest 或三种 ROM 配置均已单独验收。尤其 **Teleport 和战败返回尚未开放**，不应写进本次完成功能。

## 2. HEAD→REF-332 累计功能（第一笔）

- 继承 REF-325 已提交基线的 47 张活动地图与门房/室外通行；本轮新增 `CherrygrovePokecenter1F`（稳定 ID123，活动槽47），总数 **48 张活动地图、107 条 Warp**，原47张顺序不变。复用共享注册、Gold 原版 5×4 专用室内图块/碰撞/配色、双格门毯 DOWN-only 出口、隔柜台护士对话；不改 Kanto 中心原图。
- 依次累计 Town Map/Johto Fly 入口审计与真实功能：`wBuffer` 的29字节可见字符边界与 `@` 结束符；普通城都 Town Map 的地标/最近成功治疗地点定位；城都 Fly START 从**Johto 有效治疗记录**映射至 `Cherrygrove City`，并保留**已开放＋已到访**双门禁、未满足条件时不改变选择；LEFT/RIGHT 特殊轴仅允许有真实落点的 `Lake of Rage`；Kanto Fly 机制保持原路径。
- Johto 护士 Yes 完成 Gold 治疗动画后记录有效稳定 ID，使用独立 Johto 的恢复标记与当地 ID，避免污染 Kanto `wLastBlackoutMap`；Kanto 动画保留。治疗机器 Gold 专用两图块/OAM 坐标单独处理。
- 这些为多个 DEV 累计、尚待正式提交的功能，不可只用最后 DEV-339 工具补丁代表第一笔游戏功能。

## 3. 工具、合同与审计（第二笔）

- Route44/Route45 旧检查器、Gold 地名复制边界、Town Map Item/Fly/Nest 三入口、Gold Center 图像/布局/护士/治疗记录、Warp 到达与移动方向检查，以及故障注入回归。聚合 Gold 综合迁移审计 **1518/1518 PASS**。
- DEV-339 将 `tools/johto_rpp_pipeline.py` 的活动图合同补到 **48 张**，将 `tools/johto_indoor_registration_generator.py` 与 `johto_pilot_door_contracts.json` 的 Warp 预期严格补到 **107 条**，同步 Field Move/Surf/脚本 Bank/存档地名与负向测试；不是简单改一个总计数。
- 本轮 Gold 对照的全仓库 Python 用相同的 `tools/tests/test_*.py` 测试文件分成五组独立运行：**727 passed、49 skipped、0 failed**（另有独立 subtests）。统一入口一次整批 pytest 曾超时，**不能宣称那条超时命令全程通过**。ASM 局部符号预检 2104 文件通过；48图三表均通过。

## 4. ROM/MAP 与设备证据边界

- `REF-332` 导出随包 `patches/rppred.map` 的解析报告显示 **Red ROM0 余 97B**（项目最低64B），作为随包证据保留；审查/清理没有自行 RGBDS 重新链接。
- 这里**没有同版本 Blue/TEST 的独立链接 MAP 证据**，不能从 Red 推出三版同时通过。部分 ROMX 银行布局非常紧：Red MAP Bank `$17` 显示布局余量 0B，但可移动段的空间不是固定可写空间。
- 用户已确认 Fly START 实机正常。尚未取得 Red/Blue/TEST 完整功能/回归证据；新的功能阶段如影响 ROM，应本机编译、检查 ROM0≥64B 与受影响 ROMX，再针对性实测。

## 5. 模式 A 三补丁／两笔提交

1. `01_清理增量.patch`：**已应用 DEV-339 的 REF-332 当前工作树 → 最终清理版**（仅维护文档）。
2. `03_HEAD累计全量.patch`：**干净 HEAD `300e0a4c...` → 完整清理版**（包含 DEV-330～339 累计游戏+工具改动）。**①③互斥，只选一份应用**。
3. `02_工具审计反向隔离.patch`：这是**从仅功能状态到完整最终状态的正向补丁**；在完整清理版上先运行 `git apply -R 02_工具审计反向隔离.patch`，临时撤下 `tools/` 和文档，提交功能；再运行 `git apply 02_工具审计反向隔离.patch` 恢复工具、合同和维护文档，提交第二笔。不要把这个补丁当作①或③的替代补丁。
4. 两笔提交的中文日志随 ZIP 附带，先读并核对本机实际 `git status`。**由用户本机执行 Git Commit/Push**，本清理副本没有替用户提交／推送／构建 ROM。

## 6. 下一阶段（不属于本次提交）

- 以 `Cherrygrove City` 的稳定模板逐座扩展其它 Pokémon Center，先逐一核对 Gold 门口/室内 Warp 和原版资源，不复制 Kanto 的护士动画和相机布局。
- 等有足够真实治疗点记录与安全落点数据后，再规划 Johto Teleport、战败返回和跨区存档兼容；当前不能直接启用。
- 城都 Pokédex Nest 的分布数据、更多 Fly 特殊目的地和 PC 存储服务另作独立专项；只有地图地标并不意味着已开放可飞 Warp。
- 最小交接：确认用户 Git 新 HEAD、最新 Red/Blue/TEST MAP，随后继续开发；不因历史 TODO 中的旧47图数字重新改动当前48图配置。

## 7. 清理复核追加（提交前）

- 对上传的 `REF-332(1).patch` 从相同 HEAD 回放后，对照 DEV-339 完成树的 3,166 个文件**字节全一致**；此前 CLEAN 与用户差异只有 `README.md`、`TODO.md`、`PROJECT_DELIVERY_RULES.md` 及新增本交接文档。
- 发现 Gold 专用治疗动画 `AnimateHealingMachineRegional337` 的 `.johto` 已在成功结束后写入 Johto 最近治疗标记，而旧的 `AnimateHealingMachine` Kanto 路径还保留 `callab JohtoRecordSuccessfulCenterHeal335`。由于 Johto Center 分派先走 Gold 动画，旧调用及对应的旧写入 helper 为冗余，现已删除，源码审计转为验证真正的 Gold 成功路径，同时补上“不得恢复旧调用”的负向测试。
- 另外移除了两处 `if False` 无效工具表达式，修正把 Gold 5×4 写成 Kanto 7×4 的过期源码注释。未触碰已验收的门毯、地图移动、Fly START、Gold 动画坐标、室内资源及存档字段。此清理**改变 ROM 二进制布局**，虽然预期行为等价，仍需本机重新构建并核对 Red/Blue/TEST MAP；不能沿用旧 ROM0/ROMX 报告作为新构建证据。
