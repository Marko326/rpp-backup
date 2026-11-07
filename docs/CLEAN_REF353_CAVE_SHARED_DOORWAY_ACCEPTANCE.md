# CLEAN REF-353｜山洞共用普通房门转场：录像复查、正式清理与交接

## 1. 实际输入与 Git 基线

- 实际已提交 HEAD：`d5c2bba00ad769b8fbab0cc749578f1826601446`，分支 `常规功能备份`，来自用户 `REF-352.zip` 的 `RPP_PROJECT_CONTEXT/02_EXPORT_INFO.txt`；ZIP 内是干净源码、没有 `.git` 本地工作库。游戏显示 `REF-352@`。
- 真实待提交工作树：用户 `REF-353.patch`，头部明确 `RPP-BASE: d5c2bba00ad769b8fbab0cc749578f1826601446`，相对该基线共15个文件，`git apply --check` 和回放通过。游戏显示已升级 `REF-353@`。
- 两个新暗洞表指针在用户补丁内均为 `FadePal...353 + 11`，已包含上轮最小热修。`REF353_洞穴进出统一房门_开发候选.zip`、`REF353_暗洞出门残影_渐暗指针热修候选.zip` 均不得叠加到此工作区。

## 2. 功能与保留范围

- `home/overworld.asm`：正常进出 Rock Tunnel / Johto Dark Cave 与普通房门一样黑渐暗、开启 `hMapLoadVRAMSafeFlag`、用 LCD-on 安全地图加载；不再由 `wMapPalOffset`/Flash 状态选择 LCD-off 造成白闪；移除 Rock Tunnel 入口额外一遍淡黑。
- `home/fade.asm`：已暗洞穴依据当前 BG/OBJ 的暗度选择单调变暗的表，原四阶段、每阶段八帧；每条倒序查表必须从第四行末尾 `+11` 开始，确保结束全黑。正常亮场仍使用 REF-351B RGB555 渐暗。
- `engine/johto_pilot_runtime.asm`、`engine/johto_dark_cave_stage2.asm`：未照亮暗洞出洞时不提前强制整屏白色；在目的图块/主角精灵完成前不恢复目标调色板。Flash 只控制洞穴明暗，不更改安全上传路线。
- REF-352 房门提速、CGB HBlank DMA、STAT 安全双字节图形复制、音效/音乐代码、地图/Warp/存档格式、特殊 Warp、战斗返回和启动原路径都保持不变。
- 本次 CLEAN 只整理维护文档。开发期与用户录像一致的 ASM/测试/审计脚本不再编辑。

## 3. 用户录像的验收范围

视频：`353修复.mp4`，160×144、约59.94fps、1511帧，约25.51秒。逐帧分析的是实际进入/离开 Rock Tunnel 的普通 Warp，而不是菜单和 HM Flash 动画。

| Warp方向 / 状态 | 完全纯黑区间（含首尾） | 时长 | 画面结果 |
|---|---|---|---|
| 进洞1（尚未用Flash） | 129–145 | 17帧 | 正常洞穴首帧、无白闪 |
| 出洞1（未用Flash） | 238–257 | 20帧 | 室外新地图与人物正常，无旧图残留 |
| 进洞2（尚未用Flash） | 343–359 | 17帧 | 无白闪 |
| 出洞2（未用Flash） | 452–471 | 20帧 | 无角色残留 |
| 进洞3（尚未用Flash） | 565–581 | 17帧 | 无白闪 |
| 出洞3（用Flash后） | 967–986 | 20帧 | 无白闪或贴图残留 |
| 进洞4（尚未用Flash） | 1078–1094 | 17帧 | 无白闪 |
| 出洞4（用Flash后） | 1409–1428 | 20帧 | 无白闪或贴图残留 |

从录像可见的纯黑到地图恢复，各个新画面均先显示完整地图及人物；**不声称单一视频证明所有模式/洞穴/音频兼容**。视频中 698–719、839–878、1162–1183、1280–1319 号附近的大范围白画面来自菜单/Flash 技能阶段，非普通进出洞 Warp 时段。

## 4. 静态与回归检查（源代码级）

- `python -m pytest -q tools/tests/test_cave_doorway_unified_353.py tools/tests/test_doorway_cgb_rgb555_fade_351b.py tools/tests/test_doorway_fast_copy_351c.py tools/tests/test_doorway_lcdon_copy_pair_351a.py tools/tests/test_johto_dark_cave_stage2.py`：**74 passed**。
- `python tools/validate_current_project.py --skip-pytest`：ASM局部标签**1850文件**、活动表ASSERT **3项**、主迁移审计 **1538/1538 PASS_STATIC_ONLY**，未把全量pytest声称为通过。
- `python tools/johto_rom0_space_preflight.py --root .`：**PASS_STATIC_ONLY**，未重链接。本环境缓存的 Red MAP 属 REF-352，读到 ROM0 余 **213B**，只可用于历史预算参照，**不能当作 REF-353 新编译的容量证明**。
- 使用 `git apply --check` 与正向/反向补丁回放、改变文件和 Git 执行权限、SHA-256 比对，确认 `01/02` 两种应用方式都精确到达同一最终状态。

### 为何原检查漏检、如何防止回归

首版 `REF-353` 只检查渐暗例程/调色表存在、阶段数及内容，没有模拟 `GBFadeDecCommon` 每阶段三次 `HLD` 的**倒序读取指针**；从 `+2` 取值会读进相邻渐暗表，末尾不是全黑，LCD-on 安全上传就会显露混杂的新旧画面。新 `test_cave_doorway_unified_353.py` 既检查 `FadePalDarkBG353` 和 `FadePalAlreadyDark353` 的入口指针 **严格为 `+11`**，又检查按倒序执行的四行内容、BG/OBJ 单调变暗、最终全 `FF`、守卫在主角图形装载后才释放。后续修改表的方向、长度、阶段数或函数前置条件都必须重新核实真实读取顺序，不能只检查表格存在。本轮在独立临时故障注入中将 `FadePalDarkBG353 + 11` 改回 `+2`，指定专项测试按预期失败；再把 `PlayMapChangeSound` 最终的安全加载标志写入移走，同一合同测试也按预期失败。两项注入测试后均恢复原始源码字节。

## 5. 尚需用户本机完成

- 使用 RGBDS 0.5.2 构建 Red、Blue、TEST Red、TEST Blue 并拿到与 `REF-353@` 相符的新 MAP；检查 ROM0≥64B、各 ROMX 银行余量。本次没有构建 ROM 或发布新 MAP；REF-352 旧 MAP 不具证明力。
- My OldBoy/设备专项：Johto Dark Cave 的 Route31/Route46 双入口各做 Flash前后进出，检查紫色暗场不突然亮、BG/OBJ、地名、音乐连续；普通房门 REF-352 速度是否保持；不同模式、菜单、战斗、Warp Pad、旧存档、音频尚需回归。
- 实际 Commit/Push 必须由用户在自己的 Git 工作树完成；这个 ZIP 是可用的**提交准备材料**，不是已提交的 Git HEAD。

## 6. 清理三件套与一次提交顺序

用户特批沿用 REF-352 的提交方式：**游戏源码、测试工具与文档一次提交，不分第二批、没有隔离补丁**。

1. **`01_已打REF353工作区_到_正式清理.patch`**：只有用户已经应用本次 `REF-353.patch` 的工作树才用它，补齐正式文档，不重装功能。
2. **`02_干净HEAD_d5c2bba0_到_正式REF353.patch`**：只有项目仍处于上述已确认的干净 REF-352 HEAD 才用它，直接安装全部 REF-353 功能、测试工具与正式文档。
3. **`commit-message.txt`**：一次提交用的完整日志，只描述最终净增功能、兼容约束及项目版本，不包含测试数字。

`01`、`02` 是互斥替代路径，**切勿叠加**。应用对应补丁、检查工作树后，只创建一次 Commit；不要应用任何历史开发补丁或工具隔离包。
