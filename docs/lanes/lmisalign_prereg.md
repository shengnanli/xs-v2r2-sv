# LoadMisalignBuffer lane（agent/lmisalign）—— 跑前登记

本文件在每个目标 **FM 起跑之前**提交对应分节；跑完在文末「对账」追加，
★不修改已提交分节的任何数字★。

## 0. 输入

| 项 | 值 |
|---|---|
| 基线 commit | `3992f2dd`（main，`git worktree add /home/eda/xs-env/wt-lmisalign -b agent/lmisalign main`） |
| 工作树 | `/home/eda/xs-env/wt-lmisalign`，分支 `agent/lmisalign` |
| golden | `/home/eda/xs-env/G1-canonical/golden-rtl/LoadMisalignBuffer.sv`（只读，6203 行 / 877 端口 / 603 个 reg 共 5154 位） |
| Scala | `src/main/scala/xiangshan/mem/lsqueue/LoadMisalignBuffer.scala`（655 行） |
| 目标 | `LoadMisalignBuffer`（本体；**叶子**：golden 里没有任何子模块实例，§1 无 child 要签） |
| 口径 | `signoff-strict`，`FM_MERGE_DUP=false`（模型严格适用），无 dont_verify，无黑盒，无 fm_pins |
| codex 冲突检查 | outbox 最近 20 条 codex 消息与 15 个 `codex/*` 分支的 diff 均不含 misalign（0089 号只在 7 月的旧台账里列过名，非认领） |

## 1. LoadMisalignBuffer

### 1.1 结构

- `rtl/memblock/LoadMisalignBuffer.sv`：`loadmisalignbuffer_pkg`（状态编码、拆分方案表 `split_plan`、
  rdata 扩展函数）→ `xs_LoadMisalignBuffer_core`（§1 入队 / §2 状态机 / §3 拆分 / §4 发请求 / §5 收响应 /
  §6 拼接 / §7 写回，手写；§8 整包寄存器生成）→ golden 同名 wrapper（生成）。
- 生成器 `scripts/gen_lmisalign.py`（`--check` 已进 `gate_all.sh`）：接口 struct 字段 = golden 端口表；
  整包寄存器 req / splitLoadReqs_0/1 的字段集合 = golden 的 reg 声明（firtool DCE 的结果），
  寄存器名与 golden 逐个相同（在 `u_core` 下），**不需要 fm_pins**。fail-closed：golden 寄存器全集
  == 生成的整包寄存器 ∪ 核手写区同名声明（逐名、逐位宽）。
- 可读性：`_GEN_`/`_T_` = 0，`readability_audit.py` rc=0，文件带导航。

### 1.2 UT（verif/ut/LoadMisalignBuffer；3 seed × 3 initreg 档 × 200k）

tb 扮演 LoadUnit（激励 / 比对口径 / 覆盖判据见 `verif/ut/LoadMisalignBuffer/tb_template.py` 文件头），
逐拍比 golden 与 `_xs` 的全部 **258 个输出口**（2775 位）。初值档：`+vcs+initreg+0`（常量，从复位后第一拍比）、
`+vcs+initreg+random`（seed 1 退化成全 1 档）、`+vcs+initreg+<seed>017`（显式种子真随机）；后两档 req 不复位，
从第一次入队的下一拍起比。覆盖闸 20 项（6 状态 / 13 种跨 16B 拆分组合 / 不跨 16B 的 s_split / 子访问成功·replay·
异常·uncache·robIdx 不符 / 唤醒请求 / 三种写回 / 两种 flush / 入队 / 入队被本拍 redirect 拦下），任何一项 0 即 TEST FAILED。
读数见 §对账 C（跑完追加）。

复跑：`cd verif/ut/LoadMisalignBuffer && make run SEED=<1|7|42> INITREG=<0|random|<seed>017>`

### 1.3 跑前预测（★跑完不许改本节★；登记 docs/fm_predictions/LoadMisalignBuffer.json）

模型：expected = **7929**（golden 寄存器位 5154 + 顶层 output 位 2775），`FM_MERGE_DUP=false` 模型适用。
**本节写于任何 FM 运行之前**（含非正式试跑：0 次）。按 golden 结构逐项推：

**Constant reg（预测 267 位，两侧对称）** —— 只被写 0、复位也是 0 的寄存器，FM 常量折叠、不产生比较点：
- `splitLoadReqs_{0,1}_*` 中 Chisel 用 `WireInit(0.U.asTypeOf(new LsPipelineBundle))` 起头、拆分时从不赋值的字段：
  vaNeedExt 1 / paddr 48 / gpaddr 64 / nc / mmio / memBackTypeMM / isForVSnonLeafPTE / is128bit / vecActive（6×1）/
  mshrid 4 / schedIndex 7 / uop_exceptionVec_4 1（拆分时被清 0）/ uop_flushPipe 1（req 里没有这个字段）
  = 132 位 × 2 = 264；
- `highResultShift`（3 位）：拆分表里高半的右移恒 0。
- 风险（可能 +1）：`lowResultShift[2]` 的取值只有 0..3，第 2 位也是"复位 0、只写 0"，
  FM 若在位级识别出来会多 1 个 constant_reg（两侧同构，不影响判定）。

**matched-but-unread（预测 145 位，两侧对称死位）**：
- `REG`（1）：`RegNext(!req_valid)`，只喂 XSPerfAccumulate("alloc")，本配置无出口；
- `splitLoadReqs_{0,1}_uop_fuOpType[8:2]`（2×7=14）：发请求时标量只取子访问宽度 `[1:0]`、向量直接用 req 的 fuOpType；
- `splitLoadResp_{0,1}_data[128:64]`（2×65=130）：拼接只用低 64 位（`getShiftAndTruncateData` 取 `data(63, ...)`）。
  重写件照抄 golden 位宽（不收窄；收窄会变成 golden-only 死位）。

**vmucp 预案**：先跑一次 `FM_MODE=diagnostic-full`（不出 receipt）核对上面两组集合；若 unread 点集合**逐位等于**
上面 145 位且全部 matched_nc、两侧独占 0，则加 `verif/fm_target_config/LoadMisalignBuffer.tcl` + Makefile 开 vmucp，
六条证据写进该文件；若不等，先诊断，不开 vmucp。

| 项 | 预测（正式 run_proof，vmucp 开） |
|---|---|
| passing | **7662**（= 模型 7929 − constant_reg 267）；未开 vmucp 时 7517（再 −145） |
| failing / unverified / aborted / unread_notcompared | 0 / 0 / 0 / 0 |
| unmatched | 0(0) |
| constant_reg | 267（若 lowResultShift[2] 被识别则 268，passing 相应 7661） |
| 黑盒 | 无（叶子） |
| dont_verify / elab147 / relaxed_appvars | 皆空 |
| verdict | SUCCEEDED（signoff-strict） |

`fm_predict check` 的对账口径：差额 7929 − passing 应由 receipt 的 constant_reg 指认。

### 1.4 明写可能出错的地方

1. 端口 877 个、寄存器 603 个，全靠同名自动配对。重写件寄存器在 `u_core/` 下，`bufferState` 是 enum 类型；
   若出现 unmatched，先查配对（名字 / 位序），不先怀疑 RTL。
2. golden 的 `canEnqValid` / `flush` 用的是 robIdx 的 `flag ^ flag ^ (value > value)`（`>` 优先于 `^`），重写件写成
   `isAfter` 的同一式子；s_resp 的状态转移**不**核对 robIdx，而数据 / 指针 / 异常累计要核对 —— 这是 Chisel 原样，
   写反了 UT 会抓到（变异 M1 已验证，见 §对账 D）。
3. `split_plan` 表里 lb / 对齐的 lw、ld 三类"非法组合"在跨 16B 时结构上不可达（跨 16B 必不对齐），UT 打不到；
   其行为（地址 / 掩码 0、fuOpType 保持、四个移位宽度寄存器不写）只能由 FM 证等价。

### 1.5 正式证明前的补充登记（诊断跑之后；上面 §1.3 的数字不动）

诊断跑（commit `f2d5a5d2` 同字节，`FM_MODE=diagnostic-full FM_FAILING_LIMIT=0 make fm-LoadMisalignBuffer`，vmucp 关，不出正式 receipt）：
native SUCCEEDED，passing **7516** / failing 0 / unmatched 0(0)，Not Compared：Constant reg **268** + Unread **145**。
7929 − 7516 = 413 = 268 + 145，全部可指认：
- constant_reg 268 = §1.3 预测的 267 + 风险项 `lowResultShift[2]`（ref 标 DFF0X、impl 标 DFF0，两侧同一位）；
- unread 145 逐位等于 §1.3 预测的三组集合，全部 matched_nc、两侧独占 0。

据此按 standing rule 加 `verif/fm_target_config/LoadMisalignBuffer.tcl` + Makefile 开 vmucp。正式 run_proof 预测：

| 项 | 预测（正式 run_proof，vmucp 开） |
|---|---|
| passing | **7661**（= 7929 − 268 = 7516 + 145） |
| failing / unverified / aborted / unread_notcompared | 0 / 0 / 0 / 0 |
| unmatched | 0(0) |
| constant_reg | 268 |
| 黑盒 / dont_verify / elab147 / relaxed_appvars | 无 / 空 / 空 / 空 |
| verdict | SUCCEEDED（signoff-strict） |

## 对账（跑完追加，不改上文任何数字）

### A. LoadMisalignBuffer 正式证明（proof commit 5462ffc6，evidence/5462ffc60d9f/LoadMisalignBuffer/）
`bash scripts/run_proof.sh LoadMisalignBuffer LoadMisalignBuffer`（signoff-strict、vmucp 开、FM_MERGE_DUP=false）：
native **SUCCEEDED**，passing **7661** / failing 0 / unverified 0 / aborted 0 / unread_notcompared 0 / unmatched 0(0)，
constant_reg 268，dont_verify / elab147 / relaxed_appvars 皆空，黑盒 0，fm_target_config/LoadMisalignBuffer.tcl 在 script_closure 里。
receipt.json sha256 `c597c5c24d9b1b0ea0b1128f4619ad2320a248082e814e56971f89192db5813e`；
impl_closure `rtl/memblock/LoadMisalignBuffer.sv` sha256 `fca42b83…77dcb1b9`（= 提交字节）。

| 项 | §1.3 预测（跑前） | §1.5 预测（诊断后） | 实测 | 差额指认 |
|---|---|---|---|---|
| passing | 7662 | 7661 | 7661 | §1.3 差 −1 = `lowResultShift[2]` 被 FM 识别为常量（§1.3 已列为 +1 风险项） |
| constant_reg | 267（+1 风险） | 268 | 268 | 同上 |
| unread（vmucp 前） | 145 | 145 | 145（诊断跑）→ 0（正式） | 三组集合逐位命中 |
| failing / unmatched | 0 / 0 | 0 / 0 | 0 / 0 | — |

`python3 scripts/fm_predict.py check LoadMisalignBuffer` rc=0：模型 7929 − 实测 7661 = 268 = receipt constant_reg 268。

### C. LoadMisalignBuffer UT（在 48542675 的字节上跑；48542675..5462ffc6 之间 rtl/ 与 tb 无改动）
| seed | `+vcs+initreg+0` | `+vcs+initreg+random` | `+vcs+initreg+<seed>017` |
|---|---|---|---|
| 1  | checks=200000 errors=0 PASSED | checks=199999 errors=0 PASSED（= 全 1 档） | 1017：checks=199999 errors=0 PASSED |
| 7  | checks=200000 errors=0 PASSED | checks=199998 errors=0 PASSED | 7017：checks=199998 errors=0 PASSED |
| 42 | checks=200000 errors=0 PASSED | checks=199998 errors=0 PASSED | 42017：checks=199998 errors=0 PASSED |

9 轮 cover_holes 全 0。覆盖读数（seed 1 / initreg 0）：状态 idle 34555 / split 9092 / req 20844 / resp 47195 /
comb 6824 / wb 81490；跨 16B 拆分 H 2170、W/01 841、W/10 873、W/11 780、D/001..111 = 186 173 185 209 233 221 260；
不跨 16B 进 s_split 2961；响应 成功 10550 / replay 1834 / 异常 1744 / uncache 916 / robIdx 不符 4104；
唤醒请求 fire 3860；写回 标量正常 3066 / 标量异常 1860 / 向量 2319；flush 空闲 122 / 非空闲 1942；入队 9214 / 入队被 redirect 拦 140。
（random / <seed>017 档从第一次入队下一拍起比，所以 checks 比 200000 少 1~2。）

### D. 变异自检（scratchpad，不进库；UT：seed1/initreg0 与 seed7/initreg7017 各 20k 拍）
16 个变异，UT 抓到 13 个（M1 resp 不核对 robIdx、M2 isFinalSplit 不看唤醒、M3 跨 16B 判错位、M4 拆分表 D/011 宽度、
M5 写回异常不门控、M6 fp lh 不做 NaN-boxing、M8 flush 不清 MMIO 标志、M9 replay 也推进指针、M10 入队优先级、
M11 向量 fuOpType 取错源、M12 拼接不回绕、M13 写回不让路 loadOutValid、M14 异常不看 vecActive，errors 21..1455306）。
UT 结构上看不见的 3 个，全部由 FM 覆盖（scratch detached worktree @5462ffc6，diagnostic-full、FAILING_LIMIT=0，不出 receipt）：

| 变异 | UT | FM |
|---|---|---|
| M7 uncache 时不清其它累计异常位（s_resp 里 exceptionVec 结构上恒 0，UT 造不出差异） | errors=0 | **FAILED failing 5**（不截断）= exceptionVec_{3,5,13,19,21} |
| M15 给 req_uop_pc 加异步复位（复位域；req 在首次入队前不比） | errors=0 | **FAILED failing 50** = req_uop_pc[49:0] |
| M16 去掉 data_select 的复位（复位域；首次入队前不比） | errors=0 | **FAILED failing 9** = data_select[8:0] |
