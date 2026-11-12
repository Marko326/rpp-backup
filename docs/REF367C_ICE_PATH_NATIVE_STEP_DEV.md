# REF-367C｜冰之通路 Gold 原生地形前进一步判定（开发候选，尚未激活）

**基线**：用户导出的 `REF-366.zip`，分支 `常规功能备份`，正式 HEAD `a95ac8d1ddaf47575bc4f08935033d014bfa58cf`。在上一轮 REF-367B 的开发状态上继续开发；用户是否已安装 A/B 尚无最新工作区导出证据。游戏继续显示 `REF-366@`，65 张活动地图、172 条注册 Warp。

## 实际新增

- `data/johto_ice_path_stage/ice_path_step_runtime_367c.asm`：使用已暂存的 `JohtoIcePathGoldRoleAt367B` 角色读取函数，对 Gold 五张地图执行原生 LR35902 前进一步地形判定：检查起始 `WALL/PIT`、向上离开 `UP_WALL`、方向墙进入限制、`HOP_DOWN` 和 `HOP_DOWN_LEFT` 的方向性、`ICE` 连续移动资格，以及 **只有 B1F 的 PIT** 可被标为掉洞入口。输入 `B=Y/C=X/D=方向`，输出 `A=0` 阻挡／`1` 普通通过／`2` 冰面／`3` B1F 落洞，Carry=是否允许，原样保留 BC/DE/HL。不会实际移动玩家、改变地图或触发 Warp。
- `JohtoIcePathContinueSlide367C` 仅在玩家**已站上 ICE**、旧方向的下一格可通行时允许继续滑动；如果前方阻挡就不继续，避免每帧重复撞墙声。实际游戏集成仍需保存滑行方向，不能把当前 Joypad 新输入当作滑行方向。
- `tools/johto_ice_path_367_native_audit.py` 使用受限 LR35902 指令解释器运行上述**实际 ASM 分支**，用五张 Gold 角色表交叉检查 3,060 格 × 四方向，以及所有冰格继续滑行分支、越界与未开放地图。加入非法指令/错误方向/不合法的 PIT 反向和提前链接的负向测试。该解释器将角色读取函数作为已验证的数据查询，不是完整 ROM/CPU 模拟器；另做 `JR` 大致字节位移检测，不取代 RGBDS 正式汇编。
- 新检查已接入 `tools/validate_current_project.py`，必须与现有 Gold 地图、机制模型和 Warp 入口门禁一起验证。

## 必须明确的边界

原生判定**尚未链接 ROM**：不修改 `main.asm`、`home/overworld.asm`、任何活动地图/注册 Warp/图形加载器/`wram.asm`，不消耗 ROM0。这是从独立 Python 行为模型走向目标 CPU 原生 ASM 的一批实质代码，**不是已在游戏中滑冰**。

下轮才可在全部条件具备时真正连入玩家输入/碰撞：保持冰面惯性方向的 WRAM 状态、B 键和菜单处理、逐帧动画、HOP 双格跃迁、四块 Strength 占位与落洞状态、B1F `PIT`→B2F 的单向传送/动画/保存，以及独立 Gold ice_path 图块载入/调色、五图 Header/22 Warp/Route44 与 Blackthorn 双外口和 Dig/Escape Rope 安全返回。地图未完善时不能为了测试而提前开通；`B2FMahoganySide` 的四个 ICE 落地 `warp_event` 永远不是逆向主动入口。

NPC、野外遭遇、剧情、普通物品与 **Rock Smash** 仍暂缓。**Strength 四块石头不属于 Rock Smash，必须在真正开放 Ice Path 之前完成**。

## 验证层级

`python tools/johto_ice_path_367_native_audit.py --root .` 仅验证 ASM 的有限指令分支和 Gold 格子语义；`python tools/johto_ice_path_367_stage_audit.py --root .` 校验 Gold 资源及不提前激活；`python tools/johto_ice_path_367_movement.py --root .` 校验高层模型；`python -m pytest -q tools/tests/test_johto_ice_path_367_native.py` 包含错改指令、错改方向等负向检查。不能将这些 PASS 宣称为 RGBDS 编译、ROM/MAP 或手机验收。项目禁止 AI 代用户编译/link ROM；用户完整运行后以四版新 ROM、MAP 的 ROM0≥64B、真机滑冰/推石/落洞/出入及 Save/Continue 作为 R2 验收门槛。

## 交付

仍按 `RPP_PROJECT_CONTEXT/03_PROJECT_REQUIREMENTS.txt`：一个 ZIP 仅包含两份**互斥正向补丁**。`01` 仅适用于已经安装 REF-367B 的开发工作区，`02` 适用于经用户确认的干净 REF-366 Git HEAD。开发阶段不预先制作 CLEAN/提交日志，不 Commit/Push。使用前必须在用户真实工作区执行 `git status --short` 和 `git apply --check`。
