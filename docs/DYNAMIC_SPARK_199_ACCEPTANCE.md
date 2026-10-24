# MOVE-5.62.199 — Dynamic Spark 正式收口说明

## 范围

本版新增第四招式分类元数据 `DYNAMIC = $03`，只将普通 Spark 设为 Dynamic。Spark 仍为电属性、威力 65、命中 100%、PP 20，麻痹追加效果和动画不变；不修改存档格式。

## 约定行为

- MoveDex 固定显示与原版同框尺寸／字模的 `DYNAMIC`，切换其他技能时恢复原分类图块。
- 战斗选招菜单显示**当时预测**的完整 `Physical`／`Special`；不把光标预览记录为最终伤害类别。
- 实际轮到 Spark 造成伤害时，再依据该使用者当前经过能力等级修正的 Attack 与 Red++ 单一 Special 比较；Attack 大于或等于 Special 时为物理，仅低于 Special 时为特殊，**相等恢复 Spark 原本的物理分类（200T-004 规则修正）**。
- 选择后、发动前若受到叫声等影响，菜单先前显示可以与本次实际类别不同；发动后变化只影响下次分类判定。
- 烧伤不参与类别判定：仅在烧伤时根据未经烧伤折半的原始攻击及当前等级重算攻击，按项目通常上限 999 截断；烧伤对物理伤害的处理仍交给原战斗系统。
- 按实际类别沿用已有 Attack/Defense 或 Special/Special 伤害路径；不新增新的伤害算法。

## 用户反馈与未验收项

用户确认 199C 原字模的 Dynamic 框满意，选招第二槽 Spark 不再跳选，来回移动未见花屏；常规 Attack 高于 Special 显示物理、降低后落至低于 Special 显示特殊。上述为已测主路径，并非全部状态或两个 ROM 版本验收。

尚未专项实测：同回合选招后降攻再出招；攻击等于 Special 的伤害分类；烧伤且提升重算超过 999；敌方使用、会心／派生技能（Mirror Move、Metronome）、Red/Hard/Blue 新 ROM 链接与 MAP。

## 明确排除 Counter

本版**不**包含 199D／199E 的 Counter 缓存、ROM0 桥接和保留 WRAM 使用。Counter 仍沿用原项目机制；`Spark` 与 `Counter` 的精确受击类别关联尚未在本版修复或验收，后续另行开发，不应把这一项解释成 Dynamic 分类主路径失败或正式版已支持完整 Counter 规则。

本项目按交付规则不由助手自行编译、链接 ROM 或执行 Git Commit／Push。
