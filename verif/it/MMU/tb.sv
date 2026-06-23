// 自动生成：verif/it/MMU/gen_tb.py —— 勿手改
// MMU 簇 IT：golden L2TLB (u_g) vs 全重写 MMU_it (u_i) 双例化（共用同名 golden 子模块/SRAM 宏），
// 约束随机驱动簇边界(TileLink mem 通道 + 2 路 TLB req/resp + CSR distribute + sfence/csr)，
// 逐拍 !$isunknown 比对全部功能输出；DFT/MBIST 旁路输出(bore/sigFromSrams/cg)单列 nonfunc_errors。
`timescale 1ns/1ps
module tb;
  int unsigned NCYCLES = 200000;
  int unsigned WARMUP  = 64;
  bit clk = 0, rst;
  int errors = 0, checks = 0, nonfunc_errors = 0;
  int cyc = 0;
  // 活跃度统计：证明集成确被激励到（PTW 发 mem 请求 / TLB 出 resp / cache 命中等）
  int act_mem_req = 0, act_tlb0_resp = 0, act_tlb1_resp = 0;
  always #5 clk = ~clk;

  // ---- 簇边界输入信号 ----
  logic auto_out_a_ready;
  logic auto_out_d_valid;
  logic [3:0] auto_out_d_bits_opcode;
  logic [2:0] auto_out_d_bits_size;
  logic [2:0] auto_out_d_bits_source;
  logic [255:0] auto_out_d_bits_data;
  logic io_tlb_0_req_0_valid;
  logic [37:0] io_tlb_0_req_0_bits_vpn;
  logic [1:0] io_tlb_0_req_0_bits_s2xlate;
  logic io_tlb_0_resp_ready;
  logic io_tlb_1_req_0_valid;
  logic [37:0] io_tlb_1_req_0_bits_vpn;
  logic [1:0] io_tlb_1_req_0_bits_s2xlate;
  logic io_sfence_valid;
  logic io_sfence_bits_rs1;
  logic io_sfence_bits_rs2;
  logic [49:0] io_sfence_bits_addr;
  logic [15:0] io_sfence_bits_id;
  logic io_sfence_bits_hv;
  logic io_sfence_bits_hg;
  logic io_wfi_wfiReq;
  logic [3:0] io_csr_tlb_satp_mode;
  logic [15:0] io_csr_tlb_satp_asid;
  logic [43:0] io_csr_tlb_satp_ppn;
  logic io_csr_tlb_satp_changed;
  logic [3:0] io_csr_tlb_vsatp_mode;
  logic [15:0] io_csr_tlb_vsatp_asid;
  logic [43:0] io_csr_tlb_vsatp_ppn;
  logic io_csr_tlb_vsatp_changed;
  logic [3:0] io_csr_tlb_hgatp_mode;
  logic [15:0] io_csr_tlb_hgatp_vmid;
  logic [43:0] io_csr_tlb_hgatp_ppn;
  logic io_csr_tlb_hgatp_changed;
  logic io_csr_tlb_priv_mxr;
  logic io_csr_tlb_priv_virt;
  logic io_csr_tlb_mPBMTE;
  logic io_csr_tlb_hPBMTE;
  logic io_csr_distribute_csr_w_valid;
  logic [11:0] io_csr_distribute_csr_w_bits_addr;
  logic [63:0] io_csr_distribute_csr_w_bits_data;
  logic [5:0] boreChildrenBd_bore_array;
  logic boreChildrenBd_bore_all;
  logic boreChildrenBd_bore_req;
  logic boreChildrenBd_bore_writeen;
  logic [1:0] boreChildrenBd_bore_be;
  logic [3:0] boreChildrenBd_bore_addr;
  logic [199:0] boreChildrenBd_bore_indata;
  logic boreChildrenBd_bore_readen;
  logic [3:0] boreChildrenBd_bore_addr_rd;
  logic [5:0] boreChildrenBd_bore_1_array;
  logic boreChildrenBd_bore_1_all;
  logic boreChildrenBd_bore_1_req;
  logic boreChildrenBd_bore_1_writeen;
  logic [1:0] boreChildrenBd_bore_1_be;
  logic [5:0] boreChildrenBd_bore_1_addr;
  logic [227:0] boreChildrenBd_bore_1_indata;
  logic boreChildrenBd_bore_1_readen;
  logic [5:0] boreChildrenBd_bore_1_addr_rd;
  logic sigFromSrams_bore_ram_hold;
  logic sigFromSrams_bore_ram_bypass;
  logic sigFromSrams_bore_ram_bp_clken;
  logic sigFromSrams_bore_ram_aux_clk;
  logic sigFromSrams_bore_ram_aux_ckbp;
  logic sigFromSrams_bore_ram_mcp_hold;
  logic sigFromSrams_bore_cgen;
  logic sigFromSrams_bore_1_ram_hold;
  logic sigFromSrams_bore_1_ram_bypass;
  logic sigFromSrams_bore_1_ram_bp_clken;
  logic sigFromSrams_bore_1_ram_aux_clk;
  logic sigFromSrams_bore_1_ram_aux_ckbp;
  logic sigFromSrams_bore_1_ram_mcp_hold;
  logic sigFromSrams_bore_1_cgen;
  logic sigFromSrams_bore_2_ram_hold;
  logic sigFromSrams_bore_2_ram_bypass;
  logic sigFromSrams_bore_2_ram_bp_clken;
  logic sigFromSrams_bore_2_ram_aux_clk;
  logic sigFromSrams_bore_2_ram_aux_ckbp;
  logic sigFromSrams_bore_2_ram_mcp_hold;
  logic sigFromSrams_bore_2_cgen;
  logic sigFromSrams_bore_3_ram_hold;
  logic sigFromSrams_bore_3_ram_bypass;
  logic sigFromSrams_bore_3_ram_bp_clken;
  logic sigFromSrams_bore_3_ram_aux_clk;
  logic sigFromSrams_bore_3_ram_aux_ckbp;
  logic sigFromSrams_bore_3_ram_mcp_hold;
  logic sigFromSrams_bore_3_cgen;
  logic sigFromSrams_bore_4_ram_hold;
  logic sigFromSrams_bore_4_ram_bypass;
  logic sigFromSrams_bore_4_ram_bp_clken;
  logic sigFromSrams_bore_4_ram_aux_clk;
  logic sigFromSrams_bore_4_ram_aux_ckbp;
  logic sigFromSrams_bore_4_ram_mcp_hold;
  logic sigFromSrams_bore_4_cgen;
  logic sigFromSrams_bore_5_ram_hold;
  logic sigFromSrams_bore_5_ram_bypass;
  logic sigFromSrams_bore_5_ram_bp_clken;
  logic sigFromSrams_bore_5_ram_aux_clk;
  logic sigFromSrams_bore_5_ram_aux_ckbp;
  logic sigFromSrams_bore_5_ram_mcp_hold;
  logic sigFromSrams_bore_5_cgen;
  logic sigFromSrams_bore_6_ram_hold;
  logic sigFromSrams_bore_6_ram_bypass;
  logic sigFromSrams_bore_6_ram_bp_clken;
  logic sigFromSrams_bore_6_ram_aux_clk;
  logic sigFromSrams_bore_6_ram_aux_ckbp;
  logic sigFromSrams_bore_6_ram_mcp_hold;
  logic sigFromSrams_bore_6_cgen;
  logic sigFromSrams_bore_7_ram_hold;
  logic sigFromSrams_bore_7_ram_bypass;
  logic sigFromSrams_bore_7_ram_bp_clken;
  logic sigFromSrams_bore_7_ram_aux_clk;
  logic sigFromSrams_bore_7_ram_aux_ckbp;
  logic sigFromSrams_bore_7_ram_mcp_hold;
  logic sigFromSrams_bore_7_cgen;
  logic sigFromSrams_bore_8_ram_hold;
  logic sigFromSrams_bore_8_ram_bypass;
  logic sigFromSrams_bore_8_ram_bp_clken;
  logic sigFromSrams_bore_8_ram_aux_clk;
  logic sigFromSrams_bore_8_ram_aux_ckbp;
  logic sigFromSrams_bore_8_ram_mcp_hold;
  logic sigFromSrams_bore_8_cgen;
  logic sigFromSrams_bore_9_ram_hold;
  logic sigFromSrams_bore_9_ram_bypass;
  logic sigFromSrams_bore_9_ram_bp_clken;
  logic sigFromSrams_bore_9_ram_aux_clk;
  logic sigFromSrams_bore_9_ram_aux_ckbp;
  logic sigFromSrams_bore_9_ram_mcp_hold;
  logic sigFromSrams_bore_9_cgen;
  logic sigFromSrams_bore_10_ram_hold;
  logic sigFromSrams_bore_10_ram_bypass;
  logic sigFromSrams_bore_10_ram_bp_clken;
  logic sigFromSrams_bore_10_ram_aux_clk;
  logic sigFromSrams_bore_10_ram_aux_ckbp;
  logic sigFromSrams_bore_10_ram_mcp_hold;
  logic sigFromSrams_bore_10_cgen;
  logic sigFromSrams_bore_11_ram_hold;
  logic sigFromSrams_bore_11_ram_bypass;
  logic sigFromSrams_bore_11_ram_bp_clken;
  logic sigFromSrams_bore_11_ram_aux_clk;
  logic sigFromSrams_bore_11_ram_aux_ckbp;
  logic sigFromSrams_bore_11_ram_mcp_hold;
  logic sigFromSrams_bore_11_cgen;
  logic cg_bore_cgen;

  // ---- golden(g_) / it(i_) 各自输出信号 ----
  logic g_auto_out_a_valid;
  logic [2:0] g_auto_out_a_bits_source;
  logic [47:0] g_auto_out_a_bits_address;
  logic g_io_tlb_0_req_0_ready;
  logic g_io_tlb_0_resp_valid;
  logic [1:0] g_io_tlb_0_resp_bits_s2xlate;
  logic [34:0] g_io_tlb_0_resp_bits_s1_entry_tag;
  logic [15:0] g_io_tlb_0_resp_bits_s1_entry_asid;
  logic [13:0] g_io_tlb_0_resp_bits_s1_entry_vmid;
  logic g_io_tlb_0_resp_bits_s1_entry_n;
  logic [1:0] g_io_tlb_0_resp_bits_s1_entry_pbmt;
  logic g_io_tlb_0_resp_bits_s1_entry_perm_d;
  logic g_io_tlb_0_resp_bits_s1_entry_perm_a;
  logic g_io_tlb_0_resp_bits_s1_entry_perm_g;
  logic g_io_tlb_0_resp_bits_s1_entry_perm_u;
  logic g_io_tlb_0_resp_bits_s1_entry_perm_x;
  logic g_io_tlb_0_resp_bits_s1_entry_perm_w;
  logic g_io_tlb_0_resp_bits_s1_entry_perm_r;
  logic [1:0] g_io_tlb_0_resp_bits_s1_entry_level;
  logic g_io_tlb_0_resp_bits_s1_entry_v;
  logic [40:0] g_io_tlb_0_resp_bits_s1_entry_ppn;
  logic [2:0] g_io_tlb_0_resp_bits_s1_addr_low;
  logic [2:0] g_io_tlb_0_resp_bits_s1_ppn_low_0;
  logic [2:0] g_io_tlb_0_resp_bits_s1_ppn_low_1;
  logic [2:0] g_io_tlb_0_resp_bits_s1_ppn_low_2;
  logic [2:0] g_io_tlb_0_resp_bits_s1_ppn_low_3;
  logic [2:0] g_io_tlb_0_resp_bits_s1_ppn_low_4;
  logic [2:0] g_io_tlb_0_resp_bits_s1_ppn_low_5;
  logic [2:0] g_io_tlb_0_resp_bits_s1_ppn_low_6;
  logic [2:0] g_io_tlb_0_resp_bits_s1_ppn_low_7;
  logic g_io_tlb_0_resp_bits_s1_valididx_0;
  logic g_io_tlb_0_resp_bits_s1_valididx_1;
  logic g_io_tlb_0_resp_bits_s1_valididx_2;
  logic g_io_tlb_0_resp_bits_s1_valididx_3;
  logic g_io_tlb_0_resp_bits_s1_valididx_4;
  logic g_io_tlb_0_resp_bits_s1_valididx_5;
  logic g_io_tlb_0_resp_bits_s1_valididx_6;
  logic g_io_tlb_0_resp_bits_s1_valididx_7;
  logic g_io_tlb_0_resp_bits_s1_pteidx_0;
  logic g_io_tlb_0_resp_bits_s1_pteidx_1;
  logic g_io_tlb_0_resp_bits_s1_pteidx_2;
  logic g_io_tlb_0_resp_bits_s1_pteidx_3;
  logic g_io_tlb_0_resp_bits_s1_pteidx_4;
  logic g_io_tlb_0_resp_bits_s1_pteidx_5;
  logic g_io_tlb_0_resp_bits_s1_pteidx_6;
  logic g_io_tlb_0_resp_bits_s1_pteidx_7;
  logic g_io_tlb_0_resp_bits_s1_pf;
  logic g_io_tlb_0_resp_bits_s1_af;
  logic [37:0] g_io_tlb_0_resp_bits_s2_entry_tag;
  logic [13:0] g_io_tlb_0_resp_bits_s2_entry_vmid;
  logic g_io_tlb_0_resp_bits_s2_entry_n;
  logic [1:0] g_io_tlb_0_resp_bits_s2_entry_pbmt;
  logic [37:0] g_io_tlb_0_resp_bits_s2_entry_ppn;
  logic g_io_tlb_0_resp_bits_s2_entry_perm_d;
  logic g_io_tlb_0_resp_bits_s2_entry_perm_a;
  logic g_io_tlb_0_resp_bits_s2_entry_perm_g;
  logic g_io_tlb_0_resp_bits_s2_entry_perm_u;
  logic g_io_tlb_0_resp_bits_s2_entry_perm_x;
  logic g_io_tlb_0_resp_bits_s2_entry_perm_w;
  logic g_io_tlb_0_resp_bits_s2_entry_perm_r;
  logic [1:0] g_io_tlb_0_resp_bits_s2_entry_level;
  logic g_io_tlb_0_resp_bits_s2_gpf;
  logic g_io_tlb_0_resp_bits_s2_gaf;
  logic g_io_tlb_1_req_0_ready;
  logic g_io_tlb_1_resp_valid;
  logic [1:0] g_io_tlb_1_resp_bits_s2xlate;
  logic [34:0] g_io_tlb_1_resp_bits_s1_entry_tag;
  logic [15:0] g_io_tlb_1_resp_bits_s1_entry_asid;
  logic [13:0] g_io_tlb_1_resp_bits_s1_entry_vmid;
  logic g_io_tlb_1_resp_bits_s1_entry_n;
  logic [1:0] g_io_tlb_1_resp_bits_s1_entry_pbmt;
  logic g_io_tlb_1_resp_bits_s1_entry_perm_d;
  logic g_io_tlb_1_resp_bits_s1_entry_perm_a;
  logic g_io_tlb_1_resp_bits_s1_entry_perm_g;
  logic g_io_tlb_1_resp_bits_s1_entry_perm_u;
  logic g_io_tlb_1_resp_bits_s1_entry_perm_x;
  logic g_io_tlb_1_resp_bits_s1_entry_perm_w;
  logic g_io_tlb_1_resp_bits_s1_entry_perm_r;
  logic [1:0] g_io_tlb_1_resp_bits_s1_entry_level;
  logic g_io_tlb_1_resp_bits_s1_entry_v;
  logic [40:0] g_io_tlb_1_resp_bits_s1_entry_ppn;
  logic [2:0] g_io_tlb_1_resp_bits_s1_addr_low;
  logic [2:0] g_io_tlb_1_resp_bits_s1_ppn_low_0;
  logic [2:0] g_io_tlb_1_resp_bits_s1_ppn_low_1;
  logic [2:0] g_io_tlb_1_resp_bits_s1_ppn_low_2;
  logic [2:0] g_io_tlb_1_resp_bits_s1_ppn_low_3;
  logic [2:0] g_io_tlb_1_resp_bits_s1_ppn_low_4;
  logic [2:0] g_io_tlb_1_resp_bits_s1_ppn_low_5;
  logic [2:0] g_io_tlb_1_resp_bits_s1_ppn_low_6;
  logic [2:0] g_io_tlb_1_resp_bits_s1_ppn_low_7;
  logic g_io_tlb_1_resp_bits_s1_valididx_0;
  logic g_io_tlb_1_resp_bits_s1_valididx_1;
  logic g_io_tlb_1_resp_bits_s1_valididx_2;
  logic g_io_tlb_1_resp_bits_s1_valididx_3;
  logic g_io_tlb_1_resp_bits_s1_valididx_4;
  logic g_io_tlb_1_resp_bits_s1_valididx_5;
  logic g_io_tlb_1_resp_bits_s1_valididx_6;
  logic g_io_tlb_1_resp_bits_s1_valididx_7;
  logic g_io_tlb_1_resp_bits_s1_pteidx_0;
  logic g_io_tlb_1_resp_bits_s1_pteidx_1;
  logic g_io_tlb_1_resp_bits_s1_pteidx_2;
  logic g_io_tlb_1_resp_bits_s1_pteidx_3;
  logic g_io_tlb_1_resp_bits_s1_pteidx_4;
  logic g_io_tlb_1_resp_bits_s1_pteidx_5;
  logic g_io_tlb_1_resp_bits_s1_pteidx_6;
  logic g_io_tlb_1_resp_bits_s1_pteidx_7;
  logic g_io_tlb_1_resp_bits_s1_pf;
  logic g_io_tlb_1_resp_bits_s1_af;
  logic [37:0] g_io_tlb_1_resp_bits_s2_entry_tag;
  logic [13:0] g_io_tlb_1_resp_bits_s2_entry_vmid;
  logic g_io_tlb_1_resp_bits_s2_entry_n;
  logic [1:0] g_io_tlb_1_resp_bits_s2_entry_pbmt;
  logic [37:0] g_io_tlb_1_resp_bits_s2_entry_ppn;
  logic g_io_tlb_1_resp_bits_s2_entry_perm_d;
  logic g_io_tlb_1_resp_bits_s2_entry_perm_a;
  logic g_io_tlb_1_resp_bits_s2_entry_perm_g;
  logic g_io_tlb_1_resp_bits_s2_entry_perm_u;
  logic g_io_tlb_1_resp_bits_s2_entry_perm_x;
  logic g_io_tlb_1_resp_bits_s2_entry_perm_w;
  logic g_io_tlb_1_resp_bits_s2_entry_perm_r;
  logic [1:0] g_io_tlb_1_resp_bits_s2_entry_level;
  logic g_io_tlb_1_resp_bits_s2_gpf;
  logic g_io_tlb_1_resp_bits_s2_gaf;
  logic g_io_wfi_wfiSafe;
  logic [5:0] g_io_perf_0_value;
  logic [5:0] g_io_perf_1_value;
  logic [5:0] g_io_perf_2_value;
  logic [5:0] g_io_perf_3_value;
  logic [5:0] g_io_perf_4_value;
  logic [5:0] g_io_perf_5_value;
  logic [5:0] g_io_perf_6_value;
  logic [5:0] g_io_perf_7_value;
  logic [5:0] g_io_perf_8_value;
  logic [5:0] g_io_perf_9_value;
  logic [5:0] g_io_perf_10_value;
  logic [5:0] g_io_perf_11_value;
  logic [5:0] g_io_perf_12_value;
  logic [5:0] g_io_perf_13_value;
  logic [5:0] g_io_perf_14_value;
  logic [5:0] g_io_perf_15_value;
  logic [5:0] g_io_perf_16_value;
  logic [5:0] g_io_perf_17_value;
  logic [5:0] g_io_perf_18_value;
  logic g_boreChildrenBd_bore_ack;
  logic [199:0] g_boreChildrenBd_bore_outdata;
  logic g_boreChildrenBd_bore_1_ack;
  logic [227:0] g_boreChildrenBd_bore_1_outdata;
  logic i_auto_out_a_valid;
  logic [2:0] i_auto_out_a_bits_source;
  logic [47:0] i_auto_out_a_bits_address;
  logic i_io_tlb_0_req_0_ready;
  logic i_io_tlb_0_resp_valid;
  logic [1:0] i_io_tlb_0_resp_bits_s2xlate;
  logic [34:0] i_io_tlb_0_resp_bits_s1_entry_tag;
  logic [15:0] i_io_tlb_0_resp_bits_s1_entry_asid;
  logic [13:0] i_io_tlb_0_resp_bits_s1_entry_vmid;
  logic i_io_tlb_0_resp_bits_s1_entry_n;
  logic [1:0] i_io_tlb_0_resp_bits_s1_entry_pbmt;
  logic i_io_tlb_0_resp_bits_s1_entry_perm_d;
  logic i_io_tlb_0_resp_bits_s1_entry_perm_a;
  logic i_io_tlb_0_resp_bits_s1_entry_perm_g;
  logic i_io_tlb_0_resp_bits_s1_entry_perm_u;
  logic i_io_tlb_0_resp_bits_s1_entry_perm_x;
  logic i_io_tlb_0_resp_bits_s1_entry_perm_w;
  logic i_io_tlb_0_resp_bits_s1_entry_perm_r;
  logic [1:0] i_io_tlb_0_resp_bits_s1_entry_level;
  logic i_io_tlb_0_resp_bits_s1_entry_v;
  logic [40:0] i_io_tlb_0_resp_bits_s1_entry_ppn;
  logic [2:0] i_io_tlb_0_resp_bits_s1_addr_low;
  logic [2:0] i_io_tlb_0_resp_bits_s1_ppn_low_0;
  logic [2:0] i_io_tlb_0_resp_bits_s1_ppn_low_1;
  logic [2:0] i_io_tlb_0_resp_bits_s1_ppn_low_2;
  logic [2:0] i_io_tlb_0_resp_bits_s1_ppn_low_3;
  logic [2:0] i_io_tlb_0_resp_bits_s1_ppn_low_4;
  logic [2:0] i_io_tlb_0_resp_bits_s1_ppn_low_5;
  logic [2:0] i_io_tlb_0_resp_bits_s1_ppn_low_6;
  logic [2:0] i_io_tlb_0_resp_bits_s1_ppn_low_7;
  logic i_io_tlb_0_resp_bits_s1_valididx_0;
  logic i_io_tlb_0_resp_bits_s1_valididx_1;
  logic i_io_tlb_0_resp_bits_s1_valididx_2;
  logic i_io_tlb_0_resp_bits_s1_valididx_3;
  logic i_io_tlb_0_resp_bits_s1_valididx_4;
  logic i_io_tlb_0_resp_bits_s1_valididx_5;
  logic i_io_tlb_0_resp_bits_s1_valididx_6;
  logic i_io_tlb_0_resp_bits_s1_valididx_7;
  logic i_io_tlb_0_resp_bits_s1_pteidx_0;
  logic i_io_tlb_0_resp_bits_s1_pteidx_1;
  logic i_io_tlb_0_resp_bits_s1_pteidx_2;
  logic i_io_tlb_0_resp_bits_s1_pteidx_3;
  logic i_io_tlb_0_resp_bits_s1_pteidx_4;
  logic i_io_tlb_0_resp_bits_s1_pteidx_5;
  logic i_io_tlb_0_resp_bits_s1_pteidx_6;
  logic i_io_tlb_0_resp_bits_s1_pteidx_7;
  logic i_io_tlb_0_resp_bits_s1_pf;
  logic i_io_tlb_0_resp_bits_s1_af;
  logic [37:0] i_io_tlb_0_resp_bits_s2_entry_tag;
  logic [13:0] i_io_tlb_0_resp_bits_s2_entry_vmid;
  logic i_io_tlb_0_resp_bits_s2_entry_n;
  logic [1:0] i_io_tlb_0_resp_bits_s2_entry_pbmt;
  logic [37:0] i_io_tlb_0_resp_bits_s2_entry_ppn;
  logic i_io_tlb_0_resp_bits_s2_entry_perm_d;
  logic i_io_tlb_0_resp_bits_s2_entry_perm_a;
  logic i_io_tlb_0_resp_bits_s2_entry_perm_g;
  logic i_io_tlb_0_resp_bits_s2_entry_perm_u;
  logic i_io_tlb_0_resp_bits_s2_entry_perm_x;
  logic i_io_tlb_0_resp_bits_s2_entry_perm_w;
  logic i_io_tlb_0_resp_bits_s2_entry_perm_r;
  logic [1:0] i_io_tlb_0_resp_bits_s2_entry_level;
  logic i_io_tlb_0_resp_bits_s2_gpf;
  logic i_io_tlb_0_resp_bits_s2_gaf;
  logic i_io_tlb_1_req_0_ready;
  logic i_io_tlb_1_resp_valid;
  logic [1:0] i_io_tlb_1_resp_bits_s2xlate;
  logic [34:0] i_io_tlb_1_resp_bits_s1_entry_tag;
  logic [15:0] i_io_tlb_1_resp_bits_s1_entry_asid;
  logic [13:0] i_io_tlb_1_resp_bits_s1_entry_vmid;
  logic i_io_tlb_1_resp_bits_s1_entry_n;
  logic [1:0] i_io_tlb_1_resp_bits_s1_entry_pbmt;
  logic i_io_tlb_1_resp_bits_s1_entry_perm_d;
  logic i_io_tlb_1_resp_bits_s1_entry_perm_a;
  logic i_io_tlb_1_resp_bits_s1_entry_perm_g;
  logic i_io_tlb_1_resp_bits_s1_entry_perm_u;
  logic i_io_tlb_1_resp_bits_s1_entry_perm_x;
  logic i_io_tlb_1_resp_bits_s1_entry_perm_w;
  logic i_io_tlb_1_resp_bits_s1_entry_perm_r;
  logic [1:0] i_io_tlb_1_resp_bits_s1_entry_level;
  logic i_io_tlb_1_resp_bits_s1_entry_v;
  logic [40:0] i_io_tlb_1_resp_bits_s1_entry_ppn;
  logic [2:0] i_io_tlb_1_resp_bits_s1_addr_low;
  logic [2:0] i_io_tlb_1_resp_bits_s1_ppn_low_0;
  logic [2:0] i_io_tlb_1_resp_bits_s1_ppn_low_1;
  logic [2:0] i_io_tlb_1_resp_bits_s1_ppn_low_2;
  logic [2:0] i_io_tlb_1_resp_bits_s1_ppn_low_3;
  logic [2:0] i_io_tlb_1_resp_bits_s1_ppn_low_4;
  logic [2:0] i_io_tlb_1_resp_bits_s1_ppn_low_5;
  logic [2:0] i_io_tlb_1_resp_bits_s1_ppn_low_6;
  logic [2:0] i_io_tlb_1_resp_bits_s1_ppn_low_7;
  logic i_io_tlb_1_resp_bits_s1_valididx_0;
  logic i_io_tlb_1_resp_bits_s1_valididx_1;
  logic i_io_tlb_1_resp_bits_s1_valididx_2;
  logic i_io_tlb_1_resp_bits_s1_valididx_3;
  logic i_io_tlb_1_resp_bits_s1_valididx_4;
  logic i_io_tlb_1_resp_bits_s1_valididx_5;
  logic i_io_tlb_1_resp_bits_s1_valididx_6;
  logic i_io_tlb_1_resp_bits_s1_valididx_7;
  logic i_io_tlb_1_resp_bits_s1_pteidx_0;
  logic i_io_tlb_1_resp_bits_s1_pteidx_1;
  logic i_io_tlb_1_resp_bits_s1_pteidx_2;
  logic i_io_tlb_1_resp_bits_s1_pteidx_3;
  logic i_io_tlb_1_resp_bits_s1_pteidx_4;
  logic i_io_tlb_1_resp_bits_s1_pteidx_5;
  logic i_io_tlb_1_resp_bits_s1_pteidx_6;
  logic i_io_tlb_1_resp_bits_s1_pteidx_7;
  logic i_io_tlb_1_resp_bits_s1_pf;
  logic i_io_tlb_1_resp_bits_s1_af;
  logic [37:0] i_io_tlb_1_resp_bits_s2_entry_tag;
  logic [13:0] i_io_tlb_1_resp_bits_s2_entry_vmid;
  logic i_io_tlb_1_resp_bits_s2_entry_n;
  logic [1:0] i_io_tlb_1_resp_bits_s2_entry_pbmt;
  logic [37:0] i_io_tlb_1_resp_bits_s2_entry_ppn;
  logic i_io_tlb_1_resp_bits_s2_entry_perm_d;
  logic i_io_tlb_1_resp_bits_s2_entry_perm_a;
  logic i_io_tlb_1_resp_bits_s2_entry_perm_g;
  logic i_io_tlb_1_resp_bits_s2_entry_perm_u;
  logic i_io_tlb_1_resp_bits_s2_entry_perm_x;
  logic i_io_tlb_1_resp_bits_s2_entry_perm_w;
  logic i_io_tlb_1_resp_bits_s2_entry_perm_r;
  logic [1:0] i_io_tlb_1_resp_bits_s2_entry_level;
  logic i_io_tlb_1_resp_bits_s2_gpf;
  logic i_io_tlb_1_resp_bits_s2_gaf;
  logic i_io_wfi_wfiSafe;
  logic [5:0] i_io_perf_0_value;
  logic [5:0] i_io_perf_1_value;
  logic [5:0] i_io_perf_2_value;
  logic [5:0] i_io_perf_3_value;
  logic [5:0] i_io_perf_4_value;
  logic [5:0] i_io_perf_5_value;
  logic [5:0] i_io_perf_6_value;
  logic [5:0] i_io_perf_7_value;
  logic [5:0] i_io_perf_8_value;
  logic [5:0] i_io_perf_9_value;
  logic [5:0] i_io_perf_10_value;
  logic [5:0] i_io_perf_11_value;
  logic [5:0] i_io_perf_12_value;
  logic [5:0] i_io_perf_13_value;
  logic [5:0] i_io_perf_14_value;
  logic [5:0] i_io_perf_15_value;
  logic [5:0] i_io_perf_16_value;
  logic [5:0] i_io_perf_17_value;
  logic [5:0] i_io_perf_18_value;
  logic i_boreChildrenBd_bore_ack;
  logic [199:0] i_boreChildrenBd_bore_outdata;
  logic i_boreChildrenBd_bore_1_ack;
  logic [227:0] i_boreChildrenBd_bore_1_outdata;

  // ---- 通用随机驱动：非握手类功能输入约束随机 ----
  task automatic drive_inputs();
    io_tlb_0_req_0_bits_vpn <= {$random, $random};
    io_tlb_0_req_0_bits_s2xlate <= $random;
    io_tlb_1_req_0_bits_vpn <= {$random, $random};
    io_tlb_1_req_0_bits_s2xlate <= $random;
    io_sfence_bits_rs1 <= $random;
    io_sfence_bits_rs2 <= $random;
    io_sfence_bits_addr <= {$random, $random};
    io_sfence_bits_id <= $random;
    io_sfence_bits_hv <= $random;
    io_sfence_bits_hg <= $random;
    io_wfi_wfiReq <= $random;
    io_csr_tlb_priv_mxr <= $random;
    io_csr_tlb_priv_virt <= $random;
    io_csr_tlb_mPBMTE <= $random;
    io_csr_tlb_hPBMTE <= $random;
  endtask

  task automatic zero_dft();
    boreChildrenBd_bore_array <= '0;
    boreChildrenBd_bore_all <= '0;
    boreChildrenBd_bore_req <= '0;
    boreChildrenBd_bore_writeen <= '0;
    boreChildrenBd_bore_be <= '0;
    boreChildrenBd_bore_addr <= '0;
    boreChildrenBd_bore_indata <= '0;
    boreChildrenBd_bore_readen <= '0;
    boreChildrenBd_bore_addr_rd <= '0;
    boreChildrenBd_bore_1_array <= '0;
    boreChildrenBd_bore_1_all <= '0;
    boreChildrenBd_bore_1_req <= '0;
    boreChildrenBd_bore_1_writeen <= '0;
    boreChildrenBd_bore_1_be <= '0;
    boreChildrenBd_bore_1_addr <= '0;
    boreChildrenBd_bore_1_indata <= '0;
    boreChildrenBd_bore_1_readen <= '0;
    boreChildrenBd_bore_1_addr_rd <= '0;
    sigFromSrams_bore_ram_hold <= '0;
    sigFromSrams_bore_ram_bypass <= '0;
    sigFromSrams_bore_ram_bp_clken <= '0;
    sigFromSrams_bore_ram_aux_clk <= '0;
    sigFromSrams_bore_ram_aux_ckbp <= '0;
    sigFromSrams_bore_ram_mcp_hold <= '0;
    sigFromSrams_bore_cgen <= '0;
    sigFromSrams_bore_1_ram_hold <= '0;
    sigFromSrams_bore_1_ram_bypass <= '0;
    sigFromSrams_bore_1_ram_bp_clken <= '0;
    sigFromSrams_bore_1_ram_aux_clk <= '0;
    sigFromSrams_bore_1_ram_aux_ckbp <= '0;
    sigFromSrams_bore_1_ram_mcp_hold <= '0;
    sigFromSrams_bore_1_cgen <= '0;
    sigFromSrams_bore_2_ram_hold <= '0;
    sigFromSrams_bore_2_ram_bypass <= '0;
    sigFromSrams_bore_2_ram_bp_clken <= '0;
    sigFromSrams_bore_2_ram_aux_clk <= '0;
    sigFromSrams_bore_2_ram_aux_ckbp <= '0;
    sigFromSrams_bore_2_ram_mcp_hold <= '0;
    sigFromSrams_bore_2_cgen <= '0;
    sigFromSrams_bore_3_ram_hold <= '0;
    sigFromSrams_bore_3_ram_bypass <= '0;
    sigFromSrams_bore_3_ram_bp_clken <= '0;
    sigFromSrams_bore_3_ram_aux_clk <= '0;
    sigFromSrams_bore_3_ram_aux_ckbp <= '0;
    sigFromSrams_bore_3_ram_mcp_hold <= '0;
    sigFromSrams_bore_3_cgen <= '0;
    sigFromSrams_bore_4_ram_hold <= '0;
    sigFromSrams_bore_4_ram_bypass <= '0;
    sigFromSrams_bore_4_ram_bp_clken <= '0;
    sigFromSrams_bore_4_ram_aux_clk <= '0;
    sigFromSrams_bore_4_ram_aux_ckbp <= '0;
    sigFromSrams_bore_4_ram_mcp_hold <= '0;
    sigFromSrams_bore_4_cgen <= '0;
    sigFromSrams_bore_5_ram_hold <= '0;
    sigFromSrams_bore_5_ram_bypass <= '0;
    sigFromSrams_bore_5_ram_bp_clken <= '0;
    sigFromSrams_bore_5_ram_aux_clk <= '0;
    sigFromSrams_bore_5_ram_aux_ckbp <= '0;
    sigFromSrams_bore_5_ram_mcp_hold <= '0;
    sigFromSrams_bore_5_cgen <= '0;
    sigFromSrams_bore_6_ram_hold <= '0;
    sigFromSrams_bore_6_ram_bypass <= '0;
    sigFromSrams_bore_6_ram_bp_clken <= '0;
    sigFromSrams_bore_6_ram_aux_clk <= '0;
    sigFromSrams_bore_6_ram_aux_ckbp <= '0;
    sigFromSrams_bore_6_ram_mcp_hold <= '0;
    sigFromSrams_bore_6_cgen <= '0;
    sigFromSrams_bore_7_ram_hold <= '0;
    sigFromSrams_bore_7_ram_bypass <= '0;
    sigFromSrams_bore_7_ram_bp_clken <= '0;
    sigFromSrams_bore_7_ram_aux_clk <= '0;
    sigFromSrams_bore_7_ram_aux_ckbp <= '0;
    sigFromSrams_bore_7_ram_mcp_hold <= '0;
    sigFromSrams_bore_7_cgen <= '0;
    sigFromSrams_bore_8_ram_hold <= '0;
    sigFromSrams_bore_8_ram_bypass <= '0;
    sigFromSrams_bore_8_ram_bp_clken <= '0;
    sigFromSrams_bore_8_ram_aux_clk <= '0;
    sigFromSrams_bore_8_ram_aux_ckbp <= '0;
    sigFromSrams_bore_8_ram_mcp_hold <= '0;
    sigFromSrams_bore_8_cgen <= '0;
    sigFromSrams_bore_9_ram_hold <= '0;
    sigFromSrams_bore_9_ram_bypass <= '0;
    sigFromSrams_bore_9_ram_bp_clken <= '0;
    sigFromSrams_bore_9_ram_aux_clk <= '0;
    sigFromSrams_bore_9_ram_aux_ckbp <= '0;
    sigFromSrams_bore_9_ram_mcp_hold <= '0;
    sigFromSrams_bore_9_cgen <= '0;
    sigFromSrams_bore_10_ram_hold <= '0;
    sigFromSrams_bore_10_ram_bypass <= '0;
    sigFromSrams_bore_10_ram_bp_clken <= '0;
    sigFromSrams_bore_10_ram_aux_clk <= '0;
    sigFromSrams_bore_10_ram_aux_ckbp <= '0;
    sigFromSrams_bore_10_ram_mcp_hold <= '0;
    sigFromSrams_bore_10_cgen <= '0;
    sigFromSrams_bore_11_ram_hold <= '0;
    sigFromSrams_bore_11_ram_bypass <= '0;
    sigFromSrams_bore_11_ram_bp_clken <= '0;
    sigFromSrams_bore_11_ram_aux_clk <= '0;
    sigFromSrams_bore_11_ram_aux_ckbp <= '0;
    sigFromSrams_bore_11_ram_mcp_hold <= '0;
    sigFromSrams_bore_11_cgen <= '0;
    cg_bore_cgen <= '0;
  endtask

  // ---- 双例化：golden 参考模型 u_g / 全重写 IT u_i ----
  L2TLB u_g (
    .clock(clk),
    .reset(rst),
    .auto_out_a_ready(auto_out_a_ready),
    .auto_out_d_valid(auto_out_d_valid),
    .auto_out_d_bits_opcode(auto_out_d_bits_opcode),
    .auto_out_d_bits_size(auto_out_d_bits_size),
    .auto_out_d_bits_source(auto_out_d_bits_source),
    .auto_out_d_bits_data(auto_out_d_bits_data),
    .io_tlb_0_req_0_valid(io_tlb_0_req_0_valid),
    .io_tlb_0_req_0_bits_vpn(io_tlb_0_req_0_bits_vpn),
    .io_tlb_0_req_0_bits_s2xlate(io_tlb_0_req_0_bits_s2xlate),
    .io_tlb_0_resp_ready(io_tlb_0_resp_ready),
    .io_tlb_1_req_0_valid(io_tlb_1_req_0_valid),
    .io_tlb_1_req_0_bits_vpn(io_tlb_1_req_0_bits_vpn),
    .io_tlb_1_req_0_bits_s2xlate(io_tlb_1_req_0_bits_s2xlate),
    .io_sfence_valid(io_sfence_valid),
    .io_sfence_bits_rs1(io_sfence_bits_rs1),
    .io_sfence_bits_rs2(io_sfence_bits_rs2),
    .io_sfence_bits_addr(io_sfence_bits_addr),
    .io_sfence_bits_id(io_sfence_bits_id),
    .io_sfence_bits_hv(io_sfence_bits_hv),
    .io_sfence_bits_hg(io_sfence_bits_hg),
    .io_wfi_wfiReq(io_wfi_wfiReq),
    .io_csr_tlb_satp_mode(io_csr_tlb_satp_mode),
    .io_csr_tlb_satp_asid(io_csr_tlb_satp_asid),
    .io_csr_tlb_satp_ppn(io_csr_tlb_satp_ppn),
    .io_csr_tlb_satp_changed(io_csr_tlb_satp_changed),
    .io_csr_tlb_vsatp_mode(io_csr_tlb_vsatp_mode),
    .io_csr_tlb_vsatp_asid(io_csr_tlb_vsatp_asid),
    .io_csr_tlb_vsatp_ppn(io_csr_tlb_vsatp_ppn),
    .io_csr_tlb_vsatp_changed(io_csr_tlb_vsatp_changed),
    .io_csr_tlb_hgatp_mode(io_csr_tlb_hgatp_mode),
    .io_csr_tlb_hgatp_vmid(io_csr_tlb_hgatp_vmid),
    .io_csr_tlb_hgatp_ppn(io_csr_tlb_hgatp_ppn),
    .io_csr_tlb_hgatp_changed(io_csr_tlb_hgatp_changed),
    .io_csr_tlb_priv_mxr(io_csr_tlb_priv_mxr),
    .io_csr_tlb_priv_virt(io_csr_tlb_priv_virt),
    .io_csr_tlb_mPBMTE(io_csr_tlb_mPBMTE),
    .io_csr_tlb_hPBMTE(io_csr_tlb_hPBMTE),
    .io_csr_distribute_csr_w_valid(io_csr_distribute_csr_w_valid),
    .io_csr_distribute_csr_w_bits_addr(io_csr_distribute_csr_w_bits_addr),
    .io_csr_distribute_csr_w_bits_data(io_csr_distribute_csr_w_bits_data),
    .boreChildrenBd_bore_array(boreChildrenBd_bore_array),
    .boreChildrenBd_bore_all(boreChildrenBd_bore_all),
    .boreChildrenBd_bore_req(boreChildrenBd_bore_req),
    .boreChildrenBd_bore_writeen(boreChildrenBd_bore_writeen),
    .boreChildrenBd_bore_be(boreChildrenBd_bore_be),
    .boreChildrenBd_bore_addr(boreChildrenBd_bore_addr),
    .boreChildrenBd_bore_indata(boreChildrenBd_bore_indata),
    .boreChildrenBd_bore_readen(boreChildrenBd_bore_readen),
    .boreChildrenBd_bore_addr_rd(boreChildrenBd_bore_addr_rd),
    .boreChildrenBd_bore_1_array(boreChildrenBd_bore_1_array),
    .boreChildrenBd_bore_1_all(boreChildrenBd_bore_1_all),
    .boreChildrenBd_bore_1_req(boreChildrenBd_bore_1_req),
    .boreChildrenBd_bore_1_writeen(boreChildrenBd_bore_1_writeen),
    .boreChildrenBd_bore_1_be(boreChildrenBd_bore_1_be),
    .boreChildrenBd_bore_1_addr(boreChildrenBd_bore_1_addr),
    .boreChildrenBd_bore_1_indata(boreChildrenBd_bore_1_indata),
    .boreChildrenBd_bore_1_readen(boreChildrenBd_bore_1_readen),
    .boreChildrenBd_bore_1_addr_rd(boreChildrenBd_bore_1_addr_rd),
    .sigFromSrams_bore_ram_hold(sigFromSrams_bore_ram_hold),
    .sigFromSrams_bore_ram_bypass(sigFromSrams_bore_ram_bypass),
    .sigFromSrams_bore_ram_bp_clken(sigFromSrams_bore_ram_bp_clken),
    .sigFromSrams_bore_ram_aux_clk(sigFromSrams_bore_ram_aux_clk),
    .sigFromSrams_bore_ram_aux_ckbp(sigFromSrams_bore_ram_aux_ckbp),
    .sigFromSrams_bore_ram_mcp_hold(sigFromSrams_bore_ram_mcp_hold),
    .sigFromSrams_bore_cgen(sigFromSrams_bore_cgen),
    .sigFromSrams_bore_1_ram_hold(sigFromSrams_bore_1_ram_hold),
    .sigFromSrams_bore_1_ram_bypass(sigFromSrams_bore_1_ram_bypass),
    .sigFromSrams_bore_1_ram_bp_clken(sigFromSrams_bore_1_ram_bp_clken),
    .sigFromSrams_bore_1_ram_aux_clk(sigFromSrams_bore_1_ram_aux_clk),
    .sigFromSrams_bore_1_ram_aux_ckbp(sigFromSrams_bore_1_ram_aux_ckbp),
    .sigFromSrams_bore_1_ram_mcp_hold(sigFromSrams_bore_1_ram_mcp_hold),
    .sigFromSrams_bore_1_cgen(sigFromSrams_bore_1_cgen),
    .sigFromSrams_bore_2_ram_hold(sigFromSrams_bore_2_ram_hold),
    .sigFromSrams_bore_2_ram_bypass(sigFromSrams_bore_2_ram_bypass),
    .sigFromSrams_bore_2_ram_bp_clken(sigFromSrams_bore_2_ram_bp_clken),
    .sigFromSrams_bore_2_ram_aux_clk(sigFromSrams_bore_2_ram_aux_clk),
    .sigFromSrams_bore_2_ram_aux_ckbp(sigFromSrams_bore_2_ram_aux_ckbp),
    .sigFromSrams_bore_2_ram_mcp_hold(sigFromSrams_bore_2_ram_mcp_hold),
    .sigFromSrams_bore_2_cgen(sigFromSrams_bore_2_cgen),
    .sigFromSrams_bore_3_ram_hold(sigFromSrams_bore_3_ram_hold),
    .sigFromSrams_bore_3_ram_bypass(sigFromSrams_bore_3_ram_bypass),
    .sigFromSrams_bore_3_ram_bp_clken(sigFromSrams_bore_3_ram_bp_clken),
    .sigFromSrams_bore_3_ram_aux_clk(sigFromSrams_bore_3_ram_aux_clk),
    .sigFromSrams_bore_3_ram_aux_ckbp(sigFromSrams_bore_3_ram_aux_ckbp),
    .sigFromSrams_bore_3_ram_mcp_hold(sigFromSrams_bore_3_ram_mcp_hold),
    .sigFromSrams_bore_3_cgen(sigFromSrams_bore_3_cgen),
    .sigFromSrams_bore_4_ram_hold(sigFromSrams_bore_4_ram_hold),
    .sigFromSrams_bore_4_ram_bypass(sigFromSrams_bore_4_ram_bypass),
    .sigFromSrams_bore_4_ram_bp_clken(sigFromSrams_bore_4_ram_bp_clken),
    .sigFromSrams_bore_4_ram_aux_clk(sigFromSrams_bore_4_ram_aux_clk),
    .sigFromSrams_bore_4_ram_aux_ckbp(sigFromSrams_bore_4_ram_aux_ckbp),
    .sigFromSrams_bore_4_ram_mcp_hold(sigFromSrams_bore_4_ram_mcp_hold),
    .sigFromSrams_bore_4_cgen(sigFromSrams_bore_4_cgen),
    .sigFromSrams_bore_5_ram_hold(sigFromSrams_bore_5_ram_hold),
    .sigFromSrams_bore_5_ram_bypass(sigFromSrams_bore_5_ram_bypass),
    .sigFromSrams_bore_5_ram_bp_clken(sigFromSrams_bore_5_ram_bp_clken),
    .sigFromSrams_bore_5_ram_aux_clk(sigFromSrams_bore_5_ram_aux_clk),
    .sigFromSrams_bore_5_ram_aux_ckbp(sigFromSrams_bore_5_ram_aux_ckbp),
    .sigFromSrams_bore_5_ram_mcp_hold(sigFromSrams_bore_5_ram_mcp_hold),
    .sigFromSrams_bore_5_cgen(sigFromSrams_bore_5_cgen),
    .sigFromSrams_bore_6_ram_hold(sigFromSrams_bore_6_ram_hold),
    .sigFromSrams_bore_6_ram_bypass(sigFromSrams_bore_6_ram_bypass),
    .sigFromSrams_bore_6_ram_bp_clken(sigFromSrams_bore_6_ram_bp_clken),
    .sigFromSrams_bore_6_ram_aux_clk(sigFromSrams_bore_6_ram_aux_clk),
    .sigFromSrams_bore_6_ram_aux_ckbp(sigFromSrams_bore_6_ram_aux_ckbp),
    .sigFromSrams_bore_6_ram_mcp_hold(sigFromSrams_bore_6_ram_mcp_hold),
    .sigFromSrams_bore_6_cgen(sigFromSrams_bore_6_cgen),
    .sigFromSrams_bore_7_ram_hold(sigFromSrams_bore_7_ram_hold),
    .sigFromSrams_bore_7_ram_bypass(sigFromSrams_bore_7_ram_bypass),
    .sigFromSrams_bore_7_ram_bp_clken(sigFromSrams_bore_7_ram_bp_clken),
    .sigFromSrams_bore_7_ram_aux_clk(sigFromSrams_bore_7_ram_aux_clk),
    .sigFromSrams_bore_7_ram_aux_ckbp(sigFromSrams_bore_7_ram_aux_ckbp),
    .sigFromSrams_bore_7_ram_mcp_hold(sigFromSrams_bore_7_ram_mcp_hold),
    .sigFromSrams_bore_7_cgen(sigFromSrams_bore_7_cgen),
    .sigFromSrams_bore_8_ram_hold(sigFromSrams_bore_8_ram_hold),
    .sigFromSrams_bore_8_ram_bypass(sigFromSrams_bore_8_ram_bypass),
    .sigFromSrams_bore_8_ram_bp_clken(sigFromSrams_bore_8_ram_bp_clken),
    .sigFromSrams_bore_8_ram_aux_clk(sigFromSrams_bore_8_ram_aux_clk),
    .sigFromSrams_bore_8_ram_aux_ckbp(sigFromSrams_bore_8_ram_aux_ckbp),
    .sigFromSrams_bore_8_ram_mcp_hold(sigFromSrams_bore_8_ram_mcp_hold),
    .sigFromSrams_bore_8_cgen(sigFromSrams_bore_8_cgen),
    .sigFromSrams_bore_9_ram_hold(sigFromSrams_bore_9_ram_hold),
    .sigFromSrams_bore_9_ram_bypass(sigFromSrams_bore_9_ram_bypass),
    .sigFromSrams_bore_9_ram_bp_clken(sigFromSrams_bore_9_ram_bp_clken),
    .sigFromSrams_bore_9_ram_aux_clk(sigFromSrams_bore_9_ram_aux_clk),
    .sigFromSrams_bore_9_ram_aux_ckbp(sigFromSrams_bore_9_ram_aux_ckbp),
    .sigFromSrams_bore_9_ram_mcp_hold(sigFromSrams_bore_9_ram_mcp_hold),
    .sigFromSrams_bore_9_cgen(sigFromSrams_bore_9_cgen),
    .sigFromSrams_bore_10_ram_hold(sigFromSrams_bore_10_ram_hold),
    .sigFromSrams_bore_10_ram_bypass(sigFromSrams_bore_10_ram_bypass),
    .sigFromSrams_bore_10_ram_bp_clken(sigFromSrams_bore_10_ram_bp_clken),
    .sigFromSrams_bore_10_ram_aux_clk(sigFromSrams_bore_10_ram_aux_clk),
    .sigFromSrams_bore_10_ram_aux_ckbp(sigFromSrams_bore_10_ram_aux_ckbp),
    .sigFromSrams_bore_10_ram_mcp_hold(sigFromSrams_bore_10_ram_mcp_hold),
    .sigFromSrams_bore_10_cgen(sigFromSrams_bore_10_cgen),
    .sigFromSrams_bore_11_ram_hold(sigFromSrams_bore_11_ram_hold),
    .sigFromSrams_bore_11_ram_bypass(sigFromSrams_bore_11_ram_bypass),
    .sigFromSrams_bore_11_ram_bp_clken(sigFromSrams_bore_11_ram_bp_clken),
    .sigFromSrams_bore_11_ram_aux_clk(sigFromSrams_bore_11_ram_aux_clk),
    .sigFromSrams_bore_11_ram_aux_ckbp(sigFromSrams_bore_11_ram_aux_ckbp),
    .sigFromSrams_bore_11_ram_mcp_hold(sigFromSrams_bore_11_ram_mcp_hold),
    .sigFromSrams_bore_11_cgen(sigFromSrams_bore_11_cgen),
    .cg_bore_cgen(cg_bore_cgen),
    .auto_out_a_valid(g_auto_out_a_valid),
    .auto_out_a_bits_source(g_auto_out_a_bits_source),
    .auto_out_a_bits_address(g_auto_out_a_bits_address),
    .io_tlb_0_req_0_ready(g_io_tlb_0_req_0_ready),
    .io_tlb_0_resp_valid(g_io_tlb_0_resp_valid),
    .io_tlb_0_resp_bits_s2xlate(g_io_tlb_0_resp_bits_s2xlate),
    .io_tlb_0_resp_bits_s1_entry_tag(g_io_tlb_0_resp_bits_s1_entry_tag),
    .io_tlb_0_resp_bits_s1_entry_asid(g_io_tlb_0_resp_bits_s1_entry_asid),
    .io_tlb_0_resp_bits_s1_entry_vmid(g_io_tlb_0_resp_bits_s1_entry_vmid),
    .io_tlb_0_resp_bits_s1_entry_n(g_io_tlb_0_resp_bits_s1_entry_n),
    .io_tlb_0_resp_bits_s1_entry_pbmt(g_io_tlb_0_resp_bits_s1_entry_pbmt),
    .io_tlb_0_resp_bits_s1_entry_perm_d(g_io_tlb_0_resp_bits_s1_entry_perm_d),
    .io_tlb_0_resp_bits_s1_entry_perm_a(g_io_tlb_0_resp_bits_s1_entry_perm_a),
    .io_tlb_0_resp_bits_s1_entry_perm_g(g_io_tlb_0_resp_bits_s1_entry_perm_g),
    .io_tlb_0_resp_bits_s1_entry_perm_u(g_io_tlb_0_resp_bits_s1_entry_perm_u),
    .io_tlb_0_resp_bits_s1_entry_perm_x(g_io_tlb_0_resp_bits_s1_entry_perm_x),
    .io_tlb_0_resp_bits_s1_entry_perm_w(g_io_tlb_0_resp_bits_s1_entry_perm_w),
    .io_tlb_0_resp_bits_s1_entry_perm_r(g_io_tlb_0_resp_bits_s1_entry_perm_r),
    .io_tlb_0_resp_bits_s1_entry_level(g_io_tlb_0_resp_bits_s1_entry_level),
    .io_tlb_0_resp_bits_s1_entry_v(g_io_tlb_0_resp_bits_s1_entry_v),
    .io_tlb_0_resp_bits_s1_entry_ppn(g_io_tlb_0_resp_bits_s1_entry_ppn),
    .io_tlb_0_resp_bits_s1_addr_low(g_io_tlb_0_resp_bits_s1_addr_low),
    .io_tlb_0_resp_bits_s1_ppn_low_0(g_io_tlb_0_resp_bits_s1_ppn_low_0),
    .io_tlb_0_resp_bits_s1_ppn_low_1(g_io_tlb_0_resp_bits_s1_ppn_low_1),
    .io_tlb_0_resp_bits_s1_ppn_low_2(g_io_tlb_0_resp_bits_s1_ppn_low_2),
    .io_tlb_0_resp_bits_s1_ppn_low_3(g_io_tlb_0_resp_bits_s1_ppn_low_3),
    .io_tlb_0_resp_bits_s1_ppn_low_4(g_io_tlb_0_resp_bits_s1_ppn_low_4),
    .io_tlb_0_resp_bits_s1_ppn_low_5(g_io_tlb_0_resp_bits_s1_ppn_low_5),
    .io_tlb_0_resp_bits_s1_ppn_low_6(g_io_tlb_0_resp_bits_s1_ppn_low_6),
    .io_tlb_0_resp_bits_s1_ppn_low_7(g_io_tlb_0_resp_bits_s1_ppn_low_7),
    .io_tlb_0_resp_bits_s1_valididx_0(g_io_tlb_0_resp_bits_s1_valididx_0),
    .io_tlb_0_resp_bits_s1_valididx_1(g_io_tlb_0_resp_bits_s1_valididx_1),
    .io_tlb_0_resp_bits_s1_valididx_2(g_io_tlb_0_resp_bits_s1_valididx_2),
    .io_tlb_0_resp_bits_s1_valididx_3(g_io_tlb_0_resp_bits_s1_valididx_3),
    .io_tlb_0_resp_bits_s1_valididx_4(g_io_tlb_0_resp_bits_s1_valididx_4),
    .io_tlb_0_resp_bits_s1_valididx_5(g_io_tlb_0_resp_bits_s1_valididx_5),
    .io_tlb_0_resp_bits_s1_valididx_6(g_io_tlb_0_resp_bits_s1_valididx_6),
    .io_tlb_0_resp_bits_s1_valididx_7(g_io_tlb_0_resp_bits_s1_valididx_7),
    .io_tlb_0_resp_bits_s1_pteidx_0(g_io_tlb_0_resp_bits_s1_pteidx_0),
    .io_tlb_0_resp_bits_s1_pteidx_1(g_io_tlb_0_resp_bits_s1_pteidx_1),
    .io_tlb_0_resp_bits_s1_pteidx_2(g_io_tlb_0_resp_bits_s1_pteidx_2),
    .io_tlb_0_resp_bits_s1_pteidx_3(g_io_tlb_0_resp_bits_s1_pteidx_3),
    .io_tlb_0_resp_bits_s1_pteidx_4(g_io_tlb_0_resp_bits_s1_pteidx_4),
    .io_tlb_0_resp_bits_s1_pteidx_5(g_io_tlb_0_resp_bits_s1_pteidx_5),
    .io_tlb_0_resp_bits_s1_pteidx_6(g_io_tlb_0_resp_bits_s1_pteidx_6),
    .io_tlb_0_resp_bits_s1_pteidx_7(g_io_tlb_0_resp_bits_s1_pteidx_7),
    .io_tlb_0_resp_bits_s1_pf(g_io_tlb_0_resp_bits_s1_pf),
    .io_tlb_0_resp_bits_s1_af(g_io_tlb_0_resp_bits_s1_af),
    .io_tlb_0_resp_bits_s2_entry_tag(g_io_tlb_0_resp_bits_s2_entry_tag),
    .io_tlb_0_resp_bits_s2_entry_vmid(g_io_tlb_0_resp_bits_s2_entry_vmid),
    .io_tlb_0_resp_bits_s2_entry_n(g_io_tlb_0_resp_bits_s2_entry_n),
    .io_tlb_0_resp_bits_s2_entry_pbmt(g_io_tlb_0_resp_bits_s2_entry_pbmt),
    .io_tlb_0_resp_bits_s2_entry_ppn(g_io_tlb_0_resp_bits_s2_entry_ppn),
    .io_tlb_0_resp_bits_s2_entry_perm_d(g_io_tlb_0_resp_bits_s2_entry_perm_d),
    .io_tlb_0_resp_bits_s2_entry_perm_a(g_io_tlb_0_resp_bits_s2_entry_perm_a),
    .io_tlb_0_resp_bits_s2_entry_perm_g(g_io_tlb_0_resp_bits_s2_entry_perm_g),
    .io_tlb_0_resp_bits_s2_entry_perm_u(g_io_tlb_0_resp_bits_s2_entry_perm_u),
    .io_tlb_0_resp_bits_s2_entry_perm_x(g_io_tlb_0_resp_bits_s2_entry_perm_x),
    .io_tlb_0_resp_bits_s2_entry_perm_w(g_io_tlb_0_resp_bits_s2_entry_perm_w),
    .io_tlb_0_resp_bits_s2_entry_perm_r(g_io_tlb_0_resp_bits_s2_entry_perm_r),
    .io_tlb_0_resp_bits_s2_entry_level(g_io_tlb_0_resp_bits_s2_entry_level),
    .io_tlb_0_resp_bits_s2_gpf(g_io_tlb_0_resp_bits_s2_gpf),
    .io_tlb_0_resp_bits_s2_gaf(g_io_tlb_0_resp_bits_s2_gaf),
    .io_tlb_1_req_0_ready(g_io_tlb_1_req_0_ready),
    .io_tlb_1_resp_valid(g_io_tlb_1_resp_valid),
    .io_tlb_1_resp_bits_s2xlate(g_io_tlb_1_resp_bits_s2xlate),
    .io_tlb_1_resp_bits_s1_entry_tag(g_io_tlb_1_resp_bits_s1_entry_tag),
    .io_tlb_1_resp_bits_s1_entry_asid(g_io_tlb_1_resp_bits_s1_entry_asid),
    .io_tlb_1_resp_bits_s1_entry_vmid(g_io_tlb_1_resp_bits_s1_entry_vmid),
    .io_tlb_1_resp_bits_s1_entry_n(g_io_tlb_1_resp_bits_s1_entry_n),
    .io_tlb_1_resp_bits_s1_entry_pbmt(g_io_tlb_1_resp_bits_s1_entry_pbmt),
    .io_tlb_1_resp_bits_s1_entry_perm_d(g_io_tlb_1_resp_bits_s1_entry_perm_d),
    .io_tlb_1_resp_bits_s1_entry_perm_a(g_io_tlb_1_resp_bits_s1_entry_perm_a),
    .io_tlb_1_resp_bits_s1_entry_perm_g(g_io_tlb_1_resp_bits_s1_entry_perm_g),
    .io_tlb_1_resp_bits_s1_entry_perm_u(g_io_tlb_1_resp_bits_s1_entry_perm_u),
    .io_tlb_1_resp_bits_s1_entry_perm_x(g_io_tlb_1_resp_bits_s1_entry_perm_x),
    .io_tlb_1_resp_bits_s1_entry_perm_w(g_io_tlb_1_resp_bits_s1_entry_perm_w),
    .io_tlb_1_resp_bits_s1_entry_perm_r(g_io_tlb_1_resp_bits_s1_entry_perm_r),
    .io_tlb_1_resp_bits_s1_entry_level(g_io_tlb_1_resp_bits_s1_entry_level),
    .io_tlb_1_resp_bits_s1_entry_v(g_io_tlb_1_resp_bits_s1_entry_v),
    .io_tlb_1_resp_bits_s1_entry_ppn(g_io_tlb_1_resp_bits_s1_entry_ppn),
    .io_tlb_1_resp_bits_s1_addr_low(g_io_tlb_1_resp_bits_s1_addr_low),
    .io_tlb_1_resp_bits_s1_ppn_low_0(g_io_tlb_1_resp_bits_s1_ppn_low_0),
    .io_tlb_1_resp_bits_s1_ppn_low_1(g_io_tlb_1_resp_bits_s1_ppn_low_1),
    .io_tlb_1_resp_bits_s1_ppn_low_2(g_io_tlb_1_resp_bits_s1_ppn_low_2),
    .io_tlb_1_resp_bits_s1_ppn_low_3(g_io_tlb_1_resp_bits_s1_ppn_low_3),
    .io_tlb_1_resp_bits_s1_ppn_low_4(g_io_tlb_1_resp_bits_s1_ppn_low_4),
    .io_tlb_1_resp_bits_s1_ppn_low_5(g_io_tlb_1_resp_bits_s1_ppn_low_5),
    .io_tlb_1_resp_bits_s1_ppn_low_6(g_io_tlb_1_resp_bits_s1_ppn_low_6),
    .io_tlb_1_resp_bits_s1_ppn_low_7(g_io_tlb_1_resp_bits_s1_ppn_low_7),
    .io_tlb_1_resp_bits_s1_valididx_0(g_io_tlb_1_resp_bits_s1_valididx_0),
    .io_tlb_1_resp_bits_s1_valididx_1(g_io_tlb_1_resp_bits_s1_valididx_1),
    .io_tlb_1_resp_bits_s1_valididx_2(g_io_tlb_1_resp_bits_s1_valididx_2),
    .io_tlb_1_resp_bits_s1_valididx_3(g_io_tlb_1_resp_bits_s1_valididx_3),
    .io_tlb_1_resp_bits_s1_valididx_4(g_io_tlb_1_resp_bits_s1_valididx_4),
    .io_tlb_1_resp_bits_s1_valididx_5(g_io_tlb_1_resp_bits_s1_valididx_5),
    .io_tlb_1_resp_bits_s1_valididx_6(g_io_tlb_1_resp_bits_s1_valididx_6),
    .io_tlb_1_resp_bits_s1_valididx_7(g_io_tlb_1_resp_bits_s1_valididx_7),
    .io_tlb_1_resp_bits_s1_pteidx_0(g_io_tlb_1_resp_bits_s1_pteidx_0),
    .io_tlb_1_resp_bits_s1_pteidx_1(g_io_tlb_1_resp_bits_s1_pteidx_1),
    .io_tlb_1_resp_bits_s1_pteidx_2(g_io_tlb_1_resp_bits_s1_pteidx_2),
    .io_tlb_1_resp_bits_s1_pteidx_3(g_io_tlb_1_resp_bits_s1_pteidx_3),
    .io_tlb_1_resp_bits_s1_pteidx_4(g_io_tlb_1_resp_bits_s1_pteidx_4),
    .io_tlb_1_resp_bits_s1_pteidx_5(g_io_tlb_1_resp_bits_s1_pteidx_5),
    .io_tlb_1_resp_bits_s1_pteidx_6(g_io_tlb_1_resp_bits_s1_pteidx_6),
    .io_tlb_1_resp_bits_s1_pteidx_7(g_io_tlb_1_resp_bits_s1_pteidx_7),
    .io_tlb_1_resp_bits_s1_pf(g_io_tlb_1_resp_bits_s1_pf),
    .io_tlb_1_resp_bits_s1_af(g_io_tlb_1_resp_bits_s1_af),
    .io_tlb_1_resp_bits_s2_entry_tag(g_io_tlb_1_resp_bits_s2_entry_tag),
    .io_tlb_1_resp_bits_s2_entry_vmid(g_io_tlb_1_resp_bits_s2_entry_vmid),
    .io_tlb_1_resp_bits_s2_entry_n(g_io_tlb_1_resp_bits_s2_entry_n),
    .io_tlb_1_resp_bits_s2_entry_pbmt(g_io_tlb_1_resp_bits_s2_entry_pbmt),
    .io_tlb_1_resp_bits_s2_entry_ppn(g_io_tlb_1_resp_bits_s2_entry_ppn),
    .io_tlb_1_resp_bits_s2_entry_perm_d(g_io_tlb_1_resp_bits_s2_entry_perm_d),
    .io_tlb_1_resp_bits_s2_entry_perm_a(g_io_tlb_1_resp_bits_s2_entry_perm_a),
    .io_tlb_1_resp_bits_s2_entry_perm_g(g_io_tlb_1_resp_bits_s2_entry_perm_g),
    .io_tlb_1_resp_bits_s2_entry_perm_u(g_io_tlb_1_resp_bits_s2_entry_perm_u),
    .io_tlb_1_resp_bits_s2_entry_perm_x(g_io_tlb_1_resp_bits_s2_entry_perm_x),
    .io_tlb_1_resp_bits_s2_entry_perm_w(g_io_tlb_1_resp_bits_s2_entry_perm_w),
    .io_tlb_1_resp_bits_s2_entry_perm_r(g_io_tlb_1_resp_bits_s2_entry_perm_r),
    .io_tlb_1_resp_bits_s2_entry_level(g_io_tlb_1_resp_bits_s2_entry_level),
    .io_tlb_1_resp_bits_s2_gpf(g_io_tlb_1_resp_bits_s2_gpf),
    .io_tlb_1_resp_bits_s2_gaf(g_io_tlb_1_resp_bits_s2_gaf),
    .io_wfi_wfiSafe(g_io_wfi_wfiSafe),
    .io_perf_0_value(g_io_perf_0_value),
    .io_perf_1_value(g_io_perf_1_value),
    .io_perf_2_value(g_io_perf_2_value),
    .io_perf_3_value(g_io_perf_3_value),
    .io_perf_4_value(g_io_perf_4_value),
    .io_perf_5_value(g_io_perf_5_value),
    .io_perf_6_value(g_io_perf_6_value),
    .io_perf_7_value(g_io_perf_7_value),
    .io_perf_8_value(g_io_perf_8_value),
    .io_perf_9_value(g_io_perf_9_value),
    .io_perf_10_value(g_io_perf_10_value),
    .io_perf_11_value(g_io_perf_11_value),
    .io_perf_12_value(g_io_perf_12_value),
    .io_perf_13_value(g_io_perf_13_value),
    .io_perf_14_value(g_io_perf_14_value),
    .io_perf_15_value(g_io_perf_15_value),
    .io_perf_16_value(g_io_perf_16_value),
    .io_perf_17_value(g_io_perf_17_value),
    .io_perf_18_value(g_io_perf_18_value),
    .boreChildrenBd_bore_ack(g_boreChildrenBd_bore_ack),
    .boreChildrenBd_bore_outdata(g_boreChildrenBd_bore_outdata),
    .boreChildrenBd_bore_1_ack(g_boreChildrenBd_bore_1_ack),
    .boreChildrenBd_bore_1_outdata(g_boreChildrenBd_bore_1_outdata)
  );

  MMU_it u_i (
    .clock(clk),
    .reset(rst),
    .auto_out_a_ready(auto_out_a_ready),
    .auto_out_d_valid(auto_out_d_valid),
    .auto_out_d_bits_opcode(auto_out_d_bits_opcode),
    .auto_out_d_bits_size(auto_out_d_bits_size),
    .auto_out_d_bits_source(auto_out_d_bits_source),
    .auto_out_d_bits_data(auto_out_d_bits_data),
    .io_tlb_0_req_0_valid(io_tlb_0_req_0_valid),
    .io_tlb_0_req_0_bits_vpn(io_tlb_0_req_0_bits_vpn),
    .io_tlb_0_req_0_bits_s2xlate(io_tlb_0_req_0_bits_s2xlate),
    .io_tlb_0_resp_ready(io_tlb_0_resp_ready),
    .io_tlb_1_req_0_valid(io_tlb_1_req_0_valid),
    .io_tlb_1_req_0_bits_vpn(io_tlb_1_req_0_bits_vpn),
    .io_tlb_1_req_0_bits_s2xlate(io_tlb_1_req_0_bits_s2xlate),
    .io_sfence_valid(io_sfence_valid),
    .io_sfence_bits_rs1(io_sfence_bits_rs1),
    .io_sfence_bits_rs2(io_sfence_bits_rs2),
    .io_sfence_bits_addr(io_sfence_bits_addr),
    .io_sfence_bits_id(io_sfence_bits_id),
    .io_sfence_bits_hv(io_sfence_bits_hv),
    .io_sfence_bits_hg(io_sfence_bits_hg),
    .io_wfi_wfiReq(io_wfi_wfiReq),
    .io_csr_tlb_satp_mode(io_csr_tlb_satp_mode),
    .io_csr_tlb_satp_asid(io_csr_tlb_satp_asid),
    .io_csr_tlb_satp_ppn(io_csr_tlb_satp_ppn),
    .io_csr_tlb_satp_changed(io_csr_tlb_satp_changed),
    .io_csr_tlb_vsatp_mode(io_csr_tlb_vsatp_mode),
    .io_csr_tlb_vsatp_asid(io_csr_tlb_vsatp_asid),
    .io_csr_tlb_vsatp_ppn(io_csr_tlb_vsatp_ppn),
    .io_csr_tlb_vsatp_changed(io_csr_tlb_vsatp_changed),
    .io_csr_tlb_hgatp_mode(io_csr_tlb_hgatp_mode),
    .io_csr_tlb_hgatp_vmid(io_csr_tlb_hgatp_vmid),
    .io_csr_tlb_hgatp_ppn(io_csr_tlb_hgatp_ppn),
    .io_csr_tlb_hgatp_changed(io_csr_tlb_hgatp_changed),
    .io_csr_tlb_priv_mxr(io_csr_tlb_priv_mxr),
    .io_csr_tlb_priv_virt(io_csr_tlb_priv_virt),
    .io_csr_tlb_mPBMTE(io_csr_tlb_mPBMTE),
    .io_csr_tlb_hPBMTE(io_csr_tlb_hPBMTE),
    .io_csr_distribute_csr_w_valid(io_csr_distribute_csr_w_valid),
    .io_csr_distribute_csr_w_bits_addr(io_csr_distribute_csr_w_bits_addr),
    .io_csr_distribute_csr_w_bits_data(io_csr_distribute_csr_w_bits_data),
    .boreChildrenBd_bore_array(boreChildrenBd_bore_array),
    .boreChildrenBd_bore_all(boreChildrenBd_bore_all),
    .boreChildrenBd_bore_req(boreChildrenBd_bore_req),
    .boreChildrenBd_bore_writeen(boreChildrenBd_bore_writeen),
    .boreChildrenBd_bore_be(boreChildrenBd_bore_be),
    .boreChildrenBd_bore_addr(boreChildrenBd_bore_addr),
    .boreChildrenBd_bore_indata(boreChildrenBd_bore_indata),
    .boreChildrenBd_bore_readen(boreChildrenBd_bore_readen),
    .boreChildrenBd_bore_addr_rd(boreChildrenBd_bore_addr_rd),
    .boreChildrenBd_bore_1_array(boreChildrenBd_bore_1_array),
    .boreChildrenBd_bore_1_all(boreChildrenBd_bore_1_all),
    .boreChildrenBd_bore_1_req(boreChildrenBd_bore_1_req),
    .boreChildrenBd_bore_1_writeen(boreChildrenBd_bore_1_writeen),
    .boreChildrenBd_bore_1_be(boreChildrenBd_bore_1_be),
    .boreChildrenBd_bore_1_addr(boreChildrenBd_bore_1_addr),
    .boreChildrenBd_bore_1_indata(boreChildrenBd_bore_1_indata),
    .boreChildrenBd_bore_1_readen(boreChildrenBd_bore_1_readen),
    .boreChildrenBd_bore_1_addr_rd(boreChildrenBd_bore_1_addr_rd),
    .sigFromSrams_bore_ram_hold(sigFromSrams_bore_ram_hold),
    .sigFromSrams_bore_ram_bypass(sigFromSrams_bore_ram_bypass),
    .sigFromSrams_bore_ram_bp_clken(sigFromSrams_bore_ram_bp_clken),
    .sigFromSrams_bore_ram_aux_clk(sigFromSrams_bore_ram_aux_clk),
    .sigFromSrams_bore_ram_aux_ckbp(sigFromSrams_bore_ram_aux_ckbp),
    .sigFromSrams_bore_ram_mcp_hold(sigFromSrams_bore_ram_mcp_hold),
    .sigFromSrams_bore_cgen(sigFromSrams_bore_cgen),
    .sigFromSrams_bore_1_ram_hold(sigFromSrams_bore_1_ram_hold),
    .sigFromSrams_bore_1_ram_bypass(sigFromSrams_bore_1_ram_bypass),
    .sigFromSrams_bore_1_ram_bp_clken(sigFromSrams_bore_1_ram_bp_clken),
    .sigFromSrams_bore_1_ram_aux_clk(sigFromSrams_bore_1_ram_aux_clk),
    .sigFromSrams_bore_1_ram_aux_ckbp(sigFromSrams_bore_1_ram_aux_ckbp),
    .sigFromSrams_bore_1_ram_mcp_hold(sigFromSrams_bore_1_ram_mcp_hold),
    .sigFromSrams_bore_1_cgen(sigFromSrams_bore_1_cgen),
    .sigFromSrams_bore_2_ram_hold(sigFromSrams_bore_2_ram_hold),
    .sigFromSrams_bore_2_ram_bypass(sigFromSrams_bore_2_ram_bypass),
    .sigFromSrams_bore_2_ram_bp_clken(sigFromSrams_bore_2_ram_bp_clken),
    .sigFromSrams_bore_2_ram_aux_clk(sigFromSrams_bore_2_ram_aux_clk),
    .sigFromSrams_bore_2_ram_aux_ckbp(sigFromSrams_bore_2_ram_aux_ckbp),
    .sigFromSrams_bore_2_ram_mcp_hold(sigFromSrams_bore_2_ram_mcp_hold),
    .sigFromSrams_bore_2_cgen(sigFromSrams_bore_2_cgen),
    .sigFromSrams_bore_3_ram_hold(sigFromSrams_bore_3_ram_hold),
    .sigFromSrams_bore_3_ram_bypass(sigFromSrams_bore_3_ram_bypass),
    .sigFromSrams_bore_3_ram_bp_clken(sigFromSrams_bore_3_ram_bp_clken),
    .sigFromSrams_bore_3_ram_aux_clk(sigFromSrams_bore_3_ram_aux_clk),
    .sigFromSrams_bore_3_ram_aux_ckbp(sigFromSrams_bore_3_ram_aux_ckbp),
    .sigFromSrams_bore_3_ram_mcp_hold(sigFromSrams_bore_3_ram_mcp_hold),
    .sigFromSrams_bore_3_cgen(sigFromSrams_bore_3_cgen),
    .sigFromSrams_bore_4_ram_hold(sigFromSrams_bore_4_ram_hold),
    .sigFromSrams_bore_4_ram_bypass(sigFromSrams_bore_4_ram_bypass),
    .sigFromSrams_bore_4_ram_bp_clken(sigFromSrams_bore_4_ram_bp_clken),
    .sigFromSrams_bore_4_ram_aux_clk(sigFromSrams_bore_4_ram_aux_clk),
    .sigFromSrams_bore_4_ram_aux_ckbp(sigFromSrams_bore_4_ram_aux_ckbp),
    .sigFromSrams_bore_4_ram_mcp_hold(sigFromSrams_bore_4_ram_mcp_hold),
    .sigFromSrams_bore_4_cgen(sigFromSrams_bore_4_cgen),
    .sigFromSrams_bore_5_ram_hold(sigFromSrams_bore_5_ram_hold),
    .sigFromSrams_bore_5_ram_bypass(sigFromSrams_bore_5_ram_bypass),
    .sigFromSrams_bore_5_ram_bp_clken(sigFromSrams_bore_5_ram_bp_clken),
    .sigFromSrams_bore_5_ram_aux_clk(sigFromSrams_bore_5_ram_aux_clk),
    .sigFromSrams_bore_5_ram_aux_ckbp(sigFromSrams_bore_5_ram_aux_ckbp),
    .sigFromSrams_bore_5_ram_mcp_hold(sigFromSrams_bore_5_ram_mcp_hold),
    .sigFromSrams_bore_5_cgen(sigFromSrams_bore_5_cgen),
    .sigFromSrams_bore_6_ram_hold(sigFromSrams_bore_6_ram_hold),
    .sigFromSrams_bore_6_ram_bypass(sigFromSrams_bore_6_ram_bypass),
    .sigFromSrams_bore_6_ram_bp_clken(sigFromSrams_bore_6_ram_bp_clken),
    .sigFromSrams_bore_6_ram_aux_clk(sigFromSrams_bore_6_ram_aux_clk),
    .sigFromSrams_bore_6_ram_aux_ckbp(sigFromSrams_bore_6_ram_aux_ckbp),
    .sigFromSrams_bore_6_ram_mcp_hold(sigFromSrams_bore_6_ram_mcp_hold),
    .sigFromSrams_bore_6_cgen(sigFromSrams_bore_6_cgen),
    .sigFromSrams_bore_7_ram_hold(sigFromSrams_bore_7_ram_hold),
    .sigFromSrams_bore_7_ram_bypass(sigFromSrams_bore_7_ram_bypass),
    .sigFromSrams_bore_7_ram_bp_clken(sigFromSrams_bore_7_ram_bp_clken),
    .sigFromSrams_bore_7_ram_aux_clk(sigFromSrams_bore_7_ram_aux_clk),
    .sigFromSrams_bore_7_ram_aux_ckbp(sigFromSrams_bore_7_ram_aux_ckbp),
    .sigFromSrams_bore_7_ram_mcp_hold(sigFromSrams_bore_7_ram_mcp_hold),
    .sigFromSrams_bore_7_cgen(sigFromSrams_bore_7_cgen),
    .sigFromSrams_bore_8_ram_hold(sigFromSrams_bore_8_ram_hold),
    .sigFromSrams_bore_8_ram_bypass(sigFromSrams_bore_8_ram_bypass),
    .sigFromSrams_bore_8_ram_bp_clken(sigFromSrams_bore_8_ram_bp_clken),
    .sigFromSrams_bore_8_ram_aux_clk(sigFromSrams_bore_8_ram_aux_clk),
    .sigFromSrams_bore_8_ram_aux_ckbp(sigFromSrams_bore_8_ram_aux_ckbp),
    .sigFromSrams_bore_8_ram_mcp_hold(sigFromSrams_bore_8_ram_mcp_hold),
    .sigFromSrams_bore_8_cgen(sigFromSrams_bore_8_cgen),
    .sigFromSrams_bore_9_ram_hold(sigFromSrams_bore_9_ram_hold),
    .sigFromSrams_bore_9_ram_bypass(sigFromSrams_bore_9_ram_bypass),
    .sigFromSrams_bore_9_ram_bp_clken(sigFromSrams_bore_9_ram_bp_clken),
    .sigFromSrams_bore_9_ram_aux_clk(sigFromSrams_bore_9_ram_aux_clk),
    .sigFromSrams_bore_9_ram_aux_ckbp(sigFromSrams_bore_9_ram_aux_ckbp),
    .sigFromSrams_bore_9_ram_mcp_hold(sigFromSrams_bore_9_ram_mcp_hold),
    .sigFromSrams_bore_9_cgen(sigFromSrams_bore_9_cgen),
    .sigFromSrams_bore_10_ram_hold(sigFromSrams_bore_10_ram_hold),
    .sigFromSrams_bore_10_ram_bypass(sigFromSrams_bore_10_ram_bypass),
    .sigFromSrams_bore_10_ram_bp_clken(sigFromSrams_bore_10_ram_bp_clken),
    .sigFromSrams_bore_10_ram_aux_clk(sigFromSrams_bore_10_ram_aux_clk),
    .sigFromSrams_bore_10_ram_aux_ckbp(sigFromSrams_bore_10_ram_aux_ckbp),
    .sigFromSrams_bore_10_ram_mcp_hold(sigFromSrams_bore_10_ram_mcp_hold),
    .sigFromSrams_bore_10_cgen(sigFromSrams_bore_10_cgen),
    .sigFromSrams_bore_11_ram_hold(sigFromSrams_bore_11_ram_hold),
    .sigFromSrams_bore_11_ram_bypass(sigFromSrams_bore_11_ram_bypass),
    .sigFromSrams_bore_11_ram_bp_clken(sigFromSrams_bore_11_ram_bp_clken),
    .sigFromSrams_bore_11_ram_aux_clk(sigFromSrams_bore_11_ram_aux_clk),
    .sigFromSrams_bore_11_ram_aux_ckbp(sigFromSrams_bore_11_ram_aux_ckbp),
    .sigFromSrams_bore_11_ram_mcp_hold(sigFromSrams_bore_11_ram_mcp_hold),
    .sigFromSrams_bore_11_cgen(sigFromSrams_bore_11_cgen),
    .cg_bore_cgen(cg_bore_cgen),
    .auto_out_a_valid(i_auto_out_a_valid),
    .auto_out_a_bits_source(i_auto_out_a_bits_source),
    .auto_out_a_bits_address(i_auto_out_a_bits_address),
    .io_tlb_0_req_0_ready(i_io_tlb_0_req_0_ready),
    .io_tlb_0_resp_valid(i_io_tlb_0_resp_valid),
    .io_tlb_0_resp_bits_s2xlate(i_io_tlb_0_resp_bits_s2xlate),
    .io_tlb_0_resp_bits_s1_entry_tag(i_io_tlb_0_resp_bits_s1_entry_tag),
    .io_tlb_0_resp_bits_s1_entry_asid(i_io_tlb_0_resp_bits_s1_entry_asid),
    .io_tlb_0_resp_bits_s1_entry_vmid(i_io_tlb_0_resp_bits_s1_entry_vmid),
    .io_tlb_0_resp_bits_s1_entry_n(i_io_tlb_0_resp_bits_s1_entry_n),
    .io_tlb_0_resp_bits_s1_entry_pbmt(i_io_tlb_0_resp_bits_s1_entry_pbmt),
    .io_tlb_0_resp_bits_s1_entry_perm_d(i_io_tlb_0_resp_bits_s1_entry_perm_d),
    .io_tlb_0_resp_bits_s1_entry_perm_a(i_io_tlb_0_resp_bits_s1_entry_perm_a),
    .io_tlb_0_resp_bits_s1_entry_perm_g(i_io_tlb_0_resp_bits_s1_entry_perm_g),
    .io_tlb_0_resp_bits_s1_entry_perm_u(i_io_tlb_0_resp_bits_s1_entry_perm_u),
    .io_tlb_0_resp_bits_s1_entry_perm_x(i_io_tlb_0_resp_bits_s1_entry_perm_x),
    .io_tlb_0_resp_bits_s1_entry_perm_w(i_io_tlb_0_resp_bits_s1_entry_perm_w),
    .io_tlb_0_resp_bits_s1_entry_perm_r(i_io_tlb_0_resp_bits_s1_entry_perm_r),
    .io_tlb_0_resp_bits_s1_entry_level(i_io_tlb_0_resp_bits_s1_entry_level),
    .io_tlb_0_resp_bits_s1_entry_v(i_io_tlb_0_resp_bits_s1_entry_v),
    .io_tlb_0_resp_bits_s1_entry_ppn(i_io_tlb_0_resp_bits_s1_entry_ppn),
    .io_tlb_0_resp_bits_s1_addr_low(i_io_tlb_0_resp_bits_s1_addr_low),
    .io_tlb_0_resp_bits_s1_ppn_low_0(i_io_tlb_0_resp_bits_s1_ppn_low_0),
    .io_tlb_0_resp_bits_s1_ppn_low_1(i_io_tlb_0_resp_bits_s1_ppn_low_1),
    .io_tlb_0_resp_bits_s1_ppn_low_2(i_io_tlb_0_resp_bits_s1_ppn_low_2),
    .io_tlb_0_resp_bits_s1_ppn_low_3(i_io_tlb_0_resp_bits_s1_ppn_low_3),
    .io_tlb_0_resp_bits_s1_ppn_low_4(i_io_tlb_0_resp_bits_s1_ppn_low_4),
    .io_tlb_0_resp_bits_s1_ppn_low_5(i_io_tlb_0_resp_bits_s1_ppn_low_5),
    .io_tlb_0_resp_bits_s1_ppn_low_6(i_io_tlb_0_resp_bits_s1_ppn_low_6),
    .io_tlb_0_resp_bits_s1_ppn_low_7(i_io_tlb_0_resp_bits_s1_ppn_low_7),
    .io_tlb_0_resp_bits_s1_valididx_0(i_io_tlb_0_resp_bits_s1_valididx_0),
    .io_tlb_0_resp_bits_s1_valididx_1(i_io_tlb_0_resp_bits_s1_valididx_1),
    .io_tlb_0_resp_bits_s1_valididx_2(i_io_tlb_0_resp_bits_s1_valididx_2),
    .io_tlb_0_resp_bits_s1_valididx_3(i_io_tlb_0_resp_bits_s1_valididx_3),
    .io_tlb_0_resp_bits_s1_valididx_4(i_io_tlb_0_resp_bits_s1_valididx_4),
    .io_tlb_0_resp_bits_s1_valididx_5(i_io_tlb_0_resp_bits_s1_valididx_5),
    .io_tlb_0_resp_bits_s1_valididx_6(i_io_tlb_0_resp_bits_s1_valididx_6),
    .io_tlb_0_resp_bits_s1_valididx_7(i_io_tlb_0_resp_bits_s1_valididx_7),
    .io_tlb_0_resp_bits_s1_pteidx_0(i_io_tlb_0_resp_bits_s1_pteidx_0),
    .io_tlb_0_resp_bits_s1_pteidx_1(i_io_tlb_0_resp_bits_s1_pteidx_1),
    .io_tlb_0_resp_bits_s1_pteidx_2(i_io_tlb_0_resp_bits_s1_pteidx_2),
    .io_tlb_0_resp_bits_s1_pteidx_3(i_io_tlb_0_resp_bits_s1_pteidx_3),
    .io_tlb_0_resp_bits_s1_pteidx_4(i_io_tlb_0_resp_bits_s1_pteidx_4),
    .io_tlb_0_resp_bits_s1_pteidx_5(i_io_tlb_0_resp_bits_s1_pteidx_5),
    .io_tlb_0_resp_bits_s1_pteidx_6(i_io_tlb_0_resp_bits_s1_pteidx_6),
    .io_tlb_0_resp_bits_s1_pteidx_7(i_io_tlb_0_resp_bits_s1_pteidx_7),
    .io_tlb_0_resp_bits_s1_pf(i_io_tlb_0_resp_bits_s1_pf),
    .io_tlb_0_resp_bits_s1_af(i_io_tlb_0_resp_bits_s1_af),
    .io_tlb_0_resp_bits_s2_entry_tag(i_io_tlb_0_resp_bits_s2_entry_tag),
    .io_tlb_0_resp_bits_s2_entry_vmid(i_io_tlb_0_resp_bits_s2_entry_vmid),
    .io_tlb_0_resp_bits_s2_entry_n(i_io_tlb_0_resp_bits_s2_entry_n),
    .io_tlb_0_resp_bits_s2_entry_pbmt(i_io_tlb_0_resp_bits_s2_entry_pbmt),
    .io_tlb_0_resp_bits_s2_entry_ppn(i_io_tlb_0_resp_bits_s2_entry_ppn),
    .io_tlb_0_resp_bits_s2_entry_perm_d(i_io_tlb_0_resp_bits_s2_entry_perm_d),
    .io_tlb_0_resp_bits_s2_entry_perm_a(i_io_tlb_0_resp_bits_s2_entry_perm_a),
    .io_tlb_0_resp_bits_s2_entry_perm_g(i_io_tlb_0_resp_bits_s2_entry_perm_g),
    .io_tlb_0_resp_bits_s2_entry_perm_u(i_io_tlb_0_resp_bits_s2_entry_perm_u),
    .io_tlb_0_resp_bits_s2_entry_perm_x(i_io_tlb_0_resp_bits_s2_entry_perm_x),
    .io_tlb_0_resp_bits_s2_entry_perm_w(i_io_tlb_0_resp_bits_s2_entry_perm_w),
    .io_tlb_0_resp_bits_s2_entry_perm_r(i_io_tlb_0_resp_bits_s2_entry_perm_r),
    .io_tlb_0_resp_bits_s2_entry_level(i_io_tlb_0_resp_bits_s2_entry_level),
    .io_tlb_0_resp_bits_s2_gpf(i_io_tlb_0_resp_bits_s2_gpf),
    .io_tlb_0_resp_bits_s2_gaf(i_io_tlb_0_resp_bits_s2_gaf),
    .io_tlb_1_req_0_ready(i_io_tlb_1_req_0_ready),
    .io_tlb_1_resp_valid(i_io_tlb_1_resp_valid),
    .io_tlb_1_resp_bits_s2xlate(i_io_tlb_1_resp_bits_s2xlate),
    .io_tlb_1_resp_bits_s1_entry_tag(i_io_tlb_1_resp_bits_s1_entry_tag),
    .io_tlb_1_resp_bits_s1_entry_asid(i_io_tlb_1_resp_bits_s1_entry_asid),
    .io_tlb_1_resp_bits_s1_entry_vmid(i_io_tlb_1_resp_bits_s1_entry_vmid),
    .io_tlb_1_resp_bits_s1_entry_n(i_io_tlb_1_resp_bits_s1_entry_n),
    .io_tlb_1_resp_bits_s1_entry_pbmt(i_io_tlb_1_resp_bits_s1_entry_pbmt),
    .io_tlb_1_resp_bits_s1_entry_perm_d(i_io_tlb_1_resp_bits_s1_entry_perm_d),
    .io_tlb_1_resp_bits_s1_entry_perm_a(i_io_tlb_1_resp_bits_s1_entry_perm_a),
    .io_tlb_1_resp_bits_s1_entry_perm_g(i_io_tlb_1_resp_bits_s1_entry_perm_g),
    .io_tlb_1_resp_bits_s1_entry_perm_u(i_io_tlb_1_resp_bits_s1_entry_perm_u),
    .io_tlb_1_resp_bits_s1_entry_perm_x(i_io_tlb_1_resp_bits_s1_entry_perm_x),
    .io_tlb_1_resp_bits_s1_entry_perm_w(i_io_tlb_1_resp_bits_s1_entry_perm_w),
    .io_tlb_1_resp_bits_s1_entry_perm_r(i_io_tlb_1_resp_bits_s1_entry_perm_r),
    .io_tlb_1_resp_bits_s1_entry_level(i_io_tlb_1_resp_bits_s1_entry_level),
    .io_tlb_1_resp_bits_s1_entry_v(i_io_tlb_1_resp_bits_s1_entry_v),
    .io_tlb_1_resp_bits_s1_entry_ppn(i_io_tlb_1_resp_bits_s1_entry_ppn),
    .io_tlb_1_resp_bits_s1_addr_low(i_io_tlb_1_resp_bits_s1_addr_low),
    .io_tlb_1_resp_bits_s1_ppn_low_0(i_io_tlb_1_resp_bits_s1_ppn_low_0),
    .io_tlb_1_resp_bits_s1_ppn_low_1(i_io_tlb_1_resp_bits_s1_ppn_low_1),
    .io_tlb_1_resp_bits_s1_ppn_low_2(i_io_tlb_1_resp_bits_s1_ppn_low_2),
    .io_tlb_1_resp_bits_s1_ppn_low_3(i_io_tlb_1_resp_bits_s1_ppn_low_3),
    .io_tlb_1_resp_bits_s1_ppn_low_4(i_io_tlb_1_resp_bits_s1_ppn_low_4),
    .io_tlb_1_resp_bits_s1_ppn_low_5(i_io_tlb_1_resp_bits_s1_ppn_low_5),
    .io_tlb_1_resp_bits_s1_ppn_low_6(i_io_tlb_1_resp_bits_s1_ppn_low_6),
    .io_tlb_1_resp_bits_s1_ppn_low_7(i_io_tlb_1_resp_bits_s1_ppn_low_7),
    .io_tlb_1_resp_bits_s1_valididx_0(i_io_tlb_1_resp_bits_s1_valididx_0),
    .io_tlb_1_resp_bits_s1_valididx_1(i_io_tlb_1_resp_bits_s1_valididx_1),
    .io_tlb_1_resp_bits_s1_valididx_2(i_io_tlb_1_resp_bits_s1_valididx_2),
    .io_tlb_1_resp_bits_s1_valididx_3(i_io_tlb_1_resp_bits_s1_valididx_3),
    .io_tlb_1_resp_bits_s1_valididx_4(i_io_tlb_1_resp_bits_s1_valididx_4),
    .io_tlb_1_resp_bits_s1_valididx_5(i_io_tlb_1_resp_bits_s1_valididx_5),
    .io_tlb_1_resp_bits_s1_valididx_6(i_io_tlb_1_resp_bits_s1_valididx_6),
    .io_tlb_1_resp_bits_s1_valididx_7(i_io_tlb_1_resp_bits_s1_valididx_7),
    .io_tlb_1_resp_bits_s1_pteidx_0(i_io_tlb_1_resp_bits_s1_pteidx_0),
    .io_tlb_1_resp_bits_s1_pteidx_1(i_io_tlb_1_resp_bits_s1_pteidx_1),
    .io_tlb_1_resp_bits_s1_pteidx_2(i_io_tlb_1_resp_bits_s1_pteidx_2),
    .io_tlb_1_resp_bits_s1_pteidx_3(i_io_tlb_1_resp_bits_s1_pteidx_3),
    .io_tlb_1_resp_bits_s1_pteidx_4(i_io_tlb_1_resp_bits_s1_pteidx_4),
    .io_tlb_1_resp_bits_s1_pteidx_5(i_io_tlb_1_resp_bits_s1_pteidx_5),
    .io_tlb_1_resp_bits_s1_pteidx_6(i_io_tlb_1_resp_bits_s1_pteidx_6),
    .io_tlb_1_resp_bits_s1_pteidx_7(i_io_tlb_1_resp_bits_s1_pteidx_7),
    .io_tlb_1_resp_bits_s1_pf(i_io_tlb_1_resp_bits_s1_pf),
    .io_tlb_1_resp_bits_s1_af(i_io_tlb_1_resp_bits_s1_af),
    .io_tlb_1_resp_bits_s2_entry_tag(i_io_tlb_1_resp_bits_s2_entry_tag),
    .io_tlb_1_resp_bits_s2_entry_vmid(i_io_tlb_1_resp_bits_s2_entry_vmid),
    .io_tlb_1_resp_bits_s2_entry_n(i_io_tlb_1_resp_bits_s2_entry_n),
    .io_tlb_1_resp_bits_s2_entry_pbmt(i_io_tlb_1_resp_bits_s2_entry_pbmt),
    .io_tlb_1_resp_bits_s2_entry_ppn(i_io_tlb_1_resp_bits_s2_entry_ppn),
    .io_tlb_1_resp_bits_s2_entry_perm_d(i_io_tlb_1_resp_bits_s2_entry_perm_d),
    .io_tlb_1_resp_bits_s2_entry_perm_a(i_io_tlb_1_resp_bits_s2_entry_perm_a),
    .io_tlb_1_resp_bits_s2_entry_perm_g(i_io_tlb_1_resp_bits_s2_entry_perm_g),
    .io_tlb_1_resp_bits_s2_entry_perm_u(i_io_tlb_1_resp_bits_s2_entry_perm_u),
    .io_tlb_1_resp_bits_s2_entry_perm_x(i_io_tlb_1_resp_bits_s2_entry_perm_x),
    .io_tlb_1_resp_bits_s2_entry_perm_w(i_io_tlb_1_resp_bits_s2_entry_perm_w),
    .io_tlb_1_resp_bits_s2_entry_perm_r(i_io_tlb_1_resp_bits_s2_entry_perm_r),
    .io_tlb_1_resp_bits_s2_entry_level(i_io_tlb_1_resp_bits_s2_entry_level),
    .io_tlb_1_resp_bits_s2_gpf(i_io_tlb_1_resp_bits_s2_gpf),
    .io_tlb_1_resp_bits_s2_gaf(i_io_tlb_1_resp_bits_s2_gaf),
    .io_wfi_wfiSafe(i_io_wfi_wfiSafe),
    .io_perf_0_value(i_io_perf_0_value),
    .io_perf_1_value(i_io_perf_1_value),
    .io_perf_2_value(i_io_perf_2_value),
    .io_perf_3_value(i_io_perf_3_value),
    .io_perf_4_value(i_io_perf_4_value),
    .io_perf_5_value(i_io_perf_5_value),
    .io_perf_6_value(i_io_perf_6_value),
    .io_perf_7_value(i_io_perf_7_value),
    .io_perf_8_value(i_io_perf_8_value),
    .io_perf_9_value(i_io_perf_9_value),
    .io_perf_10_value(i_io_perf_10_value),
    .io_perf_11_value(i_io_perf_11_value),
    .io_perf_12_value(i_io_perf_12_value),
    .io_perf_13_value(i_io_perf_13_value),
    .io_perf_14_value(i_io_perf_14_value),
    .io_perf_15_value(i_io_perf_15_value),
    .io_perf_16_value(i_io_perf_16_value),
    .io_perf_17_value(i_io_perf_17_value),
    .io_perf_18_value(i_io_perf_18_value),
    .boreChildrenBd_bore_ack(i_boreChildrenBd_bore_ack),
    .boreChildrenBd_bore_outdata(i_boreChildrenBd_bore_outdata),
    .boreChildrenBd_bore_1_ack(i_boreChildrenBd_bore_1_ack),
    .boreChildrenBd_bore_1_outdata(i_boreChildrenBd_bore_1_outdata)
  );

  // ---- 逐拍比对：功能输出 -> errors；DFT/MBIST 旁路输出 -> nonfunc_errors ----
  always @(negedge clk) if (!rst) begin
    #4;
    if (cyc > WARMUP) begin
      checks++;
      if (g_auto_out_a_valid === 1'b1) act_mem_req++;
      if (g_io_tlb_0_resp_valid === 1'b1) act_tlb0_resp++;
      if (g_io_tlb_1_resp_valid === 1'b1) act_tlb1_resp++;
      if (!$isunknown(g_auto_out_a_valid) && g_auto_out_a_valid !== i_auto_out_a_valid) begin errors++;
        if (errors<=60) $display("[%0t] auto_out_a_valid g=%h i=%h", $time, g_auto_out_a_valid, i_auto_out_a_valid); end
      if (!$isunknown(g_auto_out_a_bits_source) && g_auto_out_a_bits_source !== i_auto_out_a_bits_source) begin errors++;
        if (errors<=60) $display("[%0t] auto_out_a_bits_source g=%h i=%h", $time, g_auto_out_a_bits_source, i_auto_out_a_bits_source); end
      if (!$isunknown(g_auto_out_a_bits_address) && g_auto_out_a_bits_address !== i_auto_out_a_bits_address) begin errors++;
        if (errors<=60) $display("[%0t] auto_out_a_bits_address g=%h i=%h", $time, g_auto_out_a_bits_address, i_auto_out_a_bits_address); end
      if (!$isunknown(g_io_tlb_0_req_0_ready) && g_io_tlb_0_req_0_ready !== i_io_tlb_0_req_0_ready) begin errors++;
        if (errors<=60) $display("[%0t] io_tlb_0_req_0_ready g=%h i=%h", $time, g_io_tlb_0_req_0_ready, i_io_tlb_0_req_0_ready); end
      if (!$isunknown(g_io_tlb_0_resp_valid) && g_io_tlb_0_resp_valid !== i_io_tlb_0_resp_valid) begin errors++;
        if (errors<=60) $display("[%0t] io_tlb_0_resp_valid g=%h i=%h", $time, g_io_tlb_0_resp_valid, i_io_tlb_0_resp_valid); end
      if (!$isunknown(g_io_tlb_0_resp_bits_s2xlate) && g_io_tlb_0_resp_bits_s2xlate !== i_io_tlb_0_resp_bits_s2xlate) begin errors++;
        if (errors<=60) $display("[%0t] io_tlb_0_resp_bits_s2xlate g=%h i=%h", $time, g_io_tlb_0_resp_bits_s2xlate, i_io_tlb_0_resp_bits_s2xlate); end
      if (!$isunknown(g_io_tlb_0_resp_bits_s1_entry_tag) && g_io_tlb_0_resp_bits_s1_entry_tag !== i_io_tlb_0_resp_bits_s1_entry_tag) begin errors++;
        if (errors<=60) $display("[%0t] io_tlb_0_resp_bits_s1_entry_tag g=%h i=%h", $time, g_io_tlb_0_resp_bits_s1_entry_tag, i_io_tlb_0_resp_bits_s1_entry_tag); end
      if (!$isunknown(g_io_tlb_0_resp_bits_s1_entry_asid) && g_io_tlb_0_resp_bits_s1_entry_asid !== i_io_tlb_0_resp_bits_s1_entry_asid) begin errors++;
        if (errors<=60) $display("[%0t] io_tlb_0_resp_bits_s1_entry_asid g=%h i=%h", $time, g_io_tlb_0_resp_bits_s1_entry_asid, i_io_tlb_0_resp_bits_s1_entry_asid); end
      if (!$isunknown(g_io_tlb_0_resp_bits_s1_entry_vmid) && g_io_tlb_0_resp_bits_s1_entry_vmid !== i_io_tlb_0_resp_bits_s1_entry_vmid) begin errors++;
        if (errors<=60) $display("[%0t] io_tlb_0_resp_bits_s1_entry_vmid g=%h i=%h", $time, g_io_tlb_0_resp_bits_s1_entry_vmid, i_io_tlb_0_resp_bits_s1_entry_vmid); end
      if (!$isunknown(g_io_tlb_0_resp_bits_s1_entry_n) && g_io_tlb_0_resp_bits_s1_entry_n !== i_io_tlb_0_resp_bits_s1_entry_n) begin errors++;
        if (errors<=60) $display("[%0t] io_tlb_0_resp_bits_s1_entry_n g=%h i=%h", $time, g_io_tlb_0_resp_bits_s1_entry_n, i_io_tlb_0_resp_bits_s1_entry_n); end
      if (!$isunknown(g_io_tlb_0_resp_bits_s1_entry_pbmt) && g_io_tlb_0_resp_bits_s1_entry_pbmt !== i_io_tlb_0_resp_bits_s1_entry_pbmt) begin errors++;
        if (errors<=60) $display("[%0t] io_tlb_0_resp_bits_s1_entry_pbmt g=%h i=%h", $time, g_io_tlb_0_resp_bits_s1_entry_pbmt, i_io_tlb_0_resp_bits_s1_entry_pbmt); end
      if (!$isunknown(g_io_tlb_0_resp_bits_s1_entry_perm_d) && g_io_tlb_0_resp_bits_s1_entry_perm_d !== i_io_tlb_0_resp_bits_s1_entry_perm_d) begin errors++;
        if (errors<=60) $display("[%0t] io_tlb_0_resp_bits_s1_entry_perm_d g=%h i=%h", $time, g_io_tlb_0_resp_bits_s1_entry_perm_d, i_io_tlb_0_resp_bits_s1_entry_perm_d); end
      if (!$isunknown(g_io_tlb_0_resp_bits_s1_entry_perm_a) && g_io_tlb_0_resp_bits_s1_entry_perm_a !== i_io_tlb_0_resp_bits_s1_entry_perm_a) begin errors++;
        if (errors<=60) $display("[%0t] io_tlb_0_resp_bits_s1_entry_perm_a g=%h i=%h", $time, g_io_tlb_0_resp_bits_s1_entry_perm_a, i_io_tlb_0_resp_bits_s1_entry_perm_a); end
      if (!$isunknown(g_io_tlb_0_resp_bits_s1_entry_perm_g) && g_io_tlb_0_resp_bits_s1_entry_perm_g !== i_io_tlb_0_resp_bits_s1_entry_perm_g) begin errors++;
        if (errors<=60) $display("[%0t] io_tlb_0_resp_bits_s1_entry_perm_g g=%h i=%h", $time, g_io_tlb_0_resp_bits_s1_entry_perm_g, i_io_tlb_0_resp_bits_s1_entry_perm_g); end
      if (!$isunknown(g_io_tlb_0_resp_bits_s1_entry_perm_u) && g_io_tlb_0_resp_bits_s1_entry_perm_u !== i_io_tlb_0_resp_bits_s1_entry_perm_u) begin errors++;
        if (errors<=60) $display("[%0t] io_tlb_0_resp_bits_s1_entry_perm_u g=%h i=%h", $time, g_io_tlb_0_resp_bits_s1_entry_perm_u, i_io_tlb_0_resp_bits_s1_entry_perm_u); end
      if (!$isunknown(g_io_tlb_0_resp_bits_s1_entry_perm_x) && g_io_tlb_0_resp_bits_s1_entry_perm_x !== i_io_tlb_0_resp_bits_s1_entry_perm_x) begin errors++;
        if (errors<=60) $display("[%0t] io_tlb_0_resp_bits_s1_entry_perm_x g=%h i=%h", $time, g_io_tlb_0_resp_bits_s1_entry_perm_x, i_io_tlb_0_resp_bits_s1_entry_perm_x); end
      if (!$isunknown(g_io_tlb_0_resp_bits_s1_entry_perm_w) && g_io_tlb_0_resp_bits_s1_entry_perm_w !== i_io_tlb_0_resp_bits_s1_entry_perm_w) begin errors++;
        if (errors<=60) $display("[%0t] io_tlb_0_resp_bits_s1_entry_perm_w g=%h i=%h", $time, g_io_tlb_0_resp_bits_s1_entry_perm_w, i_io_tlb_0_resp_bits_s1_entry_perm_w); end
      if (!$isunknown(g_io_tlb_0_resp_bits_s1_entry_perm_r) && g_io_tlb_0_resp_bits_s1_entry_perm_r !== i_io_tlb_0_resp_bits_s1_entry_perm_r) begin errors++;
        if (errors<=60) $display("[%0t] io_tlb_0_resp_bits_s1_entry_perm_r g=%h i=%h", $time, g_io_tlb_0_resp_bits_s1_entry_perm_r, i_io_tlb_0_resp_bits_s1_entry_perm_r); end
      if (!$isunknown(g_io_tlb_0_resp_bits_s1_entry_level) && g_io_tlb_0_resp_bits_s1_entry_level !== i_io_tlb_0_resp_bits_s1_entry_level) begin errors++;
        if (errors<=60) $display("[%0t] io_tlb_0_resp_bits_s1_entry_level g=%h i=%h", $time, g_io_tlb_0_resp_bits_s1_entry_level, i_io_tlb_0_resp_bits_s1_entry_level); end
      if (!$isunknown(g_io_tlb_0_resp_bits_s1_entry_v) && g_io_tlb_0_resp_bits_s1_entry_v !== i_io_tlb_0_resp_bits_s1_entry_v) begin errors++;
        if (errors<=60) $display("[%0t] io_tlb_0_resp_bits_s1_entry_v g=%h i=%h", $time, g_io_tlb_0_resp_bits_s1_entry_v, i_io_tlb_0_resp_bits_s1_entry_v); end
      if (!$isunknown(g_io_tlb_0_resp_bits_s1_entry_ppn) && g_io_tlb_0_resp_bits_s1_entry_ppn !== i_io_tlb_0_resp_bits_s1_entry_ppn) begin errors++;
        if (errors<=60) $display("[%0t] io_tlb_0_resp_bits_s1_entry_ppn g=%h i=%h", $time, g_io_tlb_0_resp_bits_s1_entry_ppn, i_io_tlb_0_resp_bits_s1_entry_ppn); end
      if (!$isunknown(g_io_tlb_0_resp_bits_s1_addr_low) && g_io_tlb_0_resp_bits_s1_addr_low !== i_io_tlb_0_resp_bits_s1_addr_low) begin errors++;
        if (errors<=60) $display("[%0t] io_tlb_0_resp_bits_s1_addr_low g=%h i=%h", $time, g_io_tlb_0_resp_bits_s1_addr_low, i_io_tlb_0_resp_bits_s1_addr_low); end
      if (!$isunknown(g_io_tlb_0_resp_bits_s1_ppn_low_0) && g_io_tlb_0_resp_bits_s1_ppn_low_0 !== i_io_tlb_0_resp_bits_s1_ppn_low_0) begin errors++;
        if (errors<=60) $display("[%0t] io_tlb_0_resp_bits_s1_ppn_low_0 g=%h i=%h", $time, g_io_tlb_0_resp_bits_s1_ppn_low_0, i_io_tlb_0_resp_bits_s1_ppn_low_0); end
      if (!$isunknown(g_io_tlb_0_resp_bits_s1_ppn_low_1) && g_io_tlb_0_resp_bits_s1_ppn_low_1 !== i_io_tlb_0_resp_bits_s1_ppn_low_1) begin errors++;
        if (errors<=60) $display("[%0t] io_tlb_0_resp_bits_s1_ppn_low_1 g=%h i=%h", $time, g_io_tlb_0_resp_bits_s1_ppn_low_1, i_io_tlb_0_resp_bits_s1_ppn_low_1); end
      if (!$isunknown(g_io_tlb_0_resp_bits_s1_ppn_low_2) && g_io_tlb_0_resp_bits_s1_ppn_low_2 !== i_io_tlb_0_resp_bits_s1_ppn_low_2) begin errors++;
        if (errors<=60) $display("[%0t] io_tlb_0_resp_bits_s1_ppn_low_2 g=%h i=%h", $time, g_io_tlb_0_resp_bits_s1_ppn_low_2, i_io_tlb_0_resp_bits_s1_ppn_low_2); end
      if (!$isunknown(g_io_tlb_0_resp_bits_s1_ppn_low_3) && g_io_tlb_0_resp_bits_s1_ppn_low_3 !== i_io_tlb_0_resp_bits_s1_ppn_low_3) begin errors++;
        if (errors<=60) $display("[%0t] io_tlb_0_resp_bits_s1_ppn_low_3 g=%h i=%h", $time, g_io_tlb_0_resp_bits_s1_ppn_low_3, i_io_tlb_0_resp_bits_s1_ppn_low_3); end
      if (!$isunknown(g_io_tlb_0_resp_bits_s1_ppn_low_4) && g_io_tlb_0_resp_bits_s1_ppn_low_4 !== i_io_tlb_0_resp_bits_s1_ppn_low_4) begin errors++;
        if (errors<=60) $display("[%0t] io_tlb_0_resp_bits_s1_ppn_low_4 g=%h i=%h", $time, g_io_tlb_0_resp_bits_s1_ppn_low_4, i_io_tlb_0_resp_bits_s1_ppn_low_4); end
      if (!$isunknown(g_io_tlb_0_resp_bits_s1_ppn_low_5) && g_io_tlb_0_resp_bits_s1_ppn_low_5 !== i_io_tlb_0_resp_bits_s1_ppn_low_5) begin errors++;
        if (errors<=60) $display("[%0t] io_tlb_0_resp_bits_s1_ppn_low_5 g=%h i=%h", $time, g_io_tlb_0_resp_bits_s1_ppn_low_5, i_io_tlb_0_resp_bits_s1_ppn_low_5); end
      if (!$isunknown(g_io_tlb_0_resp_bits_s1_ppn_low_6) && g_io_tlb_0_resp_bits_s1_ppn_low_6 !== i_io_tlb_0_resp_bits_s1_ppn_low_6) begin errors++;
        if (errors<=60) $display("[%0t] io_tlb_0_resp_bits_s1_ppn_low_6 g=%h i=%h", $time, g_io_tlb_0_resp_bits_s1_ppn_low_6, i_io_tlb_0_resp_bits_s1_ppn_low_6); end
      if (!$isunknown(g_io_tlb_0_resp_bits_s1_ppn_low_7) && g_io_tlb_0_resp_bits_s1_ppn_low_7 !== i_io_tlb_0_resp_bits_s1_ppn_low_7) begin errors++;
        if (errors<=60) $display("[%0t] io_tlb_0_resp_bits_s1_ppn_low_7 g=%h i=%h", $time, g_io_tlb_0_resp_bits_s1_ppn_low_7, i_io_tlb_0_resp_bits_s1_ppn_low_7); end
      if (!$isunknown(g_io_tlb_0_resp_bits_s1_valididx_0) && g_io_tlb_0_resp_bits_s1_valididx_0 !== i_io_tlb_0_resp_bits_s1_valididx_0) begin errors++;
        if (errors<=60) $display("[%0t] io_tlb_0_resp_bits_s1_valididx_0 g=%h i=%h", $time, g_io_tlb_0_resp_bits_s1_valididx_0, i_io_tlb_0_resp_bits_s1_valididx_0); end
      if (!$isunknown(g_io_tlb_0_resp_bits_s1_valididx_1) && g_io_tlb_0_resp_bits_s1_valididx_1 !== i_io_tlb_0_resp_bits_s1_valididx_1) begin errors++;
        if (errors<=60) $display("[%0t] io_tlb_0_resp_bits_s1_valididx_1 g=%h i=%h", $time, g_io_tlb_0_resp_bits_s1_valididx_1, i_io_tlb_0_resp_bits_s1_valididx_1); end
      if (!$isunknown(g_io_tlb_0_resp_bits_s1_valididx_2) && g_io_tlb_0_resp_bits_s1_valididx_2 !== i_io_tlb_0_resp_bits_s1_valididx_2) begin errors++;
        if (errors<=60) $display("[%0t] io_tlb_0_resp_bits_s1_valididx_2 g=%h i=%h", $time, g_io_tlb_0_resp_bits_s1_valididx_2, i_io_tlb_0_resp_bits_s1_valididx_2); end
      if (!$isunknown(g_io_tlb_0_resp_bits_s1_valididx_3) && g_io_tlb_0_resp_bits_s1_valididx_3 !== i_io_tlb_0_resp_bits_s1_valididx_3) begin errors++;
        if (errors<=60) $display("[%0t] io_tlb_0_resp_bits_s1_valididx_3 g=%h i=%h", $time, g_io_tlb_0_resp_bits_s1_valididx_3, i_io_tlb_0_resp_bits_s1_valididx_3); end
      if (!$isunknown(g_io_tlb_0_resp_bits_s1_valididx_4) && g_io_tlb_0_resp_bits_s1_valididx_4 !== i_io_tlb_0_resp_bits_s1_valididx_4) begin errors++;
        if (errors<=60) $display("[%0t] io_tlb_0_resp_bits_s1_valididx_4 g=%h i=%h", $time, g_io_tlb_0_resp_bits_s1_valididx_4, i_io_tlb_0_resp_bits_s1_valididx_4); end
      if (!$isunknown(g_io_tlb_0_resp_bits_s1_valididx_5) && g_io_tlb_0_resp_bits_s1_valididx_5 !== i_io_tlb_0_resp_bits_s1_valididx_5) begin errors++;
        if (errors<=60) $display("[%0t] io_tlb_0_resp_bits_s1_valididx_5 g=%h i=%h", $time, g_io_tlb_0_resp_bits_s1_valididx_5, i_io_tlb_0_resp_bits_s1_valididx_5); end
      if (!$isunknown(g_io_tlb_0_resp_bits_s1_valididx_6) && g_io_tlb_0_resp_bits_s1_valididx_6 !== i_io_tlb_0_resp_bits_s1_valididx_6) begin errors++;
        if (errors<=60) $display("[%0t] io_tlb_0_resp_bits_s1_valididx_6 g=%h i=%h", $time, g_io_tlb_0_resp_bits_s1_valididx_6, i_io_tlb_0_resp_bits_s1_valididx_6); end
      if (!$isunknown(g_io_tlb_0_resp_bits_s1_valididx_7) && g_io_tlb_0_resp_bits_s1_valididx_7 !== i_io_tlb_0_resp_bits_s1_valididx_7) begin errors++;
        if (errors<=60) $display("[%0t] io_tlb_0_resp_bits_s1_valididx_7 g=%h i=%h", $time, g_io_tlb_0_resp_bits_s1_valididx_7, i_io_tlb_0_resp_bits_s1_valididx_7); end
      if (!$isunknown(g_io_tlb_0_resp_bits_s1_pteidx_0) && g_io_tlb_0_resp_bits_s1_pteidx_0 !== i_io_tlb_0_resp_bits_s1_pteidx_0) begin errors++;
        if (errors<=60) $display("[%0t] io_tlb_0_resp_bits_s1_pteidx_0 g=%h i=%h", $time, g_io_tlb_0_resp_bits_s1_pteidx_0, i_io_tlb_0_resp_bits_s1_pteidx_0); end
      if (!$isunknown(g_io_tlb_0_resp_bits_s1_pteidx_1) && g_io_tlb_0_resp_bits_s1_pteidx_1 !== i_io_tlb_0_resp_bits_s1_pteidx_1) begin errors++;
        if (errors<=60) $display("[%0t] io_tlb_0_resp_bits_s1_pteidx_1 g=%h i=%h", $time, g_io_tlb_0_resp_bits_s1_pteidx_1, i_io_tlb_0_resp_bits_s1_pteidx_1); end
      if (!$isunknown(g_io_tlb_0_resp_bits_s1_pteidx_2) && g_io_tlb_0_resp_bits_s1_pteidx_2 !== i_io_tlb_0_resp_bits_s1_pteidx_2) begin errors++;
        if (errors<=60) $display("[%0t] io_tlb_0_resp_bits_s1_pteidx_2 g=%h i=%h", $time, g_io_tlb_0_resp_bits_s1_pteidx_2, i_io_tlb_0_resp_bits_s1_pteidx_2); end
      if (!$isunknown(g_io_tlb_0_resp_bits_s1_pteidx_3) && g_io_tlb_0_resp_bits_s1_pteidx_3 !== i_io_tlb_0_resp_bits_s1_pteidx_3) begin errors++;
        if (errors<=60) $display("[%0t] io_tlb_0_resp_bits_s1_pteidx_3 g=%h i=%h", $time, g_io_tlb_0_resp_bits_s1_pteidx_3, i_io_tlb_0_resp_bits_s1_pteidx_3); end
      if (!$isunknown(g_io_tlb_0_resp_bits_s1_pteidx_4) && g_io_tlb_0_resp_bits_s1_pteidx_4 !== i_io_tlb_0_resp_bits_s1_pteidx_4) begin errors++;
        if (errors<=60) $display("[%0t] io_tlb_0_resp_bits_s1_pteidx_4 g=%h i=%h", $time, g_io_tlb_0_resp_bits_s1_pteidx_4, i_io_tlb_0_resp_bits_s1_pteidx_4); end
      if (!$isunknown(g_io_tlb_0_resp_bits_s1_pteidx_5) && g_io_tlb_0_resp_bits_s1_pteidx_5 !== i_io_tlb_0_resp_bits_s1_pteidx_5) begin errors++;
        if (errors<=60) $display("[%0t] io_tlb_0_resp_bits_s1_pteidx_5 g=%h i=%h", $time, g_io_tlb_0_resp_bits_s1_pteidx_5, i_io_tlb_0_resp_bits_s1_pteidx_5); end
      if (!$isunknown(g_io_tlb_0_resp_bits_s1_pteidx_6) && g_io_tlb_0_resp_bits_s1_pteidx_6 !== i_io_tlb_0_resp_bits_s1_pteidx_6) begin errors++;
        if (errors<=60) $display("[%0t] io_tlb_0_resp_bits_s1_pteidx_6 g=%h i=%h", $time, g_io_tlb_0_resp_bits_s1_pteidx_6, i_io_tlb_0_resp_bits_s1_pteidx_6); end
      if (!$isunknown(g_io_tlb_0_resp_bits_s1_pteidx_7) && g_io_tlb_0_resp_bits_s1_pteidx_7 !== i_io_tlb_0_resp_bits_s1_pteidx_7) begin errors++;
        if (errors<=60) $display("[%0t] io_tlb_0_resp_bits_s1_pteidx_7 g=%h i=%h", $time, g_io_tlb_0_resp_bits_s1_pteidx_7, i_io_tlb_0_resp_bits_s1_pteidx_7); end
      if (!$isunknown(g_io_tlb_0_resp_bits_s1_pf) && g_io_tlb_0_resp_bits_s1_pf !== i_io_tlb_0_resp_bits_s1_pf) begin errors++;
        if (errors<=60) $display("[%0t] io_tlb_0_resp_bits_s1_pf g=%h i=%h", $time, g_io_tlb_0_resp_bits_s1_pf, i_io_tlb_0_resp_bits_s1_pf); end
      if (!$isunknown(g_io_tlb_0_resp_bits_s1_af) && g_io_tlb_0_resp_bits_s1_af !== i_io_tlb_0_resp_bits_s1_af) begin errors++;
        if (errors<=60) $display("[%0t] io_tlb_0_resp_bits_s1_af g=%h i=%h", $time, g_io_tlb_0_resp_bits_s1_af, i_io_tlb_0_resp_bits_s1_af); end
      if (!$isunknown(g_io_tlb_0_resp_bits_s2_entry_tag) && g_io_tlb_0_resp_bits_s2_entry_tag !== i_io_tlb_0_resp_bits_s2_entry_tag) begin errors++;
        if (errors<=60) $display("[%0t] io_tlb_0_resp_bits_s2_entry_tag g=%h i=%h", $time, g_io_tlb_0_resp_bits_s2_entry_tag, i_io_tlb_0_resp_bits_s2_entry_tag); end
      if (!$isunknown(g_io_tlb_0_resp_bits_s2_entry_vmid) && g_io_tlb_0_resp_bits_s2_entry_vmid !== i_io_tlb_0_resp_bits_s2_entry_vmid) begin errors++;
        if (errors<=60) $display("[%0t] io_tlb_0_resp_bits_s2_entry_vmid g=%h i=%h", $time, g_io_tlb_0_resp_bits_s2_entry_vmid, i_io_tlb_0_resp_bits_s2_entry_vmid); end
      if (!$isunknown(g_io_tlb_0_resp_bits_s2_entry_n) && g_io_tlb_0_resp_bits_s2_entry_n !== i_io_tlb_0_resp_bits_s2_entry_n) begin errors++;
        if (errors<=60) $display("[%0t] io_tlb_0_resp_bits_s2_entry_n g=%h i=%h", $time, g_io_tlb_0_resp_bits_s2_entry_n, i_io_tlb_0_resp_bits_s2_entry_n); end
      if (!$isunknown(g_io_tlb_0_resp_bits_s2_entry_pbmt) && g_io_tlb_0_resp_bits_s2_entry_pbmt !== i_io_tlb_0_resp_bits_s2_entry_pbmt) begin errors++;
        if (errors<=60) $display("[%0t] io_tlb_0_resp_bits_s2_entry_pbmt g=%h i=%h", $time, g_io_tlb_0_resp_bits_s2_entry_pbmt, i_io_tlb_0_resp_bits_s2_entry_pbmt); end
      if (!$isunknown(g_io_tlb_0_resp_bits_s2_entry_ppn) && g_io_tlb_0_resp_bits_s2_entry_ppn !== i_io_tlb_0_resp_bits_s2_entry_ppn) begin errors++;
        if (errors<=60) $display("[%0t] io_tlb_0_resp_bits_s2_entry_ppn g=%h i=%h", $time, g_io_tlb_0_resp_bits_s2_entry_ppn, i_io_tlb_0_resp_bits_s2_entry_ppn); end
      if (!$isunknown(g_io_tlb_0_resp_bits_s2_entry_perm_d) && g_io_tlb_0_resp_bits_s2_entry_perm_d !== i_io_tlb_0_resp_bits_s2_entry_perm_d) begin errors++;
        if (errors<=60) $display("[%0t] io_tlb_0_resp_bits_s2_entry_perm_d g=%h i=%h", $time, g_io_tlb_0_resp_bits_s2_entry_perm_d, i_io_tlb_0_resp_bits_s2_entry_perm_d); end
      if (!$isunknown(g_io_tlb_0_resp_bits_s2_entry_perm_a) && g_io_tlb_0_resp_bits_s2_entry_perm_a !== i_io_tlb_0_resp_bits_s2_entry_perm_a) begin errors++;
        if (errors<=60) $display("[%0t] io_tlb_0_resp_bits_s2_entry_perm_a g=%h i=%h", $time, g_io_tlb_0_resp_bits_s2_entry_perm_a, i_io_tlb_0_resp_bits_s2_entry_perm_a); end
      if (!$isunknown(g_io_tlb_0_resp_bits_s2_entry_perm_g) && g_io_tlb_0_resp_bits_s2_entry_perm_g !== i_io_tlb_0_resp_bits_s2_entry_perm_g) begin errors++;
        if (errors<=60) $display("[%0t] io_tlb_0_resp_bits_s2_entry_perm_g g=%h i=%h", $time, g_io_tlb_0_resp_bits_s2_entry_perm_g, i_io_tlb_0_resp_bits_s2_entry_perm_g); end
      if (!$isunknown(g_io_tlb_0_resp_bits_s2_entry_perm_u) && g_io_tlb_0_resp_bits_s2_entry_perm_u !== i_io_tlb_0_resp_bits_s2_entry_perm_u) begin errors++;
        if (errors<=60) $display("[%0t] io_tlb_0_resp_bits_s2_entry_perm_u g=%h i=%h", $time, g_io_tlb_0_resp_bits_s2_entry_perm_u, i_io_tlb_0_resp_bits_s2_entry_perm_u); end
      if (!$isunknown(g_io_tlb_0_resp_bits_s2_entry_perm_x) && g_io_tlb_0_resp_bits_s2_entry_perm_x !== i_io_tlb_0_resp_bits_s2_entry_perm_x) begin errors++;
        if (errors<=60) $display("[%0t] io_tlb_0_resp_bits_s2_entry_perm_x g=%h i=%h", $time, g_io_tlb_0_resp_bits_s2_entry_perm_x, i_io_tlb_0_resp_bits_s2_entry_perm_x); end
      if (!$isunknown(g_io_tlb_0_resp_bits_s2_entry_perm_w) && g_io_tlb_0_resp_bits_s2_entry_perm_w !== i_io_tlb_0_resp_bits_s2_entry_perm_w) begin errors++;
        if (errors<=60) $display("[%0t] io_tlb_0_resp_bits_s2_entry_perm_w g=%h i=%h", $time, g_io_tlb_0_resp_bits_s2_entry_perm_w, i_io_tlb_0_resp_bits_s2_entry_perm_w); end
      if (!$isunknown(g_io_tlb_0_resp_bits_s2_entry_perm_r) && g_io_tlb_0_resp_bits_s2_entry_perm_r !== i_io_tlb_0_resp_bits_s2_entry_perm_r) begin errors++;
        if (errors<=60) $display("[%0t] io_tlb_0_resp_bits_s2_entry_perm_r g=%h i=%h", $time, g_io_tlb_0_resp_bits_s2_entry_perm_r, i_io_tlb_0_resp_bits_s2_entry_perm_r); end
      if (!$isunknown(g_io_tlb_0_resp_bits_s2_entry_level) && g_io_tlb_0_resp_bits_s2_entry_level !== i_io_tlb_0_resp_bits_s2_entry_level) begin errors++;
        if (errors<=60) $display("[%0t] io_tlb_0_resp_bits_s2_entry_level g=%h i=%h", $time, g_io_tlb_0_resp_bits_s2_entry_level, i_io_tlb_0_resp_bits_s2_entry_level); end
      if (!$isunknown(g_io_tlb_0_resp_bits_s2_gpf) && g_io_tlb_0_resp_bits_s2_gpf !== i_io_tlb_0_resp_bits_s2_gpf) begin errors++;
        if (errors<=60) $display("[%0t] io_tlb_0_resp_bits_s2_gpf g=%h i=%h", $time, g_io_tlb_0_resp_bits_s2_gpf, i_io_tlb_0_resp_bits_s2_gpf); end
      if (!$isunknown(g_io_tlb_0_resp_bits_s2_gaf) && g_io_tlb_0_resp_bits_s2_gaf !== i_io_tlb_0_resp_bits_s2_gaf) begin errors++;
        if (errors<=60) $display("[%0t] io_tlb_0_resp_bits_s2_gaf g=%h i=%h", $time, g_io_tlb_0_resp_bits_s2_gaf, i_io_tlb_0_resp_bits_s2_gaf); end
      if (!$isunknown(g_io_tlb_1_req_0_ready) && g_io_tlb_1_req_0_ready !== i_io_tlb_1_req_0_ready) begin errors++;
        if (errors<=60) $display("[%0t] io_tlb_1_req_0_ready g=%h i=%h", $time, g_io_tlb_1_req_0_ready, i_io_tlb_1_req_0_ready); end
      if (!$isunknown(g_io_tlb_1_resp_valid) && g_io_tlb_1_resp_valid !== i_io_tlb_1_resp_valid) begin errors++;
        if (errors<=60) $display("[%0t] io_tlb_1_resp_valid g=%h i=%h", $time, g_io_tlb_1_resp_valid, i_io_tlb_1_resp_valid); end
      if (!$isunknown(g_io_tlb_1_resp_bits_s2xlate) && g_io_tlb_1_resp_bits_s2xlate !== i_io_tlb_1_resp_bits_s2xlate) begin errors++;
        if (errors<=60) $display("[%0t] io_tlb_1_resp_bits_s2xlate g=%h i=%h", $time, g_io_tlb_1_resp_bits_s2xlate, i_io_tlb_1_resp_bits_s2xlate); end
      if (!$isunknown(g_io_tlb_1_resp_bits_s1_entry_tag) && g_io_tlb_1_resp_bits_s1_entry_tag !== i_io_tlb_1_resp_bits_s1_entry_tag) begin errors++;
        if (errors<=60) $display("[%0t] io_tlb_1_resp_bits_s1_entry_tag g=%h i=%h", $time, g_io_tlb_1_resp_bits_s1_entry_tag, i_io_tlb_1_resp_bits_s1_entry_tag); end
      if (!$isunknown(g_io_tlb_1_resp_bits_s1_entry_asid) && g_io_tlb_1_resp_bits_s1_entry_asid !== i_io_tlb_1_resp_bits_s1_entry_asid) begin errors++;
        if (errors<=60) $display("[%0t] io_tlb_1_resp_bits_s1_entry_asid g=%h i=%h", $time, g_io_tlb_1_resp_bits_s1_entry_asid, i_io_tlb_1_resp_bits_s1_entry_asid); end
      if (!$isunknown(g_io_tlb_1_resp_bits_s1_entry_vmid) && g_io_tlb_1_resp_bits_s1_entry_vmid !== i_io_tlb_1_resp_bits_s1_entry_vmid) begin errors++;
        if (errors<=60) $display("[%0t] io_tlb_1_resp_bits_s1_entry_vmid g=%h i=%h", $time, g_io_tlb_1_resp_bits_s1_entry_vmid, i_io_tlb_1_resp_bits_s1_entry_vmid); end
      if (!$isunknown(g_io_tlb_1_resp_bits_s1_entry_n) && g_io_tlb_1_resp_bits_s1_entry_n !== i_io_tlb_1_resp_bits_s1_entry_n) begin errors++;
        if (errors<=60) $display("[%0t] io_tlb_1_resp_bits_s1_entry_n g=%h i=%h", $time, g_io_tlb_1_resp_bits_s1_entry_n, i_io_tlb_1_resp_bits_s1_entry_n); end
      if (!$isunknown(g_io_tlb_1_resp_bits_s1_entry_pbmt) && g_io_tlb_1_resp_bits_s1_entry_pbmt !== i_io_tlb_1_resp_bits_s1_entry_pbmt) begin errors++;
        if (errors<=60) $display("[%0t] io_tlb_1_resp_bits_s1_entry_pbmt g=%h i=%h", $time, g_io_tlb_1_resp_bits_s1_entry_pbmt, i_io_tlb_1_resp_bits_s1_entry_pbmt); end
      if (!$isunknown(g_io_tlb_1_resp_bits_s1_entry_perm_d) && g_io_tlb_1_resp_bits_s1_entry_perm_d !== i_io_tlb_1_resp_bits_s1_entry_perm_d) begin errors++;
        if (errors<=60) $display("[%0t] io_tlb_1_resp_bits_s1_entry_perm_d g=%h i=%h", $time, g_io_tlb_1_resp_bits_s1_entry_perm_d, i_io_tlb_1_resp_bits_s1_entry_perm_d); end
      if (!$isunknown(g_io_tlb_1_resp_bits_s1_entry_perm_a) && g_io_tlb_1_resp_bits_s1_entry_perm_a !== i_io_tlb_1_resp_bits_s1_entry_perm_a) begin errors++;
        if (errors<=60) $display("[%0t] io_tlb_1_resp_bits_s1_entry_perm_a g=%h i=%h", $time, g_io_tlb_1_resp_bits_s1_entry_perm_a, i_io_tlb_1_resp_bits_s1_entry_perm_a); end
      if (!$isunknown(g_io_tlb_1_resp_bits_s1_entry_perm_g) && g_io_tlb_1_resp_bits_s1_entry_perm_g !== i_io_tlb_1_resp_bits_s1_entry_perm_g) begin errors++;
        if (errors<=60) $display("[%0t] io_tlb_1_resp_bits_s1_entry_perm_g g=%h i=%h", $time, g_io_tlb_1_resp_bits_s1_entry_perm_g, i_io_tlb_1_resp_bits_s1_entry_perm_g); end
      if (!$isunknown(g_io_tlb_1_resp_bits_s1_entry_perm_u) && g_io_tlb_1_resp_bits_s1_entry_perm_u !== i_io_tlb_1_resp_bits_s1_entry_perm_u) begin errors++;
        if (errors<=60) $display("[%0t] io_tlb_1_resp_bits_s1_entry_perm_u g=%h i=%h", $time, g_io_tlb_1_resp_bits_s1_entry_perm_u, i_io_tlb_1_resp_bits_s1_entry_perm_u); end
      if (!$isunknown(g_io_tlb_1_resp_bits_s1_entry_perm_x) && g_io_tlb_1_resp_bits_s1_entry_perm_x !== i_io_tlb_1_resp_bits_s1_entry_perm_x) begin errors++;
        if (errors<=60) $display("[%0t] io_tlb_1_resp_bits_s1_entry_perm_x g=%h i=%h", $time, g_io_tlb_1_resp_bits_s1_entry_perm_x, i_io_tlb_1_resp_bits_s1_entry_perm_x); end
      if (!$isunknown(g_io_tlb_1_resp_bits_s1_entry_perm_w) && g_io_tlb_1_resp_bits_s1_entry_perm_w !== i_io_tlb_1_resp_bits_s1_entry_perm_w) begin errors++;
        if (errors<=60) $display("[%0t] io_tlb_1_resp_bits_s1_entry_perm_w g=%h i=%h", $time, g_io_tlb_1_resp_bits_s1_entry_perm_w, i_io_tlb_1_resp_bits_s1_entry_perm_w); end
      if (!$isunknown(g_io_tlb_1_resp_bits_s1_entry_perm_r) && g_io_tlb_1_resp_bits_s1_entry_perm_r !== i_io_tlb_1_resp_bits_s1_entry_perm_r) begin errors++;
        if (errors<=60) $display("[%0t] io_tlb_1_resp_bits_s1_entry_perm_r g=%h i=%h", $time, g_io_tlb_1_resp_bits_s1_entry_perm_r, i_io_tlb_1_resp_bits_s1_entry_perm_r); end
      if (!$isunknown(g_io_tlb_1_resp_bits_s1_entry_level) && g_io_tlb_1_resp_bits_s1_entry_level !== i_io_tlb_1_resp_bits_s1_entry_level) begin errors++;
        if (errors<=60) $display("[%0t] io_tlb_1_resp_bits_s1_entry_level g=%h i=%h", $time, g_io_tlb_1_resp_bits_s1_entry_level, i_io_tlb_1_resp_bits_s1_entry_level); end
      if (!$isunknown(g_io_tlb_1_resp_bits_s1_entry_v) && g_io_tlb_1_resp_bits_s1_entry_v !== i_io_tlb_1_resp_bits_s1_entry_v) begin errors++;
        if (errors<=60) $display("[%0t] io_tlb_1_resp_bits_s1_entry_v g=%h i=%h", $time, g_io_tlb_1_resp_bits_s1_entry_v, i_io_tlb_1_resp_bits_s1_entry_v); end
      if (!$isunknown(g_io_tlb_1_resp_bits_s1_entry_ppn) && g_io_tlb_1_resp_bits_s1_entry_ppn !== i_io_tlb_1_resp_bits_s1_entry_ppn) begin errors++;
        if (errors<=60) $display("[%0t] io_tlb_1_resp_bits_s1_entry_ppn g=%h i=%h", $time, g_io_tlb_1_resp_bits_s1_entry_ppn, i_io_tlb_1_resp_bits_s1_entry_ppn); end
      if (!$isunknown(g_io_tlb_1_resp_bits_s1_addr_low) && g_io_tlb_1_resp_bits_s1_addr_low !== i_io_tlb_1_resp_bits_s1_addr_low) begin errors++;
        if (errors<=60) $display("[%0t] io_tlb_1_resp_bits_s1_addr_low g=%h i=%h", $time, g_io_tlb_1_resp_bits_s1_addr_low, i_io_tlb_1_resp_bits_s1_addr_low); end
      if (!$isunknown(g_io_tlb_1_resp_bits_s1_ppn_low_0) && g_io_tlb_1_resp_bits_s1_ppn_low_0 !== i_io_tlb_1_resp_bits_s1_ppn_low_0) begin errors++;
        if (errors<=60) $display("[%0t] io_tlb_1_resp_bits_s1_ppn_low_0 g=%h i=%h", $time, g_io_tlb_1_resp_bits_s1_ppn_low_0, i_io_tlb_1_resp_bits_s1_ppn_low_0); end
      if (!$isunknown(g_io_tlb_1_resp_bits_s1_ppn_low_1) && g_io_tlb_1_resp_bits_s1_ppn_low_1 !== i_io_tlb_1_resp_bits_s1_ppn_low_1) begin errors++;
        if (errors<=60) $display("[%0t] io_tlb_1_resp_bits_s1_ppn_low_1 g=%h i=%h", $time, g_io_tlb_1_resp_bits_s1_ppn_low_1, i_io_tlb_1_resp_bits_s1_ppn_low_1); end
      if (!$isunknown(g_io_tlb_1_resp_bits_s1_ppn_low_2) && g_io_tlb_1_resp_bits_s1_ppn_low_2 !== i_io_tlb_1_resp_bits_s1_ppn_low_2) begin errors++;
        if (errors<=60) $display("[%0t] io_tlb_1_resp_bits_s1_ppn_low_2 g=%h i=%h", $time, g_io_tlb_1_resp_bits_s1_ppn_low_2, i_io_tlb_1_resp_bits_s1_ppn_low_2); end
      if (!$isunknown(g_io_tlb_1_resp_bits_s1_ppn_low_3) && g_io_tlb_1_resp_bits_s1_ppn_low_3 !== i_io_tlb_1_resp_bits_s1_ppn_low_3) begin errors++;
        if (errors<=60) $display("[%0t] io_tlb_1_resp_bits_s1_ppn_low_3 g=%h i=%h", $time, g_io_tlb_1_resp_bits_s1_ppn_low_3, i_io_tlb_1_resp_bits_s1_ppn_low_3); end
      if (!$isunknown(g_io_tlb_1_resp_bits_s1_ppn_low_4) && g_io_tlb_1_resp_bits_s1_ppn_low_4 !== i_io_tlb_1_resp_bits_s1_ppn_low_4) begin errors++;
        if (errors<=60) $display("[%0t] io_tlb_1_resp_bits_s1_ppn_low_4 g=%h i=%h", $time, g_io_tlb_1_resp_bits_s1_ppn_low_4, i_io_tlb_1_resp_bits_s1_ppn_low_4); end
      if (!$isunknown(g_io_tlb_1_resp_bits_s1_ppn_low_5) && g_io_tlb_1_resp_bits_s1_ppn_low_5 !== i_io_tlb_1_resp_bits_s1_ppn_low_5) begin errors++;
        if (errors<=60) $display("[%0t] io_tlb_1_resp_bits_s1_ppn_low_5 g=%h i=%h", $time, g_io_tlb_1_resp_bits_s1_ppn_low_5, i_io_tlb_1_resp_bits_s1_ppn_low_5); end
      if (!$isunknown(g_io_tlb_1_resp_bits_s1_ppn_low_6) && g_io_tlb_1_resp_bits_s1_ppn_low_6 !== i_io_tlb_1_resp_bits_s1_ppn_low_6) begin errors++;
        if (errors<=60) $display("[%0t] io_tlb_1_resp_bits_s1_ppn_low_6 g=%h i=%h", $time, g_io_tlb_1_resp_bits_s1_ppn_low_6, i_io_tlb_1_resp_bits_s1_ppn_low_6); end
      if (!$isunknown(g_io_tlb_1_resp_bits_s1_ppn_low_7) && g_io_tlb_1_resp_bits_s1_ppn_low_7 !== i_io_tlb_1_resp_bits_s1_ppn_low_7) begin errors++;
        if (errors<=60) $display("[%0t] io_tlb_1_resp_bits_s1_ppn_low_7 g=%h i=%h", $time, g_io_tlb_1_resp_bits_s1_ppn_low_7, i_io_tlb_1_resp_bits_s1_ppn_low_7); end
      if (!$isunknown(g_io_tlb_1_resp_bits_s1_valididx_0) && g_io_tlb_1_resp_bits_s1_valididx_0 !== i_io_tlb_1_resp_bits_s1_valididx_0) begin errors++;
        if (errors<=60) $display("[%0t] io_tlb_1_resp_bits_s1_valididx_0 g=%h i=%h", $time, g_io_tlb_1_resp_bits_s1_valididx_0, i_io_tlb_1_resp_bits_s1_valididx_0); end
      if (!$isunknown(g_io_tlb_1_resp_bits_s1_valididx_1) && g_io_tlb_1_resp_bits_s1_valididx_1 !== i_io_tlb_1_resp_bits_s1_valididx_1) begin errors++;
        if (errors<=60) $display("[%0t] io_tlb_1_resp_bits_s1_valididx_1 g=%h i=%h", $time, g_io_tlb_1_resp_bits_s1_valididx_1, i_io_tlb_1_resp_bits_s1_valididx_1); end
      if (!$isunknown(g_io_tlb_1_resp_bits_s1_valididx_2) && g_io_tlb_1_resp_bits_s1_valididx_2 !== i_io_tlb_1_resp_bits_s1_valididx_2) begin errors++;
        if (errors<=60) $display("[%0t] io_tlb_1_resp_bits_s1_valididx_2 g=%h i=%h", $time, g_io_tlb_1_resp_bits_s1_valididx_2, i_io_tlb_1_resp_bits_s1_valididx_2); end
      if (!$isunknown(g_io_tlb_1_resp_bits_s1_valididx_3) && g_io_tlb_1_resp_bits_s1_valididx_3 !== i_io_tlb_1_resp_bits_s1_valididx_3) begin errors++;
        if (errors<=60) $display("[%0t] io_tlb_1_resp_bits_s1_valididx_3 g=%h i=%h", $time, g_io_tlb_1_resp_bits_s1_valididx_3, i_io_tlb_1_resp_bits_s1_valididx_3); end
      if (!$isunknown(g_io_tlb_1_resp_bits_s1_valididx_4) && g_io_tlb_1_resp_bits_s1_valididx_4 !== i_io_tlb_1_resp_bits_s1_valididx_4) begin errors++;
        if (errors<=60) $display("[%0t] io_tlb_1_resp_bits_s1_valididx_4 g=%h i=%h", $time, g_io_tlb_1_resp_bits_s1_valididx_4, i_io_tlb_1_resp_bits_s1_valididx_4); end
      if (!$isunknown(g_io_tlb_1_resp_bits_s1_valididx_5) && g_io_tlb_1_resp_bits_s1_valididx_5 !== i_io_tlb_1_resp_bits_s1_valididx_5) begin errors++;
        if (errors<=60) $display("[%0t] io_tlb_1_resp_bits_s1_valididx_5 g=%h i=%h", $time, g_io_tlb_1_resp_bits_s1_valididx_5, i_io_tlb_1_resp_bits_s1_valididx_5); end
      if (!$isunknown(g_io_tlb_1_resp_bits_s1_valididx_6) && g_io_tlb_1_resp_bits_s1_valididx_6 !== i_io_tlb_1_resp_bits_s1_valididx_6) begin errors++;
        if (errors<=60) $display("[%0t] io_tlb_1_resp_bits_s1_valididx_6 g=%h i=%h", $time, g_io_tlb_1_resp_bits_s1_valididx_6, i_io_tlb_1_resp_bits_s1_valididx_6); end
      if (!$isunknown(g_io_tlb_1_resp_bits_s1_valididx_7) && g_io_tlb_1_resp_bits_s1_valididx_7 !== i_io_tlb_1_resp_bits_s1_valididx_7) begin errors++;
        if (errors<=60) $display("[%0t] io_tlb_1_resp_bits_s1_valididx_7 g=%h i=%h", $time, g_io_tlb_1_resp_bits_s1_valididx_7, i_io_tlb_1_resp_bits_s1_valididx_7); end
      if (!$isunknown(g_io_tlb_1_resp_bits_s1_pteidx_0) && g_io_tlb_1_resp_bits_s1_pteidx_0 !== i_io_tlb_1_resp_bits_s1_pteidx_0) begin errors++;
        if (errors<=60) $display("[%0t] io_tlb_1_resp_bits_s1_pteidx_0 g=%h i=%h", $time, g_io_tlb_1_resp_bits_s1_pteidx_0, i_io_tlb_1_resp_bits_s1_pteidx_0); end
      if (!$isunknown(g_io_tlb_1_resp_bits_s1_pteidx_1) && g_io_tlb_1_resp_bits_s1_pteidx_1 !== i_io_tlb_1_resp_bits_s1_pteidx_1) begin errors++;
        if (errors<=60) $display("[%0t] io_tlb_1_resp_bits_s1_pteidx_1 g=%h i=%h", $time, g_io_tlb_1_resp_bits_s1_pteidx_1, i_io_tlb_1_resp_bits_s1_pteidx_1); end
      if (!$isunknown(g_io_tlb_1_resp_bits_s1_pteidx_2) && g_io_tlb_1_resp_bits_s1_pteidx_2 !== i_io_tlb_1_resp_bits_s1_pteidx_2) begin errors++;
        if (errors<=60) $display("[%0t] io_tlb_1_resp_bits_s1_pteidx_2 g=%h i=%h", $time, g_io_tlb_1_resp_bits_s1_pteidx_2, i_io_tlb_1_resp_bits_s1_pteidx_2); end
      if (!$isunknown(g_io_tlb_1_resp_bits_s1_pteidx_3) && g_io_tlb_1_resp_bits_s1_pteidx_3 !== i_io_tlb_1_resp_bits_s1_pteidx_3) begin errors++;
        if (errors<=60) $display("[%0t] io_tlb_1_resp_bits_s1_pteidx_3 g=%h i=%h", $time, g_io_tlb_1_resp_bits_s1_pteidx_3, i_io_tlb_1_resp_bits_s1_pteidx_3); end
      if (!$isunknown(g_io_tlb_1_resp_bits_s1_pteidx_4) && g_io_tlb_1_resp_bits_s1_pteidx_4 !== i_io_tlb_1_resp_bits_s1_pteidx_4) begin errors++;
        if (errors<=60) $display("[%0t] io_tlb_1_resp_bits_s1_pteidx_4 g=%h i=%h", $time, g_io_tlb_1_resp_bits_s1_pteidx_4, i_io_tlb_1_resp_bits_s1_pteidx_4); end
      if (!$isunknown(g_io_tlb_1_resp_bits_s1_pteidx_5) && g_io_tlb_1_resp_bits_s1_pteidx_5 !== i_io_tlb_1_resp_bits_s1_pteidx_5) begin errors++;
        if (errors<=60) $display("[%0t] io_tlb_1_resp_bits_s1_pteidx_5 g=%h i=%h", $time, g_io_tlb_1_resp_bits_s1_pteidx_5, i_io_tlb_1_resp_bits_s1_pteidx_5); end
      if (!$isunknown(g_io_tlb_1_resp_bits_s1_pteidx_6) && g_io_tlb_1_resp_bits_s1_pteidx_6 !== i_io_tlb_1_resp_bits_s1_pteidx_6) begin errors++;
        if (errors<=60) $display("[%0t] io_tlb_1_resp_bits_s1_pteidx_6 g=%h i=%h", $time, g_io_tlb_1_resp_bits_s1_pteidx_6, i_io_tlb_1_resp_bits_s1_pteidx_6); end
      if (!$isunknown(g_io_tlb_1_resp_bits_s1_pteidx_7) && g_io_tlb_1_resp_bits_s1_pteidx_7 !== i_io_tlb_1_resp_bits_s1_pteidx_7) begin errors++;
        if (errors<=60) $display("[%0t] io_tlb_1_resp_bits_s1_pteidx_7 g=%h i=%h", $time, g_io_tlb_1_resp_bits_s1_pteidx_7, i_io_tlb_1_resp_bits_s1_pteidx_7); end
      if (!$isunknown(g_io_tlb_1_resp_bits_s1_pf) && g_io_tlb_1_resp_bits_s1_pf !== i_io_tlb_1_resp_bits_s1_pf) begin errors++;
        if (errors<=60) $display("[%0t] io_tlb_1_resp_bits_s1_pf g=%h i=%h", $time, g_io_tlb_1_resp_bits_s1_pf, i_io_tlb_1_resp_bits_s1_pf); end
      if (!$isunknown(g_io_tlb_1_resp_bits_s1_af) && g_io_tlb_1_resp_bits_s1_af !== i_io_tlb_1_resp_bits_s1_af) begin errors++;
        if (errors<=60) $display("[%0t] io_tlb_1_resp_bits_s1_af g=%h i=%h", $time, g_io_tlb_1_resp_bits_s1_af, i_io_tlb_1_resp_bits_s1_af); end
      if (!$isunknown(g_io_tlb_1_resp_bits_s2_entry_tag) && g_io_tlb_1_resp_bits_s2_entry_tag !== i_io_tlb_1_resp_bits_s2_entry_tag) begin errors++;
        if (errors<=60) $display("[%0t] io_tlb_1_resp_bits_s2_entry_tag g=%h i=%h", $time, g_io_tlb_1_resp_bits_s2_entry_tag, i_io_tlb_1_resp_bits_s2_entry_tag); end
      if (!$isunknown(g_io_tlb_1_resp_bits_s2_entry_vmid) && g_io_tlb_1_resp_bits_s2_entry_vmid !== i_io_tlb_1_resp_bits_s2_entry_vmid) begin errors++;
        if (errors<=60) $display("[%0t] io_tlb_1_resp_bits_s2_entry_vmid g=%h i=%h", $time, g_io_tlb_1_resp_bits_s2_entry_vmid, i_io_tlb_1_resp_bits_s2_entry_vmid); end
      if (!$isunknown(g_io_tlb_1_resp_bits_s2_entry_n) && g_io_tlb_1_resp_bits_s2_entry_n !== i_io_tlb_1_resp_bits_s2_entry_n) begin errors++;
        if (errors<=60) $display("[%0t] io_tlb_1_resp_bits_s2_entry_n g=%h i=%h", $time, g_io_tlb_1_resp_bits_s2_entry_n, i_io_tlb_1_resp_bits_s2_entry_n); end
      if (!$isunknown(g_io_tlb_1_resp_bits_s2_entry_pbmt) && g_io_tlb_1_resp_bits_s2_entry_pbmt !== i_io_tlb_1_resp_bits_s2_entry_pbmt) begin errors++;
        if (errors<=60) $display("[%0t] io_tlb_1_resp_bits_s2_entry_pbmt g=%h i=%h", $time, g_io_tlb_1_resp_bits_s2_entry_pbmt, i_io_tlb_1_resp_bits_s2_entry_pbmt); end
      if (!$isunknown(g_io_tlb_1_resp_bits_s2_entry_ppn) && g_io_tlb_1_resp_bits_s2_entry_ppn !== i_io_tlb_1_resp_bits_s2_entry_ppn) begin errors++;
        if (errors<=60) $display("[%0t] io_tlb_1_resp_bits_s2_entry_ppn g=%h i=%h", $time, g_io_tlb_1_resp_bits_s2_entry_ppn, i_io_tlb_1_resp_bits_s2_entry_ppn); end
      if (!$isunknown(g_io_tlb_1_resp_bits_s2_entry_perm_d) && g_io_tlb_1_resp_bits_s2_entry_perm_d !== i_io_tlb_1_resp_bits_s2_entry_perm_d) begin errors++;
        if (errors<=60) $display("[%0t] io_tlb_1_resp_bits_s2_entry_perm_d g=%h i=%h", $time, g_io_tlb_1_resp_bits_s2_entry_perm_d, i_io_tlb_1_resp_bits_s2_entry_perm_d); end
      if (!$isunknown(g_io_tlb_1_resp_bits_s2_entry_perm_a) && g_io_tlb_1_resp_bits_s2_entry_perm_a !== i_io_tlb_1_resp_bits_s2_entry_perm_a) begin errors++;
        if (errors<=60) $display("[%0t] io_tlb_1_resp_bits_s2_entry_perm_a g=%h i=%h", $time, g_io_tlb_1_resp_bits_s2_entry_perm_a, i_io_tlb_1_resp_bits_s2_entry_perm_a); end
      if (!$isunknown(g_io_tlb_1_resp_bits_s2_entry_perm_g) && g_io_tlb_1_resp_bits_s2_entry_perm_g !== i_io_tlb_1_resp_bits_s2_entry_perm_g) begin errors++;
        if (errors<=60) $display("[%0t] io_tlb_1_resp_bits_s2_entry_perm_g g=%h i=%h", $time, g_io_tlb_1_resp_bits_s2_entry_perm_g, i_io_tlb_1_resp_bits_s2_entry_perm_g); end
      if (!$isunknown(g_io_tlb_1_resp_bits_s2_entry_perm_u) && g_io_tlb_1_resp_bits_s2_entry_perm_u !== i_io_tlb_1_resp_bits_s2_entry_perm_u) begin errors++;
        if (errors<=60) $display("[%0t] io_tlb_1_resp_bits_s2_entry_perm_u g=%h i=%h", $time, g_io_tlb_1_resp_bits_s2_entry_perm_u, i_io_tlb_1_resp_bits_s2_entry_perm_u); end
      if (!$isunknown(g_io_tlb_1_resp_bits_s2_entry_perm_x) && g_io_tlb_1_resp_bits_s2_entry_perm_x !== i_io_tlb_1_resp_bits_s2_entry_perm_x) begin errors++;
        if (errors<=60) $display("[%0t] io_tlb_1_resp_bits_s2_entry_perm_x g=%h i=%h", $time, g_io_tlb_1_resp_bits_s2_entry_perm_x, i_io_tlb_1_resp_bits_s2_entry_perm_x); end
      if (!$isunknown(g_io_tlb_1_resp_bits_s2_entry_perm_w) && g_io_tlb_1_resp_bits_s2_entry_perm_w !== i_io_tlb_1_resp_bits_s2_entry_perm_w) begin errors++;
        if (errors<=60) $display("[%0t] io_tlb_1_resp_bits_s2_entry_perm_w g=%h i=%h", $time, g_io_tlb_1_resp_bits_s2_entry_perm_w, i_io_tlb_1_resp_bits_s2_entry_perm_w); end
      if (!$isunknown(g_io_tlb_1_resp_bits_s2_entry_perm_r) && g_io_tlb_1_resp_bits_s2_entry_perm_r !== i_io_tlb_1_resp_bits_s2_entry_perm_r) begin errors++;
        if (errors<=60) $display("[%0t] io_tlb_1_resp_bits_s2_entry_perm_r g=%h i=%h", $time, g_io_tlb_1_resp_bits_s2_entry_perm_r, i_io_tlb_1_resp_bits_s2_entry_perm_r); end
      if (!$isunknown(g_io_tlb_1_resp_bits_s2_entry_level) && g_io_tlb_1_resp_bits_s2_entry_level !== i_io_tlb_1_resp_bits_s2_entry_level) begin errors++;
        if (errors<=60) $display("[%0t] io_tlb_1_resp_bits_s2_entry_level g=%h i=%h", $time, g_io_tlb_1_resp_bits_s2_entry_level, i_io_tlb_1_resp_bits_s2_entry_level); end
      if (!$isunknown(g_io_tlb_1_resp_bits_s2_gpf) && g_io_tlb_1_resp_bits_s2_gpf !== i_io_tlb_1_resp_bits_s2_gpf) begin errors++;
        if (errors<=60) $display("[%0t] io_tlb_1_resp_bits_s2_gpf g=%h i=%h", $time, g_io_tlb_1_resp_bits_s2_gpf, i_io_tlb_1_resp_bits_s2_gpf); end
      if (!$isunknown(g_io_tlb_1_resp_bits_s2_gaf) && g_io_tlb_1_resp_bits_s2_gaf !== i_io_tlb_1_resp_bits_s2_gaf) begin errors++;
        if (errors<=60) $display("[%0t] io_tlb_1_resp_bits_s2_gaf g=%h i=%h", $time, g_io_tlb_1_resp_bits_s2_gaf, i_io_tlb_1_resp_bits_s2_gaf); end
      if (!$isunknown(g_io_wfi_wfiSafe) && g_io_wfi_wfiSafe !== i_io_wfi_wfiSafe) begin errors++;
        if (errors<=60) $display("[%0t] io_wfi_wfiSafe g=%h i=%h", $time, g_io_wfi_wfiSafe, i_io_wfi_wfiSafe); end
      if (!$isunknown(g_io_perf_0_value) && g_io_perf_0_value !== i_io_perf_0_value) begin errors++;
        if (errors<=60) $display("[%0t] io_perf_0_value g=%h i=%h", $time, g_io_perf_0_value, i_io_perf_0_value); end
      if (!$isunknown(g_io_perf_1_value) && g_io_perf_1_value !== i_io_perf_1_value) begin errors++;
        if (errors<=60) $display("[%0t] io_perf_1_value g=%h i=%h", $time, g_io_perf_1_value, i_io_perf_1_value); end
      if (!$isunknown(g_io_perf_2_value) && g_io_perf_2_value !== i_io_perf_2_value) begin errors++;
        if (errors<=60) $display("[%0t] io_perf_2_value g=%h i=%h", $time, g_io_perf_2_value, i_io_perf_2_value); end
      if (!$isunknown(g_io_perf_3_value) && g_io_perf_3_value !== i_io_perf_3_value) begin errors++;
        if (errors<=60) $display("[%0t] io_perf_3_value g=%h i=%h", $time, g_io_perf_3_value, i_io_perf_3_value); end
      if (!$isunknown(g_io_perf_4_value) && g_io_perf_4_value !== i_io_perf_4_value) begin errors++;
        if (errors<=60) $display("[%0t] io_perf_4_value g=%h i=%h", $time, g_io_perf_4_value, i_io_perf_4_value); end
      if (!$isunknown(g_io_perf_5_value) && g_io_perf_5_value !== i_io_perf_5_value) begin errors++;
        if (errors<=60) $display("[%0t] io_perf_5_value g=%h i=%h", $time, g_io_perf_5_value, i_io_perf_5_value); end
      if (!$isunknown(g_io_perf_6_value) && g_io_perf_6_value !== i_io_perf_6_value) begin errors++;
        if (errors<=60) $display("[%0t] io_perf_6_value g=%h i=%h", $time, g_io_perf_6_value, i_io_perf_6_value); end
      if (!$isunknown(g_io_perf_7_value) && g_io_perf_7_value !== i_io_perf_7_value) begin errors++;
        if (errors<=60) $display("[%0t] io_perf_7_value g=%h i=%h", $time, g_io_perf_7_value, i_io_perf_7_value); end
      if (!$isunknown(g_io_perf_8_value) && g_io_perf_8_value !== i_io_perf_8_value) begin errors++;
        if (errors<=60) $display("[%0t] io_perf_8_value g=%h i=%h", $time, g_io_perf_8_value, i_io_perf_8_value); end
      if (!$isunknown(g_io_perf_9_value) && g_io_perf_9_value !== i_io_perf_9_value) begin errors++;
        if (errors<=60) $display("[%0t] io_perf_9_value g=%h i=%h", $time, g_io_perf_9_value, i_io_perf_9_value); end
      if (!$isunknown(g_io_perf_10_value) && g_io_perf_10_value !== i_io_perf_10_value) begin errors++;
        if (errors<=60) $display("[%0t] io_perf_10_value g=%h i=%h", $time, g_io_perf_10_value, i_io_perf_10_value); end
      if (!$isunknown(g_io_perf_11_value) && g_io_perf_11_value !== i_io_perf_11_value) begin errors++;
        if (errors<=60) $display("[%0t] io_perf_11_value g=%h i=%h", $time, g_io_perf_11_value, i_io_perf_11_value); end
      if (!$isunknown(g_io_perf_12_value) && g_io_perf_12_value !== i_io_perf_12_value) begin errors++;
        if (errors<=60) $display("[%0t] io_perf_12_value g=%h i=%h", $time, g_io_perf_12_value, i_io_perf_12_value); end
      if (!$isunknown(g_io_perf_13_value) && g_io_perf_13_value !== i_io_perf_13_value) begin errors++;
        if (errors<=60) $display("[%0t] io_perf_13_value g=%h i=%h", $time, g_io_perf_13_value, i_io_perf_13_value); end
      if (!$isunknown(g_io_perf_14_value) && g_io_perf_14_value !== i_io_perf_14_value) begin errors++;
        if (errors<=60) $display("[%0t] io_perf_14_value g=%h i=%h", $time, g_io_perf_14_value, i_io_perf_14_value); end
      if (!$isunknown(g_io_perf_15_value) && g_io_perf_15_value !== i_io_perf_15_value) begin errors++;
        if (errors<=60) $display("[%0t] io_perf_15_value g=%h i=%h", $time, g_io_perf_15_value, i_io_perf_15_value); end
      if (!$isunknown(g_io_perf_16_value) && g_io_perf_16_value !== i_io_perf_16_value) begin errors++;
        if (errors<=60) $display("[%0t] io_perf_16_value g=%h i=%h", $time, g_io_perf_16_value, i_io_perf_16_value); end
      if (!$isunknown(g_io_perf_17_value) && g_io_perf_17_value !== i_io_perf_17_value) begin errors++;
        if (errors<=60) $display("[%0t] io_perf_17_value g=%h i=%h", $time, g_io_perf_17_value, i_io_perf_17_value); end
      if (!$isunknown(g_io_perf_18_value) && g_io_perf_18_value !== i_io_perf_18_value) begin errors++;
        if (errors<=60) $display("[%0t] io_perf_18_value g=%h i=%h", $time, g_io_perf_18_value, i_io_perf_18_value); end
      if (!$isunknown(g_boreChildrenBd_bore_ack) && g_boreChildrenBd_bore_ack !== i_boreChildrenBd_bore_ack) begin nonfunc_errors++;
        if (nonfunc_errors<=8) $display("[%0t] (nonfunc) boreChildrenBd_bore_ack g=%h i=%h", $time, g_boreChildrenBd_bore_ack, i_boreChildrenBd_bore_ack); end
      if (!$isunknown(g_boreChildrenBd_bore_outdata) && g_boreChildrenBd_bore_outdata !== i_boreChildrenBd_bore_outdata) begin nonfunc_errors++;
        if (nonfunc_errors<=8) $display("[%0t] (nonfunc) boreChildrenBd_bore_outdata g=%h i=%h", $time, g_boreChildrenBd_bore_outdata, i_boreChildrenBd_bore_outdata); end
      if (!$isunknown(g_boreChildrenBd_bore_1_ack) && g_boreChildrenBd_bore_1_ack !== i_boreChildrenBd_bore_1_ack) begin nonfunc_errors++;
        if (nonfunc_errors<=8) $display("[%0t] (nonfunc) boreChildrenBd_bore_1_ack g=%h i=%h", $time, g_boreChildrenBd_bore_1_ack, i_boreChildrenBd_bore_1_ack); end
      if (!$isunknown(g_boreChildrenBd_bore_1_outdata) && g_boreChildrenBd_bore_1_outdata !== i_boreChildrenBd_bore_1_outdata) begin nonfunc_errors++;
        if (nonfunc_errors<=8) $display("[%0t] (nonfunc) boreChildrenBd_bore_1_outdata g=%h i=%h", $time, g_boreChildrenBd_bore_1_outdata, i_boreChildrenBd_bore_1_outdata); end
    end
  end

  // ---- 协议感知握手：TileLink mem A/D 通道、TLB req 保持、satp 模式偏置 ----
  // mem 响应模型：A 请求被接受后入队 source，随机延迟后回 D（两侧 A 完全相同，模型一致）
  bit [2:0] mem_q [$];
  bit       d_pending;
  bit [2:0] d_source;
  int       d_delay;
  bit       csr_busy;   // initial 编程 PMP/PMA 期间置 1，主循环让出 csr_distribute 总线

  // 主激励：posedge 驱动下一拍输入；非阻塞，保证两侧采到同一激励
  always @(posedge clk) begin
    if (rst) begin
      zero_dft();
      auto_out_a_ready <= '0;
      auto_out_d_valid <= '0;
      auto_out_d_bits_opcode <= '0;
      auto_out_d_bits_size <= '0;
      auto_out_d_bits_source <= '0;
      auto_out_d_bits_data <= '0;
      io_tlb_0_req_0_valid <= '0;
      io_tlb_0_req_0_bits_vpn <= '0;
      io_tlb_0_req_0_bits_s2xlate <= '0;
      io_tlb_0_resp_ready <= '0;
      io_tlb_1_req_0_valid <= '0;
      io_tlb_1_req_0_bits_vpn <= '0;
      io_tlb_1_req_0_bits_s2xlate <= '0;
      io_sfence_valid <= '0;
      io_sfence_bits_rs1 <= '0;
      io_sfence_bits_rs2 <= '0;
      io_sfence_bits_addr <= '0;
      io_sfence_bits_id <= '0;
      io_sfence_bits_hv <= '0;
      io_sfence_bits_hg <= '0;
      io_wfi_wfiReq <= '0;
      io_csr_tlb_satp_mode <= '0;
      io_csr_tlb_satp_asid <= '0;
      io_csr_tlb_satp_ppn <= '0;
      io_csr_tlb_satp_changed <= '0;
      io_csr_tlb_vsatp_mode <= '0;
      io_csr_tlb_vsatp_asid <= '0;
      io_csr_tlb_vsatp_ppn <= '0;
      io_csr_tlb_vsatp_changed <= '0;
      io_csr_tlb_hgatp_mode <= '0;
      io_csr_tlb_hgatp_vmid <= '0;
      io_csr_tlb_hgatp_ppn <= '0;
      io_csr_tlb_hgatp_changed <= '0;
      io_csr_tlb_priv_mxr <= '0;
      io_csr_tlb_priv_virt <= '0;
      io_csr_tlb_mPBMTE <= '0;
      io_csr_tlb_hPBMTE <= '0;
      io_csr_distribute_csr_w_valid <= '0;
      io_csr_distribute_csr_w_bits_addr <= '0;
      io_csr_distribute_csr_w_bits_data <= '0;
      cyc <= 0;
      mem_q.delete(); d_pending <= 0; d_delay <= 0;
      // CSR 复位初值：satp/vsatp = Sv39 有效，使 PTW 自起步即活跃
      io_csr_tlb_satp_mode <= 4'd8; io_csr_tlb_vsatp_mode <= 4'd8; io_csr_tlb_hgatp_mode <= 4'd8;
    end else begin
      drive_inputs();
      zero_dft();
      cyc <= cyc + 1;

      // --- TLB req：保持 valid 直到被 ready 接受，接受后换新 vpn ---
      if (io_tlb_0_req_0_valid && g_io_tlb_0_req_0_ready) begin
        io_tlb_0_req_0_bits_vpn <= $random; io_tlb_0_req_0_bits_s2xlate <= $random;
        io_tlb_0_req_0_valid <= ($urandom_range(0,3) != 0);
      end else if (!io_tlb_0_req_0_valid) begin
        io_tlb_0_req_0_valid <= ($urandom_range(0,3) != 0);
        io_tlb_0_req_0_bits_vpn <= $random; io_tlb_0_req_0_bits_s2xlate <= $random;
      end
      if (io_tlb_1_req_0_valid && g_io_tlb_1_req_0_ready) begin
        io_tlb_1_req_0_bits_vpn <= $random; io_tlb_1_req_0_bits_s2xlate <= $random;
        io_tlb_1_req_0_valid <= ($urandom_range(0,3) != 0);
      end else if (!io_tlb_1_req_0_valid) begin
        io_tlb_1_req_0_valid <= ($urandom_range(0,3) != 0);
        io_tlb_1_req_0_bits_vpn <= $random; io_tlb_1_req_0_bits_s2xlate <= $random;
      end
      io_tlb_0_resp_ready <= ($urandom_range(0,3) != 0);

      // --- CSR satp/vsatp/hgatp：值整组保持稳定；约每 ~512 拍偶发 changed 脉冲刷新一次 ---
      io_csr_tlb_satp_changed  <= 1'b0;
      io_csr_tlb_vsatp_changed <= 1'b0;
      io_csr_tlb_hgatp_changed <= 1'b0;
      io_sfence_valid          <= 1'b0;
      // mode 固定有效(Sv39=8 / hgatp Sv39x4=8)，仅刷新 asid/ppn —— 保证 PTW 持续活跃
      if ($urandom_range(0,511) == 0) begin
        io_csr_tlb_satp_mode <= 4'd8;
        io_csr_tlb_satp_asid <= $random; io_csr_tlb_satp_ppn <= {$random,$random};
        io_csr_tlb_satp_changed <= 1'b1;
      end
      if ($urandom_range(0,511) == 0) begin
        io_csr_tlb_vsatp_mode <= 4'd8;
        io_csr_tlb_vsatp_asid <= $random; io_csr_tlb_vsatp_ppn <= {$random,$random};
        io_csr_tlb_vsatp_changed <= 1'b1;
      end
      if ($urandom_range(0,511) == 0) begin
        io_csr_tlb_hgatp_mode <= 4'd8;
        io_csr_tlb_hgatp_vmid <= $random; io_csr_tlb_hgatp_ppn <= {$random,$random};
        io_csr_tlb_hgatp_changed <= 1'b1;
      end
      // sfence 偶发（~每 256 拍），制造 flush 边界（IT 要覆盖的传播路径）
      if ($urandom_range(0,255) == 0) io_sfence_valid <= 1'b1;

      // csr_distribute：编程期由 initial 独占；否则默认拉低（保持 PMP/PMA 配置稳定）
      if (!csr_busy) io_csr_distribute_csr_w_valid <= 1'b0;

      // --- TileLink mem：A 通道几乎总 ready；接受的请求入队等待回 D ---
      auto_out_a_ready <= ($urandom_range(0,7) != 0);
      if (g_auto_out_a_valid && auto_out_a_ready)
        mem_q.push_back(g_auto_out_a_bits_source);
      // D 通道：有挂起则倒计时后拉高一拍，source 取自队首
      if (!d_pending && (mem_q.size() > 0) && ($urandom_range(0,2) != 0)) begin
        d_pending <= 1; d_source <= mem_q.pop_front(); d_delay <= $urandom_range(0,3);
      end
      if (d_pending) begin
        if (d_delay > 0) begin d_delay <= d_delay - 1; auto_out_d_valid <= 0; end
        else begin
          auto_out_d_valid <= 1;
          auto_out_d_bits_source <= d_source;
          auto_out_d_bits_opcode <= 4'd1;   // AccessAckData
          auto_out_d_bits_size   <= 3'd5;   // 32B beat
          // 数据=8 个 64b PTE：偶发构造"有效非叶"PTE(V=1,RWX=0,带 ppn)促使页表继续向下走，
          // 触发 PTW 发出后续 mem 请求；否则随机(多为无效->页错误，走 resp 路径)。
          if ($urandom_range(0,1)) begin
            auto_out_d_bits_data <= { {2{$random}} & 64'h003F_FFFF_FFFF_FC00 | 64'h1,
                                      {2{$random}} & 64'h003F_FFFF_FFFF_FC00 | 64'h1,
                                      {2{$random}} & 64'h003F_FFFF_FFFF_FC00 | 64'h1,
                                      {2{$random}} & 64'h003F_FFFF_FFFF_FC00 | 64'h1 };
          end else begin
            auto_out_d_bits_data <= {$random,$random,$random,$random,$random,$random,$random,$random};
          end
          d_pending <= 0;
        end
      end else begin
        auto_out_d_valid <= 0;
      end
    end
  end

  // 复位后一次性编程 PMP/PMA：覆盖全地址空间、可缓存 RWX，使页表走查地址被判为正常内存
  // （否则随机 satp.ppn 落在默认 MMIO 区，PTW 走 accessFault 路径、不发 DRAM 请求）。
  task automatic prog_csr(input [11:0] a, input [63:0] dval);
    @(negedge clk);
    io_csr_distribute_csr_w_valid     = 1'b1;
    io_csr_distribute_csr_w_bits_addr = a;
    io_csr_distribute_csr_w_bits_data = dval;
    @(negedge clk);
    io_csr_distribute_csr_w_valid     = 1'b0;
  endtask

  initial begin
    void'($value$plusargs("NCYCLES=%d", NCYCLES));
    rst = 1; repeat (16) @(posedge clk); rst = 0;
    csr_busy = 1'b1;
    // pmaaddr0 = 全 1 NAPOT(覆盖全空间)；pmacfg0 byte = NAPOT(A=3)+cacheable+RWX
    prog_csr(12'h7C8, 64'hFFFF_FFFF_FFFF_FFFF);
    prog_csr(12'h7C0, 64'h0000_0000_0000_007F);
    // pmpaddr0 = 全 1 NAPOT；pmpcfg0 byte = NAPOT+RWX
    prog_csr(12'h3B0, 64'hFFFF_FFFF_FFFF_FFFF);
    prog_csr(12'h3A0, 64'h0000_0000_0000_001F);
    csr_busy = 1'b0;
    repeat (NCYCLES) @(posedge clk);
    $display("checks=%0d errors=%0d nonfunc_errors=%0d", checks, errors, nonfunc_errors);
    $display("activity: mem_req=%0d tlb0_resp=%0d tlb1_resp=%0d", act_mem_req, act_tlb0_resp, act_tlb1_resp);
    if (errors == 0 && checks > 1000) $display("TEST PASSED"); else $display("TEST FAILED");
    $finish;
  end
endmodule
