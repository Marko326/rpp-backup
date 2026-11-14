# REF-368E｜冰之通路五张地图自行车覆盖复核（开发测试；审计增强）

## 结论

本批以用户当前 REF-368D 源码为起点，**没有发现某张冰之通路楼层遗漏 Bicycle 入口**，因此**不改变已存在的游戏运行 ASM、Gold 图、Warp 或版本显示标签**。原有 REF-368D 的 `IsBikeRidingAllowed` 在当前 Johto Map ID 上分别分派到五张地图的 Gold role 检查函数，入口可通过 Bag / SELECT，换图的骑车贴图刷新也复用同一公开许可判断。

Gold 原始 role 图的允许新上车位置（来源固定为 `docs/REF367A_ICE_PATH_GOLD_SOURCE_CONTRACT.json`）：

| 地图 | 允许新上车格 | 不能在 ICE 上新上车 | 特别说明 |
|---|---:|---:|---|
| 1F（ID70） | 818 | 234 | Gold FLOOR 815 格 + 出口地毯 3 格 |
| B1F（ID95） | 251 | 44 | 4 块临时不可推动的石头与洞口行为不因骑车改变 |
| B2F 卡吉侧（ID96） | 44 | 304 | PIT 到达点未开放，不因自行车触发 |
| B2F 烟墨侧（ID97） | 36 | 91 | 单向跳崖的方向限制仍以行走碰撞为准 |
| B3F（ID98） | 75 | 0 | 本层 Gold 原始数据没有 ICE role |

**跨楼层骑车**：`wWalkBikeSurfState == 1` 时，公开入口允许保留骑乘状态，避免跨楼梯在 ICE/LADDER 格错误换成步行贴图。新上车必须先通过当前格 Gold role 的谓词；不把 `JOHTO_ICE_PATH` 整类添加到自行车白名单，以免绕过冰面限制。`ItemUseBicycle` 的下车分支仍允许正常下车，`TryRideBike` 仍通过相同公开入口。

## 本批实际改动

- 增加 `tools/johto_ice_path_bicycle_368e_audit.py`：对 **3,060 个 Gold role 格**核对参考 SHA-256／尺寸及 FLOOR、ICE、CARPET 数量，并检查五图公开分派、每图当前坐标读取与许可标志、骑车状态、Bag、SELECT 和地图切换贴图路径。
- 增加 `tools/tests/test_johto_ice_path_bicycle_368e.py`：28 条用例，覆盖缺失楼层入口、用错楼层判断、楼梯骑乘被清零、坐标误取、冰面误允许、Bag/SELECT/贴图、全图绕过限制、Gold role 资源损坏等错误注入。
- 在 `tools/validate_current_project.py` 将新检查放在历史迁移审计之前，以免被旧版本冻结合同的错误遮住。
- 本批没有更改 ROM 行为，也没有把未完成的 ICE 自动滑行、怪力推石、落洞或碎岩称为完成；游戏版本仍为 `REF-368D@`。

## 验证边界

```sh
python tools/johto_ice_path_bicycle_368e_audit.py --root .
python -m pytest -q tools/tests/test_johto_ice_path_bicycle_368e.py
python tools/johto_warp_field_entry_gate.py --root .
python tools/asm_symbol_preflight.py
```

这是**源代码静态检查，不是 ROM 上的动态验证**。用户在手机上可任选五图的 FLOOR 使用 Bag / SELECT 上车，下车，再从 ICE 格尝试新上车，最后骑车跨 B1F/B2F/B3F 楼梯查看是否保留骑车贴图。编译／MAP ROM0 余量／手机行为不应由本报告冒称已验证；本批不 Commit/Push。

## 交付

遵照 `RPP_PROJECT_CONTEXT/03_PROJECT_REQUIREMENTS.txt` 的开发期要求，仅一个 ZIP，内有 `01` 自 REF-368D 递增至本批的补丁，`02` 自最后核实正式 REF-367 HEAD (`cd88452a05e9399b469f12fe2c6c89dd532dfcfb`) 累计至本批的全量补丁。二选一，严禁叠加。本批是**自行车审计增强**，没有新增声称已修复的骑车故障。

## 已存在的跨项目历史失败（不能算全绿）

本批冰之通路专用与此前楼层测试合跑 **112 通过**。把旧门房自行车组也并入时，产生 **125 通过、1 失败、5 跳过**，失败为 `test_johto_gate_music_bike_259.py::GoldGateMusicBike259::test_all_active_gold_gate_policies`。已在**没有本批修改**的 REF-368D 基线上复现同一失败，其检查仍假设 ROM0 紧凑允许掩码对应的 `ID75` 不活动，以及早期 Gold GATE 列表。此问题涉及全项目门房自行车契约，**不是 Ice Path 楼层缺少 Bike 入口，也不是本轮已修复项目**；不得宣称全量 pytest 或统一迁移审计通过。
