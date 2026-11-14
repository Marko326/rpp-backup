# REF-368B@｜冰之通路第四层 B3F（ID98）单层普通步行开发候选

## 已核实资料与工程基线

- 用户 `REF-368A.zip`，导出标注分支 `常规功能备份`，正式 HEAD `cd88452a05e9399b469f12fe2c6c89dd532dfcfb`，其中 Worktree 已包含未提交的 REF-368A@ B2F 卡吉侧开发修改；本次在该 Worktree 上继续，**不覆盖或伪装为干净 HEAD**。正式已 Push 版本仍为 REF-367@。
- Gold 参考来自交接 ZIP 中的 `pokegold-master/maps/IcePathB3F.asm` 及工程 `docs/REF367A_ICE_PATH_GOLD_SOURCE_CONTRACT.json`。B3F Gold 尺寸 10×9 blocks / 20×18 cells，FLOOR 75、WALL 283、LADDER 2；`IcePathB3F.runtime.blk` 与 `IcePathB3F.gold.blk` 全 90 字节一致。
- Gold 楼梯 #1 `(3,5)` 通往 B2F Mahogany Side #2 `(9,11)`；Gold #2 `(15,5)` 通往**尚未开放的** B2F Blackthorn Side #2 `(3,3)`。

## 本轮实际开发

- 新增原生独立 ROMX `data/johto_ice_path_stage/ice_path_b3f_runtime_368b.asm`，注册稳定本地地图 ID98、活动槽 68、12B Header、Gold 地图块与 20×18 角色表，开启 1 组双向梯子（两条方向 Warp），其余未开放 Gold 梯子以 `$ff,$ff` 封闭。地图注册 68→69；方向 Warp 182→184。
- B2F Mahogany Gold #2 从封闭改为 `(9,11)` STEP_IN；B3F Gold #1 从 `(3,5)` STEP_IN 返回。两张地图到达原版 LADDER 时均原地停留，不额外迈步；维持四处 B1F PIT / B2F ICE 到达点为封闭源 Warp。
- B3F Gold FLOOR 可普通行走并允许重新骑车；Gold WALL、越界与未开放 Blackthorn 楼梯不可进入。未加入自动滑冰、怪力推石、落洞转移、碎岩、NeverMeltIce 道具、NPC、野怪或剧情。
- 同步注册地图资源、角色、音乐、存档名称、Town Map 索引、`Ice Path B3F` 地点牌，以及公开碰撞、Warp/Field Move 和自行车入口。B3F ROMX 独立 Bank；ROM0 仅为自行车公共入口增加极少量分支，未做 AI 链接或空间测量。
- 游戏开发标识 `REF-368A@` → `REF-368B@`，仍处开发阶段；只有明确要求正式清理时才去除字母并准备 Git 日志。

## 实际静态检查与限制

- `python tools/asm_symbol_preflight.py`、`python tools/johto_table_assert_preflight.py --root .`、`python tools/johto_warp_field_entry_gate.py --root .`、`python tools/johto_map_name_sign_audit.py --project .`、B3F 专项审计及新增错误注入 pytest 均可运行。新加 `tools/johto_ice_path_b3f_368b_audit.py` 检查活动表、双向 Warp、Gold 资源、碰撞、骑车入口与 Blackthorn 封闭，统一入口同步更新。
- Gold Ice Path 原阶段、B1F 和 B2F 审计更新了本轮允许边界，冻结的历史 65 图和 168 Warp 合同未放松。旧迁移总审计仍可能因旧版状态假设而红，不能把专项 PASS 说成全量验收。
- 本轮 AI **不编译、不链接 ROM、不提交、不 Push**；附带的旧 MAP 对应 REF-368A，不是 REF-368B，不能据此判断本轮 ROM0 余量。用户设备上的 0.5.2 编译、四版本 MAP、实际进出 B3F 两向楼梯与实时画面均未验证。

## 下一批明确剩余

- B2F Blackthorn Side（ID97），B1F↔其区域楼梯、B3F↔其区域楼梯；B1F Strength 四石头、四处 PIT、B2F 掉落石头；冰面滑行；B3F Rock Smash、道具与剧情另批施工。不能从 B3F Gold #2 进入未开放 ID97。
- 真实 ROM 构建前按原要求核对 ROM0 ≥64B、现有所有 Bank/WRAM/地图注册和两端 Warp，再进行旧模拟器保存状态刷新后的实机验证。

## 开发测试补丁应用

一个交付 ZIP 内有两个**互斥** `.patch`：增量为当前用户 REF-368A Worktree → REF-368B；全量为已确认 `cd88452a...` REF-367 Git HEAD → REF-368B（包含先前未提交的 REF-368A）。两份只能择一应用，绝不可叠加；不会在本阶段打包提交日志或工具反向补丁。
