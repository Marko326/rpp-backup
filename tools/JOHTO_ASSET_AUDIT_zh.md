# P1-3：Gold 与 RPP 素材复用审计（离线工具）

**定位**：承接已提交 `.136` 的地图资源索引，不修改游戏功能、不导入地图、不替换任何素材。先生成“RPP 能否复用”的候选证据，供后续人工选择和转换器开发。

## 前提与依赖

- RPP 工作区**已经有** `.136` 的 `tools/johto_gold_sources.py`。本轮新增工具复用它解析 `data/maps/blocks.asm`，不会自建第二套冲突的共享布局逻辑。
- 需本地拥有完整 `pokegold` 源码和 RPP 工作区。两个目录不应相互嵌套。
- Python 3.9+、Pillow（用于 PNG 图形比对）：`python -m pip install Pillow`。
- 金银图块定义：`data/tilesets/<name>_metatiles.bin`（一个 32×32 区块对应 16 字节）；金银图形：`gfx/tilesets/<name>.png`。
- RPP 图块定义：`gfx/blocksets/<name>.bst`；RPP 图形：`gfx/tilesets/<name>.png`。
- 默认两边 PNG 的 **8×8 图块按行顺序**排列。这是工作假设，必须在真实工程中核对导出和引擎加载逻辑；若 PNG 不存在，工具不伪造图形匹配。

## 执行命令（RPP 工程根目录）

```sh
python tools/johto_rpp_asset_audit.py \
  --gold-root /绝对路径/pokegold-master \
  --project . \
  --output /两套工程之外的新空目录/rpp_asset_audit_p1_3
```

输出目录必须不存在或为空，且 **不能在 Gold、RPP 源码目录内部，也不能是它们的父目录**。工具失败时不覆盖已有报告，绝不写入 `maps/`、`gfx/`、`engine/`、`home/`、`data/`。

自动生成：

| 文件 | 用途 |
|---|---|
| `00_审计摘要.md` | 中文汇总、首段城都路线优先复核的区块 ID |
| `asset_audit.json` | 所有匹配、异常、图块集和地图数据；便于后续 V3 转换器读取 |
| `tileset_summary.csv` | 金银每套图块集在 RPP 的候选覆盖率 |
| `metatile_matches.csv` | 每个金银 32×32 区块的候选 RPP 图块集与 ID、来源碰撞标签 |
| `map_material_priority.csv` | 各地图的区块使用频率及需人工复核的高频区块 |

## 六种候选状态

1. **`PIXEL_EXACT`**：用两套 PNG 的 8×8 贴图分别拼成 32×32 图片，最终 **RGBA 像素完全一致**。这仍**不是可直接使用证明**，图块集加载、四角碰撞、地图机关、区域调色板还要单独审查。
2. **`PATTERN_ONLY`**：忽略实际颜色，把整张 32×32 图的不同颜色按出现先后编号后得到同样像素形状。只是美术候选，必须核对色表与实际外观。
3. **`RECOMPOSE_8X8`**：不一定存在整块 32×32 区块，但同一套 RPP 图块集中已有构成这块图所需的全部 8×8 图片。报告给出 16 个 RPP 小图块的编号组合，仍须新增区块数据并检查图块容量、碰撞与调色板。
4. **`RECOMPOSE_PATTERN_8X8`**：同上，但只匹配忽略颜色的形状；不等于艺术资源真正吻合。
5. **`RAW_BYTES_ONLY`**：仅 16 字节图块索引相同，但没有已确认的像素匹配；这是最容易被误判的情况，**不能直接迁移**。
6. **`UNMATCHED`**：未发现上述候选；优先尝试 RPP 8×8 图块重组，最后才考虑导入 Gold 新素材。

候选会显示同名图块集优先，但不会因此提高可信等级。一个 Gold 区块可能同时对应多个 RPP 区块，报告记录 `candidate_count` 并只展示最前 8 个，不自动选择其中之一。

`collision_status` 只有待检查或缺失警告：**不进行任何 Gold collision → RPP 可通行属性的自动映射**；这一步留给专项碰撞映射表与实机检查。

## 先复核的地图顺序

`CherrygroveCity → Route30 → Route31 → VioletCity`，以及已完成的 `NewBarkTown / Route29` 用于做视觉与碰撞参照。

先检查 `map_material_priority.csv` 中这几张地图的高频未匹配 ID，再进入 `metatile_matches.csv` 查看候选与 Gold `tilecoll`。一个候选被人工确认以后，应记录**源 Gold 区块 / RPP 目标区块 / 图像验证 / 碰撞验证 / 是否需补素材**，作为后续真正自动生成 `.blk` 的映射表输入。

## 本轮测试与阶段边界

```sh
python -m unittest discover -s tools/tests -v
```

P1-3 工具共有 15 个合成测试（原 11 个，加 4 个真实格式回归测试），使用**合成地图与 PNG**验证：像素相同、8×8 小图块重组与仅图案相同的区别、共享布局引用、错尺寸/越界图块、碰撞计数异常、禁止源码目录写入、输出稳定可复现、源码原始文件不变等。

**2026-10-13 真实源码验证记录**：用户提供的 `.136` RPP 导出工作区与 `pokegold-master(1).zip` 已实际扫描。工具阶段回归 **23/23**（含 P1-3 15 项）通过；全量审计报告：Gold 368 张登记地图、28 套图块集、RPP 32 套 `.bst`。Johto Gold 128 个区块都有同编号的 RPP `johto` PNG 像素完全一致候选；首段 CherrygroveCity → Route30 → Route31 → VioletCity 的所有布局格均有候选。**仅是离线画面证据，不是碰撞/地图连接/游戏运行验收。**

### 真实源码特殊格式和仍待处理事项

- `gfx/tilesets.asm` 中连续的 `TilesetCaveMeta::` / `TilesetDarkCaveMeta::` 及对应 Coll 标签共用 `cave_metatiles.bin` / `cave_collision.asm`。审计工具现在**读取汇编声明**定位 Gold 区块、碰撞来源，而不是按 dark_cave 名字猜路径；输出会注明真实来源。没有声明时沿用常规命名，仅供精简合成 fixture 使用。
- RPP `gfx/blocksets/facility.bst` 当前 **2049 字节**（128 × 16 + 1 个末尾 `00`）。仅对此已识别的具体旧格式，离线解析前 2048 字节并在 JSON / 中文摘要标记 **1 个残余字节**；不修改原文件、不推断游戏运行时是否忽略尾字节。其他异常 `.bst` 仍按错误拒绝。
- 真实 Gold 有 **94 个区块**因 PNG 缺失或图块索引超出当前图集范围无法像素确认；RPP **15 套区块集**没有同名 PNG，不能做像素级比对。这些是审计覆盖限制，**不可**将其当作缺素材、或默认为可用。
- 对第一批路线仍须人工审查调色板与加载时 bank、RPP 的图块/区块编号与容量、碰撞与跳崖规则。**不自动改 `.blk`、不加入新的地图 Header、不编译 ROM。**


本轮仅新增 `tools/` 脚本、测试和说明；不改变 `data/game_version.asm`，当前 ROM 仍标识 `.136`。尚不进入“清理三件套/正式提交”阶段，下一轮可以根据真实报告校正后再一并整理工具提交。
