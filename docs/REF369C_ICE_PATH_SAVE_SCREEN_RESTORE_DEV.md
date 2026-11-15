> **历史候选已被手机证伪**：REF-369C 用户 `67695.mp4` 显示保存后仍花屏。后续审计确认该版代码放在 Save 不会经过的 `StartMenuPrepareClose`，所以本文的“返回路径”推理不成立。更正见 `docs/REF369D_ICE_PATH_SAVE_LIVE_RETURN_DEV.md`。下文只保留历史记录，不能作为有效修复依据。

# REF-369C@ — Ice Path START 保存后图形恢复（开发候选，待设备验收）

## 现场证据和限界

用户提供的 `保存显示异常.mp4`（约 12.9 s）录下冰之通路 B2F Save 完成、返回地图后立即出现大范围地形图案异常；后续独立反馈：退出游戏再读档正常，上下楼梯切换后地图同样恢复。已排除“这些操作后仍永久显示异常”这种现象，不能由此断定 SRAM 事件位从未损坏。用户尚未给出“打开 START 后不保存”和“普通地图保存”的独立对照。

该故障更像保存 UI 返回地图时的即时 BG 图形恢复不完整。`StartMenu_SaveReset` 保存后重放 `wTileMapBackup2`，并经 `HoldTextDisplayOpen`／`StartMenuPrepareClose`／HOME `CloseTextDisplayAfterWindowHide` 回归地图。该 HOME tail 恢复 sprites 与可见 tilemap，但没有重新上传 tileset 图形；楼梯换图则走 map loading，重传图块。**这是静态代码和现象推导的候选原因，不能冒充已证实真实根因**。

## 本轮保留差异

- `engine/menu/start_menu_helpers.asm`：仅在既有 `.fullRestore` 分支、窗口隐藏且 Bank-0 文本合同恢复后，判断 `wCurMapTileset == JOHTO_ICE_PATH`，再根据 `EVENT_GOT_POKEDEX` 选择 Save 在图鉴菜单中的 0-based 索引 5 或无图鉴索引 3；当 `wStartMenuSavedMenuItem & $7f` 与之相等时调用现有 HOME `ReloadTilesetTilePatterns`。随后仍以 Carry=1 走原 HOME sprite/mapview close tail。没有触碰 START 仅 Quit 的 fast close，也没有改变用户 Cancel Save 的 SRAM 路径（选择 Save 后即使取消，仍可多作一次安全的 atlas 重传）。
- `data/game_version.asm`：开发标签 REF-369B@ → REF-369C@。
- `tools/johto_ice_path_save_return_369c_audit.py`、`tools/tests/test_johto_ice_path_save_return_369c.py` 与 `tools/validate_current_project.py`：注册静态强制门禁、来源分派、菜单两个索引、既有 Save/HOME 链与真实 LCD 关闭 atlas loader 的约束，并注入故意错误保证门禁会拒绝。
- `FEATURES.md`、`TODO.md`、`PROJECT_DELIVERY_RULES.md`、`RPP_DEVELOPMENT_PITFALLS.md`：说明本次有限候选和未验证边界。

未修改 `engine/save.asm`、`home.asm`、BANK0、`constants/event_constants.asm`、`wram.asm`、地图资源与 sprites。没有新增任何存档字段。REF-369B 的 D852/D853 隔离和 D855 旧档风险保留，Strength/PIT 仍是 WIP。

## 为什么以前没有拦住

此前 REF-369B 强制门禁聚焦事件位所有权和迁移，旧 START 相关检查没有断言冰洞保存后图块 atlas 的重载行为。脚本 PASS 不能证明菜单退出时 VRAM 图形稳定。新增检查只监控源码结构和触发条件；它无法模拟 CGB/DMG 的实际 VRAM 银行、VBlank 时序或真实设备输出。

## 测试、故障注入和待验证

运行 `python tools/johto_ice_path_save_return_369c_audit.py --root .`；`python -m pytest -q tools/tests/test_johto_ice_path_save_return_369c.py --tb=short`。负向用例分别破坏地图限定、分支方向、图鉴门槛、带／不带图鉴的 Save ID、atlas reload 调用、关闭后的 Carry 和 HOME tail，并验证 gate 非零返回。实际通过数量与其他检查结果应以本轮执行日志为准。

尚未执行 RGBDS 编译／链接／MAP，也未替用户在设备上运行 REF-369C；遵守项目禁止 AI 自行 ROM 编译及 Git Commit/Push 规定。旧 `tools/johto_pilot_migration_audit.py` 的历史冻结断言可能仍有失败，不能称全审计全绿。

### 用户最小手机复测

1. 先备份原 ROM 和 SAV。由用户在本地构建 REF-369C ROM，并查看 MAP 的 ROM0≥64B 和相关 ROMX bank 空间；构建失败先提供原始报错，不进入游戏。
2. 在同一冰之通路 B2F 位置按 START → Save → Yes，保存完成后直接返回地图观察是否仍花屏；角色四向移动约 3 格，再正常关闭重新 Continue。
3. 在 B1F 或 1F 再保存一次；随后上下楼梯查看地图／石头有无新异常。
4. 若有已取得图鉴的正常档，额外测含图鉴 Save 索引；若没有，则用当前档验证无图鉴菜单。普通关都地图保存一次作负向对照即可。
5. 若依旧花屏，则反馈新版录屏与保存前后各一帧图，继续围绕 BG tile attributes、`rVBK`、W2 palette map、LCDC 与 VRAM 逐步调试；不得宣称已修复。

## 开发交付基线

当前提交基线来自 RPP 导出 `常规功能备份`、HEAD `935b3fa738dce42f22768e94c92c920bb5b86d89`，提交状态为 REF-368@。本次上传源码是未提交 REF-369B@ Worktree；附带 `RPP_PROJECT_CONTEXT/patches/current_worktree.patch` 可反向准确重建 REF-368 HEAD 文件。开发 ZIP 严格两份互斥正向 patch：01 REF-369B→369C；02 REF-368 HEAD→369C。二者二选一，不叠加，不包含提交日志、ROM 或生成 MAP；RPP 导出文件不修改。
