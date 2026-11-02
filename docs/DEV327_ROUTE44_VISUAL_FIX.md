# DEV-327｜卡吉镇/44号道路跨地图屋顶变色、南侧树墙修复（测试候选）

本轮以已应用 DEV-326 的工作区为增量基线，保持 44 张活动图；游戏版由 REF-5.62.322 升为 REF-5.62.323。没有新增地图、剧情、洞穴内景、Warp 或野外 NPC。

## 设备发现及代码根因

- 视频 `GBPocket_20261102_205018.mp4`：从卡吉镇向东进入 Route44 时，左侧仍可见的卡吉镇房顶改变颜色。原因是 `ApplyJohtoGoldRoofPalette269` 按 **当前地图**选整屏屋顶 palette6；Mahogany 已指定 Gold 屋顶 RGB，而 Route44 没有继承该颜色。新增 Route44 → `.route42` 的分支，重用卡吉镇现有 Gold RGB，不改变其它地图。
- Route44 南部下方出现重复树林。Gold `data/maps/attributes.asm` 给 Route44 与 BlackthornCity 的原版 border block 都是 `$71`；当前游戏 Object Header 却用 `$05`，画出树木。将两个已开放地图的边框标记统一改成 Gold `$71`，不修改 Gold `.blk`、角色网格或实际通行。较早的其它地图边框不在本轮修改范围。
- 新增 `tools/johto_east_visual_border_palette_327.py`：无 Gold 参考也检查两张活动图 Object Header 的 `$71`、Route44/Mahogany 同组 roof palette 的真实分支及 palette6 写入路径。有 Gold 时进一步解析 Gold `attributes.asm` 来源；加入主综合审计强制执行，并写入故障注入 pytest。
- 更新现有 Route44/Blackthorn 阶段审计中误认为 `$05` 正确的历史断言。

## 验收边界

静态检查不能代替 GBC 实机逐帧观察；当前环境没有 rgbasm / rgblink，本轮未编译或生成新 MAP。用户需重新编译并检查 ROM0 >=64 B、ROMX 余量，然后沿 Mahogany → Route44 → Mahogany 与 Route44 下侧、Blackthorn 边缘截图复测。测试阶段只交工作区增量 + HEAD 累计全量两份互斥正向补丁，不 Git Commit/Push。
