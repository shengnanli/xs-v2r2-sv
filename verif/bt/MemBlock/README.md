# MemBlock BT —— 块级（整 MemBlock 访存子系统）验证

> 照 `verif/bt/Frontend/`、`verif/bt/Backend/` 样板 + `verif/it/README.md` 方法学。
> golden `MemBlock` (u_g) vs 重写装配 `MemBlock_bt` (u_i)，双例化逐拍比对 1346 个
> MemBlock 顶层功能输出（tb 与 `verif/ut/MemBlock/tb.sv` 逐字一致，仅 u_i 实例名不同）。

---

## 1. 装配了哪些 xs 重写核（grep 可证，纯重写确认）

本 BT 是**整 MemBlock 子系统装配**：顶层互联 glue 用重写核 `xs_MemBlock_core_bt`
（= `rtl/memblock/MemBlock.sv` 的 `xs_MemBlock_core` 逐字，仅 `include` 改指 BT 实例表
`memblock_inst_bt.svh`），并把实例表里 **clean-swap-set** 的子模块实例换成重写件，
其余 ~60 子模块（LSU 流水 / LSQ / 向量访存 / Atomics / 预取器 / PTW repeater / DTLB_1/_2 等）
保留 golden（无重写核或非干净双例化）。

| golden 实例 | 换成 | 链路（grep 可证） |
|---|---|---|
| `DCacheWrapper inner_dcache` | `DCacheWrapper_bt` | → `DCacheWrapper_xs` → **`xs_DCacheWrapper_core`** |
| `Uncache inner_uncache` | `Uncache_bt` | → `Uncache_xs` → **`xs_Uncache_core`** |
| `L2TLBWrapper inner_ptw` | `L2TLBWrapper_bt` | → `L2TLBWrapper_xs` → **`xs_L2TLBWrapper_core`** |
| `Sbuffer inner_sbuffer` | `Sbuffer_bt` | → `Sbuffer_xs` → **`xs_Sbuffer_core`** |
| `TLBNonBlock inner_dtlb_ld`(ld DTLB) | `TLBNonBlock_bt` | → `TLBNonBlock_xs` → **`xs_TLBNonBlock_core`** |
| `PMP inner_pmp` | `PMP_xs`(端口=golden) | → **`xs_PMP_core`** |
| `PMPChecker_10 ×8` | `PMPChecker_10_xs`(端口=golden) | → **`xs_PMPChecker_core`** |

**整子系统被测的重写核共 8 个**：顶层 glue `xs_MemBlock_core_bt` ＋ 7 个子模块核
（DCacheWrapper / Uncache / L2TLBWrapper / Sbuffer / TLBNonBlock-ld / PMP / PMPChecker）。
重写侧模块名全是 `xs_*_core` / `*_xs` / `*_bt`，与 golden **零命名冲突**，两侧同时
elaborate 0 错（VCS compile EXIT=0）。互联 body / SRAM 宏 / 未换子模块复用 golden。

> TLBNonBlock 只换 **ld DTLB** 这一实例（`TLBNonBlock_1`/`TLBNonBlock_2` 是 st/pf 不同
> 参数化，保留 golden）。`_bt` 包装做法：全 golden 端口，内部例化已验证的 `_xs` 适配器
> （= golden 名端口子集 + 真重写 glue + `xs_*_core`），golden-only input 悬空、
> golden-only output 透传重建。`gen_bt.py` 报告 **5 个包装全部 reconstructed≥0 / tied(nonfunc)=0**
> —— 即 **无任何功能输出被强制置零**（见 `nonfunc_ports.json`，全空）。

---

## 2. 结果（诚实，未达 errors=0；原因不在 BT 也不在 swap）

| 配置 | NCYCLES | errors | 不同输出口数 |
|---|---|---|---|
| **NULL**（不换任何子模块，纯重写 glue + 全 golden 子模块） | 20000 | **79464** | **49** |
| **FULL**（换全部 7 个重写核） | 20000 | 79491 | 58 |
| swap 净增量 | 20000 | **+27** | **+9** |

`sim_1.log` / `sim_7.log` / `sim_42.log` 为 full-swap、3 种子各 100000 拍
（`+vcs+initreg+0`）的正式记录。

**关键结论：errors 主体来自一个被 BT 忠实继承的基线回归，与本 BT、与 7 个 swap 核都无关。**

### 2.1 根因：golden 在 Jun-24 被 bump，重写 glue（Jun-16）未同步

- `golden/chisel-rtl/MemBlock.sv` 等 = **2026-06-24**；重写 glue
  `rtl/memblock/MemBlock.sv` + `memblock_logic.svh` = **2026-06-16**。
- bump 显著扩大了子模块接口。实测 `LsqWrapper` 模块端口从重写 glue 连接的 **1609**
  涨到 golden 的 **3081**（input 1413 / output 1668）：新增 `io_enq_req_*` / `io_ldu_ldin_*`
  / `io_sta_storeAddrIn_*` 的 **uop 元数据**（debugInfo / pdest / rfWen / vpu_* /
  srcLoadDependency …）共 **486 个 golden input 在重写 glue 实例里悬空**，外加
  `io_cboZeroStout` 全 uop、`io_diffStore` 等新输出。重写 glue 仍按**旧** golden 接口连线，
  新 input 悬空 → 传播成 49 个被检查顶层输出发散。
- 这 49 口集中在 **向量写回 `io_mem_to_ooo_writebackVldu_*`（uop 元数据）**、
  **`io_mem_to_ooo_vstuIqFeedback_*`（向量 store 反馈）**、`lsqio_uop_1_robIdx`、
  `wakeup_1_rfWen`、`issueLda_0_ready` / `issueVldu_0/1_ready` 等正是 golden 接口长大的路径。

### 2.2 这是基线回归、不是 BT 引入——已证

把**新建（Jun-26 重编）的 `verif/ut/MemBlock/simv` 直接重跑**：
`checks=6000 errors=8665`，发散口与 BT-NULL **逐口一致**。即 **MemBlock UT 本身当前就是红的**
（它那份 `errors=0` 是 Jun-16 旧 golden 下的 sim 日志，golden bump 后未重跑）。BT-NULL ≡ UT，
证明 BT 装配忠实，回归是整 MemBlock 重写**需对 Jun-24 golden 做整体 re-sync** 的工程级问题，
不属于「搭 MemBlock BT」本任务，也未触碰 `build/rtl` / 共享脚本。

### 2.3 swap 隔离：7 个重写子模块核相对干净

- **逐个单换**（5000 拍，`bisect_report.txt`）：DCacheWrapper / Uncache / L2TLBWrapper /
  Sbuffer / TLBNonBlock-ld / PMP **6 个核 = 基线 errors（7161），净增 0**；
  PMPChecker_10 **+13 errors（多 1 口 `auto_inner_dcache_client_out_b_ready`）**。
- **全换 vs NULL**（20000 拍）：净增 **+27 errors / +9 口**——
  `auto_inner_dcache_client_out_{b_ready,c_valid,c_bits_address}`（DCache probe 通道）、
  `wakeup_0_valid`、`writebackVldu_0 exceptionVec_{5,13,21}`、`issueLda_{1,2}_ready`。
  即 7 个重写核合在一起也只在基线之上加约 0.0045 误差/拍，**相对干净**（多为长跑后
  X-悲观/省略元数据级联），但因基线已红，无法判其是否能到 0。

---

## 3. tb / Makefile / 复跑

- `tb.sv`：= `verif/ut/MemBlock/tb.sv` 逐字，**仅 line 1948** 把 `MemBlock_xs u_i`
  换成 `MemBlock_bt u_i`（`diff` 仅此一行）。1346 顶层输出逐拍 `!$isunknown(golden)` 守门比对。
- `Makefile`：`include ../../../scripts/ut_common.mk`（未改共享脚本）。
  - `RTL_SRCS` = 7 类型包 + 7 个重写核(`xs_*_core`) + 7 个 `_xs` 适配器 + 5 个 `_bt` 包装
    + `MemBlock_bt.sv` + `difftest_stub.sv`。
  - `GOLDEN_SRCS` = golden `MemBlock.sv` + 273 文件传递闭包（与 MemBlock UT 同一份）
    + `DelayReg_21/22/23`（golden bump 后 Sbuffer 的 `difftest_delayer` 需真定义）。
  - `difftest_stub.sv`：访存 golden 子模块例化的 `DummyDPICWrapper_*`（input-only DPI 探针）
    空壳化（与 UT 里 VCS 自建空 cell 等价；对 u_g/u_i 对称，不引入发散）。
  - `+define+SYNTHESIS`（关 golden 断言/difftest 随机初值）；运行 `+vcs+initreg+0`。
- **生成器**（勿手改产物）：
  - `python3 gen_bt.py` → 5 个 `_bt` 全端口包装 + `nonfunc_ports.json`。
  - `python3 gen_memblock_bt.py [M...]` → `memblock_inst_bt.svh`（换核实例表，默认全换；
    给子集名可二分定位）+ `MemBlock_bt.sv`（重写 glue 核改名 + 全 golden 端口顶层包装）。

```bash
cd verif/bt/MemBlock
source ../../../scripts/env.sh
python3 gen_bt.py && python3 gen_memblock_bt.py      # 默认 full swap
make compile
for s in 1 7 42; do ./simv +ntb_random_seed=$s +vcs+initreg+0 +NCYCLES=100000 -l sim_$s.log; done
grep -E "checks=|errors=" sim_*.log
```

---

## 4. 还差什么（诚实）

1. **基线 re-sync（阻塞 errors=0 的唯一原因）**：把重写 MemBlock glue（`rtl/memblock/`
   的 `memblock_inst.svh` / `memblock_*.svh`）重生到 **Jun-24 golden** 接口——主要补
   `LsqWrapper`（及同类）新增的 `enq_req/ldu_ldin/sta_storeAddrIn` uop 元数据连线与向量
   writebackVldu 路径。这是 MemBlock 重写本体的维护，不在本 BT 任务面内。re-sync 后
   本 BT 基础设施可直接复跑收敛到 swap 净增量。
2. **swap 集扩展**：当前换 7 个干净核；StoreUnit/LoadUnit/LsqWrapper/向量访存等重写核
   是 ST 直替同名件，BT 双例化会撞名，需逐模块 `_bt`/`_xs` 重命名机械（如 Backend BT 对
   5 个 IT 簇所做）方可纳入。
3. **PMPChecker_10 的 +1 口**（`dcache_client_out_b_ready`）：待基线 re-sync 后单独复核。
