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
| 执行容器 | **ExuBlock·ExuBlock_1**(FU 黑盒,frm/error glue) |
| 发射队列 | **IssueQueueAluCsrFenceDiv + EntriesAluCsrFenceDiv + IqEntryAcfd**(乱序唤醒-选择全栈真重写,UT+FM 全过,作其余变体样板) |

**⏳ 待做**
- 发射/调度:其余 9 个 IssueQueue/Entries 变体(有 AluCsrFenceDiv 样板)、Scheduler×4(唤醒/仲裁 glue)
- 执行容器:ExeUnit(各变体)
- 控制聚合:CtrlBlock 🔨 **进行中(基础设施已搭,glue 逻辑核未完成)**
  - 已完成:ctrlblock_pkg.sv(参数/redirect-level/decin-src/融合 commitType enum,vlogan 通过)、
    gen_ctrlblock.py(端口解析→ctrlblock_ports.svh 2520 功能端口与 golden 2522 精确对齐;
    16 类子模块例化枚举,全部外部黑盒:Rob/NewDispatch/DecodeStage/FusionDecoder/
    RenameTableWrapper/Rename/RedirectGenerator/pcMem/MemCtrl/Trace/GPAMem/Snapshot/
    6×PipelineConnectPipe/PipeGroupConnect/DelayN×3)。
  - 待做:可读核 glue 逻辑(重定向流水 s0-s5 / decode-buffer FSM / 写回打拍压缩 /
    快照选择 / frontend flush 路由 / pcMem 命名读口驱动)从 Scala 重实现入核;
    ctrlblock_inst.svh 黑盒例化连线;wrapper/stubs/tb/Makefile;多种子 UT + FM。
    (golden 41426 行中 2610-19294 区是真 CtrlBlock 逻辑含 2599 个 _GEN_/_T_,须重写入核;
     19295-end 是子模块例化区,黑盒。)
- CSR:NewCSR(14k 行)
- **Backend 顶层**(capstone,1230 端口)

## 方法学与闸门(见 docs/REWRITE_STYLE.md)
从 Scala 设计意图重写(非 golden 转写)→ 结构硬闸门(struct/enum/function/genvar>0、0 生成痕迹)→ 多种子 UT → FM。
- 大互联模块:可读核(真逻辑)+ `*.svh`(纯子模块例化+连线);**.svh 套壳闸门**:`grep _GEN_/_T_` 必须≈0,上百即 golden 逻辑套壳→拒收(DataPath/NewDispatch 首版曾犯,已回退重做)。
- **铁律**:① `array[可能X索引]`→三元 mux;② priority 仲裁用 `priority case`;③ UT 只比端口、会漏覆盖内部状态分叉→关键模块用 tb 内部层次探针逐拍比 golden 内部寄存器(PtwCache/Rob/NewDispatch 即靠此抓出真 bug)。
- 协作:Claude 子 agent + codex(gpt-5.5)并行;所有产出一律独立复核(结构 grep + 多种子 UT 重跑 + FM + svh 套壳检查),不凭自报。
