# REF-369B@｜第一阶段：存档事件位清查与隔离

## 本阶段边界

本阶段只处理 Ice Path Strength/PIT 已写代码所使用的存档事件位归属、一次性旧状态迁移和静态审计。REF-369A 的四石头、推石碰撞、石头落洞、B2F 显示代码保留在源码中，但仍标记为 WIP；本阶段不宣称这些玩法已完成或已在 ROM/手机验证。玩家本人踩入 PIT 的 Warp 与碰撞仍保持封闭。

不改地图数量、地图对象坐标、楼梯/跳崖/冰面滑行/自行车行为；不新增 WRAM/SRAM 字节，不改变 `wEventFlags` 的起始地址和长度。

## 事件位地址计算

`wEventFlags` 起始地址为 `$D7CB`，长度 139 字节。事件常量中的 current ordinal 是事件数组内的 bit index。正确字节地址为：

`$D7CB + (event_index / 8)`，bit 为 `event_index % 8`。

**禁止把 `EVENT_9D7 / 8` 再额外加 1。** `EVENT_9D7` 是 current `$44F`，对应 D854 bit 7；额外加 1 才会错误地跳到 D855。

## D852–D855 完整归属表

| WRAM 字节 | bit | 归属 | 处理规则 |
|---|---:|---|---|
| D852 | 0–1 | Seafoam B2F 两块石头 | 保留 |
| D852 | 2–5 | Ice Path 四个 PIT 是否填充 | REF-369B 新分配 |
| D852 | 6–7 | Ice Path 一次性迁移签名 A/B | REF-369B 新分配 |
| D853 | 0–1 | Seafoam B3F 两块石头 | 保留 |
| D853 | 2–3 | Ice Path Route44／Blackthorn 户外出口锚点 | 保留，迁移时不得清除 |
| D853 | 4–7 | Ice Path 四块源石头已掉落 | REF-369B 保留原分配 |
| D854 | 0–1 | Seafoam B4F 两块石头 | 保留 |
| D854 | 2–5 | Johto Fly：Olivine、Cianwood、Lake of Rage、Blackthorn | 保留 |
| D854 | 6–7 | Dark Cave 两个户外出口锚点 | 保留 |
| D855 | 0–7 | Johto Fly：Ecruteak、Mahogany、Articuno defeated、New Bark、Cherrygrove、Violet、Azalea、Goldenrod | **全部已占用；Ice Path 禁止写入** |

新事件常量明确命名为 `EVENT_JOHTO_ICE_PATH_PIT_*`、`EVENT_JOHTO_ICE_PATH_PIT_STATE_MIGRATION_*`、`EVENT_JOHTO_ICE_PATH_BOULDER_*_DROPPED`。D852/D853 与其他地图共享字节，但使用独立 bit；迁移使用掩码保留其他模块的 bit。

## REF-369A 错误及旧存档边界

REF-369A 曾把 PIT 字节定义为 `EVENT_9D7 / 8 + 1`，由此错误写入 D855 bits 0–3。D855 并非空闲尾部字节，而是上表中的 Fly/Articuno 事件。REF-369A 若实际写过 PIT 状态，可能已经改变这些 Fly/Articuno 标志。

**不能从当前 D855 值可靠推断它原先是“真实解锁”还是“被 PIT 覆盖”。** REF-369B 不自动清空或重写 D855，因为那可能进一步抹掉玩家真实解锁的飞行地点或急冻鸟事件。若使用过 REF-369A 存档，第一次进入 REF-369B 前先备份；若有 REF-368 或更早的存档备份，优先保留它。没有旧备份时，无法保证自动无损修复 D855。

## 一次性迁移

首次进入 B1F 或 B2F 卡吉侧时，检查 D852 bits 6–7：

- 若签名不是 `$C0`，将 D852 改为 `(old & $03) | $C0`：保留 Seafoam B2F bits 0–1，清除 PIT bits 2–5，并写入迁移签名。
- 将 D853 改为 `old & $0F`：保留 Seafoam B3F bits 0–1 和 Ice Path 出口锚点 bits 2–3，清除 REF-369A 的源石头 bits 4–7，使四块石头恢复初始状态。
- 不读取、不清除、不写入 D854/D855。
- 若签名已为 `$C0`，后续地图加载不再重复重置，REF-369B 之后保存的石头/坑状态继续保留。

该迁移只清理 Ice Path 自己拥有的两个 nibble；不改变 Seafoam、Dark Cave、Johto Fly 或 Articuno 的事件位。

## 保留但仍为 WIP 的功能

- 四块 B1F 石头对象和 Strength 接线：保留，碰撞和四方向行为未在本阶段验收。
- 石头进入 PIT、源石头隐藏、B2F 对应石头显示：保留，仍需逐坑、存档/读档和 ROM/手机验证。
- 玩家踩入 PIT：明确未启用，B1F #3–#6 玩家 Warp 继续封闭。
- 落洞动画、落地坐标、重复触发保护：后续阶段单独实现。

## 本阶段验证

- `python tools/johto_ice_path_save_flag_audit_369b.py --root .`：通过（静态事件归属、事件地址算术、迁移写入范围、D855 保护、玩家 PIT 仍关闭）。
- `python -m pytest -q tools/tests/test_johto_ice_path_save_flags_369b.py tools/tests/test_johto_ice_path_strength_pit_369b.py --tb=short`：31 passed。
- `python tools/validate_current_project.py --skip-pytest --jobs 1`：前 19 个当前源码门禁通过；最后的历史迁移总审计仍报 35 项旧冻结合同失败，不能称全绿。
- 没有运行 RGBDS 编译、没有生成新 ROM/MAP、没有手机实测；遵守项目要求由用户侧构建/验收。

## 开发交付基线

- 版本：`REF-369B@`。
- 增量补丁：REF-369A 开发候选 → REF-369B 第一阶段（假定用户工作区已应用 REF-369A）。
- 全量补丁：正式 REF-368 HEAD `935b3fa738dce42f22768e94c92c920bb5b86d89` → REF-369B 第一阶段。
- 开发阶段一个 ZIP，严格两份互斥 `.patch`；二选一，不叠加。不制作正式提交日志，不执行 Git Commit/Push，不编译 ROM。
