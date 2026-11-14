# REF-368F@｜冰之通路原生连续滑行接线（开发测试）

## 实际基线与交付

- 本批以 `REF-368B.zip` 中的真实源码为起点，先依次应用已提供的 368C、368D、368E **01 增量**，形成 REF-368E 逻辑基线（游戏显示仍 `REF-368D@`）。
- 本批修改真实玩家输入/步进 ASM，显示版本提高到 `REF-368F@`。共 70 张活动地图、188 条方向 Warp，保持既有楼梯/跳崖/自行车/Dig 与逃洞绳代码。
- 开发交付：**一个 ZIP 内只有两份互斥正向 `.patch`**：01 从上述 REF-368E 源码状态递增到本版；02 从项目已记录正式 `REF-367` Git HEAD `cd88452a05e9399b469f12fe2c6c89dd532dfcfb` 的重建源码全量到本版。01、02 不可叠加；维护者先在手机仓库核对 `git rev-parse HEAD`、`git status` 和 `git apply --check`。未操作用户仓库 Git，也不提供正式 CLEAN 日志。

## 本轮可验证的运行改动

1. `home/overworld.asm` 在 `AdvancePlayerSprite` **步数归零后**调用 `JohtoIcePathArmAfterStep368F`，只有真实完成一次移动、到达 Gold ICE、方向有效且非模拟按键/跳崖/Surf 才存入原方向；不是单靠角色站在 ICE 就自行移动。
2. 下一次 `JoypadOverworld` 完成脚本/硬件输入刷新以后，由 `JohtoIcePathInjectSlideInput368F` 在尚未开始下一步时，检查滑行头及 Gold 角色：在 ICE 上按保存的方向强制普通方向输入，忽略中途拐弯与 START/A/SELECT。移动仍走**原有** `CollisionCheckOnLand`、`UpdateSprites`、`AdvancePlayerSprite`、Warp、毒伤/步数/遭遇，而非直接跳改坐标。
3. 当普通陆地碰撞（墙、NPC/石头等）失败，先清空滑行方向，再由原有碰撞声音和检测返回；下一帧允许重新输入方向。到非冰面完成一步会自动解除。
4. `ClearVariablesOnEnterMap` 已在所有普通地图载入执行，清空滑行状态；模拟脚本、正在跳崖、Surf、对战进入以及非 Ice Path 地图也清空/禁止继承，防止楼梯、落点、继续读档强制滑走。
5. 状态使用已有 `$D67C` **原先未使用且进入地图时会清零的 1 字节**，通过 `wIcePathSlideHeading` 别名访问，不改变 WRAM 地址/存档结构；不使用被道具写入的 `$D7A3`。
6. 五张地图在其**已有的 Gold role 所在 Bank** 提供 `IsIce` 包装入口。因为 `callab` 会将 B 改为目标 Bank，包装入口须**在切换后**从 `wYCoord/wXCoord` 重新装载 BC、通过 `cp 2` 的 Z 标志返回是否 ICE。恢复 Bank 会覆盖 A，因此绝不可直接依赖 A；B3F 原图无 ICE，依然以非冰面安全返回。
7. `main.asm` 只新增一个**浮动 ROMX** 滑行驱动区，不向紧张的指定 `Bank $0F` 堆代码。ROM0 仍新增少量必要入口；最新 MAP 空间尚未核验，不能声称 ROM0 ≥64B。

## 项目边界与未解决项

- **本次只有连续滑行**：B1F 四块怪力石头、四个落洞、B2F 落点转换仍是下轮待做，不能声称全洞可按 Gold 完整通关；碎岩/道具/NPC/剧情仍延期。
- 静态可测项目：五层 3060 个角色格，其中 673 个 ICE（1F 234、B1F 44、B2F 卡吉侧 304、烟墨侧 91、B3F 0）。REF368F live hook/Bank/状态/碰撞/方向审计通过；14 个专门错误注入/回归测试通过；全套 Ice Path `157 passed`。统一静态总迁移审计仍有历史冻结合同的 35 失败，不是本批全项目绿灯。
- **未编译、未链接** Red/Blue/TEST Red/TEST Blue ROM，未生成最新 `.map`，没有 RGBDS 语法/目标 Bank/ROM0 空间验收，也没有手机逐帧运行证据。`asm_symbol_preflight` 和补丁正反向应用不是汇编或设备验收。
- 用户实测重点：1F 与 B2F 长冰面持续前行、冰上反向键不能转向、碰墙后可选新方向、NPC/石头挡路不穿越、上/下楼梯不从 ICE 自动启动、跳崖过程无滑冰干扰、已骑车进洞正常显示。新 ROM 需离洞存档后重新进洞以刷新旧地图状态。
