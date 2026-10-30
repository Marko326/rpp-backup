用途：只读检查城都活动地图相关的 RGBDS 数据表长度 ASSERT。
不会编译 ROM，不会修改源码，不会自动删除或放宽 ASSERT。

放在项目 tools/ 目录（或在外部直接运行）：
  python tools/johto_table_assert_preflight.py --root .
  python tools/johto_table_assert_preflight.py --self-test

特别检查 engine/menu/options_menu.asm 的 JohtoActiveGSCMusic
是否与 constants/region_map_constants.asm 中的 NUM_JOHTO_ACTIVE_MAPS 一致。
新增活动地图时，先同步增加音乐表等登记条目，再执行此检查。

注意：本工具只识别可静态计算的 db/dw/dl/ds 数据表和表长 ASSERT；
并不等于 RGBDS 汇编／链接全功能校验。如果出现未知宏／复杂计算，
该工具会 fail-closed 报错，不应忽略报错。

本次会话内暂时无法取得 CAV-5.62.260 工程文件的实际字节，
所以此文件为独立的预检工具，不代表已修复用户所报的第1232行。
