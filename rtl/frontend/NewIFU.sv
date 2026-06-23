// =============================================================================
// xs_NewIFU_core —— 香山 V2R2（昆明湖）取指主控（IFU）可读重写核
//
// 在前端的位置（数据流见 docs/FRONTEND_OVERVIEW.md）：
//
//     BPU ──预测块──► FTQ ──取指请求(PC/ftqIdx)──► [ NewIFU ] ◄──取指数据──► ICache
//                                                      │  └──MMIO──► InstrUncache/iTLB/PMP
//                                                      ├──预解码后的指令──► IBuffer ──► 后端
//                                                      └──预解码发现的预测错──redirect──► FTQ
//
// NewIFU 负责：按 FTQ 给的 PC 向 ICache 取一个「取指块」(fetch block，最长 34B = 17 个
// 16-bit 半字)，收回 cacheline 数据后做：
//   1. 按 cut 指针从两条相邻 cacheline 拼出取指块的 16 个候选指令半字流；
//   2. 预解码(PreDecode)：识别 RVC / 指令边界(valid) / 分支类型 / 跳转偏移；
//   3. RVC 展开(RVCExpander×16)：把 16-bit 压缩指令还原成 32-bit；
//   4. 预测结果检查(PredChecker)：核对 BPU 的 taken/target 与实际译码是否一致，
//      不一致则向 FTQ 发 redirect(写回 pdWb)；
//   5. 处理「跨行半条 RVI」(last half)：取指块末尾若是一条 RVI 的前半，记下 middlePC，
//      下个块从该半字续取；
//   6. MMIO(非缓存)取指：用一个 11 态状态机串行地走 InstrUncache→iTLB→PMP→重发，
//      每个 MMIO 块只放 1 条指令，且必须等它从 RoB 提交后才继续取指；
//   7. 把整理好的指令 + 元数据(pd/pc/异常/触发器/范围)送入 IBuffer。
//
// 取指流水分 4 拍：f0(发请求) → f1(算 PC/cut 指针) → f2(收数据/切块/预解码) →
// f3(RVC 展开/预测检查/MMIO/送 IBuffer)，外加 1 拍 WriteBack(wb) 级把检查结果写回 FTQ。
//
// 设计取舍（为什么这么写）：
//  · PC 不在 f1 算完整 50 位，而是只算低位 + 进位选择(CatPC)，省功耗(见 §PC 切割)。
//  · ICache 只回送 40B 有效数据(5 bank)，IFU 把它复制一份首尾相接(Cat(data,data))，
//    用 cut 指针从「中段」取出请求数据，避免接收 2×64B(见 §cut)。
//  · RVC 边界检测在取指块中点(8)打断长依赖链，改善时序(在 PreDecode 内部完成)。
//
// 可读重写策略：本核把 firtool 展平的标量端口聚合为 struct/数组，流水级寄存器命名清晰
// (f1_*/f2_*/f3_*/wb_*)，MMIO 状态机用 enum；已单独验证过的子模块(PreDecode/
// RVCExpander/F3Predecoder/PredChecker/FrontendTrigger)作为黑盒在核内例化(golden 同名)，
// 本核聚焦 IFU 自身的控制与数据通路逻辑。
// =============================================================================
`default_nettype none

package xs_newifu_pkg;
  // ---- 取指几何参数 ----
  localparam int PredictWidth = 16;          // 一个取指块最多 16 条指令(16 个起点)
  localparam int VAddrBits    = 50;          // 虚拟地址位宽(本工程 SV/VA 截断后)
  localparam int PAddrBits    = 48;          // 物理地址位宽
  localparam int PAddrBitsMax = 56;          // gpaddr 用的最大物理地址位宽
  localparam int XLEN         = 64;
  localparam int blockOffBits = 6;           // cacheline = 64B，块内偏移 6 位
  localparam int blockBytes   = 64;
  localparam int PcCutPoint   = (VAddrBits / 4) - 1; // =11，PC 低位切割点
  localparam int FtqSize      = 64;          // FTQ 深度 → ftqIdx.value 6 位
  localparam int MemPredPCWidth = 10;        // foldpc 折叠宽度
  localparam int ExcW         = 2;           // ExceptionType 位宽

  // ---- ExceptionType 编码(与 Chisel FrontendBundle 一致) ----
  localparam logic [1:0] EXC_NONE = 2'h0;
  localparam logic [1:0] EXC_PF   = 2'h1;  // page fault
  localparam logic [1:0] EXC_GPF  = 2'h2;  // guest page fault
  localparam logic [1:0] EXC_AF   = 2'h3;  // access fault
  // merge = 取「优先级更高」者；编码上恰为取较大值(none<pf<gpf<af)
  function automatic logic [1:0] exc_merge(input logic [1:0] a, input logic [1:0] b);
    return (a >= b) ? a : b;
  endfunction
  function automatic logic exc_has(input logic [1:0] e);
    return |e;
  endfunction

  // ---- Pbmt 编码：nc=1, io=2 都属 uncacheable ----
  localparam logic [1:0] PBMT_NC = 2'h1;
  function automatic logic pbmt_is_uncache(input logic [1:0] p);
    return (p == 2'h1) || (p == 2'h2);
  endfunction

  // ---- MMIO 取指状态机(11 态，与 Chisel Enum 顺序一致) ----
  typedef enum logic [3:0] {
    M_IDLE          = 4'h0, // 空闲
    M_WAIT_LAST_CMT = 4'h1, // 等上一条提交(非幂等空间需串行化)
    M_SEND_REQ      = 4'h2, // 向 InstrUncache 发首次取指
    M_WAIT_RESP     = 4'h3, // 等 Uncache 返回首半
    M_SEND_TLB      = 4'h4, // 跨字需重发：先向 iTLB 取新页 paddr
    M_TLB_RESP      = 4'h5, // 等 iTLB 返回
    M_SEND_PMP      = 4'h6, // 用新 paddr 查 PMP
    M_RESEND_REQ    = 4'h7, // 用新 paddr 重发取指(取后半)
    M_WAIT_RESEND   = 4'h8, // 等重发返回
    M_WAIT_COMMIT   = 4'h9, // 等 RoB 提交本 MMIO 指令
    M_COMMITED      = 4'hA  // 已提交，回 idle
  } mmio_state_e;

  // ---- 预解码信息(PreDecodeInfo) ----
  typedef struct packed {
    logic       valid;   // 该位置是有效指令起点
    logic       isRVC;
    logic [1:0] brType;  // 00 notCFI / 01 branch / 10 jal / 11 jalr
    logic       isCall;
    logic       isRet;
  } pd_info_t;

  // ---- FTQ → IFU 取指请求 ----
  typedef struct packed {
    logic [VAddrBits-1:0] startAddr;       // 取指块起始 PC
    logic [VAddrBits-1:0] nextlineStart;   // 跨行时下一 cacheline 起始(查第二路 idx)
    logic [VAddrBits-1:0] nextStartAddr;   // 本块结束后的下一取指 PC(fall-through/目标)
    logic                 ftqIdx_flag;     // FTQ 指针(环形队列)flag
    logic [5:0]           ftqIdx_value;    // FTQ 指针 value
    logic                 ftqOffset_valid; // BPU 预测本块在某偏移处 taken
    logic [3:0]           ftqOffset_bits;  // taken 的指令偏移
  } ftq_req_t;
endpackage

import xs_newifu_pkg::*;

module xs_NewIFU_core (
  input  wire        clock,
  input  wire        reset,

  // ===== FTQ → IFU 取指请求 (f0) =====
  output wire        ftq_req_ready,
  input  wire        ftq_req_valid,
  input  ftq_req_t   ftq_req,
  input  wire [37:0] ftq_req_topdown_reasons, // topdown 计数器原因位(透传)

  // ===== FTQ → IFU 重定向 / BPU flush =====
  input  wire        ftq_redirect_valid,
  input  wire        ftq_redirect_ftqIdx_flag,
  input  wire [5:0]  ftq_redirect_ftqIdx_value,
  input  wire [3:0]  ftq_redirect_ftqOffset,
  input  wire        ftq_redirect_level,       // 1=flushItself(含自身)
  // topdown_redirect（驱动 topdown 计数器的"气泡原因"分类）
  input  wire        ftq_topdown_redirect_valid,
  input  wire        ftq_topdown_redirect_debugIsCtrl,
  input  wire        ftq_topdown_redirect_debugIsMemVio,
  input  wire        ftq_topdown_redirect_cfi_pd_isRet,
  input  wire        ftq_topdown_redirect_cfi_br_hit,
  input  wire        ftq_topdown_redirect_cfi_jr_hit,
  input  wire        ftq_topdown_redirect_cfi_sc_hit,
  // BPU stage2/3 flush（按 ftqIdx 比较是否冲刷 f0）
  input  wire        bpu_flush_s2_valid,
  input  wire        bpu_flush_s2_flag,
  input  wire [5:0]  bpu_flush_s2_value,
  input  wire        bpu_flush_s3_valid,
  input  wire        bpu_flush_s3_flag,
  input  wire [5:0]  bpu_flush_s3_value,

  // ===== IFU → FTQ 写回(预解码结果 / 预测错 redirect) =====
  output wire                            pdWb_valid,
  output wire [PredictWidth-1:0][VAddrBits-1:0] pdWb_pc,
  output pd_info_t [PredictWidth-1:0]    pdWb_pd,
  output wire                            pdWb_ftqIdx_flag,
  output wire [5:0]                      pdWb_ftqIdx_value,
  output wire                            pdWb_misOffset_valid,
  output wire [3:0]                      pdWb_misOffset_bits,
  output wire                            pdWb_cfiOffset_valid,
  output wire [VAddrBits-1:0]            pdWb_target,
  output wire [VAddrBits-1:0]            pdWb_jalTarget,
  output wire [PredictWidth-1:0]         pdWb_instrRange,

  // ===== ICache → IFU 取指响应 (f2) =====
  input  wire        icache_ready,
  input  wire        icache_resp_valid,
  input  wire        icache_resp_doubleline,
  input  wire [VAddrBits-1:0] icache_resp_vaddr_0,
  input  wire [VAddrBits-1:0] icache_resp_vaddr_1,
  input  wire [511:0] icache_resp_data,
  input  wire [PAddrBits-1:0] icache_resp_paddr_0,
  input  wire [1:0]  icache_resp_exception_0,
  input  wire [1:0]  icache_resp_exception_1,
  input  wire        icache_resp_pmp_mmio_0,
  input  wire        icache_resp_pmp_mmio_1,
  input  wire [1:0]  icache_resp_itlb_pbmt_0,
  input  wire [1:0]  icache_resp_itlb_pbmt_1,
  input  wire        icache_resp_backendException,
  input  wire [PAddrBitsMax-1:0] icache_resp_gpaddr,
  input  wire        icache_resp_isForVSnonLeafPTE,
  input  wire        icache_topdownIcacheMiss,
  input  wire        icache_topdownItlbMiss,
  output wire        icacheStop,            // 反压 ICache(f3 未就绪)

  // ===== ICache perf 信息(逐拍透传到 perf 计数) =====
  input  wire        perf_only_0_hit,
  input  wire        perf_only_0_miss,
  input  wire        perf_hit_0_hit_1,
  input  wire        perf_hit_0_miss_1,
  input  wire        perf_miss_0_hit_1,
  input  wire        perf_miss_0_miss_1,
  input  wire        perf_hit_0_except_1,
  input  wire        perf_miss_0_except_1,
  input  wire        perf_except_0,
  input  wire        perf_bank_hit_0,
  input  wire        perf_bank_hit_1,
  input  wire        perf_hit,

  // ===== IFU → IBuffer =====
  input  wire        ibuffer_ready,
  output wire        ibuffer_valid,
  output wire [PredictWidth-1:0][31:0] ibuffer_instrs,
  output wire [PredictWidth-1:0]       ibuffer_valid_vec,
  output wire [PredictWidth-1:0]       ibuffer_enqEnable,
  output pd_info_t [PredictWidth-1:0]  ibuffer_pd,        // 注：IBuffer 只用 isRVC/brType
  output wire [PredictWidth-1:0][9:0]  ibuffer_foldpc,
  output wire [PredictWidth-1:0]       ibuffer_ftqOffset_valid,
  output wire [PredictWidth-1:0]       ibuffer_backendException,
  output wire [PredictWidth-1:0][1:0]  ibuffer_exceptionType,
  output wire [PredictWidth-1:0]       ibuffer_crossPageIPFFix,
  output wire [PredictWidth-1:0]       ibuffer_illegalInstr,
  output wire [PredictWidth-1:0][3:0]  ibuffer_triggered,
  output wire [PredictWidth-1:0]       ibuffer_isLastInFtqEntry,
  output wire [PredictWidth-1:0][VAddrBits-1:0] ibuffer_pc,
  output wire        ibuffer_ftqPtr_flag,
  output wire [5:0]  ibuffer_ftqPtr_value,
  output wire [37:0] ibuffer_topdown_reasons,

  // ===== IFU → 后端 gpaddr mem 写 =====
  output wire        toBackend_gpaddrMem_wen,
  output wire [5:0]  toBackend_gpaddrMem_waddr,
  output wire [PAddrBitsMax-1:0] toBackend_gpaddrMem_wdata_gpaddr,
  output wire        toBackend_gpaddrMem_wdata_isForVSnonLeafPTE,

  // ===== MMIO: InstrUncache 接口 =====
  input  wire        uncache_resp_valid,
  input  wire [31:0] uncache_resp_data,
  input  wire        uncache_resp_corrupt,
  input  wire        uncache_req_ready,
  output wire        uncache_req_valid,
  output wire [PAddrBits-1:0] uncache_req_addr,

  // ===== MMIO: iTLB 接口 =====
  input  wire        itlb_req_ready,
  output wire        itlb_req_valid,
  output wire [VAddrBits-1:0] itlb_req_vaddr,
  output wire        itlb_resp_ready,
  input  wire        itlb_resp_valid,
  input  wire [PAddrBits-1:0] itlb_resp_paddr_0,
  input  wire [63:0] itlb_resp_gpaddr_0,
  input  wire [1:0]  itlb_resp_pbmt_0,
  input  wire        itlb_resp_miss,
  input  wire        itlb_resp_isForVSnonLeafPTE,
  input  wire        itlb_resp_gpf_instr,
  input  wire        itlb_resp_pf_instr,
  input  wire        itlb_resp_af_instr,

  // ===== MMIO: PMP 接口 =====
  output wire [PAddrBits-1:0] pmp_req_addr,
  input  wire        pmp_resp_instr,
  input  wire        pmp_resp_mmio,

  // ===== MMIO: 提交读 =====
  output wire        mmioCommitRead_mmioFtqPtr_flag,
  output wire [5:0]  mmioCommitRead_mmioFtqPtr_value,
  input  wire        mmioCommitRead_mmioLastCommit,

  // ===== FrontendTrigger 配置 (透传到黑盒 FrontendTrigger) =====
  input  wire        ft_tUpdate_valid,
  input  wire [1:0]  ft_tUpdate_addr,
  input  wire [1:0]  ft_tUpdate_matchType,
  input  wire        ft_tUpdate_select,
  input  wire [3:0]  ft_tUpdate_action,
  input  wire        ft_tUpdate_chain,
  input  wire [63:0] ft_tUpdate_tdata2,
  input  wire [3:0]  ft_tEnableVec,
  input  wire        ft_debugMode,
  input  wire        ft_triggerCanRaiseBpExp,

  // ===== RoB 提交(用于判断 MMIO 指令是否已提交) =====
  input  wire [7:0]  rob_commit_valid,
  input  wire        rob_commit_0_ftqIdx_flag, input wire [5:0] rob_commit_0_ftqIdx_value, input wire [3:0] rob_commit_0_ftqOffset,
  input  wire        rob_commit_1_ftqIdx_flag, input wire [5:0] rob_commit_1_ftqIdx_value, input wire [3:0] rob_commit_1_ftqOffset,
  input  wire        rob_commit_2_ftqIdx_flag, input wire [5:0] rob_commit_2_ftqIdx_value, input wire [3:0] rob_commit_2_ftqOffset,
  input  wire        rob_commit_3_ftqIdx_flag, input wire [5:0] rob_commit_3_ftqIdx_value, input wire [3:0] rob_commit_3_ftqOffset,
  input  wire        rob_commit_4_ftqIdx_flag, input wire [5:0] rob_commit_4_ftqIdx_value, input wire [3:0] rob_commit_4_ftqOffset,
  input  wire        rob_commit_5_ftqIdx_flag, input wire [5:0] rob_commit_5_ftqIdx_value, input wire [3:0] rob_commit_5_ftqOffset,
  input  wire        rob_commit_6_ftqIdx_flag, input wire [5:0] rob_commit_6_ftqIdx_value, input wire [3:0] rob_commit_6_ftqOffset,
  input  wire        rob_commit_7_ftqIdx_flag, input wire [5:0] rob_commit_7_ftqIdx_value, input wire [3:0] rob_commit_7_ftqOffset,

  input  wire        csr_fsIsOff,           // 浮点单元关闭(RVC 浮点访存判非法用)

  // ===== perf 事件计数(12+1 个 6 位计数) =====
  output wire [12:0][5:0] perf_value
);

  // ---------------------------------------------------------------------------
  // 工具函数
  // ---------------------------------------------------------------------------
  // cacheline 内 set index：取 startAddr 去掉块内偏移后的低位(此核 idx 直接用作 cut 拼接，
  // 实际 vSetIdx 由 ICache 侧消化，这里仅记录给 doubleline 比较——简化：不外引)。

  // CatPC：把「低位 + 1 位进位」与高位(或高位+1)拼成完整 VAddr。
  // 设计意图：f1 只算 startAddr 低 12 位 + i*2 的加法(带进位 bit)，高位不参与逐项加法以省功耗；
  //           最终 PC = 进位 ? {high+1, low} : {high, low}。
  function automatic logic [VAddrBits-1:0] catpc(
      input logic [PcCutPoint:0]            low,    // 低位含 1 位溢出(进位)
      input logic [VAddrBits-1:PcCutPoint]  hi,
      input logic [VAddrBits-1:PcCutPoint]  hi1);
    return low[PcCutPoint] ? {hi1, low[PcCutPoint-1:0]}
                           : {hi,  low[PcCutPoint-1:0]};
  endfunction

  // foldpc：把 pc[VAddrBits-1:1] 折叠成 MemPredPCWidth 位(XOR 折叠)
  function automatic logic [MemPredPCWidth-1:0] xorfold(input logic [VAddrBits-2:0] x);
    // VAddrBits-1 = 49 位输入折叠到 10 位：分 5 段(49=10*4+9)逐段异或
    logic [MemPredPCWidth-1:0] acc;
    int s, hi, w;
    acc = '0;
    for (s = 0; s * MemPredPCWidth < (VAddrBits-1); s++) begin
      logic [MemPredPCWidth-1:0] seg;
      seg = '0;
      for (w = 0; w < MemPredPCWidth; w++) begin
        if (s*MemPredPCWidth + w < (VAddrBits-1))
          seg[w] = x[s*MemPredPCWidth + w];
      end
      acc = acc ^ seg;
    end
    return acc;
  endfunction

  // ===========================================================================
  // flush / ready 骨架（f0~f3 的冲刷与反压关系）
  // ===========================================================================
  // 各级 flush 由「后端 redirect / MMIO redirect / 写回 redirect」组合而来；
  // 越靠前的级被越多来源冲刷。f0 还额外受 BPU stage2/3 flush。
  logic f0_flush, f1_flush, f2_flush, f3_flush;
  logic f1_ready, f2_ready, f3_ready;
  logic wb_redirect, mmio_redirect, backend_redirect;
  logic f3_wb_not_flush;          // 写回命中 f3 同一 ftqIdx 时不冲刷 f3
  logic icacheRespAllValid;

  // ===========================================================================
  // f0：向 ICache 发取指请求
  // ===========================================================================
  ftq_req_t f0_ftq_req;
  assign f0_ftq_req      = ftq_req;
  wire f0_valid      = ftq_req_valid;
  // crossCacheline = startAddr[blockOffBits-1]：起始地址落在 cacheline 后半 → 可能跨行
  wire f0_doubleLine = ftq_req.startAddr[blockOffBits-1];
  wire f0_fire       = ftq_req_valid && ftq_req_ready;

  // BPU 在 stage2/3 发现本预测块要冲刷：当 flush 指针「不晚于」待取块 ftqIdx 时冲刷。
  // 环形指针比较 shouldFlush(flushPtr, reqIdx) 展开为(与 Chisel isAfter 取反等价)：
  //   flush_flag ^ req_flag ^ (flush_value <= req_value)
  function automatic logic should_flush_by_bpu(
      input logic flush_flag, input logic [5:0] flush_val,
      input logic req_flag,   input logic [5:0] req_val);
    return flush_flag ^ req_flag ^ (flush_val <= req_val);
  endfunction
  wire f0_flush_from_bpu =
      (bpu_flush_s2_valid && should_flush_by_bpu(bpu_flush_s2_flag, bpu_flush_s2_value, f0_ftq_req.ftqIdx_flag, f0_ftq_req.ftqIdx_value)) ||
      (bpu_flush_s3_valid && should_flush_by_bpu(bpu_flush_s3_flag, bpu_flush_s3_value, f0_ftq_req.ftqIdx_flag, f0_ftq_req.ftqIdx_value));

  assign backend_redirect = ftq_redirect_valid;
  assign f3_flush = backend_redirect || (wb_redirect && !f3_wb_not_flush);
  assign f2_flush = backend_redirect || mmio_redirect || wb_redirect;
  assign f1_flush = f2_flush;
  assign f0_flush = f1_flush || f0_flush_from_bpu;

  // 取指请求 ready：f1 能接 且 ICache 就绪
  assign ftq_req_ready = f1_ready && icache_ready;

  // ===========================================================================
  // f1：算每条候选指令的 PC（低位 + 进位选择）与 cut 指针
  // ===========================================================================
  logic     f1_valid;
  ftq_req_t f1_ftq_req;
  logic     f1_doubleLine;
  wire      f1_fire = f1_valid && f2_ready;
  assign f1_ready = f1_fire || !f1_valid;

  always_ff @(posedge clock) if (f0_fire) f1_ftq_req    <= f0_ftq_req;
  always_ff @(posedge clock) if (f0_fire) f1_doubleLine <= f0_doubleLine;
  always_ff @(posedge clock or posedge reset) begin
    if (reset)                       f1_valid <= 1'b0;
    else if (f1_flush)               f1_valid <= 1'b0;
    else if (f0_fire && !f0_flush)   f1_valid <= 1'b1;
    else if (f1_fire)                f1_valid <= 1'b0;
  end

  // PC 高位与高位+1(供 CatPC 进位选择)
  wire [VAddrBits-1:PcCutPoint] f1_pc_high       = f1_ftq_req.startAddr[VAddrBits-1:PcCutPoint];
  wire [VAddrBits-1:PcCutPoint] f1_pc_high_plus1 = f1_pc_high + 1'b1;

  // 每条候选 PC 的低位 = startAddr 低位 + i*2（额外 1 位记进位）
  logic [PredictWidth-1:0][PcCutPoint:0] f1_pc_lower_result;
  logic [PredictWidth-1:0][PcCutPoint:0] f1_half_snpc_lower_result;
  always_comb begin
    for (int i = 0; i < PredictWidth; i++) begin
      f1_pc_lower_result[i]        = {1'b0, f1_ftq_req.startAddr[PcCutPoint-1:0]} + (i*2);
      f1_half_snpc_lower_result[i] = {1'b0, f1_ftq_req.startAddr[PcCutPoint-1:0]} + ((i+2)*2);
    end
  end

  // cut 指针：从 startAddr 的半字位置起，取 PredictWidth+1 个连续半字下标(范围在 0..3*32-1)
  logic [PredictWidth:0][6:0] f1_cut_ptr;
  always_comb
    for (int i = 0; i <= PredictWidth; i++)
      f1_cut_ptr[i] = {2'b0, f1_ftq_req.startAddr[blockOffBits-1:1]} + i;

  // ===========================================================================
  // f2：收 ICache 数据 / 切块 / 预解码 / 生成异常&范围
  // ===========================================================================
  logic     f2_valid;
  ftq_req_t f2_ftq_req;
  logic     f2_doubleLine;
  wire      f2_fire = f2_valid && f3_ready && icacheRespAllValid;
  assign f2_ready = f2_fire || !f2_valid;

  always_ff @(posedge clock) if (f1_fire) f2_ftq_req    <= f1_ftq_req;
  always_ff @(posedge clock) if (f1_fire) f2_doubleLine <= f1_doubleLine;
  always_ff @(posedge clock or posedge reset) begin
    if (reset)                     f2_valid <= 1'b0;
    else if (f2_flush)             f2_valid <= 1'b0;
    else if (f1_fire && !f1_flush) f2_valid <= 1'b1;
    else if (f2_fire)              f2_valid <= 1'b0;
  end

  // ICache 响应「全部到齐」：vaddr 与本请求 startAddr 一致，且(若 doubleline)第二行也一致
  wire f2_icache_all_resp_wire =
      icache_resp_valid &&
      (icache_resp_vaddr_0 == f2_ftq_req.startAddr) &&
      ((icache_resp_doubleline && icache_resp_vaddr_1 == f2_ftq_req.nextlineStart) || !f2_doubleLine);
  // 数据已到但 f3 未就绪 → 锁存，避免 ICache 撤走数据
  logic f2_icache_all_resp_reg;
  always_ff @(posedge clock or posedge reset) begin
    if (reset)                                                f2_icache_all_resp_reg <= 1'b0;
    else if (f2_flush)                                        f2_icache_all_resp_reg <= 1'b0;
    else if (f2_valid && f2_icache_all_resp_wire && !f3_ready) f2_icache_all_resp_reg <= 1'b1;
    else if (f2_fire && f2_icache_all_resp_reg)               f2_icache_all_resp_reg <= 1'b0;
  end
  assign icacheRespAllValid = f2_icache_all_resp_reg || f2_icache_all_resp_wire;

  assign icacheStop = !f3_ready;

  // --- f2 异常合并 ---
  // 第 0 行异常直接取 ICache 给的；第 1 行若 ICache 无异常但双行 mmio/pbmt 不一致 → 标 af
  wire [1:0] f2_exception_0 = icache_resp_exception_0;
  wire [1:0] f2_mmio_mismatch_1 =
      (!icache_resp_doubleline ||
       (icache_resp_pmp_mmio_0 == icache_resp_pmp_mmio_1 &&
        icache_resp_itlb_pbmt_0 == icache_resp_itlb_pbmt_1)) ? EXC_NONE : EXC_AF;
  wire [1:0] f2_exception_1 = exc_merge(icache_resp_exception_1, f2_mmio_mismatch_1);
  wire       f2_backendException = icache_resp_backendException;
  wire [PAddrBits-1:0]    f2_paddr_0  = icache_resp_paddr_0;
  wire [PAddrBitsMax-1:0] f2_gpaddr   = icache_resp_gpaddr;
  wire       f2_isForVSnonLeafPTE = icache_resp_isForVSnonLeafPTE;
  // 双行只需第一路的 mmio/pbmt(第二路已被要求一致)
  wire       f2_pmp_mmio  = icache_resp_pmp_mmio_0;
  wire [1:0] f2_itlb_pbmt = icache_resp_itlb_pbmt_0;

  // --- f2 PC 流水寄存(只存低位+高位，CatPC 重建省功耗) ---
  logic [PredictWidth-1:0][PcCutPoint:0]  f2_pc_lower_result;
  logic [VAddrBits-1:PcCutPoint]          f2_pc_high, f2_pc_high_plus1;
  logic [PredictWidth:0][6:0]             f2_cut_ptr;
  logic [VAddrBits-1:0]                   f2_resend_vaddr; // MMIO 跨字重发 vaddr = start+2
  always_ff @(posedge clock) if (f1_fire) begin
    f2_pc_lower_result <= f1_pc_lower_result;
    f2_pc_high         <= f1_pc_high;
    f2_pc_high_plus1   <= f1_pc_high_plus1;
    f2_cut_ptr         <= f1_cut_ptr;
    f2_resend_vaddr    <= f1_ftq_req.startAddr + 2;
  end

  logic [PredictWidth-1:0][VAddrBits-1:0] f2_pc;
  always_comb for (int i = 0; i < PredictWidth; i++)
    f2_pc[i] = catpc(f2_pc_lower_result[i], f2_pc_high, f2_pc_high_plus1);

  // foldpc(供 IBuffer 做内存依赖预测的折叠 PC)
  logic [PredictWidth-1:0][MemPredPCWidth-1:0] f2_foldpc;
  always_comb for (int i = 0; i < PredictWidth; i++)
    f2_foldpc[i] = xorfold(f2_pc[i][VAddrBits-1:1]);

  // --- 指令范围(instrRange)：本块内哪些位置属于「应取入」的指令 ---
  // jump_range：若 BPU 预测在 ftqOffset 处 taken，则 > 该偏移的位置不取
  // ftr_range  ：若未预测 taken，则按 fall-through(nextStartAddr) 截断
  function automatic logic [PredictWidth-1:0] fill_le(input logic [3:0] n);
    // 返回低 (n+1) 位为 1 的掩码 = (1<<(n+1))-1 = Fill(PW,1)>>~n
    return (~(PredictWidth'(0))) >> (~n);
  endfunction
  // getBasicBlockIdx(nextStartAddr, startAddr) = (nextStart-start-2)[log2PW:instOff]
  wire [4:0] f2_bb_byteoff = f2_ftq_req.nextStartAddr[4:0] - f2_ftq_req.startAddr[4:0] - 5'h2;
  wire [3:0] f2_bb_idx     = f2_bb_byteoff[4:1]; // instOffsetBits=1, 取 [4:1]
  wire [PredictWidth-1:0] f2_jump_range =
      f2_ftq_req.ftqOffset_valid ? fill_le(f2_ftq_req.ftqOffset_bits) : {PredictWidth{1'b1}};
  wire [PredictWidth-1:0] f2_ftr_range =
      f2_ftq_req.ftqOffset_valid ? {PredictWidth{1'b1}} : fill_le(f2_bb_idx);
  wire [PredictWidth-1:0] f2_instr_range = f2_jump_range & f2_ftr_range;

  // 每条指令的异常向量：取决于该 PC 落在第 0 行还是第 1 行
  function automatic logic is_next_line(input logic [VAddrBits-1:0] pc, input logic [VAddrBits-1:0] start);
    return start[blockOffBits] ^ pc[blockOffBits];
  endfunction
  function automatic logic is_last_in_line(input logic [VAddrBits-1:0] pc);
    return pc[blockOffBits-1:0] == 6'b111110;
  endfunction
  logic [PredictWidth-1:0][1:0] f2_exception_vec;
  always_comb for (int i = 0; i < PredictWidth; i++) begin
    if (!is_next_line(f2_pc[i], f2_ftq_req.startAddr))      f2_exception_vec[i] = f2_exception_0;
    else if (f2_doubleLine)                                 f2_exception_vec[i] = f2_exception_1;
    else                                                    f2_exception_vec[i] = EXC_NONE;
  end
  // 跨页 RVI：前页无异常但指令跨到后页时，异常实际取决于后页
  logic [PredictWidth-1:0][1:0] f2_crossPage_exception_vec;
  pd_info_t [PredictWidth-1:0] f2_pd; // 在下方由 PreDecode 黑盒驱动
  always_comb for (int i = 0; i < PredictWidth; i++)
    f2_crossPage_exception_vec[i] =
        (is_last_in_line(f2_pc[i]) && !f2_pd[i].isRVC && f2_doubleLine && !exc_has(f2_exception_0))
          ? f2_exception_1 : EXC_NONE;

  // --- 切块(cut)：从两条相邻 cacheline 拼出取指块的 17 个半字 ---
  // ICache 只回送 40B 有效数据并居中放置；IFU 把它复制首尾相接，用 cut 指针从中段取出。
  wire [1023:0] f2_data_2_cacheline = {icache_resp_data, icache_resp_data};
  logic [PredictWidth:0][15:0] f2_cut_data;
  always_comb begin
    // 视作 64 个 16-bit 半字的数组(1024/16=64)，按 cut 指针逐个取
    logic [63:0][15:0] hwords;
    hwords = f2_data_2_cacheline;
    for (int i = 0; i <= PredictWidth; i++)
      f2_cut_data[i] = hwords[f2_cut_ptr[i][5:0]];
  end

  // ===========================================================================
  // 子模块：PreDecode（黑盒，golden 同名）——预解码取指半字流
  // 产出每位置的 pd(valid/isRVC/brType/isCall/isRet)、instr(对齐 32 位)、
  // jumpOffset、hasHalfValid(跨包匹配用)
  // ===========================================================================
  logic [PredictWidth-1:0][31:0] f2_instr;
  logic [PredictWidth-1:0][63:0] f2_jump_offset;
  logic [PredictWidth-1:0]       f2_hasHalfValid; // 注：golden 只引出 [2..15]，0/1 恒 0
  xs_newifu_predecode u_predecode (
    .clock(clock), .reset(reset),
    .in_valid(f2_valid),
    .in_data (f2_cut_data),
    // FrontendTrigger 配置(PreDecode 内部不再使用，golden 已裁剪，留接口形)
    .pc      (f2_pc),
    .out_pd        (f2_pd),
    .out_instr     (f2_instr),
    .out_jumpOffset(f2_jump_offset),
    .out_hasHalfValid(f2_hasHalfValid)
  );

  // ===========================================================================
  // f3：RVC 展开 / 预测检查 / MMIO / 送 IBuffer
  // ===========================================================================
  logic     f3_valid;
  ftq_req_t f3_ftq_req;
  logic     f3_doubleLine;
  wire      f3_fire = ibuffer_valid && ibuffer_ready;

  logic [PredictWidth:0][15:0]   f3_cut_data;
  logic [1:0]                    f3_exception_0, f3_exception_1;
  logic                          f3_pmp_mmio;
  logic [1:0]                    f3_itlb_pbmt;
  logic                          f3_backendException;
  logic [PredictWidth-1:0][31:0] f3_instr;
  pd_info_t [PredictWidth-1:0]   f3_pd_wire;      // 来自 PreDecode 的原始 pd
  logic [PredictWidth-1:0][63:0] f3_jump_offset;
  logic [PredictWidth-1:0][1:0]  f3_exception_vec;
  logic [PredictWidth-1:0][1:0]  f3_crossPage_exception_vec;
  logic [PredictWidth-1:0][PcCutPoint:0] f3_pc_lower_result;
  logic [VAddrBits-1:PcCutPoint] f3_pc_high, f3_pc_high_plus1;
  logic [PcCutPoint:0]           f3_pc_last_lower_plus2, f3_pc_last_lower_plus4;
  logic [PredictWidth-1:0]       f3_instr_range;
  logic [PredictWidth-1:0][MemPredPCWidth-1:0] f3_foldpc;
  logic [PredictWidth-1:0]       f3_hasHalfValid;
  logic [PAddrBits-1:0]          f3_paddr_0;
  logic [PAddrBitsMax-1:0]       f3_gpaddr;
  logic                          f3_isForVSnonLeafPTE;
  logic [VAddrBits-1:0]          f3_resend_vaddr;

  always_ff @(posedge clock) if (f2_fire) f3_ftq_req    <= f2_ftq_req;
  always_ff @(posedge clock) if (f2_fire) f3_doubleLine <= f2_doubleLine;
  always_ff @(posedge clock) if (f2_fire) begin
    f3_cut_data                <= f2_cut_data;
    f3_exception_0             <= f2_exception_0;
    f3_exception_1             <= f2_exception_1;
    f3_pmp_mmio                <= f2_pmp_mmio;
    f3_itlb_pbmt               <= f2_itlb_pbmt;
    f3_backendException        <= f2_backendException;
    f3_instr                   <= f2_instr;
    f3_pd_wire                 <= f2_pd;
    f3_jump_offset             <= f2_jump_offset;
    f3_exception_vec           <= f2_exception_vec;
    f3_crossPage_exception_vec <= f2_crossPage_exception_vec;
    f3_pc_lower_result         <= f2_pc_lower_result;
    f3_pc_high                 <= f2_pc_high;
    f3_pc_high_plus1           <= f2_pc_high_plus1;
    f3_pc_last_lower_plus2     <= f2_pc_lower_result[PredictWidth-1] + 2;
    f3_pc_last_lower_plus4     <= f2_pc_lower_result[PredictWidth-1] + 4;
    f3_instr_range             <= f2_instr_range;
    f3_foldpc                  <= f2_foldpc;
    f3_hasHalfValid            <= f2_hasHalfValid;
    f3_paddr_0                 <= f2_paddr_0;
    f3_gpaddr                  <= f2_gpaddr;
    f3_isForVSnonLeafPTE       <= f2_isForVSnonLeafPTE;
    f3_resend_vaddr            <= f2_resend_vaddr;
  end

  // f3 PC 重建
  logic [PredictWidth-1:0][VAddrBits-1:0] f3_pc;
  always_comb for (int i = 0; i < PredictWidth; i++)
    f3_pc[i] = catpc(f3_pc_lower_result[i], f3_pc_high, f3_pc_high_plus1);

  // half_snpc(i)：比 pc(i) 大 4(即 pc(i+2))；末两条用专门寄存的 +2/+4
  logic [PredictWidth-1:0][VAddrBits-1:0] f3_half_snpc;
  always_comb for (int i = 0; i < PredictWidth; i++) begin
    if (i == PredictWidth-2)      f3_half_snpc[i] = catpc(f3_pc_last_lower_plus2, f3_pc_high, f3_pc_high_plus1);
    else if (i == PredictWidth-1) f3_half_snpc[i] = catpc(f3_pc_last_lower_plus4, f3_pc_high, f3_pc_high_plus1);
    else                          f3_half_snpc[i] = f3_pc[i+2];
  end

  // --- RVC 展开器 ×16(黑盒 golden RVCExpander) ---
  logic [PredictWidth-1:0][31:0] f3_expd_instr; // 合法则用展开结果，否则保留原非法 RVC
  logic [PredictWidth-1:0]       f3_ill;
  genvar gi;
  generate
    for (gi = 0; gi < PredictWidth; gi++) begin : g_expand
      wire [31:0] exp_out;
      wire        exp_ill;
      xs_newifu_rvcexpander u_exp (
        .io_in     (f3_instr[gi]),
        .io_fsIsOff(csr_fsIsOff),
        .io_out_bits(exp_out),
        .io_ill    (exp_ill)
      );
      assign f3_expd_instr[gi] = exp_ill ? f3_instr[gi] : exp_out;
      assign f3_ill[gi]        = exp_ill;
    end
  endgenerate

  // --- F3Predecoder(黑盒)：把 brType/isCall/isRet 的产生延后到 f3，覆盖 f3_pd_wire ---
  logic [PredictWidth-1:0][1:0] f3pd_brType;
  logic [PredictWidth-1:0]      f3pd_isCall, f3pd_isRet;
  xs_newifu_f3predecoder u_f3pd (
    .instr  (f3_instr),
    .brType (f3pd_brType),
    .isCall (f3pd_isCall),
    .isRet  (f3pd_isRet)
  );
  pd_info_t [PredictWidth-1:0] f3_pd;
  always_comb for (int i = 0; i < PredictWidth; i++) begin
    f3_pd[i].valid  = f3_pd_wire[i].valid;
    f3_pd[i].isRVC  = f3_pd_wire[i].isRVC;
    f3_pd[i].brType = f3pd_brType[i];
    f3_pd[i].isCall = f3pd_isCall[i];
    f3_pd[i].isRet  = f3pd_isRet[i];
  end

  // ===========================================================================
  // MMIO 取指状态机
  // ===========================================================================
  logic [1:0]  mmio_exception;
  logic        mmio_is_RVC;
  logic        mmio_has_resend;
  logic [PAddrBits-1:0]    mmio_resend_addr;
  logic [PAddrBitsMax-1:0] mmio_resend_gpaddr;
  logic        mmio_resend_isForVSnonLeafPTE;
  logic        is_first_instr;          // 是否系统启动后第一条指令
  mmio_state_e mmio_state;
  // MMIO 取回的两个 16-bit 半字(对应 Chisel f3_mmio_data(0)/(1))
  logic [15:0] mmio_hw0, mmio_hw1;

  // 是否为 MMIO 请求：地址 uncacheable 且无异常
  wire f3_req_is_mmio =
      f3_valid && (f3_pmp_mmio || pbmt_is_uncache(f3_itlb_pbmt)) && !exc_has(exc_merge(f3_exception_0, f3_exception_1));

  // RoB 是否提交了本块(offset=0)的 MMIO 指令
  logic mmio_commit;
  always_comb begin
    mmio_commit = 1'b0;
    mmio_commit |= rob_commit_valid[0] && (rob_commit_0_ftqIdx_flag==f3_ftq_req.ftqIdx_flag) && (rob_commit_0_ftqIdx_value==f3_ftq_req.ftqIdx_value) && (rob_commit_0_ftqOffset==4'h0);
    mmio_commit |= rob_commit_valid[1] && (rob_commit_1_ftqIdx_flag==f3_ftq_req.ftqIdx_flag) && (rob_commit_1_ftqIdx_value==f3_ftq_req.ftqIdx_value) && (rob_commit_1_ftqOffset==4'h0);
    mmio_commit |= rob_commit_valid[2] && (rob_commit_2_ftqIdx_flag==f3_ftq_req.ftqIdx_flag) && (rob_commit_2_ftqIdx_value==f3_ftq_req.ftqIdx_value) && (rob_commit_2_ftqOffset==4'h0);
    mmio_commit |= rob_commit_valid[3] && (rob_commit_3_ftqIdx_flag==f3_ftq_req.ftqIdx_flag) && (rob_commit_3_ftqIdx_value==f3_ftq_req.ftqIdx_value) && (rob_commit_3_ftqOffset==4'h0);
    mmio_commit |= rob_commit_valid[4] && (rob_commit_4_ftqIdx_flag==f3_ftq_req.ftqIdx_flag) && (rob_commit_4_ftqIdx_value==f3_ftq_req.ftqIdx_value) && (rob_commit_4_ftqOffset==4'h0);
    mmio_commit |= rob_commit_valid[5] && (rob_commit_5_ftqIdx_flag==f3_ftq_req.ftqIdx_flag) && (rob_commit_5_ftqIdx_value==f3_ftq_req.ftqIdx_value) && (rob_commit_5_ftqOffset==4'h0);
    mmio_commit |= rob_commit_valid[6] && (rob_commit_6_ftqIdx_flag==f3_ftq_req.ftqIdx_flag) && (rob_commit_6_ftqIdx_value==f3_ftq_req.ftqIdx_value) && (rob_commit_6_ftqOffset==4'h0);
    mmio_commit |= rob_commit_valid[7] && (rob_commit_7_ftqIdx_flag==f3_ftq_req.ftqIdx_flag) && (rob_commit_7_ftqIdx_value==f3_ftq_req.ftqIdx_value) && (rob_commit_7_ftqOffset==4'h0);
  end

  wire f3_mmio_req_commit = f3_req_is_mmio && (mmio_state == M_COMMITED);
  wire f3_mmio_to_commit  = f3_req_is_mmio && (mmio_state == M_WAIT_COMMIT);
  logic f3_mmio_to_commit_next;
  always_ff @(posedge clock or posedge reset)
    if (reset) f3_mmio_to_commit_next <= 1'b0; else f3_mmio_to_commit_next <= f3_mmio_to_commit;
  wire f3_mmio_can_go = f3_mmio_to_commit && !f3_mmio_to_commit_next;

  // 后端 redirect 寄存一拍(MMIO 判断要用上一拍的 redirect)
  logic                 fromFtqRedirectReg_valid;
  logic                 redirReg_ftqIdx_flag, redirReg_level;
  logic [5:0]           redirReg_ftqIdx_value;
  logic [3:0]           redirReg_ftqOffset;
  always_ff @(posedge clock or posedge reset) begin
    if (reset) fromFtqRedirectReg_valid <= 1'b0;
    else       fromFtqRedirectReg_valid <= ftq_redirect_valid;
  end
  always_ff @(posedge clock) if (ftq_redirect_valid) begin
    redirReg_ftqIdx_flag  <= ftq_redirect_ftqIdx_flag;
    redirReg_ftqIdx_value <= ftq_redirect_ftqIdx_value;
    redirReg_ftqOffset    <= ftq_redirect_ftqOffset;
    redirReg_level        <= ftq_redirect_level;
  end

  logic mmioF3Flush;
  always_ff @(posedge clock or posedge reset)
    if (reset) mmioF3Flush <= 1'b0; else mmioF3Flush <= f3_flush;

  // 环形比较：a 早于 b
  function automatic logic ftqidx_before(input logic af, input logic [5:0] av, input logic bf, input logic [5:0] bv);
    return (af ^ bf) ? (av > bv) : (av < bv);
  endfunction
  wire f3_ftq_flush_self     = fromFtqRedirectReg_valid && redirReg_level; // flushItself
  wire f3_ftq_flush_by_older = fromFtqRedirectReg_valid &&
        ftqidx_before(redirReg_ftqIdx_flag, redirReg_ftqIdx_value, f3_ftq_req.ftqIdx_flag, f3_ftq_req.ftqIdx_value);
  wire f3_need_not_flush = f3_req_is_mmio && fromFtqRedirectReg_valid && !f3_ftq_flush_self && !f3_ftq_flush_by_older;

  // (is_first_instr 的复位/清零集中在下方 MMIO 状态机 always_ff 内，避免多驱动)

  // mmioFtqPtr = RegNext(f3_ftq_req.ftqIdx - 1)
  logic       mmioFtqPtr_flag_r;
  logic [5:0] mmioFtqPtr_value_r;
  always_ff @(posedge clock) begin
    {mmioFtqPtr_flag_r, mmioFtqPtr_value_r} <= {f3_ftq_req.ftqIdx_flag, f3_ftq_req.ftqIdx_value} - 7'h1;
  end
  assign mmioCommitRead_mmioFtqPtr_flag  = mmioFtqPtr_flag_r;
  assign mmioCommitRead_mmioFtqPtr_value = mmioFtqPtr_value_r;

  // f3_valid 更新(MMIO 会让其驻留直到提交)
  always_ff @(posedge clock or posedge reset) begin
    if (reset)                                                          f3_valid <= 1'b0;
    else if (f3_flush && !f3_req_is_mmio)                               f3_valid <= 1'b0;
    else if (mmioF3Flush && f3_req_is_mmio && !f3_need_not_flush)       f3_valid <= 1'b0;
    else if (f2_fire && !f2_flush)                                      f3_valid <= 1'b1;
    else if (f3_fire && !f3_req_is_mmio)                                f3_valid <= 1'b0;
    else if (f3_req_is_mmio && f3_mmio_req_commit)                      f3_valid <= 1'b0;
  end

  // f3_mmio_use_seq_pc：MMIO redirect 用顺序 PC(start+2/+4)
  logic f3_mmio_use_seq_pc;
  logic f2_fire_no_flush_q; // RegNext(f2_fire && !f2_flush)
  always_ff @(posedge clock or posedge reset)
    if (reset) f2_fire_no_flush_q <= 1'b0; else f2_fire_no_flush_q <= (f2_fire && !f2_flush);
  wire redirect_mmio_req = fromFtqRedirectReg_valid &&
        (redirReg_ftqIdx_flag==f3_ftq_req.ftqIdx_flag) && (redirReg_ftqIdx_value==f3_ftq_req.ftqIdx_value) &&
        (redirReg_ftqOffset==4'h0);
  always_ff @(posedge clock or posedge reset) begin
    if (reset)                                  f3_mmio_use_seq_pc <= 1'b0;
    else if (f2_fire_no_flush_q && f3_req_is_mmio) f3_mmio_use_seq_pc <= 1'b1;
    else if (redirect_mmio_req)                 f3_mmio_use_seq_pc <= 1'b0;
  end

  assign f3_ready = (ibuffer_ready && (f3_mmio_req_commit || !f3_req_is_mmio)) || !f3_valid;

  // MMIO 是否需要跨字重发(非 RVC 且地址落在字尾 paddr[2:1]==3 且无异常)
  wire fromUncache_fire = uncache_resp_valid; // fromUncache.ready 恒 1
  wire mmio_needResend = (&uncache_resp_data[1:0]) && (&f3_paddr_0[2:1]) && !uncache_resp_corrupt;
  // 重发后 tlb 异常构造
  wire [1:0] mmio_tlb_exception = itlb_resp_pf_instr ? EXC_PF :
                                  itlb_resp_gpf_instr ? EXC_GPF :
                                  {2{itlb_resp_af_instr}};
  wire [1:0] mmio_tlb_full_exc = (|mmio_tlb_exception) ? mmio_tlb_exception :
                                 ((itlb_resp_pbmt_0 == f3_itlb_pbmt) ? EXC_NONE : EXC_AF);
  wire [1:0] mmio_pmp_exception = pmp_resp_instr ? {2{pmp_resp_instr}} :
                                  ((pmp_resp_mmio == f3_pmp_mmio) ? EXC_NONE : EXC_AF);

  // --- MMIO 状态机时序 ---
  always_ff @(posedge clock or posedge reset) begin
    if (reset) begin
      mmio_state <= M_IDLE;
      mmio_exception <= EXC_NONE; mmio_is_RVC <= 1'b0; mmio_has_resend <= 1'b0;
      mmio_resend_addr <= '0; mmio_resend_gpaddr <= '0; mmio_resend_isForVSnonLeafPTE <= 1'b0;
      mmio_hw0 <= '0; mmio_hw1 <= '0;
      is_first_instr <= 1'b1;
    end else begin
      unique case (mmio_state)
        M_IDLE: if (f3_req_is_mmio)
                  mmio_state <= (f3_itlb_pbmt == PBMT_NC) ? M_SEND_REQ : M_WAIT_LAST_CMT;
        M_WAIT_LAST_CMT: mmio_state <= is_first_instr ? M_SEND_REQ :
                                       (mmioCommitRead_mmioLastCommit ? M_SEND_REQ : M_WAIT_LAST_CMT);
        M_SEND_REQ: if (uncache_req_valid && uncache_req_ready) mmio_state <= M_WAIT_RESP;
        M_WAIT_RESP: if (fromUncache_fire) begin
                       mmio_state      <= mmio_needResend ? M_SEND_TLB : M_WAIT_COMMIT;
                       mmio_exception  <= {2{uncache_resp_corrupt}};
                       mmio_is_RVC     <= (uncache_resp_data[1:0] != 2'b11);
                       mmio_has_resend <= mmio_needResend;
                       mmio_hw0        <= uncache_resp_data[15:0];
                       mmio_hw1        <= uncache_resp_data[31:16];
                     end
        M_SEND_TLB: if (itlb_req_valid && itlb_req_ready) mmio_state <= M_TLB_RESP;
        M_TLB_RESP: if (itlb_resp_valid && itlb_resp_ready) begin
                      mmio_state <= exc_has(mmio_tlb_full_exc) ? M_WAIT_COMMIT : M_SEND_PMP;
                      mmio_exception   <= mmio_tlb_full_exc;
                      mmio_resend_addr <= itlb_resp_paddr_0;
                      mmio_resend_gpaddr <= itlb_resp_gpaddr_0[PAddrBitsMax-1:0];
                      mmio_resend_isForVSnonLeafPTE <= itlb_resp_isForVSnonLeafPTE;
                    end
        M_SEND_PMP: begin
                      mmio_state     <= exc_has(mmio_pmp_exception) ? M_WAIT_COMMIT : M_RESEND_REQ;
                      mmio_exception <= mmio_pmp_exception;
                    end
        M_RESEND_REQ: if (uncache_req_valid && uncache_req_ready) mmio_state <= M_WAIT_RESEND;
        M_WAIT_RESEND: if (fromUncache_fire) begin
                         mmio_state     <= M_WAIT_COMMIT;
                         mmio_exception <= {2{uncache_resp_corrupt}};
                         mmio_hw1       <= uncache_resp_data[15:0];
                       end
        M_WAIT_COMMIT: if (mmio_commit || (f3_itlb_pbmt == PBMT_NC)) mmio_state <= M_COMMITED;
        M_COMMITED: begin
                      mmio_state <= M_IDLE;
                      mmio_exception <= EXC_NONE; mmio_is_RVC <= 1'b0; mmio_has_resend <= 1'b0;
                      mmio_resend_addr <= '0; mmio_resend_gpaddr <= '0; mmio_resend_isForVSnonLeafPTE <= 1'b0;
                    end
        default: mmio_state <= M_IDLE;
      endcase

      // 后端 redirect 冲刷自身或被更早分支冲刷：MMIO 复位(优先级最高，覆盖上面)
      if (f3_ftq_flush_self || f3_ftq_flush_by_older) begin
        mmio_state <= M_IDLE;
        mmio_exception <= EXC_NONE; mmio_is_RVC <= 1'b0; mmio_has_resend <= 1'b0;
        mmio_resend_addr <= '0; mmio_resend_gpaddr <= '0; mmio_resend_isForVSnonLeafPTE <= 1'b0;
        mmio_hw0 <= '0; mmio_hw1 <= '0;
      end

      if (is_first_instr && f3_fire) is_first_instr <= 1'b0;
    end
  end

  wire [15:0] mmio_inst = {mmio_hw1, mmio_hw0};

  // MMIO 对外请求
  assign uncache_req_valid = ((mmio_state == M_SEND_REQ) || (mmio_state == M_RESEND_REQ)) && f3_req_is_mmio;
  assign uncache_req_addr  = (mmio_state == M_RESEND_REQ) ? mmio_resend_addr : f3_paddr_0;
  assign itlb_req_valid    = (mmio_state == M_SEND_TLB) && f3_req_is_mmio;
  assign itlb_req_vaddr    = f3_resend_vaddr;
  assign itlb_resp_ready   = (mmio_state == M_TLB_RESP) && f3_req_is_mmio;
  assign pmp_req_addr      = mmio_resend_addr;

  // ===========================================================================
  // last half（跨包半条 RVI）处理
  // ===========================================================================
  logic        f3_lastHalf_valid;
  logic [VAddrBits-1:0] f3_lastHalf_middlePC;
  logic        f3_lastHalf_disable;
  logic [PredictWidth-1:0] f3_instr_valid;

  // 预测检查器(PredChecker，黑盒)输入：第 0 位 instrValid 用 ~f3_lastHalf_valid
  logic [PredictWidth-1:0] checker_in_instrValid;
  always_comb begin
    checker_in_instrValid    = f3_instr_valid;
    checker_in_instrValid[0] = ~f3_lastHalf_valid;
  end
  logic [PredictWidth-1:0]            chk_fixedRange, chk_fixedTaken, chk_fixedMissPred;
  logic [PredictWidth-1:0][VAddrBits-1:0] chk_fixedTarget, chk_jalTarget;
  logic [PredictWidth-1:0][2:0]      chk_faultType;
  logic                              predChecker_fire_in_reg;
  always_ff @(posedge clock or posedge reset)
    if (reset) predChecker_fire_in_reg <= 1'b0; else predChecker_fire_in_reg <= f2_fire;

  // PredChecker 输入 pds：isRVC 用 f3_pd_wire，brType/isRet 用 f3Predecoder 输出
  pd_info_t [PredictWidth-1:0] chk_in_pds;
  always_comb for (int i = 0; i < PredictWidth; i++) begin
    chk_in_pds[i].valid  = 1'b0;
    chk_in_pds[i].isRVC  = f3_pd_wire[i].isRVC;
    chk_in_pds[i].brType = f3pd_brType[i];
    chk_in_pds[i].isCall = 1'b0;
    chk_in_pds[i].isRet  = f3pd_isRet[i];
  end

  xs_newifu_predchecker u_predchecker (
    .clock(clock),
    .ftqOffset_valid(f3_ftq_req.ftqOffset_valid),
    .ftqOffset_bits (f3_ftq_req.ftqOffset_bits),
    .jumpOffset (f3_jump_offset),
    .target     (f3_ftq_req.nextStartAddr),
    .instrRange (f3_instr_range),
    .instrValid (checker_in_instrValid),
    .pds        (chk_in_pds),
    .pc         (f3_pc),
    .fire_in    (predChecker_fire_in_reg),
    .fixedRange (chk_fixedRange),
    .fixedTaken (chk_fixedTaken),
    .fixedTarget(chk_fixedTarget),
    .jalTarget  (chk_jalTarget),
    .fixedMissPred(chk_fixedMissPred),
    .faultType  (chk_faultType)
  );

  // hasLastHalf：该位置是非 RVC、在范围内、有效、未 taken、非 MMIO → 是跨包前半。
  // 纯函数(只读入参,不读非局部信号——否则 FM 读入触 FMR_VLOG-091 致 impl 建模失败)。
  function automatic logic has_last_half(input logic isRVC, fixedRange, instr_valid,
                                                fixedTaken, is_mmio);
    return !isRVC && fixedRange && instr_valid && !fixedTaken && !is_mmio;
  endfunction
  // 范围内最后一个有效位置(后向优先编码)
  logic [3:0] f3_last_validIdx;
  always_comb begin
    f3_last_validIdx = '0;
    for (int i = 0; i < PredictWidth; i++) if (chk_fixedRange[i]) f3_last_validIdx = i[3:0];
  end
  wire f3_hasLastHalf    = has_last_half(f3_pd[PredictWidth-1].isRVC, chk_fixedRange[PredictWidth-1],
                             f3_instr_valid[PredictWidth-1], chk_fixedTaken[PredictWidth-1], f3_req_is_mmio);
  wire f3_false_lastHalf = has_last_half(f3_pd[f3_last_validIdx].isRVC, chk_fixedRange[f3_last_validIdx],
                             f3_instr_valid[f3_last_validIdx], chk_fixedTaken[f3_last_validIdx], f3_req_is_mmio);
  wire [VAddrBits-1:0] f3_false_snpc = f3_half_snpc[f3_last_validIdx];

  wire [PredictWidth-1:0] f3_lastHalf_mask = ~(PredictWidth'(1)); // 除 bit0 外全 1
  wire [PredictWidth-1:0] f3_mmio_range = PredictWidth'(1);        // MMIO 只第 0 条有效

  // wb 阶段会改 f3_lastHalf_disable / f3_lastHalf.valid（见 wb 节）；这里集中其时序
  logic wb_set_lastHalf_disable;
  logic wb_clear_lastHalf_valid;

  always_ff @(posedge clock or posedge reset) begin
    if (reset) f3_lastHalf_disable <= 1'b0;
    else if (f3_flush || (f3_fire && f3_lastHalf_disable)) f3_lastHalf_disable <= 1'b0;
    else if (wb_set_lastHalf_disable)                      f3_lastHalf_disable <= 1'b1;
  end
  always_ff @(posedge clock or posedge reset) begin
    if (reset)             f3_lastHalf_valid <= 1'b0;
    else if (f3_flush)     f3_lastHalf_valid <= 1'b0;
    else if (f3_fire)      f3_lastHalf_valid <= f3_hasLastHalf && !f3_lastHalf_disable;
    else if (wb_clear_lastHalf_valid) f3_lastHalf_valid <= 1'b0;
  end
  always_ff @(posedge clock) if (f3_fire) f3_lastHalf_middlePC <= f3_ftq_req.nextStartAddr;

  // pd.valid 向量
  logic [PredictWidth-1:0] f3_pd_valid_vec;
  always_comb for (int i = 0; i < PredictWidth; i++) f3_pd_valid_vec[i] = f3_pd[i].valid;

  // f3_instr_valid：有 lastHalf 时用 hasHalfValid，否则用 pd.valid
  always_comb
    f3_instr_valid = f3_lastHalf_valid ? f3_hasHalfValid : f3_pd_valid_vec;

  // ===========================================================================
  // FrontendTrigger（黑盒）：逐指令断点触发
  // ===========================================================================
  logic [PredictWidth-1:0][3:0] f3_triggered;
  xs_newifu_frontendtrigger u_fronttrig (
    .clock(clock), .reset(reset),
    .tUpdate_valid(ft_tUpdate_valid), .tUpdate_addr(ft_tUpdate_addr),
    .tUpdate_matchType(ft_tUpdate_matchType), .tUpdate_select(ft_tUpdate_select),
    .tUpdate_action(ft_tUpdate_action), .tUpdate_chain(ft_tUpdate_chain),
    .tUpdate_tdata2(ft_tUpdate_tdata2),
    .tEnableVec(ft_tEnableVec), .debugMode(ft_debugMode),
    .triggerCanRaiseBpExp(ft_triggerCanRaiseBpExp),
    .pc(f3_pc),
    .triggered(f3_triggered)
  );

  // ===========================================================================
  // 送 IBuffer
  // ===========================================================================
  wire f3_toIbuffer_valid = f3_valid && (!f3_req_is_mmio || f3_mmio_can_go) && !f3_flush;
  assign ibuffer_valid = f3_toIbuffer_valid;

  // enqEnable / valid_vec：基础值，再被 lastHalf / mmio 覆写
  wire [PredictWidth-1:0] enq_base   = chk_fixedRange & f3_instr_valid;
  logic [PredictWidth-1:0] enqEnable_w, valid_vec_w;
  always_comb begin
    enqEnable_w = enq_base;
    valid_vec_w = f3_instr_valid;
    if (f3_lastHalf_valid) begin
      enqEnable_w = chk_fixedRange & f3_instr_valid & f3_lastHalf_mask;
      valid_vec_w = f3_lastHalf_mask & f3_instr_valid;
    end
    if (f3_req_is_mmio) begin
      enqEnable_w = f3_mmio_range;
    end
    // bit0 与 golden 完全一致：io.toIbuffer.bits.valid[0] 恒为 ~f3_lastHalf_valid
    // （golden 把第 0 位硬接 ~f3_lastHalf_valid，不依赖 f3_pd[0].valid 寄存器；
    //  否则流水空闲/初值态下读到未更新的 f3_pd_wire 寄存器，与 golden 的组合常量分歧。
    //  功能流动时 f3_pd[0].valid 恒被置 1，二者一致；此处仅消除空闲/初值态分歧。）
    valid_vec_w[0] = ~f3_lastHalf_valid;
  end
  assign ibuffer_enqEnable = enqEnable_w;
  assign ibuffer_valid_vec = valid_vec_w;

  // MMIO 外部预解码(覆盖第 0 条)
  wire [1:0] mmio_brType = xs_predecode_pkg::xs_br_type({16'b0, mmio_inst});
  wire       mmio_isCall = xs_predecode_pkg::xs_is_call({16'b0, mmio_inst});
  wire       mmio_isRet  = xs_predecode_pkg::xs_is_ret({16'b0, mmio_inst});

  // MMIO RVC 展开器(黑盒)
  wire [31:0] mmioExp_out;
  wire        mmioExp_ill;
  xs_newifu_rvcexpander u_mmio_exp (
    .io_in     (f3_req_is_mmio ? {16'b0, mmio_inst} : 32'b0),
    .io_fsIsOff(csr_fsIsOff),
    .io_out_bits(mmioExp_out),
    .io_ill    (mmioExp_ill)
  );

  // instrs：正常用 f3_expd_instr；MMIO 时第 0 条用 MMIO 展开结果
  logic [PredictWidth-1:0][31:0] ibuf_instrs_w;
  always_comb begin
    ibuf_instrs_w = f3_expd_instr;
    if (f3_req_is_mmio)
      ibuf_instrs_w[0] = mmioExp_ill ? {16'b0, mmio_inst} : mmioExp_out;
  end
  assign ibuffer_instrs = ibuf_instrs_w;

  // pd：正常用 f3_pd；MMIO 时第 0 条用 MMIO 译码
  pd_info_t [PredictWidth-1:0] ibuf_pd_w;
  always_comb begin
    ibuf_pd_w = f3_pd;
    if (f3_req_is_mmio) begin
      ibuf_pd_w[0].valid  = 1'b1;
      ibuf_pd_w[0].isRVC  = mmio_is_RVC;
      ibuf_pd_w[0].brType = mmio_brType;
      ibuf_pd_w[0].isCall = mmio_isCall;
      ibuf_pd_w[0].isRet  = mmio_isRet;
    end
  end
  assign ibuffer_pd = ibuf_pd_w;

  assign ibuffer_ftqPtr_flag  = f3_ftq_req.ftqIdx_flag;
  assign ibuffer_ftqPtr_value = f3_ftq_req.ftqIdx_value;
  assign ibuffer_pc           = f3_pc;
  assign ibuffer_foldpc       = f3_foldpc;

  // isLastInFtqEntry = enqEnable 的最高有效位 one-hot
  logic [PredictWidth-1:0] last_in_ftq;
  always_comb begin
    last_in_ftq = '0;
    for (int i = PredictWidth-1; i >= 0; i--)
      if (enqEnable_w[i]) begin last_in_ftq[i] = 1'b1; break; end
  end
  assign ibuffer_isLastInFtqEntry = last_in_ftq;

  // ftqOffset.valid = fixedTaken && !mmio
  logic [PredictWidth-1:0] ftqOffset_valid_w;
  always_comb for (int i = 0; i < PredictWidth; i++)
    ftqOffset_valid_w[i] = chk_fixedTaken[i] && !f3_req_is_mmio;
  assign ibuffer_ftqOffset_valid = ftqOffset_valid_w;

  // exceptionType：合并普通异常 + 跨页异常；MMIO 时第 0 条用 mmio_exception
  logic [PredictWidth-1:0][1:0] exctype_w;
  logic [PredictWidth-1:0]      crosspage_w;
  always_comb for (int i = 0; i < PredictWidth; i++) begin
    exctype_w[i]   = exc_merge(f3_exception_vec[i], f3_crossPage_exception_vec[i]);
    crosspage_w[i] = exc_has(f3_crossPage_exception_vec[i]);
  end
  // backendException 只第 0 条需要
  logic [PredictWidth-1:0] backendExc_w;
  always_comb begin
    backendExc_w = '0;
    backendExc_w[0] = f3_backendException;
  end
  // illegalInstr
  logic [PredictWidth-1:0] illegal_w;
  always_comb illegal_w = f3_ill;

  // MMIO 覆盖第 0 条的 exception / crossPage / illegal
  logic [PredictWidth-1:0][1:0] exctype_final;
  logic [PredictWidth-1:0]      crosspage_final, illegal_final;
  always_comb begin
    exctype_final   = exctype_w;
    crosspage_final = crosspage_w;
    illegal_final   = illegal_w;
    if (f3_req_is_mmio) begin
      exctype_final[0]   = mmio_exception;
      crosspage_final[0] = mmio_has_resend && exc_has(mmio_exception);
      illegal_final[0]   = mmioExp_ill;
    end
  end
  assign ibuffer_exceptionType    = exctype_final;
  assign ibuffer_crossPageIPFFix  = crosspage_final;
  assign ibuffer_illegalInstr     = illegal_final;
  assign ibuffer_backendException = backendExc_w;
  assign ibuffer_triggered        = f3_triggered;

  // ---------------------------------------------------------------------------
  // topdown 气泡原因（top-down 性能分析）
  //
  // 取指请求带着 BPU/FTQ 阶段判定的"气泡原因"向量(reasons[37:0])进入流水；IFU 把它随
  // 流水移位 3 级(对应 numOfStage)，并在途中按本级发生的事件叠加额外原因位：
  //   · stage1：ICache miss → bit10(ICacheMissBubble)；iTLB miss → bit11(ITLBMissBubble)
  //   · 所有级 & 输出：后端 topdown_redirect 按其类型(Ctrl/MemVio/Other + cfiUpdate 命中)
  //     分类，叠加 TAGE/SC/ITTAGE/RAS/MemVio/Other/BTBMiss 等原因位
  //   · 写回 redirect(wb_redirect) → BTBMissBubble(bit12)
  // 原因位编号见 xiangshan.TopDownCounters：
  //   3 TAGEMiss, 4 SCMiss, 5 ITTAGEMiss, 6 RASMiss, 7 MemVioRedirect, 8 OtherRedirect,
  //   10 ICacheMiss, 11 ITLBMiss, 12 BTBMiss
  // ---------------------------------------------------------------------------
  localparam int R_TAGE=3, R_SC=4, R_ITTAGE=5, R_RAS=6, R_MEMVIO=7, R_OTHER=8,
                 R_ICACHE=10, R_ITLB=11, R_BTB=12;

  // topdown_redirect 分类(组合)：把一次后端 redirect 归到唯一一个气泡原因
  wire td_ctrl   = ftq_topdown_redirect_valid && ftq_topdown_redirect_debugIsCtrl;
  // Ctrl 类下按 cfiUpdate 命中情况细分到 BTB/TAGE/SC/ITTAGE/RAS
  wire td_isBTB  = ftq_topdown_redirect_debugIsCtrl && !ftq_topdown_redirect_cfi_br_hit && !ftq_topdown_redirect_cfi_jr_hit; // → bit12
  wire td_brhit  = ftq_topdown_redirect_debugIsCtrl &&  ftq_topdown_redirect_cfi_br_hit;
  wire td_isTAGE = td_brhit && !ftq_topdown_redirect_cfi_sc_hit;  // → bit3
  wire td_isSC   = td_brhit &&  ftq_topdown_redirect_cfi_sc_hit;  // → bit4
  wire td_jrhit  = ftq_topdown_redirect_debugIsCtrl &&  ftq_topdown_redirect_cfi_jr_hit;
  wire td_isITT  = td_jrhit && !ftq_topdown_redirect_cfi_pd_isRet; // → bit5
  wire td_isRAS  = !td_isBTB && !td_isTAGE && !td_isSC && td_jrhit && ftq_topdown_redirect_cfi_pd_isRet; // → bit6
  // 优先级链(与 golden 等价)：set_tage > set_sc > set_itt > set_ras（互斥后再取唯一）
  wire set_tage   = td_ctrl && !td_isBTB && td_isTAGE;
  wire set_sc     = td_ctrl && !(td_isBTB || td_isTAGE) && td_isSC;
  wire set_ittage = td_ctrl && !(td_isBTB || td_isTAGE || td_isSC) && td_isITT;
  wire set_ras    = td_ctrl && !(td_isBTB || td_isTAGE || td_isSC || td_isITT) && td_jrhit && ftq_topdown_redirect_cfi_pd_isRet;
  wire set_memvio = ftq_topdown_redirect_valid && !ftq_topdown_redirect_debugIsCtrl && ftq_topdown_redirect_debugIsMemVio;
  wire set_other  = ftq_topdown_redirect_valid && !(ftq_topdown_redirect_debugIsCtrl || ftq_topdown_redirect_debugIsMemVio);
  wire set_btb    = td_ctrl && td_isBTB; // ControlBTBMissBubble

  // 3 级流水寄存(每位独立移位 + 事件叠加)
  logic [37:0] td_stage0, td_stage1, td_stage2;
  always_ff @(posedge clock or posedge reset) begin
    if (reset) begin
      td_stage0 <= '0; td_stage1 <= '0; td_stage2 <= '0;
    end else begin
      // stage0 = req.topdown_info + Ctrl 类叠加(TAGE/SC/ITTAGE/RAS) + BTB(wb|ctrl)
      td_stage0 <= ftq_req_topdown_reasons;
      td_stage0[R_TAGE]   <= set_tage   | ftq_req_topdown_reasons[R_TAGE];
      td_stage0[R_SC]     <= set_sc     | ftq_req_topdown_reasons[R_SC];
      td_stage0[R_ITTAGE] <= set_ittage | ftq_req_topdown_reasons[R_ITTAGE];
      td_stage0[R_RAS]    <= set_ras    | ftq_req_topdown_reasons[R_RAS];
      td_stage0[R_MEMVIO] <= set_memvio | ftq_req_topdown_reasons[R_MEMVIO];
      td_stage0[R_OTHER]  <= set_other  | ftq_req_topdown_reasons[R_OTHER];
      td_stage0[R_BTB]    <= (wb_redirect || set_btb) | ftq_req_topdown_reasons[R_BTB];
      // stage1 = stage0 shift + ICache/iTLB miss(bit10/11) + Ctrl 类叠加 + BTB
      td_stage1 <= td_stage0;
      td_stage1[R_TAGE]   <= set_tage   | td_stage0[R_TAGE];
      td_stage1[R_SC]     <= set_sc     | td_stage0[R_SC];
      td_stage1[R_ITTAGE] <= set_ittage | td_stage0[R_ITTAGE];
      td_stage1[R_RAS]    <= set_ras    | td_stage0[R_RAS];
      td_stage1[R_MEMVIO] <= set_memvio | td_stage0[R_MEMVIO];
      td_stage1[R_OTHER]  <= set_other  | td_stage0[R_OTHER];
      td_stage1[R_ICACHE] <= icache_topdownIcacheMiss | td_stage0[R_ICACHE];
      td_stage1[R_ITLB]   <= icache_topdownItlbMiss   | td_stage0[R_ITLB];
      td_stage1[R_BTB]    <= (wb_redirect || set_btb) | td_stage0[R_BTB];
      // stage2 = stage1 shift + Ctrl 类叠加；bit12 用写回 redirect 的特殊处理
      td_stage2 <= td_stage1;
      td_stage2[R_TAGE]   <= set_tage   | td_stage1[R_TAGE];
      td_stage2[R_SC]     <= set_sc     | td_stage1[R_SC];
      td_stage2[R_ITTAGE] <= set_ittage | td_stage1[R_ITTAGE];
      td_stage2[R_RAS]    <= set_ras    | td_stage1[R_RAS];
      td_stage2[R_MEMVIO] <= set_memvio | td_stage1[R_MEMVIO];
      td_stage2[R_OTHER]  <= set_other  | td_stage1[R_OTHER];
      td_stage2[R_BTB]    <= wb_redirect ? (f3_wb_not_flush | set_btb | td_stage1[R_BTB])
                                         : (set_btb | td_stage1[R_BTB]);
    end
  end

  // 输出 = stage2 再叠加一次组合的 topdown_redirect 分类(golden 同样在输出处再 OR 一遍)
  logic [37:0] td_out;
  always_comb begin
    td_out = td_stage2;
    td_out[R_TAGE]   = set_tage   | td_stage2[R_TAGE];
    td_out[R_SC]     = set_sc     | td_stage2[R_SC];
    td_out[R_ITTAGE] = set_ittage | td_stage2[R_ITTAGE];
    td_out[R_RAS]    = set_ras    | td_stage2[R_RAS];
    td_out[R_MEMVIO] = set_memvio | td_stage2[R_MEMVIO];
    td_out[R_OTHER]  = set_other  | td_stage2[R_OTHER];
    td_out[R_BTB]    = set_btb    | td_stage2[R_BTB];
  end
  assign ibuffer_topdown_reasons = td_out;

  // --- to backend gpaddr mem ---
  assign toBackend_gpaddrMem_wen =
      f3_toIbuffer_valid && (f3_req_is_mmio ? (mmio_exception == EXC_GPF)
                                            : ((f3_exception_0 == EXC_GPF) || (f3_exception_1 == EXC_GPF)));
  assign toBackend_gpaddrMem_waddr = f3_ftq_req.ftqIdx_value;
  assign toBackend_gpaddrMem_wdata_gpaddr = f3_req_is_mmio ? mmio_resend_gpaddr : f3_gpaddr;
  assign toBackend_gpaddrMem_wdata_isForVSnonLeafPTE =
      f3_req_is_mmio ? mmio_resend_isForVSnonLeafPTE : f3_isForVSnonLeafPTE;

  // ===========================================================================
  // 写回(WriteBack)级：把预解码/检查结果写回 FTQ，预测错则 redirect
  // ===========================================================================
  wire wb_enable = f2_fire_no_flush_q && !f3_req_is_mmio && !f3_flush;
  logic wb_valid;
  always_ff @(posedge clock or posedge reset)
    if (reset) wb_valid <= 1'b0; else wb_valid <= wb_enable;

  ftq_req_t wb_ftq_req;
  logic [PredictWidth-1:0]            wb_chk_fixedRange, wb_chk_fixedTaken;
  logic [PredictWidth-1:0]            wb_instr_range, wb_instr_valid;
  logic [PredictWidth-1:0][PcCutPoint:0] wb_pc_lower_result;
  logic [VAddrBits-1:PcCutPoint]     wb_pc_high, wb_pc_high_plus1;
  pd_info_t [PredictWidth-1:0]       wb_pd;
  logic [3:0]                        wb_lastIdx;
  logic                              wb_false_lastHalf_raw;
  logic [VAddrBits-1:0]              wb_false_target;
  always_ff @(posedge clock) if (wb_enable) begin
    wb_ftq_req         <= f3_ftq_req;
    wb_chk_fixedRange  <= chk_fixedRange;
    wb_chk_fixedTaken  <= chk_fixedTaken;
    wb_instr_range     <= enqEnable_w;   // io.toIbuffer.bits.enqEnable
    wb_pc_lower_result <= f3_pc_lower_result;
    wb_pc_high         <= f3_pc_high;
    wb_pc_high_plus1   <= f3_pc_high_plus1;
    wb_pd              <= f3_pd;
    wb_instr_valid     <= f3_instr_valid;
    wb_lastIdx         <= f3_last_validIdx;
    wb_false_lastHalf_raw <= f3_false_lastHalf;
    wb_false_target    <= f3_false_snpc;
  end

  logic [PredictWidth-1:0][VAddrBits-1:0] wb_pc;
  always_comb for (int i = 0; i < PredictWidth; i++)
    wb_pc[i] = catpc(wb_pc_lower_result[i], wb_pc_high, wb_pc_high_plus1);

  // checkerOutStage2 是组合直出(无寄存)，wb 用当拍的 chk_* (stage2)
  wire [PredictWidth-1:0] wb_chk_fixedMissPred = chk_fixedMissPred;

  wire wb_false_lastHalf = wb_false_lastHalf_raw && (wb_lastIdx != (PredictWidth-1));
  wire wb_half_flush  = wb_false_lastHalf;
  wire [VAddrBits-1:0] wb_half_target = wb_false_target;

  // f3_wb_not_flush：wb 与 f3 同一 ftqIdx 且都 valid → 不冲刷 f3
  assign f3_wb_not_flush = (wb_ftq_req.ftqIdx_flag == f3_ftq_req.ftqIdx_flag) &&
                           (wb_ftq_req.ftqIdx_value == f3_ftq_req.ftqIdx_value) && f3_valid && wb_valid;

  // wb 控制 f3_lastHalf 的两个反馈(见 lastHalf 节的时序)
  logic f3_hasLastHalf_q;
  always_ff @(posedge clock or posedge reset)
    if (reset) f3_hasLastHalf_q <= 1'b0; else f3_hasLastHalf_q <= f3_hasLastHalf;
  logic f3_fire_q;
  always_ff @(posedge clock or posedge reset)
    if (reset) f3_fire_q <= 1'b0; else f3_fire_q <= f3_fire;
  assign wb_set_lastHalf_disable = wb_valid && f3_hasLastHalf_q &&
        wb_chk_fixedMissPred[PredictWidth-1] && !f3_fire && !f3_fire_q && !f3_flush;
  assign wb_clear_lastHalf_valid = wb_valid && f3_hasLastHalf_q &&
        wb_chk_fixedMissPred[PredictWidth-1] && f3_fire;

  // --- checkFlushWb：预测检查写回 ---
  // jalTarget 用第一条 isJal 有效指令的目标
  logic [3:0] checkFlushWbjalTargetIdx;
  always_comb begin
    checkFlushWbjalTargetIdx = '0;
    for (int i = PredictWidth-1; i >= 0; i--)
      if (wb_instr_valid[i] && (wb_pd[i].brType == xs_predecode_pkg::BR_JAL))
        checkFlushWbjalTargetIdx = i[3:0];
  end
  // target 用第一条 missPred 的修正目标
  logic [3:0] checkFlushWbTargetIdx;
  always_comb begin
    checkFlushWbTargetIdx = '0;
    for (int i = PredictWidth-1; i >= 0; i--)
      if (wb_chk_fixedMissPred[i]) checkFlushWbTargetIdx = i[3:0];
  end
  logic [3:0] cfi_offset_idx;
  always_comb begin
    cfi_offset_idx = '0;
    for (int i = PredictWidth-1; i >= 0; i--)
      if (wb_chk_fixedTaken[i]) cfi_offset_idx = i[3:0];
  end
  logic [3:0] mis_offset_idx;
  always_comb begin
    mis_offset_idx = '0;
    for (int i = PredictWidth-1; i >= 0; i--)
      if (wb_chk_fixedMissPred[i]) mis_offset_idx = i[3:0];
  end

  wire checkFlushWb_valid = wb_valid;
  wire checkFlushWb_misOffset_valid = (|wb_chk_fixedMissPred) || wb_half_flush;
  wire [3:0] checkFlushWb_misOffset_bits = wb_half_flush ? wb_lastIdx : mis_offset_idx;
  wire checkFlushWb_cfiOffset_valid = (|wb_chk_fixedTaken);
  wire [VAddrBits-1:0] checkFlushWb_target =
      wb_half_flush ? wb_half_target : chk_fixedTarget[checkFlushWbTargetIdx];
  wire [VAddrBits-1:0] checkFlushWb_jalTarget = chk_jalTarget[checkFlushWbjalTargetIdx];

  pd_info_t [PredictWidth-1:0] checkFlushWb_pd;
  always_comb for (int i = 0; i < PredictWidth; i++) begin
    checkFlushWb_pd[i]       = wb_pd[i];
    checkFlushWb_pd[i].valid = wb_instr_valid[i];
  end

  // --- mmioFlushWb：MMIO 完成时写回 ---
  wire fromUncache_fire_q;
  logic fromUncache_fire_r;
  always_ff @(posedge clock or posedge reset)
    if (reset) fromUncache_fire_r <= 1'b0; else fromUncache_fire_r <= fromUncache_fire;
  assign fromUncache_fire_q = fromUncache_fire_r;

  wire mmioFlushWb_valid = f3_req_is_mmio && (mmio_state == M_WAIT_COMMIT) && fromUncache_fire_q &&
        f3_mmio_use_seq_pc && !f3_ftq_flush_self && !f3_ftq_flush_by_older;
  wire [VAddrBits-1:0] mmioFlushWb_target = mmio_is_RVC ? (f3_ftq_req.startAddr + 2) : (f3_ftq_req.startAddr + 4);
  // mmioFlushWb.bits.pd：第 0 条用 MMIO 译码；其余条 Chisel 里是 DontCare，
  // firtool 把它实现为「沿用 f3_pd」(只覆写 valid=f3_mmio_range[i]=0)，这里照此处理。
  pd_info_t [PredictWidth-1:0] mmioFlushWb_pd;
  always_comb for (int i = 0; i < PredictWidth; i++) begin
    mmioFlushWb_pd[i]       = f3_pd[i];
    mmioFlushWb_pd[i].valid = f3_mmio_range[i];
    if (i == 0 && f3_req_is_mmio) begin
      mmioFlushWb_pd[0].isRVC  = mmio_is_RVC;
      mmioFlushWb_pd[0].brType = mmio_brType;
      mmioFlushWb_pd[0].isCall = mmio_isCall;
      mmioFlushWb_pd[0].isRet  = mmio_isRet;
    end
  end

  // pdWb = wb_valid ? checkFlushWb : mmioFlushWb
  assign pdWb_valid          = wb_valid ? checkFlushWb_valid : mmioFlushWb_valid;
  assign pdWb_pc             = wb_valid ? wb_pc : f3_pc;
  assign pdWb_pd             = wb_valid ? checkFlushWb_pd : mmioFlushWb_pd;
  assign pdWb_ftqIdx_flag    = wb_valid ? wb_ftq_req.ftqIdx_flag  : f3_ftq_req.ftqIdx_flag;
  assign pdWb_ftqIdx_value   = wb_valid ? wb_ftq_req.ftqIdx_value : f3_ftq_req.ftqIdx_value;
  assign pdWb_misOffset_valid= wb_valid ? checkFlushWb_misOffset_valid : f3_req_is_mmio;
  assign pdWb_misOffset_bits = wb_valid ? checkFlushWb_misOffset_bits  : 4'h0;
  assign pdWb_cfiOffset_valid= wb_valid ? checkFlushWb_cfiOffset_valid : 1'b0;
  assign pdWb_target         = wb_valid ? checkFlushWb_target : mmioFlushWb_target;
  assign pdWb_jalTarget      = wb_valid ? checkFlushWb_jalTarget : '0;
  assign pdWb_instrRange     = wb_valid ? wb_instr_range : f3_mmio_range;

  assign wb_redirect   = checkFlushWb_misOffset_valid && wb_valid;
  assign mmio_redirect = f3_req_is_mmio && (mmio_state == M_WAIT_COMMIT) && fromUncache_fire_q && f3_mmio_use_seq_pc;

  // ===========================================================================
  // perf 计数（13 个 6 位饱和计数；按 golden 的事件累加）
  // ===========================================================================
  logic                         f3_perf_bank_hit_0, f3_perf_bank_hit_1, f3_perf_hit;
  logic perf_only_0_hit_q, perf_only_0_miss_q, perf_hit_0_hit_1_q, perf_hit_0_miss_1_q;
  logic perf_miss_0_hit_1_q, perf_miss_0_miss_1_q;
  always_ff @(posedge clock) if (f2_fire) begin
    f3_perf_bank_hit_0  <= perf_bank_hit_0;
    f3_perf_bank_hit_1  <= perf_bank_hit_1;
    f3_perf_hit         <= perf_hit;
    perf_only_0_hit_q   <= perf_only_0_hit;
    perf_only_0_miss_q  <= perf_only_0_miss;
    perf_hit_0_hit_1_q  <= perf_hit_0_hit_1;
    perf_hit_0_miss_1_q <= perf_hit_0_miss_1;
    perf_miss_0_hit_1_q <= perf_miss_0_hit_1;
    perf_miss_0_miss_1_q<= perf_miss_0_miss_1;
  end

  wire ifu_fire = f3_fire;
  // 13 个事件(对应 golden perfEvents 顺序)
  wire [12:0] perf_ev = {
    /*12*/ perf_miss_0_miss_1_q && ifu_fire,
    /*11*/ perf_miss_0_hit_1_q  && ifu_fire,
    /*10*/ perf_hit_0_miss_1_q  && ifu_fire,
    /* 9*/ perf_hit_0_hit_1_q   && ifu_fire,
    /* 8*/ perf_only_0_miss_q   && ifu_fire,
    /* 7*/ perf_only_0_hit_q    && ifu_fire,
    /* 6*/ ifu_fire && f3_doubleLine && f3_perf_bank_hit_1, // cacheline_1_hit
    /* 5*/ ifu_fire && f3_doubleLine && f3_perf_bank_hit_1, // cacheline_0_hit(golden 同写 hit_1)
    /* 4*/ ifu_fire && f3_doubleLine,                        // req_cacheline_1
    /* 3*/ ifu_fire,                                         // req_cacheline_0
    /* 2*/ ifu_fire && !f3_perf_hit,                         // ifu_miss
    /* 1*/ ifu_fire,                                         // ifu_req
    /* 0*/ wb_redirect                                       // frontendFlush
  };
  // 6 位饱和累加计数器
  logic [12:0][5:0] perf_cnt;
  always_ff @(posedge clock or posedge reset) begin
    if (reset) for (int i = 0; i < 13; i++) perf_cnt[i] <= '0;
    else for (int i = 0; i < 13; i++)
      if (perf_ev[i] && (perf_cnt[i] != 6'h3F)) perf_cnt[i] <= perf_cnt[i] + 1'b1;
  end
  assign perf_value = perf_cnt;

endmodule

`default_nettype wire
