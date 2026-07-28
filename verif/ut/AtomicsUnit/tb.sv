// 自动生成: gen_tb.py —— 勿手改
`timescale 1ns/1ps
module tb;
  int unsigned NCYCLES = 200000;
  int unsigned WARMUP  = 8;
  bit clk = 0, rst;
  int errors = 0, checks = 0, cyc = 0;
  always #5 clk = ~clk;

  logic [5:0] io_hartId;
  logic io_in_valid;
  logic [8:0] io_in_bits_uop_fuOpType;
  logic io_in_bits_uop_rfWen;
  logic [7:0] io_in_bits_uop_pdest;
  logic io_in_bits_uop_robIdx_flag;
  logic [7:0] io_in_bits_uop_robIdx_value;
  logic [63:0] io_in_bits_uop_debugInfo_enqRsTime;
  logic [63:0] io_in_bits_uop_debugInfo_selectTime;
  logic [63:0] io_in_bits_uop_debugInfo_issueTime;
  logic io_in_bits_uop_sqIdx_flag;
  logic [5:0] io_in_bits_uop_sqIdx_value;
  logic [63:0] io_in_bits_src_0;
  logic io_storeDataIn_0_valid;
  logic [8:0] io_storeDataIn_0_bits_uop_fuOpType;
  logic [63:0] io_storeDataIn_0_bits_data;
  logic io_storeDataIn_1_valid;
  logic [8:0] io_storeDataIn_1_bits_uop_fuOpType;
  logic [63:0] io_storeDataIn_1_bits_data;
  logic io_dcache_req_ready;
  logic io_dcache_resp_valid;
  logic [127:0] io_dcache_resp_bits_data;
  logic io_dcache_resp_bits_miss;
  logic io_dcache_resp_bits_replay;
  logic io_dcache_resp_bits_error;
  logic [5:0] io_dcache_resp_bits_id;
  logic io_dcache_block_lr;
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
  logic io_pmpResp_mmio;
  logic io_flush_sbuffer_empty;
  logic io_redirect_valid;
  logic io_csrCtrl_cache_error_enable;
  logic io_csrCtrl_mem_trigger_tUpdate_valid;
  logic [1:0] io_csrCtrl_mem_trigger_tUpdate_bits_addr;
  logic [1:0] io_csrCtrl_mem_trigger_tUpdate_bits_tdata_matchType;
  logic io_csrCtrl_mem_trigger_tUpdate_bits_tdata_select;
  logic [3:0] io_csrCtrl_mem_trigger_tUpdate_bits_tdata_action;
  logic io_csrCtrl_mem_trigger_tUpdate_bits_tdata_chain;
  logic io_csrCtrl_mem_trigger_tUpdate_bits_tdata_store;
  logic io_csrCtrl_mem_trigger_tUpdate_bits_tdata_load;
  logic [63:0] io_csrCtrl_mem_trigger_tUpdate_bits_tdata_tdata2;
  logic io_csrCtrl_mem_trigger_tEnableVec_0;
  logic io_csrCtrl_mem_trigger_tEnableVec_1;
  logic io_csrCtrl_mem_trigger_tEnableVec_2;
  logic io_csrCtrl_mem_trigger_tEnableVec_3;
  logic io_csrCtrl_mem_trigger_debugMode;
  logic io_csrCtrl_mem_trigger_triggerCanRaiseBpExp;
  wire g_io_in_ready;
  wire i_io_in_ready;
  wire g_io_out_valid;
  wire i_io_out_valid;
  wire g_io_out_bits_uop_exceptionVec_3;
  wire i_io_out_bits_uop_exceptionVec_3;
  wire g_io_out_bits_uop_exceptionVec_4;
  wire i_io_out_bits_uop_exceptionVec_4;
  wire g_io_out_bits_uop_exceptionVec_5;
  wire i_io_out_bits_uop_exceptionVec_5;
  wire g_io_out_bits_uop_exceptionVec_6;
  wire i_io_out_bits_uop_exceptionVec_6;
  wire g_io_out_bits_uop_exceptionVec_7;
  wire i_io_out_bits_uop_exceptionVec_7;
  wire g_io_out_bits_uop_exceptionVec_13;
  wire i_io_out_bits_uop_exceptionVec_13;
  wire g_io_out_bits_uop_exceptionVec_15;
  wire i_io_out_bits_uop_exceptionVec_15;
  wire g_io_out_bits_uop_exceptionVec_21;
  wire i_io_out_bits_uop_exceptionVec_21;
  wire g_io_out_bits_uop_exceptionVec_23;
  wire i_io_out_bits_uop_exceptionVec_23;
  wire [3:0] g_io_out_bits_uop_trigger;
  wire [3:0] i_io_out_bits_uop_trigger;
  wire g_io_out_bits_uop_rfWen;
  wire i_io_out_bits_uop_rfWen;
  wire [7:0] g_io_out_bits_uop_pdest;
  wire [7:0] i_io_out_bits_uop_pdest;
  wire g_io_out_bits_uop_robIdx_flag;
  wire i_io_out_bits_uop_robIdx_flag;
  wire [7:0] g_io_out_bits_uop_robIdx_value;
  wire [7:0] i_io_out_bits_uop_robIdx_value;
  wire [63:0] g_io_out_bits_uop_debugInfo_enqRsTime;
  wire [63:0] i_io_out_bits_uop_debugInfo_enqRsTime;
  wire [63:0] g_io_out_bits_uop_debugInfo_selectTime;
  wire [63:0] i_io_out_bits_uop_debugInfo_selectTime;
  wire [63:0] g_io_out_bits_uop_debugInfo_issueTime;
  wire [63:0] i_io_out_bits_uop_debugInfo_issueTime;
  wire [63:0] g_io_out_bits_data;
  wire [63:0] i_io_out_bits_data;
  wire g_io_out_bits_debug_isMMIO;
  wire i_io_out_bits_debug_isMMIO;
  wire g_io_dcache_req_valid;
  wire i_io_dcache_req_valid;
  wire [4:0] g_io_dcache_req_bits_cmd;
  wire [4:0] i_io_dcache_req_bits_cmd;
  wire [49:0] g_io_dcache_req_bits_vaddr;
  wire [49:0] i_io_dcache_req_bits_vaddr;
  wire [47:0] g_io_dcache_req_bits_addr;
  wire [47:0] i_io_dcache_req_bits_addr;
  wire [2:0] g_io_dcache_req_bits_word_idx;
  wire [2:0] i_io_dcache_req_bits_word_idx;
  wire [127:0] g_io_dcache_req_bits_amo_data;
  wire [127:0] i_io_dcache_req_bits_amo_data;
  wire [15:0] g_io_dcache_req_bits_amo_mask;
  wire [15:0] i_io_dcache_req_bits_amo_mask;
  wire [127:0] g_io_dcache_req_bits_amo_cmp;
  wire [127:0] i_io_dcache_req_bits_amo_cmp;
  wire g_io_dtlb_req_valid;
  wire i_io_dtlb_req_valid;
  wire [49:0] g_io_dtlb_req_bits_vaddr;
  wire [49:0] i_io_dtlb_req_bits_vaddr;
  wire [63:0] g_io_dtlb_req_bits_fullva;
  wire [63:0] i_io_dtlb_req_bits_fullva;
  wire [2:0] g_io_dtlb_req_bits_cmd;
  wire [2:0] i_io_dtlb_req_bits_cmd;
  wire g_io_dtlb_req_bits_debug_robIdx_flag;
  wire i_io_dtlb_req_bits_debug_robIdx_flag;
  wire [7:0] g_io_dtlb_req_bits_debug_robIdx_value;
  wire [7:0] i_io_dtlb_req_bits_debug_robIdx_value;
  wire g_io_flush_sbuffer_valid;
  wire i_io_flush_sbuffer_valid;
  wire g_io_feedbackSlow_valid;
  wire i_io_feedbackSlow_valid;
  wire g_io_feedbackSlow_bits_sqIdx_flag;
  wire i_io_feedbackSlow_bits_sqIdx_flag;
  wire [5:0] g_io_feedbackSlow_bits_sqIdx_value;
  wire [5:0] i_io_feedbackSlow_bits_sqIdx_value;
  wire g_io_exceptionInfo_valid;
  wire i_io_exceptionInfo_valid;
  wire [63:0] g_io_exceptionInfo_bits_vaddr;
  wire [63:0] i_io_exceptionInfo_bits_vaddr;
  wire [63:0] g_io_exceptionInfo_bits_gpaddr;
  wire [63:0] i_io_exceptionInfo_bits_gpaddr;
  wire g_io_exceptionInfo_bits_isForVSnonLeafPTE;
  wire i_io_exceptionInfo_bits_isForVSnonLeafPTE;

  AtomicsUnit dut_g (
    .clock(clk), .reset(rst),
    .io_hartId(io_hartId),
    .io_in_valid(io_in_valid),
    .io_in_bits_uop_fuOpType(io_in_bits_uop_fuOpType),
    .io_in_bits_uop_rfWen(io_in_bits_uop_rfWen),
    .io_in_bits_uop_pdest(io_in_bits_uop_pdest),
    .io_in_bits_uop_robIdx_flag(io_in_bits_uop_robIdx_flag),
    .io_in_bits_uop_robIdx_value(io_in_bits_uop_robIdx_value),
    .io_in_bits_uop_debugInfo_enqRsTime(io_in_bits_uop_debugInfo_enqRsTime),
    .io_in_bits_uop_debugInfo_selectTime(io_in_bits_uop_debugInfo_selectTime),
    .io_in_bits_uop_debugInfo_issueTime(io_in_bits_uop_debugInfo_issueTime),
    .io_in_bits_uop_sqIdx_flag(io_in_bits_uop_sqIdx_flag),
    .io_in_bits_uop_sqIdx_value(io_in_bits_uop_sqIdx_value),
    .io_in_bits_src_0(io_in_bits_src_0),
    .io_storeDataIn_0_valid(io_storeDataIn_0_valid),
    .io_storeDataIn_0_bits_uop_fuOpType(io_storeDataIn_0_bits_uop_fuOpType),
    .io_storeDataIn_0_bits_data(io_storeDataIn_0_bits_data),
    .io_storeDataIn_1_valid(io_storeDataIn_1_valid),
    .io_storeDataIn_1_bits_uop_fuOpType(io_storeDataIn_1_bits_uop_fuOpType),
    .io_storeDataIn_1_bits_data(io_storeDataIn_1_bits_data),
    .io_dcache_req_ready(io_dcache_req_ready),
    .io_dcache_resp_valid(io_dcache_resp_valid),
    .io_dcache_resp_bits_data(io_dcache_resp_bits_data),
    .io_dcache_resp_bits_miss(io_dcache_resp_bits_miss),
    .io_dcache_resp_bits_replay(io_dcache_resp_bits_replay),
    .io_dcache_resp_bits_error(io_dcache_resp_bits_error),
    .io_dcache_resp_bits_id(io_dcache_resp_bits_id),
    .io_dcache_block_lr(io_dcache_block_lr),
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
    .io_pmpResp_mmio(io_pmpResp_mmio),
    .io_flush_sbuffer_empty(io_flush_sbuffer_empty),
    .io_redirect_valid(io_redirect_valid),
    .io_csrCtrl_cache_error_enable(io_csrCtrl_cache_error_enable),
    .io_csrCtrl_mem_trigger_tUpdate_valid(io_csrCtrl_mem_trigger_tUpdate_valid),
    .io_csrCtrl_mem_trigger_tUpdate_bits_addr(io_csrCtrl_mem_trigger_tUpdate_bits_addr),
    .io_csrCtrl_mem_trigger_tUpdate_bits_tdata_matchType(io_csrCtrl_mem_trigger_tUpdate_bits_tdata_matchType),
    .io_csrCtrl_mem_trigger_tUpdate_bits_tdata_select(io_csrCtrl_mem_trigger_tUpdate_bits_tdata_select),
    .io_csrCtrl_mem_trigger_tUpdate_bits_tdata_action(io_csrCtrl_mem_trigger_tUpdate_bits_tdata_action),
    .io_csrCtrl_mem_trigger_tUpdate_bits_tdata_chain(io_csrCtrl_mem_trigger_tUpdate_bits_tdata_chain),
    .io_csrCtrl_mem_trigger_tUpdate_bits_tdata_store(io_csrCtrl_mem_trigger_tUpdate_bits_tdata_store),
    .io_csrCtrl_mem_trigger_tUpdate_bits_tdata_load(io_csrCtrl_mem_trigger_tUpdate_bits_tdata_load),
    .io_csrCtrl_mem_trigger_tUpdate_bits_tdata_tdata2(io_csrCtrl_mem_trigger_tUpdate_bits_tdata_tdata2),
    .io_csrCtrl_mem_trigger_tEnableVec_0(io_csrCtrl_mem_trigger_tEnableVec_0),
    .io_csrCtrl_mem_trigger_tEnableVec_1(io_csrCtrl_mem_trigger_tEnableVec_1),
    .io_csrCtrl_mem_trigger_tEnableVec_2(io_csrCtrl_mem_trigger_tEnableVec_2),
    .io_csrCtrl_mem_trigger_tEnableVec_3(io_csrCtrl_mem_trigger_tEnableVec_3),
    .io_csrCtrl_mem_trigger_debugMode(io_csrCtrl_mem_trigger_debugMode),
    .io_csrCtrl_mem_trigger_triggerCanRaiseBpExp(io_csrCtrl_mem_trigger_triggerCanRaiseBpExp),
    .io_in_ready(g_io_in_ready),
    .io_out_valid(g_io_out_valid),
    .io_out_bits_uop_exceptionVec_3(g_io_out_bits_uop_exceptionVec_3),
    .io_out_bits_uop_exceptionVec_4(g_io_out_bits_uop_exceptionVec_4),
    .io_out_bits_uop_exceptionVec_5(g_io_out_bits_uop_exceptionVec_5),
    .io_out_bits_uop_exceptionVec_6(g_io_out_bits_uop_exceptionVec_6),
    .io_out_bits_uop_exceptionVec_7(g_io_out_bits_uop_exceptionVec_7),
    .io_out_bits_uop_exceptionVec_13(g_io_out_bits_uop_exceptionVec_13),
    .io_out_bits_uop_exceptionVec_15(g_io_out_bits_uop_exceptionVec_15),
    .io_out_bits_uop_exceptionVec_21(g_io_out_bits_uop_exceptionVec_21),
    .io_out_bits_uop_exceptionVec_23(g_io_out_bits_uop_exceptionVec_23),
    .io_out_bits_uop_trigger(g_io_out_bits_uop_trigger),
    .io_out_bits_uop_rfWen(g_io_out_bits_uop_rfWen),
    .io_out_bits_uop_pdest(g_io_out_bits_uop_pdest),
    .io_out_bits_uop_robIdx_flag(g_io_out_bits_uop_robIdx_flag),
    .io_out_bits_uop_robIdx_value(g_io_out_bits_uop_robIdx_value),
    .io_out_bits_uop_debugInfo_enqRsTime(g_io_out_bits_uop_debugInfo_enqRsTime),
    .io_out_bits_uop_debugInfo_selectTime(g_io_out_bits_uop_debugInfo_selectTime),
    .io_out_bits_uop_debugInfo_issueTime(g_io_out_bits_uop_debugInfo_issueTime),
    .io_out_bits_data(g_io_out_bits_data),
    .io_out_bits_debug_isMMIO(g_io_out_bits_debug_isMMIO),
    .io_dcache_req_valid(g_io_dcache_req_valid),
    .io_dcache_req_bits_cmd(g_io_dcache_req_bits_cmd),
    .io_dcache_req_bits_vaddr(g_io_dcache_req_bits_vaddr),
    .io_dcache_req_bits_addr(g_io_dcache_req_bits_addr),
    .io_dcache_req_bits_word_idx(g_io_dcache_req_bits_word_idx),
    .io_dcache_req_bits_amo_data(g_io_dcache_req_bits_amo_data),
    .io_dcache_req_bits_amo_mask(g_io_dcache_req_bits_amo_mask),
    .io_dcache_req_bits_amo_cmp(g_io_dcache_req_bits_amo_cmp),
    .io_dtlb_req_valid(g_io_dtlb_req_valid),
    .io_dtlb_req_bits_vaddr(g_io_dtlb_req_bits_vaddr),
    .io_dtlb_req_bits_fullva(g_io_dtlb_req_bits_fullva),
    .io_dtlb_req_bits_cmd(g_io_dtlb_req_bits_cmd),
    .io_dtlb_req_bits_debug_robIdx_flag(g_io_dtlb_req_bits_debug_robIdx_flag),
    .io_dtlb_req_bits_debug_robIdx_value(g_io_dtlb_req_bits_debug_robIdx_value),
    .io_flush_sbuffer_valid(g_io_flush_sbuffer_valid),
    .io_feedbackSlow_valid(g_io_feedbackSlow_valid),
    .io_feedbackSlow_bits_sqIdx_flag(g_io_feedbackSlow_bits_sqIdx_flag),
    .io_feedbackSlow_bits_sqIdx_value(g_io_feedbackSlow_bits_sqIdx_value),
    .io_exceptionInfo_valid(g_io_exceptionInfo_valid),
    .io_exceptionInfo_bits_vaddr(g_io_exceptionInfo_bits_vaddr),
    .io_exceptionInfo_bits_gpaddr(g_io_exceptionInfo_bits_gpaddr),
    .io_exceptionInfo_bits_isForVSnonLeafPTE(g_io_exceptionInfo_bits_isForVSnonLeafPTE)
  );

  AtomicsUnit_xs dut_i (
    .clock(clk), .reset(rst),
    .io_hartId(io_hartId),
    .io_in_valid(io_in_valid),
    .io_in_bits_uop_fuOpType(io_in_bits_uop_fuOpType),
    .io_in_bits_uop_rfWen(io_in_bits_uop_rfWen),
    .io_in_bits_uop_pdest(io_in_bits_uop_pdest),
    .io_in_bits_uop_robIdx_flag(io_in_bits_uop_robIdx_flag),
    .io_in_bits_uop_robIdx_value(io_in_bits_uop_robIdx_value),
    .io_in_bits_uop_debugInfo_enqRsTime(io_in_bits_uop_debugInfo_enqRsTime),
    .io_in_bits_uop_debugInfo_selectTime(io_in_bits_uop_debugInfo_selectTime),
    .io_in_bits_uop_debugInfo_issueTime(io_in_bits_uop_debugInfo_issueTime),
    .io_in_bits_uop_sqIdx_flag(io_in_bits_uop_sqIdx_flag),
    .io_in_bits_uop_sqIdx_value(io_in_bits_uop_sqIdx_value),
    .io_in_bits_src_0(io_in_bits_src_0),
    .io_storeDataIn_0_valid(io_storeDataIn_0_valid),
    .io_storeDataIn_0_bits_uop_fuOpType(io_storeDataIn_0_bits_uop_fuOpType),
    .io_storeDataIn_0_bits_data(io_storeDataIn_0_bits_data),
    .io_storeDataIn_1_valid(io_storeDataIn_1_valid),
    .io_storeDataIn_1_bits_uop_fuOpType(io_storeDataIn_1_bits_uop_fuOpType),
    .io_storeDataIn_1_bits_data(io_storeDataIn_1_bits_data),
    .io_dcache_req_ready(io_dcache_req_ready),
    .io_dcache_resp_valid(io_dcache_resp_valid),
    .io_dcache_resp_bits_data(io_dcache_resp_bits_data),
    .io_dcache_resp_bits_miss(io_dcache_resp_bits_miss),
    .io_dcache_resp_bits_replay(io_dcache_resp_bits_replay),
    .io_dcache_resp_bits_error(io_dcache_resp_bits_error),
    .io_dcache_resp_bits_id(io_dcache_resp_bits_id),
    .io_dcache_block_lr(io_dcache_block_lr),
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
    .io_pmpResp_mmio(io_pmpResp_mmio),
    .io_flush_sbuffer_empty(io_flush_sbuffer_empty),
    .io_redirect_valid(io_redirect_valid),
    .io_csrCtrl_cache_error_enable(io_csrCtrl_cache_error_enable),
    .io_csrCtrl_mem_trigger_tUpdate_valid(io_csrCtrl_mem_trigger_tUpdate_valid),
    .io_csrCtrl_mem_trigger_tUpdate_bits_addr(io_csrCtrl_mem_trigger_tUpdate_bits_addr),
    .io_csrCtrl_mem_trigger_tUpdate_bits_tdata_matchType(io_csrCtrl_mem_trigger_tUpdate_bits_tdata_matchType),
    .io_csrCtrl_mem_trigger_tUpdate_bits_tdata_select(io_csrCtrl_mem_trigger_tUpdate_bits_tdata_select),
    .io_csrCtrl_mem_trigger_tUpdate_bits_tdata_action(io_csrCtrl_mem_trigger_tUpdate_bits_tdata_action),
    .io_csrCtrl_mem_trigger_tUpdate_bits_tdata_chain(io_csrCtrl_mem_trigger_tUpdate_bits_tdata_chain),
    .io_csrCtrl_mem_trigger_tUpdate_bits_tdata_store(io_csrCtrl_mem_trigger_tUpdate_bits_tdata_store),
    .io_csrCtrl_mem_trigger_tUpdate_bits_tdata_load(io_csrCtrl_mem_trigger_tUpdate_bits_tdata_load),
    .io_csrCtrl_mem_trigger_tUpdate_bits_tdata_tdata2(io_csrCtrl_mem_trigger_tUpdate_bits_tdata_tdata2),
    .io_csrCtrl_mem_trigger_tEnableVec_0(io_csrCtrl_mem_trigger_tEnableVec_0),
    .io_csrCtrl_mem_trigger_tEnableVec_1(io_csrCtrl_mem_trigger_tEnableVec_1),
    .io_csrCtrl_mem_trigger_tEnableVec_2(io_csrCtrl_mem_trigger_tEnableVec_2),
    .io_csrCtrl_mem_trigger_tEnableVec_3(io_csrCtrl_mem_trigger_tEnableVec_3),
    .io_csrCtrl_mem_trigger_debugMode(io_csrCtrl_mem_trigger_debugMode),
    .io_csrCtrl_mem_trigger_triggerCanRaiseBpExp(io_csrCtrl_mem_trigger_triggerCanRaiseBpExp),
    .io_in_ready(i_io_in_ready),
    .io_out_valid(i_io_out_valid),
    .io_out_bits_uop_exceptionVec_3(i_io_out_bits_uop_exceptionVec_3),
    .io_out_bits_uop_exceptionVec_4(i_io_out_bits_uop_exceptionVec_4),
    .io_out_bits_uop_exceptionVec_5(i_io_out_bits_uop_exceptionVec_5),
    .io_out_bits_uop_exceptionVec_6(i_io_out_bits_uop_exceptionVec_6),
    .io_out_bits_uop_exceptionVec_7(i_io_out_bits_uop_exceptionVec_7),
    .io_out_bits_uop_exceptionVec_13(i_io_out_bits_uop_exceptionVec_13),
    .io_out_bits_uop_exceptionVec_15(i_io_out_bits_uop_exceptionVec_15),
    .io_out_bits_uop_exceptionVec_21(i_io_out_bits_uop_exceptionVec_21),
    .io_out_bits_uop_exceptionVec_23(i_io_out_bits_uop_exceptionVec_23),
    .io_out_bits_uop_trigger(i_io_out_bits_uop_trigger),
    .io_out_bits_uop_rfWen(i_io_out_bits_uop_rfWen),
    .io_out_bits_uop_pdest(i_io_out_bits_uop_pdest),
    .io_out_bits_uop_robIdx_flag(i_io_out_bits_uop_robIdx_flag),
    .io_out_bits_uop_robIdx_value(i_io_out_bits_uop_robIdx_value),
    .io_out_bits_uop_debugInfo_enqRsTime(i_io_out_bits_uop_debugInfo_enqRsTime),
    .io_out_bits_uop_debugInfo_selectTime(i_io_out_bits_uop_debugInfo_selectTime),
    .io_out_bits_uop_debugInfo_issueTime(i_io_out_bits_uop_debugInfo_issueTime),
    .io_out_bits_data(i_io_out_bits_data),
    .io_out_bits_debug_isMMIO(i_io_out_bits_debug_isMMIO),
    .io_dcache_req_valid(i_io_dcache_req_valid),
    .io_dcache_req_bits_cmd(i_io_dcache_req_bits_cmd),
    .io_dcache_req_bits_vaddr(i_io_dcache_req_bits_vaddr),
    .io_dcache_req_bits_addr(i_io_dcache_req_bits_addr),
    .io_dcache_req_bits_word_idx(i_io_dcache_req_bits_word_idx),
    .io_dcache_req_bits_amo_data(i_io_dcache_req_bits_amo_data),
    .io_dcache_req_bits_amo_mask(i_io_dcache_req_bits_amo_mask),
    .io_dcache_req_bits_amo_cmp(i_io_dcache_req_bits_amo_cmp),
    .io_dtlb_req_valid(i_io_dtlb_req_valid),
    .io_dtlb_req_bits_vaddr(i_io_dtlb_req_bits_vaddr),
    .io_dtlb_req_bits_fullva(i_io_dtlb_req_bits_fullva),
    .io_dtlb_req_bits_cmd(i_io_dtlb_req_bits_cmd),
    .io_dtlb_req_bits_debug_robIdx_flag(i_io_dtlb_req_bits_debug_robIdx_flag),
    .io_dtlb_req_bits_debug_robIdx_value(i_io_dtlb_req_bits_debug_robIdx_value),
    .io_flush_sbuffer_valid(i_io_flush_sbuffer_valid),
    .io_feedbackSlow_valid(i_io_feedbackSlow_valid),
    .io_feedbackSlow_bits_sqIdx_flag(i_io_feedbackSlow_bits_sqIdx_flag),
    .io_feedbackSlow_bits_sqIdx_value(i_io_feedbackSlow_bits_sqIdx_value),
    .io_exceptionInfo_valid(i_io_exceptionInfo_valid),
    .io_exceptionInfo_bits_vaddr(i_io_exceptionInfo_bits_vaddr),
    .io_exceptionInfo_bits_gpaddr(i_io_exceptionInfo_bits_gpaddr),
    .io_exceptionInfo_bits_isForVSnonLeafPTE(i_io_exceptionInfo_bits_isForVSnonLeafPTE)
  );

  // 合法原子 fuOpType 池(与 golden cmd 表覆盖一致): LR/SC W&D, AMO*, AMOCAS
  logic [8:0] fuop_pool [];
  task automatic drive_random();
    io_hartId = $random;
    io_in_valid = $random;
    io_in_bits_uop_fuOpType = $random;
    io_in_bits_uop_rfWen = $random;
    io_in_bits_uop_pdest = $random;
    io_in_bits_uop_robIdx_flag = $random;
    io_in_bits_uop_robIdx_value = $random;
    io_in_bits_uop_debugInfo_enqRsTime = {$random,$random};
    io_in_bits_uop_debugInfo_selectTime = {$random,$random};
    io_in_bits_uop_debugInfo_issueTime = {$random,$random};
    io_in_bits_uop_sqIdx_flag = $random;
    io_in_bits_uop_sqIdx_value = $random;
    io_in_bits_src_0 = {$random,$random};
    io_storeDataIn_0_valid = $random;
    io_storeDataIn_0_bits_uop_fuOpType = $random;
    io_storeDataIn_0_bits_data = {$random,$random};
    io_storeDataIn_1_valid = $random;
    io_storeDataIn_1_bits_uop_fuOpType = $random;
    io_storeDataIn_1_bits_data = {$random,$random};
    io_dcache_req_ready = $random;
    io_dcache_resp_valid = $random;
    io_dcache_resp_bits_data = {$random,$random,$random,$random};
    io_dcache_resp_bits_miss = $random;
    io_dcache_resp_bits_replay = $random;
    io_dcache_resp_bits_error = $random;
    io_dcache_resp_bits_id = $random;
    io_dcache_block_lr = $random;
    io_dtlb_resp_valid = $random;
    io_dtlb_resp_bits_paddr_0 = {$random,$random};
    io_dtlb_resp_bits_gpaddr_0 = {$random,$random};
    io_dtlb_resp_bits_fullva = {$random,$random};
    io_dtlb_resp_bits_pbmt_0 = $random;
    io_dtlb_resp_bits_miss = $random;
    io_dtlb_resp_bits_isForVSnonLeafPTE = $random;
    io_dtlb_resp_bits_excp_0_gpf_ld = $random;
    io_dtlb_resp_bits_excp_0_gpf_st = $random;
    io_dtlb_resp_bits_excp_0_pf_ld = $random;
    io_dtlb_resp_bits_excp_0_pf_st = $random;
    io_dtlb_resp_bits_excp_0_af_ld = $random;
    io_dtlb_resp_bits_excp_0_af_st = $random;
    io_pmpResp_ld = $random;
    io_pmpResp_st = $random;
    io_pmpResp_mmio = $random;
    io_flush_sbuffer_empty = $random;
    io_redirect_valid = $random;
    io_csrCtrl_cache_error_enable = $random;
    io_csrCtrl_mem_trigger_tUpdate_valid = $random;
    io_csrCtrl_mem_trigger_tUpdate_bits_addr = $random;
    io_csrCtrl_mem_trigger_tUpdate_bits_tdata_matchType = $random;
    io_csrCtrl_mem_trigger_tUpdate_bits_tdata_select = $random;
    io_csrCtrl_mem_trigger_tUpdate_bits_tdata_action = $random;
    io_csrCtrl_mem_trigger_tUpdate_bits_tdata_chain = $random;
    io_csrCtrl_mem_trigger_tUpdate_bits_tdata_store = $random;
    io_csrCtrl_mem_trigger_tUpdate_bits_tdata_load = $random;
    io_csrCtrl_mem_trigger_tUpdate_bits_tdata_tdata2 = {$random,$random};
    io_csrCtrl_mem_trigger_tEnableVec_0 = $random;
    io_csrCtrl_mem_trigger_tEnableVec_1 = $random;
    io_csrCtrl_mem_trigger_tEnableVec_2 = $random;
    io_csrCtrl_mem_trigger_tEnableVec_3 = $random;
    io_csrCtrl_mem_trigger_debugMode = $random;
    io_csrCtrl_mem_trigger_triggerCanRaiseBpExp = $random;
    // 偏置: 输入 fuOpType 取自合法池, 使 dcache cmd/AMO 路径被激活
    io_in_bits_uop_fuOpType = fuop_pool[$urandom_range(0, fuop_pool.size()-1)];
    // storeDataIn uopIdx 取 0..3 覆盖 rd_l/rs2_l/rd_h/rs2_h 分拣
    io_storeDataIn_0_bits_uop_fuOpType = {$random} & 9'h1C0 | ({$random} & 9'h3F);
    io_storeDataIn_1_bits_uop_fuOpType = {$random} & 9'h1C0 | ({$random} & 9'h3F);
    // 响应握手大多拉高以推进状态机
    if (($random & 3) != 0) io_dcache_req_ready   = 1'b1;
    if (($random & 3) != 0) io_dcache_resp_valid  = 1'b1;
    if (($random & 3) != 0) io_dtlb_resp_valid    = 1'b1;
    if (($random & 3) != 0) io_flush_sbuffer_empty= 1'b1;
    if (($random & 7) == 0) io_dcache_resp_bits_miss = 1'b1;
  endtask

  task automatic check_outputs();
    checks++;
    if (g_io_in_ready !== i_io_in_ready) begin errors++; if (errors<=20) $display("[%0d] MISMATCH io_in_ready: g=%h i=%h", cyc, g_io_in_ready, i_io_in_ready); end
    if (g_io_out_valid !== i_io_out_valid) begin errors++; if (errors<=20) $display("[%0d] MISMATCH io_out_valid: g=%h i=%h", cyc, g_io_out_valid, i_io_out_valid); end
    if (g_io_out_bits_uop_exceptionVec_3 !== i_io_out_bits_uop_exceptionVec_3) begin errors++; if (errors<=20) $display("[%0d] MISMATCH io_out_bits_uop_exceptionVec_3: g=%h i=%h", cyc, g_io_out_bits_uop_exceptionVec_3, i_io_out_bits_uop_exceptionVec_3); end
    if (g_io_out_bits_uop_exceptionVec_4 !== i_io_out_bits_uop_exceptionVec_4) begin errors++; if (errors<=20) $display("[%0d] MISMATCH io_out_bits_uop_exceptionVec_4: g=%h i=%h", cyc, g_io_out_bits_uop_exceptionVec_4, i_io_out_bits_uop_exceptionVec_4); end
    if (g_io_out_bits_uop_exceptionVec_5 !== i_io_out_bits_uop_exceptionVec_5) begin errors++; if (errors<=20) $display("[%0d] MISMATCH io_out_bits_uop_exceptionVec_5: g=%h i=%h", cyc, g_io_out_bits_uop_exceptionVec_5, i_io_out_bits_uop_exceptionVec_5); end
    if (g_io_out_bits_uop_exceptionVec_6 !== i_io_out_bits_uop_exceptionVec_6) begin errors++; if (errors<=20) $display("[%0d] MISMATCH io_out_bits_uop_exceptionVec_6: g=%h i=%h", cyc, g_io_out_bits_uop_exceptionVec_6, i_io_out_bits_uop_exceptionVec_6); end
    if (g_io_out_bits_uop_exceptionVec_7 !== i_io_out_bits_uop_exceptionVec_7) begin errors++; if (errors<=20) $display("[%0d] MISMATCH io_out_bits_uop_exceptionVec_7: g=%h i=%h", cyc, g_io_out_bits_uop_exceptionVec_7, i_io_out_bits_uop_exceptionVec_7); end
    if (g_io_out_bits_uop_exceptionVec_13 !== i_io_out_bits_uop_exceptionVec_13) begin errors++; if (errors<=20) $display("[%0d] MISMATCH io_out_bits_uop_exceptionVec_13: g=%h i=%h", cyc, g_io_out_bits_uop_exceptionVec_13, i_io_out_bits_uop_exceptionVec_13); end
    if (g_io_out_bits_uop_exceptionVec_15 !== i_io_out_bits_uop_exceptionVec_15) begin errors++; if (errors<=20) $display("[%0d] MISMATCH io_out_bits_uop_exceptionVec_15: g=%h i=%h", cyc, g_io_out_bits_uop_exceptionVec_15, i_io_out_bits_uop_exceptionVec_15); end
    if (g_io_out_bits_uop_exceptionVec_21 !== i_io_out_bits_uop_exceptionVec_21) begin errors++; if (errors<=20) $display("[%0d] MISMATCH io_out_bits_uop_exceptionVec_21: g=%h i=%h", cyc, g_io_out_bits_uop_exceptionVec_21, i_io_out_bits_uop_exceptionVec_21); end
    if (g_io_out_bits_uop_exceptionVec_23 !== i_io_out_bits_uop_exceptionVec_23) begin errors++; if (errors<=20) $display("[%0d] MISMATCH io_out_bits_uop_exceptionVec_23: g=%h i=%h", cyc, g_io_out_bits_uop_exceptionVec_23, i_io_out_bits_uop_exceptionVec_23); end
    if (g_io_out_bits_uop_trigger !== i_io_out_bits_uop_trigger) begin errors++; if (errors<=20) $display("[%0d] MISMATCH io_out_bits_uop_trigger: g=%h i=%h", cyc, g_io_out_bits_uop_trigger, i_io_out_bits_uop_trigger); end
    if (g_io_out_bits_uop_rfWen !== i_io_out_bits_uop_rfWen) begin errors++; if (errors<=20) $display("[%0d] MISMATCH io_out_bits_uop_rfWen: g=%h i=%h", cyc, g_io_out_bits_uop_rfWen, i_io_out_bits_uop_rfWen); end
    if (g_io_out_bits_uop_pdest !== i_io_out_bits_uop_pdest) begin errors++; if (errors<=20) $display("[%0d] MISMATCH io_out_bits_uop_pdest: g=%h i=%h", cyc, g_io_out_bits_uop_pdest, i_io_out_bits_uop_pdest); end
    if (g_io_out_bits_uop_robIdx_flag !== i_io_out_bits_uop_robIdx_flag) begin errors++; if (errors<=20) $display("[%0d] MISMATCH io_out_bits_uop_robIdx_flag: g=%h i=%h", cyc, g_io_out_bits_uop_robIdx_flag, i_io_out_bits_uop_robIdx_flag); end
    if (g_io_out_bits_uop_robIdx_value !== i_io_out_bits_uop_robIdx_value) begin errors++; if (errors<=20) $display("[%0d] MISMATCH io_out_bits_uop_robIdx_value: g=%h i=%h", cyc, g_io_out_bits_uop_robIdx_value, i_io_out_bits_uop_robIdx_value); end
    if (g_io_out_bits_uop_debugInfo_enqRsTime !== i_io_out_bits_uop_debugInfo_enqRsTime) begin errors++; if (errors<=20) $display("[%0d] MISMATCH io_out_bits_uop_debugInfo_enqRsTime: g=%h i=%h", cyc, g_io_out_bits_uop_debugInfo_enqRsTime, i_io_out_bits_uop_debugInfo_enqRsTime); end
    if (g_io_out_bits_uop_debugInfo_selectTime !== i_io_out_bits_uop_debugInfo_selectTime) begin errors++; if (errors<=20) $display("[%0d] MISMATCH io_out_bits_uop_debugInfo_selectTime: g=%h i=%h", cyc, g_io_out_bits_uop_debugInfo_selectTime, i_io_out_bits_uop_debugInfo_selectTime); end
    if (g_io_out_bits_uop_debugInfo_issueTime !== i_io_out_bits_uop_debugInfo_issueTime) begin errors++; if (errors<=20) $display("[%0d] MISMATCH io_out_bits_uop_debugInfo_issueTime: g=%h i=%h", cyc, g_io_out_bits_uop_debugInfo_issueTime, i_io_out_bits_uop_debugInfo_issueTime); end
    if (g_io_out_bits_data !== i_io_out_bits_data) begin errors++; if (errors<=20) $display("[%0d] MISMATCH io_out_bits_data: g=%h i=%h", cyc, g_io_out_bits_data, i_io_out_bits_data); end
    if (g_io_out_bits_debug_isMMIO !== i_io_out_bits_debug_isMMIO) begin errors++; if (errors<=20) $display("[%0d] MISMATCH io_out_bits_debug_isMMIO: g=%h i=%h", cyc, g_io_out_bits_debug_isMMIO, i_io_out_bits_debug_isMMIO); end
    if (g_io_dcache_req_valid !== i_io_dcache_req_valid) begin errors++; if (errors<=20) $display("[%0d] MISMATCH io_dcache_req_valid: g=%h i=%h", cyc, g_io_dcache_req_valid, i_io_dcache_req_valid); end
    if (g_io_dcache_req_bits_cmd !== i_io_dcache_req_bits_cmd) begin errors++; if (errors<=20) $display("[%0d] MISMATCH io_dcache_req_bits_cmd: g=%h i=%h", cyc, g_io_dcache_req_bits_cmd, i_io_dcache_req_bits_cmd); end
    if (g_io_dcache_req_bits_vaddr !== i_io_dcache_req_bits_vaddr) begin errors++; if (errors<=20) $display("[%0d] MISMATCH io_dcache_req_bits_vaddr: g=%h i=%h", cyc, g_io_dcache_req_bits_vaddr, i_io_dcache_req_bits_vaddr); end
    if (g_io_dcache_req_bits_addr !== i_io_dcache_req_bits_addr) begin errors++; if (errors<=20) $display("[%0d] MISMATCH io_dcache_req_bits_addr: g=%h i=%h", cyc, g_io_dcache_req_bits_addr, i_io_dcache_req_bits_addr); end
    if (g_io_dcache_req_bits_word_idx !== i_io_dcache_req_bits_word_idx) begin errors++; if (errors<=20) $display("[%0d] MISMATCH io_dcache_req_bits_word_idx: g=%h i=%h", cyc, g_io_dcache_req_bits_word_idx, i_io_dcache_req_bits_word_idx); end
    if (g_io_dcache_req_bits_amo_data !== i_io_dcache_req_bits_amo_data) begin errors++; if (errors<=20) $display("[%0d] MISMATCH io_dcache_req_bits_amo_data: g=%h i=%h", cyc, g_io_dcache_req_bits_amo_data, i_io_dcache_req_bits_amo_data); end
    if (g_io_dcache_req_bits_amo_mask !== i_io_dcache_req_bits_amo_mask) begin errors++; if (errors<=20) $display("[%0d] MISMATCH io_dcache_req_bits_amo_mask: g=%h i=%h", cyc, g_io_dcache_req_bits_amo_mask, i_io_dcache_req_bits_amo_mask); end
    if (g_io_dcache_req_bits_amo_cmp !== i_io_dcache_req_bits_amo_cmp) begin errors++; if (errors<=20) $display("[%0d] MISMATCH io_dcache_req_bits_amo_cmp: g=%h i=%h", cyc, g_io_dcache_req_bits_amo_cmp, i_io_dcache_req_bits_amo_cmp); end
    if (g_io_dtlb_req_valid !== i_io_dtlb_req_valid) begin errors++; if (errors<=20) $display("[%0d] MISMATCH io_dtlb_req_valid: g=%h i=%h", cyc, g_io_dtlb_req_valid, i_io_dtlb_req_valid); end
    if (g_io_dtlb_req_bits_vaddr !== i_io_dtlb_req_bits_vaddr) begin errors++; if (errors<=20) $display("[%0d] MISMATCH io_dtlb_req_bits_vaddr: g=%h i=%h", cyc, g_io_dtlb_req_bits_vaddr, i_io_dtlb_req_bits_vaddr); end
    if (g_io_dtlb_req_bits_fullva !== i_io_dtlb_req_bits_fullva) begin errors++; if (errors<=20) $display("[%0d] MISMATCH io_dtlb_req_bits_fullva: g=%h i=%h", cyc, g_io_dtlb_req_bits_fullva, i_io_dtlb_req_bits_fullva); end
    if (g_io_dtlb_req_bits_cmd !== i_io_dtlb_req_bits_cmd) begin errors++; if (errors<=20) $display("[%0d] MISMATCH io_dtlb_req_bits_cmd: g=%h i=%h", cyc, g_io_dtlb_req_bits_cmd, i_io_dtlb_req_bits_cmd); end
    if (g_io_dtlb_req_bits_debug_robIdx_flag !== i_io_dtlb_req_bits_debug_robIdx_flag) begin errors++; if (errors<=20) $display("[%0d] MISMATCH io_dtlb_req_bits_debug_robIdx_flag: g=%h i=%h", cyc, g_io_dtlb_req_bits_debug_robIdx_flag, i_io_dtlb_req_bits_debug_robIdx_flag); end
    if (g_io_dtlb_req_bits_debug_robIdx_value !== i_io_dtlb_req_bits_debug_robIdx_value) begin errors++; if (errors<=20) $display("[%0d] MISMATCH io_dtlb_req_bits_debug_robIdx_value: g=%h i=%h", cyc, g_io_dtlb_req_bits_debug_robIdx_value, i_io_dtlb_req_bits_debug_robIdx_value); end
    if (g_io_flush_sbuffer_valid !== i_io_flush_sbuffer_valid) begin errors++; if (errors<=20) $display("[%0d] MISMATCH io_flush_sbuffer_valid: g=%h i=%h", cyc, g_io_flush_sbuffer_valid, i_io_flush_sbuffer_valid); end
    if (g_io_feedbackSlow_valid !== i_io_feedbackSlow_valid) begin errors++; if (errors<=20) $display("[%0d] MISMATCH io_feedbackSlow_valid: g=%h i=%h", cyc, g_io_feedbackSlow_valid, i_io_feedbackSlow_valid); end
    if (g_io_feedbackSlow_bits_sqIdx_flag !== i_io_feedbackSlow_bits_sqIdx_flag) begin errors++; if (errors<=20) $display("[%0d] MISMATCH io_feedbackSlow_bits_sqIdx_flag: g=%h i=%h", cyc, g_io_feedbackSlow_bits_sqIdx_flag, i_io_feedbackSlow_bits_sqIdx_flag); end
    if (g_io_feedbackSlow_bits_sqIdx_value !== i_io_feedbackSlow_bits_sqIdx_value) begin errors++; if (errors<=20) $display("[%0d] MISMATCH io_feedbackSlow_bits_sqIdx_value: g=%h i=%h", cyc, g_io_feedbackSlow_bits_sqIdx_value, i_io_feedbackSlow_bits_sqIdx_value); end
    if (g_io_exceptionInfo_valid !== i_io_exceptionInfo_valid) begin errors++; if (errors<=20) $display("[%0d] MISMATCH io_exceptionInfo_valid: g=%h i=%h", cyc, g_io_exceptionInfo_valid, i_io_exceptionInfo_valid); end
    if (g_io_exceptionInfo_bits_vaddr !== i_io_exceptionInfo_bits_vaddr) begin errors++; if (errors<=20) $display("[%0d] MISMATCH io_exceptionInfo_bits_vaddr: g=%h i=%h", cyc, g_io_exceptionInfo_bits_vaddr, i_io_exceptionInfo_bits_vaddr); end
    if (g_io_exceptionInfo_bits_gpaddr !== i_io_exceptionInfo_bits_gpaddr) begin errors++; if (errors<=20) $display("[%0d] MISMATCH io_exceptionInfo_bits_gpaddr: g=%h i=%h", cyc, g_io_exceptionInfo_bits_gpaddr, i_io_exceptionInfo_bits_gpaddr); end
    if (g_io_exceptionInfo_bits_isForVSnonLeafPTE !== i_io_exceptionInfo_bits_isForVSnonLeafPTE) begin errors++; if (errors<=20) $display("[%0d] MISMATCH io_exceptionInfo_bits_isForVSnonLeafPTE: g=%h i=%h", cyc, g_io_exceptionInfo_bits_isForVSnonLeafPTE, i_io_exceptionInfo_bits_isForVSnonLeafPTE); end
  endtask

  initial begin
    fuop_pool = new[25];
    fuop_pool[0] = 9'h2;
    fuop_pool[1] = 9'h3;
    fuop_pool[2] = 9'h6;
    fuop_pool[3] = 9'h7;
    fuop_pool[4] = 9'hA;
    fuop_pool[5] = 9'hB;
    fuop_pool[6] = 9'hE;
    fuop_pool[7] = 9'hF;
    fuop_pool[8] = 9'h12;
    fuop_pool[9] = 9'h13;
    fuop_pool[10] = 9'h16;
    fuop_pool[11] = 9'h17;
    fuop_pool[12] = 9'h1A;
    fuop_pool[13] = 9'h1B;
    fuop_pool[14] = 9'h1E;
    fuop_pool[15] = 9'h1F;
    fuop_pool[16] = 9'h22;
    fuop_pool[17] = 9'h23;
    fuop_pool[18] = 9'h26;
    fuop_pool[19] = 9'h27;
    fuop_pool[20] = 9'h2A;
    fuop_pool[21] = 9'h2B;
    fuop_pool[22] = 9'h2C;
    fuop_pool[23] = 9'h2E;
    fuop_pool[24] = 9'h2F;
    rst = 1'b1;
    io_hartId = '0;
    io_in_valid = '0;
    io_in_bits_uop_fuOpType = '0;
    io_in_bits_uop_rfWen = '0;
    io_in_bits_uop_pdest = '0;
    io_in_bits_uop_robIdx_flag = '0;
    io_in_bits_uop_robIdx_value = '0;
    io_in_bits_uop_debugInfo_enqRsTime = '0;
    io_in_bits_uop_debugInfo_selectTime = '0;
    io_in_bits_uop_debugInfo_issueTime = '0;
    io_in_bits_uop_sqIdx_flag = '0;
    io_in_bits_uop_sqIdx_value = '0;
    io_in_bits_src_0 = '0;
    io_storeDataIn_0_valid = '0;
    io_storeDataIn_0_bits_uop_fuOpType = '0;
    io_storeDataIn_0_bits_data = '0;
    io_storeDataIn_1_valid = '0;
    io_storeDataIn_1_bits_uop_fuOpType = '0;
    io_storeDataIn_1_bits_data = '0;
    io_dcache_req_ready = '0;
    io_dcache_resp_valid = '0;
    io_dcache_resp_bits_data = '0;
    io_dcache_resp_bits_miss = '0;
    io_dcache_resp_bits_replay = '0;
    io_dcache_resp_bits_error = '0;
    io_dcache_resp_bits_id = '0;
    io_dcache_block_lr = '0;
    io_dtlb_resp_valid = '0;
    io_dtlb_resp_bits_paddr_0 = '0;
    io_dtlb_resp_bits_gpaddr_0 = '0;
    io_dtlb_resp_bits_fullva = '0;
    io_dtlb_resp_bits_pbmt_0 = '0;
    io_dtlb_resp_bits_miss = '0;
    io_dtlb_resp_bits_isForVSnonLeafPTE = '0;
    io_dtlb_resp_bits_excp_0_gpf_ld = '0;
    io_dtlb_resp_bits_excp_0_gpf_st = '0;
    io_dtlb_resp_bits_excp_0_pf_ld = '0;
    io_dtlb_resp_bits_excp_0_pf_st = '0;
    io_dtlb_resp_bits_excp_0_af_ld = '0;
    io_dtlb_resp_bits_excp_0_af_st = '0;
    io_pmpResp_ld = '0;
    io_pmpResp_st = '0;
    io_pmpResp_mmio = '0;
    io_flush_sbuffer_empty = '0;
    io_redirect_valid = '0;
    io_csrCtrl_cache_error_enable = '0;
    io_csrCtrl_mem_trigger_tUpdate_valid = '0;
    io_csrCtrl_mem_trigger_tUpdate_bits_addr = '0;
    io_csrCtrl_mem_trigger_tUpdate_bits_tdata_matchType = '0;
    io_csrCtrl_mem_trigger_tUpdate_bits_tdata_select = '0;
    io_csrCtrl_mem_trigger_tUpdate_bits_tdata_action = '0;
    io_csrCtrl_mem_trigger_tUpdate_bits_tdata_chain = '0;
    io_csrCtrl_mem_trigger_tUpdate_bits_tdata_store = '0;
    io_csrCtrl_mem_trigger_tUpdate_bits_tdata_load = '0;
    io_csrCtrl_mem_trigger_tUpdate_bits_tdata_tdata2 = '0;
    io_csrCtrl_mem_trigger_tEnableVec_0 = '0;
    io_csrCtrl_mem_trigger_tEnableVec_1 = '0;
    io_csrCtrl_mem_trigger_tEnableVec_2 = '0;
    io_csrCtrl_mem_trigger_tEnableVec_3 = '0;
    io_csrCtrl_mem_trigger_debugMode = '0;
    io_csrCtrl_mem_trigger_triggerCanRaiseBpExp = '0;
    repeat (6) @(posedge clk);
    @(negedge clk); rst = 1'b0;
    for (cyc = 0; cyc < NCYCLES; cyc++) begin
      @(negedge clk);
      drive_random();
      @(posedge clk);
      #1;
      if (cyc >= WARMUP) check_outputs();
    end
    if (errors == 0)
      $display("TEST PASSED: checks=%0d errors=0", checks);
    else
      $display("TEST FAILED: checks=%0d errors=%0d", checks, errors);
    $finish;
  end
endmodule
