# CLEAN REF-365｜Gold 黑暗洞穴双区域与 Warp/Field Moves 门禁正式清理记录

**项目分支：**`常规功能备份`。**用户导出声称并可由 REF-364 源码 + 累计补丁重建的 HEAD 基线：**`9b3609c5345248d09a6849a393019edbf7869a5e`。输入为 `REF-364.zip`、用户的 `REF-365B.zip` 和两轮经验证的 REF-365C 修复／审计补丁；ZIP 中不包含可读取的 `.git` 历史，因此 Git HEAD 真实性仍以用户手机的 `git rev-parse HEAD` 为最后确认。未经手机确认不得宣称已有新的 Git Commit。

**正式游戏标签：**`REF-364@`→`REF-365@`（开发末版 `REF-365C@` 去掉字母）；无其他运行逻辑变化。65 张活动地图，168 条已注册 Warp。功能提交在工具隔离状态下仍含双区洞穴、3 室外门口、2 内部方向、Surf/Flash/Bike/HOP、方向墙、Dig／离洞绳与 ID99→ID190 到达自动迈步；工具提交单独涵盖 `tools/` 的静态审计、故障注入和项目维护文档。Rock Smash 技能及四块碎岩石不做；NPC、遭遇、道具和剧情不做。

## 手机实测范围和剩余风险

用户已在 REF-365C 阶段反馈洞内返回后自动迈步与烟墨侧自行车“没问题”，此前 REF-365B 的 Route45 室外双向进出亦有用户实测反馈。**不能据此扩张为全部 ROM 版本或三入口 Dig/离洞绳已验收。** 需要用户使用 RGBDS 0.5.2 构建 Red／Blue／TEST Red／TEST Blue 四版新 ROM 和 MAP；逐版审查 ROM0≥64B、Bank `$03/$04/$0F` 余量、链接和地址。旧 REF-365B MAP 的 ROM0 125B 不代表 CLEAN REF-365。还应从 Route31／46／45 分别进入、跨区使用 Dig 和 Escape Rope、Save→Continue、旧档无锚点，确认仍返回该室外路口而非治疗中心。其它地图的旧回归与 Flash/Surf/跳崖抽查也应在手机上完成。

## 本轮真实静态检查与测试（在 REF-365C+审计源码候选运行，最终仅更改标签和清理文档）

- `python tools/johto_warp_field_entry_gate.py --root .`：**60 通过、0 失败**；源到目标 Objects ordinal、Warp 路由、到达动作、下一格 Gold 地形、Bike 公开入口与新增地图登记门禁。
- `python tools/johto_dark_cave_365_audit.py --root .`：**57 通过、0 失败**，限定为源码审计；在 CLEAN 改版时更新其版本断言到 `REF-365@`。
- `python -m pytest -q tools/tests/test_johto_warp_field_entry_gate.py tools/tests/test_johto_dark_cave_365.py tools/tests/test_johto_bike_route29_route32_252.py tools/tests/test_ref355_flash_dark_cave_only.py tools/tests/test_rom0_relief_349.py`：**57 passed / 4 skipped**。
- `python tools/validate_current_project.py --skip-pytest`：局部符号预检 **1852 ASM** 通过；活动表长度（65）、城都 Warp/Field Moves 新门禁（60）、黑暗洞穴（57）通过；**current migration audit 1529 通过、15 失败，总检查 1544**，因历史旧地图数、旧 Warp 数、Route45 门口、旧内部入口封闭假设和 Surf Manifest 等过期合同，与现行 65/168 不符，不声称统一主审计通过。
- `python -m pytest -q tools/tests`：**930 passed、51 failed、189 skipped、95 subtests passed**；多项既有旧版地图清单／Surf Manifest／Stage2 固定基线不再适配新增 ID99，另有不依赖本期功能的旧夹具失败。没有修改核心 ASM 来强行消除这些失败；逐项输出由运行日志记录，后续单独更新历史合同。

### 旧检查器漏检和新检查

1. 旧 Bike 审计只看专用 FloorAllowed helper 已包含 ID99，没有沿玩家公开 `IsBikeRidingAllowed` 的实际分派追查。新检查器执行局部 ASM 分支检查，并通过移除 ID99 分派／替换 helper 的故障注入要求 FAIL。
2. 旧 Warp 审计只核对路由、坐标和目标 ID，没有验证目的地自动迈步及安全格。新检查器沿 `JohtoPilotGateArrivalStep` 跟踪分支，区分 ID190 `(17,1)` 需要向下至 `(17,2)` 与 ID99 `(3,25)` 下一格为墙；人为删迈步、换错 ordinal、改目标地面为墙均必须 FAIL。
3. 曾有不合法 LR35902 指令 `sbc hl,de` 被关键词审计接受的问题；独立黑暗洞穴测试现使用坐标行偏移解释和负向注入，但仍不能取代 RGBDS 真正的 ROM 汇编与链接。

### 后续新增地图必须遵守

运行 `python tools/johto_warp_field_entry_gate.py --root .`、黑暗洞穴/Gold 对照和统一 `validate_current_project.py`；新增地图激活或 Warp 时必须维护公开 Bike/Surf/Flash/Dig 分派、源与目标地毯/门碰撞、自动步进与下一个格地形、错误方向和防反复传送。历史 168 路中，只有黑暗洞穴八条获得新增的深度静态验收，其余只是冻结库存。完整连接可见范围、地图边界、ROM Bank 和跨图屏幕背景仍要配合设备检查，不得把静态 PASS 当实机 PASS。

## 正式模式 A 应用顺序与 Git 操作边界

单 ZIP：`01` 清理增量（已应用 REF-365C 游戏修复但**未**安装新 Warp／Field Moves 审计门禁 → 最终 CLEAN）；`02` 工具及文档反向隔离（最终 CLEAN → 功能提交状态）；`03` 基线全量（已核实 REF-364 HEAD → 最终 CLEAN）；`04` 功能提交日志；`05` 工具提交日志。

- 使用前必须先在 Termux 确认 `git status --short` 和完整 `git rev-parse HEAD`，无其他未导出工作区变化。增量与全量只能选其一：当前 REF-365C 游戏修复状态使用 01；完全干净 REF-364 HEAD 才使用 03。**如果已经安装了新增的 Warp/Field Moves 审计门禁开发补丁，此 01 的基线不适用；应先核对差异，不能强行应用。**
- 先 `git apply --check 01.patch` 再 `git apply 01.patch`，或干净 HEAD 选择 03。获得完整 CLEAN 后，对 02 执行 `git apply --check 02.patch && git apply 02.patch`，确认运行 ASM 和版本不变，按 04 的标题/正文自行执行第一笔 `git add`/`git commit`；然后 `git apply -R --check 02.patch && git apply -R 02.patch` 恢复工具审计和相关文档，按 05 再提交第二笔。
- 用户自行 Commit/Push；AI 不提交、不 Push，不编译/链接游戏 ROM。本记录是正式**提交准备**，不是可跳过 ROM/MAP/存档最终验收的许可。
