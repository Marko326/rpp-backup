# REF-350 ROM0 最终低风险收口（游戏版本仍 REF-348）

## 最新验收结论
- 用户新传的 Red/Blue MAP 均显示 ROM0 **421B**；当前 `REF-348(1).zip` 附带的 Red MAP 同为421B，Bank `$2A` 余15,020B。已经是链接后的实测 MAP，不是估算。
- 用户反馈 REF-349 六项运行功能和 REF-350 旧档进出门房、新游戏出场、菜单战斗返回三项均实机通过。TEST 同版 MAP/实机记录尚未补齐；不自动扩大到所有地图/全部输入时机。
- 依然是 `REF-348`，清理仅更新文档，禁止改动已验收的运行指令。最新清理见 `CLEAN_REF348_ROM0_FINAL_ACCEPTANCE.md`。

## 历史迁移基线（以下旧报告数值仅供对照）
- 输入：`REF-348_ROM0-RELIEF-349_源码迁移版.zip`。先前5组迁移已由用户手机验证6项通过。
- 用户最新 Red MAP 空间报告：393B（非此轮的新 MAP）；Blue 按用户确认空间相同。
- Bank `$01` 的旧 MAP 只有4B slack；不能把 bank1 两个3B near calls 替换成6B far calls。

## 改动
- 将 `ResetPlayerSpriteData` 的实际工作、16B×2精灵状态清零、初始坐标赋值迁入 ROMX `$2A`，原指令顺序、数据地址和数值保持一致。
- HOME 保留 9B `ResetPlayerSpriteData` 入口：`callab ResetPlayerSpriteData_ROMX; ld a,$1; ret`。原例程在 ROM0 占37B；保守预计ROM0净释放28B，约393→421B（需新 MAP 确认）。
- Bank `$01` 的 `engine/oak_speech.asm` 和 `engine/menu/main_menu.asm` 两个 `call ResetPlayerSpriteData` 一字不动，防止空间溢出。
- 补充静态检查，不修改任何存档、地图、Sprite布局。

## 明确不改
- `GetItemPrice`：原地执行时动态改 ROM bank 并读取 ItemPrices/动态 MOVESLISTMENU 表，直接放 ROMX 会失去正在执行的指令页。
- `GetTrainerInformation`：函数内部 BankswitchHome / BankswitchBack，直接移出HOME违反其使用合同。
- `LoadStartupMusicOption`：在读取旧档时进入 SRAM banking mode，需要 ROM0 执行位置，不做低风险迁移。

## 原开发阶段的验收要求（现已完成部分验证，详见上方）
- 源级回归：`python -m pytest tools/tests/test_rom0_relief_350.py -q`（以及此前 REF-349 相关测试）。
- 由用户本地构建后用新 MAP 查看 Red ROM0 是否约421B、ROMX `$2A` 是否尚有空间。其他版本构建按原项目流程办理。
- 旧存档启动→地图重入、开始新游戏→角色坐标及图形、战斗与菜单来回、门房和跳崖后形象均无异常。建议至少5轮重进与连续存读档。
- 本轮仅作为**定版候选**，未进行 RGBDS 真实编译/手机验收/正式 Git 提交。
