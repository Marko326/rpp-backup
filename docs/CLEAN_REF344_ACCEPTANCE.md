# CLEAN-REF344｜清理与交接

- 正式HEAD `0a676cb4722728c990ff5340527c7762d66d245d`（REF-338、常规功能备份）；当前真实工作区为REF-344候选；不假定这中间已Git提交。
- 功能累计：Union Cave三层、Slowpoke Well B1F/B2F、共享Gold Cave图块/碰撞/楼梯/Surf与B1F怪力石头；共61活动图、144条Warp，标签REF-344。
- 用户手机反馈：怪力正常推动。未报告B2F整层楼梯/Surf/方向墙、旧存档与Red/Blue/TEST新MAP全部通过。
- 清理不改ASM/地图图块/版本，仅更新离线ROM0审计长度与文档；旧主审计仍存在REF-338冻结地图数造成的失败，不能视作全项目通过。
- 正式模式A，第一笔功能，第二笔离线工具/审计/文档。01清理增量来自已应用REF-344；03累计全量来自已确认HEAD；02仅作为临时反向隔离，先应用后提交第一笔，再`git apply -R`恢复后提交第二笔。01/03不叠加。
- 用户需自己核对三个构建ROM/MAP（ROM0>=64B）、ROMX bank、旧档，并针对B2F楼梯/Surf与井口返回做手机验收；不自动验收未开放NPC/剧情。
- 后续Burned Tower（DAY、PIT、TOWER图块）独立开发包，先做Gold语义/入口和楼层安全预检，不能把PIT降级为普通LADDER。
