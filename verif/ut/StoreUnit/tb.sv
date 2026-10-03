// =============================================================================
// StoreUnit UT —— golden StoreUnit 对重写 StoreUnit_xs 双例化，同激励逐拍比全部 250 根输出。
// 本文件由 scripts/gen_storeunit.py 生成（端口连接 / 随机驱动 / 逐根比较是机械部分，
// 激励整形与覆盖判据是生成器里 TB_HAND 的手写部分）。勿手改。
//
// 激励要点：
//   · 每拍所有输入先整体随机，再整形：三路来源 valid 以 1/2、1/4、1/8 的概率出现（保证三种
//     流都被选中，也有相互挤占）；redirect 1/16；
//   · 标量 fuOpType 在 sb/sh/sw/sd、cbo.zero、cbo.clean/flush/inval、hsv、全随机之间分桶；
//     地址低位随机 ⇒ 对齐 / 16B 内非对齐 / 跨 16B 三种情形都常见；
//   · sqCommitPtr 以 1/2 概率对准当前标量 store（跨 16B 时"能进缓冲 / 要重发"两边都打）；
//   · TLB：miss 1/4，Svpbmt 偏向 PMA，各页异常位 1/16；memidx 以 1/2 概率对准 s1 的 sqIdx；
//   · PMP：st/ld 1/16，mmio 1/8；
//   · 触发器：一半时间全关；其余时间 tdata2 取 s1 虚地址附近（相等 / 略大略小 / 同 16B / 同缓存行）。
// 不复位寄存器：+vcs+initreg+random / +<seed> 两个实例各摇各的，先跑 +warmup 拍（各级流水寄存器
//   都被写过）再开始比。
// 覆盖判据（读重写核内部信号，逐项有下限，不达标本轮不作数）：见 cov_names。
// =============================================================================
`timescale 1ns/1ps

module tb;

  int unsigned NCYCLES = 200000;
  int unsigned WARMUP  = 0;
  int      errors = 0;
  longint  checks = 0;
  bit      comparing = 0;

  logic clock = 0;
  logic reset;
  always #5 clock = ~clock;

  // ---- 输入（两侧共用）----
  logic          io_redirect_valid;
  logic          io_redirect_bits_robIdx_flag;
  logic [7:0]    io_redirect_bits_robIdx_value;
  logic          io_redirect_bits_level;
  logic          io_csrCtrl_hd_misalign_st_enable;
  logic          io_stin_valid;
  logic          io_stin_bits_uop_ftqPtr_flag;
  logic [5:0]    io_stin_bits_uop_ftqPtr_value;
  logic [3:0]    io_stin_bits_uop_ftqOffset;
  logic [34:0]   io_stin_bits_uop_fuType;
  logic [8:0]    io_stin_bits_uop_fuOpType;
  logic          io_stin_bits_uop_rfWen;
  logic [31:0]   io_stin_bits_uop_imm;
  logic [7:0]    io_stin_bits_uop_pdest;
  logic          io_stin_bits_uop_robIdx_flag;
  logic [7:0]    io_stin_bits_uop_robIdx_value;
  logic          io_stin_bits_uop_debugInfo_eliminatedMove;
  logic [63:0]   io_stin_bits_uop_debugInfo_renameTime;
  logic [63:0]   io_stin_bits_uop_debugInfo_dispatchTime;
  logic [63:0]   io_stin_bits_uop_debugInfo_enqRsTime;
  logic [63:0]   io_stin_bits_uop_debugInfo_selectTime;
  logic [63:0]   io_stin_bits_uop_debugInfo_issueTime;
  logic [63:0]   io_stin_bits_uop_debugInfo_writebackTime;
  logic [63:0]   io_stin_bits_uop_debugInfo_runahead_checkpoint_id;
  logic [63:0]   io_stin_bits_uop_debugInfo_tlbFirstReqTime;
  logic [63:0]   io_stin_bits_uop_debugInfo_tlbRespTime;
  logic [55:0]   io_stin_bits_uop_debug_seqNum_seqNum;
  logic [7:0]    io_stin_bits_uop_debug_seqNum_uopIdx;
  logic          io_stin_bits_uop_lqIdx_flag;
  logic [6:0]    io_stin_bits_uop_lqIdx_value;
  logic          io_stin_bits_uop_sqIdx_flag;
  logic [5:0]    io_stin_bits_uop_sqIdx_value;
  logic [63:0]   io_stin_bits_src_0;
  logic          io_stin_bits_isFirstIssue;
  logic          io_misalign_stin_valid;
  logic          io_misalign_stin_bits_uop_exceptionVec_0;
  logic          io_misalign_stin_bits_uop_exceptionVec_1;
  logic          io_misalign_stin_bits_uop_exceptionVec_2;
  logic          io_misalign_stin_bits_uop_exceptionVec_4;
  logic          io_misalign_stin_bits_uop_exceptionVec_5;
  logic          io_misalign_stin_bits_uop_exceptionVec_8;
  logic          io_misalign_stin_bits_uop_exceptionVec_9;
  logic          io_misalign_stin_bits_uop_exceptionVec_10;
  logic          io_misalign_stin_bits_uop_exceptionVec_11;
  logic          io_misalign_stin_bits_uop_exceptionVec_12;
  logic          io_misalign_stin_bits_uop_exceptionVec_13;
  logic          io_misalign_stin_bits_uop_exceptionVec_14;
  logic          io_misalign_stin_bits_uop_exceptionVec_16;
  logic          io_misalign_stin_bits_uop_exceptionVec_17;
  logic          io_misalign_stin_bits_uop_exceptionVec_18;
  logic          io_misalign_stin_bits_uop_exceptionVec_19;
  logic          io_misalign_stin_bits_uop_exceptionVec_20;
  logic          io_misalign_stin_bits_uop_exceptionVec_21;
  logic          io_misalign_stin_bits_uop_exceptionVec_22;
  logic [3:0]    io_misalign_stin_bits_uop_trigger;
  logic          io_misalign_stin_bits_uop_ftqPtr_flag;
  logic [5:0]    io_misalign_stin_bits_uop_ftqPtr_value;
  logic [3:0]    io_misalign_stin_bits_uop_ftqOffset;
  logic [34:0]   io_misalign_stin_bits_uop_fuType;
  logic [8:0]    io_misalign_stin_bits_uop_fuOpType;
  logic          io_misalign_stin_bits_uop_rfWen;
  logic [7:0]    io_misalign_stin_bits_uop_vpu_vstart;
  logic [2:0]    io_misalign_stin_bits_uop_vpu_nf;
  logic [1:0]    io_misalign_stin_bits_uop_vpu_veew;
  logic [6:0]    io_misalign_stin_bits_uop_uopIdx;
  logic [7:0]    io_misalign_stin_bits_uop_pdest;
  logic          io_misalign_stin_bits_uop_robIdx_flag;
  logic [7:0]    io_misalign_stin_bits_uop_robIdx_value;
  logic          io_misalign_stin_bits_uop_debugInfo_eliminatedMove;
  logic [63:0]   io_misalign_stin_bits_uop_debugInfo_renameTime;
  logic [63:0]   io_misalign_stin_bits_uop_debugInfo_dispatchTime;
  logic [63:0]   io_misalign_stin_bits_uop_debugInfo_enqRsTime;
  logic [63:0]   io_misalign_stin_bits_uop_debugInfo_selectTime;
  logic [63:0]   io_misalign_stin_bits_uop_debugInfo_issueTime;
  logic [63:0]   io_misalign_stin_bits_uop_debugInfo_writebackTime;
  logic [63:0]   io_misalign_stin_bits_uop_debugInfo_runahead_checkpoint_id;
  logic [63:0]   io_misalign_stin_bits_uop_debugInfo_tlbFirstReqTime;
  logic [63:0]   io_misalign_stin_bits_uop_debugInfo_tlbRespTime;
  logic [55:0]   io_misalign_stin_bits_uop_debug_seqNum_seqNum;
  logic [7:0]    io_misalign_stin_bits_uop_debug_seqNum_uopIdx;
  logic          io_misalign_stin_bits_uop_lqIdx_flag;
  logic [6:0]    io_misalign_stin_bits_uop_lqIdx_value;
  logic          io_misalign_stin_bits_uop_sqIdx_flag;
  logic [5:0]    io_misalign_stin_bits_uop_sqIdx_value;
  logic [49:0]   io_misalign_stin_bits_vaddr;
  logic [15:0]   io_misalign_stin_bits_mask;
  logic          io_misalign_stin_bits_isvec;
  logic          io_misalign_stin_bits_is128bit;
  logic          io_misalign_stin_bits_isFinalSplit;
  logic          io_tlb_resp_valid;
  logic [47:0]   io_tlb_resp_bits_paddr_0;
  logic [63:0]   io_tlb_resp_bits_gpaddr_0;
  logic [63:0]   io_tlb_resp_bits_fullva;
  logic [1:0]    io_tlb_resp_bits_pbmt_0;
  logic          io_tlb_resp_bits_miss;
  logic          io_tlb_resp_bits_isForVSnonLeafPTE;
  logic          io_tlb_resp_bits_excp_0_vaNeedExt;
  logic          io_tlb_resp_bits_excp_0_isHyper;
  logic          io_tlb_resp_bits_excp_0_gpf_ld;
  logic          io_tlb_resp_bits_excp_0_gpf_st;
  logic          io_tlb_resp_bits_excp_0_pf_ld;
  logic          io_tlb_resp_bits_excp_0_pf_st;
  logic          io_tlb_resp_bits_excp_0_af_ld;
  logic          io_tlb_resp_bits_excp_0_af_st;
  logic          io_tlb_resp_bits_ptwBack;
  logic [6:0]    io_tlb_resp_bits_memidx_idx;
  logic          io_pmp_ld;
  logic          io_pmp_st;
  logic          io_pmp_mmio;
  logic          io_vecstin_valid;
  logic [63:0]   io_vecstin_bits_vaddr;
  logic [49:0]   io_vecstin_bits_basevaddr;
  logic [15:0]   io_vecstin_bits_mask;
  logic [2:0]    io_vecstin_bits_alignedType;
  logic          io_vecstin_bits_vecActive;
  logic          io_vecstin_bits_vecIsFirstActiveElement;
  logic          io_vecstin_bits_uop_exceptionVec_4;
  logic          io_vecstin_bits_uop_exceptionVec_5;
  logic          io_vecstin_bits_uop_exceptionVec_6;
  logic          io_vecstin_bits_uop_exceptionVec_13;
  logic          io_vecstin_bits_uop_exceptionVec_19;
  logic          io_vecstin_bits_uop_exceptionVec_21;
  logic [3:0]    io_vecstin_bits_uop_trigger;
  logic          io_vecstin_bits_uop_ftqPtr_flag;
  logic [5:0]    io_vecstin_bits_uop_ftqPtr_value;
  logic [3:0]    io_vecstin_bits_uop_ftqOffset;
  logic [34:0]   io_vecstin_bits_uop_fuType;
  logic [8:0]    io_vecstin_bits_uop_fuOpType;
  logic          io_vecstin_bits_uop_rfWen;
  logic [7:0]    io_vecstin_bits_uop_vpu_vstart;
  logic [2:0]    io_vecstin_bits_uop_vpu_nf;
  logic [1:0]    io_vecstin_bits_uop_vpu_veew;
  logic [6:0]    io_vecstin_bits_uop_uopIdx;
  logic [7:0]    io_vecstin_bits_uop_pdest;
  logic          io_vecstin_bits_uop_robIdx_flag;
  logic [7:0]    io_vecstin_bits_uop_robIdx_value;
  logic          io_vecstin_bits_uop_debugInfo_eliminatedMove;
  logic [63:0]   io_vecstin_bits_uop_debugInfo_renameTime;
  logic [63:0]   io_vecstin_bits_uop_debugInfo_dispatchTime;
  logic [63:0]   io_vecstin_bits_uop_debugInfo_enqRsTime;
  logic [63:0]   io_vecstin_bits_uop_debugInfo_selectTime;
  logic [63:0]   io_vecstin_bits_uop_debugInfo_issueTime;
  logic [63:0]   io_vecstin_bits_uop_debugInfo_writebackTime;
  logic [63:0]   io_vecstin_bits_uop_debugInfo_runahead_checkpoint_id;
  logic [63:0]   io_vecstin_bits_uop_debugInfo_tlbFirstReqTime;
  logic [63:0]   io_vecstin_bits_uop_debugInfo_tlbRespTime;
  logic [55:0]   io_vecstin_bits_uop_debug_seqNum_seqNum;
  logic [7:0]    io_vecstin_bits_uop_debug_seqNum_uopIdx;
  logic          io_vecstin_bits_uop_lqIdx_flag;
  logic [6:0]    io_vecstin_bits_uop_lqIdx_value;
  logic          io_vecstin_bits_uop_sqIdx_flag;
  logic [5:0]    io_vecstin_bits_uop_sqIdx_value;
  logic [3:0]    io_vecstin_bits_mBIndex;
  logic [7:0]    io_vecstin_bits_elemIdx;
  logic [4:0]    io_vecstin_bits_splitIndex;
  logic          io_misalign_enq_req_ready;
  logic [1:0]    io_fromCsrTrigger_tdataVec_0_matchType;
  logic          io_fromCsrTrigger_tdataVec_0_select;
  logic          io_fromCsrTrigger_tdataVec_0_timing;
  logic [3:0]    io_fromCsrTrigger_tdataVec_0_action;
  logic          io_fromCsrTrigger_tdataVec_0_chain;
  logic          io_fromCsrTrigger_tdataVec_0_store;
  logic [63:0]   io_fromCsrTrigger_tdataVec_0_tdata2;
  logic [1:0]    io_fromCsrTrigger_tdataVec_1_matchType;
  logic          io_fromCsrTrigger_tdataVec_1_select;
  logic          io_fromCsrTrigger_tdataVec_1_timing;
  logic [3:0]    io_fromCsrTrigger_tdataVec_1_action;
  logic          io_fromCsrTrigger_tdataVec_1_chain;
  logic          io_fromCsrTrigger_tdataVec_1_store;
  logic [63:0]   io_fromCsrTrigger_tdataVec_1_tdata2;
  logic [1:0]    io_fromCsrTrigger_tdataVec_2_matchType;
  logic          io_fromCsrTrigger_tdataVec_2_select;
  logic          io_fromCsrTrigger_tdataVec_2_timing;
  logic [3:0]    io_fromCsrTrigger_tdataVec_2_action;
  logic          io_fromCsrTrigger_tdataVec_2_chain;
  logic          io_fromCsrTrigger_tdataVec_2_store;
  logic [63:0]   io_fromCsrTrigger_tdataVec_2_tdata2;
  logic [1:0]    io_fromCsrTrigger_tdataVec_3_matchType;
  logic          io_fromCsrTrigger_tdataVec_3_select;
  logic          io_fromCsrTrigger_tdataVec_3_timing;
  logic [3:0]    io_fromCsrTrigger_tdataVec_3_action;
  logic          io_fromCsrTrigger_tdataVec_3_chain;
  logic          io_fromCsrTrigger_tdataVec_3_store;
  logic [63:0]   io_fromCsrTrigger_tdataVec_3_tdata2;
  logic          io_fromCsrTrigger_tEnableVec_0;
  logic          io_fromCsrTrigger_tEnableVec_1;
  logic          io_fromCsrTrigger_tEnableVec_2;
  logic          io_fromCsrTrigger_tEnableVec_3;
  logic          io_fromCsrTrigger_debugMode;
  logic          io_fromCsrTrigger_triggerCanRaiseBpExp;
  logic          io_sqCommitPtr_flag;
  logic [5:0]    io_sqCommitPtr_value;
  logic [6:0]    io_sqCommitUopIdx;
  logic          io_sqCommitRobIdx_flag;
  logic [7:0]    io_sqCommitRobIdx_value;
  // ---- 输出：g_ = golden，x_ = 重写 ----
  wire               g_io_stin_ready, x_io_stin_ready;
  wire               g_io_issue_valid, x_io_issue_valid;
  wire               g_io_issue_bits_uop_robIdx_flag, x_io_issue_bits_uop_robIdx_flag;
  wire [7:0]         g_io_issue_bits_uop_robIdx_value, x_io_issue_bits_uop_robIdx_value;
  wire               g_io_misalign_stin_ready, x_io_misalign_stin_ready;
  wire               g_io_misalign_stout_valid, x_io_misalign_stout_valid;
  wire               g_io_misalign_stout_bits_uop_exceptionVec_3, x_io_misalign_stout_bits_uop_exceptionVec_3;
  wire               g_io_misalign_stout_bits_uop_exceptionVec_6, x_io_misalign_stout_bits_uop_exceptionVec_6;
  wire               g_io_misalign_stout_bits_uop_exceptionVec_7, x_io_misalign_stout_bits_uop_exceptionVec_7;
  wire               g_io_misalign_stout_bits_uop_exceptionVec_15, x_io_misalign_stout_bits_uop_exceptionVec_15;
  wire               g_io_misalign_stout_bits_uop_exceptionVec_19, x_io_misalign_stout_bits_uop_exceptionVec_19;
  wire               g_io_misalign_stout_bits_uop_exceptionVec_23, x_io_misalign_stout_bits_uop_exceptionVec_23;
  wire [3:0]         g_io_misalign_stout_bits_uop_trigger, x_io_misalign_stout_bits_uop_trigger;
  wire               g_io_misalign_stout_bits_uop_robIdx_flag, x_io_misalign_stout_bits_uop_robIdx_flag;
  wire [7:0]         g_io_misalign_stout_bits_uop_robIdx_value, x_io_misalign_stout_bits_uop_robIdx_value;
  wire [49:0]        g_io_misalign_stout_bits_vaddr, x_io_misalign_stout_bits_vaddr;
  wire               g_io_misalign_stout_bits_vaNeedExt, x_io_misalign_stout_bits_vaNeedExt;
  wire [47:0]        g_io_misalign_stout_bits_paddr, x_io_misalign_stout_bits_paddr;
  wire [63:0]        g_io_misalign_stout_bits_gpaddr, x_io_misalign_stout_bits_gpaddr;
  wire               g_io_misalign_stout_bits_nc, x_io_misalign_stout_bits_nc;
  wire               g_io_misalign_stout_bits_mmio, x_io_misalign_stout_bits_mmio;
  wire               g_io_misalign_stout_bits_memBackTypeMM, x_io_misalign_stout_bits_memBackTypeMM;
  wire               g_io_misalign_stout_bits_isForVSnonLeafPTE, x_io_misalign_stout_bits_isForVSnonLeafPTE;
  wire               g_io_misalign_stout_bits_vecActive, x_io_misalign_stout_bits_vecActive;
  wire               g_io_misalign_stout_bits_need_rep, x_io_misalign_stout_bits_need_rep;
  wire               g_io_tlb_req_valid, x_io_tlb_req_valid;
  wire [49:0]        g_io_tlb_req_bits_vaddr, x_io_tlb_req_bits_vaddr;
  wire [63:0]        g_io_tlb_req_bits_fullva, x_io_tlb_req_bits_fullva;
  wire               g_io_tlb_req_bits_checkfullva, x_io_tlb_req_bits_checkfullva;
  wire [2:0]         g_io_tlb_req_bits_cmd, x_io_tlb_req_bits_cmd;
  wire               g_io_tlb_req_bits_hyperinst, x_io_tlb_req_bits_hyperinst;
  wire [6:0]         g_io_tlb_req_bits_memidx_idx, x_io_tlb_req_bits_memidx_idx;
  wire               g_io_tlb_req_bits_frm_mabuf, x_io_tlb_req_bits_frm_mabuf;
  wire               g_io_tlb_req_bits_debug_robIdx_flag, x_io_tlb_req_bits_debug_robIdx_flag;
  wire [7:0]         g_io_tlb_req_bits_debug_robIdx_value, x_io_tlb_req_bits_debug_robIdx_value;
  wire               g_io_tlb_req_bits_debug_isFirstIssue, x_io_tlb_req_bits_debug_isFirstIssue;
  wire               g_io_dcache_req_valid, x_io_dcache_req_valid;
  wire               g_io_lsq_valid, x_io_lsq_valid;
  wire               g_io_lsq_bits_uop_exceptionVec_0, x_io_lsq_bits_uop_exceptionVec_0;
  wire               g_io_lsq_bits_uop_exceptionVec_1, x_io_lsq_bits_uop_exceptionVec_1;
  wire               g_io_lsq_bits_uop_exceptionVec_2, x_io_lsq_bits_uop_exceptionVec_2;
  wire               g_io_lsq_bits_uop_exceptionVec_3, x_io_lsq_bits_uop_exceptionVec_3;
  wire               g_io_lsq_bits_uop_exceptionVec_4, x_io_lsq_bits_uop_exceptionVec_4;
  wire               g_io_lsq_bits_uop_exceptionVec_5, x_io_lsq_bits_uop_exceptionVec_5;
  wire               g_io_lsq_bits_uop_exceptionVec_6, x_io_lsq_bits_uop_exceptionVec_6;
  wire               g_io_lsq_bits_uop_exceptionVec_7, x_io_lsq_bits_uop_exceptionVec_7;
  wire               g_io_lsq_bits_uop_exceptionVec_8, x_io_lsq_bits_uop_exceptionVec_8;
  wire               g_io_lsq_bits_uop_exceptionVec_9, x_io_lsq_bits_uop_exceptionVec_9;
  wire               g_io_lsq_bits_uop_exceptionVec_10, x_io_lsq_bits_uop_exceptionVec_10;
  wire               g_io_lsq_bits_uop_exceptionVec_11, x_io_lsq_bits_uop_exceptionVec_11;
  wire               g_io_lsq_bits_uop_exceptionVec_12, x_io_lsq_bits_uop_exceptionVec_12;
  wire               g_io_lsq_bits_uop_exceptionVec_13, x_io_lsq_bits_uop_exceptionVec_13;
  wire               g_io_lsq_bits_uop_exceptionVec_14, x_io_lsq_bits_uop_exceptionVec_14;
  wire               g_io_lsq_bits_uop_exceptionVec_15, x_io_lsq_bits_uop_exceptionVec_15;
  wire               g_io_lsq_bits_uop_exceptionVec_16, x_io_lsq_bits_uop_exceptionVec_16;
  wire               g_io_lsq_bits_uop_exceptionVec_17, x_io_lsq_bits_uop_exceptionVec_17;
  wire               g_io_lsq_bits_uop_exceptionVec_18, x_io_lsq_bits_uop_exceptionVec_18;
  wire               g_io_lsq_bits_uop_exceptionVec_19, x_io_lsq_bits_uop_exceptionVec_19;
  wire               g_io_lsq_bits_uop_exceptionVec_20, x_io_lsq_bits_uop_exceptionVec_20;
  wire               g_io_lsq_bits_uop_exceptionVec_21, x_io_lsq_bits_uop_exceptionVec_21;
  wire               g_io_lsq_bits_uop_exceptionVec_22, x_io_lsq_bits_uop_exceptionVec_22;
  wire               g_io_lsq_bits_uop_exceptionVec_23, x_io_lsq_bits_uop_exceptionVec_23;
  wire [3:0]         g_io_lsq_bits_uop_trigger, x_io_lsq_bits_uop_trigger;
  wire               g_io_lsq_bits_uop_ftqPtr_flag, x_io_lsq_bits_uop_ftqPtr_flag;
  wire [5:0]         g_io_lsq_bits_uop_ftqPtr_value, x_io_lsq_bits_uop_ftqPtr_value;
  wire [3:0]         g_io_lsq_bits_uop_ftqOffset, x_io_lsq_bits_uop_ftqOffset;
  wire [34:0]        g_io_lsq_bits_uop_fuType, x_io_lsq_bits_uop_fuType;
  wire [8:0]         g_io_lsq_bits_uop_fuOpType, x_io_lsq_bits_uop_fuOpType;
  wire               g_io_lsq_bits_uop_rfWen, x_io_lsq_bits_uop_rfWen;
  wire [2:0]         g_io_lsq_bits_uop_vpu_nf, x_io_lsq_bits_uop_vpu_nf;
  wire [1:0]         g_io_lsq_bits_uop_vpu_veew, x_io_lsq_bits_uop_vpu_veew;
  wire [6:0]         g_io_lsq_bits_uop_uopIdx, x_io_lsq_bits_uop_uopIdx;
  wire [7:0]         g_io_lsq_bits_uop_pdest, x_io_lsq_bits_uop_pdest;
  wire               g_io_lsq_bits_uop_robIdx_flag, x_io_lsq_bits_uop_robIdx_flag;
  wire [7:0]         g_io_lsq_bits_uop_robIdx_value, x_io_lsq_bits_uop_robIdx_value;
  wire               g_io_lsq_bits_uop_debugInfo_eliminatedMove, x_io_lsq_bits_uop_debugInfo_eliminatedMove;
  wire [63:0]        g_io_lsq_bits_uop_debugInfo_renameTime, x_io_lsq_bits_uop_debugInfo_renameTime;
  wire [63:0]        g_io_lsq_bits_uop_debugInfo_dispatchTime, x_io_lsq_bits_uop_debugInfo_dispatchTime;
  wire [63:0]        g_io_lsq_bits_uop_debugInfo_enqRsTime, x_io_lsq_bits_uop_debugInfo_enqRsTime;
  wire [63:0]        g_io_lsq_bits_uop_debugInfo_selectTime, x_io_lsq_bits_uop_debugInfo_selectTime;
  wire [63:0]        g_io_lsq_bits_uop_debugInfo_issueTime, x_io_lsq_bits_uop_debugInfo_issueTime;
  wire [63:0]        g_io_lsq_bits_uop_debugInfo_writebackTime, x_io_lsq_bits_uop_debugInfo_writebackTime;
  wire [63:0]        g_io_lsq_bits_uop_debugInfo_runahead_checkpoint_id, x_io_lsq_bits_uop_debugInfo_runahead_checkpoint_id;
  wire [63:0]        g_io_lsq_bits_uop_debugInfo_tlbFirstReqTime, x_io_lsq_bits_uop_debugInfo_tlbFirstReqTime;
  wire [63:0]        g_io_lsq_bits_uop_debugInfo_tlbRespTime, x_io_lsq_bits_uop_debugInfo_tlbRespTime;
  wire [55:0]        g_io_lsq_bits_uop_debug_seqNum_seqNum, x_io_lsq_bits_uop_debug_seqNum_seqNum;
  wire [7:0]         g_io_lsq_bits_uop_debug_seqNum_uopIdx, x_io_lsq_bits_uop_debug_seqNum_uopIdx;
  wire               g_io_lsq_bits_uop_sqIdx_flag, x_io_lsq_bits_uop_sqIdx_flag;
  wire [5:0]         g_io_lsq_bits_uop_sqIdx_value, x_io_lsq_bits_uop_sqIdx_value;
  wire [49:0]        g_io_lsq_bits_vaddr, x_io_lsq_bits_vaddr;
  wire [63:0]        g_io_lsq_bits_fullva, x_io_lsq_bits_fullva;
  wire               g_io_lsq_bits_vaNeedExt, x_io_lsq_bits_vaNeedExt;
  wire [47:0]        g_io_lsq_bits_paddr, x_io_lsq_bits_paddr;
  wire [63:0]        g_io_lsq_bits_gpaddr, x_io_lsq_bits_gpaddr;
  wire [15:0]        g_io_lsq_bits_mask, x_io_lsq_bits_mask;
  wire               g_io_lsq_bits_wlineflag, x_io_lsq_bits_wlineflag;
  wire               g_io_lsq_bits_miss, x_io_lsq_bits_miss;
  wire               g_io_lsq_bits_nc, x_io_lsq_bits_nc;
  wire               g_io_lsq_bits_isHyper, x_io_lsq_bits_isHyper;
  wire               g_io_lsq_bits_isForVSnonLeafPTE, x_io_lsq_bits_isForVSnonLeafPTE;
  wire               g_io_lsq_bits_isvec, x_io_lsq_bits_isvec;
  wire               g_io_lsq_bits_isFrmMisAlignBuf, x_io_lsq_bits_isFrmMisAlignBuf;
  wire               g_io_lsq_bits_isMisalign, x_io_lsq_bits_isMisalign;
  wire               g_io_lsq_bits_misalignWith16Byte, x_io_lsq_bits_misalignWith16Byte;
  wire               g_io_lsq_bits_updateAddrValid, x_io_lsq_bits_updateAddrValid;
  wire               g_io_lsq_replenish_uop_exceptionVec_3, x_io_lsq_replenish_uop_exceptionVec_3;
  wire               g_io_lsq_replenish_uop_exceptionVec_6, x_io_lsq_replenish_uop_exceptionVec_6;
  wire               g_io_lsq_replenish_uop_exceptionVec_15, x_io_lsq_replenish_uop_exceptionVec_15;
  wire               g_io_lsq_replenish_uop_exceptionVec_19, x_io_lsq_replenish_uop_exceptionVec_19;
  wire               g_io_lsq_replenish_uop_exceptionVec_23, x_io_lsq_replenish_uop_exceptionVec_23;
  wire [6:0]         g_io_lsq_replenish_uop_uopIdx, x_io_lsq_replenish_uop_uopIdx;
  wire               g_io_lsq_replenish_uop_robIdx_flag, x_io_lsq_replenish_uop_robIdx_flag;
  wire [7:0]         g_io_lsq_replenish_uop_robIdx_value, x_io_lsq_replenish_uop_robIdx_value;
  wire [63:0]        g_io_lsq_replenish_fullva, x_io_lsq_replenish_fullva;
  wire               g_io_lsq_replenish_vaNeedExt, x_io_lsq_replenish_vaNeedExt;
  wire [63:0]        g_io_lsq_replenish_gpaddr, x_io_lsq_replenish_gpaddr;
  wire               g_io_lsq_replenish_af, x_io_lsq_replenish_af;
  wire               g_io_lsq_replenish_mmio, x_io_lsq_replenish_mmio;
  wire               g_io_lsq_replenish_memBackTypeMM, x_io_lsq_replenish_memBackTypeMM;
  wire               g_io_lsq_replenish_hasException, x_io_lsq_replenish_hasException;
  wire               g_io_lsq_replenish_isHyper, x_io_lsq_replenish_isHyper;
  wire               g_io_lsq_replenish_isForVSnonLeafPTE, x_io_lsq_replenish_isForVSnonLeafPTE;
  wire               g_io_lsq_replenish_isvec, x_io_lsq_replenish_isvec;
  wire               g_io_lsq_replenish_updateAddrValid, x_io_lsq_replenish_updateAddrValid;
  wire               g_io_feedback_slow_valid, x_io_feedback_slow_valid;
  wire               g_io_feedback_slow_bits_robIdx_flag, x_io_feedback_slow_bits_robIdx_flag;
  wire [7:0]         g_io_feedback_slow_bits_robIdx_value, x_io_feedback_slow_bits_robIdx_value;
  wire               g_io_feedback_slow_bits_hit, x_io_feedback_slow_bits_hit;
  wire               g_io_feedback_slow_bits_flushState, x_io_feedback_slow_bits_flushState;
  wire               g_io_feedback_slow_bits_sqIdx_flag, x_io_feedback_slow_bits_sqIdx_flag;
  wire [5:0]         g_io_feedback_slow_bits_sqIdx_value, x_io_feedback_slow_bits_sqIdx_value;
  wire               g_io_feedback_slow_bits_lqIdx_flag, x_io_feedback_slow_bits_lqIdx_flag;
  wire [6:0]         g_io_feedback_slow_bits_lqIdx_value, x_io_feedback_slow_bits_lqIdx_value;
  wire               g_io_stld_nuke_query_valid, x_io_stld_nuke_query_valid;
  wire               g_io_stld_nuke_query_bits_robIdx_flag, x_io_stld_nuke_query_bits_robIdx_flag;
  wire [7:0]         g_io_stld_nuke_query_bits_robIdx_value, x_io_stld_nuke_query_bits_robIdx_value;
  wire [47:0]        g_io_stld_nuke_query_bits_paddr, x_io_stld_nuke_query_bits_paddr;
  wire [15:0]        g_io_stld_nuke_query_bits_mask, x_io_stld_nuke_query_bits_mask;
  wire [1:0]         g_io_stld_nuke_query_bits_matchType, x_io_stld_nuke_query_bits_matchType;
  wire               g_io_stout_valid, x_io_stout_valid;
  wire               g_io_stout_bits_uop_exceptionVec_3, x_io_stout_bits_uop_exceptionVec_3;
  wire               g_io_stout_bits_uop_exceptionVec_6, x_io_stout_bits_uop_exceptionVec_6;
  wire               g_io_stout_bits_uop_exceptionVec_7, x_io_stout_bits_uop_exceptionVec_7;
  wire               g_io_stout_bits_uop_exceptionVec_15, x_io_stout_bits_uop_exceptionVec_15;
  wire               g_io_stout_bits_uop_exceptionVec_19, x_io_stout_bits_uop_exceptionVec_19;
  wire               g_io_stout_bits_uop_exceptionVec_23, x_io_stout_bits_uop_exceptionVec_23;
  wire [3:0]         g_io_stout_bits_uop_trigger, x_io_stout_bits_uop_trigger;
  wire               g_io_stout_bits_uop_rfWen, x_io_stout_bits_uop_rfWen;
  wire [7:0]         g_io_stout_bits_uop_pdest, x_io_stout_bits_uop_pdest;
  wire               g_io_stout_bits_uop_robIdx_flag, x_io_stout_bits_uop_robIdx_flag;
  wire [7:0]         g_io_stout_bits_uop_robIdx_value, x_io_stout_bits_uop_robIdx_value;
  wire               g_io_stout_bits_uop_debugInfo_eliminatedMove, x_io_stout_bits_uop_debugInfo_eliminatedMove;
  wire [63:0]        g_io_stout_bits_uop_debugInfo_renameTime, x_io_stout_bits_uop_debugInfo_renameTime;
  wire [63:0]        g_io_stout_bits_uop_debugInfo_dispatchTime, x_io_stout_bits_uop_debugInfo_dispatchTime;
  wire [63:0]        g_io_stout_bits_uop_debugInfo_enqRsTime, x_io_stout_bits_uop_debugInfo_enqRsTime;
  wire [63:0]        g_io_stout_bits_uop_debugInfo_selectTime, x_io_stout_bits_uop_debugInfo_selectTime;
  wire [63:0]        g_io_stout_bits_uop_debugInfo_issueTime, x_io_stout_bits_uop_debugInfo_issueTime;
  wire [63:0]        g_io_stout_bits_uop_debugInfo_writebackTime, x_io_stout_bits_uop_debugInfo_writebackTime;
  wire [63:0]        g_io_stout_bits_uop_debugInfo_runahead_checkpoint_id, x_io_stout_bits_uop_debugInfo_runahead_checkpoint_id;
  wire [63:0]        g_io_stout_bits_uop_debugInfo_tlbFirstReqTime, x_io_stout_bits_uop_debugInfo_tlbFirstReqTime;
  wire [63:0]        g_io_stout_bits_uop_debugInfo_tlbRespTime, x_io_stout_bits_uop_debugInfo_tlbRespTime;
  wire [55:0]        g_io_stout_bits_uop_debug_seqNum_seqNum, x_io_stout_bits_uop_debug_seqNum_seqNum;
  wire [7:0]         g_io_stout_bits_uop_debug_seqNum_uopIdx, x_io_stout_bits_uop_debug_seqNum_uopIdx;
  wire               g_io_stout_bits_uop_sqIdx_flag, x_io_stout_bits_uop_sqIdx_flag;
  wire [5:0]         g_io_stout_bits_uop_sqIdx_value, x_io_stout_bits_uop_sqIdx_value;
  wire               g_io_stout_bits_debug_isMMIO, x_io_stout_bits_debug_isMMIO;
  wire               g_io_stout_bits_debug_isNCIO, x_io_stout_bits_debug_isNCIO;
  wire [47:0]        g_io_stout_bits_debug_paddr, x_io_stout_bits_debug_paddr;
  wire [49:0]        g_io_stout_bits_debug_vaddr, x_io_stout_bits_debug_vaddr;
  wire               g_io_vecstout_valid, x_io_vecstout_valid;
  wire [3:0]         g_io_vecstout_bits_mBIndex, x_io_vecstout_bits_mBIndex;
  wire               g_io_vecstout_bits_hit, x_io_vecstout_bits_hit;
  wire [3:0]         g_io_vecstout_bits_trigger, x_io_vecstout_bits_trigger;
  wire               g_io_vecstout_bits_exceptionVec_3, x_io_vecstout_bits_exceptionVec_3;
  wire               g_io_vecstout_bits_exceptionVec_6, x_io_vecstout_bits_exceptionVec_6;
  wire               g_io_vecstout_bits_exceptionVec_7, x_io_vecstout_bits_exceptionVec_7;
  wire               g_io_vecstout_bits_exceptionVec_15, x_io_vecstout_bits_exceptionVec_15;
  wire               g_io_vecstout_bits_exceptionVec_19, x_io_vecstout_bits_exceptionVec_19;
  wire               g_io_vecstout_bits_exceptionVec_23, x_io_vecstout_bits_exceptionVec_23;
  wire               g_io_vecstout_bits_hasException, x_io_vecstout_bits_hasException;
  wire [63:0]        g_io_vecstout_bits_vaddr, x_io_vecstout_bits_vaddr;
  wire               g_io_vecstout_bits_vaNeedExt, x_io_vecstout_bits_vaNeedExt;
  wire [63:0]        g_io_vecstout_bits_gpaddr, x_io_vecstout_bits_gpaddr;
  wire               g_io_vecstout_bits_isForVSnonLeafPTE, x_io_vecstout_bits_isForVSnonLeafPTE;
  wire [7:0]         g_io_vecstout_bits_vstart, x_io_vecstout_bits_vstart;
  wire [7:0]         g_io_vecstout_bits_elemIdx, x_io_vecstout_bits_elemIdx;
  wire [15:0]        g_io_vecstout_bits_mask, x_io_vecstout_bits_mask;
  wire [4:0]         g_io_vecstout_bits_splitIndex, x_io_vecstout_bits_splitIndex;
  wire               g_io_st_mask_out_valid, x_io_st_mask_out_valid;
  wire [5:0]         g_io_st_mask_out_bits_sqIdx_value, x_io_st_mask_out_bits_sqIdx_value;
  wire [15:0]        g_io_st_mask_out_bits_mask, x_io_st_mask_out_bits_mask;
  wire               g_io_vecstin_ready, x_io_vecstin_ready;
  wire               g_io_misalign_enq_req_valid, x_io_misalign_enq_req_valid;
  wire               g_io_misalign_enq_req_bits_uop_exceptionVec_0, x_io_misalign_enq_req_bits_uop_exceptionVec_0;
  wire               g_io_misalign_enq_req_bits_uop_exceptionVec_1, x_io_misalign_enq_req_bits_uop_exceptionVec_1;
  wire               g_io_misalign_enq_req_bits_uop_exceptionVec_2, x_io_misalign_enq_req_bits_uop_exceptionVec_2;
  wire               g_io_misalign_enq_req_bits_uop_exceptionVec_4, x_io_misalign_enq_req_bits_uop_exceptionVec_4;
  wire               g_io_misalign_enq_req_bits_uop_exceptionVec_5, x_io_misalign_enq_req_bits_uop_exceptionVec_5;
  wire               g_io_misalign_enq_req_bits_uop_exceptionVec_8, x_io_misalign_enq_req_bits_uop_exceptionVec_8;
  wire               g_io_misalign_enq_req_bits_uop_exceptionVec_9, x_io_misalign_enq_req_bits_uop_exceptionVec_9;
  wire               g_io_misalign_enq_req_bits_uop_exceptionVec_10, x_io_misalign_enq_req_bits_uop_exceptionVec_10;
  wire               g_io_misalign_enq_req_bits_uop_exceptionVec_11, x_io_misalign_enq_req_bits_uop_exceptionVec_11;
  wire               g_io_misalign_enq_req_bits_uop_exceptionVec_12, x_io_misalign_enq_req_bits_uop_exceptionVec_12;
  wire               g_io_misalign_enq_req_bits_uop_exceptionVec_13, x_io_misalign_enq_req_bits_uop_exceptionVec_13;
  wire               g_io_misalign_enq_req_bits_uop_exceptionVec_14, x_io_misalign_enq_req_bits_uop_exceptionVec_14;
  wire               g_io_misalign_enq_req_bits_uop_exceptionVec_16, x_io_misalign_enq_req_bits_uop_exceptionVec_16;
  wire               g_io_misalign_enq_req_bits_uop_exceptionVec_17, x_io_misalign_enq_req_bits_uop_exceptionVec_17;
  wire               g_io_misalign_enq_req_bits_uop_exceptionVec_18, x_io_misalign_enq_req_bits_uop_exceptionVec_18;
  wire               g_io_misalign_enq_req_bits_uop_exceptionVec_19, x_io_misalign_enq_req_bits_uop_exceptionVec_19;
  wire               g_io_misalign_enq_req_bits_uop_exceptionVec_20, x_io_misalign_enq_req_bits_uop_exceptionVec_20;
  wire               g_io_misalign_enq_req_bits_uop_exceptionVec_21, x_io_misalign_enq_req_bits_uop_exceptionVec_21;
  wire               g_io_misalign_enq_req_bits_uop_exceptionVec_22, x_io_misalign_enq_req_bits_uop_exceptionVec_22;
  wire [3:0]         g_io_misalign_enq_req_bits_uop_trigger, x_io_misalign_enq_req_bits_uop_trigger;
  wire               g_io_misalign_enq_req_bits_uop_ftqPtr_flag, x_io_misalign_enq_req_bits_uop_ftqPtr_flag;
  wire [5:0]         g_io_misalign_enq_req_bits_uop_ftqPtr_value, x_io_misalign_enq_req_bits_uop_ftqPtr_value;
  wire [3:0]         g_io_misalign_enq_req_bits_uop_ftqOffset, x_io_misalign_enq_req_bits_uop_ftqOffset;
  wire [34:0]        g_io_misalign_enq_req_bits_uop_fuType, x_io_misalign_enq_req_bits_uop_fuType;
  wire [8:0]         g_io_misalign_enq_req_bits_uop_fuOpType, x_io_misalign_enq_req_bits_uop_fuOpType;
  wire               g_io_misalign_enq_req_bits_uop_rfWen, x_io_misalign_enq_req_bits_uop_rfWen;
  wire [7:0]         g_io_misalign_enq_req_bits_uop_vpu_vstart, x_io_misalign_enq_req_bits_uop_vpu_vstart;
  wire [2:0]         g_io_misalign_enq_req_bits_uop_vpu_nf, x_io_misalign_enq_req_bits_uop_vpu_nf;
  wire [1:0]         g_io_misalign_enq_req_bits_uop_vpu_veew, x_io_misalign_enq_req_bits_uop_vpu_veew;
  wire [6:0]         g_io_misalign_enq_req_bits_uop_uopIdx, x_io_misalign_enq_req_bits_uop_uopIdx;
  wire [7:0]         g_io_misalign_enq_req_bits_uop_pdest, x_io_misalign_enq_req_bits_uop_pdest;
  wire               g_io_misalign_enq_req_bits_uop_robIdx_flag, x_io_misalign_enq_req_bits_uop_robIdx_flag;
  wire [7:0]         g_io_misalign_enq_req_bits_uop_robIdx_value, x_io_misalign_enq_req_bits_uop_robIdx_value;
  wire               g_io_misalign_enq_req_bits_uop_debugInfo_eliminatedMove, x_io_misalign_enq_req_bits_uop_debugInfo_eliminatedMove;
  wire [63:0]        g_io_misalign_enq_req_bits_uop_debugInfo_renameTime, x_io_misalign_enq_req_bits_uop_debugInfo_renameTime;
  wire [63:0]        g_io_misalign_enq_req_bits_uop_debugInfo_dispatchTime, x_io_misalign_enq_req_bits_uop_debugInfo_dispatchTime;
  wire [63:0]        g_io_misalign_enq_req_bits_uop_debugInfo_enqRsTime, x_io_misalign_enq_req_bits_uop_debugInfo_enqRsTime;
  wire [63:0]        g_io_misalign_enq_req_bits_uop_debugInfo_selectTime, x_io_misalign_enq_req_bits_uop_debugInfo_selectTime;
  wire [63:0]        g_io_misalign_enq_req_bits_uop_debugInfo_issueTime, x_io_misalign_enq_req_bits_uop_debugInfo_issueTime;
  wire [63:0]        g_io_misalign_enq_req_bits_uop_debugInfo_writebackTime, x_io_misalign_enq_req_bits_uop_debugInfo_writebackTime;
  wire [63:0]        g_io_misalign_enq_req_bits_uop_debugInfo_runahead_checkpoint_id, x_io_misalign_enq_req_bits_uop_debugInfo_runahead_checkpoint_id;
  wire [63:0]        g_io_misalign_enq_req_bits_uop_debugInfo_tlbFirstReqTime, x_io_misalign_enq_req_bits_uop_debugInfo_tlbFirstReqTime;
  wire [63:0]        g_io_misalign_enq_req_bits_uop_debugInfo_tlbRespTime, x_io_misalign_enq_req_bits_uop_debugInfo_tlbRespTime;
  wire [55:0]        g_io_misalign_enq_req_bits_uop_debug_seqNum_seqNum, x_io_misalign_enq_req_bits_uop_debug_seqNum_seqNum;
  wire [7:0]         g_io_misalign_enq_req_bits_uop_debug_seqNum_uopIdx, x_io_misalign_enq_req_bits_uop_debug_seqNum_uopIdx;
  wire               g_io_misalign_enq_req_bits_uop_lqIdx_flag, x_io_misalign_enq_req_bits_uop_lqIdx_flag;
  wire [6:0]         g_io_misalign_enq_req_bits_uop_lqIdx_value, x_io_misalign_enq_req_bits_uop_lqIdx_value;
  wire               g_io_misalign_enq_req_bits_uop_sqIdx_flag, x_io_misalign_enq_req_bits_uop_sqIdx_flag;
  wire [5:0]         g_io_misalign_enq_req_bits_uop_sqIdx_value, x_io_misalign_enq_req_bits_uop_sqIdx_value;
  wire [49:0]        g_io_misalign_enq_req_bits_vaddr, x_io_misalign_enq_req_bits_vaddr;
  wire [15:0]        g_io_misalign_enq_req_bits_mask, x_io_misalign_enq_req_bits_mask;
  wire               g_io_misalign_enq_req_bits_isvec, x_io_misalign_enq_req_bits_isvec;
  wire [7:0]         g_io_misalign_enq_req_bits_elemIdx, x_io_misalign_enq_req_bits_elemIdx;
  wire [2:0]         g_io_misalign_enq_req_bits_alignedType, x_io_misalign_enq_req_bits_alignedType;
  wire [3:0]         g_io_misalign_enq_req_bits_mbIndex, x_io_misalign_enq_req_bits_mbIndex;
  wire [4:0]         g_io_misalign_enq_req_bits_splitIndex, x_io_misalign_enq_req_bits_splitIndex;
  wire               g_io_misalign_enq_revoke, x_io_misalign_enq_revoke;

  StoreUnit u_golden (
    .clock (clock),
    .reset (reset),
    .io_redirect_valid (io_redirect_valid),
    .io_redirect_bits_robIdx_flag (io_redirect_bits_robIdx_flag),
    .io_redirect_bits_robIdx_value (io_redirect_bits_robIdx_value),
    .io_redirect_bits_level (io_redirect_bits_level),
    .io_csrCtrl_hd_misalign_st_enable (io_csrCtrl_hd_misalign_st_enable),
    .io_stin_ready (g_io_stin_ready),
    .io_stin_valid (io_stin_valid),
    .io_stin_bits_uop_ftqPtr_flag (io_stin_bits_uop_ftqPtr_flag),
    .io_stin_bits_uop_ftqPtr_value (io_stin_bits_uop_ftqPtr_value),
    .io_stin_bits_uop_ftqOffset (io_stin_bits_uop_ftqOffset),
    .io_stin_bits_uop_fuType (io_stin_bits_uop_fuType),
    .io_stin_bits_uop_fuOpType (io_stin_bits_uop_fuOpType),
    .io_stin_bits_uop_rfWen (io_stin_bits_uop_rfWen),
    .io_stin_bits_uop_imm (io_stin_bits_uop_imm),
    .io_stin_bits_uop_pdest (io_stin_bits_uop_pdest),
    .io_stin_bits_uop_robIdx_flag (io_stin_bits_uop_robIdx_flag),
    .io_stin_bits_uop_robIdx_value (io_stin_bits_uop_robIdx_value),
    .io_stin_bits_uop_debugInfo_eliminatedMove (io_stin_bits_uop_debugInfo_eliminatedMove),
    .io_stin_bits_uop_debugInfo_renameTime (io_stin_bits_uop_debugInfo_renameTime),
    .io_stin_bits_uop_debugInfo_dispatchTime (io_stin_bits_uop_debugInfo_dispatchTime),
    .io_stin_bits_uop_debugInfo_enqRsTime (io_stin_bits_uop_debugInfo_enqRsTime),
    .io_stin_bits_uop_debugInfo_selectTime (io_stin_bits_uop_debugInfo_selectTime),
    .io_stin_bits_uop_debugInfo_issueTime (io_stin_bits_uop_debugInfo_issueTime),
    .io_stin_bits_uop_debugInfo_writebackTime (io_stin_bits_uop_debugInfo_writebackTime),
    .io_stin_bits_uop_debugInfo_runahead_checkpoint_id (io_stin_bits_uop_debugInfo_runahead_checkpoint_id),
    .io_stin_bits_uop_debugInfo_tlbFirstReqTime (io_stin_bits_uop_debugInfo_tlbFirstReqTime),
    .io_stin_bits_uop_debugInfo_tlbRespTime (io_stin_bits_uop_debugInfo_tlbRespTime),
    .io_stin_bits_uop_debug_seqNum_seqNum (io_stin_bits_uop_debug_seqNum_seqNum),
    .io_stin_bits_uop_debug_seqNum_uopIdx (io_stin_bits_uop_debug_seqNum_uopIdx),
    .io_stin_bits_uop_lqIdx_flag (io_stin_bits_uop_lqIdx_flag),
    .io_stin_bits_uop_lqIdx_value (io_stin_bits_uop_lqIdx_value),
    .io_stin_bits_uop_sqIdx_flag (io_stin_bits_uop_sqIdx_flag),
    .io_stin_bits_uop_sqIdx_value (io_stin_bits_uop_sqIdx_value),
    .io_stin_bits_src_0 (io_stin_bits_src_0),
    .io_stin_bits_isFirstIssue (io_stin_bits_isFirstIssue),
    .io_issue_valid (g_io_issue_valid),
    .io_issue_bits_uop_robIdx_flag (g_io_issue_bits_uop_robIdx_flag),
    .io_issue_bits_uop_robIdx_value (g_io_issue_bits_uop_robIdx_value),
    .io_misalign_stin_ready (g_io_misalign_stin_ready),
    .io_misalign_stin_valid (io_misalign_stin_valid),
    .io_misalign_stin_bits_uop_exceptionVec_0 (io_misalign_stin_bits_uop_exceptionVec_0),
    .io_misalign_stin_bits_uop_exceptionVec_1 (io_misalign_stin_bits_uop_exceptionVec_1),
    .io_misalign_stin_bits_uop_exceptionVec_2 (io_misalign_stin_bits_uop_exceptionVec_2),
    .io_misalign_stin_bits_uop_exceptionVec_4 (io_misalign_stin_bits_uop_exceptionVec_4),
    .io_misalign_stin_bits_uop_exceptionVec_5 (io_misalign_stin_bits_uop_exceptionVec_5),
    .io_misalign_stin_bits_uop_exceptionVec_8 (io_misalign_stin_bits_uop_exceptionVec_8),
    .io_misalign_stin_bits_uop_exceptionVec_9 (io_misalign_stin_bits_uop_exceptionVec_9),
    .io_misalign_stin_bits_uop_exceptionVec_10 (io_misalign_stin_bits_uop_exceptionVec_10),
    .io_misalign_stin_bits_uop_exceptionVec_11 (io_misalign_stin_bits_uop_exceptionVec_11),
    .io_misalign_stin_bits_uop_exceptionVec_12 (io_misalign_stin_bits_uop_exceptionVec_12),
    .io_misalign_stin_bits_uop_exceptionVec_13 (io_misalign_stin_bits_uop_exceptionVec_13),
    .io_misalign_stin_bits_uop_exceptionVec_14 (io_misalign_stin_bits_uop_exceptionVec_14),
    .io_misalign_stin_bits_uop_exceptionVec_16 (io_misalign_stin_bits_uop_exceptionVec_16),
    .io_misalign_stin_bits_uop_exceptionVec_17 (io_misalign_stin_bits_uop_exceptionVec_17),
    .io_misalign_stin_bits_uop_exceptionVec_18 (io_misalign_stin_bits_uop_exceptionVec_18),
    .io_misalign_stin_bits_uop_exceptionVec_19 (io_misalign_stin_bits_uop_exceptionVec_19),
    .io_misalign_stin_bits_uop_exceptionVec_20 (io_misalign_stin_bits_uop_exceptionVec_20),
    .io_misalign_stin_bits_uop_exceptionVec_21 (io_misalign_stin_bits_uop_exceptionVec_21),
    .io_misalign_stin_bits_uop_exceptionVec_22 (io_misalign_stin_bits_uop_exceptionVec_22),
    .io_misalign_stin_bits_uop_trigger (io_misalign_stin_bits_uop_trigger),
    .io_misalign_stin_bits_uop_ftqPtr_flag (io_misalign_stin_bits_uop_ftqPtr_flag),
    .io_misalign_stin_bits_uop_ftqPtr_value (io_misalign_stin_bits_uop_ftqPtr_value),
    .io_misalign_stin_bits_uop_ftqOffset (io_misalign_stin_bits_uop_ftqOffset),
    .io_misalign_stin_bits_uop_fuType (io_misalign_stin_bits_uop_fuType),
    .io_misalign_stin_bits_uop_fuOpType (io_misalign_stin_bits_uop_fuOpType),
    .io_misalign_stin_bits_uop_rfWen (io_misalign_stin_bits_uop_rfWen),
    .io_misalign_stin_bits_uop_vpu_vstart (io_misalign_stin_bits_uop_vpu_vstart),
    .io_misalign_stin_bits_uop_vpu_nf (io_misalign_stin_bits_uop_vpu_nf),
    .io_misalign_stin_bits_uop_vpu_veew (io_misalign_stin_bits_uop_vpu_veew),
    .io_misalign_stin_bits_uop_uopIdx (io_misalign_stin_bits_uop_uopIdx),
    .io_misalign_stin_bits_uop_pdest (io_misalign_stin_bits_uop_pdest),
    .io_misalign_stin_bits_uop_robIdx_flag (io_misalign_stin_bits_uop_robIdx_flag),
    .io_misalign_stin_bits_uop_robIdx_value (io_misalign_stin_bits_uop_robIdx_value),
    .io_misalign_stin_bits_uop_debugInfo_eliminatedMove (io_misalign_stin_bits_uop_debugInfo_eliminatedMove),
    .io_misalign_stin_bits_uop_debugInfo_renameTime (io_misalign_stin_bits_uop_debugInfo_renameTime),
    .io_misalign_stin_bits_uop_debugInfo_dispatchTime (io_misalign_stin_bits_uop_debugInfo_dispatchTime),
    .io_misalign_stin_bits_uop_debugInfo_enqRsTime (io_misalign_stin_bits_uop_debugInfo_enqRsTime),
    .io_misalign_stin_bits_uop_debugInfo_selectTime (io_misalign_stin_bits_uop_debugInfo_selectTime),
    .io_misalign_stin_bits_uop_debugInfo_issueTime (io_misalign_stin_bits_uop_debugInfo_issueTime),
    .io_misalign_stin_bits_uop_debugInfo_writebackTime (io_misalign_stin_bits_uop_debugInfo_writebackTime),
    .io_misalign_stin_bits_uop_debugInfo_runahead_checkpoint_id (io_misalign_stin_bits_uop_debugInfo_runahead_checkpoint_id),
    .io_misalign_stin_bits_uop_debugInfo_tlbFirstReqTime (io_misalign_stin_bits_uop_debugInfo_tlbFirstReqTime),
    .io_misalign_stin_bits_uop_debugInfo_tlbRespTime (io_misalign_stin_bits_uop_debugInfo_tlbRespTime),
    .io_misalign_stin_bits_uop_debug_seqNum_seqNum (io_misalign_stin_bits_uop_debug_seqNum_seqNum),
    .io_misalign_stin_bits_uop_debug_seqNum_uopIdx (io_misalign_stin_bits_uop_debug_seqNum_uopIdx),
    .io_misalign_stin_bits_uop_lqIdx_flag (io_misalign_stin_bits_uop_lqIdx_flag),
    .io_misalign_stin_bits_uop_lqIdx_value (io_misalign_stin_bits_uop_lqIdx_value),
    .io_misalign_stin_bits_uop_sqIdx_flag (io_misalign_stin_bits_uop_sqIdx_flag),
    .io_misalign_stin_bits_uop_sqIdx_value (io_misalign_stin_bits_uop_sqIdx_value),
    .io_misalign_stin_bits_vaddr (io_misalign_stin_bits_vaddr),
    .io_misalign_stin_bits_mask (io_misalign_stin_bits_mask),
    .io_misalign_stin_bits_isvec (io_misalign_stin_bits_isvec),
    .io_misalign_stin_bits_is128bit (io_misalign_stin_bits_is128bit),
    .io_misalign_stin_bits_isFinalSplit (io_misalign_stin_bits_isFinalSplit),
    .io_misalign_stout_valid (g_io_misalign_stout_valid),
    .io_misalign_stout_bits_uop_exceptionVec_3 (g_io_misalign_stout_bits_uop_exceptionVec_3),
    .io_misalign_stout_bits_uop_exceptionVec_6 (g_io_misalign_stout_bits_uop_exceptionVec_6),
    .io_misalign_stout_bits_uop_exceptionVec_7 (g_io_misalign_stout_bits_uop_exceptionVec_7),
    .io_misalign_stout_bits_uop_exceptionVec_15 (g_io_misalign_stout_bits_uop_exceptionVec_15),
    .io_misalign_stout_bits_uop_exceptionVec_19 (g_io_misalign_stout_bits_uop_exceptionVec_19),
    .io_misalign_stout_bits_uop_exceptionVec_23 (g_io_misalign_stout_bits_uop_exceptionVec_23),
    .io_misalign_stout_bits_uop_trigger (g_io_misalign_stout_bits_uop_trigger),
    .io_misalign_stout_bits_uop_robIdx_flag (g_io_misalign_stout_bits_uop_robIdx_flag),
    .io_misalign_stout_bits_uop_robIdx_value (g_io_misalign_stout_bits_uop_robIdx_value),
    .io_misalign_stout_bits_vaddr (g_io_misalign_stout_bits_vaddr),
    .io_misalign_stout_bits_vaNeedExt (g_io_misalign_stout_bits_vaNeedExt),
    .io_misalign_stout_bits_paddr (g_io_misalign_stout_bits_paddr),
    .io_misalign_stout_bits_gpaddr (g_io_misalign_stout_bits_gpaddr),
    .io_misalign_stout_bits_nc (g_io_misalign_stout_bits_nc),
    .io_misalign_stout_bits_mmio (g_io_misalign_stout_bits_mmio),
    .io_misalign_stout_bits_memBackTypeMM (g_io_misalign_stout_bits_memBackTypeMM),
    .io_misalign_stout_bits_isForVSnonLeafPTE (g_io_misalign_stout_bits_isForVSnonLeafPTE),
    .io_misalign_stout_bits_vecActive (g_io_misalign_stout_bits_vecActive),
    .io_misalign_stout_bits_need_rep (g_io_misalign_stout_bits_need_rep),
    .io_tlb_req_valid (g_io_tlb_req_valid),
    .io_tlb_req_bits_vaddr (g_io_tlb_req_bits_vaddr),
    .io_tlb_req_bits_fullva (g_io_tlb_req_bits_fullva),
    .io_tlb_req_bits_checkfullva (g_io_tlb_req_bits_checkfullva),
    .io_tlb_req_bits_cmd (g_io_tlb_req_bits_cmd),
    .io_tlb_req_bits_hyperinst (g_io_tlb_req_bits_hyperinst),
    .io_tlb_req_bits_memidx_idx (g_io_tlb_req_bits_memidx_idx),
    .io_tlb_req_bits_frm_mabuf (g_io_tlb_req_bits_frm_mabuf),
    .io_tlb_req_bits_debug_robIdx_flag (g_io_tlb_req_bits_debug_robIdx_flag),
    .io_tlb_req_bits_debug_robIdx_value (g_io_tlb_req_bits_debug_robIdx_value),
    .io_tlb_req_bits_debug_isFirstIssue (g_io_tlb_req_bits_debug_isFirstIssue),
    .io_tlb_resp_valid (io_tlb_resp_valid),
    .io_tlb_resp_bits_paddr_0 (io_tlb_resp_bits_paddr_0),
    .io_tlb_resp_bits_gpaddr_0 (io_tlb_resp_bits_gpaddr_0),
    .io_tlb_resp_bits_fullva (io_tlb_resp_bits_fullva),
    .io_tlb_resp_bits_pbmt_0 (io_tlb_resp_bits_pbmt_0),
    .io_tlb_resp_bits_miss (io_tlb_resp_bits_miss),
    .io_tlb_resp_bits_isForVSnonLeafPTE (io_tlb_resp_bits_isForVSnonLeafPTE),
    .io_tlb_resp_bits_excp_0_vaNeedExt (io_tlb_resp_bits_excp_0_vaNeedExt),
    .io_tlb_resp_bits_excp_0_isHyper (io_tlb_resp_bits_excp_0_isHyper),
    .io_tlb_resp_bits_excp_0_gpf_ld (io_tlb_resp_bits_excp_0_gpf_ld),
    .io_tlb_resp_bits_excp_0_gpf_st (io_tlb_resp_bits_excp_0_gpf_st),
    .io_tlb_resp_bits_excp_0_pf_ld (io_tlb_resp_bits_excp_0_pf_ld),
    .io_tlb_resp_bits_excp_0_pf_st (io_tlb_resp_bits_excp_0_pf_st),
    .io_tlb_resp_bits_excp_0_af_ld (io_tlb_resp_bits_excp_0_af_ld),
    .io_tlb_resp_bits_excp_0_af_st (io_tlb_resp_bits_excp_0_af_st),
    .io_tlb_resp_bits_ptwBack (io_tlb_resp_bits_ptwBack),
    .io_tlb_resp_bits_memidx_idx (io_tlb_resp_bits_memidx_idx),
    .io_dcache_req_valid (g_io_dcache_req_valid),
    .io_pmp_ld (io_pmp_ld),
    .io_pmp_st (io_pmp_st),
    .io_pmp_mmio (io_pmp_mmio),
    .io_lsq_valid (g_io_lsq_valid),
    .io_lsq_bits_uop_exceptionVec_0 (g_io_lsq_bits_uop_exceptionVec_0),
    .io_lsq_bits_uop_exceptionVec_1 (g_io_lsq_bits_uop_exceptionVec_1),
    .io_lsq_bits_uop_exceptionVec_2 (g_io_lsq_bits_uop_exceptionVec_2),
    .io_lsq_bits_uop_exceptionVec_3 (g_io_lsq_bits_uop_exceptionVec_3),
    .io_lsq_bits_uop_exceptionVec_4 (g_io_lsq_bits_uop_exceptionVec_4),
    .io_lsq_bits_uop_exceptionVec_5 (g_io_lsq_bits_uop_exceptionVec_5),
    .io_lsq_bits_uop_exceptionVec_6 (g_io_lsq_bits_uop_exceptionVec_6),
    .io_lsq_bits_uop_exceptionVec_7 (g_io_lsq_bits_uop_exceptionVec_7),
    .io_lsq_bits_uop_exceptionVec_8 (g_io_lsq_bits_uop_exceptionVec_8),
    .io_lsq_bits_uop_exceptionVec_9 (g_io_lsq_bits_uop_exceptionVec_9),
    .io_lsq_bits_uop_exceptionVec_10 (g_io_lsq_bits_uop_exceptionVec_10),
    .io_lsq_bits_uop_exceptionVec_11 (g_io_lsq_bits_uop_exceptionVec_11),
    .io_lsq_bits_uop_exceptionVec_12 (g_io_lsq_bits_uop_exceptionVec_12),
    .io_lsq_bits_uop_exceptionVec_13 (g_io_lsq_bits_uop_exceptionVec_13),
    .io_lsq_bits_uop_exceptionVec_14 (g_io_lsq_bits_uop_exceptionVec_14),
    .io_lsq_bits_uop_exceptionVec_15 (g_io_lsq_bits_uop_exceptionVec_15),
    .io_lsq_bits_uop_exceptionVec_16 (g_io_lsq_bits_uop_exceptionVec_16),
    .io_lsq_bits_uop_exceptionVec_17 (g_io_lsq_bits_uop_exceptionVec_17),
    .io_lsq_bits_uop_exceptionVec_18 (g_io_lsq_bits_uop_exceptionVec_18),
    .io_lsq_bits_uop_exceptionVec_19 (g_io_lsq_bits_uop_exceptionVec_19),
    .io_lsq_bits_uop_exceptionVec_20 (g_io_lsq_bits_uop_exceptionVec_20),
    .io_lsq_bits_uop_exceptionVec_21 (g_io_lsq_bits_uop_exceptionVec_21),
    .io_lsq_bits_uop_exceptionVec_22 (g_io_lsq_bits_uop_exceptionVec_22),
    .io_lsq_bits_uop_exceptionVec_23 (g_io_lsq_bits_uop_exceptionVec_23),
    .io_lsq_bits_uop_trigger (g_io_lsq_bits_uop_trigger),
    .io_lsq_bits_uop_ftqPtr_flag (g_io_lsq_bits_uop_ftqPtr_flag),
    .io_lsq_bits_uop_ftqPtr_value (g_io_lsq_bits_uop_ftqPtr_value),
    .io_lsq_bits_uop_ftqOffset (g_io_lsq_bits_uop_ftqOffset),
    .io_lsq_bits_uop_fuType (g_io_lsq_bits_uop_fuType),
    .io_lsq_bits_uop_fuOpType (g_io_lsq_bits_uop_fuOpType),
    .io_lsq_bits_uop_rfWen (g_io_lsq_bits_uop_rfWen),
    .io_lsq_bits_uop_vpu_nf (g_io_lsq_bits_uop_vpu_nf),
    .io_lsq_bits_uop_vpu_veew (g_io_lsq_bits_uop_vpu_veew),
    .io_lsq_bits_uop_uopIdx (g_io_lsq_bits_uop_uopIdx),
    .io_lsq_bits_uop_pdest (g_io_lsq_bits_uop_pdest),
    .io_lsq_bits_uop_robIdx_flag (g_io_lsq_bits_uop_robIdx_flag),
    .io_lsq_bits_uop_robIdx_value (g_io_lsq_bits_uop_robIdx_value),
    .io_lsq_bits_uop_debugInfo_eliminatedMove (g_io_lsq_bits_uop_debugInfo_eliminatedMove),
    .io_lsq_bits_uop_debugInfo_renameTime (g_io_lsq_bits_uop_debugInfo_renameTime),
    .io_lsq_bits_uop_debugInfo_dispatchTime (g_io_lsq_bits_uop_debugInfo_dispatchTime),
    .io_lsq_bits_uop_debugInfo_enqRsTime (g_io_lsq_bits_uop_debugInfo_enqRsTime),
    .io_lsq_bits_uop_debugInfo_selectTime (g_io_lsq_bits_uop_debugInfo_selectTime),
    .io_lsq_bits_uop_debugInfo_issueTime (g_io_lsq_bits_uop_debugInfo_issueTime),
    .io_lsq_bits_uop_debugInfo_writebackTime (g_io_lsq_bits_uop_debugInfo_writebackTime),
    .io_lsq_bits_uop_debugInfo_runahead_checkpoint_id (g_io_lsq_bits_uop_debugInfo_runahead_checkpoint_id),
    .io_lsq_bits_uop_debugInfo_tlbFirstReqTime (g_io_lsq_bits_uop_debugInfo_tlbFirstReqTime),
    .io_lsq_bits_uop_debugInfo_tlbRespTime (g_io_lsq_bits_uop_debugInfo_tlbRespTime),
    .io_lsq_bits_uop_debug_seqNum_seqNum (g_io_lsq_bits_uop_debug_seqNum_seqNum),
    .io_lsq_bits_uop_debug_seqNum_uopIdx (g_io_lsq_bits_uop_debug_seqNum_uopIdx),
    .io_lsq_bits_uop_sqIdx_flag (g_io_lsq_bits_uop_sqIdx_flag),
    .io_lsq_bits_uop_sqIdx_value (g_io_lsq_bits_uop_sqIdx_value),
    .io_lsq_bits_vaddr (g_io_lsq_bits_vaddr),
    .io_lsq_bits_fullva (g_io_lsq_bits_fullva),
    .io_lsq_bits_vaNeedExt (g_io_lsq_bits_vaNeedExt),
    .io_lsq_bits_paddr (g_io_lsq_bits_paddr),
    .io_lsq_bits_gpaddr (g_io_lsq_bits_gpaddr),
    .io_lsq_bits_mask (g_io_lsq_bits_mask),
    .io_lsq_bits_wlineflag (g_io_lsq_bits_wlineflag),
    .io_lsq_bits_miss (g_io_lsq_bits_miss),
    .io_lsq_bits_nc (g_io_lsq_bits_nc),
    .io_lsq_bits_isHyper (g_io_lsq_bits_isHyper),
    .io_lsq_bits_isForVSnonLeafPTE (g_io_lsq_bits_isForVSnonLeafPTE),
    .io_lsq_bits_isvec (g_io_lsq_bits_isvec),
    .io_lsq_bits_isFrmMisAlignBuf (g_io_lsq_bits_isFrmMisAlignBuf),
    .io_lsq_bits_isMisalign (g_io_lsq_bits_isMisalign),
    .io_lsq_bits_misalignWith16Byte (g_io_lsq_bits_misalignWith16Byte),
    .io_lsq_bits_updateAddrValid (g_io_lsq_bits_updateAddrValid),
    .io_lsq_replenish_uop_exceptionVec_3 (g_io_lsq_replenish_uop_exceptionVec_3),
    .io_lsq_replenish_uop_exceptionVec_6 (g_io_lsq_replenish_uop_exceptionVec_6),
    .io_lsq_replenish_uop_exceptionVec_15 (g_io_lsq_replenish_uop_exceptionVec_15),
    .io_lsq_replenish_uop_exceptionVec_19 (g_io_lsq_replenish_uop_exceptionVec_19),
    .io_lsq_replenish_uop_exceptionVec_23 (g_io_lsq_replenish_uop_exceptionVec_23),
    .io_lsq_replenish_uop_uopIdx (g_io_lsq_replenish_uop_uopIdx),
    .io_lsq_replenish_uop_robIdx_flag (g_io_lsq_replenish_uop_robIdx_flag),
    .io_lsq_replenish_uop_robIdx_value (g_io_lsq_replenish_uop_robIdx_value),
    .io_lsq_replenish_fullva (g_io_lsq_replenish_fullva),
    .io_lsq_replenish_vaNeedExt (g_io_lsq_replenish_vaNeedExt),
    .io_lsq_replenish_gpaddr (g_io_lsq_replenish_gpaddr),
    .io_lsq_replenish_af (g_io_lsq_replenish_af),
    .io_lsq_replenish_mmio (g_io_lsq_replenish_mmio),
    .io_lsq_replenish_memBackTypeMM (g_io_lsq_replenish_memBackTypeMM),
    .io_lsq_replenish_hasException (g_io_lsq_replenish_hasException),
    .io_lsq_replenish_isHyper (g_io_lsq_replenish_isHyper),
    .io_lsq_replenish_isForVSnonLeafPTE (g_io_lsq_replenish_isForVSnonLeafPTE),
    .io_lsq_replenish_isvec (g_io_lsq_replenish_isvec),
    .io_lsq_replenish_updateAddrValid (g_io_lsq_replenish_updateAddrValid),
    .io_feedback_slow_valid (g_io_feedback_slow_valid),
    .io_feedback_slow_bits_robIdx_flag (g_io_feedback_slow_bits_robIdx_flag),
    .io_feedback_slow_bits_robIdx_value (g_io_feedback_slow_bits_robIdx_value),
    .io_feedback_slow_bits_hit (g_io_feedback_slow_bits_hit),
    .io_feedback_slow_bits_flushState (g_io_feedback_slow_bits_flushState),
    .io_feedback_slow_bits_sqIdx_flag (g_io_feedback_slow_bits_sqIdx_flag),
    .io_feedback_slow_bits_sqIdx_value (g_io_feedback_slow_bits_sqIdx_value),
    .io_feedback_slow_bits_lqIdx_flag (g_io_feedback_slow_bits_lqIdx_flag),
    .io_feedback_slow_bits_lqIdx_value (g_io_feedback_slow_bits_lqIdx_value),
    .io_stld_nuke_query_valid (g_io_stld_nuke_query_valid),
    .io_stld_nuke_query_bits_robIdx_flag (g_io_stld_nuke_query_bits_robIdx_flag),
    .io_stld_nuke_query_bits_robIdx_value (g_io_stld_nuke_query_bits_robIdx_value),
    .io_stld_nuke_query_bits_paddr (g_io_stld_nuke_query_bits_paddr),
    .io_stld_nuke_query_bits_mask (g_io_stld_nuke_query_bits_mask),
    .io_stld_nuke_query_bits_matchType (g_io_stld_nuke_query_bits_matchType),
    .io_stout_valid (g_io_stout_valid),
    .io_stout_bits_uop_exceptionVec_3 (g_io_stout_bits_uop_exceptionVec_3),
    .io_stout_bits_uop_exceptionVec_6 (g_io_stout_bits_uop_exceptionVec_6),
    .io_stout_bits_uop_exceptionVec_7 (g_io_stout_bits_uop_exceptionVec_7),
    .io_stout_bits_uop_exceptionVec_15 (g_io_stout_bits_uop_exceptionVec_15),
    .io_stout_bits_uop_exceptionVec_19 (g_io_stout_bits_uop_exceptionVec_19),
    .io_stout_bits_uop_exceptionVec_23 (g_io_stout_bits_uop_exceptionVec_23),
    .io_stout_bits_uop_trigger (g_io_stout_bits_uop_trigger),
    .io_stout_bits_uop_rfWen (g_io_stout_bits_uop_rfWen),
    .io_stout_bits_uop_pdest (g_io_stout_bits_uop_pdest),
    .io_stout_bits_uop_robIdx_flag (g_io_stout_bits_uop_robIdx_flag),
    .io_stout_bits_uop_robIdx_value (g_io_stout_bits_uop_robIdx_value),
    .io_stout_bits_uop_debugInfo_eliminatedMove (g_io_stout_bits_uop_debugInfo_eliminatedMove),
    .io_stout_bits_uop_debugInfo_renameTime (g_io_stout_bits_uop_debugInfo_renameTime),
    .io_stout_bits_uop_debugInfo_dispatchTime (g_io_stout_bits_uop_debugInfo_dispatchTime),
    .io_stout_bits_uop_debugInfo_enqRsTime (g_io_stout_bits_uop_debugInfo_enqRsTime),
    .io_stout_bits_uop_debugInfo_selectTime (g_io_stout_bits_uop_debugInfo_selectTime),
    .io_stout_bits_uop_debugInfo_issueTime (g_io_stout_bits_uop_debugInfo_issueTime),
    .io_stout_bits_uop_debugInfo_writebackTime (g_io_stout_bits_uop_debugInfo_writebackTime),
    .io_stout_bits_uop_debugInfo_runahead_checkpoint_id (g_io_stout_bits_uop_debugInfo_runahead_checkpoint_id),
    .io_stout_bits_uop_debugInfo_tlbFirstReqTime (g_io_stout_bits_uop_debugInfo_tlbFirstReqTime),
    .io_stout_bits_uop_debugInfo_tlbRespTime (g_io_stout_bits_uop_debugInfo_tlbRespTime),
    .io_stout_bits_uop_debug_seqNum_seqNum (g_io_stout_bits_uop_debug_seqNum_seqNum),
    .io_stout_bits_uop_debug_seqNum_uopIdx (g_io_stout_bits_uop_debug_seqNum_uopIdx),
    .io_stout_bits_uop_sqIdx_flag (g_io_stout_bits_uop_sqIdx_flag),
    .io_stout_bits_uop_sqIdx_value (g_io_stout_bits_uop_sqIdx_value),
    .io_stout_bits_debug_isMMIO (g_io_stout_bits_debug_isMMIO),
    .io_stout_bits_debug_isNCIO (g_io_stout_bits_debug_isNCIO),
    .io_stout_bits_debug_paddr (g_io_stout_bits_debug_paddr),
    .io_stout_bits_debug_vaddr (g_io_stout_bits_debug_vaddr),
    .io_vecstout_valid (g_io_vecstout_valid),
    .io_vecstout_bits_mBIndex (g_io_vecstout_bits_mBIndex),
    .io_vecstout_bits_hit (g_io_vecstout_bits_hit),
    .io_vecstout_bits_trigger (g_io_vecstout_bits_trigger),
    .io_vecstout_bits_exceptionVec_3 (g_io_vecstout_bits_exceptionVec_3),
    .io_vecstout_bits_exceptionVec_6 (g_io_vecstout_bits_exceptionVec_6),
    .io_vecstout_bits_exceptionVec_7 (g_io_vecstout_bits_exceptionVec_7),
    .io_vecstout_bits_exceptionVec_15 (g_io_vecstout_bits_exceptionVec_15),
    .io_vecstout_bits_exceptionVec_19 (g_io_vecstout_bits_exceptionVec_19),
    .io_vecstout_bits_exceptionVec_23 (g_io_vecstout_bits_exceptionVec_23),
    .io_vecstout_bits_hasException (g_io_vecstout_bits_hasException),
    .io_vecstout_bits_vaddr (g_io_vecstout_bits_vaddr),
    .io_vecstout_bits_vaNeedExt (g_io_vecstout_bits_vaNeedExt),
    .io_vecstout_bits_gpaddr (g_io_vecstout_bits_gpaddr),
    .io_vecstout_bits_isForVSnonLeafPTE (g_io_vecstout_bits_isForVSnonLeafPTE),
    .io_vecstout_bits_vstart (g_io_vecstout_bits_vstart),
    .io_vecstout_bits_elemIdx (g_io_vecstout_bits_elemIdx),
    .io_vecstout_bits_mask (g_io_vecstout_bits_mask),
    .io_vecstout_bits_splitIndex (g_io_vecstout_bits_splitIndex),
    .io_st_mask_out_valid (g_io_st_mask_out_valid),
    .io_st_mask_out_bits_sqIdx_value (g_io_st_mask_out_bits_sqIdx_value),
    .io_st_mask_out_bits_mask (g_io_st_mask_out_bits_mask),
    .io_vecstin_ready (g_io_vecstin_ready),
    .io_vecstin_valid (io_vecstin_valid),
    .io_vecstin_bits_vaddr (io_vecstin_bits_vaddr),
    .io_vecstin_bits_basevaddr (io_vecstin_bits_basevaddr),
    .io_vecstin_bits_mask (io_vecstin_bits_mask),
    .io_vecstin_bits_alignedType (io_vecstin_bits_alignedType),
    .io_vecstin_bits_vecActive (io_vecstin_bits_vecActive),
    .io_vecstin_bits_vecIsFirstActiveElement (io_vecstin_bits_vecIsFirstActiveElement),
    .io_vecstin_bits_uop_exceptionVec_4 (io_vecstin_bits_uop_exceptionVec_4),
    .io_vecstin_bits_uop_exceptionVec_5 (io_vecstin_bits_uop_exceptionVec_5),
    .io_vecstin_bits_uop_exceptionVec_6 (io_vecstin_bits_uop_exceptionVec_6),
    .io_vecstin_bits_uop_exceptionVec_13 (io_vecstin_bits_uop_exceptionVec_13),
    .io_vecstin_bits_uop_exceptionVec_19 (io_vecstin_bits_uop_exceptionVec_19),
    .io_vecstin_bits_uop_exceptionVec_21 (io_vecstin_bits_uop_exceptionVec_21),
    .io_vecstin_bits_uop_trigger (io_vecstin_bits_uop_trigger),
    .io_vecstin_bits_uop_ftqPtr_flag (io_vecstin_bits_uop_ftqPtr_flag),
    .io_vecstin_bits_uop_ftqPtr_value (io_vecstin_bits_uop_ftqPtr_value),
    .io_vecstin_bits_uop_ftqOffset (io_vecstin_bits_uop_ftqOffset),
    .io_vecstin_bits_uop_fuType (io_vecstin_bits_uop_fuType),
    .io_vecstin_bits_uop_fuOpType (io_vecstin_bits_uop_fuOpType),
    .io_vecstin_bits_uop_rfWen (io_vecstin_bits_uop_rfWen),
    .io_vecstin_bits_uop_vpu_vstart (io_vecstin_bits_uop_vpu_vstart),
    .io_vecstin_bits_uop_vpu_nf (io_vecstin_bits_uop_vpu_nf),
    .io_vecstin_bits_uop_vpu_veew (io_vecstin_bits_uop_vpu_veew),
    .io_vecstin_bits_uop_uopIdx (io_vecstin_bits_uop_uopIdx),
    .io_vecstin_bits_uop_pdest (io_vecstin_bits_uop_pdest),
    .io_vecstin_bits_uop_robIdx_flag (io_vecstin_bits_uop_robIdx_flag),
    .io_vecstin_bits_uop_robIdx_value (io_vecstin_bits_uop_robIdx_value),
    .io_vecstin_bits_uop_debugInfo_eliminatedMove (io_vecstin_bits_uop_debugInfo_eliminatedMove),
    .io_vecstin_bits_uop_debugInfo_renameTime (io_vecstin_bits_uop_debugInfo_renameTime),
    .io_vecstin_bits_uop_debugInfo_dispatchTime (io_vecstin_bits_uop_debugInfo_dispatchTime),
    .io_vecstin_bits_uop_debugInfo_enqRsTime (io_vecstin_bits_uop_debugInfo_enqRsTime),
    .io_vecstin_bits_uop_debugInfo_selectTime (io_vecstin_bits_uop_debugInfo_selectTime),
    .io_vecstin_bits_uop_debugInfo_issueTime (io_vecstin_bits_uop_debugInfo_issueTime),
    .io_vecstin_bits_uop_debugInfo_writebackTime (io_vecstin_bits_uop_debugInfo_writebackTime),
    .io_vecstin_bits_uop_debugInfo_runahead_checkpoint_id (io_vecstin_bits_uop_debugInfo_runahead_checkpoint_id),
    .io_vecstin_bits_uop_debugInfo_tlbFirstReqTime (io_vecstin_bits_uop_debugInfo_tlbFirstReqTime),
    .io_vecstin_bits_uop_debugInfo_tlbRespTime (io_vecstin_bits_uop_debugInfo_tlbRespTime),
    .io_vecstin_bits_uop_debug_seqNum_seqNum (io_vecstin_bits_uop_debug_seqNum_seqNum),
    .io_vecstin_bits_uop_debug_seqNum_uopIdx (io_vecstin_bits_uop_debug_seqNum_uopIdx),
    .io_vecstin_bits_uop_lqIdx_flag (io_vecstin_bits_uop_lqIdx_flag),
    .io_vecstin_bits_uop_lqIdx_value (io_vecstin_bits_uop_lqIdx_value),
    .io_vecstin_bits_uop_sqIdx_flag (io_vecstin_bits_uop_sqIdx_flag),
    .io_vecstin_bits_uop_sqIdx_value (io_vecstin_bits_uop_sqIdx_value),
    .io_vecstin_bits_mBIndex (io_vecstin_bits_mBIndex),
    .io_vecstin_bits_elemIdx (io_vecstin_bits_elemIdx),
    .io_vecstin_bits_splitIndex (io_vecstin_bits_splitIndex),
    .io_misalign_enq_req_ready (io_misalign_enq_req_ready),
    .io_misalign_enq_req_valid (g_io_misalign_enq_req_valid),
    .io_misalign_enq_req_bits_uop_exceptionVec_0 (g_io_misalign_enq_req_bits_uop_exceptionVec_0),
    .io_misalign_enq_req_bits_uop_exceptionVec_1 (g_io_misalign_enq_req_bits_uop_exceptionVec_1),
    .io_misalign_enq_req_bits_uop_exceptionVec_2 (g_io_misalign_enq_req_bits_uop_exceptionVec_2),
    .io_misalign_enq_req_bits_uop_exceptionVec_4 (g_io_misalign_enq_req_bits_uop_exceptionVec_4),
    .io_misalign_enq_req_bits_uop_exceptionVec_5 (g_io_misalign_enq_req_bits_uop_exceptionVec_5),
    .io_misalign_enq_req_bits_uop_exceptionVec_8 (g_io_misalign_enq_req_bits_uop_exceptionVec_8),
    .io_misalign_enq_req_bits_uop_exceptionVec_9 (g_io_misalign_enq_req_bits_uop_exceptionVec_9),
    .io_misalign_enq_req_bits_uop_exceptionVec_10 (g_io_misalign_enq_req_bits_uop_exceptionVec_10),
    .io_misalign_enq_req_bits_uop_exceptionVec_11 (g_io_misalign_enq_req_bits_uop_exceptionVec_11),
    .io_misalign_enq_req_bits_uop_exceptionVec_12 (g_io_misalign_enq_req_bits_uop_exceptionVec_12),
    .io_misalign_enq_req_bits_uop_exceptionVec_13 (g_io_misalign_enq_req_bits_uop_exceptionVec_13),
    .io_misalign_enq_req_bits_uop_exceptionVec_14 (g_io_misalign_enq_req_bits_uop_exceptionVec_14),
    .io_misalign_enq_req_bits_uop_exceptionVec_16 (g_io_misalign_enq_req_bits_uop_exceptionVec_16),
    .io_misalign_enq_req_bits_uop_exceptionVec_17 (g_io_misalign_enq_req_bits_uop_exceptionVec_17),
    .io_misalign_enq_req_bits_uop_exceptionVec_18 (g_io_misalign_enq_req_bits_uop_exceptionVec_18),
    .io_misalign_enq_req_bits_uop_exceptionVec_19 (g_io_misalign_enq_req_bits_uop_exceptionVec_19),
    .io_misalign_enq_req_bits_uop_exceptionVec_20 (g_io_misalign_enq_req_bits_uop_exceptionVec_20),
    .io_misalign_enq_req_bits_uop_exceptionVec_21 (g_io_misalign_enq_req_bits_uop_exceptionVec_21),
    .io_misalign_enq_req_bits_uop_exceptionVec_22 (g_io_misalign_enq_req_bits_uop_exceptionVec_22),
    .io_misalign_enq_req_bits_uop_trigger (g_io_misalign_enq_req_bits_uop_trigger),
    .io_misalign_enq_req_bits_uop_ftqPtr_flag (g_io_misalign_enq_req_bits_uop_ftqPtr_flag),
    .io_misalign_enq_req_bits_uop_ftqPtr_value (g_io_misalign_enq_req_bits_uop_ftqPtr_value),
    .io_misalign_enq_req_bits_uop_ftqOffset (g_io_misalign_enq_req_bits_uop_ftqOffset),
    .io_misalign_enq_req_bits_uop_fuType (g_io_misalign_enq_req_bits_uop_fuType),
    .io_misalign_enq_req_bits_uop_fuOpType (g_io_misalign_enq_req_bits_uop_fuOpType),
    .io_misalign_enq_req_bits_uop_rfWen (g_io_misalign_enq_req_bits_uop_rfWen),
    .io_misalign_enq_req_bits_uop_vpu_vstart (g_io_misalign_enq_req_bits_uop_vpu_vstart),
    .io_misalign_enq_req_bits_uop_vpu_nf (g_io_misalign_enq_req_bits_uop_vpu_nf),
    .io_misalign_enq_req_bits_uop_vpu_veew (g_io_misalign_enq_req_bits_uop_vpu_veew),
    .io_misalign_enq_req_bits_uop_uopIdx (g_io_misalign_enq_req_bits_uop_uopIdx),
    .io_misalign_enq_req_bits_uop_pdest (g_io_misalign_enq_req_bits_uop_pdest),
    .io_misalign_enq_req_bits_uop_robIdx_flag (g_io_misalign_enq_req_bits_uop_robIdx_flag),
    .io_misalign_enq_req_bits_uop_robIdx_value (g_io_misalign_enq_req_bits_uop_robIdx_value),
    .io_misalign_enq_req_bits_uop_debugInfo_eliminatedMove (g_io_misalign_enq_req_bits_uop_debugInfo_eliminatedMove),
    .io_misalign_enq_req_bits_uop_debugInfo_renameTime (g_io_misalign_enq_req_bits_uop_debugInfo_renameTime),
    .io_misalign_enq_req_bits_uop_debugInfo_dispatchTime (g_io_misalign_enq_req_bits_uop_debugInfo_dispatchTime),
    .io_misalign_enq_req_bits_uop_debugInfo_enqRsTime (g_io_misalign_enq_req_bits_uop_debugInfo_enqRsTime),
    .io_misalign_enq_req_bits_uop_debugInfo_selectTime (g_io_misalign_enq_req_bits_uop_debugInfo_selectTime),
    .io_misalign_enq_req_bits_uop_debugInfo_issueTime (g_io_misalign_enq_req_bits_uop_debugInfo_issueTime),
    .io_misalign_enq_req_bits_uop_debugInfo_writebackTime (g_io_misalign_enq_req_bits_uop_debugInfo_writebackTime),
    .io_misalign_enq_req_bits_uop_debugInfo_runahead_checkpoint_id (g_io_misalign_enq_req_bits_uop_debugInfo_runahead_checkpoint_id),
    .io_misalign_enq_req_bits_uop_debugInfo_tlbFirstReqTime (g_io_misalign_enq_req_bits_uop_debugInfo_tlbFirstReqTime),
    .io_misalign_enq_req_bits_uop_debugInfo_tlbRespTime (g_io_misalign_enq_req_bits_uop_debugInfo_tlbRespTime),
    .io_misalign_enq_req_bits_uop_debug_seqNum_seqNum (g_io_misalign_enq_req_bits_uop_debug_seqNum_seqNum),
    .io_misalign_enq_req_bits_uop_debug_seqNum_uopIdx (g_io_misalign_enq_req_bits_uop_debug_seqNum_uopIdx),
    .io_misalign_enq_req_bits_uop_lqIdx_flag (g_io_misalign_enq_req_bits_uop_lqIdx_flag),
    .io_misalign_enq_req_bits_uop_lqIdx_value (g_io_misalign_enq_req_bits_uop_lqIdx_value),
    .io_misalign_enq_req_bits_uop_sqIdx_flag (g_io_misalign_enq_req_bits_uop_sqIdx_flag),
    .io_misalign_enq_req_bits_uop_sqIdx_value (g_io_misalign_enq_req_bits_uop_sqIdx_value),
    .io_misalign_enq_req_bits_vaddr (g_io_misalign_enq_req_bits_vaddr),
    .io_misalign_enq_req_bits_mask (g_io_misalign_enq_req_bits_mask),
    .io_misalign_enq_req_bits_isvec (g_io_misalign_enq_req_bits_isvec),
    .io_misalign_enq_req_bits_elemIdx (g_io_misalign_enq_req_bits_elemIdx),
    .io_misalign_enq_req_bits_alignedType (g_io_misalign_enq_req_bits_alignedType),
    .io_misalign_enq_req_bits_mbIndex (g_io_misalign_enq_req_bits_mbIndex),
    .io_misalign_enq_req_bits_splitIndex (g_io_misalign_enq_req_bits_splitIndex),
    .io_misalign_enq_revoke (g_io_misalign_enq_revoke),
    .io_fromCsrTrigger_tdataVec_0_matchType (io_fromCsrTrigger_tdataVec_0_matchType),
    .io_fromCsrTrigger_tdataVec_0_select (io_fromCsrTrigger_tdataVec_0_select),
    .io_fromCsrTrigger_tdataVec_0_timing (io_fromCsrTrigger_tdataVec_0_timing),
    .io_fromCsrTrigger_tdataVec_0_action (io_fromCsrTrigger_tdataVec_0_action),
    .io_fromCsrTrigger_tdataVec_0_chain (io_fromCsrTrigger_tdataVec_0_chain),
    .io_fromCsrTrigger_tdataVec_0_store (io_fromCsrTrigger_tdataVec_0_store),
    .io_fromCsrTrigger_tdataVec_0_tdata2 (io_fromCsrTrigger_tdataVec_0_tdata2),
    .io_fromCsrTrigger_tdataVec_1_matchType (io_fromCsrTrigger_tdataVec_1_matchType),
    .io_fromCsrTrigger_tdataVec_1_select (io_fromCsrTrigger_tdataVec_1_select),
    .io_fromCsrTrigger_tdataVec_1_timing (io_fromCsrTrigger_tdataVec_1_timing),
    .io_fromCsrTrigger_tdataVec_1_action (io_fromCsrTrigger_tdataVec_1_action),
    .io_fromCsrTrigger_tdataVec_1_chain (io_fromCsrTrigger_tdataVec_1_chain),
    .io_fromCsrTrigger_tdataVec_1_store (io_fromCsrTrigger_tdataVec_1_store),
    .io_fromCsrTrigger_tdataVec_1_tdata2 (io_fromCsrTrigger_tdataVec_1_tdata2),
    .io_fromCsrTrigger_tdataVec_2_matchType (io_fromCsrTrigger_tdataVec_2_matchType),
    .io_fromCsrTrigger_tdataVec_2_select (io_fromCsrTrigger_tdataVec_2_select),
    .io_fromCsrTrigger_tdataVec_2_timing (io_fromCsrTrigger_tdataVec_2_timing),
    .io_fromCsrTrigger_tdataVec_2_action (io_fromCsrTrigger_tdataVec_2_action),
    .io_fromCsrTrigger_tdataVec_2_chain (io_fromCsrTrigger_tdataVec_2_chain),
    .io_fromCsrTrigger_tdataVec_2_store (io_fromCsrTrigger_tdataVec_2_store),
    .io_fromCsrTrigger_tdataVec_2_tdata2 (io_fromCsrTrigger_tdataVec_2_tdata2),
    .io_fromCsrTrigger_tdataVec_3_matchType (io_fromCsrTrigger_tdataVec_3_matchType),
    .io_fromCsrTrigger_tdataVec_3_select (io_fromCsrTrigger_tdataVec_3_select),
    .io_fromCsrTrigger_tdataVec_3_timing (io_fromCsrTrigger_tdataVec_3_timing),
    .io_fromCsrTrigger_tdataVec_3_action (io_fromCsrTrigger_tdataVec_3_action),
    .io_fromCsrTrigger_tdataVec_3_chain (io_fromCsrTrigger_tdataVec_3_chain),
    .io_fromCsrTrigger_tdataVec_3_store (io_fromCsrTrigger_tdataVec_3_store),
    .io_fromCsrTrigger_tdataVec_3_tdata2 (io_fromCsrTrigger_tdataVec_3_tdata2),
    .io_fromCsrTrigger_tEnableVec_0 (io_fromCsrTrigger_tEnableVec_0),
    .io_fromCsrTrigger_tEnableVec_1 (io_fromCsrTrigger_tEnableVec_1),
    .io_fromCsrTrigger_tEnableVec_2 (io_fromCsrTrigger_tEnableVec_2),
    .io_fromCsrTrigger_tEnableVec_3 (io_fromCsrTrigger_tEnableVec_3),
    .io_fromCsrTrigger_debugMode (io_fromCsrTrigger_debugMode),
    .io_fromCsrTrigger_triggerCanRaiseBpExp (io_fromCsrTrigger_triggerCanRaiseBpExp),
    .io_sqCommitPtr_flag (io_sqCommitPtr_flag),
    .io_sqCommitPtr_value (io_sqCommitPtr_value),
    .io_sqCommitUopIdx (io_sqCommitUopIdx),
    .io_sqCommitRobIdx_flag (io_sqCommitRobIdx_flag),
    .io_sqCommitRobIdx_value (io_sqCommitRobIdx_value)
  );

  StoreUnit_xs u_impl (
    .clock (clock),
    .reset (reset),
    .io_redirect_valid (io_redirect_valid),
    .io_redirect_bits_robIdx_flag (io_redirect_bits_robIdx_flag),
    .io_redirect_bits_robIdx_value (io_redirect_bits_robIdx_value),
    .io_redirect_bits_level (io_redirect_bits_level),
    .io_csrCtrl_hd_misalign_st_enable (io_csrCtrl_hd_misalign_st_enable),
    .io_stin_ready (x_io_stin_ready),
    .io_stin_valid (io_stin_valid),
    .io_stin_bits_uop_ftqPtr_flag (io_stin_bits_uop_ftqPtr_flag),
    .io_stin_bits_uop_ftqPtr_value (io_stin_bits_uop_ftqPtr_value),
    .io_stin_bits_uop_ftqOffset (io_stin_bits_uop_ftqOffset),
    .io_stin_bits_uop_fuType (io_stin_bits_uop_fuType),
    .io_stin_bits_uop_fuOpType (io_stin_bits_uop_fuOpType),
    .io_stin_bits_uop_rfWen (io_stin_bits_uop_rfWen),
    .io_stin_bits_uop_imm (io_stin_bits_uop_imm),
    .io_stin_bits_uop_pdest (io_stin_bits_uop_pdest),
    .io_stin_bits_uop_robIdx_flag (io_stin_bits_uop_robIdx_flag),
    .io_stin_bits_uop_robIdx_value (io_stin_bits_uop_robIdx_value),
    .io_stin_bits_uop_debugInfo_eliminatedMove (io_stin_bits_uop_debugInfo_eliminatedMove),
    .io_stin_bits_uop_debugInfo_renameTime (io_stin_bits_uop_debugInfo_renameTime),
    .io_stin_bits_uop_debugInfo_dispatchTime (io_stin_bits_uop_debugInfo_dispatchTime),
    .io_stin_bits_uop_debugInfo_enqRsTime (io_stin_bits_uop_debugInfo_enqRsTime),
    .io_stin_bits_uop_debugInfo_selectTime (io_stin_bits_uop_debugInfo_selectTime),
    .io_stin_bits_uop_debugInfo_issueTime (io_stin_bits_uop_debugInfo_issueTime),
    .io_stin_bits_uop_debugInfo_writebackTime (io_stin_bits_uop_debugInfo_writebackTime),
    .io_stin_bits_uop_debugInfo_runahead_checkpoint_id (io_stin_bits_uop_debugInfo_runahead_checkpoint_id),
    .io_stin_bits_uop_debugInfo_tlbFirstReqTime (io_stin_bits_uop_debugInfo_tlbFirstReqTime),
    .io_stin_bits_uop_debugInfo_tlbRespTime (io_stin_bits_uop_debugInfo_tlbRespTime),
    .io_stin_bits_uop_debug_seqNum_seqNum (io_stin_bits_uop_debug_seqNum_seqNum),
    .io_stin_bits_uop_debug_seqNum_uopIdx (io_stin_bits_uop_debug_seqNum_uopIdx),
    .io_stin_bits_uop_lqIdx_flag (io_stin_bits_uop_lqIdx_flag),
    .io_stin_bits_uop_lqIdx_value (io_stin_bits_uop_lqIdx_value),
    .io_stin_bits_uop_sqIdx_flag (io_stin_bits_uop_sqIdx_flag),
    .io_stin_bits_uop_sqIdx_value (io_stin_bits_uop_sqIdx_value),
    .io_stin_bits_src_0 (io_stin_bits_src_0),
    .io_stin_bits_isFirstIssue (io_stin_bits_isFirstIssue),
    .io_issue_valid (x_io_issue_valid),
    .io_issue_bits_uop_robIdx_flag (x_io_issue_bits_uop_robIdx_flag),
    .io_issue_bits_uop_robIdx_value (x_io_issue_bits_uop_robIdx_value),
    .io_misalign_stin_ready (x_io_misalign_stin_ready),
    .io_misalign_stin_valid (io_misalign_stin_valid),
    .io_misalign_stin_bits_uop_exceptionVec_0 (io_misalign_stin_bits_uop_exceptionVec_0),
    .io_misalign_stin_bits_uop_exceptionVec_1 (io_misalign_stin_bits_uop_exceptionVec_1),
    .io_misalign_stin_bits_uop_exceptionVec_2 (io_misalign_stin_bits_uop_exceptionVec_2),
    .io_misalign_stin_bits_uop_exceptionVec_4 (io_misalign_stin_bits_uop_exceptionVec_4),
    .io_misalign_stin_bits_uop_exceptionVec_5 (io_misalign_stin_bits_uop_exceptionVec_5),
    .io_misalign_stin_bits_uop_exceptionVec_8 (io_misalign_stin_bits_uop_exceptionVec_8),
    .io_misalign_stin_bits_uop_exceptionVec_9 (io_misalign_stin_bits_uop_exceptionVec_9),
    .io_misalign_stin_bits_uop_exceptionVec_10 (io_misalign_stin_bits_uop_exceptionVec_10),
    .io_misalign_stin_bits_uop_exceptionVec_11 (io_misalign_stin_bits_uop_exceptionVec_11),
    .io_misalign_stin_bits_uop_exceptionVec_12 (io_misalign_stin_bits_uop_exceptionVec_12),
    .io_misalign_stin_bits_uop_exceptionVec_13 (io_misalign_stin_bits_uop_exceptionVec_13),
    .io_misalign_stin_bits_uop_exceptionVec_14 (io_misalign_stin_bits_uop_exceptionVec_14),
    .io_misalign_stin_bits_uop_exceptionVec_16 (io_misalign_stin_bits_uop_exceptionVec_16),
    .io_misalign_stin_bits_uop_exceptionVec_17 (io_misalign_stin_bits_uop_exceptionVec_17),
    .io_misalign_stin_bits_uop_exceptionVec_18 (io_misalign_stin_bits_uop_exceptionVec_18),
    .io_misalign_stin_bits_uop_exceptionVec_19 (io_misalign_stin_bits_uop_exceptionVec_19),
    .io_misalign_stin_bits_uop_exceptionVec_20 (io_misalign_stin_bits_uop_exceptionVec_20),
    .io_misalign_stin_bits_uop_exceptionVec_21 (io_misalign_stin_bits_uop_exceptionVec_21),
    .io_misalign_stin_bits_uop_exceptionVec_22 (io_misalign_stin_bits_uop_exceptionVec_22),
    .io_misalign_stin_bits_uop_trigger (io_misalign_stin_bits_uop_trigger),
    .io_misalign_stin_bits_uop_ftqPtr_flag (io_misalign_stin_bits_uop_ftqPtr_flag),
    .io_misalign_stin_bits_uop_ftqPtr_value (io_misalign_stin_bits_uop_ftqPtr_value),
    .io_misalign_stin_bits_uop_ftqOffset (io_misalign_stin_bits_uop_ftqOffset),
    .io_misalign_stin_bits_uop_fuType (io_misalign_stin_bits_uop_fuType),
    .io_misalign_stin_bits_uop_fuOpType (io_misalign_stin_bits_uop_fuOpType),
    .io_misalign_stin_bits_uop_rfWen (io_misalign_stin_bits_uop_rfWen),
    .io_misalign_stin_bits_uop_vpu_vstart (io_misalign_stin_bits_uop_vpu_vstart),
    .io_misalign_stin_bits_uop_vpu_nf (io_misalign_stin_bits_uop_vpu_nf),
    .io_misalign_stin_bits_uop_vpu_veew (io_misalign_stin_bits_uop_vpu_veew),
    .io_misalign_stin_bits_uop_uopIdx (io_misalign_stin_bits_uop_uopIdx),
    .io_misalign_stin_bits_uop_pdest (io_misalign_stin_bits_uop_pdest),
    .io_misalign_stin_bits_uop_robIdx_flag (io_misalign_stin_bits_uop_robIdx_flag),
    .io_misalign_stin_bits_uop_robIdx_value (io_misalign_stin_bits_uop_robIdx_value),
    .io_misalign_stin_bits_uop_debugInfo_eliminatedMove (io_misalign_stin_bits_uop_debugInfo_eliminatedMove),
    .io_misalign_stin_bits_uop_debugInfo_renameTime (io_misalign_stin_bits_uop_debugInfo_renameTime),
    .io_misalign_stin_bits_uop_debugInfo_dispatchTime (io_misalign_stin_bits_uop_debugInfo_dispatchTime),
    .io_misalign_stin_bits_uop_debugInfo_enqRsTime (io_misalign_stin_bits_uop_debugInfo_enqRsTime),
    .io_misalign_stin_bits_uop_debugInfo_selectTime (io_misalign_stin_bits_uop_debugInfo_selectTime),
    .io_misalign_stin_bits_uop_debugInfo_issueTime (io_misalign_stin_bits_uop_debugInfo_issueTime),
    .io_misalign_stin_bits_uop_debugInfo_writebackTime (io_misalign_stin_bits_uop_debugInfo_writebackTime),
    .io_misalign_stin_bits_uop_debugInfo_runahead_checkpoint_id (io_misalign_stin_bits_uop_debugInfo_runahead_checkpoint_id),
    .io_misalign_stin_bits_uop_debugInfo_tlbFirstReqTime (io_misalign_stin_bits_uop_debugInfo_tlbFirstReqTime),
    .io_misalign_stin_bits_uop_debugInfo_tlbRespTime (io_misalign_stin_bits_uop_debugInfo_tlbRespTime),
    .io_misalign_stin_bits_uop_debug_seqNum_seqNum (io_misalign_stin_bits_uop_debug_seqNum_seqNum),
    .io_misalign_stin_bits_uop_debug_seqNum_uopIdx (io_misalign_stin_bits_uop_debug_seqNum_uopIdx),
    .io_misalign_stin_bits_uop_lqIdx_flag (io_misalign_stin_bits_uop_lqIdx_flag),
    .io_misalign_stin_bits_uop_lqIdx_value (io_misalign_stin_bits_uop_lqIdx_value),
    .io_misalign_stin_bits_uop_sqIdx_flag (io_misalign_stin_bits_uop_sqIdx_flag),
    .io_misalign_stin_bits_uop_sqIdx_value (io_misalign_stin_bits_uop_sqIdx_value),
    .io_misalign_stin_bits_vaddr (io_misalign_stin_bits_vaddr),
    .io_misalign_stin_bits_mask (io_misalign_stin_bits_mask),
    .io_misalign_stin_bits_isvec (io_misalign_stin_bits_isvec),
    .io_misalign_stin_bits_is128bit (io_misalign_stin_bits_is128bit),
    .io_misalign_stin_bits_isFinalSplit (io_misalign_stin_bits_isFinalSplit),
    .io_misalign_stout_valid (x_io_misalign_stout_valid),
    .io_misalign_stout_bits_uop_exceptionVec_3 (x_io_misalign_stout_bits_uop_exceptionVec_3),
    .io_misalign_stout_bits_uop_exceptionVec_6 (x_io_misalign_stout_bits_uop_exceptionVec_6),
    .io_misalign_stout_bits_uop_exceptionVec_7 (x_io_misalign_stout_bits_uop_exceptionVec_7),
    .io_misalign_stout_bits_uop_exceptionVec_15 (x_io_misalign_stout_bits_uop_exceptionVec_15),
    .io_misalign_stout_bits_uop_exceptionVec_19 (x_io_misalign_stout_bits_uop_exceptionVec_19),
    .io_misalign_stout_bits_uop_exceptionVec_23 (x_io_misalign_stout_bits_uop_exceptionVec_23),
    .io_misalign_stout_bits_uop_trigger (x_io_misalign_stout_bits_uop_trigger),
    .io_misalign_stout_bits_uop_robIdx_flag (x_io_misalign_stout_bits_uop_robIdx_flag),
    .io_misalign_stout_bits_uop_robIdx_value (x_io_misalign_stout_bits_uop_robIdx_value),
    .io_misalign_stout_bits_vaddr (x_io_misalign_stout_bits_vaddr),
    .io_misalign_stout_bits_vaNeedExt (x_io_misalign_stout_bits_vaNeedExt),
    .io_misalign_stout_bits_paddr (x_io_misalign_stout_bits_paddr),
    .io_misalign_stout_bits_gpaddr (x_io_misalign_stout_bits_gpaddr),
    .io_misalign_stout_bits_nc (x_io_misalign_stout_bits_nc),
    .io_misalign_stout_bits_mmio (x_io_misalign_stout_bits_mmio),
    .io_misalign_stout_bits_memBackTypeMM (x_io_misalign_stout_bits_memBackTypeMM),
    .io_misalign_stout_bits_isForVSnonLeafPTE (x_io_misalign_stout_bits_isForVSnonLeafPTE),
    .io_misalign_stout_bits_vecActive (x_io_misalign_stout_bits_vecActive),
    .io_misalign_stout_bits_need_rep (x_io_misalign_stout_bits_need_rep),
    .io_tlb_req_valid (x_io_tlb_req_valid),
    .io_tlb_req_bits_vaddr (x_io_tlb_req_bits_vaddr),
    .io_tlb_req_bits_fullva (x_io_tlb_req_bits_fullva),
    .io_tlb_req_bits_checkfullva (x_io_tlb_req_bits_checkfullva),
    .io_tlb_req_bits_cmd (x_io_tlb_req_bits_cmd),
    .io_tlb_req_bits_hyperinst (x_io_tlb_req_bits_hyperinst),
    .io_tlb_req_bits_memidx_idx (x_io_tlb_req_bits_memidx_idx),
    .io_tlb_req_bits_frm_mabuf (x_io_tlb_req_bits_frm_mabuf),
    .io_tlb_req_bits_debug_robIdx_flag (x_io_tlb_req_bits_debug_robIdx_flag),
    .io_tlb_req_bits_debug_robIdx_value (x_io_tlb_req_bits_debug_robIdx_value),
    .io_tlb_req_bits_debug_isFirstIssue (x_io_tlb_req_bits_debug_isFirstIssue),
    .io_tlb_resp_valid (io_tlb_resp_valid),
    .io_tlb_resp_bits_paddr_0 (io_tlb_resp_bits_paddr_0),
    .io_tlb_resp_bits_gpaddr_0 (io_tlb_resp_bits_gpaddr_0),
    .io_tlb_resp_bits_fullva (io_tlb_resp_bits_fullva),
    .io_tlb_resp_bits_pbmt_0 (io_tlb_resp_bits_pbmt_0),
    .io_tlb_resp_bits_miss (io_tlb_resp_bits_miss),
    .io_tlb_resp_bits_isForVSnonLeafPTE (io_tlb_resp_bits_isForVSnonLeafPTE),
    .io_tlb_resp_bits_excp_0_vaNeedExt (io_tlb_resp_bits_excp_0_vaNeedExt),
    .io_tlb_resp_bits_excp_0_isHyper (io_tlb_resp_bits_excp_0_isHyper),
    .io_tlb_resp_bits_excp_0_gpf_ld (io_tlb_resp_bits_excp_0_gpf_ld),
    .io_tlb_resp_bits_excp_0_gpf_st (io_tlb_resp_bits_excp_0_gpf_st),
    .io_tlb_resp_bits_excp_0_pf_ld (io_tlb_resp_bits_excp_0_pf_ld),
    .io_tlb_resp_bits_excp_0_pf_st (io_tlb_resp_bits_excp_0_pf_st),
    .io_tlb_resp_bits_excp_0_af_ld (io_tlb_resp_bits_excp_0_af_ld),
    .io_tlb_resp_bits_excp_0_af_st (io_tlb_resp_bits_excp_0_af_st),
    .io_tlb_resp_bits_ptwBack (io_tlb_resp_bits_ptwBack),
    .io_tlb_resp_bits_memidx_idx (io_tlb_resp_bits_memidx_idx),
    .io_dcache_req_valid (x_io_dcache_req_valid),
    .io_pmp_ld (io_pmp_ld),
    .io_pmp_st (io_pmp_st),
    .io_pmp_mmio (io_pmp_mmio),
    .io_lsq_valid (x_io_lsq_valid),
    .io_lsq_bits_uop_exceptionVec_0 (x_io_lsq_bits_uop_exceptionVec_0),
    .io_lsq_bits_uop_exceptionVec_1 (x_io_lsq_bits_uop_exceptionVec_1),
    .io_lsq_bits_uop_exceptionVec_2 (x_io_lsq_bits_uop_exceptionVec_2),
    .io_lsq_bits_uop_exceptionVec_3 (x_io_lsq_bits_uop_exceptionVec_3),
    .io_lsq_bits_uop_exceptionVec_4 (x_io_lsq_bits_uop_exceptionVec_4),
    .io_lsq_bits_uop_exceptionVec_5 (x_io_lsq_bits_uop_exceptionVec_5),
    .io_lsq_bits_uop_exceptionVec_6 (x_io_lsq_bits_uop_exceptionVec_6),
    .io_lsq_bits_uop_exceptionVec_7 (x_io_lsq_bits_uop_exceptionVec_7),
    .io_lsq_bits_uop_exceptionVec_8 (x_io_lsq_bits_uop_exceptionVec_8),
    .io_lsq_bits_uop_exceptionVec_9 (x_io_lsq_bits_uop_exceptionVec_9),
    .io_lsq_bits_uop_exceptionVec_10 (x_io_lsq_bits_uop_exceptionVec_10),
    .io_lsq_bits_uop_exceptionVec_11 (x_io_lsq_bits_uop_exceptionVec_11),
    .io_lsq_bits_uop_exceptionVec_12 (x_io_lsq_bits_uop_exceptionVec_12),
    .io_lsq_bits_uop_exceptionVec_13 (x_io_lsq_bits_uop_exceptionVec_13),
    .io_lsq_bits_uop_exceptionVec_14 (x_io_lsq_bits_uop_exceptionVec_14),
    .io_lsq_bits_uop_exceptionVec_15 (x_io_lsq_bits_uop_exceptionVec_15),
    .io_lsq_bits_uop_exceptionVec_16 (x_io_lsq_bits_uop_exceptionVec_16),
    .io_lsq_bits_uop_exceptionVec_17 (x_io_lsq_bits_uop_exceptionVec_17),
    .io_lsq_bits_uop_exceptionVec_18 (x_io_lsq_bits_uop_exceptionVec_18),
    .io_lsq_bits_uop_exceptionVec_19 (x_io_lsq_bits_uop_exceptionVec_19),
    .io_lsq_bits_uop_exceptionVec_20 (x_io_lsq_bits_uop_exceptionVec_20),
    .io_lsq_bits_uop_exceptionVec_21 (x_io_lsq_bits_uop_exceptionVec_21),
    .io_lsq_bits_uop_exceptionVec_22 (x_io_lsq_bits_uop_exceptionVec_22),
    .io_lsq_bits_uop_exceptionVec_23 (x_io_lsq_bits_uop_exceptionVec_23),
    .io_lsq_bits_uop_trigger (x_io_lsq_bits_uop_trigger),
    .io_lsq_bits_uop_ftqPtr_flag (x_io_lsq_bits_uop_ftqPtr_flag),
    .io_lsq_bits_uop_ftqPtr_value (x_io_lsq_bits_uop_ftqPtr_value),
    .io_lsq_bits_uop_ftqOffset (x_io_lsq_bits_uop_ftqOffset),
    .io_lsq_bits_uop_fuType (x_io_lsq_bits_uop_fuType),
    .io_lsq_bits_uop_fuOpType (x_io_lsq_bits_uop_fuOpType),
    .io_lsq_bits_uop_rfWen (x_io_lsq_bits_uop_rfWen),
    .io_lsq_bits_uop_vpu_nf (x_io_lsq_bits_uop_vpu_nf),
    .io_lsq_bits_uop_vpu_veew (x_io_lsq_bits_uop_vpu_veew),
    .io_lsq_bits_uop_uopIdx (x_io_lsq_bits_uop_uopIdx),
    .io_lsq_bits_uop_pdest (x_io_lsq_bits_uop_pdest),
    .io_lsq_bits_uop_robIdx_flag (x_io_lsq_bits_uop_robIdx_flag),
    .io_lsq_bits_uop_robIdx_value (x_io_lsq_bits_uop_robIdx_value),
    .io_lsq_bits_uop_debugInfo_eliminatedMove (x_io_lsq_bits_uop_debugInfo_eliminatedMove),
    .io_lsq_bits_uop_debugInfo_renameTime (x_io_lsq_bits_uop_debugInfo_renameTime),
    .io_lsq_bits_uop_debugInfo_dispatchTime (x_io_lsq_bits_uop_debugInfo_dispatchTime),
    .io_lsq_bits_uop_debugInfo_enqRsTime (x_io_lsq_bits_uop_debugInfo_enqRsTime),
    .io_lsq_bits_uop_debugInfo_selectTime (x_io_lsq_bits_uop_debugInfo_selectTime),
    .io_lsq_bits_uop_debugInfo_issueTime (x_io_lsq_bits_uop_debugInfo_issueTime),
    .io_lsq_bits_uop_debugInfo_writebackTime (x_io_lsq_bits_uop_debugInfo_writebackTime),
    .io_lsq_bits_uop_debugInfo_runahead_checkpoint_id (x_io_lsq_bits_uop_debugInfo_runahead_checkpoint_id),
    .io_lsq_bits_uop_debugInfo_tlbFirstReqTime (x_io_lsq_bits_uop_debugInfo_tlbFirstReqTime),
    .io_lsq_bits_uop_debugInfo_tlbRespTime (x_io_lsq_bits_uop_debugInfo_tlbRespTime),
    .io_lsq_bits_uop_debug_seqNum_seqNum (x_io_lsq_bits_uop_debug_seqNum_seqNum),
    .io_lsq_bits_uop_debug_seqNum_uopIdx (x_io_lsq_bits_uop_debug_seqNum_uopIdx),
    .io_lsq_bits_uop_sqIdx_flag (x_io_lsq_bits_uop_sqIdx_flag),
    .io_lsq_bits_uop_sqIdx_value (x_io_lsq_bits_uop_sqIdx_value),
    .io_lsq_bits_vaddr (x_io_lsq_bits_vaddr),
    .io_lsq_bits_fullva (x_io_lsq_bits_fullva),
    .io_lsq_bits_vaNeedExt (x_io_lsq_bits_vaNeedExt),
    .io_lsq_bits_paddr (x_io_lsq_bits_paddr),
    .io_lsq_bits_gpaddr (x_io_lsq_bits_gpaddr),
    .io_lsq_bits_mask (x_io_lsq_bits_mask),
    .io_lsq_bits_wlineflag (x_io_lsq_bits_wlineflag),
    .io_lsq_bits_miss (x_io_lsq_bits_miss),
    .io_lsq_bits_nc (x_io_lsq_bits_nc),
    .io_lsq_bits_isHyper (x_io_lsq_bits_isHyper),
    .io_lsq_bits_isForVSnonLeafPTE (x_io_lsq_bits_isForVSnonLeafPTE),
    .io_lsq_bits_isvec (x_io_lsq_bits_isvec),
    .io_lsq_bits_isFrmMisAlignBuf (x_io_lsq_bits_isFrmMisAlignBuf),
    .io_lsq_bits_isMisalign (x_io_lsq_bits_isMisalign),
    .io_lsq_bits_misalignWith16Byte (x_io_lsq_bits_misalignWith16Byte),
    .io_lsq_bits_updateAddrValid (x_io_lsq_bits_updateAddrValid),
    .io_lsq_replenish_uop_exceptionVec_3 (x_io_lsq_replenish_uop_exceptionVec_3),
    .io_lsq_replenish_uop_exceptionVec_6 (x_io_lsq_replenish_uop_exceptionVec_6),
    .io_lsq_replenish_uop_exceptionVec_15 (x_io_lsq_replenish_uop_exceptionVec_15),
    .io_lsq_replenish_uop_exceptionVec_19 (x_io_lsq_replenish_uop_exceptionVec_19),
    .io_lsq_replenish_uop_exceptionVec_23 (x_io_lsq_replenish_uop_exceptionVec_23),
    .io_lsq_replenish_uop_uopIdx (x_io_lsq_replenish_uop_uopIdx),
    .io_lsq_replenish_uop_robIdx_flag (x_io_lsq_replenish_uop_robIdx_flag),
    .io_lsq_replenish_uop_robIdx_value (x_io_lsq_replenish_uop_robIdx_value),
    .io_lsq_replenish_fullva (x_io_lsq_replenish_fullva),
    .io_lsq_replenish_vaNeedExt (x_io_lsq_replenish_vaNeedExt),
    .io_lsq_replenish_gpaddr (x_io_lsq_replenish_gpaddr),
    .io_lsq_replenish_af (x_io_lsq_replenish_af),
    .io_lsq_replenish_mmio (x_io_lsq_replenish_mmio),
    .io_lsq_replenish_memBackTypeMM (x_io_lsq_replenish_memBackTypeMM),
    .io_lsq_replenish_hasException (x_io_lsq_replenish_hasException),
    .io_lsq_replenish_isHyper (x_io_lsq_replenish_isHyper),
    .io_lsq_replenish_isForVSnonLeafPTE (x_io_lsq_replenish_isForVSnonLeafPTE),
    .io_lsq_replenish_isvec (x_io_lsq_replenish_isvec),
    .io_lsq_replenish_updateAddrValid (x_io_lsq_replenish_updateAddrValid),
    .io_feedback_slow_valid (x_io_feedback_slow_valid),
    .io_feedback_slow_bits_robIdx_flag (x_io_feedback_slow_bits_robIdx_flag),
    .io_feedback_slow_bits_robIdx_value (x_io_feedback_slow_bits_robIdx_value),
    .io_feedback_slow_bits_hit (x_io_feedback_slow_bits_hit),
    .io_feedback_slow_bits_flushState (x_io_feedback_slow_bits_flushState),
    .io_feedback_slow_bits_sqIdx_flag (x_io_feedback_slow_bits_sqIdx_flag),
    .io_feedback_slow_bits_sqIdx_value (x_io_feedback_slow_bits_sqIdx_value),
    .io_feedback_slow_bits_lqIdx_flag (x_io_feedback_slow_bits_lqIdx_flag),
    .io_feedback_slow_bits_lqIdx_value (x_io_feedback_slow_bits_lqIdx_value),
    .io_stld_nuke_query_valid (x_io_stld_nuke_query_valid),
    .io_stld_nuke_query_bits_robIdx_flag (x_io_stld_nuke_query_bits_robIdx_flag),
    .io_stld_nuke_query_bits_robIdx_value (x_io_stld_nuke_query_bits_robIdx_value),
    .io_stld_nuke_query_bits_paddr (x_io_stld_nuke_query_bits_paddr),
    .io_stld_nuke_query_bits_mask (x_io_stld_nuke_query_bits_mask),
    .io_stld_nuke_query_bits_matchType (x_io_stld_nuke_query_bits_matchType),
    .io_stout_valid (x_io_stout_valid),
    .io_stout_bits_uop_exceptionVec_3 (x_io_stout_bits_uop_exceptionVec_3),
    .io_stout_bits_uop_exceptionVec_6 (x_io_stout_bits_uop_exceptionVec_6),
    .io_stout_bits_uop_exceptionVec_7 (x_io_stout_bits_uop_exceptionVec_7),
    .io_stout_bits_uop_exceptionVec_15 (x_io_stout_bits_uop_exceptionVec_15),
    .io_stout_bits_uop_exceptionVec_19 (x_io_stout_bits_uop_exceptionVec_19),
    .io_stout_bits_uop_exceptionVec_23 (x_io_stout_bits_uop_exceptionVec_23),
    .io_stout_bits_uop_trigger (x_io_stout_bits_uop_trigger),
    .io_stout_bits_uop_rfWen (x_io_stout_bits_uop_rfWen),
    .io_stout_bits_uop_pdest (x_io_stout_bits_uop_pdest),
    .io_stout_bits_uop_robIdx_flag (x_io_stout_bits_uop_robIdx_flag),
    .io_stout_bits_uop_robIdx_value (x_io_stout_bits_uop_robIdx_value),
    .io_stout_bits_uop_debugInfo_eliminatedMove (x_io_stout_bits_uop_debugInfo_eliminatedMove),
    .io_stout_bits_uop_debugInfo_renameTime (x_io_stout_bits_uop_debugInfo_renameTime),
    .io_stout_bits_uop_debugInfo_dispatchTime (x_io_stout_bits_uop_debugInfo_dispatchTime),
    .io_stout_bits_uop_debugInfo_enqRsTime (x_io_stout_bits_uop_debugInfo_enqRsTime),
    .io_stout_bits_uop_debugInfo_selectTime (x_io_stout_bits_uop_debugInfo_selectTime),
    .io_stout_bits_uop_debugInfo_issueTime (x_io_stout_bits_uop_debugInfo_issueTime),
    .io_stout_bits_uop_debugInfo_writebackTime (x_io_stout_bits_uop_debugInfo_writebackTime),
    .io_stout_bits_uop_debugInfo_runahead_checkpoint_id (x_io_stout_bits_uop_debugInfo_runahead_checkpoint_id),
    .io_stout_bits_uop_debugInfo_tlbFirstReqTime (x_io_stout_bits_uop_debugInfo_tlbFirstReqTime),
    .io_stout_bits_uop_debugInfo_tlbRespTime (x_io_stout_bits_uop_debugInfo_tlbRespTime),
    .io_stout_bits_uop_debug_seqNum_seqNum (x_io_stout_bits_uop_debug_seqNum_seqNum),
    .io_stout_bits_uop_debug_seqNum_uopIdx (x_io_stout_bits_uop_debug_seqNum_uopIdx),
    .io_stout_bits_uop_sqIdx_flag (x_io_stout_bits_uop_sqIdx_flag),
    .io_stout_bits_uop_sqIdx_value (x_io_stout_bits_uop_sqIdx_value),
    .io_stout_bits_debug_isMMIO (x_io_stout_bits_debug_isMMIO),
    .io_stout_bits_debug_isNCIO (x_io_stout_bits_debug_isNCIO),
    .io_stout_bits_debug_paddr (x_io_stout_bits_debug_paddr),
    .io_stout_bits_debug_vaddr (x_io_stout_bits_debug_vaddr),
    .io_vecstout_valid (x_io_vecstout_valid),
    .io_vecstout_bits_mBIndex (x_io_vecstout_bits_mBIndex),
    .io_vecstout_bits_hit (x_io_vecstout_bits_hit),
    .io_vecstout_bits_trigger (x_io_vecstout_bits_trigger),
    .io_vecstout_bits_exceptionVec_3 (x_io_vecstout_bits_exceptionVec_3),
    .io_vecstout_bits_exceptionVec_6 (x_io_vecstout_bits_exceptionVec_6),
    .io_vecstout_bits_exceptionVec_7 (x_io_vecstout_bits_exceptionVec_7),
    .io_vecstout_bits_exceptionVec_15 (x_io_vecstout_bits_exceptionVec_15),
    .io_vecstout_bits_exceptionVec_19 (x_io_vecstout_bits_exceptionVec_19),
    .io_vecstout_bits_exceptionVec_23 (x_io_vecstout_bits_exceptionVec_23),
    .io_vecstout_bits_hasException (x_io_vecstout_bits_hasException),
    .io_vecstout_bits_vaddr (x_io_vecstout_bits_vaddr),
    .io_vecstout_bits_vaNeedExt (x_io_vecstout_bits_vaNeedExt),
    .io_vecstout_bits_gpaddr (x_io_vecstout_bits_gpaddr),
    .io_vecstout_bits_isForVSnonLeafPTE (x_io_vecstout_bits_isForVSnonLeafPTE),
    .io_vecstout_bits_vstart (x_io_vecstout_bits_vstart),
    .io_vecstout_bits_elemIdx (x_io_vecstout_bits_elemIdx),
    .io_vecstout_bits_mask (x_io_vecstout_bits_mask),
    .io_vecstout_bits_splitIndex (x_io_vecstout_bits_splitIndex),
    .io_st_mask_out_valid (x_io_st_mask_out_valid),
    .io_st_mask_out_bits_sqIdx_value (x_io_st_mask_out_bits_sqIdx_value),
    .io_st_mask_out_bits_mask (x_io_st_mask_out_bits_mask),
    .io_vecstin_ready (x_io_vecstin_ready),
    .io_vecstin_valid (io_vecstin_valid),
    .io_vecstin_bits_vaddr (io_vecstin_bits_vaddr),
    .io_vecstin_bits_basevaddr (io_vecstin_bits_basevaddr),
    .io_vecstin_bits_mask (io_vecstin_bits_mask),
    .io_vecstin_bits_alignedType (io_vecstin_bits_alignedType),
    .io_vecstin_bits_vecActive (io_vecstin_bits_vecActive),
    .io_vecstin_bits_vecIsFirstActiveElement (io_vecstin_bits_vecIsFirstActiveElement),
    .io_vecstin_bits_uop_exceptionVec_4 (io_vecstin_bits_uop_exceptionVec_4),
    .io_vecstin_bits_uop_exceptionVec_5 (io_vecstin_bits_uop_exceptionVec_5),
    .io_vecstin_bits_uop_exceptionVec_6 (io_vecstin_bits_uop_exceptionVec_6),
    .io_vecstin_bits_uop_exceptionVec_13 (io_vecstin_bits_uop_exceptionVec_13),
    .io_vecstin_bits_uop_exceptionVec_19 (io_vecstin_bits_uop_exceptionVec_19),
    .io_vecstin_bits_uop_exceptionVec_21 (io_vecstin_bits_uop_exceptionVec_21),
    .io_vecstin_bits_uop_trigger (io_vecstin_bits_uop_trigger),
    .io_vecstin_bits_uop_ftqPtr_flag (io_vecstin_bits_uop_ftqPtr_flag),
    .io_vecstin_bits_uop_ftqPtr_value (io_vecstin_bits_uop_ftqPtr_value),
    .io_vecstin_bits_uop_ftqOffset (io_vecstin_bits_uop_ftqOffset),
    .io_vecstin_bits_uop_fuType (io_vecstin_bits_uop_fuType),
    .io_vecstin_bits_uop_fuOpType (io_vecstin_bits_uop_fuOpType),
    .io_vecstin_bits_uop_rfWen (io_vecstin_bits_uop_rfWen),
    .io_vecstin_bits_uop_vpu_vstart (io_vecstin_bits_uop_vpu_vstart),
    .io_vecstin_bits_uop_vpu_nf (io_vecstin_bits_uop_vpu_nf),
    .io_vecstin_bits_uop_vpu_veew (io_vecstin_bits_uop_vpu_veew),
    .io_vecstin_bits_uop_uopIdx (io_vecstin_bits_uop_uopIdx),
    .io_vecstin_bits_uop_pdest (io_vecstin_bits_uop_pdest),
    .io_vecstin_bits_uop_robIdx_flag (io_vecstin_bits_uop_robIdx_flag),
    .io_vecstin_bits_uop_robIdx_value (io_vecstin_bits_uop_robIdx_value),
    .io_vecstin_bits_uop_debugInfo_eliminatedMove (io_vecstin_bits_uop_debugInfo_eliminatedMove),
    .io_vecstin_bits_uop_debugInfo_renameTime (io_vecstin_bits_uop_debugInfo_renameTime),
    .io_vecstin_bits_uop_debugInfo_dispatchTime (io_vecstin_bits_uop_debugInfo_dispatchTime),
    .io_vecstin_bits_uop_debugInfo_enqRsTime (io_vecstin_bits_uop_debugInfo_enqRsTime),
    .io_vecstin_bits_uop_debugInfo_selectTime (io_vecstin_bits_uop_debugInfo_selectTime),
    .io_vecstin_bits_uop_debugInfo_issueTime (io_vecstin_bits_uop_debugInfo_issueTime),
    .io_vecstin_bits_uop_debugInfo_writebackTime (io_vecstin_bits_uop_debugInfo_writebackTime),
    .io_vecstin_bits_uop_debugInfo_runahead_checkpoint_id (io_vecstin_bits_uop_debugInfo_runahead_checkpoint_id),
    .io_vecstin_bits_uop_debugInfo_tlbFirstReqTime (io_vecstin_bits_uop_debugInfo_tlbFirstReqTime),
    .io_vecstin_bits_uop_debugInfo_tlbRespTime (io_vecstin_bits_uop_debugInfo_tlbRespTime),
    .io_vecstin_bits_uop_debug_seqNum_seqNum (io_vecstin_bits_uop_debug_seqNum_seqNum),
    .io_vecstin_bits_uop_debug_seqNum_uopIdx (io_vecstin_bits_uop_debug_seqNum_uopIdx),
    .io_vecstin_bits_uop_lqIdx_flag (io_vecstin_bits_uop_lqIdx_flag),
    .io_vecstin_bits_uop_lqIdx_value (io_vecstin_bits_uop_lqIdx_value),
    .io_vecstin_bits_uop_sqIdx_flag (io_vecstin_bits_uop_sqIdx_flag),
    .io_vecstin_bits_uop_sqIdx_value (io_vecstin_bits_uop_sqIdx_value),
    .io_vecstin_bits_mBIndex (io_vecstin_bits_mBIndex),
    .io_vecstin_bits_elemIdx (io_vecstin_bits_elemIdx),
    .io_vecstin_bits_splitIndex (io_vecstin_bits_splitIndex),
    .io_misalign_enq_req_ready (io_misalign_enq_req_ready),
    .io_misalign_enq_req_valid (x_io_misalign_enq_req_valid),
    .io_misalign_enq_req_bits_uop_exceptionVec_0 (x_io_misalign_enq_req_bits_uop_exceptionVec_0),
    .io_misalign_enq_req_bits_uop_exceptionVec_1 (x_io_misalign_enq_req_bits_uop_exceptionVec_1),
    .io_misalign_enq_req_bits_uop_exceptionVec_2 (x_io_misalign_enq_req_bits_uop_exceptionVec_2),
    .io_misalign_enq_req_bits_uop_exceptionVec_4 (x_io_misalign_enq_req_bits_uop_exceptionVec_4),
    .io_misalign_enq_req_bits_uop_exceptionVec_5 (x_io_misalign_enq_req_bits_uop_exceptionVec_5),
    .io_misalign_enq_req_bits_uop_exceptionVec_8 (x_io_misalign_enq_req_bits_uop_exceptionVec_8),
    .io_misalign_enq_req_bits_uop_exceptionVec_9 (x_io_misalign_enq_req_bits_uop_exceptionVec_9),
    .io_misalign_enq_req_bits_uop_exceptionVec_10 (x_io_misalign_enq_req_bits_uop_exceptionVec_10),
    .io_misalign_enq_req_bits_uop_exceptionVec_11 (x_io_misalign_enq_req_bits_uop_exceptionVec_11),
    .io_misalign_enq_req_bits_uop_exceptionVec_12 (x_io_misalign_enq_req_bits_uop_exceptionVec_12),
    .io_misalign_enq_req_bits_uop_exceptionVec_13 (x_io_misalign_enq_req_bits_uop_exceptionVec_13),
    .io_misalign_enq_req_bits_uop_exceptionVec_14 (x_io_misalign_enq_req_bits_uop_exceptionVec_14),
    .io_misalign_enq_req_bits_uop_exceptionVec_16 (x_io_misalign_enq_req_bits_uop_exceptionVec_16),
    .io_misalign_enq_req_bits_uop_exceptionVec_17 (x_io_misalign_enq_req_bits_uop_exceptionVec_17),
    .io_misalign_enq_req_bits_uop_exceptionVec_18 (x_io_misalign_enq_req_bits_uop_exceptionVec_18),
    .io_misalign_enq_req_bits_uop_exceptionVec_19 (x_io_misalign_enq_req_bits_uop_exceptionVec_19),
    .io_misalign_enq_req_bits_uop_exceptionVec_20 (x_io_misalign_enq_req_bits_uop_exceptionVec_20),
    .io_misalign_enq_req_bits_uop_exceptionVec_21 (x_io_misalign_enq_req_bits_uop_exceptionVec_21),
    .io_misalign_enq_req_bits_uop_exceptionVec_22 (x_io_misalign_enq_req_bits_uop_exceptionVec_22),
    .io_misalign_enq_req_bits_uop_trigger (x_io_misalign_enq_req_bits_uop_trigger),
    .io_misalign_enq_req_bits_uop_ftqPtr_flag (x_io_misalign_enq_req_bits_uop_ftqPtr_flag),
    .io_misalign_enq_req_bits_uop_ftqPtr_value (x_io_misalign_enq_req_bits_uop_ftqPtr_value),
    .io_misalign_enq_req_bits_uop_ftqOffset (x_io_misalign_enq_req_bits_uop_ftqOffset),
    .io_misalign_enq_req_bits_uop_fuType (x_io_misalign_enq_req_bits_uop_fuType),
    .io_misalign_enq_req_bits_uop_fuOpType (x_io_misalign_enq_req_bits_uop_fuOpType),
    .io_misalign_enq_req_bits_uop_rfWen (x_io_misalign_enq_req_bits_uop_rfWen),
    .io_misalign_enq_req_bits_uop_vpu_vstart (x_io_misalign_enq_req_bits_uop_vpu_vstart),
    .io_misalign_enq_req_bits_uop_vpu_nf (x_io_misalign_enq_req_bits_uop_vpu_nf),
    .io_misalign_enq_req_bits_uop_vpu_veew (x_io_misalign_enq_req_bits_uop_vpu_veew),
    .io_misalign_enq_req_bits_uop_uopIdx (x_io_misalign_enq_req_bits_uop_uopIdx),
    .io_misalign_enq_req_bits_uop_pdest (x_io_misalign_enq_req_bits_uop_pdest),
    .io_misalign_enq_req_bits_uop_robIdx_flag (x_io_misalign_enq_req_bits_uop_robIdx_flag),
    .io_misalign_enq_req_bits_uop_robIdx_value (x_io_misalign_enq_req_bits_uop_robIdx_value),
    .io_misalign_enq_req_bits_uop_debugInfo_eliminatedMove (x_io_misalign_enq_req_bits_uop_debugInfo_eliminatedMove),
    .io_misalign_enq_req_bits_uop_debugInfo_renameTime (x_io_misalign_enq_req_bits_uop_debugInfo_renameTime),
    .io_misalign_enq_req_bits_uop_debugInfo_dispatchTime (x_io_misalign_enq_req_bits_uop_debugInfo_dispatchTime),
    .io_misalign_enq_req_bits_uop_debugInfo_enqRsTime (x_io_misalign_enq_req_bits_uop_debugInfo_enqRsTime),
    .io_misalign_enq_req_bits_uop_debugInfo_selectTime (x_io_misalign_enq_req_bits_uop_debugInfo_selectTime),
    .io_misalign_enq_req_bits_uop_debugInfo_issueTime (x_io_misalign_enq_req_bits_uop_debugInfo_issueTime),
    .io_misalign_enq_req_bits_uop_debugInfo_writebackTime (x_io_misalign_enq_req_bits_uop_debugInfo_writebackTime),
    .io_misalign_enq_req_bits_uop_debugInfo_runahead_checkpoint_id (x_io_misalign_enq_req_bits_uop_debugInfo_runahead_checkpoint_id),
    .io_misalign_enq_req_bits_uop_debugInfo_tlbFirstReqTime (x_io_misalign_enq_req_bits_uop_debugInfo_tlbFirstReqTime),
    .io_misalign_enq_req_bits_uop_debugInfo_tlbRespTime (x_io_misalign_enq_req_bits_uop_debugInfo_tlbRespTime),
    .io_misalign_enq_req_bits_uop_debug_seqNum_seqNum (x_io_misalign_enq_req_bits_uop_debug_seqNum_seqNum),
    .io_misalign_enq_req_bits_uop_debug_seqNum_uopIdx (x_io_misalign_enq_req_bits_uop_debug_seqNum_uopIdx),
    .io_misalign_enq_req_bits_uop_lqIdx_flag (x_io_misalign_enq_req_bits_uop_lqIdx_flag),
    .io_misalign_enq_req_bits_uop_lqIdx_value (x_io_misalign_enq_req_bits_uop_lqIdx_value),
    .io_misalign_enq_req_bits_uop_sqIdx_flag (x_io_misalign_enq_req_bits_uop_sqIdx_flag),
    .io_misalign_enq_req_bits_uop_sqIdx_value (x_io_misalign_enq_req_bits_uop_sqIdx_value),
    .io_misalign_enq_req_bits_vaddr (x_io_misalign_enq_req_bits_vaddr),
    .io_misalign_enq_req_bits_mask (x_io_misalign_enq_req_bits_mask),
    .io_misalign_enq_req_bits_isvec (x_io_misalign_enq_req_bits_isvec),
    .io_misalign_enq_req_bits_elemIdx (x_io_misalign_enq_req_bits_elemIdx),
    .io_misalign_enq_req_bits_alignedType (x_io_misalign_enq_req_bits_alignedType),
    .io_misalign_enq_req_bits_mbIndex (x_io_misalign_enq_req_bits_mbIndex),
    .io_misalign_enq_req_bits_splitIndex (x_io_misalign_enq_req_bits_splitIndex),
    .io_misalign_enq_revoke (x_io_misalign_enq_revoke),
    .io_fromCsrTrigger_tdataVec_0_matchType (io_fromCsrTrigger_tdataVec_0_matchType),
    .io_fromCsrTrigger_tdataVec_0_select (io_fromCsrTrigger_tdataVec_0_select),
    .io_fromCsrTrigger_tdataVec_0_timing (io_fromCsrTrigger_tdataVec_0_timing),
    .io_fromCsrTrigger_tdataVec_0_action (io_fromCsrTrigger_tdataVec_0_action),
    .io_fromCsrTrigger_tdataVec_0_chain (io_fromCsrTrigger_tdataVec_0_chain),
    .io_fromCsrTrigger_tdataVec_0_store (io_fromCsrTrigger_tdataVec_0_store),
    .io_fromCsrTrigger_tdataVec_0_tdata2 (io_fromCsrTrigger_tdataVec_0_tdata2),
    .io_fromCsrTrigger_tdataVec_1_matchType (io_fromCsrTrigger_tdataVec_1_matchType),
    .io_fromCsrTrigger_tdataVec_1_select (io_fromCsrTrigger_tdataVec_1_select),
    .io_fromCsrTrigger_tdataVec_1_timing (io_fromCsrTrigger_tdataVec_1_timing),
    .io_fromCsrTrigger_tdataVec_1_action (io_fromCsrTrigger_tdataVec_1_action),
    .io_fromCsrTrigger_tdataVec_1_chain (io_fromCsrTrigger_tdataVec_1_chain),
    .io_fromCsrTrigger_tdataVec_1_store (io_fromCsrTrigger_tdataVec_1_store),
    .io_fromCsrTrigger_tdataVec_1_tdata2 (io_fromCsrTrigger_tdataVec_1_tdata2),
    .io_fromCsrTrigger_tdataVec_2_matchType (io_fromCsrTrigger_tdataVec_2_matchType),
    .io_fromCsrTrigger_tdataVec_2_select (io_fromCsrTrigger_tdataVec_2_select),
    .io_fromCsrTrigger_tdataVec_2_timing (io_fromCsrTrigger_tdataVec_2_timing),
    .io_fromCsrTrigger_tdataVec_2_action (io_fromCsrTrigger_tdataVec_2_action),
    .io_fromCsrTrigger_tdataVec_2_chain (io_fromCsrTrigger_tdataVec_2_chain),
    .io_fromCsrTrigger_tdataVec_2_store (io_fromCsrTrigger_tdataVec_2_store),
    .io_fromCsrTrigger_tdataVec_2_tdata2 (io_fromCsrTrigger_tdataVec_2_tdata2),
    .io_fromCsrTrigger_tdataVec_3_matchType (io_fromCsrTrigger_tdataVec_3_matchType),
    .io_fromCsrTrigger_tdataVec_3_select (io_fromCsrTrigger_tdataVec_3_select),
    .io_fromCsrTrigger_tdataVec_3_timing (io_fromCsrTrigger_tdataVec_3_timing),
    .io_fromCsrTrigger_tdataVec_3_action (io_fromCsrTrigger_tdataVec_3_action),
    .io_fromCsrTrigger_tdataVec_3_chain (io_fromCsrTrigger_tdataVec_3_chain),
    .io_fromCsrTrigger_tdataVec_3_store (io_fromCsrTrigger_tdataVec_3_store),
    .io_fromCsrTrigger_tdataVec_3_tdata2 (io_fromCsrTrigger_tdataVec_3_tdata2),
    .io_fromCsrTrigger_tEnableVec_0 (io_fromCsrTrigger_tEnableVec_0),
    .io_fromCsrTrigger_tEnableVec_1 (io_fromCsrTrigger_tEnableVec_1),
    .io_fromCsrTrigger_tEnableVec_2 (io_fromCsrTrigger_tEnableVec_2),
    .io_fromCsrTrigger_tEnableVec_3 (io_fromCsrTrigger_tEnableVec_3),
    .io_fromCsrTrigger_debugMode (io_fromCsrTrigger_debugMode),
    .io_fromCsrTrigger_triggerCanRaiseBpExp (io_fromCsrTrigger_triggerCanRaiseBpExp),
    .io_sqCommitPtr_flag (io_sqCommitPtr_flag),
    .io_sqCommitPtr_value (io_sqCommitPtr_value),
    .io_sqCommitUopIdx (io_sqCommitUopIdx),
    .io_sqCommitRobIdx_flag (io_sqCommitRobIdx_flag),
    .io_sqCommitRobIdx_value (io_sqCommitRobIdx_value)
  );

  // ---- 所有输入整体随机（整形在 drive 里）----
  task automatic drive_random();
    io_redirect_valid = 1'($urandom);
    io_redirect_bits_robIdx_flag = 1'($urandom);
    io_redirect_bits_robIdx_value = 8'($urandom);
    io_redirect_bits_level = 1'($urandom);
    io_csrCtrl_hd_misalign_st_enable = 1'($urandom);
    io_stin_valid = 1'($urandom);
    io_stin_bits_uop_ftqPtr_flag = 1'($urandom);
    io_stin_bits_uop_ftqPtr_value = 6'($urandom);
    io_stin_bits_uop_ftqOffset = 4'($urandom);
    io_stin_bits_uop_fuType = 35'({$urandom, $urandom});
    io_stin_bits_uop_fuOpType = 9'($urandom);
    io_stin_bits_uop_rfWen = 1'($urandom);
    io_stin_bits_uop_imm = 32'($urandom);
    io_stin_bits_uop_pdest = 8'($urandom);
    io_stin_bits_uop_robIdx_flag = 1'($urandom);
    io_stin_bits_uop_robIdx_value = 8'($urandom);
    io_stin_bits_uop_debugInfo_eliminatedMove = 1'($urandom);
    io_stin_bits_uop_debugInfo_renameTime = 64'({$urandom, $urandom});
    io_stin_bits_uop_debugInfo_dispatchTime = 64'({$urandom, $urandom});
    io_stin_bits_uop_debugInfo_enqRsTime = 64'({$urandom, $urandom});
    io_stin_bits_uop_debugInfo_selectTime = 64'({$urandom, $urandom});
    io_stin_bits_uop_debugInfo_issueTime = 64'({$urandom, $urandom});
    io_stin_bits_uop_debugInfo_writebackTime = 64'({$urandom, $urandom});
    io_stin_bits_uop_debugInfo_runahead_checkpoint_id = 64'({$urandom, $urandom});
    io_stin_bits_uop_debugInfo_tlbFirstReqTime = 64'({$urandom, $urandom});
    io_stin_bits_uop_debugInfo_tlbRespTime = 64'({$urandom, $urandom});
    io_stin_bits_uop_debug_seqNum_seqNum = 56'({$urandom, $urandom});
    io_stin_bits_uop_debug_seqNum_uopIdx = 8'($urandom);
    io_stin_bits_uop_lqIdx_flag = 1'($urandom);
    io_stin_bits_uop_lqIdx_value = 7'($urandom);
    io_stin_bits_uop_sqIdx_flag = 1'($urandom);
    io_stin_bits_uop_sqIdx_value = 6'($urandom);
    io_stin_bits_src_0 = 64'({$urandom, $urandom});
    io_stin_bits_isFirstIssue = 1'($urandom);
    io_misalign_stin_valid = 1'($urandom);
    io_misalign_stin_bits_uop_exceptionVec_0 = ($urandom_range(0, 7) == 0);
    io_misalign_stin_bits_uop_exceptionVec_1 = ($urandom_range(0, 7) == 0);
    io_misalign_stin_bits_uop_exceptionVec_2 = ($urandom_range(0, 7) == 0);
    io_misalign_stin_bits_uop_exceptionVec_4 = ($urandom_range(0, 7) == 0);
    io_misalign_stin_bits_uop_exceptionVec_5 = ($urandom_range(0, 7) == 0);
    io_misalign_stin_bits_uop_exceptionVec_8 = ($urandom_range(0, 7) == 0);
    io_misalign_stin_bits_uop_exceptionVec_9 = ($urandom_range(0, 7) == 0);
    io_misalign_stin_bits_uop_exceptionVec_10 = ($urandom_range(0, 7) == 0);
    io_misalign_stin_bits_uop_exceptionVec_11 = ($urandom_range(0, 7) == 0);
    io_misalign_stin_bits_uop_exceptionVec_12 = ($urandom_range(0, 7) == 0);
    io_misalign_stin_bits_uop_exceptionVec_13 = ($urandom_range(0, 7) == 0);
    io_misalign_stin_bits_uop_exceptionVec_14 = ($urandom_range(0, 7) == 0);
    io_misalign_stin_bits_uop_exceptionVec_16 = ($urandom_range(0, 7) == 0);
    io_misalign_stin_bits_uop_exceptionVec_17 = ($urandom_range(0, 7) == 0);
    io_misalign_stin_bits_uop_exceptionVec_18 = ($urandom_range(0, 7) == 0);
    io_misalign_stin_bits_uop_exceptionVec_19 = ($urandom_range(0, 7) == 0);
    io_misalign_stin_bits_uop_exceptionVec_20 = ($urandom_range(0, 7) == 0);
    io_misalign_stin_bits_uop_exceptionVec_21 = ($urandom_range(0, 7) == 0);
    io_misalign_stin_bits_uop_exceptionVec_22 = ($urandom_range(0, 7) == 0);
    io_misalign_stin_bits_uop_trigger = 4'($urandom);
    io_misalign_stin_bits_uop_ftqPtr_flag = 1'($urandom);
    io_misalign_stin_bits_uop_ftqPtr_value = 6'($urandom);
    io_misalign_stin_bits_uop_ftqOffset = 4'($urandom);
    io_misalign_stin_bits_uop_fuType = 35'({$urandom, $urandom});
    io_misalign_stin_bits_uop_fuOpType = 9'($urandom);
    io_misalign_stin_bits_uop_rfWen = 1'($urandom);
    io_misalign_stin_bits_uop_vpu_vstart = 8'($urandom);
    io_misalign_stin_bits_uop_vpu_nf = 3'($urandom);
    io_misalign_stin_bits_uop_vpu_veew = 2'($urandom);
    io_misalign_stin_bits_uop_uopIdx = 7'($urandom);
    io_misalign_stin_bits_uop_pdest = 8'($urandom);
    io_misalign_stin_bits_uop_robIdx_flag = 1'($urandom);
    io_misalign_stin_bits_uop_robIdx_value = 8'($urandom);
    io_misalign_stin_bits_uop_debugInfo_eliminatedMove = 1'($urandom);
    io_misalign_stin_bits_uop_debugInfo_renameTime = 64'({$urandom, $urandom});
    io_misalign_stin_bits_uop_debugInfo_dispatchTime = 64'({$urandom, $urandom});
    io_misalign_stin_bits_uop_debugInfo_enqRsTime = 64'({$urandom, $urandom});
    io_misalign_stin_bits_uop_debugInfo_selectTime = 64'({$urandom, $urandom});
    io_misalign_stin_bits_uop_debugInfo_issueTime = 64'({$urandom, $urandom});
    io_misalign_stin_bits_uop_debugInfo_writebackTime = 64'({$urandom, $urandom});
    io_misalign_stin_bits_uop_debugInfo_runahead_checkpoint_id = 64'({$urandom, $urandom});
    io_misalign_stin_bits_uop_debugInfo_tlbFirstReqTime = 64'({$urandom, $urandom});
    io_misalign_stin_bits_uop_debugInfo_tlbRespTime = 64'({$urandom, $urandom});
    io_misalign_stin_bits_uop_debug_seqNum_seqNum = 56'({$urandom, $urandom});
    io_misalign_stin_bits_uop_debug_seqNum_uopIdx = 8'($urandom);
    io_misalign_stin_bits_uop_lqIdx_flag = 1'($urandom);
    io_misalign_stin_bits_uop_lqIdx_value = 7'($urandom);
    io_misalign_stin_bits_uop_sqIdx_flag = 1'($urandom);
    io_misalign_stin_bits_uop_sqIdx_value = 6'($urandom);
    io_misalign_stin_bits_vaddr = 50'({$urandom, $urandom});
    io_misalign_stin_bits_mask = 16'($urandom);
    io_misalign_stin_bits_isvec = 1'($urandom);
    io_misalign_stin_bits_is128bit = 1'($urandom);
    io_misalign_stin_bits_isFinalSplit = 1'($urandom);
    io_tlb_resp_valid = 1'($urandom);
    io_tlb_resp_bits_paddr_0 = 48'({$urandom, $urandom});
    io_tlb_resp_bits_gpaddr_0 = 64'({$urandom, $urandom});
    io_tlb_resp_bits_fullva = 64'({$urandom, $urandom});
    io_tlb_resp_bits_pbmt_0 = 2'($urandom);
    io_tlb_resp_bits_miss = 1'($urandom);
    io_tlb_resp_bits_isForVSnonLeafPTE = 1'($urandom);
    io_tlb_resp_bits_excp_0_vaNeedExt = 1'($urandom);
    io_tlb_resp_bits_excp_0_isHyper = 1'($urandom);
    io_tlb_resp_bits_excp_0_gpf_ld = 1'($urandom);
    io_tlb_resp_bits_excp_0_gpf_st = 1'($urandom);
    io_tlb_resp_bits_excp_0_pf_ld = 1'($urandom);
    io_tlb_resp_bits_excp_0_pf_st = 1'($urandom);
    io_tlb_resp_bits_excp_0_af_ld = 1'($urandom);
    io_tlb_resp_bits_excp_0_af_st = 1'($urandom);
    io_tlb_resp_bits_ptwBack = 1'($urandom);
    io_tlb_resp_bits_memidx_idx = 7'($urandom);
    io_pmp_ld = 1'($urandom);
    io_pmp_st = 1'($urandom);
    io_pmp_mmio = 1'($urandom);
    io_vecstin_valid = 1'($urandom);
    io_vecstin_bits_vaddr = 64'({$urandom, $urandom});
    io_vecstin_bits_basevaddr = 50'({$urandom, $urandom});
    io_vecstin_bits_mask = 16'($urandom);
    io_vecstin_bits_alignedType = 3'($urandom);
    io_vecstin_bits_vecActive = 1'($urandom);
    io_vecstin_bits_vecIsFirstActiveElement = 1'($urandom);
    io_vecstin_bits_uop_exceptionVec_4 = ($urandom_range(0, 7) == 0);
    io_vecstin_bits_uop_exceptionVec_5 = ($urandom_range(0, 7) == 0);
    io_vecstin_bits_uop_exceptionVec_6 = ($urandom_range(0, 7) == 0);
    io_vecstin_bits_uop_exceptionVec_13 = ($urandom_range(0, 7) == 0);
    io_vecstin_bits_uop_exceptionVec_19 = ($urandom_range(0, 7) == 0);
    io_vecstin_bits_uop_exceptionVec_21 = ($urandom_range(0, 7) == 0);
    io_vecstin_bits_uop_trigger = 4'($urandom);
    io_vecstin_bits_uop_ftqPtr_flag = 1'($urandom);
    io_vecstin_bits_uop_ftqPtr_value = 6'($urandom);
    io_vecstin_bits_uop_ftqOffset = 4'($urandom);
    io_vecstin_bits_uop_fuType = 35'({$urandom, $urandom});
    io_vecstin_bits_uop_fuOpType = 9'($urandom);
    io_vecstin_bits_uop_rfWen = 1'($urandom);
    io_vecstin_bits_uop_vpu_vstart = 8'($urandom);
    io_vecstin_bits_uop_vpu_nf = 3'($urandom);
    io_vecstin_bits_uop_vpu_veew = 2'($urandom);
    io_vecstin_bits_uop_uopIdx = 7'($urandom);
    io_vecstin_bits_uop_pdest = 8'($urandom);
    io_vecstin_bits_uop_robIdx_flag = 1'($urandom);
    io_vecstin_bits_uop_robIdx_value = 8'($urandom);
    io_vecstin_bits_uop_debugInfo_eliminatedMove = 1'($urandom);
    io_vecstin_bits_uop_debugInfo_renameTime = 64'({$urandom, $urandom});
    io_vecstin_bits_uop_debugInfo_dispatchTime = 64'({$urandom, $urandom});
    io_vecstin_bits_uop_debugInfo_enqRsTime = 64'({$urandom, $urandom});
    io_vecstin_bits_uop_debugInfo_selectTime = 64'({$urandom, $urandom});
    io_vecstin_bits_uop_debugInfo_issueTime = 64'({$urandom, $urandom});
    io_vecstin_bits_uop_debugInfo_writebackTime = 64'({$urandom, $urandom});
    io_vecstin_bits_uop_debugInfo_runahead_checkpoint_id = 64'({$urandom, $urandom});
    io_vecstin_bits_uop_debugInfo_tlbFirstReqTime = 64'({$urandom, $urandom});
    io_vecstin_bits_uop_debugInfo_tlbRespTime = 64'({$urandom, $urandom});
    io_vecstin_bits_uop_debug_seqNum_seqNum = 56'({$urandom, $urandom});
    io_vecstin_bits_uop_debug_seqNum_uopIdx = 8'($urandom);
    io_vecstin_bits_uop_lqIdx_flag = 1'($urandom);
    io_vecstin_bits_uop_lqIdx_value = 7'($urandom);
    io_vecstin_bits_uop_sqIdx_flag = 1'($urandom);
    io_vecstin_bits_uop_sqIdx_value = 6'($urandom);
    io_vecstin_bits_mBIndex = 4'($urandom);
    io_vecstin_bits_elemIdx = 8'($urandom);
    io_vecstin_bits_splitIndex = 5'($urandom);
    io_misalign_enq_req_ready = 1'($urandom);
    io_fromCsrTrigger_tdataVec_0_matchType = 2'($urandom);
    io_fromCsrTrigger_tdataVec_0_select = 1'($urandom);
    io_fromCsrTrigger_tdataVec_0_timing = 1'($urandom);
    io_fromCsrTrigger_tdataVec_0_action = 4'($urandom);
    io_fromCsrTrigger_tdataVec_0_chain = 1'($urandom);
    io_fromCsrTrigger_tdataVec_0_store = 1'($urandom);
    io_fromCsrTrigger_tdataVec_0_tdata2 = 64'({$urandom, $urandom});
    io_fromCsrTrigger_tdataVec_1_matchType = 2'($urandom);
    io_fromCsrTrigger_tdataVec_1_select = 1'($urandom);
    io_fromCsrTrigger_tdataVec_1_timing = 1'($urandom);
    io_fromCsrTrigger_tdataVec_1_action = 4'($urandom);
    io_fromCsrTrigger_tdataVec_1_chain = 1'($urandom);
    io_fromCsrTrigger_tdataVec_1_store = 1'($urandom);
    io_fromCsrTrigger_tdataVec_1_tdata2 = 64'({$urandom, $urandom});
    io_fromCsrTrigger_tdataVec_2_matchType = 2'($urandom);
    io_fromCsrTrigger_tdataVec_2_select = 1'($urandom);
    io_fromCsrTrigger_tdataVec_2_timing = 1'($urandom);
    io_fromCsrTrigger_tdataVec_2_action = 4'($urandom);
    io_fromCsrTrigger_tdataVec_2_chain = 1'($urandom);
    io_fromCsrTrigger_tdataVec_2_store = 1'($urandom);
    io_fromCsrTrigger_tdataVec_2_tdata2 = 64'({$urandom, $urandom});
    io_fromCsrTrigger_tdataVec_3_matchType = 2'($urandom);
    io_fromCsrTrigger_tdataVec_3_select = 1'($urandom);
    io_fromCsrTrigger_tdataVec_3_timing = 1'($urandom);
    io_fromCsrTrigger_tdataVec_3_action = 4'($urandom);
    io_fromCsrTrigger_tdataVec_3_chain = 1'($urandom);
    io_fromCsrTrigger_tdataVec_3_store = 1'($urandom);
    io_fromCsrTrigger_tdataVec_3_tdata2 = 64'({$urandom, $urandom});
    io_fromCsrTrigger_tEnableVec_0 = 1'($urandom);
    io_fromCsrTrigger_tEnableVec_1 = 1'($urandom);
    io_fromCsrTrigger_tEnableVec_2 = 1'($urandom);
    io_fromCsrTrigger_tEnableVec_3 = 1'($urandom);
    io_fromCsrTrigger_debugMode = 1'($urandom);
    io_fromCsrTrigger_triggerCanRaiseBpExp = 1'($urandom);
    io_sqCommitPtr_flag = 1'($urandom);
    io_sqCommitPtr_value = 6'($urandom);
    io_sqCommitUopIdx = 7'($urandom);
    io_sqCommitRobIdx_flag = 1'($urandom);
    io_sqCommitRobIdx_value = 8'($urandom);
  endtask

  // ---- 逐根比较 ----
`define CMP(SIG) \
    if (g_``SIG !== x_``SIG) begin \
      errors++; \
      if (errors < 30) $display("MISMATCH @%0d %s g=%h x=%h", checks, `"SIG`", g_``SIG, x_``SIG); \
    end
  task automatic compare();
    checks++;
    `CMP(io_stin_ready)
    `CMP(io_issue_valid)
    `CMP(io_issue_bits_uop_robIdx_flag)
    `CMP(io_issue_bits_uop_robIdx_value)
    `CMP(io_misalign_stin_ready)
    `CMP(io_misalign_stout_valid)
    `CMP(io_misalign_stout_bits_uop_exceptionVec_3)
    `CMP(io_misalign_stout_bits_uop_exceptionVec_6)
    `CMP(io_misalign_stout_bits_uop_exceptionVec_7)
    `CMP(io_misalign_stout_bits_uop_exceptionVec_15)
    `CMP(io_misalign_stout_bits_uop_exceptionVec_19)
    `CMP(io_misalign_stout_bits_uop_exceptionVec_23)
    `CMP(io_misalign_stout_bits_uop_trigger)
    `CMP(io_misalign_stout_bits_uop_robIdx_flag)
    `CMP(io_misalign_stout_bits_uop_robIdx_value)
    `CMP(io_misalign_stout_bits_vaddr)
    `CMP(io_misalign_stout_bits_vaNeedExt)
    `CMP(io_misalign_stout_bits_paddr)
    `CMP(io_misalign_stout_bits_gpaddr)
    `CMP(io_misalign_stout_bits_nc)
    `CMP(io_misalign_stout_bits_mmio)
    `CMP(io_misalign_stout_bits_memBackTypeMM)
    `CMP(io_misalign_stout_bits_isForVSnonLeafPTE)
    `CMP(io_misalign_stout_bits_vecActive)
    `CMP(io_misalign_stout_bits_need_rep)
    `CMP(io_tlb_req_valid)
    `CMP(io_tlb_req_bits_vaddr)
    `CMP(io_tlb_req_bits_fullva)
    `CMP(io_tlb_req_bits_checkfullva)
    `CMP(io_tlb_req_bits_cmd)
    `CMP(io_tlb_req_bits_hyperinst)
    `CMP(io_tlb_req_bits_memidx_idx)
    `CMP(io_tlb_req_bits_frm_mabuf)
    `CMP(io_tlb_req_bits_debug_robIdx_flag)
    `CMP(io_tlb_req_bits_debug_robIdx_value)
    `CMP(io_tlb_req_bits_debug_isFirstIssue)
    `CMP(io_dcache_req_valid)
    `CMP(io_lsq_valid)
    `CMP(io_lsq_bits_uop_exceptionVec_0)
    `CMP(io_lsq_bits_uop_exceptionVec_1)
    `CMP(io_lsq_bits_uop_exceptionVec_2)
    `CMP(io_lsq_bits_uop_exceptionVec_3)
    `CMP(io_lsq_bits_uop_exceptionVec_4)
    `CMP(io_lsq_bits_uop_exceptionVec_5)
    `CMP(io_lsq_bits_uop_exceptionVec_6)
    `CMP(io_lsq_bits_uop_exceptionVec_7)
    `CMP(io_lsq_bits_uop_exceptionVec_8)
    `CMP(io_lsq_bits_uop_exceptionVec_9)
    `CMP(io_lsq_bits_uop_exceptionVec_10)
    `CMP(io_lsq_bits_uop_exceptionVec_11)
    `CMP(io_lsq_bits_uop_exceptionVec_12)
    `CMP(io_lsq_bits_uop_exceptionVec_13)
    `CMP(io_lsq_bits_uop_exceptionVec_14)
    `CMP(io_lsq_bits_uop_exceptionVec_15)
    `CMP(io_lsq_bits_uop_exceptionVec_16)
    `CMP(io_lsq_bits_uop_exceptionVec_17)
    `CMP(io_lsq_bits_uop_exceptionVec_18)
    `CMP(io_lsq_bits_uop_exceptionVec_19)
    `CMP(io_lsq_bits_uop_exceptionVec_20)
    `CMP(io_lsq_bits_uop_exceptionVec_21)
    `CMP(io_lsq_bits_uop_exceptionVec_22)
    `CMP(io_lsq_bits_uop_exceptionVec_23)
    `CMP(io_lsq_bits_uop_trigger)
    `CMP(io_lsq_bits_uop_ftqPtr_flag)
    `CMP(io_lsq_bits_uop_ftqPtr_value)
    `CMP(io_lsq_bits_uop_ftqOffset)
    `CMP(io_lsq_bits_uop_fuType)
    `CMP(io_lsq_bits_uop_fuOpType)
    `CMP(io_lsq_bits_uop_rfWen)
    `CMP(io_lsq_bits_uop_vpu_nf)
    `CMP(io_lsq_bits_uop_vpu_veew)
    `CMP(io_lsq_bits_uop_uopIdx)
    `CMP(io_lsq_bits_uop_pdest)
    `CMP(io_lsq_bits_uop_robIdx_flag)
    `CMP(io_lsq_bits_uop_robIdx_value)
    `CMP(io_lsq_bits_uop_debugInfo_eliminatedMove)
    `CMP(io_lsq_bits_uop_debugInfo_renameTime)
    `CMP(io_lsq_bits_uop_debugInfo_dispatchTime)
    `CMP(io_lsq_bits_uop_debugInfo_enqRsTime)
    `CMP(io_lsq_bits_uop_debugInfo_selectTime)
    `CMP(io_lsq_bits_uop_debugInfo_issueTime)
    `CMP(io_lsq_bits_uop_debugInfo_writebackTime)
    `CMP(io_lsq_bits_uop_debugInfo_runahead_checkpoint_id)
    `CMP(io_lsq_bits_uop_debugInfo_tlbFirstReqTime)
    `CMP(io_lsq_bits_uop_debugInfo_tlbRespTime)
    `CMP(io_lsq_bits_uop_debug_seqNum_seqNum)
    `CMP(io_lsq_bits_uop_debug_seqNum_uopIdx)
    `CMP(io_lsq_bits_uop_sqIdx_flag)
    `CMP(io_lsq_bits_uop_sqIdx_value)
    `CMP(io_lsq_bits_vaddr)
    `CMP(io_lsq_bits_fullva)
    `CMP(io_lsq_bits_vaNeedExt)
    `CMP(io_lsq_bits_paddr)
    `CMP(io_lsq_bits_gpaddr)
    `CMP(io_lsq_bits_mask)
    `CMP(io_lsq_bits_wlineflag)
    `CMP(io_lsq_bits_miss)
    `CMP(io_lsq_bits_nc)
    `CMP(io_lsq_bits_isHyper)
    `CMP(io_lsq_bits_isForVSnonLeafPTE)
    `CMP(io_lsq_bits_isvec)
    `CMP(io_lsq_bits_isFrmMisAlignBuf)
    `CMP(io_lsq_bits_isMisalign)
    `CMP(io_lsq_bits_misalignWith16Byte)
    `CMP(io_lsq_bits_updateAddrValid)
    `CMP(io_lsq_replenish_uop_exceptionVec_3)
    `CMP(io_lsq_replenish_uop_exceptionVec_6)
    `CMP(io_lsq_replenish_uop_exceptionVec_15)
    `CMP(io_lsq_replenish_uop_exceptionVec_19)
    `CMP(io_lsq_replenish_uop_exceptionVec_23)
    `CMP(io_lsq_replenish_uop_uopIdx)
    `CMP(io_lsq_replenish_uop_robIdx_flag)
    `CMP(io_lsq_replenish_uop_robIdx_value)
    `CMP(io_lsq_replenish_fullva)
    `CMP(io_lsq_replenish_vaNeedExt)
    `CMP(io_lsq_replenish_gpaddr)
    `CMP(io_lsq_replenish_af)
    `CMP(io_lsq_replenish_mmio)
    `CMP(io_lsq_replenish_memBackTypeMM)
    `CMP(io_lsq_replenish_hasException)
    `CMP(io_lsq_replenish_isHyper)
    `CMP(io_lsq_replenish_isForVSnonLeafPTE)
    `CMP(io_lsq_replenish_isvec)
    `CMP(io_lsq_replenish_updateAddrValid)
    `CMP(io_feedback_slow_valid)
    `CMP(io_feedback_slow_bits_robIdx_flag)
    `CMP(io_feedback_slow_bits_robIdx_value)
    `CMP(io_feedback_slow_bits_hit)
    `CMP(io_feedback_slow_bits_flushState)
    `CMP(io_feedback_slow_bits_sqIdx_flag)
    `CMP(io_feedback_slow_bits_sqIdx_value)
    `CMP(io_feedback_slow_bits_lqIdx_flag)
    `CMP(io_feedback_slow_bits_lqIdx_value)
    `CMP(io_stld_nuke_query_valid)
    `CMP(io_stld_nuke_query_bits_robIdx_flag)
    `CMP(io_stld_nuke_query_bits_robIdx_value)
    `CMP(io_stld_nuke_query_bits_paddr)
    `CMP(io_stld_nuke_query_bits_mask)
    `CMP(io_stld_nuke_query_bits_matchType)
    `CMP(io_stout_valid)
    `CMP(io_stout_bits_uop_exceptionVec_3)
    `CMP(io_stout_bits_uop_exceptionVec_6)
    `CMP(io_stout_bits_uop_exceptionVec_7)
    `CMP(io_stout_bits_uop_exceptionVec_15)
    `CMP(io_stout_bits_uop_exceptionVec_19)
    `CMP(io_stout_bits_uop_exceptionVec_23)
    `CMP(io_stout_bits_uop_trigger)
    `CMP(io_stout_bits_uop_rfWen)
    `CMP(io_stout_bits_uop_pdest)
    `CMP(io_stout_bits_uop_robIdx_flag)
    `CMP(io_stout_bits_uop_robIdx_value)
    `CMP(io_stout_bits_uop_debugInfo_eliminatedMove)
    `CMP(io_stout_bits_uop_debugInfo_renameTime)
    `CMP(io_stout_bits_uop_debugInfo_dispatchTime)
    `CMP(io_stout_bits_uop_debugInfo_enqRsTime)
    `CMP(io_stout_bits_uop_debugInfo_selectTime)
    `CMP(io_stout_bits_uop_debugInfo_issueTime)
    `CMP(io_stout_bits_uop_debugInfo_writebackTime)
    `CMP(io_stout_bits_uop_debugInfo_runahead_checkpoint_id)
    `CMP(io_stout_bits_uop_debugInfo_tlbFirstReqTime)
    `CMP(io_stout_bits_uop_debugInfo_tlbRespTime)
    `CMP(io_stout_bits_uop_debug_seqNum_seqNum)
    `CMP(io_stout_bits_uop_debug_seqNum_uopIdx)
    `CMP(io_stout_bits_uop_sqIdx_flag)
    `CMP(io_stout_bits_uop_sqIdx_value)
    `CMP(io_stout_bits_debug_isMMIO)
    `CMP(io_stout_bits_debug_isNCIO)
    `CMP(io_stout_bits_debug_paddr)
    `CMP(io_stout_bits_debug_vaddr)
    `CMP(io_vecstout_valid)
    `CMP(io_vecstout_bits_mBIndex)
    `CMP(io_vecstout_bits_hit)
    `CMP(io_vecstout_bits_trigger)
    `CMP(io_vecstout_bits_exceptionVec_3)
    `CMP(io_vecstout_bits_exceptionVec_6)
    `CMP(io_vecstout_bits_exceptionVec_7)
    `CMP(io_vecstout_bits_exceptionVec_15)
    `CMP(io_vecstout_bits_exceptionVec_19)
    `CMP(io_vecstout_bits_exceptionVec_23)
    `CMP(io_vecstout_bits_hasException)
    `CMP(io_vecstout_bits_vaddr)
    `CMP(io_vecstout_bits_vaNeedExt)
    `CMP(io_vecstout_bits_gpaddr)
    `CMP(io_vecstout_bits_isForVSnonLeafPTE)
    `CMP(io_vecstout_bits_vstart)
    `CMP(io_vecstout_bits_elemIdx)
    `CMP(io_vecstout_bits_mask)
    `CMP(io_vecstout_bits_splitIndex)
    `CMP(io_st_mask_out_valid)
    `CMP(io_st_mask_out_bits_sqIdx_value)
    `CMP(io_st_mask_out_bits_mask)
    `CMP(io_vecstin_ready)
    `CMP(io_misalign_enq_req_valid)
    `CMP(io_misalign_enq_req_bits_uop_exceptionVec_0)
    `CMP(io_misalign_enq_req_bits_uop_exceptionVec_1)
    `CMP(io_misalign_enq_req_bits_uop_exceptionVec_2)
    `CMP(io_misalign_enq_req_bits_uop_exceptionVec_4)
    `CMP(io_misalign_enq_req_bits_uop_exceptionVec_5)
    `CMP(io_misalign_enq_req_bits_uop_exceptionVec_8)
    `CMP(io_misalign_enq_req_bits_uop_exceptionVec_9)
    `CMP(io_misalign_enq_req_bits_uop_exceptionVec_10)
    `CMP(io_misalign_enq_req_bits_uop_exceptionVec_11)
    `CMP(io_misalign_enq_req_bits_uop_exceptionVec_12)
    `CMP(io_misalign_enq_req_bits_uop_exceptionVec_13)
    `CMP(io_misalign_enq_req_bits_uop_exceptionVec_14)
    `CMP(io_misalign_enq_req_bits_uop_exceptionVec_16)
    `CMP(io_misalign_enq_req_bits_uop_exceptionVec_17)
    `CMP(io_misalign_enq_req_bits_uop_exceptionVec_18)
    `CMP(io_misalign_enq_req_bits_uop_exceptionVec_19)
    `CMP(io_misalign_enq_req_bits_uop_exceptionVec_20)
    `CMP(io_misalign_enq_req_bits_uop_exceptionVec_21)
    `CMP(io_misalign_enq_req_bits_uop_exceptionVec_22)
    `CMP(io_misalign_enq_req_bits_uop_trigger)
    `CMP(io_misalign_enq_req_bits_uop_ftqPtr_flag)
    `CMP(io_misalign_enq_req_bits_uop_ftqPtr_value)
    `CMP(io_misalign_enq_req_bits_uop_ftqOffset)
    `CMP(io_misalign_enq_req_bits_uop_fuType)
    `CMP(io_misalign_enq_req_bits_uop_fuOpType)
    `CMP(io_misalign_enq_req_bits_uop_rfWen)
    `CMP(io_misalign_enq_req_bits_uop_vpu_vstart)
    `CMP(io_misalign_enq_req_bits_uop_vpu_nf)
    `CMP(io_misalign_enq_req_bits_uop_vpu_veew)
    `CMP(io_misalign_enq_req_bits_uop_uopIdx)
    `CMP(io_misalign_enq_req_bits_uop_pdest)
    `CMP(io_misalign_enq_req_bits_uop_robIdx_flag)
    `CMP(io_misalign_enq_req_bits_uop_robIdx_value)
    `CMP(io_misalign_enq_req_bits_uop_debugInfo_eliminatedMove)
    `CMP(io_misalign_enq_req_bits_uop_debugInfo_renameTime)
    `CMP(io_misalign_enq_req_bits_uop_debugInfo_dispatchTime)
    `CMP(io_misalign_enq_req_bits_uop_debugInfo_enqRsTime)
    `CMP(io_misalign_enq_req_bits_uop_debugInfo_selectTime)
    `CMP(io_misalign_enq_req_bits_uop_debugInfo_issueTime)
    `CMP(io_misalign_enq_req_bits_uop_debugInfo_writebackTime)
    `CMP(io_misalign_enq_req_bits_uop_debugInfo_runahead_checkpoint_id)
    `CMP(io_misalign_enq_req_bits_uop_debugInfo_tlbFirstReqTime)
    `CMP(io_misalign_enq_req_bits_uop_debugInfo_tlbRespTime)
    `CMP(io_misalign_enq_req_bits_uop_debug_seqNum_seqNum)
    `CMP(io_misalign_enq_req_bits_uop_debug_seqNum_uopIdx)
    `CMP(io_misalign_enq_req_bits_uop_lqIdx_flag)
    `CMP(io_misalign_enq_req_bits_uop_lqIdx_value)
    `CMP(io_misalign_enq_req_bits_uop_sqIdx_flag)
    `CMP(io_misalign_enq_req_bits_uop_sqIdx_value)
    `CMP(io_misalign_enq_req_bits_vaddr)
    `CMP(io_misalign_enq_req_bits_mask)
    `CMP(io_misalign_enq_req_bits_isvec)
    `CMP(io_misalign_enq_req_bits_elemIdx)
    `CMP(io_misalign_enq_req_bits_alignedType)
    `CMP(io_misalign_enq_req_bits_mbIndex)
    `CMP(io_misalign_enq_req_bits_splitIndex)
    `CMP(io_misalign_enq_revoke)
  endtask

  // ---------------------------------------------------------------------------
  // 手写：激励整形
  // ---------------------------------------------------------------------------
  function automatic logic [63:0] near(logic [63:0] va);
    logic [63:0] t;
    case ($urandom_range(0, 7))
      0: t = {14'h0, va[49:0]};
      1: t = {14'h0, va[49:0]} + $urandom_range(1, 40);
      2: t = {14'h0, va[49:0]} - $urandom_range(1, 40);
      3: t = {14'h0, va[49:4], 4'($urandom)};
      4: t = {14'($urandom), va[49:4], 4'($urandom)};
      5: t = {14'h0, va[49:6], 6'($urandom)};
      6: t = {14'h0, va[49:6] + 44'($urandom_range(0, 2)) - 44'd1, 6'($urandom)};
      default: t = {$urandom, $urandom};
    endcase
    return t;
  endfunction

`define TRIG_CFG(I) \
    io_fromCsrTrigger_tdataVec_``I``_matchType = 2'($urandom); \
    io_fromCsrTrigger_tdataVec_``I``_select    = ($urandom_range(0, 9) == 0); \
    io_fromCsrTrigger_tdataVec_``I``_timing    = ($urandom_range(0, 3) == 0); \
    io_fromCsrTrigger_tdataVec_``I``_chain     = ($urandom_range(0, 3) == 0); \
    io_fromCsrTrigger_tdataVec_``I``_store     = ($urandom_range(0, 9) != 0); \
    io_fromCsrTrigger_tdataVec_``I``_action    = ($urandom_range(0, 7) == 0) ? 4'($urandom) : 4'($urandom_range(0, 1)); \
    io_fromCsrTrigger_tdataVec_``I``_tdata2    = $urandom_range(0, 1) ? near(target) : {$urandom, $urandom}; \
    io_fromCsrTrigger_tEnableVec_``I``         = trig_on & ($urandom_range(0, 9) != 0);

  task automatic drive();
    logic [63:0] target;
    logic        trig_on;
    drive_random();
    io_redirect_valid      = ($urandom_range(0, 15) == 0);
    io_stin_valid          = ($urandom_range(0, 1) == 0);
    io_vecstin_valid       = ($urandom_range(0, 3) == 0);
    io_misalign_stin_valid = ($urandom_range(0, 7) == 0);
    case ($urandom_range(0, 15))
      0:       io_stin_bits_uop_fuOpType = 9'h007;                              // cbo.zero
      1:       io_stin_bits_uop_fuOpType = 9'h00C + 9'($urandom_range(0, 2));   // cbo.clean/flush/inval
      2:       io_stin_bits_uop_fuOpType = 9'h010 + 9'($urandom_range(0, 3));   // hsv.b/h/w/d
      3:       io_stin_bits_uop_fuOpType = 9'($urandom);
      default: io_stin_bits_uop_fuOpType = 9'($urandom_range(0, 3));            // sb/sh/sw/sd
    endcase
    if ($urandom_range(0, 3) != 0) io_misalign_stin_bits_uop_fuOpType = 9'($urandom_range(0, 3));
    if ($urandom_range(0, 1)) begin
      io_sqCommitPtr_flag  = io_stin_bits_uop_sqIdx_flag;
      io_sqCommitPtr_value = io_stin_bits_uop_sqIdx_value;
    end
    // TLB
    io_tlb_resp_valid     = ($urandom_range(0, 7) != 0);
    io_tlb_resp_bits_miss = ($urandom_range(0, 3) == 0);
    io_tlb_resp_bits_pbmt_0 = ($urandom_range(0, 7) < 5) ? 2'd0 : 2'($urandom);
    io_tlb_resp_bits_excp_0_gpf_ld = ($urandom_range(0, 15) == 0);
    io_tlb_resp_bits_excp_0_gpf_st = ($urandom_range(0, 15) == 0);
    io_tlb_resp_bits_excp_0_pf_ld  = ($urandom_range(0, 15) == 0);
    io_tlb_resp_bits_excp_0_pf_st  = ($urandom_range(0, 15) == 0);
    io_tlb_resp_bits_excp_0_af_ld  = ($urandom_range(0, 15) == 0);
    io_tlb_resp_bits_excp_0_af_st  = ($urandom_range(0, 15) == 0);
    if ($urandom_range(0, 1)) io_tlb_resp_bits_memidx_idx = {1'b0, u_golden.s1_in_uop_sqIdx_value};
    // PMP / CSR / 非对齐缓冲
    io_pmp_st   = ($urandom_range(0, 15) == 0);
    io_pmp_ld   = ($urandom_range(0, 15) == 0);
    io_pmp_mmio = ($urandom_range(0, 7) == 0);
    io_csrCtrl_hd_misalign_st_enable = ($urandom_range(0, 15) != 0);
    io_misalign_enq_req_ready        = ($urandom_range(0, 3) != 0);
    // 触发器
    target  = u_golden.s1_in_isFrmMisAlignBuf ? {14'h0, u_golden.s1_in_vaddr} : io_tlb_resp_bits_fullva;
    trig_on = ($urandom_range(0, 1) == 0);
    `TRIG_CFG(0)
    `TRIG_CFG(1)
    `TRIG_CFG(2)
    `TRIG_CFG(3)
    io_fromCsrTrigger_debugMode            = ($urandom_range(0, 15) == 0);
    io_fromCsrTrigger_triggerCanRaiseBpExp = ($urandom_range(0, 5) != 0);
  endtask

  // ---------------------------------------------------------------------------
  // 手写：覆盖计数（读重写核内部信号）
  // ---------------------------------------------------------------------------
  localparam int NCOV = 28;
  longint cov [NCOV];
  string  cov_names [NCOV] = '{
    "s0_fire_rs", "s0_fire_vec", "s0_fire_ma", "s0_kill", "s0_cbo", "s0_cross16", "s0_misalign_in16",
    "s0_need_replay", "s1_tlbmiss_kill", "s1_redirect_flush", "s1_trig_breakpoint", "s1_trig_debugmode",
    "s1_enq_misalign", "s1_enq_nack", "s1_resptime_stamp", "s2_mmio_kill", "s2_exception",
    "s2_access_fault", "s2_addr_misaligned", "s2_revoke", "s2_mab_stout", "s2_no_writeback",
    "s3_kill", "sx_kill", "stout", "vecstout", "feedback_hit", "feedback_miss"};
  int cov_min [NCOV] = '{
    1000, 1000, 1000, 100, 100, 100, 100,
    100, 100, 100, 20, 20,
    100, 20, 100, 20, 100,
    100, 5, 100, 100, 20,
    20, 20, 1000, 100, 100, 100};

`define C u_impl.u_core
  task automatic collect_cov();
    if (`C.s0_fire & `C.s0_use_flow_rs)  cov[0]++;
    if (`C.s0_fire & `C.s0_use_flow_vec) cov[1]++;
    if (`C.s0_fire & `C.s0_use_flow_ma)  cov[2]++;
    if (`C.s0_valid & `C.s0_kill)        cov[3]++;
    if (`C.s0_fire & `C.s0_isCbo)        cov[4]++;
    if (`C.s0_fire & `C.s0_rs_cross16Bytes & ~`C.s0_addr_aligned) cov[5]++;
    if (`C.s0_fire & `C.s0_misalignWith16Byte)                    cov[6]++;
    if (`C.s0_fire & `C.s0_misalignNeedReplay)                    cov[7]++;
    if (`C.s1_valid & `C.s1_tlb_miss & ~`C.s1_isvec & ~`C.s1_frm_mabuf) cov[8]++;
    if (`C.s1_valid & `C.s1_redirect_flush)                       cov[9]++;
    if (`C.s1_fire & `C.s1_trigger_breakpoint)                    cov[10]++;
    if (`C.s1_fire & `C.s1_trigger_debug_mode)                    cov[11]++;
    if (`C.misalign_enq_req_valid & io_misalign_enq_req_ready)    cov[12]++;
    if (`C.s1_fire & `C.s1_toMisalignBufferValid & (~io_misalign_enq_req_ready | `C.s1_misalignNeedReplay)) cov[13]++;
    if (`C.s1_fire & (`C.s1_out.uop.debugInfo_tlbRespTime == `C.s1_out_uop_debugInfo_tlbRespTime_c)) cov[14]++;
    if (`C.s2_valid & `C.s2_mmio & ~`C.s2_exception & ~`C.s2_in.isvec & ~`C.s2_frm_mabuf) cov[15]++;
    if (`C.s2_fire & `C.s2_exception)                             cov[16]++;
    if (`C.s2_fire & `C.s2_access_fault)                          cov[17]++;
    if (`C.s2_fire & `C.s2_addr_misaligned)                       cov[18]++;
    if (`C.s2_valid & `C.misalign_enq_revoke)                     cov[19]++;
    if (`C.misalign_stout_valid)                                  cov[20]++;
    if (`C.s2_fire & ~`C.s2_misalign_cango)                       cov[21]++;
    if (`C.s3_valid & `C.s3_kill)                                 cov[22]++;
    if (`C.sx_valid_1_r & `C.sx_cur_kill)                         cov[23]++;
    if (`C.stout_valid)                                           cov[24]++;
    if (`C.vecstout_valid)                                        cov[25]++;
    if (`C.feedback_slow_valid & `C.feedback_slow.hit)            cov[26]++;
    if (`C.feedback_slow_valid & ~`C.feedback_slow.hit)           cov[27]++;
  endtask

  initial begin
    int bad = 0;
    if (!$value$plusargs("ncycles=%d", NCYCLES)) NCYCLES = 200000;
    if (!$value$plusargs("warmup=%d", WARMUP))   WARMUP  = 0;
    for (int i = 0; i < NCOV; i++) cov[i] = 0;
    reset = 1'b1;
    drive();
    io_stin_valid = 0; io_vecstin_valid = 0; io_misalign_stin_valid = 0;
    repeat (5) @(negedge clock);
    reset = 1'b0;
    for (int c = 0; c < NCYCLES + WARMUP; c++) begin
      drive();
      #4;
      comparing = (c >= WARMUP);
      if (comparing) begin
        compare();
        collect_cov();
      end
      @(negedge clock);
    end
    for (int i = 0; i < NCOV; i++) begin
      $display("  cov %-22s = %0d (min %0d)%s", cov_names[i], cov[i], cov_min[i],
               (cov[i] < cov_min[i]) ? "  <-- LOW" : "");
      if (cov[i] < cov_min[i]) bad++;
    end
    $display("=== COVERAGE (StoreUnit) === checks=%0d uncovered=%0d", checks, bad);
    if (bad != 0) begin $display("COVERAGE INSUFFICIENT"); errors++; end
    $display("StoreUnit UT: checks=%0d errors=%0d", checks, errors);
    if (errors == 0) $display("TEST PASSED (checks=%0d)", checks);
    else             $display("TEST FAILED errors=%0d (checks=%0d)", errors, checks);
    $finish;
  end
endmodule
