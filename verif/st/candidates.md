# ST 首批替换候选模块

判据：**自包含**——bundle 只含 `[pkg + 可读核 + (内联 svh) + wrapper]`，要么纯叶子（核不例化任何
子模块），要么只黑盒**留在 build/rtl 的 golden 数据通路叶子**（靠 `-y` 自动解析，不需替换那个叶子）。
所有候选都是后端执行单元（FU），UT + FM 已逐一验证 wrapper 与 golden 端口逐位等价，是 ST 起步的最低风险面。

判据来源：扫 `rtl/backend/*` 的核例化（`grep` 非 `xs_*` 模块实例）+ 对应 UT `Makefile` 的
`GOLDEN_SRCS / SUB_DEPS` + golden `build/rtl` 叶子存在性 + package 唯一性。

> 干跑已验证（独立 VCS elaborate，exit 0）：**Alu**（纯叶子）、**Bku**（自带 6 子单元）、
> **FAlu**（黑盒 FloatAdder）。其余候选结构同型。
>
> **系统级实测通过（coremark + NEMU difftest，全端口 wrapper）**：
> **Alu**(组合) 与 **Bku**(2 拍流水) 单替、Alu+Bku 同替——均 **HIT GOOD TRAP @ cycle 6492**
> (== golden)。证明 substitute.sh 的全端口 wrapper（见 README §2.1）能让重写 SV 进全片跑
> 真实程序、与 NEMU 逐指令一致。其余 A/B 类候选同机制，预期照此可逐个上。

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
