# Deluxe 55 组技能动画录制分支：二楼电脑展示

## 分支定位和普通编译

本分支用于游戏画面录制，不是正式技能移植：保留原技能的属性、PP、伤害和 AI。
**没有单独的 video-red 编译模式**：`make` 同时构建 Red/Blue，`make red` / `make blue` 分别构建 `patches/rppred.gbc` / `patches/rppblue.gbc`。两者均带二楼电脑展示功能。
既有 `test-red` / `test-blue` 是项目自己的独立战斗测试设施，不是此次展示功能的构建依赖。

## 二楼 PC 播放流程（此前录屏版已获用户场景实测）

主角家二楼 PC 选择 `A-Z 55 MOVES` 或 `TEST 5 MOVES`：

- A–Z：将 55 套 Deluxe 不同的技能动画按英文名称升序各播一遍。
- TEST：Gear Grind / Power Whip / Play Rough / Sand Tomb / Drill Run 五项。
- 每组播放本方（ALLY）一次、对方（FOE）一次；读取双方真实昵称和对应技能名称，使用原生文本速度及受击反馈。
- **不计算战斗回合，不扣 HP，不消耗 PP**；每段动画结束后的安全点可以用 B 提前退出。
- 播放完成或提前退出，走正常野战的结束及主地图重载路径（`NewBattle` → `EndOfBattle` → `EnterMap`），不用旧的 PC 回调手工刷新地图。

普通野战和训练师战斗不会被无条件替换：只有二楼电脑设置的 `$a7` 标志会触发展示。

## 两个独立提交的界限

1. **动画资料**：`engine/battle/deluxe_video_anim_data.asm` 内含 55 套原始指令、名称和指针；没有启动入口。
2. **自动播放改造**：`engine/battle/deluxe_video_preview.asm` 的菜单、播放次序、文本、状态切换，加上 `main.asm`、`home.asm`、`home/overworld.asm`、战斗与 PC Hook，以及本说明。

`deluxe_video_anim_data.asm` 从原已实测录屏候选中逐字节拆出，不修改 55 套指令。`INCLUDE` 必须与运行器位于同一 `ROMX` SECTION，不能用跨 Bank 的 16 位指针。

## 验收状态和边界

用户已验证**此前独立 video-red 模式**的地图/战斗退出场景正常；**普通 make/red/blue 接入尚未得到用户实机验证**。本轮执行代码/补丁静态检查，不由助手编译或链接 ROM。重新构建时检查两版 Bank 余量及二楼电脑入口；使用单独测试存档录屏，避免覆盖主分支正式游戏进度。
