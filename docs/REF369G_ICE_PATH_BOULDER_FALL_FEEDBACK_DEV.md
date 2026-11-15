# REF-369G@｜冰之通路怪力石头落洞原版反馈（开发候选）

## 原版参考与当前差异
本轮对照交接包 `JOHTO_HANDOFF_REF312_FLAT_REFERENCES_交接文档.zip` 内 Gold `maps/IcePathB1F.asm` 的 `.FinishBoulder`：
`pause 30 -> playsound SFX_STRENGTH -> earthquake 80 -> opentext -> The boulder fell through. -> waitbutton`。
REF-369F 此处已有按石头/目标坑分别写入 D853/D852、隐藏源图对象和单声效，但没有原版落洞演出、台词；不能视为完整落洞反馈。

## 运行代码修改
- `JohtoIcePathB1FCheckStoneDrop369B` 仅在 stock 推石动作完成、目标属于四个 Gold PIT、目标 PIT 尚未标记填满后执行：先写 PIT 占据位和源石头已落位，移走源图精灵，再延迟 30 帧、播放已有 Strength 音效、复用已存在的 `JohtoBurnedTowerEarthquake16` 五次（16 步×5，2 帧/步），显示 `The boulder fell / through.`。
- 既有一帧一次 bit7 消费及已满坑 `ret nz` 保护不变，落洞反馈不会因 B1F 地图脚本反复执行而连续弹出。四块石头仍然可以以不同来源进入任意未填 PIT，源石头身份与目标坑编号分开保存。
- 没有改 Bank0、ROM0、存档结构、地图/Tile/Border、图块、ICE 滑行、Save/InitMapSprites（REF-369E 修复）、Gold Warp 或已有楼梯。玩家 PIT 仍然关闭。
- 这是对 Gold `earthquake 80` 的现有震动例程复用；是否在手机上与 Gold 逐帧一致，未实际对照，不作精确动画验收声明。

## 核验与未验收
- 新增 `tools/johto_ice_path_boulder_fall_369g_audit.py`，核对实际 B1F 地图脚本入口、Gold 四个 PIT 坐标、保存状态写入先于 UI、仅一次触发、30 帧停顿、80 步震动计数、消息格式及已有 BurnedTower 符号；相关错误注入用例会主动使检查失败。统一 `tools/validate_current_project.py` 增加硬门禁。
- 用户需将两份互斥补丁之一应用到对应基线，并由用户侧编译新 ROM/MAP：在 B1F 开启 Strength，分别推动四石头入四坑；检查只在石头落洞那一次震动/出现提示，没落洞时不能弹；走楼梯到 B2F 检查落石是否出现在正确位置，保存、关机、继续游戏检查两层状态；特别复测 B2F Save 不花屏及 B1F/B2F Gold 边界。旧 REF-369A 已损坏 D855 的存档不能据此自动修复。
- 本轮静态测试不是 ROM 构建、MAP 空间或手机运行验收。Gold 玩家自身坠洞、Rock Smash、道具与剧情仍延后。

## 基线与交付
- 分支及正式基线沿用已核实 `常规功能备份` / `935b3fa738dce42f22768e94c92c920bb5b86d89`（正式 REF-368）；当前已应用开发候选 REF-369F@。
- 单一 ZIP 严格仅两份 `.patch`：01 从 REF-369F@ → REF-369G@ 增量，02 正式 REF-368 HEAD → REF-369G@ 全量；二选一不能叠加。无 Git Commit/Push，项目要求本轮不编译 ROM。
