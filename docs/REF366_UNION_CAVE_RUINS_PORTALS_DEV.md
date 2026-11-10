> **REF-366 CLEAN 说明**：下文是 REF-366A 开发候选的历史记录。正式提交准备状态、真实回归边界及未完成项以 `CLEAN_REF366_UNION_CAVE_RUINS_FINAL_ACCEPTANCE.md` 为准。游戏显示版本现为 `REF-366@`，原候选的洞穴运行行为未变。

# REF-366A 开发候选｜联合洞穴 B1F ⇄ 阿露福遗迹外部的双侧口

状态：**开发候选（源码已接入；ROM / MAP / 手机测试尚未验收）**。基线为用户上传并已确认 CLEAN 的 `REF-365.zip`，分支 `常规功能备份`，Git HEAD `62a851e72ca00db23d4e7ac95aec83ee4d046804`，工作区无未提交修改。目标游戏标签 `REF-366A@`。

## 地图范围与 Gold 来源

- 使用已有 UnionCaveB1F (stable ID114) 和 RuinsOfAlphOutside (stable ID20)，活动地图数保持 **65**。
- Gold 原版 `maps/UnionCaveB1F.asm/.blk` 和 `maps/RuinsOfAlphOutside.asm/.blk`；分别使用 cave/johto tileset 的 `.asm` collision 表。新开两对双向 Warp，共新增四条定向记录，项目总数 **168→172**。
- 严格保留 Gold 编号：B1F warp #1 (3,3) ⇄ Ruins warp #7 (6,19)，B1F warp #2 (3,11) ⇄ Ruins warp #8 (6,27)。RPP 0-based：B1F source ordinals 0/1，Ruins Outside source ordinals 3/4；不改原有 Ruins source ordinals 0/1/2，也不改 B1F 2/3/4 楼梯。
- **室外入口**：Ruins (6,20)/(6,28) 面朝 UP 踩到 `(6,19)`/`(6,27)` CAVE 格，应立即进入 B1F (3,3)/(3,11) 并停留，不能从相邻石块误进。
- **洞内出口**：站在 B1F (3,3)/(3,11) 的 `WARP_CARPET_DOWN`，仅按 DOWN 时出去；到 Ruins 的对应 CAVE 格后自动 DOWN 一格到 (6,20)/(6,28)，否则会有旧问题“卡在门上”。不能给 B1F 到达地毯强行自动迈步。
- 遗迹室外两片陆地区域受原版地形阻隔，不要因为单纯的户外逐格 BFS 暂时走不到两个侧洞，就把两个入口合并；两者正是通过独立的联合洞穴 Warp 衔接，Gold 的外围 `.blk` 与项目 `.gold.blk` 哈希一致。

## 本次修改边界

只添加四条登记、两个遗迹外部 Object Warp、外口 UP 入洞允许判定、两个 B1F DOWN 出洞判定及落点自动迈步；其余已验收洞口／楼梯、洞穴地形、现有 Field Moves 不做功能修改。无新 NPC、剧情、训练师、遭遇、物品球、Rock Smash 技能或可碎石；Strength 和水域原有实现不做重写。

## 离线与用户验收

离线审计覆盖：实际 Source Object target ordinal、4 个 Route 的目标地图、UP/DOWN 触发、错误方向拒绝、落点合法性、无连续回弹、旧楼梯与黑暗洞穴守卫、工具级负向注入。运行源检查不是 LR35902 模拟器，无法替代 RGBDS 链接或实机。

用户在 RPP Mobile / Termux 执行：

1. 先 `git apply --check`，只应用 ZIP 中一份与当前基线匹配的补丁，不要叠加；校验现有 REF-365 clean HEAD 与工作区状态。
2. 使用项目 RGBDS 0.5.2 编译 Red、Blue、TEST Red、TEST Blue，查看四份新 MAP，要求 ROM0 剩余 **≥64B**，检查银行分配；不能拿 REF-365 MAP 当新版本验证。
3. **北侧入口**可从遗迹已有外部通路走到 `(6,20)`，朝上踏入 `(6,19)`；**南侧入口**位于遗迹外围另一片独立区域，可能不能直接从北侧/南门房陆路抵达，应先由联合洞穴 B1F `(3,11)` 朝下出洞，自动到 `(6,28)`，再朝上进入 `(6,27)` 验证返程。两端分别到 B1F `(3,3)` / `(3,11)`；从 B1F 两个出口都需测落地自动下迈、回头不弹回、错误方向拒绝和连续往返。
4. 从 B1F 的三个旧楼梯去 1F/B2F 后返回，复测冲浪、跳崖、骑车可用性；进出遗迹原南门房和北门房，不能因新增两口破坏原有门。Save→Continue 不应卡死或错送。

**未完成**：正式 CLEAN、Git Commit/Push、新 ROM 构建及移动设备确认。强制审计历史的 64／164／封口冻结断言只在适用的历史版本有效，不允许拿旧合同失败当作本批新运行错误，也不允许伪造全仓库测试全绿。
