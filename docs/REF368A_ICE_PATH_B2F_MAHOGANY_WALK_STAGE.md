# REF-368A@｜冰之通路 B2F 圆朱／卡吉侧（Gold Mahogany Side）单区普通行走开发

## 本轮的事实与资料核对

- 基线：用户 `REF-367.zip`，分支 `常规功能备份`，干净 HEAD `cd88452a05e9399b469f12fe2c6c89dd532dfcfb`，正式版本 `REF-367@`。
- 固定参考：`JOHTO_HANDOFF_REF306_FLAT_REFERENCES_交接文档.zip`，ZIP 校验正常；Gold 原始 `pokegold-master/maps/IcePathB2FMahoganySide.blk` 与项目 `maps/johto_ice_path_stage/IcePathB2FMahoganySide.gold.blk` 90 字节完全相同，SHA-256 `f55fa82f6c9d4242aa2f895515eefde406e701eb893bfdb4343687c5fc0839de`。
- Gold B2F Mahogany ID96（20×18 个 8×8 格；10×9 block）：44 FLOOR、304 ICE、10 WALL、2 LADDER。现有资源和专用 Gold 图块共用 ID41，无新图像改色。
- Gold 事件 #1 `(17,1)` 通往 B1F 原版事件 #2 `(17,3)`；#2 `(9,11)` 通往尚未启用的 B3F；#3–#6 `(11,4)/(4,6)/(4,12)/(12,12)` 为从 B1F 四个 PIT 掉下来的**到达点**，绝不能作为反向进入 B1F 的普通踩入 Warp。
- 原版 B1F 四个 PIT `(11,2)/(4,7)/(5,12)/(12,13)` 均维持封闭。落石对象须等实际 Strength+PIT 施工后再生成；不要制造隐藏阻挡或没有文本指针的石头 NPC。

## 当前功能与未完边界

- 新增活动地图槽 67，稳定 ID96；地图总数 67→68，登记路由 180→182。新图在地图 Header／运行 descriptor／Gold 图块源／音乐／地点牌／Town Map／存档名称／骑车与步行公共入口均登记。
- 只开放 B1F Gold #2 `(17,3)` ↔ B2F Mahogany Gold #1 `(17,1)` 这组楼梯。B1F/1F 旧楼梯、双室外口不改变。
- 此批 ICE 仅作普通可步行地面；合法 FLOOR 格允许新上车，ICE 上不能直接新上车。原先骑车进入状态不因本图新增拒绝逻辑而自动清除。
- B2F 通往 B3F 的梯子和 B1F 的四个到达点维持 `$ff` 非触发，其他 B2F Blackthorn Side ID97 和 B3F ID98 未激活。B1F 四块可见石头仍不可推动，不添加新宝可梦／NPC／剧情／道具／碎岩。
- 新增独立原生 LR35902 Gold role 读取器及步行／自行车判定，新增 `tools/johto_ice_path_b2f_mahogany_368a_audit.py` 和错误注入测试，更新公共 Warp／Field Moves 门禁。旧的滑冰方向控制仍 dormant 未接入实时移动。

## 测试与限制

- 本地只执行 Python 工具、静态 ASM 标签/格式审计和 Git 补丁正反向检验；**AI 不运行 RGBDS、不生成 ROM**。用户需使用 RGBDS 0.5.2 自行构建 Red/Blue/TEST 四版本、核对 MAP ROM0 ≥ 64B，并实际检查动画、图像、B1F↔B2F 两向楼梯、返回位置、普通步行与封闭机关。
- **重新编译 ROM 不会自动刷新旧模拟器即时存档中的 WRAM 地图对象／Warp 缓存。** 验收前在室外正常存档，使用新 ROM 重新进入洞穴；不要直接加载旧版洞内即时存档来判定楼梯失效。
- 项目完整迁移工具还有早期版本硬编码数量／路由的历史失败，必须如实记录，不能把专项审计 PASS 当作全项目 CLEAN。
- 开发版 `REF-368A@`；两份互斥开发 `.patch`，01 以本次用户确认的干净 REF-367 工作区为起点，02 同一已确认 CLEAN HEAD 的累计路线（两者不得叠加）。无自行 Commit/Push。
