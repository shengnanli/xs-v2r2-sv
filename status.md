# 香山 V2R2 可读 SV 重写 —— 进度跟踪

状态：⬜ 未开始 / 🔨 进行中 / ✅ 完成
验证：每模块 = 结构闸门 grep + 多种子 UT(seed 1/7/42 双例化逐拍比对 golden 全输出 0 错)+ Formality 等价。

## 总览

| 子系统 | 核心模块 | 文档 | 状态 |
|--------|---------|------|------|
| **Frontend 前端** | 34 | 33 | ✅ **100% 完成** |
| **MemBlock 访存** | 46 | 47 | ✅ **100% 完成** |
| **Backend 后端** | 33+ | 34 | 🔨 进行中(执行/译码/重命名/写回/旁路/ROB/DataPath/Dispatch 已完成；发射调度/CSR/顶层待做) |

> 详见 `docs/frontend/`、`docs/memblock/MEMBLOCK_OVERVIEW.md`、`docs/backend/BACKEND_OVERVIEW.md`。

## Frontend(✅ 完成)
分支预测(Predictor/Composer/TAGE-SC/ITTage/FTB/FauFTB/RAS)、取指(NewIFU/ICache 全族/IPrefetchPipe/WayLookup/PreDecode/RVCExpander/IBuffer/InstrUncache)、Ftq(112955→2115 行)、Frontend 顶层。全部 UT+FM 验证。

## MemBlock(✅ 完成)
- LSU 流水:LoadUnit/StoreUnit/Load·StoreMisalignBuffer
- 队列:LoadQueue 顶 + VirtualLoadQueue + LQ-RAR/RAW/Replay/Uncache + StoreQueue + Sbuffer + Lq·StoreExceptionBuffer + LsqWrapper
- MMU:TLBFA/TlbStorageWrapper/TLBNonBlock/PMP/PMPChecker + PTW/HPTW/LLPTW/PtwCache/L2TlbMissQueue/L2TlbPrefetch/L2TLB/L2TLBWrapper
- DCache:DCacheWrapper/DCache 顶 + MainPipe/MissQueue/WritebackQueue/ProbeQueue/LoadPipe/StorePipe + BankedDataArray/DuplicatedTagArray/L1Coh·FlagMetaArray
- 其他:Uncache/StorePfWrapper/TLBuffer/Pipeline + MemBlock 顶层(capstone,1346 端口)

## Backend(🔨 进行中)
**✅ 已完成(33 模块)**
| 类别 | 模块 |
|------|------|
| 执行单元 FU | Alu·Bku·BranchUnit·JumpUnit·Fence·MulUnit·DivUnit·FAlu·FMA·FCVT·FDivSqrt·VSetRiWi·VSetRvfWvf |
| 译码 | DecodeUnit(gen 译码表)·DecodeStage·CompressUnit·UopInfoGen·FPDecoder |
| 重命名 | Rename·RenameTable·RenameBuffer·StdFreeList·MEFreeList |
| 物理寄存器/缓存 | RegFilePart(Int/Fp×4)·RegCache |
| 写回/旁路/工具 | WbDataPath·WbFuBusyTable·BypassNetwork·ImmExtractor·DelayReg |
| 乱序核心 | **Rob**(控制核 golden-tap 验证)·**DataPath**(真重写,逻辑入核)·**NewDispatch**(真重写) |

**⏳ 待做**
- 发射/调度:Scheduler×4、IssueQueue×N、Entries×N(唤醒-选择,最复杂)
- 执行容器:ExuBlock×3、ExeUnit
- 控制聚合:CtrlBlock
- CSR:NewCSR(14k 行)
- **Backend 顶层**(capstone,1230 端口)

## 方法学与闸门(见 docs/REWRITE_STYLE.md)
从 Scala 设计意图重写(非 golden 转写)→ 结构硬闸门(struct/enum/function/genvar>0、0 生成痕迹)→ 多种子 UT → FM。
- 大互联模块:可读核(真逻辑)+ `*.svh`(纯子模块例化+连线);**.svh 套壳闸门**:`grep _GEN_/_T_` 必须≈0,上百即 golden 逻辑套壳→拒收(DataPath/NewDispatch 首版曾犯,已回退重做)。
- **铁律**:① `array[可能X索引]`→三元 mux;② priority 仲裁用 `priority case`;③ UT 只比端口、会漏覆盖内部状态分叉→关键模块用 tb 内部层次探针逐拍比 golden 内部寄存器(PtwCache/Rob/NewDispatch 即靠此抓出真 bug)。
- 协作:Claude 子 agent + codex(gpt-5.5)并行;所有产出一律独立复核(结构 grep + 多种子 UT 重跑 + FM + svh 套壳检查),不凭自报。
