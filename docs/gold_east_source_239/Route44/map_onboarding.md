# Route44｜地图接入与Field Moves核对清单

> 来源：Gold离线数据。此表不代表ROM已注册或技能已开放。

| 检查点 | 状态 | 原因 |
|---|---|---|
| map_registration | REVIEW_REQUIRED | 地区/局部 ID、Header、Bank、图块集与地图尺寸必须完整登记 |
| art_palette_vram_bank | REVIEW_REQUIRED | 图像、色板、音效/背景音乐与固定 Bank 空间需要核对 |
| collision_and_ledge | REVIEW_REQUIRED | Gold 特殊地格 1、跳崖候选 21、不安全跳崖 0 |
| outdoor_connections | REVIEW_REQUIRED | 确认Gold连接方向、连接条带、反向、越界与跨tileset重载；没有自动放行 |
| roof_mapgroup_gold_reference | REVIEW_REQUIRED | 按 Gold data/maps/maps.asm 的 mapgroup 反查 roofs.asm 专属9 tile、roofs.pal RGB5；每张道路与所属城市共用原版屋顶组，且 full-load 与连接热替换均必需。必须通过 johto_roof_reference_audit，不允许手调近似颜色或只核对 .blk。 |
| warp_entrances | REVIEW_REQUIRED | Gold Warp 1 个，特殊入口 1 格；逐一核对双向、方向及落点 |
| surf | REVIEW_REQUIRED | Gold 水域相关16x16地格 120 个；逐岸核对上水、移动、上岸、徽章、音乐及双入口 |
| dig_escape_rope | NOT_APPLICABLE | 洞穴需分别审核技能准入、最近入口来源、跨地区安全返程、旧档与黑屏返回 |
| fly_use | REVIEW_REQUIRED | 室外可使用 Fly 的许可与徽章检查；不等于该地图是可选择的目的地 |
| fly_destination | NOT_APPLICABLE | 城镇/城市的到访记录、目的地登记和安全落点，独立于Fly使用许可 |
| bicycle | REVIEW_REQUIRED | 按实际地图/tileset和入口限制核对骑行与进门下车，不自动加入白名单 |
| obstacle_field_moves | REVIEW_REQUIRED | Cut、Strength、Rock Smash、Flash及环境机关须独立查Gold事件与RPP能力 |
| town_map | REVIEW_REQUIRED | 地标显示坐标、可浏览与实际可Fly目的地分别核验 |
| music_transitions | REVIEW_REQUIRED | 正常切图、Warp、Surf、骑行/战斗后的音乐恢复 |
| encounters_and_events | REVIEW_REQUIRED | Gold对象 10、路牌 3、坐标事件 0；野生遭遇和脚本是独立移植项目 |
| save_continue_and_blackout | REVIEW_REQUIRED | 地区/局部地图ID、Continue、旧档、Teleport、治疗点及跨地图返回安全 |
| runtime_build_and_phone | REVIEW_REQUIRED | 编译链接/Bank余量、手机正反方向、边缘和旧功能回归须独立验收 |
