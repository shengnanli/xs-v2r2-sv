// NewIFU.sv —— 取指单元 IFU（golden 模块 NewIFU 的重写）
//
// 对应 Chisel: xiangshan.frontend.NewIFU（IFU.scala）。配置（KunminghuV2Config）：
// PredictWidth=16，VAddrBits=50，PAddrBits=48，FtqSize=64，CommitWidth=8，HasCExtension。
//
// 位置：前端 FTQ 与 IBuffer 之间。FTQ 每拍给一个「取指请求」（一个预测块：起始地址 startAddr、
// BPU 预测的下一块地址 nextStartAddr、块内预测跳转位置 ftqOffset），IFU 向 ICache 要数据、切出
// 16 个半字位置的指令、预译码、核对 BPU 的预测，把指令送进 IBuffer，并把预译码结果写回 FTQ
// （发现预测明显错了就同时冲刷自己并让 FTQ 重定向）。
//
// 流水线（每级一个 valid + 一组 RegEnable(上一级 fire) 的数据寄存器）：
//   f0  （组合）接 FTQ 请求；请求同时被 ICache 接走（本模块不出 ICache 请求端口）。
//   f1  算出 16 个位置的 PC 低位（+2i）与切数据用的半字指针 cut_ptr。
//   f2  等 ICache 响应（地址要对得上）；从 64 字节响应里切出 17 个半字；PreDecode 得到每个位置的
//       指令 / isRVC / 指令起点 valid / 跳转偏移；生成取指范围 instr_range 与逐位置异常。
//   f3  RVC 展开（RVCExpander×16）、F3Predecoder 重算 brType/isCall/isRet（时序考虑，f2 的那份
//       只留着做一致性断言）、PredChecker 第 1 拍、FrontendTrigger；向 IBuffer 入队。
//       MMIO 取指也在这一级：见 §5 的状态机。
//   wb  f3 之后一拍：PredChecker 第 2 拍结果 + 打拍的 f3 信息 → 写回 FTQ（pdWb）；有误预测则
//       wb_redirect 冲刷 f0..f3。
//
// 几个贯穿全文的机制：
//   * PC 的「拆半」存法（省寄存器/功耗）：每个位置只存 12 位低位结果 pc_lower（11 位 + 1 位进位），
//     高 39 位只存 pc_high 与 pc_high+1 两份，用进位位二选一（cat_pc）。
//   * last half：一条 4 字节指令的前半落在本块最后一个半字、后半在下一块。本块把它「不入队」，
//     记 f3_lastHalf_valid；下一块到来时改用 PreDecode 的另一套起点 hasHalfValid（假设位置 0 是
//     上一条的后半）。
//   * 冲刷优先级：后端重定向 > wb（预译码）重定向 / MMIO 重定向 > BPU s2/s3 覆盖（只冲 f0）。
//
// 怪癖（照搬 golden，不要「修」）：
//   - perf 事件 5「ifu_req_cacheline_0_hit」用的是 f3_hit_1（Scala 原文笔误），与事件 6 相同。
//   - f3_pd 的 brType/isCall/isRet 寄存器（f2 PreDecode 的结果）在综合视图里没有读者：只喂
//     XSError 一致性断言；f3_perf_info 的 hit_0_except_1 / miss_0_except_1 / except_0 /
//     bank_hit[0] 只喂 XSPerfAccumulate；f2_cut_ptr 的最高位（第 7 位）取数时被截掉。
//     这些寄存器 golden 里都在，本核原样保留（对称死位，FM 用 vmucp 逐位比）。
//   - 两对「值恒等的重复寄存器」也照留：f3_entered_q / f3_entered_mmio_q（都是
//     RegNext(f2_fire & !f2_flush)）、uncache_resp_wb_q / uncache_resp_redirect_q（都是
//     RegNext(fromUncache.fire)）、hasLastHalf_dis_q / hasLastHalf_clr_q（都是 RegNext(f3_hasLastHalf)）。
//   - 复位域两类：控制位异步复位；数据寄存器（RegEnable）不复位。逐个与 golden 对齐。
//   - MMIO 状态寄存器 4 位、合法状态 0..11；12..15 保持不动（golden 的查表对这 4 项填的是自身）。
//   - pdWb 在 wb_valid=0 时输出 MMIO 写回的内容（Mux(wb_valid, checkFlushWb, mmioFlushWb)），
//     其中 DontCare 字段（jalTarget / cfiOffset）被 firtool 置 0。

package newifu_pkg;
  localparam int unsigned PW          = 16;   // PredictWidth：一个取指块的半字位置数
  localparam int unsigned VADDR_BITS  = 50;
  localparam int unsigned PADDR_BITS  = 48;
  localparam int unsigned GPADDR_BITS = 56;   // PAddrBitsMax
  localparam int unsigned XLEN        = 64;
  localparam int unsigned FTQ_IDX_W   = 6;    // FtqSize = 64
  localparam int unsigned COMMIT_W    = 8;
  localparam int unsigned TOPDOWN_N   = 38;   // TopDownCounters 个数
  localparam int unsigned STAGES      = 3;    // topdown 信息跟着走的级数（f1/f2/f3）

  // PC 拆半：低 PC_CUT 位 + 1 位进位逐位置存；高位只存两份
  localparam int unsigned PC_CUT      = 11;                    // PcCutPoint = VAddrBits/4 - 1
  localparam int unsigned PC_HIGH_W   = VADDR_BITS - PC_CUT;   // 39
  localparam int unsigned BLOCK_OFF   = 6;                     // cacheline 64 字节
  localparam int unsigned FOLDPC_W    = 10;                    // MemPredPCWidth

  // ExceptionType
  localparam logic [1:0] EXC_NONE = 2'd0;
  localparam logic [1:0] EXC_PF   = 2'd1;   // instruction page fault
  localparam logic [1:0] EXC_GPF  = 2'd2;   // instruction guest page fault
  localparam logic [1:0] EXC_AF   = 2'd3;   // instruction access fault

  // Svpbmt 页属性
  localparam logic [1:0] PBMT_NC = 2'd1;    // non-cacheable，幂等，可推测取
  localparam logic [1:0] PBMT_IO = 2'd2;    // I/O，非幂等

  // TopDownCounters 里本模块会置位的几项
  localparam int unsigned TD_TAGE_MISS      = 3;
  localparam int unsigned TD_SC_MISS        = 4;
  localparam int unsigned TD_ITTAGE_MISS    = 5;
  localparam int unsigned TD_RAS_MISS       = 6;
  localparam int unsigned TD_MEMVIO_REDIR   = 7;
  localparam int unsigned TD_OTHER_REDIR    = 8;
  localparam int unsigned TD_ICACHE_MISS    = 10;
  localparam int unsigned TD_ITLB_MISS      = 11;
  localparam int unsigned TD_BTB_MISS       = 12;

  // MMIO 取指状态机（编码与 Chisel Enum(12) 一致）
  typedef enum logic [3:0] {
    M_IDLE             = 4'd0,
    M_WAIT_LAST_CMT    = 4'd1,   // 等上一个预测块的指令全部提交（非幂等空间不许推测取）
    M_SEND_REQ         = 4'd2,   // 向 InstrUncache 发请求
    M_WAIT_RESP        = 4'd3,
    M_SEND_TLB         = 4'd4,   // 指令跨 8 字节边界：后半要重查 ITLB
    M_TLB_RESP         = 4'd5,
    M_SEND_PMP         = 4'd6,   // …再查 PMP
    M_PMP_RESP         = 4'd7,
    M_RESEND_REQ       = 4'd8,   // …再向 InstrUncache 取后半
    M_WAIT_RESEND_RESP = 4'd9,
    M_WAIT_COMMIT      = 4'd10,  // 指令已送 IBuffer，等它提交
    M_COMMITED         = 4'd11
  } mmio_state_e;

  // {进位, 低位} + 两份高位 → 完整 PC
  function automatic logic [VADDR_BITS-1:0] cat_pc(
      input logic [PC_CUT:0]        lower,
      input logic [PC_HIGH_W-1:0]   high,
      input logic [PC_HIGH_W-1:0]   high_plus1);
    return {lower[PC_CUT] ? high_plus1 : high, lower[PC_CUT-1:0]};
  endfunction

  // ExceptionType.merge：前者有异常用前者，否则用后者
  function automatic logic [1:0] exc_merge(input logic [1:0] first, input logic [1:0] second);
    return (first != EXC_NONE) ? first : second;
  endfunction
endpackage

module xs_NewIFU_core
  import newifu_pkg::*;
  import xs_predecode_pkg::*;   // MMIO 指令的分支预译码与 PreDecode 用同一套函数
(
  input  logic                         clock,
  input  logic                         reset,
  // ---- FTQ → IFU：取指请求 ----
  output logic                         io_ftqInter_fromFtq_req_ready,
  input  logic                         io_ftqInter_fromFtq_req_valid,
  input  logic [VADDR_BITS-1:0]        io_ftqInter_fromFtq_req_bits_startAddr,
  input  logic [VADDR_BITS-1:0]        io_ftqInter_fromFtq_req_bits_nextlineStart,
  input  logic [VADDR_BITS-1:0]        io_ftqInter_fromFtq_req_bits_nextStartAddr,
  input  logic                         io_ftqInter_fromFtq_req_bits_ftqIdx_flag,
  input  logic [FTQ_IDX_W-1:0]         io_ftqInter_fromFtq_req_bits_ftqIdx_value,
  input  logic                         io_ftqInter_fromFtq_req_bits_ftqOffset_valid,
  input  logic [3:0]                   io_ftqInter_fromFtq_req_bits_ftqOffset_bits,
  input  logic [TOPDOWN_N-1:0]         io_ftqInter_fromFtq_req_bits_topdown_info_reasons,
  // ---- FTQ → IFU：后端重定向（冲刷）----
  input  logic                         io_ftqInter_fromFtq_redirect_valid,
  input  logic                         io_ftqInter_fromFtq_redirect_bits_ftqIdx_flag,
  input  logic [FTQ_IDX_W-1:0]         io_ftqInter_fromFtq_redirect_bits_ftqIdx_value,
  input  logic [3:0]                   io_ftqInter_fromFtq_redirect_bits_ftqOffset,
  input  logic                         io_ftqInter_fromFtq_redirect_bits_level,
  input  logic                         io_ftqInter_fromFtq_topdown_redirect_valid,
  input  logic                         io_ftqInter_fromFtq_topdown_redirect_bits_cfiUpdate_pd_isRet,
  input  logic                         io_ftqInter_fromFtq_topdown_redirect_bits_cfiUpdate_br_hit,
  input  logic                         io_ftqInter_fromFtq_topdown_redirect_bits_cfiUpdate_jr_hit,
  input  logic                         io_ftqInter_fromFtq_topdown_redirect_bits_cfiUpdate_sc_hit,
  input  logic                         io_ftqInter_fromFtq_topdown_redirect_bits_debugIsCtrl,
  input  logic                         io_ftqInter_fromFtq_topdown_redirect_bits_debugIsMemVio,
  // ---- FTQ → IFU：BPU s2/s3 覆盖预测（只冲 f0）----
  input  logic                         io_ftqInter_fromFtq_flushFromBpu_s2_valid,
  input  logic                         io_ftqInter_fromFtq_flushFromBpu_s2_bits_flag,
  input  logic [FTQ_IDX_W-1:0]         io_ftqInter_fromFtq_flushFromBpu_s2_bits_value,
  input  logic                         io_ftqInter_fromFtq_flushFromBpu_s3_valid,
  input  logic                         io_ftqInter_fromFtq_flushFromBpu_s3_bits_flag,
  input  logic [FTQ_IDX_W-1:0]         io_ftqInter_fromFtq_flushFromBpu_s3_bits_value,
  // ---- IFU → FTQ：预译码写回 ----
  output logic                         io_ftqInter_toFtq_pdWb_valid,
  output logic [PW-1:0][VADDR_BITS-1:0] io_ftqInter_toFtq_pdWb_bits_pc,
  output logic [PW-1:0]                io_ftqInter_toFtq_pdWb_bits_pd_valid,
  output logic [PW-1:0]                io_ftqInter_toFtq_pdWb_bits_pd_isRVC,
  output logic [PW-1:0][1:0]           io_ftqInter_toFtq_pdWb_bits_pd_brType,
  output logic [PW-1:0]                io_ftqInter_toFtq_pdWb_bits_pd_isCall,
  output logic [PW-1:0]                io_ftqInter_toFtq_pdWb_bits_pd_isRet,
  output logic                         io_ftqInter_toFtq_pdWb_bits_ftqIdx_flag,
  output logic [FTQ_IDX_W-1:0]         io_ftqInter_toFtq_pdWb_bits_ftqIdx_value,
  output logic                         io_ftqInter_toFtq_pdWb_bits_misOffset_valid,
  output logic [3:0]                   io_ftqInter_toFtq_pdWb_bits_misOffset_bits,
  output logic                         io_ftqInter_toFtq_pdWb_bits_cfiOffset_valid,
  output logic [VADDR_BITS-1:0]        io_ftqInter_toFtq_pdWb_bits_target,
  output logic [VADDR_BITS-1:0]        io_ftqInter_toFtq_pdWb_bits_jalTarget,
  output logic [PW-1:0]                io_ftqInter_toFtq_pdWb_bits_instrRange,
  // ---- ICache ----
  input  logic                         io_icacheInter_icacheReady,
  input  logic                         io_icacheInter_resp_valid,
  input  logic                         io_icacheInter_resp_bits_doubleline,
  input  logic [1:0][VADDR_BITS-1:0]   io_icacheInter_resp_bits_vaddr,
  input  logic [511:0]                 io_icacheInter_resp_bits_data,
  input  logic [PADDR_BITS-1:0]        io_icacheInter_resp_bits_paddr_0,
  input  logic [1:0][1:0]              io_icacheInter_resp_bits_exception,
  input  logic [1:0]                   io_icacheInter_resp_bits_pmp_mmio,
  input  logic [1:0][1:0]              io_icacheInter_resp_bits_itlb_pbmt,
  input  logic                         io_icacheInter_resp_bits_backendException,
  input  logic                         io_icacheInter_resp_bits_hasSatpFlush,
  input  logic [GPADDR_BITS-1:0]       io_icacheInter_resp_bits_gpaddr,
  input  logic                         io_icacheInter_resp_bits_isForVSnonLeafPTE,
  input  logic                         io_icacheInter_topdownIcacheMiss,
  input  logic                         io_icacheInter_topdownItlbMiss,
  output logic                         io_icacheStop,
  input  logic                         io_icachePerfInfo_only_0_hit,
  input  logic                         io_icachePerfInfo_only_0_miss,
  input  logic                         io_icachePerfInfo_hit_0_hit_1,
  input  logic                         io_icachePerfInfo_hit_0_miss_1,
  input  logic                         io_icachePerfInfo_miss_0_hit_1,
  input  logic                         io_icachePerfInfo_miss_0_miss_1,
  input  logic                         io_icachePerfInfo_hit_0_except_1,
  input  logic                         io_icachePerfInfo_miss_0_except_1,
  input  logic                         io_icachePerfInfo_except_0,
  input  logic [1:0]                   io_icachePerfInfo_bank_hit,
  input  logic                         io_icachePerfInfo_hit,
  // ---- IFU → IBuffer ----
  input  logic                         io_toIbuffer_ready,
  output logic                         io_toIbuffer_valid,
  output logic [PW-1:0][31:0]          io_toIbuffer_bits_instrs,
  output logic [PW-1:0]                io_toIbuffer_bits_valid,
  output logic [PW-1:0]                io_toIbuffer_bits_enqEnable,
  output logic [PW-1:0]                io_toIbuffer_bits_pd_isRVC,
  output logic [PW-1:0][1:0]           io_toIbuffer_bits_pd_brType,
  output logic [PW-1:0]                io_toIbuffer_bits_pd_isCall,
  output logic [PW-1:0]                io_toIbuffer_bits_pd_isRet,
  output logic [PW-1:1]                io_toIbuffer_bits_pd_valid,   // 位置 0 恒为起点，golden 无此端口
  output logic [PW-1:0][FOLDPC_W-1:0]  io_toIbuffer_bits_foldpc,
  output logic [PW-1:0]                io_toIbuffer_bits_ftqOffset_valid,
  output logic                         io_toIbuffer_bits_backendException_0,
  output logic                         io_toIbuffer_bits_satpFlushFirstFetchFault_0,
  output logic [PW-1:0][1:0]           io_toIbuffer_bits_exceptionType,
  output logic [PW-1:0]                io_toIbuffer_bits_crossPageIPFFix,
  output logic [PW-1:0]                io_toIbuffer_bits_illegalInstr,
  output logic [PW-1:0][3:0]           io_toIbuffer_bits_triggered,
  output logic [PW-1:0]                io_toIbuffer_bits_isLastInFtqEntry,
  output logic [PW-1:0][VADDR_BITS-1:0] io_toIbuffer_bits_pc,
  output logic                         io_toIbuffer_bits_ftqPtr_flag,
  output logic [FTQ_IDX_W-1:0]         io_toIbuffer_bits_ftqPtr_value,
  output logic [TOPDOWN_N-1:0]         io_toIbuffer_bits_topdown_info_reasons,
  // ---- IFU → 后端：guest 物理地址表写口（gpf 时用）----
  output logic                         io_toBackend_gpaddrMem_wen,
  output logic [FTQ_IDX_W-1:0]         io_toBackend_gpaddrMem_waddr,
  output logic [GPADDR_BITS-1:0]       io_toBackend_gpaddrMem_wdata_gpaddr,
  output logic                         io_toBackend_gpaddrMem_wdata_isForVSnonLeafPTE,
  // ---- InstrUncache（MMIO 取指）----
  input  logic                         io_uncacheInter_fromUncache_valid,
  input  logic [31:0]                  io_uncacheInter_fromUncache_bits_data,
  input  logic                         io_uncacheInter_fromUncache_bits_corrupt,
  input  logic                         io_uncacheInter_toUncache_ready,
  output logic                         io_uncacheInter_toUncache_valid,
  output logic [PADDR_BITS-1:0]        io_uncacheInter_toUncache_bits_addr,
  output logic                         io_uncacheInter_toUncache_bits_memBackTypeMM,
  output logic                         io_uncacheInter_toUncache_bits_memPageTypeNC,
  output logic                         io_uncacheInter_toUncache_bits_flush,
  // ---- 前端断点触发器配置（透传给 FrontendTrigger）----
  input  logic                         io_frontendTrigger_tUpdate_valid,
  input  logic [1:0]                   io_frontendTrigger_tUpdate_bits_addr,
  input  logic [1:0]                   io_frontendTrigger_tUpdate_bits_tdata_matchType,
  input  logic                         io_frontendTrigger_tUpdate_bits_tdata_select,
  input  logic [3:0]                   io_frontendTrigger_tUpdate_bits_tdata_action,
  input  logic                         io_frontendTrigger_tUpdate_bits_tdata_chain,
  input  logic [63:0]                  io_frontendTrigger_tUpdate_bits_tdata_tdata2,
  input  logic [3:0]                   io_frontendTrigger_tEnableVec,
  input  logic                         io_frontendTrigger_debugMode,
  input  logic                         io_frontendTrigger_triggerCanRaiseBpExp,
  // ---- ROB 提交（MMIO 指令等自己提交）----
  input  logic [COMMIT_W-1:0]                io_rob_commits_valid,
  input  logic [COMMIT_W-1:0]                io_rob_commits_bits_ftqIdx_flag,
  input  logic [COMMIT_W-1:0][FTQ_IDX_W-1:0] io_rob_commits_bits_ftqIdx_value,
  input  logic [COMMIT_W-1:0][3:0]           io_rob_commits_bits_ftqOffset,
  // ---- ITLB / PMP（只给 MMIO 跨边界重取用）----
  input  logic                         io_iTLBInter_req_ready,
  output logic                         io_iTLBInter_req_valid,
  output logic [VADDR_BITS-1:0]        io_iTLBInter_req_bits_vaddr,
  output logic                         io_iTLBInter_resp_ready,
  input  logic                         io_iTLBInter_resp_valid,
  input  logic [PADDR_BITS-1:0]        io_iTLBInter_resp_bits_paddr_0,
  input  logic [63:0]                  io_iTLBInter_resp_bits_gpaddr_0,
  input  logic [1:0]                   io_iTLBInter_resp_bits_pbmt_0,
  input  logic                         io_iTLBInter_resp_bits_miss,       // 只进断言
  input  logic                         io_iTLBInter_resp_bits_isForVSnonLeafPTE,
  input  logic                         io_iTLBInter_resp_bits_excp_0_gpf_instr,
  input  logic                         io_iTLBInter_resp_bits_excp_0_pf_instr,
  input  logic                         io_iTLBInter_resp_bits_excp_0_af_instr,
  output logic                         io_pmp_req_valid,
  output logic [PADDR_BITS-1:0]        io_pmp_req_bits_addr,
  input  logic                         io_pmp_resp_instr,
  input  logic                         io_pmp_resp_mmio,
  // ---- 问 FTQ：上一个预测块是否已全部提交 ----
  output logic                         io_mmioCommitRead_valid,
  output logic                         io_mmioCommitRead_mmioFtqPtr_flag,
  output logic [FTQ_IDX_W-1:0]         io_mmioCommitRead_mmioFtqPtr_value,
  input  logic                         io_mmioCommitRead_mmioLastCommit,
  input  logic                         io_csr_fsIsOff,
  output logic [12:0][5:0]             io_perf_value
);

  // ===========================================================================
  // §0 跨级信号：冲刷、握手
  // ===========================================================================
  logic f1_ready, f2_ready, f3_ready;
  logic f0_fire, f1_fire, f2_fire, f3_fire;
  logic f2_flush, f3_flush;           // f1_flush == f2_flush；f0 另加 BPU 覆盖
  logic wb_redirect;                  // 预译码检查发现误预测（wb 级）
  logic mmio_redirect;                // MMIO 指令取回后，让 FTQ 从它的下一条重新取
  logic f3_wb_not_flush;              // wb 级与 f3 级是同一个块：wb 重定向不冲 f3 自己
  logic f3_req_is_mmio;

  wire backend_redirect = io_ftqInter_fromFtq_redirect_valid;
  assign f3_flush = backend_redirect | (wb_redirect & ~f3_wb_not_flush);
  assign f2_flush = backend_redirect | mmio_redirect | wb_redirect;
  wire   f1_flush = f2_flush;

  // ===========================================================================
  // §1 f0：接 FTQ 请求（组合）
  // ===========================================================================
  // BPU 的 s2 / s3 级覆盖了更早的预测：ftqIdx 不早于覆盖点的请求作废。
  // shouldFlushByStageN(idx) = sN.valid && !isAfter(sN.bits, idx)
  function automatic logic not_after(input logic a_flag, input logic [FTQ_IDX_W-1:0] a_value,
                                     input logic b_flag, input logic [FTQ_IDX_W-1:0] b_value);
    return a_flag ^ b_flag ^ (a_value <= b_value);
  endfunction

  wire f0_flush_from_bpu =
      (io_ftqInter_fromFtq_flushFromBpu_s2_valid
       & not_after(io_ftqInter_fromFtq_flushFromBpu_s2_bits_flag, io_ftqInter_fromFtq_flushFromBpu_s2_bits_value,
                   io_ftqInter_fromFtq_req_bits_ftqIdx_flag,      io_ftqInter_fromFtq_req_bits_ftqIdx_value))
    | (io_ftqInter_fromFtq_flushFromBpu_s3_valid
       & not_after(io_ftqInter_fromFtq_flushFromBpu_s3_bits_flag, io_ftqInter_fromFtq_flushFromBpu_s3_bits_value,
                   io_ftqInter_fromFtq_req_bits_ftqIdx_flag,      io_ftqInter_fromFtq_req_bits_ftqIdx_value));
  wire f0_flush = f1_flush | f0_flush_from_bpu;

  assign io_ftqInter_fromFtq_req_ready = f1_ready & io_icacheInter_icacheReady;
  assign f0_fire = io_ftqInter_fromFtq_req_ready & io_ftqInter_fromFtq_req_valid;

  // ===========================================================================
  // §2 f1：锁存请求；算每个位置的 PC 低位与切数据指针
  // ===========================================================================
  logic                  f1_valid_q;
  logic [VADDR_BITS-1:0] f1_startAddr_q, f1_nextlineStart_q, f1_nextStartAddr_q;
  logic                  f1_ftqIdx_flag_q;
  logic [FTQ_IDX_W-1:0]  f1_ftqIdx_value_q;
  logic                  f1_ftqOffset_valid_q;
  logic [3:0]            f1_ftqOffset_bits_q;
  logic                  f1_doubleLine_q;    // 起始地址在 cacheline 后半 → 取指块跨两行

  assign f1_fire  = f1_valid_q & f2_ready;
  assign f1_ready = f1_fire | ~f1_valid_q;

  always_ff @(posedge clock or posedge reset) begin
    if (reset)                    f1_valid_q <= 1'b0;
    else if (f1_flush)            f1_valid_q <= 1'b0;
    else if (f0_fire & ~f0_flush) f1_valid_q <= 1'b1;
    else if (f1_fire)             f1_valid_q <= 1'b0;
  end

  always_ff @(posedge clock) begin
    if (f0_fire) begin
      f1_startAddr_q       <= io_ftqInter_fromFtq_req_bits_startAddr;
      f1_nextlineStart_q   <= io_ftqInter_fromFtq_req_bits_nextlineStart;
      f1_nextStartAddr_q   <= io_ftqInter_fromFtq_req_bits_nextStartAddr;
      f1_ftqIdx_flag_q     <= io_ftqInter_fromFtq_req_bits_ftqIdx_flag;
      f1_ftqIdx_value_q    <= io_ftqInter_fromFtq_req_bits_ftqIdx_value;
      f1_ftqOffset_valid_q <= io_ftqInter_fromFtq_req_bits_ftqOffset_valid;
      f1_ftqOffset_bits_q  <= io_ftqInter_fromFtq_req_bits_ftqOffset_bits;
      f1_doubleLine_q      <= io_ftqInter_fromFtq_req_bits_startAddr[BLOCK_OFF-1];
    end
  end

  // 位置 i 的 PC = startAddr + 2i：只算低 11 位 + 进位
  wire [PC_HIGH_W-1:0] f1_pc_high       = f1_startAddr_q[VADDR_BITS-1:PC_CUT];
  wire [PC_HIGH_W-1:0] f1_pc_high_plus1 = f1_pc_high + 1'b1;
  wire [PC_CUT:0]      f1_start_low     = {1'b0, f1_startAddr_q[PC_CUT-1:0]};
  // 切数据指针：以半字为单位在「两份 cacheline 拼起来」的 64 个半字里的下标
  wire [6:0]           f1_start_hw      = {2'b0, f1_startAddr_q[BLOCK_OFF-1:1]};

  // ===========================================================================
  // §3 f2：等 ICache 响应、切数据、PreDecode、取指范围与异常
  // ===========================================================================
  logic                  f2_valid_q;
  logic [VADDR_BITS-1:0] f2_startAddr_q, f2_nextlineStart_q, f2_nextStartAddr_q;
  logic                  f2_ftqIdx_flag_q;
  logic [FTQ_IDX_W-1:0]  f2_ftqIdx_value_q;
  logic                  f2_ftqOffset_valid_q;
  logic [3:0]            f2_ftqOffset_bits_q;
  logic                  f2_doubleLine_q;
  logic [PW-1:0][PC_CUT:0] f2_pc_lower_q;
  logic [PC_HIGH_W-1:0]  f2_pc_high_q, f2_pc_high_plus1_q;
  logic [PW:0][6:0]      f2_cut_ptr_q;       // 17 个半字（多 1 个给最后位置的 RVI 后半）
  logic [VADDR_BITS-1:0] f2_resend_vaddr_q;  // startAddr + 2：MMIO 指令后半的虚地址
  logic                  f2_icache_all_resp_q;

  // ICache 响应「是给本块的」：地址对得上（跨行时第二行也要对上）
  wire f2_icache_all_resp_wire =
      io_icacheInter_resp_valid
    & (io_icacheInter_resp_bits_vaddr[0] == f2_startAddr_q)
    & ((io_icacheInter_resp_bits_doubleline & (io_icacheInter_resp_bits_vaddr[1] == f2_nextlineStart_q))
       | ~f2_doubleLine_q);
  // 响应只在一拍有效；f3 堵着时记下「已经到过」
  wire icacheRespAllValid = f2_icache_all_resp_q | f2_icache_all_resp_wire;

  assign f2_fire  = f2_valid_q & f3_ready & icacheRespAllValid;
  assign f2_ready = f2_fire | ~f2_valid_q;
  assign io_icacheStop = ~f3_ready;

  always_ff @(posedge clock or posedge reset) begin
    if (reset)                    f2_valid_q <= 1'b0;
    else if (f2_flush)            f2_valid_q <= 1'b0;
    else if (f1_fire & ~f1_flush) f2_valid_q <= 1'b1;
    else if (f2_fire)             f2_valid_q <= 1'b0;
  end

  always_ff @(posedge clock or posedge reset) begin
    if (reset)                                                  f2_icache_all_resp_q <= 1'b0;
    else if (f2_flush)                                          f2_icache_all_resp_q <= 1'b0;
    else if (f2_valid_q & f2_icache_all_resp_wire & ~f3_ready)  f2_icache_all_resp_q <= 1'b1;
    else if (f2_fire & f2_icache_all_resp_q)                    f2_icache_all_resp_q <= 1'b0;
  end

  always_ff @(posedge clock) begin
    if (f1_fire) begin
      f2_startAddr_q       <= f1_startAddr_q;
      f2_nextlineStart_q   <= f1_nextlineStart_q;
      f2_nextStartAddr_q   <= f1_nextStartAddr_q;
      f2_ftqIdx_flag_q     <= f1_ftqIdx_flag_q;
      f2_ftqIdx_value_q    <= f1_ftqIdx_value_q;
      f2_ftqOffset_valid_q <= f1_ftqOffset_valid_q;
      f2_ftqOffset_bits_q  <= f1_ftqOffset_bits_q;
      f2_doubleLine_q      <= f1_doubleLine_q;
      for (int i = 0; i < PW; i++)  f2_pc_lower_q[i] <= f1_start_low + (PC_CUT+1)'(2 * i);
      f2_pc_high_q         <= f1_pc_high;
      f2_pc_high_plus1_q   <= f1_pc_high_plus1;
      for (int i = 0; i <= PW; i++) f2_cut_ptr_q[i]  <= f1_start_hw + 7'(i);
      f2_resend_vaddr_q    <= f1_startAddr_q + VADDR_BITS'(2);
    end
  end

  // ---- 异常：ICache 给两行各一个；跨行且两行的 MMIO 属性不一致也算第二行 access fault ----
  wire icache_mmio_attr_same =
      (io_icacheInter_resp_bits_pmp_mmio[0]  == io_icacheInter_resp_bits_pmp_mmio[1])
    & (io_icacheInter_resp_bits_itlb_pbmt[0] == io_icacheInter_resp_bits_itlb_pbmt[1]);
  wire [1:0] f2_mmio_mismatch_exception =
      (~io_icacheInter_resp_bits_doubleline | icache_mmio_attr_same) ? EXC_NONE : EXC_AF;
  logic [1:0][1:0] f2_exception;
  assign f2_exception[0] = io_icacheInter_resp_bits_exception[0];
  assign f2_exception[1] = exc_merge(io_icacheInter_resp_bits_exception[1], f2_mmio_mismatch_exception);

  // ---- 切数据：ICache 只回 64 字节，按行内偏移环绕摆放；拼两份后从 cut_ptr 起连续取 ----
  // （ICacheDataArray 已经把跨行的两段放到各自的行内偏移上，见 Scala 源里那段长注释）
  logic [63:0][15:0]  f2_data_halfwords;
  logic [PW:0][15:0]  f2_cut_data;
  for (genvar h = 0; h < 64; h++) begin : g_halfword
    assign f2_data_halfwords[h] = io_icacheInter_resp_bits_data[(h % 32) * 16 +: 16];
  end
  for (genvar i = 0; i <= PW; i++) begin : g_cut
    assign f2_cut_data[i] = f2_data_halfwords[f2_cut_ptr_q[i][5:0]];
  end

  // ---- 预译码 ----
  logic [PW-1:0]           f2_pd_valid, f2_pd_isRVC, f2_pd_isCall, f2_pd_isRet, f2_hasHalfValid;
  logic [PW-1:0][1:0]      f2_pd_brType;
  logic [PW-1:0][31:0]     f2_instr;
  logic [PW-1:0][XLEN-1:0] f2_jump_offset;

  xs_PreDecode_core #(.PW(PW), .XLEN(XLEN)) u_preDecoder (
    .io_data      (f2_cut_data),
    .pd_valid     (f2_pd_valid),
    .pd_isRVC     (f2_pd_isRVC),
    .pd_brType    (f2_pd_brType),
    .pd_isCall    (f2_pd_isCall),
    .pd_isRet     (f2_pd_isRet),
    .hasHalfValid (f2_hasHalfValid),
    .instr        (f2_instr),
    .jumpOffset   (f2_jump_offset)
  );

  // ---- 取指范围：位置 i 在不在本块里 ----
  //   预测跳：到跳转指令为止（jump_range）；预测不跳：到 nextStartAddr 之前（ftr_range）
  wire [4:0]    f2_block_len   = (f2_nextStartAddr_q[4:0] - f2_startAddr_q[4:0]) - 5'd2;
  wire [3:0]    f2_last_idx    = f2_block_len[4:1];        // getBasicBlockIdx：最后一个半字位置
  wire [PW-1:0] f2_jump_range  = {PW{~f2_ftqOffset_valid_q}} | (16'hFFFF >> ~f2_ftqOffset_bits_q);
  wire [PW-1:0] f2_ftr_range   = {PW{ f2_ftqOffset_valid_q}} | (16'hFFFF >> ~f2_last_idx);
  wire [PW-1:0] f2_instr_range = f2_jump_range & f2_ftr_range;

  // ---- 逐位置：完整 PC（只为折叠）、折叠 PC、异常 ----
  logic [PW-1:0][FOLDPC_W-1:0] f2_foldpc;
  logic [PW-1:0][1:0]          f2_exception_vec, f2_crossPage_exception_vec;
  for (genvar i = 0; i < PW; i++) begin : g_f2_pos
    wire [VADDR_BITS-1:0] pc = cat_pc(f2_pc_lower_q[i], f2_pc_high_q, f2_pc_high_plus1_q);
    // XORFold(pc[49:1], 10)：49 位按 10 位一段异或（最高段 9 位）
    assign f2_foldpc[i] = pc[10:1] ^ pc[20:11] ^ pc[30:21] ^ pc[40:31] ^ {1'b0, pc[49:41]};

    // 这个位置落在第二行（与起始地址不在同一 cacheline）
    wire in_next_line = f2_startAddr_q[BLOCK_OFF] ^ pc[BLOCK_OFF];
    assign f2_exception_vec[i] = ~in_next_line   ? f2_exception[0]
                               : f2_doubleLine_q ? f2_exception[1]
                               :                   EXC_NONE;

    // 行内最后一个半字上的 4 字节指令：前半没异常时，异常与否取决于后半所在的那一行
    wire last_in_line = pc[BLOCK_OFF-1:0] == 6'h3E;
    assign f2_crossPage_exception_vec[i] =
        (last_in_line & ~f2_pd_isRVC[i] & f2_doubleLine_q & (f2_exception[0] == EXC_NONE))
      ? f2_exception[1] : EXC_NONE;
  end

  // ===========================================================================
  // §4 f3：RVC 展开、预测检查、触发器、入 IBuffer
  // ===========================================================================
  logic                    f3_valid_q;
  logic [VADDR_BITS-1:0]   f3_startAddr_q, f3_nextStartAddr_q;
  logic                    f3_ftqIdx_flag_q;
  logic [FTQ_IDX_W-1:0]    f3_ftqIdx_value_q;
  logic                    f3_ftqOffset_valid_q;
  logic [3:0]              f3_ftqOffset_bits_q;
  logic                    f3_doubleLine_q;
  logic [1:0][1:0]         f3_exception_q;
  logic                    f3_pmp_mmio_q;
  logic [1:0]              f3_itlb_pbmt_q;
  logic                    f3_backendException_q, f3_hasSatpFlush_q;
  logic [PW-1:0][31:0]     f3_instr_q;
  logic [PW-1:1]           f3_pd_valid_q;        // 位置 0 恒为指令起点，无寄存器
  logic [PW-1:0]           f3_pd_isRVC_q;
  logic [PW-1:0][1:0]      f3_pd_brType_q;       // 死位：只喂一致性断言（见文件头）
  logic [PW-1:0]           f3_pd_isCall_q;       // 死位
  logic [PW-1:0]           f3_pd_isRet_q;        // 死位
  logic [PW-1:0][XLEN-1:0] f3_jump_offset_q;
  logic [PW-1:0][1:0]      f3_exception_vec_q, f3_crossPage_exception_vec_q;
  logic [PW-1:0][PC_CUT:0] f3_pc_lower_q;
  logic [PC_HIGH_W-1:0]    f3_pc_high_q, f3_pc_high_plus1_q;
  logic [PC_CUT:0]         f3_pc_last_lower_plus2_q, f3_pc_last_lower_plus4_q;
  logic [PW-1:0]           f3_instr_range_q;
  logic [PW-1:0][FOLDPC_W-1:0] f3_foldpc_q;
  logic [PW-1:2]           f3_hasHalfValid_q;    // 位置 0 恒 0、位置 1 恒 1，无寄存器
  logic [PADDR_BITS-1:0]   f3_paddr0_q;
  logic [GPADDR_BITS-1:0]  f3_gpaddr_q;
  logic                    f3_isForVSnonLeafPTE_q;
  logic [VADDR_BITS-1:0]   f3_resend_vaddr_q;
  // ICache 命中情况（perf 用）
  logic                    f3_perf_only_0_hit_q, f3_perf_only_0_miss_q;
  logic                    f3_perf_hit_0_hit_1_q, f3_perf_hit_0_miss_1_q;
  logic                    f3_perf_miss_0_hit_1_q, f3_perf_miss_0_miss_1_q;
  logic                    f3_perf_hit_0_except_1_q, f3_perf_miss_0_except_1_q, f3_perf_except_0_q;  // 死位
  logic [1:0]              f3_perf_bank_hit_q;   // [0] 死位
  logic                    f3_perf_hit_q;

  always_ff @(posedge clock) begin
    if (f2_fire) begin
      f3_startAddr_q               <= f2_startAddr_q;
      f3_nextStartAddr_q           <= f2_nextStartAddr_q;
      f3_ftqIdx_flag_q             <= f2_ftqIdx_flag_q;
      f3_ftqIdx_value_q            <= f2_ftqIdx_value_q;
      f3_ftqOffset_valid_q         <= f2_ftqOffset_valid_q;
      f3_ftqOffset_bits_q          <= f2_ftqOffset_bits_q;
      f3_doubleLine_q              <= f2_doubleLine_q;
      f3_exception_q               <= f2_exception;
      f3_pmp_mmio_q                <= io_icacheInter_resp_bits_pmp_mmio[0];
      f3_itlb_pbmt_q               <= io_icacheInter_resp_bits_itlb_pbmt[0];
      f3_backendException_q        <= io_icacheInter_resp_bits_backendException;
      f3_hasSatpFlush_q            <= io_icacheInter_resp_bits_hasSatpFlush;
      f3_instr_q                   <= f2_instr;
      f3_pd_valid_q                <= f2_pd_valid[PW-1:1];
      f3_pd_isRVC_q                <= f2_pd_isRVC;
      f3_pd_brType_q               <= f2_pd_brType;
      f3_pd_isCall_q               <= f2_pd_isCall;
      f3_pd_isRet_q                <= f2_pd_isRet;
      f3_jump_offset_q             <= f2_jump_offset;
      f3_exception_vec_q           <= f2_exception_vec;
      f3_crossPage_exception_vec_q <= f2_crossPage_exception_vec;
      f3_pc_lower_q                <= f2_pc_lower_q;
      f3_pc_high_q                 <= f2_pc_high_q;
      f3_pc_high_plus1_q           <= f2_pc_high_plus1_q;
      f3_pc_last_lower_plus2_q     <= f2_pc_lower_q[PW-1] + (PC_CUT+1)'(2);
      f3_pc_last_lower_plus4_q     <= f2_pc_lower_q[PW-1] + (PC_CUT+1)'(4);
      f3_instr_range_q             <= f2_instr_range;
      f3_foldpc_q                  <= f2_foldpc;
      f3_hasHalfValid_q            <= f2_hasHalfValid[PW-1:2];
      f3_paddr0_q                  <= io_icacheInter_resp_bits_paddr_0;
      f3_gpaddr_q                  <= io_icacheInter_resp_bits_gpaddr;
      f3_isForVSnonLeafPTE_q       <= io_icacheInter_resp_bits_isForVSnonLeafPTE;
      f3_resend_vaddr_q            <= f2_resend_vaddr_q;
      f3_perf_only_0_hit_q         <= io_icachePerfInfo_only_0_hit;
      f3_perf_only_0_miss_q        <= io_icachePerfInfo_only_0_miss;
      f3_perf_hit_0_hit_1_q        <= io_icachePerfInfo_hit_0_hit_1;
      f3_perf_hit_0_miss_1_q       <= io_icachePerfInfo_hit_0_miss_1;
      f3_perf_miss_0_hit_1_q       <= io_icachePerfInfo_miss_0_hit_1;
      f3_perf_miss_0_miss_1_q      <= io_icachePerfInfo_miss_0_miss_1;
      f3_perf_hit_0_except_1_q     <= io_icachePerfInfo_hit_0_except_1;
      f3_perf_miss_0_except_1_q    <= io_icachePerfInfo_miss_0_except_1;
      f3_perf_except_0_q           <= io_icachePerfInfo_except_0;
      f3_perf_bank_hit_q           <= io_icachePerfInfo_bank_hit;
      f3_perf_hit_q                <= io_icachePerfInfo_hit;
    end
  end

  wire [FTQ_IDX_W:0] f3_ftqIdx = {f3_ftqIdx_flag_q, f3_ftqIdx_value_q};

  // ---- 完整 PC 与「半字后继」half_snpc[i] = pc[i] + 4（= pc[i+2]；最后两个另存）----
  logic [PW-1:0][VADDR_BITS-1:0] f3_pc, f3_half_snpc;
  for (genvar i = 0; i < PW; i++) begin : g_f3_pc
    assign f3_pc[i] = cat_pc(f3_pc_lower_q[i], f3_pc_high_q, f3_pc_high_plus1_q);
    if (i < PW - 2)       begin : g_in   assign f3_half_snpc[i] = f3_pc[i + 2]; end
    else if (i == PW - 2) begin : g_p2   assign f3_half_snpc[i] = cat_pc(f3_pc_last_lower_plus2_q, f3_pc_high_q, f3_pc_high_plus1_q); end
    else                  begin : g_p4   assign f3_half_snpc[i] = cat_pc(f3_pc_last_lower_plus4_q, f3_pc_high_q, f3_pc_high_plus1_q); end
  end

  // ---- RVC 展开：合法才用展开结果，非法保留原码（后端据此报 illegal）----
  logic [PW-1:0][31:0] f3_expanded, f3_expd_instr;
  logic [PW-1:0]       f3_ill;
  for (genvar i = 0; i < PW; i++) begin : g_expander
    xs_RVCExpander_core u_expander (
      .io_in       (f3_instr_q[i]),
      .io_fsIsOff  (io_csr_fsIsOff),
      .io_out_bits (f3_expanded[i]),
      .io_ill      (f3_ill[i])
    );
    assign f3_expd_instr[i] = f3_ill[i] ? f3_instr_q[i] : f3_expanded[i];
  end

  // ---- brType / isCall / isRet 在 f3 用寄存后的指令重新译码（f2 那份时序太紧）----
  logic [PW-1:0][1:0] f3_pd_brType;
  logic [PW-1:0]      f3_pd_isCall, f3_pd_isRet;
  xs_F3Predecoder_core #(.PW(PW)) u_f3Predecoder (
    .io_instr  (f3_instr_q),
    .pd_brType (f3_pd_brType),
    .pd_isCall (f3_pd_isCall),
    .pd_isRet  (f3_pd_isRet)
  );

  // ---- last half：上一块留了半条 RVI 时，本块改用「位置 0 是后半」那套起点 ----
  logic         f3_lastHalf_valid_q;
  logic         f3_lastHalf_disable_q;
  wire [PW-1:0] f3_pd_valid       = {f3_pd_valid_q, 1'b1};
  wire [PW-1:0] f3_hasHalfValid   = {f3_hasHalfValid_q, 2'b10};
  wire [PW-1:0] f3_instr_valid    = f3_lastHalf_valid_q ? f3_hasHalfValid : f3_pd_valid;

  // ---- 预测检查 ----
  logic                          checker_fire_in_q;     // RegNext(f2_fire)：f3 装入新块的那一拍
  logic [PW-1:0]                 chk_fixedRange, chk_fixedTaken, chk_fixedMissPred;
  logic [PW-1:0][VADDR_BITS-1:0] chk_fixedTarget, chk_jalTarget;
  logic [PW-1:0][2:0]            chk_faultType;

  xs_PredChecker_core u_predChecker (
    .clock                            (clock),
    .io_in_ftqOffset_valid            (f3_ftqOffset_valid_q),
    .io_in_ftqOffset_bits             (f3_ftqOffset_bits_q),
    .io_in_target                     (f3_nextStartAddr_q),
    .io_in_jumpOffset                 (f3_jump_offset_q),
    .io_in_instrRange                 (f3_instr_range_q),
    .io_in_instrValid                 (f3_instr_valid),
    .io_in_pds_isRVC                  (f3_pd_isRVC_q),
    .io_in_pds_brType                 (f3_pd_brType),
    .io_in_pds_isRet                  (f3_pd_isRet),
    .io_in_pc                         (f3_pc),
    .io_in_fire_in                    (checker_fire_in_q),
    .io_out_stage1Out_fixedRange      (chk_fixedRange),
    .io_out_stage1Out_fixedTaken      (chk_fixedTaken),
    .io_out_stage2Out_fixedTarget     (chk_fixedTarget),
    .io_out_stage2Out_jalTarget       (chk_jalTarget),
    .io_out_stage2Out_fixedMissPred   (chk_fixedMissPred),
    .io_out_stage2Out_faultType_value (chk_faultType)
  );

  // ---- 断点触发 ----
  logic [PW-1:0][3:0] f3_triggered;
  xs_FrontendTrigger_core u_frontendTrigger (
    .clock                                           (clock),
    .reset                                           (reset),
    .io_frontendTrigger_tUpdate_valid                (io_frontendTrigger_tUpdate_valid),
    .io_frontendTrigger_tUpdate_bits_addr            (io_frontendTrigger_tUpdate_bits_addr),
    .io_frontendTrigger_tUpdate_bits_tdata_matchType (io_frontendTrigger_tUpdate_bits_tdata_matchType),
    .io_frontendTrigger_tUpdate_bits_tdata_select    (io_frontendTrigger_tUpdate_bits_tdata_select),
    .io_frontendTrigger_tUpdate_bits_tdata_action    (io_frontendTrigger_tUpdate_bits_tdata_action),
    .io_frontendTrigger_tUpdate_bits_tdata_chain     (io_frontendTrigger_tUpdate_bits_tdata_chain),
    .io_frontendTrigger_tUpdate_bits_tdata_tdata2    (io_frontendTrigger_tUpdate_bits_tdata_tdata2),
    .io_frontendTrigger_tEnableVec                   (io_frontendTrigger_tEnableVec),
    .io_frontendTrigger_debugMode                    (io_frontendTrigger_debugMode),
    .io_frontendTrigger_triggerCanRaiseBpExp         (io_frontendTrigger_triggerCanRaiseBpExp),
    .io_triggered                                    (f3_triggered),
    .io_pc                                           (f3_pc)
  );

  // ===========================================================================
  // §5 MMIO 取指状态机（f3 级；一个 MMIO 块只取位置 0 这一条指令）
  // ===========================================================================
  // 取指地址落在不可缓存空间（PMP 说是 MMIO，或页表 pbmt 是 NC/IO）且第一行没有异常时，
  // 不能用 ICache 的数据，改由 InstrUncache 走总线取这一条指令：
  //   IDLE → [非幂等空间先等上一块全部提交 WAIT_LAST_CMT] → SEND_REQ → WAIT_RESP
  //        → [4 字节指令跨了 8 字节总线边界：SEND_TLB → TLB_RESP → SEND_PMP → PMP_RESP
  //            → RESEND_REQ → WAIT_RESEND_RESP 取后半]
  //        → WAIT_COMMIT（此时把指令送 IBuffer，并让 FTQ 从下一条重取）→ COMMITED → IDLE
  // 中途任何一步出异常，带着异常直接去 WAIT_COMMIT。
  mmio_state_e           mmio_state_q;
  logic [1:0][15:0]      f3_mmio_data_q;       // 取回的指令（低/高半字）；不复位
  logic [1:0]            mmio_exception_q;
  logic                  mmio_is_RVC_q;
  logic                  mmio_has_resend_q;
  logic [PADDR_BITS-1:0] mmio_resend_addr_q;
  logic [GPADDR_BITS-1:0] mmio_resend_gpaddr_q;
  logic                  mmio_resend_isForVSnonLeafPTE_q;
  logic                  is_first_instr_q;     // 复位后的第一条：没有「上一块」可等
  logic                  f3_mmio_sent_to_ibuffer_q;
  logic                  f3_mmio_use_seq_pc_q;

  wire pbmt_is_nc = f3_itlb_pbmt_q == PBMT_NC;
  assign f3_req_is_mmio = f3_valid_q
                        & (f3_pmp_mmio_q | pbmt_is_nc | (f3_itlb_pbmt_q == PBMT_IO))
                        & (f3_exception_q[0] == EXC_NONE);

  // ---- 后端重定向打一拍后的视图：它冲不冲得到 f3 里这条 MMIO 指令 ----
  logic                 redirect_valid_q;
  logic                 redirect_ftqIdx_flag_q;
  logic [FTQ_IDX_W-1:0] redirect_ftqIdx_value_q;
  logic [3:0]           redirect_ftqOffset_q;
  logic                 redirect_level_q;       // 1 = flushItself
  logic                 mmioF3Flush_q;          // RegNext(f3_flush)

  always_ff @(posedge clock or posedge reset) begin
    if (reset) begin
      redirect_valid_q        <= 1'b0;
      redirect_ftqIdx_flag_q  <= 1'b0;
      redirect_ftqIdx_value_q <= '0;
      redirect_ftqOffset_q    <= '0;
      redirect_level_q        <= 1'b0;
      mmioF3Flush_q           <= 1'b0;
    end
    else begin
      redirect_valid_q <= io_ftqInter_fromFtq_redirect_valid;
      mmioF3Flush_q    <= f3_flush;
      if (io_ftqInter_fromFtq_redirect_valid) begin
        redirect_ftqIdx_flag_q  <= io_ftqInter_fromFtq_redirect_bits_ftqIdx_flag;
        redirect_ftqIdx_value_q <= io_ftqInter_fromFtq_redirect_bits_ftqIdx_value;
        redirect_ftqOffset_q    <= io_ftqInter_fromFtq_redirect_bits_ftqOffset;
        redirect_level_q        <= io_ftqInter_fromFtq_redirect_bits_level;
      end
    end
  end

  wire f3_ftq_flush_self     = redirect_valid_q & redirect_level_q;
  // isBefore(redirect.ftqIdx, f3.ftqIdx)
  wire f3_ftq_flush_by_older = redirect_valid_q
                             & (redirect_ftqIdx_flag_q ^ f3_ftqIdx_flag_q
                                ^ (redirect_ftqIdx_value_q < f3_ftqIdx_value_q));
  // 重定向来自这条 MMIO 指令之后（比它年轻）：MMIO 指令不该被冲
  wire f3_need_not_flush     = f3_req_is_mmio & redirect_valid_q & ~f3_ftq_flush_self & ~f3_ftq_flush_by_older;
  // MMIO 状态整体作废
  wire mmio_abort            = f3_ftq_flush_self | f3_ftq_flush_by_older | (mmioF3Flush_q & ~f3_need_not_flush);

  wire f3_mmio_req_commit = f3_req_is_mmio & (mmio_state_q == M_COMMITED);
  wire f3_mmio_to_commit  = f3_req_is_mmio & (mmio_state_q == M_WAIT_COMMIT);

  // ---- 握手 ----
  wire toUncache_fire   = io_uncacheInter_toUncache_ready & io_uncacheInter_toUncache_valid;
  wire fromUncache_fire = io_uncacheInter_fromUncache_valid;       // ready 恒 1
  wire itlb_req_fire    = io_iTLBInter_req_ready  & io_iTLBInter_req_valid;
  wire itlb_resp_fire   = io_iTLBInter_resp_ready & io_iTLBInter_resp_valid;

  // 这条 MMIO 指令自己提交了（它是块内第 0 条）
  logic [COMMIT_W-1:0] commit_hit;
  for (genvar c = 0; c < COMMIT_W; c++) begin : g_commit
    assign commit_hit[c] = io_rob_commits_valid[c]
                         & ({io_rob_commits_bits_ftqIdx_flag[c], io_rob_commits_bits_ftqIdx_value[c]} == f3_ftqIdx)
                         & (io_rob_commits_bits_ftqOffset[c] == 4'd0);
  end
  wire mmio_commit = |commit_hit;

  // ---- 各步的异常与分支条件 ----
  // WAIT_RESP：总线错优先；否则若 4 字节指令的前半在行内最后一个半字，看第二行的异常
  wire       uncache_is_rvc     = io_uncacheInter_fromUncache_bits_data[1:0] != 2'b11;
  wire [1:0] uncache_bus_exc    = io_uncacheInter_fromUncache_bits_corrupt ? EXC_AF : EXC_NONE;
  wire [1:0] uncache_cross_exc  = (~uncache_is_rvc & (f3_paddr0_q[BLOCK_OFF-1:0] == 6'h3E)) ? f3_exception_q[1] : EXC_NONE;
  wire [1:0] resp_exception     = exc_merge(uncache_bus_exc, uncache_cross_exc);
  // 一次总线读 8 字节对齐里的 4 字节窗口：指令起点在 8 字节块的最后一个半字时后半要重取
  wire       need_resend        = ~uncache_is_rvc & (f3_paddr0_q[2:1] == 2'b11) & (resp_exception == EXC_NONE);

  // TLB_RESP：页表异常优先（pf > gpf > af）；否则 pbmt 与第一次查的不一致算 access fault
  wire [1:0] tlb_exception      = io_iTLBInter_resp_bits_excp_0_pf_instr  ? EXC_PF
                                : io_iTLBInter_resp_bits_excp_0_gpf_instr ? EXC_GPF
                                : io_iTLBInter_resp_bits_excp_0_af_instr  ? EXC_AF
                                :                                           EXC_NONE;
  wire [1:0] tlb_pbmt_mismatch  = (io_iTLBInter_resp_bits_pbmt_0 != f3_itlb_pbmt_q) ? EXC_AF : EXC_NONE;
  wire [1:0] tlb_resp_exception = exc_merge(tlb_exception, tlb_pbmt_mismatch);

  // PMP_RESP：PMP 拒绝，或 mmio 属性与第一次查的不一致
  wire [1:0] pmp_exception      = io_pmp_resp_instr ? EXC_AF : EXC_NONE;
  wire [1:0] pmp_mmio_mismatch  = (io_pmp_resp_mmio != f3_pmp_mmio_q) ? EXC_AF : EXC_NONE;
  wire [1:0] pmp_resp_exception = exc_merge(pmp_exception, pmp_mmio_mismatch);

  // ---- 状态转移 ----
  mmio_state_e mmio_state_next;
  always_comb begin
    mmio_state_next = mmio_state_q;
    unique case (mmio_state_q)
      M_IDLE:
        // 幂等空间（NC）可以直接推测取；否则先等上一块提交完
        if (f3_req_is_mmio)   mmio_state_next = pbmt_is_nc ? M_SEND_REQ : M_WAIT_LAST_CMT;
      M_WAIT_LAST_CMT:
        if (is_first_instr_q | io_mmioCommitRead_mmioLastCommit) mmio_state_next = M_SEND_REQ;
      M_SEND_REQ:
        if (toUncache_fire)   mmio_state_next = M_WAIT_RESP;
      M_WAIT_RESP:
        if (fromUncache_fire) mmio_state_next = need_resend ? M_SEND_TLB : M_WAIT_COMMIT;
      M_SEND_TLB:
        if (itlb_req_fire)    mmio_state_next = M_TLB_RESP;
      M_TLB_RESP:
        if (itlb_resp_fire)   mmio_state_next = (tlb_resp_exception != EXC_NONE) ? M_WAIT_COMMIT : M_SEND_PMP;
      M_SEND_PMP:
                              mmio_state_next = M_PMP_RESP;
      M_PMP_RESP:
                              mmio_state_next = (pmp_resp_exception != EXC_NONE) ? M_WAIT_COMMIT : M_RESEND_REQ;
      M_RESEND_REQ:
        if (toUncache_fire)   mmio_state_next = M_WAIT_RESEND_RESP;
      M_WAIT_RESEND_RESP:
        if (fromUncache_fire) mmio_state_next = M_WAIT_COMMIT;
      M_WAIT_COMMIT:
        // 幂等空间不必真等提交，IBuffer 收下就算（但仍经过本状态，别的逻辑依赖它）
        if (mmio_commit | (pbmt_is_nc & io_toIbuffer_ready)) mmio_state_next = M_COMMITED;
      M_COMMITED:
                              mmio_state_next = M_IDLE;
      default: ;              // 12..15 非法编码：保持
    endcase
  end

  always_ff @(posedge clock or posedge reset) begin
    if (reset) begin
      mmio_state_q                    <= M_IDLE;
      mmio_exception_q                <= EXC_NONE;
      mmio_is_RVC_q                   <= 1'b0;
      mmio_has_resend_q               <= 1'b0;
      mmio_resend_addr_q              <= '0;
      mmio_resend_gpaddr_q            <= '0;
      mmio_resend_isForVSnonLeafPTE_q <= 1'b0;
    end
    else if (mmio_abort) begin
      mmio_state_q                    <= M_IDLE;
      mmio_exception_q                <= EXC_NONE;
      mmio_is_RVC_q                   <= 1'b0;
      mmio_has_resend_q               <= 1'b0;
      mmio_resend_addr_q              <= '0;
      mmio_resend_gpaddr_q            <= '0;
      mmio_resend_isForVSnonLeafPTE_q <= 1'b0;
    end
    else begin
      mmio_state_q <= mmio_state_next;
      unique case (mmio_state_q)
        M_WAIT_RESP:
          if (fromUncache_fire) begin
            mmio_exception_q  <= resp_exception;
            mmio_is_RVC_q     <= uncache_is_rvc;
            mmio_has_resend_q <= need_resend;
          end
        M_TLB_RESP:
          if (itlb_resp_fire) begin
            mmio_exception_q                <= tlb_resp_exception;
            mmio_resend_addr_q              <= io_iTLBInter_resp_bits_paddr_0;
            mmio_resend_gpaddr_q            <= io_iTLBInter_resp_bits_gpaddr_0[GPADDR_BITS-1:0];
            mmio_resend_isForVSnonLeafPTE_q <= io_iTLBInter_resp_bits_isForVSnonLeafPTE;
          end
        M_PMP_RESP:
          mmio_exception_q <= pmp_resp_exception;
        M_WAIT_RESEND_RESP:
          if (fromUncache_fire) mmio_exception_q <= uncache_bus_exc;
        M_COMMITED: begin
          mmio_exception_q                <= EXC_NONE;
          mmio_is_RVC_q                   <= 1'b0;
          mmio_has_resend_q               <= 1'b0;
          mmio_resend_addr_q              <= '0;
          mmio_resend_gpaddr_q            <= '0;
          mmio_resend_isForVSnonLeafPTE_q <= 1'b0;
        end
        default: ;
      endcase
    end
  end

  // 取回的指令数据（不复位）：第一次取回 32 位；重取回来的低 16 位是指令的高半
  always_ff @(posedge clock) begin
    if (mmio_abort) begin
      f3_mmio_data_q <= '0;
    end
    else if (fromUncache_fire & (mmio_state_q == M_WAIT_RESP)) begin
      f3_mmio_data_q[0] <= io_uncacheInter_fromUncache_bits_data[15:0];
      f3_mmio_data_q[1] <= io_uncacheInter_fromUncache_bits_data[31:16];
    end
    else if (fromUncache_fire & (mmio_state_q == M_WAIT_RESEND_RESP)) begin
      f3_mmio_data_q[1] <= io_uncacheInter_fromUncache_bits_data[15:0];
    end
  end

  // ---- 状态机对外的请求 ----
  wire in_resend_req = mmio_state_q == M_RESEND_REQ;
  assign io_uncacheInter_toUncache_valid = ((mmio_state_q == M_SEND_REQ) | in_resend_req) & f3_req_is_mmio;
  assign io_uncacheInter_toUncache_bits_addr          = in_resend_req ? mmio_resend_addr_q : f3_paddr0_q;
  assign io_uncacheInter_toUncache_bits_flush         = mmio_abort;
  // PMP 不认为是 MMIO → 实际是访问主存的 NC/IO 页，要告诉 L2
  assign io_uncacheInter_toUncache_bits_memBackTypeMM = ~f3_pmp_mmio_q;
  assign io_uncacheInter_toUncache_bits_memPageTypeNC = pbmt_is_nc;

  assign io_iTLBInter_req_valid      = (mmio_state_q == M_SEND_TLB) & f3_req_is_mmio;
  assign io_iTLBInter_req_bits_vaddr = f3_resend_vaddr_q;
  assign io_iTLBInter_resp_ready     = (mmio_state_q == M_TLB_RESP) & f3_req_is_mmio;
  assign io_pmp_req_valid            = (mmio_state_q == M_SEND_PMP) & f3_req_is_mmio;
  assign io_pmp_req_bits_addr        = mmio_resend_addr_q;

  // ---- 问 FTQ「上一个预测块提交完没有」：指针 = f3.ftqIdx - 1（环形指针减法）----
  logic                 mmioCommitRead_valid_q;
  logic                 mmioCommitRead_ptr_flag_q;
  logic [FTQ_IDX_W-1:0] mmioCommitRead_ptr_value_q;
  wire [FTQ_IDX_W:0]    f3_ftqIdx_minus1 = f3_ftqIdx + 7'h3F;   // +(FtqSize-1)，随后翻转 flag
  always_ff @(posedge clock or posedge reset) begin
    if (reset) mmioCommitRead_valid_q <= 1'b0;
    else       mmioCommitRead_valid_q <= f3_req_is_mmio & f3_valid_q;
  end
  always_ff @(posedge clock) begin
    mmioCommitRead_ptr_flag_q  <= ~f3_ftqIdx_minus1[FTQ_IDX_W];
    mmioCommitRead_ptr_value_q <= f3_ftqIdx_minus1[FTQ_IDX_W-1:0];
  end
  assign io_mmioCommitRead_valid            = mmioCommitRead_valid_q;
  assign io_mmioCommitRead_mmioFtqPtr_flag  = mmioCommitRead_ptr_flag_q;
  assign io_mmioCommitRead_mmioFtqPtr_value = mmioCommitRead_ptr_value_q;

  // ---- f3 装入新块后的那一拍（两份值恒等的寄存器，见文件头）----
  logic f3_entered_q;        // 给 wb_enable 用
  logic f3_entered_mmio_q;   // 给 f3_mmio_use_seq_pc 用
  logic uncache_resp_wb_q;        // RegNext(fromUncache.fire)，给 pdWb.valid 用
  logic uncache_resp_redirect_q;  // RegNext(fromUncache.fire)，给 mmio_redirect 用
  always_ff @(posedge clock) begin
    f3_entered_q            <= f2_fire & ~f2_flush;
    f3_entered_mmio_q       <= f2_fire & ~f2_flush;
    uncache_resp_wb_q       <= fromUncache_fire;
    uncache_resp_redirect_q <= fromUncache_fire;
  end

  // MMIO 块只送 IBuffer 一次
  wire f3_mmio_can_sent_to_ibuffer = f3_mmio_to_commit & ~f3_mmio_sent_to_ibuffer_q;
  // 后端重定向正好指向这条 MMIO 指令自己（要重取它）：
  wire redirect_mmio_req = redirect_valid_q
                         & ({redirect_ftqIdx_flag_q, redirect_ftqIdx_value_q} == f3_ftqIdx)
                         & (redirect_ftqOffset_q == 4'd0);

  always_ff @(posedge clock or posedge reset) begin
    if (reset) begin
      is_first_instr_q          <= 1'b1;
      f3_mmio_sent_to_ibuffer_q <= 1'b0;
      f3_mmio_use_seq_pc_q      <= 1'b0;
    end
    else begin
      if (is_first_instr_q & f3_fire) is_first_instr_q <= 1'b0;

      if (~f3_req_is_mmio)                        f3_mmio_sent_to_ibuffer_q <= 1'b0;
      else if (f3_mmio_req_commit | mmio_abort)   f3_mmio_sent_to_ibuffer_q <= 1'b0;
      else if (f3_fire)                           f3_mmio_sent_to_ibuffer_q <= 1'b1;

      if (f3_entered_mmio_q & f3_req_is_mmio)     f3_mmio_use_seq_pc_q <= 1'b1;
      else if (redirect_mmio_req)                 f3_mmio_use_seq_pc_q <= 1'b0;
    end
  end

  // 取回 MMIO 指令后的那一拍：让 FTQ 从这条指令的顺序下一条重新取（一个块只有它一条）
  assign mmio_redirect = f3_mmio_to_commit & uncache_resp_redirect_q & f3_mmio_use_seq_pc_q;

  // MMIO 指令的预译码（PreDecode 看到的是 ICache 的垃圾数据，这里对取回的指令另算）
  wire [31:0] mmio_inst     = {f3_mmio_data_q[1], f3_mmio_data_q[0]};
  wire [1:0]  mmio_brType   = xs_br_type(mmio_inst);
  wire        mmio_isCall   = xs_is_call(mmio_inst);
  wire        mmio_isRet    = xs_is_ret(mmio_inst);
  wire [31:0] mmio_expd_in  = f3_req_is_mmio ? mmio_inst : 32'h0;
  logic [31:0] mmio_expanded;
  logic        mmio_ill;
  xs_RVCExpander_core u_mmioRVCExpander (
    .io_in       (mmio_expd_in),
    .io_fsIsOff  (io_csr_fsIsOff),
    .io_out_bits (mmio_expanded),
    .io_ill      (mmio_ill)
  );

  // ===========================================================================
  // §6 f3 的 valid / last half / 入 IBuffer
  // ===========================================================================
  assign f3_ready = (io_toIbuffer_ready & (f3_mmio_req_commit | ~f3_req_is_mmio)) | ~f3_valid_q;
  assign f3_fire  = io_toIbuffer_ready & io_toIbuffer_valid;

  always_ff @(posedge clock or posedge reset) begin
    if (reset)                                                  f3_valid_q <= 1'b0;
    else if (f3_flush & ~f3_req_is_mmio)                        f3_valid_q <= 1'b0;
    else if (mmioF3Flush_q & f3_req_is_mmio & ~f3_need_not_flush) f3_valid_q <= 1'b0;
    else if (f2_fire & ~f2_flush)                               f3_valid_q <= 1'b1;
    else if (f3_fire & ~f3_req_is_mmio)                         f3_valid_q <= 1'b0;
    else if (f3_req_is_mmio & f3_mmio_req_commit)               f3_valid_q <= 1'b0;
  end

  always_ff @(posedge clock or posedge reset) begin
    if (reset) checker_fire_in_q <= 1'b0;
    else       checker_fire_in_q <= f2_fire;
  end

  // hasLastHalf(idx)：位置 idx 是一条在范围内、不跳的 4 字节指令 —— 它的后半在范围之外
  function automatic logic has_last_half(input logic [3:0] idx,
                                         input logic [PW-1:0] isRVC, input logic [PW-1:0] fixedRange,
                                         input logic [PW-1:0] instrValid, input logic [PW-1:0] fixedTaken,
                                         input logic is_mmio);
    return ~isRVC[idx] & fixedRange[idx] & instrValid[idx] & ~fixedTaken[idx] & ~is_mmio;
  endfunction

  // 范围内最后一个位置（最高位优先；全空时为 0）
  logic [3:0] f3_last_validIdx;
  always_comb begin
    f3_last_validIdx = 4'd0;
    for (int i = 0; i < PW; i++) if (chk_fixedRange[i]) f3_last_validIdx = 4'(i);
  end

  // 真 last half：块满 16 个半字，最后一个位置是 RVI 前半
  wire f3_hasLastHalf    = has_last_half(4'd15, f3_pd_isRVC_q, chk_fixedRange, f3_instr_valid, chk_fixedTaken, f3_req_is_mmio);
  // 假 last half：块没满却以 RVI 前半结尾（BPU 给的块尾落在指令中间）→ wb 级冲刷重取
  wire f3_false_lastHalf = has_last_half(f3_last_validIdx, f3_pd_isRVC_q, chk_fixedRange, f3_instr_valid, chk_fixedTaken, f3_req_is_mmio);
  wire [VADDR_BITS-1:0] f3_false_snpc = f3_half_snpc[f3_last_validIdx];

  logic wb_valid_q;
  logic hasLastHalf_dis_q, hasLastHalf_clr_q;   // RegNext(f3_hasLastHalf) ×2
  logic f3_fire_d_q;                            // RegNext(f3_fire)
  // wb 级发现「留了后半的那个块」其实最后位置预测错了：那半条指令不存在，撤销 last half
  wire  wb_lastHalf_mispred_dis = wb_valid_q & hasLastHalf_dis_q & chk_fixedMissPred[PW-1];
  wire  wb_lastHalf_mispred_clr = wb_valid_q & hasLastHalf_clr_q & chk_fixedMissPred[PW-1];

  always_ff @(posedge clock or posedge reset) begin
    if (reset) begin
      f3_lastHalf_valid_q   <= 1'b0;
      f3_lastHalf_disable_q <= 1'b0;
      hasLastHalf_dis_q     <= 1'b0;
      hasLastHalf_clr_q     <= 1'b0;
      f3_fire_d_q           <= 1'b0;
    end
    else begin
      hasLastHalf_dis_q <= f3_hasLastHalf;
      hasLastHalf_clr_q <= f3_hasLastHalf;
      f3_fire_d_q       <= f3_fire;

      // wb 与 f3_fire 同拍：直接清；否则 f3 还堵着：记 disable，等它发射时不置位
      if (wb_lastHalf_mispred_clr & f3_fire)  f3_lastHalf_valid_q <= 1'b0;
      else if (f3_flush)                      f3_lastHalf_valid_q <= 1'b0;
      else if (f3_fire)                       f3_lastHalf_valid_q <= f3_hasLastHalf & ~f3_lastHalf_disable_q;

      if (wb_lastHalf_mispred_dis & ~f3_fire & ~f3_fire_d_q & ~f3_flush)
                                                       f3_lastHalf_disable_q <= 1'b1;
      else if (f3_flush | (f3_fire & f3_lastHalf_disable_q)) f3_lastHalf_disable_q <= 1'b0;
    end
  end

  // ---- 送 IBuffer ----
  assign io_toIbuffer_valid = f3_valid_q & (~f3_req_is_mmio | f3_mmio_can_sent_to_ibuffer) & ~f3_flush;

  wire [PW-1:0] f3_lastHalf_mask = {{(PW-1){1'b1}}, 1'b0};   // 位置 0 是上一条的后半，不算
  assign io_toIbuffer_bits_valid     = f3_lastHalf_valid_q ? (f3_instr_valid & f3_lastHalf_mask) : f3_instr_valid;
  assign io_toIbuffer_bits_enqEnable = f3_req_is_mmio      ? PW'(1)
                                     : f3_lastHalf_valid_q ? (chk_fixedRange & f3_instr_valid & f3_lastHalf_mask)
                                     :                       (chk_fixedRange & f3_instr_valid);

  for (genvar i = 0; i < PW; i++) begin : g_toIbuffer
    wire [1:0] normal_exc = exc_merge(f3_exception_vec_q[i], f3_crossPage_exception_vec_q[i]);
    if (i == 0) begin : g_first
      // 位置 0 在 MMIO 块里换成取回的那条指令
      assign io_toIbuffer_bits_instrs[i]          = f3_req_is_mmio ? (mmio_ill ? mmio_expd_in : mmio_expanded) : f3_expd_instr[i];
      assign io_toIbuffer_bits_pd_isRVC[i]        = f3_req_is_mmio ? mmio_is_RVC_q : f3_pd_isRVC_q[i];
      assign io_toIbuffer_bits_pd_brType[i]       = f3_req_is_mmio ? mmio_brType   : f3_pd_brType[i];
      assign io_toIbuffer_bits_pd_isCall[i]       = f3_req_is_mmio ? mmio_isCall   : f3_pd_isCall[i];
      assign io_toIbuffer_bits_pd_isRet[i]        = f3_req_is_mmio ? mmio_isRet    : f3_pd_isRet[i];
      assign io_toIbuffer_bits_exceptionType[i]   = f3_req_is_mmio ? mmio_exception_q : normal_exc;
      // MMIO：只有重取过后半才可能是「后半页」的异常
      assign io_toIbuffer_bits_crossPageIPFFix[i] = f3_req_is_mmio ? (mmio_has_resend_q & (mmio_exception_q != EXC_NONE))
                                                                   : (f3_crossPage_exception_vec_q[i] != EXC_NONE);
      assign io_toIbuffer_bits_illegalInstr[i]    = f3_req_is_mmio ? mmio_ill : f3_ill[i];
    end
    else begin : g_rest
      assign io_toIbuffer_bits_instrs[i]          = f3_expd_instr[i];
      assign io_toIbuffer_bits_pd_valid[i]        = f3_pd_valid_q[i];
      assign io_toIbuffer_bits_pd_isRVC[i]        = f3_pd_isRVC_q[i];
      assign io_toIbuffer_bits_pd_brType[i]       = f3_pd_brType[i];
      assign io_toIbuffer_bits_pd_isCall[i]       = f3_pd_isCall[i];
      assign io_toIbuffer_bits_pd_isRet[i]        = f3_pd_isRet[i];
      assign io_toIbuffer_bits_exceptionType[i]   = normal_exc;
      assign io_toIbuffer_bits_crossPageIPFFix[i] = f3_crossPage_exception_vec_q[i] != EXC_NONE;
      assign io_toIbuffer_bits_illegalInstr[i]    = f3_ill[i];
    end
    assign io_toIbuffer_bits_ftqOffset_valid[i] = chk_fixedTaken[i] & ~f3_req_is_mmio;
    // 入队的最后一条（最高位的 enqEnable）
    if (i == PW - 1) begin : g_last_top
      assign io_toIbuffer_bits_isLastInFtqEntry[i] = io_toIbuffer_bits_enqEnable[i];
    end
    else begin : g_last
      assign io_toIbuffer_bits_isLastInFtqEntry[i] = io_toIbuffer_bits_enqEnable[i] & ~(|io_toIbuffer_bits_enqEnable[PW-1:i+1]);
    end
  end
  assign io_toIbuffer_bits_foldpc      = f3_foldpc_q;
  assign io_toIbuffer_bits_triggered   = f3_triggered;
  assign io_toIbuffer_bits_pc          = f3_pc;
  assign io_toIbuffer_bits_ftqPtr_flag  = f3_ftqIdx_flag_q;
  assign io_toIbuffer_bits_ftqPtr_value = f3_ftqIdx_value_q;
  // 这两项只对块内第一条指令有意义
  assign io_toIbuffer_bits_backendException_0         = f3_backendException_q;
  assign io_toIbuffer_bits_satpFlushFirstFetchFault_0 = f3_hasSatpFlush_q & (io_toIbuffer_bits_exceptionType[0] != EXC_NONE);

  // ---- guest 物理地址：只在 gpf 时写 ----
  assign io_toBackend_gpaddrMem_wen =
      io_toIbuffer_valid
    & (f3_req_is_mmio ? (mmio_exception_q == EXC_GPF)
                      : ((f3_exception_q[0] == EXC_GPF) | (f3_exception_q[1] == EXC_GPF)));
  assign io_toBackend_gpaddrMem_waddr                   = f3_ftqIdx_value_q;
  assign io_toBackend_gpaddrMem_wdata_gpaddr            = f3_req_is_mmio ? mmio_resend_gpaddr_q : f3_gpaddr_q;
  assign io_toBackend_gpaddrMem_wdata_isForVSnonLeafPTE = f3_req_is_mmio ? mmio_resend_isForVSnonLeafPTE_q : f3_isForVSnonLeafPTE_q;

  // ===========================================================================
  // §7 wb：预译码结果写回 FTQ，误预测则重定向
  // ===========================================================================
  // f3 装入新块后一拍（PredChecker 第 2 拍同时出结果）；MMIO 块不走这条路
  wire wb_enable = f3_entered_q & ~f3_req_is_mmio & ~f3_flush;

  logic                    wb_ftqIdx_flag_q;
  logic [FTQ_IDX_W-1:0]    wb_ftqIdx_value_q;
  logic [PW-1:0]           wb_fixedTaken_q;
  logic [PW-1:0]           wb_instr_range_q;
  logic [PW-1:0][PC_CUT:0] wb_pc_lower_q;
  logic [PC_HIGH_W-1:0]    wb_pc_high_q, wb_pc_high_plus1_q;
  logic [PW-1:0]           wb_pd_isRVC_q, wb_pd_isCall_q, wb_pd_isRet_q;
  logic [PW-1:0][1:0]      wb_pd_brType_q;
  logic [PW-1:0]           wb_instr_valid_q;
  logic [3:0]              wb_lastIdx_q;
  logic                    wb_false_lastHalf_q;
  logic [VADDR_BITS-1:0]   wb_false_target_q;

  always_ff @(posedge clock or posedge reset) begin
    if (reset) wb_valid_q <= 1'b0;
    else       wb_valid_q <= wb_enable;
  end

  always_ff @(posedge clock) begin
    if (wb_enable) begin
      wb_ftqIdx_flag_q    <= f3_ftqIdx_flag_q;
      wb_ftqIdx_value_q   <= f3_ftqIdx_value_q;
      wb_fixedTaken_q     <= chk_fixedTaken;
      wb_instr_range_q    <= io_toIbuffer_bits_enqEnable;
      wb_pc_lower_q       <= f3_pc_lower_q;
      wb_pc_high_q        <= f3_pc_high_q;
      wb_pc_high_plus1_q  <= f3_pc_high_plus1_q;
      wb_pd_isRVC_q       <= f3_pd_isRVC_q;
      wb_pd_brType_q      <= f3_pd_brType;
      wb_pd_isCall_q      <= f3_pd_isCall;
      wb_pd_isRet_q       <= f3_pd_isRet;
      wb_instr_valid_q    <= f3_instr_valid;
      wb_lastIdx_q        <= f3_last_validIdx;
      wb_false_lastHalf_q <= f3_false_lastHalf;
      wb_false_target_q   <= f3_false_snpc;
    end
  end

  // 假 last half：最后位置不是 15（是 15 的话是真 last half，不用冲）
  wire wb_half_flush = wb_false_lastHalf_q & (wb_lastIdx_q != 4'd15);

  assign f3_wb_not_flush = ({wb_ftqIdx_flag_q, wb_ftqIdx_value_q} == f3_ftqIdx) & f3_valid_q & wb_valid_q;

  // 最低位优先编码（全空时为 15，与 Chisel ParallelPriorityEncoder 一致）
  function automatic logic [3:0] first_set(input logic [PW-1:0] v);
    logic [3:0] idx;
    idx = 4'd15;
    for (int i = PW - 1; i >= 0; i--) if (v[i]) idx = 4'(i);
    return idx;
  endfunction

  wire [3:0] wb_first_miss_idx = first_set(chk_fixedMissPred);
  logic [PW-1:0] wb_is_jal;
  for (genvar i = 0; i < PW; i++) begin : g_wb_jal
    assign wb_is_jal[i] = wb_instr_valid_q[i] & (wb_pd_brType_q[i] == BR_JAL);
  end
  wire [3:0] wb_first_jal_idx  = first_set(wb_is_jal);

  wire checkFlushWb_misOffset_valid = (|chk_fixedMissPred) | wb_half_flush;
  assign wb_redirect = checkFlushWb_misOffset_valid & wb_valid_q;

  // MMIO 块的写回：取回指令后一拍，告诉 FTQ「位置 0 误预测，目标 = 顺序下一条」
  wire mmioFlushWb_valid = f3_mmio_to_commit & uncache_resp_wb_q & f3_mmio_use_seq_pc_q
                         & ~f3_ftq_flush_self & ~f3_ftq_flush_by_older;
  wire [VADDR_BITS-1:0] mmio_seq_target = f3_startAddr_q + (mmio_is_RVC_q ? VADDR_BITS'(2) : VADDR_BITS'(4));

  // pdWb = wb_valid ? 预测检查的写回 : MMIO 的写回
  assign io_ftqInter_toFtq_pdWb_valid = wb_valid_q | mmioFlushWb_valid;
  for (genvar i = 0; i < PW; i++) begin : g_pdWb
    wire [VADDR_BITS-1:0] wb_pc = cat_pc(wb_pc_lower_q[i], wb_pc_high_q, wb_pc_high_plus1_q);
    assign io_ftqInter_toFtq_pdWb_bits_pc[i]        = wb_valid_q ? wb_pc             : f3_pc[i];
    assign io_ftqInter_toFtq_pdWb_bits_pd_isRVC[i]  = wb_valid_q ? wb_pd_isRVC_q[i]  : io_toIbuffer_bits_pd_isRVC[i];
    assign io_ftqInter_toFtq_pdWb_bits_pd_brType[i] = wb_valid_q ? wb_pd_brType_q[i] : io_toIbuffer_bits_pd_brType[i];
    assign io_ftqInter_toFtq_pdWb_bits_pd_isCall[i] = wb_valid_q ? wb_pd_isCall_q[i] : io_toIbuffer_bits_pd_isCall[i];
    assign io_ftqInter_toFtq_pdWb_bits_pd_isRet[i]  = wb_valid_q ? wb_pd_isRet_q[i]  : io_toIbuffer_bits_pd_isRet[i];
    // MMIO 块只有位置 0 一条指令（f3_mmio_range）
    assign io_ftqInter_toFtq_pdWb_bits_pd_valid[i]   = wb_valid_q ? wb_instr_valid_q[i] : (i == 0);
    assign io_ftqInter_toFtq_pdWb_bits_instrRange[i] = wb_valid_q ? wb_instr_range_q[i] : (i == 0);
  end
  assign io_ftqInter_toFtq_pdWb_bits_ftqIdx_flag     = wb_valid_q ? wb_ftqIdx_flag_q  : f3_ftqIdx_flag_q;
  assign io_ftqInter_toFtq_pdWb_bits_ftqIdx_value    = wb_valid_q ? wb_ftqIdx_value_q : f3_ftqIdx_value_q;
  assign io_ftqInter_toFtq_pdWb_bits_misOffset_valid = wb_valid_q ? checkFlushWb_misOffset_valid : f3_req_is_mmio;
  assign io_ftqInter_toFtq_pdWb_bits_misOffset_bits  = ~wb_valid_q   ? 4'd0
                                                     : wb_half_flush ? wb_lastIdx_q
                                                     :                 wb_first_miss_idx;
  assign io_ftqInter_toFtq_pdWb_bits_cfiOffset_valid = wb_valid_q & (|wb_fixedTaken_q);
  assign io_ftqInter_toFtq_pdWb_bits_target          = ~wb_valid_q   ? mmio_seq_target
                                                     : wb_half_flush ? wb_false_target_q
                                                     :                 chk_fixedTarget[wb_first_miss_idx];
  assign io_ftqInter_toFtq_pdWb_bits_jalTarget       = wb_valid_q ? chk_jalTarget[wb_first_jal_idx] : '0;

  // ===========================================================================
  // §8 TopDown 气泡原因：跟着 f1/f2/f3 三级走（纯时钟驱动，不看 valid/ready）
  // ===========================================================================
  logic [STAGES-1:0][TOPDOWN_N-1:0] topdown_q;

  // 后端重定向的归因（优先级链，至多一项）
  wire td_valid   = io_ftqInter_fromFtq_topdown_redirect_valid;
  wire td_is_ctrl = io_ftqInter_fromFtq_topdown_redirect_bits_debugIsCtrl;
  wire td_br_hit  = io_ftqInter_fromFtq_topdown_redirect_bits_cfiUpdate_br_hit;
  wire td_jr_hit  = io_ftqInter_fromFtq_topdown_redirect_bits_cfiUpdate_jr_hit;
  wire td_sc_hit  = io_ftqInter_fromFtq_topdown_redirect_bits_cfiUpdate_sc_hit;
  wire td_is_ret  = io_ftqInter_fromFtq_topdown_redirect_bits_cfiUpdate_pd_isRet;

  logic [TOPDOWN_N-1:0] td_redirect_reason;
  always_comb begin
    td_redirect_reason = '0;
    if (td_valid) begin
      if (td_is_ctrl) begin
        if      (~td_br_hit & ~td_jr_hit) td_redirect_reason[TD_BTB_MISS]    = 1'b1;
        else if (td_br_hit & ~td_sc_hit)  td_redirect_reason[TD_TAGE_MISS]   = 1'b1;
        else if (td_br_hit &  td_sc_hit)  td_redirect_reason[TD_SC_MISS]     = 1'b1;
        else if (td_jr_hit & ~td_is_ret)  td_redirect_reason[TD_ITTAGE_MISS] = 1'b1;
        else if (td_jr_hit &  td_is_ret)  td_redirect_reason[TD_RAS_MISS]    = 1'b1;
      end
      else if (io_ftqInter_fromFtq_topdown_redirect_bits_debugIsMemVio)
        td_redirect_reason[TD_MEMVIO_REDIR] = 1'b1;
      else
        td_redirect_reason[TD_OTHER_REDIR]  = 1'b1;
    end
  end

  logic [STAGES-1:0][TOPDOWN_N-1:0] topdown_d;
  always_comb begin
    topdown_d[0] = io_ftqInter_fromFtq_req_bits_topdown_info_reasons;
    topdown_d[1] = topdown_q[0];
    topdown_d[2] = topdown_q[1];
    // ICache / ITLB miss 的气泡出现在 f2
    if (io_icacheInter_topdownIcacheMiss) topdown_d[1][TD_ICACHE_MISS] = 1'b1;
    if (io_icacheInter_topdownItlbMiss)   topdown_d[1][TD_ITLB_MISS]   = 1'b1;
    // 预译码重定向算 BTB miss：被冲的级都记；f3 与 wb 是同一块时 f3 也记
    if (wb_redirect) begin
      topdown_d[0][TD_BTB_MISS] = 1'b1;
      topdown_d[1][TD_BTB_MISS] = 1'b1;
      if (f3_wb_not_flush) topdown_d[2][TD_BTB_MISS] = 1'b1;
    end
    // 后端重定向：三级全记
    for (int s = 0; s < STAGES; s++) topdown_d[s] = topdown_d[s] | td_redirect_reason;
  end

  always_ff @(posedge clock or posedge reset) begin
    if (reset) topdown_q <= '0;
    else       topdown_q <= topdown_d;
  end
  assign io_toIbuffer_bits_topdown_info_reasons = topdown_q[STAGES-1] | td_redirect_reason;

  // ===========================================================================
  // §9 性能事件（每个事件打两拍后输出，值 0/1）
  // ===========================================================================
  wire f3_req_1 = f3_fire & f3_doubleLine_q;
  wire f3_hit_1 = f3_fire & f3_doubleLine_q & f3_perf_bank_hit_q[1];

  logic [12:0] perf_event;
  assign perf_event[0]  = wb_redirect;                       // frontendFlush
  assign perf_event[1]  = f3_fire;                           // ifu_req
  assign perf_event[2]  = f3_fire & ~f3_perf_hit_q;          // ifu_miss
  assign perf_event[3]  = f3_fire;                           // ifu_req_cacheline_0
  assign perf_event[4]  = f3_req_1;                          // ifu_req_cacheline_1
  assign perf_event[5]  = f3_hit_1;                          // ifu_req_cacheline_0_hit（原文如此，用的是 hit_1）
  assign perf_event[6]  = f3_hit_1;                          // ifu_req_cacheline_1_hit
  assign perf_event[7]  = f3_perf_only_0_hit_q    & f3_fire;
  assign perf_event[8]  = f3_perf_only_0_miss_q   & f3_fire;
  assign perf_event[9]  = f3_perf_hit_0_hit_1_q   & f3_fire;
  assign perf_event[10] = f3_perf_hit_0_miss_1_q  & f3_fire;
  assign perf_event[11] = f3_perf_miss_0_hit_1_q  & f3_fire;
  assign perf_event[12] = f3_perf_miss_0_miss_1_q & f3_fire;

  logic [1:0][12:0] perf_q;
  always_ff @(posedge clock) begin
    perf_q[0] <= perf_event;
    perf_q[1] <= perf_q[0];
  end
  for (genvar e = 0; e < 13; e++) begin : g_perf
    assign io_perf_value[e] = {5'h0, perf_q[1][e]};
  end

endmodule

// BEGIN GENERATED(wrapper)
// 自动生成：scripts/gen_newifu_lane.py —— 勿手改（端口表照抄 G1 golden，体里只做打包/拆包）
module NewIFU (
  input          clock,
  input          reset,
  output         io_ftqInter_fromFtq_req_ready,
  input          io_ftqInter_fromFtq_req_valid,
  input  [49:0]  io_ftqInter_fromFtq_req_bits_startAddr,
  input  [49:0]  io_ftqInter_fromFtq_req_bits_nextlineStart,
  input  [49:0]  io_ftqInter_fromFtq_req_bits_nextStartAddr,
  input          io_ftqInter_fromFtq_req_bits_ftqIdx_flag,
  input  [5:0]   io_ftqInter_fromFtq_req_bits_ftqIdx_value,
  input          io_ftqInter_fromFtq_req_bits_ftqOffset_valid,
  input  [3:0]   io_ftqInter_fromFtq_req_bits_ftqOffset_bits,
  input          io_ftqInter_fromFtq_req_bits_topdown_info_reasons_0,
  input          io_ftqInter_fromFtq_req_bits_topdown_info_reasons_1,
  input          io_ftqInter_fromFtq_req_bits_topdown_info_reasons_2,
  input          io_ftqInter_fromFtq_req_bits_topdown_info_reasons_3,
  input          io_ftqInter_fromFtq_req_bits_topdown_info_reasons_4,
  input          io_ftqInter_fromFtq_req_bits_topdown_info_reasons_5,
  input          io_ftqInter_fromFtq_req_bits_topdown_info_reasons_6,
  input          io_ftqInter_fromFtq_req_bits_topdown_info_reasons_7,
  input          io_ftqInter_fromFtq_req_bits_topdown_info_reasons_8,
  input          io_ftqInter_fromFtq_req_bits_topdown_info_reasons_9,
  input          io_ftqInter_fromFtq_req_bits_topdown_info_reasons_10,
  input          io_ftqInter_fromFtq_req_bits_topdown_info_reasons_11,
  input          io_ftqInter_fromFtq_req_bits_topdown_info_reasons_12,
  input          io_ftqInter_fromFtq_req_bits_topdown_info_reasons_13,
  input          io_ftqInter_fromFtq_req_bits_topdown_info_reasons_14,
  input          io_ftqInter_fromFtq_req_bits_topdown_info_reasons_15,
  input          io_ftqInter_fromFtq_req_bits_topdown_info_reasons_16,
  input          io_ftqInter_fromFtq_req_bits_topdown_info_reasons_17,
  input          io_ftqInter_fromFtq_req_bits_topdown_info_reasons_18,
  input          io_ftqInter_fromFtq_req_bits_topdown_info_reasons_19,
  input          io_ftqInter_fromFtq_req_bits_topdown_info_reasons_20,
  input          io_ftqInter_fromFtq_req_bits_topdown_info_reasons_21,
  input          io_ftqInter_fromFtq_req_bits_topdown_info_reasons_22,
  input          io_ftqInter_fromFtq_req_bits_topdown_info_reasons_23,
  input          io_ftqInter_fromFtq_req_bits_topdown_info_reasons_24,
  input          io_ftqInter_fromFtq_req_bits_topdown_info_reasons_25,
  input          io_ftqInter_fromFtq_req_bits_topdown_info_reasons_26,
  input          io_ftqInter_fromFtq_req_bits_topdown_info_reasons_27,
  input          io_ftqInter_fromFtq_req_bits_topdown_info_reasons_28,
  input          io_ftqInter_fromFtq_req_bits_topdown_info_reasons_29,
  input          io_ftqInter_fromFtq_req_bits_topdown_info_reasons_30,
  input          io_ftqInter_fromFtq_req_bits_topdown_info_reasons_31,
  input          io_ftqInter_fromFtq_req_bits_topdown_info_reasons_32,
  input          io_ftqInter_fromFtq_req_bits_topdown_info_reasons_33,
  input          io_ftqInter_fromFtq_req_bits_topdown_info_reasons_34,
  input          io_ftqInter_fromFtq_req_bits_topdown_info_reasons_35,
  input          io_ftqInter_fromFtq_req_bits_topdown_info_reasons_36,
  input          io_ftqInter_fromFtq_req_bits_topdown_info_reasons_37,
  input          io_ftqInter_fromFtq_redirect_valid,
  input          io_ftqInter_fromFtq_redirect_bits_ftqIdx_flag,
  input  [5:0]   io_ftqInter_fromFtq_redirect_bits_ftqIdx_value,
  input  [3:0]   io_ftqInter_fromFtq_redirect_bits_ftqOffset,
  input          io_ftqInter_fromFtq_redirect_bits_level,
  input          io_ftqInter_fromFtq_topdown_redirect_valid,
  input          io_ftqInter_fromFtq_topdown_redirect_bits_cfiUpdate_pd_isRet,
  input          io_ftqInter_fromFtq_topdown_redirect_bits_cfiUpdate_br_hit,
  input          io_ftqInter_fromFtq_topdown_redirect_bits_cfiUpdate_jr_hit,
  input          io_ftqInter_fromFtq_topdown_redirect_bits_cfiUpdate_sc_hit,
  input          io_ftqInter_fromFtq_topdown_redirect_bits_debugIsCtrl,
  input          io_ftqInter_fromFtq_topdown_redirect_bits_debugIsMemVio,
  input          io_ftqInter_fromFtq_flushFromBpu_s2_valid,
  input          io_ftqInter_fromFtq_flushFromBpu_s2_bits_flag,
  input  [5:0]   io_ftqInter_fromFtq_flushFromBpu_s2_bits_value,
  input          io_ftqInter_fromFtq_flushFromBpu_s3_valid,
  input          io_ftqInter_fromFtq_flushFromBpu_s3_bits_flag,
  input  [5:0]   io_ftqInter_fromFtq_flushFromBpu_s3_bits_value,
  output         io_ftqInter_toFtq_pdWb_valid,
  output [49:0]  io_ftqInter_toFtq_pdWb_bits_pc_0,
  output [49:0]  io_ftqInter_toFtq_pdWb_bits_pc_1,
  output [49:0]  io_ftqInter_toFtq_pdWb_bits_pc_2,
  output [49:0]  io_ftqInter_toFtq_pdWb_bits_pc_3,
  output [49:0]  io_ftqInter_toFtq_pdWb_bits_pc_4,
  output [49:0]  io_ftqInter_toFtq_pdWb_bits_pc_5,
  output [49:0]  io_ftqInter_toFtq_pdWb_bits_pc_6,
  output [49:0]  io_ftqInter_toFtq_pdWb_bits_pc_7,
  output [49:0]  io_ftqInter_toFtq_pdWb_bits_pc_8,
  output [49:0]  io_ftqInter_toFtq_pdWb_bits_pc_9,
  output [49:0]  io_ftqInter_toFtq_pdWb_bits_pc_10,
  output [49:0]  io_ftqInter_toFtq_pdWb_bits_pc_11,
  output [49:0]  io_ftqInter_toFtq_pdWb_bits_pc_12,
  output [49:0]  io_ftqInter_toFtq_pdWb_bits_pc_13,
  output [49:0]  io_ftqInter_toFtq_pdWb_bits_pc_14,
  output [49:0]  io_ftqInter_toFtq_pdWb_bits_pc_15,
  output         io_ftqInter_toFtq_pdWb_bits_pd_0_valid,
  output         io_ftqInter_toFtq_pdWb_bits_pd_0_isRVC,
  output [1:0]   io_ftqInter_toFtq_pdWb_bits_pd_0_brType,
  output         io_ftqInter_toFtq_pdWb_bits_pd_0_isCall,
  output         io_ftqInter_toFtq_pdWb_bits_pd_0_isRet,
  output         io_ftqInter_toFtq_pdWb_bits_pd_1_valid,
  output         io_ftqInter_toFtq_pdWb_bits_pd_1_isRVC,
  output [1:0]   io_ftqInter_toFtq_pdWb_bits_pd_1_brType,
  output         io_ftqInter_toFtq_pdWb_bits_pd_1_isCall,
  output         io_ftqInter_toFtq_pdWb_bits_pd_1_isRet,
  output         io_ftqInter_toFtq_pdWb_bits_pd_2_valid,
  output         io_ftqInter_toFtq_pdWb_bits_pd_2_isRVC,
  output [1:0]   io_ftqInter_toFtq_pdWb_bits_pd_2_brType,
  output         io_ftqInter_toFtq_pdWb_bits_pd_2_isCall,
  output         io_ftqInter_toFtq_pdWb_bits_pd_2_isRet,
  output         io_ftqInter_toFtq_pdWb_bits_pd_3_valid,
  output         io_ftqInter_toFtq_pdWb_bits_pd_3_isRVC,
  output [1:0]   io_ftqInter_toFtq_pdWb_bits_pd_3_brType,
  output         io_ftqInter_toFtq_pdWb_bits_pd_3_isCall,
  output         io_ftqInter_toFtq_pdWb_bits_pd_3_isRet,
  output         io_ftqInter_toFtq_pdWb_bits_pd_4_valid,
  output         io_ftqInter_toFtq_pdWb_bits_pd_4_isRVC,
  output [1:0]   io_ftqInter_toFtq_pdWb_bits_pd_4_brType,
  output         io_ftqInter_toFtq_pdWb_bits_pd_4_isCall,
  output         io_ftqInter_toFtq_pdWb_bits_pd_4_isRet,
  output         io_ftqInter_toFtq_pdWb_bits_pd_5_valid,
  output         io_ftqInter_toFtq_pdWb_bits_pd_5_isRVC,
  output [1:0]   io_ftqInter_toFtq_pdWb_bits_pd_5_brType,
  output         io_ftqInter_toFtq_pdWb_bits_pd_5_isCall,
  output         io_ftqInter_toFtq_pdWb_bits_pd_5_isRet,
  output         io_ftqInter_toFtq_pdWb_bits_pd_6_valid,
  output         io_ftqInter_toFtq_pdWb_bits_pd_6_isRVC,
  output [1:0]   io_ftqInter_toFtq_pdWb_bits_pd_6_brType,
  output         io_ftqInter_toFtq_pdWb_bits_pd_6_isCall,
  output         io_ftqInter_toFtq_pdWb_bits_pd_6_isRet,
  output         io_ftqInter_toFtq_pdWb_bits_pd_7_valid,
  output         io_ftqInter_toFtq_pdWb_bits_pd_7_isRVC,
  output [1:0]   io_ftqInter_toFtq_pdWb_bits_pd_7_brType,
  output         io_ftqInter_toFtq_pdWb_bits_pd_7_isCall,
  output         io_ftqInter_toFtq_pdWb_bits_pd_7_isRet,
  output         io_ftqInter_toFtq_pdWb_bits_pd_8_valid,
  output         io_ftqInter_toFtq_pdWb_bits_pd_8_isRVC,
  output [1:0]   io_ftqInter_toFtq_pdWb_bits_pd_8_brType,
  output         io_ftqInter_toFtq_pdWb_bits_pd_8_isCall,
  output         io_ftqInter_toFtq_pdWb_bits_pd_8_isRet,
  output         io_ftqInter_toFtq_pdWb_bits_pd_9_valid,
  output         io_ftqInter_toFtq_pdWb_bits_pd_9_isRVC,
  output [1:0]   io_ftqInter_toFtq_pdWb_bits_pd_9_brType,
  output         io_ftqInter_toFtq_pdWb_bits_pd_9_isCall,
  output         io_ftqInter_toFtq_pdWb_bits_pd_9_isRet,
  output         io_ftqInter_toFtq_pdWb_bits_pd_10_valid,
  output         io_ftqInter_toFtq_pdWb_bits_pd_10_isRVC,
  output [1:0]   io_ftqInter_toFtq_pdWb_bits_pd_10_brType,
  output         io_ftqInter_toFtq_pdWb_bits_pd_10_isCall,
  output         io_ftqInter_toFtq_pdWb_bits_pd_10_isRet,
  output         io_ftqInter_toFtq_pdWb_bits_pd_11_valid,
  output         io_ftqInter_toFtq_pdWb_bits_pd_11_isRVC,
  output [1:0]   io_ftqInter_toFtq_pdWb_bits_pd_11_brType,
  output         io_ftqInter_toFtq_pdWb_bits_pd_11_isCall,
  output         io_ftqInter_toFtq_pdWb_bits_pd_11_isRet,
  output         io_ftqInter_toFtq_pdWb_bits_pd_12_valid,
  output         io_ftqInter_toFtq_pdWb_bits_pd_12_isRVC,
  output [1:0]   io_ftqInter_toFtq_pdWb_bits_pd_12_brType,
  output         io_ftqInter_toFtq_pdWb_bits_pd_12_isCall,
  output         io_ftqInter_toFtq_pdWb_bits_pd_12_isRet,
  output         io_ftqInter_toFtq_pdWb_bits_pd_13_valid,
  output         io_ftqInter_toFtq_pdWb_bits_pd_13_isRVC,
  output [1:0]   io_ftqInter_toFtq_pdWb_bits_pd_13_brType,
  output         io_ftqInter_toFtq_pdWb_bits_pd_13_isCall,
  output         io_ftqInter_toFtq_pdWb_bits_pd_13_isRet,
  output         io_ftqInter_toFtq_pdWb_bits_pd_14_valid,
  output         io_ftqInter_toFtq_pdWb_bits_pd_14_isRVC,
  output [1:0]   io_ftqInter_toFtq_pdWb_bits_pd_14_brType,
  output         io_ftqInter_toFtq_pdWb_bits_pd_14_isCall,
  output         io_ftqInter_toFtq_pdWb_bits_pd_14_isRet,
  output         io_ftqInter_toFtq_pdWb_bits_pd_15_valid,
  output         io_ftqInter_toFtq_pdWb_bits_pd_15_isRVC,
  output [1:0]   io_ftqInter_toFtq_pdWb_bits_pd_15_brType,
  output         io_ftqInter_toFtq_pdWb_bits_pd_15_isCall,
  output         io_ftqInter_toFtq_pdWb_bits_pd_15_isRet,
  output         io_ftqInter_toFtq_pdWb_bits_ftqIdx_flag,
  output [5:0]   io_ftqInter_toFtq_pdWb_bits_ftqIdx_value,
  output         io_ftqInter_toFtq_pdWb_bits_misOffset_valid,
  output [3:0]   io_ftqInter_toFtq_pdWb_bits_misOffset_bits,
  output         io_ftqInter_toFtq_pdWb_bits_cfiOffset_valid,
  output [49:0]  io_ftqInter_toFtq_pdWb_bits_target,
  output [49:0]  io_ftqInter_toFtq_pdWb_bits_jalTarget,
  output         io_ftqInter_toFtq_pdWb_bits_instrRange_0,
  output         io_ftqInter_toFtq_pdWb_bits_instrRange_1,
  output         io_ftqInter_toFtq_pdWb_bits_instrRange_2,
  output         io_ftqInter_toFtq_pdWb_bits_instrRange_3,
  output         io_ftqInter_toFtq_pdWb_bits_instrRange_4,
  output         io_ftqInter_toFtq_pdWb_bits_instrRange_5,
  output         io_ftqInter_toFtq_pdWb_bits_instrRange_6,
  output         io_ftqInter_toFtq_pdWb_bits_instrRange_7,
  output         io_ftqInter_toFtq_pdWb_bits_instrRange_8,
  output         io_ftqInter_toFtq_pdWb_bits_instrRange_9,
  output         io_ftqInter_toFtq_pdWb_bits_instrRange_10,
  output         io_ftqInter_toFtq_pdWb_bits_instrRange_11,
  output         io_ftqInter_toFtq_pdWb_bits_instrRange_12,
  output         io_ftqInter_toFtq_pdWb_bits_instrRange_13,
  output         io_ftqInter_toFtq_pdWb_bits_instrRange_14,
  output         io_ftqInter_toFtq_pdWb_bits_instrRange_15,
  input          io_icacheInter_icacheReady,
  input          io_icacheInter_resp_valid,
  input          io_icacheInter_resp_bits_doubleline,
  input  [49:0]  io_icacheInter_resp_bits_vaddr_0,
  input  [49:0]  io_icacheInter_resp_bits_vaddr_1,
  input  [511:0] io_icacheInter_resp_bits_data,
  input  [47:0]  io_icacheInter_resp_bits_paddr_0,
  input  [1:0]   io_icacheInter_resp_bits_exception_0,
  input  [1:0]   io_icacheInter_resp_bits_exception_1,
  input          io_icacheInter_resp_bits_pmp_mmio_0,
  input          io_icacheInter_resp_bits_pmp_mmio_1,
  input  [1:0]   io_icacheInter_resp_bits_itlb_pbmt_0,
  input  [1:0]   io_icacheInter_resp_bits_itlb_pbmt_1,
  input          io_icacheInter_resp_bits_backendException,
  input          io_icacheInter_resp_bits_hasSatpFlush,
  input  [55:0]  io_icacheInter_resp_bits_gpaddr,
  input          io_icacheInter_resp_bits_isForVSnonLeafPTE,
  input          io_icacheInter_topdownIcacheMiss,
  input          io_icacheInter_topdownItlbMiss,
  output         io_icacheStop,
  input          io_icachePerfInfo_only_0_hit,
  input          io_icachePerfInfo_only_0_miss,
  input          io_icachePerfInfo_hit_0_hit_1,
  input          io_icachePerfInfo_hit_0_miss_1,
  input          io_icachePerfInfo_miss_0_hit_1,
  input          io_icachePerfInfo_miss_0_miss_1,
  input          io_icachePerfInfo_hit_0_except_1,
  input          io_icachePerfInfo_miss_0_except_1,
  input          io_icachePerfInfo_except_0,
  input          io_icachePerfInfo_bank_hit_0,
  input          io_icachePerfInfo_bank_hit_1,
  input          io_icachePerfInfo_hit,
  input          io_toIbuffer_ready,
  output         io_toIbuffer_valid,
  output [31:0]  io_toIbuffer_bits_instrs_0,
  output [31:0]  io_toIbuffer_bits_instrs_1,
  output [31:0]  io_toIbuffer_bits_instrs_2,
  output [31:0]  io_toIbuffer_bits_instrs_3,
  output [31:0]  io_toIbuffer_bits_instrs_4,
  output [31:0]  io_toIbuffer_bits_instrs_5,
  output [31:0]  io_toIbuffer_bits_instrs_6,
  output [31:0]  io_toIbuffer_bits_instrs_7,
  output [31:0]  io_toIbuffer_bits_instrs_8,
  output [31:0]  io_toIbuffer_bits_instrs_9,
  output [31:0]  io_toIbuffer_bits_instrs_10,
  output [31:0]  io_toIbuffer_bits_instrs_11,
  output [31:0]  io_toIbuffer_bits_instrs_12,
  output [31:0]  io_toIbuffer_bits_instrs_13,
  output [31:0]  io_toIbuffer_bits_instrs_14,
  output [31:0]  io_toIbuffer_bits_instrs_15,
  output [15:0]  io_toIbuffer_bits_valid,
  output [15:0]  io_toIbuffer_bits_enqEnable,
  output         io_toIbuffer_bits_pd_0_isRVC,
  output [1:0]   io_toIbuffer_bits_pd_0_brType,
  output         io_toIbuffer_bits_pd_0_isCall,
  output         io_toIbuffer_bits_pd_0_isRet,
  output         io_toIbuffer_bits_pd_1_valid,
  output         io_toIbuffer_bits_pd_1_isRVC,
  output [1:0]   io_toIbuffer_bits_pd_1_brType,
  output         io_toIbuffer_bits_pd_1_isCall,
  output         io_toIbuffer_bits_pd_1_isRet,
  output         io_toIbuffer_bits_pd_2_valid,
  output         io_toIbuffer_bits_pd_2_isRVC,
  output [1:0]   io_toIbuffer_bits_pd_2_brType,
  output         io_toIbuffer_bits_pd_2_isCall,
  output         io_toIbuffer_bits_pd_2_isRet,
  output         io_toIbuffer_bits_pd_3_valid,
  output         io_toIbuffer_bits_pd_3_isRVC,
  output [1:0]   io_toIbuffer_bits_pd_3_brType,
  output         io_toIbuffer_bits_pd_3_isCall,
  output         io_toIbuffer_bits_pd_3_isRet,
  output         io_toIbuffer_bits_pd_4_valid,
  output         io_toIbuffer_bits_pd_4_isRVC,
  output [1:0]   io_toIbuffer_bits_pd_4_brType,
  output         io_toIbuffer_bits_pd_4_isCall,
  output         io_toIbuffer_bits_pd_4_isRet,
  output         io_toIbuffer_bits_pd_5_valid,
  output         io_toIbuffer_bits_pd_5_isRVC,
  output [1:0]   io_toIbuffer_bits_pd_5_brType,
  output         io_toIbuffer_bits_pd_5_isCall,
  output         io_toIbuffer_bits_pd_5_isRet,
  output         io_toIbuffer_bits_pd_6_valid,
  output         io_toIbuffer_bits_pd_6_isRVC,
  output [1:0]   io_toIbuffer_bits_pd_6_brType,
  output         io_toIbuffer_bits_pd_6_isCall,
  output         io_toIbuffer_bits_pd_6_isRet,
  output         io_toIbuffer_bits_pd_7_valid,
  output         io_toIbuffer_bits_pd_7_isRVC,
  output [1:0]   io_toIbuffer_bits_pd_7_brType,
  output         io_toIbuffer_bits_pd_7_isCall,
  output         io_toIbuffer_bits_pd_7_isRet,
  output         io_toIbuffer_bits_pd_8_valid,
  output         io_toIbuffer_bits_pd_8_isRVC,
  output [1:0]   io_toIbuffer_bits_pd_8_brType,
  output         io_toIbuffer_bits_pd_8_isCall,
  output         io_toIbuffer_bits_pd_8_isRet,
  output         io_toIbuffer_bits_pd_9_valid,
  output         io_toIbuffer_bits_pd_9_isRVC,
  output [1:0]   io_toIbuffer_bits_pd_9_brType,
  output         io_toIbuffer_bits_pd_9_isCall,
  output         io_toIbuffer_bits_pd_9_isRet,
  output         io_toIbuffer_bits_pd_10_valid,
  output         io_toIbuffer_bits_pd_10_isRVC,
  output [1:0]   io_toIbuffer_bits_pd_10_brType,
  output         io_toIbuffer_bits_pd_10_isCall,
  output         io_toIbuffer_bits_pd_10_isRet,
  output         io_toIbuffer_bits_pd_11_valid,
  output         io_toIbuffer_bits_pd_11_isRVC,
  output [1:0]   io_toIbuffer_bits_pd_11_brType,
  output         io_toIbuffer_bits_pd_11_isCall,
  output         io_toIbuffer_bits_pd_11_isRet,
  output         io_toIbuffer_bits_pd_12_valid,
  output         io_toIbuffer_bits_pd_12_isRVC,
  output [1:0]   io_toIbuffer_bits_pd_12_brType,
  output         io_toIbuffer_bits_pd_12_isCall,
  output         io_toIbuffer_bits_pd_12_isRet,
  output         io_toIbuffer_bits_pd_13_valid,
  output         io_toIbuffer_bits_pd_13_isRVC,
  output [1:0]   io_toIbuffer_bits_pd_13_brType,
  output         io_toIbuffer_bits_pd_13_isCall,
  output         io_toIbuffer_bits_pd_13_isRet,
  output         io_toIbuffer_bits_pd_14_valid,
  output         io_toIbuffer_bits_pd_14_isRVC,
  output [1:0]   io_toIbuffer_bits_pd_14_brType,
  output         io_toIbuffer_bits_pd_14_isCall,
  output         io_toIbuffer_bits_pd_14_isRet,
  output         io_toIbuffer_bits_pd_15_valid,
  output         io_toIbuffer_bits_pd_15_isRVC,
  output [1:0]   io_toIbuffer_bits_pd_15_brType,
  output         io_toIbuffer_bits_pd_15_isCall,
  output         io_toIbuffer_bits_pd_15_isRet,
  output [9:0]   io_toIbuffer_bits_foldpc_0,
  output [9:0]   io_toIbuffer_bits_foldpc_1,
  output [9:0]   io_toIbuffer_bits_foldpc_2,
  output [9:0]   io_toIbuffer_bits_foldpc_3,
  output [9:0]   io_toIbuffer_bits_foldpc_4,
  output [9:0]   io_toIbuffer_bits_foldpc_5,
  output [9:0]   io_toIbuffer_bits_foldpc_6,
  output [9:0]   io_toIbuffer_bits_foldpc_7,
  output [9:0]   io_toIbuffer_bits_foldpc_8,
  output [9:0]   io_toIbuffer_bits_foldpc_9,
  output [9:0]   io_toIbuffer_bits_foldpc_10,
  output [9:0]   io_toIbuffer_bits_foldpc_11,
  output [9:0]   io_toIbuffer_bits_foldpc_12,
  output [9:0]   io_toIbuffer_bits_foldpc_13,
  output [9:0]   io_toIbuffer_bits_foldpc_14,
  output [9:0]   io_toIbuffer_bits_foldpc_15,
  output         io_toIbuffer_bits_ftqOffset_0_valid,
  output         io_toIbuffer_bits_ftqOffset_1_valid,
  output         io_toIbuffer_bits_ftqOffset_2_valid,
  output         io_toIbuffer_bits_ftqOffset_3_valid,
  output         io_toIbuffer_bits_ftqOffset_4_valid,
  output         io_toIbuffer_bits_ftqOffset_5_valid,
  output         io_toIbuffer_bits_ftqOffset_6_valid,
  output         io_toIbuffer_bits_ftqOffset_7_valid,
  output         io_toIbuffer_bits_ftqOffset_8_valid,
  output         io_toIbuffer_bits_ftqOffset_9_valid,
  output         io_toIbuffer_bits_ftqOffset_10_valid,
  output         io_toIbuffer_bits_ftqOffset_11_valid,
  output         io_toIbuffer_bits_ftqOffset_12_valid,
  output         io_toIbuffer_bits_ftqOffset_13_valid,
  output         io_toIbuffer_bits_ftqOffset_14_valid,
  output         io_toIbuffer_bits_ftqOffset_15_valid,
  output         io_toIbuffer_bits_backendException_0,
  output         io_toIbuffer_bits_satpFlushFirstFetchFault_0,
  output [1:0]   io_toIbuffer_bits_exceptionType_0,
  output [1:0]   io_toIbuffer_bits_exceptionType_1,
  output [1:0]   io_toIbuffer_bits_exceptionType_2,
  output [1:0]   io_toIbuffer_bits_exceptionType_3,
  output [1:0]   io_toIbuffer_bits_exceptionType_4,
  output [1:0]   io_toIbuffer_bits_exceptionType_5,
  output [1:0]   io_toIbuffer_bits_exceptionType_6,
  output [1:0]   io_toIbuffer_bits_exceptionType_7,
  output [1:0]   io_toIbuffer_bits_exceptionType_8,
  output [1:0]   io_toIbuffer_bits_exceptionType_9,
  output [1:0]   io_toIbuffer_bits_exceptionType_10,
  output [1:0]   io_toIbuffer_bits_exceptionType_11,
  output [1:0]   io_toIbuffer_bits_exceptionType_12,
  output [1:0]   io_toIbuffer_bits_exceptionType_13,
  output [1:0]   io_toIbuffer_bits_exceptionType_14,
  output [1:0]   io_toIbuffer_bits_exceptionType_15,
  output         io_toIbuffer_bits_crossPageIPFFix_0,
  output         io_toIbuffer_bits_crossPageIPFFix_1,
  output         io_toIbuffer_bits_crossPageIPFFix_2,
  output         io_toIbuffer_bits_crossPageIPFFix_3,
  output         io_toIbuffer_bits_crossPageIPFFix_4,
  output         io_toIbuffer_bits_crossPageIPFFix_5,
  output         io_toIbuffer_bits_crossPageIPFFix_6,
  output         io_toIbuffer_bits_crossPageIPFFix_7,
  output         io_toIbuffer_bits_crossPageIPFFix_8,
  output         io_toIbuffer_bits_crossPageIPFFix_9,
  output         io_toIbuffer_bits_crossPageIPFFix_10,
  output         io_toIbuffer_bits_crossPageIPFFix_11,
  output         io_toIbuffer_bits_crossPageIPFFix_12,
  output         io_toIbuffer_bits_crossPageIPFFix_13,
  output         io_toIbuffer_bits_crossPageIPFFix_14,
  output         io_toIbuffer_bits_crossPageIPFFix_15,
  output         io_toIbuffer_bits_illegalInstr_0,
  output         io_toIbuffer_bits_illegalInstr_1,
  output         io_toIbuffer_bits_illegalInstr_2,
  output         io_toIbuffer_bits_illegalInstr_3,
  output         io_toIbuffer_bits_illegalInstr_4,
  output         io_toIbuffer_bits_illegalInstr_5,
  output         io_toIbuffer_bits_illegalInstr_6,
  output         io_toIbuffer_bits_illegalInstr_7,
  output         io_toIbuffer_bits_illegalInstr_8,
  output         io_toIbuffer_bits_illegalInstr_9,
  output         io_toIbuffer_bits_illegalInstr_10,
  output         io_toIbuffer_bits_illegalInstr_11,
  output         io_toIbuffer_bits_illegalInstr_12,
  output         io_toIbuffer_bits_illegalInstr_13,
  output         io_toIbuffer_bits_illegalInstr_14,
  output         io_toIbuffer_bits_illegalInstr_15,
  output [3:0]   io_toIbuffer_bits_triggered_0,
  output [3:0]   io_toIbuffer_bits_triggered_1,
  output [3:0]   io_toIbuffer_bits_triggered_2,
  output [3:0]   io_toIbuffer_bits_triggered_3,
  output [3:0]   io_toIbuffer_bits_triggered_4,
  output [3:0]   io_toIbuffer_bits_triggered_5,
  output [3:0]   io_toIbuffer_bits_triggered_6,
  output [3:0]   io_toIbuffer_bits_triggered_7,
  output [3:0]   io_toIbuffer_bits_triggered_8,
  output [3:0]   io_toIbuffer_bits_triggered_9,
  output [3:0]   io_toIbuffer_bits_triggered_10,
  output [3:0]   io_toIbuffer_bits_triggered_11,
  output [3:0]   io_toIbuffer_bits_triggered_12,
  output [3:0]   io_toIbuffer_bits_triggered_13,
  output [3:0]   io_toIbuffer_bits_triggered_14,
  output [3:0]   io_toIbuffer_bits_triggered_15,
  output         io_toIbuffer_bits_isLastInFtqEntry_0,
  output         io_toIbuffer_bits_isLastInFtqEntry_1,
  output         io_toIbuffer_bits_isLastInFtqEntry_2,
  output         io_toIbuffer_bits_isLastInFtqEntry_3,
  output         io_toIbuffer_bits_isLastInFtqEntry_4,
  output         io_toIbuffer_bits_isLastInFtqEntry_5,
  output         io_toIbuffer_bits_isLastInFtqEntry_6,
  output         io_toIbuffer_bits_isLastInFtqEntry_7,
  output         io_toIbuffer_bits_isLastInFtqEntry_8,
  output         io_toIbuffer_bits_isLastInFtqEntry_9,
  output         io_toIbuffer_bits_isLastInFtqEntry_10,
  output         io_toIbuffer_bits_isLastInFtqEntry_11,
  output         io_toIbuffer_bits_isLastInFtqEntry_12,
  output         io_toIbuffer_bits_isLastInFtqEntry_13,
  output         io_toIbuffer_bits_isLastInFtqEntry_14,
  output         io_toIbuffer_bits_isLastInFtqEntry_15,
  output [49:0]  io_toIbuffer_bits_pc_0,
  output [49:0]  io_toIbuffer_bits_pc_1,
  output [49:0]  io_toIbuffer_bits_pc_2,
  output [49:0]  io_toIbuffer_bits_pc_3,
  output [49:0]  io_toIbuffer_bits_pc_4,
  output [49:0]  io_toIbuffer_bits_pc_5,
  output [49:0]  io_toIbuffer_bits_pc_6,
  output [49:0]  io_toIbuffer_bits_pc_7,
  output [49:0]  io_toIbuffer_bits_pc_8,
  output [49:0]  io_toIbuffer_bits_pc_9,
  output [49:0]  io_toIbuffer_bits_pc_10,
  output [49:0]  io_toIbuffer_bits_pc_11,
  output [49:0]  io_toIbuffer_bits_pc_12,
  output [49:0]  io_toIbuffer_bits_pc_13,
  output [49:0]  io_toIbuffer_bits_pc_14,
  output [49:0]  io_toIbuffer_bits_pc_15,
  output         io_toIbuffer_bits_ftqPtr_flag,
  output [5:0]   io_toIbuffer_bits_ftqPtr_value,
  output         io_toIbuffer_bits_topdown_info_reasons_0,
  output         io_toIbuffer_bits_topdown_info_reasons_1,
  output         io_toIbuffer_bits_topdown_info_reasons_2,
  output         io_toIbuffer_bits_topdown_info_reasons_3,
  output         io_toIbuffer_bits_topdown_info_reasons_4,
  output         io_toIbuffer_bits_topdown_info_reasons_5,
  output         io_toIbuffer_bits_topdown_info_reasons_6,
  output         io_toIbuffer_bits_topdown_info_reasons_7,
  output         io_toIbuffer_bits_topdown_info_reasons_8,
  output         io_toIbuffer_bits_topdown_info_reasons_9,
  output         io_toIbuffer_bits_topdown_info_reasons_10,
  output         io_toIbuffer_bits_topdown_info_reasons_11,
  output         io_toIbuffer_bits_topdown_info_reasons_12,
  output         io_toIbuffer_bits_topdown_info_reasons_13,
  output         io_toIbuffer_bits_topdown_info_reasons_14,
  output         io_toIbuffer_bits_topdown_info_reasons_15,
  output         io_toIbuffer_bits_topdown_info_reasons_16,
  output         io_toIbuffer_bits_topdown_info_reasons_17,
  output         io_toIbuffer_bits_topdown_info_reasons_18,
  output         io_toIbuffer_bits_topdown_info_reasons_19,
  output         io_toIbuffer_bits_topdown_info_reasons_20,
  output         io_toIbuffer_bits_topdown_info_reasons_21,
  output         io_toIbuffer_bits_topdown_info_reasons_22,
  output         io_toIbuffer_bits_topdown_info_reasons_23,
  output         io_toIbuffer_bits_topdown_info_reasons_24,
  output         io_toIbuffer_bits_topdown_info_reasons_25,
  output         io_toIbuffer_bits_topdown_info_reasons_26,
  output         io_toIbuffer_bits_topdown_info_reasons_27,
  output         io_toIbuffer_bits_topdown_info_reasons_28,
  output         io_toIbuffer_bits_topdown_info_reasons_29,
  output         io_toIbuffer_bits_topdown_info_reasons_30,
  output         io_toIbuffer_bits_topdown_info_reasons_31,
  output         io_toIbuffer_bits_topdown_info_reasons_32,
  output         io_toIbuffer_bits_topdown_info_reasons_33,
  output         io_toIbuffer_bits_topdown_info_reasons_34,
  output         io_toIbuffer_bits_topdown_info_reasons_35,
  output         io_toIbuffer_bits_topdown_info_reasons_36,
  output         io_toIbuffer_bits_topdown_info_reasons_37,
  output         io_toBackend_gpaddrMem_wen,
  output [5:0]   io_toBackend_gpaddrMem_waddr,
  output [55:0]  io_toBackend_gpaddrMem_wdata_gpaddr,
  output         io_toBackend_gpaddrMem_wdata_isForVSnonLeafPTE,
  input          io_uncacheInter_fromUncache_valid,
  input  [31:0]  io_uncacheInter_fromUncache_bits_data,
  input          io_uncacheInter_fromUncache_bits_corrupt,
  input          io_uncacheInter_toUncache_ready,
  output         io_uncacheInter_toUncache_valid,
  output [47:0]  io_uncacheInter_toUncache_bits_addr,
  output         io_uncacheInter_toUncache_bits_memBackTypeMM,
  output         io_uncacheInter_toUncache_bits_memPageTypeNC,
  output         io_uncacheInter_toUncache_bits_flush,
  input          io_frontendTrigger_tUpdate_valid,
  input  [1:0]   io_frontendTrigger_tUpdate_bits_addr,
  input  [1:0]   io_frontendTrigger_tUpdate_bits_tdata_matchType,
  input          io_frontendTrigger_tUpdate_bits_tdata_select,
  input  [3:0]   io_frontendTrigger_tUpdate_bits_tdata_action,
  input          io_frontendTrigger_tUpdate_bits_tdata_chain,
  input  [63:0]  io_frontendTrigger_tUpdate_bits_tdata_tdata2,
  input          io_frontendTrigger_tEnableVec_0,
  input          io_frontendTrigger_tEnableVec_1,
  input          io_frontendTrigger_tEnableVec_2,
  input          io_frontendTrigger_tEnableVec_3,
  input          io_frontendTrigger_debugMode,
  input          io_frontendTrigger_triggerCanRaiseBpExp,
  input          io_rob_commits_0_valid,
  input          io_rob_commits_0_bits_ftqIdx_flag,
  input  [5:0]   io_rob_commits_0_bits_ftqIdx_value,
  input  [3:0]   io_rob_commits_0_bits_ftqOffset,
  input          io_rob_commits_1_valid,
  input          io_rob_commits_1_bits_ftqIdx_flag,
  input  [5:0]   io_rob_commits_1_bits_ftqIdx_value,
  input  [3:0]   io_rob_commits_1_bits_ftqOffset,
  input          io_rob_commits_2_valid,
  input          io_rob_commits_2_bits_ftqIdx_flag,
  input  [5:0]   io_rob_commits_2_bits_ftqIdx_value,
  input  [3:0]   io_rob_commits_2_bits_ftqOffset,
  input          io_rob_commits_3_valid,
  input          io_rob_commits_3_bits_ftqIdx_flag,
  input  [5:0]   io_rob_commits_3_bits_ftqIdx_value,
  input  [3:0]   io_rob_commits_3_bits_ftqOffset,
  input          io_rob_commits_4_valid,
  input          io_rob_commits_4_bits_ftqIdx_flag,
  input  [5:0]   io_rob_commits_4_bits_ftqIdx_value,
  input  [3:0]   io_rob_commits_4_bits_ftqOffset,
  input          io_rob_commits_5_valid,
  input          io_rob_commits_5_bits_ftqIdx_flag,
  input  [5:0]   io_rob_commits_5_bits_ftqIdx_value,
  input  [3:0]   io_rob_commits_5_bits_ftqOffset,
  input          io_rob_commits_6_valid,
  input          io_rob_commits_6_bits_ftqIdx_flag,
  input  [5:0]   io_rob_commits_6_bits_ftqIdx_value,
  input  [3:0]   io_rob_commits_6_bits_ftqOffset,
  input          io_rob_commits_7_valid,
  input          io_rob_commits_7_bits_ftqIdx_flag,
  input  [5:0]   io_rob_commits_7_bits_ftqIdx_value,
  input  [3:0]   io_rob_commits_7_bits_ftqOffset,
  input          io_iTLBInter_req_ready,
  output         io_iTLBInter_req_valid,
  output [49:0]  io_iTLBInter_req_bits_vaddr,
  output         io_iTLBInter_resp_ready,
  input          io_iTLBInter_resp_valid,
  input  [47:0]  io_iTLBInter_resp_bits_paddr_0,
  input  [63:0]  io_iTLBInter_resp_bits_gpaddr_0,
  input  [1:0]   io_iTLBInter_resp_bits_pbmt_0,
  input          io_iTLBInter_resp_bits_miss,
  input          io_iTLBInter_resp_bits_isForVSnonLeafPTE,
  input          io_iTLBInter_resp_bits_excp_0_gpf_instr,
  input          io_iTLBInter_resp_bits_excp_0_pf_instr,
  input          io_iTLBInter_resp_bits_excp_0_af_instr,
  output         io_pmp_req_valid,
  output [47:0]  io_pmp_req_bits_addr,
  input          io_pmp_resp_instr,
  input          io_pmp_resp_mmio,
  output         io_mmioCommitRead_valid,
  output         io_mmioCommitRead_mmioFtqPtr_flag,
  output [5:0]   io_mmioCommitRead_mmioFtqPtr_value,
  input          io_mmioCommitRead_mmioLastCommit,
  input          io_csr_fsIsOff,
  output [5:0]   io_perf_0_value,
  output [5:0]   io_perf_1_value,
  output [5:0]   io_perf_2_value,
  output [5:0]   io_perf_3_value,
  output [5:0]   io_perf_4_value,
  output [5:0]   io_perf_5_value,
  output [5:0]   io_perf_6_value,
  output [5:0]   io_perf_7_value,
  output [5:0]   io_perf_8_value,
  output [5:0]   io_perf_9_value,
  output [5:0]   io_perf_10_value,
  output [5:0]   io_perf_11_value,
  output [5:0]   io_perf_12_value
);
  wire [37:0] io_ftqInter_fromFtq_req_bits_topdown_info_reasons = {
    io_ftqInter_fromFtq_req_bits_topdown_info_reasons_37, io_ftqInter_fromFtq_req_bits_topdown_info_reasons_36, io_ftqInter_fromFtq_req_bits_topdown_info_reasons_35, io_ftqInter_fromFtq_req_bits_topdown_info_reasons_34,
    io_ftqInter_fromFtq_req_bits_topdown_info_reasons_33, io_ftqInter_fromFtq_req_bits_topdown_info_reasons_32, io_ftqInter_fromFtq_req_bits_topdown_info_reasons_31, io_ftqInter_fromFtq_req_bits_topdown_info_reasons_30,
    io_ftqInter_fromFtq_req_bits_topdown_info_reasons_29, io_ftqInter_fromFtq_req_bits_topdown_info_reasons_28, io_ftqInter_fromFtq_req_bits_topdown_info_reasons_27, io_ftqInter_fromFtq_req_bits_topdown_info_reasons_26,
    io_ftqInter_fromFtq_req_bits_topdown_info_reasons_25, io_ftqInter_fromFtq_req_bits_topdown_info_reasons_24, io_ftqInter_fromFtq_req_bits_topdown_info_reasons_23, io_ftqInter_fromFtq_req_bits_topdown_info_reasons_22,
    io_ftqInter_fromFtq_req_bits_topdown_info_reasons_21, io_ftqInter_fromFtq_req_bits_topdown_info_reasons_20, io_ftqInter_fromFtq_req_bits_topdown_info_reasons_19, io_ftqInter_fromFtq_req_bits_topdown_info_reasons_18,
    io_ftqInter_fromFtq_req_bits_topdown_info_reasons_17, io_ftqInter_fromFtq_req_bits_topdown_info_reasons_16, io_ftqInter_fromFtq_req_bits_topdown_info_reasons_15, io_ftqInter_fromFtq_req_bits_topdown_info_reasons_14,
    io_ftqInter_fromFtq_req_bits_topdown_info_reasons_13, io_ftqInter_fromFtq_req_bits_topdown_info_reasons_12, io_ftqInter_fromFtq_req_bits_topdown_info_reasons_11, io_ftqInter_fromFtq_req_bits_topdown_info_reasons_10,
    io_ftqInter_fromFtq_req_bits_topdown_info_reasons_9, io_ftqInter_fromFtq_req_bits_topdown_info_reasons_8, io_ftqInter_fromFtq_req_bits_topdown_info_reasons_7, io_ftqInter_fromFtq_req_bits_topdown_info_reasons_6,
    io_ftqInter_fromFtq_req_bits_topdown_info_reasons_5, io_ftqInter_fromFtq_req_bits_topdown_info_reasons_4, io_ftqInter_fromFtq_req_bits_topdown_info_reasons_3, io_ftqInter_fromFtq_req_bits_topdown_info_reasons_2,
    io_ftqInter_fromFtq_req_bits_topdown_info_reasons_1, io_ftqInter_fromFtq_req_bits_topdown_info_reasons_0};
  wire [15:0][49:0] io_ftqInter_toFtq_pdWb_bits_pc;
  wire [15:0] io_ftqInter_toFtq_pdWb_bits_pd_valid;
  wire [15:0] io_ftqInter_toFtq_pdWb_bits_pd_isRVC;
  wire [15:0][1:0] io_ftqInter_toFtq_pdWb_bits_pd_brType;
  wire [15:0] io_ftqInter_toFtq_pdWb_bits_pd_isCall;
  wire [15:0] io_ftqInter_toFtq_pdWb_bits_pd_isRet;
  wire [15:0] io_ftqInter_toFtq_pdWb_bits_instrRange;
  wire [1:0][49:0] io_icacheInter_resp_bits_vaddr = {
    io_icacheInter_resp_bits_vaddr_1, io_icacheInter_resp_bits_vaddr_0};
  wire [1:0][1:0] io_icacheInter_resp_bits_exception = {
    io_icacheInter_resp_bits_exception_1, io_icacheInter_resp_bits_exception_0};
  wire [1:0] io_icacheInter_resp_bits_pmp_mmio = {
    io_icacheInter_resp_bits_pmp_mmio_1, io_icacheInter_resp_bits_pmp_mmio_0};
  wire [1:0][1:0] io_icacheInter_resp_bits_itlb_pbmt = {
    io_icacheInter_resp_bits_itlb_pbmt_1, io_icacheInter_resp_bits_itlb_pbmt_0};
  wire [1:0] io_icachePerfInfo_bank_hit = {
    io_icachePerfInfo_bank_hit_1, io_icachePerfInfo_bank_hit_0};
  wire [15:0][31:0] io_toIbuffer_bits_instrs;
  wire [15:0] io_toIbuffer_bits_pd_isRVC;
  wire [15:0][1:0] io_toIbuffer_bits_pd_brType;
  wire [15:0] io_toIbuffer_bits_pd_isCall;
  wire [15:0] io_toIbuffer_bits_pd_isRet;
  wire [15:1] io_toIbuffer_bits_pd_valid;
  wire [15:0][9:0] io_toIbuffer_bits_foldpc;
  wire [15:0] io_toIbuffer_bits_ftqOffset_valid;
  wire [15:0][1:0] io_toIbuffer_bits_exceptionType;
  wire [15:0] io_toIbuffer_bits_crossPageIPFFix;
  wire [15:0] io_toIbuffer_bits_illegalInstr;
  wire [15:0][3:0] io_toIbuffer_bits_triggered;
  wire [15:0] io_toIbuffer_bits_isLastInFtqEntry;
  wire [15:0][49:0] io_toIbuffer_bits_pc;
  wire [37:0] io_toIbuffer_bits_topdown_info_reasons;
  wire [3:0] io_frontendTrigger_tEnableVec = {
    io_frontendTrigger_tEnableVec_3, io_frontendTrigger_tEnableVec_2, io_frontendTrigger_tEnableVec_1, io_frontendTrigger_tEnableVec_0};
  wire [7:0] io_rob_commits_valid = {
    io_rob_commits_7_valid, io_rob_commits_6_valid, io_rob_commits_5_valid, io_rob_commits_4_valid,
    io_rob_commits_3_valid, io_rob_commits_2_valid, io_rob_commits_1_valid, io_rob_commits_0_valid};
  wire [7:0] io_rob_commits_bits_ftqIdx_flag = {
    io_rob_commits_7_bits_ftqIdx_flag, io_rob_commits_6_bits_ftqIdx_flag, io_rob_commits_5_bits_ftqIdx_flag, io_rob_commits_4_bits_ftqIdx_flag,
    io_rob_commits_3_bits_ftqIdx_flag, io_rob_commits_2_bits_ftqIdx_flag, io_rob_commits_1_bits_ftqIdx_flag, io_rob_commits_0_bits_ftqIdx_flag};
  wire [7:0][5:0] io_rob_commits_bits_ftqIdx_value = {
    io_rob_commits_7_bits_ftqIdx_value, io_rob_commits_6_bits_ftqIdx_value, io_rob_commits_5_bits_ftqIdx_value, io_rob_commits_4_bits_ftqIdx_value,
    io_rob_commits_3_bits_ftqIdx_value, io_rob_commits_2_bits_ftqIdx_value, io_rob_commits_1_bits_ftqIdx_value, io_rob_commits_0_bits_ftqIdx_value};
  wire [7:0][3:0] io_rob_commits_bits_ftqOffset = {
    io_rob_commits_7_bits_ftqOffset, io_rob_commits_6_bits_ftqOffset, io_rob_commits_5_bits_ftqOffset, io_rob_commits_4_bits_ftqOffset,
    io_rob_commits_3_bits_ftqOffset, io_rob_commits_2_bits_ftqOffset, io_rob_commits_1_bits_ftqOffset, io_rob_commits_0_bits_ftqOffset};
  wire [12:0][5:0] io_perf_value;

  xs_NewIFU_core u_core (
    .clock                                                        (clock),
    .reset                                                        (reset),
    .io_ftqInter_fromFtq_req_ready                                (io_ftqInter_fromFtq_req_ready),
    .io_ftqInter_fromFtq_req_valid                                (io_ftqInter_fromFtq_req_valid),
    .io_ftqInter_fromFtq_req_bits_startAddr                       (io_ftqInter_fromFtq_req_bits_startAddr),
    .io_ftqInter_fromFtq_req_bits_nextlineStart                   (io_ftqInter_fromFtq_req_bits_nextlineStart),
    .io_ftqInter_fromFtq_req_bits_nextStartAddr                   (io_ftqInter_fromFtq_req_bits_nextStartAddr),
    .io_ftqInter_fromFtq_req_bits_ftqIdx_flag                     (io_ftqInter_fromFtq_req_bits_ftqIdx_flag),
    .io_ftqInter_fromFtq_req_bits_ftqIdx_value                    (io_ftqInter_fromFtq_req_bits_ftqIdx_value),
    .io_ftqInter_fromFtq_req_bits_ftqOffset_valid                 (io_ftqInter_fromFtq_req_bits_ftqOffset_valid),
    .io_ftqInter_fromFtq_req_bits_ftqOffset_bits                  (io_ftqInter_fromFtq_req_bits_ftqOffset_bits),
    .io_ftqInter_fromFtq_req_bits_topdown_info_reasons            (io_ftqInter_fromFtq_req_bits_topdown_info_reasons),
    .io_ftqInter_fromFtq_redirect_valid                           (io_ftqInter_fromFtq_redirect_valid),
    .io_ftqInter_fromFtq_redirect_bits_ftqIdx_flag                (io_ftqInter_fromFtq_redirect_bits_ftqIdx_flag),
    .io_ftqInter_fromFtq_redirect_bits_ftqIdx_value               (io_ftqInter_fromFtq_redirect_bits_ftqIdx_value),
    .io_ftqInter_fromFtq_redirect_bits_ftqOffset                  (io_ftqInter_fromFtq_redirect_bits_ftqOffset),
    .io_ftqInter_fromFtq_redirect_bits_level                      (io_ftqInter_fromFtq_redirect_bits_level),
    .io_ftqInter_fromFtq_topdown_redirect_valid                   (io_ftqInter_fromFtq_topdown_redirect_valid),
    .io_ftqInter_fromFtq_topdown_redirect_bits_cfiUpdate_pd_isRet (io_ftqInter_fromFtq_topdown_redirect_bits_cfiUpdate_pd_isRet),
    .io_ftqInter_fromFtq_topdown_redirect_bits_cfiUpdate_br_hit   (io_ftqInter_fromFtq_topdown_redirect_bits_cfiUpdate_br_hit),
    .io_ftqInter_fromFtq_topdown_redirect_bits_cfiUpdate_jr_hit   (io_ftqInter_fromFtq_topdown_redirect_bits_cfiUpdate_jr_hit),
    .io_ftqInter_fromFtq_topdown_redirect_bits_cfiUpdate_sc_hit   (io_ftqInter_fromFtq_topdown_redirect_bits_cfiUpdate_sc_hit),
    .io_ftqInter_fromFtq_topdown_redirect_bits_debugIsCtrl        (io_ftqInter_fromFtq_topdown_redirect_bits_debugIsCtrl),
    .io_ftqInter_fromFtq_topdown_redirect_bits_debugIsMemVio      (io_ftqInter_fromFtq_topdown_redirect_bits_debugIsMemVio),
    .io_ftqInter_fromFtq_flushFromBpu_s2_valid                    (io_ftqInter_fromFtq_flushFromBpu_s2_valid),
    .io_ftqInter_fromFtq_flushFromBpu_s2_bits_flag                (io_ftqInter_fromFtq_flushFromBpu_s2_bits_flag),
    .io_ftqInter_fromFtq_flushFromBpu_s2_bits_value               (io_ftqInter_fromFtq_flushFromBpu_s2_bits_value),
    .io_ftqInter_fromFtq_flushFromBpu_s3_valid                    (io_ftqInter_fromFtq_flushFromBpu_s3_valid),
    .io_ftqInter_fromFtq_flushFromBpu_s3_bits_flag                (io_ftqInter_fromFtq_flushFromBpu_s3_bits_flag),
    .io_ftqInter_fromFtq_flushFromBpu_s3_bits_value               (io_ftqInter_fromFtq_flushFromBpu_s3_bits_value),
    .io_ftqInter_toFtq_pdWb_valid                                 (io_ftqInter_toFtq_pdWb_valid),
    .io_ftqInter_toFtq_pdWb_bits_pc                               (io_ftqInter_toFtq_pdWb_bits_pc),
    .io_ftqInter_toFtq_pdWb_bits_pd_valid                         (io_ftqInter_toFtq_pdWb_bits_pd_valid),
    .io_ftqInter_toFtq_pdWb_bits_pd_isRVC                         (io_ftqInter_toFtq_pdWb_bits_pd_isRVC),
    .io_ftqInter_toFtq_pdWb_bits_pd_brType                        (io_ftqInter_toFtq_pdWb_bits_pd_brType),
    .io_ftqInter_toFtq_pdWb_bits_pd_isCall                        (io_ftqInter_toFtq_pdWb_bits_pd_isCall),
    .io_ftqInter_toFtq_pdWb_bits_pd_isRet                         (io_ftqInter_toFtq_pdWb_bits_pd_isRet),
    .io_ftqInter_toFtq_pdWb_bits_ftqIdx_flag                      (io_ftqInter_toFtq_pdWb_bits_ftqIdx_flag),
    .io_ftqInter_toFtq_pdWb_bits_ftqIdx_value                     (io_ftqInter_toFtq_pdWb_bits_ftqIdx_value),
    .io_ftqInter_toFtq_pdWb_bits_misOffset_valid                  (io_ftqInter_toFtq_pdWb_bits_misOffset_valid),
    .io_ftqInter_toFtq_pdWb_bits_misOffset_bits                   (io_ftqInter_toFtq_pdWb_bits_misOffset_bits),
    .io_ftqInter_toFtq_pdWb_bits_cfiOffset_valid                  (io_ftqInter_toFtq_pdWb_bits_cfiOffset_valid),
    .io_ftqInter_toFtq_pdWb_bits_target                           (io_ftqInter_toFtq_pdWb_bits_target),
    .io_ftqInter_toFtq_pdWb_bits_jalTarget                        (io_ftqInter_toFtq_pdWb_bits_jalTarget),
    .io_ftqInter_toFtq_pdWb_bits_instrRange                       (io_ftqInter_toFtq_pdWb_bits_instrRange),
    .io_icacheInter_icacheReady                                   (io_icacheInter_icacheReady),
    .io_icacheInter_resp_valid                                    (io_icacheInter_resp_valid),
    .io_icacheInter_resp_bits_doubleline                          (io_icacheInter_resp_bits_doubleline),
    .io_icacheInter_resp_bits_vaddr                               (io_icacheInter_resp_bits_vaddr),
    .io_icacheInter_resp_bits_data                                (io_icacheInter_resp_bits_data),
    .io_icacheInter_resp_bits_paddr_0                             (io_icacheInter_resp_bits_paddr_0),
    .io_icacheInter_resp_bits_exception                           (io_icacheInter_resp_bits_exception),
    .io_icacheInter_resp_bits_pmp_mmio                            (io_icacheInter_resp_bits_pmp_mmio),
    .io_icacheInter_resp_bits_itlb_pbmt                           (io_icacheInter_resp_bits_itlb_pbmt),
    .io_icacheInter_resp_bits_backendException                    (io_icacheInter_resp_bits_backendException),
    .io_icacheInter_resp_bits_hasSatpFlush                        (io_icacheInter_resp_bits_hasSatpFlush),
    .io_icacheInter_resp_bits_gpaddr                              (io_icacheInter_resp_bits_gpaddr),
    .io_icacheInter_resp_bits_isForVSnonLeafPTE                   (io_icacheInter_resp_bits_isForVSnonLeafPTE),
    .io_icacheInter_topdownIcacheMiss                             (io_icacheInter_topdownIcacheMiss),
    .io_icacheInter_topdownItlbMiss                               (io_icacheInter_topdownItlbMiss),
    .io_icacheStop                                                (io_icacheStop),
    .io_icachePerfInfo_only_0_hit                                 (io_icachePerfInfo_only_0_hit),
    .io_icachePerfInfo_only_0_miss                                (io_icachePerfInfo_only_0_miss),
    .io_icachePerfInfo_hit_0_hit_1                                (io_icachePerfInfo_hit_0_hit_1),
    .io_icachePerfInfo_hit_0_miss_1                               (io_icachePerfInfo_hit_0_miss_1),
    .io_icachePerfInfo_miss_0_hit_1                               (io_icachePerfInfo_miss_0_hit_1),
    .io_icachePerfInfo_miss_0_miss_1                              (io_icachePerfInfo_miss_0_miss_1),
    .io_icachePerfInfo_hit_0_except_1                             (io_icachePerfInfo_hit_0_except_1),
    .io_icachePerfInfo_miss_0_except_1                            (io_icachePerfInfo_miss_0_except_1),
    .io_icachePerfInfo_except_0                                   (io_icachePerfInfo_except_0),
    .io_icachePerfInfo_bank_hit                                   (io_icachePerfInfo_bank_hit),
    .io_icachePerfInfo_hit                                        (io_icachePerfInfo_hit),
    .io_toIbuffer_ready                                           (io_toIbuffer_ready),
    .io_toIbuffer_valid                                           (io_toIbuffer_valid),
    .io_toIbuffer_bits_instrs                                     (io_toIbuffer_bits_instrs),
    .io_toIbuffer_bits_valid                                      (io_toIbuffer_bits_valid),
    .io_toIbuffer_bits_enqEnable                                  (io_toIbuffer_bits_enqEnable),
    .io_toIbuffer_bits_pd_isRVC                                   (io_toIbuffer_bits_pd_isRVC),
    .io_toIbuffer_bits_pd_brType                                  (io_toIbuffer_bits_pd_brType),
    .io_toIbuffer_bits_pd_isCall                                  (io_toIbuffer_bits_pd_isCall),
    .io_toIbuffer_bits_pd_isRet                                   (io_toIbuffer_bits_pd_isRet),
    .io_toIbuffer_bits_pd_valid                                   (io_toIbuffer_bits_pd_valid),
    .io_toIbuffer_bits_foldpc                                     (io_toIbuffer_bits_foldpc),
    .io_toIbuffer_bits_ftqOffset_valid                            (io_toIbuffer_bits_ftqOffset_valid),
    .io_toIbuffer_bits_backendException_0                         (io_toIbuffer_bits_backendException_0),
    .io_toIbuffer_bits_satpFlushFirstFetchFault_0                 (io_toIbuffer_bits_satpFlushFirstFetchFault_0),
    .io_toIbuffer_bits_exceptionType                              (io_toIbuffer_bits_exceptionType),
    .io_toIbuffer_bits_crossPageIPFFix                            (io_toIbuffer_bits_crossPageIPFFix),
    .io_toIbuffer_bits_illegalInstr                               (io_toIbuffer_bits_illegalInstr),
    .io_toIbuffer_bits_triggered                                  (io_toIbuffer_bits_triggered),
    .io_toIbuffer_bits_isLastInFtqEntry                           (io_toIbuffer_bits_isLastInFtqEntry),
    .io_toIbuffer_bits_pc                                         (io_toIbuffer_bits_pc),
    .io_toIbuffer_bits_ftqPtr_flag                                (io_toIbuffer_bits_ftqPtr_flag),
    .io_toIbuffer_bits_ftqPtr_value                               (io_toIbuffer_bits_ftqPtr_value),
    .io_toIbuffer_bits_topdown_info_reasons                       (io_toIbuffer_bits_topdown_info_reasons),
    .io_toBackend_gpaddrMem_wen                                   (io_toBackend_gpaddrMem_wen),
    .io_toBackend_gpaddrMem_waddr                                 (io_toBackend_gpaddrMem_waddr),
    .io_toBackend_gpaddrMem_wdata_gpaddr                          (io_toBackend_gpaddrMem_wdata_gpaddr),
    .io_toBackend_gpaddrMem_wdata_isForVSnonLeafPTE               (io_toBackend_gpaddrMem_wdata_isForVSnonLeafPTE),
    .io_uncacheInter_fromUncache_valid                            (io_uncacheInter_fromUncache_valid),
    .io_uncacheInter_fromUncache_bits_data                        (io_uncacheInter_fromUncache_bits_data),
    .io_uncacheInter_fromUncache_bits_corrupt                     (io_uncacheInter_fromUncache_bits_corrupt),
    .io_uncacheInter_toUncache_ready                              (io_uncacheInter_toUncache_ready),
    .io_uncacheInter_toUncache_valid                              (io_uncacheInter_toUncache_valid),
    .io_uncacheInter_toUncache_bits_addr                          (io_uncacheInter_toUncache_bits_addr),
    .io_uncacheInter_toUncache_bits_memBackTypeMM                 (io_uncacheInter_toUncache_bits_memBackTypeMM),
    .io_uncacheInter_toUncache_bits_memPageTypeNC                 (io_uncacheInter_toUncache_bits_memPageTypeNC),
    .io_uncacheInter_toUncache_bits_flush                         (io_uncacheInter_toUncache_bits_flush),
    .io_frontendTrigger_tUpdate_valid                             (io_frontendTrigger_tUpdate_valid),
    .io_frontendTrigger_tUpdate_bits_addr                         (io_frontendTrigger_tUpdate_bits_addr),
    .io_frontendTrigger_tUpdate_bits_tdata_matchType              (io_frontendTrigger_tUpdate_bits_tdata_matchType),
    .io_frontendTrigger_tUpdate_bits_tdata_select                 (io_frontendTrigger_tUpdate_bits_tdata_select),
    .io_frontendTrigger_tUpdate_bits_tdata_action                 (io_frontendTrigger_tUpdate_bits_tdata_action),
    .io_frontendTrigger_tUpdate_bits_tdata_chain                  (io_frontendTrigger_tUpdate_bits_tdata_chain),
    .io_frontendTrigger_tUpdate_bits_tdata_tdata2                 (io_frontendTrigger_tUpdate_bits_tdata_tdata2),
    .io_frontendTrigger_tEnableVec                                (io_frontendTrigger_tEnableVec),
    .io_frontendTrigger_debugMode                                 (io_frontendTrigger_debugMode),
    .io_frontendTrigger_triggerCanRaiseBpExp                      (io_frontendTrigger_triggerCanRaiseBpExp),
    .io_rob_commits_valid                                         (io_rob_commits_valid),
    .io_rob_commits_bits_ftqIdx_flag                              (io_rob_commits_bits_ftqIdx_flag),
    .io_rob_commits_bits_ftqIdx_value                             (io_rob_commits_bits_ftqIdx_value),
    .io_rob_commits_bits_ftqOffset                                (io_rob_commits_bits_ftqOffset),
    .io_iTLBInter_req_ready                                       (io_iTLBInter_req_ready),
    .io_iTLBInter_req_valid                                       (io_iTLBInter_req_valid),
    .io_iTLBInter_req_bits_vaddr                                  (io_iTLBInter_req_bits_vaddr),
    .io_iTLBInter_resp_ready                                      (io_iTLBInter_resp_ready),
    .io_iTLBInter_resp_valid                                      (io_iTLBInter_resp_valid),
    .io_iTLBInter_resp_bits_paddr_0                               (io_iTLBInter_resp_bits_paddr_0),
    .io_iTLBInter_resp_bits_gpaddr_0                              (io_iTLBInter_resp_bits_gpaddr_0),
    .io_iTLBInter_resp_bits_pbmt_0                                (io_iTLBInter_resp_bits_pbmt_0),
    .io_iTLBInter_resp_bits_miss                                  (io_iTLBInter_resp_bits_miss),
    .io_iTLBInter_resp_bits_isForVSnonLeafPTE                     (io_iTLBInter_resp_bits_isForVSnonLeafPTE),
    .io_iTLBInter_resp_bits_excp_0_gpf_instr                      (io_iTLBInter_resp_bits_excp_0_gpf_instr),
    .io_iTLBInter_resp_bits_excp_0_pf_instr                       (io_iTLBInter_resp_bits_excp_0_pf_instr),
    .io_iTLBInter_resp_bits_excp_0_af_instr                       (io_iTLBInter_resp_bits_excp_0_af_instr),
    .io_pmp_req_valid                                             (io_pmp_req_valid),
    .io_pmp_req_bits_addr                                         (io_pmp_req_bits_addr),
    .io_pmp_resp_instr                                            (io_pmp_resp_instr),
    .io_pmp_resp_mmio                                             (io_pmp_resp_mmio),
    .io_mmioCommitRead_valid                                      (io_mmioCommitRead_valid),
    .io_mmioCommitRead_mmioFtqPtr_flag                            (io_mmioCommitRead_mmioFtqPtr_flag),
    .io_mmioCommitRead_mmioFtqPtr_value                           (io_mmioCommitRead_mmioFtqPtr_value),
    .io_mmioCommitRead_mmioLastCommit                             (io_mmioCommitRead_mmioLastCommit),
    .io_csr_fsIsOff                                               (io_csr_fsIsOff),
    .io_perf_value                                                (io_perf_value)
  );

  assign io_ftqInter_toFtq_pdWb_bits_pc_0 = io_ftqInter_toFtq_pdWb_bits_pc[0];
  assign io_ftqInter_toFtq_pdWb_bits_pc_1 = io_ftqInter_toFtq_pdWb_bits_pc[1];
  assign io_ftqInter_toFtq_pdWb_bits_pc_2 = io_ftqInter_toFtq_pdWb_bits_pc[2];
  assign io_ftqInter_toFtq_pdWb_bits_pc_3 = io_ftqInter_toFtq_pdWb_bits_pc[3];
  assign io_ftqInter_toFtq_pdWb_bits_pc_4 = io_ftqInter_toFtq_pdWb_bits_pc[4];
  assign io_ftqInter_toFtq_pdWb_bits_pc_5 = io_ftqInter_toFtq_pdWb_bits_pc[5];
  assign io_ftqInter_toFtq_pdWb_bits_pc_6 = io_ftqInter_toFtq_pdWb_bits_pc[6];
  assign io_ftqInter_toFtq_pdWb_bits_pc_7 = io_ftqInter_toFtq_pdWb_bits_pc[7];
  assign io_ftqInter_toFtq_pdWb_bits_pc_8 = io_ftqInter_toFtq_pdWb_bits_pc[8];
  assign io_ftqInter_toFtq_pdWb_bits_pc_9 = io_ftqInter_toFtq_pdWb_bits_pc[9];
  assign io_ftqInter_toFtq_pdWb_bits_pc_10 = io_ftqInter_toFtq_pdWb_bits_pc[10];
  assign io_ftqInter_toFtq_pdWb_bits_pc_11 = io_ftqInter_toFtq_pdWb_bits_pc[11];
  assign io_ftqInter_toFtq_pdWb_bits_pc_12 = io_ftqInter_toFtq_pdWb_bits_pc[12];
  assign io_ftqInter_toFtq_pdWb_bits_pc_13 = io_ftqInter_toFtq_pdWb_bits_pc[13];
  assign io_ftqInter_toFtq_pdWb_bits_pc_14 = io_ftqInter_toFtq_pdWb_bits_pc[14];
  assign io_ftqInter_toFtq_pdWb_bits_pc_15 = io_ftqInter_toFtq_pdWb_bits_pc[15];
  assign io_ftqInter_toFtq_pdWb_bits_pd_0_valid = io_ftqInter_toFtq_pdWb_bits_pd_valid[0];
  assign io_ftqInter_toFtq_pdWb_bits_pd_1_valid = io_ftqInter_toFtq_pdWb_bits_pd_valid[1];
  assign io_ftqInter_toFtq_pdWb_bits_pd_2_valid = io_ftqInter_toFtq_pdWb_bits_pd_valid[2];
  assign io_ftqInter_toFtq_pdWb_bits_pd_3_valid = io_ftqInter_toFtq_pdWb_bits_pd_valid[3];
  assign io_ftqInter_toFtq_pdWb_bits_pd_4_valid = io_ftqInter_toFtq_pdWb_bits_pd_valid[4];
  assign io_ftqInter_toFtq_pdWb_bits_pd_5_valid = io_ftqInter_toFtq_pdWb_bits_pd_valid[5];
  assign io_ftqInter_toFtq_pdWb_bits_pd_6_valid = io_ftqInter_toFtq_pdWb_bits_pd_valid[6];
  assign io_ftqInter_toFtq_pdWb_bits_pd_7_valid = io_ftqInter_toFtq_pdWb_bits_pd_valid[7];
  assign io_ftqInter_toFtq_pdWb_bits_pd_8_valid = io_ftqInter_toFtq_pdWb_bits_pd_valid[8];
  assign io_ftqInter_toFtq_pdWb_bits_pd_9_valid = io_ftqInter_toFtq_pdWb_bits_pd_valid[9];
  assign io_ftqInter_toFtq_pdWb_bits_pd_10_valid = io_ftqInter_toFtq_pdWb_bits_pd_valid[10];
  assign io_ftqInter_toFtq_pdWb_bits_pd_11_valid = io_ftqInter_toFtq_pdWb_bits_pd_valid[11];
  assign io_ftqInter_toFtq_pdWb_bits_pd_12_valid = io_ftqInter_toFtq_pdWb_bits_pd_valid[12];
  assign io_ftqInter_toFtq_pdWb_bits_pd_13_valid = io_ftqInter_toFtq_pdWb_bits_pd_valid[13];
  assign io_ftqInter_toFtq_pdWb_bits_pd_14_valid = io_ftqInter_toFtq_pdWb_bits_pd_valid[14];
  assign io_ftqInter_toFtq_pdWb_bits_pd_15_valid = io_ftqInter_toFtq_pdWb_bits_pd_valid[15];
  assign io_ftqInter_toFtq_pdWb_bits_pd_0_isRVC = io_ftqInter_toFtq_pdWb_bits_pd_isRVC[0];
  assign io_ftqInter_toFtq_pdWb_bits_pd_1_isRVC = io_ftqInter_toFtq_pdWb_bits_pd_isRVC[1];
  assign io_ftqInter_toFtq_pdWb_bits_pd_2_isRVC = io_ftqInter_toFtq_pdWb_bits_pd_isRVC[2];
  assign io_ftqInter_toFtq_pdWb_bits_pd_3_isRVC = io_ftqInter_toFtq_pdWb_bits_pd_isRVC[3];
  assign io_ftqInter_toFtq_pdWb_bits_pd_4_isRVC = io_ftqInter_toFtq_pdWb_bits_pd_isRVC[4];
  assign io_ftqInter_toFtq_pdWb_bits_pd_5_isRVC = io_ftqInter_toFtq_pdWb_bits_pd_isRVC[5];
  assign io_ftqInter_toFtq_pdWb_bits_pd_6_isRVC = io_ftqInter_toFtq_pdWb_bits_pd_isRVC[6];
  assign io_ftqInter_toFtq_pdWb_bits_pd_7_isRVC = io_ftqInter_toFtq_pdWb_bits_pd_isRVC[7];
  assign io_ftqInter_toFtq_pdWb_bits_pd_8_isRVC = io_ftqInter_toFtq_pdWb_bits_pd_isRVC[8];
  assign io_ftqInter_toFtq_pdWb_bits_pd_9_isRVC = io_ftqInter_toFtq_pdWb_bits_pd_isRVC[9];
  assign io_ftqInter_toFtq_pdWb_bits_pd_10_isRVC = io_ftqInter_toFtq_pdWb_bits_pd_isRVC[10];
  assign io_ftqInter_toFtq_pdWb_bits_pd_11_isRVC = io_ftqInter_toFtq_pdWb_bits_pd_isRVC[11];
  assign io_ftqInter_toFtq_pdWb_bits_pd_12_isRVC = io_ftqInter_toFtq_pdWb_bits_pd_isRVC[12];
  assign io_ftqInter_toFtq_pdWb_bits_pd_13_isRVC = io_ftqInter_toFtq_pdWb_bits_pd_isRVC[13];
  assign io_ftqInter_toFtq_pdWb_bits_pd_14_isRVC = io_ftqInter_toFtq_pdWb_bits_pd_isRVC[14];
  assign io_ftqInter_toFtq_pdWb_bits_pd_15_isRVC = io_ftqInter_toFtq_pdWb_bits_pd_isRVC[15];
  assign io_ftqInter_toFtq_pdWb_bits_pd_0_brType = io_ftqInter_toFtq_pdWb_bits_pd_brType[0];
  assign io_ftqInter_toFtq_pdWb_bits_pd_1_brType = io_ftqInter_toFtq_pdWb_bits_pd_brType[1];
  assign io_ftqInter_toFtq_pdWb_bits_pd_2_brType = io_ftqInter_toFtq_pdWb_bits_pd_brType[2];
  assign io_ftqInter_toFtq_pdWb_bits_pd_3_brType = io_ftqInter_toFtq_pdWb_bits_pd_brType[3];
  assign io_ftqInter_toFtq_pdWb_bits_pd_4_brType = io_ftqInter_toFtq_pdWb_bits_pd_brType[4];
  assign io_ftqInter_toFtq_pdWb_bits_pd_5_brType = io_ftqInter_toFtq_pdWb_bits_pd_brType[5];
  assign io_ftqInter_toFtq_pdWb_bits_pd_6_brType = io_ftqInter_toFtq_pdWb_bits_pd_brType[6];
  assign io_ftqInter_toFtq_pdWb_bits_pd_7_brType = io_ftqInter_toFtq_pdWb_bits_pd_brType[7];
  assign io_ftqInter_toFtq_pdWb_bits_pd_8_brType = io_ftqInter_toFtq_pdWb_bits_pd_brType[8];
  assign io_ftqInter_toFtq_pdWb_bits_pd_9_brType = io_ftqInter_toFtq_pdWb_bits_pd_brType[9];
  assign io_ftqInter_toFtq_pdWb_bits_pd_10_brType = io_ftqInter_toFtq_pdWb_bits_pd_brType[10];
  assign io_ftqInter_toFtq_pdWb_bits_pd_11_brType = io_ftqInter_toFtq_pdWb_bits_pd_brType[11];
  assign io_ftqInter_toFtq_pdWb_bits_pd_12_brType = io_ftqInter_toFtq_pdWb_bits_pd_brType[12];
  assign io_ftqInter_toFtq_pdWb_bits_pd_13_brType = io_ftqInter_toFtq_pdWb_bits_pd_brType[13];
  assign io_ftqInter_toFtq_pdWb_bits_pd_14_brType = io_ftqInter_toFtq_pdWb_bits_pd_brType[14];
  assign io_ftqInter_toFtq_pdWb_bits_pd_15_brType = io_ftqInter_toFtq_pdWb_bits_pd_brType[15];
  assign io_ftqInter_toFtq_pdWb_bits_pd_0_isCall = io_ftqInter_toFtq_pdWb_bits_pd_isCall[0];
  assign io_ftqInter_toFtq_pdWb_bits_pd_1_isCall = io_ftqInter_toFtq_pdWb_bits_pd_isCall[1];
  assign io_ftqInter_toFtq_pdWb_bits_pd_2_isCall = io_ftqInter_toFtq_pdWb_bits_pd_isCall[2];
  assign io_ftqInter_toFtq_pdWb_bits_pd_3_isCall = io_ftqInter_toFtq_pdWb_bits_pd_isCall[3];
  assign io_ftqInter_toFtq_pdWb_bits_pd_4_isCall = io_ftqInter_toFtq_pdWb_bits_pd_isCall[4];
  assign io_ftqInter_toFtq_pdWb_bits_pd_5_isCall = io_ftqInter_toFtq_pdWb_bits_pd_isCall[5];
  assign io_ftqInter_toFtq_pdWb_bits_pd_6_isCall = io_ftqInter_toFtq_pdWb_bits_pd_isCall[6];
  assign io_ftqInter_toFtq_pdWb_bits_pd_7_isCall = io_ftqInter_toFtq_pdWb_bits_pd_isCall[7];
  assign io_ftqInter_toFtq_pdWb_bits_pd_8_isCall = io_ftqInter_toFtq_pdWb_bits_pd_isCall[8];
  assign io_ftqInter_toFtq_pdWb_bits_pd_9_isCall = io_ftqInter_toFtq_pdWb_bits_pd_isCall[9];
  assign io_ftqInter_toFtq_pdWb_bits_pd_10_isCall = io_ftqInter_toFtq_pdWb_bits_pd_isCall[10];
  assign io_ftqInter_toFtq_pdWb_bits_pd_11_isCall = io_ftqInter_toFtq_pdWb_bits_pd_isCall[11];
  assign io_ftqInter_toFtq_pdWb_bits_pd_12_isCall = io_ftqInter_toFtq_pdWb_bits_pd_isCall[12];
  assign io_ftqInter_toFtq_pdWb_bits_pd_13_isCall = io_ftqInter_toFtq_pdWb_bits_pd_isCall[13];
  assign io_ftqInter_toFtq_pdWb_bits_pd_14_isCall = io_ftqInter_toFtq_pdWb_bits_pd_isCall[14];
  assign io_ftqInter_toFtq_pdWb_bits_pd_15_isCall = io_ftqInter_toFtq_pdWb_bits_pd_isCall[15];
  assign io_ftqInter_toFtq_pdWb_bits_pd_0_isRet = io_ftqInter_toFtq_pdWb_bits_pd_isRet[0];
  assign io_ftqInter_toFtq_pdWb_bits_pd_1_isRet = io_ftqInter_toFtq_pdWb_bits_pd_isRet[1];
  assign io_ftqInter_toFtq_pdWb_bits_pd_2_isRet = io_ftqInter_toFtq_pdWb_bits_pd_isRet[2];
  assign io_ftqInter_toFtq_pdWb_bits_pd_3_isRet = io_ftqInter_toFtq_pdWb_bits_pd_isRet[3];
  assign io_ftqInter_toFtq_pdWb_bits_pd_4_isRet = io_ftqInter_toFtq_pdWb_bits_pd_isRet[4];
  assign io_ftqInter_toFtq_pdWb_bits_pd_5_isRet = io_ftqInter_toFtq_pdWb_bits_pd_isRet[5];
  assign io_ftqInter_toFtq_pdWb_bits_pd_6_isRet = io_ftqInter_toFtq_pdWb_bits_pd_isRet[6];
  assign io_ftqInter_toFtq_pdWb_bits_pd_7_isRet = io_ftqInter_toFtq_pdWb_bits_pd_isRet[7];
  assign io_ftqInter_toFtq_pdWb_bits_pd_8_isRet = io_ftqInter_toFtq_pdWb_bits_pd_isRet[8];
  assign io_ftqInter_toFtq_pdWb_bits_pd_9_isRet = io_ftqInter_toFtq_pdWb_bits_pd_isRet[9];
  assign io_ftqInter_toFtq_pdWb_bits_pd_10_isRet = io_ftqInter_toFtq_pdWb_bits_pd_isRet[10];
  assign io_ftqInter_toFtq_pdWb_bits_pd_11_isRet = io_ftqInter_toFtq_pdWb_bits_pd_isRet[11];
  assign io_ftqInter_toFtq_pdWb_bits_pd_12_isRet = io_ftqInter_toFtq_pdWb_bits_pd_isRet[12];
  assign io_ftqInter_toFtq_pdWb_bits_pd_13_isRet = io_ftqInter_toFtq_pdWb_bits_pd_isRet[13];
  assign io_ftqInter_toFtq_pdWb_bits_pd_14_isRet = io_ftqInter_toFtq_pdWb_bits_pd_isRet[14];
  assign io_ftqInter_toFtq_pdWb_bits_pd_15_isRet = io_ftqInter_toFtq_pdWb_bits_pd_isRet[15];
  assign io_ftqInter_toFtq_pdWb_bits_instrRange_0 = io_ftqInter_toFtq_pdWb_bits_instrRange[0];
  assign io_ftqInter_toFtq_pdWb_bits_instrRange_1 = io_ftqInter_toFtq_pdWb_bits_instrRange[1];
  assign io_ftqInter_toFtq_pdWb_bits_instrRange_2 = io_ftqInter_toFtq_pdWb_bits_instrRange[2];
  assign io_ftqInter_toFtq_pdWb_bits_instrRange_3 = io_ftqInter_toFtq_pdWb_bits_instrRange[3];
  assign io_ftqInter_toFtq_pdWb_bits_instrRange_4 = io_ftqInter_toFtq_pdWb_bits_instrRange[4];
  assign io_ftqInter_toFtq_pdWb_bits_instrRange_5 = io_ftqInter_toFtq_pdWb_bits_instrRange[5];
  assign io_ftqInter_toFtq_pdWb_bits_instrRange_6 = io_ftqInter_toFtq_pdWb_bits_instrRange[6];
  assign io_ftqInter_toFtq_pdWb_bits_instrRange_7 = io_ftqInter_toFtq_pdWb_bits_instrRange[7];
  assign io_ftqInter_toFtq_pdWb_bits_instrRange_8 = io_ftqInter_toFtq_pdWb_bits_instrRange[8];
  assign io_ftqInter_toFtq_pdWb_bits_instrRange_9 = io_ftqInter_toFtq_pdWb_bits_instrRange[9];
  assign io_ftqInter_toFtq_pdWb_bits_instrRange_10 = io_ftqInter_toFtq_pdWb_bits_instrRange[10];
  assign io_ftqInter_toFtq_pdWb_bits_instrRange_11 = io_ftqInter_toFtq_pdWb_bits_instrRange[11];
  assign io_ftqInter_toFtq_pdWb_bits_instrRange_12 = io_ftqInter_toFtq_pdWb_bits_instrRange[12];
  assign io_ftqInter_toFtq_pdWb_bits_instrRange_13 = io_ftqInter_toFtq_pdWb_bits_instrRange[13];
  assign io_ftqInter_toFtq_pdWb_bits_instrRange_14 = io_ftqInter_toFtq_pdWb_bits_instrRange[14];
  assign io_ftqInter_toFtq_pdWb_bits_instrRange_15 = io_ftqInter_toFtq_pdWb_bits_instrRange[15];
  assign io_toIbuffer_bits_instrs_0 = io_toIbuffer_bits_instrs[0];
  assign io_toIbuffer_bits_instrs_1 = io_toIbuffer_bits_instrs[1];
  assign io_toIbuffer_bits_instrs_2 = io_toIbuffer_bits_instrs[2];
  assign io_toIbuffer_bits_instrs_3 = io_toIbuffer_bits_instrs[3];
  assign io_toIbuffer_bits_instrs_4 = io_toIbuffer_bits_instrs[4];
  assign io_toIbuffer_bits_instrs_5 = io_toIbuffer_bits_instrs[5];
  assign io_toIbuffer_bits_instrs_6 = io_toIbuffer_bits_instrs[6];
  assign io_toIbuffer_bits_instrs_7 = io_toIbuffer_bits_instrs[7];
  assign io_toIbuffer_bits_instrs_8 = io_toIbuffer_bits_instrs[8];
  assign io_toIbuffer_bits_instrs_9 = io_toIbuffer_bits_instrs[9];
  assign io_toIbuffer_bits_instrs_10 = io_toIbuffer_bits_instrs[10];
  assign io_toIbuffer_bits_instrs_11 = io_toIbuffer_bits_instrs[11];
  assign io_toIbuffer_bits_instrs_12 = io_toIbuffer_bits_instrs[12];
  assign io_toIbuffer_bits_instrs_13 = io_toIbuffer_bits_instrs[13];
  assign io_toIbuffer_bits_instrs_14 = io_toIbuffer_bits_instrs[14];
  assign io_toIbuffer_bits_instrs_15 = io_toIbuffer_bits_instrs[15];
  assign io_toIbuffer_bits_pd_0_isRVC = io_toIbuffer_bits_pd_isRVC[0];
  assign io_toIbuffer_bits_pd_1_isRVC = io_toIbuffer_bits_pd_isRVC[1];
  assign io_toIbuffer_bits_pd_2_isRVC = io_toIbuffer_bits_pd_isRVC[2];
  assign io_toIbuffer_bits_pd_3_isRVC = io_toIbuffer_bits_pd_isRVC[3];
  assign io_toIbuffer_bits_pd_4_isRVC = io_toIbuffer_bits_pd_isRVC[4];
  assign io_toIbuffer_bits_pd_5_isRVC = io_toIbuffer_bits_pd_isRVC[5];
  assign io_toIbuffer_bits_pd_6_isRVC = io_toIbuffer_bits_pd_isRVC[6];
  assign io_toIbuffer_bits_pd_7_isRVC = io_toIbuffer_bits_pd_isRVC[7];
  assign io_toIbuffer_bits_pd_8_isRVC = io_toIbuffer_bits_pd_isRVC[8];
  assign io_toIbuffer_bits_pd_9_isRVC = io_toIbuffer_bits_pd_isRVC[9];
  assign io_toIbuffer_bits_pd_10_isRVC = io_toIbuffer_bits_pd_isRVC[10];
  assign io_toIbuffer_bits_pd_11_isRVC = io_toIbuffer_bits_pd_isRVC[11];
  assign io_toIbuffer_bits_pd_12_isRVC = io_toIbuffer_bits_pd_isRVC[12];
  assign io_toIbuffer_bits_pd_13_isRVC = io_toIbuffer_bits_pd_isRVC[13];
  assign io_toIbuffer_bits_pd_14_isRVC = io_toIbuffer_bits_pd_isRVC[14];
  assign io_toIbuffer_bits_pd_15_isRVC = io_toIbuffer_bits_pd_isRVC[15];
  assign io_toIbuffer_bits_pd_0_brType = io_toIbuffer_bits_pd_brType[0];
  assign io_toIbuffer_bits_pd_1_brType = io_toIbuffer_bits_pd_brType[1];
  assign io_toIbuffer_bits_pd_2_brType = io_toIbuffer_bits_pd_brType[2];
  assign io_toIbuffer_bits_pd_3_brType = io_toIbuffer_bits_pd_brType[3];
  assign io_toIbuffer_bits_pd_4_brType = io_toIbuffer_bits_pd_brType[4];
  assign io_toIbuffer_bits_pd_5_brType = io_toIbuffer_bits_pd_brType[5];
  assign io_toIbuffer_bits_pd_6_brType = io_toIbuffer_bits_pd_brType[6];
  assign io_toIbuffer_bits_pd_7_brType = io_toIbuffer_bits_pd_brType[7];
  assign io_toIbuffer_bits_pd_8_brType = io_toIbuffer_bits_pd_brType[8];
  assign io_toIbuffer_bits_pd_9_brType = io_toIbuffer_bits_pd_brType[9];
  assign io_toIbuffer_bits_pd_10_brType = io_toIbuffer_bits_pd_brType[10];
  assign io_toIbuffer_bits_pd_11_brType = io_toIbuffer_bits_pd_brType[11];
  assign io_toIbuffer_bits_pd_12_brType = io_toIbuffer_bits_pd_brType[12];
  assign io_toIbuffer_bits_pd_13_brType = io_toIbuffer_bits_pd_brType[13];
  assign io_toIbuffer_bits_pd_14_brType = io_toIbuffer_bits_pd_brType[14];
  assign io_toIbuffer_bits_pd_15_brType = io_toIbuffer_bits_pd_brType[15];
  assign io_toIbuffer_bits_pd_0_isCall = io_toIbuffer_bits_pd_isCall[0];
  assign io_toIbuffer_bits_pd_1_isCall = io_toIbuffer_bits_pd_isCall[1];
  assign io_toIbuffer_bits_pd_2_isCall = io_toIbuffer_bits_pd_isCall[2];
  assign io_toIbuffer_bits_pd_3_isCall = io_toIbuffer_bits_pd_isCall[3];
  assign io_toIbuffer_bits_pd_4_isCall = io_toIbuffer_bits_pd_isCall[4];
  assign io_toIbuffer_bits_pd_5_isCall = io_toIbuffer_bits_pd_isCall[5];
  assign io_toIbuffer_bits_pd_6_isCall = io_toIbuffer_bits_pd_isCall[6];
  assign io_toIbuffer_bits_pd_7_isCall = io_toIbuffer_bits_pd_isCall[7];
  assign io_toIbuffer_bits_pd_8_isCall = io_toIbuffer_bits_pd_isCall[8];
  assign io_toIbuffer_bits_pd_9_isCall = io_toIbuffer_bits_pd_isCall[9];
  assign io_toIbuffer_bits_pd_10_isCall = io_toIbuffer_bits_pd_isCall[10];
  assign io_toIbuffer_bits_pd_11_isCall = io_toIbuffer_bits_pd_isCall[11];
  assign io_toIbuffer_bits_pd_12_isCall = io_toIbuffer_bits_pd_isCall[12];
  assign io_toIbuffer_bits_pd_13_isCall = io_toIbuffer_bits_pd_isCall[13];
  assign io_toIbuffer_bits_pd_14_isCall = io_toIbuffer_bits_pd_isCall[14];
  assign io_toIbuffer_bits_pd_15_isCall = io_toIbuffer_bits_pd_isCall[15];
  assign io_toIbuffer_bits_pd_0_isRet = io_toIbuffer_bits_pd_isRet[0];
  assign io_toIbuffer_bits_pd_1_isRet = io_toIbuffer_bits_pd_isRet[1];
  assign io_toIbuffer_bits_pd_2_isRet = io_toIbuffer_bits_pd_isRet[2];
  assign io_toIbuffer_bits_pd_3_isRet = io_toIbuffer_bits_pd_isRet[3];
  assign io_toIbuffer_bits_pd_4_isRet = io_toIbuffer_bits_pd_isRet[4];
  assign io_toIbuffer_bits_pd_5_isRet = io_toIbuffer_bits_pd_isRet[5];
  assign io_toIbuffer_bits_pd_6_isRet = io_toIbuffer_bits_pd_isRet[6];
  assign io_toIbuffer_bits_pd_7_isRet = io_toIbuffer_bits_pd_isRet[7];
  assign io_toIbuffer_bits_pd_8_isRet = io_toIbuffer_bits_pd_isRet[8];
  assign io_toIbuffer_bits_pd_9_isRet = io_toIbuffer_bits_pd_isRet[9];
  assign io_toIbuffer_bits_pd_10_isRet = io_toIbuffer_bits_pd_isRet[10];
  assign io_toIbuffer_bits_pd_11_isRet = io_toIbuffer_bits_pd_isRet[11];
  assign io_toIbuffer_bits_pd_12_isRet = io_toIbuffer_bits_pd_isRet[12];
  assign io_toIbuffer_bits_pd_13_isRet = io_toIbuffer_bits_pd_isRet[13];
  assign io_toIbuffer_bits_pd_14_isRet = io_toIbuffer_bits_pd_isRet[14];
  assign io_toIbuffer_bits_pd_15_isRet = io_toIbuffer_bits_pd_isRet[15];
  assign io_toIbuffer_bits_pd_1_valid = io_toIbuffer_bits_pd_valid[1];
  assign io_toIbuffer_bits_pd_2_valid = io_toIbuffer_bits_pd_valid[2];
  assign io_toIbuffer_bits_pd_3_valid = io_toIbuffer_bits_pd_valid[3];
  assign io_toIbuffer_bits_pd_4_valid = io_toIbuffer_bits_pd_valid[4];
  assign io_toIbuffer_bits_pd_5_valid = io_toIbuffer_bits_pd_valid[5];
  assign io_toIbuffer_bits_pd_6_valid = io_toIbuffer_bits_pd_valid[6];
  assign io_toIbuffer_bits_pd_7_valid = io_toIbuffer_bits_pd_valid[7];
  assign io_toIbuffer_bits_pd_8_valid = io_toIbuffer_bits_pd_valid[8];
  assign io_toIbuffer_bits_pd_9_valid = io_toIbuffer_bits_pd_valid[9];
  assign io_toIbuffer_bits_pd_10_valid = io_toIbuffer_bits_pd_valid[10];
  assign io_toIbuffer_bits_pd_11_valid = io_toIbuffer_bits_pd_valid[11];
  assign io_toIbuffer_bits_pd_12_valid = io_toIbuffer_bits_pd_valid[12];
  assign io_toIbuffer_bits_pd_13_valid = io_toIbuffer_bits_pd_valid[13];
  assign io_toIbuffer_bits_pd_14_valid = io_toIbuffer_bits_pd_valid[14];
  assign io_toIbuffer_bits_pd_15_valid = io_toIbuffer_bits_pd_valid[15];
  assign io_toIbuffer_bits_foldpc_0 = io_toIbuffer_bits_foldpc[0];
  assign io_toIbuffer_bits_foldpc_1 = io_toIbuffer_bits_foldpc[1];
  assign io_toIbuffer_bits_foldpc_2 = io_toIbuffer_bits_foldpc[2];
  assign io_toIbuffer_bits_foldpc_3 = io_toIbuffer_bits_foldpc[3];
  assign io_toIbuffer_bits_foldpc_4 = io_toIbuffer_bits_foldpc[4];
  assign io_toIbuffer_bits_foldpc_5 = io_toIbuffer_bits_foldpc[5];
  assign io_toIbuffer_bits_foldpc_6 = io_toIbuffer_bits_foldpc[6];
  assign io_toIbuffer_bits_foldpc_7 = io_toIbuffer_bits_foldpc[7];
  assign io_toIbuffer_bits_foldpc_8 = io_toIbuffer_bits_foldpc[8];
  assign io_toIbuffer_bits_foldpc_9 = io_toIbuffer_bits_foldpc[9];
  assign io_toIbuffer_bits_foldpc_10 = io_toIbuffer_bits_foldpc[10];
  assign io_toIbuffer_bits_foldpc_11 = io_toIbuffer_bits_foldpc[11];
  assign io_toIbuffer_bits_foldpc_12 = io_toIbuffer_bits_foldpc[12];
  assign io_toIbuffer_bits_foldpc_13 = io_toIbuffer_bits_foldpc[13];
  assign io_toIbuffer_bits_foldpc_14 = io_toIbuffer_bits_foldpc[14];
  assign io_toIbuffer_bits_foldpc_15 = io_toIbuffer_bits_foldpc[15];
  assign io_toIbuffer_bits_ftqOffset_0_valid = io_toIbuffer_bits_ftqOffset_valid[0];
  assign io_toIbuffer_bits_ftqOffset_1_valid = io_toIbuffer_bits_ftqOffset_valid[1];
  assign io_toIbuffer_bits_ftqOffset_2_valid = io_toIbuffer_bits_ftqOffset_valid[2];
  assign io_toIbuffer_bits_ftqOffset_3_valid = io_toIbuffer_bits_ftqOffset_valid[3];
  assign io_toIbuffer_bits_ftqOffset_4_valid = io_toIbuffer_bits_ftqOffset_valid[4];
  assign io_toIbuffer_bits_ftqOffset_5_valid = io_toIbuffer_bits_ftqOffset_valid[5];
  assign io_toIbuffer_bits_ftqOffset_6_valid = io_toIbuffer_bits_ftqOffset_valid[6];
  assign io_toIbuffer_bits_ftqOffset_7_valid = io_toIbuffer_bits_ftqOffset_valid[7];
  assign io_toIbuffer_bits_ftqOffset_8_valid = io_toIbuffer_bits_ftqOffset_valid[8];
  assign io_toIbuffer_bits_ftqOffset_9_valid = io_toIbuffer_bits_ftqOffset_valid[9];
  assign io_toIbuffer_bits_ftqOffset_10_valid = io_toIbuffer_bits_ftqOffset_valid[10];
  assign io_toIbuffer_bits_ftqOffset_11_valid = io_toIbuffer_bits_ftqOffset_valid[11];
  assign io_toIbuffer_bits_ftqOffset_12_valid = io_toIbuffer_bits_ftqOffset_valid[12];
  assign io_toIbuffer_bits_ftqOffset_13_valid = io_toIbuffer_bits_ftqOffset_valid[13];
  assign io_toIbuffer_bits_ftqOffset_14_valid = io_toIbuffer_bits_ftqOffset_valid[14];
  assign io_toIbuffer_bits_ftqOffset_15_valid = io_toIbuffer_bits_ftqOffset_valid[15];
  assign io_toIbuffer_bits_exceptionType_0 = io_toIbuffer_bits_exceptionType[0];
  assign io_toIbuffer_bits_exceptionType_1 = io_toIbuffer_bits_exceptionType[1];
  assign io_toIbuffer_bits_exceptionType_2 = io_toIbuffer_bits_exceptionType[2];
  assign io_toIbuffer_bits_exceptionType_3 = io_toIbuffer_bits_exceptionType[3];
  assign io_toIbuffer_bits_exceptionType_4 = io_toIbuffer_bits_exceptionType[4];
  assign io_toIbuffer_bits_exceptionType_5 = io_toIbuffer_bits_exceptionType[5];
  assign io_toIbuffer_bits_exceptionType_6 = io_toIbuffer_bits_exceptionType[6];
  assign io_toIbuffer_bits_exceptionType_7 = io_toIbuffer_bits_exceptionType[7];
  assign io_toIbuffer_bits_exceptionType_8 = io_toIbuffer_bits_exceptionType[8];
  assign io_toIbuffer_bits_exceptionType_9 = io_toIbuffer_bits_exceptionType[9];
  assign io_toIbuffer_bits_exceptionType_10 = io_toIbuffer_bits_exceptionType[10];
  assign io_toIbuffer_bits_exceptionType_11 = io_toIbuffer_bits_exceptionType[11];
  assign io_toIbuffer_bits_exceptionType_12 = io_toIbuffer_bits_exceptionType[12];
  assign io_toIbuffer_bits_exceptionType_13 = io_toIbuffer_bits_exceptionType[13];
  assign io_toIbuffer_bits_exceptionType_14 = io_toIbuffer_bits_exceptionType[14];
  assign io_toIbuffer_bits_exceptionType_15 = io_toIbuffer_bits_exceptionType[15];
  assign io_toIbuffer_bits_crossPageIPFFix_0 = io_toIbuffer_bits_crossPageIPFFix[0];
  assign io_toIbuffer_bits_crossPageIPFFix_1 = io_toIbuffer_bits_crossPageIPFFix[1];
  assign io_toIbuffer_bits_crossPageIPFFix_2 = io_toIbuffer_bits_crossPageIPFFix[2];
  assign io_toIbuffer_bits_crossPageIPFFix_3 = io_toIbuffer_bits_crossPageIPFFix[3];
  assign io_toIbuffer_bits_crossPageIPFFix_4 = io_toIbuffer_bits_crossPageIPFFix[4];
  assign io_toIbuffer_bits_crossPageIPFFix_5 = io_toIbuffer_bits_crossPageIPFFix[5];
  assign io_toIbuffer_bits_crossPageIPFFix_6 = io_toIbuffer_bits_crossPageIPFFix[6];
  assign io_toIbuffer_bits_crossPageIPFFix_7 = io_toIbuffer_bits_crossPageIPFFix[7];
  assign io_toIbuffer_bits_crossPageIPFFix_8 = io_toIbuffer_bits_crossPageIPFFix[8];
  assign io_toIbuffer_bits_crossPageIPFFix_9 = io_toIbuffer_bits_crossPageIPFFix[9];
  assign io_toIbuffer_bits_crossPageIPFFix_10 = io_toIbuffer_bits_crossPageIPFFix[10];
  assign io_toIbuffer_bits_crossPageIPFFix_11 = io_toIbuffer_bits_crossPageIPFFix[11];
  assign io_toIbuffer_bits_crossPageIPFFix_12 = io_toIbuffer_bits_crossPageIPFFix[12];
  assign io_toIbuffer_bits_crossPageIPFFix_13 = io_toIbuffer_bits_crossPageIPFFix[13];
  assign io_toIbuffer_bits_crossPageIPFFix_14 = io_toIbuffer_bits_crossPageIPFFix[14];
  assign io_toIbuffer_bits_crossPageIPFFix_15 = io_toIbuffer_bits_crossPageIPFFix[15];
  assign io_toIbuffer_bits_illegalInstr_0 = io_toIbuffer_bits_illegalInstr[0];
  assign io_toIbuffer_bits_illegalInstr_1 = io_toIbuffer_bits_illegalInstr[1];
  assign io_toIbuffer_bits_illegalInstr_2 = io_toIbuffer_bits_illegalInstr[2];
  assign io_toIbuffer_bits_illegalInstr_3 = io_toIbuffer_bits_illegalInstr[3];
  assign io_toIbuffer_bits_illegalInstr_4 = io_toIbuffer_bits_illegalInstr[4];
  assign io_toIbuffer_bits_illegalInstr_5 = io_toIbuffer_bits_illegalInstr[5];
  assign io_toIbuffer_bits_illegalInstr_6 = io_toIbuffer_bits_illegalInstr[6];
  assign io_toIbuffer_bits_illegalInstr_7 = io_toIbuffer_bits_illegalInstr[7];
  assign io_toIbuffer_bits_illegalInstr_8 = io_toIbuffer_bits_illegalInstr[8];
  assign io_toIbuffer_bits_illegalInstr_9 = io_toIbuffer_bits_illegalInstr[9];
  assign io_toIbuffer_bits_illegalInstr_10 = io_toIbuffer_bits_illegalInstr[10];
  assign io_toIbuffer_bits_illegalInstr_11 = io_toIbuffer_bits_illegalInstr[11];
  assign io_toIbuffer_bits_illegalInstr_12 = io_toIbuffer_bits_illegalInstr[12];
  assign io_toIbuffer_bits_illegalInstr_13 = io_toIbuffer_bits_illegalInstr[13];
  assign io_toIbuffer_bits_illegalInstr_14 = io_toIbuffer_bits_illegalInstr[14];
  assign io_toIbuffer_bits_illegalInstr_15 = io_toIbuffer_bits_illegalInstr[15];
  assign io_toIbuffer_bits_triggered_0 = io_toIbuffer_bits_triggered[0];
  assign io_toIbuffer_bits_triggered_1 = io_toIbuffer_bits_triggered[1];
  assign io_toIbuffer_bits_triggered_2 = io_toIbuffer_bits_triggered[2];
  assign io_toIbuffer_bits_triggered_3 = io_toIbuffer_bits_triggered[3];
  assign io_toIbuffer_bits_triggered_4 = io_toIbuffer_bits_triggered[4];
  assign io_toIbuffer_bits_triggered_5 = io_toIbuffer_bits_triggered[5];
  assign io_toIbuffer_bits_triggered_6 = io_toIbuffer_bits_triggered[6];
  assign io_toIbuffer_bits_triggered_7 = io_toIbuffer_bits_triggered[7];
  assign io_toIbuffer_bits_triggered_8 = io_toIbuffer_bits_triggered[8];
  assign io_toIbuffer_bits_triggered_9 = io_toIbuffer_bits_triggered[9];
  assign io_toIbuffer_bits_triggered_10 = io_toIbuffer_bits_triggered[10];
  assign io_toIbuffer_bits_triggered_11 = io_toIbuffer_bits_triggered[11];
  assign io_toIbuffer_bits_triggered_12 = io_toIbuffer_bits_triggered[12];
  assign io_toIbuffer_bits_triggered_13 = io_toIbuffer_bits_triggered[13];
  assign io_toIbuffer_bits_triggered_14 = io_toIbuffer_bits_triggered[14];
  assign io_toIbuffer_bits_triggered_15 = io_toIbuffer_bits_triggered[15];
  assign io_toIbuffer_bits_isLastInFtqEntry_0 = io_toIbuffer_bits_isLastInFtqEntry[0];
  assign io_toIbuffer_bits_isLastInFtqEntry_1 = io_toIbuffer_bits_isLastInFtqEntry[1];
  assign io_toIbuffer_bits_isLastInFtqEntry_2 = io_toIbuffer_bits_isLastInFtqEntry[2];
  assign io_toIbuffer_bits_isLastInFtqEntry_3 = io_toIbuffer_bits_isLastInFtqEntry[3];
  assign io_toIbuffer_bits_isLastInFtqEntry_4 = io_toIbuffer_bits_isLastInFtqEntry[4];
  assign io_toIbuffer_bits_isLastInFtqEntry_5 = io_toIbuffer_bits_isLastInFtqEntry[5];
  assign io_toIbuffer_bits_isLastInFtqEntry_6 = io_toIbuffer_bits_isLastInFtqEntry[6];
  assign io_toIbuffer_bits_isLastInFtqEntry_7 = io_toIbuffer_bits_isLastInFtqEntry[7];
  assign io_toIbuffer_bits_isLastInFtqEntry_8 = io_toIbuffer_bits_isLastInFtqEntry[8];
  assign io_toIbuffer_bits_isLastInFtqEntry_9 = io_toIbuffer_bits_isLastInFtqEntry[9];
  assign io_toIbuffer_bits_isLastInFtqEntry_10 = io_toIbuffer_bits_isLastInFtqEntry[10];
  assign io_toIbuffer_bits_isLastInFtqEntry_11 = io_toIbuffer_bits_isLastInFtqEntry[11];
  assign io_toIbuffer_bits_isLastInFtqEntry_12 = io_toIbuffer_bits_isLastInFtqEntry[12];
  assign io_toIbuffer_bits_isLastInFtqEntry_13 = io_toIbuffer_bits_isLastInFtqEntry[13];
  assign io_toIbuffer_bits_isLastInFtqEntry_14 = io_toIbuffer_bits_isLastInFtqEntry[14];
  assign io_toIbuffer_bits_isLastInFtqEntry_15 = io_toIbuffer_bits_isLastInFtqEntry[15];
  assign io_toIbuffer_bits_pc_0 = io_toIbuffer_bits_pc[0];
  assign io_toIbuffer_bits_pc_1 = io_toIbuffer_bits_pc[1];
  assign io_toIbuffer_bits_pc_2 = io_toIbuffer_bits_pc[2];
  assign io_toIbuffer_bits_pc_3 = io_toIbuffer_bits_pc[3];
  assign io_toIbuffer_bits_pc_4 = io_toIbuffer_bits_pc[4];
  assign io_toIbuffer_bits_pc_5 = io_toIbuffer_bits_pc[5];
  assign io_toIbuffer_bits_pc_6 = io_toIbuffer_bits_pc[6];
  assign io_toIbuffer_bits_pc_7 = io_toIbuffer_bits_pc[7];
  assign io_toIbuffer_bits_pc_8 = io_toIbuffer_bits_pc[8];
  assign io_toIbuffer_bits_pc_9 = io_toIbuffer_bits_pc[9];
  assign io_toIbuffer_bits_pc_10 = io_toIbuffer_bits_pc[10];
  assign io_toIbuffer_bits_pc_11 = io_toIbuffer_bits_pc[11];
  assign io_toIbuffer_bits_pc_12 = io_toIbuffer_bits_pc[12];
  assign io_toIbuffer_bits_pc_13 = io_toIbuffer_bits_pc[13];
  assign io_toIbuffer_bits_pc_14 = io_toIbuffer_bits_pc[14];
  assign io_toIbuffer_bits_pc_15 = io_toIbuffer_bits_pc[15];
  assign io_toIbuffer_bits_topdown_info_reasons_0 = io_toIbuffer_bits_topdown_info_reasons[0];
  assign io_toIbuffer_bits_topdown_info_reasons_1 = io_toIbuffer_bits_topdown_info_reasons[1];
  assign io_toIbuffer_bits_topdown_info_reasons_2 = io_toIbuffer_bits_topdown_info_reasons[2];
  assign io_toIbuffer_bits_topdown_info_reasons_3 = io_toIbuffer_bits_topdown_info_reasons[3];
  assign io_toIbuffer_bits_topdown_info_reasons_4 = io_toIbuffer_bits_topdown_info_reasons[4];
  assign io_toIbuffer_bits_topdown_info_reasons_5 = io_toIbuffer_bits_topdown_info_reasons[5];
  assign io_toIbuffer_bits_topdown_info_reasons_6 = io_toIbuffer_bits_topdown_info_reasons[6];
  assign io_toIbuffer_bits_topdown_info_reasons_7 = io_toIbuffer_bits_topdown_info_reasons[7];
  assign io_toIbuffer_bits_topdown_info_reasons_8 = io_toIbuffer_bits_topdown_info_reasons[8];
  assign io_toIbuffer_bits_topdown_info_reasons_9 = io_toIbuffer_bits_topdown_info_reasons[9];
  assign io_toIbuffer_bits_topdown_info_reasons_10 = io_toIbuffer_bits_topdown_info_reasons[10];
  assign io_toIbuffer_bits_topdown_info_reasons_11 = io_toIbuffer_bits_topdown_info_reasons[11];
  assign io_toIbuffer_bits_topdown_info_reasons_12 = io_toIbuffer_bits_topdown_info_reasons[12];
  assign io_toIbuffer_bits_topdown_info_reasons_13 = io_toIbuffer_bits_topdown_info_reasons[13];
  assign io_toIbuffer_bits_topdown_info_reasons_14 = io_toIbuffer_bits_topdown_info_reasons[14];
  assign io_toIbuffer_bits_topdown_info_reasons_15 = io_toIbuffer_bits_topdown_info_reasons[15];
  assign io_toIbuffer_bits_topdown_info_reasons_16 = io_toIbuffer_bits_topdown_info_reasons[16];
  assign io_toIbuffer_bits_topdown_info_reasons_17 = io_toIbuffer_bits_topdown_info_reasons[17];
  assign io_toIbuffer_bits_topdown_info_reasons_18 = io_toIbuffer_bits_topdown_info_reasons[18];
  assign io_toIbuffer_bits_topdown_info_reasons_19 = io_toIbuffer_bits_topdown_info_reasons[19];
  assign io_toIbuffer_bits_topdown_info_reasons_20 = io_toIbuffer_bits_topdown_info_reasons[20];
  assign io_toIbuffer_bits_topdown_info_reasons_21 = io_toIbuffer_bits_topdown_info_reasons[21];
  assign io_toIbuffer_bits_topdown_info_reasons_22 = io_toIbuffer_bits_topdown_info_reasons[22];
  assign io_toIbuffer_bits_topdown_info_reasons_23 = io_toIbuffer_bits_topdown_info_reasons[23];
  assign io_toIbuffer_bits_topdown_info_reasons_24 = io_toIbuffer_bits_topdown_info_reasons[24];
  assign io_toIbuffer_bits_topdown_info_reasons_25 = io_toIbuffer_bits_topdown_info_reasons[25];
  assign io_toIbuffer_bits_topdown_info_reasons_26 = io_toIbuffer_bits_topdown_info_reasons[26];
  assign io_toIbuffer_bits_topdown_info_reasons_27 = io_toIbuffer_bits_topdown_info_reasons[27];
  assign io_toIbuffer_bits_topdown_info_reasons_28 = io_toIbuffer_bits_topdown_info_reasons[28];
  assign io_toIbuffer_bits_topdown_info_reasons_29 = io_toIbuffer_bits_topdown_info_reasons[29];
  assign io_toIbuffer_bits_topdown_info_reasons_30 = io_toIbuffer_bits_topdown_info_reasons[30];
  assign io_toIbuffer_bits_topdown_info_reasons_31 = io_toIbuffer_bits_topdown_info_reasons[31];
  assign io_toIbuffer_bits_topdown_info_reasons_32 = io_toIbuffer_bits_topdown_info_reasons[32];
  assign io_toIbuffer_bits_topdown_info_reasons_33 = io_toIbuffer_bits_topdown_info_reasons[33];
  assign io_toIbuffer_bits_topdown_info_reasons_34 = io_toIbuffer_bits_topdown_info_reasons[34];
  assign io_toIbuffer_bits_topdown_info_reasons_35 = io_toIbuffer_bits_topdown_info_reasons[35];
  assign io_toIbuffer_bits_topdown_info_reasons_36 = io_toIbuffer_bits_topdown_info_reasons[36];
  assign io_toIbuffer_bits_topdown_info_reasons_37 = io_toIbuffer_bits_topdown_info_reasons[37];
  assign io_perf_0_value = io_perf_value[0];
  assign io_perf_1_value = io_perf_value[1];
  assign io_perf_2_value = io_perf_value[2];
  assign io_perf_3_value = io_perf_value[3];
  assign io_perf_4_value = io_perf_value[4];
  assign io_perf_5_value = io_perf_value[5];
  assign io_perf_6_value = io_perf_value[6];
  assign io_perf_7_value = io_perf_value[7];
  assign io_perf_8_value = io_perf_value[8];
  assign io_perf_9_value = io_perf_value[9];
  assign io_perf_10_value = io_perf_value[10];
  assign io_perf_11_value = io_perf_value[11];
  assign io_perf_12_value = io_perf_value[12];
endmodule
// END GENERATED(wrapper)
