# docs/backend 学习导航

香山 V2R2（昆明湖）**后端（Backend）** 的职责一句话：**把前端按序送来的指令流乱序地、
但看起来仍然按序地执行掉**。它沿「译码 → 重命名 → 派遣 → 发射 → 读寄存器/旁路 → 执行 →
写回 → 提交」一条主流水推进：重命名消除假相关，四个 Scheduler 挂一批 IssueQueue 做乱序
唤醒-发射，DataPath/BypassNetwork 供操作数，各 FU 并行执行，WbDataPath 仲裁写回，最后
ROB 按序提交保证精确异常，NewCSR 掌管特权与 trap。本目录是逐模块设计文档层；**先读原理、
后读模块**。

## 0. 阅读顺序（先原理后模块）

1. 总入口：[../ARCHITECTURE.md](../ARCHITECTURE.md) —— 整机认知（后端在芯片层次里的位置）。
2. 本目录 `arch/` 原理层（讲 why 与协同，不重复实现细节）：
   - [arch/0-BACKEND_OVERVIEW](arch/0-BACKEND_OVERVIEW.md) —— 后端总览 + 模块索引脉络
   - [arch/1-REQUIREMENTS](arch/1-REQUIREMENTS.md) —— 需求与设计目标（乱序执行要解决什么）
   - [arch/2-RENAME_DISPATCH_PRINCIPLES](arch/2-RENAME_DISPATCH_PRINCIPLES.md) —— 重命名与派遣原理
   - [arch/3-ISSUE_WAKEUP_PRINCIPLES](arch/3-ISSUE_WAKEUP_PRINCIPLES.md) —— 发射与唤醒原理（推测唤醒/取消/年龄仲裁）
   - [arch/4-EXECUTION_WRITEBACK_PRINCIPLES](arch/4-EXECUTION_WRITEBACK_PRINCIPLES.md) —— 执行与写回原理
   - [arch/5-COMMIT_EXCEPTION_CSR_PRINCIPLES](arch/5-COMMIT_EXCEPTION_CSR_PRINCIPLES.md) —— 提交、精确异常与 CSR 原理
   - [arch/6-CONTROL_FLOW_AND_TIMING](arch/6-CONTROL_FLOW_AND_TIMING.md) —— 后端全景流水与控制流回路
3. 再按下面的分组进入各模块文档。

> 说明：各模块文档开头常有「FM 分类 / UT / 验证状态」banner，那是本仓库**可读 SV 重写工程**
> 的等价验证台账记录；学习微架构时可先跳过，机理章节独立成立。

## 1. 模块索引（按流水阶段分组）

### 1.1 译码（Decode）

| 文档 | 一行简介 |
|---|---|
| [DecodeStage](DecodeStage.md) | 译码级顶层：6 路并行 DecodeUnit + 复杂指令拆分 + VTypeGen，流水控制 |
| [DecodeUnit](DecodeUnit.md) | 单指令译码器：32 位指令（已 RVC 展开）→ 一条 uop 的控制信息 DecodedInst |
| [FusionDecoder](FusionDecoder.md) | 宏融合译码器：5 个相邻指令对做 28 种融合模式匹配，命中则合并成单 uop |
| [FPDecoder](FPDecoder.md) | 浮点译码叶子：从指令编码抽 5 个浮点控制位（纯组合） |
| [UopInfoGen](UopInfoGen.md) | 向量/特殊指令的 uop 拆分数目计算（内联真值表，纯组合） |
| [ImmExtractor](ImmExtractor.md) | 压缩立即数还原为 64/128 位真值（位于发射→执行之间，编码定义源自译码 ImmUnion） |

### 1.2 重命名（Rename）

| 文档 | 一行简介 |
|---|---|
| [Rename](Rename.md) | 重命名流水顶层：查 RAT、领物理寄存器、移动消除、对接 ROB/RAB |
| [RenameTable](RenameTable.md) | RAT 寄存器别名表（整数基版）：逻辑 → 物理映射 + spec/arch 双表 |
| [RenameTable_variants](RenameTable_variants.md) | fp / vec / v0,vl 三个 RAT 参数变体（相对基版只写差异） |
| [RenameTableWrapper](RenameTableWrapper.md) | 5 张 RAT 的装配壳：提交/walk 写口的共享派生信号分发（纯 wiring） |
| [StdFreeList](StdFreeList.md) | 标准空闲列表：物理寄存器分配/回收环形队列（浮点等寄存器池） |
| [MEFreeList](MEFreeList.md) | Move-Elimination 空闲列表：整数寄存器池（size=224），支持移动消除 |
| [CompressUnit](CompressUnit.md) | ROB 压缩：连续可压缩指令折叠共享一个 ROB 条目，扩大有效乱序窗口 |
| [RenameBuffer](RenameBuffer.md) | 重命名缓冲（Rab）：暂存重命名记录，提交/回滚时按序更新 arch RAT |

### 1.3 派遣（Dispatch）

| 文档 | 一行简介 |
|---|---|
| [NewDispatch](NewDispatch.md) | 派遣级：按 fuType 把 uop 分类送入各 Scheduler 的 IssueQueue，并登记 ROB/LSQ |
| [MemCtrl](MemCtrl.md) | SSIT/WaitTable（访存依赖预测表）的持有者与更新打拍级 |

### 1.4 发射（Issue / Scheduler）

乱序调度的心脏。**先读样板 [IssueQueueAluCsrFenceDiv](IssueQueueAluCsrFenceDiv.md)**——它
详述条目阵列、双类唤醒（WB/IQ）、推测唤醒与取消、年龄最老仲裁的整套机理；**其余变体文档
只写相对样板的增量**（挂哪些 FU、条目/端口规模、访存反馈或向量特有机制）。

| 文档 | 一行简介 |
|---|---|
| [Scheduler](Scheduler.md) | Int 调度顶层：例化整数 IssueQueue 做互联（本身几乎无算法逻辑） |
| [Scheduler_Fp](Scheduler_Fp.md) | Fp 变体：浮点 IssueQueue 互联 |
| [Scheduler_Vf](Scheduler_Vf.md) | Vf 变体：3 个向量 IssueQueue 互联 |
| [Scheduler_Mem](Scheduler_Mem.md) | Mem 变体：9 个访存 IssueQueue 互联（规模最大） |
| [IssueQueueAluCsrFenceDiv](IssueQueueAluCsrFenceDiv.md) | ★样板★ 整数 IQ（ALU/CSR/Fence/Div）：发射队列机理的完整讲解 |
| [IssueQueueAluMulBkuBrhJmp](IssueQueueAluMulBkuBrhJmp.md) | 整数 IQ 变体：ALU/Mul/Bku/Brh/Jmp |
| [IssueQueueAluBrhJmpI2fVsetriwiVsetriwvfI2v](IssueQueueAluBrhJmpI2fVsetriwiVsetriwvfI2v.md) | 整数侧最大变体：7 类 FU（含 i2f/vset/i2v） |
| [IssueQueueFaluFmac](IssueQueueFaluFmac.md) | 浮点 IQ 变体：FALU/FMAC |
| [IssueQueueFaluFmacFdiv](IssueQueueFaluFmacFdiv.md) | 浮点 IQ 变体：FALU/FMAC/FDIV |
| [IssueQueueFaluFcvtF2vFmacFdiv](IssueQueueFaluFcvtF2vFmacFdiv.md) | 浮点 IQ 变体：+FCVT/F2V |
| [IssueQueueLdu](IssueQueueLdu.md) | 访存 IQ 变体：load 地址（带 load replay 反馈，IO 最多） |
| [IssueQueueStaMou](IssueQueueStaMou.md) | 访存 IQ 变体：store 地址 + 原子/fence 地址（访存样板） |
| [IssueQueueStdMoud](IssueQueueStdMoud.md) | 访存 IQ 变体：store 数据（派生自普通整数 IQ 而非访存子类） |
| [IssueQueueVfdivVidiv](IssueQueueVfdivVidiv.md) | 向量 IQ 开荒变体：向量除法（VFDIV/VIDIV） |
| [IssueQueueVfmaVialuFixVfalu](IssueQueueVfmaVialuFixVfalu.md) | 向量执行 IQ：3 种向量 FU / 双发射 |
| [IssueQueueVfmaVialuFixVimacVppuVfaluVfcvtVipuVsetrvfwvf](IssueQueueVfmaVialuFixVimacVppuVfaluVfcvtVipuVsetrvfwvf.md) | 最大向量执行 IQ：8 种向量 FU / 双发射 |
| [IssueQueueVlduVstu](IssueQueueVlduVstu.md) | 向量访存 IQ：向量 load/store（向量调度 + 访存反馈融合） |
| [IssueQueueVlduVstuVseglduVsegstu](IssueQueueVlduVstuVseglduVsegstu.md) | 向量访存 IQ：+ 段（segment）load/store |

### 1.5 执行（Execute / FU）

| 文档 | 一行简介 |
|---|---|
| [ExeUnit](ExeUnit.md) | 执行单元包装：把若干 FU 装进一个发射端口的执行簇（输入流水/结果选择） |
| [Alu](Alu.md) | 整数 ALU：加减/逻辑/移位/比较（0 延迟，最常用 FU） |
| [MulUnit](MulUnit.md) | 整数乘法：2 拍定长流水（mul/mulh/mulw…） |
| [DivUnit](DivUnit.md) | 整数除法：多周期迭代（div/rem 及 W 变体），带握手与 flush |
| [Bku](Bku.md) | 位操作/加密单元：B 扩展 + 标量加密指令 |
| [BranchUnit](BranchUnit.md) | 条件分支单元：当拍判方向/算目标，产生重定向 |
| [JumpUnit](JumpUnit.md) | 无条件跳转单元：jal/jalr/auipc（0 延迟） |
| [Fence](Fence.md) | 栅栏单元：fence/fence.i/sfence.vma 的 6 态状态机，向 sbuffer/TLB/ICache 发 flush |
| [FAlu](FAlu.md) | 浮点加/比较/符号注入/分类：1 拍定长流水 |
| [FMA](FMA.md) | 浮点融合乘加：3 拍定长流水（fmadd 族 + fmul） |
| [FCVT](FCVT.md) | 浮点转换：f2i/i2f/f2f/fround…，2 拍定长流水 |
| [FDivSqrt](FDivSqrt.md) | 浮点除/开方：SRT 迭代、唯一非定长浮点 FU（带完整握手与 flush） |
| [VSetRiWi](VSetRiWi.md) | 向量配置单元：vsetvl 类指令算 vl/vtype（读整数写整数变体，含通用原理） |
| [VSetRvfWvf](VSetRvfWvf.md) | 向量配置单元变体：保持 vl 改 vtype、写回 vconfig（只写与 RiWi 的差异） |

### 1.6 数据通路与写回

| 文档 | 一行简介 |
|---|---|
| [DataPath](DataPath.md) | 数据通路：发射后读寄存器堆/RegCache/立即数，把操作数路由给各执行簇 |
| [RegFile](RegFile.md) | 物理寄存器堆分片：Int/Fp 各 4 片的参数化多口寄存器堆 |
| [RegCache](RegCache.md) | 寄存器缓存：小容量缓存最近写回值，省 PRF 读口 |
| [BypassNetwork](BypassNetwork.md) | 旁路网络：执行结果不等写回、直送后续 uop 的源操作数 |
| [WbDataPath](WbDataPath.md) | 写回总枢纽：各 EXU 结果按目标域仲裁抢写回口，写 PRF 并汇报 ROB |
| [WbFuBusyTable](WbFuBusyTable.md) | 写回忙表：按 FU 延迟预约写回口，发射前避免写回冲突 |

### 1.7 提交与特权（Commit / CSR）

| 文档 | 一行简介 |
|---|---|
| [Rob](Rob.md) | 重排序缓冲：160 项按序提交核心，精确异常 + 误预测/异常 walk 回滚 |
| [RenameBuffer](RenameBuffer.md) | （亦见 1.2）提交侧按序把重命名记录释放回 arch RAT |
| [NewCSR](NewCSR.md) | CSR 文件聚合器：300+ CSR 读写、特权态机、trap 派发、AIA/IMSIC |
| [InterruptFilter](InterruptFilter.md) | 中断过滤器：中断优先级解析 + M/HS/VS 委派 + 虚拟中断注入 |
| [DelayReg](DelayReg.md) | 通用延迟 N 拍移位链（difftest 提交信息打拍，Rob 例化） |

### 1.8 顶层装配

| 文档 | 一行简介 |
|---|---|
| [Backend](Backend.md) | 后端最高层总集成（capstone）：45 个子模块实例的互联/流水 glue |
| [CtrlBlock](CtrlBlock.md) | 控制平面：重定向生成、decode→rename→dispatch 流水、ROB 控制、pcMem |

## 2. 建议学习路线

**路线 A —— 沿一条指令的生命周期**（推荐第一遍）：

1. 译码：[DecodeStage](DecodeStage.md) → [DecodeUnit](DecodeUnit.md)（可顺带 [FusionDecoder](FusionDecoder.md)）
2. 重命名：[Rename](Rename.md) → [RenameTable](RenameTable.md) → [StdFreeList](StdFreeList.md) / [MEFreeList](MEFreeList.md)
3. 派遣：[NewDispatch](NewDispatch.md)
4. 发射：[arch/3-ISSUE_WAKEUP_PRINCIPLES](arch/3-ISSUE_WAKEUP_PRINCIPLES.md) →
   [IssueQueueAluCsrFenceDiv](IssueQueueAluCsrFenceDiv.md)（样板）→ [Scheduler](Scheduler.md)
5. 操作数与执行：[DataPath](DataPath.md) → [BypassNetwork](BypassNetwork.md) →
   [ExeUnit](ExeUnit.md) → [Alu](Alu.md)（再挑感兴趣的 FU）
6. 写回：[WbDataPath](WbDataPath.md) → [WbFuBusyTable](WbFuBusyTable.md)
7. 提交：[Rob](Rob.md) → [RenameBuffer](RenameBuffer.md) → [NewCSR](NewCSR.md)

**路线 B —— 控制回路专题**（第二遍，理解误预测/异常怎么收场）：

[arch/6-CONTROL_FLOW_AND_TIMING](arch/6-CONTROL_FLOW_AND_TIMING.md) → [CtrlBlock](CtrlBlock.md)
（重定向的产生与广播）→ [Rob](Rob.md)（异常/walk）→
[arch/5-COMMIT_EXCEPTION_CSR_PRINCIPLES](arch/5-COMMIT_EXCEPTION_CSR_PRINCIPLES.md) →
[NewCSR](NewCSR.md) / [InterruptFilter](InterruptFilter.md)。

**路线 C —— 家族横向对比**（第三遍，看参数化如何覆盖变体）：

IssueQueue 家族（样板 → 整数 → 浮点 → 访存 → 向量变体，见 1.4 表序）、
Scheduler 四变体、RAT 变体（[RenameTable_variants](RenameTable_variants.md)）、
RegFile 8 分片（[RegFile](RegFile.md)）。最后读 [Backend](Backend.md) 看整个后端如何装配。
