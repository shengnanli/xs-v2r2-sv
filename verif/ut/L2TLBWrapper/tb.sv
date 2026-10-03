// L2TLBWrapper 双例化 UT（由 gen.py 生成，勿手改）
`timescale 1ns/1ps
module tb;
  int unsigned NCYCLES = 200000;
  int errors = 0, checks = 0, cov_fail = 0;
  int unsigned cyc = 0;
  logic clk = 1'b0;
  always #5 clk = ~clk;
  localparam int RESET_CYC = 8;

  // ================= L2TLBWrapper =================
  int unsigned w_mode = 0;
  initial begin
    #1;
    force w_u_impl.perf_stage1[0] = w_u_gold.io_perf_0_value_REG;
    force w_u_impl.perf_stage2[0] = w_u_gold.io_perf_0_value_REG_1;
    force w_u_impl.perf_stage1[1] = w_u_gold.io_perf_1_value_REG;
    force w_u_impl.perf_stage2[1] = w_u_gold.io_perf_1_value_REG_1;
    force w_u_impl.perf_stage1[2] = w_u_gold.io_perf_2_value_REG;
    force w_u_impl.perf_stage2[2] = w_u_gold.io_perf_2_value_REG_1;
    force w_u_impl.perf_stage1[3] = w_u_gold.io_perf_3_value_REG;
    force w_u_impl.perf_stage2[3] = w_u_gold.io_perf_3_value_REG_1;
    force w_u_impl.perf_stage1[4] = w_u_gold.io_perf_4_value_REG;
    force w_u_impl.perf_stage2[4] = w_u_gold.io_perf_4_value_REG_1;
    force w_u_impl.perf_stage1[5] = w_u_gold.io_perf_5_value_REG;
    force w_u_impl.perf_stage2[5] = w_u_gold.io_perf_5_value_REG_1;
    force w_u_impl.perf_stage1[6] = w_u_gold.io_perf_6_value_REG;
    force w_u_impl.perf_stage2[6] = w_u_gold.io_perf_6_value_REG_1;
    force w_u_impl.perf_stage1[7] = w_u_gold.io_perf_7_value_REG;
    force w_u_impl.perf_stage2[7] = w_u_gold.io_perf_7_value_REG_1;
    force w_u_impl.perf_stage1[8] = w_u_gold.io_perf_8_value_REG;
    force w_u_impl.perf_stage2[8] = w_u_gold.io_perf_8_value_REG_1;
    force w_u_impl.perf_stage1[9] = w_u_gold.io_perf_9_value_REG;
    force w_u_impl.perf_stage2[9] = w_u_gold.io_perf_9_value_REG_1;
    force w_u_impl.perf_stage1[10] = w_u_gold.io_perf_10_value_REG;
    force w_u_impl.perf_stage2[10] = w_u_gold.io_perf_10_value_REG_1;
    force w_u_impl.perf_stage1[11] = w_u_gold.io_perf_11_value_REG;
    force w_u_impl.perf_stage2[11] = w_u_gold.io_perf_11_value_REG_1;
    force w_u_impl.perf_stage1[12] = w_u_gold.io_perf_12_value_REG;
    force w_u_impl.perf_stage2[12] = w_u_gold.io_perf_12_value_REG_1;
    force w_u_impl.perf_stage1[13] = w_u_gold.io_perf_13_value_REG;
    force w_u_impl.perf_stage2[13] = w_u_gold.io_perf_13_value_REG_1;
    force w_u_impl.perf_stage1[14] = w_u_gold.io_perf_14_value_REG;
    force w_u_impl.perf_stage2[14] = w_u_gold.io_perf_14_value_REG_1;
    force w_u_impl.perf_stage1[15] = w_u_gold.io_perf_15_value_REG;
    force w_u_impl.perf_stage2[15] = w_u_gold.io_perf_15_value_REG_1;
    force w_u_impl.perf_stage1[16] = w_u_gold.io_perf_16_value_REG;
    force w_u_impl.perf_stage2[16] = w_u_gold.io_perf_16_value_REG_1;
    force w_u_impl.perf_stage1[17] = w_u_gold.io_perf_17_value_REG;
    force w_u_impl.perf_stage2[17] = w_u_gold.io_perf_17_value_REG_1;
    force w_u_impl.perf_stage1[18] = w_u_gold.io_perf_18_value_REG;
    force w_u_impl.perf_stage2[18] = w_u_gold.io_perf_18_value_REG_1;
    #0;
    release w_u_impl.perf_stage1[0];
    release w_u_impl.perf_stage2[0];
    release w_u_impl.perf_stage1[1];
    release w_u_impl.perf_stage2[1];
    release w_u_impl.perf_stage1[2];
    release w_u_impl.perf_stage2[2];
    release w_u_impl.perf_stage1[3];
    release w_u_impl.perf_stage2[3];
    release w_u_impl.perf_stage1[4];
    release w_u_impl.perf_stage2[4];
    release w_u_impl.perf_stage1[5];
    release w_u_impl.perf_stage2[5];
    release w_u_impl.perf_stage1[6];
    release w_u_impl.perf_stage2[6];
    release w_u_impl.perf_stage1[7];
    release w_u_impl.perf_stage2[7];
    release w_u_impl.perf_stage1[8];
    release w_u_impl.perf_stage2[8];
    release w_u_impl.perf_stage1[9];
    release w_u_impl.perf_stage2[9];
    release w_u_impl.perf_stage1[10];
    release w_u_impl.perf_stage2[10];
    release w_u_impl.perf_stage1[11];
    release w_u_impl.perf_stage2[11];
    release w_u_impl.perf_stage1[12];
    release w_u_impl.perf_stage2[12];
    release w_u_impl.perf_stage1[13];
    release w_u_impl.perf_stage2[13];
    release w_u_impl.perf_stage1[14];
    release w_u_impl.perf_stage2[14];
    release w_u_impl.perf_stage1[15];
    release w_u_impl.perf_stage2[15];
    release w_u_impl.perf_stage1[16];
    release w_u_impl.perf_stage2[16];
    release w_u_impl.perf_stage1[17];
    release w_u_impl.perf_stage2[17];
    release w_u_impl.perf_stage1[18];
    release w_u_impl.perf_stage2[18];
  end
  logic w_reset;
  logic w_auto_out_a_ready;
  wire  w_g_auto_out_a_valid, w_i_auto_out_a_valid;
  logic w_s0_auto_out_a_valid = '0, w_s1_auto_out_a_valid = '0;
  wire  [3:0] w_g_auto_out_a_bits_source, w_i_auto_out_a_bits_source;
  logic [3:0] w_s0_auto_out_a_bits_source = '0, w_s1_auto_out_a_bits_source = '0;
  wire  [47:0] w_g_auto_out_a_bits_address, w_i_auto_out_a_bits_address;
  logic [47:0] w_s0_auto_out_a_bits_address = '0, w_s1_auto_out_a_bits_address = '0;
  logic w_auto_out_d_valid;
  logic [3:0] w_auto_out_d_bits_opcode;
  logic [2:0] w_auto_out_d_bits_size;
  logic [3:0] w_auto_out_d_bits_source;
  logic [255:0] w_auto_out_d_bits_data;
  logic [5:0] w_io_hartId;
  wire  w_g_io_tlb_0_req_0_ready, w_i_io_tlb_0_req_0_ready;
  logic w_s0_io_tlb_0_req_0_ready = '0, w_s1_io_tlb_0_req_0_ready = '0;
  logic w_io_tlb_0_req_0_valid;
  logic [37:0] w_io_tlb_0_req_0_bits_vpn;
  logic [1:0] w_io_tlb_0_req_0_bits_s2xlate;
  logic w_io_tlb_0_resp_ready;
  wire  w_g_io_tlb_0_resp_valid, w_i_io_tlb_0_resp_valid;
  logic w_s0_io_tlb_0_resp_valid = '0, w_s1_io_tlb_0_resp_valid = '0;
  wire  [1:0] w_g_io_tlb_0_resp_bits_s2xlate, w_i_io_tlb_0_resp_bits_s2xlate;
  logic [1:0] w_s0_io_tlb_0_resp_bits_s2xlate = '0, w_s1_io_tlb_0_resp_bits_s2xlate = '0;
  wire  [34:0] w_g_io_tlb_0_resp_bits_s1_entry_tag, w_i_io_tlb_0_resp_bits_s1_entry_tag;
  logic [34:0] w_s0_io_tlb_0_resp_bits_s1_entry_tag = '0, w_s1_io_tlb_0_resp_bits_s1_entry_tag = '0;
  wire  [15:0] w_g_io_tlb_0_resp_bits_s1_entry_asid, w_i_io_tlb_0_resp_bits_s1_entry_asid;
  logic [15:0] w_s0_io_tlb_0_resp_bits_s1_entry_asid = '0, w_s1_io_tlb_0_resp_bits_s1_entry_asid = '0;
  wire  [13:0] w_g_io_tlb_0_resp_bits_s1_entry_vmid, w_i_io_tlb_0_resp_bits_s1_entry_vmid;
  logic [13:0] w_s0_io_tlb_0_resp_bits_s1_entry_vmid = '0, w_s1_io_tlb_0_resp_bits_s1_entry_vmid = '0;
  wire  w_g_io_tlb_0_resp_bits_s1_entry_n, w_i_io_tlb_0_resp_bits_s1_entry_n;
  logic w_s0_io_tlb_0_resp_bits_s1_entry_n = '0, w_s1_io_tlb_0_resp_bits_s1_entry_n = '0;
  wire  [1:0] w_g_io_tlb_0_resp_bits_s1_entry_pbmt, w_i_io_tlb_0_resp_bits_s1_entry_pbmt;
  logic [1:0] w_s0_io_tlb_0_resp_bits_s1_entry_pbmt = '0, w_s1_io_tlb_0_resp_bits_s1_entry_pbmt = '0;
  wire  w_g_io_tlb_0_resp_bits_s1_entry_perm_d, w_i_io_tlb_0_resp_bits_s1_entry_perm_d;
  logic w_s0_io_tlb_0_resp_bits_s1_entry_perm_d = '0, w_s1_io_tlb_0_resp_bits_s1_entry_perm_d = '0;
  wire  w_g_io_tlb_0_resp_bits_s1_entry_perm_a, w_i_io_tlb_0_resp_bits_s1_entry_perm_a;
  logic w_s0_io_tlb_0_resp_bits_s1_entry_perm_a = '0, w_s1_io_tlb_0_resp_bits_s1_entry_perm_a = '0;
  wire  w_g_io_tlb_0_resp_bits_s1_entry_perm_g, w_i_io_tlb_0_resp_bits_s1_entry_perm_g;
  logic w_s0_io_tlb_0_resp_bits_s1_entry_perm_g = '0, w_s1_io_tlb_0_resp_bits_s1_entry_perm_g = '0;
  wire  w_g_io_tlb_0_resp_bits_s1_entry_perm_u, w_i_io_tlb_0_resp_bits_s1_entry_perm_u;
  logic w_s0_io_tlb_0_resp_bits_s1_entry_perm_u = '0, w_s1_io_tlb_0_resp_bits_s1_entry_perm_u = '0;
  wire  w_g_io_tlb_0_resp_bits_s1_entry_perm_x, w_i_io_tlb_0_resp_bits_s1_entry_perm_x;
  logic w_s0_io_tlb_0_resp_bits_s1_entry_perm_x = '0, w_s1_io_tlb_0_resp_bits_s1_entry_perm_x = '0;
  wire  w_g_io_tlb_0_resp_bits_s1_entry_perm_w, w_i_io_tlb_0_resp_bits_s1_entry_perm_w;
  logic w_s0_io_tlb_0_resp_bits_s1_entry_perm_w = '0, w_s1_io_tlb_0_resp_bits_s1_entry_perm_w = '0;
  wire  w_g_io_tlb_0_resp_bits_s1_entry_perm_r, w_i_io_tlb_0_resp_bits_s1_entry_perm_r;
  logic w_s0_io_tlb_0_resp_bits_s1_entry_perm_r = '0, w_s1_io_tlb_0_resp_bits_s1_entry_perm_r = '0;
  wire  [1:0] w_g_io_tlb_0_resp_bits_s1_entry_level, w_i_io_tlb_0_resp_bits_s1_entry_level;
  logic [1:0] w_s0_io_tlb_0_resp_bits_s1_entry_level = '0, w_s1_io_tlb_0_resp_bits_s1_entry_level = '0;
  wire  w_g_io_tlb_0_resp_bits_s1_entry_v, w_i_io_tlb_0_resp_bits_s1_entry_v;
  logic w_s0_io_tlb_0_resp_bits_s1_entry_v = '0, w_s1_io_tlb_0_resp_bits_s1_entry_v = '0;
  wire  [40:0] w_g_io_tlb_0_resp_bits_s1_entry_ppn, w_i_io_tlb_0_resp_bits_s1_entry_ppn;
  logic [40:0] w_s0_io_tlb_0_resp_bits_s1_entry_ppn = '0, w_s1_io_tlb_0_resp_bits_s1_entry_ppn = '0;
  wire  [2:0] w_g_io_tlb_0_resp_bits_s1_addr_low, w_i_io_tlb_0_resp_bits_s1_addr_low;
  logic [2:0] w_s0_io_tlb_0_resp_bits_s1_addr_low = '0, w_s1_io_tlb_0_resp_bits_s1_addr_low = '0;
  wire  [2:0] w_g_io_tlb_0_resp_bits_s1_ppn_low_0, w_i_io_tlb_0_resp_bits_s1_ppn_low_0;
  logic [2:0] w_s0_io_tlb_0_resp_bits_s1_ppn_low_0 = '0, w_s1_io_tlb_0_resp_bits_s1_ppn_low_0 = '0;
  wire  [2:0] w_g_io_tlb_0_resp_bits_s1_ppn_low_1, w_i_io_tlb_0_resp_bits_s1_ppn_low_1;
  logic [2:0] w_s0_io_tlb_0_resp_bits_s1_ppn_low_1 = '0, w_s1_io_tlb_0_resp_bits_s1_ppn_low_1 = '0;
  wire  [2:0] w_g_io_tlb_0_resp_bits_s1_ppn_low_2, w_i_io_tlb_0_resp_bits_s1_ppn_low_2;
  logic [2:0] w_s0_io_tlb_0_resp_bits_s1_ppn_low_2 = '0, w_s1_io_tlb_0_resp_bits_s1_ppn_low_2 = '0;
  wire  [2:0] w_g_io_tlb_0_resp_bits_s1_ppn_low_3, w_i_io_tlb_0_resp_bits_s1_ppn_low_3;
  logic [2:0] w_s0_io_tlb_0_resp_bits_s1_ppn_low_3 = '0, w_s1_io_tlb_0_resp_bits_s1_ppn_low_3 = '0;
  wire  [2:0] w_g_io_tlb_0_resp_bits_s1_ppn_low_4, w_i_io_tlb_0_resp_bits_s1_ppn_low_4;
  logic [2:0] w_s0_io_tlb_0_resp_bits_s1_ppn_low_4 = '0, w_s1_io_tlb_0_resp_bits_s1_ppn_low_4 = '0;
  wire  [2:0] w_g_io_tlb_0_resp_bits_s1_ppn_low_5, w_i_io_tlb_0_resp_bits_s1_ppn_low_5;
  logic [2:0] w_s0_io_tlb_0_resp_bits_s1_ppn_low_5 = '0, w_s1_io_tlb_0_resp_bits_s1_ppn_low_5 = '0;
  wire  [2:0] w_g_io_tlb_0_resp_bits_s1_ppn_low_6, w_i_io_tlb_0_resp_bits_s1_ppn_low_6;
  logic [2:0] w_s0_io_tlb_0_resp_bits_s1_ppn_low_6 = '0, w_s1_io_tlb_0_resp_bits_s1_ppn_low_6 = '0;
  wire  [2:0] w_g_io_tlb_0_resp_bits_s1_ppn_low_7, w_i_io_tlb_0_resp_bits_s1_ppn_low_7;
  logic [2:0] w_s0_io_tlb_0_resp_bits_s1_ppn_low_7 = '0, w_s1_io_tlb_0_resp_bits_s1_ppn_low_7 = '0;
  wire  w_g_io_tlb_0_resp_bits_s1_valididx_0, w_i_io_tlb_0_resp_bits_s1_valididx_0;
  logic w_s0_io_tlb_0_resp_bits_s1_valididx_0 = '0, w_s1_io_tlb_0_resp_bits_s1_valididx_0 = '0;
  wire  w_g_io_tlb_0_resp_bits_s1_valididx_1, w_i_io_tlb_0_resp_bits_s1_valididx_1;
  logic w_s0_io_tlb_0_resp_bits_s1_valididx_1 = '0, w_s1_io_tlb_0_resp_bits_s1_valididx_1 = '0;
  wire  w_g_io_tlb_0_resp_bits_s1_valididx_2, w_i_io_tlb_0_resp_bits_s1_valididx_2;
  logic w_s0_io_tlb_0_resp_bits_s1_valididx_2 = '0, w_s1_io_tlb_0_resp_bits_s1_valididx_2 = '0;
  wire  w_g_io_tlb_0_resp_bits_s1_valididx_3, w_i_io_tlb_0_resp_bits_s1_valididx_3;
  logic w_s0_io_tlb_0_resp_bits_s1_valididx_3 = '0, w_s1_io_tlb_0_resp_bits_s1_valididx_3 = '0;
  wire  w_g_io_tlb_0_resp_bits_s1_valididx_4, w_i_io_tlb_0_resp_bits_s1_valididx_4;
  logic w_s0_io_tlb_0_resp_bits_s1_valididx_4 = '0, w_s1_io_tlb_0_resp_bits_s1_valididx_4 = '0;
  wire  w_g_io_tlb_0_resp_bits_s1_valididx_5, w_i_io_tlb_0_resp_bits_s1_valididx_5;
  logic w_s0_io_tlb_0_resp_bits_s1_valididx_5 = '0, w_s1_io_tlb_0_resp_bits_s1_valididx_5 = '0;
  wire  w_g_io_tlb_0_resp_bits_s1_valididx_6, w_i_io_tlb_0_resp_bits_s1_valididx_6;
  logic w_s0_io_tlb_0_resp_bits_s1_valididx_6 = '0, w_s1_io_tlb_0_resp_bits_s1_valididx_6 = '0;
  wire  w_g_io_tlb_0_resp_bits_s1_valididx_7, w_i_io_tlb_0_resp_bits_s1_valididx_7;
  logic w_s0_io_tlb_0_resp_bits_s1_valididx_7 = '0, w_s1_io_tlb_0_resp_bits_s1_valididx_7 = '0;
  wire  w_g_io_tlb_0_resp_bits_s1_pteidx_0, w_i_io_tlb_0_resp_bits_s1_pteidx_0;
  logic w_s0_io_tlb_0_resp_bits_s1_pteidx_0 = '0, w_s1_io_tlb_0_resp_bits_s1_pteidx_0 = '0;
  wire  w_g_io_tlb_0_resp_bits_s1_pteidx_1, w_i_io_tlb_0_resp_bits_s1_pteidx_1;
  logic w_s0_io_tlb_0_resp_bits_s1_pteidx_1 = '0, w_s1_io_tlb_0_resp_bits_s1_pteidx_1 = '0;
  wire  w_g_io_tlb_0_resp_bits_s1_pteidx_2, w_i_io_tlb_0_resp_bits_s1_pteidx_2;
  logic w_s0_io_tlb_0_resp_bits_s1_pteidx_2 = '0, w_s1_io_tlb_0_resp_bits_s1_pteidx_2 = '0;
  wire  w_g_io_tlb_0_resp_bits_s1_pteidx_3, w_i_io_tlb_0_resp_bits_s1_pteidx_3;
  logic w_s0_io_tlb_0_resp_bits_s1_pteidx_3 = '0, w_s1_io_tlb_0_resp_bits_s1_pteidx_3 = '0;
  wire  w_g_io_tlb_0_resp_bits_s1_pteidx_4, w_i_io_tlb_0_resp_bits_s1_pteidx_4;
  logic w_s0_io_tlb_0_resp_bits_s1_pteidx_4 = '0, w_s1_io_tlb_0_resp_bits_s1_pteidx_4 = '0;
  wire  w_g_io_tlb_0_resp_bits_s1_pteidx_5, w_i_io_tlb_0_resp_bits_s1_pteidx_5;
  logic w_s0_io_tlb_0_resp_bits_s1_pteidx_5 = '0, w_s1_io_tlb_0_resp_bits_s1_pteidx_5 = '0;
  wire  w_g_io_tlb_0_resp_bits_s1_pteidx_6, w_i_io_tlb_0_resp_bits_s1_pteidx_6;
  logic w_s0_io_tlb_0_resp_bits_s1_pteidx_6 = '0, w_s1_io_tlb_0_resp_bits_s1_pteidx_6 = '0;
  wire  w_g_io_tlb_0_resp_bits_s1_pteidx_7, w_i_io_tlb_0_resp_bits_s1_pteidx_7;
  logic w_s0_io_tlb_0_resp_bits_s1_pteidx_7 = '0, w_s1_io_tlb_0_resp_bits_s1_pteidx_7 = '0;
  wire  w_g_io_tlb_0_resp_bits_s1_pf, w_i_io_tlb_0_resp_bits_s1_pf;
  logic w_s0_io_tlb_0_resp_bits_s1_pf = '0, w_s1_io_tlb_0_resp_bits_s1_pf = '0;
  wire  w_g_io_tlb_0_resp_bits_s1_af, w_i_io_tlb_0_resp_bits_s1_af;
  logic w_s0_io_tlb_0_resp_bits_s1_af = '0, w_s1_io_tlb_0_resp_bits_s1_af = '0;
  wire  [37:0] w_g_io_tlb_0_resp_bits_s2_entry_tag, w_i_io_tlb_0_resp_bits_s2_entry_tag;
  logic [37:0] w_s0_io_tlb_0_resp_bits_s2_entry_tag = '0, w_s1_io_tlb_0_resp_bits_s2_entry_tag = '0;
  wire  [13:0] w_g_io_tlb_0_resp_bits_s2_entry_vmid, w_i_io_tlb_0_resp_bits_s2_entry_vmid;
  logic [13:0] w_s0_io_tlb_0_resp_bits_s2_entry_vmid = '0, w_s1_io_tlb_0_resp_bits_s2_entry_vmid = '0;
  wire  w_g_io_tlb_0_resp_bits_s2_entry_n, w_i_io_tlb_0_resp_bits_s2_entry_n;
  logic w_s0_io_tlb_0_resp_bits_s2_entry_n = '0, w_s1_io_tlb_0_resp_bits_s2_entry_n = '0;
  wire  [1:0] w_g_io_tlb_0_resp_bits_s2_entry_pbmt, w_i_io_tlb_0_resp_bits_s2_entry_pbmt;
  logic [1:0] w_s0_io_tlb_0_resp_bits_s2_entry_pbmt = '0, w_s1_io_tlb_0_resp_bits_s2_entry_pbmt = '0;
  wire  [37:0] w_g_io_tlb_0_resp_bits_s2_entry_ppn, w_i_io_tlb_0_resp_bits_s2_entry_ppn;
  logic [37:0] w_s0_io_tlb_0_resp_bits_s2_entry_ppn = '0, w_s1_io_tlb_0_resp_bits_s2_entry_ppn = '0;
  wire  w_g_io_tlb_0_resp_bits_s2_entry_perm_d, w_i_io_tlb_0_resp_bits_s2_entry_perm_d;
  logic w_s0_io_tlb_0_resp_bits_s2_entry_perm_d = '0, w_s1_io_tlb_0_resp_bits_s2_entry_perm_d = '0;
  wire  w_g_io_tlb_0_resp_bits_s2_entry_perm_a, w_i_io_tlb_0_resp_bits_s2_entry_perm_a;
  logic w_s0_io_tlb_0_resp_bits_s2_entry_perm_a = '0, w_s1_io_tlb_0_resp_bits_s2_entry_perm_a = '0;
  wire  w_g_io_tlb_0_resp_bits_s2_entry_perm_g, w_i_io_tlb_0_resp_bits_s2_entry_perm_g;
  logic w_s0_io_tlb_0_resp_bits_s2_entry_perm_g = '0, w_s1_io_tlb_0_resp_bits_s2_entry_perm_g = '0;
  wire  w_g_io_tlb_0_resp_bits_s2_entry_perm_u, w_i_io_tlb_0_resp_bits_s2_entry_perm_u;
  logic w_s0_io_tlb_0_resp_bits_s2_entry_perm_u = '0, w_s1_io_tlb_0_resp_bits_s2_entry_perm_u = '0;
  wire  w_g_io_tlb_0_resp_bits_s2_entry_perm_x, w_i_io_tlb_0_resp_bits_s2_entry_perm_x;
  logic w_s0_io_tlb_0_resp_bits_s2_entry_perm_x = '0, w_s1_io_tlb_0_resp_bits_s2_entry_perm_x = '0;
  wire  w_g_io_tlb_0_resp_bits_s2_entry_perm_w, w_i_io_tlb_0_resp_bits_s2_entry_perm_w;
  logic w_s0_io_tlb_0_resp_bits_s2_entry_perm_w = '0, w_s1_io_tlb_0_resp_bits_s2_entry_perm_w = '0;
  wire  w_g_io_tlb_0_resp_bits_s2_entry_perm_r, w_i_io_tlb_0_resp_bits_s2_entry_perm_r;
  logic w_s0_io_tlb_0_resp_bits_s2_entry_perm_r = '0, w_s1_io_tlb_0_resp_bits_s2_entry_perm_r = '0;
  wire  [1:0] w_g_io_tlb_0_resp_bits_s2_entry_level, w_i_io_tlb_0_resp_bits_s2_entry_level;
  logic [1:0] w_s0_io_tlb_0_resp_bits_s2_entry_level = '0, w_s1_io_tlb_0_resp_bits_s2_entry_level = '0;
  wire  w_g_io_tlb_0_resp_bits_s2_gpf, w_i_io_tlb_0_resp_bits_s2_gpf;
  logic w_s0_io_tlb_0_resp_bits_s2_gpf = '0, w_s1_io_tlb_0_resp_bits_s2_gpf = '0;
  wire  w_g_io_tlb_0_resp_bits_s2_gaf, w_i_io_tlb_0_resp_bits_s2_gaf;
  logic w_s0_io_tlb_0_resp_bits_s2_gaf = '0, w_s1_io_tlb_0_resp_bits_s2_gaf = '0;
  wire  w_g_io_tlb_1_req_0_ready, w_i_io_tlb_1_req_0_ready;
  logic w_s0_io_tlb_1_req_0_ready = '0, w_s1_io_tlb_1_req_0_ready = '0;
  logic w_io_tlb_1_req_0_valid;
  logic [37:0] w_io_tlb_1_req_0_bits_vpn;
  logic [1:0] w_io_tlb_1_req_0_bits_s2xlate;
  wire  w_g_io_tlb_1_resp_valid, w_i_io_tlb_1_resp_valid;
  logic w_s0_io_tlb_1_resp_valid = '0, w_s1_io_tlb_1_resp_valid = '0;
  wire  [1:0] w_g_io_tlb_1_resp_bits_s2xlate, w_i_io_tlb_1_resp_bits_s2xlate;
  logic [1:0] w_s0_io_tlb_1_resp_bits_s2xlate = '0, w_s1_io_tlb_1_resp_bits_s2xlate = '0;
  wire  [34:0] w_g_io_tlb_1_resp_bits_s1_entry_tag, w_i_io_tlb_1_resp_bits_s1_entry_tag;
  logic [34:0] w_s0_io_tlb_1_resp_bits_s1_entry_tag = '0, w_s1_io_tlb_1_resp_bits_s1_entry_tag = '0;
  wire  [15:0] w_g_io_tlb_1_resp_bits_s1_entry_asid, w_i_io_tlb_1_resp_bits_s1_entry_asid;
  logic [15:0] w_s0_io_tlb_1_resp_bits_s1_entry_asid = '0, w_s1_io_tlb_1_resp_bits_s1_entry_asid = '0;
  wire  [13:0] w_g_io_tlb_1_resp_bits_s1_entry_vmid, w_i_io_tlb_1_resp_bits_s1_entry_vmid;
  logic [13:0] w_s0_io_tlb_1_resp_bits_s1_entry_vmid = '0, w_s1_io_tlb_1_resp_bits_s1_entry_vmid = '0;
  wire  w_g_io_tlb_1_resp_bits_s1_entry_n, w_i_io_tlb_1_resp_bits_s1_entry_n;
  logic w_s0_io_tlb_1_resp_bits_s1_entry_n = '0, w_s1_io_tlb_1_resp_bits_s1_entry_n = '0;
  wire  [1:0] w_g_io_tlb_1_resp_bits_s1_entry_pbmt, w_i_io_tlb_1_resp_bits_s1_entry_pbmt;
  logic [1:0] w_s0_io_tlb_1_resp_bits_s1_entry_pbmt = '0, w_s1_io_tlb_1_resp_bits_s1_entry_pbmt = '0;
  wire  w_g_io_tlb_1_resp_bits_s1_entry_perm_d, w_i_io_tlb_1_resp_bits_s1_entry_perm_d;
  logic w_s0_io_tlb_1_resp_bits_s1_entry_perm_d = '0, w_s1_io_tlb_1_resp_bits_s1_entry_perm_d = '0;
  wire  w_g_io_tlb_1_resp_bits_s1_entry_perm_a, w_i_io_tlb_1_resp_bits_s1_entry_perm_a;
  logic w_s0_io_tlb_1_resp_bits_s1_entry_perm_a = '0, w_s1_io_tlb_1_resp_bits_s1_entry_perm_a = '0;
  wire  w_g_io_tlb_1_resp_bits_s1_entry_perm_g, w_i_io_tlb_1_resp_bits_s1_entry_perm_g;
  logic w_s0_io_tlb_1_resp_bits_s1_entry_perm_g = '0, w_s1_io_tlb_1_resp_bits_s1_entry_perm_g = '0;
  wire  w_g_io_tlb_1_resp_bits_s1_entry_perm_u, w_i_io_tlb_1_resp_bits_s1_entry_perm_u;
  logic w_s0_io_tlb_1_resp_bits_s1_entry_perm_u = '0, w_s1_io_tlb_1_resp_bits_s1_entry_perm_u = '0;
  wire  w_g_io_tlb_1_resp_bits_s1_entry_perm_x, w_i_io_tlb_1_resp_bits_s1_entry_perm_x;
  logic w_s0_io_tlb_1_resp_bits_s1_entry_perm_x = '0, w_s1_io_tlb_1_resp_bits_s1_entry_perm_x = '0;
  wire  w_g_io_tlb_1_resp_bits_s1_entry_perm_w, w_i_io_tlb_1_resp_bits_s1_entry_perm_w;
  logic w_s0_io_tlb_1_resp_bits_s1_entry_perm_w = '0, w_s1_io_tlb_1_resp_bits_s1_entry_perm_w = '0;
  wire  w_g_io_tlb_1_resp_bits_s1_entry_perm_r, w_i_io_tlb_1_resp_bits_s1_entry_perm_r;
  logic w_s0_io_tlb_1_resp_bits_s1_entry_perm_r = '0, w_s1_io_tlb_1_resp_bits_s1_entry_perm_r = '0;
  wire  [1:0] w_g_io_tlb_1_resp_bits_s1_entry_level, w_i_io_tlb_1_resp_bits_s1_entry_level;
  logic [1:0] w_s0_io_tlb_1_resp_bits_s1_entry_level = '0, w_s1_io_tlb_1_resp_bits_s1_entry_level = '0;
  wire  w_g_io_tlb_1_resp_bits_s1_entry_v, w_i_io_tlb_1_resp_bits_s1_entry_v;
  logic w_s0_io_tlb_1_resp_bits_s1_entry_v = '0, w_s1_io_tlb_1_resp_bits_s1_entry_v = '0;
  wire  [40:0] w_g_io_tlb_1_resp_bits_s1_entry_ppn, w_i_io_tlb_1_resp_bits_s1_entry_ppn;
  logic [40:0] w_s0_io_tlb_1_resp_bits_s1_entry_ppn = '0, w_s1_io_tlb_1_resp_bits_s1_entry_ppn = '0;
  wire  [2:0] w_g_io_tlb_1_resp_bits_s1_addr_low, w_i_io_tlb_1_resp_bits_s1_addr_low;
  logic [2:0] w_s0_io_tlb_1_resp_bits_s1_addr_low = '0, w_s1_io_tlb_1_resp_bits_s1_addr_low = '0;
  wire  [2:0] w_g_io_tlb_1_resp_bits_s1_ppn_low_0, w_i_io_tlb_1_resp_bits_s1_ppn_low_0;
  logic [2:0] w_s0_io_tlb_1_resp_bits_s1_ppn_low_0 = '0, w_s1_io_tlb_1_resp_bits_s1_ppn_low_0 = '0;
  wire  [2:0] w_g_io_tlb_1_resp_bits_s1_ppn_low_1, w_i_io_tlb_1_resp_bits_s1_ppn_low_1;
  logic [2:0] w_s0_io_tlb_1_resp_bits_s1_ppn_low_1 = '0, w_s1_io_tlb_1_resp_bits_s1_ppn_low_1 = '0;
  wire  [2:0] w_g_io_tlb_1_resp_bits_s1_ppn_low_2, w_i_io_tlb_1_resp_bits_s1_ppn_low_2;
  logic [2:0] w_s0_io_tlb_1_resp_bits_s1_ppn_low_2 = '0, w_s1_io_tlb_1_resp_bits_s1_ppn_low_2 = '0;
  wire  [2:0] w_g_io_tlb_1_resp_bits_s1_ppn_low_3, w_i_io_tlb_1_resp_bits_s1_ppn_low_3;
  logic [2:0] w_s0_io_tlb_1_resp_bits_s1_ppn_low_3 = '0, w_s1_io_tlb_1_resp_bits_s1_ppn_low_3 = '0;
  wire  [2:0] w_g_io_tlb_1_resp_bits_s1_ppn_low_4, w_i_io_tlb_1_resp_bits_s1_ppn_low_4;
  logic [2:0] w_s0_io_tlb_1_resp_bits_s1_ppn_low_4 = '0, w_s1_io_tlb_1_resp_bits_s1_ppn_low_4 = '0;
  wire  [2:0] w_g_io_tlb_1_resp_bits_s1_ppn_low_5, w_i_io_tlb_1_resp_bits_s1_ppn_low_5;
  logic [2:0] w_s0_io_tlb_1_resp_bits_s1_ppn_low_5 = '0, w_s1_io_tlb_1_resp_bits_s1_ppn_low_5 = '0;
  wire  [2:0] w_g_io_tlb_1_resp_bits_s1_ppn_low_6, w_i_io_tlb_1_resp_bits_s1_ppn_low_6;
  logic [2:0] w_s0_io_tlb_1_resp_bits_s1_ppn_low_6 = '0, w_s1_io_tlb_1_resp_bits_s1_ppn_low_6 = '0;
  wire  [2:0] w_g_io_tlb_1_resp_bits_s1_ppn_low_7, w_i_io_tlb_1_resp_bits_s1_ppn_low_7;
  logic [2:0] w_s0_io_tlb_1_resp_bits_s1_ppn_low_7 = '0, w_s1_io_tlb_1_resp_bits_s1_ppn_low_7 = '0;
  wire  w_g_io_tlb_1_resp_bits_s1_valididx_0, w_i_io_tlb_1_resp_bits_s1_valididx_0;
  logic w_s0_io_tlb_1_resp_bits_s1_valididx_0 = '0, w_s1_io_tlb_1_resp_bits_s1_valididx_0 = '0;
  wire  w_g_io_tlb_1_resp_bits_s1_valididx_1, w_i_io_tlb_1_resp_bits_s1_valididx_1;
  logic w_s0_io_tlb_1_resp_bits_s1_valididx_1 = '0, w_s1_io_tlb_1_resp_bits_s1_valididx_1 = '0;
  wire  w_g_io_tlb_1_resp_bits_s1_valididx_2, w_i_io_tlb_1_resp_bits_s1_valididx_2;
  logic w_s0_io_tlb_1_resp_bits_s1_valididx_2 = '0, w_s1_io_tlb_1_resp_bits_s1_valididx_2 = '0;
  wire  w_g_io_tlb_1_resp_bits_s1_valididx_3, w_i_io_tlb_1_resp_bits_s1_valididx_3;
  logic w_s0_io_tlb_1_resp_bits_s1_valididx_3 = '0, w_s1_io_tlb_1_resp_bits_s1_valididx_3 = '0;
  wire  w_g_io_tlb_1_resp_bits_s1_valididx_4, w_i_io_tlb_1_resp_bits_s1_valididx_4;
  logic w_s0_io_tlb_1_resp_bits_s1_valididx_4 = '0, w_s1_io_tlb_1_resp_bits_s1_valididx_4 = '0;
  wire  w_g_io_tlb_1_resp_bits_s1_valididx_5, w_i_io_tlb_1_resp_bits_s1_valididx_5;
  logic w_s0_io_tlb_1_resp_bits_s1_valididx_5 = '0, w_s1_io_tlb_1_resp_bits_s1_valididx_5 = '0;
  wire  w_g_io_tlb_1_resp_bits_s1_valididx_6, w_i_io_tlb_1_resp_bits_s1_valididx_6;
  logic w_s0_io_tlb_1_resp_bits_s1_valididx_6 = '0, w_s1_io_tlb_1_resp_bits_s1_valididx_6 = '0;
  wire  w_g_io_tlb_1_resp_bits_s1_valididx_7, w_i_io_tlb_1_resp_bits_s1_valididx_7;
  logic w_s0_io_tlb_1_resp_bits_s1_valididx_7 = '0, w_s1_io_tlb_1_resp_bits_s1_valididx_7 = '0;
  wire  w_g_io_tlb_1_resp_bits_s1_pteidx_0, w_i_io_tlb_1_resp_bits_s1_pteidx_0;
  logic w_s0_io_tlb_1_resp_bits_s1_pteidx_0 = '0, w_s1_io_tlb_1_resp_bits_s1_pteidx_0 = '0;
  wire  w_g_io_tlb_1_resp_bits_s1_pteidx_1, w_i_io_tlb_1_resp_bits_s1_pteidx_1;
  logic w_s0_io_tlb_1_resp_bits_s1_pteidx_1 = '0, w_s1_io_tlb_1_resp_bits_s1_pteidx_1 = '0;
  wire  w_g_io_tlb_1_resp_bits_s1_pteidx_2, w_i_io_tlb_1_resp_bits_s1_pteidx_2;
  logic w_s0_io_tlb_1_resp_bits_s1_pteidx_2 = '0, w_s1_io_tlb_1_resp_bits_s1_pteidx_2 = '0;
  wire  w_g_io_tlb_1_resp_bits_s1_pteidx_3, w_i_io_tlb_1_resp_bits_s1_pteidx_3;
  logic w_s0_io_tlb_1_resp_bits_s1_pteidx_3 = '0, w_s1_io_tlb_1_resp_bits_s1_pteidx_3 = '0;
  wire  w_g_io_tlb_1_resp_bits_s1_pteidx_4, w_i_io_tlb_1_resp_bits_s1_pteidx_4;
  logic w_s0_io_tlb_1_resp_bits_s1_pteidx_4 = '0, w_s1_io_tlb_1_resp_bits_s1_pteidx_4 = '0;
  wire  w_g_io_tlb_1_resp_bits_s1_pteidx_5, w_i_io_tlb_1_resp_bits_s1_pteidx_5;
  logic w_s0_io_tlb_1_resp_bits_s1_pteidx_5 = '0, w_s1_io_tlb_1_resp_bits_s1_pteidx_5 = '0;
  wire  w_g_io_tlb_1_resp_bits_s1_pteidx_6, w_i_io_tlb_1_resp_bits_s1_pteidx_6;
  logic w_s0_io_tlb_1_resp_bits_s1_pteidx_6 = '0, w_s1_io_tlb_1_resp_bits_s1_pteidx_6 = '0;
  wire  w_g_io_tlb_1_resp_bits_s1_pteidx_7, w_i_io_tlb_1_resp_bits_s1_pteidx_7;
  logic w_s0_io_tlb_1_resp_bits_s1_pteidx_7 = '0, w_s1_io_tlb_1_resp_bits_s1_pteidx_7 = '0;
  wire  w_g_io_tlb_1_resp_bits_s1_pf, w_i_io_tlb_1_resp_bits_s1_pf;
  logic w_s0_io_tlb_1_resp_bits_s1_pf = '0, w_s1_io_tlb_1_resp_bits_s1_pf = '0;
  wire  w_g_io_tlb_1_resp_bits_s1_af, w_i_io_tlb_1_resp_bits_s1_af;
  logic w_s0_io_tlb_1_resp_bits_s1_af = '0, w_s1_io_tlb_1_resp_bits_s1_af = '0;
  wire  [37:0] w_g_io_tlb_1_resp_bits_s2_entry_tag, w_i_io_tlb_1_resp_bits_s2_entry_tag;
  logic [37:0] w_s0_io_tlb_1_resp_bits_s2_entry_tag = '0, w_s1_io_tlb_1_resp_bits_s2_entry_tag = '0;
  wire  [13:0] w_g_io_tlb_1_resp_bits_s2_entry_vmid, w_i_io_tlb_1_resp_bits_s2_entry_vmid;
  logic [13:0] w_s0_io_tlb_1_resp_bits_s2_entry_vmid = '0, w_s1_io_tlb_1_resp_bits_s2_entry_vmid = '0;
  wire  w_g_io_tlb_1_resp_bits_s2_entry_n, w_i_io_tlb_1_resp_bits_s2_entry_n;
  logic w_s0_io_tlb_1_resp_bits_s2_entry_n = '0, w_s1_io_tlb_1_resp_bits_s2_entry_n = '0;
  wire  [1:0] w_g_io_tlb_1_resp_bits_s2_entry_pbmt, w_i_io_tlb_1_resp_bits_s2_entry_pbmt;
  logic [1:0] w_s0_io_tlb_1_resp_bits_s2_entry_pbmt = '0, w_s1_io_tlb_1_resp_bits_s2_entry_pbmt = '0;
  wire  [37:0] w_g_io_tlb_1_resp_bits_s2_entry_ppn, w_i_io_tlb_1_resp_bits_s2_entry_ppn;
  logic [37:0] w_s0_io_tlb_1_resp_bits_s2_entry_ppn = '0, w_s1_io_tlb_1_resp_bits_s2_entry_ppn = '0;
  wire  w_g_io_tlb_1_resp_bits_s2_entry_perm_d, w_i_io_tlb_1_resp_bits_s2_entry_perm_d;
  logic w_s0_io_tlb_1_resp_bits_s2_entry_perm_d = '0, w_s1_io_tlb_1_resp_bits_s2_entry_perm_d = '0;
  wire  w_g_io_tlb_1_resp_bits_s2_entry_perm_a, w_i_io_tlb_1_resp_bits_s2_entry_perm_a;
  logic w_s0_io_tlb_1_resp_bits_s2_entry_perm_a = '0, w_s1_io_tlb_1_resp_bits_s2_entry_perm_a = '0;
  wire  w_g_io_tlb_1_resp_bits_s2_entry_perm_g, w_i_io_tlb_1_resp_bits_s2_entry_perm_g;
  logic w_s0_io_tlb_1_resp_bits_s2_entry_perm_g = '0, w_s1_io_tlb_1_resp_bits_s2_entry_perm_g = '0;
  wire  w_g_io_tlb_1_resp_bits_s2_entry_perm_u, w_i_io_tlb_1_resp_bits_s2_entry_perm_u;
  logic w_s0_io_tlb_1_resp_bits_s2_entry_perm_u = '0, w_s1_io_tlb_1_resp_bits_s2_entry_perm_u = '0;
  wire  w_g_io_tlb_1_resp_bits_s2_entry_perm_x, w_i_io_tlb_1_resp_bits_s2_entry_perm_x;
  logic w_s0_io_tlb_1_resp_bits_s2_entry_perm_x = '0, w_s1_io_tlb_1_resp_bits_s2_entry_perm_x = '0;
  wire  w_g_io_tlb_1_resp_bits_s2_entry_perm_w, w_i_io_tlb_1_resp_bits_s2_entry_perm_w;
  logic w_s0_io_tlb_1_resp_bits_s2_entry_perm_w = '0, w_s1_io_tlb_1_resp_bits_s2_entry_perm_w = '0;
  wire  w_g_io_tlb_1_resp_bits_s2_entry_perm_r, w_i_io_tlb_1_resp_bits_s2_entry_perm_r;
  logic w_s0_io_tlb_1_resp_bits_s2_entry_perm_r = '0, w_s1_io_tlb_1_resp_bits_s2_entry_perm_r = '0;
  wire  [1:0] w_g_io_tlb_1_resp_bits_s2_entry_level, w_i_io_tlb_1_resp_bits_s2_entry_level;
  logic [1:0] w_s0_io_tlb_1_resp_bits_s2_entry_level = '0, w_s1_io_tlb_1_resp_bits_s2_entry_level = '0;
  wire  w_g_io_tlb_1_resp_bits_s2_gpf, w_i_io_tlb_1_resp_bits_s2_gpf;
  logic w_s0_io_tlb_1_resp_bits_s2_gpf = '0, w_s1_io_tlb_1_resp_bits_s2_gpf = '0;
  wire  w_g_io_tlb_1_resp_bits_s2_gaf, w_i_io_tlb_1_resp_bits_s2_gaf;
  logic w_s0_io_tlb_1_resp_bits_s2_gaf = '0, w_s1_io_tlb_1_resp_bits_s2_gaf = '0;
  logic w_io_sfence_valid;
  logic w_io_sfence_bits_rs1;
  logic w_io_sfence_bits_rs2;
  logic [49:0] w_io_sfence_bits_addr;
  logic [15:0] w_io_sfence_bits_id;
  logic w_io_sfence_bits_hv;
  logic w_io_sfence_bits_hg;
  logic w_io_wfi_wfiReq;
  wire  w_g_io_wfi_wfiSafe, w_i_io_wfi_wfiSafe;
  logic w_s0_io_wfi_wfiSafe = '0, w_s1_io_wfi_wfiSafe = '0;
  logic [3:0] w_io_csr_tlb_satp_mode;
  logic [15:0] w_io_csr_tlb_satp_asid;
  logic [43:0] w_io_csr_tlb_satp_ppn;
  logic w_io_csr_tlb_satp_changed;
  logic [3:0] w_io_csr_tlb_vsatp_mode;
  logic [15:0] w_io_csr_tlb_vsatp_asid;
  logic [43:0] w_io_csr_tlb_vsatp_ppn;
  logic w_io_csr_tlb_vsatp_changed;
  logic [3:0] w_io_csr_tlb_hgatp_mode;
  logic [15:0] w_io_csr_tlb_hgatp_vmid;
  logic [43:0] w_io_csr_tlb_hgatp_ppn;
  logic w_io_csr_tlb_hgatp_changed;
  logic w_io_csr_tlb_mbmc_BME;
  logic w_io_csr_tlb_mbmc_CMODE;
  logic w_io_csr_tlb_mbmc_BCLEAR;
  logic [57:0] w_io_csr_tlb_mbmc_BMA;
  logic w_io_csr_tlb_priv_virt;
  logic w_io_csr_tlb_priv_virt_changed;
  logic w_io_csr_tlb_priv_debug;
  logic w_io_csr_tlb_mPBMTE;
  logic w_io_csr_tlb_hPBMTE;
  logic w_io_csr_distribute_csr_w_valid;
  logic [11:0] w_io_csr_distribute_csr_w_bits_addr;
  logic [63:0] w_io_csr_distribute_csr_w_bits_data;
  wire  [5:0] w_g_io_perf_0_value, w_i_io_perf_0_value;
  logic [5:0] w_s0_io_perf_0_value = '0, w_s1_io_perf_0_value = '0;
  wire  [5:0] w_g_io_perf_1_value, w_i_io_perf_1_value;
  logic [5:0] w_s0_io_perf_1_value = '0, w_s1_io_perf_1_value = '0;
  wire  [5:0] w_g_io_perf_2_value, w_i_io_perf_2_value;
  logic [5:0] w_s0_io_perf_2_value = '0, w_s1_io_perf_2_value = '0;
  wire  [5:0] w_g_io_perf_3_value, w_i_io_perf_3_value;
  logic [5:0] w_s0_io_perf_3_value = '0, w_s1_io_perf_3_value = '0;
  wire  [5:0] w_g_io_perf_4_value, w_i_io_perf_4_value;
  logic [5:0] w_s0_io_perf_4_value = '0, w_s1_io_perf_4_value = '0;
  wire  [5:0] w_g_io_perf_5_value, w_i_io_perf_5_value;
  logic [5:0] w_s0_io_perf_5_value = '0, w_s1_io_perf_5_value = '0;
  wire  [5:0] w_g_io_perf_6_value, w_i_io_perf_6_value;
  logic [5:0] w_s0_io_perf_6_value = '0, w_s1_io_perf_6_value = '0;
  wire  [5:0] w_g_io_perf_7_value, w_i_io_perf_7_value;
  logic [5:0] w_s0_io_perf_7_value = '0, w_s1_io_perf_7_value = '0;
  wire  [5:0] w_g_io_perf_8_value, w_i_io_perf_8_value;
  logic [5:0] w_s0_io_perf_8_value = '0, w_s1_io_perf_8_value = '0;
  wire  [5:0] w_g_io_perf_9_value, w_i_io_perf_9_value;
  logic [5:0] w_s0_io_perf_9_value = '0, w_s1_io_perf_9_value = '0;
  wire  [5:0] w_g_io_perf_10_value, w_i_io_perf_10_value;
  logic [5:0] w_s0_io_perf_10_value = '0, w_s1_io_perf_10_value = '0;
  wire  [5:0] w_g_io_perf_11_value, w_i_io_perf_11_value;
  logic [5:0] w_s0_io_perf_11_value = '0, w_s1_io_perf_11_value = '0;
  wire  [5:0] w_g_io_perf_12_value, w_i_io_perf_12_value;
  logic [5:0] w_s0_io_perf_12_value = '0, w_s1_io_perf_12_value = '0;
  wire  [5:0] w_g_io_perf_13_value, w_i_io_perf_13_value;
  logic [5:0] w_s0_io_perf_13_value = '0, w_s1_io_perf_13_value = '0;
  wire  [5:0] w_g_io_perf_14_value, w_i_io_perf_14_value;
  logic [5:0] w_s0_io_perf_14_value = '0, w_s1_io_perf_14_value = '0;
  wire  [5:0] w_g_io_perf_15_value, w_i_io_perf_15_value;
  logic [5:0] w_s0_io_perf_15_value = '0, w_s1_io_perf_15_value = '0;
  wire  [5:0] w_g_io_perf_16_value, w_i_io_perf_16_value;
  logic [5:0] w_s0_io_perf_16_value = '0, w_s1_io_perf_16_value = '0;
  wire  [5:0] w_g_io_perf_17_value, w_i_io_perf_17_value;
  logic [5:0] w_s0_io_perf_17_value = '0, w_s1_io_perf_17_value = '0;
  wire  [5:0] w_g_io_perf_18_value, w_i_io_perf_18_value;
  logic [5:0] w_s0_io_perf_18_value = '0, w_s1_io_perf_18_value = '0;
  logic [5:0] w_boreChildrenBd_bore_array;
  logic w_boreChildrenBd_bore_all;
  logic w_boreChildrenBd_bore_req;
  wire  w_g_boreChildrenBd_bore_ack, w_i_boreChildrenBd_bore_ack;
  logic w_s0_boreChildrenBd_bore_ack = '0, w_s1_boreChildrenBd_bore_ack = '0;
  logic w_boreChildrenBd_bore_writeen;
  logic [1:0] w_boreChildrenBd_bore_be;
  logic [5:0] w_boreChildrenBd_bore_addr;
  logic [89:0] w_boreChildrenBd_bore_indata;
  logic w_boreChildrenBd_bore_readen;
  logic [5:0] w_boreChildrenBd_bore_addr_rd;
  wire  [89:0] w_g_boreChildrenBd_bore_outdata, w_i_boreChildrenBd_bore_outdata;
  logic [89:0] w_s0_boreChildrenBd_bore_outdata = '0, w_s1_boreChildrenBd_bore_outdata = '0;
  logic [5:0] w_boreChildrenBd_bore_1_array;
  logic w_boreChildrenBd_bore_1_all;
  logic w_boreChildrenBd_bore_1_req;
  wire  w_g_boreChildrenBd_bore_1_ack, w_i_boreChildrenBd_bore_1_ack;
  logic w_s0_boreChildrenBd_bore_1_ack = '0, w_s1_boreChildrenBd_bore_1_ack = '0;
  logic w_boreChildrenBd_bore_1_writeen;
  logic w_boreChildrenBd_bore_1_be;
  logic [2:0] w_boreChildrenBd_bore_1_addr;
  logic [130:0] w_boreChildrenBd_bore_1_indata;
  logic w_boreChildrenBd_bore_1_readen;
  logic [2:0] w_boreChildrenBd_bore_1_addr_rd;
  wire  [130:0] w_g_boreChildrenBd_bore_1_outdata, w_i_boreChildrenBd_bore_1_outdata;
  logic [130:0] w_s0_boreChildrenBd_bore_1_outdata = '0, w_s1_boreChildrenBd_bore_1_outdata = '0;
  logic [6:0] w_boreChildrenBd_bore_2_array;
  logic w_boreChildrenBd_bore_2_all;
  logic w_boreChildrenBd_bore_2_req;
  wire  w_g_boreChildrenBd_bore_2_ack, w_i_boreChildrenBd_bore_2_ack;
  logic w_s0_boreChildrenBd_bore_2_ack = '0, w_s1_boreChildrenBd_bore_2_ack = '0;
  logic w_boreChildrenBd_bore_2_writeen;
  logic [1:0] w_boreChildrenBd_bore_2_be;
  logic [6:0] w_boreChildrenBd_bore_2_addr;
  logic [113:0] w_boreChildrenBd_bore_2_indata;
  logic w_boreChildrenBd_bore_2_readen;
  logic [6:0] w_boreChildrenBd_bore_2_addr_rd;
  wire  [113:0] w_g_boreChildrenBd_bore_2_outdata, w_i_boreChildrenBd_bore_2_outdata;
  logic [113:0] w_s0_boreChildrenBd_bore_2_outdata = '0, w_s1_boreChildrenBd_bore_2_outdata = '0;
  logic w_sigFromSrams_bore_ram_hold;
  logic w_sigFromSrams_bore_ram_bypass;
  logic w_sigFromSrams_bore_ram_bp_clken;
  logic w_sigFromSrams_bore_ram_aux_clk;
  logic w_sigFromSrams_bore_ram_aux_ckbp;
  logic w_sigFromSrams_bore_ram_mcp_hold;
  logic w_sigFromSrams_bore_cgen;
  logic w_sigFromSrams_bore_1_ram_hold;
  logic w_sigFromSrams_bore_1_ram_bypass;
  logic w_sigFromSrams_bore_1_ram_bp_clken;
  logic w_sigFromSrams_bore_1_ram_aux_clk;
  logic w_sigFromSrams_bore_1_ram_aux_ckbp;
  logic w_sigFromSrams_bore_1_ram_mcp_hold;
  logic w_sigFromSrams_bore_1_cgen;
  logic w_sigFromSrams_bore_2_ram_hold;
  logic w_sigFromSrams_bore_2_ram_bypass;
  logic w_sigFromSrams_bore_2_ram_bp_clken;
  logic w_sigFromSrams_bore_2_ram_aux_clk;
  logic w_sigFromSrams_bore_2_ram_aux_ckbp;
  logic w_sigFromSrams_bore_2_ram_mcp_hold;
  logic w_sigFromSrams_bore_2_cgen;
  logic w_sigFromSrams_bore_3_ram_hold;
  logic w_sigFromSrams_bore_3_ram_bypass;
  logic w_sigFromSrams_bore_3_ram_bp_clken;
  logic w_sigFromSrams_bore_3_ram_aux_clk;
  logic w_sigFromSrams_bore_3_ram_aux_ckbp;
  logic w_sigFromSrams_bore_3_ram_mcp_hold;
  logic w_sigFromSrams_bore_3_cgen;
  logic w_sigFromSrams_bore_4_ram_hold;
  logic w_sigFromSrams_bore_4_ram_bypass;
  logic w_sigFromSrams_bore_4_ram_bp_clken;
  logic w_sigFromSrams_bore_4_ram_aux_clk;
  logic w_sigFromSrams_bore_4_ram_aux_ckbp;
  logic w_sigFromSrams_bore_4_ram_mcp_hold;
  logic w_sigFromSrams_bore_4_cgen;
  logic w_sigFromSrams_bore_5_ram_hold;
  logic w_sigFromSrams_bore_5_ram_bypass;
  logic w_sigFromSrams_bore_5_ram_bp_clken;
  logic w_sigFromSrams_bore_5_ram_aux_clk;
  logic w_sigFromSrams_bore_5_ram_aux_ckbp;
  logic w_sigFromSrams_bore_5_ram_mcp_hold;
  logic w_sigFromSrams_bore_5_cgen;
  logic w_sigFromSrams_bore_6_ram_hold;
  logic w_sigFromSrams_bore_6_ram_bypass;
  logic w_sigFromSrams_bore_6_ram_bp_clken;
  logic w_sigFromSrams_bore_6_ram_aux_clk;
  logic w_sigFromSrams_bore_6_ram_aux_ckbp;
  logic w_sigFromSrams_bore_6_ram_mcp_hold;
  logic w_sigFromSrams_bore_6_cgen;
  logic w_sigFromSrams_bore_7_ram_hold;
  logic w_sigFromSrams_bore_7_ram_bypass;
  logic w_sigFromSrams_bore_7_ram_bp_clken;
  logic w_sigFromSrams_bore_7_ram_aux_clk;
  logic w_sigFromSrams_bore_7_ram_aux_ckbp;
  logic w_sigFromSrams_bore_7_ram_mcp_hold;
  logic w_sigFromSrams_bore_7_cgen;
  logic w_sigFromSrams_bore_8_ram_hold;
  logic w_sigFromSrams_bore_8_ram_bypass;
  logic w_sigFromSrams_bore_8_ram_bp_clken;
  logic w_sigFromSrams_bore_8_ram_aux_clk;
  logic w_sigFromSrams_bore_8_ram_aux_ckbp;
  logic w_sigFromSrams_bore_8_ram_mcp_hold;
  logic w_sigFromSrams_bore_8_cgen;
  logic w_sigFromSrams_bore_9_ram_hold;
  logic w_sigFromSrams_bore_9_ram_bypass;
  logic w_sigFromSrams_bore_9_ram_bp_clken;
  logic w_sigFromSrams_bore_9_ram_aux_clk;
  logic w_sigFromSrams_bore_9_ram_aux_ckbp;
  logic w_sigFromSrams_bore_9_ram_mcp_hold;
  logic w_sigFromSrams_bore_9_cgen;
  logic w_sigFromSrams_bore_10_ram_hold;
  logic w_sigFromSrams_bore_10_ram_bypass;
  logic w_sigFromSrams_bore_10_ram_bp_clken;
  logic w_sigFromSrams_bore_10_ram_aux_clk;
  logic w_sigFromSrams_bore_10_ram_aux_ckbp;
  logic w_sigFromSrams_bore_10_ram_mcp_hold;
  logic w_sigFromSrams_bore_10_cgen;
  logic w_sigFromSrams_bore_11_ram_hold;
  logic w_sigFromSrams_bore_11_ram_bypass;
  logic w_sigFromSrams_bore_11_ram_bp_clken;
  logic w_sigFromSrams_bore_11_ram_aux_clk;
  logic w_sigFromSrams_bore_11_ram_aux_ckbp;
  logic w_sigFromSrams_bore_11_ram_mcp_hold;
  logic w_sigFromSrams_bore_11_cgen;
  logic w_sigFromSrams_bore_12_ram_hold;
  logic w_sigFromSrams_bore_12_ram_bypass;
  logic w_sigFromSrams_bore_12_ram_bp_clken;
  logic w_sigFromSrams_bore_12_ram_aux_clk;
  logic w_sigFromSrams_bore_12_ram_aux_ckbp;
  logic w_sigFromSrams_bore_12_ram_mcp_hold;
  logic w_sigFromSrams_bore_12_cgen;
  logic w_sigFromSrams_bore_13_ram_hold;
  logic w_sigFromSrams_bore_13_ram_bypass;
  logic w_sigFromSrams_bore_13_ram_bp_clken;
  logic w_sigFromSrams_bore_13_ram_aux_clk;
  logic w_sigFromSrams_bore_13_ram_aux_ckbp;
  logic w_sigFromSrams_bore_13_ram_mcp_hold;
  logic w_sigFromSrams_bore_13_cgen;
  logic w_sigFromSrams_bore_14_ram_hold;
  logic w_sigFromSrams_bore_14_ram_bypass;
  logic w_sigFromSrams_bore_14_ram_bp_clken;
  logic w_sigFromSrams_bore_14_ram_aux_clk;
  logic w_sigFromSrams_bore_14_ram_aux_ckbp;
  logic w_sigFromSrams_bore_14_ram_mcp_hold;
  logic w_sigFromSrams_bore_14_cgen;
  logic w_sigFromSrams_bore_15_ram_hold;
  logic w_sigFromSrams_bore_15_ram_bypass;
  logic w_sigFromSrams_bore_15_ram_bp_clken;
  logic w_sigFromSrams_bore_15_ram_aux_clk;
  logic w_sigFromSrams_bore_15_ram_aux_ckbp;
  logic w_sigFromSrams_bore_15_ram_mcp_hold;
  logic w_sigFromSrams_bore_15_cgen;
  logic w_sigFromSrams_bore_16_ram_hold;
  logic w_sigFromSrams_bore_16_ram_bypass;
  logic w_sigFromSrams_bore_16_ram_bp_clken;
  logic w_sigFromSrams_bore_16_ram_aux_clk;
  logic w_sigFromSrams_bore_16_ram_aux_ckbp;
  logic w_sigFromSrams_bore_16_ram_mcp_hold;
  logic w_sigFromSrams_bore_16_cgen;
  logic w_sigFromSrams_bore_17_ram_hold;
  logic w_sigFromSrams_bore_17_ram_bypass;
  logic w_sigFromSrams_bore_17_ram_bp_clken;
  logic w_sigFromSrams_bore_17_ram_aux_clk;
  logic w_sigFromSrams_bore_17_ram_aux_ckbp;
  logic w_sigFromSrams_bore_17_ram_mcp_hold;
  logic w_sigFromSrams_bore_17_cgen;
  logic w_sigFromSrams_bore_18_ram_hold;
  logic w_sigFromSrams_bore_18_ram_bypass;
  logic w_sigFromSrams_bore_18_ram_bp_clken;
  logic w_sigFromSrams_bore_18_ram_aux_clk;
  logic w_sigFromSrams_bore_18_ram_aux_ckbp;
  logic w_sigFromSrams_bore_18_ram_mcp_hold;
  logic w_sigFromSrams_bore_18_cgen;
  logic w_sigFromSrams_bore_19_ram_hold;
  logic w_sigFromSrams_bore_19_ram_bypass;
  logic w_sigFromSrams_bore_19_ram_bp_clken;
  logic w_sigFromSrams_bore_19_ram_aux_clk;
  logic w_sigFromSrams_bore_19_ram_aux_ckbp;
  logic w_sigFromSrams_bore_19_ram_mcp_hold;
  logic w_sigFromSrams_bore_19_cgen;
  logic w_sigFromSrams_bore_20_ram_hold;
  logic w_sigFromSrams_bore_20_ram_bypass;
  logic w_sigFromSrams_bore_20_ram_bp_clken;
  logic w_sigFromSrams_bore_20_ram_aux_clk;
  logic w_sigFromSrams_bore_20_ram_aux_ckbp;
  logic w_sigFromSrams_bore_20_ram_mcp_hold;
  logic w_sigFromSrams_bore_20_cgen;
  logic w_cg_bore_cgen;
  logic w_cg_bore_1_cgen;
  wire  [600:0] w_g_gatewayIn_packed_43_bore, w_i_gatewayIn_packed_43_bore;
  logic [600:0] w_s0_gatewayIn_packed_43_bore = '0, w_s1_gatewayIn_packed_43_bore = '0;
  wire  [968:0] w_g_gatewayIn_packed_44_bore, w_i_gatewayIn_packed_44_bore;
  logic [968:0] w_s0_gatewayIn_packed_44_bore = '0, w_s1_gatewayIn_packed_44_bore = '0;
  wire  [968:0] w_g_gatewayIn_packed_45_bore, w_i_gatewayIn_packed_45_bore;
  logic [968:0] w_s0_gatewayIn_packed_45_bore = '0, w_s1_gatewayIn_packed_45_bore = '0;
  int w_cov_perf_nz = 0;
  int w_cov_ptw_req = 0;
  int w_cov_tlb_resp = 0;
  logic [0:0] w_armed = '0;
  int w_armed_at = -1;
  L2TLBWrapper w_u_gold (
    .clock(clk),
    .reset(w_reset),
    .auto_out_a_ready(w_auto_out_a_ready),
    .auto_out_a_valid(w_g_auto_out_a_valid),
    .auto_out_a_bits_source(w_g_auto_out_a_bits_source),
    .auto_out_a_bits_address(w_g_auto_out_a_bits_address),
    .auto_out_d_valid(w_auto_out_d_valid),
    .auto_out_d_bits_opcode(w_auto_out_d_bits_opcode),
    .auto_out_d_bits_size(w_auto_out_d_bits_size),
    .auto_out_d_bits_source(w_auto_out_d_bits_source),
    .auto_out_d_bits_data(w_auto_out_d_bits_data),
    .io_hartId(w_io_hartId),
    .io_tlb_0_req_0_ready(w_g_io_tlb_0_req_0_ready),
    .io_tlb_0_req_0_valid(w_io_tlb_0_req_0_valid),
    .io_tlb_0_req_0_bits_vpn(w_io_tlb_0_req_0_bits_vpn),
    .io_tlb_0_req_0_bits_s2xlate(w_io_tlb_0_req_0_bits_s2xlate),
    .io_tlb_0_resp_ready(w_io_tlb_0_resp_ready),
    .io_tlb_0_resp_valid(w_g_io_tlb_0_resp_valid),
    .io_tlb_0_resp_bits_s2xlate(w_g_io_tlb_0_resp_bits_s2xlate),
    .io_tlb_0_resp_bits_s1_entry_tag(w_g_io_tlb_0_resp_bits_s1_entry_tag),
    .io_tlb_0_resp_bits_s1_entry_asid(w_g_io_tlb_0_resp_bits_s1_entry_asid),
    .io_tlb_0_resp_bits_s1_entry_vmid(w_g_io_tlb_0_resp_bits_s1_entry_vmid),
    .io_tlb_0_resp_bits_s1_entry_n(w_g_io_tlb_0_resp_bits_s1_entry_n),
    .io_tlb_0_resp_bits_s1_entry_pbmt(w_g_io_tlb_0_resp_bits_s1_entry_pbmt),
    .io_tlb_0_resp_bits_s1_entry_perm_d(w_g_io_tlb_0_resp_bits_s1_entry_perm_d),
    .io_tlb_0_resp_bits_s1_entry_perm_a(w_g_io_tlb_0_resp_bits_s1_entry_perm_a),
    .io_tlb_0_resp_bits_s1_entry_perm_g(w_g_io_tlb_0_resp_bits_s1_entry_perm_g),
    .io_tlb_0_resp_bits_s1_entry_perm_u(w_g_io_tlb_0_resp_bits_s1_entry_perm_u),
    .io_tlb_0_resp_bits_s1_entry_perm_x(w_g_io_tlb_0_resp_bits_s1_entry_perm_x),
    .io_tlb_0_resp_bits_s1_entry_perm_w(w_g_io_tlb_0_resp_bits_s1_entry_perm_w),
    .io_tlb_0_resp_bits_s1_entry_perm_r(w_g_io_tlb_0_resp_bits_s1_entry_perm_r),
    .io_tlb_0_resp_bits_s1_entry_level(w_g_io_tlb_0_resp_bits_s1_entry_level),
    .io_tlb_0_resp_bits_s1_entry_v(w_g_io_tlb_0_resp_bits_s1_entry_v),
    .io_tlb_0_resp_bits_s1_entry_ppn(w_g_io_tlb_0_resp_bits_s1_entry_ppn),
    .io_tlb_0_resp_bits_s1_addr_low(w_g_io_tlb_0_resp_bits_s1_addr_low),
    .io_tlb_0_resp_bits_s1_ppn_low_0(w_g_io_tlb_0_resp_bits_s1_ppn_low_0),
    .io_tlb_0_resp_bits_s1_ppn_low_1(w_g_io_tlb_0_resp_bits_s1_ppn_low_1),
    .io_tlb_0_resp_bits_s1_ppn_low_2(w_g_io_tlb_0_resp_bits_s1_ppn_low_2),
    .io_tlb_0_resp_bits_s1_ppn_low_3(w_g_io_tlb_0_resp_bits_s1_ppn_low_3),
    .io_tlb_0_resp_bits_s1_ppn_low_4(w_g_io_tlb_0_resp_bits_s1_ppn_low_4),
    .io_tlb_0_resp_bits_s1_ppn_low_5(w_g_io_tlb_0_resp_bits_s1_ppn_low_5),
    .io_tlb_0_resp_bits_s1_ppn_low_6(w_g_io_tlb_0_resp_bits_s1_ppn_low_6),
    .io_tlb_0_resp_bits_s1_ppn_low_7(w_g_io_tlb_0_resp_bits_s1_ppn_low_7),
    .io_tlb_0_resp_bits_s1_valididx_0(w_g_io_tlb_0_resp_bits_s1_valididx_0),
    .io_tlb_0_resp_bits_s1_valididx_1(w_g_io_tlb_0_resp_bits_s1_valididx_1),
    .io_tlb_0_resp_bits_s1_valididx_2(w_g_io_tlb_0_resp_bits_s1_valididx_2),
    .io_tlb_0_resp_bits_s1_valididx_3(w_g_io_tlb_0_resp_bits_s1_valididx_3),
    .io_tlb_0_resp_bits_s1_valididx_4(w_g_io_tlb_0_resp_bits_s1_valididx_4),
    .io_tlb_0_resp_bits_s1_valididx_5(w_g_io_tlb_0_resp_bits_s1_valididx_5),
    .io_tlb_0_resp_bits_s1_valididx_6(w_g_io_tlb_0_resp_bits_s1_valididx_6),
    .io_tlb_0_resp_bits_s1_valididx_7(w_g_io_tlb_0_resp_bits_s1_valididx_7),
    .io_tlb_0_resp_bits_s1_pteidx_0(w_g_io_tlb_0_resp_bits_s1_pteidx_0),
    .io_tlb_0_resp_bits_s1_pteidx_1(w_g_io_tlb_0_resp_bits_s1_pteidx_1),
    .io_tlb_0_resp_bits_s1_pteidx_2(w_g_io_tlb_0_resp_bits_s1_pteidx_2),
    .io_tlb_0_resp_bits_s1_pteidx_3(w_g_io_tlb_0_resp_bits_s1_pteidx_3),
    .io_tlb_0_resp_bits_s1_pteidx_4(w_g_io_tlb_0_resp_bits_s1_pteidx_4),
    .io_tlb_0_resp_bits_s1_pteidx_5(w_g_io_tlb_0_resp_bits_s1_pteidx_5),
    .io_tlb_0_resp_bits_s1_pteidx_6(w_g_io_tlb_0_resp_bits_s1_pteidx_6),
    .io_tlb_0_resp_bits_s1_pteidx_7(w_g_io_tlb_0_resp_bits_s1_pteidx_7),
    .io_tlb_0_resp_bits_s1_pf(w_g_io_tlb_0_resp_bits_s1_pf),
    .io_tlb_0_resp_bits_s1_af(w_g_io_tlb_0_resp_bits_s1_af),
    .io_tlb_0_resp_bits_s2_entry_tag(w_g_io_tlb_0_resp_bits_s2_entry_tag),
    .io_tlb_0_resp_bits_s2_entry_vmid(w_g_io_tlb_0_resp_bits_s2_entry_vmid),
    .io_tlb_0_resp_bits_s2_entry_n(w_g_io_tlb_0_resp_bits_s2_entry_n),
    .io_tlb_0_resp_bits_s2_entry_pbmt(w_g_io_tlb_0_resp_bits_s2_entry_pbmt),
    .io_tlb_0_resp_bits_s2_entry_ppn(w_g_io_tlb_0_resp_bits_s2_entry_ppn),
    .io_tlb_0_resp_bits_s2_entry_perm_d(w_g_io_tlb_0_resp_bits_s2_entry_perm_d),
    .io_tlb_0_resp_bits_s2_entry_perm_a(w_g_io_tlb_0_resp_bits_s2_entry_perm_a),
    .io_tlb_0_resp_bits_s2_entry_perm_g(w_g_io_tlb_0_resp_bits_s2_entry_perm_g),
    .io_tlb_0_resp_bits_s2_entry_perm_u(w_g_io_tlb_0_resp_bits_s2_entry_perm_u),
    .io_tlb_0_resp_bits_s2_entry_perm_x(w_g_io_tlb_0_resp_bits_s2_entry_perm_x),
    .io_tlb_0_resp_bits_s2_entry_perm_w(w_g_io_tlb_0_resp_bits_s2_entry_perm_w),
    .io_tlb_0_resp_bits_s2_entry_perm_r(w_g_io_tlb_0_resp_bits_s2_entry_perm_r),
    .io_tlb_0_resp_bits_s2_entry_level(w_g_io_tlb_0_resp_bits_s2_entry_level),
    .io_tlb_0_resp_bits_s2_gpf(w_g_io_tlb_0_resp_bits_s2_gpf),
    .io_tlb_0_resp_bits_s2_gaf(w_g_io_tlb_0_resp_bits_s2_gaf),
    .io_tlb_1_req_0_ready(w_g_io_tlb_1_req_0_ready),
    .io_tlb_1_req_0_valid(w_io_tlb_1_req_0_valid),
    .io_tlb_1_req_0_bits_vpn(w_io_tlb_1_req_0_bits_vpn),
    .io_tlb_1_req_0_bits_s2xlate(w_io_tlb_1_req_0_bits_s2xlate),
    .io_tlb_1_resp_valid(w_g_io_tlb_1_resp_valid),
    .io_tlb_1_resp_bits_s2xlate(w_g_io_tlb_1_resp_bits_s2xlate),
    .io_tlb_1_resp_bits_s1_entry_tag(w_g_io_tlb_1_resp_bits_s1_entry_tag),
    .io_tlb_1_resp_bits_s1_entry_asid(w_g_io_tlb_1_resp_bits_s1_entry_asid),
    .io_tlb_1_resp_bits_s1_entry_vmid(w_g_io_tlb_1_resp_bits_s1_entry_vmid),
    .io_tlb_1_resp_bits_s1_entry_n(w_g_io_tlb_1_resp_bits_s1_entry_n),
    .io_tlb_1_resp_bits_s1_entry_pbmt(w_g_io_tlb_1_resp_bits_s1_entry_pbmt),
    .io_tlb_1_resp_bits_s1_entry_perm_d(w_g_io_tlb_1_resp_bits_s1_entry_perm_d),
    .io_tlb_1_resp_bits_s1_entry_perm_a(w_g_io_tlb_1_resp_bits_s1_entry_perm_a),
    .io_tlb_1_resp_bits_s1_entry_perm_g(w_g_io_tlb_1_resp_bits_s1_entry_perm_g),
    .io_tlb_1_resp_bits_s1_entry_perm_u(w_g_io_tlb_1_resp_bits_s1_entry_perm_u),
    .io_tlb_1_resp_bits_s1_entry_perm_x(w_g_io_tlb_1_resp_bits_s1_entry_perm_x),
    .io_tlb_1_resp_bits_s1_entry_perm_w(w_g_io_tlb_1_resp_bits_s1_entry_perm_w),
    .io_tlb_1_resp_bits_s1_entry_perm_r(w_g_io_tlb_1_resp_bits_s1_entry_perm_r),
    .io_tlb_1_resp_bits_s1_entry_level(w_g_io_tlb_1_resp_bits_s1_entry_level),
    .io_tlb_1_resp_bits_s1_entry_v(w_g_io_tlb_1_resp_bits_s1_entry_v),
    .io_tlb_1_resp_bits_s1_entry_ppn(w_g_io_tlb_1_resp_bits_s1_entry_ppn),
    .io_tlb_1_resp_bits_s1_addr_low(w_g_io_tlb_1_resp_bits_s1_addr_low),
    .io_tlb_1_resp_bits_s1_ppn_low_0(w_g_io_tlb_1_resp_bits_s1_ppn_low_0),
    .io_tlb_1_resp_bits_s1_ppn_low_1(w_g_io_tlb_1_resp_bits_s1_ppn_low_1),
    .io_tlb_1_resp_bits_s1_ppn_low_2(w_g_io_tlb_1_resp_bits_s1_ppn_low_2),
    .io_tlb_1_resp_bits_s1_ppn_low_3(w_g_io_tlb_1_resp_bits_s1_ppn_low_3),
    .io_tlb_1_resp_bits_s1_ppn_low_4(w_g_io_tlb_1_resp_bits_s1_ppn_low_4),
    .io_tlb_1_resp_bits_s1_ppn_low_5(w_g_io_tlb_1_resp_bits_s1_ppn_low_5),
    .io_tlb_1_resp_bits_s1_ppn_low_6(w_g_io_tlb_1_resp_bits_s1_ppn_low_6),
    .io_tlb_1_resp_bits_s1_ppn_low_7(w_g_io_tlb_1_resp_bits_s1_ppn_low_7),
    .io_tlb_1_resp_bits_s1_valididx_0(w_g_io_tlb_1_resp_bits_s1_valididx_0),
    .io_tlb_1_resp_bits_s1_valididx_1(w_g_io_tlb_1_resp_bits_s1_valididx_1),
    .io_tlb_1_resp_bits_s1_valididx_2(w_g_io_tlb_1_resp_bits_s1_valididx_2),
    .io_tlb_1_resp_bits_s1_valididx_3(w_g_io_tlb_1_resp_bits_s1_valididx_3),
    .io_tlb_1_resp_bits_s1_valididx_4(w_g_io_tlb_1_resp_bits_s1_valididx_4),
    .io_tlb_1_resp_bits_s1_valididx_5(w_g_io_tlb_1_resp_bits_s1_valididx_5),
    .io_tlb_1_resp_bits_s1_valididx_6(w_g_io_tlb_1_resp_bits_s1_valididx_6),
    .io_tlb_1_resp_bits_s1_valididx_7(w_g_io_tlb_1_resp_bits_s1_valididx_7),
    .io_tlb_1_resp_bits_s1_pteidx_0(w_g_io_tlb_1_resp_bits_s1_pteidx_0),
    .io_tlb_1_resp_bits_s1_pteidx_1(w_g_io_tlb_1_resp_bits_s1_pteidx_1),
    .io_tlb_1_resp_bits_s1_pteidx_2(w_g_io_tlb_1_resp_bits_s1_pteidx_2),
    .io_tlb_1_resp_bits_s1_pteidx_3(w_g_io_tlb_1_resp_bits_s1_pteidx_3),
    .io_tlb_1_resp_bits_s1_pteidx_4(w_g_io_tlb_1_resp_bits_s1_pteidx_4),
    .io_tlb_1_resp_bits_s1_pteidx_5(w_g_io_tlb_1_resp_bits_s1_pteidx_5),
    .io_tlb_1_resp_bits_s1_pteidx_6(w_g_io_tlb_1_resp_bits_s1_pteidx_6),
    .io_tlb_1_resp_bits_s1_pteidx_7(w_g_io_tlb_1_resp_bits_s1_pteidx_7),
    .io_tlb_1_resp_bits_s1_pf(w_g_io_tlb_1_resp_bits_s1_pf),
    .io_tlb_1_resp_bits_s1_af(w_g_io_tlb_1_resp_bits_s1_af),
    .io_tlb_1_resp_bits_s2_entry_tag(w_g_io_tlb_1_resp_bits_s2_entry_tag),
    .io_tlb_1_resp_bits_s2_entry_vmid(w_g_io_tlb_1_resp_bits_s2_entry_vmid),
    .io_tlb_1_resp_bits_s2_entry_n(w_g_io_tlb_1_resp_bits_s2_entry_n),
    .io_tlb_1_resp_bits_s2_entry_pbmt(w_g_io_tlb_1_resp_bits_s2_entry_pbmt),
    .io_tlb_1_resp_bits_s2_entry_ppn(w_g_io_tlb_1_resp_bits_s2_entry_ppn),
    .io_tlb_1_resp_bits_s2_entry_perm_d(w_g_io_tlb_1_resp_bits_s2_entry_perm_d),
    .io_tlb_1_resp_bits_s2_entry_perm_a(w_g_io_tlb_1_resp_bits_s2_entry_perm_a),
    .io_tlb_1_resp_bits_s2_entry_perm_g(w_g_io_tlb_1_resp_bits_s2_entry_perm_g),
    .io_tlb_1_resp_bits_s2_entry_perm_u(w_g_io_tlb_1_resp_bits_s2_entry_perm_u),
    .io_tlb_1_resp_bits_s2_entry_perm_x(w_g_io_tlb_1_resp_bits_s2_entry_perm_x),
    .io_tlb_1_resp_bits_s2_entry_perm_w(w_g_io_tlb_1_resp_bits_s2_entry_perm_w),
    .io_tlb_1_resp_bits_s2_entry_perm_r(w_g_io_tlb_1_resp_bits_s2_entry_perm_r),
    .io_tlb_1_resp_bits_s2_entry_level(w_g_io_tlb_1_resp_bits_s2_entry_level),
    .io_tlb_1_resp_bits_s2_gpf(w_g_io_tlb_1_resp_bits_s2_gpf),
    .io_tlb_1_resp_bits_s2_gaf(w_g_io_tlb_1_resp_bits_s2_gaf),
    .io_sfence_valid(w_io_sfence_valid),
    .io_sfence_bits_rs1(w_io_sfence_bits_rs1),
    .io_sfence_bits_rs2(w_io_sfence_bits_rs2),
    .io_sfence_bits_addr(w_io_sfence_bits_addr),
    .io_sfence_bits_id(w_io_sfence_bits_id),
    .io_sfence_bits_hv(w_io_sfence_bits_hv),
    .io_sfence_bits_hg(w_io_sfence_bits_hg),
    .io_wfi_wfiReq(w_io_wfi_wfiReq),
    .io_wfi_wfiSafe(w_g_io_wfi_wfiSafe),
    .io_csr_tlb_satp_mode(w_io_csr_tlb_satp_mode),
    .io_csr_tlb_satp_asid(w_io_csr_tlb_satp_asid),
    .io_csr_tlb_satp_ppn(w_io_csr_tlb_satp_ppn),
    .io_csr_tlb_satp_changed(w_io_csr_tlb_satp_changed),
    .io_csr_tlb_vsatp_mode(w_io_csr_tlb_vsatp_mode),
    .io_csr_tlb_vsatp_asid(w_io_csr_tlb_vsatp_asid),
    .io_csr_tlb_vsatp_ppn(w_io_csr_tlb_vsatp_ppn),
    .io_csr_tlb_vsatp_changed(w_io_csr_tlb_vsatp_changed),
    .io_csr_tlb_hgatp_mode(w_io_csr_tlb_hgatp_mode),
    .io_csr_tlb_hgatp_vmid(w_io_csr_tlb_hgatp_vmid),
    .io_csr_tlb_hgatp_ppn(w_io_csr_tlb_hgatp_ppn),
    .io_csr_tlb_hgatp_changed(w_io_csr_tlb_hgatp_changed),
    .io_csr_tlb_mbmc_BME(w_io_csr_tlb_mbmc_BME),
    .io_csr_tlb_mbmc_CMODE(w_io_csr_tlb_mbmc_CMODE),
    .io_csr_tlb_mbmc_BCLEAR(w_io_csr_tlb_mbmc_BCLEAR),
    .io_csr_tlb_mbmc_BMA(w_io_csr_tlb_mbmc_BMA),
    .io_csr_tlb_priv_virt(w_io_csr_tlb_priv_virt),
    .io_csr_tlb_priv_virt_changed(w_io_csr_tlb_priv_virt_changed),
    .io_csr_tlb_priv_debug(w_io_csr_tlb_priv_debug),
    .io_csr_tlb_mPBMTE(w_io_csr_tlb_mPBMTE),
    .io_csr_tlb_hPBMTE(w_io_csr_tlb_hPBMTE),
    .io_csr_distribute_csr_w_valid(w_io_csr_distribute_csr_w_valid),
    .io_csr_distribute_csr_w_bits_addr(w_io_csr_distribute_csr_w_bits_addr),
    .io_csr_distribute_csr_w_bits_data(w_io_csr_distribute_csr_w_bits_data),
    .io_perf_0_value(w_g_io_perf_0_value),
    .io_perf_1_value(w_g_io_perf_1_value),
    .io_perf_2_value(w_g_io_perf_2_value),
    .io_perf_3_value(w_g_io_perf_3_value),
    .io_perf_4_value(w_g_io_perf_4_value),
    .io_perf_5_value(w_g_io_perf_5_value),
    .io_perf_6_value(w_g_io_perf_6_value),
    .io_perf_7_value(w_g_io_perf_7_value),
    .io_perf_8_value(w_g_io_perf_8_value),
    .io_perf_9_value(w_g_io_perf_9_value),
    .io_perf_10_value(w_g_io_perf_10_value),
    .io_perf_11_value(w_g_io_perf_11_value),
    .io_perf_12_value(w_g_io_perf_12_value),
    .io_perf_13_value(w_g_io_perf_13_value),
    .io_perf_14_value(w_g_io_perf_14_value),
    .io_perf_15_value(w_g_io_perf_15_value),
    .io_perf_16_value(w_g_io_perf_16_value),
    .io_perf_17_value(w_g_io_perf_17_value),
    .io_perf_18_value(w_g_io_perf_18_value),
    .boreChildrenBd_bore_array(w_boreChildrenBd_bore_array),
    .boreChildrenBd_bore_all(w_boreChildrenBd_bore_all),
    .boreChildrenBd_bore_req(w_boreChildrenBd_bore_req),
    .boreChildrenBd_bore_ack(w_g_boreChildrenBd_bore_ack),
    .boreChildrenBd_bore_writeen(w_boreChildrenBd_bore_writeen),
    .boreChildrenBd_bore_be(w_boreChildrenBd_bore_be),
    .boreChildrenBd_bore_addr(w_boreChildrenBd_bore_addr),
    .boreChildrenBd_bore_indata(w_boreChildrenBd_bore_indata),
    .boreChildrenBd_bore_readen(w_boreChildrenBd_bore_readen),
    .boreChildrenBd_bore_addr_rd(w_boreChildrenBd_bore_addr_rd),
    .boreChildrenBd_bore_outdata(w_g_boreChildrenBd_bore_outdata),
    .boreChildrenBd_bore_1_array(w_boreChildrenBd_bore_1_array),
    .boreChildrenBd_bore_1_all(w_boreChildrenBd_bore_1_all),
    .boreChildrenBd_bore_1_req(w_boreChildrenBd_bore_1_req),
    .boreChildrenBd_bore_1_ack(w_g_boreChildrenBd_bore_1_ack),
    .boreChildrenBd_bore_1_writeen(w_boreChildrenBd_bore_1_writeen),
    .boreChildrenBd_bore_1_be(w_boreChildrenBd_bore_1_be),
    .boreChildrenBd_bore_1_addr(w_boreChildrenBd_bore_1_addr),
    .boreChildrenBd_bore_1_indata(w_boreChildrenBd_bore_1_indata),
    .boreChildrenBd_bore_1_readen(w_boreChildrenBd_bore_1_readen),
    .boreChildrenBd_bore_1_addr_rd(w_boreChildrenBd_bore_1_addr_rd),
    .boreChildrenBd_bore_1_outdata(w_g_boreChildrenBd_bore_1_outdata),
    .boreChildrenBd_bore_2_array(w_boreChildrenBd_bore_2_array),
    .boreChildrenBd_bore_2_all(w_boreChildrenBd_bore_2_all),
    .boreChildrenBd_bore_2_req(w_boreChildrenBd_bore_2_req),
    .boreChildrenBd_bore_2_ack(w_g_boreChildrenBd_bore_2_ack),
    .boreChildrenBd_bore_2_writeen(w_boreChildrenBd_bore_2_writeen),
    .boreChildrenBd_bore_2_be(w_boreChildrenBd_bore_2_be),
    .boreChildrenBd_bore_2_addr(w_boreChildrenBd_bore_2_addr),
    .boreChildrenBd_bore_2_indata(w_boreChildrenBd_bore_2_indata),
    .boreChildrenBd_bore_2_readen(w_boreChildrenBd_bore_2_readen),
    .boreChildrenBd_bore_2_addr_rd(w_boreChildrenBd_bore_2_addr_rd),
    .boreChildrenBd_bore_2_outdata(w_g_boreChildrenBd_bore_2_outdata),
    .sigFromSrams_bore_ram_hold(w_sigFromSrams_bore_ram_hold),
    .sigFromSrams_bore_ram_bypass(w_sigFromSrams_bore_ram_bypass),
    .sigFromSrams_bore_ram_bp_clken(w_sigFromSrams_bore_ram_bp_clken),
    .sigFromSrams_bore_ram_aux_clk(w_sigFromSrams_bore_ram_aux_clk),
    .sigFromSrams_bore_ram_aux_ckbp(w_sigFromSrams_bore_ram_aux_ckbp),
    .sigFromSrams_bore_ram_mcp_hold(w_sigFromSrams_bore_ram_mcp_hold),
    .sigFromSrams_bore_cgen(w_sigFromSrams_bore_cgen),
    .sigFromSrams_bore_1_ram_hold(w_sigFromSrams_bore_1_ram_hold),
    .sigFromSrams_bore_1_ram_bypass(w_sigFromSrams_bore_1_ram_bypass),
    .sigFromSrams_bore_1_ram_bp_clken(w_sigFromSrams_bore_1_ram_bp_clken),
    .sigFromSrams_bore_1_ram_aux_clk(w_sigFromSrams_bore_1_ram_aux_clk),
    .sigFromSrams_bore_1_ram_aux_ckbp(w_sigFromSrams_bore_1_ram_aux_ckbp),
    .sigFromSrams_bore_1_ram_mcp_hold(w_sigFromSrams_bore_1_ram_mcp_hold),
    .sigFromSrams_bore_1_cgen(w_sigFromSrams_bore_1_cgen),
    .sigFromSrams_bore_2_ram_hold(w_sigFromSrams_bore_2_ram_hold),
    .sigFromSrams_bore_2_ram_bypass(w_sigFromSrams_bore_2_ram_bypass),
    .sigFromSrams_bore_2_ram_bp_clken(w_sigFromSrams_bore_2_ram_bp_clken),
    .sigFromSrams_bore_2_ram_aux_clk(w_sigFromSrams_bore_2_ram_aux_clk),
    .sigFromSrams_bore_2_ram_aux_ckbp(w_sigFromSrams_bore_2_ram_aux_ckbp),
    .sigFromSrams_bore_2_ram_mcp_hold(w_sigFromSrams_bore_2_ram_mcp_hold),
    .sigFromSrams_bore_2_cgen(w_sigFromSrams_bore_2_cgen),
    .sigFromSrams_bore_3_ram_hold(w_sigFromSrams_bore_3_ram_hold),
    .sigFromSrams_bore_3_ram_bypass(w_sigFromSrams_bore_3_ram_bypass),
    .sigFromSrams_bore_3_ram_bp_clken(w_sigFromSrams_bore_3_ram_bp_clken),
    .sigFromSrams_bore_3_ram_aux_clk(w_sigFromSrams_bore_3_ram_aux_clk),
    .sigFromSrams_bore_3_ram_aux_ckbp(w_sigFromSrams_bore_3_ram_aux_ckbp),
    .sigFromSrams_bore_3_ram_mcp_hold(w_sigFromSrams_bore_3_ram_mcp_hold),
    .sigFromSrams_bore_3_cgen(w_sigFromSrams_bore_3_cgen),
    .sigFromSrams_bore_4_ram_hold(w_sigFromSrams_bore_4_ram_hold),
    .sigFromSrams_bore_4_ram_bypass(w_sigFromSrams_bore_4_ram_bypass),
    .sigFromSrams_bore_4_ram_bp_clken(w_sigFromSrams_bore_4_ram_bp_clken),
    .sigFromSrams_bore_4_ram_aux_clk(w_sigFromSrams_bore_4_ram_aux_clk),
    .sigFromSrams_bore_4_ram_aux_ckbp(w_sigFromSrams_bore_4_ram_aux_ckbp),
    .sigFromSrams_bore_4_ram_mcp_hold(w_sigFromSrams_bore_4_ram_mcp_hold),
    .sigFromSrams_bore_4_cgen(w_sigFromSrams_bore_4_cgen),
    .sigFromSrams_bore_5_ram_hold(w_sigFromSrams_bore_5_ram_hold),
    .sigFromSrams_bore_5_ram_bypass(w_sigFromSrams_bore_5_ram_bypass),
    .sigFromSrams_bore_5_ram_bp_clken(w_sigFromSrams_bore_5_ram_bp_clken),
    .sigFromSrams_bore_5_ram_aux_clk(w_sigFromSrams_bore_5_ram_aux_clk),
    .sigFromSrams_bore_5_ram_aux_ckbp(w_sigFromSrams_bore_5_ram_aux_ckbp),
    .sigFromSrams_bore_5_ram_mcp_hold(w_sigFromSrams_bore_5_ram_mcp_hold),
    .sigFromSrams_bore_5_cgen(w_sigFromSrams_bore_5_cgen),
    .sigFromSrams_bore_6_ram_hold(w_sigFromSrams_bore_6_ram_hold),
    .sigFromSrams_bore_6_ram_bypass(w_sigFromSrams_bore_6_ram_bypass),
    .sigFromSrams_bore_6_ram_bp_clken(w_sigFromSrams_bore_6_ram_bp_clken),
    .sigFromSrams_bore_6_ram_aux_clk(w_sigFromSrams_bore_6_ram_aux_clk),
    .sigFromSrams_bore_6_ram_aux_ckbp(w_sigFromSrams_bore_6_ram_aux_ckbp),
    .sigFromSrams_bore_6_ram_mcp_hold(w_sigFromSrams_bore_6_ram_mcp_hold),
    .sigFromSrams_bore_6_cgen(w_sigFromSrams_bore_6_cgen),
    .sigFromSrams_bore_7_ram_hold(w_sigFromSrams_bore_7_ram_hold),
    .sigFromSrams_bore_7_ram_bypass(w_sigFromSrams_bore_7_ram_bypass),
    .sigFromSrams_bore_7_ram_bp_clken(w_sigFromSrams_bore_7_ram_bp_clken),
    .sigFromSrams_bore_7_ram_aux_clk(w_sigFromSrams_bore_7_ram_aux_clk),
    .sigFromSrams_bore_7_ram_aux_ckbp(w_sigFromSrams_bore_7_ram_aux_ckbp),
    .sigFromSrams_bore_7_ram_mcp_hold(w_sigFromSrams_bore_7_ram_mcp_hold),
    .sigFromSrams_bore_7_cgen(w_sigFromSrams_bore_7_cgen),
    .sigFromSrams_bore_8_ram_hold(w_sigFromSrams_bore_8_ram_hold),
    .sigFromSrams_bore_8_ram_bypass(w_sigFromSrams_bore_8_ram_bypass),
    .sigFromSrams_bore_8_ram_bp_clken(w_sigFromSrams_bore_8_ram_bp_clken),
    .sigFromSrams_bore_8_ram_aux_clk(w_sigFromSrams_bore_8_ram_aux_clk),
    .sigFromSrams_bore_8_ram_aux_ckbp(w_sigFromSrams_bore_8_ram_aux_ckbp),
    .sigFromSrams_bore_8_ram_mcp_hold(w_sigFromSrams_bore_8_ram_mcp_hold),
    .sigFromSrams_bore_8_cgen(w_sigFromSrams_bore_8_cgen),
    .sigFromSrams_bore_9_ram_hold(w_sigFromSrams_bore_9_ram_hold),
    .sigFromSrams_bore_9_ram_bypass(w_sigFromSrams_bore_9_ram_bypass),
    .sigFromSrams_bore_9_ram_bp_clken(w_sigFromSrams_bore_9_ram_bp_clken),
    .sigFromSrams_bore_9_ram_aux_clk(w_sigFromSrams_bore_9_ram_aux_clk),
    .sigFromSrams_bore_9_ram_aux_ckbp(w_sigFromSrams_bore_9_ram_aux_ckbp),
    .sigFromSrams_bore_9_ram_mcp_hold(w_sigFromSrams_bore_9_ram_mcp_hold),
    .sigFromSrams_bore_9_cgen(w_sigFromSrams_bore_9_cgen),
    .sigFromSrams_bore_10_ram_hold(w_sigFromSrams_bore_10_ram_hold),
    .sigFromSrams_bore_10_ram_bypass(w_sigFromSrams_bore_10_ram_bypass),
    .sigFromSrams_bore_10_ram_bp_clken(w_sigFromSrams_bore_10_ram_bp_clken),
    .sigFromSrams_bore_10_ram_aux_clk(w_sigFromSrams_bore_10_ram_aux_clk),
    .sigFromSrams_bore_10_ram_aux_ckbp(w_sigFromSrams_bore_10_ram_aux_ckbp),
    .sigFromSrams_bore_10_ram_mcp_hold(w_sigFromSrams_bore_10_ram_mcp_hold),
    .sigFromSrams_bore_10_cgen(w_sigFromSrams_bore_10_cgen),
    .sigFromSrams_bore_11_ram_hold(w_sigFromSrams_bore_11_ram_hold),
    .sigFromSrams_bore_11_ram_bypass(w_sigFromSrams_bore_11_ram_bypass),
    .sigFromSrams_bore_11_ram_bp_clken(w_sigFromSrams_bore_11_ram_bp_clken),
    .sigFromSrams_bore_11_ram_aux_clk(w_sigFromSrams_bore_11_ram_aux_clk),
    .sigFromSrams_bore_11_ram_aux_ckbp(w_sigFromSrams_bore_11_ram_aux_ckbp),
    .sigFromSrams_bore_11_ram_mcp_hold(w_sigFromSrams_bore_11_ram_mcp_hold),
    .sigFromSrams_bore_11_cgen(w_sigFromSrams_bore_11_cgen),
    .sigFromSrams_bore_12_ram_hold(w_sigFromSrams_bore_12_ram_hold),
    .sigFromSrams_bore_12_ram_bypass(w_sigFromSrams_bore_12_ram_bypass),
    .sigFromSrams_bore_12_ram_bp_clken(w_sigFromSrams_bore_12_ram_bp_clken),
    .sigFromSrams_bore_12_ram_aux_clk(w_sigFromSrams_bore_12_ram_aux_clk),
    .sigFromSrams_bore_12_ram_aux_ckbp(w_sigFromSrams_bore_12_ram_aux_ckbp),
    .sigFromSrams_bore_12_ram_mcp_hold(w_sigFromSrams_bore_12_ram_mcp_hold),
    .sigFromSrams_bore_12_cgen(w_sigFromSrams_bore_12_cgen),
    .sigFromSrams_bore_13_ram_hold(w_sigFromSrams_bore_13_ram_hold),
    .sigFromSrams_bore_13_ram_bypass(w_sigFromSrams_bore_13_ram_bypass),
    .sigFromSrams_bore_13_ram_bp_clken(w_sigFromSrams_bore_13_ram_bp_clken),
    .sigFromSrams_bore_13_ram_aux_clk(w_sigFromSrams_bore_13_ram_aux_clk),
    .sigFromSrams_bore_13_ram_aux_ckbp(w_sigFromSrams_bore_13_ram_aux_ckbp),
    .sigFromSrams_bore_13_ram_mcp_hold(w_sigFromSrams_bore_13_ram_mcp_hold),
    .sigFromSrams_bore_13_cgen(w_sigFromSrams_bore_13_cgen),
    .sigFromSrams_bore_14_ram_hold(w_sigFromSrams_bore_14_ram_hold),
    .sigFromSrams_bore_14_ram_bypass(w_sigFromSrams_bore_14_ram_bypass),
    .sigFromSrams_bore_14_ram_bp_clken(w_sigFromSrams_bore_14_ram_bp_clken),
    .sigFromSrams_bore_14_ram_aux_clk(w_sigFromSrams_bore_14_ram_aux_clk),
    .sigFromSrams_bore_14_ram_aux_ckbp(w_sigFromSrams_bore_14_ram_aux_ckbp),
    .sigFromSrams_bore_14_ram_mcp_hold(w_sigFromSrams_bore_14_ram_mcp_hold),
    .sigFromSrams_bore_14_cgen(w_sigFromSrams_bore_14_cgen),
    .sigFromSrams_bore_15_ram_hold(w_sigFromSrams_bore_15_ram_hold),
    .sigFromSrams_bore_15_ram_bypass(w_sigFromSrams_bore_15_ram_bypass),
    .sigFromSrams_bore_15_ram_bp_clken(w_sigFromSrams_bore_15_ram_bp_clken),
    .sigFromSrams_bore_15_ram_aux_clk(w_sigFromSrams_bore_15_ram_aux_clk),
    .sigFromSrams_bore_15_ram_aux_ckbp(w_sigFromSrams_bore_15_ram_aux_ckbp),
    .sigFromSrams_bore_15_ram_mcp_hold(w_sigFromSrams_bore_15_ram_mcp_hold),
    .sigFromSrams_bore_15_cgen(w_sigFromSrams_bore_15_cgen),
    .sigFromSrams_bore_16_ram_hold(w_sigFromSrams_bore_16_ram_hold),
    .sigFromSrams_bore_16_ram_bypass(w_sigFromSrams_bore_16_ram_bypass),
    .sigFromSrams_bore_16_ram_bp_clken(w_sigFromSrams_bore_16_ram_bp_clken),
    .sigFromSrams_bore_16_ram_aux_clk(w_sigFromSrams_bore_16_ram_aux_clk),
    .sigFromSrams_bore_16_ram_aux_ckbp(w_sigFromSrams_bore_16_ram_aux_ckbp),
    .sigFromSrams_bore_16_ram_mcp_hold(w_sigFromSrams_bore_16_ram_mcp_hold),
    .sigFromSrams_bore_16_cgen(w_sigFromSrams_bore_16_cgen),
    .sigFromSrams_bore_17_ram_hold(w_sigFromSrams_bore_17_ram_hold),
    .sigFromSrams_bore_17_ram_bypass(w_sigFromSrams_bore_17_ram_bypass),
    .sigFromSrams_bore_17_ram_bp_clken(w_sigFromSrams_bore_17_ram_bp_clken),
    .sigFromSrams_bore_17_ram_aux_clk(w_sigFromSrams_bore_17_ram_aux_clk),
    .sigFromSrams_bore_17_ram_aux_ckbp(w_sigFromSrams_bore_17_ram_aux_ckbp),
    .sigFromSrams_bore_17_ram_mcp_hold(w_sigFromSrams_bore_17_ram_mcp_hold),
    .sigFromSrams_bore_17_cgen(w_sigFromSrams_bore_17_cgen),
    .sigFromSrams_bore_18_ram_hold(w_sigFromSrams_bore_18_ram_hold),
    .sigFromSrams_bore_18_ram_bypass(w_sigFromSrams_bore_18_ram_bypass),
    .sigFromSrams_bore_18_ram_bp_clken(w_sigFromSrams_bore_18_ram_bp_clken),
    .sigFromSrams_bore_18_ram_aux_clk(w_sigFromSrams_bore_18_ram_aux_clk),
    .sigFromSrams_bore_18_ram_aux_ckbp(w_sigFromSrams_bore_18_ram_aux_ckbp),
    .sigFromSrams_bore_18_ram_mcp_hold(w_sigFromSrams_bore_18_ram_mcp_hold),
    .sigFromSrams_bore_18_cgen(w_sigFromSrams_bore_18_cgen),
    .sigFromSrams_bore_19_ram_hold(w_sigFromSrams_bore_19_ram_hold),
    .sigFromSrams_bore_19_ram_bypass(w_sigFromSrams_bore_19_ram_bypass),
    .sigFromSrams_bore_19_ram_bp_clken(w_sigFromSrams_bore_19_ram_bp_clken),
    .sigFromSrams_bore_19_ram_aux_clk(w_sigFromSrams_bore_19_ram_aux_clk),
    .sigFromSrams_bore_19_ram_aux_ckbp(w_sigFromSrams_bore_19_ram_aux_ckbp),
    .sigFromSrams_bore_19_ram_mcp_hold(w_sigFromSrams_bore_19_ram_mcp_hold),
    .sigFromSrams_bore_19_cgen(w_sigFromSrams_bore_19_cgen),
    .sigFromSrams_bore_20_ram_hold(w_sigFromSrams_bore_20_ram_hold),
    .sigFromSrams_bore_20_ram_bypass(w_sigFromSrams_bore_20_ram_bypass),
    .sigFromSrams_bore_20_ram_bp_clken(w_sigFromSrams_bore_20_ram_bp_clken),
    .sigFromSrams_bore_20_ram_aux_clk(w_sigFromSrams_bore_20_ram_aux_clk),
    .sigFromSrams_bore_20_ram_aux_ckbp(w_sigFromSrams_bore_20_ram_aux_ckbp),
    .sigFromSrams_bore_20_ram_mcp_hold(w_sigFromSrams_bore_20_ram_mcp_hold),
    .sigFromSrams_bore_20_cgen(w_sigFromSrams_bore_20_cgen),
    .cg_bore_cgen(w_cg_bore_cgen),
    .cg_bore_1_cgen(w_cg_bore_1_cgen),
    .gatewayIn_packed_43_bore(w_g_gatewayIn_packed_43_bore),
    .gatewayIn_packed_44_bore(w_g_gatewayIn_packed_44_bore),
    .gatewayIn_packed_45_bore(w_g_gatewayIn_packed_45_bore)
  );
  L2TLBWrapper_xs w_u_impl (
    .clock(clk),
    .reset(w_reset),
    .auto_out_a_ready(w_auto_out_a_ready),
    .auto_out_a_valid(w_i_auto_out_a_valid),
    .auto_out_a_bits_source(w_i_auto_out_a_bits_source),
    .auto_out_a_bits_address(w_i_auto_out_a_bits_address),
    .auto_out_d_valid(w_auto_out_d_valid),
    .auto_out_d_bits_opcode(w_auto_out_d_bits_opcode),
    .auto_out_d_bits_size(w_auto_out_d_bits_size),
    .auto_out_d_bits_source(w_auto_out_d_bits_source),
    .auto_out_d_bits_data(w_auto_out_d_bits_data),
    .io_hartId(w_io_hartId),
    .io_tlb_0_req_0_ready(w_i_io_tlb_0_req_0_ready),
    .io_tlb_0_req_0_valid(w_io_tlb_0_req_0_valid),
    .io_tlb_0_req_0_bits_vpn(w_io_tlb_0_req_0_bits_vpn),
    .io_tlb_0_req_0_bits_s2xlate(w_io_tlb_0_req_0_bits_s2xlate),
    .io_tlb_0_resp_ready(w_io_tlb_0_resp_ready),
    .io_tlb_0_resp_valid(w_i_io_tlb_0_resp_valid),
    .io_tlb_0_resp_bits_s2xlate(w_i_io_tlb_0_resp_bits_s2xlate),
    .io_tlb_0_resp_bits_s1_entry_tag(w_i_io_tlb_0_resp_bits_s1_entry_tag),
    .io_tlb_0_resp_bits_s1_entry_asid(w_i_io_tlb_0_resp_bits_s1_entry_asid),
    .io_tlb_0_resp_bits_s1_entry_vmid(w_i_io_tlb_0_resp_bits_s1_entry_vmid),
    .io_tlb_0_resp_bits_s1_entry_n(w_i_io_tlb_0_resp_bits_s1_entry_n),
    .io_tlb_0_resp_bits_s1_entry_pbmt(w_i_io_tlb_0_resp_bits_s1_entry_pbmt),
    .io_tlb_0_resp_bits_s1_entry_perm_d(w_i_io_tlb_0_resp_bits_s1_entry_perm_d),
    .io_tlb_0_resp_bits_s1_entry_perm_a(w_i_io_tlb_0_resp_bits_s1_entry_perm_a),
    .io_tlb_0_resp_bits_s1_entry_perm_g(w_i_io_tlb_0_resp_bits_s1_entry_perm_g),
    .io_tlb_0_resp_bits_s1_entry_perm_u(w_i_io_tlb_0_resp_bits_s1_entry_perm_u),
    .io_tlb_0_resp_bits_s1_entry_perm_x(w_i_io_tlb_0_resp_bits_s1_entry_perm_x),
    .io_tlb_0_resp_bits_s1_entry_perm_w(w_i_io_tlb_0_resp_bits_s1_entry_perm_w),
    .io_tlb_0_resp_bits_s1_entry_perm_r(w_i_io_tlb_0_resp_bits_s1_entry_perm_r),
    .io_tlb_0_resp_bits_s1_entry_level(w_i_io_tlb_0_resp_bits_s1_entry_level),
    .io_tlb_0_resp_bits_s1_entry_v(w_i_io_tlb_0_resp_bits_s1_entry_v),
    .io_tlb_0_resp_bits_s1_entry_ppn(w_i_io_tlb_0_resp_bits_s1_entry_ppn),
    .io_tlb_0_resp_bits_s1_addr_low(w_i_io_tlb_0_resp_bits_s1_addr_low),
    .io_tlb_0_resp_bits_s1_ppn_low_0(w_i_io_tlb_0_resp_bits_s1_ppn_low_0),
    .io_tlb_0_resp_bits_s1_ppn_low_1(w_i_io_tlb_0_resp_bits_s1_ppn_low_1),
    .io_tlb_0_resp_bits_s1_ppn_low_2(w_i_io_tlb_0_resp_bits_s1_ppn_low_2),
    .io_tlb_0_resp_bits_s1_ppn_low_3(w_i_io_tlb_0_resp_bits_s1_ppn_low_3),
    .io_tlb_0_resp_bits_s1_ppn_low_4(w_i_io_tlb_0_resp_bits_s1_ppn_low_4),
    .io_tlb_0_resp_bits_s1_ppn_low_5(w_i_io_tlb_0_resp_bits_s1_ppn_low_5),
    .io_tlb_0_resp_bits_s1_ppn_low_6(w_i_io_tlb_0_resp_bits_s1_ppn_low_6),
    .io_tlb_0_resp_bits_s1_ppn_low_7(w_i_io_tlb_0_resp_bits_s1_ppn_low_7),
    .io_tlb_0_resp_bits_s1_valididx_0(w_i_io_tlb_0_resp_bits_s1_valididx_0),
    .io_tlb_0_resp_bits_s1_valididx_1(w_i_io_tlb_0_resp_bits_s1_valididx_1),
    .io_tlb_0_resp_bits_s1_valididx_2(w_i_io_tlb_0_resp_bits_s1_valididx_2),
    .io_tlb_0_resp_bits_s1_valididx_3(w_i_io_tlb_0_resp_bits_s1_valididx_3),
    .io_tlb_0_resp_bits_s1_valididx_4(w_i_io_tlb_0_resp_bits_s1_valididx_4),
    .io_tlb_0_resp_bits_s1_valididx_5(w_i_io_tlb_0_resp_bits_s1_valididx_5),
    .io_tlb_0_resp_bits_s1_valididx_6(w_i_io_tlb_0_resp_bits_s1_valididx_6),
    .io_tlb_0_resp_bits_s1_valididx_7(w_i_io_tlb_0_resp_bits_s1_valididx_7),
    .io_tlb_0_resp_bits_s1_pteidx_0(w_i_io_tlb_0_resp_bits_s1_pteidx_0),
    .io_tlb_0_resp_bits_s1_pteidx_1(w_i_io_tlb_0_resp_bits_s1_pteidx_1),
    .io_tlb_0_resp_bits_s1_pteidx_2(w_i_io_tlb_0_resp_bits_s1_pteidx_2),
    .io_tlb_0_resp_bits_s1_pteidx_3(w_i_io_tlb_0_resp_bits_s1_pteidx_3),
    .io_tlb_0_resp_bits_s1_pteidx_4(w_i_io_tlb_0_resp_bits_s1_pteidx_4),
    .io_tlb_0_resp_bits_s1_pteidx_5(w_i_io_tlb_0_resp_bits_s1_pteidx_5),
    .io_tlb_0_resp_bits_s1_pteidx_6(w_i_io_tlb_0_resp_bits_s1_pteidx_6),
    .io_tlb_0_resp_bits_s1_pteidx_7(w_i_io_tlb_0_resp_bits_s1_pteidx_7),
    .io_tlb_0_resp_bits_s1_pf(w_i_io_tlb_0_resp_bits_s1_pf),
    .io_tlb_0_resp_bits_s1_af(w_i_io_tlb_0_resp_bits_s1_af),
    .io_tlb_0_resp_bits_s2_entry_tag(w_i_io_tlb_0_resp_bits_s2_entry_tag),
    .io_tlb_0_resp_bits_s2_entry_vmid(w_i_io_tlb_0_resp_bits_s2_entry_vmid),
    .io_tlb_0_resp_bits_s2_entry_n(w_i_io_tlb_0_resp_bits_s2_entry_n),
    .io_tlb_0_resp_bits_s2_entry_pbmt(w_i_io_tlb_0_resp_bits_s2_entry_pbmt),
    .io_tlb_0_resp_bits_s2_entry_ppn(w_i_io_tlb_0_resp_bits_s2_entry_ppn),
    .io_tlb_0_resp_bits_s2_entry_perm_d(w_i_io_tlb_0_resp_bits_s2_entry_perm_d),
    .io_tlb_0_resp_bits_s2_entry_perm_a(w_i_io_tlb_0_resp_bits_s2_entry_perm_a),
    .io_tlb_0_resp_bits_s2_entry_perm_g(w_i_io_tlb_0_resp_bits_s2_entry_perm_g),
    .io_tlb_0_resp_bits_s2_entry_perm_u(w_i_io_tlb_0_resp_bits_s2_entry_perm_u),
    .io_tlb_0_resp_bits_s2_entry_perm_x(w_i_io_tlb_0_resp_bits_s2_entry_perm_x),
    .io_tlb_0_resp_bits_s2_entry_perm_w(w_i_io_tlb_0_resp_bits_s2_entry_perm_w),
    .io_tlb_0_resp_bits_s2_entry_perm_r(w_i_io_tlb_0_resp_bits_s2_entry_perm_r),
    .io_tlb_0_resp_bits_s2_entry_level(w_i_io_tlb_0_resp_bits_s2_entry_level),
    .io_tlb_0_resp_bits_s2_gpf(w_i_io_tlb_0_resp_bits_s2_gpf),
    .io_tlb_0_resp_bits_s2_gaf(w_i_io_tlb_0_resp_bits_s2_gaf),
    .io_tlb_1_req_0_ready(w_i_io_tlb_1_req_0_ready),
    .io_tlb_1_req_0_valid(w_io_tlb_1_req_0_valid),
    .io_tlb_1_req_0_bits_vpn(w_io_tlb_1_req_0_bits_vpn),
    .io_tlb_1_req_0_bits_s2xlate(w_io_tlb_1_req_0_bits_s2xlate),
    .io_tlb_1_resp_valid(w_i_io_tlb_1_resp_valid),
    .io_tlb_1_resp_bits_s2xlate(w_i_io_tlb_1_resp_bits_s2xlate),
    .io_tlb_1_resp_bits_s1_entry_tag(w_i_io_tlb_1_resp_bits_s1_entry_tag),
    .io_tlb_1_resp_bits_s1_entry_asid(w_i_io_tlb_1_resp_bits_s1_entry_asid),
    .io_tlb_1_resp_bits_s1_entry_vmid(w_i_io_tlb_1_resp_bits_s1_entry_vmid),
    .io_tlb_1_resp_bits_s1_entry_n(w_i_io_tlb_1_resp_bits_s1_entry_n),
    .io_tlb_1_resp_bits_s1_entry_pbmt(w_i_io_tlb_1_resp_bits_s1_entry_pbmt),
    .io_tlb_1_resp_bits_s1_entry_perm_d(w_i_io_tlb_1_resp_bits_s1_entry_perm_d),
    .io_tlb_1_resp_bits_s1_entry_perm_a(w_i_io_tlb_1_resp_bits_s1_entry_perm_a),
    .io_tlb_1_resp_bits_s1_entry_perm_g(w_i_io_tlb_1_resp_bits_s1_entry_perm_g),
    .io_tlb_1_resp_bits_s1_entry_perm_u(w_i_io_tlb_1_resp_bits_s1_entry_perm_u),
    .io_tlb_1_resp_bits_s1_entry_perm_x(w_i_io_tlb_1_resp_bits_s1_entry_perm_x),
    .io_tlb_1_resp_bits_s1_entry_perm_w(w_i_io_tlb_1_resp_bits_s1_entry_perm_w),
    .io_tlb_1_resp_bits_s1_entry_perm_r(w_i_io_tlb_1_resp_bits_s1_entry_perm_r),
    .io_tlb_1_resp_bits_s1_entry_level(w_i_io_tlb_1_resp_bits_s1_entry_level),
    .io_tlb_1_resp_bits_s1_entry_v(w_i_io_tlb_1_resp_bits_s1_entry_v),
    .io_tlb_1_resp_bits_s1_entry_ppn(w_i_io_tlb_1_resp_bits_s1_entry_ppn),
    .io_tlb_1_resp_bits_s1_addr_low(w_i_io_tlb_1_resp_bits_s1_addr_low),
    .io_tlb_1_resp_bits_s1_ppn_low_0(w_i_io_tlb_1_resp_bits_s1_ppn_low_0),
    .io_tlb_1_resp_bits_s1_ppn_low_1(w_i_io_tlb_1_resp_bits_s1_ppn_low_1),
    .io_tlb_1_resp_bits_s1_ppn_low_2(w_i_io_tlb_1_resp_bits_s1_ppn_low_2),
    .io_tlb_1_resp_bits_s1_ppn_low_3(w_i_io_tlb_1_resp_bits_s1_ppn_low_3),
    .io_tlb_1_resp_bits_s1_ppn_low_4(w_i_io_tlb_1_resp_bits_s1_ppn_low_4),
    .io_tlb_1_resp_bits_s1_ppn_low_5(w_i_io_tlb_1_resp_bits_s1_ppn_low_5),
    .io_tlb_1_resp_bits_s1_ppn_low_6(w_i_io_tlb_1_resp_bits_s1_ppn_low_6),
    .io_tlb_1_resp_bits_s1_ppn_low_7(w_i_io_tlb_1_resp_bits_s1_ppn_low_7),
    .io_tlb_1_resp_bits_s1_valididx_0(w_i_io_tlb_1_resp_bits_s1_valididx_0),
    .io_tlb_1_resp_bits_s1_valididx_1(w_i_io_tlb_1_resp_bits_s1_valididx_1),
    .io_tlb_1_resp_bits_s1_valididx_2(w_i_io_tlb_1_resp_bits_s1_valididx_2),
    .io_tlb_1_resp_bits_s1_valididx_3(w_i_io_tlb_1_resp_bits_s1_valididx_3),
    .io_tlb_1_resp_bits_s1_valididx_4(w_i_io_tlb_1_resp_bits_s1_valididx_4),
    .io_tlb_1_resp_bits_s1_valididx_5(w_i_io_tlb_1_resp_bits_s1_valididx_5),
    .io_tlb_1_resp_bits_s1_valididx_6(w_i_io_tlb_1_resp_bits_s1_valididx_6),
    .io_tlb_1_resp_bits_s1_valididx_7(w_i_io_tlb_1_resp_bits_s1_valididx_7),
    .io_tlb_1_resp_bits_s1_pteidx_0(w_i_io_tlb_1_resp_bits_s1_pteidx_0),
    .io_tlb_1_resp_bits_s1_pteidx_1(w_i_io_tlb_1_resp_bits_s1_pteidx_1),
    .io_tlb_1_resp_bits_s1_pteidx_2(w_i_io_tlb_1_resp_bits_s1_pteidx_2),
    .io_tlb_1_resp_bits_s1_pteidx_3(w_i_io_tlb_1_resp_bits_s1_pteidx_3),
    .io_tlb_1_resp_bits_s1_pteidx_4(w_i_io_tlb_1_resp_bits_s1_pteidx_4),
    .io_tlb_1_resp_bits_s1_pteidx_5(w_i_io_tlb_1_resp_bits_s1_pteidx_5),
    .io_tlb_1_resp_bits_s1_pteidx_6(w_i_io_tlb_1_resp_bits_s1_pteidx_6),
    .io_tlb_1_resp_bits_s1_pteidx_7(w_i_io_tlb_1_resp_bits_s1_pteidx_7),
    .io_tlb_1_resp_bits_s1_pf(w_i_io_tlb_1_resp_bits_s1_pf),
    .io_tlb_1_resp_bits_s1_af(w_i_io_tlb_1_resp_bits_s1_af),
    .io_tlb_1_resp_bits_s2_entry_tag(w_i_io_tlb_1_resp_bits_s2_entry_tag),
    .io_tlb_1_resp_bits_s2_entry_vmid(w_i_io_tlb_1_resp_bits_s2_entry_vmid),
    .io_tlb_1_resp_bits_s2_entry_n(w_i_io_tlb_1_resp_bits_s2_entry_n),
    .io_tlb_1_resp_bits_s2_entry_pbmt(w_i_io_tlb_1_resp_bits_s2_entry_pbmt),
    .io_tlb_1_resp_bits_s2_entry_ppn(w_i_io_tlb_1_resp_bits_s2_entry_ppn),
    .io_tlb_1_resp_bits_s2_entry_perm_d(w_i_io_tlb_1_resp_bits_s2_entry_perm_d),
    .io_tlb_1_resp_bits_s2_entry_perm_a(w_i_io_tlb_1_resp_bits_s2_entry_perm_a),
    .io_tlb_1_resp_bits_s2_entry_perm_g(w_i_io_tlb_1_resp_bits_s2_entry_perm_g),
    .io_tlb_1_resp_bits_s2_entry_perm_u(w_i_io_tlb_1_resp_bits_s2_entry_perm_u),
    .io_tlb_1_resp_bits_s2_entry_perm_x(w_i_io_tlb_1_resp_bits_s2_entry_perm_x),
    .io_tlb_1_resp_bits_s2_entry_perm_w(w_i_io_tlb_1_resp_bits_s2_entry_perm_w),
    .io_tlb_1_resp_bits_s2_entry_perm_r(w_i_io_tlb_1_resp_bits_s2_entry_perm_r),
    .io_tlb_1_resp_bits_s2_entry_level(w_i_io_tlb_1_resp_bits_s2_entry_level),
    .io_tlb_1_resp_bits_s2_gpf(w_i_io_tlb_1_resp_bits_s2_gpf),
    .io_tlb_1_resp_bits_s2_gaf(w_i_io_tlb_1_resp_bits_s2_gaf),
    .io_sfence_valid(w_io_sfence_valid),
    .io_sfence_bits_rs1(w_io_sfence_bits_rs1),
    .io_sfence_bits_rs2(w_io_sfence_bits_rs2),
    .io_sfence_bits_addr(w_io_sfence_bits_addr),
    .io_sfence_bits_id(w_io_sfence_bits_id),
    .io_sfence_bits_hv(w_io_sfence_bits_hv),
    .io_sfence_bits_hg(w_io_sfence_bits_hg),
    .io_wfi_wfiReq(w_io_wfi_wfiReq),
    .io_wfi_wfiSafe(w_i_io_wfi_wfiSafe),
    .io_csr_tlb_satp_mode(w_io_csr_tlb_satp_mode),
    .io_csr_tlb_satp_asid(w_io_csr_tlb_satp_asid),
    .io_csr_tlb_satp_ppn(w_io_csr_tlb_satp_ppn),
    .io_csr_tlb_satp_changed(w_io_csr_tlb_satp_changed),
    .io_csr_tlb_vsatp_mode(w_io_csr_tlb_vsatp_mode),
    .io_csr_tlb_vsatp_asid(w_io_csr_tlb_vsatp_asid),
    .io_csr_tlb_vsatp_ppn(w_io_csr_tlb_vsatp_ppn),
    .io_csr_tlb_vsatp_changed(w_io_csr_tlb_vsatp_changed),
    .io_csr_tlb_hgatp_mode(w_io_csr_tlb_hgatp_mode),
    .io_csr_tlb_hgatp_vmid(w_io_csr_tlb_hgatp_vmid),
    .io_csr_tlb_hgatp_ppn(w_io_csr_tlb_hgatp_ppn),
    .io_csr_tlb_hgatp_changed(w_io_csr_tlb_hgatp_changed),
    .io_csr_tlb_mbmc_BME(w_io_csr_tlb_mbmc_BME),
    .io_csr_tlb_mbmc_CMODE(w_io_csr_tlb_mbmc_CMODE),
    .io_csr_tlb_mbmc_BCLEAR(w_io_csr_tlb_mbmc_BCLEAR),
    .io_csr_tlb_mbmc_BMA(w_io_csr_tlb_mbmc_BMA),
    .io_csr_tlb_priv_virt(w_io_csr_tlb_priv_virt),
    .io_csr_tlb_priv_virt_changed(w_io_csr_tlb_priv_virt_changed),
    .io_csr_tlb_priv_debug(w_io_csr_tlb_priv_debug),
    .io_csr_tlb_mPBMTE(w_io_csr_tlb_mPBMTE),
    .io_csr_tlb_hPBMTE(w_io_csr_tlb_hPBMTE),
    .io_csr_distribute_csr_w_valid(w_io_csr_distribute_csr_w_valid),
    .io_csr_distribute_csr_w_bits_addr(w_io_csr_distribute_csr_w_bits_addr),
    .io_csr_distribute_csr_w_bits_data(w_io_csr_distribute_csr_w_bits_data),
    .io_perf_0_value(w_i_io_perf_0_value),
    .io_perf_1_value(w_i_io_perf_1_value),
    .io_perf_2_value(w_i_io_perf_2_value),
    .io_perf_3_value(w_i_io_perf_3_value),
    .io_perf_4_value(w_i_io_perf_4_value),
    .io_perf_5_value(w_i_io_perf_5_value),
    .io_perf_6_value(w_i_io_perf_6_value),
    .io_perf_7_value(w_i_io_perf_7_value),
    .io_perf_8_value(w_i_io_perf_8_value),
    .io_perf_9_value(w_i_io_perf_9_value),
    .io_perf_10_value(w_i_io_perf_10_value),
    .io_perf_11_value(w_i_io_perf_11_value),
    .io_perf_12_value(w_i_io_perf_12_value),
    .io_perf_13_value(w_i_io_perf_13_value),
    .io_perf_14_value(w_i_io_perf_14_value),
    .io_perf_15_value(w_i_io_perf_15_value),
    .io_perf_16_value(w_i_io_perf_16_value),
    .io_perf_17_value(w_i_io_perf_17_value),
    .io_perf_18_value(w_i_io_perf_18_value),
    .boreChildrenBd_bore_array(w_boreChildrenBd_bore_array),
    .boreChildrenBd_bore_all(w_boreChildrenBd_bore_all),
    .boreChildrenBd_bore_req(w_boreChildrenBd_bore_req),
    .boreChildrenBd_bore_ack(w_i_boreChildrenBd_bore_ack),
    .boreChildrenBd_bore_writeen(w_boreChildrenBd_bore_writeen),
    .boreChildrenBd_bore_be(w_boreChildrenBd_bore_be),
    .boreChildrenBd_bore_addr(w_boreChildrenBd_bore_addr),
    .boreChildrenBd_bore_indata(w_boreChildrenBd_bore_indata),
    .boreChildrenBd_bore_readen(w_boreChildrenBd_bore_readen),
    .boreChildrenBd_bore_addr_rd(w_boreChildrenBd_bore_addr_rd),
    .boreChildrenBd_bore_outdata(w_i_boreChildrenBd_bore_outdata),
    .boreChildrenBd_bore_1_array(w_boreChildrenBd_bore_1_array),
    .boreChildrenBd_bore_1_all(w_boreChildrenBd_bore_1_all),
    .boreChildrenBd_bore_1_req(w_boreChildrenBd_bore_1_req),
    .boreChildrenBd_bore_1_ack(w_i_boreChildrenBd_bore_1_ack),
    .boreChildrenBd_bore_1_writeen(w_boreChildrenBd_bore_1_writeen),
    .boreChildrenBd_bore_1_be(w_boreChildrenBd_bore_1_be),
    .boreChildrenBd_bore_1_addr(w_boreChildrenBd_bore_1_addr),
    .boreChildrenBd_bore_1_indata(w_boreChildrenBd_bore_1_indata),
    .boreChildrenBd_bore_1_readen(w_boreChildrenBd_bore_1_readen),
    .boreChildrenBd_bore_1_addr_rd(w_boreChildrenBd_bore_1_addr_rd),
    .boreChildrenBd_bore_1_outdata(w_i_boreChildrenBd_bore_1_outdata),
    .boreChildrenBd_bore_2_array(w_boreChildrenBd_bore_2_array),
    .boreChildrenBd_bore_2_all(w_boreChildrenBd_bore_2_all),
    .boreChildrenBd_bore_2_req(w_boreChildrenBd_bore_2_req),
    .boreChildrenBd_bore_2_ack(w_i_boreChildrenBd_bore_2_ack),
    .boreChildrenBd_bore_2_writeen(w_boreChildrenBd_bore_2_writeen),
    .boreChildrenBd_bore_2_be(w_boreChildrenBd_bore_2_be),
    .boreChildrenBd_bore_2_addr(w_boreChildrenBd_bore_2_addr),
    .boreChildrenBd_bore_2_indata(w_boreChildrenBd_bore_2_indata),
    .boreChildrenBd_bore_2_readen(w_boreChildrenBd_bore_2_readen),
    .boreChildrenBd_bore_2_addr_rd(w_boreChildrenBd_bore_2_addr_rd),
    .boreChildrenBd_bore_2_outdata(w_i_boreChildrenBd_bore_2_outdata),
    .sigFromSrams_bore_ram_hold(w_sigFromSrams_bore_ram_hold),
    .sigFromSrams_bore_ram_bypass(w_sigFromSrams_bore_ram_bypass),
    .sigFromSrams_bore_ram_bp_clken(w_sigFromSrams_bore_ram_bp_clken),
    .sigFromSrams_bore_ram_aux_clk(w_sigFromSrams_bore_ram_aux_clk),
    .sigFromSrams_bore_ram_aux_ckbp(w_sigFromSrams_bore_ram_aux_ckbp),
    .sigFromSrams_bore_ram_mcp_hold(w_sigFromSrams_bore_ram_mcp_hold),
    .sigFromSrams_bore_cgen(w_sigFromSrams_bore_cgen),
    .sigFromSrams_bore_1_ram_hold(w_sigFromSrams_bore_1_ram_hold),
    .sigFromSrams_bore_1_ram_bypass(w_sigFromSrams_bore_1_ram_bypass),
    .sigFromSrams_bore_1_ram_bp_clken(w_sigFromSrams_bore_1_ram_bp_clken),
    .sigFromSrams_bore_1_ram_aux_clk(w_sigFromSrams_bore_1_ram_aux_clk),
    .sigFromSrams_bore_1_ram_aux_ckbp(w_sigFromSrams_bore_1_ram_aux_ckbp),
    .sigFromSrams_bore_1_ram_mcp_hold(w_sigFromSrams_bore_1_ram_mcp_hold),
    .sigFromSrams_bore_1_cgen(w_sigFromSrams_bore_1_cgen),
    .sigFromSrams_bore_2_ram_hold(w_sigFromSrams_bore_2_ram_hold),
    .sigFromSrams_bore_2_ram_bypass(w_sigFromSrams_bore_2_ram_bypass),
    .sigFromSrams_bore_2_ram_bp_clken(w_sigFromSrams_bore_2_ram_bp_clken),
    .sigFromSrams_bore_2_ram_aux_clk(w_sigFromSrams_bore_2_ram_aux_clk),
    .sigFromSrams_bore_2_ram_aux_ckbp(w_sigFromSrams_bore_2_ram_aux_ckbp),
    .sigFromSrams_bore_2_ram_mcp_hold(w_sigFromSrams_bore_2_ram_mcp_hold),
    .sigFromSrams_bore_2_cgen(w_sigFromSrams_bore_2_cgen),
    .sigFromSrams_bore_3_ram_hold(w_sigFromSrams_bore_3_ram_hold),
    .sigFromSrams_bore_3_ram_bypass(w_sigFromSrams_bore_3_ram_bypass),
    .sigFromSrams_bore_3_ram_bp_clken(w_sigFromSrams_bore_3_ram_bp_clken),
    .sigFromSrams_bore_3_ram_aux_clk(w_sigFromSrams_bore_3_ram_aux_clk),
    .sigFromSrams_bore_3_ram_aux_ckbp(w_sigFromSrams_bore_3_ram_aux_ckbp),
    .sigFromSrams_bore_3_ram_mcp_hold(w_sigFromSrams_bore_3_ram_mcp_hold),
    .sigFromSrams_bore_3_cgen(w_sigFromSrams_bore_3_cgen),
    .sigFromSrams_bore_4_ram_hold(w_sigFromSrams_bore_4_ram_hold),
    .sigFromSrams_bore_4_ram_bypass(w_sigFromSrams_bore_4_ram_bypass),
    .sigFromSrams_bore_4_ram_bp_clken(w_sigFromSrams_bore_4_ram_bp_clken),
    .sigFromSrams_bore_4_ram_aux_clk(w_sigFromSrams_bore_4_ram_aux_clk),
    .sigFromSrams_bore_4_ram_aux_ckbp(w_sigFromSrams_bore_4_ram_aux_ckbp),
    .sigFromSrams_bore_4_ram_mcp_hold(w_sigFromSrams_bore_4_ram_mcp_hold),
    .sigFromSrams_bore_4_cgen(w_sigFromSrams_bore_4_cgen),
    .sigFromSrams_bore_5_ram_hold(w_sigFromSrams_bore_5_ram_hold),
    .sigFromSrams_bore_5_ram_bypass(w_sigFromSrams_bore_5_ram_bypass),
    .sigFromSrams_bore_5_ram_bp_clken(w_sigFromSrams_bore_5_ram_bp_clken),
    .sigFromSrams_bore_5_ram_aux_clk(w_sigFromSrams_bore_5_ram_aux_clk),
    .sigFromSrams_bore_5_ram_aux_ckbp(w_sigFromSrams_bore_5_ram_aux_ckbp),
    .sigFromSrams_bore_5_ram_mcp_hold(w_sigFromSrams_bore_5_ram_mcp_hold),
    .sigFromSrams_bore_5_cgen(w_sigFromSrams_bore_5_cgen),
    .sigFromSrams_bore_6_ram_hold(w_sigFromSrams_bore_6_ram_hold),
    .sigFromSrams_bore_6_ram_bypass(w_sigFromSrams_bore_6_ram_bypass),
    .sigFromSrams_bore_6_ram_bp_clken(w_sigFromSrams_bore_6_ram_bp_clken),
    .sigFromSrams_bore_6_ram_aux_clk(w_sigFromSrams_bore_6_ram_aux_clk),
    .sigFromSrams_bore_6_ram_aux_ckbp(w_sigFromSrams_bore_6_ram_aux_ckbp),
    .sigFromSrams_bore_6_ram_mcp_hold(w_sigFromSrams_bore_6_ram_mcp_hold),
    .sigFromSrams_bore_6_cgen(w_sigFromSrams_bore_6_cgen),
    .sigFromSrams_bore_7_ram_hold(w_sigFromSrams_bore_7_ram_hold),
    .sigFromSrams_bore_7_ram_bypass(w_sigFromSrams_bore_7_ram_bypass),
    .sigFromSrams_bore_7_ram_bp_clken(w_sigFromSrams_bore_7_ram_bp_clken),
    .sigFromSrams_bore_7_ram_aux_clk(w_sigFromSrams_bore_7_ram_aux_clk),
    .sigFromSrams_bore_7_ram_aux_ckbp(w_sigFromSrams_bore_7_ram_aux_ckbp),
    .sigFromSrams_bore_7_ram_mcp_hold(w_sigFromSrams_bore_7_ram_mcp_hold),
    .sigFromSrams_bore_7_cgen(w_sigFromSrams_bore_7_cgen),
    .sigFromSrams_bore_8_ram_hold(w_sigFromSrams_bore_8_ram_hold),
    .sigFromSrams_bore_8_ram_bypass(w_sigFromSrams_bore_8_ram_bypass),
    .sigFromSrams_bore_8_ram_bp_clken(w_sigFromSrams_bore_8_ram_bp_clken),
    .sigFromSrams_bore_8_ram_aux_clk(w_sigFromSrams_bore_8_ram_aux_clk),
    .sigFromSrams_bore_8_ram_aux_ckbp(w_sigFromSrams_bore_8_ram_aux_ckbp),
    .sigFromSrams_bore_8_ram_mcp_hold(w_sigFromSrams_bore_8_ram_mcp_hold),
    .sigFromSrams_bore_8_cgen(w_sigFromSrams_bore_8_cgen),
    .sigFromSrams_bore_9_ram_hold(w_sigFromSrams_bore_9_ram_hold),
    .sigFromSrams_bore_9_ram_bypass(w_sigFromSrams_bore_9_ram_bypass),
    .sigFromSrams_bore_9_ram_bp_clken(w_sigFromSrams_bore_9_ram_bp_clken),
    .sigFromSrams_bore_9_ram_aux_clk(w_sigFromSrams_bore_9_ram_aux_clk),
    .sigFromSrams_bore_9_ram_aux_ckbp(w_sigFromSrams_bore_9_ram_aux_ckbp),
    .sigFromSrams_bore_9_ram_mcp_hold(w_sigFromSrams_bore_9_ram_mcp_hold),
    .sigFromSrams_bore_9_cgen(w_sigFromSrams_bore_9_cgen),
    .sigFromSrams_bore_10_ram_hold(w_sigFromSrams_bore_10_ram_hold),
    .sigFromSrams_bore_10_ram_bypass(w_sigFromSrams_bore_10_ram_bypass),
    .sigFromSrams_bore_10_ram_bp_clken(w_sigFromSrams_bore_10_ram_bp_clken),
    .sigFromSrams_bore_10_ram_aux_clk(w_sigFromSrams_bore_10_ram_aux_clk),
    .sigFromSrams_bore_10_ram_aux_ckbp(w_sigFromSrams_bore_10_ram_aux_ckbp),
    .sigFromSrams_bore_10_ram_mcp_hold(w_sigFromSrams_bore_10_ram_mcp_hold),
    .sigFromSrams_bore_10_cgen(w_sigFromSrams_bore_10_cgen),
    .sigFromSrams_bore_11_ram_hold(w_sigFromSrams_bore_11_ram_hold),
    .sigFromSrams_bore_11_ram_bypass(w_sigFromSrams_bore_11_ram_bypass),
    .sigFromSrams_bore_11_ram_bp_clken(w_sigFromSrams_bore_11_ram_bp_clken),
    .sigFromSrams_bore_11_ram_aux_clk(w_sigFromSrams_bore_11_ram_aux_clk),
    .sigFromSrams_bore_11_ram_aux_ckbp(w_sigFromSrams_bore_11_ram_aux_ckbp),
    .sigFromSrams_bore_11_ram_mcp_hold(w_sigFromSrams_bore_11_ram_mcp_hold),
    .sigFromSrams_bore_11_cgen(w_sigFromSrams_bore_11_cgen),
    .sigFromSrams_bore_12_ram_hold(w_sigFromSrams_bore_12_ram_hold),
    .sigFromSrams_bore_12_ram_bypass(w_sigFromSrams_bore_12_ram_bypass),
    .sigFromSrams_bore_12_ram_bp_clken(w_sigFromSrams_bore_12_ram_bp_clken),
    .sigFromSrams_bore_12_ram_aux_clk(w_sigFromSrams_bore_12_ram_aux_clk),
    .sigFromSrams_bore_12_ram_aux_ckbp(w_sigFromSrams_bore_12_ram_aux_ckbp),
    .sigFromSrams_bore_12_ram_mcp_hold(w_sigFromSrams_bore_12_ram_mcp_hold),
    .sigFromSrams_bore_12_cgen(w_sigFromSrams_bore_12_cgen),
    .sigFromSrams_bore_13_ram_hold(w_sigFromSrams_bore_13_ram_hold),
    .sigFromSrams_bore_13_ram_bypass(w_sigFromSrams_bore_13_ram_bypass),
    .sigFromSrams_bore_13_ram_bp_clken(w_sigFromSrams_bore_13_ram_bp_clken),
    .sigFromSrams_bore_13_ram_aux_clk(w_sigFromSrams_bore_13_ram_aux_clk),
    .sigFromSrams_bore_13_ram_aux_ckbp(w_sigFromSrams_bore_13_ram_aux_ckbp),
    .sigFromSrams_bore_13_ram_mcp_hold(w_sigFromSrams_bore_13_ram_mcp_hold),
    .sigFromSrams_bore_13_cgen(w_sigFromSrams_bore_13_cgen),
    .sigFromSrams_bore_14_ram_hold(w_sigFromSrams_bore_14_ram_hold),
    .sigFromSrams_bore_14_ram_bypass(w_sigFromSrams_bore_14_ram_bypass),
    .sigFromSrams_bore_14_ram_bp_clken(w_sigFromSrams_bore_14_ram_bp_clken),
    .sigFromSrams_bore_14_ram_aux_clk(w_sigFromSrams_bore_14_ram_aux_clk),
    .sigFromSrams_bore_14_ram_aux_ckbp(w_sigFromSrams_bore_14_ram_aux_ckbp),
    .sigFromSrams_bore_14_ram_mcp_hold(w_sigFromSrams_bore_14_ram_mcp_hold),
    .sigFromSrams_bore_14_cgen(w_sigFromSrams_bore_14_cgen),
    .sigFromSrams_bore_15_ram_hold(w_sigFromSrams_bore_15_ram_hold),
    .sigFromSrams_bore_15_ram_bypass(w_sigFromSrams_bore_15_ram_bypass),
    .sigFromSrams_bore_15_ram_bp_clken(w_sigFromSrams_bore_15_ram_bp_clken),
    .sigFromSrams_bore_15_ram_aux_clk(w_sigFromSrams_bore_15_ram_aux_clk),
    .sigFromSrams_bore_15_ram_aux_ckbp(w_sigFromSrams_bore_15_ram_aux_ckbp),
    .sigFromSrams_bore_15_ram_mcp_hold(w_sigFromSrams_bore_15_ram_mcp_hold),
    .sigFromSrams_bore_15_cgen(w_sigFromSrams_bore_15_cgen),
    .sigFromSrams_bore_16_ram_hold(w_sigFromSrams_bore_16_ram_hold),
    .sigFromSrams_bore_16_ram_bypass(w_sigFromSrams_bore_16_ram_bypass),
    .sigFromSrams_bore_16_ram_bp_clken(w_sigFromSrams_bore_16_ram_bp_clken),
    .sigFromSrams_bore_16_ram_aux_clk(w_sigFromSrams_bore_16_ram_aux_clk),
    .sigFromSrams_bore_16_ram_aux_ckbp(w_sigFromSrams_bore_16_ram_aux_ckbp),
    .sigFromSrams_bore_16_ram_mcp_hold(w_sigFromSrams_bore_16_ram_mcp_hold),
    .sigFromSrams_bore_16_cgen(w_sigFromSrams_bore_16_cgen),
    .sigFromSrams_bore_17_ram_hold(w_sigFromSrams_bore_17_ram_hold),
    .sigFromSrams_bore_17_ram_bypass(w_sigFromSrams_bore_17_ram_bypass),
    .sigFromSrams_bore_17_ram_bp_clken(w_sigFromSrams_bore_17_ram_bp_clken),
    .sigFromSrams_bore_17_ram_aux_clk(w_sigFromSrams_bore_17_ram_aux_clk),
    .sigFromSrams_bore_17_ram_aux_ckbp(w_sigFromSrams_bore_17_ram_aux_ckbp),
    .sigFromSrams_bore_17_ram_mcp_hold(w_sigFromSrams_bore_17_ram_mcp_hold),
    .sigFromSrams_bore_17_cgen(w_sigFromSrams_bore_17_cgen),
    .sigFromSrams_bore_18_ram_hold(w_sigFromSrams_bore_18_ram_hold),
    .sigFromSrams_bore_18_ram_bypass(w_sigFromSrams_bore_18_ram_bypass),
    .sigFromSrams_bore_18_ram_bp_clken(w_sigFromSrams_bore_18_ram_bp_clken),
    .sigFromSrams_bore_18_ram_aux_clk(w_sigFromSrams_bore_18_ram_aux_clk),
    .sigFromSrams_bore_18_ram_aux_ckbp(w_sigFromSrams_bore_18_ram_aux_ckbp),
    .sigFromSrams_bore_18_ram_mcp_hold(w_sigFromSrams_bore_18_ram_mcp_hold),
    .sigFromSrams_bore_18_cgen(w_sigFromSrams_bore_18_cgen),
    .sigFromSrams_bore_19_ram_hold(w_sigFromSrams_bore_19_ram_hold),
    .sigFromSrams_bore_19_ram_bypass(w_sigFromSrams_bore_19_ram_bypass),
    .sigFromSrams_bore_19_ram_bp_clken(w_sigFromSrams_bore_19_ram_bp_clken),
    .sigFromSrams_bore_19_ram_aux_clk(w_sigFromSrams_bore_19_ram_aux_clk),
    .sigFromSrams_bore_19_ram_aux_ckbp(w_sigFromSrams_bore_19_ram_aux_ckbp),
    .sigFromSrams_bore_19_ram_mcp_hold(w_sigFromSrams_bore_19_ram_mcp_hold),
    .sigFromSrams_bore_19_cgen(w_sigFromSrams_bore_19_cgen),
    .sigFromSrams_bore_20_ram_hold(w_sigFromSrams_bore_20_ram_hold),
    .sigFromSrams_bore_20_ram_bypass(w_sigFromSrams_bore_20_ram_bypass),
    .sigFromSrams_bore_20_ram_bp_clken(w_sigFromSrams_bore_20_ram_bp_clken),
    .sigFromSrams_bore_20_ram_aux_clk(w_sigFromSrams_bore_20_ram_aux_clk),
    .sigFromSrams_bore_20_ram_aux_ckbp(w_sigFromSrams_bore_20_ram_aux_ckbp),
    .sigFromSrams_bore_20_ram_mcp_hold(w_sigFromSrams_bore_20_ram_mcp_hold),
    .sigFromSrams_bore_20_cgen(w_sigFromSrams_bore_20_cgen),
    .cg_bore_cgen(w_cg_bore_cgen),
    .cg_bore_1_cgen(w_cg_bore_1_cgen),
    .gatewayIn_packed_43_bore(w_i_gatewayIn_packed_43_bore),
    .gatewayIn_packed_44_bore(w_i_gatewayIn_packed_44_bore),
    .gatewayIn_packed_45_bore(w_i_gatewayIn_packed_45_bore)
  );

  initial begin
    if ($value$plusargs("ncycles=%d", NCYCLES)) ;
    for (cyc = 0; cyc < NCYCLES; cyc++) begin
      @(negedge clk);
      if (cyc % 4000 == 0) w_mode = $urandom_range(0, 15);
      w_auto_out_a_ready = 1'($urandom);
      w_auto_out_d_valid = 1'($urandom);
      w_auto_out_d_bits_opcode = 4'($urandom);
      w_auto_out_d_bits_size = 3'($urandom);
      w_auto_out_d_bits_source = 4'($urandom);
      w_auto_out_d_bits_data = 256'({$urandom, $urandom, $urandom, $urandom, $urandom, $urandom, $urandom, $urandom});
      w_io_hartId = 6'($urandom);
      w_io_tlb_0_req_0_valid = 1'($urandom);
      w_io_tlb_0_req_0_bits_vpn = 38'({$urandom, $urandom});
      w_io_tlb_0_req_0_bits_s2xlate = 2'($urandom);
      w_io_tlb_0_resp_ready = 1'($urandom);
      w_io_tlb_1_req_0_valid = 1'($urandom);
      w_io_tlb_1_req_0_bits_vpn = 38'({$urandom, $urandom});
      w_io_tlb_1_req_0_bits_s2xlate = 2'($urandom);
      w_io_sfence_valid = 1'($urandom);
      w_io_sfence_bits_rs1 = 1'($urandom);
      w_io_sfence_bits_rs2 = 1'($urandom);
      w_io_sfence_bits_addr = 50'({$urandom, $urandom});
      w_io_sfence_bits_id = 16'($urandom);
      w_io_sfence_bits_hv = 1'($urandom);
      w_io_sfence_bits_hg = 1'($urandom);
      w_io_wfi_wfiReq = 1'($urandom);
      w_io_csr_tlb_satp_mode = 4'($urandom);
      w_io_csr_tlb_satp_asid = 16'($urandom);
      w_io_csr_tlb_satp_ppn = 44'({$urandom, $urandom});
      w_io_csr_tlb_satp_changed = 1'($urandom);
      w_io_csr_tlb_vsatp_mode = 4'($urandom);
      w_io_csr_tlb_vsatp_asid = 16'($urandom);
      w_io_csr_tlb_vsatp_ppn = 44'({$urandom, $urandom});
      w_io_csr_tlb_vsatp_changed = 1'($urandom);
      w_io_csr_tlb_hgatp_mode = 4'($urandom);
      w_io_csr_tlb_hgatp_vmid = 16'($urandom);
      w_io_csr_tlb_hgatp_ppn = 44'({$urandom, $urandom});
      w_io_csr_tlb_hgatp_changed = 1'($urandom);
      w_io_csr_tlb_mbmc_BME = 1'($urandom);
      w_io_csr_tlb_mbmc_CMODE = 1'($urandom);
      w_io_csr_tlb_mbmc_BCLEAR = 1'($urandom);
      w_io_csr_tlb_mbmc_BMA = 58'({$urandom, $urandom});
      w_io_csr_tlb_priv_virt = 1'($urandom);
      w_io_csr_tlb_priv_virt_changed = 1'($urandom);
      w_io_csr_tlb_priv_debug = 1'($urandom);
      w_io_csr_tlb_mPBMTE = 1'($urandom);
      w_io_csr_tlb_hPBMTE = 1'($urandom);
      w_io_csr_distribute_csr_w_valid = 1'($urandom);
      w_io_csr_distribute_csr_w_bits_addr = 12'($urandom);
      w_io_csr_distribute_csr_w_bits_data = 64'({$urandom, $urandom});
      w_boreChildrenBd_bore_array = 6'($urandom);
      w_boreChildrenBd_bore_all = 1'($urandom);
      w_boreChildrenBd_bore_req = 1'($urandom);
      w_boreChildrenBd_bore_writeen = 1'($urandom);
      w_boreChildrenBd_bore_be = 2'($urandom);
      w_boreChildrenBd_bore_addr = 6'($urandom);
      w_boreChildrenBd_bore_indata = 90'({$urandom, $urandom, $urandom});
      w_boreChildrenBd_bore_readen = 1'($urandom);
      w_boreChildrenBd_bore_addr_rd = 6'($urandom);
      w_boreChildrenBd_bore_1_array = 6'($urandom);
      w_boreChildrenBd_bore_1_all = 1'($urandom);
      w_boreChildrenBd_bore_1_req = 1'($urandom);
      w_boreChildrenBd_bore_1_writeen = 1'($urandom);
      w_boreChildrenBd_bore_1_be = 1'($urandom);
      w_boreChildrenBd_bore_1_addr = 3'($urandom);
      w_boreChildrenBd_bore_1_indata = 131'({$urandom, $urandom, $urandom, $urandom, $urandom});
      w_boreChildrenBd_bore_1_readen = 1'($urandom);
      w_boreChildrenBd_bore_1_addr_rd = 3'($urandom);
      w_boreChildrenBd_bore_2_array = 7'($urandom);
      w_boreChildrenBd_bore_2_all = 1'($urandom);
      w_boreChildrenBd_bore_2_req = 1'($urandom);
      w_boreChildrenBd_bore_2_writeen = 1'($urandom);
      w_boreChildrenBd_bore_2_be = 2'($urandom);
      w_boreChildrenBd_bore_2_addr = 7'($urandom);
      w_boreChildrenBd_bore_2_indata = 114'({$urandom, $urandom, $urandom, $urandom});
      w_boreChildrenBd_bore_2_readen = 1'($urandom);
      w_boreChildrenBd_bore_2_addr_rd = 7'($urandom);
      w_sigFromSrams_bore_ram_hold = 1'($urandom);
      w_sigFromSrams_bore_ram_bypass = 1'($urandom);
      w_sigFromSrams_bore_ram_bp_clken = 1'($urandom);
      w_sigFromSrams_bore_ram_aux_clk = 1'($urandom);
      w_sigFromSrams_bore_ram_aux_ckbp = 1'($urandom);
      w_sigFromSrams_bore_ram_mcp_hold = 1'($urandom);
      w_sigFromSrams_bore_cgen = 1'($urandom);
      w_sigFromSrams_bore_1_ram_hold = 1'($urandom);
      w_sigFromSrams_bore_1_ram_bypass = 1'($urandom);
      w_sigFromSrams_bore_1_ram_bp_clken = 1'($urandom);
      w_sigFromSrams_bore_1_ram_aux_clk = 1'($urandom);
      w_sigFromSrams_bore_1_ram_aux_ckbp = 1'($urandom);
      w_sigFromSrams_bore_1_ram_mcp_hold = 1'($urandom);
      w_sigFromSrams_bore_1_cgen = 1'($urandom);
      w_sigFromSrams_bore_2_ram_hold = 1'($urandom);
      w_sigFromSrams_bore_2_ram_bypass = 1'($urandom);
      w_sigFromSrams_bore_2_ram_bp_clken = 1'($urandom);
      w_sigFromSrams_bore_2_ram_aux_clk = 1'($urandom);
      w_sigFromSrams_bore_2_ram_aux_ckbp = 1'($urandom);
      w_sigFromSrams_bore_2_ram_mcp_hold = 1'($urandom);
      w_sigFromSrams_bore_2_cgen = 1'($urandom);
      w_sigFromSrams_bore_3_ram_hold = 1'($urandom);
      w_sigFromSrams_bore_3_ram_bypass = 1'($urandom);
      w_sigFromSrams_bore_3_ram_bp_clken = 1'($urandom);
      w_sigFromSrams_bore_3_ram_aux_clk = 1'($urandom);
      w_sigFromSrams_bore_3_ram_aux_ckbp = 1'($urandom);
      w_sigFromSrams_bore_3_ram_mcp_hold = 1'($urandom);
      w_sigFromSrams_bore_3_cgen = 1'($urandom);
      w_sigFromSrams_bore_4_ram_hold = 1'($urandom);
      w_sigFromSrams_bore_4_ram_bypass = 1'($urandom);
      w_sigFromSrams_bore_4_ram_bp_clken = 1'($urandom);
      w_sigFromSrams_bore_4_ram_aux_clk = 1'($urandom);
      w_sigFromSrams_bore_4_ram_aux_ckbp = 1'($urandom);
      w_sigFromSrams_bore_4_ram_mcp_hold = 1'($urandom);
      w_sigFromSrams_bore_4_cgen = 1'($urandom);
      w_sigFromSrams_bore_5_ram_hold = 1'($urandom);
      w_sigFromSrams_bore_5_ram_bypass = 1'($urandom);
      w_sigFromSrams_bore_5_ram_bp_clken = 1'($urandom);
      w_sigFromSrams_bore_5_ram_aux_clk = 1'($urandom);
      w_sigFromSrams_bore_5_ram_aux_ckbp = 1'($urandom);
      w_sigFromSrams_bore_5_ram_mcp_hold = 1'($urandom);
      w_sigFromSrams_bore_5_cgen = 1'($urandom);
      w_sigFromSrams_bore_6_ram_hold = 1'($urandom);
      w_sigFromSrams_bore_6_ram_bypass = 1'($urandom);
      w_sigFromSrams_bore_6_ram_bp_clken = 1'($urandom);
      w_sigFromSrams_bore_6_ram_aux_clk = 1'($urandom);
      w_sigFromSrams_bore_6_ram_aux_ckbp = 1'($urandom);
      w_sigFromSrams_bore_6_ram_mcp_hold = 1'($urandom);
      w_sigFromSrams_bore_6_cgen = 1'($urandom);
      w_sigFromSrams_bore_7_ram_hold = 1'($urandom);
      w_sigFromSrams_bore_7_ram_bypass = 1'($urandom);
      w_sigFromSrams_bore_7_ram_bp_clken = 1'($urandom);
      w_sigFromSrams_bore_7_ram_aux_clk = 1'($urandom);
      w_sigFromSrams_bore_7_ram_aux_ckbp = 1'($urandom);
      w_sigFromSrams_bore_7_ram_mcp_hold = 1'($urandom);
      w_sigFromSrams_bore_7_cgen = 1'($urandom);
      w_sigFromSrams_bore_8_ram_hold = 1'($urandom);
      w_sigFromSrams_bore_8_ram_bypass = 1'($urandom);
      w_sigFromSrams_bore_8_ram_bp_clken = 1'($urandom);
      w_sigFromSrams_bore_8_ram_aux_clk = 1'($urandom);
      w_sigFromSrams_bore_8_ram_aux_ckbp = 1'($urandom);
      w_sigFromSrams_bore_8_ram_mcp_hold = 1'($urandom);
      w_sigFromSrams_bore_8_cgen = 1'($urandom);
      w_sigFromSrams_bore_9_ram_hold = 1'($urandom);
      w_sigFromSrams_bore_9_ram_bypass = 1'($urandom);
      w_sigFromSrams_bore_9_ram_bp_clken = 1'($urandom);
      w_sigFromSrams_bore_9_ram_aux_clk = 1'($urandom);
      w_sigFromSrams_bore_9_ram_aux_ckbp = 1'($urandom);
      w_sigFromSrams_bore_9_ram_mcp_hold = 1'($urandom);
      w_sigFromSrams_bore_9_cgen = 1'($urandom);
      w_sigFromSrams_bore_10_ram_hold = 1'($urandom);
      w_sigFromSrams_bore_10_ram_bypass = 1'($urandom);
      w_sigFromSrams_bore_10_ram_bp_clken = 1'($urandom);
      w_sigFromSrams_bore_10_ram_aux_clk = 1'($urandom);
      w_sigFromSrams_bore_10_ram_aux_ckbp = 1'($urandom);
      w_sigFromSrams_bore_10_ram_mcp_hold = 1'($urandom);
      w_sigFromSrams_bore_10_cgen = 1'($urandom);
      w_sigFromSrams_bore_11_ram_hold = 1'($urandom);
      w_sigFromSrams_bore_11_ram_bypass = 1'($urandom);
      w_sigFromSrams_bore_11_ram_bp_clken = 1'($urandom);
      w_sigFromSrams_bore_11_ram_aux_clk = 1'($urandom);
      w_sigFromSrams_bore_11_ram_aux_ckbp = 1'($urandom);
      w_sigFromSrams_bore_11_ram_mcp_hold = 1'($urandom);
      w_sigFromSrams_bore_11_cgen = 1'($urandom);
      w_sigFromSrams_bore_12_ram_hold = 1'($urandom);
      w_sigFromSrams_bore_12_ram_bypass = 1'($urandom);
      w_sigFromSrams_bore_12_ram_bp_clken = 1'($urandom);
      w_sigFromSrams_bore_12_ram_aux_clk = 1'($urandom);
      w_sigFromSrams_bore_12_ram_aux_ckbp = 1'($urandom);
      w_sigFromSrams_bore_12_ram_mcp_hold = 1'($urandom);
      w_sigFromSrams_bore_12_cgen = 1'($urandom);
      w_sigFromSrams_bore_13_ram_hold = 1'($urandom);
      w_sigFromSrams_bore_13_ram_bypass = 1'($urandom);
      w_sigFromSrams_bore_13_ram_bp_clken = 1'($urandom);
      w_sigFromSrams_bore_13_ram_aux_clk = 1'($urandom);
      w_sigFromSrams_bore_13_ram_aux_ckbp = 1'($urandom);
      w_sigFromSrams_bore_13_ram_mcp_hold = 1'($urandom);
      w_sigFromSrams_bore_13_cgen = 1'($urandom);
      w_sigFromSrams_bore_14_ram_hold = 1'($urandom);
      w_sigFromSrams_bore_14_ram_bypass = 1'($urandom);
      w_sigFromSrams_bore_14_ram_bp_clken = 1'($urandom);
      w_sigFromSrams_bore_14_ram_aux_clk = 1'($urandom);
      w_sigFromSrams_bore_14_ram_aux_ckbp = 1'($urandom);
      w_sigFromSrams_bore_14_ram_mcp_hold = 1'($urandom);
      w_sigFromSrams_bore_14_cgen = 1'($urandom);
      w_sigFromSrams_bore_15_ram_hold = 1'($urandom);
      w_sigFromSrams_bore_15_ram_bypass = 1'($urandom);
      w_sigFromSrams_bore_15_ram_bp_clken = 1'($urandom);
      w_sigFromSrams_bore_15_ram_aux_clk = 1'($urandom);
      w_sigFromSrams_bore_15_ram_aux_ckbp = 1'($urandom);
      w_sigFromSrams_bore_15_ram_mcp_hold = 1'($urandom);
      w_sigFromSrams_bore_15_cgen = 1'($urandom);
      w_sigFromSrams_bore_16_ram_hold = 1'($urandom);
      w_sigFromSrams_bore_16_ram_bypass = 1'($urandom);
      w_sigFromSrams_bore_16_ram_bp_clken = 1'($urandom);
      w_sigFromSrams_bore_16_ram_aux_clk = 1'($urandom);
      w_sigFromSrams_bore_16_ram_aux_ckbp = 1'($urandom);
      w_sigFromSrams_bore_16_ram_mcp_hold = 1'($urandom);
      w_sigFromSrams_bore_16_cgen = 1'($urandom);
      w_sigFromSrams_bore_17_ram_hold = 1'($urandom);
      w_sigFromSrams_bore_17_ram_bypass = 1'($urandom);
      w_sigFromSrams_bore_17_ram_bp_clken = 1'($urandom);
      w_sigFromSrams_bore_17_ram_aux_clk = 1'($urandom);
      w_sigFromSrams_bore_17_ram_aux_ckbp = 1'($urandom);
      w_sigFromSrams_bore_17_ram_mcp_hold = 1'($urandom);
      w_sigFromSrams_bore_17_cgen = 1'($urandom);
      w_sigFromSrams_bore_18_ram_hold = 1'($urandom);
      w_sigFromSrams_bore_18_ram_bypass = 1'($urandom);
      w_sigFromSrams_bore_18_ram_bp_clken = 1'($urandom);
      w_sigFromSrams_bore_18_ram_aux_clk = 1'($urandom);
      w_sigFromSrams_bore_18_ram_aux_ckbp = 1'($urandom);
      w_sigFromSrams_bore_18_ram_mcp_hold = 1'($urandom);
      w_sigFromSrams_bore_18_cgen = 1'($urandom);
      w_sigFromSrams_bore_19_ram_hold = 1'($urandom);
      w_sigFromSrams_bore_19_ram_bypass = 1'($urandom);
      w_sigFromSrams_bore_19_ram_bp_clken = 1'($urandom);
      w_sigFromSrams_bore_19_ram_aux_clk = 1'($urandom);
      w_sigFromSrams_bore_19_ram_aux_ckbp = 1'($urandom);
      w_sigFromSrams_bore_19_ram_mcp_hold = 1'($urandom);
      w_sigFromSrams_bore_19_cgen = 1'($urandom);
      w_sigFromSrams_bore_20_ram_hold = 1'($urandom);
      w_sigFromSrams_bore_20_ram_bypass = 1'($urandom);
      w_sigFromSrams_bore_20_ram_bp_clken = 1'($urandom);
      w_sigFromSrams_bore_20_ram_aux_clk = 1'($urandom);
      w_sigFromSrams_bore_20_ram_aux_ckbp = 1'($urandom);
      w_sigFromSrams_bore_20_ram_mcp_hold = 1'($urandom);
      w_sigFromSrams_bore_20_cgen = 1'($urandom);
      w_cg_bore_cgen = 1'($urandom);
      w_cg_bore_1_cgen = 1'($urandom);
      w_reset = (cyc < RESET_CYC) || ($urandom_range(0, 19999) == 0);
      #4;
      w_armed = 1'b1;
      if (cyc >= RESET_CYC + 0 && (&w_armed)) begin
        checks++;
        if (w_g_auto_out_a_valid !== w_i_auto_out_a_valid) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d L2TLBWrapper.auto_out_a_valid g=%h i=%h", cyc, w_g_auto_out_a_valid, w_i_auto_out_a_valid);
        end
        w_s1_auto_out_a_valid |= w_g_auto_out_a_valid;
        w_s0_auto_out_a_valid |= ~w_g_auto_out_a_valid;
        checks++;
        if (w_g_auto_out_a_bits_source !== w_i_auto_out_a_bits_source) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d L2TLBWrapper.auto_out_a_bits_source g=%h i=%h", cyc, w_g_auto_out_a_bits_source, w_i_auto_out_a_bits_source);
        end
        w_s1_auto_out_a_bits_source |= w_g_auto_out_a_bits_source;
        w_s0_auto_out_a_bits_source |= ~w_g_auto_out_a_bits_source;
        checks++;
        if (w_g_auto_out_a_bits_address !== w_i_auto_out_a_bits_address) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d L2TLBWrapper.auto_out_a_bits_address g=%h i=%h", cyc, w_g_auto_out_a_bits_address, w_i_auto_out_a_bits_address);
        end
        w_s1_auto_out_a_bits_address |= w_g_auto_out_a_bits_address;
        w_s0_auto_out_a_bits_address |= ~w_g_auto_out_a_bits_address;
        checks++;
        if (w_g_io_tlb_0_req_0_ready !== w_i_io_tlb_0_req_0_ready) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d L2TLBWrapper.io_tlb_0_req_0_ready g=%h i=%h", cyc, w_g_io_tlb_0_req_0_ready, w_i_io_tlb_0_req_0_ready);
        end
        w_s1_io_tlb_0_req_0_ready |= w_g_io_tlb_0_req_0_ready;
        w_s0_io_tlb_0_req_0_ready |= ~w_g_io_tlb_0_req_0_ready;
        checks++;
        if (w_g_io_tlb_0_resp_valid !== w_i_io_tlb_0_resp_valid) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d L2TLBWrapper.io_tlb_0_resp_valid g=%h i=%h", cyc, w_g_io_tlb_0_resp_valid, w_i_io_tlb_0_resp_valid);
        end
        w_s1_io_tlb_0_resp_valid |= w_g_io_tlb_0_resp_valid;
        w_s0_io_tlb_0_resp_valid |= ~w_g_io_tlb_0_resp_valid;
        checks++;
        if (w_g_io_tlb_0_resp_bits_s2xlate !== w_i_io_tlb_0_resp_bits_s2xlate) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d L2TLBWrapper.io_tlb_0_resp_bits_s2xlate g=%h i=%h", cyc, w_g_io_tlb_0_resp_bits_s2xlate, w_i_io_tlb_0_resp_bits_s2xlate);
        end
        w_s1_io_tlb_0_resp_bits_s2xlate |= w_g_io_tlb_0_resp_bits_s2xlate;
        w_s0_io_tlb_0_resp_bits_s2xlate |= ~w_g_io_tlb_0_resp_bits_s2xlate;
        checks++;
        if (w_g_io_tlb_0_resp_bits_s1_entry_tag !== w_i_io_tlb_0_resp_bits_s1_entry_tag) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d L2TLBWrapper.io_tlb_0_resp_bits_s1_entry_tag g=%h i=%h", cyc, w_g_io_tlb_0_resp_bits_s1_entry_tag, w_i_io_tlb_0_resp_bits_s1_entry_tag);
        end
        w_s1_io_tlb_0_resp_bits_s1_entry_tag |= w_g_io_tlb_0_resp_bits_s1_entry_tag;
        w_s0_io_tlb_0_resp_bits_s1_entry_tag |= ~w_g_io_tlb_0_resp_bits_s1_entry_tag;
        checks++;
        if (w_g_io_tlb_0_resp_bits_s1_entry_asid !== w_i_io_tlb_0_resp_bits_s1_entry_asid) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d L2TLBWrapper.io_tlb_0_resp_bits_s1_entry_asid g=%h i=%h", cyc, w_g_io_tlb_0_resp_bits_s1_entry_asid, w_i_io_tlb_0_resp_bits_s1_entry_asid);
        end
        w_s1_io_tlb_0_resp_bits_s1_entry_asid |= w_g_io_tlb_0_resp_bits_s1_entry_asid;
        w_s0_io_tlb_0_resp_bits_s1_entry_asid |= ~w_g_io_tlb_0_resp_bits_s1_entry_asid;
        checks++;
        if (w_g_io_tlb_0_resp_bits_s1_entry_vmid !== w_i_io_tlb_0_resp_bits_s1_entry_vmid) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d L2TLBWrapper.io_tlb_0_resp_bits_s1_entry_vmid g=%h i=%h", cyc, w_g_io_tlb_0_resp_bits_s1_entry_vmid, w_i_io_tlb_0_resp_bits_s1_entry_vmid);
        end
        w_s1_io_tlb_0_resp_bits_s1_entry_vmid |= w_g_io_tlb_0_resp_bits_s1_entry_vmid;
        w_s0_io_tlb_0_resp_bits_s1_entry_vmid |= ~w_g_io_tlb_0_resp_bits_s1_entry_vmid;
        checks++;
        if (w_g_io_tlb_0_resp_bits_s1_entry_n !== w_i_io_tlb_0_resp_bits_s1_entry_n) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d L2TLBWrapper.io_tlb_0_resp_bits_s1_entry_n g=%h i=%h", cyc, w_g_io_tlb_0_resp_bits_s1_entry_n, w_i_io_tlb_0_resp_bits_s1_entry_n);
        end
        w_s1_io_tlb_0_resp_bits_s1_entry_n |= w_g_io_tlb_0_resp_bits_s1_entry_n;
        w_s0_io_tlb_0_resp_bits_s1_entry_n |= ~w_g_io_tlb_0_resp_bits_s1_entry_n;
        checks++;
        if (w_g_io_tlb_0_resp_bits_s1_entry_pbmt !== w_i_io_tlb_0_resp_bits_s1_entry_pbmt) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d L2TLBWrapper.io_tlb_0_resp_bits_s1_entry_pbmt g=%h i=%h", cyc, w_g_io_tlb_0_resp_bits_s1_entry_pbmt, w_i_io_tlb_0_resp_bits_s1_entry_pbmt);
        end
        w_s1_io_tlb_0_resp_bits_s1_entry_pbmt |= w_g_io_tlb_0_resp_bits_s1_entry_pbmt;
        w_s0_io_tlb_0_resp_bits_s1_entry_pbmt |= ~w_g_io_tlb_0_resp_bits_s1_entry_pbmt;
        checks++;
        if (w_g_io_tlb_0_resp_bits_s1_entry_perm_d !== w_i_io_tlb_0_resp_bits_s1_entry_perm_d) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d L2TLBWrapper.io_tlb_0_resp_bits_s1_entry_perm_d g=%h i=%h", cyc, w_g_io_tlb_0_resp_bits_s1_entry_perm_d, w_i_io_tlb_0_resp_bits_s1_entry_perm_d);
        end
        w_s1_io_tlb_0_resp_bits_s1_entry_perm_d |= w_g_io_tlb_0_resp_bits_s1_entry_perm_d;
        w_s0_io_tlb_0_resp_bits_s1_entry_perm_d |= ~w_g_io_tlb_0_resp_bits_s1_entry_perm_d;
        checks++;
        if (w_g_io_tlb_0_resp_bits_s1_entry_perm_a !== w_i_io_tlb_0_resp_bits_s1_entry_perm_a) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d L2TLBWrapper.io_tlb_0_resp_bits_s1_entry_perm_a g=%h i=%h", cyc, w_g_io_tlb_0_resp_bits_s1_entry_perm_a, w_i_io_tlb_0_resp_bits_s1_entry_perm_a);
        end
        w_s1_io_tlb_0_resp_bits_s1_entry_perm_a |= w_g_io_tlb_0_resp_bits_s1_entry_perm_a;
        w_s0_io_tlb_0_resp_bits_s1_entry_perm_a |= ~w_g_io_tlb_0_resp_bits_s1_entry_perm_a;
        checks++;
        if (w_g_io_tlb_0_resp_bits_s1_entry_perm_g !== w_i_io_tlb_0_resp_bits_s1_entry_perm_g) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d L2TLBWrapper.io_tlb_0_resp_bits_s1_entry_perm_g g=%h i=%h", cyc, w_g_io_tlb_0_resp_bits_s1_entry_perm_g, w_i_io_tlb_0_resp_bits_s1_entry_perm_g);
        end
        w_s1_io_tlb_0_resp_bits_s1_entry_perm_g |= w_g_io_tlb_0_resp_bits_s1_entry_perm_g;
        w_s0_io_tlb_0_resp_bits_s1_entry_perm_g |= ~w_g_io_tlb_0_resp_bits_s1_entry_perm_g;
        checks++;
        if (w_g_io_tlb_0_resp_bits_s1_entry_perm_u !== w_i_io_tlb_0_resp_bits_s1_entry_perm_u) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d L2TLBWrapper.io_tlb_0_resp_bits_s1_entry_perm_u g=%h i=%h", cyc, w_g_io_tlb_0_resp_bits_s1_entry_perm_u, w_i_io_tlb_0_resp_bits_s1_entry_perm_u);
        end
        w_s1_io_tlb_0_resp_bits_s1_entry_perm_u |= w_g_io_tlb_0_resp_bits_s1_entry_perm_u;
        w_s0_io_tlb_0_resp_bits_s1_entry_perm_u |= ~w_g_io_tlb_0_resp_bits_s1_entry_perm_u;
        checks++;
        if (w_g_io_tlb_0_resp_bits_s1_entry_perm_x !== w_i_io_tlb_0_resp_bits_s1_entry_perm_x) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d L2TLBWrapper.io_tlb_0_resp_bits_s1_entry_perm_x g=%h i=%h", cyc, w_g_io_tlb_0_resp_bits_s1_entry_perm_x, w_i_io_tlb_0_resp_bits_s1_entry_perm_x);
        end
        w_s1_io_tlb_0_resp_bits_s1_entry_perm_x |= w_g_io_tlb_0_resp_bits_s1_entry_perm_x;
        w_s0_io_tlb_0_resp_bits_s1_entry_perm_x |= ~w_g_io_tlb_0_resp_bits_s1_entry_perm_x;
        checks++;
        if (w_g_io_tlb_0_resp_bits_s1_entry_perm_w !== w_i_io_tlb_0_resp_bits_s1_entry_perm_w) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d L2TLBWrapper.io_tlb_0_resp_bits_s1_entry_perm_w g=%h i=%h", cyc, w_g_io_tlb_0_resp_bits_s1_entry_perm_w, w_i_io_tlb_0_resp_bits_s1_entry_perm_w);
        end
        w_s1_io_tlb_0_resp_bits_s1_entry_perm_w |= w_g_io_tlb_0_resp_bits_s1_entry_perm_w;
        w_s0_io_tlb_0_resp_bits_s1_entry_perm_w |= ~w_g_io_tlb_0_resp_bits_s1_entry_perm_w;
        checks++;
        if (w_g_io_tlb_0_resp_bits_s1_entry_perm_r !== w_i_io_tlb_0_resp_bits_s1_entry_perm_r) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d L2TLBWrapper.io_tlb_0_resp_bits_s1_entry_perm_r g=%h i=%h", cyc, w_g_io_tlb_0_resp_bits_s1_entry_perm_r, w_i_io_tlb_0_resp_bits_s1_entry_perm_r);
        end
        w_s1_io_tlb_0_resp_bits_s1_entry_perm_r |= w_g_io_tlb_0_resp_bits_s1_entry_perm_r;
        w_s0_io_tlb_0_resp_bits_s1_entry_perm_r |= ~w_g_io_tlb_0_resp_bits_s1_entry_perm_r;
        checks++;
        if (w_g_io_tlb_0_resp_bits_s1_entry_level !== w_i_io_tlb_0_resp_bits_s1_entry_level) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d L2TLBWrapper.io_tlb_0_resp_bits_s1_entry_level g=%h i=%h", cyc, w_g_io_tlb_0_resp_bits_s1_entry_level, w_i_io_tlb_0_resp_bits_s1_entry_level);
        end
        w_s1_io_tlb_0_resp_bits_s1_entry_level |= w_g_io_tlb_0_resp_bits_s1_entry_level;
        w_s0_io_tlb_0_resp_bits_s1_entry_level |= ~w_g_io_tlb_0_resp_bits_s1_entry_level;
        checks++;
        if (w_g_io_tlb_0_resp_bits_s1_entry_v !== w_i_io_tlb_0_resp_bits_s1_entry_v) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d L2TLBWrapper.io_tlb_0_resp_bits_s1_entry_v g=%h i=%h", cyc, w_g_io_tlb_0_resp_bits_s1_entry_v, w_i_io_tlb_0_resp_bits_s1_entry_v);
        end
        w_s1_io_tlb_0_resp_bits_s1_entry_v |= w_g_io_tlb_0_resp_bits_s1_entry_v;
        w_s0_io_tlb_0_resp_bits_s1_entry_v |= ~w_g_io_tlb_0_resp_bits_s1_entry_v;
        checks++;
        if (w_g_io_tlb_0_resp_bits_s1_entry_ppn !== w_i_io_tlb_0_resp_bits_s1_entry_ppn) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d L2TLBWrapper.io_tlb_0_resp_bits_s1_entry_ppn g=%h i=%h", cyc, w_g_io_tlb_0_resp_bits_s1_entry_ppn, w_i_io_tlb_0_resp_bits_s1_entry_ppn);
        end
        w_s1_io_tlb_0_resp_bits_s1_entry_ppn |= w_g_io_tlb_0_resp_bits_s1_entry_ppn;
        w_s0_io_tlb_0_resp_bits_s1_entry_ppn |= ~w_g_io_tlb_0_resp_bits_s1_entry_ppn;
        checks++;
        if (w_g_io_tlb_0_resp_bits_s1_addr_low !== w_i_io_tlb_0_resp_bits_s1_addr_low) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d L2TLBWrapper.io_tlb_0_resp_bits_s1_addr_low g=%h i=%h", cyc, w_g_io_tlb_0_resp_bits_s1_addr_low, w_i_io_tlb_0_resp_bits_s1_addr_low);
        end
        w_s1_io_tlb_0_resp_bits_s1_addr_low |= w_g_io_tlb_0_resp_bits_s1_addr_low;
        w_s0_io_tlb_0_resp_bits_s1_addr_low |= ~w_g_io_tlb_0_resp_bits_s1_addr_low;
        checks++;
        if (w_g_io_tlb_0_resp_bits_s1_ppn_low_0 !== w_i_io_tlb_0_resp_bits_s1_ppn_low_0) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d L2TLBWrapper.io_tlb_0_resp_bits_s1_ppn_low_0 g=%h i=%h", cyc, w_g_io_tlb_0_resp_bits_s1_ppn_low_0, w_i_io_tlb_0_resp_bits_s1_ppn_low_0);
        end
        w_s1_io_tlb_0_resp_bits_s1_ppn_low_0 |= w_g_io_tlb_0_resp_bits_s1_ppn_low_0;
        w_s0_io_tlb_0_resp_bits_s1_ppn_low_0 |= ~w_g_io_tlb_0_resp_bits_s1_ppn_low_0;
        checks++;
        if (w_g_io_tlb_0_resp_bits_s1_ppn_low_1 !== w_i_io_tlb_0_resp_bits_s1_ppn_low_1) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d L2TLBWrapper.io_tlb_0_resp_bits_s1_ppn_low_1 g=%h i=%h", cyc, w_g_io_tlb_0_resp_bits_s1_ppn_low_1, w_i_io_tlb_0_resp_bits_s1_ppn_low_1);
        end
        w_s1_io_tlb_0_resp_bits_s1_ppn_low_1 |= w_g_io_tlb_0_resp_bits_s1_ppn_low_1;
        w_s0_io_tlb_0_resp_bits_s1_ppn_low_1 |= ~w_g_io_tlb_0_resp_bits_s1_ppn_low_1;
        checks++;
        if (w_g_io_tlb_0_resp_bits_s1_ppn_low_2 !== w_i_io_tlb_0_resp_bits_s1_ppn_low_2) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d L2TLBWrapper.io_tlb_0_resp_bits_s1_ppn_low_2 g=%h i=%h", cyc, w_g_io_tlb_0_resp_bits_s1_ppn_low_2, w_i_io_tlb_0_resp_bits_s1_ppn_low_2);
        end
        w_s1_io_tlb_0_resp_bits_s1_ppn_low_2 |= w_g_io_tlb_0_resp_bits_s1_ppn_low_2;
        w_s0_io_tlb_0_resp_bits_s1_ppn_low_2 |= ~w_g_io_tlb_0_resp_bits_s1_ppn_low_2;
        checks++;
        if (w_g_io_tlb_0_resp_bits_s1_ppn_low_3 !== w_i_io_tlb_0_resp_bits_s1_ppn_low_3) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d L2TLBWrapper.io_tlb_0_resp_bits_s1_ppn_low_3 g=%h i=%h", cyc, w_g_io_tlb_0_resp_bits_s1_ppn_low_3, w_i_io_tlb_0_resp_bits_s1_ppn_low_3);
        end
        w_s1_io_tlb_0_resp_bits_s1_ppn_low_3 |= w_g_io_tlb_0_resp_bits_s1_ppn_low_3;
        w_s0_io_tlb_0_resp_bits_s1_ppn_low_3 |= ~w_g_io_tlb_0_resp_bits_s1_ppn_low_3;
        checks++;
        if (w_g_io_tlb_0_resp_bits_s1_ppn_low_4 !== w_i_io_tlb_0_resp_bits_s1_ppn_low_4) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d L2TLBWrapper.io_tlb_0_resp_bits_s1_ppn_low_4 g=%h i=%h", cyc, w_g_io_tlb_0_resp_bits_s1_ppn_low_4, w_i_io_tlb_0_resp_bits_s1_ppn_low_4);
        end
        w_s1_io_tlb_0_resp_bits_s1_ppn_low_4 |= w_g_io_tlb_0_resp_bits_s1_ppn_low_4;
        w_s0_io_tlb_0_resp_bits_s1_ppn_low_4 |= ~w_g_io_tlb_0_resp_bits_s1_ppn_low_4;
        checks++;
        if (w_g_io_tlb_0_resp_bits_s1_ppn_low_5 !== w_i_io_tlb_0_resp_bits_s1_ppn_low_5) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d L2TLBWrapper.io_tlb_0_resp_bits_s1_ppn_low_5 g=%h i=%h", cyc, w_g_io_tlb_0_resp_bits_s1_ppn_low_5, w_i_io_tlb_0_resp_bits_s1_ppn_low_5);
        end
        w_s1_io_tlb_0_resp_bits_s1_ppn_low_5 |= w_g_io_tlb_0_resp_bits_s1_ppn_low_5;
        w_s0_io_tlb_0_resp_bits_s1_ppn_low_5 |= ~w_g_io_tlb_0_resp_bits_s1_ppn_low_5;
        checks++;
        if (w_g_io_tlb_0_resp_bits_s1_ppn_low_6 !== w_i_io_tlb_0_resp_bits_s1_ppn_low_6) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d L2TLBWrapper.io_tlb_0_resp_bits_s1_ppn_low_6 g=%h i=%h", cyc, w_g_io_tlb_0_resp_bits_s1_ppn_low_6, w_i_io_tlb_0_resp_bits_s1_ppn_low_6);
        end
        w_s1_io_tlb_0_resp_bits_s1_ppn_low_6 |= w_g_io_tlb_0_resp_bits_s1_ppn_low_6;
        w_s0_io_tlb_0_resp_bits_s1_ppn_low_6 |= ~w_g_io_tlb_0_resp_bits_s1_ppn_low_6;
        checks++;
        if (w_g_io_tlb_0_resp_bits_s1_ppn_low_7 !== w_i_io_tlb_0_resp_bits_s1_ppn_low_7) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d L2TLBWrapper.io_tlb_0_resp_bits_s1_ppn_low_7 g=%h i=%h", cyc, w_g_io_tlb_0_resp_bits_s1_ppn_low_7, w_i_io_tlb_0_resp_bits_s1_ppn_low_7);
        end
        w_s1_io_tlb_0_resp_bits_s1_ppn_low_7 |= w_g_io_tlb_0_resp_bits_s1_ppn_low_7;
        w_s0_io_tlb_0_resp_bits_s1_ppn_low_7 |= ~w_g_io_tlb_0_resp_bits_s1_ppn_low_7;
        checks++;
        if (w_g_io_tlb_0_resp_bits_s1_valididx_0 !== w_i_io_tlb_0_resp_bits_s1_valididx_0) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d L2TLBWrapper.io_tlb_0_resp_bits_s1_valididx_0 g=%h i=%h", cyc, w_g_io_tlb_0_resp_bits_s1_valididx_0, w_i_io_tlb_0_resp_bits_s1_valididx_0);
        end
        w_s1_io_tlb_0_resp_bits_s1_valididx_0 |= w_g_io_tlb_0_resp_bits_s1_valididx_0;
        w_s0_io_tlb_0_resp_bits_s1_valididx_0 |= ~w_g_io_tlb_0_resp_bits_s1_valididx_0;
        checks++;
        if (w_g_io_tlb_0_resp_bits_s1_valididx_1 !== w_i_io_tlb_0_resp_bits_s1_valididx_1) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d L2TLBWrapper.io_tlb_0_resp_bits_s1_valididx_1 g=%h i=%h", cyc, w_g_io_tlb_0_resp_bits_s1_valididx_1, w_i_io_tlb_0_resp_bits_s1_valididx_1);
        end
        w_s1_io_tlb_0_resp_bits_s1_valididx_1 |= w_g_io_tlb_0_resp_bits_s1_valididx_1;
        w_s0_io_tlb_0_resp_bits_s1_valididx_1 |= ~w_g_io_tlb_0_resp_bits_s1_valididx_1;
        checks++;
        if (w_g_io_tlb_0_resp_bits_s1_valididx_2 !== w_i_io_tlb_0_resp_bits_s1_valididx_2) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d L2TLBWrapper.io_tlb_0_resp_bits_s1_valididx_2 g=%h i=%h", cyc, w_g_io_tlb_0_resp_bits_s1_valididx_2, w_i_io_tlb_0_resp_bits_s1_valididx_2);
        end
        w_s1_io_tlb_0_resp_bits_s1_valididx_2 |= w_g_io_tlb_0_resp_bits_s1_valididx_2;
        w_s0_io_tlb_0_resp_bits_s1_valididx_2 |= ~w_g_io_tlb_0_resp_bits_s1_valididx_2;
        checks++;
        if (w_g_io_tlb_0_resp_bits_s1_valididx_3 !== w_i_io_tlb_0_resp_bits_s1_valididx_3) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d L2TLBWrapper.io_tlb_0_resp_bits_s1_valididx_3 g=%h i=%h", cyc, w_g_io_tlb_0_resp_bits_s1_valididx_3, w_i_io_tlb_0_resp_bits_s1_valididx_3);
        end
        w_s1_io_tlb_0_resp_bits_s1_valididx_3 |= w_g_io_tlb_0_resp_bits_s1_valididx_3;
        w_s0_io_tlb_0_resp_bits_s1_valididx_3 |= ~w_g_io_tlb_0_resp_bits_s1_valididx_3;
        checks++;
        if (w_g_io_tlb_0_resp_bits_s1_valididx_4 !== w_i_io_tlb_0_resp_bits_s1_valididx_4) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d L2TLBWrapper.io_tlb_0_resp_bits_s1_valididx_4 g=%h i=%h", cyc, w_g_io_tlb_0_resp_bits_s1_valididx_4, w_i_io_tlb_0_resp_bits_s1_valididx_4);
        end
        w_s1_io_tlb_0_resp_bits_s1_valididx_4 |= w_g_io_tlb_0_resp_bits_s1_valididx_4;
        w_s0_io_tlb_0_resp_bits_s1_valididx_4 |= ~w_g_io_tlb_0_resp_bits_s1_valididx_4;
        checks++;
        if (w_g_io_tlb_0_resp_bits_s1_valididx_5 !== w_i_io_tlb_0_resp_bits_s1_valididx_5) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d L2TLBWrapper.io_tlb_0_resp_bits_s1_valididx_5 g=%h i=%h", cyc, w_g_io_tlb_0_resp_bits_s1_valididx_5, w_i_io_tlb_0_resp_bits_s1_valididx_5);
        end
        w_s1_io_tlb_0_resp_bits_s1_valididx_5 |= w_g_io_tlb_0_resp_bits_s1_valididx_5;
        w_s0_io_tlb_0_resp_bits_s1_valididx_5 |= ~w_g_io_tlb_0_resp_bits_s1_valididx_5;
        checks++;
        if (w_g_io_tlb_0_resp_bits_s1_valididx_6 !== w_i_io_tlb_0_resp_bits_s1_valididx_6) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d L2TLBWrapper.io_tlb_0_resp_bits_s1_valididx_6 g=%h i=%h", cyc, w_g_io_tlb_0_resp_bits_s1_valididx_6, w_i_io_tlb_0_resp_bits_s1_valididx_6);
        end
        w_s1_io_tlb_0_resp_bits_s1_valididx_6 |= w_g_io_tlb_0_resp_bits_s1_valididx_6;
        w_s0_io_tlb_0_resp_bits_s1_valididx_6 |= ~w_g_io_tlb_0_resp_bits_s1_valididx_6;
        checks++;
        if (w_g_io_tlb_0_resp_bits_s1_valididx_7 !== w_i_io_tlb_0_resp_bits_s1_valididx_7) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d L2TLBWrapper.io_tlb_0_resp_bits_s1_valididx_7 g=%h i=%h", cyc, w_g_io_tlb_0_resp_bits_s1_valididx_7, w_i_io_tlb_0_resp_bits_s1_valididx_7);
        end
        w_s1_io_tlb_0_resp_bits_s1_valididx_7 |= w_g_io_tlb_0_resp_bits_s1_valididx_7;
        w_s0_io_tlb_0_resp_bits_s1_valididx_7 |= ~w_g_io_tlb_0_resp_bits_s1_valididx_7;
        checks++;
        if (w_g_io_tlb_0_resp_bits_s1_pteidx_0 !== w_i_io_tlb_0_resp_bits_s1_pteidx_0) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d L2TLBWrapper.io_tlb_0_resp_bits_s1_pteidx_0 g=%h i=%h", cyc, w_g_io_tlb_0_resp_bits_s1_pteidx_0, w_i_io_tlb_0_resp_bits_s1_pteidx_0);
        end
        w_s1_io_tlb_0_resp_bits_s1_pteidx_0 |= w_g_io_tlb_0_resp_bits_s1_pteidx_0;
        w_s0_io_tlb_0_resp_bits_s1_pteidx_0 |= ~w_g_io_tlb_0_resp_bits_s1_pteidx_0;
        checks++;
        if (w_g_io_tlb_0_resp_bits_s1_pteidx_1 !== w_i_io_tlb_0_resp_bits_s1_pteidx_1) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d L2TLBWrapper.io_tlb_0_resp_bits_s1_pteidx_1 g=%h i=%h", cyc, w_g_io_tlb_0_resp_bits_s1_pteidx_1, w_i_io_tlb_0_resp_bits_s1_pteidx_1);
        end
        w_s1_io_tlb_0_resp_bits_s1_pteidx_1 |= w_g_io_tlb_0_resp_bits_s1_pteidx_1;
        w_s0_io_tlb_0_resp_bits_s1_pteidx_1 |= ~w_g_io_tlb_0_resp_bits_s1_pteidx_1;
        checks++;
        if (w_g_io_tlb_0_resp_bits_s1_pteidx_2 !== w_i_io_tlb_0_resp_bits_s1_pteidx_2) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d L2TLBWrapper.io_tlb_0_resp_bits_s1_pteidx_2 g=%h i=%h", cyc, w_g_io_tlb_0_resp_bits_s1_pteidx_2, w_i_io_tlb_0_resp_bits_s1_pteidx_2);
        end
        w_s1_io_tlb_0_resp_bits_s1_pteidx_2 |= w_g_io_tlb_0_resp_bits_s1_pteidx_2;
        w_s0_io_tlb_0_resp_bits_s1_pteidx_2 |= ~w_g_io_tlb_0_resp_bits_s1_pteidx_2;
        checks++;
        if (w_g_io_tlb_0_resp_bits_s1_pteidx_3 !== w_i_io_tlb_0_resp_bits_s1_pteidx_3) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d L2TLBWrapper.io_tlb_0_resp_bits_s1_pteidx_3 g=%h i=%h", cyc, w_g_io_tlb_0_resp_bits_s1_pteidx_3, w_i_io_tlb_0_resp_bits_s1_pteidx_3);
        end
        w_s1_io_tlb_0_resp_bits_s1_pteidx_3 |= w_g_io_tlb_0_resp_bits_s1_pteidx_3;
        w_s0_io_tlb_0_resp_bits_s1_pteidx_3 |= ~w_g_io_tlb_0_resp_bits_s1_pteidx_3;
        checks++;
        if (w_g_io_tlb_0_resp_bits_s1_pteidx_4 !== w_i_io_tlb_0_resp_bits_s1_pteidx_4) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d L2TLBWrapper.io_tlb_0_resp_bits_s1_pteidx_4 g=%h i=%h", cyc, w_g_io_tlb_0_resp_bits_s1_pteidx_4, w_i_io_tlb_0_resp_bits_s1_pteidx_4);
        end
        w_s1_io_tlb_0_resp_bits_s1_pteidx_4 |= w_g_io_tlb_0_resp_bits_s1_pteidx_4;
        w_s0_io_tlb_0_resp_bits_s1_pteidx_4 |= ~w_g_io_tlb_0_resp_bits_s1_pteidx_4;
        checks++;
        if (w_g_io_tlb_0_resp_bits_s1_pteidx_5 !== w_i_io_tlb_0_resp_bits_s1_pteidx_5) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d L2TLBWrapper.io_tlb_0_resp_bits_s1_pteidx_5 g=%h i=%h", cyc, w_g_io_tlb_0_resp_bits_s1_pteidx_5, w_i_io_tlb_0_resp_bits_s1_pteidx_5);
        end
        w_s1_io_tlb_0_resp_bits_s1_pteidx_5 |= w_g_io_tlb_0_resp_bits_s1_pteidx_5;
        w_s0_io_tlb_0_resp_bits_s1_pteidx_5 |= ~w_g_io_tlb_0_resp_bits_s1_pteidx_5;
        checks++;
        if (w_g_io_tlb_0_resp_bits_s1_pteidx_6 !== w_i_io_tlb_0_resp_bits_s1_pteidx_6) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d L2TLBWrapper.io_tlb_0_resp_bits_s1_pteidx_6 g=%h i=%h", cyc, w_g_io_tlb_0_resp_bits_s1_pteidx_6, w_i_io_tlb_0_resp_bits_s1_pteidx_6);
        end
        w_s1_io_tlb_0_resp_bits_s1_pteidx_6 |= w_g_io_tlb_0_resp_bits_s1_pteidx_6;
        w_s0_io_tlb_0_resp_bits_s1_pteidx_6 |= ~w_g_io_tlb_0_resp_bits_s1_pteidx_6;
        checks++;
        if (w_g_io_tlb_0_resp_bits_s1_pteidx_7 !== w_i_io_tlb_0_resp_bits_s1_pteidx_7) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d L2TLBWrapper.io_tlb_0_resp_bits_s1_pteidx_7 g=%h i=%h", cyc, w_g_io_tlb_0_resp_bits_s1_pteidx_7, w_i_io_tlb_0_resp_bits_s1_pteidx_7);
        end
        w_s1_io_tlb_0_resp_bits_s1_pteidx_7 |= w_g_io_tlb_0_resp_bits_s1_pteidx_7;
        w_s0_io_tlb_0_resp_bits_s1_pteidx_7 |= ~w_g_io_tlb_0_resp_bits_s1_pteidx_7;
        checks++;
        if (w_g_io_tlb_0_resp_bits_s1_pf !== w_i_io_tlb_0_resp_bits_s1_pf) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d L2TLBWrapper.io_tlb_0_resp_bits_s1_pf g=%h i=%h", cyc, w_g_io_tlb_0_resp_bits_s1_pf, w_i_io_tlb_0_resp_bits_s1_pf);
        end
        w_s1_io_tlb_0_resp_bits_s1_pf |= w_g_io_tlb_0_resp_bits_s1_pf;
        w_s0_io_tlb_0_resp_bits_s1_pf |= ~w_g_io_tlb_0_resp_bits_s1_pf;
        checks++;
        if (w_g_io_tlb_0_resp_bits_s1_af !== w_i_io_tlb_0_resp_bits_s1_af) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d L2TLBWrapper.io_tlb_0_resp_bits_s1_af g=%h i=%h", cyc, w_g_io_tlb_0_resp_bits_s1_af, w_i_io_tlb_0_resp_bits_s1_af);
        end
        w_s1_io_tlb_0_resp_bits_s1_af |= w_g_io_tlb_0_resp_bits_s1_af;
        w_s0_io_tlb_0_resp_bits_s1_af |= ~w_g_io_tlb_0_resp_bits_s1_af;
        checks++;
        if (w_g_io_tlb_0_resp_bits_s2_entry_tag !== w_i_io_tlb_0_resp_bits_s2_entry_tag) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d L2TLBWrapper.io_tlb_0_resp_bits_s2_entry_tag g=%h i=%h", cyc, w_g_io_tlb_0_resp_bits_s2_entry_tag, w_i_io_tlb_0_resp_bits_s2_entry_tag);
        end
        w_s1_io_tlb_0_resp_bits_s2_entry_tag |= w_g_io_tlb_0_resp_bits_s2_entry_tag;
        w_s0_io_tlb_0_resp_bits_s2_entry_tag |= ~w_g_io_tlb_0_resp_bits_s2_entry_tag;
        checks++;
        if (w_g_io_tlb_0_resp_bits_s2_entry_vmid !== w_i_io_tlb_0_resp_bits_s2_entry_vmid) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d L2TLBWrapper.io_tlb_0_resp_bits_s2_entry_vmid g=%h i=%h", cyc, w_g_io_tlb_0_resp_bits_s2_entry_vmid, w_i_io_tlb_0_resp_bits_s2_entry_vmid);
        end
        w_s1_io_tlb_0_resp_bits_s2_entry_vmid |= w_g_io_tlb_0_resp_bits_s2_entry_vmid;
        w_s0_io_tlb_0_resp_bits_s2_entry_vmid |= ~w_g_io_tlb_0_resp_bits_s2_entry_vmid;
        checks++;
        if (w_g_io_tlb_0_resp_bits_s2_entry_n !== w_i_io_tlb_0_resp_bits_s2_entry_n) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d L2TLBWrapper.io_tlb_0_resp_bits_s2_entry_n g=%h i=%h", cyc, w_g_io_tlb_0_resp_bits_s2_entry_n, w_i_io_tlb_0_resp_bits_s2_entry_n);
        end
        w_s1_io_tlb_0_resp_bits_s2_entry_n |= w_g_io_tlb_0_resp_bits_s2_entry_n;
        w_s0_io_tlb_0_resp_bits_s2_entry_n |= ~w_g_io_tlb_0_resp_bits_s2_entry_n;
        checks++;
        if (w_g_io_tlb_0_resp_bits_s2_entry_pbmt !== w_i_io_tlb_0_resp_bits_s2_entry_pbmt) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d L2TLBWrapper.io_tlb_0_resp_bits_s2_entry_pbmt g=%h i=%h", cyc, w_g_io_tlb_0_resp_bits_s2_entry_pbmt, w_i_io_tlb_0_resp_bits_s2_entry_pbmt);
        end
        w_s1_io_tlb_0_resp_bits_s2_entry_pbmt |= w_g_io_tlb_0_resp_bits_s2_entry_pbmt;
        w_s0_io_tlb_0_resp_bits_s2_entry_pbmt |= ~w_g_io_tlb_0_resp_bits_s2_entry_pbmt;
        checks++;
        if (w_g_io_tlb_0_resp_bits_s2_entry_ppn !== w_i_io_tlb_0_resp_bits_s2_entry_ppn) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d L2TLBWrapper.io_tlb_0_resp_bits_s2_entry_ppn g=%h i=%h", cyc, w_g_io_tlb_0_resp_bits_s2_entry_ppn, w_i_io_tlb_0_resp_bits_s2_entry_ppn);
        end
        w_s1_io_tlb_0_resp_bits_s2_entry_ppn |= w_g_io_tlb_0_resp_bits_s2_entry_ppn;
        w_s0_io_tlb_0_resp_bits_s2_entry_ppn |= ~w_g_io_tlb_0_resp_bits_s2_entry_ppn;
        checks++;
        if (w_g_io_tlb_0_resp_bits_s2_entry_perm_d !== w_i_io_tlb_0_resp_bits_s2_entry_perm_d) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d L2TLBWrapper.io_tlb_0_resp_bits_s2_entry_perm_d g=%h i=%h", cyc, w_g_io_tlb_0_resp_bits_s2_entry_perm_d, w_i_io_tlb_0_resp_bits_s2_entry_perm_d);
        end
        w_s1_io_tlb_0_resp_bits_s2_entry_perm_d |= w_g_io_tlb_0_resp_bits_s2_entry_perm_d;
        w_s0_io_tlb_0_resp_bits_s2_entry_perm_d |= ~w_g_io_tlb_0_resp_bits_s2_entry_perm_d;
        checks++;
        if (w_g_io_tlb_0_resp_bits_s2_entry_perm_a !== w_i_io_tlb_0_resp_bits_s2_entry_perm_a) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d L2TLBWrapper.io_tlb_0_resp_bits_s2_entry_perm_a g=%h i=%h", cyc, w_g_io_tlb_0_resp_bits_s2_entry_perm_a, w_i_io_tlb_0_resp_bits_s2_entry_perm_a);
        end
        w_s1_io_tlb_0_resp_bits_s2_entry_perm_a |= w_g_io_tlb_0_resp_bits_s2_entry_perm_a;
        w_s0_io_tlb_0_resp_bits_s2_entry_perm_a |= ~w_g_io_tlb_0_resp_bits_s2_entry_perm_a;
        checks++;
        if (w_g_io_tlb_0_resp_bits_s2_entry_perm_g !== w_i_io_tlb_0_resp_bits_s2_entry_perm_g) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d L2TLBWrapper.io_tlb_0_resp_bits_s2_entry_perm_g g=%h i=%h", cyc, w_g_io_tlb_0_resp_bits_s2_entry_perm_g, w_i_io_tlb_0_resp_bits_s2_entry_perm_g);
        end
        w_s1_io_tlb_0_resp_bits_s2_entry_perm_g |= w_g_io_tlb_0_resp_bits_s2_entry_perm_g;
        w_s0_io_tlb_0_resp_bits_s2_entry_perm_g |= ~w_g_io_tlb_0_resp_bits_s2_entry_perm_g;
        checks++;
        if (w_g_io_tlb_0_resp_bits_s2_entry_perm_u !== w_i_io_tlb_0_resp_bits_s2_entry_perm_u) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d L2TLBWrapper.io_tlb_0_resp_bits_s2_entry_perm_u g=%h i=%h", cyc, w_g_io_tlb_0_resp_bits_s2_entry_perm_u, w_i_io_tlb_0_resp_bits_s2_entry_perm_u);
        end
        w_s1_io_tlb_0_resp_bits_s2_entry_perm_u |= w_g_io_tlb_0_resp_bits_s2_entry_perm_u;
        w_s0_io_tlb_0_resp_bits_s2_entry_perm_u |= ~w_g_io_tlb_0_resp_bits_s2_entry_perm_u;
        checks++;
        if (w_g_io_tlb_0_resp_bits_s2_entry_perm_x !== w_i_io_tlb_0_resp_bits_s2_entry_perm_x) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d L2TLBWrapper.io_tlb_0_resp_bits_s2_entry_perm_x g=%h i=%h", cyc, w_g_io_tlb_0_resp_bits_s2_entry_perm_x, w_i_io_tlb_0_resp_bits_s2_entry_perm_x);
        end
        w_s1_io_tlb_0_resp_bits_s2_entry_perm_x |= w_g_io_tlb_0_resp_bits_s2_entry_perm_x;
        w_s0_io_tlb_0_resp_bits_s2_entry_perm_x |= ~w_g_io_tlb_0_resp_bits_s2_entry_perm_x;
        checks++;
        if (w_g_io_tlb_0_resp_bits_s2_entry_perm_w !== w_i_io_tlb_0_resp_bits_s2_entry_perm_w) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d L2TLBWrapper.io_tlb_0_resp_bits_s2_entry_perm_w g=%h i=%h", cyc, w_g_io_tlb_0_resp_bits_s2_entry_perm_w, w_i_io_tlb_0_resp_bits_s2_entry_perm_w);
        end
        w_s1_io_tlb_0_resp_bits_s2_entry_perm_w |= w_g_io_tlb_0_resp_bits_s2_entry_perm_w;
        w_s0_io_tlb_0_resp_bits_s2_entry_perm_w |= ~w_g_io_tlb_0_resp_bits_s2_entry_perm_w;
        checks++;
        if (w_g_io_tlb_0_resp_bits_s2_entry_perm_r !== w_i_io_tlb_0_resp_bits_s2_entry_perm_r) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d L2TLBWrapper.io_tlb_0_resp_bits_s2_entry_perm_r g=%h i=%h", cyc, w_g_io_tlb_0_resp_bits_s2_entry_perm_r, w_i_io_tlb_0_resp_bits_s2_entry_perm_r);
        end
        w_s1_io_tlb_0_resp_bits_s2_entry_perm_r |= w_g_io_tlb_0_resp_bits_s2_entry_perm_r;
        w_s0_io_tlb_0_resp_bits_s2_entry_perm_r |= ~w_g_io_tlb_0_resp_bits_s2_entry_perm_r;
        checks++;
        if (w_g_io_tlb_0_resp_bits_s2_entry_level !== w_i_io_tlb_0_resp_bits_s2_entry_level) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d L2TLBWrapper.io_tlb_0_resp_bits_s2_entry_level g=%h i=%h", cyc, w_g_io_tlb_0_resp_bits_s2_entry_level, w_i_io_tlb_0_resp_bits_s2_entry_level);
        end
        w_s1_io_tlb_0_resp_bits_s2_entry_level |= w_g_io_tlb_0_resp_bits_s2_entry_level;
        w_s0_io_tlb_0_resp_bits_s2_entry_level |= ~w_g_io_tlb_0_resp_bits_s2_entry_level;
        checks++;
        if (w_g_io_tlb_0_resp_bits_s2_gpf !== w_i_io_tlb_0_resp_bits_s2_gpf) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d L2TLBWrapper.io_tlb_0_resp_bits_s2_gpf g=%h i=%h", cyc, w_g_io_tlb_0_resp_bits_s2_gpf, w_i_io_tlb_0_resp_bits_s2_gpf);
        end
        w_s1_io_tlb_0_resp_bits_s2_gpf |= w_g_io_tlb_0_resp_bits_s2_gpf;
        w_s0_io_tlb_0_resp_bits_s2_gpf |= ~w_g_io_tlb_0_resp_bits_s2_gpf;
        checks++;
        if (w_g_io_tlb_0_resp_bits_s2_gaf !== w_i_io_tlb_0_resp_bits_s2_gaf) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d L2TLBWrapper.io_tlb_0_resp_bits_s2_gaf g=%h i=%h", cyc, w_g_io_tlb_0_resp_bits_s2_gaf, w_i_io_tlb_0_resp_bits_s2_gaf);
        end
        w_s1_io_tlb_0_resp_bits_s2_gaf |= w_g_io_tlb_0_resp_bits_s2_gaf;
        w_s0_io_tlb_0_resp_bits_s2_gaf |= ~w_g_io_tlb_0_resp_bits_s2_gaf;
        checks++;
        if (w_g_io_tlb_1_req_0_ready !== w_i_io_tlb_1_req_0_ready) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d L2TLBWrapper.io_tlb_1_req_0_ready g=%h i=%h", cyc, w_g_io_tlb_1_req_0_ready, w_i_io_tlb_1_req_0_ready);
        end
        w_s1_io_tlb_1_req_0_ready |= w_g_io_tlb_1_req_0_ready;
        w_s0_io_tlb_1_req_0_ready |= ~w_g_io_tlb_1_req_0_ready;
        checks++;
        if (w_g_io_tlb_1_resp_valid !== w_i_io_tlb_1_resp_valid) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d L2TLBWrapper.io_tlb_1_resp_valid g=%h i=%h", cyc, w_g_io_tlb_1_resp_valid, w_i_io_tlb_1_resp_valid);
        end
        w_s1_io_tlb_1_resp_valid |= w_g_io_tlb_1_resp_valid;
        w_s0_io_tlb_1_resp_valid |= ~w_g_io_tlb_1_resp_valid;
        checks++;
        if (w_g_io_tlb_1_resp_bits_s2xlate !== w_i_io_tlb_1_resp_bits_s2xlate) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d L2TLBWrapper.io_tlb_1_resp_bits_s2xlate g=%h i=%h", cyc, w_g_io_tlb_1_resp_bits_s2xlate, w_i_io_tlb_1_resp_bits_s2xlate);
        end
        w_s1_io_tlb_1_resp_bits_s2xlate |= w_g_io_tlb_1_resp_bits_s2xlate;
        w_s0_io_tlb_1_resp_bits_s2xlate |= ~w_g_io_tlb_1_resp_bits_s2xlate;
        checks++;
        if (w_g_io_tlb_1_resp_bits_s1_entry_tag !== w_i_io_tlb_1_resp_bits_s1_entry_tag) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d L2TLBWrapper.io_tlb_1_resp_bits_s1_entry_tag g=%h i=%h", cyc, w_g_io_tlb_1_resp_bits_s1_entry_tag, w_i_io_tlb_1_resp_bits_s1_entry_tag);
        end
        w_s1_io_tlb_1_resp_bits_s1_entry_tag |= w_g_io_tlb_1_resp_bits_s1_entry_tag;
        w_s0_io_tlb_1_resp_bits_s1_entry_tag |= ~w_g_io_tlb_1_resp_bits_s1_entry_tag;
        checks++;
        if (w_g_io_tlb_1_resp_bits_s1_entry_asid !== w_i_io_tlb_1_resp_bits_s1_entry_asid) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d L2TLBWrapper.io_tlb_1_resp_bits_s1_entry_asid g=%h i=%h", cyc, w_g_io_tlb_1_resp_bits_s1_entry_asid, w_i_io_tlb_1_resp_bits_s1_entry_asid);
        end
        w_s1_io_tlb_1_resp_bits_s1_entry_asid |= w_g_io_tlb_1_resp_bits_s1_entry_asid;
        w_s0_io_tlb_1_resp_bits_s1_entry_asid |= ~w_g_io_tlb_1_resp_bits_s1_entry_asid;
        checks++;
        if (w_g_io_tlb_1_resp_bits_s1_entry_vmid !== w_i_io_tlb_1_resp_bits_s1_entry_vmid) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d L2TLBWrapper.io_tlb_1_resp_bits_s1_entry_vmid g=%h i=%h", cyc, w_g_io_tlb_1_resp_bits_s1_entry_vmid, w_i_io_tlb_1_resp_bits_s1_entry_vmid);
        end
        w_s1_io_tlb_1_resp_bits_s1_entry_vmid |= w_g_io_tlb_1_resp_bits_s1_entry_vmid;
        w_s0_io_tlb_1_resp_bits_s1_entry_vmid |= ~w_g_io_tlb_1_resp_bits_s1_entry_vmid;
        checks++;
        if (w_g_io_tlb_1_resp_bits_s1_entry_n !== w_i_io_tlb_1_resp_bits_s1_entry_n) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d L2TLBWrapper.io_tlb_1_resp_bits_s1_entry_n g=%h i=%h", cyc, w_g_io_tlb_1_resp_bits_s1_entry_n, w_i_io_tlb_1_resp_bits_s1_entry_n);
        end
        w_s1_io_tlb_1_resp_bits_s1_entry_n |= w_g_io_tlb_1_resp_bits_s1_entry_n;
        w_s0_io_tlb_1_resp_bits_s1_entry_n |= ~w_g_io_tlb_1_resp_bits_s1_entry_n;
        checks++;
        if (w_g_io_tlb_1_resp_bits_s1_entry_pbmt !== w_i_io_tlb_1_resp_bits_s1_entry_pbmt) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d L2TLBWrapper.io_tlb_1_resp_bits_s1_entry_pbmt g=%h i=%h", cyc, w_g_io_tlb_1_resp_bits_s1_entry_pbmt, w_i_io_tlb_1_resp_bits_s1_entry_pbmt);
        end
        w_s1_io_tlb_1_resp_bits_s1_entry_pbmt |= w_g_io_tlb_1_resp_bits_s1_entry_pbmt;
        w_s0_io_tlb_1_resp_bits_s1_entry_pbmt |= ~w_g_io_tlb_1_resp_bits_s1_entry_pbmt;
        checks++;
        if (w_g_io_tlb_1_resp_bits_s1_entry_perm_d !== w_i_io_tlb_1_resp_bits_s1_entry_perm_d) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d L2TLBWrapper.io_tlb_1_resp_bits_s1_entry_perm_d g=%h i=%h", cyc, w_g_io_tlb_1_resp_bits_s1_entry_perm_d, w_i_io_tlb_1_resp_bits_s1_entry_perm_d);
        end
        w_s1_io_tlb_1_resp_bits_s1_entry_perm_d |= w_g_io_tlb_1_resp_bits_s1_entry_perm_d;
        w_s0_io_tlb_1_resp_bits_s1_entry_perm_d |= ~w_g_io_tlb_1_resp_bits_s1_entry_perm_d;
        checks++;
        if (w_g_io_tlb_1_resp_bits_s1_entry_perm_a !== w_i_io_tlb_1_resp_bits_s1_entry_perm_a) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d L2TLBWrapper.io_tlb_1_resp_bits_s1_entry_perm_a g=%h i=%h", cyc, w_g_io_tlb_1_resp_bits_s1_entry_perm_a, w_i_io_tlb_1_resp_bits_s1_entry_perm_a);
        end
        w_s1_io_tlb_1_resp_bits_s1_entry_perm_a |= w_g_io_tlb_1_resp_bits_s1_entry_perm_a;
        w_s0_io_tlb_1_resp_bits_s1_entry_perm_a |= ~w_g_io_tlb_1_resp_bits_s1_entry_perm_a;
        checks++;
        if (w_g_io_tlb_1_resp_bits_s1_entry_perm_g !== w_i_io_tlb_1_resp_bits_s1_entry_perm_g) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d L2TLBWrapper.io_tlb_1_resp_bits_s1_entry_perm_g g=%h i=%h", cyc, w_g_io_tlb_1_resp_bits_s1_entry_perm_g, w_i_io_tlb_1_resp_bits_s1_entry_perm_g);
        end
        w_s1_io_tlb_1_resp_bits_s1_entry_perm_g |= w_g_io_tlb_1_resp_bits_s1_entry_perm_g;
        w_s0_io_tlb_1_resp_bits_s1_entry_perm_g |= ~w_g_io_tlb_1_resp_bits_s1_entry_perm_g;
        checks++;
        if (w_g_io_tlb_1_resp_bits_s1_entry_perm_u !== w_i_io_tlb_1_resp_bits_s1_entry_perm_u) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d L2TLBWrapper.io_tlb_1_resp_bits_s1_entry_perm_u g=%h i=%h", cyc, w_g_io_tlb_1_resp_bits_s1_entry_perm_u, w_i_io_tlb_1_resp_bits_s1_entry_perm_u);
        end
        w_s1_io_tlb_1_resp_bits_s1_entry_perm_u |= w_g_io_tlb_1_resp_bits_s1_entry_perm_u;
        w_s0_io_tlb_1_resp_bits_s1_entry_perm_u |= ~w_g_io_tlb_1_resp_bits_s1_entry_perm_u;
        checks++;
        if (w_g_io_tlb_1_resp_bits_s1_entry_perm_x !== w_i_io_tlb_1_resp_bits_s1_entry_perm_x) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d L2TLBWrapper.io_tlb_1_resp_bits_s1_entry_perm_x g=%h i=%h", cyc, w_g_io_tlb_1_resp_bits_s1_entry_perm_x, w_i_io_tlb_1_resp_bits_s1_entry_perm_x);
        end
        w_s1_io_tlb_1_resp_bits_s1_entry_perm_x |= w_g_io_tlb_1_resp_bits_s1_entry_perm_x;
        w_s0_io_tlb_1_resp_bits_s1_entry_perm_x |= ~w_g_io_tlb_1_resp_bits_s1_entry_perm_x;
        checks++;
        if (w_g_io_tlb_1_resp_bits_s1_entry_perm_w !== w_i_io_tlb_1_resp_bits_s1_entry_perm_w) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d L2TLBWrapper.io_tlb_1_resp_bits_s1_entry_perm_w g=%h i=%h", cyc, w_g_io_tlb_1_resp_bits_s1_entry_perm_w, w_i_io_tlb_1_resp_bits_s1_entry_perm_w);
        end
        w_s1_io_tlb_1_resp_bits_s1_entry_perm_w |= w_g_io_tlb_1_resp_bits_s1_entry_perm_w;
        w_s0_io_tlb_1_resp_bits_s1_entry_perm_w |= ~w_g_io_tlb_1_resp_bits_s1_entry_perm_w;
        checks++;
        if (w_g_io_tlb_1_resp_bits_s1_entry_perm_r !== w_i_io_tlb_1_resp_bits_s1_entry_perm_r) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d L2TLBWrapper.io_tlb_1_resp_bits_s1_entry_perm_r g=%h i=%h", cyc, w_g_io_tlb_1_resp_bits_s1_entry_perm_r, w_i_io_tlb_1_resp_bits_s1_entry_perm_r);
        end
        w_s1_io_tlb_1_resp_bits_s1_entry_perm_r |= w_g_io_tlb_1_resp_bits_s1_entry_perm_r;
        w_s0_io_tlb_1_resp_bits_s1_entry_perm_r |= ~w_g_io_tlb_1_resp_bits_s1_entry_perm_r;
        checks++;
        if (w_g_io_tlb_1_resp_bits_s1_entry_level !== w_i_io_tlb_1_resp_bits_s1_entry_level) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d L2TLBWrapper.io_tlb_1_resp_bits_s1_entry_level g=%h i=%h", cyc, w_g_io_tlb_1_resp_bits_s1_entry_level, w_i_io_tlb_1_resp_bits_s1_entry_level);
        end
        w_s1_io_tlb_1_resp_bits_s1_entry_level |= w_g_io_tlb_1_resp_bits_s1_entry_level;
        w_s0_io_tlb_1_resp_bits_s1_entry_level |= ~w_g_io_tlb_1_resp_bits_s1_entry_level;
        checks++;
        if (w_g_io_tlb_1_resp_bits_s1_entry_v !== w_i_io_tlb_1_resp_bits_s1_entry_v) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d L2TLBWrapper.io_tlb_1_resp_bits_s1_entry_v g=%h i=%h", cyc, w_g_io_tlb_1_resp_bits_s1_entry_v, w_i_io_tlb_1_resp_bits_s1_entry_v);
        end
        w_s1_io_tlb_1_resp_bits_s1_entry_v |= w_g_io_tlb_1_resp_bits_s1_entry_v;
        w_s0_io_tlb_1_resp_bits_s1_entry_v |= ~w_g_io_tlb_1_resp_bits_s1_entry_v;
        checks++;
        if (w_g_io_tlb_1_resp_bits_s1_entry_ppn !== w_i_io_tlb_1_resp_bits_s1_entry_ppn) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d L2TLBWrapper.io_tlb_1_resp_bits_s1_entry_ppn g=%h i=%h", cyc, w_g_io_tlb_1_resp_bits_s1_entry_ppn, w_i_io_tlb_1_resp_bits_s1_entry_ppn);
        end
        w_s1_io_tlb_1_resp_bits_s1_entry_ppn |= w_g_io_tlb_1_resp_bits_s1_entry_ppn;
        w_s0_io_tlb_1_resp_bits_s1_entry_ppn |= ~w_g_io_tlb_1_resp_bits_s1_entry_ppn;
        checks++;
        if (w_g_io_tlb_1_resp_bits_s1_addr_low !== w_i_io_tlb_1_resp_bits_s1_addr_low) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d L2TLBWrapper.io_tlb_1_resp_bits_s1_addr_low g=%h i=%h", cyc, w_g_io_tlb_1_resp_bits_s1_addr_low, w_i_io_tlb_1_resp_bits_s1_addr_low);
        end
        w_s1_io_tlb_1_resp_bits_s1_addr_low |= w_g_io_tlb_1_resp_bits_s1_addr_low;
        w_s0_io_tlb_1_resp_bits_s1_addr_low |= ~w_g_io_tlb_1_resp_bits_s1_addr_low;
        checks++;
        if (w_g_io_tlb_1_resp_bits_s1_ppn_low_0 !== w_i_io_tlb_1_resp_bits_s1_ppn_low_0) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d L2TLBWrapper.io_tlb_1_resp_bits_s1_ppn_low_0 g=%h i=%h", cyc, w_g_io_tlb_1_resp_bits_s1_ppn_low_0, w_i_io_tlb_1_resp_bits_s1_ppn_low_0);
        end
        w_s1_io_tlb_1_resp_bits_s1_ppn_low_0 |= w_g_io_tlb_1_resp_bits_s1_ppn_low_0;
        w_s0_io_tlb_1_resp_bits_s1_ppn_low_0 |= ~w_g_io_tlb_1_resp_bits_s1_ppn_low_0;
        checks++;
        if (w_g_io_tlb_1_resp_bits_s1_ppn_low_1 !== w_i_io_tlb_1_resp_bits_s1_ppn_low_1) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d L2TLBWrapper.io_tlb_1_resp_bits_s1_ppn_low_1 g=%h i=%h", cyc, w_g_io_tlb_1_resp_bits_s1_ppn_low_1, w_i_io_tlb_1_resp_bits_s1_ppn_low_1);
        end
        w_s1_io_tlb_1_resp_bits_s1_ppn_low_1 |= w_g_io_tlb_1_resp_bits_s1_ppn_low_1;
        w_s0_io_tlb_1_resp_bits_s1_ppn_low_1 |= ~w_g_io_tlb_1_resp_bits_s1_ppn_low_1;
        checks++;
        if (w_g_io_tlb_1_resp_bits_s1_ppn_low_2 !== w_i_io_tlb_1_resp_bits_s1_ppn_low_2) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d L2TLBWrapper.io_tlb_1_resp_bits_s1_ppn_low_2 g=%h i=%h", cyc, w_g_io_tlb_1_resp_bits_s1_ppn_low_2, w_i_io_tlb_1_resp_bits_s1_ppn_low_2);
        end
        w_s1_io_tlb_1_resp_bits_s1_ppn_low_2 |= w_g_io_tlb_1_resp_bits_s1_ppn_low_2;
        w_s0_io_tlb_1_resp_bits_s1_ppn_low_2 |= ~w_g_io_tlb_1_resp_bits_s1_ppn_low_2;
        checks++;
        if (w_g_io_tlb_1_resp_bits_s1_ppn_low_3 !== w_i_io_tlb_1_resp_bits_s1_ppn_low_3) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d L2TLBWrapper.io_tlb_1_resp_bits_s1_ppn_low_3 g=%h i=%h", cyc, w_g_io_tlb_1_resp_bits_s1_ppn_low_3, w_i_io_tlb_1_resp_bits_s1_ppn_low_3);
        end
        w_s1_io_tlb_1_resp_bits_s1_ppn_low_3 |= w_g_io_tlb_1_resp_bits_s1_ppn_low_3;
        w_s0_io_tlb_1_resp_bits_s1_ppn_low_3 |= ~w_g_io_tlb_1_resp_bits_s1_ppn_low_3;
        checks++;
        if (w_g_io_tlb_1_resp_bits_s1_ppn_low_4 !== w_i_io_tlb_1_resp_bits_s1_ppn_low_4) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d L2TLBWrapper.io_tlb_1_resp_bits_s1_ppn_low_4 g=%h i=%h", cyc, w_g_io_tlb_1_resp_bits_s1_ppn_low_4, w_i_io_tlb_1_resp_bits_s1_ppn_low_4);
        end
        w_s1_io_tlb_1_resp_bits_s1_ppn_low_4 |= w_g_io_tlb_1_resp_bits_s1_ppn_low_4;
        w_s0_io_tlb_1_resp_bits_s1_ppn_low_4 |= ~w_g_io_tlb_1_resp_bits_s1_ppn_low_4;
        checks++;
        if (w_g_io_tlb_1_resp_bits_s1_ppn_low_5 !== w_i_io_tlb_1_resp_bits_s1_ppn_low_5) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d L2TLBWrapper.io_tlb_1_resp_bits_s1_ppn_low_5 g=%h i=%h", cyc, w_g_io_tlb_1_resp_bits_s1_ppn_low_5, w_i_io_tlb_1_resp_bits_s1_ppn_low_5);
        end
        w_s1_io_tlb_1_resp_bits_s1_ppn_low_5 |= w_g_io_tlb_1_resp_bits_s1_ppn_low_5;
        w_s0_io_tlb_1_resp_bits_s1_ppn_low_5 |= ~w_g_io_tlb_1_resp_bits_s1_ppn_low_5;
        checks++;
        if (w_g_io_tlb_1_resp_bits_s1_ppn_low_6 !== w_i_io_tlb_1_resp_bits_s1_ppn_low_6) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d L2TLBWrapper.io_tlb_1_resp_bits_s1_ppn_low_6 g=%h i=%h", cyc, w_g_io_tlb_1_resp_bits_s1_ppn_low_6, w_i_io_tlb_1_resp_bits_s1_ppn_low_6);
        end
        w_s1_io_tlb_1_resp_bits_s1_ppn_low_6 |= w_g_io_tlb_1_resp_bits_s1_ppn_low_6;
        w_s0_io_tlb_1_resp_bits_s1_ppn_low_6 |= ~w_g_io_tlb_1_resp_bits_s1_ppn_low_6;
        checks++;
        if (w_g_io_tlb_1_resp_bits_s1_ppn_low_7 !== w_i_io_tlb_1_resp_bits_s1_ppn_low_7) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d L2TLBWrapper.io_tlb_1_resp_bits_s1_ppn_low_7 g=%h i=%h", cyc, w_g_io_tlb_1_resp_bits_s1_ppn_low_7, w_i_io_tlb_1_resp_bits_s1_ppn_low_7);
        end
        w_s1_io_tlb_1_resp_bits_s1_ppn_low_7 |= w_g_io_tlb_1_resp_bits_s1_ppn_low_7;
        w_s0_io_tlb_1_resp_bits_s1_ppn_low_7 |= ~w_g_io_tlb_1_resp_bits_s1_ppn_low_7;
        checks++;
        if (w_g_io_tlb_1_resp_bits_s1_valididx_0 !== w_i_io_tlb_1_resp_bits_s1_valididx_0) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d L2TLBWrapper.io_tlb_1_resp_bits_s1_valididx_0 g=%h i=%h", cyc, w_g_io_tlb_1_resp_bits_s1_valididx_0, w_i_io_tlb_1_resp_bits_s1_valididx_0);
        end
        w_s1_io_tlb_1_resp_bits_s1_valididx_0 |= w_g_io_tlb_1_resp_bits_s1_valididx_0;
        w_s0_io_tlb_1_resp_bits_s1_valididx_0 |= ~w_g_io_tlb_1_resp_bits_s1_valididx_0;
        checks++;
        if (w_g_io_tlb_1_resp_bits_s1_valididx_1 !== w_i_io_tlb_1_resp_bits_s1_valididx_1) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d L2TLBWrapper.io_tlb_1_resp_bits_s1_valididx_1 g=%h i=%h", cyc, w_g_io_tlb_1_resp_bits_s1_valididx_1, w_i_io_tlb_1_resp_bits_s1_valididx_1);
        end
        w_s1_io_tlb_1_resp_bits_s1_valididx_1 |= w_g_io_tlb_1_resp_bits_s1_valididx_1;
        w_s0_io_tlb_1_resp_bits_s1_valididx_1 |= ~w_g_io_tlb_1_resp_bits_s1_valididx_1;
        checks++;
        if (w_g_io_tlb_1_resp_bits_s1_valididx_2 !== w_i_io_tlb_1_resp_bits_s1_valididx_2) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d L2TLBWrapper.io_tlb_1_resp_bits_s1_valididx_2 g=%h i=%h", cyc, w_g_io_tlb_1_resp_bits_s1_valididx_2, w_i_io_tlb_1_resp_bits_s1_valididx_2);
        end
        w_s1_io_tlb_1_resp_bits_s1_valididx_2 |= w_g_io_tlb_1_resp_bits_s1_valididx_2;
        w_s0_io_tlb_1_resp_bits_s1_valididx_2 |= ~w_g_io_tlb_1_resp_bits_s1_valididx_2;
        checks++;
        if (w_g_io_tlb_1_resp_bits_s1_valididx_3 !== w_i_io_tlb_1_resp_bits_s1_valididx_3) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d L2TLBWrapper.io_tlb_1_resp_bits_s1_valididx_3 g=%h i=%h", cyc, w_g_io_tlb_1_resp_bits_s1_valididx_3, w_i_io_tlb_1_resp_bits_s1_valididx_3);
        end
        w_s1_io_tlb_1_resp_bits_s1_valididx_3 |= w_g_io_tlb_1_resp_bits_s1_valididx_3;
        w_s0_io_tlb_1_resp_bits_s1_valididx_3 |= ~w_g_io_tlb_1_resp_bits_s1_valididx_3;
        checks++;
        if (w_g_io_tlb_1_resp_bits_s1_valididx_4 !== w_i_io_tlb_1_resp_bits_s1_valididx_4) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d L2TLBWrapper.io_tlb_1_resp_bits_s1_valididx_4 g=%h i=%h", cyc, w_g_io_tlb_1_resp_bits_s1_valididx_4, w_i_io_tlb_1_resp_bits_s1_valididx_4);
        end
        w_s1_io_tlb_1_resp_bits_s1_valididx_4 |= w_g_io_tlb_1_resp_bits_s1_valididx_4;
        w_s0_io_tlb_1_resp_bits_s1_valididx_4 |= ~w_g_io_tlb_1_resp_bits_s1_valididx_4;
        checks++;
        if (w_g_io_tlb_1_resp_bits_s1_valididx_5 !== w_i_io_tlb_1_resp_bits_s1_valididx_5) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d L2TLBWrapper.io_tlb_1_resp_bits_s1_valididx_5 g=%h i=%h", cyc, w_g_io_tlb_1_resp_bits_s1_valididx_5, w_i_io_tlb_1_resp_bits_s1_valididx_5);
        end
        w_s1_io_tlb_1_resp_bits_s1_valididx_5 |= w_g_io_tlb_1_resp_bits_s1_valididx_5;
        w_s0_io_tlb_1_resp_bits_s1_valididx_5 |= ~w_g_io_tlb_1_resp_bits_s1_valididx_5;
        checks++;
        if (w_g_io_tlb_1_resp_bits_s1_valididx_6 !== w_i_io_tlb_1_resp_bits_s1_valididx_6) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d L2TLBWrapper.io_tlb_1_resp_bits_s1_valididx_6 g=%h i=%h", cyc, w_g_io_tlb_1_resp_bits_s1_valididx_6, w_i_io_tlb_1_resp_bits_s1_valididx_6);
        end
        w_s1_io_tlb_1_resp_bits_s1_valididx_6 |= w_g_io_tlb_1_resp_bits_s1_valididx_6;
        w_s0_io_tlb_1_resp_bits_s1_valididx_6 |= ~w_g_io_tlb_1_resp_bits_s1_valididx_6;
        checks++;
        if (w_g_io_tlb_1_resp_bits_s1_valididx_7 !== w_i_io_tlb_1_resp_bits_s1_valididx_7) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d L2TLBWrapper.io_tlb_1_resp_bits_s1_valididx_7 g=%h i=%h", cyc, w_g_io_tlb_1_resp_bits_s1_valididx_7, w_i_io_tlb_1_resp_bits_s1_valididx_7);
        end
        w_s1_io_tlb_1_resp_bits_s1_valididx_7 |= w_g_io_tlb_1_resp_bits_s1_valididx_7;
        w_s0_io_tlb_1_resp_bits_s1_valididx_7 |= ~w_g_io_tlb_1_resp_bits_s1_valididx_7;
        checks++;
        if (w_g_io_tlb_1_resp_bits_s1_pteidx_0 !== w_i_io_tlb_1_resp_bits_s1_pteidx_0) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d L2TLBWrapper.io_tlb_1_resp_bits_s1_pteidx_0 g=%h i=%h", cyc, w_g_io_tlb_1_resp_bits_s1_pteidx_0, w_i_io_tlb_1_resp_bits_s1_pteidx_0);
        end
        w_s1_io_tlb_1_resp_bits_s1_pteidx_0 |= w_g_io_tlb_1_resp_bits_s1_pteidx_0;
        w_s0_io_tlb_1_resp_bits_s1_pteidx_0 |= ~w_g_io_tlb_1_resp_bits_s1_pteidx_0;
        checks++;
        if (w_g_io_tlb_1_resp_bits_s1_pteidx_1 !== w_i_io_tlb_1_resp_bits_s1_pteidx_1) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d L2TLBWrapper.io_tlb_1_resp_bits_s1_pteidx_1 g=%h i=%h", cyc, w_g_io_tlb_1_resp_bits_s1_pteidx_1, w_i_io_tlb_1_resp_bits_s1_pteidx_1);
        end
        w_s1_io_tlb_1_resp_bits_s1_pteidx_1 |= w_g_io_tlb_1_resp_bits_s1_pteidx_1;
        w_s0_io_tlb_1_resp_bits_s1_pteidx_1 |= ~w_g_io_tlb_1_resp_bits_s1_pteidx_1;
        checks++;
        if (w_g_io_tlb_1_resp_bits_s1_pteidx_2 !== w_i_io_tlb_1_resp_bits_s1_pteidx_2) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d L2TLBWrapper.io_tlb_1_resp_bits_s1_pteidx_2 g=%h i=%h", cyc, w_g_io_tlb_1_resp_bits_s1_pteidx_2, w_i_io_tlb_1_resp_bits_s1_pteidx_2);
        end
        w_s1_io_tlb_1_resp_bits_s1_pteidx_2 |= w_g_io_tlb_1_resp_bits_s1_pteidx_2;
        w_s0_io_tlb_1_resp_bits_s1_pteidx_2 |= ~w_g_io_tlb_1_resp_bits_s1_pteidx_2;
        checks++;
        if (w_g_io_tlb_1_resp_bits_s1_pteidx_3 !== w_i_io_tlb_1_resp_bits_s1_pteidx_3) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d L2TLBWrapper.io_tlb_1_resp_bits_s1_pteidx_3 g=%h i=%h", cyc, w_g_io_tlb_1_resp_bits_s1_pteidx_3, w_i_io_tlb_1_resp_bits_s1_pteidx_3);
        end
        w_s1_io_tlb_1_resp_bits_s1_pteidx_3 |= w_g_io_tlb_1_resp_bits_s1_pteidx_3;
        w_s0_io_tlb_1_resp_bits_s1_pteidx_3 |= ~w_g_io_tlb_1_resp_bits_s1_pteidx_3;
        checks++;
        if (w_g_io_tlb_1_resp_bits_s1_pteidx_4 !== w_i_io_tlb_1_resp_bits_s1_pteidx_4) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d L2TLBWrapper.io_tlb_1_resp_bits_s1_pteidx_4 g=%h i=%h", cyc, w_g_io_tlb_1_resp_bits_s1_pteidx_4, w_i_io_tlb_1_resp_bits_s1_pteidx_4);
        end
        w_s1_io_tlb_1_resp_bits_s1_pteidx_4 |= w_g_io_tlb_1_resp_bits_s1_pteidx_4;
        w_s0_io_tlb_1_resp_bits_s1_pteidx_4 |= ~w_g_io_tlb_1_resp_bits_s1_pteidx_4;
        checks++;
        if (w_g_io_tlb_1_resp_bits_s1_pteidx_5 !== w_i_io_tlb_1_resp_bits_s1_pteidx_5) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d L2TLBWrapper.io_tlb_1_resp_bits_s1_pteidx_5 g=%h i=%h", cyc, w_g_io_tlb_1_resp_bits_s1_pteidx_5, w_i_io_tlb_1_resp_bits_s1_pteidx_5);
        end
        w_s1_io_tlb_1_resp_bits_s1_pteidx_5 |= w_g_io_tlb_1_resp_bits_s1_pteidx_5;
        w_s0_io_tlb_1_resp_bits_s1_pteidx_5 |= ~w_g_io_tlb_1_resp_bits_s1_pteidx_5;
        checks++;
        if (w_g_io_tlb_1_resp_bits_s1_pteidx_6 !== w_i_io_tlb_1_resp_bits_s1_pteidx_6) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d L2TLBWrapper.io_tlb_1_resp_bits_s1_pteidx_6 g=%h i=%h", cyc, w_g_io_tlb_1_resp_bits_s1_pteidx_6, w_i_io_tlb_1_resp_bits_s1_pteidx_6);
        end
        w_s1_io_tlb_1_resp_bits_s1_pteidx_6 |= w_g_io_tlb_1_resp_bits_s1_pteidx_6;
        w_s0_io_tlb_1_resp_bits_s1_pteidx_6 |= ~w_g_io_tlb_1_resp_bits_s1_pteidx_6;
        checks++;
        if (w_g_io_tlb_1_resp_bits_s1_pteidx_7 !== w_i_io_tlb_1_resp_bits_s1_pteidx_7) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d L2TLBWrapper.io_tlb_1_resp_bits_s1_pteidx_7 g=%h i=%h", cyc, w_g_io_tlb_1_resp_bits_s1_pteidx_7, w_i_io_tlb_1_resp_bits_s1_pteidx_7);
        end
        w_s1_io_tlb_1_resp_bits_s1_pteidx_7 |= w_g_io_tlb_1_resp_bits_s1_pteidx_7;
        w_s0_io_tlb_1_resp_bits_s1_pteidx_7 |= ~w_g_io_tlb_1_resp_bits_s1_pteidx_7;
        checks++;
        if (w_g_io_tlb_1_resp_bits_s1_pf !== w_i_io_tlb_1_resp_bits_s1_pf) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d L2TLBWrapper.io_tlb_1_resp_bits_s1_pf g=%h i=%h", cyc, w_g_io_tlb_1_resp_bits_s1_pf, w_i_io_tlb_1_resp_bits_s1_pf);
        end
        w_s1_io_tlb_1_resp_bits_s1_pf |= w_g_io_tlb_1_resp_bits_s1_pf;
        w_s0_io_tlb_1_resp_bits_s1_pf |= ~w_g_io_tlb_1_resp_bits_s1_pf;
        checks++;
        if (w_g_io_tlb_1_resp_bits_s1_af !== w_i_io_tlb_1_resp_bits_s1_af) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d L2TLBWrapper.io_tlb_1_resp_bits_s1_af g=%h i=%h", cyc, w_g_io_tlb_1_resp_bits_s1_af, w_i_io_tlb_1_resp_bits_s1_af);
        end
        w_s1_io_tlb_1_resp_bits_s1_af |= w_g_io_tlb_1_resp_bits_s1_af;
        w_s0_io_tlb_1_resp_bits_s1_af |= ~w_g_io_tlb_1_resp_bits_s1_af;
        checks++;
        if (w_g_io_tlb_1_resp_bits_s2_entry_tag !== w_i_io_tlb_1_resp_bits_s2_entry_tag) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d L2TLBWrapper.io_tlb_1_resp_bits_s2_entry_tag g=%h i=%h", cyc, w_g_io_tlb_1_resp_bits_s2_entry_tag, w_i_io_tlb_1_resp_bits_s2_entry_tag);
        end
        w_s1_io_tlb_1_resp_bits_s2_entry_tag |= w_g_io_tlb_1_resp_bits_s2_entry_tag;
        w_s0_io_tlb_1_resp_bits_s2_entry_tag |= ~w_g_io_tlb_1_resp_bits_s2_entry_tag;
        checks++;
        if (w_g_io_tlb_1_resp_bits_s2_entry_vmid !== w_i_io_tlb_1_resp_bits_s2_entry_vmid) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d L2TLBWrapper.io_tlb_1_resp_bits_s2_entry_vmid g=%h i=%h", cyc, w_g_io_tlb_1_resp_bits_s2_entry_vmid, w_i_io_tlb_1_resp_bits_s2_entry_vmid);
        end
        w_s1_io_tlb_1_resp_bits_s2_entry_vmid |= w_g_io_tlb_1_resp_bits_s2_entry_vmid;
        w_s0_io_tlb_1_resp_bits_s2_entry_vmid |= ~w_g_io_tlb_1_resp_bits_s2_entry_vmid;
        checks++;
        if (w_g_io_tlb_1_resp_bits_s2_entry_n !== w_i_io_tlb_1_resp_bits_s2_entry_n) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d L2TLBWrapper.io_tlb_1_resp_bits_s2_entry_n g=%h i=%h", cyc, w_g_io_tlb_1_resp_bits_s2_entry_n, w_i_io_tlb_1_resp_bits_s2_entry_n);
        end
        w_s1_io_tlb_1_resp_bits_s2_entry_n |= w_g_io_tlb_1_resp_bits_s2_entry_n;
        w_s0_io_tlb_1_resp_bits_s2_entry_n |= ~w_g_io_tlb_1_resp_bits_s2_entry_n;
        checks++;
        if (w_g_io_tlb_1_resp_bits_s2_entry_pbmt !== w_i_io_tlb_1_resp_bits_s2_entry_pbmt) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d L2TLBWrapper.io_tlb_1_resp_bits_s2_entry_pbmt g=%h i=%h", cyc, w_g_io_tlb_1_resp_bits_s2_entry_pbmt, w_i_io_tlb_1_resp_bits_s2_entry_pbmt);
        end
        w_s1_io_tlb_1_resp_bits_s2_entry_pbmt |= w_g_io_tlb_1_resp_bits_s2_entry_pbmt;
        w_s0_io_tlb_1_resp_bits_s2_entry_pbmt |= ~w_g_io_tlb_1_resp_bits_s2_entry_pbmt;
        checks++;
        if (w_g_io_tlb_1_resp_bits_s2_entry_ppn !== w_i_io_tlb_1_resp_bits_s2_entry_ppn) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d L2TLBWrapper.io_tlb_1_resp_bits_s2_entry_ppn g=%h i=%h", cyc, w_g_io_tlb_1_resp_bits_s2_entry_ppn, w_i_io_tlb_1_resp_bits_s2_entry_ppn);
        end
        w_s1_io_tlb_1_resp_bits_s2_entry_ppn |= w_g_io_tlb_1_resp_bits_s2_entry_ppn;
        w_s0_io_tlb_1_resp_bits_s2_entry_ppn |= ~w_g_io_tlb_1_resp_bits_s2_entry_ppn;
        checks++;
        if (w_g_io_tlb_1_resp_bits_s2_entry_perm_d !== w_i_io_tlb_1_resp_bits_s2_entry_perm_d) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d L2TLBWrapper.io_tlb_1_resp_bits_s2_entry_perm_d g=%h i=%h", cyc, w_g_io_tlb_1_resp_bits_s2_entry_perm_d, w_i_io_tlb_1_resp_bits_s2_entry_perm_d);
        end
        w_s1_io_tlb_1_resp_bits_s2_entry_perm_d |= w_g_io_tlb_1_resp_bits_s2_entry_perm_d;
        w_s0_io_tlb_1_resp_bits_s2_entry_perm_d |= ~w_g_io_tlb_1_resp_bits_s2_entry_perm_d;
        checks++;
        if (w_g_io_tlb_1_resp_bits_s2_entry_perm_a !== w_i_io_tlb_1_resp_bits_s2_entry_perm_a) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d L2TLBWrapper.io_tlb_1_resp_bits_s2_entry_perm_a g=%h i=%h", cyc, w_g_io_tlb_1_resp_bits_s2_entry_perm_a, w_i_io_tlb_1_resp_bits_s2_entry_perm_a);
        end
        w_s1_io_tlb_1_resp_bits_s2_entry_perm_a |= w_g_io_tlb_1_resp_bits_s2_entry_perm_a;
        w_s0_io_tlb_1_resp_bits_s2_entry_perm_a |= ~w_g_io_tlb_1_resp_bits_s2_entry_perm_a;
        checks++;
        if (w_g_io_tlb_1_resp_bits_s2_entry_perm_g !== w_i_io_tlb_1_resp_bits_s2_entry_perm_g) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d L2TLBWrapper.io_tlb_1_resp_bits_s2_entry_perm_g g=%h i=%h", cyc, w_g_io_tlb_1_resp_bits_s2_entry_perm_g, w_i_io_tlb_1_resp_bits_s2_entry_perm_g);
        end
        w_s1_io_tlb_1_resp_bits_s2_entry_perm_g |= w_g_io_tlb_1_resp_bits_s2_entry_perm_g;
        w_s0_io_tlb_1_resp_bits_s2_entry_perm_g |= ~w_g_io_tlb_1_resp_bits_s2_entry_perm_g;
        checks++;
        if (w_g_io_tlb_1_resp_bits_s2_entry_perm_u !== w_i_io_tlb_1_resp_bits_s2_entry_perm_u) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d L2TLBWrapper.io_tlb_1_resp_bits_s2_entry_perm_u g=%h i=%h", cyc, w_g_io_tlb_1_resp_bits_s2_entry_perm_u, w_i_io_tlb_1_resp_bits_s2_entry_perm_u);
        end
        w_s1_io_tlb_1_resp_bits_s2_entry_perm_u |= w_g_io_tlb_1_resp_bits_s2_entry_perm_u;
        w_s0_io_tlb_1_resp_bits_s2_entry_perm_u |= ~w_g_io_tlb_1_resp_bits_s2_entry_perm_u;
        checks++;
        if (w_g_io_tlb_1_resp_bits_s2_entry_perm_x !== w_i_io_tlb_1_resp_bits_s2_entry_perm_x) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d L2TLBWrapper.io_tlb_1_resp_bits_s2_entry_perm_x g=%h i=%h", cyc, w_g_io_tlb_1_resp_bits_s2_entry_perm_x, w_i_io_tlb_1_resp_bits_s2_entry_perm_x);
        end
        w_s1_io_tlb_1_resp_bits_s2_entry_perm_x |= w_g_io_tlb_1_resp_bits_s2_entry_perm_x;
        w_s0_io_tlb_1_resp_bits_s2_entry_perm_x |= ~w_g_io_tlb_1_resp_bits_s2_entry_perm_x;
        checks++;
        if (w_g_io_tlb_1_resp_bits_s2_entry_perm_w !== w_i_io_tlb_1_resp_bits_s2_entry_perm_w) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d L2TLBWrapper.io_tlb_1_resp_bits_s2_entry_perm_w g=%h i=%h", cyc, w_g_io_tlb_1_resp_bits_s2_entry_perm_w, w_i_io_tlb_1_resp_bits_s2_entry_perm_w);
        end
        w_s1_io_tlb_1_resp_bits_s2_entry_perm_w |= w_g_io_tlb_1_resp_bits_s2_entry_perm_w;
        w_s0_io_tlb_1_resp_bits_s2_entry_perm_w |= ~w_g_io_tlb_1_resp_bits_s2_entry_perm_w;
        checks++;
        if (w_g_io_tlb_1_resp_bits_s2_entry_perm_r !== w_i_io_tlb_1_resp_bits_s2_entry_perm_r) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d L2TLBWrapper.io_tlb_1_resp_bits_s2_entry_perm_r g=%h i=%h", cyc, w_g_io_tlb_1_resp_bits_s2_entry_perm_r, w_i_io_tlb_1_resp_bits_s2_entry_perm_r);
        end
        w_s1_io_tlb_1_resp_bits_s2_entry_perm_r |= w_g_io_tlb_1_resp_bits_s2_entry_perm_r;
        w_s0_io_tlb_1_resp_bits_s2_entry_perm_r |= ~w_g_io_tlb_1_resp_bits_s2_entry_perm_r;
        checks++;
        if (w_g_io_tlb_1_resp_bits_s2_entry_level !== w_i_io_tlb_1_resp_bits_s2_entry_level) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d L2TLBWrapper.io_tlb_1_resp_bits_s2_entry_level g=%h i=%h", cyc, w_g_io_tlb_1_resp_bits_s2_entry_level, w_i_io_tlb_1_resp_bits_s2_entry_level);
        end
        w_s1_io_tlb_1_resp_bits_s2_entry_level |= w_g_io_tlb_1_resp_bits_s2_entry_level;
        w_s0_io_tlb_1_resp_bits_s2_entry_level |= ~w_g_io_tlb_1_resp_bits_s2_entry_level;
        checks++;
        if (w_g_io_tlb_1_resp_bits_s2_gpf !== w_i_io_tlb_1_resp_bits_s2_gpf) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d L2TLBWrapper.io_tlb_1_resp_bits_s2_gpf g=%h i=%h", cyc, w_g_io_tlb_1_resp_bits_s2_gpf, w_i_io_tlb_1_resp_bits_s2_gpf);
        end
        w_s1_io_tlb_1_resp_bits_s2_gpf |= w_g_io_tlb_1_resp_bits_s2_gpf;
        w_s0_io_tlb_1_resp_bits_s2_gpf |= ~w_g_io_tlb_1_resp_bits_s2_gpf;
        checks++;
        if (w_g_io_tlb_1_resp_bits_s2_gaf !== w_i_io_tlb_1_resp_bits_s2_gaf) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d L2TLBWrapper.io_tlb_1_resp_bits_s2_gaf g=%h i=%h", cyc, w_g_io_tlb_1_resp_bits_s2_gaf, w_i_io_tlb_1_resp_bits_s2_gaf);
        end
        w_s1_io_tlb_1_resp_bits_s2_gaf |= w_g_io_tlb_1_resp_bits_s2_gaf;
        w_s0_io_tlb_1_resp_bits_s2_gaf |= ~w_g_io_tlb_1_resp_bits_s2_gaf;
        checks++;
        if (w_g_io_wfi_wfiSafe !== w_i_io_wfi_wfiSafe) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d L2TLBWrapper.io_wfi_wfiSafe g=%h i=%h", cyc, w_g_io_wfi_wfiSafe, w_i_io_wfi_wfiSafe);
        end
        w_s1_io_wfi_wfiSafe |= w_g_io_wfi_wfiSafe;
        w_s0_io_wfi_wfiSafe |= ~w_g_io_wfi_wfiSafe;
        checks++;
        if (w_g_io_perf_0_value !== w_i_io_perf_0_value) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d L2TLBWrapper.io_perf_0_value g=%h i=%h", cyc, w_g_io_perf_0_value, w_i_io_perf_0_value);
        end
        w_s1_io_perf_0_value |= w_g_io_perf_0_value;
        w_s0_io_perf_0_value |= ~w_g_io_perf_0_value;
        checks++;
        if (w_g_io_perf_1_value !== w_i_io_perf_1_value) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d L2TLBWrapper.io_perf_1_value g=%h i=%h", cyc, w_g_io_perf_1_value, w_i_io_perf_1_value);
        end
        w_s1_io_perf_1_value |= w_g_io_perf_1_value;
        w_s0_io_perf_1_value |= ~w_g_io_perf_1_value;
        checks++;
        if (w_g_io_perf_2_value !== w_i_io_perf_2_value) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d L2TLBWrapper.io_perf_2_value g=%h i=%h", cyc, w_g_io_perf_2_value, w_i_io_perf_2_value);
        end
        w_s1_io_perf_2_value |= w_g_io_perf_2_value;
        w_s0_io_perf_2_value |= ~w_g_io_perf_2_value;
        checks++;
        if (w_g_io_perf_3_value !== w_i_io_perf_3_value) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d L2TLBWrapper.io_perf_3_value g=%h i=%h", cyc, w_g_io_perf_3_value, w_i_io_perf_3_value);
        end
        w_s1_io_perf_3_value |= w_g_io_perf_3_value;
        w_s0_io_perf_3_value |= ~w_g_io_perf_3_value;
        checks++;
        if (w_g_io_perf_4_value !== w_i_io_perf_4_value) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d L2TLBWrapper.io_perf_4_value g=%h i=%h", cyc, w_g_io_perf_4_value, w_i_io_perf_4_value);
        end
        w_s1_io_perf_4_value |= w_g_io_perf_4_value;
        w_s0_io_perf_4_value |= ~w_g_io_perf_4_value;
        checks++;
        if (w_g_io_perf_5_value !== w_i_io_perf_5_value) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d L2TLBWrapper.io_perf_5_value g=%h i=%h", cyc, w_g_io_perf_5_value, w_i_io_perf_5_value);
        end
        w_s1_io_perf_5_value |= w_g_io_perf_5_value;
        w_s0_io_perf_5_value |= ~w_g_io_perf_5_value;
        checks++;
        if (w_g_io_perf_6_value !== w_i_io_perf_6_value) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d L2TLBWrapper.io_perf_6_value g=%h i=%h", cyc, w_g_io_perf_6_value, w_i_io_perf_6_value);
        end
        w_s1_io_perf_6_value |= w_g_io_perf_6_value;
        w_s0_io_perf_6_value |= ~w_g_io_perf_6_value;
        checks++;
        if (w_g_io_perf_7_value !== w_i_io_perf_7_value) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d L2TLBWrapper.io_perf_7_value g=%h i=%h", cyc, w_g_io_perf_7_value, w_i_io_perf_7_value);
        end
        w_s1_io_perf_7_value |= w_g_io_perf_7_value;
        w_s0_io_perf_7_value |= ~w_g_io_perf_7_value;
        checks++;
        if (w_g_io_perf_8_value !== w_i_io_perf_8_value) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d L2TLBWrapper.io_perf_8_value g=%h i=%h", cyc, w_g_io_perf_8_value, w_i_io_perf_8_value);
        end
        w_s1_io_perf_8_value |= w_g_io_perf_8_value;
        w_s0_io_perf_8_value |= ~w_g_io_perf_8_value;
        checks++;
        if (w_g_io_perf_9_value !== w_i_io_perf_9_value) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d L2TLBWrapper.io_perf_9_value g=%h i=%h", cyc, w_g_io_perf_9_value, w_i_io_perf_9_value);
        end
        w_s1_io_perf_9_value |= w_g_io_perf_9_value;
        w_s0_io_perf_9_value |= ~w_g_io_perf_9_value;
        checks++;
        if (w_g_io_perf_10_value !== w_i_io_perf_10_value) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d L2TLBWrapper.io_perf_10_value g=%h i=%h", cyc, w_g_io_perf_10_value, w_i_io_perf_10_value);
        end
        w_s1_io_perf_10_value |= w_g_io_perf_10_value;
        w_s0_io_perf_10_value |= ~w_g_io_perf_10_value;
        checks++;
        if (w_g_io_perf_11_value !== w_i_io_perf_11_value) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d L2TLBWrapper.io_perf_11_value g=%h i=%h", cyc, w_g_io_perf_11_value, w_i_io_perf_11_value);
        end
        w_s1_io_perf_11_value |= w_g_io_perf_11_value;
        w_s0_io_perf_11_value |= ~w_g_io_perf_11_value;
        checks++;
        if (w_g_io_perf_12_value !== w_i_io_perf_12_value) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d L2TLBWrapper.io_perf_12_value g=%h i=%h", cyc, w_g_io_perf_12_value, w_i_io_perf_12_value);
        end
        w_s1_io_perf_12_value |= w_g_io_perf_12_value;
        w_s0_io_perf_12_value |= ~w_g_io_perf_12_value;
        checks++;
        if (w_g_io_perf_13_value !== w_i_io_perf_13_value) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d L2TLBWrapper.io_perf_13_value g=%h i=%h", cyc, w_g_io_perf_13_value, w_i_io_perf_13_value);
        end
        w_s1_io_perf_13_value |= w_g_io_perf_13_value;
        w_s0_io_perf_13_value |= ~w_g_io_perf_13_value;
        checks++;
        if (w_g_io_perf_14_value !== w_i_io_perf_14_value) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d L2TLBWrapper.io_perf_14_value g=%h i=%h", cyc, w_g_io_perf_14_value, w_i_io_perf_14_value);
        end
        w_s1_io_perf_14_value |= w_g_io_perf_14_value;
        w_s0_io_perf_14_value |= ~w_g_io_perf_14_value;
        checks++;
        if (w_g_io_perf_15_value !== w_i_io_perf_15_value) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d L2TLBWrapper.io_perf_15_value g=%h i=%h", cyc, w_g_io_perf_15_value, w_i_io_perf_15_value);
        end
        w_s1_io_perf_15_value |= w_g_io_perf_15_value;
        w_s0_io_perf_15_value |= ~w_g_io_perf_15_value;
        checks++;
        if (w_g_io_perf_16_value !== w_i_io_perf_16_value) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d L2TLBWrapper.io_perf_16_value g=%h i=%h", cyc, w_g_io_perf_16_value, w_i_io_perf_16_value);
        end
        w_s1_io_perf_16_value |= w_g_io_perf_16_value;
        w_s0_io_perf_16_value |= ~w_g_io_perf_16_value;
        checks++;
        if (w_g_io_perf_17_value !== w_i_io_perf_17_value) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d L2TLBWrapper.io_perf_17_value g=%h i=%h", cyc, w_g_io_perf_17_value, w_i_io_perf_17_value);
        end
        w_s1_io_perf_17_value |= w_g_io_perf_17_value;
        w_s0_io_perf_17_value |= ~w_g_io_perf_17_value;
        checks++;
        if (w_g_io_perf_18_value !== w_i_io_perf_18_value) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d L2TLBWrapper.io_perf_18_value g=%h i=%h", cyc, w_g_io_perf_18_value, w_i_io_perf_18_value);
        end
        w_s1_io_perf_18_value |= w_g_io_perf_18_value;
        w_s0_io_perf_18_value |= ~w_g_io_perf_18_value;
        checks++;
        if (w_g_boreChildrenBd_bore_ack !== w_i_boreChildrenBd_bore_ack) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d L2TLBWrapper.boreChildrenBd_bore_ack g=%h i=%h", cyc, w_g_boreChildrenBd_bore_ack, w_i_boreChildrenBd_bore_ack);
        end
        w_s1_boreChildrenBd_bore_ack |= w_g_boreChildrenBd_bore_ack;
        w_s0_boreChildrenBd_bore_ack |= ~w_g_boreChildrenBd_bore_ack;
        checks++;
        if (w_g_boreChildrenBd_bore_outdata !== w_i_boreChildrenBd_bore_outdata) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d L2TLBWrapper.boreChildrenBd_bore_outdata g=%h i=%h", cyc, w_g_boreChildrenBd_bore_outdata, w_i_boreChildrenBd_bore_outdata);
        end
        w_s1_boreChildrenBd_bore_outdata |= w_g_boreChildrenBd_bore_outdata;
        w_s0_boreChildrenBd_bore_outdata |= ~w_g_boreChildrenBd_bore_outdata;
        checks++;
        if (w_g_boreChildrenBd_bore_1_ack !== w_i_boreChildrenBd_bore_1_ack) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d L2TLBWrapper.boreChildrenBd_bore_1_ack g=%h i=%h", cyc, w_g_boreChildrenBd_bore_1_ack, w_i_boreChildrenBd_bore_1_ack);
        end
        w_s1_boreChildrenBd_bore_1_ack |= w_g_boreChildrenBd_bore_1_ack;
        w_s0_boreChildrenBd_bore_1_ack |= ~w_g_boreChildrenBd_bore_1_ack;
        checks++;
        if (w_g_boreChildrenBd_bore_1_outdata !== w_i_boreChildrenBd_bore_1_outdata) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d L2TLBWrapper.boreChildrenBd_bore_1_outdata g=%h i=%h", cyc, w_g_boreChildrenBd_bore_1_outdata, w_i_boreChildrenBd_bore_1_outdata);
        end
        w_s1_boreChildrenBd_bore_1_outdata |= w_g_boreChildrenBd_bore_1_outdata;
        w_s0_boreChildrenBd_bore_1_outdata |= ~w_g_boreChildrenBd_bore_1_outdata;
        checks++;
        if (w_g_boreChildrenBd_bore_2_ack !== w_i_boreChildrenBd_bore_2_ack) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d L2TLBWrapper.boreChildrenBd_bore_2_ack g=%h i=%h", cyc, w_g_boreChildrenBd_bore_2_ack, w_i_boreChildrenBd_bore_2_ack);
        end
        w_s1_boreChildrenBd_bore_2_ack |= w_g_boreChildrenBd_bore_2_ack;
        w_s0_boreChildrenBd_bore_2_ack |= ~w_g_boreChildrenBd_bore_2_ack;
        checks++;
        if (w_g_boreChildrenBd_bore_2_outdata !== w_i_boreChildrenBd_bore_2_outdata) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d L2TLBWrapper.boreChildrenBd_bore_2_outdata g=%h i=%h", cyc, w_g_boreChildrenBd_bore_2_outdata, w_i_boreChildrenBd_bore_2_outdata);
        end
        w_s1_boreChildrenBd_bore_2_outdata |= w_g_boreChildrenBd_bore_2_outdata;
        w_s0_boreChildrenBd_bore_2_outdata |= ~w_g_boreChildrenBd_bore_2_outdata;
        checks++;
        if (w_g_gatewayIn_packed_43_bore !== w_i_gatewayIn_packed_43_bore) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d L2TLBWrapper.gatewayIn_packed_43_bore g=%h i=%h", cyc, w_g_gatewayIn_packed_43_bore, w_i_gatewayIn_packed_43_bore);
        end
        w_s1_gatewayIn_packed_43_bore |= w_g_gatewayIn_packed_43_bore;
        w_s0_gatewayIn_packed_43_bore |= ~w_g_gatewayIn_packed_43_bore;
        checks++;
        if (w_g_gatewayIn_packed_44_bore !== w_i_gatewayIn_packed_44_bore) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d L2TLBWrapper.gatewayIn_packed_44_bore g=%h i=%h", cyc, w_g_gatewayIn_packed_44_bore, w_i_gatewayIn_packed_44_bore);
        end
        w_s1_gatewayIn_packed_44_bore |= w_g_gatewayIn_packed_44_bore;
        w_s0_gatewayIn_packed_44_bore |= ~w_g_gatewayIn_packed_44_bore;
        checks++;
        if (w_g_gatewayIn_packed_45_bore !== w_i_gatewayIn_packed_45_bore) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d L2TLBWrapper.gatewayIn_packed_45_bore g=%h i=%h", cyc, w_g_gatewayIn_packed_45_bore, w_i_gatewayIn_packed_45_bore);
        end
        w_s1_gatewayIn_packed_45_bore |= w_g_gatewayIn_packed_45_bore;
        w_s0_gatewayIn_packed_45_bore |= ~w_g_gatewayIn_packed_45_bore;
        if (|w_g_io_perf_0_value || |w_g_io_perf_3_value || |w_g_io_perf_10_value) w_cov_perf_nz++;
        if (w_g_auto_out_a_valid && w_auto_out_a_ready) w_cov_ptw_req++;
        if (w_g_io_tlb_0_resp_valid || w_g_io_tlb_1_resp_valid) w_cov_tlb_resp++;
      end
      if (w_armed_at < 0 && (&w_armed)) w_armed_at = cyc + 1;
    end

    // ---- 覆盖闸 ----
    if (!(w_s0_auto_out_a_valid && w_s1_auto_out_a_valid)) begin cov_fail++; $display("[COV] L2TLBWrapper.auto_out_a_valid 未见过 0 和 1"); end
    if (!(w_s0_auto_out_a_bits_source[0] && w_s1_auto_out_a_bits_source[0])) begin cov_fail++; $display("[COV] L2TLBWrapper.auto_out_a_bits_source[0] 未见过 0 和 1"); end
    if (!(w_s0_auto_out_a_bits_source[1] && w_s1_auto_out_a_bits_source[1])) begin cov_fail++; $display("[COV] L2TLBWrapper.auto_out_a_bits_source[1] 未见过 0 和 1"); end
    if (!(w_s0_auto_out_a_bits_source[2] && w_s1_auto_out_a_bits_source[2])) begin cov_fail++; $display("[COV] L2TLBWrapper.auto_out_a_bits_source[2] 未见过 0 和 1"); end
    if (!(w_s0_auto_out_a_bits_source[3] && w_s1_auto_out_a_bits_source[3])) begin cov_fail++; $display("[COV] L2TLBWrapper.auto_out_a_bits_source[3] 未见过 0 和 1"); end
    if (!(w_s0_auto_out_a_bits_address[0] && w_s1_auto_out_a_bits_address[0])) begin cov_fail++; $display("[COV] L2TLBWrapper.auto_out_a_bits_address[0] 未见过 0 和 1"); end
    if (!(w_s0_auto_out_a_bits_address[1] && w_s1_auto_out_a_bits_address[1])) begin cov_fail++; $display("[COV] L2TLBWrapper.auto_out_a_bits_address[1] 未见过 0 和 1"); end
    if (!(w_s0_auto_out_a_bits_address[2] && w_s1_auto_out_a_bits_address[2])) begin cov_fail++; $display("[COV] L2TLBWrapper.auto_out_a_bits_address[2] 未见过 0 和 1"); end
    if (!(w_s0_auto_out_a_bits_address[3] && w_s1_auto_out_a_bits_address[3])) begin cov_fail++; $display("[COV] L2TLBWrapper.auto_out_a_bits_address[3] 未见过 0 和 1"); end
    if (!(w_s0_auto_out_a_bits_address[4] && w_s1_auto_out_a_bits_address[4])) begin cov_fail++; $display("[COV] L2TLBWrapper.auto_out_a_bits_address[4] 未见过 0 和 1"); end
    if (!(w_s0_auto_out_a_bits_address[5] && w_s1_auto_out_a_bits_address[5])) begin cov_fail++; $display("[COV] L2TLBWrapper.auto_out_a_bits_address[5] 未见过 0 和 1"); end
    if (!(w_s0_auto_out_a_bits_address[6] && w_s1_auto_out_a_bits_address[6])) begin cov_fail++; $display("[COV] L2TLBWrapper.auto_out_a_bits_address[6] 未见过 0 和 1"); end
    if (!(w_s0_auto_out_a_bits_address[7] && w_s1_auto_out_a_bits_address[7])) begin cov_fail++; $display("[COV] L2TLBWrapper.auto_out_a_bits_address[7] 未见过 0 和 1"); end
    if (!(w_s0_auto_out_a_bits_address[8] && w_s1_auto_out_a_bits_address[8])) begin cov_fail++; $display("[COV] L2TLBWrapper.auto_out_a_bits_address[8] 未见过 0 和 1"); end
    if (!(w_s0_auto_out_a_bits_address[9] && w_s1_auto_out_a_bits_address[9])) begin cov_fail++; $display("[COV] L2TLBWrapper.auto_out_a_bits_address[9] 未见过 0 和 1"); end
    if (!(w_s0_auto_out_a_bits_address[10] && w_s1_auto_out_a_bits_address[10])) begin cov_fail++; $display("[COV] L2TLBWrapper.auto_out_a_bits_address[10] 未见过 0 和 1"); end
    if (!(w_s0_auto_out_a_bits_address[11] && w_s1_auto_out_a_bits_address[11])) begin cov_fail++; $display("[COV] L2TLBWrapper.auto_out_a_bits_address[11] 未见过 0 和 1"); end
    if (!(w_s0_auto_out_a_bits_address[12] && w_s1_auto_out_a_bits_address[12])) begin cov_fail++; $display("[COV] L2TLBWrapper.auto_out_a_bits_address[12] 未见过 0 和 1"); end
    if (!(w_s0_auto_out_a_bits_address[13] && w_s1_auto_out_a_bits_address[13])) begin cov_fail++; $display("[COV] L2TLBWrapper.auto_out_a_bits_address[13] 未见过 0 和 1"); end
    if (!(w_s0_auto_out_a_bits_address[14] && w_s1_auto_out_a_bits_address[14])) begin cov_fail++; $display("[COV] L2TLBWrapper.auto_out_a_bits_address[14] 未见过 0 和 1"); end
    if (!(w_s0_auto_out_a_bits_address[15] && w_s1_auto_out_a_bits_address[15])) begin cov_fail++; $display("[COV] L2TLBWrapper.auto_out_a_bits_address[15] 未见过 0 和 1"); end
    if (!(w_s0_auto_out_a_bits_address[16] && w_s1_auto_out_a_bits_address[16])) begin cov_fail++; $display("[COV] L2TLBWrapper.auto_out_a_bits_address[16] 未见过 0 和 1"); end
    if (!(w_s0_auto_out_a_bits_address[17] && w_s1_auto_out_a_bits_address[17])) begin cov_fail++; $display("[COV] L2TLBWrapper.auto_out_a_bits_address[17] 未见过 0 和 1"); end
    if (!(w_s0_auto_out_a_bits_address[18] && w_s1_auto_out_a_bits_address[18])) begin cov_fail++; $display("[COV] L2TLBWrapper.auto_out_a_bits_address[18] 未见过 0 和 1"); end
    if (!(w_s0_auto_out_a_bits_address[19] && w_s1_auto_out_a_bits_address[19])) begin cov_fail++; $display("[COV] L2TLBWrapper.auto_out_a_bits_address[19] 未见过 0 和 1"); end
    if (!(w_s0_auto_out_a_bits_address[20] && w_s1_auto_out_a_bits_address[20])) begin cov_fail++; $display("[COV] L2TLBWrapper.auto_out_a_bits_address[20] 未见过 0 和 1"); end
    if (!(w_s0_auto_out_a_bits_address[21] && w_s1_auto_out_a_bits_address[21])) begin cov_fail++; $display("[COV] L2TLBWrapper.auto_out_a_bits_address[21] 未见过 0 和 1"); end
    if (!(w_s0_auto_out_a_bits_address[22] && w_s1_auto_out_a_bits_address[22])) begin cov_fail++; $display("[COV] L2TLBWrapper.auto_out_a_bits_address[22] 未见过 0 和 1"); end
    if (!(w_s0_auto_out_a_bits_address[23] && w_s1_auto_out_a_bits_address[23])) begin cov_fail++; $display("[COV] L2TLBWrapper.auto_out_a_bits_address[23] 未见过 0 和 1"); end
    if (!(w_s0_auto_out_a_bits_address[24] && w_s1_auto_out_a_bits_address[24])) begin cov_fail++; $display("[COV] L2TLBWrapper.auto_out_a_bits_address[24] 未见过 0 和 1"); end
    if (!(w_s0_auto_out_a_bits_address[25] && w_s1_auto_out_a_bits_address[25])) begin cov_fail++; $display("[COV] L2TLBWrapper.auto_out_a_bits_address[25] 未见过 0 和 1"); end
    if (!(w_s0_auto_out_a_bits_address[26] && w_s1_auto_out_a_bits_address[26])) begin cov_fail++; $display("[COV] L2TLBWrapper.auto_out_a_bits_address[26] 未见过 0 和 1"); end
    if (!(w_s0_auto_out_a_bits_address[27] && w_s1_auto_out_a_bits_address[27])) begin cov_fail++; $display("[COV] L2TLBWrapper.auto_out_a_bits_address[27] 未见过 0 和 1"); end
    if (!(w_s0_auto_out_a_bits_address[28] && w_s1_auto_out_a_bits_address[28])) begin cov_fail++; $display("[COV] L2TLBWrapper.auto_out_a_bits_address[28] 未见过 0 和 1"); end
    if (!(w_s0_auto_out_a_bits_address[29] && w_s1_auto_out_a_bits_address[29])) begin cov_fail++; $display("[COV] L2TLBWrapper.auto_out_a_bits_address[29] 未见过 0 和 1"); end
    if (!(w_s0_auto_out_a_bits_address[30] && w_s1_auto_out_a_bits_address[30])) begin cov_fail++; $display("[COV] L2TLBWrapper.auto_out_a_bits_address[30] 未见过 0 和 1"); end
    if (!(w_s0_auto_out_a_bits_address[31] && w_s1_auto_out_a_bits_address[31])) begin cov_fail++; $display("[COV] L2TLBWrapper.auto_out_a_bits_address[31] 未见过 0 和 1"); end
    if (!(w_s0_auto_out_a_bits_address[32] && w_s1_auto_out_a_bits_address[32])) begin cov_fail++; $display("[COV] L2TLBWrapper.auto_out_a_bits_address[32] 未见过 0 和 1"); end
    if (!(w_s0_auto_out_a_bits_address[33] && w_s1_auto_out_a_bits_address[33])) begin cov_fail++; $display("[COV] L2TLBWrapper.auto_out_a_bits_address[33] 未见过 0 和 1"); end
    if (!(w_s0_auto_out_a_bits_address[34] && w_s1_auto_out_a_bits_address[34])) begin cov_fail++; $display("[COV] L2TLBWrapper.auto_out_a_bits_address[34] 未见过 0 和 1"); end
    if (!(w_s0_auto_out_a_bits_address[35] && w_s1_auto_out_a_bits_address[35])) begin cov_fail++; $display("[COV] L2TLBWrapper.auto_out_a_bits_address[35] 未见过 0 和 1"); end
    if (!(w_s0_auto_out_a_bits_address[36] && w_s1_auto_out_a_bits_address[36])) begin cov_fail++; $display("[COV] L2TLBWrapper.auto_out_a_bits_address[36] 未见过 0 和 1"); end
    if (!(w_s0_auto_out_a_bits_address[37] && w_s1_auto_out_a_bits_address[37])) begin cov_fail++; $display("[COV] L2TLBWrapper.auto_out_a_bits_address[37] 未见过 0 和 1"); end
    if (!(w_s0_auto_out_a_bits_address[38] && w_s1_auto_out_a_bits_address[38])) begin cov_fail++; $display("[COV] L2TLBWrapper.auto_out_a_bits_address[38] 未见过 0 和 1"); end
    if (!(w_s0_auto_out_a_bits_address[39] && w_s1_auto_out_a_bits_address[39])) begin cov_fail++; $display("[COV] L2TLBWrapper.auto_out_a_bits_address[39] 未见过 0 和 1"); end
    if (!(w_s0_auto_out_a_bits_address[40] && w_s1_auto_out_a_bits_address[40])) begin cov_fail++; $display("[COV] L2TLBWrapper.auto_out_a_bits_address[40] 未见过 0 和 1"); end
    if (!(w_s0_auto_out_a_bits_address[41] && w_s1_auto_out_a_bits_address[41])) begin cov_fail++; $display("[COV] L2TLBWrapper.auto_out_a_bits_address[41] 未见过 0 和 1"); end
    if (!(w_s0_auto_out_a_bits_address[42] && w_s1_auto_out_a_bits_address[42])) begin cov_fail++; $display("[COV] L2TLBWrapper.auto_out_a_bits_address[42] 未见过 0 和 1"); end
    if (!(w_s0_auto_out_a_bits_address[43] && w_s1_auto_out_a_bits_address[43])) begin cov_fail++; $display("[COV] L2TLBWrapper.auto_out_a_bits_address[43] 未见过 0 和 1"); end
    if (!(w_s0_auto_out_a_bits_address[44] && w_s1_auto_out_a_bits_address[44])) begin cov_fail++; $display("[COV] L2TLBWrapper.auto_out_a_bits_address[44] 未见过 0 和 1"); end
    if (!(w_s0_auto_out_a_bits_address[45] && w_s1_auto_out_a_bits_address[45])) begin cov_fail++; $display("[COV] L2TLBWrapper.auto_out_a_bits_address[45] 未见过 0 和 1"); end
    if (!(w_s0_auto_out_a_bits_address[46] && w_s1_auto_out_a_bits_address[46])) begin cov_fail++; $display("[COV] L2TLBWrapper.auto_out_a_bits_address[46] 未见过 0 和 1"); end
    if (!(w_s0_auto_out_a_bits_address[47] && w_s1_auto_out_a_bits_address[47])) begin cov_fail++; $display("[COV] L2TLBWrapper.auto_out_a_bits_address[47] 未见过 0 和 1"); end
    if (!(w_s0_io_tlb_0_req_0_ready && w_s1_io_tlb_0_req_0_ready)) begin cov_fail++; $display("[COV] L2TLBWrapper.io_tlb_0_req_0_ready 未见过 0 和 1"); end
    if (!(w_s0_io_tlb_0_resp_valid && w_s1_io_tlb_0_resp_valid)) begin cov_fail++; $display("[COV] L2TLBWrapper.io_tlb_0_resp_valid 未见过 0 和 1"); end
    if (!(w_s0_io_tlb_0_resp_bits_s2xlate[0] && w_s1_io_tlb_0_resp_bits_s2xlate[0])) begin cov_fail++; $display("[COV] L2TLBWrapper.io_tlb_0_resp_bits_s2xlate[0] 未见过 0 和 1"); end
    if (!(w_s0_io_tlb_0_resp_bits_s2xlate[1] && w_s1_io_tlb_0_resp_bits_s2xlate[1])) begin cov_fail++; $display("[COV] L2TLBWrapper.io_tlb_0_resp_bits_s2xlate[1] 未见过 0 和 1"); end
    if (!(w_s0_io_tlb_0_resp_bits_s1_entry_tag[0] && w_s1_io_tlb_0_resp_bits_s1_entry_tag[0])) begin cov_fail++; $display("[COV] L2TLBWrapper.io_tlb_0_resp_bits_s1_entry_tag[0] 未见过 0 和 1"); end
    if (!(w_s0_io_tlb_0_resp_bits_s1_entry_tag[1] && w_s1_io_tlb_0_resp_bits_s1_entry_tag[1])) begin cov_fail++; $display("[COV] L2TLBWrapper.io_tlb_0_resp_bits_s1_entry_tag[1] 未见过 0 和 1"); end
    if (!(w_s0_io_tlb_0_resp_bits_s1_entry_tag[2] && w_s1_io_tlb_0_resp_bits_s1_entry_tag[2])) begin cov_fail++; $display("[COV] L2TLBWrapper.io_tlb_0_resp_bits_s1_entry_tag[2] 未见过 0 和 1"); end
    if (!(w_s0_io_tlb_0_resp_bits_s1_entry_tag[3] && w_s1_io_tlb_0_resp_bits_s1_entry_tag[3])) begin cov_fail++; $display("[COV] L2TLBWrapper.io_tlb_0_resp_bits_s1_entry_tag[3] 未见过 0 和 1"); end
    if (!(w_s0_io_tlb_0_resp_bits_s1_entry_tag[4] && w_s1_io_tlb_0_resp_bits_s1_entry_tag[4])) begin cov_fail++; $display("[COV] L2TLBWrapper.io_tlb_0_resp_bits_s1_entry_tag[4] 未见过 0 和 1"); end
    if (!(w_s0_io_tlb_0_resp_bits_s1_entry_tag[5] && w_s1_io_tlb_0_resp_bits_s1_entry_tag[5])) begin cov_fail++; $display("[COV] L2TLBWrapper.io_tlb_0_resp_bits_s1_entry_tag[5] 未见过 0 和 1"); end
    if (!(w_s0_io_tlb_0_resp_bits_s1_entry_tag[6] && w_s1_io_tlb_0_resp_bits_s1_entry_tag[6])) begin cov_fail++; $display("[COV] L2TLBWrapper.io_tlb_0_resp_bits_s1_entry_tag[6] 未见过 0 和 1"); end
    if (!(w_s0_io_tlb_0_resp_bits_s1_entry_tag[7] && w_s1_io_tlb_0_resp_bits_s1_entry_tag[7])) begin cov_fail++; $display("[COV] L2TLBWrapper.io_tlb_0_resp_bits_s1_entry_tag[7] 未见过 0 和 1"); end
    if (!(w_s0_io_tlb_0_resp_bits_s1_entry_tag[8] && w_s1_io_tlb_0_resp_bits_s1_entry_tag[8])) begin cov_fail++; $display("[COV] L2TLBWrapper.io_tlb_0_resp_bits_s1_entry_tag[8] 未见过 0 和 1"); end
    if (!(w_s0_io_tlb_0_resp_bits_s1_entry_tag[9] && w_s1_io_tlb_0_resp_bits_s1_entry_tag[9])) begin cov_fail++; $display("[COV] L2TLBWrapper.io_tlb_0_resp_bits_s1_entry_tag[9] 未见过 0 和 1"); end
    if (!(w_s0_io_tlb_0_resp_bits_s1_entry_tag[10] && w_s1_io_tlb_0_resp_bits_s1_entry_tag[10])) begin cov_fail++; $display("[COV] L2TLBWrapper.io_tlb_0_resp_bits_s1_entry_tag[10] 未见过 0 和 1"); end
    if (!(w_s0_io_tlb_0_resp_bits_s1_entry_tag[11] && w_s1_io_tlb_0_resp_bits_s1_entry_tag[11])) begin cov_fail++; $display("[COV] L2TLBWrapper.io_tlb_0_resp_bits_s1_entry_tag[11] 未见过 0 和 1"); end
    if (!(w_s0_io_tlb_0_resp_bits_s1_entry_tag[12] && w_s1_io_tlb_0_resp_bits_s1_entry_tag[12])) begin cov_fail++; $display("[COV] L2TLBWrapper.io_tlb_0_resp_bits_s1_entry_tag[12] 未见过 0 和 1"); end
    if (!(w_s0_io_tlb_0_resp_bits_s1_entry_tag[13] && w_s1_io_tlb_0_resp_bits_s1_entry_tag[13])) begin cov_fail++; $display("[COV] L2TLBWrapper.io_tlb_0_resp_bits_s1_entry_tag[13] 未见过 0 和 1"); end
    if (!(w_s0_io_tlb_0_resp_bits_s1_entry_tag[14] && w_s1_io_tlb_0_resp_bits_s1_entry_tag[14])) begin cov_fail++; $display("[COV] L2TLBWrapper.io_tlb_0_resp_bits_s1_entry_tag[14] 未见过 0 和 1"); end
    if (!(w_s0_io_tlb_0_resp_bits_s1_entry_tag[15] && w_s1_io_tlb_0_resp_bits_s1_entry_tag[15])) begin cov_fail++; $display("[COV] L2TLBWrapper.io_tlb_0_resp_bits_s1_entry_tag[15] 未见过 0 和 1"); end
    if (!(w_s0_io_tlb_0_resp_bits_s1_entry_tag[16] && w_s1_io_tlb_0_resp_bits_s1_entry_tag[16])) begin cov_fail++; $display("[COV] L2TLBWrapper.io_tlb_0_resp_bits_s1_entry_tag[16] 未见过 0 和 1"); end
    if (!(w_s0_io_tlb_0_resp_bits_s1_entry_tag[17] && w_s1_io_tlb_0_resp_bits_s1_entry_tag[17])) begin cov_fail++; $display("[COV] L2TLBWrapper.io_tlb_0_resp_bits_s1_entry_tag[17] 未见过 0 和 1"); end
    if (!(w_s0_io_tlb_0_resp_bits_s1_entry_tag[18] && w_s1_io_tlb_0_resp_bits_s1_entry_tag[18])) begin cov_fail++; $display("[COV] L2TLBWrapper.io_tlb_0_resp_bits_s1_entry_tag[18] 未见过 0 和 1"); end
    if (!(w_s0_io_tlb_0_resp_bits_s1_entry_tag[19] && w_s1_io_tlb_0_resp_bits_s1_entry_tag[19])) begin cov_fail++; $display("[COV] L2TLBWrapper.io_tlb_0_resp_bits_s1_entry_tag[19] 未见过 0 和 1"); end
    if (!(w_s0_io_tlb_0_resp_bits_s1_entry_tag[20] && w_s1_io_tlb_0_resp_bits_s1_entry_tag[20])) begin cov_fail++; $display("[COV] L2TLBWrapper.io_tlb_0_resp_bits_s1_entry_tag[20] 未见过 0 和 1"); end
    if (!(w_s0_io_tlb_0_resp_bits_s1_entry_tag[21] && w_s1_io_tlb_0_resp_bits_s1_entry_tag[21])) begin cov_fail++; $display("[COV] L2TLBWrapper.io_tlb_0_resp_bits_s1_entry_tag[21] 未见过 0 和 1"); end
    if (!(w_s0_io_tlb_0_resp_bits_s1_entry_tag[22] && w_s1_io_tlb_0_resp_bits_s1_entry_tag[22])) begin cov_fail++; $display("[COV] L2TLBWrapper.io_tlb_0_resp_bits_s1_entry_tag[22] 未见过 0 和 1"); end
    if (!(w_s0_io_tlb_0_resp_bits_s1_entry_tag[23] && w_s1_io_tlb_0_resp_bits_s1_entry_tag[23])) begin cov_fail++; $display("[COV] L2TLBWrapper.io_tlb_0_resp_bits_s1_entry_tag[23] 未见过 0 和 1"); end
    if (!(w_s0_io_tlb_0_resp_bits_s1_entry_tag[24] && w_s1_io_tlb_0_resp_bits_s1_entry_tag[24])) begin cov_fail++; $display("[COV] L2TLBWrapper.io_tlb_0_resp_bits_s1_entry_tag[24] 未见过 0 和 1"); end
    if (!(w_s0_io_tlb_0_resp_bits_s1_entry_tag[25] && w_s1_io_tlb_0_resp_bits_s1_entry_tag[25])) begin cov_fail++; $display("[COV] L2TLBWrapper.io_tlb_0_resp_bits_s1_entry_tag[25] 未见过 0 和 1"); end
    if (!(w_s0_io_tlb_0_resp_bits_s1_entry_tag[26] && w_s1_io_tlb_0_resp_bits_s1_entry_tag[26])) begin cov_fail++; $display("[COV] L2TLBWrapper.io_tlb_0_resp_bits_s1_entry_tag[26] 未见过 0 和 1"); end
    if (!(w_s0_io_tlb_0_resp_bits_s1_entry_tag[27] && w_s1_io_tlb_0_resp_bits_s1_entry_tag[27])) begin cov_fail++; $display("[COV] L2TLBWrapper.io_tlb_0_resp_bits_s1_entry_tag[27] 未见过 0 和 1"); end
    if (!(w_s0_io_tlb_0_resp_bits_s1_entry_tag[28] && w_s1_io_tlb_0_resp_bits_s1_entry_tag[28])) begin cov_fail++; $display("[COV] L2TLBWrapper.io_tlb_0_resp_bits_s1_entry_tag[28] 未见过 0 和 1"); end
    if (!(w_s0_io_tlb_0_resp_bits_s1_entry_tag[29] && w_s1_io_tlb_0_resp_bits_s1_entry_tag[29])) begin cov_fail++; $display("[COV] L2TLBWrapper.io_tlb_0_resp_bits_s1_entry_tag[29] 未见过 0 和 1"); end
    if (!(w_s0_io_tlb_0_resp_bits_s1_entry_tag[30] && w_s1_io_tlb_0_resp_bits_s1_entry_tag[30])) begin cov_fail++; $display("[COV] L2TLBWrapper.io_tlb_0_resp_bits_s1_entry_tag[30] 未见过 0 和 1"); end
    if (!(w_s0_io_tlb_0_resp_bits_s1_entry_tag[31] && w_s1_io_tlb_0_resp_bits_s1_entry_tag[31])) begin cov_fail++; $display("[COV] L2TLBWrapper.io_tlb_0_resp_bits_s1_entry_tag[31] 未见过 0 和 1"); end
    if (!(w_s0_io_tlb_0_resp_bits_s1_entry_tag[32] && w_s1_io_tlb_0_resp_bits_s1_entry_tag[32])) begin cov_fail++; $display("[COV] L2TLBWrapper.io_tlb_0_resp_bits_s1_entry_tag[32] 未见过 0 和 1"); end
    if (!(w_s0_io_tlb_0_resp_bits_s1_entry_tag[33] && w_s1_io_tlb_0_resp_bits_s1_entry_tag[33])) begin cov_fail++; $display("[COV] L2TLBWrapper.io_tlb_0_resp_bits_s1_entry_tag[33] 未见过 0 和 1"); end
    if (!(w_s0_io_tlb_0_resp_bits_s1_entry_tag[34] && w_s1_io_tlb_0_resp_bits_s1_entry_tag[34])) begin cov_fail++; $display("[COV] L2TLBWrapper.io_tlb_0_resp_bits_s1_entry_tag[34] 未见过 0 和 1"); end
    if (!(w_s0_io_tlb_0_resp_bits_s1_entry_asid[0] && w_s1_io_tlb_0_resp_bits_s1_entry_asid[0])) begin cov_fail++; $display("[COV] L2TLBWrapper.io_tlb_0_resp_bits_s1_entry_asid[0] 未见过 0 和 1"); end
    if (!(w_s0_io_tlb_0_resp_bits_s1_entry_asid[1] && w_s1_io_tlb_0_resp_bits_s1_entry_asid[1])) begin cov_fail++; $display("[COV] L2TLBWrapper.io_tlb_0_resp_bits_s1_entry_asid[1] 未见过 0 和 1"); end
    if (!(w_s0_io_tlb_0_resp_bits_s1_entry_asid[2] && w_s1_io_tlb_0_resp_bits_s1_entry_asid[2])) begin cov_fail++; $display("[COV] L2TLBWrapper.io_tlb_0_resp_bits_s1_entry_asid[2] 未见过 0 和 1"); end
    if (!(w_s0_io_tlb_0_resp_bits_s1_entry_asid[3] && w_s1_io_tlb_0_resp_bits_s1_entry_asid[3])) begin cov_fail++; $display("[COV] L2TLBWrapper.io_tlb_0_resp_bits_s1_entry_asid[3] 未见过 0 和 1"); end
    if (!(w_s0_io_tlb_0_resp_bits_s1_entry_asid[4] && w_s1_io_tlb_0_resp_bits_s1_entry_asid[4])) begin cov_fail++; $display("[COV] L2TLBWrapper.io_tlb_0_resp_bits_s1_entry_asid[4] 未见过 0 和 1"); end
    if (!(w_s0_io_tlb_0_resp_bits_s1_entry_asid[5] && w_s1_io_tlb_0_resp_bits_s1_entry_asid[5])) begin cov_fail++; $display("[COV] L2TLBWrapper.io_tlb_0_resp_bits_s1_entry_asid[5] 未见过 0 和 1"); end
    if (!(w_s0_io_tlb_0_resp_bits_s1_entry_asid[6] && w_s1_io_tlb_0_resp_bits_s1_entry_asid[6])) begin cov_fail++; $display("[COV] L2TLBWrapper.io_tlb_0_resp_bits_s1_entry_asid[6] 未见过 0 和 1"); end
    if (!(w_s0_io_tlb_0_resp_bits_s1_entry_asid[7] && w_s1_io_tlb_0_resp_bits_s1_entry_asid[7])) begin cov_fail++; $display("[COV] L2TLBWrapper.io_tlb_0_resp_bits_s1_entry_asid[7] 未见过 0 和 1"); end
    if (!(w_s0_io_tlb_0_resp_bits_s1_entry_asid[8] && w_s1_io_tlb_0_resp_bits_s1_entry_asid[8])) begin cov_fail++; $display("[COV] L2TLBWrapper.io_tlb_0_resp_bits_s1_entry_asid[8] 未见过 0 和 1"); end
    if (!(w_s0_io_tlb_0_resp_bits_s1_entry_asid[9] && w_s1_io_tlb_0_resp_bits_s1_entry_asid[9])) begin cov_fail++; $display("[COV] L2TLBWrapper.io_tlb_0_resp_bits_s1_entry_asid[9] 未见过 0 和 1"); end
    if (!(w_s0_io_tlb_0_resp_bits_s1_entry_asid[10] && w_s1_io_tlb_0_resp_bits_s1_entry_asid[10])) begin cov_fail++; $display("[COV] L2TLBWrapper.io_tlb_0_resp_bits_s1_entry_asid[10] 未见过 0 和 1"); end
    if (!(w_s0_io_tlb_0_resp_bits_s1_entry_asid[11] && w_s1_io_tlb_0_resp_bits_s1_entry_asid[11])) begin cov_fail++; $display("[COV] L2TLBWrapper.io_tlb_0_resp_bits_s1_entry_asid[11] 未见过 0 和 1"); end
    if (!(w_s0_io_tlb_0_resp_bits_s1_entry_asid[12] && w_s1_io_tlb_0_resp_bits_s1_entry_asid[12])) begin cov_fail++; $display("[COV] L2TLBWrapper.io_tlb_0_resp_bits_s1_entry_asid[12] 未见过 0 和 1"); end
    if (!(w_s0_io_tlb_0_resp_bits_s1_entry_asid[13] && w_s1_io_tlb_0_resp_bits_s1_entry_asid[13])) begin cov_fail++; $display("[COV] L2TLBWrapper.io_tlb_0_resp_bits_s1_entry_asid[13] 未见过 0 和 1"); end
    if (!(w_s0_io_tlb_0_resp_bits_s1_entry_asid[14] && w_s1_io_tlb_0_resp_bits_s1_entry_asid[14])) begin cov_fail++; $display("[COV] L2TLBWrapper.io_tlb_0_resp_bits_s1_entry_asid[14] 未见过 0 和 1"); end
    if (!(w_s0_io_tlb_0_resp_bits_s1_entry_asid[15] && w_s1_io_tlb_0_resp_bits_s1_entry_asid[15])) begin cov_fail++; $display("[COV] L2TLBWrapper.io_tlb_0_resp_bits_s1_entry_asid[15] 未见过 0 和 1"); end
    if (!(w_s0_io_tlb_0_resp_bits_s1_entry_vmid[0] && w_s1_io_tlb_0_resp_bits_s1_entry_vmid[0])) begin cov_fail++; $display("[COV] L2TLBWrapper.io_tlb_0_resp_bits_s1_entry_vmid[0] 未见过 0 和 1"); end
    if (!(w_s0_io_tlb_0_resp_bits_s1_entry_vmid[1] && w_s1_io_tlb_0_resp_bits_s1_entry_vmid[1])) begin cov_fail++; $display("[COV] L2TLBWrapper.io_tlb_0_resp_bits_s1_entry_vmid[1] 未见过 0 和 1"); end
    if (!(w_s0_io_tlb_0_resp_bits_s1_entry_vmid[2] && w_s1_io_tlb_0_resp_bits_s1_entry_vmid[2])) begin cov_fail++; $display("[COV] L2TLBWrapper.io_tlb_0_resp_bits_s1_entry_vmid[2] 未见过 0 和 1"); end
    if (!(w_s0_io_tlb_0_resp_bits_s1_entry_vmid[3] && w_s1_io_tlb_0_resp_bits_s1_entry_vmid[3])) begin cov_fail++; $display("[COV] L2TLBWrapper.io_tlb_0_resp_bits_s1_entry_vmid[3] 未见过 0 和 1"); end
    if (!(w_s0_io_tlb_0_resp_bits_s1_entry_vmid[4] && w_s1_io_tlb_0_resp_bits_s1_entry_vmid[4])) begin cov_fail++; $display("[COV] L2TLBWrapper.io_tlb_0_resp_bits_s1_entry_vmid[4] 未见过 0 和 1"); end
    if (!(w_s0_io_tlb_0_resp_bits_s1_entry_vmid[5] && w_s1_io_tlb_0_resp_bits_s1_entry_vmid[5])) begin cov_fail++; $display("[COV] L2TLBWrapper.io_tlb_0_resp_bits_s1_entry_vmid[5] 未见过 0 和 1"); end
    if (!(w_s0_io_tlb_0_resp_bits_s1_entry_vmid[6] && w_s1_io_tlb_0_resp_bits_s1_entry_vmid[6])) begin cov_fail++; $display("[COV] L2TLBWrapper.io_tlb_0_resp_bits_s1_entry_vmid[6] 未见过 0 和 1"); end
    if (!(w_s0_io_tlb_0_resp_bits_s1_entry_vmid[7] && w_s1_io_tlb_0_resp_bits_s1_entry_vmid[7])) begin cov_fail++; $display("[COV] L2TLBWrapper.io_tlb_0_resp_bits_s1_entry_vmid[7] 未见过 0 和 1"); end
    if (!(w_s0_io_tlb_0_resp_bits_s1_entry_vmid[8] && w_s1_io_tlb_0_resp_bits_s1_entry_vmid[8])) begin cov_fail++; $display("[COV] L2TLBWrapper.io_tlb_0_resp_bits_s1_entry_vmid[8] 未见过 0 和 1"); end
    if (!(w_s0_io_tlb_0_resp_bits_s1_entry_vmid[9] && w_s1_io_tlb_0_resp_bits_s1_entry_vmid[9])) begin cov_fail++; $display("[COV] L2TLBWrapper.io_tlb_0_resp_bits_s1_entry_vmid[9] 未见过 0 和 1"); end
    if (!(w_s0_io_tlb_0_resp_bits_s1_entry_vmid[10] && w_s1_io_tlb_0_resp_bits_s1_entry_vmid[10])) begin cov_fail++; $display("[COV] L2TLBWrapper.io_tlb_0_resp_bits_s1_entry_vmid[10] 未见过 0 和 1"); end
    if (!(w_s0_io_tlb_0_resp_bits_s1_entry_vmid[11] && w_s1_io_tlb_0_resp_bits_s1_entry_vmid[11])) begin cov_fail++; $display("[COV] L2TLBWrapper.io_tlb_0_resp_bits_s1_entry_vmid[11] 未见过 0 和 1"); end
    if (!(w_s0_io_tlb_0_resp_bits_s1_entry_vmid[12] && w_s1_io_tlb_0_resp_bits_s1_entry_vmid[12])) begin cov_fail++; $display("[COV] L2TLBWrapper.io_tlb_0_resp_bits_s1_entry_vmid[12] 未见过 0 和 1"); end
    if (!(w_s0_io_tlb_0_resp_bits_s1_entry_vmid[13] && w_s1_io_tlb_0_resp_bits_s1_entry_vmid[13])) begin cov_fail++; $display("[COV] L2TLBWrapper.io_tlb_0_resp_bits_s1_entry_vmid[13] 未见过 0 和 1"); end
    if (!(w_s0_io_tlb_0_resp_bits_s1_entry_n && w_s1_io_tlb_0_resp_bits_s1_entry_n)) begin cov_fail++; $display("[COV] L2TLBWrapper.io_tlb_0_resp_bits_s1_entry_n 未见过 0 和 1"); end
    if (!(w_s0_io_tlb_0_resp_bits_s1_entry_pbmt[0] && w_s1_io_tlb_0_resp_bits_s1_entry_pbmt[0])) begin cov_fail++; $display("[COV] L2TLBWrapper.io_tlb_0_resp_bits_s1_entry_pbmt[0] 未见过 0 和 1"); end
    if (!(w_s0_io_tlb_0_resp_bits_s1_entry_pbmt[1] && w_s1_io_tlb_0_resp_bits_s1_entry_pbmt[1])) begin cov_fail++; $display("[COV] L2TLBWrapper.io_tlb_0_resp_bits_s1_entry_pbmt[1] 未见过 0 和 1"); end
    if (!(w_s0_io_tlb_0_resp_bits_s1_entry_perm_d && w_s1_io_tlb_0_resp_bits_s1_entry_perm_d)) begin cov_fail++; $display("[COV] L2TLBWrapper.io_tlb_0_resp_bits_s1_entry_perm_d 未见过 0 和 1"); end
    if (!(w_s0_io_tlb_0_resp_bits_s1_entry_perm_a && w_s1_io_tlb_0_resp_bits_s1_entry_perm_a)) begin cov_fail++; $display("[COV] L2TLBWrapper.io_tlb_0_resp_bits_s1_entry_perm_a 未见过 0 和 1"); end
    if (!(w_s0_io_tlb_0_resp_bits_s1_entry_perm_g && w_s1_io_tlb_0_resp_bits_s1_entry_perm_g)) begin cov_fail++; $display("[COV] L2TLBWrapper.io_tlb_0_resp_bits_s1_entry_perm_g 未见过 0 和 1"); end
    if (!(w_s0_io_tlb_0_resp_bits_s1_entry_perm_u && w_s1_io_tlb_0_resp_bits_s1_entry_perm_u)) begin cov_fail++; $display("[COV] L2TLBWrapper.io_tlb_0_resp_bits_s1_entry_perm_u 未见过 0 和 1"); end
    if (!(w_s0_io_tlb_0_resp_bits_s1_entry_perm_x && w_s1_io_tlb_0_resp_bits_s1_entry_perm_x)) begin cov_fail++; $display("[COV] L2TLBWrapper.io_tlb_0_resp_bits_s1_entry_perm_x 未见过 0 和 1"); end
    if (!(w_s0_io_tlb_0_resp_bits_s1_entry_perm_w && w_s1_io_tlb_0_resp_bits_s1_entry_perm_w)) begin cov_fail++; $display("[COV] L2TLBWrapper.io_tlb_0_resp_bits_s1_entry_perm_w 未见过 0 和 1"); end
    if (!(w_s0_io_tlb_0_resp_bits_s1_entry_perm_r && w_s1_io_tlb_0_resp_bits_s1_entry_perm_r)) begin cov_fail++; $display("[COV] L2TLBWrapper.io_tlb_0_resp_bits_s1_entry_perm_r 未见过 0 和 1"); end
    if (!(w_s0_io_tlb_0_resp_bits_s1_entry_level[0] && w_s1_io_tlb_0_resp_bits_s1_entry_level[0])) begin cov_fail++; $display("[COV] L2TLBWrapper.io_tlb_0_resp_bits_s1_entry_level[0] 未见过 0 和 1"); end
    if (!(w_s0_io_tlb_0_resp_bits_s1_entry_level[1] && w_s1_io_tlb_0_resp_bits_s1_entry_level[1])) begin cov_fail++; $display("[COV] L2TLBWrapper.io_tlb_0_resp_bits_s1_entry_level[1] 未见过 0 和 1"); end
    if (!(w_s0_io_tlb_0_resp_bits_s1_entry_v && w_s1_io_tlb_0_resp_bits_s1_entry_v)) begin cov_fail++; $display("[COV] L2TLBWrapper.io_tlb_0_resp_bits_s1_entry_v 未见过 0 和 1"); end
    if (!(w_s0_io_tlb_0_resp_bits_s1_entry_ppn[0] && w_s1_io_tlb_0_resp_bits_s1_entry_ppn[0])) begin cov_fail++; $display("[COV] L2TLBWrapper.io_tlb_0_resp_bits_s1_entry_ppn[0] 未见过 0 和 1"); end
    if (!(w_s0_io_tlb_0_resp_bits_s1_entry_ppn[1] && w_s1_io_tlb_0_resp_bits_s1_entry_ppn[1])) begin cov_fail++; $display("[COV] L2TLBWrapper.io_tlb_0_resp_bits_s1_entry_ppn[1] 未见过 0 和 1"); end
    if (!(w_s0_io_tlb_0_resp_bits_s1_entry_ppn[2] && w_s1_io_tlb_0_resp_bits_s1_entry_ppn[2])) begin cov_fail++; $display("[COV] L2TLBWrapper.io_tlb_0_resp_bits_s1_entry_ppn[2] 未见过 0 和 1"); end
    if (!(w_s0_io_tlb_0_resp_bits_s1_entry_ppn[3] && w_s1_io_tlb_0_resp_bits_s1_entry_ppn[3])) begin cov_fail++; $display("[COV] L2TLBWrapper.io_tlb_0_resp_bits_s1_entry_ppn[3] 未见过 0 和 1"); end
    if (!(w_s0_io_tlb_0_resp_bits_s1_entry_ppn[4] && w_s1_io_tlb_0_resp_bits_s1_entry_ppn[4])) begin cov_fail++; $display("[COV] L2TLBWrapper.io_tlb_0_resp_bits_s1_entry_ppn[4] 未见过 0 和 1"); end
    if (!(w_s0_io_tlb_0_resp_bits_s1_entry_ppn[5] && w_s1_io_tlb_0_resp_bits_s1_entry_ppn[5])) begin cov_fail++; $display("[COV] L2TLBWrapper.io_tlb_0_resp_bits_s1_entry_ppn[5] 未见过 0 和 1"); end
    if (!(w_s0_io_tlb_0_resp_bits_s1_entry_ppn[6] && w_s1_io_tlb_0_resp_bits_s1_entry_ppn[6])) begin cov_fail++; $display("[COV] L2TLBWrapper.io_tlb_0_resp_bits_s1_entry_ppn[6] 未见过 0 和 1"); end
    if (!(w_s0_io_tlb_0_resp_bits_s1_entry_ppn[7] && w_s1_io_tlb_0_resp_bits_s1_entry_ppn[7])) begin cov_fail++; $display("[COV] L2TLBWrapper.io_tlb_0_resp_bits_s1_entry_ppn[7] 未见过 0 和 1"); end
    if (!(w_s0_io_tlb_0_resp_bits_s1_entry_ppn[8] && w_s1_io_tlb_0_resp_bits_s1_entry_ppn[8])) begin cov_fail++; $display("[COV] L2TLBWrapper.io_tlb_0_resp_bits_s1_entry_ppn[8] 未见过 0 和 1"); end
    if (!(w_s0_io_tlb_0_resp_bits_s1_entry_ppn[9] && w_s1_io_tlb_0_resp_bits_s1_entry_ppn[9])) begin cov_fail++; $display("[COV] L2TLBWrapper.io_tlb_0_resp_bits_s1_entry_ppn[9] 未见过 0 和 1"); end
    if (!(w_s0_io_tlb_0_resp_bits_s1_entry_ppn[10] && w_s1_io_tlb_0_resp_bits_s1_entry_ppn[10])) begin cov_fail++; $display("[COV] L2TLBWrapper.io_tlb_0_resp_bits_s1_entry_ppn[10] 未见过 0 和 1"); end
    if (!(w_s0_io_tlb_0_resp_bits_s1_entry_ppn[11] && w_s1_io_tlb_0_resp_bits_s1_entry_ppn[11])) begin cov_fail++; $display("[COV] L2TLBWrapper.io_tlb_0_resp_bits_s1_entry_ppn[11] 未见过 0 和 1"); end
    if (!(w_s0_io_tlb_0_resp_bits_s1_entry_ppn[12] && w_s1_io_tlb_0_resp_bits_s1_entry_ppn[12])) begin cov_fail++; $display("[COV] L2TLBWrapper.io_tlb_0_resp_bits_s1_entry_ppn[12] 未见过 0 和 1"); end
    if (!(w_s0_io_tlb_0_resp_bits_s1_entry_ppn[13] && w_s1_io_tlb_0_resp_bits_s1_entry_ppn[13])) begin cov_fail++; $display("[COV] L2TLBWrapper.io_tlb_0_resp_bits_s1_entry_ppn[13] 未见过 0 和 1"); end
    if (!(w_s0_io_tlb_0_resp_bits_s1_entry_ppn[14] && w_s1_io_tlb_0_resp_bits_s1_entry_ppn[14])) begin cov_fail++; $display("[COV] L2TLBWrapper.io_tlb_0_resp_bits_s1_entry_ppn[14] 未见过 0 和 1"); end
    if (!(w_s0_io_tlb_0_resp_bits_s1_entry_ppn[15] && w_s1_io_tlb_0_resp_bits_s1_entry_ppn[15])) begin cov_fail++; $display("[COV] L2TLBWrapper.io_tlb_0_resp_bits_s1_entry_ppn[15] 未见过 0 和 1"); end
    if (!(w_s0_io_tlb_0_resp_bits_s1_entry_ppn[16] && w_s1_io_tlb_0_resp_bits_s1_entry_ppn[16])) begin cov_fail++; $display("[COV] L2TLBWrapper.io_tlb_0_resp_bits_s1_entry_ppn[16] 未见过 0 和 1"); end
    if (!(w_s0_io_tlb_0_resp_bits_s1_entry_ppn[17] && w_s1_io_tlb_0_resp_bits_s1_entry_ppn[17])) begin cov_fail++; $display("[COV] L2TLBWrapper.io_tlb_0_resp_bits_s1_entry_ppn[17] 未见过 0 和 1"); end
    if (!(w_s0_io_tlb_0_resp_bits_s1_entry_ppn[18] && w_s1_io_tlb_0_resp_bits_s1_entry_ppn[18])) begin cov_fail++; $display("[COV] L2TLBWrapper.io_tlb_0_resp_bits_s1_entry_ppn[18] 未见过 0 和 1"); end
    if (!(w_s0_io_tlb_0_resp_bits_s1_entry_ppn[19] && w_s1_io_tlb_0_resp_bits_s1_entry_ppn[19])) begin cov_fail++; $display("[COV] L2TLBWrapper.io_tlb_0_resp_bits_s1_entry_ppn[19] 未见过 0 和 1"); end
    if (!(w_s0_io_tlb_0_resp_bits_s1_entry_ppn[20] && w_s1_io_tlb_0_resp_bits_s1_entry_ppn[20])) begin cov_fail++; $display("[COV] L2TLBWrapper.io_tlb_0_resp_bits_s1_entry_ppn[20] 未见过 0 和 1"); end
    if (!(w_s0_io_tlb_0_resp_bits_s1_entry_ppn[21] && w_s1_io_tlb_0_resp_bits_s1_entry_ppn[21])) begin cov_fail++; $display("[COV] L2TLBWrapper.io_tlb_0_resp_bits_s1_entry_ppn[21] 未见过 0 和 1"); end
    if (!(w_s0_io_tlb_0_resp_bits_s1_entry_ppn[22] && w_s1_io_tlb_0_resp_bits_s1_entry_ppn[22])) begin cov_fail++; $display("[COV] L2TLBWrapper.io_tlb_0_resp_bits_s1_entry_ppn[22] 未见过 0 和 1"); end
    if (!(w_s0_io_tlb_0_resp_bits_s1_entry_ppn[23] && w_s1_io_tlb_0_resp_bits_s1_entry_ppn[23])) begin cov_fail++; $display("[COV] L2TLBWrapper.io_tlb_0_resp_bits_s1_entry_ppn[23] 未见过 0 和 1"); end
    if (!(w_s0_io_tlb_0_resp_bits_s1_entry_ppn[24] && w_s1_io_tlb_0_resp_bits_s1_entry_ppn[24])) begin cov_fail++; $display("[COV] L2TLBWrapper.io_tlb_0_resp_bits_s1_entry_ppn[24] 未见过 0 和 1"); end
    if (!(w_s0_io_tlb_0_resp_bits_s1_entry_ppn[25] && w_s1_io_tlb_0_resp_bits_s1_entry_ppn[25])) begin cov_fail++; $display("[COV] L2TLBWrapper.io_tlb_0_resp_bits_s1_entry_ppn[25] 未见过 0 和 1"); end
    if (!(w_s0_io_tlb_0_resp_bits_s1_entry_ppn[26] && w_s1_io_tlb_0_resp_bits_s1_entry_ppn[26])) begin cov_fail++; $display("[COV] L2TLBWrapper.io_tlb_0_resp_bits_s1_entry_ppn[26] 未见过 0 和 1"); end
    if (!(w_s0_io_tlb_0_resp_bits_s1_entry_ppn[27] && w_s1_io_tlb_0_resp_bits_s1_entry_ppn[27])) begin cov_fail++; $display("[COV] L2TLBWrapper.io_tlb_0_resp_bits_s1_entry_ppn[27] 未见过 0 和 1"); end
    if (!(w_s0_io_tlb_0_resp_bits_s1_entry_ppn[28] && w_s1_io_tlb_0_resp_bits_s1_entry_ppn[28])) begin cov_fail++; $display("[COV] L2TLBWrapper.io_tlb_0_resp_bits_s1_entry_ppn[28] 未见过 0 和 1"); end
    if (!(w_s0_io_tlb_0_resp_bits_s1_entry_ppn[29] && w_s1_io_tlb_0_resp_bits_s1_entry_ppn[29])) begin cov_fail++; $display("[COV] L2TLBWrapper.io_tlb_0_resp_bits_s1_entry_ppn[29] 未见过 0 和 1"); end
    if (!(w_s0_io_tlb_0_resp_bits_s1_entry_ppn[30] && w_s1_io_tlb_0_resp_bits_s1_entry_ppn[30])) begin cov_fail++; $display("[COV] L2TLBWrapper.io_tlb_0_resp_bits_s1_entry_ppn[30] 未见过 0 和 1"); end
    if (!(w_s0_io_tlb_0_resp_bits_s1_entry_ppn[31] && w_s1_io_tlb_0_resp_bits_s1_entry_ppn[31])) begin cov_fail++; $display("[COV] L2TLBWrapper.io_tlb_0_resp_bits_s1_entry_ppn[31] 未见过 0 和 1"); end
    if (!(w_s0_io_tlb_0_resp_bits_s1_entry_ppn[32] && w_s1_io_tlb_0_resp_bits_s1_entry_ppn[32])) begin cov_fail++; $display("[COV] L2TLBWrapper.io_tlb_0_resp_bits_s1_entry_ppn[32] 未见过 0 和 1"); end
    if (!(w_s0_io_tlb_0_resp_bits_s1_entry_ppn[33] && w_s1_io_tlb_0_resp_bits_s1_entry_ppn[33])) begin cov_fail++; $display("[COV] L2TLBWrapper.io_tlb_0_resp_bits_s1_entry_ppn[33] 未见过 0 和 1"); end
    if (!(w_s0_io_tlb_0_resp_bits_s1_entry_ppn[34] && w_s1_io_tlb_0_resp_bits_s1_entry_ppn[34])) begin cov_fail++; $display("[COV] L2TLBWrapper.io_tlb_0_resp_bits_s1_entry_ppn[34] 未见过 0 和 1"); end
    if (!(w_s0_io_tlb_0_resp_bits_s1_entry_ppn[35] && w_s1_io_tlb_0_resp_bits_s1_entry_ppn[35])) begin cov_fail++; $display("[COV] L2TLBWrapper.io_tlb_0_resp_bits_s1_entry_ppn[35] 未见过 0 和 1"); end
    if (!(w_s0_io_tlb_0_resp_bits_s1_entry_ppn[36] && w_s1_io_tlb_0_resp_bits_s1_entry_ppn[36])) begin cov_fail++; $display("[COV] L2TLBWrapper.io_tlb_0_resp_bits_s1_entry_ppn[36] 未见过 0 和 1"); end
    if (!(w_s0_io_tlb_0_resp_bits_s1_entry_ppn[37] && w_s1_io_tlb_0_resp_bits_s1_entry_ppn[37])) begin cov_fail++; $display("[COV] L2TLBWrapper.io_tlb_0_resp_bits_s1_entry_ppn[37] 未见过 0 和 1"); end
    if (!(w_s0_io_tlb_0_resp_bits_s1_entry_ppn[38] && w_s1_io_tlb_0_resp_bits_s1_entry_ppn[38])) begin cov_fail++; $display("[COV] L2TLBWrapper.io_tlb_0_resp_bits_s1_entry_ppn[38] 未见过 0 和 1"); end
    if (!(w_s0_io_tlb_0_resp_bits_s1_entry_ppn[39] && w_s1_io_tlb_0_resp_bits_s1_entry_ppn[39])) begin cov_fail++; $display("[COV] L2TLBWrapper.io_tlb_0_resp_bits_s1_entry_ppn[39] 未见过 0 和 1"); end
    if (!(w_s0_io_tlb_0_resp_bits_s1_entry_ppn[40] && w_s1_io_tlb_0_resp_bits_s1_entry_ppn[40])) begin cov_fail++; $display("[COV] L2TLBWrapper.io_tlb_0_resp_bits_s1_entry_ppn[40] 未见过 0 和 1"); end
    if (!(w_s0_io_tlb_0_resp_bits_s1_addr_low[0] && w_s1_io_tlb_0_resp_bits_s1_addr_low[0])) begin cov_fail++; $display("[COV] L2TLBWrapper.io_tlb_0_resp_bits_s1_addr_low[0] 未见过 0 和 1"); end
    if (!(w_s0_io_tlb_0_resp_bits_s1_addr_low[1] && w_s1_io_tlb_0_resp_bits_s1_addr_low[1])) begin cov_fail++; $display("[COV] L2TLBWrapper.io_tlb_0_resp_bits_s1_addr_low[1] 未见过 0 和 1"); end
    if (!(w_s0_io_tlb_0_resp_bits_s1_addr_low[2] && w_s1_io_tlb_0_resp_bits_s1_addr_low[2])) begin cov_fail++; $display("[COV] L2TLBWrapper.io_tlb_0_resp_bits_s1_addr_low[2] 未见过 0 和 1"); end
    if (!(w_s0_io_tlb_0_resp_bits_s1_ppn_low_0[0] && w_s1_io_tlb_0_resp_bits_s1_ppn_low_0[0])) begin cov_fail++; $display("[COV] L2TLBWrapper.io_tlb_0_resp_bits_s1_ppn_low_0[0] 未见过 0 和 1"); end
    if (!(w_s0_io_tlb_0_resp_bits_s1_ppn_low_0[1] && w_s1_io_tlb_0_resp_bits_s1_ppn_low_0[1])) begin cov_fail++; $display("[COV] L2TLBWrapper.io_tlb_0_resp_bits_s1_ppn_low_0[1] 未见过 0 和 1"); end
    if (!(w_s0_io_tlb_0_resp_bits_s1_ppn_low_0[2] && w_s1_io_tlb_0_resp_bits_s1_ppn_low_0[2])) begin cov_fail++; $display("[COV] L2TLBWrapper.io_tlb_0_resp_bits_s1_ppn_low_0[2] 未见过 0 和 1"); end
    if (!(w_s0_io_tlb_0_resp_bits_s1_ppn_low_1[0] && w_s1_io_tlb_0_resp_bits_s1_ppn_low_1[0])) begin cov_fail++; $display("[COV] L2TLBWrapper.io_tlb_0_resp_bits_s1_ppn_low_1[0] 未见过 0 和 1"); end
    if (!(w_s0_io_tlb_0_resp_bits_s1_ppn_low_1[1] && w_s1_io_tlb_0_resp_bits_s1_ppn_low_1[1])) begin cov_fail++; $display("[COV] L2TLBWrapper.io_tlb_0_resp_bits_s1_ppn_low_1[1] 未见过 0 和 1"); end
    if (!(w_s0_io_tlb_0_resp_bits_s1_ppn_low_1[2] && w_s1_io_tlb_0_resp_bits_s1_ppn_low_1[2])) begin cov_fail++; $display("[COV] L2TLBWrapper.io_tlb_0_resp_bits_s1_ppn_low_1[2] 未见过 0 和 1"); end
    if (!(w_s0_io_tlb_0_resp_bits_s1_ppn_low_2[0] && w_s1_io_tlb_0_resp_bits_s1_ppn_low_2[0])) begin cov_fail++; $display("[COV] L2TLBWrapper.io_tlb_0_resp_bits_s1_ppn_low_2[0] 未见过 0 和 1"); end
    if (!(w_s0_io_tlb_0_resp_bits_s1_ppn_low_2[1] && w_s1_io_tlb_0_resp_bits_s1_ppn_low_2[1])) begin cov_fail++; $display("[COV] L2TLBWrapper.io_tlb_0_resp_bits_s1_ppn_low_2[1] 未见过 0 和 1"); end
    if (!(w_s0_io_tlb_0_resp_bits_s1_ppn_low_2[2] && w_s1_io_tlb_0_resp_bits_s1_ppn_low_2[2])) begin cov_fail++; $display("[COV] L2TLBWrapper.io_tlb_0_resp_bits_s1_ppn_low_2[2] 未见过 0 和 1"); end
    if (!(w_s0_io_tlb_0_resp_bits_s1_ppn_low_3[0] && w_s1_io_tlb_0_resp_bits_s1_ppn_low_3[0])) begin cov_fail++; $display("[COV] L2TLBWrapper.io_tlb_0_resp_bits_s1_ppn_low_3[0] 未见过 0 和 1"); end
    if (!(w_s0_io_tlb_0_resp_bits_s1_ppn_low_3[1] && w_s1_io_tlb_0_resp_bits_s1_ppn_low_3[1])) begin cov_fail++; $display("[COV] L2TLBWrapper.io_tlb_0_resp_bits_s1_ppn_low_3[1] 未见过 0 和 1"); end
    if (!(w_s0_io_tlb_0_resp_bits_s1_ppn_low_3[2] && w_s1_io_tlb_0_resp_bits_s1_ppn_low_3[2])) begin cov_fail++; $display("[COV] L2TLBWrapper.io_tlb_0_resp_bits_s1_ppn_low_3[2] 未见过 0 和 1"); end
    if (!(w_s0_io_tlb_0_resp_bits_s1_ppn_low_4[0] && w_s1_io_tlb_0_resp_bits_s1_ppn_low_4[0])) begin cov_fail++; $display("[COV] L2TLBWrapper.io_tlb_0_resp_bits_s1_ppn_low_4[0] 未见过 0 和 1"); end
    if (!(w_s0_io_tlb_0_resp_bits_s1_ppn_low_4[1] && w_s1_io_tlb_0_resp_bits_s1_ppn_low_4[1])) begin cov_fail++; $display("[COV] L2TLBWrapper.io_tlb_0_resp_bits_s1_ppn_low_4[1] 未见过 0 和 1"); end
    if (!(w_s0_io_tlb_0_resp_bits_s1_ppn_low_4[2] && w_s1_io_tlb_0_resp_bits_s1_ppn_low_4[2])) begin cov_fail++; $display("[COV] L2TLBWrapper.io_tlb_0_resp_bits_s1_ppn_low_4[2] 未见过 0 和 1"); end
    if (!(w_s0_io_tlb_0_resp_bits_s1_ppn_low_5[0] && w_s1_io_tlb_0_resp_bits_s1_ppn_low_5[0])) begin cov_fail++; $display("[COV] L2TLBWrapper.io_tlb_0_resp_bits_s1_ppn_low_5[0] 未见过 0 和 1"); end
    if (!(w_s0_io_tlb_0_resp_bits_s1_ppn_low_5[1] && w_s1_io_tlb_0_resp_bits_s1_ppn_low_5[1])) begin cov_fail++; $display("[COV] L2TLBWrapper.io_tlb_0_resp_bits_s1_ppn_low_5[1] 未见过 0 和 1"); end
    if (!(w_s0_io_tlb_0_resp_bits_s1_ppn_low_5[2] && w_s1_io_tlb_0_resp_bits_s1_ppn_low_5[2])) begin cov_fail++; $display("[COV] L2TLBWrapper.io_tlb_0_resp_bits_s1_ppn_low_5[2] 未见过 0 和 1"); end
    if (!(w_s0_io_tlb_0_resp_bits_s1_ppn_low_6[0] && w_s1_io_tlb_0_resp_bits_s1_ppn_low_6[0])) begin cov_fail++; $display("[COV] L2TLBWrapper.io_tlb_0_resp_bits_s1_ppn_low_6[0] 未见过 0 和 1"); end
    if (!(w_s0_io_tlb_0_resp_bits_s1_ppn_low_6[1] && w_s1_io_tlb_0_resp_bits_s1_ppn_low_6[1])) begin cov_fail++; $display("[COV] L2TLBWrapper.io_tlb_0_resp_bits_s1_ppn_low_6[1] 未见过 0 和 1"); end
    if (!(w_s0_io_tlb_0_resp_bits_s1_ppn_low_6[2] && w_s1_io_tlb_0_resp_bits_s1_ppn_low_6[2])) begin cov_fail++; $display("[COV] L2TLBWrapper.io_tlb_0_resp_bits_s1_ppn_low_6[2] 未见过 0 和 1"); end
    if (!(w_s0_io_tlb_0_resp_bits_s1_ppn_low_7[0] && w_s1_io_tlb_0_resp_bits_s1_ppn_low_7[0])) begin cov_fail++; $display("[COV] L2TLBWrapper.io_tlb_0_resp_bits_s1_ppn_low_7[0] 未见过 0 和 1"); end
    if (!(w_s0_io_tlb_0_resp_bits_s1_ppn_low_7[1] && w_s1_io_tlb_0_resp_bits_s1_ppn_low_7[1])) begin cov_fail++; $display("[COV] L2TLBWrapper.io_tlb_0_resp_bits_s1_ppn_low_7[1] 未见过 0 和 1"); end
    if (!(w_s0_io_tlb_0_resp_bits_s1_ppn_low_7[2] && w_s1_io_tlb_0_resp_bits_s1_ppn_low_7[2])) begin cov_fail++; $display("[COV] L2TLBWrapper.io_tlb_0_resp_bits_s1_ppn_low_7[2] 未见过 0 和 1"); end
    if (!(w_s0_io_tlb_0_resp_bits_s1_valididx_0 && w_s1_io_tlb_0_resp_bits_s1_valididx_0)) begin cov_fail++; $display("[COV] L2TLBWrapper.io_tlb_0_resp_bits_s1_valididx_0 未见过 0 和 1"); end
    if (!(w_s0_io_tlb_0_resp_bits_s1_valididx_1 && w_s1_io_tlb_0_resp_bits_s1_valididx_1)) begin cov_fail++; $display("[COV] L2TLBWrapper.io_tlb_0_resp_bits_s1_valididx_1 未见过 0 和 1"); end
    if (!(w_s0_io_tlb_0_resp_bits_s1_valididx_2 && w_s1_io_tlb_0_resp_bits_s1_valididx_2)) begin cov_fail++; $display("[COV] L2TLBWrapper.io_tlb_0_resp_bits_s1_valididx_2 未见过 0 和 1"); end
    if (!(w_s0_io_tlb_0_resp_bits_s1_valididx_3 && w_s1_io_tlb_0_resp_bits_s1_valididx_3)) begin cov_fail++; $display("[COV] L2TLBWrapper.io_tlb_0_resp_bits_s1_valididx_3 未见过 0 和 1"); end
    if (!(w_s0_io_tlb_0_resp_bits_s1_valididx_4 && w_s1_io_tlb_0_resp_bits_s1_valididx_4)) begin cov_fail++; $display("[COV] L2TLBWrapper.io_tlb_0_resp_bits_s1_valididx_4 未见过 0 和 1"); end
    if (!(w_s0_io_tlb_0_resp_bits_s1_valididx_5 && w_s1_io_tlb_0_resp_bits_s1_valididx_5)) begin cov_fail++; $display("[COV] L2TLBWrapper.io_tlb_0_resp_bits_s1_valididx_5 未见过 0 和 1"); end
    if (!(w_s0_io_tlb_0_resp_bits_s1_valididx_6 && w_s1_io_tlb_0_resp_bits_s1_valididx_6)) begin cov_fail++; $display("[COV] L2TLBWrapper.io_tlb_0_resp_bits_s1_valididx_6 未见过 0 和 1"); end
    if (!(w_s0_io_tlb_0_resp_bits_s1_valididx_7 && w_s1_io_tlb_0_resp_bits_s1_valididx_7)) begin cov_fail++; $display("[COV] L2TLBWrapper.io_tlb_0_resp_bits_s1_valididx_7 未见过 0 和 1"); end
    if (!(w_s0_io_tlb_0_resp_bits_s1_pteidx_0 && w_s1_io_tlb_0_resp_bits_s1_pteidx_0)) begin cov_fail++; $display("[COV] L2TLBWrapper.io_tlb_0_resp_bits_s1_pteidx_0 未见过 0 和 1"); end
    if (!(w_s0_io_tlb_0_resp_bits_s1_pteidx_1 && w_s1_io_tlb_0_resp_bits_s1_pteidx_1)) begin cov_fail++; $display("[COV] L2TLBWrapper.io_tlb_0_resp_bits_s1_pteidx_1 未见过 0 和 1"); end
    if (!(w_s0_io_tlb_0_resp_bits_s1_pteidx_2 && w_s1_io_tlb_0_resp_bits_s1_pteidx_2)) begin cov_fail++; $display("[COV] L2TLBWrapper.io_tlb_0_resp_bits_s1_pteidx_2 未见过 0 和 1"); end
    if (!(w_s0_io_tlb_0_resp_bits_s1_pteidx_3 && w_s1_io_tlb_0_resp_bits_s1_pteidx_3)) begin cov_fail++; $display("[COV] L2TLBWrapper.io_tlb_0_resp_bits_s1_pteidx_3 未见过 0 和 1"); end
    if (!(w_s0_io_tlb_0_resp_bits_s1_pteidx_4 && w_s1_io_tlb_0_resp_bits_s1_pteidx_4)) begin cov_fail++; $display("[COV] L2TLBWrapper.io_tlb_0_resp_bits_s1_pteidx_4 未见过 0 和 1"); end
    if (!(w_s0_io_tlb_0_resp_bits_s1_pteidx_5 && w_s1_io_tlb_0_resp_bits_s1_pteidx_5)) begin cov_fail++; $display("[COV] L2TLBWrapper.io_tlb_0_resp_bits_s1_pteidx_5 未见过 0 和 1"); end
    if (!(w_s0_io_tlb_0_resp_bits_s1_pteidx_6 && w_s1_io_tlb_0_resp_bits_s1_pteidx_6)) begin cov_fail++; $display("[COV] L2TLBWrapper.io_tlb_0_resp_bits_s1_pteidx_6 未见过 0 和 1"); end
    if (!(w_s0_io_tlb_0_resp_bits_s1_pteidx_7 && w_s1_io_tlb_0_resp_bits_s1_pteidx_7)) begin cov_fail++; $display("[COV] L2TLBWrapper.io_tlb_0_resp_bits_s1_pteidx_7 未见过 0 和 1"); end
    if (!(w_s0_io_tlb_0_resp_bits_s1_pf && w_s1_io_tlb_0_resp_bits_s1_pf)) begin cov_fail++; $display("[COV] L2TLBWrapper.io_tlb_0_resp_bits_s1_pf 未见过 0 和 1"); end
    if (!(w_s0_io_tlb_0_resp_bits_s1_af && w_s1_io_tlb_0_resp_bits_s1_af)) begin cov_fail++; $display("[COV] L2TLBWrapper.io_tlb_0_resp_bits_s1_af 未见过 0 和 1"); end
    if (!(w_s0_io_tlb_0_resp_bits_s2_entry_tag[0] && w_s1_io_tlb_0_resp_bits_s2_entry_tag[0])) begin cov_fail++; $display("[COV] L2TLBWrapper.io_tlb_0_resp_bits_s2_entry_tag[0] 未见过 0 和 1"); end
    if (!(w_s0_io_tlb_0_resp_bits_s2_entry_tag[1] && w_s1_io_tlb_0_resp_bits_s2_entry_tag[1])) begin cov_fail++; $display("[COV] L2TLBWrapper.io_tlb_0_resp_bits_s2_entry_tag[1] 未见过 0 和 1"); end
    if (!(w_s0_io_tlb_0_resp_bits_s2_entry_tag[2] && w_s1_io_tlb_0_resp_bits_s2_entry_tag[2])) begin cov_fail++; $display("[COV] L2TLBWrapper.io_tlb_0_resp_bits_s2_entry_tag[2] 未见过 0 和 1"); end
    if (!(w_s0_io_tlb_0_resp_bits_s2_entry_tag[3] && w_s1_io_tlb_0_resp_bits_s2_entry_tag[3])) begin cov_fail++; $display("[COV] L2TLBWrapper.io_tlb_0_resp_bits_s2_entry_tag[3] 未见过 0 和 1"); end
    if (!(w_s0_io_tlb_0_resp_bits_s2_entry_tag[4] && w_s1_io_tlb_0_resp_bits_s2_entry_tag[4])) begin cov_fail++; $display("[COV] L2TLBWrapper.io_tlb_0_resp_bits_s2_entry_tag[4] 未见过 0 和 1"); end
    if (!(w_s0_io_tlb_0_resp_bits_s2_entry_tag[5] && w_s1_io_tlb_0_resp_bits_s2_entry_tag[5])) begin cov_fail++; $display("[COV] L2TLBWrapper.io_tlb_0_resp_bits_s2_entry_tag[5] 未见过 0 和 1"); end
    if (!(w_s0_io_tlb_0_resp_bits_s2_entry_tag[6] && w_s1_io_tlb_0_resp_bits_s2_entry_tag[6])) begin cov_fail++; $display("[COV] L2TLBWrapper.io_tlb_0_resp_bits_s2_entry_tag[6] 未见过 0 和 1"); end
    if (!(w_s0_io_tlb_0_resp_bits_s2_entry_tag[7] && w_s1_io_tlb_0_resp_bits_s2_entry_tag[7])) begin cov_fail++; $display("[COV] L2TLBWrapper.io_tlb_0_resp_bits_s2_entry_tag[7] 未见过 0 和 1"); end
    if (!(w_s0_io_tlb_0_resp_bits_s2_entry_tag[8] && w_s1_io_tlb_0_resp_bits_s2_entry_tag[8])) begin cov_fail++; $display("[COV] L2TLBWrapper.io_tlb_0_resp_bits_s2_entry_tag[8] 未见过 0 和 1"); end
    if (!(w_s0_io_tlb_0_resp_bits_s2_entry_tag[9] && w_s1_io_tlb_0_resp_bits_s2_entry_tag[9])) begin cov_fail++; $display("[COV] L2TLBWrapper.io_tlb_0_resp_bits_s2_entry_tag[9] 未见过 0 和 1"); end
    if (!(w_s0_io_tlb_0_resp_bits_s2_entry_tag[10] && w_s1_io_tlb_0_resp_bits_s2_entry_tag[10])) begin cov_fail++; $display("[COV] L2TLBWrapper.io_tlb_0_resp_bits_s2_entry_tag[10] 未见过 0 和 1"); end
    if (!(w_s0_io_tlb_0_resp_bits_s2_entry_tag[11] && w_s1_io_tlb_0_resp_bits_s2_entry_tag[11])) begin cov_fail++; $display("[COV] L2TLBWrapper.io_tlb_0_resp_bits_s2_entry_tag[11] 未见过 0 和 1"); end
    if (!(w_s0_io_tlb_0_resp_bits_s2_entry_tag[12] && w_s1_io_tlb_0_resp_bits_s2_entry_tag[12])) begin cov_fail++; $display("[COV] L2TLBWrapper.io_tlb_0_resp_bits_s2_entry_tag[12] 未见过 0 和 1"); end
    if (!(w_s0_io_tlb_0_resp_bits_s2_entry_tag[13] && w_s1_io_tlb_0_resp_bits_s2_entry_tag[13])) begin cov_fail++; $display("[COV] L2TLBWrapper.io_tlb_0_resp_bits_s2_entry_tag[13] 未见过 0 和 1"); end
    if (!(w_s0_io_tlb_0_resp_bits_s2_entry_tag[14] && w_s1_io_tlb_0_resp_bits_s2_entry_tag[14])) begin cov_fail++; $display("[COV] L2TLBWrapper.io_tlb_0_resp_bits_s2_entry_tag[14] 未见过 0 和 1"); end
    if (!(w_s0_io_tlb_0_resp_bits_s2_entry_tag[15] && w_s1_io_tlb_0_resp_bits_s2_entry_tag[15])) begin cov_fail++; $display("[COV] L2TLBWrapper.io_tlb_0_resp_bits_s2_entry_tag[15] 未见过 0 和 1"); end
    if (!(w_s0_io_tlb_0_resp_bits_s2_entry_tag[16] && w_s1_io_tlb_0_resp_bits_s2_entry_tag[16])) begin cov_fail++; $display("[COV] L2TLBWrapper.io_tlb_0_resp_bits_s2_entry_tag[16] 未见过 0 和 1"); end
    if (!(w_s0_io_tlb_0_resp_bits_s2_entry_tag[17] && w_s1_io_tlb_0_resp_bits_s2_entry_tag[17])) begin cov_fail++; $display("[COV] L2TLBWrapper.io_tlb_0_resp_bits_s2_entry_tag[17] 未见过 0 和 1"); end
    if (!(w_s0_io_tlb_0_resp_bits_s2_entry_tag[18] && w_s1_io_tlb_0_resp_bits_s2_entry_tag[18])) begin cov_fail++; $display("[COV] L2TLBWrapper.io_tlb_0_resp_bits_s2_entry_tag[18] 未见过 0 和 1"); end
    if (!(w_s0_io_tlb_0_resp_bits_s2_entry_tag[19] && w_s1_io_tlb_0_resp_bits_s2_entry_tag[19])) begin cov_fail++; $display("[COV] L2TLBWrapper.io_tlb_0_resp_bits_s2_entry_tag[19] 未见过 0 和 1"); end
    if (!(w_s0_io_tlb_0_resp_bits_s2_entry_tag[20] && w_s1_io_tlb_0_resp_bits_s2_entry_tag[20])) begin cov_fail++; $display("[COV] L2TLBWrapper.io_tlb_0_resp_bits_s2_entry_tag[20] 未见过 0 和 1"); end
    if (!(w_s0_io_tlb_0_resp_bits_s2_entry_tag[21] && w_s1_io_tlb_0_resp_bits_s2_entry_tag[21])) begin cov_fail++; $display("[COV] L2TLBWrapper.io_tlb_0_resp_bits_s2_entry_tag[21] 未见过 0 和 1"); end
    if (!(w_s0_io_tlb_0_resp_bits_s2_entry_tag[22] && w_s1_io_tlb_0_resp_bits_s2_entry_tag[22])) begin cov_fail++; $display("[COV] L2TLBWrapper.io_tlb_0_resp_bits_s2_entry_tag[22] 未见过 0 和 1"); end
    if (!(w_s0_io_tlb_0_resp_bits_s2_entry_tag[23] && w_s1_io_tlb_0_resp_bits_s2_entry_tag[23])) begin cov_fail++; $display("[COV] L2TLBWrapper.io_tlb_0_resp_bits_s2_entry_tag[23] 未见过 0 和 1"); end
    if (!(w_s0_io_tlb_0_resp_bits_s2_entry_tag[24] && w_s1_io_tlb_0_resp_bits_s2_entry_tag[24])) begin cov_fail++; $display("[COV] L2TLBWrapper.io_tlb_0_resp_bits_s2_entry_tag[24] 未见过 0 和 1"); end
    if (!(w_s0_io_tlb_0_resp_bits_s2_entry_tag[25] && w_s1_io_tlb_0_resp_bits_s2_entry_tag[25])) begin cov_fail++; $display("[COV] L2TLBWrapper.io_tlb_0_resp_bits_s2_entry_tag[25] 未见过 0 和 1"); end
    if (!(w_s0_io_tlb_0_resp_bits_s2_entry_tag[26] && w_s1_io_tlb_0_resp_bits_s2_entry_tag[26])) begin cov_fail++; $display("[COV] L2TLBWrapper.io_tlb_0_resp_bits_s2_entry_tag[26] 未见过 0 和 1"); end
    if (!(w_s0_io_tlb_0_resp_bits_s2_entry_tag[27] && w_s1_io_tlb_0_resp_bits_s2_entry_tag[27])) begin cov_fail++; $display("[COV] L2TLBWrapper.io_tlb_0_resp_bits_s2_entry_tag[27] 未见过 0 和 1"); end
    if (!(w_s0_io_tlb_0_resp_bits_s2_entry_tag[28] && w_s1_io_tlb_0_resp_bits_s2_entry_tag[28])) begin cov_fail++; $display("[COV] L2TLBWrapper.io_tlb_0_resp_bits_s2_entry_tag[28] 未见过 0 和 1"); end
    if (!(w_s0_io_tlb_0_resp_bits_s2_entry_tag[29] && w_s1_io_tlb_0_resp_bits_s2_entry_tag[29])) begin cov_fail++; $display("[COV] L2TLBWrapper.io_tlb_0_resp_bits_s2_entry_tag[29] 未见过 0 和 1"); end
    if (!(w_s0_io_tlb_0_resp_bits_s2_entry_tag[30] && w_s1_io_tlb_0_resp_bits_s2_entry_tag[30])) begin cov_fail++; $display("[COV] L2TLBWrapper.io_tlb_0_resp_bits_s2_entry_tag[30] 未见过 0 和 1"); end
    if (!(w_s0_io_tlb_0_resp_bits_s2_entry_tag[31] && w_s1_io_tlb_0_resp_bits_s2_entry_tag[31])) begin cov_fail++; $display("[COV] L2TLBWrapper.io_tlb_0_resp_bits_s2_entry_tag[31] 未见过 0 和 1"); end
    if (!(w_s0_io_tlb_0_resp_bits_s2_entry_tag[32] && w_s1_io_tlb_0_resp_bits_s2_entry_tag[32])) begin cov_fail++; $display("[COV] L2TLBWrapper.io_tlb_0_resp_bits_s2_entry_tag[32] 未见过 0 和 1"); end
    if (!(w_s0_io_tlb_0_resp_bits_s2_entry_tag[33] && w_s1_io_tlb_0_resp_bits_s2_entry_tag[33])) begin cov_fail++; $display("[COV] L2TLBWrapper.io_tlb_0_resp_bits_s2_entry_tag[33] 未见过 0 和 1"); end
    if (!(w_s0_io_tlb_0_resp_bits_s2_entry_tag[34] && w_s1_io_tlb_0_resp_bits_s2_entry_tag[34])) begin cov_fail++; $display("[COV] L2TLBWrapper.io_tlb_0_resp_bits_s2_entry_tag[34] 未见过 0 和 1"); end
    if (!(w_s0_io_tlb_0_resp_bits_s2_entry_tag[35] && w_s1_io_tlb_0_resp_bits_s2_entry_tag[35])) begin cov_fail++; $display("[COV] L2TLBWrapper.io_tlb_0_resp_bits_s2_entry_tag[35] 未见过 0 和 1"); end
    if (!(w_s0_io_tlb_0_resp_bits_s2_entry_tag[36] && w_s1_io_tlb_0_resp_bits_s2_entry_tag[36])) begin cov_fail++; $display("[COV] L2TLBWrapper.io_tlb_0_resp_bits_s2_entry_tag[36] 未见过 0 和 1"); end
    if (!(w_s0_io_tlb_0_resp_bits_s2_entry_tag[37] && w_s1_io_tlb_0_resp_bits_s2_entry_tag[37])) begin cov_fail++; $display("[COV] L2TLBWrapper.io_tlb_0_resp_bits_s2_entry_tag[37] 未见过 0 和 1"); end
    if (!(w_s0_io_tlb_0_resp_bits_s2_entry_vmid[0] && w_s1_io_tlb_0_resp_bits_s2_entry_vmid[0])) begin cov_fail++; $display("[COV] L2TLBWrapper.io_tlb_0_resp_bits_s2_entry_vmid[0] 未见过 0 和 1"); end
    if (!(w_s0_io_tlb_0_resp_bits_s2_entry_vmid[1] && w_s1_io_tlb_0_resp_bits_s2_entry_vmid[1])) begin cov_fail++; $display("[COV] L2TLBWrapper.io_tlb_0_resp_bits_s2_entry_vmid[1] 未见过 0 和 1"); end
    if (!(w_s0_io_tlb_0_resp_bits_s2_entry_vmid[2] && w_s1_io_tlb_0_resp_bits_s2_entry_vmid[2])) begin cov_fail++; $display("[COV] L2TLBWrapper.io_tlb_0_resp_bits_s2_entry_vmid[2] 未见过 0 和 1"); end
    if (!(w_s0_io_tlb_0_resp_bits_s2_entry_vmid[3] && w_s1_io_tlb_0_resp_bits_s2_entry_vmid[3])) begin cov_fail++; $display("[COV] L2TLBWrapper.io_tlb_0_resp_bits_s2_entry_vmid[3] 未见过 0 和 1"); end
    if (!(w_s0_io_tlb_0_resp_bits_s2_entry_vmid[4] && w_s1_io_tlb_0_resp_bits_s2_entry_vmid[4])) begin cov_fail++; $display("[COV] L2TLBWrapper.io_tlb_0_resp_bits_s2_entry_vmid[4] 未见过 0 和 1"); end
    if (!(w_s0_io_tlb_0_resp_bits_s2_entry_vmid[5] && w_s1_io_tlb_0_resp_bits_s2_entry_vmid[5])) begin cov_fail++; $display("[COV] L2TLBWrapper.io_tlb_0_resp_bits_s2_entry_vmid[5] 未见过 0 和 1"); end
    if (!(w_s0_io_tlb_0_resp_bits_s2_entry_vmid[6] && w_s1_io_tlb_0_resp_bits_s2_entry_vmid[6])) begin cov_fail++; $display("[COV] L2TLBWrapper.io_tlb_0_resp_bits_s2_entry_vmid[6] 未见过 0 和 1"); end
    if (!(w_s0_io_tlb_0_resp_bits_s2_entry_vmid[7] && w_s1_io_tlb_0_resp_bits_s2_entry_vmid[7])) begin cov_fail++; $display("[COV] L2TLBWrapper.io_tlb_0_resp_bits_s2_entry_vmid[7] 未见过 0 和 1"); end
    if (!(w_s0_io_tlb_0_resp_bits_s2_entry_vmid[8] && w_s1_io_tlb_0_resp_bits_s2_entry_vmid[8])) begin cov_fail++; $display("[COV] L2TLBWrapper.io_tlb_0_resp_bits_s2_entry_vmid[8] 未见过 0 和 1"); end
    if (!(w_s0_io_tlb_0_resp_bits_s2_entry_vmid[9] && w_s1_io_tlb_0_resp_bits_s2_entry_vmid[9])) begin cov_fail++; $display("[COV] L2TLBWrapper.io_tlb_0_resp_bits_s2_entry_vmid[9] 未见过 0 和 1"); end
    if (!(w_s0_io_tlb_0_resp_bits_s2_entry_vmid[10] && w_s1_io_tlb_0_resp_bits_s2_entry_vmid[10])) begin cov_fail++; $display("[COV] L2TLBWrapper.io_tlb_0_resp_bits_s2_entry_vmid[10] 未见过 0 和 1"); end
    if (!(w_s0_io_tlb_0_resp_bits_s2_entry_vmid[11] && w_s1_io_tlb_0_resp_bits_s2_entry_vmid[11])) begin cov_fail++; $display("[COV] L2TLBWrapper.io_tlb_0_resp_bits_s2_entry_vmid[11] 未见过 0 和 1"); end
    if (!(w_s0_io_tlb_0_resp_bits_s2_entry_vmid[12] && w_s1_io_tlb_0_resp_bits_s2_entry_vmid[12])) begin cov_fail++; $display("[COV] L2TLBWrapper.io_tlb_0_resp_bits_s2_entry_vmid[12] 未见过 0 和 1"); end
    if (!(w_s0_io_tlb_0_resp_bits_s2_entry_vmid[13] && w_s1_io_tlb_0_resp_bits_s2_entry_vmid[13])) begin cov_fail++; $display("[COV] L2TLBWrapper.io_tlb_0_resp_bits_s2_entry_vmid[13] 未见过 0 和 1"); end
    if (!(w_s0_io_tlb_0_resp_bits_s2_entry_n && w_s1_io_tlb_0_resp_bits_s2_entry_n)) begin cov_fail++; $display("[COV] L2TLBWrapper.io_tlb_0_resp_bits_s2_entry_n 未见过 0 和 1"); end
    if (!(w_s0_io_tlb_0_resp_bits_s2_entry_pbmt[0] && w_s1_io_tlb_0_resp_bits_s2_entry_pbmt[0])) begin cov_fail++; $display("[COV] L2TLBWrapper.io_tlb_0_resp_bits_s2_entry_pbmt[0] 未见过 0 和 1"); end
    if (!(w_s0_io_tlb_0_resp_bits_s2_entry_pbmt[1] && w_s1_io_tlb_0_resp_bits_s2_entry_pbmt[1])) begin cov_fail++; $display("[COV] L2TLBWrapper.io_tlb_0_resp_bits_s2_entry_pbmt[1] 未见过 0 和 1"); end
    if (!(w_s0_io_tlb_0_resp_bits_s2_entry_ppn[0] && w_s1_io_tlb_0_resp_bits_s2_entry_ppn[0])) begin cov_fail++; $display("[COV] L2TLBWrapper.io_tlb_0_resp_bits_s2_entry_ppn[0] 未见过 0 和 1"); end
    if (!(w_s0_io_tlb_0_resp_bits_s2_entry_ppn[1] && w_s1_io_tlb_0_resp_bits_s2_entry_ppn[1])) begin cov_fail++; $display("[COV] L2TLBWrapper.io_tlb_0_resp_bits_s2_entry_ppn[1] 未见过 0 和 1"); end
    if (!(w_s0_io_tlb_0_resp_bits_s2_entry_ppn[2] && w_s1_io_tlb_0_resp_bits_s2_entry_ppn[2])) begin cov_fail++; $display("[COV] L2TLBWrapper.io_tlb_0_resp_bits_s2_entry_ppn[2] 未见过 0 和 1"); end
    if (!(w_s0_io_tlb_0_resp_bits_s2_entry_ppn[3] && w_s1_io_tlb_0_resp_bits_s2_entry_ppn[3])) begin cov_fail++; $display("[COV] L2TLBWrapper.io_tlb_0_resp_bits_s2_entry_ppn[3] 未见过 0 和 1"); end
    if (!(w_s0_io_tlb_0_resp_bits_s2_entry_ppn[4] && w_s1_io_tlb_0_resp_bits_s2_entry_ppn[4])) begin cov_fail++; $display("[COV] L2TLBWrapper.io_tlb_0_resp_bits_s2_entry_ppn[4] 未见过 0 和 1"); end
    if (!(w_s0_io_tlb_0_resp_bits_s2_entry_ppn[5] && w_s1_io_tlb_0_resp_bits_s2_entry_ppn[5])) begin cov_fail++; $display("[COV] L2TLBWrapper.io_tlb_0_resp_bits_s2_entry_ppn[5] 未见过 0 和 1"); end
    if (!(w_s0_io_tlb_0_resp_bits_s2_entry_ppn[6] && w_s1_io_tlb_0_resp_bits_s2_entry_ppn[6])) begin cov_fail++; $display("[COV] L2TLBWrapper.io_tlb_0_resp_bits_s2_entry_ppn[6] 未见过 0 和 1"); end
    if (!(w_s0_io_tlb_0_resp_bits_s2_entry_ppn[7] && w_s1_io_tlb_0_resp_bits_s2_entry_ppn[7])) begin cov_fail++; $display("[COV] L2TLBWrapper.io_tlb_0_resp_bits_s2_entry_ppn[7] 未见过 0 和 1"); end
    if (!(w_s0_io_tlb_0_resp_bits_s2_entry_ppn[8] && w_s1_io_tlb_0_resp_bits_s2_entry_ppn[8])) begin cov_fail++; $display("[COV] L2TLBWrapper.io_tlb_0_resp_bits_s2_entry_ppn[8] 未见过 0 和 1"); end
    if (!(w_s0_io_tlb_0_resp_bits_s2_entry_ppn[9] && w_s1_io_tlb_0_resp_bits_s2_entry_ppn[9])) begin cov_fail++; $display("[COV] L2TLBWrapper.io_tlb_0_resp_bits_s2_entry_ppn[9] 未见过 0 和 1"); end
    if (!(w_s0_io_tlb_0_resp_bits_s2_entry_ppn[10] && w_s1_io_tlb_0_resp_bits_s2_entry_ppn[10])) begin cov_fail++; $display("[COV] L2TLBWrapper.io_tlb_0_resp_bits_s2_entry_ppn[10] 未见过 0 和 1"); end
    if (!(w_s0_io_tlb_0_resp_bits_s2_entry_ppn[11] && w_s1_io_tlb_0_resp_bits_s2_entry_ppn[11])) begin cov_fail++; $display("[COV] L2TLBWrapper.io_tlb_0_resp_bits_s2_entry_ppn[11] 未见过 0 和 1"); end
    if (!(w_s0_io_tlb_0_resp_bits_s2_entry_ppn[12] && w_s1_io_tlb_0_resp_bits_s2_entry_ppn[12])) begin cov_fail++; $display("[COV] L2TLBWrapper.io_tlb_0_resp_bits_s2_entry_ppn[12] 未见过 0 和 1"); end
    if (!(w_s0_io_tlb_0_resp_bits_s2_entry_ppn[13] && w_s1_io_tlb_0_resp_bits_s2_entry_ppn[13])) begin cov_fail++; $display("[COV] L2TLBWrapper.io_tlb_0_resp_bits_s2_entry_ppn[13] 未见过 0 和 1"); end
    if (!(w_s0_io_tlb_0_resp_bits_s2_entry_ppn[14] && w_s1_io_tlb_0_resp_bits_s2_entry_ppn[14])) begin cov_fail++; $display("[COV] L2TLBWrapper.io_tlb_0_resp_bits_s2_entry_ppn[14] 未见过 0 和 1"); end
    if (!(w_s0_io_tlb_0_resp_bits_s2_entry_ppn[15] && w_s1_io_tlb_0_resp_bits_s2_entry_ppn[15])) begin cov_fail++; $display("[COV] L2TLBWrapper.io_tlb_0_resp_bits_s2_entry_ppn[15] 未见过 0 和 1"); end
    if (!(w_s0_io_tlb_0_resp_bits_s2_entry_ppn[16] && w_s1_io_tlb_0_resp_bits_s2_entry_ppn[16])) begin cov_fail++; $display("[COV] L2TLBWrapper.io_tlb_0_resp_bits_s2_entry_ppn[16] 未见过 0 和 1"); end
    if (!(w_s0_io_tlb_0_resp_bits_s2_entry_ppn[17] && w_s1_io_tlb_0_resp_bits_s2_entry_ppn[17])) begin cov_fail++; $display("[COV] L2TLBWrapper.io_tlb_0_resp_bits_s2_entry_ppn[17] 未见过 0 和 1"); end
    if (!(w_s0_io_tlb_0_resp_bits_s2_entry_ppn[18] && w_s1_io_tlb_0_resp_bits_s2_entry_ppn[18])) begin cov_fail++; $display("[COV] L2TLBWrapper.io_tlb_0_resp_bits_s2_entry_ppn[18] 未见过 0 和 1"); end
    if (!(w_s0_io_tlb_0_resp_bits_s2_entry_ppn[19] && w_s1_io_tlb_0_resp_bits_s2_entry_ppn[19])) begin cov_fail++; $display("[COV] L2TLBWrapper.io_tlb_0_resp_bits_s2_entry_ppn[19] 未见过 0 和 1"); end
    if (!(w_s0_io_tlb_0_resp_bits_s2_entry_ppn[20] && w_s1_io_tlb_0_resp_bits_s2_entry_ppn[20])) begin cov_fail++; $display("[COV] L2TLBWrapper.io_tlb_0_resp_bits_s2_entry_ppn[20] 未见过 0 和 1"); end
    if (!(w_s0_io_tlb_0_resp_bits_s2_entry_ppn[21] && w_s1_io_tlb_0_resp_bits_s2_entry_ppn[21])) begin cov_fail++; $display("[COV] L2TLBWrapper.io_tlb_0_resp_bits_s2_entry_ppn[21] 未见过 0 和 1"); end
    if (!(w_s0_io_tlb_0_resp_bits_s2_entry_ppn[22] && w_s1_io_tlb_0_resp_bits_s2_entry_ppn[22])) begin cov_fail++; $display("[COV] L2TLBWrapper.io_tlb_0_resp_bits_s2_entry_ppn[22] 未见过 0 和 1"); end
    if (!(w_s0_io_tlb_0_resp_bits_s2_entry_ppn[23] && w_s1_io_tlb_0_resp_bits_s2_entry_ppn[23])) begin cov_fail++; $display("[COV] L2TLBWrapper.io_tlb_0_resp_bits_s2_entry_ppn[23] 未见过 0 和 1"); end
    if (!(w_s0_io_tlb_0_resp_bits_s2_entry_ppn[24] && w_s1_io_tlb_0_resp_bits_s2_entry_ppn[24])) begin cov_fail++; $display("[COV] L2TLBWrapper.io_tlb_0_resp_bits_s2_entry_ppn[24] 未见过 0 和 1"); end
    if (!(w_s0_io_tlb_0_resp_bits_s2_entry_ppn[25] && w_s1_io_tlb_0_resp_bits_s2_entry_ppn[25])) begin cov_fail++; $display("[COV] L2TLBWrapper.io_tlb_0_resp_bits_s2_entry_ppn[25] 未见过 0 和 1"); end
    if (!(w_s0_io_tlb_0_resp_bits_s2_entry_ppn[26] && w_s1_io_tlb_0_resp_bits_s2_entry_ppn[26])) begin cov_fail++; $display("[COV] L2TLBWrapper.io_tlb_0_resp_bits_s2_entry_ppn[26] 未见过 0 和 1"); end
    if (!(w_s0_io_tlb_0_resp_bits_s2_entry_ppn[27] && w_s1_io_tlb_0_resp_bits_s2_entry_ppn[27])) begin cov_fail++; $display("[COV] L2TLBWrapper.io_tlb_0_resp_bits_s2_entry_ppn[27] 未见过 0 和 1"); end
    if (!(w_s0_io_tlb_0_resp_bits_s2_entry_ppn[28] && w_s1_io_tlb_0_resp_bits_s2_entry_ppn[28])) begin cov_fail++; $display("[COV] L2TLBWrapper.io_tlb_0_resp_bits_s2_entry_ppn[28] 未见过 0 和 1"); end
    if (!(w_s0_io_tlb_0_resp_bits_s2_entry_ppn[29] && w_s1_io_tlb_0_resp_bits_s2_entry_ppn[29])) begin cov_fail++; $display("[COV] L2TLBWrapper.io_tlb_0_resp_bits_s2_entry_ppn[29] 未见过 0 和 1"); end
    if (!(w_s0_io_tlb_0_resp_bits_s2_entry_ppn[30] && w_s1_io_tlb_0_resp_bits_s2_entry_ppn[30])) begin cov_fail++; $display("[COV] L2TLBWrapper.io_tlb_0_resp_bits_s2_entry_ppn[30] 未见过 0 和 1"); end
    if (!(w_s0_io_tlb_0_resp_bits_s2_entry_ppn[31] && w_s1_io_tlb_0_resp_bits_s2_entry_ppn[31])) begin cov_fail++; $display("[COV] L2TLBWrapper.io_tlb_0_resp_bits_s2_entry_ppn[31] 未见过 0 和 1"); end
    if (!(w_s0_io_tlb_0_resp_bits_s2_entry_ppn[32] && w_s1_io_tlb_0_resp_bits_s2_entry_ppn[32])) begin cov_fail++; $display("[COV] L2TLBWrapper.io_tlb_0_resp_bits_s2_entry_ppn[32] 未见过 0 和 1"); end
    if (!(w_s0_io_tlb_0_resp_bits_s2_entry_ppn[33] && w_s1_io_tlb_0_resp_bits_s2_entry_ppn[33])) begin cov_fail++; $display("[COV] L2TLBWrapper.io_tlb_0_resp_bits_s2_entry_ppn[33] 未见过 0 和 1"); end
    if (!(w_s0_io_tlb_0_resp_bits_s2_entry_ppn[34] && w_s1_io_tlb_0_resp_bits_s2_entry_ppn[34])) begin cov_fail++; $display("[COV] L2TLBWrapper.io_tlb_0_resp_bits_s2_entry_ppn[34] 未见过 0 和 1"); end
    if (!(w_s0_io_tlb_0_resp_bits_s2_entry_ppn[35] && w_s1_io_tlb_0_resp_bits_s2_entry_ppn[35])) begin cov_fail++; $display("[COV] L2TLBWrapper.io_tlb_0_resp_bits_s2_entry_ppn[35] 未见过 0 和 1"); end
    if (!(w_s0_io_tlb_0_resp_bits_s2_entry_ppn[36] && w_s1_io_tlb_0_resp_bits_s2_entry_ppn[36])) begin cov_fail++; $display("[COV] L2TLBWrapper.io_tlb_0_resp_bits_s2_entry_ppn[36] 未见过 0 和 1"); end
    if (!(w_s0_io_tlb_0_resp_bits_s2_entry_ppn[37] && w_s1_io_tlb_0_resp_bits_s2_entry_ppn[37])) begin cov_fail++; $display("[COV] L2TLBWrapper.io_tlb_0_resp_bits_s2_entry_ppn[37] 未见过 0 和 1"); end
    if (!(w_s0_io_tlb_0_resp_bits_s2_entry_perm_d && w_s1_io_tlb_0_resp_bits_s2_entry_perm_d)) begin cov_fail++; $display("[COV] L2TLBWrapper.io_tlb_0_resp_bits_s2_entry_perm_d 未见过 0 和 1"); end
    if (!(w_s0_io_tlb_0_resp_bits_s2_entry_perm_a && w_s1_io_tlb_0_resp_bits_s2_entry_perm_a)) begin cov_fail++; $display("[COV] L2TLBWrapper.io_tlb_0_resp_bits_s2_entry_perm_a 未见过 0 和 1"); end
    if (!(w_s0_io_tlb_0_resp_bits_s2_entry_perm_g && w_s1_io_tlb_0_resp_bits_s2_entry_perm_g)) begin cov_fail++; $display("[COV] L2TLBWrapper.io_tlb_0_resp_bits_s2_entry_perm_g 未见过 0 和 1"); end
    if (!(w_s0_io_tlb_0_resp_bits_s2_entry_perm_u && w_s1_io_tlb_0_resp_bits_s2_entry_perm_u)) begin cov_fail++; $display("[COV] L2TLBWrapper.io_tlb_0_resp_bits_s2_entry_perm_u 未见过 0 和 1"); end
    if (!(w_s0_io_tlb_0_resp_bits_s2_entry_perm_x && w_s1_io_tlb_0_resp_bits_s2_entry_perm_x)) begin cov_fail++; $display("[COV] L2TLBWrapper.io_tlb_0_resp_bits_s2_entry_perm_x 未见过 0 和 1"); end
    if (!(w_s0_io_tlb_0_resp_bits_s2_entry_perm_w && w_s1_io_tlb_0_resp_bits_s2_entry_perm_w)) begin cov_fail++; $display("[COV] L2TLBWrapper.io_tlb_0_resp_bits_s2_entry_perm_w 未见过 0 和 1"); end
    if (!(w_s0_io_tlb_0_resp_bits_s2_entry_perm_r && w_s1_io_tlb_0_resp_bits_s2_entry_perm_r)) begin cov_fail++; $display("[COV] L2TLBWrapper.io_tlb_0_resp_bits_s2_entry_perm_r 未见过 0 和 1"); end
    if (!(w_s0_io_tlb_0_resp_bits_s2_entry_level[0] && w_s1_io_tlb_0_resp_bits_s2_entry_level[0])) begin cov_fail++; $display("[COV] L2TLBWrapper.io_tlb_0_resp_bits_s2_entry_level[0] 未见过 0 和 1"); end
    if (!(w_s0_io_tlb_0_resp_bits_s2_entry_level[1] && w_s1_io_tlb_0_resp_bits_s2_entry_level[1])) begin cov_fail++; $display("[COV] L2TLBWrapper.io_tlb_0_resp_bits_s2_entry_level[1] 未见过 0 和 1"); end
    if (!(w_s0_io_tlb_0_resp_bits_s2_gpf && w_s1_io_tlb_0_resp_bits_s2_gpf)) begin cov_fail++; $display("[COV] L2TLBWrapper.io_tlb_0_resp_bits_s2_gpf 未见过 0 和 1"); end
    if (!(w_s0_io_tlb_0_resp_bits_s2_gaf && w_s1_io_tlb_0_resp_bits_s2_gaf)) begin cov_fail++; $display("[COV] L2TLBWrapper.io_tlb_0_resp_bits_s2_gaf 未见过 0 和 1"); end
    if (!(w_s0_io_tlb_1_req_0_ready && w_s1_io_tlb_1_req_0_ready)) begin cov_fail++; $display("[COV] L2TLBWrapper.io_tlb_1_req_0_ready 未见过 0 和 1"); end
    if (!(w_s0_io_tlb_1_resp_valid && w_s1_io_tlb_1_resp_valid)) begin cov_fail++; $display("[COV] L2TLBWrapper.io_tlb_1_resp_valid 未见过 0 和 1"); end
    if (!(w_s0_io_tlb_1_resp_bits_s2xlate[0] && w_s1_io_tlb_1_resp_bits_s2xlate[0])) begin cov_fail++; $display("[COV] L2TLBWrapper.io_tlb_1_resp_bits_s2xlate[0] 未见过 0 和 1"); end
    if (!(w_s0_io_tlb_1_resp_bits_s2xlate[1] && w_s1_io_tlb_1_resp_bits_s2xlate[1])) begin cov_fail++; $display("[COV] L2TLBWrapper.io_tlb_1_resp_bits_s2xlate[1] 未见过 0 和 1"); end
    if (!(w_s0_io_tlb_1_resp_bits_s1_entry_tag[0] && w_s1_io_tlb_1_resp_bits_s1_entry_tag[0])) begin cov_fail++; $display("[COV] L2TLBWrapper.io_tlb_1_resp_bits_s1_entry_tag[0] 未见过 0 和 1"); end
    if (!(w_s0_io_tlb_1_resp_bits_s1_entry_tag[1] && w_s1_io_tlb_1_resp_bits_s1_entry_tag[1])) begin cov_fail++; $display("[COV] L2TLBWrapper.io_tlb_1_resp_bits_s1_entry_tag[1] 未见过 0 和 1"); end
    if (!(w_s0_io_tlb_1_resp_bits_s1_entry_tag[2] && w_s1_io_tlb_1_resp_bits_s1_entry_tag[2])) begin cov_fail++; $display("[COV] L2TLBWrapper.io_tlb_1_resp_bits_s1_entry_tag[2] 未见过 0 和 1"); end
    if (!(w_s0_io_tlb_1_resp_bits_s1_entry_tag[3] && w_s1_io_tlb_1_resp_bits_s1_entry_tag[3])) begin cov_fail++; $display("[COV] L2TLBWrapper.io_tlb_1_resp_bits_s1_entry_tag[3] 未见过 0 和 1"); end
    if (!(w_s0_io_tlb_1_resp_bits_s1_entry_tag[4] && w_s1_io_tlb_1_resp_bits_s1_entry_tag[4])) begin cov_fail++; $display("[COV] L2TLBWrapper.io_tlb_1_resp_bits_s1_entry_tag[4] 未见过 0 和 1"); end
    if (!(w_s0_io_tlb_1_resp_bits_s1_entry_tag[5] && w_s1_io_tlb_1_resp_bits_s1_entry_tag[5])) begin cov_fail++; $display("[COV] L2TLBWrapper.io_tlb_1_resp_bits_s1_entry_tag[5] 未见过 0 和 1"); end
    if (!(w_s0_io_tlb_1_resp_bits_s1_entry_tag[6] && w_s1_io_tlb_1_resp_bits_s1_entry_tag[6])) begin cov_fail++; $display("[COV] L2TLBWrapper.io_tlb_1_resp_bits_s1_entry_tag[6] 未见过 0 和 1"); end
    if (!(w_s0_io_tlb_1_resp_bits_s1_entry_tag[7] && w_s1_io_tlb_1_resp_bits_s1_entry_tag[7])) begin cov_fail++; $display("[COV] L2TLBWrapper.io_tlb_1_resp_bits_s1_entry_tag[7] 未见过 0 和 1"); end
    if (!(w_s0_io_tlb_1_resp_bits_s1_entry_tag[8] && w_s1_io_tlb_1_resp_bits_s1_entry_tag[8])) begin cov_fail++; $display("[COV] L2TLBWrapper.io_tlb_1_resp_bits_s1_entry_tag[8] 未见过 0 和 1"); end
    if (!(w_s0_io_tlb_1_resp_bits_s1_entry_tag[9] && w_s1_io_tlb_1_resp_bits_s1_entry_tag[9])) begin cov_fail++; $display("[COV] L2TLBWrapper.io_tlb_1_resp_bits_s1_entry_tag[9] 未见过 0 和 1"); end
    if (!(w_s0_io_tlb_1_resp_bits_s1_entry_tag[10] && w_s1_io_tlb_1_resp_bits_s1_entry_tag[10])) begin cov_fail++; $display("[COV] L2TLBWrapper.io_tlb_1_resp_bits_s1_entry_tag[10] 未见过 0 和 1"); end
    if (!(w_s0_io_tlb_1_resp_bits_s1_entry_tag[11] && w_s1_io_tlb_1_resp_bits_s1_entry_tag[11])) begin cov_fail++; $display("[COV] L2TLBWrapper.io_tlb_1_resp_bits_s1_entry_tag[11] 未见过 0 和 1"); end
    if (!(w_s0_io_tlb_1_resp_bits_s1_entry_tag[12] && w_s1_io_tlb_1_resp_bits_s1_entry_tag[12])) begin cov_fail++; $display("[COV] L2TLBWrapper.io_tlb_1_resp_bits_s1_entry_tag[12] 未见过 0 和 1"); end
    if (!(w_s0_io_tlb_1_resp_bits_s1_entry_tag[13] && w_s1_io_tlb_1_resp_bits_s1_entry_tag[13])) begin cov_fail++; $display("[COV] L2TLBWrapper.io_tlb_1_resp_bits_s1_entry_tag[13] 未见过 0 和 1"); end
    if (!(w_s0_io_tlb_1_resp_bits_s1_entry_tag[14] && w_s1_io_tlb_1_resp_bits_s1_entry_tag[14])) begin cov_fail++; $display("[COV] L2TLBWrapper.io_tlb_1_resp_bits_s1_entry_tag[14] 未见过 0 和 1"); end
    if (!(w_s0_io_tlb_1_resp_bits_s1_entry_tag[15] && w_s1_io_tlb_1_resp_bits_s1_entry_tag[15])) begin cov_fail++; $display("[COV] L2TLBWrapper.io_tlb_1_resp_bits_s1_entry_tag[15] 未见过 0 和 1"); end
    if (!(w_s0_io_tlb_1_resp_bits_s1_entry_tag[16] && w_s1_io_tlb_1_resp_bits_s1_entry_tag[16])) begin cov_fail++; $display("[COV] L2TLBWrapper.io_tlb_1_resp_bits_s1_entry_tag[16] 未见过 0 和 1"); end
    if (!(w_s0_io_tlb_1_resp_bits_s1_entry_tag[17] && w_s1_io_tlb_1_resp_bits_s1_entry_tag[17])) begin cov_fail++; $display("[COV] L2TLBWrapper.io_tlb_1_resp_bits_s1_entry_tag[17] 未见过 0 和 1"); end
    if (!(w_s0_io_tlb_1_resp_bits_s1_entry_tag[18] && w_s1_io_tlb_1_resp_bits_s1_entry_tag[18])) begin cov_fail++; $display("[COV] L2TLBWrapper.io_tlb_1_resp_bits_s1_entry_tag[18] 未见过 0 和 1"); end
    if (!(w_s0_io_tlb_1_resp_bits_s1_entry_tag[19] && w_s1_io_tlb_1_resp_bits_s1_entry_tag[19])) begin cov_fail++; $display("[COV] L2TLBWrapper.io_tlb_1_resp_bits_s1_entry_tag[19] 未见过 0 和 1"); end
    if (!(w_s0_io_tlb_1_resp_bits_s1_entry_tag[20] && w_s1_io_tlb_1_resp_bits_s1_entry_tag[20])) begin cov_fail++; $display("[COV] L2TLBWrapper.io_tlb_1_resp_bits_s1_entry_tag[20] 未见过 0 和 1"); end
    if (!(w_s0_io_tlb_1_resp_bits_s1_entry_tag[21] && w_s1_io_tlb_1_resp_bits_s1_entry_tag[21])) begin cov_fail++; $display("[COV] L2TLBWrapper.io_tlb_1_resp_bits_s1_entry_tag[21] 未见过 0 和 1"); end
    if (!(w_s0_io_tlb_1_resp_bits_s1_entry_tag[22] && w_s1_io_tlb_1_resp_bits_s1_entry_tag[22])) begin cov_fail++; $display("[COV] L2TLBWrapper.io_tlb_1_resp_bits_s1_entry_tag[22] 未见过 0 和 1"); end
    if (!(w_s0_io_tlb_1_resp_bits_s1_entry_tag[23] && w_s1_io_tlb_1_resp_bits_s1_entry_tag[23])) begin cov_fail++; $display("[COV] L2TLBWrapper.io_tlb_1_resp_bits_s1_entry_tag[23] 未见过 0 和 1"); end
    if (!(w_s0_io_tlb_1_resp_bits_s1_entry_tag[24] && w_s1_io_tlb_1_resp_bits_s1_entry_tag[24])) begin cov_fail++; $display("[COV] L2TLBWrapper.io_tlb_1_resp_bits_s1_entry_tag[24] 未见过 0 和 1"); end
    if (!(w_s0_io_tlb_1_resp_bits_s1_entry_tag[25] && w_s1_io_tlb_1_resp_bits_s1_entry_tag[25])) begin cov_fail++; $display("[COV] L2TLBWrapper.io_tlb_1_resp_bits_s1_entry_tag[25] 未见过 0 和 1"); end
    if (!(w_s0_io_tlb_1_resp_bits_s1_entry_tag[26] && w_s1_io_tlb_1_resp_bits_s1_entry_tag[26])) begin cov_fail++; $display("[COV] L2TLBWrapper.io_tlb_1_resp_bits_s1_entry_tag[26] 未见过 0 和 1"); end
    if (!(w_s0_io_tlb_1_resp_bits_s1_entry_tag[27] && w_s1_io_tlb_1_resp_bits_s1_entry_tag[27])) begin cov_fail++; $display("[COV] L2TLBWrapper.io_tlb_1_resp_bits_s1_entry_tag[27] 未见过 0 和 1"); end
    if (!(w_s0_io_tlb_1_resp_bits_s1_entry_tag[28] && w_s1_io_tlb_1_resp_bits_s1_entry_tag[28])) begin cov_fail++; $display("[COV] L2TLBWrapper.io_tlb_1_resp_bits_s1_entry_tag[28] 未见过 0 和 1"); end
    if (!(w_s0_io_tlb_1_resp_bits_s1_entry_tag[29] && w_s1_io_tlb_1_resp_bits_s1_entry_tag[29])) begin cov_fail++; $display("[COV] L2TLBWrapper.io_tlb_1_resp_bits_s1_entry_tag[29] 未见过 0 和 1"); end
    if (!(w_s0_io_tlb_1_resp_bits_s1_entry_tag[30] && w_s1_io_tlb_1_resp_bits_s1_entry_tag[30])) begin cov_fail++; $display("[COV] L2TLBWrapper.io_tlb_1_resp_bits_s1_entry_tag[30] 未见过 0 和 1"); end
    if (!(w_s0_io_tlb_1_resp_bits_s1_entry_tag[31] && w_s1_io_tlb_1_resp_bits_s1_entry_tag[31])) begin cov_fail++; $display("[COV] L2TLBWrapper.io_tlb_1_resp_bits_s1_entry_tag[31] 未见过 0 和 1"); end
    if (!(w_s0_io_tlb_1_resp_bits_s1_entry_tag[32] && w_s1_io_tlb_1_resp_bits_s1_entry_tag[32])) begin cov_fail++; $display("[COV] L2TLBWrapper.io_tlb_1_resp_bits_s1_entry_tag[32] 未见过 0 和 1"); end
    if (!(w_s0_io_tlb_1_resp_bits_s1_entry_tag[33] && w_s1_io_tlb_1_resp_bits_s1_entry_tag[33])) begin cov_fail++; $display("[COV] L2TLBWrapper.io_tlb_1_resp_bits_s1_entry_tag[33] 未见过 0 和 1"); end
    if (!(w_s0_io_tlb_1_resp_bits_s1_entry_tag[34] && w_s1_io_tlb_1_resp_bits_s1_entry_tag[34])) begin cov_fail++; $display("[COV] L2TLBWrapper.io_tlb_1_resp_bits_s1_entry_tag[34] 未见过 0 和 1"); end
    if (!(w_s0_io_tlb_1_resp_bits_s1_entry_asid[0] && w_s1_io_tlb_1_resp_bits_s1_entry_asid[0])) begin cov_fail++; $display("[COV] L2TLBWrapper.io_tlb_1_resp_bits_s1_entry_asid[0] 未见过 0 和 1"); end
    if (!(w_s0_io_tlb_1_resp_bits_s1_entry_asid[1] && w_s1_io_tlb_1_resp_bits_s1_entry_asid[1])) begin cov_fail++; $display("[COV] L2TLBWrapper.io_tlb_1_resp_bits_s1_entry_asid[1] 未见过 0 和 1"); end
    if (!(w_s0_io_tlb_1_resp_bits_s1_entry_asid[2] && w_s1_io_tlb_1_resp_bits_s1_entry_asid[2])) begin cov_fail++; $display("[COV] L2TLBWrapper.io_tlb_1_resp_bits_s1_entry_asid[2] 未见过 0 和 1"); end
    if (!(w_s0_io_tlb_1_resp_bits_s1_entry_asid[3] && w_s1_io_tlb_1_resp_bits_s1_entry_asid[3])) begin cov_fail++; $display("[COV] L2TLBWrapper.io_tlb_1_resp_bits_s1_entry_asid[3] 未见过 0 和 1"); end
    if (!(w_s0_io_tlb_1_resp_bits_s1_entry_asid[4] && w_s1_io_tlb_1_resp_bits_s1_entry_asid[4])) begin cov_fail++; $display("[COV] L2TLBWrapper.io_tlb_1_resp_bits_s1_entry_asid[4] 未见过 0 和 1"); end
    if (!(w_s0_io_tlb_1_resp_bits_s1_entry_asid[5] && w_s1_io_tlb_1_resp_bits_s1_entry_asid[5])) begin cov_fail++; $display("[COV] L2TLBWrapper.io_tlb_1_resp_bits_s1_entry_asid[5] 未见过 0 和 1"); end
    if (!(w_s0_io_tlb_1_resp_bits_s1_entry_asid[6] && w_s1_io_tlb_1_resp_bits_s1_entry_asid[6])) begin cov_fail++; $display("[COV] L2TLBWrapper.io_tlb_1_resp_bits_s1_entry_asid[6] 未见过 0 和 1"); end
    if (!(w_s0_io_tlb_1_resp_bits_s1_entry_asid[7] && w_s1_io_tlb_1_resp_bits_s1_entry_asid[7])) begin cov_fail++; $display("[COV] L2TLBWrapper.io_tlb_1_resp_bits_s1_entry_asid[7] 未见过 0 和 1"); end
    if (!(w_s0_io_tlb_1_resp_bits_s1_entry_asid[8] && w_s1_io_tlb_1_resp_bits_s1_entry_asid[8])) begin cov_fail++; $display("[COV] L2TLBWrapper.io_tlb_1_resp_bits_s1_entry_asid[8] 未见过 0 和 1"); end
    if (!(w_s0_io_tlb_1_resp_bits_s1_entry_asid[9] && w_s1_io_tlb_1_resp_bits_s1_entry_asid[9])) begin cov_fail++; $display("[COV] L2TLBWrapper.io_tlb_1_resp_bits_s1_entry_asid[9] 未见过 0 和 1"); end
    if (!(w_s0_io_tlb_1_resp_bits_s1_entry_asid[10] && w_s1_io_tlb_1_resp_bits_s1_entry_asid[10])) begin cov_fail++; $display("[COV] L2TLBWrapper.io_tlb_1_resp_bits_s1_entry_asid[10] 未见过 0 和 1"); end
    if (!(w_s0_io_tlb_1_resp_bits_s1_entry_asid[11] && w_s1_io_tlb_1_resp_bits_s1_entry_asid[11])) begin cov_fail++; $display("[COV] L2TLBWrapper.io_tlb_1_resp_bits_s1_entry_asid[11] 未见过 0 和 1"); end
    if (!(w_s0_io_tlb_1_resp_bits_s1_entry_asid[12] && w_s1_io_tlb_1_resp_bits_s1_entry_asid[12])) begin cov_fail++; $display("[COV] L2TLBWrapper.io_tlb_1_resp_bits_s1_entry_asid[12] 未见过 0 和 1"); end
    if (!(w_s0_io_tlb_1_resp_bits_s1_entry_asid[13] && w_s1_io_tlb_1_resp_bits_s1_entry_asid[13])) begin cov_fail++; $display("[COV] L2TLBWrapper.io_tlb_1_resp_bits_s1_entry_asid[13] 未见过 0 和 1"); end
    if (!(w_s0_io_tlb_1_resp_bits_s1_entry_asid[14] && w_s1_io_tlb_1_resp_bits_s1_entry_asid[14])) begin cov_fail++; $display("[COV] L2TLBWrapper.io_tlb_1_resp_bits_s1_entry_asid[14] 未见过 0 和 1"); end
    if (!(w_s0_io_tlb_1_resp_bits_s1_entry_asid[15] && w_s1_io_tlb_1_resp_bits_s1_entry_asid[15])) begin cov_fail++; $display("[COV] L2TLBWrapper.io_tlb_1_resp_bits_s1_entry_asid[15] 未见过 0 和 1"); end
    if (!(w_s0_io_tlb_1_resp_bits_s1_entry_vmid[0] && w_s1_io_tlb_1_resp_bits_s1_entry_vmid[0])) begin cov_fail++; $display("[COV] L2TLBWrapper.io_tlb_1_resp_bits_s1_entry_vmid[0] 未见过 0 和 1"); end
    if (!(w_s0_io_tlb_1_resp_bits_s1_entry_vmid[1] && w_s1_io_tlb_1_resp_bits_s1_entry_vmid[1])) begin cov_fail++; $display("[COV] L2TLBWrapper.io_tlb_1_resp_bits_s1_entry_vmid[1] 未见过 0 和 1"); end
    if (!(w_s0_io_tlb_1_resp_bits_s1_entry_vmid[2] && w_s1_io_tlb_1_resp_bits_s1_entry_vmid[2])) begin cov_fail++; $display("[COV] L2TLBWrapper.io_tlb_1_resp_bits_s1_entry_vmid[2] 未见过 0 和 1"); end
    if (!(w_s0_io_tlb_1_resp_bits_s1_entry_vmid[3] && w_s1_io_tlb_1_resp_bits_s1_entry_vmid[3])) begin cov_fail++; $display("[COV] L2TLBWrapper.io_tlb_1_resp_bits_s1_entry_vmid[3] 未见过 0 和 1"); end
    if (!(w_s0_io_tlb_1_resp_bits_s1_entry_vmid[4] && w_s1_io_tlb_1_resp_bits_s1_entry_vmid[4])) begin cov_fail++; $display("[COV] L2TLBWrapper.io_tlb_1_resp_bits_s1_entry_vmid[4] 未见过 0 和 1"); end
    if (!(w_s0_io_tlb_1_resp_bits_s1_entry_vmid[5] && w_s1_io_tlb_1_resp_bits_s1_entry_vmid[5])) begin cov_fail++; $display("[COV] L2TLBWrapper.io_tlb_1_resp_bits_s1_entry_vmid[5] 未见过 0 和 1"); end
    if (!(w_s0_io_tlb_1_resp_bits_s1_entry_vmid[6] && w_s1_io_tlb_1_resp_bits_s1_entry_vmid[6])) begin cov_fail++; $display("[COV] L2TLBWrapper.io_tlb_1_resp_bits_s1_entry_vmid[6] 未见过 0 和 1"); end
    if (!(w_s0_io_tlb_1_resp_bits_s1_entry_vmid[7] && w_s1_io_tlb_1_resp_bits_s1_entry_vmid[7])) begin cov_fail++; $display("[COV] L2TLBWrapper.io_tlb_1_resp_bits_s1_entry_vmid[7] 未见过 0 和 1"); end
    if (!(w_s0_io_tlb_1_resp_bits_s1_entry_vmid[8] && w_s1_io_tlb_1_resp_bits_s1_entry_vmid[8])) begin cov_fail++; $display("[COV] L2TLBWrapper.io_tlb_1_resp_bits_s1_entry_vmid[8] 未见过 0 和 1"); end
    if (!(w_s0_io_tlb_1_resp_bits_s1_entry_vmid[9] && w_s1_io_tlb_1_resp_bits_s1_entry_vmid[9])) begin cov_fail++; $display("[COV] L2TLBWrapper.io_tlb_1_resp_bits_s1_entry_vmid[9] 未见过 0 和 1"); end
    if (!(w_s0_io_tlb_1_resp_bits_s1_entry_vmid[10] && w_s1_io_tlb_1_resp_bits_s1_entry_vmid[10])) begin cov_fail++; $display("[COV] L2TLBWrapper.io_tlb_1_resp_bits_s1_entry_vmid[10] 未见过 0 和 1"); end
    if (!(w_s0_io_tlb_1_resp_bits_s1_entry_vmid[11] && w_s1_io_tlb_1_resp_bits_s1_entry_vmid[11])) begin cov_fail++; $display("[COV] L2TLBWrapper.io_tlb_1_resp_bits_s1_entry_vmid[11] 未见过 0 和 1"); end
    if (!(w_s0_io_tlb_1_resp_bits_s1_entry_vmid[12] && w_s1_io_tlb_1_resp_bits_s1_entry_vmid[12])) begin cov_fail++; $display("[COV] L2TLBWrapper.io_tlb_1_resp_bits_s1_entry_vmid[12] 未见过 0 和 1"); end
    if (!(w_s0_io_tlb_1_resp_bits_s1_entry_vmid[13] && w_s1_io_tlb_1_resp_bits_s1_entry_vmid[13])) begin cov_fail++; $display("[COV] L2TLBWrapper.io_tlb_1_resp_bits_s1_entry_vmid[13] 未见过 0 和 1"); end
    if (!(w_s0_io_tlb_1_resp_bits_s1_entry_n && w_s1_io_tlb_1_resp_bits_s1_entry_n)) begin cov_fail++; $display("[COV] L2TLBWrapper.io_tlb_1_resp_bits_s1_entry_n 未见过 0 和 1"); end
    if (!(w_s0_io_tlb_1_resp_bits_s1_entry_pbmt[0] && w_s1_io_tlb_1_resp_bits_s1_entry_pbmt[0])) begin cov_fail++; $display("[COV] L2TLBWrapper.io_tlb_1_resp_bits_s1_entry_pbmt[0] 未见过 0 和 1"); end
    if (!(w_s0_io_tlb_1_resp_bits_s1_entry_pbmt[1] && w_s1_io_tlb_1_resp_bits_s1_entry_pbmt[1])) begin cov_fail++; $display("[COV] L2TLBWrapper.io_tlb_1_resp_bits_s1_entry_pbmt[1] 未见过 0 和 1"); end
    if (!(w_s0_io_tlb_1_resp_bits_s1_entry_perm_d && w_s1_io_tlb_1_resp_bits_s1_entry_perm_d)) begin cov_fail++; $display("[COV] L2TLBWrapper.io_tlb_1_resp_bits_s1_entry_perm_d 未见过 0 和 1"); end
    if (!(w_s0_io_tlb_1_resp_bits_s1_entry_perm_a && w_s1_io_tlb_1_resp_bits_s1_entry_perm_a)) begin cov_fail++; $display("[COV] L2TLBWrapper.io_tlb_1_resp_bits_s1_entry_perm_a 未见过 0 和 1"); end
    if (!(w_s0_io_tlb_1_resp_bits_s1_entry_perm_g && w_s1_io_tlb_1_resp_bits_s1_entry_perm_g)) begin cov_fail++; $display("[COV] L2TLBWrapper.io_tlb_1_resp_bits_s1_entry_perm_g 未见过 0 和 1"); end
    if (!(w_s0_io_tlb_1_resp_bits_s1_entry_perm_u && w_s1_io_tlb_1_resp_bits_s1_entry_perm_u)) begin cov_fail++; $display("[COV] L2TLBWrapper.io_tlb_1_resp_bits_s1_entry_perm_u 未见过 0 和 1"); end
    if (!(w_s0_io_tlb_1_resp_bits_s1_entry_perm_x && w_s1_io_tlb_1_resp_bits_s1_entry_perm_x)) begin cov_fail++; $display("[COV] L2TLBWrapper.io_tlb_1_resp_bits_s1_entry_perm_x 未见过 0 和 1"); end
    if (!(w_s0_io_tlb_1_resp_bits_s1_entry_perm_w && w_s1_io_tlb_1_resp_bits_s1_entry_perm_w)) begin cov_fail++; $display("[COV] L2TLBWrapper.io_tlb_1_resp_bits_s1_entry_perm_w 未见过 0 和 1"); end
    if (!(w_s0_io_tlb_1_resp_bits_s1_entry_perm_r && w_s1_io_tlb_1_resp_bits_s1_entry_perm_r)) begin cov_fail++; $display("[COV] L2TLBWrapper.io_tlb_1_resp_bits_s1_entry_perm_r 未见过 0 和 1"); end
    if (!(w_s0_io_tlb_1_resp_bits_s1_entry_level[0] && w_s1_io_tlb_1_resp_bits_s1_entry_level[0])) begin cov_fail++; $display("[COV] L2TLBWrapper.io_tlb_1_resp_bits_s1_entry_level[0] 未见过 0 和 1"); end
    if (!(w_s0_io_tlb_1_resp_bits_s1_entry_level[1] && w_s1_io_tlb_1_resp_bits_s1_entry_level[1])) begin cov_fail++; $display("[COV] L2TLBWrapper.io_tlb_1_resp_bits_s1_entry_level[1] 未见过 0 和 1"); end
    if (!(w_s0_io_tlb_1_resp_bits_s1_entry_v && w_s1_io_tlb_1_resp_bits_s1_entry_v)) begin cov_fail++; $display("[COV] L2TLBWrapper.io_tlb_1_resp_bits_s1_entry_v 未见过 0 和 1"); end
    if (!(w_s0_io_tlb_1_resp_bits_s1_entry_ppn[0] && w_s1_io_tlb_1_resp_bits_s1_entry_ppn[0])) begin cov_fail++; $display("[COV] L2TLBWrapper.io_tlb_1_resp_bits_s1_entry_ppn[0] 未见过 0 和 1"); end
    if (!(w_s0_io_tlb_1_resp_bits_s1_entry_ppn[1] && w_s1_io_tlb_1_resp_bits_s1_entry_ppn[1])) begin cov_fail++; $display("[COV] L2TLBWrapper.io_tlb_1_resp_bits_s1_entry_ppn[1] 未见过 0 和 1"); end
    if (!(w_s0_io_tlb_1_resp_bits_s1_entry_ppn[2] && w_s1_io_tlb_1_resp_bits_s1_entry_ppn[2])) begin cov_fail++; $display("[COV] L2TLBWrapper.io_tlb_1_resp_bits_s1_entry_ppn[2] 未见过 0 和 1"); end
    if (!(w_s0_io_tlb_1_resp_bits_s1_entry_ppn[3] && w_s1_io_tlb_1_resp_bits_s1_entry_ppn[3])) begin cov_fail++; $display("[COV] L2TLBWrapper.io_tlb_1_resp_bits_s1_entry_ppn[3] 未见过 0 和 1"); end
    if (!(w_s0_io_tlb_1_resp_bits_s1_entry_ppn[4] && w_s1_io_tlb_1_resp_bits_s1_entry_ppn[4])) begin cov_fail++; $display("[COV] L2TLBWrapper.io_tlb_1_resp_bits_s1_entry_ppn[4] 未见过 0 和 1"); end
    if (!(w_s0_io_tlb_1_resp_bits_s1_entry_ppn[5] && w_s1_io_tlb_1_resp_bits_s1_entry_ppn[5])) begin cov_fail++; $display("[COV] L2TLBWrapper.io_tlb_1_resp_bits_s1_entry_ppn[5] 未见过 0 和 1"); end
    if (!(w_s0_io_tlb_1_resp_bits_s1_entry_ppn[6] && w_s1_io_tlb_1_resp_bits_s1_entry_ppn[6])) begin cov_fail++; $display("[COV] L2TLBWrapper.io_tlb_1_resp_bits_s1_entry_ppn[6] 未见过 0 和 1"); end
    if (!(w_s0_io_tlb_1_resp_bits_s1_entry_ppn[7] && w_s1_io_tlb_1_resp_bits_s1_entry_ppn[7])) begin cov_fail++; $display("[COV] L2TLBWrapper.io_tlb_1_resp_bits_s1_entry_ppn[7] 未见过 0 和 1"); end
    if (!(w_s0_io_tlb_1_resp_bits_s1_entry_ppn[8] && w_s1_io_tlb_1_resp_bits_s1_entry_ppn[8])) begin cov_fail++; $display("[COV] L2TLBWrapper.io_tlb_1_resp_bits_s1_entry_ppn[8] 未见过 0 和 1"); end
    if (!(w_s0_io_tlb_1_resp_bits_s1_entry_ppn[9] && w_s1_io_tlb_1_resp_bits_s1_entry_ppn[9])) begin cov_fail++; $display("[COV] L2TLBWrapper.io_tlb_1_resp_bits_s1_entry_ppn[9] 未见过 0 和 1"); end
    if (!(w_s0_io_tlb_1_resp_bits_s1_entry_ppn[10] && w_s1_io_tlb_1_resp_bits_s1_entry_ppn[10])) begin cov_fail++; $display("[COV] L2TLBWrapper.io_tlb_1_resp_bits_s1_entry_ppn[10] 未见过 0 和 1"); end
    if (!(w_s0_io_tlb_1_resp_bits_s1_entry_ppn[11] && w_s1_io_tlb_1_resp_bits_s1_entry_ppn[11])) begin cov_fail++; $display("[COV] L2TLBWrapper.io_tlb_1_resp_bits_s1_entry_ppn[11] 未见过 0 和 1"); end
    if (!(w_s0_io_tlb_1_resp_bits_s1_entry_ppn[12] && w_s1_io_tlb_1_resp_bits_s1_entry_ppn[12])) begin cov_fail++; $display("[COV] L2TLBWrapper.io_tlb_1_resp_bits_s1_entry_ppn[12] 未见过 0 和 1"); end
    if (!(w_s0_io_tlb_1_resp_bits_s1_entry_ppn[13] && w_s1_io_tlb_1_resp_bits_s1_entry_ppn[13])) begin cov_fail++; $display("[COV] L2TLBWrapper.io_tlb_1_resp_bits_s1_entry_ppn[13] 未见过 0 和 1"); end
    if (!(w_s0_io_tlb_1_resp_bits_s1_entry_ppn[14] && w_s1_io_tlb_1_resp_bits_s1_entry_ppn[14])) begin cov_fail++; $display("[COV] L2TLBWrapper.io_tlb_1_resp_bits_s1_entry_ppn[14] 未见过 0 和 1"); end
    if (!(w_s0_io_tlb_1_resp_bits_s1_entry_ppn[15] && w_s1_io_tlb_1_resp_bits_s1_entry_ppn[15])) begin cov_fail++; $display("[COV] L2TLBWrapper.io_tlb_1_resp_bits_s1_entry_ppn[15] 未见过 0 和 1"); end
    if (!(w_s0_io_tlb_1_resp_bits_s1_entry_ppn[16] && w_s1_io_tlb_1_resp_bits_s1_entry_ppn[16])) begin cov_fail++; $display("[COV] L2TLBWrapper.io_tlb_1_resp_bits_s1_entry_ppn[16] 未见过 0 和 1"); end
    if (!(w_s0_io_tlb_1_resp_bits_s1_entry_ppn[17] && w_s1_io_tlb_1_resp_bits_s1_entry_ppn[17])) begin cov_fail++; $display("[COV] L2TLBWrapper.io_tlb_1_resp_bits_s1_entry_ppn[17] 未见过 0 和 1"); end
    if (!(w_s0_io_tlb_1_resp_bits_s1_entry_ppn[18] && w_s1_io_tlb_1_resp_bits_s1_entry_ppn[18])) begin cov_fail++; $display("[COV] L2TLBWrapper.io_tlb_1_resp_bits_s1_entry_ppn[18] 未见过 0 和 1"); end
    if (!(w_s0_io_tlb_1_resp_bits_s1_entry_ppn[19] && w_s1_io_tlb_1_resp_bits_s1_entry_ppn[19])) begin cov_fail++; $display("[COV] L2TLBWrapper.io_tlb_1_resp_bits_s1_entry_ppn[19] 未见过 0 和 1"); end
    if (!(w_s0_io_tlb_1_resp_bits_s1_entry_ppn[20] && w_s1_io_tlb_1_resp_bits_s1_entry_ppn[20])) begin cov_fail++; $display("[COV] L2TLBWrapper.io_tlb_1_resp_bits_s1_entry_ppn[20] 未见过 0 和 1"); end
    if (!(w_s0_io_tlb_1_resp_bits_s1_entry_ppn[21] && w_s1_io_tlb_1_resp_bits_s1_entry_ppn[21])) begin cov_fail++; $display("[COV] L2TLBWrapper.io_tlb_1_resp_bits_s1_entry_ppn[21] 未见过 0 和 1"); end
    if (!(w_s0_io_tlb_1_resp_bits_s1_entry_ppn[22] && w_s1_io_tlb_1_resp_bits_s1_entry_ppn[22])) begin cov_fail++; $display("[COV] L2TLBWrapper.io_tlb_1_resp_bits_s1_entry_ppn[22] 未见过 0 和 1"); end
    if (!(w_s0_io_tlb_1_resp_bits_s1_entry_ppn[23] && w_s1_io_tlb_1_resp_bits_s1_entry_ppn[23])) begin cov_fail++; $display("[COV] L2TLBWrapper.io_tlb_1_resp_bits_s1_entry_ppn[23] 未见过 0 和 1"); end
    if (!(w_s0_io_tlb_1_resp_bits_s1_entry_ppn[24] && w_s1_io_tlb_1_resp_bits_s1_entry_ppn[24])) begin cov_fail++; $display("[COV] L2TLBWrapper.io_tlb_1_resp_bits_s1_entry_ppn[24] 未见过 0 和 1"); end
    if (!(w_s0_io_tlb_1_resp_bits_s1_entry_ppn[25] && w_s1_io_tlb_1_resp_bits_s1_entry_ppn[25])) begin cov_fail++; $display("[COV] L2TLBWrapper.io_tlb_1_resp_bits_s1_entry_ppn[25] 未见过 0 和 1"); end
    if (!(w_s0_io_tlb_1_resp_bits_s1_entry_ppn[26] && w_s1_io_tlb_1_resp_bits_s1_entry_ppn[26])) begin cov_fail++; $display("[COV] L2TLBWrapper.io_tlb_1_resp_bits_s1_entry_ppn[26] 未见过 0 和 1"); end
    if (!(w_s0_io_tlb_1_resp_bits_s1_entry_ppn[27] && w_s1_io_tlb_1_resp_bits_s1_entry_ppn[27])) begin cov_fail++; $display("[COV] L2TLBWrapper.io_tlb_1_resp_bits_s1_entry_ppn[27] 未见过 0 和 1"); end
    if (!(w_s0_io_tlb_1_resp_bits_s1_entry_ppn[28] && w_s1_io_tlb_1_resp_bits_s1_entry_ppn[28])) begin cov_fail++; $display("[COV] L2TLBWrapper.io_tlb_1_resp_bits_s1_entry_ppn[28] 未见过 0 和 1"); end
    if (!(w_s0_io_tlb_1_resp_bits_s1_entry_ppn[29] && w_s1_io_tlb_1_resp_bits_s1_entry_ppn[29])) begin cov_fail++; $display("[COV] L2TLBWrapper.io_tlb_1_resp_bits_s1_entry_ppn[29] 未见过 0 和 1"); end
    if (!(w_s0_io_tlb_1_resp_bits_s1_entry_ppn[30] && w_s1_io_tlb_1_resp_bits_s1_entry_ppn[30])) begin cov_fail++; $display("[COV] L2TLBWrapper.io_tlb_1_resp_bits_s1_entry_ppn[30] 未见过 0 和 1"); end
    if (!(w_s0_io_tlb_1_resp_bits_s1_entry_ppn[31] && w_s1_io_tlb_1_resp_bits_s1_entry_ppn[31])) begin cov_fail++; $display("[COV] L2TLBWrapper.io_tlb_1_resp_bits_s1_entry_ppn[31] 未见过 0 和 1"); end
    if (!(w_s0_io_tlb_1_resp_bits_s1_entry_ppn[32] && w_s1_io_tlb_1_resp_bits_s1_entry_ppn[32])) begin cov_fail++; $display("[COV] L2TLBWrapper.io_tlb_1_resp_bits_s1_entry_ppn[32] 未见过 0 和 1"); end
    if (!(w_s0_io_tlb_1_resp_bits_s1_entry_ppn[33] && w_s1_io_tlb_1_resp_bits_s1_entry_ppn[33])) begin cov_fail++; $display("[COV] L2TLBWrapper.io_tlb_1_resp_bits_s1_entry_ppn[33] 未见过 0 和 1"); end
    if (!(w_s0_io_tlb_1_resp_bits_s1_entry_ppn[34] && w_s1_io_tlb_1_resp_bits_s1_entry_ppn[34])) begin cov_fail++; $display("[COV] L2TLBWrapper.io_tlb_1_resp_bits_s1_entry_ppn[34] 未见过 0 和 1"); end
    if (!(w_s0_io_tlb_1_resp_bits_s1_entry_ppn[35] && w_s1_io_tlb_1_resp_bits_s1_entry_ppn[35])) begin cov_fail++; $display("[COV] L2TLBWrapper.io_tlb_1_resp_bits_s1_entry_ppn[35] 未见过 0 和 1"); end
    if (!(w_s0_io_tlb_1_resp_bits_s1_entry_ppn[36] && w_s1_io_tlb_1_resp_bits_s1_entry_ppn[36])) begin cov_fail++; $display("[COV] L2TLBWrapper.io_tlb_1_resp_bits_s1_entry_ppn[36] 未见过 0 和 1"); end
    if (!(w_s0_io_tlb_1_resp_bits_s1_entry_ppn[37] && w_s1_io_tlb_1_resp_bits_s1_entry_ppn[37])) begin cov_fail++; $display("[COV] L2TLBWrapper.io_tlb_1_resp_bits_s1_entry_ppn[37] 未见过 0 和 1"); end
    if (!(w_s0_io_tlb_1_resp_bits_s1_entry_ppn[38] && w_s1_io_tlb_1_resp_bits_s1_entry_ppn[38])) begin cov_fail++; $display("[COV] L2TLBWrapper.io_tlb_1_resp_bits_s1_entry_ppn[38] 未见过 0 和 1"); end
    if (!(w_s0_io_tlb_1_resp_bits_s1_entry_ppn[39] && w_s1_io_tlb_1_resp_bits_s1_entry_ppn[39])) begin cov_fail++; $display("[COV] L2TLBWrapper.io_tlb_1_resp_bits_s1_entry_ppn[39] 未见过 0 和 1"); end
    if (!(w_s0_io_tlb_1_resp_bits_s1_entry_ppn[40] && w_s1_io_tlb_1_resp_bits_s1_entry_ppn[40])) begin cov_fail++; $display("[COV] L2TLBWrapper.io_tlb_1_resp_bits_s1_entry_ppn[40] 未见过 0 和 1"); end
    if (!(w_s0_io_tlb_1_resp_bits_s1_addr_low[0] && w_s1_io_tlb_1_resp_bits_s1_addr_low[0])) begin cov_fail++; $display("[COV] L2TLBWrapper.io_tlb_1_resp_bits_s1_addr_low[0] 未见过 0 和 1"); end
    if (!(w_s0_io_tlb_1_resp_bits_s1_addr_low[1] && w_s1_io_tlb_1_resp_bits_s1_addr_low[1])) begin cov_fail++; $display("[COV] L2TLBWrapper.io_tlb_1_resp_bits_s1_addr_low[1] 未见过 0 和 1"); end
    if (!(w_s0_io_tlb_1_resp_bits_s1_addr_low[2] && w_s1_io_tlb_1_resp_bits_s1_addr_low[2])) begin cov_fail++; $display("[COV] L2TLBWrapper.io_tlb_1_resp_bits_s1_addr_low[2] 未见过 0 和 1"); end
    if (!(w_s0_io_tlb_1_resp_bits_s1_ppn_low_0[0] && w_s1_io_tlb_1_resp_bits_s1_ppn_low_0[0])) begin cov_fail++; $display("[COV] L2TLBWrapper.io_tlb_1_resp_bits_s1_ppn_low_0[0] 未见过 0 和 1"); end
    if (!(w_s0_io_tlb_1_resp_bits_s1_ppn_low_0[1] && w_s1_io_tlb_1_resp_bits_s1_ppn_low_0[1])) begin cov_fail++; $display("[COV] L2TLBWrapper.io_tlb_1_resp_bits_s1_ppn_low_0[1] 未见过 0 和 1"); end
    if (!(w_s0_io_tlb_1_resp_bits_s1_ppn_low_0[2] && w_s1_io_tlb_1_resp_bits_s1_ppn_low_0[2])) begin cov_fail++; $display("[COV] L2TLBWrapper.io_tlb_1_resp_bits_s1_ppn_low_0[2] 未见过 0 和 1"); end
    if (!(w_s0_io_tlb_1_resp_bits_s1_ppn_low_1[0] && w_s1_io_tlb_1_resp_bits_s1_ppn_low_1[0])) begin cov_fail++; $display("[COV] L2TLBWrapper.io_tlb_1_resp_bits_s1_ppn_low_1[0] 未见过 0 和 1"); end
    if (!(w_s0_io_tlb_1_resp_bits_s1_ppn_low_1[1] && w_s1_io_tlb_1_resp_bits_s1_ppn_low_1[1])) begin cov_fail++; $display("[COV] L2TLBWrapper.io_tlb_1_resp_bits_s1_ppn_low_1[1] 未见过 0 和 1"); end
    if (!(w_s0_io_tlb_1_resp_bits_s1_ppn_low_1[2] && w_s1_io_tlb_1_resp_bits_s1_ppn_low_1[2])) begin cov_fail++; $display("[COV] L2TLBWrapper.io_tlb_1_resp_bits_s1_ppn_low_1[2] 未见过 0 和 1"); end
    if (!(w_s0_io_tlb_1_resp_bits_s1_ppn_low_2[0] && w_s1_io_tlb_1_resp_bits_s1_ppn_low_2[0])) begin cov_fail++; $display("[COV] L2TLBWrapper.io_tlb_1_resp_bits_s1_ppn_low_2[0] 未见过 0 和 1"); end
    if (!(w_s0_io_tlb_1_resp_bits_s1_ppn_low_2[1] && w_s1_io_tlb_1_resp_bits_s1_ppn_low_2[1])) begin cov_fail++; $display("[COV] L2TLBWrapper.io_tlb_1_resp_bits_s1_ppn_low_2[1] 未见过 0 和 1"); end
    if (!(w_s0_io_tlb_1_resp_bits_s1_ppn_low_2[2] && w_s1_io_tlb_1_resp_bits_s1_ppn_low_2[2])) begin cov_fail++; $display("[COV] L2TLBWrapper.io_tlb_1_resp_bits_s1_ppn_low_2[2] 未见过 0 和 1"); end
    if (!(w_s0_io_tlb_1_resp_bits_s1_ppn_low_3[0] && w_s1_io_tlb_1_resp_bits_s1_ppn_low_3[0])) begin cov_fail++; $display("[COV] L2TLBWrapper.io_tlb_1_resp_bits_s1_ppn_low_3[0] 未见过 0 和 1"); end
    if (!(w_s0_io_tlb_1_resp_bits_s1_ppn_low_3[1] && w_s1_io_tlb_1_resp_bits_s1_ppn_low_3[1])) begin cov_fail++; $display("[COV] L2TLBWrapper.io_tlb_1_resp_bits_s1_ppn_low_3[1] 未见过 0 和 1"); end
    if (!(w_s0_io_tlb_1_resp_bits_s1_ppn_low_3[2] && w_s1_io_tlb_1_resp_bits_s1_ppn_low_3[2])) begin cov_fail++; $display("[COV] L2TLBWrapper.io_tlb_1_resp_bits_s1_ppn_low_3[2] 未见过 0 和 1"); end
    if (!(w_s0_io_tlb_1_resp_bits_s1_ppn_low_4[0] && w_s1_io_tlb_1_resp_bits_s1_ppn_low_4[0])) begin cov_fail++; $display("[COV] L2TLBWrapper.io_tlb_1_resp_bits_s1_ppn_low_4[0] 未见过 0 和 1"); end
    if (!(w_s0_io_tlb_1_resp_bits_s1_ppn_low_4[1] && w_s1_io_tlb_1_resp_bits_s1_ppn_low_4[1])) begin cov_fail++; $display("[COV] L2TLBWrapper.io_tlb_1_resp_bits_s1_ppn_low_4[1] 未见过 0 和 1"); end
    if (!(w_s0_io_tlb_1_resp_bits_s1_ppn_low_4[2] && w_s1_io_tlb_1_resp_bits_s1_ppn_low_4[2])) begin cov_fail++; $display("[COV] L2TLBWrapper.io_tlb_1_resp_bits_s1_ppn_low_4[2] 未见过 0 和 1"); end
    if (!(w_s0_io_tlb_1_resp_bits_s1_ppn_low_5[0] && w_s1_io_tlb_1_resp_bits_s1_ppn_low_5[0])) begin cov_fail++; $display("[COV] L2TLBWrapper.io_tlb_1_resp_bits_s1_ppn_low_5[0] 未见过 0 和 1"); end
    if (!(w_s0_io_tlb_1_resp_bits_s1_ppn_low_5[1] && w_s1_io_tlb_1_resp_bits_s1_ppn_low_5[1])) begin cov_fail++; $display("[COV] L2TLBWrapper.io_tlb_1_resp_bits_s1_ppn_low_5[1] 未见过 0 和 1"); end
    if (!(w_s0_io_tlb_1_resp_bits_s1_ppn_low_5[2] && w_s1_io_tlb_1_resp_bits_s1_ppn_low_5[2])) begin cov_fail++; $display("[COV] L2TLBWrapper.io_tlb_1_resp_bits_s1_ppn_low_5[2] 未见过 0 和 1"); end
    if (!(w_s0_io_tlb_1_resp_bits_s1_ppn_low_6[0] && w_s1_io_tlb_1_resp_bits_s1_ppn_low_6[0])) begin cov_fail++; $display("[COV] L2TLBWrapper.io_tlb_1_resp_bits_s1_ppn_low_6[0] 未见过 0 和 1"); end
    if (!(w_s0_io_tlb_1_resp_bits_s1_ppn_low_6[1] && w_s1_io_tlb_1_resp_bits_s1_ppn_low_6[1])) begin cov_fail++; $display("[COV] L2TLBWrapper.io_tlb_1_resp_bits_s1_ppn_low_6[1] 未见过 0 和 1"); end
    if (!(w_s0_io_tlb_1_resp_bits_s1_ppn_low_6[2] && w_s1_io_tlb_1_resp_bits_s1_ppn_low_6[2])) begin cov_fail++; $display("[COV] L2TLBWrapper.io_tlb_1_resp_bits_s1_ppn_low_6[2] 未见过 0 和 1"); end
    if (!(w_s0_io_tlb_1_resp_bits_s1_ppn_low_7[0] && w_s1_io_tlb_1_resp_bits_s1_ppn_low_7[0])) begin cov_fail++; $display("[COV] L2TLBWrapper.io_tlb_1_resp_bits_s1_ppn_low_7[0] 未见过 0 和 1"); end
    if (!(w_s0_io_tlb_1_resp_bits_s1_ppn_low_7[1] && w_s1_io_tlb_1_resp_bits_s1_ppn_low_7[1])) begin cov_fail++; $display("[COV] L2TLBWrapper.io_tlb_1_resp_bits_s1_ppn_low_7[1] 未见过 0 和 1"); end
    if (!(w_s0_io_tlb_1_resp_bits_s1_ppn_low_7[2] && w_s1_io_tlb_1_resp_bits_s1_ppn_low_7[2])) begin cov_fail++; $display("[COV] L2TLBWrapper.io_tlb_1_resp_bits_s1_ppn_low_7[2] 未见过 0 和 1"); end
    if (!(w_s0_io_tlb_1_resp_bits_s1_valididx_0 && w_s1_io_tlb_1_resp_bits_s1_valididx_0)) begin cov_fail++; $display("[COV] L2TLBWrapper.io_tlb_1_resp_bits_s1_valididx_0 未见过 0 和 1"); end
    if (!(w_s0_io_tlb_1_resp_bits_s1_valididx_1 && w_s1_io_tlb_1_resp_bits_s1_valididx_1)) begin cov_fail++; $display("[COV] L2TLBWrapper.io_tlb_1_resp_bits_s1_valididx_1 未见过 0 和 1"); end
    if (!(w_s0_io_tlb_1_resp_bits_s1_valididx_2 && w_s1_io_tlb_1_resp_bits_s1_valididx_2)) begin cov_fail++; $display("[COV] L2TLBWrapper.io_tlb_1_resp_bits_s1_valididx_2 未见过 0 和 1"); end
    if (!(w_s0_io_tlb_1_resp_bits_s1_valididx_3 && w_s1_io_tlb_1_resp_bits_s1_valididx_3)) begin cov_fail++; $display("[COV] L2TLBWrapper.io_tlb_1_resp_bits_s1_valididx_3 未见过 0 和 1"); end
    if (!(w_s0_io_tlb_1_resp_bits_s1_valididx_4 && w_s1_io_tlb_1_resp_bits_s1_valididx_4)) begin cov_fail++; $display("[COV] L2TLBWrapper.io_tlb_1_resp_bits_s1_valididx_4 未见过 0 和 1"); end
    if (!(w_s0_io_tlb_1_resp_bits_s1_valididx_5 && w_s1_io_tlb_1_resp_bits_s1_valididx_5)) begin cov_fail++; $display("[COV] L2TLBWrapper.io_tlb_1_resp_bits_s1_valididx_5 未见过 0 和 1"); end
    if (!(w_s0_io_tlb_1_resp_bits_s1_valididx_6 && w_s1_io_tlb_1_resp_bits_s1_valididx_6)) begin cov_fail++; $display("[COV] L2TLBWrapper.io_tlb_1_resp_bits_s1_valididx_6 未见过 0 和 1"); end
    if (!(w_s0_io_tlb_1_resp_bits_s1_valididx_7 && w_s1_io_tlb_1_resp_bits_s1_valididx_7)) begin cov_fail++; $display("[COV] L2TLBWrapper.io_tlb_1_resp_bits_s1_valididx_7 未见过 0 和 1"); end
    if (!(w_s0_io_tlb_1_resp_bits_s1_pteidx_0 && w_s1_io_tlb_1_resp_bits_s1_pteidx_0)) begin cov_fail++; $display("[COV] L2TLBWrapper.io_tlb_1_resp_bits_s1_pteidx_0 未见过 0 和 1"); end
    if (!(w_s0_io_tlb_1_resp_bits_s1_pteidx_1 && w_s1_io_tlb_1_resp_bits_s1_pteidx_1)) begin cov_fail++; $display("[COV] L2TLBWrapper.io_tlb_1_resp_bits_s1_pteidx_1 未见过 0 和 1"); end
    if (!(w_s0_io_tlb_1_resp_bits_s1_pteidx_2 && w_s1_io_tlb_1_resp_bits_s1_pteidx_2)) begin cov_fail++; $display("[COV] L2TLBWrapper.io_tlb_1_resp_bits_s1_pteidx_2 未见过 0 和 1"); end
    if (!(w_s0_io_tlb_1_resp_bits_s1_pteidx_3 && w_s1_io_tlb_1_resp_bits_s1_pteidx_3)) begin cov_fail++; $display("[COV] L2TLBWrapper.io_tlb_1_resp_bits_s1_pteidx_3 未见过 0 和 1"); end
    if (!(w_s0_io_tlb_1_resp_bits_s1_pteidx_4 && w_s1_io_tlb_1_resp_bits_s1_pteidx_4)) begin cov_fail++; $display("[COV] L2TLBWrapper.io_tlb_1_resp_bits_s1_pteidx_4 未见过 0 和 1"); end
    if (!(w_s0_io_tlb_1_resp_bits_s1_pteidx_5 && w_s1_io_tlb_1_resp_bits_s1_pteidx_5)) begin cov_fail++; $display("[COV] L2TLBWrapper.io_tlb_1_resp_bits_s1_pteidx_5 未见过 0 和 1"); end
    if (!(w_s0_io_tlb_1_resp_bits_s1_pteidx_6 && w_s1_io_tlb_1_resp_bits_s1_pteidx_6)) begin cov_fail++; $display("[COV] L2TLBWrapper.io_tlb_1_resp_bits_s1_pteidx_6 未见过 0 和 1"); end
    if (!(w_s0_io_tlb_1_resp_bits_s1_pteidx_7 && w_s1_io_tlb_1_resp_bits_s1_pteidx_7)) begin cov_fail++; $display("[COV] L2TLBWrapper.io_tlb_1_resp_bits_s1_pteidx_7 未见过 0 和 1"); end
    if (!(w_s0_io_tlb_1_resp_bits_s1_pf && w_s1_io_tlb_1_resp_bits_s1_pf)) begin cov_fail++; $display("[COV] L2TLBWrapper.io_tlb_1_resp_bits_s1_pf 未见过 0 和 1"); end
    if (!(w_s0_io_tlb_1_resp_bits_s1_af && w_s1_io_tlb_1_resp_bits_s1_af)) begin cov_fail++; $display("[COV] L2TLBWrapper.io_tlb_1_resp_bits_s1_af 未见过 0 和 1"); end
    if (!(w_s0_io_tlb_1_resp_bits_s2_entry_tag[0] && w_s1_io_tlb_1_resp_bits_s2_entry_tag[0])) begin cov_fail++; $display("[COV] L2TLBWrapper.io_tlb_1_resp_bits_s2_entry_tag[0] 未见过 0 和 1"); end
    if (!(w_s0_io_tlb_1_resp_bits_s2_entry_tag[1] && w_s1_io_tlb_1_resp_bits_s2_entry_tag[1])) begin cov_fail++; $display("[COV] L2TLBWrapper.io_tlb_1_resp_bits_s2_entry_tag[1] 未见过 0 和 1"); end
    if (!(w_s0_io_tlb_1_resp_bits_s2_entry_tag[2] && w_s1_io_tlb_1_resp_bits_s2_entry_tag[2])) begin cov_fail++; $display("[COV] L2TLBWrapper.io_tlb_1_resp_bits_s2_entry_tag[2] 未见过 0 和 1"); end
    if (!(w_s0_io_tlb_1_resp_bits_s2_entry_tag[3] && w_s1_io_tlb_1_resp_bits_s2_entry_tag[3])) begin cov_fail++; $display("[COV] L2TLBWrapper.io_tlb_1_resp_bits_s2_entry_tag[3] 未见过 0 和 1"); end
    if (!(w_s0_io_tlb_1_resp_bits_s2_entry_tag[4] && w_s1_io_tlb_1_resp_bits_s2_entry_tag[4])) begin cov_fail++; $display("[COV] L2TLBWrapper.io_tlb_1_resp_bits_s2_entry_tag[4] 未见过 0 和 1"); end
    if (!(w_s0_io_tlb_1_resp_bits_s2_entry_tag[5] && w_s1_io_tlb_1_resp_bits_s2_entry_tag[5])) begin cov_fail++; $display("[COV] L2TLBWrapper.io_tlb_1_resp_bits_s2_entry_tag[5] 未见过 0 和 1"); end
    if (!(w_s0_io_tlb_1_resp_bits_s2_entry_tag[6] && w_s1_io_tlb_1_resp_bits_s2_entry_tag[6])) begin cov_fail++; $display("[COV] L2TLBWrapper.io_tlb_1_resp_bits_s2_entry_tag[6] 未见过 0 和 1"); end
    if (!(w_s0_io_tlb_1_resp_bits_s2_entry_tag[7] && w_s1_io_tlb_1_resp_bits_s2_entry_tag[7])) begin cov_fail++; $display("[COV] L2TLBWrapper.io_tlb_1_resp_bits_s2_entry_tag[7] 未见过 0 和 1"); end
    if (!(w_s0_io_tlb_1_resp_bits_s2_entry_tag[8] && w_s1_io_tlb_1_resp_bits_s2_entry_tag[8])) begin cov_fail++; $display("[COV] L2TLBWrapper.io_tlb_1_resp_bits_s2_entry_tag[8] 未见过 0 和 1"); end
    if (!(w_s0_io_tlb_1_resp_bits_s2_entry_tag[9] && w_s1_io_tlb_1_resp_bits_s2_entry_tag[9])) begin cov_fail++; $display("[COV] L2TLBWrapper.io_tlb_1_resp_bits_s2_entry_tag[9] 未见过 0 和 1"); end
    if (!(w_s0_io_tlb_1_resp_bits_s2_entry_tag[10] && w_s1_io_tlb_1_resp_bits_s2_entry_tag[10])) begin cov_fail++; $display("[COV] L2TLBWrapper.io_tlb_1_resp_bits_s2_entry_tag[10] 未见过 0 和 1"); end
    if (!(w_s0_io_tlb_1_resp_bits_s2_entry_tag[11] && w_s1_io_tlb_1_resp_bits_s2_entry_tag[11])) begin cov_fail++; $display("[COV] L2TLBWrapper.io_tlb_1_resp_bits_s2_entry_tag[11] 未见过 0 和 1"); end
    if (!(w_s0_io_tlb_1_resp_bits_s2_entry_tag[12] && w_s1_io_tlb_1_resp_bits_s2_entry_tag[12])) begin cov_fail++; $display("[COV] L2TLBWrapper.io_tlb_1_resp_bits_s2_entry_tag[12] 未见过 0 和 1"); end
    if (!(w_s0_io_tlb_1_resp_bits_s2_entry_tag[13] && w_s1_io_tlb_1_resp_bits_s2_entry_tag[13])) begin cov_fail++; $display("[COV] L2TLBWrapper.io_tlb_1_resp_bits_s2_entry_tag[13] 未见过 0 和 1"); end
    if (!(w_s0_io_tlb_1_resp_bits_s2_entry_tag[14] && w_s1_io_tlb_1_resp_bits_s2_entry_tag[14])) begin cov_fail++; $display("[COV] L2TLBWrapper.io_tlb_1_resp_bits_s2_entry_tag[14] 未见过 0 和 1"); end
    if (!(w_s0_io_tlb_1_resp_bits_s2_entry_tag[15] && w_s1_io_tlb_1_resp_bits_s2_entry_tag[15])) begin cov_fail++; $display("[COV] L2TLBWrapper.io_tlb_1_resp_bits_s2_entry_tag[15] 未见过 0 和 1"); end
    if (!(w_s0_io_tlb_1_resp_bits_s2_entry_tag[16] && w_s1_io_tlb_1_resp_bits_s2_entry_tag[16])) begin cov_fail++; $display("[COV] L2TLBWrapper.io_tlb_1_resp_bits_s2_entry_tag[16] 未见过 0 和 1"); end
    if (!(w_s0_io_tlb_1_resp_bits_s2_entry_tag[17] && w_s1_io_tlb_1_resp_bits_s2_entry_tag[17])) begin cov_fail++; $display("[COV] L2TLBWrapper.io_tlb_1_resp_bits_s2_entry_tag[17] 未见过 0 和 1"); end
    if (!(w_s0_io_tlb_1_resp_bits_s2_entry_tag[18] && w_s1_io_tlb_1_resp_bits_s2_entry_tag[18])) begin cov_fail++; $display("[COV] L2TLBWrapper.io_tlb_1_resp_bits_s2_entry_tag[18] 未见过 0 和 1"); end
    if (!(w_s0_io_tlb_1_resp_bits_s2_entry_tag[19] && w_s1_io_tlb_1_resp_bits_s2_entry_tag[19])) begin cov_fail++; $display("[COV] L2TLBWrapper.io_tlb_1_resp_bits_s2_entry_tag[19] 未见过 0 和 1"); end
    if (!(w_s0_io_tlb_1_resp_bits_s2_entry_tag[20] && w_s1_io_tlb_1_resp_bits_s2_entry_tag[20])) begin cov_fail++; $display("[COV] L2TLBWrapper.io_tlb_1_resp_bits_s2_entry_tag[20] 未见过 0 和 1"); end
    if (!(w_s0_io_tlb_1_resp_bits_s2_entry_tag[21] && w_s1_io_tlb_1_resp_bits_s2_entry_tag[21])) begin cov_fail++; $display("[COV] L2TLBWrapper.io_tlb_1_resp_bits_s2_entry_tag[21] 未见过 0 和 1"); end
    if (!(w_s0_io_tlb_1_resp_bits_s2_entry_tag[22] && w_s1_io_tlb_1_resp_bits_s2_entry_tag[22])) begin cov_fail++; $display("[COV] L2TLBWrapper.io_tlb_1_resp_bits_s2_entry_tag[22] 未见过 0 和 1"); end
    if (!(w_s0_io_tlb_1_resp_bits_s2_entry_tag[23] && w_s1_io_tlb_1_resp_bits_s2_entry_tag[23])) begin cov_fail++; $display("[COV] L2TLBWrapper.io_tlb_1_resp_bits_s2_entry_tag[23] 未见过 0 和 1"); end
    if (!(w_s0_io_tlb_1_resp_bits_s2_entry_tag[24] && w_s1_io_tlb_1_resp_bits_s2_entry_tag[24])) begin cov_fail++; $display("[COV] L2TLBWrapper.io_tlb_1_resp_bits_s2_entry_tag[24] 未见过 0 和 1"); end
    if (!(w_s0_io_tlb_1_resp_bits_s2_entry_tag[25] && w_s1_io_tlb_1_resp_bits_s2_entry_tag[25])) begin cov_fail++; $display("[COV] L2TLBWrapper.io_tlb_1_resp_bits_s2_entry_tag[25] 未见过 0 和 1"); end
    if (!(w_s0_io_tlb_1_resp_bits_s2_entry_tag[26] && w_s1_io_tlb_1_resp_bits_s2_entry_tag[26])) begin cov_fail++; $display("[COV] L2TLBWrapper.io_tlb_1_resp_bits_s2_entry_tag[26] 未见过 0 和 1"); end
    if (!(w_s0_io_tlb_1_resp_bits_s2_entry_tag[27] && w_s1_io_tlb_1_resp_bits_s2_entry_tag[27])) begin cov_fail++; $display("[COV] L2TLBWrapper.io_tlb_1_resp_bits_s2_entry_tag[27] 未见过 0 和 1"); end
    if (!(w_s0_io_tlb_1_resp_bits_s2_entry_tag[28] && w_s1_io_tlb_1_resp_bits_s2_entry_tag[28])) begin cov_fail++; $display("[COV] L2TLBWrapper.io_tlb_1_resp_bits_s2_entry_tag[28] 未见过 0 和 1"); end
    if (!(w_s0_io_tlb_1_resp_bits_s2_entry_tag[29] && w_s1_io_tlb_1_resp_bits_s2_entry_tag[29])) begin cov_fail++; $display("[COV] L2TLBWrapper.io_tlb_1_resp_bits_s2_entry_tag[29] 未见过 0 和 1"); end
    if (!(w_s0_io_tlb_1_resp_bits_s2_entry_tag[30] && w_s1_io_tlb_1_resp_bits_s2_entry_tag[30])) begin cov_fail++; $display("[COV] L2TLBWrapper.io_tlb_1_resp_bits_s2_entry_tag[30] 未见过 0 和 1"); end
    if (!(w_s0_io_tlb_1_resp_bits_s2_entry_tag[31] && w_s1_io_tlb_1_resp_bits_s2_entry_tag[31])) begin cov_fail++; $display("[COV] L2TLBWrapper.io_tlb_1_resp_bits_s2_entry_tag[31] 未见过 0 和 1"); end
    if (!(w_s0_io_tlb_1_resp_bits_s2_entry_tag[32] && w_s1_io_tlb_1_resp_bits_s2_entry_tag[32])) begin cov_fail++; $display("[COV] L2TLBWrapper.io_tlb_1_resp_bits_s2_entry_tag[32] 未见过 0 和 1"); end
    if (!(w_s0_io_tlb_1_resp_bits_s2_entry_tag[33] && w_s1_io_tlb_1_resp_bits_s2_entry_tag[33])) begin cov_fail++; $display("[COV] L2TLBWrapper.io_tlb_1_resp_bits_s2_entry_tag[33] 未见过 0 和 1"); end
    if (!(w_s0_io_tlb_1_resp_bits_s2_entry_tag[34] && w_s1_io_tlb_1_resp_bits_s2_entry_tag[34])) begin cov_fail++; $display("[COV] L2TLBWrapper.io_tlb_1_resp_bits_s2_entry_tag[34] 未见过 0 和 1"); end
    if (!(w_s0_io_tlb_1_resp_bits_s2_entry_tag[35] && w_s1_io_tlb_1_resp_bits_s2_entry_tag[35])) begin cov_fail++; $display("[COV] L2TLBWrapper.io_tlb_1_resp_bits_s2_entry_tag[35] 未见过 0 和 1"); end
    if (!(w_s0_io_tlb_1_resp_bits_s2_entry_tag[36] && w_s1_io_tlb_1_resp_bits_s2_entry_tag[36])) begin cov_fail++; $display("[COV] L2TLBWrapper.io_tlb_1_resp_bits_s2_entry_tag[36] 未见过 0 和 1"); end
    if (!(w_s0_io_tlb_1_resp_bits_s2_entry_tag[37] && w_s1_io_tlb_1_resp_bits_s2_entry_tag[37])) begin cov_fail++; $display("[COV] L2TLBWrapper.io_tlb_1_resp_bits_s2_entry_tag[37] 未见过 0 和 1"); end
    if (!(w_s0_io_tlb_1_resp_bits_s2_entry_vmid[0] && w_s1_io_tlb_1_resp_bits_s2_entry_vmid[0])) begin cov_fail++; $display("[COV] L2TLBWrapper.io_tlb_1_resp_bits_s2_entry_vmid[0] 未见过 0 和 1"); end
    if (!(w_s0_io_tlb_1_resp_bits_s2_entry_vmid[1] && w_s1_io_tlb_1_resp_bits_s2_entry_vmid[1])) begin cov_fail++; $display("[COV] L2TLBWrapper.io_tlb_1_resp_bits_s2_entry_vmid[1] 未见过 0 和 1"); end
    if (!(w_s0_io_tlb_1_resp_bits_s2_entry_vmid[2] && w_s1_io_tlb_1_resp_bits_s2_entry_vmid[2])) begin cov_fail++; $display("[COV] L2TLBWrapper.io_tlb_1_resp_bits_s2_entry_vmid[2] 未见过 0 和 1"); end
    if (!(w_s0_io_tlb_1_resp_bits_s2_entry_vmid[3] && w_s1_io_tlb_1_resp_bits_s2_entry_vmid[3])) begin cov_fail++; $display("[COV] L2TLBWrapper.io_tlb_1_resp_bits_s2_entry_vmid[3] 未见过 0 和 1"); end
    if (!(w_s0_io_tlb_1_resp_bits_s2_entry_vmid[4] && w_s1_io_tlb_1_resp_bits_s2_entry_vmid[4])) begin cov_fail++; $display("[COV] L2TLBWrapper.io_tlb_1_resp_bits_s2_entry_vmid[4] 未见过 0 和 1"); end
    if (!(w_s0_io_tlb_1_resp_bits_s2_entry_vmid[5] && w_s1_io_tlb_1_resp_bits_s2_entry_vmid[5])) begin cov_fail++; $display("[COV] L2TLBWrapper.io_tlb_1_resp_bits_s2_entry_vmid[5] 未见过 0 和 1"); end
    if (!(w_s0_io_tlb_1_resp_bits_s2_entry_vmid[6] && w_s1_io_tlb_1_resp_bits_s2_entry_vmid[6])) begin cov_fail++; $display("[COV] L2TLBWrapper.io_tlb_1_resp_bits_s2_entry_vmid[6] 未见过 0 和 1"); end
    if (!(w_s0_io_tlb_1_resp_bits_s2_entry_vmid[7] && w_s1_io_tlb_1_resp_bits_s2_entry_vmid[7])) begin cov_fail++; $display("[COV] L2TLBWrapper.io_tlb_1_resp_bits_s2_entry_vmid[7] 未见过 0 和 1"); end
    if (!(w_s0_io_tlb_1_resp_bits_s2_entry_vmid[8] && w_s1_io_tlb_1_resp_bits_s2_entry_vmid[8])) begin cov_fail++; $display("[COV] L2TLBWrapper.io_tlb_1_resp_bits_s2_entry_vmid[8] 未见过 0 和 1"); end
    if (!(w_s0_io_tlb_1_resp_bits_s2_entry_vmid[9] && w_s1_io_tlb_1_resp_bits_s2_entry_vmid[9])) begin cov_fail++; $display("[COV] L2TLBWrapper.io_tlb_1_resp_bits_s2_entry_vmid[9] 未见过 0 和 1"); end
    if (!(w_s0_io_tlb_1_resp_bits_s2_entry_vmid[10] && w_s1_io_tlb_1_resp_bits_s2_entry_vmid[10])) begin cov_fail++; $display("[COV] L2TLBWrapper.io_tlb_1_resp_bits_s2_entry_vmid[10] 未见过 0 和 1"); end
    if (!(w_s0_io_tlb_1_resp_bits_s2_entry_vmid[11] && w_s1_io_tlb_1_resp_bits_s2_entry_vmid[11])) begin cov_fail++; $display("[COV] L2TLBWrapper.io_tlb_1_resp_bits_s2_entry_vmid[11] 未见过 0 和 1"); end
    if (!(w_s0_io_tlb_1_resp_bits_s2_entry_vmid[12] && w_s1_io_tlb_1_resp_bits_s2_entry_vmid[12])) begin cov_fail++; $display("[COV] L2TLBWrapper.io_tlb_1_resp_bits_s2_entry_vmid[12] 未见过 0 和 1"); end
    if (!(w_s0_io_tlb_1_resp_bits_s2_entry_vmid[13] && w_s1_io_tlb_1_resp_bits_s2_entry_vmid[13])) begin cov_fail++; $display("[COV] L2TLBWrapper.io_tlb_1_resp_bits_s2_entry_vmid[13] 未见过 0 和 1"); end
    if (!(w_s0_io_tlb_1_resp_bits_s2_entry_n && w_s1_io_tlb_1_resp_bits_s2_entry_n)) begin cov_fail++; $display("[COV] L2TLBWrapper.io_tlb_1_resp_bits_s2_entry_n 未见过 0 和 1"); end
    if (!(w_s0_io_tlb_1_resp_bits_s2_entry_pbmt[0] && w_s1_io_tlb_1_resp_bits_s2_entry_pbmt[0])) begin cov_fail++; $display("[COV] L2TLBWrapper.io_tlb_1_resp_bits_s2_entry_pbmt[0] 未见过 0 和 1"); end
    if (!(w_s0_io_tlb_1_resp_bits_s2_entry_pbmt[1] && w_s1_io_tlb_1_resp_bits_s2_entry_pbmt[1])) begin cov_fail++; $display("[COV] L2TLBWrapper.io_tlb_1_resp_bits_s2_entry_pbmt[1] 未见过 0 和 1"); end
    if (!(w_s0_io_tlb_1_resp_bits_s2_entry_ppn[0] && w_s1_io_tlb_1_resp_bits_s2_entry_ppn[0])) begin cov_fail++; $display("[COV] L2TLBWrapper.io_tlb_1_resp_bits_s2_entry_ppn[0] 未见过 0 和 1"); end
    if (!(w_s0_io_tlb_1_resp_bits_s2_entry_ppn[1] && w_s1_io_tlb_1_resp_bits_s2_entry_ppn[1])) begin cov_fail++; $display("[COV] L2TLBWrapper.io_tlb_1_resp_bits_s2_entry_ppn[1] 未见过 0 和 1"); end
    if (!(w_s0_io_tlb_1_resp_bits_s2_entry_ppn[2] && w_s1_io_tlb_1_resp_bits_s2_entry_ppn[2])) begin cov_fail++; $display("[COV] L2TLBWrapper.io_tlb_1_resp_bits_s2_entry_ppn[2] 未见过 0 和 1"); end
    if (!(w_s0_io_tlb_1_resp_bits_s2_entry_ppn[3] && w_s1_io_tlb_1_resp_bits_s2_entry_ppn[3])) begin cov_fail++; $display("[COV] L2TLBWrapper.io_tlb_1_resp_bits_s2_entry_ppn[3] 未见过 0 和 1"); end
    if (!(w_s0_io_tlb_1_resp_bits_s2_entry_ppn[4] && w_s1_io_tlb_1_resp_bits_s2_entry_ppn[4])) begin cov_fail++; $display("[COV] L2TLBWrapper.io_tlb_1_resp_bits_s2_entry_ppn[4] 未见过 0 和 1"); end
    if (!(w_s0_io_tlb_1_resp_bits_s2_entry_ppn[5] && w_s1_io_tlb_1_resp_bits_s2_entry_ppn[5])) begin cov_fail++; $display("[COV] L2TLBWrapper.io_tlb_1_resp_bits_s2_entry_ppn[5] 未见过 0 和 1"); end
    if (!(w_s0_io_tlb_1_resp_bits_s2_entry_ppn[6] && w_s1_io_tlb_1_resp_bits_s2_entry_ppn[6])) begin cov_fail++; $display("[COV] L2TLBWrapper.io_tlb_1_resp_bits_s2_entry_ppn[6] 未见过 0 和 1"); end
    if (!(w_s0_io_tlb_1_resp_bits_s2_entry_ppn[7] && w_s1_io_tlb_1_resp_bits_s2_entry_ppn[7])) begin cov_fail++; $display("[COV] L2TLBWrapper.io_tlb_1_resp_bits_s2_entry_ppn[7] 未见过 0 和 1"); end
    if (!(w_s0_io_tlb_1_resp_bits_s2_entry_ppn[8] && w_s1_io_tlb_1_resp_bits_s2_entry_ppn[8])) begin cov_fail++; $display("[COV] L2TLBWrapper.io_tlb_1_resp_bits_s2_entry_ppn[8] 未见过 0 和 1"); end
    if (!(w_s0_io_tlb_1_resp_bits_s2_entry_ppn[9] && w_s1_io_tlb_1_resp_bits_s2_entry_ppn[9])) begin cov_fail++; $display("[COV] L2TLBWrapper.io_tlb_1_resp_bits_s2_entry_ppn[9] 未见过 0 和 1"); end
    if (!(w_s0_io_tlb_1_resp_bits_s2_entry_ppn[10] && w_s1_io_tlb_1_resp_bits_s2_entry_ppn[10])) begin cov_fail++; $display("[COV] L2TLBWrapper.io_tlb_1_resp_bits_s2_entry_ppn[10] 未见过 0 和 1"); end
    if (!(w_s0_io_tlb_1_resp_bits_s2_entry_ppn[11] && w_s1_io_tlb_1_resp_bits_s2_entry_ppn[11])) begin cov_fail++; $display("[COV] L2TLBWrapper.io_tlb_1_resp_bits_s2_entry_ppn[11] 未见过 0 和 1"); end
    if (!(w_s0_io_tlb_1_resp_bits_s2_entry_ppn[12] && w_s1_io_tlb_1_resp_bits_s2_entry_ppn[12])) begin cov_fail++; $display("[COV] L2TLBWrapper.io_tlb_1_resp_bits_s2_entry_ppn[12] 未见过 0 和 1"); end
    if (!(w_s0_io_tlb_1_resp_bits_s2_entry_ppn[13] && w_s1_io_tlb_1_resp_bits_s2_entry_ppn[13])) begin cov_fail++; $display("[COV] L2TLBWrapper.io_tlb_1_resp_bits_s2_entry_ppn[13] 未见过 0 和 1"); end
    if (!(w_s0_io_tlb_1_resp_bits_s2_entry_ppn[14] && w_s1_io_tlb_1_resp_bits_s2_entry_ppn[14])) begin cov_fail++; $display("[COV] L2TLBWrapper.io_tlb_1_resp_bits_s2_entry_ppn[14] 未见过 0 和 1"); end
    if (!(w_s0_io_tlb_1_resp_bits_s2_entry_ppn[15] && w_s1_io_tlb_1_resp_bits_s2_entry_ppn[15])) begin cov_fail++; $display("[COV] L2TLBWrapper.io_tlb_1_resp_bits_s2_entry_ppn[15] 未见过 0 和 1"); end
    if (!(w_s0_io_tlb_1_resp_bits_s2_entry_ppn[16] && w_s1_io_tlb_1_resp_bits_s2_entry_ppn[16])) begin cov_fail++; $display("[COV] L2TLBWrapper.io_tlb_1_resp_bits_s2_entry_ppn[16] 未见过 0 和 1"); end
    if (!(w_s0_io_tlb_1_resp_bits_s2_entry_ppn[17] && w_s1_io_tlb_1_resp_bits_s2_entry_ppn[17])) begin cov_fail++; $display("[COV] L2TLBWrapper.io_tlb_1_resp_bits_s2_entry_ppn[17] 未见过 0 和 1"); end
    if (!(w_s0_io_tlb_1_resp_bits_s2_entry_ppn[18] && w_s1_io_tlb_1_resp_bits_s2_entry_ppn[18])) begin cov_fail++; $display("[COV] L2TLBWrapper.io_tlb_1_resp_bits_s2_entry_ppn[18] 未见过 0 和 1"); end
    if (!(w_s0_io_tlb_1_resp_bits_s2_entry_ppn[19] && w_s1_io_tlb_1_resp_bits_s2_entry_ppn[19])) begin cov_fail++; $display("[COV] L2TLBWrapper.io_tlb_1_resp_bits_s2_entry_ppn[19] 未见过 0 和 1"); end
    if (!(w_s0_io_tlb_1_resp_bits_s2_entry_ppn[20] && w_s1_io_tlb_1_resp_bits_s2_entry_ppn[20])) begin cov_fail++; $display("[COV] L2TLBWrapper.io_tlb_1_resp_bits_s2_entry_ppn[20] 未见过 0 和 1"); end
    if (!(w_s0_io_tlb_1_resp_bits_s2_entry_ppn[21] && w_s1_io_tlb_1_resp_bits_s2_entry_ppn[21])) begin cov_fail++; $display("[COV] L2TLBWrapper.io_tlb_1_resp_bits_s2_entry_ppn[21] 未见过 0 和 1"); end
    if (!(w_s0_io_tlb_1_resp_bits_s2_entry_ppn[22] && w_s1_io_tlb_1_resp_bits_s2_entry_ppn[22])) begin cov_fail++; $display("[COV] L2TLBWrapper.io_tlb_1_resp_bits_s2_entry_ppn[22] 未见过 0 和 1"); end
    if (!(w_s0_io_tlb_1_resp_bits_s2_entry_ppn[23] && w_s1_io_tlb_1_resp_bits_s2_entry_ppn[23])) begin cov_fail++; $display("[COV] L2TLBWrapper.io_tlb_1_resp_bits_s2_entry_ppn[23] 未见过 0 和 1"); end
    if (!(w_s0_io_tlb_1_resp_bits_s2_entry_ppn[24] && w_s1_io_tlb_1_resp_bits_s2_entry_ppn[24])) begin cov_fail++; $display("[COV] L2TLBWrapper.io_tlb_1_resp_bits_s2_entry_ppn[24] 未见过 0 和 1"); end
    if (!(w_s0_io_tlb_1_resp_bits_s2_entry_ppn[25] && w_s1_io_tlb_1_resp_bits_s2_entry_ppn[25])) begin cov_fail++; $display("[COV] L2TLBWrapper.io_tlb_1_resp_bits_s2_entry_ppn[25] 未见过 0 和 1"); end
    if (!(w_s0_io_tlb_1_resp_bits_s2_entry_ppn[26] && w_s1_io_tlb_1_resp_bits_s2_entry_ppn[26])) begin cov_fail++; $display("[COV] L2TLBWrapper.io_tlb_1_resp_bits_s2_entry_ppn[26] 未见过 0 和 1"); end
    if (!(w_s0_io_tlb_1_resp_bits_s2_entry_ppn[27] && w_s1_io_tlb_1_resp_bits_s2_entry_ppn[27])) begin cov_fail++; $display("[COV] L2TLBWrapper.io_tlb_1_resp_bits_s2_entry_ppn[27] 未见过 0 和 1"); end
    if (!(w_s0_io_tlb_1_resp_bits_s2_entry_ppn[28] && w_s1_io_tlb_1_resp_bits_s2_entry_ppn[28])) begin cov_fail++; $display("[COV] L2TLBWrapper.io_tlb_1_resp_bits_s2_entry_ppn[28] 未见过 0 和 1"); end
    if (!(w_s0_io_tlb_1_resp_bits_s2_entry_ppn[29] && w_s1_io_tlb_1_resp_bits_s2_entry_ppn[29])) begin cov_fail++; $display("[COV] L2TLBWrapper.io_tlb_1_resp_bits_s2_entry_ppn[29] 未见过 0 和 1"); end
    if (!(w_s0_io_tlb_1_resp_bits_s2_entry_ppn[30] && w_s1_io_tlb_1_resp_bits_s2_entry_ppn[30])) begin cov_fail++; $display("[COV] L2TLBWrapper.io_tlb_1_resp_bits_s2_entry_ppn[30] 未见过 0 和 1"); end
    if (!(w_s0_io_tlb_1_resp_bits_s2_entry_ppn[31] && w_s1_io_tlb_1_resp_bits_s2_entry_ppn[31])) begin cov_fail++; $display("[COV] L2TLBWrapper.io_tlb_1_resp_bits_s2_entry_ppn[31] 未见过 0 和 1"); end
    if (!(w_s0_io_tlb_1_resp_bits_s2_entry_ppn[32] && w_s1_io_tlb_1_resp_bits_s2_entry_ppn[32])) begin cov_fail++; $display("[COV] L2TLBWrapper.io_tlb_1_resp_bits_s2_entry_ppn[32] 未见过 0 和 1"); end
    if (!(w_s0_io_tlb_1_resp_bits_s2_entry_ppn[33] && w_s1_io_tlb_1_resp_bits_s2_entry_ppn[33])) begin cov_fail++; $display("[COV] L2TLBWrapper.io_tlb_1_resp_bits_s2_entry_ppn[33] 未见过 0 和 1"); end
    if (!(w_s0_io_tlb_1_resp_bits_s2_entry_ppn[34] && w_s1_io_tlb_1_resp_bits_s2_entry_ppn[34])) begin cov_fail++; $display("[COV] L2TLBWrapper.io_tlb_1_resp_bits_s2_entry_ppn[34] 未见过 0 和 1"); end
    if (!(w_s0_io_tlb_1_resp_bits_s2_entry_ppn[35] && w_s1_io_tlb_1_resp_bits_s2_entry_ppn[35])) begin cov_fail++; $display("[COV] L2TLBWrapper.io_tlb_1_resp_bits_s2_entry_ppn[35] 未见过 0 和 1"); end
    if (!(w_s0_io_tlb_1_resp_bits_s2_entry_ppn[36] && w_s1_io_tlb_1_resp_bits_s2_entry_ppn[36])) begin cov_fail++; $display("[COV] L2TLBWrapper.io_tlb_1_resp_bits_s2_entry_ppn[36] 未见过 0 和 1"); end
    if (!(w_s0_io_tlb_1_resp_bits_s2_entry_ppn[37] && w_s1_io_tlb_1_resp_bits_s2_entry_ppn[37])) begin cov_fail++; $display("[COV] L2TLBWrapper.io_tlb_1_resp_bits_s2_entry_ppn[37] 未见过 0 和 1"); end
    if (!(w_s0_io_tlb_1_resp_bits_s2_entry_perm_d && w_s1_io_tlb_1_resp_bits_s2_entry_perm_d)) begin cov_fail++; $display("[COV] L2TLBWrapper.io_tlb_1_resp_bits_s2_entry_perm_d 未见过 0 和 1"); end
    if (!(w_s0_io_tlb_1_resp_bits_s2_entry_perm_a && w_s1_io_tlb_1_resp_bits_s2_entry_perm_a)) begin cov_fail++; $display("[COV] L2TLBWrapper.io_tlb_1_resp_bits_s2_entry_perm_a 未见过 0 和 1"); end
    if (!(w_s0_io_tlb_1_resp_bits_s2_entry_perm_g && w_s1_io_tlb_1_resp_bits_s2_entry_perm_g)) begin cov_fail++; $display("[COV] L2TLBWrapper.io_tlb_1_resp_bits_s2_entry_perm_g 未见过 0 和 1"); end
    if (!(w_s0_io_tlb_1_resp_bits_s2_entry_perm_u && w_s1_io_tlb_1_resp_bits_s2_entry_perm_u)) begin cov_fail++; $display("[COV] L2TLBWrapper.io_tlb_1_resp_bits_s2_entry_perm_u 未见过 0 和 1"); end
    if (!(w_s0_io_tlb_1_resp_bits_s2_entry_perm_x && w_s1_io_tlb_1_resp_bits_s2_entry_perm_x)) begin cov_fail++; $display("[COV] L2TLBWrapper.io_tlb_1_resp_bits_s2_entry_perm_x 未见过 0 和 1"); end
    if (!(w_s0_io_tlb_1_resp_bits_s2_entry_perm_w && w_s1_io_tlb_1_resp_bits_s2_entry_perm_w)) begin cov_fail++; $display("[COV] L2TLBWrapper.io_tlb_1_resp_bits_s2_entry_perm_w 未见过 0 和 1"); end
    if (!(w_s0_io_tlb_1_resp_bits_s2_entry_perm_r && w_s1_io_tlb_1_resp_bits_s2_entry_perm_r)) begin cov_fail++; $display("[COV] L2TLBWrapper.io_tlb_1_resp_bits_s2_entry_perm_r 未见过 0 和 1"); end
    if (!(w_s0_io_tlb_1_resp_bits_s2_entry_level[0] && w_s1_io_tlb_1_resp_bits_s2_entry_level[0])) begin cov_fail++; $display("[COV] L2TLBWrapper.io_tlb_1_resp_bits_s2_entry_level[0] 未见过 0 和 1"); end
    if (!(w_s0_io_tlb_1_resp_bits_s2_entry_level[1] && w_s1_io_tlb_1_resp_bits_s2_entry_level[1])) begin cov_fail++; $display("[COV] L2TLBWrapper.io_tlb_1_resp_bits_s2_entry_level[1] 未见过 0 和 1"); end
    if (!(w_s0_io_tlb_1_resp_bits_s2_gpf && w_s1_io_tlb_1_resp_bits_s2_gpf)) begin cov_fail++; $display("[COV] L2TLBWrapper.io_tlb_1_resp_bits_s2_gpf 未见过 0 和 1"); end
    if (!(w_s0_io_tlb_1_resp_bits_s2_gaf && w_s1_io_tlb_1_resp_bits_s2_gaf)) begin cov_fail++; $display("[COV] L2TLBWrapper.io_tlb_1_resp_bits_s2_gaf 未见过 0 和 1"); end
    if (!(w_s0_io_wfi_wfiSafe && w_s1_io_wfi_wfiSafe)) begin cov_fail++; $display("[COV] L2TLBWrapper.io_wfi_wfiSafe 未见过 0 和 1"); end
    if (!(w_s0_io_perf_0_value[0] && w_s1_io_perf_0_value[0])) begin cov_fail++; $display("[COV] L2TLBWrapper.io_perf_0_value[0] 未见过 0 和 1"); end
    if (!(w_s0_io_perf_0_value[1] && w_s1_io_perf_0_value[1])) begin cov_fail++; $display("[COV] L2TLBWrapper.io_perf_0_value[1] 未见过 0 和 1"); end
    if (!(w_s0_io_perf_0_value[2] && w_s1_io_perf_0_value[2])) begin cov_fail++; $display("[COV] L2TLBWrapper.io_perf_0_value[2] 未见过 0 和 1"); end
    if (!(w_s0_io_perf_0_value[3] && w_s1_io_perf_0_value[3])) begin cov_fail++; $display("[COV] L2TLBWrapper.io_perf_0_value[3] 未见过 0 和 1"); end
    if (!(w_s0_io_perf_0_value[4] && w_s1_io_perf_0_value[4])) begin cov_fail++; $display("[COV] L2TLBWrapper.io_perf_0_value[4] 未见过 0 和 1"); end
    if (!(w_s0_io_perf_0_value[5] && w_s1_io_perf_0_value[5])) begin cov_fail++; $display("[COV] L2TLBWrapper.io_perf_0_value[5] 未见过 0 和 1"); end
    if (!(w_s0_io_perf_1_value[0] && w_s1_io_perf_1_value[0])) begin cov_fail++; $display("[COV] L2TLBWrapper.io_perf_1_value[0] 未见过 0 和 1"); end
    if (!(w_s0_io_perf_1_value[1] && w_s1_io_perf_1_value[1])) begin cov_fail++; $display("[COV] L2TLBWrapper.io_perf_1_value[1] 未见过 0 和 1"); end
    if (!(w_s0_io_perf_1_value[2] && w_s1_io_perf_1_value[2])) begin cov_fail++; $display("[COV] L2TLBWrapper.io_perf_1_value[2] 未见过 0 和 1"); end
    if (!(w_s0_io_perf_1_value[3] && w_s1_io_perf_1_value[3])) begin cov_fail++; $display("[COV] L2TLBWrapper.io_perf_1_value[3] 未见过 0 和 1"); end
    if (!(w_s0_io_perf_1_value[4] && w_s1_io_perf_1_value[4])) begin cov_fail++; $display("[COV] L2TLBWrapper.io_perf_1_value[4] 未见过 0 和 1"); end
    if (!(w_s0_io_perf_1_value[5] && w_s1_io_perf_1_value[5])) begin cov_fail++; $display("[COV] L2TLBWrapper.io_perf_1_value[5] 未见过 0 和 1"); end
    if (!(w_s0_io_perf_2_value[0] && w_s1_io_perf_2_value[0])) begin cov_fail++; $display("[COV] L2TLBWrapper.io_perf_2_value[0] 未见过 0 和 1"); end
    if (!(w_s0_io_perf_2_value[1] && w_s1_io_perf_2_value[1])) begin cov_fail++; $display("[COV] L2TLBWrapper.io_perf_2_value[1] 未见过 0 和 1"); end
    if (!(w_s0_io_perf_2_value[2] && w_s1_io_perf_2_value[2])) begin cov_fail++; $display("[COV] L2TLBWrapper.io_perf_2_value[2] 未见过 0 和 1"); end
    if (!(w_s0_io_perf_2_value[3] && w_s1_io_perf_2_value[3])) begin cov_fail++; $display("[COV] L2TLBWrapper.io_perf_2_value[3] 未见过 0 和 1"); end
    if (!(w_s0_io_perf_2_value[4] && w_s1_io_perf_2_value[4])) begin cov_fail++; $display("[COV] L2TLBWrapper.io_perf_2_value[4] 未见过 0 和 1"); end
    if (!(w_s0_io_perf_2_value[5] && w_s1_io_perf_2_value[5])) begin cov_fail++; $display("[COV] L2TLBWrapper.io_perf_2_value[5] 未见过 0 和 1"); end
    if (!(w_s0_io_perf_3_value[0] && w_s1_io_perf_3_value[0])) begin cov_fail++; $display("[COV] L2TLBWrapper.io_perf_3_value[0] 未见过 0 和 1"); end
    if (!(w_s0_io_perf_3_value[1] && w_s1_io_perf_3_value[1])) begin cov_fail++; $display("[COV] L2TLBWrapper.io_perf_3_value[1] 未见过 0 和 1"); end
    if (!(w_s0_io_perf_3_value[2] && w_s1_io_perf_3_value[2])) begin cov_fail++; $display("[COV] L2TLBWrapper.io_perf_3_value[2] 未见过 0 和 1"); end
    if (!(w_s0_io_perf_3_value[3] && w_s1_io_perf_3_value[3])) begin cov_fail++; $display("[COV] L2TLBWrapper.io_perf_3_value[3] 未见过 0 和 1"); end
    if (!(w_s0_io_perf_3_value[4] && w_s1_io_perf_3_value[4])) begin cov_fail++; $display("[COV] L2TLBWrapper.io_perf_3_value[4] 未见过 0 和 1"); end
    if (!(w_s0_io_perf_3_value[5] && w_s1_io_perf_3_value[5])) begin cov_fail++; $display("[COV] L2TLBWrapper.io_perf_3_value[5] 未见过 0 和 1"); end
    if (!(w_s0_io_perf_4_value[0] && w_s1_io_perf_4_value[0])) begin cov_fail++; $display("[COV] L2TLBWrapper.io_perf_4_value[0] 未见过 0 和 1"); end
    if (!(w_s0_io_perf_4_value[1] && w_s1_io_perf_4_value[1])) begin cov_fail++; $display("[COV] L2TLBWrapper.io_perf_4_value[1] 未见过 0 和 1"); end
    if (!(w_s0_io_perf_4_value[2] && w_s1_io_perf_4_value[2])) begin cov_fail++; $display("[COV] L2TLBWrapper.io_perf_4_value[2] 未见过 0 和 1"); end
    if (!(w_s0_io_perf_4_value[3] && w_s1_io_perf_4_value[3])) begin cov_fail++; $display("[COV] L2TLBWrapper.io_perf_4_value[3] 未见过 0 和 1"); end
    if (!(w_s0_io_perf_4_value[4] && w_s1_io_perf_4_value[4])) begin cov_fail++; $display("[COV] L2TLBWrapper.io_perf_4_value[4] 未见过 0 和 1"); end
    if (!(w_s0_io_perf_4_value[5] && w_s1_io_perf_4_value[5])) begin cov_fail++; $display("[COV] L2TLBWrapper.io_perf_4_value[5] 未见过 0 和 1"); end
    if (!(w_s0_io_perf_5_value[0] && w_s1_io_perf_5_value[0])) begin cov_fail++; $display("[COV] L2TLBWrapper.io_perf_5_value[0] 未见过 0 和 1"); end
    if (!(w_s0_io_perf_5_value[1] && w_s1_io_perf_5_value[1])) begin cov_fail++; $display("[COV] L2TLBWrapper.io_perf_5_value[1] 未见过 0 和 1"); end
    if (!(w_s0_io_perf_5_value[2] && w_s1_io_perf_5_value[2])) begin cov_fail++; $display("[COV] L2TLBWrapper.io_perf_5_value[2] 未见过 0 和 1"); end
    if (!(w_s0_io_perf_5_value[3] && w_s1_io_perf_5_value[3])) begin cov_fail++; $display("[COV] L2TLBWrapper.io_perf_5_value[3] 未见过 0 和 1"); end
    if (!(w_s0_io_perf_5_value[4] && w_s1_io_perf_5_value[4])) begin cov_fail++; $display("[COV] L2TLBWrapper.io_perf_5_value[4] 未见过 0 和 1"); end
    if (!(w_s0_io_perf_5_value[5] && w_s1_io_perf_5_value[5])) begin cov_fail++; $display("[COV] L2TLBWrapper.io_perf_5_value[5] 未见过 0 和 1"); end
    if (!(w_s0_io_perf_6_value[0] && w_s1_io_perf_6_value[0])) begin cov_fail++; $display("[COV] L2TLBWrapper.io_perf_6_value[0] 未见过 0 和 1"); end
    if (!(w_s0_io_perf_6_value[1] && w_s1_io_perf_6_value[1])) begin cov_fail++; $display("[COV] L2TLBWrapper.io_perf_6_value[1] 未见过 0 和 1"); end
    if (!(w_s0_io_perf_6_value[2] && w_s1_io_perf_6_value[2])) begin cov_fail++; $display("[COV] L2TLBWrapper.io_perf_6_value[2] 未见过 0 和 1"); end
    if (!(w_s0_io_perf_6_value[3] && w_s1_io_perf_6_value[3])) begin cov_fail++; $display("[COV] L2TLBWrapper.io_perf_6_value[3] 未见过 0 和 1"); end
    if (!(w_s0_io_perf_6_value[4] && w_s1_io_perf_6_value[4])) begin cov_fail++; $display("[COV] L2TLBWrapper.io_perf_6_value[4] 未见过 0 和 1"); end
    if (!(w_s0_io_perf_6_value[5] && w_s1_io_perf_6_value[5])) begin cov_fail++; $display("[COV] L2TLBWrapper.io_perf_6_value[5] 未见过 0 和 1"); end
    if (!(w_s0_io_perf_7_value[0] && w_s1_io_perf_7_value[0])) begin cov_fail++; $display("[COV] L2TLBWrapper.io_perf_7_value[0] 未见过 0 和 1"); end
    if (!(w_s0_io_perf_7_value[1] && w_s1_io_perf_7_value[1])) begin cov_fail++; $display("[COV] L2TLBWrapper.io_perf_7_value[1] 未见过 0 和 1"); end
    if (!(w_s0_io_perf_7_value[2] && w_s1_io_perf_7_value[2])) begin cov_fail++; $display("[COV] L2TLBWrapper.io_perf_7_value[2] 未见过 0 和 1"); end
    if (!(w_s0_io_perf_7_value[3] && w_s1_io_perf_7_value[3])) begin cov_fail++; $display("[COV] L2TLBWrapper.io_perf_7_value[3] 未见过 0 和 1"); end
    if (!(w_s0_io_perf_7_value[4] && w_s1_io_perf_7_value[4])) begin cov_fail++; $display("[COV] L2TLBWrapper.io_perf_7_value[4] 未见过 0 和 1"); end
    if (!(w_s0_io_perf_7_value[5] && w_s1_io_perf_7_value[5])) begin cov_fail++; $display("[COV] L2TLBWrapper.io_perf_7_value[5] 未见过 0 和 1"); end
    if (!(w_s0_io_perf_8_value[0] && w_s1_io_perf_8_value[0])) begin cov_fail++; $display("[COV] L2TLBWrapper.io_perf_8_value[0] 未见过 0 和 1"); end
    if (!(w_s0_io_perf_8_value[1] && w_s1_io_perf_8_value[1])) begin cov_fail++; $display("[COV] L2TLBWrapper.io_perf_8_value[1] 未见过 0 和 1"); end
    if (!(w_s0_io_perf_8_value[2] && w_s1_io_perf_8_value[2])) begin cov_fail++; $display("[COV] L2TLBWrapper.io_perf_8_value[2] 未见过 0 和 1"); end
    if (!(w_s0_io_perf_8_value[3] && w_s1_io_perf_8_value[3])) begin cov_fail++; $display("[COV] L2TLBWrapper.io_perf_8_value[3] 未见过 0 和 1"); end
    if (!(w_s0_io_perf_8_value[4] && w_s1_io_perf_8_value[4])) begin cov_fail++; $display("[COV] L2TLBWrapper.io_perf_8_value[4] 未见过 0 和 1"); end
    if (!(w_s0_io_perf_8_value[5] && w_s1_io_perf_8_value[5])) begin cov_fail++; $display("[COV] L2TLBWrapper.io_perf_8_value[5] 未见过 0 和 1"); end
    if (!(w_s0_io_perf_9_value[0] && w_s1_io_perf_9_value[0])) begin cov_fail++; $display("[COV] L2TLBWrapper.io_perf_9_value[0] 未见过 0 和 1"); end
    if (!(w_s0_io_perf_9_value[1] && w_s1_io_perf_9_value[1])) begin cov_fail++; $display("[COV] L2TLBWrapper.io_perf_9_value[1] 未见过 0 和 1"); end
    if (!(w_s0_io_perf_9_value[2] && w_s1_io_perf_9_value[2])) begin cov_fail++; $display("[COV] L2TLBWrapper.io_perf_9_value[2] 未见过 0 和 1"); end
    if (!(w_s0_io_perf_9_value[3] && w_s1_io_perf_9_value[3])) begin cov_fail++; $display("[COV] L2TLBWrapper.io_perf_9_value[3] 未见过 0 和 1"); end
    if (!(w_s0_io_perf_9_value[4] && w_s1_io_perf_9_value[4])) begin cov_fail++; $display("[COV] L2TLBWrapper.io_perf_9_value[4] 未见过 0 和 1"); end
    if (!(w_s0_io_perf_9_value[5] && w_s1_io_perf_9_value[5])) begin cov_fail++; $display("[COV] L2TLBWrapper.io_perf_9_value[5] 未见过 0 和 1"); end
    if (!(w_s0_io_perf_10_value[0] && w_s1_io_perf_10_value[0])) begin cov_fail++; $display("[COV] L2TLBWrapper.io_perf_10_value[0] 未见过 0 和 1"); end
    if (!(w_s0_io_perf_10_value[1] && w_s1_io_perf_10_value[1])) begin cov_fail++; $display("[COV] L2TLBWrapper.io_perf_10_value[1] 未见过 0 和 1"); end
    if (!(w_s0_io_perf_10_value[2] && w_s1_io_perf_10_value[2])) begin cov_fail++; $display("[COV] L2TLBWrapper.io_perf_10_value[2] 未见过 0 和 1"); end
    if (!(w_s0_io_perf_10_value[3] && w_s1_io_perf_10_value[3])) begin cov_fail++; $display("[COV] L2TLBWrapper.io_perf_10_value[3] 未见过 0 和 1"); end
    if (!(w_s0_io_perf_10_value[4] && w_s1_io_perf_10_value[4])) begin cov_fail++; $display("[COV] L2TLBWrapper.io_perf_10_value[4] 未见过 0 和 1"); end
    if (!(w_s0_io_perf_10_value[5] && w_s1_io_perf_10_value[5])) begin cov_fail++; $display("[COV] L2TLBWrapper.io_perf_10_value[5] 未见过 0 和 1"); end
    if (!(w_s0_io_perf_11_value[0] && w_s1_io_perf_11_value[0])) begin cov_fail++; $display("[COV] L2TLBWrapper.io_perf_11_value[0] 未见过 0 和 1"); end
    if (!(w_s0_io_perf_11_value[1] && w_s1_io_perf_11_value[1])) begin cov_fail++; $display("[COV] L2TLBWrapper.io_perf_11_value[1] 未见过 0 和 1"); end
    if (!(w_s0_io_perf_11_value[2] && w_s1_io_perf_11_value[2])) begin cov_fail++; $display("[COV] L2TLBWrapper.io_perf_11_value[2] 未见过 0 和 1"); end
    if (!(w_s0_io_perf_11_value[3] && w_s1_io_perf_11_value[3])) begin cov_fail++; $display("[COV] L2TLBWrapper.io_perf_11_value[3] 未见过 0 和 1"); end
    if (!(w_s0_io_perf_11_value[4] && w_s1_io_perf_11_value[4])) begin cov_fail++; $display("[COV] L2TLBWrapper.io_perf_11_value[4] 未见过 0 和 1"); end
    if (!(w_s0_io_perf_11_value[5] && w_s1_io_perf_11_value[5])) begin cov_fail++; $display("[COV] L2TLBWrapper.io_perf_11_value[5] 未见过 0 和 1"); end
    if (!(w_s0_io_perf_12_value[0] && w_s1_io_perf_12_value[0])) begin cov_fail++; $display("[COV] L2TLBWrapper.io_perf_12_value[0] 未见过 0 和 1"); end
    if (!(w_s0_io_perf_12_value[1] && w_s1_io_perf_12_value[1])) begin cov_fail++; $display("[COV] L2TLBWrapper.io_perf_12_value[1] 未见过 0 和 1"); end
    if (!(w_s0_io_perf_12_value[2] && w_s1_io_perf_12_value[2])) begin cov_fail++; $display("[COV] L2TLBWrapper.io_perf_12_value[2] 未见过 0 和 1"); end
    if (!(w_s0_io_perf_12_value[3] && w_s1_io_perf_12_value[3])) begin cov_fail++; $display("[COV] L2TLBWrapper.io_perf_12_value[3] 未见过 0 和 1"); end
    if (!(w_s0_io_perf_12_value[4] && w_s1_io_perf_12_value[4])) begin cov_fail++; $display("[COV] L2TLBWrapper.io_perf_12_value[4] 未见过 0 和 1"); end
    if (!(w_s0_io_perf_12_value[5] && w_s1_io_perf_12_value[5])) begin cov_fail++; $display("[COV] L2TLBWrapper.io_perf_12_value[5] 未见过 0 和 1"); end
    if (!(w_s0_io_perf_13_value[0] && w_s1_io_perf_13_value[0])) begin cov_fail++; $display("[COV] L2TLBWrapper.io_perf_13_value[0] 未见过 0 和 1"); end
    if (!(w_s0_io_perf_13_value[1] && w_s1_io_perf_13_value[1])) begin cov_fail++; $display("[COV] L2TLBWrapper.io_perf_13_value[1] 未见过 0 和 1"); end
    if (!(w_s0_io_perf_13_value[2] && w_s1_io_perf_13_value[2])) begin cov_fail++; $display("[COV] L2TLBWrapper.io_perf_13_value[2] 未见过 0 和 1"); end
    if (!(w_s0_io_perf_13_value[3] && w_s1_io_perf_13_value[3])) begin cov_fail++; $display("[COV] L2TLBWrapper.io_perf_13_value[3] 未见过 0 和 1"); end
    if (!(w_s0_io_perf_13_value[4] && w_s1_io_perf_13_value[4])) begin cov_fail++; $display("[COV] L2TLBWrapper.io_perf_13_value[4] 未见过 0 和 1"); end
    if (!(w_s0_io_perf_13_value[5] && w_s1_io_perf_13_value[5])) begin cov_fail++; $display("[COV] L2TLBWrapper.io_perf_13_value[5] 未见过 0 和 1"); end
    if (!(w_s0_io_perf_14_value[0] && w_s1_io_perf_14_value[0])) begin cov_fail++; $display("[COV] L2TLBWrapper.io_perf_14_value[0] 未见过 0 和 1"); end
    if (!(w_s0_io_perf_14_value[1] && w_s1_io_perf_14_value[1])) begin cov_fail++; $display("[COV] L2TLBWrapper.io_perf_14_value[1] 未见过 0 和 1"); end
    if (!(w_s0_io_perf_14_value[2] && w_s1_io_perf_14_value[2])) begin cov_fail++; $display("[COV] L2TLBWrapper.io_perf_14_value[2] 未见过 0 和 1"); end
    if (!(w_s0_io_perf_14_value[3] && w_s1_io_perf_14_value[3])) begin cov_fail++; $display("[COV] L2TLBWrapper.io_perf_14_value[3] 未见过 0 和 1"); end
    if (!(w_s0_io_perf_14_value[4] && w_s1_io_perf_14_value[4])) begin cov_fail++; $display("[COV] L2TLBWrapper.io_perf_14_value[4] 未见过 0 和 1"); end
    if (!(w_s0_io_perf_14_value[5] && w_s1_io_perf_14_value[5])) begin cov_fail++; $display("[COV] L2TLBWrapper.io_perf_14_value[5] 未见过 0 和 1"); end
    if (!(w_s0_io_perf_15_value[0] && w_s1_io_perf_15_value[0])) begin cov_fail++; $display("[COV] L2TLBWrapper.io_perf_15_value[0] 未见过 0 和 1"); end
    if (!(w_s0_io_perf_15_value[1] && w_s1_io_perf_15_value[1])) begin cov_fail++; $display("[COV] L2TLBWrapper.io_perf_15_value[1] 未见过 0 和 1"); end
    if (!(w_s0_io_perf_15_value[2] && w_s1_io_perf_15_value[2])) begin cov_fail++; $display("[COV] L2TLBWrapper.io_perf_15_value[2] 未见过 0 和 1"); end
    if (!(w_s0_io_perf_15_value[3] && w_s1_io_perf_15_value[3])) begin cov_fail++; $display("[COV] L2TLBWrapper.io_perf_15_value[3] 未见过 0 和 1"); end
    if (!(w_s0_io_perf_15_value[4] && w_s1_io_perf_15_value[4])) begin cov_fail++; $display("[COV] L2TLBWrapper.io_perf_15_value[4] 未见过 0 和 1"); end
    if (!(w_s0_io_perf_15_value[5] && w_s1_io_perf_15_value[5])) begin cov_fail++; $display("[COV] L2TLBWrapper.io_perf_15_value[5] 未见过 0 和 1"); end
    if (!(w_s0_io_perf_16_value[0] && w_s1_io_perf_16_value[0])) begin cov_fail++; $display("[COV] L2TLBWrapper.io_perf_16_value[0] 未见过 0 和 1"); end
    if (!(w_s0_io_perf_16_value[1] && w_s1_io_perf_16_value[1])) begin cov_fail++; $display("[COV] L2TLBWrapper.io_perf_16_value[1] 未见过 0 和 1"); end
    if (!(w_s0_io_perf_16_value[2] && w_s1_io_perf_16_value[2])) begin cov_fail++; $display("[COV] L2TLBWrapper.io_perf_16_value[2] 未见过 0 和 1"); end
    if (!(w_s0_io_perf_16_value[3] && w_s1_io_perf_16_value[3])) begin cov_fail++; $display("[COV] L2TLBWrapper.io_perf_16_value[3] 未见过 0 和 1"); end
    if (!(w_s0_io_perf_16_value[4] && w_s1_io_perf_16_value[4])) begin cov_fail++; $display("[COV] L2TLBWrapper.io_perf_16_value[4] 未见过 0 和 1"); end
    if (!(w_s0_io_perf_16_value[5] && w_s1_io_perf_16_value[5])) begin cov_fail++; $display("[COV] L2TLBWrapper.io_perf_16_value[5] 未见过 0 和 1"); end
    if (!(w_s0_io_perf_17_value[0] && w_s1_io_perf_17_value[0])) begin cov_fail++; $display("[COV] L2TLBWrapper.io_perf_17_value[0] 未见过 0 和 1"); end
    if (!(w_s0_io_perf_17_value[1] && w_s1_io_perf_17_value[1])) begin cov_fail++; $display("[COV] L2TLBWrapper.io_perf_17_value[1] 未见过 0 和 1"); end
    if (!(w_s0_io_perf_17_value[2] && w_s1_io_perf_17_value[2])) begin cov_fail++; $display("[COV] L2TLBWrapper.io_perf_17_value[2] 未见过 0 和 1"); end
    if (!(w_s0_io_perf_17_value[3] && w_s1_io_perf_17_value[3])) begin cov_fail++; $display("[COV] L2TLBWrapper.io_perf_17_value[3] 未见过 0 和 1"); end
    if (!(w_s0_io_perf_17_value[4] && w_s1_io_perf_17_value[4])) begin cov_fail++; $display("[COV] L2TLBWrapper.io_perf_17_value[4] 未见过 0 和 1"); end
    if (!(w_s0_io_perf_17_value[5] && w_s1_io_perf_17_value[5])) begin cov_fail++; $display("[COV] L2TLBWrapper.io_perf_17_value[5] 未见过 0 和 1"); end
    if (!(w_s0_io_perf_18_value[0] && w_s1_io_perf_18_value[0])) begin cov_fail++; $display("[COV] L2TLBWrapper.io_perf_18_value[0] 未见过 0 和 1"); end
    if (!(w_s0_io_perf_18_value[1] && w_s1_io_perf_18_value[1])) begin cov_fail++; $display("[COV] L2TLBWrapper.io_perf_18_value[1] 未见过 0 和 1"); end
    if (!(w_s0_io_perf_18_value[2] && w_s1_io_perf_18_value[2])) begin cov_fail++; $display("[COV] L2TLBWrapper.io_perf_18_value[2] 未见过 0 和 1"); end
    if (!(w_s0_io_perf_18_value[3] && w_s1_io_perf_18_value[3])) begin cov_fail++; $display("[COV] L2TLBWrapper.io_perf_18_value[3] 未见过 0 和 1"); end
    if (!(w_s0_io_perf_18_value[4] && w_s1_io_perf_18_value[4])) begin cov_fail++; $display("[COV] L2TLBWrapper.io_perf_18_value[4] 未见过 0 和 1"); end
    if (!(w_s0_io_perf_18_value[5] && w_s1_io_perf_18_value[5])) begin cov_fail++; $display("[COV] L2TLBWrapper.io_perf_18_value[5] 未见过 0 和 1"); end
    if (!(w_s0_boreChildrenBd_bore_ack && w_s1_boreChildrenBd_bore_ack)) begin cov_fail++; $display("[COV] L2TLBWrapper.boreChildrenBd_bore_ack 未见过 0 和 1"); end
    if (!(w_s0_boreChildrenBd_bore_outdata[0] && w_s1_boreChildrenBd_bore_outdata[0])) begin cov_fail++; $display("[COV] L2TLBWrapper.boreChildrenBd_bore_outdata[0] 未见过 0 和 1"); end
    if (!(w_s0_boreChildrenBd_bore_outdata[1] && w_s1_boreChildrenBd_bore_outdata[1])) begin cov_fail++; $display("[COV] L2TLBWrapper.boreChildrenBd_bore_outdata[1] 未见过 0 和 1"); end
    if (!(w_s0_boreChildrenBd_bore_outdata[2] && w_s1_boreChildrenBd_bore_outdata[2])) begin cov_fail++; $display("[COV] L2TLBWrapper.boreChildrenBd_bore_outdata[2] 未见过 0 和 1"); end
    if (!(w_s0_boreChildrenBd_bore_outdata[3] && w_s1_boreChildrenBd_bore_outdata[3])) begin cov_fail++; $display("[COV] L2TLBWrapper.boreChildrenBd_bore_outdata[3] 未见过 0 和 1"); end
    if (!(w_s0_boreChildrenBd_bore_outdata[4] && w_s1_boreChildrenBd_bore_outdata[4])) begin cov_fail++; $display("[COV] L2TLBWrapper.boreChildrenBd_bore_outdata[4] 未见过 0 和 1"); end
    if (!(w_s0_boreChildrenBd_bore_outdata[5] && w_s1_boreChildrenBd_bore_outdata[5])) begin cov_fail++; $display("[COV] L2TLBWrapper.boreChildrenBd_bore_outdata[5] 未见过 0 和 1"); end
    if (!(w_s0_boreChildrenBd_bore_outdata[6] && w_s1_boreChildrenBd_bore_outdata[6])) begin cov_fail++; $display("[COV] L2TLBWrapper.boreChildrenBd_bore_outdata[6] 未见过 0 和 1"); end
    if (!(w_s0_boreChildrenBd_bore_outdata[7] && w_s1_boreChildrenBd_bore_outdata[7])) begin cov_fail++; $display("[COV] L2TLBWrapper.boreChildrenBd_bore_outdata[7] 未见过 0 和 1"); end
    if (!(w_s0_boreChildrenBd_bore_outdata[8] && w_s1_boreChildrenBd_bore_outdata[8])) begin cov_fail++; $display("[COV] L2TLBWrapper.boreChildrenBd_bore_outdata[8] 未见过 0 和 1"); end
    if (!(w_s0_boreChildrenBd_bore_outdata[9] && w_s1_boreChildrenBd_bore_outdata[9])) begin cov_fail++; $display("[COV] L2TLBWrapper.boreChildrenBd_bore_outdata[9] 未见过 0 和 1"); end
    if (!(w_s0_boreChildrenBd_bore_outdata[10] && w_s1_boreChildrenBd_bore_outdata[10])) begin cov_fail++; $display("[COV] L2TLBWrapper.boreChildrenBd_bore_outdata[10] 未见过 0 和 1"); end
    if (!(w_s0_boreChildrenBd_bore_outdata[11] && w_s1_boreChildrenBd_bore_outdata[11])) begin cov_fail++; $display("[COV] L2TLBWrapper.boreChildrenBd_bore_outdata[11] 未见过 0 和 1"); end
    if (!(w_s0_boreChildrenBd_bore_outdata[12] && w_s1_boreChildrenBd_bore_outdata[12])) begin cov_fail++; $display("[COV] L2TLBWrapper.boreChildrenBd_bore_outdata[12] 未见过 0 和 1"); end
    if (!(w_s0_boreChildrenBd_bore_outdata[13] && w_s1_boreChildrenBd_bore_outdata[13])) begin cov_fail++; $display("[COV] L2TLBWrapper.boreChildrenBd_bore_outdata[13] 未见过 0 和 1"); end
    if (!(w_s0_boreChildrenBd_bore_outdata[14] && w_s1_boreChildrenBd_bore_outdata[14])) begin cov_fail++; $display("[COV] L2TLBWrapper.boreChildrenBd_bore_outdata[14] 未见过 0 和 1"); end
    if (!(w_s0_boreChildrenBd_bore_outdata[15] && w_s1_boreChildrenBd_bore_outdata[15])) begin cov_fail++; $display("[COV] L2TLBWrapper.boreChildrenBd_bore_outdata[15] 未见过 0 和 1"); end
    if (!(w_s0_boreChildrenBd_bore_outdata[16] && w_s1_boreChildrenBd_bore_outdata[16])) begin cov_fail++; $display("[COV] L2TLBWrapper.boreChildrenBd_bore_outdata[16] 未见过 0 和 1"); end
    if (!(w_s0_boreChildrenBd_bore_outdata[17] && w_s1_boreChildrenBd_bore_outdata[17])) begin cov_fail++; $display("[COV] L2TLBWrapper.boreChildrenBd_bore_outdata[17] 未见过 0 和 1"); end
    if (!(w_s0_boreChildrenBd_bore_outdata[18] && w_s1_boreChildrenBd_bore_outdata[18])) begin cov_fail++; $display("[COV] L2TLBWrapper.boreChildrenBd_bore_outdata[18] 未见过 0 和 1"); end
    if (!(w_s0_boreChildrenBd_bore_outdata[19] && w_s1_boreChildrenBd_bore_outdata[19])) begin cov_fail++; $display("[COV] L2TLBWrapper.boreChildrenBd_bore_outdata[19] 未见过 0 和 1"); end
    if (!(w_s0_boreChildrenBd_bore_outdata[20] && w_s1_boreChildrenBd_bore_outdata[20])) begin cov_fail++; $display("[COV] L2TLBWrapper.boreChildrenBd_bore_outdata[20] 未见过 0 和 1"); end
    if (!(w_s0_boreChildrenBd_bore_outdata[21] && w_s1_boreChildrenBd_bore_outdata[21])) begin cov_fail++; $display("[COV] L2TLBWrapper.boreChildrenBd_bore_outdata[21] 未见过 0 和 1"); end
    if (!(w_s0_boreChildrenBd_bore_outdata[22] && w_s1_boreChildrenBd_bore_outdata[22])) begin cov_fail++; $display("[COV] L2TLBWrapper.boreChildrenBd_bore_outdata[22] 未见过 0 和 1"); end
    if (!(w_s0_boreChildrenBd_bore_outdata[23] && w_s1_boreChildrenBd_bore_outdata[23])) begin cov_fail++; $display("[COV] L2TLBWrapper.boreChildrenBd_bore_outdata[23] 未见过 0 和 1"); end
    if (!(w_s0_boreChildrenBd_bore_outdata[24] && w_s1_boreChildrenBd_bore_outdata[24])) begin cov_fail++; $display("[COV] L2TLBWrapper.boreChildrenBd_bore_outdata[24] 未见过 0 和 1"); end
    if (!(w_s0_boreChildrenBd_bore_outdata[25] && w_s1_boreChildrenBd_bore_outdata[25])) begin cov_fail++; $display("[COV] L2TLBWrapper.boreChildrenBd_bore_outdata[25] 未见过 0 和 1"); end
    if (!(w_s0_boreChildrenBd_bore_outdata[26] && w_s1_boreChildrenBd_bore_outdata[26])) begin cov_fail++; $display("[COV] L2TLBWrapper.boreChildrenBd_bore_outdata[26] 未见过 0 和 1"); end
    if (!(w_s0_boreChildrenBd_bore_outdata[27] && w_s1_boreChildrenBd_bore_outdata[27])) begin cov_fail++; $display("[COV] L2TLBWrapper.boreChildrenBd_bore_outdata[27] 未见过 0 和 1"); end
    if (!(w_s0_boreChildrenBd_bore_outdata[28] && w_s1_boreChildrenBd_bore_outdata[28])) begin cov_fail++; $display("[COV] L2TLBWrapper.boreChildrenBd_bore_outdata[28] 未见过 0 和 1"); end
    if (!(w_s0_boreChildrenBd_bore_outdata[29] && w_s1_boreChildrenBd_bore_outdata[29])) begin cov_fail++; $display("[COV] L2TLBWrapper.boreChildrenBd_bore_outdata[29] 未见过 0 和 1"); end
    if (!(w_s0_boreChildrenBd_bore_outdata[30] && w_s1_boreChildrenBd_bore_outdata[30])) begin cov_fail++; $display("[COV] L2TLBWrapper.boreChildrenBd_bore_outdata[30] 未见过 0 和 1"); end
    if (!(w_s0_boreChildrenBd_bore_outdata[31] && w_s1_boreChildrenBd_bore_outdata[31])) begin cov_fail++; $display("[COV] L2TLBWrapper.boreChildrenBd_bore_outdata[31] 未见过 0 和 1"); end
    if (!(w_s0_boreChildrenBd_bore_outdata[32] && w_s1_boreChildrenBd_bore_outdata[32])) begin cov_fail++; $display("[COV] L2TLBWrapper.boreChildrenBd_bore_outdata[32] 未见过 0 和 1"); end
    if (!(w_s0_boreChildrenBd_bore_outdata[33] && w_s1_boreChildrenBd_bore_outdata[33])) begin cov_fail++; $display("[COV] L2TLBWrapper.boreChildrenBd_bore_outdata[33] 未见过 0 和 1"); end
    if (!(w_s0_boreChildrenBd_bore_outdata[34] && w_s1_boreChildrenBd_bore_outdata[34])) begin cov_fail++; $display("[COV] L2TLBWrapper.boreChildrenBd_bore_outdata[34] 未见过 0 和 1"); end
    if (!(w_s0_boreChildrenBd_bore_outdata[35] && w_s1_boreChildrenBd_bore_outdata[35])) begin cov_fail++; $display("[COV] L2TLBWrapper.boreChildrenBd_bore_outdata[35] 未见过 0 和 1"); end
    if (!(w_s0_boreChildrenBd_bore_outdata[36] && w_s1_boreChildrenBd_bore_outdata[36])) begin cov_fail++; $display("[COV] L2TLBWrapper.boreChildrenBd_bore_outdata[36] 未见过 0 和 1"); end
    if (!(w_s0_boreChildrenBd_bore_outdata[37] && w_s1_boreChildrenBd_bore_outdata[37])) begin cov_fail++; $display("[COV] L2TLBWrapper.boreChildrenBd_bore_outdata[37] 未见过 0 和 1"); end
    if (!(w_s0_boreChildrenBd_bore_outdata[38] && w_s1_boreChildrenBd_bore_outdata[38])) begin cov_fail++; $display("[COV] L2TLBWrapper.boreChildrenBd_bore_outdata[38] 未见过 0 和 1"); end
    if (!(w_s0_boreChildrenBd_bore_outdata[39] && w_s1_boreChildrenBd_bore_outdata[39])) begin cov_fail++; $display("[COV] L2TLBWrapper.boreChildrenBd_bore_outdata[39] 未见过 0 和 1"); end
    if (!(w_s0_boreChildrenBd_bore_outdata[40] && w_s1_boreChildrenBd_bore_outdata[40])) begin cov_fail++; $display("[COV] L2TLBWrapper.boreChildrenBd_bore_outdata[40] 未见过 0 和 1"); end
    if (!(w_s0_boreChildrenBd_bore_outdata[41] && w_s1_boreChildrenBd_bore_outdata[41])) begin cov_fail++; $display("[COV] L2TLBWrapper.boreChildrenBd_bore_outdata[41] 未见过 0 和 1"); end
    if (!(w_s0_boreChildrenBd_bore_outdata[42] && w_s1_boreChildrenBd_bore_outdata[42])) begin cov_fail++; $display("[COV] L2TLBWrapper.boreChildrenBd_bore_outdata[42] 未见过 0 和 1"); end
    if (!(w_s0_boreChildrenBd_bore_outdata[43] && w_s1_boreChildrenBd_bore_outdata[43])) begin cov_fail++; $display("[COV] L2TLBWrapper.boreChildrenBd_bore_outdata[43] 未见过 0 和 1"); end
    if (!(w_s0_boreChildrenBd_bore_outdata[44] && w_s1_boreChildrenBd_bore_outdata[44])) begin cov_fail++; $display("[COV] L2TLBWrapper.boreChildrenBd_bore_outdata[44] 未见过 0 和 1"); end
    if (!(w_s0_boreChildrenBd_bore_outdata[45] && w_s1_boreChildrenBd_bore_outdata[45])) begin cov_fail++; $display("[COV] L2TLBWrapper.boreChildrenBd_bore_outdata[45] 未见过 0 和 1"); end
    if (!(w_s0_boreChildrenBd_bore_outdata[46] && w_s1_boreChildrenBd_bore_outdata[46])) begin cov_fail++; $display("[COV] L2TLBWrapper.boreChildrenBd_bore_outdata[46] 未见过 0 和 1"); end
    if (!(w_s0_boreChildrenBd_bore_outdata[47] && w_s1_boreChildrenBd_bore_outdata[47])) begin cov_fail++; $display("[COV] L2TLBWrapper.boreChildrenBd_bore_outdata[47] 未见过 0 和 1"); end
    if (!(w_s0_boreChildrenBd_bore_outdata[48] && w_s1_boreChildrenBd_bore_outdata[48])) begin cov_fail++; $display("[COV] L2TLBWrapper.boreChildrenBd_bore_outdata[48] 未见过 0 和 1"); end
    if (!(w_s0_boreChildrenBd_bore_outdata[49] && w_s1_boreChildrenBd_bore_outdata[49])) begin cov_fail++; $display("[COV] L2TLBWrapper.boreChildrenBd_bore_outdata[49] 未见过 0 和 1"); end
    if (!(w_s0_boreChildrenBd_bore_outdata[50] && w_s1_boreChildrenBd_bore_outdata[50])) begin cov_fail++; $display("[COV] L2TLBWrapper.boreChildrenBd_bore_outdata[50] 未见过 0 和 1"); end
    if (!(w_s0_boreChildrenBd_bore_outdata[51] && w_s1_boreChildrenBd_bore_outdata[51])) begin cov_fail++; $display("[COV] L2TLBWrapper.boreChildrenBd_bore_outdata[51] 未见过 0 和 1"); end
    if (!(w_s0_boreChildrenBd_bore_outdata[52] && w_s1_boreChildrenBd_bore_outdata[52])) begin cov_fail++; $display("[COV] L2TLBWrapper.boreChildrenBd_bore_outdata[52] 未见过 0 和 1"); end
    if (!(w_s0_boreChildrenBd_bore_outdata[53] && w_s1_boreChildrenBd_bore_outdata[53])) begin cov_fail++; $display("[COV] L2TLBWrapper.boreChildrenBd_bore_outdata[53] 未见过 0 和 1"); end
    if (!(w_s0_boreChildrenBd_bore_outdata[54] && w_s1_boreChildrenBd_bore_outdata[54])) begin cov_fail++; $display("[COV] L2TLBWrapper.boreChildrenBd_bore_outdata[54] 未见过 0 和 1"); end
    if (!(w_s0_boreChildrenBd_bore_outdata[55] && w_s1_boreChildrenBd_bore_outdata[55])) begin cov_fail++; $display("[COV] L2TLBWrapper.boreChildrenBd_bore_outdata[55] 未见过 0 和 1"); end
    if (!(w_s0_boreChildrenBd_bore_outdata[56] && w_s1_boreChildrenBd_bore_outdata[56])) begin cov_fail++; $display("[COV] L2TLBWrapper.boreChildrenBd_bore_outdata[56] 未见过 0 和 1"); end
    if (!(w_s0_boreChildrenBd_bore_outdata[57] && w_s1_boreChildrenBd_bore_outdata[57])) begin cov_fail++; $display("[COV] L2TLBWrapper.boreChildrenBd_bore_outdata[57] 未见过 0 和 1"); end
    if (!(w_s0_boreChildrenBd_bore_outdata[58] && w_s1_boreChildrenBd_bore_outdata[58])) begin cov_fail++; $display("[COV] L2TLBWrapper.boreChildrenBd_bore_outdata[58] 未见过 0 和 1"); end
    if (!(w_s0_boreChildrenBd_bore_outdata[59] && w_s1_boreChildrenBd_bore_outdata[59])) begin cov_fail++; $display("[COV] L2TLBWrapper.boreChildrenBd_bore_outdata[59] 未见过 0 和 1"); end
    if (!(w_s0_boreChildrenBd_bore_outdata[60] && w_s1_boreChildrenBd_bore_outdata[60])) begin cov_fail++; $display("[COV] L2TLBWrapper.boreChildrenBd_bore_outdata[60] 未见过 0 和 1"); end
    if (!(w_s0_boreChildrenBd_bore_outdata[61] && w_s1_boreChildrenBd_bore_outdata[61])) begin cov_fail++; $display("[COV] L2TLBWrapper.boreChildrenBd_bore_outdata[61] 未见过 0 和 1"); end
    if (!(w_s0_boreChildrenBd_bore_outdata[62] && w_s1_boreChildrenBd_bore_outdata[62])) begin cov_fail++; $display("[COV] L2TLBWrapper.boreChildrenBd_bore_outdata[62] 未见过 0 和 1"); end
    if (!(w_s0_boreChildrenBd_bore_outdata[63] && w_s1_boreChildrenBd_bore_outdata[63])) begin cov_fail++; $display("[COV] L2TLBWrapper.boreChildrenBd_bore_outdata[63] 未见过 0 和 1"); end
    if (!(w_s0_boreChildrenBd_bore_outdata[64] && w_s1_boreChildrenBd_bore_outdata[64])) begin cov_fail++; $display("[COV] L2TLBWrapper.boreChildrenBd_bore_outdata[64] 未见过 0 和 1"); end
    if (!(w_s0_boreChildrenBd_bore_outdata[65] && w_s1_boreChildrenBd_bore_outdata[65])) begin cov_fail++; $display("[COV] L2TLBWrapper.boreChildrenBd_bore_outdata[65] 未见过 0 和 1"); end
    if (!(w_s0_boreChildrenBd_bore_outdata[66] && w_s1_boreChildrenBd_bore_outdata[66])) begin cov_fail++; $display("[COV] L2TLBWrapper.boreChildrenBd_bore_outdata[66] 未见过 0 和 1"); end
    if (!(w_s0_boreChildrenBd_bore_outdata[67] && w_s1_boreChildrenBd_bore_outdata[67])) begin cov_fail++; $display("[COV] L2TLBWrapper.boreChildrenBd_bore_outdata[67] 未见过 0 和 1"); end
    if (!(w_s0_boreChildrenBd_bore_outdata[68] && w_s1_boreChildrenBd_bore_outdata[68])) begin cov_fail++; $display("[COV] L2TLBWrapper.boreChildrenBd_bore_outdata[68] 未见过 0 和 1"); end
    if (!(w_s0_boreChildrenBd_bore_outdata[69] && w_s1_boreChildrenBd_bore_outdata[69])) begin cov_fail++; $display("[COV] L2TLBWrapper.boreChildrenBd_bore_outdata[69] 未见过 0 和 1"); end
    if (!(w_s0_boreChildrenBd_bore_outdata[70] && w_s1_boreChildrenBd_bore_outdata[70])) begin cov_fail++; $display("[COV] L2TLBWrapper.boreChildrenBd_bore_outdata[70] 未见过 0 和 1"); end
    if (!(w_s0_boreChildrenBd_bore_outdata[71] && w_s1_boreChildrenBd_bore_outdata[71])) begin cov_fail++; $display("[COV] L2TLBWrapper.boreChildrenBd_bore_outdata[71] 未见过 0 和 1"); end
    if (!(w_s0_boreChildrenBd_bore_outdata[72] && w_s1_boreChildrenBd_bore_outdata[72])) begin cov_fail++; $display("[COV] L2TLBWrapper.boreChildrenBd_bore_outdata[72] 未见过 0 和 1"); end
    if (!(w_s0_boreChildrenBd_bore_outdata[73] && w_s1_boreChildrenBd_bore_outdata[73])) begin cov_fail++; $display("[COV] L2TLBWrapper.boreChildrenBd_bore_outdata[73] 未见过 0 和 1"); end
    if (!(w_s0_boreChildrenBd_bore_outdata[74] && w_s1_boreChildrenBd_bore_outdata[74])) begin cov_fail++; $display("[COV] L2TLBWrapper.boreChildrenBd_bore_outdata[74] 未见过 0 和 1"); end
    if (!(w_s0_boreChildrenBd_bore_outdata[75] && w_s1_boreChildrenBd_bore_outdata[75])) begin cov_fail++; $display("[COV] L2TLBWrapper.boreChildrenBd_bore_outdata[75] 未见过 0 和 1"); end
    if (!(w_s0_boreChildrenBd_bore_outdata[76] && w_s1_boreChildrenBd_bore_outdata[76])) begin cov_fail++; $display("[COV] L2TLBWrapper.boreChildrenBd_bore_outdata[76] 未见过 0 和 1"); end
    if (!(w_s0_boreChildrenBd_bore_outdata[77] && w_s1_boreChildrenBd_bore_outdata[77])) begin cov_fail++; $display("[COV] L2TLBWrapper.boreChildrenBd_bore_outdata[77] 未见过 0 和 1"); end
    if (!(w_s0_boreChildrenBd_bore_outdata[78] && w_s1_boreChildrenBd_bore_outdata[78])) begin cov_fail++; $display("[COV] L2TLBWrapper.boreChildrenBd_bore_outdata[78] 未见过 0 和 1"); end
    if (!(w_s0_boreChildrenBd_bore_outdata[79] && w_s1_boreChildrenBd_bore_outdata[79])) begin cov_fail++; $display("[COV] L2TLBWrapper.boreChildrenBd_bore_outdata[79] 未见过 0 和 1"); end
    if (!(w_s0_boreChildrenBd_bore_outdata[80] && w_s1_boreChildrenBd_bore_outdata[80])) begin cov_fail++; $display("[COV] L2TLBWrapper.boreChildrenBd_bore_outdata[80] 未见过 0 和 1"); end
    if (!(w_s0_boreChildrenBd_bore_outdata[81] && w_s1_boreChildrenBd_bore_outdata[81])) begin cov_fail++; $display("[COV] L2TLBWrapper.boreChildrenBd_bore_outdata[81] 未见过 0 和 1"); end
    if (!(w_s0_boreChildrenBd_bore_outdata[82] && w_s1_boreChildrenBd_bore_outdata[82])) begin cov_fail++; $display("[COV] L2TLBWrapper.boreChildrenBd_bore_outdata[82] 未见过 0 和 1"); end
    if (!(w_s0_boreChildrenBd_bore_outdata[83] && w_s1_boreChildrenBd_bore_outdata[83])) begin cov_fail++; $display("[COV] L2TLBWrapper.boreChildrenBd_bore_outdata[83] 未见过 0 和 1"); end
    if (!(w_s0_boreChildrenBd_bore_outdata[84] && w_s1_boreChildrenBd_bore_outdata[84])) begin cov_fail++; $display("[COV] L2TLBWrapper.boreChildrenBd_bore_outdata[84] 未见过 0 和 1"); end
    if (!(w_s0_boreChildrenBd_bore_outdata[85] && w_s1_boreChildrenBd_bore_outdata[85])) begin cov_fail++; $display("[COV] L2TLBWrapper.boreChildrenBd_bore_outdata[85] 未见过 0 和 1"); end
    if (!(w_s0_boreChildrenBd_bore_outdata[86] && w_s1_boreChildrenBd_bore_outdata[86])) begin cov_fail++; $display("[COV] L2TLBWrapper.boreChildrenBd_bore_outdata[86] 未见过 0 和 1"); end
    if (!(w_s0_boreChildrenBd_bore_outdata[87] && w_s1_boreChildrenBd_bore_outdata[87])) begin cov_fail++; $display("[COV] L2TLBWrapper.boreChildrenBd_bore_outdata[87] 未见过 0 和 1"); end
    if (!(w_s0_boreChildrenBd_bore_outdata[88] && w_s1_boreChildrenBd_bore_outdata[88])) begin cov_fail++; $display("[COV] L2TLBWrapper.boreChildrenBd_bore_outdata[88] 未见过 0 和 1"); end
    if (!(w_s0_boreChildrenBd_bore_outdata[89] && w_s1_boreChildrenBd_bore_outdata[89])) begin cov_fail++; $display("[COV] L2TLBWrapper.boreChildrenBd_bore_outdata[89] 未见过 0 和 1"); end
    if (!(w_s0_boreChildrenBd_bore_1_ack && w_s1_boreChildrenBd_bore_1_ack)) begin cov_fail++; $display("[COV] L2TLBWrapper.boreChildrenBd_bore_1_ack 未见过 0 和 1"); end
    if (!(w_s0_boreChildrenBd_bore_1_outdata[0] && w_s1_boreChildrenBd_bore_1_outdata[0])) begin cov_fail++; $display("[COV] L2TLBWrapper.boreChildrenBd_bore_1_outdata[0] 未见过 0 和 1"); end
    if (!(w_s0_boreChildrenBd_bore_1_outdata[1] && w_s1_boreChildrenBd_bore_1_outdata[1])) begin cov_fail++; $display("[COV] L2TLBWrapper.boreChildrenBd_bore_1_outdata[1] 未见过 0 和 1"); end
    if (!(w_s0_boreChildrenBd_bore_1_outdata[2] && w_s1_boreChildrenBd_bore_1_outdata[2])) begin cov_fail++; $display("[COV] L2TLBWrapper.boreChildrenBd_bore_1_outdata[2] 未见过 0 和 1"); end
    if (!(w_s0_boreChildrenBd_bore_1_outdata[3] && w_s1_boreChildrenBd_bore_1_outdata[3])) begin cov_fail++; $display("[COV] L2TLBWrapper.boreChildrenBd_bore_1_outdata[3] 未见过 0 和 1"); end
    if (!(w_s0_boreChildrenBd_bore_1_outdata[4] && w_s1_boreChildrenBd_bore_1_outdata[4])) begin cov_fail++; $display("[COV] L2TLBWrapper.boreChildrenBd_bore_1_outdata[4] 未见过 0 和 1"); end
    if (!(w_s0_boreChildrenBd_bore_1_outdata[5] && w_s1_boreChildrenBd_bore_1_outdata[5])) begin cov_fail++; $display("[COV] L2TLBWrapper.boreChildrenBd_bore_1_outdata[5] 未见过 0 和 1"); end
    if (!(w_s0_boreChildrenBd_bore_1_outdata[6] && w_s1_boreChildrenBd_bore_1_outdata[6])) begin cov_fail++; $display("[COV] L2TLBWrapper.boreChildrenBd_bore_1_outdata[6] 未见过 0 和 1"); end
    if (!(w_s0_boreChildrenBd_bore_1_outdata[7] && w_s1_boreChildrenBd_bore_1_outdata[7])) begin cov_fail++; $display("[COV] L2TLBWrapper.boreChildrenBd_bore_1_outdata[7] 未见过 0 和 1"); end
    if (!(w_s0_boreChildrenBd_bore_1_outdata[8] && w_s1_boreChildrenBd_bore_1_outdata[8])) begin cov_fail++; $display("[COV] L2TLBWrapper.boreChildrenBd_bore_1_outdata[8] 未见过 0 和 1"); end
    if (!(w_s0_boreChildrenBd_bore_1_outdata[9] && w_s1_boreChildrenBd_bore_1_outdata[9])) begin cov_fail++; $display("[COV] L2TLBWrapper.boreChildrenBd_bore_1_outdata[9] 未见过 0 和 1"); end
    if (!(w_s0_boreChildrenBd_bore_1_outdata[10] && w_s1_boreChildrenBd_bore_1_outdata[10])) begin cov_fail++; $display("[COV] L2TLBWrapper.boreChildrenBd_bore_1_outdata[10] 未见过 0 和 1"); end
    if (!(w_s0_boreChildrenBd_bore_1_outdata[11] && w_s1_boreChildrenBd_bore_1_outdata[11])) begin cov_fail++; $display("[COV] L2TLBWrapper.boreChildrenBd_bore_1_outdata[11] 未见过 0 和 1"); end
    if (!(w_s0_boreChildrenBd_bore_1_outdata[12] && w_s1_boreChildrenBd_bore_1_outdata[12])) begin cov_fail++; $display("[COV] L2TLBWrapper.boreChildrenBd_bore_1_outdata[12] 未见过 0 和 1"); end
    if (!(w_s0_boreChildrenBd_bore_1_outdata[13] && w_s1_boreChildrenBd_bore_1_outdata[13])) begin cov_fail++; $display("[COV] L2TLBWrapper.boreChildrenBd_bore_1_outdata[13] 未见过 0 和 1"); end
    if (!(w_s0_boreChildrenBd_bore_1_outdata[14] && w_s1_boreChildrenBd_bore_1_outdata[14])) begin cov_fail++; $display("[COV] L2TLBWrapper.boreChildrenBd_bore_1_outdata[14] 未见过 0 和 1"); end
    if (!(w_s0_boreChildrenBd_bore_1_outdata[15] && w_s1_boreChildrenBd_bore_1_outdata[15])) begin cov_fail++; $display("[COV] L2TLBWrapper.boreChildrenBd_bore_1_outdata[15] 未见过 0 和 1"); end
    if (!(w_s0_boreChildrenBd_bore_1_outdata[16] && w_s1_boreChildrenBd_bore_1_outdata[16])) begin cov_fail++; $display("[COV] L2TLBWrapper.boreChildrenBd_bore_1_outdata[16] 未见过 0 和 1"); end
    if (!(w_s0_boreChildrenBd_bore_1_outdata[17] && w_s1_boreChildrenBd_bore_1_outdata[17])) begin cov_fail++; $display("[COV] L2TLBWrapper.boreChildrenBd_bore_1_outdata[17] 未见过 0 和 1"); end
    if (!(w_s0_boreChildrenBd_bore_1_outdata[18] && w_s1_boreChildrenBd_bore_1_outdata[18])) begin cov_fail++; $display("[COV] L2TLBWrapper.boreChildrenBd_bore_1_outdata[18] 未见过 0 和 1"); end
    if (!(w_s0_boreChildrenBd_bore_1_outdata[19] && w_s1_boreChildrenBd_bore_1_outdata[19])) begin cov_fail++; $display("[COV] L2TLBWrapper.boreChildrenBd_bore_1_outdata[19] 未见过 0 和 1"); end
    if (!(w_s0_boreChildrenBd_bore_1_outdata[20] && w_s1_boreChildrenBd_bore_1_outdata[20])) begin cov_fail++; $display("[COV] L2TLBWrapper.boreChildrenBd_bore_1_outdata[20] 未见过 0 和 1"); end
    if (!(w_s0_boreChildrenBd_bore_1_outdata[21] && w_s1_boreChildrenBd_bore_1_outdata[21])) begin cov_fail++; $display("[COV] L2TLBWrapper.boreChildrenBd_bore_1_outdata[21] 未见过 0 和 1"); end
    if (!(w_s0_boreChildrenBd_bore_1_outdata[22] && w_s1_boreChildrenBd_bore_1_outdata[22])) begin cov_fail++; $display("[COV] L2TLBWrapper.boreChildrenBd_bore_1_outdata[22] 未见过 0 和 1"); end
    if (!(w_s0_boreChildrenBd_bore_1_outdata[23] && w_s1_boreChildrenBd_bore_1_outdata[23])) begin cov_fail++; $display("[COV] L2TLBWrapper.boreChildrenBd_bore_1_outdata[23] 未见过 0 和 1"); end
    if (!(w_s0_boreChildrenBd_bore_1_outdata[24] && w_s1_boreChildrenBd_bore_1_outdata[24])) begin cov_fail++; $display("[COV] L2TLBWrapper.boreChildrenBd_bore_1_outdata[24] 未见过 0 和 1"); end
    if (!(w_s0_boreChildrenBd_bore_1_outdata[25] && w_s1_boreChildrenBd_bore_1_outdata[25])) begin cov_fail++; $display("[COV] L2TLBWrapper.boreChildrenBd_bore_1_outdata[25] 未见过 0 和 1"); end
    if (!(w_s0_boreChildrenBd_bore_1_outdata[26] && w_s1_boreChildrenBd_bore_1_outdata[26])) begin cov_fail++; $display("[COV] L2TLBWrapper.boreChildrenBd_bore_1_outdata[26] 未见过 0 和 1"); end
    if (!(w_s0_boreChildrenBd_bore_1_outdata[27] && w_s1_boreChildrenBd_bore_1_outdata[27])) begin cov_fail++; $display("[COV] L2TLBWrapper.boreChildrenBd_bore_1_outdata[27] 未见过 0 和 1"); end
    if (!(w_s0_boreChildrenBd_bore_1_outdata[28] && w_s1_boreChildrenBd_bore_1_outdata[28])) begin cov_fail++; $display("[COV] L2TLBWrapper.boreChildrenBd_bore_1_outdata[28] 未见过 0 和 1"); end
    if (!(w_s0_boreChildrenBd_bore_1_outdata[29] && w_s1_boreChildrenBd_bore_1_outdata[29])) begin cov_fail++; $display("[COV] L2TLBWrapper.boreChildrenBd_bore_1_outdata[29] 未见过 0 和 1"); end
    if (!(w_s0_boreChildrenBd_bore_1_outdata[30] && w_s1_boreChildrenBd_bore_1_outdata[30])) begin cov_fail++; $display("[COV] L2TLBWrapper.boreChildrenBd_bore_1_outdata[30] 未见过 0 和 1"); end
    if (!(w_s0_boreChildrenBd_bore_1_outdata[31] && w_s1_boreChildrenBd_bore_1_outdata[31])) begin cov_fail++; $display("[COV] L2TLBWrapper.boreChildrenBd_bore_1_outdata[31] 未见过 0 和 1"); end
    if (!(w_s0_boreChildrenBd_bore_1_outdata[32] && w_s1_boreChildrenBd_bore_1_outdata[32])) begin cov_fail++; $display("[COV] L2TLBWrapper.boreChildrenBd_bore_1_outdata[32] 未见过 0 和 1"); end
    if (!(w_s0_boreChildrenBd_bore_1_outdata[33] && w_s1_boreChildrenBd_bore_1_outdata[33])) begin cov_fail++; $display("[COV] L2TLBWrapper.boreChildrenBd_bore_1_outdata[33] 未见过 0 和 1"); end
    if (!(w_s0_boreChildrenBd_bore_1_outdata[34] && w_s1_boreChildrenBd_bore_1_outdata[34])) begin cov_fail++; $display("[COV] L2TLBWrapper.boreChildrenBd_bore_1_outdata[34] 未见过 0 和 1"); end
    if (!(w_s0_boreChildrenBd_bore_1_outdata[35] && w_s1_boreChildrenBd_bore_1_outdata[35])) begin cov_fail++; $display("[COV] L2TLBWrapper.boreChildrenBd_bore_1_outdata[35] 未见过 0 和 1"); end
    if (!(w_s0_boreChildrenBd_bore_1_outdata[36] && w_s1_boreChildrenBd_bore_1_outdata[36])) begin cov_fail++; $display("[COV] L2TLBWrapper.boreChildrenBd_bore_1_outdata[36] 未见过 0 和 1"); end
    if (!(w_s0_boreChildrenBd_bore_1_outdata[37] && w_s1_boreChildrenBd_bore_1_outdata[37])) begin cov_fail++; $display("[COV] L2TLBWrapper.boreChildrenBd_bore_1_outdata[37] 未见过 0 和 1"); end
    if (!(w_s0_boreChildrenBd_bore_1_outdata[38] && w_s1_boreChildrenBd_bore_1_outdata[38])) begin cov_fail++; $display("[COV] L2TLBWrapper.boreChildrenBd_bore_1_outdata[38] 未见过 0 和 1"); end
    if (!(w_s0_boreChildrenBd_bore_1_outdata[39] && w_s1_boreChildrenBd_bore_1_outdata[39])) begin cov_fail++; $display("[COV] L2TLBWrapper.boreChildrenBd_bore_1_outdata[39] 未见过 0 和 1"); end
    if (!(w_s0_boreChildrenBd_bore_1_outdata[40] && w_s1_boreChildrenBd_bore_1_outdata[40])) begin cov_fail++; $display("[COV] L2TLBWrapper.boreChildrenBd_bore_1_outdata[40] 未见过 0 和 1"); end
    if (!(w_s0_boreChildrenBd_bore_1_outdata[41] && w_s1_boreChildrenBd_bore_1_outdata[41])) begin cov_fail++; $display("[COV] L2TLBWrapper.boreChildrenBd_bore_1_outdata[41] 未见过 0 和 1"); end
    if (!(w_s0_boreChildrenBd_bore_1_outdata[42] && w_s1_boreChildrenBd_bore_1_outdata[42])) begin cov_fail++; $display("[COV] L2TLBWrapper.boreChildrenBd_bore_1_outdata[42] 未见过 0 和 1"); end
    if (!(w_s0_boreChildrenBd_bore_1_outdata[43] && w_s1_boreChildrenBd_bore_1_outdata[43])) begin cov_fail++; $display("[COV] L2TLBWrapper.boreChildrenBd_bore_1_outdata[43] 未见过 0 和 1"); end
    if (!(w_s0_boreChildrenBd_bore_1_outdata[44] && w_s1_boreChildrenBd_bore_1_outdata[44])) begin cov_fail++; $display("[COV] L2TLBWrapper.boreChildrenBd_bore_1_outdata[44] 未见过 0 和 1"); end
    if (!(w_s0_boreChildrenBd_bore_1_outdata[45] && w_s1_boreChildrenBd_bore_1_outdata[45])) begin cov_fail++; $display("[COV] L2TLBWrapper.boreChildrenBd_bore_1_outdata[45] 未见过 0 和 1"); end
    if (!(w_s0_boreChildrenBd_bore_1_outdata[46] && w_s1_boreChildrenBd_bore_1_outdata[46])) begin cov_fail++; $display("[COV] L2TLBWrapper.boreChildrenBd_bore_1_outdata[46] 未见过 0 和 1"); end
    if (!(w_s0_boreChildrenBd_bore_1_outdata[47] && w_s1_boreChildrenBd_bore_1_outdata[47])) begin cov_fail++; $display("[COV] L2TLBWrapper.boreChildrenBd_bore_1_outdata[47] 未见过 0 和 1"); end
    if (!(w_s0_boreChildrenBd_bore_1_outdata[48] && w_s1_boreChildrenBd_bore_1_outdata[48])) begin cov_fail++; $display("[COV] L2TLBWrapper.boreChildrenBd_bore_1_outdata[48] 未见过 0 和 1"); end
    if (!(w_s0_boreChildrenBd_bore_1_outdata[49] && w_s1_boreChildrenBd_bore_1_outdata[49])) begin cov_fail++; $display("[COV] L2TLBWrapper.boreChildrenBd_bore_1_outdata[49] 未见过 0 和 1"); end
    if (!(w_s0_boreChildrenBd_bore_1_outdata[50] && w_s1_boreChildrenBd_bore_1_outdata[50])) begin cov_fail++; $display("[COV] L2TLBWrapper.boreChildrenBd_bore_1_outdata[50] 未见过 0 和 1"); end
    if (!(w_s0_boreChildrenBd_bore_1_outdata[51] && w_s1_boreChildrenBd_bore_1_outdata[51])) begin cov_fail++; $display("[COV] L2TLBWrapper.boreChildrenBd_bore_1_outdata[51] 未见过 0 和 1"); end
    if (!(w_s0_boreChildrenBd_bore_1_outdata[52] && w_s1_boreChildrenBd_bore_1_outdata[52])) begin cov_fail++; $display("[COV] L2TLBWrapper.boreChildrenBd_bore_1_outdata[52] 未见过 0 和 1"); end
    if (!(w_s0_boreChildrenBd_bore_1_outdata[53] && w_s1_boreChildrenBd_bore_1_outdata[53])) begin cov_fail++; $display("[COV] L2TLBWrapper.boreChildrenBd_bore_1_outdata[53] 未见过 0 和 1"); end
    if (!(w_s0_boreChildrenBd_bore_1_outdata[54] && w_s1_boreChildrenBd_bore_1_outdata[54])) begin cov_fail++; $display("[COV] L2TLBWrapper.boreChildrenBd_bore_1_outdata[54] 未见过 0 和 1"); end
    if (!(w_s0_boreChildrenBd_bore_1_outdata[55] && w_s1_boreChildrenBd_bore_1_outdata[55])) begin cov_fail++; $display("[COV] L2TLBWrapper.boreChildrenBd_bore_1_outdata[55] 未见过 0 和 1"); end
    if (!(w_s0_boreChildrenBd_bore_1_outdata[56] && w_s1_boreChildrenBd_bore_1_outdata[56])) begin cov_fail++; $display("[COV] L2TLBWrapper.boreChildrenBd_bore_1_outdata[56] 未见过 0 和 1"); end
    if (!(w_s0_boreChildrenBd_bore_1_outdata[57] && w_s1_boreChildrenBd_bore_1_outdata[57])) begin cov_fail++; $display("[COV] L2TLBWrapper.boreChildrenBd_bore_1_outdata[57] 未见过 0 和 1"); end
    if (!(w_s0_boreChildrenBd_bore_1_outdata[58] && w_s1_boreChildrenBd_bore_1_outdata[58])) begin cov_fail++; $display("[COV] L2TLBWrapper.boreChildrenBd_bore_1_outdata[58] 未见过 0 和 1"); end
    if (!(w_s0_boreChildrenBd_bore_1_outdata[59] && w_s1_boreChildrenBd_bore_1_outdata[59])) begin cov_fail++; $display("[COV] L2TLBWrapper.boreChildrenBd_bore_1_outdata[59] 未见过 0 和 1"); end
    if (!(w_s0_boreChildrenBd_bore_1_outdata[60] && w_s1_boreChildrenBd_bore_1_outdata[60])) begin cov_fail++; $display("[COV] L2TLBWrapper.boreChildrenBd_bore_1_outdata[60] 未见过 0 和 1"); end
    if (!(w_s0_boreChildrenBd_bore_1_outdata[61] && w_s1_boreChildrenBd_bore_1_outdata[61])) begin cov_fail++; $display("[COV] L2TLBWrapper.boreChildrenBd_bore_1_outdata[61] 未见过 0 和 1"); end
    if (!(w_s0_boreChildrenBd_bore_1_outdata[62] && w_s1_boreChildrenBd_bore_1_outdata[62])) begin cov_fail++; $display("[COV] L2TLBWrapper.boreChildrenBd_bore_1_outdata[62] 未见过 0 和 1"); end
    if (!(w_s0_boreChildrenBd_bore_1_outdata[63] && w_s1_boreChildrenBd_bore_1_outdata[63])) begin cov_fail++; $display("[COV] L2TLBWrapper.boreChildrenBd_bore_1_outdata[63] 未见过 0 和 1"); end
    if (!(w_s0_boreChildrenBd_bore_1_outdata[64] && w_s1_boreChildrenBd_bore_1_outdata[64])) begin cov_fail++; $display("[COV] L2TLBWrapper.boreChildrenBd_bore_1_outdata[64] 未见过 0 和 1"); end
    if (!(w_s0_boreChildrenBd_bore_1_outdata[65] && w_s1_boreChildrenBd_bore_1_outdata[65])) begin cov_fail++; $display("[COV] L2TLBWrapper.boreChildrenBd_bore_1_outdata[65] 未见过 0 和 1"); end
    if (!(w_s0_boreChildrenBd_bore_1_outdata[66] && w_s1_boreChildrenBd_bore_1_outdata[66])) begin cov_fail++; $display("[COV] L2TLBWrapper.boreChildrenBd_bore_1_outdata[66] 未见过 0 和 1"); end
    if (!(w_s0_boreChildrenBd_bore_1_outdata[67] && w_s1_boreChildrenBd_bore_1_outdata[67])) begin cov_fail++; $display("[COV] L2TLBWrapper.boreChildrenBd_bore_1_outdata[67] 未见过 0 和 1"); end
    if (!(w_s0_boreChildrenBd_bore_1_outdata[68] && w_s1_boreChildrenBd_bore_1_outdata[68])) begin cov_fail++; $display("[COV] L2TLBWrapper.boreChildrenBd_bore_1_outdata[68] 未见过 0 和 1"); end
    if (!(w_s0_boreChildrenBd_bore_1_outdata[69] && w_s1_boreChildrenBd_bore_1_outdata[69])) begin cov_fail++; $display("[COV] L2TLBWrapper.boreChildrenBd_bore_1_outdata[69] 未见过 0 和 1"); end
    if (!(w_s0_boreChildrenBd_bore_1_outdata[70] && w_s1_boreChildrenBd_bore_1_outdata[70])) begin cov_fail++; $display("[COV] L2TLBWrapper.boreChildrenBd_bore_1_outdata[70] 未见过 0 和 1"); end
    if (!(w_s0_boreChildrenBd_bore_1_outdata[71] && w_s1_boreChildrenBd_bore_1_outdata[71])) begin cov_fail++; $display("[COV] L2TLBWrapper.boreChildrenBd_bore_1_outdata[71] 未见过 0 和 1"); end
    if (!(w_s0_boreChildrenBd_bore_1_outdata[72] && w_s1_boreChildrenBd_bore_1_outdata[72])) begin cov_fail++; $display("[COV] L2TLBWrapper.boreChildrenBd_bore_1_outdata[72] 未见过 0 和 1"); end
    if (!(w_s0_boreChildrenBd_bore_1_outdata[73] && w_s1_boreChildrenBd_bore_1_outdata[73])) begin cov_fail++; $display("[COV] L2TLBWrapper.boreChildrenBd_bore_1_outdata[73] 未见过 0 和 1"); end
    if (!(w_s0_boreChildrenBd_bore_1_outdata[74] && w_s1_boreChildrenBd_bore_1_outdata[74])) begin cov_fail++; $display("[COV] L2TLBWrapper.boreChildrenBd_bore_1_outdata[74] 未见过 0 和 1"); end
    if (!(w_s0_boreChildrenBd_bore_1_outdata[75] && w_s1_boreChildrenBd_bore_1_outdata[75])) begin cov_fail++; $display("[COV] L2TLBWrapper.boreChildrenBd_bore_1_outdata[75] 未见过 0 和 1"); end
    if (!(w_s0_boreChildrenBd_bore_1_outdata[76] && w_s1_boreChildrenBd_bore_1_outdata[76])) begin cov_fail++; $display("[COV] L2TLBWrapper.boreChildrenBd_bore_1_outdata[76] 未见过 0 和 1"); end
    if (!(w_s0_boreChildrenBd_bore_1_outdata[77] && w_s1_boreChildrenBd_bore_1_outdata[77])) begin cov_fail++; $display("[COV] L2TLBWrapper.boreChildrenBd_bore_1_outdata[77] 未见过 0 和 1"); end
    if (!(w_s0_boreChildrenBd_bore_1_outdata[78] && w_s1_boreChildrenBd_bore_1_outdata[78])) begin cov_fail++; $display("[COV] L2TLBWrapper.boreChildrenBd_bore_1_outdata[78] 未见过 0 和 1"); end
    if (!(w_s0_boreChildrenBd_bore_1_outdata[79] && w_s1_boreChildrenBd_bore_1_outdata[79])) begin cov_fail++; $display("[COV] L2TLBWrapper.boreChildrenBd_bore_1_outdata[79] 未见过 0 和 1"); end
    if (!(w_s0_boreChildrenBd_bore_1_outdata[80] && w_s1_boreChildrenBd_bore_1_outdata[80])) begin cov_fail++; $display("[COV] L2TLBWrapper.boreChildrenBd_bore_1_outdata[80] 未见过 0 和 1"); end
    if (!(w_s0_boreChildrenBd_bore_1_outdata[81] && w_s1_boreChildrenBd_bore_1_outdata[81])) begin cov_fail++; $display("[COV] L2TLBWrapper.boreChildrenBd_bore_1_outdata[81] 未见过 0 和 1"); end
    if (!(w_s0_boreChildrenBd_bore_1_outdata[82] && w_s1_boreChildrenBd_bore_1_outdata[82])) begin cov_fail++; $display("[COV] L2TLBWrapper.boreChildrenBd_bore_1_outdata[82] 未见过 0 和 1"); end
    if (!(w_s0_boreChildrenBd_bore_1_outdata[83] && w_s1_boreChildrenBd_bore_1_outdata[83])) begin cov_fail++; $display("[COV] L2TLBWrapper.boreChildrenBd_bore_1_outdata[83] 未见过 0 和 1"); end
    if (!(w_s0_boreChildrenBd_bore_1_outdata[84] && w_s1_boreChildrenBd_bore_1_outdata[84])) begin cov_fail++; $display("[COV] L2TLBWrapper.boreChildrenBd_bore_1_outdata[84] 未见过 0 和 1"); end
    if (!(w_s0_boreChildrenBd_bore_1_outdata[85] && w_s1_boreChildrenBd_bore_1_outdata[85])) begin cov_fail++; $display("[COV] L2TLBWrapper.boreChildrenBd_bore_1_outdata[85] 未见过 0 和 1"); end
    if (!(w_s0_boreChildrenBd_bore_1_outdata[86] && w_s1_boreChildrenBd_bore_1_outdata[86])) begin cov_fail++; $display("[COV] L2TLBWrapper.boreChildrenBd_bore_1_outdata[86] 未见过 0 和 1"); end
    if (!(w_s0_boreChildrenBd_bore_1_outdata[87] && w_s1_boreChildrenBd_bore_1_outdata[87])) begin cov_fail++; $display("[COV] L2TLBWrapper.boreChildrenBd_bore_1_outdata[87] 未见过 0 和 1"); end
    if (!(w_s0_boreChildrenBd_bore_1_outdata[88] && w_s1_boreChildrenBd_bore_1_outdata[88])) begin cov_fail++; $display("[COV] L2TLBWrapper.boreChildrenBd_bore_1_outdata[88] 未见过 0 和 1"); end
    if (!(w_s0_boreChildrenBd_bore_1_outdata[89] && w_s1_boreChildrenBd_bore_1_outdata[89])) begin cov_fail++; $display("[COV] L2TLBWrapper.boreChildrenBd_bore_1_outdata[89] 未见过 0 和 1"); end
    if (!(w_s0_boreChildrenBd_bore_1_outdata[90] && w_s1_boreChildrenBd_bore_1_outdata[90])) begin cov_fail++; $display("[COV] L2TLBWrapper.boreChildrenBd_bore_1_outdata[90] 未见过 0 和 1"); end
    if (!(w_s0_boreChildrenBd_bore_1_outdata[91] && w_s1_boreChildrenBd_bore_1_outdata[91])) begin cov_fail++; $display("[COV] L2TLBWrapper.boreChildrenBd_bore_1_outdata[91] 未见过 0 和 1"); end
    if (!(w_s0_boreChildrenBd_bore_1_outdata[92] && w_s1_boreChildrenBd_bore_1_outdata[92])) begin cov_fail++; $display("[COV] L2TLBWrapper.boreChildrenBd_bore_1_outdata[92] 未见过 0 和 1"); end
    if (!(w_s0_boreChildrenBd_bore_1_outdata[93] && w_s1_boreChildrenBd_bore_1_outdata[93])) begin cov_fail++; $display("[COV] L2TLBWrapper.boreChildrenBd_bore_1_outdata[93] 未见过 0 和 1"); end
    if (!(w_s0_boreChildrenBd_bore_1_outdata[94] && w_s1_boreChildrenBd_bore_1_outdata[94])) begin cov_fail++; $display("[COV] L2TLBWrapper.boreChildrenBd_bore_1_outdata[94] 未见过 0 和 1"); end
    if (!(w_s0_boreChildrenBd_bore_1_outdata[95] && w_s1_boreChildrenBd_bore_1_outdata[95])) begin cov_fail++; $display("[COV] L2TLBWrapper.boreChildrenBd_bore_1_outdata[95] 未见过 0 和 1"); end
    if (!(w_s0_boreChildrenBd_bore_1_outdata[96] && w_s1_boreChildrenBd_bore_1_outdata[96])) begin cov_fail++; $display("[COV] L2TLBWrapper.boreChildrenBd_bore_1_outdata[96] 未见过 0 和 1"); end
    if (!(w_s0_boreChildrenBd_bore_1_outdata[97] && w_s1_boreChildrenBd_bore_1_outdata[97])) begin cov_fail++; $display("[COV] L2TLBWrapper.boreChildrenBd_bore_1_outdata[97] 未见过 0 和 1"); end
    if (!(w_s0_boreChildrenBd_bore_1_outdata[98] && w_s1_boreChildrenBd_bore_1_outdata[98])) begin cov_fail++; $display("[COV] L2TLBWrapper.boreChildrenBd_bore_1_outdata[98] 未见过 0 和 1"); end
    if (!(w_s0_boreChildrenBd_bore_1_outdata[99] && w_s1_boreChildrenBd_bore_1_outdata[99])) begin cov_fail++; $display("[COV] L2TLBWrapper.boreChildrenBd_bore_1_outdata[99] 未见过 0 和 1"); end
    if (!(w_s0_boreChildrenBd_bore_1_outdata[100] && w_s1_boreChildrenBd_bore_1_outdata[100])) begin cov_fail++; $display("[COV] L2TLBWrapper.boreChildrenBd_bore_1_outdata[100] 未见过 0 和 1"); end
    if (!(w_s0_boreChildrenBd_bore_1_outdata[101] && w_s1_boreChildrenBd_bore_1_outdata[101])) begin cov_fail++; $display("[COV] L2TLBWrapper.boreChildrenBd_bore_1_outdata[101] 未见过 0 和 1"); end
    if (!(w_s0_boreChildrenBd_bore_1_outdata[102] && w_s1_boreChildrenBd_bore_1_outdata[102])) begin cov_fail++; $display("[COV] L2TLBWrapper.boreChildrenBd_bore_1_outdata[102] 未见过 0 和 1"); end
    if (!(w_s0_boreChildrenBd_bore_1_outdata[103] && w_s1_boreChildrenBd_bore_1_outdata[103])) begin cov_fail++; $display("[COV] L2TLBWrapper.boreChildrenBd_bore_1_outdata[103] 未见过 0 和 1"); end
    if (!(w_s0_boreChildrenBd_bore_1_outdata[104] && w_s1_boreChildrenBd_bore_1_outdata[104])) begin cov_fail++; $display("[COV] L2TLBWrapper.boreChildrenBd_bore_1_outdata[104] 未见过 0 和 1"); end
    if (!(w_s0_boreChildrenBd_bore_1_outdata[105] && w_s1_boreChildrenBd_bore_1_outdata[105])) begin cov_fail++; $display("[COV] L2TLBWrapper.boreChildrenBd_bore_1_outdata[105] 未见过 0 和 1"); end
    if (!(w_s0_boreChildrenBd_bore_1_outdata[106] && w_s1_boreChildrenBd_bore_1_outdata[106])) begin cov_fail++; $display("[COV] L2TLBWrapper.boreChildrenBd_bore_1_outdata[106] 未见过 0 和 1"); end
    if (!(w_s0_boreChildrenBd_bore_1_outdata[107] && w_s1_boreChildrenBd_bore_1_outdata[107])) begin cov_fail++; $display("[COV] L2TLBWrapper.boreChildrenBd_bore_1_outdata[107] 未见过 0 和 1"); end
    if (!(w_s0_boreChildrenBd_bore_1_outdata[108] && w_s1_boreChildrenBd_bore_1_outdata[108])) begin cov_fail++; $display("[COV] L2TLBWrapper.boreChildrenBd_bore_1_outdata[108] 未见过 0 和 1"); end
    if (!(w_s0_boreChildrenBd_bore_1_outdata[109] && w_s1_boreChildrenBd_bore_1_outdata[109])) begin cov_fail++; $display("[COV] L2TLBWrapper.boreChildrenBd_bore_1_outdata[109] 未见过 0 和 1"); end
    if (!(w_s0_boreChildrenBd_bore_1_outdata[110] && w_s1_boreChildrenBd_bore_1_outdata[110])) begin cov_fail++; $display("[COV] L2TLBWrapper.boreChildrenBd_bore_1_outdata[110] 未见过 0 和 1"); end
    if (!(w_s0_boreChildrenBd_bore_1_outdata[111] && w_s1_boreChildrenBd_bore_1_outdata[111])) begin cov_fail++; $display("[COV] L2TLBWrapper.boreChildrenBd_bore_1_outdata[111] 未见过 0 和 1"); end
    if (!(w_s0_boreChildrenBd_bore_1_outdata[112] && w_s1_boreChildrenBd_bore_1_outdata[112])) begin cov_fail++; $display("[COV] L2TLBWrapper.boreChildrenBd_bore_1_outdata[112] 未见过 0 和 1"); end
    if (!(w_s0_boreChildrenBd_bore_1_outdata[113] && w_s1_boreChildrenBd_bore_1_outdata[113])) begin cov_fail++; $display("[COV] L2TLBWrapper.boreChildrenBd_bore_1_outdata[113] 未见过 0 和 1"); end
    if (!(w_s0_boreChildrenBd_bore_1_outdata[114] && w_s1_boreChildrenBd_bore_1_outdata[114])) begin cov_fail++; $display("[COV] L2TLBWrapper.boreChildrenBd_bore_1_outdata[114] 未见过 0 和 1"); end
    if (!(w_s0_boreChildrenBd_bore_1_outdata[115] && w_s1_boreChildrenBd_bore_1_outdata[115])) begin cov_fail++; $display("[COV] L2TLBWrapper.boreChildrenBd_bore_1_outdata[115] 未见过 0 和 1"); end
    if (!(w_s0_boreChildrenBd_bore_1_outdata[116] && w_s1_boreChildrenBd_bore_1_outdata[116])) begin cov_fail++; $display("[COV] L2TLBWrapper.boreChildrenBd_bore_1_outdata[116] 未见过 0 和 1"); end
    if (!(w_s0_boreChildrenBd_bore_1_outdata[117] && w_s1_boreChildrenBd_bore_1_outdata[117])) begin cov_fail++; $display("[COV] L2TLBWrapper.boreChildrenBd_bore_1_outdata[117] 未见过 0 和 1"); end
    if (!(w_s0_boreChildrenBd_bore_1_outdata[118] && w_s1_boreChildrenBd_bore_1_outdata[118])) begin cov_fail++; $display("[COV] L2TLBWrapper.boreChildrenBd_bore_1_outdata[118] 未见过 0 和 1"); end
    if (!(w_s0_boreChildrenBd_bore_1_outdata[119] && w_s1_boreChildrenBd_bore_1_outdata[119])) begin cov_fail++; $display("[COV] L2TLBWrapper.boreChildrenBd_bore_1_outdata[119] 未见过 0 和 1"); end
    if (!(w_s0_boreChildrenBd_bore_1_outdata[120] && w_s1_boreChildrenBd_bore_1_outdata[120])) begin cov_fail++; $display("[COV] L2TLBWrapper.boreChildrenBd_bore_1_outdata[120] 未见过 0 和 1"); end
    if (!(w_s0_boreChildrenBd_bore_1_outdata[121] && w_s1_boreChildrenBd_bore_1_outdata[121])) begin cov_fail++; $display("[COV] L2TLBWrapper.boreChildrenBd_bore_1_outdata[121] 未见过 0 和 1"); end
    if (!(w_s0_boreChildrenBd_bore_1_outdata[122] && w_s1_boreChildrenBd_bore_1_outdata[122])) begin cov_fail++; $display("[COV] L2TLBWrapper.boreChildrenBd_bore_1_outdata[122] 未见过 0 和 1"); end
    if (!(w_s0_boreChildrenBd_bore_1_outdata[123] && w_s1_boreChildrenBd_bore_1_outdata[123])) begin cov_fail++; $display("[COV] L2TLBWrapper.boreChildrenBd_bore_1_outdata[123] 未见过 0 和 1"); end
    if (!(w_s0_boreChildrenBd_bore_1_outdata[124] && w_s1_boreChildrenBd_bore_1_outdata[124])) begin cov_fail++; $display("[COV] L2TLBWrapper.boreChildrenBd_bore_1_outdata[124] 未见过 0 和 1"); end
    if (!(w_s0_boreChildrenBd_bore_1_outdata[125] && w_s1_boreChildrenBd_bore_1_outdata[125])) begin cov_fail++; $display("[COV] L2TLBWrapper.boreChildrenBd_bore_1_outdata[125] 未见过 0 和 1"); end
    if (!(w_s0_boreChildrenBd_bore_1_outdata[126] && w_s1_boreChildrenBd_bore_1_outdata[126])) begin cov_fail++; $display("[COV] L2TLBWrapper.boreChildrenBd_bore_1_outdata[126] 未见过 0 和 1"); end
    if (!(w_s0_boreChildrenBd_bore_1_outdata[127] && w_s1_boreChildrenBd_bore_1_outdata[127])) begin cov_fail++; $display("[COV] L2TLBWrapper.boreChildrenBd_bore_1_outdata[127] 未见过 0 和 1"); end
    if (!(w_s0_boreChildrenBd_bore_1_outdata[128] && w_s1_boreChildrenBd_bore_1_outdata[128])) begin cov_fail++; $display("[COV] L2TLBWrapper.boreChildrenBd_bore_1_outdata[128] 未见过 0 和 1"); end
    if (!(w_s0_boreChildrenBd_bore_1_outdata[129] && w_s1_boreChildrenBd_bore_1_outdata[129])) begin cov_fail++; $display("[COV] L2TLBWrapper.boreChildrenBd_bore_1_outdata[129] 未见过 0 和 1"); end
    if (!(w_s0_boreChildrenBd_bore_1_outdata[130] && w_s1_boreChildrenBd_bore_1_outdata[130])) begin cov_fail++; $display("[COV] L2TLBWrapper.boreChildrenBd_bore_1_outdata[130] 未见过 0 和 1"); end
    if (!(w_s0_boreChildrenBd_bore_2_ack && w_s1_boreChildrenBd_bore_2_ack)) begin cov_fail++; $display("[COV] L2TLBWrapper.boreChildrenBd_bore_2_ack 未见过 0 和 1"); end
    if (!(w_s0_boreChildrenBd_bore_2_outdata[0] && w_s1_boreChildrenBd_bore_2_outdata[0])) begin cov_fail++; $display("[COV] L2TLBWrapper.boreChildrenBd_bore_2_outdata[0] 未见过 0 和 1"); end
    if (!(w_s0_boreChildrenBd_bore_2_outdata[1] && w_s1_boreChildrenBd_bore_2_outdata[1])) begin cov_fail++; $display("[COV] L2TLBWrapper.boreChildrenBd_bore_2_outdata[1] 未见过 0 和 1"); end
    if (!(w_s0_boreChildrenBd_bore_2_outdata[2] && w_s1_boreChildrenBd_bore_2_outdata[2])) begin cov_fail++; $display("[COV] L2TLBWrapper.boreChildrenBd_bore_2_outdata[2] 未见过 0 和 1"); end
    if (!(w_s0_boreChildrenBd_bore_2_outdata[3] && w_s1_boreChildrenBd_bore_2_outdata[3])) begin cov_fail++; $display("[COV] L2TLBWrapper.boreChildrenBd_bore_2_outdata[3] 未见过 0 和 1"); end
    if (!(w_s0_boreChildrenBd_bore_2_outdata[4] && w_s1_boreChildrenBd_bore_2_outdata[4])) begin cov_fail++; $display("[COV] L2TLBWrapper.boreChildrenBd_bore_2_outdata[4] 未见过 0 和 1"); end
    if (!(w_s0_boreChildrenBd_bore_2_outdata[5] && w_s1_boreChildrenBd_bore_2_outdata[5])) begin cov_fail++; $display("[COV] L2TLBWrapper.boreChildrenBd_bore_2_outdata[5] 未见过 0 和 1"); end
    if (!(w_s0_boreChildrenBd_bore_2_outdata[6] && w_s1_boreChildrenBd_bore_2_outdata[6])) begin cov_fail++; $display("[COV] L2TLBWrapper.boreChildrenBd_bore_2_outdata[6] 未见过 0 和 1"); end
    if (!(w_s0_boreChildrenBd_bore_2_outdata[7] && w_s1_boreChildrenBd_bore_2_outdata[7])) begin cov_fail++; $display("[COV] L2TLBWrapper.boreChildrenBd_bore_2_outdata[7] 未见过 0 和 1"); end
    if (!(w_s0_boreChildrenBd_bore_2_outdata[8] && w_s1_boreChildrenBd_bore_2_outdata[8])) begin cov_fail++; $display("[COV] L2TLBWrapper.boreChildrenBd_bore_2_outdata[8] 未见过 0 和 1"); end
    if (!(w_s0_boreChildrenBd_bore_2_outdata[9] && w_s1_boreChildrenBd_bore_2_outdata[9])) begin cov_fail++; $display("[COV] L2TLBWrapper.boreChildrenBd_bore_2_outdata[9] 未见过 0 和 1"); end
    if (!(w_s0_boreChildrenBd_bore_2_outdata[10] && w_s1_boreChildrenBd_bore_2_outdata[10])) begin cov_fail++; $display("[COV] L2TLBWrapper.boreChildrenBd_bore_2_outdata[10] 未见过 0 和 1"); end
    if (!(w_s0_boreChildrenBd_bore_2_outdata[11] && w_s1_boreChildrenBd_bore_2_outdata[11])) begin cov_fail++; $display("[COV] L2TLBWrapper.boreChildrenBd_bore_2_outdata[11] 未见过 0 和 1"); end
    if (!(w_s0_boreChildrenBd_bore_2_outdata[12] && w_s1_boreChildrenBd_bore_2_outdata[12])) begin cov_fail++; $display("[COV] L2TLBWrapper.boreChildrenBd_bore_2_outdata[12] 未见过 0 和 1"); end
    if (!(w_s0_boreChildrenBd_bore_2_outdata[13] && w_s1_boreChildrenBd_bore_2_outdata[13])) begin cov_fail++; $display("[COV] L2TLBWrapper.boreChildrenBd_bore_2_outdata[13] 未见过 0 和 1"); end
    if (!(w_s0_boreChildrenBd_bore_2_outdata[14] && w_s1_boreChildrenBd_bore_2_outdata[14])) begin cov_fail++; $display("[COV] L2TLBWrapper.boreChildrenBd_bore_2_outdata[14] 未见过 0 和 1"); end
    if (!(w_s0_boreChildrenBd_bore_2_outdata[15] && w_s1_boreChildrenBd_bore_2_outdata[15])) begin cov_fail++; $display("[COV] L2TLBWrapper.boreChildrenBd_bore_2_outdata[15] 未见过 0 和 1"); end
    if (!(w_s0_boreChildrenBd_bore_2_outdata[16] && w_s1_boreChildrenBd_bore_2_outdata[16])) begin cov_fail++; $display("[COV] L2TLBWrapper.boreChildrenBd_bore_2_outdata[16] 未见过 0 和 1"); end
    if (!(w_s0_boreChildrenBd_bore_2_outdata[17] && w_s1_boreChildrenBd_bore_2_outdata[17])) begin cov_fail++; $display("[COV] L2TLBWrapper.boreChildrenBd_bore_2_outdata[17] 未见过 0 和 1"); end
    if (!(w_s0_boreChildrenBd_bore_2_outdata[18] && w_s1_boreChildrenBd_bore_2_outdata[18])) begin cov_fail++; $display("[COV] L2TLBWrapper.boreChildrenBd_bore_2_outdata[18] 未见过 0 和 1"); end
    if (!(w_s0_boreChildrenBd_bore_2_outdata[19] && w_s1_boreChildrenBd_bore_2_outdata[19])) begin cov_fail++; $display("[COV] L2TLBWrapper.boreChildrenBd_bore_2_outdata[19] 未见过 0 和 1"); end
    if (!(w_s0_boreChildrenBd_bore_2_outdata[20] && w_s1_boreChildrenBd_bore_2_outdata[20])) begin cov_fail++; $display("[COV] L2TLBWrapper.boreChildrenBd_bore_2_outdata[20] 未见过 0 和 1"); end
    if (!(w_s0_boreChildrenBd_bore_2_outdata[21] && w_s1_boreChildrenBd_bore_2_outdata[21])) begin cov_fail++; $display("[COV] L2TLBWrapper.boreChildrenBd_bore_2_outdata[21] 未见过 0 和 1"); end
    if (!(w_s0_boreChildrenBd_bore_2_outdata[22] && w_s1_boreChildrenBd_bore_2_outdata[22])) begin cov_fail++; $display("[COV] L2TLBWrapper.boreChildrenBd_bore_2_outdata[22] 未见过 0 和 1"); end
    if (!(w_s0_boreChildrenBd_bore_2_outdata[23] && w_s1_boreChildrenBd_bore_2_outdata[23])) begin cov_fail++; $display("[COV] L2TLBWrapper.boreChildrenBd_bore_2_outdata[23] 未见过 0 和 1"); end
    if (!(w_s0_boreChildrenBd_bore_2_outdata[24] && w_s1_boreChildrenBd_bore_2_outdata[24])) begin cov_fail++; $display("[COV] L2TLBWrapper.boreChildrenBd_bore_2_outdata[24] 未见过 0 和 1"); end
    if (!(w_s0_boreChildrenBd_bore_2_outdata[25] && w_s1_boreChildrenBd_bore_2_outdata[25])) begin cov_fail++; $display("[COV] L2TLBWrapper.boreChildrenBd_bore_2_outdata[25] 未见过 0 和 1"); end
    if (!(w_s0_boreChildrenBd_bore_2_outdata[26] && w_s1_boreChildrenBd_bore_2_outdata[26])) begin cov_fail++; $display("[COV] L2TLBWrapper.boreChildrenBd_bore_2_outdata[26] 未见过 0 和 1"); end
    if (!(w_s0_boreChildrenBd_bore_2_outdata[27] && w_s1_boreChildrenBd_bore_2_outdata[27])) begin cov_fail++; $display("[COV] L2TLBWrapper.boreChildrenBd_bore_2_outdata[27] 未见过 0 和 1"); end
    if (!(w_s0_boreChildrenBd_bore_2_outdata[28] && w_s1_boreChildrenBd_bore_2_outdata[28])) begin cov_fail++; $display("[COV] L2TLBWrapper.boreChildrenBd_bore_2_outdata[28] 未见过 0 和 1"); end
    if (!(w_s0_boreChildrenBd_bore_2_outdata[29] && w_s1_boreChildrenBd_bore_2_outdata[29])) begin cov_fail++; $display("[COV] L2TLBWrapper.boreChildrenBd_bore_2_outdata[29] 未见过 0 和 1"); end
    if (!(w_s0_boreChildrenBd_bore_2_outdata[30] && w_s1_boreChildrenBd_bore_2_outdata[30])) begin cov_fail++; $display("[COV] L2TLBWrapper.boreChildrenBd_bore_2_outdata[30] 未见过 0 和 1"); end
    if (!(w_s0_boreChildrenBd_bore_2_outdata[31] && w_s1_boreChildrenBd_bore_2_outdata[31])) begin cov_fail++; $display("[COV] L2TLBWrapper.boreChildrenBd_bore_2_outdata[31] 未见过 0 和 1"); end
    if (!(w_s0_boreChildrenBd_bore_2_outdata[32] && w_s1_boreChildrenBd_bore_2_outdata[32])) begin cov_fail++; $display("[COV] L2TLBWrapper.boreChildrenBd_bore_2_outdata[32] 未见过 0 和 1"); end
    if (!(w_s0_boreChildrenBd_bore_2_outdata[33] && w_s1_boreChildrenBd_bore_2_outdata[33])) begin cov_fail++; $display("[COV] L2TLBWrapper.boreChildrenBd_bore_2_outdata[33] 未见过 0 和 1"); end
    if (!(w_s0_boreChildrenBd_bore_2_outdata[34] && w_s1_boreChildrenBd_bore_2_outdata[34])) begin cov_fail++; $display("[COV] L2TLBWrapper.boreChildrenBd_bore_2_outdata[34] 未见过 0 和 1"); end
    if (!(w_s0_boreChildrenBd_bore_2_outdata[35] && w_s1_boreChildrenBd_bore_2_outdata[35])) begin cov_fail++; $display("[COV] L2TLBWrapper.boreChildrenBd_bore_2_outdata[35] 未见过 0 和 1"); end
    if (!(w_s0_boreChildrenBd_bore_2_outdata[36] && w_s1_boreChildrenBd_bore_2_outdata[36])) begin cov_fail++; $display("[COV] L2TLBWrapper.boreChildrenBd_bore_2_outdata[36] 未见过 0 和 1"); end
    if (!(w_s0_boreChildrenBd_bore_2_outdata[37] && w_s1_boreChildrenBd_bore_2_outdata[37])) begin cov_fail++; $display("[COV] L2TLBWrapper.boreChildrenBd_bore_2_outdata[37] 未见过 0 和 1"); end
    if (!(w_s0_boreChildrenBd_bore_2_outdata[38] && w_s1_boreChildrenBd_bore_2_outdata[38])) begin cov_fail++; $display("[COV] L2TLBWrapper.boreChildrenBd_bore_2_outdata[38] 未见过 0 和 1"); end
    if (!(w_s0_boreChildrenBd_bore_2_outdata[39] && w_s1_boreChildrenBd_bore_2_outdata[39])) begin cov_fail++; $display("[COV] L2TLBWrapper.boreChildrenBd_bore_2_outdata[39] 未见过 0 和 1"); end
    if (!(w_s0_boreChildrenBd_bore_2_outdata[40] && w_s1_boreChildrenBd_bore_2_outdata[40])) begin cov_fail++; $display("[COV] L2TLBWrapper.boreChildrenBd_bore_2_outdata[40] 未见过 0 和 1"); end
    if (!(w_s0_boreChildrenBd_bore_2_outdata[41] && w_s1_boreChildrenBd_bore_2_outdata[41])) begin cov_fail++; $display("[COV] L2TLBWrapper.boreChildrenBd_bore_2_outdata[41] 未见过 0 和 1"); end
    if (!(w_s0_boreChildrenBd_bore_2_outdata[42] && w_s1_boreChildrenBd_bore_2_outdata[42])) begin cov_fail++; $display("[COV] L2TLBWrapper.boreChildrenBd_bore_2_outdata[42] 未见过 0 和 1"); end
    if (!(w_s0_boreChildrenBd_bore_2_outdata[43] && w_s1_boreChildrenBd_bore_2_outdata[43])) begin cov_fail++; $display("[COV] L2TLBWrapper.boreChildrenBd_bore_2_outdata[43] 未见过 0 和 1"); end
    if (!(w_s0_boreChildrenBd_bore_2_outdata[44] && w_s1_boreChildrenBd_bore_2_outdata[44])) begin cov_fail++; $display("[COV] L2TLBWrapper.boreChildrenBd_bore_2_outdata[44] 未见过 0 和 1"); end
    if (!(w_s0_boreChildrenBd_bore_2_outdata[45] && w_s1_boreChildrenBd_bore_2_outdata[45])) begin cov_fail++; $display("[COV] L2TLBWrapper.boreChildrenBd_bore_2_outdata[45] 未见过 0 和 1"); end
    if (!(w_s0_boreChildrenBd_bore_2_outdata[46] && w_s1_boreChildrenBd_bore_2_outdata[46])) begin cov_fail++; $display("[COV] L2TLBWrapper.boreChildrenBd_bore_2_outdata[46] 未见过 0 和 1"); end
    if (!(w_s0_boreChildrenBd_bore_2_outdata[47] && w_s1_boreChildrenBd_bore_2_outdata[47])) begin cov_fail++; $display("[COV] L2TLBWrapper.boreChildrenBd_bore_2_outdata[47] 未见过 0 和 1"); end
    if (!(w_s0_boreChildrenBd_bore_2_outdata[48] && w_s1_boreChildrenBd_bore_2_outdata[48])) begin cov_fail++; $display("[COV] L2TLBWrapper.boreChildrenBd_bore_2_outdata[48] 未见过 0 和 1"); end
    if (!(w_s0_boreChildrenBd_bore_2_outdata[49] && w_s1_boreChildrenBd_bore_2_outdata[49])) begin cov_fail++; $display("[COV] L2TLBWrapper.boreChildrenBd_bore_2_outdata[49] 未见过 0 和 1"); end
    if (!(w_s0_boreChildrenBd_bore_2_outdata[50] && w_s1_boreChildrenBd_bore_2_outdata[50])) begin cov_fail++; $display("[COV] L2TLBWrapper.boreChildrenBd_bore_2_outdata[50] 未见过 0 和 1"); end
    if (!(w_s0_boreChildrenBd_bore_2_outdata[51] && w_s1_boreChildrenBd_bore_2_outdata[51])) begin cov_fail++; $display("[COV] L2TLBWrapper.boreChildrenBd_bore_2_outdata[51] 未见过 0 和 1"); end
    if (!(w_s0_boreChildrenBd_bore_2_outdata[52] && w_s1_boreChildrenBd_bore_2_outdata[52])) begin cov_fail++; $display("[COV] L2TLBWrapper.boreChildrenBd_bore_2_outdata[52] 未见过 0 和 1"); end
    if (!(w_s0_boreChildrenBd_bore_2_outdata[53] && w_s1_boreChildrenBd_bore_2_outdata[53])) begin cov_fail++; $display("[COV] L2TLBWrapper.boreChildrenBd_bore_2_outdata[53] 未见过 0 和 1"); end
    if (!(w_s0_boreChildrenBd_bore_2_outdata[54] && w_s1_boreChildrenBd_bore_2_outdata[54])) begin cov_fail++; $display("[COV] L2TLBWrapper.boreChildrenBd_bore_2_outdata[54] 未见过 0 和 1"); end
    if (!(w_s0_boreChildrenBd_bore_2_outdata[55] && w_s1_boreChildrenBd_bore_2_outdata[55])) begin cov_fail++; $display("[COV] L2TLBWrapper.boreChildrenBd_bore_2_outdata[55] 未见过 0 和 1"); end
    if (!(w_s0_boreChildrenBd_bore_2_outdata[56] && w_s1_boreChildrenBd_bore_2_outdata[56])) begin cov_fail++; $display("[COV] L2TLBWrapper.boreChildrenBd_bore_2_outdata[56] 未见过 0 和 1"); end
    if (!(w_s0_boreChildrenBd_bore_2_outdata[57] && w_s1_boreChildrenBd_bore_2_outdata[57])) begin cov_fail++; $display("[COV] L2TLBWrapper.boreChildrenBd_bore_2_outdata[57] 未见过 0 和 1"); end
    if (!(w_s0_boreChildrenBd_bore_2_outdata[58] && w_s1_boreChildrenBd_bore_2_outdata[58])) begin cov_fail++; $display("[COV] L2TLBWrapper.boreChildrenBd_bore_2_outdata[58] 未见过 0 和 1"); end
    if (!(w_s0_boreChildrenBd_bore_2_outdata[59] && w_s1_boreChildrenBd_bore_2_outdata[59])) begin cov_fail++; $display("[COV] L2TLBWrapper.boreChildrenBd_bore_2_outdata[59] 未见过 0 和 1"); end
    if (!(w_s0_boreChildrenBd_bore_2_outdata[60] && w_s1_boreChildrenBd_bore_2_outdata[60])) begin cov_fail++; $display("[COV] L2TLBWrapper.boreChildrenBd_bore_2_outdata[60] 未见过 0 和 1"); end
    if (!(w_s0_boreChildrenBd_bore_2_outdata[61] && w_s1_boreChildrenBd_bore_2_outdata[61])) begin cov_fail++; $display("[COV] L2TLBWrapper.boreChildrenBd_bore_2_outdata[61] 未见过 0 和 1"); end
    if (!(w_s0_boreChildrenBd_bore_2_outdata[62] && w_s1_boreChildrenBd_bore_2_outdata[62])) begin cov_fail++; $display("[COV] L2TLBWrapper.boreChildrenBd_bore_2_outdata[62] 未见过 0 和 1"); end
    if (!(w_s0_boreChildrenBd_bore_2_outdata[63] && w_s1_boreChildrenBd_bore_2_outdata[63])) begin cov_fail++; $display("[COV] L2TLBWrapper.boreChildrenBd_bore_2_outdata[63] 未见过 0 和 1"); end
    if (!(w_s0_boreChildrenBd_bore_2_outdata[64] && w_s1_boreChildrenBd_bore_2_outdata[64])) begin cov_fail++; $display("[COV] L2TLBWrapper.boreChildrenBd_bore_2_outdata[64] 未见过 0 和 1"); end
    if (!(w_s0_boreChildrenBd_bore_2_outdata[65] && w_s1_boreChildrenBd_bore_2_outdata[65])) begin cov_fail++; $display("[COV] L2TLBWrapper.boreChildrenBd_bore_2_outdata[65] 未见过 0 和 1"); end
    if (!(w_s0_boreChildrenBd_bore_2_outdata[66] && w_s1_boreChildrenBd_bore_2_outdata[66])) begin cov_fail++; $display("[COV] L2TLBWrapper.boreChildrenBd_bore_2_outdata[66] 未见过 0 和 1"); end
    if (!(w_s0_boreChildrenBd_bore_2_outdata[67] && w_s1_boreChildrenBd_bore_2_outdata[67])) begin cov_fail++; $display("[COV] L2TLBWrapper.boreChildrenBd_bore_2_outdata[67] 未见过 0 和 1"); end
    if (!(w_s0_boreChildrenBd_bore_2_outdata[68] && w_s1_boreChildrenBd_bore_2_outdata[68])) begin cov_fail++; $display("[COV] L2TLBWrapper.boreChildrenBd_bore_2_outdata[68] 未见过 0 和 1"); end
    if (!(w_s0_boreChildrenBd_bore_2_outdata[69] && w_s1_boreChildrenBd_bore_2_outdata[69])) begin cov_fail++; $display("[COV] L2TLBWrapper.boreChildrenBd_bore_2_outdata[69] 未见过 0 和 1"); end
    if (!(w_s0_boreChildrenBd_bore_2_outdata[70] && w_s1_boreChildrenBd_bore_2_outdata[70])) begin cov_fail++; $display("[COV] L2TLBWrapper.boreChildrenBd_bore_2_outdata[70] 未见过 0 和 1"); end
    if (!(w_s0_boreChildrenBd_bore_2_outdata[71] && w_s1_boreChildrenBd_bore_2_outdata[71])) begin cov_fail++; $display("[COV] L2TLBWrapper.boreChildrenBd_bore_2_outdata[71] 未见过 0 和 1"); end
    if (!(w_s0_boreChildrenBd_bore_2_outdata[72] && w_s1_boreChildrenBd_bore_2_outdata[72])) begin cov_fail++; $display("[COV] L2TLBWrapper.boreChildrenBd_bore_2_outdata[72] 未见过 0 和 1"); end
    if (!(w_s0_boreChildrenBd_bore_2_outdata[73] && w_s1_boreChildrenBd_bore_2_outdata[73])) begin cov_fail++; $display("[COV] L2TLBWrapper.boreChildrenBd_bore_2_outdata[73] 未见过 0 和 1"); end
    if (!(w_s0_boreChildrenBd_bore_2_outdata[74] && w_s1_boreChildrenBd_bore_2_outdata[74])) begin cov_fail++; $display("[COV] L2TLBWrapper.boreChildrenBd_bore_2_outdata[74] 未见过 0 和 1"); end
    if (!(w_s0_boreChildrenBd_bore_2_outdata[75] && w_s1_boreChildrenBd_bore_2_outdata[75])) begin cov_fail++; $display("[COV] L2TLBWrapper.boreChildrenBd_bore_2_outdata[75] 未见过 0 和 1"); end
    if (!(w_s0_boreChildrenBd_bore_2_outdata[76] && w_s1_boreChildrenBd_bore_2_outdata[76])) begin cov_fail++; $display("[COV] L2TLBWrapper.boreChildrenBd_bore_2_outdata[76] 未见过 0 和 1"); end
    if (!(w_s0_boreChildrenBd_bore_2_outdata[77] && w_s1_boreChildrenBd_bore_2_outdata[77])) begin cov_fail++; $display("[COV] L2TLBWrapper.boreChildrenBd_bore_2_outdata[77] 未见过 0 和 1"); end
    if (!(w_s0_boreChildrenBd_bore_2_outdata[78] && w_s1_boreChildrenBd_bore_2_outdata[78])) begin cov_fail++; $display("[COV] L2TLBWrapper.boreChildrenBd_bore_2_outdata[78] 未见过 0 和 1"); end
    if (!(w_s0_boreChildrenBd_bore_2_outdata[79] && w_s1_boreChildrenBd_bore_2_outdata[79])) begin cov_fail++; $display("[COV] L2TLBWrapper.boreChildrenBd_bore_2_outdata[79] 未见过 0 和 1"); end
    if (!(w_s0_boreChildrenBd_bore_2_outdata[80] && w_s1_boreChildrenBd_bore_2_outdata[80])) begin cov_fail++; $display("[COV] L2TLBWrapper.boreChildrenBd_bore_2_outdata[80] 未见过 0 和 1"); end
    if (!(w_s0_boreChildrenBd_bore_2_outdata[81] && w_s1_boreChildrenBd_bore_2_outdata[81])) begin cov_fail++; $display("[COV] L2TLBWrapper.boreChildrenBd_bore_2_outdata[81] 未见过 0 和 1"); end
    if (!(w_s0_boreChildrenBd_bore_2_outdata[82] && w_s1_boreChildrenBd_bore_2_outdata[82])) begin cov_fail++; $display("[COV] L2TLBWrapper.boreChildrenBd_bore_2_outdata[82] 未见过 0 和 1"); end
    if (!(w_s0_boreChildrenBd_bore_2_outdata[83] && w_s1_boreChildrenBd_bore_2_outdata[83])) begin cov_fail++; $display("[COV] L2TLBWrapper.boreChildrenBd_bore_2_outdata[83] 未见过 0 和 1"); end
    if (!(w_s0_boreChildrenBd_bore_2_outdata[84] && w_s1_boreChildrenBd_bore_2_outdata[84])) begin cov_fail++; $display("[COV] L2TLBWrapper.boreChildrenBd_bore_2_outdata[84] 未见过 0 和 1"); end
    if (!(w_s0_boreChildrenBd_bore_2_outdata[85] && w_s1_boreChildrenBd_bore_2_outdata[85])) begin cov_fail++; $display("[COV] L2TLBWrapper.boreChildrenBd_bore_2_outdata[85] 未见过 0 和 1"); end
    if (!(w_s0_boreChildrenBd_bore_2_outdata[86] && w_s1_boreChildrenBd_bore_2_outdata[86])) begin cov_fail++; $display("[COV] L2TLBWrapper.boreChildrenBd_bore_2_outdata[86] 未见过 0 和 1"); end
    if (!(w_s0_boreChildrenBd_bore_2_outdata[87] && w_s1_boreChildrenBd_bore_2_outdata[87])) begin cov_fail++; $display("[COV] L2TLBWrapper.boreChildrenBd_bore_2_outdata[87] 未见过 0 和 1"); end
    if (!(w_s0_boreChildrenBd_bore_2_outdata[88] && w_s1_boreChildrenBd_bore_2_outdata[88])) begin cov_fail++; $display("[COV] L2TLBWrapper.boreChildrenBd_bore_2_outdata[88] 未见过 0 和 1"); end
    if (!(w_s0_boreChildrenBd_bore_2_outdata[89] && w_s1_boreChildrenBd_bore_2_outdata[89])) begin cov_fail++; $display("[COV] L2TLBWrapper.boreChildrenBd_bore_2_outdata[89] 未见过 0 和 1"); end
    if (!(w_s0_boreChildrenBd_bore_2_outdata[90] && w_s1_boreChildrenBd_bore_2_outdata[90])) begin cov_fail++; $display("[COV] L2TLBWrapper.boreChildrenBd_bore_2_outdata[90] 未见过 0 和 1"); end
    if (!(w_s0_boreChildrenBd_bore_2_outdata[91] && w_s1_boreChildrenBd_bore_2_outdata[91])) begin cov_fail++; $display("[COV] L2TLBWrapper.boreChildrenBd_bore_2_outdata[91] 未见过 0 和 1"); end
    if (!(w_s0_boreChildrenBd_bore_2_outdata[92] && w_s1_boreChildrenBd_bore_2_outdata[92])) begin cov_fail++; $display("[COV] L2TLBWrapper.boreChildrenBd_bore_2_outdata[92] 未见过 0 和 1"); end
    if (!(w_s0_boreChildrenBd_bore_2_outdata[93] && w_s1_boreChildrenBd_bore_2_outdata[93])) begin cov_fail++; $display("[COV] L2TLBWrapper.boreChildrenBd_bore_2_outdata[93] 未见过 0 和 1"); end
    if (!(w_s0_boreChildrenBd_bore_2_outdata[94] && w_s1_boreChildrenBd_bore_2_outdata[94])) begin cov_fail++; $display("[COV] L2TLBWrapper.boreChildrenBd_bore_2_outdata[94] 未见过 0 和 1"); end
    if (!(w_s0_boreChildrenBd_bore_2_outdata[95] && w_s1_boreChildrenBd_bore_2_outdata[95])) begin cov_fail++; $display("[COV] L2TLBWrapper.boreChildrenBd_bore_2_outdata[95] 未见过 0 和 1"); end
    if (!(w_s0_boreChildrenBd_bore_2_outdata[96] && w_s1_boreChildrenBd_bore_2_outdata[96])) begin cov_fail++; $display("[COV] L2TLBWrapper.boreChildrenBd_bore_2_outdata[96] 未见过 0 和 1"); end
    if (!(w_s0_boreChildrenBd_bore_2_outdata[97] && w_s1_boreChildrenBd_bore_2_outdata[97])) begin cov_fail++; $display("[COV] L2TLBWrapper.boreChildrenBd_bore_2_outdata[97] 未见过 0 和 1"); end
    if (!(w_s0_boreChildrenBd_bore_2_outdata[98] && w_s1_boreChildrenBd_bore_2_outdata[98])) begin cov_fail++; $display("[COV] L2TLBWrapper.boreChildrenBd_bore_2_outdata[98] 未见过 0 和 1"); end
    if (!(w_s0_boreChildrenBd_bore_2_outdata[99] && w_s1_boreChildrenBd_bore_2_outdata[99])) begin cov_fail++; $display("[COV] L2TLBWrapper.boreChildrenBd_bore_2_outdata[99] 未见过 0 和 1"); end
    if (!(w_s0_boreChildrenBd_bore_2_outdata[100] && w_s1_boreChildrenBd_bore_2_outdata[100])) begin cov_fail++; $display("[COV] L2TLBWrapper.boreChildrenBd_bore_2_outdata[100] 未见过 0 和 1"); end
    if (!(w_s0_boreChildrenBd_bore_2_outdata[101] && w_s1_boreChildrenBd_bore_2_outdata[101])) begin cov_fail++; $display("[COV] L2TLBWrapper.boreChildrenBd_bore_2_outdata[101] 未见过 0 和 1"); end
    if (!(w_s0_boreChildrenBd_bore_2_outdata[102] && w_s1_boreChildrenBd_bore_2_outdata[102])) begin cov_fail++; $display("[COV] L2TLBWrapper.boreChildrenBd_bore_2_outdata[102] 未见过 0 和 1"); end
    if (!(w_s0_boreChildrenBd_bore_2_outdata[103] && w_s1_boreChildrenBd_bore_2_outdata[103])) begin cov_fail++; $display("[COV] L2TLBWrapper.boreChildrenBd_bore_2_outdata[103] 未见过 0 和 1"); end
    if (!(w_s0_boreChildrenBd_bore_2_outdata[104] && w_s1_boreChildrenBd_bore_2_outdata[104])) begin cov_fail++; $display("[COV] L2TLBWrapper.boreChildrenBd_bore_2_outdata[104] 未见过 0 和 1"); end
    if (!(w_s0_boreChildrenBd_bore_2_outdata[105] && w_s1_boreChildrenBd_bore_2_outdata[105])) begin cov_fail++; $display("[COV] L2TLBWrapper.boreChildrenBd_bore_2_outdata[105] 未见过 0 和 1"); end
    if (!(w_s0_boreChildrenBd_bore_2_outdata[106] && w_s1_boreChildrenBd_bore_2_outdata[106])) begin cov_fail++; $display("[COV] L2TLBWrapper.boreChildrenBd_bore_2_outdata[106] 未见过 0 和 1"); end
    if (!(w_s0_boreChildrenBd_bore_2_outdata[107] && w_s1_boreChildrenBd_bore_2_outdata[107])) begin cov_fail++; $display("[COV] L2TLBWrapper.boreChildrenBd_bore_2_outdata[107] 未见过 0 和 1"); end
    if (!(w_s0_boreChildrenBd_bore_2_outdata[108] && w_s1_boreChildrenBd_bore_2_outdata[108])) begin cov_fail++; $display("[COV] L2TLBWrapper.boreChildrenBd_bore_2_outdata[108] 未见过 0 和 1"); end
    if (!(w_s0_boreChildrenBd_bore_2_outdata[109] && w_s1_boreChildrenBd_bore_2_outdata[109])) begin cov_fail++; $display("[COV] L2TLBWrapper.boreChildrenBd_bore_2_outdata[109] 未见过 0 和 1"); end
    if (!(w_s0_boreChildrenBd_bore_2_outdata[110] && w_s1_boreChildrenBd_bore_2_outdata[110])) begin cov_fail++; $display("[COV] L2TLBWrapper.boreChildrenBd_bore_2_outdata[110] 未见过 0 和 1"); end
    if (!(w_s0_boreChildrenBd_bore_2_outdata[111] && w_s1_boreChildrenBd_bore_2_outdata[111])) begin cov_fail++; $display("[COV] L2TLBWrapper.boreChildrenBd_bore_2_outdata[111] 未见过 0 和 1"); end
    if (!(w_s0_boreChildrenBd_bore_2_outdata[112] && w_s1_boreChildrenBd_bore_2_outdata[112])) begin cov_fail++; $display("[COV] L2TLBWrapper.boreChildrenBd_bore_2_outdata[112] 未见过 0 和 1"); end
    if (!(w_s0_boreChildrenBd_bore_2_outdata[113] && w_s1_boreChildrenBd_bore_2_outdata[113])) begin cov_fail++; $display("[COV] L2TLBWrapper.boreChildrenBd_bore_2_outdata[113] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_43_bore[0] && w_s1_gatewayIn_packed_43_bore[0])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_43_bore[0] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_43_bore[1] && w_s1_gatewayIn_packed_43_bore[1])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_43_bore[1] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_43_bore[2] && w_s1_gatewayIn_packed_43_bore[2])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_43_bore[2] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_43_bore[3] && w_s1_gatewayIn_packed_43_bore[3])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_43_bore[3] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_43_bore[4] && w_s1_gatewayIn_packed_43_bore[4])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_43_bore[4] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_43_bore[5] && w_s1_gatewayIn_packed_43_bore[5])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_43_bore[5] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_43_bore[6] && w_s1_gatewayIn_packed_43_bore[6])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_43_bore[6] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_43_bore[7] && w_s1_gatewayIn_packed_43_bore[7])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_43_bore[7] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_43_bore[8] && w_s1_gatewayIn_packed_43_bore[8])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_43_bore[8] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_43_bore[9] && w_s1_gatewayIn_packed_43_bore[9])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_43_bore[9] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_43_bore[10] && w_s1_gatewayIn_packed_43_bore[10])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_43_bore[10] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_43_bore[11] && w_s1_gatewayIn_packed_43_bore[11])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_43_bore[11] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_43_bore[12] && w_s1_gatewayIn_packed_43_bore[12])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_43_bore[12] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_43_bore[13] && w_s1_gatewayIn_packed_43_bore[13])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_43_bore[13] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_43_bore[14] && w_s1_gatewayIn_packed_43_bore[14])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_43_bore[14] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_43_bore[15] && w_s1_gatewayIn_packed_43_bore[15])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_43_bore[15] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_43_bore[16] && w_s1_gatewayIn_packed_43_bore[16])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_43_bore[16] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_43_bore[17] && w_s1_gatewayIn_packed_43_bore[17])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_43_bore[17] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_43_bore[18] && w_s1_gatewayIn_packed_43_bore[18])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_43_bore[18] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_43_bore[19] && w_s1_gatewayIn_packed_43_bore[19])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_43_bore[19] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_43_bore[20] && w_s1_gatewayIn_packed_43_bore[20])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_43_bore[20] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_43_bore[21] && w_s1_gatewayIn_packed_43_bore[21])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_43_bore[21] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_43_bore[22] && w_s1_gatewayIn_packed_43_bore[22])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_43_bore[22] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_43_bore[23] && w_s1_gatewayIn_packed_43_bore[23])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_43_bore[23] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_43_bore[24] && w_s1_gatewayIn_packed_43_bore[24])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_43_bore[24] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_43_bore[25] && w_s1_gatewayIn_packed_43_bore[25])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_43_bore[25] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_43_bore[26] && w_s1_gatewayIn_packed_43_bore[26])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_43_bore[26] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_43_bore[27] && w_s1_gatewayIn_packed_43_bore[27])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_43_bore[27] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_43_bore[28] && w_s1_gatewayIn_packed_43_bore[28])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_43_bore[28] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_43_bore[29] && w_s1_gatewayIn_packed_43_bore[29])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_43_bore[29] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_43_bore[30] && w_s1_gatewayIn_packed_43_bore[30])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_43_bore[30] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_43_bore[31] && w_s1_gatewayIn_packed_43_bore[31])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_43_bore[31] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_43_bore[32] && w_s1_gatewayIn_packed_43_bore[32])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_43_bore[32] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_43_bore[33] && w_s1_gatewayIn_packed_43_bore[33])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_43_bore[33] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_43_bore[34] && w_s1_gatewayIn_packed_43_bore[34])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_43_bore[34] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_43_bore[35] && w_s1_gatewayIn_packed_43_bore[35])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_43_bore[35] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_43_bore[36] && w_s1_gatewayIn_packed_43_bore[36])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_43_bore[36] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_43_bore[37] && w_s1_gatewayIn_packed_43_bore[37])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_43_bore[37] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_43_bore[38] && w_s1_gatewayIn_packed_43_bore[38])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_43_bore[38] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_43_bore[39] && w_s1_gatewayIn_packed_43_bore[39])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_43_bore[39] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_43_bore[40] && w_s1_gatewayIn_packed_43_bore[40])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_43_bore[40] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_43_bore[41] && w_s1_gatewayIn_packed_43_bore[41])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_43_bore[41] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_43_bore[42] && w_s1_gatewayIn_packed_43_bore[42])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_43_bore[42] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_43_bore[43] && w_s1_gatewayIn_packed_43_bore[43])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_43_bore[43] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_43_bore[44] && w_s1_gatewayIn_packed_43_bore[44])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_43_bore[44] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_43_bore[45] && w_s1_gatewayIn_packed_43_bore[45])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_43_bore[45] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_43_bore[46] && w_s1_gatewayIn_packed_43_bore[46])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_43_bore[46] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_43_bore[47] && w_s1_gatewayIn_packed_43_bore[47])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_43_bore[47] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_43_bore[48] && w_s1_gatewayIn_packed_43_bore[48])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_43_bore[48] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_43_bore[49] && w_s1_gatewayIn_packed_43_bore[49])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_43_bore[49] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_43_bore[50] && w_s1_gatewayIn_packed_43_bore[50])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_43_bore[50] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_43_bore[51] && w_s1_gatewayIn_packed_43_bore[51])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_43_bore[51] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_43_bore[52] && w_s1_gatewayIn_packed_43_bore[52])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_43_bore[52] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_43_bore[53] && w_s1_gatewayIn_packed_43_bore[53])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_43_bore[53] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_43_bore[54] && w_s1_gatewayIn_packed_43_bore[54])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_43_bore[54] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_43_bore[55] && w_s1_gatewayIn_packed_43_bore[55])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_43_bore[55] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_43_bore[56] && w_s1_gatewayIn_packed_43_bore[56])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_43_bore[56] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_43_bore[57] && w_s1_gatewayIn_packed_43_bore[57])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_43_bore[57] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_43_bore[58] && w_s1_gatewayIn_packed_43_bore[58])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_43_bore[58] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_43_bore[59] && w_s1_gatewayIn_packed_43_bore[59])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_43_bore[59] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_43_bore[60] && w_s1_gatewayIn_packed_43_bore[60])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_43_bore[60] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_43_bore[61] && w_s1_gatewayIn_packed_43_bore[61])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_43_bore[61] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_43_bore[62] && w_s1_gatewayIn_packed_43_bore[62])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_43_bore[62] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_43_bore[63] && w_s1_gatewayIn_packed_43_bore[63])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_43_bore[63] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_43_bore[64] && w_s1_gatewayIn_packed_43_bore[64])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_43_bore[64] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_43_bore[65] && w_s1_gatewayIn_packed_43_bore[65])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_43_bore[65] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_43_bore[66] && w_s1_gatewayIn_packed_43_bore[66])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_43_bore[66] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_43_bore[67] && w_s1_gatewayIn_packed_43_bore[67])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_43_bore[67] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_43_bore[68] && w_s1_gatewayIn_packed_43_bore[68])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_43_bore[68] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_43_bore[69] && w_s1_gatewayIn_packed_43_bore[69])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_43_bore[69] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_43_bore[70] && w_s1_gatewayIn_packed_43_bore[70])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_43_bore[70] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_43_bore[71] && w_s1_gatewayIn_packed_43_bore[71])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_43_bore[71] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_43_bore[72] && w_s1_gatewayIn_packed_43_bore[72])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_43_bore[72] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_43_bore[73] && w_s1_gatewayIn_packed_43_bore[73])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_43_bore[73] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_43_bore[74] && w_s1_gatewayIn_packed_43_bore[74])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_43_bore[74] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_43_bore[75] && w_s1_gatewayIn_packed_43_bore[75])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_43_bore[75] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_43_bore[76] && w_s1_gatewayIn_packed_43_bore[76])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_43_bore[76] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_43_bore[77] && w_s1_gatewayIn_packed_43_bore[77])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_43_bore[77] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_43_bore[78] && w_s1_gatewayIn_packed_43_bore[78])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_43_bore[78] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_43_bore[79] && w_s1_gatewayIn_packed_43_bore[79])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_43_bore[79] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_43_bore[80] && w_s1_gatewayIn_packed_43_bore[80])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_43_bore[80] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_43_bore[81] && w_s1_gatewayIn_packed_43_bore[81])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_43_bore[81] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_43_bore[82] && w_s1_gatewayIn_packed_43_bore[82])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_43_bore[82] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_43_bore[83] && w_s1_gatewayIn_packed_43_bore[83])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_43_bore[83] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_43_bore[84] && w_s1_gatewayIn_packed_43_bore[84])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_43_bore[84] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_43_bore[85] && w_s1_gatewayIn_packed_43_bore[85])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_43_bore[85] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_43_bore[86] && w_s1_gatewayIn_packed_43_bore[86])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_43_bore[86] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_43_bore[87] && w_s1_gatewayIn_packed_43_bore[87])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_43_bore[87] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_43_bore[88] && w_s1_gatewayIn_packed_43_bore[88])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_43_bore[88] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_43_bore[89] && w_s1_gatewayIn_packed_43_bore[89])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_43_bore[89] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_43_bore[90] && w_s1_gatewayIn_packed_43_bore[90])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_43_bore[90] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_43_bore[91] && w_s1_gatewayIn_packed_43_bore[91])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_43_bore[91] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_43_bore[92] && w_s1_gatewayIn_packed_43_bore[92])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_43_bore[92] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_43_bore[93] && w_s1_gatewayIn_packed_43_bore[93])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_43_bore[93] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_43_bore[94] && w_s1_gatewayIn_packed_43_bore[94])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_43_bore[94] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_43_bore[95] && w_s1_gatewayIn_packed_43_bore[95])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_43_bore[95] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_43_bore[96] && w_s1_gatewayIn_packed_43_bore[96])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_43_bore[96] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_43_bore[97] && w_s1_gatewayIn_packed_43_bore[97])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_43_bore[97] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_43_bore[98] && w_s1_gatewayIn_packed_43_bore[98])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_43_bore[98] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_43_bore[99] && w_s1_gatewayIn_packed_43_bore[99])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_43_bore[99] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_43_bore[100] && w_s1_gatewayIn_packed_43_bore[100])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_43_bore[100] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_43_bore[101] && w_s1_gatewayIn_packed_43_bore[101])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_43_bore[101] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_43_bore[102] && w_s1_gatewayIn_packed_43_bore[102])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_43_bore[102] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_43_bore[103] && w_s1_gatewayIn_packed_43_bore[103])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_43_bore[103] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_43_bore[104] && w_s1_gatewayIn_packed_43_bore[104])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_43_bore[104] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_43_bore[105] && w_s1_gatewayIn_packed_43_bore[105])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_43_bore[105] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_43_bore[106] && w_s1_gatewayIn_packed_43_bore[106])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_43_bore[106] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_43_bore[107] && w_s1_gatewayIn_packed_43_bore[107])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_43_bore[107] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_43_bore[108] && w_s1_gatewayIn_packed_43_bore[108])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_43_bore[108] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_43_bore[109] && w_s1_gatewayIn_packed_43_bore[109])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_43_bore[109] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_43_bore[110] && w_s1_gatewayIn_packed_43_bore[110])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_43_bore[110] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_43_bore[111] && w_s1_gatewayIn_packed_43_bore[111])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_43_bore[111] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_43_bore[112] && w_s1_gatewayIn_packed_43_bore[112])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_43_bore[112] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_43_bore[113] && w_s1_gatewayIn_packed_43_bore[113])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_43_bore[113] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_43_bore[114] && w_s1_gatewayIn_packed_43_bore[114])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_43_bore[114] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_43_bore[115] && w_s1_gatewayIn_packed_43_bore[115])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_43_bore[115] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_43_bore[116] && w_s1_gatewayIn_packed_43_bore[116])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_43_bore[116] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_43_bore[117] && w_s1_gatewayIn_packed_43_bore[117])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_43_bore[117] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_43_bore[118] && w_s1_gatewayIn_packed_43_bore[118])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_43_bore[118] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_43_bore[119] && w_s1_gatewayIn_packed_43_bore[119])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_43_bore[119] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_43_bore[120] && w_s1_gatewayIn_packed_43_bore[120])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_43_bore[120] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_43_bore[121] && w_s1_gatewayIn_packed_43_bore[121])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_43_bore[121] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_43_bore[122] && w_s1_gatewayIn_packed_43_bore[122])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_43_bore[122] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_43_bore[123] && w_s1_gatewayIn_packed_43_bore[123])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_43_bore[123] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_43_bore[124] && w_s1_gatewayIn_packed_43_bore[124])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_43_bore[124] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_43_bore[125] && w_s1_gatewayIn_packed_43_bore[125])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_43_bore[125] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_43_bore[126] && w_s1_gatewayIn_packed_43_bore[126])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_43_bore[126] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_43_bore[127] && w_s1_gatewayIn_packed_43_bore[127])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_43_bore[127] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_43_bore[128] && w_s1_gatewayIn_packed_43_bore[128])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_43_bore[128] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_43_bore[129] && w_s1_gatewayIn_packed_43_bore[129])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_43_bore[129] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_43_bore[130] && w_s1_gatewayIn_packed_43_bore[130])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_43_bore[130] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_43_bore[131] && w_s1_gatewayIn_packed_43_bore[131])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_43_bore[131] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_43_bore[132] && w_s1_gatewayIn_packed_43_bore[132])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_43_bore[132] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_43_bore[133] && w_s1_gatewayIn_packed_43_bore[133])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_43_bore[133] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_43_bore[134] && w_s1_gatewayIn_packed_43_bore[134])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_43_bore[134] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_43_bore[135] && w_s1_gatewayIn_packed_43_bore[135])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_43_bore[135] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_43_bore[136] && w_s1_gatewayIn_packed_43_bore[136])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_43_bore[136] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_43_bore[137] && w_s1_gatewayIn_packed_43_bore[137])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_43_bore[137] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_43_bore[138] && w_s1_gatewayIn_packed_43_bore[138])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_43_bore[138] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_43_bore[139] && w_s1_gatewayIn_packed_43_bore[139])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_43_bore[139] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_43_bore[140] && w_s1_gatewayIn_packed_43_bore[140])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_43_bore[140] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_43_bore[141] && w_s1_gatewayIn_packed_43_bore[141])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_43_bore[141] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_43_bore[142] && w_s1_gatewayIn_packed_43_bore[142])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_43_bore[142] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_43_bore[143] && w_s1_gatewayIn_packed_43_bore[143])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_43_bore[143] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_43_bore[144] && w_s1_gatewayIn_packed_43_bore[144])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_43_bore[144] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_43_bore[145] && w_s1_gatewayIn_packed_43_bore[145])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_43_bore[145] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_43_bore[146] && w_s1_gatewayIn_packed_43_bore[146])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_43_bore[146] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_43_bore[147] && w_s1_gatewayIn_packed_43_bore[147])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_43_bore[147] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_43_bore[148] && w_s1_gatewayIn_packed_43_bore[148])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_43_bore[148] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_43_bore[149] && w_s1_gatewayIn_packed_43_bore[149])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_43_bore[149] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_43_bore[150] && w_s1_gatewayIn_packed_43_bore[150])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_43_bore[150] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_43_bore[151] && w_s1_gatewayIn_packed_43_bore[151])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_43_bore[151] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_43_bore[152] && w_s1_gatewayIn_packed_43_bore[152])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_43_bore[152] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_43_bore[153] && w_s1_gatewayIn_packed_43_bore[153])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_43_bore[153] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_43_bore[154] && w_s1_gatewayIn_packed_43_bore[154])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_43_bore[154] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_43_bore[155] && w_s1_gatewayIn_packed_43_bore[155])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_43_bore[155] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_43_bore[156] && w_s1_gatewayIn_packed_43_bore[156])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_43_bore[156] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_43_bore[157] && w_s1_gatewayIn_packed_43_bore[157])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_43_bore[157] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_43_bore[158] && w_s1_gatewayIn_packed_43_bore[158])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_43_bore[158] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_43_bore[159] && w_s1_gatewayIn_packed_43_bore[159])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_43_bore[159] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_43_bore[160] && w_s1_gatewayIn_packed_43_bore[160])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_43_bore[160] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_43_bore[161] && w_s1_gatewayIn_packed_43_bore[161])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_43_bore[161] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_43_bore[162] && w_s1_gatewayIn_packed_43_bore[162])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_43_bore[162] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_43_bore[163] && w_s1_gatewayIn_packed_43_bore[163])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_43_bore[163] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_43_bore[164] && w_s1_gatewayIn_packed_43_bore[164])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_43_bore[164] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_43_bore[165] && w_s1_gatewayIn_packed_43_bore[165])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_43_bore[165] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_43_bore[166] && w_s1_gatewayIn_packed_43_bore[166])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_43_bore[166] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_43_bore[167] && w_s1_gatewayIn_packed_43_bore[167])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_43_bore[167] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_43_bore[168] && w_s1_gatewayIn_packed_43_bore[168])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_43_bore[168] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_43_bore[169] && w_s1_gatewayIn_packed_43_bore[169])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_43_bore[169] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_43_bore[170] && w_s1_gatewayIn_packed_43_bore[170])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_43_bore[170] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_43_bore[171] && w_s1_gatewayIn_packed_43_bore[171])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_43_bore[171] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_43_bore[172] && w_s1_gatewayIn_packed_43_bore[172])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_43_bore[172] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_43_bore[173] && w_s1_gatewayIn_packed_43_bore[173])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_43_bore[173] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_43_bore[174] && w_s1_gatewayIn_packed_43_bore[174])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_43_bore[174] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_43_bore[175] && w_s1_gatewayIn_packed_43_bore[175])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_43_bore[175] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_43_bore[176] && w_s1_gatewayIn_packed_43_bore[176])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_43_bore[176] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_43_bore[177] && w_s1_gatewayIn_packed_43_bore[177])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_43_bore[177] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_43_bore[178] && w_s1_gatewayIn_packed_43_bore[178])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_43_bore[178] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_43_bore[179] && w_s1_gatewayIn_packed_43_bore[179])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_43_bore[179] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_43_bore[180] && w_s1_gatewayIn_packed_43_bore[180])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_43_bore[180] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_43_bore[181] && w_s1_gatewayIn_packed_43_bore[181])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_43_bore[181] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_43_bore[182] && w_s1_gatewayIn_packed_43_bore[182])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_43_bore[182] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_43_bore[183] && w_s1_gatewayIn_packed_43_bore[183])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_43_bore[183] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_43_bore[184] && w_s1_gatewayIn_packed_43_bore[184])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_43_bore[184] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_43_bore[185] && w_s1_gatewayIn_packed_43_bore[185])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_43_bore[185] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_43_bore[186] && w_s1_gatewayIn_packed_43_bore[186])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_43_bore[186] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_43_bore[187] && w_s1_gatewayIn_packed_43_bore[187])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_43_bore[187] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_43_bore[188] && w_s1_gatewayIn_packed_43_bore[188])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_43_bore[188] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_43_bore[189] && w_s1_gatewayIn_packed_43_bore[189])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_43_bore[189] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_43_bore[190] && w_s1_gatewayIn_packed_43_bore[190])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_43_bore[190] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_43_bore[191] && w_s1_gatewayIn_packed_43_bore[191])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_43_bore[191] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_43_bore[192] && w_s1_gatewayIn_packed_43_bore[192])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_43_bore[192] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_43_bore[193] && w_s1_gatewayIn_packed_43_bore[193])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_43_bore[193] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_43_bore[194] && w_s1_gatewayIn_packed_43_bore[194])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_43_bore[194] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_43_bore[195] && w_s1_gatewayIn_packed_43_bore[195])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_43_bore[195] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_43_bore[196] && w_s1_gatewayIn_packed_43_bore[196])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_43_bore[196] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_43_bore[197] && w_s1_gatewayIn_packed_43_bore[197])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_43_bore[197] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_43_bore[198] && w_s1_gatewayIn_packed_43_bore[198])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_43_bore[198] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_43_bore[199] && w_s1_gatewayIn_packed_43_bore[199])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_43_bore[199] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_43_bore[200] && w_s1_gatewayIn_packed_43_bore[200])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_43_bore[200] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_43_bore[201] && w_s1_gatewayIn_packed_43_bore[201])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_43_bore[201] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_43_bore[202] && w_s1_gatewayIn_packed_43_bore[202])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_43_bore[202] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_43_bore[203] && w_s1_gatewayIn_packed_43_bore[203])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_43_bore[203] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_43_bore[204] && w_s1_gatewayIn_packed_43_bore[204])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_43_bore[204] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_43_bore[205] && w_s1_gatewayIn_packed_43_bore[205])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_43_bore[205] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_43_bore[206] && w_s1_gatewayIn_packed_43_bore[206])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_43_bore[206] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_43_bore[207] && w_s1_gatewayIn_packed_43_bore[207])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_43_bore[207] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_43_bore[208] && w_s1_gatewayIn_packed_43_bore[208])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_43_bore[208] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_43_bore[209] && w_s1_gatewayIn_packed_43_bore[209])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_43_bore[209] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_43_bore[210] && w_s1_gatewayIn_packed_43_bore[210])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_43_bore[210] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_43_bore[211] && w_s1_gatewayIn_packed_43_bore[211])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_43_bore[211] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_43_bore[212] && w_s1_gatewayIn_packed_43_bore[212])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_43_bore[212] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_43_bore[213] && w_s1_gatewayIn_packed_43_bore[213])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_43_bore[213] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_43_bore[214] && w_s1_gatewayIn_packed_43_bore[214])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_43_bore[214] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_43_bore[215] && w_s1_gatewayIn_packed_43_bore[215])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_43_bore[215] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_43_bore[216] && w_s1_gatewayIn_packed_43_bore[216])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_43_bore[216] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_43_bore[217] && w_s1_gatewayIn_packed_43_bore[217])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_43_bore[217] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_43_bore[218] && w_s1_gatewayIn_packed_43_bore[218])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_43_bore[218] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_43_bore[219] && w_s1_gatewayIn_packed_43_bore[219])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_43_bore[219] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_43_bore[220] && w_s1_gatewayIn_packed_43_bore[220])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_43_bore[220] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_43_bore[221] && w_s1_gatewayIn_packed_43_bore[221])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_43_bore[221] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_43_bore[222] && w_s1_gatewayIn_packed_43_bore[222])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_43_bore[222] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_43_bore[223] && w_s1_gatewayIn_packed_43_bore[223])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_43_bore[223] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_43_bore[224] && w_s1_gatewayIn_packed_43_bore[224])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_43_bore[224] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_43_bore[225] && w_s1_gatewayIn_packed_43_bore[225])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_43_bore[225] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_43_bore[226] && w_s1_gatewayIn_packed_43_bore[226])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_43_bore[226] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_43_bore[227] && w_s1_gatewayIn_packed_43_bore[227])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_43_bore[227] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_43_bore[228] && w_s1_gatewayIn_packed_43_bore[228])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_43_bore[228] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_43_bore[229] && w_s1_gatewayIn_packed_43_bore[229])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_43_bore[229] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_43_bore[230] && w_s1_gatewayIn_packed_43_bore[230])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_43_bore[230] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_43_bore[231] && w_s1_gatewayIn_packed_43_bore[231])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_43_bore[231] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_43_bore[232] && w_s1_gatewayIn_packed_43_bore[232])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_43_bore[232] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_43_bore[233] && w_s1_gatewayIn_packed_43_bore[233])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_43_bore[233] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_43_bore[234] && w_s1_gatewayIn_packed_43_bore[234])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_43_bore[234] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_43_bore[235] && w_s1_gatewayIn_packed_43_bore[235])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_43_bore[235] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_43_bore[236] && w_s1_gatewayIn_packed_43_bore[236])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_43_bore[236] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_43_bore[237] && w_s1_gatewayIn_packed_43_bore[237])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_43_bore[237] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_43_bore[238] && w_s1_gatewayIn_packed_43_bore[238])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_43_bore[238] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_43_bore[239] && w_s1_gatewayIn_packed_43_bore[239])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_43_bore[239] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_43_bore[240] && w_s1_gatewayIn_packed_43_bore[240])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_43_bore[240] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_43_bore[241] && w_s1_gatewayIn_packed_43_bore[241])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_43_bore[241] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_43_bore[242] && w_s1_gatewayIn_packed_43_bore[242])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_43_bore[242] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_43_bore[243] && w_s1_gatewayIn_packed_43_bore[243])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_43_bore[243] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_43_bore[244] && w_s1_gatewayIn_packed_43_bore[244])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_43_bore[244] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_43_bore[245] && w_s1_gatewayIn_packed_43_bore[245])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_43_bore[245] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_43_bore[246] && w_s1_gatewayIn_packed_43_bore[246])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_43_bore[246] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_43_bore[247] && w_s1_gatewayIn_packed_43_bore[247])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_43_bore[247] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_43_bore[248] && w_s1_gatewayIn_packed_43_bore[248])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_43_bore[248] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_43_bore[249] && w_s1_gatewayIn_packed_43_bore[249])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_43_bore[249] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_43_bore[250] && w_s1_gatewayIn_packed_43_bore[250])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_43_bore[250] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_43_bore[251] && w_s1_gatewayIn_packed_43_bore[251])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_43_bore[251] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_43_bore[252] && w_s1_gatewayIn_packed_43_bore[252])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_43_bore[252] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_43_bore[253] && w_s1_gatewayIn_packed_43_bore[253])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_43_bore[253] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_43_bore[254] && w_s1_gatewayIn_packed_43_bore[254])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_43_bore[254] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_43_bore[255] && w_s1_gatewayIn_packed_43_bore[255])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_43_bore[255] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_43_bore[256] && w_s1_gatewayIn_packed_43_bore[256])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_43_bore[256] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_43_bore[257] && w_s1_gatewayIn_packed_43_bore[257])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_43_bore[257] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_43_bore[258] && w_s1_gatewayIn_packed_43_bore[258])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_43_bore[258] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_43_bore[259] && w_s1_gatewayIn_packed_43_bore[259])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_43_bore[259] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_43_bore[260] && w_s1_gatewayIn_packed_43_bore[260])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_43_bore[260] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_43_bore[261] && w_s1_gatewayIn_packed_43_bore[261])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_43_bore[261] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_43_bore[262] && w_s1_gatewayIn_packed_43_bore[262])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_43_bore[262] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_43_bore[263] && w_s1_gatewayIn_packed_43_bore[263])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_43_bore[263] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_43_bore[264] && w_s1_gatewayIn_packed_43_bore[264])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_43_bore[264] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_43_bore[265] && w_s1_gatewayIn_packed_43_bore[265])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_43_bore[265] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_43_bore[266] && w_s1_gatewayIn_packed_43_bore[266])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_43_bore[266] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_43_bore[267] && w_s1_gatewayIn_packed_43_bore[267])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_43_bore[267] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_43_bore[268] && w_s1_gatewayIn_packed_43_bore[268])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_43_bore[268] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_43_bore[269] && w_s1_gatewayIn_packed_43_bore[269])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_43_bore[269] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_43_bore[270] && w_s1_gatewayIn_packed_43_bore[270])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_43_bore[270] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_43_bore[271] && w_s1_gatewayIn_packed_43_bore[271])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_43_bore[271] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_43_bore[272] && w_s1_gatewayIn_packed_43_bore[272])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_43_bore[272] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_43_bore[273] && w_s1_gatewayIn_packed_43_bore[273])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_43_bore[273] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_43_bore[274] && w_s1_gatewayIn_packed_43_bore[274])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_43_bore[274] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_43_bore[275] && w_s1_gatewayIn_packed_43_bore[275])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_43_bore[275] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_43_bore[276] && w_s1_gatewayIn_packed_43_bore[276])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_43_bore[276] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_43_bore[277] && w_s1_gatewayIn_packed_43_bore[277])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_43_bore[277] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_43_bore[278] && w_s1_gatewayIn_packed_43_bore[278])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_43_bore[278] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_43_bore[279] && w_s1_gatewayIn_packed_43_bore[279])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_43_bore[279] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_43_bore[280] && w_s1_gatewayIn_packed_43_bore[280])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_43_bore[280] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_43_bore[281] && w_s1_gatewayIn_packed_43_bore[281])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_43_bore[281] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_43_bore[282] && w_s1_gatewayIn_packed_43_bore[282])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_43_bore[282] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_43_bore[283] && w_s1_gatewayIn_packed_43_bore[283])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_43_bore[283] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_43_bore[284] && w_s1_gatewayIn_packed_43_bore[284])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_43_bore[284] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_43_bore[285] && w_s1_gatewayIn_packed_43_bore[285])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_43_bore[285] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_43_bore[286] && w_s1_gatewayIn_packed_43_bore[286])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_43_bore[286] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_43_bore[287] && w_s1_gatewayIn_packed_43_bore[287])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_43_bore[287] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_43_bore[288] && w_s1_gatewayIn_packed_43_bore[288])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_43_bore[288] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_43_bore[289] && w_s1_gatewayIn_packed_43_bore[289])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_43_bore[289] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_43_bore[290] && w_s1_gatewayIn_packed_43_bore[290])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_43_bore[290] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_43_bore[291] && w_s1_gatewayIn_packed_43_bore[291])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_43_bore[291] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_43_bore[292] && w_s1_gatewayIn_packed_43_bore[292])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_43_bore[292] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_43_bore[293] && w_s1_gatewayIn_packed_43_bore[293])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_43_bore[293] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_43_bore[294] && w_s1_gatewayIn_packed_43_bore[294])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_43_bore[294] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_43_bore[295] && w_s1_gatewayIn_packed_43_bore[295])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_43_bore[295] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_43_bore[296] && w_s1_gatewayIn_packed_43_bore[296])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_43_bore[296] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_43_bore[297] && w_s1_gatewayIn_packed_43_bore[297])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_43_bore[297] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_43_bore[298] && w_s1_gatewayIn_packed_43_bore[298])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_43_bore[298] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_43_bore[299] && w_s1_gatewayIn_packed_43_bore[299])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_43_bore[299] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_43_bore[300] && w_s1_gatewayIn_packed_43_bore[300])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_43_bore[300] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_43_bore[301] && w_s1_gatewayIn_packed_43_bore[301])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_43_bore[301] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_43_bore[302] && w_s1_gatewayIn_packed_43_bore[302])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_43_bore[302] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_43_bore[303] && w_s1_gatewayIn_packed_43_bore[303])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_43_bore[303] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_43_bore[304] && w_s1_gatewayIn_packed_43_bore[304])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_43_bore[304] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_43_bore[305] && w_s1_gatewayIn_packed_43_bore[305])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_43_bore[305] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_43_bore[306] && w_s1_gatewayIn_packed_43_bore[306])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_43_bore[306] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_43_bore[307] && w_s1_gatewayIn_packed_43_bore[307])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_43_bore[307] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_43_bore[308] && w_s1_gatewayIn_packed_43_bore[308])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_43_bore[308] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_43_bore[309] && w_s1_gatewayIn_packed_43_bore[309])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_43_bore[309] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_43_bore[310] && w_s1_gatewayIn_packed_43_bore[310])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_43_bore[310] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_43_bore[311] && w_s1_gatewayIn_packed_43_bore[311])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_43_bore[311] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_43_bore[312] && w_s1_gatewayIn_packed_43_bore[312])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_43_bore[312] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_43_bore[313] && w_s1_gatewayIn_packed_43_bore[313])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_43_bore[313] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_43_bore[314] && w_s1_gatewayIn_packed_43_bore[314])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_43_bore[314] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_43_bore[315] && w_s1_gatewayIn_packed_43_bore[315])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_43_bore[315] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_43_bore[316] && w_s1_gatewayIn_packed_43_bore[316])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_43_bore[316] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_43_bore[317] && w_s1_gatewayIn_packed_43_bore[317])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_43_bore[317] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_43_bore[318] && w_s1_gatewayIn_packed_43_bore[318])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_43_bore[318] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_43_bore[319] && w_s1_gatewayIn_packed_43_bore[319])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_43_bore[319] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_43_bore[320] && w_s1_gatewayIn_packed_43_bore[320])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_43_bore[320] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_43_bore[321] && w_s1_gatewayIn_packed_43_bore[321])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_43_bore[321] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_43_bore[322] && w_s1_gatewayIn_packed_43_bore[322])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_43_bore[322] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_43_bore[323] && w_s1_gatewayIn_packed_43_bore[323])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_43_bore[323] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_43_bore[324] && w_s1_gatewayIn_packed_43_bore[324])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_43_bore[324] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_43_bore[325] && w_s1_gatewayIn_packed_43_bore[325])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_43_bore[325] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_43_bore[326] && w_s1_gatewayIn_packed_43_bore[326])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_43_bore[326] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_43_bore[327] && w_s1_gatewayIn_packed_43_bore[327])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_43_bore[327] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_43_bore[328] && w_s1_gatewayIn_packed_43_bore[328])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_43_bore[328] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_43_bore[329] && w_s1_gatewayIn_packed_43_bore[329])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_43_bore[329] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_43_bore[330] && w_s1_gatewayIn_packed_43_bore[330])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_43_bore[330] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_43_bore[331] && w_s1_gatewayIn_packed_43_bore[331])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_43_bore[331] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_43_bore[332] && w_s1_gatewayIn_packed_43_bore[332])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_43_bore[332] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_43_bore[333] && w_s1_gatewayIn_packed_43_bore[333])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_43_bore[333] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_43_bore[334] && w_s1_gatewayIn_packed_43_bore[334])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_43_bore[334] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_43_bore[335] && w_s1_gatewayIn_packed_43_bore[335])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_43_bore[335] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_43_bore[336] && w_s1_gatewayIn_packed_43_bore[336])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_43_bore[336] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_43_bore[337] && w_s1_gatewayIn_packed_43_bore[337])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_43_bore[337] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_43_bore[338] && w_s1_gatewayIn_packed_43_bore[338])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_43_bore[338] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_43_bore[339] && w_s1_gatewayIn_packed_43_bore[339])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_43_bore[339] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_43_bore[340] && w_s1_gatewayIn_packed_43_bore[340])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_43_bore[340] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_43_bore[341] && w_s1_gatewayIn_packed_43_bore[341])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_43_bore[341] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_43_bore[342] && w_s1_gatewayIn_packed_43_bore[342])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_43_bore[342] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_43_bore[343] && w_s1_gatewayIn_packed_43_bore[343])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_43_bore[343] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_43_bore[344] && w_s1_gatewayIn_packed_43_bore[344])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_43_bore[344] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_43_bore[345] && w_s1_gatewayIn_packed_43_bore[345])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_43_bore[345] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_43_bore[346] && w_s1_gatewayIn_packed_43_bore[346])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_43_bore[346] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_43_bore[347] && w_s1_gatewayIn_packed_43_bore[347])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_43_bore[347] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_43_bore[348] && w_s1_gatewayIn_packed_43_bore[348])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_43_bore[348] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_43_bore[349] && w_s1_gatewayIn_packed_43_bore[349])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_43_bore[349] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_43_bore[350] && w_s1_gatewayIn_packed_43_bore[350])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_43_bore[350] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_43_bore[351] && w_s1_gatewayIn_packed_43_bore[351])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_43_bore[351] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_43_bore[352] && w_s1_gatewayIn_packed_43_bore[352])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_43_bore[352] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_43_bore[353] && w_s1_gatewayIn_packed_43_bore[353])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_43_bore[353] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_43_bore[354] && w_s1_gatewayIn_packed_43_bore[354])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_43_bore[354] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_43_bore[355] && w_s1_gatewayIn_packed_43_bore[355])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_43_bore[355] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_43_bore[356] && w_s1_gatewayIn_packed_43_bore[356])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_43_bore[356] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_43_bore[357] && w_s1_gatewayIn_packed_43_bore[357])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_43_bore[357] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_43_bore[358] && w_s1_gatewayIn_packed_43_bore[358])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_43_bore[358] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_43_bore[359] && w_s1_gatewayIn_packed_43_bore[359])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_43_bore[359] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_43_bore[360] && w_s1_gatewayIn_packed_43_bore[360])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_43_bore[360] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_43_bore[361] && w_s1_gatewayIn_packed_43_bore[361])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_43_bore[361] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_43_bore[362] && w_s1_gatewayIn_packed_43_bore[362])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_43_bore[362] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_43_bore[363] && w_s1_gatewayIn_packed_43_bore[363])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_43_bore[363] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_43_bore[364] && w_s1_gatewayIn_packed_43_bore[364])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_43_bore[364] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_43_bore[365] && w_s1_gatewayIn_packed_43_bore[365])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_43_bore[365] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_43_bore[366] && w_s1_gatewayIn_packed_43_bore[366])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_43_bore[366] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_43_bore[367] && w_s1_gatewayIn_packed_43_bore[367])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_43_bore[367] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_43_bore[368] && w_s1_gatewayIn_packed_43_bore[368])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_43_bore[368] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_43_bore[369] && w_s1_gatewayIn_packed_43_bore[369])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_43_bore[369] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_43_bore[370] && w_s1_gatewayIn_packed_43_bore[370])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_43_bore[370] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_43_bore[371] && w_s1_gatewayIn_packed_43_bore[371])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_43_bore[371] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_43_bore[372] && w_s1_gatewayIn_packed_43_bore[372])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_43_bore[372] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_43_bore[373] && w_s1_gatewayIn_packed_43_bore[373])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_43_bore[373] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_43_bore[374] && w_s1_gatewayIn_packed_43_bore[374])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_43_bore[374] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_43_bore[375] && w_s1_gatewayIn_packed_43_bore[375])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_43_bore[375] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_43_bore[376] && w_s1_gatewayIn_packed_43_bore[376])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_43_bore[376] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_43_bore[377] && w_s1_gatewayIn_packed_43_bore[377])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_43_bore[377] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_43_bore[378] && w_s1_gatewayIn_packed_43_bore[378])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_43_bore[378] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_43_bore[379] && w_s1_gatewayIn_packed_43_bore[379])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_43_bore[379] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_43_bore[380] && w_s1_gatewayIn_packed_43_bore[380])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_43_bore[380] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_43_bore[381] && w_s1_gatewayIn_packed_43_bore[381])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_43_bore[381] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_43_bore[382] && w_s1_gatewayIn_packed_43_bore[382])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_43_bore[382] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_43_bore[383] && w_s1_gatewayIn_packed_43_bore[383])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_43_bore[383] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_43_bore[384] && w_s1_gatewayIn_packed_43_bore[384])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_43_bore[384] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_43_bore[385] && w_s1_gatewayIn_packed_43_bore[385])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_43_bore[385] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_43_bore[386] && w_s1_gatewayIn_packed_43_bore[386])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_43_bore[386] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_43_bore[387] && w_s1_gatewayIn_packed_43_bore[387])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_43_bore[387] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_43_bore[388] && w_s1_gatewayIn_packed_43_bore[388])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_43_bore[388] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_43_bore[389] && w_s1_gatewayIn_packed_43_bore[389])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_43_bore[389] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_43_bore[390] && w_s1_gatewayIn_packed_43_bore[390])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_43_bore[390] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_43_bore[391] && w_s1_gatewayIn_packed_43_bore[391])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_43_bore[391] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_43_bore[392] && w_s1_gatewayIn_packed_43_bore[392])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_43_bore[392] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_43_bore[393] && w_s1_gatewayIn_packed_43_bore[393])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_43_bore[393] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_43_bore[394] && w_s1_gatewayIn_packed_43_bore[394])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_43_bore[394] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_43_bore[395] && w_s1_gatewayIn_packed_43_bore[395])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_43_bore[395] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_43_bore[396] && w_s1_gatewayIn_packed_43_bore[396])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_43_bore[396] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_43_bore[397] && w_s1_gatewayIn_packed_43_bore[397])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_43_bore[397] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_43_bore[398] && w_s1_gatewayIn_packed_43_bore[398])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_43_bore[398] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_43_bore[399] && w_s1_gatewayIn_packed_43_bore[399])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_43_bore[399] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_43_bore[400] && w_s1_gatewayIn_packed_43_bore[400])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_43_bore[400] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_43_bore[401] && w_s1_gatewayIn_packed_43_bore[401])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_43_bore[401] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_43_bore[402] && w_s1_gatewayIn_packed_43_bore[402])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_43_bore[402] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_43_bore[403] && w_s1_gatewayIn_packed_43_bore[403])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_43_bore[403] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_43_bore[404] && w_s1_gatewayIn_packed_43_bore[404])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_43_bore[404] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_43_bore[405] && w_s1_gatewayIn_packed_43_bore[405])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_43_bore[405] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_43_bore[406] && w_s1_gatewayIn_packed_43_bore[406])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_43_bore[406] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_43_bore[407] && w_s1_gatewayIn_packed_43_bore[407])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_43_bore[407] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_43_bore[408] && w_s1_gatewayIn_packed_43_bore[408])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_43_bore[408] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_43_bore[409] && w_s1_gatewayIn_packed_43_bore[409])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_43_bore[409] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_43_bore[410] && w_s1_gatewayIn_packed_43_bore[410])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_43_bore[410] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_43_bore[411] && w_s1_gatewayIn_packed_43_bore[411])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_43_bore[411] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_43_bore[412] && w_s1_gatewayIn_packed_43_bore[412])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_43_bore[412] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_43_bore[413] && w_s1_gatewayIn_packed_43_bore[413])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_43_bore[413] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_43_bore[414] && w_s1_gatewayIn_packed_43_bore[414])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_43_bore[414] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_43_bore[415] && w_s1_gatewayIn_packed_43_bore[415])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_43_bore[415] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_43_bore[416] && w_s1_gatewayIn_packed_43_bore[416])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_43_bore[416] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_43_bore[417] && w_s1_gatewayIn_packed_43_bore[417])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_43_bore[417] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_43_bore[418] && w_s1_gatewayIn_packed_43_bore[418])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_43_bore[418] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_43_bore[419] && w_s1_gatewayIn_packed_43_bore[419])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_43_bore[419] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_43_bore[420] && w_s1_gatewayIn_packed_43_bore[420])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_43_bore[420] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_43_bore[421] && w_s1_gatewayIn_packed_43_bore[421])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_43_bore[421] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_43_bore[422] && w_s1_gatewayIn_packed_43_bore[422])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_43_bore[422] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_43_bore[423] && w_s1_gatewayIn_packed_43_bore[423])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_43_bore[423] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_43_bore[424] && w_s1_gatewayIn_packed_43_bore[424])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_43_bore[424] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_43_bore[425] && w_s1_gatewayIn_packed_43_bore[425])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_43_bore[425] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_43_bore[426] && w_s1_gatewayIn_packed_43_bore[426])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_43_bore[426] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_43_bore[427] && w_s1_gatewayIn_packed_43_bore[427])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_43_bore[427] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_43_bore[428] && w_s1_gatewayIn_packed_43_bore[428])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_43_bore[428] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_43_bore[429] && w_s1_gatewayIn_packed_43_bore[429])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_43_bore[429] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_43_bore[430] && w_s1_gatewayIn_packed_43_bore[430])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_43_bore[430] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_43_bore[431] && w_s1_gatewayIn_packed_43_bore[431])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_43_bore[431] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_43_bore[432] && w_s1_gatewayIn_packed_43_bore[432])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_43_bore[432] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_43_bore[433] && w_s1_gatewayIn_packed_43_bore[433])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_43_bore[433] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_43_bore[434] && w_s1_gatewayIn_packed_43_bore[434])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_43_bore[434] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_43_bore[435] && w_s1_gatewayIn_packed_43_bore[435])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_43_bore[435] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_43_bore[436] && w_s1_gatewayIn_packed_43_bore[436])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_43_bore[436] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_43_bore[437] && w_s1_gatewayIn_packed_43_bore[437])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_43_bore[437] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_43_bore[438] && w_s1_gatewayIn_packed_43_bore[438])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_43_bore[438] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_43_bore[439] && w_s1_gatewayIn_packed_43_bore[439])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_43_bore[439] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_43_bore[440] && w_s1_gatewayIn_packed_43_bore[440])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_43_bore[440] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_43_bore[441] && w_s1_gatewayIn_packed_43_bore[441])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_43_bore[441] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_43_bore[442] && w_s1_gatewayIn_packed_43_bore[442])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_43_bore[442] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_43_bore[443] && w_s1_gatewayIn_packed_43_bore[443])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_43_bore[443] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_43_bore[444] && w_s1_gatewayIn_packed_43_bore[444])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_43_bore[444] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_43_bore[445] && w_s1_gatewayIn_packed_43_bore[445])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_43_bore[445] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_43_bore[446] && w_s1_gatewayIn_packed_43_bore[446])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_43_bore[446] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_43_bore[447] && w_s1_gatewayIn_packed_43_bore[447])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_43_bore[447] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_43_bore[448] && w_s1_gatewayIn_packed_43_bore[448])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_43_bore[448] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_43_bore[449] && w_s1_gatewayIn_packed_43_bore[449])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_43_bore[449] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_43_bore[450] && w_s1_gatewayIn_packed_43_bore[450])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_43_bore[450] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_43_bore[451] && w_s1_gatewayIn_packed_43_bore[451])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_43_bore[451] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_43_bore[452] && w_s1_gatewayIn_packed_43_bore[452])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_43_bore[452] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_43_bore[453] && w_s1_gatewayIn_packed_43_bore[453])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_43_bore[453] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_43_bore[454] && w_s1_gatewayIn_packed_43_bore[454])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_43_bore[454] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_43_bore[455] && w_s1_gatewayIn_packed_43_bore[455])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_43_bore[455] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_43_bore[456] && w_s1_gatewayIn_packed_43_bore[456])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_43_bore[456] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_43_bore[457] && w_s1_gatewayIn_packed_43_bore[457])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_43_bore[457] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_43_bore[458] && w_s1_gatewayIn_packed_43_bore[458])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_43_bore[458] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_43_bore[459] && w_s1_gatewayIn_packed_43_bore[459])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_43_bore[459] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_43_bore[460] && w_s1_gatewayIn_packed_43_bore[460])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_43_bore[460] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_43_bore[461] && w_s1_gatewayIn_packed_43_bore[461])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_43_bore[461] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_43_bore[462] && w_s1_gatewayIn_packed_43_bore[462])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_43_bore[462] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_43_bore[463] && w_s1_gatewayIn_packed_43_bore[463])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_43_bore[463] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_43_bore[464] && w_s1_gatewayIn_packed_43_bore[464])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_43_bore[464] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_43_bore[465] && w_s1_gatewayIn_packed_43_bore[465])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_43_bore[465] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_43_bore[466] && w_s1_gatewayIn_packed_43_bore[466])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_43_bore[466] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_43_bore[467] && w_s1_gatewayIn_packed_43_bore[467])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_43_bore[467] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_43_bore[468] && w_s1_gatewayIn_packed_43_bore[468])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_43_bore[468] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_43_bore[469] && w_s1_gatewayIn_packed_43_bore[469])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_43_bore[469] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_43_bore[470] && w_s1_gatewayIn_packed_43_bore[470])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_43_bore[470] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_43_bore[471] && w_s1_gatewayIn_packed_43_bore[471])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_43_bore[471] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_43_bore[472] && w_s1_gatewayIn_packed_43_bore[472])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_43_bore[472] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_43_bore[473] && w_s1_gatewayIn_packed_43_bore[473])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_43_bore[473] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_43_bore[474] && w_s1_gatewayIn_packed_43_bore[474])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_43_bore[474] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_43_bore[475] && w_s1_gatewayIn_packed_43_bore[475])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_43_bore[475] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_43_bore[476] && w_s1_gatewayIn_packed_43_bore[476])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_43_bore[476] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_43_bore[477] && w_s1_gatewayIn_packed_43_bore[477])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_43_bore[477] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_43_bore[478] && w_s1_gatewayIn_packed_43_bore[478])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_43_bore[478] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_43_bore[479] && w_s1_gatewayIn_packed_43_bore[479])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_43_bore[479] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_43_bore[480] && w_s1_gatewayIn_packed_43_bore[480])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_43_bore[480] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_43_bore[481] && w_s1_gatewayIn_packed_43_bore[481])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_43_bore[481] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_43_bore[482] && w_s1_gatewayIn_packed_43_bore[482])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_43_bore[482] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_43_bore[483] && w_s1_gatewayIn_packed_43_bore[483])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_43_bore[483] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_43_bore[484] && w_s1_gatewayIn_packed_43_bore[484])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_43_bore[484] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_43_bore[485] && w_s1_gatewayIn_packed_43_bore[485])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_43_bore[485] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_43_bore[486] && w_s1_gatewayIn_packed_43_bore[486])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_43_bore[486] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_43_bore[487] && w_s1_gatewayIn_packed_43_bore[487])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_43_bore[487] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_43_bore[488] && w_s1_gatewayIn_packed_43_bore[488])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_43_bore[488] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_43_bore[489] && w_s1_gatewayIn_packed_43_bore[489])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_43_bore[489] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_43_bore[490] && w_s1_gatewayIn_packed_43_bore[490])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_43_bore[490] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_43_bore[491] && w_s1_gatewayIn_packed_43_bore[491])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_43_bore[491] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_43_bore[492] && w_s1_gatewayIn_packed_43_bore[492])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_43_bore[492] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_43_bore[493] && w_s1_gatewayIn_packed_43_bore[493])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_43_bore[493] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_43_bore[494] && w_s1_gatewayIn_packed_43_bore[494])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_43_bore[494] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_43_bore[495] && w_s1_gatewayIn_packed_43_bore[495])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_43_bore[495] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_43_bore[496] && w_s1_gatewayIn_packed_43_bore[496])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_43_bore[496] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_43_bore[497] && w_s1_gatewayIn_packed_43_bore[497])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_43_bore[497] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_43_bore[498] && w_s1_gatewayIn_packed_43_bore[498])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_43_bore[498] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_43_bore[499] && w_s1_gatewayIn_packed_43_bore[499])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_43_bore[499] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_43_bore[500] && w_s1_gatewayIn_packed_43_bore[500])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_43_bore[500] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_43_bore[501] && w_s1_gatewayIn_packed_43_bore[501])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_43_bore[501] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_43_bore[502] && w_s1_gatewayIn_packed_43_bore[502])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_43_bore[502] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_43_bore[503] && w_s1_gatewayIn_packed_43_bore[503])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_43_bore[503] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_43_bore[504] && w_s1_gatewayIn_packed_43_bore[504])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_43_bore[504] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_43_bore[505] && w_s1_gatewayIn_packed_43_bore[505])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_43_bore[505] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_43_bore[506] && w_s1_gatewayIn_packed_43_bore[506])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_43_bore[506] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_43_bore[507] && w_s1_gatewayIn_packed_43_bore[507])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_43_bore[507] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_43_bore[508] && w_s1_gatewayIn_packed_43_bore[508])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_43_bore[508] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_43_bore[509] && w_s1_gatewayIn_packed_43_bore[509])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_43_bore[509] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_43_bore[510] && w_s1_gatewayIn_packed_43_bore[510])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_43_bore[510] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_43_bore[511] && w_s1_gatewayIn_packed_43_bore[511])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_43_bore[511] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_43_bore[512] && w_s1_gatewayIn_packed_43_bore[512])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_43_bore[512] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_43_bore[513] && w_s1_gatewayIn_packed_43_bore[513])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_43_bore[513] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_43_bore[514] && w_s1_gatewayIn_packed_43_bore[514])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_43_bore[514] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_43_bore[515] && w_s1_gatewayIn_packed_43_bore[515])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_43_bore[515] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_43_bore[516] && w_s1_gatewayIn_packed_43_bore[516])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_43_bore[516] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_43_bore[517] && w_s1_gatewayIn_packed_43_bore[517])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_43_bore[517] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_43_bore[518] && w_s1_gatewayIn_packed_43_bore[518])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_43_bore[518] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_43_bore[519] && w_s1_gatewayIn_packed_43_bore[519])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_43_bore[519] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_43_bore[520] && w_s1_gatewayIn_packed_43_bore[520])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_43_bore[520] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_43_bore[521] && w_s1_gatewayIn_packed_43_bore[521])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_43_bore[521] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_43_bore[522] && w_s1_gatewayIn_packed_43_bore[522])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_43_bore[522] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_43_bore[523] && w_s1_gatewayIn_packed_43_bore[523])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_43_bore[523] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_43_bore[524] && w_s1_gatewayIn_packed_43_bore[524])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_43_bore[524] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_43_bore[525] && w_s1_gatewayIn_packed_43_bore[525])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_43_bore[525] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_43_bore[526] && w_s1_gatewayIn_packed_43_bore[526])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_43_bore[526] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_43_bore[527] && w_s1_gatewayIn_packed_43_bore[527])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_43_bore[527] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_43_bore[528] && w_s1_gatewayIn_packed_43_bore[528])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_43_bore[528] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_43_bore[529] && w_s1_gatewayIn_packed_43_bore[529])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_43_bore[529] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_43_bore[530] && w_s1_gatewayIn_packed_43_bore[530])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_43_bore[530] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_43_bore[531] && w_s1_gatewayIn_packed_43_bore[531])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_43_bore[531] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_43_bore[532] && w_s1_gatewayIn_packed_43_bore[532])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_43_bore[532] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_43_bore[533] && w_s1_gatewayIn_packed_43_bore[533])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_43_bore[533] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_43_bore[534] && w_s1_gatewayIn_packed_43_bore[534])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_43_bore[534] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_43_bore[535] && w_s1_gatewayIn_packed_43_bore[535])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_43_bore[535] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_43_bore[536] && w_s1_gatewayIn_packed_43_bore[536])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_43_bore[536] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_43_bore[537] && w_s1_gatewayIn_packed_43_bore[537])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_43_bore[537] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_43_bore[538] && w_s1_gatewayIn_packed_43_bore[538])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_43_bore[538] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_43_bore[539] && w_s1_gatewayIn_packed_43_bore[539])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_43_bore[539] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_43_bore[540] && w_s1_gatewayIn_packed_43_bore[540])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_43_bore[540] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_43_bore[541] && w_s1_gatewayIn_packed_43_bore[541])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_43_bore[541] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_43_bore[542] && w_s1_gatewayIn_packed_43_bore[542])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_43_bore[542] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_43_bore[543] && w_s1_gatewayIn_packed_43_bore[543])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_43_bore[543] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_43_bore[544] && w_s1_gatewayIn_packed_43_bore[544])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_43_bore[544] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_43_bore[545] && w_s1_gatewayIn_packed_43_bore[545])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_43_bore[545] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_43_bore[546] && w_s1_gatewayIn_packed_43_bore[546])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_43_bore[546] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_43_bore[547] && w_s1_gatewayIn_packed_43_bore[547])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_43_bore[547] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_43_bore[548] && w_s1_gatewayIn_packed_43_bore[548])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_43_bore[548] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_43_bore[549] && w_s1_gatewayIn_packed_43_bore[549])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_43_bore[549] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_43_bore[550] && w_s1_gatewayIn_packed_43_bore[550])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_43_bore[550] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_43_bore[551] && w_s1_gatewayIn_packed_43_bore[551])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_43_bore[551] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_43_bore[552] && w_s1_gatewayIn_packed_43_bore[552])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_43_bore[552] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_43_bore[553] && w_s1_gatewayIn_packed_43_bore[553])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_43_bore[553] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_43_bore[554] && w_s1_gatewayIn_packed_43_bore[554])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_43_bore[554] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_43_bore[555] && w_s1_gatewayIn_packed_43_bore[555])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_43_bore[555] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_43_bore[556] && w_s1_gatewayIn_packed_43_bore[556])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_43_bore[556] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_43_bore[557] && w_s1_gatewayIn_packed_43_bore[557])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_43_bore[557] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_43_bore[558] && w_s1_gatewayIn_packed_43_bore[558])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_43_bore[558] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_43_bore[559] && w_s1_gatewayIn_packed_43_bore[559])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_43_bore[559] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_43_bore[560] && w_s1_gatewayIn_packed_43_bore[560])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_43_bore[560] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_43_bore[561] && w_s1_gatewayIn_packed_43_bore[561])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_43_bore[561] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_43_bore[562] && w_s1_gatewayIn_packed_43_bore[562])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_43_bore[562] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_43_bore[563] && w_s1_gatewayIn_packed_43_bore[563])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_43_bore[563] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_43_bore[564] && w_s1_gatewayIn_packed_43_bore[564])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_43_bore[564] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_43_bore[565] && w_s1_gatewayIn_packed_43_bore[565])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_43_bore[565] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_43_bore[566] && w_s1_gatewayIn_packed_43_bore[566])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_43_bore[566] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_43_bore[567] && w_s1_gatewayIn_packed_43_bore[567])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_43_bore[567] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_43_bore[568] && w_s1_gatewayIn_packed_43_bore[568])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_43_bore[568] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_43_bore[569] && w_s1_gatewayIn_packed_43_bore[569])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_43_bore[569] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_43_bore[570] && w_s1_gatewayIn_packed_43_bore[570])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_43_bore[570] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_43_bore[571] && w_s1_gatewayIn_packed_43_bore[571])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_43_bore[571] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_43_bore[572] && w_s1_gatewayIn_packed_43_bore[572])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_43_bore[572] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_43_bore[573] && w_s1_gatewayIn_packed_43_bore[573])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_43_bore[573] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_43_bore[574] && w_s1_gatewayIn_packed_43_bore[574])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_43_bore[574] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_43_bore[575] && w_s1_gatewayIn_packed_43_bore[575])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_43_bore[575] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_43_bore[576] && w_s1_gatewayIn_packed_43_bore[576])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_43_bore[576] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_43_bore[577] && w_s1_gatewayIn_packed_43_bore[577])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_43_bore[577] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_43_bore[578] && w_s1_gatewayIn_packed_43_bore[578])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_43_bore[578] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_43_bore[579] && w_s1_gatewayIn_packed_43_bore[579])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_43_bore[579] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_43_bore[580] && w_s1_gatewayIn_packed_43_bore[580])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_43_bore[580] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_43_bore[581] && w_s1_gatewayIn_packed_43_bore[581])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_43_bore[581] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_43_bore[582] && w_s1_gatewayIn_packed_43_bore[582])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_43_bore[582] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_43_bore[583] && w_s1_gatewayIn_packed_43_bore[583])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_43_bore[583] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_43_bore[584] && w_s1_gatewayIn_packed_43_bore[584])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_43_bore[584] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_43_bore[585] && w_s1_gatewayIn_packed_43_bore[585])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_43_bore[585] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_43_bore[586] && w_s1_gatewayIn_packed_43_bore[586])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_43_bore[586] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_43_bore[587] && w_s1_gatewayIn_packed_43_bore[587])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_43_bore[587] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_43_bore[588] && w_s1_gatewayIn_packed_43_bore[588])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_43_bore[588] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_43_bore[589] && w_s1_gatewayIn_packed_43_bore[589])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_43_bore[589] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_43_bore[590] && w_s1_gatewayIn_packed_43_bore[590])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_43_bore[590] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_43_bore[591] && w_s1_gatewayIn_packed_43_bore[591])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_43_bore[591] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_43_bore[592] && w_s1_gatewayIn_packed_43_bore[592])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_43_bore[592] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_43_bore[593] && w_s1_gatewayIn_packed_43_bore[593])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_43_bore[593] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_43_bore[594] && w_s1_gatewayIn_packed_43_bore[594])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_43_bore[594] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_43_bore[595] && w_s1_gatewayIn_packed_43_bore[595])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_43_bore[595] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_43_bore[596] && w_s1_gatewayIn_packed_43_bore[596])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_43_bore[596] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_43_bore[597] && w_s1_gatewayIn_packed_43_bore[597])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_43_bore[597] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_43_bore[598] && w_s1_gatewayIn_packed_43_bore[598])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_43_bore[598] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_43_bore[599] && w_s1_gatewayIn_packed_43_bore[599])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_43_bore[599] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_43_bore[600] && w_s1_gatewayIn_packed_43_bore[600])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_43_bore[600] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_44_bore[0] && w_s1_gatewayIn_packed_44_bore[0])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_44_bore[0] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_44_bore[1] && w_s1_gatewayIn_packed_44_bore[1])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_44_bore[1] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_44_bore[2] && w_s1_gatewayIn_packed_44_bore[2])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_44_bore[2] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_44_bore[3] && w_s1_gatewayIn_packed_44_bore[3])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_44_bore[3] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_44_bore[4] && w_s1_gatewayIn_packed_44_bore[4])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_44_bore[4] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_44_bore[5] && w_s1_gatewayIn_packed_44_bore[5])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_44_bore[5] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_44_bore[6] && w_s1_gatewayIn_packed_44_bore[6])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_44_bore[6] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_44_bore[7] && w_s1_gatewayIn_packed_44_bore[7])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_44_bore[7] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_44_bore[8] && w_s1_gatewayIn_packed_44_bore[8])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_44_bore[8] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_44_bore[9] && w_s1_gatewayIn_packed_44_bore[9])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_44_bore[9] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_44_bore[10] && w_s1_gatewayIn_packed_44_bore[10])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_44_bore[10] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_44_bore[11] && w_s1_gatewayIn_packed_44_bore[11])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_44_bore[11] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_44_bore[12] && w_s1_gatewayIn_packed_44_bore[12])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_44_bore[12] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_44_bore[13] && w_s1_gatewayIn_packed_44_bore[13])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_44_bore[13] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_44_bore[14] && w_s1_gatewayIn_packed_44_bore[14])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_44_bore[14] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_44_bore[15] && w_s1_gatewayIn_packed_44_bore[15])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_44_bore[15] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_44_bore[16] && w_s1_gatewayIn_packed_44_bore[16])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_44_bore[16] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_44_bore[17] && w_s1_gatewayIn_packed_44_bore[17])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_44_bore[17] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_44_bore[18] && w_s1_gatewayIn_packed_44_bore[18])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_44_bore[18] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_44_bore[19] && w_s1_gatewayIn_packed_44_bore[19])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_44_bore[19] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_44_bore[20] && w_s1_gatewayIn_packed_44_bore[20])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_44_bore[20] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_44_bore[21] && w_s1_gatewayIn_packed_44_bore[21])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_44_bore[21] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_44_bore[22] && w_s1_gatewayIn_packed_44_bore[22])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_44_bore[22] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_44_bore[23] && w_s1_gatewayIn_packed_44_bore[23])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_44_bore[23] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_44_bore[24] && w_s1_gatewayIn_packed_44_bore[24])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_44_bore[24] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_44_bore[25] && w_s1_gatewayIn_packed_44_bore[25])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_44_bore[25] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_44_bore[26] && w_s1_gatewayIn_packed_44_bore[26])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_44_bore[26] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_44_bore[27] && w_s1_gatewayIn_packed_44_bore[27])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_44_bore[27] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_44_bore[28] && w_s1_gatewayIn_packed_44_bore[28])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_44_bore[28] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_44_bore[29] && w_s1_gatewayIn_packed_44_bore[29])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_44_bore[29] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_44_bore[30] && w_s1_gatewayIn_packed_44_bore[30])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_44_bore[30] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_44_bore[31] && w_s1_gatewayIn_packed_44_bore[31])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_44_bore[31] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_44_bore[32] && w_s1_gatewayIn_packed_44_bore[32])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_44_bore[32] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_44_bore[33] && w_s1_gatewayIn_packed_44_bore[33])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_44_bore[33] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_44_bore[34] && w_s1_gatewayIn_packed_44_bore[34])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_44_bore[34] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_44_bore[35] && w_s1_gatewayIn_packed_44_bore[35])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_44_bore[35] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_44_bore[36] && w_s1_gatewayIn_packed_44_bore[36])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_44_bore[36] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_44_bore[37] && w_s1_gatewayIn_packed_44_bore[37])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_44_bore[37] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_44_bore[38] && w_s1_gatewayIn_packed_44_bore[38])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_44_bore[38] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_44_bore[39] && w_s1_gatewayIn_packed_44_bore[39])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_44_bore[39] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_44_bore[40] && w_s1_gatewayIn_packed_44_bore[40])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_44_bore[40] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_44_bore[41] && w_s1_gatewayIn_packed_44_bore[41])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_44_bore[41] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_44_bore[42] && w_s1_gatewayIn_packed_44_bore[42])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_44_bore[42] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_44_bore[43] && w_s1_gatewayIn_packed_44_bore[43])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_44_bore[43] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_44_bore[44] && w_s1_gatewayIn_packed_44_bore[44])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_44_bore[44] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_44_bore[45] && w_s1_gatewayIn_packed_44_bore[45])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_44_bore[45] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_44_bore[46] && w_s1_gatewayIn_packed_44_bore[46])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_44_bore[46] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_44_bore[47] && w_s1_gatewayIn_packed_44_bore[47])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_44_bore[47] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_44_bore[48] && w_s1_gatewayIn_packed_44_bore[48])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_44_bore[48] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_44_bore[49] && w_s1_gatewayIn_packed_44_bore[49])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_44_bore[49] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_44_bore[50] && w_s1_gatewayIn_packed_44_bore[50])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_44_bore[50] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_44_bore[51] && w_s1_gatewayIn_packed_44_bore[51])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_44_bore[51] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_44_bore[52] && w_s1_gatewayIn_packed_44_bore[52])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_44_bore[52] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_44_bore[53] && w_s1_gatewayIn_packed_44_bore[53])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_44_bore[53] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_44_bore[54] && w_s1_gatewayIn_packed_44_bore[54])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_44_bore[54] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_44_bore[55] && w_s1_gatewayIn_packed_44_bore[55])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_44_bore[55] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_44_bore[56] && w_s1_gatewayIn_packed_44_bore[56])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_44_bore[56] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_44_bore[57] && w_s1_gatewayIn_packed_44_bore[57])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_44_bore[57] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_44_bore[58] && w_s1_gatewayIn_packed_44_bore[58])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_44_bore[58] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_44_bore[59] && w_s1_gatewayIn_packed_44_bore[59])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_44_bore[59] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_44_bore[60] && w_s1_gatewayIn_packed_44_bore[60])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_44_bore[60] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_44_bore[61] && w_s1_gatewayIn_packed_44_bore[61])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_44_bore[61] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_44_bore[62] && w_s1_gatewayIn_packed_44_bore[62])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_44_bore[62] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_44_bore[63] && w_s1_gatewayIn_packed_44_bore[63])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_44_bore[63] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_44_bore[64] && w_s1_gatewayIn_packed_44_bore[64])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_44_bore[64] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_44_bore[65] && w_s1_gatewayIn_packed_44_bore[65])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_44_bore[65] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_44_bore[66] && w_s1_gatewayIn_packed_44_bore[66])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_44_bore[66] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_44_bore[67] && w_s1_gatewayIn_packed_44_bore[67])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_44_bore[67] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_44_bore[68] && w_s1_gatewayIn_packed_44_bore[68])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_44_bore[68] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_44_bore[69] && w_s1_gatewayIn_packed_44_bore[69])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_44_bore[69] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_44_bore[70] && w_s1_gatewayIn_packed_44_bore[70])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_44_bore[70] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_44_bore[71] && w_s1_gatewayIn_packed_44_bore[71])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_44_bore[71] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_44_bore[72] && w_s1_gatewayIn_packed_44_bore[72])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_44_bore[72] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_44_bore[73] && w_s1_gatewayIn_packed_44_bore[73])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_44_bore[73] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_44_bore[74] && w_s1_gatewayIn_packed_44_bore[74])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_44_bore[74] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_44_bore[75] && w_s1_gatewayIn_packed_44_bore[75])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_44_bore[75] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_44_bore[76] && w_s1_gatewayIn_packed_44_bore[76])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_44_bore[76] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_44_bore[77] && w_s1_gatewayIn_packed_44_bore[77])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_44_bore[77] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_44_bore[78] && w_s1_gatewayIn_packed_44_bore[78])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_44_bore[78] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_44_bore[79] && w_s1_gatewayIn_packed_44_bore[79])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_44_bore[79] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_44_bore[80] && w_s1_gatewayIn_packed_44_bore[80])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_44_bore[80] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_44_bore[81] && w_s1_gatewayIn_packed_44_bore[81])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_44_bore[81] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_44_bore[82] && w_s1_gatewayIn_packed_44_bore[82])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_44_bore[82] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_44_bore[83] && w_s1_gatewayIn_packed_44_bore[83])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_44_bore[83] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_44_bore[84] && w_s1_gatewayIn_packed_44_bore[84])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_44_bore[84] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_44_bore[85] && w_s1_gatewayIn_packed_44_bore[85])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_44_bore[85] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_44_bore[86] && w_s1_gatewayIn_packed_44_bore[86])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_44_bore[86] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_44_bore[87] && w_s1_gatewayIn_packed_44_bore[87])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_44_bore[87] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_44_bore[88] && w_s1_gatewayIn_packed_44_bore[88])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_44_bore[88] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_44_bore[89] && w_s1_gatewayIn_packed_44_bore[89])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_44_bore[89] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_44_bore[90] && w_s1_gatewayIn_packed_44_bore[90])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_44_bore[90] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_44_bore[91] && w_s1_gatewayIn_packed_44_bore[91])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_44_bore[91] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_44_bore[92] && w_s1_gatewayIn_packed_44_bore[92])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_44_bore[92] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_44_bore[93] && w_s1_gatewayIn_packed_44_bore[93])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_44_bore[93] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_44_bore[94] && w_s1_gatewayIn_packed_44_bore[94])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_44_bore[94] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_44_bore[95] && w_s1_gatewayIn_packed_44_bore[95])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_44_bore[95] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_44_bore[96] && w_s1_gatewayIn_packed_44_bore[96])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_44_bore[96] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_44_bore[97] && w_s1_gatewayIn_packed_44_bore[97])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_44_bore[97] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_44_bore[98] && w_s1_gatewayIn_packed_44_bore[98])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_44_bore[98] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_44_bore[99] && w_s1_gatewayIn_packed_44_bore[99])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_44_bore[99] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_44_bore[100] && w_s1_gatewayIn_packed_44_bore[100])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_44_bore[100] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_44_bore[101] && w_s1_gatewayIn_packed_44_bore[101])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_44_bore[101] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_44_bore[102] && w_s1_gatewayIn_packed_44_bore[102])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_44_bore[102] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_44_bore[103] && w_s1_gatewayIn_packed_44_bore[103])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_44_bore[103] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_44_bore[104] && w_s1_gatewayIn_packed_44_bore[104])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_44_bore[104] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_44_bore[105] && w_s1_gatewayIn_packed_44_bore[105])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_44_bore[105] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_44_bore[106] && w_s1_gatewayIn_packed_44_bore[106])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_44_bore[106] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_44_bore[107] && w_s1_gatewayIn_packed_44_bore[107])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_44_bore[107] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_44_bore[108] && w_s1_gatewayIn_packed_44_bore[108])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_44_bore[108] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_44_bore[109] && w_s1_gatewayIn_packed_44_bore[109])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_44_bore[109] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_44_bore[110] && w_s1_gatewayIn_packed_44_bore[110])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_44_bore[110] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_44_bore[111] && w_s1_gatewayIn_packed_44_bore[111])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_44_bore[111] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_44_bore[112] && w_s1_gatewayIn_packed_44_bore[112])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_44_bore[112] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_44_bore[113] && w_s1_gatewayIn_packed_44_bore[113])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_44_bore[113] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_44_bore[114] && w_s1_gatewayIn_packed_44_bore[114])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_44_bore[114] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_44_bore[115] && w_s1_gatewayIn_packed_44_bore[115])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_44_bore[115] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_44_bore[116] && w_s1_gatewayIn_packed_44_bore[116])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_44_bore[116] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_44_bore[117] && w_s1_gatewayIn_packed_44_bore[117])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_44_bore[117] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_44_bore[118] && w_s1_gatewayIn_packed_44_bore[118])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_44_bore[118] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_44_bore[119] && w_s1_gatewayIn_packed_44_bore[119])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_44_bore[119] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_44_bore[120] && w_s1_gatewayIn_packed_44_bore[120])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_44_bore[120] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_44_bore[121] && w_s1_gatewayIn_packed_44_bore[121])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_44_bore[121] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_44_bore[122] && w_s1_gatewayIn_packed_44_bore[122])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_44_bore[122] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_44_bore[123] && w_s1_gatewayIn_packed_44_bore[123])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_44_bore[123] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_44_bore[124] && w_s1_gatewayIn_packed_44_bore[124])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_44_bore[124] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_44_bore[125] && w_s1_gatewayIn_packed_44_bore[125])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_44_bore[125] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_44_bore[126] && w_s1_gatewayIn_packed_44_bore[126])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_44_bore[126] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_44_bore[127] && w_s1_gatewayIn_packed_44_bore[127])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_44_bore[127] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_44_bore[128] && w_s1_gatewayIn_packed_44_bore[128])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_44_bore[128] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_44_bore[129] && w_s1_gatewayIn_packed_44_bore[129])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_44_bore[129] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_44_bore[130] && w_s1_gatewayIn_packed_44_bore[130])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_44_bore[130] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_44_bore[131] && w_s1_gatewayIn_packed_44_bore[131])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_44_bore[131] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_44_bore[132] && w_s1_gatewayIn_packed_44_bore[132])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_44_bore[132] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_44_bore[133] && w_s1_gatewayIn_packed_44_bore[133])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_44_bore[133] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_44_bore[134] && w_s1_gatewayIn_packed_44_bore[134])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_44_bore[134] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_44_bore[135] && w_s1_gatewayIn_packed_44_bore[135])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_44_bore[135] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_44_bore[136] && w_s1_gatewayIn_packed_44_bore[136])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_44_bore[136] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_44_bore[137] && w_s1_gatewayIn_packed_44_bore[137])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_44_bore[137] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_44_bore[138] && w_s1_gatewayIn_packed_44_bore[138])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_44_bore[138] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_44_bore[139] && w_s1_gatewayIn_packed_44_bore[139])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_44_bore[139] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_44_bore[140] && w_s1_gatewayIn_packed_44_bore[140])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_44_bore[140] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_44_bore[141] && w_s1_gatewayIn_packed_44_bore[141])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_44_bore[141] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_44_bore[142] && w_s1_gatewayIn_packed_44_bore[142])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_44_bore[142] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_44_bore[143] && w_s1_gatewayIn_packed_44_bore[143])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_44_bore[143] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_44_bore[144] && w_s1_gatewayIn_packed_44_bore[144])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_44_bore[144] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_44_bore[145] && w_s1_gatewayIn_packed_44_bore[145])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_44_bore[145] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_44_bore[146] && w_s1_gatewayIn_packed_44_bore[146])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_44_bore[146] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_44_bore[147] && w_s1_gatewayIn_packed_44_bore[147])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_44_bore[147] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_44_bore[148] && w_s1_gatewayIn_packed_44_bore[148])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_44_bore[148] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_44_bore[149] && w_s1_gatewayIn_packed_44_bore[149])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_44_bore[149] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_44_bore[150] && w_s1_gatewayIn_packed_44_bore[150])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_44_bore[150] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_44_bore[151] && w_s1_gatewayIn_packed_44_bore[151])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_44_bore[151] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_44_bore[152] && w_s1_gatewayIn_packed_44_bore[152])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_44_bore[152] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_44_bore[153] && w_s1_gatewayIn_packed_44_bore[153])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_44_bore[153] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_44_bore[154] && w_s1_gatewayIn_packed_44_bore[154])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_44_bore[154] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_44_bore[155] && w_s1_gatewayIn_packed_44_bore[155])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_44_bore[155] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_44_bore[156] && w_s1_gatewayIn_packed_44_bore[156])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_44_bore[156] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_44_bore[157] && w_s1_gatewayIn_packed_44_bore[157])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_44_bore[157] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_44_bore[158] && w_s1_gatewayIn_packed_44_bore[158])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_44_bore[158] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_44_bore[159] && w_s1_gatewayIn_packed_44_bore[159])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_44_bore[159] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_44_bore[160] && w_s1_gatewayIn_packed_44_bore[160])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_44_bore[160] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_44_bore[161] && w_s1_gatewayIn_packed_44_bore[161])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_44_bore[161] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_44_bore[162] && w_s1_gatewayIn_packed_44_bore[162])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_44_bore[162] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_44_bore[163] && w_s1_gatewayIn_packed_44_bore[163])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_44_bore[163] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_44_bore[164] && w_s1_gatewayIn_packed_44_bore[164])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_44_bore[164] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_44_bore[165] && w_s1_gatewayIn_packed_44_bore[165])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_44_bore[165] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_44_bore[166] && w_s1_gatewayIn_packed_44_bore[166])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_44_bore[166] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_44_bore[167] && w_s1_gatewayIn_packed_44_bore[167])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_44_bore[167] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_44_bore[168] && w_s1_gatewayIn_packed_44_bore[168])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_44_bore[168] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_44_bore[169] && w_s1_gatewayIn_packed_44_bore[169])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_44_bore[169] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_44_bore[170] && w_s1_gatewayIn_packed_44_bore[170])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_44_bore[170] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_44_bore[171] && w_s1_gatewayIn_packed_44_bore[171])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_44_bore[171] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_44_bore[172] && w_s1_gatewayIn_packed_44_bore[172])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_44_bore[172] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_44_bore[173] && w_s1_gatewayIn_packed_44_bore[173])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_44_bore[173] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_44_bore[174] && w_s1_gatewayIn_packed_44_bore[174])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_44_bore[174] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_44_bore[175] && w_s1_gatewayIn_packed_44_bore[175])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_44_bore[175] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_44_bore[176] && w_s1_gatewayIn_packed_44_bore[176])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_44_bore[176] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_44_bore[177] && w_s1_gatewayIn_packed_44_bore[177])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_44_bore[177] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_44_bore[178] && w_s1_gatewayIn_packed_44_bore[178])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_44_bore[178] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_44_bore[179] && w_s1_gatewayIn_packed_44_bore[179])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_44_bore[179] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_44_bore[180] && w_s1_gatewayIn_packed_44_bore[180])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_44_bore[180] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_44_bore[181] && w_s1_gatewayIn_packed_44_bore[181])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_44_bore[181] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_44_bore[182] && w_s1_gatewayIn_packed_44_bore[182])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_44_bore[182] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_44_bore[183] && w_s1_gatewayIn_packed_44_bore[183])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_44_bore[183] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_44_bore[184] && w_s1_gatewayIn_packed_44_bore[184])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_44_bore[184] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_44_bore[185] && w_s1_gatewayIn_packed_44_bore[185])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_44_bore[185] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_44_bore[186] && w_s1_gatewayIn_packed_44_bore[186])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_44_bore[186] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_44_bore[187] && w_s1_gatewayIn_packed_44_bore[187])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_44_bore[187] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_44_bore[188] && w_s1_gatewayIn_packed_44_bore[188])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_44_bore[188] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_44_bore[189] && w_s1_gatewayIn_packed_44_bore[189])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_44_bore[189] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_44_bore[190] && w_s1_gatewayIn_packed_44_bore[190])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_44_bore[190] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_44_bore[191] && w_s1_gatewayIn_packed_44_bore[191])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_44_bore[191] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_44_bore[192] && w_s1_gatewayIn_packed_44_bore[192])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_44_bore[192] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_44_bore[193] && w_s1_gatewayIn_packed_44_bore[193])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_44_bore[193] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_44_bore[194] && w_s1_gatewayIn_packed_44_bore[194])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_44_bore[194] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_44_bore[195] && w_s1_gatewayIn_packed_44_bore[195])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_44_bore[195] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_44_bore[196] && w_s1_gatewayIn_packed_44_bore[196])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_44_bore[196] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_44_bore[197] && w_s1_gatewayIn_packed_44_bore[197])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_44_bore[197] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_44_bore[198] && w_s1_gatewayIn_packed_44_bore[198])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_44_bore[198] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_44_bore[199] && w_s1_gatewayIn_packed_44_bore[199])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_44_bore[199] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_44_bore[200] && w_s1_gatewayIn_packed_44_bore[200])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_44_bore[200] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_44_bore[201] && w_s1_gatewayIn_packed_44_bore[201])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_44_bore[201] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_44_bore[202] && w_s1_gatewayIn_packed_44_bore[202])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_44_bore[202] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_44_bore[203] && w_s1_gatewayIn_packed_44_bore[203])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_44_bore[203] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_44_bore[204] && w_s1_gatewayIn_packed_44_bore[204])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_44_bore[204] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_44_bore[205] && w_s1_gatewayIn_packed_44_bore[205])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_44_bore[205] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_44_bore[206] && w_s1_gatewayIn_packed_44_bore[206])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_44_bore[206] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_44_bore[207] && w_s1_gatewayIn_packed_44_bore[207])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_44_bore[207] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_44_bore[208] && w_s1_gatewayIn_packed_44_bore[208])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_44_bore[208] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_44_bore[209] && w_s1_gatewayIn_packed_44_bore[209])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_44_bore[209] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_44_bore[210] && w_s1_gatewayIn_packed_44_bore[210])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_44_bore[210] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_44_bore[211] && w_s1_gatewayIn_packed_44_bore[211])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_44_bore[211] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_44_bore[212] && w_s1_gatewayIn_packed_44_bore[212])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_44_bore[212] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_44_bore[213] && w_s1_gatewayIn_packed_44_bore[213])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_44_bore[213] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_44_bore[214] && w_s1_gatewayIn_packed_44_bore[214])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_44_bore[214] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_44_bore[215] && w_s1_gatewayIn_packed_44_bore[215])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_44_bore[215] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_44_bore[216] && w_s1_gatewayIn_packed_44_bore[216])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_44_bore[216] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_44_bore[217] && w_s1_gatewayIn_packed_44_bore[217])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_44_bore[217] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_44_bore[218] && w_s1_gatewayIn_packed_44_bore[218])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_44_bore[218] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_44_bore[219] && w_s1_gatewayIn_packed_44_bore[219])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_44_bore[219] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_44_bore[220] && w_s1_gatewayIn_packed_44_bore[220])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_44_bore[220] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_44_bore[221] && w_s1_gatewayIn_packed_44_bore[221])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_44_bore[221] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_44_bore[222] && w_s1_gatewayIn_packed_44_bore[222])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_44_bore[222] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_44_bore[223] && w_s1_gatewayIn_packed_44_bore[223])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_44_bore[223] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_44_bore[224] && w_s1_gatewayIn_packed_44_bore[224])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_44_bore[224] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_44_bore[225] && w_s1_gatewayIn_packed_44_bore[225])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_44_bore[225] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_44_bore[226] && w_s1_gatewayIn_packed_44_bore[226])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_44_bore[226] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_44_bore[227] && w_s1_gatewayIn_packed_44_bore[227])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_44_bore[227] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_44_bore[228] && w_s1_gatewayIn_packed_44_bore[228])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_44_bore[228] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_44_bore[229] && w_s1_gatewayIn_packed_44_bore[229])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_44_bore[229] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_44_bore[230] && w_s1_gatewayIn_packed_44_bore[230])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_44_bore[230] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_44_bore[231] && w_s1_gatewayIn_packed_44_bore[231])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_44_bore[231] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_44_bore[232] && w_s1_gatewayIn_packed_44_bore[232])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_44_bore[232] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_44_bore[233] && w_s1_gatewayIn_packed_44_bore[233])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_44_bore[233] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_44_bore[234] && w_s1_gatewayIn_packed_44_bore[234])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_44_bore[234] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_44_bore[235] && w_s1_gatewayIn_packed_44_bore[235])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_44_bore[235] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_44_bore[236] && w_s1_gatewayIn_packed_44_bore[236])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_44_bore[236] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_44_bore[237] && w_s1_gatewayIn_packed_44_bore[237])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_44_bore[237] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_44_bore[238] && w_s1_gatewayIn_packed_44_bore[238])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_44_bore[238] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_44_bore[239] && w_s1_gatewayIn_packed_44_bore[239])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_44_bore[239] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_44_bore[240] && w_s1_gatewayIn_packed_44_bore[240])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_44_bore[240] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_44_bore[241] && w_s1_gatewayIn_packed_44_bore[241])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_44_bore[241] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_44_bore[242] && w_s1_gatewayIn_packed_44_bore[242])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_44_bore[242] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_44_bore[243] && w_s1_gatewayIn_packed_44_bore[243])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_44_bore[243] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_44_bore[244] && w_s1_gatewayIn_packed_44_bore[244])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_44_bore[244] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_44_bore[245] && w_s1_gatewayIn_packed_44_bore[245])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_44_bore[245] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_44_bore[246] && w_s1_gatewayIn_packed_44_bore[246])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_44_bore[246] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_44_bore[247] && w_s1_gatewayIn_packed_44_bore[247])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_44_bore[247] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_44_bore[248] && w_s1_gatewayIn_packed_44_bore[248])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_44_bore[248] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_44_bore[249] && w_s1_gatewayIn_packed_44_bore[249])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_44_bore[249] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_44_bore[250] && w_s1_gatewayIn_packed_44_bore[250])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_44_bore[250] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_44_bore[251] && w_s1_gatewayIn_packed_44_bore[251])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_44_bore[251] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_44_bore[252] && w_s1_gatewayIn_packed_44_bore[252])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_44_bore[252] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_44_bore[253] && w_s1_gatewayIn_packed_44_bore[253])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_44_bore[253] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_44_bore[254] && w_s1_gatewayIn_packed_44_bore[254])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_44_bore[254] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_44_bore[255] && w_s1_gatewayIn_packed_44_bore[255])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_44_bore[255] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_44_bore[256] && w_s1_gatewayIn_packed_44_bore[256])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_44_bore[256] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_44_bore[257] && w_s1_gatewayIn_packed_44_bore[257])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_44_bore[257] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_44_bore[258] && w_s1_gatewayIn_packed_44_bore[258])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_44_bore[258] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_44_bore[259] && w_s1_gatewayIn_packed_44_bore[259])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_44_bore[259] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_44_bore[260] && w_s1_gatewayIn_packed_44_bore[260])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_44_bore[260] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_44_bore[261] && w_s1_gatewayIn_packed_44_bore[261])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_44_bore[261] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_44_bore[262] && w_s1_gatewayIn_packed_44_bore[262])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_44_bore[262] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_44_bore[263] && w_s1_gatewayIn_packed_44_bore[263])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_44_bore[263] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_44_bore[264] && w_s1_gatewayIn_packed_44_bore[264])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_44_bore[264] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_44_bore[265] && w_s1_gatewayIn_packed_44_bore[265])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_44_bore[265] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_44_bore[266] && w_s1_gatewayIn_packed_44_bore[266])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_44_bore[266] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_44_bore[267] && w_s1_gatewayIn_packed_44_bore[267])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_44_bore[267] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_44_bore[268] && w_s1_gatewayIn_packed_44_bore[268])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_44_bore[268] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_44_bore[269] && w_s1_gatewayIn_packed_44_bore[269])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_44_bore[269] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_44_bore[270] && w_s1_gatewayIn_packed_44_bore[270])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_44_bore[270] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_44_bore[271] && w_s1_gatewayIn_packed_44_bore[271])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_44_bore[271] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_44_bore[272] && w_s1_gatewayIn_packed_44_bore[272])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_44_bore[272] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_44_bore[273] && w_s1_gatewayIn_packed_44_bore[273])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_44_bore[273] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_44_bore[274] && w_s1_gatewayIn_packed_44_bore[274])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_44_bore[274] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_44_bore[275] && w_s1_gatewayIn_packed_44_bore[275])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_44_bore[275] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_44_bore[276] && w_s1_gatewayIn_packed_44_bore[276])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_44_bore[276] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_44_bore[277] && w_s1_gatewayIn_packed_44_bore[277])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_44_bore[277] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_44_bore[278] && w_s1_gatewayIn_packed_44_bore[278])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_44_bore[278] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_44_bore[279] && w_s1_gatewayIn_packed_44_bore[279])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_44_bore[279] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_44_bore[280] && w_s1_gatewayIn_packed_44_bore[280])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_44_bore[280] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_44_bore[281] && w_s1_gatewayIn_packed_44_bore[281])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_44_bore[281] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_44_bore[282] && w_s1_gatewayIn_packed_44_bore[282])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_44_bore[282] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_44_bore[283] && w_s1_gatewayIn_packed_44_bore[283])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_44_bore[283] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_44_bore[284] && w_s1_gatewayIn_packed_44_bore[284])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_44_bore[284] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_44_bore[285] && w_s1_gatewayIn_packed_44_bore[285])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_44_bore[285] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_44_bore[286] && w_s1_gatewayIn_packed_44_bore[286])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_44_bore[286] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_44_bore[287] && w_s1_gatewayIn_packed_44_bore[287])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_44_bore[287] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_44_bore[288] && w_s1_gatewayIn_packed_44_bore[288])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_44_bore[288] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_44_bore[289] && w_s1_gatewayIn_packed_44_bore[289])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_44_bore[289] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_44_bore[290] && w_s1_gatewayIn_packed_44_bore[290])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_44_bore[290] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_44_bore[291] && w_s1_gatewayIn_packed_44_bore[291])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_44_bore[291] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_44_bore[292] && w_s1_gatewayIn_packed_44_bore[292])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_44_bore[292] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_44_bore[293] && w_s1_gatewayIn_packed_44_bore[293])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_44_bore[293] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_44_bore[294] && w_s1_gatewayIn_packed_44_bore[294])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_44_bore[294] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_44_bore[295] && w_s1_gatewayIn_packed_44_bore[295])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_44_bore[295] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_44_bore[296] && w_s1_gatewayIn_packed_44_bore[296])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_44_bore[296] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_44_bore[297] && w_s1_gatewayIn_packed_44_bore[297])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_44_bore[297] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_44_bore[298] && w_s1_gatewayIn_packed_44_bore[298])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_44_bore[298] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_44_bore[299] && w_s1_gatewayIn_packed_44_bore[299])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_44_bore[299] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_44_bore[300] && w_s1_gatewayIn_packed_44_bore[300])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_44_bore[300] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_44_bore[301] && w_s1_gatewayIn_packed_44_bore[301])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_44_bore[301] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_44_bore[302] && w_s1_gatewayIn_packed_44_bore[302])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_44_bore[302] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_44_bore[303] && w_s1_gatewayIn_packed_44_bore[303])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_44_bore[303] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_44_bore[304] && w_s1_gatewayIn_packed_44_bore[304])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_44_bore[304] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_44_bore[305] && w_s1_gatewayIn_packed_44_bore[305])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_44_bore[305] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_44_bore[306] && w_s1_gatewayIn_packed_44_bore[306])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_44_bore[306] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_44_bore[307] && w_s1_gatewayIn_packed_44_bore[307])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_44_bore[307] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_44_bore[308] && w_s1_gatewayIn_packed_44_bore[308])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_44_bore[308] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_44_bore[309] && w_s1_gatewayIn_packed_44_bore[309])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_44_bore[309] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_44_bore[310] && w_s1_gatewayIn_packed_44_bore[310])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_44_bore[310] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_44_bore[311] && w_s1_gatewayIn_packed_44_bore[311])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_44_bore[311] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_44_bore[312] && w_s1_gatewayIn_packed_44_bore[312])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_44_bore[312] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_44_bore[313] && w_s1_gatewayIn_packed_44_bore[313])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_44_bore[313] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_44_bore[314] && w_s1_gatewayIn_packed_44_bore[314])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_44_bore[314] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_44_bore[315] && w_s1_gatewayIn_packed_44_bore[315])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_44_bore[315] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_44_bore[316] && w_s1_gatewayIn_packed_44_bore[316])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_44_bore[316] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_44_bore[317] && w_s1_gatewayIn_packed_44_bore[317])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_44_bore[317] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_44_bore[318] && w_s1_gatewayIn_packed_44_bore[318])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_44_bore[318] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_44_bore[319] && w_s1_gatewayIn_packed_44_bore[319])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_44_bore[319] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_44_bore[320] && w_s1_gatewayIn_packed_44_bore[320])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_44_bore[320] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_44_bore[321] && w_s1_gatewayIn_packed_44_bore[321])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_44_bore[321] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_44_bore[322] && w_s1_gatewayIn_packed_44_bore[322])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_44_bore[322] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_44_bore[323] && w_s1_gatewayIn_packed_44_bore[323])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_44_bore[323] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_44_bore[324] && w_s1_gatewayIn_packed_44_bore[324])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_44_bore[324] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_44_bore[325] && w_s1_gatewayIn_packed_44_bore[325])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_44_bore[325] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_44_bore[326] && w_s1_gatewayIn_packed_44_bore[326])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_44_bore[326] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_44_bore[327] && w_s1_gatewayIn_packed_44_bore[327])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_44_bore[327] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_44_bore[328] && w_s1_gatewayIn_packed_44_bore[328])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_44_bore[328] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_44_bore[329] && w_s1_gatewayIn_packed_44_bore[329])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_44_bore[329] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_44_bore[330] && w_s1_gatewayIn_packed_44_bore[330])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_44_bore[330] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_44_bore[331] && w_s1_gatewayIn_packed_44_bore[331])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_44_bore[331] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_44_bore[332] && w_s1_gatewayIn_packed_44_bore[332])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_44_bore[332] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_44_bore[333] && w_s1_gatewayIn_packed_44_bore[333])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_44_bore[333] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_44_bore[334] && w_s1_gatewayIn_packed_44_bore[334])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_44_bore[334] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_44_bore[335] && w_s1_gatewayIn_packed_44_bore[335])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_44_bore[335] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_44_bore[336] && w_s1_gatewayIn_packed_44_bore[336])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_44_bore[336] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_44_bore[337] && w_s1_gatewayIn_packed_44_bore[337])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_44_bore[337] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_44_bore[338] && w_s1_gatewayIn_packed_44_bore[338])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_44_bore[338] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_44_bore[339] && w_s1_gatewayIn_packed_44_bore[339])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_44_bore[339] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_44_bore[340] && w_s1_gatewayIn_packed_44_bore[340])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_44_bore[340] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_44_bore[341] && w_s1_gatewayIn_packed_44_bore[341])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_44_bore[341] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_44_bore[342] && w_s1_gatewayIn_packed_44_bore[342])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_44_bore[342] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_44_bore[343] && w_s1_gatewayIn_packed_44_bore[343])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_44_bore[343] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_44_bore[344] && w_s1_gatewayIn_packed_44_bore[344])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_44_bore[344] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_44_bore[345] && w_s1_gatewayIn_packed_44_bore[345])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_44_bore[345] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_44_bore[346] && w_s1_gatewayIn_packed_44_bore[346])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_44_bore[346] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_44_bore[347] && w_s1_gatewayIn_packed_44_bore[347])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_44_bore[347] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_44_bore[348] && w_s1_gatewayIn_packed_44_bore[348])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_44_bore[348] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_44_bore[349] && w_s1_gatewayIn_packed_44_bore[349])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_44_bore[349] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_44_bore[350] && w_s1_gatewayIn_packed_44_bore[350])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_44_bore[350] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_44_bore[351] && w_s1_gatewayIn_packed_44_bore[351])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_44_bore[351] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_44_bore[352] && w_s1_gatewayIn_packed_44_bore[352])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_44_bore[352] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_44_bore[353] && w_s1_gatewayIn_packed_44_bore[353])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_44_bore[353] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_44_bore[354] && w_s1_gatewayIn_packed_44_bore[354])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_44_bore[354] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_44_bore[355] && w_s1_gatewayIn_packed_44_bore[355])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_44_bore[355] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_44_bore[356] && w_s1_gatewayIn_packed_44_bore[356])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_44_bore[356] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_44_bore[357] && w_s1_gatewayIn_packed_44_bore[357])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_44_bore[357] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_44_bore[358] && w_s1_gatewayIn_packed_44_bore[358])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_44_bore[358] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_44_bore[359] && w_s1_gatewayIn_packed_44_bore[359])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_44_bore[359] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_44_bore[360] && w_s1_gatewayIn_packed_44_bore[360])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_44_bore[360] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_44_bore[361] && w_s1_gatewayIn_packed_44_bore[361])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_44_bore[361] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_44_bore[362] && w_s1_gatewayIn_packed_44_bore[362])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_44_bore[362] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_44_bore[363] && w_s1_gatewayIn_packed_44_bore[363])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_44_bore[363] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_44_bore[364] && w_s1_gatewayIn_packed_44_bore[364])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_44_bore[364] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_44_bore[365] && w_s1_gatewayIn_packed_44_bore[365])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_44_bore[365] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_44_bore[366] && w_s1_gatewayIn_packed_44_bore[366])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_44_bore[366] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_44_bore[367] && w_s1_gatewayIn_packed_44_bore[367])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_44_bore[367] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_44_bore[368] && w_s1_gatewayIn_packed_44_bore[368])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_44_bore[368] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_44_bore[369] && w_s1_gatewayIn_packed_44_bore[369])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_44_bore[369] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_44_bore[370] && w_s1_gatewayIn_packed_44_bore[370])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_44_bore[370] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_44_bore[371] && w_s1_gatewayIn_packed_44_bore[371])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_44_bore[371] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_44_bore[372] && w_s1_gatewayIn_packed_44_bore[372])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_44_bore[372] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_44_bore[373] && w_s1_gatewayIn_packed_44_bore[373])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_44_bore[373] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_44_bore[374] && w_s1_gatewayIn_packed_44_bore[374])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_44_bore[374] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_44_bore[375] && w_s1_gatewayIn_packed_44_bore[375])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_44_bore[375] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_44_bore[376] && w_s1_gatewayIn_packed_44_bore[376])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_44_bore[376] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_44_bore[377] && w_s1_gatewayIn_packed_44_bore[377])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_44_bore[377] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_44_bore[378] && w_s1_gatewayIn_packed_44_bore[378])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_44_bore[378] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_44_bore[379] && w_s1_gatewayIn_packed_44_bore[379])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_44_bore[379] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_44_bore[380] && w_s1_gatewayIn_packed_44_bore[380])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_44_bore[380] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_44_bore[381] && w_s1_gatewayIn_packed_44_bore[381])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_44_bore[381] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_44_bore[382] && w_s1_gatewayIn_packed_44_bore[382])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_44_bore[382] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_44_bore[383] && w_s1_gatewayIn_packed_44_bore[383])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_44_bore[383] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_44_bore[384] && w_s1_gatewayIn_packed_44_bore[384])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_44_bore[384] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_44_bore[385] && w_s1_gatewayIn_packed_44_bore[385])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_44_bore[385] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_44_bore[386] && w_s1_gatewayIn_packed_44_bore[386])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_44_bore[386] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_44_bore[387] && w_s1_gatewayIn_packed_44_bore[387])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_44_bore[387] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_44_bore[388] && w_s1_gatewayIn_packed_44_bore[388])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_44_bore[388] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_44_bore[389] && w_s1_gatewayIn_packed_44_bore[389])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_44_bore[389] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_44_bore[390] && w_s1_gatewayIn_packed_44_bore[390])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_44_bore[390] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_44_bore[391] && w_s1_gatewayIn_packed_44_bore[391])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_44_bore[391] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_44_bore[392] && w_s1_gatewayIn_packed_44_bore[392])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_44_bore[392] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_44_bore[393] && w_s1_gatewayIn_packed_44_bore[393])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_44_bore[393] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_44_bore[394] && w_s1_gatewayIn_packed_44_bore[394])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_44_bore[394] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_44_bore[395] && w_s1_gatewayIn_packed_44_bore[395])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_44_bore[395] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_44_bore[396] && w_s1_gatewayIn_packed_44_bore[396])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_44_bore[396] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_44_bore[397] && w_s1_gatewayIn_packed_44_bore[397])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_44_bore[397] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_44_bore[398] && w_s1_gatewayIn_packed_44_bore[398])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_44_bore[398] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_44_bore[399] && w_s1_gatewayIn_packed_44_bore[399])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_44_bore[399] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_44_bore[400] && w_s1_gatewayIn_packed_44_bore[400])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_44_bore[400] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_44_bore[401] && w_s1_gatewayIn_packed_44_bore[401])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_44_bore[401] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_44_bore[402] && w_s1_gatewayIn_packed_44_bore[402])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_44_bore[402] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_44_bore[403] && w_s1_gatewayIn_packed_44_bore[403])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_44_bore[403] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_44_bore[404] && w_s1_gatewayIn_packed_44_bore[404])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_44_bore[404] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_44_bore[405] && w_s1_gatewayIn_packed_44_bore[405])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_44_bore[405] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_44_bore[406] && w_s1_gatewayIn_packed_44_bore[406])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_44_bore[406] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_44_bore[407] && w_s1_gatewayIn_packed_44_bore[407])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_44_bore[407] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_44_bore[408] && w_s1_gatewayIn_packed_44_bore[408])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_44_bore[408] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_44_bore[409] && w_s1_gatewayIn_packed_44_bore[409])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_44_bore[409] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_44_bore[410] && w_s1_gatewayIn_packed_44_bore[410])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_44_bore[410] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_44_bore[411] && w_s1_gatewayIn_packed_44_bore[411])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_44_bore[411] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_44_bore[412] && w_s1_gatewayIn_packed_44_bore[412])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_44_bore[412] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_44_bore[413] && w_s1_gatewayIn_packed_44_bore[413])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_44_bore[413] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_44_bore[414] && w_s1_gatewayIn_packed_44_bore[414])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_44_bore[414] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_44_bore[415] && w_s1_gatewayIn_packed_44_bore[415])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_44_bore[415] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_44_bore[416] && w_s1_gatewayIn_packed_44_bore[416])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_44_bore[416] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_44_bore[417] && w_s1_gatewayIn_packed_44_bore[417])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_44_bore[417] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_44_bore[418] && w_s1_gatewayIn_packed_44_bore[418])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_44_bore[418] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_44_bore[419] && w_s1_gatewayIn_packed_44_bore[419])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_44_bore[419] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_44_bore[420] && w_s1_gatewayIn_packed_44_bore[420])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_44_bore[420] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_44_bore[421] && w_s1_gatewayIn_packed_44_bore[421])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_44_bore[421] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_44_bore[422] && w_s1_gatewayIn_packed_44_bore[422])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_44_bore[422] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_44_bore[423] && w_s1_gatewayIn_packed_44_bore[423])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_44_bore[423] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_44_bore[424] && w_s1_gatewayIn_packed_44_bore[424])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_44_bore[424] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_44_bore[425] && w_s1_gatewayIn_packed_44_bore[425])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_44_bore[425] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_44_bore[426] && w_s1_gatewayIn_packed_44_bore[426])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_44_bore[426] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_44_bore[427] && w_s1_gatewayIn_packed_44_bore[427])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_44_bore[427] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_44_bore[428] && w_s1_gatewayIn_packed_44_bore[428])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_44_bore[428] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_44_bore[429] && w_s1_gatewayIn_packed_44_bore[429])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_44_bore[429] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_44_bore[430] && w_s1_gatewayIn_packed_44_bore[430])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_44_bore[430] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_44_bore[431] && w_s1_gatewayIn_packed_44_bore[431])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_44_bore[431] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_44_bore[432] && w_s1_gatewayIn_packed_44_bore[432])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_44_bore[432] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_44_bore[433] && w_s1_gatewayIn_packed_44_bore[433])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_44_bore[433] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_44_bore[434] && w_s1_gatewayIn_packed_44_bore[434])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_44_bore[434] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_44_bore[435] && w_s1_gatewayIn_packed_44_bore[435])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_44_bore[435] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_44_bore[436] && w_s1_gatewayIn_packed_44_bore[436])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_44_bore[436] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_44_bore[437] && w_s1_gatewayIn_packed_44_bore[437])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_44_bore[437] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_44_bore[438] && w_s1_gatewayIn_packed_44_bore[438])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_44_bore[438] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_44_bore[439] && w_s1_gatewayIn_packed_44_bore[439])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_44_bore[439] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_44_bore[440] && w_s1_gatewayIn_packed_44_bore[440])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_44_bore[440] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_44_bore[441] && w_s1_gatewayIn_packed_44_bore[441])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_44_bore[441] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_44_bore[442] && w_s1_gatewayIn_packed_44_bore[442])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_44_bore[442] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_44_bore[443] && w_s1_gatewayIn_packed_44_bore[443])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_44_bore[443] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_44_bore[444] && w_s1_gatewayIn_packed_44_bore[444])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_44_bore[444] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_44_bore[445] && w_s1_gatewayIn_packed_44_bore[445])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_44_bore[445] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_44_bore[446] && w_s1_gatewayIn_packed_44_bore[446])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_44_bore[446] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_44_bore[447] && w_s1_gatewayIn_packed_44_bore[447])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_44_bore[447] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_44_bore[448] && w_s1_gatewayIn_packed_44_bore[448])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_44_bore[448] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_44_bore[449] && w_s1_gatewayIn_packed_44_bore[449])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_44_bore[449] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_44_bore[450] && w_s1_gatewayIn_packed_44_bore[450])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_44_bore[450] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_44_bore[451] && w_s1_gatewayIn_packed_44_bore[451])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_44_bore[451] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_44_bore[452] && w_s1_gatewayIn_packed_44_bore[452])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_44_bore[452] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_44_bore[453] && w_s1_gatewayIn_packed_44_bore[453])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_44_bore[453] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_44_bore[454] && w_s1_gatewayIn_packed_44_bore[454])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_44_bore[454] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_44_bore[455] && w_s1_gatewayIn_packed_44_bore[455])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_44_bore[455] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_44_bore[456] && w_s1_gatewayIn_packed_44_bore[456])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_44_bore[456] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_44_bore[457] && w_s1_gatewayIn_packed_44_bore[457])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_44_bore[457] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_44_bore[458] && w_s1_gatewayIn_packed_44_bore[458])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_44_bore[458] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_44_bore[459] && w_s1_gatewayIn_packed_44_bore[459])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_44_bore[459] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_44_bore[460] && w_s1_gatewayIn_packed_44_bore[460])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_44_bore[460] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_44_bore[461] && w_s1_gatewayIn_packed_44_bore[461])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_44_bore[461] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_44_bore[462] && w_s1_gatewayIn_packed_44_bore[462])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_44_bore[462] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_44_bore[463] && w_s1_gatewayIn_packed_44_bore[463])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_44_bore[463] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_44_bore[464] && w_s1_gatewayIn_packed_44_bore[464])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_44_bore[464] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_44_bore[465] && w_s1_gatewayIn_packed_44_bore[465])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_44_bore[465] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_44_bore[466] && w_s1_gatewayIn_packed_44_bore[466])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_44_bore[466] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_44_bore[467] && w_s1_gatewayIn_packed_44_bore[467])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_44_bore[467] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_44_bore[468] && w_s1_gatewayIn_packed_44_bore[468])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_44_bore[468] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_44_bore[469] && w_s1_gatewayIn_packed_44_bore[469])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_44_bore[469] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_44_bore[470] && w_s1_gatewayIn_packed_44_bore[470])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_44_bore[470] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_44_bore[471] && w_s1_gatewayIn_packed_44_bore[471])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_44_bore[471] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_44_bore[472] && w_s1_gatewayIn_packed_44_bore[472])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_44_bore[472] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_44_bore[473] && w_s1_gatewayIn_packed_44_bore[473])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_44_bore[473] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_44_bore[474] && w_s1_gatewayIn_packed_44_bore[474])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_44_bore[474] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_44_bore[475] && w_s1_gatewayIn_packed_44_bore[475])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_44_bore[475] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_44_bore[476] && w_s1_gatewayIn_packed_44_bore[476])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_44_bore[476] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_44_bore[477] && w_s1_gatewayIn_packed_44_bore[477])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_44_bore[477] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_44_bore[478] && w_s1_gatewayIn_packed_44_bore[478])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_44_bore[478] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_44_bore[479] && w_s1_gatewayIn_packed_44_bore[479])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_44_bore[479] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_44_bore[480] && w_s1_gatewayIn_packed_44_bore[480])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_44_bore[480] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_44_bore[481] && w_s1_gatewayIn_packed_44_bore[481])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_44_bore[481] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_44_bore[482] && w_s1_gatewayIn_packed_44_bore[482])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_44_bore[482] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_44_bore[483] && w_s1_gatewayIn_packed_44_bore[483])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_44_bore[483] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_44_bore[484] && w_s1_gatewayIn_packed_44_bore[484])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_44_bore[484] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_44_bore[485] && w_s1_gatewayIn_packed_44_bore[485])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_44_bore[485] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_44_bore[486] && w_s1_gatewayIn_packed_44_bore[486])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_44_bore[486] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_44_bore[487] && w_s1_gatewayIn_packed_44_bore[487])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_44_bore[487] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_44_bore[488] && w_s1_gatewayIn_packed_44_bore[488])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_44_bore[488] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_44_bore[489] && w_s1_gatewayIn_packed_44_bore[489])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_44_bore[489] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_44_bore[490] && w_s1_gatewayIn_packed_44_bore[490])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_44_bore[490] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_44_bore[491] && w_s1_gatewayIn_packed_44_bore[491])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_44_bore[491] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_44_bore[492] && w_s1_gatewayIn_packed_44_bore[492])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_44_bore[492] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_44_bore[493] && w_s1_gatewayIn_packed_44_bore[493])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_44_bore[493] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_44_bore[494] && w_s1_gatewayIn_packed_44_bore[494])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_44_bore[494] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_44_bore[495] && w_s1_gatewayIn_packed_44_bore[495])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_44_bore[495] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_44_bore[496] && w_s1_gatewayIn_packed_44_bore[496])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_44_bore[496] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_44_bore[497] && w_s1_gatewayIn_packed_44_bore[497])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_44_bore[497] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_44_bore[498] && w_s1_gatewayIn_packed_44_bore[498])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_44_bore[498] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_44_bore[499] && w_s1_gatewayIn_packed_44_bore[499])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_44_bore[499] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_44_bore[500] && w_s1_gatewayIn_packed_44_bore[500])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_44_bore[500] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_44_bore[501] && w_s1_gatewayIn_packed_44_bore[501])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_44_bore[501] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_44_bore[502] && w_s1_gatewayIn_packed_44_bore[502])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_44_bore[502] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_44_bore[503] && w_s1_gatewayIn_packed_44_bore[503])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_44_bore[503] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_44_bore[504] && w_s1_gatewayIn_packed_44_bore[504])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_44_bore[504] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_44_bore[505] && w_s1_gatewayIn_packed_44_bore[505])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_44_bore[505] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_44_bore[506] && w_s1_gatewayIn_packed_44_bore[506])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_44_bore[506] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_44_bore[507] && w_s1_gatewayIn_packed_44_bore[507])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_44_bore[507] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_44_bore[508] && w_s1_gatewayIn_packed_44_bore[508])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_44_bore[508] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_44_bore[509] && w_s1_gatewayIn_packed_44_bore[509])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_44_bore[509] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_44_bore[510] && w_s1_gatewayIn_packed_44_bore[510])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_44_bore[510] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_44_bore[511] && w_s1_gatewayIn_packed_44_bore[511])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_44_bore[511] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_44_bore[512] && w_s1_gatewayIn_packed_44_bore[512])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_44_bore[512] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_44_bore[513] && w_s1_gatewayIn_packed_44_bore[513])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_44_bore[513] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_44_bore[514] && w_s1_gatewayIn_packed_44_bore[514])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_44_bore[514] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_44_bore[515] && w_s1_gatewayIn_packed_44_bore[515])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_44_bore[515] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_44_bore[516] && w_s1_gatewayIn_packed_44_bore[516])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_44_bore[516] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_44_bore[517] && w_s1_gatewayIn_packed_44_bore[517])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_44_bore[517] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_44_bore[518] && w_s1_gatewayIn_packed_44_bore[518])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_44_bore[518] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_44_bore[519] && w_s1_gatewayIn_packed_44_bore[519])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_44_bore[519] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_44_bore[520] && w_s1_gatewayIn_packed_44_bore[520])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_44_bore[520] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_44_bore[521] && w_s1_gatewayIn_packed_44_bore[521])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_44_bore[521] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_44_bore[522] && w_s1_gatewayIn_packed_44_bore[522])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_44_bore[522] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_44_bore[523] && w_s1_gatewayIn_packed_44_bore[523])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_44_bore[523] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_44_bore[524] && w_s1_gatewayIn_packed_44_bore[524])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_44_bore[524] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_44_bore[525] && w_s1_gatewayIn_packed_44_bore[525])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_44_bore[525] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_44_bore[526] && w_s1_gatewayIn_packed_44_bore[526])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_44_bore[526] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_44_bore[527] && w_s1_gatewayIn_packed_44_bore[527])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_44_bore[527] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_44_bore[528] && w_s1_gatewayIn_packed_44_bore[528])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_44_bore[528] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_44_bore[529] && w_s1_gatewayIn_packed_44_bore[529])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_44_bore[529] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_44_bore[530] && w_s1_gatewayIn_packed_44_bore[530])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_44_bore[530] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_44_bore[531] && w_s1_gatewayIn_packed_44_bore[531])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_44_bore[531] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_44_bore[532] && w_s1_gatewayIn_packed_44_bore[532])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_44_bore[532] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_44_bore[533] && w_s1_gatewayIn_packed_44_bore[533])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_44_bore[533] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_44_bore[534] && w_s1_gatewayIn_packed_44_bore[534])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_44_bore[534] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_44_bore[535] && w_s1_gatewayIn_packed_44_bore[535])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_44_bore[535] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_44_bore[536] && w_s1_gatewayIn_packed_44_bore[536])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_44_bore[536] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_44_bore[537] && w_s1_gatewayIn_packed_44_bore[537])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_44_bore[537] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_44_bore[538] && w_s1_gatewayIn_packed_44_bore[538])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_44_bore[538] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_44_bore[539] && w_s1_gatewayIn_packed_44_bore[539])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_44_bore[539] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_44_bore[540] && w_s1_gatewayIn_packed_44_bore[540])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_44_bore[540] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_44_bore[541] && w_s1_gatewayIn_packed_44_bore[541])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_44_bore[541] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_44_bore[542] && w_s1_gatewayIn_packed_44_bore[542])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_44_bore[542] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_44_bore[543] && w_s1_gatewayIn_packed_44_bore[543])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_44_bore[543] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_44_bore[544] && w_s1_gatewayIn_packed_44_bore[544])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_44_bore[544] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_44_bore[545] && w_s1_gatewayIn_packed_44_bore[545])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_44_bore[545] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_44_bore[546] && w_s1_gatewayIn_packed_44_bore[546])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_44_bore[546] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_44_bore[547] && w_s1_gatewayIn_packed_44_bore[547])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_44_bore[547] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_44_bore[548] && w_s1_gatewayIn_packed_44_bore[548])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_44_bore[548] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_44_bore[549] && w_s1_gatewayIn_packed_44_bore[549])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_44_bore[549] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_44_bore[550] && w_s1_gatewayIn_packed_44_bore[550])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_44_bore[550] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_44_bore[551] && w_s1_gatewayIn_packed_44_bore[551])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_44_bore[551] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_44_bore[552] && w_s1_gatewayIn_packed_44_bore[552])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_44_bore[552] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_44_bore[553] && w_s1_gatewayIn_packed_44_bore[553])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_44_bore[553] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_44_bore[554] && w_s1_gatewayIn_packed_44_bore[554])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_44_bore[554] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_44_bore[555] && w_s1_gatewayIn_packed_44_bore[555])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_44_bore[555] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_44_bore[556] && w_s1_gatewayIn_packed_44_bore[556])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_44_bore[556] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_44_bore[557] && w_s1_gatewayIn_packed_44_bore[557])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_44_bore[557] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_44_bore[558] && w_s1_gatewayIn_packed_44_bore[558])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_44_bore[558] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_44_bore[559] && w_s1_gatewayIn_packed_44_bore[559])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_44_bore[559] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_44_bore[560] && w_s1_gatewayIn_packed_44_bore[560])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_44_bore[560] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_44_bore[561] && w_s1_gatewayIn_packed_44_bore[561])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_44_bore[561] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_44_bore[562] && w_s1_gatewayIn_packed_44_bore[562])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_44_bore[562] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_44_bore[563] && w_s1_gatewayIn_packed_44_bore[563])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_44_bore[563] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_44_bore[564] && w_s1_gatewayIn_packed_44_bore[564])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_44_bore[564] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_44_bore[565] && w_s1_gatewayIn_packed_44_bore[565])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_44_bore[565] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_44_bore[566] && w_s1_gatewayIn_packed_44_bore[566])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_44_bore[566] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_44_bore[567] && w_s1_gatewayIn_packed_44_bore[567])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_44_bore[567] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_44_bore[568] && w_s1_gatewayIn_packed_44_bore[568])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_44_bore[568] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_44_bore[569] && w_s1_gatewayIn_packed_44_bore[569])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_44_bore[569] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_44_bore[570] && w_s1_gatewayIn_packed_44_bore[570])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_44_bore[570] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_44_bore[571] && w_s1_gatewayIn_packed_44_bore[571])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_44_bore[571] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_44_bore[572] && w_s1_gatewayIn_packed_44_bore[572])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_44_bore[572] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_44_bore[573] && w_s1_gatewayIn_packed_44_bore[573])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_44_bore[573] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_44_bore[574] && w_s1_gatewayIn_packed_44_bore[574])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_44_bore[574] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_44_bore[575] && w_s1_gatewayIn_packed_44_bore[575])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_44_bore[575] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_44_bore[576] && w_s1_gatewayIn_packed_44_bore[576])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_44_bore[576] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_44_bore[577] && w_s1_gatewayIn_packed_44_bore[577])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_44_bore[577] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_44_bore[578] && w_s1_gatewayIn_packed_44_bore[578])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_44_bore[578] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_44_bore[579] && w_s1_gatewayIn_packed_44_bore[579])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_44_bore[579] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_44_bore[580] && w_s1_gatewayIn_packed_44_bore[580])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_44_bore[580] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_44_bore[581] && w_s1_gatewayIn_packed_44_bore[581])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_44_bore[581] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_44_bore[582] && w_s1_gatewayIn_packed_44_bore[582])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_44_bore[582] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_44_bore[583] && w_s1_gatewayIn_packed_44_bore[583])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_44_bore[583] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_44_bore[584] && w_s1_gatewayIn_packed_44_bore[584])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_44_bore[584] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_44_bore[585] && w_s1_gatewayIn_packed_44_bore[585])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_44_bore[585] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_44_bore[586] && w_s1_gatewayIn_packed_44_bore[586])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_44_bore[586] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_44_bore[587] && w_s1_gatewayIn_packed_44_bore[587])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_44_bore[587] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_44_bore[588] && w_s1_gatewayIn_packed_44_bore[588])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_44_bore[588] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_44_bore[589] && w_s1_gatewayIn_packed_44_bore[589])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_44_bore[589] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_44_bore[590] && w_s1_gatewayIn_packed_44_bore[590])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_44_bore[590] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_44_bore[591] && w_s1_gatewayIn_packed_44_bore[591])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_44_bore[591] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_44_bore[592] && w_s1_gatewayIn_packed_44_bore[592])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_44_bore[592] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_44_bore[593] && w_s1_gatewayIn_packed_44_bore[593])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_44_bore[593] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_44_bore[594] && w_s1_gatewayIn_packed_44_bore[594])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_44_bore[594] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_44_bore[595] && w_s1_gatewayIn_packed_44_bore[595])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_44_bore[595] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_44_bore[596] && w_s1_gatewayIn_packed_44_bore[596])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_44_bore[596] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_44_bore[597] && w_s1_gatewayIn_packed_44_bore[597])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_44_bore[597] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_44_bore[598] && w_s1_gatewayIn_packed_44_bore[598])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_44_bore[598] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_44_bore[599] && w_s1_gatewayIn_packed_44_bore[599])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_44_bore[599] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_44_bore[600] && w_s1_gatewayIn_packed_44_bore[600])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_44_bore[600] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_44_bore[601] && w_s1_gatewayIn_packed_44_bore[601])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_44_bore[601] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_44_bore[602] && w_s1_gatewayIn_packed_44_bore[602])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_44_bore[602] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_44_bore[603] && w_s1_gatewayIn_packed_44_bore[603])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_44_bore[603] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_44_bore[604] && w_s1_gatewayIn_packed_44_bore[604])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_44_bore[604] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_44_bore[605] && w_s1_gatewayIn_packed_44_bore[605])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_44_bore[605] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_44_bore[606] && w_s1_gatewayIn_packed_44_bore[606])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_44_bore[606] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_44_bore[607] && w_s1_gatewayIn_packed_44_bore[607])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_44_bore[607] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_44_bore[608] && w_s1_gatewayIn_packed_44_bore[608])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_44_bore[608] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_44_bore[609] && w_s1_gatewayIn_packed_44_bore[609])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_44_bore[609] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_44_bore[610] && w_s1_gatewayIn_packed_44_bore[610])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_44_bore[610] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_44_bore[611] && w_s1_gatewayIn_packed_44_bore[611])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_44_bore[611] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_44_bore[612] && w_s1_gatewayIn_packed_44_bore[612])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_44_bore[612] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_44_bore[613] && w_s1_gatewayIn_packed_44_bore[613])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_44_bore[613] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_44_bore[614] && w_s1_gatewayIn_packed_44_bore[614])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_44_bore[614] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_44_bore[615] && w_s1_gatewayIn_packed_44_bore[615])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_44_bore[615] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_44_bore[616] && w_s1_gatewayIn_packed_44_bore[616])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_44_bore[616] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_44_bore[617] && w_s1_gatewayIn_packed_44_bore[617])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_44_bore[617] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_44_bore[618] && w_s1_gatewayIn_packed_44_bore[618])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_44_bore[618] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_44_bore[619] && w_s1_gatewayIn_packed_44_bore[619])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_44_bore[619] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_44_bore[620] && w_s1_gatewayIn_packed_44_bore[620])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_44_bore[620] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_44_bore[621] && w_s1_gatewayIn_packed_44_bore[621])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_44_bore[621] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_44_bore[622] && w_s1_gatewayIn_packed_44_bore[622])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_44_bore[622] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_44_bore[623] && w_s1_gatewayIn_packed_44_bore[623])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_44_bore[623] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_44_bore[624] && w_s1_gatewayIn_packed_44_bore[624])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_44_bore[624] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_44_bore[625] && w_s1_gatewayIn_packed_44_bore[625])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_44_bore[625] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_44_bore[626] && w_s1_gatewayIn_packed_44_bore[626])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_44_bore[626] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_44_bore[627] && w_s1_gatewayIn_packed_44_bore[627])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_44_bore[627] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_44_bore[628] && w_s1_gatewayIn_packed_44_bore[628])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_44_bore[628] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_44_bore[629] && w_s1_gatewayIn_packed_44_bore[629])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_44_bore[629] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_44_bore[630] && w_s1_gatewayIn_packed_44_bore[630])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_44_bore[630] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_44_bore[631] && w_s1_gatewayIn_packed_44_bore[631])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_44_bore[631] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_44_bore[632] && w_s1_gatewayIn_packed_44_bore[632])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_44_bore[632] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_44_bore[633] && w_s1_gatewayIn_packed_44_bore[633])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_44_bore[633] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_44_bore[634] && w_s1_gatewayIn_packed_44_bore[634])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_44_bore[634] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_44_bore[635] && w_s1_gatewayIn_packed_44_bore[635])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_44_bore[635] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_44_bore[636] && w_s1_gatewayIn_packed_44_bore[636])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_44_bore[636] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_44_bore[637] && w_s1_gatewayIn_packed_44_bore[637])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_44_bore[637] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_44_bore[638] && w_s1_gatewayIn_packed_44_bore[638])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_44_bore[638] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_44_bore[639] && w_s1_gatewayIn_packed_44_bore[639])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_44_bore[639] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_44_bore[640] && w_s1_gatewayIn_packed_44_bore[640])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_44_bore[640] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_44_bore[641] && w_s1_gatewayIn_packed_44_bore[641])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_44_bore[641] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_44_bore[642] && w_s1_gatewayIn_packed_44_bore[642])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_44_bore[642] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_44_bore[643] && w_s1_gatewayIn_packed_44_bore[643])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_44_bore[643] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_44_bore[644] && w_s1_gatewayIn_packed_44_bore[644])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_44_bore[644] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_44_bore[645] && w_s1_gatewayIn_packed_44_bore[645])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_44_bore[645] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_44_bore[646] && w_s1_gatewayIn_packed_44_bore[646])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_44_bore[646] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_44_bore[647] && w_s1_gatewayIn_packed_44_bore[647])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_44_bore[647] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_44_bore[648] && w_s1_gatewayIn_packed_44_bore[648])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_44_bore[648] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_44_bore[649] && w_s1_gatewayIn_packed_44_bore[649])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_44_bore[649] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_44_bore[650] && w_s1_gatewayIn_packed_44_bore[650])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_44_bore[650] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_44_bore[651] && w_s1_gatewayIn_packed_44_bore[651])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_44_bore[651] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_44_bore[652] && w_s1_gatewayIn_packed_44_bore[652])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_44_bore[652] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_44_bore[653] && w_s1_gatewayIn_packed_44_bore[653])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_44_bore[653] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_44_bore[654] && w_s1_gatewayIn_packed_44_bore[654])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_44_bore[654] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_44_bore[655] && w_s1_gatewayIn_packed_44_bore[655])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_44_bore[655] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_44_bore[656] && w_s1_gatewayIn_packed_44_bore[656])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_44_bore[656] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_44_bore[657] && w_s1_gatewayIn_packed_44_bore[657])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_44_bore[657] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_44_bore[658] && w_s1_gatewayIn_packed_44_bore[658])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_44_bore[658] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_44_bore[659] && w_s1_gatewayIn_packed_44_bore[659])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_44_bore[659] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_44_bore[660] && w_s1_gatewayIn_packed_44_bore[660])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_44_bore[660] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_44_bore[661] && w_s1_gatewayIn_packed_44_bore[661])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_44_bore[661] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_44_bore[662] && w_s1_gatewayIn_packed_44_bore[662])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_44_bore[662] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_44_bore[663] && w_s1_gatewayIn_packed_44_bore[663])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_44_bore[663] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_44_bore[664] && w_s1_gatewayIn_packed_44_bore[664])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_44_bore[664] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_44_bore[665] && w_s1_gatewayIn_packed_44_bore[665])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_44_bore[665] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_44_bore[666] && w_s1_gatewayIn_packed_44_bore[666])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_44_bore[666] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_44_bore[667] && w_s1_gatewayIn_packed_44_bore[667])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_44_bore[667] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_44_bore[668] && w_s1_gatewayIn_packed_44_bore[668])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_44_bore[668] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_44_bore[669] && w_s1_gatewayIn_packed_44_bore[669])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_44_bore[669] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_44_bore[670] && w_s1_gatewayIn_packed_44_bore[670])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_44_bore[670] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_44_bore[671] && w_s1_gatewayIn_packed_44_bore[671])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_44_bore[671] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_44_bore[672] && w_s1_gatewayIn_packed_44_bore[672])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_44_bore[672] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_44_bore[673] && w_s1_gatewayIn_packed_44_bore[673])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_44_bore[673] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_44_bore[674] && w_s1_gatewayIn_packed_44_bore[674])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_44_bore[674] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_44_bore[675] && w_s1_gatewayIn_packed_44_bore[675])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_44_bore[675] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_44_bore[676] && w_s1_gatewayIn_packed_44_bore[676])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_44_bore[676] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_44_bore[677] && w_s1_gatewayIn_packed_44_bore[677])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_44_bore[677] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_44_bore[678] && w_s1_gatewayIn_packed_44_bore[678])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_44_bore[678] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_44_bore[679] && w_s1_gatewayIn_packed_44_bore[679])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_44_bore[679] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_44_bore[680] && w_s1_gatewayIn_packed_44_bore[680])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_44_bore[680] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_44_bore[681] && w_s1_gatewayIn_packed_44_bore[681])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_44_bore[681] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_44_bore[682] && w_s1_gatewayIn_packed_44_bore[682])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_44_bore[682] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_44_bore[683] && w_s1_gatewayIn_packed_44_bore[683])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_44_bore[683] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_44_bore[684] && w_s1_gatewayIn_packed_44_bore[684])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_44_bore[684] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_44_bore[685] && w_s1_gatewayIn_packed_44_bore[685])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_44_bore[685] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_44_bore[686] && w_s1_gatewayIn_packed_44_bore[686])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_44_bore[686] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_44_bore[687] && w_s1_gatewayIn_packed_44_bore[687])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_44_bore[687] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_44_bore[688] && w_s1_gatewayIn_packed_44_bore[688])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_44_bore[688] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_44_bore[689] && w_s1_gatewayIn_packed_44_bore[689])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_44_bore[689] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_44_bore[690] && w_s1_gatewayIn_packed_44_bore[690])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_44_bore[690] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_44_bore[691] && w_s1_gatewayIn_packed_44_bore[691])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_44_bore[691] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_44_bore[692] && w_s1_gatewayIn_packed_44_bore[692])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_44_bore[692] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_44_bore[693] && w_s1_gatewayIn_packed_44_bore[693])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_44_bore[693] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_44_bore[694] && w_s1_gatewayIn_packed_44_bore[694])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_44_bore[694] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_44_bore[695] && w_s1_gatewayIn_packed_44_bore[695])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_44_bore[695] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_44_bore[696] && w_s1_gatewayIn_packed_44_bore[696])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_44_bore[696] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_44_bore[697] && w_s1_gatewayIn_packed_44_bore[697])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_44_bore[697] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_44_bore[698] && w_s1_gatewayIn_packed_44_bore[698])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_44_bore[698] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_44_bore[699] && w_s1_gatewayIn_packed_44_bore[699])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_44_bore[699] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_44_bore[700] && w_s1_gatewayIn_packed_44_bore[700])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_44_bore[700] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_44_bore[701] && w_s1_gatewayIn_packed_44_bore[701])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_44_bore[701] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_44_bore[702] && w_s1_gatewayIn_packed_44_bore[702])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_44_bore[702] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_44_bore[703] && w_s1_gatewayIn_packed_44_bore[703])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_44_bore[703] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_44_bore[704] && w_s1_gatewayIn_packed_44_bore[704])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_44_bore[704] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_44_bore[705] && w_s1_gatewayIn_packed_44_bore[705])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_44_bore[705] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_44_bore[706] && w_s1_gatewayIn_packed_44_bore[706])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_44_bore[706] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_44_bore[707] && w_s1_gatewayIn_packed_44_bore[707])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_44_bore[707] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_44_bore[708] && w_s1_gatewayIn_packed_44_bore[708])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_44_bore[708] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_44_bore[709] && w_s1_gatewayIn_packed_44_bore[709])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_44_bore[709] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_44_bore[710] && w_s1_gatewayIn_packed_44_bore[710])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_44_bore[710] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_44_bore[711] && w_s1_gatewayIn_packed_44_bore[711])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_44_bore[711] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_44_bore[712] && w_s1_gatewayIn_packed_44_bore[712])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_44_bore[712] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_44_bore[713] && w_s1_gatewayIn_packed_44_bore[713])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_44_bore[713] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_44_bore[714] && w_s1_gatewayIn_packed_44_bore[714])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_44_bore[714] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_44_bore[715] && w_s1_gatewayIn_packed_44_bore[715])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_44_bore[715] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_44_bore[716] && w_s1_gatewayIn_packed_44_bore[716])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_44_bore[716] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_44_bore[717] && w_s1_gatewayIn_packed_44_bore[717])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_44_bore[717] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_44_bore[718] && w_s1_gatewayIn_packed_44_bore[718])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_44_bore[718] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_44_bore[719] && w_s1_gatewayIn_packed_44_bore[719])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_44_bore[719] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_44_bore[720] && w_s1_gatewayIn_packed_44_bore[720])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_44_bore[720] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_44_bore[721] && w_s1_gatewayIn_packed_44_bore[721])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_44_bore[721] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_44_bore[722] && w_s1_gatewayIn_packed_44_bore[722])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_44_bore[722] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_44_bore[723] && w_s1_gatewayIn_packed_44_bore[723])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_44_bore[723] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_44_bore[724] && w_s1_gatewayIn_packed_44_bore[724])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_44_bore[724] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_44_bore[725] && w_s1_gatewayIn_packed_44_bore[725])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_44_bore[725] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_44_bore[726] && w_s1_gatewayIn_packed_44_bore[726])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_44_bore[726] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_44_bore[727] && w_s1_gatewayIn_packed_44_bore[727])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_44_bore[727] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_44_bore[728] && w_s1_gatewayIn_packed_44_bore[728])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_44_bore[728] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_44_bore[729] && w_s1_gatewayIn_packed_44_bore[729])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_44_bore[729] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_44_bore[730] && w_s1_gatewayIn_packed_44_bore[730])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_44_bore[730] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_44_bore[731] && w_s1_gatewayIn_packed_44_bore[731])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_44_bore[731] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_44_bore[732] && w_s1_gatewayIn_packed_44_bore[732])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_44_bore[732] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_44_bore[733] && w_s1_gatewayIn_packed_44_bore[733])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_44_bore[733] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_44_bore[734] && w_s1_gatewayIn_packed_44_bore[734])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_44_bore[734] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_44_bore[735] && w_s1_gatewayIn_packed_44_bore[735])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_44_bore[735] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_44_bore[736] && w_s1_gatewayIn_packed_44_bore[736])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_44_bore[736] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_44_bore[737] && w_s1_gatewayIn_packed_44_bore[737])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_44_bore[737] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_44_bore[738] && w_s1_gatewayIn_packed_44_bore[738])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_44_bore[738] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_44_bore[739] && w_s1_gatewayIn_packed_44_bore[739])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_44_bore[739] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_44_bore[740] && w_s1_gatewayIn_packed_44_bore[740])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_44_bore[740] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_44_bore[741] && w_s1_gatewayIn_packed_44_bore[741])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_44_bore[741] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_44_bore[742] && w_s1_gatewayIn_packed_44_bore[742])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_44_bore[742] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_44_bore[743] && w_s1_gatewayIn_packed_44_bore[743])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_44_bore[743] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_44_bore[744] && w_s1_gatewayIn_packed_44_bore[744])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_44_bore[744] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_44_bore[745] && w_s1_gatewayIn_packed_44_bore[745])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_44_bore[745] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_44_bore[746] && w_s1_gatewayIn_packed_44_bore[746])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_44_bore[746] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_44_bore[747] && w_s1_gatewayIn_packed_44_bore[747])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_44_bore[747] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_44_bore[748] && w_s1_gatewayIn_packed_44_bore[748])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_44_bore[748] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_44_bore[749] && w_s1_gatewayIn_packed_44_bore[749])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_44_bore[749] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_44_bore[750] && w_s1_gatewayIn_packed_44_bore[750])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_44_bore[750] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_44_bore[751] && w_s1_gatewayIn_packed_44_bore[751])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_44_bore[751] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_44_bore[752] && w_s1_gatewayIn_packed_44_bore[752])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_44_bore[752] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_44_bore[753] && w_s1_gatewayIn_packed_44_bore[753])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_44_bore[753] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_44_bore[754] && w_s1_gatewayIn_packed_44_bore[754])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_44_bore[754] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_44_bore[755] && w_s1_gatewayIn_packed_44_bore[755])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_44_bore[755] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_44_bore[756] && w_s1_gatewayIn_packed_44_bore[756])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_44_bore[756] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_44_bore[757] && w_s1_gatewayIn_packed_44_bore[757])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_44_bore[757] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_44_bore[758] && w_s1_gatewayIn_packed_44_bore[758])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_44_bore[758] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_44_bore[759] && w_s1_gatewayIn_packed_44_bore[759])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_44_bore[759] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_44_bore[760] && w_s1_gatewayIn_packed_44_bore[760])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_44_bore[760] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_44_bore[761] && w_s1_gatewayIn_packed_44_bore[761])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_44_bore[761] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_44_bore[762] && w_s1_gatewayIn_packed_44_bore[762])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_44_bore[762] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_44_bore[763] && w_s1_gatewayIn_packed_44_bore[763])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_44_bore[763] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_44_bore[764] && w_s1_gatewayIn_packed_44_bore[764])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_44_bore[764] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_44_bore[765] && w_s1_gatewayIn_packed_44_bore[765])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_44_bore[765] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_44_bore[766] && w_s1_gatewayIn_packed_44_bore[766])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_44_bore[766] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_44_bore[767] && w_s1_gatewayIn_packed_44_bore[767])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_44_bore[767] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_44_bore[768] && w_s1_gatewayIn_packed_44_bore[768])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_44_bore[768] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_44_bore[769] && w_s1_gatewayIn_packed_44_bore[769])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_44_bore[769] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_44_bore[770] && w_s1_gatewayIn_packed_44_bore[770])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_44_bore[770] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_44_bore[771] && w_s1_gatewayIn_packed_44_bore[771])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_44_bore[771] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_44_bore[772] && w_s1_gatewayIn_packed_44_bore[772])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_44_bore[772] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_44_bore[773] && w_s1_gatewayIn_packed_44_bore[773])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_44_bore[773] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_44_bore[774] && w_s1_gatewayIn_packed_44_bore[774])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_44_bore[774] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_44_bore[775] && w_s1_gatewayIn_packed_44_bore[775])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_44_bore[775] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_44_bore[776] && w_s1_gatewayIn_packed_44_bore[776])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_44_bore[776] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_44_bore[777] && w_s1_gatewayIn_packed_44_bore[777])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_44_bore[777] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_44_bore[778] && w_s1_gatewayIn_packed_44_bore[778])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_44_bore[778] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_44_bore[779] && w_s1_gatewayIn_packed_44_bore[779])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_44_bore[779] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_44_bore[780] && w_s1_gatewayIn_packed_44_bore[780])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_44_bore[780] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_44_bore[781] && w_s1_gatewayIn_packed_44_bore[781])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_44_bore[781] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_44_bore[782] && w_s1_gatewayIn_packed_44_bore[782])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_44_bore[782] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_44_bore[783] && w_s1_gatewayIn_packed_44_bore[783])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_44_bore[783] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_44_bore[784] && w_s1_gatewayIn_packed_44_bore[784])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_44_bore[784] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_44_bore[785] && w_s1_gatewayIn_packed_44_bore[785])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_44_bore[785] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_44_bore[786] && w_s1_gatewayIn_packed_44_bore[786])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_44_bore[786] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_44_bore[787] && w_s1_gatewayIn_packed_44_bore[787])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_44_bore[787] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_44_bore[788] && w_s1_gatewayIn_packed_44_bore[788])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_44_bore[788] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_44_bore[789] && w_s1_gatewayIn_packed_44_bore[789])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_44_bore[789] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_44_bore[790] && w_s1_gatewayIn_packed_44_bore[790])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_44_bore[790] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_44_bore[791] && w_s1_gatewayIn_packed_44_bore[791])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_44_bore[791] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_44_bore[792] && w_s1_gatewayIn_packed_44_bore[792])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_44_bore[792] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_44_bore[793] && w_s1_gatewayIn_packed_44_bore[793])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_44_bore[793] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_44_bore[794] && w_s1_gatewayIn_packed_44_bore[794])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_44_bore[794] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_44_bore[795] && w_s1_gatewayIn_packed_44_bore[795])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_44_bore[795] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_44_bore[796] && w_s1_gatewayIn_packed_44_bore[796])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_44_bore[796] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_44_bore[797] && w_s1_gatewayIn_packed_44_bore[797])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_44_bore[797] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_44_bore[798] && w_s1_gatewayIn_packed_44_bore[798])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_44_bore[798] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_44_bore[799] && w_s1_gatewayIn_packed_44_bore[799])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_44_bore[799] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_44_bore[800] && w_s1_gatewayIn_packed_44_bore[800])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_44_bore[800] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_44_bore[801] && w_s1_gatewayIn_packed_44_bore[801])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_44_bore[801] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_44_bore[802] && w_s1_gatewayIn_packed_44_bore[802])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_44_bore[802] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_44_bore[803] && w_s1_gatewayIn_packed_44_bore[803])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_44_bore[803] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_44_bore[804] && w_s1_gatewayIn_packed_44_bore[804])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_44_bore[804] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_44_bore[805] && w_s1_gatewayIn_packed_44_bore[805])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_44_bore[805] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_44_bore[806] && w_s1_gatewayIn_packed_44_bore[806])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_44_bore[806] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_44_bore[807] && w_s1_gatewayIn_packed_44_bore[807])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_44_bore[807] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_44_bore[808] && w_s1_gatewayIn_packed_44_bore[808])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_44_bore[808] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_44_bore[809] && w_s1_gatewayIn_packed_44_bore[809])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_44_bore[809] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_44_bore[810] && w_s1_gatewayIn_packed_44_bore[810])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_44_bore[810] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_44_bore[811] && w_s1_gatewayIn_packed_44_bore[811])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_44_bore[811] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_44_bore[812] && w_s1_gatewayIn_packed_44_bore[812])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_44_bore[812] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_44_bore[813] && w_s1_gatewayIn_packed_44_bore[813])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_44_bore[813] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_44_bore[814] && w_s1_gatewayIn_packed_44_bore[814])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_44_bore[814] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_44_bore[815] && w_s1_gatewayIn_packed_44_bore[815])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_44_bore[815] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_44_bore[816] && w_s1_gatewayIn_packed_44_bore[816])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_44_bore[816] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_44_bore[817] && w_s1_gatewayIn_packed_44_bore[817])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_44_bore[817] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_44_bore[818] && w_s1_gatewayIn_packed_44_bore[818])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_44_bore[818] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_44_bore[819] && w_s1_gatewayIn_packed_44_bore[819])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_44_bore[819] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_44_bore[820] && w_s1_gatewayIn_packed_44_bore[820])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_44_bore[820] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_44_bore[821] && w_s1_gatewayIn_packed_44_bore[821])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_44_bore[821] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_44_bore[822] && w_s1_gatewayIn_packed_44_bore[822])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_44_bore[822] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_44_bore[823] && w_s1_gatewayIn_packed_44_bore[823])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_44_bore[823] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_44_bore[824] && w_s1_gatewayIn_packed_44_bore[824])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_44_bore[824] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_44_bore[825] && w_s1_gatewayIn_packed_44_bore[825])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_44_bore[825] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_44_bore[826] && w_s1_gatewayIn_packed_44_bore[826])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_44_bore[826] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_44_bore[827] && w_s1_gatewayIn_packed_44_bore[827])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_44_bore[827] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_44_bore[828] && w_s1_gatewayIn_packed_44_bore[828])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_44_bore[828] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_44_bore[829] && w_s1_gatewayIn_packed_44_bore[829])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_44_bore[829] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_44_bore[830] && w_s1_gatewayIn_packed_44_bore[830])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_44_bore[830] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_44_bore[831] && w_s1_gatewayIn_packed_44_bore[831])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_44_bore[831] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_44_bore[832] && w_s1_gatewayIn_packed_44_bore[832])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_44_bore[832] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_44_bore[833] && w_s1_gatewayIn_packed_44_bore[833])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_44_bore[833] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_44_bore[834] && w_s1_gatewayIn_packed_44_bore[834])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_44_bore[834] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_44_bore[835] && w_s1_gatewayIn_packed_44_bore[835])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_44_bore[835] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_44_bore[836] && w_s1_gatewayIn_packed_44_bore[836])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_44_bore[836] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_44_bore[837] && w_s1_gatewayIn_packed_44_bore[837])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_44_bore[837] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_44_bore[838] && w_s1_gatewayIn_packed_44_bore[838])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_44_bore[838] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_44_bore[839] && w_s1_gatewayIn_packed_44_bore[839])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_44_bore[839] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_44_bore[840] && w_s1_gatewayIn_packed_44_bore[840])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_44_bore[840] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_44_bore[841] && w_s1_gatewayIn_packed_44_bore[841])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_44_bore[841] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_44_bore[842] && w_s1_gatewayIn_packed_44_bore[842])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_44_bore[842] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_44_bore[843] && w_s1_gatewayIn_packed_44_bore[843])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_44_bore[843] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_44_bore[844] && w_s1_gatewayIn_packed_44_bore[844])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_44_bore[844] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_44_bore[845] && w_s1_gatewayIn_packed_44_bore[845])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_44_bore[845] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_44_bore[846] && w_s1_gatewayIn_packed_44_bore[846])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_44_bore[846] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_44_bore[847] && w_s1_gatewayIn_packed_44_bore[847])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_44_bore[847] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_44_bore[848] && w_s1_gatewayIn_packed_44_bore[848])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_44_bore[848] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_44_bore[849] && w_s1_gatewayIn_packed_44_bore[849])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_44_bore[849] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_44_bore[850] && w_s1_gatewayIn_packed_44_bore[850])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_44_bore[850] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_44_bore[851] && w_s1_gatewayIn_packed_44_bore[851])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_44_bore[851] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_44_bore[852] && w_s1_gatewayIn_packed_44_bore[852])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_44_bore[852] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_44_bore[853] && w_s1_gatewayIn_packed_44_bore[853])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_44_bore[853] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_44_bore[854] && w_s1_gatewayIn_packed_44_bore[854])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_44_bore[854] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_44_bore[855] && w_s1_gatewayIn_packed_44_bore[855])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_44_bore[855] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_44_bore[856] && w_s1_gatewayIn_packed_44_bore[856])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_44_bore[856] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_44_bore[857] && w_s1_gatewayIn_packed_44_bore[857])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_44_bore[857] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_44_bore[858] && w_s1_gatewayIn_packed_44_bore[858])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_44_bore[858] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_44_bore[859] && w_s1_gatewayIn_packed_44_bore[859])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_44_bore[859] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_44_bore[860] && w_s1_gatewayIn_packed_44_bore[860])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_44_bore[860] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_44_bore[861] && w_s1_gatewayIn_packed_44_bore[861])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_44_bore[861] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_44_bore[862] && w_s1_gatewayIn_packed_44_bore[862])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_44_bore[862] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_44_bore[863] && w_s1_gatewayIn_packed_44_bore[863])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_44_bore[863] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_44_bore[864] && w_s1_gatewayIn_packed_44_bore[864])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_44_bore[864] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_44_bore[865] && w_s1_gatewayIn_packed_44_bore[865])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_44_bore[865] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_44_bore[866] && w_s1_gatewayIn_packed_44_bore[866])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_44_bore[866] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_44_bore[867] && w_s1_gatewayIn_packed_44_bore[867])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_44_bore[867] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_44_bore[868] && w_s1_gatewayIn_packed_44_bore[868])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_44_bore[868] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_44_bore[869] && w_s1_gatewayIn_packed_44_bore[869])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_44_bore[869] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_44_bore[870] && w_s1_gatewayIn_packed_44_bore[870])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_44_bore[870] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_44_bore[871] && w_s1_gatewayIn_packed_44_bore[871])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_44_bore[871] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_44_bore[872] && w_s1_gatewayIn_packed_44_bore[872])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_44_bore[872] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_44_bore[873] && w_s1_gatewayIn_packed_44_bore[873])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_44_bore[873] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_44_bore[874] && w_s1_gatewayIn_packed_44_bore[874])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_44_bore[874] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_44_bore[875] && w_s1_gatewayIn_packed_44_bore[875])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_44_bore[875] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_44_bore[876] && w_s1_gatewayIn_packed_44_bore[876])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_44_bore[876] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_44_bore[877] && w_s1_gatewayIn_packed_44_bore[877])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_44_bore[877] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_44_bore[878] && w_s1_gatewayIn_packed_44_bore[878])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_44_bore[878] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_44_bore[879] && w_s1_gatewayIn_packed_44_bore[879])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_44_bore[879] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_44_bore[880] && w_s1_gatewayIn_packed_44_bore[880])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_44_bore[880] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_44_bore[881] && w_s1_gatewayIn_packed_44_bore[881])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_44_bore[881] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_44_bore[882] && w_s1_gatewayIn_packed_44_bore[882])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_44_bore[882] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_44_bore[883] && w_s1_gatewayIn_packed_44_bore[883])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_44_bore[883] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_44_bore[884] && w_s1_gatewayIn_packed_44_bore[884])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_44_bore[884] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_44_bore[885] && w_s1_gatewayIn_packed_44_bore[885])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_44_bore[885] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_44_bore[886] && w_s1_gatewayIn_packed_44_bore[886])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_44_bore[886] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_44_bore[887] && w_s1_gatewayIn_packed_44_bore[887])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_44_bore[887] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_44_bore[888] && w_s1_gatewayIn_packed_44_bore[888])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_44_bore[888] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_44_bore[889] && w_s1_gatewayIn_packed_44_bore[889])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_44_bore[889] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_44_bore[890] && w_s1_gatewayIn_packed_44_bore[890])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_44_bore[890] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_44_bore[891] && w_s1_gatewayIn_packed_44_bore[891])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_44_bore[891] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_44_bore[892] && w_s1_gatewayIn_packed_44_bore[892])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_44_bore[892] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_44_bore[893] && w_s1_gatewayIn_packed_44_bore[893])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_44_bore[893] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_44_bore[894] && w_s1_gatewayIn_packed_44_bore[894])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_44_bore[894] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_44_bore[895] && w_s1_gatewayIn_packed_44_bore[895])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_44_bore[895] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_44_bore[896] && w_s1_gatewayIn_packed_44_bore[896])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_44_bore[896] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_44_bore[897] && w_s1_gatewayIn_packed_44_bore[897])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_44_bore[897] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_44_bore[898] && w_s1_gatewayIn_packed_44_bore[898])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_44_bore[898] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_44_bore[899] && w_s1_gatewayIn_packed_44_bore[899])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_44_bore[899] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_44_bore[900] && w_s1_gatewayIn_packed_44_bore[900])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_44_bore[900] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_44_bore[901] && w_s1_gatewayIn_packed_44_bore[901])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_44_bore[901] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_44_bore[902] && w_s1_gatewayIn_packed_44_bore[902])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_44_bore[902] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_44_bore[903] && w_s1_gatewayIn_packed_44_bore[903])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_44_bore[903] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_44_bore[904] && w_s1_gatewayIn_packed_44_bore[904])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_44_bore[904] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_44_bore[905] && w_s1_gatewayIn_packed_44_bore[905])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_44_bore[905] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_44_bore[906] && w_s1_gatewayIn_packed_44_bore[906])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_44_bore[906] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_44_bore[907] && w_s1_gatewayIn_packed_44_bore[907])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_44_bore[907] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_44_bore[908] && w_s1_gatewayIn_packed_44_bore[908])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_44_bore[908] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_44_bore[909] && w_s1_gatewayIn_packed_44_bore[909])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_44_bore[909] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_44_bore[910] && w_s1_gatewayIn_packed_44_bore[910])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_44_bore[910] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_44_bore[911] && w_s1_gatewayIn_packed_44_bore[911])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_44_bore[911] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_44_bore[912] && w_s1_gatewayIn_packed_44_bore[912])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_44_bore[912] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_44_bore[913] && w_s1_gatewayIn_packed_44_bore[913])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_44_bore[913] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_44_bore[914] && w_s1_gatewayIn_packed_44_bore[914])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_44_bore[914] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_44_bore[915] && w_s1_gatewayIn_packed_44_bore[915])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_44_bore[915] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_44_bore[916] && w_s1_gatewayIn_packed_44_bore[916])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_44_bore[916] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_44_bore[917] && w_s1_gatewayIn_packed_44_bore[917])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_44_bore[917] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_44_bore[918] && w_s1_gatewayIn_packed_44_bore[918])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_44_bore[918] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_44_bore[919] && w_s1_gatewayIn_packed_44_bore[919])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_44_bore[919] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_44_bore[920] && w_s1_gatewayIn_packed_44_bore[920])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_44_bore[920] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_44_bore[921] && w_s1_gatewayIn_packed_44_bore[921])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_44_bore[921] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_44_bore[922] && w_s1_gatewayIn_packed_44_bore[922])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_44_bore[922] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_44_bore[923] && w_s1_gatewayIn_packed_44_bore[923])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_44_bore[923] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_44_bore[924] && w_s1_gatewayIn_packed_44_bore[924])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_44_bore[924] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_44_bore[925] && w_s1_gatewayIn_packed_44_bore[925])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_44_bore[925] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_44_bore[926] && w_s1_gatewayIn_packed_44_bore[926])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_44_bore[926] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_44_bore[927] && w_s1_gatewayIn_packed_44_bore[927])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_44_bore[927] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_44_bore[928] && w_s1_gatewayIn_packed_44_bore[928])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_44_bore[928] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_44_bore[929] && w_s1_gatewayIn_packed_44_bore[929])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_44_bore[929] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_44_bore[930] && w_s1_gatewayIn_packed_44_bore[930])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_44_bore[930] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_44_bore[931] && w_s1_gatewayIn_packed_44_bore[931])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_44_bore[931] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_44_bore[932] && w_s1_gatewayIn_packed_44_bore[932])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_44_bore[932] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_44_bore[933] && w_s1_gatewayIn_packed_44_bore[933])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_44_bore[933] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_44_bore[934] && w_s1_gatewayIn_packed_44_bore[934])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_44_bore[934] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_44_bore[935] && w_s1_gatewayIn_packed_44_bore[935])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_44_bore[935] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_44_bore[936] && w_s1_gatewayIn_packed_44_bore[936])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_44_bore[936] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_44_bore[937] && w_s1_gatewayIn_packed_44_bore[937])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_44_bore[937] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_44_bore[938] && w_s1_gatewayIn_packed_44_bore[938])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_44_bore[938] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_44_bore[939] && w_s1_gatewayIn_packed_44_bore[939])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_44_bore[939] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_44_bore[940] && w_s1_gatewayIn_packed_44_bore[940])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_44_bore[940] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_44_bore[941] && w_s1_gatewayIn_packed_44_bore[941])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_44_bore[941] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_44_bore[942] && w_s1_gatewayIn_packed_44_bore[942])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_44_bore[942] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_44_bore[943] && w_s1_gatewayIn_packed_44_bore[943])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_44_bore[943] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_44_bore[944] && w_s1_gatewayIn_packed_44_bore[944])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_44_bore[944] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_44_bore[945] && w_s1_gatewayIn_packed_44_bore[945])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_44_bore[945] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_44_bore[946] && w_s1_gatewayIn_packed_44_bore[946])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_44_bore[946] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_44_bore[947] && w_s1_gatewayIn_packed_44_bore[947])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_44_bore[947] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_44_bore[948] && w_s1_gatewayIn_packed_44_bore[948])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_44_bore[948] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_44_bore[949] && w_s1_gatewayIn_packed_44_bore[949])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_44_bore[949] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_44_bore[950] && w_s1_gatewayIn_packed_44_bore[950])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_44_bore[950] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_44_bore[951] && w_s1_gatewayIn_packed_44_bore[951])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_44_bore[951] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_44_bore[952] && w_s1_gatewayIn_packed_44_bore[952])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_44_bore[952] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_44_bore[953] && w_s1_gatewayIn_packed_44_bore[953])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_44_bore[953] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_44_bore[954] && w_s1_gatewayIn_packed_44_bore[954])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_44_bore[954] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_44_bore[955] && w_s1_gatewayIn_packed_44_bore[955])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_44_bore[955] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_44_bore[956] && w_s1_gatewayIn_packed_44_bore[956])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_44_bore[956] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_44_bore[957] && w_s1_gatewayIn_packed_44_bore[957])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_44_bore[957] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_44_bore[958] && w_s1_gatewayIn_packed_44_bore[958])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_44_bore[958] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_44_bore[959] && w_s1_gatewayIn_packed_44_bore[959])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_44_bore[959] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_44_bore[960] && w_s1_gatewayIn_packed_44_bore[960])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_44_bore[960] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_44_bore[961] && w_s1_gatewayIn_packed_44_bore[961])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_44_bore[961] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_44_bore[962] && w_s1_gatewayIn_packed_44_bore[962])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_44_bore[962] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_44_bore[963] && w_s1_gatewayIn_packed_44_bore[963])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_44_bore[963] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_44_bore[964] && w_s1_gatewayIn_packed_44_bore[964])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_44_bore[964] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_44_bore[965] && w_s1_gatewayIn_packed_44_bore[965])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_44_bore[965] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_44_bore[966] && w_s1_gatewayIn_packed_44_bore[966])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_44_bore[966] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_44_bore[967] && w_s1_gatewayIn_packed_44_bore[967])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_44_bore[967] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_44_bore[968] && w_s1_gatewayIn_packed_44_bore[968])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_44_bore[968] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_45_bore[0] && w_s1_gatewayIn_packed_45_bore[0])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_45_bore[0] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_45_bore[1] && w_s1_gatewayIn_packed_45_bore[1])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_45_bore[1] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_45_bore[2] && w_s1_gatewayIn_packed_45_bore[2])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_45_bore[2] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_45_bore[3] && w_s1_gatewayIn_packed_45_bore[3])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_45_bore[3] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_45_bore[4] && w_s1_gatewayIn_packed_45_bore[4])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_45_bore[4] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_45_bore[5] && w_s1_gatewayIn_packed_45_bore[5])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_45_bore[5] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_45_bore[6] && w_s1_gatewayIn_packed_45_bore[6])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_45_bore[6] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_45_bore[7] && w_s1_gatewayIn_packed_45_bore[7])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_45_bore[7] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_45_bore[8] && w_s1_gatewayIn_packed_45_bore[8])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_45_bore[8] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_45_bore[9] && w_s1_gatewayIn_packed_45_bore[9])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_45_bore[9] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_45_bore[10] && w_s1_gatewayIn_packed_45_bore[10])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_45_bore[10] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_45_bore[11] && w_s1_gatewayIn_packed_45_bore[11])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_45_bore[11] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_45_bore[12] && w_s1_gatewayIn_packed_45_bore[12])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_45_bore[12] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_45_bore[13] && w_s1_gatewayIn_packed_45_bore[13])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_45_bore[13] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_45_bore[14] && w_s1_gatewayIn_packed_45_bore[14])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_45_bore[14] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_45_bore[15] && w_s1_gatewayIn_packed_45_bore[15])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_45_bore[15] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_45_bore[16] && w_s1_gatewayIn_packed_45_bore[16])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_45_bore[16] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_45_bore[17] && w_s1_gatewayIn_packed_45_bore[17])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_45_bore[17] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_45_bore[18] && w_s1_gatewayIn_packed_45_bore[18])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_45_bore[18] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_45_bore[19] && w_s1_gatewayIn_packed_45_bore[19])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_45_bore[19] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_45_bore[20] && w_s1_gatewayIn_packed_45_bore[20])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_45_bore[20] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_45_bore[21] && w_s1_gatewayIn_packed_45_bore[21])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_45_bore[21] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_45_bore[22] && w_s1_gatewayIn_packed_45_bore[22])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_45_bore[22] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_45_bore[23] && w_s1_gatewayIn_packed_45_bore[23])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_45_bore[23] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_45_bore[24] && w_s1_gatewayIn_packed_45_bore[24])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_45_bore[24] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_45_bore[25] && w_s1_gatewayIn_packed_45_bore[25])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_45_bore[25] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_45_bore[26] && w_s1_gatewayIn_packed_45_bore[26])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_45_bore[26] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_45_bore[27] && w_s1_gatewayIn_packed_45_bore[27])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_45_bore[27] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_45_bore[28] && w_s1_gatewayIn_packed_45_bore[28])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_45_bore[28] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_45_bore[29] && w_s1_gatewayIn_packed_45_bore[29])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_45_bore[29] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_45_bore[30] && w_s1_gatewayIn_packed_45_bore[30])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_45_bore[30] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_45_bore[31] && w_s1_gatewayIn_packed_45_bore[31])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_45_bore[31] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_45_bore[32] && w_s1_gatewayIn_packed_45_bore[32])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_45_bore[32] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_45_bore[33] && w_s1_gatewayIn_packed_45_bore[33])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_45_bore[33] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_45_bore[34] && w_s1_gatewayIn_packed_45_bore[34])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_45_bore[34] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_45_bore[35] && w_s1_gatewayIn_packed_45_bore[35])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_45_bore[35] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_45_bore[36] && w_s1_gatewayIn_packed_45_bore[36])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_45_bore[36] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_45_bore[37] && w_s1_gatewayIn_packed_45_bore[37])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_45_bore[37] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_45_bore[38] && w_s1_gatewayIn_packed_45_bore[38])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_45_bore[38] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_45_bore[39] && w_s1_gatewayIn_packed_45_bore[39])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_45_bore[39] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_45_bore[40] && w_s1_gatewayIn_packed_45_bore[40])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_45_bore[40] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_45_bore[41] && w_s1_gatewayIn_packed_45_bore[41])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_45_bore[41] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_45_bore[42] && w_s1_gatewayIn_packed_45_bore[42])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_45_bore[42] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_45_bore[43] && w_s1_gatewayIn_packed_45_bore[43])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_45_bore[43] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_45_bore[44] && w_s1_gatewayIn_packed_45_bore[44])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_45_bore[44] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_45_bore[45] && w_s1_gatewayIn_packed_45_bore[45])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_45_bore[45] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_45_bore[46] && w_s1_gatewayIn_packed_45_bore[46])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_45_bore[46] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_45_bore[47] && w_s1_gatewayIn_packed_45_bore[47])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_45_bore[47] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_45_bore[48] && w_s1_gatewayIn_packed_45_bore[48])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_45_bore[48] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_45_bore[49] && w_s1_gatewayIn_packed_45_bore[49])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_45_bore[49] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_45_bore[50] && w_s1_gatewayIn_packed_45_bore[50])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_45_bore[50] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_45_bore[51] && w_s1_gatewayIn_packed_45_bore[51])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_45_bore[51] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_45_bore[52] && w_s1_gatewayIn_packed_45_bore[52])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_45_bore[52] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_45_bore[53] && w_s1_gatewayIn_packed_45_bore[53])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_45_bore[53] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_45_bore[54] && w_s1_gatewayIn_packed_45_bore[54])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_45_bore[54] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_45_bore[55] && w_s1_gatewayIn_packed_45_bore[55])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_45_bore[55] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_45_bore[56] && w_s1_gatewayIn_packed_45_bore[56])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_45_bore[56] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_45_bore[57] && w_s1_gatewayIn_packed_45_bore[57])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_45_bore[57] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_45_bore[58] && w_s1_gatewayIn_packed_45_bore[58])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_45_bore[58] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_45_bore[59] && w_s1_gatewayIn_packed_45_bore[59])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_45_bore[59] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_45_bore[60] && w_s1_gatewayIn_packed_45_bore[60])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_45_bore[60] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_45_bore[61] && w_s1_gatewayIn_packed_45_bore[61])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_45_bore[61] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_45_bore[62] && w_s1_gatewayIn_packed_45_bore[62])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_45_bore[62] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_45_bore[63] && w_s1_gatewayIn_packed_45_bore[63])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_45_bore[63] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_45_bore[64] && w_s1_gatewayIn_packed_45_bore[64])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_45_bore[64] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_45_bore[65] && w_s1_gatewayIn_packed_45_bore[65])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_45_bore[65] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_45_bore[66] && w_s1_gatewayIn_packed_45_bore[66])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_45_bore[66] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_45_bore[67] && w_s1_gatewayIn_packed_45_bore[67])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_45_bore[67] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_45_bore[68] && w_s1_gatewayIn_packed_45_bore[68])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_45_bore[68] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_45_bore[69] && w_s1_gatewayIn_packed_45_bore[69])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_45_bore[69] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_45_bore[70] && w_s1_gatewayIn_packed_45_bore[70])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_45_bore[70] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_45_bore[71] && w_s1_gatewayIn_packed_45_bore[71])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_45_bore[71] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_45_bore[72] && w_s1_gatewayIn_packed_45_bore[72])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_45_bore[72] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_45_bore[73] && w_s1_gatewayIn_packed_45_bore[73])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_45_bore[73] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_45_bore[74] && w_s1_gatewayIn_packed_45_bore[74])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_45_bore[74] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_45_bore[75] && w_s1_gatewayIn_packed_45_bore[75])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_45_bore[75] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_45_bore[76] && w_s1_gatewayIn_packed_45_bore[76])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_45_bore[76] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_45_bore[77] && w_s1_gatewayIn_packed_45_bore[77])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_45_bore[77] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_45_bore[78] && w_s1_gatewayIn_packed_45_bore[78])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_45_bore[78] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_45_bore[79] && w_s1_gatewayIn_packed_45_bore[79])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_45_bore[79] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_45_bore[80] && w_s1_gatewayIn_packed_45_bore[80])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_45_bore[80] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_45_bore[81] && w_s1_gatewayIn_packed_45_bore[81])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_45_bore[81] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_45_bore[82] && w_s1_gatewayIn_packed_45_bore[82])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_45_bore[82] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_45_bore[83] && w_s1_gatewayIn_packed_45_bore[83])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_45_bore[83] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_45_bore[84] && w_s1_gatewayIn_packed_45_bore[84])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_45_bore[84] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_45_bore[85] && w_s1_gatewayIn_packed_45_bore[85])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_45_bore[85] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_45_bore[86] && w_s1_gatewayIn_packed_45_bore[86])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_45_bore[86] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_45_bore[87] && w_s1_gatewayIn_packed_45_bore[87])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_45_bore[87] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_45_bore[88] && w_s1_gatewayIn_packed_45_bore[88])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_45_bore[88] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_45_bore[89] && w_s1_gatewayIn_packed_45_bore[89])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_45_bore[89] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_45_bore[90] && w_s1_gatewayIn_packed_45_bore[90])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_45_bore[90] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_45_bore[91] && w_s1_gatewayIn_packed_45_bore[91])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_45_bore[91] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_45_bore[92] && w_s1_gatewayIn_packed_45_bore[92])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_45_bore[92] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_45_bore[93] && w_s1_gatewayIn_packed_45_bore[93])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_45_bore[93] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_45_bore[94] && w_s1_gatewayIn_packed_45_bore[94])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_45_bore[94] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_45_bore[95] && w_s1_gatewayIn_packed_45_bore[95])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_45_bore[95] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_45_bore[96] && w_s1_gatewayIn_packed_45_bore[96])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_45_bore[96] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_45_bore[97] && w_s1_gatewayIn_packed_45_bore[97])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_45_bore[97] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_45_bore[98] && w_s1_gatewayIn_packed_45_bore[98])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_45_bore[98] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_45_bore[99] && w_s1_gatewayIn_packed_45_bore[99])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_45_bore[99] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_45_bore[100] && w_s1_gatewayIn_packed_45_bore[100])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_45_bore[100] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_45_bore[101] && w_s1_gatewayIn_packed_45_bore[101])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_45_bore[101] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_45_bore[102] && w_s1_gatewayIn_packed_45_bore[102])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_45_bore[102] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_45_bore[103] && w_s1_gatewayIn_packed_45_bore[103])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_45_bore[103] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_45_bore[104] && w_s1_gatewayIn_packed_45_bore[104])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_45_bore[104] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_45_bore[105] && w_s1_gatewayIn_packed_45_bore[105])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_45_bore[105] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_45_bore[106] && w_s1_gatewayIn_packed_45_bore[106])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_45_bore[106] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_45_bore[107] && w_s1_gatewayIn_packed_45_bore[107])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_45_bore[107] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_45_bore[108] && w_s1_gatewayIn_packed_45_bore[108])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_45_bore[108] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_45_bore[109] && w_s1_gatewayIn_packed_45_bore[109])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_45_bore[109] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_45_bore[110] && w_s1_gatewayIn_packed_45_bore[110])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_45_bore[110] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_45_bore[111] && w_s1_gatewayIn_packed_45_bore[111])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_45_bore[111] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_45_bore[112] && w_s1_gatewayIn_packed_45_bore[112])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_45_bore[112] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_45_bore[113] && w_s1_gatewayIn_packed_45_bore[113])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_45_bore[113] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_45_bore[114] && w_s1_gatewayIn_packed_45_bore[114])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_45_bore[114] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_45_bore[115] && w_s1_gatewayIn_packed_45_bore[115])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_45_bore[115] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_45_bore[116] && w_s1_gatewayIn_packed_45_bore[116])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_45_bore[116] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_45_bore[117] && w_s1_gatewayIn_packed_45_bore[117])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_45_bore[117] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_45_bore[118] && w_s1_gatewayIn_packed_45_bore[118])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_45_bore[118] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_45_bore[119] && w_s1_gatewayIn_packed_45_bore[119])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_45_bore[119] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_45_bore[120] && w_s1_gatewayIn_packed_45_bore[120])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_45_bore[120] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_45_bore[121] && w_s1_gatewayIn_packed_45_bore[121])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_45_bore[121] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_45_bore[122] && w_s1_gatewayIn_packed_45_bore[122])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_45_bore[122] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_45_bore[123] && w_s1_gatewayIn_packed_45_bore[123])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_45_bore[123] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_45_bore[124] && w_s1_gatewayIn_packed_45_bore[124])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_45_bore[124] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_45_bore[125] && w_s1_gatewayIn_packed_45_bore[125])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_45_bore[125] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_45_bore[126] && w_s1_gatewayIn_packed_45_bore[126])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_45_bore[126] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_45_bore[127] && w_s1_gatewayIn_packed_45_bore[127])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_45_bore[127] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_45_bore[128] && w_s1_gatewayIn_packed_45_bore[128])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_45_bore[128] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_45_bore[129] && w_s1_gatewayIn_packed_45_bore[129])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_45_bore[129] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_45_bore[130] && w_s1_gatewayIn_packed_45_bore[130])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_45_bore[130] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_45_bore[131] && w_s1_gatewayIn_packed_45_bore[131])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_45_bore[131] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_45_bore[132] && w_s1_gatewayIn_packed_45_bore[132])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_45_bore[132] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_45_bore[133] && w_s1_gatewayIn_packed_45_bore[133])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_45_bore[133] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_45_bore[134] && w_s1_gatewayIn_packed_45_bore[134])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_45_bore[134] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_45_bore[135] && w_s1_gatewayIn_packed_45_bore[135])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_45_bore[135] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_45_bore[136] && w_s1_gatewayIn_packed_45_bore[136])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_45_bore[136] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_45_bore[137] && w_s1_gatewayIn_packed_45_bore[137])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_45_bore[137] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_45_bore[138] && w_s1_gatewayIn_packed_45_bore[138])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_45_bore[138] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_45_bore[139] && w_s1_gatewayIn_packed_45_bore[139])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_45_bore[139] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_45_bore[140] && w_s1_gatewayIn_packed_45_bore[140])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_45_bore[140] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_45_bore[141] && w_s1_gatewayIn_packed_45_bore[141])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_45_bore[141] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_45_bore[142] && w_s1_gatewayIn_packed_45_bore[142])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_45_bore[142] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_45_bore[143] && w_s1_gatewayIn_packed_45_bore[143])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_45_bore[143] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_45_bore[144] && w_s1_gatewayIn_packed_45_bore[144])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_45_bore[144] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_45_bore[145] && w_s1_gatewayIn_packed_45_bore[145])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_45_bore[145] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_45_bore[146] && w_s1_gatewayIn_packed_45_bore[146])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_45_bore[146] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_45_bore[147] && w_s1_gatewayIn_packed_45_bore[147])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_45_bore[147] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_45_bore[148] && w_s1_gatewayIn_packed_45_bore[148])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_45_bore[148] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_45_bore[149] && w_s1_gatewayIn_packed_45_bore[149])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_45_bore[149] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_45_bore[150] && w_s1_gatewayIn_packed_45_bore[150])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_45_bore[150] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_45_bore[151] && w_s1_gatewayIn_packed_45_bore[151])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_45_bore[151] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_45_bore[152] && w_s1_gatewayIn_packed_45_bore[152])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_45_bore[152] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_45_bore[153] && w_s1_gatewayIn_packed_45_bore[153])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_45_bore[153] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_45_bore[154] && w_s1_gatewayIn_packed_45_bore[154])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_45_bore[154] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_45_bore[155] && w_s1_gatewayIn_packed_45_bore[155])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_45_bore[155] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_45_bore[156] && w_s1_gatewayIn_packed_45_bore[156])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_45_bore[156] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_45_bore[157] && w_s1_gatewayIn_packed_45_bore[157])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_45_bore[157] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_45_bore[158] && w_s1_gatewayIn_packed_45_bore[158])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_45_bore[158] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_45_bore[159] && w_s1_gatewayIn_packed_45_bore[159])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_45_bore[159] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_45_bore[160] && w_s1_gatewayIn_packed_45_bore[160])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_45_bore[160] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_45_bore[161] && w_s1_gatewayIn_packed_45_bore[161])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_45_bore[161] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_45_bore[162] && w_s1_gatewayIn_packed_45_bore[162])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_45_bore[162] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_45_bore[163] && w_s1_gatewayIn_packed_45_bore[163])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_45_bore[163] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_45_bore[164] && w_s1_gatewayIn_packed_45_bore[164])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_45_bore[164] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_45_bore[165] && w_s1_gatewayIn_packed_45_bore[165])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_45_bore[165] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_45_bore[166] && w_s1_gatewayIn_packed_45_bore[166])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_45_bore[166] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_45_bore[167] && w_s1_gatewayIn_packed_45_bore[167])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_45_bore[167] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_45_bore[168] && w_s1_gatewayIn_packed_45_bore[168])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_45_bore[168] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_45_bore[169] && w_s1_gatewayIn_packed_45_bore[169])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_45_bore[169] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_45_bore[170] && w_s1_gatewayIn_packed_45_bore[170])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_45_bore[170] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_45_bore[171] && w_s1_gatewayIn_packed_45_bore[171])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_45_bore[171] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_45_bore[172] && w_s1_gatewayIn_packed_45_bore[172])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_45_bore[172] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_45_bore[173] && w_s1_gatewayIn_packed_45_bore[173])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_45_bore[173] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_45_bore[174] && w_s1_gatewayIn_packed_45_bore[174])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_45_bore[174] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_45_bore[175] && w_s1_gatewayIn_packed_45_bore[175])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_45_bore[175] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_45_bore[176] && w_s1_gatewayIn_packed_45_bore[176])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_45_bore[176] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_45_bore[177] && w_s1_gatewayIn_packed_45_bore[177])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_45_bore[177] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_45_bore[178] && w_s1_gatewayIn_packed_45_bore[178])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_45_bore[178] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_45_bore[179] && w_s1_gatewayIn_packed_45_bore[179])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_45_bore[179] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_45_bore[180] && w_s1_gatewayIn_packed_45_bore[180])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_45_bore[180] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_45_bore[181] && w_s1_gatewayIn_packed_45_bore[181])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_45_bore[181] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_45_bore[182] && w_s1_gatewayIn_packed_45_bore[182])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_45_bore[182] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_45_bore[183] && w_s1_gatewayIn_packed_45_bore[183])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_45_bore[183] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_45_bore[184] && w_s1_gatewayIn_packed_45_bore[184])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_45_bore[184] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_45_bore[185] && w_s1_gatewayIn_packed_45_bore[185])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_45_bore[185] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_45_bore[186] && w_s1_gatewayIn_packed_45_bore[186])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_45_bore[186] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_45_bore[187] && w_s1_gatewayIn_packed_45_bore[187])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_45_bore[187] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_45_bore[188] && w_s1_gatewayIn_packed_45_bore[188])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_45_bore[188] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_45_bore[189] && w_s1_gatewayIn_packed_45_bore[189])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_45_bore[189] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_45_bore[190] && w_s1_gatewayIn_packed_45_bore[190])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_45_bore[190] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_45_bore[191] && w_s1_gatewayIn_packed_45_bore[191])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_45_bore[191] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_45_bore[192] && w_s1_gatewayIn_packed_45_bore[192])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_45_bore[192] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_45_bore[193] && w_s1_gatewayIn_packed_45_bore[193])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_45_bore[193] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_45_bore[194] && w_s1_gatewayIn_packed_45_bore[194])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_45_bore[194] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_45_bore[195] && w_s1_gatewayIn_packed_45_bore[195])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_45_bore[195] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_45_bore[196] && w_s1_gatewayIn_packed_45_bore[196])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_45_bore[196] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_45_bore[197] && w_s1_gatewayIn_packed_45_bore[197])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_45_bore[197] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_45_bore[198] && w_s1_gatewayIn_packed_45_bore[198])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_45_bore[198] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_45_bore[199] && w_s1_gatewayIn_packed_45_bore[199])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_45_bore[199] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_45_bore[200] && w_s1_gatewayIn_packed_45_bore[200])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_45_bore[200] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_45_bore[201] && w_s1_gatewayIn_packed_45_bore[201])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_45_bore[201] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_45_bore[202] && w_s1_gatewayIn_packed_45_bore[202])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_45_bore[202] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_45_bore[203] && w_s1_gatewayIn_packed_45_bore[203])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_45_bore[203] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_45_bore[204] && w_s1_gatewayIn_packed_45_bore[204])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_45_bore[204] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_45_bore[205] && w_s1_gatewayIn_packed_45_bore[205])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_45_bore[205] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_45_bore[206] && w_s1_gatewayIn_packed_45_bore[206])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_45_bore[206] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_45_bore[207] && w_s1_gatewayIn_packed_45_bore[207])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_45_bore[207] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_45_bore[208] && w_s1_gatewayIn_packed_45_bore[208])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_45_bore[208] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_45_bore[209] && w_s1_gatewayIn_packed_45_bore[209])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_45_bore[209] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_45_bore[210] && w_s1_gatewayIn_packed_45_bore[210])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_45_bore[210] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_45_bore[211] && w_s1_gatewayIn_packed_45_bore[211])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_45_bore[211] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_45_bore[212] && w_s1_gatewayIn_packed_45_bore[212])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_45_bore[212] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_45_bore[213] && w_s1_gatewayIn_packed_45_bore[213])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_45_bore[213] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_45_bore[214] && w_s1_gatewayIn_packed_45_bore[214])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_45_bore[214] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_45_bore[215] && w_s1_gatewayIn_packed_45_bore[215])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_45_bore[215] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_45_bore[216] && w_s1_gatewayIn_packed_45_bore[216])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_45_bore[216] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_45_bore[217] && w_s1_gatewayIn_packed_45_bore[217])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_45_bore[217] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_45_bore[218] && w_s1_gatewayIn_packed_45_bore[218])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_45_bore[218] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_45_bore[219] && w_s1_gatewayIn_packed_45_bore[219])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_45_bore[219] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_45_bore[220] && w_s1_gatewayIn_packed_45_bore[220])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_45_bore[220] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_45_bore[221] && w_s1_gatewayIn_packed_45_bore[221])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_45_bore[221] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_45_bore[222] && w_s1_gatewayIn_packed_45_bore[222])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_45_bore[222] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_45_bore[223] && w_s1_gatewayIn_packed_45_bore[223])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_45_bore[223] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_45_bore[224] && w_s1_gatewayIn_packed_45_bore[224])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_45_bore[224] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_45_bore[225] && w_s1_gatewayIn_packed_45_bore[225])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_45_bore[225] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_45_bore[226] && w_s1_gatewayIn_packed_45_bore[226])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_45_bore[226] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_45_bore[227] && w_s1_gatewayIn_packed_45_bore[227])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_45_bore[227] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_45_bore[228] && w_s1_gatewayIn_packed_45_bore[228])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_45_bore[228] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_45_bore[229] && w_s1_gatewayIn_packed_45_bore[229])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_45_bore[229] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_45_bore[230] && w_s1_gatewayIn_packed_45_bore[230])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_45_bore[230] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_45_bore[231] && w_s1_gatewayIn_packed_45_bore[231])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_45_bore[231] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_45_bore[232] && w_s1_gatewayIn_packed_45_bore[232])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_45_bore[232] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_45_bore[233] && w_s1_gatewayIn_packed_45_bore[233])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_45_bore[233] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_45_bore[234] && w_s1_gatewayIn_packed_45_bore[234])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_45_bore[234] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_45_bore[235] && w_s1_gatewayIn_packed_45_bore[235])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_45_bore[235] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_45_bore[236] && w_s1_gatewayIn_packed_45_bore[236])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_45_bore[236] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_45_bore[237] && w_s1_gatewayIn_packed_45_bore[237])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_45_bore[237] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_45_bore[238] && w_s1_gatewayIn_packed_45_bore[238])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_45_bore[238] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_45_bore[239] && w_s1_gatewayIn_packed_45_bore[239])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_45_bore[239] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_45_bore[240] && w_s1_gatewayIn_packed_45_bore[240])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_45_bore[240] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_45_bore[241] && w_s1_gatewayIn_packed_45_bore[241])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_45_bore[241] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_45_bore[242] && w_s1_gatewayIn_packed_45_bore[242])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_45_bore[242] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_45_bore[243] && w_s1_gatewayIn_packed_45_bore[243])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_45_bore[243] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_45_bore[244] && w_s1_gatewayIn_packed_45_bore[244])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_45_bore[244] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_45_bore[245] && w_s1_gatewayIn_packed_45_bore[245])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_45_bore[245] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_45_bore[246] && w_s1_gatewayIn_packed_45_bore[246])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_45_bore[246] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_45_bore[247] && w_s1_gatewayIn_packed_45_bore[247])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_45_bore[247] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_45_bore[248] && w_s1_gatewayIn_packed_45_bore[248])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_45_bore[248] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_45_bore[249] && w_s1_gatewayIn_packed_45_bore[249])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_45_bore[249] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_45_bore[250] && w_s1_gatewayIn_packed_45_bore[250])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_45_bore[250] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_45_bore[251] && w_s1_gatewayIn_packed_45_bore[251])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_45_bore[251] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_45_bore[252] && w_s1_gatewayIn_packed_45_bore[252])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_45_bore[252] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_45_bore[253] && w_s1_gatewayIn_packed_45_bore[253])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_45_bore[253] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_45_bore[254] && w_s1_gatewayIn_packed_45_bore[254])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_45_bore[254] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_45_bore[255] && w_s1_gatewayIn_packed_45_bore[255])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_45_bore[255] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_45_bore[256] && w_s1_gatewayIn_packed_45_bore[256])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_45_bore[256] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_45_bore[257] && w_s1_gatewayIn_packed_45_bore[257])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_45_bore[257] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_45_bore[258] && w_s1_gatewayIn_packed_45_bore[258])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_45_bore[258] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_45_bore[259] && w_s1_gatewayIn_packed_45_bore[259])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_45_bore[259] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_45_bore[260] && w_s1_gatewayIn_packed_45_bore[260])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_45_bore[260] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_45_bore[261] && w_s1_gatewayIn_packed_45_bore[261])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_45_bore[261] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_45_bore[262] && w_s1_gatewayIn_packed_45_bore[262])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_45_bore[262] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_45_bore[263] && w_s1_gatewayIn_packed_45_bore[263])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_45_bore[263] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_45_bore[264] && w_s1_gatewayIn_packed_45_bore[264])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_45_bore[264] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_45_bore[265] && w_s1_gatewayIn_packed_45_bore[265])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_45_bore[265] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_45_bore[266] && w_s1_gatewayIn_packed_45_bore[266])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_45_bore[266] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_45_bore[267] && w_s1_gatewayIn_packed_45_bore[267])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_45_bore[267] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_45_bore[268] && w_s1_gatewayIn_packed_45_bore[268])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_45_bore[268] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_45_bore[269] && w_s1_gatewayIn_packed_45_bore[269])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_45_bore[269] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_45_bore[270] && w_s1_gatewayIn_packed_45_bore[270])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_45_bore[270] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_45_bore[271] && w_s1_gatewayIn_packed_45_bore[271])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_45_bore[271] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_45_bore[272] && w_s1_gatewayIn_packed_45_bore[272])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_45_bore[272] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_45_bore[273] && w_s1_gatewayIn_packed_45_bore[273])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_45_bore[273] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_45_bore[274] && w_s1_gatewayIn_packed_45_bore[274])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_45_bore[274] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_45_bore[275] && w_s1_gatewayIn_packed_45_bore[275])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_45_bore[275] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_45_bore[276] && w_s1_gatewayIn_packed_45_bore[276])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_45_bore[276] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_45_bore[277] && w_s1_gatewayIn_packed_45_bore[277])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_45_bore[277] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_45_bore[278] && w_s1_gatewayIn_packed_45_bore[278])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_45_bore[278] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_45_bore[279] && w_s1_gatewayIn_packed_45_bore[279])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_45_bore[279] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_45_bore[280] && w_s1_gatewayIn_packed_45_bore[280])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_45_bore[280] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_45_bore[281] && w_s1_gatewayIn_packed_45_bore[281])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_45_bore[281] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_45_bore[282] && w_s1_gatewayIn_packed_45_bore[282])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_45_bore[282] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_45_bore[283] && w_s1_gatewayIn_packed_45_bore[283])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_45_bore[283] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_45_bore[284] && w_s1_gatewayIn_packed_45_bore[284])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_45_bore[284] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_45_bore[285] && w_s1_gatewayIn_packed_45_bore[285])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_45_bore[285] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_45_bore[286] && w_s1_gatewayIn_packed_45_bore[286])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_45_bore[286] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_45_bore[287] && w_s1_gatewayIn_packed_45_bore[287])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_45_bore[287] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_45_bore[288] && w_s1_gatewayIn_packed_45_bore[288])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_45_bore[288] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_45_bore[289] && w_s1_gatewayIn_packed_45_bore[289])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_45_bore[289] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_45_bore[290] && w_s1_gatewayIn_packed_45_bore[290])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_45_bore[290] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_45_bore[291] && w_s1_gatewayIn_packed_45_bore[291])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_45_bore[291] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_45_bore[292] && w_s1_gatewayIn_packed_45_bore[292])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_45_bore[292] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_45_bore[293] && w_s1_gatewayIn_packed_45_bore[293])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_45_bore[293] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_45_bore[294] && w_s1_gatewayIn_packed_45_bore[294])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_45_bore[294] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_45_bore[295] && w_s1_gatewayIn_packed_45_bore[295])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_45_bore[295] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_45_bore[296] && w_s1_gatewayIn_packed_45_bore[296])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_45_bore[296] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_45_bore[297] && w_s1_gatewayIn_packed_45_bore[297])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_45_bore[297] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_45_bore[298] && w_s1_gatewayIn_packed_45_bore[298])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_45_bore[298] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_45_bore[299] && w_s1_gatewayIn_packed_45_bore[299])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_45_bore[299] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_45_bore[300] && w_s1_gatewayIn_packed_45_bore[300])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_45_bore[300] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_45_bore[301] && w_s1_gatewayIn_packed_45_bore[301])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_45_bore[301] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_45_bore[302] && w_s1_gatewayIn_packed_45_bore[302])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_45_bore[302] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_45_bore[303] && w_s1_gatewayIn_packed_45_bore[303])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_45_bore[303] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_45_bore[304] && w_s1_gatewayIn_packed_45_bore[304])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_45_bore[304] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_45_bore[305] && w_s1_gatewayIn_packed_45_bore[305])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_45_bore[305] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_45_bore[306] && w_s1_gatewayIn_packed_45_bore[306])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_45_bore[306] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_45_bore[307] && w_s1_gatewayIn_packed_45_bore[307])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_45_bore[307] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_45_bore[308] && w_s1_gatewayIn_packed_45_bore[308])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_45_bore[308] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_45_bore[309] && w_s1_gatewayIn_packed_45_bore[309])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_45_bore[309] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_45_bore[310] && w_s1_gatewayIn_packed_45_bore[310])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_45_bore[310] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_45_bore[311] && w_s1_gatewayIn_packed_45_bore[311])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_45_bore[311] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_45_bore[312] && w_s1_gatewayIn_packed_45_bore[312])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_45_bore[312] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_45_bore[313] && w_s1_gatewayIn_packed_45_bore[313])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_45_bore[313] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_45_bore[314] && w_s1_gatewayIn_packed_45_bore[314])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_45_bore[314] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_45_bore[315] && w_s1_gatewayIn_packed_45_bore[315])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_45_bore[315] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_45_bore[316] && w_s1_gatewayIn_packed_45_bore[316])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_45_bore[316] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_45_bore[317] && w_s1_gatewayIn_packed_45_bore[317])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_45_bore[317] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_45_bore[318] && w_s1_gatewayIn_packed_45_bore[318])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_45_bore[318] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_45_bore[319] && w_s1_gatewayIn_packed_45_bore[319])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_45_bore[319] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_45_bore[320] && w_s1_gatewayIn_packed_45_bore[320])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_45_bore[320] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_45_bore[321] && w_s1_gatewayIn_packed_45_bore[321])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_45_bore[321] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_45_bore[322] && w_s1_gatewayIn_packed_45_bore[322])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_45_bore[322] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_45_bore[323] && w_s1_gatewayIn_packed_45_bore[323])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_45_bore[323] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_45_bore[324] && w_s1_gatewayIn_packed_45_bore[324])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_45_bore[324] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_45_bore[325] && w_s1_gatewayIn_packed_45_bore[325])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_45_bore[325] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_45_bore[326] && w_s1_gatewayIn_packed_45_bore[326])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_45_bore[326] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_45_bore[327] && w_s1_gatewayIn_packed_45_bore[327])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_45_bore[327] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_45_bore[328] && w_s1_gatewayIn_packed_45_bore[328])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_45_bore[328] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_45_bore[329] && w_s1_gatewayIn_packed_45_bore[329])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_45_bore[329] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_45_bore[330] && w_s1_gatewayIn_packed_45_bore[330])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_45_bore[330] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_45_bore[331] && w_s1_gatewayIn_packed_45_bore[331])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_45_bore[331] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_45_bore[332] && w_s1_gatewayIn_packed_45_bore[332])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_45_bore[332] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_45_bore[333] && w_s1_gatewayIn_packed_45_bore[333])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_45_bore[333] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_45_bore[334] && w_s1_gatewayIn_packed_45_bore[334])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_45_bore[334] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_45_bore[335] && w_s1_gatewayIn_packed_45_bore[335])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_45_bore[335] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_45_bore[336] && w_s1_gatewayIn_packed_45_bore[336])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_45_bore[336] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_45_bore[337] && w_s1_gatewayIn_packed_45_bore[337])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_45_bore[337] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_45_bore[338] && w_s1_gatewayIn_packed_45_bore[338])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_45_bore[338] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_45_bore[339] && w_s1_gatewayIn_packed_45_bore[339])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_45_bore[339] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_45_bore[340] && w_s1_gatewayIn_packed_45_bore[340])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_45_bore[340] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_45_bore[341] && w_s1_gatewayIn_packed_45_bore[341])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_45_bore[341] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_45_bore[342] && w_s1_gatewayIn_packed_45_bore[342])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_45_bore[342] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_45_bore[343] && w_s1_gatewayIn_packed_45_bore[343])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_45_bore[343] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_45_bore[344] && w_s1_gatewayIn_packed_45_bore[344])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_45_bore[344] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_45_bore[345] && w_s1_gatewayIn_packed_45_bore[345])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_45_bore[345] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_45_bore[346] && w_s1_gatewayIn_packed_45_bore[346])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_45_bore[346] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_45_bore[347] && w_s1_gatewayIn_packed_45_bore[347])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_45_bore[347] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_45_bore[348] && w_s1_gatewayIn_packed_45_bore[348])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_45_bore[348] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_45_bore[349] && w_s1_gatewayIn_packed_45_bore[349])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_45_bore[349] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_45_bore[350] && w_s1_gatewayIn_packed_45_bore[350])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_45_bore[350] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_45_bore[351] && w_s1_gatewayIn_packed_45_bore[351])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_45_bore[351] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_45_bore[352] && w_s1_gatewayIn_packed_45_bore[352])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_45_bore[352] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_45_bore[353] && w_s1_gatewayIn_packed_45_bore[353])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_45_bore[353] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_45_bore[354] && w_s1_gatewayIn_packed_45_bore[354])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_45_bore[354] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_45_bore[355] && w_s1_gatewayIn_packed_45_bore[355])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_45_bore[355] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_45_bore[356] && w_s1_gatewayIn_packed_45_bore[356])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_45_bore[356] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_45_bore[357] && w_s1_gatewayIn_packed_45_bore[357])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_45_bore[357] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_45_bore[358] && w_s1_gatewayIn_packed_45_bore[358])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_45_bore[358] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_45_bore[359] && w_s1_gatewayIn_packed_45_bore[359])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_45_bore[359] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_45_bore[360] && w_s1_gatewayIn_packed_45_bore[360])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_45_bore[360] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_45_bore[361] && w_s1_gatewayIn_packed_45_bore[361])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_45_bore[361] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_45_bore[362] && w_s1_gatewayIn_packed_45_bore[362])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_45_bore[362] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_45_bore[363] && w_s1_gatewayIn_packed_45_bore[363])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_45_bore[363] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_45_bore[364] && w_s1_gatewayIn_packed_45_bore[364])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_45_bore[364] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_45_bore[365] && w_s1_gatewayIn_packed_45_bore[365])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_45_bore[365] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_45_bore[366] && w_s1_gatewayIn_packed_45_bore[366])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_45_bore[366] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_45_bore[367] && w_s1_gatewayIn_packed_45_bore[367])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_45_bore[367] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_45_bore[368] && w_s1_gatewayIn_packed_45_bore[368])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_45_bore[368] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_45_bore[369] && w_s1_gatewayIn_packed_45_bore[369])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_45_bore[369] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_45_bore[370] && w_s1_gatewayIn_packed_45_bore[370])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_45_bore[370] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_45_bore[371] && w_s1_gatewayIn_packed_45_bore[371])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_45_bore[371] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_45_bore[372] && w_s1_gatewayIn_packed_45_bore[372])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_45_bore[372] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_45_bore[373] && w_s1_gatewayIn_packed_45_bore[373])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_45_bore[373] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_45_bore[374] && w_s1_gatewayIn_packed_45_bore[374])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_45_bore[374] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_45_bore[375] && w_s1_gatewayIn_packed_45_bore[375])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_45_bore[375] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_45_bore[376] && w_s1_gatewayIn_packed_45_bore[376])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_45_bore[376] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_45_bore[377] && w_s1_gatewayIn_packed_45_bore[377])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_45_bore[377] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_45_bore[378] && w_s1_gatewayIn_packed_45_bore[378])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_45_bore[378] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_45_bore[379] && w_s1_gatewayIn_packed_45_bore[379])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_45_bore[379] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_45_bore[380] && w_s1_gatewayIn_packed_45_bore[380])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_45_bore[380] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_45_bore[381] && w_s1_gatewayIn_packed_45_bore[381])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_45_bore[381] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_45_bore[382] && w_s1_gatewayIn_packed_45_bore[382])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_45_bore[382] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_45_bore[383] && w_s1_gatewayIn_packed_45_bore[383])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_45_bore[383] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_45_bore[384] && w_s1_gatewayIn_packed_45_bore[384])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_45_bore[384] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_45_bore[385] && w_s1_gatewayIn_packed_45_bore[385])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_45_bore[385] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_45_bore[386] && w_s1_gatewayIn_packed_45_bore[386])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_45_bore[386] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_45_bore[387] && w_s1_gatewayIn_packed_45_bore[387])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_45_bore[387] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_45_bore[388] && w_s1_gatewayIn_packed_45_bore[388])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_45_bore[388] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_45_bore[389] && w_s1_gatewayIn_packed_45_bore[389])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_45_bore[389] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_45_bore[390] && w_s1_gatewayIn_packed_45_bore[390])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_45_bore[390] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_45_bore[391] && w_s1_gatewayIn_packed_45_bore[391])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_45_bore[391] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_45_bore[392] && w_s1_gatewayIn_packed_45_bore[392])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_45_bore[392] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_45_bore[393] && w_s1_gatewayIn_packed_45_bore[393])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_45_bore[393] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_45_bore[394] && w_s1_gatewayIn_packed_45_bore[394])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_45_bore[394] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_45_bore[395] && w_s1_gatewayIn_packed_45_bore[395])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_45_bore[395] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_45_bore[396] && w_s1_gatewayIn_packed_45_bore[396])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_45_bore[396] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_45_bore[397] && w_s1_gatewayIn_packed_45_bore[397])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_45_bore[397] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_45_bore[398] && w_s1_gatewayIn_packed_45_bore[398])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_45_bore[398] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_45_bore[399] && w_s1_gatewayIn_packed_45_bore[399])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_45_bore[399] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_45_bore[400] && w_s1_gatewayIn_packed_45_bore[400])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_45_bore[400] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_45_bore[401] && w_s1_gatewayIn_packed_45_bore[401])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_45_bore[401] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_45_bore[402] && w_s1_gatewayIn_packed_45_bore[402])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_45_bore[402] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_45_bore[403] && w_s1_gatewayIn_packed_45_bore[403])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_45_bore[403] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_45_bore[404] && w_s1_gatewayIn_packed_45_bore[404])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_45_bore[404] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_45_bore[405] && w_s1_gatewayIn_packed_45_bore[405])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_45_bore[405] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_45_bore[406] && w_s1_gatewayIn_packed_45_bore[406])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_45_bore[406] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_45_bore[407] && w_s1_gatewayIn_packed_45_bore[407])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_45_bore[407] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_45_bore[408] && w_s1_gatewayIn_packed_45_bore[408])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_45_bore[408] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_45_bore[409] && w_s1_gatewayIn_packed_45_bore[409])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_45_bore[409] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_45_bore[410] && w_s1_gatewayIn_packed_45_bore[410])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_45_bore[410] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_45_bore[411] && w_s1_gatewayIn_packed_45_bore[411])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_45_bore[411] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_45_bore[412] && w_s1_gatewayIn_packed_45_bore[412])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_45_bore[412] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_45_bore[413] && w_s1_gatewayIn_packed_45_bore[413])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_45_bore[413] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_45_bore[414] && w_s1_gatewayIn_packed_45_bore[414])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_45_bore[414] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_45_bore[415] && w_s1_gatewayIn_packed_45_bore[415])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_45_bore[415] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_45_bore[416] && w_s1_gatewayIn_packed_45_bore[416])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_45_bore[416] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_45_bore[417] && w_s1_gatewayIn_packed_45_bore[417])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_45_bore[417] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_45_bore[418] && w_s1_gatewayIn_packed_45_bore[418])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_45_bore[418] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_45_bore[419] && w_s1_gatewayIn_packed_45_bore[419])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_45_bore[419] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_45_bore[420] && w_s1_gatewayIn_packed_45_bore[420])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_45_bore[420] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_45_bore[421] && w_s1_gatewayIn_packed_45_bore[421])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_45_bore[421] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_45_bore[422] && w_s1_gatewayIn_packed_45_bore[422])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_45_bore[422] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_45_bore[423] && w_s1_gatewayIn_packed_45_bore[423])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_45_bore[423] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_45_bore[424] && w_s1_gatewayIn_packed_45_bore[424])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_45_bore[424] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_45_bore[425] && w_s1_gatewayIn_packed_45_bore[425])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_45_bore[425] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_45_bore[426] && w_s1_gatewayIn_packed_45_bore[426])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_45_bore[426] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_45_bore[427] && w_s1_gatewayIn_packed_45_bore[427])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_45_bore[427] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_45_bore[428] && w_s1_gatewayIn_packed_45_bore[428])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_45_bore[428] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_45_bore[429] && w_s1_gatewayIn_packed_45_bore[429])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_45_bore[429] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_45_bore[430] && w_s1_gatewayIn_packed_45_bore[430])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_45_bore[430] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_45_bore[431] && w_s1_gatewayIn_packed_45_bore[431])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_45_bore[431] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_45_bore[432] && w_s1_gatewayIn_packed_45_bore[432])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_45_bore[432] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_45_bore[433] && w_s1_gatewayIn_packed_45_bore[433])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_45_bore[433] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_45_bore[434] && w_s1_gatewayIn_packed_45_bore[434])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_45_bore[434] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_45_bore[435] && w_s1_gatewayIn_packed_45_bore[435])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_45_bore[435] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_45_bore[436] && w_s1_gatewayIn_packed_45_bore[436])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_45_bore[436] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_45_bore[437] && w_s1_gatewayIn_packed_45_bore[437])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_45_bore[437] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_45_bore[438] && w_s1_gatewayIn_packed_45_bore[438])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_45_bore[438] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_45_bore[439] && w_s1_gatewayIn_packed_45_bore[439])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_45_bore[439] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_45_bore[440] && w_s1_gatewayIn_packed_45_bore[440])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_45_bore[440] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_45_bore[441] && w_s1_gatewayIn_packed_45_bore[441])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_45_bore[441] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_45_bore[442] && w_s1_gatewayIn_packed_45_bore[442])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_45_bore[442] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_45_bore[443] && w_s1_gatewayIn_packed_45_bore[443])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_45_bore[443] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_45_bore[444] && w_s1_gatewayIn_packed_45_bore[444])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_45_bore[444] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_45_bore[445] && w_s1_gatewayIn_packed_45_bore[445])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_45_bore[445] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_45_bore[446] && w_s1_gatewayIn_packed_45_bore[446])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_45_bore[446] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_45_bore[447] && w_s1_gatewayIn_packed_45_bore[447])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_45_bore[447] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_45_bore[448] && w_s1_gatewayIn_packed_45_bore[448])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_45_bore[448] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_45_bore[449] && w_s1_gatewayIn_packed_45_bore[449])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_45_bore[449] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_45_bore[450] && w_s1_gatewayIn_packed_45_bore[450])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_45_bore[450] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_45_bore[451] && w_s1_gatewayIn_packed_45_bore[451])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_45_bore[451] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_45_bore[452] && w_s1_gatewayIn_packed_45_bore[452])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_45_bore[452] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_45_bore[453] && w_s1_gatewayIn_packed_45_bore[453])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_45_bore[453] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_45_bore[454] && w_s1_gatewayIn_packed_45_bore[454])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_45_bore[454] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_45_bore[455] && w_s1_gatewayIn_packed_45_bore[455])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_45_bore[455] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_45_bore[456] && w_s1_gatewayIn_packed_45_bore[456])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_45_bore[456] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_45_bore[457] && w_s1_gatewayIn_packed_45_bore[457])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_45_bore[457] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_45_bore[458] && w_s1_gatewayIn_packed_45_bore[458])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_45_bore[458] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_45_bore[459] && w_s1_gatewayIn_packed_45_bore[459])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_45_bore[459] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_45_bore[460] && w_s1_gatewayIn_packed_45_bore[460])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_45_bore[460] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_45_bore[461] && w_s1_gatewayIn_packed_45_bore[461])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_45_bore[461] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_45_bore[462] && w_s1_gatewayIn_packed_45_bore[462])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_45_bore[462] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_45_bore[463] && w_s1_gatewayIn_packed_45_bore[463])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_45_bore[463] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_45_bore[464] && w_s1_gatewayIn_packed_45_bore[464])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_45_bore[464] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_45_bore[465] && w_s1_gatewayIn_packed_45_bore[465])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_45_bore[465] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_45_bore[466] && w_s1_gatewayIn_packed_45_bore[466])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_45_bore[466] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_45_bore[467] && w_s1_gatewayIn_packed_45_bore[467])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_45_bore[467] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_45_bore[468] && w_s1_gatewayIn_packed_45_bore[468])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_45_bore[468] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_45_bore[469] && w_s1_gatewayIn_packed_45_bore[469])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_45_bore[469] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_45_bore[470] && w_s1_gatewayIn_packed_45_bore[470])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_45_bore[470] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_45_bore[471] && w_s1_gatewayIn_packed_45_bore[471])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_45_bore[471] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_45_bore[472] && w_s1_gatewayIn_packed_45_bore[472])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_45_bore[472] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_45_bore[473] && w_s1_gatewayIn_packed_45_bore[473])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_45_bore[473] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_45_bore[474] && w_s1_gatewayIn_packed_45_bore[474])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_45_bore[474] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_45_bore[475] && w_s1_gatewayIn_packed_45_bore[475])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_45_bore[475] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_45_bore[476] && w_s1_gatewayIn_packed_45_bore[476])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_45_bore[476] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_45_bore[477] && w_s1_gatewayIn_packed_45_bore[477])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_45_bore[477] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_45_bore[478] && w_s1_gatewayIn_packed_45_bore[478])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_45_bore[478] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_45_bore[479] && w_s1_gatewayIn_packed_45_bore[479])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_45_bore[479] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_45_bore[480] && w_s1_gatewayIn_packed_45_bore[480])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_45_bore[480] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_45_bore[481] && w_s1_gatewayIn_packed_45_bore[481])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_45_bore[481] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_45_bore[482] && w_s1_gatewayIn_packed_45_bore[482])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_45_bore[482] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_45_bore[483] && w_s1_gatewayIn_packed_45_bore[483])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_45_bore[483] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_45_bore[484] && w_s1_gatewayIn_packed_45_bore[484])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_45_bore[484] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_45_bore[485] && w_s1_gatewayIn_packed_45_bore[485])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_45_bore[485] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_45_bore[486] && w_s1_gatewayIn_packed_45_bore[486])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_45_bore[486] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_45_bore[487] && w_s1_gatewayIn_packed_45_bore[487])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_45_bore[487] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_45_bore[488] && w_s1_gatewayIn_packed_45_bore[488])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_45_bore[488] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_45_bore[489] && w_s1_gatewayIn_packed_45_bore[489])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_45_bore[489] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_45_bore[490] && w_s1_gatewayIn_packed_45_bore[490])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_45_bore[490] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_45_bore[491] && w_s1_gatewayIn_packed_45_bore[491])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_45_bore[491] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_45_bore[492] && w_s1_gatewayIn_packed_45_bore[492])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_45_bore[492] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_45_bore[493] && w_s1_gatewayIn_packed_45_bore[493])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_45_bore[493] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_45_bore[494] && w_s1_gatewayIn_packed_45_bore[494])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_45_bore[494] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_45_bore[495] && w_s1_gatewayIn_packed_45_bore[495])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_45_bore[495] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_45_bore[496] && w_s1_gatewayIn_packed_45_bore[496])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_45_bore[496] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_45_bore[497] && w_s1_gatewayIn_packed_45_bore[497])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_45_bore[497] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_45_bore[498] && w_s1_gatewayIn_packed_45_bore[498])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_45_bore[498] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_45_bore[499] && w_s1_gatewayIn_packed_45_bore[499])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_45_bore[499] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_45_bore[500] && w_s1_gatewayIn_packed_45_bore[500])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_45_bore[500] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_45_bore[501] && w_s1_gatewayIn_packed_45_bore[501])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_45_bore[501] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_45_bore[502] && w_s1_gatewayIn_packed_45_bore[502])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_45_bore[502] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_45_bore[503] && w_s1_gatewayIn_packed_45_bore[503])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_45_bore[503] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_45_bore[504] && w_s1_gatewayIn_packed_45_bore[504])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_45_bore[504] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_45_bore[505] && w_s1_gatewayIn_packed_45_bore[505])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_45_bore[505] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_45_bore[506] && w_s1_gatewayIn_packed_45_bore[506])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_45_bore[506] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_45_bore[507] && w_s1_gatewayIn_packed_45_bore[507])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_45_bore[507] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_45_bore[508] && w_s1_gatewayIn_packed_45_bore[508])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_45_bore[508] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_45_bore[509] && w_s1_gatewayIn_packed_45_bore[509])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_45_bore[509] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_45_bore[510] && w_s1_gatewayIn_packed_45_bore[510])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_45_bore[510] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_45_bore[511] && w_s1_gatewayIn_packed_45_bore[511])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_45_bore[511] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_45_bore[512] && w_s1_gatewayIn_packed_45_bore[512])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_45_bore[512] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_45_bore[513] && w_s1_gatewayIn_packed_45_bore[513])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_45_bore[513] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_45_bore[514] && w_s1_gatewayIn_packed_45_bore[514])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_45_bore[514] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_45_bore[515] && w_s1_gatewayIn_packed_45_bore[515])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_45_bore[515] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_45_bore[516] && w_s1_gatewayIn_packed_45_bore[516])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_45_bore[516] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_45_bore[517] && w_s1_gatewayIn_packed_45_bore[517])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_45_bore[517] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_45_bore[518] && w_s1_gatewayIn_packed_45_bore[518])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_45_bore[518] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_45_bore[519] && w_s1_gatewayIn_packed_45_bore[519])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_45_bore[519] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_45_bore[520] && w_s1_gatewayIn_packed_45_bore[520])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_45_bore[520] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_45_bore[521] && w_s1_gatewayIn_packed_45_bore[521])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_45_bore[521] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_45_bore[522] && w_s1_gatewayIn_packed_45_bore[522])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_45_bore[522] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_45_bore[523] && w_s1_gatewayIn_packed_45_bore[523])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_45_bore[523] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_45_bore[524] && w_s1_gatewayIn_packed_45_bore[524])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_45_bore[524] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_45_bore[525] && w_s1_gatewayIn_packed_45_bore[525])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_45_bore[525] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_45_bore[526] && w_s1_gatewayIn_packed_45_bore[526])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_45_bore[526] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_45_bore[527] && w_s1_gatewayIn_packed_45_bore[527])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_45_bore[527] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_45_bore[528] && w_s1_gatewayIn_packed_45_bore[528])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_45_bore[528] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_45_bore[529] && w_s1_gatewayIn_packed_45_bore[529])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_45_bore[529] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_45_bore[530] && w_s1_gatewayIn_packed_45_bore[530])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_45_bore[530] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_45_bore[531] && w_s1_gatewayIn_packed_45_bore[531])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_45_bore[531] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_45_bore[532] && w_s1_gatewayIn_packed_45_bore[532])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_45_bore[532] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_45_bore[533] && w_s1_gatewayIn_packed_45_bore[533])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_45_bore[533] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_45_bore[534] && w_s1_gatewayIn_packed_45_bore[534])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_45_bore[534] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_45_bore[535] && w_s1_gatewayIn_packed_45_bore[535])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_45_bore[535] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_45_bore[536] && w_s1_gatewayIn_packed_45_bore[536])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_45_bore[536] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_45_bore[537] && w_s1_gatewayIn_packed_45_bore[537])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_45_bore[537] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_45_bore[538] && w_s1_gatewayIn_packed_45_bore[538])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_45_bore[538] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_45_bore[539] && w_s1_gatewayIn_packed_45_bore[539])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_45_bore[539] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_45_bore[540] && w_s1_gatewayIn_packed_45_bore[540])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_45_bore[540] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_45_bore[541] && w_s1_gatewayIn_packed_45_bore[541])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_45_bore[541] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_45_bore[542] && w_s1_gatewayIn_packed_45_bore[542])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_45_bore[542] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_45_bore[543] && w_s1_gatewayIn_packed_45_bore[543])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_45_bore[543] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_45_bore[544] && w_s1_gatewayIn_packed_45_bore[544])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_45_bore[544] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_45_bore[545] && w_s1_gatewayIn_packed_45_bore[545])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_45_bore[545] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_45_bore[546] && w_s1_gatewayIn_packed_45_bore[546])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_45_bore[546] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_45_bore[547] && w_s1_gatewayIn_packed_45_bore[547])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_45_bore[547] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_45_bore[548] && w_s1_gatewayIn_packed_45_bore[548])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_45_bore[548] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_45_bore[549] && w_s1_gatewayIn_packed_45_bore[549])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_45_bore[549] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_45_bore[550] && w_s1_gatewayIn_packed_45_bore[550])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_45_bore[550] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_45_bore[551] && w_s1_gatewayIn_packed_45_bore[551])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_45_bore[551] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_45_bore[552] && w_s1_gatewayIn_packed_45_bore[552])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_45_bore[552] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_45_bore[553] && w_s1_gatewayIn_packed_45_bore[553])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_45_bore[553] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_45_bore[554] && w_s1_gatewayIn_packed_45_bore[554])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_45_bore[554] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_45_bore[555] && w_s1_gatewayIn_packed_45_bore[555])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_45_bore[555] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_45_bore[556] && w_s1_gatewayIn_packed_45_bore[556])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_45_bore[556] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_45_bore[557] && w_s1_gatewayIn_packed_45_bore[557])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_45_bore[557] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_45_bore[558] && w_s1_gatewayIn_packed_45_bore[558])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_45_bore[558] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_45_bore[559] && w_s1_gatewayIn_packed_45_bore[559])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_45_bore[559] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_45_bore[560] && w_s1_gatewayIn_packed_45_bore[560])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_45_bore[560] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_45_bore[561] && w_s1_gatewayIn_packed_45_bore[561])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_45_bore[561] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_45_bore[562] && w_s1_gatewayIn_packed_45_bore[562])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_45_bore[562] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_45_bore[563] && w_s1_gatewayIn_packed_45_bore[563])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_45_bore[563] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_45_bore[564] && w_s1_gatewayIn_packed_45_bore[564])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_45_bore[564] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_45_bore[565] && w_s1_gatewayIn_packed_45_bore[565])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_45_bore[565] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_45_bore[566] && w_s1_gatewayIn_packed_45_bore[566])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_45_bore[566] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_45_bore[567] && w_s1_gatewayIn_packed_45_bore[567])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_45_bore[567] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_45_bore[568] && w_s1_gatewayIn_packed_45_bore[568])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_45_bore[568] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_45_bore[569] && w_s1_gatewayIn_packed_45_bore[569])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_45_bore[569] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_45_bore[570] && w_s1_gatewayIn_packed_45_bore[570])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_45_bore[570] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_45_bore[571] && w_s1_gatewayIn_packed_45_bore[571])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_45_bore[571] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_45_bore[572] && w_s1_gatewayIn_packed_45_bore[572])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_45_bore[572] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_45_bore[573] && w_s1_gatewayIn_packed_45_bore[573])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_45_bore[573] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_45_bore[574] && w_s1_gatewayIn_packed_45_bore[574])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_45_bore[574] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_45_bore[575] && w_s1_gatewayIn_packed_45_bore[575])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_45_bore[575] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_45_bore[576] && w_s1_gatewayIn_packed_45_bore[576])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_45_bore[576] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_45_bore[577] && w_s1_gatewayIn_packed_45_bore[577])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_45_bore[577] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_45_bore[578] && w_s1_gatewayIn_packed_45_bore[578])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_45_bore[578] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_45_bore[579] && w_s1_gatewayIn_packed_45_bore[579])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_45_bore[579] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_45_bore[580] && w_s1_gatewayIn_packed_45_bore[580])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_45_bore[580] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_45_bore[581] && w_s1_gatewayIn_packed_45_bore[581])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_45_bore[581] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_45_bore[582] && w_s1_gatewayIn_packed_45_bore[582])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_45_bore[582] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_45_bore[583] && w_s1_gatewayIn_packed_45_bore[583])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_45_bore[583] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_45_bore[584] && w_s1_gatewayIn_packed_45_bore[584])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_45_bore[584] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_45_bore[585] && w_s1_gatewayIn_packed_45_bore[585])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_45_bore[585] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_45_bore[586] && w_s1_gatewayIn_packed_45_bore[586])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_45_bore[586] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_45_bore[587] && w_s1_gatewayIn_packed_45_bore[587])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_45_bore[587] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_45_bore[588] && w_s1_gatewayIn_packed_45_bore[588])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_45_bore[588] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_45_bore[589] && w_s1_gatewayIn_packed_45_bore[589])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_45_bore[589] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_45_bore[590] && w_s1_gatewayIn_packed_45_bore[590])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_45_bore[590] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_45_bore[591] && w_s1_gatewayIn_packed_45_bore[591])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_45_bore[591] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_45_bore[592] && w_s1_gatewayIn_packed_45_bore[592])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_45_bore[592] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_45_bore[593] && w_s1_gatewayIn_packed_45_bore[593])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_45_bore[593] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_45_bore[594] && w_s1_gatewayIn_packed_45_bore[594])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_45_bore[594] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_45_bore[595] && w_s1_gatewayIn_packed_45_bore[595])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_45_bore[595] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_45_bore[596] && w_s1_gatewayIn_packed_45_bore[596])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_45_bore[596] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_45_bore[597] && w_s1_gatewayIn_packed_45_bore[597])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_45_bore[597] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_45_bore[598] && w_s1_gatewayIn_packed_45_bore[598])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_45_bore[598] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_45_bore[599] && w_s1_gatewayIn_packed_45_bore[599])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_45_bore[599] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_45_bore[600] && w_s1_gatewayIn_packed_45_bore[600])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_45_bore[600] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_45_bore[601] && w_s1_gatewayIn_packed_45_bore[601])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_45_bore[601] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_45_bore[602] && w_s1_gatewayIn_packed_45_bore[602])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_45_bore[602] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_45_bore[603] && w_s1_gatewayIn_packed_45_bore[603])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_45_bore[603] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_45_bore[604] && w_s1_gatewayIn_packed_45_bore[604])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_45_bore[604] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_45_bore[605] && w_s1_gatewayIn_packed_45_bore[605])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_45_bore[605] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_45_bore[606] && w_s1_gatewayIn_packed_45_bore[606])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_45_bore[606] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_45_bore[607] && w_s1_gatewayIn_packed_45_bore[607])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_45_bore[607] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_45_bore[608] && w_s1_gatewayIn_packed_45_bore[608])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_45_bore[608] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_45_bore[609] && w_s1_gatewayIn_packed_45_bore[609])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_45_bore[609] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_45_bore[610] && w_s1_gatewayIn_packed_45_bore[610])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_45_bore[610] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_45_bore[611] && w_s1_gatewayIn_packed_45_bore[611])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_45_bore[611] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_45_bore[612] && w_s1_gatewayIn_packed_45_bore[612])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_45_bore[612] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_45_bore[613] && w_s1_gatewayIn_packed_45_bore[613])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_45_bore[613] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_45_bore[614] && w_s1_gatewayIn_packed_45_bore[614])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_45_bore[614] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_45_bore[615] && w_s1_gatewayIn_packed_45_bore[615])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_45_bore[615] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_45_bore[616] && w_s1_gatewayIn_packed_45_bore[616])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_45_bore[616] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_45_bore[617] && w_s1_gatewayIn_packed_45_bore[617])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_45_bore[617] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_45_bore[618] && w_s1_gatewayIn_packed_45_bore[618])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_45_bore[618] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_45_bore[619] && w_s1_gatewayIn_packed_45_bore[619])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_45_bore[619] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_45_bore[620] && w_s1_gatewayIn_packed_45_bore[620])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_45_bore[620] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_45_bore[621] && w_s1_gatewayIn_packed_45_bore[621])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_45_bore[621] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_45_bore[622] && w_s1_gatewayIn_packed_45_bore[622])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_45_bore[622] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_45_bore[623] && w_s1_gatewayIn_packed_45_bore[623])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_45_bore[623] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_45_bore[624] && w_s1_gatewayIn_packed_45_bore[624])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_45_bore[624] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_45_bore[625] && w_s1_gatewayIn_packed_45_bore[625])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_45_bore[625] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_45_bore[626] && w_s1_gatewayIn_packed_45_bore[626])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_45_bore[626] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_45_bore[627] && w_s1_gatewayIn_packed_45_bore[627])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_45_bore[627] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_45_bore[628] && w_s1_gatewayIn_packed_45_bore[628])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_45_bore[628] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_45_bore[629] && w_s1_gatewayIn_packed_45_bore[629])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_45_bore[629] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_45_bore[630] && w_s1_gatewayIn_packed_45_bore[630])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_45_bore[630] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_45_bore[631] && w_s1_gatewayIn_packed_45_bore[631])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_45_bore[631] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_45_bore[632] && w_s1_gatewayIn_packed_45_bore[632])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_45_bore[632] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_45_bore[633] && w_s1_gatewayIn_packed_45_bore[633])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_45_bore[633] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_45_bore[634] && w_s1_gatewayIn_packed_45_bore[634])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_45_bore[634] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_45_bore[635] && w_s1_gatewayIn_packed_45_bore[635])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_45_bore[635] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_45_bore[636] && w_s1_gatewayIn_packed_45_bore[636])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_45_bore[636] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_45_bore[637] && w_s1_gatewayIn_packed_45_bore[637])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_45_bore[637] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_45_bore[638] && w_s1_gatewayIn_packed_45_bore[638])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_45_bore[638] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_45_bore[639] && w_s1_gatewayIn_packed_45_bore[639])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_45_bore[639] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_45_bore[640] && w_s1_gatewayIn_packed_45_bore[640])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_45_bore[640] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_45_bore[641] && w_s1_gatewayIn_packed_45_bore[641])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_45_bore[641] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_45_bore[642] && w_s1_gatewayIn_packed_45_bore[642])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_45_bore[642] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_45_bore[643] && w_s1_gatewayIn_packed_45_bore[643])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_45_bore[643] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_45_bore[644] && w_s1_gatewayIn_packed_45_bore[644])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_45_bore[644] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_45_bore[645] && w_s1_gatewayIn_packed_45_bore[645])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_45_bore[645] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_45_bore[646] && w_s1_gatewayIn_packed_45_bore[646])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_45_bore[646] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_45_bore[647] && w_s1_gatewayIn_packed_45_bore[647])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_45_bore[647] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_45_bore[648] && w_s1_gatewayIn_packed_45_bore[648])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_45_bore[648] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_45_bore[649] && w_s1_gatewayIn_packed_45_bore[649])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_45_bore[649] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_45_bore[650] && w_s1_gatewayIn_packed_45_bore[650])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_45_bore[650] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_45_bore[651] && w_s1_gatewayIn_packed_45_bore[651])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_45_bore[651] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_45_bore[652] && w_s1_gatewayIn_packed_45_bore[652])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_45_bore[652] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_45_bore[653] && w_s1_gatewayIn_packed_45_bore[653])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_45_bore[653] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_45_bore[654] && w_s1_gatewayIn_packed_45_bore[654])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_45_bore[654] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_45_bore[655] && w_s1_gatewayIn_packed_45_bore[655])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_45_bore[655] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_45_bore[656] && w_s1_gatewayIn_packed_45_bore[656])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_45_bore[656] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_45_bore[657] && w_s1_gatewayIn_packed_45_bore[657])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_45_bore[657] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_45_bore[658] && w_s1_gatewayIn_packed_45_bore[658])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_45_bore[658] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_45_bore[659] && w_s1_gatewayIn_packed_45_bore[659])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_45_bore[659] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_45_bore[660] && w_s1_gatewayIn_packed_45_bore[660])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_45_bore[660] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_45_bore[661] && w_s1_gatewayIn_packed_45_bore[661])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_45_bore[661] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_45_bore[662] && w_s1_gatewayIn_packed_45_bore[662])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_45_bore[662] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_45_bore[663] && w_s1_gatewayIn_packed_45_bore[663])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_45_bore[663] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_45_bore[664] && w_s1_gatewayIn_packed_45_bore[664])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_45_bore[664] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_45_bore[665] && w_s1_gatewayIn_packed_45_bore[665])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_45_bore[665] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_45_bore[666] && w_s1_gatewayIn_packed_45_bore[666])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_45_bore[666] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_45_bore[667] && w_s1_gatewayIn_packed_45_bore[667])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_45_bore[667] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_45_bore[668] && w_s1_gatewayIn_packed_45_bore[668])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_45_bore[668] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_45_bore[669] && w_s1_gatewayIn_packed_45_bore[669])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_45_bore[669] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_45_bore[670] && w_s1_gatewayIn_packed_45_bore[670])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_45_bore[670] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_45_bore[671] && w_s1_gatewayIn_packed_45_bore[671])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_45_bore[671] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_45_bore[672] && w_s1_gatewayIn_packed_45_bore[672])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_45_bore[672] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_45_bore[673] && w_s1_gatewayIn_packed_45_bore[673])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_45_bore[673] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_45_bore[674] && w_s1_gatewayIn_packed_45_bore[674])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_45_bore[674] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_45_bore[675] && w_s1_gatewayIn_packed_45_bore[675])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_45_bore[675] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_45_bore[676] && w_s1_gatewayIn_packed_45_bore[676])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_45_bore[676] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_45_bore[677] && w_s1_gatewayIn_packed_45_bore[677])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_45_bore[677] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_45_bore[678] && w_s1_gatewayIn_packed_45_bore[678])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_45_bore[678] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_45_bore[679] && w_s1_gatewayIn_packed_45_bore[679])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_45_bore[679] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_45_bore[680] && w_s1_gatewayIn_packed_45_bore[680])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_45_bore[680] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_45_bore[681] && w_s1_gatewayIn_packed_45_bore[681])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_45_bore[681] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_45_bore[682] && w_s1_gatewayIn_packed_45_bore[682])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_45_bore[682] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_45_bore[683] && w_s1_gatewayIn_packed_45_bore[683])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_45_bore[683] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_45_bore[684] && w_s1_gatewayIn_packed_45_bore[684])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_45_bore[684] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_45_bore[685] && w_s1_gatewayIn_packed_45_bore[685])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_45_bore[685] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_45_bore[686] && w_s1_gatewayIn_packed_45_bore[686])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_45_bore[686] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_45_bore[687] && w_s1_gatewayIn_packed_45_bore[687])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_45_bore[687] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_45_bore[688] && w_s1_gatewayIn_packed_45_bore[688])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_45_bore[688] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_45_bore[689] && w_s1_gatewayIn_packed_45_bore[689])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_45_bore[689] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_45_bore[690] && w_s1_gatewayIn_packed_45_bore[690])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_45_bore[690] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_45_bore[691] && w_s1_gatewayIn_packed_45_bore[691])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_45_bore[691] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_45_bore[692] && w_s1_gatewayIn_packed_45_bore[692])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_45_bore[692] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_45_bore[693] && w_s1_gatewayIn_packed_45_bore[693])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_45_bore[693] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_45_bore[694] && w_s1_gatewayIn_packed_45_bore[694])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_45_bore[694] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_45_bore[695] && w_s1_gatewayIn_packed_45_bore[695])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_45_bore[695] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_45_bore[696] && w_s1_gatewayIn_packed_45_bore[696])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_45_bore[696] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_45_bore[697] && w_s1_gatewayIn_packed_45_bore[697])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_45_bore[697] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_45_bore[698] && w_s1_gatewayIn_packed_45_bore[698])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_45_bore[698] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_45_bore[699] && w_s1_gatewayIn_packed_45_bore[699])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_45_bore[699] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_45_bore[700] && w_s1_gatewayIn_packed_45_bore[700])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_45_bore[700] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_45_bore[701] && w_s1_gatewayIn_packed_45_bore[701])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_45_bore[701] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_45_bore[702] && w_s1_gatewayIn_packed_45_bore[702])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_45_bore[702] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_45_bore[703] && w_s1_gatewayIn_packed_45_bore[703])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_45_bore[703] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_45_bore[704] && w_s1_gatewayIn_packed_45_bore[704])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_45_bore[704] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_45_bore[705] && w_s1_gatewayIn_packed_45_bore[705])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_45_bore[705] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_45_bore[706] && w_s1_gatewayIn_packed_45_bore[706])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_45_bore[706] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_45_bore[707] && w_s1_gatewayIn_packed_45_bore[707])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_45_bore[707] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_45_bore[708] && w_s1_gatewayIn_packed_45_bore[708])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_45_bore[708] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_45_bore[709] && w_s1_gatewayIn_packed_45_bore[709])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_45_bore[709] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_45_bore[710] && w_s1_gatewayIn_packed_45_bore[710])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_45_bore[710] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_45_bore[711] && w_s1_gatewayIn_packed_45_bore[711])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_45_bore[711] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_45_bore[712] && w_s1_gatewayIn_packed_45_bore[712])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_45_bore[712] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_45_bore[713] && w_s1_gatewayIn_packed_45_bore[713])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_45_bore[713] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_45_bore[714] && w_s1_gatewayIn_packed_45_bore[714])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_45_bore[714] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_45_bore[715] && w_s1_gatewayIn_packed_45_bore[715])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_45_bore[715] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_45_bore[716] && w_s1_gatewayIn_packed_45_bore[716])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_45_bore[716] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_45_bore[717] && w_s1_gatewayIn_packed_45_bore[717])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_45_bore[717] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_45_bore[718] && w_s1_gatewayIn_packed_45_bore[718])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_45_bore[718] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_45_bore[719] && w_s1_gatewayIn_packed_45_bore[719])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_45_bore[719] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_45_bore[720] && w_s1_gatewayIn_packed_45_bore[720])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_45_bore[720] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_45_bore[721] && w_s1_gatewayIn_packed_45_bore[721])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_45_bore[721] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_45_bore[722] && w_s1_gatewayIn_packed_45_bore[722])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_45_bore[722] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_45_bore[723] && w_s1_gatewayIn_packed_45_bore[723])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_45_bore[723] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_45_bore[724] && w_s1_gatewayIn_packed_45_bore[724])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_45_bore[724] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_45_bore[725] && w_s1_gatewayIn_packed_45_bore[725])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_45_bore[725] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_45_bore[726] && w_s1_gatewayIn_packed_45_bore[726])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_45_bore[726] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_45_bore[727] && w_s1_gatewayIn_packed_45_bore[727])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_45_bore[727] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_45_bore[728] && w_s1_gatewayIn_packed_45_bore[728])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_45_bore[728] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_45_bore[729] && w_s1_gatewayIn_packed_45_bore[729])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_45_bore[729] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_45_bore[730] && w_s1_gatewayIn_packed_45_bore[730])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_45_bore[730] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_45_bore[731] && w_s1_gatewayIn_packed_45_bore[731])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_45_bore[731] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_45_bore[732] && w_s1_gatewayIn_packed_45_bore[732])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_45_bore[732] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_45_bore[733] && w_s1_gatewayIn_packed_45_bore[733])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_45_bore[733] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_45_bore[734] && w_s1_gatewayIn_packed_45_bore[734])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_45_bore[734] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_45_bore[735] && w_s1_gatewayIn_packed_45_bore[735])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_45_bore[735] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_45_bore[736] && w_s1_gatewayIn_packed_45_bore[736])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_45_bore[736] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_45_bore[737] && w_s1_gatewayIn_packed_45_bore[737])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_45_bore[737] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_45_bore[738] && w_s1_gatewayIn_packed_45_bore[738])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_45_bore[738] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_45_bore[739] && w_s1_gatewayIn_packed_45_bore[739])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_45_bore[739] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_45_bore[740] && w_s1_gatewayIn_packed_45_bore[740])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_45_bore[740] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_45_bore[741] && w_s1_gatewayIn_packed_45_bore[741])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_45_bore[741] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_45_bore[742] && w_s1_gatewayIn_packed_45_bore[742])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_45_bore[742] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_45_bore[743] && w_s1_gatewayIn_packed_45_bore[743])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_45_bore[743] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_45_bore[744] && w_s1_gatewayIn_packed_45_bore[744])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_45_bore[744] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_45_bore[745] && w_s1_gatewayIn_packed_45_bore[745])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_45_bore[745] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_45_bore[746] && w_s1_gatewayIn_packed_45_bore[746])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_45_bore[746] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_45_bore[747] && w_s1_gatewayIn_packed_45_bore[747])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_45_bore[747] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_45_bore[748] && w_s1_gatewayIn_packed_45_bore[748])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_45_bore[748] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_45_bore[749] && w_s1_gatewayIn_packed_45_bore[749])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_45_bore[749] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_45_bore[750] && w_s1_gatewayIn_packed_45_bore[750])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_45_bore[750] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_45_bore[751] && w_s1_gatewayIn_packed_45_bore[751])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_45_bore[751] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_45_bore[752] && w_s1_gatewayIn_packed_45_bore[752])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_45_bore[752] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_45_bore[753] && w_s1_gatewayIn_packed_45_bore[753])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_45_bore[753] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_45_bore[754] && w_s1_gatewayIn_packed_45_bore[754])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_45_bore[754] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_45_bore[755] && w_s1_gatewayIn_packed_45_bore[755])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_45_bore[755] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_45_bore[756] && w_s1_gatewayIn_packed_45_bore[756])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_45_bore[756] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_45_bore[757] && w_s1_gatewayIn_packed_45_bore[757])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_45_bore[757] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_45_bore[758] && w_s1_gatewayIn_packed_45_bore[758])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_45_bore[758] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_45_bore[759] && w_s1_gatewayIn_packed_45_bore[759])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_45_bore[759] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_45_bore[760] && w_s1_gatewayIn_packed_45_bore[760])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_45_bore[760] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_45_bore[761] && w_s1_gatewayIn_packed_45_bore[761])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_45_bore[761] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_45_bore[762] && w_s1_gatewayIn_packed_45_bore[762])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_45_bore[762] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_45_bore[763] && w_s1_gatewayIn_packed_45_bore[763])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_45_bore[763] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_45_bore[764] && w_s1_gatewayIn_packed_45_bore[764])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_45_bore[764] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_45_bore[765] && w_s1_gatewayIn_packed_45_bore[765])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_45_bore[765] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_45_bore[766] && w_s1_gatewayIn_packed_45_bore[766])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_45_bore[766] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_45_bore[767] && w_s1_gatewayIn_packed_45_bore[767])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_45_bore[767] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_45_bore[768] && w_s1_gatewayIn_packed_45_bore[768])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_45_bore[768] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_45_bore[769] && w_s1_gatewayIn_packed_45_bore[769])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_45_bore[769] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_45_bore[770] && w_s1_gatewayIn_packed_45_bore[770])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_45_bore[770] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_45_bore[771] && w_s1_gatewayIn_packed_45_bore[771])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_45_bore[771] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_45_bore[772] && w_s1_gatewayIn_packed_45_bore[772])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_45_bore[772] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_45_bore[773] && w_s1_gatewayIn_packed_45_bore[773])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_45_bore[773] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_45_bore[774] && w_s1_gatewayIn_packed_45_bore[774])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_45_bore[774] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_45_bore[775] && w_s1_gatewayIn_packed_45_bore[775])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_45_bore[775] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_45_bore[776] && w_s1_gatewayIn_packed_45_bore[776])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_45_bore[776] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_45_bore[777] && w_s1_gatewayIn_packed_45_bore[777])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_45_bore[777] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_45_bore[778] && w_s1_gatewayIn_packed_45_bore[778])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_45_bore[778] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_45_bore[779] && w_s1_gatewayIn_packed_45_bore[779])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_45_bore[779] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_45_bore[780] && w_s1_gatewayIn_packed_45_bore[780])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_45_bore[780] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_45_bore[781] && w_s1_gatewayIn_packed_45_bore[781])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_45_bore[781] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_45_bore[782] && w_s1_gatewayIn_packed_45_bore[782])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_45_bore[782] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_45_bore[783] && w_s1_gatewayIn_packed_45_bore[783])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_45_bore[783] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_45_bore[784] && w_s1_gatewayIn_packed_45_bore[784])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_45_bore[784] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_45_bore[785] && w_s1_gatewayIn_packed_45_bore[785])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_45_bore[785] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_45_bore[786] && w_s1_gatewayIn_packed_45_bore[786])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_45_bore[786] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_45_bore[787] && w_s1_gatewayIn_packed_45_bore[787])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_45_bore[787] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_45_bore[788] && w_s1_gatewayIn_packed_45_bore[788])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_45_bore[788] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_45_bore[789] && w_s1_gatewayIn_packed_45_bore[789])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_45_bore[789] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_45_bore[790] && w_s1_gatewayIn_packed_45_bore[790])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_45_bore[790] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_45_bore[791] && w_s1_gatewayIn_packed_45_bore[791])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_45_bore[791] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_45_bore[792] && w_s1_gatewayIn_packed_45_bore[792])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_45_bore[792] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_45_bore[793] && w_s1_gatewayIn_packed_45_bore[793])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_45_bore[793] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_45_bore[794] && w_s1_gatewayIn_packed_45_bore[794])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_45_bore[794] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_45_bore[795] && w_s1_gatewayIn_packed_45_bore[795])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_45_bore[795] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_45_bore[796] && w_s1_gatewayIn_packed_45_bore[796])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_45_bore[796] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_45_bore[797] && w_s1_gatewayIn_packed_45_bore[797])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_45_bore[797] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_45_bore[798] && w_s1_gatewayIn_packed_45_bore[798])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_45_bore[798] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_45_bore[799] && w_s1_gatewayIn_packed_45_bore[799])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_45_bore[799] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_45_bore[800] && w_s1_gatewayIn_packed_45_bore[800])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_45_bore[800] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_45_bore[801] && w_s1_gatewayIn_packed_45_bore[801])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_45_bore[801] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_45_bore[802] && w_s1_gatewayIn_packed_45_bore[802])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_45_bore[802] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_45_bore[803] && w_s1_gatewayIn_packed_45_bore[803])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_45_bore[803] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_45_bore[804] && w_s1_gatewayIn_packed_45_bore[804])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_45_bore[804] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_45_bore[805] && w_s1_gatewayIn_packed_45_bore[805])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_45_bore[805] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_45_bore[806] && w_s1_gatewayIn_packed_45_bore[806])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_45_bore[806] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_45_bore[807] && w_s1_gatewayIn_packed_45_bore[807])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_45_bore[807] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_45_bore[808] && w_s1_gatewayIn_packed_45_bore[808])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_45_bore[808] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_45_bore[809] && w_s1_gatewayIn_packed_45_bore[809])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_45_bore[809] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_45_bore[810] && w_s1_gatewayIn_packed_45_bore[810])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_45_bore[810] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_45_bore[811] && w_s1_gatewayIn_packed_45_bore[811])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_45_bore[811] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_45_bore[812] && w_s1_gatewayIn_packed_45_bore[812])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_45_bore[812] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_45_bore[813] && w_s1_gatewayIn_packed_45_bore[813])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_45_bore[813] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_45_bore[814] && w_s1_gatewayIn_packed_45_bore[814])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_45_bore[814] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_45_bore[815] && w_s1_gatewayIn_packed_45_bore[815])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_45_bore[815] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_45_bore[816] && w_s1_gatewayIn_packed_45_bore[816])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_45_bore[816] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_45_bore[817] && w_s1_gatewayIn_packed_45_bore[817])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_45_bore[817] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_45_bore[818] && w_s1_gatewayIn_packed_45_bore[818])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_45_bore[818] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_45_bore[819] && w_s1_gatewayIn_packed_45_bore[819])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_45_bore[819] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_45_bore[820] && w_s1_gatewayIn_packed_45_bore[820])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_45_bore[820] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_45_bore[821] && w_s1_gatewayIn_packed_45_bore[821])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_45_bore[821] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_45_bore[822] && w_s1_gatewayIn_packed_45_bore[822])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_45_bore[822] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_45_bore[823] && w_s1_gatewayIn_packed_45_bore[823])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_45_bore[823] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_45_bore[824] && w_s1_gatewayIn_packed_45_bore[824])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_45_bore[824] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_45_bore[825] && w_s1_gatewayIn_packed_45_bore[825])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_45_bore[825] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_45_bore[826] && w_s1_gatewayIn_packed_45_bore[826])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_45_bore[826] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_45_bore[827] && w_s1_gatewayIn_packed_45_bore[827])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_45_bore[827] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_45_bore[828] && w_s1_gatewayIn_packed_45_bore[828])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_45_bore[828] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_45_bore[829] && w_s1_gatewayIn_packed_45_bore[829])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_45_bore[829] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_45_bore[830] && w_s1_gatewayIn_packed_45_bore[830])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_45_bore[830] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_45_bore[831] && w_s1_gatewayIn_packed_45_bore[831])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_45_bore[831] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_45_bore[832] && w_s1_gatewayIn_packed_45_bore[832])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_45_bore[832] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_45_bore[833] && w_s1_gatewayIn_packed_45_bore[833])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_45_bore[833] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_45_bore[834] && w_s1_gatewayIn_packed_45_bore[834])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_45_bore[834] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_45_bore[835] && w_s1_gatewayIn_packed_45_bore[835])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_45_bore[835] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_45_bore[836] && w_s1_gatewayIn_packed_45_bore[836])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_45_bore[836] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_45_bore[837] && w_s1_gatewayIn_packed_45_bore[837])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_45_bore[837] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_45_bore[838] && w_s1_gatewayIn_packed_45_bore[838])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_45_bore[838] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_45_bore[839] && w_s1_gatewayIn_packed_45_bore[839])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_45_bore[839] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_45_bore[840] && w_s1_gatewayIn_packed_45_bore[840])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_45_bore[840] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_45_bore[841] && w_s1_gatewayIn_packed_45_bore[841])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_45_bore[841] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_45_bore[842] && w_s1_gatewayIn_packed_45_bore[842])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_45_bore[842] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_45_bore[843] && w_s1_gatewayIn_packed_45_bore[843])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_45_bore[843] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_45_bore[844] && w_s1_gatewayIn_packed_45_bore[844])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_45_bore[844] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_45_bore[845] && w_s1_gatewayIn_packed_45_bore[845])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_45_bore[845] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_45_bore[846] && w_s1_gatewayIn_packed_45_bore[846])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_45_bore[846] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_45_bore[847] && w_s1_gatewayIn_packed_45_bore[847])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_45_bore[847] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_45_bore[848] && w_s1_gatewayIn_packed_45_bore[848])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_45_bore[848] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_45_bore[849] && w_s1_gatewayIn_packed_45_bore[849])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_45_bore[849] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_45_bore[850] && w_s1_gatewayIn_packed_45_bore[850])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_45_bore[850] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_45_bore[851] && w_s1_gatewayIn_packed_45_bore[851])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_45_bore[851] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_45_bore[852] && w_s1_gatewayIn_packed_45_bore[852])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_45_bore[852] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_45_bore[853] && w_s1_gatewayIn_packed_45_bore[853])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_45_bore[853] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_45_bore[854] && w_s1_gatewayIn_packed_45_bore[854])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_45_bore[854] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_45_bore[855] && w_s1_gatewayIn_packed_45_bore[855])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_45_bore[855] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_45_bore[856] && w_s1_gatewayIn_packed_45_bore[856])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_45_bore[856] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_45_bore[857] && w_s1_gatewayIn_packed_45_bore[857])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_45_bore[857] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_45_bore[858] && w_s1_gatewayIn_packed_45_bore[858])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_45_bore[858] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_45_bore[859] && w_s1_gatewayIn_packed_45_bore[859])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_45_bore[859] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_45_bore[860] && w_s1_gatewayIn_packed_45_bore[860])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_45_bore[860] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_45_bore[861] && w_s1_gatewayIn_packed_45_bore[861])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_45_bore[861] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_45_bore[862] && w_s1_gatewayIn_packed_45_bore[862])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_45_bore[862] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_45_bore[863] && w_s1_gatewayIn_packed_45_bore[863])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_45_bore[863] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_45_bore[864] && w_s1_gatewayIn_packed_45_bore[864])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_45_bore[864] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_45_bore[865] && w_s1_gatewayIn_packed_45_bore[865])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_45_bore[865] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_45_bore[866] && w_s1_gatewayIn_packed_45_bore[866])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_45_bore[866] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_45_bore[867] && w_s1_gatewayIn_packed_45_bore[867])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_45_bore[867] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_45_bore[868] && w_s1_gatewayIn_packed_45_bore[868])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_45_bore[868] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_45_bore[869] && w_s1_gatewayIn_packed_45_bore[869])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_45_bore[869] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_45_bore[870] && w_s1_gatewayIn_packed_45_bore[870])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_45_bore[870] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_45_bore[871] && w_s1_gatewayIn_packed_45_bore[871])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_45_bore[871] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_45_bore[872] && w_s1_gatewayIn_packed_45_bore[872])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_45_bore[872] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_45_bore[873] && w_s1_gatewayIn_packed_45_bore[873])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_45_bore[873] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_45_bore[874] && w_s1_gatewayIn_packed_45_bore[874])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_45_bore[874] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_45_bore[875] && w_s1_gatewayIn_packed_45_bore[875])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_45_bore[875] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_45_bore[876] && w_s1_gatewayIn_packed_45_bore[876])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_45_bore[876] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_45_bore[877] && w_s1_gatewayIn_packed_45_bore[877])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_45_bore[877] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_45_bore[878] && w_s1_gatewayIn_packed_45_bore[878])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_45_bore[878] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_45_bore[879] && w_s1_gatewayIn_packed_45_bore[879])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_45_bore[879] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_45_bore[880] && w_s1_gatewayIn_packed_45_bore[880])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_45_bore[880] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_45_bore[881] && w_s1_gatewayIn_packed_45_bore[881])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_45_bore[881] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_45_bore[882] && w_s1_gatewayIn_packed_45_bore[882])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_45_bore[882] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_45_bore[883] && w_s1_gatewayIn_packed_45_bore[883])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_45_bore[883] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_45_bore[884] && w_s1_gatewayIn_packed_45_bore[884])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_45_bore[884] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_45_bore[885] && w_s1_gatewayIn_packed_45_bore[885])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_45_bore[885] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_45_bore[886] && w_s1_gatewayIn_packed_45_bore[886])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_45_bore[886] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_45_bore[887] && w_s1_gatewayIn_packed_45_bore[887])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_45_bore[887] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_45_bore[888] && w_s1_gatewayIn_packed_45_bore[888])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_45_bore[888] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_45_bore[889] && w_s1_gatewayIn_packed_45_bore[889])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_45_bore[889] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_45_bore[890] && w_s1_gatewayIn_packed_45_bore[890])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_45_bore[890] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_45_bore[891] && w_s1_gatewayIn_packed_45_bore[891])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_45_bore[891] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_45_bore[892] && w_s1_gatewayIn_packed_45_bore[892])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_45_bore[892] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_45_bore[893] && w_s1_gatewayIn_packed_45_bore[893])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_45_bore[893] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_45_bore[894] && w_s1_gatewayIn_packed_45_bore[894])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_45_bore[894] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_45_bore[895] && w_s1_gatewayIn_packed_45_bore[895])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_45_bore[895] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_45_bore[896] && w_s1_gatewayIn_packed_45_bore[896])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_45_bore[896] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_45_bore[897] && w_s1_gatewayIn_packed_45_bore[897])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_45_bore[897] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_45_bore[898] && w_s1_gatewayIn_packed_45_bore[898])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_45_bore[898] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_45_bore[899] && w_s1_gatewayIn_packed_45_bore[899])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_45_bore[899] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_45_bore[900] && w_s1_gatewayIn_packed_45_bore[900])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_45_bore[900] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_45_bore[901] && w_s1_gatewayIn_packed_45_bore[901])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_45_bore[901] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_45_bore[902] && w_s1_gatewayIn_packed_45_bore[902])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_45_bore[902] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_45_bore[903] && w_s1_gatewayIn_packed_45_bore[903])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_45_bore[903] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_45_bore[904] && w_s1_gatewayIn_packed_45_bore[904])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_45_bore[904] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_45_bore[905] && w_s1_gatewayIn_packed_45_bore[905])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_45_bore[905] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_45_bore[906] && w_s1_gatewayIn_packed_45_bore[906])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_45_bore[906] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_45_bore[907] && w_s1_gatewayIn_packed_45_bore[907])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_45_bore[907] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_45_bore[908] && w_s1_gatewayIn_packed_45_bore[908])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_45_bore[908] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_45_bore[909] && w_s1_gatewayIn_packed_45_bore[909])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_45_bore[909] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_45_bore[910] && w_s1_gatewayIn_packed_45_bore[910])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_45_bore[910] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_45_bore[911] && w_s1_gatewayIn_packed_45_bore[911])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_45_bore[911] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_45_bore[912] && w_s1_gatewayIn_packed_45_bore[912])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_45_bore[912] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_45_bore[913] && w_s1_gatewayIn_packed_45_bore[913])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_45_bore[913] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_45_bore[914] && w_s1_gatewayIn_packed_45_bore[914])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_45_bore[914] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_45_bore[915] && w_s1_gatewayIn_packed_45_bore[915])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_45_bore[915] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_45_bore[916] && w_s1_gatewayIn_packed_45_bore[916])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_45_bore[916] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_45_bore[917] && w_s1_gatewayIn_packed_45_bore[917])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_45_bore[917] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_45_bore[918] && w_s1_gatewayIn_packed_45_bore[918])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_45_bore[918] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_45_bore[919] && w_s1_gatewayIn_packed_45_bore[919])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_45_bore[919] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_45_bore[920] && w_s1_gatewayIn_packed_45_bore[920])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_45_bore[920] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_45_bore[921] && w_s1_gatewayIn_packed_45_bore[921])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_45_bore[921] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_45_bore[922] && w_s1_gatewayIn_packed_45_bore[922])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_45_bore[922] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_45_bore[923] && w_s1_gatewayIn_packed_45_bore[923])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_45_bore[923] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_45_bore[924] && w_s1_gatewayIn_packed_45_bore[924])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_45_bore[924] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_45_bore[925] && w_s1_gatewayIn_packed_45_bore[925])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_45_bore[925] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_45_bore[926] && w_s1_gatewayIn_packed_45_bore[926])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_45_bore[926] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_45_bore[927] && w_s1_gatewayIn_packed_45_bore[927])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_45_bore[927] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_45_bore[928] && w_s1_gatewayIn_packed_45_bore[928])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_45_bore[928] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_45_bore[929] && w_s1_gatewayIn_packed_45_bore[929])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_45_bore[929] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_45_bore[930] && w_s1_gatewayIn_packed_45_bore[930])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_45_bore[930] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_45_bore[931] && w_s1_gatewayIn_packed_45_bore[931])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_45_bore[931] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_45_bore[932] && w_s1_gatewayIn_packed_45_bore[932])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_45_bore[932] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_45_bore[933] && w_s1_gatewayIn_packed_45_bore[933])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_45_bore[933] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_45_bore[934] && w_s1_gatewayIn_packed_45_bore[934])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_45_bore[934] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_45_bore[935] && w_s1_gatewayIn_packed_45_bore[935])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_45_bore[935] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_45_bore[936] && w_s1_gatewayIn_packed_45_bore[936])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_45_bore[936] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_45_bore[937] && w_s1_gatewayIn_packed_45_bore[937])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_45_bore[937] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_45_bore[938] && w_s1_gatewayIn_packed_45_bore[938])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_45_bore[938] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_45_bore[939] && w_s1_gatewayIn_packed_45_bore[939])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_45_bore[939] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_45_bore[940] && w_s1_gatewayIn_packed_45_bore[940])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_45_bore[940] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_45_bore[941] && w_s1_gatewayIn_packed_45_bore[941])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_45_bore[941] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_45_bore[942] && w_s1_gatewayIn_packed_45_bore[942])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_45_bore[942] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_45_bore[943] && w_s1_gatewayIn_packed_45_bore[943])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_45_bore[943] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_45_bore[944] && w_s1_gatewayIn_packed_45_bore[944])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_45_bore[944] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_45_bore[945] && w_s1_gatewayIn_packed_45_bore[945])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_45_bore[945] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_45_bore[946] && w_s1_gatewayIn_packed_45_bore[946])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_45_bore[946] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_45_bore[947] && w_s1_gatewayIn_packed_45_bore[947])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_45_bore[947] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_45_bore[948] && w_s1_gatewayIn_packed_45_bore[948])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_45_bore[948] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_45_bore[949] && w_s1_gatewayIn_packed_45_bore[949])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_45_bore[949] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_45_bore[950] && w_s1_gatewayIn_packed_45_bore[950])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_45_bore[950] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_45_bore[951] && w_s1_gatewayIn_packed_45_bore[951])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_45_bore[951] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_45_bore[952] && w_s1_gatewayIn_packed_45_bore[952])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_45_bore[952] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_45_bore[953] && w_s1_gatewayIn_packed_45_bore[953])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_45_bore[953] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_45_bore[954] && w_s1_gatewayIn_packed_45_bore[954])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_45_bore[954] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_45_bore[955] && w_s1_gatewayIn_packed_45_bore[955])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_45_bore[955] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_45_bore[956] && w_s1_gatewayIn_packed_45_bore[956])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_45_bore[956] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_45_bore[957] && w_s1_gatewayIn_packed_45_bore[957])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_45_bore[957] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_45_bore[958] && w_s1_gatewayIn_packed_45_bore[958])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_45_bore[958] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_45_bore[959] && w_s1_gatewayIn_packed_45_bore[959])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_45_bore[959] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_45_bore[960] && w_s1_gatewayIn_packed_45_bore[960])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_45_bore[960] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_45_bore[961] && w_s1_gatewayIn_packed_45_bore[961])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_45_bore[961] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_45_bore[962] && w_s1_gatewayIn_packed_45_bore[962])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_45_bore[962] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_45_bore[963] && w_s1_gatewayIn_packed_45_bore[963])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_45_bore[963] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_45_bore[964] && w_s1_gatewayIn_packed_45_bore[964])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_45_bore[964] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_45_bore[965] && w_s1_gatewayIn_packed_45_bore[965])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_45_bore[965] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_45_bore[966] && w_s1_gatewayIn_packed_45_bore[966])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_45_bore[966] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_45_bore[967] && w_s1_gatewayIn_packed_45_bore[967])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_45_bore[967] 未见过 0 和 1"); end
    if (!(w_s0_gatewayIn_packed_45_bore[968] && w_s1_gatewayIn_packed_45_bore[968])) begin cov_fail++; $display("[COV] L2TLBWrapper.gatewayIn_packed_45_bore[968] 未见过 0 和 1"); end
    $display("[ARM] L2TLBWrapper armed_at=%0d", w_armed_at);
    if (w_armed_at < 0) begin cov_fail++; $display("[ARM] L2TLBWrapper 从未 arm"); end
    $display("[COV] L2TLBWrapper.perf_nz = %0d", w_cov_perf_nz);
    if (w_cov_perf_nz < 10) begin cov_fail++; $display("[COV] L2TLBWrapper.perf_nz < 10"); end
    $display("[COV] L2TLBWrapper.ptw_req = %0d", w_cov_ptw_req);
    if (w_cov_ptw_req < 10) begin cov_fail++; $display("[COV] L2TLBWrapper.ptw_req < 10"); end
    $display("[COV] L2TLBWrapper.tlb_resp = %0d", w_cov_tlb_resp);
    if (w_cov_tlb_resp < 10) begin cov_fail++; $display("[COV] L2TLBWrapper.tlb_resp < 10"); end
    $display("checks=%0d errors=%0d cov_fail=%0d", checks, errors, cov_fail);
    if (errors == 0 && cov_fail == 0 && checks > 0) $display("TEST PASSED");
    else $display("TEST FAILED");
    $finish;
  end
endmodule
