# 城都地图连接防错检查器｜针对 `.147` 漏检补充

## 根因与职责边界

在 `.147` 制作过程中，`johto_rpp_batch.py` 的 `convert_one` 用于 **Gold 32×32 地形块转换与跳崖适配**，不会生成可用的 RPP 地图 Header/跨图连接。新建 `data/mapHeaders/JohtoRoute30.asm` 里的 `NORTH_MAP_CONNECTION ... -10, 0` 是移植整合阶段另外写入的内容，**不是原来的素材转换脚本自动生成的**。原有图块逐像素核验、跳崖核验与 Git 补丁核验，没有对 RPP 宏展开后的目标写入地址、复制宽度逐格做边界计算，因而漏掉错误。

Gold 原版 `data/maps/attributes.asm` 的 `connection north, Route31, ROUTE_31, -10` 表达地图**相对错位**。RPP 的历史 `NORTH_MAP_CONNECTION` 第三参数却直接参与数据起始地址/复制长度计算。对于 Route30 宽10、Route31 宽20，照搬会使目标地址变成 `wOverworldMap - 7`，复制长度为23（超过一行缓存16格），源列错选为0，构成越界和树块残影风险。

`.148` 用明确的 10×3 北向复制记录解决这条连接；用户实机反馈残留消失。这不意味着其它老连接可以批量改写。

## 此工具做什么

`tools/johto_rpp_connection_guard.py` 独立只读执行。对指定的**新接入**北/南连接：

- 从 Gold 的 attributes 与双方地图尺寸计算真正重叠的源列、目的列和预期角色进图偏移。
- 从 RPP 地图 Header 解析历史 `NORTH_MAP_CONNECTION` / `SOUTH_MAP_CONNECTION`，或 `.148` 使用的显式8字段连接记录。
- 严格核验3行源 `.blk` 是否越过原始地图数据、3行写入是否落在有效缓冲行内，及方向标志、宽度、地图尺寸、人物X/Y对齐、窗口字段。
- 任一计算不匹配时报 `FAIL` 并返回退出码 `2`，可用于打补丁前的 CI/命令行阻断。

**尚不支持 EAST/WEST；要求失败退出，不会伪称已检查。** 不检查人物/NPC、门/Warp、碰撞细节、实际 Bank 装箱，不能替代游戏编译和实机测试。

## 使用方法

在已经应用了拟发布代码的 RPP 项目目录执行（`--project` 指向实际待验收工程，不要指向旧 `.144`）：

```bash
python3 tools/johto_rpp_connection_guard.py \
  --project . --gold-root /路径/pokegold-master \
  --edge JohtoRoute30 JohtoRoute31 Route30 Route31 north \
  --edge JohtoRoute31 JohtoRoute30 Route31 Route30 south \
  --json-out connection_audit.json
```

成功 `PASS`、程序退出码 `0`；失败 `FAIL`、退出码 `2`。每接入一组新北南相邻地图，把**两个方向都列进** `--edge`。不需要编译游戏。工具不自动修改任何游戏数据。

用内置小样本回归测试：

```bash
python3 -m unittest discover -s tools/tests -p 'test_johto_rpp_connection_guard.py' -v
```

用回归用例证明：`.147` 旧宏 => FAIL（负地址、23列复制）；`.148` 两向连接 => PASS（10×3）；篡改复制宽度、复制源偏移、Gold 相对偏移、未开启的方向标志 => FAIL。

## 日后接入其他地图的规则

- 原版的 offset 只作为**空间关系参考**，不能直接套入 RPP 历史连接宏。
- 先计算双方实际重叠部分与缓冲边界，再选择现有宏或带明确宽度的连接记录。
- 尤其注意负值、大小不一的地图、转角以及连接段外的未开放边缘。
- 每个新地图先通过独立地形/碰撞检查，再通过**每个双向连接**的内存范围检查，最后提交给用户做手机实测。
- 后续要开放桔梗市东西方向时，先给本工具增加 EAST/WEST 模型与对应的失败/成功回归用例；本版本不会尝试自动推断这两种连接。

本工具修改只涉及 `tools/` 的 Python 静态审计、测试及文档。**不修改 `.148` 的已通过游戏代码，不编译 ROM、不提交 Git。**
