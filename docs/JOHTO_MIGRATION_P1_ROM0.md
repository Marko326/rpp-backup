# ROM-5.62.211 / TEST-218：P1 ROM 扩容与 ROM0 迁表收口

## 功能范围

- `main.asm` 在 Bank `$7F:$7FFF` 设置容量锚点，扩展 ROM 至 2MB；保持原 MBC3、SRAM 与 Makefile 设置。
- 关都 `MapHeaderPointers` 的 248 项（496B）从 ROM0 移至 Bank `$40`，`GetKantoMapHeaderPointer` 使用 `E` 传地图编号，返回地图 Header 地址 `HL`。此处不能改用 `A` 传参，因为跨 Bank 调用会覆盖 `A`。
- 关都指针表的顺序与内容保持不变；原 Warp、地图连接、地区身份、存档与战斗逻辑不变。本阶段尚未引入城都地图。
- 正式/测试版本已分别更新为 `ROM-5.62.211`、`TEST-218`；此次清理仅更新维护文档，不再修改 ASM。

## MAP 验收

| 项目 | 改动前 | 正式红版 | 正式蓝版 |
|---|---:|---:|---:|
| ROM0 空闲 | 319B (`$013F`) | 824B (`$0338`) | 824B (`$0338`) |
| `MapHeaderPointers` | ROM0 | Bank `$40:$4000–$41EF` | Bank `$40:$4000–$41EF` |
| 跨 Bank 查表例程 | 无 | Bank `$40:$41F0–$41FB` | Bank `$40:$41F0–$41FB` |
| Bank `$7F:$7FFF` 容量锚点 | 无 | 存在 | 存在 |

- 本次数据来自后续提供的 `all_maps(1).zip` 中 `patches/rppred.map` 与 `patches/rppblue.map`，不是根据历史版本推算。
- 同包内 `buildRB/pokered.map`、`buildRB/pokeblue.map` 是另一组布局，不作为 P1 合并后的验收对象。
- 正式红蓝 MAP 对应 ROM0 空闲净增 **505B**，≥800B 的第一阶段目标达到。
- 当前 MAP 同时显示 WRAM0 余量 0B、WRAMX #1 余量 1B；新增城都运行态字段前必须另外规划 RAM。

## 运行验证与保留边界

- 已收到的运行确认：宝可梦中心、山洞、普通房屋的进出和存读档正常。仅记录这些已确认的路径。
- 尚未单独收到 Fly、跨地图边界、道馆/港口及独立测试 Red/Blue 对应 MAP 的完整验收；没有 ROM 二进制供独立核对文件长度/头部容量码。不能将正式红蓝 MAP 合格扩大为四构建全部验收。
- 项目源码的迁表 248 项内容不变，`MapHeaderPointers` 唯一 INCLUDE、Bank 切换 ABI 和补丁回放由静态审查确认，不等于运行全部路径通过。
- 本环境不执行 RGBDS 编译、ROM 链接、模拟器实测或 Git Commit/Push。

## 清理补丁前置

- 开发版：`TEST217_ROM0_P1_001_incremental_from_TEST217.patch`，对 `TEST-217.zip` 的干净导出 HEAD `486c89c4a032473306267e95d5865149fc0b12a6` 应用后即为清理增量的前置状态。
- 正式清理增量：在上述 P1-001 已应用的状态上更新本项目维护文档。
- 累计全量：从上述干净 HEAD 直接到 P1 清理最终状态；**全量与增量不能叠加应用**。
- 后续 P2 才开始城都稳定 ID、活动槽位与地图功能移植；P1 不引入金版地图数据。
