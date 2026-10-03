// 自动生成：verif/ut/PTWFilter/gen.py（scripts/dual_tb_lib.py，读 G1 golden 端口表）—— 勿手改
// PTWFilter 双例化逐拍比对：golden PTWFilter vs 重写 PTWFilter_xs，全部输出逐位 !==。
`timescale 1ns/1ps
module tb;
  int unsigned NCYCLES = 200000;
  int errors = 0, checks = 0, cov_fail = 0;
  int unsigned cyc = 0;
  logic clk = 1'b0;
  always #5 clk = ~clk;
  localparam int RESET_CYC = 8;

  // ================= PTWFilter =================
  int unsigned pf_mode = 0;
  logic [7:0][37:0] pf_pool;
  logic [7:0][37:0] pf_vpns;
  logic [7:0][1:0]  pf_s2xs;
  logic [37:0]      pf_tvpn;
  logic [1:0]       pf_ts2x;
  int unsigned      pf_enq_total = 0;
  function automatic logic [1:0] pf_s2x(input int unsigned mode);
    case (mode % 4)
      0:       return 2'd0;
      1:       return 2'd2;
      2:       return 2'($urandom_range(0, 3));
      default: return {1'($urandom), 1'b1};   // onlyStage1 / allStage
    endcase
  endfunction
  logic pf_reset;
  logic pf_io_sfence_valid;
  logic [15:0] pf_io_csr_satp_asid;
  logic pf_io_csr_satp_changed;
  logic [15:0] pf_io_csr_vsatp_asid;
  logic pf_io_csr_vsatp_changed;
  logic [15:0] pf_io_csr_hgatp_vmid;
  logic pf_io_csr_hgatp_changed;
  logic pf_io_csr_priv_virt_changed;
  wire  pf_g_io_tlb_req_0_ready, pf_i_io_tlb_req_0_ready;
  logic pf_s0_io_tlb_req_0_ready = '0, pf_s1_io_tlb_req_0_ready = '0;
  logic pf_io_tlb_req_0_valid;
  logic [37:0] pf_io_tlb_req_0_bits_vpn;
  logic [1:0] pf_io_tlb_req_0_bits_s2xlate;
  logic pf_io_tlb_req_0_bits_getGpa;
  wire  pf_g_io_tlb_req_1_ready, pf_i_io_tlb_req_1_ready;
  logic pf_s0_io_tlb_req_1_ready = '0, pf_s1_io_tlb_req_1_ready = '0;
  logic pf_io_tlb_req_1_valid;
  logic [37:0] pf_io_tlb_req_1_bits_vpn;
  logic [1:0] pf_io_tlb_req_1_bits_s2xlate;
  logic pf_io_tlb_req_1_bits_getGpa;
  wire  pf_g_io_tlb_req_2_ready, pf_i_io_tlb_req_2_ready;
  logic pf_s0_io_tlb_req_2_ready = '0, pf_s1_io_tlb_req_2_ready = '0;
  logic pf_io_tlb_req_2_valid;
  logic [37:0] pf_io_tlb_req_2_bits_vpn;
  logic [1:0] pf_io_tlb_req_2_bits_s2xlate;
  logic pf_io_tlb_req_2_bits_getGpa;
  wire  pf_g_io_tlb_resp_valid, pf_i_io_tlb_resp_valid;
  logic pf_s0_io_tlb_resp_valid = '0, pf_s1_io_tlb_resp_valid = '0;
  wire  [1:0] pf_g_io_tlb_resp_bits_data_s2xlate, pf_i_io_tlb_resp_bits_data_s2xlate;
  logic [1:0] pf_s0_io_tlb_resp_bits_data_s2xlate = '0, pf_s1_io_tlb_resp_bits_data_s2xlate = '0;
  wire  [34:0] pf_g_io_tlb_resp_bits_data_s1_entry_tag, pf_i_io_tlb_resp_bits_data_s1_entry_tag;
  logic [34:0] pf_s0_io_tlb_resp_bits_data_s1_entry_tag = '0, pf_s1_io_tlb_resp_bits_data_s1_entry_tag = '0;
  wire  [15:0] pf_g_io_tlb_resp_bits_data_s1_entry_asid, pf_i_io_tlb_resp_bits_data_s1_entry_asid;
  logic [15:0] pf_s0_io_tlb_resp_bits_data_s1_entry_asid = '0, pf_s1_io_tlb_resp_bits_data_s1_entry_asid = '0;
  wire  [13:0] pf_g_io_tlb_resp_bits_data_s1_entry_vmid, pf_i_io_tlb_resp_bits_data_s1_entry_vmid;
  logic [13:0] pf_s0_io_tlb_resp_bits_data_s1_entry_vmid = '0, pf_s1_io_tlb_resp_bits_data_s1_entry_vmid = '0;
  wire  pf_g_io_tlb_resp_bits_data_s1_entry_n, pf_i_io_tlb_resp_bits_data_s1_entry_n;
  logic pf_s0_io_tlb_resp_bits_data_s1_entry_n = '0, pf_s1_io_tlb_resp_bits_data_s1_entry_n = '0;
  wire  [1:0] pf_g_io_tlb_resp_bits_data_s1_entry_pbmt, pf_i_io_tlb_resp_bits_data_s1_entry_pbmt;
  logic [1:0] pf_s0_io_tlb_resp_bits_data_s1_entry_pbmt = '0, pf_s1_io_tlb_resp_bits_data_s1_entry_pbmt = '0;
  wire  pf_g_io_tlb_resp_bits_data_s1_entry_perm_d, pf_i_io_tlb_resp_bits_data_s1_entry_perm_d;
  logic pf_s0_io_tlb_resp_bits_data_s1_entry_perm_d = '0, pf_s1_io_tlb_resp_bits_data_s1_entry_perm_d = '0;
  wire  pf_g_io_tlb_resp_bits_data_s1_entry_perm_a, pf_i_io_tlb_resp_bits_data_s1_entry_perm_a;
  logic pf_s0_io_tlb_resp_bits_data_s1_entry_perm_a = '0, pf_s1_io_tlb_resp_bits_data_s1_entry_perm_a = '0;
  wire  pf_g_io_tlb_resp_bits_data_s1_entry_perm_g, pf_i_io_tlb_resp_bits_data_s1_entry_perm_g;
  logic pf_s0_io_tlb_resp_bits_data_s1_entry_perm_g = '0, pf_s1_io_tlb_resp_bits_data_s1_entry_perm_g = '0;
  wire  pf_g_io_tlb_resp_bits_data_s1_entry_perm_u, pf_i_io_tlb_resp_bits_data_s1_entry_perm_u;
  logic pf_s0_io_tlb_resp_bits_data_s1_entry_perm_u = '0, pf_s1_io_tlb_resp_bits_data_s1_entry_perm_u = '0;
  wire  pf_g_io_tlb_resp_bits_data_s1_entry_perm_x, pf_i_io_tlb_resp_bits_data_s1_entry_perm_x;
  logic pf_s0_io_tlb_resp_bits_data_s1_entry_perm_x = '0, pf_s1_io_tlb_resp_bits_data_s1_entry_perm_x = '0;
  wire  pf_g_io_tlb_resp_bits_data_s1_entry_perm_w, pf_i_io_tlb_resp_bits_data_s1_entry_perm_w;
  logic pf_s0_io_tlb_resp_bits_data_s1_entry_perm_w = '0, pf_s1_io_tlb_resp_bits_data_s1_entry_perm_w = '0;
  wire  pf_g_io_tlb_resp_bits_data_s1_entry_perm_r, pf_i_io_tlb_resp_bits_data_s1_entry_perm_r;
  logic pf_s0_io_tlb_resp_bits_data_s1_entry_perm_r = '0, pf_s1_io_tlb_resp_bits_data_s1_entry_perm_r = '0;
  wire  [1:0] pf_g_io_tlb_resp_bits_data_s1_entry_level, pf_i_io_tlb_resp_bits_data_s1_entry_level;
  logic [1:0] pf_s0_io_tlb_resp_bits_data_s1_entry_level = '0, pf_s1_io_tlb_resp_bits_data_s1_entry_level = '0;
  wire  pf_g_io_tlb_resp_bits_data_s1_entry_v, pf_i_io_tlb_resp_bits_data_s1_entry_v;
  logic pf_s0_io_tlb_resp_bits_data_s1_entry_v = '0, pf_s1_io_tlb_resp_bits_data_s1_entry_v = '0;
  wire  [40:0] pf_g_io_tlb_resp_bits_data_s1_entry_ppn, pf_i_io_tlb_resp_bits_data_s1_entry_ppn;
  logic [40:0] pf_s0_io_tlb_resp_bits_data_s1_entry_ppn = '0, pf_s1_io_tlb_resp_bits_data_s1_entry_ppn = '0;
  wire  [2:0] pf_g_io_tlb_resp_bits_data_s1_addr_low, pf_i_io_tlb_resp_bits_data_s1_addr_low;
  logic [2:0] pf_s0_io_tlb_resp_bits_data_s1_addr_low = '0, pf_s1_io_tlb_resp_bits_data_s1_addr_low = '0;
  wire  [2:0] pf_g_io_tlb_resp_bits_data_s1_ppn_low_0, pf_i_io_tlb_resp_bits_data_s1_ppn_low_0;
  logic [2:0] pf_s0_io_tlb_resp_bits_data_s1_ppn_low_0 = '0, pf_s1_io_tlb_resp_bits_data_s1_ppn_low_0 = '0;
  wire  [2:0] pf_g_io_tlb_resp_bits_data_s1_ppn_low_1, pf_i_io_tlb_resp_bits_data_s1_ppn_low_1;
  logic [2:0] pf_s0_io_tlb_resp_bits_data_s1_ppn_low_1 = '0, pf_s1_io_tlb_resp_bits_data_s1_ppn_low_1 = '0;
  wire  [2:0] pf_g_io_tlb_resp_bits_data_s1_ppn_low_2, pf_i_io_tlb_resp_bits_data_s1_ppn_low_2;
  logic [2:0] pf_s0_io_tlb_resp_bits_data_s1_ppn_low_2 = '0, pf_s1_io_tlb_resp_bits_data_s1_ppn_low_2 = '0;
  wire  [2:0] pf_g_io_tlb_resp_bits_data_s1_ppn_low_3, pf_i_io_tlb_resp_bits_data_s1_ppn_low_3;
  logic [2:0] pf_s0_io_tlb_resp_bits_data_s1_ppn_low_3 = '0, pf_s1_io_tlb_resp_bits_data_s1_ppn_low_3 = '0;
  wire  [2:0] pf_g_io_tlb_resp_bits_data_s1_ppn_low_4, pf_i_io_tlb_resp_bits_data_s1_ppn_low_4;
  logic [2:0] pf_s0_io_tlb_resp_bits_data_s1_ppn_low_4 = '0, pf_s1_io_tlb_resp_bits_data_s1_ppn_low_4 = '0;
  wire  [2:0] pf_g_io_tlb_resp_bits_data_s1_ppn_low_5, pf_i_io_tlb_resp_bits_data_s1_ppn_low_5;
  logic [2:0] pf_s0_io_tlb_resp_bits_data_s1_ppn_low_5 = '0, pf_s1_io_tlb_resp_bits_data_s1_ppn_low_5 = '0;
  wire  [2:0] pf_g_io_tlb_resp_bits_data_s1_ppn_low_6, pf_i_io_tlb_resp_bits_data_s1_ppn_low_6;
  logic [2:0] pf_s0_io_tlb_resp_bits_data_s1_ppn_low_6 = '0, pf_s1_io_tlb_resp_bits_data_s1_ppn_low_6 = '0;
  wire  [2:0] pf_g_io_tlb_resp_bits_data_s1_ppn_low_7, pf_i_io_tlb_resp_bits_data_s1_ppn_low_7;
  logic [2:0] pf_s0_io_tlb_resp_bits_data_s1_ppn_low_7 = '0, pf_s1_io_tlb_resp_bits_data_s1_ppn_low_7 = '0;
  wire  pf_g_io_tlb_resp_bits_data_s1_valididx_0, pf_i_io_tlb_resp_bits_data_s1_valididx_0;
  logic pf_s0_io_tlb_resp_bits_data_s1_valididx_0 = '0, pf_s1_io_tlb_resp_bits_data_s1_valididx_0 = '0;
  wire  pf_g_io_tlb_resp_bits_data_s1_valididx_1, pf_i_io_tlb_resp_bits_data_s1_valididx_1;
  logic pf_s0_io_tlb_resp_bits_data_s1_valididx_1 = '0, pf_s1_io_tlb_resp_bits_data_s1_valididx_1 = '0;
  wire  pf_g_io_tlb_resp_bits_data_s1_valididx_2, pf_i_io_tlb_resp_bits_data_s1_valididx_2;
  logic pf_s0_io_tlb_resp_bits_data_s1_valididx_2 = '0, pf_s1_io_tlb_resp_bits_data_s1_valididx_2 = '0;
  wire  pf_g_io_tlb_resp_bits_data_s1_valididx_3, pf_i_io_tlb_resp_bits_data_s1_valididx_3;
  logic pf_s0_io_tlb_resp_bits_data_s1_valididx_3 = '0, pf_s1_io_tlb_resp_bits_data_s1_valididx_3 = '0;
  wire  pf_g_io_tlb_resp_bits_data_s1_valididx_4, pf_i_io_tlb_resp_bits_data_s1_valididx_4;
  logic pf_s0_io_tlb_resp_bits_data_s1_valididx_4 = '0, pf_s1_io_tlb_resp_bits_data_s1_valididx_4 = '0;
  wire  pf_g_io_tlb_resp_bits_data_s1_valididx_5, pf_i_io_tlb_resp_bits_data_s1_valididx_5;
  logic pf_s0_io_tlb_resp_bits_data_s1_valididx_5 = '0, pf_s1_io_tlb_resp_bits_data_s1_valididx_5 = '0;
  wire  pf_g_io_tlb_resp_bits_data_s1_valididx_6, pf_i_io_tlb_resp_bits_data_s1_valididx_6;
  logic pf_s0_io_tlb_resp_bits_data_s1_valididx_6 = '0, pf_s1_io_tlb_resp_bits_data_s1_valididx_6 = '0;
  wire  pf_g_io_tlb_resp_bits_data_s1_valididx_7, pf_i_io_tlb_resp_bits_data_s1_valididx_7;
  logic pf_s0_io_tlb_resp_bits_data_s1_valididx_7 = '0, pf_s1_io_tlb_resp_bits_data_s1_valididx_7 = '0;
  wire  pf_g_io_tlb_resp_bits_data_s1_pteidx_0, pf_i_io_tlb_resp_bits_data_s1_pteidx_0;
  logic pf_s0_io_tlb_resp_bits_data_s1_pteidx_0 = '0, pf_s1_io_tlb_resp_bits_data_s1_pteidx_0 = '0;
  wire  pf_g_io_tlb_resp_bits_data_s1_pteidx_1, pf_i_io_tlb_resp_bits_data_s1_pteidx_1;
  logic pf_s0_io_tlb_resp_bits_data_s1_pteidx_1 = '0, pf_s1_io_tlb_resp_bits_data_s1_pteidx_1 = '0;
  wire  pf_g_io_tlb_resp_bits_data_s1_pteidx_2, pf_i_io_tlb_resp_bits_data_s1_pteidx_2;
  logic pf_s0_io_tlb_resp_bits_data_s1_pteidx_2 = '0, pf_s1_io_tlb_resp_bits_data_s1_pteidx_2 = '0;
  wire  pf_g_io_tlb_resp_bits_data_s1_pteidx_3, pf_i_io_tlb_resp_bits_data_s1_pteidx_3;
  logic pf_s0_io_tlb_resp_bits_data_s1_pteidx_3 = '0, pf_s1_io_tlb_resp_bits_data_s1_pteidx_3 = '0;
  wire  pf_g_io_tlb_resp_bits_data_s1_pteidx_4, pf_i_io_tlb_resp_bits_data_s1_pteidx_4;
  logic pf_s0_io_tlb_resp_bits_data_s1_pteidx_4 = '0, pf_s1_io_tlb_resp_bits_data_s1_pteidx_4 = '0;
  wire  pf_g_io_tlb_resp_bits_data_s1_pteidx_5, pf_i_io_tlb_resp_bits_data_s1_pteidx_5;
  logic pf_s0_io_tlb_resp_bits_data_s1_pteidx_5 = '0, pf_s1_io_tlb_resp_bits_data_s1_pteidx_5 = '0;
  wire  pf_g_io_tlb_resp_bits_data_s1_pteidx_6, pf_i_io_tlb_resp_bits_data_s1_pteidx_6;
  logic pf_s0_io_tlb_resp_bits_data_s1_pteidx_6 = '0, pf_s1_io_tlb_resp_bits_data_s1_pteidx_6 = '0;
  wire  pf_g_io_tlb_resp_bits_data_s1_pteidx_7, pf_i_io_tlb_resp_bits_data_s1_pteidx_7;
  logic pf_s0_io_tlb_resp_bits_data_s1_pteidx_7 = '0, pf_s1_io_tlb_resp_bits_data_s1_pteidx_7 = '0;
  wire  pf_g_io_tlb_resp_bits_data_s1_pf, pf_i_io_tlb_resp_bits_data_s1_pf;
  logic pf_s0_io_tlb_resp_bits_data_s1_pf = '0, pf_s1_io_tlb_resp_bits_data_s1_pf = '0;
  wire  pf_g_io_tlb_resp_bits_data_s1_af, pf_i_io_tlb_resp_bits_data_s1_af;
  logic pf_s0_io_tlb_resp_bits_data_s1_af = '0, pf_s1_io_tlb_resp_bits_data_s1_af = '0;
  wire  [37:0] pf_g_io_tlb_resp_bits_data_s2_entry_tag, pf_i_io_tlb_resp_bits_data_s2_entry_tag;
  logic [37:0] pf_s0_io_tlb_resp_bits_data_s2_entry_tag = '0, pf_s1_io_tlb_resp_bits_data_s2_entry_tag = '0;
  wire  [13:0] pf_g_io_tlb_resp_bits_data_s2_entry_vmid, pf_i_io_tlb_resp_bits_data_s2_entry_vmid;
  logic [13:0] pf_s0_io_tlb_resp_bits_data_s2_entry_vmid = '0, pf_s1_io_tlb_resp_bits_data_s2_entry_vmid = '0;
  wire  pf_g_io_tlb_resp_bits_data_s2_entry_n, pf_i_io_tlb_resp_bits_data_s2_entry_n;
  logic pf_s0_io_tlb_resp_bits_data_s2_entry_n = '0, pf_s1_io_tlb_resp_bits_data_s2_entry_n = '0;
  wire  [1:0] pf_g_io_tlb_resp_bits_data_s2_entry_pbmt, pf_i_io_tlb_resp_bits_data_s2_entry_pbmt;
  logic [1:0] pf_s0_io_tlb_resp_bits_data_s2_entry_pbmt = '0, pf_s1_io_tlb_resp_bits_data_s2_entry_pbmt = '0;
  wire  [37:0] pf_g_io_tlb_resp_bits_data_s2_entry_ppn, pf_i_io_tlb_resp_bits_data_s2_entry_ppn;
  logic [37:0] pf_s0_io_tlb_resp_bits_data_s2_entry_ppn = '0, pf_s1_io_tlb_resp_bits_data_s2_entry_ppn = '0;
  wire  pf_g_io_tlb_resp_bits_data_s2_entry_perm_d, pf_i_io_tlb_resp_bits_data_s2_entry_perm_d;
  logic pf_s0_io_tlb_resp_bits_data_s2_entry_perm_d = '0, pf_s1_io_tlb_resp_bits_data_s2_entry_perm_d = '0;
  wire  pf_g_io_tlb_resp_bits_data_s2_entry_perm_a, pf_i_io_tlb_resp_bits_data_s2_entry_perm_a;
  logic pf_s0_io_tlb_resp_bits_data_s2_entry_perm_a = '0, pf_s1_io_tlb_resp_bits_data_s2_entry_perm_a = '0;
  wire  pf_g_io_tlb_resp_bits_data_s2_entry_perm_g, pf_i_io_tlb_resp_bits_data_s2_entry_perm_g;
  logic pf_s0_io_tlb_resp_bits_data_s2_entry_perm_g = '0, pf_s1_io_tlb_resp_bits_data_s2_entry_perm_g = '0;
  wire  pf_g_io_tlb_resp_bits_data_s2_entry_perm_u, pf_i_io_tlb_resp_bits_data_s2_entry_perm_u;
  logic pf_s0_io_tlb_resp_bits_data_s2_entry_perm_u = '0, pf_s1_io_tlb_resp_bits_data_s2_entry_perm_u = '0;
  wire  pf_g_io_tlb_resp_bits_data_s2_entry_perm_x, pf_i_io_tlb_resp_bits_data_s2_entry_perm_x;
  logic pf_s0_io_tlb_resp_bits_data_s2_entry_perm_x = '0, pf_s1_io_tlb_resp_bits_data_s2_entry_perm_x = '0;
  wire  pf_g_io_tlb_resp_bits_data_s2_entry_perm_w, pf_i_io_tlb_resp_bits_data_s2_entry_perm_w;
  logic pf_s0_io_tlb_resp_bits_data_s2_entry_perm_w = '0, pf_s1_io_tlb_resp_bits_data_s2_entry_perm_w = '0;
  wire  pf_g_io_tlb_resp_bits_data_s2_entry_perm_r, pf_i_io_tlb_resp_bits_data_s2_entry_perm_r;
  logic pf_s0_io_tlb_resp_bits_data_s2_entry_perm_r = '0, pf_s1_io_tlb_resp_bits_data_s2_entry_perm_r = '0;
  wire  [1:0] pf_g_io_tlb_resp_bits_data_s2_entry_level, pf_i_io_tlb_resp_bits_data_s2_entry_level;
  logic [1:0] pf_s0_io_tlb_resp_bits_data_s2_entry_level = '0, pf_s1_io_tlb_resp_bits_data_s2_entry_level = '0;
  wire  pf_g_io_tlb_resp_bits_data_s2_gpf, pf_i_io_tlb_resp_bits_data_s2_gpf;
  logic pf_s0_io_tlb_resp_bits_data_s2_gpf = '0, pf_s1_io_tlb_resp_bits_data_s2_gpf = '0;
  wire  pf_g_io_tlb_resp_bits_data_s2_gaf, pf_i_io_tlb_resp_bits_data_s2_gaf;
  logic pf_s0_io_tlb_resp_bits_data_s2_gaf = '0, pf_s1_io_tlb_resp_bits_data_s2_gaf = '0;
  wire  pf_g_io_tlb_resp_bits_data_getGpa, pf_i_io_tlb_resp_bits_data_getGpa;
  logic pf_s0_io_tlb_resp_bits_data_getGpa = '0, pf_s1_io_tlb_resp_bits_data_getGpa = '0;
  logic pf_io_ptw_req_0_ready;
  wire  pf_g_io_ptw_req_0_valid, pf_i_io_ptw_req_0_valid;
  logic pf_s0_io_ptw_req_0_valid = '0, pf_s1_io_ptw_req_0_valid = '0;
  wire  [37:0] pf_g_io_ptw_req_0_bits_vpn, pf_i_io_ptw_req_0_bits_vpn;
  logic [37:0] pf_s0_io_ptw_req_0_bits_vpn = '0, pf_s1_io_ptw_req_0_bits_vpn = '0;
  wire  [1:0] pf_g_io_ptw_req_0_bits_s2xlate, pf_i_io_ptw_req_0_bits_s2xlate;
  logic [1:0] pf_s0_io_ptw_req_0_bits_s2xlate = '0, pf_s1_io_ptw_req_0_bits_s2xlate = '0;
  logic pf_io_ptw_resp_valid;
  logic [1:0] pf_io_ptw_resp_bits_s2xlate;
  logic [34:0] pf_io_ptw_resp_bits_s1_entry_tag;
  logic [15:0] pf_io_ptw_resp_bits_s1_entry_asid;
  logic [13:0] pf_io_ptw_resp_bits_s1_entry_vmid;
  logic pf_io_ptw_resp_bits_s1_entry_n;
  logic [1:0] pf_io_ptw_resp_bits_s1_entry_pbmt;
  logic pf_io_ptw_resp_bits_s1_entry_perm_d;
  logic pf_io_ptw_resp_bits_s1_entry_perm_a;
  logic pf_io_ptw_resp_bits_s1_entry_perm_g;
  logic pf_io_ptw_resp_bits_s1_entry_perm_u;
  logic pf_io_ptw_resp_bits_s1_entry_perm_x;
  logic pf_io_ptw_resp_bits_s1_entry_perm_w;
  logic pf_io_ptw_resp_bits_s1_entry_perm_r;
  logic [1:0] pf_io_ptw_resp_bits_s1_entry_level;
  logic pf_io_ptw_resp_bits_s1_entry_v;
  logic [40:0] pf_io_ptw_resp_bits_s1_entry_ppn;
  logic [2:0] pf_io_ptw_resp_bits_s1_addr_low;
  logic [2:0] pf_io_ptw_resp_bits_s1_ppn_low_0;
  logic [2:0] pf_io_ptw_resp_bits_s1_ppn_low_1;
  logic [2:0] pf_io_ptw_resp_bits_s1_ppn_low_2;
  logic [2:0] pf_io_ptw_resp_bits_s1_ppn_low_3;
  logic [2:0] pf_io_ptw_resp_bits_s1_ppn_low_4;
  logic [2:0] pf_io_ptw_resp_bits_s1_ppn_low_5;
  logic [2:0] pf_io_ptw_resp_bits_s1_ppn_low_6;
  logic [2:0] pf_io_ptw_resp_bits_s1_ppn_low_7;
  logic pf_io_ptw_resp_bits_s1_valididx_0;
  logic pf_io_ptw_resp_bits_s1_valididx_1;
  logic pf_io_ptw_resp_bits_s1_valididx_2;
  logic pf_io_ptw_resp_bits_s1_valididx_3;
  logic pf_io_ptw_resp_bits_s1_valididx_4;
  logic pf_io_ptw_resp_bits_s1_valididx_5;
  logic pf_io_ptw_resp_bits_s1_valididx_6;
  logic pf_io_ptw_resp_bits_s1_valididx_7;
  logic pf_io_ptw_resp_bits_s1_pteidx_0;
  logic pf_io_ptw_resp_bits_s1_pteidx_1;
  logic pf_io_ptw_resp_bits_s1_pteidx_2;
  logic pf_io_ptw_resp_bits_s1_pteidx_3;
  logic pf_io_ptw_resp_bits_s1_pteidx_4;
  logic pf_io_ptw_resp_bits_s1_pteidx_5;
  logic pf_io_ptw_resp_bits_s1_pteidx_6;
  logic pf_io_ptw_resp_bits_s1_pteidx_7;
  logic pf_io_ptw_resp_bits_s1_pf;
  logic pf_io_ptw_resp_bits_s1_af;
  logic [37:0] pf_io_ptw_resp_bits_s2_entry_tag;
  logic [13:0] pf_io_ptw_resp_bits_s2_entry_vmid;
  logic pf_io_ptw_resp_bits_s2_entry_n;
  logic [1:0] pf_io_ptw_resp_bits_s2_entry_pbmt;
  logic [37:0] pf_io_ptw_resp_bits_s2_entry_ppn;
  logic pf_io_ptw_resp_bits_s2_entry_perm_d;
  logic pf_io_ptw_resp_bits_s2_entry_perm_a;
  logic pf_io_ptw_resp_bits_s2_entry_perm_g;
  logic pf_io_ptw_resp_bits_s2_entry_perm_u;
  logic pf_io_ptw_resp_bits_s2_entry_perm_x;
  logic pf_io_ptw_resp_bits_s2_entry_perm_w;
  logic pf_io_ptw_resp_bits_s2_entry_perm_r;
  logic [1:0] pf_io_ptw_resp_bits_s2_entry_level;
  logic pf_io_ptw_resp_bits_s2_gpf;
  logic pf_io_ptw_resp_bits_s2_gaf;
  int pf_cov_enq = 0;
  int pf_cov_enq2plus = 0;
  int pf_cov_enq_blocked = 0;
  int pf_cov_ready_low = 0;
  int pf_cov_full = 0;
  int pf_cov_deq = 0;
  int pf_cov_iss_fire = 0;
  int pf_cov_iss_skip_dead = 0;
  int pf_cov_inflight_full = 0;
  int pf_cov_resp_hit_entry = 0;
  int pf_cov_resp_miss_all = 0;
  int pf_cov_tlb_resp = 0;
  int pf_cov_fake_enq = 0;
  int pf_cov_merge_last_resp = 0;
  int pf_cov_merge_old = 0;
  int pf_cov_merge_port = 0;
  int pf_cov_flush = 0;
  int pf_cov_flush_kills_resp = 0;
  int pf_cov_hit_noS2 = 0;
  int pf_cov_hit_onlyS2 = 0;
  int pf_cov_hit_allS1 = 0;
  int pf_cov_hit_napot = 0;
  int pf_cov_hit_super = 0;
  int pf_cov_hit_g = 0;
  int pf_cov_getGpa = 0;
  logic [4:0] pf_armed = '0;
  int pf_armed_at = -1;
  PTWFilter pf_u_gold (
    .clock(clk),
    .reset(pf_reset),
    .io_sfence_valid(pf_io_sfence_valid),
    .io_csr_satp_asid(pf_io_csr_satp_asid),
    .io_csr_satp_changed(pf_io_csr_satp_changed),
    .io_csr_vsatp_asid(pf_io_csr_vsatp_asid),
    .io_csr_vsatp_changed(pf_io_csr_vsatp_changed),
    .io_csr_hgatp_vmid(pf_io_csr_hgatp_vmid),
    .io_csr_hgatp_changed(pf_io_csr_hgatp_changed),
    .io_csr_priv_virt_changed(pf_io_csr_priv_virt_changed),
    .io_tlb_req_0_ready(pf_g_io_tlb_req_0_ready),
    .io_tlb_req_0_valid(pf_io_tlb_req_0_valid),
    .io_tlb_req_0_bits_vpn(pf_io_tlb_req_0_bits_vpn),
    .io_tlb_req_0_bits_s2xlate(pf_io_tlb_req_0_bits_s2xlate),
    .io_tlb_req_0_bits_getGpa(pf_io_tlb_req_0_bits_getGpa),
    .io_tlb_req_1_ready(pf_g_io_tlb_req_1_ready),
    .io_tlb_req_1_valid(pf_io_tlb_req_1_valid),
    .io_tlb_req_1_bits_vpn(pf_io_tlb_req_1_bits_vpn),
    .io_tlb_req_1_bits_s2xlate(pf_io_tlb_req_1_bits_s2xlate),
    .io_tlb_req_1_bits_getGpa(pf_io_tlb_req_1_bits_getGpa),
    .io_tlb_req_2_ready(pf_g_io_tlb_req_2_ready),
    .io_tlb_req_2_valid(pf_io_tlb_req_2_valid),
    .io_tlb_req_2_bits_vpn(pf_io_tlb_req_2_bits_vpn),
    .io_tlb_req_2_bits_s2xlate(pf_io_tlb_req_2_bits_s2xlate),
    .io_tlb_req_2_bits_getGpa(pf_io_tlb_req_2_bits_getGpa),
    .io_tlb_resp_valid(pf_g_io_tlb_resp_valid),
    .io_tlb_resp_bits_data_s2xlate(pf_g_io_tlb_resp_bits_data_s2xlate),
    .io_tlb_resp_bits_data_s1_entry_tag(pf_g_io_tlb_resp_bits_data_s1_entry_tag),
    .io_tlb_resp_bits_data_s1_entry_asid(pf_g_io_tlb_resp_bits_data_s1_entry_asid),
    .io_tlb_resp_bits_data_s1_entry_vmid(pf_g_io_tlb_resp_bits_data_s1_entry_vmid),
    .io_tlb_resp_bits_data_s1_entry_n(pf_g_io_tlb_resp_bits_data_s1_entry_n),
    .io_tlb_resp_bits_data_s1_entry_pbmt(pf_g_io_tlb_resp_bits_data_s1_entry_pbmt),
    .io_tlb_resp_bits_data_s1_entry_perm_d(pf_g_io_tlb_resp_bits_data_s1_entry_perm_d),
    .io_tlb_resp_bits_data_s1_entry_perm_a(pf_g_io_tlb_resp_bits_data_s1_entry_perm_a),
    .io_tlb_resp_bits_data_s1_entry_perm_g(pf_g_io_tlb_resp_bits_data_s1_entry_perm_g),
    .io_tlb_resp_bits_data_s1_entry_perm_u(pf_g_io_tlb_resp_bits_data_s1_entry_perm_u),
    .io_tlb_resp_bits_data_s1_entry_perm_x(pf_g_io_tlb_resp_bits_data_s1_entry_perm_x),
    .io_tlb_resp_bits_data_s1_entry_perm_w(pf_g_io_tlb_resp_bits_data_s1_entry_perm_w),
    .io_tlb_resp_bits_data_s1_entry_perm_r(pf_g_io_tlb_resp_bits_data_s1_entry_perm_r),
    .io_tlb_resp_bits_data_s1_entry_level(pf_g_io_tlb_resp_bits_data_s1_entry_level),
    .io_tlb_resp_bits_data_s1_entry_v(pf_g_io_tlb_resp_bits_data_s1_entry_v),
    .io_tlb_resp_bits_data_s1_entry_ppn(pf_g_io_tlb_resp_bits_data_s1_entry_ppn),
    .io_tlb_resp_bits_data_s1_addr_low(pf_g_io_tlb_resp_bits_data_s1_addr_low),
    .io_tlb_resp_bits_data_s1_ppn_low_0(pf_g_io_tlb_resp_bits_data_s1_ppn_low_0),
    .io_tlb_resp_bits_data_s1_ppn_low_1(pf_g_io_tlb_resp_bits_data_s1_ppn_low_1),
    .io_tlb_resp_bits_data_s1_ppn_low_2(pf_g_io_tlb_resp_bits_data_s1_ppn_low_2),
    .io_tlb_resp_bits_data_s1_ppn_low_3(pf_g_io_tlb_resp_bits_data_s1_ppn_low_3),
    .io_tlb_resp_bits_data_s1_ppn_low_4(pf_g_io_tlb_resp_bits_data_s1_ppn_low_4),
    .io_tlb_resp_bits_data_s1_ppn_low_5(pf_g_io_tlb_resp_bits_data_s1_ppn_low_5),
    .io_tlb_resp_bits_data_s1_ppn_low_6(pf_g_io_tlb_resp_bits_data_s1_ppn_low_6),
    .io_tlb_resp_bits_data_s1_ppn_low_7(pf_g_io_tlb_resp_bits_data_s1_ppn_low_7),
    .io_tlb_resp_bits_data_s1_valididx_0(pf_g_io_tlb_resp_bits_data_s1_valididx_0),
    .io_tlb_resp_bits_data_s1_valididx_1(pf_g_io_tlb_resp_bits_data_s1_valididx_1),
    .io_tlb_resp_bits_data_s1_valididx_2(pf_g_io_tlb_resp_bits_data_s1_valididx_2),
    .io_tlb_resp_bits_data_s1_valididx_3(pf_g_io_tlb_resp_bits_data_s1_valididx_3),
    .io_tlb_resp_bits_data_s1_valididx_4(pf_g_io_tlb_resp_bits_data_s1_valididx_4),
    .io_tlb_resp_bits_data_s1_valididx_5(pf_g_io_tlb_resp_bits_data_s1_valididx_5),
    .io_tlb_resp_bits_data_s1_valididx_6(pf_g_io_tlb_resp_bits_data_s1_valididx_6),
    .io_tlb_resp_bits_data_s1_valididx_7(pf_g_io_tlb_resp_bits_data_s1_valididx_7),
    .io_tlb_resp_bits_data_s1_pteidx_0(pf_g_io_tlb_resp_bits_data_s1_pteidx_0),
    .io_tlb_resp_bits_data_s1_pteidx_1(pf_g_io_tlb_resp_bits_data_s1_pteidx_1),
    .io_tlb_resp_bits_data_s1_pteidx_2(pf_g_io_tlb_resp_bits_data_s1_pteidx_2),
    .io_tlb_resp_bits_data_s1_pteidx_3(pf_g_io_tlb_resp_bits_data_s1_pteidx_3),
    .io_tlb_resp_bits_data_s1_pteidx_4(pf_g_io_tlb_resp_bits_data_s1_pteidx_4),
    .io_tlb_resp_bits_data_s1_pteidx_5(pf_g_io_tlb_resp_bits_data_s1_pteidx_5),
    .io_tlb_resp_bits_data_s1_pteidx_6(pf_g_io_tlb_resp_bits_data_s1_pteidx_6),
    .io_tlb_resp_bits_data_s1_pteidx_7(pf_g_io_tlb_resp_bits_data_s1_pteidx_7),
    .io_tlb_resp_bits_data_s1_pf(pf_g_io_tlb_resp_bits_data_s1_pf),
    .io_tlb_resp_bits_data_s1_af(pf_g_io_tlb_resp_bits_data_s1_af),
    .io_tlb_resp_bits_data_s2_entry_tag(pf_g_io_tlb_resp_bits_data_s2_entry_tag),
    .io_tlb_resp_bits_data_s2_entry_vmid(pf_g_io_tlb_resp_bits_data_s2_entry_vmid),
    .io_tlb_resp_bits_data_s2_entry_n(pf_g_io_tlb_resp_bits_data_s2_entry_n),
    .io_tlb_resp_bits_data_s2_entry_pbmt(pf_g_io_tlb_resp_bits_data_s2_entry_pbmt),
    .io_tlb_resp_bits_data_s2_entry_ppn(pf_g_io_tlb_resp_bits_data_s2_entry_ppn),
    .io_tlb_resp_bits_data_s2_entry_perm_d(pf_g_io_tlb_resp_bits_data_s2_entry_perm_d),
    .io_tlb_resp_bits_data_s2_entry_perm_a(pf_g_io_tlb_resp_bits_data_s2_entry_perm_a),
    .io_tlb_resp_bits_data_s2_entry_perm_g(pf_g_io_tlb_resp_bits_data_s2_entry_perm_g),
    .io_tlb_resp_bits_data_s2_entry_perm_u(pf_g_io_tlb_resp_bits_data_s2_entry_perm_u),
    .io_tlb_resp_bits_data_s2_entry_perm_x(pf_g_io_tlb_resp_bits_data_s2_entry_perm_x),
    .io_tlb_resp_bits_data_s2_entry_perm_w(pf_g_io_tlb_resp_bits_data_s2_entry_perm_w),
    .io_tlb_resp_bits_data_s2_entry_perm_r(pf_g_io_tlb_resp_bits_data_s2_entry_perm_r),
    .io_tlb_resp_bits_data_s2_entry_level(pf_g_io_tlb_resp_bits_data_s2_entry_level),
    .io_tlb_resp_bits_data_s2_gpf(pf_g_io_tlb_resp_bits_data_s2_gpf),
    .io_tlb_resp_bits_data_s2_gaf(pf_g_io_tlb_resp_bits_data_s2_gaf),
    .io_tlb_resp_bits_data_getGpa(pf_g_io_tlb_resp_bits_data_getGpa),
    .io_ptw_req_0_ready(pf_io_ptw_req_0_ready),
    .io_ptw_req_0_valid(pf_g_io_ptw_req_0_valid),
    .io_ptw_req_0_bits_vpn(pf_g_io_ptw_req_0_bits_vpn),
    .io_ptw_req_0_bits_s2xlate(pf_g_io_ptw_req_0_bits_s2xlate),
    .io_ptw_resp_valid(pf_io_ptw_resp_valid),
    .io_ptw_resp_bits_s2xlate(pf_io_ptw_resp_bits_s2xlate),
    .io_ptw_resp_bits_s1_entry_tag(pf_io_ptw_resp_bits_s1_entry_tag),
    .io_ptw_resp_bits_s1_entry_asid(pf_io_ptw_resp_bits_s1_entry_asid),
    .io_ptw_resp_bits_s1_entry_vmid(pf_io_ptw_resp_bits_s1_entry_vmid),
    .io_ptw_resp_bits_s1_entry_n(pf_io_ptw_resp_bits_s1_entry_n),
    .io_ptw_resp_bits_s1_entry_pbmt(pf_io_ptw_resp_bits_s1_entry_pbmt),
    .io_ptw_resp_bits_s1_entry_perm_d(pf_io_ptw_resp_bits_s1_entry_perm_d),
    .io_ptw_resp_bits_s1_entry_perm_a(pf_io_ptw_resp_bits_s1_entry_perm_a),
    .io_ptw_resp_bits_s1_entry_perm_g(pf_io_ptw_resp_bits_s1_entry_perm_g),
    .io_ptw_resp_bits_s1_entry_perm_u(pf_io_ptw_resp_bits_s1_entry_perm_u),
    .io_ptw_resp_bits_s1_entry_perm_x(pf_io_ptw_resp_bits_s1_entry_perm_x),
    .io_ptw_resp_bits_s1_entry_perm_w(pf_io_ptw_resp_bits_s1_entry_perm_w),
    .io_ptw_resp_bits_s1_entry_perm_r(pf_io_ptw_resp_bits_s1_entry_perm_r),
    .io_ptw_resp_bits_s1_entry_level(pf_io_ptw_resp_bits_s1_entry_level),
    .io_ptw_resp_bits_s1_entry_v(pf_io_ptw_resp_bits_s1_entry_v),
    .io_ptw_resp_bits_s1_entry_ppn(pf_io_ptw_resp_bits_s1_entry_ppn),
    .io_ptw_resp_bits_s1_addr_low(pf_io_ptw_resp_bits_s1_addr_low),
    .io_ptw_resp_bits_s1_ppn_low_0(pf_io_ptw_resp_bits_s1_ppn_low_0),
    .io_ptw_resp_bits_s1_ppn_low_1(pf_io_ptw_resp_bits_s1_ppn_low_1),
    .io_ptw_resp_bits_s1_ppn_low_2(pf_io_ptw_resp_bits_s1_ppn_low_2),
    .io_ptw_resp_bits_s1_ppn_low_3(pf_io_ptw_resp_bits_s1_ppn_low_3),
    .io_ptw_resp_bits_s1_ppn_low_4(pf_io_ptw_resp_bits_s1_ppn_low_4),
    .io_ptw_resp_bits_s1_ppn_low_5(pf_io_ptw_resp_bits_s1_ppn_low_5),
    .io_ptw_resp_bits_s1_ppn_low_6(pf_io_ptw_resp_bits_s1_ppn_low_6),
    .io_ptw_resp_bits_s1_ppn_low_7(pf_io_ptw_resp_bits_s1_ppn_low_7),
    .io_ptw_resp_bits_s1_valididx_0(pf_io_ptw_resp_bits_s1_valididx_0),
    .io_ptw_resp_bits_s1_valididx_1(pf_io_ptw_resp_bits_s1_valididx_1),
    .io_ptw_resp_bits_s1_valididx_2(pf_io_ptw_resp_bits_s1_valididx_2),
    .io_ptw_resp_bits_s1_valididx_3(pf_io_ptw_resp_bits_s1_valididx_3),
    .io_ptw_resp_bits_s1_valididx_4(pf_io_ptw_resp_bits_s1_valididx_4),
    .io_ptw_resp_bits_s1_valididx_5(pf_io_ptw_resp_bits_s1_valididx_5),
    .io_ptw_resp_bits_s1_valididx_6(pf_io_ptw_resp_bits_s1_valididx_6),
    .io_ptw_resp_bits_s1_valididx_7(pf_io_ptw_resp_bits_s1_valididx_7),
    .io_ptw_resp_bits_s1_pteidx_0(pf_io_ptw_resp_bits_s1_pteidx_0),
    .io_ptw_resp_bits_s1_pteidx_1(pf_io_ptw_resp_bits_s1_pteidx_1),
    .io_ptw_resp_bits_s1_pteidx_2(pf_io_ptw_resp_bits_s1_pteidx_2),
    .io_ptw_resp_bits_s1_pteidx_3(pf_io_ptw_resp_bits_s1_pteidx_3),
    .io_ptw_resp_bits_s1_pteidx_4(pf_io_ptw_resp_bits_s1_pteidx_4),
    .io_ptw_resp_bits_s1_pteidx_5(pf_io_ptw_resp_bits_s1_pteidx_5),
    .io_ptw_resp_bits_s1_pteidx_6(pf_io_ptw_resp_bits_s1_pteidx_6),
    .io_ptw_resp_bits_s1_pteidx_7(pf_io_ptw_resp_bits_s1_pteidx_7),
    .io_ptw_resp_bits_s1_pf(pf_io_ptw_resp_bits_s1_pf),
    .io_ptw_resp_bits_s1_af(pf_io_ptw_resp_bits_s1_af),
    .io_ptw_resp_bits_s2_entry_tag(pf_io_ptw_resp_bits_s2_entry_tag),
    .io_ptw_resp_bits_s2_entry_vmid(pf_io_ptw_resp_bits_s2_entry_vmid),
    .io_ptw_resp_bits_s2_entry_n(pf_io_ptw_resp_bits_s2_entry_n),
    .io_ptw_resp_bits_s2_entry_pbmt(pf_io_ptw_resp_bits_s2_entry_pbmt),
    .io_ptw_resp_bits_s2_entry_ppn(pf_io_ptw_resp_bits_s2_entry_ppn),
    .io_ptw_resp_bits_s2_entry_perm_d(pf_io_ptw_resp_bits_s2_entry_perm_d),
    .io_ptw_resp_bits_s2_entry_perm_a(pf_io_ptw_resp_bits_s2_entry_perm_a),
    .io_ptw_resp_bits_s2_entry_perm_g(pf_io_ptw_resp_bits_s2_entry_perm_g),
    .io_ptw_resp_bits_s2_entry_perm_u(pf_io_ptw_resp_bits_s2_entry_perm_u),
    .io_ptw_resp_bits_s2_entry_perm_x(pf_io_ptw_resp_bits_s2_entry_perm_x),
    .io_ptw_resp_bits_s2_entry_perm_w(pf_io_ptw_resp_bits_s2_entry_perm_w),
    .io_ptw_resp_bits_s2_entry_perm_r(pf_io_ptw_resp_bits_s2_entry_perm_r),
    .io_ptw_resp_bits_s2_entry_level(pf_io_ptw_resp_bits_s2_entry_level),
    .io_ptw_resp_bits_s2_gpf(pf_io_ptw_resp_bits_s2_gpf),
    .io_ptw_resp_bits_s2_gaf(pf_io_ptw_resp_bits_s2_gaf)
  );
  PTWFilter_xs pf_u_impl (
    .clock(clk),
    .reset(pf_reset),
    .io_sfence_valid(pf_io_sfence_valid),
    .io_csr_satp_asid(pf_io_csr_satp_asid),
    .io_csr_satp_changed(pf_io_csr_satp_changed),
    .io_csr_vsatp_asid(pf_io_csr_vsatp_asid),
    .io_csr_vsatp_changed(pf_io_csr_vsatp_changed),
    .io_csr_hgatp_vmid(pf_io_csr_hgatp_vmid),
    .io_csr_hgatp_changed(pf_io_csr_hgatp_changed),
    .io_csr_priv_virt_changed(pf_io_csr_priv_virt_changed),
    .io_tlb_req_0_ready(pf_i_io_tlb_req_0_ready),
    .io_tlb_req_0_valid(pf_io_tlb_req_0_valid),
    .io_tlb_req_0_bits_vpn(pf_io_tlb_req_0_bits_vpn),
    .io_tlb_req_0_bits_s2xlate(pf_io_tlb_req_0_bits_s2xlate),
    .io_tlb_req_0_bits_getGpa(pf_io_tlb_req_0_bits_getGpa),
    .io_tlb_req_1_ready(pf_i_io_tlb_req_1_ready),
    .io_tlb_req_1_valid(pf_io_tlb_req_1_valid),
    .io_tlb_req_1_bits_vpn(pf_io_tlb_req_1_bits_vpn),
    .io_tlb_req_1_bits_s2xlate(pf_io_tlb_req_1_bits_s2xlate),
    .io_tlb_req_1_bits_getGpa(pf_io_tlb_req_1_bits_getGpa),
    .io_tlb_req_2_ready(pf_i_io_tlb_req_2_ready),
    .io_tlb_req_2_valid(pf_io_tlb_req_2_valid),
    .io_tlb_req_2_bits_vpn(pf_io_tlb_req_2_bits_vpn),
    .io_tlb_req_2_bits_s2xlate(pf_io_tlb_req_2_bits_s2xlate),
    .io_tlb_req_2_bits_getGpa(pf_io_tlb_req_2_bits_getGpa),
    .io_tlb_resp_valid(pf_i_io_tlb_resp_valid),
    .io_tlb_resp_bits_data_s2xlate(pf_i_io_tlb_resp_bits_data_s2xlate),
    .io_tlb_resp_bits_data_s1_entry_tag(pf_i_io_tlb_resp_bits_data_s1_entry_tag),
    .io_tlb_resp_bits_data_s1_entry_asid(pf_i_io_tlb_resp_bits_data_s1_entry_asid),
    .io_tlb_resp_bits_data_s1_entry_vmid(pf_i_io_tlb_resp_bits_data_s1_entry_vmid),
    .io_tlb_resp_bits_data_s1_entry_n(pf_i_io_tlb_resp_bits_data_s1_entry_n),
    .io_tlb_resp_bits_data_s1_entry_pbmt(pf_i_io_tlb_resp_bits_data_s1_entry_pbmt),
    .io_tlb_resp_bits_data_s1_entry_perm_d(pf_i_io_tlb_resp_bits_data_s1_entry_perm_d),
    .io_tlb_resp_bits_data_s1_entry_perm_a(pf_i_io_tlb_resp_bits_data_s1_entry_perm_a),
    .io_tlb_resp_bits_data_s1_entry_perm_g(pf_i_io_tlb_resp_bits_data_s1_entry_perm_g),
    .io_tlb_resp_bits_data_s1_entry_perm_u(pf_i_io_tlb_resp_bits_data_s1_entry_perm_u),
    .io_tlb_resp_bits_data_s1_entry_perm_x(pf_i_io_tlb_resp_bits_data_s1_entry_perm_x),
    .io_tlb_resp_bits_data_s1_entry_perm_w(pf_i_io_tlb_resp_bits_data_s1_entry_perm_w),
    .io_tlb_resp_bits_data_s1_entry_perm_r(pf_i_io_tlb_resp_bits_data_s1_entry_perm_r),
    .io_tlb_resp_bits_data_s1_entry_level(pf_i_io_tlb_resp_bits_data_s1_entry_level),
    .io_tlb_resp_bits_data_s1_entry_v(pf_i_io_tlb_resp_bits_data_s1_entry_v),
    .io_tlb_resp_bits_data_s1_entry_ppn(pf_i_io_tlb_resp_bits_data_s1_entry_ppn),
    .io_tlb_resp_bits_data_s1_addr_low(pf_i_io_tlb_resp_bits_data_s1_addr_low),
    .io_tlb_resp_bits_data_s1_ppn_low_0(pf_i_io_tlb_resp_bits_data_s1_ppn_low_0),
    .io_tlb_resp_bits_data_s1_ppn_low_1(pf_i_io_tlb_resp_bits_data_s1_ppn_low_1),
    .io_tlb_resp_bits_data_s1_ppn_low_2(pf_i_io_tlb_resp_bits_data_s1_ppn_low_2),
    .io_tlb_resp_bits_data_s1_ppn_low_3(pf_i_io_tlb_resp_bits_data_s1_ppn_low_3),
    .io_tlb_resp_bits_data_s1_ppn_low_4(pf_i_io_tlb_resp_bits_data_s1_ppn_low_4),
    .io_tlb_resp_bits_data_s1_ppn_low_5(pf_i_io_tlb_resp_bits_data_s1_ppn_low_5),
    .io_tlb_resp_bits_data_s1_ppn_low_6(pf_i_io_tlb_resp_bits_data_s1_ppn_low_6),
    .io_tlb_resp_bits_data_s1_ppn_low_7(pf_i_io_tlb_resp_bits_data_s1_ppn_low_7),
    .io_tlb_resp_bits_data_s1_valididx_0(pf_i_io_tlb_resp_bits_data_s1_valididx_0),
    .io_tlb_resp_bits_data_s1_valididx_1(pf_i_io_tlb_resp_bits_data_s1_valididx_1),
    .io_tlb_resp_bits_data_s1_valididx_2(pf_i_io_tlb_resp_bits_data_s1_valididx_2),
    .io_tlb_resp_bits_data_s1_valididx_3(pf_i_io_tlb_resp_bits_data_s1_valididx_3),
    .io_tlb_resp_bits_data_s1_valididx_4(pf_i_io_tlb_resp_bits_data_s1_valididx_4),
    .io_tlb_resp_bits_data_s1_valididx_5(pf_i_io_tlb_resp_bits_data_s1_valididx_5),
    .io_tlb_resp_bits_data_s1_valididx_6(pf_i_io_tlb_resp_bits_data_s1_valididx_6),
    .io_tlb_resp_bits_data_s1_valididx_7(pf_i_io_tlb_resp_bits_data_s1_valididx_7),
    .io_tlb_resp_bits_data_s1_pteidx_0(pf_i_io_tlb_resp_bits_data_s1_pteidx_0),
    .io_tlb_resp_bits_data_s1_pteidx_1(pf_i_io_tlb_resp_bits_data_s1_pteidx_1),
    .io_tlb_resp_bits_data_s1_pteidx_2(pf_i_io_tlb_resp_bits_data_s1_pteidx_2),
    .io_tlb_resp_bits_data_s1_pteidx_3(pf_i_io_tlb_resp_bits_data_s1_pteidx_3),
    .io_tlb_resp_bits_data_s1_pteidx_4(pf_i_io_tlb_resp_bits_data_s1_pteidx_4),
    .io_tlb_resp_bits_data_s1_pteidx_5(pf_i_io_tlb_resp_bits_data_s1_pteidx_5),
    .io_tlb_resp_bits_data_s1_pteidx_6(pf_i_io_tlb_resp_bits_data_s1_pteidx_6),
    .io_tlb_resp_bits_data_s1_pteidx_7(pf_i_io_tlb_resp_bits_data_s1_pteidx_7),
    .io_tlb_resp_bits_data_s1_pf(pf_i_io_tlb_resp_bits_data_s1_pf),
    .io_tlb_resp_bits_data_s1_af(pf_i_io_tlb_resp_bits_data_s1_af),
    .io_tlb_resp_bits_data_s2_entry_tag(pf_i_io_tlb_resp_bits_data_s2_entry_tag),
    .io_tlb_resp_bits_data_s2_entry_vmid(pf_i_io_tlb_resp_bits_data_s2_entry_vmid),
    .io_tlb_resp_bits_data_s2_entry_n(pf_i_io_tlb_resp_bits_data_s2_entry_n),
    .io_tlb_resp_bits_data_s2_entry_pbmt(pf_i_io_tlb_resp_bits_data_s2_entry_pbmt),
    .io_tlb_resp_bits_data_s2_entry_ppn(pf_i_io_tlb_resp_bits_data_s2_entry_ppn),
    .io_tlb_resp_bits_data_s2_entry_perm_d(pf_i_io_tlb_resp_bits_data_s2_entry_perm_d),
    .io_tlb_resp_bits_data_s2_entry_perm_a(pf_i_io_tlb_resp_bits_data_s2_entry_perm_a),
    .io_tlb_resp_bits_data_s2_entry_perm_g(pf_i_io_tlb_resp_bits_data_s2_entry_perm_g),
    .io_tlb_resp_bits_data_s2_entry_perm_u(pf_i_io_tlb_resp_bits_data_s2_entry_perm_u),
    .io_tlb_resp_bits_data_s2_entry_perm_x(pf_i_io_tlb_resp_bits_data_s2_entry_perm_x),
    .io_tlb_resp_bits_data_s2_entry_perm_w(pf_i_io_tlb_resp_bits_data_s2_entry_perm_w),
    .io_tlb_resp_bits_data_s2_entry_perm_r(pf_i_io_tlb_resp_bits_data_s2_entry_perm_r),
    .io_tlb_resp_bits_data_s2_entry_level(pf_i_io_tlb_resp_bits_data_s2_entry_level),
    .io_tlb_resp_bits_data_s2_gpf(pf_i_io_tlb_resp_bits_data_s2_gpf),
    .io_tlb_resp_bits_data_s2_gaf(pf_i_io_tlb_resp_bits_data_s2_gaf),
    .io_tlb_resp_bits_data_getGpa(pf_i_io_tlb_resp_bits_data_getGpa),
    .io_ptw_req_0_ready(pf_io_ptw_req_0_ready),
    .io_ptw_req_0_valid(pf_i_io_ptw_req_0_valid),
    .io_ptw_req_0_bits_vpn(pf_i_io_ptw_req_0_bits_vpn),
    .io_ptw_req_0_bits_s2xlate(pf_i_io_ptw_req_0_bits_s2xlate),
    .io_ptw_resp_valid(pf_io_ptw_resp_valid),
    .io_ptw_resp_bits_s2xlate(pf_io_ptw_resp_bits_s2xlate),
    .io_ptw_resp_bits_s1_entry_tag(pf_io_ptw_resp_bits_s1_entry_tag),
    .io_ptw_resp_bits_s1_entry_asid(pf_io_ptw_resp_bits_s1_entry_asid),
    .io_ptw_resp_bits_s1_entry_vmid(pf_io_ptw_resp_bits_s1_entry_vmid),
    .io_ptw_resp_bits_s1_entry_n(pf_io_ptw_resp_bits_s1_entry_n),
    .io_ptw_resp_bits_s1_entry_pbmt(pf_io_ptw_resp_bits_s1_entry_pbmt),
    .io_ptw_resp_bits_s1_entry_perm_d(pf_io_ptw_resp_bits_s1_entry_perm_d),
    .io_ptw_resp_bits_s1_entry_perm_a(pf_io_ptw_resp_bits_s1_entry_perm_a),
    .io_ptw_resp_bits_s1_entry_perm_g(pf_io_ptw_resp_bits_s1_entry_perm_g),
    .io_ptw_resp_bits_s1_entry_perm_u(pf_io_ptw_resp_bits_s1_entry_perm_u),
    .io_ptw_resp_bits_s1_entry_perm_x(pf_io_ptw_resp_bits_s1_entry_perm_x),
    .io_ptw_resp_bits_s1_entry_perm_w(pf_io_ptw_resp_bits_s1_entry_perm_w),
    .io_ptw_resp_bits_s1_entry_perm_r(pf_io_ptw_resp_bits_s1_entry_perm_r),
    .io_ptw_resp_bits_s1_entry_level(pf_io_ptw_resp_bits_s1_entry_level),
    .io_ptw_resp_bits_s1_entry_v(pf_io_ptw_resp_bits_s1_entry_v),
    .io_ptw_resp_bits_s1_entry_ppn(pf_io_ptw_resp_bits_s1_entry_ppn),
    .io_ptw_resp_bits_s1_addr_low(pf_io_ptw_resp_bits_s1_addr_low),
    .io_ptw_resp_bits_s1_ppn_low_0(pf_io_ptw_resp_bits_s1_ppn_low_0),
    .io_ptw_resp_bits_s1_ppn_low_1(pf_io_ptw_resp_bits_s1_ppn_low_1),
    .io_ptw_resp_bits_s1_ppn_low_2(pf_io_ptw_resp_bits_s1_ppn_low_2),
    .io_ptw_resp_bits_s1_ppn_low_3(pf_io_ptw_resp_bits_s1_ppn_low_3),
    .io_ptw_resp_bits_s1_ppn_low_4(pf_io_ptw_resp_bits_s1_ppn_low_4),
    .io_ptw_resp_bits_s1_ppn_low_5(pf_io_ptw_resp_bits_s1_ppn_low_5),
    .io_ptw_resp_bits_s1_ppn_low_6(pf_io_ptw_resp_bits_s1_ppn_low_6),
    .io_ptw_resp_bits_s1_ppn_low_7(pf_io_ptw_resp_bits_s1_ppn_low_7),
    .io_ptw_resp_bits_s1_valididx_0(pf_io_ptw_resp_bits_s1_valididx_0),
    .io_ptw_resp_bits_s1_valididx_1(pf_io_ptw_resp_bits_s1_valididx_1),
    .io_ptw_resp_bits_s1_valididx_2(pf_io_ptw_resp_bits_s1_valididx_2),
    .io_ptw_resp_bits_s1_valididx_3(pf_io_ptw_resp_bits_s1_valididx_3),
    .io_ptw_resp_bits_s1_valididx_4(pf_io_ptw_resp_bits_s1_valididx_4),
    .io_ptw_resp_bits_s1_valididx_5(pf_io_ptw_resp_bits_s1_valididx_5),
    .io_ptw_resp_bits_s1_valididx_6(pf_io_ptw_resp_bits_s1_valididx_6),
    .io_ptw_resp_bits_s1_valididx_7(pf_io_ptw_resp_bits_s1_valididx_7),
    .io_ptw_resp_bits_s1_pteidx_0(pf_io_ptw_resp_bits_s1_pteidx_0),
    .io_ptw_resp_bits_s1_pteidx_1(pf_io_ptw_resp_bits_s1_pteidx_1),
    .io_ptw_resp_bits_s1_pteidx_2(pf_io_ptw_resp_bits_s1_pteidx_2),
    .io_ptw_resp_bits_s1_pteidx_3(pf_io_ptw_resp_bits_s1_pteidx_3),
    .io_ptw_resp_bits_s1_pteidx_4(pf_io_ptw_resp_bits_s1_pteidx_4),
    .io_ptw_resp_bits_s1_pteidx_5(pf_io_ptw_resp_bits_s1_pteidx_5),
    .io_ptw_resp_bits_s1_pteidx_6(pf_io_ptw_resp_bits_s1_pteidx_6),
    .io_ptw_resp_bits_s1_pteidx_7(pf_io_ptw_resp_bits_s1_pteidx_7),
    .io_ptw_resp_bits_s1_pf(pf_io_ptw_resp_bits_s1_pf),
    .io_ptw_resp_bits_s1_af(pf_io_ptw_resp_bits_s1_af),
    .io_ptw_resp_bits_s2_entry_tag(pf_io_ptw_resp_bits_s2_entry_tag),
    .io_ptw_resp_bits_s2_entry_vmid(pf_io_ptw_resp_bits_s2_entry_vmid),
    .io_ptw_resp_bits_s2_entry_n(pf_io_ptw_resp_bits_s2_entry_n),
    .io_ptw_resp_bits_s2_entry_pbmt(pf_io_ptw_resp_bits_s2_entry_pbmt),
    .io_ptw_resp_bits_s2_entry_ppn(pf_io_ptw_resp_bits_s2_entry_ppn),
    .io_ptw_resp_bits_s2_entry_perm_d(pf_io_ptw_resp_bits_s2_entry_perm_d),
    .io_ptw_resp_bits_s2_entry_perm_a(pf_io_ptw_resp_bits_s2_entry_perm_a),
    .io_ptw_resp_bits_s2_entry_perm_g(pf_io_ptw_resp_bits_s2_entry_perm_g),
    .io_ptw_resp_bits_s2_entry_perm_u(pf_io_ptw_resp_bits_s2_entry_perm_u),
    .io_ptw_resp_bits_s2_entry_perm_x(pf_io_ptw_resp_bits_s2_entry_perm_x),
    .io_ptw_resp_bits_s2_entry_perm_w(pf_io_ptw_resp_bits_s2_entry_perm_w),
    .io_ptw_resp_bits_s2_entry_perm_r(pf_io_ptw_resp_bits_s2_entry_perm_r),
    .io_ptw_resp_bits_s2_entry_level(pf_io_ptw_resp_bits_s2_entry_level),
    .io_ptw_resp_bits_s2_gpf(pf_io_ptw_resp_bits_s2_gpf),
    .io_ptw_resp_bits_s2_gaf(pf_io_ptw_resp_bits_s2_gaf)
  );

  initial begin
    if ($value$plusargs("ncycles=%d", NCYCLES)) ;
    for (cyc = 0; cyc < NCYCLES; cyc++) begin
      @(negedge clk);
      if (cyc % 1000 == 0) pf_mode = $urandom_range(0, 15);
      pf_io_sfence_valid = 1'($urandom);
      pf_io_csr_satp_asid = 16'($urandom);
      pf_io_csr_satp_changed = 1'($urandom);
      pf_io_csr_vsatp_asid = 16'($urandom);
      pf_io_csr_vsatp_changed = 1'($urandom);
      pf_io_csr_hgatp_vmid = 16'($urandom);
      pf_io_csr_hgatp_changed = 1'($urandom);
      pf_io_csr_priv_virt_changed = 1'($urandom);
      pf_io_tlb_req_0_valid = 1'($urandom);
      pf_io_tlb_req_0_bits_vpn = 38'({$urandom, $urandom});
      pf_io_tlb_req_0_bits_s2xlate = 2'($urandom);
      pf_io_tlb_req_0_bits_getGpa = 1'($urandom);
      pf_io_tlb_req_1_valid = 1'($urandom);
      pf_io_tlb_req_1_bits_vpn = 38'({$urandom, $urandom});
      pf_io_tlb_req_1_bits_s2xlate = 2'($urandom);
      pf_io_tlb_req_1_bits_getGpa = 1'($urandom);
      pf_io_tlb_req_2_valid = 1'($urandom);
      pf_io_tlb_req_2_bits_vpn = 38'({$urandom, $urandom});
      pf_io_tlb_req_2_bits_s2xlate = 2'($urandom);
      pf_io_tlb_req_2_bits_getGpa = 1'($urandom);
      pf_io_ptw_req_0_ready = 1'($urandom);
      pf_io_ptw_resp_valid = 1'($urandom);
      pf_io_ptw_resp_bits_s2xlate = 2'($urandom);
      pf_io_ptw_resp_bits_s1_entry_tag = 35'({$urandom, $urandom});
      pf_io_ptw_resp_bits_s1_entry_asid = 16'($urandom);
      pf_io_ptw_resp_bits_s1_entry_vmid = 14'($urandom);
      pf_io_ptw_resp_bits_s1_entry_n = 1'($urandom);
      pf_io_ptw_resp_bits_s1_entry_pbmt = 2'($urandom);
      pf_io_ptw_resp_bits_s1_entry_perm_d = 1'($urandom);
      pf_io_ptw_resp_bits_s1_entry_perm_a = 1'($urandom);
      pf_io_ptw_resp_bits_s1_entry_perm_g = 1'($urandom);
      pf_io_ptw_resp_bits_s1_entry_perm_u = 1'($urandom);
      pf_io_ptw_resp_bits_s1_entry_perm_x = 1'($urandom);
      pf_io_ptw_resp_bits_s1_entry_perm_w = 1'($urandom);
      pf_io_ptw_resp_bits_s1_entry_perm_r = 1'($urandom);
      pf_io_ptw_resp_bits_s1_entry_level = 2'($urandom);
      pf_io_ptw_resp_bits_s1_entry_v = 1'($urandom);
      pf_io_ptw_resp_bits_s1_entry_ppn = 41'({$urandom, $urandom});
      pf_io_ptw_resp_bits_s1_addr_low = 3'($urandom);
      pf_io_ptw_resp_bits_s1_ppn_low_0 = 3'($urandom);
      pf_io_ptw_resp_bits_s1_ppn_low_1 = 3'($urandom);
      pf_io_ptw_resp_bits_s1_ppn_low_2 = 3'($urandom);
      pf_io_ptw_resp_bits_s1_ppn_low_3 = 3'($urandom);
      pf_io_ptw_resp_bits_s1_ppn_low_4 = 3'($urandom);
      pf_io_ptw_resp_bits_s1_ppn_low_5 = 3'($urandom);
      pf_io_ptw_resp_bits_s1_ppn_low_6 = 3'($urandom);
      pf_io_ptw_resp_bits_s1_ppn_low_7 = 3'($urandom);
      pf_io_ptw_resp_bits_s1_valididx_0 = 1'($urandom);
      pf_io_ptw_resp_bits_s1_valididx_1 = 1'($urandom);
      pf_io_ptw_resp_bits_s1_valididx_2 = 1'($urandom);
      pf_io_ptw_resp_bits_s1_valididx_3 = 1'($urandom);
      pf_io_ptw_resp_bits_s1_valididx_4 = 1'($urandom);
      pf_io_ptw_resp_bits_s1_valididx_5 = 1'($urandom);
      pf_io_ptw_resp_bits_s1_valididx_6 = 1'($urandom);
      pf_io_ptw_resp_bits_s1_valididx_7 = 1'($urandom);
      pf_io_ptw_resp_bits_s1_pteidx_0 = 1'($urandom);
      pf_io_ptw_resp_bits_s1_pteidx_1 = 1'($urandom);
      pf_io_ptw_resp_bits_s1_pteidx_2 = 1'($urandom);
      pf_io_ptw_resp_bits_s1_pteidx_3 = 1'($urandom);
      pf_io_ptw_resp_bits_s1_pteidx_4 = 1'($urandom);
      pf_io_ptw_resp_bits_s1_pteidx_5 = 1'($urandom);
      pf_io_ptw_resp_bits_s1_pteidx_6 = 1'($urandom);
      pf_io_ptw_resp_bits_s1_pteidx_7 = 1'($urandom);
      pf_io_ptw_resp_bits_s1_pf = 1'($urandom);
      pf_io_ptw_resp_bits_s1_af = 1'($urandom);
      pf_io_ptw_resp_bits_s2_entry_tag = 38'({$urandom, $urandom});
      pf_io_ptw_resp_bits_s2_entry_vmid = 14'($urandom);
      pf_io_ptw_resp_bits_s2_entry_n = 1'($urandom);
      pf_io_ptw_resp_bits_s2_entry_pbmt = 2'($urandom);
      pf_io_ptw_resp_bits_s2_entry_ppn = 38'({$urandom, $urandom});
      pf_io_ptw_resp_bits_s2_entry_perm_d = 1'($urandom);
      pf_io_ptw_resp_bits_s2_entry_perm_a = 1'($urandom);
      pf_io_ptw_resp_bits_s2_entry_perm_g = 1'($urandom);
      pf_io_ptw_resp_bits_s2_entry_perm_u = 1'($urandom);
      pf_io_ptw_resp_bits_s2_entry_perm_x = 1'($urandom);
      pf_io_ptw_resp_bits_s2_entry_perm_w = 1'($urandom);
      pf_io_ptw_resp_bits_s2_entry_perm_r = 1'($urandom);
      pf_io_ptw_resp_bits_s2_entry_level = 2'($urandom);
      pf_io_ptw_resp_bits_s2_gpf = 1'($urandom);
      pf_io_ptw_resp_bits_s2_gaf = 1'($urandom);
      pf_reset = (cyc < RESET_CYC) || ($urandom_range(0, 49999) == 0);
      begin : stim_pf
        if (cyc % 1000 == 0) begin
          pf_pool[0] = 38'({$urandom, $urandom});
          for (int k = 1; k < 8; k++) pf_pool[k] = (pf_mode % 3 == 0) ? {pf_pool[0][37:3], 3'($urandom)}
                                                  : (pf_mode % 3 == 1) ? {pf_pool[0][37:9], 9'($urandom)} : 38'({$urandom, $urandom});
        end
        if (pf_u_gold.do_enq) pf_enq_total += pf_u_gold._enqNum_T_2;
        pf_vpns = {pf_u_gold.vpn_7, pf_u_gold.vpn_6, pf_u_gold.vpn_5, pf_u_gold.vpn_4, pf_u_gold.vpn_3, pf_u_gold.vpn_2, pf_u_gold.vpn_1, pf_u_gold.vpn_0};
        pf_s2xs = {pf_u_gold.s2xlate_7, pf_u_gold.s2xlate_6, pf_u_gold.s2xlate_5, pf_u_gold.s2xlate_4, pf_u_gold.s2xlate_3, pf_u_gold.s2xlate_2, pf_u_gold.s2xlate_1, pf_u_gold.s2xlate_0};
        if ($urandom_range(0, 63) != 0) pf_io_csr_satp_asid = 16'h12;
        if ($urandom_range(0, 63) != 0) pf_io_csr_vsatp_asid = 16'h34;
        if ($urandom_range(0, 63) != 0) pf_io_csr_hgatp_vmid = 16'h5;
        pf_io_sfence_valid = ($urandom_range(0, 499) == 0);
        pf_io_csr_satp_changed = ($urandom_range(0, 499) == 0);
        pf_io_csr_vsatp_changed = ($urandom_range(0, 499) == 0);
        pf_io_csr_hgatp_changed = ($urandom_range(0, 499) == 0);
        pf_io_csr_priv_virt_changed = ($urandom_range(0, 499) == 0);
        pf_io_tlb_req_0_valid = (pf_mode % 8 == 7) ? 1'($urandom) : ($urandom_range(0, 15) == 0);
        if ($urandom_range(0, 3) != 0) pf_io_tlb_req_0_bits_vpn = pf_pool[$urandom_range(0, 7)];
        pf_io_tlb_req_0_bits_s2xlate = pf_s2x(pf_mode);
        pf_io_tlb_req_1_valid = (pf_mode % 8 == 7) ? 1'($urandom) : ($urandom_range(0, 15) == 0);
        if ($urandom_range(0, 3) != 0) pf_io_tlb_req_1_bits_vpn = pf_pool[$urandom_range(0, 7)];
        pf_io_tlb_req_1_bits_s2xlate = pf_s2x(pf_mode);
        pf_io_tlb_req_2_valid = (pf_mode % 8 == 7) ? 1'($urandom) : ($urandom_range(0, 15) == 0);
        if ($urandom_range(0, 3) != 0) pf_io_tlb_req_2_bits_vpn = pf_pool[$urandom_range(0, 7)];
        pf_io_tlb_req_2_bits_s2xlate = pf_s2x(pf_mode);
        pf_io_ptw_req_0_ready = ($urandom_range(0, 7) != 0);
        pf_io_ptw_resp_valid = (pf_mode % 8 == 6) ? ($urandom_range(0, 15) == 0) : 1'($urandom);
        if ($urandom_range(0, 3) == 0) begin pf_tvpn = pf_pool[$urandom_range(0, 7)]; pf_ts2x = pf_s2x(pf_mode); end
        else begin pf_tvpn = pf_vpns[$urandom_range(0, 7)]; pf_ts2x = pf_s2xs[$urandom_range(0, 7)]; end
        if ($urandom_range(0, 7) != 0) begin
          pf_io_ptw_resp_bits_s2xlate = pf_ts2x;
          pf_io_ptw_resp_bits_s1_entry_tag = pf_tvpn[37:3];
          pf_io_ptw_resp_bits_s1_addr_low = pf_tvpn[2:0];
          pf_io_ptw_resp_bits_s2_entry_tag = pf_tvpn;
        end
        if ($urandom_range(0, 7) != 0) pf_io_ptw_resp_bits_s1_entry_asid = (pf_ts2x == 2'd0) ? pf_io_csr_satp_asid : pf_io_csr_vsatp_asid;
        if ($urandom_range(0, 7) != 0) pf_io_ptw_resp_bits_s1_entry_vmid = pf_io_csr_hgatp_vmid[13:0];
        if ($urandom_range(0, 7) != 0) pf_io_ptw_resp_bits_s2_entry_vmid = pf_io_csr_hgatp_vmid[13:0];
        if ($urandom_range(0, 1)) pf_io_ptw_resp_bits_s1_entry_level = 2'd0;
        if ($urandom_range(0, 1)) pf_io_ptw_resp_bits_s2_entry_level = 2'd0;
        pf_io_ptw_resp_bits_s1_entry_n = ($urandom_range(0, 7) == 0);
        pf_io_ptw_resp_bits_s2_entry_n = ($urandom_range(0, 7) == 0);
        pf_io_ptw_resp_bits_s1_entry_perm_g = ($urandom_range(0, 3) == 0);
        if ($urandom_range(0, 7) != 0) pf_io_ptw_resp_bits_s1_valididx_0 = 1'b1;
      end
      #4;
      if (cyc >= RESET_CYC + 0 && pf_armed_at >= 0 && cyc >= pf_armed_at) begin
        checks++;
        if (pf_g_io_tlb_req_0_ready !== pf_i_io_tlb_req_0_ready) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d PTWFilter.io_tlb_req_0_ready g=%h i=%h", cyc, pf_g_io_tlb_req_0_ready, pf_i_io_tlb_req_0_ready);
        end
        pf_s1_io_tlb_req_0_ready |= pf_g_io_tlb_req_0_ready;
        pf_s0_io_tlb_req_0_ready |= ~pf_g_io_tlb_req_0_ready;
        checks++;
        if (pf_g_io_tlb_req_1_ready !== pf_i_io_tlb_req_1_ready) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d PTWFilter.io_tlb_req_1_ready g=%h i=%h", cyc, pf_g_io_tlb_req_1_ready, pf_i_io_tlb_req_1_ready);
        end
        pf_s1_io_tlb_req_1_ready |= pf_g_io_tlb_req_1_ready;
        pf_s0_io_tlb_req_1_ready |= ~pf_g_io_tlb_req_1_ready;
        checks++;
        if (pf_g_io_tlb_req_2_ready !== pf_i_io_tlb_req_2_ready) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d PTWFilter.io_tlb_req_2_ready g=%h i=%h", cyc, pf_g_io_tlb_req_2_ready, pf_i_io_tlb_req_2_ready);
        end
        pf_s1_io_tlb_req_2_ready |= pf_g_io_tlb_req_2_ready;
        pf_s0_io_tlb_req_2_ready |= ~pf_g_io_tlb_req_2_ready;
        checks++;
        if (pf_g_io_tlb_resp_valid !== pf_i_io_tlb_resp_valid) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d PTWFilter.io_tlb_resp_valid g=%h i=%h", cyc, pf_g_io_tlb_resp_valid, pf_i_io_tlb_resp_valid);
        end
        pf_s1_io_tlb_resp_valid |= pf_g_io_tlb_resp_valid;
        pf_s0_io_tlb_resp_valid |= ~pf_g_io_tlb_resp_valid;
        checks++;
        if (pf_g_io_tlb_resp_bits_data_s2xlate !== pf_i_io_tlb_resp_bits_data_s2xlate) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d PTWFilter.io_tlb_resp_bits_data_s2xlate g=%h i=%h", cyc, pf_g_io_tlb_resp_bits_data_s2xlate, pf_i_io_tlb_resp_bits_data_s2xlate);
        end
        pf_s1_io_tlb_resp_bits_data_s2xlate |= pf_g_io_tlb_resp_bits_data_s2xlate;
        pf_s0_io_tlb_resp_bits_data_s2xlate |= ~pf_g_io_tlb_resp_bits_data_s2xlate;
        checks++;
        if (pf_g_io_tlb_resp_bits_data_s1_entry_tag !== pf_i_io_tlb_resp_bits_data_s1_entry_tag) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d PTWFilter.io_tlb_resp_bits_data_s1_entry_tag g=%h i=%h", cyc, pf_g_io_tlb_resp_bits_data_s1_entry_tag, pf_i_io_tlb_resp_bits_data_s1_entry_tag);
        end
        pf_s1_io_tlb_resp_bits_data_s1_entry_tag |= pf_g_io_tlb_resp_bits_data_s1_entry_tag;
        pf_s0_io_tlb_resp_bits_data_s1_entry_tag |= ~pf_g_io_tlb_resp_bits_data_s1_entry_tag;
        checks++;
        if (pf_g_io_tlb_resp_bits_data_s1_entry_asid !== pf_i_io_tlb_resp_bits_data_s1_entry_asid) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d PTWFilter.io_tlb_resp_bits_data_s1_entry_asid g=%h i=%h", cyc, pf_g_io_tlb_resp_bits_data_s1_entry_asid, pf_i_io_tlb_resp_bits_data_s1_entry_asid);
        end
        pf_s1_io_tlb_resp_bits_data_s1_entry_asid |= pf_g_io_tlb_resp_bits_data_s1_entry_asid;
        pf_s0_io_tlb_resp_bits_data_s1_entry_asid |= ~pf_g_io_tlb_resp_bits_data_s1_entry_asid;
        checks++;
        if (pf_g_io_tlb_resp_bits_data_s1_entry_vmid !== pf_i_io_tlb_resp_bits_data_s1_entry_vmid) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d PTWFilter.io_tlb_resp_bits_data_s1_entry_vmid g=%h i=%h", cyc, pf_g_io_tlb_resp_bits_data_s1_entry_vmid, pf_i_io_tlb_resp_bits_data_s1_entry_vmid);
        end
        pf_s1_io_tlb_resp_bits_data_s1_entry_vmid |= pf_g_io_tlb_resp_bits_data_s1_entry_vmid;
        pf_s0_io_tlb_resp_bits_data_s1_entry_vmid |= ~pf_g_io_tlb_resp_bits_data_s1_entry_vmid;
        checks++;
        if (pf_g_io_tlb_resp_bits_data_s1_entry_n !== pf_i_io_tlb_resp_bits_data_s1_entry_n) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d PTWFilter.io_tlb_resp_bits_data_s1_entry_n g=%h i=%h", cyc, pf_g_io_tlb_resp_bits_data_s1_entry_n, pf_i_io_tlb_resp_bits_data_s1_entry_n);
        end
        pf_s1_io_tlb_resp_bits_data_s1_entry_n |= pf_g_io_tlb_resp_bits_data_s1_entry_n;
        pf_s0_io_tlb_resp_bits_data_s1_entry_n |= ~pf_g_io_tlb_resp_bits_data_s1_entry_n;
        checks++;
        if (pf_g_io_tlb_resp_bits_data_s1_entry_pbmt !== pf_i_io_tlb_resp_bits_data_s1_entry_pbmt) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d PTWFilter.io_tlb_resp_bits_data_s1_entry_pbmt g=%h i=%h", cyc, pf_g_io_tlb_resp_bits_data_s1_entry_pbmt, pf_i_io_tlb_resp_bits_data_s1_entry_pbmt);
        end
        pf_s1_io_tlb_resp_bits_data_s1_entry_pbmt |= pf_g_io_tlb_resp_bits_data_s1_entry_pbmt;
        pf_s0_io_tlb_resp_bits_data_s1_entry_pbmt |= ~pf_g_io_tlb_resp_bits_data_s1_entry_pbmt;
        checks++;
        if (pf_g_io_tlb_resp_bits_data_s1_entry_perm_d !== pf_i_io_tlb_resp_bits_data_s1_entry_perm_d) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d PTWFilter.io_tlb_resp_bits_data_s1_entry_perm_d g=%h i=%h", cyc, pf_g_io_tlb_resp_bits_data_s1_entry_perm_d, pf_i_io_tlb_resp_bits_data_s1_entry_perm_d);
        end
        pf_s1_io_tlb_resp_bits_data_s1_entry_perm_d |= pf_g_io_tlb_resp_bits_data_s1_entry_perm_d;
        pf_s0_io_tlb_resp_bits_data_s1_entry_perm_d |= ~pf_g_io_tlb_resp_bits_data_s1_entry_perm_d;
        checks++;
        if (pf_g_io_tlb_resp_bits_data_s1_entry_perm_a !== pf_i_io_tlb_resp_bits_data_s1_entry_perm_a) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d PTWFilter.io_tlb_resp_bits_data_s1_entry_perm_a g=%h i=%h", cyc, pf_g_io_tlb_resp_bits_data_s1_entry_perm_a, pf_i_io_tlb_resp_bits_data_s1_entry_perm_a);
        end
        pf_s1_io_tlb_resp_bits_data_s1_entry_perm_a |= pf_g_io_tlb_resp_bits_data_s1_entry_perm_a;
        pf_s0_io_tlb_resp_bits_data_s1_entry_perm_a |= ~pf_g_io_tlb_resp_bits_data_s1_entry_perm_a;
        checks++;
        if (pf_g_io_tlb_resp_bits_data_s1_entry_perm_g !== pf_i_io_tlb_resp_bits_data_s1_entry_perm_g) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d PTWFilter.io_tlb_resp_bits_data_s1_entry_perm_g g=%h i=%h", cyc, pf_g_io_tlb_resp_bits_data_s1_entry_perm_g, pf_i_io_tlb_resp_bits_data_s1_entry_perm_g);
        end
        pf_s1_io_tlb_resp_bits_data_s1_entry_perm_g |= pf_g_io_tlb_resp_bits_data_s1_entry_perm_g;
        pf_s0_io_tlb_resp_bits_data_s1_entry_perm_g |= ~pf_g_io_tlb_resp_bits_data_s1_entry_perm_g;
        checks++;
        if (pf_g_io_tlb_resp_bits_data_s1_entry_perm_u !== pf_i_io_tlb_resp_bits_data_s1_entry_perm_u) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d PTWFilter.io_tlb_resp_bits_data_s1_entry_perm_u g=%h i=%h", cyc, pf_g_io_tlb_resp_bits_data_s1_entry_perm_u, pf_i_io_tlb_resp_bits_data_s1_entry_perm_u);
        end
        pf_s1_io_tlb_resp_bits_data_s1_entry_perm_u |= pf_g_io_tlb_resp_bits_data_s1_entry_perm_u;
        pf_s0_io_tlb_resp_bits_data_s1_entry_perm_u |= ~pf_g_io_tlb_resp_bits_data_s1_entry_perm_u;
        checks++;
        if (pf_g_io_tlb_resp_bits_data_s1_entry_perm_x !== pf_i_io_tlb_resp_bits_data_s1_entry_perm_x) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d PTWFilter.io_tlb_resp_bits_data_s1_entry_perm_x g=%h i=%h", cyc, pf_g_io_tlb_resp_bits_data_s1_entry_perm_x, pf_i_io_tlb_resp_bits_data_s1_entry_perm_x);
        end
        pf_s1_io_tlb_resp_bits_data_s1_entry_perm_x |= pf_g_io_tlb_resp_bits_data_s1_entry_perm_x;
        pf_s0_io_tlb_resp_bits_data_s1_entry_perm_x |= ~pf_g_io_tlb_resp_bits_data_s1_entry_perm_x;
        checks++;
        if (pf_g_io_tlb_resp_bits_data_s1_entry_perm_w !== pf_i_io_tlb_resp_bits_data_s1_entry_perm_w) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d PTWFilter.io_tlb_resp_bits_data_s1_entry_perm_w g=%h i=%h", cyc, pf_g_io_tlb_resp_bits_data_s1_entry_perm_w, pf_i_io_tlb_resp_bits_data_s1_entry_perm_w);
        end
        pf_s1_io_tlb_resp_bits_data_s1_entry_perm_w |= pf_g_io_tlb_resp_bits_data_s1_entry_perm_w;
        pf_s0_io_tlb_resp_bits_data_s1_entry_perm_w |= ~pf_g_io_tlb_resp_bits_data_s1_entry_perm_w;
        checks++;
        if (pf_g_io_tlb_resp_bits_data_s1_entry_perm_r !== pf_i_io_tlb_resp_bits_data_s1_entry_perm_r) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d PTWFilter.io_tlb_resp_bits_data_s1_entry_perm_r g=%h i=%h", cyc, pf_g_io_tlb_resp_bits_data_s1_entry_perm_r, pf_i_io_tlb_resp_bits_data_s1_entry_perm_r);
        end
        pf_s1_io_tlb_resp_bits_data_s1_entry_perm_r |= pf_g_io_tlb_resp_bits_data_s1_entry_perm_r;
        pf_s0_io_tlb_resp_bits_data_s1_entry_perm_r |= ~pf_g_io_tlb_resp_bits_data_s1_entry_perm_r;
        checks++;
        if (pf_g_io_tlb_resp_bits_data_s1_entry_level !== pf_i_io_tlb_resp_bits_data_s1_entry_level) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d PTWFilter.io_tlb_resp_bits_data_s1_entry_level g=%h i=%h", cyc, pf_g_io_tlb_resp_bits_data_s1_entry_level, pf_i_io_tlb_resp_bits_data_s1_entry_level);
        end
        pf_s1_io_tlb_resp_bits_data_s1_entry_level |= pf_g_io_tlb_resp_bits_data_s1_entry_level;
        pf_s0_io_tlb_resp_bits_data_s1_entry_level |= ~pf_g_io_tlb_resp_bits_data_s1_entry_level;
        checks++;
        if (pf_g_io_tlb_resp_bits_data_s1_entry_v !== pf_i_io_tlb_resp_bits_data_s1_entry_v) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d PTWFilter.io_tlb_resp_bits_data_s1_entry_v g=%h i=%h", cyc, pf_g_io_tlb_resp_bits_data_s1_entry_v, pf_i_io_tlb_resp_bits_data_s1_entry_v);
        end
        pf_s1_io_tlb_resp_bits_data_s1_entry_v |= pf_g_io_tlb_resp_bits_data_s1_entry_v;
        pf_s0_io_tlb_resp_bits_data_s1_entry_v |= ~pf_g_io_tlb_resp_bits_data_s1_entry_v;
        checks++;
        if (pf_g_io_tlb_resp_bits_data_s1_entry_ppn !== pf_i_io_tlb_resp_bits_data_s1_entry_ppn) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d PTWFilter.io_tlb_resp_bits_data_s1_entry_ppn g=%h i=%h", cyc, pf_g_io_tlb_resp_bits_data_s1_entry_ppn, pf_i_io_tlb_resp_bits_data_s1_entry_ppn);
        end
        pf_s1_io_tlb_resp_bits_data_s1_entry_ppn |= pf_g_io_tlb_resp_bits_data_s1_entry_ppn;
        pf_s0_io_tlb_resp_bits_data_s1_entry_ppn |= ~pf_g_io_tlb_resp_bits_data_s1_entry_ppn;
        checks++;
        if (pf_g_io_tlb_resp_bits_data_s1_addr_low !== pf_i_io_tlb_resp_bits_data_s1_addr_low) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d PTWFilter.io_tlb_resp_bits_data_s1_addr_low g=%h i=%h", cyc, pf_g_io_tlb_resp_bits_data_s1_addr_low, pf_i_io_tlb_resp_bits_data_s1_addr_low);
        end
        pf_s1_io_tlb_resp_bits_data_s1_addr_low |= pf_g_io_tlb_resp_bits_data_s1_addr_low;
        pf_s0_io_tlb_resp_bits_data_s1_addr_low |= ~pf_g_io_tlb_resp_bits_data_s1_addr_low;
        checks++;
        if (pf_g_io_tlb_resp_bits_data_s1_ppn_low_0 !== pf_i_io_tlb_resp_bits_data_s1_ppn_low_0) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d PTWFilter.io_tlb_resp_bits_data_s1_ppn_low_0 g=%h i=%h", cyc, pf_g_io_tlb_resp_bits_data_s1_ppn_low_0, pf_i_io_tlb_resp_bits_data_s1_ppn_low_0);
        end
        pf_s1_io_tlb_resp_bits_data_s1_ppn_low_0 |= pf_g_io_tlb_resp_bits_data_s1_ppn_low_0;
        pf_s0_io_tlb_resp_bits_data_s1_ppn_low_0 |= ~pf_g_io_tlb_resp_bits_data_s1_ppn_low_0;
        checks++;
        if (pf_g_io_tlb_resp_bits_data_s1_ppn_low_1 !== pf_i_io_tlb_resp_bits_data_s1_ppn_low_1) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d PTWFilter.io_tlb_resp_bits_data_s1_ppn_low_1 g=%h i=%h", cyc, pf_g_io_tlb_resp_bits_data_s1_ppn_low_1, pf_i_io_tlb_resp_bits_data_s1_ppn_low_1);
        end
        pf_s1_io_tlb_resp_bits_data_s1_ppn_low_1 |= pf_g_io_tlb_resp_bits_data_s1_ppn_low_1;
        pf_s0_io_tlb_resp_bits_data_s1_ppn_low_1 |= ~pf_g_io_tlb_resp_bits_data_s1_ppn_low_1;
        checks++;
        if (pf_g_io_tlb_resp_bits_data_s1_ppn_low_2 !== pf_i_io_tlb_resp_bits_data_s1_ppn_low_2) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d PTWFilter.io_tlb_resp_bits_data_s1_ppn_low_2 g=%h i=%h", cyc, pf_g_io_tlb_resp_bits_data_s1_ppn_low_2, pf_i_io_tlb_resp_bits_data_s1_ppn_low_2);
        end
        pf_s1_io_tlb_resp_bits_data_s1_ppn_low_2 |= pf_g_io_tlb_resp_bits_data_s1_ppn_low_2;
        pf_s0_io_tlb_resp_bits_data_s1_ppn_low_2 |= ~pf_g_io_tlb_resp_bits_data_s1_ppn_low_2;
        checks++;
        if (pf_g_io_tlb_resp_bits_data_s1_ppn_low_3 !== pf_i_io_tlb_resp_bits_data_s1_ppn_low_3) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d PTWFilter.io_tlb_resp_bits_data_s1_ppn_low_3 g=%h i=%h", cyc, pf_g_io_tlb_resp_bits_data_s1_ppn_low_3, pf_i_io_tlb_resp_bits_data_s1_ppn_low_3);
        end
        pf_s1_io_tlb_resp_bits_data_s1_ppn_low_3 |= pf_g_io_tlb_resp_bits_data_s1_ppn_low_3;
        pf_s0_io_tlb_resp_bits_data_s1_ppn_low_3 |= ~pf_g_io_tlb_resp_bits_data_s1_ppn_low_3;
        checks++;
        if (pf_g_io_tlb_resp_bits_data_s1_ppn_low_4 !== pf_i_io_tlb_resp_bits_data_s1_ppn_low_4) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d PTWFilter.io_tlb_resp_bits_data_s1_ppn_low_4 g=%h i=%h", cyc, pf_g_io_tlb_resp_bits_data_s1_ppn_low_4, pf_i_io_tlb_resp_bits_data_s1_ppn_low_4);
        end
        pf_s1_io_tlb_resp_bits_data_s1_ppn_low_4 |= pf_g_io_tlb_resp_bits_data_s1_ppn_low_4;
        pf_s0_io_tlb_resp_bits_data_s1_ppn_low_4 |= ~pf_g_io_tlb_resp_bits_data_s1_ppn_low_4;
        checks++;
        if (pf_g_io_tlb_resp_bits_data_s1_ppn_low_5 !== pf_i_io_tlb_resp_bits_data_s1_ppn_low_5) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d PTWFilter.io_tlb_resp_bits_data_s1_ppn_low_5 g=%h i=%h", cyc, pf_g_io_tlb_resp_bits_data_s1_ppn_low_5, pf_i_io_tlb_resp_bits_data_s1_ppn_low_5);
        end
        pf_s1_io_tlb_resp_bits_data_s1_ppn_low_5 |= pf_g_io_tlb_resp_bits_data_s1_ppn_low_5;
        pf_s0_io_tlb_resp_bits_data_s1_ppn_low_5 |= ~pf_g_io_tlb_resp_bits_data_s1_ppn_low_5;
        checks++;
        if (pf_g_io_tlb_resp_bits_data_s1_ppn_low_6 !== pf_i_io_tlb_resp_bits_data_s1_ppn_low_6) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d PTWFilter.io_tlb_resp_bits_data_s1_ppn_low_6 g=%h i=%h", cyc, pf_g_io_tlb_resp_bits_data_s1_ppn_low_6, pf_i_io_tlb_resp_bits_data_s1_ppn_low_6);
        end
        pf_s1_io_tlb_resp_bits_data_s1_ppn_low_6 |= pf_g_io_tlb_resp_bits_data_s1_ppn_low_6;
        pf_s0_io_tlb_resp_bits_data_s1_ppn_low_6 |= ~pf_g_io_tlb_resp_bits_data_s1_ppn_low_6;
        checks++;
        if (pf_g_io_tlb_resp_bits_data_s1_ppn_low_7 !== pf_i_io_tlb_resp_bits_data_s1_ppn_low_7) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d PTWFilter.io_tlb_resp_bits_data_s1_ppn_low_7 g=%h i=%h", cyc, pf_g_io_tlb_resp_bits_data_s1_ppn_low_7, pf_i_io_tlb_resp_bits_data_s1_ppn_low_7);
        end
        pf_s1_io_tlb_resp_bits_data_s1_ppn_low_7 |= pf_g_io_tlb_resp_bits_data_s1_ppn_low_7;
        pf_s0_io_tlb_resp_bits_data_s1_ppn_low_7 |= ~pf_g_io_tlb_resp_bits_data_s1_ppn_low_7;
        checks++;
        if (pf_g_io_tlb_resp_bits_data_s1_valididx_0 !== pf_i_io_tlb_resp_bits_data_s1_valididx_0) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d PTWFilter.io_tlb_resp_bits_data_s1_valididx_0 g=%h i=%h", cyc, pf_g_io_tlb_resp_bits_data_s1_valididx_0, pf_i_io_tlb_resp_bits_data_s1_valididx_0);
        end
        pf_s1_io_tlb_resp_bits_data_s1_valididx_0 |= pf_g_io_tlb_resp_bits_data_s1_valididx_0;
        pf_s0_io_tlb_resp_bits_data_s1_valididx_0 |= ~pf_g_io_tlb_resp_bits_data_s1_valididx_0;
        checks++;
        if (pf_g_io_tlb_resp_bits_data_s1_valididx_1 !== pf_i_io_tlb_resp_bits_data_s1_valididx_1) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d PTWFilter.io_tlb_resp_bits_data_s1_valididx_1 g=%h i=%h", cyc, pf_g_io_tlb_resp_bits_data_s1_valididx_1, pf_i_io_tlb_resp_bits_data_s1_valididx_1);
        end
        pf_s1_io_tlb_resp_bits_data_s1_valididx_1 |= pf_g_io_tlb_resp_bits_data_s1_valididx_1;
        pf_s0_io_tlb_resp_bits_data_s1_valididx_1 |= ~pf_g_io_tlb_resp_bits_data_s1_valididx_1;
        checks++;
        if (pf_g_io_tlb_resp_bits_data_s1_valididx_2 !== pf_i_io_tlb_resp_bits_data_s1_valididx_2) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d PTWFilter.io_tlb_resp_bits_data_s1_valididx_2 g=%h i=%h", cyc, pf_g_io_tlb_resp_bits_data_s1_valididx_2, pf_i_io_tlb_resp_bits_data_s1_valididx_2);
        end
        pf_s1_io_tlb_resp_bits_data_s1_valididx_2 |= pf_g_io_tlb_resp_bits_data_s1_valididx_2;
        pf_s0_io_tlb_resp_bits_data_s1_valididx_2 |= ~pf_g_io_tlb_resp_bits_data_s1_valididx_2;
        checks++;
        if (pf_g_io_tlb_resp_bits_data_s1_valididx_3 !== pf_i_io_tlb_resp_bits_data_s1_valididx_3) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d PTWFilter.io_tlb_resp_bits_data_s1_valididx_3 g=%h i=%h", cyc, pf_g_io_tlb_resp_bits_data_s1_valididx_3, pf_i_io_tlb_resp_bits_data_s1_valididx_3);
        end
        pf_s1_io_tlb_resp_bits_data_s1_valididx_3 |= pf_g_io_tlb_resp_bits_data_s1_valididx_3;
        pf_s0_io_tlb_resp_bits_data_s1_valididx_3 |= ~pf_g_io_tlb_resp_bits_data_s1_valididx_3;
        checks++;
        if (pf_g_io_tlb_resp_bits_data_s1_valididx_4 !== pf_i_io_tlb_resp_bits_data_s1_valididx_4) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d PTWFilter.io_tlb_resp_bits_data_s1_valididx_4 g=%h i=%h", cyc, pf_g_io_tlb_resp_bits_data_s1_valididx_4, pf_i_io_tlb_resp_bits_data_s1_valididx_4);
        end
        pf_s1_io_tlb_resp_bits_data_s1_valididx_4 |= pf_g_io_tlb_resp_bits_data_s1_valididx_4;
        pf_s0_io_tlb_resp_bits_data_s1_valididx_4 |= ~pf_g_io_tlb_resp_bits_data_s1_valididx_4;
        checks++;
        if (pf_g_io_tlb_resp_bits_data_s1_valididx_5 !== pf_i_io_tlb_resp_bits_data_s1_valididx_5) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d PTWFilter.io_tlb_resp_bits_data_s1_valididx_5 g=%h i=%h", cyc, pf_g_io_tlb_resp_bits_data_s1_valididx_5, pf_i_io_tlb_resp_bits_data_s1_valididx_5);
        end
        pf_s1_io_tlb_resp_bits_data_s1_valididx_5 |= pf_g_io_tlb_resp_bits_data_s1_valididx_5;
        pf_s0_io_tlb_resp_bits_data_s1_valididx_5 |= ~pf_g_io_tlb_resp_bits_data_s1_valididx_5;
        checks++;
        if (pf_g_io_tlb_resp_bits_data_s1_valididx_6 !== pf_i_io_tlb_resp_bits_data_s1_valididx_6) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d PTWFilter.io_tlb_resp_bits_data_s1_valididx_6 g=%h i=%h", cyc, pf_g_io_tlb_resp_bits_data_s1_valididx_6, pf_i_io_tlb_resp_bits_data_s1_valididx_6);
        end
        pf_s1_io_tlb_resp_bits_data_s1_valididx_6 |= pf_g_io_tlb_resp_bits_data_s1_valididx_6;
        pf_s0_io_tlb_resp_bits_data_s1_valididx_6 |= ~pf_g_io_tlb_resp_bits_data_s1_valididx_6;
        checks++;
        if (pf_g_io_tlb_resp_bits_data_s1_valididx_7 !== pf_i_io_tlb_resp_bits_data_s1_valididx_7) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d PTWFilter.io_tlb_resp_bits_data_s1_valididx_7 g=%h i=%h", cyc, pf_g_io_tlb_resp_bits_data_s1_valididx_7, pf_i_io_tlb_resp_bits_data_s1_valididx_7);
        end
        pf_s1_io_tlb_resp_bits_data_s1_valididx_7 |= pf_g_io_tlb_resp_bits_data_s1_valididx_7;
        pf_s0_io_tlb_resp_bits_data_s1_valididx_7 |= ~pf_g_io_tlb_resp_bits_data_s1_valididx_7;
        checks++;
        if (pf_g_io_tlb_resp_bits_data_s1_pteidx_0 !== pf_i_io_tlb_resp_bits_data_s1_pteidx_0) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d PTWFilter.io_tlb_resp_bits_data_s1_pteidx_0 g=%h i=%h", cyc, pf_g_io_tlb_resp_bits_data_s1_pteidx_0, pf_i_io_tlb_resp_bits_data_s1_pteidx_0);
        end
        pf_s1_io_tlb_resp_bits_data_s1_pteidx_0 |= pf_g_io_tlb_resp_bits_data_s1_pteidx_0;
        pf_s0_io_tlb_resp_bits_data_s1_pteidx_0 |= ~pf_g_io_tlb_resp_bits_data_s1_pteidx_0;
        checks++;
        if (pf_g_io_tlb_resp_bits_data_s1_pteidx_1 !== pf_i_io_tlb_resp_bits_data_s1_pteidx_1) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d PTWFilter.io_tlb_resp_bits_data_s1_pteidx_1 g=%h i=%h", cyc, pf_g_io_tlb_resp_bits_data_s1_pteidx_1, pf_i_io_tlb_resp_bits_data_s1_pteidx_1);
        end
        pf_s1_io_tlb_resp_bits_data_s1_pteidx_1 |= pf_g_io_tlb_resp_bits_data_s1_pteidx_1;
        pf_s0_io_tlb_resp_bits_data_s1_pteidx_1 |= ~pf_g_io_tlb_resp_bits_data_s1_pteidx_1;
        checks++;
        if (pf_g_io_tlb_resp_bits_data_s1_pteidx_2 !== pf_i_io_tlb_resp_bits_data_s1_pteidx_2) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d PTWFilter.io_tlb_resp_bits_data_s1_pteidx_2 g=%h i=%h", cyc, pf_g_io_tlb_resp_bits_data_s1_pteidx_2, pf_i_io_tlb_resp_bits_data_s1_pteidx_2);
        end
        pf_s1_io_tlb_resp_bits_data_s1_pteidx_2 |= pf_g_io_tlb_resp_bits_data_s1_pteidx_2;
        pf_s0_io_tlb_resp_bits_data_s1_pteidx_2 |= ~pf_g_io_tlb_resp_bits_data_s1_pteidx_2;
        checks++;
        if (pf_g_io_tlb_resp_bits_data_s1_pteidx_3 !== pf_i_io_tlb_resp_bits_data_s1_pteidx_3) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d PTWFilter.io_tlb_resp_bits_data_s1_pteidx_3 g=%h i=%h", cyc, pf_g_io_tlb_resp_bits_data_s1_pteidx_3, pf_i_io_tlb_resp_bits_data_s1_pteidx_3);
        end
        pf_s1_io_tlb_resp_bits_data_s1_pteidx_3 |= pf_g_io_tlb_resp_bits_data_s1_pteidx_3;
        pf_s0_io_tlb_resp_bits_data_s1_pteidx_3 |= ~pf_g_io_tlb_resp_bits_data_s1_pteidx_3;
        checks++;
        if (pf_g_io_tlb_resp_bits_data_s1_pteidx_4 !== pf_i_io_tlb_resp_bits_data_s1_pteidx_4) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d PTWFilter.io_tlb_resp_bits_data_s1_pteidx_4 g=%h i=%h", cyc, pf_g_io_tlb_resp_bits_data_s1_pteidx_4, pf_i_io_tlb_resp_bits_data_s1_pteidx_4);
        end
        pf_s1_io_tlb_resp_bits_data_s1_pteidx_4 |= pf_g_io_tlb_resp_bits_data_s1_pteidx_4;
        pf_s0_io_tlb_resp_bits_data_s1_pteidx_4 |= ~pf_g_io_tlb_resp_bits_data_s1_pteidx_4;
        checks++;
        if (pf_g_io_tlb_resp_bits_data_s1_pteidx_5 !== pf_i_io_tlb_resp_bits_data_s1_pteidx_5) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d PTWFilter.io_tlb_resp_bits_data_s1_pteidx_5 g=%h i=%h", cyc, pf_g_io_tlb_resp_bits_data_s1_pteidx_5, pf_i_io_tlb_resp_bits_data_s1_pteidx_5);
        end
        pf_s1_io_tlb_resp_bits_data_s1_pteidx_5 |= pf_g_io_tlb_resp_bits_data_s1_pteidx_5;
        pf_s0_io_tlb_resp_bits_data_s1_pteidx_5 |= ~pf_g_io_tlb_resp_bits_data_s1_pteidx_5;
        checks++;
        if (pf_g_io_tlb_resp_bits_data_s1_pteidx_6 !== pf_i_io_tlb_resp_bits_data_s1_pteidx_6) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d PTWFilter.io_tlb_resp_bits_data_s1_pteidx_6 g=%h i=%h", cyc, pf_g_io_tlb_resp_bits_data_s1_pteidx_6, pf_i_io_tlb_resp_bits_data_s1_pteidx_6);
        end
        pf_s1_io_tlb_resp_bits_data_s1_pteidx_6 |= pf_g_io_tlb_resp_bits_data_s1_pteidx_6;
        pf_s0_io_tlb_resp_bits_data_s1_pteidx_6 |= ~pf_g_io_tlb_resp_bits_data_s1_pteidx_6;
        checks++;
        if (pf_g_io_tlb_resp_bits_data_s1_pteidx_7 !== pf_i_io_tlb_resp_bits_data_s1_pteidx_7) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d PTWFilter.io_tlb_resp_bits_data_s1_pteidx_7 g=%h i=%h", cyc, pf_g_io_tlb_resp_bits_data_s1_pteidx_7, pf_i_io_tlb_resp_bits_data_s1_pteidx_7);
        end
        pf_s1_io_tlb_resp_bits_data_s1_pteidx_7 |= pf_g_io_tlb_resp_bits_data_s1_pteidx_7;
        pf_s0_io_tlb_resp_bits_data_s1_pteidx_7 |= ~pf_g_io_tlb_resp_bits_data_s1_pteidx_7;
        checks++;
        if (pf_g_io_tlb_resp_bits_data_s1_pf !== pf_i_io_tlb_resp_bits_data_s1_pf) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d PTWFilter.io_tlb_resp_bits_data_s1_pf g=%h i=%h", cyc, pf_g_io_tlb_resp_bits_data_s1_pf, pf_i_io_tlb_resp_bits_data_s1_pf);
        end
        pf_s1_io_tlb_resp_bits_data_s1_pf |= pf_g_io_tlb_resp_bits_data_s1_pf;
        pf_s0_io_tlb_resp_bits_data_s1_pf |= ~pf_g_io_tlb_resp_bits_data_s1_pf;
        checks++;
        if (pf_g_io_tlb_resp_bits_data_s1_af !== pf_i_io_tlb_resp_bits_data_s1_af) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d PTWFilter.io_tlb_resp_bits_data_s1_af g=%h i=%h", cyc, pf_g_io_tlb_resp_bits_data_s1_af, pf_i_io_tlb_resp_bits_data_s1_af);
        end
        pf_s1_io_tlb_resp_bits_data_s1_af |= pf_g_io_tlb_resp_bits_data_s1_af;
        pf_s0_io_tlb_resp_bits_data_s1_af |= ~pf_g_io_tlb_resp_bits_data_s1_af;
        checks++;
        if (pf_g_io_tlb_resp_bits_data_s2_entry_tag !== pf_i_io_tlb_resp_bits_data_s2_entry_tag) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d PTWFilter.io_tlb_resp_bits_data_s2_entry_tag g=%h i=%h", cyc, pf_g_io_tlb_resp_bits_data_s2_entry_tag, pf_i_io_tlb_resp_bits_data_s2_entry_tag);
        end
        pf_s1_io_tlb_resp_bits_data_s2_entry_tag |= pf_g_io_tlb_resp_bits_data_s2_entry_tag;
        pf_s0_io_tlb_resp_bits_data_s2_entry_tag |= ~pf_g_io_tlb_resp_bits_data_s2_entry_tag;
        checks++;
        if (pf_g_io_tlb_resp_bits_data_s2_entry_vmid !== pf_i_io_tlb_resp_bits_data_s2_entry_vmid) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d PTWFilter.io_tlb_resp_bits_data_s2_entry_vmid g=%h i=%h", cyc, pf_g_io_tlb_resp_bits_data_s2_entry_vmid, pf_i_io_tlb_resp_bits_data_s2_entry_vmid);
        end
        pf_s1_io_tlb_resp_bits_data_s2_entry_vmid |= pf_g_io_tlb_resp_bits_data_s2_entry_vmid;
        pf_s0_io_tlb_resp_bits_data_s2_entry_vmid |= ~pf_g_io_tlb_resp_bits_data_s2_entry_vmid;
        checks++;
        if (pf_g_io_tlb_resp_bits_data_s2_entry_n !== pf_i_io_tlb_resp_bits_data_s2_entry_n) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d PTWFilter.io_tlb_resp_bits_data_s2_entry_n g=%h i=%h", cyc, pf_g_io_tlb_resp_bits_data_s2_entry_n, pf_i_io_tlb_resp_bits_data_s2_entry_n);
        end
        pf_s1_io_tlb_resp_bits_data_s2_entry_n |= pf_g_io_tlb_resp_bits_data_s2_entry_n;
        pf_s0_io_tlb_resp_bits_data_s2_entry_n |= ~pf_g_io_tlb_resp_bits_data_s2_entry_n;
        checks++;
        if (pf_g_io_tlb_resp_bits_data_s2_entry_pbmt !== pf_i_io_tlb_resp_bits_data_s2_entry_pbmt) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d PTWFilter.io_tlb_resp_bits_data_s2_entry_pbmt g=%h i=%h", cyc, pf_g_io_tlb_resp_bits_data_s2_entry_pbmt, pf_i_io_tlb_resp_bits_data_s2_entry_pbmt);
        end
        pf_s1_io_tlb_resp_bits_data_s2_entry_pbmt |= pf_g_io_tlb_resp_bits_data_s2_entry_pbmt;
        pf_s0_io_tlb_resp_bits_data_s2_entry_pbmt |= ~pf_g_io_tlb_resp_bits_data_s2_entry_pbmt;
        checks++;
        if (pf_g_io_tlb_resp_bits_data_s2_entry_ppn !== pf_i_io_tlb_resp_bits_data_s2_entry_ppn) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d PTWFilter.io_tlb_resp_bits_data_s2_entry_ppn g=%h i=%h", cyc, pf_g_io_tlb_resp_bits_data_s2_entry_ppn, pf_i_io_tlb_resp_bits_data_s2_entry_ppn);
        end
        pf_s1_io_tlb_resp_bits_data_s2_entry_ppn |= pf_g_io_tlb_resp_bits_data_s2_entry_ppn;
        pf_s0_io_tlb_resp_bits_data_s2_entry_ppn |= ~pf_g_io_tlb_resp_bits_data_s2_entry_ppn;
        checks++;
        if (pf_g_io_tlb_resp_bits_data_s2_entry_perm_d !== pf_i_io_tlb_resp_bits_data_s2_entry_perm_d) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d PTWFilter.io_tlb_resp_bits_data_s2_entry_perm_d g=%h i=%h", cyc, pf_g_io_tlb_resp_bits_data_s2_entry_perm_d, pf_i_io_tlb_resp_bits_data_s2_entry_perm_d);
        end
        pf_s1_io_tlb_resp_bits_data_s2_entry_perm_d |= pf_g_io_tlb_resp_bits_data_s2_entry_perm_d;
        pf_s0_io_tlb_resp_bits_data_s2_entry_perm_d |= ~pf_g_io_tlb_resp_bits_data_s2_entry_perm_d;
        checks++;
        if (pf_g_io_tlb_resp_bits_data_s2_entry_perm_a !== pf_i_io_tlb_resp_bits_data_s2_entry_perm_a) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d PTWFilter.io_tlb_resp_bits_data_s2_entry_perm_a g=%h i=%h", cyc, pf_g_io_tlb_resp_bits_data_s2_entry_perm_a, pf_i_io_tlb_resp_bits_data_s2_entry_perm_a);
        end
        pf_s1_io_tlb_resp_bits_data_s2_entry_perm_a |= pf_g_io_tlb_resp_bits_data_s2_entry_perm_a;
        pf_s0_io_tlb_resp_bits_data_s2_entry_perm_a |= ~pf_g_io_tlb_resp_bits_data_s2_entry_perm_a;
        checks++;
        if (pf_g_io_tlb_resp_bits_data_s2_entry_perm_g !== pf_i_io_tlb_resp_bits_data_s2_entry_perm_g) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d PTWFilter.io_tlb_resp_bits_data_s2_entry_perm_g g=%h i=%h", cyc, pf_g_io_tlb_resp_bits_data_s2_entry_perm_g, pf_i_io_tlb_resp_bits_data_s2_entry_perm_g);
        end
        pf_s1_io_tlb_resp_bits_data_s2_entry_perm_g |= pf_g_io_tlb_resp_bits_data_s2_entry_perm_g;
        pf_s0_io_tlb_resp_bits_data_s2_entry_perm_g |= ~pf_g_io_tlb_resp_bits_data_s2_entry_perm_g;
        checks++;
        if (pf_g_io_tlb_resp_bits_data_s2_entry_perm_u !== pf_i_io_tlb_resp_bits_data_s2_entry_perm_u) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d PTWFilter.io_tlb_resp_bits_data_s2_entry_perm_u g=%h i=%h", cyc, pf_g_io_tlb_resp_bits_data_s2_entry_perm_u, pf_i_io_tlb_resp_bits_data_s2_entry_perm_u);
        end
        pf_s1_io_tlb_resp_bits_data_s2_entry_perm_u |= pf_g_io_tlb_resp_bits_data_s2_entry_perm_u;
        pf_s0_io_tlb_resp_bits_data_s2_entry_perm_u |= ~pf_g_io_tlb_resp_bits_data_s2_entry_perm_u;
        checks++;
        if (pf_g_io_tlb_resp_bits_data_s2_entry_perm_x !== pf_i_io_tlb_resp_bits_data_s2_entry_perm_x) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d PTWFilter.io_tlb_resp_bits_data_s2_entry_perm_x g=%h i=%h", cyc, pf_g_io_tlb_resp_bits_data_s2_entry_perm_x, pf_i_io_tlb_resp_bits_data_s2_entry_perm_x);
        end
        pf_s1_io_tlb_resp_bits_data_s2_entry_perm_x |= pf_g_io_tlb_resp_bits_data_s2_entry_perm_x;
        pf_s0_io_tlb_resp_bits_data_s2_entry_perm_x |= ~pf_g_io_tlb_resp_bits_data_s2_entry_perm_x;
        checks++;
        if (pf_g_io_tlb_resp_bits_data_s2_entry_perm_w !== pf_i_io_tlb_resp_bits_data_s2_entry_perm_w) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d PTWFilter.io_tlb_resp_bits_data_s2_entry_perm_w g=%h i=%h", cyc, pf_g_io_tlb_resp_bits_data_s2_entry_perm_w, pf_i_io_tlb_resp_bits_data_s2_entry_perm_w);
        end
        pf_s1_io_tlb_resp_bits_data_s2_entry_perm_w |= pf_g_io_tlb_resp_bits_data_s2_entry_perm_w;
        pf_s0_io_tlb_resp_bits_data_s2_entry_perm_w |= ~pf_g_io_tlb_resp_bits_data_s2_entry_perm_w;
        checks++;
        if (pf_g_io_tlb_resp_bits_data_s2_entry_perm_r !== pf_i_io_tlb_resp_bits_data_s2_entry_perm_r) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d PTWFilter.io_tlb_resp_bits_data_s2_entry_perm_r g=%h i=%h", cyc, pf_g_io_tlb_resp_bits_data_s2_entry_perm_r, pf_i_io_tlb_resp_bits_data_s2_entry_perm_r);
        end
        pf_s1_io_tlb_resp_bits_data_s2_entry_perm_r |= pf_g_io_tlb_resp_bits_data_s2_entry_perm_r;
        pf_s0_io_tlb_resp_bits_data_s2_entry_perm_r |= ~pf_g_io_tlb_resp_bits_data_s2_entry_perm_r;
        checks++;
        if (pf_g_io_tlb_resp_bits_data_s2_entry_level !== pf_i_io_tlb_resp_bits_data_s2_entry_level) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d PTWFilter.io_tlb_resp_bits_data_s2_entry_level g=%h i=%h", cyc, pf_g_io_tlb_resp_bits_data_s2_entry_level, pf_i_io_tlb_resp_bits_data_s2_entry_level);
        end
        pf_s1_io_tlb_resp_bits_data_s2_entry_level |= pf_g_io_tlb_resp_bits_data_s2_entry_level;
        pf_s0_io_tlb_resp_bits_data_s2_entry_level |= ~pf_g_io_tlb_resp_bits_data_s2_entry_level;
        checks++;
        if (pf_g_io_tlb_resp_bits_data_s2_gpf !== pf_i_io_tlb_resp_bits_data_s2_gpf) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d PTWFilter.io_tlb_resp_bits_data_s2_gpf g=%h i=%h", cyc, pf_g_io_tlb_resp_bits_data_s2_gpf, pf_i_io_tlb_resp_bits_data_s2_gpf);
        end
        pf_s1_io_tlb_resp_bits_data_s2_gpf |= pf_g_io_tlb_resp_bits_data_s2_gpf;
        pf_s0_io_tlb_resp_bits_data_s2_gpf |= ~pf_g_io_tlb_resp_bits_data_s2_gpf;
        checks++;
        if (pf_g_io_tlb_resp_bits_data_s2_gaf !== pf_i_io_tlb_resp_bits_data_s2_gaf) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d PTWFilter.io_tlb_resp_bits_data_s2_gaf g=%h i=%h", cyc, pf_g_io_tlb_resp_bits_data_s2_gaf, pf_i_io_tlb_resp_bits_data_s2_gaf);
        end
        pf_s1_io_tlb_resp_bits_data_s2_gaf |= pf_g_io_tlb_resp_bits_data_s2_gaf;
        pf_s0_io_tlb_resp_bits_data_s2_gaf |= ~pf_g_io_tlb_resp_bits_data_s2_gaf;
        checks++;
        if (pf_g_io_tlb_resp_bits_data_getGpa !== pf_i_io_tlb_resp_bits_data_getGpa) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d PTWFilter.io_tlb_resp_bits_data_getGpa g=%h i=%h", cyc, pf_g_io_tlb_resp_bits_data_getGpa, pf_i_io_tlb_resp_bits_data_getGpa);
        end
        pf_s1_io_tlb_resp_bits_data_getGpa |= pf_g_io_tlb_resp_bits_data_getGpa;
        pf_s0_io_tlb_resp_bits_data_getGpa |= ~pf_g_io_tlb_resp_bits_data_getGpa;
        checks++;
        if (pf_g_io_ptw_req_0_valid !== pf_i_io_ptw_req_0_valid) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d PTWFilter.io_ptw_req_0_valid g=%h i=%h", cyc, pf_g_io_ptw_req_0_valid, pf_i_io_ptw_req_0_valid);
        end
        pf_s1_io_ptw_req_0_valid |= pf_g_io_ptw_req_0_valid;
        pf_s0_io_ptw_req_0_valid |= ~pf_g_io_ptw_req_0_valid;
        checks++;
        if (pf_g_io_ptw_req_0_bits_vpn !== pf_i_io_ptw_req_0_bits_vpn) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d PTWFilter.io_ptw_req_0_bits_vpn g=%h i=%h", cyc, pf_g_io_ptw_req_0_bits_vpn, pf_i_io_ptw_req_0_bits_vpn);
        end
        pf_s1_io_ptw_req_0_bits_vpn |= pf_g_io_ptw_req_0_bits_vpn;
        pf_s0_io_ptw_req_0_bits_vpn |= ~pf_g_io_ptw_req_0_bits_vpn;
        checks++;
        if (pf_g_io_ptw_req_0_bits_s2xlate !== pf_i_io_ptw_req_0_bits_s2xlate) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d PTWFilter.io_ptw_req_0_bits_s2xlate g=%h i=%h", cyc, pf_g_io_ptw_req_0_bits_s2xlate, pf_i_io_ptw_req_0_bits_s2xlate);
        end
        pf_s1_io_ptw_req_0_bits_s2xlate |= pf_g_io_ptw_req_0_bits_s2xlate;
        pf_s0_io_ptw_req_0_bits_s2xlate |= ~pf_g_io_ptw_req_0_bits_s2xlate;
        if (pf_u_gold.do_enq) pf_cov_enq++;
        if (pf_u_gold.do_enq && pf_u_gold._enqNum_T_2 >= 2'd2) pf_cov_enq2plus++;
        if ((|{pf_u_gold.reqs_0_valid, pf_u_gold.reqs_1_valid, pf_u_gold.reqs_2_valid}) && !pf_u_gold.canEnqueue) pf_cov_enq_blocked++;
        if (!pf_g_io_tlb_req_0_ready) pf_cov_ready_low++;
        if (pf_u_gold.counter == 4'd8) pf_cov_full++;
        if (pf_u_gold.do_deq) pf_cov_deq++;
        if (pf_g_io_ptw_req_0_valid && pf_io_ptw_req_0_ready) pf_cov_iss_fire++;
        if (!pf_u_gold._GEN_15 && !pf_u_gold.isEmptyIss) pf_cov_iss_skip_dead++;
        if (pf_u_gold.inflight_counter == 4'd8) pf_cov_inflight_full++;
        if (pf_io_ptw_resp_valid && (|{pf_u_gold.ptwResp_OldMatchVec_0, pf_u_gold.ptwResp_OldMatchVec_3, pf_u_gold.ptwResp_OldMatchVec_7})) pf_cov_resp_hit_entry++;
        if (pf_io_ptw_resp_valid && !pf_u_gold.ptwResp_valid_last_REG) pf_cov_resp_miss_all++;
        if (pf_g_io_tlb_resp_valid) pf_cov_tlb_resp++;
        if (pf_u_gold.reqs_0_valid && pf_u_gold.canEnqueue && pf_u_gold.tlb_req_flushed_0) pf_cov_fake_enq++;
        if (pf_io_tlb_req_1_valid && !pf_u_gold.tlb_req_1_valid_last_REG) pf_cov_merge_last_resp++;
        if (pf_u_gold.tlb_req_0_valid_last_REG && pf_u_gold.oldMatchVec_last_REG) pf_cov_merge_old++;
        if (pf_u_gold.tlb_req_2_valid_last_REG && (pf_u_gold.newMatchVec_last_REG_6 || pf_u_gold.newMatchVec_last_REG_7)) pf_cov_merge_port++;
        if (pf_u_gold._flush_delay_io_out) pf_cov_flush++;
        if (pf_u_gold._flush_delay_io_out && pf_u_gold.ptwResp_valid_last_REG) pf_cov_flush_kills_resp++;
        if (pf_io_ptw_resp_valid && pf_io_ptw_resp_bits_s2xlate == 2'd0 && pf_u_gold.ptwResp_OldMatchVec_1) pf_cov_hit_noS2++;
        if (pf_io_ptw_resp_valid && pf_io_ptw_resp_bits_s2xlate == 2'd2 && pf_u_gold.ptwResp_OldMatchVec_1) pf_cov_hit_onlyS2++;
        if (pf_io_ptw_resp_valid && pf_io_ptw_resp_bits_s2xlate[0] && pf_u_gold.ptwResp_OldMatchVec_1) pf_cov_hit_allS1++;
        if (pf_io_ptw_resp_valid && pf_io_ptw_resp_bits_s1_entry_n && pf_u_gold.ptwResp_OldMatchVec_1) pf_cov_hit_napot++;
        if (pf_io_ptw_resp_valid && pf_io_ptw_resp_bits_s1_entry_level != 2'd0 && pf_u_gold.ptwResp_OldMatchVec_1) pf_cov_hit_super++;
        if (pf_io_ptw_resp_valid && pf_io_ptw_resp_bits_s1_entry_perm_g && pf_io_ptw_resp_bits_s1_entry_asid != pf_io_csr_satp_asid && pf_u_gold.ptwResp_OldMatchVec_1) pf_cov_hit_g++;
        if (pf_g_io_tlb_resp_valid && pf_g_io_tlb_resp_bits_data_getGpa) pf_cov_getGpa++;
      end
      if (pf_enq_total >= 8) pf_armed[0] = 1'b1;
      if (pf_io_tlb_req_0_valid) pf_armed[1] = 1'b1;
      if (pf_io_tlb_req_1_valid) pf_armed[2] = 1'b1;
      if (pf_io_tlb_req_2_valid) pf_armed[3] = 1'b1;
      if (pf_io_ptw_resp_valid) pf_armed[4] = 1'b1;
      if (pf_armed_at < 0 && (&pf_armed)) pf_armed_at = cyc + 1 + 2;
    end

    // ---- 覆盖闸 ----
    if (!(pf_s0_io_tlb_req_0_ready && pf_s1_io_tlb_req_0_ready)) begin cov_fail++; $display("[COV] PTWFilter.io_tlb_req_0_ready 未见过 0 和 1"); end
    if (!(pf_s0_io_tlb_req_1_ready && pf_s1_io_tlb_req_1_ready)) begin cov_fail++; $display("[COV] PTWFilter.io_tlb_req_1_ready 未见过 0 和 1"); end
    if (!(pf_s0_io_tlb_req_2_ready && pf_s1_io_tlb_req_2_ready)) begin cov_fail++; $display("[COV] PTWFilter.io_tlb_req_2_ready 未见过 0 和 1"); end
    if (!(pf_s0_io_tlb_resp_valid && pf_s1_io_tlb_resp_valid)) begin cov_fail++; $display("[COV] PTWFilter.io_tlb_resp_valid 未见过 0 和 1"); end
    if (!(pf_s0_io_tlb_resp_bits_data_s2xlate[0] && pf_s1_io_tlb_resp_bits_data_s2xlate[0])) begin cov_fail++; $display("[COV] PTWFilter.io_tlb_resp_bits_data_s2xlate[0] 未见过 0 和 1"); end
    if (!(pf_s0_io_tlb_resp_bits_data_s2xlate[1] && pf_s1_io_tlb_resp_bits_data_s2xlate[1])) begin cov_fail++; $display("[COV] PTWFilter.io_tlb_resp_bits_data_s2xlate[1] 未见过 0 和 1"); end
    if (!(pf_s0_io_tlb_resp_bits_data_s1_entry_tag[0] && pf_s1_io_tlb_resp_bits_data_s1_entry_tag[0])) begin cov_fail++; $display("[COV] PTWFilter.io_tlb_resp_bits_data_s1_entry_tag[0] 未见过 0 和 1"); end
    if (!(pf_s0_io_tlb_resp_bits_data_s1_entry_tag[1] && pf_s1_io_tlb_resp_bits_data_s1_entry_tag[1])) begin cov_fail++; $display("[COV] PTWFilter.io_tlb_resp_bits_data_s1_entry_tag[1] 未见过 0 和 1"); end
    if (!(pf_s0_io_tlb_resp_bits_data_s1_entry_tag[2] && pf_s1_io_tlb_resp_bits_data_s1_entry_tag[2])) begin cov_fail++; $display("[COV] PTWFilter.io_tlb_resp_bits_data_s1_entry_tag[2] 未见过 0 和 1"); end
    if (!(pf_s0_io_tlb_resp_bits_data_s1_entry_tag[3] && pf_s1_io_tlb_resp_bits_data_s1_entry_tag[3])) begin cov_fail++; $display("[COV] PTWFilter.io_tlb_resp_bits_data_s1_entry_tag[3] 未见过 0 和 1"); end
    if (!(pf_s0_io_tlb_resp_bits_data_s1_entry_tag[4] && pf_s1_io_tlb_resp_bits_data_s1_entry_tag[4])) begin cov_fail++; $display("[COV] PTWFilter.io_tlb_resp_bits_data_s1_entry_tag[4] 未见过 0 和 1"); end
    if (!(pf_s0_io_tlb_resp_bits_data_s1_entry_tag[5] && pf_s1_io_tlb_resp_bits_data_s1_entry_tag[5])) begin cov_fail++; $display("[COV] PTWFilter.io_tlb_resp_bits_data_s1_entry_tag[5] 未见过 0 和 1"); end
    if (!(pf_s0_io_tlb_resp_bits_data_s1_entry_tag[6] && pf_s1_io_tlb_resp_bits_data_s1_entry_tag[6])) begin cov_fail++; $display("[COV] PTWFilter.io_tlb_resp_bits_data_s1_entry_tag[6] 未见过 0 和 1"); end
    if (!(pf_s0_io_tlb_resp_bits_data_s1_entry_tag[7] && pf_s1_io_tlb_resp_bits_data_s1_entry_tag[7])) begin cov_fail++; $display("[COV] PTWFilter.io_tlb_resp_bits_data_s1_entry_tag[7] 未见过 0 和 1"); end
    if (!(pf_s0_io_tlb_resp_bits_data_s1_entry_tag[8] && pf_s1_io_tlb_resp_bits_data_s1_entry_tag[8])) begin cov_fail++; $display("[COV] PTWFilter.io_tlb_resp_bits_data_s1_entry_tag[8] 未见过 0 和 1"); end
    if (!(pf_s0_io_tlb_resp_bits_data_s1_entry_tag[9] && pf_s1_io_tlb_resp_bits_data_s1_entry_tag[9])) begin cov_fail++; $display("[COV] PTWFilter.io_tlb_resp_bits_data_s1_entry_tag[9] 未见过 0 和 1"); end
    if (!(pf_s0_io_tlb_resp_bits_data_s1_entry_tag[10] && pf_s1_io_tlb_resp_bits_data_s1_entry_tag[10])) begin cov_fail++; $display("[COV] PTWFilter.io_tlb_resp_bits_data_s1_entry_tag[10] 未见过 0 和 1"); end
    if (!(pf_s0_io_tlb_resp_bits_data_s1_entry_tag[11] && pf_s1_io_tlb_resp_bits_data_s1_entry_tag[11])) begin cov_fail++; $display("[COV] PTWFilter.io_tlb_resp_bits_data_s1_entry_tag[11] 未见过 0 和 1"); end
    if (!(pf_s0_io_tlb_resp_bits_data_s1_entry_tag[12] && pf_s1_io_tlb_resp_bits_data_s1_entry_tag[12])) begin cov_fail++; $display("[COV] PTWFilter.io_tlb_resp_bits_data_s1_entry_tag[12] 未见过 0 和 1"); end
    if (!(pf_s0_io_tlb_resp_bits_data_s1_entry_tag[13] && pf_s1_io_tlb_resp_bits_data_s1_entry_tag[13])) begin cov_fail++; $display("[COV] PTWFilter.io_tlb_resp_bits_data_s1_entry_tag[13] 未见过 0 和 1"); end
    if (!(pf_s0_io_tlb_resp_bits_data_s1_entry_tag[14] && pf_s1_io_tlb_resp_bits_data_s1_entry_tag[14])) begin cov_fail++; $display("[COV] PTWFilter.io_tlb_resp_bits_data_s1_entry_tag[14] 未见过 0 和 1"); end
    if (!(pf_s0_io_tlb_resp_bits_data_s1_entry_tag[15] && pf_s1_io_tlb_resp_bits_data_s1_entry_tag[15])) begin cov_fail++; $display("[COV] PTWFilter.io_tlb_resp_bits_data_s1_entry_tag[15] 未见过 0 和 1"); end
    if (!(pf_s0_io_tlb_resp_bits_data_s1_entry_tag[16] && pf_s1_io_tlb_resp_bits_data_s1_entry_tag[16])) begin cov_fail++; $display("[COV] PTWFilter.io_tlb_resp_bits_data_s1_entry_tag[16] 未见过 0 和 1"); end
    if (!(pf_s0_io_tlb_resp_bits_data_s1_entry_tag[17] && pf_s1_io_tlb_resp_bits_data_s1_entry_tag[17])) begin cov_fail++; $display("[COV] PTWFilter.io_tlb_resp_bits_data_s1_entry_tag[17] 未见过 0 和 1"); end
    if (!(pf_s0_io_tlb_resp_bits_data_s1_entry_tag[18] && pf_s1_io_tlb_resp_bits_data_s1_entry_tag[18])) begin cov_fail++; $display("[COV] PTWFilter.io_tlb_resp_bits_data_s1_entry_tag[18] 未见过 0 和 1"); end
    if (!(pf_s0_io_tlb_resp_bits_data_s1_entry_tag[19] && pf_s1_io_tlb_resp_bits_data_s1_entry_tag[19])) begin cov_fail++; $display("[COV] PTWFilter.io_tlb_resp_bits_data_s1_entry_tag[19] 未见过 0 和 1"); end
    if (!(pf_s0_io_tlb_resp_bits_data_s1_entry_tag[20] && pf_s1_io_tlb_resp_bits_data_s1_entry_tag[20])) begin cov_fail++; $display("[COV] PTWFilter.io_tlb_resp_bits_data_s1_entry_tag[20] 未见过 0 和 1"); end
    if (!(pf_s0_io_tlb_resp_bits_data_s1_entry_tag[21] && pf_s1_io_tlb_resp_bits_data_s1_entry_tag[21])) begin cov_fail++; $display("[COV] PTWFilter.io_tlb_resp_bits_data_s1_entry_tag[21] 未见过 0 和 1"); end
    if (!(pf_s0_io_tlb_resp_bits_data_s1_entry_tag[22] && pf_s1_io_tlb_resp_bits_data_s1_entry_tag[22])) begin cov_fail++; $display("[COV] PTWFilter.io_tlb_resp_bits_data_s1_entry_tag[22] 未见过 0 和 1"); end
    if (!(pf_s0_io_tlb_resp_bits_data_s1_entry_tag[23] && pf_s1_io_tlb_resp_bits_data_s1_entry_tag[23])) begin cov_fail++; $display("[COV] PTWFilter.io_tlb_resp_bits_data_s1_entry_tag[23] 未见过 0 和 1"); end
    if (!(pf_s0_io_tlb_resp_bits_data_s1_entry_tag[24] && pf_s1_io_tlb_resp_bits_data_s1_entry_tag[24])) begin cov_fail++; $display("[COV] PTWFilter.io_tlb_resp_bits_data_s1_entry_tag[24] 未见过 0 和 1"); end
    if (!(pf_s0_io_tlb_resp_bits_data_s1_entry_tag[25] && pf_s1_io_tlb_resp_bits_data_s1_entry_tag[25])) begin cov_fail++; $display("[COV] PTWFilter.io_tlb_resp_bits_data_s1_entry_tag[25] 未见过 0 和 1"); end
    if (!(pf_s0_io_tlb_resp_bits_data_s1_entry_tag[26] && pf_s1_io_tlb_resp_bits_data_s1_entry_tag[26])) begin cov_fail++; $display("[COV] PTWFilter.io_tlb_resp_bits_data_s1_entry_tag[26] 未见过 0 和 1"); end
    if (!(pf_s0_io_tlb_resp_bits_data_s1_entry_tag[27] && pf_s1_io_tlb_resp_bits_data_s1_entry_tag[27])) begin cov_fail++; $display("[COV] PTWFilter.io_tlb_resp_bits_data_s1_entry_tag[27] 未见过 0 和 1"); end
    if (!(pf_s0_io_tlb_resp_bits_data_s1_entry_tag[28] && pf_s1_io_tlb_resp_bits_data_s1_entry_tag[28])) begin cov_fail++; $display("[COV] PTWFilter.io_tlb_resp_bits_data_s1_entry_tag[28] 未见过 0 和 1"); end
    if (!(pf_s0_io_tlb_resp_bits_data_s1_entry_tag[29] && pf_s1_io_tlb_resp_bits_data_s1_entry_tag[29])) begin cov_fail++; $display("[COV] PTWFilter.io_tlb_resp_bits_data_s1_entry_tag[29] 未见过 0 和 1"); end
    if (!(pf_s0_io_tlb_resp_bits_data_s1_entry_tag[30] && pf_s1_io_tlb_resp_bits_data_s1_entry_tag[30])) begin cov_fail++; $display("[COV] PTWFilter.io_tlb_resp_bits_data_s1_entry_tag[30] 未见过 0 和 1"); end
    if (!(pf_s0_io_tlb_resp_bits_data_s1_entry_tag[31] && pf_s1_io_tlb_resp_bits_data_s1_entry_tag[31])) begin cov_fail++; $display("[COV] PTWFilter.io_tlb_resp_bits_data_s1_entry_tag[31] 未见过 0 和 1"); end
    if (!(pf_s0_io_tlb_resp_bits_data_s1_entry_tag[32] && pf_s1_io_tlb_resp_bits_data_s1_entry_tag[32])) begin cov_fail++; $display("[COV] PTWFilter.io_tlb_resp_bits_data_s1_entry_tag[32] 未见过 0 和 1"); end
    if (!(pf_s0_io_tlb_resp_bits_data_s1_entry_tag[33] && pf_s1_io_tlb_resp_bits_data_s1_entry_tag[33])) begin cov_fail++; $display("[COV] PTWFilter.io_tlb_resp_bits_data_s1_entry_tag[33] 未见过 0 和 1"); end
    if (!(pf_s0_io_tlb_resp_bits_data_s1_entry_tag[34] && pf_s1_io_tlb_resp_bits_data_s1_entry_tag[34])) begin cov_fail++; $display("[COV] PTWFilter.io_tlb_resp_bits_data_s1_entry_tag[34] 未见过 0 和 1"); end
    if (!(pf_s0_io_tlb_resp_bits_data_s1_entry_asid[0] && pf_s1_io_tlb_resp_bits_data_s1_entry_asid[0])) begin cov_fail++; $display("[COV] PTWFilter.io_tlb_resp_bits_data_s1_entry_asid[0] 未见过 0 和 1"); end
    if (!(pf_s0_io_tlb_resp_bits_data_s1_entry_asid[1] && pf_s1_io_tlb_resp_bits_data_s1_entry_asid[1])) begin cov_fail++; $display("[COV] PTWFilter.io_tlb_resp_bits_data_s1_entry_asid[1] 未见过 0 和 1"); end
    if (!(pf_s0_io_tlb_resp_bits_data_s1_entry_asid[2] && pf_s1_io_tlb_resp_bits_data_s1_entry_asid[2])) begin cov_fail++; $display("[COV] PTWFilter.io_tlb_resp_bits_data_s1_entry_asid[2] 未见过 0 和 1"); end
    if (!(pf_s0_io_tlb_resp_bits_data_s1_entry_asid[3] && pf_s1_io_tlb_resp_bits_data_s1_entry_asid[3])) begin cov_fail++; $display("[COV] PTWFilter.io_tlb_resp_bits_data_s1_entry_asid[3] 未见过 0 和 1"); end
    if (!(pf_s0_io_tlb_resp_bits_data_s1_entry_asid[4] && pf_s1_io_tlb_resp_bits_data_s1_entry_asid[4])) begin cov_fail++; $display("[COV] PTWFilter.io_tlb_resp_bits_data_s1_entry_asid[4] 未见过 0 和 1"); end
    if (!(pf_s0_io_tlb_resp_bits_data_s1_entry_asid[5] && pf_s1_io_tlb_resp_bits_data_s1_entry_asid[5])) begin cov_fail++; $display("[COV] PTWFilter.io_tlb_resp_bits_data_s1_entry_asid[5] 未见过 0 和 1"); end
    if (!(pf_s0_io_tlb_resp_bits_data_s1_entry_asid[6] && pf_s1_io_tlb_resp_bits_data_s1_entry_asid[6])) begin cov_fail++; $display("[COV] PTWFilter.io_tlb_resp_bits_data_s1_entry_asid[6] 未见过 0 和 1"); end
    if (!(pf_s0_io_tlb_resp_bits_data_s1_entry_asid[7] && pf_s1_io_tlb_resp_bits_data_s1_entry_asid[7])) begin cov_fail++; $display("[COV] PTWFilter.io_tlb_resp_bits_data_s1_entry_asid[7] 未见过 0 和 1"); end
    if (!(pf_s0_io_tlb_resp_bits_data_s1_entry_asid[8] && pf_s1_io_tlb_resp_bits_data_s1_entry_asid[8])) begin cov_fail++; $display("[COV] PTWFilter.io_tlb_resp_bits_data_s1_entry_asid[8] 未见过 0 和 1"); end
    if (!(pf_s0_io_tlb_resp_bits_data_s1_entry_asid[9] && pf_s1_io_tlb_resp_bits_data_s1_entry_asid[9])) begin cov_fail++; $display("[COV] PTWFilter.io_tlb_resp_bits_data_s1_entry_asid[9] 未见过 0 和 1"); end
    if (!(pf_s0_io_tlb_resp_bits_data_s1_entry_asid[10] && pf_s1_io_tlb_resp_bits_data_s1_entry_asid[10])) begin cov_fail++; $display("[COV] PTWFilter.io_tlb_resp_bits_data_s1_entry_asid[10] 未见过 0 和 1"); end
    if (!(pf_s0_io_tlb_resp_bits_data_s1_entry_asid[11] && pf_s1_io_tlb_resp_bits_data_s1_entry_asid[11])) begin cov_fail++; $display("[COV] PTWFilter.io_tlb_resp_bits_data_s1_entry_asid[11] 未见过 0 和 1"); end
    if (!(pf_s0_io_tlb_resp_bits_data_s1_entry_asid[12] && pf_s1_io_tlb_resp_bits_data_s1_entry_asid[12])) begin cov_fail++; $display("[COV] PTWFilter.io_tlb_resp_bits_data_s1_entry_asid[12] 未见过 0 和 1"); end
    if (!(pf_s0_io_tlb_resp_bits_data_s1_entry_asid[13] && pf_s1_io_tlb_resp_bits_data_s1_entry_asid[13])) begin cov_fail++; $display("[COV] PTWFilter.io_tlb_resp_bits_data_s1_entry_asid[13] 未见过 0 和 1"); end
    if (!(pf_s0_io_tlb_resp_bits_data_s1_entry_asid[14] && pf_s1_io_tlb_resp_bits_data_s1_entry_asid[14])) begin cov_fail++; $display("[COV] PTWFilter.io_tlb_resp_bits_data_s1_entry_asid[14] 未见过 0 和 1"); end
    if (!(pf_s0_io_tlb_resp_bits_data_s1_entry_asid[15] && pf_s1_io_tlb_resp_bits_data_s1_entry_asid[15])) begin cov_fail++; $display("[COV] PTWFilter.io_tlb_resp_bits_data_s1_entry_asid[15] 未见过 0 和 1"); end
    if (!(pf_s0_io_tlb_resp_bits_data_s1_entry_vmid[0] && pf_s1_io_tlb_resp_bits_data_s1_entry_vmid[0])) begin cov_fail++; $display("[COV] PTWFilter.io_tlb_resp_bits_data_s1_entry_vmid[0] 未见过 0 和 1"); end
    if (!(pf_s0_io_tlb_resp_bits_data_s1_entry_vmid[1] && pf_s1_io_tlb_resp_bits_data_s1_entry_vmid[1])) begin cov_fail++; $display("[COV] PTWFilter.io_tlb_resp_bits_data_s1_entry_vmid[1] 未见过 0 和 1"); end
    if (!(pf_s0_io_tlb_resp_bits_data_s1_entry_vmid[2] && pf_s1_io_tlb_resp_bits_data_s1_entry_vmid[2])) begin cov_fail++; $display("[COV] PTWFilter.io_tlb_resp_bits_data_s1_entry_vmid[2] 未见过 0 和 1"); end
    if (!(pf_s0_io_tlb_resp_bits_data_s1_entry_vmid[3] && pf_s1_io_tlb_resp_bits_data_s1_entry_vmid[3])) begin cov_fail++; $display("[COV] PTWFilter.io_tlb_resp_bits_data_s1_entry_vmid[3] 未见过 0 和 1"); end
    if (!(pf_s0_io_tlb_resp_bits_data_s1_entry_vmid[4] && pf_s1_io_tlb_resp_bits_data_s1_entry_vmid[4])) begin cov_fail++; $display("[COV] PTWFilter.io_tlb_resp_bits_data_s1_entry_vmid[4] 未见过 0 和 1"); end
    if (!(pf_s0_io_tlb_resp_bits_data_s1_entry_vmid[5] && pf_s1_io_tlb_resp_bits_data_s1_entry_vmid[5])) begin cov_fail++; $display("[COV] PTWFilter.io_tlb_resp_bits_data_s1_entry_vmid[5] 未见过 0 和 1"); end
    if (!(pf_s0_io_tlb_resp_bits_data_s1_entry_vmid[6] && pf_s1_io_tlb_resp_bits_data_s1_entry_vmid[6])) begin cov_fail++; $display("[COV] PTWFilter.io_tlb_resp_bits_data_s1_entry_vmid[6] 未见过 0 和 1"); end
    if (!(pf_s0_io_tlb_resp_bits_data_s1_entry_vmid[7] && pf_s1_io_tlb_resp_bits_data_s1_entry_vmid[7])) begin cov_fail++; $display("[COV] PTWFilter.io_tlb_resp_bits_data_s1_entry_vmid[7] 未见过 0 和 1"); end
    if (!(pf_s0_io_tlb_resp_bits_data_s1_entry_vmid[8] && pf_s1_io_tlb_resp_bits_data_s1_entry_vmid[8])) begin cov_fail++; $display("[COV] PTWFilter.io_tlb_resp_bits_data_s1_entry_vmid[8] 未见过 0 和 1"); end
    if (!(pf_s0_io_tlb_resp_bits_data_s1_entry_vmid[9] && pf_s1_io_tlb_resp_bits_data_s1_entry_vmid[9])) begin cov_fail++; $display("[COV] PTWFilter.io_tlb_resp_bits_data_s1_entry_vmid[9] 未见过 0 和 1"); end
    if (!(pf_s0_io_tlb_resp_bits_data_s1_entry_vmid[10] && pf_s1_io_tlb_resp_bits_data_s1_entry_vmid[10])) begin cov_fail++; $display("[COV] PTWFilter.io_tlb_resp_bits_data_s1_entry_vmid[10] 未见过 0 和 1"); end
    if (!(pf_s0_io_tlb_resp_bits_data_s1_entry_vmid[11] && pf_s1_io_tlb_resp_bits_data_s1_entry_vmid[11])) begin cov_fail++; $display("[COV] PTWFilter.io_tlb_resp_bits_data_s1_entry_vmid[11] 未见过 0 和 1"); end
    if (!(pf_s0_io_tlb_resp_bits_data_s1_entry_vmid[12] && pf_s1_io_tlb_resp_bits_data_s1_entry_vmid[12])) begin cov_fail++; $display("[COV] PTWFilter.io_tlb_resp_bits_data_s1_entry_vmid[12] 未见过 0 和 1"); end
    if (!(pf_s0_io_tlb_resp_bits_data_s1_entry_vmid[13] && pf_s1_io_tlb_resp_bits_data_s1_entry_vmid[13])) begin cov_fail++; $display("[COV] PTWFilter.io_tlb_resp_bits_data_s1_entry_vmid[13] 未见过 0 和 1"); end
    if (!(pf_s0_io_tlb_resp_bits_data_s1_entry_n && pf_s1_io_tlb_resp_bits_data_s1_entry_n)) begin cov_fail++; $display("[COV] PTWFilter.io_tlb_resp_bits_data_s1_entry_n 未见过 0 和 1"); end
    if (!(pf_s0_io_tlb_resp_bits_data_s1_entry_pbmt[0] && pf_s1_io_tlb_resp_bits_data_s1_entry_pbmt[0])) begin cov_fail++; $display("[COV] PTWFilter.io_tlb_resp_bits_data_s1_entry_pbmt[0] 未见过 0 和 1"); end
    if (!(pf_s0_io_tlb_resp_bits_data_s1_entry_pbmt[1] && pf_s1_io_tlb_resp_bits_data_s1_entry_pbmt[1])) begin cov_fail++; $display("[COV] PTWFilter.io_tlb_resp_bits_data_s1_entry_pbmt[1] 未见过 0 和 1"); end
    if (!(pf_s0_io_tlb_resp_bits_data_s1_entry_perm_d && pf_s1_io_tlb_resp_bits_data_s1_entry_perm_d)) begin cov_fail++; $display("[COV] PTWFilter.io_tlb_resp_bits_data_s1_entry_perm_d 未见过 0 和 1"); end
    if (!(pf_s0_io_tlb_resp_bits_data_s1_entry_perm_a && pf_s1_io_tlb_resp_bits_data_s1_entry_perm_a)) begin cov_fail++; $display("[COV] PTWFilter.io_tlb_resp_bits_data_s1_entry_perm_a 未见过 0 和 1"); end
    if (!(pf_s0_io_tlb_resp_bits_data_s1_entry_perm_g && pf_s1_io_tlb_resp_bits_data_s1_entry_perm_g)) begin cov_fail++; $display("[COV] PTWFilter.io_tlb_resp_bits_data_s1_entry_perm_g 未见过 0 和 1"); end
    if (!(pf_s0_io_tlb_resp_bits_data_s1_entry_perm_u && pf_s1_io_tlb_resp_bits_data_s1_entry_perm_u)) begin cov_fail++; $display("[COV] PTWFilter.io_tlb_resp_bits_data_s1_entry_perm_u 未见过 0 和 1"); end
    if (!(pf_s0_io_tlb_resp_bits_data_s1_entry_perm_x && pf_s1_io_tlb_resp_bits_data_s1_entry_perm_x)) begin cov_fail++; $display("[COV] PTWFilter.io_tlb_resp_bits_data_s1_entry_perm_x 未见过 0 和 1"); end
    if (!(pf_s0_io_tlb_resp_bits_data_s1_entry_perm_w && pf_s1_io_tlb_resp_bits_data_s1_entry_perm_w)) begin cov_fail++; $display("[COV] PTWFilter.io_tlb_resp_bits_data_s1_entry_perm_w 未见过 0 和 1"); end
    if (!(pf_s0_io_tlb_resp_bits_data_s1_entry_perm_r && pf_s1_io_tlb_resp_bits_data_s1_entry_perm_r)) begin cov_fail++; $display("[COV] PTWFilter.io_tlb_resp_bits_data_s1_entry_perm_r 未见过 0 和 1"); end
    if (!(pf_s0_io_tlb_resp_bits_data_s1_entry_level[0] && pf_s1_io_tlb_resp_bits_data_s1_entry_level[0])) begin cov_fail++; $display("[COV] PTWFilter.io_tlb_resp_bits_data_s1_entry_level[0] 未见过 0 和 1"); end
    if (!(pf_s0_io_tlb_resp_bits_data_s1_entry_level[1] && pf_s1_io_tlb_resp_bits_data_s1_entry_level[1])) begin cov_fail++; $display("[COV] PTWFilter.io_tlb_resp_bits_data_s1_entry_level[1] 未见过 0 和 1"); end
    if (!(pf_s0_io_tlb_resp_bits_data_s1_entry_v && pf_s1_io_tlb_resp_bits_data_s1_entry_v)) begin cov_fail++; $display("[COV] PTWFilter.io_tlb_resp_bits_data_s1_entry_v 未见过 0 和 1"); end
    if (!(pf_s0_io_tlb_resp_bits_data_s1_entry_ppn[0] && pf_s1_io_tlb_resp_bits_data_s1_entry_ppn[0])) begin cov_fail++; $display("[COV] PTWFilter.io_tlb_resp_bits_data_s1_entry_ppn[0] 未见过 0 和 1"); end
    if (!(pf_s0_io_tlb_resp_bits_data_s1_entry_ppn[1] && pf_s1_io_tlb_resp_bits_data_s1_entry_ppn[1])) begin cov_fail++; $display("[COV] PTWFilter.io_tlb_resp_bits_data_s1_entry_ppn[1] 未见过 0 和 1"); end
    if (!(pf_s0_io_tlb_resp_bits_data_s1_entry_ppn[2] && pf_s1_io_tlb_resp_bits_data_s1_entry_ppn[2])) begin cov_fail++; $display("[COV] PTWFilter.io_tlb_resp_bits_data_s1_entry_ppn[2] 未见过 0 和 1"); end
    if (!(pf_s0_io_tlb_resp_bits_data_s1_entry_ppn[3] && pf_s1_io_tlb_resp_bits_data_s1_entry_ppn[3])) begin cov_fail++; $display("[COV] PTWFilter.io_tlb_resp_bits_data_s1_entry_ppn[3] 未见过 0 和 1"); end
    if (!(pf_s0_io_tlb_resp_bits_data_s1_entry_ppn[4] && pf_s1_io_tlb_resp_bits_data_s1_entry_ppn[4])) begin cov_fail++; $display("[COV] PTWFilter.io_tlb_resp_bits_data_s1_entry_ppn[4] 未见过 0 和 1"); end
    if (!(pf_s0_io_tlb_resp_bits_data_s1_entry_ppn[5] && pf_s1_io_tlb_resp_bits_data_s1_entry_ppn[5])) begin cov_fail++; $display("[COV] PTWFilter.io_tlb_resp_bits_data_s1_entry_ppn[5] 未见过 0 和 1"); end
    if (!(pf_s0_io_tlb_resp_bits_data_s1_entry_ppn[6] && pf_s1_io_tlb_resp_bits_data_s1_entry_ppn[6])) begin cov_fail++; $display("[COV] PTWFilter.io_tlb_resp_bits_data_s1_entry_ppn[6] 未见过 0 和 1"); end
    if (!(pf_s0_io_tlb_resp_bits_data_s1_entry_ppn[7] && pf_s1_io_tlb_resp_bits_data_s1_entry_ppn[7])) begin cov_fail++; $display("[COV] PTWFilter.io_tlb_resp_bits_data_s1_entry_ppn[7] 未见过 0 和 1"); end
    if (!(pf_s0_io_tlb_resp_bits_data_s1_entry_ppn[8] && pf_s1_io_tlb_resp_bits_data_s1_entry_ppn[8])) begin cov_fail++; $display("[COV] PTWFilter.io_tlb_resp_bits_data_s1_entry_ppn[8] 未见过 0 和 1"); end
    if (!(pf_s0_io_tlb_resp_bits_data_s1_entry_ppn[9] && pf_s1_io_tlb_resp_bits_data_s1_entry_ppn[9])) begin cov_fail++; $display("[COV] PTWFilter.io_tlb_resp_bits_data_s1_entry_ppn[9] 未见过 0 和 1"); end
    if (!(pf_s0_io_tlb_resp_bits_data_s1_entry_ppn[10] && pf_s1_io_tlb_resp_bits_data_s1_entry_ppn[10])) begin cov_fail++; $display("[COV] PTWFilter.io_tlb_resp_bits_data_s1_entry_ppn[10] 未见过 0 和 1"); end
    if (!(pf_s0_io_tlb_resp_bits_data_s1_entry_ppn[11] && pf_s1_io_tlb_resp_bits_data_s1_entry_ppn[11])) begin cov_fail++; $display("[COV] PTWFilter.io_tlb_resp_bits_data_s1_entry_ppn[11] 未见过 0 和 1"); end
    if (!(pf_s0_io_tlb_resp_bits_data_s1_entry_ppn[12] && pf_s1_io_tlb_resp_bits_data_s1_entry_ppn[12])) begin cov_fail++; $display("[COV] PTWFilter.io_tlb_resp_bits_data_s1_entry_ppn[12] 未见过 0 和 1"); end
    if (!(pf_s0_io_tlb_resp_bits_data_s1_entry_ppn[13] && pf_s1_io_tlb_resp_bits_data_s1_entry_ppn[13])) begin cov_fail++; $display("[COV] PTWFilter.io_tlb_resp_bits_data_s1_entry_ppn[13] 未见过 0 和 1"); end
    if (!(pf_s0_io_tlb_resp_bits_data_s1_entry_ppn[14] && pf_s1_io_tlb_resp_bits_data_s1_entry_ppn[14])) begin cov_fail++; $display("[COV] PTWFilter.io_tlb_resp_bits_data_s1_entry_ppn[14] 未见过 0 和 1"); end
    if (!(pf_s0_io_tlb_resp_bits_data_s1_entry_ppn[15] && pf_s1_io_tlb_resp_bits_data_s1_entry_ppn[15])) begin cov_fail++; $display("[COV] PTWFilter.io_tlb_resp_bits_data_s1_entry_ppn[15] 未见过 0 和 1"); end
    if (!(pf_s0_io_tlb_resp_bits_data_s1_entry_ppn[16] && pf_s1_io_tlb_resp_bits_data_s1_entry_ppn[16])) begin cov_fail++; $display("[COV] PTWFilter.io_tlb_resp_bits_data_s1_entry_ppn[16] 未见过 0 和 1"); end
    if (!(pf_s0_io_tlb_resp_bits_data_s1_entry_ppn[17] && pf_s1_io_tlb_resp_bits_data_s1_entry_ppn[17])) begin cov_fail++; $display("[COV] PTWFilter.io_tlb_resp_bits_data_s1_entry_ppn[17] 未见过 0 和 1"); end
    if (!(pf_s0_io_tlb_resp_bits_data_s1_entry_ppn[18] && pf_s1_io_tlb_resp_bits_data_s1_entry_ppn[18])) begin cov_fail++; $display("[COV] PTWFilter.io_tlb_resp_bits_data_s1_entry_ppn[18] 未见过 0 和 1"); end
    if (!(pf_s0_io_tlb_resp_bits_data_s1_entry_ppn[19] && pf_s1_io_tlb_resp_bits_data_s1_entry_ppn[19])) begin cov_fail++; $display("[COV] PTWFilter.io_tlb_resp_bits_data_s1_entry_ppn[19] 未见过 0 和 1"); end
    if (!(pf_s0_io_tlb_resp_bits_data_s1_entry_ppn[20] && pf_s1_io_tlb_resp_bits_data_s1_entry_ppn[20])) begin cov_fail++; $display("[COV] PTWFilter.io_tlb_resp_bits_data_s1_entry_ppn[20] 未见过 0 和 1"); end
    if (!(pf_s0_io_tlb_resp_bits_data_s1_entry_ppn[21] && pf_s1_io_tlb_resp_bits_data_s1_entry_ppn[21])) begin cov_fail++; $display("[COV] PTWFilter.io_tlb_resp_bits_data_s1_entry_ppn[21] 未见过 0 和 1"); end
    if (!(pf_s0_io_tlb_resp_bits_data_s1_entry_ppn[22] && pf_s1_io_tlb_resp_bits_data_s1_entry_ppn[22])) begin cov_fail++; $display("[COV] PTWFilter.io_tlb_resp_bits_data_s1_entry_ppn[22] 未见过 0 和 1"); end
    if (!(pf_s0_io_tlb_resp_bits_data_s1_entry_ppn[23] && pf_s1_io_tlb_resp_bits_data_s1_entry_ppn[23])) begin cov_fail++; $display("[COV] PTWFilter.io_tlb_resp_bits_data_s1_entry_ppn[23] 未见过 0 和 1"); end
    if (!(pf_s0_io_tlb_resp_bits_data_s1_entry_ppn[24] && pf_s1_io_tlb_resp_bits_data_s1_entry_ppn[24])) begin cov_fail++; $display("[COV] PTWFilter.io_tlb_resp_bits_data_s1_entry_ppn[24] 未见过 0 和 1"); end
    if (!(pf_s0_io_tlb_resp_bits_data_s1_entry_ppn[25] && pf_s1_io_tlb_resp_bits_data_s1_entry_ppn[25])) begin cov_fail++; $display("[COV] PTWFilter.io_tlb_resp_bits_data_s1_entry_ppn[25] 未见过 0 和 1"); end
    if (!(pf_s0_io_tlb_resp_bits_data_s1_entry_ppn[26] && pf_s1_io_tlb_resp_bits_data_s1_entry_ppn[26])) begin cov_fail++; $display("[COV] PTWFilter.io_tlb_resp_bits_data_s1_entry_ppn[26] 未见过 0 和 1"); end
    if (!(pf_s0_io_tlb_resp_bits_data_s1_entry_ppn[27] && pf_s1_io_tlb_resp_bits_data_s1_entry_ppn[27])) begin cov_fail++; $display("[COV] PTWFilter.io_tlb_resp_bits_data_s1_entry_ppn[27] 未见过 0 和 1"); end
    if (!(pf_s0_io_tlb_resp_bits_data_s1_entry_ppn[28] && pf_s1_io_tlb_resp_bits_data_s1_entry_ppn[28])) begin cov_fail++; $display("[COV] PTWFilter.io_tlb_resp_bits_data_s1_entry_ppn[28] 未见过 0 和 1"); end
    if (!(pf_s0_io_tlb_resp_bits_data_s1_entry_ppn[29] && pf_s1_io_tlb_resp_bits_data_s1_entry_ppn[29])) begin cov_fail++; $display("[COV] PTWFilter.io_tlb_resp_bits_data_s1_entry_ppn[29] 未见过 0 和 1"); end
    if (!(pf_s0_io_tlb_resp_bits_data_s1_entry_ppn[30] && pf_s1_io_tlb_resp_bits_data_s1_entry_ppn[30])) begin cov_fail++; $display("[COV] PTWFilter.io_tlb_resp_bits_data_s1_entry_ppn[30] 未见过 0 和 1"); end
    if (!(pf_s0_io_tlb_resp_bits_data_s1_entry_ppn[31] && pf_s1_io_tlb_resp_bits_data_s1_entry_ppn[31])) begin cov_fail++; $display("[COV] PTWFilter.io_tlb_resp_bits_data_s1_entry_ppn[31] 未见过 0 和 1"); end
    if (!(pf_s0_io_tlb_resp_bits_data_s1_entry_ppn[32] && pf_s1_io_tlb_resp_bits_data_s1_entry_ppn[32])) begin cov_fail++; $display("[COV] PTWFilter.io_tlb_resp_bits_data_s1_entry_ppn[32] 未见过 0 和 1"); end
    if (!(pf_s0_io_tlb_resp_bits_data_s1_entry_ppn[33] && pf_s1_io_tlb_resp_bits_data_s1_entry_ppn[33])) begin cov_fail++; $display("[COV] PTWFilter.io_tlb_resp_bits_data_s1_entry_ppn[33] 未见过 0 和 1"); end
    if (!(pf_s0_io_tlb_resp_bits_data_s1_entry_ppn[34] && pf_s1_io_tlb_resp_bits_data_s1_entry_ppn[34])) begin cov_fail++; $display("[COV] PTWFilter.io_tlb_resp_bits_data_s1_entry_ppn[34] 未见过 0 和 1"); end
    if (!(pf_s0_io_tlb_resp_bits_data_s1_entry_ppn[35] && pf_s1_io_tlb_resp_bits_data_s1_entry_ppn[35])) begin cov_fail++; $display("[COV] PTWFilter.io_tlb_resp_bits_data_s1_entry_ppn[35] 未见过 0 和 1"); end
    if (!(pf_s0_io_tlb_resp_bits_data_s1_entry_ppn[36] && pf_s1_io_tlb_resp_bits_data_s1_entry_ppn[36])) begin cov_fail++; $display("[COV] PTWFilter.io_tlb_resp_bits_data_s1_entry_ppn[36] 未见过 0 和 1"); end
    if (!(pf_s0_io_tlb_resp_bits_data_s1_entry_ppn[37] && pf_s1_io_tlb_resp_bits_data_s1_entry_ppn[37])) begin cov_fail++; $display("[COV] PTWFilter.io_tlb_resp_bits_data_s1_entry_ppn[37] 未见过 0 和 1"); end
    if (!(pf_s0_io_tlb_resp_bits_data_s1_entry_ppn[38] && pf_s1_io_tlb_resp_bits_data_s1_entry_ppn[38])) begin cov_fail++; $display("[COV] PTWFilter.io_tlb_resp_bits_data_s1_entry_ppn[38] 未见过 0 和 1"); end
    if (!(pf_s0_io_tlb_resp_bits_data_s1_entry_ppn[39] && pf_s1_io_tlb_resp_bits_data_s1_entry_ppn[39])) begin cov_fail++; $display("[COV] PTWFilter.io_tlb_resp_bits_data_s1_entry_ppn[39] 未见过 0 和 1"); end
    if (!(pf_s0_io_tlb_resp_bits_data_s1_entry_ppn[40] && pf_s1_io_tlb_resp_bits_data_s1_entry_ppn[40])) begin cov_fail++; $display("[COV] PTWFilter.io_tlb_resp_bits_data_s1_entry_ppn[40] 未见过 0 和 1"); end
    if (!(pf_s0_io_tlb_resp_bits_data_s1_addr_low[0] && pf_s1_io_tlb_resp_bits_data_s1_addr_low[0])) begin cov_fail++; $display("[COV] PTWFilter.io_tlb_resp_bits_data_s1_addr_low[0] 未见过 0 和 1"); end
    if (!(pf_s0_io_tlb_resp_bits_data_s1_addr_low[1] && pf_s1_io_tlb_resp_bits_data_s1_addr_low[1])) begin cov_fail++; $display("[COV] PTWFilter.io_tlb_resp_bits_data_s1_addr_low[1] 未见过 0 和 1"); end
    if (!(pf_s0_io_tlb_resp_bits_data_s1_addr_low[2] && pf_s1_io_tlb_resp_bits_data_s1_addr_low[2])) begin cov_fail++; $display("[COV] PTWFilter.io_tlb_resp_bits_data_s1_addr_low[2] 未见过 0 和 1"); end
    if (!(pf_s0_io_tlb_resp_bits_data_s1_ppn_low_0[0] && pf_s1_io_tlb_resp_bits_data_s1_ppn_low_0[0])) begin cov_fail++; $display("[COV] PTWFilter.io_tlb_resp_bits_data_s1_ppn_low_0[0] 未见过 0 和 1"); end
    if (!(pf_s0_io_tlb_resp_bits_data_s1_ppn_low_0[1] && pf_s1_io_tlb_resp_bits_data_s1_ppn_low_0[1])) begin cov_fail++; $display("[COV] PTWFilter.io_tlb_resp_bits_data_s1_ppn_low_0[1] 未见过 0 和 1"); end
    if (!(pf_s0_io_tlb_resp_bits_data_s1_ppn_low_0[2] && pf_s1_io_tlb_resp_bits_data_s1_ppn_low_0[2])) begin cov_fail++; $display("[COV] PTWFilter.io_tlb_resp_bits_data_s1_ppn_low_0[2] 未见过 0 和 1"); end
    if (!(pf_s0_io_tlb_resp_bits_data_s1_ppn_low_1[0] && pf_s1_io_tlb_resp_bits_data_s1_ppn_low_1[0])) begin cov_fail++; $display("[COV] PTWFilter.io_tlb_resp_bits_data_s1_ppn_low_1[0] 未见过 0 和 1"); end
    if (!(pf_s0_io_tlb_resp_bits_data_s1_ppn_low_1[1] && pf_s1_io_tlb_resp_bits_data_s1_ppn_low_1[1])) begin cov_fail++; $display("[COV] PTWFilter.io_tlb_resp_bits_data_s1_ppn_low_1[1] 未见过 0 和 1"); end
    if (!(pf_s0_io_tlb_resp_bits_data_s1_ppn_low_1[2] && pf_s1_io_tlb_resp_bits_data_s1_ppn_low_1[2])) begin cov_fail++; $display("[COV] PTWFilter.io_tlb_resp_bits_data_s1_ppn_low_1[2] 未见过 0 和 1"); end
    if (!(pf_s0_io_tlb_resp_bits_data_s1_ppn_low_2[0] && pf_s1_io_tlb_resp_bits_data_s1_ppn_low_2[0])) begin cov_fail++; $display("[COV] PTWFilter.io_tlb_resp_bits_data_s1_ppn_low_2[0] 未见过 0 和 1"); end
    if (!(pf_s0_io_tlb_resp_bits_data_s1_ppn_low_2[1] && pf_s1_io_tlb_resp_bits_data_s1_ppn_low_2[1])) begin cov_fail++; $display("[COV] PTWFilter.io_tlb_resp_bits_data_s1_ppn_low_2[1] 未见过 0 和 1"); end
    if (!(pf_s0_io_tlb_resp_bits_data_s1_ppn_low_2[2] && pf_s1_io_tlb_resp_bits_data_s1_ppn_low_2[2])) begin cov_fail++; $display("[COV] PTWFilter.io_tlb_resp_bits_data_s1_ppn_low_2[2] 未见过 0 和 1"); end
    if (!(pf_s0_io_tlb_resp_bits_data_s1_ppn_low_3[0] && pf_s1_io_tlb_resp_bits_data_s1_ppn_low_3[0])) begin cov_fail++; $display("[COV] PTWFilter.io_tlb_resp_bits_data_s1_ppn_low_3[0] 未见过 0 和 1"); end
    if (!(pf_s0_io_tlb_resp_bits_data_s1_ppn_low_3[1] && pf_s1_io_tlb_resp_bits_data_s1_ppn_low_3[1])) begin cov_fail++; $display("[COV] PTWFilter.io_tlb_resp_bits_data_s1_ppn_low_3[1] 未见过 0 和 1"); end
    if (!(pf_s0_io_tlb_resp_bits_data_s1_ppn_low_3[2] && pf_s1_io_tlb_resp_bits_data_s1_ppn_low_3[2])) begin cov_fail++; $display("[COV] PTWFilter.io_tlb_resp_bits_data_s1_ppn_low_3[2] 未见过 0 和 1"); end
    if (!(pf_s0_io_tlb_resp_bits_data_s1_ppn_low_4[0] && pf_s1_io_tlb_resp_bits_data_s1_ppn_low_4[0])) begin cov_fail++; $display("[COV] PTWFilter.io_tlb_resp_bits_data_s1_ppn_low_4[0] 未见过 0 和 1"); end
    if (!(pf_s0_io_tlb_resp_bits_data_s1_ppn_low_4[1] && pf_s1_io_tlb_resp_bits_data_s1_ppn_low_4[1])) begin cov_fail++; $display("[COV] PTWFilter.io_tlb_resp_bits_data_s1_ppn_low_4[1] 未见过 0 和 1"); end
    if (!(pf_s0_io_tlb_resp_bits_data_s1_ppn_low_4[2] && pf_s1_io_tlb_resp_bits_data_s1_ppn_low_4[2])) begin cov_fail++; $display("[COV] PTWFilter.io_tlb_resp_bits_data_s1_ppn_low_4[2] 未见过 0 和 1"); end
    if (!(pf_s0_io_tlb_resp_bits_data_s1_ppn_low_5[0] && pf_s1_io_tlb_resp_bits_data_s1_ppn_low_5[0])) begin cov_fail++; $display("[COV] PTWFilter.io_tlb_resp_bits_data_s1_ppn_low_5[0] 未见过 0 和 1"); end
    if (!(pf_s0_io_tlb_resp_bits_data_s1_ppn_low_5[1] && pf_s1_io_tlb_resp_bits_data_s1_ppn_low_5[1])) begin cov_fail++; $display("[COV] PTWFilter.io_tlb_resp_bits_data_s1_ppn_low_5[1] 未见过 0 和 1"); end
    if (!(pf_s0_io_tlb_resp_bits_data_s1_ppn_low_5[2] && pf_s1_io_tlb_resp_bits_data_s1_ppn_low_5[2])) begin cov_fail++; $display("[COV] PTWFilter.io_tlb_resp_bits_data_s1_ppn_low_5[2] 未见过 0 和 1"); end
    if (!(pf_s0_io_tlb_resp_bits_data_s1_ppn_low_6[0] && pf_s1_io_tlb_resp_bits_data_s1_ppn_low_6[0])) begin cov_fail++; $display("[COV] PTWFilter.io_tlb_resp_bits_data_s1_ppn_low_6[0] 未见过 0 和 1"); end
    if (!(pf_s0_io_tlb_resp_bits_data_s1_ppn_low_6[1] && pf_s1_io_tlb_resp_bits_data_s1_ppn_low_6[1])) begin cov_fail++; $display("[COV] PTWFilter.io_tlb_resp_bits_data_s1_ppn_low_6[1] 未见过 0 和 1"); end
    if (!(pf_s0_io_tlb_resp_bits_data_s1_ppn_low_6[2] && pf_s1_io_tlb_resp_bits_data_s1_ppn_low_6[2])) begin cov_fail++; $display("[COV] PTWFilter.io_tlb_resp_bits_data_s1_ppn_low_6[2] 未见过 0 和 1"); end
    if (!(pf_s0_io_tlb_resp_bits_data_s1_ppn_low_7[0] && pf_s1_io_tlb_resp_bits_data_s1_ppn_low_7[0])) begin cov_fail++; $display("[COV] PTWFilter.io_tlb_resp_bits_data_s1_ppn_low_7[0] 未见过 0 和 1"); end
    if (!(pf_s0_io_tlb_resp_bits_data_s1_ppn_low_7[1] && pf_s1_io_tlb_resp_bits_data_s1_ppn_low_7[1])) begin cov_fail++; $display("[COV] PTWFilter.io_tlb_resp_bits_data_s1_ppn_low_7[1] 未见过 0 和 1"); end
    if (!(pf_s0_io_tlb_resp_bits_data_s1_ppn_low_7[2] && pf_s1_io_tlb_resp_bits_data_s1_ppn_low_7[2])) begin cov_fail++; $display("[COV] PTWFilter.io_tlb_resp_bits_data_s1_ppn_low_7[2] 未见过 0 和 1"); end
    if (!(pf_s0_io_tlb_resp_bits_data_s1_valididx_0 && pf_s1_io_tlb_resp_bits_data_s1_valididx_0)) begin cov_fail++; $display("[COV] PTWFilter.io_tlb_resp_bits_data_s1_valididx_0 未见过 0 和 1"); end
    if (!(pf_s0_io_tlb_resp_bits_data_s1_valididx_1 && pf_s1_io_tlb_resp_bits_data_s1_valididx_1)) begin cov_fail++; $display("[COV] PTWFilter.io_tlb_resp_bits_data_s1_valididx_1 未见过 0 和 1"); end
    if (!(pf_s0_io_tlb_resp_bits_data_s1_valididx_2 && pf_s1_io_tlb_resp_bits_data_s1_valididx_2)) begin cov_fail++; $display("[COV] PTWFilter.io_tlb_resp_bits_data_s1_valididx_2 未见过 0 和 1"); end
    if (!(pf_s0_io_tlb_resp_bits_data_s1_valididx_3 && pf_s1_io_tlb_resp_bits_data_s1_valididx_3)) begin cov_fail++; $display("[COV] PTWFilter.io_tlb_resp_bits_data_s1_valididx_3 未见过 0 和 1"); end
    if (!(pf_s0_io_tlb_resp_bits_data_s1_valididx_4 && pf_s1_io_tlb_resp_bits_data_s1_valididx_4)) begin cov_fail++; $display("[COV] PTWFilter.io_tlb_resp_bits_data_s1_valididx_4 未见过 0 和 1"); end
    if (!(pf_s0_io_tlb_resp_bits_data_s1_valididx_5 && pf_s1_io_tlb_resp_bits_data_s1_valididx_5)) begin cov_fail++; $display("[COV] PTWFilter.io_tlb_resp_bits_data_s1_valididx_5 未见过 0 和 1"); end
    if (!(pf_s0_io_tlb_resp_bits_data_s1_valididx_6 && pf_s1_io_tlb_resp_bits_data_s1_valididx_6)) begin cov_fail++; $display("[COV] PTWFilter.io_tlb_resp_bits_data_s1_valididx_6 未见过 0 和 1"); end
    if (!(pf_s0_io_tlb_resp_bits_data_s1_valididx_7 && pf_s1_io_tlb_resp_bits_data_s1_valididx_7)) begin cov_fail++; $display("[COV] PTWFilter.io_tlb_resp_bits_data_s1_valididx_7 未见过 0 和 1"); end
    if (!(pf_s0_io_tlb_resp_bits_data_s1_pteidx_0 && pf_s1_io_tlb_resp_bits_data_s1_pteidx_0)) begin cov_fail++; $display("[COV] PTWFilter.io_tlb_resp_bits_data_s1_pteidx_0 未见过 0 和 1"); end
    if (!(pf_s0_io_tlb_resp_bits_data_s1_pteidx_1 && pf_s1_io_tlb_resp_bits_data_s1_pteidx_1)) begin cov_fail++; $display("[COV] PTWFilter.io_tlb_resp_bits_data_s1_pteidx_1 未见过 0 和 1"); end
    if (!(pf_s0_io_tlb_resp_bits_data_s1_pteidx_2 && pf_s1_io_tlb_resp_bits_data_s1_pteidx_2)) begin cov_fail++; $display("[COV] PTWFilter.io_tlb_resp_bits_data_s1_pteidx_2 未见过 0 和 1"); end
    if (!(pf_s0_io_tlb_resp_bits_data_s1_pteidx_3 && pf_s1_io_tlb_resp_bits_data_s1_pteidx_3)) begin cov_fail++; $display("[COV] PTWFilter.io_tlb_resp_bits_data_s1_pteidx_3 未见过 0 和 1"); end
    if (!(pf_s0_io_tlb_resp_bits_data_s1_pteidx_4 && pf_s1_io_tlb_resp_bits_data_s1_pteidx_4)) begin cov_fail++; $display("[COV] PTWFilter.io_tlb_resp_bits_data_s1_pteidx_4 未见过 0 和 1"); end
    if (!(pf_s0_io_tlb_resp_bits_data_s1_pteidx_5 && pf_s1_io_tlb_resp_bits_data_s1_pteidx_5)) begin cov_fail++; $display("[COV] PTWFilter.io_tlb_resp_bits_data_s1_pteidx_5 未见过 0 和 1"); end
    if (!(pf_s0_io_tlb_resp_bits_data_s1_pteidx_6 && pf_s1_io_tlb_resp_bits_data_s1_pteidx_6)) begin cov_fail++; $display("[COV] PTWFilter.io_tlb_resp_bits_data_s1_pteidx_6 未见过 0 和 1"); end
    if (!(pf_s0_io_tlb_resp_bits_data_s1_pteidx_7 && pf_s1_io_tlb_resp_bits_data_s1_pteidx_7)) begin cov_fail++; $display("[COV] PTWFilter.io_tlb_resp_bits_data_s1_pteidx_7 未见过 0 和 1"); end
    if (!(pf_s0_io_tlb_resp_bits_data_s1_pf && pf_s1_io_tlb_resp_bits_data_s1_pf)) begin cov_fail++; $display("[COV] PTWFilter.io_tlb_resp_bits_data_s1_pf 未见过 0 和 1"); end
    if (!(pf_s0_io_tlb_resp_bits_data_s1_af && pf_s1_io_tlb_resp_bits_data_s1_af)) begin cov_fail++; $display("[COV] PTWFilter.io_tlb_resp_bits_data_s1_af 未见过 0 和 1"); end
    if (!(pf_s0_io_tlb_resp_bits_data_s2_entry_tag[0] && pf_s1_io_tlb_resp_bits_data_s2_entry_tag[0])) begin cov_fail++; $display("[COV] PTWFilter.io_tlb_resp_bits_data_s2_entry_tag[0] 未见过 0 和 1"); end
    if (!(pf_s0_io_tlb_resp_bits_data_s2_entry_tag[1] && pf_s1_io_tlb_resp_bits_data_s2_entry_tag[1])) begin cov_fail++; $display("[COV] PTWFilter.io_tlb_resp_bits_data_s2_entry_tag[1] 未见过 0 和 1"); end
    if (!(pf_s0_io_tlb_resp_bits_data_s2_entry_tag[2] && pf_s1_io_tlb_resp_bits_data_s2_entry_tag[2])) begin cov_fail++; $display("[COV] PTWFilter.io_tlb_resp_bits_data_s2_entry_tag[2] 未见过 0 和 1"); end
    if (!(pf_s0_io_tlb_resp_bits_data_s2_entry_tag[3] && pf_s1_io_tlb_resp_bits_data_s2_entry_tag[3])) begin cov_fail++; $display("[COV] PTWFilter.io_tlb_resp_bits_data_s2_entry_tag[3] 未见过 0 和 1"); end
    if (!(pf_s0_io_tlb_resp_bits_data_s2_entry_tag[4] && pf_s1_io_tlb_resp_bits_data_s2_entry_tag[4])) begin cov_fail++; $display("[COV] PTWFilter.io_tlb_resp_bits_data_s2_entry_tag[4] 未见过 0 和 1"); end
    if (!(pf_s0_io_tlb_resp_bits_data_s2_entry_tag[5] && pf_s1_io_tlb_resp_bits_data_s2_entry_tag[5])) begin cov_fail++; $display("[COV] PTWFilter.io_tlb_resp_bits_data_s2_entry_tag[5] 未见过 0 和 1"); end
    if (!(pf_s0_io_tlb_resp_bits_data_s2_entry_tag[6] && pf_s1_io_tlb_resp_bits_data_s2_entry_tag[6])) begin cov_fail++; $display("[COV] PTWFilter.io_tlb_resp_bits_data_s2_entry_tag[6] 未见过 0 和 1"); end
    if (!(pf_s0_io_tlb_resp_bits_data_s2_entry_tag[7] && pf_s1_io_tlb_resp_bits_data_s2_entry_tag[7])) begin cov_fail++; $display("[COV] PTWFilter.io_tlb_resp_bits_data_s2_entry_tag[7] 未见过 0 和 1"); end
    if (!(pf_s0_io_tlb_resp_bits_data_s2_entry_tag[8] && pf_s1_io_tlb_resp_bits_data_s2_entry_tag[8])) begin cov_fail++; $display("[COV] PTWFilter.io_tlb_resp_bits_data_s2_entry_tag[8] 未见过 0 和 1"); end
    if (!(pf_s0_io_tlb_resp_bits_data_s2_entry_tag[9] && pf_s1_io_tlb_resp_bits_data_s2_entry_tag[9])) begin cov_fail++; $display("[COV] PTWFilter.io_tlb_resp_bits_data_s2_entry_tag[9] 未见过 0 和 1"); end
    if (!(pf_s0_io_tlb_resp_bits_data_s2_entry_tag[10] && pf_s1_io_tlb_resp_bits_data_s2_entry_tag[10])) begin cov_fail++; $display("[COV] PTWFilter.io_tlb_resp_bits_data_s2_entry_tag[10] 未见过 0 和 1"); end
    if (!(pf_s0_io_tlb_resp_bits_data_s2_entry_tag[11] && pf_s1_io_tlb_resp_bits_data_s2_entry_tag[11])) begin cov_fail++; $display("[COV] PTWFilter.io_tlb_resp_bits_data_s2_entry_tag[11] 未见过 0 和 1"); end
    if (!(pf_s0_io_tlb_resp_bits_data_s2_entry_tag[12] && pf_s1_io_tlb_resp_bits_data_s2_entry_tag[12])) begin cov_fail++; $display("[COV] PTWFilter.io_tlb_resp_bits_data_s2_entry_tag[12] 未见过 0 和 1"); end
    if (!(pf_s0_io_tlb_resp_bits_data_s2_entry_tag[13] && pf_s1_io_tlb_resp_bits_data_s2_entry_tag[13])) begin cov_fail++; $display("[COV] PTWFilter.io_tlb_resp_bits_data_s2_entry_tag[13] 未见过 0 和 1"); end
    if (!(pf_s0_io_tlb_resp_bits_data_s2_entry_tag[14] && pf_s1_io_tlb_resp_bits_data_s2_entry_tag[14])) begin cov_fail++; $display("[COV] PTWFilter.io_tlb_resp_bits_data_s2_entry_tag[14] 未见过 0 和 1"); end
    if (!(pf_s0_io_tlb_resp_bits_data_s2_entry_tag[15] && pf_s1_io_tlb_resp_bits_data_s2_entry_tag[15])) begin cov_fail++; $display("[COV] PTWFilter.io_tlb_resp_bits_data_s2_entry_tag[15] 未见过 0 和 1"); end
    if (!(pf_s0_io_tlb_resp_bits_data_s2_entry_tag[16] && pf_s1_io_tlb_resp_bits_data_s2_entry_tag[16])) begin cov_fail++; $display("[COV] PTWFilter.io_tlb_resp_bits_data_s2_entry_tag[16] 未见过 0 和 1"); end
    if (!(pf_s0_io_tlb_resp_bits_data_s2_entry_tag[17] && pf_s1_io_tlb_resp_bits_data_s2_entry_tag[17])) begin cov_fail++; $display("[COV] PTWFilter.io_tlb_resp_bits_data_s2_entry_tag[17] 未见过 0 和 1"); end
    if (!(pf_s0_io_tlb_resp_bits_data_s2_entry_tag[18] && pf_s1_io_tlb_resp_bits_data_s2_entry_tag[18])) begin cov_fail++; $display("[COV] PTWFilter.io_tlb_resp_bits_data_s2_entry_tag[18] 未见过 0 和 1"); end
    if (!(pf_s0_io_tlb_resp_bits_data_s2_entry_tag[19] && pf_s1_io_tlb_resp_bits_data_s2_entry_tag[19])) begin cov_fail++; $display("[COV] PTWFilter.io_tlb_resp_bits_data_s2_entry_tag[19] 未见过 0 和 1"); end
    if (!(pf_s0_io_tlb_resp_bits_data_s2_entry_tag[20] && pf_s1_io_tlb_resp_bits_data_s2_entry_tag[20])) begin cov_fail++; $display("[COV] PTWFilter.io_tlb_resp_bits_data_s2_entry_tag[20] 未见过 0 和 1"); end
    if (!(pf_s0_io_tlb_resp_bits_data_s2_entry_tag[21] && pf_s1_io_tlb_resp_bits_data_s2_entry_tag[21])) begin cov_fail++; $display("[COV] PTWFilter.io_tlb_resp_bits_data_s2_entry_tag[21] 未见过 0 和 1"); end
    if (!(pf_s0_io_tlb_resp_bits_data_s2_entry_tag[22] && pf_s1_io_tlb_resp_bits_data_s2_entry_tag[22])) begin cov_fail++; $display("[COV] PTWFilter.io_tlb_resp_bits_data_s2_entry_tag[22] 未见过 0 和 1"); end
    if (!(pf_s0_io_tlb_resp_bits_data_s2_entry_tag[23] && pf_s1_io_tlb_resp_bits_data_s2_entry_tag[23])) begin cov_fail++; $display("[COV] PTWFilter.io_tlb_resp_bits_data_s2_entry_tag[23] 未见过 0 和 1"); end
    if (!(pf_s0_io_tlb_resp_bits_data_s2_entry_tag[24] && pf_s1_io_tlb_resp_bits_data_s2_entry_tag[24])) begin cov_fail++; $display("[COV] PTWFilter.io_tlb_resp_bits_data_s2_entry_tag[24] 未见过 0 和 1"); end
    if (!(pf_s0_io_tlb_resp_bits_data_s2_entry_tag[25] && pf_s1_io_tlb_resp_bits_data_s2_entry_tag[25])) begin cov_fail++; $display("[COV] PTWFilter.io_tlb_resp_bits_data_s2_entry_tag[25] 未见过 0 和 1"); end
    if (!(pf_s0_io_tlb_resp_bits_data_s2_entry_tag[26] && pf_s1_io_tlb_resp_bits_data_s2_entry_tag[26])) begin cov_fail++; $display("[COV] PTWFilter.io_tlb_resp_bits_data_s2_entry_tag[26] 未见过 0 和 1"); end
    if (!(pf_s0_io_tlb_resp_bits_data_s2_entry_tag[27] && pf_s1_io_tlb_resp_bits_data_s2_entry_tag[27])) begin cov_fail++; $display("[COV] PTWFilter.io_tlb_resp_bits_data_s2_entry_tag[27] 未见过 0 和 1"); end
    if (!(pf_s0_io_tlb_resp_bits_data_s2_entry_tag[28] && pf_s1_io_tlb_resp_bits_data_s2_entry_tag[28])) begin cov_fail++; $display("[COV] PTWFilter.io_tlb_resp_bits_data_s2_entry_tag[28] 未见过 0 和 1"); end
    if (!(pf_s0_io_tlb_resp_bits_data_s2_entry_tag[29] && pf_s1_io_tlb_resp_bits_data_s2_entry_tag[29])) begin cov_fail++; $display("[COV] PTWFilter.io_tlb_resp_bits_data_s2_entry_tag[29] 未见过 0 和 1"); end
    if (!(pf_s0_io_tlb_resp_bits_data_s2_entry_tag[30] && pf_s1_io_tlb_resp_bits_data_s2_entry_tag[30])) begin cov_fail++; $display("[COV] PTWFilter.io_tlb_resp_bits_data_s2_entry_tag[30] 未见过 0 和 1"); end
    if (!(pf_s0_io_tlb_resp_bits_data_s2_entry_tag[31] && pf_s1_io_tlb_resp_bits_data_s2_entry_tag[31])) begin cov_fail++; $display("[COV] PTWFilter.io_tlb_resp_bits_data_s2_entry_tag[31] 未见过 0 和 1"); end
    if (!(pf_s0_io_tlb_resp_bits_data_s2_entry_tag[32] && pf_s1_io_tlb_resp_bits_data_s2_entry_tag[32])) begin cov_fail++; $display("[COV] PTWFilter.io_tlb_resp_bits_data_s2_entry_tag[32] 未见过 0 和 1"); end
    if (!(pf_s0_io_tlb_resp_bits_data_s2_entry_tag[33] && pf_s1_io_tlb_resp_bits_data_s2_entry_tag[33])) begin cov_fail++; $display("[COV] PTWFilter.io_tlb_resp_bits_data_s2_entry_tag[33] 未见过 0 和 1"); end
    if (!(pf_s0_io_tlb_resp_bits_data_s2_entry_tag[34] && pf_s1_io_tlb_resp_bits_data_s2_entry_tag[34])) begin cov_fail++; $display("[COV] PTWFilter.io_tlb_resp_bits_data_s2_entry_tag[34] 未见过 0 和 1"); end
    if (!(pf_s0_io_tlb_resp_bits_data_s2_entry_tag[35] && pf_s1_io_tlb_resp_bits_data_s2_entry_tag[35])) begin cov_fail++; $display("[COV] PTWFilter.io_tlb_resp_bits_data_s2_entry_tag[35] 未见过 0 和 1"); end
    if (!(pf_s0_io_tlb_resp_bits_data_s2_entry_tag[36] && pf_s1_io_tlb_resp_bits_data_s2_entry_tag[36])) begin cov_fail++; $display("[COV] PTWFilter.io_tlb_resp_bits_data_s2_entry_tag[36] 未见过 0 和 1"); end
    if (!(pf_s0_io_tlb_resp_bits_data_s2_entry_tag[37] && pf_s1_io_tlb_resp_bits_data_s2_entry_tag[37])) begin cov_fail++; $display("[COV] PTWFilter.io_tlb_resp_bits_data_s2_entry_tag[37] 未见过 0 和 1"); end
    if (!(pf_s0_io_tlb_resp_bits_data_s2_entry_vmid[0] && pf_s1_io_tlb_resp_bits_data_s2_entry_vmid[0])) begin cov_fail++; $display("[COV] PTWFilter.io_tlb_resp_bits_data_s2_entry_vmid[0] 未见过 0 和 1"); end
    if (!(pf_s0_io_tlb_resp_bits_data_s2_entry_vmid[1] && pf_s1_io_tlb_resp_bits_data_s2_entry_vmid[1])) begin cov_fail++; $display("[COV] PTWFilter.io_tlb_resp_bits_data_s2_entry_vmid[1] 未见过 0 和 1"); end
    if (!(pf_s0_io_tlb_resp_bits_data_s2_entry_vmid[2] && pf_s1_io_tlb_resp_bits_data_s2_entry_vmid[2])) begin cov_fail++; $display("[COV] PTWFilter.io_tlb_resp_bits_data_s2_entry_vmid[2] 未见过 0 和 1"); end
    if (!(pf_s0_io_tlb_resp_bits_data_s2_entry_vmid[3] && pf_s1_io_tlb_resp_bits_data_s2_entry_vmid[3])) begin cov_fail++; $display("[COV] PTWFilter.io_tlb_resp_bits_data_s2_entry_vmid[3] 未见过 0 和 1"); end
    if (!(pf_s0_io_tlb_resp_bits_data_s2_entry_vmid[4] && pf_s1_io_tlb_resp_bits_data_s2_entry_vmid[4])) begin cov_fail++; $display("[COV] PTWFilter.io_tlb_resp_bits_data_s2_entry_vmid[4] 未见过 0 和 1"); end
    if (!(pf_s0_io_tlb_resp_bits_data_s2_entry_vmid[5] && pf_s1_io_tlb_resp_bits_data_s2_entry_vmid[5])) begin cov_fail++; $display("[COV] PTWFilter.io_tlb_resp_bits_data_s2_entry_vmid[5] 未见过 0 和 1"); end
    if (!(pf_s0_io_tlb_resp_bits_data_s2_entry_vmid[6] && pf_s1_io_tlb_resp_bits_data_s2_entry_vmid[6])) begin cov_fail++; $display("[COV] PTWFilter.io_tlb_resp_bits_data_s2_entry_vmid[6] 未见过 0 和 1"); end
    if (!(pf_s0_io_tlb_resp_bits_data_s2_entry_vmid[7] && pf_s1_io_tlb_resp_bits_data_s2_entry_vmid[7])) begin cov_fail++; $display("[COV] PTWFilter.io_tlb_resp_bits_data_s2_entry_vmid[7] 未见过 0 和 1"); end
    if (!(pf_s0_io_tlb_resp_bits_data_s2_entry_vmid[8] && pf_s1_io_tlb_resp_bits_data_s2_entry_vmid[8])) begin cov_fail++; $display("[COV] PTWFilter.io_tlb_resp_bits_data_s2_entry_vmid[8] 未见过 0 和 1"); end
    if (!(pf_s0_io_tlb_resp_bits_data_s2_entry_vmid[9] && pf_s1_io_tlb_resp_bits_data_s2_entry_vmid[9])) begin cov_fail++; $display("[COV] PTWFilter.io_tlb_resp_bits_data_s2_entry_vmid[9] 未见过 0 和 1"); end
    if (!(pf_s0_io_tlb_resp_bits_data_s2_entry_vmid[10] && pf_s1_io_tlb_resp_bits_data_s2_entry_vmid[10])) begin cov_fail++; $display("[COV] PTWFilter.io_tlb_resp_bits_data_s2_entry_vmid[10] 未见过 0 和 1"); end
    if (!(pf_s0_io_tlb_resp_bits_data_s2_entry_vmid[11] && pf_s1_io_tlb_resp_bits_data_s2_entry_vmid[11])) begin cov_fail++; $display("[COV] PTWFilter.io_tlb_resp_bits_data_s2_entry_vmid[11] 未见过 0 和 1"); end
    if (!(pf_s0_io_tlb_resp_bits_data_s2_entry_vmid[12] && pf_s1_io_tlb_resp_bits_data_s2_entry_vmid[12])) begin cov_fail++; $display("[COV] PTWFilter.io_tlb_resp_bits_data_s2_entry_vmid[12] 未见过 0 和 1"); end
    if (!(pf_s0_io_tlb_resp_bits_data_s2_entry_vmid[13] && pf_s1_io_tlb_resp_bits_data_s2_entry_vmid[13])) begin cov_fail++; $display("[COV] PTWFilter.io_tlb_resp_bits_data_s2_entry_vmid[13] 未见过 0 和 1"); end
    if (!(pf_s0_io_tlb_resp_bits_data_s2_entry_n && pf_s1_io_tlb_resp_bits_data_s2_entry_n)) begin cov_fail++; $display("[COV] PTWFilter.io_tlb_resp_bits_data_s2_entry_n 未见过 0 和 1"); end
    if (!(pf_s0_io_tlb_resp_bits_data_s2_entry_pbmt[0] && pf_s1_io_tlb_resp_bits_data_s2_entry_pbmt[0])) begin cov_fail++; $display("[COV] PTWFilter.io_tlb_resp_bits_data_s2_entry_pbmt[0] 未见过 0 和 1"); end
    if (!(pf_s0_io_tlb_resp_bits_data_s2_entry_pbmt[1] && pf_s1_io_tlb_resp_bits_data_s2_entry_pbmt[1])) begin cov_fail++; $display("[COV] PTWFilter.io_tlb_resp_bits_data_s2_entry_pbmt[1] 未见过 0 和 1"); end
    if (!(pf_s0_io_tlb_resp_bits_data_s2_entry_ppn[0] && pf_s1_io_tlb_resp_bits_data_s2_entry_ppn[0])) begin cov_fail++; $display("[COV] PTWFilter.io_tlb_resp_bits_data_s2_entry_ppn[0] 未见过 0 和 1"); end
    if (!(pf_s0_io_tlb_resp_bits_data_s2_entry_ppn[1] && pf_s1_io_tlb_resp_bits_data_s2_entry_ppn[1])) begin cov_fail++; $display("[COV] PTWFilter.io_tlb_resp_bits_data_s2_entry_ppn[1] 未见过 0 和 1"); end
    if (!(pf_s0_io_tlb_resp_bits_data_s2_entry_ppn[2] && pf_s1_io_tlb_resp_bits_data_s2_entry_ppn[2])) begin cov_fail++; $display("[COV] PTWFilter.io_tlb_resp_bits_data_s2_entry_ppn[2] 未见过 0 和 1"); end
    if (!(pf_s0_io_tlb_resp_bits_data_s2_entry_ppn[3] && pf_s1_io_tlb_resp_bits_data_s2_entry_ppn[3])) begin cov_fail++; $display("[COV] PTWFilter.io_tlb_resp_bits_data_s2_entry_ppn[3] 未见过 0 和 1"); end
    if (!(pf_s0_io_tlb_resp_bits_data_s2_entry_ppn[4] && pf_s1_io_tlb_resp_bits_data_s2_entry_ppn[4])) begin cov_fail++; $display("[COV] PTWFilter.io_tlb_resp_bits_data_s2_entry_ppn[4] 未见过 0 和 1"); end
    if (!(pf_s0_io_tlb_resp_bits_data_s2_entry_ppn[5] && pf_s1_io_tlb_resp_bits_data_s2_entry_ppn[5])) begin cov_fail++; $display("[COV] PTWFilter.io_tlb_resp_bits_data_s2_entry_ppn[5] 未见过 0 和 1"); end
    if (!(pf_s0_io_tlb_resp_bits_data_s2_entry_ppn[6] && pf_s1_io_tlb_resp_bits_data_s2_entry_ppn[6])) begin cov_fail++; $display("[COV] PTWFilter.io_tlb_resp_bits_data_s2_entry_ppn[6] 未见过 0 和 1"); end
    if (!(pf_s0_io_tlb_resp_bits_data_s2_entry_ppn[7] && pf_s1_io_tlb_resp_bits_data_s2_entry_ppn[7])) begin cov_fail++; $display("[COV] PTWFilter.io_tlb_resp_bits_data_s2_entry_ppn[7] 未见过 0 和 1"); end
    if (!(pf_s0_io_tlb_resp_bits_data_s2_entry_ppn[8] && pf_s1_io_tlb_resp_bits_data_s2_entry_ppn[8])) begin cov_fail++; $display("[COV] PTWFilter.io_tlb_resp_bits_data_s2_entry_ppn[8] 未见过 0 和 1"); end
    if (!(pf_s0_io_tlb_resp_bits_data_s2_entry_ppn[9] && pf_s1_io_tlb_resp_bits_data_s2_entry_ppn[9])) begin cov_fail++; $display("[COV] PTWFilter.io_tlb_resp_bits_data_s2_entry_ppn[9] 未见过 0 和 1"); end
    if (!(pf_s0_io_tlb_resp_bits_data_s2_entry_ppn[10] && pf_s1_io_tlb_resp_bits_data_s2_entry_ppn[10])) begin cov_fail++; $display("[COV] PTWFilter.io_tlb_resp_bits_data_s2_entry_ppn[10] 未见过 0 和 1"); end
    if (!(pf_s0_io_tlb_resp_bits_data_s2_entry_ppn[11] && pf_s1_io_tlb_resp_bits_data_s2_entry_ppn[11])) begin cov_fail++; $display("[COV] PTWFilter.io_tlb_resp_bits_data_s2_entry_ppn[11] 未见过 0 和 1"); end
    if (!(pf_s0_io_tlb_resp_bits_data_s2_entry_ppn[12] && pf_s1_io_tlb_resp_bits_data_s2_entry_ppn[12])) begin cov_fail++; $display("[COV] PTWFilter.io_tlb_resp_bits_data_s2_entry_ppn[12] 未见过 0 和 1"); end
    if (!(pf_s0_io_tlb_resp_bits_data_s2_entry_ppn[13] && pf_s1_io_tlb_resp_bits_data_s2_entry_ppn[13])) begin cov_fail++; $display("[COV] PTWFilter.io_tlb_resp_bits_data_s2_entry_ppn[13] 未见过 0 和 1"); end
    if (!(pf_s0_io_tlb_resp_bits_data_s2_entry_ppn[14] && pf_s1_io_tlb_resp_bits_data_s2_entry_ppn[14])) begin cov_fail++; $display("[COV] PTWFilter.io_tlb_resp_bits_data_s2_entry_ppn[14] 未见过 0 和 1"); end
    if (!(pf_s0_io_tlb_resp_bits_data_s2_entry_ppn[15] && pf_s1_io_tlb_resp_bits_data_s2_entry_ppn[15])) begin cov_fail++; $display("[COV] PTWFilter.io_tlb_resp_bits_data_s2_entry_ppn[15] 未见过 0 和 1"); end
    if (!(pf_s0_io_tlb_resp_bits_data_s2_entry_ppn[16] && pf_s1_io_tlb_resp_bits_data_s2_entry_ppn[16])) begin cov_fail++; $display("[COV] PTWFilter.io_tlb_resp_bits_data_s2_entry_ppn[16] 未见过 0 和 1"); end
    if (!(pf_s0_io_tlb_resp_bits_data_s2_entry_ppn[17] && pf_s1_io_tlb_resp_bits_data_s2_entry_ppn[17])) begin cov_fail++; $display("[COV] PTWFilter.io_tlb_resp_bits_data_s2_entry_ppn[17] 未见过 0 和 1"); end
    if (!(pf_s0_io_tlb_resp_bits_data_s2_entry_ppn[18] && pf_s1_io_tlb_resp_bits_data_s2_entry_ppn[18])) begin cov_fail++; $display("[COV] PTWFilter.io_tlb_resp_bits_data_s2_entry_ppn[18] 未见过 0 和 1"); end
    if (!(pf_s0_io_tlb_resp_bits_data_s2_entry_ppn[19] && pf_s1_io_tlb_resp_bits_data_s2_entry_ppn[19])) begin cov_fail++; $display("[COV] PTWFilter.io_tlb_resp_bits_data_s2_entry_ppn[19] 未见过 0 和 1"); end
    if (!(pf_s0_io_tlb_resp_bits_data_s2_entry_ppn[20] && pf_s1_io_tlb_resp_bits_data_s2_entry_ppn[20])) begin cov_fail++; $display("[COV] PTWFilter.io_tlb_resp_bits_data_s2_entry_ppn[20] 未见过 0 和 1"); end
    if (!(pf_s0_io_tlb_resp_bits_data_s2_entry_ppn[21] && pf_s1_io_tlb_resp_bits_data_s2_entry_ppn[21])) begin cov_fail++; $display("[COV] PTWFilter.io_tlb_resp_bits_data_s2_entry_ppn[21] 未见过 0 和 1"); end
    if (!(pf_s0_io_tlb_resp_bits_data_s2_entry_ppn[22] && pf_s1_io_tlb_resp_bits_data_s2_entry_ppn[22])) begin cov_fail++; $display("[COV] PTWFilter.io_tlb_resp_bits_data_s2_entry_ppn[22] 未见过 0 和 1"); end
    if (!(pf_s0_io_tlb_resp_bits_data_s2_entry_ppn[23] && pf_s1_io_tlb_resp_bits_data_s2_entry_ppn[23])) begin cov_fail++; $display("[COV] PTWFilter.io_tlb_resp_bits_data_s2_entry_ppn[23] 未见过 0 和 1"); end
    if (!(pf_s0_io_tlb_resp_bits_data_s2_entry_ppn[24] && pf_s1_io_tlb_resp_bits_data_s2_entry_ppn[24])) begin cov_fail++; $display("[COV] PTWFilter.io_tlb_resp_bits_data_s2_entry_ppn[24] 未见过 0 和 1"); end
    if (!(pf_s0_io_tlb_resp_bits_data_s2_entry_ppn[25] && pf_s1_io_tlb_resp_bits_data_s2_entry_ppn[25])) begin cov_fail++; $display("[COV] PTWFilter.io_tlb_resp_bits_data_s2_entry_ppn[25] 未见过 0 和 1"); end
    if (!(pf_s0_io_tlb_resp_bits_data_s2_entry_ppn[26] && pf_s1_io_tlb_resp_bits_data_s2_entry_ppn[26])) begin cov_fail++; $display("[COV] PTWFilter.io_tlb_resp_bits_data_s2_entry_ppn[26] 未见过 0 和 1"); end
    if (!(pf_s0_io_tlb_resp_bits_data_s2_entry_ppn[27] && pf_s1_io_tlb_resp_bits_data_s2_entry_ppn[27])) begin cov_fail++; $display("[COV] PTWFilter.io_tlb_resp_bits_data_s2_entry_ppn[27] 未见过 0 和 1"); end
    if (!(pf_s0_io_tlb_resp_bits_data_s2_entry_ppn[28] && pf_s1_io_tlb_resp_bits_data_s2_entry_ppn[28])) begin cov_fail++; $display("[COV] PTWFilter.io_tlb_resp_bits_data_s2_entry_ppn[28] 未见过 0 和 1"); end
    if (!(pf_s0_io_tlb_resp_bits_data_s2_entry_ppn[29] && pf_s1_io_tlb_resp_bits_data_s2_entry_ppn[29])) begin cov_fail++; $display("[COV] PTWFilter.io_tlb_resp_bits_data_s2_entry_ppn[29] 未见过 0 和 1"); end
    if (!(pf_s0_io_tlb_resp_bits_data_s2_entry_ppn[30] && pf_s1_io_tlb_resp_bits_data_s2_entry_ppn[30])) begin cov_fail++; $display("[COV] PTWFilter.io_tlb_resp_bits_data_s2_entry_ppn[30] 未见过 0 和 1"); end
    if (!(pf_s0_io_tlb_resp_bits_data_s2_entry_ppn[31] && pf_s1_io_tlb_resp_bits_data_s2_entry_ppn[31])) begin cov_fail++; $display("[COV] PTWFilter.io_tlb_resp_bits_data_s2_entry_ppn[31] 未见过 0 和 1"); end
    if (!(pf_s0_io_tlb_resp_bits_data_s2_entry_ppn[32] && pf_s1_io_tlb_resp_bits_data_s2_entry_ppn[32])) begin cov_fail++; $display("[COV] PTWFilter.io_tlb_resp_bits_data_s2_entry_ppn[32] 未见过 0 和 1"); end
    if (!(pf_s0_io_tlb_resp_bits_data_s2_entry_ppn[33] && pf_s1_io_tlb_resp_bits_data_s2_entry_ppn[33])) begin cov_fail++; $display("[COV] PTWFilter.io_tlb_resp_bits_data_s2_entry_ppn[33] 未见过 0 和 1"); end
    if (!(pf_s0_io_tlb_resp_bits_data_s2_entry_ppn[34] && pf_s1_io_tlb_resp_bits_data_s2_entry_ppn[34])) begin cov_fail++; $display("[COV] PTWFilter.io_tlb_resp_bits_data_s2_entry_ppn[34] 未见过 0 和 1"); end
    if (!(pf_s0_io_tlb_resp_bits_data_s2_entry_ppn[35] && pf_s1_io_tlb_resp_bits_data_s2_entry_ppn[35])) begin cov_fail++; $display("[COV] PTWFilter.io_tlb_resp_bits_data_s2_entry_ppn[35] 未见过 0 和 1"); end
    if (!(pf_s0_io_tlb_resp_bits_data_s2_entry_ppn[36] && pf_s1_io_tlb_resp_bits_data_s2_entry_ppn[36])) begin cov_fail++; $display("[COV] PTWFilter.io_tlb_resp_bits_data_s2_entry_ppn[36] 未见过 0 和 1"); end
    if (!(pf_s0_io_tlb_resp_bits_data_s2_entry_ppn[37] && pf_s1_io_tlb_resp_bits_data_s2_entry_ppn[37])) begin cov_fail++; $display("[COV] PTWFilter.io_tlb_resp_bits_data_s2_entry_ppn[37] 未见过 0 和 1"); end
    if (!(pf_s0_io_tlb_resp_bits_data_s2_entry_perm_d && pf_s1_io_tlb_resp_bits_data_s2_entry_perm_d)) begin cov_fail++; $display("[COV] PTWFilter.io_tlb_resp_bits_data_s2_entry_perm_d 未见过 0 和 1"); end
    if (!(pf_s0_io_tlb_resp_bits_data_s2_entry_perm_a && pf_s1_io_tlb_resp_bits_data_s2_entry_perm_a)) begin cov_fail++; $display("[COV] PTWFilter.io_tlb_resp_bits_data_s2_entry_perm_a 未见过 0 和 1"); end
    if (!(pf_s0_io_tlb_resp_bits_data_s2_entry_perm_g && pf_s1_io_tlb_resp_bits_data_s2_entry_perm_g)) begin cov_fail++; $display("[COV] PTWFilter.io_tlb_resp_bits_data_s2_entry_perm_g 未见过 0 和 1"); end
    if (!(pf_s0_io_tlb_resp_bits_data_s2_entry_perm_u && pf_s1_io_tlb_resp_bits_data_s2_entry_perm_u)) begin cov_fail++; $display("[COV] PTWFilter.io_tlb_resp_bits_data_s2_entry_perm_u 未见过 0 和 1"); end
    if (!(pf_s0_io_tlb_resp_bits_data_s2_entry_perm_x && pf_s1_io_tlb_resp_bits_data_s2_entry_perm_x)) begin cov_fail++; $display("[COV] PTWFilter.io_tlb_resp_bits_data_s2_entry_perm_x 未见过 0 和 1"); end
    if (!(pf_s0_io_tlb_resp_bits_data_s2_entry_perm_w && pf_s1_io_tlb_resp_bits_data_s2_entry_perm_w)) begin cov_fail++; $display("[COV] PTWFilter.io_tlb_resp_bits_data_s2_entry_perm_w 未见过 0 和 1"); end
    if (!(pf_s0_io_tlb_resp_bits_data_s2_entry_perm_r && pf_s1_io_tlb_resp_bits_data_s2_entry_perm_r)) begin cov_fail++; $display("[COV] PTWFilter.io_tlb_resp_bits_data_s2_entry_perm_r 未见过 0 和 1"); end
    if (!(pf_s0_io_tlb_resp_bits_data_s2_entry_level[0] && pf_s1_io_tlb_resp_bits_data_s2_entry_level[0])) begin cov_fail++; $display("[COV] PTWFilter.io_tlb_resp_bits_data_s2_entry_level[0] 未见过 0 和 1"); end
    if (!(pf_s0_io_tlb_resp_bits_data_s2_entry_level[1] && pf_s1_io_tlb_resp_bits_data_s2_entry_level[1])) begin cov_fail++; $display("[COV] PTWFilter.io_tlb_resp_bits_data_s2_entry_level[1] 未见过 0 和 1"); end
    if (!(pf_s0_io_tlb_resp_bits_data_s2_gpf && pf_s1_io_tlb_resp_bits_data_s2_gpf)) begin cov_fail++; $display("[COV] PTWFilter.io_tlb_resp_bits_data_s2_gpf 未见过 0 和 1"); end
    if (!(pf_s0_io_tlb_resp_bits_data_s2_gaf && pf_s1_io_tlb_resp_bits_data_s2_gaf)) begin cov_fail++; $display("[COV] PTWFilter.io_tlb_resp_bits_data_s2_gaf 未见过 0 和 1"); end
    if (!(pf_s0_io_tlb_resp_bits_data_getGpa && pf_s1_io_tlb_resp_bits_data_getGpa)) begin cov_fail++; $display("[COV] PTWFilter.io_tlb_resp_bits_data_getGpa 未见过 0 和 1"); end
    if (!(pf_s0_io_ptw_req_0_valid && pf_s1_io_ptw_req_0_valid)) begin cov_fail++; $display("[COV] PTWFilter.io_ptw_req_0_valid 未见过 0 和 1"); end
    if (!(pf_s0_io_ptw_req_0_bits_vpn[0] && pf_s1_io_ptw_req_0_bits_vpn[0])) begin cov_fail++; $display("[COV] PTWFilter.io_ptw_req_0_bits_vpn[0] 未见过 0 和 1"); end
    if (!(pf_s0_io_ptw_req_0_bits_vpn[1] && pf_s1_io_ptw_req_0_bits_vpn[1])) begin cov_fail++; $display("[COV] PTWFilter.io_ptw_req_0_bits_vpn[1] 未见过 0 和 1"); end
    if (!(pf_s0_io_ptw_req_0_bits_vpn[2] && pf_s1_io_ptw_req_0_bits_vpn[2])) begin cov_fail++; $display("[COV] PTWFilter.io_ptw_req_0_bits_vpn[2] 未见过 0 和 1"); end
    if (!(pf_s0_io_ptw_req_0_bits_vpn[3] && pf_s1_io_ptw_req_0_bits_vpn[3])) begin cov_fail++; $display("[COV] PTWFilter.io_ptw_req_0_bits_vpn[3] 未见过 0 和 1"); end
    if (!(pf_s0_io_ptw_req_0_bits_vpn[4] && pf_s1_io_ptw_req_0_bits_vpn[4])) begin cov_fail++; $display("[COV] PTWFilter.io_ptw_req_0_bits_vpn[4] 未见过 0 和 1"); end
    if (!(pf_s0_io_ptw_req_0_bits_vpn[5] && pf_s1_io_ptw_req_0_bits_vpn[5])) begin cov_fail++; $display("[COV] PTWFilter.io_ptw_req_0_bits_vpn[5] 未见过 0 和 1"); end
    if (!(pf_s0_io_ptw_req_0_bits_vpn[6] && pf_s1_io_ptw_req_0_bits_vpn[6])) begin cov_fail++; $display("[COV] PTWFilter.io_ptw_req_0_bits_vpn[6] 未见过 0 和 1"); end
    if (!(pf_s0_io_ptw_req_0_bits_vpn[7] && pf_s1_io_ptw_req_0_bits_vpn[7])) begin cov_fail++; $display("[COV] PTWFilter.io_ptw_req_0_bits_vpn[7] 未见过 0 和 1"); end
    if (!(pf_s0_io_ptw_req_0_bits_vpn[8] && pf_s1_io_ptw_req_0_bits_vpn[8])) begin cov_fail++; $display("[COV] PTWFilter.io_ptw_req_0_bits_vpn[8] 未见过 0 和 1"); end
    if (!(pf_s0_io_ptw_req_0_bits_vpn[9] && pf_s1_io_ptw_req_0_bits_vpn[9])) begin cov_fail++; $display("[COV] PTWFilter.io_ptw_req_0_bits_vpn[9] 未见过 0 和 1"); end
    if (!(pf_s0_io_ptw_req_0_bits_vpn[10] && pf_s1_io_ptw_req_0_bits_vpn[10])) begin cov_fail++; $display("[COV] PTWFilter.io_ptw_req_0_bits_vpn[10] 未见过 0 和 1"); end
    if (!(pf_s0_io_ptw_req_0_bits_vpn[11] && pf_s1_io_ptw_req_0_bits_vpn[11])) begin cov_fail++; $display("[COV] PTWFilter.io_ptw_req_0_bits_vpn[11] 未见过 0 和 1"); end
    if (!(pf_s0_io_ptw_req_0_bits_vpn[12] && pf_s1_io_ptw_req_0_bits_vpn[12])) begin cov_fail++; $display("[COV] PTWFilter.io_ptw_req_0_bits_vpn[12] 未见过 0 和 1"); end
    if (!(pf_s0_io_ptw_req_0_bits_vpn[13] && pf_s1_io_ptw_req_0_bits_vpn[13])) begin cov_fail++; $display("[COV] PTWFilter.io_ptw_req_0_bits_vpn[13] 未见过 0 和 1"); end
    if (!(pf_s0_io_ptw_req_0_bits_vpn[14] && pf_s1_io_ptw_req_0_bits_vpn[14])) begin cov_fail++; $display("[COV] PTWFilter.io_ptw_req_0_bits_vpn[14] 未见过 0 和 1"); end
    if (!(pf_s0_io_ptw_req_0_bits_vpn[15] && pf_s1_io_ptw_req_0_bits_vpn[15])) begin cov_fail++; $display("[COV] PTWFilter.io_ptw_req_0_bits_vpn[15] 未见过 0 和 1"); end
    if (!(pf_s0_io_ptw_req_0_bits_vpn[16] && pf_s1_io_ptw_req_0_bits_vpn[16])) begin cov_fail++; $display("[COV] PTWFilter.io_ptw_req_0_bits_vpn[16] 未见过 0 和 1"); end
    if (!(pf_s0_io_ptw_req_0_bits_vpn[17] && pf_s1_io_ptw_req_0_bits_vpn[17])) begin cov_fail++; $display("[COV] PTWFilter.io_ptw_req_0_bits_vpn[17] 未见过 0 和 1"); end
    if (!(pf_s0_io_ptw_req_0_bits_vpn[18] && pf_s1_io_ptw_req_0_bits_vpn[18])) begin cov_fail++; $display("[COV] PTWFilter.io_ptw_req_0_bits_vpn[18] 未见过 0 和 1"); end
    if (!(pf_s0_io_ptw_req_0_bits_vpn[19] && pf_s1_io_ptw_req_0_bits_vpn[19])) begin cov_fail++; $display("[COV] PTWFilter.io_ptw_req_0_bits_vpn[19] 未见过 0 和 1"); end
    if (!(pf_s0_io_ptw_req_0_bits_vpn[20] && pf_s1_io_ptw_req_0_bits_vpn[20])) begin cov_fail++; $display("[COV] PTWFilter.io_ptw_req_0_bits_vpn[20] 未见过 0 和 1"); end
    if (!(pf_s0_io_ptw_req_0_bits_vpn[21] && pf_s1_io_ptw_req_0_bits_vpn[21])) begin cov_fail++; $display("[COV] PTWFilter.io_ptw_req_0_bits_vpn[21] 未见过 0 和 1"); end
    if (!(pf_s0_io_ptw_req_0_bits_vpn[22] && pf_s1_io_ptw_req_0_bits_vpn[22])) begin cov_fail++; $display("[COV] PTWFilter.io_ptw_req_0_bits_vpn[22] 未见过 0 和 1"); end
    if (!(pf_s0_io_ptw_req_0_bits_vpn[23] && pf_s1_io_ptw_req_0_bits_vpn[23])) begin cov_fail++; $display("[COV] PTWFilter.io_ptw_req_0_bits_vpn[23] 未见过 0 和 1"); end
    if (!(pf_s0_io_ptw_req_0_bits_vpn[24] && pf_s1_io_ptw_req_0_bits_vpn[24])) begin cov_fail++; $display("[COV] PTWFilter.io_ptw_req_0_bits_vpn[24] 未见过 0 和 1"); end
    if (!(pf_s0_io_ptw_req_0_bits_vpn[25] && pf_s1_io_ptw_req_0_bits_vpn[25])) begin cov_fail++; $display("[COV] PTWFilter.io_ptw_req_0_bits_vpn[25] 未见过 0 和 1"); end
    if (!(pf_s0_io_ptw_req_0_bits_vpn[26] && pf_s1_io_ptw_req_0_bits_vpn[26])) begin cov_fail++; $display("[COV] PTWFilter.io_ptw_req_0_bits_vpn[26] 未见过 0 和 1"); end
    if (!(pf_s0_io_ptw_req_0_bits_vpn[27] && pf_s1_io_ptw_req_0_bits_vpn[27])) begin cov_fail++; $display("[COV] PTWFilter.io_ptw_req_0_bits_vpn[27] 未见过 0 和 1"); end
    if (!(pf_s0_io_ptw_req_0_bits_vpn[28] && pf_s1_io_ptw_req_0_bits_vpn[28])) begin cov_fail++; $display("[COV] PTWFilter.io_ptw_req_0_bits_vpn[28] 未见过 0 和 1"); end
    if (!(pf_s0_io_ptw_req_0_bits_vpn[29] && pf_s1_io_ptw_req_0_bits_vpn[29])) begin cov_fail++; $display("[COV] PTWFilter.io_ptw_req_0_bits_vpn[29] 未见过 0 和 1"); end
    if (!(pf_s0_io_ptw_req_0_bits_vpn[30] && pf_s1_io_ptw_req_0_bits_vpn[30])) begin cov_fail++; $display("[COV] PTWFilter.io_ptw_req_0_bits_vpn[30] 未见过 0 和 1"); end
    if (!(pf_s0_io_ptw_req_0_bits_vpn[31] && pf_s1_io_ptw_req_0_bits_vpn[31])) begin cov_fail++; $display("[COV] PTWFilter.io_ptw_req_0_bits_vpn[31] 未见过 0 和 1"); end
    if (!(pf_s0_io_ptw_req_0_bits_vpn[32] && pf_s1_io_ptw_req_0_bits_vpn[32])) begin cov_fail++; $display("[COV] PTWFilter.io_ptw_req_0_bits_vpn[32] 未见过 0 和 1"); end
    if (!(pf_s0_io_ptw_req_0_bits_vpn[33] && pf_s1_io_ptw_req_0_bits_vpn[33])) begin cov_fail++; $display("[COV] PTWFilter.io_ptw_req_0_bits_vpn[33] 未见过 0 和 1"); end
    if (!(pf_s0_io_ptw_req_0_bits_vpn[34] && pf_s1_io_ptw_req_0_bits_vpn[34])) begin cov_fail++; $display("[COV] PTWFilter.io_ptw_req_0_bits_vpn[34] 未见过 0 和 1"); end
    if (!(pf_s0_io_ptw_req_0_bits_vpn[35] && pf_s1_io_ptw_req_0_bits_vpn[35])) begin cov_fail++; $display("[COV] PTWFilter.io_ptw_req_0_bits_vpn[35] 未见过 0 和 1"); end
    if (!(pf_s0_io_ptw_req_0_bits_vpn[36] && pf_s1_io_ptw_req_0_bits_vpn[36])) begin cov_fail++; $display("[COV] PTWFilter.io_ptw_req_0_bits_vpn[36] 未见过 0 和 1"); end
    if (!(pf_s0_io_ptw_req_0_bits_vpn[37] && pf_s1_io_ptw_req_0_bits_vpn[37])) begin cov_fail++; $display("[COV] PTWFilter.io_ptw_req_0_bits_vpn[37] 未见过 0 和 1"); end
    if (!(pf_s0_io_ptw_req_0_bits_s2xlate[0] && pf_s1_io_ptw_req_0_bits_s2xlate[0])) begin cov_fail++; $display("[COV] PTWFilter.io_ptw_req_0_bits_s2xlate[0] 未见过 0 和 1"); end
    if (!(pf_s0_io_ptw_req_0_bits_s2xlate[1] && pf_s1_io_ptw_req_0_bits_s2xlate[1])) begin cov_fail++; $display("[COV] PTWFilter.io_ptw_req_0_bits_s2xlate[1] 未见过 0 和 1"); end
    $display("[ARM] PTWFilter armed_at=%0d", pf_armed_at);
    if (pf_armed_at < 0) begin cov_fail++; $display("[ARM] PTWFilter 从未 arm"); end
    $display("[COV] PTWFilter.enq = %0d", pf_cov_enq);
    if (pf_cov_enq < 50) begin cov_fail++; $display("[COV] PTWFilter.enq < 50"); end
    $display("[COV] PTWFilter.enq2plus = %0d", pf_cov_enq2plus);
    if (pf_cov_enq2plus < 50) begin cov_fail++; $display("[COV] PTWFilter.enq2plus < 50"); end
    $display("[COV] PTWFilter.enq_blocked = %0d", pf_cov_enq_blocked);
    if (pf_cov_enq_blocked < 50) begin cov_fail++; $display("[COV] PTWFilter.enq_blocked < 50"); end
    $display("[COV] PTWFilter.ready_low = %0d", pf_cov_ready_low);
    if (pf_cov_ready_low < 50) begin cov_fail++; $display("[COV] PTWFilter.ready_low < 50"); end
    $display("[COV] PTWFilter.full = %0d", pf_cov_full);
    if (pf_cov_full < 50) begin cov_fail++; $display("[COV] PTWFilter.full < 50"); end
    $display("[COV] PTWFilter.deq = %0d", pf_cov_deq);
    if (pf_cov_deq < 50) begin cov_fail++; $display("[COV] PTWFilter.deq < 50"); end
    $display("[COV] PTWFilter.iss_fire = %0d", pf_cov_iss_fire);
    if (pf_cov_iss_fire < 50) begin cov_fail++; $display("[COV] PTWFilter.iss_fire < 50"); end
    $display("[COV] PTWFilter.iss_skip_dead = %0d", pf_cov_iss_skip_dead);
    if (pf_cov_iss_skip_dead < 50) begin cov_fail++; $display("[COV] PTWFilter.iss_skip_dead < 50"); end
    $display("[COV] PTWFilter.inflight_full = %0d", pf_cov_inflight_full);
    if (pf_cov_inflight_full < 50) begin cov_fail++; $display("[COV] PTWFilter.inflight_full < 50"); end
    $display("[COV] PTWFilter.resp_hit_entry = %0d", pf_cov_resp_hit_entry);
    if (pf_cov_resp_hit_entry < 50) begin cov_fail++; $display("[COV] PTWFilter.resp_hit_entry < 50"); end
    $display("[COV] PTWFilter.resp_miss_all = %0d", pf_cov_resp_miss_all);
    if (pf_cov_resp_miss_all < 50) begin cov_fail++; $display("[COV] PTWFilter.resp_miss_all < 50"); end
    $display("[COV] PTWFilter.tlb_resp = %0d", pf_cov_tlb_resp);
    if (pf_cov_tlb_resp < 50) begin cov_fail++; $display("[COV] PTWFilter.tlb_resp < 50"); end
    $display("[COV] PTWFilter.fake_enq = %0d", pf_cov_fake_enq);
    if (pf_cov_fake_enq < 50) begin cov_fail++; $display("[COV] PTWFilter.fake_enq < 50"); end
    $display("[COV] PTWFilter.merge_last_resp = %0d", pf_cov_merge_last_resp);
    if (pf_cov_merge_last_resp < 50) begin cov_fail++; $display("[COV] PTWFilter.merge_last_resp < 50"); end
    $display("[COV] PTWFilter.merge_old = %0d", pf_cov_merge_old);
    if (pf_cov_merge_old < 50) begin cov_fail++; $display("[COV] PTWFilter.merge_old < 50"); end
    $display("[COV] PTWFilter.merge_port = %0d", pf_cov_merge_port);
    if (pf_cov_merge_port < 50) begin cov_fail++; $display("[COV] PTWFilter.merge_port < 50"); end
    $display("[COV] PTWFilter.flush = %0d", pf_cov_flush);
    if (pf_cov_flush < 50) begin cov_fail++; $display("[COV] PTWFilter.flush < 50"); end
    $display("[COV] PTWFilter.flush_kills_resp = %0d", pf_cov_flush_kills_resp);
    if (pf_cov_flush_kills_resp < 50) begin cov_fail++; $display("[COV] PTWFilter.flush_kills_resp < 50"); end
    $display("[COV] PTWFilter.hit_noS2 = %0d", pf_cov_hit_noS2);
    if (pf_cov_hit_noS2 < 50) begin cov_fail++; $display("[COV] PTWFilter.hit_noS2 < 50"); end
    $display("[COV] PTWFilter.hit_onlyS2 = %0d", pf_cov_hit_onlyS2);
    if (pf_cov_hit_onlyS2 < 50) begin cov_fail++; $display("[COV] PTWFilter.hit_onlyS2 < 50"); end
    $display("[COV] PTWFilter.hit_allS1 = %0d", pf_cov_hit_allS1);
    if (pf_cov_hit_allS1 < 50) begin cov_fail++; $display("[COV] PTWFilter.hit_allS1 < 50"); end
    $display("[COV] PTWFilter.hit_napot = %0d", pf_cov_hit_napot);
    if (pf_cov_hit_napot < 50) begin cov_fail++; $display("[COV] PTWFilter.hit_napot < 50"); end
    $display("[COV] PTWFilter.hit_super = %0d", pf_cov_hit_super);
    if (pf_cov_hit_super < 50) begin cov_fail++; $display("[COV] PTWFilter.hit_super < 50"); end
    $display("[COV] PTWFilter.hit_g = %0d", pf_cov_hit_g);
    if (pf_cov_hit_g < 50) begin cov_fail++; $display("[COV] PTWFilter.hit_g < 50"); end
    $display("[COV] PTWFilter.getGpa = %0d", pf_cov_getGpa);
    if (pf_cov_getGpa < 50) begin cov_fail++; $display("[COV] PTWFilter.getGpa < 50"); end
    $display("checks=%0d errors=%0d cov_fail=%0d", checks, errors, cov_fail);
    if (errors == 0 && cov_fail == 0 && checks > 0) $display("TEST PASSED");
    else $display("TEST FAILED");
    $finish;
  end
endmodule
