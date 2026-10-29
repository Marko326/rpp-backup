## 验收与提交安排（ACC-248）

用户已确认桔梗市上岸修复正常，当前 `.248` 补丁已测试无异常。本工具及 Gold 数据审计属于第三笔 `test(tool)` 提交，不得和旧存档指针刷新、地图地形运行代码混为同一笔。工具仍不自动运行 Game Boy ROM，Route32 及洞穴水面合同需以后逐图登记。

# SURF-AUD-001｜城都水域复用与交付前强制检查（工具专项，无 ROM 行为修改）

## 现成方案来源与边界

- 旧 NPC 参考工程的 `docs/JOHTO_ROUTE32_SURF_187.md`、`docs/JOHTO_SURF_RUNTIME_187.md` 记载过 `johto_route32_surf_geometry.py`、`johto_surf_runtime_audit.py` 和负向测试；**本次上传的旧参考包没有这些脚本实体**，不能声称已经直接复用了它们的文件。
- 旧分支的 `home/overworld.asm::CollisionCheckOnWater` 确实先用地图特定的 Gold 水格识别前方水面；若前方不是水，再恢复 `wTileInFrontOfPlayer` 到 `C`，走项目原有陆地通行扫描。`VIOLET-247` 复制水格思路时遗漏了这一细节，`.248` 才补齐。用户已反馈该次桔梗市无法上岸问题实机解除。
- 当前 `tools/johto_rpp_pipeline.py` 的 `onboarding` 已经计算水格并生成包含上岸的审查清单，但**不会验证运行时分支**。本工具补足这一关，不重写冲浪状态机、不替代游戏内测试。

## 交付前执行（主要供下个窗口／AI 使用）

```
python tools/johto_surf_preflight.py
python tools/johto_surf_preflight.py --gold /实际解压的pokegold根目录
python -m unittest discover -s tools/tests -p test_johto_surf_preflight.py
```

必须以用户提供的 Gold 参考资产执行 `--gold` 的逐格严格比较；没有源码时只能运行非 Gold 的代码静态检查，**不能标记源数据验收通过**。调用返回非 0 即停止生成开发补丁，不要删断言。

本工具检查：

1. `IsSurfTile`（面对水面按 A/宝可梦 Surf）、`IsNextTileShoreOrWater`（Surfboard）、`CollisionCheckOnWater`（水中持续移动／上岸）三个入口全部调用已登记的同一地图水面判断；新水面 helper 未登记即失败。
2. 只在城都共享句柄、正确地区、指定稳定地图 ID 下启用，不把共享美术图块加入全局水面白名单。
3. 从 Gold `.blk` 与原版 tilecoll 完整解码真实 WATER 坐标，并对照源码的水面坐标表（现有桔梗市 140 格）。发现漏格、多格、重复或越界立即失败。
4. 在 `CollisionCheckOnWater` 中，水面为真时继续冲浪；非水面必须先 `ld a,[wTileInFrontOfPlayer]`／`ld c,a` 再调用原来陆地可通行扫描；不因无法确认水面就直接宣告岸上可走。
5. 故障注入：删除 `ld c,a`、翻转水面分支、遗漏三个入口之一、添加未登记水面 helper、错误地图 ID、错水格等必须使审计失败。

## 下一张带河流地图如何接入

1. 先从旧项目确认相关 ASM 与当前 RPP 编号／Bank 是否兼容；优先复用三个引擎入口和现有陆地通行扫描，不另起新 Surf 状态机。
2. 使用当前 `johto_rpp_pipeline.py` 的接入审查读取 Gold 水格；明确哪些墙和水共用 8×8 图块，**禁止**把该 Johto Tileset 全局设为可冲浪／可步行。
3. 在 `tools/johto_surf_contracts.json` 登记地图名、稳定 ID、helper、源水格与尺寸；扩展审计解析器后再支持旧项目 Route32 的位图编码（现有 `yx_db` 格式之外的编码**尚未实现，不能声称支持**）。
4. 执行 Gold 严格几何比对、三个入口与上岸分支审计、负向用例、ASM 符号检查、现有地图迁移/门房/Warp 审计、补丁正反向回放。若修改了 JR、Bank、ROM0 或寄存器保存，静态检查不能代替 RGBDS 链接。
5. 用户在手机上分别验证：从各岸边入水、四向移动、靠合法岸上岸并继续行走、非法墙不出水、重新入水、冲浪音乐/切图/存读档，以及关都正常。

**限制**：本工具不是 Game Boy CPU 仿真器，不执行 ROM 链接或音频与玩家操作。它能拦截这次遗漏的代码模式，不能保证未来所有地图自动一次成功。
