# CLEAN-5.62.296｜正式清理与跨窗口交接

## 1. 真实基线和验收边界

- 分支：`常规功能备份`；最新可核对已提交HEAD是用户2026-10-31 `.290` 导出中的 `a6141c690bb7bf6fca128011498cac2526124666`；导出记录明确HEAD干净且此前双提交已合并。无本轮 `.293～.296` 用户Git提交证据，不得擅自声称已有新HEAD。
- 本轮未提交累计实现：`MAP-5.62.293`(只准备Gold资源)→`MAP-5.62.294`(启用Route37和EcruteakCity，26→28活动图)→`FIX-5.62.295`(圆朱Surf运行分派)→`TOOL-5.62.296`(开发者Surf审计，不改游戏)。游戏正式版本`FIX-5.62.295`，测试版本`TEST-231`。
- 用户实测报告`.294`的圆朱冲浪无法下水，`.295`修正后明确回复“没问题了”，不推断其已经覆盖所有步行／骑行、Save/Continue、其他地图。没有与`.295`对应的最新链接MAP或本环境ROM构建结果。
- 新增运行地图Route37和EcruteakCity；Route38及圆朱西门房只有源候选，仍关闭，未开放相关门毯、剧情和额外道路。

## 2. 本阶段事故与真正的阻断措施

- `.294`先报803/803主审计全绿，但完整Gold测试后才发现37号路6处跳台、圆朱6条方向性跳台及20格水域的场地技能执行合同不全；已纳入Gold主审计而不是跳过。
- `.294`圆朱拥有Gold水格，但Surf ROMX移动分派没有圆朱ID，导致用户实机无法正常冲浪；`.295`接入正确执行路径，审计故意切断后必须FAIL。
- `.296`每次地图改动由开发者主动运行`tools/johto_surf_dev_check_296.py`：从真实活动地图+原版Gold水坐标及锁定manifest自动审查A键/道具下水、水中四方向移动与安全上岸。用户不需要运行此脚本；无Makefile强制钩子。若改动地图导致水域清单漂移，开发者应检查Gold来源和代码，不能直接重生成manifest以消警。
- 之前`.283～.290`Warp目标序号、碰撞函数实际分派、跨Bank脚本、门房边界、成熟阻挡、草丛OAM、窄图右侧预览条带错误均已在`RPP_DEVELOPMENT_PITFALLS.md`首部记录。新阶段不得回退这些门禁。

## 3. 关键目录、开发者审计和下一批入场

- Gold：`REFERENCES/Gold/pokegold-master`；旧成熟：`REFERENCES/NPC/NPC-5.62.243`。两者来自此前用户提供的完整Gold/NPC交接包；若新窗口缺必要具体资源，必须先向用户索取，不可凭视频、推测或不完整文件替代。
- 最新运行源码：`PROJECT_SOURCE/`，含工具、合约、测试、规则及历史导出元数据；原版参考不应直接复制为现有物理稳定ID。
- Gold 主审计：`python tools/johto_pilot_migration_audit.py --project . --gold-root <Gold目录>`；开发者Surf门禁：`python tools/johto_surf_dev_check_296.py --project . --gold-root <Gold目录>`；完整测试：`GOLD_SOURCE_ROOT=<Gold目录> JOHTO_GOLD_SOURCE=<Gold目录> PYTHONPATH=tools python -m unittest discover -s tools/tests -p 'test_*.py'`；局部标签：`python tools/asm_symbol_preflight.py`。必须保存实跑结果，不得把静态检查写成ROM链接通过。
- 下一阶段优先Route38EcruteakGate(ID23)、Route38(ID24)；Gold源文件候选在`maps/johto_pilot/candidates293/`。圆朱成熟阻挡相较候选Gold有2格差异、Route38有4格差异，需逐格对照；旧 NPC 有38门房返程方向陷阱。必须同时审Bank/Script、Warp源目的零基槽与来回方向、开放边界与封闭边界、显示缓冲、音乐续播、骑车、Fly/名牌、Cut/Surf/跳台，非必要入口保持关闭。

## 4. 双提交／交付规则

用户自行将清理增量应用到已安装`TOOL-5.62.296`的当前未提交工作区，或者从确认`.290`HEAD应用累计全量恢复，两者互斥。为提交两笔，先应用反向隔离补丁退回工具、测试和维护文档，仅保留游戏功能提交第一笔；再执行`git apply -R`恢复隔离补丁并提交第二笔。没有新的用户HEAD前，不把旧`.290`以来的功能写成已提交。

清理包仅包含3份patch+2份中文日志；交接包单独包含当前完整源码、Gold/NPC原始参考、项目要求和来源校验。所有用户侧旧MAP属历史构建信息，不能证明当前ROM0≥64B；助手未编译ROM、未操作用户Git。
