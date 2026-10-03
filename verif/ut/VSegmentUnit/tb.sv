// =============================================================================
// VSegmentUnit UT —— golden VSegmentUnit 对重写 VSegmentUnit_xs 双例化（各带自己的 VSegmentTrigger /
// NewPipelineConnectPipe_33 子树），同激励逐拍比全部 108 根输出。
// 本文件由 scripts/gen_vsegmentunit.py 生成（端口连接 / 随机驱动 / 逐根比较是机械部分，
// 激励整形与覆盖判据是生成器里 TB_* 的手写部分）。勿手改。
//
// 激励要点：
//   · 入口：golden 空闲时以 1/4 概率起一条指令（1..6 条 uop 成串，串内指令级字段不变：fuType 一半
//     segment load（bit33）一半 segment store（bit34），mop 随机，nf 偏 0..2，vl 偏 1..8，vstart 偶尔非 0，
//     fof（0x90）1/8；最后一条 uop 带 lastUop）；每条 uop 的 vuopIdx 递增、源操作数随机；
//   · DTLB：应答 7/8，miss 1/8，Svpbmt 偏 0，各页异常位 1/256；PMP ld/st/mmio 各 1/256；
//   · DCache：req_ready 3/4，resp 7/8，miss 1/8，bank_conflict 1/16，tl_denied/corrupt 各 1/256；
//     data_delayed 随机；sbuffer_ready 3/4；flush_sbuffer_empty 3/4；cache_error_enable 7/8；
//   · 触发器：15/16 时间全关；其余 tdata2 取 golden 当前元素地址附近。
// 不复位寄存器：非常量 initreg 档两个实例各摇各的，先跑 +warmup 拍再开始比。
// 覆盖判据（读重写核内部信号，逐项有下限，不达标本轮不作数）：见 cov_names。
// =============================================================================
`timescale 1ns/1ps

module tb;

  int unsigned NCYCLES = 200000;
  int unsigned WARMUP  = 0;
  int      errors = 0;
  longint  checks = 0;

  logic clock = 0;
  logic reset;
  always #5 clock = ~clock;

  // ---- 输入（两侧共用）----
  logic          io_in_valid;
  logic [34:0]   io_in_bits_uop_fuType;
  logic [8:0]    io_in_bits_uop_fuOpType;
  logic          io_in_bits_uop_vecWen;
  logic          io_in_bits_uop_v0Wen;
  logic          io_in_bits_uop_vlWen;
  logic          io_in_bits_uop_vpu_vill;
  logic          io_in_bits_uop_vpu_vma;
  logic          io_in_bits_uop_vpu_vta;
  logic [1:0]    io_in_bits_uop_vpu_vsew;
  logic [2:0]    io_in_bits_uop_vpu_vlmul;
  logic          io_in_bits_uop_vpu_specVill;
  logic          io_in_bits_uop_vpu_specVma;
  logic          io_in_bits_uop_vpu_specVta;
  logic [1:0]    io_in_bits_uop_vpu_specVsew;
  logic [2:0]    io_in_bits_uop_vpu_specVlmul;
  logic          io_in_bits_uop_vpu_vm;
  logic [7:0]    io_in_bits_uop_vpu_vstart;
  logic [2:0]    io_in_bits_uop_vpu_frm;
  logic          io_in_bits_uop_vpu_fpu_isFpToVecInst;
  logic          io_in_bits_uop_vpu_fpu_isFP32Instr;
  logic          io_in_bits_uop_vpu_fpu_isFP64Instr;
  logic          io_in_bits_uop_vpu_fpu_isReduction;
  logic          io_in_bits_uop_vpu_fpu_isFoldTo1_2;
  logic          io_in_bits_uop_vpu_fpu_isFoldTo1_4;
  logic          io_in_bits_uop_vpu_fpu_isFoldTo1_8;
  logic [1:0]    io_in_bits_uop_vpu_vxrm;
  logic [6:0]    io_in_bits_uop_vpu_vuopIdx;
  logic          io_in_bits_uop_vpu_lastUop;
  logic [2:0]    io_in_bits_uop_vpu_nf;
  logic [1:0]    io_in_bits_uop_vpu_veew;
  logic          io_in_bits_uop_vpu_isReverse;
  logic          io_in_bits_uop_vpu_isExt;
  logic          io_in_bits_uop_vpu_isNarrow;
  logic          io_in_bits_uop_vpu_isDstMask;
  logic          io_in_bits_uop_vpu_isOpMask;
  logic          io_in_bits_uop_vpu_isMove;
  logic          io_in_bits_uop_vpu_isDependOldVd;
  logic          io_in_bits_uop_vpu_isWritePartVd;
  logic          io_in_bits_uop_vpu_isVleff;
  logic [7:0]    io_in_bits_uop_pdest;
  logic          io_in_bits_uop_robIdx_flag;
  logic [7:0]    io_in_bits_uop_robIdx_value;
  logic          io_in_bits_uop_debugInfo_eliminatedMove;
  logic [63:0]   io_in_bits_uop_debugInfo_renameTime;
  logic [63:0]   io_in_bits_uop_debugInfo_dispatchTime;
  logic [63:0]   io_in_bits_uop_debugInfo_enqRsTime;
  logic [63:0]   io_in_bits_uop_debugInfo_selectTime;
  logic [63:0]   io_in_bits_uop_debugInfo_issueTime;
  logic [63:0]   io_in_bits_uop_debugInfo_writebackTime;
  logic [63:0]   io_in_bits_uop_debugInfo_runahead_checkpoint_id;
  logic [63:0]   io_in_bits_uop_debugInfo_tlbFirstReqTime;
  logic [63:0]   io_in_bits_uop_debugInfo_tlbRespTime;
  logic [55:0]   io_in_bits_uop_debug_seqNum_seqNum;
  logic [7:0]    io_in_bits_uop_debug_seqNum_uopIdx;
  logic          io_in_bits_uop_lqIdx_flag;
  logic [6:0]    io_in_bits_uop_lqIdx_value;
  logic          io_in_bits_uop_sqIdx_flag;
  logic [5:0]    io_in_bits_uop_sqIdx_value;
  logic [127:0]  io_in_bits_src_0;
  logic [127:0]  io_in_bits_src_1;
  logic [127:0]  io_in_bits_src_2;
  logic [127:0]  io_in_bits_src_3;
  logic [127:0]  io_in_bits_src_4;
  logic          io_csrCtrl_cache_error_enable;
  logic          io_rdcache_req_ready;
  logic          io_rdcache_resp_valid;
  logic [127:0]  io_rdcache_resp_bits_data_delayed;
  logic          io_rdcache_resp_bits_miss;
  logic          io_rdcache_resp_bits_tl_error_delayed_tl_denied;
  logic          io_rdcache_resp_bits_tl_error_delayed_tl_corrupt;
  logic          io_rdcache_s2_bank_conflict;
  logic          io_sbuffer_ready;
  logic          io_dtlb_resp_valid;
  logic [47:0]   io_dtlb_resp_bits_paddr_0;
  logic [63:0]   io_dtlb_resp_bits_gpaddr_0;
  logic [63:0]   io_dtlb_resp_bits_fullva;
  logic [1:0]    io_dtlb_resp_bits_pbmt_0;
  logic          io_dtlb_resp_bits_miss;
  logic          io_dtlb_resp_bits_isForVSnonLeafPTE;
  logic          io_dtlb_resp_bits_excp_0_gpf_ld;
  logic          io_dtlb_resp_bits_excp_0_gpf_st;
  logic          io_dtlb_resp_bits_excp_0_pf_ld;
  logic          io_dtlb_resp_bits_excp_0_pf_st;
  logic          io_dtlb_resp_bits_excp_0_af_ld;
  logic          io_dtlb_resp_bits_excp_0_af_st;
  logic          io_pmpResp_ld;
  logic          io_pmpResp_st;
  logic          io_pmpResp_instr;
  logic          io_pmpResp_mmio;
  logic          io_pmpResp_atomic;
  logic          io_flush_sbuffer_empty;
  logic [1:0]    io_fromCsrTrigger_tdataVec_0_matchType;
  logic          io_fromCsrTrigger_tdataVec_0_select;
  logic          io_fromCsrTrigger_tdataVec_0_timing;
  logic [3:0]    io_fromCsrTrigger_tdataVec_0_action;
  logic          io_fromCsrTrigger_tdataVec_0_chain;
  logic          io_fromCsrTrigger_tdataVec_0_store;
  logic          io_fromCsrTrigger_tdataVec_0_load;
  logic [63:0]   io_fromCsrTrigger_tdataVec_0_tdata2;
  logic [1:0]    io_fromCsrTrigger_tdataVec_1_matchType;
  logic          io_fromCsrTrigger_tdataVec_1_select;
  logic          io_fromCsrTrigger_tdataVec_1_timing;
  logic [3:0]    io_fromCsrTrigger_tdataVec_1_action;
  logic          io_fromCsrTrigger_tdataVec_1_chain;
  logic          io_fromCsrTrigger_tdataVec_1_store;
  logic          io_fromCsrTrigger_tdataVec_1_load;
  logic [63:0]   io_fromCsrTrigger_tdataVec_1_tdata2;
  logic [1:0]    io_fromCsrTrigger_tdataVec_2_matchType;
  logic          io_fromCsrTrigger_tdataVec_2_select;
  logic          io_fromCsrTrigger_tdataVec_2_timing;
  logic [3:0]    io_fromCsrTrigger_tdataVec_2_action;
  logic          io_fromCsrTrigger_tdataVec_2_chain;
  logic          io_fromCsrTrigger_tdataVec_2_store;
  logic          io_fromCsrTrigger_tdataVec_2_load;
  logic [63:0]   io_fromCsrTrigger_tdataVec_2_tdata2;
  logic [1:0]    io_fromCsrTrigger_tdataVec_3_matchType;
  logic          io_fromCsrTrigger_tdataVec_3_select;
  logic          io_fromCsrTrigger_tdataVec_3_timing;
  logic [3:0]    io_fromCsrTrigger_tdataVec_3_action;
  logic          io_fromCsrTrigger_tdataVec_3_chain;
  logic          io_fromCsrTrigger_tdataVec_3_store;
  logic          io_fromCsrTrigger_tdataVec_3_load;
  logic [63:0]   io_fromCsrTrigger_tdataVec_3_tdata2;
  logic          io_fromCsrTrigger_tEnableVec_0;
  logic          io_fromCsrTrigger_tEnableVec_1;
  logic          io_fromCsrTrigger_tEnableVec_2;
  logic          io_fromCsrTrigger_tEnableVec_3;
  logic          io_fromCsrTrigger_debugMode;
  logic          io_fromCsrTrigger_triggerCanRaiseBpExp;
  // ---- 输出：g_ = golden，x_ = 重写 ----
  wire               g_io_uopwriteback_valid, x_io_uopwriteback_valid;
  wire               g_io_uopwriteback_bits_uop_exceptionVec_3, x_io_uopwriteback_bits_uop_exceptionVec_3;
  wire               g_io_uopwriteback_bits_uop_exceptionVec_5, x_io_uopwriteback_bits_uop_exceptionVec_5;
  wire               g_io_uopwriteback_bits_uop_exceptionVec_7, x_io_uopwriteback_bits_uop_exceptionVec_7;
  wire               g_io_uopwriteback_bits_uop_exceptionVec_13, x_io_uopwriteback_bits_uop_exceptionVec_13;
  wire               g_io_uopwriteback_bits_uop_exceptionVec_15, x_io_uopwriteback_bits_uop_exceptionVec_15;
  wire               g_io_uopwriteback_bits_uop_exceptionVec_19, x_io_uopwriteback_bits_uop_exceptionVec_19;
  wire               g_io_uopwriteback_bits_uop_exceptionVec_21, x_io_uopwriteback_bits_uop_exceptionVec_21;
  wire               g_io_uopwriteback_bits_uop_exceptionVec_23, x_io_uopwriteback_bits_uop_exceptionVec_23;
  wire [3:0]         g_io_uopwriteback_bits_uop_trigger, x_io_uopwriteback_bits_uop_trigger;
  wire [8:0]         g_io_uopwriteback_bits_uop_fuOpType, x_io_uopwriteback_bits_uop_fuOpType;
  wire               g_io_uopwriteback_bits_uop_vecWen, x_io_uopwriteback_bits_uop_vecWen;
  wire               g_io_uopwriteback_bits_uop_v0Wen, x_io_uopwriteback_bits_uop_v0Wen;
  wire               g_io_uopwriteback_bits_uop_vlWen, x_io_uopwriteback_bits_uop_vlWen;
  wire               g_io_uopwriteback_bits_uop_vpu_vill, x_io_uopwriteback_bits_uop_vpu_vill;
  wire               g_io_uopwriteback_bits_uop_vpu_vma, x_io_uopwriteback_bits_uop_vpu_vma;
  wire               g_io_uopwriteback_bits_uop_vpu_vta, x_io_uopwriteback_bits_uop_vpu_vta;
  wire [1:0]         g_io_uopwriteback_bits_uop_vpu_vsew, x_io_uopwriteback_bits_uop_vpu_vsew;
  wire [2:0]         g_io_uopwriteback_bits_uop_vpu_vlmul, x_io_uopwriteback_bits_uop_vpu_vlmul;
  wire               g_io_uopwriteback_bits_uop_vpu_specVill, x_io_uopwriteback_bits_uop_vpu_specVill;
  wire               g_io_uopwriteback_bits_uop_vpu_specVma, x_io_uopwriteback_bits_uop_vpu_specVma;
  wire               g_io_uopwriteback_bits_uop_vpu_specVta, x_io_uopwriteback_bits_uop_vpu_specVta;
  wire [1:0]         g_io_uopwriteback_bits_uop_vpu_specVsew, x_io_uopwriteback_bits_uop_vpu_specVsew;
  wire [2:0]         g_io_uopwriteback_bits_uop_vpu_specVlmul, x_io_uopwriteback_bits_uop_vpu_specVlmul;
  wire               g_io_uopwriteback_bits_uop_vpu_vm, x_io_uopwriteback_bits_uop_vpu_vm;
  wire [7:0]         g_io_uopwriteback_bits_uop_vpu_vstart, x_io_uopwriteback_bits_uop_vpu_vstart;
  wire [2:0]         g_io_uopwriteback_bits_uop_vpu_frm, x_io_uopwriteback_bits_uop_vpu_frm;
  wire               g_io_uopwriteback_bits_uop_vpu_fpu_isFpToVecInst, x_io_uopwriteback_bits_uop_vpu_fpu_isFpToVecInst;
  wire               g_io_uopwriteback_bits_uop_vpu_fpu_isFP32Instr, x_io_uopwriteback_bits_uop_vpu_fpu_isFP32Instr;
  wire               g_io_uopwriteback_bits_uop_vpu_fpu_isFP64Instr, x_io_uopwriteback_bits_uop_vpu_fpu_isFP64Instr;
  wire               g_io_uopwriteback_bits_uop_vpu_fpu_isReduction, x_io_uopwriteback_bits_uop_vpu_fpu_isReduction;
  wire               g_io_uopwriteback_bits_uop_vpu_fpu_isFoldTo1_2, x_io_uopwriteback_bits_uop_vpu_fpu_isFoldTo1_2;
  wire               g_io_uopwriteback_bits_uop_vpu_fpu_isFoldTo1_4, x_io_uopwriteback_bits_uop_vpu_fpu_isFoldTo1_4;
  wire               g_io_uopwriteback_bits_uop_vpu_fpu_isFoldTo1_8, x_io_uopwriteback_bits_uop_vpu_fpu_isFoldTo1_8;
  wire [1:0]         g_io_uopwriteback_bits_uop_vpu_vxrm, x_io_uopwriteback_bits_uop_vpu_vxrm;
  wire [6:0]         g_io_uopwriteback_bits_uop_vpu_vuopIdx, x_io_uopwriteback_bits_uop_vpu_vuopIdx;
  wire               g_io_uopwriteback_bits_uop_vpu_lastUop, x_io_uopwriteback_bits_uop_vpu_lastUop;
  wire [127:0]       g_io_uopwriteback_bits_uop_vpu_vmask, x_io_uopwriteback_bits_uop_vpu_vmask;
  wire [7:0]         g_io_uopwriteback_bits_uop_vpu_vl, x_io_uopwriteback_bits_uop_vpu_vl;
  wire [2:0]         g_io_uopwriteback_bits_uop_vpu_nf, x_io_uopwriteback_bits_uop_vpu_nf;
  wire [1:0]         g_io_uopwriteback_bits_uop_vpu_veew, x_io_uopwriteback_bits_uop_vpu_veew;
  wire               g_io_uopwriteback_bits_uop_vpu_isReverse, x_io_uopwriteback_bits_uop_vpu_isReverse;
  wire               g_io_uopwriteback_bits_uop_vpu_isExt, x_io_uopwriteback_bits_uop_vpu_isExt;
  wire               g_io_uopwriteback_bits_uop_vpu_isNarrow, x_io_uopwriteback_bits_uop_vpu_isNarrow;
  wire               g_io_uopwriteback_bits_uop_vpu_isDstMask, x_io_uopwriteback_bits_uop_vpu_isDstMask;
  wire               g_io_uopwriteback_bits_uop_vpu_isOpMask, x_io_uopwriteback_bits_uop_vpu_isOpMask;
  wire               g_io_uopwriteback_bits_uop_vpu_isMove, x_io_uopwriteback_bits_uop_vpu_isMove;
  wire               g_io_uopwriteback_bits_uop_vpu_isDependOldVd, x_io_uopwriteback_bits_uop_vpu_isDependOldVd;
  wire               g_io_uopwriteback_bits_uop_vpu_isWritePartVd, x_io_uopwriteback_bits_uop_vpu_isWritePartVd;
  wire               g_io_uopwriteback_bits_uop_vpu_isVleff, x_io_uopwriteback_bits_uop_vpu_isVleff;
  wire [7:0]         g_io_uopwriteback_bits_uop_pdest, x_io_uopwriteback_bits_uop_pdest;
  wire               g_io_uopwriteback_bits_uop_robIdx_flag, x_io_uopwriteback_bits_uop_robIdx_flag;
  wire [7:0]         g_io_uopwriteback_bits_uop_robIdx_value, x_io_uopwriteback_bits_uop_robIdx_value;
  wire               g_io_uopwriteback_bits_uop_debugInfo_eliminatedMove, x_io_uopwriteback_bits_uop_debugInfo_eliminatedMove;
  wire [63:0]        g_io_uopwriteback_bits_uop_debugInfo_renameTime, x_io_uopwriteback_bits_uop_debugInfo_renameTime;
  wire [63:0]        g_io_uopwriteback_bits_uop_debugInfo_dispatchTime, x_io_uopwriteback_bits_uop_debugInfo_dispatchTime;
  wire [63:0]        g_io_uopwriteback_bits_uop_debugInfo_enqRsTime, x_io_uopwriteback_bits_uop_debugInfo_enqRsTime;
  wire [63:0]        g_io_uopwriteback_bits_uop_debugInfo_selectTime, x_io_uopwriteback_bits_uop_debugInfo_selectTime;
  wire [63:0]        g_io_uopwriteback_bits_uop_debugInfo_issueTime, x_io_uopwriteback_bits_uop_debugInfo_issueTime;
  wire [63:0]        g_io_uopwriteback_bits_uop_debugInfo_writebackTime, x_io_uopwriteback_bits_uop_debugInfo_writebackTime;
  wire [63:0]        g_io_uopwriteback_bits_uop_debugInfo_runahead_checkpoint_id, x_io_uopwriteback_bits_uop_debugInfo_runahead_checkpoint_id;
  wire [63:0]        g_io_uopwriteback_bits_uop_debugInfo_tlbFirstReqTime, x_io_uopwriteback_bits_uop_debugInfo_tlbFirstReqTime;
  wire [63:0]        g_io_uopwriteback_bits_uop_debugInfo_tlbRespTime, x_io_uopwriteback_bits_uop_debugInfo_tlbRespTime;
  wire [55:0]        g_io_uopwriteback_bits_uop_debug_seqNum_seqNum, x_io_uopwriteback_bits_uop_debug_seqNum_seqNum;
  wire [7:0]         g_io_uopwriteback_bits_uop_debug_seqNum_uopIdx, x_io_uopwriteback_bits_uop_debug_seqNum_uopIdx;
  wire [127:0]       g_io_uopwriteback_bits_data, x_io_uopwriteback_bits_data;
  wire [2:0]         g_io_uopwriteback_bits_vdIdx, x_io_uopwriteback_bits_vdIdx;
  wire [2:0]         g_io_uopwriteback_bits_vdIdxInField, x_io_uopwriteback_bits_vdIdxInField;
  wire               g_io_uopwriteback_bits_debug_isMMIO, x_io_uopwriteback_bits_debug_isMMIO;
  wire               g_io_uopwriteback_bits_debug_isNCIO, x_io_uopwriteback_bits_debug_isNCIO;
  wire               g_io_uopwriteback_bits_debug_isPerfCnt, x_io_uopwriteback_bits_debug_isPerfCnt;
  wire [47:0]        g_io_uopwriteback_bits_debug_paddr, x_io_uopwriteback_bits_debug_paddr;
  wire [49:0]        g_io_uopwriteback_bits_debug_vaddr, x_io_uopwriteback_bits_debug_vaddr;
  wire               g_io_rdcache_req_valid, x_io_rdcache_req_valid;
  wire [49:0]        g_io_rdcache_req_bits_vaddr, x_io_rdcache_req_bits_vaddr;
  wire [49:0]        g_io_rdcache_req_bits_vaddr_dup, x_io_rdcache_req_bits_vaddr_dup;
  wire               g_io_rdcache_is128Req, x_io_rdcache_is128Req;
  wire [47:0]        g_io_rdcache_s1_paddr_dup_lsu, x_io_rdcache_s1_paddr_dup_lsu;
  wire [47:0]        g_io_rdcache_s1_paddr_dup_dcache, x_io_rdcache_s1_paddr_dup_dcache;
  wire               g_io_sbuffer_valid, x_io_sbuffer_valid;
  wire [49:0]        g_io_sbuffer_bits_vaddr, x_io_sbuffer_bits_vaddr;
  wire [127:0]       g_io_sbuffer_bits_data, x_io_sbuffer_bits_data;
  wire [15:0]        g_io_sbuffer_bits_mask, x_io_sbuffer_bits_mask;
  wire [47:0]        g_io_sbuffer_bits_addr, x_io_sbuffer_bits_addr;
  wire               g_io_sbuffer_bits_vecValid, x_io_sbuffer_bits_vecValid;
  wire [34:0]        g_io_vecDifftestInfo_bits_uop_fuType, x_io_vecDifftestInfo_bits_uop_fuType;
  wire [8:0]         g_io_vecDifftestInfo_bits_uop_fuOpType, x_io_vecDifftestInfo_bits_uop_fuOpType;
  wire [2:0]         g_io_vecDifftestInfo_bits_uop_vpu_nf, x_io_vecDifftestInfo_bits_uop_vpu_nf;
  wire [1:0]         g_io_vecDifftestInfo_bits_uop_vpu_veew, x_io_vecDifftestInfo_bits_uop_vpu_veew;
  wire [7:0]         g_io_vecDifftestInfo_bits_uop_robIdx_value, x_io_vecDifftestInfo_bits_uop_robIdx_value;
  wire               g_io_dtlb_req_valid, x_io_dtlb_req_valid;
  wire [49:0]        g_io_dtlb_req_bits_vaddr, x_io_dtlb_req_bits_vaddr;
  wire [63:0]        g_io_dtlb_req_bits_fullva, x_io_dtlb_req_bits_fullva;
  wire [2:0]         g_io_dtlb_req_bits_cmd, x_io_dtlb_req_bits_cmd;
  wire               g_io_dtlb_req_bits_debug_robIdx_flag, x_io_dtlb_req_bits_debug_robIdx_flag;
  wire [7:0]         g_io_dtlb_req_bits_debug_robIdx_value, x_io_dtlb_req_bits_debug_robIdx_value;
  wire               g_io_flush_sbuffer_valid, x_io_flush_sbuffer_valid;
  wire               g_io_feedback_valid, x_io_feedback_valid;
  wire               g_io_feedback_bits_robIdx_flag, x_io_feedback_bits_robIdx_flag;
  wire [7:0]         g_io_feedback_bits_robIdx_value, x_io_feedback_bits_robIdx_value;
  wire               g_io_feedback_bits_sqIdx_flag, x_io_feedback_bits_sqIdx_flag;
  wire [5:0]         g_io_feedback_bits_sqIdx_value, x_io_feedback_bits_sqIdx_value;
  wire               g_io_feedback_bits_lqIdx_flag, x_io_feedback_bits_lqIdx_flag;
  wire [6:0]         g_io_feedback_bits_lqIdx_value, x_io_feedback_bits_lqIdx_value;
  wire               g_io_exceptionInfo_valid, x_io_exceptionInfo_valid;
  wire [63:0]        g_io_exceptionInfo_bits_vaddr, x_io_exceptionInfo_bits_vaddr;
  wire [63:0]        g_io_exceptionInfo_bits_gpaddr, x_io_exceptionInfo_bits_gpaddr;
  wire               g_io_exceptionInfo_bits_isForVSnonLeafPTE, x_io_exceptionInfo_bits_isForVSnonLeafPTE;

  VSegmentUnit u_golden (
    .clock (clock),
    .reset (reset),
    .io_in_valid (io_in_valid),
    .io_in_bits_uop_fuType (io_in_bits_uop_fuType),
    .io_in_bits_uop_fuOpType (io_in_bits_uop_fuOpType),
    .io_in_bits_uop_vecWen (io_in_bits_uop_vecWen),
    .io_in_bits_uop_v0Wen (io_in_bits_uop_v0Wen),
    .io_in_bits_uop_vlWen (io_in_bits_uop_vlWen),
    .io_in_bits_uop_vpu_vill (io_in_bits_uop_vpu_vill),
    .io_in_bits_uop_vpu_vma (io_in_bits_uop_vpu_vma),
    .io_in_bits_uop_vpu_vta (io_in_bits_uop_vpu_vta),
    .io_in_bits_uop_vpu_vsew (io_in_bits_uop_vpu_vsew),
    .io_in_bits_uop_vpu_vlmul (io_in_bits_uop_vpu_vlmul),
    .io_in_bits_uop_vpu_specVill (io_in_bits_uop_vpu_specVill),
    .io_in_bits_uop_vpu_specVma (io_in_bits_uop_vpu_specVma),
    .io_in_bits_uop_vpu_specVta (io_in_bits_uop_vpu_specVta),
    .io_in_bits_uop_vpu_specVsew (io_in_bits_uop_vpu_specVsew),
    .io_in_bits_uop_vpu_specVlmul (io_in_bits_uop_vpu_specVlmul),
    .io_in_bits_uop_vpu_vm (io_in_bits_uop_vpu_vm),
    .io_in_bits_uop_vpu_vstart (io_in_bits_uop_vpu_vstart),
    .io_in_bits_uop_vpu_frm (io_in_bits_uop_vpu_frm),
    .io_in_bits_uop_vpu_fpu_isFpToVecInst (io_in_bits_uop_vpu_fpu_isFpToVecInst),
    .io_in_bits_uop_vpu_fpu_isFP32Instr (io_in_bits_uop_vpu_fpu_isFP32Instr),
    .io_in_bits_uop_vpu_fpu_isFP64Instr (io_in_bits_uop_vpu_fpu_isFP64Instr),
    .io_in_bits_uop_vpu_fpu_isReduction (io_in_bits_uop_vpu_fpu_isReduction),
    .io_in_bits_uop_vpu_fpu_isFoldTo1_2 (io_in_bits_uop_vpu_fpu_isFoldTo1_2),
    .io_in_bits_uop_vpu_fpu_isFoldTo1_4 (io_in_bits_uop_vpu_fpu_isFoldTo1_4),
    .io_in_bits_uop_vpu_fpu_isFoldTo1_8 (io_in_bits_uop_vpu_fpu_isFoldTo1_8),
    .io_in_bits_uop_vpu_vxrm (io_in_bits_uop_vpu_vxrm),
    .io_in_bits_uop_vpu_vuopIdx (io_in_bits_uop_vpu_vuopIdx),
    .io_in_bits_uop_vpu_lastUop (io_in_bits_uop_vpu_lastUop),
    .io_in_bits_uop_vpu_nf (io_in_bits_uop_vpu_nf),
    .io_in_bits_uop_vpu_veew (io_in_bits_uop_vpu_veew),
    .io_in_bits_uop_vpu_isReverse (io_in_bits_uop_vpu_isReverse),
    .io_in_bits_uop_vpu_isExt (io_in_bits_uop_vpu_isExt),
    .io_in_bits_uop_vpu_isNarrow (io_in_bits_uop_vpu_isNarrow),
    .io_in_bits_uop_vpu_isDstMask (io_in_bits_uop_vpu_isDstMask),
    .io_in_bits_uop_vpu_isOpMask (io_in_bits_uop_vpu_isOpMask),
    .io_in_bits_uop_vpu_isMove (io_in_bits_uop_vpu_isMove),
    .io_in_bits_uop_vpu_isDependOldVd (io_in_bits_uop_vpu_isDependOldVd),
    .io_in_bits_uop_vpu_isWritePartVd (io_in_bits_uop_vpu_isWritePartVd),
    .io_in_bits_uop_vpu_isVleff (io_in_bits_uop_vpu_isVleff),
    .io_in_bits_uop_pdest (io_in_bits_uop_pdest),
    .io_in_bits_uop_robIdx_flag (io_in_bits_uop_robIdx_flag),
    .io_in_bits_uop_robIdx_value (io_in_bits_uop_robIdx_value),
    .io_in_bits_uop_debugInfo_eliminatedMove (io_in_bits_uop_debugInfo_eliminatedMove),
    .io_in_bits_uop_debugInfo_renameTime (io_in_bits_uop_debugInfo_renameTime),
    .io_in_bits_uop_debugInfo_dispatchTime (io_in_bits_uop_debugInfo_dispatchTime),
    .io_in_bits_uop_debugInfo_enqRsTime (io_in_bits_uop_debugInfo_enqRsTime),
    .io_in_bits_uop_debugInfo_selectTime (io_in_bits_uop_debugInfo_selectTime),
    .io_in_bits_uop_debugInfo_issueTime (io_in_bits_uop_debugInfo_issueTime),
    .io_in_bits_uop_debugInfo_writebackTime (io_in_bits_uop_debugInfo_writebackTime),
    .io_in_bits_uop_debugInfo_runahead_checkpoint_id (io_in_bits_uop_debugInfo_runahead_checkpoint_id),
    .io_in_bits_uop_debugInfo_tlbFirstReqTime (io_in_bits_uop_debugInfo_tlbFirstReqTime),
    .io_in_bits_uop_debugInfo_tlbRespTime (io_in_bits_uop_debugInfo_tlbRespTime),
    .io_in_bits_uop_debug_seqNum_seqNum (io_in_bits_uop_debug_seqNum_seqNum),
    .io_in_bits_uop_debug_seqNum_uopIdx (io_in_bits_uop_debug_seqNum_uopIdx),
    .io_in_bits_uop_lqIdx_flag (io_in_bits_uop_lqIdx_flag),
    .io_in_bits_uop_lqIdx_value (io_in_bits_uop_lqIdx_value),
    .io_in_bits_uop_sqIdx_flag (io_in_bits_uop_sqIdx_flag),
    .io_in_bits_uop_sqIdx_value (io_in_bits_uop_sqIdx_value),
    .io_in_bits_src_0 (io_in_bits_src_0),
    .io_in_bits_src_1 (io_in_bits_src_1),
    .io_in_bits_src_2 (io_in_bits_src_2),
    .io_in_bits_src_3 (io_in_bits_src_3),
    .io_in_bits_src_4 (io_in_bits_src_4),
    .io_uopwriteback_valid (g_io_uopwriteback_valid),
    .io_uopwriteback_bits_uop_exceptionVec_3 (g_io_uopwriteback_bits_uop_exceptionVec_3),
    .io_uopwriteback_bits_uop_exceptionVec_5 (g_io_uopwriteback_bits_uop_exceptionVec_5),
    .io_uopwriteback_bits_uop_exceptionVec_7 (g_io_uopwriteback_bits_uop_exceptionVec_7),
    .io_uopwriteback_bits_uop_exceptionVec_13 (g_io_uopwriteback_bits_uop_exceptionVec_13),
    .io_uopwriteback_bits_uop_exceptionVec_15 (g_io_uopwriteback_bits_uop_exceptionVec_15),
    .io_uopwriteback_bits_uop_exceptionVec_19 (g_io_uopwriteback_bits_uop_exceptionVec_19),
    .io_uopwriteback_bits_uop_exceptionVec_21 (g_io_uopwriteback_bits_uop_exceptionVec_21),
    .io_uopwriteback_bits_uop_exceptionVec_23 (g_io_uopwriteback_bits_uop_exceptionVec_23),
    .io_uopwriteback_bits_uop_trigger (g_io_uopwriteback_bits_uop_trigger),
    .io_uopwriteback_bits_uop_fuOpType (g_io_uopwriteback_bits_uop_fuOpType),
    .io_uopwriteback_bits_uop_vecWen (g_io_uopwriteback_bits_uop_vecWen),
    .io_uopwriteback_bits_uop_v0Wen (g_io_uopwriteback_bits_uop_v0Wen),
    .io_uopwriteback_bits_uop_vlWen (g_io_uopwriteback_bits_uop_vlWen),
    .io_uopwriteback_bits_uop_vpu_vill (g_io_uopwriteback_bits_uop_vpu_vill),
    .io_uopwriteback_bits_uop_vpu_vma (g_io_uopwriteback_bits_uop_vpu_vma),
    .io_uopwriteback_bits_uop_vpu_vta (g_io_uopwriteback_bits_uop_vpu_vta),
    .io_uopwriteback_bits_uop_vpu_vsew (g_io_uopwriteback_bits_uop_vpu_vsew),
    .io_uopwriteback_bits_uop_vpu_vlmul (g_io_uopwriteback_bits_uop_vpu_vlmul),
    .io_uopwriteback_bits_uop_vpu_specVill (g_io_uopwriteback_bits_uop_vpu_specVill),
    .io_uopwriteback_bits_uop_vpu_specVma (g_io_uopwriteback_bits_uop_vpu_specVma),
    .io_uopwriteback_bits_uop_vpu_specVta (g_io_uopwriteback_bits_uop_vpu_specVta),
    .io_uopwriteback_bits_uop_vpu_specVsew (g_io_uopwriteback_bits_uop_vpu_specVsew),
    .io_uopwriteback_bits_uop_vpu_specVlmul (g_io_uopwriteback_bits_uop_vpu_specVlmul),
    .io_uopwriteback_bits_uop_vpu_vm (g_io_uopwriteback_bits_uop_vpu_vm),
    .io_uopwriteback_bits_uop_vpu_vstart (g_io_uopwriteback_bits_uop_vpu_vstart),
    .io_uopwriteback_bits_uop_vpu_frm (g_io_uopwriteback_bits_uop_vpu_frm),
    .io_uopwriteback_bits_uop_vpu_fpu_isFpToVecInst (g_io_uopwriteback_bits_uop_vpu_fpu_isFpToVecInst),
    .io_uopwriteback_bits_uop_vpu_fpu_isFP32Instr (g_io_uopwriteback_bits_uop_vpu_fpu_isFP32Instr),
    .io_uopwriteback_bits_uop_vpu_fpu_isFP64Instr (g_io_uopwriteback_bits_uop_vpu_fpu_isFP64Instr),
    .io_uopwriteback_bits_uop_vpu_fpu_isReduction (g_io_uopwriteback_bits_uop_vpu_fpu_isReduction),
    .io_uopwriteback_bits_uop_vpu_fpu_isFoldTo1_2 (g_io_uopwriteback_bits_uop_vpu_fpu_isFoldTo1_2),
    .io_uopwriteback_bits_uop_vpu_fpu_isFoldTo1_4 (g_io_uopwriteback_bits_uop_vpu_fpu_isFoldTo1_4),
    .io_uopwriteback_bits_uop_vpu_fpu_isFoldTo1_8 (g_io_uopwriteback_bits_uop_vpu_fpu_isFoldTo1_8),
    .io_uopwriteback_bits_uop_vpu_vxrm (g_io_uopwriteback_bits_uop_vpu_vxrm),
    .io_uopwriteback_bits_uop_vpu_vuopIdx (g_io_uopwriteback_bits_uop_vpu_vuopIdx),
    .io_uopwriteback_bits_uop_vpu_lastUop (g_io_uopwriteback_bits_uop_vpu_lastUop),
    .io_uopwriteback_bits_uop_vpu_vmask (g_io_uopwriteback_bits_uop_vpu_vmask),
    .io_uopwriteback_bits_uop_vpu_vl (g_io_uopwriteback_bits_uop_vpu_vl),
    .io_uopwriteback_bits_uop_vpu_nf (g_io_uopwriteback_bits_uop_vpu_nf),
    .io_uopwriteback_bits_uop_vpu_veew (g_io_uopwriteback_bits_uop_vpu_veew),
    .io_uopwriteback_bits_uop_vpu_isReverse (g_io_uopwriteback_bits_uop_vpu_isReverse),
    .io_uopwriteback_bits_uop_vpu_isExt (g_io_uopwriteback_bits_uop_vpu_isExt),
    .io_uopwriteback_bits_uop_vpu_isNarrow (g_io_uopwriteback_bits_uop_vpu_isNarrow),
    .io_uopwriteback_bits_uop_vpu_isDstMask (g_io_uopwriteback_bits_uop_vpu_isDstMask),
    .io_uopwriteback_bits_uop_vpu_isOpMask (g_io_uopwriteback_bits_uop_vpu_isOpMask),
    .io_uopwriteback_bits_uop_vpu_isMove (g_io_uopwriteback_bits_uop_vpu_isMove),
    .io_uopwriteback_bits_uop_vpu_isDependOldVd (g_io_uopwriteback_bits_uop_vpu_isDependOldVd),
    .io_uopwriteback_bits_uop_vpu_isWritePartVd (g_io_uopwriteback_bits_uop_vpu_isWritePartVd),
    .io_uopwriteback_bits_uop_vpu_isVleff (g_io_uopwriteback_bits_uop_vpu_isVleff),
    .io_uopwriteback_bits_uop_pdest (g_io_uopwriteback_bits_uop_pdest),
    .io_uopwriteback_bits_uop_robIdx_flag (g_io_uopwriteback_bits_uop_robIdx_flag),
    .io_uopwriteback_bits_uop_robIdx_value (g_io_uopwriteback_bits_uop_robIdx_value),
    .io_uopwriteback_bits_uop_debugInfo_eliminatedMove (g_io_uopwriteback_bits_uop_debugInfo_eliminatedMove),
    .io_uopwriteback_bits_uop_debugInfo_renameTime (g_io_uopwriteback_bits_uop_debugInfo_renameTime),
    .io_uopwriteback_bits_uop_debugInfo_dispatchTime (g_io_uopwriteback_bits_uop_debugInfo_dispatchTime),
    .io_uopwriteback_bits_uop_debugInfo_enqRsTime (g_io_uopwriteback_bits_uop_debugInfo_enqRsTime),
    .io_uopwriteback_bits_uop_debugInfo_selectTime (g_io_uopwriteback_bits_uop_debugInfo_selectTime),
    .io_uopwriteback_bits_uop_debugInfo_issueTime (g_io_uopwriteback_bits_uop_debugInfo_issueTime),
    .io_uopwriteback_bits_uop_debugInfo_writebackTime (g_io_uopwriteback_bits_uop_debugInfo_writebackTime),
    .io_uopwriteback_bits_uop_debugInfo_runahead_checkpoint_id (g_io_uopwriteback_bits_uop_debugInfo_runahead_checkpoint_id),
    .io_uopwriteback_bits_uop_debugInfo_tlbFirstReqTime (g_io_uopwriteback_bits_uop_debugInfo_tlbFirstReqTime),
    .io_uopwriteback_bits_uop_debugInfo_tlbRespTime (g_io_uopwriteback_bits_uop_debugInfo_tlbRespTime),
    .io_uopwriteback_bits_uop_debug_seqNum_seqNum (g_io_uopwriteback_bits_uop_debug_seqNum_seqNum),
    .io_uopwriteback_bits_uop_debug_seqNum_uopIdx (g_io_uopwriteback_bits_uop_debug_seqNum_uopIdx),
    .io_uopwriteback_bits_data (g_io_uopwriteback_bits_data),
    .io_uopwriteback_bits_vdIdx (g_io_uopwriteback_bits_vdIdx),
    .io_uopwriteback_bits_vdIdxInField (g_io_uopwriteback_bits_vdIdxInField),
    .io_uopwriteback_bits_debug_isMMIO (g_io_uopwriteback_bits_debug_isMMIO),
    .io_uopwriteback_bits_debug_isNCIO (g_io_uopwriteback_bits_debug_isNCIO),
    .io_uopwriteback_bits_debug_isPerfCnt (g_io_uopwriteback_bits_debug_isPerfCnt),
    .io_uopwriteback_bits_debug_paddr (g_io_uopwriteback_bits_debug_paddr),
    .io_uopwriteback_bits_debug_vaddr (g_io_uopwriteback_bits_debug_vaddr),
    .io_csrCtrl_cache_error_enable (io_csrCtrl_cache_error_enable),
    .io_rdcache_req_ready (io_rdcache_req_ready),
    .io_rdcache_req_valid (g_io_rdcache_req_valid),
    .io_rdcache_req_bits_vaddr (g_io_rdcache_req_bits_vaddr),
    .io_rdcache_req_bits_vaddr_dup (g_io_rdcache_req_bits_vaddr_dup),
    .io_rdcache_resp_valid (io_rdcache_resp_valid),
    .io_rdcache_resp_bits_data_delayed (io_rdcache_resp_bits_data_delayed),
    .io_rdcache_resp_bits_miss (io_rdcache_resp_bits_miss),
    .io_rdcache_resp_bits_tl_error_delayed_tl_denied (io_rdcache_resp_bits_tl_error_delayed_tl_denied),
    .io_rdcache_resp_bits_tl_error_delayed_tl_corrupt (io_rdcache_resp_bits_tl_error_delayed_tl_corrupt),
    .io_rdcache_is128Req (g_io_rdcache_is128Req),
    .io_rdcache_s1_paddr_dup_lsu (g_io_rdcache_s1_paddr_dup_lsu),
    .io_rdcache_s1_paddr_dup_dcache (g_io_rdcache_s1_paddr_dup_dcache),
    .io_rdcache_s2_bank_conflict (io_rdcache_s2_bank_conflict),
    .io_sbuffer_ready (io_sbuffer_ready),
    .io_sbuffer_valid (g_io_sbuffer_valid),
    .io_sbuffer_bits_vaddr (g_io_sbuffer_bits_vaddr),
    .io_sbuffer_bits_data (g_io_sbuffer_bits_data),
    .io_sbuffer_bits_mask (g_io_sbuffer_bits_mask),
    .io_sbuffer_bits_addr (g_io_sbuffer_bits_addr),
    .io_sbuffer_bits_vecValid (g_io_sbuffer_bits_vecValid),
    .io_vecDifftestInfo_bits_uop_fuType (g_io_vecDifftestInfo_bits_uop_fuType),
    .io_vecDifftestInfo_bits_uop_fuOpType (g_io_vecDifftestInfo_bits_uop_fuOpType),
    .io_vecDifftestInfo_bits_uop_vpu_nf (g_io_vecDifftestInfo_bits_uop_vpu_nf),
    .io_vecDifftestInfo_bits_uop_vpu_veew (g_io_vecDifftestInfo_bits_uop_vpu_veew),
    .io_vecDifftestInfo_bits_uop_robIdx_value (g_io_vecDifftestInfo_bits_uop_robIdx_value),
    .io_dtlb_req_valid (g_io_dtlb_req_valid),
    .io_dtlb_req_bits_vaddr (g_io_dtlb_req_bits_vaddr),
    .io_dtlb_req_bits_fullva (g_io_dtlb_req_bits_fullva),
    .io_dtlb_req_bits_cmd (g_io_dtlb_req_bits_cmd),
    .io_dtlb_req_bits_debug_robIdx_flag (g_io_dtlb_req_bits_debug_robIdx_flag),
    .io_dtlb_req_bits_debug_robIdx_value (g_io_dtlb_req_bits_debug_robIdx_value),
    .io_dtlb_resp_valid (io_dtlb_resp_valid),
    .io_dtlb_resp_bits_paddr_0 (io_dtlb_resp_bits_paddr_0),
    .io_dtlb_resp_bits_gpaddr_0 (io_dtlb_resp_bits_gpaddr_0),
    .io_dtlb_resp_bits_fullva (io_dtlb_resp_bits_fullva),
    .io_dtlb_resp_bits_pbmt_0 (io_dtlb_resp_bits_pbmt_0),
    .io_dtlb_resp_bits_miss (io_dtlb_resp_bits_miss),
    .io_dtlb_resp_bits_isForVSnonLeafPTE (io_dtlb_resp_bits_isForVSnonLeafPTE),
    .io_dtlb_resp_bits_excp_0_gpf_ld (io_dtlb_resp_bits_excp_0_gpf_ld),
    .io_dtlb_resp_bits_excp_0_gpf_st (io_dtlb_resp_bits_excp_0_gpf_st),
    .io_dtlb_resp_bits_excp_0_pf_ld (io_dtlb_resp_bits_excp_0_pf_ld),
    .io_dtlb_resp_bits_excp_0_pf_st (io_dtlb_resp_bits_excp_0_pf_st),
    .io_dtlb_resp_bits_excp_0_af_ld (io_dtlb_resp_bits_excp_0_af_ld),
    .io_dtlb_resp_bits_excp_0_af_st (io_dtlb_resp_bits_excp_0_af_st),
    .io_pmpResp_ld (io_pmpResp_ld),
    .io_pmpResp_st (io_pmpResp_st),
    .io_pmpResp_instr (io_pmpResp_instr),
    .io_pmpResp_mmio (io_pmpResp_mmio),
    .io_pmpResp_atomic (io_pmpResp_atomic),
    .io_flush_sbuffer_valid (g_io_flush_sbuffer_valid),
    .io_flush_sbuffer_empty (io_flush_sbuffer_empty),
    .io_feedback_valid (g_io_feedback_valid),
    .io_feedback_bits_robIdx_flag (g_io_feedback_bits_robIdx_flag),
    .io_feedback_bits_robIdx_value (g_io_feedback_bits_robIdx_value),
    .io_feedback_bits_sqIdx_flag (g_io_feedback_bits_sqIdx_flag),
    .io_feedback_bits_sqIdx_value (g_io_feedback_bits_sqIdx_value),
    .io_feedback_bits_lqIdx_flag (g_io_feedback_bits_lqIdx_flag),
    .io_feedback_bits_lqIdx_value (g_io_feedback_bits_lqIdx_value),
    .io_exceptionInfo_valid (g_io_exceptionInfo_valid),
    .io_exceptionInfo_bits_vaddr (g_io_exceptionInfo_bits_vaddr),
    .io_exceptionInfo_bits_gpaddr (g_io_exceptionInfo_bits_gpaddr),
    .io_exceptionInfo_bits_isForVSnonLeafPTE (g_io_exceptionInfo_bits_isForVSnonLeafPTE),
    .io_fromCsrTrigger_tdataVec_0_matchType (io_fromCsrTrigger_tdataVec_0_matchType),
    .io_fromCsrTrigger_tdataVec_0_select (io_fromCsrTrigger_tdataVec_0_select),
    .io_fromCsrTrigger_tdataVec_0_timing (io_fromCsrTrigger_tdataVec_0_timing),
    .io_fromCsrTrigger_tdataVec_0_action (io_fromCsrTrigger_tdataVec_0_action),
    .io_fromCsrTrigger_tdataVec_0_chain (io_fromCsrTrigger_tdataVec_0_chain),
    .io_fromCsrTrigger_tdataVec_0_store (io_fromCsrTrigger_tdataVec_0_store),
    .io_fromCsrTrigger_tdataVec_0_load (io_fromCsrTrigger_tdataVec_0_load),
    .io_fromCsrTrigger_tdataVec_0_tdata2 (io_fromCsrTrigger_tdataVec_0_tdata2),
    .io_fromCsrTrigger_tdataVec_1_matchType (io_fromCsrTrigger_tdataVec_1_matchType),
    .io_fromCsrTrigger_tdataVec_1_select (io_fromCsrTrigger_tdataVec_1_select),
    .io_fromCsrTrigger_tdataVec_1_timing (io_fromCsrTrigger_tdataVec_1_timing),
    .io_fromCsrTrigger_tdataVec_1_action (io_fromCsrTrigger_tdataVec_1_action),
    .io_fromCsrTrigger_tdataVec_1_chain (io_fromCsrTrigger_tdataVec_1_chain),
    .io_fromCsrTrigger_tdataVec_1_store (io_fromCsrTrigger_tdataVec_1_store),
    .io_fromCsrTrigger_tdataVec_1_load (io_fromCsrTrigger_tdataVec_1_load),
    .io_fromCsrTrigger_tdataVec_1_tdata2 (io_fromCsrTrigger_tdataVec_1_tdata2),
    .io_fromCsrTrigger_tdataVec_2_matchType (io_fromCsrTrigger_tdataVec_2_matchType),
    .io_fromCsrTrigger_tdataVec_2_select (io_fromCsrTrigger_tdataVec_2_select),
    .io_fromCsrTrigger_tdataVec_2_timing (io_fromCsrTrigger_tdataVec_2_timing),
    .io_fromCsrTrigger_tdataVec_2_action (io_fromCsrTrigger_tdataVec_2_action),
    .io_fromCsrTrigger_tdataVec_2_chain (io_fromCsrTrigger_tdataVec_2_chain),
    .io_fromCsrTrigger_tdataVec_2_store (io_fromCsrTrigger_tdataVec_2_store),
    .io_fromCsrTrigger_tdataVec_2_load (io_fromCsrTrigger_tdataVec_2_load),
    .io_fromCsrTrigger_tdataVec_2_tdata2 (io_fromCsrTrigger_tdataVec_2_tdata2),
    .io_fromCsrTrigger_tdataVec_3_matchType (io_fromCsrTrigger_tdataVec_3_matchType),
    .io_fromCsrTrigger_tdataVec_3_select (io_fromCsrTrigger_tdataVec_3_select),
    .io_fromCsrTrigger_tdataVec_3_timing (io_fromCsrTrigger_tdataVec_3_timing),
    .io_fromCsrTrigger_tdataVec_3_action (io_fromCsrTrigger_tdataVec_3_action),
    .io_fromCsrTrigger_tdataVec_3_chain (io_fromCsrTrigger_tdataVec_3_chain),
    .io_fromCsrTrigger_tdataVec_3_store (io_fromCsrTrigger_tdataVec_3_store),
    .io_fromCsrTrigger_tdataVec_3_load (io_fromCsrTrigger_tdataVec_3_load),
    .io_fromCsrTrigger_tdataVec_3_tdata2 (io_fromCsrTrigger_tdataVec_3_tdata2),
    .io_fromCsrTrigger_tEnableVec_0 (io_fromCsrTrigger_tEnableVec_0),
    .io_fromCsrTrigger_tEnableVec_1 (io_fromCsrTrigger_tEnableVec_1),
    .io_fromCsrTrigger_tEnableVec_2 (io_fromCsrTrigger_tEnableVec_2),
    .io_fromCsrTrigger_tEnableVec_3 (io_fromCsrTrigger_tEnableVec_3),
    .io_fromCsrTrigger_debugMode (io_fromCsrTrigger_debugMode),
    .io_fromCsrTrigger_triggerCanRaiseBpExp (io_fromCsrTrigger_triggerCanRaiseBpExp)
  );

  VSegmentUnit_xs u_impl (
    .clock (clock),
    .reset (reset),
    .io_in_valid (io_in_valid),
    .io_in_bits_uop_fuType (io_in_bits_uop_fuType),
    .io_in_bits_uop_fuOpType (io_in_bits_uop_fuOpType),
    .io_in_bits_uop_vecWen (io_in_bits_uop_vecWen),
    .io_in_bits_uop_v0Wen (io_in_bits_uop_v0Wen),
    .io_in_bits_uop_vlWen (io_in_bits_uop_vlWen),
    .io_in_bits_uop_vpu_vill (io_in_bits_uop_vpu_vill),
    .io_in_bits_uop_vpu_vma (io_in_bits_uop_vpu_vma),
    .io_in_bits_uop_vpu_vta (io_in_bits_uop_vpu_vta),
    .io_in_bits_uop_vpu_vsew (io_in_bits_uop_vpu_vsew),
    .io_in_bits_uop_vpu_vlmul (io_in_bits_uop_vpu_vlmul),
    .io_in_bits_uop_vpu_specVill (io_in_bits_uop_vpu_specVill),
    .io_in_bits_uop_vpu_specVma (io_in_bits_uop_vpu_specVma),
    .io_in_bits_uop_vpu_specVta (io_in_bits_uop_vpu_specVta),
    .io_in_bits_uop_vpu_specVsew (io_in_bits_uop_vpu_specVsew),
    .io_in_bits_uop_vpu_specVlmul (io_in_bits_uop_vpu_specVlmul),
    .io_in_bits_uop_vpu_vm (io_in_bits_uop_vpu_vm),
    .io_in_bits_uop_vpu_vstart (io_in_bits_uop_vpu_vstart),
    .io_in_bits_uop_vpu_frm (io_in_bits_uop_vpu_frm),
    .io_in_bits_uop_vpu_fpu_isFpToVecInst (io_in_bits_uop_vpu_fpu_isFpToVecInst),
    .io_in_bits_uop_vpu_fpu_isFP32Instr (io_in_bits_uop_vpu_fpu_isFP32Instr),
    .io_in_bits_uop_vpu_fpu_isFP64Instr (io_in_bits_uop_vpu_fpu_isFP64Instr),
    .io_in_bits_uop_vpu_fpu_isReduction (io_in_bits_uop_vpu_fpu_isReduction),
    .io_in_bits_uop_vpu_fpu_isFoldTo1_2 (io_in_bits_uop_vpu_fpu_isFoldTo1_2),
    .io_in_bits_uop_vpu_fpu_isFoldTo1_4 (io_in_bits_uop_vpu_fpu_isFoldTo1_4),
    .io_in_bits_uop_vpu_fpu_isFoldTo1_8 (io_in_bits_uop_vpu_fpu_isFoldTo1_8),
    .io_in_bits_uop_vpu_vxrm (io_in_bits_uop_vpu_vxrm),
    .io_in_bits_uop_vpu_vuopIdx (io_in_bits_uop_vpu_vuopIdx),
    .io_in_bits_uop_vpu_lastUop (io_in_bits_uop_vpu_lastUop),
    .io_in_bits_uop_vpu_nf (io_in_bits_uop_vpu_nf),
    .io_in_bits_uop_vpu_veew (io_in_bits_uop_vpu_veew),
    .io_in_bits_uop_vpu_isReverse (io_in_bits_uop_vpu_isReverse),
    .io_in_bits_uop_vpu_isExt (io_in_bits_uop_vpu_isExt),
    .io_in_bits_uop_vpu_isNarrow (io_in_bits_uop_vpu_isNarrow),
    .io_in_bits_uop_vpu_isDstMask (io_in_bits_uop_vpu_isDstMask),
    .io_in_bits_uop_vpu_isOpMask (io_in_bits_uop_vpu_isOpMask),
    .io_in_bits_uop_vpu_isMove (io_in_bits_uop_vpu_isMove),
    .io_in_bits_uop_vpu_isDependOldVd (io_in_bits_uop_vpu_isDependOldVd),
    .io_in_bits_uop_vpu_isWritePartVd (io_in_bits_uop_vpu_isWritePartVd),
    .io_in_bits_uop_vpu_isVleff (io_in_bits_uop_vpu_isVleff),
    .io_in_bits_uop_pdest (io_in_bits_uop_pdest),
    .io_in_bits_uop_robIdx_flag (io_in_bits_uop_robIdx_flag),
    .io_in_bits_uop_robIdx_value (io_in_bits_uop_robIdx_value),
    .io_in_bits_uop_debugInfo_eliminatedMove (io_in_bits_uop_debugInfo_eliminatedMove),
    .io_in_bits_uop_debugInfo_renameTime (io_in_bits_uop_debugInfo_renameTime),
    .io_in_bits_uop_debugInfo_dispatchTime (io_in_bits_uop_debugInfo_dispatchTime),
    .io_in_bits_uop_debugInfo_enqRsTime (io_in_bits_uop_debugInfo_enqRsTime),
    .io_in_bits_uop_debugInfo_selectTime (io_in_bits_uop_debugInfo_selectTime),
    .io_in_bits_uop_debugInfo_issueTime (io_in_bits_uop_debugInfo_issueTime),
    .io_in_bits_uop_debugInfo_writebackTime (io_in_bits_uop_debugInfo_writebackTime),
    .io_in_bits_uop_debugInfo_runahead_checkpoint_id (io_in_bits_uop_debugInfo_runahead_checkpoint_id),
    .io_in_bits_uop_debugInfo_tlbFirstReqTime (io_in_bits_uop_debugInfo_tlbFirstReqTime),
    .io_in_bits_uop_debugInfo_tlbRespTime (io_in_bits_uop_debugInfo_tlbRespTime),
    .io_in_bits_uop_debug_seqNum_seqNum (io_in_bits_uop_debug_seqNum_seqNum),
    .io_in_bits_uop_debug_seqNum_uopIdx (io_in_bits_uop_debug_seqNum_uopIdx),
    .io_in_bits_uop_lqIdx_flag (io_in_bits_uop_lqIdx_flag),
    .io_in_bits_uop_lqIdx_value (io_in_bits_uop_lqIdx_value),
    .io_in_bits_uop_sqIdx_flag (io_in_bits_uop_sqIdx_flag),
    .io_in_bits_uop_sqIdx_value (io_in_bits_uop_sqIdx_value),
    .io_in_bits_src_0 (io_in_bits_src_0),
    .io_in_bits_src_1 (io_in_bits_src_1),
    .io_in_bits_src_2 (io_in_bits_src_2),
    .io_in_bits_src_3 (io_in_bits_src_3),
    .io_in_bits_src_4 (io_in_bits_src_4),
    .io_uopwriteback_valid (x_io_uopwriteback_valid),
    .io_uopwriteback_bits_uop_exceptionVec_3 (x_io_uopwriteback_bits_uop_exceptionVec_3),
    .io_uopwriteback_bits_uop_exceptionVec_5 (x_io_uopwriteback_bits_uop_exceptionVec_5),
    .io_uopwriteback_bits_uop_exceptionVec_7 (x_io_uopwriteback_bits_uop_exceptionVec_7),
    .io_uopwriteback_bits_uop_exceptionVec_13 (x_io_uopwriteback_bits_uop_exceptionVec_13),
    .io_uopwriteback_bits_uop_exceptionVec_15 (x_io_uopwriteback_bits_uop_exceptionVec_15),
    .io_uopwriteback_bits_uop_exceptionVec_19 (x_io_uopwriteback_bits_uop_exceptionVec_19),
    .io_uopwriteback_bits_uop_exceptionVec_21 (x_io_uopwriteback_bits_uop_exceptionVec_21),
    .io_uopwriteback_bits_uop_exceptionVec_23 (x_io_uopwriteback_bits_uop_exceptionVec_23),
    .io_uopwriteback_bits_uop_trigger (x_io_uopwriteback_bits_uop_trigger),
    .io_uopwriteback_bits_uop_fuOpType (x_io_uopwriteback_bits_uop_fuOpType),
    .io_uopwriteback_bits_uop_vecWen (x_io_uopwriteback_bits_uop_vecWen),
    .io_uopwriteback_bits_uop_v0Wen (x_io_uopwriteback_bits_uop_v0Wen),
    .io_uopwriteback_bits_uop_vlWen (x_io_uopwriteback_bits_uop_vlWen),
    .io_uopwriteback_bits_uop_vpu_vill (x_io_uopwriteback_bits_uop_vpu_vill),
    .io_uopwriteback_bits_uop_vpu_vma (x_io_uopwriteback_bits_uop_vpu_vma),
    .io_uopwriteback_bits_uop_vpu_vta (x_io_uopwriteback_bits_uop_vpu_vta),
    .io_uopwriteback_bits_uop_vpu_vsew (x_io_uopwriteback_bits_uop_vpu_vsew),
    .io_uopwriteback_bits_uop_vpu_vlmul (x_io_uopwriteback_bits_uop_vpu_vlmul),
    .io_uopwriteback_bits_uop_vpu_specVill (x_io_uopwriteback_bits_uop_vpu_specVill),
    .io_uopwriteback_bits_uop_vpu_specVma (x_io_uopwriteback_bits_uop_vpu_specVma),
    .io_uopwriteback_bits_uop_vpu_specVta (x_io_uopwriteback_bits_uop_vpu_specVta),
    .io_uopwriteback_bits_uop_vpu_specVsew (x_io_uopwriteback_bits_uop_vpu_specVsew),
    .io_uopwriteback_bits_uop_vpu_specVlmul (x_io_uopwriteback_bits_uop_vpu_specVlmul),
    .io_uopwriteback_bits_uop_vpu_vm (x_io_uopwriteback_bits_uop_vpu_vm),
    .io_uopwriteback_bits_uop_vpu_vstart (x_io_uopwriteback_bits_uop_vpu_vstart),
    .io_uopwriteback_bits_uop_vpu_frm (x_io_uopwriteback_bits_uop_vpu_frm),
    .io_uopwriteback_bits_uop_vpu_fpu_isFpToVecInst (x_io_uopwriteback_bits_uop_vpu_fpu_isFpToVecInst),
    .io_uopwriteback_bits_uop_vpu_fpu_isFP32Instr (x_io_uopwriteback_bits_uop_vpu_fpu_isFP32Instr),
    .io_uopwriteback_bits_uop_vpu_fpu_isFP64Instr (x_io_uopwriteback_bits_uop_vpu_fpu_isFP64Instr),
    .io_uopwriteback_bits_uop_vpu_fpu_isReduction (x_io_uopwriteback_bits_uop_vpu_fpu_isReduction),
    .io_uopwriteback_bits_uop_vpu_fpu_isFoldTo1_2 (x_io_uopwriteback_bits_uop_vpu_fpu_isFoldTo1_2),
    .io_uopwriteback_bits_uop_vpu_fpu_isFoldTo1_4 (x_io_uopwriteback_bits_uop_vpu_fpu_isFoldTo1_4),
    .io_uopwriteback_bits_uop_vpu_fpu_isFoldTo1_8 (x_io_uopwriteback_bits_uop_vpu_fpu_isFoldTo1_8),
    .io_uopwriteback_bits_uop_vpu_vxrm (x_io_uopwriteback_bits_uop_vpu_vxrm),
    .io_uopwriteback_bits_uop_vpu_vuopIdx (x_io_uopwriteback_bits_uop_vpu_vuopIdx),
    .io_uopwriteback_bits_uop_vpu_lastUop (x_io_uopwriteback_bits_uop_vpu_lastUop),
    .io_uopwriteback_bits_uop_vpu_vmask (x_io_uopwriteback_bits_uop_vpu_vmask),
    .io_uopwriteback_bits_uop_vpu_vl (x_io_uopwriteback_bits_uop_vpu_vl),
    .io_uopwriteback_bits_uop_vpu_nf (x_io_uopwriteback_bits_uop_vpu_nf),
    .io_uopwriteback_bits_uop_vpu_veew (x_io_uopwriteback_bits_uop_vpu_veew),
    .io_uopwriteback_bits_uop_vpu_isReverse (x_io_uopwriteback_bits_uop_vpu_isReverse),
    .io_uopwriteback_bits_uop_vpu_isExt (x_io_uopwriteback_bits_uop_vpu_isExt),
    .io_uopwriteback_bits_uop_vpu_isNarrow (x_io_uopwriteback_bits_uop_vpu_isNarrow),
    .io_uopwriteback_bits_uop_vpu_isDstMask (x_io_uopwriteback_bits_uop_vpu_isDstMask),
    .io_uopwriteback_bits_uop_vpu_isOpMask (x_io_uopwriteback_bits_uop_vpu_isOpMask),
    .io_uopwriteback_bits_uop_vpu_isMove (x_io_uopwriteback_bits_uop_vpu_isMove),
    .io_uopwriteback_bits_uop_vpu_isDependOldVd (x_io_uopwriteback_bits_uop_vpu_isDependOldVd),
    .io_uopwriteback_bits_uop_vpu_isWritePartVd (x_io_uopwriteback_bits_uop_vpu_isWritePartVd),
    .io_uopwriteback_bits_uop_vpu_isVleff (x_io_uopwriteback_bits_uop_vpu_isVleff),
    .io_uopwriteback_bits_uop_pdest (x_io_uopwriteback_bits_uop_pdest),
    .io_uopwriteback_bits_uop_robIdx_flag (x_io_uopwriteback_bits_uop_robIdx_flag),
    .io_uopwriteback_bits_uop_robIdx_value (x_io_uopwriteback_bits_uop_robIdx_value),
    .io_uopwriteback_bits_uop_debugInfo_eliminatedMove (x_io_uopwriteback_bits_uop_debugInfo_eliminatedMove),
    .io_uopwriteback_bits_uop_debugInfo_renameTime (x_io_uopwriteback_bits_uop_debugInfo_renameTime),
    .io_uopwriteback_bits_uop_debugInfo_dispatchTime (x_io_uopwriteback_bits_uop_debugInfo_dispatchTime),
    .io_uopwriteback_bits_uop_debugInfo_enqRsTime (x_io_uopwriteback_bits_uop_debugInfo_enqRsTime),
    .io_uopwriteback_bits_uop_debugInfo_selectTime (x_io_uopwriteback_bits_uop_debugInfo_selectTime),
    .io_uopwriteback_bits_uop_debugInfo_issueTime (x_io_uopwriteback_bits_uop_debugInfo_issueTime),
    .io_uopwriteback_bits_uop_debugInfo_writebackTime (x_io_uopwriteback_bits_uop_debugInfo_writebackTime),
    .io_uopwriteback_bits_uop_debugInfo_runahead_checkpoint_id (x_io_uopwriteback_bits_uop_debugInfo_runahead_checkpoint_id),
    .io_uopwriteback_bits_uop_debugInfo_tlbFirstReqTime (x_io_uopwriteback_bits_uop_debugInfo_tlbFirstReqTime),
    .io_uopwriteback_bits_uop_debugInfo_tlbRespTime (x_io_uopwriteback_bits_uop_debugInfo_tlbRespTime),
    .io_uopwriteback_bits_uop_debug_seqNum_seqNum (x_io_uopwriteback_bits_uop_debug_seqNum_seqNum),
    .io_uopwriteback_bits_uop_debug_seqNum_uopIdx (x_io_uopwriteback_bits_uop_debug_seqNum_uopIdx),
    .io_uopwriteback_bits_data (x_io_uopwriteback_bits_data),
    .io_uopwriteback_bits_vdIdx (x_io_uopwriteback_bits_vdIdx),
    .io_uopwriteback_bits_vdIdxInField (x_io_uopwriteback_bits_vdIdxInField),
    .io_uopwriteback_bits_debug_isMMIO (x_io_uopwriteback_bits_debug_isMMIO),
    .io_uopwriteback_bits_debug_isNCIO (x_io_uopwriteback_bits_debug_isNCIO),
    .io_uopwriteback_bits_debug_isPerfCnt (x_io_uopwriteback_bits_debug_isPerfCnt),
    .io_uopwriteback_bits_debug_paddr (x_io_uopwriteback_bits_debug_paddr),
    .io_uopwriteback_bits_debug_vaddr (x_io_uopwriteback_bits_debug_vaddr),
    .io_csrCtrl_cache_error_enable (io_csrCtrl_cache_error_enable),
    .io_rdcache_req_ready (io_rdcache_req_ready),
    .io_rdcache_req_valid (x_io_rdcache_req_valid),
    .io_rdcache_req_bits_vaddr (x_io_rdcache_req_bits_vaddr),
    .io_rdcache_req_bits_vaddr_dup (x_io_rdcache_req_bits_vaddr_dup),
    .io_rdcache_resp_valid (io_rdcache_resp_valid),
    .io_rdcache_resp_bits_data_delayed (io_rdcache_resp_bits_data_delayed),
    .io_rdcache_resp_bits_miss (io_rdcache_resp_bits_miss),
    .io_rdcache_resp_bits_tl_error_delayed_tl_denied (io_rdcache_resp_bits_tl_error_delayed_tl_denied),
    .io_rdcache_resp_bits_tl_error_delayed_tl_corrupt (io_rdcache_resp_bits_tl_error_delayed_tl_corrupt),
    .io_rdcache_is128Req (x_io_rdcache_is128Req),
    .io_rdcache_s1_paddr_dup_lsu (x_io_rdcache_s1_paddr_dup_lsu),
    .io_rdcache_s1_paddr_dup_dcache (x_io_rdcache_s1_paddr_dup_dcache),
    .io_rdcache_s2_bank_conflict (io_rdcache_s2_bank_conflict),
    .io_sbuffer_ready (io_sbuffer_ready),
    .io_sbuffer_valid (x_io_sbuffer_valid),
    .io_sbuffer_bits_vaddr (x_io_sbuffer_bits_vaddr),
    .io_sbuffer_bits_data (x_io_sbuffer_bits_data),
    .io_sbuffer_bits_mask (x_io_sbuffer_bits_mask),
    .io_sbuffer_bits_addr (x_io_sbuffer_bits_addr),
    .io_sbuffer_bits_vecValid (x_io_sbuffer_bits_vecValid),
    .io_vecDifftestInfo_bits_uop_fuType (x_io_vecDifftestInfo_bits_uop_fuType),
    .io_vecDifftestInfo_bits_uop_fuOpType (x_io_vecDifftestInfo_bits_uop_fuOpType),
    .io_vecDifftestInfo_bits_uop_vpu_nf (x_io_vecDifftestInfo_bits_uop_vpu_nf),
    .io_vecDifftestInfo_bits_uop_vpu_veew (x_io_vecDifftestInfo_bits_uop_vpu_veew),
    .io_vecDifftestInfo_bits_uop_robIdx_value (x_io_vecDifftestInfo_bits_uop_robIdx_value),
    .io_dtlb_req_valid (x_io_dtlb_req_valid),
    .io_dtlb_req_bits_vaddr (x_io_dtlb_req_bits_vaddr),
    .io_dtlb_req_bits_fullva (x_io_dtlb_req_bits_fullva),
    .io_dtlb_req_bits_cmd (x_io_dtlb_req_bits_cmd),
    .io_dtlb_req_bits_debug_robIdx_flag (x_io_dtlb_req_bits_debug_robIdx_flag),
    .io_dtlb_req_bits_debug_robIdx_value (x_io_dtlb_req_bits_debug_robIdx_value),
    .io_dtlb_resp_valid (io_dtlb_resp_valid),
    .io_dtlb_resp_bits_paddr_0 (io_dtlb_resp_bits_paddr_0),
    .io_dtlb_resp_bits_gpaddr_0 (io_dtlb_resp_bits_gpaddr_0),
    .io_dtlb_resp_bits_fullva (io_dtlb_resp_bits_fullva),
    .io_dtlb_resp_bits_pbmt_0 (io_dtlb_resp_bits_pbmt_0),
    .io_dtlb_resp_bits_miss (io_dtlb_resp_bits_miss),
    .io_dtlb_resp_bits_isForVSnonLeafPTE (io_dtlb_resp_bits_isForVSnonLeafPTE),
    .io_dtlb_resp_bits_excp_0_gpf_ld (io_dtlb_resp_bits_excp_0_gpf_ld),
    .io_dtlb_resp_bits_excp_0_gpf_st (io_dtlb_resp_bits_excp_0_gpf_st),
    .io_dtlb_resp_bits_excp_0_pf_ld (io_dtlb_resp_bits_excp_0_pf_ld),
    .io_dtlb_resp_bits_excp_0_pf_st (io_dtlb_resp_bits_excp_0_pf_st),
    .io_dtlb_resp_bits_excp_0_af_ld (io_dtlb_resp_bits_excp_0_af_ld),
    .io_dtlb_resp_bits_excp_0_af_st (io_dtlb_resp_bits_excp_0_af_st),
    .io_pmpResp_ld (io_pmpResp_ld),
    .io_pmpResp_st (io_pmpResp_st),
    .io_pmpResp_instr (io_pmpResp_instr),
    .io_pmpResp_mmio (io_pmpResp_mmio),
    .io_pmpResp_atomic (io_pmpResp_atomic),
    .io_flush_sbuffer_valid (x_io_flush_sbuffer_valid),
    .io_flush_sbuffer_empty (io_flush_sbuffer_empty),
    .io_feedback_valid (x_io_feedback_valid),
    .io_feedback_bits_robIdx_flag (x_io_feedback_bits_robIdx_flag),
    .io_feedback_bits_robIdx_value (x_io_feedback_bits_robIdx_value),
    .io_feedback_bits_sqIdx_flag (x_io_feedback_bits_sqIdx_flag),
    .io_feedback_bits_sqIdx_value (x_io_feedback_bits_sqIdx_value),
    .io_feedback_bits_lqIdx_flag (x_io_feedback_bits_lqIdx_flag),
    .io_feedback_bits_lqIdx_value (x_io_feedback_bits_lqIdx_value),
    .io_exceptionInfo_valid (x_io_exceptionInfo_valid),
    .io_exceptionInfo_bits_vaddr (x_io_exceptionInfo_bits_vaddr),
    .io_exceptionInfo_bits_gpaddr (x_io_exceptionInfo_bits_gpaddr),
    .io_exceptionInfo_bits_isForVSnonLeafPTE (x_io_exceptionInfo_bits_isForVSnonLeafPTE),
    .io_fromCsrTrigger_tdataVec_0_matchType (io_fromCsrTrigger_tdataVec_0_matchType),
    .io_fromCsrTrigger_tdataVec_0_select (io_fromCsrTrigger_tdataVec_0_select),
    .io_fromCsrTrigger_tdataVec_0_timing (io_fromCsrTrigger_tdataVec_0_timing),
    .io_fromCsrTrigger_tdataVec_0_action (io_fromCsrTrigger_tdataVec_0_action),
    .io_fromCsrTrigger_tdataVec_0_chain (io_fromCsrTrigger_tdataVec_0_chain),
    .io_fromCsrTrigger_tdataVec_0_store (io_fromCsrTrigger_tdataVec_0_store),
    .io_fromCsrTrigger_tdataVec_0_load (io_fromCsrTrigger_tdataVec_0_load),
    .io_fromCsrTrigger_tdataVec_0_tdata2 (io_fromCsrTrigger_tdataVec_0_tdata2),
    .io_fromCsrTrigger_tdataVec_1_matchType (io_fromCsrTrigger_tdataVec_1_matchType),
    .io_fromCsrTrigger_tdataVec_1_select (io_fromCsrTrigger_tdataVec_1_select),
    .io_fromCsrTrigger_tdataVec_1_timing (io_fromCsrTrigger_tdataVec_1_timing),
    .io_fromCsrTrigger_tdataVec_1_action (io_fromCsrTrigger_tdataVec_1_action),
    .io_fromCsrTrigger_tdataVec_1_chain (io_fromCsrTrigger_tdataVec_1_chain),
    .io_fromCsrTrigger_tdataVec_1_store (io_fromCsrTrigger_tdataVec_1_store),
    .io_fromCsrTrigger_tdataVec_1_load (io_fromCsrTrigger_tdataVec_1_load),
    .io_fromCsrTrigger_tdataVec_1_tdata2 (io_fromCsrTrigger_tdataVec_1_tdata2),
    .io_fromCsrTrigger_tdataVec_2_matchType (io_fromCsrTrigger_tdataVec_2_matchType),
    .io_fromCsrTrigger_tdataVec_2_select (io_fromCsrTrigger_tdataVec_2_select),
    .io_fromCsrTrigger_tdataVec_2_timing (io_fromCsrTrigger_tdataVec_2_timing),
    .io_fromCsrTrigger_tdataVec_2_action (io_fromCsrTrigger_tdataVec_2_action),
    .io_fromCsrTrigger_tdataVec_2_chain (io_fromCsrTrigger_tdataVec_2_chain),
    .io_fromCsrTrigger_tdataVec_2_store (io_fromCsrTrigger_tdataVec_2_store),
    .io_fromCsrTrigger_tdataVec_2_load (io_fromCsrTrigger_tdataVec_2_load),
    .io_fromCsrTrigger_tdataVec_2_tdata2 (io_fromCsrTrigger_tdataVec_2_tdata2),
    .io_fromCsrTrigger_tdataVec_3_matchType (io_fromCsrTrigger_tdataVec_3_matchType),
    .io_fromCsrTrigger_tdataVec_3_select (io_fromCsrTrigger_tdataVec_3_select),
    .io_fromCsrTrigger_tdataVec_3_timing (io_fromCsrTrigger_tdataVec_3_timing),
    .io_fromCsrTrigger_tdataVec_3_action (io_fromCsrTrigger_tdataVec_3_action),
    .io_fromCsrTrigger_tdataVec_3_chain (io_fromCsrTrigger_tdataVec_3_chain),
    .io_fromCsrTrigger_tdataVec_3_store (io_fromCsrTrigger_tdataVec_3_store),
    .io_fromCsrTrigger_tdataVec_3_load (io_fromCsrTrigger_tdataVec_3_load),
    .io_fromCsrTrigger_tdataVec_3_tdata2 (io_fromCsrTrigger_tdataVec_3_tdata2),
    .io_fromCsrTrigger_tEnableVec_0 (io_fromCsrTrigger_tEnableVec_0),
    .io_fromCsrTrigger_tEnableVec_1 (io_fromCsrTrigger_tEnableVec_1),
    .io_fromCsrTrigger_tEnableVec_2 (io_fromCsrTrigger_tEnableVec_2),
    .io_fromCsrTrigger_tEnableVec_3 (io_fromCsrTrigger_tEnableVec_3),
    .io_fromCsrTrigger_debugMode (io_fromCsrTrigger_debugMode),
    .io_fromCsrTrigger_triggerCanRaiseBpExp (io_fromCsrTrigger_triggerCanRaiseBpExp)
  );

  // ---- 所有输入整体随机（整形在 drive 里）----
  task automatic drive_random();
    io_in_valid = 1'($urandom);
    io_in_bits_uop_fuType = 35'({$urandom, $urandom});
    io_in_bits_uop_fuOpType = 9'($urandom);
    io_in_bits_uop_vecWen = 1'($urandom);
    io_in_bits_uop_v0Wen = 1'($urandom);
    io_in_bits_uop_vlWen = 1'($urandom);
    io_in_bits_uop_vpu_vill = 1'($urandom);
    io_in_bits_uop_vpu_vma = 1'($urandom);
    io_in_bits_uop_vpu_vta = 1'($urandom);
    io_in_bits_uop_vpu_vsew = 2'($urandom);
    io_in_bits_uop_vpu_vlmul = 3'($urandom);
    io_in_bits_uop_vpu_specVill = 1'($urandom);
    io_in_bits_uop_vpu_specVma = 1'($urandom);
    io_in_bits_uop_vpu_specVta = 1'($urandom);
    io_in_bits_uop_vpu_specVsew = 2'($urandom);
    io_in_bits_uop_vpu_specVlmul = 3'($urandom);
    io_in_bits_uop_vpu_vm = 1'($urandom);
    io_in_bits_uop_vpu_vstart = 8'($urandom);
    io_in_bits_uop_vpu_frm = 3'($urandom);
    io_in_bits_uop_vpu_fpu_isFpToVecInst = 1'($urandom);
    io_in_bits_uop_vpu_fpu_isFP32Instr = 1'($urandom);
    io_in_bits_uop_vpu_fpu_isFP64Instr = 1'($urandom);
    io_in_bits_uop_vpu_fpu_isReduction = 1'($urandom);
    io_in_bits_uop_vpu_fpu_isFoldTo1_2 = 1'($urandom);
    io_in_bits_uop_vpu_fpu_isFoldTo1_4 = 1'($urandom);
    io_in_bits_uop_vpu_fpu_isFoldTo1_8 = 1'($urandom);
    io_in_bits_uop_vpu_vxrm = 2'($urandom);
    io_in_bits_uop_vpu_vuopIdx = 7'($urandom);
    io_in_bits_uop_vpu_lastUop = 1'($urandom);
    io_in_bits_uop_vpu_nf = 3'($urandom);
    io_in_bits_uop_vpu_veew = 2'($urandom);
    io_in_bits_uop_vpu_isReverse = 1'($urandom);
    io_in_bits_uop_vpu_isExt = 1'($urandom);
    io_in_bits_uop_vpu_isNarrow = 1'($urandom);
    io_in_bits_uop_vpu_isDstMask = 1'($urandom);
    io_in_bits_uop_vpu_isOpMask = 1'($urandom);
    io_in_bits_uop_vpu_isMove = 1'($urandom);
    io_in_bits_uop_vpu_isDependOldVd = 1'($urandom);
    io_in_bits_uop_vpu_isWritePartVd = 1'($urandom);
    io_in_bits_uop_vpu_isVleff = 1'($urandom);
    io_in_bits_uop_pdest = 8'($urandom);
    io_in_bits_uop_robIdx_flag = 1'($urandom);
    io_in_bits_uop_robIdx_value = 8'($urandom);
    io_in_bits_uop_debugInfo_eliminatedMove = 1'($urandom);
    io_in_bits_uop_debugInfo_renameTime = 64'({$urandom, $urandom});
    io_in_bits_uop_debugInfo_dispatchTime = 64'({$urandom, $urandom});
    io_in_bits_uop_debugInfo_enqRsTime = 64'({$urandom, $urandom});
    io_in_bits_uop_debugInfo_selectTime = 64'({$urandom, $urandom});
    io_in_bits_uop_debugInfo_issueTime = 64'({$urandom, $urandom});
    io_in_bits_uop_debugInfo_writebackTime = 64'({$urandom, $urandom});
    io_in_bits_uop_debugInfo_runahead_checkpoint_id = 64'({$urandom, $urandom});
    io_in_bits_uop_debugInfo_tlbFirstReqTime = 64'({$urandom, $urandom});
    io_in_bits_uop_debugInfo_tlbRespTime = 64'({$urandom, $urandom});
    io_in_bits_uop_debug_seqNum_seqNum = 56'({$urandom, $urandom});
    io_in_bits_uop_debug_seqNum_uopIdx = 8'($urandom);
    io_in_bits_uop_lqIdx_flag = 1'($urandom);
    io_in_bits_uop_lqIdx_value = 7'($urandom);
    io_in_bits_uop_sqIdx_flag = 1'($urandom);
    io_in_bits_uop_sqIdx_value = 6'($urandom);
    io_in_bits_src_0 = 128'({$urandom, $urandom, $urandom, $urandom});
    io_in_bits_src_1 = 128'({$urandom, $urandom, $urandom, $urandom});
    io_in_bits_src_2 = 128'({$urandom, $urandom, $urandom, $urandom});
    io_in_bits_src_3 = 128'({$urandom, $urandom, $urandom, $urandom});
    io_in_bits_src_4 = 128'({$urandom, $urandom, $urandom, $urandom});
    io_csrCtrl_cache_error_enable = 1'($urandom);
    io_rdcache_req_ready = 1'($urandom);
    io_rdcache_resp_valid = 1'($urandom);
    io_rdcache_resp_bits_data_delayed = 128'({$urandom, $urandom, $urandom, $urandom});
    io_rdcache_resp_bits_miss = 1'($urandom);
    io_rdcache_resp_bits_tl_error_delayed_tl_denied = 1'($urandom);
    io_rdcache_resp_bits_tl_error_delayed_tl_corrupt = 1'($urandom);
    io_rdcache_s2_bank_conflict = 1'($urandom);
    io_sbuffer_ready = 1'($urandom);
    io_dtlb_resp_valid = 1'($urandom);
    io_dtlb_resp_bits_paddr_0 = 48'({$urandom, $urandom});
    io_dtlb_resp_bits_gpaddr_0 = 64'({$urandom, $urandom});
    io_dtlb_resp_bits_fullva = 64'({$urandom, $urandom});
    io_dtlb_resp_bits_pbmt_0 = 2'($urandom);
    io_dtlb_resp_bits_miss = 1'($urandom);
    io_dtlb_resp_bits_isForVSnonLeafPTE = 1'($urandom);
    io_dtlb_resp_bits_excp_0_gpf_ld = 1'($urandom);
    io_dtlb_resp_bits_excp_0_gpf_st = 1'($urandom);
    io_dtlb_resp_bits_excp_0_pf_ld = 1'($urandom);
    io_dtlb_resp_bits_excp_0_pf_st = 1'($urandom);
    io_dtlb_resp_bits_excp_0_af_ld = 1'($urandom);
    io_dtlb_resp_bits_excp_0_af_st = 1'($urandom);
    io_pmpResp_ld = 1'($urandom);
    io_pmpResp_st = 1'($urandom);
    io_pmpResp_instr = 1'($urandom);
    io_pmpResp_mmio = 1'($urandom);
    io_pmpResp_atomic = 1'($urandom);
    io_flush_sbuffer_empty = 1'($urandom);
    io_fromCsrTrigger_tdataVec_0_matchType = 2'($urandom);
    io_fromCsrTrigger_tdataVec_0_select = 1'($urandom);
    io_fromCsrTrigger_tdataVec_0_timing = 1'($urandom);
    io_fromCsrTrigger_tdataVec_0_action = 4'($urandom);
    io_fromCsrTrigger_tdataVec_0_chain = 1'($urandom);
    io_fromCsrTrigger_tdataVec_0_store = 1'($urandom);
    io_fromCsrTrigger_tdataVec_0_load = 1'($urandom);
    io_fromCsrTrigger_tdataVec_0_tdata2 = 64'({$urandom, $urandom});
    io_fromCsrTrigger_tdataVec_1_matchType = 2'($urandom);
    io_fromCsrTrigger_tdataVec_1_select = 1'($urandom);
    io_fromCsrTrigger_tdataVec_1_timing = 1'($urandom);
    io_fromCsrTrigger_tdataVec_1_action = 4'($urandom);
    io_fromCsrTrigger_tdataVec_1_chain = 1'($urandom);
    io_fromCsrTrigger_tdataVec_1_store = 1'($urandom);
    io_fromCsrTrigger_tdataVec_1_load = 1'($urandom);
    io_fromCsrTrigger_tdataVec_1_tdata2 = 64'({$urandom, $urandom});
    io_fromCsrTrigger_tdataVec_2_matchType = 2'($urandom);
    io_fromCsrTrigger_tdataVec_2_select = 1'($urandom);
    io_fromCsrTrigger_tdataVec_2_timing = 1'($urandom);
    io_fromCsrTrigger_tdataVec_2_action = 4'($urandom);
    io_fromCsrTrigger_tdataVec_2_chain = 1'($urandom);
    io_fromCsrTrigger_tdataVec_2_store = 1'($urandom);
    io_fromCsrTrigger_tdataVec_2_load = 1'($urandom);
    io_fromCsrTrigger_tdataVec_2_tdata2 = 64'({$urandom, $urandom});
    io_fromCsrTrigger_tdataVec_3_matchType = 2'($urandom);
    io_fromCsrTrigger_tdataVec_3_select = 1'($urandom);
    io_fromCsrTrigger_tdataVec_3_timing = 1'($urandom);
    io_fromCsrTrigger_tdataVec_3_action = 4'($urandom);
    io_fromCsrTrigger_tdataVec_3_chain = 1'($urandom);
    io_fromCsrTrigger_tdataVec_3_store = 1'($urandom);
    io_fromCsrTrigger_tdataVec_3_load = 1'($urandom);
    io_fromCsrTrigger_tdataVec_3_tdata2 = 64'({$urandom, $urandom});
    io_fromCsrTrigger_tEnableVec_0 = 1'($urandom);
    io_fromCsrTrigger_tEnableVec_1 = 1'($urandom);
    io_fromCsrTrigger_tEnableVec_2 = 1'($urandom);
    io_fromCsrTrigger_tEnableVec_3 = 1'($urandom);
    io_fromCsrTrigger_debugMode = 1'($urandom);
    io_fromCsrTrigger_triggerCanRaiseBpExp = 1'($urandom);
  endtask

  // ---- 逐根比较 ----
`define CMP(SIG) \
    if (g_``SIG !== x_``SIG) begin \
      errors++; \
      if (errors < 30) $display("MISMATCH @%0d %s g=%h x=%h", checks, `"SIG`", g_``SIG, x_``SIG); \
    end
  task automatic compare();
    checks++;
    `CMP(io_uopwriteback_valid)
    `CMP(io_uopwriteback_bits_uop_exceptionVec_3)
    `CMP(io_uopwriteback_bits_uop_exceptionVec_5)
    `CMP(io_uopwriteback_bits_uop_exceptionVec_7)
    `CMP(io_uopwriteback_bits_uop_exceptionVec_13)
    `CMP(io_uopwriteback_bits_uop_exceptionVec_15)
    `CMP(io_uopwriteback_bits_uop_exceptionVec_19)
    `CMP(io_uopwriteback_bits_uop_exceptionVec_21)
    `CMP(io_uopwriteback_bits_uop_exceptionVec_23)
    `CMP(io_uopwriteback_bits_uop_trigger)
    `CMP(io_uopwriteback_bits_uop_fuOpType)
    `CMP(io_uopwriteback_bits_uop_vecWen)
    `CMP(io_uopwriteback_bits_uop_v0Wen)
    `CMP(io_uopwriteback_bits_uop_vlWen)
    `CMP(io_uopwriteback_bits_uop_vpu_vill)
    `CMP(io_uopwriteback_bits_uop_vpu_vma)
    `CMP(io_uopwriteback_bits_uop_vpu_vta)
    `CMP(io_uopwriteback_bits_uop_vpu_vsew)
    `CMP(io_uopwriteback_bits_uop_vpu_vlmul)
    `CMP(io_uopwriteback_bits_uop_vpu_specVill)
    `CMP(io_uopwriteback_bits_uop_vpu_specVma)
    `CMP(io_uopwriteback_bits_uop_vpu_specVta)
    `CMP(io_uopwriteback_bits_uop_vpu_specVsew)
    `CMP(io_uopwriteback_bits_uop_vpu_specVlmul)
    `CMP(io_uopwriteback_bits_uop_vpu_vm)
    `CMP(io_uopwriteback_bits_uop_vpu_vstart)
    `CMP(io_uopwriteback_bits_uop_vpu_frm)
    `CMP(io_uopwriteback_bits_uop_vpu_fpu_isFpToVecInst)
    `CMP(io_uopwriteback_bits_uop_vpu_fpu_isFP32Instr)
    `CMP(io_uopwriteback_bits_uop_vpu_fpu_isFP64Instr)
    `CMP(io_uopwriteback_bits_uop_vpu_fpu_isReduction)
    `CMP(io_uopwriteback_bits_uop_vpu_fpu_isFoldTo1_2)
    `CMP(io_uopwriteback_bits_uop_vpu_fpu_isFoldTo1_4)
    `CMP(io_uopwriteback_bits_uop_vpu_fpu_isFoldTo1_8)
    `CMP(io_uopwriteback_bits_uop_vpu_vxrm)
    `CMP(io_uopwriteback_bits_uop_vpu_vuopIdx)
    `CMP(io_uopwriteback_bits_uop_vpu_lastUop)
    `CMP(io_uopwriteback_bits_uop_vpu_vmask)
    `CMP(io_uopwriteback_bits_uop_vpu_vl)
    `CMP(io_uopwriteback_bits_uop_vpu_nf)
    `CMP(io_uopwriteback_bits_uop_vpu_veew)
    `CMP(io_uopwriteback_bits_uop_vpu_isReverse)
    `CMP(io_uopwriteback_bits_uop_vpu_isExt)
    `CMP(io_uopwriteback_bits_uop_vpu_isNarrow)
    `CMP(io_uopwriteback_bits_uop_vpu_isDstMask)
    `CMP(io_uopwriteback_bits_uop_vpu_isOpMask)
    `CMP(io_uopwriteback_bits_uop_vpu_isMove)
    `CMP(io_uopwriteback_bits_uop_vpu_isDependOldVd)
    `CMP(io_uopwriteback_bits_uop_vpu_isWritePartVd)
    `CMP(io_uopwriteback_bits_uop_vpu_isVleff)
    `CMP(io_uopwriteback_bits_uop_pdest)
    `CMP(io_uopwriteback_bits_uop_robIdx_flag)
    `CMP(io_uopwriteback_bits_uop_robIdx_value)
    `CMP(io_uopwriteback_bits_uop_debugInfo_eliminatedMove)
    `CMP(io_uopwriteback_bits_uop_debugInfo_renameTime)
    `CMP(io_uopwriteback_bits_uop_debugInfo_dispatchTime)
    `CMP(io_uopwriteback_bits_uop_debugInfo_enqRsTime)
    `CMP(io_uopwriteback_bits_uop_debugInfo_selectTime)
    `CMP(io_uopwriteback_bits_uop_debugInfo_issueTime)
    `CMP(io_uopwriteback_bits_uop_debugInfo_writebackTime)
    `CMP(io_uopwriteback_bits_uop_debugInfo_runahead_checkpoint_id)
    `CMP(io_uopwriteback_bits_uop_debugInfo_tlbFirstReqTime)
    `CMP(io_uopwriteback_bits_uop_debugInfo_tlbRespTime)
    `CMP(io_uopwriteback_bits_uop_debug_seqNum_seqNum)
    `CMP(io_uopwriteback_bits_uop_debug_seqNum_uopIdx)
    `CMP(io_uopwriteback_bits_data)
    `CMP(io_uopwriteback_bits_vdIdx)
    `CMP(io_uopwriteback_bits_vdIdxInField)
    `CMP(io_uopwriteback_bits_debug_isMMIO)
    `CMP(io_uopwriteback_bits_debug_isNCIO)
    `CMP(io_uopwriteback_bits_debug_isPerfCnt)
    `CMP(io_uopwriteback_bits_debug_paddr)
    `CMP(io_uopwriteback_bits_debug_vaddr)
    `CMP(io_rdcache_req_valid)
    `CMP(io_rdcache_req_bits_vaddr)
    `CMP(io_rdcache_req_bits_vaddr_dup)
    `CMP(io_rdcache_is128Req)
    `CMP(io_rdcache_s1_paddr_dup_lsu)
    `CMP(io_rdcache_s1_paddr_dup_dcache)
    `CMP(io_sbuffer_valid)
    `CMP(io_sbuffer_bits_vaddr)
    `CMP(io_sbuffer_bits_data)
    `CMP(io_sbuffer_bits_mask)
    `CMP(io_sbuffer_bits_addr)
    `CMP(io_sbuffer_bits_vecValid)
    `CMP(io_vecDifftestInfo_bits_uop_fuType)
    `CMP(io_vecDifftestInfo_bits_uop_fuOpType)
    `CMP(io_vecDifftestInfo_bits_uop_vpu_nf)
    `CMP(io_vecDifftestInfo_bits_uop_vpu_veew)
    `CMP(io_vecDifftestInfo_bits_uop_robIdx_value)
    `CMP(io_dtlb_req_valid)
    `CMP(io_dtlb_req_bits_vaddr)
    `CMP(io_dtlb_req_bits_fullva)
    `CMP(io_dtlb_req_bits_cmd)
    `CMP(io_dtlb_req_bits_debug_robIdx_flag)
    `CMP(io_dtlb_req_bits_debug_robIdx_value)
    `CMP(io_flush_sbuffer_valid)
    `CMP(io_feedback_valid)
    `CMP(io_feedback_bits_robIdx_flag)
    `CMP(io_feedback_bits_robIdx_value)
    `CMP(io_feedback_bits_sqIdx_flag)
    `CMP(io_feedback_bits_sqIdx_value)
    `CMP(io_feedback_bits_lqIdx_flag)
    `CMP(io_feedback_bits_lqIdx_value)
    `CMP(io_exceptionInfo_valid)
    `CMP(io_exceptionInfo_bits_vaddr)
    `CMP(io_exceptionInfo_bits_gpaddr)
    `CMP(io_exceptionInfo_bits_isForVSnonLeafPTE)
  endtask

  function automatic logic [63:0] near(logic [63:0] va);
    logic [63:0] t;
    case ($urandom_range(0, 5))
      0: t = {14'h0, va[49:0]};
      1: t = {14'h0, va[49:0]} + $urandom_range(1, 40);
      2: t = {14'h0, va[49:0]} - $urandom_range(1, 40);
      3: t = {14'h0, va[49:4], 4'($urandom)};
      4: t = {14'h0, va[49:6], 6'($urandom)};
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
    io_fromCsrTrigger_tdataVec_``I``_load      = ($urandom_range(0, 9) != 0); \
    io_fromCsrTrigger_tdataVec_``I``_action    = ($urandom_range(0, 7) == 0) ? 4'($urandom) : 4'($urandom_range(0, 1)); \
    io_fromCsrTrigger_tdataVec_``I``_tdata2    = $urandom_range(0, 1) ? near(target) : {$urandom, $urandom}; \
    io_fromCsrTrigger_tEnableVec_``I``         = trig_on & ($urandom_range(0, 9) != 0);

  // 一条指令 = 一串 uop：指令级字段（robIdx / fuType / fuOpType / vtype / nf / vl / vstart / mask）在
  // 串内保持不变（后端不会在上一条指令写回前发下一条）；每条 uop 只变 vuopIdx / lastUop / 源操作数。
  logic        inst_robIdx_flag;
  logic [7:0]  inst_robIdx_value;
  logic [34:0] inst_fuType;
  logic [8:0]  inst_fuOpType;
  logic [2:0]  inst_nf, inst_vlmul;
  logic [1:0]  inst_vsew, inst_veew;
  logic        inst_vm;
  logic [7:0]  inst_vl, inst_vstart;
  logic [127:0] inst_mask;
  int          burst_left = 0, burst_idx = 0;

  task automatic new_inst();
    inst_robIdx_flag  = $urandom;
    inst_robIdx_value = $urandom;
    inst_fuType = '0;
    if ($urandom_range(0, 1)) inst_fuType[33] = 1'b1; else inst_fuType[34] = 1'b1;
    if ($urandom_range(0, 31) == 0) inst_fuType = 35'($urandom);
    inst_fuOpType = ($urandom_range(0, 7) == 0) ? 9'h090 : {2'($urandom), 2'($urandom), 5'($urandom_range(0, 1))};
    inst_nf     = ($urandom_range(0, 3) != 0) ? 3'($urandom_range(0, 2)) : 3'($urandom);
    inst_vlmul  = ($urandom_range(0, 7) != 0) ? 3'($urandom_range(5, 11)) : 3'($urandom);
    inst_vsew   = 2'($urandom);
    inst_veew   = 2'($urandom);
    inst_vm     = ($urandom_range(0, 2) == 0);
    inst_vl     = ($urandom_range(0, 15) == 0) ? 8'($urandom_range(0, 255)) : 8'($urandom_range(1, 8));
    inst_vstart = ($urandom_range(0, 7) == 0) ? 8'($urandom_range(0, 6)) : 8'h0;
    inst_mask   = ($urandom_range(0, 3) == 0) ? '1 : {$urandom, $urandom, $urandom, $urandom};
  endtask

  task automatic drive();
    logic [63:0] target;
    logic        trig_on;
    drive_random();
    // ---- 入口 uop ----
    if (burst_left == 0 && u_golden.state == 4'd0 && $urandom_range(0, 3) == 0) begin
      burst_left = $urandom_range(1, 6);
      burst_idx  = 0;
      new_inst();
    end
    io_in_valid = 1'b0;
    if (burst_left > 0 && $urandom_range(0, 3) != 0) begin
      io_in_valid = 1'b1;
      burst_left--;
    end
    io_in_bits_uop_robIdx_flag  = inst_robIdx_flag;
    io_in_bits_uop_robIdx_value = inst_robIdx_value;
    io_in_bits_uop_fuType       = inst_fuType;
    io_in_bits_uop_fuOpType     = inst_fuOpType;
    io_in_bits_uop_vpu_nf       = inst_nf;
    io_in_bits_uop_vpu_vlmul    = inst_vlmul;
    io_in_bits_uop_vpu_vsew     = inst_vsew;
    io_in_bits_uop_vpu_veew     = inst_veew;
    io_in_bits_uop_vpu_vm       = inst_vm;
    io_in_bits_uop_vpu_vstart   = inst_vstart;
    io_in_bits_uop_vpu_vuopIdx  = 7'(burst_idx);
    io_in_bits_uop_vpu_lastUop  = (burst_left == 0);
    io_in_bits_src_4            = 128'(inst_vl);
    io_in_bits_src_3            = inst_mask;
    if (io_in_valid) burst_idx++;
    if ($urandom_range(0, 1)) io_in_bits_src_0[63:4] = '0;                     // 基址偏小，让非对齐 / 跨 16B 常见
    if ($urandom_range(0, 1)) io_in_bits_src_1[127:4] = '0;
    // ---- TLB / PMP ----
    io_dtlb_resp_valid     = ($urandom_range(0, 7) != 0);
    io_dtlb_resp_bits_miss = ($urandom_range(0, 7) == 0);
    io_dtlb_resp_bits_pbmt_0 = ($urandom_range(0, 7) < 6) ? 2'd0 : 2'($urandom);
    io_dtlb_resp_bits_excp_0_gpf_ld = ($urandom_range(0, 255) == 0);
    io_dtlb_resp_bits_excp_0_gpf_st = ($urandom_range(0, 255) == 0);
    io_dtlb_resp_bits_excp_0_pf_ld  = ($urandom_range(0, 255) == 0);
    io_dtlb_resp_bits_excp_0_pf_st  = ($urandom_range(0, 255) == 0);
    io_dtlb_resp_bits_excp_0_af_ld  = ($urandom_range(0, 255) == 0);
    io_dtlb_resp_bits_excp_0_af_st  = ($urandom_range(0, 255) == 0);
    io_pmpResp_ld   = ($urandom_range(0, 255) == 0);
    io_pmpResp_st   = ($urandom_range(0, 255) == 0);
    io_pmpResp_mmio = ($urandom_range(0, 255) == 0);
    // ---- DCache / sbuffer ----
    io_rdcache_req_ready   = ($urandom_range(0, 3) != 0);
    io_rdcache_resp_valid  = ($urandom_range(0, 7) != 0);
    io_rdcache_resp_bits_miss = ($urandom_range(0, 7) == 0);
    io_rdcache_s2_bank_conflict = ($urandom_range(0, 15) == 0);
    io_rdcache_resp_bits_tl_error_delayed_tl_denied  = ($urandom_range(0, 255) == 0);
    io_rdcache_resp_bits_tl_error_delayed_tl_corrupt = ($urandom_range(0, 255) == 0);
    io_sbuffer_ready       = ($urandom_range(0, 3) != 0);
    io_flush_sbuffer_empty = ($urandom_range(0, 3) != 0);
    io_csrCtrl_cache_error_enable = ($urandom_range(0, 7) != 0);
    // ---- 触发器 ----
    target  = {14'h0, u_golden.dcacheReqVaddr};
    trig_on = ($urandom_range(0, 15) == 0);
    `TRIG_CFG(0)
    `TRIG_CFG(1)
    `TRIG_CFG(2)
    `TRIG_CFG(3)
    io_fromCsrTrigger_debugMode            = ($urandom_range(0, 63) == 0);
    io_fromCsrTrigger_triggerCanRaiseBpExp = ($urandom_range(0, 5) != 0);
  endtask
  task automatic quiesce();
    io_in_valid = 0;
  endtask

`define C u_impl.u_core

  localparam int NCOV = 37;
  longint cov [NCOV];
  string  cov_names [NCOV] = '{"enq_uop", "inst_latch", "fof_fixvl_enq", "st_flush_sbuffer", "st_wait_flush", "st_tlb_req", "st_tlb_miss_retry", "st_pm", "st_cache_req", "st_cache_retry", "st_misalign_merge", "st_latch_merge", "st_send_data", "st_wait_to_sbuffer", "st_finish", "st_fof_fix_vl", "seg_inactive", "misalign_detected", "misalign_cross16", "load_second_half", "store_second_half", "exception_va", "exception_gpa", "exception_pa", "cache_error", "fof_suppressed_exc", "trigger_breakpoint", "trigger_debugmode", "indexed_inst", "strided_inst", "multi_field", "writeback", "writeback_fof", "feedback", "exception_info", "split_ptr_next_seg", "queue_wrap"};
  int     cov_min   [NCOV] = '{1000, 200, 50, 200, 50, 1000, 100, 1000, 500, 50, 30, 500, 500, 20, 500, 20, 200, 100, 50, 10, 10, 50, 5, 10, 3, 2, 5, 5, 300, 300, 300, 500, 20, 500, 50, 200, 100};
  task automatic collect_cov();
    if (`C.uopEnqueue) cov[0]++;
    if (`C.instMicroOp_load) cov[1]++;
    if (`C.fofBuffer_load) cov[2]++;
    if (`C.state == 4'd1) cov[3]++;
    if (`C.state == 4'd2) cov[4]++;
    if (`C.state == 4'd3) cov[5]++;
    if ((`C.state == 4'd4) & io_dtlb_resp_valid & io_dtlb_resp_bits_miss) cov[6]++;
    if (`C.state == 4'd5) cov[7]++;
    if (`C.state == 4'd6) cov[8]++;
    if ((`C.state == 4'd7) & io_rdcache_resp_valid & (io_rdcache_resp_bits_miss | io_rdcache_s2_bank_conflict)) cov[9]++;
    if (`C.state == 4'd8) cov[10]++;
    if (`C.state == 4'd9) cov[11]++;
    if (`C.state == 4'd10) cov[12]++;
    if (`C.state == 4'd11) cov[13]++;
    if (`C.state == 4'd12) cov[14]++;
    if (`C.state == 4'd13) cov[15]++;
    if ((`C.state == 4'd3) & ~`C.segmentActive) cov[16]++;
    if ((`C.state == 4'd5) & `C.isMisalignWire & ~`C.anyException) cov[17]++;
    if ((`C.state == 4'd5) & `C.isMisalignWire & ~`C.notCross16ByteWire & ~`C.anyException) cov[18]++;
    if ((`C.state == 4'd8) & `C.curPtr) cov[19]++;
    if ((`C.state == 4'd10) & `C.isMisalignReg & ~`C.notCross16ByteReg & `C.curPtr & `C.sbufferOut_fire) cov[20]++;
    if (`C.exception_va) cov[21]++;
    if (`C.exception_gpa) cov[22]++;
    if (`C.exception_pa) cov[23]++;
    if (`C.cacheRespError) cov[24]++;
    if ((`C.state == 4'd5) & `C.anyException & ~`C.canTriggerException) cov[25]++;
    if ((`C.state == 4'd5) & `C.triggerBreakpoint) cov[26]++;
    if ((`C.state == 4'd5) & `C.triggerDebugMode) cov[27]++;
    if ((`C.state == 4'd3) & `C.issueIsIndexed) cov[28]++;
    if ((`C.state == 4'd3) & (`C.instMicroOp_uop_q.fuOpType[6:5] == 2'b10)) cov[29]++;
    if ((`C.state == 4'd3) & (`C.fieldIdx != 4'd0)) cov[30]++;
    if (`C.writebackValid) cov[31]++;
    if (`C.fofFixVlValid) cov[32]++;
    if (`C.feedbackValid) cov[33]++;
    if (`C.exceptionInfo_valid) cov[34]++;
    if ((`C.state == 4'd9) & (`C.fieldDone | ~`C.segmentActive)) cov[35]++;
    if (`C.uopEnqueue & (`C.enqPtr_value == 3'd7)) cov[36]++;
  endtask

  initial begin
    int bad = 0;
    if (!$value$plusargs("ncycles=%d", NCYCLES)) NCYCLES = 200000;
    if (!$value$plusargs("warmup=%d", WARMUP))   WARMUP  = 0;
    for (int i = 0; i < NCOV; i++) cov[i] = 0;
    reset = 1'b1;
    drive();
    quiesce();
    repeat (5) @(negedge clock);
    reset = 1'b0;
    for (int c = 0; c < NCYCLES + WARMUP; c++) begin
      drive();
      #4;
      if (c >= WARMUP) begin
        compare();
        collect_cov();
      end
      @(negedge clock);
    end
    for (int i = 0; i < NCOV; i++) begin
      $display("  cov %-24s = %0d (min %0d)%s", cov_names[i], cov[i], cov_min[i],
               (cov[i] < cov_min[i]) ? "  <-- LOW" : "");
      if (cov[i] < cov_min[i]) bad++;
    end
    $display("=== COVERAGE (VSegmentUnit) === checks=%0d uncovered=%0d", checks, bad);
    if (bad != 0) begin $display("COVERAGE INSUFFICIENT"); errors++; end
    $display("VSegmentUnit UT: checks=%0d errors=%0d", checks, errors);
    if (errors == 0) $display("TEST PASSED (checks=%0d)", checks);
    else             $display("TEST FAILED errors=%0d (checks=%0d)", errors, checks);
    $finish;
  end
endmodule
