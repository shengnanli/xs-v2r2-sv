# LoadQueueRAR lane（agent/lqrar）—— 跑前登记

本文件在每个目标 **FM 起跑之前**提交对应分节；跑完在文末「对账」追加，
★不修改已提交分节的任何数字★。

## 0. 输入

| 项 | 值 |
|---|---|
| 基线 commit | `3992f2dd`（main，`git worktree add /home/eda/xs-env/wt-lqrar -b agent/lqrar main`） |
| 工作树 | `/home/eda/xs-env/wt-lqrar`，分支 `agent/lqrar` |
| golden | `/home/eda/xs-env/G1-canonical/golden-rtl`（只读） |
| 目标 | `LqPAddrModule`（child，叶子阵列）→ `LoadQueueRAR`（本体，golden 7,566 行） |
| child 状态（docs/coverage_three_axis.tsv 第 3 列） | `LqPAddrModule` UNPROVEN（本 lane 重写签核）；`FreeList_3` PROVEN_DIRECT（直接两侧白盒） |
| 口径 | 全部 `signoff-strict`，`FM_MERGE_DUP=false`（模型严格适用），allowlist 空，无 dont_verify |
| codex 冲突检查 | outbox 最近 20 条 codex 消息（0176..0195）与 15 个 `codex/*` 分支均未触及 LoadQueueRAR / LqPAddrModule / FreeList_3 |

## 1. LqPAddrModule

### 1.1 结构与子模块处置

- Chisel `LqPAddrModule`（基类 `LqRawDataModule`）：72 项 × 16 位折叠 paddr，3 写口（分 8 bank × 9 项、
  **numWDelay=1 ⇒ 0 级延迟，当拍写入**、Mux1H 按位或），CAM 两组：release ×1（只剩第 2 口）+
  releaseViolation ×3，规则都是 16 位全等。读口 / violation CAM / release 第 0、1 口被 firtool 消掉。
- 可读核 `xs_LqPAddrModule_core` 与 wrapper 同在 `rtl/memblock/LqPAddrModule.sv`；wrapper 在
  GENERATED(lqpaddr-wrapper) 区，由 `scripts/gen_lqrar.py` 生成（端口形状 fail-closed，`--check` 已登记 gate_all）。
- **不复用** `xs_LqRawDataCam_core`：那个核固化了 numWDelay=2 的带 clock/valid 延迟件与 violation CAM；
  改它要加模式参数并重证 LoadQueueRAW / LqMaskModule / LqPAddrModule_1 三个已签目标
  （`check_shared_impl_impact.py --file rtl/memblock/xs_LqRawDataCam_core.sv` 列出的影响面），读起来也更绕。
  与 LqVAddrModule 同样自成一个核。本 lane **没有改任何共享核**。
- 72 个 0 级延迟件（24 × {DelayN_225, DelayNWithValid_4, DelayNWithValid_7}，golden 里连 clock 都没有）
  全部 `PROVEN_DIRECT`，处置 = **两侧白盒**（ref golden 同名件，impl 本仓重写件）。无黑盒。

### 1.2 UT（verif/ut/LqPAddrModule；3 档 × 3 seed × 200k，commit 26d3d85c 的字节）

逐拍比全部 288 个输出口（release 72 + releaseViolation 3×72）；暖机 24 拍写满 72 项后才开始比。

| seed | `+vcs+initreg+0` | `+vcs+initreg+random` | `+vcs+initreg+<seed>017` |
|---|---|---|---|
| 1  | checks=199976 errors=0 PASSED | checks=199976 errors=0 PASSED（= 全 1 档） | 1017：checks=199976 errors=0 PASSED |
| 7  | checks=199976 errors=0 PASSED | checks=199976 errors=0 PASSED | 7017：checks=199976 errors=0 PASSED |
| 42 | checks=199976 errors=0 PASSED | checks=199976 errors=0 PASSED | 42017：checks=199976 errors=0 PASSED |

覆盖（seed 1）：写口撞地址 19886 拍、越界写地址 9905 拍、release CAM 有命中 189693 拍、
releaseViolation 有命中 568923 口·拍（其中多命中 568052）。
变异自证（scratchpad 独立 worktree，30k 拍，不进库）：P1 Mux1H 按位或→优先级 ⇒ errors=52252；
P2 violation CAM 忽略最高位 ⇒ errors=1；P3 越界写地址回绕进 bank ⇒ errors=81247。全部抓到。

复跑：`cd verif/ut/LqPAddrModule && make run SEED=<1|7|42> INITREG=<0|random|<seed>017>`

### 1.3 跑前预测（★跑完不许改本节★，登记见 docs/fm_predictions/LqPAddrModule.json）

| 目标 | passing 预测（模型 = golden 闭包寄存器位 + 顶层 output 位） | 其余 |
|---|---|---|
| LqPAddrModule | **1440**（1152 + 288；1152 = 72 × 16 条目；72 个延迟件都是 0 级、无寄存器） | failing 0 / unverified 0 / unmatched 全 0 / unread 0 / constant_reg 0 / 无黑盒 / SUCCEEDED |

无 vmucp、无 fm_pins、无 allow/dead_ref 声明。

### 1.4 明写可能出错的地方
1. 条目寄存器名 golden `data_<n>` ↔ impl `u_core/data_reg[<n>]` 靠 FM 自动名字配对（LqRawCam 32 项、
   LqVAddrModule 72 项同形已配上）；若出现 unmatched，先查配对再谈别的。
2. 本节没有做过任何 FM 试跑，数字纯按模型登记。

## 2. LoadQueueRAR（本体，golden 7,566 行 / 50 端口）

### 2.1 结构与子模块处置

- 可读核 `rtl/memblock/LoadQueueRAR.sv`：package loadqueuerar_pkg（常量、指针/总线类型、环形指针比较、
  `gen_partial_paddr` 折叠函数）+ xs_LoadQueueRAR_core（§1 入队 / §2 槽状态 / §3 出队与 revoke /
  §4 release 与 CAM / §5 违例检测 / §6 输出与 perf）+ golden 同名 wrapper。wrapper 与 CAM 例化在 GENERATED 区。
- 寄存器全部按字段 SoA 存（与 golden 扁平寄存器一一对应），结构体只用于组合逻辑与端口。
- golden 直接 child 2 实例 / 2 种全部白盒：LqPAddrModule（本 lane，§1）、FreeList_3（PROVEN_DIRECT，
  `rtl/memblock/FreeList.sv` 家族核 + `FreeList_3.sv`），以及 CAM 内部 72 个 0 级延迟件。无黑盒。
- FM「匹配前」钉点 `verif/ut/LoadQueueRAR/fm_pins_pre.tcl`（gen_lqrar.py 生成）：golden 顶层 736 个寄存器 /
  **1741 位**逐位 set_user_match 到核里的字段数组元素 / 标量；每个 golden 寄存器恰好命中一条映射规则、
  映射单射，否则生成失败；运行时逐条数返回值，拒一条或总数 != 1741 即 error。只消名差，不约束 ref。
  child 内部不钉。
- golden 怪癖照抄：release2Cycle.valid 实为 io.release.valid 打**两**拍（Chisel 对 RegEnable 寄存器的
  valid 字段二次连线）；release2Cycle.paddr 48 位全宽打拍只用 [47:6]；GatedRegNext 逐元素"不同才更新"。

### 2.2 UT（verif/ut/LoadQueueRAR；3 档 × 3 seed × 200k，commit 26d3d85c 的字节）

逐拍比全部 15 个输出信号（3×ready / 3×resp.valid / 3×rep_frm_fetch / lqFull / 2×perf）；
rep_frm_fetch_w 在 +random 档按"该流水首次 req.valid 之后"门控（ldLdViolationMask 不复位，见 tb 文件头）。
结果见 §对账 C（跑完追加，本节不写数字）。

变异自证（scratchpad 独立 worktree，30k 拍，seed 1，initreg 0）：
| 变异 | UT |
|---|---|
| R1 release2Cycle.valid 只打一拍（"修"掉怪癖） | errors=1522 抓到 |
| R2 released 多口写优先级反向 | **errors=0**（需要 FreeList 同拍把同一槽发给两口，tb 按构造产生不出来） |
| R3 revoke 不查 allocated | **errors=0**（对已释放槽 revoke 在可达状态里不出现） |
| R4 needFlush 忽略 level | errors=921 |
| R5 违例年龄比较反向 | errors=63009 |
| R6 release 命中不查 allocated | errors=3429 |
| R7 折叠 paddr 低位配对错位（paddr[15-i]→[14-i]） | **errors=0**（折叠函数对写/查/release 一致地改，只在撞键模式上有差，随机激励几乎打不到） |
| R8 released 入队初值漏掉 is_nc | errors=11049 |
| R9 出队条件 !isBefore → isAfter | errors=3161 |

UT 看不见的 R2 / R3 / R7 归 FM 兜底，预期 FM failing 落点见 §2.4；实测见 §对账 D。

### 2.3 跑前预测（★跑完不许改本节★，登记见 docs/fm_predictions/LoadQueueRAR.json）

模型：expected = **3806**（golden 闭包寄存器位 3784 + 顶层 output 位 22）；3784 = 顶层 1741 +
LqPAddrModule 1152 + FreeList_3 891。`FM_MERGE_DUP=false`，模型适用。

预期不进比较点的两类，**都是推理所得、本节登记时没有做过任何 FM 试跑**：
- **Constant reg 216**：FreeList_3 的 `freeSlotOH_next_nextVec_{0..3}_r`（4 × 72 位）。freeWidth=4 把 72 项
  分成 4 个 bank × 18 项，第 k 个释放口的 one-hot 只可能落在自己 bank 的 18 位里，其余 54 位恒 0 ⇒
  4 × 54 = 216 个常量寄存器，两侧对称（impl 的 xs_FreeList_core 同一结构）。
  依据：同家族 FreeList_4（32 项 / 4 bank × 8）在 LoadQueueRAW 里实测 constant_reg = 4 × 24 = 96，同一公式。
- **Unread 6**：`release2Cycle_bits_paddr[5:0]`（ref）↔ `u_core/release2Cycle_bits_paddr_reg[5:0]`（impl），
  matched_nc、两侧对称死位：RegEnable 了 48 位全宽 paddr，读者只有 `paddr[47:6]` 的 cacheline 比较。

计划：先按 vmucp 关做一次 **diagnostic-full**（不出 receipt）确认上述两类的点集合，
再加 `verif/fm_target_config/LoadQueueRAR.tcl`（vmucp 六条）后跑正式 signoff-strict、vmucp 开。

| 项 | 预测（vmucp 关，diagnostic） | 预测（正式 run_proof，vmucp 开） |
|---|---|---|
| passing | **3584**（= 3806 − 216 − 6） | **3590**（= 3806 − 216；正好 +6） |
| failing / unverified / aborted | 0 / 0 / 0 | 0 / 0 / 0 |
| unread_notcompared | 6 | 0 |
| unmatched | 0(0) | 0(0) |
| constant_reg | 216 | 216 |
| 黑盒 / dont_verify | 无 / 无 | 无 / 无 |
| verdict | strict PARTIAL（unread≠0） | SUCCEEDED |

`fm_predict check` 的对账口径：差额 216 应由 receipt 的 constant_reg=216 指认。

### 2.4 明写可能出错的地方
1. constant_reg 216 是按 FreeList_4 的实测外推的；若 FM 把更多 FreeList 内部位判成常量
   （例如 72 不是 2 的幂带来的指针高位），差额会大于 216 —— 那时逐点列出、不改本节数字。
2. 钉点名形状（`_reg\[i\]`、`_reg\[w\]\[i\]`、标量 `_reg`）若与 FM 实际命名不同会早退（error），不会静默。
3. R2 / R3 / R7 的 FM 覆盖：released_* / allocated_*（及 freeList 内 freeMask）/ paddrModule 的 data_* 都是
   passing 的 DFF 比较点，预期注入后 FM failing 恰好落在这些寄存器上。

## 对账（跑完追加，不改上文任何数字）
