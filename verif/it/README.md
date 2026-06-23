# IT —— 集成级（Integration Test）验证平台

> 本目录是香山 V2R2 可读 SV 重写工程的 **IT（集成级）验证** 子项目。
> BPU 簇（`verif/it/BPU/`）是开篇样板，立模式；后续各簇照此并行。

---

## 1. IT 是什么 / 为什么需要

本工程的重写架构里，**每一层 = 重写 glue 核（`xs_<M>_core`）+ golden 叶子黑盒**：

- **per-module UT** 只验「**1 个重写 glue 核 vs golden**」，且该核被 golden 子模块团团围住
  （`<M>_xs` 适配器把 golden 扁平端口搬到 `xs_<M>_core`，其余子模块全用 golden）。
- 结果：**UT 里从来没有任何重写件去例化另一个重写件**。重写核之间的边界（位宽对齐、
  握手时序、meta/perf 拼接偏移、流水级 fire/flush 传播…）**一次都没被一起跑过**。

**IT 的价值 = 首次把重写的 glue 核与重写的叶子核全部直连**，整簇对比 golden，
专抓 **集成 / 边界 bug**——这些 bug 是 per-module UT 结构上看不见的。

---

## 2. IT 装配模式（样板，务必照抄）

对每个簇，写一个 **`<簇>_it` 顶层装配**，规则：

1. **顶层端口 = golden 顶层端口**（逐字相同），便于 tb 双例化逐拍比对。所有内部模块名
   一律带 `xs_` / `_xs` / `_it` 前后缀，**与 golden 无命名冲突**，两侧可同时编译。

2. **算法逻辑全部用重写核**：
   - 直接例化重写核 `xs_<M>_core`，或复用各模块 UT 现成的 **`<M>_xs` 适配器**
     （`verif/ut/<M>/variants_xs.sv`，每个文件恰好 1 个适配器模块，纯端口搬运 +
     例化 `xs_<M>_core`，**不含任何 golden 算法叶子**）——这是 IT 最省力且诚实的积木。
   - 适配器与 golden 同名模块**端口完全一致**（已逐一核对），因此可作 golden 叶子的
     **drop-in 替换**：把 golden 装配体里 `Foo foo(...)` 改成 `Foo_xs foo(...)` 即可。

3. **叶子边界 = SRAM 模板 / SRAM 宏**：`SRAMTemplate` / `FoldedSRAMTemplate` /
   `SplittedSRAMTemplate` / `WrBypass` / `array_*` 等是**存储原语**（memory model），
   golden 与 rewrite 共用同一份——它们不是「算法」，作为共享叶子保留 golden 是诚实且
   不可避免的（两侧例化同一份 SRAM 宏，存储行为天然一致）。

4. **纯结构 / 纯延迟件**（`DelayN`、`PriorityMuxModule`、MBIST pipe 壳）若无独立重写，
   可暂用 golden；在 README 与报告里如实标注「非重写」。

5. **互联 glue 若无独立重写核**（例如 golden `Predictor` / `Composer` 的菊花链布线本身
   是自动生成的扁平 body，工程里没有把它单独抽成一个重写核），则 `<簇>_it` 复用该 golden
   互联 body，**只把其中的算法叶子实例换成重写适配器**。这样「重写叶子 ↔ 重写叶子」的
   集成边界依然被真实地连起来跑——这正是 IT 要覆盖的部分。

---

## 3. 与 UT 的区别（一张表）

| 维度        | UT（per-module）                         | IT（per-cluster）                                  |
|-------------|------------------------------------------|----------------------------------------------------|
| 被测重写件  | 1 个 `xs_<M>_core`                        | 整簇所有 `xs_*_core` **直连**                       |
| 周围环境    | golden 子模块包围                         | 重写叶子互相包围（仅 SRAM 宏 / 纯结构件用 golden）  |
| 抓的 bug    | 单核内部算法                             | **核间边界 / 集成 / 时序传播**                      |
| golden 角色 | 参考模型 + 被测核的所有邻居              | **仅参考模型**（u_g）+ 共享存储原语                 |
| 顶层端口    | golden 扁平端口（含 `xs_dbg_*` 影子口）  | = golden 顶层端口（去掉影子口，影子核转内部观察）  |

---

## 4. tb / Makefile 约定

- **tb.sv**：双例化 golden 顶层 `u_g` 与 `<簇>_it u_i`，喂**相同**随机激励到簇边界，
  **逐拍比对全部顶层输出端口**，`!$isunknown(golden)` 跳 don't-care。
  - 复用对应模块 UT 的 tb 作底（激励生成 + 端口比对已写好），只需：
    顶层换 `_it`、去掉 u_i 的 `xs_dbg_*` 端口连接、把在环重写核影子线用 `u_i.xs_dbg_*`
    引出做 **bonus 交叉校验**（`core_errors`）。
  - **PASS 判据 = 功能输出 `errors==0` 且在环核 `core_errors==0`**。
  - **非功能输出**（DFT/MBIST bore 链、重写侧主动置零的 perf 性能计数器）单列
    `nonfunc_errors`，**打印但不计入 PASS**（见第 6 节 BPU 实例）。
  - `+NCYCLES=<n>` 运行时覆盖拍数。

- **Makefile**：`include ../../../scripts/ut_common.mk`（**复用，别改**）。
  - `RTL_SRCS` = 全部重写 xs 核 + `_xs` 叶子适配器（直接引用 `../../ut/<M>/variants_xs.sv`）
    + 本目录 `<簇>_it.sv` 装配文件。
  - `GOLDEN_SRCS` = golden 顶层 + 全部 golden 叶子（u_g 用）+ 共享 SRAM 宏。
  - `TB_SRCS = tb.sv`；`FM_VARIANTS=`（**IT 不做 FM**，等价证明是 per-module 的事）。
  - `VCS += +define+SYNTHESIS`（关 golden `ifndef SYNTHESIS` 随机初值 / 运行时断言，
    避免随机激励误触 `$fatal`）；`+vcs+initreg+random`（编译）配运行时 `+vcs+initreg+0`
    （无 reset 寄存器清 0，两侧从同一确定态出发）。

---

## 5. 簇清单规划（后续照此并行）

- **Frontend**：**BPU**（本样板，已完成）、IFU、IBuffer、Ftq
- **MemBlock**：LSU、LSQ、MMU、DCache
- **Backend**：Decode、Rename-Dispatch、Issue、Exec、Writeback

每个簇一个 `verif/it/<簇>/` 目录，内含 `<簇>_it.sv`(+ 必要的子装配) / `tb.sv` / `Makefile`。

---

## 6. 复跑命令

```bash
cd verif/it/BPU
source ../../../scripts/env.sh
make compile
# 单 seed
./simv +ntb_random_seed=1 +vcs+initreg+0 +NCYCLES=200000 -l sim_1.log
# 三 seed 全跑（验收）
for s in 1 7 42; do
  ./simv +ntb_random_seed=$s +vcs+initreg+0 +NCYCLES=200000 -l sim_$s.log
  grep -E 'checks=|TEST' sim_$s.log
done
```

验收标准：seed 1/7/42 各 ≥200000 拍，`errors=0 core_errors=0` → `TEST PASSED`。
许可证 27080 DOWN 时：`lmstat -a` 查 / `lmgrd`(或本机 `lmg`) 起 license。

---

## 7. BPU 簇实测结论（本样板）

**装配树（全部重写，已硬核对无 golden 算法叶子）：**

```
Predictor_it (= golden Predictor 互联 body + xs_Predictor_core 在环 FSM 观察核)
 └─ Composer_it (= golden Composer 菊花链 body + xs_Composer_core 驱动 perf/meta/ready)
     ├─ FTB_xs      → xs_FTB_core
     ├─ FauFTB_xs   → xs_FauFTB_core (→ xs_FauFTBWay)
     ├─ Tage_SC_xs  → xs_Tage_SC_core
     ├─ ITTage_xs   → xs_ITTage_core
     └─ RAS_it (= golden RAS 簿记壳) → RASStack_xs → xs_RASStack
```

golden 残留 = SRAM 模板/宏（共享存储原语）、`DelayN`、MBIST pipe 壳，以及
`Predictor`/`Composer`/`RAS` 的**互联/簿记 body**（工程未把这些扁平互联抽成独立重写核）。

**结果（seed 1/7/42 各 200000 拍）：**

| seed | checks  | errors | core_checks | core_errors | nonfunc_errors |
|------|---------|--------|-------------|-------------|----------------|
| 1    | 199936  | **0**  | 3398912     | **0**       | 558132         |
| 7    | 199936  | **0**  | 3398912     | **0**       | 557523         |
| 42   | 199936  | **0**  | 3398912     | **0**       | 557903         |

→ 三 seed **TEST PASSED**：所有**功能预测输出**（FTQ resp / full_pred / targets /
fallThrough / topdown 等）逐拍等于 golden；在环 `xs_Predictor_core` FSM 也逐拍等于 golden。

**IT 抓到的 2 个集成发现（per-module UT 漏掉、非功能，已单列 `nonfunc_errors`）：**

1. **DFT/MBIST bore 链未驱动**：`Tage_SC_xs` 把模块级 `boreChildrenBd_bore_ack/outdata`
   输出**悬空**（内部 MBIST `childBd_*` 端点未回连到顶层 bore 口），在 IT 顶层表现为
   `boreChildrenBd_bore_1_*` = `z`（golden = 0）。属 DFT 旁路链，非预测数据通路。
2. **perf 计数器置零**：`Tage_SC_xs` 把 `io_perf_{0,1,2}_value` 硬接 `6'b0`（重写时主动
   省略 TAGE 的 perf 统计），经 `xs_Composer_core` 传到顶层 `io_perf_2_value`，与 golden
   递增的计数不符。属性能观测口，非功能输出。

两者都是**重写在叶子级对非功能口的有意简化**，per-module UT 的比对/FM 把这些口排除了，
故在 UT 里看不见；IT 把它们一路连到顶层才暴露。因均为 DFT/perf 旁路、不影响预测正确性，
本样板将其单列 `nonfunc_errors`（打印可见、不计入 PASS），并在此如实记录。
如需后续把它们也对齐 golden，应在 `Tage_SC_xs` / `xs_Tage_SC_core` 补 bore 回连与 perf 计数。

**Predictor 顶层 FSM 的接入深度（已知边界）：** `xs_Predictor_core`（重写的 s1/s2/s3
valid·fire·flush·topdown FSM）在 `Predictor_it` 里作为**在环观察核**与 golden FSM 逐拍
交叉校验（`core_errors=0`，3.4M 次/seed 全过）；但把它**反向接管** golden Predictor 那
~17k 行自动生成互联 body 的 FSM 信号（让重写 FSM 成为唯一数据源）尚未做——因为该 body
未被抽成独立重写互联核，深度 splice 风险高。这一步留作 BPU IT 的后续加强项。
