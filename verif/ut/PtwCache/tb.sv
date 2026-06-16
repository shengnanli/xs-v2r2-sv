// 自动生成：scripts/gen_ptwcache_tb.py —— 勿手改
`timescale 1ns/1ps
module tb;
  int unsigned NVEC = 200000;
  int unsigned WARMUP = 64;
  int errors = 0, checks = 0;
  int pmm_l3v = 0, pmm_l1v = 0;
  // 本轮新增：L1 元数据/replace 分叉探针计数
  int pmm_l1g = 0, pmm_l1vmids = 0, pmm_l1repl = 0, pmm_l0repl = 0;
  int pmm_l2repl = 0, pmm_l3repl = 0, pmm_l1sram5 = 0;
  logic clock = 0, reset;
  always #5 clock = ~clock;
  logic io_csr_mPBMTE;
  logic io_csr_hPBMTE;
  logic io_req_valid;
  logic [37:0] io_req_bits_req_info_vpn;
  logic [1:0] io_req_bits_req_info_s2xlate;
  logic [1:0] io_req_bits_req_info_source;
  logic io_req_bits_isFirst;
  logic io_req_bits_isHptwReq;
  logic [2:0] io_req_bits_hptwId;
  logic io_resp_ready;
  logic io_refill_valid;
  logic [511:0] io_refill_bits_ptes;
  logic io_refill_bits_levelOH_sp;
  logic io_refill_bits_levelOH_l0;
  logic io_refill_bits_levelOH_l1;
  logic io_refill_bits_levelOH_l2;
  logic io_refill_bits_levelOH_l3;
  logic [37:0] io_refill_bits_req_info_dup_0_vpn;
  logic [1:0] io_refill_bits_req_info_dup_0_s2xlate;
  logic [1:0] io_refill_bits_req_info_dup_0_source;
  logic [37:0] io_refill_bits_req_info_dup_1_vpn;
  logic [1:0] io_refill_bits_req_info_dup_1_s2xlate;
  logic [1:0] io_refill_bits_req_info_dup_1_source;
  logic [37:0] io_refill_bits_req_info_dup_2_vpn;
  logic [1:0] io_refill_bits_req_info_dup_2_s2xlate;
  logic [1:0] io_refill_bits_req_info_dup_2_source;
  logic [1:0] io_refill_bits_level_dup_0;
  logic [1:0] io_refill_bits_level_dup_2;
  logic [63:0] io_refill_bits_sel_pte_dup_0;
  logic [63:0] io_refill_bits_sel_pte_dup_2;
  logic io_sfence_dup_0_valid;
  logic io_sfence_dup_0_bits_rs1;
  logic io_sfence_dup_0_bits_rs2;
  logic [49:0] io_sfence_dup_0_bits_addr;
  logic [15:0] io_sfence_dup_0_bits_id;
  logic io_sfence_dup_0_bits_hv;
  logic io_sfence_dup_0_bits_hg;
  logic io_sfence_dup_1_valid;
  logic [15:0] io_sfence_dup_1_bits_id;
  logic io_sfence_dup_2_valid;
  logic io_sfence_dup_2_bits_rs1;
  logic io_sfence_dup_2_bits_rs2;
  logic [15:0] io_sfence_dup_2_bits_id;
  logic [15:0] io_csr_dup_0_satp_asid;
  logic io_csr_dup_0_satp_changed;
  logic [15:0] io_csr_dup_0_vsatp_asid;
  logic io_csr_dup_0_vsatp_changed;
  logic [3:0] io_csr_dup_0_hgatp_mode;
  logic [15:0] io_csr_dup_0_hgatp_vmid;
  logic io_csr_dup_0_hgatp_changed;
  logic io_csr_dup_0_priv_virt;
  logic [15:0] io_csr_dup_1_satp_asid;
  logic io_csr_dup_1_satp_changed;
  logic [15:0] io_csr_dup_1_vsatp_asid;
  logic io_csr_dup_1_vsatp_changed;
  logic [3:0] io_csr_dup_1_hgatp_mode;
  logic [15:0] io_csr_dup_1_hgatp_vmid;
  logic io_csr_dup_1_hgatp_changed;
  logic io_csr_dup_1_priv_virt;
  logic [15:0] io_csr_dup_2_satp_asid;
  logic io_csr_dup_2_satp_changed;
  logic [15:0] io_csr_dup_2_vsatp_asid;
  logic io_csr_dup_2_vsatp_changed;
  logic [3:0] io_csr_dup_2_hgatp_mode;
  logic [15:0] io_csr_dup_2_hgatp_vmid;
  logic io_csr_dup_2_hgatp_changed;
  logic io_csr_dup_2_priv_virt;
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
  wire g_io_req_ready;  wire i_io_req_ready;
  wire g_io_resp_valid;  wire i_io_resp_valid;
  wire [37:0] g_io_resp_bits_req_info_vpn;  wire [37:0] i_io_resp_bits_req_info_vpn;
  wire [1:0] g_io_resp_bits_req_info_s2xlate;  wire [1:0] i_io_resp_bits_req_info_s2xlate;
  wire [1:0] g_io_resp_bits_req_info_source;  wire [1:0] i_io_resp_bits_req_info_source;
  wire g_io_resp_bits_isFirst;  wire i_io_resp_bits_isFirst;
  wire g_io_resp_bits_hit;  wire i_io_resp_bits_hit;
  wire g_io_resp_bits_prefetch;  wire i_io_resp_bits_prefetch;
  wire g_io_resp_bits_bypassed;  wire i_io_resp_bits_bypassed;
  wire g_io_resp_bits_toFsm_l3Hit;  wire i_io_resp_bits_toFsm_l3Hit;
  wire g_io_resp_bits_toFsm_l2Hit;  wire i_io_resp_bits_toFsm_l2Hit;
  wire g_io_resp_bits_toFsm_l1Hit;  wire i_io_resp_bits_toFsm_l1Hit;
  wire [37:0] g_io_resp_bits_toFsm_ppn;  wire [37:0] i_io_resp_bits_toFsm_ppn;
  wire g_io_resp_bits_toFsm_stage1Hit;  wire i_io_resp_bits_toFsm_stage1Hit;
  wire [34:0] g_io_resp_bits_stage1_entry_0_tag;  wire [34:0] i_io_resp_bits_stage1_entry_0_tag;
  wire [15:0] g_io_resp_bits_stage1_entry_0_asid;  wire [15:0] i_io_resp_bits_stage1_entry_0_asid;
  wire [13:0] g_io_resp_bits_stage1_entry_0_vmid;  wire [13:0] i_io_resp_bits_stage1_entry_0_vmid;
  wire g_io_resp_bits_stage1_entry_0_n;  wire i_io_resp_bits_stage1_entry_0_n;
  wire [1:0] g_io_resp_bits_stage1_entry_0_pbmt;  wire [1:0] i_io_resp_bits_stage1_entry_0_pbmt;
  wire g_io_resp_bits_stage1_entry_0_perm_d;  wire i_io_resp_bits_stage1_entry_0_perm_d;
  wire g_io_resp_bits_stage1_entry_0_perm_a;  wire i_io_resp_bits_stage1_entry_0_perm_a;
  wire g_io_resp_bits_stage1_entry_0_perm_g;  wire i_io_resp_bits_stage1_entry_0_perm_g;
  wire g_io_resp_bits_stage1_entry_0_perm_u;  wire i_io_resp_bits_stage1_entry_0_perm_u;
  wire g_io_resp_bits_stage1_entry_0_perm_x;  wire i_io_resp_bits_stage1_entry_0_perm_x;
  wire g_io_resp_bits_stage1_entry_0_perm_w;  wire i_io_resp_bits_stage1_entry_0_perm_w;
  wire g_io_resp_bits_stage1_entry_0_perm_r;  wire i_io_resp_bits_stage1_entry_0_perm_r;
  wire [1:0] g_io_resp_bits_stage1_entry_0_level;  wire [1:0] i_io_resp_bits_stage1_entry_0_level;
  wire g_io_resp_bits_stage1_entry_0_v;  wire i_io_resp_bits_stage1_entry_0_v;
  wire [40:0] g_io_resp_bits_stage1_entry_0_ppn;  wire [40:0] i_io_resp_bits_stage1_entry_0_ppn;
  wire [2:0] g_io_resp_bits_stage1_entry_0_ppn_low;  wire [2:0] i_io_resp_bits_stage1_entry_0_ppn_low;
  wire g_io_resp_bits_stage1_entry_0_pf;  wire i_io_resp_bits_stage1_entry_0_pf;
  wire [34:0] g_io_resp_bits_stage1_entry_1_tag;  wire [34:0] i_io_resp_bits_stage1_entry_1_tag;
  wire [15:0] g_io_resp_bits_stage1_entry_1_asid;  wire [15:0] i_io_resp_bits_stage1_entry_1_asid;
  wire [13:0] g_io_resp_bits_stage1_entry_1_vmid;  wire [13:0] i_io_resp_bits_stage1_entry_1_vmid;
  wire g_io_resp_bits_stage1_entry_1_n;  wire i_io_resp_bits_stage1_entry_1_n;
  wire [1:0] g_io_resp_bits_stage1_entry_1_pbmt;  wire [1:0] i_io_resp_bits_stage1_entry_1_pbmt;
  wire g_io_resp_bits_stage1_entry_1_perm_d;  wire i_io_resp_bits_stage1_entry_1_perm_d;
  wire g_io_resp_bits_stage1_entry_1_perm_a;  wire i_io_resp_bits_stage1_entry_1_perm_a;
  wire g_io_resp_bits_stage1_entry_1_perm_g;  wire i_io_resp_bits_stage1_entry_1_perm_g;
  wire g_io_resp_bits_stage1_entry_1_perm_u;  wire i_io_resp_bits_stage1_entry_1_perm_u;
  wire g_io_resp_bits_stage1_entry_1_perm_x;  wire i_io_resp_bits_stage1_entry_1_perm_x;
  wire g_io_resp_bits_stage1_entry_1_perm_w;  wire i_io_resp_bits_stage1_entry_1_perm_w;
  wire g_io_resp_bits_stage1_entry_1_perm_r;  wire i_io_resp_bits_stage1_entry_1_perm_r;
  wire [1:0] g_io_resp_bits_stage1_entry_1_level;  wire [1:0] i_io_resp_bits_stage1_entry_1_level;
  wire g_io_resp_bits_stage1_entry_1_v;  wire i_io_resp_bits_stage1_entry_1_v;
  wire [40:0] g_io_resp_bits_stage1_entry_1_ppn;  wire [40:0] i_io_resp_bits_stage1_entry_1_ppn;
  wire [2:0] g_io_resp_bits_stage1_entry_1_ppn_low;  wire [2:0] i_io_resp_bits_stage1_entry_1_ppn_low;
  wire g_io_resp_bits_stage1_entry_1_pf;  wire i_io_resp_bits_stage1_entry_1_pf;
  wire [34:0] g_io_resp_bits_stage1_entry_2_tag;  wire [34:0] i_io_resp_bits_stage1_entry_2_tag;
  wire [15:0] g_io_resp_bits_stage1_entry_2_asid;  wire [15:0] i_io_resp_bits_stage1_entry_2_asid;
  wire [13:0] g_io_resp_bits_stage1_entry_2_vmid;  wire [13:0] i_io_resp_bits_stage1_entry_2_vmid;
  wire g_io_resp_bits_stage1_entry_2_n;  wire i_io_resp_bits_stage1_entry_2_n;
  wire [1:0] g_io_resp_bits_stage1_entry_2_pbmt;  wire [1:0] i_io_resp_bits_stage1_entry_2_pbmt;
  wire g_io_resp_bits_stage1_entry_2_perm_d;  wire i_io_resp_bits_stage1_entry_2_perm_d;
  wire g_io_resp_bits_stage1_entry_2_perm_a;  wire i_io_resp_bits_stage1_entry_2_perm_a;
  wire g_io_resp_bits_stage1_entry_2_perm_g;  wire i_io_resp_bits_stage1_entry_2_perm_g;
  wire g_io_resp_bits_stage1_entry_2_perm_u;  wire i_io_resp_bits_stage1_entry_2_perm_u;
  wire g_io_resp_bits_stage1_entry_2_perm_x;  wire i_io_resp_bits_stage1_entry_2_perm_x;
  wire g_io_resp_bits_stage1_entry_2_perm_w;  wire i_io_resp_bits_stage1_entry_2_perm_w;
  wire g_io_resp_bits_stage1_entry_2_perm_r;  wire i_io_resp_bits_stage1_entry_2_perm_r;
  wire [1:0] g_io_resp_bits_stage1_entry_2_level;  wire [1:0] i_io_resp_bits_stage1_entry_2_level;
  wire g_io_resp_bits_stage1_entry_2_v;  wire i_io_resp_bits_stage1_entry_2_v;
  wire [40:0] g_io_resp_bits_stage1_entry_2_ppn;  wire [40:0] i_io_resp_bits_stage1_entry_2_ppn;
  wire [2:0] g_io_resp_bits_stage1_entry_2_ppn_low;  wire [2:0] i_io_resp_bits_stage1_entry_2_ppn_low;
  wire g_io_resp_bits_stage1_entry_2_pf;  wire i_io_resp_bits_stage1_entry_2_pf;
  wire [34:0] g_io_resp_bits_stage1_entry_3_tag;  wire [34:0] i_io_resp_bits_stage1_entry_3_tag;
  wire [15:0] g_io_resp_bits_stage1_entry_3_asid;  wire [15:0] i_io_resp_bits_stage1_entry_3_asid;
  wire [13:0] g_io_resp_bits_stage1_entry_3_vmid;  wire [13:0] i_io_resp_bits_stage1_entry_3_vmid;
  wire g_io_resp_bits_stage1_entry_3_n;  wire i_io_resp_bits_stage1_entry_3_n;
  wire [1:0] g_io_resp_bits_stage1_entry_3_pbmt;  wire [1:0] i_io_resp_bits_stage1_entry_3_pbmt;
  wire g_io_resp_bits_stage1_entry_3_perm_d;  wire i_io_resp_bits_stage1_entry_3_perm_d;
  wire g_io_resp_bits_stage1_entry_3_perm_a;  wire i_io_resp_bits_stage1_entry_3_perm_a;
  wire g_io_resp_bits_stage1_entry_3_perm_g;  wire i_io_resp_bits_stage1_entry_3_perm_g;
  wire g_io_resp_bits_stage1_entry_3_perm_u;  wire i_io_resp_bits_stage1_entry_3_perm_u;
  wire g_io_resp_bits_stage1_entry_3_perm_x;  wire i_io_resp_bits_stage1_entry_3_perm_x;
  wire g_io_resp_bits_stage1_entry_3_perm_w;  wire i_io_resp_bits_stage1_entry_3_perm_w;
  wire g_io_resp_bits_stage1_entry_3_perm_r;  wire i_io_resp_bits_stage1_entry_3_perm_r;
  wire [1:0] g_io_resp_bits_stage1_entry_3_level;  wire [1:0] i_io_resp_bits_stage1_entry_3_level;
  wire g_io_resp_bits_stage1_entry_3_v;  wire i_io_resp_bits_stage1_entry_3_v;
  wire [40:0] g_io_resp_bits_stage1_entry_3_ppn;  wire [40:0] i_io_resp_bits_stage1_entry_3_ppn;
  wire [2:0] g_io_resp_bits_stage1_entry_3_ppn_low;  wire [2:0] i_io_resp_bits_stage1_entry_3_ppn_low;
  wire g_io_resp_bits_stage1_entry_3_pf;  wire i_io_resp_bits_stage1_entry_3_pf;
  wire [34:0] g_io_resp_bits_stage1_entry_4_tag;  wire [34:0] i_io_resp_bits_stage1_entry_4_tag;
  wire [15:0] g_io_resp_bits_stage1_entry_4_asid;  wire [15:0] i_io_resp_bits_stage1_entry_4_asid;
  wire [13:0] g_io_resp_bits_stage1_entry_4_vmid;  wire [13:0] i_io_resp_bits_stage1_entry_4_vmid;
  wire g_io_resp_bits_stage1_entry_4_n;  wire i_io_resp_bits_stage1_entry_4_n;
  wire [1:0] g_io_resp_bits_stage1_entry_4_pbmt;  wire [1:0] i_io_resp_bits_stage1_entry_4_pbmt;
  wire g_io_resp_bits_stage1_entry_4_perm_d;  wire i_io_resp_bits_stage1_entry_4_perm_d;
  wire g_io_resp_bits_stage1_entry_4_perm_a;  wire i_io_resp_bits_stage1_entry_4_perm_a;
  wire g_io_resp_bits_stage1_entry_4_perm_g;  wire i_io_resp_bits_stage1_entry_4_perm_g;
  wire g_io_resp_bits_stage1_entry_4_perm_u;  wire i_io_resp_bits_stage1_entry_4_perm_u;
  wire g_io_resp_bits_stage1_entry_4_perm_x;  wire i_io_resp_bits_stage1_entry_4_perm_x;
  wire g_io_resp_bits_stage1_entry_4_perm_w;  wire i_io_resp_bits_stage1_entry_4_perm_w;
  wire g_io_resp_bits_stage1_entry_4_perm_r;  wire i_io_resp_bits_stage1_entry_4_perm_r;
  wire [1:0] g_io_resp_bits_stage1_entry_4_level;  wire [1:0] i_io_resp_bits_stage1_entry_4_level;
  wire g_io_resp_bits_stage1_entry_4_v;  wire i_io_resp_bits_stage1_entry_4_v;
  wire [40:0] g_io_resp_bits_stage1_entry_4_ppn;  wire [40:0] i_io_resp_bits_stage1_entry_4_ppn;
  wire [2:0] g_io_resp_bits_stage1_entry_4_ppn_low;  wire [2:0] i_io_resp_bits_stage1_entry_4_ppn_low;
  wire g_io_resp_bits_stage1_entry_4_pf;  wire i_io_resp_bits_stage1_entry_4_pf;
  wire [34:0] g_io_resp_bits_stage1_entry_5_tag;  wire [34:0] i_io_resp_bits_stage1_entry_5_tag;
  wire [15:0] g_io_resp_bits_stage1_entry_5_asid;  wire [15:0] i_io_resp_bits_stage1_entry_5_asid;
  wire [13:0] g_io_resp_bits_stage1_entry_5_vmid;  wire [13:0] i_io_resp_bits_stage1_entry_5_vmid;
  wire g_io_resp_bits_stage1_entry_5_n;  wire i_io_resp_bits_stage1_entry_5_n;
  wire [1:0] g_io_resp_bits_stage1_entry_5_pbmt;  wire [1:0] i_io_resp_bits_stage1_entry_5_pbmt;
  wire g_io_resp_bits_stage1_entry_5_perm_d;  wire i_io_resp_bits_stage1_entry_5_perm_d;
  wire g_io_resp_bits_stage1_entry_5_perm_a;  wire i_io_resp_bits_stage1_entry_5_perm_a;
  wire g_io_resp_bits_stage1_entry_5_perm_g;  wire i_io_resp_bits_stage1_entry_5_perm_g;
  wire g_io_resp_bits_stage1_entry_5_perm_u;  wire i_io_resp_bits_stage1_entry_5_perm_u;
  wire g_io_resp_bits_stage1_entry_5_perm_x;  wire i_io_resp_bits_stage1_entry_5_perm_x;
  wire g_io_resp_bits_stage1_entry_5_perm_w;  wire i_io_resp_bits_stage1_entry_5_perm_w;
  wire g_io_resp_bits_stage1_entry_5_perm_r;  wire i_io_resp_bits_stage1_entry_5_perm_r;
  wire [1:0] g_io_resp_bits_stage1_entry_5_level;  wire [1:0] i_io_resp_bits_stage1_entry_5_level;
  wire g_io_resp_bits_stage1_entry_5_v;  wire i_io_resp_bits_stage1_entry_5_v;
  wire [40:0] g_io_resp_bits_stage1_entry_5_ppn;  wire [40:0] i_io_resp_bits_stage1_entry_5_ppn;
  wire [2:0] g_io_resp_bits_stage1_entry_5_ppn_low;  wire [2:0] i_io_resp_bits_stage1_entry_5_ppn_low;
  wire g_io_resp_bits_stage1_entry_5_pf;  wire i_io_resp_bits_stage1_entry_5_pf;
  wire [34:0] g_io_resp_bits_stage1_entry_6_tag;  wire [34:0] i_io_resp_bits_stage1_entry_6_tag;
  wire [15:0] g_io_resp_bits_stage1_entry_6_asid;  wire [15:0] i_io_resp_bits_stage1_entry_6_asid;
  wire [13:0] g_io_resp_bits_stage1_entry_6_vmid;  wire [13:0] i_io_resp_bits_stage1_entry_6_vmid;
  wire g_io_resp_bits_stage1_entry_6_n;  wire i_io_resp_bits_stage1_entry_6_n;
  wire [1:0] g_io_resp_bits_stage1_entry_6_pbmt;  wire [1:0] i_io_resp_bits_stage1_entry_6_pbmt;
  wire g_io_resp_bits_stage1_entry_6_perm_d;  wire i_io_resp_bits_stage1_entry_6_perm_d;
  wire g_io_resp_bits_stage1_entry_6_perm_a;  wire i_io_resp_bits_stage1_entry_6_perm_a;
  wire g_io_resp_bits_stage1_entry_6_perm_g;  wire i_io_resp_bits_stage1_entry_6_perm_g;
  wire g_io_resp_bits_stage1_entry_6_perm_u;  wire i_io_resp_bits_stage1_entry_6_perm_u;
  wire g_io_resp_bits_stage1_entry_6_perm_x;  wire i_io_resp_bits_stage1_entry_6_perm_x;
  wire g_io_resp_bits_stage1_entry_6_perm_w;  wire i_io_resp_bits_stage1_entry_6_perm_w;
  wire g_io_resp_bits_stage1_entry_6_perm_r;  wire i_io_resp_bits_stage1_entry_6_perm_r;
  wire [1:0] g_io_resp_bits_stage1_entry_6_level;  wire [1:0] i_io_resp_bits_stage1_entry_6_level;
  wire g_io_resp_bits_stage1_entry_6_v;  wire i_io_resp_bits_stage1_entry_6_v;
  wire [40:0] g_io_resp_bits_stage1_entry_6_ppn;  wire [40:0] i_io_resp_bits_stage1_entry_6_ppn;
  wire [2:0] g_io_resp_bits_stage1_entry_6_ppn_low;  wire [2:0] i_io_resp_bits_stage1_entry_6_ppn_low;
  wire g_io_resp_bits_stage1_entry_6_pf;  wire i_io_resp_bits_stage1_entry_6_pf;
  wire [34:0] g_io_resp_bits_stage1_entry_7_tag;  wire [34:0] i_io_resp_bits_stage1_entry_7_tag;
  wire [15:0] g_io_resp_bits_stage1_entry_7_asid;  wire [15:0] i_io_resp_bits_stage1_entry_7_asid;
  wire [13:0] g_io_resp_bits_stage1_entry_7_vmid;  wire [13:0] i_io_resp_bits_stage1_entry_7_vmid;
  wire g_io_resp_bits_stage1_entry_7_n;  wire i_io_resp_bits_stage1_entry_7_n;
  wire [1:0] g_io_resp_bits_stage1_entry_7_pbmt;  wire [1:0] i_io_resp_bits_stage1_entry_7_pbmt;
  wire g_io_resp_bits_stage1_entry_7_perm_d;  wire i_io_resp_bits_stage1_entry_7_perm_d;
  wire g_io_resp_bits_stage1_entry_7_perm_a;  wire i_io_resp_bits_stage1_entry_7_perm_a;
  wire g_io_resp_bits_stage1_entry_7_perm_g;  wire i_io_resp_bits_stage1_entry_7_perm_g;
  wire g_io_resp_bits_stage1_entry_7_perm_u;  wire i_io_resp_bits_stage1_entry_7_perm_u;
  wire g_io_resp_bits_stage1_entry_7_perm_x;  wire i_io_resp_bits_stage1_entry_7_perm_x;
  wire g_io_resp_bits_stage1_entry_7_perm_w;  wire i_io_resp_bits_stage1_entry_7_perm_w;
  wire g_io_resp_bits_stage1_entry_7_perm_r;  wire i_io_resp_bits_stage1_entry_7_perm_r;
  wire [1:0] g_io_resp_bits_stage1_entry_7_level;  wire [1:0] i_io_resp_bits_stage1_entry_7_level;
  wire g_io_resp_bits_stage1_entry_7_v;  wire i_io_resp_bits_stage1_entry_7_v;
  wire [40:0] g_io_resp_bits_stage1_entry_7_ppn;  wire [40:0] i_io_resp_bits_stage1_entry_7_ppn;
  wire [2:0] g_io_resp_bits_stage1_entry_7_ppn_low;  wire [2:0] i_io_resp_bits_stage1_entry_7_ppn_low;
  wire g_io_resp_bits_stage1_entry_7_pf;  wire i_io_resp_bits_stage1_entry_7_pf;
  wire g_io_resp_bits_stage1_pteidx_0;  wire i_io_resp_bits_stage1_pteidx_0;
  wire g_io_resp_bits_stage1_pteidx_1;  wire i_io_resp_bits_stage1_pteidx_1;
  wire g_io_resp_bits_stage1_pteidx_2;  wire i_io_resp_bits_stage1_pteidx_2;
  wire g_io_resp_bits_stage1_pteidx_3;  wire i_io_resp_bits_stage1_pteidx_3;
  wire g_io_resp_bits_stage1_pteidx_4;  wire i_io_resp_bits_stage1_pteidx_4;
  wire g_io_resp_bits_stage1_pteidx_5;  wire i_io_resp_bits_stage1_pteidx_5;
  wire g_io_resp_bits_stage1_pteidx_6;  wire i_io_resp_bits_stage1_pteidx_6;
  wire g_io_resp_bits_stage1_pteidx_7;  wire i_io_resp_bits_stage1_pteidx_7;
  wire g_io_resp_bits_stage1_not_super;  wire i_io_resp_bits_stage1_not_super;
  wire g_io_resp_bits_isHptwReq;  wire i_io_resp_bits_isHptwReq;
  wire g_io_resp_bits_toHptw_l3Hit;  wire i_io_resp_bits_toHptw_l3Hit;
  wire g_io_resp_bits_toHptw_l2Hit;  wire i_io_resp_bits_toHptw_l2Hit;
  wire g_io_resp_bits_toHptw_l1Hit;  wire i_io_resp_bits_toHptw_l1Hit;
  wire [35:0] g_io_resp_bits_toHptw_ppn;  wire [35:0] i_io_resp_bits_toHptw_ppn;
  wire [2:0] g_io_resp_bits_toHptw_id;  wire [2:0] i_io_resp_bits_toHptw_id;
  wire [37:0] g_io_resp_bits_toHptw_resp_entry_tag;  wire [37:0] i_io_resp_bits_toHptw_resp_entry_tag;
  wire [13:0] g_io_resp_bits_toHptw_resp_entry_vmid;  wire [13:0] i_io_resp_bits_toHptw_resp_entry_vmid;
  wire g_io_resp_bits_toHptw_resp_entry_n;  wire i_io_resp_bits_toHptw_resp_entry_n;
  wire [1:0] g_io_resp_bits_toHptw_resp_entry_pbmt;  wire [1:0] i_io_resp_bits_toHptw_resp_entry_pbmt;
  wire [37:0] g_io_resp_bits_toHptw_resp_entry_ppn;  wire [37:0] i_io_resp_bits_toHptw_resp_entry_ppn;
  wire g_io_resp_bits_toHptw_resp_entry_perm_d;  wire i_io_resp_bits_toHptw_resp_entry_perm_d;
  wire g_io_resp_bits_toHptw_resp_entry_perm_a;  wire i_io_resp_bits_toHptw_resp_entry_perm_a;
  wire g_io_resp_bits_toHptw_resp_entry_perm_g;  wire i_io_resp_bits_toHptw_resp_entry_perm_g;
  wire g_io_resp_bits_toHptw_resp_entry_perm_u;  wire i_io_resp_bits_toHptw_resp_entry_perm_u;
  wire g_io_resp_bits_toHptw_resp_entry_perm_x;  wire i_io_resp_bits_toHptw_resp_entry_perm_x;
  wire g_io_resp_bits_toHptw_resp_entry_perm_w;  wire i_io_resp_bits_toHptw_resp_entry_perm_w;
  wire g_io_resp_bits_toHptw_resp_entry_perm_r;  wire i_io_resp_bits_toHptw_resp_entry_perm_r;
  wire [1:0] g_io_resp_bits_toHptw_resp_entry_level;  wire [1:0] i_io_resp_bits_toHptw_resp_entry_level;
  wire g_io_resp_bits_toHptw_resp_gpf;  wire i_io_resp_bits_toHptw_resp_gpf;
  wire g_io_resp_bits_toHptw_bypassed;  wire i_io_resp_bits_toHptw_bypassed;
  wire [5:0] g_io_perf_0_value;  wire [5:0] i_io_perf_0_value;
  wire [5:0] g_io_perf_1_value;  wire [5:0] i_io_perf_1_value;
  wire [5:0] g_io_perf_2_value;  wire [5:0] i_io_perf_2_value;
  wire [5:0] g_io_perf_3_value;  wire [5:0] i_io_perf_3_value;
  wire [5:0] g_io_perf_4_value;  wire [5:0] i_io_perf_4_value;
  wire [5:0] g_io_perf_5_value;  wire [5:0] i_io_perf_5_value;
  wire [5:0] g_io_perf_6_value;  wire [5:0] i_io_perf_6_value;
  wire [5:0] g_io_perf_7_value;  wire [5:0] i_io_perf_7_value;
  wire g_boreChildrenBd_bore_ack;  wire i_boreChildrenBd_bore_ack;
  wire [199:0] g_boreChildrenBd_bore_outdata;  wire [199:0] i_boreChildrenBd_bore_outdata;
  wire g_boreChildrenBd_bore_1_ack;  wire i_boreChildrenBd_bore_1_ack;
  wire [227:0] g_boreChildrenBd_bore_1_outdata;  wire [227:0] i_boreChildrenBd_bore_1_outdata;

  PtwCache u_g (.clock(clock), .reset(reset), .io_csr_mPBMTE(io_csr_mPBMTE), .io_csr_hPBMTE(io_csr_hPBMTE), .io_req_valid(io_req_valid), .io_req_bits_req_info_vpn(io_req_bits_req_info_vpn), .io_req_bits_req_info_s2xlate(io_req_bits_req_info_s2xlate), .io_req_bits_req_info_source(io_req_bits_req_info_source), .io_req_bits_isFirst(io_req_bits_isFirst), .io_req_bits_isHptwReq(io_req_bits_isHptwReq), .io_req_bits_hptwId(io_req_bits_hptwId), .io_resp_ready(io_resp_ready), .io_refill_valid(io_refill_valid), .io_refill_bits_ptes(io_refill_bits_ptes), .io_refill_bits_levelOH_sp(io_refill_bits_levelOH_sp), .io_refill_bits_levelOH_l0(io_refill_bits_levelOH_l0), .io_refill_bits_levelOH_l1(io_refill_bits_levelOH_l1), .io_refill_bits_levelOH_l2(io_refill_bits_levelOH_l2), .io_refill_bits_levelOH_l3(io_refill_bits_levelOH_l3), .io_refill_bits_req_info_dup_0_vpn(io_refill_bits_req_info_dup_0_vpn), .io_refill_bits_req_info_dup_0_s2xlate(io_refill_bits_req_info_dup_0_s2xlate), .io_refill_bits_req_info_dup_0_source(io_refill_bits_req_info_dup_0_source), .io_refill_bits_req_info_dup_1_vpn(io_refill_bits_req_info_dup_1_vpn), .io_refill_bits_req_info_dup_1_s2xlate(io_refill_bits_req_info_dup_1_s2xlate), .io_refill_bits_req_info_dup_1_source(io_refill_bits_req_info_dup_1_source), .io_refill_bits_req_info_dup_2_vpn(io_refill_bits_req_info_dup_2_vpn), .io_refill_bits_req_info_dup_2_s2xlate(io_refill_bits_req_info_dup_2_s2xlate), .io_refill_bits_req_info_dup_2_source(io_refill_bits_req_info_dup_2_source), .io_refill_bits_level_dup_0(io_refill_bits_level_dup_0), .io_refill_bits_level_dup_2(io_refill_bits_level_dup_2), .io_refill_bits_sel_pte_dup_0(io_refill_bits_sel_pte_dup_0), .io_refill_bits_sel_pte_dup_2(io_refill_bits_sel_pte_dup_2), .io_sfence_dup_0_valid(io_sfence_dup_0_valid), .io_sfence_dup_0_bits_rs1(io_sfence_dup_0_bits_rs1), .io_sfence_dup_0_bits_rs2(io_sfence_dup_0_bits_rs2), .io_sfence_dup_0_bits_addr(io_sfence_dup_0_bits_addr), .io_sfence_dup_0_bits_id(io_sfence_dup_0_bits_id), .io_sfence_dup_0_bits_hv(io_sfence_dup_0_bits_hv), .io_sfence_dup_0_bits_hg(io_sfence_dup_0_bits_hg), .io_sfence_dup_1_valid(io_sfence_dup_1_valid), .io_sfence_dup_1_bits_id(io_sfence_dup_1_bits_id), .io_sfence_dup_2_valid(io_sfence_dup_2_valid), .io_sfence_dup_2_bits_rs1(io_sfence_dup_2_bits_rs1), .io_sfence_dup_2_bits_rs2(io_sfence_dup_2_bits_rs2), .io_sfence_dup_2_bits_id(io_sfence_dup_2_bits_id), .io_csr_dup_0_satp_asid(io_csr_dup_0_satp_asid), .io_csr_dup_0_satp_changed(io_csr_dup_0_satp_changed), .io_csr_dup_0_vsatp_asid(io_csr_dup_0_vsatp_asid), .io_csr_dup_0_vsatp_changed(io_csr_dup_0_vsatp_changed), .io_csr_dup_0_hgatp_mode(io_csr_dup_0_hgatp_mode), .io_csr_dup_0_hgatp_vmid(io_csr_dup_0_hgatp_vmid), .io_csr_dup_0_hgatp_changed(io_csr_dup_0_hgatp_changed), .io_csr_dup_0_priv_virt(io_csr_dup_0_priv_virt), .io_csr_dup_1_satp_asid(io_csr_dup_1_satp_asid), .io_csr_dup_1_satp_changed(io_csr_dup_1_satp_changed), .io_csr_dup_1_vsatp_asid(io_csr_dup_1_vsatp_asid), .io_csr_dup_1_vsatp_changed(io_csr_dup_1_vsatp_changed), .io_csr_dup_1_hgatp_mode(io_csr_dup_1_hgatp_mode), .io_csr_dup_1_hgatp_vmid(io_csr_dup_1_hgatp_vmid), .io_csr_dup_1_hgatp_changed(io_csr_dup_1_hgatp_changed), .io_csr_dup_1_priv_virt(io_csr_dup_1_priv_virt), .io_csr_dup_2_satp_asid(io_csr_dup_2_satp_asid), .io_csr_dup_2_satp_changed(io_csr_dup_2_satp_changed), .io_csr_dup_2_vsatp_asid(io_csr_dup_2_vsatp_asid), .io_csr_dup_2_vsatp_changed(io_csr_dup_2_vsatp_changed), .io_csr_dup_2_hgatp_mode(io_csr_dup_2_hgatp_mode), .io_csr_dup_2_hgatp_vmid(io_csr_dup_2_hgatp_vmid), .io_csr_dup_2_hgatp_changed(io_csr_dup_2_hgatp_changed), .io_csr_dup_2_priv_virt(io_csr_dup_2_priv_virt), .boreChildrenBd_bore_array(boreChildrenBd_bore_array), .boreChildrenBd_bore_all(boreChildrenBd_bore_all), .boreChildrenBd_bore_req(boreChildrenBd_bore_req), .boreChildrenBd_bore_writeen(boreChildrenBd_bore_writeen), .boreChildrenBd_bore_be(boreChildrenBd_bore_be), .boreChildrenBd_bore_addr(boreChildrenBd_bore_addr), .boreChildrenBd_bore_indata(boreChildrenBd_bore_indata), .boreChildrenBd_bore_readen(boreChildrenBd_bore_readen), .boreChildrenBd_bore_addr_rd(boreChildrenBd_bore_addr_rd), .boreChildrenBd_bore_1_array(boreChildrenBd_bore_1_array), .boreChildrenBd_bore_1_all(boreChildrenBd_bore_1_all), .boreChildrenBd_bore_1_req(boreChildrenBd_bore_1_req), .boreChildrenBd_bore_1_writeen(boreChildrenBd_bore_1_writeen), .boreChildrenBd_bore_1_be(boreChildrenBd_bore_1_be), .boreChildrenBd_bore_1_addr(boreChildrenBd_bore_1_addr), .boreChildrenBd_bore_1_indata(boreChildrenBd_bore_1_indata), .boreChildrenBd_bore_1_readen(boreChildrenBd_bore_1_readen), .boreChildrenBd_bore_1_addr_rd(boreChildrenBd_bore_1_addr_rd), .sigFromSrams_bore_ram_hold(sigFromSrams_bore_ram_hold), .sigFromSrams_bore_ram_bypass(sigFromSrams_bore_ram_bypass), .sigFromSrams_bore_ram_bp_clken(sigFromSrams_bore_ram_bp_clken), .sigFromSrams_bore_ram_aux_clk(sigFromSrams_bore_ram_aux_clk), .sigFromSrams_bore_ram_aux_ckbp(sigFromSrams_bore_ram_aux_ckbp), .sigFromSrams_bore_ram_mcp_hold(sigFromSrams_bore_ram_mcp_hold), .sigFromSrams_bore_cgen(sigFromSrams_bore_cgen), .sigFromSrams_bore_1_ram_hold(sigFromSrams_bore_1_ram_hold), .sigFromSrams_bore_1_ram_bypass(sigFromSrams_bore_1_ram_bypass), .sigFromSrams_bore_1_ram_bp_clken(sigFromSrams_bore_1_ram_bp_clken), .sigFromSrams_bore_1_ram_aux_clk(sigFromSrams_bore_1_ram_aux_clk), .sigFromSrams_bore_1_ram_aux_ckbp(sigFromSrams_bore_1_ram_aux_ckbp), .sigFromSrams_bore_1_ram_mcp_hold(sigFromSrams_bore_1_ram_mcp_hold), .sigFromSrams_bore_1_cgen(sigFromSrams_bore_1_cgen), .sigFromSrams_bore_2_ram_hold(sigFromSrams_bore_2_ram_hold), .sigFromSrams_bore_2_ram_bypass(sigFromSrams_bore_2_ram_bypass), .sigFromSrams_bore_2_ram_bp_clken(sigFromSrams_bore_2_ram_bp_clken), .sigFromSrams_bore_2_ram_aux_clk(sigFromSrams_bore_2_ram_aux_clk), .sigFromSrams_bore_2_ram_aux_ckbp(sigFromSrams_bore_2_ram_aux_ckbp), .sigFromSrams_bore_2_ram_mcp_hold(sigFromSrams_bore_2_ram_mcp_hold), .sigFromSrams_bore_2_cgen(sigFromSrams_bore_2_cgen), .sigFromSrams_bore_3_ram_hold(sigFromSrams_bore_3_ram_hold), .sigFromSrams_bore_3_ram_bypass(sigFromSrams_bore_3_ram_bypass), .sigFromSrams_bore_3_ram_bp_clken(sigFromSrams_bore_3_ram_bp_clken), .sigFromSrams_bore_3_ram_aux_clk(sigFromSrams_bore_3_ram_aux_clk), .sigFromSrams_bore_3_ram_aux_ckbp(sigFromSrams_bore_3_ram_aux_ckbp), .sigFromSrams_bore_3_ram_mcp_hold(sigFromSrams_bore_3_ram_mcp_hold), .sigFromSrams_bore_3_cgen(sigFromSrams_bore_3_cgen), .sigFromSrams_bore_4_ram_hold(sigFromSrams_bore_4_ram_hold), .sigFromSrams_bore_4_ram_bypass(sigFromSrams_bore_4_ram_bypass), .sigFromSrams_bore_4_ram_bp_clken(sigFromSrams_bore_4_ram_bp_clken), .sigFromSrams_bore_4_ram_aux_clk(sigFromSrams_bore_4_ram_aux_clk), .sigFromSrams_bore_4_ram_aux_ckbp(sigFromSrams_bore_4_ram_aux_ckbp), .sigFromSrams_bore_4_ram_mcp_hold(sigFromSrams_bore_4_ram_mcp_hold), .sigFromSrams_bore_4_cgen(sigFromSrams_bore_4_cgen), .sigFromSrams_bore_5_ram_hold(sigFromSrams_bore_5_ram_hold), .sigFromSrams_bore_5_ram_bypass(sigFromSrams_bore_5_ram_bypass), .sigFromSrams_bore_5_ram_bp_clken(sigFromSrams_bore_5_ram_bp_clken), .sigFromSrams_bore_5_ram_aux_clk(sigFromSrams_bore_5_ram_aux_clk), .sigFromSrams_bore_5_ram_aux_ckbp(sigFromSrams_bore_5_ram_aux_ckbp), .sigFromSrams_bore_5_ram_mcp_hold(sigFromSrams_bore_5_ram_mcp_hold), .sigFromSrams_bore_5_cgen(sigFromSrams_bore_5_cgen), .sigFromSrams_bore_6_ram_hold(sigFromSrams_bore_6_ram_hold), .sigFromSrams_bore_6_ram_bypass(sigFromSrams_bore_6_ram_bypass), .sigFromSrams_bore_6_ram_bp_clken(sigFromSrams_bore_6_ram_bp_clken), .sigFromSrams_bore_6_ram_aux_clk(sigFromSrams_bore_6_ram_aux_clk), .sigFromSrams_bore_6_ram_aux_ckbp(sigFromSrams_bore_6_ram_aux_ckbp), .sigFromSrams_bore_6_ram_mcp_hold(sigFromSrams_bore_6_ram_mcp_hold), .sigFromSrams_bore_6_cgen(sigFromSrams_bore_6_cgen), .sigFromSrams_bore_7_ram_hold(sigFromSrams_bore_7_ram_hold), .sigFromSrams_bore_7_ram_bypass(sigFromSrams_bore_7_ram_bypass), .sigFromSrams_bore_7_ram_bp_clken(sigFromSrams_bore_7_ram_bp_clken), .sigFromSrams_bore_7_ram_aux_clk(sigFromSrams_bore_7_ram_aux_clk), .sigFromSrams_bore_7_ram_aux_ckbp(sigFromSrams_bore_7_ram_aux_ckbp), .sigFromSrams_bore_7_ram_mcp_hold(sigFromSrams_bore_7_ram_mcp_hold), .sigFromSrams_bore_7_cgen(sigFromSrams_bore_7_cgen), .sigFromSrams_bore_8_ram_hold(sigFromSrams_bore_8_ram_hold), .sigFromSrams_bore_8_ram_bypass(sigFromSrams_bore_8_ram_bypass), .sigFromSrams_bore_8_ram_bp_clken(sigFromSrams_bore_8_ram_bp_clken), .sigFromSrams_bore_8_ram_aux_clk(sigFromSrams_bore_8_ram_aux_clk), .sigFromSrams_bore_8_ram_aux_ckbp(sigFromSrams_bore_8_ram_aux_ckbp), .sigFromSrams_bore_8_ram_mcp_hold(sigFromSrams_bore_8_ram_mcp_hold), .sigFromSrams_bore_8_cgen(sigFromSrams_bore_8_cgen), .sigFromSrams_bore_9_ram_hold(sigFromSrams_bore_9_ram_hold), .sigFromSrams_bore_9_ram_bypass(sigFromSrams_bore_9_ram_bypass), .sigFromSrams_bore_9_ram_bp_clken(sigFromSrams_bore_9_ram_bp_clken), .sigFromSrams_bore_9_ram_aux_clk(sigFromSrams_bore_9_ram_aux_clk), .sigFromSrams_bore_9_ram_aux_ckbp(sigFromSrams_bore_9_ram_aux_ckbp), .sigFromSrams_bore_9_ram_mcp_hold(sigFromSrams_bore_9_ram_mcp_hold), .sigFromSrams_bore_9_cgen(sigFromSrams_bore_9_cgen), .sigFromSrams_bore_10_ram_hold(sigFromSrams_bore_10_ram_hold), .sigFromSrams_bore_10_ram_bypass(sigFromSrams_bore_10_ram_bypass), .sigFromSrams_bore_10_ram_bp_clken(sigFromSrams_bore_10_ram_bp_clken), .sigFromSrams_bore_10_ram_aux_clk(sigFromSrams_bore_10_ram_aux_clk), .sigFromSrams_bore_10_ram_aux_ckbp(sigFromSrams_bore_10_ram_aux_ckbp), .sigFromSrams_bore_10_ram_mcp_hold(sigFromSrams_bore_10_ram_mcp_hold), .sigFromSrams_bore_10_cgen(sigFromSrams_bore_10_cgen), .sigFromSrams_bore_11_ram_hold(sigFromSrams_bore_11_ram_hold), .sigFromSrams_bore_11_ram_bypass(sigFromSrams_bore_11_ram_bypass), .sigFromSrams_bore_11_ram_bp_clken(sigFromSrams_bore_11_ram_bp_clken), .sigFromSrams_bore_11_ram_aux_clk(sigFromSrams_bore_11_ram_aux_clk), .sigFromSrams_bore_11_ram_aux_ckbp(sigFromSrams_bore_11_ram_aux_ckbp), .sigFromSrams_bore_11_ram_mcp_hold(sigFromSrams_bore_11_ram_mcp_hold), .sigFromSrams_bore_11_cgen(sigFromSrams_bore_11_cgen), .cg_bore_cgen(cg_bore_cgen), .io_req_ready(g_io_req_ready), .io_resp_valid(g_io_resp_valid), .io_resp_bits_req_info_vpn(g_io_resp_bits_req_info_vpn), .io_resp_bits_req_info_s2xlate(g_io_resp_bits_req_info_s2xlate), .io_resp_bits_req_info_source(g_io_resp_bits_req_info_source), .io_resp_bits_isFirst(g_io_resp_bits_isFirst), .io_resp_bits_hit(g_io_resp_bits_hit), .io_resp_bits_prefetch(g_io_resp_bits_prefetch), .io_resp_bits_bypassed(g_io_resp_bits_bypassed), .io_resp_bits_toFsm_l3Hit(g_io_resp_bits_toFsm_l3Hit), .io_resp_bits_toFsm_l2Hit(g_io_resp_bits_toFsm_l2Hit), .io_resp_bits_toFsm_l1Hit(g_io_resp_bits_toFsm_l1Hit), .io_resp_bits_toFsm_ppn(g_io_resp_bits_toFsm_ppn), .io_resp_bits_toFsm_stage1Hit(g_io_resp_bits_toFsm_stage1Hit), .io_resp_bits_stage1_entry_0_tag(g_io_resp_bits_stage1_entry_0_tag), .io_resp_bits_stage1_entry_0_asid(g_io_resp_bits_stage1_entry_0_asid), .io_resp_bits_stage1_entry_0_vmid(g_io_resp_bits_stage1_entry_0_vmid), .io_resp_bits_stage1_entry_0_n(g_io_resp_bits_stage1_entry_0_n), .io_resp_bits_stage1_entry_0_pbmt(g_io_resp_bits_stage1_entry_0_pbmt), .io_resp_bits_stage1_entry_0_perm_d(g_io_resp_bits_stage1_entry_0_perm_d), .io_resp_bits_stage1_entry_0_perm_a(g_io_resp_bits_stage1_entry_0_perm_a), .io_resp_bits_stage1_entry_0_perm_g(g_io_resp_bits_stage1_entry_0_perm_g), .io_resp_bits_stage1_entry_0_perm_u(g_io_resp_bits_stage1_entry_0_perm_u), .io_resp_bits_stage1_entry_0_perm_x(g_io_resp_bits_stage1_entry_0_perm_x), .io_resp_bits_stage1_entry_0_perm_w(g_io_resp_bits_stage1_entry_0_perm_w), .io_resp_bits_stage1_entry_0_perm_r(g_io_resp_bits_stage1_entry_0_perm_r), .io_resp_bits_stage1_entry_0_level(g_io_resp_bits_stage1_entry_0_level), .io_resp_bits_stage1_entry_0_v(g_io_resp_bits_stage1_entry_0_v), .io_resp_bits_stage1_entry_0_ppn(g_io_resp_bits_stage1_entry_0_ppn), .io_resp_bits_stage1_entry_0_ppn_low(g_io_resp_bits_stage1_entry_0_ppn_low), .io_resp_bits_stage1_entry_0_pf(g_io_resp_bits_stage1_entry_0_pf), .io_resp_bits_stage1_entry_1_tag(g_io_resp_bits_stage1_entry_1_tag), .io_resp_bits_stage1_entry_1_asid(g_io_resp_bits_stage1_entry_1_asid), .io_resp_bits_stage1_entry_1_vmid(g_io_resp_bits_stage1_entry_1_vmid), .io_resp_bits_stage1_entry_1_n(g_io_resp_bits_stage1_entry_1_n), .io_resp_bits_stage1_entry_1_pbmt(g_io_resp_bits_stage1_entry_1_pbmt), .io_resp_bits_stage1_entry_1_perm_d(g_io_resp_bits_stage1_entry_1_perm_d), .io_resp_bits_stage1_entry_1_perm_a(g_io_resp_bits_stage1_entry_1_perm_a), .io_resp_bits_stage1_entry_1_perm_g(g_io_resp_bits_stage1_entry_1_perm_g), .io_resp_bits_stage1_entry_1_perm_u(g_io_resp_bits_stage1_entry_1_perm_u), .io_resp_bits_stage1_entry_1_perm_x(g_io_resp_bits_stage1_entry_1_perm_x), .io_resp_bits_stage1_entry_1_perm_w(g_io_resp_bits_stage1_entry_1_perm_w), .io_resp_bits_stage1_entry_1_perm_r(g_io_resp_bits_stage1_entry_1_perm_r), .io_resp_bits_stage1_entry_1_level(g_io_resp_bits_stage1_entry_1_level), .io_resp_bits_stage1_entry_1_v(g_io_resp_bits_stage1_entry_1_v), .io_resp_bits_stage1_entry_1_ppn(g_io_resp_bits_stage1_entry_1_ppn), .io_resp_bits_stage1_entry_1_ppn_low(g_io_resp_bits_stage1_entry_1_ppn_low), .io_resp_bits_stage1_entry_1_pf(g_io_resp_bits_stage1_entry_1_pf), .io_resp_bits_stage1_entry_2_tag(g_io_resp_bits_stage1_entry_2_tag), .io_resp_bits_stage1_entry_2_asid(g_io_resp_bits_stage1_entry_2_asid), .io_resp_bits_stage1_entry_2_vmid(g_io_resp_bits_stage1_entry_2_vmid), .io_resp_bits_stage1_entry_2_n(g_io_resp_bits_stage1_entry_2_n), .io_resp_bits_stage1_entry_2_pbmt(g_io_resp_bits_stage1_entry_2_pbmt), .io_resp_bits_stage1_entry_2_perm_d(g_io_resp_bits_stage1_entry_2_perm_d), .io_resp_bits_stage1_entry_2_perm_a(g_io_resp_bits_stage1_entry_2_perm_a), .io_resp_bits_stage1_entry_2_perm_g(g_io_resp_bits_stage1_entry_2_perm_g), .io_resp_bits_stage1_entry_2_perm_u(g_io_resp_bits_stage1_entry_2_perm_u), .io_resp_bits_stage1_entry_2_perm_x(g_io_resp_bits_stage1_entry_2_perm_x), .io_resp_bits_stage1_entry_2_perm_w(g_io_resp_bits_stage1_entry_2_perm_w), .io_resp_bits_stage1_entry_2_perm_r(g_io_resp_bits_stage1_entry_2_perm_r), .io_resp_bits_stage1_entry_2_level(g_io_resp_bits_stage1_entry_2_level), .io_resp_bits_stage1_entry_2_v(g_io_resp_bits_stage1_entry_2_v), .io_resp_bits_stage1_entry_2_ppn(g_io_resp_bits_stage1_entry_2_ppn), .io_resp_bits_stage1_entry_2_ppn_low(g_io_resp_bits_stage1_entry_2_ppn_low), .io_resp_bits_stage1_entry_2_pf(g_io_resp_bits_stage1_entry_2_pf), .io_resp_bits_stage1_entry_3_tag(g_io_resp_bits_stage1_entry_3_tag), .io_resp_bits_stage1_entry_3_asid(g_io_resp_bits_stage1_entry_3_asid), .io_resp_bits_stage1_entry_3_vmid(g_io_resp_bits_stage1_entry_3_vmid), .io_resp_bits_stage1_entry_3_n(g_io_resp_bits_stage1_entry_3_n), .io_resp_bits_stage1_entry_3_pbmt(g_io_resp_bits_stage1_entry_3_pbmt), .io_resp_bits_stage1_entry_3_perm_d(g_io_resp_bits_stage1_entry_3_perm_d), .io_resp_bits_stage1_entry_3_perm_a(g_io_resp_bits_stage1_entry_3_perm_a), .io_resp_bits_stage1_entry_3_perm_g(g_io_resp_bits_stage1_entry_3_perm_g), .io_resp_bits_stage1_entry_3_perm_u(g_io_resp_bits_stage1_entry_3_perm_u), .io_resp_bits_stage1_entry_3_perm_x(g_io_resp_bits_stage1_entry_3_perm_x), .io_resp_bits_stage1_entry_3_perm_w(g_io_resp_bits_stage1_entry_3_perm_w), .io_resp_bits_stage1_entry_3_perm_r(g_io_resp_bits_stage1_entry_3_perm_r), .io_resp_bits_stage1_entry_3_level(g_io_resp_bits_stage1_entry_3_level), .io_resp_bits_stage1_entry_3_v(g_io_resp_bits_stage1_entry_3_v), .io_resp_bits_stage1_entry_3_ppn(g_io_resp_bits_stage1_entry_3_ppn), .io_resp_bits_stage1_entry_3_ppn_low(g_io_resp_bits_stage1_entry_3_ppn_low), .io_resp_bits_stage1_entry_3_pf(g_io_resp_bits_stage1_entry_3_pf), .io_resp_bits_stage1_entry_4_tag(g_io_resp_bits_stage1_entry_4_tag), .io_resp_bits_stage1_entry_4_asid(g_io_resp_bits_stage1_entry_4_asid), .io_resp_bits_stage1_entry_4_vmid(g_io_resp_bits_stage1_entry_4_vmid), .io_resp_bits_stage1_entry_4_n(g_io_resp_bits_stage1_entry_4_n), .io_resp_bits_stage1_entry_4_pbmt(g_io_resp_bits_stage1_entry_4_pbmt), .io_resp_bits_stage1_entry_4_perm_d(g_io_resp_bits_stage1_entry_4_perm_d), .io_resp_bits_stage1_entry_4_perm_a(g_io_resp_bits_stage1_entry_4_perm_a), .io_resp_bits_stage1_entry_4_perm_g(g_io_resp_bits_stage1_entry_4_perm_g), .io_resp_bits_stage1_entry_4_perm_u(g_io_resp_bits_stage1_entry_4_perm_u), .io_resp_bits_stage1_entry_4_perm_x(g_io_resp_bits_stage1_entry_4_perm_x), .io_resp_bits_stage1_entry_4_perm_w(g_io_resp_bits_stage1_entry_4_perm_w), .io_resp_bits_stage1_entry_4_perm_r(g_io_resp_bits_stage1_entry_4_perm_r), .io_resp_bits_stage1_entry_4_level(g_io_resp_bits_stage1_entry_4_level), .io_resp_bits_stage1_entry_4_v(g_io_resp_bits_stage1_entry_4_v), .io_resp_bits_stage1_entry_4_ppn(g_io_resp_bits_stage1_entry_4_ppn), .io_resp_bits_stage1_entry_4_ppn_low(g_io_resp_bits_stage1_entry_4_ppn_low), .io_resp_bits_stage1_entry_4_pf(g_io_resp_bits_stage1_entry_4_pf), .io_resp_bits_stage1_entry_5_tag(g_io_resp_bits_stage1_entry_5_tag), .io_resp_bits_stage1_entry_5_asid(g_io_resp_bits_stage1_entry_5_asid), .io_resp_bits_stage1_entry_5_vmid(g_io_resp_bits_stage1_entry_5_vmid), .io_resp_bits_stage1_entry_5_n(g_io_resp_bits_stage1_entry_5_n), .io_resp_bits_stage1_entry_5_pbmt(g_io_resp_bits_stage1_entry_5_pbmt), .io_resp_bits_stage1_entry_5_perm_d(g_io_resp_bits_stage1_entry_5_perm_d), .io_resp_bits_stage1_entry_5_perm_a(g_io_resp_bits_stage1_entry_5_perm_a), .io_resp_bits_stage1_entry_5_perm_g(g_io_resp_bits_stage1_entry_5_perm_g), .io_resp_bits_stage1_entry_5_perm_u(g_io_resp_bits_stage1_entry_5_perm_u), .io_resp_bits_stage1_entry_5_perm_x(g_io_resp_bits_stage1_entry_5_perm_x), .io_resp_bits_stage1_entry_5_perm_w(g_io_resp_bits_stage1_entry_5_perm_w), .io_resp_bits_stage1_entry_5_perm_r(g_io_resp_bits_stage1_entry_5_perm_r), .io_resp_bits_stage1_entry_5_level(g_io_resp_bits_stage1_entry_5_level), .io_resp_bits_stage1_entry_5_v(g_io_resp_bits_stage1_entry_5_v), .io_resp_bits_stage1_entry_5_ppn(g_io_resp_bits_stage1_entry_5_ppn), .io_resp_bits_stage1_entry_5_ppn_low(g_io_resp_bits_stage1_entry_5_ppn_low), .io_resp_bits_stage1_entry_5_pf(g_io_resp_bits_stage1_entry_5_pf), .io_resp_bits_stage1_entry_6_tag(g_io_resp_bits_stage1_entry_6_tag), .io_resp_bits_stage1_entry_6_asid(g_io_resp_bits_stage1_entry_6_asid), .io_resp_bits_stage1_entry_6_vmid(g_io_resp_bits_stage1_entry_6_vmid), .io_resp_bits_stage1_entry_6_n(g_io_resp_bits_stage1_entry_6_n), .io_resp_bits_stage1_entry_6_pbmt(g_io_resp_bits_stage1_entry_6_pbmt), .io_resp_bits_stage1_entry_6_perm_d(g_io_resp_bits_stage1_entry_6_perm_d), .io_resp_bits_stage1_entry_6_perm_a(g_io_resp_bits_stage1_entry_6_perm_a), .io_resp_bits_stage1_entry_6_perm_g(g_io_resp_bits_stage1_entry_6_perm_g), .io_resp_bits_stage1_entry_6_perm_u(g_io_resp_bits_stage1_entry_6_perm_u), .io_resp_bits_stage1_entry_6_perm_x(g_io_resp_bits_stage1_entry_6_perm_x), .io_resp_bits_stage1_entry_6_perm_w(g_io_resp_bits_stage1_entry_6_perm_w), .io_resp_bits_stage1_entry_6_perm_r(g_io_resp_bits_stage1_entry_6_perm_r), .io_resp_bits_stage1_entry_6_level(g_io_resp_bits_stage1_entry_6_level), .io_resp_bits_stage1_entry_6_v(g_io_resp_bits_stage1_entry_6_v), .io_resp_bits_stage1_entry_6_ppn(g_io_resp_bits_stage1_entry_6_ppn), .io_resp_bits_stage1_entry_6_ppn_low(g_io_resp_bits_stage1_entry_6_ppn_low), .io_resp_bits_stage1_entry_6_pf(g_io_resp_bits_stage1_entry_6_pf), .io_resp_bits_stage1_entry_7_tag(g_io_resp_bits_stage1_entry_7_tag), .io_resp_bits_stage1_entry_7_asid(g_io_resp_bits_stage1_entry_7_asid), .io_resp_bits_stage1_entry_7_vmid(g_io_resp_bits_stage1_entry_7_vmid), .io_resp_bits_stage1_entry_7_n(g_io_resp_bits_stage1_entry_7_n), .io_resp_bits_stage1_entry_7_pbmt(g_io_resp_bits_stage1_entry_7_pbmt), .io_resp_bits_stage1_entry_7_perm_d(g_io_resp_bits_stage1_entry_7_perm_d), .io_resp_bits_stage1_entry_7_perm_a(g_io_resp_bits_stage1_entry_7_perm_a), .io_resp_bits_stage1_entry_7_perm_g(g_io_resp_bits_stage1_entry_7_perm_g), .io_resp_bits_stage1_entry_7_perm_u(g_io_resp_bits_stage1_entry_7_perm_u), .io_resp_bits_stage1_entry_7_perm_x(g_io_resp_bits_stage1_entry_7_perm_x), .io_resp_bits_stage1_entry_7_perm_w(g_io_resp_bits_stage1_entry_7_perm_w), .io_resp_bits_stage1_entry_7_perm_r(g_io_resp_bits_stage1_entry_7_perm_r), .io_resp_bits_stage1_entry_7_level(g_io_resp_bits_stage1_entry_7_level), .io_resp_bits_stage1_entry_7_v(g_io_resp_bits_stage1_entry_7_v), .io_resp_bits_stage1_entry_7_ppn(g_io_resp_bits_stage1_entry_7_ppn), .io_resp_bits_stage1_entry_7_ppn_low(g_io_resp_bits_stage1_entry_7_ppn_low), .io_resp_bits_stage1_entry_7_pf(g_io_resp_bits_stage1_entry_7_pf), .io_resp_bits_stage1_pteidx_0(g_io_resp_bits_stage1_pteidx_0), .io_resp_bits_stage1_pteidx_1(g_io_resp_bits_stage1_pteidx_1), .io_resp_bits_stage1_pteidx_2(g_io_resp_bits_stage1_pteidx_2), .io_resp_bits_stage1_pteidx_3(g_io_resp_bits_stage1_pteidx_3), .io_resp_bits_stage1_pteidx_4(g_io_resp_bits_stage1_pteidx_4), .io_resp_bits_stage1_pteidx_5(g_io_resp_bits_stage1_pteidx_5), .io_resp_bits_stage1_pteidx_6(g_io_resp_bits_stage1_pteidx_6), .io_resp_bits_stage1_pteidx_7(g_io_resp_bits_stage1_pteidx_7), .io_resp_bits_stage1_not_super(g_io_resp_bits_stage1_not_super), .io_resp_bits_isHptwReq(g_io_resp_bits_isHptwReq), .io_resp_bits_toHptw_l3Hit(g_io_resp_bits_toHptw_l3Hit), .io_resp_bits_toHptw_l2Hit(g_io_resp_bits_toHptw_l2Hit), .io_resp_bits_toHptw_l1Hit(g_io_resp_bits_toHptw_l1Hit), .io_resp_bits_toHptw_ppn(g_io_resp_bits_toHptw_ppn), .io_resp_bits_toHptw_id(g_io_resp_bits_toHptw_id), .io_resp_bits_toHptw_resp_entry_tag(g_io_resp_bits_toHptw_resp_entry_tag), .io_resp_bits_toHptw_resp_entry_vmid(g_io_resp_bits_toHptw_resp_entry_vmid), .io_resp_bits_toHptw_resp_entry_n(g_io_resp_bits_toHptw_resp_entry_n), .io_resp_bits_toHptw_resp_entry_pbmt(g_io_resp_bits_toHptw_resp_entry_pbmt), .io_resp_bits_toHptw_resp_entry_ppn(g_io_resp_bits_toHptw_resp_entry_ppn), .io_resp_bits_toHptw_resp_entry_perm_d(g_io_resp_bits_toHptw_resp_entry_perm_d), .io_resp_bits_toHptw_resp_entry_perm_a(g_io_resp_bits_toHptw_resp_entry_perm_a), .io_resp_bits_toHptw_resp_entry_perm_g(g_io_resp_bits_toHptw_resp_entry_perm_g), .io_resp_bits_toHptw_resp_entry_perm_u(g_io_resp_bits_toHptw_resp_entry_perm_u), .io_resp_bits_toHptw_resp_entry_perm_x(g_io_resp_bits_toHptw_resp_entry_perm_x), .io_resp_bits_toHptw_resp_entry_perm_w(g_io_resp_bits_toHptw_resp_entry_perm_w), .io_resp_bits_toHptw_resp_entry_perm_r(g_io_resp_bits_toHptw_resp_entry_perm_r), .io_resp_bits_toHptw_resp_entry_level(g_io_resp_bits_toHptw_resp_entry_level), .io_resp_bits_toHptw_resp_gpf(g_io_resp_bits_toHptw_resp_gpf), .io_resp_bits_toHptw_bypassed(g_io_resp_bits_toHptw_bypassed), .io_perf_0_value(g_io_perf_0_value), .io_perf_1_value(g_io_perf_1_value), .io_perf_2_value(g_io_perf_2_value), .io_perf_3_value(g_io_perf_3_value), .io_perf_4_value(g_io_perf_4_value), .io_perf_5_value(g_io_perf_5_value), .io_perf_6_value(g_io_perf_6_value), .io_perf_7_value(g_io_perf_7_value), .boreChildrenBd_bore_ack(g_boreChildrenBd_bore_ack), .boreChildrenBd_bore_outdata(g_boreChildrenBd_bore_outdata), .boreChildrenBd_bore_1_ack(g_boreChildrenBd_bore_1_ack), .boreChildrenBd_bore_1_outdata(g_boreChildrenBd_bore_1_outdata));

  PtwCache_xs u_i (.clock(clock), .reset(reset), .io_csr_mPBMTE(io_csr_mPBMTE), .io_csr_hPBMTE(io_csr_hPBMTE), .io_req_valid(io_req_valid), .io_req_bits_req_info_vpn(io_req_bits_req_info_vpn), .io_req_bits_req_info_s2xlate(io_req_bits_req_info_s2xlate), .io_req_bits_req_info_source(io_req_bits_req_info_source), .io_req_bits_isFirst(io_req_bits_isFirst), .io_req_bits_isHptwReq(io_req_bits_isHptwReq), .io_req_bits_hptwId(io_req_bits_hptwId), .io_resp_ready(io_resp_ready), .io_refill_valid(io_refill_valid), .io_refill_bits_ptes(io_refill_bits_ptes), .io_refill_bits_levelOH_sp(io_refill_bits_levelOH_sp), .io_refill_bits_levelOH_l0(io_refill_bits_levelOH_l0), .io_refill_bits_levelOH_l1(io_refill_bits_levelOH_l1), .io_refill_bits_levelOH_l2(io_refill_bits_levelOH_l2), .io_refill_bits_levelOH_l3(io_refill_bits_levelOH_l3), .io_refill_bits_req_info_dup_0_vpn(io_refill_bits_req_info_dup_0_vpn), .io_refill_bits_req_info_dup_0_s2xlate(io_refill_bits_req_info_dup_0_s2xlate), .io_refill_bits_req_info_dup_0_source(io_refill_bits_req_info_dup_0_source), .io_refill_bits_req_info_dup_1_vpn(io_refill_bits_req_info_dup_1_vpn), .io_refill_bits_req_info_dup_1_s2xlate(io_refill_bits_req_info_dup_1_s2xlate), .io_refill_bits_req_info_dup_1_source(io_refill_bits_req_info_dup_1_source), .io_refill_bits_req_info_dup_2_vpn(io_refill_bits_req_info_dup_2_vpn), .io_refill_bits_req_info_dup_2_s2xlate(io_refill_bits_req_info_dup_2_s2xlate), .io_refill_bits_req_info_dup_2_source(io_refill_bits_req_info_dup_2_source), .io_refill_bits_level_dup_0(io_refill_bits_level_dup_0), .io_refill_bits_level_dup_2(io_refill_bits_level_dup_2), .io_refill_bits_sel_pte_dup_0(io_refill_bits_sel_pte_dup_0), .io_refill_bits_sel_pte_dup_2(io_refill_bits_sel_pte_dup_2), .io_sfence_dup_0_valid(io_sfence_dup_0_valid), .io_sfence_dup_0_bits_rs1(io_sfence_dup_0_bits_rs1), .io_sfence_dup_0_bits_rs2(io_sfence_dup_0_bits_rs2), .io_sfence_dup_0_bits_addr(io_sfence_dup_0_bits_addr), .io_sfence_dup_0_bits_id(io_sfence_dup_0_bits_id), .io_sfence_dup_0_bits_hv(io_sfence_dup_0_bits_hv), .io_sfence_dup_0_bits_hg(io_sfence_dup_0_bits_hg), .io_sfence_dup_1_valid(io_sfence_dup_1_valid), .io_sfence_dup_1_bits_id(io_sfence_dup_1_bits_id), .io_sfence_dup_2_valid(io_sfence_dup_2_valid), .io_sfence_dup_2_bits_rs1(io_sfence_dup_2_bits_rs1), .io_sfence_dup_2_bits_rs2(io_sfence_dup_2_bits_rs2), .io_sfence_dup_2_bits_id(io_sfence_dup_2_bits_id), .io_csr_dup_0_satp_asid(io_csr_dup_0_satp_asid), .io_csr_dup_0_satp_changed(io_csr_dup_0_satp_changed), .io_csr_dup_0_vsatp_asid(io_csr_dup_0_vsatp_asid), .io_csr_dup_0_vsatp_changed(io_csr_dup_0_vsatp_changed), .io_csr_dup_0_hgatp_mode(io_csr_dup_0_hgatp_mode), .io_csr_dup_0_hgatp_vmid(io_csr_dup_0_hgatp_vmid), .io_csr_dup_0_hgatp_changed(io_csr_dup_0_hgatp_changed), .io_csr_dup_0_priv_virt(io_csr_dup_0_priv_virt), .io_csr_dup_1_satp_asid(io_csr_dup_1_satp_asid), .io_csr_dup_1_satp_changed(io_csr_dup_1_satp_changed), .io_csr_dup_1_vsatp_asid(io_csr_dup_1_vsatp_asid), .io_csr_dup_1_vsatp_changed(io_csr_dup_1_vsatp_changed), .io_csr_dup_1_hgatp_mode(io_csr_dup_1_hgatp_mode), .io_csr_dup_1_hgatp_vmid(io_csr_dup_1_hgatp_vmid), .io_csr_dup_1_hgatp_changed(io_csr_dup_1_hgatp_changed), .io_csr_dup_1_priv_virt(io_csr_dup_1_priv_virt), .io_csr_dup_2_satp_asid(io_csr_dup_2_satp_asid), .io_csr_dup_2_satp_changed(io_csr_dup_2_satp_changed), .io_csr_dup_2_vsatp_asid(io_csr_dup_2_vsatp_asid), .io_csr_dup_2_vsatp_changed(io_csr_dup_2_vsatp_changed), .io_csr_dup_2_hgatp_mode(io_csr_dup_2_hgatp_mode), .io_csr_dup_2_hgatp_vmid(io_csr_dup_2_hgatp_vmid), .io_csr_dup_2_hgatp_changed(io_csr_dup_2_hgatp_changed), .io_csr_dup_2_priv_virt(io_csr_dup_2_priv_virt), .boreChildrenBd_bore_array(boreChildrenBd_bore_array), .boreChildrenBd_bore_all(boreChildrenBd_bore_all), .boreChildrenBd_bore_req(boreChildrenBd_bore_req), .boreChildrenBd_bore_writeen(boreChildrenBd_bore_writeen), .boreChildrenBd_bore_be(boreChildrenBd_bore_be), .boreChildrenBd_bore_addr(boreChildrenBd_bore_addr), .boreChildrenBd_bore_indata(boreChildrenBd_bore_indata), .boreChildrenBd_bore_readen(boreChildrenBd_bore_readen), .boreChildrenBd_bore_addr_rd(boreChildrenBd_bore_addr_rd), .boreChildrenBd_bore_1_array(boreChildrenBd_bore_1_array), .boreChildrenBd_bore_1_all(boreChildrenBd_bore_1_all), .boreChildrenBd_bore_1_req(boreChildrenBd_bore_1_req), .boreChildrenBd_bore_1_writeen(boreChildrenBd_bore_1_writeen), .boreChildrenBd_bore_1_be(boreChildrenBd_bore_1_be), .boreChildrenBd_bore_1_addr(boreChildrenBd_bore_1_addr), .boreChildrenBd_bore_1_indata(boreChildrenBd_bore_1_indata), .boreChildrenBd_bore_1_readen(boreChildrenBd_bore_1_readen), .boreChildrenBd_bore_1_addr_rd(boreChildrenBd_bore_1_addr_rd), .sigFromSrams_bore_ram_hold(sigFromSrams_bore_ram_hold), .sigFromSrams_bore_ram_bypass(sigFromSrams_bore_ram_bypass), .sigFromSrams_bore_ram_bp_clken(sigFromSrams_bore_ram_bp_clken), .sigFromSrams_bore_ram_aux_clk(sigFromSrams_bore_ram_aux_clk), .sigFromSrams_bore_ram_aux_ckbp(sigFromSrams_bore_ram_aux_ckbp), .sigFromSrams_bore_ram_mcp_hold(sigFromSrams_bore_ram_mcp_hold), .sigFromSrams_bore_cgen(sigFromSrams_bore_cgen), .sigFromSrams_bore_1_ram_hold(sigFromSrams_bore_1_ram_hold), .sigFromSrams_bore_1_ram_bypass(sigFromSrams_bore_1_ram_bypass), .sigFromSrams_bore_1_ram_bp_clken(sigFromSrams_bore_1_ram_bp_clken), .sigFromSrams_bore_1_ram_aux_clk(sigFromSrams_bore_1_ram_aux_clk), .sigFromSrams_bore_1_ram_aux_ckbp(sigFromSrams_bore_1_ram_aux_ckbp), .sigFromSrams_bore_1_ram_mcp_hold(sigFromSrams_bore_1_ram_mcp_hold), .sigFromSrams_bore_1_cgen(sigFromSrams_bore_1_cgen), .sigFromSrams_bore_2_ram_hold(sigFromSrams_bore_2_ram_hold), .sigFromSrams_bore_2_ram_bypass(sigFromSrams_bore_2_ram_bypass), .sigFromSrams_bore_2_ram_bp_clken(sigFromSrams_bore_2_ram_bp_clken), .sigFromSrams_bore_2_ram_aux_clk(sigFromSrams_bore_2_ram_aux_clk), .sigFromSrams_bore_2_ram_aux_ckbp(sigFromSrams_bore_2_ram_aux_ckbp), .sigFromSrams_bore_2_ram_mcp_hold(sigFromSrams_bore_2_ram_mcp_hold), .sigFromSrams_bore_2_cgen(sigFromSrams_bore_2_cgen), .sigFromSrams_bore_3_ram_hold(sigFromSrams_bore_3_ram_hold), .sigFromSrams_bore_3_ram_bypass(sigFromSrams_bore_3_ram_bypass), .sigFromSrams_bore_3_ram_bp_clken(sigFromSrams_bore_3_ram_bp_clken), .sigFromSrams_bore_3_ram_aux_clk(sigFromSrams_bore_3_ram_aux_clk), .sigFromSrams_bore_3_ram_aux_ckbp(sigFromSrams_bore_3_ram_aux_ckbp), .sigFromSrams_bore_3_ram_mcp_hold(sigFromSrams_bore_3_ram_mcp_hold), .sigFromSrams_bore_3_cgen(sigFromSrams_bore_3_cgen), .sigFromSrams_bore_4_ram_hold(sigFromSrams_bore_4_ram_hold), .sigFromSrams_bore_4_ram_bypass(sigFromSrams_bore_4_ram_bypass), .sigFromSrams_bore_4_ram_bp_clken(sigFromSrams_bore_4_ram_bp_clken), .sigFromSrams_bore_4_ram_aux_clk(sigFromSrams_bore_4_ram_aux_clk), .sigFromSrams_bore_4_ram_aux_ckbp(sigFromSrams_bore_4_ram_aux_ckbp), .sigFromSrams_bore_4_ram_mcp_hold(sigFromSrams_bore_4_ram_mcp_hold), .sigFromSrams_bore_4_cgen(sigFromSrams_bore_4_cgen), .sigFromSrams_bore_5_ram_hold(sigFromSrams_bore_5_ram_hold), .sigFromSrams_bore_5_ram_bypass(sigFromSrams_bore_5_ram_bypass), .sigFromSrams_bore_5_ram_bp_clken(sigFromSrams_bore_5_ram_bp_clken), .sigFromSrams_bore_5_ram_aux_clk(sigFromSrams_bore_5_ram_aux_clk), .sigFromSrams_bore_5_ram_aux_ckbp(sigFromSrams_bore_5_ram_aux_ckbp), .sigFromSrams_bore_5_ram_mcp_hold(sigFromSrams_bore_5_ram_mcp_hold), .sigFromSrams_bore_5_cgen(sigFromSrams_bore_5_cgen), .sigFromSrams_bore_6_ram_hold(sigFromSrams_bore_6_ram_hold), .sigFromSrams_bore_6_ram_bypass(sigFromSrams_bore_6_ram_bypass), .sigFromSrams_bore_6_ram_bp_clken(sigFromSrams_bore_6_ram_bp_clken), .sigFromSrams_bore_6_ram_aux_clk(sigFromSrams_bore_6_ram_aux_clk), .sigFromSrams_bore_6_ram_aux_ckbp(sigFromSrams_bore_6_ram_aux_ckbp), .sigFromSrams_bore_6_ram_mcp_hold(sigFromSrams_bore_6_ram_mcp_hold), .sigFromSrams_bore_6_cgen(sigFromSrams_bore_6_cgen), .sigFromSrams_bore_7_ram_hold(sigFromSrams_bore_7_ram_hold), .sigFromSrams_bore_7_ram_bypass(sigFromSrams_bore_7_ram_bypass), .sigFromSrams_bore_7_ram_bp_clken(sigFromSrams_bore_7_ram_bp_clken), .sigFromSrams_bore_7_ram_aux_clk(sigFromSrams_bore_7_ram_aux_clk), .sigFromSrams_bore_7_ram_aux_ckbp(sigFromSrams_bore_7_ram_aux_ckbp), .sigFromSrams_bore_7_ram_mcp_hold(sigFromSrams_bore_7_ram_mcp_hold), .sigFromSrams_bore_7_cgen(sigFromSrams_bore_7_cgen), .sigFromSrams_bore_8_ram_hold(sigFromSrams_bore_8_ram_hold), .sigFromSrams_bore_8_ram_bypass(sigFromSrams_bore_8_ram_bypass), .sigFromSrams_bore_8_ram_bp_clken(sigFromSrams_bore_8_ram_bp_clken), .sigFromSrams_bore_8_ram_aux_clk(sigFromSrams_bore_8_ram_aux_clk), .sigFromSrams_bore_8_ram_aux_ckbp(sigFromSrams_bore_8_ram_aux_ckbp), .sigFromSrams_bore_8_ram_mcp_hold(sigFromSrams_bore_8_ram_mcp_hold), .sigFromSrams_bore_8_cgen(sigFromSrams_bore_8_cgen), .sigFromSrams_bore_9_ram_hold(sigFromSrams_bore_9_ram_hold), .sigFromSrams_bore_9_ram_bypass(sigFromSrams_bore_9_ram_bypass), .sigFromSrams_bore_9_ram_bp_clken(sigFromSrams_bore_9_ram_bp_clken), .sigFromSrams_bore_9_ram_aux_clk(sigFromSrams_bore_9_ram_aux_clk), .sigFromSrams_bore_9_ram_aux_ckbp(sigFromSrams_bore_9_ram_aux_ckbp), .sigFromSrams_bore_9_ram_mcp_hold(sigFromSrams_bore_9_ram_mcp_hold), .sigFromSrams_bore_9_cgen(sigFromSrams_bore_9_cgen), .sigFromSrams_bore_10_ram_hold(sigFromSrams_bore_10_ram_hold), .sigFromSrams_bore_10_ram_bypass(sigFromSrams_bore_10_ram_bypass), .sigFromSrams_bore_10_ram_bp_clken(sigFromSrams_bore_10_ram_bp_clken), .sigFromSrams_bore_10_ram_aux_clk(sigFromSrams_bore_10_ram_aux_clk), .sigFromSrams_bore_10_ram_aux_ckbp(sigFromSrams_bore_10_ram_aux_ckbp), .sigFromSrams_bore_10_ram_mcp_hold(sigFromSrams_bore_10_ram_mcp_hold), .sigFromSrams_bore_10_cgen(sigFromSrams_bore_10_cgen), .sigFromSrams_bore_11_ram_hold(sigFromSrams_bore_11_ram_hold), .sigFromSrams_bore_11_ram_bypass(sigFromSrams_bore_11_ram_bypass), .sigFromSrams_bore_11_ram_bp_clken(sigFromSrams_bore_11_ram_bp_clken), .sigFromSrams_bore_11_ram_aux_clk(sigFromSrams_bore_11_ram_aux_clk), .sigFromSrams_bore_11_ram_aux_ckbp(sigFromSrams_bore_11_ram_aux_ckbp), .sigFromSrams_bore_11_ram_mcp_hold(sigFromSrams_bore_11_ram_mcp_hold), .sigFromSrams_bore_11_cgen(sigFromSrams_bore_11_cgen), .cg_bore_cgen(cg_bore_cgen), .io_req_ready(i_io_req_ready), .io_resp_valid(i_io_resp_valid), .io_resp_bits_req_info_vpn(i_io_resp_bits_req_info_vpn), .io_resp_bits_req_info_s2xlate(i_io_resp_bits_req_info_s2xlate), .io_resp_bits_req_info_source(i_io_resp_bits_req_info_source), .io_resp_bits_isFirst(i_io_resp_bits_isFirst), .io_resp_bits_hit(i_io_resp_bits_hit), .io_resp_bits_prefetch(i_io_resp_bits_prefetch), .io_resp_bits_bypassed(i_io_resp_bits_bypassed), .io_resp_bits_toFsm_l3Hit(i_io_resp_bits_toFsm_l3Hit), .io_resp_bits_toFsm_l2Hit(i_io_resp_bits_toFsm_l2Hit), .io_resp_bits_toFsm_l1Hit(i_io_resp_bits_toFsm_l1Hit), .io_resp_bits_toFsm_ppn(i_io_resp_bits_toFsm_ppn), .io_resp_bits_toFsm_stage1Hit(i_io_resp_bits_toFsm_stage1Hit), .io_resp_bits_stage1_entry_0_tag(i_io_resp_bits_stage1_entry_0_tag), .io_resp_bits_stage1_entry_0_asid(i_io_resp_bits_stage1_entry_0_asid), .io_resp_bits_stage1_entry_0_vmid(i_io_resp_bits_stage1_entry_0_vmid), .io_resp_bits_stage1_entry_0_n(i_io_resp_bits_stage1_entry_0_n), .io_resp_bits_stage1_entry_0_pbmt(i_io_resp_bits_stage1_entry_0_pbmt), .io_resp_bits_stage1_entry_0_perm_d(i_io_resp_bits_stage1_entry_0_perm_d), .io_resp_bits_stage1_entry_0_perm_a(i_io_resp_bits_stage1_entry_0_perm_a), .io_resp_bits_stage1_entry_0_perm_g(i_io_resp_bits_stage1_entry_0_perm_g), .io_resp_bits_stage1_entry_0_perm_u(i_io_resp_bits_stage1_entry_0_perm_u), .io_resp_bits_stage1_entry_0_perm_x(i_io_resp_bits_stage1_entry_0_perm_x), .io_resp_bits_stage1_entry_0_perm_w(i_io_resp_bits_stage1_entry_0_perm_w), .io_resp_bits_stage1_entry_0_perm_r(i_io_resp_bits_stage1_entry_0_perm_r), .io_resp_bits_stage1_entry_0_level(i_io_resp_bits_stage1_entry_0_level), .io_resp_bits_stage1_entry_0_v(i_io_resp_bits_stage1_entry_0_v), .io_resp_bits_stage1_entry_0_ppn(i_io_resp_bits_stage1_entry_0_ppn), .io_resp_bits_stage1_entry_0_ppn_low(i_io_resp_bits_stage1_entry_0_ppn_low), .io_resp_bits_stage1_entry_0_pf(i_io_resp_bits_stage1_entry_0_pf), .io_resp_bits_stage1_entry_1_tag(i_io_resp_bits_stage1_entry_1_tag), .io_resp_bits_stage1_entry_1_asid(i_io_resp_bits_stage1_entry_1_asid), .io_resp_bits_stage1_entry_1_vmid(i_io_resp_bits_stage1_entry_1_vmid), .io_resp_bits_stage1_entry_1_n(i_io_resp_bits_stage1_entry_1_n), .io_resp_bits_stage1_entry_1_pbmt(i_io_resp_bits_stage1_entry_1_pbmt), .io_resp_bits_stage1_entry_1_perm_d(i_io_resp_bits_stage1_entry_1_perm_d), .io_resp_bits_stage1_entry_1_perm_a(i_io_resp_bits_stage1_entry_1_perm_a), .io_resp_bits_stage1_entry_1_perm_g(i_io_resp_bits_stage1_entry_1_perm_g), .io_resp_bits_stage1_entry_1_perm_u(i_io_resp_bits_stage1_entry_1_perm_u), .io_resp_bits_stage1_entry_1_perm_x(i_io_resp_bits_stage1_entry_1_perm_x), .io_resp_bits_stage1_entry_1_perm_w(i_io_resp_bits_stage1_entry_1_perm_w), .io_resp_bits_stage1_entry_1_perm_r(i_io_resp_bits_stage1_entry_1_perm_r), .io_resp_bits_stage1_entry_1_level(i_io_resp_bits_stage1_entry_1_level), .io_resp_bits_stage1_entry_1_v(i_io_resp_bits_stage1_entry_1_v), .io_resp_bits_stage1_entry_1_ppn(i_io_resp_bits_stage1_entry_1_ppn), .io_resp_bits_stage1_entry_1_ppn_low(i_io_resp_bits_stage1_entry_1_ppn_low), .io_resp_bits_stage1_entry_1_pf(i_io_resp_bits_stage1_entry_1_pf), .io_resp_bits_stage1_entry_2_tag(i_io_resp_bits_stage1_entry_2_tag), .io_resp_bits_stage1_entry_2_asid(i_io_resp_bits_stage1_entry_2_asid), .io_resp_bits_stage1_entry_2_vmid(i_io_resp_bits_stage1_entry_2_vmid), .io_resp_bits_stage1_entry_2_n(i_io_resp_bits_stage1_entry_2_n), .io_resp_bits_stage1_entry_2_pbmt(i_io_resp_bits_stage1_entry_2_pbmt), .io_resp_bits_stage1_entry_2_perm_d(i_io_resp_bits_stage1_entry_2_perm_d), .io_resp_bits_stage1_entry_2_perm_a(i_io_resp_bits_stage1_entry_2_perm_a), .io_resp_bits_stage1_entry_2_perm_g(i_io_resp_bits_stage1_entry_2_perm_g), .io_resp_bits_stage1_entry_2_perm_u(i_io_resp_bits_stage1_entry_2_perm_u), .io_resp_bits_stage1_entry_2_perm_x(i_io_resp_bits_stage1_entry_2_perm_x), .io_resp_bits_stage1_entry_2_perm_w(i_io_resp_bits_stage1_entry_2_perm_w), .io_resp_bits_stage1_entry_2_perm_r(i_io_resp_bits_stage1_entry_2_perm_r), .io_resp_bits_stage1_entry_2_level(i_io_resp_bits_stage1_entry_2_level), .io_resp_bits_stage1_entry_2_v(i_io_resp_bits_stage1_entry_2_v), .io_resp_bits_stage1_entry_2_ppn(i_io_resp_bits_stage1_entry_2_ppn), .io_resp_bits_stage1_entry_2_ppn_low(i_io_resp_bits_stage1_entry_2_ppn_low), .io_resp_bits_stage1_entry_2_pf(i_io_resp_bits_stage1_entry_2_pf), .io_resp_bits_stage1_entry_3_tag(i_io_resp_bits_stage1_entry_3_tag), .io_resp_bits_stage1_entry_3_asid(i_io_resp_bits_stage1_entry_3_asid), .io_resp_bits_stage1_entry_3_vmid(i_io_resp_bits_stage1_entry_3_vmid), .io_resp_bits_stage1_entry_3_n(i_io_resp_bits_stage1_entry_3_n), .io_resp_bits_stage1_entry_3_pbmt(i_io_resp_bits_stage1_entry_3_pbmt), .io_resp_bits_stage1_entry_3_perm_d(i_io_resp_bits_stage1_entry_3_perm_d), .io_resp_bits_stage1_entry_3_perm_a(i_io_resp_bits_stage1_entry_3_perm_a), .io_resp_bits_stage1_entry_3_perm_g(i_io_resp_bits_stage1_entry_3_perm_g), .io_resp_bits_stage1_entry_3_perm_u(i_io_resp_bits_stage1_entry_3_perm_u), .io_resp_bits_stage1_entry_3_perm_x(i_io_resp_bits_stage1_entry_3_perm_x), .io_resp_bits_stage1_entry_3_perm_w(i_io_resp_bits_stage1_entry_3_perm_w), .io_resp_bits_stage1_entry_3_perm_r(i_io_resp_bits_stage1_entry_3_perm_r), .io_resp_bits_stage1_entry_3_level(i_io_resp_bits_stage1_entry_3_level), .io_resp_bits_stage1_entry_3_v(i_io_resp_bits_stage1_entry_3_v), .io_resp_bits_stage1_entry_3_ppn(i_io_resp_bits_stage1_entry_3_ppn), .io_resp_bits_stage1_entry_3_ppn_low(i_io_resp_bits_stage1_entry_3_ppn_low), .io_resp_bits_stage1_entry_3_pf(i_io_resp_bits_stage1_entry_3_pf), .io_resp_bits_stage1_entry_4_tag(i_io_resp_bits_stage1_entry_4_tag), .io_resp_bits_stage1_entry_4_asid(i_io_resp_bits_stage1_entry_4_asid), .io_resp_bits_stage1_entry_4_vmid(i_io_resp_bits_stage1_entry_4_vmid), .io_resp_bits_stage1_entry_4_n(i_io_resp_bits_stage1_entry_4_n), .io_resp_bits_stage1_entry_4_pbmt(i_io_resp_bits_stage1_entry_4_pbmt), .io_resp_bits_stage1_entry_4_perm_d(i_io_resp_bits_stage1_entry_4_perm_d), .io_resp_bits_stage1_entry_4_perm_a(i_io_resp_bits_stage1_entry_4_perm_a), .io_resp_bits_stage1_entry_4_perm_g(i_io_resp_bits_stage1_entry_4_perm_g), .io_resp_bits_stage1_entry_4_perm_u(i_io_resp_bits_stage1_entry_4_perm_u), .io_resp_bits_stage1_entry_4_perm_x(i_io_resp_bits_stage1_entry_4_perm_x), .io_resp_bits_stage1_entry_4_perm_w(i_io_resp_bits_stage1_entry_4_perm_w), .io_resp_bits_stage1_entry_4_perm_r(i_io_resp_bits_stage1_entry_4_perm_r), .io_resp_bits_stage1_entry_4_level(i_io_resp_bits_stage1_entry_4_level), .io_resp_bits_stage1_entry_4_v(i_io_resp_bits_stage1_entry_4_v), .io_resp_bits_stage1_entry_4_ppn(i_io_resp_bits_stage1_entry_4_ppn), .io_resp_bits_stage1_entry_4_ppn_low(i_io_resp_bits_stage1_entry_4_ppn_low), .io_resp_bits_stage1_entry_4_pf(i_io_resp_bits_stage1_entry_4_pf), .io_resp_bits_stage1_entry_5_tag(i_io_resp_bits_stage1_entry_5_tag), .io_resp_bits_stage1_entry_5_asid(i_io_resp_bits_stage1_entry_5_asid), .io_resp_bits_stage1_entry_5_vmid(i_io_resp_bits_stage1_entry_5_vmid), .io_resp_bits_stage1_entry_5_n(i_io_resp_bits_stage1_entry_5_n), .io_resp_bits_stage1_entry_5_pbmt(i_io_resp_bits_stage1_entry_5_pbmt), .io_resp_bits_stage1_entry_5_perm_d(i_io_resp_bits_stage1_entry_5_perm_d), .io_resp_bits_stage1_entry_5_perm_a(i_io_resp_bits_stage1_entry_5_perm_a), .io_resp_bits_stage1_entry_5_perm_g(i_io_resp_bits_stage1_entry_5_perm_g), .io_resp_bits_stage1_entry_5_perm_u(i_io_resp_bits_stage1_entry_5_perm_u), .io_resp_bits_stage1_entry_5_perm_x(i_io_resp_bits_stage1_entry_5_perm_x), .io_resp_bits_stage1_entry_5_perm_w(i_io_resp_bits_stage1_entry_5_perm_w), .io_resp_bits_stage1_entry_5_perm_r(i_io_resp_bits_stage1_entry_5_perm_r), .io_resp_bits_stage1_entry_5_level(i_io_resp_bits_stage1_entry_5_level), .io_resp_bits_stage1_entry_5_v(i_io_resp_bits_stage1_entry_5_v), .io_resp_bits_stage1_entry_5_ppn(i_io_resp_bits_stage1_entry_5_ppn), .io_resp_bits_stage1_entry_5_ppn_low(i_io_resp_bits_stage1_entry_5_ppn_low), .io_resp_bits_stage1_entry_5_pf(i_io_resp_bits_stage1_entry_5_pf), .io_resp_bits_stage1_entry_6_tag(i_io_resp_bits_stage1_entry_6_tag), .io_resp_bits_stage1_entry_6_asid(i_io_resp_bits_stage1_entry_6_asid), .io_resp_bits_stage1_entry_6_vmid(i_io_resp_bits_stage1_entry_6_vmid), .io_resp_bits_stage1_entry_6_n(i_io_resp_bits_stage1_entry_6_n), .io_resp_bits_stage1_entry_6_pbmt(i_io_resp_bits_stage1_entry_6_pbmt), .io_resp_bits_stage1_entry_6_perm_d(i_io_resp_bits_stage1_entry_6_perm_d), .io_resp_bits_stage1_entry_6_perm_a(i_io_resp_bits_stage1_entry_6_perm_a), .io_resp_bits_stage1_entry_6_perm_g(i_io_resp_bits_stage1_entry_6_perm_g), .io_resp_bits_stage1_entry_6_perm_u(i_io_resp_bits_stage1_entry_6_perm_u), .io_resp_bits_stage1_entry_6_perm_x(i_io_resp_bits_stage1_entry_6_perm_x), .io_resp_bits_stage1_entry_6_perm_w(i_io_resp_bits_stage1_entry_6_perm_w), .io_resp_bits_stage1_entry_6_perm_r(i_io_resp_bits_stage1_entry_6_perm_r), .io_resp_bits_stage1_entry_6_level(i_io_resp_bits_stage1_entry_6_level), .io_resp_bits_stage1_entry_6_v(i_io_resp_bits_stage1_entry_6_v), .io_resp_bits_stage1_entry_6_ppn(i_io_resp_bits_stage1_entry_6_ppn), .io_resp_bits_stage1_entry_6_ppn_low(i_io_resp_bits_stage1_entry_6_ppn_low), .io_resp_bits_stage1_entry_6_pf(i_io_resp_bits_stage1_entry_6_pf), .io_resp_bits_stage1_entry_7_tag(i_io_resp_bits_stage1_entry_7_tag), .io_resp_bits_stage1_entry_7_asid(i_io_resp_bits_stage1_entry_7_asid), .io_resp_bits_stage1_entry_7_vmid(i_io_resp_bits_stage1_entry_7_vmid), .io_resp_bits_stage1_entry_7_n(i_io_resp_bits_stage1_entry_7_n), .io_resp_bits_stage1_entry_7_pbmt(i_io_resp_bits_stage1_entry_7_pbmt), .io_resp_bits_stage1_entry_7_perm_d(i_io_resp_bits_stage1_entry_7_perm_d), .io_resp_bits_stage1_entry_7_perm_a(i_io_resp_bits_stage1_entry_7_perm_a), .io_resp_bits_stage1_entry_7_perm_g(i_io_resp_bits_stage1_entry_7_perm_g), .io_resp_bits_stage1_entry_7_perm_u(i_io_resp_bits_stage1_entry_7_perm_u), .io_resp_bits_stage1_entry_7_perm_x(i_io_resp_bits_stage1_entry_7_perm_x), .io_resp_bits_stage1_entry_7_perm_w(i_io_resp_bits_stage1_entry_7_perm_w), .io_resp_bits_stage1_entry_7_perm_r(i_io_resp_bits_stage1_entry_7_perm_r), .io_resp_bits_stage1_entry_7_level(i_io_resp_bits_stage1_entry_7_level), .io_resp_bits_stage1_entry_7_v(i_io_resp_bits_stage1_entry_7_v), .io_resp_bits_stage1_entry_7_ppn(i_io_resp_bits_stage1_entry_7_ppn), .io_resp_bits_stage1_entry_7_ppn_low(i_io_resp_bits_stage1_entry_7_ppn_low), .io_resp_bits_stage1_entry_7_pf(i_io_resp_bits_stage1_entry_7_pf), .io_resp_bits_stage1_pteidx_0(i_io_resp_bits_stage1_pteidx_0), .io_resp_bits_stage1_pteidx_1(i_io_resp_bits_stage1_pteidx_1), .io_resp_bits_stage1_pteidx_2(i_io_resp_bits_stage1_pteidx_2), .io_resp_bits_stage1_pteidx_3(i_io_resp_bits_stage1_pteidx_3), .io_resp_bits_stage1_pteidx_4(i_io_resp_bits_stage1_pteidx_4), .io_resp_bits_stage1_pteidx_5(i_io_resp_bits_stage1_pteidx_5), .io_resp_bits_stage1_pteidx_6(i_io_resp_bits_stage1_pteidx_6), .io_resp_bits_stage1_pteidx_7(i_io_resp_bits_stage1_pteidx_7), .io_resp_bits_stage1_not_super(i_io_resp_bits_stage1_not_super), .io_resp_bits_isHptwReq(i_io_resp_bits_isHptwReq), .io_resp_bits_toHptw_l3Hit(i_io_resp_bits_toHptw_l3Hit), .io_resp_bits_toHptw_l2Hit(i_io_resp_bits_toHptw_l2Hit), .io_resp_bits_toHptw_l1Hit(i_io_resp_bits_toHptw_l1Hit), .io_resp_bits_toHptw_ppn(i_io_resp_bits_toHptw_ppn), .io_resp_bits_toHptw_id(i_io_resp_bits_toHptw_id), .io_resp_bits_toHptw_resp_entry_tag(i_io_resp_bits_toHptw_resp_entry_tag), .io_resp_bits_toHptw_resp_entry_vmid(i_io_resp_bits_toHptw_resp_entry_vmid), .io_resp_bits_toHptw_resp_entry_n(i_io_resp_bits_toHptw_resp_entry_n), .io_resp_bits_toHptw_resp_entry_pbmt(i_io_resp_bits_toHptw_resp_entry_pbmt), .io_resp_bits_toHptw_resp_entry_ppn(i_io_resp_bits_toHptw_resp_entry_ppn), .io_resp_bits_toHptw_resp_entry_perm_d(i_io_resp_bits_toHptw_resp_entry_perm_d), .io_resp_bits_toHptw_resp_entry_perm_a(i_io_resp_bits_toHptw_resp_entry_perm_a), .io_resp_bits_toHptw_resp_entry_perm_g(i_io_resp_bits_toHptw_resp_entry_perm_g), .io_resp_bits_toHptw_resp_entry_perm_u(i_io_resp_bits_toHptw_resp_entry_perm_u), .io_resp_bits_toHptw_resp_entry_perm_x(i_io_resp_bits_toHptw_resp_entry_perm_x), .io_resp_bits_toHptw_resp_entry_perm_w(i_io_resp_bits_toHptw_resp_entry_perm_w), .io_resp_bits_toHptw_resp_entry_perm_r(i_io_resp_bits_toHptw_resp_entry_perm_r), .io_resp_bits_toHptw_resp_entry_level(i_io_resp_bits_toHptw_resp_entry_level), .io_resp_bits_toHptw_resp_gpf(i_io_resp_bits_toHptw_resp_gpf), .io_resp_bits_toHptw_bypassed(i_io_resp_bits_toHptw_bypassed), .io_perf_0_value(i_io_perf_0_value), .io_perf_1_value(i_io_perf_1_value), .io_perf_2_value(i_io_perf_2_value), .io_perf_3_value(i_io_perf_3_value), .io_perf_4_value(i_io_perf_4_value), .io_perf_5_value(i_io_perf_5_value), .io_perf_6_value(i_io_perf_6_value), .io_perf_7_value(i_io_perf_7_value), .boreChildrenBd_bore_ack(i_boreChildrenBd_bore_ack), .boreChildrenBd_bore_outdata(i_boreChildrenBd_bore_outdata), .boreChildrenBd_bore_1_ack(i_boreChildrenBd_bore_1_ack), .boreChildrenBd_bore_1_outdata(i_boreChildrenBd_bore_1_outdata));

  // ---------------------------------------------------------------------------
  // 本轮探针：L1 元数据(l1g/l1vmids)、PLRU(l1replace/l0replace/l2replace/l3replace)
  // 与 golden 逐拍比对。golden 为扁平 reg；impl 在 u_i.u_core 内为数组。
  // golden l1g/l1v 位序：bit = set*2 + way（set0..7，每 set {way1,way0}）。
  // ---------------------------------------------------------------------------
  task automatic probe_l1meta();
    // l1g：整 16 位（layout 与 l1v 同）
    if (!$isunknown(u_g.l1g) && u_g.l1g !== u_i.u_core.l1g) pmm_l1g++;
    // l1vmids：8 set × 2 way，golden 扁平 l1vmids_<set>_<way>
    if (u_g.l1vmids_0_0 !== u_i.u_core.l1vmids[0][0]) pmm_l1vmids++;
    if (u_g.l1vmids_0_1 !== u_i.u_core.l1vmids[0][1]) pmm_l1vmids++;
    if (u_g.l1vmids_1_0 !== u_i.u_core.l1vmids[1][0]) pmm_l1vmids++;
    if (u_g.l1vmids_1_1 !== u_i.u_core.l1vmids[1][1]) pmm_l1vmids++;
    if (u_g.l1vmids_2_0 !== u_i.u_core.l1vmids[2][0]) pmm_l1vmids++;
    if (u_g.l1vmids_2_1 !== u_i.u_core.l1vmids[2][1]) pmm_l1vmids++;
    if (u_g.l1vmids_3_0 !== u_i.u_core.l1vmids[3][0]) pmm_l1vmids++;
    if (u_g.l1vmids_3_1 !== u_i.u_core.l1vmids[3][1]) pmm_l1vmids++;
    if (u_g.l1vmids_4_0 !== u_i.u_core.l1vmids[4][0]) pmm_l1vmids++;
    if (u_g.l1vmids_4_1 !== u_i.u_core.l1vmids[4][1]) pmm_l1vmids++;
    if (u_g.l1vmids_5_0 !== u_i.u_core.l1vmids[5][0]) pmm_l1vmids++;
    if (u_g.l1vmids_5_1 !== u_i.u_core.l1vmids[5][1]) pmm_l1vmids++;
    if (u_g.l1vmids_6_0 !== u_i.u_core.l1vmids[6][0]) pmm_l1vmids++;
    if (u_g.l1vmids_6_1 !== u_i.u_core.l1vmids[6][1]) pmm_l1vmids++;
    if (u_g.l1vmids_7_0 !== u_i.u_core.l1vmids[7][0]) pmm_l1vmids++;
    if (u_g.l1vmids_7_1 !== u_i.u_core.l1vmids[7][1]) pmm_l1vmids++;
    // l1replace：8 set × 1 bit（golden state_vec_0..7）
    if (u_g.state_vec_0 !== u_i.u_core.l1replace[0]) pmm_l1repl++;
    if (u_g.state_vec_1 !== u_i.u_core.l1replace[1]) pmm_l1repl++;
    if (u_g.state_vec_2 !== u_i.u_core.l1replace[2]) pmm_l1repl++;
    if (u_g.state_vec_3 !== u_i.u_core.l1replace[3]) pmm_l1repl++;
    if (u_g.state_vec_4 !== u_i.u_core.l1replace[4]) pmm_l1repl++;
    if (u_g.state_vec_5 !== u_i.u_core.l1replace[5]) pmm_l1repl++;
    if (u_g.state_vec_6 !== u_i.u_core.l1replace[6]) pmm_l1repl++;
    if (u_g.state_vec_7 !== u_i.u_core.l1replace[7]) pmm_l1repl++;
    // l3replace / l2replace（golden state_reg / state_reg_1）
    if (!$isunknown(u_g.state_reg)   && u_g.state_reg   !== u_i.u_core.l3replace) pmm_l3repl++;
    if (!$isunknown(u_g.state_reg_1) && u_g.state_reg_1 !== u_i.u_core.l2replace) pmm_l2repl++;
    // l0replace：32 set × 3 bit（golden state_vec_1_0..31）—— 逐 set 比
    probe_l0repl();
  endtask

  task automatic probe_l0repl();
    if (u_g.state_vec_1_0  !== u_i.u_core.l0replace[0])  pmm_l0repl++;
    if (u_g.state_vec_1_1  !== u_i.u_core.l0replace[1])  pmm_l0repl++;
    if (u_g.state_vec_1_2  !== u_i.u_core.l0replace[2])  pmm_l0repl++;
    if (u_g.state_vec_1_3  !== u_i.u_core.l0replace[3])  pmm_l0repl++;
    if (u_g.state_vec_1_4  !== u_i.u_core.l0replace[4])  pmm_l0repl++;
    if (u_g.state_vec_1_5  !== u_i.u_core.l0replace[5])  pmm_l0repl++;
    if (u_g.state_vec_1_6  !== u_i.u_core.l0replace[6])  pmm_l0repl++;
    if (u_g.state_vec_1_7  !== u_i.u_core.l0replace[7])  pmm_l0repl++;
    if (u_g.state_vec_1_8  !== u_i.u_core.l0replace[8])  pmm_l0repl++;
    if (u_g.state_vec_1_9  !== u_i.u_core.l0replace[9])  pmm_l0repl++;
    if (u_g.state_vec_1_10 !== u_i.u_core.l0replace[10]) pmm_l0repl++;
    if (u_g.state_vec_1_11 !== u_i.u_core.l0replace[11]) pmm_l0repl++;
    if (u_g.state_vec_1_12 !== u_i.u_core.l0replace[12]) pmm_l0repl++;
    if (u_g.state_vec_1_13 !== u_i.u_core.l0replace[13]) pmm_l0repl++;
    if (u_g.state_vec_1_14 !== u_i.u_core.l0replace[14]) pmm_l0repl++;
    if (u_g.state_vec_1_15 !== u_i.u_core.l0replace[15]) pmm_l0repl++;
    if (u_g.state_vec_1_16 !== u_i.u_core.l0replace[16]) pmm_l0repl++;
    if (u_g.state_vec_1_17 !== u_i.u_core.l0replace[17]) pmm_l0repl++;
    if (u_g.state_vec_1_18 !== u_i.u_core.l0replace[18]) pmm_l0repl++;
    if (u_g.state_vec_1_19 !== u_i.u_core.l0replace[19]) pmm_l0repl++;
    if (u_g.state_vec_1_20 !== u_i.u_core.l0replace[20]) pmm_l0repl++;
    if (u_g.state_vec_1_21 !== u_i.u_core.l0replace[21]) pmm_l0repl++;
    if (u_g.state_vec_1_22 !== u_i.u_core.l0replace[22]) pmm_l0repl++;
    if (u_g.state_vec_1_23 !== u_i.u_core.l0replace[23]) pmm_l0repl++;
    if (u_g.state_vec_1_24 !== u_i.u_core.l0replace[24]) pmm_l0repl++;
    if (u_g.state_vec_1_25 !== u_i.u_core.l0replace[25]) pmm_l0repl++;
    if (u_g.state_vec_1_26 !== u_i.u_core.l0replace[26]) pmm_l0repl++;
    if (u_g.state_vec_1_27 !== u_i.u_core.l0replace[27]) pmm_l0repl++;
    if (u_g.state_vec_1_28 !== u_i.u_core.l0replace[28]) pmm_l0repl++;
    if (u_g.state_vec_1_29 !== u_i.u_core.l0replace[29]) pmm_l0repl++;
    if (u_g.state_vec_1_30 !== u_i.u_core.l0replace[30]) pmm_l0repl++;
    if (u_g.state_vec_1_31 !== u_i.u_core.l0replace[31]) pmm_l0repl++;
  endtask

  task automatic do_check(int t);
    checks++;
    if (!$isunknown(u_g.l3v) && u_g.l3v !== u_i.u_core.l3v) pmm_l3v++;
    if (!$isunknown(u_g.l1v) && u_g.l1v !== u_i.u_core.l1v) pmm_l1v++;
    probe_l1meta();
    if (!$isunknown(g_io_req_ready) && !$isunknown(i_io_req_ready) && (g_io_req_ready !== i_io_req_ready)) begin errors++;
      if(errors<=80) $display("vec %0d io_req_ready g=%b i=%b",t,g_io_req_ready,i_io_req_ready); end
    if (!$isunknown(g_io_resp_valid) && !$isunknown(i_io_resp_valid) && (g_io_resp_valid !== i_io_resp_valid)) begin errors++;
      if(errors<=80) $display("vec %0d io_resp_valid g=%b i=%b",t,g_io_resp_valid,i_io_resp_valid); end
    if (!$isunknown(g_io_resp_bits_req_info_vpn) && !$isunknown(i_io_resp_bits_req_info_vpn) && (g_io_resp_bits_req_info_vpn !== i_io_resp_bits_req_info_vpn)) begin errors++;
      if(errors<=80) $display("vec %0d io_resp_bits_req_info_vpn g=%h i=%h",t,g_io_resp_bits_req_info_vpn,i_io_resp_bits_req_info_vpn); end
    if (!$isunknown(g_io_resp_bits_req_info_s2xlate) && !$isunknown(i_io_resp_bits_req_info_s2xlate) && (g_io_resp_bits_req_info_s2xlate !== i_io_resp_bits_req_info_s2xlate)) begin errors++;
      if(errors<=80) $display("vec %0d io_resp_bits_req_info_s2xlate g=%h i=%h",t,g_io_resp_bits_req_info_s2xlate,i_io_resp_bits_req_info_s2xlate); end
    if (!$isunknown(g_io_resp_bits_req_info_source) && !$isunknown(i_io_resp_bits_req_info_source) && (g_io_resp_bits_req_info_source !== i_io_resp_bits_req_info_source)) begin errors++;
      if(errors<=80) $display("vec %0d io_resp_bits_req_info_source g=%h i=%h",t,g_io_resp_bits_req_info_source,i_io_resp_bits_req_info_source); end
    if (!$isunknown(g_io_resp_bits_isFirst) && !$isunknown(i_io_resp_bits_isFirst) && (g_io_resp_bits_isFirst !== i_io_resp_bits_isFirst)) begin errors++;
      if(errors<=80) $display("vec %0d io_resp_bits_isFirst g=%b i=%b",t,g_io_resp_bits_isFirst,i_io_resp_bits_isFirst); end
    if (!$isunknown(g_io_resp_bits_hit) && !$isunknown(i_io_resp_bits_hit) && (g_io_resp_bits_hit !== i_io_resp_bits_hit)) begin errors++;
      if(errors<=80) $display("vec %0d io_resp_bits_hit g=%b i=%b",t,g_io_resp_bits_hit,i_io_resp_bits_hit); end
    if (!$isunknown(g_io_resp_bits_prefetch) && !$isunknown(i_io_resp_bits_prefetch) && (g_io_resp_bits_prefetch !== i_io_resp_bits_prefetch)) begin errors++;
      if(errors<=80) $display("vec %0d io_resp_bits_prefetch g=%b i=%b",t,g_io_resp_bits_prefetch,i_io_resp_bits_prefetch); end
    if (!$isunknown(g_io_resp_bits_bypassed) && !$isunknown(i_io_resp_bits_bypassed) && (g_io_resp_bits_bypassed !== i_io_resp_bits_bypassed)) begin errors++;
      if(errors<=80) $display("vec %0d io_resp_bits_bypassed g=%b i=%b",t,g_io_resp_bits_bypassed,i_io_resp_bits_bypassed); end
    if (!$isunknown(g_io_resp_bits_toFsm_l3Hit) && !$isunknown(i_io_resp_bits_toFsm_l3Hit) && (g_io_resp_bits_toFsm_l3Hit !== i_io_resp_bits_toFsm_l3Hit)) begin errors++;
      if(errors<=80) $display("vec %0d io_resp_bits_toFsm_l3Hit g=%b i=%b",t,g_io_resp_bits_toFsm_l3Hit,i_io_resp_bits_toFsm_l3Hit); end
    if (!$isunknown(g_io_resp_bits_toFsm_l2Hit) && !$isunknown(i_io_resp_bits_toFsm_l2Hit) && (g_io_resp_bits_toFsm_l2Hit !== i_io_resp_bits_toFsm_l2Hit)) begin errors++;
      if(errors<=80) $display("vec %0d io_resp_bits_toFsm_l2Hit g=%b i=%b",t,g_io_resp_bits_toFsm_l2Hit,i_io_resp_bits_toFsm_l2Hit); end
    if (!$isunknown(g_io_resp_bits_toFsm_l1Hit) && !$isunknown(i_io_resp_bits_toFsm_l1Hit) && (g_io_resp_bits_toFsm_l1Hit !== i_io_resp_bits_toFsm_l1Hit)) begin errors++;
      if(errors<=80) $display("vec %0d io_resp_bits_toFsm_l1Hit g=%b i=%b",t,g_io_resp_bits_toFsm_l1Hit,i_io_resp_bits_toFsm_l1Hit); end
    if (!$isunknown(g_io_resp_bits_toFsm_ppn) && !$isunknown(i_io_resp_bits_toFsm_ppn) && (g_io_resp_bits_toFsm_ppn !== i_io_resp_bits_toFsm_ppn)) begin errors++;
      if(errors<=80) $display("vec %0d io_resp_bits_toFsm_ppn g=%h i=%h",t,g_io_resp_bits_toFsm_ppn,i_io_resp_bits_toFsm_ppn); end
    if (!$isunknown(g_io_resp_bits_toFsm_stage1Hit) && !$isunknown(i_io_resp_bits_toFsm_stage1Hit) && (g_io_resp_bits_toFsm_stage1Hit !== i_io_resp_bits_toFsm_stage1Hit)) begin errors++;
      if(errors<=80) $display("vec %0d io_resp_bits_toFsm_stage1Hit g=%b i=%b",t,g_io_resp_bits_toFsm_stage1Hit,i_io_resp_bits_toFsm_stage1Hit); end
    if (!$isunknown(g_io_resp_bits_stage1_entry_0_tag) && !$isunknown(i_io_resp_bits_stage1_entry_0_tag) && (g_io_resp_bits_stage1_entry_0_tag !== i_io_resp_bits_stage1_entry_0_tag)) begin errors++;
      if(errors<=80) $display("vec %0d io_resp_bits_stage1_entry_0_tag g=%h i=%h",t,g_io_resp_bits_stage1_entry_0_tag,i_io_resp_bits_stage1_entry_0_tag); end
    if (!$isunknown(g_io_resp_bits_stage1_entry_0_asid) && !$isunknown(i_io_resp_bits_stage1_entry_0_asid) && (g_io_resp_bits_stage1_entry_0_asid !== i_io_resp_bits_stage1_entry_0_asid)) begin errors++;
      if(errors<=80) $display("vec %0d io_resp_bits_stage1_entry_0_asid g=%h i=%h",t,g_io_resp_bits_stage1_entry_0_asid,i_io_resp_bits_stage1_entry_0_asid); end
    if (!$isunknown(g_io_resp_bits_stage1_entry_0_vmid) && !$isunknown(i_io_resp_bits_stage1_entry_0_vmid) && (g_io_resp_bits_stage1_entry_0_vmid !== i_io_resp_bits_stage1_entry_0_vmid)) begin errors++;
      if(errors<=80) $display("vec %0d io_resp_bits_stage1_entry_0_vmid g=%h i=%h",t,g_io_resp_bits_stage1_entry_0_vmid,i_io_resp_bits_stage1_entry_0_vmid); end
    if (!$isunknown(g_io_resp_bits_stage1_entry_0_n) && !$isunknown(i_io_resp_bits_stage1_entry_0_n) && (g_io_resp_bits_stage1_entry_0_n !== i_io_resp_bits_stage1_entry_0_n)) begin errors++;
      if(errors<=80) $display("vec %0d io_resp_bits_stage1_entry_0_n g=%b i=%b",t,g_io_resp_bits_stage1_entry_0_n,i_io_resp_bits_stage1_entry_0_n); end
    if (!$isunknown(g_io_resp_bits_stage1_entry_0_pbmt) && !$isunknown(i_io_resp_bits_stage1_entry_0_pbmt) && (g_io_resp_bits_stage1_entry_0_pbmt !== i_io_resp_bits_stage1_entry_0_pbmt)) begin errors++;
      if(errors<=80) $display("vec %0d io_resp_bits_stage1_entry_0_pbmt g=%h i=%h",t,g_io_resp_bits_stage1_entry_0_pbmt,i_io_resp_bits_stage1_entry_0_pbmt); end
    if (!$isunknown(g_io_resp_bits_stage1_entry_0_perm_d) && !$isunknown(i_io_resp_bits_stage1_entry_0_perm_d) && (g_io_resp_bits_stage1_entry_0_perm_d !== i_io_resp_bits_stage1_entry_0_perm_d)) begin errors++;
      if(errors<=80) $display("vec %0d io_resp_bits_stage1_entry_0_perm_d g=%b i=%b",t,g_io_resp_bits_stage1_entry_0_perm_d,i_io_resp_bits_stage1_entry_0_perm_d); end
    if (!$isunknown(g_io_resp_bits_stage1_entry_0_perm_a) && !$isunknown(i_io_resp_bits_stage1_entry_0_perm_a) && (g_io_resp_bits_stage1_entry_0_perm_a !== i_io_resp_bits_stage1_entry_0_perm_a)) begin errors++;
      if(errors<=80) $display("vec %0d io_resp_bits_stage1_entry_0_perm_a g=%b i=%b",t,g_io_resp_bits_stage1_entry_0_perm_a,i_io_resp_bits_stage1_entry_0_perm_a); end
    if (!$isunknown(g_io_resp_bits_stage1_entry_0_perm_g) && !$isunknown(i_io_resp_bits_stage1_entry_0_perm_g) && (g_io_resp_bits_stage1_entry_0_perm_g !== i_io_resp_bits_stage1_entry_0_perm_g)) begin errors++;
      if(errors<=80) $display("vec %0d io_resp_bits_stage1_entry_0_perm_g g=%b i=%b",t,g_io_resp_bits_stage1_entry_0_perm_g,i_io_resp_bits_stage1_entry_0_perm_g); end
    if (!$isunknown(g_io_resp_bits_stage1_entry_0_perm_u) && !$isunknown(i_io_resp_bits_stage1_entry_0_perm_u) && (g_io_resp_bits_stage1_entry_0_perm_u !== i_io_resp_bits_stage1_entry_0_perm_u)) begin errors++;
      if(errors<=80) $display("vec %0d io_resp_bits_stage1_entry_0_perm_u g=%b i=%b",t,g_io_resp_bits_stage1_entry_0_perm_u,i_io_resp_bits_stage1_entry_0_perm_u); end
    if (!$isunknown(g_io_resp_bits_stage1_entry_0_perm_x) && !$isunknown(i_io_resp_bits_stage1_entry_0_perm_x) && (g_io_resp_bits_stage1_entry_0_perm_x !== i_io_resp_bits_stage1_entry_0_perm_x)) begin errors++;
      if(errors<=80) $display("vec %0d io_resp_bits_stage1_entry_0_perm_x g=%b i=%b",t,g_io_resp_bits_stage1_entry_0_perm_x,i_io_resp_bits_stage1_entry_0_perm_x); end
    if (!$isunknown(g_io_resp_bits_stage1_entry_0_perm_w) && !$isunknown(i_io_resp_bits_stage1_entry_0_perm_w) && (g_io_resp_bits_stage1_entry_0_perm_w !== i_io_resp_bits_stage1_entry_0_perm_w)) begin errors++;
      if(errors<=80) $display("vec %0d io_resp_bits_stage1_entry_0_perm_w g=%b i=%b",t,g_io_resp_bits_stage1_entry_0_perm_w,i_io_resp_bits_stage1_entry_0_perm_w); end
    if (!$isunknown(g_io_resp_bits_stage1_entry_0_perm_r) && !$isunknown(i_io_resp_bits_stage1_entry_0_perm_r) && (g_io_resp_bits_stage1_entry_0_perm_r !== i_io_resp_bits_stage1_entry_0_perm_r)) begin errors++;
      if(errors<=80) $display("vec %0d io_resp_bits_stage1_entry_0_perm_r g=%b i=%b",t,g_io_resp_bits_stage1_entry_0_perm_r,i_io_resp_bits_stage1_entry_0_perm_r); end
    if (!$isunknown(g_io_resp_bits_stage1_entry_0_level) && !$isunknown(i_io_resp_bits_stage1_entry_0_level) && (g_io_resp_bits_stage1_entry_0_level !== i_io_resp_bits_stage1_entry_0_level)) begin errors++;
      if(errors<=80) $display("vec %0d io_resp_bits_stage1_entry_0_level g=%h i=%h",t,g_io_resp_bits_stage1_entry_0_level,i_io_resp_bits_stage1_entry_0_level); end
    if (!$isunknown(g_io_resp_bits_stage1_entry_0_v) && !$isunknown(i_io_resp_bits_stage1_entry_0_v) && (g_io_resp_bits_stage1_entry_0_v !== i_io_resp_bits_stage1_entry_0_v)) begin errors++;
      if(errors<=80) $display("vec %0d io_resp_bits_stage1_entry_0_v g=%b i=%b",t,g_io_resp_bits_stage1_entry_0_v,i_io_resp_bits_stage1_entry_0_v); end
    if (!$isunknown(g_io_resp_bits_stage1_entry_0_ppn) && !$isunknown(i_io_resp_bits_stage1_entry_0_ppn) && (g_io_resp_bits_stage1_entry_0_ppn !== i_io_resp_bits_stage1_entry_0_ppn)) begin errors++;
      if(errors<=80) $display("vec %0d io_resp_bits_stage1_entry_0_ppn g=%h i=%h",t,g_io_resp_bits_stage1_entry_0_ppn,i_io_resp_bits_stage1_entry_0_ppn); end
    if (!$isunknown(g_io_resp_bits_stage1_entry_0_ppn_low) && !$isunknown(i_io_resp_bits_stage1_entry_0_ppn_low) && (g_io_resp_bits_stage1_entry_0_ppn_low !== i_io_resp_bits_stage1_entry_0_ppn_low)) begin errors++;
      if(errors<=80) $display("vec %0d io_resp_bits_stage1_entry_0_ppn_low g=%h i=%h",t,g_io_resp_bits_stage1_entry_0_ppn_low,i_io_resp_bits_stage1_entry_0_ppn_low); end
    if (!$isunknown(g_io_resp_bits_stage1_entry_0_pf) && !$isunknown(i_io_resp_bits_stage1_entry_0_pf) && (g_io_resp_bits_stage1_entry_0_pf !== i_io_resp_bits_stage1_entry_0_pf)) begin errors++;
      if(errors<=80) $display("vec %0d io_resp_bits_stage1_entry_0_pf g=%b i=%b",t,g_io_resp_bits_stage1_entry_0_pf,i_io_resp_bits_stage1_entry_0_pf); end
    if (!$isunknown(g_io_resp_bits_stage1_entry_1_tag) && !$isunknown(i_io_resp_bits_stage1_entry_1_tag) && (g_io_resp_bits_stage1_entry_1_tag !== i_io_resp_bits_stage1_entry_1_tag)) begin errors++;
      if(errors<=80) $display("vec %0d io_resp_bits_stage1_entry_1_tag g=%h i=%h",t,g_io_resp_bits_stage1_entry_1_tag,i_io_resp_bits_stage1_entry_1_tag); end
    if (!$isunknown(g_io_resp_bits_stage1_entry_1_asid) && !$isunknown(i_io_resp_bits_stage1_entry_1_asid) && (g_io_resp_bits_stage1_entry_1_asid !== i_io_resp_bits_stage1_entry_1_asid)) begin errors++;
      if(errors<=80) $display("vec %0d io_resp_bits_stage1_entry_1_asid g=%h i=%h",t,g_io_resp_bits_stage1_entry_1_asid,i_io_resp_bits_stage1_entry_1_asid); end
    if (!$isunknown(g_io_resp_bits_stage1_entry_1_vmid) && !$isunknown(i_io_resp_bits_stage1_entry_1_vmid) && (g_io_resp_bits_stage1_entry_1_vmid !== i_io_resp_bits_stage1_entry_1_vmid)) begin errors++;
      if(errors<=80) $display("vec %0d io_resp_bits_stage1_entry_1_vmid g=%h i=%h",t,g_io_resp_bits_stage1_entry_1_vmid,i_io_resp_bits_stage1_entry_1_vmid); end
    if (!$isunknown(g_io_resp_bits_stage1_entry_1_n) && !$isunknown(i_io_resp_bits_stage1_entry_1_n) && (g_io_resp_bits_stage1_entry_1_n !== i_io_resp_bits_stage1_entry_1_n)) begin errors++;
      if(errors<=80) $display("vec %0d io_resp_bits_stage1_entry_1_n g=%b i=%b",t,g_io_resp_bits_stage1_entry_1_n,i_io_resp_bits_stage1_entry_1_n); end
    if (!$isunknown(g_io_resp_bits_stage1_entry_1_pbmt) && !$isunknown(i_io_resp_bits_stage1_entry_1_pbmt) && (g_io_resp_bits_stage1_entry_1_pbmt !== i_io_resp_bits_stage1_entry_1_pbmt)) begin errors++;
      if(errors<=80) $display("vec %0d io_resp_bits_stage1_entry_1_pbmt g=%h i=%h",t,g_io_resp_bits_stage1_entry_1_pbmt,i_io_resp_bits_stage1_entry_1_pbmt); end
    if (!$isunknown(g_io_resp_bits_stage1_entry_1_perm_d) && !$isunknown(i_io_resp_bits_stage1_entry_1_perm_d) && (g_io_resp_bits_stage1_entry_1_perm_d !== i_io_resp_bits_stage1_entry_1_perm_d)) begin errors++;
      if(errors<=80) $display("vec %0d io_resp_bits_stage1_entry_1_perm_d g=%b i=%b",t,g_io_resp_bits_stage1_entry_1_perm_d,i_io_resp_bits_stage1_entry_1_perm_d); end
    if (!$isunknown(g_io_resp_bits_stage1_entry_1_perm_a) && !$isunknown(i_io_resp_bits_stage1_entry_1_perm_a) && (g_io_resp_bits_stage1_entry_1_perm_a !== i_io_resp_bits_stage1_entry_1_perm_a)) begin errors++;
      if(errors<=80) $display("vec %0d io_resp_bits_stage1_entry_1_perm_a g=%b i=%b",t,g_io_resp_bits_stage1_entry_1_perm_a,i_io_resp_bits_stage1_entry_1_perm_a); end
    if (!$isunknown(g_io_resp_bits_stage1_entry_1_perm_g) && !$isunknown(i_io_resp_bits_stage1_entry_1_perm_g) && (g_io_resp_bits_stage1_entry_1_perm_g !== i_io_resp_bits_stage1_entry_1_perm_g)) begin errors++;
      if(errors<=80) $display("vec %0d io_resp_bits_stage1_entry_1_perm_g g=%b i=%b",t,g_io_resp_bits_stage1_entry_1_perm_g,i_io_resp_bits_stage1_entry_1_perm_g); end
    if (!$isunknown(g_io_resp_bits_stage1_entry_1_perm_u) && !$isunknown(i_io_resp_bits_stage1_entry_1_perm_u) && (g_io_resp_bits_stage1_entry_1_perm_u !== i_io_resp_bits_stage1_entry_1_perm_u)) begin errors++;
      if(errors<=80) $display("vec %0d io_resp_bits_stage1_entry_1_perm_u g=%b i=%b",t,g_io_resp_bits_stage1_entry_1_perm_u,i_io_resp_bits_stage1_entry_1_perm_u); end
    if (!$isunknown(g_io_resp_bits_stage1_entry_1_perm_x) && !$isunknown(i_io_resp_bits_stage1_entry_1_perm_x) && (g_io_resp_bits_stage1_entry_1_perm_x !== i_io_resp_bits_stage1_entry_1_perm_x)) begin errors++;
      if(errors<=80) $display("vec %0d io_resp_bits_stage1_entry_1_perm_x g=%b i=%b",t,g_io_resp_bits_stage1_entry_1_perm_x,i_io_resp_bits_stage1_entry_1_perm_x); end
    if (!$isunknown(g_io_resp_bits_stage1_entry_1_perm_w) && !$isunknown(i_io_resp_bits_stage1_entry_1_perm_w) && (g_io_resp_bits_stage1_entry_1_perm_w !== i_io_resp_bits_stage1_entry_1_perm_w)) begin errors++;
      if(errors<=80) $display("vec %0d io_resp_bits_stage1_entry_1_perm_w g=%b i=%b",t,g_io_resp_bits_stage1_entry_1_perm_w,i_io_resp_bits_stage1_entry_1_perm_w); end
    if (!$isunknown(g_io_resp_bits_stage1_entry_1_perm_r) && !$isunknown(i_io_resp_bits_stage1_entry_1_perm_r) && (g_io_resp_bits_stage1_entry_1_perm_r !== i_io_resp_bits_stage1_entry_1_perm_r)) begin errors++;
      if(errors<=80) $display("vec %0d io_resp_bits_stage1_entry_1_perm_r g=%b i=%b",t,g_io_resp_bits_stage1_entry_1_perm_r,i_io_resp_bits_stage1_entry_1_perm_r); end
    if (!$isunknown(g_io_resp_bits_stage1_entry_1_level) && !$isunknown(i_io_resp_bits_stage1_entry_1_level) && (g_io_resp_bits_stage1_entry_1_level !== i_io_resp_bits_stage1_entry_1_level)) begin errors++;
      if(errors<=80) $display("vec %0d io_resp_bits_stage1_entry_1_level g=%h i=%h",t,g_io_resp_bits_stage1_entry_1_level,i_io_resp_bits_stage1_entry_1_level); end
    if (!$isunknown(g_io_resp_bits_stage1_entry_1_v) && !$isunknown(i_io_resp_bits_stage1_entry_1_v) && (g_io_resp_bits_stage1_entry_1_v !== i_io_resp_bits_stage1_entry_1_v)) begin errors++;
      if(errors<=80) $display("vec %0d io_resp_bits_stage1_entry_1_v g=%b i=%b",t,g_io_resp_bits_stage1_entry_1_v,i_io_resp_bits_stage1_entry_1_v); end
    if (!$isunknown(g_io_resp_bits_stage1_entry_1_ppn) && !$isunknown(i_io_resp_bits_stage1_entry_1_ppn) && (g_io_resp_bits_stage1_entry_1_ppn !== i_io_resp_bits_stage1_entry_1_ppn)) begin errors++;
      if(errors<=80) $display("vec %0d io_resp_bits_stage1_entry_1_ppn g=%h i=%h",t,g_io_resp_bits_stage1_entry_1_ppn,i_io_resp_bits_stage1_entry_1_ppn); end
    if (!$isunknown(g_io_resp_bits_stage1_entry_1_ppn_low) && !$isunknown(i_io_resp_bits_stage1_entry_1_ppn_low) && (g_io_resp_bits_stage1_entry_1_ppn_low !== i_io_resp_bits_stage1_entry_1_ppn_low)) begin errors++;
      if(errors<=80) $display("vec %0d io_resp_bits_stage1_entry_1_ppn_low g=%h i=%h",t,g_io_resp_bits_stage1_entry_1_ppn_low,i_io_resp_bits_stage1_entry_1_ppn_low); end
    if (!$isunknown(g_io_resp_bits_stage1_entry_1_pf) && !$isunknown(i_io_resp_bits_stage1_entry_1_pf) && (g_io_resp_bits_stage1_entry_1_pf !== i_io_resp_bits_stage1_entry_1_pf)) begin errors++;
      if(errors<=80) $display("vec %0d io_resp_bits_stage1_entry_1_pf g=%b i=%b",t,g_io_resp_bits_stage1_entry_1_pf,i_io_resp_bits_stage1_entry_1_pf); end
    if (!$isunknown(g_io_resp_bits_stage1_entry_2_tag) && !$isunknown(i_io_resp_bits_stage1_entry_2_tag) && (g_io_resp_bits_stage1_entry_2_tag !== i_io_resp_bits_stage1_entry_2_tag)) begin errors++;
      if(errors<=80) $display("vec %0d io_resp_bits_stage1_entry_2_tag g=%h i=%h",t,g_io_resp_bits_stage1_entry_2_tag,i_io_resp_bits_stage1_entry_2_tag); end
    if (!$isunknown(g_io_resp_bits_stage1_entry_2_asid) && !$isunknown(i_io_resp_bits_stage1_entry_2_asid) && (g_io_resp_bits_stage1_entry_2_asid !== i_io_resp_bits_stage1_entry_2_asid)) begin errors++;
      if(errors<=80) $display("vec %0d io_resp_bits_stage1_entry_2_asid g=%h i=%h",t,g_io_resp_bits_stage1_entry_2_asid,i_io_resp_bits_stage1_entry_2_asid); end
    if (!$isunknown(g_io_resp_bits_stage1_entry_2_vmid) && !$isunknown(i_io_resp_bits_stage1_entry_2_vmid) && (g_io_resp_bits_stage1_entry_2_vmid !== i_io_resp_bits_stage1_entry_2_vmid)) begin errors++;
      if(errors<=80) $display("vec %0d io_resp_bits_stage1_entry_2_vmid g=%h i=%h",t,g_io_resp_bits_stage1_entry_2_vmid,i_io_resp_bits_stage1_entry_2_vmid); end
    if (!$isunknown(g_io_resp_bits_stage1_entry_2_n) && !$isunknown(i_io_resp_bits_stage1_entry_2_n) && (g_io_resp_bits_stage1_entry_2_n !== i_io_resp_bits_stage1_entry_2_n)) begin errors++;
      if(errors<=80) $display("vec %0d io_resp_bits_stage1_entry_2_n g=%b i=%b",t,g_io_resp_bits_stage1_entry_2_n,i_io_resp_bits_stage1_entry_2_n); end
    if (!$isunknown(g_io_resp_bits_stage1_entry_2_pbmt) && !$isunknown(i_io_resp_bits_stage1_entry_2_pbmt) && (g_io_resp_bits_stage1_entry_2_pbmt !== i_io_resp_bits_stage1_entry_2_pbmt)) begin errors++;
      if(errors<=80) $display("vec %0d io_resp_bits_stage1_entry_2_pbmt g=%h i=%h",t,g_io_resp_bits_stage1_entry_2_pbmt,i_io_resp_bits_stage1_entry_2_pbmt); end
    if (!$isunknown(g_io_resp_bits_stage1_entry_2_perm_d) && !$isunknown(i_io_resp_bits_stage1_entry_2_perm_d) && (g_io_resp_bits_stage1_entry_2_perm_d !== i_io_resp_bits_stage1_entry_2_perm_d)) begin errors++;
      if(errors<=80) $display("vec %0d io_resp_bits_stage1_entry_2_perm_d g=%b i=%b",t,g_io_resp_bits_stage1_entry_2_perm_d,i_io_resp_bits_stage1_entry_2_perm_d); end
    if (!$isunknown(g_io_resp_bits_stage1_entry_2_perm_a) && !$isunknown(i_io_resp_bits_stage1_entry_2_perm_a) && (g_io_resp_bits_stage1_entry_2_perm_a !== i_io_resp_bits_stage1_entry_2_perm_a)) begin errors++;
      if(errors<=80) $display("vec %0d io_resp_bits_stage1_entry_2_perm_a g=%b i=%b",t,g_io_resp_bits_stage1_entry_2_perm_a,i_io_resp_bits_stage1_entry_2_perm_a); end
    if (!$isunknown(g_io_resp_bits_stage1_entry_2_perm_g) && !$isunknown(i_io_resp_bits_stage1_entry_2_perm_g) && (g_io_resp_bits_stage1_entry_2_perm_g !== i_io_resp_bits_stage1_entry_2_perm_g)) begin errors++;
      if(errors<=80) $display("vec %0d io_resp_bits_stage1_entry_2_perm_g g=%b i=%b",t,g_io_resp_bits_stage1_entry_2_perm_g,i_io_resp_bits_stage1_entry_2_perm_g); end
    if (!$isunknown(g_io_resp_bits_stage1_entry_2_perm_u) && !$isunknown(i_io_resp_bits_stage1_entry_2_perm_u) && (g_io_resp_bits_stage1_entry_2_perm_u !== i_io_resp_bits_stage1_entry_2_perm_u)) begin errors++;
      if(errors<=80) $display("vec %0d io_resp_bits_stage1_entry_2_perm_u g=%b i=%b",t,g_io_resp_bits_stage1_entry_2_perm_u,i_io_resp_bits_stage1_entry_2_perm_u); end
    if (!$isunknown(g_io_resp_bits_stage1_entry_2_perm_x) && !$isunknown(i_io_resp_bits_stage1_entry_2_perm_x) && (g_io_resp_bits_stage1_entry_2_perm_x !== i_io_resp_bits_stage1_entry_2_perm_x)) begin errors++;
      if(errors<=80) $display("vec %0d io_resp_bits_stage1_entry_2_perm_x g=%b i=%b",t,g_io_resp_bits_stage1_entry_2_perm_x,i_io_resp_bits_stage1_entry_2_perm_x); end
    if (!$isunknown(g_io_resp_bits_stage1_entry_2_perm_w) && !$isunknown(i_io_resp_bits_stage1_entry_2_perm_w) && (g_io_resp_bits_stage1_entry_2_perm_w !== i_io_resp_bits_stage1_entry_2_perm_w)) begin errors++;
      if(errors<=80) $display("vec %0d io_resp_bits_stage1_entry_2_perm_w g=%b i=%b",t,g_io_resp_bits_stage1_entry_2_perm_w,i_io_resp_bits_stage1_entry_2_perm_w); end
    if (!$isunknown(g_io_resp_bits_stage1_entry_2_perm_r) && !$isunknown(i_io_resp_bits_stage1_entry_2_perm_r) && (g_io_resp_bits_stage1_entry_2_perm_r !== i_io_resp_bits_stage1_entry_2_perm_r)) begin errors++;
      if(errors<=80) $display("vec %0d io_resp_bits_stage1_entry_2_perm_r g=%b i=%b",t,g_io_resp_bits_stage1_entry_2_perm_r,i_io_resp_bits_stage1_entry_2_perm_r); end
    if (!$isunknown(g_io_resp_bits_stage1_entry_2_level) && !$isunknown(i_io_resp_bits_stage1_entry_2_level) && (g_io_resp_bits_stage1_entry_2_level !== i_io_resp_bits_stage1_entry_2_level)) begin errors++;
      if(errors<=80) $display("vec %0d io_resp_bits_stage1_entry_2_level g=%h i=%h",t,g_io_resp_bits_stage1_entry_2_level,i_io_resp_bits_stage1_entry_2_level); end
    if (!$isunknown(g_io_resp_bits_stage1_entry_2_v) && !$isunknown(i_io_resp_bits_stage1_entry_2_v) && (g_io_resp_bits_stage1_entry_2_v !== i_io_resp_bits_stage1_entry_2_v)) begin errors++;
      if(errors<=80) $display("vec %0d io_resp_bits_stage1_entry_2_v g=%b i=%b",t,g_io_resp_bits_stage1_entry_2_v,i_io_resp_bits_stage1_entry_2_v); end
    if (!$isunknown(g_io_resp_bits_stage1_entry_2_ppn) && !$isunknown(i_io_resp_bits_stage1_entry_2_ppn) && (g_io_resp_bits_stage1_entry_2_ppn !== i_io_resp_bits_stage1_entry_2_ppn)) begin errors++;
      if(errors<=80) $display("vec %0d io_resp_bits_stage1_entry_2_ppn g=%h i=%h",t,g_io_resp_bits_stage1_entry_2_ppn,i_io_resp_bits_stage1_entry_2_ppn); end
    if (!$isunknown(g_io_resp_bits_stage1_entry_2_ppn_low) && !$isunknown(i_io_resp_bits_stage1_entry_2_ppn_low) && (g_io_resp_bits_stage1_entry_2_ppn_low !== i_io_resp_bits_stage1_entry_2_ppn_low)) begin errors++;
      if(errors<=80) $display("vec %0d io_resp_bits_stage1_entry_2_ppn_low g=%h i=%h",t,g_io_resp_bits_stage1_entry_2_ppn_low,i_io_resp_bits_stage1_entry_2_ppn_low); end
    if (!$isunknown(g_io_resp_bits_stage1_entry_2_pf) && !$isunknown(i_io_resp_bits_stage1_entry_2_pf) && (g_io_resp_bits_stage1_entry_2_pf !== i_io_resp_bits_stage1_entry_2_pf)) begin errors++;
      if(errors<=80) $display("vec %0d io_resp_bits_stage1_entry_2_pf g=%b i=%b",t,g_io_resp_bits_stage1_entry_2_pf,i_io_resp_bits_stage1_entry_2_pf); end
    if (!$isunknown(g_io_resp_bits_stage1_entry_3_tag) && !$isunknown(i_io_resp_bits_stage1_entry_3_tag) && (g_io_resp_bits_stage1_entry_3_tag !== i_io_resp_bits_stage1_entry_3_tag)) begin errors++;
      if(errors<=80) $display("vec %0d io_resp_bits_stage1_entry_3_tag g=%h i=%h",t,g_io_resp_bits_stage1_entry_3_tag,i_io_resp_bits_stage1_entry_3_tag); end
    if (!$isunknown(g_io_resp_bits_stage1_entry_3_asid) && !$isunknown(i_io_resp_bits_stage1_entry_3_asid) && (g_io_resp_bits_stage1_entry_3_asid !== i_io_resp_bits_stage1_entry_3_asid)) begin errors++;
      if(errors<=80) $display("vec %0d io_resp_bits_stage1_entry_3_asid g=%h i=%h",t,g_io_resp_bits_stage1_entry_3_asid,i_io_resp_bits_stage1_entry_3_asid); end
    if (!$isunknown(g_io_resp_bits_stage1_entry_3_vmid) && !$isunknown(i_io_resp_bits_stage1_entry_3_vmid) && (g_io_resp_bits_stage1_entry_3_vmid !== i_io_resp_bits_stage1_entry_3_vmid)) begin errors++;
      if(errors<=80) $display("vec %0d io_resp_bits_stage1_entry_3_vmid g=%h i=%h",t,g_io_resp_bits_stage1_entry_3_vmid,i_io_resp_bits_stage1_entry_3_vmid); end
    if (!$isunknown(g_io_resp_bits_stage1_entry_3_n) && !$isunknown(i_io_resp_bits_stage1_entry_3_n) && (g_io_resp_bits_stage1_entry_3_n !== i_io_resp_bits_stage1_entry_3_n)) begin errors++;
      if(errors<=80) $display("vec %0d io_resp_bits_stage1_entry_3_n g=%b i=%b",t,g_io_resp_bits_stage1_entry_3_n,i_io_resp_bits_stage1_entry_3_n); end
    if (!$isunknown(g_io_resp_bits_stage1_entry_3_pbmt) && !$isunknown(i_io_resp_bits_stage1_entry_3_pbmt) && (g_io_resp_bits_stage1_entry_3_pbmt !== i_io_resp_bits_stage1_entry_3_pbmt)) begin errors++;
      if(errors<=80) $display("vec %0d io_resp_bits_stage1_entry_3_pbmt g=%h i=%h",t,g_io_resp_bits_stage1_entry_3_pbmt,i_io_resp_bits_stage1_entry_3_pbmt); end
    if (!$isunknown(g_io_resp_bits_stage1_entry_3_perm_d) && !$isunknown(i_io_resp_bits_stage1_entry_3_perm_d) && (g_io_resp_bits_stage1_entry_3_perm_d !== i_io_resp_bits_stage1_entry_3_perm_d)) begin errors++;
      if(errors<=80) $display("vec %0d io_resp_bits_stage1_entry_3_perm_d g=%b i=%b",t,g_io_resp_bits_stage1_entry_3_perm_d,i_io_resp_bits_stage1_entry_3_perm_d); end
    if (!$isunknown(g_io_resp_bits_stage1_entry_3_perm_a) && !$isunknown(i_io_resp_bits_stage1_entry_3_perm_a) && (g_io_resp_bits_stage1_entry_3_perm_a !== i_io_resp_bits_stage1_entry_3_perm_a)) begin errors++;
      if(errors<=80) $display("vec %0d io_resp_bits_stage1_entry_3_perm_a g=%b i=%b",t,g_io_resp_bits_stage1_entry_3_perm_a,i_io_resp_bits_stage1_entry_3_perm_a); end
    if (!$isunknown(g_io_resp_bits_stage1_entry_3_perm_g) && !$isunknown(i_io_resp_bits_stage1_entry_3_perm_g) && (g_io_resp_bits_stage1_entry_3_perm_g !== i_io_resp_bits_stage1_entry_3_perm_g)) begin errors++;
      if(errors<=80) $display("vec %0d io_resp_bits_stage1_entry_3_perm_g g=%b i=%b",t,g_io_resp_bits_stage1_entry_3_perm_g,i_io_resp_bits_stage1_entry_3_perm_g); end
    if (!$isunknown(g_io_resp_bits_stage1_entry_3_perm_u) && !$isunknown(i_io_resp_bits_stage1_entry_3_perm_u) && (g_io_resp_bits_stage1_entry_3_perm_u !== i_io_resp_bits_stage1_entry_3_perm_u)) begin errors++;
      if(errors<=80) $display("vec %0d io_resp_bits_stage1_entry_3_perm_u g=%b i=%b",t,g_io_resp_bits_stage1_entry_3_perm_u,i_io_resp_bits_stage1_entry_3_perm_u); end
    if (!$isunknown(g_io_resp_bits_stage1_entry_3_perm_x) && !$isunknown(i_io_resp_bits_stage1_entry_3_perm_x) && (g_io_resp_bits_stage1_entry_3_perm_x !== i_io_resp_bits_stage1_entry_3_perm_x)) begin errors++;
      if(errors<=80) $display("vec %0d io_resp_bits_stage1_entry_3_perm_x g=%b i=%b",t,g_io_resp_bits_stage1_entry_3_perm_x,i_io_resp_bits_stage1_entry_3_perm_x); end
    if (!$isunknown(g_io_resp_bits_stage1_entry_3_perm_w) && !$isunknown(i_io_resp_bits_stage1_entry_3_perm_w) && (g_io_resp_bits_stage1_entry_3_perm_w !== i_io_resp_bits_stage1_entry_3_perm_w)) begin errors++;
      if(errors<=80) $display("vec %0d io_resp_bits_stage1_entry_3_perm_w g=%b i=%b",t,g_io_resp_bits_stage1_entry_3_perm_w,i_io_resp_bits_stage1_entry_3_perm_w); end
    if (!$isunknown(g_io_resp_bits_stage1_entry_3_perm_r) && !$isunknown(i_io_resp_bits_stage1_entry_3_perm_r) && (g_io_resp_bits_stage1_entry_3_perm_r !== i_io_resp_bits_stage1_entry_3_perm_r)) begin errors++;
      if(errors<=80) $display("vec %0d io_resp_bits_stage1_entry_3_perm_r g=%b i=%b",t,g_io_resp_bits_stage1_entry_3_perm_r,i_io_resp_bits_stage1_entry_3_perm_r); end
    if (!$isunknown(g_io_resp_bits_stage1_entry_3_level) && !$isunknown(i_io_resp_bits_stage1_entry_3_level) && (g_io_resp_bits_stage1_entry_3_level !== i_io_resp_bits_stage1_entry_3_level)) begin errors++;
      if(errors<=80) $display("vec %0d io_resp_bits_stage1_entry_3_level g=%h i=%h",t,g_io_resp_bits_stage1_entry_3_level,i_io_resp_bits_stage1_entry_3_level); end
    if (!$isunknown(g_io_resp_bits_stage1_entry_3_v) && !$isunknown(i_io_resp_bits_stage1_entry_3_v) && (g_io_resp_bits_stage1_entry_3_v !== i_io_resp_bits_stage1_entry_3_v)) begin errors++;
      if(errors<=80) $display("vec %0d io_resp_bits_stage1_entry_3_v g=%b i=%b",t,g_io_resp_bits_stage1_entry_3_v,i_io_resp_bits_stage1_entry_3_v); end
    if (!$isunknown(g_io_resp_bits_stage1_entry_3_ppn) && !$isunknown(i_io_resp_bits_stage1_entry_3_ppn) && (g_io_resp_bits_stage1_entry_3_ppn !== i_io_resp_bits_stage1_entry_3_ppn)) begin errors++;
      if(errors<=80) $display("vec %0d io_resp_bits_stage1_entry_3_ppn g=%h i=%h",t,g_io_resp_bits_stage1_entry_3_ppn,i_io_resp_bits_stage1_entry_3_ppn); end
    if (!$isunknown(g_io_resp_bits_stage1_entry_3_ppn_low) && !$isunknown(i_io_resp_bits_stage1_entry_3_ppn_low) && (g_io_resp_bits_stage1_entry_3_ppn_low !== i_io_resp_bits_stage1_entry_3_ppn_low)) begin errors++;
      if(errors<=80) $display("vec %0d io_resp_bits_stage1_entry_3_ppn_low g=%h i=%h",t,g_io_resp_bits_stage1_entry_3_ppn_low,i_io_resp_bits_stage1_entry_3_ppn_low); end
    if (!$isunknown(g_io_resp_bits_stage1_entry_3_pf) && !$isunknown(i_io_resp_bits_stage1_entry_3_pf) && (g_io_resp_bits_stage1_entry_3_pf !== i_io_resp_bits_stage1_entry_3_pf)) begin errors++;
      if(errors<=80) $display("vec %0d io_resp_bits_stage1_entry_3_pf g=%b i=%b",t,g_io_resp_bits_stage1_entry_3_pf,i_io_resp_bits_stage1_entry_3_pf); end
    if (!$isunknown(g_io_resp_bits_stage1_entry_4_tag) && !$isunknown(i_io_resp_bits_stage1_entry_4_tag) && (g_io_resp_bits_stage1_entry_4_tag !== i_io_resp_bits_stage1_entry_4_tag)) begin errors++;
      if(errors<=80) $display("vec %0d io_resp_bits_stage1_entry_4_tag g=%h i=%h",t,g_io_resp_bits_stage1_entry_4_tag,i_io_resp_bits_stage1_entry_4_tag); end
    if (!$isunknown(g_io_resp_bits_stage1_entry_4_asid) && !$isunknown(i_io_resp_bits_stage1_entry_4_asid) && (g_io_resp_bits_stage1_entry_4_asid !== i_io_resp_bits_stage1_entry_4_asid)) begin errors++;
      if(errors<=80) $display("vec %0d io_resp_bits_stage1_entry_4_asid g=%h i=%h",t,g_io_resp_bits_stage1_entry_4_asid,i_io_resp_bits_stage1_entry_4_asid); end
    if (!$isunknown(g_io_resp_bits_stage1_entry_4_vmid) && !$isunknown(i_io_resp_bits_stage1_entry_4_vmid) && (g_io_resp_bits_stage1_entry_4_vmid !== i_io_resp_bits_stage1_entry_4_vmid)) begin errors++;
      if(errors<=80) $display("vec %0d io_resp_bits_stage1_entry_4_vmid g=%h i=%h",t,g_io_resp_bits_stage1_entry_4_vmid,i_io_resp_bits_stage1_entry_4_vmid); end
    if (!$isunknown(g_io_resp_bits_stage1_entry_4_n) && !$isunknown(i_io_resp_bits_stage1_entry_4_n) && (g_io_resp_bits_stage1_entry_4_n !== i_io_resp_bits_stage1_entry_4_n)) begin errors++;
      if(errors<=80) $display("vec %0d io_resp_bits_stage1_entry_4_n g=%b i=%b",t,g_io_resp_bits_stage1_entry_4_n,i_io_resp_bits_stage1_entry_4_n); end
    if (!$isunknown(g_io_resp_bits_stage1_entry_4_pbmt) && !$isunknown(i_io_resp_bits_stage1_entry_4_pbmt) && (g_io_resp_bits_stage1_entry_4_pbmt !== i_io_resp_bits_stage1_entry_4_pbmt)) begin errors++;
      if(errors<=80) $display("vec %0d io_resp_bits_stage1_entry_4_pbmt g=%h i=%h",t,g_io_resp_bits_stage1_entry_4_pbmt,i_io_resp_bits_stage1_entry_4_pbmt); end
    if (!$isunknown(g_io_resp_bits_stage1_entry_4_perm_d) && !$isunknown(i_io_resp_bits_stage1_entry_4_perm_d) && (g_io_resp_bits_stage1_entry_4_perm_d !== i_io_resp_bits_stage1_entry_4_perm_d)) begin errors++;
      if(errors<=80) $display("vec %0d io_resp_bits_stage1_entry_4_perm_d g=%b i=%b",t,g_io_resp_bits_stage1_entry_4_perm_d,i_io_resp_bits_stage1_entry_4_perm_d); end
    if (!$isunknown(g_io_resp_bits_stage1_entry_4_perm_a) && !$isunknown(i_io_resp_bits_stage1_entry_4_perm_a) && (g_io_resp_bits_stage1_entry_4_perm_a !== i_io_resp_bits_stage1_entry_4_perm_a)) begin errors++;
      if(errors<=80) $display("vec %0d io_resp_bits_stage1_entry_4_perm_a g=%b i=%b",t,g_io_resp_bits_stage1_entry_4_perm_a,i_io_resp_bits_stage1_entry_4_perm_a); end
    if (!$isunknown(g_io_resp_bits_stage1_entry_4_perm_g) && !$isunknown(i_io_resp_bits_stage1_entry_4_perm_g) && (g_io_resp_bits_stage1_entry_4_perm_g !== i_io_resp_bits_stage1_entry_4_perm_g)) begin errors++;
      if(errors<=80) $display("vec %0d io_resp_bits_stage1_entry_4_perm_g g=%b i=%b",t,g_io_resp_bits_stage1_entry_4_perm_g,i_io_resp_bits_stage1_entry_4_perm_g); end
    if (!$isunknown(g_io_resp_bits_stage1_entry_4_perm_u) && !$isunknown(i_io_resp_bits_stage1_entry_4_perm_u) && (g_io_resp_bits_stage1_entry_4_perm_u !== i_io_resp_bits_stage1_entry_4_perm_u)) begin errors++;
      if(errors<=80) $display("vec %0d io_resp_bits_stage1_entry_4_perm_u g=%b i=%b",t,g_io_resp_bits_stage1_entry_4_perm_u,i_io_resp_bits_stage1_entry_4_perm_u); end
    if (!$isunknown(g_io_resp_bits_stage1_entry_4_perm_x) && !$isunknown(i_io_resp_bits_stage1_entry_4_perm_x) && (g_io_resp_bits_stage1_entry_4_perm_x !== i_io_resp_bits_stage1_entry_4_perm_x)) begin errors++;
      if(errors<=80) $display("vec %0d io_resp_bits_stage1_entry_4_perm_x g=%b i=%b",t,g_io_resp_bits_stage1_entry_4_perm_x,i_io_resp_bits_stage1_entry_4_perm_x); end
    if (!$isunknown(g_io_resp_bits_stage1_entry_4_perm_w) && !$isunknown(i_io_resp_bits_stage1_entry_4_perm_w) && (g_io_resp_bits_stage1_entry_4_perm_w !== i_io_resp_bits_stage1_entry_4_perm_w)) begin errors++;
      if(errors<=80) $display("vec %0d io_resp_bits_stage1_entry_4_perm_w g=%b i=%b",t,g_io_resp_bits_stage1_entry_4_perm_w,i_io_resp_bits_stage1_entry_4_perm_w); end
    if (!$isunknown(g_io_resp_bits_stage1_entry_4_perm_r) && !$isunknown(i_io_resp_bits_stage1_entry_4_perm_r) && (g_io_resp_bits_stage1_entry_4_perm_r !== i_io_resp_bits_stage1_entry_4_perm_r)) begin errors++;
      if(errors<=80) $display("vec %0d io_resp_bits_stage1_entry_4_perm_r g=%b i=%b",t,g_io_resp_bits_stage1_entry_4_perm_r,i_io_resp_bits_stage1_entry_4_perm_r); end
    if (!$isunknown(g_io_resp_bits_stage1_entry_4_level) && !$isunknown(i_io_resp_bits_stage1_entry_4_level) && (g_io_resp_bits_stage1_entry_4_level !== i_io_resp_bits_stage1_entry_4_level)) begin errors++;
      if(errors<=80) $display("vec %0d io_resp_bits_stage1_entry_4_level g=%h i=%h",t,g_io_resp_bits_stage1_entry_4_level,i_io_resp_bits_stage1_entry_4_level); end
    if (!$isunknown(g_io_resp_bits_stage1_entry_4_v) && !$isunknown(i_io_resp_bits_stage1_entry_4_v) && (g_io_resp_bits_stage1_entry_4_v !== i_io_resp_bits_stage1_entry_4_v)) begin errors++;
      if(errors<=80) $display("vec %0d io_resp_bits_stage1_entry_4_v g=%b i=%b",t,g_io_resp_bits_stage1_entry_4_v,i_io_resp_bits_stage1_entry_4_v); end
    if (!$isunknown(g_io_resp_bits_stage1_entry_4_ppn) && !$isunknown(i_io_resp_bits_stage1_entry_4_ppn) && (g_io_resp_bits_stage1_entry_4_ppn !== i_io_resp_bits_stage1_entry_4_ppn)) begin errors++;
      if(errors<=80) $display("vec %0d io_resp_bits_stage1_entry_4_ppn g=%h i=%h",t,g_io_resp_bits_stage1_entry_4_ppn,i_io_resp_bits_stage1_entry_4_ppn); end
    if (!$isunknown(g_io_resp_bits_stage1_entry_4_ppn_low) && !$isunknown(i_io_resp_bits_stage1_entry_4_ppn_low) && (g_io_resp_bits_stage1_entry_4_ppn_low !== i_io_resp_bits_stage1_entry_4_ppn_low)) begin errors++;
      if(errors<=80) $display("vec %0d io_resp_bits_stage1_entry_4_ppn_low g=%h i=%h",t,g_io_resp_bits_stage1_entry_4_ppn_low,i_io_resp_bits_stage1_entry_4_ppn_low); end
    if (!$isunknown(g_io_resp_bits_stage1_entry_4_pf) && !$isunknown(i_io_resp_bits_stage1_entry_4_pf) && (g_io_resp_bits_stage1_entry_4_pf !== i_io_resp_bits_stage1_entry_4_pf)) begin errors++;
      if(errors<=80) $display("vec %0d io_resp_bits_stage1_entry_4_pf g=%b i=%b",t,g_io_resp_bits_stage1_entry_4_pf,i_io_resp_bits_stage1_entry_4_pf); end
    if (!$isunknown(g_io_resp_bits_stage1_entry_5_tag) && !$isunknown(i_io_resp_bits_stage1_entry_5_tag) && (g_io_resp_bits_stage1_entry_5_tag !== i_io_resp_bits_stage1_entry_5_tag)) begin errors++;
      if(errors<=80) $display("vec %0d io_resp_bits_stage1_entry_5_tag g=%h i=%h",t,g_io_resp_bits_stage1_entry_5_tag,i_io_resp_bits_stage1_entry_5_tag); end
    if (!$isunknown(g_io_resp_bits_stage1_entry_5_asid) && !$isunknown(i_io_resp_bits_stage1_entry_5_asid) && (g_io_resp_bits_stage1_entry_5_asid !== i_io_resp_bits_stage1_entry_5_asid)) begin errors++;
      if(errors<=80) $display("vec %0d io_resp_bits_stage1_entry_5_asid g=%h i=%h",t,g_io_resp_bits_stage1_entry_5_asid,i_io_resp_bits_stage1_entry_5_asid); end
    if (!$isunknown(g_io_resp_bits_stage1_entry_5_vmid) && !$isunknown(i_io_resp_bits_stage1_entry_5_vmid) && (g_io_resp_bits_stage1_entry_5_vmid !== i_io_resp_bits_stage1_entry_5_vmid)) begin errors++;
      if(errors<=80) $display("vec %0d io_resp_bits_stage1_entry_5_vmid g=%h i=%h",t,g_io_resp_bits_stage1_entry_5_vmid,i_io_resp_bits_stage1_entry_5_vmid); end
    if (!$isunknown(g_io_resp_bits_stage1_entry_5_n) && !$isunknown(i_io_resp_bits_stage1_entry_5_n) && (g_io_resp_bits_stage1_entry_5_n !== i_io_resp_bits_stage1_entry_5_n)) begin errors++;
      if(errors<=80) $display("vec %0d io_resp_bits_stage1_entry_5_n g=%b i=%b",t,g_io_resp_bits_stage1_entry_5_n,i_io_resp_bits_stage1_entry_5_n); end
    if (!$isunknown(g_io_resp_bits_stage1_entry_5_pbmt) && !$isunknown(i_io_resp_bits_stage1_entry_5_pbmt) && (g_io_resp_bits_stage1_entry_5_pbmt !== i_io_resp_bits_stage1_entry_5_pbmt)) begin errors++;
      if(errors<=80) $display("vec %0d io_resp_bits_stage1_entry_5_pbmt g=%h i=%h",t,g_io_resp_bits_stage1_entry_5_pbmt,i_io_resp_bits_stage1_entry_5_pbmt); end
    if (!$isunknown(g_io_resp_bits_stage1_entry_5_perm_d) && !$isunknown(i_io_resp_bits_stage1_entry_5_perm_d) && (g_io_resp_bits_stage1_entry_5_perm_d !== i_io_resp_bits_stage1_entry_5_perm_d)) begin errors++;
      if(errors<=80) $display("vec %0d io_resp_bits_stage1_entry_5_perm_d g=%b i=%b",t,g_io_resp_bits_stage1_entry_5_perm_d,i_io_resp_bits_stage1_entry_5_perm_d); end
    if (!$isunknown(g_io_resp_bits_stage1_entry_5_perm_a) && !$isunknown(i_io_resp_bits_stage1_entry_5_perm_a) && (g_io_resp_bits_stage1_entry_5_perm_a !== i_io_resp_bits_stage1_entry_5_perm_a)) begin errors++;
      if(errors<=80) $display("vec %0d io_resp_bits_stage1_entry_5_perm_a g=%b i=%b",t,g_io_resp_bits_stage1_entry_5_perm_a,i_io_resp_bits_stage1_entry_5_perm_a); end
    if (!$isunknown(g_io_resp_bits_stage1_entry_5_perm_g) && !$isunknown(i_io_resp_bits_stage1_entry_5_perm_g) && (g_io_resp_bits_stage1_entry_5_perm_g !== i_io_resp_bits_stage1_entry_5_perm_g)) begin errors++;
      if(errors<=80) $display("vec %0d io_resp_bits_stage1_entry_5_perm_g g=%b i=%b",t,g_io_resp_bits_stage1_entry_5_perm_g,i_io_resp_bits_stage1_entry_5_perm_g); end
    if (!$isunknown(g_io_resp_bits_stage1_entry_5_perm_u) && !$isunknown(i_io_resp_bits_stage1_entry_5_perm_u) && (g_io_resp_bits_stage1_entry_5_perm_u !== i_io_resp_bits_stage1_entry_5_perm_u)) begin errors++;
      if(errors<=80) $display("vec %0d io_resp_bits_stage1_entry_5_perm_u g=%b i=%b",t,g_io_resp_bits_stage1_entry_5_perm_u,i_io_resp_bits_stage1_entry_5_perm_u); end
    if (!$isunknown(g_io_resp_bits_stage1_entry_5_perm_x) && !$isunknown(i_io_resp_bits_stage1_entry_5_perm_x) && (g_io_resp_bits_stage1_entry_5_perm_x !== i_io_resp_bits_stage1_entry_5_perm_x)) begin errors++;
      if(errors<=80) $display("vec %0d io_resp_bits_stage1_entry_5_perm_x g=%b i=%b",t,g_io_resp_bits_stage1_entry_5_perm_x,i_io_resp_bits_stage1_entry_5_perm_x); end
    if (!$isunknown(g_io_resp_bits_stage1_entry_5_perm_w) && !$isunknown(i_io_resp_bits_stage1_entry_5_perm_w) && (g_io_resp_bits_stage1_entry_5_perm_w !== i_io_resp_bits_stage1_entry_5_perm_w)) begin errors++;
      if(errors<=80) $display("vec %0d io_resp_bits_stage1_entry_5_perm_w g=%b i=%b",t,g_io_resp_bits_stage1_entry_5_perm_w,i_io_resp_bits_stage1_entry_5_perm_w); end
    if (!$isunknown(g_io_resp_bits_stage1_entry_5_perm_r) && !$isunknown(i_io_resp_bits_stage1_entry_5_perm_r) && (g_io_resp_bits_stage1_entry_5_perm_r !== i_io_resp_bits_stage1_entry_5_perm_r)) begin errors++;
      if(errors<=80) $display("vec %0d io_resp_bits_stage1_entry_5_perm_r g=%b i=%b",t,g_io_resp_bits_stage1_entry_5_perm_r,i_io_resp_bits_stage1_entry_5_perm_r); end
    if (!$isunknown(g_io_resp_bits_stage1_entry_5_level) && !$isunknown(i_io_resp_bits_stage1_entry_5_level) && (g_io_resp_bits_stage1_entry_5_level !== i_io_resp_bits_stage1_entry_5_level)) begin errors++;
      if(errors<=80) $display("vec %0d io_resp_bits_stage1_entry_5_level g=%h i=%h",t,g_io_resp_bits_stage1_entry_5_level,i_io_resp_bits_stage1_entry_5_level); end
    if (!$isunknown(g_io_resp_bits_stage1_entry_5_v) && !$isunknown(i_io_resp_bits_stage1_entry_5_v) && (g_io_resp_bits_stage1_entry_5_v !== i_io_resp_bits_stage1_entry_5_v)) begin errors++;
      if(errors<=80) $display("vec %0d io_resp_bits_stage1_entry_5_v g=%b i=%b",t,g_io_resp_bits_stage1_entry_5_v,i_io_resp_bits_stage1_entry_5_v); end
    if (!$isunknown(g_io_resp_bits_stage1_entry_5_ppn) && !$isunknown(i_io_resp_bits_stage1_entry_5_ppn) && (g_io_resp_bits_stage1_entry_5_ppn !== i_io_resp_bits_stage1_entry_5_ppn)) begin errors++;
      if(errors<=80) $display("vec %0d io_resp_bits_stage1_entry_5_ppn g=%h i=%h",t,g_io_resp_bits_stage1_entry_5_ppn,i_io_resp_bits_stage1_entry_5_ppn); end
    if (!$isunknown(g_io_resp_bits_stage1_entry_5_ppn_low) && !$isunknown(i_io_resp_bits_stage1_entry_5_ppn_low) && (g_io_resp_bits_stage1_entry_5_ppn_low !== i_io_resp_bits_stage1_entry_5_ppn_low)) begin errors++;
      if(errors<=80) $display("vec %0d io_resp_bits_stage1_entry_5_ppn_low g=%h i=%h",t,g_io_resp_bits_stage1_entry_5_ppn_low,i_io_resp_bits_stage1_entry_5_ppn_low); end
    if (!$isunknown(g_io_resp_bits_stage1_entry_5_pf) && !$isunknown(i_io_resp_bits_stage1_entry_5_pf) && (g_io_resp_bits_stage1_entry_5_pf !== i_io_resp_bits_stage1_entry_5_pf)) begin errors++;
      if(errors<=80) $display("vec %0d io_resp_bits_stage1_entry_5_pf g=%b i=%b",t,g_io_resp_bits_stage1_entry_5_pf,i_io_resp_bits_stage1_entry_5_pf); end
    if (!$isunknown(g_io_resp_bits_stage1_entry_6_tag) && !$isunknown(i_io_resp_bits_stage1_entry_6_tag) && (g_io_resp_bits_stage1_entry_6_tag !== i_io_resp_bits_stage1_entry_6_tag)) begin errors++;
      if(errors<=80) $display("vec %0d io_resp_bits_stage1_entry_6_tag g=%h i=%h",t,g_io_resp_bits_stage1_entry_6_tag,i_io_resp_bits_stage1_entry_6_tag); end
    if (!$isunknown(g_io_resp_bits_stage1_entry_6_asid) && !$isunknown(i_io_resp_bits_stage1_entry_6_asid) && (g_io_resp_bits_stage1_entry_6_asid !== i_io_resp_bits_stage1_entry_6_asid)) begin errors++;
      if(errors<=80) $display("vec %0d io_resp_bits_stage1_entry_6_asid g=%h i=%h",t,g_io_resp_bits_stage1_entry_6_asid,i_io_resp_bits_stage1_entry_6_asid); end
    if (!$isunknown(g_io_resp_bits_stage1_entry_6_vmid) && !$isunknown(i_io_resp_bits_stage1_entry_6_vmid) && (g_io_resp_bits_stage1_entry_6_vmid !== i_io_resp_bits_stage1_entry_6_vmid)) begin errors++;
      if(errors<=80) $display("vec %0d io_resp_bits_stage1_entry_6_vmid g=%h i=%h",t,g_io_resp_bits_stage1_entry_6_vmid,i_io_resp_bits_stage1_entry_6_vmid); end
    if (!$isunknown(g_io_resp_bits_stage1_entry_6_n) && !$isunknown(i_io_resp_bits_stage1_entry_6_n) && (g_io_resp_bits_stage1_entry_6_n !== i_io_resp_bits_stage1_entry_6_n)) begin errors++;
      if(errors<=80) $display("vec %0d io_resp_bits_stage1_entry_6_n g=%b i=%b",t,g_io_resp_bits_stage1_entry_6_n,i_io_resp_bits_stage1_entry_6_n); end
    if (!$isunknown(g_io_resp_bits_stage1_entry_6_pbmt) && !$isunknown(i_io_resp_bits_stage1_entry_6_pbmt) && (g_io_resp_bits_stage1_entry_6_pbmt !== i_io_resp_bits_stage1_entry_6_pbmt)) begin errors++;
      if(errors<=80) $display("vec %0d io_resp_bits_stage1_entry_6_pbmt g=%h i=%h",t,g_io_resp_bits_stage1_entry_6_pbmt,i_io_resp_bits_stage1_entry_6_pbmt); end
    if (!$isunknown(g_io_resp_bits_stage1_entry_6_perm_d) && !$isunknown(i_io_resp_bits_stage1_entry_6_perm_d) && (g_io_resp_bits_stage1_entry_6_perm_d !== i_io_resp_bits_stage1_entry_6_perm_d)) begin errors++;
      if(errors<=80) $display("vec %0d io_resp_bits_stage1_entry_6_perm_d g=%b i=%b",t,g_io_resp_bits_stage1_entry_6_perm_d,i_io_resp_bits_stage1_entry_6_perm_d); end
    if (!$isunknown(g_io_resp_bits_stage1_entry_6_perm_a) && !$isunknown(i_io_resp_bits_stage1_entry_6_perm_a) && (g_io_resp_bits_stage1_entry_6_perm_a !== i_io_resp_bits_stage1_entry_6_perm_a)) begin errors++;
      if(errors<=80) $display("vec %0d io_resp_bits_stage1_entry_6_perm_a g=%b i=%b",t,g_io_resp_bits_stage1_entry_6_perm_a,i_io_resp_bits_stage1_entry_6_perm_a); end
    if (!$isunknown(g_io_resp_bits_stage1_entry_6_perm_g) && !$isunknown(i_io_resp_bits_stage1_entry_6_perm_g) && (g_io_resp_bits_stage1_entry_6_perm_g !== i_io_resp_bits_stage1_entry_6_perm_g)) begin errors++;
      if(errors<=80) $display("vec %0d io_resp_bits_stage1_entry_6_perm_g g=%b i=%b",t,g_io_resp_bits_stage1_entry_6_perm_g,i_io_resp_bits_stage1_entry_6_perm_g); end
    if (!$isunknown(g_io_resp_bits_stage1_entry_6_perm_u) && !$isunknown(i_io_resp_bits_stage1_entry_6_perm_u) && (g_io_resp_bits_stage1_entry_6_perm_u !== i_io_resp_bits_stage1_entry_6_perm_u)) begin errors++;
      if(errors<=80) $display("vec %0d io_resp_bits_stage1_entry_6_perm_u g=%b i=%b",t,g_io_resp_bits_stage1_entry_6_perm_u,i_io_resp_bits_stage1_entry_6_perm_u); end
    if (!$isunknown(g_io_resp_bits_stage1_entry_6_perm_x) && !$isunknown(i_io_resp_bits_stage1_entry_6_perm_x) && (g_io_resp_bits_stage1_entry_6_perm_x !== i_io_resp_bits_stage1_entry_6_perm_x)) begin errors++;
      if(errors<=80) $display("vec %0d io_resp_bits_stage1_entry_6_perm_x g=%b i=%b",t,g_io_resp_bits_stage1_entry_6_perm_x,i_io_resp_bits_stage1_entry_6_perm_x); end
    if (!$isunknown(g_io_resp_bits_stage1_entry_6_perm_w) && !$isunknown(i_io_resp_bits_stage1_entry_6_perm_w) && (g_io_resp_bits_stage1_entry_6_perm_w !== i_io_resp_bits_stage1_entry_6_perm_w)) begin errors++;
      if(errors<=80) $display("vec %0d io_resp_bits_stage1_entry_6_perm_w g=%b i=%b",t,g_io_resp_bits_stage1_entry_6_perm_w,i_io_resp_bits_stage1_entry_6_perm_w); end
    if (!$isunknown(g_io_resp_bits_stage1_entry_6_perm_r) && !$isunknown(i_io_resp_bits_stage1_entry_6_perm_r) && (g_io_resp_bits_stage1_entry_6_perm_r !== i_io_resp_bits_stage1_entry_6_perm_r)) begin errors++;
      if(errors<=80) $display("vec %0d io_resp_bits_stage1_entry_6_perm_r g=%b i=%b",t,g_io_resp_bits_stage1_entry_6_perm_r,i_io_resp_bits_stage1_entry_6_perm_r); end
    if (!$isunknown(g_io_resp_bits_stage1_entry_6_level) && !$isunknown(i_io_resp_bits_stage1_entry_6_level) && (g_io_resp_bits_stage1_entry_6_level !== i_io_resp_bits_stage1_entry_6_level)) begin errors++;
      if(errors<=80) $display("vec %0d io_resp_bits_stage1_entry_6_level g=%h i=%h",t,g_io_resp_bits_stage1_entry_6_level,i_io_resp_bits_stage1_entry_6_level); end
    if (!$isunknown(g_io_resp_bits_stage1_entry_6_v) && !$isunknown(i_io_resp_bits_stage1_entry_6_v) && (g_io_resp_bits_stage1_entry_6_v !== i_io_resp_bits_stage1_entry_6_v)) begin errors++;
      if(errors<=80) $display("vec %0d io_resp_bits_stage1_entry_6_v g=%b i=%b",t,g_io_resp_bits_stage1_entry_6_v,i_io_resp_bits_stage1_entry_6_v); end
    if (!$isunknown(g_io_resp_bits_stage1_entry_6_ppn) && !$isunknown(i_io_resp_bits_stage1_entry_6_ppn) && (g_io_resp_bits_stage1_entry_6_ppn !== i_io_resp_bits_stage1_entry_6_ppn)) begin errors++;
      if(errors<=80) $display("vec %0d io_resp_bits_stage1_entry_6_ppn g=%h i=%h",t,g_io_resp_bits_stage1_entry_6_ppn,i_io_resp_bits_stage1_entry_6_ppn); end
    if (!$isunknown(g_io_resp_bits_stage1_entry_6_ppn_low) && !$isunknown(i_io_resp_bits_stage1_entry_6_ppn_low) && (g_io_resp_bits_stage1_entry_6_ppn_low !== i_io_resp_bits_stage1_entry_6_ppn_low)) begin errors++;
      if(errors<=80) $display("vec %0d io_resp_bits_stage1_entry_6_ppn_low g=%h i=%h",t,g_io_resp_bits_stage1_entry_6_ppn_low,i_io_resp_bits_stage1_entry_6_ppn_low); end
    if (!$isunknown(g_io_resp_bits_stage1_entry_6_pf) && !$isunknown(i_io_resp_bits_stage1_entry_6_pf) && (g_io_resp_bits_stage1_entry_6_pf !== i_io_resp_bits_stage1_entry_6_pf)) begin errors++;
      if(errors<=80) $display("vec %0d io_resp_bits_stage1_entry_6_pf g=%b i=%b",t,g_io_resp_bits_stage1_entry_6_pf,i_io_resp_bits_stage1_entry_6_pf); end
    if (!$isunknown(g_io_resp_bits_stage1_entry_7_tag) && !$isunknown(i_io_resp_bits_stage1_entry_7_tag) && (g_io_resp_bits_stage1_entry_7_tag !== i_io_resp_bits_stage1_entry_7_tag)) begin errors++;
      if(errors<=80) $display("vec %0d io_resp_bits_stage1_entry_7_tag g=%h i=%h",t,g_io_resp_bits_stage1_entry_7_tag,i_io_resp_bits_stage1_entry_7_tag); end
    if (!$isunknown(g_io_resp_bits_stage1_entry_7_asid) && !$isunknown(i_io_resp_bits_stage1_entry_7_asid) && (g_io_resp_bits_stage1_entry_7_asid !== i_io_resp_bits_stage1_entry_7_asid)) begin errors++;
      if(errors<=80) $display("vec %0d io_resp_bits_stage1_entry_7_asid g=%h i=%h",t,g_io_resp_bits_stage1_entry_7_asid,i_io_resp_bits_stage1_entry_7_asid); end
    if (!$isunknown(g_io_resp_bits_stage1_entry_7_vmid) && !$isunknown(i_io_resp_bits_stage1_entry_7_vmid) && (g_io_resp_bits_stage1_entry_7_vmid !== i_io_resp_bits_stage1_entry_7_vmid)) begin errors++;
      if(errors<=80) $display("vec %0d io_resp_bits_stage1_entry_7_vmid g=%h i=%h",t,g_io_resp_bits_stage1_entry_7_vmid,i_io_resp_bits_stage1_entry_7_vmid); end
    if (!$isunknown(g_io_resp_bits_stage1_entry_7_n) && !$isunknown(i_io_resp_bits_stage1_entry_7_n) && (g_io_resp_bits_stage1_entry_7_n !== i_io_resp_bits_stage1_entry_7_n)) begin errors++;
      if(errors<=80) $display("vec %0d io_resp_bits_stage1_entry_7_n g=%b i=%b",t,g_io_resp_bits_stage1_entry_7_n,i_io_resp_bits_stage1_entry_7_n); end
    if (!$isunknown(g_io_resp_bits_stage1_entry_7_pbmt) && !$isunknown(i_io_resp_bits_stage1_entry_7_pbmt) && (g_io_resp_bits_stage1_entry_7_pbmt !== i_io_resp_bits_stage1_entry_7_pbmt)) begin errors++;
      if(errors<=80) $display("vec %0d io_resp_bits_stage1_entry_7_pbmt g=%h i=%h",t,g_io_resp_bits_stage1_entry_7_pbmt,i_io_resp_bits_stage1_entry_7_pbmt); end
    if (!$isunknown(g_io_resp_bits_stage1_entry_7_perm_d) && !$isunknown(i_io_resp_bits_stage1_entry_7_perm_d) && (g_io_resp_bits_stage1_entry_7_perm_d !== i_io_resp_bits_stage1_entry_7_perm_d)) begin errors++;
      if(errors<=80) $display("vec %0d io_resp_bits_stage1_entry_7_perm_d g=%b i=%b",t,g_io_resp_bits_stage1_entry_7_perm_d,i_io_resp_bits_stage1_entry_7_perm_d); end
    if (!$isunknown(g_io_resp_bits_stage1_entry_7_perm_a) && !$isunknown(i_io_resp_bits_stage1_entry_7_perm_a) && (g_io_resp_bits_stage1_entry_7_perm_a !== i_io_resp_bits_stage1_entry_7_perm_a)) begin errors++;
      if(errors<=80) $display("vec %0d io_resp_bits_stage1_entry_7_perm_a g=%b i=%b",t,g_io_resp_bits_stage1_entry_7_perm_a,i_io_resp_bits_stage1_entry_7_perm_a); end
    if (!$isunknown(g_io_resp_bits_stage1_entry_7_perm_g) && !$isunknown(i_io_resp_bits_stage1_entry_7_perm_g) && (g_io_resp_bits_stage1_entry_7_perm_g !== i_io_resp_bits_stage1_entry_7_perm_g)) begin errors++;
      if(errors<=80) $display("vec %0d io_resp_bits_stage1_entry_7_perm_g g=%b i=%b",t,g_io_resp_bits_stage1_entry_7_perm_g,i_io_resp_bits_stage1_entry_7_perm_g); end
    if (!$isunknown(g_io_resp_bits_stage1_entry_7_perm_u) && !$isunknown(i_io_resp_bits_stage1_entry_7_perm_u) && (g_io_resp_bits_stage1_entry_7_perm_u !== i_io_resp_bits_stage1_entry_7_perm_u)) begin errors++;
      if(errors<=80) $display("vec %0d io_resp_bits_stage1_entry_7_perm_u g=%b i=%b",t,g_io_resp_bits_stage1_entry_7_perm_u,i_io_resp_bits_stage1_entry_7_perm_u); end
    if (!$isunknown(g_io_resp_bits_stage1_entry_7_perm_x) && !$isunknown(i_io_resp_bits_stage1_entry_7_perm_x) && (g_io_resp_bits_stage1_entry_7_perm_x !== i_io_resp_bits_stage1_entry_7_perm_x)) begin errors++;
      if(errors<=80) $display("vec %0d io_resp_bits_stage1_entry_7_perm_x g=%b i=%b",t,g_io_resp_bits_stage1_entry_7_perm_x,i_io_resp_bits_stage1_entry_7_perm_x); end
    if (!$isunknown(g_io_resp_bits_stage1_entry_7_perm_w) && !$isunknown(i_io_resp_bits_stage1_entry_7_perm_w) && (g_io_resp_bits_stage1_entry_7_perm_w !== i_io_resp_bits_stage1_entry_7_perm_w)) begin errors++;
      if(errors<=80) $display("vec %0d io_resp_bits_stage1_entry_7_perm_w g=%b i=%b",t,g_io_resp_bits_stage1_entry_7_perm_w,i_io_resp_bits_stage1_entry_7_perm_w); end
    if (!$isunknown(g_io_resp_bits_stage1_entry_7_perm_r) && !$isunknown(i_io_resp_bits_stage1_entry_7_perm_r) && (g_io_resp_bits_stage1_entry_7_perm_r !== i_io_resp_bits_stage1_entry_7_perm_r)) begin errors++;
      if(errors<=80) $display("vec %0d io_resp_bits_stage1_entry_7_perm_r g=%b i=%b",t,g_io_resp_bits_stage1_entry_7_perm_r,i_io_resp_bits_stage1_entry_7_perm_r); end
    if (!$isunknown(g_io_resp_bits_stage1_entry_7_level) && !$isunknown(i_io_resp_bits_stage1_entry_7_level) && (g_io_resp_bits_stage1_entry_7_level !== i_io_resp_bits_stage1_entry_7_level)) begin errors++;
      if(errors<=80) $display("vec %0d io_resp_bits_stage1_entry_7_level g=%h i=%h",t,g_io_resp_bits_stage1_entry_7_level,i_io_resp_bits_stage1_entry_7_level); end
    if (!$isunknown(g_io_resp_bits_stage1_entry_7_v) && !$isunknown(i_io_resp_bits_stage1_entry_7_v) && (g_io_resp_bits_stage1_entry_7_v !== i_io_resp_bits_stage1_entry_7_v)) begin errors++;
      if(errors<=80) $display("vec %0d io_resp_bits_stage1_entry_7_v g=%b i=%b",t,g_io_resp_bits_stage1_entry_7_v,i_io_resp_bits_stage1_entry_7_v); end
    if (!$isunknown(g_io_resp_bits_stage1_entry_7_ppn) && !$isunknown(i_io_resp_bits_stage1_entry_7_ppn) && (g_io_resp_bits_stage1_entry_7_ppn !== i_io_resp_bits_stage1_entry_7_ppn)) begin errors++;
      if(errors<=80) $display("vec %0d io_resp_bits_stage1_entry_7_ppn g=%h i=%h",t,g_io_resp_bits_stage1_entry_7_ppn,i_io_resp_bits_stage1_entry_7_ppn); end
    if (!$isunknown(g_io_resp_bits_stage1_entry_7_ppn_low) && !$isunknown(i_io_resp_bits_stage1_entry_7_ppn_low) && (g_io_resp_bits_stage1_entry_7_ppn_low !== i_io_resp_bits_stage1_entry_7_ppn_low)) begin errors++;
      if(errors<=80) $display("vec %0d io_resp_bits_stage1_entry_7_ppn_low g=%h i=%h",t,g_io_resp_bits_stage1_entry_7_ppn_low,i_io_resp_bits_stage1_entry_7_ppn_low); end
    if (!$isunknown(g_io_resp_bits_stage1_entry_7_pf) && !$isunknown(i_io_resp_bits_stage1_entry_7_pf) && (g_io_resp_bits_stage1_entry_7_pf !== i_io_resp_bits_stage1_entry_7_pf)) begin errors++;
      if(errors<=80) $display("vec %0d io_resp_bits_stage1_entry_7_pf g=%b i=%b",t,g_io_resp_bits_stage1_entry_7_pf,i_io_resp_bits_stage1_entry_7_pf); end
    if (!$isunknown(g_io_resp_bits_stage1_pteidx_0) && !$isunknown(i_io_resp_bits_stage1_pteidx_0) && (g_io_resp_bits_stage1_pteidx_0 !== i_io_resp_bits_stage1_pteidx_0)) begin errors++;
      if(errors<=80) $display("vec %0d io_resp_bits_stage1_pteidx_0 g=%b i=%b",t,g_io_resp_bits_stage1_pteidx_0,i_io_resp_bits_stage1_pteidx_0); end
    if (!$isunknown(g_io_resp_bits_stage1_pteidx_1) && !$isunknown(i_io_resp_bits_stage1_pteidx_1) && (g_io_resp_bits_stage1_pteidx_1 !== i_io_resp_bits_stage1_pteidx_1)) begin errors++;
      if(errors<=80) $display("vec %0d io_resp_bits_stage1_pteidx_1 g=%b i=%b",t,g_io_resp_bits_stage1_pteidx_1,i_io_resp_bits_stage1_pteidx_1); end
    if (!$isunknown(g_io_resp_bits_stage1_pteidx_2) && !$isunknown(i_io_resp_bits_stage1_pteidx_2) && (g_io_resp_bits_stage1_pteidx_2 !== i_io_resp_bits_stage1_pteidx_2)) begin errors++;
      if(errors<=80) $display("vec %0d io_resp_bits_stage1_pteidx_2 g=%b i=%b",t,g_io_resp_bits_stage1_pteidx_2,i_io_resp_bits_stage1_pteidx_2); end
    if (!$isunknown(g_io_resp_bits_stage1_pteidx_3) && !$isunknown(i_io_resp_bits_stage1_pteidx_3) && (g_io_resp_bits_stage1_pteidx_3 !== i_io_resp_bits_stage1_pteidx_3)) begin errors++;
      if(errors<=80) $display("vec %0d io_resp_bits_stage1_pteidx_3 g=%b i=%b",t,g_io_resp_bits_stage1_pteidx_3,i_io_resp_bits_stage1_pteidx_3); end
    if (!$isunknown(g_io_resp_bits_stage1_pteidx_4) && !$isunknown(i_io_resp_bits_stage1_pteidx_4) && (g_io_resp_bits_stage1_pteidx_4 !== i_io_resp_bits_stage1_pteidx_4)) begin errors++;
      if(errors<=80) $display("vec %0d io_resp_bits_stage1_pteidx_4 g=%b i=%b",t,g_io_resp_bits_stage1_pteidx_4,i_io_resp_bits_stage1_pteidx_4); end
    if (!$isunknown(g_io_resp_bits_stage1_pteidx_5) && !$isunknown(i_io_resp_bits_stage1_pteidx_5) && (g_io_resp_bits_stage1_pteidx_5 !== i_io_resp_bits_stage1_pteidx_5)) begin errors++;
      if(errors<=80) $display("vec %0d io_resp_bits_stage1_pteidx_5 g=%b i=%b",t,g_io_resp_bits_stage1_pteidx_5,i_io_resp_bits_stage1_pteidx_5); end
    if (!$isunknown(g_io_resp_bits_stage1_pteidx_6) && !$isunknown(i_io_resp_bits_stage1_pteidx_6) && (g_io_resp_bits_stage1_pteidx_6 !== i_io_resp_bits_stage1_pteidx_6)) begin errors++;
      if(errors<=80) $display("vec %0d io_resp_bits_stage1_pteidx_6 g=%b i=%b",t,g_io_resp_bits_stage1_pteidx_6,i_io_resp_bits_stage1_pteidx_6); end
    if (!$isunknown(g_io_resp_bits_stage1_pteidx_7) && !$isunknown(i_io_resp_bits_stage1_pteidx_7) && (g_io_resp_bits_stage1_pteidx_7 !== i_io_resp_bits_stage1_pteidx_7)) begin errors++;
      if(errors<=80) $display("vec %0d io_resp_bits_stage1_pteidx_7 g=%b i=%b",t,g_io_resp_bits_stage1_pteidx_7,i_io_resp_bits_stage1_pteidx_7); end
    if (!$isunknown(g_io_resp_bits_stage1_not_super) && !$isunknown(i_io_resp_bits_stage1_not_super) && (g_io_resp_bits_stage1_not_super !== i_io_resp_bits_stage1_not_super)) begin errors++;
      if(errors<=80) $display("vec %0d io_resp_bits_stage1_not_super g=%b i=%b",t,g_io_resp_bits_stage1_not_super,i_io_resp_bits_stage1_not_super); end
    if (!$isunknown(g_io_resp_bits_isHptwReq) && !$isunknown(i_io_resp_bits_isHptwReq) && (g_io_resp_bits_isHptwReq !== i_io_resp_bits_isHptwReq)) begin errors++;
      if(errors<=80) $display("vec %0d io_resp_bits_isHptwReq g=%b i=%b",t,g_io_resp_bits_isHptwReq,i_io_resp_bits_isHptwReq); end
    if (!$isunknown(g_io_resp_bits_toHptw_l3Hit) && !$isunknown(i_io_resp_bits_toHptw_l3Hit) && (g_io_resp_bits_toHptw_l3Hit !== i_io_resp_bits_toHptw_l3Hit)) begin errors++;
      if(errors<=80) $display("vec %0d io_resp_bits_toHptw_l3Hit g=%b i=%b",t,g_io_resp_bits_toHptw_l3Hit,i_io_resp_bits_toHptw_l3Hit); end
    if (!$isunknown(g_io_resp_bits_toHptw_l2Hit) && !$isunknown(i_io_resp_bits_toHptw_l2Hit) && (g_io_resp_bits_toHptw_l2Hit !== i_io_resp_bits_toHptw_l2Hit)) begin errors++;
      if(errors<=80) $display("vec %0d io_resp_bits_toHptw_l2Hit g=%b i=%b",t,g_io_resp_bits_toHptw_l2Hit,i_io_resp_bits_toHptw_l2Hit); end
    if (!$isunknown(g_io_resp_bits_toHptw_l1Hit) && !$isunknown(i_io_resp_bits_toHptw_l1Hit) && (g_io_resp_bits_toHptw_l1Hit !== i_io_resp_bits_toHptw_l1Hit)) begin errors++;
      if(errors<=80) $display("vec %0d io_resp_bits_toHptw_l1Hit g=%b i=%b",t,g_io_resp_bits_toHptw_l1Hit,i_io_resp_bits_toHptw_l1Hit); end
    if (!$isunknown(g_io_resp_bits_toHptw_ppn) && !$isunknown(i_io_resp_bits_toHptw_ppn) && (g_io_resp_bits_toHptw_ppn !== i_io_resp_bits_toHptw_ppn)) begin errors++;
      if(errors<=80) $display("vec %0d io_resp_bits_toHptw_ppn g=%h i=%h",t,g_io_resp_bits_toHptw_ppn,i_io_resp_bits_toHptw_ppn); end
    if (!$isunknown(g_io_resp_bits_toHptw_id) && !$isunknown(i_io_resp_bits_toHptw_id) && (g_io_resp_bits_toHptw_id !== i_io_resp_bits_toHptw_id)) begin errors++;
      if(errors<=80) $display("vec %0d io_resp_bits_toHptw_id g=%h i=%h",t,g_io_resp_bits_toHptw_id,i_io_resp_bits_toHptw_id); end
    if (!$isunknown(g_io_resp_bits_toHptw_resp_entry_tag) && !$isunknown(i_io_resp_bits_toHptw_resp_entry_tag) && (g_io_resp_bits_toHptw_resp_entry_tag !== i_io_resp_bits_toHptw_resp_entry_tag)) begin errors++;
      if(errors<=80) $display("vec %0d io_resp_bits_toHptw_resp_entry_tag g=%h i=%h",t,g_io_resp_bits_toHptw_resp_entry_tag,i_io_resp_bits_toHptw_resp_entry_tag); end
    if (!$isunknown(g_io_resp_bits_toHptw_resp_entry_vmid) && !$isunknown(i_io_resp_bits_toHptw_resp_entry_vmid) && (g_io_resp_bits_toHptw_resp_entry_vmid !== i_io_resp_bits_toHptw_resp_entry_vmid)) begin errors++;
      if(errors<=80) $display("vec %0d io_resp_bits_toHptw_resp_entry_vmid g=%h i=%h",t,g_io_resp_bits_toHptw_resp_entry_vmid,i_io_resp_bits_toHptw_resp_entry_vmid); end
    if (!$isunknown(g_io_resp_bits_toHptw_resp_entry_n) && !$isunknown(i_io_resp_bits_toHptw_resp_entry_n) && (g_io_resp_bits_toHptw_resp_entry_n !== i_io_resp_bits_toHptw_resp_entry_n)) begin errors++;
      if(errors<=80) $display("vec %0d io_resp_bits_toHptw_resp_entry_n g=%b i=%b",t,g_io_resp_bits_toHptw_resp_entry_n,i_io_resp_bits_toHptw_resp_entry_n); end
    if (!$isunknown(g_io_resp_bits_toHptw_resp_entry_pbmt) && !$isunknown(i_io_resp_bits_toHptw_resp_entry_pbmt) && (g_io_resp_bits_toHptw_resp_entry_pbmt !== i_io_resp_bits_toHptw_resp_entry_pbmt)) begin errors++;
      if(errors<=80) $display("vec %0d io_resp_bits_toHptw_resp_entry_pbmt g=%h i=%h",t,g_io_resp_bits_toHptw_resp_entry_pbmt,i_io_resp_bits_toHptw_resp_entry_pbmt); end
    if (!$isunknown(g_io_resp_bits_toHptw_resp_entry_ppn) && !$isunknown(i_io_resp_bits_toHptw_resp_entry_ppn) && (g_io_resp_bits_toHptw_resp_entry_ppn !== i_io_resp_bits_toHptw_resp_entry_ppn)) begin errors++;
      if(errors<=80) $display("vec %0d io_resp_bits_toHptw_resp_entry_ppn g=%h i=%h",t,g_io_resp_bits_toHptw_resp_entry_ppn,i_io_resp_bits_toHptw_resp_entry_ppn); end
    if (!$isunknown(g_io_resp_bits_toHptw_resp_entry_perm_d) && !$isunknown(i_io_resp_bits_toHptw_resp_entry_perm_d) && (g_io_resp_bits_toHptw_resp_entry_perm_d !== i_io_resp_bits_toHptw_resp_entry_perm_d)) begin errors++;
      if(errors<=80) $display("vec %0d io_resp_bits_toHptw_resp_entry_perm_d g=%b i=%b",t,g_io_resp_bits_toHptw_resp_entry_perm_d,i_io_resp_bits_toHptw_resp_entry_perm_d); end
    if (!$isunknown(g_io_resp_bits_toHptw_resp_entry_perm_a) && !$isunknown(i_io_resp_bits_toHptw_resp_entry_perm_a) && (g_io_resp_bits_toHptw_resp_entry_perm_a !== i_io_resp_bits_toHptw_resp_entry_perm_a)) begin errors++;
      if(errors<=80) $display("vec %0d io_resp_bits_toHptw_resp_entry_perm_a g=%b i=%b",t,g_io_resp_bits_toHptw_resp_entry_perm_a,i_io_resp_bits_toHptw_resp_entry_perm_a); end
    if (!$isunknown(g_io_resp_bits_toHptw_resp_entry_perm_g) && !$isunknown(i_io_resp_bits_toHptw_resp_entry_perm_g) && (g_io_resp_bits_toHptw_resp_entry_perm_g !== i_io_resp_bits_toHptw_resp_entry_perm_g)) begin errors++;
      if(errors<=80) $display("vec %0d io_resp_bits_toHptw_resp_entry_perm_g g=%b i=%b",t,g_io_resp_bits_toHptw_resp_entry_perm_g,i_io_resp_bits_toHptw_resp_entry_perm_g); end
    if (!$isunknown(g_io_resp_bits_toHptw_resp_entry_perm_u) && !$isunknown(i_io_resp_bits_toHptw_resp_entry_perm_u) && (g_io_resp_bits_toHptw_resp_entry_perm_u !== i_io_resp_bits_toHptw_resp_entry_perm_u)) begin errors++;
      if(errors<=80) $display("vec %0d io_resp_bits_toHptw_resp_entry_perm_u g=%b i=%b",t,g_io_resp_bits_toHptw_resp_entry_perm_u,i_io_resp_bits_toHptw_resp_entry_perm_u); end
    if (!$isunknown(g_io_resp_bits_toHptw_resp_entry_perm_x) && !$isunknown(i_io_resp_bits_toHptw_resp_entry_perm_x) && (g_io_resp_bits_toHptw_resp_entry_perm_x !== i_io_resp_bits_toHptw_resp_entry_perm_x)) begin errors++;
      if(errors<=80) $display("vec %0d io_resp_bits_toHptw_resp_entry_perm_x g=%b i=%b",t,g_io_resp_bits_toHptw_resp_entry_perm_x,i_io_resp_bits_toHptw_resp_entry_perm_x); end
    if (!$isunknown(g_io_resp_bits_toHptw_resp_entry_perm_w) && !$isunknown(i_io_resp_bits_toHptw_resp_entry_perm_w) && (g_io_resp_bits_toHptw_resp_entry_perm_w !== i_io_resp_bits_toHptw_resp_entry_perm_w)) begin errors++;
      if(errors<=80) $display("vec %0d io_resp_bits_toHptw_resp_entry_perm_w g=%b i=%b",t,g_io_resp_bits_toHptw_resp_entry_perm_w,i_io_resp_bits_toHptw_resp_entry_perm_w); end
    if (!$isunknown(g_io_resp_bits_toHptw_resp_entry_perm_r) && !$isunknown(i_io_resp_bits_toHptw_resp_entry_perm_r) && (g_io_resp_bits_toHptw_resp_entry_perm_r !== i_io_resp_bits_toHptw_resp_entry_perm_r)) begin errors++;
      if(errors<=80) $display("vec %0d io_resp_bits_toHptw_resp_entry_perm_r g=%b i=%b",t,g_io_resp_bits_toHptw_resp_entry_perm_r,i_io_resp_bits_toHptw_resp_entry_perm_r); end
    if (!$isunknown(g_io_resp_bits_toHptw_resp_entry_level) && !$isunknown(i_io_resp_bits_toHptw_resp_entry_level) && (g_io_resp_bits_toHptw_resp_entry_level !== i_io_resp_bits_toHptw_resp_entry_level)) begin errors++;
      if(errors<=80) $display("vec %0d io_resp_bits_toHptw_resp_entry_level g=%h i=%h",t,g_io_resp_bits_toHptw_resp_entry_level,i_io_resp_bits_toHptw_resp_entry_level); end
    if (!$isunknown(g_io_resp_bits_toHptw_resp_gpf) && !$isunknown(i_io_resp_bits_toHptw_resp_gpf) && (g_io_resp_bits_toHptw_resp_gpf !== i_io_resp_bits_toHptw_resp_gpf)) begin errors++;
      if(errors<=80) $display("vec %0d io_resp_bits_toHptw_resp_gpf g=%b i=%b",t,g_io_resp_bits_toHptw_resp_gpf,i_io_resp_bits_toHptw_resp_gpf); end
    if (!$isunknown(g_io_resp_bits_toHptw_bypassed) && !$isunknown(i_io_resp_bits_toHptw_bypassed) && (g_io_resp_bits_toHptw_bypassed !== i_io_resp_bits_toHptw_bypassed)) begin errors++;
      if(errors<=80) $display("vec %0d io_resp_bits_toHptw_bypassed g=%b i=%b",t,g_io_resp_bits_toHptw_bypassed,i_io_resp_bits_toHptw_bypassed); end
    if (!$isunknown(g_io_perf_0_value) && !$isunknown(i_io_perf_0_value) && (g_io_perf_0_value !== i_io_perf_0_value)) begin errors++;
      if(errors<=80) $display("vec %0d io_perf_0_value g=%h i=%h",t,g_io_perf_0_value,i_io_perf_0_value); end
    if (!$isunknown(g_io_perf_1_value) && !$isunknown(i_io_perf_1_value) && (g_io_perf_1_value !== i_io_perf_1_value)) begin errors++;
      if(errors<=80) $display("vec %0d io_perf_1_value g=%h i=%h",t,g_io_perf_1_value,i_io_perf_1_value); end
    if (!$isunknown(g_io_perf_2_value) && !$isunknown(i_io_perf_2_value) && (g_io_perf_2_value !== i_io_perf_2_value)) begin errors++;
      if(errors<=80) $display("vec %0d io_perf_2_value g=%h i=%h",t,g_io_perf_2_value,i_io_perf_2_value); end
    if (!$isunknown(g_io_perf_3_value) && !$isunknown(i_io_perf_3_value) && (g_io_perf_3_value !== i_io_perf_3_value)) begin errors++;
      if(errors<=80) $display("vec %0d io_perf_3_value g=%h i=%h",t,g_io_perf_3_value,i_io_perf_3_value); end
    if (!$isunknown(g_io_perf_4_value) && !$isunknown(i_io_perf_4_value) && (g_io_perf_4_value !== i_io_perf_4_value)) begin errors++;
      if(errors<=80) $display("vec %0d io_perf_4_value g=%h i=%h",t,g_io_perf_4_value,i_io_perf_4_value); end
    if (!$isunknown(g_io_perf_5_value) && !$isunknown(i_io_perf_5_value) && (g_io_perf_5_value !== i_io_perf_5_value)) begin errors++;
      if(errors<=80) $display("vec %0d io_perf_5_value g=%h i=%h",t,g_io_perf_5_value,i_io_perf_5_value); end
    if (!$isunknown(g_io_perf_6_value) && !$isunknown(i_io_perf_6_value) && (g_io_perf_6_value !== i_io_perf_6_value)) begin errors++;
      if(errors<=80) $display("vec %0d io_perf_6_value g=%h i=%h",t,g_io_perf_6_value,i_io_perf_6_value); end
    if (!$isunknown(g_io_perf_7_value) && !$isunknown(i_io_perf_7_value) && (g_io_perf_7_value !== i_io_perf_7_value)) begin errors++;
      if(errors<=80) $display("vec %0d io_perf_7_value g=%h i=%h",t,g_io_perf_7_value,i_io_perf_7_value); end
  endtask

  task automatic drive_random();
    io_csr_mPBMTE = ($urandom_range(0,3)==0);
    io_csr_hPBMTE = ($urandom_range(0,3)==0);
    io_req_valid = ($urandom_range(0,3)==0);
    io_req_bits_req_info_vpn = {$urandom,$urandom};
    io_req_bits_req_info_s2xlate = 2'($urandom);
    io_req_bits_req_info_source = 2'($urandom);
    io_req_bits_isFirst = ($urandom_range(0,3)==0);
    io_req_bits_isHptwReq = ($urandom_range(0,3)==0);
    io_req_bits_hptwId = 3'($urandom);
    io_resp_ready = $urandom_range(0,1);
    io_refill_valid = ($urandom_range(0,3)==0);
    io_refill_bits_ptes = {$urandom,$urandom,$urandom,$urandom,$urandom,$urandom,$urandom,$urandom,$urandom,$urandom,$urandom,$urandom,$urandom,$urandom,$urandom,$urandom};
    io_refill_bits_levelOH_sp = ($urandom_range(0,3)==0);
    io_refill_bits_levelOH_l0 = ($urandom_range(0,3)==0);
    io_refill_bits_levelOH_l1 = ($urandom_range(0,3)==0);
    io_refill_bits_levelOH_l2 = ($urandom_range(0,3)==0);
    io_refill_bits_levelOH_l3 = ($urandom_range(0,3)==0);
    io_refill_bits_req_info_dup_0_vpn = {$urandom,$urandom};
    io_refill_bits_req_info_dup_0_s2xlate = 2'($urandom);
    io_refill_bits_req_info_dup_0_source = 2'($urandom);
    io_refill_bits_req_info_dup_1_vpn = {$urandom,$urandom};
    io_refill_bits_req_info_dup_1_s2xlate = 2'($urandom);
    io_refill_bits_req_info_dup_1_source = 2'($urandom);
    io_refill_bits_req_info_dup_2_vpn = {$urandom,$urandom};
    io_refill_bits_req_info_dup_2_s2xlate = 2'($urandom);
    io_refill_bits_req_info_dup_2_source = 2'($urandom);
    io_refill_bits_level_dup_0 = 2'($urandom);
    io_refill_bits_level_dup_2 = 2'($urandom);
    io_refill_bits_sel_pte_dup_0 = {$urandom,$urandom};
    io_refill_bits_sel_pte_dup_2 = {$urandom,$urandom};
    io_sfence_dup_0_valid = ($urandom_range(0,3)==0);
    io_sfence_dup_0_bits_rs1 = ($urandom_range(0,3)==0);
    io_sfence_dup_0_bits_rs2 = ($urandom_range(0,3)==0);
    io_sfence_dup_0_bits_addr = {$urandom,$urandom};
    io_sfence_dup_0_bits_id = 16'($urandom);
    io_sfence_dup_0_bits_hv = ($urandom_range(0,3)==0);
    io_sfence_dup_0_bits_hg = ($urandom_range(0,3)==0);
    io_sfence_dup_1_valid = ($urandom_range(0,3)==0);
    io_sfence_dup_1_bits_id = 16'($urandom);
    io_sfence_dup_2_valid = ($urandom_range(0,3)==0);
    io_sfence_dup_2_bits_rs1 = ($urandom_range(0,3)==0);
    io_sfence_dup_2_bits_rs2 = ($urandom_range(0,3)==0);
    io_sfence_dup_2_bits_id = 16'($urandom);
    io_csr_dup_0_satp_asid = 16'($urandom);
    io_csr_dup_0_satp_changed = ($urandom_range(0,3)==0);
    io_csr_dup_0_vsatp_asid = 16'($urandom);
    io_csr_dup_0_vsatp_changed = ($urandom_range(0,3)==0);
    io_csr_dup_0_hgatp_mode = 4'($urandom);
    io_csr_dup_0_hgatp_vmid = 16'($urandom);
    io_csr_dup_0_hgatp_changed = ($urandom_range(0,3)==0);
    io_csr_dup_0_priv_virt = ($urandom_range(0,3)==0);
    io_csr_dup_1_satp_asid = 16'($urandom);
    io_csr_dup_1_satp_changed = ($urandom_range(0,3)==0);
    io_csr_dup_1_vsatp_asid = 16'($urandom);
    io_csr_dup_1_vsatp_changed = ($urandom_range(0,3)==0);
    io_csr_dup_1_hgatp_mode = 4'($urandom);
    io_csr_dup_1_hgatp_vmid = 16'($urandom);
    io_csr_dup_1_hgatp_changed = ($urandom_range(0,3)==0);
    io_csr_dup_1_priv_virt = ($urandom_range(0,3)==0);
    io_csr_dup_2_satp_asid = 16'($urandom);
    io_csr_dup_2_satp_changed = ($urandom_range(0,3)==0);
    io_csr_dup_2_vsatp_asid = 16'($urandom);
    io_csr_dup_2_vsatp_changed = ($urandom_range(0,3)==0);
    io_csr_dup_2_hgatp_mode = 4'($urandom);
    io_csr_dup_2_hgatp_vmid = 16'($urandom);
    io_csr_dup_2_hgatp_changed = ($urandom_range(0,3)==0);
    io_csr_dup_2_priv_virt = ($urandom_range(0,3)==0);
    boreChildrenBd_bore_array = 6'($urandom);
    boreChildrenBd_bore_all = $urandom_range(0,1);
    boreChildrenBd_bore_req = $urandom_range(0,1);
    boreChildrenBd_bore_writeen = $urandom_range(0,1);
    boreChildrenBd_bore_be = 2'($urandom);
    boreChildrenBd_bore_addr = 4'($urandom);
    boreChildrenBd_bore_indata = {$urandom,$urandom,$urandom,$urandom,$urandom,$urandom,$urandom};
    boreChildrenBd_bore_readen = $urandom_range(0,1);
    boreChildrenBd_bore_addr_rd = 4'($urandom);
    boreChildrenBd_bore_1_array = 6'($urandom);
    boreChildrenBd_bore_1_all = $urandom_range(0,1);
    boreChildrenBd_bore_1_req = $urandom_range(0,1);
    boreChildrenBd_bore_1_writeen = $urandom_range(0,1);
    boreChildrenBd_bore_1_be = 2'($urandom);
    boreChildrenBd_bore_1_addr = 6'($urandom);
    boreChildrenBd_bore_1_indata = {$urandom,$urandom,$urandom,$urandom,$urandom,$urandom,$urandom,$urandom};
    boreChildrenBd_bore_1_readen = $urandom_range(0,1);
    boreChildrenBd_bore_1_addr_rd = 6'($urandom);
    sigFromSrams_bore_ram_hold = $urandom_range(0,1);
    sigFromSrams_bore_ram_bypass = $urandom_range(0,1);
    sigFromSrams_bore_ram_bp_clken = $urandom_range(0,1);
    sigFromSrams_bore_ram_aux_clk = $urandom_range(0,1);
    sigFromSrams_bore_ram_aux_ckbp = $urandom_range(0,1);
    sigFromSrams_bore_ram_mcp_hold = $urandom_range(0,1);
    sigFromSrams_bore_cgen = $urandom_range(0,1);
    sigFromSrams_bore_1_ram_hold = $urandom_range(0,1);
    sigFromSrams_bore_1_ram_bypass = $urandom_range(0,1);
    sigFromSrams_bore_1_ram_bp_clken = $urandom_range(0,1);
    sigFromSrams_bore_1_ram_aux_clk = $urandom_range(0,1);
    sigFromSrams_bore_1_ram_aux_ckbp = $urandom_range(0,1);
    sigFromSrams_bore_1_ram_mcp_hold = $urandom_range(0,1);
    sigFromSrams_bore_1_cgen = $urandom_range(0,1);
    sigFromSrams_bore_2_ram_hold = $urandom_range(0,1);
    sigFromSrams_bore_2_ram_bypass = $urandom_range(0,1);
    sigFromSrams_bore_2_ram_bp_clken = $urandom_range(0,1);
    sigFromSrams_bore_2_ram_aux_clk = $urandom_range(0,1);
    sigFromSrams_bore_2_ram_aux_ckbp = $urandom_range(0,1);
    sigFromSrams_bore_2_ram_mcp_hold = $urandom_range(0,1);
    sigFromSrams_bore_2_cgen = $urandom_range(0,1);
    sigFromSrams_bore_3_ram_hold = $urandom_range(0,1);
    sigFromSrams_bore_3_ram_bypass = $urandom_range(0,1);
    sigFromSrams_bore_3_ram_bp_clken = $urandom_range(0,1);
    sigFromSrams_bore_3_ram_aux_clk = $urandom_range(0,1);
    sigFromSrams_bore_3_ram_aux_ckbp = $urandom_range(0,1);
    sigFromSrams_bore_3_ram_mcp_hold = $urandom_range(0,1);
    sigFromSrams_bore_3_cgen = $urandom_range(0,1);
    sigFromSrams_bore_4_ram_hold = $urandom_range(0,1);
    sigFromSrams_bore_4_ram_bypass = $urandom_range(0,1);
    sigFromSrams_bore_4_ram_bp_clken = $urandom_range(0,1);
    sigFromSrams_bore_4_ram_aux_clk = $urandom_range(0,1);
    sigFromSrams_bore_4_ram_aux_ckbp = $urandom_range(0,1);
    sigFromSrams_bore_4_ram_mcp_hold = $urandom_range(0,1);
    sigFromSrams_bore_4_cgen = $urandom_range(0,1);
    sigFromSrams_bore_5_ram_hold = $urandom_range(0,1);
    sigFromSrams_bore_5_ram_bypass = $urandom_range(0,1);
    sigFromSrams_bore_5_ram_bp_clken = $urandom_range(0,1);
    sigFromSrams_bore_5_ram_aux_clk = $urandom_range(0,1);
    sigFromSrams_bore_5_ram_aux_ckbp = $urandom_range(0,1);
    sigFromSrams_bore_5_ram_mcp_hold = $urandom_range(0,1);
    sigFromSrams_bore_5_cgen = $urandom_range(0,1);
    sigFromSrams_bore_6_ram_hold = $urandom_range(0,1);
    sigFromSrams_bore_6_ram_bypass = $urandom_range(0,1);
    sigFromSrams_bore_6_ram_bp_clken = $urandom_range(0,1);
    sigFromSrams_bore_6_ram_aux_clk = $urandom_range(0,1);
    sigFromSrams_bore_6_ram_aux_ckbp = $urandom_range(0,1);
    sigFromSrams_bore_6_ram_mcp_hold = $urandom_range(0,1);
    sigFromSrams_bore_6_cgen = $urandom_range(0,1);
    sigFromSrams_bore_7_ram_hold = $urandom_range(0,1);
    sigFromSrams_bore_7_ram_bypass = $urandom_range(0,1);
    sigFromSrams_bore_7_ram_bp_clken = $urandom_range(0,1);
    sigFromSrams_bore_7_ram_aux_clk = $urandom_range(0,1);
    sigFromSrams_bore_7_ram_aux_ckbp = $urandom_range(0,1);
    sigFromSrams_bore_7_ram_mcp_hold = $urandom_range(0,1);
    sigFromSrams_bore_7_cgen = $urandom_range(0,1);
    sigFromSrams_bore_8_ram_hold = $urandom_range(0,1);
    sigFromSrams_bore_8_ram_bypass = $urandom_range(0,1);
    sigFromSrams_bore_8_ram_bp_clken = $urandom_range(0,1);
    sigFromSrams_bore_8_ram_aux_clk = $urandom_range(0,1);
    sigFromSrams_bore_8_ram_aux_ckbp = $urandom_range(0,1);
    sigFromSrams_bore_8_ram_mcp_hold = $urandom_range(0,1);
    sigFromSrams_bore_8_cgen = $urandom_range(0,1);
    sigFromSrams_bore_9_ram_hold = $urandom_range(0,1);
    sigFromSrams_bore_9_ram_bypass = $urandom_range(0,1);
    sigFromSrams_bore_9_ram_bp_clken = $urandom_range(0,1);
    sigFromSrams_bore_9_ram_aux_clk = $urandom_range(0,1);
    sigFromSrams_bore_9_ram_aux_ckbp = $urandom_range(0,1);
    sigFromSrams_bore_9_ram_mcp_hold = $urandom_range(0,1);
    sigFromSrams_bore_9_cgen = $urandom_range(0,1);
    sigFromSrams_bore_10_ram_hold = $urandom_range(0,1);
    sigFromSrams_bore_10_ram_bypass = $urandom_range(0,1);
    sigFromSrams_bore_10_ram_bp_clken = $urandom_range(0,1);
    sigFromSrams_bore_10_ram_aux_clk = $urandom_range(0,1);
    sigFromSrams_bore_10_ram_aux_ckbp = $urandom_range(0,1);
    sigFromSrams_bore_10_ram_mcp_hold = $urandom_range(0,1);
    sigFromSrams_bore_10_cgen = $urandom_range(0,1);
    sigFromSrams_bore_11_ram_hold = $urandom_range(0,1);
    sigFromSrams_bore_11_ram_bypass = $urandom_range(0,1);
    sigFromSrams_bore_11_ram_bp_clken = $urandom_range(0,1);
    sigFromSrams_bore_11_ram_aux_clk = $urandom_range(0,1);
    sigFromSrams_bore_11_ram_aux_ckbp = $urandom_range(0,1);
    sigFromSrams_bore_11_ram_mcp_hold = $urandom_range(0,1);
    sigFromSrams_bore_11_cgen = $urandom_range(0,1);
    cg_bore_cgen = $urandom_range(0,1);
  endtask

  initial begin
    reset = 1;
    drive_random();
    repeat (10) @(posedge clock);
    #1 reset = 0;
    for (int t = 0; t < NVEC; t++) begin
      @(negedge clock);
      drive_random();
      @(posedge clock);
      #1;
      if (t >= WARMUP) do_check(t);
    end
    $display("PROBE l3v_mm=%0d l1v_mm=%0d", pmm_l3v, pmm_l1v);
    $display("PROBE l1g_mm=%0d l1vmids_mm=%0d l1repl_mm=%0d l0repl_mm=%0d l2repl_mm=%0d l3repl_mm=%0d",
             pmm_l1g, pmm_l1vmids, pmm_l1repl, pmm_l0repl, pmm_l2repl, pmm_l3repl);
    if (errors==0) $display("TEST PASSED checks=%0d", checks);
    else           $display("TEST FAILED errors=%0d checks=%0d", errors, checks);
    $finish;
  end
endmodule
