> **历史失败候选；`.208` 实机依然停在崖壁，已登记 `ILEX-LEDGE-001` 暂缓。切勿继续应用本文件的共享跳崖方案。参见 [`ISSUE_ILEX_FOREST_LEDGE_DEFERRED_209.md`](ISSUE_ILEX_FOREST_LEDGE_DEFERRED_209.md)。**

# LEDGE-5.62.208｜共用跳崖执行器：强制位移先于落地（候选修复）

> 状态：**仅源码修复候选及静态/离散帧模型验证**。尚未编译/链接完整 ROM，也未得到 `.208` 实机通过证据。`.207` 的实机录像明确显示跳跃后位移不足，不可列为成功版本。

## 1. 为什么现成 Route29 逻辑不能只复制“动画”

- `engine/overworld/ledges.asm:HandleLedges` 已统一进行图块配对/方向识别，调用 `StartSimulatingJoypadStates` 以后将剩余强制方向写入 `wSimulatedJoypadStatesEnd`，使用 `wSimulatedJoypadStatesIndex` 计数。
- 29～32 号道路和原 RPP：首格由当次按键移动，再模拟 **2** 格，总计 **3** 格。
- Ilex Forest：首格由当次按键移动，再模拟 **1** 格，总计 **2** 格；第三格在 10 条方向中有 7 条是摇树，不允许直接延长到三格。
- 旧的 `engine/overworld/player_animations.asm:_HandleMidJump` 动画结束时只判断 `wWalkCounter == 0`，**没有**检查模拟队列 `wSimulatedJoypadStatesIndex` 是否仍非零。游戏在一格完成与下一格强制输入读取之间恰好有 `wWalkCounter == 0` 的帧边界，动画可能在该边界清掉 `wd736.6` 与 `wd730.7`，导致剩余方向不再执行。
- `.207` 只是避免最后一格完成后提前派发普通输入，**没有防住前述格间边界**，且有桐树林专用清空模拟队列代码。`.207` 实机失败与此机制吻合；缺少 CPU/RAM 逐帧记录时，此处仍是最高优先级根因假设，而非完成实机归因。

## 2. `.208` 修改范围（共同执行链）

1. `home/overworld.asm:HandleMidJump`（ROM0 包装器）：若已在跳崖且 `wWalkCounter == 0`、`wd730.7` 模拟仍激活且 `wSimulatedJoypadStatesIndex > 0`，**不调用** `_HandleMidJump`，先让 `JoypadOverworld` 派发下一格。若当前格正在移动，则仍执行原动画；它自己会在 `wWalkCounter != 0` 时拒绝收尾。
2. `home/overworld.asm:OverworldLoopLessDelay`：针对**所有**跳崖（不按地图判断），在 `wWalkCounter == 0` 且跳跃标志仍置位、强制队列已耗尽时，只更新精灵并等待原动画落地；不能提前接收新的普通方向。如果队列尚未耗尽，则必须调用 `JoypadOverworld` 让它派发下一格。
3. 删除 `.207` 针对桐树林的 `wSimulatedJoypadStatesIndex` / `wSimulatedJoypadStatesEnd` 强制清零；继续由原 `_HandleMidJump` 正常关闭 `wd736.6`、`wd730.7`、`wJoyIgnore`。`engine/overworld/player_animations.asm` **完全未修改**，避免填充历史已满的 ROMX 动画 bank。
4. `engine/overworld/ledges.asm` **完全未修改**。仅森林保持一个附加模拟输入，旧道路继续两个；森林跳崖中的 B 加速禁用条件也保持不变。

此修复不新增任何坐标式森林跳崖表，不改森林 Gold 地形、碰撞掩码、落点或其它地图的图块配对表。正常非跳崖移动不受共享跳崖落地门禁处理。

## 3. 检查与不能声称的结果

```bash
python3 -m unittest tools.tests.test_ledge_regression_208 tools.tests.test_johto_rpp_connection_guard -v
python3 tools/ledge_regression_audit.py
```

- **28 项静态与模型/连接测试通过**，其中 `.208` 专项 10 项、连接 18 项；全图资产静态审计错误数为 0，登记原生图块方向 95 条、独立坐标 HOP 16 条。离散帧模型包含一个能重现 `.207` 在首格末提前关闭跳崖的反例，并在不同动画节奏下验证两格/三格的队列消费契约。**模型不是 Game Boy CPU 仿真。**
- 缺少可用 RGBDS 0.5.2 构建工具，尚未提供新的 ROM、MAP 或实机采样。旧 `.206` map 的容量值无法保证 `.208` 能实际链接；本次主要在 ROM0 做收敛，不增加动画 ROMX bank 内容。
- 已知剩余审计：Route33 7 条和 AzaleaTown 9 条仍用坐标式识别，且按两次额外移动执行；它们可能存在第三格越界/越地形问题，**未擅自改其原始落点**。

## 4. 必须完成的真实验收

1. 在真正构建的 `.208` ROM 中，Ilex Forest 三组障碍的 10 个允许方向逐一走。每次观察相对于地形的 **两格** 位移（越过障碍后落在 FLOOR），不应停在中间障碍格；不能继续踩入第三格的树。
2. 每个方向至少验证：正常按方向、持续按方向、按住 B；重复跳、落地立即转向与反向碰撞。影子、精灵、地图滚动一致；落地不能穿墙。
3. **特别抓首格末的内存**：`wWalkCounter`、`wSimulatedJoypadStatesIndex`、`wd736 bit6`、`wd730 bit7`、`wXCoord`/`wYCoord`。预期在首格末仍有 `wSimulatedJoypadStatesIndex=1`，下一帧进入第二格开始前不得清除 `wd736.6` / `wd730.7`。
4. Route29、Route31 三格原生跳崖（包含 B）与 Route33、桧皮镇的方向式/坐标式跳崖抽查；须确认共享动画保护不会破坏历史行为。
5. 项目全量 ROM build/link、MAP bank 容量与手机录像通过后，才能将此候选标记为已修复。

**原则：跳崖长度由地图设定，队列/动画生命周期由公共执行器管理。测试必须覆盖“格间 `wWalkCounter == 0` 但模拟队列仍非空”的边界，禁止将静态 PASS 当成实机 PASS。**
