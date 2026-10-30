# FIX-261｜合并独立 RGBDS ASSERT 预检与联合洞穴歌曲补项

## 历史问题

用户 `CAV-5.62.260.zip` 的 `NUM_JOHTO_ACTIVE_MAPS` 为14，新开放的 Union Cave 1F 是稳定 ID 8、活动 slot13。`engine/menu/options_menu.asm::JohtoActiveGSCMusic` 原先只有13个 `db`，导致第1232行 `ASSERT JohtoActiveGSCMusicEnd - JohtoActiveGSCMusic == NUM_JOHTO_ACTIVE_MAPS` 报错。

本次根据已恢复的用户交接资料 `REFERENCES/Gold/pokegold-master/data/maps/maps.asm`：`UnionCave1F ... MUSIC_UNION_CAVE`，在第14项写入 `db MUSIC_GBP_GSC_UNION_CAVE`；其他13项与 `JohtoPilotMapProfiles` 未变。

## 上一个独立 ZIP 的合并方式

先前单独提供的 `johto_assert_preflight_standalone.zip` 含 `johto_table_assert_preflight.py` 和 `README.txt`。这次工具已纳入源码 `tools/johto_table_assert_preflight.py`，且直接挂在 `tools/johto_pilot_migration_audit.py` 中，不需要用户再复制脚本或另打一包。原 TXT 的用途、只读行为、调用方式和限制已完整吸收在本文件与开发包说明里。

## 验证命令

```sh
python tools/johto_table_assert_preflight.py --root .
python tools/johto_table_assert_preflight.py --self-test
python tools/johto_pilot_migration_audit.py --project . --gold-root /你的Gold源码目录
python -m unittest discover -s tools/tests -p 'test_*.py'
python tools/asm_symbol_preflight.py
```

预检会静态计算与活动地图数有关的 `db/dw/dl/ds` 表数据字节数，必须至少检查 Town Map项、浏览索引、GSC音乐表三条相关 ASSERT。删除表项、重复表项、缺少 ASSERT 均 FAIL；无法安全解析的复杂语法也 FAIL。更一般的常量表达式与 ROM 链接问题并不覆盖。

## 验收边界

本次未调用 `make`、RGBDS 或 ROM 链接；也未更新生成 MAP。原有洞口 Warp、音乐场景延续、骑车、Surf 及已有存档格式不改。先本机成功编译并提供新 MAP，然后实机复测洞穴音乐和进出，再做清理三件套与 Git 提交日志。
