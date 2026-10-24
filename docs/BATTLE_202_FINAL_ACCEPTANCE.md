# BATTLE-5.62.202 — 正式验收与清理记录

## 最终保留的正式功能

- Dynamic Spark：MoveDex 固定显示 Dynamic；实际 Attack >= Special（含相等）走 Physical，Attack < Special 走 Special；烧伤不参与分类比较，物理伤害仍受烧伤影响。
- 能力等级 -6～+6 与数值限幅 1～999 分开处理；烧伤下的 Dynamic 重算遵守最低值 1。
- 混乱自伤固定使用自方 Attack 对自方 Defense、40 威力、无属性、不可会心，不读取本回合所选招式的物理／特殊分类。
- 公共伤害公式对能力缩放后的防御除数设最低值 1，避免极低 Defense／Special 除零。
- Counter 继续读取当回合真实本体 HP 受击记录，按最后一笔有效物理 HP 损失乘二，保留命中判定、优先级与现有资格规则；新增幽灵目标免疫检查，Ghost 目标不扣 HP。
- 烧伤／麻痹的公共能力重算修复和 Counter 条件失败提示保持不变。

## 用户实测证据

- TEST 21：用户说明实际已成功降攻 6 次；最后一次 Growl 的“不能再降低”提示用于证明到达 -6。Spark 显示 Physical，按通过记录。
- TEST 30：用户视频显示选择 Spark 与 Tackle 时混乱自伤均扣 16 HP，符合不受所选招式分类影响的规则。
- 205T：物理／特殊极低除数两个入口、固定伤害 Counter 与 Mirror Move Counter 场景未报告新的明显异常。
- TEST 04（206T）：视频显示玩家为 Gastly（HP 999/999），敌方 Snorlax 使用 Counter，随后提示 `It doesn't affect Gastly!`；Gastly HP 仍为 999/999。幽灵免疫通过用户视频验收。

## 正式清理内容

- 恢复 `scripts/CeladonMansion1.asm` 与 `text/maps/CeladonMansion1.asm` 的正式 NPC／导师对话。
- 恢复 `data/wildPokemon/route7.asm` 的原始 Normal／Hard 野生遭遇表。
- 移除 `InitWildBattle` 内的临时测试远调用、`Battle203TChooseCase`／`Battle203TConfigureWildEnemy`、WRAM 测试别名和五个游戏内 TEST 标签。
- 删除临时测试指南 `BATTLE_203T_QUICK_CHECK.md`、`BATTLE_204T_ONE_CLICK_BATCH.md`；本记录保留实际验收结果，不保留可运行测试设施。
- 正式游戏版本为 `BATTLE-5.62.202`。

## 未声称完成的验证

- 没有要求玩家复测已通过的替身、多段、换人、真实未命中场景，也没有要求读取敌方精确 HP；因此这些只按既有定性测试记录，不声称完成精确数值验收。
- 本环境没有构建 ROM、链接 Normal／Hard 或生成新 MAP。用户本地构建与 MAP 检查仍是正式提交前最后的工程验证。
- 没有执行 Git Commit／Push。基线为 `BATTLE-5.62.201` / `eba1a803a7791a74bd2706982345d2894e3f93e2`，拟提交目标为 `BATTLE-5.62.202`。
