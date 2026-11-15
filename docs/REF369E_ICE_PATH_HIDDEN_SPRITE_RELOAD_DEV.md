# REF-369E@ — 冰之通路 B2F 保存后画面异常：隐藏落石精灵 ID 安全修复（开发候选）

## 用户实测与本轮归因边界

- 已有录像：REF-369C 保存后仍在 Ice Path B2F Mahogany Side 大范围图块错乱；用户报告 REF-369D 也未解决。
- 山洞外保存不闪、冰洞其他层保存可能短暂闪但不留下错误图块；B2F 保存后花屏，而上下楼梯切图及重启 Continue 能恢复。
- **不能凭静态源码把 B2F 花屏认定为彻底修复。** 本轮定位并排除了可重现的 *无效精灵图片编号* 源码风险，待用户本机重新保存验证画面。

## 确认的源码缺陷

`data/johto_ice_path_stage/ice_path_b2f_mahogany_runtime_368a.asm` 的 `JohtoIcePathB2FMahoganySyncLanded369B` 隐藏四个尚未落下的岩石时，原实现把 `wSpriteStateData1 + $10/$20/$30/$40` 的图片编号清零，并清掉 `wSpriteStateData2 + $1e/$2e/$3e/$4e` 的 VRAM slot。B1F 的 `JohtoIcePathB1FHideDropped369B` 对已落石头也有同样操作。

而 `home.asm` 的 `CloseTextDisplayAfterWindowHide` 会调用 `InitMapSprites`。`engine/overworld/map_sprites.asm` 先从 `wSpriteStateData1` 复制每个对象 picture ID，在 `LoadMapSpriteTilePatterns` 对参与重载的对象把 picture ID **减 1** 并乘 4，用于索引 `SpriteSheetPointerTable`。图片编号为 0 会在 8 位算术中下溢到 `$ff`，越过有效图形索引区间。因此隐藏对象不能通过改图片 ID 为 0 来表示“不可见”。

这一静态缺陷与 B2F 独有的四个落石对象以及 Save/Text 返回时重载精灵的路径一致，但无法单独证明它是整块 BG 错乱的唯一原因。

## 实际代码修正

1. B2F 未收到落石的对象：**保留原始的 `SPRITE_BOULDER` 非零 picture ID 和由通用装载器维护的 VRAM slot**；只把其坐标 `wSpriteStateData2 + $14/$15`、`$24/$25`、`$34/$35`、`$44/$45` 设置为 `$ff`，不参与当前地图正常显示/接触。事件位判定不变。
2. B1F 已落入坑的四块石头：同样保留有效 picture ID/VRAM slot，只移出当前坐标；既有事件状态、岩石位和洞位逻辑不变。
3. 移除 REF-369D 放入 `StartMenu_SaveReset` 的 `ReloadTilesetTilePatterns` 附加调用，并保持 `StartMenuPrepareClose` 没有 REF-369C 的死路径重载。恢复原有 `predef SaveSAV → LoadScreenTilesFromBuffer2 → jp HoldTextDisplayOpen`，不改全局保存系统，不动存档结构。
4. `data/game_version.asm` 标记为 `REF-369E@`；修改相应防回归审计和测试，检查所有 8 个隐藏石头都没有清零 picture ID/VRAM slot、坐标确实移出、Save 保持原路径、文本返回仍调用 `InitMapSprites`，并注入反向故障确认检查器能够发现回归。

## 项目要求与验证边界

- 这是开发候选，不是正式收口：一个 ZIP，内含 **01：REF-369D → REF-369E 增量补丁** 与 **02：正式 REF-368 HEAD `935b3fa738dce42f22768e94c92c920bb5b86d89` → REF-369E 全量补丁**，二选一、不叠加。
- 未改 BANK0，不增加 Bank 0 指令；没有运行 ROM 编译/链接、没有提供新的 MAP/ROM0 空间数字，也没有执行 Commit/Push。
- 本地自动化测试、统一门禁和补丁应用／逆向还原结果以实际执行记录为准。历史审计失败不能声明已解决。

## 手机最小复测

备份 ROM/SAV 后，只应用对应的 01 或 02 补丁，在设置确认 `REF-369E`。使用相同 SAV、相同位置、相同四块石头落洞状态：冰之通路 **B2F Mahogany Side → START → Save → Yes → 返回地图**，观察画面有没有立刻花屏，移动两步。若正常再上下楼梯、重启 Continue，确认石头显示/碰撞无变化。如果依旧花屏，应停止猜测性修改并抓取保存前后 `wSpriteStateData1/2`、`wCurMapTileset`、BG tilemap/属性及 VRAM 数据的运行态差异。
