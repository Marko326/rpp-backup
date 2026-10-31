## FIX-5.62.285｜35号路栏杆碰撞真实入口修复（待实机验证）

- 实机视频 `62987.mp4` 证明：35号路从满金北门房出去，左侧视觉栏杆可被步行/骑车穿越，而右侧外观相近栏杆正常。`.284` 把国家公园入口 `(3,5)` 加入 `JohtoSouthMatureDoorFence`，却未验证这条函数能否在普通移动路径被调用；因此属于修错层级。
- 根因：`JohtoOverworldSouthLandDecision` 的地形分派只接收稳定ID10～15。新增 Route35(ID17) 与 Route35GoldenrodGate(ID18) 遭 `.route33` 回退，E=2 进入旧的 8×8 图块碰撞；因此 Gold 16×16 `Route35.roles.bin` / 门槛封锁和骑车通用规则均不能被可靠执行。
- 修复：在 ROMX Bank `$4F` 的入口显式检查 ID17、ID18，并汇入原 `.activeSouthMap` 的 `HandleLedges → JohtoSouthSpatialStep`；旧10～15和 Route33 继续原路径，**ID16 Route36 不纳入此范围**。不修改ROM0指令、不编辑Gold `.blk`、角色表、门槛和Warp、地毯、Surf/Cut、音频或存档结构。
- 新增强制审计及4项负向测试：删掉17、遗漏18、误把16接进分派、丢失公共执行入口必须失败。项目版本 `FIX-5.62.285`；测试版 `TEST-231` 保持不变。旧 `.284` MAP不能证明本次ROM链接余量，手机与新的Red/Blue ROM/MAP仍待验证（ROM0≥64B）。
