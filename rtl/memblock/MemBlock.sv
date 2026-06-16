// ============================================================================
// xs_MemBlock_core —— 访存子系统总集成（香山 V2R2 昆明湖，全工程 capstone）
// ----------------------------------------------------------------------------
// 设计意图来源：src/main/scala/xiangshan/mem/MemBlock.scala
//   （class MemBlockInlined / MemBlockInlinedImp，外层 MemBlock / MemBlockImp）
//
// MemBlock 是整个访存子系统的**顶层互联 glue**：后端把访存指令（load / store /
// atomic / 向量访存）发到这里，MemBlock 负责把它们路由到各功能单元，并在单元之间
// 做仲裁、互联、异常聚合、CSR/触发器分发与性能汇聚。它本身**不含访存算法**——
// 所有“真正的逻辑”都在子模块里，对本层是黑盒（UT/FM 两侧共用同一份 golden 子模块）。
//
// ---------------------------------------------------------------------------
// 一、本层把哪些功能单元组装在一起（按数据流分组）
// ---------------------------------------------------------------------------
//  执行流水（LSU 心脏）：
//    LoadUnit ×3       —— load 执行流水：查 DTLB → 访 DCache → 从 SQ/SBuffer forward
//                         → miss 时进 LoadQueueReplay 重放；产出 ldout / rollback。
//    StoreUnit ×2      —— store 地址流水：算地址、查 DTLB/PMP、写 StoreQueue。
//    MemExeUnit ×2     —— store 数据流水（stdExeUnit）：把 store 数据写 StoreQueue。
//    AtomicsUnit ×1    —— 原子指令（LR/SC/AMO）执行。
//  向量访存：
//    VLSplitImp ×2 / VSSplitImp ×2 —— 向量 load/store 拆成多个元素访存。
//    VLMergeBufferImp / VSMergeBufferImp ×2 —— 元素结果合并回向量寄存器。
//    VSegmentUnit / VfofBuffer —— 段访存 / fault-only-first 缓冲。
//    LoadMisalignBuffer / StoreMisalignBuffer —— 非对齐访存拆分缓冲。
//  队列与缓存：
//    LsqWrapper ×1     —— Load/Store 队列层（LoadQueue + StoreQueue + 违例/重放）。
//    Sbuffer ×1        —— store 写合并缓冲（提交后的 store 攒够再写 DCache）。
//    DCacheWrapper ×1  —— L1 数据缓存（MainPipe/MissQueue/WBQueue/Meta/Data/...）。
//    Uncache ×1        —— 非缓存 / MMIO 访问（TileLink）。
//  地址翻译：
//    TLBNonBlock ×3    —— 数据侧 DTLB：load(4 路) / store(2 路) / prefetch(2 路)。
//    PMP ×1 + PMPChecker ×8 —— 物理内存保护：每个 DTLB 端口一个 checker。
//    L2TLBWrapper ×1   —— 共享 MMU（页表遍历器 PTW + page cache）；前端 ITLB 也回这里。
//    PTWNewFilter / PTWRepeaterNB —— DTLB→L2TLB 的 miss 过滤 / 重发。
//  预取：
//    SMSPrefetcher / L1Prefetcher —— 空间/步长预取器。
//  TileLink 互联与杂项：
//    TLBuffer ×N / TLXbar —— TileLink 缓冲与交叉开关。
//    Pipeline / NewPipelineConnectPipe / DelayN / PipelineRegModule —— 打拍/连接。
//    PFEvent / HPerfMonitor / MBIST —— 性能事件 / 内建自测。
//
// ---------------------------------------------------------------------------
// 二、本层手写的“顶层 glue”有哪些（少量真正的顶层逻辑）
// ---------------------------------------------------------------------------
// 绝大多数端口是“后端/上游 ↔ 子模块 ↔ 下游”的**直通连线 + 简单仲裁/选择**。本层
// 真正属于“顶层逻辑”的只有几类（都在 memblock_logic.svh 的 assign/always 里）：
//   1) CSR / 触发器（debug trigger）分发：tdata_0..3（matchType/select/timing/action/
//      tdata2 等）从 CSR 接口寄存后广播给各 LoadUnit/StoreUnit 做断点匹配。
//   2) prefetch enable 链：l1D/SMS/L1Prefetcher 的 enable / 阈值 / 步长从 CSR
//      经两级寄存器（_next_r / _next_r_1）打拍后送预取器（降长扇出、跨时序）。
//   3) 异常聚合：atomics / vSegment 等异常与 LSQ/各单元异常汇聚成对 ROB 的异常报告
//      （inner_atomicsException / inner_vSegmentException / inner__probe_* 等）。
//   4) redirect / robIdx 比较：把后端 redirect 打一拍后广播给各单元做冲刷。
//   5) uncache / mmio 写回仲裁（mmioStout vs cboZeroStout 等）。
//   6) perf 汇聚：各单元性能事件经 PFEvent/HPerfMonitor 汇聚后两级寄存输出 io_perf_*。
//
// ---------------------------------------------------------------------------
// 三、为何机械互联拆进 .svh
// ---------------------------------------------------------------------------
// 这是 1346 端口 / 71 实例 / ~5300 内部网 / 326 assign 的巨型扁平互联——它的
// “可读性”体现在**架构讲解**（本文件注释 + docs/memblock/MemBlock.md）而非把五千多条
// 机械连线手工改名（那既无学习价值又极易出错）。故按工程既定先例（LoadQueue /
// LsqWrapper）：把信号声明 / 连线 / 实例端口表机械保留到 .svh（仅剥离 firtool 的
// 随机化与 assert 样板，不改写任何逻辑），由本可读核 `include；阅读时以本文件与
// 文档的分节讲解为脉络，对照 .svh 里的具体连线。
//
//   memblock_ports.svh —— 端口表（与 golden 同名扁平端口）
//   memblock_nets.svh  —— 内部互联网声明（子模块输出网 / 流水寄存器 / CSR 副本）
//   memblock_logic.svh —— 顶层 assign + always（路由/仲裁/异常聚合/CSR 分发/perf）
//   memblock_inst.svh  —— 71 个子模块实例（全部 golden 黑盒）
//
// 验证：UT 与 golden MemBlock 双例化逐拍比对全部 594 路输出（两侧共用 golden 子模块）；
//       FM 以全部子模块为黑盒、对本层互联 glue 做签名等价。详见 docs/memblock/MemBlock.md。
// ============================================================================
module xs_MemBlock_core
  import memblock_pkg::*;
(
  `include "memblock_ports.svh"
);

  // ==========================================================================
  // 1. 内部互联网声明
  // --------------------------------------------------------------------------
  // 子模块输出网（_inner_<unit>_io_*）、顶层流水寄存器（inner_*_REG / _next_r）、
  // CSR/触发器副本（inner_tdata_*）等。这些网是“各单元如何互联 / 顶层如何寄存”的
  // 载体；命名沿用 golden 的层次名（inner_ = 顶层逻辑网，_inner_ = 子模块输出网），
  // 便于与 docs 中的分节讲解一一对照。
  // ==========================================================================
  `include "memblock_nets.svh"

  // ==========================================================================
  // 2. 顶层组合 / 时序 glue
  // --------------------------------------------------------------------------
  // assign：端口路由 / 仲裁选择 / 异常聚合 / 单元间互联。
  // always：① CSR/触发器分发与 prefetch enable 两级打拍（带复位初值，
  //            如 act_threshold=0xC / act_stride=0x1E）；
  //         ② redirect 寄存、loadPc 训练打拍等。
  // 见各 always 块内的 inner_*_REG / _next_r 命名与 docs/memblock/MemBlock.md §CSR分发。
  // ==========================================================================
  `include "memblock_logic.svh"

  // ==========================================================================
  // 2b. 性能事件（perf）输出：8 路 × 2 级流水（从机械 glue 抬出，可读实现）
  // --------------------------------------------------------------------------
  // HPerfMonitor 汇聚出 PERF_OUT_NUM 路事件计数（perf_src[i]，由 memblock_perf_src.svh
  // 从子模块输出网映射），各打两拍对齐后接到 io_perf_*，降低长扇出对时序的影响
  // （与 DCacheWrapper / LsqWrapper 的 perf 同一做法）。用 perf_cnt_t 数组 + genvar 表达，
  // 取代 golden 展平的逐路标量寄存链。
  // ==========================================================================
  perf_cnt_t perf_src   [PERF_OUT_NUM];
  perf_cnt_t perf_stage1[PERF_OUT_NUM];
  perf_cnt_t perf_stage2[PERF_OUT_NUM];

  `include "memblock_perf_src.svh"  // assign perf_src[i] = _inner_perfEvents_hpm_io_perf_i_value;

  for (genvar i = 0; i < PERF_OUT_NUM; i++) begin : g_perf
    always_ff @(posedge clock) begin
      perf_stage1[i] <= perf_src[i];
      perf_stage2[i] <= perf_stage1[i];
    end
  end

  `include "memblock_perf_out.svh"  // assign io_perf_<i>_value = perf_stage2[i];

  // ==========================================================================
  // 3. 子模块实例（71 个，全部 golden 黑盒）
  // --------------------------------------------------------------------------
  // 各功能单元的算法在子模块内部；本层只把它们的端口接到上面的互联网 / 顶层端口。
  // 直通端口连顶层同名口，单元间互联连 _inner_* 网。UT/FM 两侧共用同一份 golden 定义。
  // ==========================================================================
  `include "memblock_inst.svh"

endmodule
