# FIX-5.62.258 — 城都地点栏/门房中立地图检查

## 问题与最小功能修复

MAP-5.62.257 遗迹北门房 ID19 已在 Town Map/存档名称表中，但 `engine/overworld/map_name_sign.asm::.IsNeutralMap` 只识别 ID6、102，遗漏 ID19。走入门房后未被识别为中立过渡区，显示兜底 `Johto`。修复仅为稳定 ID19 加 `cp`/`ret z` 两条指令；不更改 Warp、门房自动移动、地图布局或关都行为。

## 新增自动审计

- `tools/johto_map_name_sign_contracts.json` 中按**活动资源描述表**排列每个稳定地图 ID，并明确中立 `neutral` 或可显示名称 `named`；中立门房保留其 Town Map/Save/Continue 使用的文本绑定，但 map-name popup 必须继承前一有效地点。
- `tools/johto_map_name_sign_audit.py` 从 ASM 读取活动表、两个地区/句柄判定分支、每个稳定 ID 的中立或有名派发、实际文本及 Town Map/Save 名字。不硬编码单个门房。新增地图必须增加合同，否则报 FAIL。
- `tools/johto_pilot_migration_audit.py` 调用审计；`tools/tests/test_johto_map_name_sign_258.py` 通过故障注入确保漏门房、漏道路、错误文本、缺合同、缺地区守卫都能被发现。

## 验收边界

脚本是静态源码审计，不是 Game Boy 仿真。开发阶段不编译 ROM、不执行 Git 提交。用户需构建正式／TEST 红蓝并实测遗迹北门房双向进出，确认进门无 `Johto`，离开显示正确区域，保留双向 `DOOR` 落点自动走一步和其他旧门房逻辑。
