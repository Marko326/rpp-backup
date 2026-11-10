# REF-365C｜城都地图 Warp / Field Moves 入口验收门禁（开发期工具改动）

## 本轮边界与基线

- 来源：用户提供 `REF-365B.zip`（分支 `常规功能备份`、已导出 HEAD `9b3609c5345248d09a6849a393019edbf7869a5e`，工作树已有未提交变更），再准确应用上一轮已交付的 `01_REF365B_当前工作区_到_REF365C_开发增量.patch` 得到本轮 **REF-365C 工作区基线**。
- 用户已反馈 REF-365C 两处修复正常；**本轮不改 ASM、地形、Bank、ROM 版本和任何既有 Warp/Field Move 运行行为**。版本继续 `REF-365C@`，65 活动地图、168 条已注册 Warp；Rock Smash 和四块碎岩对象继续暂缓。
- 修的是测试门禁，而不是把已通过的洞穴另做一套共用运行引擎。

## 上一次为什么没有拦截

1. 自行车审计只识别 `JohtoDarkCaveBikeFloorAllowed349` 的局部地形许可，没有从公众入口 `IsBikeRidingAllowed` 追查地图 ID99 是否进入该分支。ID99 存在却走到普通室内规则。
2. Warp 审计主要看路由表、源 Warp 是否注册、目标坐标；没有强制核对目的地 `JohtoPilotGateArrivalStep` 的实际判定、后续模拟迈步的方向和下一格是否是合法地面。ID99→ID190 落在 `(17,1)` Gold CAVE，却没有自动下走到 `(17,2)`。
3. 更早的非法 `sbc hl,de` 曾被静态审计视为正确指令，说明关键词检查不能替代真实汇编（本轮不改变 ROM 构建权限）。

## 新的强制源审计

`tools/johto_warp_field_entry_gate.py` 已接到 `tools/validate_current_project.py` 的 **迁移主审计之前**，不依赖主审计是否因过期版本合同失败而被跳过。

- 读取真实 `JohtoStableIDToActiveSlot` 和 `JohtoRegisteredWarpRoutes`；对 REF-365C **65 个既有活动 ID 与 168 条既有方向路由采用冻结哈希库存**，后续新增地图不能仅改数量/偷偷加行。新增地图必须独立填写 `new_map_activation_reviews` 的 Bike/Surf/Flash/入口来源规则、实际源码参考及新增负向审计测试路径/函数，新增 Warp 必须在 `critical_arrivals` 登记 `new_route_review=true` 与双端落点逻辑。**原有 168 路由的历史库存不是“全部已完成逐条 ROM 行为验证”的声明**。
- 对黑暗洞穴八条进出路由从注册表和 **运行时 Objects 内的源 ordinal、源坐标、目标 ordinal、目标坐标** 交叉核对；防止只改注册表但对象 Warp 错位。
- 在受限 LR35902 分支解释器中实际沿 `JohtoPilotGateArrivalStep`、`JohtoPilotIsVerticalGatePairMap314`、`JohtoVerticalGateArrivalProfiles314` 的调用路径推导落点停留或 DOWN 自动迈步；两个洞内口不同处理，Route31/45/46 门外 DOWN，洞内地毯原地停留。
- 校验 ID190 的 `(17,1)` 是 Gold CAVE、自动下一格 `(17,2)` 是 FLOOR；ID99 的 `(3,25)` 为 DOWN 地毯，而 `(3,26)` 是墙，因此不得硬套 DOWN。再检查邻近格不能被错误地当成门口。
- 对公众入口 `IsBikeRidingAllowed` 逐地图查到 `.darkCaveBike` 并包含调用 `JohtoDarkCaveBikeFloorAllowed349`，不再只检查该叶子函数存在。
- 独立运行 `tools/johto_dark_cave_365_audit.py` 仍核对 Surf/Flash、地形、双区域角色表、Dig／离洞绳来源，形成互补；新增地图属于其他类型时必须按其真实 Field Move 入口添加专项语义检查，不因已更新 JSON 就自动认为全部技能通过。

## 负向故障注入与范围限制

`tools/tests/test_johto_warp_field_entry_gate.py` 故意注入“删除 Bike 分派、替换 Bike helper、取消自动迈步、洞内地毯错误强制迈步、撤销 Route45 公共门口分派、删除门口落点 Profile、篡改洞内对象源坐标/目标 ordinal、改落地 FLOOR 为墙、未经审核新增地图/路由、误把普通邻格当门”。对应测试应全部观察审计 FAIL，而不是只检查字符串是否存在。

**限制**：这是一个当前实现分支范围内的受限源码指令追踪器，不是 RGBDS、Game Boy CPU 模拟器。对历史其余 160 条路由，冻结清单只证明“没有悄悄改变”，不代表逐条深度验收；对未来新增路线，必须在审计器中扩充实际分派/碰撞/Field Move 语义，不能只添加 JSON 来通过。当前 Surf/Flash/Dig 的深度审计仍主要局限于现有 Dark Cave 专项工具；离洞绳使用后的保存/读取和实机动画仍须设备测试。

## 使用及发布

```sh
python tools/johto_warp_field_entry_gate.py --root .
python -m pytest -q tools/tests/test_johto_warp_field_entry_gate.py
python tools/johto_dark_cave_365_audit.py --root .
python tools/validate_current_project.py --skip-pytest
```

统一验证入口中如果旧主迁移审计因 REF-364 固定计数失败，应如实单列历史失配，不可宣称全量通过；本门禁必须先通过才可继续新地图开发。**本轮没有编译链接 ROM、没有生成新 MAP、不代手机实机、不代 Commit/Push**。交付仍是开发期双补丁 ZIP：01 当前 REF-365C 工作区→本工具版，02 已核实 HEAD→累计包含 REF-365C 的工具版，二选一，不叠加。正式 CLEAN/拆分提交须等用户另外明确要求。
