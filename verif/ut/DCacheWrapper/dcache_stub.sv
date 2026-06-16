// 自动生成：scripts/gen_dcachewrapper.py —— 勿手改
// 内层 DCache 黑盒桩：UT 两侧共用，驱动 perf 计数以激励包装层 perf 流水。
module DCache(
  input  clock,
  input  reset,
  output auto_cacheCtrlOpt_in_a_ready,
  input  auto_cacheCtrlOpt_in_a_valid,
  input  [3:0] auto_cacheCtrlOpt_in_a_bits_opcode,
  input  [1:0] auto_cacheCtrlOpt_in_a_bits_size,
  input  [1:0] auto_cacheCtrlOpt_in_a_bits_source,
  input  [29:0] auto_cacheCtrlOpt_in_a_bits_address,
  input  [7:0] auto_cacheCtrlOpt_in_a_bits_mask,
  input  [63:0] auto_cacheCtrlOpt_in_a_bits_data,
  input  auto_cacheCtrlOpt_in_d_ready,
  output auto_cacheCtrlOpt_in_d_valid,
  output [3:0] auto_cacheCtrlOpt_in_d_bits_opcode,
  output [1:0] auto_cacheCtrlOpt_in_d_bits_size,
  output [1:0] auto_cacheCtrlOpt_in_d_bits_source,
  output [63:0] auto_cacheCtrlOpt_in_d_bits_data,
  input  auto_client_out_a_ready,
  output auto_client_out_a_valid,
  output [3:0] auto_client_out_a_bits_opcode,
  output [2:0] auto_client_out_a_bits_param,
  output [2:0] auto_client_out_a_bits_size,
  output [5:0] auto_client_out_a_bits_source,
  output [47:0] auto_client_out_a_bits_address,
  output [1:0] auto_client_out_a_bits_user_alias,
  output [43:0] auto_client_out_a_bits_user_vaddr,
  output [4:0] auto_client_out_a_bits_user_reqSource,
  output auto_client_out_a_bits_user_needHint,
  output auto_client_out_a_bits_echo_isKeyword,
  output [31:0] auto_client_out_a_bits_mask,
  output auto_client_out_b_ready,
  input  auto_client_out_b_valid,
  input  [2:0] auto_client_out_b_bits_opcode,
  input  [1:0] auto_client_out_b_bits_param,
  input  [47:0] auto_client_out_b_bits_address,
  input  [255:0] auto_client_out_b_bits_data,
  input  auto_client_out_c_ready,
  output auto_client_out_c_valid,
  output [2:0] auto_client_out_c_bits_opcode,
  output [2:0] auto_client_out_c_bits_param,
  output [2:0] auto_client_out_c_bits_size,
  output [5:0] auto_client_out_c_bits_source,
  output [47:0] auto_client_out_c_bits_address,
  output [255:0] auto_client_out_c_bits_data,
  output auto_client_out_c_bits_corrupt,
  output auto_client_out_d_ready,
  input  auto_client_out_d_valid,
  input  [3:0] auto_client_out_d_bits_opcode,
  input  [1:0] auto_client_out_d_bits_param,
  input  [2:0] auto_client_out_d_bits_size,
  input  [5:0] auto_client_out_d_bits_source,
  input  [9:0] auto_client_out_d_bits_sink,
  input  auto_client_out_d_bits_denied,
  input  auto_client_out_d_bits_echo_isKeyword,
  input  [255:0] auto_client_out_d_bits_data,
  input  auto_client_out_d_bits_corrupt,
  input  auto_client_out_e_ready,
  output auto_client_out_e_valid,
  output [9:0] auto_client_out_e_bits_sink,
  input  io_l2_pf_store_only,
  output io_lsu_load_0_req_ready,
  input  io_lsu_load_0_req_valid,
  input  [4:0] io_lsu_load_0_req_bits_cmd,
  input  [49:0] io_lsu_load_0_req_bits_vaddr,
  input  [49:0] io_lsu_load_0_req_bits_vaddr_dup,
  input  [3:0] io_lsu_load_0_req_bits_instrtype,
  input  io_lsu_load_0_req_bits_isFirstIssue,
  input  io_lsu_load_0_req_bits_lqIdx_flag,
  input  [6:0] io_lsu_load_0_req_bits_lqIdx_value,
  output io_lsu_load_0_resp_valid,
  output [127:0] io_lsu_load_0_resp_bits_data,
  output [127:0] io_lsu_load_0_resp_bits_data_delayed,
  output io_lsu_load_0_resp_bits_miss,
  output [3:0] io_lsu_load_0_resp_bits_mshr_id,
  output [2:0] io_lsu_load_0_resp_bits_meta_prefetch,
  output io_lsu_load_0_resp_bits_handled,
  output io_lsu_load_0_resp_bits_error_delayed,
  input  io_lsu_load_0_s1_kill,
  input  io_lsu_load_0_s2_kill,
  input  io_lsu_load_0_is128Req,
  input  [2:0] io_lsu_load_0_pf_source,
  input  [47:0] io_lsu_load_0_s1_paddr_dup_lsu,
  input  [47:0] io_lsu_load_0_s1_paddr_dup_dcache,
  output io_lsu_load_0_s2_bank_conflict,
  output io_lsu_load_0_s2_mq_nack,
  output io_lsu_load_1_req_ready,
  input  io_lsu_load_1_req_valid,
  input  [4:0] io_lsu_load_1_req_bits_cmd,
  input  [49:0] io_lsu_load_1_req_bits_vaddr,
  input  [49:0] io_lsu_load_1_req_bits_vaddr_dup,
  input  [3:0] io_lsu_load_1_req_bits_instrtype,
  input  io_lsu_load_1_req_bits_isFirstIssue,
  input  io_lsu_load_1_req_bits_lqIdx_flag,
  input  [6:0] io_lsu_load_1_req_bits_lqIdx_value,
  output io_lsu_load_1_resp_valid,
  output [127:0] io_lsu_load_1_resp_bits_data,
  output io_lsu_load_1_resp_bits_miss,
  output [3:0] io_lsu_load_1_resp_bits_mshr_id,
  output [2:0] io_lsu_load_1_resp_bits_meta_prefetch,
  output io_lsu_load_1_resp_bits_handled,
  output io_lsu_load_1_resp_bits_error_delayed,
  input  io_lsu_load_1_s1_kill,
  input  io_lsu_load_1_s2_kill,
  input  io_lsu_load_1_is128Req,
  input  [2:0] io_lsu_load_1_pf_source,
  input  [47:0] io_lsu_load_1_s1_paddr_dup_lsu,
  input  [47:0] io_lsu_load_1_s1_paddr_dup_dcache,
  output io_lsu_load_1_s2_bank_conflict,
  output io_lsu_load_1_s2_mq_nack,
  output io_lsu_load_2_req_ready,
  input  io_lsu_load_2_req_valid,
  input  [4:0] io_lsu_load_2_req_bits_cmd,
  input  [49:0] io_lsu_load_2_req_bits_vaddr,
  input  [49:0] io_lsu_load_2_req_bits_vaddr_dup,
  input  [3:0] io_lsu_load_2_req_bits_instrtype,
  input  io_lsu_load_2_req_bits_isFirstIssue,
  input  io_lsu_load_2_req_bits_lqIdx_flag,
  input  [6:0] io_lsu_load_2_req_bits_lqIdx_value,
  output io_lsu_load_2_resp_valid,
  output [127:0] io_lsu_load_2_resp_bits_data,
  output io_lsu_load_2_resp_bits_miss,
  output [3:0] io_lsu_load_2_resp_bits_mshr_id,
  output [2:0] io_lsu_load_2_resp_bits_meta_prefetch,
  output io_lsu_load_2_resp_bits_handled,
  output io_lsu_load_2_resp_bits_error_delayed,
  input  io_lsu_load_2_s1_kill,
  input  io_lsu_load_2_s2_kill,
  input  io_lsu_load_2_is128Req,
  input  [2:0] io_lsu_load_2_pf_source,
  input  [47:0] io_lsu_load_2_s1_paddr_dup_lsu,
  input  [47:0] io_lsu_load_2_s1_paddr_dup_dcache,
  output io_lsu_load_2_s2_bank_conflict,
  output io_lsu_load_2_s2_mq_nack,
  input  io_lsu_sta_0_req_valid,
  input  io_lsu_sta_1_req_valid,
  output io_lsu_tl_d_channel_valid,
  output [3:0] io_lsu_tl_d_channel_mshrid,
  output io_lsu_store_req_ready,
  input  io_lsu_store_req_valid,
  input  [49:0] io_lsu_store_req_bits_vaddr,
  input  [47:0] io_lsu_store_req_bits_addr,
  input  [511:0] io_lsu_store_req_bits_data,
  input  [63:0] io_lsu_store_req_bits_mask,
  input  [5:0] io_lsu_store_req_bits_id,
  output io_lsu_store_main_pipe_hit_resp_valid,
  output [5:0] io_lsu_store_main_pipe_hit_resp_bits_id,
  output io_lsu_store_replay_resp_valid,
  output [5:0] io_lsu_store_replay_resp_bits_id,
  output io_lsu_atomics_req_ready,
  input  io_lsu_atomics_req_valid,
  input  [4:0] io_lsu_atomics_req_bits_cmd,
  input  [49:0] io_lsu_atomics_req_bits_vaddr,
  input  [47:0] io_lsu_atomics_req_bits_addr,
  input  [2:0] io_lsu_atomics_req_bits_word_idx,
  input  [127:0] io_lsu_atomics_req_bits_amo_data,
  input  [15:0] io_lsu_atomics_req_bits_amo_mask,
  input  [127:0] io_lsu_atomics_req_bits_amo_cmp,
  output io_lsu_atomics_resp_valid,
  output [127:0] io_lsu_atomics_resp_bits_data,
  output io_lsu_atomics_resp_bits_miss,
  output io_lsu_atomics_resp_bits_replay,
  output io_lsu_atomics_resp_bits_error,
  output [5:0] io_lsu_atomics_resp_bits_id,
  output io_lsu_atomics_block_lr,
  output io_lsu_release_valid,
  output [47:0] io_lsu_release_bits_paddr,
  output io_lsu_forward_D_0_valid,
  output [255:0] io_lsu_forward_D_0_data,
  output [3:0] io_lsu_forward_D_0_mshrid,
  output io_lsu_forward_D_0_last,
  output io_lsu_forward_D_0_corrupt,
  output io_lsu_forward_D_1_valid,
  output [255:0] io_lsu_forward_D_1_data,
  output [3:0] io_lsu_forward_D_1_mshrid,
  output io_lsu_forward_D_1_last,
  output io_lsu_forward_D_1_corrupt,
  output io_lsu_forward_D_2_valid,
  output [255:0] io_lsu_forward_D_2_data,
  output [3:0] io_lsu_forward_D_2_mshrid,
  output io_lsu_forward_D_2_last,
  output io_lsu_forward_D_2_corrupt,
  input  io_lsu_forward_mshr_0_valid,
  input  [3:0] io_lsu_forward_mshr_0_mshrid,
  input  [47:0] io_lsu_forward_mshr_0_paddr,
  output io_lsu_forward_mshr_0_forward_mshr,
  output [7:0] io_lsu_forward_mshr_0_forwardData_0,
  output [7:0] io_lsu_forward_mshr_0_forwardData_1,
  output [7:0] io_lsu_forward_mshr_0_forwardData_2,
  output [7:0] io_lsu_forward_mshr_0_forwardData_3,
  output [7:0] io_lsu_forward_mshr_0_forwardData_4,
  output [7:0] io_lsu_forward_mshr_0_forwardData_5,
  output [7:0] io_lsu_forward_mshr_0_forwardData_6,
  output [7:0] io_lsu_forward_mshr_0_forwardData_7,
  output [7:0] io_lsu_forward_mshr_0_forwardData_8,
  output [7:0] io_lsu_forward_mshr_0_forwardData_9,
  output [7:0] io_lsu_forward_mshr_0_forwardData_10,
  output [7:0] io_lsu_forward_mshr_0_forwardData_11,
  output [7:0] io_lsu_forward_mshr_0_forwardData_12,
  output [7:0] io_lsu_forward_mshr_0_forwardData_13,
  output [7:0] io_lsu_forward_mshr_0_forwardData_14,
  output [7:0] io_lsu_forward_mshr_0_forwardData_15,
  output io_lsu_forward_mshr_0_forward_result_valid,
  output io_lsu_forward_mshr_0_corrupt,
  input  io_lsu_forward_mshr_1_valid,
  input  [3:0] io_lsu_forward_mshr_1_mshrid,
  input  [47:0] io_lsu_forward_mshr_1_paddr,
  output io_lsu_forward_mshr_1_forward_mshr,
  output [7:0] io_lsu_forward_mshr_1_forwardData_0,
  output [7:0] io_lsu_forward_mshr_1_forwardData_1,
  output [7:0] io_lsu_forward_mshr_1_forwardData_2,
  output [7:0] io_lsu_forward_mshr_1_forwardData_3,
  output [7:0] io_lsu_forward_mshr_1_forwardData_4,
  output [7:0] io_lsu_forward_mshr_1_forwardData_5,
  output [7:0] io_lsu_forward_mshr_1_forwardData_6,
  output [7:0] io_lsu_forward_mshr_1_forwardData_7,
  output [7:0] io_lsu_forward_mshr_1_forwardData_8,
  output [7:0] io_lsu_forward_mshr_1_forwardData_9,
  output [7:0] io_lsu_forward_mshr_1_forwardData_10,
  output [7:0] io_lsu_forward_mshr_1_forwardData_11,
  output [7:0] io_lsu_forward_mshr_1_forwardData_12,
  output [7:0] io_lsu_forward_mshr_1_forwardData_13,
  output [7:0] io_lsu_forward_mshr_1_forwardData_14,
  output [7:0] io_lsu_forward_mshr_1_forwardData_15,
  output io_lsu_forward_mshr_1_forward_result_valid,
  output io_lsu_forward_mshr_1_corrupt,
  input  io_lsu_forward_mshr_2_valid,
  input  [3:0] io_lsu_forward_mshr_2_mshrid,
  input  [47:0] io_lsu_forward_mshr_2_paddr,
  output io_lsu_forward_mshr_2_forward_mshr,
  output [7:0] io_lsu_forward_mshr_2_forwardData_0,
  output [7:0] io_lsu_forward_mshr_2_forwardData_1,
  output [7:0] io_lsu_forward_mshr_2_forwardData_2,
  output [7:0] io_lsu_forward_mshr_2_forwardData_3,
  output [7:0] io_lsu_forward_mshr_2_forwardData_4,
  output [7:0] io_lsu_forward_mshr_2_forwardData_5,
  output [7:0] io_lsu_forward_mshr_2_forwardData_6,
  output [7:0] io_lsu_forward_mshr_2_forwardData_7,
  output [7:0] io_lsu_forward_mshr_2_forwardData_8,
  output [7:0] io_lsu_forward_mshr_2_forwardData_9,
  output [7:0] io_lsu_forward_mshr_2_forwardData_10,
  output [7:0] io_lsu_forward_mshr_2_forwardData_11,
  output [7:0] io_lsu_forward_mshr_2_forwardData_12,
  output [7:0] io_lsu_forward_mshr_2_forwardData_13,
  output [7:0] io_lsu_forward_mshr_2_forwardData_14,
  output [7:0] io_lsu_forward_mshr_2_forwardData_15,
  output io_lsu_forward_mshr_2_forward_result_valid,
  output io_lsu_forward_mshr_2_corrupt,
  output io_error_valid,
  output [47:0] io_error_bits_paddr,
  output io_error_bits_report_to_beu,
  input  io_lqEmpty,
  output io_pf_ctrl_enable,
  output io_pf_ctrl_confidence,
  output io_sms_agt_evict_req_valid,
  output [49:0] io_sms_agt_evict_req_bits_vaddr,
  input  io_debugTopDown_robHeadVaddr_valid,
  input  [49:0] io_debugTopDown_robHeadVaddr_bits,
  output io_debugTopDown_robHeadMissInDCache,
  input  io_l2_hint_valid,
  input  [3:0] io_l2_hint_bits_sourceId,
  output io_cmoOpReq_ready,
  input  io_cmoOpReq_valid,
  input  [2:0] io_cmoOpReq_bits_opcode,
  input  [63:0] io_cmoOpReq_bits_address,
  input  io_cmoOpResp_ready,
  output io_cmoOpResp_valid,
  output io_cmoOpResp_bits_nderr,
  output io_l1Miss,
  input  io_wfi_wfiReq,
  output io_wfi_wfiSafe,
  output [5:0] io_perf_0_value,
  output [5:0] io_perf_1_value,
  output [5:0] io_perf_2_value,
  output [5:0] io_perf_3_value,
  output [5:0] io_perf_4_value,
  output [5:0] io_perf_5_value,
  output [5:0] io_perf_6_value,
  output [5:0] io_perf_7_value,
  output [5:0] io_perf_8_value,
  output [5:0] io_perf_9_value,
  output [5:0] io_perf_10_value,
  output [5:0] io_perf_11_value,
  output [5:0] io_perf_12_value,
  output [5:0] io_perf_13_value,
  output [5:0] io_perf_14_value,
  output [5:0] io_perf_15_value,
  output [5:0] io_perf_16_value,
  output [5:0] io_perf_17_value,
  output [5:0] io_perf_18_value,
  output [5:0] io_perf_19_value,
  output [5:0] io_perf_20_value,
  output [5:0] io_perf_21_value,
  output [5:0] io_perf_22_value,
  output [5:0] io_perf_23_value,
  output [5:0] io_perf_24_value,
  output [5:0] io_perf_25_value,
  output [5:0] io_perf_26_value,
  output [5:0] io_perf_27_value,
  output [5:0] io_perf_28_value,
  output [5:0] io_perf_29_value,
  output [5:0] io_perf_30_value,
  output [5:0] io_perf_31_value,
  input  [4:0] boreChildrenBd_bore_array,
  input  boreChildrenBd_bore_all,
  input  boreChildrenBd_bore_req,
  output boreChildrenBd_bore_ack,
  input  boreChildrenBd_bore_writeen,
  input  boreChildrenBd_bore_be,
  input  [8:0] boreChildrenBd_bore_addr,
  input  [71:0] boreChildrenBd_bore_indata,
  input  boreChildrenBd_bore_readen,
  input  [8:0] boreChildrenBd_bore_addr_rd,
  output [71:0] boreChildrenBd_bore_outdata,
  input  [5:0] boreChildrenBd_bore_1_array,
  input  boreChildrenBd_bore_1_all,
  input  boreChildrenBd_bore_1_req,
  output boreChildrenBd_bore_1_ack,
  input  boreChildrenBd_bore_1_writeen,
  input  [1:0] boreChildrenBd_bore_1_be,
  input  [8:0] boreChildrenBd_bore_1_addr,
  input  [85:0] boreChildrenBd_bore_1_indata,
  input  boreChildrenBd_bore_1_readen,
  input  [8:0] boreChildrenBd_bore_1_addr_rd,
  output [85:0] boreChildrenBd_bore_1_outdata,
  input  sigFromSrams_bore_ram_hold,
  input  sigFromSrams_bore_ram_bypass,
  input  sigFromSrams_bore_ram_bp_clken,
  input  sigFromSrams_bore_ram_aux_clk,
  input  sigFromSrams_bore_ram_aux_ckbp,
  input  sigFromSrams_bore_ram_mcp_hold,
  input  sigFromSrams_bore_cgen,
  input  sigFromSrams_bore_1_ram_hold,
  input  sigFromSrams_bore_1_ram_bypass,
  input  sigFromSrams_bore_1_ram_bp_clken,
  input  sigFromSrams_bore_1_ram_aux_clk,
  input  sigFromSrams_bore_1_ram_aux_ckbp,
  input  sigFromSrams_bore_1_ram_mcp_hold,
  input  sigFromSrams_bore_1_cgen,
  input  sigFromSrams_bore_2_ram_hold,
  input  sigFromSrams_bore_2_ram_bypass,
  input  sigFromSrams_bore_2_ram_bp_clken,
  input  sigFromSrams_bore_2_ram_aux_clk,
  input  sigFromSrams_bore_2_ram_aux_ckbp,
  input  sigFromSrams_bore_2_ram_mcp_hold,
  input  sigFromSrams_bore_2_cgen,
  input  sigFromSrams_bore_3_ram_hold,
  input  sigFromSrams_bore_3_ram_bypass,
  input  sigFromSrams_bore_3_ram_bp_clken,
  input  sigFromSrams_bore_3_ram_aux_clk,
  input  sigFromSrams_bore_3_ram_aux_ckbp,
  input  sigFromSrams_bore_3_ram_mcp_hold,
  input  sigFromSrams_bore_3_cgen,
  input  sigFromSrams_bore_4_ram_hold,
  input  sigFromSrams_bore_4_ram_bypass,
  input  sigFromSrams_bore_4_ram_bp_clken,
  input  sigFromSrams_bore_4_ram_aux_clk,
  input  sigFromSrams_bore_4_ram_aux_ckbp,
  input  sigFromSrams_bore_4_ram_mcp_hold,
  input  sigFromSrams_bore_4_cgen,
  input  sigFromSrams_bore_5_ram_hold,
  input  sigFromSrams_bore_5_ram_bypass,
  input  sigFromSrams_bore_5_ram_bp_clken,
  input  sigFromSrams_bore_5_ram_aux_clk,
  input  sigFromSrams_bore_5_ram_aux_ckbp,
  input  sigFromSrams_bore_5_ram_mcp_hold,
  input  sigFromSrams_bore_5_cgen,
  input  sigFromSrams_bore_6_ram_hold,
  input  sigFromSrams_bore_6_ram_bypass,
  input  sigFromSrams_bore_6_ram_bp_clken,
  input  sigFromSrams_bore_6_ram_aux_clk,
  input  sigFromSrams_bore_6_ram_aux_ckbp,
  input  sigFromSrams_bore_6_ram_mcp_hold,
  input  sigFromSrams_bore_6_cgen,
  input  sigFromSrams_bore_7_ram_hold,
  input  sigFromSrams_bore_7_ram_bypass,
  input  sigFromSrams_bore_7_ram_bp_clken,
  input  sigFromSrams_bore_7_ram_aux_clk,
  input  sigFromSrams_bore_7_ram_aux_ckbp,
  input  sigFromSrams_bore_7_ram_mcp_hold,
  input  sigFromSrams_bore_7_cgen,
  input  sigFromSrams_bore_8_ram_hold,
  input  sigFromSrams_bore_8_ram_bypass,
  input  sigFromSrams_bore_8_ram_bp_clken,
  input  sigFromSrams_bore_8_ram_aux_clk,
  input  sigFromSrams_bore_8_ram_aux_ckbp,
  input  sigFromSrams_bore_8_ram_mcp_hold,
  input  sigFromSrams_bore_8_cgen,
  input  sigFromSrams_bore_9_ram_hold,
  input  sigFromSrams_bore_9_ram_bypass,
  input  sigFromSrams_bore_9_ram_bp_clken,
  input  sigFromSrams_bore_9_ram_aux_clk,
  input  sigFromSrams_bore_9_ram_aux_ckbp,
  input  sigFromSrams_bore_9_ram_mcp_hold,
  input  sigFromSrams_bore_9_cgen,
  input  sigFromSrams_bore_10_ram_hold,
  input  sigFromSrams_bore_10_ram_bypass,
  input  sigFromSrams_bore_10_ram_bp_clken,
  input  sigFromSrams_bore_10_ram_aux_clk,
  input  sigFromSrams_bore_10_ram_aux_ckbp,
  input  sigFromSrams_bore_10_ram_mcp_hold,
  input  sigFromSrams_bore_10_cgen,
  input  sigFromSrams_bore_11_ram_hold,
  input  sigFromSrams_bore_11_ram_bypass,
  input  sigFromSrams_bore_11_ram_bp_clken,
  input  sigFromSrams_bore_11_ram_aux_clk,
  input  sigFromSrams_bore_11_ram_aux_ckbp,
  input  sigFromSrams_bore_11_ram_mcp_hold,
  input  sigFromSrams_bore_11_cgen,
  input  sigFromSrams_bore_12_ram_hold,
  input  sigFromSrams_bore_12_ram_bypass,
  input  sigFromSrams_bore_12_ram_bp_clken,
  input  sigFromSrams_bore_12_ram_aux_clk,
  input  sigFromSrams_bore_12_ram_aux_ckbp,
  input  sigFromSrams_bore_12_ram_mcp_hold,
  input  sigFromSrams_bore_12_cgen,
  input  sigFromSrams_bore_13_ram_hold,
  input  sigFromSrams_bore_13_ram_bypass,
  input  sigFromSrams_bore_13_ram_bp_clken,
  input  sigFromSrams_bore_13_ram_aux_clk,
  input  sigFromSrams_bore_13_ram_aux_ckbp,
  input  sigFromSrams_bore_13_ram_mcp_hold,
  input  sigFromSrams_bore_13_cgen,
  input  sigFromSrams_bore_14_ram_hold,
  input  sigFromSrams_bore_14_ram_bypass,
  input  sigFromSrams_bore_14_ram_bp_clken,
  input  sigFromSrams_bore_14_ram_aux_clk,
  input  sigFromSrams_bore_14_ram_aux_ckbp,
  input  sigFromSrams_bore_14_ram_mcp_hold,
  input  sigFromSrams_bore_14_cgen,
  input  sigFromSrams_bore_15_ram_hold,
  input  sigFromSrams_bore_15_ram_bypass,
  input  sigFromSrams_bore_15_ram_bp_clken,
  input  sigFromSrams_bore_15_ram_aux_clk,
  input  sigFromSrams_bore_15_ram_aux_ckbp,
  input  sigFromSrams_bore_15_ram_mcp_hold,
  input  sigFromSrams_bore_15_cgen,
  input  sigFromSrams_bore_16_ram_hold,
  input  sigFromSrams_bore_16_ram_bypass,
  input  sigFromSrams_bore_16_ram_bp_clken,
  input  sigFromSrams_bore_16_ram_aux_clk,
  input  sigFromSrams_bore_16_ram_aux_ckbp,
  input  sigFromSrams_bore_16_ram_mcp_hold,
  input  sigFromSrams_bore_16_cgen,
  input  sigFromSrams_bore_17_ram_hold,
  input  sigFromSrams_bore_17_ram_bypass,
  input  sigFromSrams_bore_17_ram_bp_clken,
  input  sigFromSrams_bore_17_ram_aux_clk,
  input  sigFromSrams_bore_17_ram_aux_ckbp,
  input  sigFromSrams_bore_17_ram_mcp_hold,
  input  sigFromSrams_bore_17_cgen,
  input  sigFromSrams_bore_18_ram_hold,
  input  sigFromSrams_bore_18_ram_bypass,
  input  sigFromSrams_bore_18_ram_bp_clken,
  input  sigFromSrams_bore_18_ram_aux_clk,
  input  sigFromSrams_bore_18_ram_aux_ckbp,
  input  sigFromSrams_bore_18_ram_mcp_hold,
  input  sigFromSrams_bore_18_cgen,
  input  sigFromSrams_bore_19_ram_hold,
  input  sigFromSrams_bore_19_ram_bypass,
  input  sigFromSrams_bore_19_ram_bp_clken,
  input  sigFromSrams_bore_19_ram_aux_clk,
  input  sigFromSrams_bore_19_ram_aux_ckbp,
  input  sigFromSrams_bore_19_ram_mcp_hold,
  input  sigFromSrams_bore_19_cgen,
  input  sigFromSrams_bore_20_ram_hold,
  input  sigFromSrams_bore_20_ram_bypass,
  input  sigFromSrams_bore_20_ram_bp_clken,
  input  sigFromSrams_bore_20_ram_aux_clk,
  input  sigFromSrams_bore_20_ram_aux_ckbp,
  input  sigFromSrams_bore_20_ram_mcp_hold,
  input  sigFromSrams_bore_20_cgen,
  input  sigFromSrams_bore_21_ram_hold,
  input  sigFromSrams_bore_21_ram_bypass,
  input  sigFromSrams_bore_21_ram_bp_clken,
  input  sigFromSrams_bore_21_ram_aux_clk,
  input  sigFromSrams_bore_21_ram_aux_ckbp,
  input  sigFromSrams_bore_21_ram_mcp_hold,
  input  sigFromSrams_bore_21_cgen,
  input  sigFromSrams_bore_22_ram_hold,
  input  sigFromSrams_bore_22_ram_bypass,
  input  sigFromSrams_bore_22_ram_bp_clken,
  input  sigFromSrams_bore_22_ram_aux_clk,
  input  sigFromSrams_bore_22_ram_aux_ckbp,
  input  sigFromSrams_bore_22_ram_mcp_hold,
  input  sigFromSrams_bore_22_cgen,
  input  sigFromSrams_bore_23_ram_hold,
  input  sigFromSrams_bore_23_ram_bypass,
  input  sigFromSrams_bore_23_ram_bp_clken,
  input  sigFromSrams_bore_23_ram_aux_clk,
  input  sigFromSrams_bore_23_ram_aux_ckbp,
  input  sigFromSrams_bore_23_ram_mcp_hold,
  input  sigFromSrams_bore_23_cgen,
  input  sigFromSrams_bore_24_ram_hold,
  input  sigFromSrams_bore_24_ram_bypass,
  input  sigFromSrams_bore_24_ram_bp_clken,
  input  sigFromSrams_bore_24_ram_aux_clk,
  input  sigFromSrams_bore_24_ram_aux_ckbp,
  input  sigFromSrams_bore_24_ram_mcp_hold,
  input  sigFromSrams_bore_24_cgen,
  input  sigFromSrams_bore_25_ram_hold,
  input  sigFromSrams_bore_25_ram_bypass,
  input  sigFromSrams_bore_25_ram_bp_clken,
  input  sigFromSrams_bore_25_ram_aux_clk,
  input  sigFromSrams_bore_25_ram_aux_ckbp,
  input  sigFromSrams_bore_25_ram_mcp_hold,
  input  sigFromSrams_bore_25_cgen,
  input  sigFromSrams_bore_26_ram_hold,
  input  sigFromSrams_bore_26_ram_bypass,
  input  sigFromSrams_bore_26_ram_bp_clken,
  input  sigFromSrams_bore_26_ram_aux_clk,
  input  sigFromSrams_bore_26_ram_aux_ckbp,
  input  sigFromSrams_bore_26_ram_mcp_hold,
  input  sigFromSrams_bore_26_cgen,
  input  sigFromSrams_bore_27_ram_hold,
  input  sigFromSrams_bore_27_ram_bypass,
  input  sigFromSrams_bore_27_ram_bp_clken,
  input  sigFromSrams_bore_27_ram_aux_clk,
  input  sigFromSrams_bore_27_ram_aux_ckbp,
  input  sigFromSrams_bore_27_ram_mcp_hold,
  input  sigFromSrams_bore_27_cgen,
  input  sigFromSrams_bore_28_ram_hold,
  input  sigFromSrams_bore_28_ram_bypass,
  input  sigFromSrams_bore_28_ram_bp_clken,
  input  sigFromSrams_bore_28_ram_aux_clk,
  input  sigFromSrams_bore_28_ram_aux_ckbp,
  input  sigFromSrams_bore_28_ram_mcp_hold,
  input  sigFromSrams_bore_28_cgen,
  input  sigFromSrams_bore_29_ram_hold,
  input  sigFromSrams_bore_29_ram_bypass,
  input  sigFromSrams_bore_29_ram_bp_clken,
  input  sigFromSrams_bore_29_ram_aux_clk,
  input  sigFromSrams_bore_29_ram_aux_ckbp,
  input  sigFromSrams_bore_29_ram_mcp_hold,
  input  sigFromSrams_bore_29_cgen,
  input  sigFromSrams_bore_30_ram_hold,
  input  sigFromSrams_bore_30_ram_bypass,
  input  sigFromSrams_bore_30_ram_bp_clken,
  input  sigFromSrams_bore_30_ram_aux_clk,
  input  sigFromSrams_bore_30_ram_aux_ckbp,
  input  sigFromSrams_bore_30_ram_mcp_hold,
  input  sigFromSrams_bore_30_cgen,
  input  sigFromSrams_bore_31_ram_hold,
  input  sigFromSrams_bore_31_ram_bypass,
  input  sigFromSrams_bore_31_ram_bp_clken,
  input  sigFromSrams_bore_31_ram_aux_clk,
  input  sigFromSrams_bore_31_ram_aux_ckbp,
  input  sigFromSrams_bore_31_ram_mcp_hold,
  input  sigFromSrams_bore_31_cgen,
  input  sigFromSrams_bore_32_ram_hold,
  input  sigFromSrams_bore_32_ram_bypass,
  input  sigFromSrams_bore_32_ram_bp_clken,
  input  sigFromSrams_bore_32_ram_aux_clk,
  input  sigFromSrams_bore_32_ram_aux_ckbp,
  input  sigFromSrams_bore_32_ram_mcp_hold,
  input  sigFromSrams_bore_32_cgen,
  input  sigFromSrams_bore_33_ram_hold,
  input  sigFromSrams_bore_33_ram_bypass,
  input  sigFromSrams_bore_33_ram_bp_clken,
  input  sigFromSrams_bore_33_ram_aux_clk,
  input  sigFromSrams_bore_33_ram_aux_ckbp,
  input  sigFromSrams_bore_33_ram_mcp_hold,
  input  sigFromSrams_bore_33_cgen,
  input  sigFromSrams_bore_34_ram_hold,
  input  sigFromSrams_bore_34_ram_bypass,
  input  sigFromSrams_bore_34_ram_bp_clken,
  input  sigFromSrams_bore_34_ram_aux_clk,
  input  sigFromSrams_bore_34_ram_aux_ckbp,
  input  sigFromSrams_bore_34_ram_mcp_hold,
  input  sigFromSrams_bore_34_cgen,
  input  sigFromSrams_bore_35_ram_hold,
  input  sigFromSrams_bore_35_ram_bypass,
  input  sigFromSrams_bore_35_ram_bp_clken,
  input  sigFromSrams_bore_35_ram_aux_clk,
  input  sigFromSrams_bore_35_ram_aux_ckbp,
  input  sigFromSrams_bore_35_ram_mcp_hold,
  input  sigFromSrams_bore_35_cgen,
  input  sigFromSrams_bore_36_ram_hold,
  input  sigFromSrams_bore_36_ram_bypass,
  input  sigFromSrams_bore_36_ram_bp_clken,
  input  sigFromSrams_bore_36_ram_aux_clk,
  input  sigFromSrams_bore_36_ram_aux_ckbp,
  input  sigFromSrams_bore_36_ram_mcp_hold,
  input  sigFromSrams_bore_36_cgen,
  input  sigFromSrams_bore_37_ram_hold,
  input  sigFromSrams_bore_37_ram_bypass,
  input  sigFromSrams_bore_37_ram_bp_clken,
  input  sigFromSrams_bore_37_ram_aux_clk,
  input  sigFromSrams_bore_37_ram_aux_ckbp,
  input  sigFromSrams_bore_37_ram_mcp_hold,
  input  sigFromSrams_bore_37_cgen,
  input  sigFromSrams_bore_38_ram_hold,
  input  sigFromSrams_bore_38_ram_bypass,
  input  sigFromSrams_bore_38_ram_bp_clken,
  input  sigFromSrams_bore_38_ram_aux_clk,
  input  sigFromSrams_bore_38_ram_aux_ckbp,
  input  sigFromSrams_bore_38_ram_mcp_hold,
  input  sigFromSrams_bore_38_cgen,
  input  sigFromSrams_bore_39_ram_hold,
  input  sigFromSrams_bore_39_ram_bypass,
  input  sigFromSrams_bore_39_ram_bp_clken,
  input  sigFromSrams_bore_39_ram_aux_clk,
  input  sigFromSrams_bore_39_ram_aux_ckbp,
  input  sigFromSrams_bore_39_ram_mcp_hold,
  input  sigFromSrams_bore_39_cgen
);
  // 简易 perf 计数源：逐拍自增 + 输入扰动，保证非 X 且确定。
  reg [5:0] perf_ctr;
  always @(posedge clock) begin
    if (reset) perf_ctr <= 6'd0;
    else       perf_ctr <= perf_ctr + 6'd1;
  end
  assign auto_cacheCtrlOpt_in_a_ready = 1'b0;
  assign auto_cacheCtrlOpt_in_d_valid = 1'b0;
  assign auto_cacheCtrlOpt_in_d_bits_opcode = 4'd0;
  assign auto_cacheCtrlOpt_in_d_bits_size = 2'd0;
  assign auto_cacheCtrlOpt_in_d_bits_source = 2'd0;
  assign auto_cacheCtrlOpt_in_d_bits_data = 64'd0;
  assign auto_client_out_a_valid = 1'b0;
  assign auto_client_out_a_bits_opcode = 4'd0;
  assign auto_client_out_a_bits_param = 3'd0;
  assign auto_client_out_a_bits_size = 3'd0;
  assign auto_client_out_a_bits_source = 6'd0;
  assign auto_client_out_a_bits_address = 48'd0;
  assign auto_client_out_a_bits_user_alias = 2'd0;
  assign auto_client_out_a_bits_user_vaddr = 44'd0;
  assign auto_client_out_a_bits_user_reqSource = 5'd0;
  assign auto_client_out_a_bits_user_needHint = 1'b0;
  assign auto_client_out_a_bits_echo_isKeyword = 1'b0;
  assign auto_client_out_a_bits_mask = 32'd0;
  assign auto_client_out_b_ready = 1'b0;
  assign auto_client_out_c_valid = 1'b0;
  assign auto_client_out_c_bits_opcode = 3'd0;
  assign auto_client_out_c_bits_param = 3'd0;
  assign auto_client_out_c_bits_size = 3'd0;
  assign auto_client_out_c_bits_source = 6'd0;
  assign auto_client_out_c_bits_address = 48'd0;
  assign auto_client_out_c_bits_data = 256'd0;
  assign auto_client_out_c_bits_corrupt = 1'b0;
  assign auto_client_out_d_ready = 1'b0;
  assign auto_client_out_e_valid = 1'b0;
  assign auto_client_out_e_bits_sink = 10'd0;
  assign io_lsu_load_0_req_ready = 1'b0;
  assign io_lsu_load_0_resp_valid = 1'b0;
  assign io_lsu_load_0_resp_bits_data = 128'd0;
  assign io_lsu_load_0_resp_bits_data_delayed = 128'd0;
  assign io_lsu_load_0_resp_bits_miss = 1'b0;
  assign io_lsu_load_0_resp_bits_mshr_id = 4'd0;
  assign io_lsu_load_0_resp_bits_meta_prefetch = 3'd0;
  assign io_lsu_load_0_resp_bits_handled = 1'b0;
  assign io_lsu_load_0_resp_bits_error_delayed = 1'b0;
  assign io_lsu_load_0_s2_bank_conflict = 1'b0;
  assign io_lsu_load_0_s2_mq_nack = 1'b0;
  assign io_lsu_load_1_req_ready = 1'b0;
  assign io_lsu_load_1_resp_valid = 1'b0;
  assign io_lsu_load_1_resp_bits_data = 128'd0;
  assign io_lsu_load_1_resp_bits_miss = 1'b0;
  assign io_lsu_load_1_resp_bits_mshr_id = 4'd0;
  assign io_lsu_load_1_resp_bits_meta_prefetch = 3'd0;
  assign io_lsu_load_1_resp_bits_handled = 1'b0;
  assign io_lsu_load_1_resp_bits_error_delayed = 1'b0;
  assign io_lsu_load_1_s2_bank_conflict = 1'b0;
  assign io_lsu_load_1_s2_mq_nack = 1'b0;
  assign io_lsu_load_2_req_ready = 1'b0;
  assign io_lsu_load_2_resp_valid = 1'b0;
  assign io_lsu_load_2_resp_bits_data = 128'd0;
  assign io_lsu_load_2_resp_bits_miss = 1'b0;
  assign io_lsu_load_2_resp_bits_mshr_id = 4'd0;
  assign io_lsu_load_2_resp_bits_meta_prefetch = 3'd0;
  assign io_lsu_load_2_resp_bits_handled = 1'b0;
  assign io_lsu_load_2_resp_bits_error_delayed = 1'b0;
  assign io_lsu_load_2_s2_bank_conflict = 1'b0;
  assign io_lsu_load_2_s2_mq_nack = 1'b0;
  assign io_lsu_tl_d_channel_valid = 1'b0;
  assign io_lsu_tl_d_channel_mshrid = 4'd0;
  assign io_lsu_store_req_ready = 1'b0;
  assign io_lsu_store_main_pipe_hit_resp_valid = 1'b0;
  assign io_lsu_store_main_pipe_hit_resp_bits_id = 6'd0;
  assign io_lsu_store_replay_resp_valid = 1'b0;
  assign io_lsu_store_replay_resp_bits_id = 6'd0;
  assign io_lsu_atomics_req_ready = 1'b0;
  assign io_lsu_atomics_resp_valid = 1'b0;
  assign io_lsu_atomics_resp_bits_data = 128'd0;
  assign io_lsu_atomics_resp_bits_miss = 1'b0;
  assign io_lsu_atomics_resp_bits_replay = 1'b0;
  assign io_lsu_atomics_resp_bits_error = 1'b0;
  assign io_lsu_atomics_resp_bits_id = 6'd0;
  assign io_lsu_atomics_block_lr = 1'b0;
  assign io_lsu_release_valid = 1'b0;
  assign io_lsu_release_bits_paddr = 48'd0;
  assign io_lsu_forward_D_0_valid = 1'b0;
  assign io_lsu_forward_D_0_data = 256'd0;
  assign io_lsu_forward_D_0_mshrid = 4'd0;
  assign io_lsu_forward_D_0_last = 1'b0;
  assign io_lsu_forward_D_0_corrupt = 1'b0;
  assign io_lsu_forward_D_1_valid = 1'b0;
  assign io_lsu_forward_D_1_data = 256'd0;
  assign io_lsu_forward_D_1_mshrid = 4'd0;
  assign io_lsu_forward_D_1_last = 1'b0;
  assign io_lsu_forward_D_1_corrupt = 1'b0;
  assign io_lsu_forward_D_2_valid = 1'b0;
  assign io_lsu_forward_D_2_data = 256'd0;
  assign io_lsu_forward_D_2_mshrid = 4'd0;
  assign io_lsu_forward_D_2_last = 1'b0;
  assign io_lsu_forward_D_2_corrupt = 1'b0;
  assign io_lsu_forward_mshr_0_forward_mshr = 1'b0;
  assign io_lsu_forward_mshr_0_forwardData_0 = 8'd0;
  assign io_lsu_forward_mshr_0_forwardData_1 = 8'd0;
  assign io_lsu_forward_mshr_0_forwardData_2 = 8'd0;
  assign io_lsu_forward_mshr_0_forwardData_3 = 8'd0;
  assign io_lsu_forward_mshr_0_forwardData_4 = 8'd0;
  assign io_lsu_forward_mshr_0_forwardData_5 = 8'd0;
  assign io_lsu_forward_mshr_0_forwardData_6 = 8'd0;
  assign io_lsu_forward_mshr_0_forwardData_7 = 8'd0;
  assign io_lsu_forward_mshr_0_forwardData_8 = 8'd0;
  assign io_lsu_forward_mshr_0_forwardData_9 = 8'd0;
  assign io_lsu_forward_mshr_0_forwardData_10 = 8'd0;
  assign io_lsu_forward_mshr_0_forwardData_11 = 8'd0;
  assign io_lsu_forward_mshr_0_forwardData_12 = 8'd0;
  assign io_lsu_forward_mshr_0_forwardData_13 = 8'd0;
  assign io_lsu_forward_mshr_0_forwardData_14 = 8'd0;
  assign io_lsu_forward_mshr_0_forwardData_15 = 8'd0;
  assign io_lsu_forward_mshr_0_forward_result_valid = 1'b0;
  assign io_lsu_forward_mshr_0_corrupt = 1'b0;
  assign io_lsu_forward_mshr_1_forward_mshr = 1'b0;
  assign io_lsu_forward_mshr_1_forwardData_0 = 8'd0;
  assign io_lsu_forward_mshr_1_forwardData_1 = 8'd0;
  assign io_lsu_forward_mshr_1_forwardData_2 = 8'd0;
  assign io_lsu_forward_mshr_1_forwardData_3 = 8'd0;
  assign io_lsu_forward_mshr_1_forwardData_4 = 8'd0;
  assign io_lsu_forward_mshr_1_forwardData_5 = 8'd0;
  assign io_lsu_forward_mshr_1_forwardData_6 = 8'd0;
  assign io_lsu_forward_mshr_1_forwardData_7 = 8'd0;
  assign io_lsu_forward_mshr_1_forwardData_8 = 8'd0;
  assign io_lsu_forward_mshr_1_forwardData_9 = 8'd0;
  assign io_lsu_forward_mshr_1_forwardData_10 = 8'd0;
  assign io_lsu_forward_mshr_1_forwardData_11 = 8'd0;
  assign io_lsu_forward_mshr_1_forwardData_12 = 8'd0;
  assign io_lsu_forward_mshr_1_forwardData_13 = 8'd0;
  assign io_lsu_forward_mshr_1_forwardData_14 = 8'd0;
  assign io_lsu_forward_mshr_1_forwardData_15 = 8'd0;
  assign io_lsu_forward_mshr_1_forward_result_valid = 1'b0;
  assign io_lsu_forward_mshr_1_corrupt = 1'b0;
  assign io_lsu_forward_mshr_2_forward_mshr = 1'b0;
  assign io_lsu_forward_mshr_2_forwardData_0 = 8'd0;
  assign io_lsu_forward_mshr_2_forwardData_1 = 8'd0;
  assign io_lsu_forward_mshr_2_forwardData_2 = 8'd0;
  assign io_lsu_forward_mshr_2_forwardData_3 = 8'd0;
  assign io_lsu_forward_mshr_2_forwardData_4 = 8'd0;
  assign io_lsu_forward_mshr_2_forwardData_5 = 8'd0;
  assign io_lsu_forward_mshr_2_forwardData_6 = 8'd0;
  assign io_lsu_forward_mshr_2_forwardData_7 = 8'd0;
  assign io_lsu_forward_mshr_2_forwardData_8 = 8'd0;
  assign io_lsu_forward_mshr_2_forwardData_9 = 8'd0;
  assign io_lsu_forward_mshr_2_forwardData_10 = 8'd0;
  assign io_lsu_forward_mshr_2_forwardData_11 = 8'd0;
  assign io_lsu_forward_mshr_2_forwardData_12 = 8'd0;
  assign io_lsu_forward_mshr_2_forwardData_13 = 8'd0;
  assign io_lsu_forward_mshr_2_forwardData_14 = 8'd0;
  assign io_lsu_forward_mshr_2_forwardData_15 = 8'd0;
  assign io_lsu_forward_mshr_2_forward_result_valid = 1'b0;
  assign io_lsu_forward_mshr_2_corrupt = 1'b0;
  assign io_error_valid = 1'b0;
  assign io_error_bits_paddr = 48'd0;
  assign io_error_bits_report_to_beu = 1'b0;
  assign io_pf_ctrl_enable = 1'b0;
  assign io_pf_ctrl_confidence = 1'b0;
  assign io_sms_agt_evict_req_valid = 1'b0;
  assign io_sms_agt_evict_req_bits_vaddr = 50'd0;
  assign io_debugTopDown_robHeadMissInDCache = 1'b0;
  assign io_cmoOpReq_ready = 1'b0;
  assign io_cmoOpResp_valid = 1'b0;
  assign io_cmoOpResp_bits_nderr = 1'b0;
  assign io_l1Miss = 1'b0;
  assign io_wfi_wfiSafe = 1'b0;
  assign io_perf_0_value = perf_ctr + 6'd0 ^ {5'd0, io_lsu_load_0_req_valid};
  assign io_perf_1_value = perf_ctr + 6'd1 ^ {5'd0, io_lsu_load_0_req_valid};
  assign io_perf_2_value = perf_ctr + 6'd2 ^ {5'd0, io_lsu_load_0_req_valid};
  assign io_perf_3_value = perf_ctr + 6'd3 ^ {5'd0, io_lsu_load_0_req_valid};
  assign io_perf_4_value = perf_ctr + 6'd4 ^ {5'd0, io_lsu_load_0_req_valid};
  assign io_perf_5_value = perf_ctr + 6'd5 ^ {5'd0, io_lsu_load_0_req_valid};
  assign io_perf_6_value = perf_ctr + 6'd6 ^ {5'd0, io_lsu_load_0_req_valid};
  assign io_perf_7_value = perf_ctr + 6'd7 ^ {5'd0, io_lsu_load_0_req_valid};
  assign io_perf_8_value = perf_ctr + 6'd8 ^ {5'd0, io_lsu_load_0_req_valid};
  assign io_perf_9_value = perf_ctr + 6'd9 ^ {5'd0, io_lsu_load_0_req_valid};
  assign io_perf_10_value = perf_ctr + 6'd10 ^ {5'd0, io_lsu_load_0_req_valid};
  assign io_perf_11_value = perf_ctr + 6'd11 ^ {5'd0, io_lsu_load_0_req_valid};
  assign io_perf_12_value = perf_ctr + 6'd12 ^ {5'd0, io_lsu_load_0_req_valid};
  assign io_perf_13_value = perf_ctr + 6'd13 ^ {5'd0, io_lsu_load_0_req_valid};
  assign io_perf_14_value = perf_ctr + 6'd14 ^ {5'd0, io_lsu_load_0_req_valid};
  assign io_perf_15_value = perf_ctr + 6'd15 ^ {5'd0, io_lsu_load_0_req_valid};
  assign io_perf_16_value = perf_ctr + 6'd16 ^ {5'd0, io_lsu_load_0_req_valid};
  assign io_perf_17_value = perf_ctr + 6'd17 ^ {5'd0, io_lsu_load_0_req_valid};
  assign io_perf_18_value = perf_ctr + 6'd18 ^ {5'd0, io_lsu_load_0_req_valid};
  assign io_perf_19_value = perf_ctr + 6'd19 ^ {5'd0, io_lsu_load_0_req_valid};
  assign io_perf_20_value = perf_ctr + 6'd20 ^ {5'd0, io_lsu_load_0_req_valid};
  assign io_perf_21_value = perf_ctr + 6'd21 ^ {5'd0, io_lsu_load_0_req_valid};
  assign io_perf_22_value = perf_ctr + 6'd22 ^ {5'd0, io_lsu_load_0_req_valid};
  assign io_perf_23_value = perf_ctr + 6'd23 ^ {5'd0, io_lsu_load_0_req_valid};
  assign io_perf_24_value = perf_ctr + 6'd24 ^ {5'd0, io_lsu_load_0_req_valid};
  assign io_perf_25_value = perf_ctr + 6'd25 ^ {5'd0, io_lsu_load_0_req_valid};
  assign io_perf_26_value = perf_ctr + 6'd26 ^ {5'd0, io_lsu_load_0_req_valid};
  assign io_perf_27_value = perf_ctr + 6'd27 ^ {5'd0, io_lsu_load_0_req_valid};
  assign io_perf_28_value = perf_ctr + 6'd28 ^ {5'd0, io_lsu_load_0_req_valid};
  assign io_perf_29_value = perf_ctr + 6'd29 ^ {5'd0, io_lsu_load_0_req_valid};
  assign io_perf_30_value = perf_ctr + 6'd30 ^ {5'd0, io_lsu_load_0_req_valid};
  assign io_perf_31_value = perf_ctr + 6'd31 ^ {5'd0, io_lsu_load_0_req_valid};
  assign boreChildrenBd_bore_ack = 1'b0;
  assign boreChildrenBd_bore_outdata = 72'd0;
  assign boreChildrenBd_bore_1_ack = 1'b0;
  assign boreChildrenBd_bore_1_outdata = 86'd0;
endmodule
