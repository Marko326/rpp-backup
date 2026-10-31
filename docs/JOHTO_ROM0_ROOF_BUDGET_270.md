# FIX-5.62.270｜ROM0 Home Copy Data 链接溢出修复

## 用户反馈与原因

用户在应用 `.269` 后由本机 `rgblink` 报 `Unable to place "Home Copy Data" (ROM0 section) anywhere`。`Home Copy Data` 是原有 9 字节 ROM0 复制例程，未被本轮直接改动；近乎填满的 ROM0 无法再容纳其独立 SECTION。`.269` 在 `home/overworld.asm` 的**完整地图载入**和**无缝地图连接**各新增一次 `callba`，项目宏展开每次为 `ld b,bank` (2B) + `ld hl,address` (3B) + `rst $18` (1B)，即两处共 12B。这是能从源码确认的 ROM0 额外开销，未取得本机失败版本 MAP，不能推算准确剩余空间或宣称 ROM 已成功链接。

## 修复设计（不增加 ROM0 的跨 Bank 调用）

- `LoadTilesetTilePatternData` 已有一次 `callba ApplySnowTilesetGfxPatch`，改为相同 6B 的 `callba JohtoSouthTilesetGfxFinalizer270`。新 ROMX Bank `$4F` 包装器先执行原雪天图块补丁，再执行 `.269` 的 `JohtoSouthRoofAfterTilesetLoad`。原 `LoadMapData` 末尾额外 6B 的屋顶调用删除。
- `CheckMapConnections` 已有一次 `callba InitMapSprites`，改为相同 6B 的 `callba JohtoSouthConnectionSpritesAndRoofs270`。新 ROMX Bank `$4F` 包装器先初始化地图精灵，再执行 `.269` 的 `JohtoSouthRoofOnConnection`。原外层额外 6B 调用删除。
- **仍由 ROM0 执行 `call LoadTileBlockMap`**：它处理地图接缝、调用 `SwitchToMapRomBank`，可能改变当前 ROM Bank；不能粗暴将整个函数搬进正在执行的 ROMX Bank，否则存在中途切换代码 Bank 的风险。
- 结果：两处原有 6B 跨 Bank 调用的位置、个数不变，删掉 `.269` 新增的 12B；屋顶 PNG、RGB5、白天/夜间、雪天处理以及已验收的 `jp nz,.noCollision` 不改。
- `ReloadMapData` 与 `ReloadTilesetTilePatterns` 同样走 `LoadTilesetTilePatternData`，因此重新加载图块时仍会进行屋顶重绘。无缝连接的屋顶更新在 Sprite 初始化后、地图块 WRAM 更新前执行，两者互不依赖；不增加 ROM0 容量。

## 防回归与验收边界

- `python tools/johto_rom0_roof_preflight_270.py`：检查两个 ROM0 旧 farcall 替换、ROMX 包装调用链、原 `CopyData` 未动及车主长 `jp` 保留。
- `tools/tests/test_johto_rom0_roof_270.py`：注入冗余 `callba`、移除雪天／精灵处理、更换分支、换回短 `jr` 均必须被拒绝；并加入总迁移审计。
- 执行 Python、Gold、ASM 标签与补丁回放等静态验证；**没有编译 ROM，也没有从当前源码生成新的 MAP**。用户本机需重建红蓝和测试版本，检查最新版 MAP 及 ROM0 至少 64B 安全余量，随后复测33号路—桧皮镇接缝、森林跳崖与屋顶颜色。若仍溢出，需新 MAP／完整链接日志进一步诊断，不得删除 `Home Copy Data` 或硬塞 `.2bpp`。

正式版 `FIX-5.62.270`，TEST 保持 `TEST-231`；开发阶段只交两份互斥补丁的单一 ZIP，不执行 Git Commit/Push 或正式日志。
