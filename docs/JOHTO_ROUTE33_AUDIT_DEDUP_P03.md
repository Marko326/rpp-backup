# Route33 重复审计清理｜P03（不改游戏功能）

基线：用户已经安装的 `.194 + P02` 工作树。此补丁只修改审计工具、测试与当前说明，不触碰 `.asm`、地图资源或存档格式。

| 旧脚本检查 | 原有、现在保留的检查 | 处理 |
|---|---|---|
| staged `.blk` / modern metatiles / PNG 逐字节对照 | `johto_route33_runtime191.audit` 检查实际 ROM 使用的相同三种资源 | 删除重复阶段门禁，不再对离线快照重复比较 |
| Gold 16×16 水平/纵向碰撞角色与图块别名 | `johto_route33_geometry190.generate` + `johto_gold_cells.decode_cells` | 继续复用，不另造解析器 |
| Route32 南部边界、Route33 地区编号、连接/图块加载 | `johto_route33_runtime191.audit` | 删除重复检查 |
| Union Cave 第二洞口、Dig / Escape Rope 安全落点 | `johto_union_cave_exit192_audit`、`johto_cave_escape_audit` | 保留独立安全门禁 |
| Gold Route33 原版 tileset、north/west 连接、路标位置 | 原运行时门禁以前没有全覆盖 | **合并**到 `johto_route33_runtime191.audit`，新增反向测试 |
| 金银参考素材阶段快照 | 不参与 ROM 构建；只作历史追溯 | 原文件仍保留，不在每次总门禁重复运行比对 |

不移除 `geometry190` 与其 54 字节阻挡掩码；当前 ASM 的 `INCBIN` 实际依赖后者。已提交的历史导出文档与 `RPP_PROJECT_CONTEXT` 快照保留原貌，不伪造历史测试数字。

静态门禁仍要求完整 Gold 源码、全部必需模块与关键负向测试、0 skip。新地图必须单独评估新增检查的独立价值，不应因历史阶段而机械复制一套新审计脚本。
