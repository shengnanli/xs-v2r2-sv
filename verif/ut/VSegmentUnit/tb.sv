// 自动生成 gen_vsegment.py —— 勿手改。双例化 golden VSegmentUnit vs VSegmentUnit_xs 逐拍比对。
`timescale 1ns/1ps
module tb;
  int unsigned NCYCLES = 200000;
  int unsigned WARMUP  = 8;
  bit clk = 0, rst;
  int errors = 0, checks = 0, cyc = 0;
  always #5 clk = ~clk;

  logic io_in_valid;
  logic [34:0] io_in_bits_uop_fuType;
  logic [8:0] io_in_bits_uop_fuOpType;
  logic io_in_bits_uop_vecWen;
  logic io_in_bits_uop_v0Wen;
  logic io_in_bits_uop_vlWen;
  logic io_in_bits_uop_vpu_vma;
  logic io_in_bits_uop_vpu_vta;
  logic [1:0] io_in_bits_uop_vpu_vsew;
  logic [2:0] io_in_bits_uop_vpu_vlmul;
  logic io_in_bits_uop_vpu_vm;
  logic [7:0] io_in_bits_uop_vpu_vstart;
  logic [6:0] io_in_bits_uop_vpu_vuopIdx;
  logic io_in_bits_uop_vpu_lastUop;
  logic [2:0] io_in_bits_uop_vpu_nf;
  logic [1:0] io_in_bits_uop_vpu_veew;
  logic [7:0] io_in_bits_uop_pdest;
  logic io_in_bits_uop_robIdx_flag;
  logic [7:0] io_in_bits_uop_robIdx_value;
  logic [63:0] io_in_bits_uop_debugInfo_enqRsTime;
  logic [63:0] io_in_bits_uop_debugInfo_selectTime;
  logic [63:0] io_in_bits_uop_debugInfo_issueTime;
  logic io_in_bits_uop_lqIdx_flag;
  logic [6:0] io_in_bits_uop_lqIdx_value;
  logic io_in_bits_uop_sqIdx_flag;
  logic [5:0] io_in_bits_uop_sqIdx_value;
  logic [127:0] io_in_bits_src_0;
  logic [127:0] io_in_bits_src_1;
  logic [127:0] io_in_bits_src_2;
  logic [127:0] io_in_bits_src_3;
  logic [127:0] io_in_bits_src_4;
  logic io_csrCtrl_cache_error_enable;
  logic io_rdcache_req_ready;
  logic io_rdcache_resp_valid;
  logic [127:0] io_rdcache_resp_bits_data_delayed;
  logic io_rdcache_resp_bits_miss;
  logic io_rdcache_resp_bits_error_delayed;
  logic io_rdcache_s2_bank_conflict;
  logic io_sbuffer_ready;
  logic io_dtlb_resp_valid;
  logic [47:0] io_dtlb_resp_bits_paddr_0;
  logic [63:0] io_dtlb_resp_bits_gpaddr_0;
  logic [63:0] io_dtlb_resp_bits_fullva;
  logic [1:0] io_dtlb_resp_bits_pbmt_0;
  logic io_dtlb_resp_bits_miss;
  logic io_dtlb_resp_bits_isForVSnonLeafPTE;
  logic io_dtlb_resp_bits_excp_0_gpf_ld;
  logic io_dtlb_resp_bits_excp_0_gpf_st;
  logic io_dtlb_resp_bits_excp_0_pf_ld;
  logic io_dtlb_resp_bits_excp_0_pf_st;
  logic io_dtlb_resp_bits_excp_0_af_ld;
  logic io_dtlb_resp_bits_excp_0_af_st;
  logic io_pmpResp_ld;
  logic io_pmpResp_st;
  logic io_pmpResp_instr;
  logic io_pmpResp_mmio;
  logic io_pmpResp_atomic;
  logic io_flush_sbuffer_empty;
  logic [1:0] io_fromCsrTrigger_tdataVec_0_matchType;
  logic io_fromCsrTrigger_tdataVec_0_select;
  logic io_fromCsrTrigger_tdataVec_0_timing;
  logic [3:0] io_fromCsrTrigger_tdataVec_0_action;
  logic io_fromCsrTrigger_tdataVec_0_chain;
  logic io_fromCsrTrigger_tdataVec_0_store;
  logic io_fromCsrTrigger_tdataVec_0_load;
  logic [63:0] io_fromCsrTrigger_tdataVec_0_tdata2;
  logic [1:0] io_fromCsrTrigger_tdataVec_1_matchType;
  logic io_fromCsrTrigger_tdataVec_1_select;
  logic io_fromCsrTrigger_tdataVec_1_timing;
  logic [3:0] io_fromCsrTrigger_tdataVec_1_action;
  logic io_fromCsrTrigger_tdataVec_1_chain;
  logic io_fromCsrTrigger_tdataVec_1_store;
  logic io_fromCsrTrigger_tdataVec_1_load;
  logic [63:0] io_fromCsrTrigger_tdataVec_1_tdata2;
  logic [1:0] io_fromCsrTrigger_tdataVec_2_matchType;
  logic io_fromCsrTrigger_tdataVec_2_select;
  logic io_fromCsrTrigger_tdataVec_2_timing;
  logic [3:0] io_fromCsrTrigger_tdataVec_2_action;
  logic io_fromCsrTrigger_tdataVec_2_chain;
  logic io_fromCsrTrigger_tdataVec_2_store;
  logic io_fromCsrTrigger_tdataVec_2_load;
  logic [63:0] io_fromCsrTrigger_tdataVec_2_tdata2;
  logic [1:0] io_fromCsrTrigger_tdataVec_3_matchType;
  logic io_fromCsrTrigger_tdataVec_3_select;
  logic io_fromCsrTrigger_tdataVec_3_timing;
  logic [3:0] io_fromCsrTrigger_tdataVec_3_action;
  logic io_fromCsrTrigger_tdataVec_3_chain;
  logic io_fromCsrTrigger_tdataVec_3_store;
  logic io_fromCsrTrigger_tdataVec_3_load;
  logic [63:0] io_fromCsrTrigger_tdataVec_3_tdata2;
  logic io_fromCsrTrigger_tEnableVec_0;
  logic io_fromCsrTrigger_tEnableVec_1;
  logic io_fromCsrTrigger_tEnableVec_2;
  logic io_fromCsrTrigger_tEnableVec_3;
  logic io_fromCsrTrigger_debugMode;
  logic io_fromCsrTrigger_triggerCanRaiseBpExp;
  logic g_io_uopwriteback_valid;
  logic i_io_uopwriteback_valid;
  logic g_io_uopwriteback_bits_uop_exceptionVec_3;
  logic i_io_uopwriteback_bits_uop_exceptionVec_3;
  logic g_io_uopwriteback_bits_uop_exceptionVec_5;
  logic i_io_uopwriteback_bits_uop_exceptionVec_5;
  logic g_io_uopwriteback_bits_uop_exceptionVec_7;
  logic i_io_uopwriteback_bits_uop_exceptionVec_7;
  logic g_io_uopwriteback_bits_uop_exceptionVec_13;
  logic i_io_uopwriteback_bits_uop_exceptionVec_13;
  logic g_io_uopwriteback_bits_uop_exceptionVec_15;
  logic i_io_uopwriteback_bits_uop_exceptionVec_15;
  logic g_io_uopwriteback_bits_uop_exceptionVec_19;
  logic i_io_uopwriteback_bits_uop_exceptionVec_19;
  logic g_io_uopwriteback_bits_uop_exceptionVec_21;
  logic i_io_uopwriteback_bits_uop_exceptionVec_21;
  logic g_io_uopwriteback_bits_uop_exceptionVec_23;
  logic i_io_uopwriteback_bits_uop_exceptionVec_23;
  logic [3:0] g_io_uopwriteback_bits_uop_trigger;
  logic [3:0] i_io_uopwriteback_bits_uop_trigger;
  logic [8:0] g_io_uopwriteback_bits_uop_fuOpType;
  logic [8:0] i_io_uopwriteback_bits_uop_fuOpType;
  logic g_io_uopwriteback_bits_uop_vecWen;
  logic i_io_uopwriteback_bits_uop_vecWen;
  logic g_io_uopwriteback_bits_uop_v0Wen;
  logic i_io_uopwriteback_bits_uop_v0Wen;
  logic g_io_uopwriteback_bits_uop_vlWen;
  logic i_io_uopwriteback_bits_uop_vlWen;
  logic g_io_uopwriteback_bits_uop_vpu_vma;
  logic i_io_uopwriteback_bits_uop_vpu_vma;
  logic g_io_uopwriteback_bits_uop_vpu_vta;
  logic i_io_uopwriteback_bits_uop_vpu_vta;
  logic [1:0] g_io_uopwriteback_bits_uop_vpu_vsew;
  logic [1:0] i_io_uopwriteback_bits_uop_vpu_vsew;
  logic [2:0] g_io_uopwriteback_bits_uop_vpu_vlmul;
  logic [2:0] i_io_uopwriteback_bits_uop_vpu_vlmul;
  logic g_io_uopwriteback_bits_uop_vpu_vm;
  logic i_io_uopwriteback_bits_uop_vpu_vm;
  logic [7:0] g_io_uopwriteback_bits_uop_vpu_vstart;
  logic [7:0] i_io_uopwriteback_bits_uop_vpu_vstart;
  logic [6:0] g_io_uopwriteback_bits_uop_vpu_vuopIdx;
  logic [6:0] i_io_uopwriteback_bits_uop_vpu_vuopIdx;
  logic [127:0] g_io_uopwriteback_bits_uop_vpu_vmask;
  logic [127:0] i_io_uopwriteback_bits_uop_vpu_vmask;
  logic [7:0] g_io_uopwriteback_bits_uop_vpu_vl;
  logic [7:0] i_io_uopwriteback_bits_uop_vpu_vl;
  logic [2:0] g_io_uopwriteback_bits_uop_vpu_nf;
  logic [2:0] i_io_uopwriteback_bits_uop_vpu_nf;
  logic [1:0] g_io_uopwriteback_bits_uop_vpu_veew;
  logic [1:0] i_io_uopwriteback_bits_uop_vpu_veew;
  logic [7:0] g_io_uopwriteback_bits_uop_pdest;
  logic [7:0] i_io_uopwriteback_bits_uop_pdest;
  logic g_io_uopwriteback_bits_uop_robIdx_flag;
  logic i_io_uopwriteback_bits_uop_robIdx_flag;
  logic [7:0] g_io_uopwriteback_bits_uop_robIdx_value;
  logic [7:0] i_io_uopwriteback_bits_uop_robIdx_value;
  logic [63:0] g_io_uopwriteback_bits_uop_debugInfo_enqRsTime;
  logic [63:0] i_io_uopwriteback_bits_uop_debugInfo_enqRsTime;
  logic [63:0] g_io_uopwriteback_bits_uop_debugInfo_selectTime;
  logic [63:0] i_io_uopwriteback_bits_uop_debugInfo_selectTime;
  logic [63:0] g_io_uopwriteback_bits_uop_debugInfo_issueTime;
  logic [63:0] i_io_uopwriteback_bits_uop_debugInfo_issueTime;
  logic [127:0] g_io_uopwriteback_bits_data;
  logic [127:0] i_io_uopwriteback_bits_data;
  logic [2:0] g_io_uopwriteback_bits_vdIdx;
  logic [2:0] i_io_uopwriteback_bits_vdIdx;
  logic [2:0] g_io_uopwriteback_bits_vdIdxInField;
  logic [2:0] i_io_uopwriteback_bits_vdIdxInField;
  logic g_io_uopwriteback_bits_debug_isMMIO;
  logic i_io_uopwriteback_bits_debug_isMMIO;
  logic g_io_uopwriteback_bits_debug_isNCIO;
  logic i_io_uopwriteback_bits_debug_isNCIO;
  logic g_io_uopwriteback_bits_debug_isPerfCnt;
  logic i_io_uopwriteback_bits_debug_isPerfCnt;
  logic g_io_rdcache_req_valid;
  logic i_io_rdcache_req_valid;
  logic [49:0] g_io_rdcache_req_bits_vaddr;
  logic [49:0] i_io_rdcache_req_bits_vaddr;
  logic [49:0] g_io_rdcache_req_bits_vaddr_dup;
  logic [49:0] i_io_rdcache_req_bits_vaddr_dup;
  logic g_io_rdcache_is128Req;
  logic i_io_rdcache_is128Req;
  logic [47:0] g_io_rdcache_s1_paddr_dup_lsu;
  logic [47:0] i_io_rdcache_s1_paddr_dup_lsu;
  logic [47:0] g_io_rdcache_s1_paddr_dup_dcache;
  logic [47:0] i_io_rdcache_s1_paddr_dup_dcache;
  logic g_io_sbuffer_valid;
  logic i_io_sbuffer_valid;
  logic [49:0] g_io_sbuffer_bits_vaddr;
  logic [49:0] i_io_sbuffer_bits_vaddr;
  logic [127:0] g_io_sbuffer_bits_data;
  logic [127:0] i_io_sbuffer_bits_data;
  logic [15:0] g_io_sbuffer_bits_mask;
  logic [15:0] i_io_sbuffer_bits_mask;
  logic [47:0] g_io_sbuffer_bits_addr;
  logic [47:0] i_io_sbuffer_bits_addr;
  logic g_io_sbuffer_bits_vecValid;
  logic i_io_sbuffer_bits_vecValid;
  logic g_io_dtlb_req_valid;
  logic i_io_dtlb_req_valid;
  logic [49:0] g_io_dtlb_req_bits_vaddr;
  logic [49:0] i_io_dtlb_req_bits_vaddr;
  logic [63:0] g_io_dtlb_req_bits_fullva;
  logic [63:0] i_io_dtlb_req_bits_fullva;
  logic [2:0] g_io_dtlb_req_bits_cmd;
  logic [2:0] i_io_dtlb_req_bits_cmd;
  logic g_io_dtlb_req_bits_debug_robIdx_flag;
  logic i_io_dtlb_req_bits_debug_robIdx_flag;
  logic [7:0] g_io_dtlb_req_bits_debug_robIdx_value;
  logic [7:0] i_io_dtlb_req_bits_debug_robIdx_value;
  logic g_io_flush_sbuffer_valid;
  logic i_io_flush_sbuffer_valid;
  logic g_io_feedback_valid;
  logic i_io_feedback_valid;
  logic g_io_feedback_bits_sqIdx_flag;
  logic i_io_feedback_bits_sqIdx_flag;
  logic [5:0] g_io_feedback_bits_sqIdx_value;
  logic [5:0] i_io_feedback_bits_sqIdx_value;
  logic g_io_feedback_bits_lqIdx_flag;
  logic i_io_feedback_bits_lqIdx_flag;
  logic [6:0] g_io_feedback_bits_lqIdx_value;
  logic [6:0] i_io_feedback_bits_lqIdx_value;
  logic g_io_exceptionInfo_valid;
  logic i_io_exceptionInfo_valid;
  logic [63:0] g_io_exceptionInfo_bits_vaddr;
  logic [63:0] i_io_exceptionInfo_bits_vaddr;
  logic [49:0] g_io_exceptionInfo_bits_gpaddr;
  logic [49:0] i_io_exceptionInfo_bits_gpaddr;
  logic g_io_exceptionInfo_bits_isForVSnonLeafPTE;
  logic i_io_exceptionInfo_bits_isForVSnonLeafPTE;

  VSegmentUnit u_g (
    .clock(clk), .reset(rst),
    .io_in_valid(io_in_valid),
    .io_in_bits_uop_fuType(io_in_bits_uop_fuType),
    .io_in_bits_uop_fuOpType(io_in_bits_uop_fuOpType),
    .io_in_bits_uop_vecWen(io_in_bits_uop_vecWen),
    .io_in_bits_uop_v0Wen(io_in_bits_uop_v0Wen),
    .io_in_bits_uop_vlWen(io_in_bits_uop_vlWen),
    .io_in_bits_uop_vpu_vma(io_in_bits_uop_vpu_vma),
    .io_in_bits_uop_vpu_vta(io_in_bits_uop_vpu_vta),
    .io_in_bits_uop_vpu_vsew(io_in_bits_uop_vpu_vsew),
    .io_in_bits_uop_vpu_vlmul(io_in_bits_uop_vpu_vlmul),
    .io_in_bits_uop_vpu_vm(io_in_bits_uop_vpu_vm),
    .io_in_bits_uop_vpu_vstart(io_in_bits_uop_vpu_vstart),
    .io_in_bits_uop_vpu_vuopIdx(io_in_bits_uop_vpu_vuopIdx),
    .io_in_bits_uop_vpu_lastUop(io_in_bits_uop_vpu_lastUop),
    .io_in_bits_uop_vpu_nf(io_in_bits_uop_vpu_nf),
    .io_in_bits_uop_vpu_veew(io_in_bits_uop_vpu_veew),
    .io_in_bits_uop_pdest(io_in_bits_uop_pdest),
    .io_in_bits_uop_robIdx_flag(io_in_bits_uop_robIdx_flag),
    .io_in_bits_uop_robIdx_value(io_in_bits_uop_robIdx_value),
    .io_in_bits_uop_debugInfo_enqRsTime(io_in_bits_uop_debugInfo_enqRsTime),
    .io_in_bits_uop_debugInfo_selectTime(io_in_bits_uop_debugInfo_selectTime),
    .io_in_bits_uop_debugInfo_issueTime(io_in_bits_uop_debugInfo_issueTime),
    .io_in_bits_uop_lqIdx_flag(io_in_bits_uop_lqIdx_flag),
    .io_in_bits_uop_lqIdx_value(io_in_bits_uop_lqIdx_value),
    .io_in_bits_uop_sqIdx_flag(io_in_bits_uop_sqIdx_flag),
    .io_in_bits_uop_sqIdx_value(io_in_bits_uop_sqIdx_value),
    .io_in_bits_src_0(io_in_bits_src_0),
    .io_in_bits_src_1(io_in_bits_src_1),
    .io_in_bits_src_2(io_in_bits_src_2),
    .io_in_bits_src_3(io_in_bits_src_3),
    .io_in_bits_src_4(io_in_bits_src_4),
    .io_csrCtrl_cache_error_enable(io_csrCtrl_cache_error_enable),
    .io_rdcache_req_ready(io_rdcache_req_ready),
    .io_rdcache_resp_valid(io_rdcache_resp_valid),
    .io_rdcache_resp_bits_data_delayed(io_rdcache_resp_bits_data_delayed),
    .io_rdcache_resp_bits_miss(io_rdcache_resp_bits_miss),
    .io_rdcache_resp_bits_error_delayed(io_rdcache_resp_bits_error_delayed),
    .io_rdcache_s2_bank_conflict(io_rdcache_s2_bank_conflict),
    .io_sbuffer_ready(io_sbuffer_ready),
    .io_dtlb_resp_valid(io_dtlb_resp_valid),
    .io_dtlb_resp_bits_paddr_0(io_dtlb_resp_bits_paddr_0),
    .io_dtlb_resp_bits_gpaddr_0(io_dtlb_resp_bits_gpaddr_0),
    .io_dtlb_resp_bits_fullva(io_dtlb_resp_bits_fullva),
    .io_dtlb_resp_bits_pbmt_0(io_dtlb_resp_bits_pbmt_0),
    .io_dtlb_resp_bits_miss(io_dtlb_resp_bits_miss),
    .io_dtlb_resp_bits_isForVSnonLeafPTE(io_dtlb_resp_bits_isForVSnonLeafPTE),
    .io_dtlb_resp_bits_excp_0_gpf_ld(io_dtlb_resp_bits_excp_0_gpf_ld),
    .io_dtlb_resp_bits_excp_0_gpf_st(io_dtlb_resp_bits_excp_0_gpf_st),
    .io_dtlb_resp_bits_excp_0_pf_ld(io_dtlb_resp_bits_excp_0_pf_ld),
    .io_dtlb_resp_bits_excp_0_pf_st(io_dtlb_resp_bits_excp_0_pf_st),
    .io_dtlb_resp_bits_excp_0_af_ld(io_dtlb_resp_bits_excp_0_af_ld),
    .io_dtlb_resp_bits_excp_0_af_st(io_dtlb_resp_bits_excp_0_af_st),
    .io_pmpResp_ld(io_pmpResp_ld),
    .io_pmpResp_st(io_pmpResp_st),
    .io_pmpResp_instr(io_pmpResp_instr),
    .io_pmpResp_mmio(io_pmpResp_mmio),
    .io_pmpResp_atomic(io_pmpResp_atomic),
    .io_flush_sbuffer_empty(io_flush_sbuffer_empty),
    .io_fromCsrTrigger_tdataVec_0_matchType(io_fromCsrTrigger_tdataVec_0_matchType),
    .io_fromCsrTrigger_tdataVec_0_select(io_fromCsrTrigger_tdataVec_0_select),
    .io_fromCsrTrigger_tdataVec_0_timing(io_fromCsrTrigger_tdataVec_0_timing),
    .io_fromCsrTrigger_tdataVec_0_action(io_fromCsrTrigger_tdataVec_0_action),
    .io_fromCsrTrigger_tdataVec_0_chain(io_fromCsrTrigger_tdataVec_0_chain),
    .io_fromCsrTrigger_tdataVec_0_store(io_fromCsrTrigger_tdataVec_0_store),
    .io_fromCsrTrigger_tdataVec_0_load(io_fromCsrTrigger_tdataVec_0_load),
    .io_fromCsrTrigger_tdataVec_0_tdata2(io_fromCsrTrigger_tdataVec_0_tdata2),
    .io_fromCsrTrigger_tdataVec_1_matchType(io_fromCsrTrigger_tdataVec_1_matchType),
    .io_fromCsrTrigger_tdataVec_1_select(io_fromCsrTrigger_tdataVec_1_select),
    .io_fromCsrTrigger_tdataVec_1_timing(io_fromCsrTrigger_tdataVec_1_timing),
    .io_fromCsrTrigger_tdataVec_1_action(io_fromCsrTrigger_tdataVec_1_action),
    .io_fromCsrTrigger_tdataVec_1_chain(io_fromCsrTrigger_tdataVec_1_chain),
    .io_fromCsrTrigger_tdataVec_1_store(io_fromCsrTrigger_tdataVec_1_store),
    .io_fromCsrTrigger_tdataVec_1_load(io_fromCsrTrigger_tdataVec_1_load),
    .io_fromCsrTrigger_tdataVec_1_tdata2(io_fromCsrTrigger_tdataVec_1_tdata2),
    .io_fromCsrTrigger_tdataVec_2_matchType(io_fromCsrTrigger_tdataVec_2_matchType),
    .io_fromCsrTrigger_tdataVec_2_select(io_fromCsrTrigger_tdataVec_2_select),
    .io_fromCsrTrigger_tdataVec_2_timing(io_fromCsrTrigger_tdataVec_2_timing),
    .io_fromCsrTrigger_tdataVec_2_action(io_fromCsrTrigger_tdataVec_2_action),
    .io_fromCsrTrigger_tdataVec_2_chain(io_fromCsrTrigger_tdataVec_2_chain),
    .io_fromCsrTrigger_tdataVec_2_store(io_fromCsrTrigger_tdataVec_2_store),
    .io_fromCsrTrigger_tdataVec_2_load(io_fromCsrTrigger_tdataVec_2_load),
    .io_fromCsrTrigger_tdataVec_2_tdata2(io_fromCsrTrigger_tdataVec_2_tdata2),
    .io_fromCsrTrigger_tdataVec_3_matchType(io_fromCsrTrigger_tdataVec_3_matchType),
    .io_fromCsrTrigger_tdataVec_3_select(io_fromCsrTrigger_tdataVec_3_select),
    .io_fromCsrTrigger_tdataVec_3_timing(io_fromCsrTrigger_tdataVec_3_timing),
    .io_fromCsrTrigger_tdataVec_3_action(io_fromCsrTrigger_tdataVec_3_action),
    .io_fromCsrTrigger_tdataVec_3_chain(io_fromCsrTrigger_tdataVec_3_chain),
    .io_fromCsrTrigger_tdataVec_3_store(io_fromCsrTrigger_tdataVec_3_store),
    .io_fromCsrTrigger_tdataVec_3_load(io_fromCsrTrigger_tdataVec_3_load),
    .io_fromCsrTrigger_tdataVec_3_tdata2(io_fromCsrTrigger_tdataVec_3_tdata2),
    .io_fromCsrTrigger_tEnableVec_0(io_fromCsrTrigger_tEnableVec_0),
    .io_fromCsrTrigger_tEnableVec_1(io_fromCsrTrigger_tEnableVec_1),
    .io_fromCsrTrigger_tEnableVec_2(io_fromCsrTrigger_tEnableVec_2),
    .io_fromCsrTrigger_tEnableVec_3(io_fromCsrTrigger_tEnableVec_3),
    .io_fromCsrTrigger_debugMode(io_fromCsrTrigger_debugMode),
    .io_fromCsrTrigger_triggerCanRaiseBpExp(io_fromCsrTrigger_triggerCanRaiseBpExp),
    .io_uopwriteback_valid(g_io_uopwriteback_valid),
    .io_uopwriteback_bits_uop_exceptionVec_3(g_io_uopwriteback_bits_uop_exceptionVec_3),
    .io_uopwriteback_bits_uop_exceptionVec_5(g_io_uopwriteback_bits_uop_exceptionVec_5),
    .io_uopwriteback_bits_uop_exceptionVec_7(g_io_uopwriteback_bits_uop_exceptionVec_7),
    .io_uopwriteback_bits_uop_exceptionVec_13(g_io_uopwriteback_bits_uop_exceptionVec_13),
    .io_uopwriteback_bits_uop_exceptionVec_15(g_io_uopwriteback_bits_uop_exceptionVec_15),
    .io_uopwriteback_bits_uop_exceptionVec_19(g_io_uopwriteback_bits_uop_exceptionVec_19),
    .io_uopwriteback_bits_uop_exceptionVec_21(g_io_uopwriteback_bits_uop_exceptionVec_21),
    .io_uopwriteback_bits_uop_exceptionVec_23(g_io_uopwriteback_bits_uop_exceptionVec_23),
    .io_uopwriteback_bits_uop_trigger(g_io_uopwriteback_bits_uop_trigger),
    .io_uopwriteback_bits_uop_fuOpType(g_io_uopwriteback_bits_uop_fuOpType),
    .io_uopwriteback_bits_uop_vecWen(g_io_uopwriteback_bits_uop_vecWen),
    .io_uopwriteback_bits_uop_v0Wen(g_io_uopwriteback_bits_uop_v0Wen),
    .io_uopwriteback_bits_uop_vlWen(g_io_uopwriteback_bits_uop_vlWen),
    .io_uopwriteback_bits_uop_vpu_vma(g_io_uopwriteback_bits_uop_vpu_vma),
    .io_uopwriteback_bits_uop_vpu_vta(g_io_uopwriteback_bits_uop_vpu_vta),
    .io_uopwriteback_bits_uop_vpu_vsew(g_io_uopwriteback_bits_uop_vpu_vsew),
    .io_uopwriteback_bits_uop_vpu_vlmul(g_io_uopwriteback_bits_uop_vpu_vlmul),
    .io_uopwriteback_bits_uop_vpu_vm(g_io_uopwriteback_bits_uop_vpu_vm),
    .io_uopwriteback_bits_uop_vpu_vstart(g_io_uopwriteback_bits_uop_vpu_vstart),
    .io_uopwriteback_bits_uop_vpu_vuopIdx(g_io_uopwriteback_bits_uop_vpu_vuopIdx),
    .io_uopwriteback_bits_uop_vpu_vmask(g_io_uopwriteback_bits_uop_vpu_vmask),
    .io_uopwriteback_bits_uop_vpu_vl(g_io_uopwriteback_bits_uop_vpu_vl),
    .io_uopwriteback_bits_uop_vpu_nf(g_io_uopwriteback_bits_uop_vpu_nf),
    .io_uopwriteback_bits_uop_vpu_veew(g_io_uopwriteback_bits_uop_vpu_veew),
    .io_uopwriteback_bits_uop_pdest(g_io_uopwriteback_bits_uop_pdest),
    .io_uopwriteback_bits_uop_robIdx_flag(g_io_uopwriteback_bits_uop_robIdx_flag),
    .io_uopwriteback_bits_uop_robIdx_value(g_io_uopwriteback_bits_uop_robIdx_value),
    .io_uopwriteback_bits_uop_debugInfo_enqRsTime(g_io_uopwriteback_bits_uop_debugInfo_enqRsTime),
    .io_uopwriteback_bits_uop_debugInfo_selectTime(g_io_uopwriteback_bits_uop_debugInfo_selectTime),
    .io_uopwriteback_bits_uop_debugInfo_issueTime(g_io_uopwriteback_bits_uop_debugInfo_issueTime),
    .io_uopwriteback_bits_data(g_io_uopwriteback_bits_data),
    .io_uopwriteback_bits_vdIdx(g_io_uopwriteback_bits_vdIdx),
    .io_uopwriteback_bits_vdIdxInField(g_io_uopwriteback_bits_vdIdxInField),
    .io_uopwriteback_bits_debug_isMMIO(g_io_uopwriteback_bits_debug_isMMIO),
    .io_uopwriteback_bits_debug_isNCIO(g_io_uopwriteback_bits_debug_isNCIO),
    .io_uopwriteback_bits_debug_isPerfCnt(g_io_uopwriteback_bits_debug_isPerfCnt),
    .io_rdcache_req_valid(g_io_rdcache_req_valid),
    .io_rdcache_req_bits_vaddr(g_io_rdcache_req_bits_vaddr),
    .io_rdcache_req_bits_vaddr_dup(g_io_rdcache_req_bits_vaddr_dup),
    .io_rdcache_is128Req(g_io_rdcache_is128Req),
    .io_rdcache_s1_paddr_dup_lsu(g_io_rdcache_s1_paddr_dup_lsu),
    .io_rdcache_s1_paddr_dup_dcache(g_io_rdcache_s1_paddr_dup_dcache),
    .io_sbuffer_valid(g_io_sbuffer_valid),
    .io_sbuffer_bits_vaddr(g_io_sbuffer_bits_vaddr),
    .io_sbuffer_bits_data(g_io_sbuffer_bits_data),
    .io_sbuffer_bits_mask(g_io_sbuffer_bits_mask),
    .io_sbuffer_bits_addr(g_io_sbuffer_bits_addr),
    .io_sbuffer_bits_vecValid(g_io_sbuffer_bits_vecValid),
    .io_dtlb_req_valid(g_io_dtlb_req_valid),
    .io_dtlb_req_bits_vaddr(g_io_dtlb_req_bits_vaddr),
    .io_dtlb_req_bits_fullva(g_io_dtlb_req_bits_fullva),
    .io_dtlb_req_bits_cmd(g_io_dtlb_req_bits_cmd),
    .io_dtlb_req_bits_debug_robIdx_flag(g_io_dtlb_req_bits_debug_robIdx_flag),
    .io_dtlb_req_bits_debug_robIdx_value(g_io_dtlb_req_bits_debug_robIdx_value),
    .io_flush_sbuffer_valid(g_io_flush_sbuffer_valid),
    .io_feedback_valid(g_io_feedback_valid),
    .io_feedback_bits_sqIdx_flag(g_io_feedback_bits_sqIdx_flag),
    .io_feedback_bits_sqIdx_value(g_io_feedback_bits_sqIdx_value),
    .io_feedback_bits_lqIdx_flag(g_io_feedback_bits_lqIdx_flag),
    .io_feedback_bits_lqIdx_value(g_io_feedback_bits_lqIdx_value),
    .io_exceptionInfo_valid(g_io_exceptionInfo_valid),
    .io_exceptionInfo_bits_vaddr(g_io_exceptionInfo_bits_vaddr),
    .io_exceptionInfo_bits_gpaddr(g_io_exceptionInfo_bits_gpaddr),
    .io_exceptionInfo_bits_isForVSnonLeafPTE(g_io_exceptionInfo_bits_isForVSnonLeafPTE)
  );
  VSegmentUnit_xs u_i (
    .clock(clk), .reset(rst),
    .io_in_valid(io_in_valid),
    .io_in_bits_uop_fuType(io_in_bits_uop_fuType),
    .io_in_bits_uop_fuOpType(io_in_bits_uop_fuOpType),
    .io_in_bits_uop_vecWen(io_in_bits_uop_vecWen),
    .io_in_bits_uop_v0Wen(io_in_bits_uop_v0Wen),
    .io_in_bits_uop_vlWen(io_in_bits_uop_vlWen),
    .io_in_bits_uop_vpu_vma(io_in_bits_uop_vpu_vma),
    .io_in_bits_uop_vpu_vta(io_in_bits_uop_vpu_vta),
    .io_in_bits_uop_vpu_vsew(io_in_bits_uop_vpu_vsew),
    .io_in_bits_uop_vpu_vlmul(io_in_bits_uop_vpu_vlmul),
    .io_in_bits_uop_vpu_vm(io_in_bits_uop_vpu_vm),
    .io_in_bits_uop_vpu_vstart(io_in_bits_uop_vpu_vstart),
    .io_in_bits_uop_vpu_vuopIdx(io_in_bits_uop_vpu_vuopIdx),
    .io_in_bits_uop_vpu_lastUop(io_in_bits_uop_vpu_lastUop),
    .io_in_bits_uop_vpu_nf(io_in_bits_uop_vpu_nf),
    .io_in_bits_uop_vpu_veew(io_in_bits_uop_vpu_veew),
    .io_in_bits_uop_pdest(io_in_bits_uop_pdest),
    .io_in_bits_uop_robIdx_flag(io_in_bits_uop_robIdx_flag),
    .io_in_bits_uop_robIdx_value(io_in_bits_uop_robIdx_value),
    .io_in_bits_uop_debugInfo_enqRsTime(io_in_bits_uop_debugInfo_enqRsTime),
    .io_in_bits_uop_debugInfo_selectTime(io_in_bits_uop_debugInfo_selectTime),
    .io_in_bits_uop_debugInfo_issueTime(io_in_bits_uop_debugInfo_issueTime),
    .io_in_bits_uop_lqIdx_flag(io_in_bits_uop_lqIdx_flag),
    .io_in_bits_uop_lqIdx_value(io_in_bits_uop_lqIdx_value),
    .io_in_bits_uop_sqIdx_flag(io_in_bits_uop_sqIdx_flag),
    .io_in_bits_uop_sqIdx_value(io_in_bits_uop_sqIdx_value),
    .io_in_bits_src_0(io_in_bits_src_0),
    .io_in_bits_src_1(io_in_bits_src_1),
    .io_in_bits_src_2(io_in_bits_src_2),
    .io_in_bits_src_3(io_in_bits_src_3),
    .io_in_bits_src_4(io_in_bits_src_4),
    .io_csrCtrl_cache_error_enable(io_csrCtrl_cache_error_enable),
    .io_rdcache_req_ready(io_rdcache_req_ready),
    .io_rdcache_resp_valid(io_rdcache_resp_valid),
    .io_rdcache_resp_bits_data_delayed(io_rdcache_resp_bits_data_delayed),
    .io_rdcache_resp_bits_miss(io_rdcache_resp_bits_miss),
    .io_rdcache_resp_bits_error_delayed(io_rdcache_resp_bits_error_delayed),
    .io_rdcache_s2_bank_conflict(io_rdcache_s2_bank_conflict),
    .io_sbuffer_ready(io_sbuffer_ready),
    .io_dtlb_resp_valid(io_dtlb_resp_valid),
    .io_dtlb_resp_bits_paddr_0(io_dtlb_resp_bits_paddr_0),
    .io_dtlb_resp_bits_gpaddr_0(io_dtlb_resp_bits_gpaddr_0),
    .io_dtlb_resp_bits_fullva(io_dtlb_resp_bits_fullva),
    .io_dtlb_resp_bits_pbmt_0(io_dtlb_resp_bits_pbmt_0),
    .io_dtlb_resp_bits_miss(io_dtlb_resp_bits_miss),
    .io_dtlb_resp_bits_isForVSnonLeafPTE(io_dtlb_resp_bits_isForVSnonLeafPTE),
    .io_dtlb_resp_bits_excp_0_gpf_ld(io_dtlb_resp_bits_excp_0_gpf_ld),
    .io_dtlb_resp_bits_excp_0_gpf_st(io_dtlb_resp_bits_excp_0_gpf_st),
    .io_dtlb_resp_bits_excp_0_pf_ld(io_dtlb_resp_bits_excp_0_pf_ld),
    .io_dtlb_resp_bits_excp_0_pf_st(io_dtlb_resp_bits_excp_0_pf_st),
    .io_dtlb_resp_bits_excp_0_af_ld(io_dtlb_resp_bits_excp_0_af_ld),
    .io_dtlb_resp_bits_excp_0_af_st(io_dtlb_resp_bits_excp_0_af_st),
    .io_pmpResp_ld(io_pmpResp_ld),
    .io_pmpResp_st(io_pmpResp_st),
    .io_pmpResp_instr(io_pmpResp_instr),
    .io_pmpResp_mmio(io_pmpResp_mmio),
    .io_pmpResp_atomic(io_pmpResp_atomic),
    .io_flush_sbuffer_empty(io_flush_sbuffer_empty),
    .io_fromCsrTrigger_tdataVec_0_matchType(io_fromCsrTrigger_tdataVec_0_matchType),
    .io_fromCsrTrigger_tdataVec_0_select(io_fromCsrTrigger_tdataVec_0_select),
    .io_fromCsrTrigger_tdataVec_0_timing(io_fromCsrTrigger_tdataVec_0_timing),
    .io_fromCsrTrigger_tdataVec_0_action(io_fromCsrTrigger_tdataVec_0_action),
    .io_fromCsrTrigger_tdataVec_0_chain(io_fromCsrTrigger_tdataVec_0_chain),
    .io_fromCsrTrigger_tdataVec_0_store(io_fromCsrTrigger_tdataVec_0_store),
    .io_fromCsrTrigger_tdataVec_0_load(io_fromCsrTrigger_tdataVec_0_load),
    .io_fromCsrTrigger_tdataVec_0_tdata2(io_fromCsrTrigger_tdataVec_0_tdata2),
    .io_fromCsrTrigger_tdataVec_1_matchType(io_fromCsrTrigger_tdataVec_1_matchType),
    .io_fromCsrTrigger_tdataVec_1_select(io_fromCsrTrigger_tdataVec_1_select),
    .io_fromCsrTrigger_tdataVec_1_timing(io_fromCsrTrigger_tdataVec_1_timing),
    .io_fromCsrTrigger_tdataVec_1_action(io_fromCsrTrigger_tdataVec_1_action),
    .io_fromCsrTrigger_tdataVec_1_chain(io_fromCsrTrigger_tdataVec_1_chain),
    .io_fromCsrTrigger_tdataVec_1_store(io_fromCsrTrigger_tdataVec_1_store),
    .io_fromCsrTrigger_tdataVec_1_load(io_fromCsrTrigger_tdataVec_1_load),
    .io_fromCsrTrigger_tdataVec_1_tdata2(io_fromCsrTrigger_tdataVec_1_tdata2),
    .io_fromCsrTrigger_tdataVec_2_matchType(io_fromCsrTrigger_tdataVec_2_matchType),
    .io_fromCsrTrigger_tdataVec_2_select(io_fromCsrTrigger_tdataVec_2_select),
    .io_fromCsrTrigger_tdataVec_2_timing(io_fromCsrTrigger_tdataVec_2_timing),
    .io_fromCsrTrigger_tdataVec_2_action(io_fromCsrTrigger_tdataVec_2_action),
    .io_fromCsrTrigger_tdataVec_2_chain(io_fromCsrTrigger_tdataVec_2_chain),
    .io_fromCsrTrigger_tdataVec_2_store(io_fromCsrTrigger_tdataVec_2_store),
    .io_fromCsrTrigger_tdataVec_2_load(io_fromCsrTrigger_tdataVec_2_load),
    .io_fromCsrTrigger_tdataVec_2_tdata2(io_fromCsrTrigger_tdataVec_2_tdata2),
    .io_fromCsrTrigger_tdataVec_3_matchType(io_fromCsrTrigger_tdataVec_3_matchType),
    .io_fromCsrTrigger_tdataVec_3_select(io_fromCsrTrigger_tdataVec_3_select),
    .io_fromCsrTrigger_tdataVec_3_timing(io_fromCsrTrigger_tdataVec_3_timing),
    .io_fromCsrTrigger_tdataVec_3_action(io_fromCsrTrigger_tdataVec_3_action),
    .io_fromCsrTrigger_tdataVec_3_chain(io_fromCsrTrigger_tdataVec_3_chain),
    .io_fromCsrTrigger_tdataVec_3_store(io_fromCsrTrigger_tdataVec_3_store),
    .io_fromCsrTrigger_tdataVec_3_load(io_fromCsrTrigger_tdataVec_3_load),
    .io_fromCsrTrigger_tdataVec_3_tdata2(io_fromCsrTrigger_tdataVec_3_tdata2),
    .io_fromCsrTrigger_tEnableVec_0(io_fromCsrTrigger_tEnableVec_0),
    .io_fromCsrTrigger_tEnableVec_1(io_fromCsrTrigger_tEnableVec_1),
    .io_fromCsrTrigger_tEnableVec_2(io_fromCsrTrigger_tEnableVec_2),
    .io_fromCsrTrigger_tEnableVec_3(io_fromCsrTrigger_tEnableVec_3),
    .io_fromCsrTrigger_debugMode(io_fromCsrTrigger_debugMode),
    .io_fromCsrTrigger_triggerCanRaiseBpExp(io_fromCsrTrigger_triggerCanRaiseBpExp),
    .io_uopwriteback_valid(i_io_uopwriteback_valid),
    .io_uopwriteback_bits_uop_exceptionVec_3(i_io_uopwriteback_bits_uop_exceptionVec_3),
    .io_uopwriteback_bits_uop_exceptionVec_5(i_io_uopwriteback_bits_uop_exceptionVec_5),
    .io_uopwriteback_bits_uop_exceptionVec_7(i_io_uopwriteback_bits_uop_exceptionVec_7),
    .io_uopwriteback_bits_uop_exceptionVec_13(i_io_uopwriteback_bits_uop_exceptionVec_13),
    .io_uopwriteback_bits_uop_exceptionVec_15(i_io_uopwriteback_bits_uop_exceptionVec_15),
    .io_uopwriteback_bits_uop_exceptionVec_19(i_io_uopwriteback_bits_uop_exceptionVec_19),
    .io_uopwriteback_bits_uop_exceptionVec_21(i_io_uopwriteback_bits_uop_exceptionVec_21),
    .io_uopwriteback_bits_uop_exceptionVec_23(i_io_uopwriteback_bits_uop_exceptionVec_23),
    .io_uopwriteback_bits_uop_trigger(i_io_uopwriteback_bits_uop_trigger),
    .io_uopwriteback_bits_uop_fuOpType(i_io_uopwriteback_bits_uop_fuOpType),
    .io_uopwriteback_bits_uop_vecWen(i_io_uopwriteback_bits_uop_vecWen),
    .io_uopwriteback_bits_uop_v0Wen(i_io_uopwriteback_bits_uop_v0Wen),
    .io_uopwriteback_bits_uop_vlWen(i_io_uopwriteback_bits_uop_vlWen),
    .io_uopwriteback_bits_uop_vpu_vma(i_io_uopwriteback_bits_uop_vpu_vma),
    .io_uopwriteback_bits_uop_vpu_vta(i_io_uopwriteback_bits_uop_vpu_vta),
    .io_uopwriteback_bits_uop_vpu_vsew(i_io_uopwriteback_bits_uop_vpu_vsew),
    .io_uopwriteback_bits_uop_vpu_vlmul(i_io_uopwriteback_bits_uop_vpu_vlmul),
    .io_uopwriteback_bits_uop_vpu_vm(i_io_uopwriteback_bits_uop_vpu_vm),
    .io_uopwriteback_bits_uop_vpu_vstart(i_io_uopwriteback_bits_uop_vpu_vstart),
    .io_uopwriteback_bits_uop_vpu_vuopIdx(i_io_uopwriteback_bits_uop_vpu_vuopIdx),
    .io_uopwriteback_bits_uop_vpu_vmask(i_io_uopwriteback_bits_uop_vpu_vmask),
    .io_uopwriteback_bits_uop_vpu_vl(i_io_uopwriteback_bits_uop_vpu_vl),
    .io_uopwriteback_bits_uop_vpu_nf(i_io_uopwriteback_bits_uop_vpu_nf),
    .io_uopwriteback_bits_uop_vpu_veew(i_io_uopwriteback_bits_uop_vpu_veew),
    .io_uopwriteback_bits_uop_pdest(i_io_uopwriteback_bits_uop_pdest),
    .io_uopwriteback_bits_uop_robIdx_flag(i_io_uopwriteback_bits_uop_robIdx_flag),
    .io_uopwriteback_bits_uop_robIdx_value(i_io_uopwriteback_bits_uop_robIdx_value),
    .io_uopwriteback_bits_uop_debugInfo_enqRsTime(i_io_uopwriteback_bits_uop_debugInfo_enqRsTime),
    .io_uopwriteback_bits_uop_debugInfo_selectTime(i_io_uopwriteback_bits_uop_debugInfo_selectTime),
    .io_uopwriteback_bits_uop_debugInfo_issueTime(i_io_uopwriteback_bits_uop_debugInfo_issueTime),
    .io_uopwriteback_bits_data(i_io_uopwriteback_bits_data),
    .io_uopwriteback_bits_vdIdx(i_io_uopwriteback_bits_vdIdx),
    .io_uopwriteback_bits_vdIdxInField(i_io_uopwriteback_bits_vdIdxInField),
    .io_uopwriteback_bits_debug_isMMIO(i_io_uopwriteback_bits_debug_isMMIO),
    .io_uopwriteback_bits_debug_isNCIO(i_io_uopwriteback_bits_debug_isNCIO),
    .io_uopwriteback_bits_debug_isPerfCnt(i_io_uopwriteback_bits_debug_isPerfCnt),
    .io_rdcache_req_valid(i_io_rdcache_req_valid),
    .io_rdcache_req_bits_vaddr(i_io_rdcache_req_bits_vaddr),
    .io_rdcache_req_bits_vaddr_dup(i_io_rdcache_req_bits_vaddr_dup),
    .io_rdcache_is128Req(i_io_rdcache_is128Req),
    .io_rdcache_s1_paddr_dup_lsu(i_io_rdcache_s1_paddr_dup_lsu),
    .io_rdcache_s1_paddr_dup_dcache(i_io_rdcache_s1_paddr_dup_dcache),
    .io_sbuffer_valid(i_io_sbuffer_valid),
    .io_sbuffer_bits_vaddr(i_io_sbuffer_bits_vaddr),
    .io_sbuffer_bits_data(i_io_sbuffer_bits_data),
    .io_sbuffer_bits_mask(i_io_sbuffer_bits_mask),
    .io_sbuffer_bits_addr(i_io_sbuffer_bits_addr),
    .io_sbuffer_bits_vecValid(i_io_sbuffer_bits_vecValid),
    .io_dtlb_req_valid(i_io_dtlb_req_valid),
    .io_dtlb_req_bits_vaddr(i_io_dtlb_req_bits_vaddr),
    .io_dtlb_req_bits_fullva(i_io_dtlb_req_bits_fullva),
    .io_dtlb_req_bits_cmd(i_io_dtlb_req_bits_cmd),
    .io_dtlb_req_bits_debug_robIdx_flag(i_io_dtlb_req_bits_debug_robIdx_flag),
    .io_dtlb_req_bits_debug_robIdx_value(i_io_dtlb_req_bits_debug_robIdx_value),
    .io_flush_sbuffer_valid(i_io_flush_sbuffer_valid),
    .io_feedback_valid(i_io_feedback_valid),
    .io_feedback_bits_sqIdx_flag(i_io_feedback_bits_sqIdx_flag),
    .io_feedback_bits_sqIdx_value(i_io_feedback_bits_sqIdx_value),
    .io_feedback_bits_lqIdx_flag(i_io_feedback_bits_lqIdx_flag),
    .io_feedback_bits_lqIdx_value(i_io_feedback_bits_lqIdx_value),
    .io_exceptionInfo_valid(i_io_exceptionInfo_valid),
    .io_exceptionInfo_bits_vaddr(i_io_exceptionInfo_bits_vaddr),
    .io_exceptionInfo_bits_gpaddr(i_io_exceptionInfo_bits_gpaddr),
    .io_exceptionInfo_bits_isForVSnonLeafPTE(i_io_exceptionInfo_bits_isForVSnonLeafPTE)
  );

  initial begin
    rst = 1;
    io_in_valid = 0;
    io_in_bits_uop_fuType = 0;
    io_in_bits_uop_fuOpType = 0;
    io_in_bits_uop_vecWen = 0;
    io_in_bits_uop_v0Wen = 0;
    io_in_bits_uop_vlWen = 0;
    io_in_bits_uop_vpu_vma = 0;
    io_in_bits_uop_vpu_vta = 0;
    io_in_bits_uop_vpu_vsew = 0;
    io_in_bits_uop_vpu_vlmul = 0;
    io_in_bits_uop_vpu_vm = 0;
    io_in_bits_uop_vpu_vstart = 0;
    io_in_bits_uop_vpu_vuopIdx = 0;
    io_in_bits_uop_vpu_lastUop = 0;
    io_in_bits_uop_vpu_nf = 0;
    io_in_bits_uop_vpu_veew = 0;
    io_in_bits_uop_pdest = 0;
    io_in_bits_uop_robIdx_flag = 0;
    io_in_bits_uop_robIdx_value = 0;
    io_in_bits_uop_debugInfo_enqRsTime = 0;
    io_in_bits_uop_debugInfo_selectTime = 0;
    io_in_bits_uop_debugInfo_issueTime = 0;
    io_in_bits_uop_lqIdx_flag = 0;
    io_in_bits_uop_lqIdx_value = 0;
    io_in_bits_uop_sqIdx_flag = 0;
    io_in_bits_uop_sqIdx_value = 0;
    io_in_bits_src_0 = 0;
    io_in_bits_src_1 = 0;
    io_in_bits_src_2 = 0;
    io_in_bits_src_3 = 0;
    io_in_bits_src_4 = 0;
    io_csrCtrl_cache_error_enable = 0;
    io_rdcache_req_ready = 0;
    io_rdcache_resp_valid = 0;
    io_rdcache_resp_bits_data_delayed = 0;
    io_rdcache_resp_bits_miss = 0;
    io_rdcache_resp_bits_error_delayed = 0;
    io_rdcache_s2_bank_conflict = 0;
    io_sbuffer_ready = 0;
    io_dtlb_resp_valid = 0;
    io_dtlb_resp_bits_paddr_0 = 0;
    io_dtlb_resp_bits_gpaddr_0 = 0;
    io_dtlb_resp_bits_fullva = 0;
    io_dtlb_resp_bits_pbmt_0 = 0;
    io_dtlb_resp_bits_miss = 0;
    io_dtlb_resp_bits_isForVSnonLeafPTE = 0;
    io_dtlb_resp_bits_excp_0_gpf_ld = 0;
    io_dtlb_resp_bits_excp_0_gpf_st = 0;
    io_dtlb_resp_bits_excp_0_pf_ld = 0;
    io_dtlb_resp_bits_excp_0_pf_st = 0;
    io_dtlb_resp_bits_excp_0_af_ld = 0;
    io_dtlb_resp_bits_excp_0_af_st = 0;
    io_pmpResp_ld = 0;
    io_pmpResp_st = 0;
    io_pmpResp_instr = 0;
    io_pmpResp_mmio = 0;
    io_pmpResp_atomic = 0;
    io_flush_sbuffer_empty = 0;
    io_fromCsrTrigger_tdataVec_0_matchType = 0;
    io_fromCsrTrigger_tdataVec_0_select = 0;
    io_fromCsrTrigger_tdataVec_0_timing = 0;
    io_fromCsrTrigger_tdataVec_0_action = 0;
    io_fromCsrTrigger_tdataVec_0_chain = 0;
    io_fromCsrTrigger_tdataVec_0_store = 0;
    io_fromCsrTrigger_tdataVec_0_load = 0;
    io_fromCsrTrigger_tdataVec_0_tdata2 = 0;
    io_fromCsrTrigger_tdataVec_1_matchType = 0;
    io_fromCsrTrigger_tdataVec_1_select = 0;
    io_fromCsrTrigger_tdataVec_1_timing = 0;
    io_fromCsrTrigger_tdataVec_1_action = 0;
    io_fromCsrTrigger_tdataVec_1_chain = 0;
    io_fromCsrTrigger_tdataVec_1_store = 0;
    io_fromCsrTrigger_tdataVec_1_load = 0;
    io_fromCsrTrigger_tdataVec_1_tdata2 = 0;
    io_fromCsrTrigger_tdataVec_2_matchType = 0;
    io_fromCsrTrigger_tdataVec_2_select = 0;
    io_fromCsrTrigger_tdataVec_2_timing = 0;
    io_fromCsrTrigger_tdataVec_2_action = 0;
    io_fromCsrTrigger_tdataVec_2_chain = 0;
    io_fromCsrTrigger_tdataVec_2_store = 0;
    io_fromCsrTrigger_tdataVec_2_load = 0;
    io_fromCsrTrigger_tdataVec_2_tdata2 = 0;
    io_fromCsrTrigger_tdataVec_3_matchType = 0;
    io_fromCsrTrigger_tdataVec_3_select = 0;
    io_fromCsrTrigger_tdataVec_3_timing = 0;
    io_fromCsrTrigger_tdataVec_3_action = 0;
    io_fromCsrTrigger_tdataVec_3_chain = 0;
    io_fromCsrTrigger_tdataVec_3_store = 0;
    io_fromCsrTrigger_tdataVec_3_load = 0;
    io_fromCsrTrigger_tdataVec_3_tdata2 = 0;
    io_fromCsrTrigger_tEnableVec_0 = 0;
    io_fromCsrTrigger_tEnableVec_1 = 0;
    io_fromCsrTrigger_tEnableVec_2 = 0;
    io_fromCsrTrigger_tEnableVec_3 = 0;
    io_fromCsrTrigger_debugMode = 0;
    io_fromCsrTrigger_triggerCanRaiseBpExp = 0;
    repeat (WARMUP) @(posedge clk);
    rst = 0;
    for (cyc = 0; cyc < NCYCLES; cyc++) begin
      @(negedge clk);
      io_in_valid <= $random;
      io_in_bits_uop_fuType <= {$random, $random};
      io_in_bits_uop_fuOpType <= $random;
      io_in_bits_uop_vecWen <= $random;
      io_in_bits_uop_v0Wen <= $random;
      io_in_bits_uop_vlWen <= $random;
      io_in_bits_uop_vpu_vma <= $random;
      io_in_bits_uop_vpu_vta <= $random;
      io_in_bits_uop_vpu_vsew <= $random;
      io_in_bits_uop_vpu_vlmul <= $random;
      io_in_bits_uop_vpu_vm <= $random;
      io_in_bits_uop_vpu_vstart <= $random;
      io_in_bits_uop_vpu_vuopIdx <= $random;
      io_in_bits_uop_vpu_lastUop <= $random;
      io_in_bits_uop_vpu_nf <= $random;
      io_in_bits_uop_vpu_veew <= $random;
      io_in_bits_uop_pdest <= $random;
      io_in_bits_uop_robIdx_flag <= $random;
      io_in_bits_uop_robIdx_value <= $random;
      io_in_bits_uop_debugInfo_enqRsTime <= {$random, $random};
      io_in_bits_uop_debugInfo_selectTime <= {$random, $random};
      io_in_bits_uop_debugInfo_issueTime <= {$random, $random};
      io_in_bits_uop_lqIdx_flag <= $random;
      io_in_bits_uop_lqIdx_value <= $random;
      io_in_bits_uop_sqIdx_flag <= $random;
      io_in_bits_uop_sqIdx_value <= $random;
      io_in_bits_src_0 <= {$random, $random, $random, $random};
      io_in_bits_src_1 <= {$random, $random, $random, $random};
      io_in_bits_src_2 <= {$random, $random, $random, $random};
      io_in_bits_src_3 <= {$random, $random, $random, $random};
      io_in_bits_src_4 <= {$random, $random, $random, $random};
      io_csrCtrl_cache_error_enable <= $random;
      io_rdcache_req_ready <= $random;
      io_rdcache_resp_valid <= $random;
      io_rdcache_resp_bits_data_delayed <= {$random, $random, $random, $random};
      io_rdcache_resp_bits_miss <= $random;
      io_rdcache_resp_bits_error_delayed <= $random;
      io_rdcache_s2_bank_conflict <= $random;
      io_sbuffer_ready <= $random;
      io_dtlb_resp_valid <= $random;
      io_dtlb_resp_bits_paddr_0 <= {$random, $random};
      io_dtlb_resp_bits_gpaddr_0 <= {$random, $random};
      io_dtlb_resp_bits_fullva <= {$random, $random};
      io_dtlb_resp_bits_pbmt_0 <= $random;
      io_dtlb_resp_bits_miss <= $random;
      io_dtlb_resp_bits_isForVSnonLeafPTE <= $random;
      io_dtlb_resp_bits_excp_0_gpf_ld <= $random;
      io_dtlb_resp_bits_excp_0_gpf_st <= $random;
      io_dtlb_resp_bits_excp_0_pf_ld <= $random;
      io_dtlb_resp_bits_excp_0_pf_st <= $random;
      io_dtlb_resp_bits_excp_0_af_ld <= $random;
      io_dtlb_resp_bits_excp_0_af_st <= $random;
      io_pmpResp_ld <= $random;
      io_pmpResp_st <= $random;
      io_pmpResp_instr <= $random;
      io_pmpResp_mmio <= $random;
      io_pmpResp_atomic <= $random;
      io_flush_sbuffer_empty <= $random;
      io_fromCsrTrigger_tdataVec_0_matchType <= $random;
      io_fromCsrTrigger_tdataVec_0_select <= $random;
      io_fromCsrTrigger_tdataVec_0_timing <= $random;
      io_fromCsrTrigger_tdataVec_0_action <= $random;
      io_fromCsrTrigger_tdataVec_0_chain <= $random;
      io_fromCsrTrigger_tdataVec_0_store <= $random;
      io_fromCsrTrigger_tdataVec_0_load <= $random;
      io_fromCsrTrigger_tdataVec_0_tdata2 <= {$random, $random};
      io_fromCsrTrigger_tdataVec_1_matchType <= $random;
      io_fromCsrTrigger_tdataVec_1_select <= $random;
      io_fromCsrTrigger_tdataVec_1_timing <= $random;
      io_fromCsrTrigger_tdataVec_1_action <= $random;
      io_fromCsrTrigger_tdataVec_1_chain <= $random;
      io_fromCsrTrigger_tdataVec_1_store <= $random;
      io_fromCsrTrigger_tdataVec_1_load <= $random;
      io_fromCsrTrigger_tdataVec_1_tdata2 <= {$random, $random};
      io_fromCsrTrigger_tdataVec_2_matchType <= $random;
      io_fromCsrTrigger_tdataVec_2_select <= $random;
      io_fromCsrTrigger_tdataVec_2_timing <= $random;
      io_fromCsrTrigger_tdataVec_2_action <= $random;
      io_fromCsrTrigger_tdataVec_2_chain <= $random;
      io_fromCsrTrigger_tdataVec_2_store <= $random;
      io_fromCsrTrigger_tdataVec_2_load <= $random;
      io_fromCsrTrigger_tdataVec_2_tdata2 <= {$random, $random};
      io_fromCsrTrigger_tdataVec_3_matchType <= $random;
      io_fromCsrTrigger_tdataVec_3_select <= $random;
      io_fromCsrTrigger_tdataVec_3_timing <= $random;
      io_fromCsrTrigger_tdataVec_3_action <= $random;
      io_fromCsrTrigger_tdataVec_3_chain <= $random;
      io_fromCsrTrigger_tdataVec_3_store <= $random;
      io_fromCsrTrigger_tdataVec_3_load <= $random;
      io_fromCsrTrigger_tdataVec_3_tdata2 <= {$random, $random};
      io_fromCsrTrigger_tEnableVec_0 <= $random;
      io_fromCsrTrigger_tEnableVec_1 <= $random;
      io_fromCsrTrigger_tEnableVec_2 <= $random;
      io_fromCsrTrigger_tEnableVec_3 <= $random;
      io_fromCsrTrigger_debugMode <= $random;
      io_fromCsrTrigger_triggerCanRaiseBpExp <= $random;
      @(posedge clk);
      #1;
      if (cyc > 2) begin
        checks++;
      if (g_io_uopwriteback_valid !== i_io_uopwriteback_valid) begin errors++; if (errors<20) $display("MISMATCH io_uopwriteback_valid @%0d g=%h i=%h", cyc, g_io_uopwriteback_valid, i_io_uopwriteback_valid); end
      if (g_io_uopwriteback_bits_uop_exceptionVec_3 !== i_io_uopwriteback_bits_uop_exceptionVec_3) begin errors++; if (errors<20) $display("MISMATCH io_uopwriteback_bits_uop_exceptionVec_3 @%0d g=%h i=%h", cyc, g_io_uopwriteback_bits_uop_exceptionVec_3, i_io_uopwriteback_bits_uop_exceptionVec_3); end
      if (g_io_uopwriteback_bits_uop_exceptionVec_5 !== i_io_uopwriteback_bits_uop_exceptionVec_5) begin errors++; if (errors<20) $display("MISMATCH io_uopwriteback_bits_uop_exceptionVec_5 @%0d g=%h i=%h", cyc, g_io_uopwriteback_bits_uop_exceptionVec_5, i_io_uopwriteback_bits_uop_exceptionVec_5); end
      if (g_io_uopwriteback_bits_uop_exceptionVec_7 !== i_io_uopwriteback_bits_uop_exceptionVec_7) begin errors++; if (errors<20) $display("MISMATCH io_uopwriteback_bits_uop_exceptionVec_7 @%0d g=%h i=%h", cyc, g_io_uopwriteback_bits_uop_exceptionVec_7, i_io_uopwriteback_bits_uop_exceptionVec_7); end
      if (g_io_uopwriteback_bits_uop_exceptionVec_13 !== i_io_uopwriteback_bits_uop_exceptionVec_13) begin errors++; if (errors<20) $display("MISMATCH io_uopwriteback_bits_uop_exceptionVec_13 @%0d g=%h i=%h", cyc, g_io_uopwriteback_bits_uop_exceptionVec_13, i_io_uopwriteback_bits_uop_exceptionVec_13); end
      if (g_io_uopwriteback_bits_uop_exceptionVec_15 !== i_io_uopwriteback_bits_uop_exceptionVec_15) begin errors++; if (errors<20) $display("MISMATCH io_uopwriteback_bits_uop_exceptionVec_15 @%0d g=%h i=%h", cyc, g_io_uopwriteback_bits_uop_exceptionVec_15, i_io_uopwriteback_bits_uop_exceptionVec_15); end
      if (g_io_uopwriteback_bits_uop_exceptionVec_19 !== i_io_uopwriteback_bits_uop_exceptionVec_19) begin errors++; if (errors<20) $display("MISMATCH io_uopwriteback_bits_uop_exceptionVec_19 @%0d g=%h i=%h", cyc, g_io_uopwriteback_bits_uop_exceptionVec_19, i_io_uopwriteback_bits_uop_exceptionVec_19); end
      if (g_io_uopwriteback_bits_uop_exceptionVec_21 !== i_io_uopwriteback_bits_uop_exceptionVec_21) begin errors++; if (errors<20) $display("MISMATCH io_uopwriteback_bits_uop_exceptionVec_21 @%0d g=%h i=%h", cyc, g_io_uopwriteback_bits_uop_exceptionVec_21, i_io_uopwriteback_bits_uop_exceptionVec_21); end
      if (g_io_uopwriteback_bits_uop_exceptionVec_23 !== i_io_uopwriteback_bits_uop_exceptionVec_23) begin errors++; if (errors<20) $display("MISMATCH io_uopwriteback_bits_uop_exceptionVec_23 @%0d g=%h i=%h", cyc, g_io_uopwriteback_bits_uop_exceptionVec_23, i_io_uopwriteback_bits_uop_exceptionVec_23); end
      if (g_io_uopwriteback_bits_uop_trigger !== i_io_uopwriteback_bits_uop_trigger) begin errors++; if (errors<20) $display("MISMATCH io_uopwriteback_bits_uop_trigger @%0d g=%h i=%h", cyc, g_io_uopwriteback_bits_uop_trigger, i_io_uopwriteback_bits_uop_trigger); end
      if (g_io_uopwriteback_bits_uop_fuOpType !== i_io_uopwriteback_bits_uop_fuOpType) begin errors++; if (errors<20) $display("MISMATCH io_uopwriteback_bits_uop_fuOpType @%0d g=%h i=%h", cyc, g_io_uopwriteback_bits_uop_fuOpType, i_io_uopwriteback_bits_uop_fuOpType); end
      if (g_io_uopwriteback_bits_uop_vecWen !== i_io_uopwriteback_bits_uop_vecWen) begin errors++; if (errors<20) $display("MISMATCH io_uopwriteback_bits_uop_vecWen @%0d g=%h i=%h", cyc, g_io_uopwriteback_bits_uop_vecWen, i_io_uopwriteback_bits_uop_vecWen); end
      if (g_io_uopwriteback_bits_uop_v0Wen !== i_io_uopwriteback_bits_uop_v0Wen) begin errors++; if (errors<20) $display("MISMATCH io_uopwriteback_bits_uop_v0Wen @%0d g=%h i=%h", cyc, g_io_uopwriteback_bits_uop_v0Wen, i_io_uopwriteback_bits_uop_v0Wen); end
      if (g_io_uopwriteback_bits_uop_vlWen !== i_io_uopwriteback_bits_uop_vlWen) begin errors++; if (errors<20) $display("MISMATCH io_uopwriteback_bits_uop_vlWen @%0d g=%h i=%h", cyc, g_io_uopwriteback_bits_uop_vlWen, i_io_uopwriteback_bits_uop_vlWen); end
      if (g_io_uopwriteback_bits_uop_vpu_vma !== i_io_uopwriteback_bits_uop_vpu_vma) begin errors++; if (errors<20) $display("MISMATCH io_uopwriteback_bits_uop_vpu_vma @%0d g=%h i=%h", cyc, g_io_uopwriteback_bits_uop_vpu_vma, i_io_uopwriteback_bits_uop_vpu_vma); end
      if (g_io_uopwriteback_bits_uop_vpu_vta !== i_io_uopwriteback_bits_uop_vpu_vta) begin errors++; if (errors<20) $display("MISMATCH io_uopwriteback_bits_uop_vpu_vta @%0d g=%h i=%h", cyc, g_io_uopwriteback_bits_uop_vpu_vta, i_io_uopwriteback_bits_uop_vpu_vta); end
      if (g_io_uopwriteback_bits_uop_vpu_vsew !== i_io_uopwriteback_bits_uop_vpu_vsew) begin errors++; if (errors<20) $display("MISMATCH io_uopwriteback_bits_uop_vpu_vsew @%0d g=%h i=%h", cyc, g_io_uopwriteback_bits_uop_vpu_vsew, i_io_uopwriteback_bits_uop_vpu_vsew); end
      if (g_io_uopwriteback_bits_uop_vpu_vlmul !== i_io_uopwriteback_bits_uop_vpu_vlmul) begin errors++; if (errors<20) $display("MISMATCH io_uopwriteback_bits_uop_vpu_vlmul @%0d g=%h i=%h", cyc, g_io_uopwriteback_bits_uop_vpu_vlmul, i_io_uopwriteback_bits_uop_vpu_vlmul); end
      if (g_io_uopwriteback_bits_uop_vpu_vm !== i_io_uopwriteback_bits_uop_vpu_vm) begin errors++; if (errors<20) $display("MISMATCH io_uopwriteback_bits_uop_vpu_vm @%0d g=%h i=%h", cyc, g_io_uopwriteback_bits_uop_vpu_vm, i_io_uopwriteback_bits_uop_vpu_vm); end
      if (g_io_uopwriteback_bits_uop_vpu_vstart !== i_io_uopwriteback_bits_uop_vpu_vstart) begin errors++; if (errors<20) $display("MISMATCH io_uopwriteback_bits_uop_vpu_vstart @%0d g=%h i=%h", cyc, g_io_uopwriteback_bits_uop_vpu_vstart, i_io_uopwriteback_bits_uop_vpu_vstart); end
      if (g_io_uopwriteback_bits_uop_vpu_vuopIdx !== i_io_uopwriteback_bits_uop_vpu_vuopIdx) begin errors++; if (errors<20) $display("MISMATCH io_uopwriteback_bits_uop_vpu_vuopIdx @%0d g=%h i=%h", cyc, g_io_uopwriteback_bits_uop_vpu_vuopIdx, i_io_uopwriteback_bits_uop_vpu_vuopIdx); end
      if (g_io_uopwriteback_bits_uop_vpu_vmask !== i_io_uopwriteback_bits_uop_vpu_vmask) begin errors++; if (errors<20) $display("MISMATCH io_uopwriteback_bits_uop_vpu_vmask @%0d g=%h i=%h", cyc, g_io_uopwriteback_bits_uop_vpu_vmask, i_io_uopwriteback_bits_uop_vpu_vmask); end
      if (g_io_uopwriteback_bits_uop_vpu_vl !== i_io_uopwriteback_bits_uop_vpu_vl) begin errors++; if (errors<20) $display("MISMATCH io_uopwriteback_bits_uop_vpu_vl @%0d g=%h i=%h", cyc, g_io_uopwriteback_bits_uop_vpu_vl, i_io_uopwriteback_bits_uop_vpu_vl); end
      if (g_io_uopwriteback_bits_uop_vpu_nf !== i_io_uopwriteback_bits_uop_vpu_nf) begin errors++; if (errors<20) $display("MISMATCH io_uopwriteback_bits_uop_vpu_nf @%0d g=%h i=%h", cyc, g_io_uopwriteback_bits_uop_vpu_nf, i_io_uopwriteback_bits_uop_vpu_nf); end
      if (g_io_uopwriteback_bits_uop_vpu_veew !== i_io_uopwriteback_bits_uop_vpu_veew) begin errors++; if (errors<20) $display("MISMATCH io_uopwriteback_bits_uop_vpu_veew @%0d g=%h i=%h", cyc, g_io_uopwriteback_bits_uop_vpu_veew, i_io_uopwriteback_bits_uop_vpu_veew); end
      if (g_io_uopwriteback_bits_uop_pdest !== i_io_uopwriteback_bits_uop_pdest) begin errors++; if (errors<20) $display("MISMATCH io_uopwriteback_bits_uop_pdest @%0d g=%h i=%h", cyc, g_io_uopwriteback_bits_uop_pdest, i_io_uopwriteback_bits_uop_pdest); end
      if (g_io_uopwriteback_bits_uop_robIdx_flag !== i_io_uopwriteback_bits_uop_robIdx_flag) begin errors++; if (errors<20) $display("MISMATCH io_uopwriteback_bits_uop_robIdx_flag @%0d g=%h i=%h", cyc, g_io_uopwriteback_bits_uop_robIdx_flag, i_io_uopwriteback_bits_uop_robIdx_flag); end
      if (g_io_uopwriteback_bits_uop_robIdx_value !== i_io_uopwriteback_bits_uop_robIdx_value) begin errors++; if (errors<20) $display("MISMATCH io_uopwriteback_bits_uop_robIdx_value @%0d g=%h i=%h", cyc, g_io_uopwriteback_bits_uop_robIdx_value, i_io_uopwriteback_bits_uop_robIdx_value); end
      if (g_io_uopwriteback_bits_uop_debugInfo_enqRsTime !== i_io_uopwriteback_bits_uop_debugInfo_enqRsTime) begin errors++; if (errors<20) $display("MISMATCH io_uopwriteback_bits_uop_debugInfo_enqRsTime @%0d g=%h i=%h", cyc, g_io_uopwriteback_bits_uop_debugInfo_enqRsTime, i_io_uopwriteback_bits_uop_debugInfo_enqRsTime); end
      if (g_io_uopwriteback_bits_uop_debugInfo_selectTime !== i_io_uopwriteback_bits_uop_debugInfo_selectTime) begin errors++; if (errors<20) $display("MISMATCH io_uopwriteback_bits_uop_debugInfo_selectTime @%0d g=%h i=%h", cyc, g_io_uopwriteback_bits_uop_debugInfo_selectTime, i_io_uopwriteback_bits_uop_debugInfo_selectTime); end
      if (g_io_uopwriteback_bits_uop_debugInfo_issueTime !== i_io_uopwriteback_bits_uop_debugInfo_issueTime) begin errors++; if (errors<20) $display("MISMATCH io_uopwriteback_bits_uop_debugInfo_issueTime @%0d g=%h i=%h", cyc, g_io_uopwriteback_bits_uop_debugInfo_issueTime, i_io_uopwriteback_bits_uop_debugInfo_issueTime); end
      if (g_io_uopwriteback_bits_data !== i_io_uopwriteback_bits_data) begin errors++; if (errors<20) $display("MISMATCH io_uopwriteback_bits_data @%0d g=%h i=%h", cyc, g_io_uopwriteback_bits_data, i_io_uopwriteback_bits_data); end
      if (g_io_uopwriteback_bits_vdIdx !== i_io_uopwriteback_bits_vdIdx) begin errors++; if (errors<20) $display("MISMATCH io_uopwriteback_bits_vdIdx @%0d g=%h i=%h", cyc, g_io_uopwriteback_bits_vdIdx, i_io_uopwriteback_bits_vdIdx); end
      if (g_io_uopwriteback_bits_vdIdxInField !== i_io_uopwriteback_bits_vdIdxInField) begin errors++; if (errors<20) $display("MISMATCH io_uopwriteback_bits_vdIdxInField @%0d g=%h i=%h", cyc, g_io_uopwriteback_bits_vdIdxInField, i_io_uopwriteback_bits_vdIdxInField); end
      if (g_io_uopwriteback_bits_debug_isMMIO !== i_io_uopwriteback_bits_debug_isMMIO) begin errors++; if (errors<20) $display("MISMATCH io_uopwriteback_bits_debug_isMMIO @%0d g=%h i=%h", cyc, g_io_uopwriteback_bits_debug_isMMIO, i_io_uopwriteback_bits_debug_isMMIO); end
      if (g_io_uopwriteback_bits_debug_isNCIO !== i_io_uopwriteback_bits_debug_isNCIO) begin errors++; if (errors<20) $display("MISMATCH io_uopwriteback_bits_debug_isNCIO @%0d g=%h i=%h", cyc, g_io_uopwriteback_bits_debug_isNCIO, i_io_uopwriteback_bits_debug_isNCIO); end
      if (g_io_uopwriteback_bits_debug_isPerfCnt !== i_io_uopwriteback_bits_debug_isPerfCnt) begin errors++; if (errors<20) $display("MISMATCH io_uopwriteback_bits_debug_isPerfCnt @%0d g=%h i=%h", cyc, g_io_uopwriteback_bits_debug_isPerfCnt, i_io_uopwriteback_bits_debug_isPerfCnt); end
      if (g_io_rdcache_req_valid !== i_io_rdcache_req_valid) begin errors++; if (errors<20) $display("MISMATCH io_rdcache_req_valid @%0d g=%h i=%h", cyc, g_io_rdcache_req_valid, i_io_rdcache_req_valid); end
      if (g_io_rdcache_req_bits_vaddr !== i_io_rdcache_req_bits_vaddr) begin errors++; if (errors<20) $display("MISMATCH io_rdcache_req_bits_vaddr @%0d g=%h i=%h", cyc, g_io_rdcache_req_bits_vaddr, i_io_rdcache_req_bits_vaddr); end
      if (g_io_rdcache_req_bits_vaddr_dup !== i_io_rdcache_req_bits_vaddr_dup) begin errors++; if (errors<20) $display("MISMATCH io_rdcache_req_bits_vaddr_dup @%0d g=%h i=%h", cyc, g_io_rdcache_req_bits_vaddr_dup, i_io_rdcache_req_bits_vaddr_dup); end
      if (g_io_rdcache_is128Req !== i_io_rdcache_is128Req) begin errors++; if (errors<20) $display("MISMATCH io_rdcache_is128Req @%0d g=%h i=%h", cyc, g_io_rdcache_is128Req, i_io_rdcache_is128Req); end
      if (g_io_rdcache_s1_paddr_dup_lsu !== i_io_rdcache_s1_paddr_dup_lsu) begin errors++; if (errors<20) $display("MISMATCH io_rdcache_s1_paddr_dup_lsu @%0d g=%h i=%h", cyc, g_io_rdcache_s1_paddr_dup_lsu, i_io_rdcache_s1_paddr_dup_lsu); end
      if (g_io_rdcache_s1_paddr_dup_dcache !== i_io_rdcache_s1_paddr_dup_dcache) begin errors++; if (errors<20) $display("MISMATCH io_rdcache_s1_paddr_dup_dcache @%0d g=%h i=%h", cyc, g_io_rdcache_s1_paddr_dup_dcache, i_io_rdcache_s1_paddr_dup_dcache); end
      if (g_io_sbuffer_valid !== i_io_sbuffer_valid) begin errors++; if (errors<20) $display("MISMATCH io_sbuffer_valid @%0d g=%h i=%h", cyc, g_io_sbuffer_valid, i_io_sbuffer_valid); end
      if (g_io_sbuffer_bits_vaddr !== i_io_sbuffer_bits_vaddr) begin errors++; if (errors<20) $display("MISMATCH io_sbuffer_bits_vaddr @%0d g=%h i=%h", cyc, g_io_sbuffer_bits_vaddr, i_io_sbuffer_bits_vaddr); end
      if (g_io_sbuffer_bits_data !== i_io_sbuffer_bits_data) begin errors++; if (errors<20) $display("MISMATCH io_sbuffer_bits_data @%0d g=%h i=%h", cyc, g_io_sbuffer_bits_data, i_io_sbuffer_bits_data); end
      if (g_io_sbuffer_bits_mask !== i_io_sbuffer_bits_mask) begin errors++; if (errors<20) $display("MISMATCH io_sbuffer_bits_mask @%0d g=%h i=%h", cyc, g_io_sbuffer_bits_mask, i_io_sbuffer_bits_mask); end
      if (g_io_sbuffer_bits_addr !== i_io_sbuffer_bits_addr) begin errors++; if (errors<20) $display("MISMATCH io_sbuffer_bits_addr @%0d g=%h i=%h", cyc, g_io_sbuffer_bits_addr, i_io_sbuffer_bits_addr); end
      if (g_io_sbuffer_bits_vecValid !== i_io_sbuffer_bits_vecValid) begin errors++; if (errors<20) $display("MISMATCH io_sbuffer_bits_vecValid @%0d g=%h i=%h", cyc, g_io_sbuffer_bits_vecValid, i_io_sbuffer_bits_vecValid); end
      if (g_io_dtlb_req_valid !== i_io_dtlb_req_valid) begin errors++; if (errors<20) $display("MISMATCH io_dtlb_req_valid @%0d g=%h i=%h", cyc, g_io_dtlb_req_valid, i_io_dtlb_req_valid); end
      if (g_io_dtlb_req_bits_vaddr !== i_io_dtlb_req_bits_vaddr) begin errors++; if (errors<20) $display("MISMATCH io_dtlb_req_bits_vaddr @%0d g=%h i=%h", cyc, g_io_dtlb_req_bits_vaddr, i_io_dtlb_req_bits_vaddr); end
      if (g_io_dtlb_req_bits_fullva !== i_io_dtlb_req_bits_fullva) begin errors++; if (errors<20) $display("MISMATCH io_dtlb_req_bits_fullva @%0d g=%h i=%h", cyc, g_io_dtlb_req_bits_fullva, i_io_dtlb_req_bits_fullva); end
      if (g_io_dtlb_req_bits_cmd !== i_io_dtlb_req_bits_cmd) begin errors++; if (errors<20) $display("MISMATCH io_dtlb_req_bits_cmd @%0d g=%h i=%h", cyc, g_io_dtlb_req_bits_cmd, i_io_dtlb_req_bits_cmd); end
      if (g_io_dtlb_req_bits_debug_robIdx_flag !== i_io_dtlb_req_bits_debug_robIdx_flag) begin errors++; if (errors<20) $display("MISMATCH io_dtlb_req_bits_debug_robIdx_flag @%0d g=%h i=%h", cyc, g_io_dtlb_req_bits_debug_robIdx_flag, i_io_dtlb_req_bits_debug_robIdx_flag); end
      if (g_io_dtlb_req_bits_debug_robIdx_value !== i_io_dtlb_req_bits_debug_robIdx_value) begin errors++; if (errors<20) $display("MISMATCH io_dtlb_req_bits_debug_robIdx_value @%0d g=%h i=%h", cyc, g_io_dtlb_req_bits_debug_robIdx_value, i_io_dtlb_req_bits_debug_robIdx_value); end
      if (g_io_flush_sbuffer_valid !== i_io_flush_sbuffer_valid) begin errors++; if (errors<20) $display("MISMATCH io_flush_sbuffer_valid @%0d g=%h i=%h", cyc, g_io_flush_sbuffer_valid, i_io_flush_sbuffer_valid); end
      if (g_io_feedback_valid !== i_io_feedback_valid) begin errors++; if (errors<20) $display("MISMATCH io_feedback_valid @%0d g=%h i=%h", cyc, g_io_feedback_valid, i_io_feedback_valid); end
      if (g_io_feedback_bits_sqIdx_flag !== i_io_feedback_bits_sqIdx_flag) begin errors++; if (errors<20) $display("MISMATCH io_feedback_bits_sqIdx_flag @%0d g=%h i=%h", cyc, g_io_feedback_bits_sqIdx_flag, i_io_feedback_bits_sqIdx_flag); end
      if (g_io_feedback_bits_sqIdx_value !== i_io_feedback_bits_sqIdx_value) begin errors++; if (errors<20) $display("MISMATCH io_feedback_bits_sqIdx_value @%0d g=%h i=%h", cyc, g_io_feedback_bits_sqIdx_value, i_io_feedback_bits_sqIdx_value); end
      if (g_io_feedback_bits_lqIdx_flag !== i_io_feedback_bits_lqIdx_flag) begin errors++; if (errors<20) $display("MISMATCH io_feedback_bits_lqIdx_flag @%0d g=%h i=%h", cyc, g_io_feedback_bits_lqIdx_flag, i_io_feedback_bits_lqIdx_flag); end
      if (g_io_feedback_bits_lqIdx_value !== i_io_feedback_bits_lqIdx_value) begin errors++; if (errors<20) $display("MISMATCH io_feedback_bits_lqIdx_value @%0d g=%h i=%h", cyc, g_io_feedback_bits_lqIdx_value, i_io_feedback_bits_lqIdx_value); end
      if (g_io_exceptionInfo_valid !== i_io_exceptionInfo_valid) begin errors++; if (errors<20) $display("MISMATCH io_exceptionInfo_valid @%0d g=%h i=%h", cyc, g_io_exceptionInfo_valid, i_io_exceptionInfo_valid); end
      if (g_io_exceptionInfo_bits_vaddr !== i_io_exceptionInfo_bits_vaddr) begin errors++; if (errors<20) $display("MISMATCH io_exceptionInfo_bits_vaddr @%0d g=%h i=%h", cyc, g_io_exceptionInfo_bits_vaddr, i_io_exceptionInfo_bits_vaddr); end
      if (g_io_exceptionInfo_bits_gpaddr !== i_io_exceptionInfo_bits_gpaddr) begin errors++; if (errors<20) $display("MISMATCH io_exceptionInfo_bits_gpaddr @%0d g=%h i=%h", cyc, g_io_exceptionInfo_bits_gpaddr, i_io_exceptionInfo_bits_gpaddr); end
      if (g_io_exceptionInfo_bits_isForVSnonLeafPTE !== i_io_exceptionInfo_bits_isForVSnonLeafPTE) begin errors++; if (errors<20) $display("MISMATCH io_exceptionInfo_bits_isForVSnonLeafPTE @%0d g=%h i=%h", cyc, g_io_exceptionInfo_bits_isForVSnonLeafPTE, i_io_exceptionInfo_bits_isForVSnonLeafPTE); end
      end
    end
    if (errors == 0) $display("TEST PASSED checks=%0d errors=0", checks);
    else             $display("TEST FAILED checks=%0d errors=%0d", checks, errors);
    $finish;
  end
endmodule
