# ST 首批替换候选模块

判据：**自包含**——bundle 只含 `[pkg + 可读核 + (内联 svh) + wrapper]`，要么纯叶子（核不例化任何
子模块），要么只黑盒**留在 build/rtl 的 golden 数据通路叶子**（靠 `-y` 自动解析，不需替换那个叶子）。
所有候选都是后端执行单元（FU），UT + FM 已逐一验证 wrapper 与 golden 端口逐位等价，是 ST 起步的最低风险面。

判据来源：扫 `rtl/backend/*` 的核例化（`grep` 非 `xs_*` 模块实例）+ 对应 UT `Makefile` 的
`GOLDEN_SRCS / SUB_DEPS` + golden `build/rtl` 叶子存在性 + package 唯一性。

> 干跑已验证（独立 VCS elaborate，exit 0）：**Alu**（纯叶子）、**Bku**（自带 6 子单元）、
> **FAlu**（黑盒 FloatAdder）。其余候选结构同型。
>
> **系统级实测通过（coremark + microbench + NEMU difftest，全端口 wrapper）**：
> **Alu**(组合) 与 **Bku**(2 拍流水) 单替、Alu+Bku 同替——均 **HIT GOOD TRAP @ cycle 6492**
> (== golden)。证明 substitute.sh 的全端口 wrapper（见 README §2.1）能让重写 SV 进全片跑
> 真实程序、与 NEMU 逐指令一致。
>
> **★ 大范围同替实测（2026-06-26）★** 一次性把 **17 个重写模块** 同时装进 build/rtl 重编重跑：
> - 11 个整数+浮点 FU：**Alu / Bku / MulUnit / DivUnit / BranchUnit / JumpUnit / Fence /
>   FAlu / FMA / FCVT / FDivSqrt**
> - 6 个更大粒度的后端 glue/解码块：**CompressUnit(662 行) / FPDecoder(649) / DelayReg(606) /
>   UopInfoGen(266) / WbFuBusyTable(221) / ImmExtractor(100)**
>
>   结果：**coremark HIT GOOD TRAP @ 6492、microbench HIT GOOD TRAP @ 6430**，均 == golden
>   基线（golden 同跑 coremark@6492 / microbench@6430），全程 difftest 零 MISMATCH。证明
>   重写 SV 可大范围（17 块）同时进真实芯片、跑多个真实程序、与 NEMU 逐指令一致。
>
> **linux.bin（OpenSBI+Linux 镜像）在本 ready-to-run 环境**：golden 与 17-替换 simv **都**在
>   cycle **4575**（instrCnt=0，difftest 干净）就 HIT GOOD TRAP——即该镜像在此 VCS-difftest
>   通路上没真正 boot（早早 trap），golden/替换行为**完全一致**。本环境真正能跑的"更大
>   workload"是 coremark/microbench（~6.4k–6.5k cyc），均已 bit-exact 通过。（verilator emu
>   因 glibc 跑不动，full Linux boot 走不通是环境天花板，非核 bug。）

---

## ★ 工具升级与 XMRE/bore 机制（2026-06-26，扩大替换时踩到并固化）

大范围同替时遇到两类**新失败模式**，均已在 `gen_full_wrapper.py` / `substitute.sh` 修复（不动重写核）：

1. **ANSI 头 import 子句**：`Fence_wrapper.sv` 把 `import fence_pkg::*;` 写在 `module Fence`
   与端口左括号之间。原 `gen_full_wrapper.parse_ports` 正则不容忍 → "module Fence not found"，
   且 substitute.sh **静默 exit 0**（python stderr 被吞）装进一个**没有 module Fence** 的残缺
   bundle。修：parse_ports 正则容忍 `(#(...))?(import ...;)*` 后再到端口 `(`；substitute.sh
   落地前加守卫——bundle 必须含 `module <M>(`，否则报错退出。

2. **SimTop BoringUtils 跨模块 bore → XMRE**：firtool 给浮点 FU（FAlu/FMA/FDivSqrt/FCVT）的
   非法操作码断言生成 `wire _GEN = io_in_valid & io_in_bits_ctrl_fuOpType == 9'hFF;`，并经
   `BoringUtils` 把该 `_GEN` 探到 SimTop（`SimTop.sv` 里 `.x1_bore_NNN (...exus_N.Falu._GEN)`）。
   重写 wrapper 无此 net → 顶层 9 条 **XMRE**（"token '_GEN' cannot resolve"）。
   **关键洞察**：`_GEN` 是**纯端口组合**（只依赖 golden 端口），可在全端口 wrapper 里照抄复刻。
   修：`gen_full_wrapper.scavenge_bored_wires()` 从 golden 模块体抓 module 作用域的
   `wire _GEN[_n] = <纯端口表达式>;` 原样复刻进 module M（先剔 SV 基数字面量 `9'hFF` 再判端口依赖，
   否则 `hFF` 被当非端口标识误滤）。UopInfoGen/FPDecoder 也有这类 `_GEN_n`，一并复刻（不参与
   difftest 架构比对）。

### 可替换性判据（决定性）：**golden 模块体内有无被 bore 的内部探针 net**

`grep -c '_probe' build/rtl/<M>.sv`：
- **=0**（FU 全部 + CompressUnit/FPDecoder/DelayReg/UopInfoGen/WbFuBusyTable/ImmExtractor）→
  bore 至多探 `_GEN`（纯端口组合，可复刻）→ **wrapper 可替换**。
- **>0**（**ExeUnit** =6，IssueQueue/Entries 同型）→ SimTop bore 直接探 `data_0_probe /
  clk_en_probe / clk_en_N_probe / _GEN_0..2` 等**内部流水状态 net**（`= _Alu_io_in_ready &
  _in1ToN_io_out_0_valid`、`= {_Bku_io_out_valid,_Mul_io_out_valid,_Alu_io_out_valid}` 等，
  引用核内部网而非端口）→ 黑盒 wrapper 看不到核内部、无法复刻 → **当前 wrapper 机制替不了**。
  （要替须让重写核自身原样吐出这些探针 net——但那要动重写核，超出 ST 工具范围。）

> **最大可替换粒度结论**：FU 级 + 无内部探针的后端 glue/解码块（17 块已同替通过）。
> 互联块 ExeUnit / IssueQueue(Entries) 受 BoringUtils 内部探针 bore 阻塞，wrapper 替不了。

---

## A. 纯叶子（bundle 完全自包含，零外部依赖）

核不例化任何 golden 模块；替换后原 golden 叶子变孤儿，无害。**最优先**。

| 模块 | wrapper(module名) | 核 | pkg | bundle 文件清单 | 备注 |
|------|------|-----|-----|----------------|------|
| **Alu** | `Alu_wrapper.sv` (module Alu) | `Alu.sv` (xs_Alu_core) | `alu_pkg.sv` (alu_pkg) | pkg + 核 + wrapper | 单周期纯组合，✅ 已 elaborate |
| **Bku** | `Bku_wrapper.sv` (module Bku) | `Bku.sv` (xs_Bku_core + 6 子单元 xs_bku_count/clmul/misc/hash/cipher/crypto) | `bku_pkg.sv` (**xs_bku_pkg**) | pkg + 核(含 6 子) + wrapper | 子单元都在 `Bku.sv` 内，✅ 已 elaborate |
| **Fence** | `Fence_wrapper.sv` (module Fence) | `Fence.sv` (xs_Fence_core) | `fence_pkg.sv` (fence_pkg) | pkg + 核 + wrapper | |
| **JumpUnit** | `JumpUnit_wrapper.sv` (module JumpUnit) | `JumpUnit.sv` | `jumpunit_pkg.sv` | pkg + 核 + wrapper | |
| **BranchUnit** | `BranchUnit_wrapper.sv` (module BranchUnit) | `BranchUnit.sv` | `branchunit_pkg.sv` | pkg + 核 + wrapper | |
| **VSetRiWi** | `VSetRiWi_wrapper.sv` | `VSetRiWi.sv` | `vset_pkg.sv` (**vset_pkg**) | pkg + 核 + wrapper | ⚠ 与 VSetRvfWvf 共用 vset_pkg |
| **VSetRvfWvf** | `VSetRvfWvf_wrapper.sv` | `VSetRvfWvf.sv` | `vset_pkg.sv` (**vset_pkg**) | pkg + 核 + wrapper | ⚠ 与 VSetRiWi 共用 vset_pkg |

> **VSetRiWi / VSetRvfWvf 不能同时替换**（共用 `vset_pkg` → package 重定义）。要同时上须把两者
> co-bundle（vset_pkg 只出现一次）。`substitute.sh` 的包冲突守卫会拦截单独同装。

---

## B. 黑盒单叶子（bundle 不含数据通路叶子，靠 `-y` 解析 build/rtl 里原 golden 叶子）

核黑盒一个 golden 浮点/乘除数据通路叶子；该叶子**保持原样留在 build/rtl**，不替换。bundle 只装
pkg+核+wrapper。

| 模块 | 核(xs_*_core) | pkg | 黑盒的 golden 叶子(留 build/rtl) | bundle 文件清单 |
|------|------|-----|------|----------------|
| **MulUnit** | `MulUnit.sv` | `mulunit_pkg.sv` | `ArrayMulDataModule.sv` | pkg + 核 + wrapper |
| **DivUnit** | `DivUnit.sv` | `divunit_pkg.sv` | `SRT16DividerDataModule.sv` | pkg + 核 + wrapper |
| **FAlu** | `FAlu.sv` | `falu_pkg.sv` | `FloatAdder.sv` | pkg + 核 + wrapper（✅ 已 elaborate） |
| **FMA** | `FMA.sv` | `fma_pkg.sv` | `FloatFMA.sv` | pkg + 核 + wrapper |
| **FCVT** | `FCVT.sv` | `fcvt_pkg.sv` | `FPCVT.sv` | pkg + 核 + wrapper |
| **FDivSqrt** | `FDivSqrt.sv` | `fdivsqrt_pkg.sv` | `FloatDivider.sv` | pkg + 核 + wrapper |

> 6 个黑盒叶子均已确认存在于 `build/rtl`。这些 FU 在 golden 顶层就是一层薄 wrapper 例化对应叶子，
> 重写核同样薄黑盒，替换面极小、风险低。

---

## C. 不属于首批（需更高阶处理，列此备忘）

- **共享 package 的成组模块**：`xs_ftb_pkg`（FTB / FauFTB / FTBBank / …×4）、`xs_ptw_pkg`、
  `xs_pmp_pkg`、`xs_predecode_pkg`、`xs_l1metaarray_pkg`、`exceptionbuffer_pkg`、`vset_pkg`。
  要替换其中任一须 co-bundle 同包模块（共享包只出现一次），否则 package 重定义。
- **大互联模块**（CtrlBlock / DataPath / NewDispatch / NewCSR / Backend / MemBlock / DCache /
  L2TLB / Frontend …）：核 `` `include `` 多个 svh（端口/连线分片），且黑盒大量 golden 子模块。
  `substitute.sh` 的 svh 内联已支持（DecodeUnit 干跑验证了内联路径），但这些模块依赖众多、面大，
  建议先把 A/B 类 FU 在系统级跑通、确认 difftest 通路无误后再逐步上。

---

## 推荐首批顺序

1. **Alu**（纯叶子、最常用整数 FU、已干跑）
2. **Bku → Fence → JumpUnit → BranchUnit**（纯叶子，逐个上）
3. **FAlu → FMA → FCVT → MulUnit → DivUnit → FDivSqrt**（黑盒单叶子）
4. **VSetRiWi / VSetRvfWvf**（二选一单独上，或 co-bundle 同上）

每步：`substitute.sh <M>` → `run_st.sh build` → `run_st.sh run`（带 NEMU `REF_SO` 做 difftest），
出错即 `restore.sh <M>` 回滚定位。
