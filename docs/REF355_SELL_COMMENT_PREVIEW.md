# REF-355｜SELL 旧提示完整注释及测试精简记录（已归档）

此处记录 REF-355 开发阶段的源码精简。**不改玩家已验收的运行行为**：上一版删除的 SELL 旧显示链在原位置恢复成注释，重复或无效的测试被删减。正式清理仅更新文档状态，具体设计以同目录的 SELL/Flash/PC 功能文档为准。

## 注释范围
1. `engine/overworld/pokemart.asm` `.sellMenu`：原 `ld hl,PokemonSellingGreetingText`、`call PrintText` 两条全部注释。
2. 同一文件原文字包装：`PokemonSellingGreetingText:`、`TX_FAR _PokemonSellingGreetingText`、`db "@"` 三条全部注释。
3. `text.asm`：原 `_PokemonSellingGreetingText::`、`text "What would you"`、`line "like to sell?"`、`done` 四条全部注释。

这三个位置的完整代码仍能阅读，但全部以 `;` 开头；不存在可供链接的同名有效符号，不再占用 ROM 数据。

## 精简内容
- 删除 Flash 套件里重复的 SELL 死文本检查，改由 SELL 专项唯一验证**完整注释链且不存在活跃引用**。
- 删除 SELL 测试里重复的 PC 库存解码和 Flash 门控测试，分别继续由 PC/Flash 套件负责。
- 删除 PC 套件仅验证 Python 示例映射、未读取 ASM 的测试。
- 将 FEATURES、TODO、PROJECT_DELIVERY_RULES 的重复 REF-355 候选摘要整理为各一段；原 REF-354 历史及三份功能文档保留。

## 保留的验证
Flash 地图条件/徽章/A-only 确认、SELL 列表门控/交易返回、PC 列表地址/Cancel/道具说明、文本三个位置的注释与活跃代码检查。未执行 ROM 编译或设备验收。
