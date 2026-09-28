// 自动生成：verif/ut/DCacheLeaves/gen.py（scripts/dual_tb_lib.py，读 G1 golden 端口表）—— 勿手改
// DCache 小 child 双例化逐拍比对：golden <Top> vs 重写 <Top>_xs，全部输出逐位 !==。
// 覆盖闸：每个输出位见过 0/1 + 各对的分支计数（见 gen.py）。
`timescale 1ns/1ps
module tb;
  int unsigned NCYCLES = 200000;
  int errors = 0, checks = 0, cov_fail = 0;
  int unsigned cyc = 0;
  logic clk = 1'b0;
  always #5 clk = ~clk;
  localparam int RESET_CYC = 8;

  // ================= Arbiter1_TagWriteReq =================
  int unsigned atw_mode = 0;
  logic atw_io_in_0_valid;
  logic [7:0] atw_io_in_0_bits_idx;
  logic [3:0] atw_io_in_0_bits_way_en;
  logic [35:0] atw_io_in_0_bits_tag;
  wire  atw_g_io_out_valid, atw_i_io_out_valid;
  logic atw_s0_io_out_valid = '0, atw_s1_io_out_valid = '0;
  wire  [7:0] atw_g_io_out_bits_idx, atw_i_io_out_bits_idx;
  logic [7:0] atw_s0_io_out_bits_idx = '0, atw_s1_io_out_bits_idx = '0;
  wire  [3:0] atw_g_io_out_bits_way_en, atw_i_io_out_bits_way_en;
  logic [3:0] atw_s0_io_out_bits_way_en = '0, atw_s1_io_out_bits_way_en = '0;
  wire  [35:0] atw_g_io_out_bits_tag, atw_i_io_out_bits_tag;
  logic [35:0] atw_s0_io_out_bits_tag = '0, atw_s1_io_out_bits_tag = '0;
  logic [0:0] atw_armed = '0;
  int atw_armed_at = -1;
  Arbiter1_TagWriteReq atw_u_gold (
    .io_in_0_valid(atw_io_in_0_valid),
    .io_in_0_bits_idx(atw_io_in_0_bits_idx),
    .io_in_0_bits_way_en(atw_io_in_0_bits_way_en),
    .io_in_0_bits_tag(atw_io_in_0_bits_tag),
    .io_out_valid(atw_g_io_out_valid),
    .io_out_bits_idx(atw_g_io_out_bits_idx),
    .io_out_bits_way_en(atw_g_io_out_bits_way_en),
    .io_out_bits_tag(atw_g_io_out_bits_tag)
  );
  Arbiter1_TagWriteReq_xs atw_u_impl (
    .io_in_0_valid(atw_io_in_0_valid),
    .io_in_0_bits_idx(atw_io_in_0_bits_idx),
    .io_in_0_bits_way_en(atw_io_in_0_bits_way_en),
    .io_in_0_bits_tag(atw_io_in_0_bits_tag),
    .io_out_valid(atw_i_io_out_valid),
    .io_out_bits_idx(atw_i_io_out_bits_idx),
    .io_out_bits_way_en(atw_i_io_out_bits_way_en),
    .io_out_bits_tag(atw_i_io_out_bits_tag)
  );

  // ================= Arbiter1_L1BankedDataWriteReq =================
  int unsigned adw_mode = 0;
  logic adw_io_in_0_valid;
  logic [7:0] adw_io_in_0_bits_wmask;
  logic [63:0] adw_io_in_0_bits_data_0;
  logic [63:0] adw_io_in_0_bits_data_1;
  logic [63:0] adw_io_in_0_bits_data_2;
  logic [63:0] adw_io_in_0_bits_data_3;
  logic [63:0] adw_io_in_0_bits_data_4;
  logic [63:0] adw_io_in_0_bits_data_5;
  logic [63:0] adw_io_in_0_bits_data_6;
  logic [63:0] adw_io_in_0_bits_data_7;
  wire  adw_g_io_out_valid, adw_i_io_out_valid;
  logic adw_s0_io_out_valid = '0, adw_s1_io_out_valid = '0;
  wire  [7:0] adw_g_io_out_bits_wmask, adw_i_io_out_bits_wmask;
  logic [7:0] adw_s0_io_out_bits_wmask = '0, adw_s1_io_out_bits_wmask = '0;
  wire  [63:0] adw_g_io_out_bits_data_0, adw_i_io_out_bits_data_0;
  logic [63:0] adw_s0_io_out_bits_data_0 = '0, adw_s1_io_out_bits_data_0 = '0;
  wire  [63:0] adw_g_io_out_bits_data_1, adw_i_io_out_bits_data_1;
  logic [63:0] adw_s0_io_out_bits_data_1 = '0, adw_s1_io_out_bits_data_1 = '0;
  wire  [63:0] adw_g_io_out_bits_data_2, adw_i_io_out_bits_data_2;
  logic [63:0] adw_s0_io_out_bits_data_2 = '0, adw_s1_io_out_bits_data_2 = '0;
  wire  [63:0] adw_g_io_out_bits_data_3, adw_i_io_out_bits_data_3;
  logic [63:0] adw_s0_io_out_bits_data_3 = '0, adw_s1_io_out_bits_data_3 = '0;
  wire  [63:0] adw_g_io_out_bits_data_4, adw_i_io_out_bits_data_4;
  logic [63:0] adw_s0_io_out_bits_data_4 = '0, adw_s1_io_out_bits_data_4 = '0;
  wire  [63:0] adw_g_io_out_bits_data_5, adw_i_io_out_bits_data_5;
  logic [63:0] adw_s0_io_out_bits_data_5 = '0, adw_s1_io_out_bits_data_5 = '0;
  wire  [63:0] adw_g_io_out_bits_data_6, adw_i_io_out_bits_data_6;
  logic [63:0] adw_s0_io_out_bits_data_6 = '0, adw_s1_io_out_bits_data_6 = '0;
  wire  [63:0] adw_g_io_out_bits_data_7, adw_i_io_out_bits_data_7;
  logic [63:0] adw_s0_io_out_bits_data_7 = '0, adw_s1_io_out_bits_data_7 = '0;
  logic [0:0] adw_armed = '0;
  int adw_armed_at = -1;
  Arbiter1_L1BankedDataWriteReq adw_u_gold (
    .io_in_0_valid(adw_io_in_0_valid),
    .io_in_0_bits_wmask(adw_io_in_0_bits_wmask),
    .io_in_0_bits_data_0(adw_io_in_0_bits_data_0),
    .io_in_0_bits_data_1(adw_io_in_0_bits_data_1),
    .io_in_0_bits_data_2(adw_io_in_0_bits_data_2),
    .io_in_0_bits_data_3(adw_io_in_0_bits_data_3),
    .io_in_0_bits_data_4(adw_io_in_0_bits_data_4),
    .io_in_0_bits_data_5(adw_io_in_0_bits_data_5),
    .io_in_0_bits_data_6(adw_io_in_0_bits_data_6),
    .io_in_0_bits_data_7(adw_io_in_0_bits_data_7),
    .io_out_valid(adw_g_io_out_valid),
    .io_out_bits_wmask(adw_g_io_out_bits_wmask),
    .io_out_bits_data_0(adw_g_io_out_bits_data_0),
    .io_out_bits_data_1(adw_g_io_out_bits_data_1),
    .io_out_bits_data_2(adw_g_io_out_bits_data_2),
    .io_out_bits_data_3(adw_g_io_out_bits_data_3),
    .io_out_bits_data_4(adw_g_io_out_bits_data_4),
    .io_out_bits_data_5(adw_g_io_out_bits_data_5),
    .io_out_bits_data_6(adw_g_io_out_bits_data_6),
    .io_out_bits_data_7(adw_g_io_out_bits_data_7)
  );
  Arbiter1_L1BankedDataWriteReq_xs adw_u_impl (
    .io_in_0_valid(adw_io_in_0_valid),
    .io_in_0_bits_wmask(adw_io_in_0_bits_wmask),
    .io_in_0_bits_data_0(adw_io_in_0_bits_data_0),
    .io_in_0_bits_data_1(adw_io_in_0_bits_data_1),
    .io_in_0_bits_data_2(adw_io_in_0_bits_data_2),
    .io_in_0_bits_data_3(adw_io_in_0_bits_data_3),
    .io_in_0_bits_data_4(adw_io_in_0_bits_data_4),
    .io_in_0_bits_data_5(adw_io_in_0_bits_data_5),
    .io_in_0_bits_data_6(adw_io_in_0_bits_data_6),
    .io_in_0_bits_data_7(adw_io_in_0_bits_data_7),
    .io_out_valid(adw_i_io_out_valid),
    .io_out_bits_wmask(adw_i_io_out_bits_wmask),
    .io_out_bits_data_0(adw_i_io_out_bits_data_0),
    .io_out_bits_data_1(adw_i_io_out_bits_data_1),
    .io_out_bits_data_2(adw_i_io_out_bits_data_2),
    .io_out_bits_data_3(adw_i_io_out_bits_data_3),
    .io_out_bits_data_4(adw_i_io_out_bits_data_4),
    .io_out_bits_data_5(adw_i_io_out_bits_data_5),
    .io_out_bits_data_6(adw_i_io_out_bits_data_6),
    .io_out_bits_data_7(adw_i_io_out_bits_data_7)
  );

  // ================= Arbiter1_L1BankedDataWriteReqCtrl =================
  int unsigned adc_mode = 0;
  logic adc_io_in_0_valid;
  logic [3:0] adc_io_in_0_bits_way_en;
  logic [47:0] adc_io_in_0_bits_addr;
  wire  adc_g_io_out_valid, adc_i_io_out_valid;
  logic adc_s0_io_out_valid = '0, adc_s1_io_out_valid = '0;
  wire  [3:0] adc_g_io_out_bits_way_en, adc_i_io_out_bits_way_en;
  logic [3:0] adc_s0_io_out_bits_way_en = '0, adc_s1_io_out_bits_way_en = '0;
  wire  [47:0] adc_g_io_out_bits_addr, adc_i_io_out_bits_addr;
  logic [47:0] adc_s0_io_out_bits_addr = '0, adc_s1_io_out_bits_addr = '0;
  logic [0:0] adc_armed = '0;
  int adc_armed_at = -1;
  Arbiter1_L1BankedDataWriteReqCtrl adc_u_gold (
    .io_in_0_valid(adc_io_in_0_valid),
    .io_in_0_bits_way_en(adc_io_in_0_bits_way_en),
    .io_in_0_bits_addr(adc_io_in_0_bits_addr),
    .io_out_valid(adc_g_io_out_valid),
    .io_out_bits_way_en(adc_g_io_out_bits_way_en),
    .io_out_bits_addr(adc_g_io_out_bits_addr)
  );
  Arbiter1_L1BankedDataWriteReqCtrl_xs adc_u_impl (
    .io_in_0_valid(adc_io_in_0_valid),
    .io_in_0_bits_way_en(adc_io_in_0_bits_way_en),
    .io_in_0_bits_addr(adc_io_in_0_bits_addr),
    .io_out_valid(adc_i_io_out_valid),
    .io_out_bits_way_en(adc_i_io_out_bits_way_en),
    .io_out_bits_addr(adc_i_io_out_bits_addr)
  );

  // ================= TreeArbiter =================
  int unsigned tra_mode = 0;
  wire  tra_g_io_in_0_ready, tra_i_io_in_0_ready;
  logic tra_s0_io_in_0_ready = '0, tra_s1_io_in_0_ready = '0;
  logic tra_io_in_0_valid;
  logic [3:0] tra_io_in_0_bits_source;
  logic [4:0] tra_io_in_0_bits_cmd;
  logic [47:0] tra_io_in_0_bits_addr;
  logic [49:0] tra_io_in_0_bits_vaddr;
  logic tra_io_in_0_bits_full_overwrite;
  logic [2:0] tra_io_in_0_bits_word_idx;
  logic [127:0] tra_io_in_0_bits_amo_data;
  logic [15:0] tra_io_in_0_bits_amo_mask;
  logic [127:0] tra_io_in_0_bits_amo_cmp;
  logic [1:0] tra_io_in_0_bits_req_coh_state;
  logic [5:0] tra_io_in_0_bits_id;
  logic tra_io_in_0_bits_isBtoT;
  logic [3:0] tra_io_in_0_bits_occupy_way;
  logic tra_io_in_0_bits_cancel;
  logic [511:0] tra_io_in_0_bits_store_data;
  logic [63:0] tra_io_in_0_bits_store_mask;
  wire  tra_g_io_in_1_ready, tra_i_io_in_1_ready;
  logic tra_s0_io_in_1_ready = '0, tra_s1_io_in_1_ready = '0;
  logic tra_io_in_1_valid;
  logic [3:0] tra_io_in_1_bits_source;
  logic [2:0] tra_io_in_1_bits_pf_source;
  logic [4:0] tra_io_in_1_bits_cmd;
  logic [47:0] tra_io_in_1_bits_addr;
  logic [49:0] tra_io_in_1_bits_vaddr;
  logic [1:0] tra_io_in_1_bits_req_coh_state;
  logic tra_io_in_1_bits_isBtoT;
  logic [3:0] tra_io_in_1_bits_occupy_way;
  logic tra_io_in_1_bits_cancel;
  wire  tra_g_io_in_2_ready, tra_i_io_in_2_ready;
  logic tra_s0_io_in_2_ready = '0, tra_s1_io_in_2_ready = '0;
  logic tra_io_in_2_valid;
  logic [3:0] tra_io_in_2_bits_source;
  logic [2:0] tra_io_in_2_bits_pf_source;
  logic [4:0] tra_io_in_2_bits_cmd;
  logic [47:0] tra_io_in_2_bits_addr;
  logic [49:0] tra_io_in_2_bits_vaddr;
  logic [1:0] tra_io_in_2_bits_req_coh_state;
  logic tra_io_in_2_bits_isBtoT;
  logic [3:0] tra_io_in_2_bits_occupy_way;
  logic tra_io_in_2_bits_cancel;
  wire  tra_g_io_in_3_ready, tra_i_io_in_3_ready;
  logic tra_s0_io_in_3_ready = '0, tra_s1_io_in_3_ready = '0;
  logic tra_io_in_3_valid;
  logic [3:0] tra_io_in_3_bits_source;
  logic [2:0] tra_io_in_3_bits_pf_source;
  logic [4:0] tra_io_in_3_bits_cmd;
  logic [47:0] tra_io_in_3_bits_addr;
  logic [49:0] tra_io_in_3_bits_vaddr;
  logic [1:0] tra_io_in_3_bits_req_coh_state;
  logic tra_io_in_3_bits_isBtoT;
  logic [3:0] tra_io_in_3_bits_occupy_way;
  logic tra_io_in_3_bits_cancel;
  logic tra_io_out_ready;
  wire  tra_g_io_out_valid, tra_i_io_out_valid;
  logic tra_s0_io_out_valid = '0, tra_s1_io_out_valid = '0;
  wire  [3:0] tra_g_io_out_bits_source, tra_i_io_out_bits_source;
  logic [3:0] tra_s0_io_out_bits_source = '0, tra_s1_io_out_bits_source = '0;
  wire  [2:0] tra_g_io_out_bits_pf_source, tra_i_io_out_bits_pf_source;
  logic [2:0] tra_s0_io_out_bits_pf_source = '0, tra_s1_io_out_bits_pf_source = '0;
  wire  [4:0] tra_g_io_out_bits_cmd, tra_i_io_out_bits_cmd;
  logic [4:0] tra_s0_io_out_bits_cmd = '0, tra_s1_io_out_bits_cmd = '0;
  wire  [47:0] tra_g_io_out_bits_addr, tra_i_io_out_bits_addr;
  logic [47:0] tra_s0_io_out_bits_addr = '0, tra_s1_io_out_bits_addr = '0;
  wire  [49:0] tra_g_io_out_bits_vaddr, tra_i_io_out_bits_vaddr;
  logic [49:0] tra_s0_io_out_bits_vaddr = '0, tra_s1_io_out_bits_vaddr = '0;
  wire  tra_g_io_out_bits_full_overwrite, tra_i_io_out_bits_full_overwrite;
  logic tra_s0_io_out_bits_full_overwrite = '0, tra_s1_io_out_bits_full_overwrite = '0;
  wire  [2:0] tra_g_io_out_bits_word_idx, tra_i_io_out_bits_word_idx;
  logic [2:0] tra_s0_io_out_bits_word_idx = '0, tra_s1_io_out_bits_word_idx = '0;
  wire  [127:0] tra_g_io_out_bits_amo_data, tra_i_io_out_bits_amo_data;
  logic [127:0] tra_s0_io_out_bits_amo_data = '0, tra_s1_io_out_bits_amo_data = '0;
  wire  [15:0] tra_g_io_out_bits_amo_mask, tra_i_io_out_bits_amo_mask;
  logic [15:0] tra_s0_io_out_bits_amo_mask = '0, tra_s1_io_out_bits_amo_mask = '0;
  wire  [127:0] tra_g_io_out_bits_amo_cmp, tra_i_io_out_bits_amo_cmp;
  logic [127:0] tra_s0_io_out_bits_amo_cmp = '0, tra_s1_io_out_bits_amo_cmp = '0;
  wire  [1:0] tra_g_io_out_bits_req_coh_state, tra_i_io_out_bits_req_coh_state;
  logic [1:0] tra_s0_io_out_bits_req_coh_state = '0, tra_s1_io_out_bits_req_coh_state = '0;
  wire  [5:0] tra_g_io_out_bits_id, tra_i_io_out_bits_id;
  logic [5:0] tra_s0_io_out_bits_id = '0, tra_s1_io_out_bits_id = '0;
  wire  tra_g_io_out_bits_isBtoT, tra_i_io_out_bits_isBtoT;
  logic tra_s0_io_out_bits_isBtoT = '0, tra_s1_io_out_bits_isBtoT = '0;
  wire  [3:0] tra_g_io_out_bits_occupy_way, tra_i_io_out_bits_occupy_way;
  logic [3:0] tra_s0_io_out_bits_occupy_way = '0, tra_s1_io_out_bits_occupy_way = '0;
  wire  tra_g_io_out_bits_cancel, tra_i_io_out_bits_cancel;
  logic tra_s0_io_out_bits_cancel = '0, tra_s1_io_out_bits_cancel = '0;
  wire  [511:0] tra_g_io_out_bits_store_data, tra_i_io_out_bits_store_data;
  logic [511:0] tra_s0_io_out_bits_store_data = '0, tra_s1_io_out_bits_store_data = '0;
  wire  [63:0] tra_g_io_out_bits_store_mask, tra_i_io_out_bits_store_mask;
  logic [63:0] tra_s0_io_out_bits_store_mask = '0, tra_s1_io_out_bits_store_mask = '0;
  int tra_cov_win0 = 0;
  int tra_cov_win1 = 0;
  int tra_cov_win2 = 0;
  int tra_cov_win3 = 0;
  int tra_cov_none = 0;
  int tra_cov_stall = 0;
  logic [0:0] tra_armed = '0;
  int tra_armed_at = -1;
  TreeArbiter tra_u_gold (
    .io_in_0_ready(tra_g_io_in_0_ready),
    .io_in_0_valid(tra_io_in_0_valid),
    .io_in_0_bits_source(tra_io_in_0_bits_source),
    .io_in_0_bits_cmd(tra_io_in_0_bits_cmd),
    .io_in_0_bits_addr(tra_io_in_0_bits_addr),
    .io_in_0_bits_vaddr(tra_io_in_0_bits_vaddr),
    .io_in_0_bits_full_overwrite(tra_io_in_0_bits_full_overwrite),
    .io_in_0_bits_word_idx(tra_io_in_0_bits_word_idx),
    .io_in_0_bits_amo_data(tra_io_in_0_bits_amo_data),
    .io_in_0_bits_amo_mask(tra_io_in_0_bits_amo_mask),
    .io_in_0_bits_amo_cmp(tra_io_in_0_bits_amo_cmp),
    .io_in_0_bits_req_coh_state(tra_io_in_0_bits_req_coh_state),
    .io_in_0_bits_id(tra_io_in_0_bits_id),
    .io_in_0_bits_isBtoT(tra_io_in_0_bits_isBtoT),
    .io_in_0_bits_occupy_way(tra_io_in_0_bits_occupy_way),
    .io_in_0_bits_cancel(tra_io_in_0_bits_cancel),
    .io_in_0_bits_store_data(tra_io_in_0_bits_store_data),
    .io_in_0_bits_store_mask(tra_io_in_0_bits_store_mask),
    .io_in_1_ready(tra_g_io_in_1_ready),
    .io_in_1_valid(tra_io_in_1_valid),
    .io_in_1_bits_source(tra_io_in_1_bits_source),
    .io_in_1_bits_pf_source(tra_io_in_1_bits_pf_source),
    .io_in_1_bits_cmd(tra_io_in_1_bits_cmd),
    .io_in_1_bits_addr(tra_io_in_1_bits_addr),
    .io_in_1_bits_vaddr(tra_io_in_1_bits_vaddr),
    .io_in_1_bits_req_coh_state(tra_io_in_1_bits_req_coh_state),
    .io_in_1_bits_isBtoT(tra_io_in_1_bits_isBtoT),
    .io_in_1_bits_occupy_way(tra_io_in_1_bits_occupy_way),
    .io_in_1_bits_cancel(tra_io_in_1_bits_cancel),
    .io_in_2_ready(tra_g_io_in_2_ready),
    .io_in_2_valid(tra_io_in_2_valid),
    .io_in_2_bits_source(tra_io_in_2_bits_source),
    .io_in_2_bits_pf_source(tra_io_in_2_bits_pf_source),
    .io_in_2_bits_cmd(tra_io_in_2_bits_cmd),
    .io_in_2_bits_addr(tra_io_in_2_bits_addr),
    .io_in_2_bits_vaddr(tra_io_in_2_bits_vaddr),
    .io_in_2_bits_req_coh_state(tra_io_in_2_bits_req_coh_state),
    .io_in_2_bits_isBtoT(tra_io_in_2_bits_isBtoT),
    .io_in_2_bits_occupy_way(tra_io_in_2_bits_occupy_way),
    .io_in_2_bits_cancel(tra_io_in_2_bits_cancel),
    .io_in_3_ready(tra_g_io_in_3_ready),
    .io_in_3_valid(tra_io_in_3_valid),
    .io_in_3_bits_source(tra_io_in_3_bits_source),
    .io_in_3_bits_pf_source(tra_io_in_3_bits_pf_source),
    .io_in_3_bits_cmd(tra_io_in_3_bits_cmd),
    .io_in_3_bits_addr(tra_io_in_3_bits_addr),
    .io_in_3_bits_vaddr(tra_io_in_3_bits_vaddr),
    .io_in_3_bits_req_coh_state(tra_io_in_3_bits_req_coh_state),
    .io_in_3_bits_isBtoT(tra_io_in_3_bits_isBtoT),
    .io_in_3_bits_occupy_way(tra_io_in_3_bits_occupy_way),
    .io_in_3_bits_cancel(tra_io_in_3_bits_cancel),
    .io_out_ready(tra_io_out_ready),
    .io_out_valid(tra_g_io_out_valid),
    .io_out_bits_source(tra_g_io_out_bits_source),
    .io_out_bits_pf_source(tra_g_io_out_bits_pf_source),
    .io_out_bits_cmd(tra_g_io_out_bits_cmd),
    .io_out_bits_addr(tra_g_io_out_bits_addr),
    .io_out_bits_vaddr(tra_g_io_out_bits_vaddr),
    .io_out_bits_full_overwrite(tra_g_io_out_bits_full_overwrite),
    .io_out_bits_word_idx(tra_g_io_out_bits_word_idx),
    .io_out_bits_amo_data(tra_g_io_out_bits_amo_data),
    .io_out_bits_amo_mask(tra_g_io_out_bits_amo_mask),
    .io_out_bits_amo_cmp(tra_g_io_out_bits_amo_cmp),
    .io_out_bits_req_coh_state(tra_g_io_out_bits_req_coh_state),
    .io_out_bits_id(tra_g_io_out_bits_id),
    .io_out_bits_isBtoT(tra_g_io_out_bits_isBtoT),
    .io_out_bits_occupy_way(tra_g_io_out_bits_occupy_way),
    .io_out_bits_cancel(tra_g_io_out_bits_cancel),
    .io_out_bits_store_data(tra_g_io_out_bits_store_data),
    .io_out_bits_store_mask(tra_g_io_out_bits_store_mask)
  );
  TreeArbiter_xs tra_u_impl (
    .io_in_0_ready(tra_i_io_in_0_ready),
    .io_in_0_valid(tra_io_in_0_valid),
    .io_in_0_bits_source(tra_io_in_0_bits_source),
    .io_in_0_bits_cmd(tra_io_in_0_bits_cmd),
    .io_in_0_bits_addr(tra_io_in_0_bits_addr),
    .io_in_0_bits_vaddr(tra_io_in_0_bits_vaddr),
    .io_in_0_bits_full_overwrite(tra_io_in_0_bits_full_overwrite),
    .io_in_0_bits_word_idx(tra_io_in_0_bits_word_idx),
    .io_in_0_bits_amo_data(tra_io_in_0_bits_amo_data),
    .io_in_0_bits_amo_mask(tra_io_in_0_bits_amo_mask),
    .io_in_0_bits_amo_cmp(tra_io_in_0_bits_amo_cmp),
    .io_in_0_bits_req_coh_state(tra_io_in_0_bits_req_coh_state),
    .io_in_0_bits_id(tra_io_in_0_bits_id),
    .io_in_0_bits_isBtoT(tra_io_in_0_bits_isBtoT),
    .io_in_0_bits_occupy_way(tra_io_in_0_bits_occupy_way),
    .io_in_0_bits_cancel(tra_io_in_0_bits_cancel),
    .io_in_0_bits_store_data(tra_io_in_0_bits_store_data),
    .io_in_0_bits_store_mask(tra_io_in_0_bits_store_mask),
    .io_in_1_ready(tra_i_io_in_1_ready),
    .io_in_1_valid(tra_io_in_1_valid),
    .io_in_1_bits_source(tra_io_in_1_bits_source),
    .io_in_1_bits_pf_source(tra_io_in_1_bits_pf_source),
    .io_in_1_bits_cmd(tra_io_in_1_bits_cmd),
    .io_in_1_bits_addr(tra_io_in_1_bits_addr),
    .io_in_1_bits_vaddr(tra_io_in_1_bits_vaddr),
    .io_in_1_bits_req_coh_state(tra_io_in_1_bits_req_coh_state),
    .io_in_1_bits_isBtoT(tra_io_in_1_bits_isBtoT),
    .io_in_1_bits_occupy_way(tra_io_in_1_bits_occupy_way),
    .io_in_1_bits_cancel(tra_io_in_1_bits_cancel),
    .io_in_2_ready(tra_i_io_in_2_ready),
    .io_in_2_valid(tra_io_in_2_valid),
    .io_in_2_bits_source(tra_io_in_2_bits_source),
    .io_in_2_bits_pf_source(tra_io_in_2_bits_pf_source),
    .io_in_2_bits_cmd(tra_io_in_2_bits_cmd),
    .io_in_2_bits_addr(tra_io_in_2_bits_addr),
    .io_in_2_bits_vaddr(tra_io_in_2_bits_vaddr),
    .io_in_2_bits_req_coh_state(tra_io_in_2_bits_req_coh_state),
    .io_in_2_bits_isBtoT(tra_io_in_2_bits_isBtoT),
    .io_in_2_bits_occupy_way(tra_io_in_2_bits_occupy_way),
    .io_in_2_bits_cancel(tra_io_in_2_bits_cancel),
    .io_in_3_ready(tra_i_io_in_3_ready),
    .io_in_3_valid(tra_io_in_3_valid),
    .io_in_3_bits_source(tra_io_in_3_bits_source),
    .io_in_3_bits_pf_source(tra_io_in_3_bits_pf_source),
    .io_in_3_bits_cmd(tra_io_in_3_bits_cmd),
    .io_in_3_bits_addr(tra_io_in_3_bits_addr),
    .io_in_3_bits_vaddr(tra_io_in_3_bits_vaddr),
    .io_in_3_bits_req_coh_state(tra_io_in_3_bits_req_coh_state),
    .io_in_3_bits_isBtoT(tra_io_in_3_bits_isBtoT),
    .io_in_3_bits_occupy_way(tra_io_in_3_bits_occupy_way),
    .io_in_3_bits_cancel(tra_io_in_3_bits_cancel),
    .io_out_ready(tra_io_out_ready),
    .io_out_valid(tra_i_io_out_valid),
    .io_out_bits_source(tra_i_io_out_bits_source),
    .io_out_bits_pf_source(tra_i_io_out_bits_pf_source),
    .io_out_bits_cmd(tra_i_io_out_bits_cmd),
    .io_out_bits_addr(tra_i_io_out_bits_addr),
    .io_out_bits_vaddr(tra_i_io_out_bits_vaddr),
    .io_out_bits_full_overwrite(tra_i_io_out_bits_full_overwrite),
    .io_out_bits_word_idx(tra_i_io_out_bits_word_idx),
    .io_out_bits_amo_data(tra_i_io_out_bits_amo_data),
    .io_out_bits_amo_mask(tra_i_io_out_bits_amo_mask),
    .io_out_bits_amo_cmp(tra_i_io_out_bits_amo_cmp),
    .io_out_bits_req_coh_state(tra_i_io_out_bits_req_coh_state),
    .io_out_bits_id(tra_i_io_out_bits_id),
    .io_out_bits_isBtoT(tra_i_io_out_bits_isBtoT),
    .io_out_bits_occupy_way(tra_i_io_out_bits_occupy_way),
    .io_out_bits_cancel(tra_i_io_out_bits_cancel),
    .io_out_bits_store_data(tra_i_io_out_bits_store_data),
    .io_out_bits_store_mask(tra_i_io_out_bits_store_mask)
  );

  // ================= MissReadyGen =================
  int unsigned mrg_mode = 0;
  wire  mrg_g_io_in_0_ready, mrg_i_io_in_0_ready;
  logic mrg_s0_io_in_0_ready = '0, mrg_s1_io_in_0_ready = '0;
  logic mrg_io_in_0_valid;
  logic [3:0] mrg_io_in_0_bits_source;
  logic [47:0] mrg_io_in_0_bits_addr;
  logic [49:0] mrg_io_in_0_bits_vaddr;
  wire  mrg_g_io_in_1_ready, mrg_i_io_in_1_ready;
  logic mrg_s0_io_in_1_ready = '0, mrg_s1_io_in_1_ready = '0;
  logic mrg_io_in_1_valid;
  logic [3:0] mrg_io_in_1_bits_source;
  logic [47:0] mrg_io_in_1_bits_addr;
  logic [49:0] mrg_io_in_1_bits_vaddr;
  wire  mrg_g_io_in_2_ready, mrg_i_io_in_2_ready;
  logic mrg_s0_io_in_2_ready = '0, mrg_s1_io_in_2_ready = '0;
  logic mrg_io_in_2_valid;
  logic [3:0] mrg_io_in_2_bits_source;
  logic [47:0] mrg_io_in_2_bits_addr;
  logic [49:0] mrg_io_in_2_bits_vaddr;
  wire  mrg_g_io_in_3_ready, mrg_i_io_in_3_ready;
  logic mrg_s0_io_in_3_ready = '0, mrg_s1_io_in_3_ready = '0;
  logic [3:0] mrg_io_in_3_bits_source;
  logic [47:0] mrg_io_in_3_bits_addr;
  logic [49:0] mrg_io_in_3_bits_vaddr;
  wire  [3:0] mrg_g_io_queryMQ_0_req_bits_source, mrg_i_io_queryMQ_0_req_bits_source;
  logic [3:0] mrg_s0_io_queryMQ_0_req_bits_source = '0, mrg_s1_io_queryMQ_0_req_bits_source = '0;
  wire  [47:0] mrg_g_io_queryMQ_0_req_bits_addr, mrg_i_io_queryMQ_0_req_bits_addr;
  logic [47:0] mrg_s0_io_queryMQ_0_req_bits_addr = '0, mrg_s1_io_queryMQ_0_req_bits_addr = '0;
  wire  [49:0] mrg_g_io_queryMQ_0_req_bits_vaddr, mrg_i_io_queryMQ_0_req_bits_vaddr;
  logic [49:0] mrg_s0_io_queryMQ_0_req_bits_vaddr = '0, mrg_s1_io_queryMQ_0_req_bits_vaddr = '0;
  logic mrg_io_queryMQ_0_ready;
  wire  [3:0] mrg_g_io_queryMQ_1_req_bits_source, mrg_i_io_queryMQ_1_req_bits_source;
  logic [3:0] mrg_s0_io_queryMQ_1_req_bits_source = '0, mrg_s1_io_queryMQ_1_req_bits_source = '0;
  wire  [47:0] mrg_g_io_queryMQ_1_req_bits_addr, mrg_i_io_queryMQ_1_req_bits_addr;
  logic [47:0] mrg_s0_io_queryMQ_1_req_bits_addr = '0, mrg_s1_io_queryMQ_1_req_bits_addr = '0;
  wire  [49:0] mrg_g_io_queryMQ_1_req_bits_vaddr, mrg_i_io_queryMQ_1_req_bits_vaddr;
  logic [49:0] mrg_s0_io_queryMQ_1_req_bits_vaddr = '0, mrg_s1_io_queryMQ_1_req_bits_vaddr = '0;
  logic mrg_io_queryMQ_1_ready;
  wire  [3:0] mrg_g_io_queryMQ_2_req_bits_source, mrg_i_io_queryMQ_2_req_bits_source;
  logic [3:0] mrg_s0_io_queryMQ_2_req_bits_source = '0, mrg_s1_io_queryMQ_2_req_bits_source = '0;
  wire  [47:0] mrg_g_io_queryMQ_2_req_bits_addr, mrg_i_io_queryMQ_2_req_bits_addr;
  logic [47:0] mrg_s0_io_queryMQ_2_req_bits_addr = '0, mrg_s1_io_queryMQ_2_req_bits_addr = '0;
  wire  [49:0] mrg_g_io_queryMQ_2_req_bits_vaddr, mrg_i_io_queryMQ_2_req_bits_vaddr;
  logic [49:0] mrg_s0_io_queryMQ_2_req_bits_vaddr = '0, mrg_s1_io_queryMQ_2_req_bits_vaddr = '0;
  logic mrg_io_queryMQ_2_ready;
  wire  [3:0] mrg_g_io_queryMQ_3_req_bits_source, mrg_i_io_queryMQ_3_req_bits_source;
  logic [3:0] mrg_s0_io_queryMQ_3_req_bits_source = '0, mrg_s1_io_queryMQ_3_req_bits_source = '0;
  wire  [47:0] mrg_g_io_queryMQ_3_req_bits_addr, mrg_i_io_queryMQ_3_req_bits_addr;
  logic [47:0] mrg_s0_io_queryMQ_3_req_bits_addr = '0, mrg_s1_io_queryMQ_3_req_bits_addr = '0;
  wire  [49:0] mrg_g_io_queryMQ_3_req_bits_vaddr, mrg_i_io_queryMQ_3_req_bits_vaddr;
  logic [49:0] mrg_s0_io_queryMQ_3_req_bits_vaddr = '0, mrg_s1_io_queryMQ_3_req_bits_vaddr = '0;
  logic mrg_io_queryMQ_3_ready;
  int mrg_cov_rdy0 = 0;
  int mrg_cov_rdy1 = 0;
  int mrg_cov_rdy2 = 0;
  int mrg_cov_rdy3 = 0;
  int mrg_cov_block1 = 0;
  int mrg_cov_block2 = 0;
  int mrg_cov_block3 = 0;
  logic [0:0] mrg_armed = '0;
  int mrg_armed_at = -1;
  MissReadyGen mrg_u_gold (
    .io_in_0_ready(mrg_g_io_in_0_ready),
    .io_in_0_valid(mrg_io_in_0_valid),
    .io_in_0_bits_source(mrg_io_in_0_bits_source),
    .io_in_0_bits_addr(mrg_io_in_0_bits_addr),
    .io_in_0_bits_vaddr(mrg_io_in_0_bits_vaddr),
    .io_in_1_ready(mrg_g_io_in_1_ready),
    .io_in_1_valid(mrg_io_in_1_valid),
    .io_in_1_bits_source(mrg_io_in_1_bits_source),
    .io_in_1_bits_addr(mrg_io_in_1_bits_addr),
    .io_in_1_bits_vaddr(mrg_io_in_1_bits_vaddr),
    .io_in_2_ready(mrg_g_io_in_2_ready),
    .io_in_2_valid(mrg_io_in_2_valid),
    .io_in_2_bits_source(mrg_io_in_2_bits_source),
    .io_in_2_bits_addr(mrg_io_in_2_bits_addr),
    .io_in_2_bits_vaddr(mrg_io_in_2_bits_vaddr),
    .io_in_3_ready(mrg_g_io_in_3_ready),
    .io_in_3_bits_source(mrg_io_in_3_bits_source),
    .io_in_3_bits_addr(mrg_io_in_3_bits_addr),
    .io_in_3_bits_vaddr(mrg_io_in_3_bits_vaddr),
    .io_queryMQ_0_req_bits_source(mrg_g_io_queryMQ_0_req_bits_source),
    .io_queryMQ_0_req_bits_addr(mrg_g_io_queryMQ_0_req_bits_addr),
    .io_queryMQ_0_req_bits_vaddr(mrg_g_io_queryMQ_0_req_bits_vaddr),
    .io_queryMQ_0_ready(mrg_io_queryMQ_0_ready),
    .io_queryMQ_1_req_bits_source(mrg_g_io_queryMQ_1_req_bits_source),
    .io_queryMQ_1_req_bits_addr(mrg_g_io_queryMQ_1_req_bits_addr),
    .io_queryMQ_1_req_bits_vaddr(mrg_g_io_queryMQ_1_req_bits_vaddr),
    .io_queryMQ_1_ready(mrg_io_queryMQ_1_ready),
    .io_queryMQ_2_req_bits_source(mrg_g_io_queryMQ_2_req_bits_source),
    .io_queryMQ_2_req_bits_addr(mrg_g_io_queryMQ_2_req_bits_addr),
    .io_queryMQ_2_req_bits_vaddr(mrg_g_io_queryMQ_2_req_bits_vaddr),
    .io_queryMQ_2_ready(mrg_io_queryMQ_2_ready),
    .io_queryMQ_3_req_bits_source(mrg_g_io_queryMQ_3_req_bits_source),
    .io_queryMQ_3_req_bits_addr(mrg_g_io_queryMQ_3_req_bits_addr),
    .io_queryMQ_3_req_bits_vaddr(mrg_g_io_queryMQ_3_req_bits_vaddr),
    .io_queryMQ_3_ready(mrg_io_queryMQ_3_ready)
  );
  MissReadyGen_xs mrg_u_impl (
    .io_in_0_ready(mrg_i_io_in_0_ready),
    .io_in_0_valid(mrg_io_in_0_valid),
    .io_in_0_bits_source(mrg_io_in_0_bits_source),
    .io_in_0_bits_addr(mrg_io_in_0_bits_addr),
    .io_in_0_bits_vaddr(mrg_io_in_0_bits_vaddr),
    .io_in_1_ready(mrg_i_io_in_1_ready),
    .io_in_1_valid(mrg_io_in_1_valid),
    .io_in_1_bits_source(mrg_io_in_1_bits_source),
    .io_in_1_bits_addr(mrg_io_in_1_bits_addr),
    .io_in_1_bits_vaddr(mrg_io_in_1_bits_vaddr),
    .io_in_2_ready(mrg_i_io_in_2_ready),
    .io_in_2_valid(mrg_io_in_2_valid),
    .io_in_2_bits_source(mrg_io_in_2_bits_source),
    .io_in_2_bits_addr(mrg_io_in_2_bits_addr),
    .io_in_2_bits_vaddr(mrg_io_in_2_bits_vaddr),
    .io_in_3_ready(mrg_i_io_in_3_ready),
    .io_in_3_bits_source(mrg_io_in_3_bits_source),
    .io_in_3_bits_addr(mrg_io_in_3_bits_addr),
    .io_in_3_bits_vaddr(mrg_io_in_3_bits_vaddr),
    .io_queryMQ_0_req_bits_source(mrg_i_io_queryMQ_0_req_bits_source),
    .io_queryMQ_0_req_bits_addr(mrg_i_io_queryMQ_0_req_bits_addr),
    .io_queryMQ_0_req_bits_vaddr(mrg_i_io_queryMQ_0_req_bits_vaddr),
    .io_queryMQ_0_ready(mrg_io_queryMQ_0_ready),
    .io_queryMQ_1_req_bits_source(mrg_i_io_queryMQ_1_req_bits_source),
    .io_queryMQ_1_req_bits_addr(mrg_i_io_queryMQ_1_req_bits_addr),
    .io_queryMQ_1_req_bits_vaddr(mrg_i_io_queryMQ_1_req_bits_vaddr),
    .io_queryMQ_1_ready(mrg_io_queryMQ_1_ready),
    .io_queryMQ_2_req_bits_source(mrg_i_io_queryMQ_2_req_bits_source),
    .io_queryMQ_2_req_bits_addr(mrg_i_io_queryMQ_2_req_bits_addr),
    .io_queryMQ_2_req_bits_vaddr(mrg_i_io_queryMQ_2_req_bits_vaddr),
    .io_queryMQ_2_ready(mrg_io_queryMQ_2_ready),
    .io_queryMQ_3_req_bits_source(mrg_i_io_queryMQ_3_req_bits_source),
    .io_queryMQ_3_req_bits_addr(mrg_i_io_queryMQ_3_req_bits_addr),
    .io_queryMQ_3_req_bits_vaddr(mrg_i_io_queryMQ_3_req_bits_vaddr),
    .io_queryMQ_3_ready(mrg_io_queryMQ_3_ready)
  );

  // ================= PrefetcherMonitor =================
  int unsigned pfm_mode = 0;
  logic pfm_reset;
  logic pfm_io_timely_total_prefetch;
  logic pfm_io_timely_late_hit_prefetch;
  logic pfm_io_timely_late_miss_prefetch;
  logic pfm_io_validity_good_prefetch;
  logic pfm_io_validity_bad_prefetch;
  wire  pfm_g_io_pf_ctrl_enable, pfm_i_io_pf_ctrl_enable;
  logic pfm_s0_io_pf_ctrl_enable = '0, pfm_s1_io_pf_ctrl_enable = '0;
  wire  pfm_g_io_pf_ctrl_confidence, pfm_i_io_pf_ctrl_confidence;
  logic pfm_s0_io_pf_ctrl_confidence = '0, pfm_s1_io_pf_ctrl_confidence = '0;
  int pfm_cov_timely_reset = 0;
  int pfm_cov_validity_reset = 0;
  int pfm_cov_trigger_disable = 0;
  int pfm_cov_trigger_late_hit_only = 0;
  int pfm_cov_late_miss_masks_late_hit = 0;
  int pfm_cov_back_off_reset = 0;
  int pfm_cov_enable_off = 0;
  logic [0:0] pfm_armed = '0;
  int pfm_armed_at = -1;
  PrefetcherMonitor pfm_u_gold (
    .clock(clk),
    .reset(pfm_reset),
    .io_timely_total_prefetch(pfm_io_timely_total_prefetch),
    .io_timely_late_hit_prefetch(pfm_io_timely_late_hit_prefetch),
    .io_timely_late_miss_prefetch(pfm_io_timely_late_miss_prefetch),
    .io_validity_good_prefetch(pfm_io_validity_good_prefetch),
    .io_validity_bad_prefetch(pfm_io_validity_bad_prefetch),
    .io_pf_ctrl_enable(pfm_g_io_pf_ctrl_enable),
    .io_pf_ctrl_confidence(pfm_g_io_pf_ctrl_confidence)
  );
  PrefetcherMonitor_xs pfm_u_impl (
    .clock(clk),
    .reset(pfm_reset),
    .io_timely_total_prefetch(pfm_io_timely_total_prefetch),
    .io_timely_late_hit_prefetch(pfm_io_timely_late_hit_prefetch),
    .io_timely_late_miss_prefetch(pfm_io_timely_late_miss_prefetch),
    .io_validity_good_prefetch(pfm_io_validity_good_prefetch),
    .io_validity_bad_prefetch(pfm_io_validity_bad_prefetch),
    .io_pf_ctrl_enable(pfm_i_io_pf_ctrl_enable),
    .io_pf_ctrl_confidence(pfm_i_io_pf_ctrl_confidence)
  );

  // ================= FDPrefetcherMonitor =================
  int unsigned fdp_mode = 0;
  logic fdp_io_accuracy_useful_prefetch_0;
  logic fdp_io_accuracy_useful_prefetch_1;
  logic fdp_io_accuracy_useful_prefetch_2;
  logic fdp_io_timely_late_prefetch;
  logic fdp_io_pollution_demand_miss_0;
  logic fdp_io_pollution_demand_miss_1;
  logic fdp_io_pollution_demand_miss_2;
  logic fdp_io_pollution_cache_pollution_0;
  logic fdp_io_pollution_cache_pollution_1;
  logic fdp_io_pollution_cache_pollution_2;
  logic [0:0] fdp_armed = '0;
  int fdp_armed_at = -1;
  FDPrefetcherMonitor fdp_u_gold (
    .io_accuracy_useful_prefetch_0(fdp_io_accuracy_useful_prefetch_0),
    .io_accuracy_useful_prefetch_1(fdp_io_accuracy_useful_prefetch_1),
    .io_accuracy_useful_prefetch_2(fdp_io_accuracy_useful_prefetch_2),
    .io_timely_late_prefetch(fdp_io_timely_late_prefetch),
    .io_pollution_demand_miss_0(fdp_io_pollution_demand_miss_0),
    .io_pollution_demand_miss_1(fdp_io_pollution_demand_miss_1),
    .io_pollution_demand_miss_2(fdp_io_pollution_demand_miss_2),
    .io_pollution_cache_pollution_0(fdp_io_pollution_cache_pollution_0),
    .io_pollution_cache_pollution_1(fdp_io_pollution_cache_pollution_1),
    .io_pollution_cache_pollution_2(fdp_io_pollution_cache_pollution_2)
  );
  FDPrefetcherMonitor_xs fdp_u_impl (
    .io_accuracy_useful_prefetch_0(fdp_io_accuracy_useful_prefetch_0),
    .io_accuracy_useful_prefetch_1(fdp_io_accuracy_useful_prefetch_1),
    .io_accuracy_useful_prefetch_2(fdp_io_accuracy_useful_prefetch_2),
    .io_timely_late_prefetch(fdp_io_timely_late_prefetch),
    .io_pollution_demand_miss_0(fdp_io_pollution_demand_miss_0),
    .io_pollution_demand_miss_1(fdp_io_pollution_demand_miss_1),
    .io_pollution_demand_miss_2(fdp_io_pollution_demand_miss_2),
    .io_pollution_cache_pollution_0(fdp_io_pollution_cache_pollution_0),
    .io_pollution_cache_pollution_1(fdp_io_pollution_cache_pollution_1),
    .io_pollution_cache_pollution_2(fdp_io_pollution_cache_pollution_2)
  );

  initial begin
    if ($value$plusargs("ncycles=%d", NCYCLES)) ;
    for (cyc = 0; cyc < NCYCLES; cyc++) begin
      @(negedge clk);
      if (cyc % 4000 == 0) atw_mode = $urandom_range(0, 15);
      atw_io_in_0_valid = 1'($urandom);
      atw_io_in_0_bits_idx = 8'($urandom);
      atw_io_in_0_bits_way_en = 4'($urandom);
      atw_io_in_0_bits_tag = 36'({$urandom, $urandom});
      if (cyc % 4000 == 0) adw_mode = $urandom_range(0, 15);
      adw_io_in_0_valid = 1'($urandom);
      adw_io_in_0_bits_wmask = 8'($urandom);
      adw_io_in_0_bits_data_0 = 64'({$urandom, $urandom});
      adw_io_in_0_bits_data_1 = 64'({$urandom, $urandom});
      adw_io_in_0_bits_data_2 = 64'({$urandom, $urandom});
      adw_io_in_0_bits_data_3 = 64'({$urandom, $urandom});
      adw_io_in_0_bits_data_4 = 64'({$urandom, $urandom});
      adw_io_in_0_bits_data_5 = 64'({$urandom, $urandom});
      adw_io_in_0_bits_data_6 = 64'({$urandom, $urandom});
      adw_io_in_0_bits_data_7 = 64'({$urandom, $urandom});
      if (cyc % 4000 == 0) adc_mode = $urandom_range(0, 15);
      adc_io_in_0_valid = 1'($urandom);
      adc_io_in_0_bits_way_en = 4'($urandom);
      adc_io_in_0_bits_addr = 48'({$urandom, $urandom});
      if (cyc % 64 == 0) tra_mode = $urandom_range(0, 15);
      tra_io_in_0_valid = 1'($urandom);
      tra_io_in_0_bits_source = 4'($urandom);
      tra_io_in_0_bits_cmd = 5'($urandom);
      tra_io_in_0_bits_addr = 48'({$urandom, $urandom});
      tra_io_in_0_bits_vaddr = 50'({$urandom, $urandom});
      tra_io_in_0_bits_full_overwrite = 1'($urandom);
      tra_io_in_0_bits_word_idx = 3'($urandom);
      tra_io_in_0_bits_amo_data = 128'({$urandom, $urandom, $urandom, $urandom});
      tra_io_in_0_bits_amo_mask = 16'($urandom);
      tra_io_in_0_bits_amo_cmp = 128'({$urandom, $urandom, $urandom, $urandom});
      tra_io_in_0_bits_req_coh_state = 2'($urandom);
      tra_io_in_0_bits_id = 6'($urandom);
      tra_io_in_0_bits_isBtoT = 1'($urandom);
      tra_io_in_0_bits_occupy_way = 4'($urandom);
      tra_io_in_0_bits_cancel = 1'($urandom);
      tra_io_in_0_bits_store_data = 512'({$urandom, $urandom, $urandom, $urandom, $urandom, $urandom, $urandom, $urandom, $urandom, $urandom, $urandom, $urandom, $urandom, $urandom, $urandom, $urandom});
      tra_io_in_0_bits_store_mask = 64'({$urandom, $urandom});
      tra_io_in_1_valid = 1'($urandom);
      tra_io_in_1_bits_source = 4'($urandom);
      tra_io_in_1_bits_pf_source = 3'($urandom);
      tra_io_in_1_bits_cmd = 5'($urandom);
      tra_io_in_1_bits_addr = 48'({$urandom, $urandom});
      tra_io_in_1_bits_vaddr = 50'({$urandom, $urandom});
      tra_io_in_1_bits_req_coh_state = 2'($urandom);
      tra_io_in_1_bits_isBtoT = 1'($urandom);
      tra_io_in_1_bits_occupy_way = 4'($urandom);
      tra_io_in_1_bits_cancel = 1'($urandom);
      tra_io_in_2_valid = 1'($urandom);
      tra_io_in_2_bits_source = 4'($urandom);
      tra_io_in_2_bits_pf_source = 3'($urandom);
      tra_io_in_2_bits_cmd = 5'($urandom);
      tra_io_in_2_bits_addr = 48'({$urandom, $urandom});
      tra_io_in_2_bits_vaddr = 50'({$urandom, $urandom});
      tra_io_in_2_bits_req_coh_state = 2'($urandom);
      tra_io_in_2_bits_isBtoT = 1'($urandom);
      tra_io_in_2_bits_occupy_way = 4'($urandom);
      tra_io_in_2_bits_cancel = 1'($urandom);
      tra_io_in_3_valid = 1'($urandom);
      tra_io_in_3_bits_source = 4'($urandom);
      tra_io_in_3_bits_pf_source = 3'($urandom);
      tra_io_in_3_bits_cmd = 5'($urandom);
      tra_io_in_3_bits_addr = 48'({$urandom, $urandom});
      tra_io_in_3_bits_vaddr = 50'({$urandom, $urandom});
      tra_io_in_3_bits_req_coh_state = 2'($urandom);
      tra_io_in_3_bits_isBtoT = 1'($urandom);
      tra_io_in_3_bits_occupy_way = 4'($urandom);
      tra_io_in_3_bits_cancel = 1'($urandom);
      tra_io_out_ready = 1'($urandom);
      begin : stim_tra
        // valid 位图：mode 0-3 单热、4-7 全随机、8-11 稀疏（每路 1/4）、12-15 全 0
        case (tra_mode[3:2])
          2'd0: {tra_io_in_0_valid, tra_io_in_1_valid, tra_io_in_2_valid, tra_io_in_3_valid} = 4'b1000 >> $urandom_range(0, 3);
          2'd1: ;
          2'd2: {tra_io_in_0_valid, tra_io_in_1_valid, tra_io_in_2_valid, tra_io_in_3_valid} =
                  {$urandom_range(0,3)==0, $urandom_range(0,3)==0, $urandom_range(0,3)==0, $urandom_range(0,3)==0};
          2'd3: if ($urandom_range(0, 3) == 0) {tra_io_in_0_valid, tra_io_in_1_valid, tra_io_in_2_valid, tra_io_in_3_valid} = 4'b0;
        endcase
      end
      if (cyc % 16 == 0) mrg_mode = $urandom_range(0, 15);
      mrg_io_in_0_valid = 1'($urandom);
      mrg_io_in_0_bits_source = 4'($urandom);
      mrg_io_in_0_bits_addr = 48'({$urandom, $urandom});
      mrg_io_in_0_bits_vaddr = 50'({$urandom, $urandom});
      mrg_io_in_1_valid = 1'($urandom);
      mrg_io_in_1_bits_source = 4'($urandom);
      mrg_io_in_1_bits_addr = 48'({$urandom, $urandom});
      mrg_io_in_1_bits_vaddr = 50'({$urandom, $urandom});
      mrg_io_in_2_valid = 1'($urandom);
      mrg_io_in_2_bits_source = 4'($urandom);
      mrg_io_in_2_bits_addr = 48'({$urandom, $urandom});
      mrg_io_in_2_bits_vaddr = 50'({$urandom, $urandom});
      mrg_io_in_3_bits_source = 4'($urandom);
      mrg_io_in_3_bits_addr = 48'({$urandom, $urandom});
      mrg_io_in_3_bits_vaddr = 50'({$urandom, $urandom});
      mrg_io_queryMQ_0_ready = 1'($urandom);
      mrg_io_queryMQ_1_ready = 1'($urandom);
      mrg_io_queryMQ_2_ready = 1'($urandom);
      mrg_io_queryMQ_3_ready = 1'($urandom);
      begin : stim_mrg
        if (mrg_mode[0]) {mrg_io_in_0_valid, mrg_io_in_1_valid, mrg_io_in_2_valid} = 3'b0;
      end
      if (cyc % 6000 == 0) pfm_mode = $urandom_range(0, 15);
      pfm_io_timely_total_prefetch = 1'($urandom);
      pfm_io_timely_late_hit_prefetch = 1'($urandom);
      pfm_io_timely_late_miss_prefetch = 1'($urandom);
      pfm_io_validity_good_prefetch = 1'($urandom);
      pfm_io_validity_bad_prefetch = 1'($urandom);
      pfm_reset = (cyc < RESET_CYC);
      begin : stim_pfm
        int unsigned p_tot, p_lh, p_lm, p_good, p_bad;
        case (pfm_mode[2:0])
          3'd0: begin p_tot = 50; p_lh = 50; p_lm = 50; p_good = 50; p_bad = 50; end  // 全随机
          3'd1: begin p_tot = 60; p_lh = 5;  p_lm = 5;  p_good = 5;  p_bad = 95; end  // 坏预取多 -> trigger_disable
          3'd2: begin p_tot = 5;  p_lh = 97; p_lm = 2;  p_good = 50; p_bad = 50; end  // 晚到命中多 -> trigger_late_hit
          3'd3: begin p_tot = 5;  p_lh = 97; p_lm = 60; p_good = 50; p_bad = 50; end  // late_miss 压住 late_hit
          3'd4: begin p_tot = 0;  p_lh = 0;  p_lm = 0;  p_good = 0;  p_bad = 0;  end  // 安静：让退避计时走完
          3'd5: begin p_tot = 99; p_lh = 1;  p_lm = 30; p_good = 95; p_bad = 5;  end  // total 先到 1000
          default: begin p_tot = 50; p_lh = 90; p_lm = 25; p_good = 10; p_bad = 90; end
        endcase
        pfm_io_timely_total_prefetch     = $urandom_range(0, 99) < p_tot;
        pfm_io_timely_late_hit_prefetch  = $urandom_range(0, 99) < p_lh;
        pfm_io_timely_late_miss_prefetch = $urandom_range(0, 99) < p_lm;
        pfm_io_validity_good_prefetch    = $urandom_range(0, 99) < p_good;
        pfm_io_validity_bad_prefetch     = $urandom_range(0, 99) < p_bad;
      end
      if (cyc % 4000 == 0) fdp_mode = $urandom_range(0, 15);
      fdp_io_accuracy_useful_prefetch_0 = 1'($urandom);
      fdp_io_accuracy_useful_prefetch_1 = 1'($urandom);
      fdp_io_accuracy_useful_prefetch_2 = 1'($urandom);
      fdp_io_timely_late_prefetch = 1'($urandom);
      fdp_io_pollution_demand_miss_0 = 1'($urandom);
      fdp_io_pollution_demand_miss_1 = 1'($urandom);
      fdp_io_pollution_demand_miss_2 = 1'($urandom);
      fdp_io_pollution_cache_pollution_0 = 1'($urandom);
      fdp_io_pollution_cache_pollution_1 = 1'($urandom);
      fdp_io_pollution_cache_pollution_2 = 1'($urandom);
      #4;
      atw_armed = 1'b1;
      if (cyc >= RESET_CYC + 0 && (&atw_armed)) begin
        checks++;
        if (atw_g_io_out_valid !== atw_i_io_out_valid) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d Arbiter1_TagWriteReq.io_out_valid g=%h i=%h", cyc, atw_g_io_out_valid, atw_i_io_out_valid);
        end
        atw_s1_io_out_valid |= atw_g_io_out_valid;
        atw_s0_io_out_valid |= ~atw_g_io_out_valid;
        checks++;
        if (atw_g_io_out_bits_idx !== atw_i_io_out_bits_idx) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d Arbiter1_TagWriteReq.io_out_bits_idx g=%h i=%h", cyc, atw_g_io_out_bits_idx, atw_i_io_out_bits_idx);
        end
        atw_s1_io_out_bits_idx |= atw_g_io_out_bits_idx;
        atw_s0_io_out_bits_idx |= ~atw_g_io_out_bits_idx;
        checks++;
        if (atw_g_io_out_bits_way_en !== atw_i_io_out_bits_way_en) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d Arbiter1_TagWriteReq.io_out_bits_way_en g=%h i=%h", cyc, atw_g_io_out_bits_way_en, atw_i_io_out_bits_way_en);
        end
        atw_s1_io_out_bits_way_en |= atw_g_io_out_bits_way_en;
        atw_s0_io_out_bits_way_en |= ~atw_g_io_out_bits_way_en;
        checks++;
        if (atw_g_io_out_bits_tag !== atw_i_io_out_bits_tag) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d Arbiter1_TagWriteReq.io_out_bits_tag g=%h i=%h", cyc, atw_g_io_out_bits_tag, atw_i_io_out_bits_tag);
        end
        atw_s1_io_out_bits_tag |= atw_g_io_out_bits_tag;
        atw_s0_io_out_bits_tag |= ~atw_g_io_out_bits_tag;
      end
      if (atw_armed_at < 0 && (&atw_armed)) atw_armed_at = cyc + 1;
      adw_armed = 1'b1;
      if (cyc >= RESET_CYC + 0 && (&adw_armed)) begin
        checks++;
        if (adw_g_io_out_valid !== adw_i_io_out_valid) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d Arbiter1_L1BankedDataWriteReq.io_out_valid g=%h i=%h", cyc, adw_g_io_out_valid, adw_i_io_out_valid);
        end
        adw_s1_io_out_valid |= adw_g_io_out_valid;
        adw_s0_io_out_valid |= ~adw_g_io_out_valid;
        checks++;
        if (adw_g_io_out_bits_wmask !== adw_i_io_out_bits_wmask) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d Arbiter1_L1BankedDataWriteReq.io_out_bits_wmask g=%h i=%h", cyc, adw_g_io_out_bits_wmask, adw_i_io_out_bits_wmask);
        end
        adw_s1_io_out_bits_wmask |= adw_g_io_out_bits_wmask;
        adw_s0_io_out_bits_wmask |= ~adw_g_io_out_bits_wmask;
        checks++;
        if (adw_g_io_out_bits_data_0 !== adw_i_io_out_bits_data_0) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d Arbiter1_L1BankedDataWriteReq.io_out_bits_data_0 g=%h i=%h", cyc, adw_g_io_out_bits_data_0, adw_i_io_out_bits_data_0);
        end
        adw_s1_io_out_bits_data_0 |= adw_g_io_out_bits_data_0;
        adw_s0_io_out_bits_data_0 |= ~adw_g_io_out_bits_data_0;
        checks++;
        if (adw_g_io_out_bits_data_1 !== adw_i_io_out_bits_data_1) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d Arbiter1_L1BankedDataWriteReq.io_out_bits_data_1 g=%h i=%h", cyc, adw_g_io_out_bits_data_1, adw_i_io_out_bits_data_1);
        end
        adw_s1_io_out_bits_data_1 |= adw_g_io_out_bits_data_1;
        adw_s0_io_out_bits_data_1 |= ~adw_g_io_out_bits_data_1;
        checks++;
        if (adw_g_io_out_bits_data_2 !== adw_i_io_out_bits_data_2) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d Arbiter1_L1BankedDataWriteReq.io_out_bits_data_2 g=%h i=%h", cyc, adw_g_io_out_bits_data_2, adw_i_io_out_bits_data_2);
        end
        adw_s1_io_out_bits_data_2 |= adw_g_io_out_bits_data_2;
        adw_s0_io_out_bits_data_2 |= ~adw_g_io_out_bits_data_2;
        checks++;
        if (adw_g_io_out_bits_data_3 !== adw_i_io_out_bits_data_3) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d Arbiter1_L1BankedDataWriteReq.io_out_bits_data_3 g=%h i=%h", cyc, adw_g_io_out_bits_data_3, adw_i_io_out_bits_data_3);
        end
        adw_s1_io_out_bits_data_3 |= adw_g_io_out_bits_data_3;
        adw_s0_io_out_bits_data_3 |= ~adw_g_io_out_bits_data_3;
        checks++;
        if (adw_g_io_out_bits_data_4 !== adw_i_io_out_bits_data_4) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d Arbiter1_L1BankedDataWriteReq.io_out_bits_data_4 g=%h i=%h", cyc, adw_g_io_out_bits_data_4, adw_i_io_out_bits_data_4);
        end
        adw_s1_io_out_bits_data_4 |= adw_g_io_out_bits_data_4;
        adw_s0_io_out_bits_data_4 |= ~adw_g_io_out_bits_data_4;
        checks++;
        if (adw_g_io_out_bits_data_5 !== adw_i_io_out_bits_data_5) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d Arbiter1_L1BankedDataWriteReq.io_out_bits_data_5 g=%h i=%h", cyc, adw_g_io_out_bits_data_5, adw_i_io_out_bits_data_5);
        end
        adw_s1_io_out_bits_data_5 |= adw_g_io_out_bits_data_5;
        adw_s0_io_out_bits_data_5 |= ~adw_g_io_out_bits_data_5;
        checks++;
        if (adw_g_io_out_bits_data_6 !== adw_i_io_out_bits_data_6) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d Arbiter1_L1BankedDataWriteReq.io_out_bits_data_6 g=%h i=%h", cyc, adw_g_io_out_bits_data_6, adw_i_io_out_bits_data_6);
        end
        adw_s1_io_out_bits_data_6 |= adw_g_io_out_bits_data_6;
        adw_s0_io_out_bits_data_6 |= ~adw_g_io_out_bits_data_6;
        checks++;
        if (adw_g_io_out_bits_data_7 !== adw_i_io_out_bits_data_7) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d Arbiter1_L1BankedDataWriteReq.io_out_bits_data_7 g=%h i=%h", cyc, adw_g_io_out_bits_data_7, adw_i_io_out_bits_data_7);
        end
        adw_s1_io_out_bits_data_7 |= adw_g_io_out_bits_data_7;
        adw_s0_io_out_bits_data_7 |= ~adw_g_io_out_bits_data_7;
      end
      if (adw_armed_at < 0 && (&adw_armed)) adw_armed_at = cyc + 1;
      adc_armed = 1'b1;
      if (cyc >= RESET_CYC + 0 && (&adc_armed)) begin
        checks++;
        if (adc_g_io_out_valid !== adc_i_io_out_valid) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d Arbiter1_L1BankedDataWriteReqCtrl.io_out_valid g=%h i=%h", cyc, adc_g_io_out_valid, adc_i_io_out_valid);
        end
        adc_s1_io_out_valid |= adc_g_io_out_valid;
        adc_s0_io_out_valid |= ~adc_g_io_out_valid;
        checks++;
        if (adc_g_io_out_bits_way_en !== adc_i_io_out_bits_way_en) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d Arbiter1_L1BankedDataWriteReqCtrl.io_out_bits_way_en g=%h i=%h", cyc, adc_g_io_out_bits_way_en, adc_i_io_out_bits_way_en);
        end
        adc_s1_io_out_bits_way_en |= adc_g_io_out_bits_way_en;
        adc_s0_io_out_bits_way_en |= ~adc_g_io_out_bits_way_en;
        checks++;
        if (adc_g_io_out_bits_addr !== adc_i_io_out_bits_addr) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d Arbiter1_L1BankedDataWriteReqCtrl.io_out_bits_addr g=%h i=%h", cyc, adc_g_io_out_bits_addr, adc_i_io_out_bits_addr);
        end
        adc_s1_io_out_bits_addr |= adc_g_io_out_bits_addr;
        adc_s0_io_out_bits_addr |= ~adc_g_io_out_bits_addr;
      end
      if (adc_armed_at < 0 && (&adc_armed)) adc_armed_at = cyc + 1;
      tra_armed = 1'b1;
      if (cyc >= RESET_CYC + 0 && (&tra_armed)) begin
        checks++;
        if (tra_g_io_in_0_ready !== tra_i_io_in_0_ready) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d TreeArbiter.io_in_0_ready g=%h i=%h", cyc, tra_g_io_in_0_ready, tra_i_io_in_0_ready);
        end
        tra_s1_io_in_0_ready |= tra_g_io_in_0_ready;
        tra_s0_io_in_0_ready |= ~tra_g_io_in_0_ready;
        checks++;
        if (tra_g_io_in_1_ready !== tra_i_io_in_1_ready) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d TreeArbiter.io_in_1_ready g=%h i=%h", cyc, tra_g_io_in_1_ready, tra_i_io_in_1_ready);
        end
        tra_s1_io_in_1_ready |= tra_g_io_in_1_ready;
        tra_s0_io_in_1_ready |= ~tra_g_io_in_1_ready;
        checks++;
        if (tra_g_io_in_2_ready !== tra_i_io_in_2_ready) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d TreeArbiter.io_in_2_ready g=%h i=%h", cyc, tra_g_io_in_2_ready, tra_i_io_in_2_ready);
        end
        tra_s1_io_in_2_ready |= tra_g_io_in_2_ready;
        tra_s0_io_in_2_ready |= ~tra_g_io_in_2_ready;
        checks++;
        if (tra_g_io_in_3_ready !== tra_i_io_in_3_ready) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d TreeArbiter.io_in_3_ready g=%h i=%h", cyc, tra_g_io_in_3_ready, tra_i_io_in_3_ready);
        end
        tra_s1_io_in_3_ready |= tra_g_io_in_3_ready;
        tra_s0_io_in_3_ready |= ~tra_g_io_in_3_ready;
        checks++;
        if (tra_g_io_out_valid !== tra_i_io_out_valid) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d TreeArbiter.io_out_valid g=%h i=%h", cyc, tra_g_io_out_valid, tra_i_io_out_valid);
        end
        tra_s1_io_out_valid |= tra_g_io_out_valid;
        tra_s0_io_out_valid |= ~tra_g_io_out_valid;
        checks++;
        if (tra_g_io_out_bits_source !== tra_i_io_out_bits_source) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d TreeArbiter.io_out_bits_source g=%h i=%h", cyc, tra_g_io_out_bits_source, tra_i_io_out_bits_source);
        end
        tra_s1_io_out_bits_source |= tra_g_io_out_bits_source;
        tra_s0_io_out_bits_source |= ~tra_g_io_out_bits_source;
        checks++;
        if (tra_g_io_out_bits_pf_source !== tra_i_io_out_bits_pf_source) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d TreeArbiter.io_out_bits_pf_source g=%h i=%h", cyc, tra_g_io_out_bits_pf_source, tra_i_io_out_bits_pf_source);
        end
        tra_s1_io_out_bits_pf_source |= tra_g_io_out_bits_pf_source;
        tra_s0_io_out_bits_pf_source |= ~tra_g_io_out_bits_pf_source;
        checks++;
        if (tra_g_io_out_bits_cmd !== tra_i_io_out_bits_cmd) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d TreeArbiter.io_out_bits_cmd g=%h i=%h", cyc, tra_g_io_out_bits_cmd, tra_i_io_out_bits_cmd);
        end
        tra_s1_io_out_bits_cmd |= tra_g_io_out_bits_cmd;
        tra_s0_io_out_bits_cmd |= ~tra_g_io_out_bits_cmd;
        checks++;
        if (tra_g_io_out_bits_addr !== tra_i_io_out_bits_addr) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d TreeArbiter.io_out_bits_addr g=%h i=%h", cyc, tra_g_io_out_bits_addr, tra_i_io_out_bits_addr);
        end
        tra_s1_io_out_bits_addr |= tra_g_io_out_bits_addr;
        tra_s0_io_out_bits_addr |= ~tra_g_io_out_bits_addr;
        checks++;
        if (tra_g_io_out_bits_vaddr !== tra_i_io_out_bits_vaddr) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d TreeArbiter.io_out_bits_vaddr g=%h i=%h", cyc, tra_g_io_out_bits_vaddr, tra_i_io_out_bits_vaddr);
        end
        tra_s1_io_out_bits_vaddr |= tra_g_io_out_bits_vaddr;
        tra_s0_io_out_bits_vaddr |= ~tra_g_io_out_bits_vaddr;
        checks++;
        if (tra_g_io_out_bits_full_overwrite !== tra_i_io_out_bits_full_overwrite) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d TreeArbiter.io_out_bits_full_overwrite g=%h i=%h", cyc, tra_g_io_out_bits_full_overwrite, tra_i_io_out_bits_full_overwrite);
        end
        tra_s1_io_out_bits_full_overwrite |= tra_g_io_out_bits_full_overwrite;
        tra_s0_io_out_bits_full_overwrite |= ~tra_g_io_out_bits_full_overwrite;
        checks++;
        if (tra_g_io_out_bits_word_idx !== tra_i_io_out_bits_word_idx) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d TreeArbiter.io_out_bits_word_idx g=%h i=%h", cyc, tra_g_io_out_bits_word_idx, tra_i_io_out_bits_word_idx);
        end
        tra_s1_io_out_bits_word_idx |= tra_g_io_out_bits_word_idx;
        tra_s0_io_out_bits_word_idx |= ~tra_g_io_out_bits_word_idx;
        checks++;
        if (tra_g_io_out_bits_amo_data !== tra_i_io_out_bits_amo_data) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d TreeArbiter.io_out_bits_amo_data g=%h i=%h", cyc, tra_g_io_out_bits_amo_data, tra_i_io_out_bits_amo_data);
        end
        tra_s1_io_out_bits_amo_data |= tra_g_io_out_bits_amo_data;
        tra_s0_io_out_bits_amo_data |= ~tra_g_io_out_bits_amo_data;
        checks++;
        if (tra_g_io_out_bits_amo_mask !== tra_i_io_out_bits_amo_mask) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d TreeArbiter.io_out_bits_amo_mask g=%h i=%h", cyc, tra_g_io_out_bits_amo_mask, tra_i_io_out_bits_amo_mask);
        end
        tra_s1_io_out_bits_amo_mask |= tra_g_io_out_bits_amo_mask;
        tra_s0_io_out_bits_amo_mask |= ~tra_g_io_out_bits_amo_mask;
        checks++;
        if (tra_g_io_out_bits_amo_cmp !== tra_i_io_out_bits_amo_cmp) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d TreeArbiter.io_out_bits_amo_cmp g=%h i=%h", cyc, tra_g_io_out_bits_amo_cmp, tra_i_io_out_bits_amo_cmp);
        end
        tra_s1_io_out_bits_amo_cmp |= tra_g_io_out_bits_amo_cmp;
        tra_s0_io_out_bits_amo_cmp |= ~tra_g_io_out_bits_amo_cmp;
        checks++;
        if (tra_g_io_out_bits_req_coh_state !== tra_i_io_out_bits_req_coh_state) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d TreeArbiter.io_out_bits_req_coh_state g=%h i=%h", cyc, tra_g_io_out_bits_req_coh_state, tra_i_io_out_bits_req_coh_state);
        end
        tra_s1_io_out_bits_req_coh_state |= tra_g_io_out_bits_req_coh_state;
        tra_s0_io_out_bits_req_coh_state |= ~tra_g_io_out_bits_req_coh_state;
        checks++;
        if (tra_g_io_out_bits_id !== tra_i_io_out_bits_id) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d TreeArbiter.io_out_bits_id g=%h i=%h", cyc, tra_g_io_out_bits_id, tra_i_io_out_bits_id);
        end
        tra_s1_io_out_bits_id |= tra_g_io_out_bits_id;
        tra_s0_io_out_bits_id |= ~tra_g_io_out_bits_id;
        checks++;
        if (tra_g_io_out_bits_isBtoT !== tra_i_io_out_bits_isBtoT) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d TreeArbiter.io_out_bits_isBtoT g=%h i=%h", cyc, tra_g_io_out_bits_isBtoT, tra_i_io_out_bits_isBtoT);
        end
        tra_s1_io_out_bits_isBtoT |= tra_g_io_out_bits_isBtoT;
        tra_s0_io_out_bits_isBtoT |= ~tra_g_io_out_bits_isBtoT;
        checks++;
        if (tra_g_io_out_bits_occupy_way !== tra_i_io_out_bits_occupy_way) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d TreeArbiter.io_out_bits_occupy_way g=%h i=%h", cyc, tra_g_io_out_bits_occupy_way, tra_i_io_out_bits_occupy_way);
        end
        tra_s1_io_out_bits_occupy_way |= tra_g_io_out_bits_occupy_way;
        tra_s0_io_out_bits_occupy_way |= ~tra_g_io_out_bits_occupy_way;
        checks++;
        if (tra_g_io_out_bits_cancel !== tra_i_io_out_bits_cancel) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d TreeArbiter.io_out_bits_cancel g=%h i=%h", cyc, tra_g_io_out_bits_cancel, tra_i_io_out_bits_cancel);
        end
        tra_s1_io_out_bits_cancel |= tra_g_io_out_bits_cancel;
        tra_s0_io_out_bits_cancel |= ~tra_g_io_out_bits_cancel;
        checks++;
        if (tra_g_io_out_bits_store_data !== tra_i_io_out_bits_store_data) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d TreeArbiter.io_out_bits_store_data g=%h i=%h", cyc, tra_g_io_out_bits_store_data, tra_i_io_out_bits_store_data);
        end
        tra_s1_io_out_bits_store_data |= tra_g_io_out_bits_store_data;
        tra_s0_io_out_bits_store_data |= ~tra_g_io_out_bits_store_data;
        checks++;
        if (tra_g_io_out_bits_store_mask !== tra_i_io_out_bits_store_mask) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d TreeArbiter.io_out_bits_store_mask g=%h i=%h", cyc, tra_g_io_out_bits_store_mask, tra_i_io_out_bits_store_mask);
        end
        tra_s1_io_out_bits_store_mask |= tra_g_io_out_bits_store_mask;
        tra_s0_io_out_bits_store_mask |= ~tra_g_io_out_bits_store_mask;
        if (tra_io_in_0_valid) tra_cov_win0++;
        if (!tra_io_in_0_valid && tra_io_in_1_valid) tra_cov_win1++;
        if (!tra_io_in_0_valid && !tra_io_in_1_valid && tra_io_in_2_valid) tra_cov_win2++;
        if (!tra_io_in_0_valid && !tra_io_in_1_valid && !tra_io_in_2_valid && tra_io_in_3_valid) tra_cov_win3++;
        if (!tra_io_in_0_valid && !tra_io_in_1_valid && !tra_io_in_2_valid && !tra_io_in_3_valid) tra_cov_none++;
        if (tra_g_io_out_valid && !tra_io_out_ready) tra_cov_stall++;
      end
      if (tra_armed_at < 0 && (&tra_armed)) tra_armed_at = cyc + 1;
      mrg_armed = 1'b1;
      if (cyc >= RESET_CYC + 0 && (&mrg_armed)) begin
        checks++;
        if (mrg_g_io_in_0_ready !== mrg_i_io_in_0_ready) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d MissReadyGen.io_in_0_ready g=%h i=%h", cyc, mrg_g_io_in_0_ready, mrg_i_io_in_0_ready);
        end
        mrg_s1_io_in_0_ready |= mrg_g_io_in_0_ready;
        mrg_s0_io_in_0_ready |= ~mrg_g_io_in_0_ready;
        checks++;
        if (mrg_g_io_in_1_ready !== mrg_i_io_in_1_ready) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d MissReadyGen.io_in_1_ready g=%h i=%h", cyc, mrg_g_io_in_1_ready, mrg_i_io_in_1_ready);
        end
        mrg_s1_io_in_1_ready |= mrg_g_io_in_1_ready;
        mrg_s0_io_in_1_ready |= ~mrg_g_io_in_1_ready;
        checks++;
        if (mrg_g_io_in_2_ready !== mrg_i_io_in_2_ready) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d MissReadyGen.io_in_2_ready g=%h i=%h", cyc, mrg_g_io_in_2_ready, mrg_i_io_in_2_ready);
        end
        mrg_s1_io_in_2_ready |= mrg_g_io_in_2_ready;
        mrg_s0_io_in_2_ready |= ~mrg_g_io_in_2_ready;
        checks++;
        if (mrg_g_io_in_3_ready !== mrg_i_io_in_3_ready) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d MissReadyGen.io_in_3_ready g=%h i=%h", cyc, mrg_g_io_in_3_ready, mrg_i_io_in_3_ready);
        end
        mrg_s1_io_in_3_ready |= mrg_g_io_in_3_ready;
        mrg_s0_io_in_3_ready |= ~mrg_g_io_in_3_ready;
        checks++;
        if (mrg_g_io_queryMQ_0_req_bits_source !== mrg_i_io_queryMQ_0_req_bits_source) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d MissReadyGen.io_queryMQ_0_req_bits_source g=%h i=%h", cyc, mrg_g_io_queryMQ_0_req_bits_source, mrg_i_io_queryMQ_0_req_bits_source);
        end
        mrg_s1_io_queryMQ_0_req_bits_source |= mrg_g_io_queryMQ_0_req_bits_source;
        mrg_s0_io_queryMQ_0_req_bits_source |= ~mrg_g_io_queryMQ_0_req_bits_source;
        checks++;
        if (mrg_g_io_queryMQ_0_req_bits_addr !== mrg_i_io_queryMQ_0_req_bits_addr) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d MissReadyGen.io_queryMQ_0_req_bits_addr g=%h i=%h", cyc, mrg_g_io_queryMQ_0_req_bits_addr, mrg_i_io_queryMQ_0_req_bits_addr);
        end
        mrg_s1_io_queryMQ_0_req_bits_addr |= mrg_g_io_queryMQ_0_req_bits_addr;
        mrg_s0_io_queryMQ_0_req_bits_addr |= ~mrg_g_io_queryMQ_0_req_bits_addr;
        checks++;
        if (mrg_g_io_queryMQ_0_req_bits_vaddr !== mrg_i_io_queryMQ_0_req_bits_vaddr) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d MissReadyGen.io_queryMQ_0_req_bits_vaddr g=%h i=%h", cyc, mrg_g_io_queryMQ_0_req_bits_vaddr, mrg_i_io_queryMQ_0_req_bits_vaddr);
        end
        mrg_s1_io_queryMQ_0_req_bits_vaddr |= mrg_g_io_queryMQ_0_req_bits_vaddr;
        mrg_s0_io_queryMQ_0_req_bits_vaddr |= ~mrg_g_io_queryMQ_0_req_bits_vaddr;
        checks++;
        if (mrg_g_io_queryMQ_1_req_bits_source !== mrg_i_io_queryMQ_1_req_bits_source) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d MissReadyGen.io_queryMQ_1_req_bits_source g=%h i=%h", cyc, mrg_g_io_queryMQ_1_req_bits_source, mrg_i_io_queryMQ_1_req_bits_source);
        end
        mrg_s1_io_queryMQ_1_req_bits_source |= mrg_g_io_queryMQ_1_req_bits_source;
        mrg_s0_io_queryMQ_1_req_bits_source |= ~mrg_g_io_queryMQ_1_req_bits_source;
        checks++;
        if (mrg_g_io_queryMQ_1_req_bits_addr !== mrg_i_io_queryMQ_1_req_bits_addr) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d MissReadyGen.io_queryMQ_1_req_bits_addr g=%h i=%h", cyc, mrg_g_io_queryMQ_1_req_bits_addr, mrg_i_io_queryMQ_1_req_bits_addr);
        end
        mrg_s1_io_queryMQ_1_req_bits_addr |= mrg_g_io_queryMQ_1_req_bits_addr;
        mrg_s0_io_queryMQ_1_req_bits_addr |= ~mrg_g_io_queryMQ_1_req_bits_addr;
        checks++;
        if (mrg_g_io_queryMQ_1_req_bits_vaddr !== mrg_i_io_queryMQ_1_req_bits_vaddr) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d MissReadyGen.io_queryMQ_1_req_bits_vaddr g=%h i=%h", cyc, mrg_g_io_queryMQ_1_req_bits_vaddr, mrg_i_io_queryMQ_1_req_bits_vaddr);
        end
        mrg_s1_io_queryMQ_1_req_bits_vaddr |= mrg_g_io_queryMQ_1_req_bits_vaddr;
        mrg_s0_io_queryMQ_1_req_bits_vaddr |= ~mrg_g_io_queryMQ_1_req_bits_vaddr;
        checks++;
        if (mrg_g_io_queryMQ_2_req_bits_source !== mrg_i_io_queryMQ_2_req_bits_source) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d MissReadyGen.io_queryMQ_2_req_bits_source g=%h i=%h", cyc, mrg_g_io_queryMQ_2_req_bits_source, mrg_i_io_queryMQ_2_req_bits_source);
        end
        mrg_s1_io_queryMQ_2_req_bits_source |= mrg_g_io_queryMQ_2_req_bits_source;
        mrg_s0_io_queryMQ_2_req_bits_source |= ~mrg_g_io_queryMQ_2_req_bits_source;
        checks++;
        if (mrg_g_io_queryMQ_2_req_bits_addr !== mrg_i_io_queryMQ_2_req_bits_addr) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d MissReadyGen.io_queryMQ_2_req_bits_addr g=%h i=%h", cyc, mrg_g_io_queryMQ_2_req_bits_addr, mrg_i_io_queryMQ_2_req_bits_addr);
        end
        mrg_s1_io_queryMQ_2_req_bits_addr |= mrg_g_io_queryMQ_2_req_bits_addr;
        mrg_s0_io_queryMQ_2_req_bits_addr |= ~mrg_g_io_queryMQ_2_req_bits_addr;
        checks++;
        if (mrg_g_io_queryMQ_2_req_bits_vaddr !== mrg_i_io_queryMQ_2_req_bits_vaddr) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d MissReadyGen.io_queryMQ_2_req_bits_vaddr g=%h i=%h", cyc, mrg_g_io_queryMQ_2_req_bits_vaddr, mrg_i_io_queryMQ_2_req_bits_vaddr);
        end
        mrg_s1_io_queryMQ_2_req_bits_vaddr |= mrg_g_io_queryMQ_2_req_bits_vaddr;
        mrg_s0_io_queryMQ_2_req_bits_vaddr |= ~mrg_g_io_queryMQ_2_req_bits_vaddr;
        checks++;
        if (mrg_g_io_queryMQ_3_req_bits_source !== mrg_i_io_queryMQ_3_req_bits_source) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d MissReadyGen.io_queryMQ_3_req_bits_source g=%h i=%h", cyc, mrg_g_io_queryMQ_3_req_bits_source, mrg_i_io_queryMQ_3_req_bits_source);
        end
        mrg_s1_io_queryMQ_3_req_bits_source |= mrg_g_io_queryMQ_3_req_bits_source;
        mrg_s0_io_queryMQ_3_req_bits_source |= ~mrg_g_io_queryMQ_3_req_bits_source;
        checks++;
        if (mrg_g_io_queryMQ_3_req_bits_addr !== mrg_i_io_queryMQ_3_req_bits_addr) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d MissReadyGen.io_queryMQ_3_req_bits_addr g=%h i=%h", cyc, mrg_g_io_queryMQ_3_req_bits_addr, mrg_i_io_queryMQ_3_req_bits_addr);
        end
        mrg_s1_io_queryMQ_3_req_bits_addr |= mrg_g_io_queryMQ_3_req_bits_addr;
        mrg_s0_io_queryMQ_3_req_bits_addr |= ~mrg_g_io_queryMQ_3_req_bits_addr;
        checks++;
        if (mrg_g_io_queryMQ_3_req_bits_vaddr !== mrg_i_io_queryMQ_3_req_bits_vaddr) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d MissReadyGen.io_queryMQ_3_req_bits_vaddr g=%h i=%h", cyc, mrg_g_io_queryMQ_3_req_bits_vaddr, mrg_i_io_queryMQ_3_req_bits_vaddr);
        end
        mrg_s1_io_queryMQ_3_req_bits_vaddr |= mrg_g_io_queryMQ_3_req_bits_vaddr;
        mrg_s0_io_queryMQ_3_req_bits_vaddr |= ~mrg_g_io_queryMQ_3_req_bits_vaddr;
        if (mrg_g_io_in_0_ready) mrg_cov_rdy0++;
        if (mrg_g_io_in_1_ready) mrg_cov_rdy1++;
        if (mrg_g_io_in_2_ready) mrg_cov_rdy2++;
        if (mrg_g_io_in_3_ready) mrg_cov_rdy3++;
        if (mrg_io_queryMQ_1_ready && mrg_io_in_0_valid) mrg_cov_block1++;
        if (mrg_io_queryMQ_2_ready && !mrg_io_in_0_valid && mrg_io_in_1_valid) mrg_cov_block2++;
        if (mrg_io_queryMQ_3_ready && !mrg_io_in_0_valid && !mrg_io_in_1_valid && mrg_io_in_2_valid) mrg_cov_block3++;
      end
      if (mrg_armed_at < 0 && (&mrg_armed)) mrg_armed_at = cyc + 1;
      pfm_armed = 1'b1;
      if (cyc >= RESET_CYC + 0 && (&pfm_armed)) begin
        checks++;
        if (pfm_g_io_pf_ctrl_enable !== pfm_i_io_pf_ctrl_enable) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d PrefetcherMonitor.io_pf_ctrl_enable g=%h i=%h", cyc, pfm_g_io_pf_ctrl_enable, pfm_i_io_pf_ctrl_enable);
        end
        pfm_s1_io_pf_ctrl_enable |= pfm_g_io_pf_ctrl_enable;
        pfm_s0_io_pf_ctrl_enable |= ~pfm_g_io_pf_ctrl_enable;
        checks++;
        if (pfm_g_io_pf_ctrl_confidence !== pfm_i_io_pf_ctrl_confidence) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d PrefetcherMonitor.io_pf_ctrl_confidence g=%h i=%h", cyc, pfm_g_io_pf_ctrl_confidence, pfm_i_io_pf_ctrl_confidence);
        end
        pfm_s1_io_pf_ctrl_confidence |= pfm_g_io_pf_ctrl_confidence;
        pfm_s0_io_pf_ctrl_confidence |= ~pfm_g_io_pf_ctrl_confidence;
        if (pfm_u_gold.timely_reset) pfm_cov_timely_reset++;
        if (pfm_u_gold.validity_reset) pfm_cov_validity_reset++;
        if (pfm_u_gold.trigger_disable_probe) pfm_cov_trigger_disable++;
        if (pfm_u_gold.timely_reset && pfm_u_gold.late_hit_prefetch_cnt > 11'h383 && !(pfm_u_gold.late_miss_prefetch_cnt > 11'hC7)) pfm_cov_trigger_late_hit_only++;
        if (pfm_u_gold.timely_reset && pfm_u_gold.late_hit_prefetch_cnt > 11'h383 && pfm_u_gold.late_miss_prefetch_cnt > 11'hC7) pfm_cov_late_miss_masks_late_hit++;
        if (pfm_u_gold.back_off_reset) pfm_cov_back_off_reset++;
        if (!pfm_g_io_pf_ctrl_enable) pfm_cov_enable_off++;
      end
      if (pfm_armed_at < 0 && (&pfm_armed)) pfm_armed_at = cyc + 1;
      fdp_armed = 1'b1;
      if (cyc >= RESET_CYC + 0 && (&fdp_armed)) begin
      end
      if (fdp_armed_at < 0 && (&fdp_armed)) fdp_armed_at = cyc + 1;
    end

    // ---- 覆盖闸 ----
    if (!(atw_s0_io_out_valid && atw_s1_io_out_valid)) begin cov_fail++; $display("[COV] Arbiter1_TagWriteReq.io_out_valid 未见过 0 和 1"); end
    if (!(atw_s0_io_out_bits_idx[0] && atw_s1_io_out_bits_idx[0])) begin cov_fail++; $display("[COV] Arbiter1_TagWriteReq.io_out_bits_idx[0] 未见过 0 和 1"); end
    if (!(atw_s0_io_out_bits_idx[1] && atw_s1_io_out_bits_idx[1])) begin cov_fail++; $display("[COV] Arbiter1_TagWriteReq.io_out_bits_idx[1] 未见过 0 和 1"); end
    if (!(atw_s0_io_out_bits_idx[2] && atw_s1_io_out_bits_idx[2])) begin cov_fail++; $display("[COV] Arbiter1_TagWriteReq.io_out_bits_idx[2] 未见过 0 和 1"); end
    if (!(atw_s0_io_out_bits_idx[3] && atw_s1_io_out_bits_idx[3])) begin cov_fail++; $display("[COV] Arbiter1_TagWriteReq.io_out_bits_idx[3] 未见过 0 和 1"); end
    if (!(atw_s0_io_out_bits_idx[4] && atw_s1_io_out_bits_idx[4])) begin cov_fail++; $display("[COV] Arbiter1_TagWriteReq.io_out_bits_idx[4] 未见过 0 和 1"); end
    if (!(atw_s0_io_out_bits_idx[5] && atw_s1_io_out_bits_idx[5])) begin cov_fail++; $display("[COV] Arbiter1_TagWriteReq.io_out_bits_idx[5] 未见过 0 和 1"); end
    if (!(atw_s0_io_out_bits_idx[6] && atw_s1_io_out_bits_idx[6])) begin cov_fail++; $display("[COV] Arbiter1_TagWriteReq.io_out_bits_idx[6] 未见过 0 和 1"); end
    if (!(atw_s0_io_out_bits_idx[7] && atw_s1_io_out_bits_idx[7])) begin cov_fail++; $display("[COV] Arbiter1_TagWriteReq.io_out_bits_idx[7] 未见过 0 和 1"); end
    if (!(atw_s0_io_out_bits_way_en[0] && atw_s1_io_out_bits_way_en[0])) begin cov_fail++; $display("[COV] Arbiter1_TagWriteReq.io_out_bits_way_en[0] 未见过 0 和 1"); end
    if (!(atw_s0_io_out_bits_way_en[1] && atw_s1_io_out_bits_way_en[1])) begin cov_fail++; $display("[COV] Arbiter1_TagWriteReq.io_out_bits_way_en[1] 未见过 0 和 1"); end
    if (!(atw_s0_io_out_bits_way_en[2] && atw_s1_io_out_bits_way_en[2])) begin cov_fail++; $display("[COV] Arbiter1_TagWriteReq.io_out_bits_way_en[2] 未见过 0 和 1"); end
    if (!(atw_s0_io_out_bits_way_en[3] && atw_s1_io_out_bits_way_en[3])) begin cov_fail++; $display("[COV] Arbiter1_TagWriteReq.io_out_bits_way_en[3] 未见过 0 和 1"); end
    if (!(atw_s0_io_out_bits_tag[0] && atw_s1_io_out_bits_tag[0])) begin cov_fail++; $display("[COV] Arbiter1_TagWriteReq.io_out_bits_tag[0] 未见过 0 和 1"); end
    if (!(atw_s0_io_out_bits_tag[1] && atw_s1_io_out_bits_tag[1])) begin cov_fail++; $display("[COV] Arbiter1_TagWriteReq.io_out_bits_tag[1] 未见过 0 和 1"); end
    if (!(atw_s0_io_out_bits_tag[2] && atw_s1_io_out_bits_tag[2])) begin cov_fail++; $display("[COV] Arbiter1_TagWriteReq.io_out_bits_tag[2] 未见过 0 和 1"); end
    if (!(atw_s0_io_out_bits_tag[3] && atw_s1_io_out_bits_tag[3])) begin cov_fail++; $display("[COV] Arbiter1_TagWriteReq.io_out_bits_tag[3] 未见过 0 和 1"); end
    if (!(atw_s0_io_out_bits_tag[4] && atw_s1_io_out_bits_tag[4])) begin cov_fail++; $display("[COV] Arbiter1_TagWriteReq.io_out_bits_tag[4] 未见过 0 和 1"); end
    if (!(atw_s0_io_out_bits_tag[5] && atw_s1_io_out_bits_tag[5])) begin cov_fail++; $display("[COV] Arbiter1_TagWriteReq.io_out_bits_tag[5] 未见过 0 和 1"); end
    if (!(atw_s0_io_out_bits_tag[6] && atw_s1_io_out_bits_tag[6])) begin cov_fail++; $display("[COV] Arbiter1_TagWriteReq.io_out_bits_tag[6] 未见过 0 和 1"); end
    if (!(atw_s0_io_out_bits_tag[7] && atw_s1_io_out_bits_tag[7])) begin cov_fail++; $display("[COV] Arbiter1_TagWriteReq.io_out_bits_tag[7] 未见过 0 和 1"); end
    if (!(atw_s0_io_out_bits_tag[8] && atw_s1_io_out_bits_tag[8])) begin cov_fail++; $display("[COV] Arbiter1_TagWriteReq.io_out_bits_tag[8] 未见过 0 和 1"); end
    if (!(atw_s0_io_out_bits_tag[9] && atw_s1_io_out_bits_tag[9])) begin cov_fail++; $display("[COV] Arbiter1_TagWriteReq.io_out_bits_tag[9] 未见过 0 和 1"); end
    if (!(atw_s0_io_out_bits_tag[10] && atw_s1_io_out_bits_tag[10])) begin cov_fail++; $display("[COV] Arbiter1_TagWriteReq.io_out_bits_tag[10] 未见过 0 和 1"); end
    if (!(atw_s0_io_out_bits_tag[11] && atw_s1_io_out_bits_tag[11])) begin cov_fail++; $display("[COV] Arbiter1_TagWriteReq.io_out_bits_tag[11] 未见过 0 和 1"); end
    if (!(atw_s0_io_out_bits_tag[12] && atw_s1_io_out_bits_tag[12])) begin cov_fail++; $display("[COV] Arbiter1_TagWriteReq.io_out_bits_tag[12] 未见过 0 和 1"); end
    if (!(atw_s0_io_out_bits_tag[13] && atw_s1_io_out_bits_tag[13])) begin cov_fail++; $display("[COV] Arbiter1_TagWriteReq.io_out_bits_tag[13] 未见过 0 和 1"); end
    if (!(atw_s0_io_out_bits_tag[14] && atw_s1_io_out_bits_tag[14])) begin cov_fail++; $display("[COV] Arbiter1_TagWriteReq.io_out_bits_tag[14] 未见过 0 和 1"); end
    if (!(atw_s0_io_out_bits_tag[15] && atw_s1_io_out_bits_tag[15])) begin cov_fail++; $display("[COV] Arbiter1_TagWriteReq.io_out_bits_tag[15] 未见过 0 和 1"); end
    if (!(atw_s0_io_out_bits_tag[16] && atw_s1_io_out_bits_tag[16])) begin cov_fail++; $display("[COV] Arbiter1_TagWriteReq.io_out_bits_tag[16] 未见过 0 和 1"); end
    if (!(atw_s0_io_out_bits_tag[17] && atw_s1_io_out_bits_tag[17])) begin cov_fail++; $display("[COV] Arbiter1_TagWriteReq.io_out_bits_tag[17] 未见过 0 和 1"); end
    if (!(atw_s0_io_out_bits_tag[18] && atw_s1_io_out_bits_tag[18])) begin cov_fail++; $display("[COV] Arbiter1_TagWriteReq.io_out_bits_tag[18] 未见过 0 和 1"); end
    if (!(atw_s0_io_out_bits_tag[19] && atw_s1_io_out_bits_tag[19])) begin cov_fail++; $display("[COV] Arbiter1_TagWriteReq.io_out_bits_tag[19] 未见过 0 和 1"); end
    if (!(atw_s0_io_out_bits_tag[20] && atw_s1_io_out_bits_tag[20])) begin cov_fail++; $display("[COV] Arbiter1_TagWriteReq.io_out_bits_tag[20] 未见过 0 和 1"); end
    if (!(atw_s0_io_out_bits_tag[21] && atw_s1_io_out_bits_tag[21])) begin cov_fail++; $display("[COV] Arbiter1_TagWriteReq.io_out_bits_tag[21] 未见过 0 和 1"); end
    if (!(atw_s0_io_out_bits_tag[22] && atw_s1_io_out_bits_tag[22])) begin cov_fail++; $display("[COV] Arbiter1_TagWriteReq.io_out_bits_tag[22] 未见过 0 和 1"); end
    if (!(atw_s0_io_out_bits_tag[23] && atw_s1_io_out_bits_tag[23])) begin cov_fail++; $display("[COV] Arbiter1_TagWriteReq.io_out_bits_tag[23] 未见过 0 和 1"); end
    if (!(atw_s0_io_out_bits_tag[24] && atw_s1_io_out_bits_tag[24])) begin cov_fail++; $display("[COV] Arbiter1_TagWriteReq.io_out_bits_tag[24] 未见过 0 和 1"); end
    if (!(atw_s0_io_out_bits_tag[25] && atw_s1_io_out_bits_tag[25])) begin cov_fail++; $display("[COV] Arbiter1_TagWriteReq.io_out_bits_tag[25] 未见过 0 和 1"); end
    if (!(atw_s0_io_out_bits_tag[26] && atw_s1_io_out_bits_tag[26])) begin cov_fail++; $display("[COV] Arbiter1_TagWriteReq.io_out_bits_tag[26] 未见过 0 和 1"); end
    if (!(atw_s0_io_out_bits_tag[27] && atw_s1_io_out_bits_tag[27])) begin cov_fail++; $display("[COV] Arbiter1_TagWriteReq.io_out_bits_tag[27] 未见过 0 和 1"); end
    if (!(atw_s0_io_out_bits_tag[28] && atw_s1_io_out_bits_tag[28])) begin cov_fail++; $display("[COV] Arbiter1_TagWriteReq.io_out_bits_tag[28] 未见过 0 和 1"); end
    if (!(atw_s0_io_out_bits_tag[29] && atw_s1_io_out_bits_tag[29])) begin cov_fail++; $display("[COV] Arbiter1_TagWriteReq.io_out_bits_tag[29] 未见过 0 和 1"); end
    if (!(atw_s0_io_out_bits_tag[30] && atw_s1_io_out_bits_tag[30])) begin cov_fail++; $display("[COV] Arbiter1_TagWriteReq.io_out_bits_tag[30] 未见过 0 和 1"); end
    if (!(atw_s0_io_out_bits_tag[31] && atw_s1_io_out_bits_tag[31])) begin cov_fail++; $display("[COV] Arbiter1_TagWriteReq.io_out_bits_tag[31] 未见过 0 和 1"); end
    if (!(atw_s0_io_out_bits_tag[32] && atw_s1_io_out_bits_tag[32])) begin cov_fail++; $display("[COV] Arbiter1_TagWriteReq.io_out_bits_tag[32] 未见过 0 和 1"); end
    if (!(atw_s0_io_out_bits_tag[33] && atw_s1_io_out_bits_tag[33])) begin cov_fail++; $display("[COV] Arbiter1_TagWriteReq.io_out_bits_tag[33] 未见过 0 和 1"); end
    if (!(atw_s0_io_out_bits_tag[34] && atw_s1_io_out_bits_tag[34])) begin cov_fail++; $display("[COV] Arbiter1_TagWriteReq.io_out_bits_tag[34] 未见过 0 和 1"); end
    if (!(atw_s0_io_out_bits_tag[35] && atw_s1_io_out_bits_tag[35])) begin cov_fail++; $display("[COV] Arbiter1_TagWriteReq.io_out_bits_tag[35] 未见过 0 和 1"); end
    $display("[ARM] Arbiter1_TagWriteReq armed_at=%0d", atw_armed_at);
    if (atw_armed_at < 0) begin cov_fail++; $display("[ARM] Arbiter1_TagWriteReq 从未 arm"); end
    if (!(adw_s0_io_out_valid && adw_s1_io_out_valid)) begin cov_fail++; $display("[COV] Arbiter1_L1BankedDataWriteReq.io_out_valid 未见过 0 和 1"); end
    if (!(adw_s0_io_out_bits_wmask[0] && adw_s1_io_out_bits_wmask[0])) begin cov_fail++; $display("[COV] Arbiter1_L1BankedDataWriteReq.io_out_bits_wmask[0] 未见过 0 和 1"); end
    if (!(adw_s0_io_out_bits_wmask[1] && adw_s1_io_out_bits_wmask[1])) begin cov_fail++; $display("[COV] Arbiter1_L1BankedDataWriteReq.io_out_bits_wmask[1] 未见过 0 和 1"); end
    if (!(adw_s0_io_out_bits_wmask[2] && adw_s1_io_out_bits_wmask[2])) begin cov_fail++; $display("[COV] Arbiter1_L1BankedDataWriteReq.io_out_bits_wmask[2] 未见过 0 和 1"); end
    if (!(adw_s0_io_out_bits_wmask[3] && adw_s1_io_out_bits_wmask[3])) begin cov_fail++; $display("[COV] Arbiter1_L1BankedDataWriteReq.io_out_bits_wmask[3] 未见过 0 和 1"); end
    if (!(adw_s0_io_out_bits_wmask[4] && adw_s1_io_out_bits_wmask[4])) begin cov_fail++; $display("[COV] Arbiter1_L1BankedDataWriteReq.io_out_bits_wmask[4] 未见过 0 和 1"); end
    if (!(adw_s0_io_out_bits_wmask[5] && adw_s1_io_out_bits_wmask[5])) begin cov_fail++; $display("[COV] Arbiter1_L1BankedDataWriteReq.io_out_bits_wmask[5] 未见过 0 和 1"); end
    if (!(adw_s0_io_out_bits_wmask[6] && adw_s1_io_out_bits_wmask[6])) begin cov_fail++; $display("[COV] Arbiter1_L1BankedDataWriteReq.io_out_bits_wmask[6] 未见过 0 和 1"); end
    if (!(adw_s0_io_out_bits_wmask[7] && adw_s1_io_out_bits_wmask[7])) begin cov_fail++; $display("[COV] Arbiter1_L1BankedDataWriteReq.io_out_bits_wmask[7] 未见过 0 和 1"); end
    if (!(adw_s0_io_out_bits_data_0[0] && adw_s1_io_out_bits_data_0[0])) begin cov_fail++; $display("[COV] Arbiter1_L1BankedDataWriteReq.io_out_bits_data_0[0] 未见过 0 和 1"); end
    if (!(adw_s0_io_out_bits_data_0[1] && adw_s1_io_out_bits_data_0[1])) begin cov_fail++; $display("[COV] Arbiter1_L1BankedDataWriteReq.io_out_bits_data_0[1] 未见过 0 和 1"); end
    if (!(adw_s0_io_out_bits_data_0[2] && adw_s1_io_out_bits_data_0[2])) begin cov_fail++; $display("[COV] Arbiter1_L1BankedDataWriteReq.io_out_bits_data_0[2] 未见过 0 和 1"); end
    if (!(adw_s0_io_out_bits_data_0[3] && adw_s1_io_out_bits_data_0[3])) begin cov_fail++; $display("[COV] Arbiter1_L1BankedDataWriteReq.io_out_bits_data_0[3] 未见过 0 和 1"); end
    if (!(adw_s0_io_out_bits_data_0[4] && adw_s1_io_out_bits_data_0[4])) begin cov_fail++; $display("[COV] Arbiter1_L1BankedDataWriteReq.io_out_bits_data_0[4] 未见过 0 和 1"); end
    if (!(adw_s0_io_out_bits_data_0[5] && adw_s1_io_out_bits_data_0[5])) begin cov_fail++; $display("[COV] Arbiter1_L1BankedDataWriteReq.io_out_bits_data_0[5] 未见过 0 和 1"); end
    if (!(adw_s0_io_out_bits_data_0[6] && adw_s1_io_out_bits_data_0[6])) begin cov_fail++; $display("[COV] Arbiter1_L1BankedDataWriteReq.io_out_bits_data_0[6] 未见过 0 和 1"); end
    if (!(adw_s0_io_out_bits_data_0[7] && adw_s1_io_out_bits_data_0[7])) begin cov_fail++; $display("[COV] Arbiter1_L1BankedDataWriteReq.io_out_bits_data_0[7] 未见过 0 和 1"); end
    if (!(adw_s0_io_out_bits_data_0[8] && adw_s1_io_out_bits_data_0[8])) begin cov_fail++; $display("[COV] Arbiter1_L1BankedDataWriteReq.io_out_bits_data_0[8] 未见过 0 和 1"); end
    if (!(adw_s0_io_out_bits_data_0[9] && adw_s1_io_out_bits_data_0[9])) begin cov_fail++; $display("[COV] Arbiter1_L1BankedDataWriteReq.io_out_bits_data_0[9] 未见过 0 和 1"); end
    if (!(adw_s0_io_out_bits_data_0[10] && adw_s1_io_out_bits_data_0[10])) begin cov_fail++; $display("[COV] Arbiter1_L1BankedDataWriteReq.io_out_bits_data_0[10] 未见过 0 和 1"); end
    if (!(adw_s0_io_out_bits_data_0[11] && adw_s1_io_out_bits_data_0[11])) begin cov_fail++; $display("[COV] Arbiter1_L1BankedDataWriteReq.io_out_bits_data_0[11] 未见过 0 和 1"); end
    if (!(adw_s0_io_out_bits_data_0[12] && adw_s1_io_out_bits_data_0[12])) begin cov_fail++; $display("[COV] Arbiter1_L1BankedDataWriteReq.io_out_bits_data_0[12] 未见过 0 和 1"); end
    if (!(adw_s0_io_out_bits_data_0[13] && adw_s1_io_out_bits_data_0[13])) begin cov_fail++; $display("[COV] Arbiter1_L1BankedDataWriteReq.io_out_bits_data_0[13] 未见过 0 和 1"); end
    if (!(adw_s0_io_out_bits_data_0[14] && adw_s1_io_out_bits_data_0[14])) begin cov_fail++; $display("[COV] Arbiter1_L1BankedDataWriteReq.io_out_bits_data_0[14] 未见过 0 和 1"); end
    if (!(adw_s0_io_out_bits_data_0[15] && adw_s1_io_out_bits_data_0[15])) begin cov_fail++; $display("[COV] Arbiter1_L1BankedDataWriteReq.io_out_bits_data_0[15] 未见过 0 和 1"); end
    if (!(adw_s0_io_out_bits_data_0[16] && adw_s1_io_out_bits_data_0[16])) begin cov_fail++; $display("[COV] Arbiter1_L1BankedDataWriteReq.io_out_bits_data_0[16] 未见过 0 和 1"); end
    if (!(adw_s0_io_out_bits_data_0[17] && adw_s1_io_out_bits_data_0[17])) begin cov_fail++; $display("[COV] Arbiter1_L1BankedDataWriteReq.io_out_bits_data_0[17] 未见过 0 和 1"); end
    if (!(adw_s0_io_out_bits_data_0[18] && adw_s1_io_out_bits_data_0[18])) begin cov_fail++; $display("[COV] Arbiter1_L1BankedDataWriteReq.io_out_bits_data_0[18] 未见过 0 和 1"); end
    if (!(adw_s0_io_out_bits_data_0[19] && adw_s1_io_out_bits_data_0[19])) begin cov_fail++; $display("[COV] Arbiter1_L1BankedDataWriteReq.io_out_bits_data_0[19] 未见过 0 和 1"); end
    if (!(adw_s0_io_out_bits_data_0[20] && adw_s1_io_out_bits_data_0[20])) begin cov_fail++; $display("[COV] Arbiter1_L1BankedDataWriteReq.io_out_bits_data_0[20] 未见过 0 和 1"); end
    if (!(adw_s0_io_out_bits_data_0[21] && adw_s1_io_out_bits_data_0[21])) begin cov_fail++; $display("[COV] Arbiter1_L1BankedDataWriteReq.io_out_bits_data_0[21] 未见过 0 和 1"); end
    if (!(adw_s0_io_out_bits_data_0[22] && adw_s1_io_out_bits_data_0[22])) begin cov_fail++; $display("[COV] Arbiter1_L1BankedDataWriteReq.io_out_bits_data_0[22] 未见过 0 和 1"); end
    if (!(adw_s0_io_out_bits_data_0[23] && adw_s1_io_out_bits_data_0[23])) begin cov_fail++; $display("[COV] Arbiter1_L1BankedDataWriteReq.io_out_bits_data_0[23] 未见过 0 和 1"); end
    if (!(adw_s0_io_out_bits_data_0[24] && adw_s1_io_out_bits_data_0[24])) begin cov_fail++; $display("[COV] Arbiter1_L1BankedDataWriteReq.io_out_bits_data_0[24] 未见过 0 和 1"); end
    if (!(adw_s0_io_out_bits_data_0[25] && adw_s1_io_out_bits_data_0[25])) begin cov_fail++; $display("[COV] Arbiter1_L1BankedDataWriteReq.io_out_bits_data_0[25] 未见过 0 和 1"); end
    if (!(adw_s0_io_out_bits_data_0[26] && adw_s1_io_out_bits_data_0[26])) begin cov_fail++; $display("[COV] Arbiter1_L1BankedDataWriteReq.io_out_bits_data_0[26] 未见过 0 和 1"); end
    if (!(adw_s0_io_out_bits_data_0[27] && adw_s1_io_out_bits_data_0[27])) begin cov_fail++; $display("[COV] Arbiter1_L1BankedDataWriteReq.io_out_bits_data_0[27] 未见过 0 和 1"); end
    if (!(adw_s0_io_out_bits_data_0[28] && adw_s1_io_out_bits_data_0[28])) begin cov_fail++; $display("[COV] Arbiter1_L1BankedDataWriteReq.io_out_bits_data_0[28] 未见过 0 和 1"); end
    if (!(adw_s0_io_out_bits_data_0[29] && adw_s1_io_out_bits_data_0[29])) begin cov_fail++; $display("[COV] Arbiter1_L1BankedDataWriteReq.io_out_bits_data_0[29] 未见过 0 和 1"); end
    if (!(adw_s0_io_out_bits_data_0[30] && adw_s1_io_out_bits_data_0[30])) begin cov_fail++; $display("[COV] Arbiter1_L1BankedDataWriteReq.io_out_bits_data_0[30] 未见过 0 和 1"); end
    if (!(adw_s0_io_out_bits_data_0[31] && adw_s1_io_out_bits_data_0[31])) begin cov_fail++; $display("[COV] Arbiter1_L1BankedDataWriteReq.io_out_bits_data_0[31] 未见过 0 和 1"); end
    if (!(adw_s0_io_out_bits_data_0[32] && adw_s1_io_out_bits_data_0[32])) begin cov_fail++; $display("[COV] Arbiter1_L1BankedDataWriteReq.io_out_bits_data_0[32] 未见过 0 和 1"); end
    if (!(adw_s0_io_out_bits_data_0[33] && adw_s1_io_out_bits_data_0[33])) begin cov_fail++; $display("[COV] Arbiter1_L1BankedDataWriteReq.io_out_bits_data_0[33] 未见过 0 和 1"); end
    if (!(adw_s0_io_out_bits_data_0[34] && adw_s1_io_out_bits_data_0[34])) begin cov_fail++; $display("[COV] Arbiter1_L1BankedDataWriteReq.io_out_bits_data_0[34] 未见过 0 和 1"); end
    if (!(adw_s0_io_out_bits_data_0[35] && adw_s1_io_out_bits_data_0[35])) begin cov_fail++; $display("[COV] Arbiter1_L1BankedDataWriteReq.io_out_bits_data_0[35] 未见过 0 和 1"); end
    if (!(adw_s0_io_out_bits_data_0[36] && adw_s1_io_out_bits_data_0[36])) begin cov_fail++; $display("[COV] Arbiter1_L1BankedDataWriteReq.io_out_bits_data_0[36] 未见过 0 和 1"); end
    if (!(adw_s0_io_out_bits_data_0[37] && adw_s1_io_out_bits_data_0[37])) begin cov_fail++; $display("[COV] Arbiter1_L1BankedDataWriteReq.io_out_bits_data_0[37] 未见过 0 和 1"); end
    if (!(adw_s0_io_out_bits_data_0[38] && adw_s1_io_out_bits_data_0[38])) begin cov_fail++; $display("[COV] Arbiter1_L1BankedDataWriteReq.io_out_bits_data_0[38] 未见过 0 和 1"); end
    if (!(adw_s0_io_out_bits_data_0[39] && adw_s1_io_out_bits_data_0[39])) begin cov_fail++; $display("[COV] Arbiter1_L1BankedDataWriteReq.io_out_bits_data_0[39] 未见过 0 和 1"); end
    if (!(adw_s0_io_out_bits_data_0[40] && adw_s1_io_out_bits_data_0[40])) begin cov_fail++; $display("[COV] Arbiter1_L1BankedDataWriteReq.io_out_bits_data_0[40] 未见过 0 和 1"); end
    if (!(adw_s0_io_out_bits_data_0[41] && adw_s1_io_out_bits_data_0[41])) begin cov_fail++; $display("[COV] Arbiter1_L1BankedDataWriteReq.io_out_bits_data_0[41] 未见过 0 和 1"); end
    if (!(adw_s0_io_out_bits_data_0[42] && adw_s1_io_out_bits_data_0[42])) begin cov_fail++; $display("[COV] Arbiter1_L1BankedDataWriteReq.io_out_bits_data_0[42] 未见过 0 和 1"); end
    if (!(adw_s0_io_out_bits_data_0[43] && adw_s1_io_out_bits_data_0[43])) begin cov_fail++; $display("[COV] Arbiter1_L1BankedDataWriteReq.io_out_bits_data_0[43] 未见过 0 和 1"); end
    if (!(adw_s0_io_out_bits_data_0[44] && adw_s1_io_out_bits_data_0[44])) begin cov_fail++; $display("[COV] Arbiter1_L1BankedDataWriteReq.io_out_bits_data_0[44] 未见过 0 和 1"); end
    if (!(adw_s0_io_out_bits_data_0[45] && adw_s1_io_out_bits_data_0[45])) begin cov_fail++; $display("[COV] Arbiter1_L1BankedDataWriteReq.io_out_bits_data_0[45] 未见过 0 和 1"); end
    if (!(adw_s0_io_out_bits_data_0[46] && adw_s1_io_out_bits_data_0[46])) begin cov_fail++; $display("[COV] Arbiter1_L1BankedDataWriteReq.io_out_bits_data_0[46] 未见过 0 和 1"); end
    if (!(adw_s0_io_out_bits_data_0[47] && adw_s1_io_out_bits_data_0[47])) begin cov_fail++; $display("[COV] Arbiter1_L1BankedDataWriteReq.io_out_bits_data_0[47] 未见过 0 和 1"); end
    if (!(adw_s0_io_out_bits_data_0[48] && adw_s1_io_out_bits_data_0[48])) begin cov_fail++; $display("[COV] Arbiter1_L1BankedDataWriteReq.io_out_bits_data_0[48] 未见过 0 和 1"); end
    if (!(adw_s0_io_out_bits_data_0[49] && adw_s1_io_out_bits_data_0[49])) begin cov_fail++; $display("[COV] Arbiter1_L1BankedDataWriteReq.io_out_bits_data_0[49] 未见过 0 和 1"); end
    if (!(adw_s0_io_out_bits_data_0[50] && adw_s1_io_out_bits_data_0[50])) begin cov_fail++; $display("[COV] Arbiter1_L1BankedDataWriteReq.io_out_bits_data_0[50] 未见过 0 和 1"); end
    if (!(adw_s0_io_out_bits_data_0[51] && adw_s1_io_out_bits_data_0[51])) begin cov_fail++; $display("[COV] Arbiter1_L1BankedDataWriteReq.io_out_bits_data_0[51] 未见过 0 和 1"); end
    if (!(adw_s0_io_out_bits_data_0[52] && adw_s1_io_out_bits_data_0[52])) begin cov_fail++; $display("[COV] Arbiter1_L1BankedDataWriteReq.io_out_bits_data_0[52] 未见过 0 和 1"); end
    if (!(adw_s0_io_out_bits_data_0[53] && adw_s1_io_out_bits_data_0[53])) begin cov_fail++; $display("[COV] Arbiter1_L1BankedDataWriteReq.io_out_bits_data_0[53] 未见过 0 和 1"); end
    if (!(adw_s0_io_out_bits_data_0[54] && adw_s1_io_out_bits_data_0[54])) begin cov_fail++; $display("[COV] Arbiter1_L1BankedDataWriteReq.io_out_bits_data_0[54] 未见过 0 和 1"); end
    if (!(adw_s0_io_out_bits_data_0[55] && adw_s1_io_out_bits_data_0[55])) begin cov_fail++; $display("[COV] Arbiter1_L1BankedDataWriteReq.io_out_bits_data_0[55] 未见过 0 和 1"); end
    if (!(adw_s0_io_out_bits_data_0[56] && adw_s1_io_out_bits_data_0[56])) begin cov_fail++; $display("[COV] Arbiter1_L1BankedDataWriteReq.io_out_bits_data_0[56] 未见过 0 和 1"); end
    if (!(adw_s0_io_out_bits_data_0[57] && adw_s1_io_out_bits_data_0[57])) begin cov_fail++; $display("[COV] Arbiter1_L1BankedDataWriteReq.io_out_bits_data_0[57] 未见过 0 和 1"); end
    if (!(adw_s0_io_out_bits_data_0[58] && adw_s1_io_out_bits_data_0[58])) begin cov_fail++; $display("[COV] Arbiter1_L1BankedDataWriteReq.io_out_bits_data_0[58] 未见过 0 和 1"); end
    if (!(adw_s0_io_out_bits_data_0[59] && adw_s1_io_out_bits_data_0[59])) begin cov_fail++; $display("[COV] Arbiter1_L1BankedDataWriteReq.io_out_bits_data_0[59] 未见过 0 和 1"); end
    if (!(adw_s0_io_out_bits_data_0[60] && adw_s1_io_out_bits_data_0[60])) begin cov_fail++; $display("[COV] Arbiter1_L1BankedDataWriteReq.io_out_bits_data_0[60] 未见过 0 和 1"); end
    if (!(adw_s0_io_out_bits_data_0[61] && adw_s1_io_out_bits_data_0[61])) begin cov_fail++; $display("[COV] Arbiter1_L1BankedDataWriteReq.io_out_bits_data_0[61] 未见过 0 和 1"); end
    if (!(adw_s0_io_out_bits_data_0[62] && adw_s1_io_out_bits_data_0[62])) begin cov_fail++; $display("[COV] Arbiter1_L1BankedDataWriteReq.io_out_bits_data_0[62] 未见过 0 和 1"); end
    if (!(adw_s0_io_out_bits_data_0[63] && adw_s1_io_out_bits_data_0[63])) begin cov_fail++; $display("[COV] Arbiter1_L1BankedDataWriteReq.io_out_bits_data_0[63] 未见过 0 和 1"); end
    if (!(adw_s0_io_out_bits_data_1[0] && adw_s1_io_out_bits_data_1[0])) begin cov_fail++; $display("[COV] Arbiter1_L1BankedDataWriteReq.io_out_bits_data_1[0] 未见过 0 和 1"); end
    if (!(adw_s0_io_out_bits_data_1[1] && adw_s1_io_out_bits_data_1[1])) begin cov_fail++; $display("[COV] Arbiter1_L1BankedDataWriteReq.io_out_bits_data_1[1] 未见过 0 和 1"); end
    if (!(adw_s0_io_out_bits_data_1[2] && adw_s1_io_out_bits_data_1[2])) begin cov_fail++; $display("[COV] Arbiter1_L1BankedDataWriteReq.io_out_bits_data_1[2] 未见过 0 和 1"); end
    if (!(adw_s0_io_out_bits_data_1[3] && adw_s1_io_out_bits_data_1[3])) begin cov_fail++; $display("[COV] Arbiter1_L1BankedDataWriteReq.io_out_bits_data_1[3] 未见过 0 和 1"); end
    if (!(adw_s0_io_out_bits_data_1[4] && adw_s1_io_out_bits_data_1[4])) begin cov_fail++; $display("[COV] Arbiter1_L1BankedDataWriteReq.io_out_bits_data_1[4] 未见过 0 和 1"); end
    if (!(adw_s0_io_out_bits_data_1[5] && adw_s1_io_out_bits_data_1[5])) begin cov_fail++; $display("[COV] Arbiter1_L1BankedDataWriteReq.io_out_bits_data_1[5] 未见过 0 和 1"); end
    if (!(adw_s0_io_out_bits_data_1[6] && adw_s1_io_out_bits_data_1[6])) begin cov_fail++; $display("[COV] Arbiter1_L1BankedDataWriteReq.io_out_bits_data_1[6] 未见过 0 和 1"); end
    if (!(adw_s0_io_out_bits_data_1[7] && adw_s1_io_out_bits_data_1[7])) begin cov_fail++; $display("[COV] Arbiter1_L1BankedDataWriteReq.io_out_bits_data_1[7] 未见过 0 和 1"); end
    if (!(adw_s0_io_out_bits_data_1[8] && adw_s1_io_out_bits_data_1[8])) begin cov_fail++; $display("[COV] Arbiter1_L1BankedDataWriteReq.io_out_bits_data_1[8] 未见过 0 和 1"); end
    if (!(adw_s0_io_out_bits_data_1[9] && adw_s1_io_out_bits_data_1[9])) begin cov_fail++; $display("[COV] Arbiter1_L1BankedDataWriteReq.io_out_bits_data_1[9] 未见过 0 和 1"); end
    if (!(adw_s0_io_out_bits_data_1[10] && adw_s1_io_out_bits_data_1[10])) begin cov_fail++; $display("[COV] Arbiter1_L1BankedDataWriteReq.io_out_bits_data_1[10] 未见过 0 和 1"); end
    if (!(adw_s0_io_out_bits_data_1[11] && adw_s1_io_out_bits_data_1[11])) begin cov_fail++; $display("[COV] Arbiter1_L1BankedDataWriteReq.io_out_bits_data_1[11] 未见过 0 和 1"); end
    if (!(adw_s0_io_out_bits_data_1[12] && adw_s1_io_out_bits_data_1[12])) begin cov_fail++; $display("[COV] Arbiter1_L1BankedDataWriteReq.io_out_bits_data_1[12] 未见过 0 和 1"); end
    if (!(adw_s0_io_out_bits_data_1[13] && adw_s1_io_out_bits_data_1[13])) begin cov_fail++; $display("[COV] Arbiter1_L1BankedDataWriteReq.io_out_bits_data_1[13] 未见过 0 和 1"); end
    if (!(adw_s0_io_out_bits_data_1[14] && adw_s1_io_out_bits_data_1[14])) begin cov_fail++; $display("[COV] Arbiter1_L1BankedDataWriteReq.io_out_bits_data_1[14] 未见过 0 和 1"); end
    if (!(adw_s0_io_out_bits_data_1[15] && adw_s1_io_out_bits_data_1[15])) begin cov_fail++; $display("[COV] Arbiter1_L1BankedDataWriteReq.io_out_bits_data_1[15] 未见过 0 和 1"); end
    if (!(adw_s0_io_out_bits_data_1[16] && adw_s1_io_out_bits_data_1[16])) begin cov_fail++; $display("[COV] Arbiter1_L1BankedDataWriteReq.io_out_bits_data_1[16] 未见过 0 和 1"); end
    if (!(adw_s0_io_out_bits_data_1[17] && adw_s1_io_out_bits_data_1[17])) begin cov_fail++; $display("[COV] Arbiter1_L1BankedDataWriteReq.io_out_bits_data_1[17] 未见过 0 和 1"); end
    if (!(adw_s0_io_out_bits_data_1[18] && adw_s1_io_out_bits_data_1[18])) begin cov_fail++; $display("[COV] Arbiter1_L1BankedDataWriteReq.io_out_bits_data_1[18] 未见过 0 和 1"); end
    if (!(adw_s0_io_out_bits_data_1[19] && adw_s1_io_out_bits_data_1[19])) begin cov_fail++; $display("[COV] Arbiter1_L1BankedDataWriteReq.io_out_bits_data_1[19] 未见过 0 和 1"); end
    if (!(adw_s0_io_out_bits_data_1[20] && adw_s1_io_out_bits_data_1[20])) begin cov_fail++; $display("[COV] Arbiter1_L1BankedDataWriteReq.io_out_bits_data_1[20] 未见过 0 和 1"); end
    if (!(adw_s0_io_out_bits_data_1[21] && adw_s1_io_out_bits_data_1[21])) begin cov_fail++; $display("[COV] Arbiter1_L1BankedDataWriteReq.io_out_bits_data_1[21] 未见过 0 和 1"); end
    if (!(adw_s0_io_out_bits_data_1[22] && adw_s1_io_out_bits_data_1[22])) begin cov_fail++; $display("[COV] Arbiter1_L1BankedDataWriteReq.io_out_bits_data_1[22] 未见过 0 和 1"); end
    if (!(adw_s0_io_out_bits_data_1[23] && adw_s1_io_out_bits_data_1[23])) begin cov_fail++; $display("[COV] Arbiter1_L1BankedDataWriteReq.io_out_bits_data_1[23] 未见过 0 和 1"); end
    if (!(adw_s0_io_out_bits_data_1[24] && adw_s1_io_out_bits_data_1[24])) begin cov_fail++; $display("[COV] Arbiter1_L1BankedDataWriteReq.io_out_bits_data_1[24] 未见过 0 和 1"); end
    if (!(adw_s0_io_out_bits_data_1[25] && adw_s1_io_out_bits_data_1[25])) begin cov_fail++; $display("[COV] Arbiter1_L1BankedDataWriteReq.io_out_bits_data_1[25] 未见过 0 和 1"); end
    if (!(adw_s0_io_out_bits_data_1[26] && adw_s1_io_out_bits_data_1[26])) begin cov_fail++; $display("[COV] Arbiter1_L1BankedDataWriteReq.io_out_bits_data_1[26] 未见过 0 和 1"); end
    if (!(adw_s0_io_out_bits_data_1[27] && adw_s1_io_out_bits_data_1[27])) begin cov_fail++; $display("[COV] Arbiter1_L1BankedDataWriteReq.io_out_bits_data_1[27] 未见过 0 和 1"); end
    if (!(adw_s0_io_out_bits_data_1[28] && adw_s1_io_out_bits_data_1[28])) begin cov_fail++; $display("[COV] Arbiter1_L1BankedDataWriteReq.io_out_bits_data_1[28] 未见过 0 和 1"); end
    if (!(adw_s0_io_out_bits_data_1[29] && adw_s1_io_out_bits_data_1[29])) begin cov_fail++; $display("[COV] Arbiter1_L1BankedDataWriteReq.io_out_bits_data_1[29] 未见过 0 和 1"); end
    if (!(adw_s0_io_out_bits_data_1[30] && adw_s1_io_out_bits_data_1[30])) begin cov_fail++; $display("[COV] Arbiter1_L1BankedDataWriteReq.io_out_bits_data_1[30] 未见过 0 和 1"); end
    if (!(adw_s0_io_out_bits_data_1[31] && adw_s1_io_out_bits_data_1[31])) begin cov_fail++; $display("[COV] Arbiter1_L1BankedDataWriteReq.io_out_bits_data_1[31] 未见过 0 和 1"); end
    if (!(adw_s0_io_out_bits_data_1[32] && adw_s1_io_out_bits_data_1[32])) begin cov_fail++; $display("[COV] Arbiter1_L1BankedDataWriteReq.io_out_bits_data_1[32] 未见过 0 和 1"); end
    if (!(adw_s0_io_out_bits_data_1[33] && adw_s1_io_out_bits_data_1[33])) begin cov_fail++; $display("[COV] Arbiter1_L1BankedDataWriteReq.io_out_bits_data_1[33] 未见过 0 和 1"); end
    if (!(adw_s0_io_out_bits_data_1[34] && adw_s1_io_out_bits_data_1[34])) begin cov_fail++; $display("[COV] Arbiter1_L1BankedDataWriteReq.io_out_bits_data_1[34] 未见过 0 和 1"); end
    if (!(adw_s0_io_out_bits_data_1[35] && adw_s1_io_out_bits_data_1[35])) begin cov_fail++; $display("[COV] Arbiter1_L1BankedDataWriteReq.io_out_bits_data_1[35] 未见过 0 和 1"); end
    if (!(adw_s0_io_out_bits_data_1[36] && adw_s1_io_out_bits_data_1[36])) begin cov_fail++; $display("[COV] Arbiter1_L1BankedDataWriteReq.io_out_bits_data_1[36] 未见过 0 和 1"); end
    if (!(adw_s0_io_out_bits_data_1[37] && adw_s1_io_out_bits_data_1[37])) begin cov_fail++; $display("[COV] Arbiter1_L1BankedDataWriteReq.io_out_bits_data_1[37] 未见过 0 和 1"); end
    if (!(adw_s0_io_out_bits_data_1[38] && adw_s1_io_out_bits_data_1[38])) begin cov_fail++; $display("[COV] Arbiter1_L1BankedDataWriteReq.io_out_bits_data_1[38] 未见过 0 和 1"); end
    if (!(adw_s0_io_out_bits_data_1[39] && adw_s1_io_out_bits_data_1[39])) begin cov_fail++; $display("[COV] Arbiter1_L1BankedDataWriteReq.io_out_bits_data_1[39] 未见过 0 和 1"); end
    if (!(adw_s0_io_out_bits_data_1[40] && adw_s1_io_out_bits_data_1[40])) begin cov_fail++; $display("[COV] Arbiter1_L1BankedDataWriteReq.io_out_bits_data_1[40] 未见过 0 和 1"); end
    if (!(adw_s0_io_out_bits_data_1[41] && adw_s1_io_out_bits_data_1[41])) begin cov_fail++; $display("[COV] Arbiter1_L1BankedDataWriteReq.io_out_bits_data_1[41] 未见过 0 和 1"); end
    if (!(adw_s0_io_out_bits_data_1[42] && adw_s1_io_out_bits_data_1[42])) begin cov_fail++; $display("[COV] Arbiter1_L1BankedDataWriteReq.io_out_bits_data_1[42] 未见过 0 和 1"); end
    if (!(adw_s0_io_out_bits_data_1[43] && adw_s1_io_out_bits_data_1[43])) begin cov_fail++; $display("[COV] Arbiter1_L1BankedDataWriteReq.io_out_bits_data_1[43] 未见过 0 和 1"); end
    if (!(adw_s0_io_out_bits_data_1[44] && adw_s1_io_out_bits_data_1[44])) begin cov_fail++; $display("[COV] Arbiter1_L1BankedDataWriteReq.io_out_bits_data_1[44] 未见过 0 和 1"); end
    if (!(adw_s0_io_out_bits_data_1[45] && adw_s1_io_out_bits_data_1[45])) begin cov_fail++; $display("[COV] Arbiter1_L1BankedDataWriteReq.io_out_bits_data_1[45] 未见过 0 和 1"); end
    if (!(adw_s0_io_out_bits_data_1[46] && adw_s1_io_out_bits_data_1[46])) begin cov_fail++; $display("[COV] Arbiter1_L1BankedDataWriteReq.io_out_bits_data_1[46] 未见过 0 和 1"); end
    if (!(adw_s0_io_out_bits_data_1[47] && adw_s1_io_out_bits_data_1[47])) begin cov_fail++; $display("[COV] Arbiter1_L1BankedDataWriteReq.io_out_bits_data_1[47] 未见过 0 和 1"); end
    if (!(adw_s0_io_out_bits_data_1[48] && adw_s1_io_out_bits_data_1[48])) begin cov_fail++; $display("[COV] Arbiter1_L1BankedDataWriteReq.io_out_bits_data_1[48] 未见过 0 和 1"); end
    if (!(adw_s0_io_out_bits_data_1[49] && adw_s1_io_out_bits_data_1[49])) begin cov_fail++; $display("[COV] Arbiter1_L1BankedDataWriteReq.io_out_bits_data_1[49] 未见过 0 和 1"); end
    if (!(adw_s0_io_out_bits_data_1[50] && adw_s1_io_out_bits_data_1[50])) begin cov_fail++; $display("[COV] Arbiter1_L1BankedDataWriteReq.io_out_bits_data_1[50] 未见过 0 和 1"); end
    if (!(adw_s0_io_out_bits_data_1[51] && adw_s1_io_out_bits_data_1[51])) begin cov_fail++; $display("[COV] Arbiter1_L1BankedDataWriteReq.io_out_bits_data_1[51] 未见过 0 和 1"); end
    if (!(adw_s0_io_out_bits_data_1[52] && adw_s1_io_out_bits_data_1[52])) begin cov_fail++; $display("[COV] Arbiter1_L1BankedDataWriteReq.io_out_bits_data_1[52] 未见过 0 和 1"); end
    if (!(adw_s0_io_out_bits_data_1[53] && adw_s1_io_out_bits_data_1[53])) begin cov_fail++; $display("[COV] Arbiter1_L1BankedDataWriteReq.io_out_bits_data_1[53] 未见过 0 和 1"); end
    if (!(adw_s0_io_out_bits_data_1[54] && adw_s1_io_out_bits_data_1[54])) begin cov_fail++; $display("[COV] Arbiter1_L1BankedDataWriteReq.io_out_bits_data_1[54] 未见过 0 和 1"); end
    if (!(adw_s0_io_out_bits_data_1[55] && adw_s1_io_out_bits_data_1[55])) begin cov_fail++; $display("[COV] Arbiter1_L1BankedDataWriteReq.io_out_bits_data_1[55] 未见过 0 和 1"); end
    if (!(adw_s0_io_out_bits_data_1[56] && adw_s1_io_out_bits_data_1[56])) begin cov_fail++; $display("[COV] Arbiter1_L1BankedDataWriteReq.io_out_bits_data_1[56] 未见过 0 和 1"); end
    if (!(adw_s0_io_out_bits_data_1[57] && adw_s1_io_out_bits_data_1[57])) begin cov_fail++; $display("[COV] Arbiter1_L1BankedDataWriteReq.io_out_bits_data_1[57] 未见过 0 和 1"); end
    if (!(adw_s0_io_out_bits_data_1[58] && adw_s1_io_out_bits_data_1[58])) begin cov_fail++; $display("[COV] Arbiter1_L1BankedDataWriteReq.io_out_bits_data_1[58] 未见过 0 和 1"); end
    if (!(adw_s0_io_out_bits_data_1[59] && adw_s1_io_out_bits_data_1[59])) begin cov_fail++; $display("[COV] Arbiter1_L1BankedDataWriteReq.io_out_bits_data_1[59] 未见过 0 和 1"); end
    if (!(adw_s0_io_out_bits_data_1[60] && adw_s1_io_out_bits_data_1[60])) begin cov_fail++; $display("[COV] Arbiter1_L1BankedDataWriteReq.io_out_bits_data_1[60] 未见过 0 和 1"); end
    if (!(adw_s0_io_out_bits_data_1[61] && adw_s1_io_out_bits_data_1[61])) begin cov_fail++; $display("[COV] Arbiter1_L1BankedDataWriteReq.io_out_bits_data_1[61] 未见过 0 和 1"); end
    if (!(adw_s0_io_out_bits_data_1[62] && adw_s1_io_out_bits_data_1[62])) begin cov_fail++; $display("[COV] Arbiter1_L1BankedDataWriteReq.io_out_bits_data_1[62] 未见过 0 和 1"); end
    if (!(adw_s0_io_out_bits_data_1[63] && adw_s1_io_out_bits_data_1[63])) begin cov_fail++; $display("[COV] Arbiter1_L1BankedDataWriteReq.io_out_bits_data_1[63] 未见过 0 和 1"); end
    if (!(adw_s0_io_out_bits_data_2[0] && adw_s1_io_out_bits_data_2[0])) begin cov_fail++; $display("[COV] Arbiter1_L1BankedDataWriteReq.io_out_bits_data_2[0] 未见过 0 和 1"); end
    if (!(adw_s0_io_out_bits_data_2[1] && adw_s1_io_out_bits_data_2[1])) begin cov_fail++; $display("[COV] Arbiter1_L1BankedDataWriteReq.io_out_bits_data_2[1] 未见过 0 和 1"); end
    if (!(adw_s0_io_out_bits_data_2[2] && adw_s1_io_out_bits_data_2[2])) begin cov_fail++; $display("[COV] Arbiter1_L1BankedDataWriteReq.io_out_bits_data_2[2] 未见过 0 和 1"); end
    if (!(adw_s0_io_out_bits_data_2[3] && adw_s1_io_out_bits_data_2[3])) begin cov_fail++; $display("[COV] Arbiter1_L1BankedDataWriteReq.io_out_bits_data_2[3] 未见过 0 和 1"); end
    if (!(adw_s0_io_out_bits_data_2[4] && adw_s1_io_out_bits_data_2[4])) begin cov_fail++; $display("[COV] Arbiter1_L1BankedDataWriteReq.io_out_bits_data_2[4] 未见过 0 和 1"); end
    if (!(adw_s0_io_out_bits_data_2[5] && adw_s1_io_out_bits_data_2[5])) begin cov_fail++; $display("[COV] Arbiter1_L1BankedDataWriteReq.io_out_bits_data_2[5] 未见过 0 和 1"); end
    if (!(adw_s0_io_out_bits_data_2[6] && adw_s1_io_out_bits_data_2[6])) begin cov_fail++; $display("[COV] Arbiter1_L1BankedDataWriteReq.io_out_bits_data_2[6] 未见过 0 和 1"); end
    if (!(adw_s0_io_out_bits_data_2[7] && adw_s1_io_out_bits_data_2[7])) begin cov_fail++; $display("[COV] Arbiter1_L1BankedDataWriteReq.io_out_bits_data_2[7] 未见过 0 和 1"); end
    if (!(adw_s0_io_out_bits_data_2[8] && adw_s1_io_out_bits_data_2[8])) begin cov_fail++; $display("[COV] Arbiter1_L1BankedDataWriteReq.io_out_bits_data_2[8] 未见过 0 和 1"); end
    if (!(adw_s0_io_out_bits_data_2[9] && adw_s1_io_out_bits_data_2[9])) begin cov_fail++; $display("[COV] Arbiter1_L1BankedDataWriteReq.io_out_bits_data_2[9] 未见过 0 和 1"); end
    if (!(adw_s0_io_out_bits_data_2[10] && adw_s1_io_out_bits_data_2[10])) begin cov_fail++; $display("[COV] Arbiter1_L1BankedDataWriteReq.io_out_bits_data_2[10] 未见过 0 和 1"); end
    if (!(adw_s0_io_out_bits_data_2[11] && adw_s1_io_out_bits_data_2[11])) begin cov_fail++; $display("[COV] Arbiter1_L1BankedDataWriteReq.io_out_bits_data_2[11] 未见过 0 和 1"); end
    if (!(adw_s0_io_out_bits_data_2[12] && adw_s1_io_out_bits_data_2[12])) begin cov_fail++; $display("[COV] Arbiter1_L1BankedDataWriteReq.io_out_bits_data_2[12] 未见过 0 和 1"); end
    if (!(adw_s0_io_out_bits_data_2[13] && adw_s1_io_out_bits_data_2[13])) begin cov_fail++; $display("[COV] Arbiter1_L1BankedDataWriteReq.io_out_bits_data_2[13] 未见过 0 和 1"); end
    if (!(adw_s0_io_out_bits_data_2[14] && adw_s1_io_out_bits_data_2[14])) begin cov_fail++; $display("[COV] Arbiter1_L1BankedDataWriteReq.io_out_bits_data_2[14] 未见过 0 和 1"); end
    if (!(adw_s0_io_out_bits_data_2[15] && adw_s1_io_out_bits_data_2[15])) begin cov_fail++; $display("[COV] Arbiter1_L1BankedDataWriteReq.io_out_bits_data_2[15] 未见过 0 和 1"); end
    if (!(adw_s0_io_out_bits_data_2[16] && adw_s1_io_out_bits_data_2[16])) begin cov_fail++; $display("[COV] Arbiter1_L1BankedDataWriteReq.io_out_bits_data_2[16] 未见过 0 和 1"); end
    if (!(adw_s0_io_out_bits_data_2[17] && adw_s1_io_out_bits_data_2[17])) begin cov_fail++; $display("[COV] Arbiter1_L1BankedDataWriteReq.io_out_bits_data_2[17] 未见过 0 和 1"); end
    if (!(adw_s0_io_out_bits_data_2[18] && adw_s1_io_out_bits_data_2[18])) begin cov_fail++; $display("[COV] Arbiter1_L1BankedDataWriteReq.io_out_bits_data_2[18] 未见过 0 和 1"); end
    if (!(adw_s0_io_out_bits_data_2[19] && adw_s1_io_out_bits_data_2[19])) begin cov_fail++; $display("[COV] Arbiter1_L1BankedDataWriteReq.io_out_bits_data_2[19] 未见过 0 和 1"); end
    if (!(adw_s0_io_out_bits_data_2[20] && adw_s1_io_out_bits_data_2[20])) begin cov_fail++; $display("[COV] Arbiter1_L1BankedDataWriteReq.io_out_bits_data_2[20] 未见过 0 和 1"); end
    if (!(adw_s0_io_out_bits_data_2[21] && adw_s1_io_out_bits_data_2[21])) begin cov_fail++; $display("[COV] Arbiter1_L1BankedDataWriteReq.io_out_bits_data_2[21] 未见过 0 和 1"); end
    if (!(adw_s0_io_out_bits_data_2[22] && adw_s1_io_out_bits_data_2[22])) begin cov_fail++; $display("[COV] Arbiter1_L1BankedDataWriteReq.io_out_bits_data_2[22] 未见过 0 和 1"); end
    if (!(adw_s0_io_out_bits_data_2[23] && adw_s1_io_out_bits_data_2[23])) begin cov_fail++; $display("[COV] Arbiter1_L1BankedDataWriteReq.io_out_bits_data_2[23] 未见过 0 和 1"); end
    if (!(adw_s0_io_out_bits_data_2[24] && adw_s1_io_out_bits_data_2[24])) begin cov_fail++; $display("[COV] Arbiter1_L1BankedDataWriteReq.io_out_bits_data_2[24] 未见过 0 和 1"); end
    if (!(adw_s0_io_out_bits_data_2[25] && adw_s1_io_out_bits_data_2[25])) begin cov_fail++; $display("[COV] Arbiter1_L1BankedDataWriteReq.io_out_bits_data_2[25] 未见过 0 和 1"); end
    if (!(adw_s0_io_out_bits_data_2[26] && adw_s1_io_out_bits_data_2[26])) begin cov_fail++; $display("[COV] Arbiter1_L1BankedDataWriteReq.io_out_bits_data_2[26] 未见过 0 和 1"); end
    if (!(adw_s0_io_out_bits_data_2[27] && adw_s1_io_out_bits_data_2[27])) begin cov_fail++; $display("[COV] Arbiter1_L1BankedDataWriteReq.io_out_bits_data_2[27] 未见过 0 和 1"); end
    if (!(adw_s0_io_out_bits_data_2[28] && adw_s1_io_out_bits_data_2[28])) begin cov_fail++; $display("[COV] Arbiter1_L1BankedDataWriteReq.io_out_bits_data_2[28] 未见过 0 和 1"); end
    if (!(adw_s0_io_out_bits_data_2[29] && adw_s1_io_out_bits_data_2[29])) begin cov_fail++; $display("[COV] Arbiter1_L1BankedDataWriteReq.io_out_bits_data_2[29] 未见过 0 和 1"); end
    if (!(adw_s0_io_out_bits_data_2[30] && adw_s1_io_out_bits_data_2[30])) begin cov_fail++; $display("[COV] Arbiter1_L1BankedDataWriteReq.io_out_bits_data_2[30] 未见过 0 和 1"); end
    if (!(adw_s0_io_out_bits_data_2[31] && adw_s1_io_out_bits_data_2[31])) begin cov_fail++; $display("[COV] Arbiter1_L1BankedDataWriteReq.io_out_bits_data_2[31] 未见过 0 和 1"); end
    if (!(adw_s0_io_out_bits_data_2[32] && adw_s1_io_out_bits_data_2[32])) begin cov_fail++; $display("[COV] Arbiter1_L1BankedDataWriteReq.io_out_bits_data_2[32] 未见过 0 和 1"); end
    if (!(adw_s0_io_out_bits_data_2[33] && adw_s1_io_out_bits_data_2[33])) begin cov_fail++; $display("[COV] Arbiter1_L1BankedDataWriteReq.io_out_bits_data_2[33] 未见过 0 和 1"); end
    if (!(adw_s0_io_out_bits_data_2[34] && adw_s1_io_out_bits_data_2[34])) begin cov_fail++; $display("[COV] Arbiter1_L1BankedDataWriteReq.io_out_bits_data_2[34] 未见过 0 和 1"); end
    if (!(adw_s0_io_out_bits_data_2[35] && adw_s1_io_out_bits_data_2[35])) begin cov_fail++; $display("[COV] Arbiter1_L1BankedDataWriteReq.io_out_bits_data_2[35] 未见过 0 和 1"); end
    if (!(adw_s0_io_out_bits_data_2[36] && adw_s1_io_out_bits_data_2[36])) begin cov_fail++; $display("[COV] Arbiter1_L1BankedDataWriteReq.io_out_bits_data_2[36] 未见过 0 和 1"); end
    if (!(adw_s0_io_out_bits_data_2[37] && adw_s1_io_out_bits_data_2[37])) begin cov_fail++; $display("[COV] Arbiter1_L1BankedDataWriteReq.io_out_bits_data_2[37] 未见过 0 和 1"); end
    if (!(adw_s0_io_out_bits_data_2[38] && adw_s1_io_out_bits_data_2[38])) begin cov_fail++; $display("[COV] Arbiter1_L1BankedDataWriteReq.io_out_bits_data_2[38] 未见过 0 和 1"); end
    if (!(adw_s0_io_out_bits_data_2[39] && adw_s1_io_out_bits_data_2[39])) begin cov_fail++; $display("[COV] Arbiter1_L1BankedDataWriteReq.io_out_bits_data_2[39] 未见过 0 和 1"); end
    if (!(adw_s0_io_out_bits_data_2[40] && adw_s1_io_out_bits_data_2[40])) begin cov_fail++; $display("[COV] Arbiter1_L1BankedDataWriteReq.io_out_bits_data_2[40] 未见过 0 和 1"); end
    if (!(adw_s0_io_out_bits_data_2[41] && adw_s1_io_out_bits_data_2[41])) begin cov_fail++; $display("[COV] Arbiter1_L1BankedDataWriteReq.io_out_bits_data_2[41] 未见过 0 和 1"); end
    if (!(adw_s0_io_out_bits_data_2[42] && adw_s1_io_out_bits_data_2[42])) begin cov_fail++; $display("[COV] Arbiter1_L1BankedDataWriteReq.io_out_bits_data_2[42] 未见过 0 和 1"); end
    if (!(adw_s0_io_out_bits_data_2[43] && adw_s1_io_out_bits_data_2[43])) begin cov_fail++; $display("[COV] Arbiter1_L1BankedDataWriteReq.io_out_bits_data_2[43] 未见过 0 和 1"); end
    if (!(adw_s0_io_out_bits_data_2[44] && adw_s1_io_out_bits_data_2[44])) begin cov_fail++; $display("[COV] Arbiter1_L1BankedDataWriteReq.io_out_bits_data_2[44] 未见过 0 和 1"); end
    if (!(adw_s0_io_out_bits_data_2[45] && adw_s1_io_out_bits_data_2[45])) begin cov_fail++; $display("[COV] Arbiter1_L1BankedDataWriteReq.io_out_bits_data_2[45] 未见过 0 和 1"); end
    if (!(adw_s0_io_out_bits_data_2[46] && adw_s1_io_out_bits_data_2[46])) begin cov_fail++; $display("[COV] Arbiter1_L1BankedDataWriteReq.io_out_bits_data_2[46] 未见过 0 和 1"); end
    if (!(adw_s0_io_out_bits_data_2[47] && adw_s1_io_out_bits_data_2[47])) begin cov_fail++; $display("[COV] Arbiter1_L1BankedDataWriteReq.io_out_bits_data_2[47] 未见过 0 和 1"); end
    if (!(adw_s0_io_out_bits_data_2[48] && adw_s1_io_out_bits_data_2[48])) begin cov_fail++; $display("[COV] Arbiter1_L1BankedDataWriteReq.io_out_bits_data_2[48] 未见过 0 和 1"); end
    if (!(adw_s0_io_out_bits_data_2[49] && adw_s1_io_out_bits_data_2[49])) begin cov_fail++; $display("[COV] Arbiter1_L1BankedDataWriteReq.io_out_bits_data_2[49] 未见过 0 和 1"); end
    if (!(adw_s0_io_out_bits_data_2[50] && adw_s1_io_out_bits_data_2[50])) begin cov_fail++; $display("[COV] Arbiter1_L1BankedDataWriteReq.io_out_bits_data_2[50] 未见过 0 和 1"); end
    if (!(adw_s0_io_out_bits_data_2[51] && adw_s1_io_out_bits_data_2[51])) begin cov_fail++; $display("[COV] Arbiter1_L1BankedDataWriteReq.io_out_bits_data_2[51] 未见过 0 和 1"); end
    if (!(adw_s0_io_out_bits_data_2[52] && adw_s1_io_out_bits_data_2[52])) begin cov_fail++; $display("[COV] Arbiter1_L1BankedDataWriteReq.io_out_bits_data_2[52] 未见过 0 和 1"); end
    if (!(adw_s0_io_out_bits_data_2[53] && adw_s1_io_out_bits_data_2[53])) begin cov_fail++; $display("[COV] Arbiter1_L1BankedDataWriteReq.io_out_bits_data_2[53] 未见过 0 和 1"); end
    if (!(adw_s0_io_out_bits_data_2[54] && adw_s1_io_out_bits_data_2[54])) begin cov_fail++; $display("[COV] Arbiter1_L1BankedDataWriteReq.io_out_bits_data_2[54] 未见过 0 和 1"); end
    if (!(adw_s0_io_out_bits_data_2[55] && adw_s1_io_out_bits_data_2[55])) begin cov_fail++; $display("[COV] Arbiter1_L1BankedDataWriteReq.io_out_bits_data_2[55] 未见过 0 和 1"); end
    if (!(adw_s0_io_out_bits_data_2[56] && adw_s1_io_out_bits_data_2[56])) begin cov_fail++; $display("[COV] Arbiter1_L1BankedDataWriteReq.io_out_bits_data_2[56] 未见过 0 和 1"); end
    if (!(adw_s0_io_out_bits_data_2[57] && adw_s1_io_out_bits_data_2[57])) begin cov_fail++; $display("[COV] Arbiter1_L1BankedDataWriteReq.io_out_bits_data_2[57] 未见过 0 和 1"); end
    if (!(adw_s0_io_out_bits_data_2[58] && adw_s1_io_out_bits_data_2[58])) begin cov_fail++; $display("[COV] Arbiter1_L1BankedDataWriteReq.io_out_bits_data_2[58] 未见过 0 和 1"); end
    if (!(adw_s0_io_out_bits_data_2[59] && adw_s1_io_out_bits_data_2[59])) begin cov_fail++; $display("[COV] Arbiter1_L1BankedDataWriteReq.io_out_bits_data_2[59] 未见过 0 和 1"); end
    if (!(adw_s0_io_out_bits_data_2[60] && adw_s1_io_out_bits_data_2[60])) begin cov_fail++; $display("[COV] Arbiter1_L1BankedDataWriteReq.io_out_bits_data_2[60] 未见过 0 和 1"); end
    if (!(adw_s0_io_out_bits_data_2[61] && adw_s1_io_out_bits_data_2[61])) begin cov_fail++; $display("[COV] Arbiter1_L1BankedDataWriteReq.io_out_bits_data_2[61] 未见过 0 和 1"); end
    if (!(adw_s0_io_out_bits_data_2[62] && adw_s1_io_out_bits_data_2[62])) begin cov_fail++; $display("[COV] Arbiter1_L1BankedDataWriteReq.io_out_bits_data_2[62] 未见过 0 和 1"); end
    if (!(adw_s0_io_out_bits_data_2[63] && adw_s1_io_out_bits_data_2[63])) begin cov_fail++; $display("[COV] Arbiter1_L1BankedDataWriteReq.io_out_bits_data_2[63] 未见过 0 和 1"); end
    if (!(adw_s0_io_out_bits_data_3[0] && adw_s1_io_out_bits_data_3[0])) begin cov_fail++; $display("[COV] Arbiter1_L1BankedDataWriteReq.io_out_bits_data_3[0] 未见过 0 和 1"); end
    if (!(adw_s0_io_out_bits_data_3[1] && adw_s1_io_out_bits_data_3[1])) begin cov_fail++; $display("[COV] Arbiter1_L1BankedDataWriteReq.io_out_bits_data_3[1] 未见过 0 和 1"); end
    if (!(adw_s0_io_out_bits_data_3[2] && adw_s1_io_out_bits_data_3[2])) begin cov_fail++; $display("[COV] Arbiter1_L1BankedDataWriteReq.io_out_bits_data_3[2] 未见过 0 和 1"); end
    if (!(adw_s0_io_out_bits_data_3[3] && adw_s1_io_out_bits_data_3[3])) begin cov_fail++; $display("[COV] Arbiter1_L1BankedDataWriteReq.io_out_bits_data_3[3] 未见过 0 和 1"); end
    if (!(adw_s0_io_out_bits_data_3[4] && adw_s1_io_out_bits_data_3[4])) begin cov_fail++; $display("[COV] Arbiter1_L1BankedDataWriteReq.io_out_bits_data_3[4] 未见过 0 和 1"); end
    if (!(adw_s0_io_out_bits_data_3[5] && adw_s1_io_out_bits_data_3[5])) begin cov_fail++; $display("[COV] Arbiter1_L1BankedDataWriteReq.io_out_bits_data_3[5] 未见过 0 和 1"); end
    if (!(adw_s0_io_out_bits_data_3[6] && adw_s1_io_out_bits_data_3[6])) begin cov_fail++; $display("[COV] Arbiter1_L1BankedDataWriteReq.io_out_bits_data_3[6] 未见过 0 和 1"); end
    if (!(adw_s0_io_out_bits_data_3[7] && adw_s1_io_out_bits_data_3[7])) begin cov_fail++; $display("[COV] Arbiter1_L1BankedDataWriteReq.io_out_bits_data_3[7] 未见过 0 和 1"); end
    if (!(adw_s0_io_out_bits_data_3[8] && adw_s1_io_out_bits_data_3[8])) begin cov_fail++; $display("[COV] Arbiter1_L1BankedDataWriteReq.io_out_bits_data_3[8] 未见过 0 和 1"); end
    if (!(adw_s0_io_out_bits_data_3[9] && adw_s1_io_out_bits_data_3[9])) begin cov_fail++; $display("[COV] Arbiter1_L1BankedDataWriteReq.io_out_bits_data_3[9] 未见过 0 和 1"); end
    if (!(adw_s0_io_out_bits_data_3[10] && adw_s1_io_out_bits_data_3[10])) begin cov_fail++; $display("[COV] Arbiter1_L1BankedDataWriteReq.io_out_bits_data_3[10] 未见过 0 和 1"); end
    if (!(adw_s0_io_out_bits_data_3[11] && adw_s1_io_out_bits_data_3[11])) begin cov_fail++; $display("[COV] Arbiter1_L1BankedDataWriteReq.io_out_bits_data_3[11] 未见过 0 和 1"); end
    if (!(adw_s0_io_out_bits_data_3[12] && adw_s1_io_out_bits_data_3[12])) begin cov_fail++; $display("[COV] Arbiter1_L1BankedDataWriteReq.io_out_bits_data_3[12] 未见过 0 和 1"); end
    if (!(adw_s0_io_out_bits_data_3[13] && adw_s1_io_out_bits_data_3[13])) begin cov_fail++; $display("[COV] Arbiter1_L1BankedDataWriteReq.io_out_bits_data_3[13] 未见过 0 和 1"); end
    if (!(adw_s0_io_out_bits_data_3[14] && adw_s1_io_out_bits_data_3[14])) begin cov_fail++; $display("[COV] Arbiter1_L1BankedDataWriteReq.io_out_bits_data_3[14] 未见过 0 和 1"); end
    if (!(adw_s0_io_out_bits_data_3[15] && adw_s1_io_out_bits_data_3[15])) begin cov_fail++; $display("[COV] Arbiter1_L1BankedDataWriteReq.io_out_bits_data_3[15] 未见过 0 和 1"); end
    if (!(adw_s0_io_out_bits_data_3[16] && adw_s1_io_out_bits_data_3[16])) begin cov_fail++; $display("[COV] Arbiter1_L1BankedDataWriteReq.io_out_bits_data_3[16] 未见过 0 和 1"); end
    if (!(adw_s0_io_out_bits_data_3[17] && adw_s1_io_out_bits_data_3[17])) begin cov_fail++; $display("[COV] Arbiter1_L1BankedDataWriteReq.io_out_bits_data_3[17] 未见过 0 和 1"); end
    if (!(adw_s0_io_out_bits_data_3[18] && adw_s1_io_out_bits_data_3[18])) begin cov_fail++; $display("[COV] Arbiter1_L1BankedDataWriteReq.io_out_bits_data_3[18] 未见过 0 和 1"); end
    if (!(adw_s0_io_out_bits_data_3[19] && adw_s1_io_out_bits_data_3[19])) begin cov_fail++; $display("[COV] Arbiter1_L1BankedDataWriteReq.io_out_bits_data_3[19] 未见过 0 和 1"); end
    if (!(adw_s0_io_out_bits_data_3[20] && adw_s1_io_out_bits_data_3[20])) begin cov_fail++; $display("[COV] Arbiter1_L1BankedDataWriteReq.io_out_bits_data_3[20] 未见过 0 和 1"); end
    if (!(adw_s0_io_out_bits_data_3[21] && adw_s1_io_out_bits_data_3[21])) begin cov_fail++; $display("[COV] Arbiter1_L1BankedDataWriteReq.io_out_bits_data_3[21] 未见过 0 和 1"); end
    if (!(adw_s0_io_out_bits_data_3[22] && adw_s1_io_out_bits_data_3[22])) begin cov_fail++; $display("[COV] Arbiter1_L1BankedDataWriteReq.io_out_bits_data_3[22] 未见过 0 和 1"); end
    if (!(adw_s0_io_out_bits_data_3[23] && adw_s1_io_out_bits_data_3[23])) begin cov_fail++; $display("[COV] Arbiter1_L1BankedDataWriteReq.io_out_bits_data_3[23] 未见过 0 和 1"); end
    if (!(adw_s0_io_out_bits_data_3[24] && adw_s1_io_out_bits_data_3[24])) begin cov_fail++; $display("[COV] Arbiter1_L1BankedDataWriteReq.io_out_bits_data_3[24] 未见过 0 和 1"); end
    if (!(adw_s0_io_out_bits_data_3[25] && adw_s1_io_out_bits_data_3[25])) begin cov_fail++; $display("[COV] Arbiter1_L1BankedDataWriteReq.io_out_bits_data_3[25] 未见过 0 和 1"); end
    if (!(adw_s0_io_out_bits_data_3[26] && adw_s1_io_out_bits_data_3[26])) begin cov_fail++; $display("[COV] Arbiter1_L1BankedDataWriteReq.io_out_bits_data_3[26] 未见过 0 和 1"); end
    if (!(adw_s0_io_out_bits_data_3[27] && adw_s1_io_out_bits_data_3[27])) begin cov_fail++; $display("[COV] Arbiter1_L1BankedDataWriteReq.io_out_bits_data_3[27] 未见过 0 和 1"); end
    if (!(adw_s0_io_out_bits_data_3[28] && adw_s1_io_out_bits_data_3[28])) begin cov_fail++; $display("[COV] Arbiter1_L1BankedDataWriteReq.io_out_bits_data_3[28] 未见过 0 和 1"); end
    if (!(adw_s0_io_out_bits_data_3[29] && adw_s1_io_out_bits_data_3[29])) begin cov_fail++; $display("[COV] Arbiter1_L1BankedDataWriteReq.io_out_bits_data_3[29] 未见过 0 和 1"); end
    if (!(adw_s0_io_out_bits_data_3[30] && adw_s1_io_out_bits_data_3[30])) begin cov_fail++; $display("[COV] Arbiter1_L1BankedDataWriteReq.io_out_bits_data_3[30] 未见过 0 和 1"); end
    if (!(adw_s0_io_out_bits_data_3[31] && adw_s1_io_out_bits_data_3[31])) begin cov_fail++; $display("[COV] Arbiter1_L1BankedDataWriteReq.io_out_bits_data_3[31] 未见过 0 和 1"); end
    if (!(adw_s0_io_out_bits_data_3[32] && adw_s1_io_out_bits_data_3[32])) begin cov_fail++; $display("[COV] Arbiter1_L1BankedDataWriteReq.io_out_bits_data_3[32] 未见过 0 和 1"); end
    if (!(adw_s0_io_out_bits_data_3[33] && adw_s1_io_out_bits_data_3[33])) begin cov_fail++; $display("[COV] Arbiter1_L1BankedDataWriteReq.io_out_bits_data_3[33] 未见过 0 和 1"); end
    if (!(adw_s0_io_out_bits_data_3[34] && adw_s1_io_out_bits_data_3[34])) begin cov_fail++; $display("[COV] Arbiter1_L1BankedDataWriteReq.io_out_bits_data_3[34] 未见过 0 和 1"); end
    if (!(adw_s0_io_out_bits_data_3[35] && adw_s1_io_out_bits_data_3[35])) begin cov_fail++; $display("[COV] Arbiter1_L1BankedDataWriteReq.io_out_bits_data_3[35] 未见过 0 和 1"); end
    if (!(adw_s0_io_out_bits_data_3[36] && adw_s1_io_out_bits_data_3[36])) begin cov_fail++; $display("[COV] Arbiter1_L1BankedDataWriteReq.io_out_bits_data_3[36] 未见过 0 和 1"); end
    if (!(adw_s0_io_out_bits_data_3[37] && adw_s1_io_out_bits_data_3[37])) begin cov_fail++; $display("[COV] Arbiter1_L1BankedDataWriteReq.io_out_bits_data_3[37] 未见过 0 和 1"); end
    if (!(adw_s0_io_out_bits_data_3[38] && adw_s1_io_out_bits_data_3[38])) begin cov_fail++; $display("[COV] Arbiter1_L1BankedDataWriteReq.io_out_bits_data_3[38] 未见过 0 和 1"); end
    if (!(adw_s0_io_out_bits_data_3[39] && adw_s1_io_out_bits_data_3[39])) begin cov_fail++; $display("[COV] Arbiter1_L1BankedDataWriteReq.io_out_bits_data_3[39] 未见过 0 和 1"); end
    if (!(adw_s0_io_out_bits_data_3[40] && adw_s1_io_out_bits_data_3[40])) begin cov_fail++; $display("[COV] Arbiter1_L1BankedDataWriteReq.io_out_bits_data_3[40] 未见过 0 和 1"); end
    if (!(adw_s0_io_out_bits_data_3[41] && adw_s1_io_out_bits_data_3[41])) begin cov_fail++; $display("[COV] Arbiter1_L1BankedDataWriteReq.io_out_bits_data_3[41] 未见过 0 和 1"); end
    if (!(adw_s0_io_out_bits_data_3[42] && adw_s1_io_out_bits_data_3[42])) begin cov_fail++; $display("[COV] Arbiter1_L1BankedDataWriteReq.io_out_bits_data_3[42] 未见过 0 和 1"); end
    if (!(adw_s0_io_out_bits_data_3[43] && adw_s1_io_out_bits_data_3[43])) begin cov_fail++; $display("[COV] Arbiter1_L1BankedDataWriteReq.io_out_bits_data_3[43] 未见过 0 和 1"); end
    if (!(adw_s0_io_out_bits_data_3[44] && adw_s1_io_out_bits_data_3[44])) begin cov_fail++; $display("[COV] Arbiter1_L1BankedDataWriteReq.io_out_bits_data_3[44] 未见过 0 和 1"); end
    if (!(adw_s0_io_out_bits_data_3[45] && adw_s1_io_out_bits_data_3[45])) begin cov_fail++; $display("[COV] Arbiter1_L1BankedDataWriteReq.io_out_bits_data_3[45] 未见过 0 和 1"); end
    if (!(adw_s0_io_out_bits_data_3[46] && adw_s1_io_out_bits_data_3[46])) begin cov_fail++; $display("[COV] Arbiter1_L1BankedDataWriteReq.io_out_bits_data_3[46] 未见过 0 和 1"); end
    if (!(adw_s0_io_out_bits_data_3[47] && adw_s1_io_out_bits_data_3[47])) begin cov_fail++; $display("[COV] Arbiter1_L1BankedDataWriteReq.io_out_bits_data_3[47] 未见过 0 和 1"); end
    if (!(adw_s0_io_out_bits_data_3[48] && adw_s1_io_out_bits_data_3[48])) begin cov_fail++; $display("[COV] Arbiter1_L1BankedDataWriteReq.io_out_bits_data_3[48] 未见过 0 和 1"); end
    if (!(adw_s0_io_out_bits_data_3[49] && adw_s1_io_out_bits_data_3[49])) begin cov_fail++; $display("[COV] Arbiter1_L1BankedDataWriteReq.io_out_bits_data_3[49] 未见过 0 和 1"); end
    if (!(adw_s0_io_out_bits_data_3[50] && adw_s1_io_out_bits_data_3[50])) begin cov_fail++; $display("[COV] Arbiter1_L1BankedDataWriteReq.io_out_bits_data_3[50] 未见过 0 和 1"); end
    if (!(adw_s0_io_out_bits_data_3[51] && adw_s1_io_out_bits_data_3[51])) begin cov_fail++; $display("[COV] Arbiter1_L1BankedDataWriteReq.io_out_bits_data_3[51] 未见过 0 和 1"); end
    if (!(adw_s0_io_out_bits_data_3[52] && adw_s1_io_out_bits_data_3[52])) begin cov_fail++; $display("[COV] Arbiter1_L1BankedDataWriteReq.io_out_bits_data_3[52] 未见过 0 和 1"); end
    if (!(adw_s0_io_out_bits_data_3[53] && adw_s1_io_out_bits_data_3[53])) begin cov_fail++; $display("[COV] Arbiter1_L1BankedDataWriteReq.io_out_bits_data_3[53] 未见过 0 和 1"); end
    if (!(adw_s0_io_out_bits_data_3[54] && adw_s1_io_out_bits_data_3[54])) begin cov_fail++; $display("[COV] Arbiter1_L1BankedDataWriteReq.io_out_bits_data_3[54] 未见过 0 和 1"); end
    if (!(adw_s0_io_out_bits_data_3[55] && adw_s1_io_out_bits_data_3[55])) begin cov_fail++; $display("[COV] Arbiter1_L1BankedDataWriteReq.io_out_bits_data_3[55] 未见过 0 和 1"); end
    if (!(adw_s0_io_out_bits_data_3[56] && adw_s1_io_out_bits_data_3[56])) begin cov_fail++; $display("[COV] Arbiter1_L1BankedDataWriteReq.io_out_bits_data_3[56] 未见过 0 和 1"); end
    if (!(adw_s0_io_out_bits_data_3[57] && adw_s1_io_out_bits_data_3[57])) begin cov_fail++; $display("[COV] Arbiter1_L1BankedDataWriteReq.io_out_bits_data_3[57] 未见过 0 和 1"); end
    if (!(adw_s0_io_out_bits_data_3[58] && adw_s1_io_out_bits_data_3[58])) begin cov_fail++; $display("[COV] Arbiter1_L1BankedDataWriteReq.io_out_bits_data_3[58] 未见过 0 和 1"); end
    if (!(adw_s0_io_out_bits_data_3[59] && adw_s1_io_out_bits_data_3[59])) begin cov_fail++; $display("[COV] Arbiter1_L1BankedDataWriteReq.io_out_bits_data_3[59] 未见过 0 和 1"); end
    if (!(adw_s0_io_out_bits_data_3[60] && adw_s1_io_out_bits_data_3[60])) begin cov_fail++; $display("[COV] Arbiter1_L1BankedDataWriteReq.io_out_bits_data_3[60] 未见过 0 和 1"); end
    if (!(adw_s0_io_out_bits_data_3[61] && adw_s1_io_out_bits_data_3[61])) begin cov_fail++; $display("[COV] Arbiter1_L1BankedDataWriteReq.io_out_bits_data_3[61] 未见过 0 和 1"); end
    if (!(adw_s0_io_out_bits_data_3[62] && adw_s1_io_out_bits_data_3[62])) begin cov_fail++; $display("[COV] Arbiter1_L1BankedDataWriteReq.io_out_bits_data_3[62] 未见过 0 和 1"); end
    if (!(adw_s0_io_out_bits_data_3[63] && adw_s1_io_out_bits_data_3[63])) begin cov_fail++; $display("[COV] Arbiter1_L1BankedDataWriteReq.io_out_bits_data_3[63] 未见过 0 和 1"); end
    if (!(adw_s0_io_out_bits_data_4[0] && adw_s1_io_out_bits_data_4[0])) begin cov_fail++; $display("[COV] Arbiter1_L1BankedDataWriteReq.io_out_bits_data_4[0] 未见过 0 和 1"); end
    if (!(adw_s0_io_out_bits_data_4[1] && adw_s1_io_out_bits_data_4[1])) begin cov_fail++; $display("[COV] Arbiter1_L1BankedDataWriteReq.io_out_bits_data_4[1] 未见过 0 和 1"); end
    if (!(adw_s0_io_out_bits_data_4[2] && adw_s1_io_out_bits_data_4[2])) begin cov_fail++; $display("[COV] Arbiter1_L1BankedDataWriteReq.io_out_bits_data_4[2] 未见过 0 和 1"); end
    if (!(adw_s0_io_out_bits_data_4[3] && adw_s1_io_out_bits_data_4[3])) begin cov_fail++; $display("[COV] Arbiter1_L1BankedDataWriteReq.io_out_bits_data_4[3] 未见过 0 和 1"); end
    if (!(adw_s0_io_out_bits_data_4[4] && adw_s1_io_out_bits_data_4[4])) begin cov_fail++; $display("[COV] Arbiter1_L1BankedDataWriteReq.io_out_bits_data_4[4] 未见过 0 和 1"); end
    if (!(adw_s0_io_out_bits_data_4[5] && adw_s1_io_out_bits_data_4[5])) begin cov_fail++; $display("[COV] Arbiter1_L1BankedDataWriteReq.io_out_bits_data_4[5] 未见过 0 和 1"); end
    if (!(adw_s0_io_out_bits_data_4[6] && adw_s1_io_out_bits_data_4[6])) begin cov_fail++; $display("[COV] Arbiter1_L1BankedDataWriteReq.io_out_bits_data_4[6] 未见过 0 和 1"); end
    if (!(adw_s0_io_out_bits_data_4[7] && adw_s1_io_out_bits_data_4[7])) begin cov_fail++; $display("[COV] Arbiter1_L1BankedDataWriteReq.io_out_bits_data_4[7] 未见过 0 和 1"); end
    if (!(adw_s0_io_out_bits_data_4[8] && adw_s1_io_out_bits_data_4[8])) begin cov_fail++; $display("[COV] Arbiter1_L1BankedDataWriteReq.io_out_bits_data_4[8] 未见过 0 和 1"); end
    if (!(adw_s0_io_out_bits_data_4[9] && adw_s1_io_out_bits_data_4[9])) begin cov_fail++; $display("[COV] Arbiter1_L1BankedDataWriteReq.io_out_bits_data_4[9] 未见过 0 和 1"); end
    if (!(adw_s0_io_out_bits_data_4[10] && adw_s1_io_out_bits_data_4[10])) begin cov_fail++; $display("[COV] Arbiter1_L1BankedDataWriteReq.io_out_bits_data_4[10] 未见过 0 和 1"); end
    if (!(adw_s0_io_out_bits_data_4[11] && adw_s1_io_out_bits_data_4[11])) begin cov_fail++; $display("[COV] Arbiter1_L1BankedDataWriteReq.io_out_bits_data_4[11] 未见过 0 和 1"); end
    if (!(adw_s0_io_out_bits_data_4[12] && adw_s1_io_out_bits_data_4[12])) begin cov_fail++; $display("[COV] Arbiter1_L1BankedDataWriteReq.io_out_bits_data_4[12] 未见过 0 和 1"); end
    if (!(adw_s0_io_out_bits_data_4[13] && adw_s1_io_out_bits_data_4[13])) begin cov_fail++; $display("[COV] Arbiter1_L1BankedDataWriteReq.io_out_bits_data_4[13] 未见过 0 和 1"); end
    if (!(adw_s0_io_out_bits_data_4[14] && adw_s1_io_out_bits_data_4[14])) begin cov_fail++; $display("[COV] Arbiter1_L1BankedDataWriteReq.io_out_bits_data_4[14] 未见过 0 和 1"); end
    if (!(adw_s0_io_out_bits_data_4[15] && adw_s1_io_out_bits_data_4[15])) begin cov_fail++; $display("[COV] Arbiter1_L1BankedDataWriteReq.io_out_bits_data_4[15] 未见过 0 和 1"); end
    if (!(adw_s0_io_out_bits_data_4[16] && adw_s1_io_out_bits_data_4[16])) begin cov_fail++; $display("[COV] Arbiter1_L1BankedDataWriteReq.io_out_bits_data_4[16] 未见过 0 和 1"); end
    if (!(adw_s0_io_out_bits_data_4[17] && adw_s1_io_out_bits_data_4[17])) begin cov_fail++; $display("[COV] Arbiter1_L1BankedDataWriteReq.io_out_bits_data_4[17] 未见过 0 和 1"); end
    if (!(adw_s0_io_out_bits_data_4[18] && adw_s1_io_out_bits_data_4[18])) begin cov_fail++; $display("[COV] Arbiter1_L1BankedDataWriteReq.io_out_bits_data_4[18] 未见过 0 和 1"); end
    if (!(adw_s0_io_out_bits_data_4[19] && adw_s1_io_out_bits_data_4[19])) begin cov_fail++; $display("[COV] Arbiter1_L1BankedDataWriteReq.io_out_bits_data_4[19] 未见过 0 和 1"); end
    if (!(adw_s0_io_out_bits_data_4[20] && adw_s1_io_out_bits_data_4[20])) begin cov_fail++; $display("[COV] Arbiter1_L1BankedDataWriteReq.io_out_bits_data_4[20] 未见过 0 和 1"); end
    if (!(adw_s0_io_out_bits_data_4[21] && adw_s1_io_out_bits_data_4[21])) begin cov_fail++; $display("[COV] Arbiter1_L1BankedDataWriteReq.io_out_bits_data_4[21] 未见过 0 和 1"); end
    if (!(adw_s0_io_out_bits_data_4[22] && adw_s1_io_out_bits_data_4[22])) begin cov_fail++; $display("[COV] Arbiter1_L1BankedDataWriteReq.io_out_bits_data_4[22] 未见过 0 和 1"); end
    if (!(adw_s0_io_out_bits_data_4[23] && adw_s1_io_out_bits_data_4[23])) begin cov_fail++; $display("[COV] Arbiter1_L1BankedDataWriteReq.io_out_bits_data_4[23] 未见过 0 和 1"); end
    if (!(adw_s0_io_out_bits_data_4[24] && adw_s1_io_out_bits_data_4[24])) begin cov_fail++; $display("[COV] Arbiter1_L1BankedDataWriteReq.io_out_bits_data_4[24] 未见过 0 和 1"); end
    if (!(adw_s0_io_out_bits_data_4[25] && adw_s1_io_out_bits_data_4[25])) begin cov_fail++; $display("[COV] Arbiter1_L1BankedDataWriteReq.io_out_bits_data_4[25] 未见过 0 和 1"); end
    if (!(adw_s0_io_out_bits_data_4[26] && adw_s1_io_out_bits_data_4[26])) begin cov_fail++; $display("[COV] Arbiter1_L1BankedDataWriteReq.io_out_bits_data_4[26] 未见过 0 和 1"); end
    if (!(adw_s0_io_out_bits_data_4[27] && adw_s1_io_out_bits_data_4[27])) begin cov_fail++; $display("[COV] Arbiter1_L1BankedDataWriteReq.io_out_bits_data_4[27] 未见过 0 和 1"); end
    if (!(adw_s0_io_out_bits_data_4[28] && adw_s1_io_out_bits_data_4[28])) begin cov_fail++; $display("[COV] Arbiter1_L1BankedDataWriteReq.io_out_bits_data_4[28] 未见过 0 和 1"); end
    if (!(adw_s0_io_out_bits_data_4[29] && adw_s1_io_out_bits_data_4[29])) begin cov_fail++; $display("[COV] Arbiter1_L1BankedDataWriteReq.io_out_bits_data_4[29] 未见过 0 和 1"); end
    if (!(adw_s0_io_out_bits_data_4[30] && adw_s1_io_out_bits_data_4[30])) begin cov_fail++; $display("[COV] Arbiter1_L1BankedDataWriteReq.io_out_bits_data_4[30] 未见过 0 和 1"); end
    if (!(adw_s0_io_out_bits_data_4[31] && adw_s1_io_out_bits_data_4[31])) begin cov_fail++; $display("[COV] Arbiter1_L1BankedDataWriteReq.io_out_bits_data_4[31] 未见过 0 和 1"); end
    if (!(adw_s0_io_out_bits_data_4[32] && adw_s1_io_out_bits_data_4[32])) begin cov_fail++; $display("[COV] Arbiter1_L1BankedDataWriteReq.io_out_bits_data_4[32] 未见过 0 和 1"); end
    if (!(adw_s0_io_out_bits_data_4[33] && adw_s1_io_out_bits_data_4[33])) begin cov_fail++; $display("[COV] Arbiter1_L1BankedDataWriteReq.io_out_bits_data_4[33] 未见过 0 和 1"); end
    if (!(adw_s0_io_out_bits_data_4[34] && adw_s1_io_out_bits_data_4[34])) begin cov_fail++; $display("[COV] Arbiter1_L1BankedDataWriteReq.io_out_bits_data_4[34] 未见过 0 和 1"); end
    if (!(adw_s0_io_out_bits_data_4[35] && adw_s1_io_out_bits_data_4[35])) begin cov_fail++; $display("[COV] Arbiter1_L1BankedDataWriteReq.io_out_bits_data_4[35] 未见过 0 和 1"); end
    if (!(adw_s0_io_out_bits_data_4[36] && adw_s1_io_out_bits_data_4[36])) begin cov_fail++; $display("[COV] Arbiter1_L1BankedDataWriteReq.io_out_bits_data_4[36] 未见过 0 和 1"); end
    if (!(adw_s0_io_out_bits_data_4[37] && adw_s1_io_out_bits_data_4[37])) begin cov_fail++; $display("[COV] Arbiter1_L1BankedDataWriteReq.io_out_bits_data_4[37] 未见过 0 和 1"); end
    if (!(adw_s0_io_out_bits_data_4[38] && adw_s1_io_out_bits_data_4[38])) begin cov_fail++; $display("[COV] Arbiter1_L1BankedDataWriteReq.io_out_bits_data_4[38] 未见过 0 和 1"); end
    if (!(adw_s0_io_out_bits_data_4[39] && adw_s1_io_out_bits_data_4[39])) begin cov_fail++; $display("[COV] Arbiter1_L1BankedDataWriteReq.io_out_bits_data_4[39] 未见过 0 和 1"); end
    if (!(adw_s0_io_out_bits_data_4[40] && adw_s1_io_out_bits_data_4[40])) begin cov_fail++; $display("[COV] Arbiter1_L1BankedDataWriteReq.io_out_bits_data_4[40] 未见过 0 和 1"); end
    if (!(adw_s0_io_out_bits_data_4[41] && adw_s1_io_out_bits_data_4[41])) begin cov_fail++; $display("[COV] Arbiter1_L1BankedDataWriteReq.io_out_bits_data_4[41] 未见过 0 和 1"); end
    if (!(adw_s0_io_out_bits_data_4[42] && adw_s1_io_out_bits_data_4[42])) begin cov_fail++; $display("[COV] Arbiter1_L1BankedDataWriteReq.io_out_bits_data_4[42] 未见过 0 和 1"); end
    if (!(adw_s0_io_out_bits_data_4[43] && adw_s1_io_out_bits_data_4[43])) begin cov_fail++; $display("[COV] Arbiter1_L1BankedDataWriteReq.io_out_bits_data_4[43] 未见过 0 和 1"); end
    if (!(adw_s0_io_out_bits_data_4[44] && adw_s1_io_out_bits_data_4[44])) begin cov_fail++; $display("[COV] Arbiter1_L1BankedDataWriteReq.io_out_bits_data_4[44] 未见过 0 和 1"); end
    if (!(adw_s0_io_out_bits_data_4[45] && adw_s1_io_out_bits_data_4[45])) begin cov_fail++; $display("[COV] Arbiter1_L1BankedDataWriteReq.io_out_bits_data_4[45] 未见过 0 和 1"); end
    if (!(adw_s0_io_out_bits_data_4[46] && adw_s1_io_out_bits_data_4[46])) begin cov_fail++; $display("[COV] Arbiter1_L1BankedDataWriteReq.io_out_bits_data_4[46] 未见过 0 和 1"); end
    if (!(adw_s0_io_out_bits_data_4[47] && adw_s1_io_out_bits_data_4[47])) begin cov_fail++; $display("[COV] Arbiter1_L1BankedDataWriteReq.io_out_bits_data_4[47] 未见过 0 和 1"); end
    if (!(adw_s0_io_out_bits_data_4[48] && adw_s1_io_out_bits_data_4[48])) begin cov_fail++; $display("[COV] Arbiter1_L1BankedDataWriteReq.io_out_bits_data_4[48] 未见过 0 和 1"); end
    if (!(adw_s0_io_out_bits_data_4[49] && adw_s1_io_out_bits_data_4[49])) begin cov_fail++; $display("[COV] Arbiter1_L1BankedDataWriteReq.io_out_bits_data_4[49] 未见过 0 和 1"); end
    if (!(adw_s0_io_out_bits_data_4[50] && adw_s1_io_out_bits_data_4[50])) begin cov_fail++; $display("[COV] Arbiter1_L1BankedDataWriteReq.io_out_bits_data_4[50] 未见过 0 和 1"); end
    if (!(adw_s0_io_out_bits_data_4[51] && adw_s1_io_out_bits_data_4[51])) begin cov_fail++; $display("[COV] Arbiter1_L1BankedDataWriteReq.io_out_bits_data_4[51] 未见过 0 和 1"); end
    if (!(adw_s0_io_out_bits_data_4[52] && adw_s1_io_out_bits_data_4[52])) begin cov_fail++; $display("[COV] Arbiter1_L1BankedDataWriteReq.io_out_bits_data_4[52] 未见过 0 和 1"); end
    if (!(adw_s0_io_out_bits_data_4[53] && adw_s1_io_out_bits_data_4[53])) begin cov_fail++; $display("[COV] Arbiter1_L1BankedDataWriteReq.io_out_bits_data_4[53] 未见过 0 和 1"); end
    if (!(adw_s0_io_out_bits_data_4[54] && adw_s1_io_out_bits_data_4[54])) begin cov_fail++; $display("[COV] Arbiter1_L1BankedDataWriteReq.io_out_bits_data_4[54] 未见过 0 和 1"); end
    if (!(adw_s0_io_out_bits_data_4[55] && adw_s1_io_out_bits_data_4[55])) begin cov_fail++; $display("[COV] Arbiter1_L1BankedDataWriteReq.io_out_bits_data_4[55] 未见过 0 和 1"); end
    if (!(adw_s0_io_out_bits_data_4[56] && adw_s1_io_out_bits_data_4[56])) begin cov_fail++; $display("[COV] Arbiter1_L1BankedDataWriteReq.io_out_bits_data_4[56] 未见过 0 和 1"); end
    if (!(adw_s0_io_out_bits_data_4[57] && adw_s1_io_out_bits_data_4[57])) begin cov_fail++; $display("[COV] Arbiter1_L1BankedDataWriteReq.io_out_bits_data_4[57] 未见过 0 和 1"); end
    if (!(adw_s0_io_out_bits_data_4[58] && adw_s1_io_out_bits_data_4[58])) begin cov_fail++; $display("[COV] Arbiter1_L1BankedDataWriteReq.io_out_bits_data_4[58] 未见过 0 和 1"); end
    if (!(adw_s0_io_out_bits_data_4[59] && adw_s1_io_out_bits_data_4[59])) begin cov_fail++; $display("[COV] Arbiter1_L1BankedDataWriteReq.io_out_bits_data_4[59] 未见过 0 和 1"); end
    if (!(adw_s0_io_out_bits_data_4[60] && adw_s1_io_out_bits_data_4[60])) begin cov_fail++; $display("[COV] Arbiter1_L1BankedDataWriteReq.io_out_bits_data_4[60] 未见过 0 和 1"); end
    if (!(adw_s0_io_out_bits_data_4[61] && adw_s1_io_out_bits_data_4[61])) begin cov_fail++; $display("[COV] Arbiter1_L1BankedDataWriteReq.io_out_bits_data_4[61] 未见过 0 和 1"); end
    if (!(adw_s0_io_out_bits_data_4[62] && adw_s1_io_out_bits_data_4[62])) begin cov_fail++; $display("[COV] Arbiter1_L1BankedDataWriteReq.io_out_bits_data_4[62] 未见过 0 和 1"); end
    if (!(adw_s0_io_out_bits_data_4[63] && adw_s1_io_out_bits_data_4[63])) begin cov_fail++; $display("[COV] Arbiter1_L1BankedDataWriteReq.io_out_bits_data_4[63] 未见过 0 和 1"); end
    if (!(adw_s0_io_out_bits_data_5[0] && adw_s1_io_out_bits_data_5[0])) begin cov_fail++; $display("[COV] Arbiter1_L1BankedDataWriteReq.io_out_bits_data_5[0] 未见过 0 和 1"); end
    if (!(adw_s0_io_out_bits_data_5[1] && adw_s1_io_out_bits_data_5[1])) begin cov_fail++; $display("[COV] Arbiter1_L1BankedDataWriteReq.io_out_bits_data_5[1] 未见过 0 和 1"); end
    if (!(adw_s0_io_out_bits_data_5[2] && adw_s1_io_out_bits_data_5[2])) begin cov_fail++; $display("[COV] Arbiter1_L1BankedDataWriteReq.io_out_bits_data_5[2] 未见过 0 和 1"); end
    if (!(adw_s0_io_out_bits_data_5[3] && adw_s1_io_out_bits_data_5[3])) begin cov_fail++; $display("[COV] Arbiter1_L1BankedDataWriteReq.io_out_bits_data_5[3] 未见过 0 和 1"); end
    if (!(adw_s0_io_out_bits_data_5[4] && adw_s1_io_out_bits_data_5[4])) begin cov_fail++; $display("[COV] Arbiter1_L1BankedDataWriteReq.io_out_bits_data_5[4] 未见过 0 和 1"); end
    if (!(adw_s0_io_out_bits_data_5[5] && adw_s1_io_out_bits_data_5[5])) begin cov_fail++; $display("[COV] Arbiter1_L1BankedDataWriteReq.io_out_bits_data_5[5] 未见过 0 和 1"); end
    if (!(adw_s0_io_out_bits_data_5[6] && adw_s1_io_out_bits_data_5[6])) begin cov_fail++; $display("[COV] Arbiter1_L1BankedDataWriteReq.io_out_bits_data_5[6] 未见过 0 和 1"); end
    if (!(adw_s0_io_out_bits_data_5[7] && adw_s1_io_out_bits_data_5[7])) begin cov_fail++; $display("[COV] Arbiter1_L1BankedDataWriteReq.io_out_bits_data_5[7] 未见过 0 和 1"); end
    if (!(adw_s0_io_out_bits_data_5[8] && adw_s1_io_out_bits_data_5[8])) begin cov_fail++; $display("[COV] Arbiter1_L1BankedDataWriteReq.io_out_bits_data_5[8] 未见过 0 和 1"); end
    if (!(adw_s0_io_out_bits_data_5[9] && adw_s1_io_out_bits_data_5[9])) begin cov_fail++; $display("[COV] Arbiter1_L1BankedDataWriteReq.io_out_bits_data_5[9] 未见过 0 和 1"); end
    if (!(adw_s0_io_out_bits_data_5[10] && adw_s1_io_out_bits_data_5[10])) begin cov_fail++; $display("[COV] Arbiter1_L1BankedDataWriteReq.io_out_bits_data_5[10] 未见过 0 和 1"); end
    if (!(adw_s0_io_out_bits_data_5[11] && adw_s1_io_out_bits_data_5[11])) begin cov_fail++; $display("[COV] Arbiter1_L1BankedDataWriteReq.io_out_bits_data_5[11] 未见过 0 和 1"); end
    if (!(adw_s0_io_out_bits_data_5[12] && adw_s1_io_out_bits_data_5[12])) begin cov_fail++; $display("[COV] Arbiter1_L1BankedDataWriteReq.io_out_bits_data_5[12] 未见过 0 和 1"); end
    if (!(adw_s0_io_out_bits_data_5[13] && adw_s1_io_out_bits_data_5[13])) begin cov_fail++; $display("[COV] Arbiter1_L1BankedDataWriteReq.io_out_bits_data_5[13] 未见过 0 和 1"); end
    if (!(adw_s0_io_out_bits_data_5[14] && adw_s1_io_out_bits_data_5[14])) begin cov_fail++; $display("[COV] Arbiter1_L1BankedDataWriteReq.io_out_bits_data_5[14] 未见过 0 和 1"); end
    if (!(adw_s0_io_out_bits_data_5[15] && adw_s1_io_out_bits_data_5[15])) begin cov_fail++; $display("[COV] Arbiter1_L1BankedDataWriteReq.io_out_bits_data_5[15] 未见过 0 和 1"); end
    if (!(adw_s0_io_out_bits_data_5[16] && adw_s1_io_out_bits_data_5[16])) begin cov_fail++; $display("[COV] Arbiter1_L1BankedDataWriteReq.io_out_bits_data_5[16] 未见过 0 和 1"); end
    if (!(adw_s0_io_out_bits_data_5[17] && adw_s1_io_out_bits_data_5[17])) begin cov_fail++; $display("[COV] Arbiter1_L1BankedDataWriteReq.io_out_bits_data_5[17] 未见过 0 和 1"); end
    if (!(adw_s0_io_out_bits_data_5[18] && adw_s1_io_out_bits_data_5[18])) begin cov_fail++; $display("[COV] Arbiter1_L1BankedDataWriteReq.io_out_bits_data_5[18] 未见过 0 和 1"); end
    if (!(adw_s0_io_out_bits_data_5[19] && adw_s1_io_out_bits_data_5[19])) begin cov_fail++; $display("[COV] Arbiter1_L1BankedDataWriteReq.io_out_bits_data_5[19] 未见过 0 和 1"); end
    if (!(adw_s0_io_out_bits_data_5[20] && adw_s1_io_out_bits_data_5[20])) begin cov_fail++; $display("[COV] Arbiter1_L1BankedDataWriteReq.io_out_bits_data_5[20] 未见过 0 和 1"); end
    if (!(adw_s0_io_out_bits_data_5[21] && adw_s1_io_out_bits_data_5[21])) begin cov_fail++; $display("[COV] Arbiter1_L1BankedDataWriteReq.io_out_bits_data_5[21] 未见过 0 和 1"); end
    if (!(adw_s0_io_out_bits_data_5[22] && adw_s1_io_out_bits_data_5[22])) begin cov_fail++; $display("[COV] Arbiter1_L1BankedDataWriteReq.io_out_bits_data_5[22] 未见过 0 和 1"); end
    if (!(adw_s0_io_out_bits_data_5[23] && adw_s1_io_out_bits_data_5[23])) begin cov_fail++; $display("[COV] Arbiter1_L1BankedDataWriteReq.io_out_bits_data_5[23] 未见过 0 和 1"); end
    if (!(adw_s0_io_out_bits_data_5[24] && adw_s1_io_out_bits_data_5[24])) begin cov_fail++; $display("[COV] Arbiter1_L1BankedDataWriteReq.io_out_bits_data_5[24] 未见过 0 和 1"); end
    if (!(adw_s0_io_out_bits_data_5[25] && adw_s1_io_out_bits_data_5[25])) begin cov_fail++; $display("[COV] Arbiter1_L1BankedDataWriteReq.io_out_bits_data_5[25] 未见过 0 和 1"); end
    if (!(adw_s0_io_out_bits_data_5[26] && adw_s1_io_out_bits_data_5[26])) begin cov_fail++; $display("[COV] Arbiter1_L1BankedDataWriteReq.io_out_bits_data_5[26] 未见过 0 和 1"); end
    if (!(adw_s0_io_out_bits_data_5[27] && adw_s1_io_out_bits_data_5[27])) begin cov_fail++; $display("[COV] Arbiter1_L1BankedDataWriteReq.io_out_bits_data_5[27] 未见过 0 和 1"); end
    if (!(adw_s0_io_out_bits_data_5[28] && adw_s1_io_out_bits_data_5[28])) begin cov_fail++; $display("[COV] Arbiter1_L1BankedDataWriteReq.io_out_bits_data_5[28] 未见过 0 和 1"); end
    if (!(adw_s0_io_out_bits_data_5[29] && adw_s1_io_out_bits_data_5[29])) begin cov_fail++; $display("[COV] Arbiter1_L1BankedDataWriteReq.io_out_bits_data_5[29] 未见过 0 和 1"); end
    if (!(adw_s0_io_out_bits_data_5[30] && adw_s1_io_out_bits_data_5[30])) begin cov_fail++; $display("[COV] Arbiter1_L1BankedDataWriteReq.io_out_bits_data_5[30] 未见过 0 和 1"); end
    if (!(adw_s0_io_out_bits_data_5[31] && adw_s1_io_out_bits_data_5[31])) begin cov_fail++; $display("[COV] Arbiter1_L1BankedDataWriteReq.io_out_bits_data_5[31] 未见过 0 和 1"); end
    if (!(adw_s0_io_out_bits_data_5[32] && adw_s1_io_out_bits_data_5[32])) begin cov_fail++; $display("[COV] Arbiter1_L1BankedDataWriteReq.io_out_bits_data_5[32] 未见过 0 和 1"); end
    if (!(adw_s0_io_out_bits_data_5[33] && adw_s1_io_out_bits_data_5[33])) begin cov_fail++; $display("[COV] Arbiter1_L1BankedDataWriteReq.io_out_bits_data_5[33] 未见过 0 和 1"); end
    if (!(adw_s0_io_out_bits_data_5[34] && adw_s1_io_out_bits_data_5[34])) begin cov_fail++; $display("[COV] Arbiter1_L1BankedDataWriteReq.io_out_bits_data_5[34] 未见过 0 和 1"); end
    if (!(adw_s0_io_out_bits_data_5[35] && adw_s1_io_out_bits_data_5[35])) begin cov_fail++; $display("[COV] Arbiter1_L1BankedDataWriteReq.io_out_bits_data_5[35] 未见过 0 和 1"); end
    if (!(adw_s0_io_out_bits_data_5[36] && adw_s1_io_out_bits_data_5[36])) begin cov_fail++; $display("[COV] Arbiter1_L1BankedDataWriteReq.io_out_bits_data_5[36] 未见过 0 和 1"); end
    if (!(adw_s0_io_out_bits_data_5[37] && adw_s1_io_out_bits_data_5[37])) begin cov_fail++; $display("[COV] Arbiter1_L1BankedDataWriteReq.io_out_bits_data_5[37] 未见过 0 和 1"); end
    if (!(adw_s0_io_out_bits_data_5[38] && adw_s1_io_out_bits_data_5[38])) begin cov_fail++; $display("[COV] Arbiter1_L1BankedDataWriteReq.io_out_bits_data_5[38] 未见过 0 和 1"); end
    if (!(adw_s0_io_out_bits_data_5[39] && adw_s1_io_out_bits_data_5[39])) begin cov_fail++; $display("[COV] Arbiter1_L1BankedDataWriteReq.io_out_bits_data_5[39] 未见过 0 和 1"); end
    if (!(adw_s0_io_out_bits_data_5[40] && adw_s1_io_out_bits_data_5[40])) begin cov_fail++; $display("[COV] Arbiter1_L1BankedDataWriteReq.io_out_bits_data_5[40] 未见过 0 和 1"); end
    if (!(adw_s0_io_out_bits_data_5[41] && adw_s1_io_out_bits_data_5[41])) begin cov_fail++; $display("[COV] Arbiter1_L1BankedDataWriteReq.io_out_bits_data_5[41] 未见过 0 和 1"); end
    if (!(adw_s0_io_out_bits_data_5[42] && adw_s1_io_out_bits_data_5[42])) begin cov_fail++; $display("[COV] Arbiter1_L1BankedDataWriteReq.io_out_bits_data_5[42] 未见过 0 和 1"); end
    if (!(adw_s0_io_out_bits_data_5[43] && adw_s1_io_out_bits_data_5[43])) begin cov_fail++; $display("[COV] Arbiter1_L1BankedDataWriteReq.io_out_bits_data_5[43] 未见过 0 和 1"); end
    if (!(adw_s0_io_out_bits_data_5[44] && adw_s1_io_out_bits_data_5[44])) begin cov_fail++; $display("[COV] Arbiter1_L1BankedDataWriteReq.io_out_bits_data_5[44] 未见过 0 和 1"); end
    if (!(adw_s0_io_out_bits_data_5[45] && adw_s1_io_out_bits_data_5[45])) begin cov_fail++; $display("[COV] Arbiter1_L1BankedDataWriteReq.io_out_bits_data_5[45] 未见过 0 和 1"); end
    if (!(adw_s0_io_out_bits_data_5[46] && adw_s1_io_out_bits_data_5[46])) begin cov_fail++; $display("[COV] Arbiter1_L1BankedDataWriteReq.io_out_bits_data_5[46] 未见过 0 和 1"); end
    if (!(adw_s0_io_out_bits_data_5[47] && adw_s1_io_out_bits_data_5[47])) begin cov_fail++; $display("[COV] Arbiter1_L1BankedDataWriteReq.io_out_bits_data_5[47] 未见过 0 和 1"); end
    if (!(adw_s0_io_out_bits_data_5[48] && adw_s1_io_out_bits_data_5[48])) begin cov_fail++; $display("[COV] Arbiter1_L1BankedDataWriteReq.io_out_bits_data_5[48] 未见过 0 和 1"); end
    if (!(adw_s0_io_out_bits_data_5[49] && adw_s1_io_out_bits_data_5[49])) begin cov_fail++; $display("[COV] Arbiter1_L1BankedDataWriteReq.io_out_bits_data_5[49] 未见过 0 和 1"); end
    if (!(adw_s0_io_out_bits_data_5[50] && adw_s1_io_out_bits_data_5[50])) begin cov_fail++; $display("[COV] Arbiter1_L1BankedDataWriteReq.io_out_bits_data_5[50] 未见过 0 和 1"); end
    if (!(adw_s0_io_out_bits_data_5[51] && adw_s1_io_out_bits_data_5[51])) begin cov_fail++; $display("[COV] Arbiter1_L1BankedDataWriteReq.io_out_bits_data_5[51] 未见过 0 和 1"); end
    if (!(adw_s0_io_out_bits_data_5[52] && adw_s1_io_out_bits_data_5[52])) begin cov_fail++; $display("[COV] Arbiter1_L1BankedDataWriteReq.io_out_bits_data_5[52] 未见过 0 和 1"); end
    if (!(adw_s0_io_out_bits_data_5[53] && adw_s1_io_out_bits_data_5[53])) begin cov_fail++; $display("[COV] Arbiter1_L1BankedDataWriteReq.io_out_bits_data_5[53] 未见过 0 和 1"); end
    if (!(adw_s0_io_out_bits_data_5[54] && adw_s1_io_out_bits_data_5[54])) begin cov_fail++; $display("[COV] Arbiter1_L1BankedDataWriteReq.io_out_bits_data_5[54] 未见过 0 和 1"); end
    if (!(adw_s0_io_out_bits_data_5[55] && adw_s1_io_out_bits_data_5[55])) begin cov_fail++; $display("[COV] Arbiter1_L1BankedDataWriteReq.io_out_bits_data_5[55] 未见过 0 和 1"); end
    if (!(adw_s0_io_out_bits_data_5[56] && adw_s1_io_out_bits_data_5[56])) begin cov_fail++; $display("[COV] Arbiter1_L1BankedDataWriteReq.io_out_bits_data_5[56] 未见过 0 和 1"); end
    if (!(adw_s0_io_out_bits_data_5[57] && adw_s1_io_out_bits_data_5[57])) begin cov_fail++; $display("[COV] Arbiter1_L1BankedDataWriteReq.io_out_bits_data_5[57] 未见过 0 和 1"); end
    if (!(adw_s0_io_out_bits_data_5[58] && adw_s1_io_out_bits_data_5[58])) begin cov_fail++; $display("[COV] Arbiter1_L1BankedDataWriteReq.io_out_bits_data_5[58] 未见过 0 和 1"); end
    if (!(adw_s0_io_out_bits_data_5[59] && adw_s1_io_out_bits_data_5[59])) begin cov_fail++; $display("[COV] Arbiter1_L1BankedDataWriteReq.io_out_bits_data_5[59] 未见过 0 和 1"); end
    if (!(adw_s0_io_out_bits_data_5[60] && adw_s1_io_out_bits_data_5[60])) begin cov_fail++; $display("[COV] Arbiter1_L1BankedDataWriteReq.io_out_bits_data_5[60] 未见过 0 和 1"); end
    if (!(adw_s0_io_out_bits_data_5[61] && adw_s1_io_out_bits_data_5[61])) begin cov_fail++; $display("[COV] Arbiter1_L1BankedDataWriteReq.io_out_bits_data_5[61] 未见过 0 和 1"); end
    if (!(adw_s0_io_out_bits_data_5[62] && adw_s1_io_out_bits_data_5[62])) begin cov_fail++; $display("[COV] Arbiter1_L1BankedDataWriteReq.io_out_bits_data_5[62] 未见过 0 和 1"); end
    if (!(adw_s0_io_out_bits_data_5[63] && adw_s1_io_out_bits_data_5[63])) begin cov_fail++; $display("[COV] Arbiter1_L1BankedDataWriteReq.io_out_bits_data_5[63] 未见过 0 和 1"); end
    if (!(adw_s0_io_out_bits_data_6[0] && adw_s1_io_out_bits_data_6[0])) begin cov_fail++; $display("[COV] Arbiter1_L1BankedDataWriteReq.io_out_bits_data_6[0] 未见过 0 和 1"); end
    if (!(adw_s0_io_out_bits_data_6[1] && adw_s1_io_out_bits_data_6[1])) begin cov_fail++; $display("[COV] Arbiter1_L1BankedDataWriteReq.io_out_bits_data_6[1] 未见过 0 和 1"); end
    if (!(adw_s0_io_out_bits_data_6[2] && adw_s1_io_out_bits_data_6[2])) begin cov_fail++; $display("[COV] Arbiter1_L1BankedDataWriteReq.io_out_bits_data_6[2] 未见过 0 和 1"); end
    if (!(adw_s0_io_out_bits_data_6[3] && adw_s1_io_out_bits_data_6[3])) begin cov_fail++; $display("[COV] Arbiter1_L1BankedDataWriteReq.io_out_bits_data_6[3] 未见过 0 和 1"); end
    if (!(adw_s0_io_out_bits_data_6[4] && adw_s1_io_out_bits_data_6[4])) begin cov_fail++; $display("[COV] Arbiter1_L1BankedDataWriteReq.io_out_bits_data_6[4] 未见过 0 和 1"); end
    if (!(adw_s0_io_out_bits_data_6[5] && adw_s1_io_out_bits_data_6[5])) begin cov_fail++; $display("[COV] Arbiter1_L1BankedDataWriteReq.io_out_bits_data_6[5] 未见过 0 和 1"); end
    if (!(adw_s0_io_out_bits_data_6[6] && adw_s1_io_out_bits_data_6[6])) begin cov_fail++; $display("[COV] Arbiter1_L1BankedDataWriteReq.io_out_bits_data_6[6] 未见过 0 和 1"); end
    if (!(adw_s0_io_out_bits_data_6[7] && adw_s1_io_out_bits_data_6[7])) begin cov_fail++; $display("[COV] Arbiter1_L1BankedDataWriteReq.io_out_bits_data_6[7] 未见过 0 和 1"); end
    if (!(adw_s0_io_out_bits_data_6[8] && adw_s1_io_out_bits_data_6[8])) begin cov_fail++; $display("[COV] Arbiter1_L1BankedDataWriteReq.io_out_bits_data_6[8] 未见过 0 和 1"); end
    if (!(adw_s0_io_out_bits_data_6[9] && adw_s1_io_out_bits_data_6[9])) begin cov_fail++; $display("[COV] Arbiter1_L1BankedDataWriteReq.io_out_bits_data_6[9] 未见过 0 和 1"); end
    if (!(adw_s0_io_out_bits_data_6[10] && adw_s1_io_out_bits_data_6[10])) begin cov_fail++; $display("[COV] Arbiter1_L1BankedDataWriteReq.io_out_bits_data_6[10] 未见过 0 和 1"); end
    if (!(adw_s0_io_out_bits_data_6[11] && adw_s1_io_out_bits_data_6[11])) begin cov_fail++; $display("[COV] Arbiter1_L1BankedDataWriteReq.io_out_bits_data_6[11] 未见过 0 和 1"); end
    if (!(adw_s0_io_out_bits_data_6[12] && adw_s1_io_out_bits_data_6[12])) begin cov_fail++; $display("[COV] Arbiter1_L1BankedDataWriteReq.io_out_bits_data_6[12] 未见过 0 和 1"); end
    if (!(adw_s0_io_out_bits_data_6[13] && adw_s1_io_out_bits_data_6[13])) begin cov_fail++; $display("[COV] Arbiter1_L1BankedDataWriteReq.io_out_bits_data_6[13] 未见过 0 和 1"); end
    if (!(adw_s0_io_out_bits_data_6[14] && adw_s1_io_out_bits_data_6[14])) begin cov_fail++; $display("[COV] Arbiter1_L1BankedDataWriteReq.io_out_bits_data_6[14] 未见过 0 和 1"); end
    if (!(adw_s0_io_out_bits_data_6[15] && adw_s1_io_out_bits_data_6[15])) begin cov_fail++; $display("[COV] Arbiter1_L1BankedDataWriteReq.io_out_bits_data_6[15] 未见过 0 和 1"); end
    if (!(adw_s0_io_out_bits_data_6[16] && adw_s1_io_out_bits_data_6[16])) begin cov_fail++; $display("[COV] Arbiter1_L1BankedDataWriteReq.io_out_bits_data_6[16] 未见过 0 和 1"); end
    if (!(adw_s0_io_out_bits_data_6[17] && adw_s1_io_out_bits_data_6[17])) begin cov_fail++; $display("[COV] Arbiter1_L1BankedDataWriteReq.io_out_bits_data_6[17] 未见过 0 和 1"); end
    if (!(adw_s0_io_out_bits_data_6[18] && adw_s1_io_out_bits_data_6[18])) begin cov_fail++; $display("[COV] Arbiter1_L1BankedDataWriteReq.io_out_bits_data_6[18] 未见过 0 和 1"); end
    if (!(adw_s0_io_out_bits_data_6[19] && adw_s1_io_out_bits_data_6[19])) begin cov_fail++; $display("[COV] Arbiter1_L1BankedDataWriteReq.io_out_bits_data_6[19] 未见过 0 和 1"); end
    if (!(adw_s0_io_out_bits_data_6[20] && adw_s1_io_out_bits_data_6[20])) begin cov_fail++; $display("[COV] Arbiter1_L1BankedDataWriteReq.io_out_bits_data_6[20] 未见过 0 和 1"); end
    if (!(adw_s0_io_out_bits_data_6[21] && adw_s1_io_out_bits_data_6[21])) begin cov_fail++; $display("[COV] Arbiter1_L1BankedDataWriteReq.io_out_bits_data_6[21] 未见过 0 和 1"); end
    if (!(adw_s0_io_out_bits_data_6[22] && adw_s1_io_out_bits_data_6[22])) begin cov_fail++; $display("[COV] Arbiter1_L1BankedDataWriteReq.io_out_bits_data_6[22] 未见过 0 和 1"); end
    if (!(adw_s0_io_out_bits_data_6[23] && adw_s1_io_out_bits_data_6[23])) begin cov_fail++; $display("[COV] Arbiter1_L1BankedDataWriteReq.io_out_bits_data_6[23] 未见过 0 和 1"); end
    if (!(adw_s0_io_out_bits_data_6[24] && adw_s1_io_out_bits_data_6[24])) begin cov_fail++; $display("[COV] Arbiter1_L1BankedDataWriteReq.io_out_bits_data_6[24] 未见过 0 和 1"); end
    if (!(adw_s0_io_out_bits_data_6[25] && adw_s1_io_out_bits_data_6[25])) begin cov_fail++; $display("[COV] Arbiter1_L1BankedDataWriteReq.io_out_bits_data_6[25] 未见过 0 和 1"); end
    if (!(adw_s0_io_out_bits_data_6[26] && adw_s1_io_out_bits_data_6[26])) begin cov_fail++; $display("[COV] Arbiter1_L1BankedDataWriteReq.io_out_bits_data_6[26] 未见过 0 和 1"); end
    if (!(adw_s0_io_out_bits_data_6[27] && adw_s1_io_out_bits_data_6[27])) begin cov_fail++; $display("[COV] Arbiter1_L1BankedDataWriteReq.io_out_bits_data_6[27] 未见过 0 和 1"); end
    if (!(adw_s0_io_out_bits_data_6[28] && adw_s1_io_out_bits_data_6[28])) begin cov_fail++; $display("[COV] Arbiter1_L1BankedDataWriteReq.io_out_bits_data_6[28] 未见过 0 和 1"); end
    if (!(adw_s0_io_out_bits_data_6[29] && adw_s1_io_out_bits_data_6[29])) begin cov_fail++; $display("[COV] Arbiter1_L1BankedDataWriteReq.io_out_bits_data_6[29] 未见过 0 和 1"); end
    if (!(adw_s0_io_out_bits_data_6[30] && adw_s1_io_out_bits_data_6[30])) begin cov_fail++; $display("[COV] Arbiter1_L1BankedDataWriteReq.io_out_bits_data_6[30] 未见过 0 和 1"); end
    if (!(adw_s0_io_out_bits_data_6[31] && adw_s1_io_out_bits_data_6[31])) begin cov_fail++; $display("[COV] Arbiter1_L1BankedDataWriteReq.io_out_bits_data_6[31] 未见过 0 和 1"); end
    if (!(adw_s0_io_out_bits_data_6[32] && adw_s1_io_out_bits_data_6[32])) begin cov_fail++; $display("[COV] Arbiter1_L1BankedDataWriteReq.io_out_bits_data_6[32] 未见过 0 和 1"); end
    if (!(adw_s0_io_out_bits_data_6[33] && adw_s1_io_out_bits_data_6[33])) begin cov_fail++; $display("[COV] Arbiter1_L1BankedDataWriteReq.io_out_bits_data_6[33] 未见过 0 和 1"); end
    if (!(adw_s0_io_out_bits_data_6[34] && adw_s1_io_out_bits_data_6[34])) begin cov_fail++; $display("[COV] Arbiter1_L1BankedDataWriteReq.io_out_bits_data_6[34] 未见过 0 和 1"); end
    if (!(adw_s0_io_out_bits_data_6[35] && adw_s1_io_out_bits_data_6[35])) begin cov_fail++; $display("[COV] Arbiter1_L1BankedDataWriteReq.io_out_bits_data_6[35] 未见过 0 和 1"); end
    if (!(adw_s0_io_out_bits_data_6[36] && adw_s1_io_out_bits_data_6[36])) begin cov_fail++; $display("[COV] Arbiter1_L1BankedDataWriteReq.io_out_bits_data_6[36] 未见过 0 和 1"); end
    if (!(adw_s0_io_out_bits_data_6[37] && adw_s1_io_out_bits_data_6[37])) begin cov_fail++; $display("[COV] Arbiter1_L1BankedDataWriteReq.io_out_bits_data_6[37] 未见过 0 和 1"); end
    if (!(adw_s0_io_out_bits_data_6[38] && adw_s1_io_out_bits_data_6[38])) begin cov_fail++; $display("[COV] Arbiter1_L1BankedDataWriteReq.io_out_bits_data_6[38] 未见过 0 和 1"); end
    if (!(adw_s0_io_out_bits_data_6[39] && adw_s1_io_out_bits_data_6[39])) begin cov_fail++; $display("[COV] Arbiter1_L1BankedDataWriteReq.io_out_bits_data_6[39] 未见过 0 和 1"); end
    if (!(adw_s0_io_out_bits_data_6[40] && adw_s1_io_out_bits_data_6[40])) begin cov_fail++; $display("[COV] Arbiter1_L1BankedDataWriteReq.io_out_bits_data_6[40] 未见过 0 和 1"); end
    if (!(adw_s0_io_out_bits_data_6[41] && adw_s1_io_out_bits_data_6[41])) begin cov_fail++; $display("[COV] Arbiter1_L1BankedDataWriteReq.io_out_bits_data_6[41] 未见过 0 和 1"); end
    if (!(adw_s0_io_out_bits_data_6[42] && adw_s1_io_out_bits_data_6[42])) begin cov_fail++; $display("[COV] Arbiter1_L1BankedDataWriteReq.io_out_bits_data_6[42] 未见过 0 和 1"); end
    if (!(adw_s0_io_out_bits_data_6[43] && adw_s1_io_out_bits_data_6[43])) begin cov_fail++; $display("[COV] Arbiter1_L1BankedDataWriteReq.io_out_bits_data_6[43] 未见过 0 和 1"); end
    if (!(adw_s0_io_out_bits_data_6[44] && adw_s1_io_out_bits_data_6[44])) begin cov_fail++; $display("[COV] Arbiter1_L1BankedDataWriteReq.io_out_bits_data_6[44] 未见过 0 和 1"); end
    if (!(adw_s0_io_out_bits_data_6[45] && adw_s1_io_out_bits_data_6[45])) begin cov_fail++; $display("[COV] Arbiter1_L1BankedDataWriteReq.io_out_bits_data_6[45] 未见过 0 和 1"); end
    if (!(adw_s0_io_out_bits_data_6[46] && adw_s1_io_out_bits_data_6[46])) begin cov_fail++; $display("[COV] Arbiter1_L1BankedDataWriteReq.io_out_bits_data_6[46] 未见过 0 和 1"); end
    if (!(adw_s0_io_out_bits_data_6[47] && adw_s1_io_out_bits_data_6[47])) begin cov_fail++; $display("[COV] Arbiter1_L1BankedDataWriteReq.io_out_bits_data_6[47] 未见过 0 和 1"); end
    if (!(adw_s0_io_out_bits_data_6[48] && adw_s1_io_out_bits_data_6[48])) begin cov_fail++; $display("[COV] Arbiter1_L1BankedDataWriteReq.io_out_bits_data_6[48] 未见过 0 和 1"); end
    if (!(adw_s0_io_out_bits_data_6[49] && adw_s1_io_out_bits_data_6[49])) begin cov_fail++; $display("[COV] Arbiter1_L1BankedDataWriteReq.io_out_bits_data_6[49] 未见过 0 和 1"); end
    if (!(adw_s0_io_out_bits_data_6[50] && adw_s1_io_out_bits_data_6[50])) begin cov_fail++; $display("[COV] Arbiter1_L1BankedDataWriteReq.io_out_bits_data_6[50] 未见过 0 和 1"); end
    if (!(adw_s0_io_out_bits_data_6[51] && adw_s1_io_out_bits_data_6[51])) begin cov_fail++; $display("[COV] Arbiter1_L1BankedDataWriteReq.io_out_bits_data_6[51] 未见过 0 和 1"); end
    if (!(adw_s0_io_out_bits_data_6[52] && adw_s1_io_out_bits_data_6[52])) begin cov_fail++; $display("[COV] Arbiter1_L1BankedDataWriteReq.io_out_bits_data_6[52] 未见过 0 和 1"); end
    if (!(adw_s0_io_out_bits_data_6[53] && adw_s1_io_out_bits_data_6[53])) begin cov_fail++; $display("[COV] Arbiter1_L1BankedDataWriteReq.io_out_bits_data_6[53] 未见过 0 和 1"); end
    if (!(adw_s0_io_out_bits_data_6[54] && adw_s1_io_out_bits_data_6[54])) begin cov_fail++; $display("[COV] Arbiter1_L1BankedDataWriteReq.io_out_bits_data_6[54] 未见过 0 和 1"); end
    if (!(adw_s0_io_out_bits_data_6[55] && adw_s1_io_out_bits_data_6[55])) begin cov_fail++; $display("[COV] Arbiter1_L1BankedDataWriteReq.io_out_bits_data_6[55] 未见过 0 和 1"); end
    if (!(adw_s0_io_out_bits_data_6[56] && adw_s1_io_out_bits_data_6[56])) begin cov_fail++; $display("[COV] Arbiter1_L1BankedDataWriteReq.io_out_bits_data_6[56] 未见过 0 和 1"); end
    if (!(adw_s0_io_out_bits_data_6[57] && adw_s1_io_out_bits_data_6[57])) begin cov_fail++; $display("[COV] Arbiter1_L1BankedDataWriteReq.io_out_bits_data_6[57] 未见过 0 和 1"); end
    if (!(adw_s0_io_out_bits_data_6[58] && adw_s1_io_out_bits_data_6[58])) begin cov_fail++; $display("[COV] Arbiter1_L1BankedDataWriteReq.io_out_bits_data_6[58] 未见过 0 和 1"); end
    if (!(adw_s0_io_out_bits_data_6[59] && adw_s1_io_out_bits_data_6[59])) begin cov_fail++; $display("[COV] Arbiter1_L1BankedDataWriteReq.io_out_bits_data_6[59] 未见过 0 和 1"); end
    if (!(adw_s0_io_out_bits_data_6[60] && adw_s1_io_out_bits_data_6[60])) begin cov_fail++; $display("[COV] Arbiter1_L1BankedDataWriteReq.io_out_bits_data_6[60] 未见过 0 和 1"); end
    if (!(adw_s0_io_out_bits_data_6[61] && adw_s1_io_out_bits_data_6[61])) begin cov_fail++; $display("[COV] Arbiter1_L1BankedDataWriteReq.io_out_bits_data_6[61] 未见过 0 和 1"); end
    if (!(adw_s0_io_out_bits_data_6[62] && adw_s1_io_out_bits_data_6[62])) begin cov_fail++; $display("[COV] Arbiter1_L1BankedDataWriteReq.io_out_bits_data_6[62] 未见过 0 和 1"); end
    if (!(adw_s0_io_out_bits_data_6[63] && adw_s1_io_out_bits_data_6[63])) begin cov_fail++; $display("[COV] Arbiter1_L1BankedDataWriteReq.io_out_bits_data_6[63] 未见过 0 和 1"); end
    if (!(adw_s0_io_out_bits_data_7[0] && adw_s1_io_out_bits_data_7[0])) begin cov_fail++; $display("[COV] Arbiter1_L1BankedDataWriteReq.io_out_bits_data_7[0] 未见过 0 和 1"); end
    if (!(adw_s0_io_out_bits_data_7[1] && adw_s1_io_out_bits_data_7[1])) begin cov_fail++; $display("[COV] Arbiter1_L1BankedDataWriteReq.io_out_bits_data_7[1] 未见过 0 和 1"); end
    if (!(adw_s0_io_out_bits_data_7[2] && adw_s1_io_out_bits_data_7[2])) begin cov_fail++; $display("[COV] Arbiter1_L1BankedDataWriteReq.io_out_bits_data_7[2] 未见过 0 和 1"); end
    if (!(adw_s0_io_out_bits_data_7[3] && adw_s1_io_out_bits_data_7[3])) begin cov_fail++; $display("[COV] Arbiter1_L1BankedDataWriteReq.io_out_bits_data_7[3] 未见过 0 和 1"); end
    if (!(adw_s0_io_out_bits_data_7[4] && adw_s1_io_out_bits_data_7[4])) begin cov_fail++; $display("[COV] Arbiter1_L1BankedDataWriteReq.io_out_bits_data_7[4] 未见过 0 和 1"); end
    if (!(adw_s0_io_out_bits_data_7[5] && adw_s1_io_out_bits_data_7[5])) begin cov_fail++; $display("[COV] Arbiter1_L1BankedDataWriteReq.io_out_bits_data_7[5] 未见过 0 和 1"); end
    if (!(adw_s0_io_out_bits_data_7[6] && adw_s1_io_out_bits_data_7[6])) begin cov_fail++; $display("[COV] Arbiter1_L1BankedDataWriteReq.io_out_bits_data_7[6] 未见过 0 和 1"); end
    if (!(adw_s0_io_out_bits_data_7[7] && adw_s1_io_out_bits_data_7[7])) begin cov_fail++; $display("[COV] Arbiter1_L1BankedDataWriteReq.io_out_bits_data_7[7] 未见过 0 和 1"); end
    if (!(adw_s0_io_out_bits_data_7[8] && adw_s1_io_out_bits_data_7[8])) begin cov_fail++; $display("[COV] Arbiter1_L1BankedDataWriteReq.io_out_bits_data_7[8] 未见过 0 和 1"); end
    if (!(adw_s0_io_out_bits_data_7[9] && adw_s1_io_out_bits_data_7[9])) begin cov_fail++; $display("[COV] Arbiter1_L1BankedDataWriteReq.io_out_bits_data_7[9] 未见过 0 和 1"); end
    if (!(adw_s0_io_out_bits_data_7[10] && adw_s1_io_out_bits_data_7[10])) begin cov_fail++; $display("[COV] Arbiter1_L1BankedDataWriteReq.io_out_bits_data_7[10] 未见过 0 和 1"); end
    if (!(adw_s0_io_out_bits_data_7[11] && adw_s1_io_out_bits_data_7[11])) begin cov_fail++; $display("[COV] Arbiter1_L1BankedDataWriteReq.io_out_bits_data_7[11] 未见过 0 和 1"); end
    if (!(adw_s0_io_out_bits_data_7[12] && adw_s1_io_out_bits_data_7[12])) begin cov_fail++; $display("[COV] Arbiter1_L1BankedDataWriteReq.io_out_bits_data_7[12] 未见过 0 和 1"); end
    if (!(adw_s0_io_out_bits_data_7[13] && adw_s1_io_out_bits_data_7[13])) begin cov_fail++; $display("[COV] Arbiter1_L1BankedDataWriteReq.io_out_bits_data_7[13] 未见过 0 和 1"); end
    if (!(adw_s0_io_out_bits_data_7[14] && adw_s1_io_out_bits_data_7[14])) begin cov_fail++; $display("[COV] Arbiter1_L1BankedDataWriteReq.io_out_bits_data_7[14] 未见过 0 和 1"); end
    if (!(adw_s0_io_out_bits_data_7[15] && adw_s1_io_out_bits_data_7[15])) begin cov_fail++; $display("[COV] Arbiter1_L1BankedDataWriteReq.io_out_bits_data_7[15] 未见过 0 和 1"); end
    if (!(adw_s0_io_out_bits_data_7[16] && adw_s1_io_out_bits_data_7[16])) begin cov_fail++; $display("[COV] Arbiter1_L1BankedDataWriteReq.io_out_bits_data_7[16] 未见过 0 和 1"); end
    if (!(adw_s0_io_out_bits_data_7[17] && adw_s1_io_out_bits_data_7[17])) begin cov_fail++; $display("[COV] Arbiter1_L1BankedDataWriteReq.io_out_bits_data_7[17] 未见过 0 和 1"); end
    if (!(adw_s0_io_out_bits_data_7[18] && adw_s1_io_out_bits_data_7[18])) begin cov_fail++; $display("[COV] Arbiter1_L1BankedDataWriteReq.io_out_bits_data_7[18] 未见过 0 和 1"); end
    if (!(adw_s0_io_out_bits_data_7[19] && adw_s1_io_out_bits_data_7[19])) begin cov_fail++; $display("[COV] Arbiter1_L1BankedDataWriteReq.io_out_bits_data_7[19] 未见过 0 和 1"); end
    if (!(adw_s0_io_out_bits_data_7[20] && adw_s1_io_out_bits_data_7[20])) begin cov_fail++; $display("[COV] Arbiter1_L1BankedDataWriteReq.io_out_bits_data_7[20] 未见过 0 和 1"); end
    if (!(adw_s0_io_out_bits_data_7[21] && adw_s1_io_out_bits_data_7[21])) begin cov_fail++; $display("[COV] Arbiter1_L1BankedDataWriteReq.io_out_bits_data_7[21] 未见过 0 和 1"); end
    if (!(adw_s0_io_out_bits_data_7[22] && adw_s1_io_out_bits_data_7[22])) begin cov_fail++; $display("[COV] Arbiter1_L1BankedDataWriteReq.io_out_bits_data_7[22] 未见过 0 和 1"); end
    if (!(adw_s0_io_out_bits_data_7[23] && adw_s1_io_out_bits_data_7[23])) begin cov_fail++; $display("[COV] Arbiter1_L1BankedDataWriteReq.io_out_bits_data_7[23] 未见过 0 和 1"); end
    if (!(adw_s0_io_out_bits_data_7[24] && adw_s1_io_out_bits_data_7[24])) begin cov_fail++; $display("[COV] Arbiter1_L1BankedDataWriteReq.io_out_bits_data_7[24] 未见过 0 和 1"); end
    if (!(adw_s0_io_out_bits_data_7[25] && adw_s1_io_out_bits_data_7[25])) begin cov_fail++; $display("[COV] Arbiter1_L1BankedDataWriteReq.io_out_bits_data_7[25] 未见过 0 和 1"); end
    if (!(adw_s0_io_out_bits_data_7[26] && adw_s1_io_out_bits_data_7[26])) begin cov_fail++; $display("[COV] Arbiter1_L1BankedDataWriteReq.io_out_bits_data_7[26] 未见过 0 和 1"); end
    if (!(adw_s0_io_out_bits_data_7[27] && adw_s1_io_out_bits_data_7[27])) begin cov_fail++; $display("[COV] Arbiter1_L1BankedDataWriteReq.io_out_bits_data_7[27] 未见过 0 和 1"); end
    if (!(adw_s0_io_out_bits_data_7[28] && adw_s1_io_out_bits_data_7[28])) begin cov_fail++; $display("[COV] Arbiter1_L1BankedDataWriteReq.io_out_bits_data_7[28] 未见过 0 和 1"); end
    if (!(adw_s0_io_out_bits_data_7[29] && adw_s1_io_out_bits_data_7[29])) begin cov_fail++; $display("[COV] Arbiter1_L1BankedDataWriteReq.io_out_bits_data_7[29] 未见过 0 和 1"); end
    if (!(adw_s0_io_out_bits_data_7[30] && adw_s1_io_out_bits_data_7[30])) begin cov_fail++; $display("[COV] Arbiter1_L1BankedDataWriteReq.io_out_bits_data_7[30] 未见过 0 和 1"); end
    if (!(adw_s0_io_out_bits_data_7[31] && adw_s1_io_out_bits_data_7[31])) begin cov_fail++; $display("[COV] Arbiter1_L1BankedDataWriteReq.io_out_bits_data_7[31] 未见过 0 和 1"); end
    if (!(adw_s0_io_out_bits_data_7[32] && adw_s1_io_out_bits_data_7[32])) begin cov_fail++; $display("[COV] Arbiter1_L1BankedDataWriteReq.io_out_bits_data_7[32] 未见过 0 和 1"); end
    if (!(adw_s0_io_out_bits_data_7[33] && adw_s1_io_out_bits_data_7[33])) begin cov_fail++; $display("[COV] Arbiter1_L1BankedDataWriteReq.io_out_bits_data_7[33] 未见过 0 和 1"); end
    if (!(adw_s0_io_out_bits_data_7[34] && adw_s1_io_out_bits_data_7[34])) begin cov_fail++; $display("[COV] Arbiter1_L1BankedDataWriteReq.io_out_bits_data_7[34] 未见过 0 和 1"); end
    if (!(adw_s0_io_out_bits_data_7[35] && adw_s1_io_out_bits_data_7[35])) begin cov_fail++; $display("[COV] Arbiter1_L1BankedDataWriteReq.io_out_bits_data_7[35] 未见过 0 和 1"); end
    if (!(adw_s0_io_out_bits_data_7[36] && adw_s1_io_out_bits_data_7[36])) begin cov_fail++; $display("[COV] Arbiter1_L1BankedDataWriteReq.io_out_bits_data_7[36] 未见过 0 和 1"); end
    if (!(adw_s0_io_out_bits_data_7[37] && adw_s1_io_out_bits_data_7[37])) begin cov_fail++; $display("[COV] Arbiter1_L1BankedDataWriteReq.io_out_bits_data_7[37] 未见过 0 和 1"); end
    if (!(adw_s0_io_out_bits_data_7[38] && adw_s1_io_out_bits_data_7[38])) begin cov_fail++; $display("[COV] Arbiter1_L1BankedDataWriteReq.io_out_bits_data_7[38] 未见过 0 和 1"); end
    if (!(adw_s0_io_out_bits_data_7[39] && adw_s1_io_out_bits_data_7[39])) begin cov_fail++; $display("[COV] Arbiter1_L1BankedDataWriteReq.io_out_bits_data_7[39] 未见过 0 和 1"); end
    if (!(adw_s0_io_out_bits_data_7[40] && adw_s1_io_out_bits_data_7[40])) begin cov_fail++; $display("[COV] Arbiter1_L1BankedDataWriteReq.io_out_bits_data_7[40] 未见过 0 和 1"); end
    if (!(adw_s0_io_out_bits_data_7[41] && adw_s1_io_out_bits_data_7[41])) begin cov_fail++; $display("[COV] Arbiter1_L1BankedDataWriteReq.io_out_bits_data_7[41] 未见过 0 和 1"); end
    if (!(adw_s0_io_out_bits_data_7[42] && adw_s1_io_out_bits_data_7[42])) begin cov_fail++; $display("[COV] Arbiter1_L1BankedDataWriteReq.io_out_bits_data_7[42] 未见过 0 和 1"); end
    if (!(adw_s0_io_out_bits_data_7[43] && adw_s1_io_out_bits_data_7[43])) begin cov_fail++; $display("[COV] Arbiter1_L1BankedDataWriteReq.io_out_bits_data_7[43] 未见过 0 和 1"); end
    if (!(adw_s0_io_out_bits_data_7[44] && adw_s1_io_out_bits_data_7[44])) begin cov_fail++; $display("[COV] Arbiter1_L1BankedDataWriteReq.io_out_bits_data_7[44] 未见过 0 和 1"); end
    if (!(adw_s0_io_out_bits_data_7[45] && adw_s1_io_out_bits_data_7[45])) begin cov_fail++; $display("[COV] Arbiter1_L1BankedDataWriteReq.io_out_bits_data_7[45] 未见过 0 和 1"); end
    if (!(adw_s0_io_out_bits_data_7[46] && adw_s1_io_out_bits_data_7[46])) begin cov_fail++; $display("[COV] Arbiter1_L1BankedDataWriteReq.io_out_bits_data_7[46] 未见过 0 和 1"); end
    if (!(adw_s0_io_out_bits_data_7[47] && adw_s1_io_out_bits_data_7[47])) begin cov_fail++; $display("[COV] Arbiter1_L1BankedDataWriteReq.io_out_bits_data_7[47] 未见过 0 和 1"); end
    if (!(adw_s0_io_out_bits_data_7[48] && adw_s1_io_out_bits_data_7[48])) begin cov_fail++; $display("[COV] Arbiter1_L1BankedDataWriteReq.io_out_bits_data_7[48] 未见过 0 和 1"); end
    if (!(adw_s0_io_out_bits_data_7[49] && adw_s1_io_out_bits_data_7[49])) begin cov_fail++; $display("[COV] Arbiter1_L1BankedDataWriteReq.io_out_bits_data_7[49] 未见过 0 和 1"); end
    if (!(adw_s0_io_out_bits_data_7[50] && adw_s1_io_out_bits_data_7[50])) begin cov_fail++; $display("[COV] Arbiter1_L1BankedDataWriteReq.io_out_bits_data_7[50] 未见过 0 和 1"); end
    if (!(adw_s0_io_out_bits_data_7[51] && adw_s1_io_out_bits_data_7[51])) begin cov_fail++; $display("[COV] Arbiter1_L1BankedDataWriteReq.io_out_bits_data_7[51] 未见过 0 和 1"); end
    if (!(adw_s0_io_out_bits_data_7[52] && adw_s1_io_out_bits_data_7[52])) begin cov_fail++; $display("[COV] Arbiter1_L1BankedDataWriteReq.io_out_bits_data_7[52] 未见过 0 和 1"); end
    if (!(adw_s0_io_out_bits_data_7[53] && adw_s1_io_out_bits_data_7[53])) begin cov_fail++; $display("[COV] Arbiter1_L1BankedDataWriteReq.io_out_bits_data_7[53] 未见过 0 和 1"); end
    if (!(adw_s0_io_out_bits_data_7[54] && adw_s1_io_out_bits_data_7[54])) begin cov_fail++; $display("[COV] Arbiter1_L1BankedDataWriteReq.io_out_bits_data_7[54] 未见过 0 和 1"); end
    if (!(adw_s0_io_out_bits_data_7[55] && adw_s1_io_out_bits_data_7[55])) begin cov_fail++; $display("[COV] Arbiter1_L1BankedDataWriteReq.io_out_bits_data_7[55] 未见过 0 和 1"); end
    if (!(adw_s0_io_out_bits_data_7[56] && adw_s1_io_out_bits_data_7[56])) begin cov_fail++; $display("[COV] Arbiter1_L1BankedDataWriteReq.io_out_bits_data_7[56] 未见过 0 和 1"); end
    if (!(adw_s0_io_out_bits_data_7[57] && adw_s1_io_out_bits_data_7[57])) begin cov_fail++; $display("[COV] Arbiter1_L1BankedDataWriteReq.io_out_bits_data_7[57] 未见过 0 和 1"); end
    if (!(adw_s0_io_out_bits_data_7[58] && adw_s1_io_out_bits_data_7[58])) begin cov_fail++; $display("[COV] Arbiter1_L1BankedDataWriteReq.io_out_bits_data_7[58] 未见过 0 和 1"); end
    if (!(adw_s0_io_out_bits_data_7[59] && adw_s1_io_out_bits_data_7[59])) begin cov_fail++; $display("[COV] Arbiter1_L1BankedDataWriteReq.io_out_bits_data_7[59] 未见过 0 和 1"); end
    if (!(adw_s0_io_out_bits_data_7[60] && adw_s1_io_out_bits_data_7[60])) begin cov_fail++; $display("[COV] Arbiter1_L1BankedDataWriteReq.io_out_bits_data_7[60] 未见过 0 和 1"); end
    if (!(adw_s0_io_out_bits_data_7[61] && adw_s1_io_out_bits_data_7[61])) begin cov_fail++; $display("[COV] Arbiter1_L1BankedDataWriteReq.io_out_bits_data_7[61] 未见过 0 和 1"); end
    if (!(adw_s0_io_out_bits_data_7[62] && adw_s1_io_out_bits_data_7[62])) begin cov_fail++; $display("[COV] Arbiter1_L1BankedDataWriteReq.io_out_bits_data_7[62] 未见过 0 和 1"); end
    if (!(adw_s0_io_out_bits_data_7[63] && adw_s1_io_out_bits_data_7[63])) begin cov_fail++; $display("[COV] Arbiter1_L1BankedDataWriteReq.io_out_bits_data_7[63] 未见过 0 和 1"); end
    $display("[ARM] Arbiter1_L1BankedDataWriteReq armed_at=%0d", adw_armed_at);
    if (adw_armed_at < 0) begin cov_fail++; $display("[ARM] Arbiter1_L1BankedDataWriteReq 从未 arm"); end
    if (!(adc_s0_io_out_valid && adc_s1_io_out_valid)) begin cov_fail++; $display("[COV] Arbiter1_L1BankedDataWriteReqCtrl.io_out_valid 未见过 0 和 1"); end
    if (!(adc_s0_io_out_bits_way_en[0] && adc_s1_io_out_bits_way_en[0])) begin cov_fail++; $display("[COV] Arbiter1_L1BankedDataWriteReqCtrl.io_out_bits_way_en[0] 未见过 0 和 1"); end
    if (!(adc_s0_io_out_bits_way_en[1] && adc_s1_io_out_bits_way_en[1])) begin cov_fail++; $display("[COV] Arbiter1_L1BankedDataWriteReqCtrl.io_out_bits_way_en[1] 未见过 0 和 1"); end
    if (!(adc_s0_io_out_bits_way_en[2] && adc_s1_io_out_bits_way_en[2])) begin cov_fail++; $display("[COV] Arbiter1_L1BankedDataWriteReqCtrl.io_out_bits_way_en[2] 未见过 0 和 1"); end
    if (!(adc_s0_io_out_bits_way_en[3] && adc_s1_io_out_bits_way_en[3])) begin cov_fail++; $display("[COV] Arbiter1_L1BankedDataWriteReqCtrl.io_out_bits_way_en[3] 未见过 0 和 1"); end
    if (!(adc_s0_io_out_bits_addr[0] && adc_s1_io_out_bits_addr[0])) begin cov_fail++; $display("[COV] Arbiter1_L1BankedDataWriteReqCtrl.io_out_bits_addr[0] 未见过 0 和 1"); end
    if (!(adc_s0_io_out_bits_addr[1] && adc_s1_io_out_bits_addr[1])) begin cov_fail++; $display("[COV] Arbiter1_L1BankedDataWriteReqCtrl.io_out_bits_addr[1] 未见过 0 和 1"); end
    if (!(adc_s0_io_out_bits_addr[2] && adc_s1_io_out_bits_addr[2])) begin cov_fail++; $display("[COV] Arbiter1_L1BankedDataWriteReqCtrl.io_out_bits_addr[2] 未见过 0 和 1"); end
    if (!(adc_s0_io_out_bits_addr[3] && adc_s1_io_out_bits_addr[3])) begin cov_fail++; $display("[COV] Arbiter1_L1BankedDataWriteReqCtrl.io_out_bits_addr[3] 未见过 0 和 1"); end
    if (!(adc_s0_io_out_bits_addr[4] && adc_s1_io_out_bits_addr[4])) begin cov_fail++; $display("[COV] Arbiter1_L1BankedDataWriteReqCtrl.io_out_bits_addr[4] 未见过 0 和 1"); end
    if (!(adc_s0_io_out_bits_addr[5] && adc_s1_io_out_bits_addr[5])) begin cov_fail++; $display("[COV] Arbiter1_L1BankedDataWriteReqCtrl.io_out_bits_addr[5] 未见过 0 和 1"); end
    if (!(adc_s0_io_out_bits_addr[6] && adc_s1_io_out_bits_addr[6])) begin cov_fail++; $display("[COV] Arbiter1_L1BankedDataWriteReqCtrl.io_out_bits_addr[6] 未见过 0 和 1"); end
    if (!(adc_s0_io_out_bits_addr[7] && adc_s1_io_out_bits_addr[7])) begin cov_fail++; $display("[COV] Arbiter1_L1BankedDataWriteReqCtrl.io_out_bits_addr[7] 未见过 0 和 1"); end
    if (!(adc_s0_io_out_bits_addr[8] && adc_s1_io_out_bits_addr[8])) begin cov_fail++; $display("[COV] Arbiter1_L1BankedDataWriteReqCtrl.io_out_bits_addr[8] 未见过 0 和 1"); end
    if (!(adc_s0_io_out_bits_addr[9] && adc_s1_io_out_bits_addr[9])) begin cov_fail++; $display("[COV] Arbiter1_L1BankedDataWriteReqCtrl.io_out_bits_addr[9] 未见过 0 和 1"); end
    if (!(adc_s0_io_out_bits_addr[10] && adc_s1_io_out_bits_addr[10])) begin cov_fail++; $display("[COV] Arbiter1_L1BankedDataWriteReqCtrl.io_out_bits_addr[10] 未见过 0 和 1"); end
    if (!(adc_s0_io_out_bits_addr[11] && adc_s1_io_out_bits_addr[11])) begin cov_fail++; $display("[COV] Arbiter1_L1BankedDataWriteReqCtrl.io_out_bits_addr[11] 未见过 0 和 1"); end
    if (!(adc_s0_io_out_bits_addr[12] && adc_s1_io_out_bits_addr[12])) begin cov_fail++; $display("[COV] Arbiter1_L1BankedDataWriteReqCtrl.io_out_bits_addr[12] 未见过 0 和 1"); end
    if (!(adc_s0_io_out_bits_addr[13] && adc_s1_io_out_bits_addr[13])) begin cov_fail++; $display("[COV] Arbiter1_L1BankedDataWriteReqCtrl.io_out_bits_addr[13] 未见过 0 和 1"); end
    if (!(adc_s0_io_out_bits_addr[14] && adc_s1_io_out_bits_addr[14])) begin cov_fail++; $display("[COV] Arbiter1_L1BankedDataWriteReqCtrl.io_out_bits_addr[14] 未见过 0 和 1"); end
    if (!(adc_s0_io_out_bits_addr[15] && adc_s1_io_out_bits_addr[15])) begin cov_fail++; $display("[COV] Arbiter1_L1BankedDataWriteReqCtrl.io_out_bits_addr[15] 未见过 0 和 1"); end
    if (!(adc_s0_io_out_bits_addr[16] && adc_s1_io_out_bits_addr[16])) begin cov_fail++; $display("[COV] Arbiter1_L1BankedDataWriteReqCtrl.io_out_bits_addr[16] 未见过 0 和 1"); end
    if (!(adc_s0_io_out_bits_addr[17] && adc_s1_io_out_bits_addr[17])) begin cov_fail++; $display("[COV] Arbiter1_L1BankedDataWriteReqCtrl.io_out_bits_addr[17] 未见过 0 和 1"); end
    if (!(adc_s0_io_out_bits_addr[18] && adc_s1_io_out_bits_addr[18])) begin cov_fail++; $display("[COV] Arbiter1_L1BankedDataWriteReqCtrl.io_out_bits_addr[18] 未见过 0 和 1"); end
    if (!(adc_s0_io_out_bits_addr[19] && adc_s1_io_out_bits_addr[19])) begin cov_fail++; $display("[COV] Arbiter1_L1BankedDataWriteReqCtrl.io_out_bits_addr[19] 未见过 0 和 1"); end
    if (!(adc_s0_io_out_bits_addr[20] && adc_s1_io_out_bits_addr[20])) begin cov_fail++; $display("[COV] Arbiter1_L1BankedDataWriteReqCtrl.io_out_bits_addr[20] 未见过 0 和 1"); end
    if (!(adc_s0_io_out_bits_addr[21] && adc_s1_io_out_bits_addr[21])) begin cov_fail++; $display("[COV] Arbiter1_L1BankedDataWriteReqCtrl.io_out_bits_addr[21] 未见过 0 和 1"); end
    if (!(adc_s0_io_out_bits_addr[22] && adc_s1_io_out_bits_addr[22])) begin cov_fail++; $display("[COV] Arbiter1_L1BankedDataWriteReqCtrl.io_out_bits_addr[22] 未见过 0 和 1"); end
    if (!(adc_s0_io_out_bits_addr[23] && adc_s1_io_out_bits_addr[23])) begin cov_fail++; $display("[COV] Arbiter1_L1BankedDataWriteReqCtrl.io_out_bits_addr[23] 未见过 0 和 1"); end
    if (!(adc_s0_io_out_bits_addr[24] && adc_s1_io_out_bits_addr[24])) begin cov_fail++; $display("[COV] Arbiter1_L1BankedDataWriteReqCtrl.io_out_bits_addr[24] 未见过 0 和 1"); end
    if (!(adc_s0_io_out_bits_addr[25] && adc_s1_io_out_bits_addr[25])) begin cov_fail++; $display("[COV] Arbiter1_L1BankedDataWriteReqCtrl.io_out_bits_addr[25] 未见过 0 和 1"); end
    if (!(adc_s0_io_out_bits_addr[26] && adc_s1_io_out_bits_addr[26])) begin cov_fail++; $display("[COV] Arbiter1_L1BankedDataWriteReqCtrl.io_out_bits_addr[26] 未见过 0 和 1"); end
    if (!(adc_s0_io_out_bits_addr[27] && adc_s1_io_out_bits_addr[27])) begin cov_fail++; $display("[COV] Arbiter1_L1BankedDataWriteReqCtrl.io_out_bits_addr[27] 未见过 0 和 1"); end
    if (!(adc_s0_io_out_bits_addr[28] && adc_s1_io_out_bits_addr[28])) begin cov_fail++; $display("[COV] Arbiter1_L1BankedDataWriteReqCtrl.io_out_bits_addr[28] 未见过 0 和 1"); end
    if (!(adc_s0_io_out_bits_addr[29] && adc_s1_io_out_bits_addr[29])) begin cov_fail++; $display("[COV] Arbiter1_L1BankedDataWriteReqCtrl.io_out_bits_addr[29] 未见过 0 和 1"); end
    if (!(adc_s0_io_out_bits_addr[30] && adc_s1_io_out_bits_addr[30])) begin cov_fail++; $display("[COV] Arbiter1_L1BankedDataWriteReqCtrl.io_out_bits_addr[30] 未见过 0 和 1"); end
    if (!(adc_s0_io_out_bits_addr[31] && adc_s1_io_out_bits_addr[31])) begin cov_fail++; $display("[COV] Arbiter1_L1BankedDataWriteReqCtrl.io_out_bits_addr[31] 未见过 0 和 1"); end
    if (!(adc_s0_io_out_bits_addr[32] && adc_s1_io_out_bits_addr[32])) begin cov_fail++; $display("[COV] Arbiter1_L1BankedDataWriteReqCtrl.io_out_bits_addr[32] 未见过 0 和 1"); end
    if (!(adc_s0_io_out_bits_addr[33] && adc_s1_io_out_bits_addr[33])) begin cov_fail++; $display("[COV] Arbiter1_L1BankedDataWriteReqCtrl.io_out_bits_addr[33] 未见过 0 和 1"); end
    if (!(adc_s0_io_out_bits_addr[34] && adc_s1_io_out_bits_addr[34])) begin cov_fail++; $display("[COV] Arbiter1_L1BankedDataWriteReqCtrl.io_out_bits_addr[34] 未见过 0 和 1"); end
    if (!(adc_s0_io_out_bits_addr[35] && adc_s1_io_out_bits_addr[35])) begin cov_fail++; $display("[COV] Arbiter1_L1BankedDataWriteReqCtrl.io_out_bits_addr[35] 未见过 0 和 1"); end
    if (!(adc_s0_io_out_bits_addr[36] && adc_s1_io_out_bits_addr[36])) begin cov_fail++; $display("[COV] Arbiter1_L1BankedDataWriteReqCtrl.io_out_bits_addr[36] 未见过 0 和 1"); end
    if (!(adc_s0_io_out_bits_addr[37] && adc_s1_io_out_bits_addr[37])) begin cov_fail++; $display("[COV] Arbiter1_L1BankedDataWriteReqCtrl.io_out_bits_addr[37] 未见过 0 和 1"); end
    if (!(adc_s0_io_out_bits_addr[38] && adc_s1_io_out_bits_addr[38])) begin cov_fail++; $display("[COV] Arbiter1_L1BankedDataWriteReqCtrl.io_out_bits_addr[38] 未见过 0 和 1"); end
    if (!(adc_s0_io_out_bits_addr[39] && adc_s1_io_out_bits_addr[39])) begin cov_fail++; $display("[COV] Arbiter1_L1BankedDataWriteReqCtrl.io_out_bits_addr[39] 未见过 0 和 1"); end
    if (!(adc_s0_io_out_bits_addr[40] && adc_s1_io_out_bits_addr[40])) begin cov_fail++; $display("[COV] Arbiter1_L1BankedDataWriteReqCtrl.io_out_bits_addr[40] 未见过 0 和 1"); end
    if (!(adc_s0_io_out_bits_addr[41] && adc_s1_io_out_bits_addr[41])) begin cov_fail++; $display("[COV] Arbiter1_L1BankedDataWriteReqCtrl.io_out_bits_addr[41] 未见过 0 和 1"); end
    if (!(adc_s0_io_out_bits_addr[42] && adc_s1_io_out_bits_addr[42])) begin cov_fail++; $display("[COV] Arbiter1_L1BankedDataWriteReqCtrl.io_out_bits_addr[42] 未见过 0 和 1"); end
    if (!(adc_s0_io_out_bits_addr[43] && adc_s1_io_out_bits_addr[43])) begin cov_fail++; $display("[COV] Arbiter1_L1BankedDataWriteReqCtrl.io_out_bits_addr[43] 未见过 0 和 1"); end
    if (!(adc_s0_io_out_bits_addr[44] && adc_s1_io_out_bits_addr[44])) begin cov_fail++; $display("[COV] Arbiter1_L1BankedDataWriteReqCtrl.io_out_bits_addr[44] 未见过 0 和 1"); end
    if (!(adc_s0_io_out_bits_addr[45] && adc_s1_io_out_bits_addr[45])) begin cov_fail++; $display("[COV] Arbiter1_L1BankedDataWriteReqCtrl.io_out_bits_addr[45] 未见过 0 和 1"); end
    if (!(adc_s0_io_out_bits_addr[46] && adc_s1_io_out_bits_addr[46])) begin cov_fail++; $display("[COV] Arbiter1_L1BankedDataWriteReqCtrl.io_out_bits_addr[46] 未见过 0 和 1"); end
    if (!(adc_s0_io_out_bits_addr[47] && adc_s1_io_out_bits_addr[47])) begin cov_fail++; $display("[COV] Arbiter1_L1BankedDataWriteReqCtrl.io_out_bits_addr[47] 未见过 0 和 1"); end
    $display("[ARM] Arbiter1_L1BankedDataWriteReqCtrl armed_at=%0d", adc_armed_at);
    if (adc_armed_at < 0) begin cov_fail++; $display("[ARM] Arbiter1_L1BankedDataWriteReqCtrl 从未 arm"); end
    if (!(tra_s0_io_in_0_ready && tra_s1_io_in_0_ready)) begin cov_fail++; $display("[COV] TreeArbiter.io_in_0_ready 未见过 0 和 1"); end
    if (!(tra_s0_io_in_1_ready && tra_s1_io_in_1_ready)) begin cov_fail++; $display("[COV] TreeArbiter.io_in_1_ready 未见过 0 和 1"); end
    if (!(tra_s0_io_in_2_ready && tra_s1_io_in_2_ready)) begin cov_fail++; $display("[COV] TreeArbiter.io_in_2_ready 未见过 0 和 1"); end
    if (!(tra_s0_io_in_3_ready && tra_s1_io_in_3_ready)) begin cov_fail++; $display("[COV] TreeArbiter.io_in_3_ready 未见过 0 和 1"); end
    if (!(tra_s0_io_out_valid && tra_s1_io_out_valid)) begin cov_fail++; $display("[COV] TreeArbiter.io_out_valid 未见过 0 和 1"); end
    if (!(tra_s0_io_out_bits_source[0] && tra_s1_io_out_bits_source[0])) begin cov_fail++; $display("[COV] TreeArbiter.io_out_bits_source[0] 未见过 0 和 1"); end
    if (!(tra_s0_io_out_bits_source[1] && tra_s1_io_out_bits_source[1])) begin cov_fail++; $display("[COV] TreeArbiter.io_out_bits_source[1] 未见过 0 和 1"); end
    if (!(tra_s0_io_out_bits_source[2] && tra_s1_io_out_bits_source[2])) begin cov_fail++; $display("[COV] TreeArbiter.io_out_bits_source[2] 未见过 0 和 1"); end
    if (!(tra_s0_io_out_bits_source[3] && tra_s1_io_out_bits_source[3])) begin cov_fail++; $display("[COV] TreeArbiter.io_out_bits_source[3] 未见过 0 和 1"); end
    if (!(tra_s0_io_out_bits_pf_source[0] && tra_s1_io_out_bits_pf_source[0])) begin cov_fail++; $display("[COV] TreeArbiter.io_out_bits_pf_source[0] 未见过 0 和 1"); end
    if (!(tra_s0_io_out_bits_pf_source[1] && tra_s1_io_out_bits_pf_source[1])) begin cov_fail++; $display("[COV] TreeArbiter.io_out_bits_pf_source[1] 未见过 0 和 1"); end
    if (!(tra_s0_io_out_bits_pf_source[2] && tra_s1_io_out_bits_pf_source[2])) begin cov_fail++; $display("[COV] TreeArbiter.io_out_bits_pf_source[2] 未见过 0 和 1"); end
    if (!(tra_s0_io_out_bits_cmd[0] && tra_s1_io_out_bits_cmd[0])) begin cov_fail++; $display("[COV] TreeArbiter.io_out_bits_cmd[0] 未见过 0 和 1"); end
    if (!(tra_s0_io_out_bits_cmd[1] && tra_s1_io_out_bits_cmd[1])) begin cov_fail++; $display("[COV] TreeArbiter.io_out_bits_cmd[1] 未见过 0 和 1"); end
    if (!(tra_s0_io_out_bits_cmd[2] && tra_s1_io_out_bits_cmd[2])) begin cov_fail++; $display("[COV] TreeArbiter.io_out_bits_cmd[2] 未见过 0 和 1"); end
    if (!(tra_s0_io_out_bits_cmd[3] && tra_s1_io_out_bits_cmd[3])) begin cov_fail++; $display("[COV] TreeArbiter.io_out_bits_cmd[3] 未见过 0 和 1"); end
    if (!(tra_s0_io_out_bits_cmd[4] && tra_s1_io_out_bits_cmd[4])) begin cov_fail++; $display("[COV] TreeArbiter.io_out_bits_cmd[4] 未见过 0 和 1"); end
    if (!(tra_s0_io_out_bits_addr[0] && tra_s1_io_out_bits_addr[0])) begin cov_fail++; $display("[COV] TreeArbiter.io_out_bits_addr[0] 未见过 0 和 1"); end
    if (!(tra_s0_io_out_bits_addr[1] && tra_s1_io_out_bits_addr[1])) begin cov_fail++; $display("[COV] TreeArbiter.io_out_bits_addr[1] 未见过 0 和 1"); end
    if (!(tra_s0_io_out_bits_addr[2] && tra_s1_io_out_bits_addr[2])) begin cov_fail++; $display("[COV] TreeArbiter.io_out_bits_addr[2] 未见过 0 和 1"); end
    if (!(tra_s0_io_out_bits_addr[3] && tra_s1_io_out_bits_addr[3])) begin cov_fail++; $display("[COV] TreeArbiter.io_out_bits_addr[3] 未见过 0 和 1"); end
    if (!(tra_s0_io_out_bits_addr[4] && tra_s1_io_out_bits_addr[4])) begin cov_fail++; $display("[COV] TreeArbiter.io_out_bits_addr[4] 未见过 0 和 1"); end
    if (!(tra_s0_io_out_bits_addr[5] && tra_s1_io_out_bits_addr[5])) begin cov_fail++; $display("[COV] TreeArbiter.io_out_bits_addr[5] 未见过 0 和 1"); end
    if (!(tra_s0_io_out_bits_addr[6] && tra_s1_io_out_bits_addr[6])) begin cov_fail++; $display("[COV] TreeArbiter.io_out_bits_addr[6] 未见过 0 和 1"); end
    if (!(tra_s0_io_out_bits_addr[7] && tra_s1_io_out_bits_addr[7])) begin cov_fail++; $display("[COV] TreeArbiter.io_out_bits_addr[7] 未见过 0 和 1"); end
    if (!(tra_s0_io_out_bits_addr[8] && tra_s1_io_out_bits_addr[8])) begin cov_fail++; $display("[COV] TreeArbiter.io_out_bits_addr[8] 未见过 0 和 1"); end
    if (!(tra_s0_io_out_bits_addr[9] && tra_s1_io_out_bits_addr[9])) begin cov_fail++; $display("[COV] TreeArbiter.io_out_bits_addr[9] 未见过 0 和 1"); end
    if (!(tra_s0_io_out_bits_addr[10] && tra_s1_io_out_bits_addr[10])) begin cov_fail++; $display("[COV] TreeArbiter.io_out_bits_addr[10] 未见过 0 和 1"); end
    if (!(tra_s0_io_out_bits_addr[11] && tra_s1_io_out_bits_addr[11])) begin cov_fail++; $display("[COV] TreeArbiter.io_out_bits_addr[11] 未见过 0 和 1"); end
    if (!(tra_s0_io_out_bits_addr[12] && tra_s1_io_out_bits_addr[12])) begin cov_fail++; $display("[COV] TreeArbiter.io_out_bits_addr[12] 未见过 0 和 1"); end
    if (!(tra_s0_io_out_bits_addr[13] && tra_s1_io_out_bits_addr[13])) begin cov_fail++; $display("[COV] TreeArbiter.io_out_bits_addr[13] 未见过 0 和 1"); end
    if (!(tra_s0_io_out_bits_addr[14] && tra_s1_io_out_bits_addr[14])) begin cov_fail++; $display("[COV] TreeArbiter.io_out_bits_addr[14] 未见过 0 和 1"); end
    if (!(tra_s0_io_out_bits_addr[15] && tra_s1_io_out_bits_addr[15])) begin cov_fail++; $display("[COV] TreeArbiter.io_out_bits_addr[15] 未见过 0 和 1"); end
    if (!(tra_s0_io_out_bits_addr[16] && tra_s1_io_out_bits_addr[16])) begin cov_fail++; $display("[COV] TreeArbiter.io_out_bits_addr[16] 未见过 0 和 1"); end
    if (!(tra_s0_io_out_bits_addr[17] && tra_s1_io_out_bits_addr[17])) begin cov_fail++; $display("[COV] TreeArbiter.io_out_bits_addr[17] 未见过 0 和 1"); end
    if (!(tra_s0_io_out_bits_addr[18] && tra_s1_io_out_bits_addr[18])) begin cov_fail++; $display("[COV] TreeArbiter.io_out_bits_addr[18] 未见过 0 和 1"); end
    if (!(tra_s0_io_out_bits_addr[19] && tra_s1_io_out_bits_addr[19])) begin cov_fail++; $display("[COV] TreeArbiter.io_out_bits_addr[19] 未见过 0 和 1"); end
    if (!(tra_s0_io_out_bits_addr[20] && tra_s1_io_out_bits_addr[20])) begin cov_fail++; $display("[COV] TreeArbiter.io_out_bits_addr[20] 未见过 0 和 1"); end
    if (!(tra_s0_io_out_bits_addr[21] && tra_s1_io_out_bits_addr[21])) begin cov_fail++; $display("[COV] TreeArbiter.io_out_bits_addr[21] 未见过 0 和 1"); end
    if (!(tra_s0_io_out_bits_addr[22] && tra_s1_io_out_bits_addr[22])) begin cov_fail++; $display("[COV] TreeArbiter.io_out_bits_addr[22] 未见过 0 和 1"); end
    if (!(tra_s0_io_out_bits_addr[23] && tra_s1_io_out_bits_addr[23])) begin cov_fail++; $display("[COV] TreeArbiter.io_out_bits_addr[23] 未见过 0 和 1"); end
    if (!(tra_s0_io_out_bits_addr[24] && tra_s1_io_out_bits_addr[24])) begin cov_fail++; $display("[COV] TreeArbiter.io_out_bits_addr[24] 未见过 0 和 1"); end
    if (!(tra_s0_io_out_bits_addr[25] && tra_s1_io_out_bits_addr[25])) begin cov_fail++; $display("[COV] TreeArbiter.io_out_bits_addr[25] 未见过 0 和 1"); end
    if (!(tra_s0_io_out_bits_addr[26] && tra_s1_io_out_bits_addr[26])) begin cov_fail++; $display("[COV] TreeArbiter.io_out_bits_addr[26] 未见过 0 和 1"); end
    if (!(tra_s0_io_out_bits_addr[27] && tra_s1_io_out_bits_addr[27])) begin cov_fail++; $display("[COV] TreeArbiter.io_out_bits_addr[27] 未见过 0 和 1"); end
    if (!(tra_s0_io_out_bits_addr[28] && tra_s1_io_out_bits_addr[28])) begin cov_fail++; $display("[COV] TreeArbiter.io_out_bits_addr[28] 未见过 0 和 1"); end
    if (!(tra_s0_io_out_bits_addr[29] && tra_s1_io_out_bits_addr[29])) begin cov_fail++; $display("[COV] TreeArbiter.io_out_bits_addr[29] 未见过 0 和 1"); end
    if (!(tra_s0_io_out_bits_addr[30] && tra_s1_io_out_bits_addr[30])) begin cov_fail++; $display("[COV] TreeArbiter.io_out_bits_addr[30] 未见过 0 和 1"); end
    if (!(tra_s0_io_out_bits_addr[31] && tra_s1_io_out_bits_addr[31])) begin cov_fail++; $display("[COV] TreeArbiter.io_out_bits_addr[31] 未见过 0 和 1"); end
    if (!(tra_s0_io_out_bits_addr[32] && tra_s1_io_out_bits_addr[32])) begin cov_fail++; $display("[COV] TreeArbiter.io_out_bits_addr[32] 未见过 0 和 1"); end
    if (!(tra_s0_io_out_bits_addr[33] && tra_s1_io_out_bits_addr[33])) begin cov_fail++; $display("[COV] TreeArbiter.io_out_bits_addr[33] 未见过 0 和 1"); end
    if (!(tra_s0_io_out_bits_addr[34] && tra_s1_io_out_bits_addr[34])) begin cov_fail++; $display("[COV] TreeArbiter.io_out_bits_addr[34] 未见过 0 和 1"); end
    if (!(tra_s0_io_out_bits_addr[35] && tra_s1_io_out_bits_addr[35])) begin cov_fail++; $display("[COV] TreeArbiter.io_out_bits_addr[35] 未见过 0 和 1"); end
    if (!(tra_s0_io_out_bits_addr[36] && tra_s1_io_out_bits_addr[36])) begin cov_fail++; $display("[COV] TreeArbiter.io_out_bits_addr[36] 未见过 0 和 1"); end
    if (!(tra_s0_io_out_bits_addr[37] && tra_s1_io_out_bits_addr[37])) begin cov_fail++; $display("[COV] TreeArbiter.io_out_bits_addr[37] 未见过 0 和 1"); end
    if (!(tra_s0_io_out_bits_addr[38] && tra_s1_io_out_bits_addr[38])) begin cov_fail++; $display("[COV] TreeArbiter.io_out_bits_addr[38] 未见过 0 和 1"); end
    if (!(tra_s0_io_out_bits_addr[39] && tra_s1_io_out_bits_addr[39])) begin cov_fail++; $display("[COV] TreeArbiter.io_out_bits_addr[39] 未见过 0 和 1"); end
    if (!(tra_s0_io_out_bits_addr[40] && tra_s1_io_out_bits_addr[40])) begin cov_fail++; $display("[COV] TreeArbiter.io_out_bits_addr[40] 未见过 0 和 1"); end
    if (!(tra_s0_io_out_bits_addr[41] && tra_s1_io_out_bits_addr[41])) begin cov_fail++; $display("[COV] TreeArbiter.io_out_bits_addr[41] 未见过 0 和 1"); end
    if (!(tra_s0_io_out_bits_addr[42] && tra_s1_io_out_bits_addr[42])) begin cov_fail++; $display("[COV] TreeArbiter.io_out_bits_addr[42] 未见过 0 和 1"); end
    if (!(tra_s0_io_out_bits_addr[43] && tra_s1_io_out_bits_addr[43])) begin cov_fail++; $display("[COV] TreeArbiter.io_out_bits_addr[43] 未见过 0 和 1"); end
    if (!(tra_s0_io_out_bits_addr[44] && tra_s1_io_out_bits_addr[44])) begin cov_fail++; $display("[COV] TreeArbiter.io_out_bits_addr[44] 未见过 0 和 1"); end
    if (!(tra_s0_io_out_bits_addr[45] && tra_s1_io_out_bits_addr[45])) begin cov_fail++; $display("[COV] TreeArbiter.io_out_bits_addr[45] 未见过 0 和 1"); end
    if (!(tra_s0_io_out_bits_addr[46] && tra_s1_io_out_bits_addr[46])) begin cov_fail++; $display("[COV] TreeArbiter.io_out_bits_addr[46] 未见过 0 和 1"); end
    if (!(tra_s0_io_out_bits_addr[47] && tra_s1_io_out_bits_addr[47])) begin cov_fail++; $display("[COV] TreeArbiter.io_out_bits_addr[47] 未见过 0 和 1"); end
    if (!(tra_s0_io_out_bits_vaddr[0] && tra_s1_io_out_bits_vaddr[0])) begin cov_fail++; $display("[COV] TreeArbiter.io_out_bits_vaddr[0] 未见过 0 和 1"); end
    if (!(tra_s0_io_out_bits_vaddr[1] && tra_s1_io_out_bits_vaddr[1])) begin cov_fail++; $display("[COV] TreeArbiter.io_out_bits_vaddr[1] 未见过 0 和 1"); end
    if (!(tra_s0_io_out_bits_vaddr[2] && tra_s1_io_out_bits_vaddr[2])) begin cov_fail++; $display("[COV] TreeArbiter.io_out_bits_vaddr[2] 未见过 0 和 1"); end
    if (!(tra_s0_io_out_bits_vaddr[3] && tra_s1_io_out_bits_vaddr[3])) begin cov_fail++; $display("[COV] TreeArbiter.io_out_bits_vaddr[3] 未见过 0 和 1"); end
    if (!(tra_s0_io_out_bits_vaddr[4] && tra_s1_io_out_bits_vaddr[4])) begin cov_fail++; $display("[COV] TreeArbiter.io_out_bits_vaddr[4] 未见过 0 和 1"); end
    if (!(tra_s0_io_out_bits_vaddr[5] && tra_s1_io_out_bits_vaddr[5])) begin cov_fail++; $display("[COV] TreeArbiter.io_out_bits_vaddr[5] 未见过 0 和 1"); end
    if (!(tra_s0_io_out_bits_vaddr[6] && tra_s1_io_out_bits_vaddr[6])) begin cov_fail++; $display("[COV] TreeArbiter.io_out_bits_vaddr[6] 未见过 0 和 1"); end
    if (!(tra_s0_io_out_bits_vaddr[7] && tra_s1_io_out_bits_vaddr[7])) begin cov_fail++; $display("[COV] TreeArbiter.io_out_bits_vaddr[7] 未见过 0 和 1"); end
    if (!(tra_s0_io_out_bits_vaddr[8] && tra_s1_io_out_bits_vaddr[8])) begin cov_fail++; $display("[COV] TreeArbiter.io_out_bits_vaddr[8] 未见过 0 和 1"); end
    if (!(tra_s0_io_out_bits_vaddr[9] && tra_s1_io_out_bits_vaddr[9])) begin cov_fail++; $display("[COV] TreeArbiter.io_out_bits_vaddr[9] 未见过 0 和 1"); end
    if (!(tra_s0_io_out_bits_vaddr[10] && tra_s1_io_out_bits_vaddr[10])) begin cov_fail++; $display("[COV] TreeArbiter.io_out_bits_vaddr[10] 未见过 0 和 1"); end
    if (!(tra_s0_io_out_bits_vaddr[11] && tra_s1_io_out_bits_vaddr[11])) begin cov_fail++; $display("[COV] TreeArbiter.io_out_bits_vaddr[11] 未见过 0 和 1"); end
    if (!(tra_s0_io_out_bits_vaddr[12] && tra_s1_io_out_bits_vaddr[12])) begin cov_fail++; $display("[COV] TreeArbiter.io_out_bits_vaddr[12] 未见过 0 和 1"); end
    if (!(tra_s0_io_out_bits_vaddr[13] && tra_s1_io_out_bits_vaddr[13])) begin cov_fail++; $display("[COV] TreeArbiter.io_out_bits_vaddr[13] 未见过 0 和 1"); end
    if (!(tra_s0_io_out_bits_vaddr[14] && tra_s1_io_out_bits_vaddr[14])) begin cov_fail++; $display("[COV] TreeArbiter.io_out_bits_vaddr[14] 未见过 0 和 1"); end
    if (!(tra_s0_io_out_bits_vaddr[15] && tra_s1_io_out_bits_vaddr[15])) begin cov_fail++; $display("[COV] TreeArbiter.io_out_bits_vaddr[15] 未见过 0 和 1"); end
    if (!(tra_s0_io_out_bits_vaddr[16] && tra_s1_io_out_bits_vaddr[16])) begin cov_fail++; $display("[COV] TreeArbiter.io_out_bits_vaddr[16] 未见过 0 和 1"); end
    if (!(tra_s0_io_out_bits_vaddr[17] && tra_s1_io_out_bits_vaddr[17])) begin cov_fail++; $display("[COV] TreeArbiter.io_out_bits_vaddr[17] 未见过 0 和 1"); end
    if (!(tra_s0_io_out_bits_vaddr[18] && tra_s1_io_out_bits_vaddr[18])) begin cov_fail++; $display("[COV] TreeArbiter.io_out_bits_vaddr[18] 未见过 0 和 1"); end
    if (!(tra_s0_io_out_bits_vaddr[19] && tra_s1_io_out_bits_vaddr[19])) begin cov_fail++; $display("[COV] TreeArbiter.io_out_bits_vaddr[19] 未见过 0 和 1"); end
    if (!(tra_s0_io_out_bits_vaddr[20] && tra_s1_io_out_bits_vaddr[20])) begin cov_fail++; $display("[COV] TreeArbiter.io_out_bits_vaddr[20] 未见过 0 和 1"); end
    if (!(tra_s0_io_out_bits_vaddr[21] && tra_s1_io_out_bits_vaddr[21])) begin cov_fail++; $display("[COV] TreeArbiter.io_out_bits_vaddr[21] 未见过 0 和 1"); end
    if (!(tra_s0_io_out_bits_vaddr[22] && tra_s1_io_out_bits_vaddr[22])) begin cov_fail++; $display("[COV] TreeArbiter.io_out_bits_vaddr[22] 未见过 0 和 1"); end
    if (!(tra_s0_io_out_bits_vaddr[23] && tra_s1_io_out_bits_vaddr[23])) begin cov_fail++; $display("[COV] TreeArbiter.io_out_bits_vaddr[23] 未见过 0 和 1"); end
    if (!(tra_s0_io_out_bits_vaddr[24] && tra_s1_io_out_bits_vaddr[24])) begin cov_fail++; $display("[COV] TreeArbiter.io_out_bits_vaddr[24] 未见过 0 和 1"); end
    if (!(tra_s0_io_out_bits_vaddr[25] && tra_s1_io_out_bits_vaddr[25])) begin cov_fail++; $display("[COV] TreeArbiter.io_out_bits_vaddr[25] 未见过 0 和 1"); end
    if (!(tra_s0_io_out_bits_vaddr[26] && tra_s1_io_out_bits_vaddr[26])) begin cov_fail++; $display("[COV] TreeArbiter.io_out_bits_vaddr[26] 未见过 0 和 1"); end
    if (!(tra_s0_io_out_bits_vaddr[27] && tra_s1_io_out_bits_vaddr[27])) begin cov_fail++; $display("[COV] TreeArbiter.io_out_bits_vaddr[27] 未见过 0 和 1"); end
    if (!(tra_s0_io_out_bits_vaddr[28] && tra_s1_io_out_bits_vaddr[28])) begin cov_fail++; $display("[COV] TreeArbiter.io_out_bits_vaddr[28] 未见过 0 和 1"); end
    if (!(tra_s0_io_out_bits_vaddr[29] && tra_s1_io_out_bits_vaddr[29])) begin cov_fail++; $display("[COV] TreeArbiter.io_out_bits_vaddr[29] 未见过 0 和 1"); end
    if (!(tra_s0_io_out_bits_vaddr[30] && tra_s1_io_out_bits_vaddr[30])) begin cov_fail++; $display("[COV] TreeArbiter.io_out_bits_vaddr[30] 未见过 0 和 1"); end
    if (!(tra_s0_io_out_bits_vaddr[31] && tra_s1_io_out_bits_vaddr[31])) begin cov_fail++; $display("[COV] TreeArbiter.io_out_bits_vaddr[31] 未见过 0 和 1"); end
    if (!(tra_s0_io_out_bits_vaddr[32] && tra_s1_io_out_bits_vaddr[32])) begin cov_fail++; $display("[COV] TreeArbiter.io_out_bits_vaddr[32] 未见过 0 和 1"); end
    if (!(tra_s0_io_out_bits_vaddr[33] && tra_s1_io_out_bits_vaddr[33])) begin cov_fail++; $display("[COV] TreeArbiter.io_out_bits_vaddr[33] 未见过 0 和 1"); end
    if (!(tra_s0_io_out_bits_vaddr[34] && tra_s1_io_out_bits_vaddr[34])) begin cov_fail++; $display("[COV] TreeArbiter.io_out_bits_vaddr[34] 未见过 0 和 1"); end
    if (!(tra_s0_io_out_bits_vaddr[35] && tra_s1_io_out_bits_vaddr[35])) begin cov_fail++; $display("[COV] TreeArbiter.io_out_bits_vaddr[35] 未见过 0 和 1"); end
    if (!(tra_s0_io_out_bits_vaddr[36] && tra_s1_io_out_bits_vaddr[36])) begin cov_fail++; $display("[COV] TreeArbiter.io_out_bits_vaddr[36] 未见过 0 和 1"); end
    if (!(tra_s0_io_out_bits_vaddr[37] && tra_s1_io_out_bits_vaddr[37])) begin cov_fail++; $display("[COV] TreeArbiter.io_out_bits_vaddr[37] 未见过 0 和 1"); end
    if (!(tra_s0_io_out_bits_vaddr[38] && tra_s1_io_out_bits_vaddr[38])) begin cov_fail++; $display("[COV] TreeArbiter.io_out_bits_vaddr[38] 未见过 0 和 1"); end
    if (!(tra_s0_io_out_bits_vaddr[39] && tra_s1_io_out_bits_vaddr[39])) begin cov_fail++; $display("[COV] TreeArbiter.io_out_bits_vaddr[39] 未见过 0 和 1"); end
    if (!(tra_s0_io_out_bits_vaddr[40] && tra_s1_io_out_bits_vaddr[40])) begin cov_fail++; $display("[COV] TreeArbiter.io_out_bits_vaddr[40] 未见过 0 和 1"); end
    if (!(tra_s0_io_out_bits_vaddr[41] && tra_s1_io_out_bits_vaddr[41])) begin cov_fail++; $display("[COV] TreeArbiter.io_out_bits_vaddr[41] 未见过 0 和 1"); end
    if (!(tra_s0_io_out_bits_vaddr[42] && tra_s1_io_out_bits_vaddr[42])) begin cov_fail++; $display("[COV] TreeArbiter.io_out_bits_vaddr[42] 未见过 0 和 1"); end
    if (!(tra_s0_io_out_bits_vaddr[43] && tra_s1_io_out_bits_vaddr[43])) begin cov_fail++; $display("[COV] TreeArbiter.io_out_bits_vaddr[43] 未见过 0 和 1"); end
    if (!(tra_s0_io_out_bits_vaddr[44] && tra_s1_io_out_bits_vaddr[44])) begin cov_fail++; $display("[COV] TreeArbiter.io_out_bits_vaddr[44] 未见过 0 和 1"); end
    if (!(tra_s0_io_out_bits_vaddr[45] && tra_s1_io_out_bits_vaddr[45])) begin cov_fail++; $display("[COV] TreeArbiter.io_out_bits_vaddr[45] 未见过 0 和 1"); end
    if (!(tra_s0_io_out_bits_vaddr[46] && tra_s1_io_out_bits_vaddr[46])) begin cov_fail++; $display("[COV] TreeArbiter.io_out_bits_vaddr[46] 未见过 0 和 1"); end
    if (!(tra_s0_io_out_bits_vaddr[47] && tra_s1_io_out_bits_vaddr[47])) begin cov_fail++; $display("[COV] TreeArbiter.io_out_bits_vaddr[47] 未见过 0 和 1"); end
    if (!(tra_s0_io_out_bits_vaddr[48] && tra_s1_io_out_bits_vaddr[48])) begin cov_fail++; $display("[COV] TreeArbiter.io_out_bits_vaddr[48] 未见过 0 和 1"); end
    if (!(tra_s0_io_out_bits_vaddr[49] && tra_s1_io_out_bits_vaddr[49])) begin cov_fail++; $display("[COV] TreeArbiter.io_out_bits_vaddr[49] 未见过 0 和 1"); end
    if (!(tra_s0_io_out_bits_full_overwrite && tra_s1_io_out_bits_full_overwrite)) begin cov_fail++; $display("[COV] TreeArbiter.io_out_bits_full_overwrite 未见过 0 和 1"); end
    if (!(tra_s0_io_out_bits_word_idx[0] && tra_s1_io_out_bits_word_idx[0])) begin cov_fail++; $display("[COV] TreeArbiter.io_out_bits_word_idx[0] 未见过 0 和 1"); end
    if (!(tra_s0_io_out_bits_word_idx[1] && tra_s1_io_out_bits_word_idx[1])) begin cov_fail++; $display("[COV] TreeArbiter.io_out_bits_word_idx[1] 未见过 0 和 1"); end
    if (!(tra_s0_io_out_bits_word_idx[2] && tra_s1_io_out_bits_word_idx[2])) begin cov_fail++; $display("[COV] TreeArbiter.io_out_bits_word_idx[2] 未见过 0 和 1"); end
    if (!(tra_s0_io_out_bits_amo_data[0] && tra_s1_io_out_bits_amo_data[0])) begin cov_fail++; $display("[COV] TreeArbiter.io_out_bits_amo_data[0] 未见过 0 和 1"); end
    if (!(tra_s0_io_out_bits_amo_data[1] && tra_s1_io_out_bits_amo_data[1])) begin cov_fail++; $display("[COV] TreeArbiter.io_out_bits_amo_data[1] 未见过 0 和 1"); end
    if (!(tra_s0_io_out_bits_amo_data[2] && tra_s1_io_out_bits_amo_data[2])) begin cov_fail++; $display("[COV] TreeArbiter.io_out_bits_amo_data[2] 未见过 0 和 1"); end
    if (!(tra_s0_io_out_bits_amo_data[3] && tra_s1_io_out_bits_amo_data[3])) begin cov_fail++; $display("[COV] TreeArbiter.io_out_bits_amo_data[3] 未见过 0 和 1"); end
    if (!(tra_s0_io_out_bits_amo_data[4] && tra_s1_io_out_bits_amo_data[4])) begin cov_fail++; $display("[COV] TreeArbiter.io_out_bits_amo_data[4] 未见过 0 和 1"); end
    if (!(tra_s0_io_out_bits_amo_data[5] && tra_s1_io_out_bits_amo_data[5])) begin cov_fail++; $display("[COV] TreeArbiter.io_out_bits_amo_data[5] 未见过 0 和 1"); end
    if (!(tra_s0_io_out_bits_amo_data[6] && tra_s1_io_out_bits_amo_data[6])) begin cov_fail++; $display("[COV] TreeArbiter.io_out_bits_amo_data[6] 未见过 0 和 1"); end
    if (!(tra_s0_io_out_bits_amo_data[7] && tra_s1_io_out_bits_amo_data[7])) begin cov_fail++; $display("[COV] TreeArbiter.io_out_bits_amo_data[7] 未见过 0 和 1"); end
    if (!(tra_s0_io_out_bits_amo_data[8] && tra_s1_io_out_bits_amo_data[8])) begin cov_fail++; $display("[COV] TreeArbiter.io_out_bits_amo_data[8] 未见过 0 和 1"); end
    if (!(tra_s0_io_out_bits_amo_data[9] && tra_s1_io_out_bits_amo_data[9])) begin cov_fail++; $display("[COV] TreeArbiter.io_out_bits_amo_data[9] 未见过 0 和 1"); end
    if (!(tra_s0_io_out_bits_amo_data[10] && tra_s1_io_out_bits_amo_data[10])) begin cov_fail++; $display("[COV] TreeArbiter.io_out_bits_amo_data[10] 未见过 0 和 1"); end
    if (!(tra_s0_io_out_bits_amo_data[11] && tra_s1_io_out_bits_amo_data[11])) begin cov_fail++; $display("[COV] TreeArbiter.io_out_bits_amo_data[11] 未见过 0 和 1"); end
    if (!(tra_s0_io_out_bits_amo_data[12] && tra_s1_io_out_bits_amo_data[12])) begin cov_fail++; $display("[COV] TreeArbiter.io_out_bits_amo_data[12] 未见过 0 和 1"); end
    if (!(tra_s0_io_out_bits_amo_data[13] && tra_s1_io_out_bits_amo_data[13])) begin cov_fail++; $display("[COV] TreeArbiter.io_out_bits_amo_data[13] 未见过 0 和 1"); end
    if (!(tra_s0_io_out_bits_amo_data[14] && tra_s1_io_out_bits_amo_data[14])) begin cov_fail++; $display("[COV] TreeArbiter.io_out_bits_amo_data[14] 未见过 0 和 1"); end
    if (!(tra_s0_io_out_bits_amo_data[15] && tra_s1_io_out_bits_amo_data[15])) begin cov_fail++; $display("[COV] TreeArbiter.io_out_bits_amo_data[15] 未见过 0 和 1"); end
    if (!(tra_s0_io_out_bits_amo_data[16] && tra_s1_io_out_bits_amo_data[16])) begin cov_fail++; $display("[COV] TreeArbiter.io_out_bits_amo_data[16] 未见过 0 和 1"); end
    if (!(tra_s0_io_out_bits_amo_data[17] && tra_s1_io_out_bits_amo_data[17])) begin cov_fail++; $display("[COV] TreeArbiter.io_out_bits_amo_data[17] 未见过 0 和 1"); end
    if (!(tra_s0_io_out_bits_amo_data[18] && tra_s1_io_out_bits_amo_data[18])) begin cov_fail++; $display("[COV] TreeArbiter.io_out_bits_amo_data[18] 未见过 0 和 1"); end
    if (!(tra_s0_io_out_bits_amo_data[19] && tra_s1_io_out_bits_amo_data[19])) begin cov_fail++; $display("[COV] TreeArbiter.io_out_bits_amo_data[19] 未见过 0 和 1"); end
    if (!(tra_s0_io_out_bits_amo_data[20] && tra_s1_io_out_bits_amo_data[20])) begin cov_fail++; $display("[COV] TreeArbiter.io_out_bits_amo_data[20] 未见过 0 和 1"); end
    if (!(tra_s0_io_out_bits_amo_data[21] && tra_s1_io_out_bits_amo_data[21])) begin cov_fail++; $display("[COV] TreeArbiter.io_out_bits_amo_data[21] 未见过 0 和 1"); end
    if (!(tra_s0_io_out_bits_amo_data[22] && tra_s1_io_out_bits_amo_data[22])) begin cov_fail++; $display("[COV] TreeArbiter.io_out_bits_amo_data[22] 未见过 0 和 1"); end
    if (!(tra_s0_io_out_bits_amo_data[23] && tra_s1_io_out_bits_amo_data[23])) begin cov_fail++; $display("[COV] TreeArbiter.io_out_bits_amo_data[23] 未见过 0 和 1"); end
    if (!(tra_s0_io_out_bits_amo_data[24] && tra_s1_io_out_bits_amo_data[24])) begin cov_fail++; $display("[COV] TreeArbiter.io_out_bits_amo_data[24] 未见过 0 和 1"); end
    if (!(tra_s0_io_out_bits_amo_data[25] && tra_s1_io_out_bits_amo_data[25])) begin cov_fail++; $display("[COV] TreeArbiter.io_out_bits_amo_data[25] 未见过 0 和 1"); end
    if (!(tra_s0_io_out_bits_amo_data[26] && tra_s1_io_out_bits_amo_data[26])) begin cov_fail++; $display("[COV] TreeArbiter.io_out_bits_amo_data[26] 未见过 0 和 1"); end
    if (!(tra_s0_io_out_bits_amo_data[27] && tra_s1_io_out_bits_amo_data[27])) begin cov_fail++; $display("[COV] TreeArbiter.io_out_bits_amo_data[27] 未见过 0 和 1"); end
    if (!(tra_s0_io_out_bits_amo_data[28] && tra_s1_io_out_bits_amo_data[28])) begin cov_fail++; $display("[COV] TreeArbiter.io_out_bits_amo_data[28] 未见过 0 和 1"); end
    if (!(tra_s0_io_out_bits_amo_data[29] && tra_s1_io_out_bits_amo_data[29])) begin cov_fail++; $display("[COV] TreeArbiter.io_out_bits_amo_data[29] 未见过 0 和 1"); end
    if (!(tra_s0_io_out_bits_amo_data[30] && tra_s1_io_out_bits_amo_data[30])) begin cov_fail++; $display("[COV] TreeArbiter.io_out_bits_amo_data[30] 未见过 0 和 1"); end
    if (!(tra_s0_io_out_bits_amo_data[31] && tra_s1_io_out_bits_amo_data[31])) begin cov_fail++; $display("[COV] TreeArbiter.io_out_bits_amo_data[31] 未见过 0 和 1"); end
    if (!(tra_s0_io_out_bits_amo_data[32] && tra_s1_io_out_bits_amo_data[32])) begin cov_fail++; $display("[COV] TreeArbiter.io_out_bits_amo_data[32] 未见过 0 和 1"); end
    if (!(tra_s0_io_out_bits_amo_data[33] && tra_s1_io_out_bits_amo_data[33])) begin cov_fail++; $display("[COV] TreeArbiter.io_out_bits_amo_data[33] 未见过 0 和 1"); end
    if (!(tra_s0_io_out_bits_amo_data[34] && tra_s1_io_out_bits_amo_data[34])) begin cov_fail++; $display("[COV] TreeArbiter.io_out_bits_amo_data[34] 未见过 0 和 1"); end
    if (!(tra_s0_io_out_bits_amo_data[35] && tra_s1_io_out_bits_amo_data[35])) begin cov_fail++; $display("[COV] TreeArbiter.io_out_bits_amo_data[35] 未见过 0 和 1"); end
    if (!(tra_s0_io_out_bits_amo_data[36] && tra_s1_io_out_bits_amo_data[36])) begin cov_fail++; $display("[COV] TreeArbiter.io_out_bits_amo_data[36] 未见过 0 和 1"); end
    if (!(tra_s0_io_out_bits_amo_data[37] && tra_s1_io_out_bits_amo_data[37])) begin cov_fail++; $display("[COV] TreeArbiter.io_out_bits_amo_data[37] 未见过 0 和 1"); end
    if (!(tra_s0_io_out_bits_amo_data[38] && tra_s1_io_out_bits_amo_data[38])) begin cov_fail++; $display("[COV] TreeArbiter.io_out_bits_amo_data[38] 未见过 0 和 1"); end
    if (!(tra_s0_io_out_bits_amo_data[39] && tra_s1_io_out_bits_amo_data[39])) begin cov_fail++; $display("[COV] TreeArbiter.io_out_bits_amo_data[39] 未见过 0 和 1"); end
    if (!(tra_s0_io_out_bits_amo_data[40] && tra_s1_io_out_bits_amo_data[40])) begin cov_fail++; $display("[COV] TreeArbiter.io_out_bits_amo_data[40] 未见过 0 和 1"); end
    if (!(tra_s0_io_out_bits_amo_data[41] && tra_s1_io_out_bits_amo_data[41])) begin cov_fail++; $display("[COV] TreeArbiter.io_out_bits_amo_data[41] 未见过 0 和 1"); end
    if (!(tra_s0_io_out_bits_amo_data[42] && tra_s1_io_out_bits_amo_data[42])) begin cov_fail++; $display("[COV] TreeArbiter.io_out_bits_amo_data[42] 未见过 0 和 1"); end
    if (!(tra_s0_io_out_bits_amo_data[43] && tra_s1_io_out_bits_amo_data[43])) begin cov_fail++; $display("[COV] TreeArbiter.io_out_bits_amo_data[43] 未见过 0 和 1"); end
    if (!(tra_s0_io_out_bits_amo_data[44] && tra_s1_io_out_bits_amo_data[44])) begin cov_fail++; $display("[COV] TreeArbiter.io_out_bits_amo_data[44] 未见过 0 和 1"); end
    if (!(tra_s0_io_out_bits_amo_data[45] && tra_s1_io_out_bits_amo_data[45])) begin cov_fail++; $display("[COV] TreeArbiter.io_out_bits_amo_data[45] 未见过 0 和 1"); end
    if (!(tra_s0_io_out_bits_amo_data[46] && tra_s1_io_out_bits_amo_data[46])) begin cov_fail++; $display("[COV] TreeArbiter.io_out_bits_amo_data[46] 未见过 0 和 1"); end
    if (!(tra_s0_io_out_bits_amo_data[47] && tra_s1_io_out_bits_amo_data[47])) begin cov_fail++; $display("[COV] TreeArbiter.io_out_bits_amo_data[47] 未见过 0 和 1"); end
    if (!(tra_s0_io_out_bits_amo_data[48] && tra_s1_io_out_bits_amo_data[48])) begin cov_fail++; $display("[COV] TreeArbiter.io_out_bits_amo_data[48] 未见过 0 和 1"); end
    if (!(tra_s0_io_out_bits_amo_data[49] && tra_s1_io_out_bits_amo_data[49])) begin cov_fail++; $display("[COV] TreeArbiter.io_out_bits_amo_data[49] 未见过 0 和 1"); end
    if (!(tra_s0_io_out_bits_amo_data[50] && tra_s1_io_out_bits_amo_data[50])) begin cov_fail++; $display("[COV] TreeArbiter.io_out_bits_amo_data[50] 未见过 0 和 1"); end
    if (!(tra_s0_io_out_bits_amo_data[51] && tra_s1_io_out_bits_amo_data[51])) begin cov_fail++; $display("[COV] TreeArbiter.io_out_bits_amo_data[51] 未见过 0 和 1"); end
    if (!(tra_s0_io_out_bits_amo_data[52] && tra_s1_io_out_bits_amo_data[52])) begin cov_fail++; $display("[COV] TreeArbiter.io_out_bits_amo_data[52] 未见过 0 和 1"); end
    if (!(tra_s0_io_out_bits_amo_data[53] && tra_s1_io_out_bits_amo_data[53])) begin cov_fail++; $display("[COV] TreeArbiter.io_out_bits_amo_data[53] 未见过 0 和 1"); end
    if (!(tra_s0_io_out_bits_amo_data[54] && tra_s1_io_out_bits_amo_data[54])) begin cov_fail++; $display("[COV] TreeArbiter.io_out_bits_amo_data[54] 未见过 0 和 1"); end
    if (!(tra_s0_io_out_bits_amo_data[55] && tra_s1_io_out_bits_amo_data[55])) begin cov_fail++; $display("[COV] TreeArbiter.io_out_bits_amo_data[55] 未见过 0 和 1"); end
    if (!(tra_s0_io_out_bits_amo_data[56] && tra_s1_io_out_bits_amo_data[56])) begin cov_fail++; $display("[COV] TreeArbiter.io_out_bits_amo_data[56] 未见过 0 和 1"); end
    if (!(tra_s0_io_out_bits_amo_data[57] && tra_s1_io_out_bits_amo_data[57])) begin cov_fail++; $display("[COV] TreeArbiter.io_out_bits_amo_data[57] 未见过 0 和 1"); end
    if (!(tra_s0_io_out_bits_amo_data[58] && tra_s1_io_out_bits_amo_data[58])) begin cov_fail++; $display("[COV] TreeArbiter.io_out_bits_amo_data[58] 未见过 0 和 1"); end
    if (!(tra_s0_io_out_bits_amo_data[59] && tra_s1_io_out_bits_amo_data[59])) begin cov_fail++; $display("[COV] TreeArbiter.io_out_bits_amo_data[59] 未见过 0 和 1"); end
    if (!(tra_s0_io_out_bits_amo_data[60] && tra_s1_io_out_bits_amo_data[60])) begin cov_fail++; $display("[COV] TreeArbiter.io_out_bits_amo_data[60] 未见过 0 和 1"); end
    if (!(tra_s0_io_out_bits_amo_data[61] && tra_s1_io_out_bits_amo_data[61])) begin cov_fail++; $display("[COV] TreeArbiter.io_out_bits_amo_data[61] 未见过 0 和 1"); end
    if (!(tra_s0_io_out_bits_amo_data[62] && tra_s1_io_out_bits_amo_data[62])) begin cov_fail++; $display("[COV] TreeArbiter.io_out_bits_amo_data[62] 未见过 0 和 1"); end
    if (!(tra_s0_io_out_bits_amo_data[63] && tra_s1_io_out_bits_amo_data[63])) begin cov_fail++; $display("[COV] TreeArbiter.io_out_bits_amo_data[63] 未见过 0 和 1"); end
    if (!(tra_s0_io_out_bits_amo_data[64] && tra_s1_io_out_bits_amo_data[64])) begin cov_fail++; $display("[COV] TreeArbiter.io_out_bits_amo_data[64] 未见过 0 和 1"); end
    if (!(tra_s0_io_out_bits_amo_data[65] && tra_s1_io_out_bits_amo_data[65])) begin cov_fail++; $display("[COV] TreeArbiter.io_out_bits_amo_data[65] 未见过 0 和 1"); end
    if (!(tra_s0_io_out_bits_amo_data[66] && tra_s1_io_out_bits_amo_data[66])) begin cov_fail++; $display("[COV] TreeArbiter.io_out_bits_amo_data[66] 未见过 0 和 1"); end
    if (!(tra_s0_io_out_bits_amo_data[67] && tra_s1_io_out_bits_amo_data[67])) begin cov_fail++; $display("[COV] TreeArbiter.io_out_bits_amo_data[67] 未见过 0 和 1"); end
    if (!(tra_s0_io_out_bits_amo_data[68] && tra_s1_io_out_bits_amo_data[68])) begin cov_fail++; $display("[COV] TreeArbiter.io_out_bits_amo_data[68] 未见过 0 和 1"); end
    if (!(tra_s0_io_out_bits_amo_data[69] && tra_s1_io_out_bits_amo_data[69])) begin cov_fail++; $display("[COV] TreeArbiter.io_out_bits_amo_data[69] 未见过 0 和 1"); end
    if (!(tra_s0_io_out_bits_amo_data[70] && tra_s1_io_out_bits_amo_data[70])) begin cov_fail++; $display("[COV] TreeArbiter.io_out_bits_amo_data[70] 未见过 0 和 1"); end
    if (!(tra_s0_io_out_bits_amo_data[71] && tra_s1_io_out_bits_amo_data[71])) begin cov_fail++; $display("[COV] TreeArbiter.io_out_bits_amo_data[71] 未见过 0 和 1"); end
    if (!(tra_s0_io_out_bits_amo_data[72] && tra_s1_io_out_bits_amo_data[72])) begin cov_fail++; $display("[COV] TreeArbiter.io_out_bits_amo_data[72] 未见过 0 和 1"); end
    if (!(tra_s0_io_out_bits_amo_data[73] && tra_s1_io_out_bits_amo_data[73])) begin cov_fail++; $display("[COV] TreeArbiter.io_out_bits_amo_data[73] 未见过 0 和 1"); end
    if (!(tra_s0_io_out_bits_amo_data[74] && tra_s1_io_out_bits_amo_data[74])) begin cov_fail++; $display("[COV] TreeArbiter.io_out_bits_amo_data[74] 未见过 0 和 1"); end
    if (!(tra_s0_io_out_bits_amo_data[75] && tra_s1_io_out_bits_amo_data[75])) begin cov_fail++; $display("[COV] TreeArbiter.io_out_bits_amo_data[75] 未见过 0 和 1"); end
    if (!(tra_s0_io_out_bits_amo_data[76] && tra_s1_io_out_bits_amo_data[76])) begin cov_fail++; $display("[COV] TreeArbiter.io_out_bits_amo_data[76] 未见过 0 和 1"); end
    if (!(tra_s0_io_out_bits_amo_data[77] && tra_s1_io_out_bits_amo_data[77])) begin cov_fail++; $display("[COV] TreeArbiter.io_out_bits_amo_data[77] 未见过 0 和 1"); end
    if (!(tra_s0_io_out_bits_amo_data[78] && tra_s1_io_out_bits_amo_data[78])) begin cov_fail++; $display("[COV] TreeArbiter.io_out_bits_amo_data[78] 未见过 0 和 1"); end
    if (!(tra_s0_io_out_bits_amo_data[79] && tra_s1_io_out_bits_amo_data[79])) begin cov_fail++; $display("[COV] TreeArbiter.io_out_bits_amo_data[79] 未见过 0 和 1"); end
    if (!(tra_s0_io_out_bits_amo_data[80] && tra_s1_io_out_bits_amo_data[80])) begin cov_fail++; $display("[COV] TreeArbiter.io_out_bits_amo_data[80] 未见过 0 和 1"); end
    if (!(tra_s0_io_out_bits_amo_data[81] && tra_s1_io_out_bits_amo_data[81])) begin cov_fail++; $display("[COV] TreeArbiter.io_out_bits_amo_data[81] 未见过 0 和 1"); end
    if (!(tra_s0_io_out_bits_amo_data[82] && tra_s1_io_out_bits_amo_data[82])) begin cov_fail++; $display("[COV] TreeArbiter.io_out_bits_amo_data[82] 未见过 0 和 1"); end
    if (!(tra_s0_io_out_bits_amo_data[83] && tra_s1_io_out_bits_amo_data[83])) begin cov_fail++; $display("[COV] TreeArbiter.io_out_bits_amo_data[83] 未见过 0 和 1"); end
    if (!(tra_s0_io_out_bits_amo_data[84] && tra_s1_io_out_bits_amo_data[84])) begin cov_fail++; $display("[COV] TreeArbiter.io_out_bits_amo_data[84] 未见过 0 和 1"); end
    if (!(tra_s0_io_out_bits_amo_data[85] && tra_s1_io_out_bits_amo_data[85])) begin cov_fail++; $display("[COV] TreeArbiter.io_out_bits_amo_data[85] 未见过 0 和 1"); end
    if (!(tra_s0_io_out_bits_amo_data[86] && tra_s1_io_out_bits_amo_data[86])) begin cov_fail++; $display("[COV] TreeArbiter.io_out_bits_amo_data[86] 未见过 0 和 1"); end
    if (!(tra_s0_io_out_bits_amo_data[87] && tra_s1_io_out_bits_amo_data[87])) begin cov_fail++; $display("[COV] TreeArbiter.io_out_bits_amo_data[87] 未见过 0 和 1"); end
    if (!(tra_s0_io_out_bits_amo_data[88] && tra_s1_io_out_bits_amo_data[88])) begin cov_fail++; $display("[COV] TreeArbiter.io_out_bits_amo_data[88] 未见过 0 和 1"); end
    if (!(tra_s0_io_out_bits_amo_data[89] && tra_s1_io_out_bits_amo_data[89])) begin cov_fail++; $display("[COV] TreeArbiter.io_out_bits_amo_data[89] 未见过 0 和 1"); end
    if (!(tra_s0_io_out_bits_amo_data[90] && tra_s1_io_out_bits_amo_data[90])) begin cov_fail++; $display("[COV] TreeArbiter.io_out_bits_amo_data[90] 未见过 0 和 1"); end
    if (!(tra_s0_io_out_bits_amo_data[91] && tra_s1_io_out_bits_amo_data[91])) begin cov_fail++; $display("[COV] TreeArbiter.io_out_bits_amo_data[91] 未见过 0 和 1"); end
    if (!(tra_s0_io_out_bits_amo_data[92] && tra_s1_io_out_bits_amo_data[92])) begin cov_fail++; $display("[COV] TreeArbiter.io_out_bits_amo_data[92] 未见过 0 和 1"); end
    if (!(tra_s0_io_out_bits_amo_data[93] && tra_s1_io_out_bits_amo_data[93])) begin cov_fail++; $display("[COV] TreeArbiter.io_out_bits_amo_data[93] 未见过 0 和 1"); end
    if (!(tra_s0_io_out_bits_amo_data[94] && tra_s1_io_out_bits_amo_data[94])) begin cov_fail++; $display("[COV] TreeArbiter.io_out_bits_amo_data[94] 未见过 0 和 1"); end
    if (!(tra_s0_io_out_bits_amo_data[95] && tra_s1_io_out_bits_amo_data[95])) begin cov_fail++; $display("[COV] TreeArbiter.io_out_bits_amo_data[95] 未见过 0 和 1"); end
    if (!(tra_s0_io_out_bits_amo_data[96] && tra_s1_io_out_bits_amo_data[96])) begin cov_fail++; $display("[COV] TreeArbiter.io_out_bits_amo_data[96] 未见过 0 和 1"); end
    if (!(tra_s0_io_out_bits_amo_data[97] && tra_s1_io_out_bits_amo_data[97])) begin cov_fail++; $display("[COV] TreeArbiter.io_out_bits_amo_data[97] 未见过 0 和 1"); end
    if (!(tra_s0_io_out_bits_amo_data[98] && tra_s1_io_out_bits_amo_data[98])) begin cov_fail++; $display("[COV] TreeArbiter.io_out_bits_amo_data[98] 未见过 0 和 1"); end
    if (!(tra_s0_io_out_bits_amo_data[99] && tra_s1_io_out_bits_amo_data[99])) begin cov_fail++; $display("[COV] TreeArbiter.io_out_bits_amo_data[99] 未见过 0 和 1"); end
    if (!(tra_s0_io_out_bits_amo_data[100] && tra_s1_io_out_bits_amo_data[100])) begin cov_fail++; $display("[COV] TreeArbiter.io_out_bits_amo_data[100] 未见过 0 和 1"); end
    if (!(tra_s0_io_out_bits_amo_data[101] && tra_s1_io_out_bits_amo_data[101])) begin cov_fail++; $display("[COV] TreeArbiter.io_out_bits_amo_data[101] 未见过 0 和 1"); end
    if (!(tra_s0_io_out_bits_amo_data[102] && tra_s1_io_out_bits_amo_data[102])) begin cov_fail++; $display("[COV] TreeArbiter.io_out_bits_amo_data[102] 未见过 0 和 1"); end
    if (!(tra_s0_io_out_bits_amo_data[103] && tra_s1_io_out_bits_amo_data[103])) begin cov_fail++; $display("[COV] TreeArbiter.io_out_bits_amo_data[103] 未见过 0 和 1"); end
    if (!(tra_s0_io_out_bits_amo_data[104] && tra_s1_io_out_bits_amo_data[104])) begin cov_fail++; $display("[COV] TreeArbiter.io_out_bits_amo_data[104] 未见过 0 和 1"); end
    if (!(tra_s0_io_out_bits_amo_data[105] && tra_s1_io_out_bits_amo_data[105])) begin cov_fail++; $display("[COV] TreeArbiter.io_out_bits_amo_data[105] 未见过 0 和 1"); end
    if (!(tra_s0_io_out_bits_amo_data[106] && tra_s1_io_out_bits_amo_data[106])) begin cov_fail++; $display("[COV] TreeArbiter.io_out_bits_amo_data[106] 未见过 0 和 1"); end
    if (!(tra_s0_io_out_bits_amo_data[107] && tra_s1_io_out_bits_amo_data[107])) begin cov_fail++; $display("[COV] TreeArbiter.io_out_bits_amo_data[107] 未见过 0 和 1"); end
    if (!(tra_s0_io_out_bits_amo_data[108] && tra_s1_io_out_bits_amo_data[108])) begin cov_fail++; $display("[COV] TreeArbiter.io_out_bits_amo_data[108] 未见过 0 和 1"); end
    if (!(tra_s0_io_out_bits_amo_data[109] && tra_s1_io_out_bits_amo_data[109])) begin cov_fail++; $display("[COV] TreeArbiter.io_out_bits_amo_data[109] 未见过 0 和 1"); end
    if (!(tra_s0_io_out_bits_amo_data[110] && tra_s1_io_out_bits_amo_data[110])) begin cov_fail++; $display("[COV] TreeArbiter.io_out_bits_amo_data[110] 未见过 0 和 1"); end
    if (!(tra_s0_io_out_bits_amo_data[111] && tra_s1_io_out_bits_amo_data[111])) begin cov_fail++; $display("[COV] TreeArbiter.io_out_bits_amo_data[111] 未见过 0 和 1"); end
    if (!(tra_s0_io_out_bits_amo_data[112] && tra_s1_io_out_bits_amo_data[112])) begin cov_fail++; $display("[COV] TreeArbiter.io_out_bits_amo_data[112] 未见过 0 和 1"); end
    if (!(tra_s0_io_out_bits_amo_data[113] && tra_s1_io_out_bits_amo_data[113])) begin cov_fail++; $display("[COV] TreeArbiter.io_out_bits_amo_data[113] 未见过 0 和 1"); end
    if (!(tra_s0_io_out_bits_amo_data[114] && tra_s1_io_out_bits_amo_data[114])) begin cov_fail++; $display("[COV] TreeArbiter.io_out_bits_amo_data[114] 未见过 0 和 1"); end
    if (!(tra_s0_io_out_bits_amo_data[115] && tra_s1_io_out_bits_amo_data[115])) begin cov_fail++; $display("[COV] TreeArbiter.io_out_bits_amo_data[115] 未见过 0 和 1"); end
    if (!(tra_s0_io_out_bits_amo_data[116] && tra_s1_io_out_bits_amo_data[116])) begin cov_fail++; $display("[COV] TreeArbiter.io_out_bits_amo_data[116] 未见过 0 和 1"); end
    if (!(tra_s0_io_out_bits_amo_data[117] && tra_s1_io_out_bits_amo_data[117])) begin cov_fail++; $display("[COV] TreeArbiter.io_out_bits_amo_data[117] 未见过 0 和 1"); end
    if (!(tra_s0_io_out_bits_amo_data[118] && tra_s1_io_out_bits_amo_data[118])) begin cov_fail++; $display("[COV] TreeArbiter.io_out_bits_amo_data[118] 未见过 0 和 1"); end
    if (!(tra_s0_io_out_bits_amo_data[119] && tra_s1_io_out_bits_amo_data[119])) begin cov_fail++; $display("[COV] TreeArbiter.io_out_bits_amo_data[119] 未见过 0 和 1"); end
    if (!(tra_s0_io_out_bits_amo_data[120] && tra_s1_io_out_bits_amo_data[120])) begin cov_fail++; $display("[COV] TreeArbiter.io_out_bits_amo_data[120] 未见过 0 和 1"); end
    if (!(tra_s0_io_out_bits_amo_data[121] && tra_s1_io_out_bits_amo_data[121])) begin cov_fail++; $display("[COV] TreeArbiter.io_out_bits_amo_data[121] 未见过 0 和 1"); end
    if (!(tra_s0_io_out_bits_amo_data[122] && tra_s1_io_out_bits_amo_data[122])) begin cov_fail++; $display("[COV] TreeArbiter.io_out_bits_amo_data[122] 未见过 0 和 1"); end
    if (!(tra_s0_io_out_bits_amo_data[123] && tra_s1_io_out_bits_amo_data[123])) begin cov_fail++; $display("[COV] TreeArbiter.io_out_bits_amo_data[123] 未见过 0 和 1"); end
    if (!(tra_s0_io_out_bits_amo_data[124] && tra_s1_io_out_bits_amo_data[124])) begin cov_fail++; $display("[COV] TreeArbiter.io_out_bits_amo_data[124] 未见过 0 和 1"); end
    if (!(tra_s0_io_out_bits_amo_data[125] && tra_s1_io_out_bits_amo_data[125])) begin cov_fail++; $display("[COV] TreeArbiter.io_out_bits_amo_data[125] 未见过 0 和 1"); end
    if (!(tra_s0_io_out_bits_amo_data[126] && tra_s1_io_out_bits_amo_data[126])) begin cov_fail++; $display("[COV] TreeArbiter.io_out_bits_amo_data[126] 未见过 0 和 1"); end
    if (!(tra_s0_io_out_bits_amo_data[127] && tra_s1_io_out_bits_amo_data[127])) begin cov_fail++; $display("[COV] TreeArbiter.io_out_bits_amo_data[127] 未见过 0 和 1"); end
    if (!(tra_s0_io_out_bits_amo_mask[0] && tra_s1_io_out_bits_amo_mask[0])) begin cov_fail++; $display("[COV] TreeArbiter.io_out_bits_amo_mask[0] 未见过 0 和 1"); end
    if (!(tra_s0_io_out_bits_amo_mask[1] && tra_s1_io_out_bits_amo_mask[1])) begin cov_fail++; $display("[COV] TreeArbiter.io_out_bits_amo_mask[1] 未见过 0 和 1"); end
    if (!(tra_s0_io_out_bits_amo_mask[2] && tra_s1_io_out_bits_amo_mask[2])) begin cov_fail++; $display("[COV] TreeArbiter.io_out_bits_amo_mask[2] 未见过 0 和 1"); end
    if (!(tra_s0_io_out_bits_amo_mask[3] && tra_s1_io_out_bits_amo_mask[3])) begin cov_fail++; $display("[COV] TreeArbiter.io_out_bits_amo_mask[3] 未见过 0 和 1"); end
    if (!(tra_s0_io_out_bits_amo_mask[4] && tra_s1_io_out_bits_amo_mask[4])) begin cov_fail++; $display("[COV] TreeArbiter.io_out_bits_amo_mask[4] 未见过 0 和 1"); end
    if (!(tra_s0_io_out_bits_amo_mask[5] && tra_s1_io_out_bits_amo_mask[5])) begin cov_fail++; $display("[COV] TreeArbiter.io_out_bits_amo_mask[5] 未见过 0 和 1"); end
    if (!(tra_s0_io_out_bits_amo_mask[6] && tra_s1_io_out_bits_amo_mask[6])) begin cov_fail++; $display("[COV] TreeArbiter.io_out_bits_amo_mask[6] 未见过 0 和 1"); end
    if (!(tra_s0_io_out_bits_amo_mask[7] && tra_s1_io_out_bits_amo_mask[7])) begin cov_fail++; $display("[COV] TreeArbiter.io_out_bits_amo_mask[7] 未见过 0 和 1"); end
    if (!(tra_s0_io_out_bits_amo_mask[8] && tra_s1_io_out_bits_amo_mask[8])) begin cov_fail++; $display("[COV] TreeArbiter.io_out_bits_amo_mask[8] 未见过 0 和 1"); end
    if (!(tra_s0_io_out_bits_amo_mask[9] && tra_s1_io_out_bits_amo_mask[9])) begin cov_fail++; $display("[COV] TreeArbiter.io_out_bits_amo_mask[9] 未见过 0 和 1"); end
    if (!(tra_s0_io_out_bits_amo_mask[10] && tra_s1_io_out_bits_amo_mask[10])) begin cov_fail++; $display("[COV] TreeArbiter.io_out_bits_amo_mask[10] 未见过 0 和 1"); end
    if (!(tra_s0_io_out_bits_amo_mask[11] && tra_s1_io_out_bits_amo_mask[11])) begin cov_fail++; $display("[COV] TreeArbiter.io_out_bits_amo_mask[11] 未见过 0 和 1"); end
    if (!(tra_s0_io_out_bits_amo_mask[12] && tra_s1_io_out_bits_amo_mask[12])) begin cov_fail++; $display("[COV] TreeArbiter.io_out_bits_amo_mask[12] 未见过 0 和 1"); end
    if (!(tra_s0_io_out_bits_amo_mask[13] && tra_s1_io_out_bits_amo_mask[13])) begin cov_fail++; $display("[COV] TreeArbiter.io_out_bits_amo_mask[13] 未见过 0 和 1"); end
    if (!(tra_s0_io_out_bits_amo_mask[14] && tra_s1_io_out_bits_amo_mask[14])) begin cov_fail++; $display("[COV] TreeArbiter.io_out_bits_amo_mask[14] 未见过 0 和 1"); end
    if (!(tra_s0_io_out_bits_amo_mask[15] && tra_s1_io_out_bits_amo_mask[15])) begin cov_fail++; $display("[COV] TreeArbiter.io_out_bits_amo_mask[15] 未见过 0 和 1"); end
    if (!(tra_s0_io_out_bits_amo_cmp[0] && tra_s1_io_out_bits_amo_cmp[0])) begin cov_fail++; $display("[COV] TreeArbiter.io_out_bits_amo_cmp[0] 未见过 0 和 1"); end
    if (!(tra_s0_io_out_bits_amo_cmp[1] && tra_s1_io_out_bits_amo_cmp[1])) begin cov_fail++; $display("[COV] TreeArbiter.io_out_bits_amo_cmp[1] 未见过 0 和 1"); end
    if (!(tra_s0_io_out_bits_amo_cmp[2] && tra_s1_io_out_bits_amo_cmp[2])) begin cov_fail++; $display("[COV] TreeArbiter.io_out_bits_amo_cmp[2] 未见过 0 和 1"); end
    if (!(tra_s0_io_out_bits_amo_cmp[3] && tra_s1_io_out_bits_amo_cmp[3])) begin cov_fail++; $display("[COV] TreeArbiter.io_out_bits_amo_cmp[3] 未见过 0 和 1"); end
    if (!(tra_s0_io_out_bits_amo_cmp[4] && tra_s1_io_out_bits_amo_cmp[4])) begin cov_fail++; $display("[COV] TreeArbiter.io_out_bits_amo_cmp[4] 未见过 0 和 1"); end
    if (!(tra_s0_io_out_bits_amo_cmp[5] && tra_s1_io_out_bits_amo_cmp[5])) begin cov_fail++; $display("[COV] TreeArbiter.io_out_bits_amo_cmp[5] 未见过 0 和 1"); end
    if (!(tra_s0_io_out_bits_amo_cmp[6] && tra_s1_io_out_bits_amo_cmp[6])) begin cov_fail++; $display("[COV] TreeArbiter.io_out_bits_amo_cmp[6] 未见过 0 和 1"); end
    if (!(tra_s0_io_out_bits_amo_cmp[7] && tra_s1_io_out_bits_amo_cmp[7])) begin cov_fail++; $display("[COV] TreeArbiter.io_out_bits_amo_cmp[7] 未见过 0 和 1"); end
    if (!(tra_s0_io_out_bits_amo_cmp[8] && tra_s1_io_out_bits_amo_cmp[8])) begin cov_fail++; $display("[COV] TreeArbiter.io_out_bits_amo_cmp[8] 未见过 0 和 1"); end
    if (!(tra_s0_io_out_bits_amo_cmp[9] && tra_s1_io_out_bits_amo_cmp[9])) begin cov_fail++; $display("[COV] TreeArbiter.io_out_bits_amo_cmp[9] 未见过 0 和 1"); end
    if (!(tra_s0_io_out_bits_amo_cmp[10] && tra_s1_io_out_bits_amo_cmp[10])) begin cov_fail++; $display("[COV] TreeArbiter.io_out_bits_amo_cmp[10] 未见过 0 和 1"); end
    if (!(tra_s0_io_out_bits_amo_cmp[11] && tra_s1_io_out_bits_amo_cmp[11])) begin cov_fail++; $display("[COV] TreeArbiter.io_out_bits_amo_cmp[11] 未见过 0 和 1"); end
    if (!(tra_s0_io_out_bits_amo_cmp[12] && tra_s1_io_out_bits_amo_cmp[12])) begin cov_fail++; $display("[COV] TreeArbiter.io_out_bits_amo_cmp[12] 未见过 0 和 1"); end
    if (!(tra_s0_io_out_bits_amo_cmp[13] && tra_s1_io_out_bits_amo_cmp[13])) begin cov_fail++; $display("[COV] TreeArbiter.io_out_bits_amo_cmp[13] 未见过 0 和 1"); end
    if (!(tra_s0_io_out_bits_amo_cmp[14] && tra_s1_io_out_bits_amo_cmp[14])) begin cov_fail++; $display("[COV] TreeArbiter.io_out_bits_amo_cmp[14] 未见过 0 和 1"); end
    if (!(tra_s0_io_out_bits_amo_cmp[15] && tra_s1_io_out_bits_amo_cmp[15])) begin cov_fail++; $display("[COV] TreeArbiter.io_out_bits_amo_cmp[15] 未见过 0 和 1"); end
    if (!(tra_s0_io_out_bits_amo_cmp[16] && tra_s1_io_out_bits_amo_cmp[16])) begin cov_fail++; $display("[COV] TreeArbiter.io_out_bits_amo_cmp[16] 未见过 0 和 1"); end
    if (!(tra_s0_io_out_bits_amo_cmp[17] && tra_s1_io_out_bits_amo_cmp[17])) begin cov_fail++; $display("[COV] TreeArbiter.io_out_bits_amo_cmp[17] 未见过 0 和 1"); end
    if (!(tra_s0_io_out_bits_amo_cmp[18] && tra_s1_io_out_bits_amo_cmp[18])) begin cov_fail++; $display("[COV] TreeArbiter.io_out_bits_amo_cmp[18] 未见过 0 和 1"); end
    if (!(tra_s0_io_out_bits_amo_cmp[19] && tra_s1_io_out_bits_amo_cmp[19])) begin cov_fail++; $display("[COV] TreeArbiter.io_out_bits_amo_cmp[19] 未见过 0 和 1"); end
    if (!(tra_s0_io_out_bits_amo_cmp[20] && tra_s1_io_out_bits_amo_cmp[20])) begin cov_fail++; $display("[COV] TreeArbiter.io_out_bits_amo_cmp[20] 未见过 0 和 1"); end
    if (!(tra_s0_io_out_bits_amo_cmp[21] && tra_s1_io_out_bits_amo_cmp[21])) begin cov_fail++; $display("[COV] TreeArbiter.io_out_bits_amo_cmp[21] 未见过 0 和 1"); end
    if (!(tra_s0_io_out_bits_amo_cmp[22] && tra_s1_io_out_bits_amo_cmp[22])) begin cov_fail++; $display("[COV] TreeArbiter.io_out_bits_amo_cmp[22] 未见过 0 和 1"); end
    if (!(tra_s0_io_out_bits_amo_cmp[23] && tra_s1_io_out_bits_amo_cmp[23])) begin cov_fail++; $display("[COV] TreeArbiter.io_out_bits_amo_cmp[23] 未见过 0 和 1"); end
    if (!(tra_s0_io_out_bits_amo_cmp[24] && tra_s1_io_out_bits_amo_cmp[24])) begin cov_fail++; $display("[COV] TreeArbiter.io_out_bits_amo_cmp[24] 未见过 0 和 1"); end
    if (!(tra_s0_io_out_bits_amo_cmp[25] && tra_s1_io_out_bits_amo_cmp[25])) begin cov_fail++; $display("[COV] TreeArbiter.io_out_bits_amo_cmp[25] 未见过 0 和 1"); end
    if (!(tra_s0_io_out_bits_amo_cmp[26] && tra_s1_io_out_bits_amo_cmp[26])) begin cov_fail++; $display("[COV] TreeArbiter.io_out_bits_amo_cmp[26] 未见过 0 和 1"); end
    if (!(tra_s0_io_out_bits_amo_cmp[27] && tra_s1_io_out_bits_amo_cmp[27])) begin cov_fail++; $display("[COV] TreeArbiter.io_out_bits_amo_cmp[27] 未见过 0 和 1"); end
    if (!(tra_s0_io_out_bits_amo_cmp[28] && tra_s1_io_out_bits_amo_cmp[28])) begin cov_fail++; $display("[COV] TreeArbiter.io_out_bits_amo_cmp[28] 未见过 0 和 1"); end
    if (!(tra_s0_io_out_bits_amo_cmp[29] && tra_s1_io_out_bits_amo_cmp[29])) begin cov_fail++; $display("[COV] TreeArbiter.io_out_bits_amo_cmp[29] 未见过 0 和 1"); end
    if (!(tra_s0_io_out_bits_amo_cmp[30] && tra_s1_io_out_bits_amo_cmp[30])) begin cov_fail++; $display("[COV] TreeArbiter.io_out_bits_amo_cmp[30] 未见过 0 和 1"); end
    if (!(tra_s0_io_out_bits_amo_cmp[31] && tra_s1_io_out_bits_amo_cmp[31])) begin cov_fail++; $display("[COV] TreeArbiter.io_out_bits_amo_cmp[31] 未见过 0 和 1"); end
    if (!(tra_s0_io_out_bits_amo_cmp[32] && tra_s1_io_out_bits_amo_cmp[32])) begin cov_fail++; $display("[COV] TreeArbiter.io_out_bits_amo_cmp[32] 未见过 0 和 1"); end
    if (!(tra_s0_io_out_bits_amo_cmp[33] && tra_s1_io_out_bits_amo_cmp[33])) begin cov_fail++; $display("[COV] TreeArbiter.io_out_bits_amo_cmp[33] 未见过 0 和 1"); end
    if (!(tra_s0_io_out_bits_amo_cmp[34] && tra_s1_io_out_bits_amo_cmp[34])) begin cov_fail++; $display("[COV] TreeArbiter.io_out_bits_amo_cmp[34] 未见过 0 和 1"); end
    if (!(tra_s0_io_out_bits_amo_cmp[35] && tra_s1_io_out_bits_amo_cmp[35])) begin cov_fail++; $display("[COV] TreeArbiter.io_out_bits_amo_cmp[35] 未见过 0 和 1"); end
    if (!(tra_s0_io_out_bits_amo_cmp[36] && tra_s1_io_out_bits_amo_cmp[36])) begin cov_fail++; $display("[COV] TreeArbiter.io_out_bits_amo_cmp[36] 未见过 0 和 1"); end
    if (!(tra_s0_io_out_bits_amo_cmp[37] && tra_s1_io_out_bits_amo_cmp[37])) begin cov_fail++; $display("[COV] TreeArbiter.io_out_bits_amo_cmp[37] 未见过 0 和 1"); end
    if (!(tra_s0_io_out_bits_amo_cmp[38] && tra_s1_io_out_bits_amo_cmp[38])) begin cov_fail++; $display("[COV] TreeArbiter.io_out_bits_amo_cmp[38] 未见过 0 和 1"); end
    if (!(tra_s0_io_out_bits_amo_cmp[39] && tra_s1_io_out_bits_amo_cmp[39])) begin cov_fail++; $display("[COV] TreeArbiter.io_out_bits_amo_cmp[39] 未见过 0 和 1"); end
    if (!(tra_s0_io_out_bits_amo_cmp[40] && tra_s1_io_out_bits_amo_cmp[40])) begin cov_fail++; $display("[COV] TreeArbiter.io_out_bits_amo_cmp[40] 未见过 0 和 1"); end
    if (!(tra_s0_io_out_bits_amo_cmp[41] && tra_s1_io_out_bits_amo_cmp[41])) begin cov_fail++; $display("[COV] TreeArbiter.io_out_bits_amo_cmp[41] 未见过 0 和 1"); end
    if (!(tra_s0_io_out_bits_amo_cmp[42] && tra_s1_io_out_bits_amo_cmp[42])) begin cov_fail++; $display("[COV] TreeArbiter.io_out_bits_amo_cmp[42] 未见过 0 和 1"); end
    if (!(tra_s0_io_out_bits_amo_cmp[43] && tra_s1_io_out_bits_amo_cmp[43])) begin cov_fail++; $display("[COV] TreeArbiter.io_out_bits_amo_cmp[43] 未见过 0 和 1"); end
    if (!(tra_s0_io_out_bits_amo_cmp[44] && tra_s1_io_out_bits_amo_cmp[44])) begin cov_fail++; $display("[COV] TreeArbiter.io_out_bits_amo_cmp[44] 未见过 0 和 1"); end
    if (!(tra_s0_io_out_bits_amo_cmp[45] && tra_s1_io_out_bits_amo_cmp[45])) begin cov_fail++; $display("[COV] TreeArbiter.io_out_bits_amo_cmp[45] 未见过 0 和 1"); end
    if (!(tra_s0_io_out_bits_amo_cmp[46] && tra_s1_io_out_bits_amo_cmp[46])) begin cov_fail++; $display("[COV] TreeArbiter.io_out_bits_amo_cmp[46] 未见过 0 和 1"); end
    if (!(tra_s0_io_out_bits_amo_cmp[47] && tra_s1_io_out_bits_amo_cmp[47])) begin cov_fail++; $display("[COV] TreeArbiter.io_out_bits_amo_cmp[47] 未见过 0 和 1"); end
    if (!(tra_s0_io_out_bits_amo_cmp[48] && tra_s1_io_out_bits_amo_cmp[48])) begin cov_fail++; $display("[COV] TreeArbiter.io_out_bits_amo_cmp[48] 未见过 0 和 1"); end
    if (!(tra_s0_io_out_bits_amo_cmp[49] && tra_s1_io_out_bits_amo_cmp[49])) begin cov_fail++; $display("[COV] TreeArbiter.io_out_bits_amo_cmp[49] 未见过 0 和 1"); end
    if (!(tra_s0_io_out_bits_amo_cmp[50] && tra_s1_io_out_bits_amo_cmp[50])) begin cov_fail++; $display("[COV] TreeArbiter.io_out_bits_amo_cmp[50] 未见过 0 和 1"); end
    if (!(tra_s0_io_out_bits_amo_cmp[51] && tra_s1_io_out_bits_amo_cmp[51])) begin cov_fail++; $display("[COV] TreeArbiter.io_out_bits_amo_cmp[51] 未见过 0 和 1"); end
    if (!(tra_s0_io_out_bits_amo_cmp[52] && tra_s1_io_out_bits_amo_cmp[52])) begin cov_fail++; $display("[COV] TreeArbiter.io_out_bits_amo_cmp[52] 未见过 0 和 1"); end
    if (!(tra_s0_io_out_bits_amo_cmp[53] && tra_s1_io_out_bits_amo_cmp[53])) begin cov_fail++; $display("[COV] TreeArbiter.io_out_bits_amo_cmp[53] 未见过 0 和 1"); end
    if (!(tra_s0_io_out_bits_amo_cmp[54] && tra_s1_io_out_bits_amo_cmp[54])) begin cov_fail++; $display("[COV] TreeArbiter.io_out_bits_amo_cmp[54] 未见过 0 和 1"); end
    if (!(tra_s0_io_out_bits_amo_cmp[55] && tra_s1_io_out_bits_amo_cmp[55])) begin cov_fail++; $display("[COV] TreeArbiter.io_out_bits_amo_cmp[55] 未见过 0 和 1"); end
    if (!(tra_s0_io_out_bits_amo_cmp[56] && tra_s1_io_out_bits_amo_cmp[56])) begin cov_fail++; $display("[COV] TreeArbiter.io_out_bits_amo_cmp[56] 未见过 0 和 1"); end
    if (!(tra_s0_io_out_bits_amo_cmp[57] && tra_s1_io_out_bits_amo_cmp[57])) begin cov_fail++; $display("[COV] TreeArbiter.io_out_bits_amo_cmp[57] 未见过 0 和 1"); end
    if (!(tra_s0_io_out_bits_amo_cmp[58] && tra_s1_io_out_bits_amo_cmp[58])) begin cov_fail++; $display("[COV] TreeArbiter.io_out_bits_amo_cmp[58] 未见过 0 和 1"); end
    if (!(tra_s0_io_out_bits_amo_cmp[59] && tra_s1_io_out_bits_amo_cmp[59])) begin cov_fail++; $display("[COV] TreeArbiter.io_out_bits_amo_cmp[59] 未见过 0 和 1"); end
    if (!(tra_s0_io_out_bits_amo_cmp[60] && tra_s1_io_out_bits_amo_cmp[60])) begin cov_fail++; $display("[COV] TreeArbiter.io_out_bits_amo_cmp[60] 未见过 0 和 1"); end
    if (!(tra_s0_io_out_bits_amo_cmp[61] && tra_s1_io_out_bits_amo_cmp[61])) begin cov_fail++; $display("[COV] TreeArbiter.io_out_bits_amo_cmp[61] 未见过 0 和 1"); end
    if (!(tra_s0_io_out_bits_amo_cmp[62] && tra_s1_io_out_bits_amo_cmp[62])) begin cov_fail++; $display("[COV] TreeArbiter.io_out_bits_amo_cmp[62] 未见过 0 和 1"); end
    if (!(tra_s0_io_out_bits_amo_cmp[63] && tra_s1_io_out_bits_amo_cmp[63])) begin cov_fail++; $display("[COV] TreeArbiter.io_out_bits_amo_cmp[63] 未见过 0 和 1"); end
    if (!(tra_s0_io_out_bits_amo_cmp[64] && tra_s1_io_out_bits_amo_cmp[64])) begin cov_fail++; $display("[COV] TreeArbiter.io_out_bits_amo_cmp[64] 未见过 0 和 1"); end
    if (!(tra_s0_io_out_bits_amo_cmp[65] && tra_s1_io_out_bits_amo_cmp[65])) begin cov_fail++; $display("[COV] TreeArbiter.io_out_bits_amo_cmp[65] 未见过 0 和 1"); end
    if (!(tra_s0_io_out_bits_amo_cmp[66] && tra_s1_io_out_bits_amo_cmp[66])) begin cov_fail++; $display("[COV] TreeArbiter.io_out_bits_amo_cmp[66] 未见过 0 和 1"); end
    if (!(tra_s0_io_out_bits_amo_cmp[67] && tra_s1_io_out_bits_amo_cmp[67])) begin cov_fail++; $display("[COV] TreeArbiter.io_out_bits_amo_cmp[67] 未见过 0 和 1"); end
    if (!(tra_s0_io_out_bits_amo_cmp[68] && tra_s1_io_out_bits_amo_cmp[68])) begin cov_fail++; $display("[COV] TreeArbiter.io_out_bits_amo_cmp[68] 未见过 0 和 1"); end
    if (!(tra_s0_io_out_bits_amo_cmp[69] && tra_s1_io_out_bits_amo_cmp[69])) begin cov_fail++; $display("[COV] TreeArbiter.io_out_bits_amo_cmp[69] 未见过 0 和 1"); end
    if (!(tra_s0_io_out_bits_amo_cmp[70] && tra_s1_io_out_bits_amo_cmp[70])) begin cov_fail++; $display("[COV] TreeArbiter.io_out_bits_amo_cmp[70] 未见过 0 和 1"); end
    if (!(tra_s0_io_out_bits_amo_cmp[71] && tra_s1_io_out_bits_amo_cmp[71])) begin cov_fail++; $display("[COV] TreeArbiter.io_out_bits_amo_cmp[71] 未见过 0 和 1"); end
    if (!(tra_s0_io_out_bits_amo_cmp[72] && tra_s1_io_out_bits_amo_cmp[72])) begin cov_fail++; $display("[COV] TreeArbiter.io_out_bits_amo_cmp[72] 未见过 0 和 1"); end
    if (!(tra_s0_io_out_bits_amo_cmp[73] && tra_s1_io_out_bits_amo_cmp[73])) begin cov_fail++; $display("[COV] TreeArbiter.io_out_bits_amo_cmp[73] 未见过 0 和 1"); end
    if (!(tra_s0_io_out_bits_amo_cmp[74] && tra_s1_io_out_bits_amo_cmp[74])) begin cov_fail++; $display("[COV] TreeArbiter.io_out_bits_amo_cmp[74] 未见过 0 和 1"); end
    if (!(tra_s0_io_out_bits_amo_cmp[75] && tra_s1_io_out_bits_amo_cmp[75])) begin cov_fail++; $display("[COV] TreeArbiter.io_out_bits_amo_cmp[75] 未见过 0 和 1"); end
    if (!(tra_s0_io_out_bits_amo_cmp[76] && tra_s1_io_out_bits_amo_cmp[76])) begin cov_fail++; $display("[COV] TreeArbiter.io_out_bits_amo_cmp[76] 未见过 0 和 1"); end
    if (!(tra_s0_io_out_bits_amo_cmp[77] && tra_s1_io_out_bits_amo_cmp[77])) begin cov_fail++; $display("[COV] TreeArbiter.io_out_bits_amo_cmp[77] 未见过 0 和 1"); end
    if (!(tra_s0_io_out_bits_amo_cmp[78] && tra_s1_io_out_bits_amo_cmp[78])) begin cov_fail++; $display("[COV] TreeArbiter.io_out_bits_amo_cmp[78] 未见过 0 和 1"); end
    if (!(tra_s0_io_out_bits_amo_cmp[79] && tra_s1_io_out_bits_amo_cmp[79])) begin cov_fail++; $display("[COV] TreeArbiter.io_out_bits_amo_cmp[79] 未见过 0 和 1"); end
    if (!(tra_s0_io_out_bits_amo_cmp[80] && tra_s1_io_out_bits_amo_cmp[80])) begin cov_fail++; $display("[COV] TreeArbiter.io_out_bits_amo_cmp[80] 未见过 0 和 1"); end
    if (!(tra_s0_io_out_bits_amo_cmp[81] && tra_s1_io_out_bits_amo_cmp[81])) begin cov_fail++; $display("[COV] TreeArbiter.io_out_bits_amo_cmp[81] 未见过 0 和 1"); end
    if (!(tra_s0_io_out_bits_amo_cmp[82] && tra_s1_io_out_bits_amo_cmp[82])) begin cov_fail++; $display("[COV] TreeArbiter.io_out_bits_amo_cmp[82] 未见过 0 和 1"); end
    if (!(tra_s0_io_out_bits_amo_cmp[83] && tra_s1_io_out_bits_amo_cmp[83])) begin cov_fail++; $display("[COV] TreeArbiter.io_out_bits_amo_cmp[83] 未见过 0 和 1"); end
    if (!(tra_s0_io_out_bits_amo_cmp[84] && tra_s1_io_out_bits_amo_cmp[84])) begin cov_fail++; $display("[COV] TreeArbiter.io_out_bits_amo_cmp[84] 未见过 0 和 1"); end
    if (!(tra_s0_io_out_bits_amo_cmp[85] && tra_s1_io_out_bits_amo_cmp[85])) begin cov_fail++; $display("[COV] TreeArbiter.io_out_bits_amo_cmp[85] 未见过 0 和 1"); end
    if (!(tra_s0_io_out_bits_amo_cmp[86] && tra_s1_io_out_bits_amo_cmp[86])) begin cov_fail++; $display("[COV] TreeArbiter.io_out_bits_amo_cmp[86] 未见过 0 和 1"); end
    if (!(tra_s0_io_out_bits_amo_cmp[87] && tra_s1_io_out_bits_amo_cmp[87])) begin cov_fail++; $display("[COV] TreeArbiter.io_out_bits_amo_cmp[87] 未见过 0 和 1"); end
    if (!(tra_s0_io_out_bits_amo_cmp[88] && tra_s1_io_out_bits_amo_cmp[88])) begin cov_fail++; $display("[COV] TreeArbiter.io_out_bits_amo_cmp[88] 未见过 0 和 1"); end
    if (!(tra_s0_io_out_bits_amo_cmp[89] && tra_s1_io_out_bits_amo_cmp[89])) begin cov_fail++; $display("[COV] TreeArbiter.io_out_bits_amo_cmp[89] 未见过 0 和 1"); end
    if (!(tra_s0_io_out_bits_amo_cmp[90] && tra_s1_io_out_bits_amo_cmp[90])) begin cov_fail++; $display("[COV] TreeArbiter.io_out_bits_amo_cmp[90] 未见过 0 和 1"); end
    if (!(tra_s0_io_out_bits_amo_cmp[91] && tra_s1_io_out_bits_amo_cmp[91])) begin cov_fail++; $display("[COV] TreeArbiter.io_out_bits_amo_cmp[91] 未见过 0 和 1"); end
    if (!(tra_s0_io_out_bits_amo_cmp[92] && tra_s1_io_out_bits_amo_cmp[92])) begin cov_fail++; $display("[COV] TreeArbiter.io_out_bits_amo_cmp[92] 未见过 0 和 1"); end
    if (!(tra_s0_io_out_bits_amo_cmp[93] && tra_s1_io_out_bits_amo_cmp[93])) begin cov_fail++; $display("[COV] TreeArbiter.io_out_bits_amo_cmp[93] 未见过 0 和 1"); end
    if (!(tra_s0_io_out_bits_amo_cmp[94] && tra_s1_io_out_bits_amo_cmp[94])) begin cov_fail++; $display("[COV] TreeArbiter.io_out_bits_amo_cmp[94] 未见过 0 和 1"); end
    if (!(tra_s0_io_out_bits_amo_cmp[95] && tra_s1_io_out_bits_amo_cmp[95])) begin cov_fail++; $display("[COV] TreeArbiter.io_out_bits_amo_cmp[95] 未见过 0 和 1"); end
    if (!(tra_s0_io_out_bits_amo_cmp[96] && tra_s1_io_out_bits_amo_cmp[96])) begin cov_fail++; $display("[COV] TreeArbiter.io_out_bits_amo_cmp[96] 未见过 0 和 1"); end
    if (!(tra_s0_io_out_bits_amo_cmp[97] && tra_s1_io_out_bits_amo_cmp[97])) begin cov_fail++; $display("[COV] TreeArbiter.io_out_bits_amo_cmp[97] 未见过 0 和 1"); end
    if (!(tra_s0_io_out_bits_amo_cmp[98] && tra_s1_io_out_bits_amo_cmp[98])) begin cov_fail++; $display("[COV] TreeArbiter.io_out_bits_amo_cmp[98] 未见过 0 和 1"); end
    if (!(tra_s0_io_out_bits_amo_cmp[99] && tra_s1_io_out_bits_amo_cmp[99])) begin cov_fail++; $display("[COV] TreeArbiter.io_out_bits_amo_cmp[99] 未见过 0 和 1"); end
    if (!(tra_s0_io_out_bits_amo_cmp[100] && tra_s1_io_out_bits_amo_cmp[100])) begin cov_fail++; $display("[COV] TreeArbiter.io_out_bits_amo_cmp[100] 未见过 0 和 1"); end
    if (!(tra_s0_io_out_bits_amo_cmp[101] && tra_s1_io_out_bits_amo_cmp[101])) begin cov_fail++; $display("[COV] TreeArbiter.io_out_bits_amo_cmp[101] 未见过 0 和 1"); end
    if (!(tra_s0_io_out_bits_amo_cmp[102] && tra_s1_io_out_bits_amo_cmp[102])) begin cov_fail++; $display("[COV] TreeArbiter.io_out_bits_amo_cmp[102] 未见过 0 和 1"); end
    if (!(tra_s0_io_out_bits_amo_cmp[103] && tra_s1_io_out_bits_amo_cmp[103])) begin cov_fail++; $display("[COV] TreeArbiter.io_out_bits_amo_cmp[103] 未见过 0 和 1"); end
    if (!(tra_s0_io_out_bits_amo_cmp[104] && tra_s1_io_out_bits_amo_cmp[104])) begin cov_fail++; $display("[COV] TreeArbiter.io_out_bits_amo_cmp[104] 未见过 0 和 1"); end
    if (!(tra_s0_io_out_bits_amo_cmp[105] && tra_s1_io_out_bits_amo_cmp[105])) begin cov_fail++; $display("[COV] TreeArbiter.io_out_bits_amo_cmp[105] 未见过 0 和 1"); end
    if (!(tra_s0_io_out_bits_amo_cmp[106] && tra_s1_io_out_bits_amo_cmp[106])) begin cov_fail++; $display("[COV] TreeArbiter.io_out_bits_amo_cmp[106] 未见过 0 和 1"); end
    if (!(tra_s0_io_out_bits_amo_cmp[107] && tra_s1_io_out_bits_amo_cmp[107])) begin cov_fail++; $display("[COV] TreeArbiter.io_out_bits_amo_cmp[107] 未见过 0 和 1"); end
    if (!(tra_s0_io_out_bits_amo_cmp[108] && tra_s1_io_out_bits_amo_cmp[108])) begin cov_fail++; $display("[COV] TreeArbiter.io_out_bits_amo_cmp[108] 未见过 0 和 1"); end
    if (!(tra_s0_io_out_bits_amo_cmp[109] && tra_s1_io_out_bits_amo_cmp[109])) begin cov_fail++; $display("[COV] TreeArbiter.io_out_bits_amo_cmp[109] 未见过 0 和 1"); end
    if (!(tra_s0_io_out_bits_amo_cmp[110] && tra_s1_io_out_bits_amo_cmp[110])) begin cov_fail++; $display("[COV] TreeArbiter.io_out_bits_amo_cmp[110] 未见过 0 和 1"); end
    if (!(tra_s0_io_out_bits_amo_cmp[111] && tra_s1_io_out_bits_amo_cmp[111])) begin cov_fail++; $display("[COV] TreeArbiter.io_out_bits_amo_cmp[111] 未见过 0 和 1"); end
    if (!(tra_s0_io_out_bits_amo_cmp[112] && tra_s1_io_out_bits_amo_cmp[112])) begin cov_fail++; $display("[COV] TreeArbiter.io_out_bits_amo_cmp[112] 未见过 0 和 1"); end
    if (!(tra_s0_io_out_bits_amo_cmp[113] && tra_s1_io_out_bits_amo_cmp[113])) begin cov_fail++; $display("[COV] TreeArbiter.io_out_bits_amo_cmp[113] 未见过 0 和 1"); end
    if (!(tra_s0_io_out_bits_amo_cmp[114] && tra_s1_io_out_bits_amo_cmp[114])) begin cov_fail++; $display("[COV] TreeArbiter.io_out_bits_amo_cmp[114] 未见过 0 和 1"); end
    if (!(tra_s0_io_out_bits_amo_cmp[115] && tra_s1_io_out_bits_amo_cmp[115])) begin cov_fail++; $display("[COV] TreeArbiter.io_out_bits_amo_cmp[115] 未见过 0 和 1"); end
    if (!(tra_s0_io_out_bits_amo_cmp[116] && tra_s1_io_out_bits_amo_cmp[116])) begin cov_fail++; $display("[COV] TreeArbiter.io_out_bits_amo_cmp[116] 未见过 0 和 1"); end
    if (!(tra_s0_io_out_bits_amo_cmp[117] && tra_s1_io_out_bits_amo_cmp[117])) begin cov_fail++; $display("[COV] TreeArbiter.io_out_bits_amo_cmp[117] 未见过 0 和 1"); end
    if (!(tra_s0_io_out_bits_amo_cmp[118] && tra_s1_io_out_bits_amo_cmp[118])) begin cov_fail++; $display("[COV] TreeArbiter.io_out_bits_amo_cmp[118] 未见过 0 和 1"); end
    if (!(tra_s0_io_out_bits_amo_cmp[119] && tra_s1_io_out_bits_amo_cmp[119])) begin cov_fail++; $display("[COV] TreeArbiter.io_out_bits_amo_cmp[119] 未见过 0 和 1"); end
    if (!(tra_s0_io_out_bits_amo_cmp[120] && tra_s1_io_out_bits_amo_cmp[120])) begin cov_fail++; $display("[COV] TreeArbiter.io_out_bits_amo_cmp[120] 未见过 0 和 1"); end
    if (!(tra_s0_io_out_bits_amo_cmp[121] && tra_s1_io_out_bits_amo_cmp[121])) begin cov_fail++; $display("[COV] TreeArbiter.io_out_bits_amo_cmp[121] 未见过 0 和 1"); end
    if (!(tra_s0_io_out_bits_amo_cmp[122] && tra_s1_io_out_bits_amo_cmp[122])) begin cov_fail++; $display("[COV] TreeArbiter.io_out_bits_amo_cmp[122] 未见过 0 和 1"); end
    if (!(tra_s0_io_out_bits_amo_cmp[123] && tra_s1_io_out_bits_amo_cmp[123])) begin cov_fail++; $display("[COV] TreeArbiter.io_out_bits_amo_cmp[123] 未见过 0 和 1"); end
    if (!(tra_s0_io_out_bits_amo_cmp[124] && tra_s1_io_out_bits_amo_cmp[124])) begin cov_fail++; $display("[COV] TreeArbiter.io_out_bits_amo_cmp[124] 未见过 0 和 1"); end
    if (!(tra_s0_io_out_bits_amo_cmp[125] && tra_s1_io_out_bits_amo_cmp[125])) begin cov_fail++; $display("[COV] TreeArbiter.io_out_bits_amo_cmp[125] 未见过 0 和 1"); end
    if (!(tra_s0_io_out_bits_amo_cmp[126] && tra_s1_io_out_bits_amo_cmp[126])) begin cov_fail++; $display("[COV] TreeArbiter.io_out_bits_amo_cmp[126] 未见过 0 和 1"); end
    if (!(tra_s0_io_out_bits_amo_cmp[127] && tra_s1_io_out_bits_amo_cmp[127])) begin cov_fail++; $display("[COV] TreeArbiter.io_out_bits_amo_cmp[127] 未见过 0 和 1"); end
    if (!(tra_s0_io_out_bits_req_coh_state[0] && tra_s1_io_out_bits_req_coh_state[0])) begin cov_fail++; $display("[COV] TreeArbiter.io_out_bits_req_coh_state[0] 未见过 0 和 1"); end
    if (!(tra_s0_io_out_bits_req_coh_state[1] && tra_s1_io_out_bits_req_coh_state[1])) begin cov_fail++; $display("[COV] TreeArbiter.io_out_bits_req_coh_state[1] 未见过 0 和 1"); end
    if (!(tra_s0_io_out_bits_id[0] && tra_s1_io_out_bits_id[0])) begin cov_fail++; $display("[COV] TreeArbiter.io_out_bits_id[0] 未见过 0 和 1"); end
    if (!(tra_s0_io_out_bits_id[1] && tra_s1_io_out_bits_id[1])) begin cov_fail++; $display("[COV] TreeArbiter.io_out_bits_id[1] 未见过 0 和 1"); end
    if (!(tra_s0_io_out_bits_id[2] && tra_s1_io_out_bits_id[2])) begin cov_fail++; $display("[COV] TreeArbiter.io_out_bits_id[2] 未见过 0 和 1"); end
    if (!(tra_s0_io_out_bits_id[3] && tra_s1_io_out_bits_id[3])) begin cov_fail++; $display("[COV] TreeArbiter.io_out_bits_id[3] 未见过 0 和 1"); end
    if (!(tra_s0_io_out_bits_id[4] && tra_s1_io_out_bits_id[4])) begin cov_fail++; $display("[COV] TreeArbiter.io_out_bits_id[4] 未见过 0 和 1"); end
    if (!(tra_s0_io_out_bits_id[5] && tra_s1_io_out_bits_id[5])) begin cov_fail++; $display("[COV] TreeArbiter.io_out_bits_id[5] 未见过 0 和 1"); end
    if (!(tra_s0_io_out_bits_isBtoT && tra_s1_io_out_bits_isBtoT)) begin cov_fail++; $display("[COV] TreeArbiter.io_out_bits_isBtoT 未见过 0 和 1"); end
    if (!(tra_s0_io_out_bits_occupy_way[0] && tra_s1_io_out_bits_occupy_way[0])) begin cov_fail++; $display("[COV] TreeArbiter.io_out_bits_occupy_way[0] 未见过 0 和 1"); end
    if (!(tra_s0_io_out_bits_occupy_way[1] && tra_s1_io_out_bits_occupy_way[1])) begin cov_fail++; $display("[COV] TreeArbiter.io_out_bits_occupy_way[1] 未见过 0 和 1"); end
    if (!(tra_s0_io_out_bits_occupy_way[2] && tra_s1_io_out_bits_occupy_way[2])) begin cov_fail++; $display("[COV] TreeArbiter.io_out_bits_occupy_way[2] 未见过 0 和 1"); end
    if (!(tra_s0_io_out_bits_occupy_way[3] && tra_s1_io_out_bits_occupy_way[3])) begin cov_fail++; $display("[COV] TreeArbiter.io_out_bits_occupy_way[3] 未见过 0 和 1"); end
    if (!(tra_s0_io_out_bits_cancel && tra_s1_io_out_bits_cancel)) begin cov_fail++; $display("[COV] TreeArbiter.io_out_bits_cancel 未见过 0 和 1"); end
    if (!(tra_s0_io_out_bits_store_data[0] && tra_s1_io_out_bits_store_data[0])) begin cov_fail++; $display("[COV] TreeArbiter.io_out_bits_store_data[0] 未见过 0 和 1"); end
    if (!(tra_s0_io_out_bits_store_data[1] && tra_s1_io_out_bits_store_data[1])) begin cov_fail++; $display("[COV] TreeArbiter.io_out_bits_store_data[1] 未见过 0 和 1"); end
    if (!(tra_s0_io_out_bits_store_data[2] && tra_s1_io_out_bits_store_data[2])) begin cov_fail++; $display("[COV] TreeArbiter.io_out_bits_store_data[2] 未见过 0 和 1"); end
    if (!(tra_s0_io_out_bits_store_data[3] && tra_s1_io_out_bits_store_data[3])) begin cov_fail++; $display("[COV] TreeArbiter.io_out_bits_store_data[3] 未见过 0 和 1"); end
    if (!(tra_s0_io_out_bits_store_data[4] && tra_s1_io_out_bits_store_data[4])) begin cov_fail++; $display("[COV] TreeArbiter.io_out_bits_store_data[4] 未见过 0 和 1"); end
    if (!(tra_s0_io_out_bits_store_data[5] && tra_s1_io_out_bits_store_data[5])) begin cov_fail++; $display("[COV] TreeArbiter.io_out_bits_store_data[5] 未见过 0 和 1"); end
    if (!(tra_s0_io_out_bits_store_data[6] && tra_s1_io_out_bits_store_data[6])) begin cov_fail++; $display("[COV] TreeArbiter.io_out_bits_store_data[6] 未见过 0 和 1"); end
    if (!(tra_s0_io_out_bits_store_data[7] && tra_s1_io_out_bits_store_data[7])) begin cov_fail++; $display("[COV] TreeArbiter.io_out_bits_store_data[7] 未见过 0 和 1"); end
    if (!(tra_s0_io_out_bits_store_data[8] && tra_s1_io_out_bits_store_data[8])) begin cov_fail++; $display("[COV] TreeArbiter.io_out_bits_store_data[8] 未见过 0 和 1"); end
    if (!(tra_s0_io_out_bits_store_data[9] && tra_s1_io_out_bits_store_data[9])) begin cov_fail++; $display("[COV] TreeArbiter.io_out_bits_store_data[9] 未见过 0 和 1"); end
    if (!(tra_s0_io_out_bits_store_data[10] && tra_s1_io_out_bits_store_data[10])) begin cov_fail++; $display("[COV] TreeArbiter.io_out_bits_store_data[10] 未见过 0 和 1"); end
    if (!(tra_s0_io_out_bits_store_data[11] && tra_s1_io_out_bits_store_data[11])) begin cov_fail++; $display("[COV] TreeArbiter.io_out_bits_store_data[11] 未见过 0 和 1"); end
    if (!(tra_s0_io_out_bits_store_data[12] && tra_s1_io_out_bits_store_data[12])) begin cov_fail++; $display("[COV] TreeArbiter.io_out_bits_store_data[12] 未见过 0 和 1"); end
    if (!(tra_s0_io_out_bits_store_data[13] && tra_s1_io_out_bits_store_data[13])) begin cov_fail++; $display("[COV] TreeArbiter.io_out_bits_store_data[13] 未见过 0 和 1"); end
    if (!(tra_s0_io_out_bits_store_data[14] && tra_s1_io_out_bits_store_data[14])) begin cov_fail++; $display("[COV] TreeArbiter.io_out_bits_store_data[14] 未见过 0 和 1"); end
    if (!(tra_s0_io_out_bits_store_data[15] && tra_s1_io_out_bits_store_data[15])) begin cov_fail++; $display("[COV] TreeArbiter.io_out_bits_store_data[15] 未见过 0 和 1"); end
    if (!(tra_s0_io_out_bits_store_data[16] && tra_s1_io_out_bits_store_data[16])) begin cov_fail++; $display("[COV] TreeArbiter.io_out_bits_store_data[16] 未见过 0 和 1"); end
    if (!(tra_s0_io_out_bits_store_data[17] && tra_s1_io_out_bits_store_data[17])) begin cov_fail++; $display("[COV] TreeArbiter.io_out_bits_store_data[17] 未见过 0 和 1"); end
    if (!(tra_s0_io_out_bits_store_data[18] && tra_s1_io_out_bits_store_data[18])) begin cov_fail++; $display("[COV] TreeArbiter.io_out_bits_store_data[18] 未见过 0 和 1"); end
    if (!(tra_s0_io_out_bits_store_data[19] && tra_s1_io_out_bits_store_data[19])) begin cov_fail++; $display("[COV] TreeArbiter.io_out_bits_store_data[19] 未见过 0 和 1"); end
    if (!(tra_s0_io_out_bits_store_data[20] && tra_s1_io_out_bits_store_data[20])) begin cov_fail++; $display("[COV] TreeArbiter.io_out_bits_store_data[20] 未见过 0 和 1"); end
    if (!(tra_s0_io_out_bits_store_data[21] && tra_s1_io_out_bits_store_data[21])) begin cov_fail++; $display("[COV] TreeArbiter.io_out_bits_store_data[21] 未见过 0 和 1"); end
    if (!(tra_s0_io_out_bits_store_data[22] && tra_s1_io_out_bits_store_data[22])) begin cov_fail++; $display("[COV] TreeArbiter.io_out_bits_store_data[22] 未见过 0 和 1"); end
    if (!(tra_s0_io_out_bits_store_data[23] && tra_s1_io_out_bits_store_data[23])) begin cov_fail++; $display("[COV] TreeArbiter.io_out_bits_store_data[23] 未见过 0 和 1"); end
    if (!(tra_s0_io_out_bits_store_data[24] && tra_s1_io_out_bits_store_data[24])) begin cov_fail++; $display("[COV] TreeArbiter.io_out_bits_store_data[24] 未见过 0 和 1"); end
    if (!(tra_s0_io_out_bits_store_data[25] && tra_s1_io_out_bits_store_data[25])) begin cov_fail++; $display("[COV] TreeArbiter.io_out_bits_store_data[25] 未见过 0 和 1"); end
    if (!(tra_s0_io_out_bits_store_data[26] && tra_s1_io_out_bits_store_data[26])) begin cov_fail++; $display("[COV] TreeArbiter.io_out_bits_store_data[26] 未见过 0 和 1"); end
    if (!(tra_s0_io_out_bits_store_data[27] && tra_s1_io_out_bits_store_data[27])) begin cov_fail++; $display("[COV] TreeArbiter.io_out_bits_store_data[27] 未见过 0 和 1"); end
    if (!(tra_s0_io_out_bits_store_data[28] && tra_s1_io_out_bits_store_data[28])) begin cov_fail++; $display("[COV] TreeArbiter.io_out_bits_store_data[28] 未见过 0 和 1"); end
    if (!(tra_s0_io_out_bits_store_data[29] && tra_s1_io_out_bits_store_data[29])) begin cov_fail++; $display("[COV] TreeArbiter.io_out_bits_store_data[29] 未见过 0 和 1"); end
    if (!(tra_s0_io_out_bits_store_data[30] && tra_s1_io_out_bits_store_data[30])) begin cov_fail++; $display("[COV] TreeArbiter.io_out_bits_store_data[30] 未见过 0 和 1"); end
    if (!(tra_s0_io_out_bits_store_data[31] && tra_s1_io_out_bits_store_data[31])) begin cov_fail++; $display("[COV] TreeArbiter.io_out_bits_store_data[31] 未见过 0 和 1"); end
    if (!(tra_s0_io_out_bits_store_data[32] && tra_s1_io_out_bits_store_data[32])) begin cov_fail++; $display("[COV] TreeArbiter.io_out_bits_store_data[32] 未见过 0 和 1"); end
    if (!(tra_s0_io_out_bits_store_data[33] && tra_s1_io_out_bits_store_data[33])) begin cov_fail++; $display("[COV] TreeArbiter.io_out_bits_store_data[33] 未见过 0 和 1"); end
    if (!(tra_s0_io_out_bits_store_data[34] && tra_s1_io_out_bits_store_data[34])) begin cov_fail++; $display("[COV] TreeArbiter.io_out_bits_store_data[34] 未见过 0 和 1"); end
    if (!(tra_s0_io_out_bits_store_data[35] && tra_s1_io_out_bits_store_data[35])) begin cov_fail++; $display("[COV] TreeArbiter.io_out_bits_store_data[35] 未见过 0 和 1"); end
    if (!(tra_s0_io_out_bits_store_data[36] && tra_s1_io_out_bits_store_data[36])) begin cov_fail++; $display("[COV] TreeArbiter.io_out_bits_store_data[36] 未见过 0 和 1"); end
    if (!(tra_s0_io_out_bits_store_data[37] && tra_s1_io_out_bits_store_data[37])) begin cov_fail++; $display("[COV] TreeArbiter.io_out_bits_store_data[37] 未见过 0 和 1"); end
    if (!(tra_s0_io_out_bits_store_data[38] && tra_s1_io_out_bits_store_data[38])) begin cov_fail++; $display("[COV] TreeArbiter.io_out_bits_store_data[38] 未见过 0 和 1"); end
    if (!(tra_s0_io_out_bits_store_data[39] && tra_s1_io_out_bits_store_data[39])) begin cov_fail++; $display("[COV] TreeArbiter.io_out_bits_store_data[39] 未见过 0 和 1"); end
    if (!(tra_s0_io_out_bits_store_data[40] && tra_s1_io_out_bits_store_data[40])) begin cov_fail++; $display("[COV] TreeArbiter.io_out_bits_store_data[40] 未见过 0 和 1"); end
    if (!(tra_s0_io_out_bits_store_data[41] && tra_s1_io_out_bits_store_data[41])) begin cov_fail++; $display("[COV] TreeArbiter.io_out_bits_store_data[41] 未见过 0 和 1"); end
    if (!(tra_s0_io_out_bits_store_data[42] && tra_s1_io_out_bits_store_data[42])) begin cov_fail++; $display("[COV] TreeArbiter.io_out_bits_store_data[42] 未见过 0 和 1"); end
    if (!(tra_s0_io_out_bits_store_data[43] && tra_s1_io_out_bits_store_data[43])) begin cov_fail++; $display("[COV] TreeArbiter.io_out_bits_store_data[43] 未见过 0 和 1"); end
    if (!(tra_s0_io_out_bits_store_data[44] && tra_s1_io_out_bits_store_data[44])) begin cov_fail++; $display("[COV] TreeArbiter.io_out_bits_store_data[44] 未见过 0 和 1"); end
    if (!(tra_s0_io_out_bits_store_data[45] && tra_s1_io_out_bits_store_data[45])) begin cov_fail++; $display("[COV] TreeArbiter.io_out_bits_store_data[45] 未见过 0 和 1"); end
    if (!(tra_s0_io_out_bits_store_data[46] && tra_s1_io_out_bits_store_data[46])) begin cov_fail++; $display("[COV] TreeArbiter.io_out_bits_store_data[46] 未见过 0 和 1"); end
    if (!(tra_s0_io_out_bits_store_data[47] && tra_s1_io_out_bits_store_data[47])) begin cov_fail++; $display("[COV] TreeArbiter.io_out_bits_store_data[47] 未见过 0 和 1"); end
    if (!(tra_s0_io_out_bits_store_data[48] && tra_s1_io_out_bits_store_data[48])) begin cov_fail++; $display("[COV] TreeArbiter.io_out_bits_store_data[48] 未见过 0 和 1"); end
    if (!(tra_s0_io_out_bits_store_data[49] && tra_s1_io_out_bits_store_data[49])) begin cov_fail++; $display("[COV] TreeArbiter.io_out_bits_store_data[49] 未见过 0 和 1"); end
    if (!(tra_s0_io_out_bits_store_data[50] && tra_s1_io_out_bits_store_data[50])) begin cov_fail++; $display("[COV] TreeArbiter.io_out_bits_store_data[50] 未见过 0 和 1"); end
    if (!(tra_s0_io_out_bits_store_data[51] && tra_s1_io_out_bits_store_data[51])) begin cov_fail++; $display("[COV] TreeArbiter.io_out_bits_store_data[51] 未见过 0 和 1"); end
    if (!(tra_s0_io_out_bits_store_data[52] && tra_s1_io_out_bits_store_data[52])) begin cov_fail++; $display("[COV] TreeArbiter.io_out_bits_store_data[52] 未见过 0 和 1"); end
    if (!(tra_s0_io_out_bits_store_data[53] && tra_s1_io_out_bits_store_data[53])) begin cov_fail++; $display("[COV] TreeArbiter.io_out_bits_store_data[53] 未见过 0 和 1"); end
    if (!(tra_s0_io_out_bits_store_data[54] && tra_s1_io_out_bits_store_data[54])) begin cov_fail++; $display("[COV] TreeArbiter.io_out_bits_store_data[54] 未见过 0 和 1"); end
    if (!(tra_s0_io_out_bits_store_data[55] && tra_s1_io_out_bits_store_data[55])) begin cov_fail++; $display("[COV] TreeArbiter.io_out_bits_store_data[55] 未见过 0 和 1"); end
    if (!(tra_s0_io_out_bits_store_data[56] && tra_s1_io_out_bits_store_data[56])) begin cov_fail++; $display("[COV] TreeArbiter.io_out_bits_store_data[56] 未见过 0 和 1"); end
    if (!(tra_s0_io_out_bits_store_data[57] && tra_s1_io_out_bits_store_data[57])) begin cov_fail++; $display("[COV] TreeArbiter.io_out_bits_store_data[57] 未见过 0 和 1"); end
    if (!(tra_s0_io_out_bits_store_data[58] && tra_s1_io_out_bits_store_data[58])) begin cov_fail++; $display("[COV] TreeArbiter.io_out_bits_store_data[58] 未见过 0 和 1"); end
    if (!(tra_s0_io_out_bits_store_data[59] && tra_s1_io_out_bits_store_data[59])) begin cov_fail++; $display("[COV] TreeArbiter.io_out_bits_store_data[59] 未见过 0 和 1"); end
    if (!(tra_s0_io_out_bits_store_data[60] && tra_s1_io_out_bits_store_data[60])) begin cov_fail++; $display("[COV] TreeArbiter.io_out_bits_store_data[60] 未见过 0 和 1"); end
    if (!(tra_s0_io_out_bits_store_data[61] && tra_s1_io_out_bits_store_data[61])) begin cov_fail++; $display("[COV] TreeArbiter.io_out_bits_store_data[61] 未见过 0 和 1"); end
    if (!(tra_s0_io_out_bits_store_data[62] && tra_s1_io_out_bits_store_data[62])) begin cov_fail++; $display("[COV] TreeArbiter.io_out_bits_store_data[62] 未见过 0 和 1"); end
    if (!(tra_s0_io_out_bits_store_data[63] && tra_s1_io_out_bits_store_data[63])) begin cov_fail++; $display("[COV] TreeArbiter.io_out_bits_store_data[63] 未见过 0 和 1"); end
    if (!(tra_s0_io_out_bits_store_data[64] && tra_s1_io_out_bits_store_data[64])) begin cov_fail++; $display("[COV] TreeArbiter.io_out_bits_store_data[64] 未见过 0 和 1"); end
    if (!(tra_s0_io_out_bits_store_data[65] && tra_s1_io_out_bits_store_data[65])) begin cov_fail++; $display("[COV] TreeArbiter.io_out_bits_store_data[65] 未见过 0 和 1"); end
    if (!(tra_s0_io_out_bits_store_data[66] && tra_s1_io_out_bits_store_data[66])) begin cov_fail++; $display("[COV] TreeArbiter.io_out_bits_store_data[66] 未见过 0 和 1"); end
    if (!(tra_s0_io_out_bits_store_data[67] && tra_s1_io_out_bits_store_data[67])) begin cov_fail++; $display("[COV] TreeArbiter.io_out_bits_store_data[67] 未见过 0 和 1"); end
    if (!(tra_s0_io_out_bits_store_data[68] && tra_s1_io_out_bits_store_data[68])) begin cov_fail++; $display("[COV] TreeArbiter.io_out_bits_store_data[68] 未见过 0 和 1"); end
    if (!(tra_s0_io_out_bits_store_data[69] && tra_s1_io_out_bits_store_data[69])) begin cov_fail++; $display("[COV] TreeArbiter.io_out_bits_store_data[69] 未见过 0 和 1"); end
    if (!(tra_s0_io_out_bits_store_data[70] && tra_s1_io_out_bits_store_data[70])) begin cov_fail++; $display("[COV] TreeArbiter.io_out_bits_store_data[70] 未见过 0 和 1"); end
    if (!(tra_s0_io_out_bits_store_data[71] && tra_s1_io_out_bits_store_data[71])) begin cov_fail++; $display("[COV] TreeArbiter.io_out_bits_store_data[71] 未见过 0 和 1"); end
    if (!(tra_s0_io_out_bits_store_data[72] && tra_s1_io_out_bits_store_data[72])) begin cov_fail++; $display("[COV] TreeArbiter.io_out_bits_store_data[72] 未见过 0 和 1"); end
    if (!(tra_s0_io_out_bits_store_data[73] && tra_s1_io_out_bits_store_data[73])) begin cov_fail++; $display("[COV] TreeArbiter.io_out_bits_store_data[73] 未见过 0 和 1"); end
    if (!(tra_s0_io_out_bits_store_data[74] && tra_s1_io_out_bits_store_data[74])) begin cov_fail++; $display("[COV] TreeArbiter.io_out_bits_store_data[74] 未见过 0 和 1"); end
    if (!(tra_s0_io_out_bits_store_data[75] && tra_s1_io_out_bits_store_data[75])) begin cov_fail++; $display("[COV] TreeArbiter.io_out_bits_store_data[75] 未见过 0 和 1"); end
    if (!(tra_s0_io_out_bits_store_data[76] && tra_s1_io_out_bits_store_data[76])) begin cov_fail++; $display("[COV] TreeArbiter.io_out_bits_store_data[76] 未见过 0 和 1"); end
    if (!(tra_s0_io_out_bits_store_data[77] && tra_s1_io_out_bits_store_data[77])) begin cov_fail++; $display("[COV] TreeArbiter.io_out_bits_store_data[77] 未见过 0 和 1"); end
    if (!(tra_s0_io_out_bits_store_data[78] && tra_s1_io_out_bits_store_data[78])) begin cov_fail++; $display("[COV] TreeArbiter.io_out_bits_store_data[78] 未见过 0 和 1"); end
    if (!(tra_s0_io_out_bits_store_data[79] && tra_s1_io_out_bits_store_data[79])) begin cov_fail++; $display("[COV] TreeArbiter.io_out_bits_store_data[79] 未见过 0 和 1"); end
    if (!(tra_s0_io_out_bits_store_data[80] && tra_s1_io_out_bits_store_data[80])) begin cov_fail++; $display("[COV] TreeArbiter.io_out_bits_store_data[80] 未见过 0 和 1"); end
    if (!(tra_s0_io_out_bits_store_data[81] && tra_s1_io_out_bits_store_data[81])) begin cov_fail++; $display("[COV] TreeArbiter.io_out_bits_store_data[81] 未见过 0 和 1"); end
    if (!(tra_s0_io_out_bits_store_data[82] && tra_s1_io_out_bits_store_data[82])) begin cov_fail++; $display("[COV] TreeArbiter.io_out_bits_store_data[82] 未见过 0 和 1"); end
    if (!(tra_s0_io_out_bits_store_data[83] && tra_s1_io_out_bits_store_data[83])) begin cov_fail++; $display("[COV] TreeArbiter.io_out_bits_store_data[83] 未见过 0 和 1"); end
    if (!(tra_s0_io_out_bits_store_data[84] && tra_s1_io_out_bits_store_data[84])) begin cov_fail++; $display("[COV] TreeArbiter.io_out_bits_store_data[84] 未见过 0 和 1"); end
    if (!(tra_s0_io_out_bits_store_data[85] && tra_s1_io_out_bits_store_data[85])) begin cov_fail++; $display("[COV] TreeArbiter.io_out_bits_store_data[85] 未见过 0 和 1"); end
    if (!(tra_s0_io_out_bits_store_data[86] && tra_s1_io_out_bits_store_data[86])) begin cov_fail++; $display("[COV] TreeArbiter.io_out_bits_store_data[86] 未见过 0 和 1"); end
    if (!(tra_s0_io_out_bits_store_data[87] && tra_s1_io_out_bits_store_data[87])) begin cov_fail++; $display("[COV] TreeArbiter.io_out_bits_store_data[87] 未见过 0 和 1"); end
    if (!(tra_s0_io_out_bits_store_data[88] && tra_s1_io_out_bits_store_data[88])) begin cov_fail++; $display("[COV] TreeArbiter.io_out_bits_store_data[88] 未见过 0 和 1"); end
    if (!(tra_s0_io_out_bits_store_data[89] && tra_s1_io_out_bits_store_data[89])) begin cov_fail++; $display("[COV] TreeArbiter.io_out_bits_store_data[89] 未见过 0 和 1"); end
    if (!(tra_s0_io_out_bits_store_data[90] && tra_s1_io_out_bits_store_data[90])) begin cov_fail++; $display("[COV] TreeArbiter.io_out_bits_store_data[90] 未见过 0 和 1"); end
    if (!(tra_s0_io_out_bits_store_data[91] && tra_s1_io_out_bits_store_data[91])) begin cov_fail++; $display("[COV] TreeArbiter.io_out_bits_store_data[91] 未见过 0 和 1"); end
    if (!(tra_s0_io_out_bits_store_data[92] && tra_s1_io_out_bits_store_data[92])) begin cov_fail++; $display("[COV] TreeArbiter.io_out_bits_store_data[92] 未见过 0 和 1"); end
    if (!(tra_s0_io_out_bits_store_data[93] && tra_s1_io_out_bits_store_data[93])) begin cov_fail++; $display("[COV] TreeArbiter.io_out_bits_store_data[93] 未见过 0 和 1"); end
    if (!(tra_s0_io_out_bits_store_data[94] && tra_s1_io_out_bits_store_data[94])) begin cov_fail++; $display("[COV] TreeArbiter.io_out_bits_store_data[94] 未见过 0 和 1"); end
    if (!(tra_s0_io_out_bits_store_data[95] && tra_s1_io_out_bits_store_data[95])) begin cov_fail++; $display("[COV] TreeArbiter.io_out_bits_store_data[95] 未见过 0 和 1"); end
    if (!(tra_s0_io_out_bits_store_data[96] && tra_s1_io_out_bits_store_data[96])) begin cov_fail++; $display("[COV] TreeArbiter.io_out_bits_store_data[96] 未见过 0 和 1"); end
    if (!(tra_s0_io_out_bits_store_data[97] && tra_s1_io_out_bits_store_data[97])) begin cov_fail++; $display("[COV] TreeArbiter.io_out_bits_store_data[97] 未见过 0 和 1"); end
    if (!(tra_s0_io_out_bits_store_data[98] && tra_s1_io_out_bits_store_data[98])) begin cov_fail++; $display("[COV] TreeArbiter.io_out_bits_store_data[98] 未见过 0 和 1"); end
    if (!(tra_s0_io_out_bits_store_data[99] && tra_s1_io_out_bits_store_data[99])) begin cov_fail++; $display("[COV] TreeArbiter.io_out_bits_store_data[99] 未见过 0 和 1"); end
    if (!(tra_s0_io_out_bits_store_data[100] && tra_s1_io_out_bits_store_data[100])) begin cov_fail++; $display("[COV] TreeArbiter.io_out_bits_store_data[100] 未见过 0 和 1"); end
    if (!(tra_s0_io_out_bits_store_data[101] && tra_s1_io_out_bits_store_data[101])) begin cov_fail++; $display("[COV] TreeArbiter.io_out_bits_store_data[101] 未见过 0 和 1"); end
    if (!(tra_s0_io_out_bits_store_data[102] && tra_s1_io_out_bits_store_data[102])) begin cov_fail++; $display("[COV] TreeArbiter.io_out_bits_store_data[102] 未见过 0 和 1"); end
    if (!(tra_s0_io_out_bits_store_data[103] && tra_s1_io_out_bits_store_data[103])) begin cov_fail++; $display("[COV] TreeArbiter.io_out_bits_store_data[103] 未见过 0 和 1"); end
    if (!(tra_s0_io_out_bits_store_data[104] && tra_s1_io_out_bits_store_data[104])) begin cov_fail++; $display("[COV] TreeArbiter.io_out_bits_store_data[104] 未见过 0 和 1"); end
    if (!(tra_s0_io_out_bits_store_data[105] && tra_s1_io_out_bits_store_data[105])) begin cov_fail++; $display("[COV] TreeArbiter.io_out_bits_store_data[105] 未见过 0 和 1"); end
    if (!(tra_s0_io_out_bits_store_data[106] && tra_s1_io_out_bits_store_data[106])) begin cov_fail++; $display("[COV] TreeArbiter.io_out_bits_store_data[106] 未见过 0 和 1"); end
    if (!(tra_s0_io_out_bits_store_data[107] && tra_s1_io_out_bits_store_data[107])) begin cov_fail++; $display("[COV] TreeArbiter.io_out_bits_store_data[107] 未见过 0 和 1"); end
    if (!(tra_s0_io_out_bits_store_data[108] && tra_s1_io_out_bits_store_data[108])) begin cov_fail++; $display("[COV] TreeArbiter.io_out_bits_store_data[108] 未见过 0 和 1"); end
    if (!(tra_s0_io_out_bits_store_data[109] && tra_s1_io_out_bits_store_data[109])) begin cov_fail++; $display("[COV] TreeArbiter.io_out_bits_store_data[109] 未见过 0 和 1"); end
    if (!(tra_s0_io_out_bits_store_data[110] && tra_s1_io_out_bits_store_data[110])) begin cov_fail++; $display("[COV] TreeArbiter.io_out_bits_store_data[110] 未见过 0 和 1"); end
    if (!(tra_s0_io_out_bits_store_data[111] && tra_s1_io_out_bits_store_data[111])) begin cov_fail++; $display("[COV] TreeArbiter.io_out_bits_store_data[111] 未见过 0 和 1"); end
    if (!(tra_s0_io_out_bits_store_data[112] && tra_s1_io_out_bits_store_data[112])) begin cov_fail++; $display("[COV] TreeArbiter.io_out_bits_store_data[112] 未见过 0 和 1"); end
    if (!(tra_s0_io_out_bits_store_data[113] && tra_s1_io_out_bits_store_data[113])) begin cov_fail++; $display("[COV] TreeArbiter.io_out_bits_store_data[113] 未见过 0 和 1"); end
    if (!(tra_s0_io_out_bits_store_data[114] && tra_s1_io_out_bits_store_data[114])) begin cov_fail++; $display("[COV] TreeArbiter.io_out_bits_store_data[114] 未见过 0 和 1"); end
    if (!(tra_s0_io_out_bits_store_data[115] && tra_s1_io_out_bits_store_data[115])) begin cov_fail++; $display("[COV] TreeArbiter.io_out_bits_store_data[115] 未见过 0 和 1"); end
    if (!(tra_s0_io_out_bits_store_data[116] && tra_s1_io_out_bits_store_data[116])) begin cov_fail++; $display("[COV] TreeArbiter.io_out_bits_store_data[116] 未见过 0 和 1"); end
    if (!(tra_s0_io_out_bits_store_data[117] && tra_s1_io_out_bits_store_data[117])) begin cov_fail++; $display("[COV] TreeArbiter.io_out_bits_store_data[117] 未见过 0 和 1"); end
    if (!(tra_s0_io_out_bits_store_data[118] && tra_s1_io_out_bits_store_data[118])) begin cov_fail++; $display("[COV] TreeArbiter.io_out_bits_store_data[118] 未见过 0 和 1"); end
    if (!(tra_s0_io_out_bits_store_data[119] && tra_s1_io_out_bits_store_data[119])) begin cov_fail++; $display("[COV] TreeArbiter.io_out_bits_store_data[119] 未见过 0 和 1"); end
    if (!(tra_s0_io_out_bits_store_data[120] && tra_s1_io_out_bits_store_data[120])) begin cov_fail++; $display("[COV] TreeArbiter.io_out_bits_store_data[120] 未见过 0 和 1"); end
    if (!(tra_s0_io_out_bits_store_data[121] && tra_s1_io_out_bits_store_data[121])) begin cov_fail++; $display("[COV] TreeArbiter.io_out_bits_store_data[121] 未见过 0 和 1"); end
    if (!(tra_s0_io_out_bits_store_data[122] && tra_s1_io_out_bits_store_data[122])) begin cov_fail++; $display("[COV] TreeArbiter.io_out_bits_store_data[122] 未见过 0 和 1"); end
    if (!(tra_s0_io_out_bits_store_data[123] && tra_s1_io_out_bits_store_data[123])) begin cov_fail++; $display("[COV] TreeArbiter.io_out_bits_store_data[123] 未见过 0 和 1"); end
    if (!(tra_s0_io_out_bits_store_data[124] && tra_s1_io_out_bits_store_data[124])) begin cov_fail++; $display("[COV] TreeArbiter.io_out_bits_store_data[124] 未见过 0 和 1"); end
    if (!(tra_s0_io_out_bits_store_data[125] && tra_s1_io_out_bits_store_data[125])) begin cov_fail++; $display("[COV] TreeArbiter.io_out_bits_store_data[125] 未见过 0 和 1"); end
    if (!(tra_s0_io_out_bits_store_data[126] && tra_s1_io_out_bits_store_data[126])) begin cov_fail++; $display("[COV] TreeArbiter.io_out_bits_store_data[126] 未见过 0 和 1"); end
    if (!(tra_s0_io_out_bits_store_data[127] && tra_s1_io_out_bits_store_data[127])) begin cov_fail++; $display("[COV] TreeArbiter.io_out_bits_store_data[127] 未见过 0 和 1"); end
    if (!(tra_s0_io_out_bits_store_data[128] && tra_s1_io_out_bits_store_data[128])) begin cov_fail++; $display("[COV] TreeArbiter.io_out_bits_store_data[128] 未见过 0 和 1"); end
    if (!(tra_s0_io_out_bits_store_data[129] && tra_s1_io_out_bits_store_data[129])) begin cov_fail++; $display("[COV] TreeArbiter.io_out_bits_store_data[129] 未见过 0 和 1"); end
    if (!(tra_s0_io_out_bits_store_data[130] && tra_s1_io_out_bits_store_data[130])) begin cov_fail++; $display("[COV] TreeArbiter.io_out_bits_store_data[130] 未见过 0 和 1"); end
    if (!(tra_s0_io_out_bits_store_data[131] && tra_s1_io_out_bits_store_data[131])) begin cov_fail++; $display("[COV] TreeArbiter.io_out_bits_store_data[131] 未见过 0 和 1"); end
    if (!(tra_s0_io_out_bits_store_data[132] && tra_s1_io_out_bits_store_data[132])) begin cov_fail++; $display("[COV] TreeArbiter.io_out_bits_store_data[132] 未见过 0 和 1"); end
    if (!(tra_s0_io_out_bits_store_data[133] && tra_s1_io_out_bits_store_data[133])) begin cov_fail++; $display("[COV] TreeArbiter.io_out_bits_store_data[133] 未见过 0 和 1"); end
    if (!(tra_s0_io_out_bits_store_data[134] && tra_s1_io_out_bits_store_data[134])) begin cov_fail++; $display("[COV] TreeArbiter.io_out_bits_store_data[134] 未见过 0 和 1"); end
    if (!(tra_s0_io_out_bits_store_data[135] && tra_s1_io_out_bits_store_data[135])) begin cov_fail++; $display("[COV] TreeArbiter.io_out_bits_store_data[135] 未见过 0 和 1"); end
    if (!(tra_s0_io_out_bits_store_data[136] && tra_s1_io_out_bits_store_data[136])) begin cov_fail++; $display("[COV] TreeArbiter.io_out_bits_store_data[136] 未见过 0 和 1"); end
    if (!(tra_s0_io_out_bits_store_data[137] && tra_s1_io_out_bits_store_data[137])) begin cov_fail++; $display("[COV] TreeArbiter.io_out_bits_store_data[137] 未见过 0 和 1"); end
    if (!(tra_s0_io_out_bits_store_data[138] && tra_s1_io_out_bits_store_data[138])) begin cov_fail++; $display("[COV] TreeArbiter.io_out_bits_store_data[138] 未见过 0 和 1"); end
    if (!(tra_s0_io_out_bits_store_data[139] && tra_s1_io_out_bits_store_data[139])) begin cov_fail++; $display("[COV] TreeArbiter.io_out_bits_store_data[139] 未见过 0 和 1"); end
    if (!(tra_s0_io_out_bits_store_data[140] && tra_s1_io_out_bits_store_data[140])) begin cov_fail++; $display("[COV] TreeArbiter.io_out_bits_store_data[140] 未见过 0 和 1"); end
    if (!(tra_s0_io_out_bits_store_data[141] && tra_s1_io_out_bits_store_data[141])) begin cov_fail++; $display("[COV] TreeArbiter.io_out_bits_store_data[141] 未见过 0 和 1"); end
    if (!(tra_s0_io_out_bits_store_data[142] && tra_s1_io_out_bits_store_data[142])) begin cov_fail++; $display("[COV] TreeArbiter.io_out_bits_store_data[142] 未见过 0 和 1"); end
    if (!(tra_s0_io_out_bits_store_data[143] && tra_s1_io_out_bits_store_data[143])) begin cov_fail++; $display("[COV] TreeArbiter.io_out_bits_store_data[143] 未见过 0 和 1"); end
    if (!(tra_s0_io_out_bits_store_data[144] && tra_s1_io_out_bits_store_data[144])) begin cov_fail++; $display("[COV] TreeArbiter.io_out_bits_store_data[144] 未见过 0 和 1"); end
    if (!(tra_s0_io_out_bits_store_data[145] && tra_s1_io_out_bits_store_data[145])) begin cov_fail++; $display("[COV] TreeArbiter.io_out_bits_store_data[145] 未见过 0 和 1"); end
    if (!(tra_s0_io_out_bits_store_data[146] && tra_s1_io_out_bits_store_data[146])) begin cov_fail++; $display("[COV] TreeArbiter.io_out_bits_store_data[146] 未见过 0 和 1"); end
    if (!(tra_s0_io_out_bits_store_data[147] && tra_s1_io_out_bits_store_data[147])) begin cov_fail++; $display("[COV] TreeArbiter.io_out_bits_store_data[147] 未见过 0 和 1"); end
    if (!(tra_s0_io_out_bits_store_data[148] && tra_s1_io_out_bits_store_data[148])) begin cov_fail++; $display("[COV] TreeArbiter.io_out_bits_store_data[148] 未见过 0 和 1"); end
    if (!(tra_s0_io_out_bits_store_data[149] && tra_s1_io_out_bits_store_data[149])) begin cov_fail++; $display("[COV] TreeArbiter.io_out_bits_store_data[149] 未见过 0 和 1"); end
    if (!(tra_s0_io_out_bits_store_data[150] && tra_s1_io_out_bits_store_data[150])) begin cov_fail++; $display("[COV] TreeArbiter.io_out_bits_store_data[150] 未见过 0 和 1"); end
    if (!(tra_s0_io_out_bits_store_data[151] && tra_s1_io_out_bits_store_data[151])) begin cov_fail++; $display("[COV] TreeArbiter.io_out_bits_store_data[151] 未见过 0 和 1"); end
    if (!(tra_s0_io_out_bits_store_data[152] && tra_s1_io_out_bits_store_data[152])) begin cov_fail++; $display("[COV] TreeArbiter.io_out_bits_store_data[152] 未见过 0 和 1"); end
    if (!(tra_s0_io_out_bits_store_data[153] && tra_s1_io_out_bits_store_data[153])) begin cov_fail++; $display("[COV] TreeArbiter.io_out_bits_store_data[153] 未见过 0 和 1"); end
    if (!(tra_s0_io_out_bits_store_data[154] && tra_s1_io_out_bits_store_data[154])) begin cov_fail++; $display("[COV] TreeArbiter.io_out_bits_store_data[154] 未见过 0 和 1"); end
    if (!(tra_s0_io_out_bits_store_data[155] && tra_s1_io_out_bits_store_data[155])) begin cov_fail++; $display("[COV] TreeArbiter.io_out_bits_store_data[155] 未见过 0 和 1"); end
    if (!(tra_s0_io_out_bits_store_data[156] && tra_s1_io_out_bits_store_data[156])) begin cov_fail++; $display("[COV] TreeArbiter.io_out_bits_store_data[156] 未见过 0 和 1"); end
    if (!(tra_s0_io_out_bits_store_data[157] && tra_s1_io_out_bits_store_data[157])) begin cov_fail++; $display("[COV] TreeArbiter.io_out_bits_store_data[157] 未见过 0 和 1"); end
    if (!(tra_s0_io_out_bits_store_data[158] && tra_s1_io_out_bits_store_data[158])) begin cov_fail++; $display("[COV] TreeArbiter.io_out_bits_store_data[158] 未见过 0 和 1"); end
    if (!(tra_s0_io_out_bits_store_data[159] && tra_s1_io_out_bits_store_data[159])) begin cov_fail++; $display("[COV] TreeArbiter.io_out_bits_store_data[159] 未见过 0 和 1"); end
    if (!(tra_s0_io_out_bits_store_data[160] && tra_s1_io_out_bits_store_data[160])) begin cov_fail++; $display("[COV] TreeArbiter.io_out_bits_store_data[160] 未见过 0 和 1"); end
    if (!(tra_s0_io_out_bits_store_data[161] && tra_s1_io_out_bits_store_data[161])) begin cov_fail++; $display("[COV] TreeArbiter.io_out_bits_store_data[161] 未见过 0 和 1"); end
    if (!(tra_s0_io_out_bits_store_data[162] && tra_s1_io_out_bits_store_data[162])) begin cov_fail++; $display("[COV] TreeArbiter.io_out_bits_store_data[162] 未见过 0 和 1"); end
    if (!(tra_s0_io_out_bits_store_data[163] && tra_s1_io_out_bits_store_data[163])) begin cov_fail++; $display("[COV] TreeArbiter.io_out_bits_store_data[163] 未见过 0 和 1"); end
    if (!(tra_s0_io_out_bits_store_data[164] && tra_s1_io_out_bits_store_data[164])) begin cov_fail++; $display("[COV] TreeArbiter.io_out_bits_store_data[164] 未见过 0 和 1"); end
    if (!(tra_s0_io_out_bits_store_data[165] && tra_s1_io_out_bits_store_data[165])) begin cov_fail++; $display("[COV] TreeArbiter.io_out_bits_store_data[165] 未见过 0 和 1"); end
    if (!(tra_s0_io_out_bits_store_data[166] && tra_s1_io_out_bits_store_data[166])) begin cov_fail++; $display("[COV] TreeArbiter.io_out_bits_store_data[166] 未见过 0 和 1"); end
    if (!(tra_s0_io_out_bits_store_data[167] && tra_s1_io_out_bits_store_data[167])) begin cov_fail++; $display("[COV] TreeArbiter.io_out_bits_store_data[167] 未见过 0 和 1"); end
    if (!(tra_s0_io_out_bits_store_data[168] && tra_s1_io_out_bits_store_data[168])) begin cov_fail++; $display("[COV] TreeArbiter.io_out_bits_store_data[168] 未见过 0 和 1"); end
    if (!(tra_s0_io_out_bits_store_data[169] && tra_s1_io_out_bits_store_data[169])) begin cov_fail++; $display("[COV] TreeArbiter.io_out_bits_store_data[169] 未见过 0 和 1"); end
    if (!(tra_s0_io_out_bits_store_data[170] && tra_s1_io_out_bits_store_data[170])) begin cov_fail++; $display("[COV] TreeArbiter.io_out_bits_store_data[170] 未见过 0 和 1"); end
    if (!(tra_s0_io_out_bits_store_data[171] && tra_s1_io_out_bits_store_data[171])) begin cov_fail++; $display("[COV] TreeArbiter.io_out_bits_store_data[171] 未见过 0 和 1"); end
    if (!(tra_s0_io_out_bits_store_data[172] && tra_s1_io_out_bits_store_data[172])) begin cov_fail++; $display("[COV] TreeArbiter.io_out_bits_store_data[172] 未见过 0 和 1"); end
    if (!(tra_s0_io_out_bits_store_data[173] && tra_s1_io_out_bits_store_data[173])) begin cov_fail++; $display("[COV] TreeArbiter.io_out_bits_store_data[173] 未见过 0 和 1"); end
    if (!(tra_s0_io_out_bits_store_data[174] && tra_s1_io_out_bits_store_data[174])) begin cov_fail++; $display("[COV] TreeArbiter.io_out_bits_store_data[174] 未见过 0 和 1"); end
    if (!(tra_s0_io_out_bits_store_data[175] && tra_s1_io_out_bits_store_data[175])) begin cov_fail++; $display("[COV] TreeArbiter.io_out_bits_store_data[175] 未见过 0 和 1"); end
    if (!(tra_s0_io_out_bits_store_data[176] && tra_s1_io_out_bits_store_data[176])) begin cov_fail++; $display("[COV] TreeArbiter.io_out_bits_store_data[176] 未见过 0 和 1"); end
    if (!(tra_s0_io_out_bits_store_data[177] && tra_s1_io_out_bits_store_data[177])) begin cov_fail++; $display("[COV] TreeArbiter.io_out_bits_store_data[177] 未见过 0 和 1"); end
    if (!(tra_s0_io_out_bits_store_data[178] && tra_s1_io_out_bits_store_data[178])) begin cov_fail++; $display("[COV] TreeArbiter.io_out_bits_store_data[178] 未见过 0 和 1"); end
    if (!(tra_s0_io_out_bits_store_data[179] && tra_s1_io_out_bits_store_data[179])) begin cov_fail++; $display("[COV] TreeArbiter.io_out_bits_store_data[179] 未见过 0 和 1"); end
    if (!(tra_s0_io_out_bits_store_data[180] && tra_s1_io_out_bits_store_data[180])) begin cov_fail++; $display("[COV] TreeArbiter.io_out_bits_store_data[180] 未见过 0 和 1"); end
    if (!(tra_s0_io_out_bits_store_data[181] && tra_s1_io_out_bits_store_data[181])) begin cov_fail++; $display("[COV] TreeArbiter.io_out_bits_store_data[181] 未见过 0 和 1"); end
    if (!(tra_s0_io_out_bits_store_data[182] && tra_s1_io_out_bits_store_data[182])) begin cov_fail++; $display("[COV] TreeArbiter.io_out_bits_store_data[182] 未见过 0 和 1"); end
    if (!(tra_s0_io_out_bits_store_data[183] && tra_s1_io_out_bits_store_data[183])) begin cov_fail++; $display("[COV] TreeArbiter.io_out_bits_store_data[183] 未见过 0 和 1"); end
    if (!(tra_s0_io_out_bits_store_data[184] && tra_s1_io_out_bits_store_data[184])) begin cov_fail++; $display("[COV] TreeArbiter.io_out_bits_store_data[184] 未见过 0 和 1"); end
    if (!(tra_s0_io_out_bits_store_data[185] && tra_s1_io_out_bits_store_data[185])) begin cov_fail++; $display("[COV] TreeArbiter.io_out_bits_store_data[185] 未见过 0 和 1"); end
    if (!(tra_s0_io_out_bits_store_data[186] && tra_s1_io_out_bits_store_data[186])) begin cov_fail++; $display("[COV] TreeArbiter.io_out_bits_store_data[186] 未见过 0 和 1"); end
    if (!(tra_s0_io_out_bits_store_data[187] && tra_s1_io_out_bits_store_data[187])) begin cov_fail++; $display("[COV] TreeArbiter.io_out_bits_store_data[187] 未见过 0 和 1"); end
    if (!(tra_s0_io_out_bits_store_data[188] && tra_s1_io_out_bits_store_data[188])) begin cov_fail++; $display("[COV] TreeArbiter.io_out_bits_store_data[188] 未见过 0 和 1"); end
    if (!(tra_s0_io_out_bits_store_data[189] && tra_s1_io_out_bits_store_data[189])) begin cov_fail++; $display("[COV] TreeArbiter.io_out_bits_store_data[189] 未见过 0 和 1"); end
    if (!(tra_s0_io_out_bits_store_data[190] && tra_s1_io_out_bits_store_data[190])) begin cov_fail++; $display("[COV] TreeArbiter.io_out_bits_store_data[190] 未见过 0 和 1"); end
    if (!(tra_s0_io_out_bits_store_data[191] && tra_s1_io_out_bits_store_data[191])) begin cov_fail++; $display("[COV] TreeArbiter.io_out_bits_store_data[191] 未见过 0 和 1"); end
    if (!(tra_s0_io_out_bits_store_data[192] && tra_s1_io_out_bits_store_data[192])) begin cov_fail++; $display("[COV] TreeArbiter.io_out_bits_store_data[192] 未见过 0 和 1"); end
    if (!(tra_s0_io_out_bits_store_data[193] && tra_s1_io_out_bits_store_data[193])) begin cov_fail++; $display("[COV] TreeArbiter.io_out_bits_store_data[193] 未见过 0 和 1"); end
    if (!(tra_s0_io_out_bits_store_data[194] && tra_s1_io_out_bits_store_data[194])) begin cov_fail++; $display("[COV] TreeArbiter.io_out_bits_store_data[194] 未见过 0 和 1"); end
    if (!(tra_s0_io_out_bits_store_data[195] && tra_s1_io_out_bits_store_data[195])) begin cov_fail++; $display("[COV] TreeArbiter.io_out_bits_store_data[195] 未见过 0 和 1"); end
    if (!(tra_s0_io_out_bits_store_data[196] && tra_s1_io_out_bits_store_data[196])) begin cov_fail++; $display("[COV] TreeArbiter.io_out_bits_store_data[196] 未见过 0 和 1"); end
    if (!(tra_s0_io_out_bits_store_data[197] && tra_s1_io_out_bits_store_data[197])) begin cov_fail++; $display("[COV] TreeArbiter.io_out_bits_store_data[197] 未见过 0 和 1"); end
    if (!(tra_s0_io_out_bits_store_data[198] && tra_s1_io_out_bits_store_data[198])) begin cov_fail++; $display("[COV] TreeArbiter.io_out_bits_store_data[198] 未见过 0 和 1"); end
    if (!(tra_s0_io_out_bits_store_data[199] && tra_s1_io_out_bits_store_data[199])) begin cov_fail++; $display("[COV] TreeArbiter.io_out_bits_store_data[199] 未见过 0 和 1"); end
    if (!(tra_s0_io_out_bits_store_data[200] && tra_s1_io_out_bits_store_data[200])) begin cov_fail++; $display("[COV] TreeArbiter.io_out_bits_store_data[200] 未见过 0 和 1"); end
    if (!(tra_s0_io_out_bits_store_data[201] && tra_s1_io_out_bits_store_data[201])) begin cov_fail++; $display("[COV] TreeArbiter.io_out_bits_store_data[201] 未见过 0 和 1"); end
    if (!(tra_s0_io_out_bits_store_data[202] && tra_s1_io_out_bits_store_data[202])) begin cov_fail++; $display("[COV] TreeArbiter.io_out_bits_store_data[202] 未见过 0 和 1"); end
    if (!(tra_s0_io_out_bits_store_data[203] && tra_s1_io_out_bits_store_data[203])) begin cov_fail++; $display("[COV] TreeArbiter.io_out_bits_store_data[203] 未见过 0 和 1"); end
    if (!(tra_s0_io_out_bits_store_data[204] && tra_s1_io_out_bits_store_data[204])) begin cov_fail++; $display("[COV] TreeArbiter.io_out_bits_store_data[204] 未见过 0 和 1"); end
    if (!(tra_s0_io_out_bits_store_data[205] && tra_s1_io_out_bits_store_data[205])) begin cov_fail++; $display("[COV] TreeArbiter.io_out_bits_store_data[205] 未见过 0 和 1"); end
    if (!(tra_s0_io_out_bits_store_data[206] && tra_s1_io_out_bits_store_data[206])) begin cov_fail++; $display("[COV] TreeArbiter.io_out_bits_store_data[206] 未见过 0 和 1"); end
    if (!(tra_s0_io_out_bits_store_data[207] && tra_s1_io_out_bits_store_data[207])) begin cov_fail++; $display("[COV] TreeArbiter.io_out_bits_store_data[207] 未见过 0 和 1"); end
    if (!(tra_s0_io_out_bits_store_data[208] && tra_s1_io_out_bits_store_data[208])) begin cov_fail++; $display("[COV] TreeArbiter.io_out_bits_store_data[208] 未见过 0 和 1"); end
    if (!(tra_s0_io_out_bits_store_data[209] && tra_s1_io_out_bits_store_data[209])) begin cov_fail++; $display("[COV] TreeArbiter.io_out_bits_store_data[209] 未见过 0 和 1"); end
    if (!(tra_s0_io_out_bits_store_data[210] && tra_s1_io_out_bits_store_data[210])) begin cov_fail++; $display("[COV] TreeArbiter.io_out_bits_store_data[210] 未见过 0 和 1"); end
    if (!(tra_s0_io_out_bits_store_data[211] && tra_s1_io_out_bits_store_data[211])) begin cov_fail++; $display("[COV] TreeArbiter.io_out_bits_store_data[211] 未见过 0 和 1"); end
    if (!(tra_s0_io_out_bits_store_data[212] && tra_s1_io_out_bits_store_data[212])) begin cov_fail++; $display("[COV] TreeArbiter.io_out_bits_store_data[212] 未见过 0 和 1"); end
    if (!(tra_s0_io_out_bits_store_data[213] && tra_s1_io_out_bits_store_data[213])) begin cov_fail++; $display("[COV] TreeArbiter.io_out_bits_store_data[213] 未见过 0 和 1"); end
    if (!(tra_s0_io_out_bits_store_data[214] && tra_s1_io_out_bits_store_data[214])) begin cov_fail++; $display("[COV] TreeArbiter.io_out_bits_store_data[214] 未见过 0 和 1"); end
    if (!(tra_s0_io_out_bits_store_data[215] && tra_s1_io_out_bits_store_data[215])) begin cov_fail++; $display("[COV] TreeArbiter.io_out_bits_store_data[215] 未见过 0 和 1"); end
    if (!(tra_s0_io_out_bits_store_data[216] && tra_s1_io_out_bits_store_data[216])) begin cov_fail++; $display("[COV] TreeArbiter.io_out_bits_store_data[216] 未见过 0 和 1"); end
    if (!(tra_s0_io_out_bits_store_data[217] && tra_s1_io_out_bits_store_data[217])) begin cov_fail++; $display("[COV] TreeArbiter.io_out_bits_store_data[217] 未见过 0 和 1"); end
    if (!(tra_s0_io_out_bits_store_data[218] && tra_s1_io_out_bits_store_data[218])) begin cov_fail++; $display("[COV] TreeArbiter.io_out_bits_store_data[218] 未见过 0 和 1"); end
    if (!(tra_s0_io_out_bits_store_data[219] && tra_s1_io_out_bits_store_data[219])) begin cov_fail++; $display("[COV] TreeArbiter.io_out_bits_store_data[219] 未见过 0 和 1"); end
    if (!(tra_s0_io_out_bits_store_data[220] && tra_s1_io_out_bits_store_data[220])) begin cov_fail++; $display("[COV] TreeArbiter.io_out_bits_store_data[220] 未见过 0 和 1"); end
    if (!(tra_s0_io_out_bits_store_data[221] && tra_s1_io_out_bits_store_data[221])) begin cov_fail++; $display("[COV] TreeArbiter.io_out_bits_store_data[221] 未见过 0 和 1"); end
    if (!(tra_s0_io_out_bits_store_data[222] && tra_s1_io_out_bits_store_data[222])) begin cov_fail++; $display("[COV] TreeArbiter.io_out_bits_store_data[222] 未见过 0 和 1"); end
    if (!(tra_s0_io_out_bits_store_data[223] && tra_s1_io_out_bits_store_data[223])) begin cov_fail++; $display("[COV] TreeArbiter.io_out_bits_store_data[223] 未见过 0 和 1"); end
    if (!(tra_s0_io_out_bits_store_data[224] && tra_s1_io_out_bits_store_data[224])) begin cov_fail++; $display("[COV] TreeArbiter.io_out_bits_store_data[224] 未见过 0 和 1"); end
    if (!(tra_s0_io_out_bits_store_data[225] && tra_s1_io_out_bits_store_data[225])) begin cov_fail++; $display("[COV] TreeArbiter.io_out_bits_store_data[225] 未见过 0 和 1"); end
    if (!(tra_s0_io_out_bits_store_data[226] && tra_s1_io_out_bits_store_data[226])) begin cov_fail++; $display("[COV] TreeArbiter.io_out_bits_store_data[226] 未见过 0 和 1"); end
    if (!(tra_s0_io_out_bits_store_data[227] && tra_s1_io_out_bits_store_data[227])) begin cov_fail++; $display("[COV] TreeArbiter.io_out_bits_store_data[227] 未见过 0 和 1"); end
    if (!(tra_s0_io_out_bits_store_data[228] && tra_s1_io_out_bits_store_data[228])) begin cov_fail++; $display("[COV] TreeArbiter.io_out_bits_store_data[228] 未见过 0 和 1"); end
    if (!(tra_s0_io_out_bits_store_data[229] && tra_s1_io_out_bits_store_data[229])) begin cov_fail++; $display("[COV] TreeArbiter.io_out_bits_store_data[229] 未见过 0 和 1"); end
    if (!(tra_s0_io_out_bits_store_data[230] && tra_s1_io_out_bits_store_data[230])) begin cov_fail++; $display("[COV] TreeArbiter.io_out_bits_store_data[230] 未见过 0 和 1"); end
    if (!(tra_s0_io_out_bits_store_data[231] && tra_s1_io_out_bits_store_data[231])) begin cov_fail++; $display("[COV] TreeArbiter.io_out_bits_store_data[231] 未见过 0 和 1"); end
    if (!(tra_s0_io_out_bits_store_data[232] && tra_s1_io_out_bits_store_data[232])) begin cov_fail++; $display("[COV] TreeArbiter.io_out_bits_store_data[232] 未见过 0 和 1"); end
    if (!(tra_s0_io_out_bits_store_data[233] && tra_s1_io_out_bits_store_data[233])) begin cov_fail++; $display("[COV] TreeArbiter.io_out_bits_store_data[233] 未见过 0 和 1"); end
    if (!(tra_s0_io_out_bits_store_data[234] && tra_s1_io_out_bits_store_data[234])) begin cov_fail++; $display("[COV] TreeArbiter.io_out_bits_store_data[234] 未见过 0 和 1"); end
    if (!(tra_s0_io_out_bits_store_data[235] && tra_s1_io_out_bits_store_data[235])) begin cov_fail++; $display("[COV] TreeArbiter.io_out_bits_store_data[235] 未见过 0 和 1"); end
    if (!(tra_s0_io_out_bits_store_data[236] && tra_s1_io_out_bits_store_data[236])) begin cov_fail++; $display("[COV] TreeArbiter.io_out_bits_store_data[236] 未见过 0 和 1"); end
    if (!(tra_s0_io_out_bits_store_data[237] && tra_s1_io_out_bits_store_data[237])) begin cov_fail++; $display("[COV] TreeArbiter.io_out_bits_store_data[237] 未见过 0 和 1"); end
    if (!(tra_s0_io_out_bits_store_data[238] && tra_s1_io_out_bits_store_data[238])) begin cov_fail++; $display("[COV] TreeArbiter.io_out_bits_store_data[238] 未见过 0 和 1"); end
    if (!(tra_s0_io_out_bits_store_data[239] && tra_s1_io_out_bits_store_data[239])) begin cov_fail++; $display("[COV] TreeArbiter.io_out_bits_store_data[239] 未见过 0 和 1"); end
    if (!(tra_s0_io_out_bits_store_data[240] && tra_s1_io_out_bits_store_data[240])) begin cov_fail++; $display("[COV] TreeArbiter.io_out_bits_store_data[240] 未见过 0 和 1"); end
    if (!(tra_s0_io_out_bits_store_data[241] && tra_s1_io_out_bits_store_data[241])) begin cov_fail++; $display("[COV] TreeArbiter.io_out_bits_store_data[241] 未见过 0 和 1"); end
    if (!(tra_s0_io_out_bits_store_data[242] && tra_s1_io_out_bits_store_data[242])) begin cov_fail++; $display("[COV] TreeArbiter.io_out_bits_store_data[242] 未见过 0 和 1"); end
    if (!(tra_s0_io_out_bits_store_data[243] && tra_s1_io_out_bits_store_data[243])) begin cov_fail++; $display("[COV] TreeArbiter.io_out_bits_store_data[243] 未见过 0 和 1"); end
    if (!(tra_s0_io_out_bits_store_data[244] && tra_s1_io_out_bits_store_data[244])) begin cov_fail++; $display("[COV] TreeArbiter.io_out_bits_store_data[244] 未见过 0 和 1"); end
    if (!(tra_s0_io_out_bits_store_data[245] && tra_s1_io_out_bits_store_data[245])) begin cov_fail++; $display("[COV] TreeArbiter.io_out_bits_store_data[245] 未见过 0 和 1"); end
    if (!(tra_s0_io_out_bits_store_data[246] && tra_s1_io_out_bits_store_data[246])) begin cov_fail++; $display("[COV] TreeArbiter.io_out_bits_store_data[246] 未见过 0 和 1"); end
    if (!(tra_s0_io_out_bits_store_data[247] && tra_s1_io_out_bits_store_data[247])) begin cov_fail++; $display("[COV] TreeArbiter.io_out_bits_store_data[247] 未见过 0 和 1"); end
    if (!(tra_s0_io_out_bits_store_data[248] && tra_s1_io_out_bits_store_data[248])) begin cov_fail++; $display("[COV] TreeArbiter.io_out_bits_store_data[248] 未见过 0 和 1"); end
    if (!(tra_s0_io_out_bits_store_data[249] && tra_s1_io_out_bits_store_data[249])) begin cov_fail++; $display("[COV] TreeArbiter.io_out_bits_store_data[249] 未见过 0 和 1"); end
    if (!(tra_s0_io_out_bits_store_data[250] && tra_s1_io_out_bits_store_data[250])) begin cov_fail++; $display("[COV] TreeArbiter.io_out_bits_store_data[250] 未见过 0 和 1"); end
    if (!(tra_s0_io_out_bits_store_data[251] && tra_s1_io_out_bits_store_data[251])) begin cov_fail++; $display("[COV] TreeArbiter.io_out_bits_store_data[251] 未见过 0 和 1"); end
    if (!(tra_s0_io_out_bits_store_data[252] && tra_s1_io_out_bits_store_data[252])) begin cov_fail++; $display("[COV] TreeArbiter.io_out_bits_store_data[252] 未见过 0 和 1"); end
    if (!(tra_s0_io_out_bits_store_data[253] && tra_s1_io_out_bits_store_data[253])) begin cov_fail++; $display("[COV] TreeArbiter.io_out_bits_store_data[253] 未见过 0 和 1"); end
    if (!(tra_s0_io_out_bits_store_data[254] && tra_s1_io_out_bits_store_data[254])) begin cov_fail++; $display("[COV] TreeArbiter.io_out_bits_store_data[254] 未见过 0 和 1"); end
    if (!(tra_s0_io_out_bits_store_data[255] && tra_s1_io_out_bits_store_data[255])) begin cov_fail++; $display("[COV] TreeArbiter.io_out_bits_store_data[255] 未见过 0 和 1"); end
    if (!(tra_s0_io_out_bits_store_data[256] && tra_s1_io_out_bits_store_data[256])) begin cov_fail++; $display("[COV] TreeArbiter.io_out_bits_store_data[256] 未见过 0 和 1"); end
    if (!(tra_s0_io_out_bits_store_data[257] && tra_s1_io_out_bits_store_data[257])) begin cov_fail++; $display("[COV] TreeArbiter.io_out_bits_store_data[257] 未见过 0 和 1"); end
    if (!(tra_s0_io_out_bits_store_data[258] && tra_s1_io_out_bits_store_data[258])) begin cov_fail++; $display("[COV] TreeArbiter.io_out_bits_store_data[258] 未见过 0 和 1"); end
    if (!(tra_s0_io_out_bits_store_data[259] && tra_s1_io_out_bits_store_data[259])) begin cov_fail++; $display("[COV] TreeArbiter.io_out_bits_store_data[259] 未见过 0 和 1"); end
    if (!(tra_s0_io_out_bits_store_data[260] && tra_s1_io_out_bits_store_data[260])) begin cov_fail++; $display("[COV] TreeArbiter.io_out_bits_store_data[260] 未见过 0 和 1"); end
    if (!(tra_s0_io_out_bits_store_data[261] && tra_s1_io_out_bits_store_data[261])) begin cov_fail++; $display("[COV] TreeArbiter.io_out_bits_store_data[261] 未见过 0 和 1"); end
    if (!(tra_s0_io_out_bits_store_data[262] && tra_s1_io_out_bits_store_data[262])) begin cov_fail++; $display("[COV] TreeArbiter.io_out_bits_store_data[262] 未见过 0 和 1"); end
    if (!(tra_s0_io_out_bits_store_data[263] && tra_s1_io_out_bits_store_data[263])) begin cov_fail++; $display("[COV] TreeArbiter.io_out_bits_store_data[263] 未见过 0 和 1"); end
    if (!(tra_s0_io_out_bits_store_data[264] && tra_s1_io_out_bits_store_data[264])) begin cov_fail++; $display("[COV] TreeArbiter.io_out_bits_store_data[264] 未见过 0 和 1"); end
    if (!(tra_s0_io_out_bits_store_data[265] && tra_s1_io_out_bits_store_data[265])) begin cov_fail++; $display("[COV] TreeArbiter.io_out_bits_store_data[265] 未见过 0 和 1"); end
    if (!(tra_s0_io_out_bits_store_data[266] && tra_s1_io_out_bits_store_data[266])) begin cov_fail++; $display("[COV] TreeArbiter.io_out_bits_store_data[266] 未见过 0 和 1"); end
    if (!(tra_s0_io_out_bits_store_data[267] && tra_s1_io_out_bits_store_data[267])) begin cov_fail++; $display("[COV] TreeArbiter.io_out_bits_store_data[267] 未见过 0 和 1"); end
    if (!(tra_s0_io_out_bits_store_data[268] && tra_s1_io_out_bits_store_data[268])) begin cov_fail++; $display("[COV] TreeArbiter.io_out_bits_store_data[268] 未见过 0 和 1"); end
    if (!(tra_s0_io_out_bits_store_data[269] && tra_s1_io_out_bits_store_data[269])) begin cov_fail++; $display("[COV] TreeArbiter.io_out_bits_store_data[269] 未见过 0 和 1"); end
    if (!(tra_s0_io_out_bits_store_data[270] && tra_s1_io_out_bits_store_data[270])) begin cov_fail++; $display("[COV] TreeArbiter.io_out_bits_store_data[270] 未见过 0 和 1"); end
    if (!(tra_s0_io_out_bits_store_data[271] && tra_s1_io_out_bits_store_data[271])) begin cov_fail++; $display("[COV] TreeArbiter.io_out_bits_store_data[271] 未见过 0 和 1"); end
    if (!(tra_s0_io_out_bits_store_data[272] && tra_s1_io_out_bits_store_data[272])) begin cov_fail++; $display("[COV] TreeArbiter.io_out_bits_store_data[272] 未见过 0 和 1"); end
    if (!(tra_s0_io_out_bits_store_data[273] && tra_s1_io_out_bits_store_data[273])) begin cov_fail++; $display("[COV] TreeArbiter.io_out_bits_store_data[273] 未见过 0 和 1"); end
    if (!(tra_s0_io_out_bits_store_data[274] && tra_s1_io_out_bits_store_data[274])) begin cov_fail++; $display("[COV] TreeArbiter.io_out_bits_store_data[274] 未见过 0 和 1"); end
    if (!(tra_s0_io_out_bits_store_data[275] && tra_s1_io_out_bits_store_data[275])) begin cov_fail++; $display("[COV] TreeArbiter.io_out_bits_store_data[275] 未见过 0 和 1"); end
    if (!(tra_s0_io_out_bits_store_data[276] && tra_s1_io_out_bits_store_data[276])) begin cov_fail++; $display("[COV] TreeArbiter.io_out_bits_store_data[276] 未见过 0 和 1"); end
    if (!(tra_s0_io_out_bits_store_data[277] && tra_s1_io_out_bits_store_data[277])) begin cov_fail++; $display("[COV] TreeArbiter.io_out_bits_store_data[277] 未见过 0 和 1"); end
    if (!(tra_s0_io_out_bits_store_data[278] && tra_s1_io_out_bits_store_data[278])) begin cov_fail++; $display("[COV] TreeArbiter.io_out_bits_store_data[278] 未见过 0 和 1"); end
    if (!(tra_s0_io_out_bits_store_data[279] && tra_s1_io_out_bits_store_data[279])) begin cov_fail++; $display("[COV] TreeArbiter.io_out_bits_store_data[279] 未见过 0 和 1"); end
    if (!(tra_s0_io_out_bits_store_data[280] && tra_s1_io_out_bits_store_data[280])) begin cov_fail++; $display("[COV] TreeArbiter.io_out_bits_store_data[280] 未见过 0 和 1"); end
    if (!(tra_s0_io_out_bits_store_data[281] && tra_s1_io_out_bits_store_data[281])) begin cov_fail++; $display("[COV] TreeArbiter.io_out_bits_store_data[281] 未见过 0 和 1"); end
    if (!(tra_s0_io_out_bits_store_data[282] && tra_s1_io_out_bits_store_data[282])) begin cov_fail++; $display("[COV] TreeArbiter.io_out_bits_store_data[282] 未见过 0 和 1"); end
    if (!(tra_s0_io_out_bits_store_data[283] && tra_s1_io_out_bits_store_data[283])) begin cov_fail++; $display("[COV] TreeArbiter.io_out_bits_store_data[283] 未见过 0 和 1"); end
    if (!(tra_s0_io_out_bits_store_data[284] && tra_s1_io_out_bits_store_data[284])) begin cov_fail++; $display("[COV] TreeArbiter.io_out_bits_store_data[284] 未见过 0 和 1"); end
    if (!(tra_s0_io_out_bits_store_data[285] && tra_s1_io_out_bits_store_data[285])) begin cov_fail++; $display("[COV] TreeArbiter.io_out_bits_store_data[285] 未见过 0 和 1"); end
    if (!(tra_s0_io_out_bits_store_data[286] && tra_s1_io_out_bits_store_data[286])) begin cov_fail++; $display("[COV] TreeArbiter.io_out_bits_store_data[286] 未见过 0 和 1"); end
    if (!(tra_s0_io_out_bits_store_data[287] && tra_s1_io_out_bits_store_data[287])) begin cov_fail++; $display("[COV] TreeArbiter.io_out_bits_store_data[287] 未见过 0 和 1"); end
    if (!(tra_s0_io_out_bits_store_data[288] && tra_s1_io_out_bits_store_data[288])) begin cov_fail++; $display("[COV] TreeArbiter.io_out_bits_store_data[288] 未见过 0 和 1"); end
    if (!(tra_s0_io_out_bits_store_data[289] && tra_s1_io_out_bits_store_data[289])) begin cov_fail++; $display("[COV] TreeArbiter.io_out_bits_store_data[289] 未见过 0 和 1"); end
    if (!(tra_s0_io_out_bits_store_data[290] && tra_s1_io_out_bits_store_data[290])) begin cov_fail++; $display("[COV] TreeArbiter.io_out_bits_store_data[290] 未见过 0 和 1"); end
    if (!(tra_s0_io_out_bits_store_data[291] && tra_s1_io_out_bits_store_data[291])) begin cov_fail++; $display("[COV] TreeArbiter.io_out_bits_store_data[291] 未见过 0 和 1"); end
    if (!(tra_s0_io_out_bits_store_data[292] && tra_s1_io_out_bits_store_data[292])) begin cov_fail++; $display("[COV] TreeArbiter.io_out_bits_store_data[292] 未见过 0 和 1"); end
    if (!(tra_s0_io_out_bits_store_data[293] && tra_s1_io_out_bits_store_data[293])) begin cov_fail++; $display("[COV] TreeArbiter.io_out_bits_store_data[293] 未见过 0 和 1"); end
    if (!(tra_s0_io_out_bits_store_data[294] && tra_s1_io_out_bits_store_data[294])) begin cov_fail++; $display("[COV] TreeArbiter.io_out_bits_store_data[294] 未见过 0 和 1"); end
    if (!(tra_s0_io_out_bits_store_data[295] && tra_s1_io_out_bits_store_data[295])) begin cov_fail++; $display("[COV] TreeArbiter.io_out_bits_store_data[295] 未见过 0 和 1"); end
    if (!(tra_s0_io_out_bits_store_data[296] && tra_s1_io_out_bits_store_data[296])) begin cov_fail++; $display("[COV] TreeArbiter.io_out_bits_store_data[296] 未见过 0 和 1"); end
    if (!(tra_s0_io_out_bits_store_data[297] && tra_s1_io_out_bits_store_data[297])) begin cov_fail++; $display("[COV] TreeArbiter.io_out_bits_store_data[297] 未见过 0 和 1"); end
    if (!(tra_s0_io_out_bits_store_data[298] && tra_s1_io_out_bits_store_data[298])) begin cov_fail++; $display("[COV] TreeArbiter.io_out_bits_store_data[298] 未见过 0 和 1"); end
    if (!(tra_s0_io_out_bits_store_data[299] && tra_s1_io_out_bits_store_data[299])) begin cov_fail++; $display("[COV] TreeArbiter.io_out_bits_store_data[299] 未见过 0 和 1"); end
    if (!(tra_s0_io_out_bits_store_data[300] && tra_s1_io_out_bits_store_data[300])) begin cov_fail++; $display("[COV] TreeArbiter.io_out_bits_store_data[300] 未见过 0 和 1"); end
    if (!(tra_s0_io_out_bits_store_data[301] && tra_s1_io_out_bits_store_data[301])) begin cov_fail++; $display("[COV] TreeArbiter.io_out_bits_store_data[301] 未见过 0 和 1"); end
    if (!(tra_s0_io_out_bits_store_data[302] && tra_s1_io_out_bits_store_data[302])) begin cov_fail++; $display("[COV] TreeArbiter.io_out_bits_store_data[302] 未见过 0 和 1"); end
    if (!(tra_s0_io_out_bits_store_data[303] && tra_s1_io_out_bits_store_data[303])) begin cov_fail++; $display("[COV] TreeArbiter.io_out_bits_store_data[303] 未见过 0 和 1"); end
    if (!(tra_s0_io_out_bits_store_data[304] && tra_s1_io_out_bits_store_data[304])) begin cov_fail++; $display("[COV] TreeArbiter.io_out_bits_store_data[304] 未见过 0 和 1"); end
    if (!(tra_s0_io_out_bits_store_data[305] && tra_s1_io_out_bits_store_data[305])) begin cov_fail++; $display("[COV] TreeArbiter.io_out_bits_store_data[305] 未见过 0 和 1"); end
    if (!(tra_s0_io_out_bits_store_data[306] && tra_s1_io_out_bits_store_data[306])) begin cov_fail++; $display("[COV] TreeArbiter.io_out_bits_store_data[306] 未见过 0 和 1"); end
    if (!(tra_s0_io_out_bits_store_data[307] && tra_s1_io_out_bits_store_data[307])) begin cov_fail++; $display("[COV] TreeArbiter.io_out_bits_store_data[307] 未见过 0 和 1"); end
    if (!(tra_s0_io_out_bits_store_data[308] && tra_s1_io_out_bits_store_data[308])) begin cov_fail++; $display("[COV] TreeArbiter.io_out_bits_store_data[308] 未见过 0 和 1"); end
    if (!(tra_s0_io_out_bits_store_data[309] && tra_s1_io_out_bits_store_data[309])) begin cov_fail++; $display("[COV] TreeArbiter.io_out_bits_store_data[309] 未见过 0 和 1"); end
    if (!(tra_s0_io_out_bits_store_data[310] && tra_s1_io_out_bits_store_data[310])) begin cov_fail++; $display("[COV] TreeArbiter.io_out_bits_store_data[310] 未见过 0 和 1"); end
    if (!(tra_s0_io_out_bits_store_data[311] && tra_s1_io_out_bits_store_data[311])) begin cov_fail++; $display("[COV] TreeArbiter.io_out_bits_store_data[311] 未见过 0 和 1"); end
    if (!(tra_s0_io_out_bits_store_data[312] && tra_s1_io_out_bits_store_data[312])) begin cov_fail++; $display("[COV] TreeArbiter.io_out_bits_store_data[312] 未见过 0 和 1"); end
    if (!(tra_s0_io_out_bits_store_data[313] && tra_s1_io_out_bits_store_data[313])) begin cov_fail++; $display("[COV] TreeArbiter.io_out_bits_store_data[313] 未见过 0 和 1"); end
    if (!(tra_s0_io_out_bits_store_data[314] && tra_s1_io_out_bits_store_data[314])) begin cov_fail++; $display("[COV] TreeArbiter.io_out_bits_store_data[314] 未见过 0 和 1"); end
    if (!(tra_s0_io_out_bits_store_data[315] && tra_s1_io_out_bits_store_data[315])) begin cov_fail++; $display("[COV] TreeArbiter.io_out_bits_store_data[315] 未见过 0 和 1"); end
    if (!(tra_s0_io_out_bits_store_data[316] && tra_s1_io_out_bits_store_data[316])) begin cov_fail++; $display("[COV] TreeArbiter.io_out_bits_store_data[316] 未见过 0 和 1"); end
    if (!(tra_s0_io_out_bits_store_data[317] && tra_s1_io_out_bits_store_data[317])) begin cov_fail++; $display("[COV] TreeArbiter.io_out_bits_store_data[317] 未见过 0 和 1"); end
    if (!(tra_s0_io_out_bits_store_data[318] && tra_s1_io_out_bits_store_data[318])) begin cov_fail++; $display("[COV] TreeArbiter.io_out_bits_store_data[318] 未见过 0 和 1"); end
    if (!(tra_s0_io_out_bits_store_data[319] && tra_s1_io_out_bits_store_data[319])) begin cov_fail++; $display("[COV] TreeArbiter.io_out_bits_store_data[319] 未见过 0 和 1"); end
    if (!(tra_s0_io_out_bits_store_data[320] && tra_s1_io_out_bits_store_data[320])) begin cov_fail++; $display("[COV] TreeArbiter.io_out_bits_store_data[320] 未见过 0 和 1"); end
    if (!(tra_s0_io_out_bits_store_data[321] && tra_s1_io_out_bits_store_data[321])) begin cov_fail++; $display("[COV] TreeArbiter.io_out_bits_store_data[321] 未见过 0 和 1"); end
    if (!(tra_s0_io_out_bits_store_data[322] && tra_s1_io_out_bits_store_data[322])) begin cov_fail++; $display("[COV] TreeArbiter.io_out_bits_store_data[322] 未见过 0 和 1"); end
    if (!(tra_s0_io_out_bits_store_data[323] && tra_s1_io_out_bits_store_data[323])) begin cov_fail++; $display("[COV] TreeArbiter.io_out_bits_store_data[323] 未见过 0 和 1"); end
    if (!(tra_s0_io_out_bits_store_data[324] && tra_s1_io_out_bits_store_data[324])) begin cov_fail++; $display("[COV] TreeArbiter.io_out_bits_store_data[324] 未见过 0 和 1"); end
    if (!(tra_s0_io_out_bits_store_data[325] && tra_s1_io_out_bits_store_data[325])) begin cov_fail++; $display("[COV] TreeArbiter.io_out_bits_store_data[325] 未见过 0 和 1"); end
    if (!(tra_s0_io_out_bits_store_data[326] && tra_s1_io_out_bits_store_data[326])) begin cov_fail++; $display("[COV] TreeArbiter.io_out_bits_store_data[326] 未见过 0 和 1"); end
    if (!(tra_s0_io_out_bits_store_data[327] && tra_s1_io_out_bits_store_data[327])) begin cov_fail++; $display("[COV] TreeArbiter.io_out_bits_store_data[327] 未见过 0 和 1"); end
    if (!(tra_s0_io_out_bits_store_data[328] && tra_s1_io_out_bits_store_data[328])) begin cov_fail++; $display("[COV] TreeArbiter.io_out_bits_store_data[328] 未见过 0 和 1"); end
    if (!(tra_s0_io_out_bits_store_data[329] && tra_s1_io_out_bits_store_data[329])) begin cov_fail++; $display("[COV] TreeArbiter.io_out_bits_store_data[329] 未见过 0 和 1"); end
    if (!(tra_s0_io_out_bits_store_data[330] && tra_s1_io_out_bits_store_data[330])) begin cov_fail++; $display("[COV] TreeArbiter.io_out_bits_store_data[330] 未见过 0 和 1"); end
    if (!(tra_s0_io_out_bits_store_data[331] && tra_s1_io_out_bits_store_data[331])) begin cov_fail++; $display("[COV] TreeArbiter.io_out_bits_store_data[331] 未见过 0 和 1"); end
    if (!(tra_s0_io_out_bits_store_data[332] && tra_s1_io_out_bits_store_data[332])) begin cov_fail++; $display("[COV] TreeArbiter.io_out_bits_store_data[332] 未见过 0 和 1"); end
    if (!(tra_s0_io_out_bits_store_data[333] && tra_s1_io_out_bits_store_data[333])) begin cov_fail++; $display("[COV] TreeArbiter.io_out_bits_store_data[333] 未见过 0 和 1"); end
    if (!(tra_s0_io_out_bits_store_data[334] && tra_s1_io_out_bits_store_data[334])) begin cov_fail++; $display("[COV] TreeArbiter.io_out_bits_store_data[334] 未见过 0 和 1"); end
    if (!(tra_s0_io_out_bits_store_data[335] && tra_s1_io_out_bits_store_data[335])) begin cov_fail++; $display("[COV] TreeArbiter.io_out_bits_store_data[335] 未见过 0 和 1"); end
    if (!(tra_s0_io_out_bits_store_data[336] && tra_s1_io_out_bits_store_data[336])) begin cov_fail++; $display("[COV] TreeArbiter.io_out_bits_store_data[336] 未见过 0 和 1"); end
    if (!(tra_s0_io_out_bits_store_data[337] && tra_s1_io_out_bits_store_data[337])) begin cov_fail++; $display("[COV] TreeArbiter.io_out_bits_store_data[337] 未见过 0 和 1"); end
    if (!(tra_s0_io_out_bits_store_data[338] && tra_s1_io_out_bits_store_data[338])) begin cov_fail++; $display("[COV] TreeArbiter.io_out_bits_store_data[338] 未见过 0 和 1"); end
    if (!(tra_s0_io_out_bits_store_data[339] && tra_s1_io_out_bits_store_data[339])) begin cov_fail++; $display("[COV] TreeArbiter.io_out_bits_store_data[339] 未见过 0 和 1"); end
    if (!(tra_s0_io_out_bits_store_data[340] && tra_s1_io_out_bits_store_data[340])) begin cov_fail++; $display("[COV] TreeArbiter.io_out_bits_store_data[340] 未见过 0 和 1"); end
    if (!(tra_s0_io_out_bits_store_data[341] && tra_s1_io_out_bits_store_data[341])) begin cov_fail++; $display("[COV] TreeArbiter.io_out_bits_store_data[341] 未见过 0 和 1"); end
    if (!(tra_s0_io_out_bits_store_data[342] && tra_s1_io_out_bits_store_data[342])) begin cov_fail++; $display("[COV] TreeArbiter.io_out_bits_store_data[342] 未见过 0 和 1"); end
    if (!(tra_s0_io_out_bits_store_data[343] && tra_s1_io_out_bits_store_data[343])) begin cov_fail++; $display("[COV] TreeArbiter.io_out_bits_store_data[343] 未见过 0 和 1"); end
    if (!(tra_s0_io_out_bits_store_data[344] && tra_s1_io_out_bits_store_data[344])) begin cov_fail++; $display("[COV] TreeArbiter.io_out_bits_store_data[344] 未见过 0 和 1"); end
    if (!(tra_s0_io_out_bits_store_data[345] && tra_s1_io_out_bits_store_data[345])) begin cov_fail++; $display("[COV] TreeArbiter.io_out_bits_store_data[345] 未见过 0 和 1"); end
    if (!(tra_s0_io_out_bits_store_data[346] && tra_s1_io_out_bits_store_data[346])) begin cov_fail++; $display("[COV] TreeArbiter.io_out_bits_store_data[346] 未见过 0 和 1"); end
    if (!(tra_s0_io_out_bits_store_data[347] && tra_s1_io_out_bits_store_data[347])) begin cov_fail++; $display("[COV] TreeArbiter.io_out_bits_store_data[347] 未见过 0 和 1"); end
    if (!(tra_s0_io_out_bits_store_data[348] && tra_s1_io_out_bits_store_data[348])) begin cov_fail++; $display("[COV] TreeArbiter.io_out_bits_store_data[348] 未见过 0 和 1"); end
    if (!(tra_s0_io_out_bits_store_data[349] && tra_s1_io_out_bits_store_data[349])) begin cov_fail++; $display("[COV] TreeArbiter.io_out_bits_store_data[349] 未见过 0 和 1"); end
    if (!(tra_s0_io_out_bits_store_data[350] && tra_s1_io_out_bits_store_data[350])) begin cov_fail++; $display("[COV] TreeArbiter.io_out_bits_store_data[350] 未见过 0 和 1"); end
    if (!(tra_s0_io_out_bits_store_data[351] && tra_s1_io_out_bits_store_data[351])) begin cov_fail++; $display("[COV] TreeArbiter.io_out_bits_store_data[351] 未见过 0 和 1"); end
    if (!(tra_s0_io_out_bits_store_data[352] && tra_s1_io_out_bits_store_data[352])) begin cov_fail++; $display("[COV] TreeArbiter.io_out_bits_store_data[352] 未见过 0 和 1"); end
    if (!(tra_s0_io_out_bits_store_data[353] && tra_s1_io_out_bits_store_data[353])) begin cov_fail++; $display("[COV] TreeArbiter.io_out_bits_store_data[353] 未见过 0 和 1"); end
    if (!(tra_s0_io_out_bits_store_data[354] && tra_s1_io_out_bits_store_data[354])) begin cov_fail++; $display("[COV] TreeArbiter.io_out_bits_store_data[354] 未见过 0 和 1"); end
    if (!(tra_s0_io_out_bits_store_data[355] && tra_s1_io_out_bits_store_data[355])) begin cov_fail++; $display("[COV] TreeArbiter.io_out_bits_store_data[355] 未见过 0 和 1"); end
    if (!(tra_s0_io_out_bits_store_data[356] && tra_s1_io_out_bits_store_data[356])) begin cov_fail++; $display("[COV] TreeArbiter.io_out_bits_store_data[356] 未见过 0 和 1"); end
    if (!(tra_s0_io_out_bits_store_data[357] && tra_s1_io_out_bits_store_data[357])) begin cov_fail++; $display("[COV] TreeArbiter.io_out_bits_store_data[357] 未见过 0 和 1"); end
    if (!(tra_s0_io_out_bits_store_data[358] && tra_s1_io_out_bits_store_data[358])) begin cov_fail++; $display("[COV] TreeArbiter.io_out_bits_store_data[358] 未见过 0 和 1"); end
    if (!(tra_s0_io_out_bits_store_data[359] && tra_s1_io_out_bits_store_data[359])) begin cov_fail++; $display("[COV] TreeArbiter.io_out_bits_store_data[359] 未见过 0 和 1"); end
    if (!(tra_s0_io_out_bits_store_data[360] && tra_s1_io_out_bits_store_data[360])) begin cov_fail++; $display("[COV] TreeArbiter.io_out_bits_store_data[360] 未见过 0 和 1"); end
    if (!(tra_s0_io_out_bits_store_data[361] && tra_s1_io_out_bits_store_data[361])) begin cov_fail++; $display("[COV] TreeArbiter.io_out_bits_store_data[361] 未见过 0 和 1"); end
    if (!(tra_s0_io_out_bits_store_data[362] && tra_s1_io_out_bits_store_data[362])) begin cov_fail++; $display("[COV] TreeArbiter.io_out_bits_store_data[362] 未见过 0 和 1"); end
    if (!(tra_s0_io_out_bits_store_data[363] && tra_s1_io_out_bits_store_data[363])) begin cov_fail++; $display("[COV] TreeArbiter.io_out_bits_store_data[363] 未见过 0 和 1"); end
    if (!(tra_s0_io_out_bits_store_data[364] && tra_s1_io_out_bits_store_data[364])) begin cov_fail++; $display("[COV] TreeArbiter.io_out_bits_store_data[364] 未见过 0 和 1"); end
    if (!(tra_s0_io_out_bits_store_data[365] && tra_s1_io_out_bits_store_data[365])) begin cov_fail++; $display("[COV] TreeArbiter.io_out_bits_store_data[365] 未见过 0 和 1"); end
    if (!(tra_s0_io_out_bits_store_data[366] && tra_s1_io_out_bits_store_data[366])) begin cov_fail++; $display("[COV] TreeArbiter.io_out_bits_store_data[366] 未见过 0 和 1"); end
    if (!(tra_s0_io_out_bits_store_data[367] && tra_s1_io_out_bits_store_data[367])) begin cov_fail++; $display("[COV] TreeArbiter.io_out_bits_store_data[367] 未见过 0 和 1"); end
    if (!(tra_s0_io_out_bits_store_data[368] && tra_s1_io_out_bits_store_data[368])) begin cov_fail++; $display("[COV] TreeArbiter.io_out_bits_store_data[368] 未见过 0 和 1"); end
    if (!(tra_s0_io_out_bits_store_data[369] && tra_s1_io_out_bits_store_data[369])) begin cov_fail++; $display("[COV] TreeArbiter.io_out_bits_store_data[369] 未见过 0 和 1"); end
    if (!(tra_s0_io_out_bits_store_data[370] && tra_s1_io_out_bits_store_data[370])) begin cov_fail++; $display("[COV] TreeArbiter.io_out_bits_store_data[370] 未见过 0 和 1"); end
    if (!(tra_s0_io_out_bits_store_data[371] && tra_s1_io_out_bits_store_data[371])) begin cov_fail++; $display("[COV] TreeArbiter.io_out_bits_store_data[371] 未见过 0 和 1"); end
    if (!(tra_s0_io_out_bits_store_data[372] && tra_s1_io_out_bits_store_data[372])) begin cov_fail++; $display("[COV] TreeArbiter.io_out_bits_store_data[372] 未见过 0 和 1"); end
    if (!(tra_s0_io_out_bits_store_data[373] && tra_s1_io_out_bits_store_data[373])) begin cov_fail++; $display("[COV] TreeArbiter.io_out_bits_store_data[373] 未见过 0 和 1"); end
    if (!(tra_s0_io_out_bits_store_data[374] && tra_s1_io_out_bits_store_data[374])) begin cov_fail++; $display("[COV] TreeArbiter.io_out_bits_store_data[374] 未见过 0 和 1"); end
    if (!(tra_s0_io_out_bits_store_data[375] && tra_s1_io_out_bits_store_data[375])) begin cov_fail++; $display("[COV] TreeArbiter.io_out_bits_store_data[375] 未见过 0 和 1"); end
    if (!(tra_s0_io_out_bits_store_data[376] && tra_s1_io_out_bits_store_data[376])) begin cov_fail++; $display("[COV] TreeArbiter.io_out_bits_store_data[376] 未见过 0 和 1"); end
    if (!(tra_s0_io_out_bits_store_data[377] && tra_s1_io_out_bits_store_data[377])) begin cov_fail++; $display("[COV] TreeArbiter.io_out_bits_store_data[377] 未见过 0 和 1"); end
    if (!(tra_s0_io_out_bits_store_data[378] && tra_s1_io_out_bits_store_data[378])) begin cov_fail++; $display("[COV] TreeArbiter.io_out_bits_store_data[378] 未见过 0 和 1"); end
    if (!(tra_s0_io_out_bits_store_data[379] && tra_s1_io_out_bits_store_data[379])) begin cov_fail++; $display("[COV] TreeArbiter.io_out_bits_store_data[379] 未见过 0 和 1"); end
    if (!(tra_s0_io_out_bits_store_data[380] && tra_s1_io_out_bits_store_data[380])) begin cov_fail++; $display("[COV] TreeArbiter.io_out_bits_store_data[380] 未见过 0 和 1"); end
    if (!(tra_s0_io_out_bits_store_data[381] && tra_s1_io_out_bits_store_data[381])) begin cov_fail++; $display("[COV] TreeArbiter.io_out_bits_store_data[381] 未见过 0 和 1"); end
    if (!(tra_s0_io_out_bits_store_data[382] && tra_s1_io_out_bits_store_data[382])) begin cov_fail++; $display("[COV] TreeArbiter.io_out_bits_store_data[382] 未见过 0 和 1"); end
    if (!(tra_s0_io_out_bits_store_data[383] && tra_s1_io_out_bits_store_data[383])) begin cov_fail++; $display("[COV] TreeArbiter.io_out_bits_store_data[383] 未见过 0 和 1"); end
    if (!(tra_s0_io_out_bits_store_data[384] && tra_s1_io_out_bits_store_data[384])) begin cov_fail++; $display("[COV] TreeArbiter.io_out_bits_store_data[384] 未见过 0 和 1"); end
    if (!(tra_s0_io_out_bits_store_data[385] && tra_s1_io_out_bits_store_data[385])) begin cov_fail++; $display("[COV] TreeArbiter.io_out_bits_store_data[385] 未见过 0 和 1"); end
    if (!(tra_s0_io_out_bits_store_data[386] && tra_s1_io_out_bits_store_data[386])) begin cov_fail++; $display("[COV] TreeArbiter.io_out_bits_store_data[386] 未见过 0 和 1"); end
    if (!(tra_s0_io_out_bits_store_data[387] && tra_s1_io_out_bits_store_data[387])) begin cov_fail++; $display("[COV] TreeArbiter.io_out_bits_store_data[387] 未见过 0 和 1"); end
    if (!(tra_s0_io_out_bits_store_data[388] && tra_s1_io_out_bits_store_data[388])) begin cov_fail++; $display("[COV] TreeArbiter.io_out_bits_store_data[388] 未见过 0 和 1"); end
    if (!(tra_s0_io_out_bits_store_data[389] && tra_s1_io_out_bits_store_data[389])) begin cov_fail++; $display("[COV] TreeArbiter.io_out_bits_store_data[389] 未见过 0 和 1"); end
    if (!(tra_s0_io_out_bits_store_data[390] && tra_s1_io_out_bits_store_data[390])) begin cov_fail++; $display("[COV] TreeArbiter.io_out_bits_store_data[390] 未见过 0 和 1"); end
    if (!(tra_s0_io_out_bits_store_data[391] && tra_s1_io_out_bits_store_data[391])) begin cov_fail++; $display("[COV] TreeArbiter.io_out_bits_store_data[391] 未见过 0 和 1"); end
    if (!(tra_s0_io_out_bits_store_data[392] && tra_s1_io_out_bits_store_data[392])) begin cov_fail++; $display("[COV] TreeArbiter.io_out_bits_store_data[392] 未见过 0 和 1"); end
    if (!(tra_s0_io_out_bits_store_data[393] && tra_s1_io_out_bits_store_data[393])) begin cov_fail++; $display("[COV] TreeArbiter.io_out_bits_store_data[393] 未见过 0 和 1"); end
    if (!(tra_s0_io_out_bits_store_data[394] && tra_s1_io_out_bits_store_data[394])) begin cov_fail++; $display("[COV] TreeArbiter.io_out_bits_store_data[394] 未见过 0 和 1"); end
    if (!(tra_s0_io_out_bits_store_data[395] && tra_s1_io_out_bits_store_data[395])) begin cov_fail++; $display("[COV] TreeArbiter.io_out_bits_store_data[395] 未见过 0 和 1"); end
    if (!(tra_s0_io_out_bits_store_data[396] && tra_s1_io_out_bits_store_data[396])) begin cov_fail++; $display("[COV] TreeArbiter.io_out_bits_store_data[396] 未见过 0 和 1"); end
    if (!(tra_s0_io_out_bits_store_data[397] && tra_s1_io_out_bits_store_data[397])) begin cov_fail++; $display("[COV] TreeArbiter.io_out_bits_store_data[397] 未见过 0 和 1"); end
    if (!(tra_s0_io_out_bits_store_data[398] && tra_s1_io_out_bits_store_data[398])) begin cov_fail++; $display("[COV] TreeArbiter.io_out_bits_store_data[398] 未见过 0 和 1"); end
    if (!(tra_s0_io_out_bits_store_data[399] && tra_s1_io_out_bits_store_data[399])) begin cov_fail++; $display("[COV] TreeArbiter.io_out_bits_store_data[399] 未见过 0 和 1"); end
    if (!(tra_s0_io_out_bits_store_data[400] && tra_s1_io_out_bits_store_data[400])) begin cov_fail++; $display("[COV] TreeArbiter.io_out_bits_store_data[400] 未见过 0 和 1"); end
    if (!(tra_s0_io_out_bits_store_data[401] && tra_s1_io_out_bits_store_data[401])) begin cov_fail++; $display("[COV] TreeArbiter.io_out_bits_store_data[401] 未见过 0 和 1"); end
    if (!(tra_s0_io_out_bits_store_data[402] && tra_s1_io_out_bits_store_data[402])) begin cov_fail++; $display("[COV] TreeArbiter.io_out_bits_store_data[402] 未见过 0 和 1"); end
    if (!(tra_s0_io_out_bits_store_data[403] && tra_s1_io_out_bits_store_data[403])) begin cov_fail++; $display("[COV] TreeArbiter.io_out_bits_store_data[403] 未见过 0 和 1"); end
    if (!(tra_s0_io_out_bits_store_data[404] && tra_s1_io_out_bits_store_data[404])) begin cov_fail++; $display("[COV] TreeArbiter.io_out_bits_store_data[404] 未见过 0 和 1"); end
    if (!(tra_s0_io_out_bits_store_data[405] && tra_s1_io_out_bits_store_data[405])) begin cov_fail++; $display("[COV] TreeArbiter.io_out_bits_store_data[405] 未见过 0 和 1"); end
    if (!(tra_s0_io_out_bits_store_data[406] && tra_s1_io_out_bits_store_data[406])) begin cov_fail++; $display("[COV] TreeArbiter.io_out_bits_store_data[406] 未见过 0 和 1"); end
    if (!(tra_s0_io_out_bits_store_data[407] && tra_s1_io_out_bits_store_data[407])) begin cov_fail++; $display("[COV] TreeArbiter.io_out_bits_store_data[407] 未见过 0 和 1"); end
    if (!(tra_s0_io_out_bits_store_data[408] && tra_s1_io_out_bits_store_data[408])) begin cov_fail++; $display("[COV] TreeArbiter.io_out_bits_store_data[408] 未见过 0 和 1"); end
    if (!(tra_s0_io_out_bits_store_data[409] && tra_s1_io_out_bits_store_data[409])) begin cov_fail++; $display("[COV] TreeArbiter.io_out_bits_store_data[409] 未见过 0 和 1"); end
    if (!(tra_s0_io_out_bits_store_data[410] && tra_s1_io_out_bits_store_data[410])) begin cov_fail++; $display("[COV] TreeArbiter.io_out_bits_store_data[410] 未见过 0 和 1"); end
    if (!(tra_s0_io_out_bits_store_data[411] && tra_s1_io_out_bits_store_data[411])) begin cov_fail++; $display("[COV] TreeArbiter.io_out_bits_store_data[411] 未见过 0 和 1"); end
    if (!(tra_s0_io_out_bits_store_data[412] && tra_s1_io_out_bits_store_data[412])) begin cov_fail++; $display("[COV] TreeArbiter.io_out_bits_store_data[412] 未见过 0 和 1"); end
    if (!(tra_s0_io_out_bits_store_data[413] && tra_s1_io_out_bits_store_data[413])) begin cov_fail++; $display("[COV] TreeArbiter.io_out_bits_store_data[413] 未见过 0 和 1"); end
    if (!(tra_s0_io_out_bits_store_data[414] && tra_s1_io_out_bits_store_data[414])) begin cov_fail++; $display("[COV] TreeArbiter.io_out_bits_store_data[414] 未见过 0 和 1"); end
    if (!(tra_s0_io_out_bits_store_data[415] && tra_s1_io_out_bits_store_data[415])) begin cov_fail++; $display("[COV] TreeArbiter.io_out_bits_store_data[415] 未见过 0 和 1"); end
    if (!(tra_s0_io_out_bits_store_data[416] && tra_s1_io_out_bits_store_data[416])) begin cov_fail++; $display("[COV] TreeArbiter.io_out_bits_store_data[416] 未见过 0 和 1"); end
    if (!(tra_s0_io_out_bits_store_data[417] && tra_s1_io_out_bits_store_data[417])) begin cov_fail++; $display("[COV] TreeArbiter.io_out_bits_store_data[417] 未见过 0 和 1"); end
    if (!(tra_s0_io_out_bits_store_data[418] && tra_s1_io_out_bits_store_data[418])) begin cov_fail++; $display("[COV] TreeArbiter.io_out_bits_store_data[418] 未见过 0 和 1"); end
    if (!(tra_s0_io_out_bits_store_data[419] && tra_s1_io_out_bits_store_data[419])) begin cov_fail++; $display("[COV] TreeArbiter.io_out_bits_store_data[419] 未见过 0 和 1"); end
    if (!(tra_s0_io_out_bits_store_data[420] && tra_s1_io_out_bits_store_data[420])) begin cov_fail++; $display("[COV] TreeArbiter.io_out_bits_store_data[420] 未见过 0 和 1"); end
    if (!(tra_s0_io_out_bits_store_data[421] && tra_s1_io_out_bits_store_data[421])) begin cov_fail++; $display("[COV] TreeArbiter.io_out_bits_store_data[421] 未见过 0 和 1"); end
    if (!(tra_s0_io_out_bits_store_data[422] && tra_s1_io_out_bits_store_data[422])) begin cov_fail++; $display("[COV] TreeArbiter.io_out_bits_store_data[422] 未见过 0 和 1"); end
    if (!(tra_s0_io_out_bits_store_data[423] && tra_s1_io_out_bits_store_data[423])) begin cov_fail++; $display("[COV] TreeArbiter.io_out_bits_store_data[423] 未见过 0 和 1"); end
    if (!(tra_s0_io_out_bits_store_data[424] && tra_s1_io_out_bits_store_data[424])) begin cov_fail++; $display("[COV] TreeArbiter.io_out_bits_store_data[424] 未见过 0 和 1"); end
    if (!(tra_s0_io_out_bits_store_data[425] && tra_s1_io_out_bits_store_data[425])) begin cov_fail++; $display("[COV] TreeArbiter.io_out_bits_store_data[425] 未见过 0 和 1"); end
    if (!(tra_s0_io_out_bits_store_data[426] && tra_s1_io_out_bits_store_data[426])) begin cov_fail++; $display("[COV] TreeArbiter.io_out_bits_store_data[426] 未见过 0 和 1"); end
    if (!(tra_s0_io_out_bits_store_data[427] && tra_s1_io_out_bits_store_data[427])) begin cov_fail++; $display("[COV] TreeArbiter.io_out_bits_store_data[427] 未见过 0 和 1"); end
    if (!(tra_s0_io_out_bits_store_data[428] && tra_s1_io_out_bits_store_data[428])) begin cov_fail++; $display("[COV] TreeArbiter.io_out_bits_store_data[428] 未见过 0 和 1"); end
    if (!(tra_s0_io_out_bits_store_data[429] && tra_s1_io_out_bits_store_data[429])) begin cov_fail++; $display("[COV] TreeArbiter.io_out_bits_store_data[429] 未见过 0 和 1"); end
    if (!(tra_s0_io_out_bits_store_data[430] && tra_s1_io_out_bits_store_data[430])) begin cov_fail++; $display("[COV] TreeArbiter.io_out_bits_store_data[430] 未见过 0 和 1"); end
    if (!(tra_s0_io_out_bits_store_data[431] && tra_s1_io_out_bits_store_data[431])) begin cov_fail++; $display("[COV] TreeArbiter.io_out_bits_store_data[431] 未见过 0 和 1"); end
    if (!(tra_s0_io_out_bits_store_data[432] && tra_s1_io_out_bits_store_data[432])) begin cov_fail++; $display("[COV] TreeArbiter.io_out_bits_store_data[432] 未见过 0 和 1"); end
    if (!(tra_s0_io_out_bits_store_data[433] && tra_s1_io_out_bits_store_data[433])) begin cov_fail++; $display("[COV] TreeArbiter.io_out_bits_store_data[433] 未见过 0 和 1"); end
    if (!(tra_s0_io_out_bits_store_data[434] && tra_s1_io_out_bits_store_data[434])) begin cov_fail++; $display("[COV] TreeArbiter.io_out_bits_store_data[434] 未见过 0 和 1"); end
    if (!(tra_s0_io_out_bits_store_data[435] && tra_s1_io_out_bits_store_data[435])) begin cov_fail++; $display("[COV] TreeArbiter.io_out_bits_store_data[435] 未见过 0 和 1"); end
    if (!(tra_s0_io_out_bits_store_data[436] && tra_s1_io_out_bits_store_data[436])) begin cov_fail++; $display("[COV] TreeArbiter.io_out_bits_store_data[436] 未见过 0 和 1"); end
    if (!(tra_s0_io_out_bits_store_data[437] && tra_s1_io_out_bits_store_data[437])) begin cov_fail++; $display("[COV] TreeArbiter.io_out_bits_store_data[437] 未见过 0 和 1"); end
    if (!(tra_s0_io_out_bits_store_data[438] && tra_s1_io_out_bits_store_data[438])) begin cov_fail++; $display("[COV] TreeArbiter.io_out_bits_store_data[438] 未见过 0 和 1"); end
    if (!(tra_s0_io_out_bits_store_data[439] && tra_s1_io_out_bits_store_data[439])) begin cov_fail++; $display("[COV] TreeArbiter.io_out_bits_store_data[439] 未见过 0 和 1"); end
    if (!(tra_s0_io_out_bits_store_data[440] && tra_s1_io_out_bits_store_data[440])) begin cov_fail++; $display("[COV] TreeArbiter.io_out_bits_store_data[440] 未见过 0 和 1"); end
    if (!(tra_s0_io_out_bits_store_data[441] && tra_s1_io_out_bits_store_data[441])) begin cov_fail++; $display("[COV] TreeArbiter.io_out_bits_store_data[441] 未见过 0 和 1"); end
    if (!(tra_s0_io_out_bits_store_data[442] && tra_s1_io_out_bits_store_data[442])) begin cov_fail++; $display("[COV] TreeArbiter.io_out_bits_store_data[442] 未见过 0 和 1"); end
    if (!(tra_s0_io_out_bits_store_data[443] && tra_s1_io_out_bits_store_data[443])) begin cov_fail++; $display("[COV] TreeArbiter.io_out_bits_store_data[443] 未见过 0 和 1"); end
    if (!(tra_s0_io_out_bits_store_data[444] && tra_s1_io_out_bits_store_data[444])) begin cov_fail++; $display("[COV] TreeArbiter.io_out_bits_store_data[444] 未见过 0 和 1"); end
    if (!(tra_s0_io_out_bits_store_data[445] && tra_s1_io_out_bits_store_data[445])) begin cov_fail++; $display("[COV] TreeArbiter.io_out_bits_store_data[445] 未见过 0 和 1"); end
    if (!(tra_s0_io_out_bits_store_data[446] && tra_s1_io_out_bits_store_data[446])) begin cov_fail++; $display("[COV] TreeArbiter.io_out_bits_store_data[446] 未见过 0 和 1"); end
    if (!(tra_s0_io_out_bits_store_data[447] && tra_s1_io_out_bits_store_data[447])) begin cov_fail++; $display("[COV] TreeArbiter.io_out_bits_store_data[447] 未见过 0 和 1"); end
    if (!(tra_s0_io_out_bits_store_data[448] && tra_s1_io_out_bits_store_data[448])) begin cov_fail++; $display("[COV] TreeArbiter.io_out_bits_store_data[448] 未见过 0 和 1"); end
    if (!(tra_s0_io_out_bits_store_data[449] && tra_s1_io_out_bits_store_data[449])) begin cov_fail++; $display("[COV] TreeArbiter.io_out_bits_store_data[449] 未见过 0 和 1"); end
    if (!(tra_s0_io_out_bits_store_data[450] && tra_s1_io_out_bits_store_data[450])) begin cov_fail++; $display("[COV] TreeArbiter.io_out_bits_store_data[450] 未见过 0 和 1"); end
    if (!(tra_s0_io_out_bits_store_data[451] && tra_s1_io_out_bits_store_data[451])) begin cov_fail++; $display("[COV] TreeArbiter.io_out_bits_store_data[451] 未见过 0 和 1"); end
    if (!(tra_s0_io_out_bits_store_data[452] && tra_s1_io_out_bits_store_data[452])) begin cov_fail++; $display("[COV] TreeArbiter.io_out_bits_store_data[452] 未见过 0 和 1"); end
    if (!(tra_s0_io_out_bits_store_data[453] && tra_s1_io_out_bits_store_data[453])) begin cov_fail++; $display("[COV] TreeArbiter.io_out_bits_store_data[453] 未见过 0 和 1"); end
    if (!(tra_s0_io_out_bits_store_data[454] && tra_s1_io_out_bits_store_data[454])) begin cov_fail++; $display("[COV] TreeArbiter.io_out_bits_store_data[454] 未见过 0 和 1"); end
    if (!(tra_s0_io_out_bits_store_data[455] && tra_s1_io_out_bits_store_data[455])) begin cov_fail++; $display("[COV] TreeArbiter.io_out_bits_store_data[455] 未见过 0 和 1"); end
    if (!(tra_s0_io_out_bits_store_data[456] && tra_s1_io_out_bits_store_data[456])) begin cov_fail++; $display("[COV] TreeArbiter.io_out_bits_store_data[456] 未见过 0 和 1"); end
    if (!(tra_s0_io_out_bits_store_data[457] && tra_s1_io_out_bits_store_data[457])) begin cov_fail++; $display("[COV] TreeArbiter.io_out_bits_store_data[457] 未见过 0 和 1"); end
    if (!(tra_s0_io_out_bits_store_data[458] && tra_s1_io_out_bits_store_data[458])) begin cov_fail++; $display("[COV] TreeArbiter.io_out_bits_store_data[458] 未见过 0 和 1"); end
    if (!(tra_s0_io_out_bits_store_data[459] && tra_s1_io_out_bits_store_data[459])) begin cov_fail++; $display("[COV] TreeArbiter.io_out_bits_store_data[459] 未见过 0 和 1"); end
    if (!(tra_s0_io_out_bits_store_data[460] && tra_s1_io_out_bits_store_data[460])) begin cov_fail++; $display("[COV] TreeArbiter.io_out_bits_store_data[460] 未见过 0 和 1"); end
    if (!(tra_s0_io_out_bits_store_data[461] && tra_s1_io_out_bits_store_data[461])) begin cov_fail++; $display("[COV] TreeArbiter.io_out_bits_store_data[461] 未见过 0 和 1"); end
    if (!(tra_s0_io_out_bits_store_data[462] && tra_s1_io_out_bits_store_data[462])) begin cov_fail++; $display("[COV] TreeArbiter.io_out_bits_store_data[462] 未见过 0 和 1"); end
    if (!(tra_s0_io_out_bits_store_data[463] && tra_s1_io_out_bits_store_data[463])) begin cov_fail++; $display("[COV] TreeArbiter.io_out_bits_store_data[463] 未见过 0 和 1"); end
    if (!(tra_s0_io_out_bits_store_data[464] && tra_s1_io_out_bits_store_data[464])) begin cov_fail++; $display("[COV] TreeArbiter.io_out_bits_store_data[464] 未见过 0 和 1"); end
    if (!(tra_s0_io_out_bits_store_data[465] && tra_s1_io_out_bits_store_data[465])) begin cov_fail++; $display("[COV] TreeArbiter.io_out_bits_store_data[465] 未见过 0 和 1"); end
    if (!(tra_s0_io_out_bits_store_data[466] && tra_s1_io_out_bits_store_data[466])) begin cov_fail++; $display("[COV] TreeArbiter.io_out_bits_store_data[466] 未见过 0 和 1"); end
    if (!(tra_s0_io_out_bits_store_data[467] && tra_s1_io_out_bits_store_data[467])) begin cov_fail++; $display("[COV] TreeArbiter.io_out_bits_store_data[467] 未见过 0 和 1"); end
    if (!(tra_s0_io_out_bits_store_data[468] && tra_s1_io_out_bits_store_data[468])) begin cov_fail++; $display("[COV] TreeArbiter.io_out_bits_store_data[468] 未见过 0 和 1"); end
    if (!(tra_s0_io_out_bits_store_data[469] && tra_s1_io_out_bits_store_data[469])) begin cov_fail++; $display("[COV] TreeArbiter.io_out_bits_store_data[469] 未见过 0 和 1"); end
    if (!(tra_s0_io_out_bits_store_data[470] && tra_s1_io_out_bits_store_data[470])) begin cov_fail++; $display("[COV] TreeArbiter.io_out_bits_store_data[470] 未见过 0 和 1"); end
    if (!(tra_s0_io_out_bits_store_data[471] && tra_s1_io_out_bits_store_data[471])) begin cov_fail++; $display("[COV] TreeArbiter.io_out_bits_store_data[471] 未见过 0 和 1"); end
    if (!(tra_s0_io_out_bits_store_data[472] && tra_s1_io_out_bits_store_data[472])) begin cov_fail++; $display("[COV] TreeArbiter.io_out_bits_store_data[472] 未见过 0 和 1"); end
    if (!(tra_s0_io_out_bits_store_data[473] && tra_s1_io_out_bits_store_data[473])) begin cov_fail++; $display("[COV] TreeArbiter.io_out_bits_store_data[473] 未见过 0 和 1"); end
    if (!(tra_s0_io_out_bits_store_data[474] && tra_s1_io_out_bits_store_data[474])) begin cov_fail++; $display("[COV] TreeArbiter.io_out_bits_store_data[474] 未见过 0 和 1"); end
    if (!(tra_s0_io_out_bits_store_data[475] && tra_s1_io_out_bits_store_data[475])) begin cov_fail++; $display("[COV] TreeArbiter.io_out_bits_store_data[475] 未见过 0 和 1"); end
    if (!(tra_s0_io_out_bits_store_data[476] && tra_s1_io_out_bits_store_data[476])) begin cov_fail++; $display("[COV] TreeArbiter.io_out_bits_store_data[476] 未见过 0 和 1"); end
    if (!(tra_s0_io_out_bits_store_data[477] && tra_s1_io_out_bits_store_data[477])) begin cov_fail++; $display("[COV] TreeArbiter.io_out_bits_store_data[477] 未见过 0 和 1"); end
    if (!(tra_s0_io_out_bits_store_data[478] && tra_s1_io_out_bits_store_data[478])) begin cov_fail++; $display("[COV] TreeArbiter.io_out_bits_store_data[478] 未见过 0 和 1"); end
    if (!(tra_s0_io_out_bits_store_data[479] && tra_s1_io_out_bits_store_data[479])) begin cov_fail++; $display("[COV] TreeArbiter.io_out_bits_store_data[479] 未见过 0 和 1"); end
    if (!(tra_s0_io_out_bits_store_data[480] && tra_s1_io_out_bits_store_data[480])) begin cov_fail++; $display("[COV] TreeArbiter.io_out_bits_store_data[480] 未见过 0 和 1"); end
    if (!(tra_s0_io_out_bits_store_data[481] && tra_s1_io_out_bits_store_data[481])) begin cov_fail++; $display("[COV] TreeArbiter.io_out_bits_store_data[481] 未见过 0 和 1"); end
    if (!(tra_s0_io_out_bits_store_data[482] && tra_s1_io_out_bits_store_data[482])) begin cov_fail++; $display("[COV] TreeArbiter.io_out_bits_store_data[482] 未见过 0 和 1"); end
    if (!(tra_s0_io_out_bits_store_data[483] && tra_s1_io_out_bits_store_data[483])) begin cov_fail++; $display("[COV] TreeArbiter.io_out_bits_store_data[483] 未见过 0 和 1"); end
    if (!(tra_s0_io_out_bits_store_data[484] && tra_s1_io_out_bits_store_data[484])) begin cov_fail++; $display("[COV] TreeArbiter.io_out_bits_store_data[484] 未见过 0 和 1"); end
    if (!(tra_s0_io_out_bits_store_data[485] && tra_s1_io_out_bits_store_data[485])) begin cov_fail++; $display("[COV] TreeArbiter.io_out_bits_store_data[485] 未见过 0 和 1"); end
    if (!(tra_s0_io_out_bits_store_data[486] && tra_s1_io_out_bits_store_data[486])) begin cov_fail++; $display("[COV] TreeArbiter.io_out_bits_store_data[486] 未见过 0 和 1"); end
    if (!(tra_s0_io_out_bits_store_data[487] && tra_s1_io_out_bits_store_data[487])) begin cov_fail++; $display("[COV] TreeArbiter.io_out_bits_store_data[487] 未见过 0 和 1"); end
    if (!(tra_s0_io_out_bits_store_data[488] && tra_s1_io_out_bits_store_data[488])) begin cov_fail++; $display("[COV] TreeArbiter.io_out_bits_store_data[488] 未见过 0 和 1"); end
    if (!(tra_s0_io_out_bits_store_data[489] && tra_s1_io_out_bits_store_data[489])) begin cov_fail++; $display("[COV] TreeArbiter.io_out_bits_store_data[489] 未见过 0 和 1"); end
    if (!(tra_s0_io_out_bits_store_data[490] && tra_s1_io_out_bits_store_data[490])) begin cov_fail++; $display("[COV] TreeArbiter.io_out_bits_store_data[490] 未见过 0 和 1"); end
    if (!(tra_s0_io_out_bits_store_data[491] && tra_s1_io_out_bits_store_data[491])) begin cov_fail++; $display("[COV] TreeArbiter.io_out_bits_store_data[491] 未见过 0 和 1"); end
    if (!(tra_s0_io_out_bits_store_data[492] && tra_s1_io_out_bits_store_data[492])) begin cov_fail++; $display("[COV] TreeArbiter.io_out_bits_store_data[492] 未见过 0 和 1"); end
    if (!(tra_s0_io_out_bits_store_data[493] && tra_s1_io_out_bits_store_data[493])) begin cov_fail++; $display("[COV] TreeArbiter.io_out_bits_store_data[493] 未见过 0 和 1"); end
    if (!(tra_s0_io_out_bits_store_data[494] && tra_s1_io_out_bits_store_data[494])) begin cov_fail++; $display("[COV] TreeArbiter.io_out_bits_store_data[494] 未见过 0 和 1"); end
    if (!(tra_s0_io_out_bits_store_data[495] && tra_s1_io_out_bits_store_data[495])) begin cov_fail++; $display("[COV] TreeArbiter.io_out_bits_store_data[495] 未见过 0 和 1"); end
    if (!(tra_s0_io_out_bits_store_data[496] && tra_s1_io_out_bits_store_data[496])) begin cov_fail++; $display("[COV] TreeArbiter.io_out_bits_store_data[496] 未见过 0 和 1"); end
    if (!(tra_s0_io_out_bits_store_data[497] && tra_s1_io_out_bits_store_data[497])) begin cov_fail++; $display("[COV] TreeArbiter.io_out_bits_store_data[497] 未见过 0 和 1"); end
    if (!(tra_s0_io_out_bits_store_data[498] && tra_s1_io_out_bits_store_data[498])) begin cov_fail++; $display("[COV] TreeArbiter.io_out_bits_store_data[498] 未见过 0 和 1"); end
    if (!(tra_s0_io_out_bits_store_data[499] && tra_s1_io_out_bits_store_data[499])) begin cov_fail++; $display("[COV] TreeArbiter.io_out_bits_store_data[499] 未见过 0 和 1"); end
    if (!(tra_s0_io_out_bits_store_data[500] && tra_s1_io_out_bits_store_data[500])) begin cov_fail++; $display("[COV] TreeArbiter.io_out_bits_store_data[500] 未见过 0 和 1"); end
    if (!(tra_s0_io_out_bits_store_data[501] && tra_s1_io_out_bits_store_data[501])) begin cov_fail++; $display("[COV] TreeArbiter.io_out_bits_store_data[501] 未见过 0 和 1"); end
    if (!(tra_s0_io_out_bits_store_data[502] && tra_s1_io_out_bits_store_data[502])) begin cov_fail++; $display("[COV] TreeArbiter.io_out_bits_store_data[502] 未见过 0 和 1"); end
    if (!(tra_s0_io_out_bits_store_data[503] && tra_s1_io_out_bits_store_data[503])) begin cov_fail++; $display("[COV] TreeArbiter.io_out_bits_store_data[503] 未见过 0 和 1"); end
    if (!(tra_s0_io_out_bits_store_data[504] && tra_s1_io_out_bits_store_data[504])) begin cov_fail++; $display("[COV] TreeArbiter.io_out_bits_store_data[504] 未见过 0 和 1"); end
    if (!(tra_s0_io_out_bits_store_data[505] && tra_s1_io_out_bits_store_data[505])) begin cov_fail++; $display("[COV] TreeArbiter.io_out_bits_store_data[505] 未见过 0 和 1"); end
    if (!(tra_s0_io_out_bits_store_data[506] && tra_s1_io_out_bits_store_data[506])) begin cov_fail++; $display("[COV] TreeArbiter.io_out_bits_store_data[506] 未见过 0 和 1"); end
    if (!(tra_s0_io_out_bits_store_data[507] && tra_s1_io_out_bits_store_data[507])) begin cov_fail++; $display("[COV] TreeArbiter.io_out_bits_store_data[507] 未见过 0 和 1"); end
    if (!(tra_s0_io_out_bits_store_data[508] && tra_s1_io_out_bits_store_data[508])) begin cov_fail++; $display("[COV] TreeArbiter.io_out_bits_store_data[508] 未见过 0 和 1"); end
    if (!(tra_s0_io_out_bits_store_data[509] && tra_s1_io_out_bits_store_data[509])) begin cov_fail++; $display("[COV] TreeArbiter.io_out_bits_store_data[509] 未见过 0 和 1"); end
    if (!(tra_s0_io_out_bits_store_data[510] && tra_s1_io_out_bits_store_data[510])) begin cov_fail++; $display("[COV] TreeArbiter.io_out_bits_store_data[510] 未见过 0 和 1"); end
    if (!(tra_s0_io_out_bits_store_data[511] && tra_s1_io_out_bits_store_data[511])) begin cov_fail++; $display("[COV] TreeArbiter.io_out_bits_store_data[511] 未见过 0 和 1"); end
    if (!(tra_s0_io_out_bits_store_mask[0] && tra_s1_io_out_bits_store_mask[0])) begin cov_fail++; $display("[COV] TreeArbiter.io_out_bits_store_mask[0] 未见过 0 和 1"); end
    if (!(tra_s0_io_out_bits_store_mask[1] && tra_s1_io_out_bits_store_mask[1])) begin cov_fail++; $display("[COV] TreeArbiter.io_out_bits_store_mask[1] 未见过 0 和 1"); end
    if (!(tra_s0_io_out_bits_store_mask[2] && tra_s1_io_out_bits_store_mask[2])) begin cov_fail++; $display("[COV] TreeArbiter.io_out_bits_store_mask[2] 未见过 0 和 1"); end
    if (!(tra_s0_io_out_bits_store_mask[3] && tra_s1_io_out_bits_store_mask[3])) begin cov_fail++; $display("[COV] TreeArbiter.io_out_bits_store_mask[3] 未见过 0 和 1"); end
    if (!(tra_s0_io_out_bits_store_mask[4] && tra_s1_io_out_bits_store_mask[4])) begin cov_fail++; $display("[COV] TreeArbiter.io_out_bits_store_mask[4] 未见过 0 和 1"); end
    if (!(tra_s0_io_out_bits_store_mask[5] && tra_s1_io_out_bits_store_mask[5])) begin cov_fail++; $display("[COV] TreeArbiter.io_out_bits_store_mask[5] 未见过 0 和 1"); end
    if (!(tra_s0_io_out_bits_store_mask[6] && tra_s1_io_out_bits_store_mask[6])) begin cov_fail++; $display("[COV] TreeArbiter.io_out_bits_store_mask[6] 未见过 0 和 1"); end
    if (!(tra_s0_io_out_bits_store_mask[7] && tra_s1_io_out_bits_store_mask[7])) begin cov_fail++; $display("[COV] TreeArbiter.io_out_bits_store_mask[7] 未见过 0 和 1"); end
    if (!(tra_s0_io_out_bits_store_mask[8] && tra_s1_io_out_bits_store_mask[8])) begin cov_fail++; $display("[COV] TreeArbiter.io_out_bits_store_mask[8] 未见过 0 和 1"); end
    if (!(tra_s0_io_out_bits_store_mask[9] && tra_s1_io_out_bits_store_mask[9])) begin cov_fail++; $display("[COV] TreeArbiter.io_out_bits_store_mask[9] 未见过 0 和 1"); end
    if (!(tra_s0_io_out_bits_store_mask[10] && tra_s1_io_out_bits_store_mask[10])) begin cov_fail++; $display("[COV] TreeArbiter.io_out_bits_store_mask[10] 未见过 0 和 1"); end
    if (!(tra_s0_io_out_bits_store_mask[11] && tra_s1_io_out_bits_store_mask[11])) begin cov_fail++; $display("[COV] TreeArbiter.io_out_bits_store_mask[11] 未见过 0 和 1"); end
    if (!(tra_s0_io_out_bits_store_mask[12] && tra_s1_io_out_bits_store_mask[12])) begin cov_fail++; $display("[COV] TreeArbiter.io_out_bits_store_mask[12] 未见过 0 和 1"); end
    if (!(tra_s0_io_out_bits_store_mask[13] && tra_s1_io_out_bits_store_mask[13])) begin cov_fail++; $display("[COV] TreeArbiter.io_out_bits_store_mask[13] 未见过 0 和 1"); end
    if (!(tra_s0_io_out_bits_store_mask[14] && tra_s1_io_out_bits_store_mask[14])) begin cov_fail++; $display("[COV] TreeArbiter.io_out_bits_store_mask[14] 未见过 0 和 1"); end
    if (!(tra_s0_io_out_bits_store_mask[15] && tra_s1_io_out_bits_store_mask[15])) begin cov_fail++; $display("[COV] TreeArbiter.io_out_bits_store_mask[15] 未见过 0 和 1"); end
    if (!(tra_s0_io_out_bits_store_mask[16] && tra_s1_io_out_bits_store_mask[16])) begin cov_fail++; $display("[COV] TreeArbiter.io_out_bits_store_mask[16] 未见过 0 和 1"); end
    if (!(tra_s0_io_out_bits_store_mask[17] && tra_s1_io_out_bits_store_mask[17])) begin cov_fail++; $display("[COV] TreeArbiter.io_out_bits_store_mask[17] 未见过 0 和 1"); end
    if (!(tra_s0_io_out_bits_store_mask[18] && tra_s1_io_out_bits_store_mask[18])) begin cov_fail++; $display("[COV] TreeArbiter.io_out_bits_store_mask[18] 未见过 0 和 1"); end
    if (!(tra_s0_io_out_bits_store_mask[19] && tra_s1_io_out_bits_store_mask[19])) begin cov_fail++; $display("[COV] TreeArbiter.io_out_bits_store_mask[19] 未见过 0 和 1"); end
    if (!(tra_s0_io_out_bits_store_mask[20] && tra_s1_io_out_bits_store_mask[20])) begin cov_fail++; $display("[COV] TreeArbiter.io_out_bits_store_mask[20] 未见过 0 和 1"); end
    if (!(tra_s0_io_out_bits_store_mask[21] && tra_s1_io_out_bits_store_mask[21])) begin cov_fail++; $display("[COV] TreeArbiter.io_out_bits_store_mask[21] 未见过 0 和 1"); end
    if (!(tra_s0_io_out_bits_store_mask[22] && tra_s1_io_out_bits_store_mask[22])) begin cov_fail++; $display("[COV] TreeArbiter.io_out_bits_store_mask[22] 未见过 0 和 1"); end
    if (!(tra_s0_io_out_bits_store_mask[23] && tra_s1_io_out_bits_store_mask[23])) begin cov_fail++; $display("[COV] TreeArbiter.io_out_bits_store_mask[23] 未见过 0 和 1"); end
    if (!(tra_s0_io_out_bits_store_mask[24] && tra_s1_io_out_bits_store_mask[24])) begin cov_fail++; $display("[COV] TreeArbiter.io_out_bits_store_mask[24] 未见过 0 和 1"); end
    if (!(tra_s0_io_out_bits_store_mask[25] && tra_s1_io_out_bits_store_mask[25])) begin cov_fail++; $display("[COV] TreeArbiter.io_out_bits_store_mask[25] 未见过 0 和 1"); end
    if (!(tra_s0_io_out_bits_store_mask[26] && tra_s1_io_out_bits_store_mask[26])) begin cov_fail++; $display("[COV] TreeArbiter.io_out_bits_store_mask[26] 未见过 0 和 1"); end
    if (!(tra_s0_io_out_bits_store_mask[27] && tra_s1_io_out_bits_store_mask[27])) begin cov_fail++; $display("[COV] TreeArbiter.io_out_bits_store_mask[27] 未见过 0 和 1"); end
    if (!(tra_s0_io_out_bits_store_mask[28] && tra_s1_io_out_bits_store_mask[28])) begin cov_fail++; $display("[COV] TreeArbiter.io_out_bits_store_mask[28] 未见过 0 和 1"); end
    if (!(tra_s0_io_out_bits_store_mask[29] && tra_s1_io_out_bits_store_mask[29])) begin cov_fail++; $display("[COV] TreeArbiter.io_out_bits_store_mask[29] 未见过 0 和 1"); end
    if (!(tra_s0_io_out_bits_store_mask[30] && tra_s1_io_out_bits_store_mask[30])) begin cov_fail++; $display("[COV] TreeArbiter.io_out_bits_store_mask[30] 未见过 0 和 1"); end
    if (!(tra_s0_io_out_bits_store_mask[31] && tra_s1_io_out_bits_store_mask[31])) begin cov_fail++; $display("[COV] TreeArbiter.io_out_bits_store_mask[31] 未见过 0 和 1"); end
    if (!(tra_s0_io_out_bits_store_mask[32] && tra_s1_io_out_bits_store_mask[32])) begin cov_fail++; $display("[COV] TreeArbiter.io_out_bits_store_mask[32] 未见过 0 和 1"); end
    if (!(tra_s0_io_out_bits_store_mask[33] && tra_s1_io_out_bits_store_mask[33])) begin cov_fail++; $display("[COV] TreeArbiter.io_out_bits_store_mask[33] 未见过 0 和 1"); end
    if (!(tra_s0_io_out_bits_store_mask[34] && tra_s1_io_out_bits_store_mask[34])) begin cov_fail++; $display("[COV] TreeArbiter.io_out_bits_store_mask[34] 未见过 0 和 1"); end
    if (!(tra_s0_io_out_bits_store_mask[35] && tra_s1_io_out_bits_store_mask[35])) begin cov_fail++; $display("[COV] TreeArbiter.io_out_bits_store_mask[35] 未见过 0 和 1"); end
    if (!(tra_s0_io_out_bits_store_mask[36] && tra_s1_io_out_bits_store_mask[36])) begin cov_fail++; $display("[COV] TreeArbiter.io_out_bits_store_mask[36] 未见过 0 和 1"); end
    if (!(tra_s0_io_out_bits_store_mask[37] && tra_s1_io_out_bits_store_mask[37])) begin cov_fail++; $display("[COV] TreeArbiter.io_out_bits_store_mask[37] 未见过 0 和 1"); end
    if (!(tra_s0_io_out_bits_store_mask[38] && tra_s1_io_out_bits_store_mask[38])) begin cov_fail++; $display("[COV] TreeArbiter.io_out_bits_store_mask[38] 未见过 0 和 1"); end
    if (!(tra_s0_io_out_bits_store_mask[39] && tra_s1_io_out_bits_store_mask[39])) begin cov_fail++; $display("[COV] TreeArbiter.io_out_bits_store_mask[39] 未见过 0 和 1"); end
    if (!(tra_s0_io_out_bits_store_mask[40] && tra_s1_io_out_bits_store_mask[40])) begin cov_fail++; $display("[COV] TreeArbiter.io_out_bits_store_mask[40] 未见过 0 和 1"); end
    if (!(tra_s0_io_out_bits_store_mask[41] && tra_s1_io_out_bits_store_mask[41])) begin cov_fail++; $display("[COV] TreeArbiter.io_out_bits_store_mask[41] 未见过 0 和 1"); end
    if (!(tra_s0_io_out_bits_store_mask[42] && tra_s1_io_out_bits_store_mask[42])) begin cov_fail++; $display("[COV] TreeArbiter.io_out_bits_store_mask[42] 未见过 0 和 1"); end
    if (!(tra_s0_io_out_bits_store_mask[43] && tra_s1_io_out_bits_store_mask[43])) begin cov_fail++; $display("[COV] TreeArbiter.io_out_bits_store_mask[43] 未见过 0 和 1"); end
    if (!(tra_s0_io_out_bits_store_mask[44] && tra_s1_io_out_bits_store_mask[44])) begin cov_fail++; $display("[COV] TreeArbiter.io_out_bits_store_mask[44] 未见过 0 和 1"); end
    if (!(tra_s0_io_out_bits_store_mask[45] && tra_s1_io_out_bits_store_mask[45])) begin cov_fail++; $display("[COV] TreeArbiter.io_out_bits_store_mask[45] 未见过 0 和 1"); end
    if (!(tra_s0_io_out_bits_store_mask[46] && tra_s1_io_out_bits_store_mask[46])) begin cov_fail++; $display("[COV] TreeArbiter.io_out_bits_store_mask[46] 未见过 0 和 1"); end
    if (!(tra_s0_io_out_bits_store_mask[47] && tra_s1_io_out_bits_store_mask[47])) begin cov_fail++; $display("[COV] TreeArbiter.io_out_bits_store_mask[47] 未见过 0 和 1"); end
    if (!(tra_s0_io_out_bits_store_mask[48] && tra_s1_io_out_bits_store_mask[48])) begin cov_fail++; $display("[COV] TreeArbiter.io_out_bits_store_mask[48] 未见过 0 和 1"); end
    if (!(tra_s0_io_out_bits_store_mask[49] && tra_s1_io_out_bits_store_mask[49])) begin cov_fail++; $display("[COV] TreeArbiter.io_out_bits_store_mask[49] 未见过 0 和 1"); end
    if (!(tra_s0_io_out_bits_store_mask[50] && tra_s1_io_out_bits_store_mask[50])) begin cov_fail++; $display("[COV] TreeArbiter.io_out_bits_store_mask[50] 未见过 0 和 1"); end
    if (!(tra_s0_io_out_bits_store_mask[51] && tra_s1_io_out_bits_store_mask[51])) begin cov_fail++; $display("[COV] TreeArbiter.io_out_bits_store_mask[51] 未见过 0 和 1"); end
    if (!(tra_s0_io_out_bits_store_mask[52] && tra_s1_io_out_bits_store_mask[52])) begin cov_fail++; $display("[COV] TreeArbiter.io_out_bits_store_mask[52] 未见过 0 和 1"); end
    if (!(tra_s0_io_out_bits_store_mask[53] && tra_s1_io_out_bits_store_mask[53])) begin cov_fail++; $display("[COV] TreeArbiter.io_out_bits_store_mask[53] 未见过 0 和 1"); end
    if (!(tra_s0_io_out_bits_store_mask[54] && tra_s1_io_out_bits_store_mask[54])) begin cov_fail++; $display("[COV] TreeArbiter.io_out_bits_store_mask[54] 未见过 0 和 1"); end
    if (!(tra_s0_io_out_bits_store_mask[55] && tra_s1_io_out_bits_store_mask[55])) begin cov_fail++; $display("[COV] TreeArbiter.io_out_bits_store_mask[55] 未见过 0 和 1"); end
    if (!(tra_s0_io_out_bits_store_mask[56] && tra_s1_io_out_bits_store_mask[56])) begin cov_fail++; $display("[COV] TreeArbiter.io_out_bits_store_mask[56] 未见过 0 和 1"); end
    if (!(tra_s0_io_out_bits_store_mask[57] && tra_s1_io_out_bits_store_mask[57])) begin cov_fail++; $display("[COV] TreeArbiter.io_out_bits_store_mask[57] 未见过 0 和 1"); end
    if (!(tra_s0_io_out_bits_store_mask[58] && tra_s1_io_out_bits_store_mask[58])) begin cov_fail++; $display("[COV] TreeArbiter.io_out_bits_store_mask[58] 未见过 0 和 1"); end
    if (!(tra_s0_io_out_bits_store_mask[59] && tra_s1_io_out_bits_store_mask[59])) begin cov_fail++; $display("[COV] TreeArbiter.io_out_bits_store_mask[59] 未见过 0 和 1"); end
    if (!(tra_s0_io_out_bits_store_mask[60] && tra_s1_io_out_bits_store_mask[60])) begin cov_fail++; $display("[COV] TreeArbiter.io_out_bits_store_mask[60] 未见过 0 和 1"); end
    if (!(tra_s0_io_out_bits_store_mask[61] && tra_s1_io_out_bits_store_mask[61])) begin cov_fail++; $display("[COV] TreeArbiter.io_out_bits_store_mask[61] 未见过 0 和 1"); end
    if (!(tra_s0_io_out_bits_store_mask[62] && tra_s1_io_out_bits_store_mask[62])) begin cov_fail++; $display("[COV] TreeArbiter.io_out_bits_store_mask[62] 未见过 0 和 1"); end
    if (!(tra_s0_io_out_bits_store_mask[63] && tra_s1_io_out_bits_store_mask[63])) begin cov_fail++; $display("[COV] TreeArbiter.io_out_bits_store_mask[63] 未见过 0 和 1"); end
    $display("[ARM] TreeArbiter armed_at=%0d", tra_armed_at);
    if (tra_armed_at < 0) begin cov_fail++; $display("[ARM] TreeArbiter 从未 arm"); end
    $display("[COV] TreeArbiter.win0 = %0d", tra_cov_win0);
    if (tra_cov_win0 < 1000) begin cov_fail++; $display("[COV] TreeArbiter.win0 < 1000"); end
    $display("[COV] TreeArbiter.win1 = %0d", tra_cov_win1);
    if (tra_cov_win1 < 1000) begin cov_fail++; $display("[COV] TreeArbiter.win1 < 1000"); end
    $display("[COV] TreeArbiter.win2 = %0d", tra_cov_win2);
    if (tra_cov_win2 < 1000) begin cov_fail++; $display("[COV] TreeArbiter.win2 < 1000"); end
    $display("[COV] TreeArbiter.win3 = %0d", tra_cov_win3);
    if (tra_cov_win3 < 1000) begin cov_fail++; $display("[COV] TreeArbiter.win3 < 1000"); end
    $display("[COV] TreeArbiter.none = %0d", tra_cov_none);
    if (tra_cov_none < 1000) begin cov_fail++; $display("[COV] TreeArbiter.none < 1000"); end
    $display("[COV] TreeArbiter.stall = %0d", tra_cov_stall);
    if (tra_cov_stall < 1000) begin cov_fail++; $display("[COV] TreeArbiter.stall < 1000"); end
    if (!(mrg_s0_io_in_0_ready && mrg_s1_io_in_0_ready)) begin cov_fail++; $display("[COV] MissReadyGen.io_in_0_ready 未见过 0 和 1"); end
    if (!(mrg_s0_io_in_1_ready && mrg_s1_io_in_1_ready)) begin cov_fail++; $display("[COV] MissReadyGen.io_in_1_ready 未见过 0 和 1"); end
    if (!(mrg_s0_io_in_2_ready && mrg_s1_io_in_2_ready)) begin cov_fail++; $display("[COV] MissReadyGen.io_in_2_ready 未见过 0 和 1"); end
    if (!(mrg_s0_io_in_3_ready && mrg_s1_io_in_3_ready)) begin cov_fail++; $display("[COV] MissReadyGen.io_in_3_ready 未见过 0 和 1"); end
    if (!(mrg_s0_io_queryMQ_0_req_bits_source[0] && mrg_s1_io_queryMQ_0_req_bits_source[0])) begin cov_fail++; $display("[COV] MissReadyGen.io_queryMQ_0_req_bits_source[0] 未见过 0 和 1"); end
    if (!(mrg_s0_io_queryMQ_0_req_bits_source[1] && mrg_s1_io_queryMQ_0_req_bits_source[1])) begin cov_fail++; $display("[COV] MissReadyGen.io_queryMQ_0_req_bits_source[1] 未见过 0 和 1"); end
    if (!(mrg_s0_io_queryMQ_0_req_bits_source[2] && mrg_s1_io_queryMQ_0_req_bits_source[2])) begin cov_fail++; $display("[COV] MissReadyGen.io_queryMQ_0_req_bits_source[2] 未见过 0 和 1"); end
    if (!(mrg_s0_io_queryMQ_0_req_bits_source[3] && mrg_s1_io_queryMQ_0_req_bits_source[3])) begin cov_fail++; $display("[COV] MissReadyGen.io_queryMQ_0_req_bits_source[3] 未见过 0 和 1"); end
    if (!(mrg_s0_io_queryMQ_0_req_bits_addr[0] && mrg_s1_io_queryMQ_0_req_bits_addr[0])) begin cov_fail++; $display("[COV] MissReadyGen.io_queryMQ_0_req_bits_addr[0] 未见过 0 和 1"); end
    if (!(mrg_s0_io_queryMQ_0_req_bits_addr[1] && mrg_s1_io_queryMQ_0_req_bits_addr[1])) begin cov_fail++; $display("[COV] MissReadyGen.io_queryMQ_0_req_bits_addr[1] 未见过 0 和 1"); end
    if (!(mrg_s0_io_queryMQ_0_req_bits_addr[2] && mrg_s1_io_queryMQ_0_req_bits_addr[2])) begin cov_fail++; $display("[COV] MissReadyGen.io_queryMQ_0_req_bits_addr[2] 未见过 0 和 1"); end
    if (!(mrg_s0_io_queryMQ_0_req_bits_addr[3] && mrg_s1_io_queryMQ_0_req_bits_addr[3])) begin cov_fail++; $display("[COV] MissReadyGen.io_queryMQ_0_req_bits_addr[3] 未见过 0 和 1"); end
    if (!(mrg_s0_io_queryMQ_0_req_bits_addr[4] && mrg_s1_io_queryMQ_0_req_bits_addr[4])) begin cov_fail++; $display("[COV] MissReadyGen.io_queryMQ_0_req_bits_addr[4] 未见过 0 和 1"); end
    if (!(mrg_s0_io_queryMQ_0_req_bits_addr[5] && mrg_s1_io_queryMQ_0_req_bits_addr[5])) begin cov_fail++; $display("[COV] MissReadyGen.io_queryMQ_0_req_bits_addr[5] 未见过 0 和 1"); end
    if (!(mrg_s0_io_queryMQ_0_req_bits_addr[6] && mrg_s1_io_queryMQ_0_req_bits_addr[6])) begin cov_fail++; $display("[COV] MissReadyGen.io_queryMQ_0_req_bits_addr[6] 未见过 0 和 1"); end
    if (!(mrg_s0_io_queryMQ_0_req_bits_addr[7] && mrg_s1_io_queryMQ_0_req_bits_addr[7])) begin cov_fail++; $display("[COV] MissReadyGen.io_queryMQ_0_req_bits_addr[7] 未见过 0 和 1"); end
    if (!(mrg_s0_io_queryMQ_0_req_bits_addr[8] && mrg_s1_io_queryMQ_0_req_bits_addr[8])) begin cov_fail++; $display("[COV] MissReadyGen.io_queryMQ_0_req_bits_addr[8] 未见过 0 和 1"); end
    if (!(mrg_s0_io_queryMQ_0_req_bits_addr[9] && mrg_s1_io_queryMQ_0_req_bits_addr[9])) begin cov_fail++; $display("[COV] MissReadyGen.io_queryMQ_0_req_bits_addr[9] 未见过 0 和 1"); end
    if (!(mrg_s0_io_queryMQ_0_req_bits_addr[10] && mrg_s1_io_queryMQ_0_req_bits_addr[10])) begin cov_fail++; $display("[COV] MissReadyGen.io_queryMQ_0_req_bits_addr[10] 未见过 0 和 1"); end
    if (!(mrg_s0_io_queryMQ_0_req_bits_addr[11] && mrg_s1_io_queryMQ_0_req_bits_addr[11])) begin cov_fail++; $display("[COV] MissReadyGen.io_queryMQ_0_req_bits_addr[11] 未见过 0 和 1"); end
    if (!(mrg_s0_io_queryMQ_0_req_bits_addr[12] && mrg_s1_io_queryMQ_0_req_bits_addr[12])) begin cov_fail++; $display("[COV] MissReadyGen.io_queryMQ_0_req_bits_addr[12] 未见过 0 和 1"); end
    if (!(mrg_s0_io_queryMQ_0_req_bits_addr[13] && mrg_s1_io_queryMQ_0_req_bits_addr[13])) begin cov_fail++; $display("[COV] MissReadyGen.io_queryMQ_0_req_bits_addr[13] 未见过 0 和 1"); end
    if (!(mrg_s0_io_queryMQ_0_req_bits_addr[14] && mrg_s1_io_queryMQ_0_req_bits_addr[14])) begin cov_fail++; $display("[COV] MissReadyGen.io_queryMQ_0_req_bits_addr[14] 未见过 0 和 1"); end
    if (!(mrg_s0_io_queryMQ_0_req_bits_addr[15] && mrg_s1_io_queryMQ_0_req_bits_addr[15])) begin cov_fail++; $display("[COV] MissReadyGen.io_queryMQ_0_req_bits_addr[15] 未见过 0 和 1"); end
    if (!(mrg_s0_io_queryMQ_0_req_bits_addr[16] && mrg_s1_io_queryMQ_0_req_bits_addr[16])) begin cov_fail++; $display("[COV] MissReadyGen.io_queryMQ_0_req_bits_addr[16] 未见过 0 和 1"); end
    if (!(mrg_s0_io_queryMQ_0_req_bits_addr[17] && mrg_s1_io_queryMQ_0_req_bits_addr[17])) begin cov_fail++; $display("[COV] MissReadyGen.io_queryMQ_0_req_bits_addr[17] 未见过 0 和 1"); end
    if (!(mrg_s0_io_queryMQ_0_req_bits_addr[18] && mrg_s1_io_queryMQ_0_req_bits_addr[18])) begin cov_fail++; $display("[COV] MissReadyGen.io_queryMQ_0_req_bits_addr[18] 未见过 0 和 1"); end
    if (!(mrg_s0_io_queryMQ_0_req_bits_addr[19] && mrg_s1_io_queryMQ_0_req_bits_addr[19])) begin cov_fail++; $display("[COV] MissReadyGen.io_queryMQ_0_req_bits_addr[19] 未见过 0 和 1"); end
    if (!(mrg_s0_io_queryMQ_0_req_bits_addr[20] && mrg_s1_io_queryMQ_0_req_bits_addr[20])) begin cov_fail++; $display("[COV] MissReadyGen.io_queryMQ_0_req_bits_addr[20] 未见过 0 和 1"); end
    if (!(mrg_s0_io_queryMQ_0_req_bits_addr[21] && mrg_s1_io_queryMQ_0_req_bits_addr[21])) begin cov_fail++; $display("[COV] MissReadyGen.io_queryMQ_0_req_bits_addr[21] 未见过 0 和 1"); end
    if (!(mrg_s0_io_queryMQ_0_req_bits_addr[22] && mrg_s1_io_queryMQ_0_req_bits_addr[22])) begin cov_fail++; $display("[COV] MissReadyGen.io_queryMQ_0_req_bits_addr[22] 未见过 0 和 1"); end
    if (!(mrg_s0_io_queryMQ_0_req_bits_addr[23] && mrg_s1_io_queryMQ_0_req_bits_addr[23])) begin cov_fail++; $display("[COV] MissReadyGen.io_queryMQ_0_req_bits_addr[23] 未见过 0 和 1"); end
    if (!(mrg_s0_io_queryMQ_0_req_bits_addr[24] && mrg_s1_io_queryMQ_0_req_bits_addr[24])) begin cov_fail++; $display("[COV] MissReadyGen.io_queryMQ_0_req_bits_addr[24] 未见过 0 和 1"); end
    if (!(mrg_s0_io_queryMQ_0_req_bits_addr[25] && mrg_s1_io_queryMQ_0_req_bits_addr[25])) begin cov_fail++; $display("[COV] MissReadyGen.io_queryMQ_0_req_bits_addr[25] 未见过 0 和 1"); end
    if (!(mrg_s0_io_queryMQ_0_req_bits_addr[26] && mrg_s1_io_queryMQ_0_req_bits_addr[26])) begin cov_fail++; $display("[COV] MissReadyGen.io_queryMQ_0_req_bits_addr[26] 未见过 0 和 1"); end
    if (!(mrg_s0_io_queryMQ_0_req_bits_addr[27] && mrg_s1_io_queryMQ_0_req_bits_addr[27])) begin cov_fail++; $display("[COV] MissReadyGen.io_queryMQ_0_req_bits_addr[27] 未见过 0 和 1"); end
    if (!(mrg_s0_io_queryMQ_0_req_bits_addr[28] && mrg_s1_io_queryMQ_0_req_bits_addr[28])) begin cov_fail++; $display("[COV] MissReadyGen.io_queryMQ_0_req_bits_addr[28] 未见过 0 和 1"); end
    if (!(mrg_s0_io_queryMQ_0_req_bits_addr[29] && mrg_s1_io_queryMQ_0_req_bits_addr[29])) begin cov_fail++; $display("[COV] MissReadyGen.io_queryMQ_0_req_bits_addr[29] 未见过 0 和 1"); end
    if (!(mrg_s0_io_queryMQ_0_req_bits_addr[30] && mrg_s1_io_queryMQ_0_req_bits_addr[30])) begin cov_fail++; $display("[COV] MissReadyGen.io_queryMQ_0_req_bits_addr[30] 未见过 0 和 1"); end
    if (!(mrg_s0_io_queryMQ_0_req_bits_addr[31] && mrg_s1_io_queryMQ_0_req_bits_addr[31])) begin cov_fail++; $display("[COV] MissReadyGen.io_queryMQ_0_req_bits_addr[31] 未见过 0 和 1"); end
    if (!(mrg_s0_io_queryMQ_0_req_bits_addr[32] && mrg_s1_io_queryMQ_0_req_bits_addr[32])) begin cov_fail++; $display("[COV] MissReadyGen.io_queryMQ_0_req_bits_addr[32] 未见过 0 和 1"); end
    if (!(mrg_s0_io_queryMQ_0_req_bits_addr[33] && mrg_s1_io_queryMQ_0_req_bits_addr[33])) begin cov_fail++; $display("[COV] MissReadyGen.io_queryMQ_0_req_bits_addr[33] 未见过 0 和 1"); end
    if (!(mrg_s0_io_queryMQ_0_req_bits_addr[34] && mrg_s1_io_queryMQ_0_req_bits_addr[34])) begin cov_fail++; $display("[COV] MissReadyGen.io_queryMQ_0_req_bits_addr[34] 未见过 0 和 1"); end
    if (!(mrg_s0_io_queryMQ_0_req_bits_addr[35] && mrg_s1_io_queryMQ_0_req_bits_addr[35])) begin cov_fail++; $display("[COV] MissReadyGen.io_queryMQ_0_req_bits_addr[35] 未见过 0 和 1"); end
    if (!(mrg_s0_io_queryMQ_0_req_bits_addr[36] && mrg_s1_io_queryMQ_0_req_bits_addr[36])) begin cov_fail++; $display("[COV] MissReadyGen.io_queryMQ_0_req_bits_addr[36] 未见过 0 和 1"); end
    if (!(mrg_s0_io_queryMQ_0_req_bits_addr[37] && mrg_s1_io_queryMQ_0_req_bits_addr[37])) begin cov_fail++; $display("[COV] MissReadyGen.io_queryMQ_0_req_bits_addr[37] 未见过 0 和 1"); end
    if (!(mrg_s0_io_queryMQ_0_req_bits_addr[38] && mrg_s1_io_queryMQ_0_req_bits_addr[38])) begin cov_fail++; $display("[COV] MissReadyGen.io_queryMQ_0_req_bits_addr[38] 未见过 0 和 1"); end
    if (!(mrg_s0_io_queryMQ_0_req_bits_addr[39] && mrg_s1_io_queryMQ_0_req_bits_addr[39])) begin cov_fail++; $display("[COV] MissReadyGen.io_queryMQ_0_req_bits_addr[39] 未见过 0 和 1"); end
    if (!(mrg_s0_io_queryMQ_0_req_bits_addr[40] && mrg_s1_io_queryMQ_0_req_bits_addr[40])) begin cov_fail++; $display("[COV] MissReadyGen.io_queryMQ_0_req_bits_addr[40] 未见过 0 和 1"); end
    if (!(mrg_s0_io_queryMQ_0_req_bits_addr[41] && mrg_s1_io_queryMQ_0_req_bits_addr[41])) begin cov_fail++; $display("[COV] MissReadyGen.io_queryMQ_0_req_bits_addr[41] 未见过 0 和 1"); end
    if (!(mrg_s0_io_queryMQ_0_req_bits_addr[42] && mrg_s1_io_queryMQ_0_req_bits_addr[42])) begin cov_fail++; $display("[COV] MissReadyGen.io_queryMQ_0_req_bits_addr[42] 未见过 0 和 1"); end
    if (!(mrg_s0_io_queryMQ_0_req_bits_addr[43] && mrg_s1_io_queryMQ_0_req_bits_addr[43])) begin cov_fail++; $display("[COV] MissReadyGen.io_queryMQ_0_req_bits_addr[43] 未见过 0 和 1"); end
    if (!(mrg_s0_io_queryMQ_0_req_bits_addr[44] && mrg_s1_io_queryMQ_0_req_bits_addr[44])) begin cov_fail++; $display("[COV] MissReadyGen.io_queryMQ_0_req_bits_addr[44] 未见过 0 和 1"); end
    if (!(mrg_s0_io_queryMQ_0_req_bits_addr[45] && mrg_s1_io_queryMQ_0_req_bits_addr[45])) begin cov_fail++; $display("[COV] MissReadyGen.io_queryMQ_0_req_bits_addr[45] 未见过 0 和 1"); end
    if (!(mrg_s0_io_queryMQ_0_req_bits_addr[46] && mrg_s1_io_queryMQ_0_req_bits_addr[46])) begin cov_fail++; $display("[COV] MissReadyGen.io_queryMQ_0_req_bits_addr[46] 未见过 0 和 1"); end
    if (!(mrg_s0_io_queryMQ_0_req_bits_addr[47] && mrg_s1_io_queryMQ_0_req_bits_addr[47])) begin cov_fail++; $display("[COV] MissReadyGen.io_queryMQ_0_req_bits_addr[47] 未见过 0 和 1"); end
    if (!(mrg_s0_io_queryMQ_0_req_bits_vaddr[0] && mrg_s1_io_queryMQ_0_req_bits_vaddr[0])) begin cov_fail++; $display("[COV] MissReadyGen.io_queryMQ_0_req_bits_vaddr[0] 未见过 0 和 1"); end
    if (!(mrg_s0_io_queryMQ_0_req_bits_vaddr[1] && mrg_s1_io_queryMQ_0_req_bits_vaddr[1])) begin cov_fail++; $display("[COV] MissReadyGen.io_queryMQ_0_req_bits_vaddr[1] 未见过 0 和 1"); end
    if (!(mrg_s0_io_queryMQ_0_req_bits_vaddr[2] && mrg_s1_io_queryMQ_0_req_bits_vaddr[2])) begin cov_fail++; $display("[COV] MissReadyGen.io_queryMQ_0_req_bits_vaddr[2] 未见过 0 和 1"); end
    if (!(mrg_s0_io_queryMQ_0_req_bits_vaddr[3] && mrg_s1_io_queryMQ_0_req_bits_vaddr[3])) begin cov_fail++; $display("[COV] MissReadyGen.io_queryMQ_0_req_bits_vaddr[3] 未见过 0 和 1"); end
    if (!(mrg_s0_io_queryMQ_0_req_bits_vaddr[4] && mrg_s1_io_queryMQ_0_req_bits_vaddr[4])) begin cov_fail++; $display("[COV] MissReadyGen.io_queryMQ_0_req_bits_vaddr[4] 未见过 0 和 1"); end
    if (!(mrg_s0_io_queryMQ_0_req_bits_vaddr[5] && mrg_s1_io_queryMQ_0_req_bits_vaddr[5])) begin cov_fail++; $display("[COV] MissReadyGen.io_queryMQ_0_req_bits_vaddr[5] 未见过 0 和 1"); end
    if (!(mrg_s0_io_queryMQ_0_req_bits_vaddr[6] && mrg_s1_io_queryMQ_0_req_bits_vaddr[6])) begin cov_fail++; $display("[COV] MissReadyGen.io_queryMQ_0_req_bits_vaddr[6] 未见过 0 和 1"); end
    if (!(mrg_s0_io_queryMQ_0_req_bits_vaddr[7] && mrg_s1_io_queryMQ_0_req_bits_vaddr[7])) begin cov_fail++; $display("[COV] MissReadyGen.io_queryMQ_0_req_bits_vaddr[7] 未见过 0 和 1"); end
    if (!(mrg_s0_io_queryMQ_0_req_bits_vaddr[8] && mrg_s1_io_queryMQ_0_req_bits_vaddr[8])) begin cov_fail++; $display("[COV] MissReadyGen.io_queryMQ_0_req_bits_vaddr[8] 未见过 0 和 1"); end
    if (!(mrg_s0_io_queryMQ_0_req_bits_vaddr[9] && mrg_s1_io_queryMQ_0_req_bits_vaddr[9])) begin cov_fail++; $display("[COV] MissReadyGen.io_queryMQ_0_req_bits_vaddr[9] 未见过 0 和 1"); end
    if (!(mrg_s0_io_queryMQ_0_req_bits_vaddr[10] && mrg_s1_io_queryMQ_0_req_bits_vaddr[10])) begin cov_fail++; $display("[COV] MissReadyGen.io_queryMQ_0_req_bits_vaddr[10] 未见过 0 和 1"); end
    if (!(mrg_s0_io_queryMQ_0_req_bits_vaddr[11] && mrg_s1_io_queryMQ_0_req_bits_vaddr[11])) begin cov_fail++; $display("[COV] MissReadyGen.io_queryMQ_0_req_bits_vaddr[11] 未见过 0 和 1"); end
    if (!(mrg_s0_io_queryMQ_0_req_bits_vaddr[12] && mrg_s1_io_queryMQ_0_req_bits_vaddr[12])) begin cov_fail++; $display("[COV] MissReadyGen.io_queryMQ_0_req_bits_vaddr[12] 未见过 0 和 1"); end
    if (!(mrg_s0_io_queryMQ_0_req_bits_vaddr[13] && mrg_s1_io_queryMQ_0_req_bits_vaddr[13])) begin cov_fail++; $display("[COV] MissReadyGen.io_queryMQ_0_req_bits_vaddr[13] 未见过 0 和 1"); end
    if (!(mrg_s0_io_queryMQ_0_req_bits_vaddr[14] && mrg_s1_io_queryMQ_0_req_bits_vaddr[14])) begin cov_fail++; $display("[COV] MissReadyGen.io_queryMQ_0_req_bits_vaddr[14] 未见过 0 和 1"); end
    if (!(mrg_s0_io_queryMQ_0_req_bits_vaddr[15] && mrg_s1_io_queryMQ_0_req_bits_vaddr[15])) begin cov_fail++; $display("[COV] MissReadyGen.io_queryMQ_0_req_bits_vaddr[15] 未见过 0 和 1"); end
    if (!(mrg_s0_io_queryMQ_0_req_bits_vaddr[16] && mrg_s1_io_queryMQ_0_req_bits_vaddr[16])) begin cov_fail++; $display("[COV] MissReadyGen.io_queryMQ_0_req_bits_vaddr[16] 未见过 0 和 1"); end
    if (!(mrg_s0_io_queryMQ_0_req_bits_vaddr[17] && mrg_s1_io_queryMQ_0_req_bits_vaddr[17])) begin cov_fail++; $display("[COV] MissReadyGen.io_queryMQ_0_req_bits_vaddr[17] 未见过 0 和 1"); end
    if (!(mrg_s0_io_queryMQ_0_req_bits_vaddr[18] && mrg_s1_io_queryMQ_0_req_bits_vaddr[18])) begin cov_fail++; $display("[COV] MissReadyGen.io_queryMQ_0_req_bits_vaddr[18] 未见过 0 和 1"); end
    if (!(mrg_s0_io_queryMQ_0_req_bits_vaddr[19] && mrg_s1_io_queryMQ_0_req_bits_vaddr[19])) begin cov_fail++; $display("[COV] MissReadyGen.io_queryMQ_0_req_bits_vaddr[19] 未见过 0 和 1"); end
    if (!(mrg_s0_io_queryMQ_0_req_bits_vaddr[20] && mrg_s1_io_queryMQ_0_req_bits_vaddr[20])) begin cov_fail++; $display("[COV] MissReadyGen.io_queryMQ_0_req_bits_vaddr[20] 未见过 0 和 1"); end
    if (!(mrg_s0_io_queryMQ_0_req_bits_vaddr[21] && mrg_s1_io_queryMQ_0_req_bits_vaddr[21])) begin cov_fail++; $display("[COV] MissReadyGen.io_queryMQ_0_req_bits_vaddr[21] 未见过 0 和 1"); end
    if (!(mrg_s0_io_queryMQ_0_req_bits_vaddr[22] && mrg_s1_io_queryMQ_0_req_bits_vaddr[22])) begin cov_fail++; $display("[COV] MissReadyGen.io_queryMQ_0_req_bits_vaddr[22] 未见过 0 和 1"); end
    if (!(mrg_s0_io_queryMQ_0_req_bits_vaddr[23] && mrg_s1_io_queryMQ_0_req_bits_vaddr[23])) begin cov_fail++; $display("[COV] MissReadyGen.io_queryMQ_0_req_bits_vaddr[23] 未见过 0 和 1"); end
    if (!(mrg_s0_io_queryMQ_0_req_bits_vaddr[24] && mrg_s1_io_queryMQ_0_req_bits_vaddr[24])) begin cov_fail++; $display("[COV] MissReadyGen.io_queryMQ_0_req_bits_vaddr[24] 未见过 0 和 1"); end
    if (!(mrg_s0_io_queryMQ_0_req_bits_vaddr[25] && mrg_s1_io_queryMQ_0_req_bits_vaddr[25])) begin cov_fail++; $display("[COV] MissReadyGen.io_queryMQ_0_req_bits_vaddr[25] 未见过 0 和 1"); end
    if (!(mrg_s0_io_queryMQ_0_req_bits_vaddr[26] && mrg_s1_io_queryMQ_0_req_bits_vaddr[26])) begin cov_fail++; $display("[COV] MissReadyGen.io_queryMQ_0_req_bits_vaddr[26] 未见过 0 和 1"); end
    if (!(mrg_s0_io_queryMQ_0_req_bits_vaddr[27] && mrg_s1_io_queryMQ_0_req_bits_vaddr[27])) begin cov_fail++; $display("[COV] MissReadyGen.io_queryMQ_0_req_bits_vaddr[27] 未见过 0 和 1"); end
    if (!(mrg_s0_io_queryMQ_0_req_bits_vaddr[28] && mrg_s1_io_queryMQ_0_req_bits_vaddr[28])) begin cov_fail++; $display("[COV] MissReadyGen.io_queryMQ_0_req_bits_vaddr[28] 未见过 0 和 1"); end
    if (!(mrg_s0_io_queryMQ_0_req_bits_vaddr[29] && mrg_s1_io_queryMQ_0_req_bits_vaddr[29])) begin cov_fail++; $display("[COV] MissReadyGen.io_queryMQ_0_req_bits_vaddr[29] 未见过 0 和 1"); end
    if (!(mrg_s0_io_queryMQ_0_req_bits_vaddr[30] && mrg_s1_io_queryMQ_0_req_bits_vaddr[30])) begin cov_fail++; $display("[COV] MissReadyGen.io_queryMQ_0_req_bits_vaddr[30] 未见过 0 和 1"); end
    if (!(mrg_s0_io_queryMQ_0_req_bits_vaddr[31] && mrg_s1_io_queryMQ_0_req_bits_vaddr[31])) begin cov_fail++; $display("[COV] MissReadyGen.io_queryMQ_0_req_bits_vaddr[31] 未见过 0 和 1"); end
    if (!(mrg_s0_io_queryMQ_0_req_bits_vaddr[32] && mrg_s1_io_queryMQ_0_req_bits_vaddr[32])) begin cov_fail++; $display("[COV] MissReadyGen.io_queryMQ_0_req_bits_vaddr[32] 未见过 0 和 1"); end
    if (!(mrg_s0_io_queryMQ_0_req_bits_vaddr[33] && mrg_s1_io_queryMQ_0_req_bits_vaddr[33])) begin cov_fail++; $display("[COV] MissReadyGen.io_queryMQ_0_req_bits_vaddr[33] 未见过 0 和 1"); end
    if (!(mrg_s0_io_queryMQ_0_req_bits_vaddr[34] && mrg_s1_io_queryMQ_0_req_bits_vaddr[34])) begin cov_fail++; $display("[COV] MissReadyGen.io_queryMQ_0_req_bits_vaddr[34] 未见过 0 和 1"); end
    if (!(mrg_s0_io_queryMQ_0_req_bits_vaddr[35] && mrg_s1_io_queryMQ_0_req_bits_vaddr[35])) begin cov_fail++; $display("[COV] MissReadyGen.io_queryMQ_0_req_bits_vaddr[35] 未见过 0 和 1"); end
    if (!(mrg_s0_io_queryMQ_0_req_bits_vaddr[36] && mrg_s1_io_queryMQ_0_req_bits_vaddr[36])) begin cov_fail++; $display("[COV] MissReadyGen.io_queryMQ_0_req_bits_vaddr[36] 未见过 0 和 1"); end
    if (!(mrg_s0_io_queryMQ_0_req_bits_vaddr[37] && mrg_s1_io_queryMQ_0_req_bits_vaddr[37])) begin cov_fail++; $display("[COV] MissReadyGen.io_queryMQ_0_req_bits_vaddr[37] 未见过 0 和 1"); end
    if (!(mrg_s0_io_queryMQ_0_req_bits_vaddr[38] && mrg_s1_io_queryMQ_0_req_bits_vaddr[38])) begin cov_fail++; $display("[COV] MissReadyGen.io_queryMQ_0_req_bits_vaddr[38] 未见过 0 和 1"); end
    if (!(mrg_s0_io_queryMQ_0_req_bits_vaddr[39] && mrg_s1_io_queryMQ_0_req_bits_vaddr[39])) begin cov_fail++; $display("[COV] MissReadyGen.io_queryMQ_0_req_bits_vaddr[39] 未见过 0 和 1"); end
    if (!(mrg_s0_io_queryMQ_0_req_bits_vaddr[40] && mrg_s1_io_queryMQ_0_req_bits_vaddr[40])) begin cov_fail++; $display("[COV] MissReadyGen.io_queryMQ_0_req_bits_vaddr[40] 未见过 0 和 1"); end
    if (!(mrg_s0_io_queryMQ_0_req_bits_vaddr[41] && mrg_s1_io_queryMQ_0_req_bits_vaddr[41])) begin cov_fail++; $display("[COV] MissReadyGen.io_queryMQ_0_req_bits_vaddr[41] 未见过 0 和 1"); end
    if (!(mrg_s0_io_queryMQ_0_req_bits_vaddr[42] && mrg_s1_io_queryMQ_0_req_bits_vaddr[42])) begin cov_fail++; $display("[COV] MissReadyGen.io_queryMQ_0_req_bits_vaddr[42] 未见过 0 和 1"); end
    if (!(mrg_s0_io_queryMQ_0_req_bits_vaddr[43] && mrg_s1_io_queryMQ_0_req_bits_vaddr[43])) begin cov_fail++; $display("[COV] MissReadyGen.io_queryMQ_0_req_bits_vaddr[43] 未见过 0 和 1"); end
    if (!(mrg_s0_io_queryMQ_0_req_bits_vaddr[44] && mrg_s1_io_queryMQ_0_req_bits_vaddr[44])) begin cov_fail++; $display("[COV] MissReadyGen.io_queryMQ_0_req_bits_vaddr[44] 未见过 0 和 1"); end
    if (!(mrg_s0_io_queryMQ_0_req_bits_vaddr[45] && mrg_s1_io_queryMQ_0_req_bits_vaddr[45])) begin cov_fail++; $display("[COV] MissReadyGen.io_queryMQ_0_req_bits_vaddr[45] 未见过 0 和 1"); end
    if (!(mrg_s0_io_queryMQ_0_req_bits_vaddr[46] && mrg_s1_io_queryMQ_0_req_bits_vaddr[46])) begin cov_fail++; $display("[COV] MissReadyGen.io_queryMQ_0_req_bits_vaddr[46] 未见过 0 和 1"); end
    if (!(mrg_s0_io_queryMQ_0_req_bits_vaddr[47] && mrg_s1_io_queryMQ_0_req_bits_vaddr[47])) begin cov_fail++; $display("[COV] MissReadyGen.io_queryMQ_0_req_bits_vaddr[47] 未见过 0 和 1"); end
    if (!(mrg_s0_io_queryMQ_0_req_bits_vaddr[48] && mrg_s1_io_queryMQ_0_req_bits_vaddr[48])) begin cov_fail++; $display("[COV] MissReadyGen.io_queryMQ_0_req_bits_vaddr[48] 未见过 0 和 1"); end
    if (!(mrg_s0_io_queryMQ_0_req_bits_vaddr[49] && mrg_s1_io_queryMQ_0_req_bits_vaddr[49])) begin cov_fail++; $display("[COV] MissReadyGen.io_queryMQ_0_req_bits_vaddr[49] 未见过 0 和 1"); end
    if (!(mrg_s0_io_queryMQ_1_req_bits_source[0] && mrg_s1_io_queryMQ_1_req_bits_source[0])) begin cov_fail++; $display("[COV] MissReadyGen.io_queryMQ_1_req_bits_source[0] 未见过 0 和 1"); end
    if (!(mrg_s0_io_queryMQ_1_req_bits_source[1] && mrg_s1_io_queryMQ_1_req_bits_source[1])) begin cov_fail++; $display("[COV] MissReadyGen.io_queryMQ_1_req_bits_source[1] 未见过 0 和 1"); end
    if (!(mrg_s0_io_queryMQ_1_req_bits_source[2] && mrg_s1_io_queryMQ_1_req_bits_source[2])) begin cov_fail++; $display("[COV] MissReadyGen.io_queryMQ_1_req_bits_source[2] 未见过 0 和 1"); end
    if (!(mrg_s0_io_queryMQ_1_req_bits_source[3] && mrg_s1_io_queryMQ_1_req_bits_source[3])) begin cov_fail++; $display("[COV] MissReadyGen.io_queryMQ_1_req_bits_source[3] 未见过 0 和 1"); end
    if (!(mrg_s0_io_queryMQ_1_req_bits_addr[0] && mrg_s1_io_queryMQ_1_req_bits_addr[0])) begin cov_fail++; $display("[COV] MissReadyGen.io_queryMQ_1_req_bits_addr[0] 未见过 0 和 1"); end
    if (!(mrg_s0_io_queryMQ_1_req_bits_addr[1] && mrg_s1_io_queryMQ_1_req_bits_addr[1])) begin cov_fail++; $display("[COV] MissReadyGen.io_queryMQ_1_req_bits_addr[1] 未见过 0 和 1"); end
    if (!(mrg_s0_io_queryMQ_1_req_bits_addr[2] && mrg_s1_io_queryMQ_1_req_bits_addr[2])) begin cov_fail++; $display("[COV] MissReadyGen.io_queryMQ_1_req_bits_addr[2] 未见过 0 和 1"); end
    if (!(mrg_s0_io_queryMQ_1_req_bits_addr[3] && mrg_s1_io_queryMQ_1_req_bits_addr[3])) begin cov_fail++; $display("[COV] MissReadyGen.io_queryMQ_1_req_bits_addr[3] 未见过 0 和 1"); end
    if (!(mrg_s0_io_queryMQ_1_req_bits_addr[4] && mrg_s1_io_queryMQ_1_req_bits_addr[4])) begin cov_fail++; $display("[COV] MissReadyGen.io_queryMQ_1_req_bits_addr[4] 未见过 0 和 1"); end
    if (!(mrg_s0_io_queryMQ_1_req_bits_addr[5] && mrg_s1_io_queryMQ_1_req_bits_addr[5])) begin cov_fail++; $display("[COV] MissReadyGen.io_queryMQ_1_req_bits_addr[5] 未见过 0 和 1"); end
    if (!(mrg_s0_io_queryMQ_1_req_bits_addr[6] && mrg_s1_io_queryMQ_1_req_bits_addr[6])) begin cov_fail++; $display("[COV] MissReadyGen.io_queryMQ_1_req_bits_addr[6] 未见过 0 和 1"); end
    if (!(mrg_s0_io_queryMQ_1_req_bits_addr[7] && mrg_s1_io_queryMQ_1_req_bits_addr[7])) begin cov_fail++; $display("[COV] MissReadyGen.io_queryMQ_1_req_bits_addr[7] 未见过 0 和 1"); end
    if (!(mrg_s0_io_queryMQ_1_req_bits_addr[8] && mrg_s1_io_queryMQ_1_req_bits_addr[8])) begin cov_fail++; $display("[COV] MissReadyGen.io_queryMQ_1_req_bits_addr[8] 未见过 0 和 1"); end
    if (!(mrg_s0_io_queryMQ_1_req_bits_addr[9] && mrg_s1_io_queryMQ_1_req_bits_addr[9])) begin cov_fail++; $display("[COV] MissReadyGen.io_queryMQ_1_req_bits_addr[9] 未见过 0 和 1"); end
    if (!(mrg_s0_io_queryMQ_1_req_bits_addr[10] && mrg_s1_io_queryMQ_1_req_bits_addr[10])) begin cov_fail++; $display("[COV] MissReadyGen.io_queryMQ_1_req_bits_addr[10] 未见过 0 和 1"); end
    if (!(mrg_s0_io_queryMQ_1_req_bits_addr[11] && mrg_s1_io_queryMQ_1_req_bits_addr[11])) begin cov_fail++; $display("[COV] MissReadyGen.io_queryMQ_1_req_bits_addr[11] 未见过 0 和 1"); end
    if (!(mrg_s0_io_queryMQ_1_req_bits_addr[12] && mrg_s1_io_queryMQ_1_req_bits_addr[12])) begin cov_fail++; $display("[COV] MissReadyGen.io_queryMQ_1_req_bits_addr[12] 未见过 0 和 1"); end
    if (!(mrg_s0_io_queryMQ_1_req_bits_addr[13] && mrg_s1_io_queryMQ_1_req_bits_addr[13])) begin cov_fail++; $display("[COV] MissReadyGen.io_queryMQ_1_req_bits_addr[13] 未见过 0 和 1"); end
    if (!(mrg_s0_io_queryMQ_1_req_bits_addr[14] && mrg_s1_io_queryMQ_1_req_bits_addr[14])) begin cov_fail++; $display("[COV] MissReadyGen.io_queryMQ_1_req_bits_addr[14] 未见过 0 和 1"); end
    if (!(mrg_s0_io_queryMQ_1_req_bits_addr[15] && mrg_s1_io_queryMQ_1_req_bits_addr[15])) begin cov_fail++; $display("[COV] MissReadyGen.io_queryMQ_1_req_bits_addr[15] 未见过 0 和 1"); end
    if (!(mrg_s0_io_queryMQ_1_req_bits_addr[16] && mrg_s1_io_queryMQ_1_req_bits_addr[16])) begin cov_fail++; $display("[COV] MissReadyGen.io_queryMQ_1_req_bits_addr[16] 未见过 0 和 1"); end
    if (!(mrg_s0_io_queryMQ_1_req_bits_addr[17] && mrg_s1_io_queryMQ_1_req_bits_addr[17])) begin cov_fail++; $display("[COV] MissReadyGen.io_queryMQ_1_req_bits_addr[17] 未见过 0 和 1"); end
    if (!(mrg_s0_io_queryMQ_1_req_bits_addr[18] && mrg_s1_io_queryMQ_1_req_bits_addr[18])) begin cov_fail++; $display("[COV] MissReadyGen.io_queryMQ_1_req_bits_addr[18] 未见过 0 和 1"); end
    if (!(mrg_s0_io_queryMQ_1_req_bits_addr[19] && mrg_s1_io_queryMQ_1_req_bits_addr[19])) begin cov_fail++; $display("[COV] MissReadyGen.io_queryMQ_1_req_bits_addr[19] 未见过 0 和 1"); end
    if (!(mrg_s0_io_queryMQ_1_req_bits_addr[20] && mrg_s1_io_queryMQ_1_req_bits_addr[20])) begin cov_fail++; $display("[COV] MissReadyGen.io_queryMQ_1_req_bits_addr[20] 未见过 0 和 1"); end
    if (!(mrg_s0_io_queryMQ_1_req_bits_addr[21] && mrg_s1_io_queryMQ_1_req_bits_addr[21])) begin cov_fail++; $display("[COV] MissReadyGen.io_queryMQ_1_req_bits_addr[21] 未见过 0 和 1"); end
    if (!(mrg_s0_io_queryMQ_1_req_bits_addr[22] && mrg_s1_io_queryMQ_1_req_bits_addr[22])) begin cov_fail++; $display("[COV] MissReadyGen.io_queryMQ_1_req_bits_addr[22] 未见过 0 和 1"); end
    if (!(mrg_s0_io_queryMQ_1_req_bits_addr[23] && mrg_s1_io_queryMQ_1_req_bits_addr[23])) begin cov_fail++; $display("[COV] MissReadyGen.io_queryMQ_1_req_bits_addr[23] 未见过 0 和 1"); end
    if (!(mrg_s0_io_queryMQ_1_req_bits_addr[24] && mrg_s1_io_queryMQ_1_req_bits_addr[24])) begin cov_fail++; $display("[COV] MissReadyGen.io_queryMQ_1_req_bits_addr[24] 未见过 0 和 1"); end
    if (!(mrg_s0_io_queryMQ_1_req_bits_addr[25] && mrg_s1_io_queryMQ_1_req_bits_addr[25])) begin cov_fail++; $display("[COV] MissReadyGen.io_queryMQ_1_req_bits_addr[25] 未见过 0 和 1"); end
    if (!(mrg_s0_io_queryMQ_1_req_bits_addr[26] && mrg_s1_io_queryMQ_1_req_bits_addr[26])) begin cov_fail++; $display("[COV] MissReadyGen.io_queryMQ_1_req_bits_addr[26] 未见过 0 和 1"); end
    if (!(mrg_s0_io_queryMQ_1_req_bits_addr[27] && mrg_s1_io_queryMQ_1_req_bits_addr[27])) begin cov_fail++; $display("[COV] MissReadyGen.io_queryMQ_1_req_bits_addr[27] 未见过 0 和 1"); end
    if (!(mrg_s0_io_queryMQ_1_req_bits_addr[28] && mrg_s1_io_queryMQ_1_req_bits_addr[28])) begin cov_fail++; $display("[COV] MissReadyGen.io_queryMQ_1_req_bits_addr[28] 未见过 0 和 1"); end
    if (!(mrg_s0_io_queryMQ_1_req_bits_addr[29] && mrg_s1_io_queryMQ_1_req_bits_addr[29])) begin cov_fail++; $display("[COV] MissReadyGen.io_queryMQ_1_req_bits_addr[29] 未见过 0 和 1"); end
    if (!(mrg_s0_io_queryMQ_1_req_bits_addr[30] && mrg_s1_io_queryMQ_1_req_bits_addr[30])) begin cov_fail++; $display("[COV] MissReadyGen.io_queryMQ_1_req_bits_addr[30] 未见过 0 和 1"); end
    if (!(mrg_s0_io_queryMQ_1_req_bits_addr[31] && mrg_s1_io_queryMQ_1_req_bits_addr[31])) begin cov_fail++; $display("[COV] MissReadyGen.io_queryMQ_1_req_bits_addr[31] 未见过 0 和 1"); end
    if (!(mrg_s0_io_queryMQ_1_req_bits_addr[32] && mrg_s1_io_queryMQ_1_req_bits_addr[32])) begin cov_fail++; $display("[COV] MissReadyGen.io_queryMQ_1_req_bits_addr[32] 未见过 0 和 1"); end
    if (!(mrg_s0_io_queryMQ_1_req_bits_addr[33] && mrg_s1_io_queryMQ_1_req_bits_addr[33])) begin cov_fail++; $display("[COV] MissReadyGen.io_queryMQ_1_req_bits_addr[33] 未见过 0 和 1"); end
    if (!(mrg_s0_io_queryMQ_1_req_bits_addr[34] && mrg_s1_io_queryMQ_1_req_bits_addr[34])) begin cov_fail++; $display("[COV] MissReadyGen.io_queryMQ_1_req_bits_addr[34] 未见过 0 和 1"); end
    if (!(mrg_s0_io_queryMQ_1_req_bits_addr[35] && mrg_s1_io_queryMQ_1_req_bits_addr[35])) begin cov_fail++; $display("[COV] MissReadyGen.io_queryMQ_1_req_bits_addr[35] 未见过 0 和 1"); end
    if (!(mrg_s0_io_queryMQ_1_req_bits_addr[36] && mrg_s1_io_queryMQ_1_req_bits_addr[36])) begin cov_fail++; $display("[COV] MissReadyGen.io_queryMQ_1_req_bits_addr[36] 未见过 0 和 1"); end
    if (!(mrg_s0_io_queryMQ_1_req_bits_addr[37] && mrg_s1_io_queryMQ_1_req_bits_addr[37])) begin cov_fail++; $display("[COV] MissReadyGen.io_queryMQ_1_req_bits_addr[37] 未见过 0 和 1"); end
    if (!(mrg_s0_io_queryMQ_1_req_bits_addr[38] && mrg_s1_io_queryMQ_1_req_bits_addr[38])) begin cov_fail++; $display("[COV] MissReadyGen.io_queryMQ_1_req_bits_addr[38] 未见过 0 和 1"); end
    if (!(mrg_s0_io_queryMQ_1_req_bits_addr[39] && mrg_s1_io_queryMQ_1_req_bits_addr[39])) begin cov_fail++; $display("[COV] MissReadyGen.io_queryMQ_1_req_bits_addr[39] 未见过 0 和 1"); end
    if (!(mrg_s0_io_queryMQ_1_req_bits_addr[40] && mrg_s1_io_queryMQ_1_req_bits_addr[40])) begin cov_fail++; $display("[COV] MissReadyGen.io_queryMQ_1_req_bits_addr[40] 未见过 0 和 1"); end
    if (!(mrg_s0_io_queryMQ_1_req_bits_addr[41] && mrg_s1_io_queryMQ_1_req_bits_addr[41])) begin cov_fail++; $display("[COV] MissReadyGen.io_queryMQ_1_req_bits_addr[41] 未见过 0 和 1"); end
    if (!(mrg_s0_io_queryMQ_1_req_bits_addr[42] && mrg_s1_io_queryMQ_1_req_bits_addr[42])) begin cov_fail++; $display("[COV] MissReadyGen.io_queryMQ_1_req_bits_addr[42] 未见过 0 和 1"); end
    if (!(mrg_s0_io_queryMQ_1_req_bits_addr[43] && mrg_s1_io_queryMQ_1_req_bits_addr[43])) begin cov_fail++; $display("[COV] MissReadyGen.io_queryMQ_1_req_bits_addr[43] 未见过 0 和 1"); end
    if (!(mrg_s0_io_queryMQ_1_req_bits_addr[44] && mrg_s1_io_queryMQ_1_req_bits_addr[44])) begin cov_fail++; $display("[COV] MissReadyGen.io_queryMQ_1_req_bits_addr[44] 未见过 0 和 1"); end
    if (!(mrg_s0_io_queryMQ_1_req_bits_addr[45] && mrg_s1_io_queryMQ_1_req_bits_addr[45])) begin cov_fail++; $display("[COV] MissReadyGen.io_queryMQ_1_req_bits_addr[45] 未见过 0 和 1"); end
    if (!(mrg_s0_io_queryMQ_1_req_bits_addr[46] && mrg_s1_io_queryMQ_1_req_bits_addr[46])) begin cov_fail++; $display("[COV] MissReadyGen.io_queryMQ_1_req_bits_addr[46] 未见过 0 和 1"); end
    if (!(mrg_s0_io_queryMQ_1_req_bits_addr[47] && mrg_s1_io_queryMQ_1_req_bits_addr[47])) begin cov_fail++; $display("[COV] MissReadyGen.io_queryMQ_1_req_bits_addr[47] 未见过 0 和 1"); end
    if (!(mrg_s0_io_queryMQ_1_req_bits_vaddr[0] && mrg_s1_io_queryMQ_1_req_bits_vaddr[0])) begin cov_fail++; $display("[COV] MissReadyGen.io_queryMQ_1_req_bits_vaddr[0] 未见过 0 和 1"); end
    if (!(mrg_s0_io_queryMQ_1_req_bits_vaddr[1] && mrg_s1_io_queryMQ_1_req_bits_vaddr[1])) begin cov_fail++; $display("[COV] MissReadyGen.io_queryMQ_1_req_bits_vaddr[1] 未见过 0 和 1"); end
    if (!(mrg_s0_io_queryMQ_1_req_bits_vaddr[2] && mrg_s1_io_queryMQ_1_req_bits_vaddr[2])) begin cov_fail++; $display("[COV] MissReadyGen.io_queryMQ_1_req_bits_vaddr[2] 未见过 0 和 1"); end
    if (!(mrg_s0_io_queryMQ_1_req_bits_vaddr[3] && mrg_s1_io_queryMQ_1_req_bits_vaddr[3])) begin cov_fail++; $display("[COV] MissReadyGen.io_queryMQ_1_req_bits_vaddr[3] 未见过 0 和 1"); end
    if (!(mrg_s0_io_queryMQ_1_req_bits_vaddr[4] && mrg_s1_io_queryMQ_1_req_bits_vaddr[4])) begin cov_fail++; $display("[COV] MissReadyGen.io_queryMQ_1_req_bits_vaddr[4] 未见过 0 和 1"); end
    if (!(mrg_s0_io_queryMQ_1_req_bits_vaddr[5] && mrg_s1_io_queryMQ_1_req_bits_vaddr[5])) begin cov_fail++; $display("[COV] MissReadyGen.io_queryMQ_1_req_bits_vaddr[5] 未见过 0 和 1"); end
    if (!(mrg_s0_io_queryMQ_1_req_bits_vaddr[6] && mrg_s1_io_queryMQ_1_req_bits_vaddr[6])) begin cov_fail++; $display("[COV] MissReadyGen.io_queryMQ_1_req_bits_vaddr[6] 未见过 0 和 1"); end
    if (!(mrg_s0_io_queryMQ_1_req_bits_vaddr[7] && mrg_s1_io_queryMQ_1_req_bits_vaddr[7])) begin cov_fail++; $display("[COV] MissReadyGen.io_queryMQ_1_req_bits_vaddr[7] 未见过 0 和 1"); end
    if (!(mrg_s0_io_queryMQ_1_req_bits_vaddr[8] && mrg_s1_io_queryMQ_1_req_bits_vaddr[8])) begin cov_fail++; $display("[COV] MissReadyGen.io_queryMQ_1_req_bits_vaddr[8] 未见过 0 和 1"); end
    if (!(mrg_s0_io_queryMQ_1_req_bits_vaddr[9] && mrg_s1_io_queryMQ_1_req_bits_vaddr[9])) begin cov_fail++; $display("[COV] MissReadyGen.io_queryMQ_1_req_bits_vaddr[9] 未见过 0 和 1"); end
    if (!(mrg_s0_io_queryMQ_1_req_bits_vaddr[10] && mrg_s1_io_queryMQ_1_req_bits_vaddr[10])) begin cov_fail++; $display("[COV] MissReadyGen.io_queryMQ_1_req_bits_vaddr[10] 未见过 0 和 1"); end
    if (!(mrg_s0_io_queryMQ_1_req_bits_vaddr[11] && mrg_s1_io_queryMQ_1_req_bits_vaddr[11])) begin cov_fail++; $display("[COV] MissReadyGen.io_queryMQ_1_req_bits_vaddr[11] 未见过 0 和 1"); end
    if (!(mrg_s0_io_queryMQ_1_req_bits_vaddr[12] && mrg_s1_io_queryMQ_1_req_bits_vaddr[12])) begin cov_fail++; $display("[COV] MissReadyGen.io_queryMQ_1_req_bits_vaddr[12] 未见过 0 和 1"); end
    if (!(mrg_s0_io_queryMQ_1_req_bits_vaddr[13] && mrg_s1_io_queryMQ_1_req_bits_vaddr[13])) begin cov_fail++; $display("[COV] MissReadyGen.io_queryMQ_1_req_bits_vaddr[13] 未见过 0 和 1"); end
    if (!(mrg_s0_io_queryMQ_1_req_bits_vaddr[14] && mrg_s1_io_queryMQ_1_req_bits_vaddr[14])) begin cov_fail++; $display("[COV] MissReadyGen.io_queryMQ_1_req_bits_vaddr[14] 未见过 0 和 1"); end
    if (!(mrg_s0_io_queryMQ_1_req_bits_vaddr[15] && mrg_s1_io_queryMQ_1_req_bits_vaddr[15])) begin cov_fail++; $display("[COV] MissReadyGen.io_queryMQ_1_req_bits_vaddr[15] 未见过 0 和 1"); end
    if (!(mrg_s0_io_queryMQ_1_req_bits_vaddr[16] && mrg_s1_io_queryMQ_1_req_bits_vaddr[16])) begin cov_fail++; $display("[COV] MissReadyGen.io_queryMQ_1_req_bits_vaddr[16] 未见过 0 和 1"); end
    if (!(mrg_s0_io_queryMQ_1_req_bits_vaddr[17] && mrg_s1_io_queryMQ_1_req_bits_vaddr[17])) begin cov_fail++; $display("[COV] MissReadyGen.io_queryMQ_1_req_bits_vaddr[17] 未见过 0 和 1"); end
    if (!(mrg_s0_io_queryMQ_1_req_bits_vaddr[18] && mrg_s1_io_queryMQ_1_req_bits_vaddr[18])) begin cov_fail++; $display("[COV] MissReadyGen.io_queryMQ_1_req_bits_vaddr[18] 未见过 0 和 1"); end
    if (!(mrg_s0_io_queryMQ_1_req_bits_vaddr[19] && mrg_s1_io_queryMQ_1_req_bits_vaddr[19])) begin cov_fail++; $display("[COV] MissReadyGen.io_queryMQ_1_req_bits_vaddr[19] 未见过 0 和 1"); end
    if (!(mrg_s0_io_queryMQ_1_req_bits_vaddr[20] && mrg_s1_io_queryMQ_1_req_bits_vaddr[20])) begin cov_fail++; $display("[COV] MissReadyGen.io_queryMQ_1_req_bits_vaddr[20] 未见过 0 和 1"); end
    if (!(mrg_s0_io_queryMQ_1_req_bits_vaddr[21] && mrg_s1_io_queryMQ_1_req_bits_vaddr[21])) begin cov_fail++; $display("[COV] MissReadyGen.io_queryMQ_1_req_bits_vaddr[21] 未见过 0 和 1"); end
    if (!(mrg_s0_io_queryMQ_1_req_bits_vaddr[22] && mrg_s1_io_queryMQ_1_req_bits_vaddr[22])) begin cov_fail++; $display("[COV] MissReadyGen.io_queryMQ_1_req_bits_vaddr[22] 未见过 0 和 1"); end
    if (!(mrg_s0_io_queryMQ_1_req_bits_vaddr[23] && mrg_s1_io_queryMQ_1_req_bits_vaddr[23])) begin cov_fail++; $display("[COV] MissReadyGen.io_queryMQ_1_req_bits_vaddr[23] 未见过 0 和 1"); end
    if (!(mrg_s0_io_queryMQ_1_req_bits_vaddr[24] && mrg_s1_io_queryMQ_1_req_bits_vaddr[24])) begin cov_fail++; $display("[COV] MissReadyGen.io_queryMQ_1_req_bits_vaddr[24] 未见过 0 和 1"); end
    if (!(mrg_s0_io_queryMQ_1_req_bits_vaddr[25] && mrg_s1_io_queryMQ_1_req_bits_vaddr[25])) begin cov_fail++; $display("[COV] MissReadyGen.io_queryMQ_1_req_bits_vaddr[25] 未见过 0 和 1"); end
    if (!(mrg_s0_io_queryMQ_1_req_bits_vaddr[26] && mrg_s1_io_queryMQ_1_req_bits_vaddr[26])) begin cov_fail++; $display("[COV] MissReadyGen.io_queryMQ_1_req_bits_vaddr[26] 未见过 0 和 1"); end
    if (!(mrg_s0_io_queryMQ_1_req_bits_vaddr[27] && mrg_s1_io_queryMQ_1_req_bits_vaddr[27])) begin cov_fail++; $display("[COV] MissReadyGen.io_queryMQ_1_req_bits_vaddr[27] 未见过 0 和 1"); end
    if (!(mrg_s0_io_queryMQ_1_req_bits_vaddr[28] && mrg_s1_io_queryMQ_1_req_bits_vaddr[28])) begin cov_fail++; $display("[COV] MissReadyGen.io_queryMQ_1_req_bits_vaddr[28] 未见过 0 和 1"); end
    if (!(mrg_s0_io_queryMQ_1_req_bits_vaddr[29] && mrg_s1_io_queryMQ_1_req_bits_vaddr[29])) begin cov_fail++; $display("[COV] MissReadyGen.io_queryMQ_1_req_bits_vaddr[29] 未见过 0 和 1"); end
    if (!(mrg_s0_io_queryMQ_1_req_bits_vaddr[30] && mrg_s1_io_queryMQ_1_req_bits_vaddr[30])) begin cov_fail++; $display("[COV] MissReadyGen.io_queryMQ_1_req_bits_vaddr[30] 未见过 0 和 1"); end
    if (!(mrg_s0_io_queryMQ_1_req_bits_vaddr[31] && mrg_s1_io_queryMQ_1_req_bits_vaddr[31])) begin cov_fail++; $display("[COV] MissReadyGen.io_queryMQ_1_req_bits_vaddr[31] 未见过 0 和 1"); end
    if (!(mrg_s0_io_queryMQ_1_req_bits_vaddr[32] && mrg_s1_io_queryMQ_1_req_bits_vaddr[32])) begin cov_fail++; $display("[COV] MissReadyGen.io_queryMQ_1_req_bits_vaddr[32] 未见过 0 和 1"); end
    if (!(mrg_s0_io_queryMQ_1_req_bits_vaddr[33] && mrg_s1_io_queryMQ_1_req_bits_vaddr[33])) begin cov_fail++; $display("[COV] MissReadyGen.io_queryMQ_1_req_bits_vaddr[33] 未见过 0 和 1"); end
    if (!(mrg_s0_io_queryMQ_1_req_bits_vaddr[34] && mrg_s1_io_queryMQ_1_req_bits_vaddr[34])) begin cov_fail++; $display("[COV] MissReadyGen.io_queryMQ_1_req_bits_vaddr[34] 未见过 0 和 1"); end
    if (!(mrg_s0_io_queryMQ_1_req_bits_vaddr[35] && mrg_s1_io_queryMQ_1_req_bits_vaddr[35])) begin cov_fail++; $display("[COV] MissReadyGen.io_queryMQ_1_req_bits_vaddr[35] 未见过 0 和 1"); end
    if (!(mrg_s0_io_queryMQ_1_req_bits_vaddr[36] && mrg_s1_io_queryMQ_1_req_bits_vaddr[36])) begin cov_fail++; $display("[COV] MissReadyGen.io_queryMQ_1_req_bits_vaddr[36] 未见过 0 和 1"); end
    if (!(mrg_s0_io_queryMQ_1_req_bits_vaddr[37] && mrg_s1_io_queryMQ_1_req_bits_vaddr[37])) begin cov_fail++; $display("[COV] MissReadyGen.io_queryMQ_1_req_bits_vaddr[37] 未见过 0 和 1"); end
    if (!(mrg_s0_io_queryMQ_1_req_bits_vaddr[38] && mrg_s1_io_queryMQ_1_req_bits_vaddr[38])) begin cov_fail++; $display("[COV] MissReadyGen.io_queryMQ_1_req_bits_vaddr[38] 未见过 0 和 1"); end
    if (!(mrg_s0_io_queryMQ_1_req_bits_vaddr[39] && mrg_s1_io_queryMQ_1_req_bits_vaddr[39])) begin cov_fail++; $display("[COV] MissReadyGen.io_queryMQ_1_req_bits_vaddr[39] 未见过 0 和 1"); end
    if (!(mrg_s0_io_queryMQ_1_req_bits_vaddr[40] && mrg_s1_io_queryMQ_1_req_bits_vaddr[40])) begin cov_fail++; $display("[COV] MissReadyGen.io_queryMQ_1_req_bits_vaddr[40] 未见过 0 和 1"); end
    if (!(mrg_s0_io_queryMQ_1_req_bits_vaddr[41] && mrg_s1_io_queryMQ_1_req_bits_vaddr[41])) begin cov_fail++; $display("[COV] MissReadyGen.io_queryMQ_1_req_bits_vaddr[41] 未见过 0 和 1"); end
    if (!(mrg_s0_io_queryMQ_1_req_bits_vaddr[42] && mrg_s1_io_queryMQ_1_req_bits_vaddr[42])) begin cov_fail++; $display("[COV] MissReadyGen.io_queryMQ_1_req_bits_vaddr[42] 未见过 0 和 1"); end
    if (!(mrg_s0_io_queryMQ_1_req_bits_vaddr[43] && mrg_s1_io_queryMQ_1_req_bits_vaddr[43])) begin cov_fail++; $display("[COV] MissReadyGen.io_queryMQ_1_req_bits_vaddr[43] 未见过 0 和 1"); end
    if (!(mrg_s0_io_queryMQ_1_req_bits_vaddr[44] && mrg_s1_io_queryMQ_1_req_bits_vaddr[44])) begin cov_fail++; $display("[COV] MissReadyGen.io_queryMQ_1_req_bits_vaddr[44] 未见过 0 和 1"); end
    if (!(mrg_s0_io_queryMQ_1_req_bits_vaddr[45] && mrg_s1_io_queryMQ_1_req_bits_vaddr[45])) begin cov_fail++; $display("[COV] MissReadyGen.io_queryMQ_1_req_bits_vaddr[45] 未见过 0 和 1"); end
    if (!(mrg_s0_io_queryMQ_1_req_bits_vaddr[46] && mrg_s1_io_queryMQ_1_req_bits_vaddr[46])) begin cov_fail++; $display("[COV] MissReadyGen.io_queryMQ_1_req_bits_vaddr[46] 未见过 0 和 1"); end
    if (!(mrg_s0_io_queryMQ_1_req_bits_vaddr[47] && mrg_s1_io_queryMQ_1_req_bits_vaddr[47])) begin cov_fail++; $display("[COV] MissReadyGen.io_queryMQ_1_req_bits_vaddr[47] 未见过 0 和 1"); end
    if (!(mrg_s0_io_queryMQ_1_req_bits_vaddr[48] && mrg_s1_io_queryMQ_1_req_bits_vaddr[48])) begin cov_fail++; $display("[COV] MissReadyGen.io_queryMQ_1_req_bits_vaddr[48] 未见过 0 和 1"); end
    if (!(mrg_s0_io_queryMQ_1_req_bits_vaddr[49] && mrg_s1_io_queryMQ_1_req_bits_vaddr[49])) begin cov_fail++; $display("[COV] MissReadyGen.io_queryMQ_1_req_bits_vaddr[49] 未见过 0 和 1"); end
    if (!(mrg_s0_io_queryMQ_2_req_bits_source[0] && mrg_s1_io_queryMQ_2_req_bits_source[0])) begin cov_fail++; $display("[COV] MissReadyGen.io_queryMQ_2_req_bits_source[0] 未见过 0 和 1"); end
    if (!(mrg_s0_io_queryMQ_2_req_bits_source[1] && mrg_s1_io_queryMQ_2_req_bits_source[1])) begin cov_fail++; $display("[COV] MissReadyGen.io_queryMQ_2_req_bits_source[1] 未见过 0 和 1"); end
    if (!(mrg_s0_io_queryMQ_2_req_bits_source[2] && mrg_s1_io_queryMQ_2_req_bits_source[2])) begin cov_fail++; $display("[COV] MissReadyGen.io_queryMQ_2_req_bits_source[2] 未见过 0 和 1"); end
    if (!(mrg_s0_io_queryMQ_2_req_bits_source[3] && mrg_s1_io_queryMQ_2_req_bits_source[3])) begin cov_fail++; $display("[COV] MissReadyGen.io_queryMQ_2_req_bits_source[3] 未见过 0 和 1"); end
    if (!(mrg_s0_io_queryMQ_2_req_bits_addr[0] && mrg_s1_io_queryMQ_2_req_bits_addr[0])) begin cov_fail++; $display("[COV] MissReadyGen.io_queryMQ_2_req_bits_addr[0] 未见过 0 和 1"); end
    if (!(mrg_s0_io_queryMQ_2_req_bits_addr[1] && mrg_s1_io_queryMQ_2_req_bits_addr[1])) begin cov_fail++; $display("[COV] MissReadyGen.io_queryMQ_2_req_bits_addr[1] 未见过 0 和 1"); end
    if (!(mrg_s0_io_queryMQ_2_req_bits_addr[2] && mrg_s1_io_queryMQ_2_req_bits_addr[2])) begin cov_fail++; $display("[COV] MissReadyGen.io_queryMQ_2_req_bits_addr[2] 未见过 0 和 1"); end
    if (!(mrg_s0_io_queryMQ_2_req_bits_addr[3] && mrg_s1_io_queryMQ_2_req_bits_addr[3])) begin cov_fail++; $display("[COV] MissReadyGen.io_queryMQ_2_req_bits_addr[3] 未见过 0 和 1"); end
    if (!(mrg_s0_io_queryMQ_2_req_bits_addr[4] && mrg_s1_io_queryMQ_2_req_bits_addr[4])) begin cov_fail++; $display("[COV] MissReadyGen.io_queryMQ_2_req_bits_addr[4] 未见过 0 和 1"); end
    if (!(mrg_s0_io_queryMQ_2_req_bits_addr[5] && mrg_s1_io_queryMQ_2_req_bits_addr[5])) begin cov_fail++; $display("[COV] MissReadyGen.io_queryMQ_2_req_bits_addr[5] 未见过 0 和 1"); end
    if (!(mrg_s0_io_queryMQ_2_req_bits_addr[6] && mrg_s1_io_queryMQ_2_req_bits_addr[6])) begin cov_fail++; $display("[COV] MissReadyGen.io_queryMQ_2_req_bits_addr[6] 未见过 0 和 1"); end
    if (!(mrg_s0_io_queryMQ_2_req_bits_addr[7] && mrg_s1_io_queryMQ_2_req_bits_addr[7])) begin cov_fail++; $display("[COV] MissReadyGen.io_queryMQ_2_req_bits_addr[7] 未见过 0 和 1"); end
    if (!(mrg_s0_io_queryMQ_2_req_bits_addr[8] && mrg_s1_io_queryMQ_2_req_bits_addr[8])) begin cov_fail++; $display("[COV] MissReadyGen.io_queryMQ_2_req_bits_addr[8] 未见过 0 和 1"); end
    if (!(mrg_s0_io_queryMQ_2_req_bits_addr[9] && mrg_s1_io_queryMQ_2_req_bits_addr[9])) begin cov_fail++; $display("[COV] MissReadyGen.io_queryMQ_2_req_bits_addr[9] 未见过 0 和 1"); end
    if (!(mrg_s0_io_queryMQ_2_req_bits_addr[10] && mrg_s1_io_queryMQ_2_req_bits_addr[10])) begin cov_fail++; $display("[COV] MissReadyGen.io_queryMQ_2_req_bits_addr[10] 未见过 0 和 1"); end
    if (!(mrg_s0_io_queryMQ_2_req_bits_addr[11] && mrg_s1_io_queryMQ_2_req_bits_addr[11])) begin cov_fail++; $display("[COV] MissReadyGen.io_queryMQ_2_req_bits_addr[11] 未见过 0 和 1"); end
    if (!(mrg_s0_io_queryMQ_2_req_bits_addr[12] && mrg_s1_io_queryMQ_2_req_bits_addr[12])) begin cov_fail++; $display("[COV] MissReadyGen.io_queryMQ_2_req_bits_addr[12] 未见过 0 和 1"); end
    if (!(mrg_s0_io_queryMQ_2_req_bits_addr[13] && mrg_s1_io_queryMQ_2_req_bits_addr[13])) begin cov_fail++; $display("[COV] MissReadyGen.io_queryMQ_2_req_bits_addr[13] 未见过 0 和 1"); end
    if (!(mrg_s0_io_queryMQ_2_req_bits_addr[14] && mrg_s1_io_queryMQ_2_req_bits_addr[14])) begin cov_fail++; $display("[COV] MissReadyGen.io_queryMQ_2_req_bits_addr[14] 未见过 0 和 1"); end
    if (!(mrg_s0_io_queryMQ_2_req_bits_addr[15] && mrg_s1_io_queryMQ_2_req_bits_addr[15])) begin cov_fail++; $display("[COV] MissReadyGen.io_queryMQ_2_req_bits_addr[15] 未见过 0 和 1"); end
    if (!(mrg_s0_io_queryMQ_2_req_bits_addr[16] && mrg_s1_io_queryMQ_2_req_bits_addr[16])) begin cov_fail++; $display("[COV] MissReadyGen.io_queryMQ_2_req_bits_addr[16] 未见过 0 和 1"); end
    if (!(mrg_s0_io_queryMQ_2_req_bits_addr[17] && mrg_s1_io_queryMQ_2_req_bits_addr[17])) begin cov_fail++; $display("[COV] MissReadyGen.io_queryMQ_2_req_bits_addr[17] 未见过 0 和 1"); end
    if (!(mrg_s0_io_queryMQ_2_req_bits_addr[18] && mrg_s1_io_queryMQ_2_req_bits_addr[18])) begin cov_fail++; $display("[COV] MissReadyGen.io_queryMQ_2_req_bits_addr[18] 未见过 0 和 1"); end
    if (!(mrg_s0_io_queryMQ_2_req_bits_addr[19] && mrg_s1_io_queryMQ_2_req_bits_addr[19])) begin cov_fail++; $display("[COV] MissReadyGen.io_queryMQ_2_req_bits_addr[19] 未见过 0 和 1"); end
    if (!(mrg_s0_io_queryMQ_2_req_bits_addr[20] && mrg_s1_io_queryMQ_2_req_bits_addr[20])) begin cov_fail++; $display("[COV] MissReadyGen.io_queryMQ_2_req_bits_addr[20] 未见过 0 和 1"); end
    if (!(mrg_s0_io_queryMQ_2_req_bits_addr[21] && mrg_s1_io_queryMQ_2_req_bits_addr[21])) begin cov_fail++; $display("[COV] MissReadyGen.io_queryMQ_2_req_bits_addr[21] 未见过 0 和 1"); end
    if (!(mrg_s0_io_queryMQ_2_req_bits_addr[22] && mrg_s1_io_queryMQ_2_req_bits_addr[22])) begin cov_fail++; $display("[COV] MissReadyGen.io_queryMQ_2_req_bits_addr[22] 未见过 0 和 1"); end
    if (!(mrg_s0_io_queryMQ_2_req_bits_addr[23] && mrg_s1_io_queryMQ_2_req_bits_addr[23])) begin cov_fail++; $display("[COV] MissReadyGen.io_queryMQ_2_req_bits_addr[23] 未见过 0 和 1"); end
    if (!(mrg_s0_io_queryMQ_2_req_bits_addr[24] && mrg_s1_io_queryMQ_2_req_bits_addr[24])) begin cov_fail++; $display("[COV] MissReadyGen.io_queryMQ_2_req_bits_addr[24] 未见过 0 和 1"); end
    if (!(mrg_s0_io_queryMQ_2_req_bits_addr[25] && mrg_s1_io_queryMQ_2_req_bits_addr[25])) begin cov_fail++; $display("[COV] MissReadyGen.io_queryMQ_2_req_bits_addr[25] 未见过 0 和 1"); end
    if (!(mrg_s0_io_queryMQ_2_req_bits_addr[26] && mrg_s1_io_queryMQ_2_req_bits_addr[26])) begin cov_fail++; $display("[COV] MissReadyGen.io_queryMQ_2_req_bits_addr[26] 未见过 0 和 1"); end
    if (!(mrg_s0_io_queryMQ_2_req_bits_addr[27] && mrg_s1_io_queryMQ_2_req_bits_addr[27])) begin cov_fail++; $display("[COV] MissReadyGen.io_queryMQ_2_req_bits_addr[27] 未见过 0 和 1"); end
    if (!(mrg_s0_io_queryMQ_2_req_bits_addr[28] && mrg_s1_io_queryMQ_2_req_bits_addr[28])) begin cov_fail++; $display("[COV] MissReadyGen.io_queryMQ_2_req_bits_addr[28] 未见过 0 和 1"); end
    if (!(mrg_s0_io_queryMQ_2_req_bits_addr[29] && mrg_s1_io_queryMQ_2_req_bits_addr[29])) begin cov_fail++; $display("[COV] MissReadyGen.io_queryMQ_2_req_bits_addr[29] 未见过 0 和 1"); end
    if (!(mrg_s0_io_queryMQ_2_req_bits_addr[30] && mrg_s1_io_queryMQ_2_req_bits_addr[30])) begin cov_fail++; $display("[COV] MissReadyGen.io_queryMQ_2_req_bits_addr[30] 未见过 0 和 1"); end
    if (!(mrg_s0_io_queryMQ_2_req_bits_addr[31] && mrg_s1_io_queryMQ_2_req_bits_addr[31])) begin cov_fail++; $display("[COV] MissReadyGen.io_queryMQ_2_req_bits_addr[31] 未见过 0 和 1"); end
    if (!(mrg_s0_io_queryMQ_2_req_bits_addr[32] && mrg_s1_io_queryMQ_2_req_bits_addr[32])) begin cov_fail++; $display("[COV] MissReadyGen.io_queryMQ_2_req_bits_addr[32] 未见过 0 和 1"); end
    if (!(mrg_s0_io_queryMQ_2_req_bits_addr[33] && mrg_s1_io_queryMQ_2_req_bits_addr[33])) begin cov_fail++; $display("[COV] MissReadyGen.io_queryMQ_2_req_bits_addr[33] 未见过 0 和 1"); end
    if (!(mrg_s0_io_queryMQ_2_req_bits_addr[34] && mrg_s1_io_queryMQ_2_req_bits_addr[34])) begin cov_fail++; $display("[COV] MissReadyGen.io_queryMQ_2_req_bits_addr[34] 未见过 0 和 1"); end
    if (!(mrg_s0_io_queryMQ_2_req_bits_addr[35] && mrg_s1_io_queryMQ_2_req_bits_addr[35])) begin cov_fail++; $display("[COV] MissReadyGen.io_queryMQ_2_req_bits_addr[35] 未见过 0 和 1"); end
    if (!(mrg_s0_io_queryMQ_2_req_bits_addr[36] && mrg_s1_io_queryMQ_2_req_bits_addr[36])) begin cov_fail++; $display("[COV] MissReadyGen.io_queryMQ_2_req_bits_addr[36] 未见过 0 和 1"); end
    if (!(mrg_s0_io_queryMQ_2_req_bits_addr[37] && mrg_s1_io_queryMQ_2_req_bits_addr[37])) begin cov_fail++; $display("[COV] MissReadyGen.io_queryMQ_2_req_bits_addr[37] 未见过 0 和 1"); end
    if (!(mrg_s0_io_queryMQ_2_req_bits_addr[38] && mrg_s1_io_queryMQ_2_req_bits_addr[38])) begin cov_fail++; $display("[COV] MissReadyGen.io_queryMQ_2_req_bits_addr[38] 未见过 0 和 1"); end
    if (!(mrg_s0_io_queryMQ_2_req_bits_addr[39] && mrg_s1_io_queryMQ_2_req_bits_addr[39])) begin cov_fail++; $display("[COV] MissReadyGen.io_queryMQ_2_req_bits_addr[39] 未见过 0 和 1"); end
    if (!(mrg_s0_io_queryMQ_2_req_bits_addr[40] && mrg_s1_io_queryMQ_2_req_bits_addr[40])) begin cov_fail++; $display("[COV] MissReadyGen.io_queryMQ_2_req_bits_addr[40] 未见过 0 和 1"); end
    if (!(mrg_s0_io_queryMQ_2_req_bits_addr[41] && mrg_s1_io_queryMQ_2_req_bits_addr[41])) begin cov_fail++; $display("[COV] MissReadyGen.io_queryMQ_2_req_bits_addr[41] 未见过 0 和 1"); end
    if (!(mrg_s0_io_queryMQ_2_req_bits_addr[42] && mrg_s1_io_queryMQ_2_req_bits_addr[42])) begin cov_fail++; $display("[COV] MissReadyGen.io_queryMQ_2_req_bits_addr[42] 未见过 0 和 1"); end
    if (!(mrg_s0_io_queryMQ_2_req_bits_addr[43] && mrg_s1_io_queryMQ_2_req_bits_addr[43])) begin cov_fail++; $display("[COV] MissReadyGen.io_queryMQ_2_req_bits_addr[43] 未见过 0 和 1"); end
    if (!(mrg_s0_io_queryMQ_2_req_bits_addr[44] && mrg_s1_io_queryMQ_2_req_bits_addr[44])) begin cov_fail++; $display("[COV] MissReadyGen.io_queryMQ_2_req_bits_addr[44] 未见过 0 和 1"); end
    if (!(mrg_s0_io_queryMQ_2_req_bits_addr[45] && mrg_s1_io_queryMQ_2_req_bits_addr[45])) begin cov_fail++; $display("[COV] MissReadyGen.io_queryMQ_2_req_bits_addr[45] 未见过 0 和 1"); end
    if (!(mrg_s0_io_queryMQ_2_req_bits_addr[46] && mrg_s1_io_queryMQ_2_req_bits_addr[46])) begin cov_fail++; $display("[COV] MissReadyGen.io_queryMQ_2_req_bits_addr[46] 未见过 0 和 1"); end
    if (!(mrg_s0_io_queryMQ_2_req_bits_addr[47] && mrg_s1_io_queryMQ_2_req_bits_addr[47])) begin cov_fail++; $display("[COV] MissReadyGen.io_queryMQ_2_req_bits_addr[47] 未见过 0 和 1"); end
    if (!(mrg_s0_io_queryMQ_2_req_bits_vaddr[0] && mrg_s1_io_queryMQ_2_req_bits_vaddr[0])) begin cov_fail++; $display("[COV] MissReadyGen.io_queryMQ_2_req_bits_vaddr[0] 未见过 0 和 1"); end
    if (!(mrg_s0_io_queryMQ_2_req_bits_vaddr[1] && mrg_s1_io_queryMQ_2_req_bits_vaddr[1])) begin cov_fail++; $display("[COV] MissReadyGen.io_queryMQ_2_req_bits_vaddr[1] 未见过 0 和 1"); end
    if (!(mrg_s0_io_queryMQ_2_req_bits_vaddr[2] && mrg_s1_io_queryMQ_2_req_bits_vaddr[2])) begin cov_fail++; $display("[COV] MissReadyGen.io_queryMQ_2_req_bits_vaddr[2] 未见过 0 和 1"); end
    if (!(mrg_s0_io_queryMQ_2_req_bits_vaddr[3] && mrg_s1_io_queryMQ_2_req_bits_vaddr[3])) begin cov_fail++; $display("[COV] MissReadyGen.io_queryMQ_2_req_bits_vaddr[3] 未见过 0 和 1"); end
    if (!(mrg_s0_io_queryMQ_2_req_bits_vaddr[4] && mrg_s1_io_queryMQ_2_req_bits_vaddr[4])) begin cov_fail++; $display("[COV] MissReadyGen.io_queryMQ_2_req_bits_vaddr[4] 未见过 0 和 1"); end
    if (!(mrg_s0_io_queryMQ_2_req_bits_vaddr[5] && mrg_s1_io_queryMQ_2_req_bits_vaddr[5])) begin cov_fail++; $display("[COV] MissReadyGen.io_queryMQ_2_req_bits_vaddr[5] 未见过 0 和 1"); end
    if (!(mrg_s0_io_queryMQ_2_req_bits_vaddr[6] && mrg_s1_io_queryMQ_2_req_bits_vaddr[6])) begin cov_fail++; $display("[COV] MissReadyGen.io_queryMQ_2_req_bits_vaddr[6] 未见过 0 和 1"); end
    if (!(mrg_s0_io_queryMQ_2_req_bits_vaddr[7] && mrg_s1_io_queryMQ_2_req_bits_vaddr[7])) begin cov_fail++; $display("[COV] MissReadyGen.io_queryMQ_2_req_bits_vaddr[7] 未见过 0 和 1"); end
    if (!(mrg_s0_io_queryMQ_2_req_bits_vaddr[8] && mrg_s1_io_queryMQ_2_req_bits_vaddr[8])) begin cov_fail++; $display("[COV] MissReadyGen.io_queryMQ_2_req_bits_vaddr[8] 未见过 0 和 1"); end
    if (!(mrg_s0_io_queryMQ_2_req_bits_vaddr[9] && mrg_s1_io_queryMQ_2_req_bits_vaddr[9])) begin cov_fail++; $display("[COV] MissReadyGen.io_queryMQ_2_req_bits_vaddr[9] 未见过 0 和 1"); end
    if (!(mrg_s0_io_queryMQ_2_req_bits_vaddr[10] && mrg_s1_io_queryMQ_2_req_bits_vaddr[10])) begin cov_fail++; $display("[COV] MissReadyGen.io_queryMQ_2_req_bits_vaddr[10] 未见过 0 和 1"); end
    if (!(mrg_s0_io_queryMQ_2_req_bits_vaddr[11] && mrg_s1_io_queryMQ_2_req_bits_vaddr[11])) begin cov_fail++; $display("[COV] MissReadyGen.io_queryMQ_2_req_bits_vaddr[11] 未见过 0 和 1"); end
    if (!(mrg_s0_io_queryMQ_2_req_bits_vaddr[12] && mrg_s1_io_queryMQ_2_req_bits_vaddr[12])) begin cov_fail++; $display("[COV] MissReadyGen.io_queryMQ_2_req_bits_vaddr[12] 未见过 0 和 1"); end
    if (!(mrg_s0_io_queryMQ_2_req_bits_vaddr[13] && mrg_s1_io_queryMQ_2_req_bits_vaddr[13])) begin cov_fail++; $display("[COV] MissReadyGen.io_queryMQ_2_req_bits_vaddr[13] 未见过 0 和 1"); end
    if (!(mrg_s0_io_queryMQ_2_req_bits_vaddr[14] && mrg_s1_io_queryMQ_2_req_bits_vaddr[14])) begin cov_fail++; $display("[COV] MissReadyGen.io_queryMQ_2_req_bits_vaddr[14] 未见过 0 和 1"); end
    if (!(mrg_s0_io_queryMQ_2_req_bits_vaddr[15] && mrg_s1_io_queryMQ_2_req_bits_vaddr[15])) begin cov_fail++; $display("[COV] MissReadyGen.io_queryMQ_2_req_bits_vaddr[15] 未见过 0 和 1"); end
    if (!(mrg_s0_io_queryMQ_2_req_bits_vaddr[16] && mrg_s1_io_queryMQ_2_req_bits_vaddr[16])) begin cov_fail++; $display("[COV] MissReadyGen.io_queryMQ_2_req_bits_vaddr[16] 未见过 0 和 1"); end
    if (!(mrg_s0_io_queryMQ_2_req_bits_vaddr[17] && mrg_s1_io_queryMQ_2_req_bits_vaddr[17])) begin cov_fail++; $display("[COV] MissReadyGen.io_queryMQ_2_req_bits_vaddr[17] 未见过 0 和 1"); end
    if (!(mrg_s0_io_queryMQ_2_req_bits_vaddr[18] && mrg_s1_io_queryMQ_2_req_bits_vaddr[18])) begin cov_fail++; $display("[COV] MissReadyGen.io_queryMQ_2_req_bits_vaddr[18] 未见过 0 和 1"); end
    if (!(mrg_s0_io_queryMQ_2_req_bits_vaddr[19] && mrg_s1_io_queryMQ_2_req_bits_vaddr[19])) begin cov_fail++; $display("[COV] MissReadyGen.io_queryMQ_2_req_bits_vaddr[19] 未见过 0 和 1"); end
    if (!(mrg_s0_io_queryMQ_2_req_bits_vaddr[20] && mrg_s1_io_queryMQ_2_req_bits_vaddr[20])) begin cov_fail++; $display("[COV] MissReadyGen.io_queryMQ_2_req_bits_vaddr[20] 未见过 0 和 1"); end
    if (!(mrg_s0_io_queryMQ_2_req_bits_vaddr[21] && mrg_s1_io_queryMQ_2_req_bits_vaddr[21])) begin cov_fail++; $display("[COV] MissReadyGen.io_queryMQ_2_req_bits_vaddr[21] 未见过 0 和 1"); end
    if (!(mrg_s0_io_queryMQ_2_req_bits_vaddr[22] && mrg_s1_io_queryMQ_2_req_bits_vaddr[22])) begin cov_fail++; $display("[COV] MissReadyGen.io_queryMQ_2_req_bits_vaddr[22] 未见过 0 和 1"); end
    if (!(mrg_s0_io_queryMQ_2_req_bits_vaddr[23] && mrg_s1_io_queryMQ_2_req_bits_vaddr[23])) begin cov_fail++; $display("[COV] MissReadyGen.io_queryMQ_2_req_bits_vaddr[23] 未见过 0 和 1"); end
    if (!(mrg_s0_io_queryMQ_2_req_bits_vaddr[24] && mrg_s1_io_queryMQ_2_req_bits_vaddr[24])) begin cov_fail++; $display("[COV] MissReadyGen.io_queryMQ_2_req_bits_vaddr[24] 未见过 0 和 1"); end
    if (!(mrg_s0_io_queryMQ_2_req_bits_vaddr[25] && mrg_s1_io_queryMQ_2_req_bits_vaddr[25])) begin cov_fail++; $display("[COV] MissReadyGen.io_queryMQ_2_req_bits_vaddr[25] 未见过 0 和 1"); end
    if (!(mrg_s0_io_queryMQ_2_req_bits_vaddr[26] && mrg_s1_io_queryMQ_2_req_bits_vaddr[26])) begin cov_fail++; $display("[COV] MissReadyGen.io_queryMQ_2_req_bits_vaddr[26] 未见过 0 和 1"); end
    if (!(mrg_s0_io_queryMQ_2_req_bits_vaddr[27] && mrg_s1_io_queryMQ_2_req_bits_vaddr[27])) begin cov_fail++; $display("[COV] MissReadyGen.io_queryMQ_2_req_bits_vaddr[27] 未见过 0 和 1"); end
    if (!(mrg_s0_io_queryMQ_2_req_bits_vaddr[28] && mrg_s1_io_queryMQ_2_req_bits_vaddr[28])) begin cov_fail++; $display("[COV] MissReadyGen.io_queryMQ_2_req_bits_vaddr[28] 未见过 0 和 1"); end
    if (!(mrg_s0_io_queryMQ_2_req_bits_vaddr[29] && mrg_s1_io_queryMQ_2_req_bits_vaddr[29])) begin cov_fail++; $display("[COV] MissReadyGen.io_queryMQ_2_req_bits_vaddr[29] 未见过 0 和 1"); end
    if (!(mrg_s0_io_queryMQ_2_req_bits_vaddr[30] && mrg_s1_io_queryMQ_2_req_bits_vaddr[30])) begin cov_fail++; $display("[COV] MissReadyGen.io_queryMQ_2_req_bits_vaddr[30] 未见过 0 和 1"); end
    if (!(mrg_s0_io_queryMQ_2_req_bits_vaddr[31] && mrg_s1_io_queryMQ_2_req_bits_vaddr[31])) begin cov_fail++; $display("[COV] MissReadyGen.io_queryMQ_2_req_bits_vaddr[31] 未见过 0 和 1"); end
    if (!(mrg_s0_io_queryMQ_2_req_bits_vaddr[32] && mrg_s1_io_queryMQ_2_req_bits_vaddr[32])) begin cov_fail++; $display("[COV] MissReadyGen.io_queryMQ_2_req_bits_vaddr[32] 未见过 0 和 1"); end
    if (!(mrg_s0_io_queryMQ_2_req_bits_vaddr[33] && mrg_s1_io_queryMQ_2_req_bits_vaddr[33])) begin cov_fail++; $display("[COV] MissReadyGen.io_queryMQ_2_req_bits_vaddr[33] 未见过 0 和 1"); end
    if (!(mrg_s0_io_queryMQ_2_req_bits_vaddr[34] && mrg_s1_io_queryMQ_2_req_bits_vaddr[34])) begin cov_fail++; $display("[COV] MissReadyGen.io_queryMQ_2_req_bits_vaddr[34] 未见过 0 和 1"); end
    if (!(mrg_s0_io_queryMQ_2_req_bits_vaddr[35] && mrg_s1_io_queryMQ_2_req_bits_vaddr[35])) begin cov_fail++; $display("[COV] MissReadyGen.io_queryMQ_2_req_bits_vaddr[35] 未见过 0 和 1"); end
    if (!(mrg_s0_io_queryMQ_2_req_bits_vaddr[36] && mrg_s1_io_queryMQ_2_req_bits_vaddr[36])) begin cov_fail++; $display("[COV] MissReadyGen.io_queryMQ_2_req_bits_vaddr[36] 未见过 0 和 1"); end
    if (!(mrg_s0_io_queryMQ_2_req_bits_vaddr[37] && mrg_s1_io_queryMQ_2_req_bits_vaddr[37])) begin cov_fail++; $display("[COV] MissReadyGen.io_queryMQ_2_req_bits_vaddr[37] 未见过 0 和 1"); end
    if (!(mrg_s0_io_queryMQ_2_req_bits_vaddr[38] && mrg_s1_io_queryMQ_2_req_bits_vaddr[38])) begin cov_fail++; $display("[COV] MissReadyGen.io_queryMQ_2_req_bits_vaddr[38] 未见过 0 和 1"); end
    if (!(mrg_s0_io_queryMQ_2_req_bits_vaddr[39] && mrg_s1_io_queryMQ_2_req_bits_vaddr[39])) begin cov_fail++; $display("[COV] MissReadyGen.io_queryMQ_2_req_bits_vaddr[39] 未见过 0 和 1"); end
    if (!(mrg_s0_io_queryMQ_2_req_bits_vaddr[40] && mrg_s1_io_queryMQ_2_req_bits_vaddr[40])) begin cov_fail++; $display("[COV] MissReadyGen.io_queryMQ_2_req_bits_vaddr[40] 未见过 0 和 1"); end
    if (!(mrg_s0_io_queryMQ_2_req_bits_vaddr[41] && mrg_s1_io_queryMQ_2_req_bits_vaddr[41])) begin cov_fail++; $display("[COV] MissReadyGen.io_queryMQ_2_req_bits_vaddr[41] 未见过 0 和 1"); end
    if (!(mrg_s0_io_queryMQ_2_req_bits_vaddr[42] && mrg_s1_io_queryMQ_2_req_bits_vaddr[42])) begin cov_fail++; $display("[COV] MissReadyGen.io_queryMQ_2_req_bits_vaddr[42] 未见过 0 和 1"); end
    if (!(mrg_s0_io_queryMQ_2_req_bits_vaddr[43] && mrg_s1_io_queryMQ_2_req_bits_vaddr[43])) begin cov_fail++; $display("[COV] MissReadyGen.io_queryMQ_2_req_bits_vaddr[43] 未见过 0 和 1"); end
    if (!(mrg_s0_io_queryMQ_2_req_bits_vaddr[44] && mrg_s1_io_queryMQ_2_req_bits_vaddr[44])) begin cov_fail++; $display("[COV] MissReadyGen.io_queryMQ_2_req_bits_vaddr[44] 未见过 0 和 1"); end
    if (!(mrg_s0_io_queryMQ_2_req_bits_vaddr[45] && mrg_s1_io_queryMQ_2_req_bits_vaddr[45])) begin cov_fail++; $display("[COV] MissReadyGen.io_queryMQ_2_req_bits_vaddr[45] 未见过 0 和 1"); end
    if (!(mrg_s0_io_queryMQ_2_req_bits_vaddr[46] && mrg_s1_io_queryMQ_2_req_bits_vaddr[46])) begin cov_fail++; $display("[COV] MissReadyGen.io_queryMQ_2_req_bits_vaddr[46] 未见过 0 和 1"); end
    if (!(mrg_s0_io_queryMQ_2_req_bits_vaddr[47] && mrg_s1_io_queryMQ_2_req_bits_vaddr[47])) begin cov_fail++; $display("[COV] MissReadyGen.io_queryMQ_2_req_bits_vaddr[47] 未见过 0 和 1"); end
    if (!(mrg_s0_io_queryMQ_2_req_bits_vaddr[48] && mrg_s1_io_queryMQ_2_req_bits_vaddr[48])) begin cov_fail++; $display("[COV] MissReadyGen.io_queryMQ_2_req_bits_vaddr[48] 未见过 0 和 1"); end
    if (!(mrg_s0_io_queryMQ_2_req_bits_vaddr[49] && mrg_s1_io_queryMQ_2_req_bits_vaddr[49])) begin cov_fail++; $display("[COV] MissReadyGen.io_queryMQ_2_req_bits_vaddr[49] 未见过 0 和 1"); end
    if (!(mrg_s0_io_queryMQ_3_req_bits_source[0] && mrg_s1_io_queryMQ_3_req_bits_source[0])) begin cov_fail++; $display("[COV] MissReadyGen.io_queryMQ_3_req_bits_source[0] 未见过 0 和 1"); end
    if (!(mrg_s0_io_queryMQ_3_req_bits_source[1] && mrg_s1_io_queryMQ_3_req_bits_source[1])) begin cov_fail++; $display("[COV] MissReadyGen.io_queryMQ_3_req_bits_source[1] 未见过 0 和 1"); end
    if (!(mrg_s0_io_queryMQ_3_req_bits_source[2] && mrg_s1_io_queryMQ_3_req_bits_source[2])) begin cov_fail++; $display("[COV] MissReadyGen.io_queryMQ_3_req_bits_source[2] 未见过 0 和 1"); end
    if (!(mrg_s0_io_queryMQ_3_req_bits_source[3] && mrg_s1_io_queryMQ_3_req_bits_source[3])) begin cov_fail++; $display("[COV] MissReadyGen.io_queryMQ_3_req_bits_source[3] 未见过 0 和 1"); end
    if (!(mrg_s0_io_queryMQ_3_req_bits_addr[0] && mrg_s1_io_queryMQ_3_req_bits_addr[0])) begin cov_fail++; $display("[COV] MissReadyGen.io_queryMQ_3_req_bits_addr[0] 未见过 0 和 1"); end
    if (!(mrg_s0_io_queryMQ_3_req_bits_addr[1] && mrg_s1_io_queryMQ_3_req_bits_addr[1])) begin cov_fail++; $display("[COV] MissReadyGen.io_queryMQ_3_req_bits_addr[1] 未见过 0 和 1"); end
    if (!(mrg_s0_io_queryMQ_3_req_bits_addr[2] && mrg_s1_io_queryMQ_3_req_bits_addr[2])) begin cov_fail++; $display("[COV] MissReadyGen.io_queryMQ_3_req_bits_addr[2] 未见过 0 和 1"); end
    if (!(mrg_s0_io_queryMQ_3_req_bits_addr[3] && mrg_s1_io_queryMQ_3_req_bits_addr[3])) begin cov_fail++; $display("[COV] MissReadyGen.io_queryMQ_3_req_bits_addr[3] 未见过 0 和 1"); end
    if (!(mrg_s0_io_queryMQ_3_req_bits_addr[4] && mrg_s1_io_queryMQ_3_req_bits_addr[4])) begin cov_fail++; $display("[COV] MissReadyGen.io_queryMQ_3_req_bits_addr[4] 未见过 0 和 1"); end
    if (!(mrg_s0_io_queryMQ_3_req_bits_addr[5] && mrg_s1_io_queryMQ_3_req_bits_addr[5])) begin cov_fail++; $display("[COV] MissReadyGen.io_queryMQ_3_req_bits_addr[5] 未见过 0 和 1"); end
    if (!(mrg_s0_io_queryMQ_3_req_bits_addr[6] && mrg_s1_io_queryMQ_3_req_bits_addr[6])) begin cov_fail++; $display("[COV] MissReadyGen.io_queryMQ_3_req_bits_addr[6] 未见过 0 和 1"); end
    if (!(mrg_s0_io_queryMQ_3_req_bits_addr[7] && mrg_s1_io_queryMQ_3_req_bits_addr[7])) begin cov_fail++; $display("[COV] MissReadyGen.io_queryMQ_3_req_bits_addr[7] 未见过 0 和 1"); end
    if (!(mrg_s0_io_queryMQ_3_req_bits_addr[8] && mrg_s1_io_queryMQ_3_req_bits_addr[8])) begin cov_fail++; $display("[COV] MissReadyGen.io_queryMQ_3_req_bits_addr[8] 未见过 0 和 1"); end
    if (!(mrg_s0_io_queryMQ_3_req_bits_addr[9] && mrg_s1_io_queryMQ_3_req_bits_addr[9])) begin cov_fail++; $display("[COV] MissReadyGen.io_queryMQ_3_req_bits_addr[9] 未见过 0 和 1"); end
    if (!(mrg_s0_io_queryMQ_3_req_bits_addr[10] && mrg_s1_io_queryMQ_3_req_bits_addr[10])) begin cov_fail++; $display("[COV] MissReadyGen.io_queryMQ_3_req_bits_addr[10] 未见过 0 和 1"); end
    if (!(mrg_s0_io_queryMQ_3_req_bits_addr[11] && mrg_s1_io_queryMQ_3_req_bits_addr[11])) begin cov_fail++; $display("[COV] MissReadyGen.io_queryMQ_3_req_bits_addr[11] 未见过 0 和 1"); end
    if (!(mrg_s0_io_queryMQ_3_req_bits_addr[12] && mrg_s1_io_queryMQ_3_req_bits_addr[12])) begin cov_fail++; $display("[COV] MissReadyGen.io_queryMQ_3_req_bits_addr[12] 未见过 0 和 1"); end
    if (!(mrg_s0_io_queryMQ_3_req_bits_addr[13] && mrg_s1_io_queryMQ_3_req_bits_addr[13])) begin cov_fail++; $display("[COV] MissReadyGen.io_queryMQ_3_req_bits_addr[13] 未见过 0 和 1"); end
    if (!(mrg_s0_io_queryMQ_3_req_bits_addr[14] && mrg_s1_io_queryMQ_3_req_bits_addr[14])) begin cov_fail++; $display("[COV] MissReadyGen.io_queryMQ_3_req_bits_addr[14] 未见过 0 和 1"); end
    if (!(mrg_s0_io_queryMQ_3_req_bits_addr[15] && mrg_s1_io_queryMQ_3_req_bits_addr[15])) begin cov_fail++; $display("[COV] MissReadyGen.io_queryMQ_3_req_bits_addr[15] 未见过 0 和 1"); end
    if (!(mrg_s0_io_queryMQ_3_req_bits_addr[16] && mrg_s1_io_queryMQ_3_req_bits_addr[16])) begin cov_fail++; $display("[COV] MissReadyGen.io_queryMQ_3_req_bits_addr[16] 未见过 0 和 1"); end
    if (!(mrg_s0_io_queryMQ_3_req_bits_addr[17] && mrg_s1_io_queryMQ_3_req_bits_addr[17])) begin cov_fail++; $display("[COV] MissReadyGen.io_queryMQ_3_req_bits_addr[17] 未见过 0 和 1"); end
    if (!(mrg_s0_io_queryMQ_3_req_bits_addr[18] && mrg_s1_io_queryMQ_3_req_bits_addr[18])) begin cov_fail++; $display("[COV] MissReadyGen.io_queryMQ_3_req_bits_addr[18] 未见过 0 和 1"); end
    if (!(mrg_s0_io_queryMQ_3_req_bits_addr[19] && mrg_s1_io_queryMQ_3_req_bits_addr[19])) begin cov_fail++; $display("[COV] MissReadyGen.io_queryMQ_3_req_bits_addr[19] 未见过 0 和 1"); end
    if (!(mrg_s0_io_queryMQ_3_req_bits_addr[20] && mrg_s1_io_queryMQ_3_req_bits_addr[20])) begin cov_fail++; $display("[COV] MissReadyGen.io_queryMQ_3_req_bits_addr[20] 未见过 0 和 1"); end
    if (!(mrg_s0_io_queryMQ_3_req_bits_addr[21] && mrg_s1_io_queryMQ_3_req_bits_addr[21])) begin cov_fail++; $display("[COV] MissReadyGen.io_queryMQ_3_req_bits_addr[21] 未见过 0 和 1"); end
    if (!(mrg_s0_io_queryMQ_3_req_bits_addr[22] && mrg_s1_io_queryMQ_3_req_bits_addr[22])) begin cov_fail++; $display("[COV] MissReadyGen.io_queryMQ_3_req_bits_addr[22] 未见过 0 和 1"); end
    if (!(mrg_s0_io_queryMQ_3_req_bits_addr[23] && mrg_s1_io_queryMQ_3_req_bits_addr[23])) begin cov_fail++; $display("[COV] MissReadyGen.io_queryMQ_3_req_bits_addr[23] 未见过 0 和 1"); end
    if (!(mrg_s0_io_queryMQ_3_req_bits_addr[24] && mrg_s1_io_queryMQ_3_req_bits_addr[24])) begin cov_fail++; $display("[COV] MissReadyGen.io_queryMQ_3_req_bits_addr[24] 未见过 0 和 1"); end
    if (!(mrg_s0_io_queryMQ_3_req_bits_addr[25] && mrg_s1_io_queryMQ_3_req_bits_addr[25])) begin cov_fail++; $display("[COV] MissReadyGen.io_queryMQ_3_req_bits_addr[25] 未见过 0 和 1"); end
    if (!(mrg_s0_io_queryMQ_3_req_bits_addr[26] && mrg_s1_io_queryMQ_3_req_bits_addr[26])) begin cov_fail++; $display("[COV] MissReadyGen.io_queryMQ_3_req_bits_addr[26] 未见过 0 和 1"); end
    if (!(mrg_s0_io_queryMQ_3_req_bits_addr[27] && mrg_s1_io_queryMQ_3_req_bits_addr[27])) begin cov_fail++; $display("[COV] MissReadyGen.io_queryMQ_3_req_bits_addr[27] 未见过 0 和 1"); end
    if (!(mrg_s0_io_queryMQ_3_req_bits_addr[28] && mrg_s1_io_queryMQ_3_req_bits_addr[28])) begin cov_fail++; $display("[COV] MissReadyGen.io_queryMQ_3_req_bits_addr[28] 未见过 0 和 1"); end
    if (!(mrg_s0_io_queryMQ_3_req_bits_addr[29] && mrg_s1_io_queryMQ_3_req_bits_addr[29])) begin cov_fail++; $display("[COV] MissReadyGen.io_queryMQ_3_req_bits_addr[29] 未见过 0 和 1"); end
    if (!(mrg_s0_io_queryMQ_3_req_bits_addr[30] && mrg_s1_io_queryMQ_3_req_bits_addr[30])) begin cov_fail++; $display("[COV] MissReadyGen.io_queryMQ_3_req_bits_addr[30] 未见过 0 和 1"); end
    if (!(mrg_s0_io_queryMQ_3_req_bits_addr[31] && mrg_s1_io_queryMQ_3_req_bits_addr[31])) begin cov_fail++; $display("[COV] MissReadyGen.io_queryMQ_3_req_bits_addr[31] 未见过 0 和 1"); end
    if (!(mrg_s0_io_queryMQ_3_req_bits_addr[32] && mrg_s1_io_queryMQ_3_req_bits_addr[32])) begin cov_fail++; $display("[COV] MissReadyGen.io_queryMQ_3_req_bits_addr[32] 未见过 0 和 1"); end
    if (!(mrg_s0_io_queryMQ_3_req_bits_addr[33] && mrg_s1_io_queryMQ_3_req_bits_addr[33])) begin cov_fail++; $display("[COV] MissReadyGen.io_queryMQ_3_req_bits_addr[33] 未见过 0 和 1"); end
    if (!(mrg_s0_io_queryMQ_3_req_bits_addr[34] && mrg_s1_io_queryMQ_3_req_bits_addr[34])) begin cov_fail++; $display("[COV] MissReadyGen.io_queryMQ_3_req_bits_addr[34] 未见过 0 和 1"); end
    if (!(mrg_s0_io_queryMQ_3_req_bits_addr[35] && mrg_s1_io_queryMQ_3_req_bits_addr[35])) begin cov_fail++; $display("[COV] MissReadyGen.io_queryMQ_3_req_bits_addr[35] 未见过 0 和 1"); end
    if (!(mrg_s0_io_queryMQ_3_req_bits_addr[36] && mrg_s1_io_queryMQ_3_req_bits_addr[36])) begin cov_fail++; $display("[COV] MissReadyGen.io_queryMQ_3_req_bits_addr[36] 未见过 0 和 1"); end
    if (!(mrg_s0_io_queryMQ_3_req_bits_addr[37] && mrg_s1_io_queryMQ_3_req_bits_addr[37])) begin cov_fail++; $display("[COV] MissReadyGen.io_queryMQ_3_req_bits_addr[37] 未见过 0 和 1"); end
    if (!(mrg_s0_io_queryMQ_3_req_bits_addr[38] && mrg_s1_io_queryMQ_3_req_bits_addr[38])) begin cov_fail++; $display("[COV] MissReadyGen.io_queryMQ_3_req_bits_addr[38] 未见过 0 和 1"); end
    if (!(mrg_s0_io_queryMQ_3_req_bits_addr[39] && mrg_s1_io_queryMQ_3_req_bits_addr[39])) begin cov_fail++; $display("[COV] MissReadyGen.io_queryMQ_3_req_bits_addr[39] 未见过 0 和 1"); end
    if (!(mrg_s0_io_queryMQ_3_req_bits_addr[40] && mrg_s1_io_queryMQ_3_req_bits_addr[40])) begin cov_fail++; $display("[COV] MissReadyGen.io_queryMQ_3_req_bits_addr[40] 未见过 0 和 1"); end
    if (!(mrg_s0_io_queryMQ_3_req_bits_addr[41] && mrg_s1_io_queryMQ_3_req_bits_addr[41])) begin cov_fail++; $display("[COV] MissReadyGen.io_queryMQ_3_req_bits_addr[41] 未见过 0 和 1"); end
    if (!(mrg_s0_io_queryMQ_3_req_bits_addr[42] && mrg_s1_io_queryMQ_3_req_bits_addr[42])) begin cov_fail++; $display("[COV] MissReadyGen.io_queryMQ_3_req_bits_addr[42] 未见过 0 和 1"); end
    if (!(mrg_s0_io_queryMQ_3_req_bits_addr[43] && mrg_s1_io_queryMQ_3_req_bits_addr[43])) begin cov_fail++; $display("[COV] MissReadyGen.io_queryMQ_3_req_bits_addr[43] 未见过 0 和 1"); end
    if (!(mrg_s0_io_queryMQ_3_req_bits_addr[44] && mrg_s1_io_queryMQ_3_req_bits_addr[44])) begin cov_fail++; $display("[COV] MissReadyGen.io_queryMQ_3_req_bits_addr[44] 未见过 0 和 1"); end
    if (!(mrg_s0_io_queryMQ_3_req_bits_addr[45] && mrg_s1_io_queryMQ_3_req_bits_addr[45])) begin cov_fail++; $display("[COV] MissReadyGen.io_queryMQ_3_req_bits_addr[45] 未见过 0 和 1"); end
    if (!(mrg_s0_io_queryMQ_3_req_bits_addr[46] && mrg_s1_io_queryMQ_3_req_bits_addr[46])) begin cov_fail++; $display("[COV] MissReadyGen.io_queryMQ_3_req_bits_addr[46] 未见过 0 和 1"); end
    if (!(mrg_s0_io_queryMQ_3_req_bits_addr[47] && mrg_s1_io_queryMQ_3_req_bits_addr[47])) begin cov_fail++; $display("[COV] MissReadyGen.io_queryMQ_3_req_bits_addr[47] 未见过 0 和 1"); end
    if (!(mrg_s0_io_queryMQ_3_req_bits_vaddr[0] && mrg_s1_io_queryMQ_3_req_bits_vaddr[0])) begin cov_fail++; $display("[COV] MissReadyGen.io_queryMQ_3_req_bits_vaddr[0] 未见过 0 和 1"); end
    if (!(mrg_s0_io_queryMQ_3_req_bits_vaddr[1] && mrg_s1_io_queryMQ_3_req_bits_vaddr[1])) begin cov_fail++; $display("[COV] MissReadyGen.io_queryMQ_3_req_bits_vaddr[1] 未见过 0 和 1"); end
    if (!(mrg_s0_io_queryMQ_3_req_bits_vaddr[2] && mrg_s1_io_queryMQ_3_req_bits_vaddr[2])) begin cov_fail++; $display("[COV] MissReadyGen.io_queryMQ_3_req_bits_vaddr[2] 未见过 0 和 1"); end
    if (!(mrg_s0_io_queryMQ_3_req_bits_vaddr[3] && mrg_s1_io_queryMQ_3_req_bits_vaddr[3])) begin cov_fail++; $display("[COV] MissReadyGen.io_queryMQ_3_req_bits_vaddr[3] 未见过 0 和 1"); end
    if (!(mrg_s0_io_queryMQ_3_req_bits_vaddr[4] && mrg_s1_io_queryMQ_3_req_bits_vaddr[4])) begin cov_fail++; $display("[COV] MissReadyGen.io_queryMQ_3_req_bits_vaddr[4] 未见过 0 和 1"); end
    if (!(mrg_s0_io_queryMQ_3_req_bits_vaddr[5] && mrg_s1_io_queryMQ_3_req_bits_vaddr[5])) begin cov_fail++; $display("[COV] MissReadyGen.io_queryMQ_3_req_bits_vaddr[5] 未见过 0 和 1"); end
    if (!(mrg_s0_io_queryMQ_3_req_bits_vaddr[6] && mrg_s1_io_queryMQ_3_req_bits_vaddr[6])) begin cov_fail++; $display("[COV] MissReadyGen.io_queryMQ_3_req_bits_vaddr[6] 未见过 0 和 1"); end
    if (!(mrg_s0_io_queryMQ_3_req_bits_vaddr[7] && mrg_s1_io_queryMQ_3_req_bits_vaddr[7])) begin cov_fail++; $display("[COV] MissReadyGen.io_queryMQ_3_req_bits_vaddr[7] 未见过 0 和 1"); end
    if (!(mrg_s0_io_queryMQ_3_req_bits_vaddr[8] && mrg_s1_io_queryMQ_3_req_bits_vaddr[8])) begin cov_fail++; $display("[COV] MissReadyGen.io_queryMQ_3_req_bits_vaddr[8] 未见过 0 和 1"); end
    if (!(mrg_s0_io_queryMQ_3_req_bits_vaddr[9] && mrg_s1_io_queryMQ_3_req_bits_vaddr[9])) begin cov_fail++; $display("[COV] MissReadyGen.io_queryMQ_3_req_bits_vaddr[9] 未见过 0 和 1"); end
    if (!(mrg_s0_io_queryMQ_3_req_bits_vaddr[10] && mrg_s1_io_queryMQ_3_req_bits_vaddr[10])) begin cov_fail++; $display("[COV] MissReadyGen.io_queryMQ_3_req_bits_vaddr[10] 未见过 0 和 1"); end
    if (!(mrg_s0_io_queryMQ_3_req_bits_vaddr[11] && mrg_s1_io_queryMQ_3_req_bits_vaddr[11])) begin cov_fail++; $display("[COV] MissReadyGen.io_queryMQ_3_req_bits_vaddr[11] 未见过 0 和 1"); end
    if (!(mrg_s0_io_queryMQ_3_req_bits_vaddr[12] && mrg_s1_io_queryMQ_3_req_bits_vaddr[12])) begin cov_fail++; $display("[COV] MissReadyGen.io_queryMQ_3_req_bits_vaddr[12] 未见过 0 和 1"); end
    if (!(mrg_s0_io_queryMQ_3_req_bits_vaddr[13] && mrg_s1_io_queryMQ_3_req_bits_vaddr[13])) begin cov_fail++; $display("[COV] MissReadyGen.io_queryMQ_3_req_bits_vaddr[13] 未见过 0 和 1"); end
    if (!(mrg_s0_io_queryMQ_3_req_bits_vaddr[14] && mrg_s1_io_queryMQ_3_req_bits_vaddr[14])) begin cov_fail++; $display("[COV] MissReadyGen.io_queryMQ_3_req_bits_vaddr[14] 未见过 0 和 1"); end
    if (!(mrg_s0_io_queryMQ_3_req_bits_vaddr[15] && mrg_s1_io_queryMQ_3_req_bits_vaddr[15])) begin cov_fail++; $display("[COV] MissReadyGen.io_queryMQ_3_req_bits_vaddr[15] 未见过 0 和 1"); end
    if (!(mrg_s0_io_queryMQ_3_req_bits_vaddr[16] && mrg_s1_io_queryMQ_3_req_bits_vaddr[16])) begin cov_fail++; $display("[COV] MissReadyGen.io_queryMQ_3_req_bits_vaddr[16] 未见过 0 和 1"); end
    if (!(mrg_s0_io_queryMQ_3_req_bits_vaddr[17] && mrg_s1_io_queryMQ_3_req_bits_vaddr[17])) begin cov_fail++; $display("[COV] MissReadyGen.io_queryMQ_3_req_bits_vaddr[17] 未见过 0 和 1"); end
    if (!(mrg_s0_io_queryMQ_3_req_bits_vaddr[18] && mrg_s1_io_queryMQ_3_req_bits_vaddr[18])) begin cov_fail++; $display("[COV] MissReadyGen.io_queryMQ_3_req_bits_vaddr[18] 未见过 0 和 1"); end
    if (!(mrg_s0_io_queryMQ_3_req_bits_vaddr[19] && mrg_s1_io_queryMQ_3_req_bits_vaddr[19])) begin cov_fail++; $display("[COV] MissReadyGen.io_queryMQ_3_req_bits_vaddr[19] 未见过 0 和 1"); end
    if (!(mrg_s0_io_queryMQ_3_req_bits_vaddr[20] && mrg_s1_io_queryMQ_3_req_bits_vaddr[20])) begin cov_fail++; $display("[COV] MissReadyGen.io_queryMQ_3_req_bits_vaddr[20] 未见过 0 和 1"); end
    if (!(mrg_s0_io_queryMQ_3_req_bits_vaddr[21] && mrg_s1_io_queryMQ_3_req_bits_vaddr[21])) begin cov_fail++; $display("[COV] MissReadyGen.io_queryMQ_3_req_bits_vaddr[21] 未见过 0 和 1"); end
    if (!(mrg_s0_io_queryMQ_3_req_bits_vaddr[22] && mrg_s1_io_queryMQ_3_req_bits_vaddr[22])) begin cov_fail++; $display("[COV] MissReadyGen.io_queryMQ_3_req_bits_vaddr[22] 未见过 0 和 1"); end
    if (!(mrg_s0_io_queryMQ_3_req_bits_vaddr[23] && mrg_s1_io_queryMQ_3_req_bits_vaddr[23])) begin cov_fail++; $display("[COV] MissReadyGen.io_queryMQ_3_req_bits_vaddr[23] 未见过 0 和 1"); end
    if (!(mrg_s0_io_queryMQ_3_req_bits_vaddr[24] && mrg_s1_io_queryMQ_3_req_bits_vaddr[24])) begin cov_fail++; $display("[COV] MissReadyGen.io_queryMQ_3_req_bits_vaddr[24] 未见过 0 和 1"); end
    if (!(mrg_s0_io_queryMQ_3_req_bits_vaddr[25] && mrg_s1_io_queryMQ_3_req_bits_vaddr[25])) begin cov_fail++; $display("[COV] MissReadyGen.io_queryMQ_3_req_bits_vaddr[25] 未见过 0 和 1"); end
    if (!(mrg_s0_io_queryMQ_3_req_bits_vaddr[26] && mrg_s1_io_queryMQ_3_req_bits_vaddr[26])) begin cov_fail++; $display("[COV] MissReadyGen.io_queryMQ_3_req_bits_vaddr[26] 未见过 0 和 1"); end
    if (!(mrg_s0_io_queryMQ_3_req_bits_vaddr[27] && mrg_s1_io_queryMQ_3_req_bits_vaddr[27])) begin cov_fail++; $display("[COV] MissReadyGen.io_queryMQ_3_req_bits_vaddr[27] 未见过 0 和 1"); end
    if (!(mrg_s0_io_queryMQ_3_req_bits_vaddr[28] && mrg_s1_io_queryMQ_3_req_bits_vaddr[28])) begin cov_fail++; $display("[COV] MissReadyGen.io_queryMQ_3_req_bits_vaddr[28] 未见过 0 和 1"); end
    if (!(mrg_s0_io_queryMQ_3_req_bits_vaddr[29] && mrg_s1_io_queryMQ_3_req_bits_vaddr[29])) begin cov_fail++; $display("[COV] MissReadyGen.io_queryMQ_3_req_bits_vaddr[29] 未见过 0 和 1"); end
    if (!(mrg_s0_io_queryMQ_3_req_bits_vaddr[30] && mrg_s1_io_queryMQ_3_req_bits_vaddr[30])) begin cov_fail++; $display("[COV] MissReadyGen.io_queryMQ_3_req_bits_vaddr[30] 未见过 0 和 1"); end
    if (!(mrg_s0_io_queryMQ_3_req_bits_vaddr[31] && mrg_s1_io_queryMQ_3_req_bits_vaddr[31])) begin cov_fail++; $display("[COV] MissReadyGen.io_queryMQ_3_req_bits_vaddr[31] 未见过 0 和 1"); end
    if (!(mrg_s0_io_queryMQ_3_req_bits_vaddr[32] && mrg_s1_io_queryMQ_3_req_bits_vaddr[32])) begin cov_fail++; $display("[COV] MissReadyGen.io_queryMQ_3_req_bits_vaddr[32] 未见过 0 和 1"); end
    if (!(mrg_s0_io_queryMQ_3_req_bits_vaddr[33] && mrg_s1_io_queryMQ_3_req_bits_vaddr[33])) begin cov_fail++; $display("[COV] MissReadyGen.io_queryMQ_3_req_bits_vaddr[33] 未见过 0 和 1"); end
    if (!(mrg_s0_io_queryMQ_3_req_bits_vaddr[34] && mrg_s1_io_queryMQ_3_req_bits_vaddr[34])) begin cov_fail++; $display("[COV] MissReadyGen.io_queryMQ_3_req_bits_vaddr[34] 未见过 0 和 1"); end
    if (!(mrg_s0_io_queryMQ_3_req_bits_vaddr[35] && mrg_s1_io_queryMQ_3_req_bits_vaddr[35])) begin cov_fail++; $display("[COV] MissReadyGen.io_queryMQ_3_req_bits_vaddr[35] 未见过 0 和 1"); end
    if (!(mrg_s0_io_queryMQ_3_req_bits_vaddr[36] && mrg_s1_io_queryMQ_3_req_bits_vaddr[36])) begin cov_fail++; $display("[COV] MissReadyGen.io_queryMQ_3_req_bits_vaddr[36] 未见过 0 和 1"); end
    if (!(mrg_s0_io_queryMQ_3_req_bits_vaddr[37] && mrg_s1_io_queryMQ_3_req_bits_vaddr[37])) begin cov_fail++; $display("[COV] MissReadyGen.io_queryMQ_3_req_bits_vaddr[37] 未见过 0 和 1"); end
    if (!(mrg_s0_io_queryMQ_3_req_bits_vaddr[38] && mrg_s1_io_queryMQ_3_req_bits_vaddr[38])) begin cov_fail++; $display("[COV] MissReadyGen.io_queryMQ_3_req_bits_vaddr[38] 未见过 0 和 1"); end
    if (!(mrg_s0_io_queryMQ_3_req_bits_vaddr[39] && mrg_s1_io_queryMQ_3_req_bits_vaddr[39])) begin cov_fail++; $display("[COV] MissReadyGen.io_queryMQ_3_req_bits_vaddr[39] 未见过 0 和 1"); end
    if (!(mrg_s0_io_queryMQ_3_req_bits_vaddr[40] && mrg_s1_io_queryMQ_3_req_bits_vaddr[40])) begin cov_fail++; $display("[COV] MissReadyGen.io_queryMQ_3_req_bits_vaddr[40] 未见过 0 和 1"); end
    if (!(mrg_s0_io_queryMQ_3_req_bits_vaddr[41] && mrg_s1_io_queryMQ_3_req_bits_vaddr[41])) begin cov_fail++; $display("[COV] MissReadyGen.io_queryMQ_3_req_bits_vaddr[41] 未见过 0 和 1"); end
    if (!(mrg_s0_io_queryMQ_3_req_bits_vaddr[42] && mrg_s1_io_queryMQ_3_req_bits_vaddr[42])) begin cov_fail++; $display("[COV] MissReadyGen.io_queryMQ_3_req_bits_vaddr[42] 未见过 0 和 1"); end
    if (!(mrg_s0_io_queryMQ_3_req_bits_vaddr[43] && mrg_s1_io_queryMQ_3_req_bits_vaddr[43])) begin cov_fail++; $display("[COV] MissReadyGen.io_queryMQ_3_req_bits_vaddr[43] 未见过 0 和 1"); end
    if (!(mrg_s0_io_queryMQ_3_req_bits_vaddr[44] && mrg_s1_io_queryMQ_3_req_bits_vaddr[44])) begin cov_fail++; $display("[COV] MissReadyGen.io_queryMQ_3_req_bits_vaddr[44] 未见过 0 和 1"); end
    if (!(mrg_s0_io_queryMQ_3_req_bits_vaddr[45] && mrg_s1_io_queryMQ_3_req_bits_vaddr[45])) begin cov_fail++; $display("[COV] MissReadyGen.io_queryMQ_3_req_bits_vaddr[45] 未见过 0 和 1"); end
    if (!(mrg_s0_io_queryMQ_3_req_bits_vaddr[46] && mrg_s1_io_queryMQ_3_req_bits_vaddr[46])) begin cov_fail++; $display("[COV] MissReadyGen.io_queryMQ_3_req_bits_vaddr[46] 未见过 0 和 1"); end
    if (!(mrg_s0_io_queryMQ_3_req_bits_vaddr[47] && mrg_s1_io_queryMQ_3_req_bits_vaddr[47])) begin cov_fail++; $display("[COV] MissReadyGen.io_queryMQ_3_req_bits_vaddr[47] 未见过 0 和 1"); end
    if (!(mrg_s0_io_queryMQ_3_req_bits_vaddr[48] && mrg_s1_io_queryMQ_3_req_bits_vaddr[48])) begin cov_fail++; $display("[COV] MissReadyGen.io_queryMQ_3_req_bits_vaddr[48] 未见过 0 和 1"); end
    if (!(mrg_s0_io_queryMQ_3_req_bits_vaddr[49] && mrg_s1_io_queryMQ_3_req_bits_vaddr[49])) begin cov_fail++; $display("[COV] MissReadyGen.io_queryMQ_3_req_bits_vaddr[49] 未见过 0 和 1"); end
    $display("[ARM] MissReadyGen armed_at=%0d", mrg_armed_at);
    if (mrg_armed_at < 0) begin cov_fail++; $display("[ARM] MissReadyGen 从未 arm"); end
    $display("[COV] MissReadyGen.rdy0 = %0d", mrg_cov_rdy0);
    if (mrg_cov_rdy0 < 1000) begin cov_fail++; $display("[COV] MissReadyGen.rdy0 < 1000"); end
    $display("[COV] MissReadyGen.rdy1 = %0d", mrg_cov_rdy1);
    if (mrg_cov_rdy1 < 1000) begin cov_fail++; $display("[COV] MissReadyGen.rdy1 < 1000"); end
    $display("[COV] MissReadyGen.rdy2 = %0d", mrg_cov_rdy2);
    if (mrg_cov_rdy2 < 1000) begin cov_fail++; $display("[COV] MissReadyGen.rdy2 < 1000"); end
    $display("[COV] MissReadyGen.rdy3 = %0d", mrg_cov_rdy3);
    if (mrg_cov_rdy3 < 1000) begin cov_fail++; $display("[COV] MissReadyGen.rdy3 < 1000"); end
    $display("[COV] MissReadyGen.block1 = %0d", mrg_cov_block1);
    if (mrg_cov_block1 < 1000) begin cov_fail++; $display("[COV] MissReadyGen.block1 < 1000"); end
    $display("[COV] MissReadyGen.block2 = %0d", mrg_cov_block2);
    if (mrg_cov_block2 < 1000) begin cov_fail++; $display("[COV] MissReadyGen.block2 < 1000"); end
    $display("[COV] MissReadyGen.block3 = %0d", mrg_cov_block3);
    if (mrg_cov_block3 < 1000) begin cov_fail++; $display("[COV] MissReadyGen.block3 < 1000"); end
    if (!(pfm_s0_io_pf_ctrl_enable && pfm_s1_io_pf_ctrl_enable)) begin cov_fail++; $display("[COV] PrefetcherMonitor.io_pf_ctrl_enable 未见过 0 和 1"); end
    if (!(pfm_s0_io_pf_ctrl_confidence && pfm_s1_io_pf_ctrl_confidence)) begin cov_fail++; $display("[COV] PrefetcherMonitor.io_pf_ctrl_confidence 未见过 0 和 1"); end
    $display("[ARM] PrefetcherMonitor armed_at=%0d", pfm_armed_at);
    if (pfm_armed_at < 0) begin cov_fail++; $display("[ARM] PrefetcherMonitor 从未 arm"); end
    $display("[COV] PrefetcherMonitor.timely_reset = %0d", pfm_cov_timely_reset);
    if (pfm_cov_timely_reset < 1) begin cov_fail++; $display("[COV] PrefetcherMonitor.timely_reset < 1"); end
    $display("[COV] PrefetcherMonitor.validity_reset = %0d", pfm_cov_validity_reset);
    if (pfm_cov_validity_reset < 1) begin cov_fail++; $display("[COV] PrefetcherMonitor.validity_reset < 1"); end
    $display("[COV] PrefetcherMonitor.trigger_disable = %0d", pfm_cov_trigger_disable);
    if (pfm_cov_trigger_disable < 1) begin cov_fail++; $display("[COV] PrefetcherMonitor.trigger_disable < 1"); end
    $display("[COV] PrefetcherMonitor.trigger_late_hit_only = %0d", pfm_cov_trigger_late_hit_only);
    if (pfm_cov_trigger_late_hit_only < 1) begin cov_fail++; $display("[COV] PrefetcherMonitor.trigger_late_hit_only < 1"); end
    $display("[COV] PrefetcherMonitor.late_miss_masks_late_hit = %0d", pfm_cov_late_miss_masks_late_hit);
    if (pfm_cov_late_miss_masks_late_hit < 1) begin cov_fail++; $display("[COV] PrefetcherMonitor.late_miss_masks_late_hit < 1"); end
    $display("[COV] PrefetcherMonitor.back_off_reset = %0d", pfm_cov_back_off_reset);
    if (pfm_cov_back_off_reset < 1) begin cov_fail++; $display("[COV] PrefetcherMonitor.back_off_reset < 1"); end
    $display("[COV] PrefetcherMonitor.enable_off = %0d", pfm_cov_enable_off);
    if (pfm_cov_enable_off < 1) begin cov_fail++; $display("[COV] PrefetcherMonitor.enable_off < 1"); end
    $display("[ARM] FDPrefetcherMonitor armed_at=%0d", fdp_armed_at);
    if (fdp_armed_at < 0) begin cov_fail++; $display("[ARM] FDPrefetcherMonitor 从未 arm"); end
    $display("checks=%0d errors=%0d cov_fail=%0d", checks, errors, cov_fail);
    if (errors == 0 && cov_fail == 0 && checks > 0) $display("TEST PASSED");
    else $display("TEST FAILED");
    $finish;
  end
endmodule
