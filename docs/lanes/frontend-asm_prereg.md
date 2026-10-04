# frontend-asm lane（agent/frontend-asm）—— 跑前登记

本文件在每个目标 **FM 起跑之前**提交对应分节；跑完在文末「对账」追加，★不修改已提交分节的任何数字★。

## 0. 输入

| 项 | 值 |
|---|---|
| 基线 commit | `3a1acb92`（main 8200177b + 认领），工作树 `/home/eda/xs-env/wt-frontend-asm`，分支 `agent/frontend-asm` |
| golden | `/home/eda/xs-env/G1-canonical/golden-rtl`（只读） |
| 目标 | ICacheBuffer / InstrUncacheBuffer / ICacheCtrlBuffer / MuxBundle（叶）、FDPrefetcherMonitor（NO_OUTPUT）、Frontend（本体） |
| 口径 | `signoff-strict`，`FM_MERGE_DUP=false`（模型严格适用），allowlist 空，无 dont_verify |

冲突检查（2026-10-04）：codex outbox 最新 0210（ram_78x15 / Queue40）、0209、0208 均不涉及本 lane 目标与其 child；
全部 worktree 的 `docs/lanes/*_claim.md|*_prereg.md` 里本 lane 6 个模块名只出现在 dcache 系 prereg 的
FDPrefetcherMonitor 处置说明（§3）与本 lane 认领文件；Frontend 的 child PFEvent / HPerfMonitor 属
backend-misc lane，已合入 main 并已签（evidence/6038c4afbc60）。

## 1. FrontendBridge 三个 TL 两级缓冲（ICacheBuffer / InstrUncacheBuffer / ICacheCtrlBuffer）

### 1.1 结构与子模块处置

- Scala `mem/MemBlock.scala`：FrontendBridge 里三个 `TLBufferNode`，A/D 两通道各套两层 `BufferParams.default`
  （= `Queue(2, pipe=false, flow=false)`），首尾相接。InstrUncacheBuffer 在缓冲之后把 opcode/size/source/mask/data
  重新钉成常量（端口被 firtool 删掉）；ICacheBuffer / InstrUncacheBuffer 的 D 口恒接收（第二级 deq_ready=1）。
- 重写件：`rtl/memblock/{ICacheBuffer,InstrUncacheBuffer,ICacheCtrlBuffer}.sv`（手写，无核：本层只有 4 个队列的首尾连接
  与入口常量；入口常量用具名 localparam 讲清含义）。golden 行数 257 / 245 / 243，impl 220 / 205 / 222，`_GEN_`/`_T_` 均 0。
- child：Queue2_TLBundleA_8/D_7、A_12/D_13、A_10/D_11 —— 全部已签（evidence/1fda02fae0f1，receipt impl 闭包与当前字节一致）。
  处置 = **两侧白盒**：ref golden Queue2_*，impl 重写件 `rtl/uncore/Queue2_*.sv` + 共享核 `rtl/common/xs_ChiselQueue_core.sv`；
  `ram_2xN` 是 golden 行为级叶子，两侧同源 inline（同 verif/ut/UncoreTLQueues，codex 0151 D60）。无黑盒。

### 1.2 UT（verif/ut/FrontendBridgeBuffers；tb 由 gen.py → scripts/gen_l2slice_ut.py 生成，`make gencheck` 幂等）

三个目标同一 tb 各自双例化（golden `<T>` vs 派生 `<T>_xs`），逐拍 4 态比全部输出；ram 不复位，首沿前把 golden
各 Queue2 的 Memory 抄给重写侧。出口 ready 每 2000 拍在快出(75%)/慢出(25%)间切换。

| seed | `+vcs+initreg+0` | `+vcs+initreg+random` | `+vcs+initreg+<seed>017` |
|---|---|---|---|
| 1  | checks=10000000 errors=0 PASSED | checks=10000000 errors=0 PASSED | checks=10000000 errors=0 PASSED |
| 7  | checks=10000000 errors=0 PASSED | checks=10000000 errors=0 PASSED | checks=10000000 errors=0 PASSED |
| 42 | checks=10000000 errors=0 PASSED | checks=10000000 errors=0 PASSED | checks=10000000 errors=0 PASSED |

（checks = 200k 拍 × 50 个输出端口。seed 1 × random 实为全 1 档，见 CONVENTIONS。）
覆盖（seed 7 random）：12 个 Queue2 每个 进队 / 出队 均 7.2 万 ~ 10 万拍；有 ready 的链"满且被挡"
2.7 万 ~ 7.0 万拍；翻转 20/20、12/12、18/18。D 口恒接收的两条 D 链"满"结构不可达（golden 同），不设满闸。
判据自证（scratchpad 变异，不进库，seed 7 random）：M1 reqSource 1→2 ⇒ errors=199998；M2 ICacheBuffer D 第二级
deq_ready 1→d_mid_valid ⇒ 525434；M3 InstrUncacheBuffer 第二级 NC/MM 位对调 ⇒ 100391；M4 ICacheCtrlBuffer D 入口
sink 0→opcode[0] ⇒ 100084；M5 ICacheCtrlBuffer D 第二级 deq_ready 换成 1 ⇒ 555054。5/5 抓到。

复跑：`cd verif/ut/FrontendBridgeBuffers && make run SEED=<1|7|42> INITREG=<0|random|<seed>017>`

### 1.3 试跑（diagnostic-full，vmucp 关，efac4c05 字节，不产 receipt）

| 目标 | native | passing | unread（全 matched_nc，两侧同路径） | constant_reg | failing / unmatched | 模型 |
|---|---|---|---|---|---|---|
| ICacheBuffer       | SUCCEEDED | 2844 | 52  | 307 | 0 / 0 | 3203 = 2844+52+307 |
| InstrUncacheBuffer | SUCCEEDED | 612  | 277 | 83  | 0 / 0 | 972 = 612+277+83 |
| ICacheCtrlBuffer   | SUCCEEDED | 976  | 16  | 5   | 0 / 0 | 997 = 976+16+5 |

unread 全是 Queue2 ram 里"写入但出口无人读"的字段位（D 的 param/sink、A 的 param/corrupt、InstrUncacheBuffer 第二级
被 Scala 钉常量的字段），两侧逐字同路径 → 按 vmucp standing rule 六条开 vmucp（`verif/fm_target_config/<T>.tcl`）。

### 1.4 跑前预测（★跑完不许改本节★，登记 docs/fm_predictions/<T>.json）

| 目标 | 模型（寄存器位 + 输出位） | passing 预测（vmucp 开） | 差额指认 | 其余 |
|---|---|---|---|---|
| ICacheBuffer       | 3203（2572 + 631） | **2896** = 2844 + 52 | constant_reg 307 | failing/unverified/unmatched/unread 全 0，无黑盒，SUCCEEDED |
| InstrUncacheBuffer | 972（848 + 124）   | **889** = 612 + 277  | constant_reg 83  | 同上 |
| ICacheCtrlBuffer   | 997（800 + 197）   | **992** = 976 + 16   | constant_reg 5   | 同上 |

可能出错的地方：vmucp 打开后若部分 unread 点被 FM 改判为常量，passing 会少于预测、constant_reg 等量增加（差额仍可指认）；
若 passing 不增，即 vmucp 空转，判红。

## 2. MuxBundle（rtl/frontend/MuxBundle.sv 已有重写件，补 receipt）

### 2.1 现状与原因

- 重写件 93a518eb 起就在（参数化核 xs_MuxBundle_core + golden 同名 wrapper），d2b3624d 修过 ELAB-147。
  `docs/fm_round_20260914.tsv` 有一轮 SUCCEEDED（passing 71），但那是 receipt 体系之前的结果；
  `docs/receipt_harvest.tsv` 里唯一一份（wt-err3:d2b3624d2fcd）标 SUPERSEDED，evidence/ 下没有任何 MuxBundle receipt
  → 轴二无 PROVEN_DIRECT。没有任何人在新体系下给它出过证。（`coverage_three_axis.tsv` 轴一写 GOLDEN_REUSE 是
  `golden_reuse_set()` 按 basename 收集 RTL_GOLDEN_DEPS 的副作用：ICacheMissUnit / ICache 的 Makefile 把**仓内**
  rtl/frontend/MuxBundle.sv 放进了 RTL_GOLDEN_DEPS；那是派生表，本 lane 不改。）
- 本 lane 只改 `verif/ut/MuxBundle/Makefile`：补 initreg 三档口径、`FM_MERGE_DUP=false`（0 寄存器，不改比较点，只让模型严格适用）、
  `PORTLINT_ORDER=fail`。RTL 不动。golden 230 行，impl 202 行，`_GEN_`/`_T_` 0。

### 2.2 UT（verif/ut/MuxBundle）

| seed | `+vcs+initreg+0` | `+vcs+initreg+random` | `+vcs+initreg+<seed>017` |
|---|---|---|---|
| 1  | checks=200000 errors=0 PASSED | checks=200000 errors=0 PASSED | checks=200000 errors=0 PASSED |
| 7  | checks=200000 errors=0 PASSED | checks=200000 errors=0 PASSED | checks=200000 errors=0 PASSED |
| 42 | checks=200000 errors=0 PASSED | checks=200000 errors=0 PASSED | checks=200000 errors=0 PASSED |

覆盖（seed 7）：sel 0..9 各 1.58 万 ~ 1.66 万次，越界 37456，out_ready=0 99744，选中路 valid=1/0 100268/99732，70 位载荷全翻转。
`make negtest` PASSED（source 基址抄错运行期 $fatal）。变异：MB1 sel==1 落到第 0 路 ⇒ errors=15877；MB2 in_ready 不看 out_ready ⇒ 73062。

### 2.3 跑前预测

| 目标 | 模型 | passing 预测 | 其余 |
|---|---|---|---|
| MuxBundle | 71（0 + 71） | **71** | 0 寄存器；failing/unmatched/unread 0；无 vmucp、无钉点、无黑盒；SUCCEEDED |

## 3. FDPrefetcherMonitor（NO_OUTPUT，按 dcache_prereg §1.4 先例，不跑 FM）

- golden（111 行）在本配置 0 输出 0 寄存器（`io.pf_ctrl := DontCare`，计数器只供 XSPerf，firtool 全删），体内只剩 3 条无人读的
  PopCount。重写件 `rtl/memblock/FDPrefetcherMonitor.sv`（52 行）：逐位一致的 10 个输入端口 + 同形 3 条无观察者加法
  （1998a657b dcachebody 补上，理由：空模块会被 FM 当黑盒，父级 DCache 多出 impl 侧黑盒）。代码区 `_GEN_`/`_T_` 0。
- 现状核对（本 lane）：当前字节 sha256 `8a144954837b7e4e3ac3eb9280753333bd9f3634a1735f75f421ed0a4302c015`；
  绑定它的 receipt：DCache（evidence/0dc9c4532cf5、68d1a0932a12、ce9d0692bc8e、f009d7b3c6d1，SUCCEEDED）与 DCacheLeaves 四件
  （evidence/4464d4e059b0）全部与当前字节一致；evidence/414ed06a79c5 下五份是 PopCount 补行之前的旧字节（已被 4464d4e0 重证取代）。
  端口契约 `make -C verif/ut/DCacheLeaves portlint-fdp`。
- 处置：照先例**不列 FM_VARIANTS、不出 receipt**；形式上无比较点（与 StorePipe 同类），正确性由端口契约 + 父级 DCache 闭包证明承担。
  本 lane 不需要新裁定。
