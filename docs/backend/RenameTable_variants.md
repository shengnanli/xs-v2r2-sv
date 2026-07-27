# RenameTable 参数变体 —— RenameTable_1 / _2 / _3(fp / vec / v0,vl RAT)

> 参数化可读核:`rtl/backend/renametable_var_core.sv`（`xs_RenameTable_var_core`）+ 复用 `renametable_pkg.sv` 的共享常量/结构。
> 包装层:`rtl/backend/RenameTable_{1,2,3}_wrapper.sv`（golden 同名，扁平端口 → 参数核 + SnapshotGenerator 黑盒）。
> 生成脚本:`scripts/gen_renametable_variants.py`（从 golden 端口机械派生 wrapper/UT）。
> golden:`golden/chisel-rtl/RenameTable_{1,2,3}.sv`。

## 1. 与已签核基版 RenameTable(intRat)的关系

香山后端按寄存器类型例化 5 张 RAT（见 `RenameTableWrapper`）:

| golden 类型 | 实例 | 说明 |
|-------------|------|------|
| `RenameTable`（基版，已 SIGNOFF_PASS） | intRat | 整数 Reg_I |
| `RenameTable_1` | fpRat | 浮点 Reg_F |
| `RenameTable_2` | vecRat | 向量 Reg_V |
| `RenameTable_3` | v0Rat, vlRat | Reg_V0 / Vl |

四者是**同一逻辑结构的纯参数变体**（spec/arch 双表 + 同步读旁路 + 快照回退 + difftest 真值表）。
基版可读核 `xs_RenameTable_core` 把固定 localparam 写死；本变体核 `xs_RenameTable_var_core`
把这些提升为 module parameter，逻辑逐字与基核同构。

## 2. 参数矩阵（经 diff golden 逐项核对）

| 参数 | intRat(基版) | _1 fp | _2 vec | _3 v0/vl |
|------|:---:|:---:|:---:|:---:|
| `NUM_ENTRY`（spec/arch 表项） | 32 | 34 | 47 | 1 |
| `ADDR_W`（逻辑寄存器号位宽） | 5 | 6 | 6 | 0→夹到 1 |
| `NUM_READ`（读口数） | 12 | 18 | 18 | 6 |
| `NUM_DIFF_ENTRY`（difftest 表项） | 32 | 32 | 31 | 1 |
| `DIFF_BASE`（difftest 表覆盖的最小逻辑号） | 0 | 0 | 1 | 0 |
| `HAS_NEED_FREE`（old_pdest 引用计数回收） | 1 | 0 | 0 | 0 |
| `RESET_IDENTITY`（复位表初值=identity map） | 0 | 1 | 1 | 0* |
| `SnapshotGenerator` | _4 | _5 | _6 | _7 |

要点：
- **difftest 表独立于 spec/arch 表**：项数 `NUM_DIFF_ENTRY`（=逻辑寄存器数）常 ≠ `NUM_ENTRY`（=物理表项）。
  vec 的 difftest 表覆盖逻辑号 1..31（`DIFF_BASE=1`，v0 不在 vec 真值表内），故 `diff_rdata[e]=difftest_table[e]` 对应逻辑号 `1+e`。
- **复位初值**：fp/vec 复位为 identity map（`table[e]<=e`）；整数 RAT 与 v0/vl 复位全 0（`*`v0/vl 只 1 项，identity 与 0 同值）。
- **need_free 仅整数 RAT 有**：变体 golden 无 `io_need_free` 输出与寄存器 → `HAS_NEED_FREE=0` 时核内用 generate 完全不例化该寄存器（避免 FM 严格模式 impl-only cone-dead）。
- **单项表(_3)**：`ADDR_W` 逻辑上=0（golden 无 addr 端口），SV 夹到 1；读/写恒作用 entry 0，
  golden 单项 RAT 无 `t1_raddr` / `t1_wSpec_addr` 寄存器 → 核内用 `generate if(NUM_ENTRY==1)` 走
  "恒读 entry 0 / 命中只看 wen" 分支，不例化这两组地址寄存器（否则它们恒 0 变 impl-only 死寄存器）。

## 3. FM 越界索引处理（FMR_ELAB-147）

当 `2^ADDR_W > NUM_ENTRY`（fp/vec/v0/vl），原始 addr 可越出表边界。所有"按 addr 读表"处
（同步读 spec_table、old_pdest 读 arch_table）一律用**遍历 entry 比较 addr 命中则取、否则默认 [0]**
的显式 mux，复刻 golden 的 `_GEN[addr]` 读 LUT（高位补 `table_0`）语义，不用动态数组下标，
从而不触发 FM 严格模式的 `FMR_ELAB-147`（越界常量索引硬 fail）。

## 4. 验证

- **FM（权威签核）**：`make -C verif/ut/RenameTable_{1,2,3} fm`，signoff-strict 模式，
  `SnapshotGenerator_{5,6,7}` 两侧同名对称黑盒（`hdlin_unresolved_modules=black_box`，同基版 SG_4）。
  终态 clean strict SUCCEEDED：0 failing / 0(0) unmatched 全类 / 0 unread / 无 dont_verify / 无新黑盒 / 无 vmucp 白名单。
- **UT**：`make -C verif/ut/RenameTable_{1,2,3} run`，双例化 golden `RenameTable_N` vs 手写 `RenameTable_N_xs`，
  逐拍比对所有输出端口 + 内部 spec_table/arch_table 层次探针；seed 1/7/42 各 200000 拍 errors=0。

## 5. RenameTableWrapper 闭包

`RenameTableWrapper`（CtrlBlock 子，assembly SUCCEEDED）依赖 5 个 RAT 实例
（intRat=RenameTable, fpRat=_1, vecRat=_2, v0Rat/vlRat=_3）。基版 + 本 3 变体全部独立 SIGNOFF_PASS 后，
其 assembly 闭包（`assembly_depends.tsv` 声明的 4 个 RenameTable* 依赖）全部满足。
