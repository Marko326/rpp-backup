# REF-355｜Flash 暗洞规则与按 A 确认（正式归档）

## 本轮实机反馈修正（REF-355）
- Flash 非暗洞拒绝文本使用 `text "It's not dark here.@@"`，该结束符**不等待按键**；以前 `PrintText` 一返回，START Party 便重绘菜单，导致提示自动闪过。
- 现在 `JohtoFlashEligibility349.notDark` 在 `PrintText` 之后调用 `WaitForFlashAOnly349`：先等待松开选技能时的 A，再等待**新按下的 A**，期间保持提示文字与向下箭头；仅 A 可确认，B 不会跳过。确认后才返回原队伍菜单。徽章不足的原 `prompt` 路径保持原样。
- 历史补漏：用户原 `REF-355.patch` 漏掉 SELL 包装标签和 `text.asm` 正文删除。上一轮修正版已补删；当前预览改为**旧调用/包装器/正文全部注释保留**，确保以后可回看而不产生 ROM 数据。详细代码见 `docs/REF355_MART_SELL_DESCRIPTIONS_DEV.md`。
- 用户之后确认 REF-355 候选表现正常；静态专项测试与补丁回放均有独立记录。尚未从本轮提供的源码在此环境执行四种 ROM 编译，实际设备反馈不代表所有徽章/地图/构建组合均已覆盖。


## 用户要求
- Kanto 与 Johto 的 Flash 操作规则对齐：普通室外、普通室内、非黑暗山洞，或已经开过 Flash 的暗洞，统一输出 `It's not dark here.`，不应该播放技能成功动画或重写调色板。
- 黑暗洞穴内且尚未照亮时保持现有成功效果、当前地区的徽章资格和两种暗场配色。未使用的 SELL 提示完整调用链逐行注释保存。

## 代码改动
- `engine/johto_dark_cave_stage2.asm` 的 `JohtoFlashEligibility349`：Johto 仍限定 runtime Region Johto + Violet Dark Cave，要求 `wMapPalOffset == 12`；Kanto 仅允许 `ROCK_TUNNEL_1` 或 `ROCK_TUNNEL_2` 并要求 `wMapPalOffset == 6`。其他情况直接使用现有 `.notDarkText`，返回 E=1；在有效暗洞内才检查徽章，Kanto 使用 Boulder、Johto 使用 Zephyr 或 Boulder 旧存档兼容。
- `engine/menu/start_sub_menus.asm` 成功分支**不改**：`JohtoFlashEligibility349` 返回 E=0 才会清 `wMapPalOffset`、打印 `_FlashLightsAreaText` 并执行原有 `GBPalWhiteOutWithDelay3`；失败仍返回队伍菜单。
- SELL 的历史显示调用、`PokemonSellingGreetingText` 包装和 `_PokemonSellingGreetingText` 正文均是源码注释；全项目 ASM 没有这两处标签的有效引用或定义。

## 必须实测
1. **Kanto 普通 Route10 室外/室内**：有 Boulder Badge，尝试 Flash → `It's not dark here.`，无白闪、无地图亮度变化；未取得 Boulder 的普通地点同样提示非暗场（先检查地图有效性，之后才是徽章）。
2. **Kanto Rock Tunnel 1F 和 B1F**：未照亮时，未持 Boulder → 原徽章提示；持 Boulder → 成功照亮，原洞穴调色板恢复。再试 Flash → `It's not dark here.`；出洞及重进后重新处于暗洞时可使用（按原游戏重入规则）。
3. **Johto Route31/46 室外**：任意徽章 → `It's not dark here.`。Violet Dark Cave 未照亮时 Zephyr 或旧存档 Boulder → 成功，随后再次使用 → `It's not dark here.`；无徽章 → 原徽章提示。
4. **回归**：Rock Tunnel 与 Johto Dark Cave 进出无白闪/残影；REF-355 玩家 PC Withdraw/Deposit/Toss 与商店 SELL 道具说明照旧；SELL 打开不显示 `What would you like to sell?`。

## 证据边界
- 静态检查、补丁正反向回放不等于硬件时序验证；用户已反馈常规操作正常，但本环境仍未对 Red/Blue/TEST Red/TEST Blue 四种 ROM 编译或生成本轮 MAP。其他未覆盖的地图、徽章、转场组合继续列在 TODO。
