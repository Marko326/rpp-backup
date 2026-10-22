# Gold 东线五图离线预审素材（不可直接运行）

此文件夹下的 `.gold_source.blk` 为原版 Gold 的完整布局副本，`.gold_collision_review_mask.bin` 为项目既有 `johto_rpp_pipeline.py` 离线转换得到的遮挡候选位图；它**不是完整 RPP 运行时碰撞准入许可**，尤其不包含 Surf 水格、跳崖、冰面滑动、双向地图连接、出洞返回、NPC 和 Fly。

只在下一阶段实际开发、审阅并启用相应地图时，由维护者将需要的区块/掩码编入运行时；本批未激活任一入口或新地图。来源、尺寸、哈希、Warp 和连接检查见 `tools/johto_east_corridor_source_contract.json` 与 `docs/JOHTO_EAST_CORRIDOR_239_SOURCE_REVIEW.md`。
