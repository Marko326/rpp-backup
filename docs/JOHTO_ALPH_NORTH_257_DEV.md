# ALPH-NORTH-001 / MAP-5.62.257 开发候选

用户上传的 `FIX-5.62.256.zip` 为基线。不假定最新 Git HEAD 已改变。

- 本轮仅开放遗迹北侧 DOOR → `Route36RuinsOfAlphGate` (稳定ID19) → `Route36` (稳定ID16)，双向。遗迹南门房及32号路逻辑保持不变。
- Gold 的 NorthSouthGate.blk (20B) 与 Route36.blk (270B) 逐字节保留；新 runtime 图块使用 pixel-exact 映射而非 Gold 图块索引直接拷贝。
- 门房上方 (4/5,0) 是 UP step-on DOOR；下方 (4/5,7) 是 DOWN collision carpet。36号路 (47/48,13) 仅 DOWN collision；遗迹北门 (7,5) 仅 UP step-on。
- 只在抵达北门房上方 DOOR 或遗迹北门 DOOR 时自动向下走一步；抵达 Carpet 不自动行走，避免二次触发。
- Route36 的 National Park #1/#2、35/37号路、桔梗市西边缘封闭；暂不移植胡说树剧情、训练家或 NPC 替身。
- 不修改存档、关都、Surf/Cut/既有跳崖，TEST-231 保留。只交互斥增量和全量开发补丁，不自行 Git Commit 或 ROM 编译。

建议实机检查：两车道 Route36 ↔ 北门房 ↔ 遗迹双向回程；上门踏入后自动向下走一次；下门只准 DOWN；侧撞无 Warp；到达 Carpet 不自动走；南门房、Select、旧存档 Continue 回归。
