# REF-369N@ · Gold 怪力四象限烟尘复刻（开发候选）

## 原因（以附带 Gold 源为准）

`data/sprites/facings.asm` 的 `FacingBoulderDust1` 与 `FacingBoulderDust2` 各定义 **4 个 OAM 项**，都是同一张 8×8 图案，分别放在 (Y,X)=(0,0),(0,8),(8,0),(8,8)，组成 16×16 的四团白烟。先前 REF-369L/M 仅追加 1 个 OAM 项，是手机中普通推动烟尘过小以及落洞后白色反馈不足的直接实现差异。Gold `MovementFunction_BoulderDust` 在推动时创建对象，不是落洞时额外生成一套烟尘。

## 此次修改

- `engine/overworld/johto_gold_strength_dust_369l.asm` 的绘制器改为 Gold 的四个 8×8 OAM 象限，使用同一帧 `$FC/$FD` 和 PAL_OW_EMOJI=5；方向偏移仍按 Gold 原脚本 `(0,-4),(0,8),(6,2),(-6,2)`，影子/钓鱼保留末尾 4 OAM 项。
- 只有 OAM 偏移 ≤ `$80`、且未启用跳崖/钓鱼特殊保留时才绘制完整 4 个象限。过拥挤时不绘制任何一个，避免截断或覆盖原精灵。
- 对齐 Gold `SetFacingBoulderDust` 的相位：第 1–2 个 OAM 更新使用第一帧，第 3–4 个使用第二帧。原有 32 帧寿命与 16 帧石头移动等待维持，不能把这一近似等同于精确原版每帧生命周期。
- 不变动 `push_boulder.asm` 的 Johto/Kanto 分流、关东音效/动画、落洞碰撞及存档事件、隐藏精灵合法图像 ID、REF-369M 的 2 像素震动。
- 版本标记 REF-369N@，TODO 标记源码修复完成而非手机验收。

## 验证约束

新静态审计及负向用例验证 Gold 四角坐标/同图案重复、OAM 边界、跳崖/钓鱼保留、动画相位、关东分流和震动参数。**不自行编译 ROM/MAP，不 Git Commit/Push**，手机仍需检查普通推动、石头进洞后的烟尘、连续推石、B2F 保存花屏回归；Gold 原始多对象同时运动和逐帧精确匹配尚未验收。
