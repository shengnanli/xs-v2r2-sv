// 自动生成：scripts/gen_loadqueuerar.py —— 勿手改
module LoadQueueRAR_xs(
  input clock,
  input reset,
  input io_redirect_valid,
  input io_redirect_bits_robIdx_flag,
  input [7:0] io_redirect_bits_robIdx_value,
  input io_redirect_bits_level,
  output io_query_0_req_ready,
  input io_query_0_req_valid,
  input io_query_0_req_bits_uop_robIdx_flag,
  input [7:0] io_query_0_req_bits_uop_robIdx_value,
  input io_query_0_req_bits_uop_lqIdx_flag,
  input [6:0] io_query_0_req_bits_uop_lqIdx_value,
  input [47:0] io_query_0_req_bits_paddr,
  input io_query_0_req_bits_data_valid,
  input io_query_0_req_bits_is_nc,
  output io_query_0_resp_valid,
  output io_query_0_resp_bits_rep_frm_fetch,
  input io_query_0_revoke,
  output io_query_1_req_ready,
  input io_query_1_req_valid,
  input io_query_1_req_bits_uop_robIdx_flag,
  input [7:0] io_query_1_req_bits_uop_robIdx_value,
  input io_query_1_req_bits_uop_lqIdx_flag,
  input [6:0] io_query_1_req_bits_uop_lqIdx_value,
  input [47:0] io_query_1_req_bits_paddr,
  input io_query_1_req_bits_data_valid,
  input io_query_1_req_bits_is_nc,
  output io_query_1_resp_valid,
  output io_query_1_resp_bits_rep_frm_fetch,
  input io_query_1_revoke,
  output io_query_2_req_ready,
  input io_query_2_req_valid,
  input io_query_2_req_bits_uop_robIdx_flag,
  input [7:0] io_query_2_req_bits_uop_robIdx_value,
  input io_query_2_req_bits_uop_lqIdx_flag,
  input [6:0] io_query_2_req_bits_uop_lqIdx_value,
  input [47:0] io_query_2_req_bits_paddr,
  input io_query_2_req_bits_data_valid,
  input io_query_2_req_bits_is_nc,
  output io_query_2_resp_valid,
  output io_query_2_resp_bits_rep_frm_fetch,
  input io_query_2_revoke,
  input io_release_valid,
  input [47:0] io_release_bits_paddr,
  input io_ldWbPtr_flag,
  input [6:0] io_ldWbPtr_value,
  output io_lqFull,
  output [6:0] io_validCount,
  output [5:0] io_perf_0_value,
  output [5:0] io_perf_1_value
);

  import loadqueuerar_pkg::*;
  // 把扁平 query uop 指针机械打包成核的 {flag,value} struct
  rob_ptr_t q0_robIdx, q1_robIdx, q2_robIdx;
  lq_ptr_t  q0_lqIdx,  q1_lqIdx,  q2_lqIdx;
  assign q0_robIdx = '{flag:io_query_0_req_bits_uop_robIdx_flag, value:io_query_0_req_bits_uop_robIdx_value};
  assign q1_robIdx = '{flag:io_query_1_req_bits_uop_robIdx_flag, value:io_query_1_req_bits_uop_robIdx_value};
  assign q2_robIdx = '{flag:io_query_2_req_bits_uop_robIdx_flag, value:io_query_2_req_bits_uop_robIdx_value};
  assign q0_lqIdx  = '{flag:io_query_0_req_bits_uop_lqIdx_flag,  value:io_query_0_req_bits_uop_lqIdx_value};
  assign q1_lqIdx  = '{flag:io_query_1_req_bits_uop_lqIdx_flag,  value:io_query_1_req_bits_uop_lqIdx_value};
  assign q2_lqIdx  = '{flag:io_query_2_req_bits_uop_lqIdx_flag,  value:io_query_2_req_bits_uop_lqIdx_value};

  logic [2:0] q_req_ready, q_resp_valid, q_resp_rep;
  logic [1:0] perf0, perf1;

  assign io_query_0_req_ready = q_req_ready[0];
  assign io_query_1_req_ready = q_req_ready[1];
  assign io_query_2_req_ready = q_req_ready[2];
  assign io_query_0_resp_valid = q_resp_valid[0];
  assign io_query_1_resp_valid = q_resp_valid[1];
  assign io_query_2_resp_valid = q_resp_valid[2];
  assign io_query_0_resp_bits_rep_frm_fetch = q_resp_rep[0];
  assign io_query_1_resp_bits_rep_frm_fetch = q_resp_rep[1];
  assign io_query_2_resp_bits_rep_frm_fetch = q_resp_rep[2];
  // perf：golden 输出 [5:0] = {4'h0, 2-bit count}
  assign io_perf_0_value = {4'h0, perf0};
  assign io_perf_1_value = {4'h0, perf1};

  xs_LoadQueueRAR_core u_core (
    .clock  (clock),
    .reset  (reset),
    .redirect_valid (io_redirect_valid),
    .redirect_robIdx('{flag:io_redirect_bits_robIdx_flag, value:io_redirect_bits_robIdx_value}),
    .redirect_level (io_redirect_bits_level),
    .q_req_valid      ({io_query_2_req_valid, io_query_1_req_valid, io_query_0_req_valid}),
    .q_req_robIdx     ({q2_robIdx, q1_robIdx, q0_robIdx}),
    .q_req_lqIdx      ({q2_lqIdx, q1_lqIdx, q0_lqIdx}),
    .q_req_paddr      ({io_query_2_req_bits_paddr, io_query_1_req_bits_paddr, io_query_0_req_bits_paddr}),
    .q_req_data_valid ({io_query_2_req_bits_data_valid, io_query_1_req_bits_data_valid, io_query_0_req_bits_data_valid}),
    .q_req_is_nc      ({io_query_2_req_bits_is_nc, io_query_1_req_bits_is_nc, io_query_0_req_bits_is_nc}),
    .q_revoke         ({io_query_2_revoke, io_query_1_revoke, io_query_0_revoke}),
    .q_req_ready          (q_req_ready),
    .q_resp_valid         (q_resp_valid),
    .q_resp_rep_frm_fetch (q_resp_rep),
    .release_valid (io_release_valid),
    .release_paddr (io_release_bits_paddr),
    .ldWbPtr      ('{flag:io_ldWbPtr_flag, value:io_ldWbPtr_value}),
    .lqFull       (io_lqFull),
    .validCount   (io_validCount),
    .perf_enq           (perf0),
    .perf_ldld_violation(perf1)
  );
endmodule
