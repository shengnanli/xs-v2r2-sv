# LoadQueueRAW lane（agent/lqraw）—— 跑前登记

本文件在每个目标 **FM 起跑之前**提交对应分节；跑完在文末「对账」追加，
★不修改已提交分节的任何数字★。

## 0. 输入

| 项 | 值 |
|---|---|
| 基线 commit | `975b64e6`（main，`git worktree add /home/eda/xs-env/wt-lqraw -b agent/lqraw 975b64e6`） |
| 工作树 | `/home/eda/xs-env/wt-lqraw`，分支 `agent/lqraw` |
| golden | `/home/eda/xs-env/G1-canonical/golden-rtl`（只读） |
| 目标 | `LqMaskModule` / `LqPAddrModule_1`（child，叶子阵列）→ `LoadQueueRAW`（本体） |
| 口径 | 全部 `signoff-strict`，`FM_MERGE_DUP=false`（模型严格适用），allowlist 空，无 dont_verify |

## 1. LqMaskModule / LqPAddrModule_1（共用核 xs_LqRawDataCam_core）

### 1.1 结构与子模块处置

- 两者都是 Chisel `LqRawDataModule` 基类的子类：32 项 × {16 位掩码 / 24 位部分 paddr}，
  3 写口（分 8 bank、打 1 拍写入、Mux1H 按位或）+ 2 个 violation CAM 口。golden 的读口与
  release CAM 已被 firtool 消掉（父级没接）。可读核 `rtl/memblock/xs_LqRawDataCam_core.sv`
  参数化 DATA_W 与 CAM 规则（LINE_CAM）；两个薄 wrapper 由 `scripts/gen_lqraw.py` 生成（带 `--check`，已登记 gate_all）。
- 每个 wrapper 72 个延迟件（24 × {DelayN_13, DelayNWithValid_52, DelayNWithValid_103 或 _55}）。
  查 `docs/coverage_three_axis.tsv`：四者全部 `PROVEN_DIRECT`。处置 = **两侧白盒**：
  ref 用 golden 同名件，impl 用本仓重写件（`rtl/common/DelayN_13.sv` 等 + `xs_DelayN_core` / `xs_DelayNWithValid_core`）。
  无黑盒。

### 1.2 UT（verif/ut/LqRawCam，两对同测；两档 × 3 seed × 200k）

逐拍比两模块全部 128 个输出口（2×32 位命中向量 × 2 模块）；暖机 32 拍写满 32 项后才开始比。

| seed | `+vcs+initreg+0` | `+vcs+initreg+random` |
|---|---|---|
| 1  | checks=199968 errors=0 PASSED | checks=199968 errors=0 PASSED |
| 7  | checks=199968 errors=0 PASSED | checks=199968 errors=0 PASSED |
| 42 | checks=199968 errors=0 PASSED | checks=199968 errors=0 PASSED |

覆盖（seed 1）：写口撞地址 20167 拍、掩码 CAM 命中 359827、地址 CAM 命中 324827、其中 checkLine=1 命中 119726。
判据自证（scratchpad 变异，不进库）：M1 把 checkLine 的"或"改"与" ⇒ errors=32368；
M2 把 Mux1H 按位或改优先级 ⇒ errors=21121（各 20k 拍）。

复跑：`cd verif/ut/LqRawCam && make run SEED=<1|7|42> INITREG=<0|random>`

### 1.3 跑前预测（★跑完不许改本节★，登记见 docs/fm_predictions/*.json）

| 目标 | passing 预测（模型 = golden 闭包寄存器位 + 顶层 output 位） | 其余 |
|---|---|---|
| LqMaskModule    | **1080**（1016 + 64；1016 = 32×16 条目 + 24×(4+1+16) 延迟件） | failing 0 / unverified 0 / unmatched 全 0 / unread 0 / 无黑盒 / SUCCEEDED |
| LqPAddrModule_1 | **1528**（1464 + 64；1464 = 32×24 条目 + 24×(4+1+24) 延迟件） | 同上 |

无 vmucp、无 fm_pins、无 allow/dead_ref 声明。

### 1.4 明写可能出错的地方

1. 两侧延迟件实例路径名不同（golden 扁平 `sx_*_<3b+w>`，impl `u_core/g_bank[b].g_wport[w].*`），
   靠 FM 的名字/签名匹配配对。LqVAddrModule（同一套基类、同样的 generate 命名）已签过，
   预期同样配得上；若出现 unmatched，先查配对再谈别的。
2. 写数据延迟件同一写口 8 份逐位恒等：已关 merge_dup，预期不合并、每份各一个比较点。
   若 passing 少了恰好 21×DATA_W 的倍数，就是合并/配对问题而不是 RTL 问题。
3. 本节没有做过任何 FM 试跑（非正式试跑也没有），数字纯按模型登记。
