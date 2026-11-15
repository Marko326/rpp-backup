# CLEAN REF-369｜冰之通路怪力推石、落洞与玩家下落阶段性收口

> **提交材料准备状态**：用户明确要求清理三件套和两笔提交日志；当前只准备 PATCH/TXT，不自行编译 ROM、不执行 `git commit`/`git push`。当前工作区为用户提供的 `REF-369V.patch`，目标正式显示 `REF-369@`。用户表示满意 REF-369V 当前的游戏效果，但**并未完成全图、所有存档及四版本 ROM/MAP 验收**。

## 1. 基线与数据来源（不得猜测）

- 用户导出声明：分支 `常规功能备份`；手机目录 `/data/data/com.termux/files/home/rpp-backup`；上次正式 Git HEAD `935b3fa738dce42f22768e94c92c920bb5b86d89`，显示 `REF-368@`；开发工作区 `REF-369V@`。
- 当前输入只有本次 `REF-369V.patch`，**没有 `.git` 元数据**。为验证真实性，采用用户此前上传的完整 `REF-369B.zip` 及官方交付时的 `02_REF-368_HEAD_TO_REF-369B_STAGE1_FULL.patch`，反向恢复 REF-368 源码；该恢复过程 `git apply --check -R` / `git apply -R` 成功。
- 从恢复的 REF-368 源码逐文件 `git hash-object` 计算本次 `REF-369V.patch` 的 99 项旧 Blob ID，**99/99 一致**；`git apply --check` 和正向应用本次用户补丁成功。这证明此次累计补丁的文件基线一致，但不等于在手机执行了 `git rev-parse HEAD`。
- 最终仅把 `data/game_version.asm` 从 `REF-369V@` 改为 `REF-369@`，并修订工具审计和维护说明；保留当前已经被用户接受的其他运行源码。正式序号 369 比上次提交的 368 加 1。
- 用户应在应用前再次运行 `git branch --show-current`、`git rev-parse HEAD`、`git status --short`，若实际基线或 Worktree 与导出不相同，应暂停。

## 2. 本轮正式纳入的功能（REF-368 → REF-369 的净变化）

1. **石头和事件位**：B1F 四块可推动怪力石头，四方向真实目标格与固定岩石/其他对象碰撞，四个 PIT 的状态记录，B2F 落石显示。落洞 occupancy 用 D852 bits2–5，源石头掉落用 D853 bits4–7；迁移与 Seafoam/出口锚点隔离，保持 D854/D855 不写。旧 REF-369A 曾错误占用 D855，受损 SAV 不自动猜测恢复。
2. **Gold 风格落石演出**：石头移动完整结束、进入有效洞口后立即隐藏；停顿、Strength 音效、±2px 震动和完整 `DisplayTextID` 的“石头落下”提示。隐藏对象保持合法 Sprite Picture ID，避免以前 Save 菜单返回时图片索引下溢导致花屏。
3. **推石局部反馈**：城都采用 Gold 两帧四象限烟尘和基于石头对象的跟随/隐藏后位置冻结，当前实现为双槽非存档临时状态；关东传统推石保留移动和落洞事件，但取消全局调色板闪白。Gold 完整临时对象池的多对象并发不是本期绝对等价承诺；用户已接受当前表现，本次 CLEAN 不改它。
4. **玩家 PIT**：Ice Path B1F 四个原版坑进入 B2F Mahogany 对应的单向落点，B2F 四个 ICE 格只接收、防反向触发。玩家坠落与石头存档事件位分离；烧焦塔和 Ice Path 玩家 PIT 使用已存在的黑色换层处理，跳过普通门声但保留坠落/落地自身音效。普通楼梯、房门不受影响。
5. **冰面与图形**：ICE 自动滑行使用既有 B 加速步长（目标约 8 显示帧/格），不改变普通步行/骑车/冲浪；B1F 和 B2F Mahogany 原版岩石 Border Block 修正为 `$19`；Ice Path 洞穴 OBJ 使用夜间岩石灰紫色，不修改关东全局调色板。
6. **已回退的中间尝试不计最终功能**：REF-369C/D 的 Save 图块重载与 REF-369U 的额外 B2F `UpdateSprites` 预刷新均已撤销，不能写成最终成功的“新增功能”。

## 3. 本轮实际未完成，不能在提交日志里冒充成功

| 分类 | 状态与后续处理 |
|---|---|
| Ice Path B2F 落石首帧 | 用户录制发现从玩家落洞到 B2F，已落石可能直到角色落地后才可见；REF-369U 预刷新无效且 REF-369V 已撤销。本轮接受视觉差异，**不称修复成功**。 |
| Kanto Seafoam B4F Surf 上岸 | 用户新录像在部分非常规格能够上岸；当前 `CollisionCheckOnWater` 的关东 `.legacySurfTile` 在跨 Bank Johto 判定后可能仍使用被覆盖的 C 值。需独立修复、双地区碰撞回归及对原作者末版的实机对照，**本 CLEAN 未修**。 |
| 金版严格烟尘一致 | 当前双槽烟尘不是 Gold 完整 TempObject 池；用户明确接受当前视觉表现，**不继续调帧**。连续快速多次推石的极端并发仍有覆盖边界。 |
| 城都 Fly/Town Map | 普通城都 Town Map 45 地点顺序此前已与 Gold 对齐；Fly 的湛蓝/卡吉顺序、未开放白银山及愤怒之湖自定义轴需在开放对应地点时决定是否还原。关东使用项目自定义导航。 |
| REF-369A 旧存档 | D855 Fly/Articuno 事件曾被旧版本误写；迁移只阻止继续污染，受损历史不能无损推断还原。 |
| 后续玩法 | Ice Path Rock Smash、NPC、道具、野怪、剧情未实现。 |
| 全面验收 | 四石/四坑组合、四玩家洞、关东推石/Surf、旧 SAV、四版本 ROM/MAP、ROM0 余量及 ROMX 需用户继续检查。 |

## 4. 为什么原有检查会漏报、清理中如何防回归

- **隐藏精灵**：旧检查仅查图块/事件存在，没检查菜单返回调用 `InitMapSprites` 时 Sprite Picture ID 为 0 会减一越界；后续在 `johto_ice_path_sprite_hide_369e_audit.py` 增加了源级保护与错误注入。
- **Save 假入口**：旧版只检测存在 `ReloadTilesetTilePatterns`，未沿真正 `StartMenu_SaveReset → HoldTextDisplayOpen` 路径核对，导致 REF-369C 的旁路修复被误判成功；开发阶段加入真实路径负向检查，最终取消无用重载。
- **推动与落洞**：早期只检查石头当前格而非推动后目标格，缺少 NPC 移动完成后的落洞判定及文本生命周期；现存 369H/O/P/S/V 审计分别检查方向、时序、对话和玩家单向 Warp。强制审计入口 `tools/validate_current_project.py` 已登记当前 O/P/Q/R/S/T/U/V 审计脚本（本轮未再重复新增一套生成器）。
- **长跳分支历史误报**：旧 B1F/Blackthorn 审计硬编码 `jr z`，但用户已验收工作区使用合法 `jp z`；本次只把审计与对应负向用例改为检查真实 `jp`，故意改回短跳／错误目标必须 FAIL。**没有修改运行时的跳转。**
- **工具权限隔离**：本轮新增 `tools/johto_ice_path_save_flag_audit_369b.py` 按项目入口始终由 Python 解释器运行，正式清理统一为普通可读 `.py` 权限（100644），以保证工具隔离补丁反向恢复后 Git 可执行位确定；脚本正文与调用行为不变。
- **正式版号**：多份旧审计把 REF-369V@ 写成唯一合法开发版号。本次统一改为严格要求 REF-369@，保留原有目标格、PIT、OAM、SAV 和关东隔离断言，不放宽为任意字符串。
- **覆盖边界**：源码审计与 pytest 均不能证明音视频逐帧、GB Bank、真实 ROM 构建或所有 SAV。全仓库历史冻结地图/Surf/Warp 断言失败应单独分类后修，不靠删除或修改游戏行为“凑绿”。

## 5. 真实执行的检查与未通过项

> 下列结果由本轮 CLEAN 对重建的最终源码执行；正式提交日志只记录功能/工具内容，不在日志正文写测试统计。

- 基线复原：`git apply --check -R` / `git apply -R` 前期 REF-368→B 累计补丁；本次用户 REF-369V `git apply --check` / 正向应用成功；`git hash-object` 比较 **99/99** 文件旧 ID 一致。
- 本次专项：`python -m pytest -q -p no:cacheprovider` 加 17 个 REF-369 相关测试文件，**234 passed**；清理 B1F/Blackthorn 路由后的检查分别 **18 passed**、**11 passed**；最终在 CLEAN 源码上把 19 个对应测试文件合并重跑，**263 passed / 0 failed（2.19 秒）**。包含长跳转改错的负向验证。
- 全量：`PYTHONDONTWRITEBYTECODE=1 python -m pytest -q -p no:cacheprovider tools/tests` 初次运行 **1,332 passed / 86 failed / 189 skipped / 95 subtests passed**；修正两项已证实过时的 B1F/Blackthorn 长跳审计及负向用例、清理测试空白后，对最终 CLEAN 源码重跑得到 **1,334 passed / 84 failed / 189 skipped / 95 subtests passed（32.43 秒）**。失败仍包括旧地图数量、Warp 和 Surf 阶段冻结合同、Gold 源依赖及部分旧功能合同；**不能称全仓库通过，亦不能把全部 84 项自动定性为无害。**
- 统一项目入口：`PYTHONDONTWRITEBYTECODE=1 python tools/validate_current_project.py --skip-pytest`，第一次遇到旧 B1F `jr` 断言 FAIL，修后又遇旧 Blackthorn `jr` 断言 FAIL，已按真实运行源码更新检查器。修正旧断言后最终入口为 **前 35 项现行检查 PASS，最后 current migration audit FAIL：1,523 passed / 36 failed（1,559 条）**；全入口仍返回非零退出码，不能把“前项 PASS”冒充整个入口 PASS。
- **没有执行** RGBDS Red/Blue/TEST Red/TEST Blue 编译或链接；没有新四目标 MAP 及 ROM0≥64B 的本轮证据；没有新模拟器/手机实测；没有 Git Commit/Push。

## 6. 双提交补丁的正确安装与顺序（项目模式 A）

交付 ZIP 只包含 **01、02、03 三份补丁和两份 TXT**。文件编号含义：

1. `01_*`：已经安装本次用户 `REF-369V.patch` 的实际开发工作区 → 全部 REF-369 CLEAN。或从干净正式 `935b3fa...` 基线执行 `03_*`，直接得到同一个 CLEAN。**01 和 03 两条路线绝对互斥，不得叠加。**
2. 完整 CLEAN 工作区：先执行 `git apply --check 02_*`，再 `git apply 02_*`；只撤下累计工具／测试／维护文档，保留全部游戏 ASM、图像及 `data/game_version.asm`（REF-369@）。
3. 使用功能日志作为第一笔提交说明，由用户自行 `git add`/`git commit`。必须检查暂存区没有包含 `tools/` 和维护文档。
4. 功能提交后执行 `git apply -R --check 02_*`，再 `git apply -R 02_*`，**恢复**工具/测试/文档到完整 CLEAN；按工具日志自行进行第二笔提交。
5. 第二笔完成后用户自行决定是否 Push；确认 `git status --short`、`git log -2 --oneline`、`git rev-parse HEAD`，再次执行完整工程验收。
6. 这些步骤只适用于初始 REF-368 HEAD 或与文件 Blob 完全一致的未提交 REF-369V 状态；有未说明的用户额外修改应先保留备份，禁止强打补丁或删除工作树差异。

## 7. 用户最小手机复测清单

- [ ] 冰之通路 B1F 四石推动至墙/其他石头/未填坑，坑中石头先消失、震动和 `The boulder fell through.` 文字可正常关闭。
- [ ] 玩家分别踩四个 PIT，B2F 对应落点只接收、不反传；已落石后于玩家落地出现的**已知时序差异**不影响可走动与存档。
- [ ] 冰面滑行、撞墙停止、普通走路和既有 Bike；五层楼梯与 Gold 边界；B2F Save 后即时不花屏、重启读档正常。
- [ ] 烧焦塔和冰之通路玩家落洞无门声、黑色换层，普通门/楼梯不受影响。
- [ ] 关东 Seafoam B4F 非法上岸专项（当前已知问题，不在 CLEAN 中修）、关东怪力不整块闪白、原落洞状态无回归。
- [ ] 新 SAV 和保留的旧 SAV、四版本 ROM/MAP、ROM0 和 ROMX 安全。

## 8. 后续开发遵循的规则

不复制旧的版本号冻结断言；每次启用新地图必须重新检查源 Warp ordinal、目标落点、Gold role/blocks、碰撞、OAM/VRAM、全区域 Surf/Fly/Bike 和上岸合法性。变更存档位要证明相邻 bit 所有权；新增 Bank 调用检查 A/BC/HL 被覆盖风险；禁止使用纯画面截图替代存档与完整地图生命周期验收。提交日志只描述上次正式版本以来**真实保留的净功能**，不将中间已回退尝试重新写成完成项。
