# REF-340｜联合洞穴 B2F 单层开发候选

- 基线：用户已确认 REF-339 联合洞穴 1F/B1F 边缘、楼梯与固定 NITE 暗色正常。
- 本轮只激活 Gold `UnionCaveB2F`（稳定ID115 / slot58），地图数58→59，Warp138→140。
- 只开放 B1F ordinal4 `(17,31)` ↔ B2F ordinal0 `(5,3)`；B1F 的 Ruins ordinal0/1 继续不注册路由。
- B2F 10×18 Gold 源地图只新增1个32×32运行区块，8×8图块集不变；离线逐像素渲染与Gold源完全一致。
- Surf 使用Gold collision派生的168个 WATER 坐标。联合洞穴继续固定使用Gold `PALETTE_NITE` 对应暗色；边框沿用已验收的Gold纹理不可通行块。
- 本轮明确不接：3名训练师、2个道具球、周五拉普拉斯、野生遭遇、其它剧情。
- 静态检查不能替代ROM构建/设备验收；用户需重构Red/Blue/TEST并确认MAP空间、旧档、B1F↔B2F双向通行及Surf。
