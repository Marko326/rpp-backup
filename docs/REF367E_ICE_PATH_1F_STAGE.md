# REF-367E｜Ice Path 1F 分层开发：Gold 图像 + Header/Warp 骨架

**基线**：用户已提交的 `REF-366.zip`，分支 `常规功能备份`，HEAD `a95ac8d1ddaf47575bc4f08935033d014bfa58cf`。在 REF-367D 已安装的工作区上可用本批 01 增量；若仍是干净 REF-366 则选 02 累计全量，**二选一不可叠加**。用户没有上传最新手机未提交工作区，不能假设已安装 D。

## 本批只做第一层（ID70）

- **原版大小**：20×18 block = 40×36 8×8 cell；Gold `ICE_PATH` 固定夜色 `PALETTE_NITE`。1F 有 **234 格 ICE、61 格方向墙、2 格 LADDER、3 格方向跳崖、0 个 PIT**。Gold 原始 1F 地图块和四象限角色完全保留。
- 将已附的 Gold `johto_ice_path_gold.png` 按 0 白 / 3 黑 的 Game Boy 双位平面像素排列，固化为 `gfx/tilesets/johto_ice_path_gold_96tiles.bin`（96×16B），图像使用独立的 Gold 64-block `.bst`，不误用 RPP `ICE_CAVERN`。**二进制作为固定资源不受 `make clean` 的 `*.2bpp` 清理影响**。
- 新增 `data/johto_ice_path_stage/ice_path_1f_runtime_367e.asm`：独立 Gold 1F GFX、Block、角色数据、运行块、12 字节 runtime Header、空 NPC Script、四条 Warp 占位。**文件暂不 INCLUDE 于 main.asm**，也不在活动地图、tileset headers 和 Warp routes 中注册。

| Gold # / RPP ordinal | 1F 坐标 x,y | Gold 目标 | Gold 触发 | 当前骨架 |
|---|---|---|---|---|
| 1 / 0 | (4,19) | Route44 #1 | DOWN 地毯 | 已填写静态对象；不运行 |
| 2 / 1 | (36,27) | BlackthornCity #7 | DOWN 地毯 | 已填写静态对象；不运行 |
| 3 / 2 | (37,5) | IcePathB1F #1 | 踏入楼梯 | **封闭** `$ff,$ff` |
| 4 / 3 | (37,13) | IcePathB1F #7 | 踏入楼梯 | **封闭** `$ff,$ff` |

**重要原版拓扑**：在严格的单层步进／滑行模型中，Route44 端到烟墨城端不能仅靠 1F 地形互达；必须在后续开放 B1F 后跨层通行。本批不改 Gold 图块来造捷径。因而即便 1F 具备两条室外出口，其完整贯通验收仍是跨层任务。

## 为什么没有开放游戏入口

- 主程序目前缺失独立 ICE_PATH tileset 的实际 ROMX GFX/Block + ROM0 tile collision 注册；`ice_path_slide_state_367d.asm` 仍只处理调用者传入的方向 E，没有安全 WRAM/玩家逐帧步进/地图到达的真实接线。
- 打开 Route44 或烟墨城入口会让玩家进入不能保证滑动或安全返回的半成品，打开两处 B1F 楼梯会指向未注册目标。**不做这两种不安全激活。**
- 本批未修改 `main.asm`、`home/overworld.asm`、`wram.asm`、`constants/tilesets.asm` 或现行活动表、路由表。仍是 `REF-366@`、65 张地图、172 条注册 Warp。

## 本批测试与边界

- `python tools/johto_ice_path_1f_367e_audit.py --root .`：检查固定 2bpp binary SHA-256、96 tiles、1F Header/Gold 4 ordinal、B1F 断开及模拟单层路径，不用 Gold 源工程也可运行。
- `python -m pytest -q tools/tests/test_johto_ice_path_1f_367e.py`：包含真实变异注入，确认美术字节损坏、坐标错置、未完楼梯被打开时审计拒绝。
- `python tools/validate_current_project.py --skip-pytest`：与原有 ASM 检查、65 地图/172 Warp、Gold 冰面角色和黑暗洞穴审计共用入口；**旧主迁移审计中已有失败另列**，不以本地新审计 PASS 代表全项目 PASS。
- 未编译 ROM、未做 MAP 和设备测试，也未 Commit/Push。此批是开发阶段，尚不是可进入的冰洞。

## 下阶段顺序（仍然优先 1F）

1. 在后续一个开发批中实现 1F 独立 tileset 的真实 GFX/Block/ROM0 collision 读取，量化 ROM0 空间，查 Gold 固定夜色调色是否正确。
2. 给玩家一次完整行走动画成功后的滑冰朝向分配安全 WRAM，并在碰撞／动作完成／切图／Continue 等路径同步清零或继续；负向检测菜单、门口、前方 Sprite。
3. 两端室外洞口、出洞自动迈步和安全返回完成后，再开放 **仅 ID70 的 R2 局部验收**；B1F 两个楼梯仍不得提前打开。随后才施工 ID95 B1F 的 Strength 与 PIT。

### 构建/工具补充

本批统一验证过程中发现旧的 `tools/johto_ice_path_367_slide_audit.py` 在无 `PYTHONPATH=.` 的 CLI 环境下会报 `ModuleNotFoundError`，本批仅修正其启动时的模块检索路径，不改滑行 ASM，也不把原工具导入失败误报成新冰洞运行故障。镜像回归到主迁移审计时仍有 21 项历史合同失败，不代表全仓库全绿。
