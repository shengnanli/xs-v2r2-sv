# Backend BT —— 块级（整 Backend 子系统）验证

> 照 `verif/bt/Frontend/` 样板 + `verif/it/README.md` 方法学。
> golden `Backend` (u_g) vs 部分重写装配 `Backend_bt` (u_i)，双例化逐拍比对 723 个 Backend 顶层功能输出。

---

## 1. 覆盖范围（诚实）

本 BT **不是**整 Backend 45 子模块全重写直连。原因（结构性，非偷懒）：

工程里的重写 Backend 核被设计成 **与 golden 同名的直替件**（为 ST `substitute.sh` 直接替进
`build/rtl`）。`Scheduler`/`Scheduler_1/2/3`、`ExeUnit`、`IssueQueue*`、`Rob`、`Rename`、
`DecodeStage` 等重写核 **复用 golden 名**，且彼此/对 golden 叶子按 golden 名互联。
在 BT「同一次 elaborate 里 golden + rewrite 双例化」场景下，这会 **大面积命名冲突**。
要消解须为每个重写核做 `_it`/`_bt` 重命名机械——这套机械目前只对
**Int Scheduler / Exec / Decode / RenameDispatch / Writeback** 这 5 个 IT 簇做过
（见 `verif/it/{Issue,Exec,Decode,RenameDispatch,Writeback}/`，均已 seed1/7/42 通过）。

因此本 BT 取 **能干净双例化、且重写核功能完整** 的最大子集：
把 golden Backend 的 **权威互联 body**（4.7 MB，golden `Backend.sv` 逐字）作底，
把以下 **4 个** 子模块实例的模块名换成 `_bt` 包装（内含真重写 `xs_*_core`）：

| golden 实例 | 换成 | 链路（真重写核） |
|---|---|---|
| `WbFuBusyTable inner_wbFuBusyTable` | `WbFuBusyTable_bt` | → `WbFuBusyTable_xs` → **`xs_WbFuBusyTable_core`** |
| `BypassNetwork inner_bypassNetwork` | `BypassNetwork_bt` | → `BypassNetwork_xs` → **`xs_BypassNetwork_core`** |
| `WbDataPath inner_wbDataPath` | `WbDataPath_bt` | → `WbDataPath_xs_bt` → **`xs_WbDataPath_core`** |
| `Scheduler inner_intScheduler` | `Scheduler_bt` | → `Scheduler_core_bt` → **`xs_IssueQueue{AluCsrFenceDiv,AluMulBkuBrhJmp,AluBrhJmpI2fVsetriwiVsetriwvfI2v}_core`** → **`xs_Entries*_core`** → **`xs_iq_entry_*`** |

> 共纳入 **6 个不同 `xs_*_core`** 类型（`grep xs_.*_core` 可证）：
> `xs_WbFuBusyTable_core` / `xs_BypassNetwork_core` / `xs_WbDataPath_core` /
> `xs_IssueQueueAluCsrFenceDiv_core` / `xs_IssueQueueAluMulBkuBrhJmp_core` /
> `xs_IssueQueueAluBrhJmpI2fVsetriwiVsetriwvfI2v_core`（外加 Scheduler 子树下 3 个
> `xs_Entries*_core` + 3 个 `xs_iq_entry_*` 条目核）。

其余子模块（CtrlBlock / Scheduler_1/2/3（FP/Vec/Mem）/ DataPath / ExuBlock×3 /
Og2ForVector / VecExcpDataMergeModule / NewPipelineConnectPipe×N / DelayN / PFEvent /
HPerfMonitor）保留 golden。

### 两种 `_bt` 装配机制
1. **`_xs` 适配器包装**（WbFuBusyTable / BypassNetwork / WbDataPath）：重写是
   `xs_<M>_core`（名字唯一不撞 golden）+ `verif/ut/<M>/variants_xs.sv` 里的 `<M>_xs`
   适配器（golden 名子集端口）。`gen_bt.py` 给它套 **全 golden 端口** 的 `<M>_bt` 包装。
2. **golden 同名 drop-in 子树改名**（Scheduler Int）：重写 `module Scheduler` 及其下
   3 个 IssueQueue + 3 个 Entries wrapper 都是 golden 同名（为 ST 直替设计），BT 双例化
   会撞名。照 `verif/it/Issue/gen_it.py` 的 `_it` 机制，把这 6 个算法模块 + Scheduler
   顶层 **整词加 `_bt` 后缀**（声明+例化引用），生成 `Scheduler_core_bt`（782 端口=golden
   子集），再被 `gen_bt.py` 的全端口 `Scheduler_bt` 包装。`xs_*_core` / `xs_iq_entry_*` /
   共享 golden 结构原语（AgeDetector / FuBusyTable* / MultiWakeupQueue / EnqPolicy /
   UIntCompressor，`-y` 自动解析）不改名。

### difftest 探针撞名消解（WbDataPath）
`WbDataPath_xs` 例化的 difftest sink `DummyDPICWrapper_24/32/38/44`，在 WbDataPath 单核
elaboration 里编号 N 与 golden Backend 全闭包里 **同号但不同端口** 的 `DummyDPICWrapper_N`
撞名（difftest 模块在不同 chisel 上下文复用同号）→ VCS 端口未定义错。因这些是 **纯 write-only
sink，不驱动设计任何输出**，`gen_bt.py` 在 `_bt` 侧把它们改名 `_wbdp` 并配本地空 stub
（端口对齐），与 golden 侧同号真探针隔离。golden 侧（u_g）仍用真探针。

> **被测的真 rewrite-to-rewrite 边界**：`xs_BypassNetwork_core` 的旁路网络输出 ↔
> `xs_WbFuBusyTable_core` 的写回忙表，二者都在 Backend 互联里被 golden DataPath/ExuBlock/
> Scheduler 包围，整子系统逐拍比 golden。这是 per-module UT 看不到的集成边界
> （UT 里两核各自被 golden 团团围住，从未一起跑）。

### 纳入不了的核（如实标注，`gen_bt.py` 已生成包装但 Makefile 不纳入）
- **DataPath**：`DataPath_bt.sv` 已生成，但 (1) `xs_DataPath_core` 的 difftest 探针
  `DummyDPICWrapper_9`（ArchIntRegState 变体，`io_bits_value_0..7`）与 golden Backend
  全闭包里 **同号** 的 `DummyDPICWrapper_9`（PTW 变体，`io_bits_satp…`）撞名（同
  WbDataPath，但 DataPath UT 无现成 stub 文件可复用）；(2) `xs_DataPath_core` 真省略
  **210 个** 功能 output（`gen_bt.py` 已对 26 个透传 + 200 个常量做忠实重建，仍余 210 个
  `preDecode_*`/mem-IQ `iqIdx/srcTimer/lqIdx`/`og1resp` 等含逻辑、instance-port 驱动、
  无法机械重建），纳入会在顶层量化分叉。
- **ExuBlock / ExuBlock_1**：`ExuBlock_bt.sv`/`ExuBlock_1_bt.sv` 已生成，但重写 **核**
  （`xs_ExuBlock*_core`，非仅适配器）真省略 FU 写回 output：
  · `io_in_X_0_ready` —— FU 入口 ready 背压，golden 里 = `_exus_N_io_in_ready`（ExeUnit
    内部 wire）。ExuBlock_1 的 `ExeUnit_9` 含 **FDivSqrt**（迭代 FU，除法期间 ready=0，
    **动态**），tie 0 = 谎报"FU 永不 ready"→ 发射时序分叉。
  · `io_out_X_Y_bits_data_0` 次数据通道、`io_out_*_redirect_bits_cfiUpdate_*` 分支重定向、
    `debugInfo_*`/`debug_seqNum` —— 均 instance-port 直驱，非纯透传/常量，无法重建。
  这些是 instance 端口连接（非 `assign`），`gen_bt.py` 的透传/常量重建够不着，tie 0 会真分叉。
  要纳入须扩 `verif/ut/ExuBlock*/variants_xs.sv` 适配器把 `io_in_ready` 等路由出来
  （改共享 UT 适配器，超出本轮范围）。

---

## 2. `_bt` 包装做法（忠实，零强制置零）

每个 `<M>_bt`（`gen_bt.py` 生成）：
- **全套 golden 端口**（顶层端口逐字 = golden `<M>`，故可在 golden body 里按名直替实例）。
- 例化已验证的 **`<M>_xs` 适配器**（端口 = golden 名子集 + 真重写 glue + `xs_<M>_core`）。
- golden-only output 处理（`gen_bt.py` 三档忠实重建，按优先级）：
  1. **纯透传**：扫 golden `assign <out> = <port>;`（典型 ready 背压、忙表自反馈位）→ 同规则重建。
  2. **常量**：扫 golden `assign <out> = <literal>;`（典型 always-ready `1'h1`）→ 同常量重建。
  3. 其余才接 `'0`，列 nonfunc。
- 各 active 模块重建统计（`gen_bt.py` 输出 / `nonfunc_ports.json`）：
  - BypassNetwork：passthru=299, const=0, tied=0
  - WbFuBusyTable：passthru=2, const=0, tied=0
  - WbDataPath：passthru=677, **const=9**（9 个 `io_fromMemExu_X_0_ready=1'h1` always-ready）, tied=0
  - Scheduler：passthru=0, const=0, **tied=32**（7 个 `io_wbFuBusyTable_*`（单周期 int exu 永不忙、
    golden 亦恒 0）+ 25 个 `preDecode_*`/`debug_seqNum` 元数据；instance-port 直驱无法重建，
    **经实测 tie 0 不触及 723 个比对功能输出**）。
- ⇒ 全 BT **nonfunc_errors=0**：无任何功能输出因被 tie 0 而分叉。

---

## 3. 纯重写确认（grep 可证）

```
Backend_bt.sv:   4 个实例换 _bt —— Scheduler_bt inner_intScheduler / WbFuBusyTable_bt /
                 BypassNetwork_bt / WbDataPath_bt
```
u_i 编译进的 **12 个 distinct `xs_*_core`**（外加 Scheduler 子树重写顶 `Scheduler_core_bt`）：
```
xs_BypassNetwork_core  xs_WbFuBusyTable_core  xs_WbDataPath_core
xs_IssueQueueAluCsrFenceDiv_core   xs_IssueQueueAluMulBkuBrhJmp_core
xs_IssueQueueAluBrhJmpI2fVsetriwiVsetriwvfI2v_core
xs_EntriesAluCsrFenceDiv_core   xs_EntriesAluMulBkuBrhJmp_core
xs_EntriesAluBrhJmpI2fVsetriwiVsetriwvfI2v_core
xs_iq_entry_acfd   xs_iq_entry_ambb   xs_iq_entry_abjivvi
```
rewrite 侧模块名全部带 `_xs`/`_bt`/`xs_*_core`/`*_wbdp`，与 golden 无命名冲突，两侧同时 elaborate 0 错。
> **真 rewrite↔rewrite 边界**：`xs_BypassNetwork_core`↔`xs_WbFuBusyTable_core`↔
> `xs_WbDataPath_core`↔Int Scheduler 子树（调度→发射队列→条目阵列）在 golden Backend
> 互联里被 golden DataPath/ExuBlock 包围整子系统逐拍比 golden——per-module UT 看不到的集成边界。

---

## 4. tb / Makefile

- `tb.sv`：由 `verif/ut/Backend/tb.sv` 改造——u_i 换 `Backend_bt`；`+NCYCLES=<n>` 可调；
  723 个顶层输出逐拍 `!$isunknown(golden)` 守门比对；`nonfunc_errors` 单列（本 BT 为 0）。
- `Makefile`：`include ../../../scripts/ut_common.mk`（复用，未改）。
  - `RTL_SRCS` = 7 个 pkg + 3 个 `xs_*_core`（BypassNetwork/WbFuBusyTable/WbDataPath）+
    Scheduler 子树（6 个共享 xs core + 7 个 `_bt` 改名件）+ 2 个 `_xs` 适配器 + WbDataPath 改名
    适配器/stub + 4 个 `_bt` 包装 + `Backend_bt.sv`。
  - `GOLDEN_SRCS` = golden `Backend.sv` + 31 直接子模块类型；`-y GOLDEN_RTL` 自动解析更深共享叶子
    （含 Scheduler 子树共享结构原语 AgeDetector/FuBusyTable*/MultiWakeupQueue/EnqPolicy/
    UIntCompressor 及 WbDataPath/golden 真 difftest 探针）。
  - `+incdir+. +incdir+rtl/backend`（Scheduler_core_bt 找本地 `_bt` 连接 svh + IQ 复用 rtl ports/connect svh）。
  - `+define+SYNTHESIS`；`+vcs+initreg+random` 编译 / `+vcs+initreg+0` 运行；`-assert disable`。

---

## 5. 复跑

```bash
cd verif/bt/Backend
source ../../../scripts/env.sh
python3 gen_bt.py                                              # 重生所有 _bt 包装 + Scheduler 子树
python3 gen_backend_bt.py WbFuBusyTable BypassNetwork WbDataPath Scheduler   # 选择 active 换哪些实例
make compile
for s in 1 7 42; do ./simv +ntb_random_seed=$s +vcs+initreg+0 +NCYCLES=100000 -l sim_$s.log; done
grep -E "distinct_diverging_ports|checks=|TEST" sim_*.log
```

---

## 6. 结果

见各 `sim_<seed>.log`：4 个换入重写核（BypassNetwork / WbFuBusyTable / WbDataPath /
Int Scheduler 子树）下，seed 1/7/42 各 **100000 拍**，`errors=0`、`nonfunc_errors=0`、
`distinct_diverging_ports=0/723`。（3 核中间态 WbDataPath 见 `sim_wbdp_<seed>.log`，亦 0 错。）
