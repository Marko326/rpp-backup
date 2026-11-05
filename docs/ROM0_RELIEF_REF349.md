> **历史开发预算说明（已完成）**：下列67B→约381B是 REF-349 阶段的静态估算，不是当前 MAP。后续 REF-350 已完成且用户最新 Red/Blue MAP 实测 ROM0 均为 **421B**，实机指定路径已反馈通过；见 `CLEAN_REF348_ROM0_FINAL_ACCEPTANCE.md`。

# ROM0-RELIEF-349｜REF-348 HOME helper 迁移

## 基线与目标

- 源码：用户提供的 REF-348 项目包（跳崖/落洞专项修复工作副本）。
- 容量基准：`MAP_20261105_202506.zip`，Red 与 Blue 的 ROM0 各余 67B；ROMX Bank `$2A` 余 `$3c40` = 15,424B。
- 目标：一次性净释放至少 250B，不改游戏行为、不升游戏版本、不碰碰撞/中断/地图加载热路径。

## 迁移清单与预算

| Helper / 数据 | REF-348 MAP 原占用 | 迁移后的调用增量 | 预计净释放 |
|---|---:|---:|---:|
| `IsBikeRidingAllowed` + `BikeRidingTilesets` | 97B | 3个 near caller 改 far call，+9B（另一个 caller 已是 farcall） | 88B |
| `CheckIfInOutsideMap` | 32B | 3个 near caller 改 far call，+9B | 23B |
| `PartyMenuInitState` | 70B | `PartyMenuInit` 改 tail `jpba` +6B，两个调用点 +6B | 58B |
| `GetMachineName` + TM/HM 前缀 | 77B | `GetItemName` +5B，`GetName` wrapper +12B | 60B |
| `PlayTrainerMusic` + 分类表 | 91B | 两个 tail `jpba`，+6B | 85B |
| **合计** | **367B** | **约53B** | **约314B** |

静态预计 ROM0 从67B提高到约381B。Bank `$2A` 预计新增约367B，剩余约15,057B。由于没有 RGBDS 工具，本轮不生成新链接 MAP；最终值以用户 Red/Blue/TEST 新 MAP 为准。

## 行为与 ABI 保护

- `CheckIfInOutsideMap` 仍以 Z 标志表示室外；其 Johto 分支继续调用 `JohtoPilotGetOutdoorFlag`，结果从 E 读取。
- `IsBikeRidingAllowed` 仍以 Carry 表示允许骑车；Gold 门房稳定 ID 白名单、`$f4` 掩码及 Kanto/tileset 旧规则未改。
- `PartyMenuInitState` 的状态初始化指令主体不变。`PartyMenuInit` 先照旧切 Bank 1、加载 HP/status 图形，再 tail-farcall；Battle/Summary 两个调用点改为 `callab`。
- `GetMachineName` 主体及 `BikeRidingTilesets`、TM/HM 前缀、训练师分类表均与读取代码同处 Bank `$2A`。`GetName`/`GetItemName` wrapper 保存必要的 AF/BC/HL；DE 由既有函数及 Bankswitch 保留。
- `PlayTrainerMusic` 与 `FemaleTrainerList`/`EvilTrainerList` 同 Bank；`jpba` 结束时由 Bankswitch 恢复调用方 Bank。音频例程继续在当前 Bank 状态下调用原有 `PlaySound`/`PlayMusic`。
- 每个关键符号均有 `ASSERT BANK(...)`；调用点不再保留 near `call`/`jp`。

## 静态验证

- `tools/tests/test_rom0_relief_349.py`：4项通过，覆盖 Bank/表同Bank、far-call 调用点、返回标志/寄存器合同和禁止残留 near call。
- `test_johto_bike_route29_route32_252`：4通过、4跳过（Gold/MAP输入缺失导致跳过）。
- `test_johto_gate_music_bike_259`：10通过、1跳过。
- `test_johto_gate_music_continuity_282`：8通过。
- `test_johto_east_runtime_gate_300`：1跳过（缺完整 Gold 与 NPC Stage-77 参考根目录）。
- `tools/johto_gate_music_bike_audit.py --project .`：563项静态检查通过。


- 全量 Python 测试：修改后运行779项，40 FAIL / 8 ERROR / 141 SKIP；在未修改的 REF-348 基线副本运行774项，**同样是40 FAIL / 8 ERROR / 141 SKIP，失败与错误测试名称集合完全一致**。本次新增的5项 ROM0 迁移测试全部通过，未引入新的全量测试失败。旧失败主要是历史审计合同仍固定在较早地图数量/ Warp 数量/版本标签，与当前 REF-348 状态不一致。

## 尚未完成的验收

1. 用户本机 `make red`、`make blue`、`make test-red`、`make test-blue` 或项目规定的对应构建，生成新的 Red/Blue/TEST MAP。
2. 确认 ROM0 至少64B，实际净节省是否接近314B；确认 Bank `$2A` 没有 section/linker 冲突。
3. 实机回归骑车规则、Fly/Teleport室外限制、START/Battle Party路径、TM/HM显示和训练师遭遇音乐。
4. 不编译/链接 ROM、不 Commit/Push；游戏显示版本保持 REF-348。
