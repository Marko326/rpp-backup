## CLEAN REF-367 当前安装入口（历史 REF-365A 说明保留在下方）

正式清理 ZIP 包含 `01` 当前候选→CLEAN、`02` CLEAN→仅游戏功能的工具反向隔离、`03` 干净 REF-366 HEAD→CLEAN，及两份中文提交日志。先选 `01` 或 `03`，不得叠加；用 `git apply --check` 验证后应用，然后应用 `02`、提交游戏，执行 `git apply -R 02` 恢复工具并提交。实际 ROM 编译/空间/手机验收由用户负责；历史旧文是档案而非本轮操作说明。详见 `docs/CLEAN_REF367_ICE_PATH_1F_B1F_FINAL_ACCEPTANCE.md`。

## REF-365A@ 黑暗洞穴开发候选｜基于实际工作区的补丁说明

本开发阶段只交一个 ZIP，内含两份互斥 `.patch`。这里的 01 以用户上传的 `REF-364.patch` **已应用**工作区为起点（此补丁为需求文档修改，不是 REF-365 功能版）；02 以 Git HEAD `9b3609c5345248d09a6849a393019edbf7869a5e` 干净源码为起点。**只能选择一个补丁，不能叠加。**

使用前执行 `git status --short`、`git rev-parse HEAD`、`git apply --check 所选补丁.patch`。如果工作区已有本候选的部分文件或其他未记录修改，必须先核对差异，不强制覆盖。项目要求不允许 AI 自行编译 ROM 或 Commit/Push；用户通过本机 ROM/MAP/设备测试后再正式清理。

本期接通黑暗洞穴 ID190↔ID99、ID99↔Route45，Surf/Flash/Bike/HOP/方向墙及 Dig/离洞绳来源；**Rock Smash 技能与四块碎岩石头全部延期，不实现。** 详见 `docs/REF365_DARK_CAVE_BLACKTHORN_DEV.md`。

---

## REF-5.62.312 / DEV-314｜REF-311 测试合同与纵向门房共享运行逻辑

- 基线：用户上传的 REF-311.zip；仅在该源码副本上增量修改。游戏版本提升为 REF-312，因为本轮改动了运行 ASM。
- 将 ID65 原先按地图复制的五类阈值/落点/边界判断改为 Bank $53 的共享表驱动函数；Mahogany Town 与 ID65 只保留各自坐标/方向/结果行。ID66 仍 inactive，Route43 室外与愤怒之湖仍关闭。
- 统一地图 ID allowlist：所有五个运行 hook 调用同一个 helper；未来兼容门房只需在中央 allowlist 和各配置表增加记录，不复制五套分支。
- 修正 REF-311 新增第39张地图后的历史测试合同、Gold/active-header registry、门房数量/门毯数量、Surf 无水图声明、版本断言与测试夹具。Warp 工具按实际运行表的历史 append 顺序推导，ID65 路由追加在 Ecruteak east gate 后；不重排 ASM 路由表。
- 仅源码/静态回归；AI 不编译/链接 ROM、不 Commit/Push。无 REF-312 新 MAP，ROM0/Bank 余量和设备行为仍待用户本机构建验证。
- 维护说明：`docs/JOHTO_VERTICAL_GATE_RUNTIME_314.md`；未来兼容门房只加配置，不复制阈值 ASM。

## MAP-5.62.268｜城都南线六图批量运行接入（开发候选，待本机验收）

- 基线：用户最新干净 HEAD `b4148ccb783bdf734d621d0b8e8419f24ffe72da`、分支“常规功能备份”、正式版本 `FIX-5.62.267`；一份完整补丁直接覆盖从 `.267` 到 `.268` 的全部新增源码与资源，**不需要先安装曾交付的资源／几何中间包**。
- 新增六张活动地图：`AzaleaTown`（桧皮镇）、`IlexForestAzaleaGate`（南门房）、`IlexForest`（桐树林）、`Route34IlexForestGate`（北门房）、`Route34`（34号道路）、`GoldenrodCity`（满金市）。活动地图 15→21；与既有33号道路组成连续南线。按 Gold/成熟 NPC 分支核对图块源、区块、碰撞、地图接缝、15 条六图内部 Warp、来源方向、音乐、地点名称及骑车许可；原有北洞口及关都不变。
- 场地技能：新增三张图共342格 Surf 水域（桐树林32、34号路226、满金市84），加桐树林1棵 Cut 树及桐树林/桧皮镇的精确方向跳崖规则。城都21张活动地图合计水格1098、Cut树8、跳崖碰撞格116；一切以 Gold 静态参考审计为准，不代替 ROM 实测。
- 资源：仅跟踪 PNG 图形源以及 Gold `.blk`、`.bst`、碰撞/角色数据；`.2bpp` 由 Makefile 的 PNG 转换规则在本机构建时生成，**禁止放进 Git 补丁**。保留用户已编译修改过的 `jp`，不做 `jp→jr` 回退；TEST 版本 `TEST-231` 不变。
- 边界：通往仍未接入的建筑／房间、联合洞窟地下层、Route32/33 直连及剧情 NPC/遭遇仍封闭；本轮不擅自把全部 Gold Warp 开放，也不新增存档字段。
- 验证：含 Gold 来源的完整 Python 测试267项中266通过、1项因用户侧新 MAP 不在本 ZIP 而跳过、0失败；城都迁移237/237、Warp到达18/18、ASM标签2081文件、三张表长及南线空间 Surf／资源审计通过。**未运行 RGBDS 编译、链接、ROM、手机测试，不把开发候选写成实机验收通过。** 只有用户本机成功编译并跑通整条路线之后，才制作正式清理三件套／中文提交日志。
- 开发交付：单 ZIP 中仅两份互斥 `.patch`（`.267→.268` 增量、同一已确认干净 HEAD→`.268` 全量）。两份从同一干净基线生成，不能叠加。用户本地如已装旧 `.268` 中间包，必须先还原到 `.267`，不要直接叠加完整补丁。

# Instructions

These instructions explain how to set up the tools required to build **Pokémon Red++ v3**, including [**rgbds**](https://github.com/gbdev/rgbds), which assembles the source files into a ROM.

This repository expects **RGBDS 0.5.2** (also recorded in `.rgbds-version`). The Makefile uses RGBDS from your `PATH` by default, or a separate local installation when `RGBDS=...` is provided.

If you run into trouble, ask for help on IRC or Discord (see [README.md](README.md)).


## Windows 10

Download and install [**Windows Subsystem for Linux**](https://docs.microsoft.com/en-us/windows/wsl/install-win10). Then open the **WSL terminal**.

Update WSL's software before continuing. If you chose Debian, Ubuntu, or another distribution that uses `apt-get`, then enter this command:

```bash
apt-get update && apt-get upgrade
```

WSL has its own file system that's not accessible from Windows, but Windows files *are* accessible from WSL. So you're going to want to install pokered within Windows. You'll have to change the **current working directory** every time you open WSL.

For example, if you want to store pokered in **C:\Users\\*\<user>*\Desktop**, enter this command:

```bash
cd /mnt/c/Users/<user>/Desktop
```

(The Windows `C:\` drive is called `/mnt/c/` in WSL. Replace *\<user>* in the example path with your username.)

If this works, then follow [the instructions for **Linux**](#linux) below for whatever distribution you installed for WSL.

Otherwise, continue reading below for [the older Windows instructions](#windows).


## Windows

Download [**Cygwin**](http://cygwin.com/install.html): **setup-x86_64.exe** for 64-bit Windows, **setup-x86.exe** for 32-bit.

Run setup and leave the default settings. At the "**Select Packages**" step, choose to install the following, all of which are in the "**Devel**" category:

- `make`
- `git`
- `gcc-core`

Double click on the text that says "**Skip**" next to each package to select the most recent version to install.

Then follow the [**rgbds** install instructions](https://rgbds.gbdev.io/install/windows) for Windows with Cygwin to install **rgbds 0.5.2**.

**Note:** If you already have an older rgbds, you will need to update to 0.5.2. Ignore this if you have never installed rgbds before. If a version newer than 0.5.2 does not work, try downloading 0.5.2.

Now open the **Cygwin terminal** and enter the following commands.

Cygwin has its own file system that's within Windows, at **C:\cygwin64\home\\*\<user>***. If you don't want to store pokered there, you'll have to change the **current working directory** every time you open Cygwin.

For example, if you want to store pokered in **C:\Users\\*\<user>*\Desktop**:

```bash
cd /cygdrive/c/Users/<user>/Desktop
```

(The Windows `C:\` drive is called `/cygdrive/c/` in Cygwin. Replace *\<user>* in the example path with your username.)

Now you're ready to [build **pokered**](#build-pokered).


## macOS

Install [**Homebrew**](https://brew.sh/). Follow the official instructions.

Open **Terminal** and prepare to enter commands.

Then follow the [**rgbds** instructions](https://rgbds.gbdev.io/install/macos) for macOS to install **rgbds 0.5.2**.

Now you're ready to [build **pokered**](#build-pokered).


## Linux

Open **Terminal** and enter the following commands, depending on which distro you're using.

### Debian or Ubuntu

To install the software required for **pokered**:

```bash
sudo apt-get install make gcc git
```

Then follow the [**rgbds** instructions](https://rgbds.gbdev.io/install/source) to build **rgbds 0.5.2** from source.

### OpenSUSE

To install the software required for **pokered**:

```bash
sudo zypper install make gcc git
```

Then follow the [**rgbds** instructions](https://rgbds.gbdev.io/install/source) to build **rgbds 0.5.2** from source.

### Arch Linux

To install the software required for **pokered**:

```bash
sudo pacman -S make gcc git
```

Then follow the [**rgbds** instructions](https://rgbds.gbdev.io/install/arch) for Arch Linux to install **rgbds 0.5.2**.

If you want to compile and install **rgbds** yourself instead, then follow the [**rgbds** instructions](https://rgbds.gbdev.io/install/source) to build **rgbds 0.5.2** from source.

### Termux

To install the software required for **pokered**:

```bash
sudo apt install make clang git sed
```

To install **rgbds**:

```bash
sudo apt install rgbds
```

If you want to compile and install **rgbds** yourself instead, then follow the [**rgbds** instructions](https://rgbds.gbdev.io/install/source) to build **rgbds 0.5.2** from source.

### Other distros

If your distro is not listed here, try to find the required software in its repositories:

- `make`
- `gcc` (or `clang`)
- `git`
- `rgbds`

If `rgbds` is not available, you'll need to follow the [**rgbds** instructions](https://rgbds.gbdev.io/install/source) to build **rgbds 0.5.2** from source.

Now you're ready to the rom(s).


## Build Red++ v3

To download the source files:

```bash
git clone https://github.com/JustRegularLuna/rpp-backup
cd rpp-backup
```

To build **patches/rppred.gbc** and **patches/rppblue.gbc**:

```bash
make
```

`make` uses `rgbasm`, `rgblink`, `rgbfix`, and `rgbgfx` from your `PATH` unless you set `RGBDS`. The small helper programs in `tools/` are compiled locally using your system C compiler. You can override it when needed, for example with `make CC=gcc` or `make CC=clang`.

### Build with a local rgbds version

If you have different projects that require different versions of `rgbds`, it might not be convenient to install RGBDS 0.5.2 globally. Instead, keep RGBDS 0.5.2 in a separate directory, for example `rgbds-0.5.2/`, and specify that directory when you run `make`:

```bash
make RGBDS=rgbds-0.5.2/
```

All four RGBDS programs used by the build (`rgbasm`, `rgblink`, `rgbfix`, and `rgbgfx`) will then come from that directory, so they cannot accidentally mix with another RGBDS version installed in `PATH`.

A directory named `rgbds/` at the repository root is ignored by Git, so it can also be used for a private local installation:

```bash
make RGBDS=rgbds/
```

Do not copy `make`, `gcc`, or other system build tools into `rgbds/`; install those through your operating system or build environment instead.
