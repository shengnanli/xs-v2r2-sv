# wbbyp lane B 部分（agent/wbbyp-b）—— 跑前登记

本文件在每个目标 **FM 起跑之前**提交对应分节；跑完在文末「对账」追加，
★不修改已提交分节的任何数字★。A 部分（WbDataPath 一族）在 agent/wbbyp，另有登记。

## 0. 输入

| 项 | 值 |
|---|---|
| 基线 commit | `4728f823`（main，`git worktree add /home/eda/xs-env/wt-wbbyp2 -b agent/wbbyp-b main`） |
| 工作树 | `/home/eda/xs-env/wt-wbbyp2`，分支 `agent/wbbyp-b` |
| golden | `/home/eda/xs-env/G1-canonical/golden-rtl`（只读） |
| 目标 | `ImmExtractor_2` / `ImmExtractor_37`（child）→ `BypassNetwork`（本体） |
| 口径 | 全部 `signoff-strict`，`FM_MERGE_DUP=false`，allowlist 空，无 dont_verify |

## 1. ImmExtractor_2 / ImmExtractor_37

### 1.1 结构

- 共享核 `xs_imm_extractor_core`（`rtl/backend/ImmExtractor.sv`，已签的 ImmExtractor / ImmExtractor_12 同核）**不改**，
  只新加两个薄 wrapper：
  - `ImmExtractor_2`：DATA_BITS=64，TYPE_EN=0x001E（SB/U/UJ/I，与 golden 四个分支一一对应）。
  - `ImmExtractor_37`：DATA_BITS=128，TYPE_EN=0x3000（VSETVLI/VSETIVLI；高 64 位恒 0）。
- 纯组合，无子模块、无寄存器、无黑盒。共享核字节未动 ⇒ 不触发 check_shared_impl_impact 重证。

### 1.2 UT（verif/ut/ImmExtractorBypass，两变体同测，3 seed × 3 档 × 200k）

逐拍比两个输出；每拍 85% 从 13 种合法类型抽、15% 全随机 4 位（含非法码），imm 混边界值。

| seed | `+vcs+initreg+0` | `+vcs+initreg+random` | `+vcs+initreg+<seed>017` |
|---|---|---|---|
| 1  | checks=400000 errors=0 | checks=400000 errors=0 | checks=400000 errors=0 |
| 7  | checks=400000 errors=0 | checks=400000 errors=0 | checks=400000 errors=0 |
| 42 | checks=400000 errors=0 | checks=400000 errors=0 | checks=400000 errors=0 |

覆盖（seed 1，每种使能类型产生非零输出的拍数；任一为 0 即判失败）：
ImmExtractor_2 SB=7530 U=11307 UJ=11052 I=7366；ImmExtractor_37 VSETVLI=5453 VSETIVLI=9367。
（纯组合，三档 initreg 结果逐字相同，符合"无隐藏状态"。）

变异自检（scratchpad 手改、跑完复原）：M1 `_2` 去掉 I 型（TYPE_EN 0x000E）⇒ errors=7366；
M3 `_37` 去掉 VSETVLI（0x2000）⇒ errors=12819。M2（`_37` DATA_BITS 改 64）编译被端口契约闸拦下（未进仿真）。

复跑：`cd verif/ut/ImmExtractorBypass && make run SEED=<1|7|42> INITREG=<0|random|<seed>017>`

### 1.3 跑前预测（★跑完不许改本节★，登记见 docs/fm_predictions/ImmExtractor_{2,37}.json）

| 目标 | passing 预测（模型 = 寄存器位 0 + 顶层 output 位） | 其余 |
|---|---|---|
| ImmExtractor_2  | **64**  | failing 0 / unverified 0 / unmatched 0 / unread 0 / 无黑盒 / SUCCEEDED |
| ImmExtractor_37 | **128** | 同上（高 64 位是常量 0 输出，仍按输出比较点计） |

无 vmucp、无 fm_pins、无 allow/dead_ref 声明。本节未做任何 FM 试跑。

## 2. BypassNetwork（本体，golden 5,503 行 / 2,110 端口：1,137 入 / 973 出）

### 2.1 结构与子模块处置

- 可读核 `xs_BypassNetwork_core`（`rtl/backend/BypassNetwork.sv`，手写 146 行）：§1 旁路源 forward/bypass 两份数据
  （bypass = RegEnable(valid)，无复位）；§2 每 EXU：立即数还原 + 逐源按 dataSources 码 `unique case` 选择
  （码互斥，与 golden 的 Mux1H 按位或等价）+ BJU 的 imm/nextPcOffset；§3 RegCache 写口（wen 异步复位）。
- 每-EXU 配置表 `EXU_CFG`（27 行）与 wrapper 由 `scripts/gen_bypassnetwork.py` 从 G1 golden 解析生成（`--check` 已进 gate_all）：
  逐个解析 71 个 `io_toExus_*_bits_src_*` 的展开式，每一项归类并要求同一 EXU 服从同一行配置；旁路组的位置集合、
  one-hot 来源于本源 exuSources、bypass 寄存器与 RegCache wen 寄存器原文、855 条直连与 27 条 ready 反向直连全部逐条核对。
- 子模块：ImmExtractor/_2/_12/_37/_57 两侧白盒（impl 用本仓重写件：_2/_37 本 lane §1，余在 main 已签）。
  golden 的 36 个 UIntExtractor_27_*（exuSources→27 位 one-hot 展开件）在 impl 侧不例化——核直接按序号从旁路组取数
  （`pick_int`/`pick_fp`，序号 0 给 0），两侧均为纯组合，FM 在展平后比较。golden 每个源各例化一份 ImmExtractor
  （输入相同），impl 每个 EXU 一份。无黑盒。
- 寄存器：golden 711 位（bypassDataVec_r* 9×64 + 1×128，bypassIntWenVec_last_REG* 7×1）；
  impl 647 位（byp_data 10×64 + rcw_wen 7）。差的 64 位 = fp0 旁路寄存器 [127:64]，golden 写而无读者，见 2.4。

### 2.2 UT（verif/ut/BypassNetwork，tb 由生成器产出；3 seed × 3 档 × 200k 拍，比全部 973 个输出口）

| seed | `+vcs+initreg+0` | `+vcs+initreg+random` | `+vcs+initreg+<seed>017` |
|---|---|---|---|
| 1  | checks=194596108 errors=0 | checks=194596108 errors=0 | checks=194596108 errors=0 |
| 7  | checks=194596108 errors=0 | checks=194596108 errors=0 | checks=194596108 errors=0 |
| 42 | checks=194596108 errors=0 | checks=194596108 errors=0 | checks=194596108 errors=0 |

覆盖（seed 1，命中且 golden 输出非零的源操作数拍数；任一为 0 判失败）：fwd_int=440998 byp_int=439307 fwd_fp=213878
byp_fp=212514 v0=50857 rc=502400 imm=109461 loadu=65967 jalr=149952 nojalr=450036 rcw_wen=348969。
暖机 4 拍所有旁路源 valid=1，使两侧不复位的 bypass 寄存器同值后再开始比（双例化 initreg random 各摇各的）。
UT 跑在 7ac0102c 的 RTL 上（其后对 BypassNetwork.sv 只加了"本文件导航"注释 11 行，逻辑字节未变）。

变异自检（seed 1、20k 拍，改完 git checkout 复原）：8/8 抓到——
M1 整数组序号差一 88231；M2 bypass 寄存器去掉 valid 使能 102928；M3 v0 取未选的原始 src3 40889；
M4 JALR 判定丢 is_jump 14021；M5 RegCache wen 丢 intWen 34819；M6 nextPcOffset 的 RVC 1/2 对调 59988；
M7 load U 型立即数改零扩展 3280；M8 浮点组恒取第 0 路 28672。

复跑：`cd verif/ut/BypassNetwork && make run SEED=<1|7|42> INITREG=<0|random|<seed>017>`

### 2.3 跑前预测（★跑完不许改本节★，docs/fm_predictions/BypassNetwork.json）

| 项 | 预测 |
|---|---|
| 模型 expected | 27783 = 寄存器 711 + 输出 27072 |
| passing 实测预测 | **27719**（= 27783 − 64，差额全部由 golden-only unread 指认） |
| failing / unverified / aborted | 0 / 0 / 0 |
| unmatched（ref/impl） | 0 / 0 |
| unread | ref 64（bypassDataVec_r_8_reg[127:64]）、impl 0、matched_nc 0 |
| 黑盒 / dont_verify | 无 / 无 |
| 判决 | **PASS_DEAD_REF**（native SUCCEEDED） |

### 2.4 PASS_DEAD_REF 声明（跑前写定）

`verif/dead_ref/BypassNetwork.json`：64 条 `r:/WORK/BypassNetwork/bypassDataVec_r_8_reg[64..127]`。理由：golden 把 fp_0_0 的
128 位结果全宽锁存，但 13 个读点全是 `[63:0]` 切片，fp0 也不是 RegCache 写口源；impl 按 64 位存。
声明在证明之前由分析写出（不是抄观测）；若实测集合与之有任何出入，判决退 PARTIAL，我照实记录，不改声明去凑。

### 2.5 明写可能出错的地方

1. 寄存器名差（golden `bypassDataVec_r_<pos>` vs impl `u_core/byp_data_reg[p][b]`）：只有 17 个寄存器、各自独立使能，
   预期签名分析能配上，**不预置 fm_pins**；若出现 unmatched，先补 fail-closed 钉点再重跑，并在对账里写明。
2. 本节没有做过任何 FM 试跑。

## 3. BypassNetwork 第一次起跑失败（ERROR，未产生比较数字）与修正

- 第一跑（commit bf6e2d48，evidence/bf6e2d485f03/BypassNetwork）：FM 在 elaborate 阶段报 FMR_ELAB-147 ×2 并拒绝设 top
  （make_rc=3，verdict=ERROR，无 passing/failing 数字）。原因：`pick_int`/`pick_fp` 写成 `d[INT_GRP[v-1]]`，v=0 时下标越界
  （虽然被 `v==0 ? 0 :` 守卫）。按 CONVENTIONS「ELAB 硬约束」只改 RTL：改为逐个比较序号 `if (v == k+1) r = d[GRP[k]]`，
  下标全为常量。功能不变（v=0 给 0，v=k+1 取第 k 路）。不压消息、不改 appvar。
- 修正后 UT 重跑整张 3×3 矩阵（结果在对账节）；本节不改 2.3 的任何预测数字。
- 第二跑（commit 876a9668，evidence/876a9668*/BypassNetwork）：native FAILED——failing 至少 20（截断）、unverified 3307、
  unmatched 128(128)、unread 64。unmatched 为 impl `byp_data_reg[1]`/`[3]` 与 ref `bypassDataVec_r_12`/`_21` 各 64 位，
  20 个 failing 全在 `u_core/byp_data_reg[2][*]` —— 签名分析把旁路寄存器配错了对。按 2.5 第 1 条预案：生成器新增
  fail-closed 钉点 `verif/ut/BypassNetwork/fm_pins_pre.tcl`（647 条 = 10×64 旁路寄存器 + 7 个 RegCache wen，双射、
  逐条数返回值、字面总数），只消名差。RTL 未改。若钉后仍有 failing，按失配处理（改 RTL 对齐 golden），不找解释。

## 对账（跑后追加；上面各节数字未改）

### ImmExtractor_2 / ImmExtractor_37（commit 2f3f8902，evidence/2f3f8902e695/）

| 目标 | 预测 passing | 实测 | 差 | failing | unverified | unmatched | unread | 黑盒 | dont_verify | 判决 |
|---|---|---|---|---|---|---|---|---|---|---|
| ImmExtractor_2  | 64  | 64  | 0 | 0 | 0 | 0(0) | 0 | 无 | 无 | SUCCEEDED |
| ImmExtractor_37 | 128 | 128 | 0 | 0 | 0 | 0(0) | 0 | 无 | 无 | SUCCEEDED |

### BypassNetwork（第三跑 commit ccf7f50a，evidence/ccf7f50a4e5a/BypassNetwork）

| 项 | 预测（2.3） | 实测 |
|---|---|---|
| passing | 27719 | **27719** |
| failing / unverified / aborted | 0 / 0 / 0 | 0 / 0 / 0 |
| unmatched ref/impl | 0 / 0 | 0 / 0 |
| unread | ref 64 / impl 0 / matched_nc 0 | ref 64 / impl 0 / matched_nc 0（与 verif/dead_ref/BypassNetwork.json 逐条相等） |
| 黑盒 / dont_verify / ELAB-147 | 无 | 无 |
| 钉点 | （未预置） | 647/647，bad=0 |
| 判决 | PASS_DEAD_REF | **PASS_DEAD_REF**（native SUCCEEDED） |

fm_predict check：模型 27783 − 实测 27719 = 64 = constant_reg 0 + unread 64，差额全部指认。
与预测的偏离只有一处：2.5 第 1 条押"不钉也能配上"押错了（第二跑配错对，见 §3），补了钉点；passing 数字不受影响。

更正（事实性，不是预测）：2 节标题的端口数写错了。实测 golden 端口 2,108 个：1,135 入（含 clock/reset）/ 973 出。

### BypassNetwork UT 重跑（修 ELAB-147 之后，RTL = 876a9668 起未再变）

9 档全部 checks=194596108 errors=0（seed 1/7/42 × initreg 0 / random / <seed>017）；覆盖计数与修正前逐字相同
（seed 1：fwd_int=440998 byp_int=439307 fwd_fp=213878 byp_fp=212514 v0=50857 rc=502400 imm=109461 loadu=65967
jalr=149952 nojalr=450036 rcw_wen=348969）。修正后补测变异 M1'（序号比较差一）errors=100734。
