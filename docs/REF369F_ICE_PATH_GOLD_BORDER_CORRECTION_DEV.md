# REF-369F@ — 冰之通路地图外围岩石边界块修正（开发候选）

## 依据与实测
用户提供原版 Gold 与 REF-369E 四张对照图，确认部分楼层地图外围原应是岩石，当前版本却出现浅色地面。用户同时确认 REF-369E B2F 保存后不再花屏，本轮独立处理边界显示，不改精灵及 Save 链。

Gold 对照：交接参考中的 `REFERENCES/Gold/pokegold-master/data/maps/attributes.asm` 对 Ice Path 1F、B1F、B2F Mahogany、B2F Blackthorn、B3F 的 Border Block 分别是 `$09/$19/$19/$19/$19`。

此前运行时对象边界分别 `$09/$09/$09/$19/$19`，B1F（首次于 REF-367K 活动）和 B2F Mahogany（REF-368A 活动）错把外围填充设成地面 `$09`；Gold blockset `$09` 全为地面 tile18，`$19` 是四角 rock 6/7/22/23。五图 runtime .blk 已核实与 Gold 一致，因此不要修改内部主地图块。

## 本轮修改
- B1F、B2F Mahogany 两个对象表的首字节 Border Block `$09→$19`；不改图块、人物、碰撞、事件位、SRAM、地图边框之外的主体块、Warp 或 BANK0。
- GameVersion 改为 REF-369F@；更新相关审计的精确版本门槛，增加五层 Gold Border Block 静态核验及故障注入。
- 从 REF-369E 当前工作区使用 01 增量补丁；从正式 REF-368 HEAD `935b3fa738dce42f22768e94c92c920bb5b86d89` 使用 02 累计全量补丁，二者互斥，不可叠加。

## 验收边界
本阶段不做 RGBDS ROM 编译、不执行 Git Commit/Push。静态检查及补丁回放不等于设备验证。手机复测同位置，分别观察 B1F、B2F Mahogany 的地图外围是否恢复连续岩石；回归 1F/B2F Blackthorn/B3F 原有边界与此前 Save 返回不花屏。已存档无需重置。
