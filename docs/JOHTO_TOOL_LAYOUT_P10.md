# 城都地图工具目录审查｜P10（MAP-5.62.194）

**依据**：最新上传的 RPP `.194` 实际工作区、完整 Gold，及 P09 工具候选后本轮 P10 隔离修改。当前 ZIP 导出 HEAD `27eeab0b`，仍有未提交的工具修改。

## 位置原则和本轮处理

| 类别 | 正确目录 | 检查结论 |
|---|---|---|
| Gold/RPP 转换器、脚本及门禁 | `tools/` | 正常；Python 执行逻辑不属于 ROM 资源 |
| Python 回归测试 | `tools/tests/` | 正常；被删除的几何单测已迁入现有通用测试模块 |
| 通用审计配置与核准数据 | `tools/*.json` | 正常；含原生地图、门口合同、Gold 几何核准合同 |
| 运行时地图布局、坐标位图 | `maps/` | 旧54字节 Route33 位置不当，**现已迁入** |
| tileset/metatile/图像与调色 | `gfx/`、`color/` | 正常；正式资源未移动 |
| ROM 汇编逻辑 | `engine/`、`home/`、`main.asm` 等 | 正常；只变更了 `INCBIN` 路径 |
| 自动导出、历史 Patch、空间报告 | `RPP_PROJECT_CONTEXT/` | 只用于追溯，不当作运行源码修改 |

旧 `tools/johto_route33_staging/geometry190/Route33.geometry.json` 保存 `.190` 的离线阶段状态（例如 `runtime_registered: false`），并不能描述 `.194` 当前功能。现用通用 JSON 合同和项目源码做当前版本验证；历史说明文档保留供查阅。

## 当前城都 Python 工具逐文件盘点

下列清单涵盖当前 `tools/` 根目录全部 `johto*.py` 脚本。位置检查与是否应该删除是不同判断，不能因为某脚本尚未通用化就移动或删除。

| 脚本 | 归类／处置 |
|---|---|
| `tools/johto_bidirectional_warp_validator.py` | 分系统审计或辅助实现；位置正确，未证明等价前保留 |
| `tools/johto_cave_escape_audit.py` | 分系统审计或辅助实现；位置正确，未证明等价前保留 |
| `tools/johto_door_onboarding_audit.py` | 分系统审计或辅助实现；位置正确，未证明等价前保留 |
| `tools/johto_field_moves_preflight.py` | 分系统审计或辅助实现；位置正确，未证明等价前保留 |
| `tools/johto_gate_audit.py` | 分系统审计或辅助实现；位置正确，未证明等价前保留 |
| `tools/johto_gold_cells.py` | 公共素材/碰撞/连接/门口转换能力；保留 |
| `tools/johto_gold_door_audit.py` | 分系统审计或辅助实现；位置正确，未证明等价前保留 |
| `tools/johto_gold_sources.py` | 公共素材/碰撞/连接/门口转换能力；保留 |
| `tools/johto_indoor_batch.py` | 公共素材/碰撞/连接/门口转换能力；保留 |
| `tools/johto_indoor_border_adapter.py` | 分系统审计或辅助实现；位置正确，未证明等价前保留 |
| `tools/johto_indoor_collision_adapter.py` | 公共素材/碰撞/连接/门口转换能力；保留 |
| `tools/johto_indoor_common.py` | 分系统审计或辅助实现；位置正确，未证明等价前保留 |
| `tools/johto_indoor_conversion_plan.py` | 公共素材/碰撞/连接/门口转换能力；保留 |
| `tools/johto_indoor_manifest.py` | 分系统审计或辅助实现；位置正确，未证明等价前保留 |
| `tools/johto_indoor_palette_vram_audit.py` | 分系统审计或辅助实现；位置正确，未证明等价前保留 |
| `tools/johto_indoor_pipeline.py` | 通用流程／统一门禁；**保留** |
| `tools/johto_indoor_registration_generator.py` | 公共素材/碰撞/连接/门口转换能力；保留 |
| `tools/johto_indoor_release_audit.py` | 通用流程／统一门禁；**保留** |
| `tools/johto_indoor_resource_budget.py` | 公共素材/碰撞/连接/门口转换能力；保留 |
| `tools/johto_indoor_tiles_converter.py` | 分系统审计或辅助实现；位置正确，未证明等价前保留 |
| `tools/johto_map_release_audit.py` | 通用流程／统一门禁；**保留** |
| `tools/johto_music_final_audit.py` | 分系统审计或辅助实现；位置正确，未证明等价前保留 |
| `tools/johto_native_warp_converter.py` | 公共素材/碰撞/连接/门口转换能力；保留 |
| `tools/johto_region_id_audit.py` | 分系统审计或辅助实现；位置正确，未证明等价前保留 |
| `tools/johto_route32_surf_geometry.py` | 既有冲浪几何用例；保留，后续可另评估数据合同化 |
| `tools/johto_route33_runtime191.py` | 运行安全专项审计；**保留**，尚有独立负向合同 |
| `tools/johto_rpp_asset_audit.py` | 公共素材/碰撞/连接/门口转换能力；保留 |
| `tools/johto_rpp_batch.py` | 公共素材/碰撞/连接/门口转换能力；保留 |
| `tools/johto_rpp_connection_guard.py` | 公共素材/碰撞/连接/门口转换能力；保留 |
| `tools/johto_rpp_ledge_converter.py` | 公共素材/碰撞/连接/门口转换能力；保留 |
| `tools/johto_rpp_pipeline.py` | 通用流程／统一门禁；**保留** |
| `tools/johto_rpp_tileset_contract.py` | 分系统审计或辅助实现；位置正确，未证明等价前保留 |
| `tools/johto_rpp_validate.py` | 分系统审计或辅助实现；位置正确，未证明等价前保留 |
| `tools/johto_surf_geometry_audit.py` | 分系统审计或辅助实现；位置正确，未证明等价前保留 |
| `tools/johto_surf_runtime_audit.py` | 分系统审计或辅助实现；位置正确，未证明等价前保留 |
| `tools/johto_town_map_bike_audit.py` | 分系统审计或辅助实现；位置正确，未证明等价前保留 |
| `tools/johto_union_cave_exit192_audit.py` | 运行安全专项审计；**保留**，尚有独立负向合同 |
| `tools/johto_warp_arrival_audit.py` | 分系统审计或辅助实现；位置正确，未证明等价前保留 |
| `tools/johto_warp_reference_profiles.py` | 分系统审计或辅助实现；位置正确，未证明等价前保留 |

## 已完成的去重和仍需保留的模块

- **删除**：`johto_route33_geometry190.py`、对应独立测试、阶段几何 JSON；专用几何运算与核准检查已迁入已有 `johto_indoor_collision_adapter.py` 及 `tools/tests/test_johto_rpp_batch.py`。
- **迁移**：真正进入 ROM 的54字节 `Route33.blocked_mask.bin`，从 `tools/johto_route33_staging/...` 到 `maps/JohtoRoute33.blocked_mask.bin`；源码 `INCBIN` 对应更新，内容 SHA-256 与旧文件相同。
- **保留**：`johto_route33_runtime191.py` 仍核查跨图块集连接、原本的白闪回归、共享 tileset、草地 Fly 与跳崖挂接；`johto_union_cave_exit192_audit.py` 核查洞口方向及 Dig/逃洞绳来源安全。它们不是几何转换重复品。
- **统一审计**：`tools/johto_map_release_audit.py` 强制发现新的通用几何负向测试，不依赖已删除模块。

**静态验证边界**：通过 Gold 门禁只能说明本轮源码合同未发现差异。不能据此宣称 ROM 已链接、安全余量已验证或手机测试完成。

**下一地图桧皮镇**：从 Gold 生成候选，用本项目通用 pipeline + Field Moves/连接/Warp 清单核查，再单独开放实际入口；不能继续复制 Route33 专用几何脚本，也不能直接把未核准的特殊跳崖自动放行。
