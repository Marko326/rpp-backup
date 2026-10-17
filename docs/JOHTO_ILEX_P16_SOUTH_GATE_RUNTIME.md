## P16 正式收口：GATE-5.62.202（P16F 用户手机视觉反馈）

用户在 P16B 报告双格门内外进出已修复；P16D 发现地点弹窗和整体调色错改，P16E 恢复正确紧凑图块映射，P16F 最终使用门房专属 RGB 修复半圆亮纹。最新 P16F 同地点游戏截图与 Gold 原版对比，用户确认背景效果无明显差异并接受非关键微小色差；两个门房均已观察。此为**本门房已测操作与视觉**的反馈，不等于逐项存读档/所有旧门房/ROM 空间验收。仍保留森林西口封闭。以后新门房必须先读 `docs/JOHTO_GATEHOUSE_READ_FIRST.md`，再登记八类静态测试与当前手机状态。下方“待实机”均为历史阶段措辞，由本段最终验收优先解释。


## P16F 色值校准（Gold 原版 vs RPP 专属门房）

对原版 `gfx/tilesets/bg_tiles.pal` indoor 段与 `color/data/map_palettes.asm` 实际 RGB 值进行对比；`tilepal` 标签匹配不代表调色表内容匹配。映射不同仅有 GREEN[0] 和 BROWN[0]；RPP 使用两个未使用的 palette ID 0x28/0x29 对 `JOHTO_GATE` 单独加载 Gold 原值，不改关东 `GATE` 和 `INDOOR_GREEN/BROWN` 的现有定义。P16E 用户录像半圆仍有差异，P16F 仅为静态修复候选，待用户编译和实机确认。

# P16B｜桐树林南门房卡门修正（GATE-5.62.198）

**实际手机反馈：P16A 有自动进门、门内外反向卡住、外侧两格上下受阻、门房西侧外观像半间房半片树林的问题。P16A 的静态 391 PASS 未覆盖行为。该版本不能记为用户通过。**

## 当前修正的运行行为（仍待手机验收）

- `home/overworld.asm` 以 `(JOHTO, local 10/11)` 识别两端门房 Warp，踩上门垫只置 `wd736 bit2`，不传送；实际朝左（桧皮镇）/朝右（门房）撞门框才进入既有 `CheckWarpsCollision`/`WarpFound2`。
- `engine/overworld/player_state.asm` 在 `IsPlayerFacingEdgeOfMap` 为桧皮镇 `x=2,y=10/11` 增加精确西向触发，保留已经实测的 Route31 门房和普通关东门框检查；不对共用 `$FC` 句柄的其他城都地图开放。
- `JohtoAzaleaCanStepAhead` 只增加 `(2,10) <-> (2,11)` 两格门垫之间的纵向行走；入口上方 `(2,9)` 和下方 `(2,12)` 仍是原版墙，不开放其它建筑/井/树林。
- 删除 P16A 的 `JohtoAzaleaGateWarpTileCheck` 站位即传送的重复逻辑；旧 `JohtoRoute33CaveWarpTileCheck` 完全保留。现有 Warp 坐标、目标、地图和图块资源未变。

## 外观问题：已制作局部西边框渲染候选，仍待手机验收

RPP 桧皮镇 20×9 `.blk` 与 Gold 原版逐字节一致；`JOHTO_MODERN` 的门房邻近 metatile `$1e/$0b` 也与 Gold 一致。但在 RPP 的左侧地图边界之外，`JohtoAzaleaTownObject` 使用通用树林 `$05` 作填充，房屋延伸部分显示为树林。因此用户描述的「左侧半栋建筑」合理，**不能简单全局把 `$05` 换成房屋，否则其余四周边界也会损坏**。本次在 `LoadTileBlockMap` 之后、绘制 VRAM 之前，对 `(JOHTO, Azalea local 10)` 唯一地图的西侧图外缓冲，在逻辑块行 4 和 5 的西边临近格分别写入与原版 `(0,4)/(0,5)` 相同的 `$09` 屋顶和 `$1e` 墙体区块；门房看起来会向西延续一个 32×32 区块宽度。地图 180 个 Gold 区块、原版碰撞掩码、Warp 坐标和所有其他地图的边框 **完全不变**。该方案已进行离线像素预览和静态范围核对，`visual_border_status=STATIC_CANDIDATE_PHONE_PENDING`，但手机实际观感和 ROM 链接 **尚未验证**。

## 静态与验收边界

- P16B 完整 Gold+RPP：**399 PASS / 0 FAIL / 0 SKIP**，其中 14 项南门房专项测试含反向注入。测试有对站位即传送、方向颠倒、地图 ID 误判、上下移动缺口的错误注入。
- 不编译/链接 ROM；旧 `patches/rppred.map` 不能证明 `.198` Bank 空间。没有手机实机证据，外观修复只属静态候选，不标记手机已通过。
- 下次新门房必须同时验证：视觉边框、室内外踩格延迟、朝门框碰撞、立即反向、左右两排上下自由走动、其它方向擦过不传送、两格进出、Continue/Fly 最小回归。

# P16A｜桐树林南门房首批运行时候选（GATE-5.62.197）

> 基线：用户最新干净工程导出 `2f08f49a`（`FLY-5.62.196`）和完整 `pokegold-master`。先接 P15 离线工具修复，再接 P16A 门房。**没有接入桐树林室外运行时地图**；这轮不执行 ROM 构建、链接或 Git 提交。

## 已接入的范围

- 金银原版 `IlexForestAzaleaGate` 5×4 区块，独立 Johto local ID 11（共 12 张 native 地图）；使用与 Gold `EastWestGate` 经过 13/13 逐图块匹配的现有 `JOHTO_GATE` 图块及已验证的 `JohtoRoute31VioletGate.blk` 字节布局；独立地图 Header、对象表、脚本入口、音乐、地图身份。
- 桧皮镇原版 `(2,10)` / `(2,11)` 两格 Warp，RPP 0-based slot 0/1，目标南门房 `(9,4)` / `(9,5)`（RPP 对象表使用 Y,X），精确双向 `REGION_WARP_ESCAPE` 和地区+局部 ID 映射，不把共享 `$FC` 当目的地。
- 桧皮镇只准从 `(3,10)/(3,11)` 面向西移动到门口 `(2,10)/(2,11)`；新增独立精确 Warp 脚本判断，不向全体共享 `JOHTO_MODERN` tileset 放行。以前接受的 Route33 出入口、Azalea Fly、跳崖和其它封闭门仍维持原状。
- 南门房西侧前往森林的原版出口 `(0,4)/(0,5)` **暂未登记 Warp**，地图边缘不允许跳到未接入 Forest；不复制未实现的 NPC/剧情，空文本对象不冒充真实对白。
- 地标使用原版 Route34、门房沿用路线音乐；地图为室内 `JOHTO_GATE`，保留门房下车和相关技能权限隔离。无新的 Fly 目的地、不更改任何存档位或地图数据布局。

## 为什么没有直接开放桐树林

Gold 森林 15×27 区块，涉及独立 `TILESET_FOREST`、39 种实际使用图块、原版 `forest_collision.asm` 64 定义及需审核的 6 处特殊跳崖，既有 RPP `forest` 无一使用区块能做到像素精确复用。未经专用森林图块/调色/碰撞、剧情阻断、南门房返回入口和北侧封锁完整审核，不应把森林宣称为可玩。森林 Forest native local ID 尚未分配。

## 本轮静态验收

- 通用 `tools/johto_map_release_audit.py` 严格独立 Gold 审计：391 PASS / 0 FAIL / 0 SKIP；P16A 强制六项正向/错误注入回归包含缺路口、错目标、释放森林、错误局部 ID、共享 `$FC` 越权、门房权限错误。
- 该结果仅是源码级审核。项目 `patches/rppred.map` 是旧版本构建记录，**不能证明 `GATE-5.62.197` 的 ROM/Bank 空间或汇编链接通过**。仍需要由用户在 Termux 构建和手机测行为。

## 最小手机验收（此次必须测）

1. 先从桧皮镇西口 `X=2,Y=10/11` 两格分别尝试进入南门房，再从室内东侧两格返回桧皮镇；检查画面、音乐、传送后坐标、角色方向和不会二次弹回。
2. 在门房向西尝试走到桐树林：应保持封闭，不允许走进黑图、错误地图或越界；门房内部正常行走并自动下车。
3. 在门房存档、重读后再出门；抽测桧皮镇原有33号道路双向连接、Fly 目的地和出入口未回退。
4. 若 Termux 汇编或链接失败（例如符号/Bank/空间），请保留完整日志；静态 PASS 不能代替该结果。

## 补丁基线

- **全量**：直接针对本次上传的 `2f08f49a / FLY-5.62.196` 干净 ZIP，一次包含 P15 离线工具修复 + P16A 门房运行时。
- **增量**：只针对已经成功应用 P15 前置补丁、但尚未应用 P16A 的工作区。
- **二选一，不可叠加**。没有擅自编译 ROM、Git Commit 或 Push。

## P16D 地点名与调色复查（GATE-5.62.200，待实机）

- 用户截图显示进入门房意外弹 `Route 34`；Gold 的地标与 RPP 的门房显示提示属于两项不同系统，不能改 Town Map 地标来消除 UI 错误。`engine/overworld/map_name_sign.asm` 只针对 `(wCurMap=$FC, Johto, local 11)` 增加 neutral 例外，参考已验收的 Route31-Violet gate 行为。
- Gold `EastWestGate` 13 个使用区块/22 个使用图块几何像素精确，但紧凑 `JOHTO_GATE` 的 `tilepal` 曾有 11 个 palette tag 与 Gold 源图块不一致；本轮根据 Gold `gate_palette_map.asm` 修正，并加静态逐图块反向检查。
- **仍待验收**：截图中拱形装饰缝隙的亮绿色相对 Gold 米白有差异；静态调色标签校对不证明 ROM 中 CGB palette 运行时选择正确。修订编译后需手机看颜色；若仍不同，记录实际调色槽位再专项修。门内外碰撞/双向出入、桧皮镇外侧房屋仍沿 P16C，不作额外行为改动。
- 门房门禁现在除原版 Warp/碰撞外，强制核查 neutral sign、Gold palette、手机验收状态，禁止把纯静态 PASS 当实机验收。

## P16E 视频回归与 palette ID 真映射修复（GATE-5.62.201，待实机）

P16D 曾按 Gold 已用原 Tile ID 的排序顺序当成 RPP compact 编号来重排 palette，忽略 `.bst` 中真实的 ID 置换。用户 `.200` 录像确认导致整间门房由灰白/蓝紫变为亮绿。源布局+两侧 metatile 逐格对齐后证实原 P16C 22 项映射全部正确，P16D 实际引入 10 项错误；P16E 恢复 P16C 标签，并用 `.blk + .bst` 强制重建真实映射，加入模拟 P16D 错误配置的负向测试。P16D neutral map-name 改动与已验收 Warp 保留。原版与本项目仍可能有少量运行时调色差异，待手机确认，不等同全部 CGB 色值验收。
