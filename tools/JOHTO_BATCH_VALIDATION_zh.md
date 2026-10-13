# Johto / 金银批量地图转换验收工具（.135 后续工具阶段）

本次增加 **独立校验器** 和 **批量转换入口**，没有修改 RPP ROM 的任何地图、引擎或存档代码，也没有将候选地图自动导入游戏。现有 `.135` 地形转换器保留原样。**工具的绿色“静态通过”只代表候选字节和部分元数据通过校验，不代表游戏可运行。**

## 运行方式

需要 Python 3.9+ 和 Pillow（已有批量转换器使用 Pillow），以及一个完整、结构兼容的金银原始源码目录和 .135 版 RPP 工程。Gold 源码目录应包含 `data/maps/maps.asm`、`constants/map_constants.asm`、`data/tilesets/johto_metatiles.bin`、`maps/*.blk` 等。**本次交付包不包含金银原始源码。**

在 RPP 工程根目录执行：

```bash
python tools/johto_rpp_pipeline.py \
  --gold-root /path/to/pokegold \
  --project . \
  --output /path/to/staged_johto
```

注意：`--output` 必须位于两个源码工程**之外**，例如与 RPP 同级的独立空目录，以防覆盖工程。脚本不会把结果复制到 RPP 的 `maps/`、不会修改引擎，也不会编译 ROM。

重新校验上次生成的候选（例如修改了候选，需要重新检查）：

```bash
python tools/johto_rpp_pipeline.py \
  --gold-root /path/to/pokegold \
  --project . \
  --output /path/to/staged_johto --audit-only
```

- `staged_johto/verification/index.html`：浏览器直接打开的中文报告。
- `staged_johto/verification/verification.json`：机器可读校验结果、每张地图错误、分图块集覆盖信息及接入阻断项。
- `staged_johto/verification/previews/*.png`：原始和转换地图的并排视觉参考，橙色点为 NPC、蓝色为 Warp、紫色为标牌，默认最多12张；`--preview-limit 0` 关闭，`--preview-limit -1` 生成全部。
- `.135` 原有的 `full_gold_inventory.json`、`import_plan.json` 等文件仍在输出根目录。

注意图像预览两侧都使用 RPP 当前 Johto 图块素材，**只辅助检查布局，不证明像素与 Gold 源码艺术资源完全一致**；也不证明游戏碰撞、跳崖和事件脚本语义相同。

## 第 1 步补充：共享 Gold 地图布局资源（.136）

当前工具直接解析 Gold `data/maps/blocks.asm` 中的 `<MapName>_Blocks:` 标签和对应的 `INCBIN "maps/xxx.blk"`；连续多个标签引用同一份布局时，不再误判缺少 `maps/<MapName>.blk`。无法解析标签、文件丢失或尺寸不符仍然报错，**不会猜测或生成替代布局**。

新增的离线报告：

- `full_gold_inventory.json`：各地图新增 `source_layout`（实际源文件）、`shared_layout_with`（同一源文件的其他已注册地图）、`existing_rpp_legacy_alias` 和 `connections`。
- `full_gold_map_index.csv`：增加真实源布局路径、共享关系和既有 RPP 别名列。
- `shared_blocks_index.csv`：按源 `.blk` 分组，列出复用它的全部金银地图名称；一张地图的事件、Warp、地图 ID 仍然是独立的。

这些是 **P1 资源索引**，不代表商店和民居可以直接共用 RPP 的碰撞、NPC 或剧情；素材匹配和新增图块集的适配放在后续步骤处理。

## 何时算验收通过

| 环节 | 本轮自动完成 | 是否能声称游戏可用 |
| --- | --- | --- |
| 源 `.blk` 尺寸、哈希、地图清单、ID提议一致性 | 是 | 否 |
| 候选 `.blk` 尺寸、图块编号、共享区块索引 | 是 | 否 |
| Johto 地形区块视觉 ID 等价（排除已确认的克隆格） | 是 | 否 |
| Warp / 事件的数字坐标边界及目标名称初检 | 是（目标缺失给出警告） | 否 |
| 已接入若叶镇、29号道路的输出字节未被覆盖 | 是 | 否 |
| 非 Johto 图块集的实际美术/调色板/碰撞适配 | 否 | 否 |
| 地区地图 ID、Header/Bank、通用NPC与剧情脚本批量接入 | 否 | 否 |
| RGBDS ROM 编译，模拟器中跨图、进出建筑、存档恢复 | 否 | 否 |

校验器返回 **`FAILED`**（退出码2）表示存在确定的静态数据错误，不能进行下一阶段。`OFFLINE_REVIEW_ONLY`（退出码0）表示没有发现致命静态错误，但仍然**禁止直接导入 ROM**，相关复查状态会留在报告中。

## 为什么暂时不自动改 `data/johto_map_headers.asm`

原 RPP `ResolveRegionMapHeader` 虽然支持地区+本地编号，`LegacyMapIDToRegionKey`、`SyncLegacyMapRegions`、Warp 以及存档/回城等逻辑目前仍然依赖旧地图别名。单纯添加 Header 可能在切换地图或者读取存档时出现隐藏错误。

应当等有真实 Gold 数据进行全量静态审计之后，针对 **地图身份/连接/出入口/存档** 做一次共享层的系统改造；选取几种代表地图做自动 ROM 测试，再允许批量地图写入工程。不是按每张道路/房屋重新造脚本。

## 回归测试

```bash
python -m unittest discover -s tools/tests -v
```

测试包含模拟的多图块集地图，以及故意损坏候选区块编号、NPC坐标和29号道路候选数据的拒绝测试。模拟数据通过**不能替代**真实 Gold 源码或模拟器测试。
