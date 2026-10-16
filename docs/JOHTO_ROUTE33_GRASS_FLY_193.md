# MAP-5.62.193 — Route33 草地与 Fly 最小修复说明

## 证据与原因

- 以 `pokegold-master/maps/Route33.blk`、`johto_modern_metatiles.bin` 和 `johto_modern_collision.asm` 逐格交叉核查：Route33 20×18 个 16×16 象限中，12 个 `TALL_GRASS` 均位于 Y=16、17 且 X=6..11；它们每象限四张 8×8 图片的 ID 均为 `$04`。
- `.192` `data/tileset_headers.asm` 在 `JohtoModern` 的草地字段写 `$FF`，导致 `engine/overworld/movement.asm` 和 `UpdateNPCSprite` 无法按原引擎设置下半身 OAM 优先级；改成 `$04`，不触碰 `.tilecoll`（仍为 `$FF`）、坐标碰撞掩码、图形资产。
- `.192` 队伍菜单 `engine/menu/start_sub_menus.asm` 的 `.fly` 只单独判断 `JOHTO`，没有 `JOHTO_MODERN`，而 `CheckIfInOutsideMap` 也不把此值当关东 `OVERWORLD`。故在当前已有徽章前置之后加入精确 `JOHTO_MODERN` 分支；保留旧校验，并非解除徽章条件或开放 Route33 Fly 目的地。

## 当前功能边界

- 视觉遮挡使用已存在的 RPP 草地精灵图层处理；**没有新增草地抖动特效**（早期尝试的额外覆盖精灵本来就已撤销）。
- **野生草丛遇敌仍延期**：`LoadWildData` 用旧 `wCurMap` 索引，原生 `Route33` 当前为 `$FC` 且无专用条目，`NoMons` 的草地遇敌率为 0。不能把这轮的草地遮挡修复误记为 Gold Route33 原生野怪已移植。
- 飞空仅表示站在 Route33 可以调用队伍菜单 Fly；城市候选仍遵守已经获得的徽章和已访问地点规则。洞穴、B1F、桧皮镇未开放边界不变。
- 用户在 Termux 自行构建、手机验收前，这一轮只给出源码与 Gold 静态合同，不保证 ROM Bank/链接或实机完整效果。

## 最小验收

1. Route33 草地 X=6..11、Y=16..17：角色下半身被草遮挡，离开草地立即恢复。
2. Route33 使用 Fly 能呼出城都 Fly 地图，能选已解锁城市，取消则留原地；不能从洞穴直接开启室外 Fly。
3. 简查 32↔33 北边界与联合洞穴南北 Warp、Dig/逃洞绳；旧关东 Fly 保持。
