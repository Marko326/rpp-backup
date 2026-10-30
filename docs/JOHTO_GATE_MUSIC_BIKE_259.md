# MUS-259 — 城都活动门房音乐继承与骑车权限审计（用户已验收）

## 原因与净修改

这轮源自北侧遗迹门房的用户实机报告：从遗迹进入门房时，被错误地换成36号路歌曲，且用户要求门房内延续进入前的播放进度。实际代码 `JohtoPilotLoadMapMusic` 只给31号路／桔梗市门房做了入侧音乐继承；遗迹南、北门房仍使用固定的 profile 音乐。GSC/GSCC/RND 的 `LookupJohtoMapGSCMusic` 同样只认首座门房，导致北门房固定请求 `MUSIC_GBP_GSC_ROUTE36`。骑车许可也遗漏了北门房稳定 ID19。

本轮改为三座活动城都 Gold `GATE` 门房统一采用**入口实际来源的完整音乐 profile（RBY 歌号和 Bank）与 GSC 场景**。进入门房时先从 Warp 源 `C` 保存稳定 ID，然后对照各门房的两侧合法来源。只有合法进入才继承；在门房内旧存档 Continue 或 WRAM 来源不可靠时，回退到门房原来的 Gold 默认 profile（31门房和南门房 ROUTE_30，北门房 ROUTE_36），不会误把未知 `0` 当作若叶镇。原 `CheckJohtoMusicSceneTransition` 在场景相同时不清除播放缓存，`PlayDefaultMusicCommon` 若歌号相同返回，**静态上没有要求歌曲重启**。没有修改现有歌曲资源，也没有替换遗迹外围当前暂用的地图音乐；与 Gold 的 `MUSIC_UNION_CAVE` 最终一致性是独立后续事项。

> 同一首音乐的实际播放光标是否连续，要由 ROM／模拟器或手机验收；源码检查只证明选曲和缓存路径，没有实际音频执行证据。

## 当前三座门房和 Gold 骑车许可

| 稳定 ID | 原版地图 | 有效进入侧 | Gold 环境 | 骑车 |
|---|---|---|---|---|
| 6 | Route31VioletGate | 31号路／桔梗市 | GATE | 允许 |
| 102 | Route32RuinsOfAlphGate | 32号路／遗迹外围 | GATE | 允许 |
| 19 | Route36RuinsOfAlphGate | 36号路／遗迹外围 | GATE | 本轮新增允许 |

Gold 原版的 `Route35NationalParkGate` 和 `Route36NationalParkGate` 实际环境为 `INDOOR`，**不能**按名称或共享门房贴图自动开放。关都和普通房屋沿用旧有自行车白名单，未增加 GATE tileset 全局权限。

## 强制失败的审计

`tools/johto_gate_music_bike_audit.py` 联合读取实时活动资源目录、已有 Warp 双向合同、地点弹窗的 neutral 地图合同、Gold 原版 `data/maps/maps.asm`（可选但建议提供）、RBY 与 GSC 选曲代码、音频缓存逻辑和骑车许可。每增加一个活动门房，必须有显式音乐／骑行策略和经 Gold 核对的入侧坐标来源。脚本要求三套登记一致；任何遗漏、新增 `INDOOR` 门房被自动放行、误使用 Kanto 的 `$FC`/旧 map ID、门房固定成错误道路歌曲、或相同场景下强制重启都失败。

命令：

```sh
python tools/johto_gate_music_bike_audit.py --project . --gold-root /path/to/pokegold-master
python tools/johto_pilot_migration_audit.py --project . --gold-root /path/to/pokegold-master
python -m unittest discover -s tools/tests -p 'test_*.py'
python tools/asm_symbol_preflight.py
```

该脚本已经集成到 `johto_pilot_migration_audit.py`；不附 Gold 源码也会执行当前活动门房的最基本 Fail-closed 合同。`test_johto_gate_music_bike_259.py` 包含缺北门房骑车、错误音源、未经登记的新门房、普通室内误开放、同场景重启等负向变异。

## 用户验收反馈与本机建议复测

1. **从遗迹进北门房**：在 RBY、GSC、GSCC、RND 四种模式测试，核对音轨未切到36号路，也没有重新从头播放；从36号路进入则延续36号路音乐。
2. 从31号路／桔梗市进入首座门房、从32号路／遗迹进入南门房；各自音轨应延续，离开门房到不同曲地图才换歌。
3. 北门房在有自行车时可骑车进、骑车出、门房内上下车；另外两座继续可骑车。普通室内和关都行为保持原状。
4. 音乐设置 Bike Song On/Off、Surf、存档 Continue 门房落点、上下门房自动步行及双向 Warp 做回归。
5. 检查正式／TEST 红蓝编译和最新 MAP。AI 静态测试不代替构建与实机；未经用户本次实测，不出清理提交日志，不执行 Git Commit/Push。

## 2026-10-30 正式清理记录

用户确认 `.259` 没有问题，因此记录为用户侧功能验收通过；不将本环境未做的独立音频测量、RGBDS 链接和旧存档逐样本回归写成已完成。相对干净 HEAD `403e41e5ba763b4d747a7bbc6a03d6da161ab1be`，本次提交仅包含 `.257`～`.259` 定稿后仍实际存在的地图、名称、音乐与骑车功能及其审计，不罗列已经撤销的中间试修。
