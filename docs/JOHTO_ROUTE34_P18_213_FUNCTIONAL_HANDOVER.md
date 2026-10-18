> 历史 .213 候选（用户视频否决进出门体验）。请参见 `JOHTO_ROUTE34_P18_214_DOOR_STEP_FIX.md`。

# P18 · ILEX-5.62.213｜北门房与 Route34 接入候选

状态：**源码和双源码静态检查完成；RGBDS ROM 编译、链接 MAP 与手机实机尚未验证**。不等同于游戏已验收，不是提交版本。

## 固定基线与复用原则

- 基线：已提交 .212（用户 `test(tool)` 工程）；若先应用过 P18 离线预备补丁，可直接应用本次增量。不可叠加增量和全量补丁。
- 门房机制：复用 `johto_indoor_pipeline.py`、`johto_indoor_tiles_converter.py`、`CheckWarpsNoCollisionLoop`、`CheckWarpsCollision`、`ExtraWarpCheck` 和已有地图 Gold mask 模块。不新建门房引擎或重复解析工具。
- 北门房采用 Gold `NorthSouthGate`：9 种 block 精确还原，旧 `JOHTO_GATE` 14 个 compact blocks 的内容与原槽保持，追加 5 个 block，复用 6 个未占用的 8×8 图形槽。Route34 复用 `JOHTO_MODERN` 原 blockset。
- 为新门房使用独立的 Gold 16×16 blocked mask，不将 `JOHTO_GATE` 或 Kanto Gate 通行白名单整体改宽。

## 已接通的出口与动作

- 桐树林北口 **(1,5)** 单 Warp，UP 撞门进入北门房南侧 **(4,7)**。森林南口 (3,42)/(3,43) 和已验收的南门房不改。
- 北门房南侧 **(4,7)/(5,7)**：DOWN 撞门均返回森林 (1,5)，不会站立自动传送。
- 北门房北侧 **(4,0)/(5,0)**：UP 撞门分别前往 Route34 的 (13,37)/(14,37)。
- Route34 南侧 **(13,37)/(14,37)**：DOWN 撞门分别返回北门房上侧两格。
- Gold 下侧 carpet 两格从正上方、从左右邻接 FLOOR 进入均允许；其他边界和墙保持阻挡。北侧未实现的 Goldenrod 连接与剧情对象暂不开放。
- 新图块使用 Gold 的源 tilepal 标签与项目既有 Gold Gate RGB 表；Kanto 及已完成门房图块数据不改。
- 桐树林已冻结 HOP 继续禁用（ILEX-LEDGE-001）；不引入大葱鸭/HM/徽章剧情。

## 本轮静态验收与已知限制

- 设置 `JOHTO_GOLD_SOURCE`、`JOHTO_GOLD_ROOT` 为 Gold 项目根后运行 `python3 -m unittest discover -s tools/tests -p 'test*.py'`：**501 项通过**。
- `johto_masked_step_audit` 五张地图、26 条动作边、19 条应可通行边均经源分支模型检查：0 failures；其状态是 `SOURCE_BRANCH_CHECK_ONLY`，**不是 CPU/ROM 仿真**。
- 旧全量 Gold 扫描中的 `SafariZoneBeta` 图形窗口错误为原有独立问题，本轮不靠删除检查伪造全门禁通过。
- 当前运行环境无 RGBDS 0.5.2，**未运行 ROM 编译/链接/实机**，未产生 `.213` ROM/MAP；旧 MAP 显示 Bank43/44 空间较充裕，但不足以证明新链接成功。
- 用户工作区未被自动修改，尚未执行 Commit/Push。

## 用户在 Termux 编译通过后最小实机验收

1. 从森林 (1,5) 进入北门房，检查进入位置与画面/色彩；停在门垫或仅横向换列不自动回传，DOWN 立即返回森林。
2. 北门房两条顶部出口分别进入 Route34 (13,37)/(14,37)，DOWN 立即原路返回；左右门垫和邻接地砖通行正常。
3. 北门房左右墙、森林北口旁边树墙、Route34 未接边界均不可穿越；不能出现自动行走、卡门或“必须后退一步才能再次进门”。
4. 实测两个旧门房、桐树林南门、Kanto Gate 的颜色和往返；森林 Cut 正常，冻结的跳崖不触发。
5. 检查 Town Map、音乐、存档/读档、地图载入普通与快速两条路径。出现不一致须先看本轮新 MAP/ROM 构建日志，不应盲改公共入口。

只有实际编译链接通过且手机确认这些行为后，才能将本候选标记为可玩验收，不提前进入清理三件套。
