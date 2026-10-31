# FIX-5.62.272｜ROM0 城都陆地碰撞网关优化

**症状：** `.271` 用户在本机链接时再次遇到 `Unable to place "Home Copy Data" (ROM0 section) anywhere`。附带的 `.270` MAP 历史 ROM0 总余量仅26字节。

## 修复策略

- 不移动 `CopyData`、`FarCopyData`、中断或 unbanked tileset collision。
- 保留 `CollisionCheckOnLand` 的前置跳跃标志、模拟输入、地图边缘资格、精灵及门房接近资格，之后通过一次 `callab JohtoOverworldSouthLandDecision` 进入Bank `$4F`。
- Bank `$4F` 复用原先的Cherrygrove导览之家入口例外、`HandleLedges`、`JohtoSouthSpatialStep`、`JohtoRoute33StepPolicy`，保持原有地图白名单、跳崖时序和返回方向；不扩大未开放地形。
- 银行返回 ABI 以 `E=0` 允许、`E=1` 阻挡、`E=2` 回退普通地形，不能依赖 BankSwitch 后的 A 或错误地把所有非零都当作阻挡。
- 被替换的 ROM0 代码，按指令和 `callab` 6B 宏实际编码计算是124字节；新增 ROM0 网关25字节，**静态净节省99字节**。这不等于重新链接后的容量、连续空闲块或ROM运行验收。

## 交付及验证

按开发阶段两份互斥补丁交付。`python tools/johto_land_rom0_preflight_272.py --root .` 专项门禁已检查网关和分派结构，配合 ASM 本地标签、已有地图迁移审计。原来的ROM0地图空间预算测试仍坚持64字节，旧 `.270` MAP 会失败，这是正确的，不能删测试或忽略旧MAP。

用户需要本机重新执行正式红、蓝链接，并以**新生成的 MAP** 验证 ROM0 至少64字节，及桐树林跳崖B键、33号路桧皮镇接缝、南线所有已开放门口与关都正常。
