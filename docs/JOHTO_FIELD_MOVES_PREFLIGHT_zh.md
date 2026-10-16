> **DIG-5.62.188 现行状态（覆盖下方历史 `.187` FMP-001 初始讨论）**：Surf 仍仅开放 Union Cave 1F 与 Route32；**Dig／逃洞绳新增且仅开放 Union Cave 1F**，从洞内回到 Route32 `(X=6,Y=80)`。Gold 原版是动态记忆洞口来源，当前 RPP 为单一已开放入口的固定安全落点；关东 Dig／逃洞绳、黑屏治疗点返回不改变。用户确认能回洞口，完整 Gold 门禁 `298 PASS / 0 skip`；其它洞穴/地图仍延期，Route33 开通前必须重做动态来源返回合同。下文 FMP-001 保留为历史前置设计，不能当作 `.188` 实际开关。

---

> **SRF-5.62.187 阶段更新**：本文记录 FMP-001 初始的“全延期”前置基线；当前已分阶段开放联合洞穴 1F、32号道路的 Surf，且仅这两图临时免城都徽章。仍禁止全局水面许可表放行，Dig／逃洞绳继续延期。请以 `docs/JOHTO_ROUTE32_SURF_187.md` 为现行 Surf 合同。

# 城都 Field Moves 第一阶段：只读前置检查（RBK-5.62.184）

本轮不开放新的 Surf、Dig 或 Escape Rope，也不改动骑行、门房、洞穴 Warp、背景音乐和存档结构。目的是先锁住旧引擎在原版地图与城都图块集之间的危险适配点，避免未来只加一个许可表项目就认为野外技能已经完成。

- Surf 有两套入口：`engine/overworld/field_moves.asm` 的 `WaterTilesets2` / `IsSurfTile` 与 `engine/items/items.asm` 的 `WaterTilesets` / `IsNextTileShoreOrWater`，还要核对 `TilePairCollisionsWater`、上岸、动画、音效和边缘安全。两个表都加上不等于新的 Johto 水面编号能安全执行；Gold Cave 的水面碰撞类别不能直接等同 RPP 的图块 ID。
- Dig 和 Escape Rope 共用 `CanUseEscapeRope`，但实际返程依赖 `wLastBlackoutMap`；该信息由原有 `wLastMap` 维护，在 Johto `$FC` 共享地图句柄与跨地区时不能单靠增添 `JOHTO_UNION_CAVE` 保证返回正确。打开前要设计明确的 `(region, local_id)` 返回地、保存兼容与演出路径，并单独测试原有关都 Teleport/黑屏返回。
- `wObtainedJohtoBadges` 当前只有存储位，不能把 Gold 的 Fog Badge 需求假装已连接到现有的 Kanto Soul Badge。后续独立设计徽章准入，而不是直接把所有 Johto 水域放行。

执行：`python3 tools/johto_field_moves_preflight.py --rpp . --gold /完整/pokegold-master`，或通过 `make johto-map-audit` 自动执行。工具只会在未完成的 Johto 技能被提前开放、必需引擎钩子被去掉、或来源缺失时失败；**PASS 表示目前安全维持 DEFERRED，不表示冲浪等已能使用**。负向测试覆盖错误开启两种水表、洞穴逃洞绳、把能力冒充 ALLOWED、替换旧返程寄存器路径。

下一功能阶段顺序：先逐张地图识别确实存在的可冲浪水块、岸边及不可达边缘；把适配所需的碰撞和动画与 Gold 样例独立核准；再设计独立的城都徽章判断并开放一个可控场景，手机回归确认上下水／背景音乐／进出门／存读档后才扩大范围。Dig 与 Escape Rope 在地区正确返回地址经静态和手机验证之前继续保持不开放。

由于原始 `.184` ZIP 的导出漏掉两个被忽略的 `.json` 合同，此轮须先确认它们真正受 Git 跟踪或在新 ZIP 中显式包含；不可拿缺少合同的 ZIP 运行门禁并宣布成功。
