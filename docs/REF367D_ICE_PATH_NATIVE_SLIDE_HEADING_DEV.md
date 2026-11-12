# REF-367D｜Ice Path 原生滑冰方向状态控制（开发期、未开放地图）

## 基线与范围

- 正式基线：用户上传的 REF-366.zip，分支 `常规功能备份`，HEAD `a95ac8d1ddaf47575bc4f08935033d014bfa58cf`。
- 增量前置：已完整应用 REF-367C 开发候选（包含 A/B 的原始资源和原生地形步骤）。用户目前尚未上传最新手机工作区导出，**不能视为已证实安装**。
- 游戏不变：`REF-366@`、65 张活动地图、172 条注册 Warp。不启用 Ice Path 五图；不修改 `main.asm`、`home/overworld.asm`、`wram.asm` 或地图注册；不编译 ROM。
- Rock Smash 仍延期。Ice Path B1F 必须实现的四块 **Strength** 石头和 PIT 落洞不是 Rock Smash，不能被误删。

## 本次新增的实际原生 ASM

`data/johto_ice_path_stage/ice_path_slide_state_367d.asm` 是下一次接入玩家主循环时可用的 **LR35902 状态转换控制代码**，不是 Python 参考模型：

1. `JohtoIcePathArmSlide367D`：只在**真实移动一格完成后**读取玩家现处 Gold ICE 角色；方向有效则输出新的滑行朝向，否则解除。不能在地图 Warp 到达、继续游戏或落洞自动动画完成时调用它，避免到达 B2F 的 ICE 落点自行滑走。
2. `JohtoIcePathResolveSlide367D`：根据之前保存的朝向调用 REF-367C 原生地形预判；可通行时强制保持原朝向，忽略冰上中途反向输入。遇墙/方向障碍时释放控制，下一次普通输入可选择新方向；**不能绕过玩家 sprite 与 Strength 石头的碰撞**。
3. `JohtoIcePathClearSlide367D`：重置滑行朝向，未来地图切换、掉落、Continue、脚本接管、战斗、Surf 等都应调用。

ABI：输入 B=Y、C=X、D=本次用户意图/最后一步方向、E=由调用者安全保存的滑行状态；输出 A=有效方向、E=新状态，Carry=强制滑行；BC/D/HL 保留。**E 是调用者传入的状态，当前没有分配新的全局存储地址，也未连接玩家按键入口。**

## 重要兼容性检查

- 本项目 `wUnusedD71F` 虽然名字像未使用空间，但 `engine/items/items.asm` 中有两处写入。不能未经追踪就把它用作冰滑方向持久状态。
- 必须在今后接线时选安全的 WRAM 存储位，并明确谁初始化、谁在 Map/Warp/Continue 清零，不得让曾经存盘的旧字节在读档后触发滑行。
- 不能直接在 Joypad 读取后永久覆盖方向：必须在普通输入/碰撞与一步动画完成之间明确协调 A、B、SELECT、START、脚本、跳崖与石头对象碰撞。
- 先测 `JohtoIcePathContinueSlide367C` 再发强制方向，不能无限持续撞墙；当前控制器只处理 Gold **地形**，未来玩家 sprite/Strength 占位检查必须覆盖。

## 审计与测试边界

新增 `tools/johto_ice_path_367_slide_audit.py`：使用 REF-367C 受限 LR35902 解释器执行 **本次 ASM 的真实分支**，五图 3,060 格 × 四方向检查 arming/continued-heading 与阻断；还检查 B2F 的 ICE arrival-only、无效状态、离图禁用，以及早期错误 INCLUDE。新增 `tools/tests/test_johto_ice_path_367_slide.py` 的错误注入与状态机测试；统一入口 `tools/validate_current_project.py` 已调用新审计。

此类 PASS **不能证明** ROM 汇编成功、输入逐帧时序、实机动画、推石/碰撞、掉洞/跨层、Tile/调色/Bank 或实际可玩性。项目规定 AI 不自行编译/链接 ROM。五张图仍未激活；手机无需进入冰之通路测试这一批。

## 下一次真正接入的施工门槛

- 选择明确、无复用冲突的滑行 WRAM 状态；在玩家完整步进与 Warp/Continue/脚本接管路径接入本 ASM，防止中途按键和自动动作互相覆盖。
- 完成独立 Gold Ice Path 图块/Bank/调色加载、五图 Header 和 22 个 Warp 条目的准确 Gold ordinal；B2F 四个 ICE Warp 只作落点，不可主动触发返回。
- 完成 B1F 四块 Strength 石头推入四个 PIT、掉落 B2F 和持久状态，并核对楼梯及 Route44/Blackthorn 出口的方向与自动迈步。
- 以上全部完成并通过强制入口、负向测试后，才开放 R2 供用户新 ROM/MAP 与手机验收。Rock Smash、NPC、遭遇、剧情暂不做。

开发阶段交付遵循 `RPP_PROJECT_CONTEXT/03_PROJECT_REQUIREMENTS.txt`：一个 ZIP 恰好两份互斥正向补丁；不制作 CLEAN、Commit/Push。
