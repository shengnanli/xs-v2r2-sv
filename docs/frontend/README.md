# docs/frontend 学习导航

香山 V2R2（昆明湖）**前端（Frontend）** 的职责一句话：**猜好控制流，把指令流稳定地供给后端**。
BPU 用多级预测器（uFTB → FTB → TAGE-SC / ITTAGE / RAS）每拍产出一个「取指块」预测；FTQ
把预测排成队列，同时充当预测、取指、纠错、训练四方的枢纽；IFU 配合 ICache 把指令取回、
切分、预译码；最后经 IBuffer 与后端解耦。本目录是逐模块设计文档层；**先读原理、后读模块**。

## 0. 阅读顺序（先原理后模块）

1. 总入口：[../ARCHITECTURE.md](../ARCHITECTURE.md) —— 整机认知（前端在芯片层次里的位置）。
2. 本目录 `arch/` 原理层（讲 why 与协同，不重复实现细节）：
   - [arch/0-FRONTEND_OVERVIEW](arch/0-FRONTEND_OVERVIEW.md) —— 前端总览 + 模块索引脉络
   - [arch/1-REQUIREMENTS](arch/1-REQUIREMENTS.md) —— 需求与设计目标（为什么前端长成这样）
   - [arch/2-BPU_PRINCIPLES](arch/2-BPU_PRINCIPLES.md) —— 分支预测原理（各预测器如何协同）
   - [arch/3-ICACHE_FETCH_PRINCIPLES](arch/3-ICACHE_FETCH_PRINCIPLES.md) —— 取指与指令缓存原理
   - [arch/4-CONTROL_FLOW_AND_TIMING](arch/4-CONTROL_FLOW_AND_TIMING.md) —— 控制流回路与流水时序
   - [arch/5-DATA_STRUCTURES](arch/5-DATA_STRUCTURES.md) —— 跨模块关键数据结构（FTB 条目/折叠历史/环形指针…）
3. 再按下面的分组进入各模块文档。

> 说明：各模块文档开头常有「FM 分类 / UT / 验证状态」banner，那是本仓库**可读 SV 重写工程**
> 的等价验证台账记录；学习微架构时可先跳过，机理章节独立成立。

## 1. 模块索引（按数据流分组）

### 1.1 分支预测（BPU）

预测器按「快而糙 → 慢而准」逐级覆盖：s1 出 uFTB，s2/s3 用 FTB/TAGE/ITTAGE/RAS 修正。

| 文档 | 一行简介 |
|---|---|
| [Predictor](Predictor.md) | BPU 顶层：多级覆盖式预测流水（s1/s2/s3），管理分支历史与对 FTQ 的握手/冲刷 |
| [Composer](Composer.md) | 预测器组合器：把 5 个子预测器串成组合链，meta 拼接 / perf 对齐 / s1_ready 汇聚 |
| [FauFTB](FauFTB.md) | uFTB：微型全相联 FTB，s1 级一拍出结果的快速预测 |
| [FauFTBWay](FauFTBWay.md) | uFTB 的单路：条目寄存器 + tag 比较 + 更新查询写旁路 |
| [FTB](FTB.md) | 大容量组相联 FTB 顶层：s2 级给出更准的取指块预测（覆盖 uFTB） |
| [FTBBank](FTBBank.md) | FTB 的 SRAM bank（4 路 × 512 组，SplittedSRAM 存储） |
| [FTBEntryGen](FTBEntryGen.md) | 训练回路：按预测/执行结果生成要写回 FTB 的新条目（目标压缩、插槽修正） |
| [Tage_SC](Tage_SC.md) | TAGE-SC 条件分支方向预测器顶层（标签表命中选择 + 统计校正） |
| [TageTable](TageTable.md) | TAGE 的单张几何历史长度标签表（折叠历史索引/tag，4 变体） |
| [TageBTable](TageBTable.md) | TAGE 基预测器：PC 直接索引的 2bit 饱和计数器表（bimodal） |
| [SCTable](SCTable.md) | SC 统计校正器的一张计数表（按方向分组的带符号计数器） |
| [ITTage](ITTage.md) | ITTAGE 间接跳转目标预测器顶层（jalr/虚函数派发的目标预测） |
| [ITTageTable](ITTageTable.md) | ITTAGE 的单张标签表（存完整跳转目标，5 变体） |
| [RAS](RAS.md) | 返回地址栈：推测栈+提交栈双栈、环形指针、push/pop 与重定向恢复 |
| [WrBypass](WrBypass.md) | 各预测器表共用的更新写旁路缓冲（CAM + PLRU），吸收 SRAM 多拍写延迟 |

### 1.2 取指主流水（FTQ → IFU → IBuffer）

| 文档 | 一行简介 |
|---|---|
| [Ftq](Ftq.md) | 取指目标队列：BPU 与 IFU 之间的桥梁，也是重定向纠错与预测器训练的中心枢纽 |
| [FtqPcMemWrapper](FtqPcMemWrapper.md) | FTQ 的 PC 元信息存储包装：把宽 PC 字段隔离进专用多口存储，压扇出 |
| [NewIFU](NewIFU.md) | 取指主控 IFU：F0–F3 流水，接 ICache 数据、切指令、预译码、预测检查 |
| [PreDecode](PreDecode.md) | 取指包预解码：未对齐半字流的 RVC 边界检测 + 指令切分 + 分支信息（纯组合） |
| [F3Predecoder](F3Predecoder.md) | F3 级对 16 条已对齐指令并行译出 brType/isCall/isRet（纯组合） |
| [RVCExpander](RVCExpander.md) | RVC 压缩指令展开器：16 位 → 32 位统一编码（RV64GC + Zcb） |
| [IBuffer](IBuffer.md) | 指令缓冲：前端 → 后端的解耦 FIFO，每拍最多 6 条供译码 |

### 1.3 ICache（L1 指令缓存）

先读顶层 [ICache](ICache.md) 建立组装关系，再进各功能单元。

| 文档 | 一行简介 |
|---|---|
| [ICache](ICache.md) | 指令缓存顶层：把 8 个功能单元组装成 L1 ICache（预取/主流水双流水结构） |
| [ICacheMainPipe](ICacheMainPipe.md) | 主流水：用 WayLookup 给的 waymask 读 data SRAM、ECC 校验、返数据给 IFU |
| [ICacheMetaArray](ICacheMetaArray.md) | meta（tag + valid）阵列：查命中路 |
| [ICacheDataArray](ICacheDataArray.md) | 数据阵列：cacheline 数据存储（分 bank） |
| [ICacheMissUnit](ICacheMissUnit.md) | miss 处理单元：MSHR + TileLink refill 回填 |
| [ICacheReplacer](ICacheReplacer.md) | 路替换器：256 set × 4 way 的树形伪 LRU |
| [ICacheCtrlUnit](ICacheCtrlUnit.md) | ECC 控制/错误注入旁路单元（验证 ECC 检错-纠错-上报通路） |
| [WayLookup](WayLookup.md) | IPrefetch → MainPipe 之间的 way 查询结果解耦 FIFO（含 gpf 全局单份优化） |
| [IPrefetchPipe](IPrefetchPipe.md) | 预取流水：提前查 iTLB / meta SRAM，把命中信息压入 WayLookup |
| [InstrUncache](InstrUncache.md) | MMIO 取指：单条目 4 态 FSM 经 TileLink Get 取指令，不进 ICache |

### 1.4 顶层装配

| 文档 | 一行简介 |
|---|---|
| [Frontend](Frontend.md) | 前端总顶层：装配 BPU/FTQ/IFU/ICache/IBuffer + iTLB/跨级打拍 glue |

## 2. 建议学习路线

**路线 A —— 沿一次取指的生命周期**（推荐第一遍）：

1. 预测产出：[Predictor](Predictor.md) → [Composer](Composer.md) → [FauFTB](FauFTB.md) →
   [FTB](FTB.md) → [Tage_SC](Tage_SC.md) → [ITTage](ITTage.md) → [RAS](RAS.md)
2. 排队与供给：[Ftq](Ftq.md)（+ [FtqPcMemWrapper](FtqPcMemWrapper.md)）
3. 缓存与取回：[ICache](ICache.md) → [IPrefetchPipe](IPrefetchPipe.md) →
   [WayLookup](WayLookup.md) → [ICacheMainPipe](ICacheMainPipe.md)（miss 时 [ICacheMissUnit](ICacheMissUnit.md)）
4. 切分与交付：[NewIFU](NewIFU.md) → [PreDecode](PreDecode.md) / [RVCExpander](RVCExpander.md) /
   [F3Predecoder](F3Predecoder.md) → [IBuffer](IBuffer.md)

**路线 B —— 训练与纠错回路**（第二遍，理解预测器怎么变准）：

[Ftq](Ftq.md)（提交/误预测触发训练）→ [FTBEntryGen](FTBEntryGen.md)（生成新 FTB 条目）→
[TageTable](TageTable.md) / [TageBTable](TageBTable.md) / [SCTable](SCTable.md) /
[ITTageTable](ITTageTable.md)（各表更新）→ [WrBypass](WrBypass.md)（更新写旁路）。

**路线 C —— 存储结构专题**：[FTBBank](FTBBank.md)、[ICacheMetaArray](ICacheMetaArray.md) /
[ICacheDataArray](ICacheDataArray.md)、[ICacheReplacer](ICacheReplacer.md)，配合
[arch/5-DATA_STRUCTURES](arch/5-DATA_STRUCTURES.md) 的编码原理。
