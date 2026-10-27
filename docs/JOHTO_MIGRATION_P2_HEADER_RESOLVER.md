# P2-002 — 地区 Header/Bank 安全解析接口（开发候选）

## 本轮实现

- Bank `$41` 新增 `ResolveJohtoHeaderDescriptor`：输入 `D=region` 与 `E=stable_local_id`；先验证地区是城都，再以 P2-001 稳定 ID→活动槽位查表，之后通过 **16 位** `slot×3` 访问 `[Header 低字节, 高字节, ROM Bank]` 单一描述符。
- 查询有效时返回 `E=active_slot`、`D=header_bank`、`HL=header_ptr`；非法地区、未知编号、未激活编号或无效槽位返回 `E=$FF, D=0, HL=0`。`callab` 会覆盖 A/标志，因此调用方只使用 D/E/HL，且需在访问 `[HL]` 前自行切换到 D 指定的 ROM Bank。
- 描述符表目前 **0 项**，`NUM_JOHTO_ACTIVE_MAPS=0`，与 P2-001 的活动槽位表严格一致。编译期断言：表长必须等于 `活动地图数×3`；任何地图登记都应一次性补齐指针/Bank、活动槽位、地图 Header 与其它运行资源。
- 不挂接现有 `LoadMapHeader`、Warp、Fly 或存档读写路径；关都 Header 和 P1 的跨 Bank 查表未修改；不增加 WRAM、SRAM 或存档字段。

## 不得照搬的地区存档地址冲突

在金银参考分支，`wCurRegion`～`wJohtoFlySelectedLocalID` 用 `$D7A4–$D7AB` 等字节。但 **TEST-217** 在同一范围已有 `wRegionalDexSeenExtra` (6B, `$D7A4–$D7A9`) 和 `wRegionalDexOwnedLast` (2B, `$D7AA–$D7AB`)，且这些数据处于主存档块。不得改别名、覆盖原数据或增加 `ds` 挤压 WRAM 布局。

另外主项目原有 WRAM0 空闲为 0B、WRAMX bank 1 只余 1B，因此不能直接新增 4–8B 持久地区字段。首次启用城都地图之前必须设计不冲突的 RAM 生命周期/备用 bank 和版本化存档方案（含老存档辨别和异常恢复），并单独验收。当前不引入或读写无效的地区 magic marker。

## 后续接入门禁

1. 安全的地区身份与存档载体先独立审核，不能将稳定 local ID 当作 `wCurMap` 旧地图编号，也不能使用旧城都 `$E7/$F4/$0B` 别名。
2. 第一张城都地图导入时同时登记完整 Header、Bank、Tileset、Object、Warp、连接、脚本、音乐、Town Map 等；描述符行和活动槽位更新必须保持一致。
3. 只有注册地图准备就绪后，才允许将当前未调用的解析接口接入实际 `LoadMapHeader`。对 `$FF` 的失败回退必须发生在数据解引用前。

## 当前验证范围

静态源代码检查与补丁正反应用由交付方完成。主项目正常运行链仍与 P2-001 一致。`all_maps(2).zip` 两份正式红蓝 MAP 证明的是 **P2-001** 的 ROM0 824B、Bank `$41` 表布局，**不是本轮 P2-002 的链接结果**。新增例程需用户重新编译链接、查看 MAP；尚没有新的地图可进行专项游戏测试。
