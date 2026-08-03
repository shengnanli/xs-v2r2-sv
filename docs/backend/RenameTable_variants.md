# RenameTable 参数变体 —— RenameTable_1 / _2 / _3(fp / vec / v0,vl 的 RAT)

| | |
|---|---|
| 手写 SV | `rtl/backend/renametable_var_core.sv`(参数化核 `xs_RenameTable_var_core`,与基核 `xs_RenameTable_core` 逐字同构,仅把 localparam 提升为 module parameter)+ `RenameTable_{1,2,3}_wrapper.sv`(golden 同名扁平壳) |
| 生成器 | `scripts/gen_renametable_variants.py` |
| Scala 来源 | `xiangshan/backend/rename/RenameTable.scala`(`class RenameTable(reg_t)`,同一份代码按 `Reg_I/F/V/V0/Vl` 特化) |
| golden | `golden/chisel-rtl/RenameTable_{1,2,3}.sv` |
| 依赖 | SnapshotGenerator_{5,6,7}(两侧同名对称黑盒,同基版 SG_4) |
| 验证 | UT 各变体 seed 1/7/42 checks 200000 errors=0;FM strict SUCCEEDED ×3(_1:2714 点 / _2:3322 点 / _3:286 点,均 0 failing / 0 unmatched / 0 unread) |

## 1. 定位:一份逻辑,五次特化

Chisel 里五张 RAT 是**同一个 `class RenameTable`** 按寄存器类型参数化出来的
(见 [RenameTableWrapper](RenameTableWrapper.md));firtool 去重后产生 4 个
golden 模块。基版(intRat,305 分母目标)的机制——spec/arch 双表、读写各打一拍、
写旁路、redirect 两拍恢复、快照——全部原样适用于变体,本文只讲**参数差异及其
微架构缘由**。机制本身见 [RenameTable.md](RenameTable.md)。

| golden 类型 | 实例 | 资源 |
|-------------|------|------|
| `RenameTable`(基版) | intRat | 整数 |
| `RenameTable_1` | fpRat | 浮点 |
| `RenameTable_2` | vecRat | 向量 |
| `RenameTable_3` | v0Rat, vlRat | v0 / vl(单项表) |

## 2. 参数矩阵(经 diff golden 逐项核对)

| 参数 | intRat(基版) | _1 fp | _2 vec | _3 v0/vl |
|------|:---:|:---:|:---:|:---:|
| `NUM_ENTRY`(spec/arch 表项) | 32 | 34 | 47 | 1 |
| `ADDR_W`(逻辑号位宽) | 5 | 6 | 6 | 0→夹到 1 |
| `NUM_READ`(读口数) | 12 | 18 | 18 | 6 |
| `NUM_DIFF_ENTRY`(difftest 真值表项) | 32 | 32 | 31 | 1 |
| `DIFF_BASE`(difftest 覆盖的最小逻辑号) | 0 | 0 | 1 | 0 |
| `HAS_NEED_FREE`(引用计数回收输出) | 1 | 0 | 0 | 0 |
| `RESET_IDENTITY`(复位为恒等映射) | 0 | 1 | 1 | 0* |
| `SnapshotGenerator` | _4 | _5 | _6 | _7 |

*v0/vl 只 1 项,恒等映射与全 0 同值。

### 逐项的"为什么"

- **表项数 ≠ 32**:`FpLogicRegs = 32+1+1`(I2F 转换与 stride 访存的内部临时逻辑
  寄存器)、`VecLogicRegs = 32+15`(向量拆分 uop 的内部临时)——后端给微码/拆分
  序列留的**不可见逻辑号**,同样要走重命名;于是 fp=34、vec=47,地址宽到 6 位。
- **读口数**:每条指令的源操作数上限决定——int 2 源、fp/vec 3 源、v0/vl 各 1 个
  隐式源,乘 RenameWidth=6。
- **复位值为什么不同**:int 用 `MEFreeList`,复位时所有逻辑号共享物理 0
  (x0=0 的天然共享,引用计数记账)→ 全 0 映射;fp/vec 用 `StdFreeList(PhyRegs −
  LogicRegs)`——freelist 只管理超出逻辑数的那部分物理号,复位时逻辑 i 必须占住
  物理 i(恒等映射),freelist 从第 N 号起发放。
- **`HAS_NEED_FREE` 仅 int**:move elimination 引用计数只在整数域做
  (见 RenameTableWrapper.md §3.4);变体 golden 没有该输出与寄存器,
  参数关掉时用 generate 完全不例化(避免 impl-only 死寄存器)。
- **difftest 表差异**:难点在 vec——v0 的真值在 v0Rat,vec 真值表只覆盖逻辑号
  1..31(`DIFF_BASE=1`,31 项),`diff_rdata[e]` 对应逻辑号 `1+e`。
  difftest 表独立于 spec/arch 表(无旁路、提交直写),项数是**体系结构寄存器数**
  而非表项数,故 fp 是 32 而不是 34。

## 3. 值得注意的结构退化(单项表 _3)

`NUM_ENTRY=1` 时 golden 没有 addr 端口,读/写恒作用 entry 0,命中判断只看 wen;
firtool 顺势删掉了 `t1_raddr` / `t1_wSpec_addr` 两组地址寄存器。参数核用
`generate if (NUM_ENTRY==1)` 走同样的退化分支(不例化地址寄存器),
保证与 golden 形状一致。这展示了参数化重写的一个通用原则:**参数极端值引起的
结构消失也要在 generate 层面复现**,否则多出的恒 0 寄存器就是 impl-only 差异。

另一个 FM 相关细节:当 `2^ADDR_W > NUM_ENTRY`(fp 64>34、vec 64>47),
按地址读表处用"遍历 entry 比较地址、默认取 [0]"的显式 mux 复刻 golden 的读 LUT
语义(越界地址落到 entry 0),不用动态下标——既是位级对齐,也绕开工具对越界
索引的硬报错。

## 4. 验证状态

三变体独立签核:UT seed 1/7/42 各 checks 200000 errors=0(双例化 golden
`RenameTable_N` vs `RenameTable_N_xs`,含 spec/arch 表层次探针);
FM strict SUCCEEDED(0 failing / 0 unmatched / 0 unread,SnapshotGenerator_{5,6,7}
两侧对称黑盒)。基版 + 三变体全部通过后,`RenameTableWrapper` 的 assembly
依赖闭包已闭合。
