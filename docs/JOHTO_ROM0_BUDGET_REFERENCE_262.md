# ROM0-262｜联合洞穴首次链接溢出：旧 NPC 分支对照与修复边界

## 原因与实物证据

用户 `RPP_编译及MAP日志_20261030_141037.md` 中，`rgbasm` 已生成 main/wram 对象，
`rgblink` 才报 `Unable to place "Home Clear Sprites" (ROM0 section) anywhere`。
这是 ROM0 布局空间问题，不代表 `ClearSprites` 例程损坏；用户要求不由 AI 编译。

交接包 `REFERENCES/NPC/NPC-5.62.243/patches/rppred.map` 与主工程现存的
`patches/rppred.map` 是**不同版本、过去已经成功链接的 MAP**，仅用于趋势判断：

| ROM0 | 旧 NPC-5.62.243 | 本工程旧 MAP |
|---|---:|---:|
| 总占用 | 15,916 B | 16,353 B |
| 剩余 `SLACK` | 468 B | 31 B |
| `Main` 节 | `$3C21` | `$3DAE` |
| 单独 `Home Clear Sprites` 节 | 11 B | 11 B |

旧 NPC 分支并非没有 ROM0 碰撞表：`data/collision.asm` 包含 `JohtoUnionCave_Coll`，
并由 `home.asm` 主节包含。该表必须对 unbanked 的 `wTilesetCollisionPtr` 读取可见。
旧分支早已将特殊地图碰撞/冲浪谓词放入 ROMX，通过 `callba IsJohtoSurfWaterAhead` 和
`callba JohtoNativeCanStepAhead` 从 ROM0 薄入口调用。旧分支曾将大型
`DisplayListMenuID_` 主体移至 Bank `$01`，但目前新工程 `$01` 仅有2字节余量、
ROM0 已形成不同布局，绝不可无差异地搬菜单实现或覆盖 `home.asm`。

## 本次选择

1. **保持** `home.asm` 的 `JohtoPilot_Coll`、`JohtoHouse_Coll`、`JohtoUnionCave_Coll` 在 ROM0；
   同时不修改 `ClearSprites`、中断、存档、音乐、Warp 和现有两条其它 Surf 入口。
2. `CollisionCheckOnWater` 移除重复的八地图行内判定，ROM0 只保留一次
   `callab JohtoOverworldSurfDecision` + 原有岸线与关都分支。
3. 在现有扩展 Bank `$48` 的 `engine/johto_violet_field_skills.asm` 做对应 Gold map-local
   逐图 Surf 判定；使用 Carry/Zero 两标志编码四个结果。
   `Bankswitch` 会覆盖 A，因此**不能用 A 返回分类**，但其恢复路径不会更改 Carry/Zero。
4. 继续保证吉花市 Gold FLOOR 特例、正常下水/继续游泳/岸线落地、旧关都共享瓦片水域判断。
5. ASM 源码预算预检估计 ROM0 `Surf` 入口由约196B压为23B（**约释放173B，只是估计**）。
   不应把估算当成用户新 MAP 的 ROM0 余量，更不应声称修复已完成真实链接。

## 新增门禁

- `python tools/johto_rom0_space_preflight.py --root .`：报告 ROM0 Surf 宽度、
  Bank `$48`、远调用标志 ABI、全部8图、洞穴3种独立碰撞指针约束。
- 日常 `johto_pilot_migration_audit.py` 合并此源码检查。
- `python tools/johto_rom0_space_preflight.py --root . --require-fresh-map`：
  专门在**用户重新执行 rgblink 之后**检查新 MAP 是否仍带旧 ROM0 本地分支标签，
  并要求 ROM0 余量至少64字节。若链接本身失败或 MAP 没更新，必须 FAIL。
- 7项故障注入验证删调用、倒置岸线、错误 Bank、碰撞指针位置、过时 MAP 和新 MAP 余量。

## 交付与下一关

开发补丁基线：用户实际 `CAV-5.62.260.zip` + 已交付 `.261` 修复；
增量从 `.261` 状态到 `.262`，累计从该 `.260` ZIP 到 `.262`，二选一。
`TEST-231` 不改。本轮无 Commit/Push、无 RGBDS ROM 编译/链接。
下一关必须由用户实际 `make red`，取得**新的** Red MAP，再测联合洞穴进出/Surf、
Route32、吉花市 FLOOR 岸线和关都原始冲浪。前一份含 `$001f` slack 的旧 MAP 不作验收证据。
