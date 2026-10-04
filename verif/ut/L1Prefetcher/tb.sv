// 自动生成：verif/ut/L1Prefetcher/gen.py（scripts/dual_tb_lib.py，读 G1 golden 端口表）—— 勿手改
// L1Prefetcher 双例化逐拍比对，全部输出逐位 !==。
`timescale 1ns/1ps
module tb;
  int unsigned NCYCLES = 200000;
  int errors = 0, checks = 0, cov_fail = 0;
  int unsigned cyc = 0;
  logic clk = 1'b0;
  always #5 clk = ~clk;
  localparam int RESET_CYC = 8;

  // ================= L1Prefetcher =================
  int unsigned l_mode = 0;
  logic [49:0] l_stream_cur [8];
  logic [49:0] l_stride_cur [8];
  logic [49:0] l_stride_pc [8];
  logic signed [9:0] l_stride_step [8];
  logic l_tlb_req_q = 1'b0;
  int unsigned l_nstream = 2;
  always @(posedge clk) l_tlb_req_q <= l_u_gold.io_tlb_req_req_valid;
  function automatic logic [49:0] l_rand_region();
    if ($urandom_range(0, 3) == 0) return {12'($urandom), 32'($urandom), 6'h0};   // 偶尔用满 50 位地址
    return {14'h0, 4'($urandom), 26'($urandom), 6'h0};
  endfunction
  initial begin
    for (int i = 0; i < 8; i++) begin
      l_stream_cur[i] = l_rand_region();
      l_stride_cur[i] = l_rand_region();
      l_stride_pc[i]  = {14'h0, 36'($urandom)} & ~50'h1;
      l_stride_step[i] = (10'($urandom_range(1, 8)) <<< 6) * (($urandom_range(0, 1) != 0) ? 1 : -1);
    end
  end
  logic l_reset;
  logic l_io_ld_in_0_valid;
  logic l_io_ld_in_0_bits_uop_robIdx_flag;
  logic [7:0] l_io_ld_in_0_bits_uop_robIdx_value;
  logic [49:0] l_io_ld_in_0_bits_vaddr;
  logic l_io_ld_in_0_bits_miss;
  logic [2:0] l_io_ld_in_0_bits_meta_prefetch;
  logic l_io_ld_in_1_valid;
  logic l_io_ld_in_1_bits_uop_robIdx_flag;
  logic [7:0] l_io_ld_in_1_bits_uop_robIdx_value;
  logic [49:0] l_io_ld_in_1_bits_vaddr;
  logic l_io_ld_in_1_bits_miss;
  logic [2:0] l_io_ld_in_1_bits_meta_prefetch;
  logic l_io_ld_in_2_valid;
  logic l_io_ld_in_2_bits_uop_robIdx_flag;
  logic [7:0] l_io_ld_in_2_bits_uop_robIdx_value;
  logic [49:0] l_io_ld_in_2_bits_vaddr;
  logic l_io_ld_in_2_bits_miss;
  logic [2:0] l_io_ld_in_2_bits_meta_prefetch;
  wire  l_g_io_tlb_req_req_valid, l_i_io_tlb_req_req_valid;
  logic l_s0_io_tlb_req_req_valid = '0, l_s1_io_tlb_req_req_valid = '0;
  wire  [49:0] l_g_io_tlb_req_req_bits_vaddr, l_i_io_tlb_req_req_bits_vaddr;
  logic [49:0] l_s0_io_tlb_req_req_bits_vaddr = '0, l_s1_io_tlb_req_req_bits_vaddr = '0;
  wire  [63:0] l_g_io_tlb_req_req_bits_fullva, l_i_io_tlb_req_req_bits_fullva;
  logic [63:0] l_s0_io_tlb_req_req_bits_fullva = '0, l_s1_io_tlb_req_req_bits_fullva = '0;
  wire  l_g_io_tlb_req_req_bits_checkfullva, l_i_io_tlb_req_req_bits_checkfullva;
  logic l_s0_io_tlb_req_req_bits_checkfullva = '0, l_s1_io_tlb_req_req_bits_checkfullva = '0;
  wire  [2:0] l_g_io_tlb_req_req_bits_cmd, l_i_io_tlb_req_req_bits_cmd;
  logic [2:0] l_s0_io_tlb_req_req_bits_cmd = '0, l_s1_io_tlb_req_req_bits_cmd = '0;
  wire  l_g_io_tlb_req_req_bits_hyperinst, l_i_io_tlb_req_req_bits_hyperinst;
  logic l_s0_io_tlb_req_req_bits_hyperinst = '0, l_s1_io_tlb_req_req_bits_hyperinst = '0;
  wire  l_g_io_tlb_req_req_bits_hlvx, l_i_io_tlb_req_req_bits_hlvx;
  logic l_s0_io_tlb_req_req_bits_hlvx = '0, l_s1_io_tlb_req_req_bits_hlvx = '0;
  wire  l_g_io_tlb_req_req_bits_kill, l_i_io_tlb_req_req_bits_kill;
  logic l_s0_io_tlb_req_req_bits_kill = '0, l_s1_io_tlb_req_req_bits_kill = '0;
  wire  l_g_io_tlb_req_req_bits_isPrefetch, l_i_io_tlb_req_req_bits_isPrefetch;
  logic l_s0_io_tlb_req_req_bits_isPrefetch = '0, l_s1_io_tlb_req_req_bits_isPrefetch = '0;
  wire  l_g_io_tlb_req_req_bits_no_translate, l_i_io_tlb_req_req_bits_no_translate;
  logic l_s0_io_tlb_req_req_bits_no_translate = '0, l_s1_io_tlb_req_req_bits_no_translate = '0;
  wire  [47:0] l_g_io_tlb_req_req_bits_pmp_addr, l_i_io_tlb_req_req_bits_pmp_addr;
  logic [47:0] l_s0_io_tlb_req_req_bits_pmp_addr = '0, l_s1_io_tlb_req_req_bits_pmp_addr = '0;
  wire  l_g_io_tlb_req_req_bits_frm_mabuf, l_i_io_tlb_req_req_bits_frm_mabuf;
  logic l_s0_io_tlb_req_req_bits_frm_mabuf = '0, l_s1_io_tlb_req_req_bits_frm_mabuf = '0;
  wire  l_g_io_tlb_req_req_bits_debug_robIdx_flag, l_i_io_tlb_req_req_bits_debug_robIdx_flag;
  logic l_s0_io_tlb_req_req_bits_debug_robIdx_flag = '0, l_s1_io_tlb_req_req_bits_debug_robIdx_flag = '0;
  wire  [7:0] l_g_io_tlb_req_req_bits_debug_robIdx_value, l_i_io_tlb_req_req_bits_debug_robIdx_value;
  logic [7:0] l_s0_io_tlb_req_req_bits_debug_robIdx_value = '0, l_s1_io_tlb_req_req_bits_debug_robIdx_value = '0;
  wire  l_g_io_tlb_req_req_bits_debug_isFirstIssue, l_i_io_tlb_req_req_bits_debug_isFirstIssue;
  logic l_s0_io_tlb_req_req_bits_debug_isFirstIssue = '0, l_s1_io_tlb_req_req_bits_debug_isFirstIssue = '0;
  logic l_io_tlb_req_resp_valid;
  logic [47:0] l_io_tlb_req_resp_bits_paddr_0;
  logic [1:0] l_io_tlb_req_resp_bits_pbmt_0;
  logic l_io_tlb_req_resp_bits_miss;
  logic l_io_tlb_req_resp_bits_excp_0_gpf_ld;
  logic l_io_tlb_req_resp_bits_excp_0_pf_ld;
  logic l_io_tlb_req_resp_bits_excp_0_af_ld;
  logic l_io_pmp_resp_ld;
  logic l_io_pmp_resp_mmio;
  logic l_io_l1_req_ready;
  wire  l_g_io_l1_req_valid, l_i_io_l1_req_valid;
  logic l_s0_io_l1_req_valid = '0, l_s1_io_l1_req_valid = '0;
  wire  [47:0] l_g_io_l1_req_bits_paddr, l_i_io_l1_req_bits_paddr;
  logic [47:0] l_s0_io_l1_req_bits_paddr = '0, l_s1_io_l1_req_bits_paddr = '0;
  wire  [1:0] l_g_io_l1_req_bits_alias, l_i_io_l1_req_bits_alias;
  logic [1:0] l_s0_io_l1_req_bits_alias = '0, l_s1_io_l1_req_bits_alias = '0;
  wire  l_g_io_l1_req_bits_confidence, l_i_io_l1_req_bits_confidence;
  logic l_s0_io_l1_req_bits_confidence = '0, l_s1_io_l1_req_bits_confidence = '0;
  wire  l_g_io_l1_req_bits_is_store, l_i_io_l1_req_bits_is_store;
  logic l_s0_io_l1_req_bits_is_store = '0, l_s1_io_l1_req_bits_is_store = '0;
  wire  [2:0] l_g_io_l1_req_bits_pf_source_value, l_i_io_l1_req_bits_pf_source_value;
  logic [2:0] l_s0_io_l1_req_bits_pf_source_value = '0, l_s1_io_l1_req_bits_pf_source_value = '0;
  wire  l_g_io_l2_req_valid, l_i_io_l2_req_valid;
  logic l_s0_io_l2_req_valid = '0, l_s1_io_l2_req_valid = '0;
  wire  [47:0] l_g_io_l2_req_bits_addr, l_i_io_l2_req_bits_addr;
  logic [47:0] l_s0_io_l2_req_bits_addr = '0, l_s1_io_l2_req_bits_addr = '0;
  wire  [4:0] l_g_io_l2_req_bits_source, l_i_io_l2_req_bits_source;
  logic [4:0] l_s0_io_l2_req_bits_source = '0, l_s1_io_l2_req_bits_source = '0;
  logic l_io_enable;
  logic l_pf_ctrl_enable;
  logic l_pf_ctrl_confidence;
  logic l_stride_train_0_valid;
  logic [49:0] l_stride_train_0_bits_uop_pc;
  logic l_stride_train_0_bits_uop_robIdx_flag;
  logic [7:0] l_stride_train_0_bits_uop_robIdx_value;
  logic [49:0] l_stride_train_0_bits_vaddr;
  logic l_stride_train_1_valid;
  logic [49:0] l_stride_train_1_bits_uop_pc;
  logic l_stride_train_1_bits_uop_robIdx_flag;
  logic [7:0] l_stride_train_1_bits_uop_robIdx_value;
  logic [49:0] l_stride_train_1_bits_vaddr;
  logic l_stride_train_2_valid;
  logic [49:0] l_stride_train_2_bits_uop_pc;
  logic l_stride_train_2_bits_uop_robIdx_flag;
  logic [7:0] l_stride_train_2_bits_uop_robIdx_value;
  logic [49:0] l_stride_train_2_bits_vaddr;
  int l_cov_l1_req = 0;
  int l_cov_l2_req = 0;
  int l_cov_tlb_req = 0;
  int l_cov_stream_l1 = 0;
  int l_cov_stride_l1 = 0;
  int l_cov_both_l1 = 0;
  int l_cov_stride_l2l3 = 0;
  int l_cov_pf_ctrl_off = 0;
  int l_cov_l2_out_of_pmem = 0;
  logic [31:0] l_armed = '0;
  int l_armed_at = -1;
  L1Prefetcher l_u_gold (
    .clock(clk),
    .reset(l_reset),
    .io_ld_in_0_valid(l_io_ld_in_0_valid),
    .io_ld_in_0_bits_uop_robIdx_flag(l_io_ld_in_0_bits_uop_robIdx_flag),
    .io_ld_in_0_bits_uop_robIdx_value(l_io_ld_in_0_bits_uop_robIdx_value),
    .io_ld_in_0_bits_vaddr(l_io_ld_in_0_bits_vaddr),
    .io_ld_in_0_bits_miss(l_io_ld_in_0_bits_miss),
    .io_ld_in_0_bits_meta_prefetch(l_io_ld_in_0_bits_meta_prefetch),
    .io_ld_in_1_valid(l_io_ld_in_1_valid),
    .io_ld_in_1_bits_uop_robIdx_flag(l_io_ld_in_1_bits_uop_robIdx_flag),
    .io_ld_in_1_bits_uop_robIdx_value(l_io_ld_in_1_bits_uop_robIdx_value),
    .io_ld_in_1_bits_vaddr(l_io_ld_in_1_bits_vaddr),
    .io_ld_in_1_bits_miss(l_io_ld_in_1_bits_miss),
    .io_ld_in_1_bits_meta_prefetch(l_io_ld_in_1_bits_meta_prefetch),
    .io_ld_in_2_valid(l_io_ld_in_2_valid),
    .io_ld_in_2_bits_uop_robIdx_flag(l_io_ld_in_2_bits_uop_robIdx_flag),
    .io_ld_in_2_bits_uop_robIdx_value(l_io_ld_in_2_bits_uop_robIdx_value),
    .io_ld_in_2_bits_vaddr(l_io_ld_in_2_bits_vaddr),
    .io_ld_in_2_bits_miss(l_io_ld_in_2_bits_miss),
    .io_ld_in_2_bits_meta_prefetch(l_io_ld_in_2_bits_meta_prefetch),
    .io_tlb_req_req_valid(l_g_io_tlb_req_req_valid),
    .io_tlb_req_req_bits_vaddr(l_g_io_tlb_req_req_bits_vaddr),
    .io_tlb_req_req_bits_fullva(l_g_io_tlb_req_req_bits_fullva),
    .io_tlb_req_req_bits_checkfullva(l_g_io_tlb_req_req_bits_checkfullva),
    .io_tlb_req_req_bits_cmd(l_g_io_tlb_req_req_bits_cmd),
    .io_tlb_req_req_bits_hyperinst(l_g_io_tlb_req_req_bits_hyperinst),
    .io_tlb_req_req_bits_hlvx(l_g_io_tlb_req_req_bits_hlvx),
    .io_tlb_req_req_bits_kill(l_g_io_tlb_req_req_bits_kill),
    .io_tlb_req_req_bits_isPrefetch(l_g_io_tlb_req_req_bits_isPrefetch),
    .io_tlb_req_req_bits_no_translate(l_g_io_tlb_req_req_bits_no_translate),
    .io_tlb_req_req_bits_pmp_addr(l_g_io_tlb_req_req_bits_pmp_addr),
    .io_tlb_req_req_bits_frm_mabuf(l_g_io_tlb_req_req_bits_frm_mabuf),
    .io_tlb_req_req_bits_debug_robIdx_flag(l_g_io_tlb_req_req_bits_debug_robIdx_flag),
    .io_tlb_req_req_bits_debug_robIdx_value(l_g_io_tlb_req_req_bits_debug_robIdx_value),
    .io_tlb_req_req_bits_debug_isFirstIssue(l_g_io_tlb_req_req_bits_debug_isFirstIssue),
    .io_tlb_req_resp_valid(l_io_tlb_req_resp_valid),
    .io_tlb_req_resp_bits_paddr_0(l_io_tlb_req_resp_bits_paddr_0),
    .io_tlb_req_resp_bits_pbmt_0(l_io_tlb_req_resp_bits_pbmt_0),
    .io_tlb_req_resp_bits_miss(l_io_tlb_req_resp_bits_miss),
    .io_tlb_req_resp_bits_excp_0_gpf_ld(l_io_tlb_req_resp_bits_excp_0_gpf_ld),
    .io_tlb_req_resp_bits_excp_0_pf_ld(l_io_tlb_req_resp_bits_excp_0_pf_ld),
    .io_tlb_req_resp_bits_excp_0_af_ld(l_io_tlb_req_resp_bits_excp_0_af_ld),
    .io_pmp_resp_ld(l_io_pmp_resp_ld),
    .io_pmp_resp_mmio(l_io_pmp_resp_mmio),
    .io_l1_req_ready(l_io_l1_req_ready),
    .io_l1_req_valid(l_g_io_l1_req_valid),
    .io_l1_req_bits_paddr(l_g_io_l1_req_bits_paddr),
    .io_l1_req_bits_alias(l_g_io_l1_req_bits_alias),
    .io_l1_req_bits_confidence(l_g_io_l1_req_bits_confidence),
    .io_l1_req_bits_is_store(l_g_io_l1_req_bits_is_store),
    .io_l1_req_bits_pf_source_value(l_g_io_l1_req_bits_pf_source_value),
    .io_l2_req_valid(l_g_io_l2_req_valid),
    .io_l2_req_bits_addr(l_g_io_l2_req_bits_addr),
    .io_l2_req_bits_source(l_g_io_l2_req_bits_source),
    .io_enable(l_io_enable),
    .pf_ctrl_enable(l_pf_ctrl_enable),
    .pf_ctrl_confidence(l_pf_ctrl_confidence),
    .stride_train_0_valid(l_stride_train_0_valid),
    .stride_train_0_bits_uop_pc(l_stride_train_0_bits_uop_pc),
    .stride_train_0_bits_uop_robIdx_flag(l_stride_train_0_bits_uop_robIdx_flag),
    .stride_train_0_bits_uop_robIdx_value(l_stride_train_0_bits_uop_robIdx_value),
    .stride_train_0_bits_vaddr(l_stride_train_0_bits_vaddr),
    .stride_train_1_valid(l_stride_train_1_valid),
    .stride_train_1_bits_uop_pc(l_stride_train_1_bits_uop_pc),
    .stride_train_1_bits_uop_robIdx_flag(l_stride_train_1_bits_uop_robIdx_flag),
    .stride_train_1_bits_uop_robIdx_value(l_stride_train_1_bits_uop_robIdx_value),
    .stride_train_1_bits_vaddr(l_stride_train_1_bits_vaddr),
    .stride_train_2_valid(l_stride_train_2_valid),
    .stride_train_2_bits_uop_pc(l_stride_train_2_bits_uop_pc),
    .stride_train_2_bits_uop_robIdx_flag(l_stride_train_2_bits_uop_robIdx_flag),
    .stride_train_2_bits_uop_robIdx_value(l_stride_train_2_bits_uop_robIdx_value),
    .stride_train_2_bits_vaddr(l_stride_train_2_bits_vaddr)
  );
  L1Prefetcher_xs l_u_impl (
    .clock(clk),
    .reset(l_reset),
    .io_ld_in_0_valid(l_io_ld_in_0_valid),
    .io_ld_in_0_bits_uop_robIdx_flag(l_io_ld_in_0_bits_uop_robIdx_flag),
    .io_ld_in_0_bits_uop_robIdx_value(l_io_ld_in_0_bits_uop_robIdx_value),
    .io_ld_in_0_bits_vaddr(l_io_ld_in_0_bits_vaddr),
    .io_ld_in_0_bits_miss(l_io_ld_in_0_bits_miss),
    .io_ld_in_0_bits_meta_prefetch(l_io_ld_in_0_bits_meta_prefetch),
    .io_ld_in_1_valid(l_io_ld_in_1_valid),
    .io_ld_in_1_bits_uop_robIdx_flag(l_io_ld_in_1_bits_uop_robIdx_flag),
    .io_ld_in_1_bits_uop_robIdx_value(l_io_ld_in_1_bits_uop_robIdx_value),
    .io_ld_in_1_bits_vaddr(l_io_ld_in_1_bits_vaddr),
    .io_ld_in_1_bits_miss(l_io_ld_in_1_bits_miss),
    .io_ld_in_1_bits_meta_prefetch(l_io_ld_in_1_bits_meta_prefetch),
    .io_ld_in_2_valid(l_io_ld_in_2_valid),
    .io_ld_in_2_bits_uop_robIdx_flag(l_io_ld_in_2_bits_uop_robIdx_flag),
    .io_ld_in_2_bits_uop_robIdx_value(l_io_ld_in_2_bits_uop_robIdx_value),
    .io_ld_in_2_bits_vaddr(l_io_ld_in_2_bits_vaddr),
    .io_ld_in_2_bits_miss(l_io_ld_in_2_bits_miss),
    .io_ld_in_2_bits_meta_prefetch(l_io_ld_in_2_bits_meta_prefetch),
    .io_tlb_req_req_valid(l_i_io_tlb_req_req_valid),
    .io_tlb_req_req_bits_vaddr(l_i_io_tlb_req_req_bits_vaddr),
    .io_tlb_req_req_bits_fullva(l_i_io_tlb_req_req_bits_fullva),
    .io_tlb_req_req_bits_checkfullva(l_i_io_tlb_req_req_bits_checkfullva),
    .io_tlb_req_req_bits_cmd(l_i_io_tlb_req_req_bits_cmd),
    .io_tlb_req_req_bits_hyperinst(l_i_io_tlb_req_req_bits_hyperinst),
    .io_tlb_req_req_bits_hlvx(l_i_io_tlb_req_req_bits_hlvx),
    .io_tlb_req_req_bits_kill(l_i_io_tlb_req_req_bits_kill),
    .io_tlb_req_req_bits_isPrefetch(l_i_io_tlb_req_req_bits_isPrefetch),
    .io_tlb_req_req_bits_no_translate(l_i_io_tlb_req_req_bits_no_translate),
    .io_tlb_req_req_bits_pmp_addr(l_i_io_tlb_req_req_bits_pmp_addr),
    .io_tlb_req_req_bits_frm_mabuf(l_i_io_tlb_req_req_bits_frm_mabuf),
    .io_tlb_req_req_bits_debug_robIdx_flag(l_i_io_tlb_req_req_bits_debug_robIdx_flag),
    .io_tlb_req_req_bits_debug_robIdx_value(l_i_io_tlb_req_req_bits_debug_robIdx_value),
    .io_tlb_req_req_bits_debug_isFirstIssue(l_i_io_tlb_req_req_bits_debug_isFirstIssue),
    .io_tlb_req_resp_valid(l_io_tlb_req_resp_valid),
    .io_tlb_req_resp_bits_paddr_0(l_io_tlb_req_resp_bits_paddr_0),
    .io_tlb_req_resp_bits_pbmt_0(l_io_tlb_req_resp_bits_pbmt_0),
    .io_tlb_req_resp_bits_miss(l_io_tlb_req_resp_bits_miss),
    .io_tlb_req_resp_bits_excp_0_gpf_ld(l_io_tlb_req_resp_bits_excp_0_gpf_ld),
    .io_tlb_req_resp_bits_excp_0_pf_ld(l_io_tlb_req_resp_bits_excp_0_pf_ld),
    .io_tlb_req_resp_bits_excp_0_af_ld(l_io_tlb_req_resp_bits_excp_0_af_ld),
    .io_pmp_resp_ld(l_io_pmp_resp_ld),
    .io_pmp_resp_mmio(l_io_pmp_resp_mmio),
    .io_l1_req_ready(l_io_l1_req_ready),
    .io_l1_req_valid(l_i_io_l1_req_valid),
    .io_l1_req_bits_paddr(l_i_io_l1_req_bits_paddr),
    .io_l1_req_bits_alias(l_i_io_l1_req_bits_alias),
    .io_l1_req_bits_confidence(l_i_io_l1_req_bits_confidence),
    .io_l1_req_bits_is_store(l_i_io_l1_req_bits_is_store),
    .io_l1_req_bits_pf_source_value(l_i_io_l1_req_bits_pf_source_value),
    .io_l2_req_valid(l_i_io_l2_req_valid),
    .io_l2_req_bits_addr(l_i_io_l2_req_bits_addr),
    .io_l2_req_bits_source(l_i_io_l2_req_bits_source),
    .io_enable(l_io_enable),
    .pf_ctrl_enable(l_pf_ctrl_enable),
    .pf_ctrl_confidence(l_pf_ctrl_confidence),
    .stride_train_0_valid(l_stride_train_0_valid),
    .stride_train_0_bits_uop_pc(l_stride_train_0_bits_uop_pc),
    .stride_train_0_bits_uop_robIdx_flag(l_stride_train_0_bits_uop_robIdx_flag),
    .stride_train_0_bits_uop_robIdx_value(l_stride_train_0_bits_uop_robIdx_value),
    .stride_train_0_bits_vaddr(l_stride_train_0_bits_vaddr),
    .stride_train_1_valid(l_stride_train_1_valid),
    .stride_train_1_bits_uop_pc(l_stride_train_1_bits_uop_pc),
    .stride_train_1_bits_uop_robIdx_flag(l_stride_train_1_bits_uop_robIdx_flag),
    .stride_train_1_bits_uop_robIdx_value(l_stride_train_1_bits_uop_robIdx_value),
    .stride_train_1_bits_vaddr(l_stride_train_1_bits_vaddr),
    .stride_train_2_valid(l_stride_train_2_valid),
    .stride_train_2_bits_uop_pc(l_stride_train_2_bits_uop_pc),
    .stride_train_2_bits_uop_robIdx_flag(l_stride_train_2_bits_uop_robIdx_flag),
    .stride_train_2_bits_uop_robIdx_value(l_stride_train_2_bits_uop_robIdx_value),
    .stride_train_2_bits_vaddr(l_stride_train_2_bits_vaddr)
  );

  initial begin
    if ($value$plusargs("ncycles=%d", NCYCLES)) ;
    for (cyc = 0; cyc < NCYCLES; cyc++) begin
      @(negedge clk);
      if (cyc % 4000 == 0) l_mode = $urandom_range(0, 15);
      l_io_ld_in_0_valid = 1'($urandom);
      l_io_ld_in_0_bits_uop_robIdx_flag = 1'($urandom);
      l_io_ld_in_0_bits_uop_robIdx_value = 8'($urandom);
      l_io_ld_in_0_bits_vaddr = 50'({$urandom, $urandom});
      l_io_ld_in_0_bits_miss = 1'($urandom);
      l_io_ld_in_0_bits_meta_prefetch = 3'($urandom);
      l_io_ld_in_1_valid = 1'($urandom);
      l_io_ld_in_1_bits_uop_robIdx_flag = 1'($urandom);
      l_io_ld_in_1_bits_uop_robIdx_value = 8'($urandom);
      l_io_ld_in_1_bits_vaddr = 50'({$urandom, $urandom});
      l_io_ld_in_1_bits_miss = 1'($urandom);
      l_io_ld_in_1_bits_meta_prefetch = 3'($urandom);
      l_io_ld_in_2_valid = 1'($urandom);
      l_io_ld_in_2_bits_uop_robIdx_flag = 1'($urandom);
      l_io_ld_in_2_bits_uop_robIdx_value = 8'($urandom);
      l_io_ld_in_2_bits_vaddr = 50'({$urandom, $urandom});
      l_io_ld_in_2_bits_miss = 1'($urandom);
      l_io_ld_in_2_bits_meta_prefetch = 3'($urandom);
      l_io_tlb_req_resp_valid = 1'($urandom);
      l_io_tlb_req_resp_bits_paddr_0 = 48'({$urandom, $urandom});
      l_io_tlb_req_resp_bits_pbmt_0 = 2'($urandom);
      l_io_tlb_req_resp_bits_miss = 1'($urandom);
      l_io_tlb_req_resp_bits_excp_0_gpf_ld = 1'($urandom);
      l_io_tlb_req_resp_bits_excp_0_pf_ld = 1'($urandom);
      l_io_tlb_req_resp_bits_excp_0_af_ld = 1'($urandom);
      l_io_pmp_resp_ld = 1'($urandom);
      l_io_pmp_resp_mmio = 1'($urandom);
      l_io_l1_req_ready = 1'($urandom);
      l_io_enable = 1'($urandom);
      l_pf_ctrl_enable = 1'($urandom);
      l_pf_ctrl_confidence = 1'($urandom);
      l_stride_train_0_valid = 1'($urandom);
      l_stride_train_0_bits_uop_pc = 50'({$urandom, $urandom});
      l_stride_train_0_bits_uop_robIdx_flag = 1'($urandom);
      l_stride_train_0_bits_uop_robIdx_value = 8'($urandom);
      l_stride_train_0_bits_vaddr = 50'({$urandom, $urandom});
      l_stride_train_1_valid = 1'($urandom);
      l_stride_train_1_bits_uop_pc = 50'({$urandom, $urandom});
      l_stride_train_1_bits_uop_robIdx_flag = 1'($urandom);
      l_stride_train_1_bits_uop_robIdx_value = 8'($urandom);
      l_stride_train_1_bits_vaddr = 50'({$urandom, $urandom});
      l_stride_train_2_valid = 1'($urandom);
      l_stride_train_2_bits_uop_pc = 50'({$urandom, $urandom});
      l_stride_train_2_bits_uop_robIdx_flag = 1'($urandom);
      l_stride_train_2_bits_uop_robIdx_value = 8'($urandom);
      l_stride_train_2_bits_vaddr = 50'({$urandom, $urandom});
      l_reset = (cyc < RESET_CYC) || ($urandom_range(0, 39999) == 0);
      begin : stim_l
        if (cyc % 4000 == 0) l_nstream = $urandom_range(1, 8);
        if (cyc % 40 == 0) for (int i = 0; i < 8; i++) l_stream_cur[i] += 50'd1024;   // 流向下一个 1KB 区域
        if (cyc % 3000 == 0)
          for (int i = 0; i < 8; i++) begin l_stream_cur[i] = l_rand_region(); l_stride_cur[i] = l_rand_region(); end
        l_io_enable = ($urandom_range(0, 15) != 0);
        l_pf_ctrl_enable = ($urandom_range(0, 15) != 0);
        l_io_l1_req_ready = ($urandom_range(0, 3) != 0);
        begin
          int k;
          k = $urandom_range(0, l_nstream - 1); l_io_ld_in_0_bits_vaddr = l_stream_cur[k] + 50'($urandom_range(0, 15) * 64);
          k = $urandom_range(0, l_nstream - 1); l_io_ld_in_1_bits_vaddr = l_stream_cur[k] + 50'($urandom_range(0, 15) * 64);
          k = $urandom_range(0, l_nstream - 1); l_io_ld_in_2_bits_vaddr = l_stream_cur[k] + 50'($urandom_range(0, 15) * 64);
          l_io_ld_in_0_valid = ($urandom_range(0, 3) == 0);
          l_io_ld_in_1_valid = ($urandom_range(0, 3) == 0);
          l_io_ld_in_2_valid = ($urandom_range(0, 3) == 0);
          l_io_ld_in_0_bits_miss = ($urandom_range(0, 3) != 0);
          l_io_ld_in_1_bits_miss = ($urandom_range(0, 3) != 0);
          l_io_ld_in_2_bits_miss = ($urandom_range(0, 3) != 0);
          k = $urandom_range(0, 7); l_stride_train_0_bits_uop_pc = l_stride_pc[k]; l_stride_train_0_bits_vaddr = l_stride_cur[k]; l_stride_cur[k] += 50'($signed(l_stride_step[k]));
          k = $urandom_range(0, 7); l_stride_train_1_bits_uop_pc = l_stride_pc[k]; l_stride_train_1_bits_vaddr = l_stride_cur[k]; l_stride_cur[k] += 50'($signed(l_stride_step[k]));
          k = $urandom_range(0, 7); l_stride_train_2_bits_uop_pc = l_stride_pc[k]; l_stride_train_2_bits_vaddr = l_stride_cur[k]; l_stride_cur[k] += 50'($signed(l_stride_step[k]));
        end
        l_io_tlb_req_resp_valid = l_tlb_req_q ? ($urandom_range(0, 99) < 95) : ($urandom_range(0, 99) < 2);
        if ($urandom_range(0, 99) < 85) begin
          l_io_tlb_req_resp_bits_paddr_0 = {5'h0, 11'($urandom), 32'($urandom)};
          if (l_io_tlb_req_resp_bits_paddr_0 < 48'h8000_0000) l_io_tlb_req_resp_bits_paddr_0[31] = 1'b1;
        end
        l_io_tlb_req_resp_bits_miss = ($urandom_range(0, 99) < 15);
        l_io_tlb_req_resp_bits_excp_0_gpf_ld = ($urandom_range(0, 99) < 3);
        l_io_tlb_req_resp_bits_excp_0_pf_ld = ($urandom_range(0, 99) < 3);
        l_io_tlb_req_resp_bits_excp_0_af_ld = ($urandom_range(0, 99) < 3);
        l_io_pmp_resp_ld = ($urandom_range(0, 99) < 3);
        l_io_pmp_resp_mmio = ($urandom_range(0, 99) < 3);
      end
      #4;
      if (cyc >= RESET_CYC + 0 && l_armed_at >= 0 && cyc >= l_armed_at) begin
        checks++;
        if (l_g_io_tlb_req_req_valid !== l_i_io_tlb_req_req_valid) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d L1Prefetcher.io_tlb_req_req_valid g=%h i=%h", cyc, l_g_io_tlb_req_req_valid, l_i_io_tlb_req_req_valid);
        end
        l_s1_io_tlb_req_req_valid |= l_g_io_tlb_req_req_valid;
        l_s0_io_tlb_req_req_valid |= ~l_g_io_tlb_req_req_valid;
        checks++;
        if (l_g_io_tlb_req_req_bits_vaddr !== l_i_io_tlb_req_req_bits_vaddr) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d L1Prefetcher.io_tlb_req_req_bits_vaddr g=%h i=%h", cyc, l_g_io_tlb_req_req_bits_vaddr, l_i_io_tlb_req_req_bits_vaddr);
        end
        l_s1_io_tlb_req_req_bits_vaddr |= l_g_io_tlb_req_req_bits_vaddr;
        l_s0_io_tlb_req_req_bits_vaddr |= ~l_g_io_tlb_req_req_bits_vaddr;
        checks++;
        if (l_g_io_tlb_req_req_bits_fullva !== l_i_io_tlb_req_req_bits_fullva) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d L1Prefetcher.io_tlb_req_req_bits_fullva g=%h i=%h", cyc, l_g_io_tlb_req_req_bits_fullva, l_i_io_tlb_req_req_bits_fullva);
        end
        l_s1_io_tlb_req_req_bits_fullva |= l_g_io_tlb_req_req_bits_fullva;
        l_s0_io_tlb_req_req_bits_fullva |= ~l_g_io_tlb_req_req_bits_fullva;
        checks++;
        if (l_g_io_tlb_req_req_bits_checkfullva !== l_i_io_tlb_req_req_bits_checkfullva) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d L1Prefetcher.io_tlb_req_req_bits_checkfullva g=%h i=%h", cyc, l_g_io_tlb_req_req_bits_checkfullva, l_i_io_tlb_req_req_bits_checkfullva);
        end
        l_s1_io_tlb_req_req_bits_checkfullva |= l_g_io_tlb_req_req_bits_checkfullva;
        l_s0_io_tlb_req_req_bits_checkfullva |= ~l_g_io_tlb_req_req_bits_checkfullva;
        checks++;
        if (l_g_io_tlb_req_req_bits_cmd !== l_i_io_tlb_req_req_bits_cmd) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d L1Prefetcher.io_tlb_req_req_bits_cmd g=%h i=%h", cyc, l_g_io_tlb_req_req_bits_cmd, l_i_io_tlb_req_req_bits_cmd);
        end
        l_s1_io_tlb_req_req_bits_cmd |= l_g_io_tlb_req_req_bits_cmd;
        l_s0_io_tlb_req_req_bits_cmd |= ~l_g_io_tlb_req_req_bits_cmd;
        checks++;
        if (l_g_io_tlb_req_req_bits_hyperinst !== l_i_io_tlb_req_req_bits_hyperinst) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d L1Prefetcher.io_tlb_req_req_bits_hyperinst g=%h i=%h", cyc, l_g_io_tlb_req_req_bits_hyperinst, l_i_io_tlb_req_req_bits_hyperinst);
        end
        l_s1_io_tlb_req_req_bits_hyperinst |= l_g_io_tlb_req_req_bits_hyperinst;
        l_s0_io_tlb_req_req_bits_hyperinst |= ~l_g_io_tlb_req_req_bits_hyperinst;
        checks++;
        if (l_g_io_tlb_req_req_bits_hlvx !== l_i_io_tlb_req_req_bits_hlvx) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d L1Prefetcher.io_tlb_req_req_bits_hlvx g=%h i=%h", cyc, l_g_io_tlb_req_req_bits_hlvx, l_i_io_tlb_req_req_bits_hlvx);
        end
        l_s1_io_tlb_req_req_bits_hlvx |= l_g_io_tlb_req_req_bits_hlvx;
        l_s0_io_tlb_req_req_bits_hlvx |= ~l_g_io_tlb_req_req_bits_hlvx;
        checks++;
        if (l_g_io_tlb_req_req_bits_kill !== l_i_io_tlb_req_req_bits_kill) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d L1Prefetcher.io_tlb_req_req_bits_kill g=%h i=%h", cyc, l_g_io_tlb_req_req_bits_kill, l_i_io_tlb_req_req_bits_kill);
        end
        l_s1_io_tlb_req_req_bits_kill |= l_g_io_tlb_req_req_bits_kill;
        l_s0_io_tlb_req_req_bits_kill |= ~l_g_io_tlb_req_req_bits_kill;
        checks++;
        if (l_g_io_tlb_req_req_bits_isPrefetch !== l_i_io_tlb_req_req_bits_isPrefetch) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d L1Prefetcher.io_tlb_req_req_bits_isPrefetch g=%h i=%h", cyc, l_g_io_tlb_req_req_bits_isPrefetch, l_i_io_tlb_req_req_bits_isPrefetch);
        end
        l_s1_io_tlb_req_req_bits_isPrefetch |= l_g_io_tlb_req_req_bits_isPrefetch;
        l_s0_io_tlb_req_req_bits_isPrefetch |= ~l_g_io_tlb_req_req_bits_isPrefetch;
        checks++;
        if (l_g_io_tlb_req_req_bits_no_translate !== l_i_io_tlb_req_req_bits_no_translate) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d L1Prefetcher.io_tlb_req_req_bits_no_translate g=%h i=%h", cyc, l_g_io_tlb_req_req_bits_no_translate, l_i_io_tlb_req_req_bits_no_translate);
        end
        l_s1_io_tlb_req_req_bits_no_translate |= l_g_io_tlb_req_req_bits_no_translate;
        l_s0_io_tlb_req_req_bits_no_translate |= ~l_g_io_tlb_req_req_bits_no_translate;
        checks++;
        if (l_g_io_tlb_req_req_bits_pmp_addr !== l_i_io_tlb_req_req_bits_pmp_addr) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d L1Prefetcher.io_tlb_req_req_bits_pmp_addr g=%h i=%h", cyc, l_g_io_tlb_req_req_bits_pmp_addr, l_i_io_tlb_req_req_bits_pmp_addr);
        end
        l_s1_io_tlb_req_req_bits_pmp_addr |= l_g_io_tlb_req_req_bits_pmp_addr;
        l_s0_io_tlb_req_req_bits_pmp_addr |= ~l_g_io_tlb_req_req_bits_pmp_addr;
        checks++;
        if (l_g_io_tlb_req_req_bits_frm_mabuf !== l_i_io_tlb_req_req_bits_frm_mabuf) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d L1Prefetcher.io_tlb_req_req_bits_frm_mabuf g=%h i=%h", cyc, l_g_io_tlb_req_req_bits_frm_mabuf, l_i_io_tlb_req_req_bits_frm_mabuf);
        end
        l_s1_io_tlb_req_req_bits_frm_mabuf |= l_g_io_tlb_req_req_bits_frm_mabuf;
        l_s0_io_tlb_req_req_bits_frm_mabuf |= ~l_g_io_tlb_req_req_bits_frm_mabuf;
        checks++;
        if (l_g_io_tlb_req_req_bits_debug_robIdx_flag !== l_i_io_tlb_req_req_bits_debug_robIdx_flag) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d L1Prefetcher.io_tlb_req_req_bits_debug_robIdx_flag g=%h i=%h", cyc, l_g_io_tlb_req_req_bits_debug_robIdx_flag, l_i_io_tlb_req_req_bits_debug_robIdx_flag);
        end
        l_s1_io_tlb_req_req_bits_debug_robIdx_flag |= l_g_io_tlb_req_req_bits_debug_robIdx_flag;
        l_s0_io_tlb_req_req_bits_debug_robIdx_flag |= ~l_g_io_tlb_req_req_bits_debug_robIdx_flag;
        checks++;
        if (l_g_io_tlb_req_req_bits_debug_robIdx_value !== l_i_io_tlb_req_req_bits_debug_robIdx_value) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d L1Prefetcher.io_tlb_req_req_bits_debug_robIdx_value g=%h i=%h", cyc, l_g_io_tlb_req_req_bits_debug_robIdx_value, l_i_io_tlb_req_req_bits_debug_robIdx_value);
        end
        l_s1_io_tlb_req_req_bits_debug_robIdx_value |= l_g_io_tlb_req_req_bits_debug_robIdx_value;
        l_s0_io_tlb_req_req_bits_debug_robIdx_value |= ~l_g_io_tlb_req_req_bits_debug_robIdx_value;
        checks++;
        if (l_g_io_tlb_req_req_bits_debug_isFirstIssue !== l_i_io_tlb_req_req_bits_debug_isFirstIssue) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d L1Prefetcher.io_tlb_req_req_bits_debug_isFirstIssue g=%h i=%h", cyc, l_g_io_tlb_req_req_bits_debug_isFirstIssue, l_i_io_tlb_req_req_bits_debug_isFirstIssue);
        end
        l_s1_io_tlb_req_req_bits_debug_isFirstIssue |= l_g_io_tlb_req_req_bits_debug_isFirstIssue;
        l_s0_io_tlb_req_req_bits_debug_isFirstIssue |= ~l_g_io_tlb_req_req_bits_debug_isFirstIssue;
        checks++;
        if (l_g_io_l1_req_valid !== l_i_io_l1_req_valid) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d L1Prefetcher.io_l1_req_valid g=%h i=%h", cyc, l_g_io_l1_req_valid, l_i_io_l1_req_valid);
        end
        l_s1_io_l1_req_valid |= l_g_io_l1_req_valid;
        l_s0_io_l1_req_valid |= ~l_g_io_l1_req_valid;
        checks++;
        if (l_g_io_l1_req_bits_paddr !== l_i_io_l1_req_bits_paddr) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d L1Prefetcher.io_l1_req_bits_paddr g=%h i=%h", cyc, l_g_io_l1_req_bits_paddr, l_i_io_l1_req_bits_paddr);
        end
        l_s1_io_l1_req_bits_paddr |= l_g_io_l1_req_bits_paddr;
        l_s0_io_l1_req_bits_paddr |= ~l_g_io_l1_req_bits_paddr;
        checks++;
        if (l_g_io_l1_req_bits_alias !== l_i_io_l1_req_bits_alias) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d L1Prefetcher.io_l1_req_bits_alias g=%h i=%h", cyc, l_g_io_l1_req_bits_alias, l_i_io_l1_req_bits_alias);
        end
        l_s1_io_l1_req_bits_alias |= l_g_io_l1_req_bits_alias;
        l_s0_io_l1_req_bits_alias |= ~l_g_io_l1_req_bits_alias;
        checks++;
        if (l_g_io_l1_req_bits_confidence !== l_i_io_l1_req_bits_confidence) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d L1Prefetcher.io_l1_req_bits_confidence g=%h i=%h", cyc, l_g_io_l1_req_bits_confidence, l_i_io_l1_req_bits_confidence);
        end
        l_s1_io_l1_req_bits_confidence |= l_g_io_l1_req_bits_confidence;
        l_s0_io_l1_req_bits_confidence |= ~l_g_io_l1_req_bits_confidence;
        checks++;
        if (l_g_io_l1_req_bits_is_store !== l_i_io_l1_req_bits_is_store) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d L1Prefetcher.io_l1_req_bits_is_store g=%h i=%h", cyc, l_g_io_l1_req_bits_is_store, l_i_io_l1_req_bits_is_store);
        end
        l_s1_io_l1_req_bits_is_store |= l_g_io_l1_req_bits_is_store;
        l_s0_io_l1_req_bits_is_store |= ~l_g_io_l1_req_bits_is_store;
        checks++;
        if (l_g_io_l1_req_bits_pf_source_value !== l_i_io_l1_req_bits_pf_source_value) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d L1Prefetcher.io_l1_req_bits_pf_source_value g=%h i=%h", cyc, l_g_io_l1_req_bits_pf_source_value, l_i_io_l1_req_bits_pf_source_value);
        end
        l_s1_io_l1_req_bits_pf_source_value |= l_g_io_l1_req_bits_pf_source_value;
        l_s0_io_l1_req_bits_pf_source_value |= ~l_g_io_l1_req_bits_pf_source_value;
        checks++;
        if (l_g_io_l2_req_valid !== l_i_io_l2_req_valid) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d L1Prefetcher.io_l2_req_valid g=%h i=%h", cyc, l_g_io_l2_req_valid, l_i_io_l2_req_valid);
        end
        l_s1_io_l2_req_valid |= l_g_io_l2_req_valid;
        l_s0_io_l2_req_valid |= ~l_g_io_l2_req_valid;
        checks++;
        if (l_g_io_l2_req_bits_addr !== l_i_io_l2_req_bits_addr) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d L1Prefetcher.io_l2_req_bits_addr g=%h i=%h", cyc, l_g_io_l2_req_bits_addr, l_i_io_l2_req_bits_addr);
        end
        l_s1_io_l2_req_bits_addr |= l_g_io_l2_req_bits_addr;
        l_s0_io_l2_req_bits_addr |= ~l_g_io_l2_req_bits_addr;
        checks++;
        if (l_g_io_l2_req_bits_source !== l_i_io_l2_req_bits_source) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d L1Prefetcher.io_l2_req_bits_source g=%h i=%h", cyc, l_g_io_l2_req_bits_source, l_i_io_l2_req_bits_source);
        end
        l_s1_io_l2_req_bits_source |= l_g_io_l2_req_bits_source;
        l_s0_io_l2_req_bits_source |= ~l_g_io_l2_req_bits_source;
        if (l_g_io_l1_req_valid && l_io_l1_req_ready) l_cov_l1_req++;
        if (l_g_io_l2_req_valid) l_cov_l2_req++;
        if (l_g_io_tlb_req_req_valid) l_cov_tlb_req++;
        if (l_u_gold.stream_bit_vec_array.io_l1_prefetch_req_valid) l_cov_stream_l1++;
        if (l_u_gold.stride_meta_array.io_l1_prefetch_req_valid) l_cov_stride_l1++;
        if (l_u_gold.stream_bit_vec_array.io_l1_prefetch_req_valid && l_u_gold.stride_meta_array.io_l1_prefetch_req_valid) l_cov_both_l1++;
        if (l_u_gold.stride_meta_array.io_l2_l3_prefetch_req_valid && !l_u_gold.stream_bit_vec_array.io_l2_l3_prefetch_req_valid) l_cov_stride_l2l3++;
        if (!l_pf_ctrl_enable && l_u_gold.pf_queue_filter.io_l1_req_valid) l_cov_pf_ctrl_off++;
        if (l_u_gold.pf_queue_filter.io_l2_pf_addr_valid && !l_g_io_l2_req_valid && l_io_enable && l_pf_ctrl_enable) l_cov_l2_out_of_pmem++;
      end
      if (l_u_gold.pf_queue_filter.l1_valids_0) l_armed[0] = 1'b1;
      if (l_u_gold.pf_queue_filter.l1_valids_1) l_armed[1] = 1'b1;
      if (l_u_gold.pf_queue_filter.l1_valids_2) l_armed[2] = 1'b1;
      if (l_u_gold.pf_queue_filter.l1_valids_3) l_armed[3] = 1'b1;
      if (l_u_gold.pf_queue_filter.l1_valids_4) l_armed[4] = 1'b1;
      if (l_u_gold.pf_queue_filter.l1_valids_5) l_armed[5] = 1'b1;
      if (l_u_gold.pf_queue_filter.l1_valids_6) l_armed[6] = 1'b1;
      if (l_u_gold.pf_queue_filter.l1_valids_7) l_armed[7] = 1'b1;
      if (l_u_gold.pf_queue_filter.l1_valids_8) l_armed[8] = 1'b1;
      if (l_u_gold.pf_queue_filter.l1_valids_9) l_armed[9] = 1'b1;
      if (l_u_gold.pf_queue_filter.l1_valids_10) l_armed[10] = 1'b1;
      if (l_u_gold.pf_queue_filter.l1_valids_11) l_armed[11] = 1'b1;
      if (l_u_gold.pf_queue_filter.l1_valids_12) l_armed[12] = 1'b1;
      if (l_u_gold.pf_queue_filter.l1_valids_13) l_armed[13] = 1'b1;
      if (l_u_gold.pf_queue_filter.l1_valids_14) l_armed[14] = 1'b1;
      if (l_u_gold.pf_queue_filter.l1_valids_15) l_armed[15] = 1'b1;
      if (l_u_gold.pf_queue_filter.l2_valids_0) l_armed[16] = 1'b1;
      if (l_u_gold.pf_queue_filter.l2_valids_1) l_armed[17] = 1'b1;
      if (l_u_gold.pf_queue_filter.l2_valids_2) l_armed[18] = 1'b1;
      if (l_u_gold.pf_queue_filter.l2_valids_3) l_armed[19] = 1'b1;
      if (l_u_gold.pf_queue_filter.l2_valids_4) l_armed[20] = 1'b1;
      if (l_u_gold.pf_queue_filter.l2_valids_5) l_armed[21] = 1'b1;
      if (l_u_gold.pf_queue_filter.l2_valids_6) l_armed[22] = 1'b1;
      if (l_u_gold.pf_queue_filter.l2_valids_7) l_armed[23] = 1'b1;
      if (l_u_gold.pf_queue_filter.l2_valids_8) l_armed[24] = 1'b1;
      if (l_u_gold.pf_queue_filter.l2_valids_9) l_armed[25] = 1'b1;
      if (l_u_gold.pf_queue_filter.l2_valids_10) l_armed[26] = 1'b1;
      if (l_u_gold.pf_queue_filter.l2_valids_11) l_armed[27] = 1'b1;
      if (l_u_gold.pf_queue_filter.l2_valids_12) l_armed[28] = 1'b1;
      if (l_u_gold.pf_queue_filter.l2_valids_13) l_armed[29] = 1'b1;
      if (l_u_gold.pf_queue_filter.l2_valids_14) l_armed[30] = 1'b1;
      if (l_u_gold.pf_queue_filter.l2_valids_15) l_armed[31] = 1'b1;
      if (l_armed_at < 0 && (&l_armed)) l_armed_at = cyc + 1 + 4;
    end

    // ---- 覆盖闸 ----
    if (!(l_s0_io_tlb_req_req_valid && l_s1_io_tlb_req_req_valid)) begin cov_fail++; $display("[COV] L1Prefetcher.io_tlb_req_req_valid 未见过 0 和 1"); end
    if (!(l_s0_io_tlb_req_req_bits_vaddr[10] && l_s1_io_tlb_req_req_bits_vaddr[10])) begin cov_fail++; $display("[COV] L1Prefetcher.io_tlb_req_req_bits_vaddr[10] 未见过 0 和 1"); end
    if (!(l_s0_io_tlb_req_req_bits_vaddr[11] && l_s1_io_tlb_req_req_bits_vaddr[11])) begin cov_fail++; $display("[COV] L1Prefetcher.io_tlb_req_req_bits_vaddr[11] 未见过 0 和 1"); end
    if (!(l_s0_io_tlb_req_req_bits_vaddr[12] && l_s1_io_tlb_req_req_bits_vaddr[12])) begin cov_fail++; $display("[COV] L1Prefetcher.io_tlb_req_req_bits_vaddr[12] 未见过 0 和 1"); end
    if (!(l_s0_io_tlb_req_req_bits_vaddr[13] && l_s1_io_tlb_req_req_bits_vaddr[13])) begin cov_fail++; $display("[COV] L1Prefetcher.io_tlb_req_req_bits_vaddr[13] 未见过 0 和 1"); end
    if (!(l_s0_io_tlb_req_req_bits_vaddr[14] && l_s1_io_tlb_req_req_bits_vaddr[14])) begin cov_fail++; $display("[COV] L1Prefetcher.io_tlb_req_req_bits_vaddr[14] 未见过 0 和 1"); end
    if (!(l_s0_io_tlb_req_req_bits_vaddr[15] && l_s1_io_tlb_req_req_bits_vaddr[15])) begin cov_fail++; $display("[COV] L1Prefetcher.io_tlb_req_req_bits_vaddr[15] 未见过 0 和 1"); end
    if (!(l_s0_io_tlb_req_req_bits_vaddr[16] && l_s1_io_tlb_req_req_bits_vaddr[16])) begin cov_fail++; $display("[COV] L1Prefetcher.io_tlb_req_req_bits_vaddr[16] 未见过 0 和 1"); end
    if (!(l_s0_io_tlb_req_req_bits_vaddr[17] && l_s1_io_tlb_req_req_bits_vaddr[17])) begin cov_fail++; $display("[COV] L1Prefetcher.io_tlb_req_req_bits_vaddr[17] 未见过 0 和 1"); end
    if (!(l_s0_io_tlb_req_req_bits_vaddr[18] && l_s1_io_tlb_req_req_bits_vaddr[18])) begin cov_fail++; $display("[COV] L1Prefetcher.io_tlb_req_req_bits_vaddr[18] 未见过 0 和 1"); end
    if (!(l_s0_io_tlb_req_req_bits_vaddr[19] && l_s1_io_tlb_req_req_bits_vaddr[19])) begin cov_fail++; $display("[COV] L1Prefetcher.io_tlb_req_req_bits_vaddr[19] 未见过 0 和 1"); end
    if (!(l_s0_io_tlb_req_req_bits_vaddr[20] && l_s1_io_tlb_req_req_bits_vaddr[20])) begin cov_fail++; $display("[COV] L1Prefetcher.io_tlb_req_req_bits_vaddr[20] 未见过 0 和 1"); end
    if (!(l_s0_io_tlb_req_req_bits_vaddr[21] && l_s1_io_tlb_req_req_bits_vaddr[21])) begin cov_fail++; $display("[COV] L1Prefetcher.io_tlb_req_req_bits_vaddr[21] 未见过 0 和 1"); end
    if (!(l_s0_io_tlb_req_req_bits_vaddr[22] && l_s1_io_tlb_req_req_bits_vaddr[22])) begin cov_fail++; $display("[COV] L1Prefetcher.io_tlb_req_req_bits_vaddr[22] 未见过 0 和 1"); end
    if (!(l_s0_io_tlb_req_req_bits_vaddr[23] && l_s1_io_tlb_req_req_bits_vaddr[23])) begin cov_fail++; $display("[COV] L1Prefetcher.io_tlb_req_req_bits_vaddr[23] 未见过 0 和 1"); end
    if (!(l_s0_io_tlb_req_req_bits_vaddr[24] && l_s1_io_tlb_req_req_bits_vaddr[24])) begin cov_fail++; $display("[COV] L1Prefetcher.io_tlb_req_req_bits_vaddr[24] 未见过 0 和 1"); end
    if (!(l_s0_io_tlb_req_req_bits_vaddr[25] && l_s1_io_tlb_req_req_bits_vaddr[25])) begin cov_fail++; $display("[COV] L1Prefetcher.io_tlb_req_req_bits_vaddr[25] 未见过 0 和 1"); end
    if (!(l_s0_io_tlb_req_req_bits_vaddr[26] && l_s1_io_tlb_req_req_bits_vaddr[26])) begin cov_fail++; $display("[COV] L1Prefetcher.io_tlb_req_req_bits_vaddr[26] 未见过 0 和 1"); end
    if (!(l_s0_io_tlb_req_req_bits_vaddr[27] && l_s1_io_tlb_req_req_bits_vaddr[27])) begin cov_fail++; $display("[COV] L1Prefetcher.io_tlb_req_req_bits_vaddr[27] 未见过 0 和 1"); end
    if (!(l_s0_io_tlb_req_req_bits_vaddr[28] && l_s1_io_tlb_req_req_bits_vaddr[28])) begin cov_fail++; $display("[COV] L1Prefetcher.io_tlb_req_req_bits_vaddr[28] 未见过 0 和 1"); end
    if (!(l_s0_io_tlb_req_req_bits_vaddr[29] && l_s1_io_tlb_req_req_bits_vaddr[29])) begin cov_fail++; $display("[COV] L1Prefetcher.io_tlb_req_req_bits_vaddr[29] 未见过 0 和 1"); end
    if (!(l_s0_io_tlb_req_req_bits_vaddr[30] && l_s1_io_tlb_req_req_bits_vaddr[30])) begin cov_fail++; $display("[COV] L1Prefetcher.io_tlb_req_req_bits_vaddr[30] 未见过 0 和 1"); end
    if (!(l_s0_io_tlb_req_req_bits_vaddr[31] && l_s1_io_tlb_req_req_bits_vaddr[31])) begin cov_fail++; $display("[COV] L1Prefetcher.io_tlb_req_req_bits_vaddr[31] 未见过 0 和 1"); end
    if (!(l_s0_io_tlb_req_req_bits_vaddr[32] && l_s1_io_tlb_req_req_bits_vaddr[32])) begin cov_fail++; $display("[COV] L1Prefetcher.io_tlb_req_req_bits_vaddr[32] 未见过 0 和 1"); end
    if (!(l_s0_io_tlb_req_req_bits_vaddr[33] && l_s1_io_tlb_req_req_bits_vaddr[33])) begin cov_fail++; $display("[COV] L1Prefetcher.io_tlb_req_req_bits_vaddr[33] 未见过 0 和 1"); end
    if (!(l_s0_io_tlb_req_req_bits_vaddr[34] && l_s1_io_tlb_req_req_bits_vaddr[34])) begin cov_fail++; $display("[COV] L1Prefetcher.io_tlb_req_req_bits_vaddr[34] 未见过 0 和 1"); end
    if (!(l_s0_io_tlb_req_req_bits_vaddr[35] && l_s1_io_tlb_req_req_bits_vaddr[35])) begin cov_fail++; $display("[COV] L1Prefetcher.io_tlb_req_req_bits_vaddr[35] 未见过 0 和 1"); end
    if (!(l_s0_io_tlb_req_req_bits_vaddr[36] && l_s1_io_tlb_req_req_bits_vaddr[36])) begin cov_fail++; $display("[COV] L1Prefetcher.io_tlb_req_req_bits_vaddr[36] 未见过 0 和 1"); end
    if (!(l_s0_io_tlb_req_req_bits_vaddr[37] && l_s1_io_tlb_req_req_bits_vaddr[37])) begin cov_fail++; $display("[COV] L1Prefetcher.io_tlb_req_req_bits_vaddr[37] 未见过 0 和 1"); end
    if (!(l_s0_io_tlb_req_req_bits_vaddr[38] && l_s1_io_tlb_req_req_bits_vaddr[38])) begin cov_fail++; $display("[COV] L1Prefetcher.io_tlb_req_req_bits_vaddr[38] 未见过 0 和 1"); end
    if (!(l_s0_io_tlb_req_req_bits_vaddr[39] && l_s1_io_tlb_req_req_bits_vaddr[39])) begin cov_fail++; $display("[COV] L1Prefetcher.io_tlb_req_req_bits_vaddr[39] 未见过 0 和 1"); end
    if (!(l_s0_io_tlb_req_req_bits_vaddr[40] && l_s1_io_tlb_req_req_bits_vaddr[40])) begin cov_fail++; $display("[COV] L1Prefetcher.io_tlb_req_req_bits_vaddr[40] 未见过 0 和 1"); end
    if (!(l_s0_io_tlb_req_req_bits_vaddr[41] && l_s1_io_tlb_req_req_bits_vaddr[41])) begin cov_fail++; $display("[COV] L1Prefetcher.io_tlb_req_req_bits_vaddr[41] 未见过 0 和 1"); end
    if (!(l_s0_io_tlb_req_req_bits_vaddr[42] && l_s1_io_tlb_req_req_bits_vaddr[42])) begin cov_fail++; $display("[COV] L1Prefetcher.io_tlb_req_req_bits_vaddr[42] 未见过 0 和 1"); end
    if (!(l_s0_io_tlb_req_req_bits_vaddr[43] && l_s1_io_tlb_req_req_bits_vaddr[43])) begin cov_fail++; $display("[COV] L1Prefetcher.io_tlb_req_req_bits_vaddr[43] 未见过 0 和 1"); end
    if (!(l_s0_io_tlb_req_req_bits_vaddr[44] && l_s1_io_tlb_req_req_bits_vaddr[44])) begin cov_fail++; $display("[COV] L1Prefetcher.io_tlb_req_req_bits_vaddr[44] 未见过 0 和 1"); end
    if (!(l_s0_io_tlb_req_req_bits_vaddr[45] && l_s1_io_tlb_req_req_bits_vaddr[45])) begin cov_fail++; $display("[COV] L1Prefetcher.io_tlb_req_req_bits_vaddr[45] 未见过 0 和 1"); end
    if (!(l_s0_io_tlb_req_req_bits_vaddr[46] && l_s1_io_tlb_req_req_bits_vaddr[46])) begin cov_fail++; $display("[COV] L1Prefetcher.io_tlb_req_req_bits_vaddr[46] 未见过 0 和 1"); end
    if (!(l_s0_io_tlb_req_req_bits_vaddr[47] && l_s1_io_tlb_req_req_bits_vaddr[47])) begin cov_fail++; $display("[COV] L1Prefetcher.io_tlb_req_req_bits_vaddr[47] 未见过 0 和 1"); end
    if (!(l_s0_io_tlb_req_req_bits_vaddr[48] && l_s1_io_tlb_req_req_bits_vaddr[48])) begin cov_fail++; $display("[COV] L1Prefetcher.io_tlb_req_req_bits_vaddr[48] 未见过 0 和 1"); end
    if (!(l_s0_io_tlb_req_req_bits_vaddr[49] && l_s1_io_tlb_req_req_bits_vaddr[49])) begin cov_fail++; $display("[COV] L1Prefetcher.io_tlb_req_req_bits_vaddr[49] 未见过 0 和 1"); end
    if (!(l_s0_io_l1_req_valid && l_s1_io_l1_req_valid)) begin cov_fail++; $display("[COV] L1Prefetcher.io_l1_req_valid 未见过 0 和 1"); end
    if (!(l_s0_io_l1_req_bits_paddr[6] && l_s1_io_l1_req_bits_paddr[6])) begin cov_fail++; $display("[COV] L1Prefetcher.io_l1_req_bits_paddr[6] 未见过 0 和 1"); end
    if (!(l_s0_io_l1_req_bits_paddr[7] && l_s1_io_l1_req_bits_paddr[7])) begin cov_fail++; $display("[COV] L1Prefetcher.io_l1_req_bits_paddr[7] 未见过 0 和 1"); end
    if (!(l_s0_io_l1_req_bits_paddr[8] && l_s1_io_l1_req_bits_paddr[8])) begin cov_fail++; $display("[COV] L1Prefetcher.io_l1_req_bits_paddr[8] 未见过 0 和 1"); end
    if (!(l_s0_io_l1_req_bits_paddr[9] && l_s1_io_l1_req_bits_paddr[9])) begin cov_fail++; $display("[COV] L1Prefetcher.io_l1_req_bits_paddr[9] 未见过 0 和 1"); end
    if (!(l_s0_io_l1_req_bits_paddr[10] && l_s1_io_l1_req_bits_paddr[10])) begin cov_fail++; $display("[COV] L1Prefetcher.io_l1_req_bits_paddr[10] 未见过 0 和 1"); end
    if (!(l_s0_io_l1_req_bits_paddr[11] && l_s1_io_l1_req_bits_paddr[11])) begin cov_fail++; $display("[COV] L1Prefetcher.io_l1_req_bits_paddr[11] 未见过 0 和 1"); end
    if (!(l_s0_io_l1_req_bits_paddr[12] && l_s1_io_l1_req_bits_paddr[12])) begin cov_fail++; $display("[COV] L1Prefetcher.io_l1_req_bits_paddr[12] 未见过 0 和 1"); end
    if (!(l_s0_io_l1_req_bits_paddr[13] && l_s1_io_l1_req_bits_paddr[13])) begin cov_fail++; $display("[COV] L1Prefetcher.io_l1_req_bits_paddr[13] 未见过 0 和 1"); end
    if (!(l_s0_io_l1_req_bits_paddr[14] && l_s1_io_l1_req_bits_paddr[14])) begin cov_fail++; $display("[COV] L1Prefetcher.io_l1_req_bits_paddr[14] 未见过 0 和 1"); end
    if (!(l_s0_io_l1_req_bits_paddr[15] && l_s1_io_l1_req_bits_paddr[15])) begin cov_fail++; $display("[COV] L1Prefetcher.io_l1_req_bits_paddr[15] 未见过 0 和 1"); end
    if (!(l_s0_io_l1_req_bits_paddr[16] && l_s1_io_l1_req_bits_paddr[16])) begin cov_fail++; $display("[COV] L1Prefetcher.io_l1_req_bits_paddr[16] 未见过 0 和 1"); end
    if (!(l_s0_io_l1_req_bits_paddr[17] && l_s1_io_l1_req_bits_paddr[17])) begin cov_fail++; $display("[COV] L1Prefetcher.io_l1_req_bits_paddr[17] 未见过 0 和 1"); end
    if (!(l_s0_io_l1_req_bits_paddr[18] && l_s1_io_l1_req_bits_paddr[18])) begin cov_fail++; $display("[COV] L1Prefetcher.io_l1_req_bits_paddr[18] 未见过 0 和 1"); end
    if (!(l_s0_io_l1_req_bits_paddr[19] && l_s1_io_l1_req_bits_paddr[19])) begin cov_fail++; $display("[COV] L1Prefetcher.io_l1_req_bits_paddr[19] 未见过 0 和 1"); end
    if (!(l_s0_io_l1_req_bits_paddr[20] && l_s1_io_l1_req_bits_paddr[20])) begin cov_fail++; $display("[COV] L1Prefetcher.io_l1_req_bits_paddr[20] 未见过 0 和 1"); end
    if (!(l_s0_io_l1_req_bits_paddr[21] && l_s1_io_l1_req_bits_paddr[21])) begin cov_fail++; $display("[COV] L1Prefetcher.io_l1_req_bits_paddr[21] 未见过 0 和 1"); end
    if (!(l_s0_io_l1_req_bits_paddr[22] && l_s1_io_l1_req_bits_paddr[22])) begin cov_fail++; $display("[COV] L1Prefetcher.io_l1_req_bits_paddr[22] 未见过 0 和 1"); end
    if (!(l_s0_io_l1_req_bits_paddr[23] && l_s1_io_l1_req_bits_paddr[23])) begin cov_fail++; $display("[COV] L1Prefetcher.io_l1_req_bits_paddr[23] 未见过 0 和 1"); end
    if (!(l_s0_io_l1_req_bits_paddr[24] && l_s1_io_l1_req_bits_paddr[24])) begin cov_fail++; $display("[COV] L1Prefetcher.io_l1_req_bits_paddr[24] 未见过 0 和 1"); end
    if (!(l_s0_io_l1_req_bits_paddr[25] && l_s1_io_l1_req_bits_paddr[25])) begin cov_fail++; $display("[COV] L1Prefetcher.io_l1_req_bits_paddr[25] 未见过 0 和 1"); end
    if (!(l_s0_io_l1_req_bits_paddr[26] && l_s1_io_l1_req_bits_paddr[26])) begin cov_fail++; $display("[COV] L1Prefetcher.io_l1_req_bits_paddr[26] 未见过 0 和 1"); end
    if (!(l_s0_io_l1_req_bits_paddr[27] && l_s1_io_l1_req_bits_paddr[27])) begin cov_fail++; $display("[COV] L1Prefetcher.io_l1_req_bits_paddr[27] 未见过 0 和 1"); end
    if (!(l_s0_io_l1_req_bits_paddr[28] && l_s1_io_l1_req_bits_paddr[28])) begin cov_fail++; $display("[COV] L1Prefetcher.io_l1_req_bits_paddr[28] 未见过 0 和 1"); end
    if (!(l_s0_io_l1_req_bits_paddr[29] && l_s1_io_l1_req_bits_paddr[29])) begin cov_fail++; $display("[COV] L1Prefetcher.io_l1_req_bits_paddr[29] 未见过 0 和 1"); end
    if (!(l_s0_io_l1_req_bits_paddr[30] && l_s1_io_l1_req_bits_paddr[30])) begin cov_fail++; $display("[COV] L1Prefetcher.io_l1_req_bits_paddr[30] 未见过 0 和 1"); end
    if (!(l_s0_io_l1_req_bits_paddr[31] && l_s1_io_l1_req_bits_paddr[31])) begin cov_fail++; $display("[COV] L1Prefetcher.io_l1_req_bits_paddr[31] 未见过 0 和 1"); end
    if (!(l_s0_io_l1_req_bits_paddr[32] && l_s1_io_l1_req_bits_paddr[32])) begin cov_fail++; $display("[COV] L1Prefetcher.io_l1_req_bits_paddr[32] 未见过 0 和 1"); end
    if (!(l_s0_io_l1_req_bits_paddr[33] && l_s1_io_l1_req_bits_paddr[33])) begin cov_fail++; $display("[COV] L1Prefetcher.io_l1_req_bits_paddr[33] 未见过 0 和 1"); end
    if (!(l_s0_io_l1_req_bits_paddr[34] && l_s1_io_l1_req_bits_paddr[34])) begin cov_fail++; $display("[COV] L1Prefetcher.io_l1_req_bits_paddr[34] 未见过 0 和 1"); end
    if (!(l_s0_io_l1_req_bits_paddr[35] && l_s1_io_l1_req_bits_paddr[35])) begin cov_fail++; $display("[COV] L1Prefetcher.io_l1_req_bits_paddr[35] 未见过 0 和 1"); end
    if (!(l_s0_io_l1_req_bits_paddr[36] && l_s1_io_l1_req_bits_paddr[36])) begin cov_fail++; $display("[COV] L1Prefetcher.io_l1_req_bits_paddr[36] 未见过 0 和 1"); end
    if (!(l_s0_io_l1_req_bits_paddr[37] && l_s1_io_l1_req_bits_paddr[37])) begin cov_fail++; $display("[COV] L1Prefetcher.io_l1_req_bits_paddr[37] 未见过 0 和 1"); end
    if (!(l_s0_io_l1_req_bits_paddr[38] && l_s1_io_l1_req_bits_paddr[38])) begin cov_fail++; $display("[COV] L1Prefetcher.io_l1_req_bits_paddr[38] 未见过 0 和 1"); end
    if (!(l_s0_io_l1_req_bits_paddr[39] && l_s1_io_l1_req_bits_paddr[39])) begin cov_fail++; $display("[COV] L1Prefetcher.io_l1_req_bits_paddr[39] 未见过 0 和 1"); end
    if (!(l_s0_io_l1_req_bits_paddr[40] && l_s1_io_l1_req_bits_paddr[40])) begin cov_fail++; $display("[COV] L1Prefetcher.io_l1_req_bits_paddr[40] 未见过 0 和 1"); end
    if (!(l_s0_io_l1_req_bits_paddr[41] && l_s1_io_l1_req_bits_paddr[41])) begin cov_fail++; $display("[COV] L1Prefetcher.io_l1_req_bits_paddr[41] 未见过 0 和 1"); end
    if (!(l_s0_io_l1_req_bits_paddr[42] && l_s1_io_l1_req_bits_paddr[42])) begin cov_fail++; $display("[COV] L1Prefetcher.io_l1_req_bits_paddr[42] 未见过 0 和 1"); end
    if (!(l_s0_io_l1_req_bits_paddr[43] && l_s1_io_l1_req_bits_paddr[43])) begin cov_fail++; $display("[COV] L1Prefetcher.io_l1_req_bits_paddr[43] 未见过 0 和 1"); end
    if (!(l_s0_io_l1_req_bits_paddr[44] && l_s1_io_l1_req_bits_paddr[44])) begin cov_fail++; $display("[COV] L1Prefetcher.io_l1_req_bits_paddr[44] 未见过 0 和 1"); end
    if (!(l_s0_io_l1_req_bits_paddr[45] && l_s1_io_l1_req_bits_paddr[45])) begin cov_fail++; $display("[COV] L1Prefetcher.io_l1_req_bits_paddr[45] 未见过 0 和 1"); end
    if (!(l_s0_io_l1_req_bits_paddr[46] && l_s1_io_l1_req_bits_paddr[46])) begin cov_fail++; $display("[COV] L1Prefetcher.io_l1_req_bits_paddr[46] 未见过 0 和 1"); end
    if (!(l_s0_io_l1_req_bits_paddr[47] && l_s1_io_l1_req_bits_paddr[47])) begin cov_fail++; $display("[COV] L1Prefetcher.io_l1_req_bits_paddr[47] 未见过 0 和 1"); end
    if (!(l_s0_io_l1_req_bits_alias[0] && l_s1_io_l1_req_bits_alias[0])) begin cov_fail++; $display("[COV] L1Prefetcher.io_l1_req_bits_alias[0] 未见过 0 和 1"); end
    if (!(l_s0_io_l1_req_bits_alias[1] && l_s1_io_l1_req_bits_alias[1])) begin cov_fail++; $display("[COV] L1Prefetcher.io_l1_req_bits_alias[1] 未见过 0 和 1"); end
    if (!(l_s0_io_l1_req_bits_confidence && l_s1_io_l1_req_bits_confidence)) begin cov_fail++; $display("[COV] L1Prefetcher.io_l1_req_bits_confidence 未见过 0 和 1"); end
    if (!(l_s0_io_l1_req_bits_pf_source_value[0] && l_s1_io_l1_req_bits_pf_source_value[0])) begin cov_fail++; $display("[COV] L1Prefetcher.io_l1_req_bits_pf_source_value[0] 未见过 0 和 1"); end
    if (!(l_s0_io_l2_req_valid && l_s1_io_l2_req_valid)) begin cov_fail++; $display("[COV] L1Prefetcher.io_l2_req_valid 未见过 0 和 1"); end
    if (!(l_s0_io_l2_req_bits_addr[6] && l_s1_io_l2_req_bits_addr[6])) begin cov_fail++; $display("[COV] L1Prefetcher.io_l2_req_bits_addr[6] 未见过 0 和 1"); end
    if (!(l_s0_io_l2_req_bits_addr[7] && l_s1_io_l2_req_bits_addr[7])) begin cov_fail++; $display("[COV] L1Prefetcher.io_l2_req_bits_addr[7] 未见过 0 和 1"); end
    if (!(l_s0_io_l2_req_bits_addr[8] && l_s1_io_l2_req_bits_addr[8])) begin cov_fail++; $display("[COV] L1Prefetcher.io_l2_req_bits_addr[8] 未见过 0 和 1"); end
    if (!(l_s0_io_l2_req_bits_addr[9] && l_s1_io_l2_req_bits_addr[9])) begin cov_fail++; $display("[COV] L1Prefetcher.io_l2_req_bits_addr[9] 未见过 0 和 1"); end
    if (!(l_s0_io_l2_req_bits_addr[10] && l_s1_io_l2_req_bits_addr[10])) begin cov_fail++; $display("[COV] L1Prefetcher.io_l2_req_bits_addr[10] 未见过 0 和 1"); end
    if (!(l_s0_io_l2_req_bits_addr[11] && l_s1_io_l2_req_bits_addr[11])) begin cov_fail++; $display("[COV] L1Prefetcher.io_l2_req_bits_addr[11] 未见过 0 和 1"); end
    if (!(l_s0_io_l2_req_bits_addr[12] && l_s1_io_l2_req_bits_addr[12])) begin cov_fail++; $display("[COV] L1Prefetcher.io_l2_req_bits_addr[12] 未见过 0 和 1"); end
    if (!(l_s0_io_l2_req_bits_addr[13] && l_s1_io_l2_req_bits_addr[13])) begin cov_fail++; $display("[COV] L1Prefetcher.io_l2_req_bits_addr[13] 未见过 0 和 1"); end
    if (!(l_s0_io_l2_req_bits_addr[14] && l_s1_io_l2_req_bits_addr[14])) begin cov_fail++; $display("[COV] L1Prefetcher.io_l2_req_bits_addr[14] 未见过 0 和 1"); end
    if (!(l_s0_io_l2_req_bits_addr[15] && l_s1_io_l2_req_bits_addr[15])) begin cov_fail++; $display("[COV] L1Prefetcher.io_l2_req_bits_addr[15] 未见过 0 和 1"); end
    if (!(l_s0_io_l2_req_bits_addr[16] && l_s1_io_l2_req_bits_addr[16])) begin cov_fail++; $display("[COV] L1Prefetcher.io_l2_req_bits_addr[16] 未见过 0 和 1"); end
    if (!(l_s0_io_l2_req_bits_addr[17] && l_s1_io_l2_req_bits_addr[17])) begin cov_fail++; $display("[COV] L1Prefetcher.io_l2_req_bits_addr[17] 未见过 0 和 1"); end
    if (!(l_s0_io_l2_req_bits_addr[18] && l_s1_io_l2_req_bits_addr[18])) begin cov_fail++; $display("[COV] L1Prefetcher.io_l2_req_bits_addr[18] 未见过 0 和 1"); end
    if (!(l_s0_io_l2_req_bits_addr[19] && l_s1_io_l2_req_bits_addr[19])) begin cov_fail++; $display("[COV] L1Prefetcher.io_l2_req_bits_addr[19] 未见过 0 和 1"); end
    if (!(l_s0_io_l2_req_bits_addr[20] && l_s1_io_l2_req_bits_addr[20])) begin cov_fail++; $display("[COV] L1Prefetcher.io_l2_req_bits_addr[20] 未见过 0 和 1"); end
    if (!(l_s0_io_l2_req_bits_addr[21] && l_s1_io_l2_req_bits_addr[21])) begin cov_fail++; $display("[COV] L1Prefetcher.io_l2_req_bits_addr[21] 未见过 0 和 1"); end
    if (!(l_s0_io_l2_req_bits_addr[22] && l_s1_io_l2_req_bits_addr[22])) begin cov_fail++; $display("[COV] L1Prefetcher.io_l2_req_bits_addr[22] 未见过 0 和 1"); end
    if (!(l_s0_io_l2_req_bits_addr[23] && l_s1_io_l2_req_bits_addr[23])) begin cov_fail++; $display("[COV] L1Prefetcher.io_l2_req_bits_addr[23] 未见过 0 和 1"); end
    if (!(l_s0_io_l2_req_bits_addr[24] && l_s1_io_l2_req_bits_addr[24])) begin cov_fail++; $display("[COV] L1Prefetcher.io_l2_req_bits_addr[24] 未见过 0 和 1"); end
    if (!(l_s0_io_l2_req_bits_addr[25] && l_s1_io_l2_req_bits_addr[25])) begin cov_fail++; $display("[COV] L1Prefetcher.io_l2_req_bits_addr[25] 未见过 0 和 1"); end
    if (!(l_s0_io_l2_req_bits_addr[26] && l_s1_io_l2_req_bits_addr[26])) begin cov_fail++; $display("[COV] L1Prefetcher.io_l2_req_bits_addr[26] 未见过 0 和 1"); end
    if (!(l_s0_io_l2_req_bits_addr[27] && l_s1_io_l2_req_bits_addr[27])) begin cov_fail++; $display("[COV] L1Prefetcher.io_l2_req_bits_addr[27] 未见过 0 和 1"); end
    if (!(l_s0_io_l2_req_bits_addr[28] && l_s1_io_l2_req_bits_addr[28])) begin cov_fail++; $display("[COV] L1Prefetcher.io_l2_req_bits_addr[28] 未见过 0 和 1"); end
    if (!(l_s0_io_l2_req_bits_addr[29] && l_s1_io_l2_req_bits_addr[29])) begin cov_fail++; $display("[COV] L1Prefetcher.io_l2_req_bits_addr[29] 未见过 0 和 1"); end
    if (!(l_s0_io_l2_req_bits_addr[30] && l_s1_io_l2_req_bits_addr[30])) begin cov_fail++; $display("[COV] L1Prefetcher.io_l2_req_bits_addr[30] 未见过 0 和 1"); end
    if (!(l_s0_io_l2_req_bits_addr[31] && l_s1_io_l2_req_bits_addr[31])) begin cov_fail++; $display("[COV] L1Prefetcher.io_l2_req_bits_addr[31] 未见过 0 和 1"); end
    if (!(l_s0_io_l2_req_bits_addr[32] && l_s1_io_l2_req_bits_addr[32])) begin cov_fail++; $display("[COV] L1Prefetcher.io_l2_req_bits_addr[32] 未见过 0 和 1"); end
    if (!(l_s0_io_l2_req_bits_addr[33] && l_s1_io_l2_req_bits_addr[33])) begin cov_fail++; $display("[COV] L1Prefetcher.io_l2_req_bits_addr[33] 未见过 0 和 1"); end
    if (!(l_s0_io_l2_req_bits_addr[34] && l_s1_io_l2_req_bits_addr[34])) begin cov_fail++; $display("[COV] L1Prefetcher.io_l2_req_bits_addr[34] 未见过 0 和 1"); end
    if (!(l_s0_io_l2_req_bits_addr[35] && l_s1_io_l2_req_bits_addr[35])) begin cov_fail++; $display("[COV] L1Prefetcher.io_l2_req_bits_addr[35] 未见过 0 和 1"); end
    if (!(l_s0_io_l2_req_bits_addr[36] && l_s1_io_l2_req_bits_addr[36])) begin cov_fail++; $display("[COV] L1Prefetcher.io_l2_req_bits_addr[36] 未见过 0 和 1"); end
    if (!(l_s0_io_l2_req_bits_addr[37] && l_s1_io_l2_req_bits_addr[37])) begin cov_fail++; $display("[COV] L1Prefetcher.io_l2_req_bits_addr[37] 未见过 0 和 1"); end
    if (!(l_s0_io_l2_req_bits_addr[38] && l_s1_io_l2_req_bits_addr[38])) begin cov_fail++; $display("[COV] L1Prefetcher.io_l2_req_bits_addr[38] 未见过 0 和 1"); end
    if (!(l_s0_io_l2_req_bits_addr[39] && l_s1_io_l2_req_bits_addr[39])) begin cov_fail++; $display("[COV] L1Prefetcher.io_l2_req_bits_addr[39] 未见过 0 和 1"); end
    if (!(l_s0_io_l2_req_bits_addr[40] && l_s1_io_l2_req_bits_addr[40])) begin cov_fail++; $display("[COV] L1Prefetcher.io_l2_req_bits_addr[40] 未见过 0 和 1"); end
    if (!(l_s0_io_l2_req_bits_addr[41] && l_s1_io_l2_req_bits_addr[41])) begin cov_fail++; $display("[COV] L1Prefetcher.io_l2_req_bits_addr[41] 未见过 0 和 1"); end
    if (!(l_s0_io_l2_req_bits_addr[42] && l_s1_io_l2_req_bits_addr[42])) begin cov_fail++; $display("[COV] L1Prefetcher.io_l2_req_bits_addr[42] 未见过 0 和 1"); end
    if (!(l_s0_io_l2_req_bits_addr[43] && l_s1_io_l2_req_bits_addr[43])) begin cov_fail++; $display("[COV] L1Prefetcher.io_l2_req_bits_addr[43] 未见过 0 和 1"); end
    if (!(l_s0_io_l2_req_bits_addr[44] && l_s1_io_l2_req_bits_addr[44])) begin cov_fail++; $display("[COV] L1Prefetcher.io_l2_req_bits_addr[44] 未见过 0 和 1"); end
    if (!(l_s0_io_l2_req_bits_addr[45] && l_s1_io_l2_req_bits_addr[45])) begin cov_fail++; $display("[COV] L1Prefetcher.io_l2_req_bits_addr[45] 未见过 0 和 1"); end
    if (!(l_s0_io_l2_req_bits_addr[46] && l_s1_io_l2_req_bits_addr[46])) begin cov_fail++; $display("[COV] L1Prefetcher.io_l2_req_bits_addr[46] 未见过 0 和 1"); end
    if (!(l_s0_io_l2_req_bits_addr[47] && l_s1_io_l2_req_bits_addr[47])) begin cov_fail++; $display("[COV] L1Prefetcher.io_l2_req_bits_addr[47] 未见过 0 和 1"); end
    if (!(l_s0_io_l2_req_bits_source[0] && l_s1_io_l2_req_bits_source[0])) begin cov_fail++; $display("[COV] L1Prefetcher.io_l2_req_bits_source[0] 未见过 0 和 1"); end
    if (!(l_s0_io_l2_req_bits_source[1] && l_s1_io_l2_req_bits_source[1])) begin cov_fail++; $display("[COV] L1Prefetcher.io_l2_req_bits_source[1] 未见过 0 和 1"); end
    if (!(l_s0_io_l2_req_bits_source[2] && l_s1_io_l2_req_bits_source[2])) begin cov_fail++; $display("[COV] L1Prefetcher.io_l2_req_bits_source[2] 未见过 0 和 1"); end
    $display("[ARM] L1Prefetcher armed_at=%0d", l_armed_at);
    if (l_armed_at < 0) begin cov_fail++; $display("[ARM] L1Prefetcher 从未 arm"); end
    $display("[COV] L1Prefetcher.l1_req = %0d", l_cov_l1_req);
    if (l_cov_l1_req < 5) begin cov_fail++; $display("[COV] L1Prefetcher.l1_req < 5"); end
    $display("[COV] L1Prefetcher.l2_req = %0d", l_cov_l2_req);
    if (l_cov_l2_req < 5) begin cov_fail++; $display("[COV] L1Prefetcher.l2_req < 5"); end
    $display("[COV] L1Prefetcher.tlb_req = %0d", l_cov_tlb_req);
    if (l_cov_tlb_req < 5) begin cov_fail++; $display("[COV] L1Prefetcher.tlb_req < 5"); end
    $display("[COV] L1Prefetcher.stream_l1 = %0d", l_cov_stream_l1);
    if (l_cov_stream_l1 < 5) begin cov_fail++; $display("[COV] L1Prefetcher.stream_l1 < 5"); end
    $display("[COV] L1Prefetcher.stride_l1 = %0d", l_cov_stride_l1);
    if (l_cov_stride_l1 < 5) begin cov_fail++; $display("[COV] L1Prefetcher.stride_l1 < 5"); end
    $display("[COV] L1Prefetcher.both_l1 = %0d", l_cov_both_l1);
    if (l_cov_both_l1 < 5) begin cov_fail++; $display("[COV] L1Prefetcher.both_l1 < 5"); end
    $display("[COV] L1Prefetcher.stride_l2l3 = %0d", l_cov_stride_l2l3);
    if (l_cov_stride_l2l3 < 5) begin cov_fail++; $display("[COV] L1Prefetcher.stride_l2l3 < 5"); end
    $display("[COV] L1Prefetcher.pf_ctrl_off = %0d", l_cov_pf_ctrl_off);
    if (l_cov_pf_ctrl_off < 5) begin cov_fail++; $display("[COV] L1Prefetcher.pf_ctrl_off < 5"); end
    $display("[COV] L1Prefetcher.l2_out_of_pmem = %0d", l_cov_l2_out_of_pmem);
    if (l_cov_l2_out_of_pmem < 5) begin cov_fail++; $display("[COV] L1Prefetcher.l2_out_of_pmem < 5"); end
    $display("checks=%0d errors=%0d cov_fail=%0d", checks, errors, cov_fail);
    if (errors == 0 && cov_fail == 0 && checks > 0) $display("TEST PASSED");
    else $display("TEST FAILED");
    $finish;
  end
endmodule
