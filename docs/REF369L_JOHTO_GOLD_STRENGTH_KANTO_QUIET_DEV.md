# REF-369L@ — 城都 Gold 怪力烟尘与关东去闪白（开发候选）

## 用户目标
- 城都（RPP Johto）的所有怪力石头采用 Gold 原版局部烟尘反馈，推石进入洞口、石头消失后烟尘仍有独立帧生命周期。
- 关东保持现有谜题、音效及推动流程，仅去掉 `rOBP1` 整块闪白。
- 根据项目 TODO 条目，区分“代码已实现”和“ROM/MAP/手机最终验收”。

## 依据与范围
Gold 源码：`engine/overworld/map_objects.asm` 的 `MovementFunction_Strength`、`MovementFunction_BoulderDust`、`SpawnStrengthBoulderDust`，`engine/overworld/map_object_action.asm` 的 `SetFacingBoulderDust` 及 `gfx/overworld/boulder_dust.png`。项目参考见上传的 REF-312 交接 ZIP。

RPP 原实现 `DoBoulderDustAnimation -> AnimateBoulderDust` 阻塞地切换 `rOBP1`，不允许洞口消失后继续显示。REF-369K 仅屏蔽 B1F 调色板闪烁，仍为阻塞调用。REF-369L 对所有 `JOHTO_RUNTIME_MAP_HANDLE` 使用非阻塞 Gold 风格 OAM，采用 Gold 原始两帧素材，不影响其他精灵调色板；非 Johto 使用原有静态烟尘并关闭调色板闪烁，且删除 `ssanne.asm` 不再可达的旧调色板循环。音效 Johto 换成原版 Strength SFX，Kanto 仍用原推石音效。

## 数据、保守边界
- `wram.asm` 仅重划 CD56-CD58 原九字节暂存，**既有符号及存档布局地址不变**；进入地图自动清理。仅记录方向、源精灵槽与剩余帧数。
- OBJ `$FC/$FD` 使用原 Gold 两帧 8x8 图案，不覆写 normal boulder Sprite ID。单 OAM 槽附加在正常精灵之后，保留最后 4 个 OAM 项给跳崖/钓鱼。拥挤时跳过特效，不遮挡已有精灵。
- 烟尘名义时长为 32 帧。启动后仅等待原本推动石头走完 16 像素（16 帧），再允许地图脚本做落洞判定；烟尘仍通过每帧 OAM 钩子继续显示，不等待烟尘完结。此处专门防止异步替换旧阻塞动画后出现过早 PIT 判定。
- 32 帧烟尘用于模拟 Gold 依附目标动作持续两倍步长；精确帧率/多次连续推石的多对象叠加与 Gold 的多临时对象调度**不是逐指令移植**，仍待用户视频对齐。本轮不改地震幅度与 PIT 跳洞。
- 不能把静态 PASS 写作完成设备验收。无新 RGBDS ROM/Bank MAP 证据，按项目规范 AI 不编 ROM、不提交 Git。

## 最小实机验收
1. 城都 B1F 连续单步推动、石头进入 PIT、落洞后烟尘是否残留短时间；与 Gold 视频逐帧对齐。
2. 城都其他有 Strength 的地图推石，确认没有整块闪白。
3. 关东双子岛及普通推石：不整块闪白，原谜题/落洞/音效/保存功能不变。
4. B2F 保存不花屏，已落石头仍隐藏合法图片 ID；检查 Red/Blue/Test ROM/MAP 以及 ROM0≥64B。

## 审计
运行 `python tools/johto_strength_gold_dust_369l_audit.py --root .`，相关 pytest 和 `python tools/validate_current_project.py --skip-pytest`。负向用例覆盖地图条件、Kanto 调色板、Gold 源图、OAM 保留区及临时状态，历史冻结检查仍单独列出。
