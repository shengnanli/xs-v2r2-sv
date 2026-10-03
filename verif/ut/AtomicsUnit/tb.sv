// =============================================================================
// tb —— AtomicsUnit UT：golden AtomicsUnit 与重写件 AtomicsUnit_xs 双例化，同激励逐拍比全部 63 个输出。
//
// 激励（tb 自己做"后端 + dtlb + PMP + sbuffer + DCache"的随机环境，按事务驱动）：
//   * 指令：从 25 个合法原子编码（lr/sc/amo* × W/D，amocas × W/D/Q）里选，另有 1/16 概率给非 CAS 的
//     size=1 非法编码（golden 照样走完）；sta uop 先发 uopIdx=0，AMOCAS.Q 随后再发 uopIdx=2 的第二个 sta；
//     std 按需要的个数（1 / 2 / 4）、随机口、随机拍数送到，两口可同拍。
//   * dtlb：有请求时按概率回 resp（miss 30%，各类异常各 3%），另随机给"无请求时的 resp"（预取器噪声）；
//   * PMP / PBMT / sbuffer_empty / out_ready / block_lr / redirect / csr 触发器更新 / tEnable 全随机；
//   * DCache：req_ready 随机；resp_valid 随机（miss 30%，其中 replay 一半），data/id/tl_error 随机；
//   * rs1 与 tdata2 从同一个 16 对齐的小地址池里取（一半原样、其余加低位扰动造不对齐），让触发器三种 matchType 都能命中。
// 比对门控：uop/rs1/操作数/paddr/resp/tdata/difftest 打拍等不复位寄存器直通输出，+random 档两侧初值不同；
//   tb 先做暖机（4 个触发器槽各更新一次、4 个 std 槽各写一次、跑完一条 AMOCAS.Q 与一条 LR）把它们
//   全部写过一遍，之后才开始逐拍比对（WARM_DONE）。暖机期间激励同样打到两侧。
// 覆盖（写进 PASS 判据）：9 个状态各 >= 100 拍；25 个合法编码各 >= 20 条；异常早退（state1→7）、PM 异常、
//   dcache replay、mmio、触发器动作 != None、CASQ 第二拍写回 各 >= 20 次；每个输出都见过 0/1。
// =============================================================================
`timescale 1ns/1ps
module tb;
  int unsigned NCYCLES = 200000;
  longint errors = 0, checks = 0;
  int cyc;
  bit warm_done = 0;

  // ---- 以下声明/例化/比较由 golden 端口表机械展开（76 输入 / 62 输出）----
  logic clock;
  logic reset;
  logic [5:0] io_hartId;
  logic io_in_valid;
  logic [8:0] io_in_bits_uop_fuOpType;
  logic io_in_bits_uop_rfWen;
  logic [7:0] io_in_bits_uop_pdest;
  logic io_in_bits_uop_robIdx_flag;
  logic [7:0] io_in_bits_uop_robIdx_value;
  logic io_in_bits_uop_debugInfo_eliminatedMove;
  logic [63:0] io_in_bits_uop_debugInfo_renameTime;
  logic [63:0] io_in_bits_uop_debugInfo_dispatchTime;
  logic [63:0] io_in_bits_uop_debugInfo_enqRsTime;
  logic [63:0] io_in_bits_uop_debugInfo_selectTime;
  logic [63:0] io_in_bits_uop_debugInfo_issueTime;
  logic [63:0] io_in_bits_uop_debugInfo_writebackTime;
  logic [63:0] io_in_bits_uop_debugInfo_runahead_checkpoint_id;
  logic [63:0] io_in_bits_uop_debugInfo_tlbFirstReqTime;
  logic [63:0] io_in_bits_uop_debugInfo_tlbRespTime;
  logic [55:0] io_in_bits_uop_debug_seqNum_seqNum;
  logic [7:0] io_in_bits_uop_debug_seqNum_uopIdx;
  logic io_in_bits_uop_lqIdx_flag;
  logic [6:0] io_in_bits_uop_lqIdx_value;
  logic io_in_bits_uop_sqIdx_flag;
  logic [5:0] io_in_bits_uop_sqIdx_value;
  logic [63:0] io_in_bits_src_0;
  logic io_storeDataIn_0_valid;
  logic [8:0] io_storeDataIn_0_bits_uop_fuOpType;
  logic [63:0] io_storeDataIn_0_bits_data;
  logic io_storeDataIn_1_valid;
  logic [8:0] io_storeDataIn_1_bits_uop_fuOpType;
  logic [63:0] io_storeDataIn_1_bits_data;
  logic io_out_ready;
  logic io_dcache_req_ready;
  logic io_dcache_resp_valid;
  logic [127:0] io_dcache_resp_bits_data;
  logic io_dcache_resp_bits_miss;
  logic io_dcache_resp_bits_replay;
  logic io_dcache_resp_bits_tl_error_tl_denied;
  logic io_dcache_resp_bits_tl_error_tl_corrupt;
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
  logic g_io_in_ready, i_io_in_ready;
  logic g_io_out_valid, i_io_out_valid;
  logic g_io_out_bits_uop_exceptionVec_3, i_io_out_bits_uop_exceptionVec_3;
  logic g_io_out_bits_uop_exceptionVec_4, i_io_out_bits_uop_exceptionVec_4;
  logic g_io_out_bits_uop_exceptionVec_5, i_io_out_bits_uop_exceptionVec_5;
  logic g_io_out_bits_uop_exceptionVec_6, i_io_out_bits_uop_exceptionVec_6;
  logic g_io_out_bits_uop_exceptionVec_7, i_io_out_bits_uop_exceptionVec_7;
  logic g_io_out_bits_uop_exceptionVec_13, i_io_out_bits_uop_exceptionVec_13;
  logic g_io_out_bits_uop_exceptionVec_15, i_io_out_bits_uop_exceptionVec_15;
  logic g_io_out_bits_uop_exceptionVec_19, i_io_out_bits_uop_exceptionVec_19;
  logic g_io_out_bits_uop_exceptionVec_21, i_io_out_bits_uop_exceptionVec_21;
  logic g_io_out_bits_uop_exceptionVec_23, i_io_out_bits_uop_exceptionVec_23;
  logic [3:0] g_io_out_bits_uop_trigger, i_io_out_bits_uop_trigger;
  logic g_io_out_bits_uop_rfWen, i_io_out_bits_uop_rfWen;
  logic [7:0] g_io_out_bits_uop_pdest, i_io_out_bits_uop_pdest;
  logic g_io_out_bits_uop_robIdx_flag, i_io_out_bits_uop_robIdx_flag;
  logic [7:0] g_io_out_bits_uop_robIdx_value, i_io_out_bits_uop_robIdx_value;
  logic g_io_out_bits_uop_debugInfo_eliminatedMove, i_io_out_bits_uop_debugInfo_eliminatedMove;
  logic [63:0] g_io_out_bits_uop_debugInfo_renameTime, i_io_out_bits_uop_debugInfo_renameTime;
  logic [63:0] g_io_out_bits_uop_debugInfo_dispatchTime, i_io_out_bits_uop_debugInfo_dispatchTime;
  logic [63:0] g_io_out_bits_uop_debugInfo_enqRsTime, i_io_out_bits_uop_debugInfo_enqRsTime;
  logic [63:0] g_io_out_bits_uop_debugInfo_selectTime, i_io_out_bits_uop_debugInfo_selectTime;
  logic [63:0] g_io_out_bits_uop_debugInfo_issueTime, i_io_out_bits_uop_debugInfo_issueTime;
  logic [63:0] g_io_out_bits_uop_debugInfo_writebackTime, i_io_out_bits_uop_debugInfo_writebackTime;
  logic [63:0] g_io_out_bits_uop_debugInfo_runahead_checkpoint_id, i_io_out_bits_uop_debugInfo_runahead_checkpoint_id;
  logic [63:0] g_io_out_bits_uop_debugInfo_tlbFirstReqTime, i_io_out_bits_uop_debugInfo_tlbFirstReqTime;
  logic [63:0] g_io_out_bits_uop_debugInfo_tlbRespTime, i_io_out_bits_uop_debugInfo_tlbRespTime;
  logic [55:0] g_io_out_bits_uop_debug_seqNum_seqNum, i_io_out_bits_uop_debug_seqNum_seqNum;
  logic [7:0] g_io_out_bits_uop_debug_seqNum_uopIdx, i_io_out_bits_uop_debug_seqNum_uopIdx;
  logic g_io_out_bits_uop_lqIdx_flag, i_io_out_bits_uop_lqIdx_flag;
  logic [6:0] g_io_out_bits_uop_lqIdx_value, i_io_out_bits_uop_lqIdx_value;
  logic [63:0] g_io_out_bits_data, i_io_out_bits_data;
  logic g_io_out_bits_debug_isMMIO, i_io_out_bits_debug_isMMIO;
  logic [47:0] g_io_out_bits_debug_paddr, i_io_out_bits_debug_paddr;
  logic g_io_dcache_req_valid, i_io_dcache_req_valid;
  logic [4:0] g_io_dcache_req_bits_cmd, i_io_dcache_req_bits_cmd;
  logic [49:0] g_io_dcache_req_bits_vaddr, i_io_dcache_req_bits_vaddr;
  logic [47:0] g_io_dcache_req_bits_addr, i_io_dcache_req_bits_addr;
  logic [2:0] g_io_dcache_req_bits_word_idx, i_io_dcache_req_bits_word_idx;
  logic [127:0] g_io_dcache_req_bits_amo_data, i_io_dcache_req_bits_amo_data;
  logic [15:0] g_io_dcache_req_bits_amo_mask, i_io_dcache_req_bits_amo_mask;
  logic [127:0] g_io_dcache_req_bits_amo_cmp, i_io_dcache_req_bits_amo_cmp;
  logic g_io_dtlb_req_valid, i_io_dtlb_req_valid;
  logic [49:0] g_io_dtlb_req_bits_vaddr, i_io_dtlb_req_bits_vaddr;
  logic [63:0] g_io_dtlb_req_bits_fullva, i_io_dtlb_req_bits_fullva;
  logic [2:0] g_io_dtlb_req_bits_cmd, i_io_dtlb_req_bits_cmd;
  logic g_io_dtlb_req_bits_debug_robIdx_flag, i_io_dtlb_req_bits_debug_robIdx_flag;
  logic [7:0] g_io_dtlb_req_bits_debug_robIdx_value, i_io_dtlb_req_bits_debug_robIdx_value;
  logic g_io_flush_sbuffer_valid, i_io_flush_sbuffer_valid;
  logic g_io_feedbackSlow_valid, i_io_feedbackSlow_valid;
  logic g_io_feedbackSlow_bits_robIdx_flag, i_io_feedbackSlow_bits_robIdx_flag;
  logic [7:0] g_io_feedbackSlow_bits_robIdx_value, i_io_feedbackSlow_bits_robIdx_value;
  logic g_io_feedbackSlow_bits_sqIdx_flag, i_io_feedbackSlow_bits_sqIdx_flag;
  logic [5:0] g_io_feedbackSlow_bits_sqIdx_value, i_io_feedbackSlow_bits_sqIdx_value;
  logic g_io_feedbackSlow_bits_lqIdx_flag, i_io_feedbackSlow_bits_lqIdx_flag;
  logic [6:0] g_io_feedbackSlow_bits_lqIdx_value, i_io_feedbackSlow_bits_lqIdx_value;
  logic g_io_exceptionInfo_valid, i_io_exceptionInfo_valid;
  logic [63:0] g_io_exceptionInfo_bits_vaddr, i_io_exceptionInfo_bits_vaddr;
  logic [63:0] g_io_exceptionInfo_bits_gpaddr, i_io_exceptionInfo_bits_gpaddr;
  logic g_io_exceptionInfo_bits_isForVSnonLeafPTE, i_io_exceptionInfo_bits_isForVSnonLeafPTE;
  logic [480:0] g_gatewayIn_packed_46_bore, i_gatewayIn_packed_46_bore;
  logic [9:0] g_gatewayIn_packed_47_bore, i_gatewayIn_packed_47_bore;
  AtomicsUnit u_g (
    .clock(clock),
    .reset(reset),
    .io_hartId(io_hartId),
    .io_in_valid(io_in_valid),
    .io_in_bits_uop_fuOpType(io_in_bits_uop_fuOpType),
    .io_in_bits_uop_rfWen(io_in_bits_uop_rfWen),
    .io_in_bits_uop_pdest(io_in_bits_uop_pdest),
    .io_in_bits_uop_robIdx_flag(io_in_bits_uop_robIdx_flag),
    .io_in_bits_uop_robIdx_value(io_in_bits_uop_robIdx_value),
    .io_in_bits_uop_debugInfo_eliminatedMove(io_in_bits_uop_debugInfo_eliminatedMove),
    .io_in_bits_uop_debugInfo_renameTime(io_in_bits_uop_debugInfo_renameTime),
    .io_in_bits_uop_debugInfo_dispatchTime(io_in_bits_uop_debugInfo_dispatchTime),
    .io_in_bits_uop_debugInfo_enqRsTime(io_in_bits_uop_debugInfo_enqRsTime),
    .io_in_bits_uop_debugInfo_selectTime(io_in_bits_uop_debugInfo_selectTime),
    .io_in_bits_uop_debugInfo_issueTime(io_in_bits_uop_debugInfo_issueTime),
    .io_in_bits_uop_debugInfo_writebackTime(io_in_bits_uop_debugInfo_writebackTime),
    .io_in_bits_uop_debugInfo_runahead_checkpoint_id(io_in_bits_uop_debugInfo_runahead_checkpoint_id),
    .io_in_bits_uop_debugInfo_tlbFirstReqTime(io_in_bits_uop_debugInfo_tlbFirstReqTime),
    .io_in_bits_uop_debugInfo_tlbRespTime(io_in_bits_uop_debugInfo_tlbRespTime),
    .io_in_bits_uop_debug_seqNum_seqNum(io_in_bits_uop_debug_seqNum_seqNum),
    .io_in_bits_uop_debug_seqNum_uopIdx(io_in_bits_uop_debug_seqNum_uopIdx),
    .io_in_bits_uop_lqIdx_flag(io_in_bits_uop_lqIdx_flag),
    .io_in_bits_uop_lqIdx_value(io_in_bits_uop_lqIdx_value),
    .io_in_bits_uop_sqIdx_flag(io_in_bits_uop_sqIdx_flag),
    .io_in_bits_uop_sqIdx_value(io_in_bits_uop_sqIdx_value),
    .io_in_bits_src_0(io_in_bits_src_0),
    .io_storeDataIn_0_valid(io_storeDataIn_0_valid),
    .io_storeDataIn_0_bits_uop_fuOpType(io_storeDataIn_0_bits_uop_fuOpType),
    .io_storeDataIn_0_bits_data(io_storeDataIn_0_bits_data),
    .io_storeDataIn_1_valid(io_storeDataIn_1_valid),
    .io_storeDataIn_1_bits_uop_fuOpType(io_storeDataIn_1_bits_uop_fuOpType),
    .io_storeDataIn_1_bits_data(io_storeDataIn_1_bits_data),
    .io_out_ready(io_out_ready),
    .io_dcache_req_ready(io_dcache_req_ready),
    .io_dcache_resp_valid(io_dcache_resp_valid),
    .io_dcache_resp_bits_data(io_dcache_resp_bits_data),
    .io_dcache_resp_bits_miss(io_dcache_resp_bits_miss),
    .io_dcache_resp_bits_replay(io_dcache_resp_bits_replay),
    .io_dcache_resp_bits_tl_error_tl_denied(io_dcache_resp_bits_tl_error_tl_denied),
    .io_dcache_resp_bits_tl_error_tl_corrupt(io_dcache_resp_bits_tl_error_tl_corrupt),
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
    .io_out_bits_uop_exceptionVec_19(g_io_out_bits_uop_exceptionVec_19),
    .io_out_bits_uop_exceptionVec_21(g_io_out_bits_uop_exceptionVec_21),
    .io_out_bits_uop_exceptionVec_23(g_io_out_bits_uop_exceptionVec_23),
    .io_out_bits_uop_trigger(g_io_out_bits_uop_trigger),
    .io_out_bits_uop_rfWen(g_io_out_bits_uop_rfWen),
    .io_out_bits_uop_pdest(g_io_out_bits_uop_pdest),
    .io_out_bits_uop_robIdx_flag(g_io_out_bits_uop_robIdx_flag),
    .io_out_bits_uop_robIdx_value(g_io_out_bits_uop_robIdx_value),
    .io_out_bits_uop_debugInfo_eliminatedMove(g_io_out_bits_uop_debugInfo_eliminatedMove),
    .io_out_bits_uop_debugInfo_renameTime(g_io_out_bits_uop_debugInfo_renameTime),
    .io_out_bits_uop_debugInfo_dispatchTime(g_io_out_bits_uop_debugInfo_dispatchTime),
    .io_out_bits_uop_debugInfo_enqRsTime(g_io_out_bits_uop_debugInfo_enqRsTime),
    .io_out_bits_uop_debugInfo_selectTime(g_io_out_bits_uop_debugInfo_selectTime),
    .io_out_bits_uop_debugInfo_issueTime(g_io_out_bits_uop_debugInfo_issueTime),
    .io_out_bits_uop_debugInfo_writebackTime(g_io_out_bits_uop_debugInfo_writebackTime),
    .io_out_bits_uop_debugInfo_runahead_checkpoint_id(g_io_out_bits_uop_debugInfo_runahead_checkpoint_id),
    .io_out_bits_uop_debugInfo_tlbFirstReqTime(g_io_out_bits_uop_debugInfo_tlbFirstReqTime),
    .io_out_bits_uop_debugInfo_tlbRespTime(g_io_out_bits_uop_debugInfo_tlbRespTime),
    .io_out_bits_uop_debug_seqNum_seqNum(g_io_out_bits_uop_debug_seqNum_seqNum),
    .io_out_bits_uop_debug_seqNum_uopIdx(g_io_out_bits_uop_debug_seqNum_uopIdx),
    .io_out_bits_uop_lqIdx_flag(g_io_out_bits_uop_lqIdx_flag),
    .io_out_bits_uop_lqIdx_value(g_io_out_bits_uop_lqIdx_value),
    .io_out_bits_data(g_io_out_bits_data),
    .io_out_bits_debug_isMMIO(g_io_out_bits_debug_isMMIO),
    .io_out_bits_debug_paddr(g_io_out_bits_debug_paddr),
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
    .io_feedbackSlow_bits_robIdx_flag(g_io_feedbackSlow_bits_robIdx_flag),
    .io_feedbackSlow_bits_robIdx_value(g_io_feedbackSlow_bits_robIdx_value),
    .io_feedbackSlow_bits_sqIdx_flag(g_io_feedbackSlow_bits_sqIdx_flag),
    .io_feedbackSlow_bits_sqIdx_value(g_io_feedbackSlow_bits_sqIdx_value),
    .io_feedbackSlow_bits_lqIdx_flag(g_io_feedbackSlow_bits_lqIdx_flag),
    .io_feedbackSlow_bits_lqIdx_value(g_io_feedbackSlow_bits_lqIdx_value),
    .io_exceptionInfo_valid(g_io_exceptionInfo_valid),
    .io_exceptionInfo_bits_vaddr(g_io_exceptionInfo_bits_vaddr),
    .io_exceptionInfo_bits_gpaddr(g_io_exceptionInfo_bits_gpaddr),
    .io_exceptionInfo_bits_isForVSnonLeafPTE(g_io_exceptionInfo_bits_isForVSnonLeafPTE),
    .gatewayIn_packed_46_bore(g_gatewayIn_packed_46_bore),
    .gatewayIn_packed_47_bore(g_gatewayIn_packed_47_bore)
  );
  AtomicsUnit_xs u_i (
    .clock(clock),
    .reset(reset),
    .io_hartId(io_hartId),
    .io_in_valid(io_in_valid),
    .io_in_bits_uop_fuOpType(io_in_bits_uop_fuOpType),
    .io_in_bits_uop_rfWen(io_in_bits_uop_rfWen),
    .io_in_bits_uop_pdest(io_in_bits_uop_pdest),
    .io_in_bits_uop_robIdx_flag(io_in_bits_uop_robIdx_flag),
    .io_in_bits_uop_robIdx_value(io_in_bits_uop_robIdx_value),
    .io_in_bits_uop_debugInfo_eliminatedMove(io_in_bits_uop_debugInfo_eliminatedMove),
    .io_in_bits_uop_debugInfo_renameTime(io_in_bits_uop_debugInfo_renameTime),
    .io_in_bits_uop_debugInfo_dispatchTime(io_in_bits_uop_debugInfo_dispatchTime),
    .io_in_bits_uop_debugInfo_enqRsTime(io_in_bits_uop_debugInfo_enqRsTime),
    .io_in_bits_uop_debugInfo_selectTime(io_in_bits_uop_debugInfo_selectTime),
    .io_in_bits_uop_debugInfo_issueTime(io_in_bits_uop_debugInfo_issueTime),
    .io_in_bits_uop_debugInfo_writebackTime(io_in_bits_uop_debugInfo_writebackTime),
    .io_in_bits_uop_debugInfo_runahead_checkpoint_id(io_in_bits_uop_debugInfo_runahead_checkpoint_id),
    .io_in_bits_uop_debugInfo_tlbFirstReqTime(io_in_bits_uop_debugInfo_tlbFirstReqTime),
    .io_in_bits_uop_debugInfo_tlbRespTime(io_in_bits_uop_debugInfo_tlbRespTime),
    .io_in_bits_uop_debug_seqNum_seqNum(io_in_bits_uop_debug_seqNum_seqNum),
    .io_in_bits_uop_debug_seqNum_uopIdx(io_in_bits_uop_debug_seqNum_uopIdx),
    .io_in_bits_uop_lqIdx_flag(io_in_bits_uop_lqIdx_flag),
    .io_in_bits_uop_lqIdx_value(io_in_bits_uop_lqIdx_value),
    .io_in_bits_uop_sqIdx_flag(io_in_bits_uop_sqIdx_flag),
    .io_in_bits_uop_sqIdx_value(io_in_bits_uop_sqIdx_value),
    .io_in_bits_src_0(io_in_bits_src_0),
    .io_storeDataIn_0_valid(io_storeDataIn_0_valid),
    .io_storeDataIn_0_bits_uop_fuOpType(io_storeDataIn_0_bits_uop_fuOpType),
    .io_storeDataIn_0_bits_data(io_storeDataIn_0_bits_data),
    .io_storeDataIn_1_valid(io_storeDataIn_1_valid),
    .io_storeDataIn_1_bits_uop_fuOpType(io_storeDataIn_1_bits_uop_fuOpType),
    .io_storeDataIn_1_bits_data(io_storeDataIn_1_bits_data),
    .io_out_ready(io_out_ready),
    .io_dcache_req_ready(io_dcache_req_ready),
    .io_dcache_resp_valid(io_dcache_resp_valid),
    .io_dcache_resp_bits_data(io_dcache_resp_bits_data),
    .io_dcache_resp_bits_miss(io_dcache_resp_bits_miss),
    .io_dcache_resp_bits_replay(io_dcache_resp_bits_replay),
    .io_dcache_resp_bits_tl_error_tl_denied(io_dcache_resp_bits_tl_error_tl_denied),
    .io_dcache_resp_bits_tl_error_tl_corrupt(io_dcache_resp_bits_tl_error_tl_corrupt),
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
    .io_out_bits_uop_exceptionVec_19(i_io_out_bits_uop_exceptionVec_19),
    .io_out_bits_uop_exceptionVec_21(i_io_out_bits_uop_exceptionVec_21),
    .io_out_bits_uop_exceptionVec_23(i_io_out_bits_uop_exceptionVec_23),
    .io_out_bits_uop_trigger(i_io_out_bits_uop_trigger),
    .io_out_bits_uop_rfWen(i_io_out_bits_uop_rfWen),
    .io_out_bits_uop_pdest(i_io_out_bits_uop_pdest),
    .io_out_bits_uop_robIdx_flag(i_io_out_bits_uop_robIdx_flag),
    .io_out_bits_uop_robIdx_value(i_io_out_bits_uop_robIdx_value),
    .io_out_bits_uop_debugInfo_eliminatedMove(i_io_out_bits_uop_debugInfo_eliminatedMove),
    .io_out_bits_uop_debugInfo_renameTime(i_io_out_bits_uop_debugInfo_renameTime),
    .io_out_bits_uop_debugInfo_dispatchTime(i_io_out_bits_uop_debugInfo_dispatchTime),
    .io_out_bits_uop_debugInfo_enqRsTime(i_io_out_bits_uop_debugInfo_enqRsTime),
    .io_out_bits_uop_debugInfo_selectTime(i_io_out_bits_uop_debugInfo_selectTime),
    .io_out_bits_uop_debugInfo_issueTime(i_io_out_bits_uop_debugInfo_issueTime),
    .io_out_bits_uop_debugInfo_writebackTime(i_io_out_bits_uop_debugInfo_writebackTime),
    .io_out_bits_uop_debugInfo_runahead_checkpoint_id(i_io_out_bits_uop_debugInfo_runahead_checkpoint_id),
    .io_out_bits_uop_debugInfo_tlbFirstReqTime(i_io_out_bits_uop_debugInfo_tlbFirstReqTime),
    .io_out_bits_uop_debugInfo_tlbRespTime(i_io_out_bits_uop_debugInfo_tlbRespTime),
    .io_out_bits_uop_debug_seqNum_seqNum(i_io_out_bits_uop_debug_seqNum_seqNum),
    .io_out_bits_uop_debug_seqNum_uopIdx(i_io_out_bits_uop_debug_seqNum_uopIdx),
    .io_out_bits_uop_lqIdx_flag(i_io_out_bits_uop_lqIdx_flag),
    .io_out_bits_uop_lqIdx_value(i_io_out_bits_uop_lqIdx_value),
    .io_out_bits_data(i_io_out_bits_data),
    .io_out_bits_debug_isMMIO(i_io_out_bits_debug_isMMIO),
    .io_out_bits_debug_paddr(i_io_out_bits_debug_paddr),
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
    .io_feedbackSlow_bits_robIdx_flag(i_io_feedbackSlow_bits_robIdx_flag),
    .io_feedbackSlow_bits_robIdx_value(i_io_feedbackSlow_bits_robIdx_value),
    .io_feedbackSlow_bits_sqIdx_flag(i_io_feedbackSlow_bits_sqIdx_flag),
    .io_feedbackSlow_bits_sqIdx_value(i_io_feedbackSlow_bits_sqIdx_value),
    .io_feedbackSlow_bits_lqIdx_flag(i_io_feedbackSlow_bits_lqIdx_flag),
    .io_feedbackSlow_bits_lqIdx_value(i_io_feedbackSlow_bits_lqIdx_value),
    .io_exceptionInfo_valid(i_io_exceptionInfo_valid),
    .io_exceptionInfo_bits_vaddr(i_io_exceptionInfo_bits_vaddr),
    .io_exceptionInfo_bits_gpaddr(i_io_exceptionInfo_bits_gpaddr),
    .io_exceptionInfo_bits_isForVSnonLeafPTE(i_io_exceptionInfo_bits_isForVSnonLeafPTE),
    .gatewayIn_packed_46_bore(i_gatewayIn_packed_46_bore),
    .gatewayIn_packed_47_bore(i_gatewayIn_packed_47_bore)
  );
  localparam int N_OUT = 62;
  bit seen0 [N_OUT];  // 该输出出现过"某位为 0"
  bit seen1 [N_OUT];  // 该输出出现过"某位为 1"
  `define CMP(k, g, i, nm) \
    begin checks++; if ((g) !== (i)) begin errors++; \
      if (errors <= 30) $display("[%0d] MISMATCH %s golden=%h impl=%h", cyc, nm, (g), (i)); end \
      if (|(g)) seen1[k] = 1; if (!(&(g))) seen0[k] = 1; end
  task automatic compare_all();
    `CMP(0, g_io_in_ready, i_io_in_ready, "io_in_ready")
    `CMP(1, g_io_out_valid, i_io_out_valid, "io_out_valid")
    `CMP(2, g_io_out_bits_uop_exceptionVec_3, i_io_out_bits_uop_exceptionVec_3, "io_out_bits_uop_exceptionVec_3")
    `CMP(3, g_io_out_bits_uop_exceptionVec_4, i_io_out_bits_uop_exceptionVec_4, "io_out_bits_uop_exceptionVec_4")
    `CMP(4, g_io_out_bits_uop_exceptionVec_5, i_io_out_bits_uop_exceptionVec_5, "io_out_bits_uop_exceptionVec_5")
    `CMP(5, g_io_out_bits_uop_exceptionVec_6, i_io_out_bits_uop_exceptionVec_6, "io_out_bits_uop_exceptionVec_6")
    `CMP(6, g_io_out_bits_uop_exceptionVec_7, i_io_out_bits_uop_exceptionVec_7, "io_out_bits_uop_exceptionVec_7")
    `CMP(7, g_io_out_bits_uop_exceptionVec_13, i_io_out_bits_uop_exceptionVec_13, "io_out_bits_uop_exceptionVec_13")
    `CMP(8, g_io_out_bits_uop_exceptionVec_15, i_io_out_bits_uop_exceptionVec_15, "io_out_bits_uop_exceptionVec_15")
    `CMP(9, g_io_out_bits_uop_exceptionVec_19, i_io_out_bits_uop_exceptionVec_19, "io_out_bits_uop_exceptionVec_19")
    `CMP(10, g_io_out_bits_uop_exceptionVec_21, i_io_out_bits_uop_exceptionVec_21, "io_out_bits_uop_exceptionVec_21")
    `CMP(11, g_io_out_bits_uop_exceptionVec_23, i_io_out_bits_uop_exceptionVec_23, "io_out_bits_uop_exceptionVec_23")
    `CMP(12, g_io_out_bits_uop_trigger, i_io_out_bits_uop_trigger, "io_out_bits_uop_trigger")
    `CMP(13, g_io_out_bits_uop_rfWen, i_io_out_bits_uop_rfWen, "io_out_bits_uop_rfWen")
    `CMP(14, g_io_out_bits_uop_pdest, i_io_out_bits_uop_pdest, "io_out_bits_uop_pdest")
    `CMP(15, g_io_out_bits_uop_robIdx_flag, i_io_out_bits_uop_robIdx_flag, "io_out_bits_uop_robIdx_flag")
    `CMP(16, g_io_out_bits_uop_robIdx_value, i_io_out_bits_uop_robIdx_value, "io_out_bits_uop_robIdx_value")
    `CMP(17, g_io_out_bits_uop_debugInfo_eliminatedMove, i_io_out_bits_uop_debugInfo_eliminatedMove, "io_out_bits_uop_debugInfo_eliminatedMove")
    `CMP(18, g_io_out_bits_uop_debugInfo_renameTime, i_io_out_bits_uop_debugInfo_renameTime, "io_out_bits_uop_debugInfo_renameTime")
    `CMP(19, g_io_out_bits_uop_debugInfo_dispatchTime, i_io_out_bits_uop_debugInfo_dispatchTime, "io_out_bits_uop_debugInfo_dispatchTime")
    `CMP(20, g_io_out_bits_uop_debugInfo_enqRsTime, i_io_out_bits_uop_debugInfo_enqRsTime, "io_out_bits_uop_debugInfo_enqRsTime")
    `CMP(21, g_io_out_bits_uop_debugInfo_selectTime, i_io_out_bits_uop_debugInfo_selectTime, "io_out_bits_uop_debugInfo_selectTime")
    `CMP(22, g_io_out_bits_uop_debugInfo_issueTime, i_io_out_bits_uop_debugInfo_issueTime, "io_out_bits_uop_debugInfo_issueTime")
    `CMP(23, g_io_out_bits_uop_debugInfo_writebackTime, i_io_out_bits_uop_debugInfo_writebackTime, "io_out_bits_uop_debugInfo_writebackTime")
    `CMP(24, g_io_out_bits_uop_debugInfo_runahead_checkpoint_id, i_io_out_bits_uop_debugInfo_runahead_checkpoint_id, "io_out_bits_uop_debugInfo_runahead_checkpoint_id")
    `CMP(25, g_io_out_bits_uop_debugInfo_tlbFirstReqTime, i_io_out_bits_uop_debugInfo_tlbFirstReqTime, "io_out_bits_uop_debugInfo_tlbFirstReqTime")
    `CMP(26, g_io_out_bits_uop_debugInfo_tlbRespTime, i_io_out_bits_uop_debugInfo_tlbRespTime, "io_out_bits_uop_debugInfo_tlbRespTime")
    `CMP(27, g_io_out_bits_uop_debug_seqNum_seqNum, i_io_out_bits_uop_debug_seqNum_seqNum, "io_out_bits_uop_debug_seqNum_seqNum")
    `CMP(28, g_io_out_bits_uop_debug_seqNum_uopIdx, i_io_out_bits_uop_debug_seqNum_uopIdx, "io_out_bits_uop_debug_seqNum_uopIdx")
    `CMP(29, g_io_out_bits_uop_lqIdx_flag, i_io_out_bits_uop_lqIdx_flag, "io_out_bits_uop_lqIdx_flag")
    `CMP(30, g_io_out_bits_uop_lqIdx_value, i_io_out_bits_uop_lqIdx_value, "io_out_bits_uop_lqIdx_value")
    `CMP(31, g_io_out_bits_data, i_io_out_bits_data, "io_out_bits_data")
    `CMP(32, g_io_out_bits_debug_isMMIO, i_io_out_bits_debug_isMMIO, "io_out_bits_debug_isMMIO")
    `CMP(33, g_io_out_bits_debug_paddr, i_io_out_bits_debug_paddr, "io_out_bits_debug_paddr")
    `CMP(34, g_io_dcache_req_valid, i_io_dcache_req_valid, "io_dcache_req_valid")
    `CMP(35, g_io_dcache_req_bits_cmd, i_io_dcache_req_bits_cmd, "io_dcache_req_bits_cmd")
    `CMP(36, g_io_dcache_req_bits_vaddr, i_io_dcache_req_bits_vaddr, "io_dcache_req_bits_vaddr")
    `CMP(37, g_io_dcache_req_bits_addr, i_io_dcache_req_bits_addr, "io_dcache_req_bits_addr")
    `CMP(38, g_io_dcache_req_bits_word_idx, i_io_dcache_req_bits_word_idx, "io_dcache_req_bits_word_idx")
    `CMP(39, g_io_dcache_req_bits_amo_data, i_io_dcache_req_bits_amo_data, "io_dcache_req_bits_amo_data")
    `CMP(40, g_io_dcache_req_bits_amo_mask, i_io_dcache_req_bits_amo_mask, "io_dcache_req_bits_amo_mask")
    `CMP(41, g_io_dcache_req_bits_amo_cmp, i_io_dcache_req_bits_amo_cmp, "io_dcache_req_bits_amo_cmp")
    `CMP(42, g_io_dtlb_req_valid, i_io_dtlb_req_valid, "io_dtlb_req_valid")
    `CMP(43, g_io_dtlb_req_bits_vaddr, i_io_dtlb_req_bits_vaddr, "io_dtlb_req_bits_vaddr")
    `CMP(44, g_io_dtlb_req_bits_fullva, i_io_dtlb_req_bits_fullva, "io_dtlb_req_bits_fullva")
    `CMP(45, g_io_dtlb_req_bits_cmd, i_io_dtlb_req_bits_cmd, "io_dtlb_req_bits_cmd")
    `CMP(46, g_io_dtlb_req_bits_debug_robIdx_flag, i_io_dtlb_req_bits_debug_robIdx_flag, "io_dtlb_req_bits_debug_robIdx_flag")
    `CMP(47, g_io_dtlb_req_bits_debug_robIdx_value, i_io_dtlb_req_bits_debug_robIdx_value, "io_dtlb_req_bits_debug_robIdx_value")
    `CMP(48, g_io_flush_sbuffer_valid, i_io_flush_sbuffer_valid, "io_flush_sbuffer_valid")
    `CMP(49, g_io_feedbackSlow_valid, i_io_feedbackSlow_valid, "io_feedbackSlow_valid")
    `CMP(50, g_io_feedbackSlow_bits_robIdx_flag, i_io_feedbackSlow_bits_robIdx_flag, "io_feedbackSlow_bits_robIdx_flag")
    `CMP(51, g_io_feedbackSlow_bits_robIdx_value, i_io_feedbackSlow_bits_robIdx_value, "io_feedbackSlow_bits_robIdx_value")
    `CMP(52, g_io_feedbackSlow_bits_sqIdx_flag, i_io_feedbackSlow_bits_sqIdx_flag, "io_feedbackSlow_bits_sqIdx_flag")
    `CMP(53, g_io_feedbackSlow_bits_sqIdx_value, i_io_feedbackSlow_bits_sqIdx_value, "io_feedbackSlow_bits_sqIdx_value")
    `CMP(54, g_io_feedbackSlow_bits_lqIdx_flag, i_io_feedbackSlow_bits_lqIdx_flag, "io_feedbackSlow_bits_lqIdx_flag")
    `CMP(55, g_io_feedbackSlow_bits_lqIdx_value, i_io_feedbackSlow_bits_lqIdx_value, "io_feedbackSlow_bits_lqIdx_value")
    `CMP(56, g_io_exceptionInfo_valid, i_io_exceptionInfo_valid, "io_exceptionInfo_valid")
    `CMP(57, g_io_exceptionInfo_bits_vaddr, i_io_exceptionInfo_bits_vaddr, "io_exceptionInfo_bits_vaddr")
    `CMP(58, g_io_exceptionInfo_bits_gpaddr, i_io_exceptionInfo_bits_gpaddr, "io_exceptionInfo_bits_gpaddr")
    `CMP(59, g_io_exceptionInfo_bits_isForVSnonLeafPTE, i_io_exceptionInfo_bits_isForVSnonLeafPTE, "io_exceptionInfo_bits_isForVSnonLeafPTE")
    `CMP(60, g_gatewayIn_packed_46_bore, i_gatewayIn_packed_46_bore, "gatewayIn_packed_46_bore")
    `CMP(61, g_gatewayIn_packed_47_bore, i_gatewayIn_packed_47_bore, "gatewayIn_packed_47_bore")
  endtask
  task automatic rand_inputs();  // 时钟/复位不在其中
    io_hartId = 6'($urandom);
    io_in_valid = 1'($urandom);
    io_in_bits_uop_fuOpType = 9'($urandom);
    io_in_bits_uop_rfWen = 1'($urandom);
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
    io_in_bits_src_0 = 64'({$urandom, $urandom});
    io_storeDataIn_0_valid = 1'($urandom);
    io_storeDataIn_0_bits_uop_fuOpType = 9'($urandom);
    io_storeDataIn_0_bits_data = 64'({$urandom, $urandom});
    io_storeDataIn_1_valid = 1'($urandom);
    io_storeDataIn_1_bits_uop_fuOpType = 9'($urandom);
    io_storeDataIn_1_bits_data = 64'({$urandom, $urandom});
    io_out_ready = 1'($urandom);
    io_dcache_req_ready = 1'($urandom);
    io_dcache_resp_valid = 1'($urandom);
    io_dcache_resp_bits_data = 128'({$urandom, $urandom, $urandom, $urandom});
    io_dcache_resp_bits_miss = 1'($urandom);
    io_dcache_resp_bits_replay = 1'($urandom);
    io_dcache_resp_bits_tl_error_tl_denied = 1'($urandom);
    io_dcache_resp_bits_tl_error_tl_corrupt = 1'($urandom);
    io_dcache_resp_bits_id = 6'($urandom);
    io_dcache_block_lr = 1'($urandom);
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
    io_pmpResp_mmio = 1'($urandom);
    io_flush_sbuffer_empty = 1'($urandom);
    io_redirect_valid = 1'($urandom);
    io_csrCtrl_cache_error_enable = 1'($urandom);
    io_csrCtrl_mem_trigger_tUpdate_valid = 1'($urandom);
    io_csrCtrl_mem_trigger_tUpdate_bits_addr = 2'($urandom);
    io_csrCtrl_mem_trigger_tUpdate_bits_tdata_matchType = 2'($urandom);
    io_csrCtrl_mem_trigger_tUpdate_bits_tdata_select = 1'($urandom);
    io_csrCtrl_mem_trigger_tUpdate_bits_tdata_action = 4'($urandom);
    io_csrCtrl_mem_trigger_tUpdate_bits_tdata_chain = 1'($urandom);
    io_csrCtrl_mem_trigger_tUpdate_bits_tdata_store = 1'($urandom);
    io_csrCtrl_mem_trigger_tUpdate_bits_tdata_load = 1'($urandom);
    io_csrCtrl_mem_trigger_tUpdate_bits_tdata_tdata2 = 64'({$urandom, $urandom});
    io_csrCtrl_mem_trigger_tEnableVec_0 = 1'($urandom);
    io_csrCtrl_mem_trigger_tEnableVec_1 = 1'($urandom);
    io_csrCtrl_mem_trigger_tEnableVec_2 = 1'($urandom);
    io_csrCtrl_mem_trigger_tEnableVec_3 = 1'($urandom);
    io_csrCtrl_mem_trigger_debugMode = 1'($urandom);
    io_csrCtrl_mem_trigger_triggerCanRaiseBpExp = 1'($urandom);
  endtask

  // ---------------------------------------------------------------------------
  // 事务生成器
  // ---------------------------------------------------------------------------
  localparam int NOPS = 25;
  logic [5:0] OPS [NOPS] = '{6'h02, 6'h03, 6'h06, 6'h07, 6'h0A, 6'h0B, 6'h0E, 6'h0F, 6'h12, 6'h13,
                             6'h16, 6'h17, 6'h1A, 6'h1B, 6'h1E, 6'h1F, 6'h22, 6'h23, 6'h26, 6'h27,
                             6'h2A, 6'h2B, 6'h2E, 6'h2F, 6'h2C};
  logic [63:0] ADDR_POOL [8];

  typedef enum int {T_IDLE, T_STA0, T_RUN} tphase_e;
  tphase_e tphase = T_IDLE;
  logic [5:0] cur_op;
  int   std_need;            // 还需发出的 std 个数（按 uopIdx 顺序）
  int   std_next;            // 下一个要发的 uopIdx
  bit   sta2_pending;        // CASQ 第二个 sta 还没发
  int   wb_left;             // 还要等几次写回
  int   age;                 // 本条指令已跑拍数
  bit   force_mode = 0;      // 暖机：所有握手都给 1，异常全关

  int cov_state [9];
  int cov_op [NOPS];
  int cov_early_finish, cov_pm_exc, cov_replay, cov_mmio, cov_trig, cov_finish2, cov_insts;
  int cov_illegal;
  logic [3:0] prev_state;

  function automatic int op_index(logic [5:0] op);
    for (int i = 0; i < NOPS; i++) if (OPS[i] == op) return i;
    return -1;
  endfunction
  function automatic int std_count(logic [5:0] op);
    if (op == 6'h2C) return 4;
    if (op == 6'h2E || op == 6'h2F) return 2;
    return 1;
  endfunction

  task automatic drive_env();
    // 环境输入（每拍重掷）
    rand_inputs();
    io_hartId = 6'd5;
    io_in_bits_src_0 = ADDR_POOL[$urandom_range(0, 7)];
    case ($urandom_range(0, 7))
      0: io_in_bits_src_0 = {$urandom, $urandom};                 // 任意地址（多半不对齐）
      1: io_in_bits_src_0[3:0] = 4'($urandom);                    // 池地址 + 低 4 位扰动
      2: io_in_bits_src_0[3:0] = 4'd8;                            // 8 对齐（D 对齐、Q 不对齐）
      3: io_in_bits_src_0[3:0] = 4'd4;                            // 4 对齐（W 对齐）
      default: ;                                                  // 16 对齐
    endcase
    if (force_mode) io_in_bits_src_0 = ADDR_POOL[$urandom_range(0, 7)];
    io_dtlb_resp_bits_fullva = ADDR_POOL[$urandom_range(0, 7)] ^ 64'($urandom_range(0, 15));
    io_dtlb_resp_valid  = force_mode ? 1'b1 : ($urandom_range(0, 2) != 0);
    io_dtlb_resp_bits_miss = force_mode ? 1'b0 : ($urandom_range(0, 9) < 3);
    {io_dtlb_resp_bits_excp_0_gpf_ld, io_dtlb_resp_bits_excp_0_gpf_st, io_dtlb_resp_bits_excp_0_pf_ld,
     io_dtlb_resp_bits_excp_0_pf_st, io_dtlb_resp_bits_excp_0_af_ld, io_dtlb_resp_bits_excp_0_af_st} = '0;
    if (!force_mode) for (int i = 0; i < 6; i++) if ($urandom_range(0, 32) == 0) begin
      case (i)
        0: io_dtlb_resp_bits_excp_0_gpf_ld = 1; 1: io_dtlb_resp_bits_excp_0_gpf_st = 1;
        2: io_dtlb_resp_bits_excp_0_pf_ld = 1;  3: io_dtlb_resp_bits_excp_0_pf_st = 1;
        4: io_dtlb_resp_bits_excp_0_af_ld = 1;  default: io_dtlb_resp_bits_excp_0_af_st = 1;
      endcase
    end
    io_dtlb_resp_bits_pbmt_0 = force_mode ? 2'd0 : (($urandom_range(0, 3) == 0) ? 2'($urandom) : 2'd0);
    io_pmpResp_ld   = !force_mode && ($urandom_range(0, 24) == 0);
    io_pmpResp_st   = !force_mode && ($urandom_range(0, 24) == 0);
    io_pmpResp_mmio = !force_mode && ($urandom_range(0, 9) == 0);
    io_flush_sbuffer_empty = force_mode ? 1'b1 : ($urandom_range(0, 2) != 0);
    io_dcache_req_ready = force_mode ? 1'b1 : ($urandom_range(0, 1) == 0);
    io_dcache_block_lr  = !force_mode && ($urandom_range(0, 3) == 0);
    io_dcache_resp_valid = force_mode ? 1'b1 : ($urandom_range(0, 1) == 0);
    io_dcache_resp_bits_miss = !force_mode && ($urandom_range(0, 9) < 3);
    io_dcache_resp_bits_tl_error_tl_denied  = !force_mode && ($urandom_range(0, 9) == 0);
    io_dcache_resp_bits_tl_error_tl_corrupt = !force_mode && ($urandom_range(0, 9) == 0);
    io_out_ready = force_mode ? 1'b1 : ($urandom_range(0, 2) != 0);
    io_redirect_valid = !force_mode && ($urandom_range(0, 15) == 0);
    io_csrCtrl_mem_trigger_tUpdate_valid = ($urandom_range(0, 31) == 0);
    io_csrCtrl_mem_trigger_tUpdate_bits_tdata_tdata2 = ADDR_POOL[$urandom_range(0, 7)];
    io_csrCtrl_mem_trigger_tUpdate_bits_tdata_action = ($urandom_range(0, 2) == 0) ? 4'd1 : 4'($urandom_range(0, 1) ? 0 : $urandom);
    io_csrCtrl_mem_trigger_debugMode = ($urandom_range(0, 7) == 0);
    if (force_mode) begin
      {io_csrCtrl_mem_trigger_tEnableVec_3, io_csrCtrl_mem_trigger_tEnableVec_2,
       io_csrCtrl_mem_trigger_tEnableVec_1, io_csrCtrl_mem_trigger_tEnableVec_0} = '0;
      io_csrCtrl_mem_trigger_debugMode = 1'b0;
    end
    // sta / std 默认不发
    io_in_valid = 1'b0;
    io_storeDataIn_0_valid = 1'b0;
    io_storeDataIn_1_valid = 1'b0;
  endtask

  // 随机噪声：不在 fire 位置的 in_valid（in_ready=0 时被忽略）由事务层控制，不单独掷
  task automatic send_std(int idx, int port);
    if (port == 0) begin
      io_storeDataIn_0_valid = 1'b1;
      io_storeDataIn_0_bits_uop_fuOpType = {3'(idx), cur_op};
    end else begin
      io_storeDataIn_1_valid = 1'b1;
      io_storeDataIn_1_bits_uop_fuOpType = {3'(idx), cur_op};
    end
  endtask

  task automatic drive_txn();
    // 由上一拍采样到的握手推进事务；本拍设置 in / std 口
    case (tphase)
      T_IDLE: begin
        if (force_mode || $urandom_range(0, 3) == 0) begin
          if (!force_mode && $urandom_range(0, 15) == 0) begin
            cur_op = {OPS[$urandom_range(0, 21)][5:2], 2'd1};   // 非 CAS 的非法 size
            cov_illegal++;
          end else
            cur_op = OPS[$urandom_range(0, NOPS - 1)];
          tphase = T_STA0; std_need = std_count(cur_op); std_next = 0;
          sta2_pending = (cur_op == 6'h2C); wb_left = (cur_op == 6'h2C) ? 2 : 1; age = 0;
          cov_insts++;
        end
      end
      default: ;
    endcase
    if (tphase == T_STA0) begin
      io_in_valid = 1'b1;
      io_in_bits_uop_fuOpType = {3'd0, cur_op};
    end
    if (tphase == T_RUN) begin
      if (sta2_pending && ($urandom_range(0, 3) == 0)) begin
        io_in_valid = 1'b1;
        io_in_bits_uop_fuOpType = {3'd2, cur_op};
      end
      // std：随机 0/1/2 个，按顺序
      if (std_need > 0 && $urandom_range(0, 2) != 0) begin
        int p; p = $urandom_range(0, 1);
        send_std(std_next, p); std_next++; std_need--;
        if (std_need > 0 && $urandom_range(0, 1)) begin
          send_std(std_next, 1 - p); std_next++; std_need--;
        end
      end
    end
  endtask

  task automatic sample_txn();
    // 在时钟沿前按"已驱动的输入 × 当前输出"预测本沿握手，推进事务状态
    if (tphase == T_STA0 && io_in_valid && g_io_in_ready) begin
      tphase = T_RUN;
      if (warm_done && op_index(cur_op) >= 0) cov_op[op_index(cur_op)]++;
    end
    else if (tphase == T_RUN) begin
      if (io_in_valid && g_io_in_ready && io_in_bits_uop_fuOpType[8:6] == 3'd2) sta2_pending = 0;
      if (g_io_out_valid && io_out_ready) begin
        wb_left--;
        if (wb_left == 0) tphase = T_IDLE;
      end
    end
    if (tphase != T_IDLE) begin
      age++;
      if (age > 5000) begin
        $display("[%0d] TB HANG: op=%h phase=%0d state=%0d std_need=%0d sta2=%0d wb_left=%0d", cyc, cur_op, tphase,
                 u_g.state, std_need, sta2_pending, wb_left);
        errors++; tphase = T_IDLE;
      end
    end
  endtask

  initial begin
    clock = 0;
    forever #5 clock = ~clock;
  end

  initial begin
    int bad;
    if (!$value$plusargs("ncycles=%d", NCYCLES)) NCYCLES = 200000;
    for (int i = 0; i < 8; i++) ADDR_POOL[i] = {$urandom, $urandom} & 64'h0000_0000_FFFF_FFF0;
    ADDR_POOL[0] = 64'h0000_0000_8000_1000;
    reset = 1;
    drive_env(); io_in_valid = 0;
    repeat (3) @(posedge clock);
    #1 reset = 0;
    force_mode = 1;
    cyc = 0;
    // ---- 暖机：4 个触发器槽各更新一次，然后 4 个 std 槽各写一次，然后跑一条 AMOCAS.Q + 一条 LR ----
    for (int j = 0; j < 4; j++) begin
      @(negedge clock);
      drive_env();
      io_csrCtrl_mem_trigger_tUpdate_valid = 1; io_csrCtrl_mem_trigger_tUpdate_bits_addr = 2'(j);
      cyc++;
    end
    begin
      @(negedge clock); drive_env(); cur_op = 6'h2C; send_std(0, 0); send_std(1, 1); cyc++;
      @(negedge clock); drive_env(); send_std(2, 0); send_std(3, 1); cyc++;
    end
    // 一条 AMOCAS.Q：sta0 → sta2 → 4 std → 两次写回
    begin
      int guard;
      @(negedge clock); drive_env(); cyc++;
      cur_op = 6'h2C; tphase = T_STA0; std_need = 4; std_next = 0; sta2_pending = 1; wb_left = 2; age = 0;
      guard = 0;
      while (tphase != T_IDLE && guard < 500) begin
        @(negedge clock); drive_env(); drive_txn(); sample_txn(); cyc++; guard++;
      end
      if (tphase != T_IDLE) begin $display("WARM CASQ did not finish"); errors++; end
      cur_op = 6'h02; tphase = T_STA0; std_need = 1; std_next = 0; sta2_pending = 0; wb_left = 1; age = 0;
      guard = 0;
      while (tphase != T_IDLE && guard < 500) begin
        @(negedge clock); drive_env(); drive_txn(); sample_txn(); cyc++; guard++;
      end
      if (tphase != T_IDLE) begin $display("WARM LR did not finish"); errors++; end
    end
    force_mode = 0;
    warm_done = 1;
    $display("WARM_DONE at cyc=%0d", cyc);
    prev_state = u_g.state;
    // ---- 主循环 ----
    while (cyc < NCYCLES) begin
      @(negedge clock);
      compare_all();
      // 覆盖
      cov_state[u_g.state]++;
      if (u_g.state == 4'd7 && prev_state == 4'd1) cov_early_finish++;
      if (u_g.state == 4'd7 && prev_state == 4'd2) cov_pm_exc++;
      if (u_g.state == 4'd4 && prev_state == 4'd5) cov_replay++;
      if (g_io_out_valid && io_out_ready && g_io_out_bits_debug_isMMIO) cov_mmio++;
      if (g_io_out_valid && io_out_ready && g_io_out_bits_uop_trigger != 4'hF) cov_trig++;
      if (g_io_out_valid && io_out_ready && u_g.state == 4'd8) cov_finish2++;
      prev_state = u_g.state;
      drive_env();
      drive_txn();
      sample_txn();   // 用刚驱动的输入 + 当前输出预测下一个时钟沿的握手
      cyc++;
    end
    bad = 0;
    for (int s = 0; s < 9; s++) begin
      $display("cov state %0d : %0d", s, cov_state[s]);
      if (cov_state[s] < 100) bad++;
    end
    for (int i = 0; i < NOPS; i++) begin
      $display("cov op %h : %0d", OPS[i], cov_op[i]);
      if (cov_op[i] < 20) bad++;
    end
    $display("cov insts=%0d illegal=%0d early_finish=%0d pm_exc=%0d replay=%0d mmio=%0d trig=%0d finish2=%0d",
             cov_insts, cov_illegal, cov_early_finish, cov_pm_exc, cov_replay, cov_mmio, cov_trig, cov_finish2);
    if (cov_early_finish < 20 || cov_pm_exc < 20 || cov_replay < 20 || cov_mmio < 20 || cov_trig < 20 ||
        cov_finish2 < 20) bad++;
    for (int o = 0; o < N_OUT; o++) if (!seen0[o] || !seen1[o]) begin bad++; $display("output %0d stuck", o); end
    $display("checks=%0d errors=%0d bad_cov=%0d", checks, errors, bad);
    if (errors == 0 && checks > 1000 && bad == 0) $display("TEST PASSED");
    else $display("TEST FAILED");
    $finish;
  end
endmodule
