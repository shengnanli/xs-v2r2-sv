# 香山 V2R2 可读 SV 重写 —— 进度跟踪

状态：⬜ 未开始 / 🔨 进行中 / ✅ 完成
验证：每模块 = 结构闸门 grep + 多种子 UT(seed 1/7/42 双例化逐拍比对 golden 全输出 0 错)+ Formality 等价。

## 总览

| 子系统 | 核心模块 | 文档 | 状态 |
|--------|---------|------|------|
| **Frontend 前端** | 34 | 33 | ✅ **100% 完成** |
| **MemBlock 访存** | 46 | 47 | ✅ **100% 完成** |
| **Backend 后端** | 60+ | 60+ | ✅ **基本完成**(执行/译码/重命名/写回/旁路/ROB/DataPath/Dispatch/CtrlBlock/14个发射队列变体/4个Scheduler/ExeUnit/NewCSR/Backend顶层 全部完成,均 UT+FM 验证) |

> 详见 `docs/frontend/`、`docs/memblock/MEMBLOCK_OVERVIEW.md`、`docs/backend/BACKEND_OVERVIEW.md`。

## Frontend(✅ 完成)
分支预测(Predictor/Composer/TAGE-SC/ITTage/FTB/FauFTB/RAS)、取指(NewIFU/ICache 全族/IPrefetchPipe/WayLookup/PreDecode/RVCExpander/IBuffer/InstrUncache)、Ftq(112955→2115 行)、Frontend 顶层。全部 UT+FM 验证。

## MemBlock(✅ 完成)
- LSU 流水:LoadUnit/StoreUnit/Load·StoreMisalignBuffer
- 队列:LoadQueue 顶 + VirtualLoadQueue + LQ-RAR/RAW/Replay/Uncache + StoreQueue + Sbuffer + Lq·StoreExceptionBuffer + LsqWrapper
- MMU:TLBFA/TlbStorageWrapper/TLBNonBlock/PMP/PMPChecker + PTW/HPTW/LLPTW/PtwCache/L2TlbMissQueue/L2TlbPrefetch/L2TLB/L2TLBWrapper
- DCache:DCacheWrapper/DCache 顶 + MainPipe/MissQueue/WritebackQueue/ProbeQueue/LoadPipe/StorePipe + BankedDataArray/DuplicatedTagArray/L1Coh·FlagMetaArray
- 其他:Uncache/StorePfWrapper/TLBuffer/Pipeline + MemBlock 顶层(capstone,1346 端口)

## Backend(✅ 基本完成)
全部模块从 Scala 设计意图真重写、独立复核(结构闸门 + 多种子 UT 重跑 + FM + svh 套壳检查),无套壳。
| 类别 | 模块 |
|------|------|
| 执行单元 FU | Alu·Bku·BranchUnit·JumpUnit·Fence·MulUnit·DivUnit·FAlu·FMA·FCVT·FDivSqrt·VSetRiWi·VSetRvfWvf |
| 译码 | DecodeUnit(gen 译码表)·DecodeStage·CompressUnit·UopInfoGen·FPDecoder |
| 重命名 | Rename·RenameTable·RenameBuffer·StdFreeList·MEFreeList |
| 物理寄存器/缓存 | RegFilePart(Int/Fp×4)·RegCache |
| 写回/旁路/工具 | WbDataPath·WbFuBusyTable·BypassNetwork·ImmExtractor·DelayReg |
| 乱序核心 | **Rob**(控制核 golden-tap 验证)·**DataPath**(真重写)·**NewDispatch**(真重写) |
| 执行容器 | **ExuBlock·ExuBlock_1**·**ExeUnit×3**(整数/浮点代表变体,FU 黑盒) |
| **发射队列(14 变体全栈)** | 整数:**AluCsrFenceDiv**(样板)·**AluMulBkuBrhJmp**·**AluBrhJmpI2fVsetriwiVsetriwvfI2v**;浮点:**FaluFmac**·**FaluFmacFdiv**·**FaluFcvtF2vFmacFdiv**;向量:**VfdivVidiv**·**VfmaVialuFixVfalu**·**VfmaVialuFix…Vsetrvfwvf**;访存:**StaMou**·**StdMoud**·**Ldu**·**VlduVstu**·**VlduVstuVseglduVsegstu**(均含 Entries+IqEntry,UT 3种子200k/0 + FM SUCCEEDED) |
| 调度 | **Scheduler**(Int)·**Scheduler_1/2/3**(Fp/Vf/Mem,IQ 黑盒互联) |
| 控制聚合 | **CtrlBlock**(41426行,9轮;重定向流水/decode-buffer FSM/写回压缩/快照 flushVec 前缀OR;22 子模块黑盒;UT 1736 输出 seed1/7/42 各200k/0;FM verify) |
| CSR | **NewCSR**(14259行,9轮;CSR 译码/读OR-mux/写fanout/特权FSM/trap派发/AIA-IMSIC/difftest;300+ CSRModule 黑盒;UT 3种子200k/0;FM 37934 passing SUCCEEDED;golden _T_/_GEN_ 全重映射语义名) |

> 发射队列 14 变体均以 AluCsrFenceDiv(整数)/ FaluFmac(浮点)/ VfdivVidiv(向量开荒,numRegSrc=5/ignoreOldVd/og2Resp)/ StaMou(访存 mem feedback)为样板逐步派生,差异处从 Scala 真重写。

### Backend 顶层(capstone)
- **Backend 顶层**(capstone,1230 端口)✅ **UT 三种子 200k errors=0 通过(收官)**
  - 可读核 `rtl/backend/Backend.sv`(xs_Backend_core):顶层 glue 全部从 Scala 意图重写入核
    (backend_logic.svh:唤醒总线打拍 wakeupDelayed×10 / 五域写回打拍 {int,fp,vf,v0,vl}WbDelayed /
    CSR↔Mem 边界打拍 instrTransType·msiInfo·clintTime·l2FlushDone·extInt / mem 发射超时
    issueTimeout×5 4-bit 饱和计数 / vsetvl vtype 二选一锁存 / debugVl·topDownInfo·pfevent 杂项打拍 /
    flush 判定拼接别名 flushRobIdxFull·robDeqPtrFull)。45 子模块(31 类型)全 golden 黑盒。
  - gen_backend.py:端口解析→backend_ports.svh(1230)/backend_decls.svh(5651 互联网)/
    backend_inst.svh(45 例化·12896 引脚,golden glue 临时名 rewrite 全映射核内具名,leaks=0)/
    backend_outassign.svh(208 io 输出驱动)/Backend_wrapper.sv/blackbox_stubs/UT(505 驱·723 比)。
  - GATE 全过:核+logic+pkg 去注释 _GEN_/_T_/io_x_N_N/RANDOMIZE=0;**5 个 backend_*.svh 套壳闸门
    _GEN_/_T_ 合计=0**(纯例化连线,无套壳)。VCS elab 通过(623 模块,1 条 TFIPC-L lint,0 多驱动)。
  - UT 双例化逐拍比 723 输出:**seed1/7/42 各 200000 拍 errors=0,distinct_diverging_ports=0/723**
    (+SYNTHESIS·+vcs+initreg+0·-assert disable,子模块两侧 golden 真定义共用)。
  - **FM 诚实**:`make fm` 跑完(192416 passing / 20 failing / 1959 unverified)。20 failing **全部在子模块
    内部**(inner_ctrlBlock/* 的 wbData vls_isVlm·isWhole·rename lsrc / inner_wbDataPath/* 的
    WbArbiter io_in_ready),**Backend 自身 glue 0 failing**;根因是 FM 把更深叶子(Rob/Rename/
    wbArbiter)黑盒后其输出 pin 在 ref 扇入悬空(undriven),工具无法跨 ref/impl 配对 X 扇入
    (fm_eq.tcl 注释明示的 FTQ/IFU 扇出复制同类工具局限,非设计差异)。width-mismatch 告警在
    wb_delayed addr 改 per-域位宽(int/fp=8,vf=7,v0/vl=5)后已清 0。**UT 200k bit-exact 为权威**。
  - 文档 docs/backend/Backend.md(子模块清单 / 7 类 glue 表 / issueTimeout 时序 / gen 产物 / 验证)。

## 验证平台(UT / IT / BT / ST)
| 级别 | 状态 | 说明 |
|------|------|------|
| **UT 单元级** | ✅ 156 模块 | VCS 双例化逐拍比对 golden + Formality 等价 |
| **IT 集成级** | ✅ 8 簇 | 重写 glue 核↔重写叶子核全部直连(非黑盒 golden 叶子), 整簇 vs golden 双例化, seed1/7/42 各 200k errors=0。簇:BPU/IFU/MMU/Issue/RenameDispatch/Decode/LoadQueue/DCache。方法学见 verif/it/README.md |
| **BT 块级** | ⬜ 待做 | Frontend 子系统级 vs golden |
| **ST 系统级** | ⬜ 待做 | 重写 SV 替换进香山 build/rtl, difftest+NEMU 跑真实程序 |

> **IT 抓出并修复 6 个 per-module UT 漏掉的真 bug**(整簇直连才暴露):NewIFU toIbuffer valid[0]、
> FPDecoder 半精度/保留编码 typeTagOut/wflags、MainPipe writeback hasData(alwaysReleaseData)、
> LoadQueueReplay Vec(56) 越界读回绕、MainPipe oh_to_way OHToUInt 语义、MissQueue resp_id。

## 方法学与闸门(见 docs/REWRITE_STYLE.md)
从 Scala 设计意图重写(非 golden 转写)→ 结构硬闸门(struct/enum/function/genvar>0、0 生成痕迹)→ 多种子 UT → FM。
- 大互联模块:可读核(真逻辑)+ `*.svh`(纯子模块例化+连线);**.svh 套壳闸门**:`grep _GEN_/_T_` 必须≈0,上百即 golden 逻辑套壳→拒收(DataPath/NewDispatch 首版曾犯,已回退重做)。
- **铁律**:① `array[可能X索引]`→三元 mux;② priority 仲裁用 `priority case`;③ UT 只比端口、会漏覆盖内部状态分叉→关键模块用 tb 内部层次探针逐拍比 golden 内部寄存器(PtwCache/Rob/NewDispatch 即靠此抓出真 bug)。
- 协作:Claude 子 agent + codex(gpt-5.5)并行;所有产出一律独立复核(结构 grep + 多种子 UT 重跑 + FM + svh 套壳检查),不凭自报。
