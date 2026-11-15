# REF-369S@ 冰之通路 B1F 玩家掉洞（开发候选；待设备验收）

## 本轮实际完成

- **冻结烟尘**：不修改 REF-369R 已有双槽 Gold 推石烟尘、音效、文字、震动、怪力碰撞和 D852/D853 存档位；本轮只做玩家 PIT。
- B1F Gold 四个 `PIT` (`X,Y`: `(11,2)`、`(4,7)`、`(5,12)`、`(12,13)`) 的地图对象 Warp #3–#6 启用，源到达 B2F Mahogany Side 的对应 Warp #3–#6。先判 Gold 原始 PIT 角色（只能这四格踩入），不会对其他 FLOOR/ICE/LADDER 误开启。
- B2F Gold 四个确切接收落点 `(11,4)`、`(4,6)`、`(4,12)`、`(12,12)` 启用为**接收坐标**；仅两条正常楼梯为主动 Warp，B2F 这四块 ICE 不会反向把玩家传回 B1F，也不会造成入口循环。
- 玩家下降复用现有烧焦塔的 `JohtoBurnedTowerMaybeFallWarp`/`JohtoBurnedTowerFallEntryAnim` 动画，在触发真实 B1F PIT 的单向路由时启用落洞白屏→下落动画；正常楼梯不触发下落动画。
- Registered Johto directed warp routes 从 188→192；活动地图仍为 70；Gold 参考 `REFERENCES/Gold/pokegold-master/maps/IcePathB1F.asm` 和 `IcePathB2FMahoganySide.asm`。
- 版本更新为 `REF-369S@`；源码与负向防回归见 `tools/johto_ice_path_player_fall_369s_audit.py` 及单元测试，同时接入 `tools/validate_current_project.py`。

## 为什么不直接复制 Gold 传送机制

项目使用自有的 warp 注册、角色碰撞与烧焦塔完整掉落动画。Gold 四个源点和四个目标点保持原样，但需要明确屏蔽目标 ICE 的回程路由；普通梯子和离洞逻辑不得走坠落动画。新路径被限制在城都冰之通路，不改变关东区域。

## 待用户手机验证 / 正式收口前强制检查

1. B1F 四个洞分别从可到达方向步入，确认不被障碍挡住，能下落到各自的 B2F 安全落点；玩家进入坑后有完整下落动画。
2. B2F 四个落点可走动或正常滑冰，不会自己反向传送；正常楼梯 B1F↔B2F / B3F、冰面自动滑行及屋外入口仍正常。
3. 玩家踩洞不改变四块石头落洞/存档状态，不重复发出石头掉洞文字；重复进入坑可再次下落但没有循环返回。
4. 四石头推进坑、保存/读取、B2F 静态石头显示、B2F 保存后无花屏、START 不残留旧文字/烟尘。
5. 由用户本机构建四版 Red、Blue、TEST Red、TEST Blue ROM/MAP，逐一复查 ROM0≥64B、ROMX、游戏启动；此轮 **AI 未自行编译 ROM**。
6. 原 35 项迁移历史审计失败、旧 REF-369A D855 污染存档风险均需维持真实记录；不以本轮专项测试取代全项目成功。

## 交付及版本边界

按 `RPP_PROJECT_CONTEXT/03_PROJECT_REQUIREMENTS.txt`：开发阶段 ZIP 内只含两个互斥补丁：01 **已应用 REF-369R → REF-369S**；02 **已核实正式 REF-368 HEAD `935b3fa738dce42f22768e94c92c920bb5b86d89` → REF-369S**。不叠加，不清理，不 Git Commit/Push。Rock Smash、NPC、道具和野怪等延期项目仍未完成；故“冰之通路核心地图／怪力／玩家落洞闭环”可在设备验收后提请阶段收口，**不是所有后续内容已经完成**。
