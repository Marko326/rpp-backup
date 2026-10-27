# P2-003 — 地区运行身份与旧存档兼容（开发待验）

## 本轮落地

- 地区身份采用 `(region, stable local ID)`，关都 `region=0`、城都 `region=1`。城都引擎句柄 `$FC` 只代表未来的载入通道，不作为地图身份存档，也没有为 `$E7/$F4/$0B` 建立旧城都别名。
- 从 `wMainDataStart..wMainDataEnd` 中六个未命名、源码未引用的已有保存字节复用：`$D79A`、`$D7B3`、`$D7B5`、`$D7C2`、`$D7C5`、`$D7C6`，分别存 magic0、magic1、current region、current ID、last region、last ID。此前旧注释称 unused，本轮静态检索未发现其它显式引用。源数据长度不变，其他 WRAM 地址不移动。
- **严格不碰** `$D7A4–$D7AB` 的地区图鉴资料，也不占用 `$D7A3`（道具例程用作临时字节）。
- 新游戏通过 `InitPlayerData` 初始化地区键为关都；读取主存档并通过原校验和后，验证两个标记、当前地区、城都运行句柄及已登记地图；缺标记／无效映射统一将身份校正为关都当前地图。关都 ID 按原 `wCurMap` 同步；上张地图为关都时按 `wLastMap` 同步。
- 存档前先校正 WRAM 地区键，再通过原有 `wMainData` 拷贝与校验和流程保存。不添加并行 SRAM 保存文件，也不修改原有 checksum 算法、SRAM Bank 或游戏存档长度。
- 在 Bank `$41` 实现 `JohtoResetRegionStateToKanto`、`JohtoValidateSavedRegionState`、`JohtoPrepareRegionStateForSave`、`JohtoGetPhysicalMapKey`。读取当前物理键时同步关都原有 `wCurMap`（以及关都前一地图 `wLastMap`），避免仅在存读档时更新造成中途切图返回旧值。跨 Bank 调用的地区键结果是 D/E，不依赖 A/进位标志。

## 当前限制与门禁

- 本阶段仍 **0 张已激活城都地图**。所有城都 local ID 在活动表里是 `$FF`，即便旧存档中碰巧有伪造的有效 magic，也不能激活城都。未修改 `LoadMapHeader`、Warp、Fly、Town Map、Sprite 或关都 `wCurMap` 的工作机制。
- 地区键已经在新游戏初始化、读档和存档时进行初始化／归一化；**这轮涉及存读档路径，应做最小旧档继续游戏→存档→读档、以及新开档初始化测试**，不能像 P2-001/002 一样完全省去实机验证。
- 城都首图接入前，必须补上显式的地区切换提交点（完整 Warp/地图 Header 资源成功解析后才更新地区身份），同步 LastRegion/LastLocalMapID，并验证 `$FC` 句柄切换和在城都存读档的落点；本轮不存在这些操作。
- 如果未来需要跨地区 `wLastMap` 镜像或存档故障回退，必须单独审计，而不是假设当前对旧关都状态的兼容逻辑已经覆盖将来城都的所有场景。

## 待用户构建检查

正式红、蓝以及能生成的测试 MAP：Bank `$41` 地区状态例程链接；ROM0 空闲与上轮 824B 对照；WRAMX/保存块边界不变。AI 未编译 ROM。补丁只能选增量或累计全量其中一份。
