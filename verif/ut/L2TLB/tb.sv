// 自动生成：verif/ut/L2TLB/gen_tb.py —— 勿手改（改生成器后重跑）
// L2TLB（共享 MMU 顶层）双例化逐拍比对：golden L2TLB vs 重写 L2TLB_xs。
// 端口 376（入 224 / 出 152）；其中 DFT/MBIST 输入 176 根钉 0，功能输入 40 根随机，TileLink 应答 6 根由模型驱动。
`timescale 1ns/1ps
module tb;
  int unsigned NVEC = 200000;
  localparam int WARMUP = 64;   // 暖机拍数（不比较），见 initial 块里的说明
  int errors = 0, checks = 0;
  int unsigned n_a_fire = 0, n_d_fire = 0, n_resp_fire = 0, n_req_fire = 0;
  int unsigned n_a_llptw = 0, n_a_ptw = 0, n_a_hptw = 0, n_a_bitmap = 0;
  logic clock = 0, reset;
  always #5 clock = ~clock;

  logic auto_out_a_ready;
  logic auto_out_d_valid;
  logic [3:0] auto_out_d_bits_opcode;
  logic [2:0] auto_out_d_bits_size;
  logic [3:0] auto_out_d_bits_source;
  logic [255:0] auto_out_d_bits_data;
  logic [5:0] io_hartId;
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
  logic io_csr_tlb_mbmc_BME;
  logic io_csr_tlb_mbmc_CMODE;
  logic io_csr_tlb_mbmc_BCLEAR;
  logic [57:0] io_csr_tlb_mbmc_BMA;
  logic io_csr_tlb_priv_virt;
  logic io_csr_tlb_priv_virt_changed;
  logic io_csr_tlb_priv_debug;
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
  logic [5:0] boreChildrenBd_bore_addr;
  logic [89:0] boreChildrenBd_bore_indata;
  logic boreChildrenBd_bore_readen;
  logic [5:0] boreChildrenBd_bore_addr_rd;
  logic [5:0] boreChildrenBd_bore_1_array;
  logic boreChildrenBd_bore_1_all;
  logic boreChildrenBd_bore_1_req;
  logic boreChildrenBd_bore_1_writeen;
  logic boreChildrenBd_bore_1_be;
  logic [2:0] boreChildrenBd_bore_1_addr;
  logic [130:0] boreChildrenBd_bore_1_indata;
  logic boreChildrenBd_bore_1_readen;
  logic [2:0] boreChildrenBd_bore_1_addr_rd;
  logic [6:0] boreChildrenBd_bore_2_array;
  logic boreChildrenBd_bore_2_all;
  logic boreChildrenBd_bore_2_req;
  logic boreChildrenBd_bore_2_writeen;
  logic [1:0] boreChildrenBd_bore_2_be;
  logic [6:0] boreChildrenBd_bore_2_addr;
  logic [113:0] boreChildrenBd_bore_2_indata;
  logic boreChildrenBd_bore_2_readen;
  logic [6:0] boreChildrenBd_bore_2_addr_rd;
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
  logic sigFromSrams_bore_12_ram_hold;
  logic sigFromSrams_bore_12_ram_bypass;
  logic sigFromSrams_bore_12_ram_bp_clken;
  logic sigFromSrams_bore_12_ram_aux_clk;
  logic sigFromSrams_bore_12_ram_aux_ckbp;
  logic sigFromSrams_bore_12_ram_mcp_hold;
  logic sigFromSrams_bore_12_cgen;
  logic sigFromSrams_bore_13_ram_hold;
  logic sigFromSrams_bore_13_ram_bypass;
  logic sigFromSrams_bore_13_ram_bp_clken;
  logic sigFromSrams_bore_13_ram_aux_clk;
  logic sigFromSrams_bore_13_ram_aux_ckbp;
  logic sigFromSrams_bore_13_ram_mcp_hold;
  logic sigFromSrams_bore_13_cgen;
  logic sigFromSrams_bore_14_ram_hold;
  logic sigFromSrams_bore_14_ram_bypass;
  logic sigFromSrams_bore_14_ram_bp_clken;
  logic sigFromSrams_bore_14_ram_aux_clk;
  logic sigFromSrams_bore_14_ram_aux_ckbp;
  logic sigFromSrams_bore_14_ram_mcp_hold;
  logic sigFromSrams_bore_14_cgen;
  logic sigFromSrams_bore_15_ram_hold;
  logic sigFromSrams_bore_15_ram_bypass;
  logic sigFromSrams_bore_15_ram_bp_clken;
  logic sigFromSrams_bore_15_ram_aux_clk;
  logic sigFromSrams_bore_15_ram_aux_ckbp;
  logic sigFromSrams_bore_15_ram_mcp_hold;
  logic sigFromSrams_bore_15_cgen;
  logic sigFromSrams_bore_16_ram_hold;
  logic sigFromSrams_bore_16_ram_bypass;
  logic sigFromSrams_bore_16_ram_bp_clken;
  logic sigFromSrams_bore_16_ram_aux_clk;
  logic sigFromSrams_bore_16_ram_aux_ckbp;
  logic sigFromSrams_bore_16_ram_mcp_hold;
  logic sigFromSrams_bore_16_cgen;
  logic sigFromSrams_bore_17_ram_hold;
  logic sigFromSrams_bore_17_ram_bypass;
  logic sigFromSrams_bore_17_ram_bp_clken;
  logic sigFromSrams_bore_17_ram_aux_clk;
  logic sigFromSrams_bore_17_ram_aux_ckbp;
  logic sigFromSrams_bore_17_ram_mcp_hold;
  logic sigFromSrams_bore_17_cgen;
  logic sigFromSrams_bore_18_ram_hold;
  logic sigFromSrams_bore_18_ram_bypass;
  logic sigFromSrams_bore_18_ram_bp_clken;
  logic sigFromSrams_bore_18_ram_aux_clk;
  logic sigFromSrams_bore_18_ram_aux_ckbp;
  logic sigFromSrams_bore_18_ram_mcp_hold;
  logic sigFromSrams_bore_18_cgen;
  logic sigFromSrams_bore_19_ram_hold;
  logic sigFromSrams_bore_19_ram_bypass;
  logic sigFromSrams_bore_19_ram_bp_clken;
  logic sigFromSrams_bore_19_ram_aux_clk;
  logic sigFromSrams_bore_19_ram_aux_ckbp;
  logic sigFromSrams_bore_19_ram_mcp_hold;
  logic sigFromSrams_bore_19_cgen;
  logic sigFromSrams_bore_20_ram_hold;
  logic sigFromSrams_bore_20_ram_bypass;
  logic sigFromSrams_bore_20_ram_bp_clken;
  logic sigFromSrams_bore_20_ram_aux_clk;
  logic sigFromSrams_bore_20_ram_aux_ckbp;
  logic sigFromSrams_bore_20_ram_mcp_hold;
  logic sigFromSrams_bore_20_cgen;
  logic cg_bore_cgen;
  logic cg_bore_1_cgen;
  wire g_auto_out_a_valid;
  wire i_auto_out_a_valid;
  wire [3:0] g_auto_out_a_bits_source;
  wire [3:0] i_auto_out_a_bits_source;
  wire [47:0] g_auto_out_a_bits_address;
  wire [47:0] i_auto_out_a_bits_address;
  wire g_io_tlb_0_req_0_ready;
  wire i_io_tlb_0_req_0_ready;
  wire g_io_tlb_0_resp_valid;
  wire i_io_tlb_0_resp_valid;
  wire [1:0] g_io_tlb_0_resp_bits_s2xlate;
  wire [1:0] i_io_tlb_0_resp_bits_s2xlate;
  wire [34:0] g_io_tlb_0_resp_bits_s1_entry_tag;
  wire [34:0] i_io_tlb_0_resp_bits_s1_entry_tag;
  wire [15:0] g_io_tlb_0_resp_bits_s1_entry_asid;
  wire [15:0] i_io_tlb_0_resp_bits_s1_entry_asid;
  wire [13:0] g_io_tlb_0_resp_bits_s1_entry_vmid;
  wire [13:0] i_io_tlb_0_resp_bits_s1_entry_vmid;
  wire g_io_tlb_0_resp_bits_s1_entry_n;
  wire i_io_tlb_0_resp_bits_s1_entry_n;
  wire [1:0] g_io_tlb_0_resp_bits_s1_entry_pbmt;
  wire [1:0] i_io_tlb_0_resp_bits_s1_entry_pbmt;
  wire g_io_tlb_0_resp_bits_s1_entry_perm_d;
  wire i_io_tlb_0_resp_bits_s1_entry_perm_d;
  wire g_io_tlb_0_resp_bits_s1_entry_perm_a;
  wire i_io_tlb_0_resp_bits_s1_entry_perm_a;
  wire g_io_tlb_0_resp_bits_s1_entry_perm_g;
  wire i_io_tlb_0_resp_bits_s1_entry_perm_g;
  wire g_io_tlb_0_resp_bits_s1_entry_perm_u;
  wire i_io_tlb_0_resp_bits_s1_entry_perm_u;
  wire g_io_tlb_0_resp_bits_s1_entry_perm_x;
  wire i_io_tlb_0_resp_bits_s1_entry_perm_x;
  wire g_io_tlb_0_resp_bits_s1_entry_perm_w;
  wire i_io_tlb_0_resp_bits_s1_entry_perm_w;
  wire g_io_tlb_0_resp_bits_s1_entry_perm_r;
  wire i_io_tlb_0_resp_bits_s1_entry_perm_r;
  wire [1:0] g_io_tlb_0_resp_bits_s1_entry_level;
  wire [1:0] i_io_tlb_0_resp_bits_s1_entry_level;
  wire g_io_tlb_0_resp_bits_s1_entry_v;
  wire i_io_tlb_0_resp_bits_s1_entry_v;
  wire [40:0] g_io_tlb_0_resp_bits_s1_entry_ppn;
  wire [40:0] i_io_tlb_0_resp_bits_s1_entry_ppn;
  wire [2:0] g_io_tlb_0_resp_bits_s1_addr_low;
  wire [2:0] i_io_tlb_0_resp_bits_s1_addr_low;
  wire [2:0] g_io_tlb_0_resp_bits_s1_ppn_low_0;
  wire [2:0] i_io_tlb_0_resp_bits_s1_ppn_low_0;
  wire [2:0] g_io_tlb_0_resp_bits_s1_ppn_low_1;
  wire [2:0] i_io_tlb_0_resp_bits_s1_ppn_low_1;
  wire [2:0] g_io_tlb_0_resp_bits_s1_ppn_low_2;
  wire [2:0] i_io_tlb_0_resp_bits_s1_ppn_low_2;
  wire [2:0] g_io_tlb_0_resp_bits_s1_ppn_low_3;
  wire [2:0] i_io_tlb_0_resp_bits_s1_ppn_low_3;
  wire [2:0] g_io_tlb_0_resp_bits_s1_ppn_low_4;
  wire [2:0] i_io_tlb_0_resp_bits_s1_ppn_low_4;
  wire [2:0] g_io_tlb_0_resp_bits_s1_ppn_low_5;
  wire [2:0] i_io_tlb_0_resp_bits_s1_ppn_low_5;
  wire [2:0] g_io_tlb_0_resp_bits_s1_ppn_low_6;
  wire [2:0] i_io_tlb_0_resp_bits_s1_ppn_low_6;
  wire [2:0] g_io_tlb_0_resp_bits_s1_ppn_low_7;
  wire [2:0] i_io_tlb_0_resp_bits_s1_ppn_low_7;
  wire g_io_tlb_0_resp_bits_s1_valididx_0;
  wire i_io_tlb_0_resp_bits_s1_valididx_0;
  wire g_io_tlb_0_resp_bits_s1_valididx_1;
  wire i_io_tlb_0_resp_bits_s1_valididx_1;
  wire g_io_tlb_0_resp_bits_s1_valididx_2;
  wire i_io_tlb_0_resp_bits_s1_valididx_2;
  wire g_io_tlb_0_resp_bits_s1_valididx_3;
  wire i_io_tlb_0_resp_bits_s1_valididx_3;
  wire g_io_tlb_0_resp_bits_s1_valididx_4;
  wire i_io_tlb_0_resp_bits_s1_valididx_4;
  wire g_io_tlb_0_resp_bits_s1_valididx_5;
  wire i_io_tlb_0_resp_bits_s1_valididx_5;
  wire g_io_tlb_0_resp_bits_s1_valididx_6;
  wire i_io_tlb_0_resp_bits_s1_valididx_6;
  wire g_io_tlb_0_resp_bits_s1_valididx_7;
  wire i_io_tlb_0_resp_bits_s1_valididx_7;
  wire g_io_tlb_0_resp_bits_s1_pteidx_0;
  wire i_io_tlb_0_resp_bits_s1_pteidx_0;
  wire g_io_tlb_0_resp_bits_s1_pteidx_1;
  wire i_io_tlb_0_resp_bits_s1_pteidx_1;
  wire g_io_tlb_0_resp_bits_s1_pteidx_2;
  wire i_io_tlb_0_resp_bits_s1_pteidx_2;
  wire g_io_tlb_0_resp_bits_s1_pteidx_3;
  wire i_io_tlb_0_resp_bits_s1_pteidx_3;
  wire g_io_tlb_0_resp_bits_s1_pteidx_4;
  wire i_io_tlb_0_resp_bits_s1_pteidx_4;
  wire g_io_tlb_0_resp_bits_s1_pteidx_5;
  wire i_io_tlb_0_resp_bits_s1_pteidx_5;
  wire g_io_tlb_0_resp_bits_s1_pteidx_6;
  wire i_io_tlb_0_resp_bits_s1_pteidx_6;
  wire g_io_tlb_0_resp_bits_s1_pteidx_7;
  wire i_io_tlb_0_resp_bits_s1_pteidx_7;
  wire g_io_tlb_0_resp_bits_s1_pf;
  wire i_io_tlb_0_resp_bits_s1_pf;
  wire g_io_tlb_0_resp_bits_s1_af;
  wire i_io_tlb_0_resp_bits_s1_af;
  wire [37:0] g_io_tlb_0_resp_bits_s2_entry_tag;
  wire [37:0] i_io_tlb_0_resp_bits_s2_entry_tag;
  wire [13:0] g_io_tlb_0_resp_bits_s2_entry_vmid;
  wire [13:0] i_io_tlb_0_resp_bits_s2_entry_vmid;
  wire g_io_tlb_0_resp_bits_s2_entry_n;
  wire i_io_tlb_0_resp_bits_s2_entry_n;
  wire [1:0] g_io_tlb_0_resp_bits_s2_entry_pbmt;
  wire [1:0] i_io_tlb_0_resp_bits_s2_entry_pbmt;
  wire [37:0] g_io_tlb_0_resp_bits_s2_entry_ppn;
  wire [37:0] i_io_tlb_0_resp_bits_s2_entry_ppn;
  wire g_io_tlb_0_resp_bits_s2_entry_perm_d;
  wire i_io_tlb_0_resp_bits_s2_entry_perm_d;
  wire g_io_tlb_0_resp_bits_s2_entry_perm_a;
  wire i_io_tlb_0_resp_bits_s2_entry_perm_a;
  wire g_io_tlb_0_resp_bits_s2_entry_perm_g;
  wire i_io_tlb_0_resp_bits_s2_entry_perm_g;
  wire g_io_tlb_0_resp_bits_s2_entry_perm_u;
  wire i_io_tlb_0_resp_bits_s2_entry_perm_u;
  wire g_io_tlb_0_resp_bits_s2_entry_perm_x;
  wire i_io_tlb_0_resp_bits_s2_entry_perm_x;
  wire g_io_tlb_0_resp_bits_s2_entry_perm_w;
  wire i_io_tlb_0_resp_bits_s2_entry_perm_w;
  wire g_io_tlb_0_resp_bits_s2_entry_perm_r;
  wire i_io_tlb_0_resp_bits_s2_entry_perm_r;
  wire [1:0] g_io_tlb_0_resp_bits_s2_entry_level;
  wire [1:0] i_io_tlb_0_resp_bits_s2_entry_level;
  wire g_io_tlb_0_resp_bits_s2_gpf;
  wire i_io_tlb_0_resp_bits_s2_gpf;
  wire g_io_tlb_0_resp_bits_s2_gaf;
  wire i_io_tlb_0_resp_bits_s2_gaf;
  wire g_io_tlb_1_req_0_ready;
  wire i_io_tlb_1_req_0_ready;
  wire g_io_tlb_1_resp_valid;
  wire i_io_tlb_1_resp_valid;
  wire [1:0] g_io_tlb_1_resp_bits_s2xlate;
  wire [1:0] i_io_tlb_1_resp_bits_s2xlate;
  wire [34:0] g_io_tlb_1_resp_bits_s1_entry_tag;
  wire [34:0] i_io_tlb_1_resp_bits_s1_entry_tag;
  wire [15:0] g_io_tlb_1_resp_bits_s1_entry_asid;
  wire [15:0] i_io_tlb_1_resp_bits_s1_entry_asid;
  wire [13:0] g_io_tlb_1_resp_bits_s1_entry_vmid;
  wire [13:0] i_io_tlb_1_resp_bits_s1_entry_vmid;
  wire g_io_tlb_1_resp_bits_s1_entry_n;
  wire i_io_tlb_1_resp_bits_s1_entry_n;
  wire [1:0] g_io_tlb_1_resp_bits_s1_entry_pbmt;
  wire [1:0] i_io_tlb_1_resp_bits_s1_entry_pbmt;
  wire g_io_tlb_1_resp_bits_s1_entry_perm_d;
  wire i_io_tlb_1_resp_bits_s1_entry_perm_d;
  wire g_io_tlb_1_resp_bits_s1_entry_perm_a;
  wire i_io_tlb_1_resp_bits_s1_entry_perm_a;
  wire g_io_tlb_1_resp_bits_s1_entry_perm_g;
  wire i_io_tlb_1_resp_bits_s1_entry_perm_g;
  wire g_io_tlb_1_resp_bits_s1_entry_perm_u;
  wire i_io_tlb_1_resp_bits_s1_entry_perm_u;
  wire g_io_tlb_1_resp_bits_s1_entry_perm_x;
  wire i_io_tlb_1_resp_bits_s1_entry_perm_x;
  wire g_io_tlb_1_resp_bits_s1_entry_perm_w;
  wire i_io_tlb_1_resp_bits_s1_entry_perm_w;
  wire g_io_tlb_1_resp_bits_s1_entry_perm_r;
  wire i_io_tlb_1_resp_bits_s1_entry_perm_r;
  wire [1:0] g_io_tlb_1_resp_bits_s1_entry_level;
  wire [1:0] i_io_tlb_1_resp_bits_s1_entry_level;
  wire g_io_tlb_1_resp_bits_s1_entry_v;
  wire i_io_tlb_1_resp_bits_s1_entry_v;
  wire [40:0] g_io_tlb_1_resp_bits_s1_entry_ppn;
  wire [40:0] i_io_tlb_1_resp_bits_s1_entry_ppn;
  wire [2:0] g_io_tlb_1_resp_bits_s1_addr_low;
  wire [2:0] i_io_tlb_1_resp_bits_s1_addr_low;
  wire [2:0] g_io_tlb_1_resp_bits_s1_ppn_low_0;
  wire [2:0] i_io_tlb_1_resp_bits_s1_ppn_low_0;
  wire [2:0] g_io_tlb_1_resp_bits_s1_ppn_low_1;
  wire [2:0] i_io_tlb_1_resp_bits_s1_ppn_low_1;
  wire [2:0] g_io_tlb_1_resp_bits_s1_ppn_low_2;
  wire [2:0] i_io_tlb_1_resp_bits_s1_ppn_low_2;
  wire [2:0] g_io_tlb_1_resp_bits_s1_ppn_low_3;
  wire [2:0] i_io_tlb_1_resp_bits_s1_ppn_low_3;
  wire [2:0] g_io_tlb_1_resp_bits_s1_ppn_low_4;
  wire [2:0] i_io_tlb_1_resp_bits_s1_ppn_low_4;
  wire [2:0] g_io_tlb_1_resp_bits_s1_ppn_low_5;
  wire [2:0] i_io_tlb_1_resp_bits_s1_ppn_low_5;
  wire [2:0] g_io_tlb_1_resp_bits_s1_ppn_low_6;
  wire [2:0] i_io_tlb_1_resp_bits_s1_ppn_low_6;
  wire [2:0] g_io_tlb_1_resp_bits_s1_ppn_low_7;
  wire [2:0] i_io_tlb_1_resp_bits_s1_ppn_low_7;
  wire g_io_tlb_1_resp_bits_s1_valididx_0;
  wire i_io_tlb_1_resp_bits_s1_valididx_0;
  wire g_io_tlb_1_resp_bits_s1_valididx_1;
  wire i_io_tlb_1_resp_bits_s1_valididx_1;
  wire g_io_tlb_1_resp_bits_s1_valididx_2;
  wire i_io_tlb_1_resp_bits_s1_valididx_2;
  wire g_io_tlb_1_resp_bits_s1_valididx_3;
  wire i_io_tlb_1_resp_bits_s1_valididx_3;
  wire g_io_tlb_1_resp_bits_s1_valididx_4;
  wire i_io_tlb_1_resp_bits_s1_valididx_4;
  wire g_io_tlb_1_resp_bits_s1_valididx_5;
  wire i_io_tlb_1_resp_bits_s1_valididx_5;
  wire g_io_tlb_1_resp_bits_s1_valididx_6;
  wire i_io_tlb_1_resp_bits_s1_valididx_6;
  wire g_io_tlb_1_resp_bits_s1_valididx_7;
  wire i_io_tlb_1_resp_bits_s1_valididx_7;
  wire g_io_tlb_1_resp_bits_s1_pteidx_0;
  wire i_io_tlb_1_resp_bits_s1_pteidx_0;
  wire g_io_tlb_1_resp_bits_s1_pteidx_1;
  wire i_io_tlb_1_resp_bits_s1_pteidx_1;
  wire g_io_tlb_1_resp_bits_s1_pteidx_2;
  wire i_io_tlb_1_resp_bits_s1_pteidx_2;
  wire g_io_tlb_1_resp_bits_s1_pteidx_3;
  wire i_io_tlb_1_resp_bits_s1_pteidx_3;
  wire g_io_tlb_1_resp_bits_s1_pteidx_4;
  wire i_io_tlb_1_resp_bits_s1_pteidx_4;
  wire g_io_tlb_1_resp_bits_s1_pteidx_5;
  wire i_io_tlb_1_resp_bits_s1_pteidx_5;
  wire g_io_tlb_1_resp_bits_s1_pteidx_6;
  wire i_io_tlb_1_resp_bits_s1_pteidx_6;
  wire g_io_tlb_1_resp_bits_s1_pteidx_7;
  wire i_io_tlb_1_resp_bits_s1_pteidx_7;
  wire g_io_tlb_1_resp_bits_s1_pf;
  wire i_io_tlb_1_resp_bits_s1_pf;
  wire g_io_tlb_1_resp_bits_s1_af;
  wire i_io_tlb_1_resp_bits_s1_af;
  wire [37:0] g_io_tlb_1_resp_bits_s2_entry_tag;
  wire [37:0] i_io_tlb_1_resp_bits_s2_entry_tag;
  wire [13:0] g_io_tlb_1_resp_bits_s2_entry_vmid;
  wire [13:0] i_io_tlb_1_resp_bits_s2_entry_vmid;
  wire g_io_tlb_1_resp_bits_s2_entry_n;
  wire i_io_tlb_1_resp_bits_s2_entry_n;
  wire [1:0] g_io_tlb_1_resp_bits_s2_entry_pbmt;
  wire [1:0] i_io_tlb_1_resp_bits_s2_entry_pbmt;
  wire [37:0] g_io_tlb_1_resp_bits_s2_entry_ppn;
  wire [37:0] i_io_tlb_1_resp_bits_s2_entry_ppn;
  wire g_io_tlb_1_resp_bits_s2_entry_perm_d;
  wire i_io_tlb_1_resp_bits_s2_entry_perm_d;
  wire g_io_tlb_1_resp_bits_s2_entry_perm_a;
  wire i_io_tlb_1_resp_bits_s2_entry_perm_a;
  wire g_io_tlb_1_resp_bits_s2_entry_perm_g;
  wire i_io_tlb_1_resp_bits_s2_entry_perm_g;
  wire g_io_tlb_1_resp_bits_s2_entry_perm_u;
  wire i_io_tlb_1_resp_bits_s2_entry_perm_u;
  wire g_io_tlb_1_resp_bits_s2_entry_perm_x;
  wire i_io_tlb_1_resp_bits_s2_entry_perm_x;
  wire g_io_tlb_1_resp_bits_s2_entry_perm_w;
  wire i_io_tlb_1_resp_bits_s2_entry_perm_w;
  wire g_io_tlb_1_resp_bits_s2_entry_perm_r;
  wire i_io_tlb_1_resp_bits_s2_entry_perm_r;
  wire [1:0] g_io_tlb_1_resp_bits_s2_entry_level;
  wire [1:0] i_io_tlb_1_resp_bits_s2_entry_level;
  wire g_io_tlb_1_resp_bits_s2_gpf;
  wire i_io_tlb_1_resp_bits_s2_gpf;
  wire g_io_tlb_1_resp_bits_s2_gaf;
  wire i_io_tlb_1_resp_bits_s2_gaf;
  wire g_io_wfi_wfiSafe;
  wire i_io_wfi_wfiSafe;
  wire [5:0] g_io_perf_0_value;
  wire [5:0] i_io_perf_0_value;
  wire [5:0] g_io_perf_1_value;
  wire [5:0] i_io_perf_1_value;
  wire [5:0] g_io_perf_2_value;
  wire [5:0] i_io_perf_2_value;
  wire [5:0] g_io_perf_3_value;
  wire [5:0] i_io_perf_3_value;
  wire [5:0] g_io_perf_4_value;
  wire [5:0] i_io_perf_4_value;
  wire [5:0] g_io_perf_5_value;
  wire [5:0] i_io_perf_5_value;
  wire [5:0] g_io_perf_6_value;
  wire [5:0] i_io_perf_6_value;
  wire [5:0] g_io_perf_7_value;
  wire [5:0] i_io_perf_7_value;
  wire [5:0] g_io_perf_8_value;
  wire [5:0] i_io_perf_8_value;
  wire [5:0] g_io_perf_9_value;
  wire [5:0] i_io_perf_9_value;
  wire [5:0] g_io_perf_10_value;
  wire [5:0] i_io_perf_10_value;
  wire [5:0] g_io_perf_11_value;
  wire [5:0] i_io_perf_11_value;
  wire [5:0] g_io_perf_12_value;
  wire [5:0] i_io_perf_12_value;
  wire [5:0] g_io_perf_13_value;
  wire [5:0] i_io_perf_13_value;
  wire [5:0] g_io_perf_14_value;
  wire [5:0] i_io_perf_14_value;
  wire [5:0] g_io_perf_15_value;
  wire [5:0] i_io_perf_15_value;
  wire [5:0] g_io_perf_16_value;
  wire [5:0] i_io_perf_16_value;
  wire [5:0] g_io_perf_17_value;
  wire [5:0] i_io_perf_17_value;
  wire [5:0] g_io_perf_18_value;
  wire [5:0] i_io_perf_18_value;
  wire g_boreChildrenBd_bore_ack;
  wire i_boreChildrenBd_bore_ack;
  wire [89:0] g_boreChildrenBd_bore_outdata;
  wire [89:0] i_boreChildrenBd_bore_outdata;
  wire g_boreChildrenBd_bore_1_ack;
  wire i_boreChildrenBd_bore_1_ack;
  wire [130:0] g_boreChildrenBd_bore_1_outdata;
  wire [130:0] i_boreChildrenBd_bore_1_outdata;
  wire g_boreChildrenBd_bore_2_ack;
  wire i_boreChildrenBd_bore_2_ack;
  wire [113:0] g_boreChildrenBd_bore_2_outdata;
  wire [113:0] i_boreChildrenBd_bore_2_outdata;
  wire [600:0] g_gatewayIn_packed_43_bore;
  wire [600:0] i_gatewayIn_packed_43_bore;
  wire [968:0] g_gatewayIn_packed_44_bore;
  wire [968:0] i_gatewayIn_packed_44_bore;
  wire [968:0] g_gatewayIn_packed_45_bore;
  wire [968:0] i_gatewayIn_packed_45_bore;

  L2TLB u_g (
    .clock(clock),
    .reset(reset),
    .auto_out_a_ready(auto_out_a_ready),
    .auto_out_d_valid(auto_out_d_valid),
    .auto_out_d_bits_opcode(auto_out_d_bits_opcode),
    .auto_out_d_bits_size(auto_out_d_bits_size),
    .auto_out_d_bits_source(auto_out_d_bits_source),
    .auto_out_d_bits_data(auto_out_d_bits_data),
    .io_hartId(io_hartId),
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
    .io_csr_tlb_mbmc_BME(io_csr_tlb_mbmc_BME),
    .io_csr_tlb_mbmc_CMODE(io_csr_tlb_mbmc_CMODE),
    .io_csr_tlb_mbmc_BCLEAR(io_csr_tlb_mbmc_BCLEAR),
    .io_csr_tlb_mbmc_BMA(io_csr_tlb_mbmc_BMA),
    .io_csr_tlb_priv_virt(io_csr_tlb_priv_virt),
    .io_csr_tlb_priv_virt_changed(io_csr_tlb_priv_virt_changed),
    .io_csr_tlb_priv_debug(io_csr_tlb_priv_debug),
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
    .boreChildrenBd_bore_2_array(boreChildrenBd_bore_2_array),
    .boreChildrenBd_bore_2_all(boreChildrenBd_bore_2_all),
    .boreChildrenBd_bore_2_req(boreChildrenBd_bore_2_req),
    .boreChildrenBd_bore_2_writeen(boreChildrenBd_bore_2_writeen),
    .boreChildrenBd_bore_2_be(boreChildrenBd_bore_2_be),
    .boreChildrenBd_bore_2_addr(boreChildrenBd_bore_2_addr),
    .boreChildrenBd_bore_2_indata(boreChildrenBd_bore_2_indata),
    .boreChildrenBd_bore_2_readen(boreChildrenBd_bore_2_readen),
    .boreChildrenBd_bore_2_addr_rd(boreChildrenBd_bore_2_addr_rd),
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
    .sigFromSrams_bore_12_ram_hold(sigFromSrams_bore_12_ram_hold),
    .sigFromSrams_bore_12_ram_bypass(sigFromSrams_bore_12_ram_bypass),
    .sigFromSrams_bore_12_ram_bp_clken(sigFromSrams_bore_12_ram_bp_clken),
    .sigFromSrams_bore_12_ram_aux_clk(sigFromSrams_bore_12_ram_aux_clk),
    .sigFromSrams_bore_12_ram_aux_ckbp(sigFromSrams_bore_12_ram_aux_ckbp),
    .sigFromSrams_bore_12_ram_mcp_hold(sigFromSrams_bore_12_ram_mcp_hold),
    .sigFromSrams_bore_12_cgen(sigFromSrams_bore_12_cgen),
    .sigFromSrams_bore_13_ram_hold(sigFromSrams_bore_13_ram_hold),
    .sigFromSrams_bore_13_ram_bypass(sigFromSrams_bore_13_ram_bypass),
    .sigFromSrams_bore_13_ram_bp_clken(sigFromSrams_bore_13_ram_bp_clken),
    .sigFromSrams_bore_13_ram_aux_clk(sigFromSrams_bore_13_ram_aux_clk),
    .sigFromSrams_bore_13_ram_aux_ckbp(sigFromSrams_bore_13_ram_aux_ckbp),
    .sigFromSrams_bore_13_ram_mcp_hold(sigFromSrams_bore_13_ram_mcp_hold),
    .sigFromSrams_bore_13_cgen(sigFromSrams_bore_13_cgen),
    .sigFromSrams_bore_14_ram_hold(sigFromSrams_bore_14_ram_hold),
    .sigFromSrams_bore_14_ram_bypass(sigFromSrams_bore_14_ram_bypass),
    .sigFromSrams_bore_14_ram_bp_clken(sigFromSrams_bore_14_ram_bp_clken),
    .sigFromSrams_bore_14_ram_aux_clk(sigFromSrams_bore_14_ram_aux_clk),
    .sigFromSrams_bore_14_ram_aux_ckbp(sigFromSrams_bore_14_ram_aux_ckbp),
    .sigFromSrams_bore_14_ram_mcp_hold(sigFromSrams_bore_14_ram_mcp_hold),
    .sigFromSrams_bore_14_cgen(sigFromSrams_bore_14_cgen),
    .sigFromSrams_bore_15_ram_hold(sigFromSrams_bore_15_ram_hold),
    .sigFromSrams_bore_15_ram_bypass(sigFromSrams_bore_15_ram_bypass),
    .sigFromSrams_bore_15_ram_bp_clken(sigFromSrams_bore_15_ram_bp_clken),
    .sigFromSrams_bore_15_ram_aux_clk(sigFromSrams_bore_15_ram_aux_clk),
    .sigFromSrams_bore_15_ram_aux_ckbp(sigFromSrams_bore_15_ram_aux_ckbp),
    .sigFromSrams_bore_15_ram_mcp_hold(sigFromSrams_bore_15_ram_mcp_hold),
    .sigFromSrams_bore_15_cgen(sigFromSrams_bore_15_cgen),
    .sigFromSrams_bore_16_ram_hold(sigFromSrams_bore_16_ram_hold),
    .sigFromSrams_bore_16_ram_bypass(sigFromSrams_bore_16_ram_bypass),
    .sigFromSrams_bore_16_ram_bp_clken(sigFromSrams_bore_16_ram_bp_clken),
    .sigFromSrams_bore_16_ram_aux_clk(sigFromSrams_bore_16_ram_aux_clk),
    .sigFromSrams_bore_16_ram_aux_ckbp(sigFromSrams_bore_16_ram_aux_ckbp),
    .sigFromSrams_bore_16_ram_mcp_hold(sigFromSrams_bore_16_ram_mcp_hold),
    .sigFromSrams_bore_16_cgen(sigFromSrams_bore_16_cgen),
    .sigFromSrams_bore_17_ram_hold(sigFromSrams_bore_17_ram_hold),
    .sigFromSrams_bore_17_ram_bypass(sigFromSrams_bore_17_ram_bypass),
    .sigFromSrams_bore_17_ram_bp_clken(sigFromSrams_bore_17_ram_bp_clken),
    .sigFromSrams_bore_17_ram_aux_clk(sigFromSrams_bore_17_ram_aux_clk),
    .sigFromSrams_bore_17_ram_aux_ckbp(sigFromSrams_bore_17_ram_aux_ckbp),
    .sigFromSrams_bore_17_ram_mcp_hold(sigFromSrams_bore_17_ram_mcp_hold),
    .sigFromSrams_bore_17_cgen(sigFromSrams_bore_17_cgen),
    .sigFromSrams_bore_18_ram_hold(sigFromSrams_bore_18_ram_hold),
    .sigFromSrams_bore_18_ram_bypass(sigFromSrams_bore_18_ram_bypass),
    .sigFromSrams_bore_18_ram_bp_clken(sigFromSrams_bore_18_ram_bp_clken),
    .sigFromSrams_bore_18_ram_aux_clk(sigFromSrams_bore_18_ram_aux_clk),
    .sigFromSrams_bore_18_ram_aux_ckbp(sigFromSrams_bore_18_ram_aux_ckbp),
    .sigFromSrams_bore_18_ram_mcp_hold(sigFromSrams_bore_18_ram_mcp_hold),
    .sigFromSrams_bore_18_cgen(sigFromSrams_bore_18_cgen),
    .sigFromSrams_bore_19_ram_hold(sigFromSrams_bore_19_ram_hold),
    .sigFromSrams_bore_19_ram_bypass(sigFromSrams_bore_19_ram_bypass),
    .sigFromSrams_bore_19_ram_bp_clken(sigFromSrams_bore_19_ram_bp_clken),
    .sigFromSrams_bore_19_ram_aux_clk(sigFromSrams_bore_19_ram_aux_clk),
    .sigFromSrams_bore_19_ram_aux_ckbp(sigFromSrams_bore_19_ram_aux_ckbp),
    .sigFromSrams_bore_19_ram_mcp_hold(sigFromSrams_bore_19_ram_mcp_hold),
    .sigFromSrams_bore_19_cgen(sigFromSrams_bore_19_cgen),
    .sigFromSrams_bore_20_ram_hold(sigFromSrams_bore_20_ram_hold),
    .sigFromSrams_bore_20_ram_bypass(sigFromSrams_bore_20_ram_bypass),
    .sigFromSrams_bore_20_ram_bp_clken(sigFromSrams_bore_20_ram_bp_clken),
    .sigFromSrams_bore_20_ram_aux_clk(sigFromSrams_bore_20_ram_aux_clk),
    .sigFromSrams_bore_20_ram_aux_ckbp(sigFromSrams_bore_20_ram_aux_ckbp),
    .sigFromSrams_bore_20_ram_mcp_hold(sigFromSrams_bore_20_ram_mcp_hold),
    .sigFromSrams_bore_20_cgen(sigFromSrams_bore_20_cgen),
    .cg_bore_cgen(cg_bore_cgen),
    .cg_bore_1_cgen(cg_bore_1_cgen),
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
    .boreChildrenBd_bore_1_outdata(g_boreChildrenBd_bore_1_outdata),
    .boreChildrenBd_bore_2_ack(g_boreChildrenBd_bore_2_ack),
    .boreChildrenBd_bore_2_outdata(g_boreChildrenBd_bore_2_outdata),
    .gatewayIn_packed_43_bore(g_gatewayIn_packed_43_bore),
    .gatewayIn_packed_44_bore(g_gatewayIn_packed_44_bore),
    .gatewayIn_packed_45_bore(g_gatewayIn_packed_45_bore)
  );

  L2TLB_xs u_i (
    .clock(clock),
    .reset(reset),
    .auto_out_a_ready(auto_out_a_ready),
    .auto_out_d_valid(auto_out_d_valid),
    .auto_out_d_bits_opcode(auto_out_d_bits_opcode),
    .auto_out_d_bits_size(auto_out_d_bits_size),
    .auto_out_d_bits_source(auto_out_d_bits_source),
    .auto_out_d_bits_data(auto_out_d_bits_data),
    .io_hartId(io_hartId),
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
    .io_csr_tlb_mbmc_BME(io_csr_tlb_mbmc_BME),
    .io_csr_tlb_mbmc_CMODE(io_csr_tlb_mbmc_CMODE),
    .io_csr_tlb_mbmc_BCLEAR(io_csr_tlb_mbmc_BCLEAR),
    .io_csr_tlb_mbmc_BMA(io_csr_tlb_mbmc_BMA),
    .io_csr_tlb_priv_virt(io_csr_tlb_priv_virt),
    .io_csr_tlb_priv_virt_changed(io_csr_tlb_priv_virt_changed),
    .io_csr_tlb_priv_debug(io_csr_tlb_priv_debug),
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
    .boreChildrenBd_bore_2_array(boreChildrenBd_bore_2_array),
    .boreChildrenBd_bore_2_all(boreChildrenBd_bore_2_all),
    .boreChildrenBd_bore_2_req(boreChildrenBd_bore_2_req),
    .boreChildrenBd_bore_2_writeen(boreChildrenBd_bore_2_writeen),
    .boreChildrenBd_bore_2_be(boreChildrenBd_bore_2_be),
    .boreChildrenBd_bore_2_addr(boreChildrenBd_bore_2_addr),
    .boreChildrenBd_bore_2_indata(boreChildrenBd_bore_2_indata),
    .boreChildrenBd_bore_2_readen(boreChildrenBd_bore_2_readen),
    .boreChildrenBd_bore_2_addr_rd(boreChildrenBd_bore_2_addr_rd),
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
    .sigFromSrams_bore_12_ram_hold(sigFromSrams_bore_12_ram_hold),
    .sigFromSrams_bore_12_ram_bypass(sigFromSrams_bore_12_ram_bypass),
    .sigFromSrams_bore_12_ram_bp_clken(sigFromSrams_bore_12_ram_bp_clken),
    .sigFromSrams_bore_12_ram_aux_clk(sigFromSrams_bore_12_ram_aux_clk),
    .sigFromSrams_bore_12_ram_aux_ckbp(sigFromSrams_bore_12_ram_aux_ckbp),
    .sigFromSrams_bore_12_ram_mcp_hold(sigFromSrams_bore_12_ram_mcp_hold),
    .sigFromSrams_bore_12_cgen(sigFromSrams_bore_12_cgen),
    .sigFromSrams_bore_13_ram_hold(sigFromSrams_bore_13_ram_hold),
    .sigFromSrams_bore_13_ram_bypass(sigFromSrams_bore_13_ram_bypass),
    .sigFromSrams_bore_13_ram_bp_clken(sigFromSrams_bore_13_ram_bp_clken),
    .sigFromSrams_bore_13_ram_aux_clk(sigFromSrams_bore_13_ram_aux_clk),
    .sigFromSrams_bore_13_ram_aux_ckbp(sigFromSrams_bore_13_ram_aux_ckbp),
    .sigFromSrams_bore_13_ram_mcp_hold(sigFromSrams_bore_13_ram_mcp_hold),
    .sigFromSrams_bore_13_cgen(sigFromSrams_bore_13_cgen),
    .sigFromSrams_bore_14_ram_hold(sigFromSrams_bore_14_ram_hold),
    .sigFromSrams_bore_14_ram_bypass(sigFromSrams_bore_14_ram_bypass),
    .sigFromSrams_bore_14_ram_bp_clken(sigFromSrams_bore_14_ram_bp_clken),
    .sigFromSrams_bore_14_ram_aux_clk(sigFromSrams_bore_14_ram_aux_clk),
    .sigFromSrams_bore_14_ram_aux_ckbp(sigFromSrams_bore_14_ram_aux_ckbp),
    .sigFromSrams_bore_14_ram_mcp_hold(sigFromSrams_bore_14_ram_mcp_hold),
    .sigFromSrams_bore_14_cgen(sigFromSrams_bore_14_cgen),
    .sigFromSrams_bore_15_ram_hold(sigFromSrams_bore_15_ram_hold),
    .sigFromSrams_bore_15_ram_bypass(sigFromSrams_bore_15_ram_bypass),
    .sigFromSrams_bore_15_ram_bp_clken(sigFromSrams_bore_15_ram_bp_clken),
    .sigFromSrams_bore_15_ram_aux_clk(sigFromSrams_bore_15_ram_aux_clk),
    .sigFromSrams_bore_15_ram_aux_ckbp(sigFromSrams_bore_15_ram_aux_ckbp),
    .sigFromSrams_bore_15_ram_mcp_hold(sigFromSrams_bore_15_ram_mcp_hold),
    .sigFromSrams_bore_15_cgen(sigFromSrams_bore_15_cgen),
    .sigFromSrams_bore_16_ram_hold(sigFromSrams_bore_16_ram_hold),
    .sigFromSrams_bore_16_ram_bypass(sigFromSrams_bore_16_ram_bypass),
    .sigFromSrams_bore_16_ram_bp_clken(sigFromSrams_bore_16_ram_bp_clken),
    .sigFromSrams_bore_16_ram_aux_clk(sigFromSrams_bore_16_ram_aux_clk),
    .sigFromSrams_bore_16_ram_aux_ckbp(sigFromSrams_bore_16_ram_aux_ckbp),
    .sigFromSrams_bore_16_ram_mcp_hold(sigFromSrams_bore_16_ram_mcp_hold),
    .sigFromSrams_bore_16_cgen(sigFromSrams_bore_16_cgen),
    .sigFromSrams_bore_17_ram_hold(sigFromSrams_bore_17_ram_hold),
    .sigFromSrams_bore_17_ram_bypass(sigFromSrams_bore_17_ram_bypass),
    .sigFromSrams_bore_17_ram_bp_clken(sigFromSrams_bore_17_ram_bp_clken),
    .sigFromSrams_bore_17_ram_aux_clk(sigFromSrams_bore_17_ram_aux_clk),
    .sigFromSrams_bore_17_ram_aux_ckbp(sigFromSrams_bore_17_ram_aux_ckbp),
    .sigFromSrams_bore_17_ram_mcp_hold(sigFromSrams_bore_17_ram_mcp_hold),
    .sigFromSrams_bore_17_cgen(sigFromSrams_bore_17_cgen),
    .sigFromSrams_bore_18_ram_hold(sigFromSrams_bore_18_ram_hold),
    .sigFromSrams_bore_18_ram_bypass(sigFromSrams_bore_18_ram_bypass),
    .sigFromSrams_bore_18_ram_bp_clken(sigFromSrams_bore_18_ram_bp_clken),
    .sigFromSrams_bore_18_ram_aux_clk(sigFromSrams_bore_18_ram_aux_clk),
    .sigFromSrams_bore_18_ram_aux_ckbp(sigFromSrams_bore_18_ram_aux_ckbp),
    .sigFromSrams_bore_18_ram_mcp_hold(sigFromSrams_bore_18_ram_mcp_hold),
    .sigFromSrams_bore_18_cgen(sigFromSrams_bore_18_cgen),
    .sigFromSrams_bore_19_ram_hold(sigFromSrams_bore_19_ram_hold),
    .sigFromSrams_bore_19_ram_bypass(sigFromSrams_bore_19_ram_bypass),
    .sigFromSrams_bore_19_ram_bp_clken(sigFromSrams_bore_19_ram_bp_clken),
    .sigFromSrams_bore_19_ram_aux_clk(sigFromSrams_bore_19_ram_aux_clk),
    .sigFromSrams_bore_19_ram_aux_ckbp(sigFromSrams_bore_19_ram_aux_ckbp),
    .sigFromSrams_bore_19_ram_mcp_hold(sigFromSrams_bore_19_ram_mcp_hold),
    .sigFromSrams_bore_19_cgen(sigFromSrams_bore_19_cgen),
    .sigFromSrams_bore_20_ram_hold(sigFromSrams_bore_20_ram_hold),
    .sigFromSrams_bore_20_ram_bypass(sigFromSrams_bore_20_ram_bypass),
    .sigFromSrams_bore_20_ram_bp_clken(sigFromSrams_bore_20_ram_bp_clken),
    .sigFromSrams_bore_20_ram_aux_clk(sigFromSrams_bore_20_ram_aux_clk),
    .sigFromSrams_bore_20_ram_aux_ckbp(sigFromSrams_bore_20_ram_aux_ckbp),
    .sigFromSrams_bore_20_ram_mcp_hold(sigFromSrams_bore_20_ram_mcp_hold),
    .sigFromSrams_bore_20_cgen(sigFromSrams_bore_20_cgen),
    .cg_bore_cgen(cg_bore_cgen),
    .cg_bore_1_cgen(cg_bore_1_cgen),
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
    .boreChildrenBd_bore_1_outdata(i_boreChildrenBd_bore_1_outdata),
    .boreChildrenBd_bore_2_ack(i_boreChildrenBd_bore_2_ack),
    .boreChildrenBd_bore_2_outdata(i_boreChildrenBd_bore_2_outdata),
    .gatewayIn_packed_43_bore(i_gatewayIn_packed_43_bore),
    .gatewayIn_packed_44_bore(i_gatewayIn_packed_44_bore),
    .gatewayIn_packed_45_bore(i_gatewayIn_packed_45_bore)
  );

  task automatic do_check(int t);
    checks++;
    if (g_auto_out_a_valid !== i_auto_out_a_valid) begin errors++;
      if (errors<=60) $display("vec %0d auto_out_a_valid g=%b i=%b", t, g_auto_out_a_valid, i_auto_out_a_valid); end
    if (g_auto_out_a_bits_source !== i_auto_out_a_bits_source) begin errors++;
      if (errors<=60) $display("vec %0d auto_out_a_bits_source g=%h i=%h", t, g_auto_out_a_bits_source, i_auto_out_a_bits_source); end
    if (g_auto_out_a_bits_address !== i_auto_out_a_bits_address) begin errors++;
      if (errors<=60) $display("vec %0d auto_out_a_bits_address g=%h i=%h", t, g_auto_out_a_bits_address, i_auto_out_a_bits_address); end
    if (g_io_tlb_0_req_0_ready !== i_io_tlb_0_req_0_ready) begin errors++;
      if (errors<=60) $display("vec %0d io_tlb_0_req_0_ready g=%b i=%b", t, g_io_tlb_0_req_0_ready, i_io_tlb_0_req_0_ready); end
    if (g_io_tlb_0_resp_valid !== i_io_tlb_0_resp_valid) begin errors++;
      if (errors<=60) $display("vec %0d io_tlb_0_resp_valid g=%b i=%b", t, g_io_tlb_0_resp_valid, i_io_tlb_0_resp_valid); end
    if (g_io_tlb_0_resp_bits_s2xlate !== i_io_tlb_0_resp_bits_s2xlate) begin errors++;
      if (errors<=60) $display("vec %0d io_tlb_0_resp_bits_s2xlate g=%h i=%h", t, g_io_tlb_0_resp_bits_s2xlate, i_io_tlb_0_resp_bits_s2xlate); end
    if (g_io_tlb_0_resp_bits_s1_entry_tag !== i_io_tlb_0_resp_bits_s1_entry_tag) begin errors++;
      if (errors<=60) $display("vec %0d io_tlb_0_resp_bits_s1_entry_tag g=%h i=%h", t, g_io_tlb_0_resp_bits_s1_entry_tag, i_io_tlb_0_resp_bits_s1_entry_tag); end
    if (g_io_tlb_0_resp_bits_s1_entry_asid !== i_io_tlb_0_resp_bits_s1_entry_asid) begin errors++;
      if (errors<=60) $display("vec %0d io_tlb_0_resp_bits_s1_entry_asid g=%h i=%h", t, g_io_tlb_0_resp_bits_s1_entry_asid, i_io_tlb_0_resp_bits_s1_entry_asid); end
    if (g_io_tlb_0_resp_bits_s1_entry_vmid !== i_io_tlb_0_resp_bits_s1_entry_vmid) begin errors++;
      if (errors<=60) $display("vec %0d io_tlb_0_resp_bits_s1_entry_vmid g=%h i=%h", t, g_io_tlb_0_resp_bits_s1_entry_vmid, i_io_tlb_0_resp_bits_s1_entry_vmid); end
    if (g_io_tlb_0_resp_bits_s1_entry_n !== i_io_tlb_0_resp_bits_s1_entry_n) begin errors++;
      if (errors<=60) $display("vec %0d io_tlb_0_resp_bits_s1_entry_n g=%b i=%b", t, g_io_tlb_0_resp_bits_s1_entry_n, i_io_tlb_0_resp_bits_s1_entry_n); end
    if (g_io_tlb_0_resp_bits_s1_entry_pbmt !== i_io_tlb_0_resp_bits_s1_entry_pbmt) begin errors++;
      if (errors<=60) $display("vec %0d io_tlb_0_resp_bits_s1_entry_pbmt g=%h i=%h", t, g_io_tlb_0_resp_bits_s1_entry_pbmt, i_io_tlb_0_resp_bits_s1_entry_pbmt); end
    if (g_io_tlb_0_resp_bits_s1_entry_perm_d !== i_io_tlb_0_resp_bits_s1_entry_perm_d) begin errors++;
      if (errors<=60) $display("vec %0d io_tlb_0_resp_bits_s1_entry_perm_d g=%b i=%b", t, g_io_tlb_0_resp_bits_s1_entry_perm_d, i_io_tlb_0_resp_bits_s1_entry_perm_d); end
    if (g_io_tlb_0_resp_bits_s1_entry_perm_a !== i_io_tlb_0_resp_bits_s1_entry_perm_a) begin errors++;
      if (errors<=60) $display("vec %0d io_tlb_0_resp_bits_s1_entry_perm_a g=%b i=%b", t, g_io_tlb_0_resp_bits_s1_entry_perm_a, i_io_tlb_0_resp_bits_s1_entry_perm_a); end
    if (g_io_tlb_0_resp_bits_s1_entry_perm_g !== i_io_tlb_0_resp_bits_s1_entry_perm_g) begin errors++;
      if (errors<=60) $display("vec %0d io_tlb_0_resp_bits_s1_entry_perm_g g=%b i=%b", t, g_io_tlb_0_resp_bits_s1_entry_perm_g, i_io_tlb_0_resp_bits_s1_entry_perm_g); end
    if (g_io_tlb_0_resp_bits_s1_entry_perm_u !== i_io_tlb_0_resp_bits_s1_entry_perm_u) begin errors++;
      if (errors<=60) $display("vec %0d io_tlb_0_resp_bits_s1_entry_perm_u g=%b i=%b", t, g_io_tlb_0_resp_bits_s1_entry_perm_u, i_io_tlb_0_resp_bits_s1_entry_perm_u); end
    if (g_io_tlb_0_resp_bits_s1_entry_perm_x !== i_io_tlb_0_resp_bits_s1_entry_perm_x) begin errors++;
      if (errors<=60) $display("vec %0d io_tlb_0_resp_bits_s1_entry_perm_x g=%b i=%b", t, g_io_tlb_0_resp_bits_s1_entry_perm_x, i_io_tlb_0_resp_bits_s1_entry_perm_x); end
    if (g_io_tlb_0_resp_bits_s1_entry_perm_w !== i_io_tlb_0_resp_bits_s1_entry_perm_w) begin errors++;
      if (errors<=60) $display("vec %0d io_tlb_0_resp_bits_s1_entry_perm_w g=%b i=%b", t, g_io_tlb_0_resp_bits_s1_entry_perm_w, i_io_tlb_0_resp_bits_s1_entry_perm_w); end
    if (g_io_tlb_0_resp_bits_s1_entry_perm_r !== i_io_tlb_0_resp_bits_s1_entry_perm_r) begin errors++;
      if (errors<=60) $display("vec %0d io_tlb_0_resp_bits_s1_entry_perm_r g=%b i=%b", t, g_io_tlb_0_resp_bits_s1_entry_perm_r, i_io_tlb_0_resp_bits_s1_entry_perm_r); end
    if (g_io_tlb_0_resp_bits_s1_entry_level !== i_io_tlb_0_resp_bits_s1_entry_level) begin errors++;
      if (errors<=60) $display("vec %0d io_tlb_0_resp_bits_s1_entry_level g=%h i=%h", t, g_io_tlb_0_resp_bits_s1_entry_level, i_io_tlb_0_resp_bits_s1_entry_level); end
    if (g_io_tlb_0_resp_bits_s1_entry_v !== i_io_tlb_0_resp_bits_s1_entry_v) begin errors++;
      if (errors<=60) $display("vec %0d io_tlb_0_resp_bits_s1_entry_v g=%b i=%b", t, g_io_tlb_0_resp_bits_s1_entry_v, i_io_tlb_0_resp_bits_s1_entry_v); end
    if (g_io_tlb_0_resp_bits_s1_entry_ppn !== i_io_tlb_0_resp_bits_s1_entry_ppn) begin errors++;
      if (errors<=60) $display("vec %0d io_tlb_0_resp_bits_s1_entry_ppn g=%h i=%h", t, g_io_tlb_0_resp_bits_s1_entry_ppn, i_io_tlb_0_resp_bits_s1_entry_ppn); end
    if (g_io_tlb_0_resp_bits_s1_addr_low !== i_io_tlb_0_resp_bits_s1_addr_low) begin errors++;
      if (errors<=60) $display("vec %0d io_tlb_0_resp_bits_s1_addr_low g=%h i=%h", t, g_io_tlb_0_resp_bits_s1_addr_low, i_io_tlb_0_resp_bits_s1_addr_low); end
    if (g_io_tlb_0_resp_bits_s1_ppn_low_0 !== i_io_tlb_0_resp_bits_s1_ppn_low_0) begin errors++;
      if (errors<=60) $display("vec %0d io_tlb_0_resp_bits_s1_ppn_low_0 g=%h i=%h", t, g_io_tlb_0_resp_bits_s1_ppn_low_0, i_io_tlb_0_resp_bits_s1_ppn_low_0); end
    if (g_io_tlb_0_resp_bits_s1_ppn_low_1 !== i_io_tlb_0_resp_bits_s1_ppn_low_1) begin errors++;
      if (errors<=60) $display("vec %0d io_tlb_0_resp_bits_s1_ppn_low_1 g=%h i=%h", t, g_io_tlb_0_resp_bits_s1_ppn_low_1, i_io_tlb_0_resp_bits_s1_ppn_low_1); end
    if (g_io_tlb_0_resp_bits_s1_ppn_low_2 !== i_io_tlb_0_resp_bits_s1_ppn_low_2) begin errors++;
      if (errors<=60) $display("vec %0d io_tlb_0_resp_bits_s1_ppn_low_2 g=%h i=%h", t, g_io_tlb_0_resp_bits_s1_ppn_low_2, i_io_tlb_0_resp_bits_s1_ppn_low_2); end
    if (g_io_tlb_0_resp_bits_s1_ppn_low_3 !== i_io_tlb_0_resp_bits_s1_ppn_low_3) begin errors++;
      if (errors<=60) $display("vec %0d io_tlb_0_resp_bits_s1_ppn_low_3 g=%h i=%h", t, g_io_tlb_0_resp_bits_s1_ppn_low_3, i_io_tlb_0_resp_bits_s1_ppn_low_3); end
    if (g_io_tlb_0_resp_bits_s1_ppn_low_4 !== i_io_tlb_0_resp_bits_s1_ppn_low_4) begin errors++;
      if (errors<=60) $display("vec %0d io_tlb_0_resp_bits_s1_ppn_low_4 g=%h i=%h", t, g_io_tlb_0_resp_bits_s1_ppn_low_4, i_io_tlb_0_resp_bits_s1_ppn_low_4); end
    if (g_io_tlb_0_resp_bits_s1_ppn_low_5 !== i_io_tlb_0_resp_bits_s1_ppn_low_5) begin errors++;
      if (errors<=60) $display("vec %0d io_tlb_0_resp_bits_s1_ppn_low_5 g=%h i=%h", t, g_io_tlb_0_resp_bits_s1_ppn_low_5, i_io_tlb_0_resp_bits_s1_ppn_low_5); end
    if (g_io_tlb_0_resp_bits_s1_ppn_low_6 !== i_io_tlb_0_resp_bits_s1_ppn_low_6) begin errors++;
      if (errors<=60) $display("vec %0d io_tlb_0_resp_bits_s1_ppn_low_6 g=%h i=%h", t, g_io_tlb_0_resp_bits_s1_ppn_low_6, i_io_tlb_0_resp_bits_s1_ppn_low_6); end
    if (g_io_tlb_0_resp_bits_s1_ppn_low_7 !== i_io_tlb_0_resp_bits_s1_ppn_low_7) begin errors++;
      if (errors<=60) $display("vec %0d io_tlb_0_resp_bits_s1_ppn_low_7 g=%h i=%h", t, g_io_tlb_0_resp_bits_s1_ppn_low_7, i_io_tlb_0_resp_bits_s1_ppn_low_7); end
    if (g_io_tlb_0_resp_bits_s1_valididx_0 !== i_io_tlb_0_resp_bits_s1_valididx_0) begin errors++;
      if (errors<=60) $display("vec %0d io_tlb_0_resp_bits_s1_valididx_0 g=%b i=%b", t, g_io_tlb_0_resp_bits_s1_valididx_0, i_io_tlb_0_resp_bits_s1_valididx_0); end
    if (g_io_tlb_0_resp_bits_s1_valididx_1 !== i_io_tlb_0_resp_bits_s1_valididx_1) begin errors++;
      if (errors<=60) $display("vec %0d io_tlb_0_resp_bits_s1_valididx_1 g=%b i=%b", t, g_io_tlb_0_resp_bits_s1_valididx_1, i_io_tlb_0_resp_bits_s1_valididx_1); end
    if (g_io_tlb_0_resp_bits_s1_valididx_2 !== i_io_tlb_0_resp_bits_s1_valididx_2) begin errors++;
      if (errors<=60) $display("vec %0d io_tlb_0_resp_bits_s1_valididx_2 g=%b i=%b", t, g_io_tlb_0_resp_bits_s1_valididx_2, i_io_tlb_0_resp_bits_s1_valididx_2); end
    if (g_io_tlb_0_resp_bits_s1_valididx_3 !== i_io_tlb_0_resp_bits_s1_valididx_3) begin errors++;
      if (errors<=60) $display("vec %0d io_tlb_0_resp_bits_s1_valididx_3 g=%b i=%b", t, g_io_tlb_0_resp_bits_s1_valididx_3, i_io_tlb_0_resp_bits_s1_valididx_3); end
    if (g_io_tlb_0_resp_bits_s1_valididx_4 !== i_io_tlb_0_resp_bits_s1_valididx_4) begin errors++;
      if (errors<=60) $display("vec %0d io_tlb_0_resp_bits_s1_valididx_4 g=%b i=%b", t, g_io_tlb_0_resp_bits_s1_valididx_4, i_io_tlb_0_resp_bits_s1_valididx_4); end
    if (g_io_tlb_0_resp_bits_s1_valididx_5 !== i_io_tlb_0_resp_bits_s1_valididx_5) begin errors++;
      if (errors<=60) $display("vec %0d io_tlb_0_resp_bits_s1_valididx_5 g=%b i=%b", t, g_io_tlb_0_resp_bits_s1_valididx_5, i_io_tlb_0_resp_bits_s1_valididx_5); end
    if (g_io_tlb_0_resp_bits_s1_valididx_6 !== i_io_tlb_0_resp_bits_s1_valididx_6) begin errors++;
      if (errors<=60) $display("vec %0d io_tlb_0_resp_bits_s1_valididx_6 g=%b i=%b", t, g_io_tlb_0_resp_bits_s1_valididx_6, i_io_tlb_0_resp_bits_s1_valididx_6); end
    if (g_io_tlb_0_resp_bits_s1_valididx_7 !== i_io_tlb_0_resp_bits_s1_valididx_7) begin errors++;
      if (errors<=60) $display("vec %0d io_tlb_0_resp_bits_s1_valididx_7 g=%b i=%b", t, g_io_tlb_0_resp_bits_s1_valididx_7, i_io_tlb_0_resp_bits_s1_valididx_7); end
    if (g_io_tlb_0_resp_bits_s1_pteidx_0 !== i_io_tlb_0_resp_bits_s1_pteidx_0) begin errors++;
      if (errors<=60) $display("vec %0d io_tlb_0_resp_bits_s1_pteidx_0 g=%b i=%b", t, g_io_tlb_0_resp_bits_s1_pteidx_0, i_io_tlb_0_resp_bits_s1_pteidx_0); end
    if (g_io_tlb_0_resp_bits_s1_pteidx_1 !== i_io_tlb_0_resp_bits_s1_pteidx_1) begin errors++;
      if (errors<=60) $display("vec %0d io_tlb_0_resp_bits_s1_pteidx_1 g=%b i=%b", t, g_io_tlb_0_resp_bits_s1_pteidx_1, i_io_tlb_0_resp_bits_s1_pteidx_1); end
    if (g_io_tlb_0_resp_bits_s1_pteidx_2 !== i_io_tlb_0_resp_bits_s1_pteidx_2) begin errors++;
      if (errors<=60) $display("vec %0d io_tlb_0_resp_bits_s1_pteidx_2 g=%b i=%b", t, g_io_tlb_0_resp_bits_s1_pteidx_2, i_io_tlb_0_resp_bits_s1_pteidx_2); end
    if (g_io_tlb_0_resp_bits_s1_pteidx_3 !== i_io_tlb_0_resp_bits_s1_pteidx_3) begin errors++;
      if (errors<=60) $display("vec %0d io_tlb_0_resp_bits_s1_pteidx_3 g=%b i=%b", t, g_io_tlb_0_resp_bits_s1_pteidx_3, i_io_tlb_0_resp_bits_s1_pteidx_3); end
    if (g_io_tlb_0_resp_bits_s1_pteidx_4 !== i_io_tlb_0_resp_bits_s1_pteidx_4) begin errors++;
      if (errors<=60) $display("vec %0d io_tlb_0_resp_bits_s1_pteidx_4 g=%b i=%b", t, g_io_tlb_0_resp_bits_s1_pteidx_4, i_io_tlb_0_resp_bits_s1_pteidx_4); end
    if (g_io_tlb_0_resp_bits_s1_pteidx_5 !== i_io_tlb_0_resp_bits_s1_pteidx_5) begin errors++;
      if (errors<=60) $display("vec %0d io_tlb_0_resp_bits_s1_pteidx_5 g=%b i=%b", t, g_io_tlb_0_resp_bits_s1_pteidx_5, i_io_tlb_0_resp_bits_s1_pteidx_5); end
    if (g_io_tlb_0_resp_bits_s1_pteidx_6 !== i_io_tlb_0_resp_bits_s1_pteidx_6) begin errors++;
      if (errors<=60) $display("vec %0d io_tlb_0_resp_bits_s1_pteidx_6 g=%b i=%b", t, g_io_tlb_0_resp_bits_s1_pteidx_6, i_io_tlb_0_resp_bits_s1_pteidx_6); end
    if (g_io_tlb_0_resp_bits_s1_pteidx_7 !== i_io_tlb_0_resp_bits_s1_pteidx_7) begin errors++;
      if (errors<=60) $display("vec %0d io_tlb_0_resp_bits_s1_pteidx_7 g=%b i=%b", t, g_io_tlb_0_resp_bits_s1_pteidx_7, i_io_tlb_0_resp_bits_s1_pteidx_7); end
    if (g_io_tlb_0_resp_bits_s1_pf !== i_io_tlb_0_resp_bits_s1_pf) begin errors++;
      if (errors<=60) $display("vec %0d io_tlb_0_resp_bits_s1_pf g=%b i=%b", t, g_io_tlb_0_resp_bits_s1_pf, i_io_tlb_0_resp_bits_s1_pf); end
    if (g_io_tlb_0_resp_bits_s1_af !== i_io_tlb_0_resp_bits_s1_af) begin errors++;
      if (errors<=60) $display("vec %0d io_tlb_0_resp_bits_s1_af g=%b i=%b", t, g_io_tlb_0_resp_bits_s1_af, i_io_tlb_0_resp_bits_s1_af); end
    if (g_io_tlb_0_resp_bits_s2_entry_tag !== i_io_tlb_0_resp_bits_s2_entry_tag) begin errors++;
      if (errors<=60) $display("vec %0d io_tlb_0_resp_bits_s2_entry_tag g=%h i=%h", t, g_io_tlb_0_resp_bits_s2_entry_tag, i_io_tlb_0_resp_bits_s2_entry_tag); end
    if (g_io_tlb_0_resp_bits_s2_entry_vmid !== i_io_tlb_0_resp_bits_s2_entry_vmid) begin errors++;
      if (errors<=60) $display("vec %0d io_tlb_0_resp_bits_s2_entry_vmid g=%h i=%h", t, g_io_tlb_0_resp_bits_s2_entry_vmid, i_io_tlb_0_resp_bits_s2_entry_vmid); end
    if (g_io_tlb_0_resp_bits_s2_entry_n !== i_io_tlb_0_resp_bits_s2_entry_n) begin errors++;
      if (errors<=60) $display("vec %0d io_tlb_0_resp_bits_s2_entry_n g=%b i=%b", t, g_io_tlb_0_resp_bits_s2_entry_n, i_io_tlb_0_resp_bits_s2_entry_n); end
    if (g_io_tlb_0_resp_bits_s2_entry_pbmt !== i_io_tlb_0_resp_bits_s2_entry_pbmt) begin errors++;
      if (errors<=60) $display("vec %0d io_tlb_0_resp_bits_s2_entry_pbmt g=%h i=%h", t, g_io_tlb_0_resp_bits_s2_entry_pbmt, i_io_tlb_0_resp_bits_s2_entry_pbmt); end
    if (g_io_tlb_0_resp_bits_s2_entry_ppn !== i_io_tlb_0_resp_bits_s2_entry_ppn) begin errors++;
      if (errors<=60) $display("vec %0d io_tlb_0_resp_bits_s2_entry_ppn g=%h i=%h", t, g_io_tlb_0_resp_bits_s2_entry_ppn, i_io_tlb_0_resp_bits_s2_entry_ppn); end
    if (g_io_tlb_0_resp_bits_s2_entry_perm_d !== i_io_tlb_0_resp_bits_s2_entry_perm_d) begin errors++;
      if (errors<=60) $display("vec %0d io_tlb_0_resp_bits_s2_entry_perm_d g=%b i=%b", t, g_io_tlb_0_resp_bits_s2_entry_perm_d, i_io_tlb_0_resp_bits_s2_entry_perm_d); end
    if (g_io_tlb_0_resp_bits_s2_entry_perm_a !== i_io_tlb_0_resp_bits_s2_entry_perm_a) begin errors++;
      if (errors<=60) $display("vec %0d io_tlb_0_resp_bits_s2_entry_perm_a g=%b i=%b", t, g_io_tlb_0_resp_bits_s2_entry_perm_a, i_io_tlb_0_resp_bits_s2_entry_perm_a); end
    if (g_io_tlb_0_resp_bits_s2_entry_perm_g !== i_io_tlb_0_resp_bits_s2_entry_perm_g) begin errors++;
      if (errors<=60) $display("vec %0d io_tlb_0_resp_bits_s2_entry_perm_g g=%b i=%b", t, g_io_tlb_0_resp_bits_s2_entry_perm_g, i_io_tlb_0_resp_bits_s2_entry_perm_g); end
    if (g_io_tlb_0_resp_bits_s2_entry_perm_u !== i_io_tlb_0_resp_bits_s2_entry_perm_u) begin errors++;
      if (errors<=60) $display("vec %0d io_tlb_0_resp_bits_s2_entry_perm_u g=%b i=%b", t, g_io_tlb_0_resp_bits_s2_entry_perm_u, i_io_tlb_0_resp_bits_s2_entry_perm_u); end
    if (g_io_tlb_0_resp_bits_s2_entry_perm_x !== i_io_tlb_0_resp_bits_s2_entry_perm_x) begin errors++;
      if (errors<=60) $display("vec %0d io_tlb_0_resp_bits_s2_entry_perm_x g=%b i=%b", t, g_io_tlb_0_resp_bits_s2_entry_perm_x, i_io_tlb_0_resp_bits_s2_entry_perm_x); end
    if (g_io_tlb_0_resp_bits_s2_entry_perm_w !== i_io_tlb_0_resp_bits_s2_entry_perm_w) begin errors++;
      if (errors<=60) $display("vec %0d io_tlb_0_resp_bits_s2_entry_perm_w g=%b i=%b", t, g_io_tlb_0_resp_bits_s2_entry_perm_w, i_io_tlb_0_resp_bits_s2_entry_perm_w); end
    if (g_io_tlb_0_resp_bits_s2_entry_perm_r !== i_io_tlb_0_resp_bits_s2_entry_perm_r) begin errors++;
      if (errors<=60) $display("vec %0d io_tlb_0_resp_bits_s2_entry_perm_r g=%b i=%b", t, g_io_tlb_0_resp_bits_s2_entry_perm_r, i_io_tlb_0_resp_bits_s2_entry_perm_r); end
    if (g_io_tlb_0_resp_bits_s2_entry_level !== i_io_tlb_0_resp_bits_s2_entry_level) begin errors++;
      if (errors<=60) $display("vec %0d io_tlb_0_resp_bits_s2_entry_level g=%h i=%h", t, g_io_tlb_0_resp_bits_s2_entry_level, i_io_tlb_0_resp_bits_s2_entry_level); end
    if (g_io_tlb_0_resp_bits_s2_gpf !== i_io_tlb_0_resp_bits_s2_gpf) begin errors++;
      if (errors<=60) $display("vec %0d io_tlb_0_resp_bits_s2_gpf g=%b i=%b", t, g_io_tlb_0_resp_bits_s2_gpf, i_io_tlb_0_resp_bits_s2_gpf); end
    if (g_io_tlb_0_resp_bits_s2_gaf !== i_io_tlb_0_resp_bits_s2_gaf) begin errors++;
      if (errors<=60) $display("vec %0d io_tlb_0_resp_bits_s2_gaf g=%b i=%b", t, g_io_tlb_0_resp_bits_s2_gaf, i_io_tlb_0_resp_bits_s2_gaf); end
    if (g_io_tlb_1_req_0_ready !== i_io_tlb_1_req_0_ready) begin errors++;
      if (errors<=60) $display("vec %0d io_tlb_1_req_0_ready g=%b i=%b", t, g_io_tlb_1_req_0_ready, i_io_tlb_1_req_0_ready); end
    if (g_io_tlb_1_resp_valid !== i_io_tlb_1_resp_valid) begin errors++;
      if (errors<=60) $display("vec %0d io_tlb_1_resp_valid g=%b i=%b", t, g_io_tlb_1_resp_valid, i_io_tlb_1_resp_valid); end
    if (g_io_tlb_1_resp_bits_s2xlate !== i_io_tlb_1_resp_bits_s2xlate) begin errors++;
      if (errors<=60) $display("vec %0d io_tlb_1_resp_bits_s2xlate g=%h i=%h", t, g_io_tlb_1_resp_bits_s2xlate, i_io_tlb_1_resp_bits_s2xlate); end
    if (g_io_tlb_1_resp_bits_s1_entry_tag !== i_io_tlb_1_resp_bits_s1_entry_tag) begin errors++;
      if (errors<=60) $display("vec %0d io_tlb_1_resp_bits_s1_entry_tag g=%h i=%h", t, g_io_tlb_1_resp_bits_s1_entry_tag, i_io_tlb_1_resp_bits_s1_entry_tag); end
    if (g_io_tlb_1_resp_bits_s1_entry_asid !== i_io_tlb_1_resp_bits_s1_entry_asid) begin errors++;
      if (errors<=60) $display("vec %0d io_tlb_1_resp_bits_s1_entry_asid g=%h i=%h", t, g_io_tlb_1_resp_bits_s1_entry_asid, i_io_tlb_1_resp_bits_s1_entry_asid); end
    if (g_io_tlb_1_resp_bits_s1_entry_vmid !== i_io_tlb_1_resp_bits_s1_entry_vmid) begin errors++;
      if (errors<=60) $display("vec %0d io_tlb_1_resp_bits_s1_entry_vmid g=%h i=%h", t, g_io_tlb_1_resp_bits_s1_entry_vmid, i_io_tlb_1_resp_bits_s1_entry_vmid); end
    if (g_io_tlb_1_resp_bits_s1_entry_n !== i_io_tlb_1_resp_bits_s1_entry_n) begin errors++;
      if (errors<=60) $display("vec %0d io_tlb_1_resp_bits_s1_entry_n g=%b i=%b", t, g_io_tlb_1_resp_bits_s1_entry_n, i_io_tlb_1_resp_bits_s1_entry_n); end
    if (g_io_tlb_1_resp_bits_s1_entry_pbmt !== i_io_tlb_1_resp_bits_s1_entry_pbmt) begin errors++;
      if (errors<=60) $display("vec %0d io_tlb_1_resp_bits_s1_entry_pbmt g=%h i=%h", t, g_io_tlb_1_resp_bits_s1_entry_pbmt, i_io_tlb_1_resp_bits_s1_entry_pbmt); end
    if (g_io_tlb_1_resp_bits_s1_entry_perm_d !== i_io_tlb_1_resp_bits_s1_entry_perm_d) begin errors++;
      if (errors<=60) $display("vec %0d io_tlb_1_resp_bits_s1_entry_perm_d g=%b i=%b", t, g_io_tlb_1_resp_bits_s1_entry_perm_d, i_io_tlb_1_resp_bits_s1_entry_perm_d); end
    if (g_io_tlb_1_resp_bits_s1_entry_perm_a !== i_io_tlb_1_resp_bits_s1_entry_perm_a) begin errors++;
      if (errors<=60) $display("vec %0d io_tlb_1_resp_bits_s1_entry_perm_a g=%b i=%b", t, g_io_tlb_1_resp_bits_s1_entry_perm_a, i_io_tlb_1_resp_bits_s1_entry_perm_a); end
    if (g_io_tlb_1_resp_bits_s1_entry_perm_g !== i_io_tlb_1_resp_bits_s1_entry_perm_g) begin errors++;
      if (errors<=60) $display("vec %0d io_tlb_1_resp_bits_s1_entry_perm_g g=%b i=%b", t, g_io_tlb_1_resp_bits_s1_entry_perm_g, i_io_tlb_1_resp_bits_s1_entry_perm_g); end
    if (g_io_tlb_1_resp_bits_s1_entry_perm_u !== i_io_tlb_1_resp_bits_s1_entry_perm_u) begin errors++;
      if (errors<=60) $display("vec %0d io_tlb_1_resp_bits_s1_entry_perm_u g=%b i=%b", t, g_io_tlb_1_resp_bits_s1_entry_perm_u, i_io_tlb_1_resp_bits_s1_entry_perm_u); end
    if (g_io_tlb_1_resp_bits_s1_entry_perm_x !== i_io_tlb_1_resp_bits_s1_entry_perm_x) begin errors++;
      if (errors<=60) $display("vec %0d io_tlb_1_resp_bits_s1_entry_perm_x g=%b i=%b", t, g_io_tlb_1_resp_bits_s1_entry_perm_x, i_io_tlb_1_resp_bits_s1_entry_perm_x); end
    if (g_io_tlb_1_resp_bits_s1_entry_perm_w !== i_io_tlb_1_resp_bits_s1_entry_perm_w) begin errors++;
      if (errors<=60) $display("vec %0d io_tlb_1_resp_bits_s1_entry_perm_w g=%b i=%b", t, g_io_tlb_1_resp_bits_s1_entry_perm_w, i_io_tlb_1_resp_bits_s1_entry_perm_w); end
    if (g_io_tlb_1_resp_bits_s1_entry_perm_r !== i_io_tlb_1_resp_bits_s1_entry_perm_r) begin errors++;
      if (errors<=60) $display("vec %0d io_tlb_1_resp_bits_s1_entry_perm_r g=%b i=%b", t, g_io_tlb_1_resp_bits_s1_entry_perm_r, i_io_tlb_1_resp_bits_s1_entry_perm_r); end
    if (g_io_tlb_1_resp_bits_s1_entry_level !== i_io_tlb_1_resp_bits_s1_entry_level) begin errors++;
      if (errors<=60) $display("vec %0d io_tlb_1_resp_bits_s1_entry_level g=%h i=%h", t, g_io_tlb_1_resp_bits_s1_entry_level, i_io_tlb_1_resp_bits_s1_entry_level); end
    if (g_io_tlb_1_resp_bits_s1_entry_v !== i_io_tlb_1_resp_bits_s1_entry_v) begin errors++;
      if (errors<=60) $display("vec %0d io_tlb_1_resp_bits_s1_entry_v g=%b i=%b", t, g_io_tlb_1_resp_bits_s1_entry_v, i_io_tlb_1_resp_bits_s1_entry_v); end
    if (g_io_tlb_1_resp_bits_s1_entry_ppn !== i_io_tlb_1_resp_bits_s1_entry_ppn) begin errors++;
      if (errors<=60) $display("vec %0d io_tlb_1_resp_bits_s1_entry_ppn g=%h i=%h", t, g_io_tlb_1_resp_bits_s1_entry_ppn, i_io_tlb_1_resp_bits_s1_entry_ppn); end
    if (g_io_tlb_1_resp_bits_s1_addr_low !== i_io_tlb_1_resp_bits_s1_addr_low) begin errors++;
      if (errors<=60) $display("vec %0d io_tlb_1_resp_bits_s1_addr_low g=%h i=%h", t, g_io_tlb_1_resp_bits_s1_addr_low, i_io_tlb_1_resp_bits_s1_addr_low); end
    if (g_io_tlb_1_resp_bits_s1_ppn_low_0 !== i_io_tlb_1_resp_bits_s1_ppn_low_0) begin errors++;
      if (errors<=60) $display("vec %0d io_tlb_1_resp_bits_s1_ppn_low_0 g=%h i=%h", t, g_io_tlb_1_resp_bits_s1_ppn_low_0, i_io_tlb_1_resp_bits_s1_ppn_low_0); end
    if (g_io_tlb_1_resp_bits_s1_ppn_low_1 !== i_io_tlb_1_resp_bits_s1_ppn_low_1) begin errors++;
      if (errors<=60) $display("vec %0d io_tlb_1_resp_bits_s1_ppn_low_1 g=%h i=%h", t, g_io_tlb_1_resp_bits_s1_ppn_low_1, i_io_tlb_1_resp_bits_s1_ppn_low_1); end
    if (g_io_tlb_1_resp_bits_s1_ppn_low_2 !== i_io_tlb_1_resp_bits_s1_ppn_low_2) begin errors++;
      if (errors<=60) $display("vec %0d io_tlb_1_resp_bits_s1_ppn_low_2 g=%h i=%h", t, g_io_tlb_1_resp_bits_s1_ppn_low_2, i_io_tlb_1_resp_bits_s1_ppn_low_2); end
    if (g_io_tlb_1_resp_bits_s1_ppn_low_3 !== i_io_tlb_1_resp_bits_s1_ppn_low_3) begin errors++;
      if (errors<=60) $display("vec %0d io_tlb_1_resp_bits_s1_ppn_low_3 g=%h i=%h", t, g_io_tlb_1_resp_bits_s1_ppn_low_3, i_io_tlb_1_resp_bits_s1_ppn_low_3); end
    if (g_io_tlb_1_resp_bits_s1_ppn_low_4 !== i_io_tlb_1_resp_bits_s1_ppn_low_4) begin errors++;
      if (errors<=60) $display("vec %0d io_tlb_1_resp_bits_s1_ppn_low_4 g=%h i=%h", t, g_io_tlb_1_resp_bits_s1_ppn_low_4, i_io_tlb_1_resp_bits_s1_ppn_low_4); end
    if (g_io_tlb_1_resp_bits_s1_ppn_low_5 !== i_io_tlb_1_resp_bits_s1_ppn_low_5) begin errors++;
      if (errors<=60) $display("vec %0d io_tlb_1_resp_bits_s1_ppn_low_5 g=%h i=%h", t, g_io_tlb_1_resp_bits_s1_ppn_low_5, i_io_tlb_1_resp_bits_s1_ppn_low_5); end
    if (g_io_tlb_1_resp_bits_s1_ppn_low_6 !== i_io_tlb_1_resp_bits_s1_ppn_low_6) begin errors++;
      if (errors<=60) $display("vec %0d io_tlb_1_resp_bits_s1_ppn_low_6 g=%h i=%h", t, g_io_tlb_1_resp_bits_s1_ppn_low_6, i_io_tlb_1_resp_bits_s1_ppn_low_6); end
    if (g_io_tlb_1_resp_bits_s1_ppn_low_7 !== i_io_tlb_1_resp_bits_s1_ppn_low_7) begin errors++;
      if (errors<=60) $display("vec %0d io_tlb_1_resp_bits_s1_ppn_low_7 g=%h i=%h", t, g_io_tlb_1_resp_bits_s1_ppn_low_7, i_io_tlb_1_resp_bits_s1_ppn_low_7); end
    if (g_io_tlb_1_resp_bits_s1_valididx_0 !== i_io_tlb_1_resp_bits_s1_valididx_0) begin errors++;
      if (errors<=60) $display("vec %0d io_tlb_1_resp_bits_s1_valididx_0 g=%b i=%b", t, g_io_tlb_1_resp_bits_s1_valididx_0, i_io_tlb_1_resp_bits_s1_valididx_0); end
    if (g_io_tlb_1_resp_bits_s1_valididx_1 !== i_io_tlb_1_resp_bits_s1_valididx_1) begin errors++;
      if (errors<=60) $display("vec %0d io_tlb_1_resp_bits_s1_valididx_1 g=%b i=%b", t, g_io_tlb_1_resp_bits_s1_valididx_1, i_io_tlb_1_resp_bits_s1_valididx_1); end
    if (g_io_tlb_1_resp_bits_s1_valididx_2 !== i_io_tlb_1_resp_bits_s1_valididx_2) begin errors++;
      if (errors<=60) $display("vec %0d io_tlb_1_resp_bits_s1_valididx_2 g=%b i=%b", t, g_io_tlb_1_resp_bits_s1_valididx_2, i_io_tlb_1_resp_bits_s1_valididx_2); end
    if (g_io_tlb_1_resp_bits_s1_valididx_3 !== i_io_tlb_1_resp_bits_s1_valididx_3) begin errors++;
      if (errors<=60) $display("vec %0d io_tlb_1_resp_bits_s1_valididx_3 g=%b i=%b", t, g_io_tlb_1_resp_bits_s1_valididx_3, i_io_tlb_1_resp_bits_s1_valididx_3); end
    if (g_io_tlb_1_resp_bits_s1_valididx_4 !== i_io_tlb_1_resp_bits_s1_valididx_4) begin errors++;
      if (errors<=60) $display("vec %0d io_tlb_1_resp_bits_s1_valididx_4 g=%b i=%b", t, g_io_tlb_1_resp_bits_s1_valididx_4, i_io_tlb_1_resp_bits_s1_valididx_4); end
    if (g_io_tlb_1_resp_bits_s1_valididx_5 !== i_io_tlb_1_resp_bits_s1_valididx_5) begin errors++;
      if (errors<=60) $display("vec %0d io_tlb_1_resp_bits_s1_valididx_5 g=%b i=%b", t, g_io_tlb_1_resp_bits_s1_valididx_5, i_io_tlb_1_resp_bits_s1_valididx_5); end
    if (g_io_tlb_1_resp_bits_s1_valididx_6 !== i_io_tlb_1_resp_bits_s1_valididx_6) begin errors++;
      if (errors<=60) $display("vec %0d io_tlb_1_resp_bits_s1_valididx_6 g=%b i=%b", t, g_io_tlb_1_resp_bits_s1_valididx_6, i_io_tlb_1_resp_bits_s1_valididx_6); end
    if (g_io_tlb_1_resp_bits_s1_valididx_7 !== i_io_tlb_1_resp_bits_s1_valididx_7) begin errors++;
      if (errors<=60) $display("vec %0d io_tlb_1_resp_bits_s1_valididx_7 g=%b i=%b", t, g_io_tlb_1_resp_bits_s1_valididx_7, i_io_tlb_1_resp_bits_s1_valididx_7); end
    if (g_io_tlb_1_resp_bits_s1_pteidx_0 !== i_io_tlb_1_resp_bits_s1_pteidx_0) begin errors++;
      if (errors<=60) $display("vec %0d io_tlb_1_resp_bits_s1_pteidx_0 g=%b i=%b", t, g_io_tlb_1_resp_bits_s1_pteidx_0, i_io_tlb_1_resp_bits_s1_pteidx_0); end
    if (g_io_tlb_1_resp_bits_s1_pteidx_1 !== i_io_tlb_1_resp_bits_s1_pteidx_1) begin errors++;
      if (errors<=60) $display("vec %0d io_tlb_1_resp_bits_s1_pteidx_1 g=%b i=%b", t, g_io_tlb_1_resp_bits_s1_pteidx_1, i_io_tlb_1_resp_bits_s1_pteidx_1); end
    if (g_io_tlb_1_resp_bits_s1_pteidx_2 !== i_io_tlb_1_resp_bits_s1_pteidx_2) begin errors++;
      if (errors<=60) $display("vec %0d io_tlb_1_resp_bits_s1_pteidx_2 g=%b i=%b", t, g_io_tlb_1_resp_bits_s1_pteidx_2, i_io_tlb_1_resp_bits_s1_pteidx_2); end
    if (g_io_tlb_1_resp_bits_s1_pteidx_3 !== i_io_tlb_1_resp_bits_s1_pteidx_3) begin errors++;
      if (errors<=60) $display("vec %0d io_tlb_1_resp_bits_s1_pteidx_3 g=%b i=%b", t, g_io_tlb_1_resp_bits_s1_pteidx_3, i_io_tlb_1_resp_bits_s1_pteidx_3); end
    if (g_io_tlb_1_resp_bits_s1_pteidx_4 !== i_io_tlb_1_resp_bits_s1_pteidx_4) begin errors++;
      if (errors<=60) $display("vec %0d io_tlb_1_resp_bits_s1_pteidx_4 g=%b i=%b", t, g_io_tlb_1_resp_bits_s1_pteidx_4, i_io_tlb_1_resp_bits_s1_pteidx_4); end
    if (g_io_tlb_1_resp_bits_s1_pteidx_5 !== i_io_tlb_1_resp_bits_s1_pteidx_5) begin errors++;
      if (errors<=60) $display("vec %0d io_tlb_1_resp_bits_s1_pteidx_5 g=%b i=%b", t, g_io_tlb_1_resp_bits_s1_pteidx_5, i_io_tlb_1_resp_bits_s1_pteidx_5); end
    if (g_io_tlb_1_resp_bits_s1_pteidx_6 !== i_io_tlb_1_resp_bits_s1_pteidx_6) begin errors++;
      if (errors<=60) $display("vec %0d io_tlb_1_resp_bits_s1_pteidx_6 g=%b i=%b", t, g_io_tlb_1_resp_bits_s1_pteidx_6, i_io_tlb_1_resp_bits_s1_pteidx_6); end
    if (g_io_tlb_1_resp_bits_s1_pteidx_7 !== i_io_tlb_1_resp_bits_s1_pteidx_7) begin errors++;
      if (errors<=60) $display("vec %0d io_tlb_1_resp_bits_s1_pteidx_7 g=%b i=%b", t, g_io_tlb_1_resp_bits_s1_pteidx_7, i_io_tlb_1_resp_bits_s1_pteidx_7); end
    if (g_io_tlb_1_resp_bits_s1_pf !== i_io_tlb_1_resp_bits_s1_pf) begin errors++;
      if (errors<=60) $display("vec %0d io_tlb_1_resp_bits_s1_pf g=%b i=%b", t, g_io_tlb_1_resp_bits_s1_pf, i_io_tlb_1_resp_bits_s1_pf); end
    if (g_io_tlb_1_resp_bits_s1_af !== i_io_tlb_1_resp_bits_s1_af) begin errors++;
      if (errors<=60) $display("vec %0d io_tlb_1_resp_bits_s1_af g=%b i=%b", t, g_io_tlb_1_resp_bits_s1_af, i_io_tlb_1_resp_bits_s1_af); end
    if (g_io_tlb_1_resp_bits_s2_entry_tag !== i_io_tlb_1_resp_bits_s2_entry_tag) begin errors++;
      if (errors<=60) $display("vec %0d io_tlb_1_resp_bits_s2_entry_tag g=%h i=%h", t, g_io_tlb_1_resp_bits_s2_entry_tag, i_io_tlb_1_resp_bits_s2_entry_tag); end
    if (g_io_tlb_1_resp_bits_s2_entry_vmid !== i_io_tlb_1_resp_bits_s2_entry_vmid) begin errors++;
      if (errors<=60) $display("vec %0d io_tlb_1_resp_bits_s2_entry_vmid g=%h i=%h", t, g_io_tlb_1_resp_bits_s2_entry_vmid, i_io_tlb_1_resp_bits_s2_entry_vmid); end
    if (g_io_tlb_1_resp_bits_s2_entry_n !== i_io_tlb_1_resp_bits_s2_entry_n) begin errors++;
      if (errors<=60) $display("vec %0d io_tlb_1_resp_bits_s2_entry_n g=%b i=%b", t, g_io_tlb_1_resp_bits_s2_entry_n, i_io_tlb_1_resp_bits_s2_entry_n); end
    if (g_io_tlb_1_resp_bits_s2_entry_pbmt !== i_io_tlb_1_resp_bits_s2_entry_pbmt) begin errors++;
      if (errors<=60) $display("vec %0d io_tlb_1_resp_bits_s2_entry_pbmt g=%h i=%h", t, g_io_tlb_1_resp_bits_s2_entry_pbmt, i_io_tlb_1_resp_bits_s2_entry_pbmt); end
    if (g_io_tlb_1_resp_bits_s2_entry_ppn !== i_io_tlb_1_resp_bits_s2_entry_ppn) begin errors++;
      if (errors<=60) $display("vec %0d io_tlb_1_resp_bits_s2_entry_ppn g=%h i=%h", t, g_io_tlb_1_resp_bits_s2_entry_ppn, i_io_tlb_1_resp_bits_s2_entry_ppn); end
    if (g_io_tlb_1_resp_bits_s2_entry_perm_d !== i_io_tlb_1_resp_bits_s2_entry_perm_d) begin errors++;
      if (errors<=60) $display("vec %0d io_tlb_1_resp_bits_s2_entry_perm_d g=%b i=%b", t, g_io_tlb_1_resp_bits_s2_entry_perm_d, i_io_tlb_1_resp_bits_s2_entry_perm_d); end
    if (g_io_tlb_1_resp_bits_s2_entry_perm_a !== i_io_tlb_1_resp_bits_s2_entry_perm_a) begin errors++;
      if (errors<=60) $display("vec %0d io_tlb_1_resp_bits_s2_entry_perm_a g=%b i=%b", t, g_io_tlb_1_resp_bits_s2_entry_perm_a, i_io_tlb_1_resp_bits_s2_entry_perm_a); end
    if (g_io_tlb_1_resp_bits_s2_entry_perm_g !== i_io_tlb_1_resp_bits_s2_entry_perm_g) begin errors++;
      if (errors<=60) $display("vec %0d io_tlb_1_resp_bits_s2_entry_perm_g g=%b i=%b", t, g_io_tlb_1_resp_bits_s2_entry_perm_g, i_io_tlb_1_resp_bits_s2_entry_perm_g); end
    if (g_io_tlb_1_resp_bits_s2_entry_perm_u !== i_io_tlb_1_resp_bits_s2_entry_perm_u) begin errors++;
      if (errors<=60) $display("vec %0d io_tlb_1_resp_bits_s2_entry_perm_u g=%b i=%b", t, g_io_tlb_1_resp_bits_s2_entry_perm_u, i_io_tlb_1_resp_bits_s2_entry_perm_u); end
    if (g_io_tlb_1_resp_bits_s2_entry_perm_x !== i_io_tlb_1_resp_bits_s2_entry_perm_x) begin errors++;
      if (errors<=60) $display("vec %0d io_tlb_1_resp_bits_s2_entry_perm_x g=%b i=%b", t, g_io_tlb_1_resp_bits_s2_entry_perm_x, i_io_tlb_1_resp_bits_s2_entry_perm_x); end
    if (g_io_tlb_1_resp_bits_s2_entry_perm_w !== i_io_tlb_1_resp_bits_s2_entry_perm_w) begin errors++;
      if (errors<=60) $display("vec %0d io_tlb_1_resp_bits_s2_entry_perm_w g=%b i=%b", t, g_io_tlb_1_resp_bits_s2_entry_perm_w, i_io_tlb_1_resp_bits_s2_entry_perm_w); end
    if (g_io_tlb_1_resp_bits_s2_entry_perm_r !== i_io_tlb_1_resp_bits_s2_entry_perm_r) begin errors++;
      if (errors<=60) $display("vec %0d io_tlb_1_resp_bits_s2_entry_perm_r g=%b i=%b", t, g_io_tlb_1_resp_bits_s2_entry_perm_r, i_io_tlb_1_resp_bits_s2_entry_perm_r); end
    if (g_io_tlb_1_resp_bits_s2_entry_level !== i_io_tlb_1_resp_bits_s2_entry_level) begin errors++;
      if (errors<=60) $display("vec %0d io_tlb_1_resp_bits_s2_entry_level g=%h i=%h", t, g_io_tlb_1_resp_bits_s2_entry_level, i_io_tlb_1_resp_bits_s2_entry_level); end
    if (g_io_tlb_1_resp_bits_s2_gpf !== i_io_tlb_1_resp_bits_s2_gpf) begin errors++;
      if (errors<=60) $display("vec %0d io_tlb_1_resp_bits_s2_gpf g=%b i=%b", t, g_io_tlb_1_resp_bits_s2_gpf, i_io_tlb_1_resp_bits_s2_gpf); end
    if (g_io_tlb_1_resp_bits_s2_gaf !== i_io_tlb_1_resp_bits_s2_gaf) begin errors++;
      if (errors<=60) $display("vec %0d io_tlb_1_resp_bits_s2_gaf g=%b i=%b", t, g_io_tlb_1_resp_bits_s2_gaf, i_io_tlb_1_resp_bits_s2_gaf); end
    if (g_io_wfi_wfiSafe !== i_io_wfi_wfiSafe) begin errors++;
      if (errors<=60) $display("vec %0d io_wfi_wfiSafe g=%b i=%b", t, g_io_wfi_wfiSafe, i_io_wfi_wfiSafe); end
    if (g_io_perf_0_value !== i_io_perf_0_value) begin errors++;
      if (errors<=60) $display("vec %0d io_perf_0_value g=%h i=%h", t, g_io_perf_0_value, i_io_perf_0_value); end
    if (g_io_perf_1_value !== i_io_perf_1_value) begin errors++;
      if (errors<=60) $display("vec %0d io_perf_1_value g=%h i=%h", t, g_io_perf_1_value, i_io_perf_1_value); end
    if (g_io_perf_2_value !== i_io_perf_2_value) begin errors++;
      if (errors<=60) $display("vec %0d io_perf_2_value g=%h i=%h", t, g_io_perf_2_value, i_io_perf_2_value); end
    if (g_io_perf_3_value !== i_io_perf_3_value) begin errors++;
      if (errors<=60) $display("vec %0d io_perf_3_value g=%h i=%h", t, g_io_perf_3_value, i_io_perf_3_value); end
    if (g_io_perf_4_value !== i_io_perf_4_value) begin errors++;
      if (errors<=60) $display("vec %0d io_perf_4_value g=%h i=%h", t, g_io_perf_4_value, i_io_perf_4_value); end
    if (g_io_perf_5_value !== i_io_perf_5_value) begin errors++;
      if (errors<=60) $display("vec %0d io_perf_5_value g=%h i=%h", t, g_io_perf_5_value, i_io_perf_5_value); end
    if (g_io_perf_6_value !== i_io_perf_6_value) begin errors++;
      if (errors<=60) $display("vec %0d io_perf_6_value g=%h i=%h", t, g_io_perf_6_value, i_io_perf_6_value); end
    if (g_io_perf_7_value !== i_io_perf_7_value) begin errors++;
      if (errors<=60) $display("vec %0d io_perf_7_value g=%h i=%h", t, g_io_perf_7_value, i_io_perf_7_value); end
    if (g_io_perf_8_value !== i_io_perf_8_value) begin errors++;
      if (errors<=60) $display("vec %0d io_perf_8_value g=%h i=%h", t, g_io_perf_8_value, i_io_perf_8_value); end
    if (g_io_perf_9_value !== i_io_perf_9_value) begin errors++;
      if (errors<=60) $display("vec %0d io_perf_9_value g=%h i=%h", t, g_io_perf_9_value, i_io_perf_9_value); end
    if (g_io_perf_10_value !== i_io_perf_10_value) begin errors++;
      if (errors<=60) $display("vec %0d io_perf_10_value g=%h i=%h", t, g_io_perf_10_value, i_io_perf_10_value); end
    if (g_io_perf_11_value !== i_io_perf_11_value) begin errors++;
      if (errors<=60) $display("vec %0d io_perf_11_value g=%h i=%h", t, g_io_perf_11_value, i_io_perf_11_value); end
    if (g_io_perf_12_value !== i_io_perf_12_value) begin errors++;
      if (errors<=60) $display("vec %0d io_perf_12_value g=%h i=%h", t, g_io_perf_12_value, i_io_perf_12_value); end
    if (g_io_perf_13_value !== i_io_perf_13_value) begin errors++;
      if (errors<=60) $display("vec %0d io_perf_13_value g=%h i=%h", t, g_io_perf_13_value, i_io_perf_13_value); end
    if (g_io_perf_14_value !== i_io_perf_14_value) begin errors++;
      if (errors<=60) $display("vec %0d io_perf_14_value g=%h i=%h", t, g_io_perf_14_value, i_io_perf_14_value); end
    if (g_io_perf_15_value !== i_io_perf_15_value) begin errors++;
      if (errors<=60) $display("vec %0d io_perf_15_value g=%h i=%h", t, g_io_perf_15_value, i_io_perf_15_value); end
    if (g_io_perf_16_value !== i_io_perf_16_value) begin errors++;
      if (errors<=60) $display("vec %0d io_perf_16_value g=%h i=%h", t, g_io_perf_16_value, i_io_perf_16_value); end
    if (g_io_perf_17_value !== i_io_perf_17_value) begin errors++;
      if (errors<=60) $display("vec %0d io_perf_17_value g=%h i=%h", t, g_io_perf_17_value, i_io_perf_17_value); end
    if (g_io_perf_18_value !== i_io_perf_18_value) begin errors++;
      if (errors<=60) $display("vec %0d io_perf_18_value g=%h i=%h", t, g_io_perf_18_value, i_io_perf_18_value); end
    if (g_boreChildrenBd_bore_ack !== i_boreChildrenBd_bore_ack) begin errors++;
      if (errors<=60) $display("vec %0d boreChildrenBd_bore_ack g=%b i=%b", t, g_boreChildrenBd_bore_ack, i_boreChildrenBd_bore_ack); end
    if (g_boreChildrenBd_bore_outdata !== i_boreChildrenBd_bore_outdata) begin errors++;
      if (errors<=60) $display("vec %0d boreChildrenBd_bore_outdata g=%h i=%h", t, g_boreChildrenBd_bore_outdata, i_boreChildrenBd_bore_outdata); end
    if (g_boreChildrenBd_bore_1_ack !== i_boreChildrenBd_bore_1_ack) begin errors++;
      if (errors<=60) $display("vec %0d boreChildrenBd_bore_1_ack g=%b i=%b", t, g_boreChildrenBd_bore_1_ack, i_boreChildrenBd_bore_1_ack); end
    if (g_boreChildrenBd_bore_1_outdata !== i_boreChildrenBd_bore_1_outdata) begin errors++;
      if (errors<=60) $display("vec %0d boreChildrenBd_bore_1_outdata g=%h i=%h", t, g_boreChildrenBd_bore_1_outdata, i_boreChildrenBd_bore_1_outdata); end
    if (g_boreChildrenBd_bore_2_ack !== i_boreChildrenBd_bore_2_ack) begin errors++;
      if (errors<=60) $display("vec %0d boreChildrenBd_bore_2_ack g=%b i=%b", t, g_boreChildrenBd_bore_2_ack, i_boreChildrenBd_bore_2_ack); end
    if (g_boreChildrenBd_bore_2_outdata !== i_boreChildrenBd_bore_2_outdata) begin errors++;
      if (errors<=60) $display("vec %0d boreChildrenBd_bore_2_outdata g=%h i=%h", t, g_boreChildrenBd_bore_2_outdata, i_boreChildrenBd_bore_2_outdata); end
    if (g_gatewayIn_packed_43_bore !== i_gatewayIn_packed_43_bore) begin errors++;
      if (errors<=60) $display("vec %0d gatewayIn_packed_43_bore g=%h i=%h", t, g_gatewayIn_packed_43_bore, i_gatewayIn_packed_43_bore); end
    if (g_gatewayIn_packed_44_bore !== i_gatewayIn_packed_44_bore) begin errors++;
      if (errors<=60) $display("vec %0d gatewayIn_packed_44_bore g=%h i=%h", t, g_gatewayIn_packed_44_bore, i_gatewayIn_packed_44_bore); end
    if (g_gatewayIn_packed_45_bore !== i_gatewayIn_packed_45_bore) begin errors++;
      if (errors<=60) $display("vec %0d gatewayIn_packed_45_bore g=%h i=%h", t, g_gatewayIn_packed_45_bore, i_gatewayIn_packed_45_bore); end
  endtask

  // DFT/MBIST 输入：功能模式恒 0（见文件头说明）。
  task automatic drive_dft_zero();
    boreChildrenBd_bore_array = '0;
    boreChildrenBd_bore_all = '0;
    boreChildrenBd_bore_req = '0;
    boreChildrenBd_bore_writeen = '0;
    boreChildrenBd_bore_be = '0;
    boreChildrenBd_bore_addr = '0;
    boreChildrenBd_bore_indata = '0;
    boreChildrenBd_bore_readen = '0;
    boreChildrenBd_bore_addr_rd = '0;
    boreChildrenBd_bore_1_array = '0;
    boreChildrenBd_bore_1_all = '0;
    boreChildrenBd_bore_1_req = '0;
    boreChildrenBd_bore_1_writeen = '0;
    boreChildrenBd_bore_1_be = '0;
    boreChildrenBd_bore_1_addr = '0;
    boreChildrenBd_bore_1_indata = '0;
    boreChildrenBd_bore_1_readen = '0;
    boreChildrenBd_bore_1_addr_rd = '0;
    boreChildrenBd_bore_2_array = '0;
    boreChildrenBd_bore_2_all = '0;
    boreChildrenBd_bore_2_req = '0;
    boreChildrenBd_bore_2_writeen = '0;
    boreChildrenBd_bore_2_be = '0;
    boreChildrenBd_bore_2_addr = '0;
    boreChildrenBd_bore_2_indata = '0;
    boreChildrenBd_bore_2_readen = '0;
    boreChildrenBd_bore_2_addr_rd = '0;
    sigFromSrams_bore_ram_hold = '0;
    sigFromSrams_bore_ram_bypass = '0;
    sigFromSrams_bore_ram_bp_clken = '0;
    sigFromSrams_bore_ram_aux_clk = '0;
    sigFromSrams_bore_ram_aux_ckbp = '0;
    sigFromSrams_bore_ram_mcp_hold = '0;
    sigFromSrams_bore_cgen = '0;
    sigFromSrams_bore_1_ram_hold = '0;
    sigFromSrams_bore_1_ram_bypass = '0;
    sigFromSrams_bore_1_ram_bp_clken = '0;
    sigFromSrams_bore_1_ram_aux_clk = '0;
    sigFromSrams_bore_1_ram_aux_ckbp = '0;
    sigFromSrams_bore_1_ram_mcp_hold = '0;
    sigFromSrams_bore_1_cgen = '0;
    sigFromSrams_bore_2_ram_hold = '0;
    sigFromSrams_bore_2_ram_bypass = '0;
    sigFromSrams_bore_2_ram_bp_clken = '0;
    sigFromSrams_bore_2_ram_aux_clk = '0;
    sigFromSrams_bore_2_ram_aux_ckbp = '0;
    sigFromSrams_bore_2_ram_mcp_hold = '0;
    sigFromSrams_bore_2_cgen = '0;
    sigFromSrams_bore_3_ram_hold = '0;
    sigFromSrams_bore_3_ram_bypass = '0;
    sigFromSrams_bore_3_ram_bp_clken = '0;
    sigFromSrams_bore_3_ram_aux_clk = '0;
    sigFromSrams_bore_3_ram_aux_ckbp = '0;
    sigFromSrams_bore_3_ram_mcp_hold = '0;
    sigFromSrams_bore_3_cgen = '0;
    sigFromSrams_bore_4_ram_hold = '0;
    sigFromSrams_bore_4_ram_bypass = '0;
    sigFromSrams_bore_4_ram_bp_clken = '0;
    sigFromSrams_bore_4_ram_aux_clk = '0;
    sigFromSrams_bore_4_ram_aux_ckbp = '0;
    sigFromSrams_bore_4_ram_mcp_hold = '0;
    sigFromSrams_bore_4_cgen = '0;
    sigFromSrams_bore_5_ram_hold = '0;
    sigFromSrams_bore_5_ram_bypass = '0;
    sigFromSrams_bore_5_ram_bp_clken = '0;
    sigFromSrams_bore_5_ram_aux_clk = '0;
    sigFromSrams_bore_5_ram_aux_ckbp = '0;
    sigFromSrams_bore_5_ram_mcp_hold = '0;
    sigFromSrams_bore_5_cgen = '0;
    sigFromSrams_bore_6_ram_hold = '0;
    sigFromSrams_bore_6_ram_bypass = '0;
    sigFromSrams_bore_6_ram_bp_clken = '0;
    sigFromSrams_bore_6_ram_aux_clk = '0;
    sigFromSrams_bore_6_ram_aux_ckbp = '0;
    sigFromSrams_bore_6_ram_mcp_hold = '0;
    sigFromSrams_bore_6_cgen = '0;
    sigFromSrams_bore_7_ram_hold = '0;
    sigFromSrams_bore_7_ram_bypass = '0;
    sigFromSrams_bore_7_ram_bp_clken = '0;
    sigFromSrams_bore_7_ram_aux_clk = '0;
    sigFromSrams_bore_7_ram_aux_ckbp = '0;
    sigFromSrams_bore_7_ram_mcp_hold = '0;
    sigFromSrams_bore_7_cgen = '0;
    sigFromSrams_bore_8_ram_hold = '0;
    sigFromSrams_bore_8_ram_bypass = '0;
    sigFromSrams_bore_8_ram_bp_clken = '0;
    sigFromSrams_bore_8_ram_aux_clk = '0;
    sigFromSrams_bore_8_ram_aux_ckbp = '0;
    sigFromSrams_bore_8_ram_mcp_hold = '0;
    sigFromSrams_bore_8_cgen = '0;
    sigFromSrams_bore_9_ram_hold = '0;
    sigFromSrams_bore_9_ram_bypass = '0;
    sigFromSrams_bore_9_ram_bp_clken = '0;
    sigFromSrams_bore_9_ram_aux_clk = '0;
    sigFromSrams_bore_9_ram_aux_ckbp = '0;
    sigFromSrams_bore_9_ram_mcp_hold = '0;
    sigFromSrams_bore_9_cgen = '0;
    sigFromSrams_bore_10_ram_hold = '0;
    sigFromSrams_bore_10_ram_bypass = '0;
    sigFromSrams_bore_10_ram_bp_clken = '0;
    sigFromSrams_bore_10_ram_aux_clk = '0;
    sigFromSrams_bore_10_ram_aux_ckbp = '0;
    sigFromSrams_bore_10_ram_mcp_hold = '0;
    sigFromSrams_bore_10_cgen = '0;
    sigFromSrams_bore_11_ram_hold = '0;
    sigFromSrams_bore_11_ram_bypass = '0;
    sigFromSrams_bore_11_ram_bp_clken = '0;
    sigFromSrams_bore_11_ram_aux_clk = '0;
    sigFromSrams_bore_11_ram_aux_ckbp = '0;
    sigFromSrams_bore_11_ram_mcp_hold = '0;
    sigFromSrams_bore_11_cgen = '0;
    sigFromSrams_bore_12_ram_hold = '0;
    sigFromSrams_bore_12_ram_bypass = '0;
    sigFromSrams_bore_12_ram_bp_clken = '0;
    sigFromSrams_bore_12_ram_aux_clk = '0;
    sigFromSrams_bore_12_ram_aux_ckbp = '0;
    sigFromSrams_bore_12_ram_mcp_hold = '0;
    sigFromSrams_bore_12_cgen = '0;
    sigFromSrams_bore_13_ram_hold = '0;
    sigFromSrams_bore_13_ram_bypass = '0;
    sigFromSrams_bore_13_ram_bp_clken = '0;
    sigFromSrams_bore_13_ram_aux_clk = '0;
    sigFromSrams_bore_13_ram_aux_ckbp = '0;
    sigFromSrams_bore_13_ram_mcp_hold = '0;
    sigFromSrams_bore_13_cgen = '0;
    sigFromSrams_bore_14_ram_hold = '0;
    sigFromSrams_bore_14_ram_bypass = '0;
    sigFromSrams_bore_14_ram_bp_clken = '0;
    sigFromSrams_bore_14_ram_aux_clk = '0;
    sigFromSrams_bore_14_ram_aux_ckbp = '0;
    sigFromSrams_bore_14_ram_mcp_hold = '0;
    sigFromSrams_bore_14_cgen = '0;
    sigFromSrams_bore_15_ram_hold = '0;
    sigFromSrams_bore_15_ram_bypass = '0;
    sigFromSrams_bore_15_ram_bp_clken = '0;
    sigFromSrams_bore_15_ram_aux_clk = '0;
    sigFromSrams_bore_15_ram_aux_ckbp = '0;
    sigFromSrams_bore_15_ram_mcp_hold = '0;
    sigFromSrams_bore_15_cgen = '0;
    sigFromSrams_bore_16_ram_hold = '0;
    sigFromSrams_bore_16_ram_bypass = '0;
    sigFromSrams_bore_16_ram_bp_clken = '0;
    sigFromSrams_bore_16_ram_aux_clk = '0;
    sigFromSrams_bore_16_ram_aux_ckbp = '0;
    sigFromSrams_bore_16_ram_mcp_hold = '0;
    sigFromSrams_bore_16_cgen = '0;
    sigFromSrams_bore_17_ram_hold = '0;
    sigFromSrams_bore_17_ram_bypass = '0;
    sigFromSrams_bore_17_ram_bp_clken = '0;
    sigFromSrams_bore_17_ram_aux_clk = '0;
    sigFromSrams_bore_17_ram_aux_ckbp = '0;
    sigFromSrams_bore_17_ram_mcp_hold = '0;
    sigFromSrams_bore_17_cgen = '0;
    sigFromSrams_bore_18_ram_hold = '0;
    sigFromSrams_bore_18_ram_bypass = '0;
    sigFromSrams_bore_18_ram_bp_clken = '0;
    sigFromSrams_bore_18_ram_aux_clk = '0;
    sigFromSrams_bore_18_ram_aux_ckbp = '0;
    sigFromSrams_bore_18_ram_mcp_hold = '0;
    sigFromSrams_bore_18_cgen = '0;
    sigFromSrams_bore_19_ram_hold = '0;
    sigFromSrams_bore_19_ram_bypass = '0;
    sigFromSrams_bore_19_ram_bp_clken = '0;
    sigFromSrams_bore_19_ram_aux_clk = '0;
    sigFromSrams_bore_19_ram_aux_ckbp = '0;
    sigFromSrams_bore_19_ram_mcp_hold = '0;
    sigFromSrams_bore_19_cgen = '0;
    sigFromSrams_bore_20_ram_hold = '0;
    sigFromSrams_bore_20_ram_bypass = '0;
    sigFromSrams_bore_20_ram_bp_clken = '0;
    sigFromSrams_bore_20_ram_aux_clk = '0;
    sigFromSrams_bore_20_ram_aux_ckbp = '0;
    sigFromSrams_bore_20_ram_mcp_hold = '0;
    sigFromSrams_bore_20_cgen = '0;
    cg_bore_cgen = '0;
    cg_bore_1_cgen = '0;
  endtask

  // 功能输入随机激励。CSR 的 mode/asid 等取窄范围，让 satp/vsatp/hgatp 真的会命中
  // 同一组页表；全 32bit 随机会让每拍都像换了个地址空间，遍历器永远走不完一次。
  task automatic drive_random();
    automatic int act = $urandom_range(0, 15);
    io_hartId = 6'($urandom);
    io_tlb_0_req_0_valid = (act < 6);
    io_tlb_0_req_0_bits_vpn = 38'($urandom_range(0, 63));
    io_tlb_0_req_0_bits_s2xlate = 2'($urandom);
    io_tlb_0_resp_ready = ($urandom_range(0, 3) != 0);
    io_tlb_1_req_0_valid = (act < 6);
    io_tlb_1_req_0_bits_vpn = 38'($urandom_range(0, 63));
    io_tlb_1_req_0_bits_s2xlate = 2'($urandom);
    io_sfence_valid = ($urandom_range(0, 63) == 0);
    io_sfence_bits_rs1 = $urandom_range(0, 1);
    io_sfence_bits_rs2 = $urandom_range(0, 1);
    io_sfence_bits_addr = {$urandom, $urandom};
    io_sfence_bits_id = 16'($urandom);
    io_sfence_bits_hv = $urandom_range(0, 1);
    io_sfence_bits_hg = $urandom_range(0, 1);
    io_wfi_wfiReq = ($urandom_range(0, 31) == 0);
    io_csr_tlb_satp_mode = ($urandom_range(0,1)) ? 4'h8 : 4'h9;
    io_csr_tlb_satp_asid = 16'($urandom_range(0, 3));
    io_csr_tlb_satp_ppn = 44'(44'h80000 + $urandom_range(0, 15));
    io_csr_tlb_satp_changed = ($urandom_range(0, 63) == 0);
    io_csr_tlb_vsatp_mode = ($urandom_range(0,1)) ? 4'h8 : 4'h9;
    io_csr_tlb_vsatp_asid = 16'($urandom_range(0, 3));
    io_csr_tlb_vsatp_ppn = 44'(44'h80000 + $urandom_range(0, 15));
    io_csr_tlb_vsatp_changed = ($urandom_range(0, 63) == 0);
    io_csr_tlb_hgatp_mode = ($urandom_range(0,1)) ? 4'h8 : 4'h9;
    io_csr_tlb_hgatp_vmid = 16'($urandom_range(0, 3));
    io_csr_tlb_hgatp_ppn = 44'(44'h80000 + $urandom_range(0, 15));
    io_csr_tlb_hgatp_changed = ($urandom_range(0, 63) == 0);
    io_csr_tlb_mbmc_BME = $urandom_range(0, 1);
    io_csr_tlb_mbmc_CMODE = $urandom_range(0, 1);
    io_csr_tlb_mbmc_BCLEAR = $urandom_range(0, 1);
    io_csr_tlb_mbmc_BMA = {$urandom, $urandom};
    io_csr_tlb_priv_virt = $urandom_range(0, 1);
    io_csr_tlb_priv_virt_changed = ($urandom_range(0, 63) == 0);
    io_csr_tlb_priv_debug = $urandom_range(0, 1);
    io_csr_tlb_mPBMTE = $urandom_range(0, 1);
    io_csr_tlb_hPBMTE = $urandom_range(0, 1);
    io_csr_distribute_csr_w_valid = ($urandom_range(0, 255) == 0);
    io_csr_distribute_csr_w_bits_addr = 12'($urandom);
    io_csr_distribute_csr_w_bits_data = {$urandom, $urandom};
  endtask

  // ---------------------------------------------------------------------------
  // TileLink 应答模型
  // ---------------------------------------------------------------------------
  // L2TLB 用 source 当 mem id（0..5 LLPTW / 6 PTW / 7 HPTW / 8..15 Bitmap），每次请求
  // 取回 64B（2 个 256bit beat）。这里跟踪在途 source，只对**真发过**的 source 回
  // 数据：随机乱回 id 的话，waiting_resp 永远对不上，refill / merge / sector 合并这
  // 几条主路径一拍也走不到。
  //   outstanding[i] —— id i 有请求在途
  //   d_beat         —— 当前应答处在第几个 beat（0=首，1=末）
  logic [15:0] outstanding;
  logic        d_beat;
  logic [3:0]  d_cur_src;

  // 一拍 D 通道 = 256 bit = 4 条 PTE。按 Sv48 的位域**造合法 PTE**，不要全随机：
  //   [63]n [62:61]pbmt [60:54]rsv [53:10]ppn [9:8]rsw [7]D [6]A [5]G [4]U [3]X [2]W [1]R [0]V
  //
  // 三条约束都是**实测逼出来的**，不是照抄手册：
  // 1. ★ppn 必须落在 DRAM 区★，否则下一级地址一出 PMA 就是 accessFault，
  //    遍历走一层就断（实测 a_fire=0）。
  // 2. ★superpage 必须按级对齐★：golden 的 pte_page_fault 里有"superpage 未对齐
  //    ⇒ page fault"。ppn 取 0x80000+rand(0..255) 时低位必非 0 ⇒ **任何 superpage
  //    都直接 fault**，sector 合并里 level 1/2/3 那几条路一次都走不到。
  //    实测后果：变异 M5（把 1GB 的切点写错一位）**UT 抓不到**。
  //    这里按级把低位清零：2MB 清低 9 位、1GB 清低 18 位。
  // 3. ★napot 要真的出现★：n 是 pte[63]，且 golden 要求 ppn[3:0]==8 才合法。
  //    原来 [63:54] 恒 0 ⇒ n 恒 0 ⇒ 变异 M2（entry_n 不归零）**UT 抓不到**。
  //
  // 非叶级带 u/a/d/n/pbmt 会被判 page fault，所以这些位只给叶子。
  function automatic logic [255:0] make_ptes();
    logic [255:0] blk;
    logic [43:0]  ppn;
    logic         leaf, napot;
    logic [1:0]   pbmt, cls;
    for (int k = 0; k < 4; k++) begin
      leaf  = ($urandom_range(0, 2) != 0);         // 2/3 概率是叶子
      cls   = 2'($urandom_range(0, 3));            // 页大小类别
      napot = leaf & (cls == 2'h3);
      case (cls)
        2'h1:    ppn = 44'h80000 + (44'($urandom_range(0, 7)) << 9);   // 2MB 对齐
        2'h2:    ppn = 44'h80000 + (44'($urandom_range(0, 3)) << 18);  // 1GB 对齐
        2'h3:    ppn = 44'h80000 + (44'($urandom_range(0, 15)) << 4) + 44'h8; // napot: ppn[3:0]=8
        default: ppn = 44'h80000 + 44'($urandom_range(0, 255));        // 4KB
      endcase
      pbmt = leaf ? 2'($urandom_range(0, 2)) : 2'h0;   // 3 是保留值，会 page fault
      blk[k*64 +: 64] = {napot, pbmt, 7'h0, ppn, 2'h0,
                         leaf, leaf,                 // D, A（非叶级带 A/D 会 fault）
                         1'b0, leaf,                 // G, U
                         leaf & $urandom_range(0,1), // X
                         leaf & $urandom_range(0,1), // W
                         leaf,                       // R
                         1'b1};                      // V
    end
    return blk;
  endfunction

  task automatic tl_reset();
    outstanding = '0;  d_beat = 1'b0;  d_cur_src = '0;
    auto_out_a_ready     = 1'b1;
    auto_out_d_valid     = 1'b0;
    auto_out_d_bits_opcode = 3'h1;   // AccessAckData：带数据、多 beat
    auto_out_d_bits_size   = 3'h6;   // 64B
    auto_out_d_bits_source = '0;
    auto_out_d_bits_data   = '0;
  endtask

  // 每拍在时钟沿后推进：先记 A 通道握手，再决定这一拍 D 通道给什么。
  task automatic tl_step();
    automatic int pick;
    auto_out_a_ready = ($urandom_range(0, 7) != 0);   // 偶尔背压
    // A 通道握手 → 登记在途
    if (g_auto_out_a_valid && auto_out_a_ready) begin
      outstanding[g_auto_out_a_bits_source] = 1'b1;
      n_a_fire++;
      // 按 mem id 分类计数：0..5 LLPTW / 6 PTW / 7 HPTW / 8..15 Bitmap。
      // 只看端口，不用层次引用，所以 golden 和重写侧都适用。
      if (g_auto_out_a_bits_source[3])            n_a_bitmap++;
      else if (g_auto_out_a_bits_source == 4'h7)  n_a_hptw++;
      else if (g_auto_out_a_bits_source == 4'h6)  n_a_ptw++;
      else                                        n_a_llptw++;
    end
    // D 通道
    if (auto_out_d_valid) begin
      n_d_fire++;
      if (d_beat) begin                    // 末 beat 交付完毕
        outstanding[d_cur_src] = 1'b0;
        d_beat = 1'b0;
        auto_out_d_valid = 1'b0;
      end else begin                       // 继续送第二个 beat
        d_beat = 1'b1;
        auto_out_d_bits_data = make_ptes();
      end
    end else if (|outstanding && $urandom_range(0, 2) != 0) begin
      // 从在途集合里挑一个开始应答
      pick = -1;
      for (int k = 0; k < 16; k++)
        if (outstanding[k] && (pick < 0 || $urandom_range(0, 3) == 0)) pick = k;
      if (pick >= 0) begin
        d_cur_src = 4'(pick);
        auto_out_d_bits_source = 4'(pick);
        auto_out_d_valid = 1'b1;
        d_beat = 1'b0;
        auto_out_d_bits_data = make_ptes();
      end
    end
  endtask


  initial begin
    if (!$value$plusargs("ncycles=%d", NVEC)) NVEC = 200000;
    drive_dft_zero();
    tl_reset();
    drive_random();
    reset = 1'b1;
    repeat (8) @(posedge clock);
    #1 reset = 1'b0;

    // ------------------------------------------------------------------
    // 暖机窗口（不比较）：把两侧推到确定状态，并把 PMP 配成"放行"。
    //
    // ★为什么非配不可★（2026-09-20 实测定位，不是猜的）：
    // L2TLB 给 5 个 PMPChecker 的 mode 在 golden 里写死成 ModeS。S 态下 PMP
    // 若没有任何表项命中就是**拒绝**，而复位后 pmpcfg/pmpaddr 全 0 ⇒ 没有表项。
    // 实测 50000/50000 拍 PMPChecker 的 io_resp_ld 都是拒绝，PTW 每次 pmp_check
    // 之后直接 accessFault，`io_mem_req_valid = ~s_mem_req & ~mem_mask &
    // ~accessFault & s_pmp_check` 永远为 0：
    //     ptwmem=0 llmem=0 hpmem=0 marb=0 a_valid=0  -> a_fire=0
    // 也就是 refill / merge / sector / difftest refill 探针整条路一拍没走到。
    // 这里写 pmpaddr0=全 1（NAPOT 覆盖全空间）、pmpcfg0=0x1F（A=NAPOT, RWX）。
    //
    // 顺带这个窗口也是「不复位寄存器 + 随机读」那条坑的标准修法：比较窗口打开
    // 之前先跑一段，让两侧的无复位寄存器都被写成确定值。
    // ------------------------------------------------------------------
    for (int t = 0; t < WARMUP; t++) begin
      @(posedge clock); #1;
      drive_random();
      drive_dft_zero();
      if (t == 1) begin
        io_csr_distribute_csr_w_valid     = 1'b1;
        io_csr_distribute_csr_w_bits_addr = 12'h3B0;   // pmpaddr0
        io_csr_distribute_csr_w_bits_data = {64{1'b1}};
      end else if (t == 2) begin
        io_csr_distribute_csr_w_valid     = 1'b1;
        io_csr_distribute_csr_w_bits_addr = 12'h3A0;   // pmpcfg0
        io_csr_distribute_csr_w_bits_data = 64'h1F;    // A=NAPOT | X|W|R
      end else begin
        io_csr_distribute_csr_w_valid     = 1'b0;
      end
      tl_step();
    end
    for (int t = 0; t < NVEC; t++) begin
      @(posedge clock); #1;
      do_check(t);
      if (g_io_tlb_0_resp_valid || g_io_tlb_1_resp_valid) n_resp_fire++;
      if (io_tlb_0_req_0_valid && g_io_tlb_0_req_0_ready) n_req_fire++;
      drive_random();
      drive_dft_zero();
      // ★周期性把 PMP 重新配成放行★（2026-09-20 实测加的）
      // 随机 CSR 写口有 72 个地址会打到 PMP/PMA 配置上（PMP.sv 里 72 处
      // `distribute_csr_w_bits_addr == 12'h…`）。按 1/256 的写频率，期望
      // 约 1.4 万拍就会命中一次，把暖机时配好的表项冲掉。实测正是如此：
      //     t=10000 a_fire=264 | t=20000 a_fire=379 | t=30000..190000 a_fire=379
      //     （t>=20000 起 PMPChecker 的 io_resp_ld 恒为"拒绝"）
      // 也就是说后 18 万拍访存通道是**死的**，"200k 拍"名不副实。
      // 每 1024 拍重配一次：随机 CSR 写仍然被覆盖，主路径也不会一去不回。
      if (t % 1024 == 0) begin
        io_csr_distribute_csr_w_valid     = 1'b1;
        io_csr_distribute_csr_w_bits_addr = 12'h3B0;
        io_csr_distribute_csr_w_bits_data = {64{1'b1}};
      end else if (t % 1024 == 1) begin
        io_csr_distribute_csr_w_valid     = 1'b1;
        io_csr_distribute_csr_w_bits_addr = 12'h3A0;
        io_csr_distribute_csr_w_bits_data = 64'h1F;
      end
      tl_step();
    end
    $display("a_fire_by_id: llptw=%0d ptw=%0d hptw=%0d bitmap=%0d",
             n_a_llptw, n_a_ptw, n_a_hptw, n_a_bitmap);
    $display("checks=%0d errors=%0d  a_fire=%0d d_fire=%0d tlb_req_fire=%0d tlb_resp=%0d",
             checks, errors, n_a_fire, n_d_fire, n_req_fire, n_resp_fire);
    // 覆盖闸：光 errors=0 不算数 —— 比较点、访存握手、TLB 请求都必须真的发生过。
    if (checks == 0)      begin $display("TEST FAILED: checks=0"); $finish; end
    if (n_a_fire == 0)    begin $display("TEST FAILED: 访存通道一次都没握手"); $finish; end
    if (n_d_fire == 0)    begin $display("TEST FAILED: D 通道一次都没应答"); $finish; end
    if (n_req_fire == 0)  begin $display("TEST FAILED: TLB 请求一次都没被接受"); $finish; end
    if (errors == 0) $display("TEST PASSED"); else $display("TEST FAILED");
    $finish;
  end
endmodule
