# REF-369D@ — 修正真正执行的 Ice Path Save 返回路径（开发候选）

## 用户实测与上一轮误判

用户提供 `67695.mp4`（约 8.3 s）：设置显示 `REF-369C`，进入 Ice Path 的 START Save 后在约 5.3 s 返回地图，随后至视频结束地图出现原有的严重图块错乱。**REF-369C 手机验收未通过**，不能再沿用“静态 gate 已通过则显示修好了”的结论。用户此前确认重启读档或上下楼梯重载地图可恢复显示，这只能说明画面异常具有即时性，不能替代事件位及 SRAM 校验。

本轮直接检查真实执行链：

`DisplayStartMenu` 的 Save 分支 -> `StartMenu_SaveReset` -> `predef SaveSAV` -> `LoadScreenTilesFromBuffer2` -> `jp HoldTextDisplayOpen` -> HOME `CloseTextDisplay` -> `CloseTextDisplayAfterWindowHide` -> `LoadCurrentMapView`。

**REF-369C 失败的已确认控制流程原因**：当时把重载代码放在 `StartMenuPrepareClose`（仅 START 的 B/START/EXIT `CloseStartMenu` 会经过）；Save 在 `StartMenu_SaveReset` 直接跳 HOME，完全绕过那个分支。上一轮的静态 gate 仅证明“错误的 helper 存在”，未审计 Save 的真实跳转与 helper 是否相连。故即使门禁全绿，视频仍会花屏。这个入口错误已静态确定；Ice Path 图块是否为唯一导致花屏的资源，则仍须实机确认。

## 改动

1. `engine/menu/start_sub_menus.asm`：在现有 `predef SaveSAV` + `LoadScreenTilesFromBuffer2` **之后、`jp HoldTextDisplayOpen` 之前**，检查 `wCurMapTileset == JOHTO_ICE_PATH`，使用单条 `call z,ReloadTilesetTilePatterns` 调用 HOME 现有 LCD-safe tileset loader。守卫与调用仅新增 8 个 Bank $04 ROMX 机器码字节（静态指令长度预算；未执行 ROM 链接），无新增 BANK0 指令。非冰之通路 Save 与 LINK SoftReset 不进行该重载。
2. `engine/menu/start_menu_helpers.asm`：删掉 REF-369C 不可达的 Save 专属判定和重载代码，还原原 full restore Carry 合同；START 的 Exit/其他子菜单未新增重传。
3. `data/game_version.asm`：开发标签 REF-369C@ -> REF-369D@。
4. `tools/johto_ice_path_save_return_369d_audit.py` 与其负向测试替代旧 369C 入口错误 gate，校验 Save 的实际顺序、只有 Ice Path 触发、实际 HOME 尾部、旧 helper 不得残留重载，以及现有 LCD-safe tileset loader；`tools/validate_current_project.py` 改为调用新 gate。

## 边界

- **本次不改** `engine/save.asm`、`home.asm`、SRAM/WRAM 布局、事件常量、地图/图形资产、ROM0 指令或所有 Strength/PIT WIP；保留 REF-369B 事件位保护及旧 REF-369A 存档 D855 风险。
- `ReloadTilesetTilePatterns` 的目标只是恢复图块图像：它不是新的地图进入流程，不能代替地图 Bank/属性、OBJ、特殊动画实机验证。若本次仍花屏，应做保存前/后 VRAM bank、LCDC BG tile address mode、`wTilesetGfxPtr`、W2 属性表与 `wCurrentTileBlockMapViewPointer` 等针对性运行状态对照；不要再在旁路上重复贴同一调用。
- 开发 ZIP 只有两份互斥正向补丁：01 从**已安装的 REF-369C@** 工作区；02 从**已核实的正式 REF-368 HEAD 935b3fa738dce42f22768e94c92c920bb5b86d89**。二选一，严禁叠加。不可用文件名推断新的正式 HEAD；本轮没有用户提供更高的已提交 Git 基线。无正式提交日志、ROM、MAP 或 Commit/Push。
- 项目禁止 AI 自行编译/链接 ROM，故本轮没有实机或 4 ROM 构建证据、也没有新版 MAP ROM0≥64B 证据。仅以实际日志报告源门禁、测试与补丁回放。

## 用户最小复测

备份当前 SAV/ROM，用正确的一个补丁生成 REF-369D ROM（应在设置显示 REF-369D）。沿用同一 Ice Path B2F 存档，执行 START → Save → Yes → 返回地图，立即查看地图；再按上下左右走几步。若画面正常，另测 B1F、普通地图 Save、上下楼梯及重启 Continue。若异常仍存，发视频且记录是否只在 Save 后发生；本候选绝不能在手机验收前视作成功。
