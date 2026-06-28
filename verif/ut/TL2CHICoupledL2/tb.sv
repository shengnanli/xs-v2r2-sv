// 自动生成:scripts/gen_coupledl2.py —— 勿手改(顶层 glue 为从 firtool 意图的具名可读重写)

`timescale 1ns/1ps
module tb;
  int unsigned NCYCLES = 200000;
  bit clk = 0, rst;
  int errors = 0, checks = 0;
  always #5 clk = ~clk;

  logic auto_mmioBridge_mmio_in_a_valid;
  logic [3:0] auto_mmioBridge_mmio_in_a_bits_opcode;
  logic [2:0] auto_mmioBridge_mmio_in_a_bits_param;
  logic [1:0] auto_mmioBridge_mmio_in_a_bits_size;
  logic [2:0] auto_mmioBridge_mmio_in_a_bits_source;
  logic [47:0] auto_mmioBridge_mmio_in_a_bits_address;
  logic auto_mmioBridge_mmio_in_a_bits_user_memBackType_MM;
  logic auto_mmioBridge_mmio_in_a_bits_user_memPageType_NC;
  logic [7:0] auto_mmioBridge_mmio_in_a_bits_mask;
  logic [63:0] auto_mmioBridge_mmio_in_a_bits_data;
  logic auto_mmioBridge_mmio_in_a_bits_corrupt;
  logic auto_mmioBridge_mmio_in_d_ready;
  logic auto_in_3_a_valid;
  logic [3:0] auto_in_3_a_bits_opcode;
  logic [2:0] auto_in_3_a_bits_param;
  logic [2:0] auto_in_3_a_bits_size;
  logic [6:0] auto_in_3_a_bits_source;
  logic [47:0] auto_in_3_a_bits_address;
  logic [4:0] auto_in_3_a_bits_user_reqSource;
  logic [1:0] auto_in_3_a_bits_user_alias;
  logic [43:0] auto_in_3_a_bits_user_vaddr;
  logic auto_in_3_a_bits_user_needHint;
  logic auto_in_3_a_bits_echo_isKeyword;
  logic auto_in_3_a_bits_corrupt;
  logic auto_in_3_b_ready;
  logic auto_in_3_c_valid;
  logic [2:0] auto_in_3_c_bits_opcode;
  logic [2:0] auto_in_3_c_bits_param;
  logic [2:0] auto_in_3_c_bits_size;
  logic [6:0] auto_in_3_c_bits_source;
  logic [47:0] auto_in_3_c_bits_address;
  logic [255:0] auto_in_3_c_bits_data;
  logic auto_in_3_c_bits_corrupt;
  logic auto_in_3_d_ready;
  logic auto_in_3_e_valid;
  logic [7:0] auto_in_3_e_bits_sink;
  logic auto_in_2_a_valid;
  logic [3:0] auto_in_2_a_bits_opcode;
  logic [2:0] auto_in_2_a_bits_param;
  logic [2:0] auto_in_2_a_bits_size;
  logic [6:0] auto_in_2_a_bits_source;
  logic [47:0] auto_in_2_a_bits_address;
  logic [4:0] auto_in_2_a_bits_user_reqSource;
  logic [1:0] auto_in_2_a_bits_user_alias;
  logic [43:0] auto_in_2_a_bits_user_vaddr;
  logic auto_in_2_a_bits_user_needHint;
  logic auto_in_2_a_bits_echo_isKeyword;
  logic auto_in_2_a_bits_corrupt;
  logic auto_in_2_b_ready;
  logic auto_in_2_c_valid;
  logic [2:0] auto_in_2_c_bits_opcode;
  logic [2:0] auto_in_2_c_bits_param;
  logic [2:0] auto_in_2_c_bits_size;
  logic [6:0] auto_in_2_c_bits_source;
  logic [47:0] auto_in_2_c_bits_address;
  logic [255:0] auto_in_2_c_bits_data;
  logic auto_in_2_c_bits_corrupt;
  logic auto_in_2_d_ready;
  logic auto_in_2_e_valid;
  logic [7:0] auto_in_2_e_bits_sink;
  logic auto_in_1_a_valid;
  logic [3:0] auto_in_1_a_bits_opcode;
  logic [2:0] auto_in_1_a_bits_param;
  logic [2:0] auto_in_1_a_bits_size;
  logic [6:0] auto_in_1_a_bits_source;
  logic [47:0] auto_in_1_a_bits_address;
  logic [4:0] auto_in_1_a_bits_user_reqSource;
  logic [1:0] auto_in_1_a_bits_user_alias;
  logic [43:0] auto_in_1_a_bits_user_vaddr;
  logic auto_in_1_a_bits_user_needHint;
  logic auto_in_1_a_bits_echo_isKeyword;
  logic auto_in_1_a_bits_corrupt;
  logic auto_in_1_b_ready;
  logic auto_in_1_c_valid;
  logic [2:0] auto_in_1_c_bits_opcode;
  logic [2:0] auto_in_1_c_bits_param;
  logic [2:0] auto_in_1_c_bits_size;
  logic [6:0] auto_in_1_c_bits_source;
  logic [47:0] auto_in_1_c_bits_address;
  logic [255:0] auto_in_1_c_bits_data;
  logic auto_in_1_c_bits_corrupt;
  logic auto_in_1_d_ready;
  logic auto_in_1_e_valid;
  logic [7:0] auto_in_1_e_bits_sink;
  logic auto_in_0_a_valid;
  logic [3:0] auto_in_0_a_bits_opcode;
  logic [2:0] auto_in_0_a_bits_param;
  logic [2:0] auto_in_0_a_bits_size;
  logic [6:0] auto_in_0_a_bits_source;
  logic [47:0] auto_in_0_a_bits_address;
  logic [4:0] auto_in_0_a_bits_user_reqSource;
  logic [1:0] auto_in_0_a_bits_user_alias;
  logic [43:0] auto_in_0_a_bits_user_vaddr;
  logic auto_in_0_a_bits_user_needHint;
  logic auto_in_0_a_bits_echo_isKeyword;
  logic auto_in_0_a_bits_corrupt;
  logic auto_in_0_b_ready;
  logic auto_in_0_c_valid;
  logic [2:0] auto_in_0_c_bits_opcode;
  logic [2:0] auto_in_0_c_bits_param;
  logic [2:0] auto_in_0_c_bits_size;
  logic [6:0] auto_in_0_c_bits_source;
  logic [47:0] auto_in_0_c_bits_address;
  logic [255:0] auto_in_0_c_bits_data;
  logic auto_in_0_c_bits_corrupt;
  logic auto_in_0_d_ready;
  logic auto_in_0_e_valid;
  logic [7:0] auto_in_0_e_bits_sink;
  logic [63:0] auto_pf_recv_in_addr;
  logic [4:0] auto_pf_recv_in_pf_source;
  logic auto_pf_recv_in_addr_valid;
  logic io_pfCtrlFromCore_l2_pf_master_en;
  logic io_pfCtrlFromCore_l2_pf_recv_en;
  logic io_pfCtrlFromCore_l2_pbop_en;
  logic io_pfCtrlFromCore_l2_vbop_en;
  logic io_l2_tlb_req_resp_valid;
  logic [47:0] io_l2_tlb_req_resp_bits_paddr_0;
  logic [1:0] io_l2_tlb_req_resp_bits_pbmt;
  logic io_l2_tlb_req_resp_bits_miss;
  logic io_l2_tlb_req_resp_bits_excp_0_gpf_ld;
  logic io_l2_tlb_req_resp_bits_excp_0_pf_ld;
  logic io_l2_tlb_req_resp_bits_excp_0_af_ld;
  logic io_l2_tlb_req_pmp_resp_ld;
  logic io_l2_tlb_req_pmp_resp_mmio;
  logic io_debugTopDown_robHeadPaddr_valid;
  logic [35:0] io_debugTopDown_robHeadPaddr_bits;
  logic io_dft_ram_hold;
  logic io_dft_ram_bypass;
  logic io_dft_ram_bp_clken;
  logic io_dft_ram_aux_clk;
  logic io_dft_ram_aux_ckbp;
  logic io_dft_ram_mcp_hold;
  logic io_dft_cgen;
  logic io_chi_rxsactive;
  logic io_chi_syscoack;
  logic io_chi_tx_linkactiveack;
  logic io_chi_tx_req_lcrdv;
  logic io_chi_tx_rsp_lcrdv;
  logic io_chi_tx_dat_lcrdv;
  logic io_chi_rx_linkactivereq;
  logic io_chi_rx_rsp_flitpend;
  logic io_chi_rx_rsp_flitv;
  logic [72:0] io_chi_rx_rsp_flit;
  logic io_chi_rx_dat_flitpend;
  logic io_chi_rx_dat_flitv;
  logic [421:0] io_chi_rx_dat_flit;
  logic io_chi_rx_snp_flitpend;
  logic io_chi_rx_snp_flitv;
  logic [114:0] io_chi_rx_snp_flit;
  logic [10:0] io_nodeID;
  wire g_auto_mmioBridge_mmio_in_a_ready;
  wire i_auto_mmioBridge_mmio_in_a_ready;
  wire g_auto_mmioBridge_mmio_in_d_valid;
  wire i_auto_mmioBridge_mmio_in_d_valid;
  wire [3:0] g_auto_mmioBridge_mmio_in_d_bits_opcode;
  wire [3:0] i_auto_mmioBridge_mmio_in_d_bits_opcode;
  wire [1:0] g_auto_mmioBridge_mmio_in_d_bits_param;
  wire [1:0] i_auto_mmioBridge_mmio_in_d_bits_param;
  wire [1:0] g_auto_mmioBridge_mmio_in_d_bits_size;
  wire [1:0] i_auto_mmioBridge_mmio_in_d_bits_size;
  wire [2:0] g_auto_mmioBridge_mmio_in_d_bits_source;
  wire [2:0] i_auto_mmioBridge_mmio_in_d_bits_source;
  wire g_auto_mmioBridge_mmio_in_d_bits_sink;
  wire i_auto_mmioBridge_mmio_in_d_bits_sink;
  wire g_auto_mmioBridge_mmio_in_d_bits_denied;
  wire i_auto_mmioBridge_mmio_in_d_bits_denied;
  wire [63:0] g_auto_mmioBridge_mmio_in_d_bits_data;
  wire [63:0] i_auto_mmioBridge_mmio_in_d_bits_data;
  wire g_auto_mmioBridge_mmio_in_d_bits_corrupt;
  wire i_auto_mmioBridge_mmio_in_d_bits_corrupt;
  wire g_auto_in_3_a_ready;
  wire i_auto_in_3_a_ready;
  wire g_auto_in_3_b_valid;
  wire i_auto_in_3_b_valid;
  wire [2:0] g_auto_in_3_b_bits_opcode;
  wire [2:0] i_auto_in_3_b_bits_opcode;
  wire [1:0] g_auto_in_3_b_bits_param;
  wire [1:0] i_auto_in_3_b_bits_param;
  wire [47:0] g_auto_in_3_b_bits_address;
  wire [47:0] i_auto_in_3_b_bits_address;
  wire [255:0] g_auto_in_3_b_bits_data;
  wire [255:0] i_auto_in_3_b_bits_data;
  wire g_auto_in_3_c_ready;
  wire i_auto_in_3_c_ready;
  wire g_auto_in_3_d_valid;
  wire i_auto_in_3_d_valid;
  wire [3:0] g_auto_in_3_d_bits_opcode;
  wire [3:0] i_auto_in_3_d_bits_opcode;
  wire [1:0] g_auto_in_3_d_bits_param;
  wire [1:0] i_auto_in_3_d_bits_param;
  wire [6:0] g_auto_in_3_d_bits_source;
  wire [6:0] i_auto_in_3_d_bits_source;
  wire [7:0] g_auto_in_3_d_bits_sink;
  wire [7:0] i_auto_in_3_d_bits_sink;
  wire g_auto_in_3_d_bits_denied;
  wire i_auto_in_3_d_bits_denied;
  wire g_auto_in_3_d_bits_echo_isKeyword;
  wire i_auto_in_3_d_bits_echo_isKeyword;
  wire [255:0] g_auto_in_3_d_bits_data;
  wire [255:0] i_auto_in_3_d_bits_data;
  wire g_auto_in_3_d_bits_corrupt;
  wire i_auto_in_3_d_bits_corrupt;
  wire g_auto_in_2_a_ready;
  wire i_auto_in_2_a_ready;
  wire g_auto_in_2_b_valid;
  wire i_auto_in_2_b_valid;
  wire [2:0] g_auto_in_2_b_bits_opcode;
  wire [2:0] i_auto_in_2_b_bits_opcode;
  wire [1:0] g_auto_in_2_b_bits_param;
  wire [1:0] i_auto_in_2_b_bits_param;
  wire [47:0] g_auto_in_2_b_bits_address;
  wire [47:0] i_auto_in_2_b_bits_address;
  wire [255:0] g_auto_in_2_b_bits_data;
  wire [255:0] i_auto_in_2_b_bits_data;
  wire g_auto_in_2_c_ready;
  wire i_auto_in_2_c_ready;
  wire g_auto_in_2_d_valid;
  wire i_auto_in_2_d_valid;
  wire [3:0] g_auto_in_2_d_bits_opcode;
  wire [3:0] i_auto_in_2_d_bits_opcode;
  wire [1:0] g_auto_in_2_d_bits_param;
  wire [1:0] i_auto_in_2_d_bits_param;
  wire [6:0] g_auto_in_2_d_bits_source;
  wire [6:0] i_auto_in_2_d_bits_source;
  wire [7:0] g_auto_in_2_d_bits_sink;
  wire [7:0] i_auto_in_2_d_bits_sink;
  wire g_auto_in_2_d_bits_denied;
  wire i_auto_in_2_d_bits_denied;
  wire g_auto_in_2_d_bits_echo_isKeyword;
  wire i_auto_in_2_d_bits_echo_isKeyword;
  wire [255:0] g_auto_in_2_d_bits_data;
  wire [255:0] i_auto_in_2_d_bits_data;
  wire g_auto_in_2_d_bits_corrupt;
  wire i_auto_in_2_d_bits_corrupt;
  wire g_auto_in_1_a_ready;
  wire i_auto_in_1_a_ready;
  wire g_auto_in_1_b_valid;
  wire i_auto_in_1_b_valid;
  wire [2:0] g_auto_in_1_b_bits_opcode;
  wire [2:0] i_auto_in_1_b_bits_opcode;
  wire [1:0] g_auto_in_1_b_bits_param;
  wire [1:0] i_auto_in_1_b_bits_param;
  wire [47:0] g_auto_in_1_b_bits_address;
  wire [47:0] i_auto_in_1_b_bits_address;
  wire [255:0] g_auto_in_1_b_bits_data;
  wire [255:0] i_auto_in_1_b_bits_data;
  wire g_auto_in_1_c_ready;
  wire i_auto_in_1_c_ready;
  wire g_auto_in_1_d_valid;
  wire i_auto_in_1_d_valid;
  wire [3:0] g_auto_in_1_d_bits_opcode;
  wire [3:0] i_auto_in_1_d_bits_opcode;
  wire [1:0] g_auto_in_1_d_bits_param;
  wire [1:0] i_auto_in_1_d_bits_param;
  wire [6:0] g_auto_in_1_d_bits_source;
  wire [6:0] i_auto_in_1_d_bits_source;
  wire [7:0] g_auto_in_1_d_bits_sink;
  wire [7:0] i_auto_in_1_d_bits_sink;
  wire g_auto_in_1_d_bits_denied;
  wire i_auto_in_1_d_bits_denied;
  wire g_auto_in_1_d_bits_echo_isKeyword;
  wire i_auto_in_1_d_bits_echo_isKeyword;
  wire [255:0] g_auto_in_1_d_bits_data;
  wire [255:0] i_auto_in_1_d_bits_data;
  wire g_auto_in_1_d_bits_corrupt;
  wire i_auto_in_1_d_bits_corrupt;
  wire g_auto_in_0_a_ready;
  wire i_auto_in_0_a_ready;
  wire g_auto_in_0_b_valid;
  wire i_auto_in_0_b_valid;
  wire [2:0] g_auto_in_0_b_bits_opcode;
  wire [2:0] i_auto_in_0_b_bits_opcode;
  wire [1:0] g_auto_in_0_b_bits_param;
  wire [1:0] i_auto_in_0_b_bits_param;
  wire [47:0] g_auto_in_0_b_bits_address;
  wire [47:0] i_auto_in_0_b_bits_address;
  wire [255:0] g_auto_in_0_b_bits_data;
  wire [255:0] i_auto_in_0_b_bits_data;
  wire g_auto_in_0_c_ready;
  wire i_auto_in_0_c_ready;
  wire g_auto_in_0_d_valid;
  wire i_auto_in_0_d_valid;
  wire [3:0] g_auto_in_0_d_bits_opcode;
  wire [3:0] i_auto_in_0_d_bits_opcode;
  wire [1:0] g_auto_in_0_d_bits_param;
  wire [1:0] i_auto_in_0_d_bits_param;
  wire [6:0] g_auto_in_0_d_bits_source;
  wire [6:0] i_auto_in_0_d_bits_source;
  wire [7:0] g_auto_in_0_d_bits_sink;
  wire [7:0] i_auto_in_0_d_bits_sink;
  wire g_auto_in_0_d_bits_denied;
  wire i_auto_in_0_d_bits_denied;
  wire g_auto_in_0_d_bits_echo_isKeyword;
  wire i_auto_in_0_d_bits_echo_isKeyword;
  wire [255:0] g_auto_in_0_d_bits_data;
  wire [255:0] i_auto_in_0_d_bits_data;
  wire g_auto_in_0_d_bits_corrupt;
  wire i_auto_in_0_d_bits_corrupt;
  wire g_io_l2_hint_valid;
  wire i_io_l2_hint_valid;
  wire [31:0] g_io_l2_hint_bits_sourceId;
  wire [31:0] i_io_l2_hint_bits_sourceId;
  wire g_io_l2_hint_bits_isKeyword;
  wire i_io_l2_hint_bits_isKeyword;
  wire g_io_l2_tlb_req_req_valid;
  wire i_io_l2_tlb_req_req_valid;
  wire [49:0] g_io_l2_tlb_req_req_bits_vaddr;
  wire [49:0] i_io_l2_tlb_req_req_bits_vaddr;
  wire [2:0] g_io_l2_tlb_req_req_bits_cmd;
  wire [2:0] i_io_l2_tlb_req_req_bits_cmd;
  wire g_io_l2_tlb_req_req_bits_kill;
  wire i_io_l2_tlb_req_req_bits_kill;
  wire g_io_l2_tlb_req_req_bits_no_translate;
  wire i_io_l2_tlb_req_req_bits_no_translate;
  wire g_io_debugTopDown_l2MissMatch;
  wire i_io_debugTopDown_l2MissMatch;
  wire g_io_l2Miss;
  wire i_io_l2Miss;
  wire g_io_error_valid;
  wire i_io_error_valid;
  wire [45:0] g_io_error_address;
  wire [45:0] i_io_error_address;
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
  wire [5:0] g_io_perf_19_value;
  wire [5:0] i_io_perf_19_value;
  wire [5:0] g_io_perf_20_value;
  wire [5:0] i_io_perf_20_value;
  wire [5:0] g_io_perf_21_value;
  wire [5:0] i_io_perf_21_value;
  wire [5:0] g_io_perf_22_value;
  wire [5:0] i_io_perf_22_value;
  wire [5:0] g_io_perf_23_value;
  wire [5:0] i_io_perf_23_value;
  wire [5:0] g_io_perf_24_value;
  wire [5:0] i_io_perf_24_value;
  wire [5:0] g_io_perf_25_value;
  wire [5:0] i_io_perf_25_value;
  wire [5:0] g_io_perf_26_value;
  wire [5:0] i_io_perf_26_value;
  wire [5:0] g_io_perf_27_value;
  wire [5:0] i_io_perf_27_value;
  wire [5:0] g_io_perf_28_value;
  wire [5:0] i_io_perf_28_value;
  wire [5:0] g_io_perf_29_value;
  wire [5:0] i_io_perf_29_value;
  wire [5:0] g_io_perf_30_value;
  wire [5:0] i_io_perf_30_value;
  wire [5:0] g_io_perf_31_value;
  wire [5:0] i_io_perf_31_value;
  wire [5:0] g_io_perf_32_value;
  wire [5:0] i_io_perf_32_value;
  wire [5:0] g_io_perf_33_value;
  wire [5:0] i_io_perf_33_value;
  wire [5:0] g_io_perf_34_value;
  wire [5:0] i_io_perf_34_value;
  wire [5:0] g_io_perf_35_value;
  wire [5:0] i_io_perf_35_value;
  wire [5:0] g_io_perf_36_value;
  wire [5:0] i_io_perf_36_value;
  wire [5:0] g_io_perf_37_value;
  wire [5:0] i_io_perf_37_value;
  wire [5:0] g_io_perf_38_value;
  wire [5:0] i_io_perf_38_value;
  wire [5:0] g_io_perf_39_value;
  wire [5:0] i_io_perf_39_value;
  wire [5:0] g_io_perf_40_value;
  wire [5:0] i_io_perf_40_value;
  wire [5:0] g_io_perf_41_value;
  wire [5:0] i_io_perf_41_value;
  wire [5:0] g_io_perf_42_value;
  wire [5:0] i_io_perf_42_value;
  wire [5:0] g_io_perf_43_value;
  wire [5:0] i_io_perf_43_value;
  wire [5:0] g_io_perf_44_value;
  wire [5:0] i_io_perf_44_value;
  wire [5:0] g_io_perf_45_value;
  wire [5:0] i_io_perf_45_value;
  wire [5:0] g_io_perf_46_value;
  wire [5:0] i_io_perf_46_value;
  wire [5:0] g_io_perf_47_value;
  wire [5:0] i_io_perf_47_value;
  wire [5:0] g_io_perf_48_value;
  wire [5:0] i_io_perf_48_value;
  wire g_io_chi_txsactive;
  wire i_io_chi_txsactive;
  wire g_io_chi_syscoreq;
  wire i_io_chi_syscoreq;
  wire g_io_chi_tx_linkactivereq;
  wire i_io_chi_tx_linkactivereq;
  wire g_io_chi_tx_req_flitpend;
  wire i_io_chi_tx_req_flitpend;
  wire g_io_chi_tx_req_flitv;
  wire i_io_chi_tx_req_flitv;
  wire [161:0] g_io_chi_tx_req_flit;
  wire [161:0] i_io_chi_tx_req_flit;
  wire g_io_chi_tx_rsp_flitpend;
  wire i_io_chi_tx_rsp_flitpend;
  wire g_io_chi_tx_rsp_flitv;
  wire i_io_chi_tx_rsp_flitv;
  wire [72:0] g_io_chi_tx_rsp_flit;
  wire [72:0] i_io_chi_tx_rsp_flit;
  wire g_io_chi_tx_dat_flitpend;
  wire i_io_chi_tx_dat_flitpend;
  wire g_io_chi_tx_dat_flitv;
  wire i_io_chi_tx_dat_flitv;
  wire [421:0] g_io_chi_tx_dat_flit;
  wire [421:0] i_io_chi_tx_dat_flit;
  wire g_io_chi_rx_linkactiveack;
  wire i_io_chi_rx_linkactiveack;
  wire g_io_chi_rx_rsp_lcrdv;
  wire i_io_chi_rx_rsp_lcrdv;
  wire g_io_chi_rx_dat_lcrdv;
  wire i_io_chi_rx_dat_lcrdv;
  wire g_io_chi_rx_snp_lcrdv;
  wire i_io_chi_rx_snp_lcrdv;

  TL2CHICoupledL2    u_g (.clock(clk), .reset(rst), .auto_mmioBridge_mmio_in_a_ready(g_auto_mmioBridge_mmio_in_a_ready), .auto_mmioBridge_mmio_in_a_valid(auto_mmioBridge_mmio_in_a_valid), .auto_mmioBridge_mmio_in_a_bits_opcode(auto_mmioBridge_mmio_in_a_bits_opcode), .auto_mmioBridge_mmio_in_a_bits_param(auto_mmioBridge_mmio_in_a_bits_param), .auto_mmioBridge_mmio_in_a_bits_size(auto_mmioBridge_mmio_in_a_bits_size), .auto_mmioBridge_mmio_in_a_bits_source(auto_mmioBridge_mmio_in_a_bits_source), .auto_mmioBridge_mmio_in_a_bits_address(auto_mmioBridge_mmio_in_a_bits_address), .auto_mmioBridge_mmio_in_a_bits_user_memBackType_MM(auto_mmioBridge_mmio_in_a_bits_user_memBackType_MM), .auto_mmioBridge_mmio_in_a_bits_user_memPageType_NC(auto_mmioBridge_mmio_in_a_bits_user_memPageType_NC), .auto_mmioBridge_mmio_in_a_bits_mask(auto_mmioBridge_mmio_in_a_bits_mask), .auto_mmioBridge_mmio_in_a_bits_data(auto_mmioBridge_mmio_in_a_bits_data), .auto_mmioBridge_mmio_in_a_bits_corrupt(auto_mmioBridge_mmio_in_a_bits_corrupt), .auto_mmioBridge_mmio_in_d_ready(auto_mmioBridge_mmio_in_d_ready), .auto_mmioBridge_mmio_in_d_valid(g_auto_mmioBridge_mmio_in_d_valid), .auto_mmioBridge_mmio_in_d_bits_opcode(g_auto_mmioBridge_mmio_in_d_bits_opcode), .auto_mmioBridge_mmio_in_d_bits_param(g_auto_mmioBridge_mmio_in_d_bits_param), .auto_mmioBridge_mmio_in_d_bits_size(g_auto_mmioBridge_mmio_in_d_bits_size), .auto_mmioBridge_mmio_in_d_bits_source(g_auto_mmioBridge_mmio_in_d_bits_source), .auto_mmioBridge_mmio_in_d_bits_sink(g_auto_mmioBridge_mmio_in_d_bits_sink), .auto_mmioBridge_mmio_in_d_bits_denied(g_auto_mmioBridge_mmio_in_d_bits_denied), .auto_mmioBridge_mmio_in_d_bits_data(g_auto_mmioBridge_mmio_in_d_bits_data), .auto_mmioBridge_mmio_in_d_bits_corrupt(g_auto_mmioBridge_mmio_in_d_bits_corrupt), .auto_in_3_a_ready(g_auto_in_3_a_ready), .auto_in_3_a_valid(auto_in_3_a_valid), .auto_in_3_a_bits_opcode(auto_in_3_a_bits_opcode), .auto_in_3_a_bits_param(auto_in_3_a_bits_param), .auto_in_3_a_bits_size(auto_in_3_a_bits_size), .auto_in_3_a_bits_source(auto_in_3_a_bits_source), .auto_in_3_a_bits_address(auto_in_3_a_bits_address), .auto_in_3_a_bits_user_reqSource(auto_in_3_a_bits_user_reqSource), .auto_in_3_a_bits_user_alias(auto_in_3_a_bits_user_alias), .auto_in_3_a_bits_user_vaddr(auto_in_3_a_bits_user_vaddr), .auto_in_3_a_bits_user_needHint(auto_in_3_a_bits_user_needHint), .auto_in_3_a_bits_echo_isKeyword(auto_in_3_a_bits_echo_isKeyword), .auto_in_3_a_bits_corrupt(auto_in_3_a_bits_corrupt), .auto_in_3_b_ready(auto_in_3_b_ready), .auto_in_3_b_valid(g_auto_in_3_b_valid), .auto_in_3_b_bits_opcode(g_auto_in_3_b_bits_opcode), .auto_in_3_b_bits_param(g_auto_in_3_b_bits_param), .auto_in_3_b_bits_address(g_auto_in_3_b_bits_address), .auto_in_3_b_bits_data(g_auto_in_3_b_bits_data), .auto_in_3_c_ready(g_auto_in_3_c_ready), .auto_in_3_c_valid(auto_in_3_c_valid), .auto_in_3_c_bits_opcode(auto_in_3_c_bits_opcode), .auto_in_3_c_bits_param(auto_in_3_c_bits_param), .auto_in_3_c_bits_size(auto_in_3_c_bits_size), .auto_in_3_c_bits_source(auto_in_3_c_bits_source), .auto_in_3_c_bits_address(auto_in_3_c_bits_address), .auto_in_3_c_bits_data(auto_in_3_c_bits_data), .auto_in_3_c_bits_corrupt(auto_in_3_c_bits_corrupt), .auto_in_3_d_ready(auto_in_3_d_ready), .auto_in_3_d_valid(g_auto_in_3_d_valid), .auto_in_3_d_bits_opcode(g_auto_in_3_d_bits_opcode), .auto_in_3_d_bits_param(g_auto_in_3_d_bits_param), .auto_in_3_d_bits_source(g_auto_in_3_d_bits_source), .auto_in_3_d_bits_sink(g_auto_in_3_d_bits_sink), .auto_in_3_d_bits_denied(g_auto_in_3_d_bits_denied), .auto_in_3_d_bits_echo_isKeyword(g_auto_in_3_d_bits_echo_isKeyword), .auto_in_3_d_bits_data(g_auto_in_3_d_bits_data), .auto_in_3_d_bits_corrupt(g_auto_in_3_d_bits_corrupt), .auto_in_3_e_valid(auto_in_3_e_valid), .auto_in_3_e_bits_sink(auto_in_3_e_bits_sink), .auto_in_2_a_ready(g_auto_in_2_a_ready), .auto_in_2_a_valid(auto_in_2_a_valid), .auto_in_2_a_bits_opcode(auto_in_2_a_bits_opcode), .auto_in_2_a_bits_param(auto_in_2_a_bits_param), .auto_in_2_a_bits_size(auto_in_2_a_bits_size), .auto_in_2_a_bits_source(auto_in_2_a_bits_source), .auto_in_2_a_bits_address(auto_in_2_a_bits_address), .auto_in_2_a_bits_user_reqSource(auto_in_2_a_bits_user_reqSource), .auto_in_2_a_bits_user_alias(auto_in_2_a_bits_user_alias), .auto_in_2_a_bits_user_vaddr(auto_in_2_a_bits_user_vaddr), .auto_in_2_a_bits_user_needHint(auto_in_2_a_bits_user_needHint), .auto_in_2_a_bits_echo_isKeyword(auto_in_2_a_bits_echo_isKeyword), .auto_in_2_a_bits_corrupt(auto_in_2_a_bits_corrupt), .auto_in_2_b_ready(auto_in_2_b_ready), .auto_in_2_b_valid(g_auto_in_2_b_valid), .auto_in_2_b_bits_opcode(g_auto_in_2_b_bits_opcode), .auto_in_2_b_bits_param(g_auto_in_2_b_bits_param), .auto_in_2_b_bits_address(g_auto_in_2_b_bits_address), .auto_in_2_b_bits_data(g_auto_in_2_b_bits_data), .auto_in_2_c_ready(g_auto_in_2_c_ready), .auto_in_2_c_valid(auto_in_2_c_valid), .auto_in_2_c_bits_opcode(auto_in_2_c_bits_opcode), .auto_in_2_c_bits_param(auto_in_2_c_bits_param), .auto_in_2_c_bits_size(auto_in_2_c_bits_size), .auto_in_2_c_bits_source(auto_in_2_c_bits_source), .auto_in_2_c_bits_address(auto_in_2_c_bits_address), .auto_in_2_c_bits_data(auto_in_2_c_bits_data), .auto_in_2_c_bits_corrupt(auto_in_2_c_bits_corrupt), .auto_in_2_d_ready(auto_in_2_d_ready), .auto_in_2_d_valid(g_auto_in_2_d_valid), .auto_in_2_d_bits_opcode(g_auto_in_2_d_bits_opcode), .auto_in_2_d_bits_param(g_auto_in_2_d_bits_param), .auto_in_2_d_bits_source(g_auto_in_2_d_bits_source), .auto_in_2_d_bits_sink(g_auto_in_2_d_bits_sink), .auto_in_2_d_bits_denied(g_auto_in_2_d_bits_denied), .auto_in_2_d_bits_echo_isKeyword(g_auto_in_2_d_bits_echo_isKeyword), .auto_in_2_d_bits_data(g_auto_in_2_d_bits_data), .auto_in_2_d_bits_corrupt(g_auto_in_2_d_bits_corrupt), .auto_in_2_e_valid(auto_in_2_e_valid), .auto_in_2_e_bits_sink(auto_in_2_e_bits_sink), .auto_in_1_a_ready(g_auto_in_1_a_ready), .auto_in_1_a_valid(auto_in_1_a_valid), .auto_in_1_a_bits_opcode(auto_in_1_a_bits_opcode), .auto_in_1_a_bits_param(auto_in_1_a_bits_param), .auto_in_1_a_bits_size(auto_in_1_a_bits_size), .auto_in_1_a_bits_source(auto_in_1_a_bits_source), .auto_in_1_a_bits_address(auto_in_1_a_bits_address), .auto_in_1_a_bits_user_reqSource(auto_in_1_a_bits_user_reqSource), .auto_in_1_a_bits_user_alias(auto_in_1_a_bits_user_alias), .auto_in_1_a_bits_user_vaddr(auto_in_1_a_bits_user_vaddr), .auto_in_1_a_bits_user_needHint(auto_in_1_a_bits_user_needHint), .auto_in_1_a_bits_echo_isKeyword(auto_in_1_a_bits_echo_isKeyword), .auto_in_1_a_bits_corrupt(auto_in_1_a_bits_corrupt), .auto_in_1_b_ready(auto_in_1_b_ready), .auto_in_1_b_valid(g_auto_in_1_b_valid), .auto_in_1_b_bits_opcode(g_auto_in_1_b_bits_opcode), .auto_in_1_b_bits_param(g_auto_in_1_b_bits_param), .auto_in_1_b_bits_address(g_auto_in_1_b_bits_address), .auto_in_1_b_bits_data(g_auto_in_1_b_bits_data), .auto_in_1_c_ready(g_auto_in_1_c_ready), .auto_in_1_c_valid(auto_in_1_c_valid), .auto_in_1_c_bits_opcode(auto_in_1_c_bits_opcode), .auto_in_1_c_bits_param(auto_in_1_c_bits_param), .auto_in_1_c_bits_size(auto_in_1_c_bits_size), .auto_in_1_c_bits_source(auto_in_1_c_bits_source), .auto_in_1_c_bits_address(auto_in_1_c_bits_address), .auto_in_1_c_bits_data(auto_in_1_c_bits_data), .auto_in_1_c_bits_corrupt(auto_in_1_c_bits_corrupt), .auto_in_1_d_ready(auto_in_1_d_ready), .auto_in_1_d_valid(g_auto_in_1_d_valid), .auto_in_1_d_bits_opcode(g_auto_in_1_d_bits_opcode), .auto_in_1_d_bits_param(g_auto_in_1_d_bits_param), .auto_in_1_d_bits_source(g_auto_in_1_d_bits_source), .auto_in_1_d_bits_sink(g_auto_in_1_d_bits_sink), .auto_in_1_d_bits_denied(g_auto_in_1_d_bits_denied), .auto_in_1_d_bits_echo_isKeyword(g_auto_in_1_d_bits_echo_isKeyword), .auto_in_1_d_bits_data(g_auto_in_1_d_bits_data), .auto_in_1_d_bits_corrupt(g_auto_in_1_d_bits_corrupt), .auto_in_1_e_valid(auto_in_1_e_valid), .auto_in_1_e_bits_sink(auto_in_1_e_bits_sink), .auto_in_0_a_ready(g_auto_in_0_a_ready), .auto_in_0_a_valid(auto_in_0_a_valid), .auto_in_0_a_bits_opcode(auto_in_0_a_bits_opcode), .auto_in_0_a_bits_param(auto_in_0_a_bits_param), .auto_in_0_a_bits_size(auto_in_0_a_bits_size), .auto_in_0_a_bits_source(auto_in_0_a_bits_source), .auto_in_0_a_bits_address(auto_in_0_a_bits_address), .auto_in_0_a_bits_user_reqSource(auto_in_0_a_bits_user_reqSource), .auto_in_0_a_bits_user_alias(auto_in_0_a_bits_user_alias), .auto_in_0_a_bits_user_vaddr(auto_in_0_a_bits_user_vaddr), .auto_in_0_a_bits_user_needHint(auto_in_0_a_bits_user_needHint), .auto_in_0_a_bits_echo_isKeyword(auto_in_0_a_bits_echo_isKeyword), .auto_in_0_a_bits_corrupt(auto_in_0_a_bits_corrupt), .auto_in_0_b_ready(auto_in_0_b_ready), .auto_in_0_b_valid(g_auto_in_0_b_valid), .auto_in_0_b_bits_opcode(g_auto_in_0_b_bits_opcode), .auto_in_0_b_bits_param(g_auto_in_0_b_bits_param), .auto_in_0_b_bits_address(g_auto_in_0_b_bits_address), .auto_in_0_b_bits_data(g_auto_in_0_b_bits_data), .auto_in_0_c_ready(g_auto_in_0_c_ready), .auto_in_0_c_valid(auto_in_0_c_valid), .auto_in_0_c_bits_opcode(auto_in_0_c_bits_opcode), .auto_in_0_c_bits_param(auto_in_0_c_bits_param), .auto_in_0_c_bits_size(auto_in_0_c_bits_size), .auto_in_0_c_bits_source(auto_in_0_c_bits_source), .auto_in_0_c_bits_address(auto_in_0_c_bits_address), .auto_in_0_c_bits_data(auto_in_0_c_bits_data), .auto_in_0_c_bits_corrupt(auto_in_0_c_bits_corrupt), .auto_in_0_d_ready(auto_in_0_d_ready), .auto_in_0_d_valid(g_auto_in_0_d_valid), .auto_in_0_d_bits_opcode(g_auto_in_0_d_bits_opcode), .auto_in_0_d_bits_param(g_auto_in_0_d_bits_param), .auto_in_0_d_bits_source(g_auto_in_0_d_bits_source), .auto_in_0_d_bits_sink(g_auto_in_0_d_bits_sink), .auto_in_0_d_bits_denied(g_auto_in_0_d_bits_denied), .auto_in_0_d_bits_echo_isKeyword(g_auto_in_0_d_bits_echo_isKeyword), .auto_in_0_d_bits_data(g_auto_in_0_d_bits_data), .auto_in_0_d_bits_corrupt(g_auto_in_0_d_bits_corrupt), .auto_in_0_e_valid(auto_in_0_e_valid), .auto_in_0_e_bits_sink(auto_in_0_e_bits_sink), .auto_pf_recv_in_addr(auto_pf_recv_in_addr), .auto_pf_recv_in_pf_source(auto_pf_recv_in_pf_source), .auto_pf_recv_in_addr_valid(auto_pf_recv_in_addr_valid), .io_pfCtrlFromCore_l2_pf_master_en(io_pfCtrlFromCore_l2_pf_master_en), .io_pfCtrlFromCore_l2_pf_recv_en(io_pfCtrlFromCore_l2_pf_recv_en), .io_pfCtrlFromCore_l2_pbop_en(io_pfCtrlFromCore_l2_pbop_en), .io_pfCtrlFromCore_l2_vbop_en(io_pfCtrlFromCore_l2_vbop_en), .io_l2_hint_valid(g_io_l2_hint_valid), .io_l2_hint_bits_sourceId(g_io_l2_hint_bits_sourceId), .io_l2_hint_bits_isKeyword(g_io_l2_hint_bits_isKeyword), .io_l2_tlb_req_req_valid(g_io_l2_tlb_req_req_valid), .io_l2_tlb_req_req_bits_vaddr(g_io_l2_tlb_req_req_bits_vaddr), .io_l2_tlb_req_req_bits_cmd(g_io_l2_tlb_req_req_bits_cmd), .io_l2_tlb_req_req_bits_kill(g_io_l2_tlb_req_req_bits_kill), .io_l2_tlb_req_req_bits_no_translate(g_io_l2_tlb_req_req_bits_no_translate), .io_l2_tlb_req_resp_valid(io_l2_tlb_req_resp_valid), .io_l2_tlb_req_resp_bits_paddr_0(io_l2_tlb_req_resp_bits_paddr_0), .io_l2_tlb_req_resp_bits_pbmt(io_l2_tlb_req_resp_bits_pbmt), .io_l2_tlb_req_resp_bits_miss(io_l2_tlb_req_resp_bits_miss), .io_l2_tlb_req_resp_bits_excp_0_gpf_ld(io_l2_tlb_req_resp_bits_excp_0_gpf_ld), .io_l2_tlb_req_resp_bits_excp_0_pf_ld(io_l2_tlb_req_resp_bits_excp_0_pf_ld), .io_l2_tlb_req_resp_bits_excp_0_af_ld(io_l2_tlb_req_resp_bits_excp_0_af_ld), .io_l2_tlb_req_pmp_resp_ld(io_l2_tlb_req_pmp_resp_ld), .io_l2_tlb_req_pmp_resp_mmio(io_l2_tlb_req_pmp_resp_mmio), .io_debugTopDown_robHeadPaddr_valid(io_debugTopDown_robHeadPaddr_valid), .io_debugTopDown_robHeadPaddr_bits(io_debugTopDown_robHeadPaddr_bits), .io_debugTopDown_l2MissMatch(g_io_debugTopDown_l2MissMatch), .io_l2Miss(g_io_l2Miss), .io_error_valid(g_io_error_valid), .io_error_address(g_io_error_address), .io_dft_ram_hold(io_dft_ram_hold), .io_dft_ram_bypass(io_dft_ram_bypass), .io_dft_ram_bp_clken(io_dft_ram_bp_clken), .io_dft_ram_aux_clk(io_dft_ram_aux_clk), .io_dft_ram_aux_ckbp(io_dft_ram_aux_ckbp), .io_dft_ram_mcp_hold(io_dft_ram_mcp_hold), .io_dft_cgen(io_dft_cgen), .io_perf_1_value(g_io_perf_1_value), .io_perf_2_value(g_io_perf_2_value), .io_perf_3_value(g_io_perf_3_value), .io_perf_4_value(g_io_perf_4_value), .io_perf_5_value(g_io_perf_5_value), .io_perf_6_value(g_io_perf_6_value), .io_perf_7_value(g_io_perf_7_value), .io_perf_8_value(g_io_perf_8_value), .io_perf_9_value(g_io_perf_9_value), .io_perf_10_value(g_io_perf_10_value), .io_perf_11_value(g_io_perf_11_value), .io_perf_12_value(g_io_perf_12_value), .io_perf_13_value(g_io_perf_13_value), .io_perf_14_value(g_io_perf_14_value), .io_perf_15_value(g_io_perf_15_value), .io_perf_16_value(g_io_perf_16_value), .io_perf_17_value(g_io_perf_17_value), .io_perf_18_value(g_io_perf_18_value), .io_perf_19_value(g_io_perf_19_value), .io_perf_20_value(g_io_perf_20_value), .io_perf_21_value(g_io_perf_21_value), .io_perf_22_value(g_io_perf_22_value), .io_perf_23_value(g_io_perf_23_value), .io_perf_24_value(g_io_perf_24_value), .io_perf_25_value(g_io_perf_25_value), .io_perf_26_value(g_io_perf_26_value), .io_perf_27_value(g_io_perf_27_value), .io_perf_28_value(g_io_perf_28_value), .io_perf_29_value(g_io_perf_29_value), .io_perf_30_value(g_io_perf_30_value), .io_perf_31_value(g_io_perf_31_value), .io_perf_32_value(g_io_perf_32_value), .io_perf_33_value(g_io_perf_33_value), .io_perf_34_value(g_io_perf_34_value), .io_perf_35_value(g_io_perf_35_value), .io_perf_36_value(g_io_perf_36_value), .io_perf_37_value(g_io_perf_37_value), .io_perf_38_value(g_io_perf_38_value), .io_perf_39_value(g_io_perf_39_value), .io_perf_40_value(g_io_perf_40_value), .io_perf_41_value(g_io_perf_41_value), .io_perf_42_value(g_io_perf_42_value), .io_perf_43_value(g_io_perf_43_value), .io_perf_44_value(g_io_perf_44_value), .io_perf_45_value(g_io_perf_45_value), .io_perf_46_value(g_io_perf_46_value), .io_perf_47_value(g_io_perf_47_value), .io_perf_48_value(g_io_perf_48_value), .io_chi_txsactive(g_io_chi_txsactive), .io_chi_rxsactive(io_chi_rxsactive), .io_chi_syscoreq(g_io_chi_syscoreq), .io_chi_syscoack(io_chi_syscoack), .io_chi_tx_linkactivereq(g_io_chi_tx_linkactivereq), .io_chi_tx_linkactiveack(io_chi_tx_linkactiveack), .io_chi_tx_req_flitpend(g_io_chi_tx_req_flitpend), .io_chi_tx_req_flitv(g_io_chi_tx_req_flitv), .io_chi_tx_req_flit(g_io_chi_tx_req_flit), .io_chi_tx_req_lcrdv(io_chi_tx_req_lcrdv), .io_chi_tx_rsp_flitpend(g_io_chi_tx_rsp_flitpend), .io_chi_tx_rsp_flitv(g_io_chi_tx_rsp_flitv), .io_chi_tx_rsp_flit(g_io_chi_tx_rsp_flit), .io_chi_tx_rsp_lcrdv(io_chi_tx_rsp_lcrdv), .io_chi_tx_dat_flitpend(g_io_chi_tx_dat_flitpend), .io_chi_tx_dat_flitv(g_io_chi_tx_dat_flitv), .io_chi_tx_dat_flit(g_io_chi_tx_dat_flit), .io_chi_tx_dat_lcrdv(io_chi_tx_dat_lcrdv), .io_chi_rx_linkactivereq(io_chi_rx_linkactivereq), .io_chi_rx_linkactiveack(g_io_chi_rx_linkactiveack), .io_chi_rx_rsp_flitpend(io_chi_rx_rsp_flitpend), .io_chi_rx_rsp_flitv(io_chi_rx_rsp_flitv), .io_chi_rx_rsp_flit(io_chi_rx_rsp_flit), .io_chi_rx_rsp_lcrdv(g_io_chi_rx_rsp_lcrdv), .io_chi_rx_dat_flitpend(io_chi_rx_dat_flitpend), .io_chi_rx_dat_flitv(io_chi_rx_dat_flitv), .io_chi_rx_dat_flit(io_chi_rx_dat_flit), .io_chi_rx_dat_lcrdv(g_io_chi_rx_dat_lcrdv), .io_chi_rx_snp_flitpend(io_chi_rx_snp_flitpend), .io_chi_rx_snp_flitv(io_chi_rx_snp_flitv), .io_chi_rx_snp_flit(io_chi_rx_snp_flit), .io_chi_rx_snp_lcrdv(g_io_chi_rx_snp_lcrdv), .io_nodeID(io_nodeID));
  TL2CHICoupledL2_xs u_i (.clock(clk), .reset(rst), .auto_mmioBridge_mmio_in_a_ready(i_auto_mmioBridge_mmio_in_a_ready), .auto_mmioBridge_mmio_in_a_valid(auto_mmioBridge_mmio_in_a_valid), .auto_mmioBridge_mmio_in_a_bits_opcode(auto_mmioBridge_mmio_in_a_bits_opcode), .auto_mmioBridge_mmio_in_a_bits_param(auto_mmioBridge_mmio_in_a_bits_param), .auto_mmioBridge_mmio_in_a_bits_size(auto_mmioBridge_mmio_in_a_bits_size), .auto_mmioBridge_mmio_in_a_bits_source(auto_mmioBridge_mmio_in_a_bits_source), .auto_mmioBridge_mmio_in_a_bits_address(auto_mmioBridge_mmio_in_a_bits_address), .auto_mmioBridge_mmio_in_a_bits_user_memBackType_MM(auto_mmioBridge_mmio_in_a_bits_user_memBackType_MM), .auto_mmioBridge_mmio_in_a_bits_user_memPageType_NC(auto_mmioBridge_mmio_in_a_bits_user_memPageType_NC), .auto_mmioBridge_mmio_in_a_bits_mask(auto_mmioBridge_mmio_in_a_bits_mask), .auto_mmioBridge_mmio_in_a_bits_data(auto_mmioBridge_mmio_in_a_bits_data), .auto_mmioBridge_mmio_in_a_bits_corrupt(auto_mmioBridge_mmio_in_a_bits_corrupt), .auto_mmioBridge_mmio_in_d_ready(auto_mmioBridge_mmio_in_d_ready), .auto_mmioBridge_mmio_in_d_valid(i_auto_mmioBridge_mmio_in_d_valid), .auto_mmioBridge_mmio_in_d_bits_opcode(i_auto_mmioBridge_mmio_in_d_bits_opcode), .auto_mmioBridge_mmio_in_d_bits_param(i_auto_mmioBridge_mmio_in_d_bits_param), .auto_mmioBridge_mmio_in_d_bits_size(i_auto_mmioBridge_mmio_in_d_bits_size), .auto_mmioBridge_mmio_in_d_bits_source(i_auto_mmioBridge_mmio_in_d_bits_source), .auto_mmioBridge_mmio_in_d_bits_sink(i_auto_mmioBridge_mmio_in_d_bits_sink), .auto_mmioBridge_mmio_in_d_bits_denied(i_auto_mmioBridge_mmio_in_d_bits_denied), .auto_mmioBridge_mmio_in_d_bits_data(i_auto_mmioBridge_mmio_in_d_bits_data), .auto_mmioBridge_mmio_in_d_bits_corrupt(i_auto_mmioBridge_mmio_in_d_bits_corrupt), .auto_in_3_a_ready(i_auto_in_3_a_ready), .auto_in_3_a_valid(auto_in_3_a_valid), .auto_in_3_a_bits_opcode(auto_in_3_a_bits_opcode), .auto_in_3_a_bits_param(auto_in_3_a_bits_param), .auto_in_3_a_bits_size(auto_in_3_a_bits_size), .auto_in_3_a_bits_source(auto_in_3_a_bits_source), .auto_in_3_a_bits_address(auto_in_3_a_bits_address), .auto_in_3_a_bits_user_reqSource(auto_in_3_a_bits_user_reqSource), .auto_in_3_a_bits_user_alias(auto_in_3_a_bits_user_alias), .auto_in_3_a_bits_user_vaddr(auto_in_3_a_bits_user_vaddr), .auto_in_3_a_bits_user_needHint(auto_in_3_a_bits_user_needHint), .auto_in_3_a_bits_echo_isKeyword(auto_in_3_a_bits_echo_isKeyword), .auto_in_3_a_bits_corrupt(auto_in_3_a_bits_corrupt), .auto_in_3_b_ready(auto_in_3_b_ready), .auto_in_3_b_valid(i_auto_in_3_b_valid), .auto_in_3_b_bits_opcode(i_auto_in_3_b_bits_opcode), .auto_in_3_b_bits_param(i_auto_in_3_b_bits_param), .auto_in_3_b_bits_address(i_auto_in_3_b_bits_address), .auto_in_3_b_bits_data(i_auto_in_3_b_bits_data), .auto_in_3_c_ready(i_auto_in_3_c_ready), .auto_in_3_c_valid(auto_in_3_c_valid), .auto_in_3_c_bits_opcode(auto_in_3_c_bits_opcode), .auto_in_3_c_bits_param(auto_in_3_c_bits_param), .auto_in_3_c_bits_size(auto_in_3_c_bits_size), .auto_in_3_c_bits_source(auto_in_3_c_bits_source), .auto_in_3_c_bits_address(auto_in_3_c_bits_address), .auto_in_3_c_bits_data(auto_in_3_c_bits_data), .auto_in_3_c_bits_corrupt(auto_in_3_c_bits_corrupt), .auto_in_3_d_ready(auto_in_3_d_ready), .auto_in_3_d_valid(i_auto_in_3_d_valid), .auto_in_3_d_bits_opcode(i_auto_in_3_d_bits_opcode), .auto_in_3_d_bits_param(i_auto_in_3_d_bits_param), .auto_in_3_d_bits_source(i_auto_in_3_d_bits_source), .auto_in_3_d_bits_sink(i_auto_in_3_d_bits_sink), .auto_in_3_d_bits_denied(i_auto_in_3_d_bits_denied), .auto_in_3_d_bits_echo_isKeyword(i_auto_in_3_d_bits_echo_isKeyword), .auto_in_3_d_bits_data(i_auto_in_3_d_bits_data), .auto_in_3_d_bits_corrupt(i_auto_in_3_d_bits_corrupt), .auto_in_3_e_valid(auto_in_3_e_valid), .auto_in_3_e_bits_sink(auto_in_3_e_bits_sink), .auto_in_2_a_ready(i_auto_in_2_a_ready), .auto_in_2_a_valid(auto_in_2_a_valid), .auto_in_2_a_bits_opcode(auto_in_2_a_bits_opcode), .auto_in_2_a_bits_param(auto_in_2_a_bits_param), .auto_in_2_a_bits_size(auto_in_2_a_bits_size), .auto_in_2_a_bits_source(auto_in_2_a_bits_source), .auto_in_2_a_bits_address(auto_in_2_a_bits_address), .auto_in_2_a_bits_user_reqSource(auto_in_2_a_bits_user_reqSource), .auto_in_2_a_bits_user_alias(auto_in_2_a_bits_user_alias), .auto_in_2_a_bits_user_vaddr(auto_in_2_a_bits_user_vaddr), .auto_in_2_a_bits_user_needHint(auto_in_2_a_bits_user_needHint), .auto_in_2_a_bits_echo_isKeyword(auto_in_2_a_bits_echo_isKeyword), .auto_in_2_a_bits_corrupt(auto_in_2_a_bits_corrupt), .auto_in_2_b_ready(auto_in_2_b_ready), .auto_in_2_b_valid(i_auto_in_2_b_valid), .auto_in_2_b_bits_opcode(i_auto_in_2_b_bits_opcode), .auto_in_2_b_bits_param(i_auto_in_2_b_bits_param), .auto_in_2_b_bits_address(i_auto_in_2_b_bits_address), .auto_in_2_b_bits_data(i_auto_in_2_b_bits_data), .auto_in_2_c_ready(i_auto_in_2_c_ready), .auto_in_2_c_valid(auto_in_2_c_valid), .auto_in_2_c_bits_opcode(auto_in_2_c_bits_opcode), .auto_in_2_c_bits_param(auto_in_2_c_bits_param), .auto_in_2_c_bits_size(auto_in_2_c_bits_size), .auto_in_2_c_bits_source(auto_in_2_c_bits_source), .auto_in_2_c_bits_address(auto_in_2_c_bits_address), .auto_in_2_c_bits_data(auto_in_2_c_bits_data), .auto_in_2_c_bits_corrupt(auto_in_2_c_bits_corrupt), .auto_in_2_d_ready(auto_in_2_d_ready), .auto_in_2_d_valid(i_auto_in_2_d_valid), .auto_in_2_d_bits_opcode(i_auto_in_2_d_bits_opcode), .auto_in_2_d_bits_param(i_auto_in_2_d_bits_param), .auto_in_2_d_bits_source(i_auto_in_2_d_bits_source), .auto_in_2_d_bits_sink(i_auto_in_2_d_bits_sink), .auto_in_2_d_bits_denied(i_auto_in_2_d_bits_denied), .auto_in_2_d_bits_echo_isKeyword(i_auto_in_2_d_bits_echo_isKeyword), .auto_in_2_d_bits_data(i_auto_in_2_d_bits_data), .auto_in_2_d_bits_corrupt(i_auto_in_2_d_bits_corrupt), .auto_in_2_e_valid(auto_in_2_e_valid), .auto_in_2_e_bits_sink(auto_in_2_e_bits_sink), .auto_in_1_a_ready(i_auto_in_1_a_ready), .auto_in_1_a_valid(auto_in_1_a_valid), .auto_in_1_a_bits_opcode(auto_in_1_a_bits_opcode), .auto_in_1_a_bits_param(auto_in_1_a_bits_param), .auto_in_1_a_bits_size(auto_in_1_a_bits_size), .auto_in_1_a_bits_source(auto_in_1_a_bits_source), .auto_in_1_a_bits_address(auto_in_1_a_bits_address), .auto_in_1_a_bits_user_reqSource(auto_in_1_a_bits_user_reqSource), .auto_in_1_a_bits_user_alias(auto_in_1_a_bits_user_alias), .auto_in_1_a_bits_user_vaddr(auto_in_1_a_bits_user_vaddr), .auto_in_1_a_bits_user_needHint(auto_in_1_a_bits_user_needHint), .auto_in_1_a_bits_echo_isKeyword(auto_in_1_a_bits_echo_isKeyword), .auto_in_1_a_bits_corrupt(auto_in_1_a_bits_corrupt), .auto_in_1_b_ready(auto_in_1_b_ready), .auto_in_1_b_valid(i_auto_in_1_b_valid), .auto_in_1_b_bits_opcode(i_auto_in_1_b_bits_opcode), .auto_in_1_b_bits_param(i_auto_in_1_b_bits_param), .auto_in_1_b_bits_address(i_auto_in_1_b_bits_address), .auto_in_1_b_bits_data(i_auto_in_1_b_bits_data), .auto_in_1_c_ready(i_auto_in_1_c_ready), .auto_in_1_c_valid(auto_in_1_c_valid), .auto_in_1_c_bits_opcode(auto_in_1_c_bits_opcode), .auto_in_1_c_bits_param(auto_in_1_c_bits_param), .auto_in_1_c_bits_size(auto_in_1_c_bits_size), .auto_in_1_c_bits_source(auto_in_1_c_bits_source), .auto_in_1_c_bits_address(auto_in_1_c_bits_address), .auto_in_1_c_bits_data(auto_in_1_c_bits_data), .auto_in_1_c_bits_corrupt(auto_in_1_c_bits_corrupt), .auto_in_1_d_ready(auto_in_1_d_ready), .auto_in_1_d_valid(i_auto_in_1_d_valid), .auto_in_1_d_bits_opcode(i_auto_in_1_d_bits_opcode), .auto_in_1_d_bits_param(i_auto_in_1_d_bits_param), .auto_in_1_d_bits_source(i_auto_in_1_d_bits_source), .auto_in_1_d_bits_sink(i_auto_in_1_d_bits_sink), .auto_in_1_d_bits_denied(i_auto_in_1_d_bits_denied), .auto_in_1_d_bits_echo_isKeyword(i_auto_in_1_d_bits_echo_isKeyword), .auto_in_1_d_bits_data(i_auto_in_1_d_bits_data), .auto_in_1_d_bits_corrupt(i_auto_in_1_d_bits_corrupt), .auto_in_1_e_valid(auto_in_1_e_valid), .auto_in_1_e_bits_sink(auto_in_1_e_bits_sink), .auto_in_0_a_ready(i_auto_in_0_a_ready), .auto_in_0_a_valid(auto_in_0_a_valid), .auto_in_0_a_bits_opcode(auto_in_0_a_bits_opcode), .auto_in_0_a_bits_param(auto_in_0_a_bits_param), .auto_in_0_a_bits_size(auto_in_0_a_bits_size), .auto_in_0_a_bits_source(auto_in_0_a_bits_source), .auto_in_0_a_bits_address(auto_in_0_a_bits_address), .auto_in_0_a_bits_user_reqSource(auto_in_0_a_bits_user_reqSource), .auto_in_0_a_bits_user_alias(auto_in_0_a_bits_user_alias), .auto_in_0_a_bits_user_vaddr(auto_in_0_a_bits_user_vaddr), .auto_in_0_a_bits_user_needHint(auto_in_0_a_bits_user_needHint), .auto_in_0_a_bits_echo_isKeyword(auto_in_0_a_bits_echo_isKeyword), .auto_in_0_a_bits_corrupt(auto_in_0_a_bits_corrupt), .auto_in_0_b_ready(auto_in_0_b_ready), .auto_in_0_b_valid(i_auto_in_0_b_valid), .auto_in_0_b_bits_opcode(i_auto_in_0_b_bits_opcode), .auto_in_0_b_bits_param(i_auto_in_0_b_bits_param), .auto_in_0_b_bits_address(i_auto_in_0_b_bits_address), .auto_in_0_b_bits_data(i_auto_in_0_b_bits_data), .auto_in_0_c_ready(i_auto_in_0_c_ready), .auto_in_0_c_valid(auto_in_0_c_valid), .auto_in_0_c_bits_opcode(auto_in_0_c_bits_opcode), .auto_in_0_c_bits_param(auto_in_0_c_bits_param), .auto_in_0_c_bits_size(auto_in_0_c_bits_size), .auto_in_0_c_bits_source(auto_in_0_c_bits_source), .auto_in_0_c_bits_address(auto_in_0_c_bits_address), .auto_in_0_c_bits_data(auto_in_0_c_bits_data), .auto_in_0_c_bits_corrupt(auto_in_0_c_bits_corrupt), .auto_in_0_d_ready(auto_in_0_d_ready), .auto_in_0_d_valid(i_auto_in_0_d_valid), .auto_in_0_d_bits_opcode(i_auto_in_0_d_bits_opcode), .auto_in_0_d_bits_param(i_auto_in_0_d_bits_param), .auto_in_0_d_bits_source(i_auto_in_0_d_bits_source), .auto_in_0_d_bits_sink(i_auto_in_0_d_bits_sink), .auto_in_0_d_bits_denied(i_auto_in_0_d_bits_denied), .auto_in_0_d_bits_echo_isKeyword(i_auto_in_0_d_bits_echo_isKeyword), .auto_in_0_d_bits_data(i_auto_in_0_d_bits_data), .auto_in_0_d_bits_corrupt(i_auto_in_0_d_bits_corrupt), .auto_in_0_e_valid(auto_in_0_e_valid), .auto_in_0_e_bits_sink(auto_in_0_e_bits_sink), .auto_pf_recv_in_addr(auto_pf_recv_in_addr), .auto_pf_recv_in_pf_source(auto_pf_recv_in_pf_source), .auto_pf_recv_in_addr_valid(auto_pf_recv_in_addr_valid), .io_pfCtrlFromCore_l2_pf_master_en(io_pfCtrlFromCore_l2_pf_master_en), .io_pfCtrlFromCore_l2_pf_recv_en(io_pfCtrlFromCore_l2_pf_recv_en), .io_pfCtrlFromCore_l2_pbop_en(io_pfCtrlFromCore_l2_pbop_en), .io_pfCtrlFromCore_l2_vbop_en(io_pfCtrlFromCore_l2_vbop_en), .io_l2_hint_valid(i_io_l2_hint_valid), .io_l2_hint_bits_sourceId(i_io_l2_hint_bits_sourceId), .io_l2_hint_bits_isKeyword(i_io_l2_hint_bits_isKeyword), .io_l2_tlb_req_req_valid(i_io_l2_tlb_req_req_valid), .io_l2_tlb_req_req_bits_vaddr(i_io_l2_tlb_req_req_bits_vaddr), .io_l2_tlb_req_req_bits_cmd(i_io_l2_tlb_req_req_bits_cmd), .io_l2_tlb_req_req_bits_kill(i_io_l2_tlb_req_req_bits_kill), .io_l2_tlb_req_req_bits_no_translate(i_io_l2_tlb_req_req_bits_no_translate), .io_l2_tlb_req_resp_valid(io_l2_tlb_req_resp_valid), .io_l2_tlb_req_resp_bits_paddr_0(io_l2_tlb_req_resp_bits_paddr_0), .io_l2_tlb_req_resp_bits_pbmt(io_l2_tlb_req_resp_bits_pbmt), .io_l2_tlb_req_resp_bits_miss(io_l2_tlb_req_resp_bits_miss), .io_l2_tlb_req_resp_bits_excp_0_gpf_ld(io_l2_tlb_req_resp_bits_excp_0_gpf_ld), .io_l2_tlb_req_resp_bits_excp_0_pf_ld(io_l2_tlb_req_resp_bits_excp_0_pf_ld), .io_l2_tlb_req_resp_bits_excp_0_af_ld(io_l2_tlb_req_resp_bits_excp_0_af_ld), .io_l2_tlb_req_pmp_resp_ld(io_l2_tlb_req_pmp_resp_ld), .io_l2_tlb_req_pmp_resp_mmio(io_l2_tlb_req_pmp_resp_mmio), .io_debugTopDown_robHeadPaddr_valid(io_debugTopDown_robHeadPaddr_valid), .io_debugTopDown_robHeadPaddr_bits(io_debugTopDown_robHeadPaddr_bits), .io_debugTopDown_l2MissMatch(i_io_debugTopDown_l2MissMatch), .io_l2Miss(i_io_l2Miss), .io_error_valid(i_io_error_valid), .io_error_address(i_io_error_address), .io_dft_ram_hold(io_dft_ram_hold), .io_dft_ram_bypass(io_dft_ram_bypass), .io_dft_ram_bp_clken(io_dft_ram_bp_clken), .io_dft_ram_aux_clk(io_dft_ram_aux_clk), .io_dft_ram_aux_ckbp(io_dft_ram_aux_ckbp), .io_dft_ram_mcp_hold(io_dft_ram_mcp_hold), .io_dft_cgen(io_dft_cgen), .io_perf_1_value(i_io_perf_1_value), .io_perf_2_value(i_io_perf_2_value), .io_perf_3_value(i_io_perf_3_value), .io_perf_4_value(i_io_perf_4_value), .io_perf_5_value(i_io_perf_5_value), .io_perf_6_value(i_io_perf_6_value), .io_perf_7_value(i_io_perf_7_value), .io_perf_8_value(i_io_perf_8_value), .io_perf_9_value(i_io_perf_9_value), .io_perf_10_value(i_io_perf_10_value), .io_perf_11_value(i_io_perf_11_value), .io_perf_12_value(i_io_perf_12_value), .io_perf_13_value(i_io_perf_13_value), .io_perf_14_value(i_io_perf_14_value), .io_perf_15_value(i_io_perf_15_value), .io_perf_16_value(i_io_perf_16_value), .io_perf_17_value(i_io_perf_17_value), .io_perf_18_value(i_io_perf_18_value), .io_perf_19_value(i_io_perf_19_value), .io_perf_20_value(i_io_perf_20_value), .io_perf_21_value(i_io_perf_21_value), .io_perf_22_value(i_io_perf_22_value), .io_perf_23_value(i_io_perf_23_value), .io_perf_24_value(i_io_perf_24_value), .io_perf_25_value(i_io_perf_25_value), .io_perf_26_value(i_io_perf_26_value), .io_perf_27_value(i_io_perf_27_value), .io_perf_28_value(i_io_perf_28_value), .io_perf_29_value(i_io_perf_29_value), .io_perf_30_value(i_io_perf_30_value), .io_perf_31_value(i_io_perf_31_value), .io_perf_32_value(i_io_perf_32_value), .io_perf_33_value(i_io_perf_33_value), .io_perf_34_value(i_io_perf_34_value), .io_perf_35_value(i_io_perf_35_value), .io_perf_36_value(i_io_perf_36_value), .io_perf_37_value(i_io_perf_37_value), .io_perf_38_value(i_io_perf_38_value), .io_perf_39_value(i_io_perf_39_value), .io_perf_40_value(i_io_perf_40_value), .io_perf_41_value(i_io_perf_41_value), .io_perf_42_value(i_io_perf_42_value), .io_perf_43_value(i_io_perf_43_value), .io_perf_44_value(i_io_perf_44_value), .io_perf_45_value(i_io_perf_45_value), .io_perf_46_value(i_io_perf_46_value), .io_perf_47_value(i_io_perf_47_value), .io_perf_48_value(i_io_perf_48_value), .io_chi_txsactive(i_io_chi_txsactive), .io_chi_rxsactive(io_chi_rxsactive), .io_chi_syscoreq(i_io_chi_syscoreq), .io_chi_syscoack(io_chi_syscoack), .io_chi_tx_linkactivereq(i_io_chi_tx_linkactivereq), .io_chi_tx_linkactiveack(io_chi_tx_linkactiveack), .io_chi_tx_req_flitpend(i_io_chi_tx_req_flitpend), .io_chi_tx_req_flitv(i_io_chi_tx_req_flitv), .io_chi_tx_req_flit(i_io_chi_tx_req_flit), .io_chi_tx_req_lcrdv(io_chi_tx_req_lcrdv), .io_chi_tx_rsp_flitpend(i_io_chi_tx_rsp_flitpend), .io_chi_tx_rsp_flitv(i_io_chi_tx_rsp_flitv), .io_chi_tx_rsp_flit(i_io_chi_tx_rsp_flit), .io_chi_tx_rsp_lcrdv(io_chi_tx_rsp_lcrdv), .io_chi_tx_dat_flitpend(i_io_chi_tx_dat_flitpend), .io_chi_tx_dat_flitv(i_io_chi_tx_dat_flitv), .io_chi_tx_dat_flit(i_io_chi_tx_dat_flit), .io_chi_tx_dat_lcrdv(io_chi_tx_dat_lcrdv), .io_chi_rx_linkactivereq(io_chi_rx_linkactivereq), .io_chi_rx_linkactiveack(i_io_chi_rx_linkactiveack), .io_chi_rx_rsp_flitpend(io_chi_rx_rsp_flitpend), .io_chi_rx_rsp_flitv(io_chi_rx_rsp_flitv), .io_chi_rx_rsp_flit(io_chi_rx_rsp_flit), .io_chi_rx_rsp_lcrdv(i_io_chi_rx_rsp_lcrdv), .io_chi_rx_dat_flitpend(io_chi_rx_dat_flitpend), .io_chi_rx_dat_flitv(io_chi_rx_dat_flitv), .io_chi_rx_dat_flit(io_chi_rx_dat_flit), .io_chi_rx_dat_lcrdv(i_io_chi_rx_dat_lcrdv), .io_chi_rx_snp_flitpend(io_chi_rx_snp_flitpend), .io_chi_rx_snp_flitv(io_chi_rx_snp_flitv), .io_chi_rx_snp_flit(io_chi_rx_snp_flit), .io_chi_rx_snp_lcrdv(i_io_chi_rx_snp_lcrdv), .io_nodeID(io_nodeID));

  bit reported [0:149];
  int distinct_div = 0;

  always @(negedge clk) begin
    if (rst) begin
      auto_mmioBridge_mmio_in_a_valid <= 1'b0;
      auto_mmioBridge_mmio_in_d_ready <= 1'b0;
      auto_in_3_a_valid <= 1'b0;
      auto_in_3_b_ready <= 1'b0;
      auto_in_3_c_valid <= 1'b0;
      auto_in_3_d_ready <= 1'b0;
      auto_in_3_e_valid <= 1'b0;
      auto_in_2_a_valid <= 1'b0;
      auto_in_2_b_ready <= 1'b0;
      auto_in_2_c_valid <= 1'b0;
      auto_in_2_d_ready <= 1'b0;
      auto_in_2_e_valid <= 1'b0;
      auto_in_1_a_valid <= 1'b0;
      auto_in_1_b_ready <= 1'b0;
      auto_in_1_c_valid <= 1'b0;
      auto_in_1_d_ready <= 1'b0;
      auto_in_1_e_valid <= 1'b0;
      auto_in_0_a_valid <= 1'b0;
      auto_in_0_b_ready <= 1'b0;
      auto_in_0_c_valid <= 1'b0;
      auto_in_0_d_ready <= 1'b0;
      auto_in_0_e_valid <= 1'b0;
      auto_pf_recv_in_addr_valid <= 1'b0;
      io_l2_tlb_req_resp_valid <= 1'b0;
      io_debugTopDown_robHeadPaddr_valid <= 1'b0;
      io_chi_tx_req_lcrdv <= 1'b0;
      io_chi_tx_rsp_lcrdv <= 1'b0;
      io_chi_tx_dat_lcrdv <= 1'b0;
      io_chi_rx_rsp_flitpend <= 1'b0;
      io_chi_rx_rsp_flitv <= 1'b0;
      io_chi_rx_dat_flitpend <= 1'b0;
      io_chi_rx_dat_flitv <= 1'b0;
      io_chi_rx_snp_flitpend <= 1'b0;
      io_chi_rx_snp_flitv <= 1'b0;
    end else begin
      auto_mmioBridge_mmio_in_a_valid <= $urandom_range(0,1);
      auto_mmioBridge_mmio_in_a_bits_opcode <= 4'($urandom);
      auto_mmioBridge_mmio_in_a_bits_param <= 3'($urandom);
      auto_mmioBridge_mmio_in_a_bits_size <= 2'($urandom);
      auto_mmioBridge_mmio_in_a_bits_source <= 3'($urandom);
      auto_mmioBridge_mmio_in_a_bits_address <= {$urandom(), $urandom()};
      auto_mmioBridge_mmio_in_a_bits_user_memBackType_MM <= $urandom_range(0,1);
      auto_mmioBridge_mmio_in_a_bits_user_memPageType_NC <= $urandom_range(0,1);
      auto_mmioBridge_mmio_in_a_bits_mask <= 8'($urandom);
      auto_mmioBridge_mmio_in_a_bits_data <= {$urandom(), $urandom()};
      auto_mmioBridge_mmio_in_a_bits_corrupt <= $urandom_range(0,1);
      auto_mmioBridge_mmio_in_d_ready <= $urandom_range(0,1);
      auto_in_3_a_valid <= $urandom_range(0,1);
      auto_in_3_a_bits_opcode <= 4'($urandom);
      auto_in_3_a_bits_param <= 3'($urandom);
      auto_in_3_a_bits_size <= 3'($urandom);
      auto_in_3_a_bits_source <= 7'($urandom);
      auto_in_3_a_bits_address <= {$urandom(), $urandom()};
      auto_in_3_a_bits_user_reqSource <= 5'($urandom);
      auto_in_3_a_bits_user_alias <= 2'($urandom);
      auto_in_3_a_bits_user_vaddr <= {$urandom(), $urandom()};
      auto_in_3_a_bits_user_needHint <= $urandom_range(0,1);
      auto_in_3_a_bits_echo_isKeyword <= $urandom_range(0,1);
      auto_in_3_a_bits_corrupt <= $urandom_range(0,1);
      auto_in_3_b_ready <= $urandom_range(0,1);
      auto_in_3_c_valid <= $urandom_range(0,1);
      auto_in_3_c_bits_opcode <= 3'($urandom);
      auto_in_3_c_bits_param <= 3'($urandom);
      auto_in_3_c_bits_size <= 3'($urandom);
      auto_in_3_c_bits_source <= 7'($urandom);
      auto_in_3_c_bits_address <= {$urandom(), $urandom()};
      auto_in_3_c_bits_data <= {$urandom(), $urandom(), $urandom(), $urandom(), $urandom(), $urandom(), $urandom(), $urandom()};
      auto_in_3_c_bits_corrupt <= $urandom_range(0,1);
      auto_in_3_d_ready <= $urandom_range(0,1);
      auto_in_3_e_valid <= $urandom_range(0,1);
      auto_in_3_e_bits_sink <= 8'($urandom);
      auto_in_2_a_valid <= $urandom_range(0,1);
      auto_in_2_a_bits_opcode <= 4'($urandom);
      auto_in_2_a_bits_param <= 3'($urandom);
      auto_in_2_a_bits_size <= 3'($urandom);
      auto_in_2_a_bits_source <= 7'($urandom);
      auto_in_2_a_bits_address <= {$urandom(), $urandom()};
      auto_in_2_a_bits_user_reqSource <= 5'($urandom);
      auto_in_2_a_bits_user_alias <= 2'($urandom);
      auto_in_2_a_bits_user_vaddr <= {$urandom(), $urandom()};
      auto_in_2_a_bits_user_needHint <= $urandom_range(0,1);
      auto_in_2_a_bits_echo_isKeyword <= $urandom_range(0,1);
      auto_in_2_a_bits_corrupt <= $urandom_range(0,1);
      auto_in_2_b_ready <= $urandom_range(0,1);
      auto_in_2_c_valid <= $urandom_range(0,1);
      auto_in_2_c_bits_opcode <= 3'($urandom);
      auto_in_2_c_bits_param <= 3'($urandom);
      auto_in_2_c_bits_size <= 3'($urandom);
      auto_in_2_c_bits_source <= 7'($urandom);
      auto_in_2_c_bits_address <= {$urandom(), $urandom()};
      auto_in_2_c_bits_data <= {$urandom(), $urandom(), $urandom(), $urandom(), $urandom(), $urandom(), $urandom(), $urandom()};
      auto_in_2_c_bits_corrupt <= $urandom_range(0,1);
      auto_in_2_d_ready <= $urandom_range(0,1);
      auto_in_2_e_valid <= $urandom_range(0,1);
      auto_in_2_e_bits_sink <= 8'($urandom);
      auto_in_1_a_valid <= $urandom_range(0,1);
      auto_in_1_a_bits_opcode <= 4'($urandom);
      auto_in_1_a_bits_param <= 3'($urandom);
      auto_in_1_a_bits_size <= 3'($urandom);
      auto_in_1_a_bits_source <= 7'($urandom);
      auto_in_1_a_bits_address <= {$urandom(), $urandom()};
      auto_in_1_a_bits_user_reqSource <= 5'($urandom);
      auto_in_1_a_bits_user_alias <= 2'($urandom);
      auto_in_1_a_bits_user_vaddr <= {$urandom(), $urandom()};
      auto_in_1_a_bits_user_needHint <= $urandom_range(0,1);
      auto_in_1_a_bits_echo_isKeyword <= $urandom_range(0,1);
      auto_in_1_a_bits_corrupt <= $urandom_range(0,1);
      auto_in_1_b_ready <= $urandom_range(0,1);
      auto_in_1_c_valid <= $urandom_range(0,1);
      auto_in_1_c_bits_opcode <= 3'($urandom);
      auto_in_1_c_bits_param <= 3'($urandom);
      auto_in_1_c_bits_size <= 3'($urandom);
      auto_in_1_c_bits_source <= 7'($urandom);
      auto_in_1_c_bits_address <= {$urandom(), $urandom()};
      auto_in_1_c_bits_data <= {$urandom(), $urandom(), $urandom(), $urandom(), $urandom(), $urandom(), $urandom(), $urandom()};
      auto_in_1_c_bits_corrupt <= $urandom_range(0,1);
      auto_in_1_d_ready <= $urandom_range(0,1);
      auto_in_1_e_valid <= $urandom_range(0,1);
      auto_in_1_e_bits_sink <= 8'($urandom);
      auto_in_0_a_valid <= $urandom_range(0,1);
      auto_in_0_a_bits_opcode <= 4'($urandom);
      auto_in_0_a_bits_param <= 3'($urandom);
      auto_in_0_a_bits_size <= 3'($urandom);
      auto_in_0_a_bits_source <= 7'($urandom);
      auto_in_0_a_bits_address <= {$urandom(), $urandom()};
      auto_in_0_a_bits_user_reqSource <= 5'($urandom);
      auto_in_0_a_bits_user_alias <= 2'($urandom);
      auto_in_0_a_bits_user_vaddr <= {$urandom(), $urandom()};
      auto_in_0_a_bits_user_needHint <= $urandom_range(0,1);
      auto_in_0_a_bits_echo_isKeyword <= $urandom_range(0,1);
      auto_in_0_a_bits_corrupt <= $urandom_range(0,1);
      auto_in_0_b_ready <= $urandom_range(0,1);
      auto_in_0_c_valid <= $urandom_range(0,1);
      auto_in_0_c_bits_opcode <= 3'($urandom);
      auto_in_0_c_bits_param <= 3'($urandom);
      auto_in_0_c_bits_size <= 3'($urandom);
      auto_in_0_c_bits_source <= 7'($urandom);
      auto_in_0_c_bits_address <= {$urandom(), $urandom()};
      auto_in_0_c_bits_data <= {$urandom(), $urandom(), $urandom(), $urandom(), $urandom(), $urandom(), $urandom(), $urandom()};
      auto_in_0_c_bits_corrupt <= $urandom_range(0,1);
      auto_in_0_d_ready <= $urandom_range(0,1);
      auto_in_0_e_valid <= $urandom_range(0,1);
      auto_in_0_e_bits_sink <= 8'($urandom);
      auto_pf_recv_in_addr <= {$urandom(), $urandom()};
      auto_pf_recv_in_pf_source <= 5'($urandom);
      auto_pf_recv_in_addr_valid <= $urandom_range(0,1);
      io_pfCtrlFromCore_l2_pf_master_en <= $urandom_range(0,1);
      io_pfCtrlFromCore_l2_pf_recv_en <= $urandom_range(0,1);
      io_pfCtrlFromCore_l2_pbop_en <= $urandom_range(0,1);
      io_pfCtrlFromCore_l2_vbop_en <= $urandom_range(0,1);
      io_l2_tlb_req_resp_valid <= $urandom_range(0,1);
      io_l2_tlb_req_resp_bits_paddr_0 <= {$urandom(), $urandom()};
      io_l2_tlb_req_resp_bits_pbmt <= 2'($urandom);
      io_l2_tlb_req_resp_bits_miss <= $urandom_range(0,1);
      io_l2_tlb_req_resp_bits_excp_0_gpf_ld <= $urandom_range(0,1);
      io_l2_tlb_req_resp_bits_excp_0_pf_ld <= $urandom_range(0,1);
      io_l2_tlb_req_resp_bits_excp_0_af_ld <= $urandom_range(0,1);
      io_l2_tlb_req_pmp_resp_ld <= $urandom_range(0,1);
      io_l2_tlb_req_pmp_resp_mmio <= $urandom_range(0,1);
      io_debugTopDown_robHeadPaddr_valid <= $urandom_range(0,1);
      io_debugTopDown_robHeadPaddr_bits <= {$urandom(), $urandom()};
      io_dft_ram_hold <= $urandom_range(0,1);
      io_dft_ram_bypass <= $urandom_range(0,1);
      io_dft_ram_bp_clken <= $urandom_range(0,1);
      io_dft_ram_aux_clk <= $urandom_range(0,1);
      io_dft_ram_aux_ckbp <= $urandom_range(0,1);
      io_dft_ram_mcp_hold <= $urandom_range(0,1);
      io_dft_cgen <= $urandom_range(0,1);
      io_chi_rxsactive <= $urandom_range(0,1);
      io_chi_syscoack <= $urandom_range(0,1);
      io_chi_tx_linkactiveack <= $urandom_range(0,1);
      io_chi_tx_req_lcrdv <= $urandom_range(0,1);
      io_chi_tx_rsp_lcrdv <= $urandom_range(0,1);
      io_chi_tx_dat_lcrdv <= $urandom_range(0,1);
      io_chi_rx_linkactivereq <= $urandom_range(0,1);
      io_chi_rx_rsp_flitpend <= $urandom_range(0,1);
      io_chi_rx_rsp_flitv <= $urandom_range(0,1);
      io_chi_rx_rsp_flit <= {$urandom(), $urandom(), $urandom()};
      io_chi_rx_dat_flitpend <= $urandom_range(0,1);
      io_chi_rx_dat_flitv <= $urandom_range(0,1);
      io_chi_rx_dat_flit <= {$urandom(), $urandom(), $urandom(), $urandom(), $urandom(), $urandom(), $urandom(), $urandom(), $urandom(), $urandom(), $urandom(), $urandom(), $urandom(), $urandom()};
      io_chi_rx_snp_flitpend <= $urandom_range(0,1);
      io_chi_rx_snp_flitv <= $urandom_range(0,1);
      io_chi_rx_snp_flit <= {$urandom(), $urandom(), $urandom(), $urandom()};
      io_nodeID <= 11'($urandom);
    end
  end

  always @(negedge clk) if (!rst) begin
    #4; checks++;
    if (!$isunknown(g_auto_mmioBridge_mmio_in_a_ready) && g_auto_mmioBridge_mmio_in_a_ready !== i_auto_mmioBridge_mmio_in_a_ready) begin errors++;
      if(!reported[0]) begin reported[0]=1; distinct_div++;
        $display("[DIV %0t] auto_mmioBridge_mmio_in_a_ready g=%h i=%h", $time, g_auto_mmioBridge_mmio_in_a_ready, i_auto_mmioBridge_mmio_in_a_ready); end end
    if (!$isunknown(g_auto_mmioBridge_mmio_in_d_valid) && g_auto_mmioBridge_mmio_in_d_valid !== i_auto_mmioBridge_mmio_in_d_valid) begin errors++;
      if(!reported[1]) begin reported[1]=1; distinct_div++;
        $display("[DIV %0t] auto_mmioBridge_mmio_in_d_valid g=%h i=%h", $time, g_auto_mmioBridge_mmio_in_d_valid, i_auto_mmioBridge_mmio_in_d_valid); end end
    if (!$isunknown(g_auto_mmioBridge_mmio_in_d_bits_opcode) && g_auto_mmioBridge_mmio_in_d_bits_opcode !== i_auto_mmioBridge_mmio_in_d_bits_opcode) begin errors++;
      if(!reported[2]) begin reported[2]=1; distinct_div++;
        $display("[DIV %0t] auto_mmioBridge_mmio_in_d_bits_opcode g=%h i=%h", $time, g_auto_mmioBridge_mmio_in_d_bits_opcode, i_auto_mmioBridge_mmio_in_d_bits_opcode); end end
    if (!$isunknown(g_auto_mmioBridge_mmio_in_d_bits_param) && g_auto_mmioBridge_mmio_in_d_bits_param !== i_auto_mmioBridge_mmio_in_d_bits_param) begin errors++;
      if(!reported[3]) begin reported[3]=1; distinct_div++;
        $display("[DIV %0t] auto_mmioBridge_mmio_in_d_bits_param g=%h i=%h", $time, g_auto_mmioBridge_mmio_in_d_bits_param, i_auto_mmioBridge_mmio_in_d_bits_param); end end
    if (!$isunknown(g_auto_mmioBridge_mmio_in_d_bits_size) && g_auto_mmioBridge_mmio_in_d_bits_size !== i_auto_mmioBridge_mmio_in_d_bits_size) begin errors++;
      if(!reported[4]) begin reported[4]=1; distinct_div++;
        $display("[DIV %0t] auto_mmioBridge_mmio_in_d_bits_size g=%h i=%h", $time, g_auto_mmioBridge_mmio_in_d_bits_size, i_auto_mmioBridge_mmio_in_d_bits_size); end end
    if (!$isunknown(g_auto_mmioBridge_mmio_in_d_bits_source) && g_auto_mmioBridge_mmio_in_d_bits_source !== i_auto_mmioBridge_mmio_in_d_bits_source) begin errors++;
      if(!reported[5]) begin reported[5]=1; distinct_div++;
        $display("[DIV %0t] auto_mmioBridge_mmio_in_d_bits_source g=%h i=%h", $time, g_auto_mmioBridge_mmio_in_d_bits_source, i_auto_mmioBridge_mmio_in_d_bits_source); end end
    if (!$isunknown(g_auto_mmioBridge_mmio_in_d_bits_sink) && g_auto_mmioBridge_mmio_in_d_bits_sink !== i_auto_mmioBridge_mmio_in_d_bits_sink) begin errors++;
      if(!reported[6]) begin reported[6]=1; distinct_div++;
        $display("[DIV %0t] auto_mmioBridge_mmio_in_d_bits_sink g=%h i=%h", $time, g_auto_mmioBridge_mmio_in_d_bits_sink, i_auto_mmioBridge_mmio_in_d_bits_sink); end end
    if (!$isunknown(g_auto_mmioBridge_mmio_in_d_bits_denied) && g_auto_mmioBridge_mmio_in_d_bits_denied !== i_auto_mmioBridge_mmio_in_d_bits_denied) begin errors++;
      if(!reported[7]) begin reported[7]=1; distinct_div++;
        $display("[DIV %0t] auto_mmioBridge_mmio_in_d_bits_denied g=%h i=%h", $time, g_auto_mmioBridge_mmio_in_d_bits_denied, i_auto_mmioBridge_mmio_in_d_bits_denied); end end
    if (!$isunknown(g_auto_mmioBridge_mmio_in_d_bits_data) && g_auto_mmioBridge_mmio_in_d_bits_data !== i_auto_mmioBridge_mmio_in_d_bits_data) begin errors++;
      if(!reported[8]) begin reported[8]=1; distinct_div++;
        $display("[DIV %0t] auto_mmioBridge_mmio_in_d_bits_data g=%h i=%h", $time, g_auto_mmioBridge_mmio_in_d_bits_data, i_auto_mmioBridge_mmio_in_d_bits_data); end end
    if (!$isunknown(g_auto_mmioBridge_mmio_in_d_bits_corrupt) && g_auto_mmioBridge_mmio_in_d_bits_corrupt !== i_auto_mmioBridge_mmio_in_d_bits_corrupt) begin errors++;
      if(!reported[9]) begin reported[9]=1; distinct_div++;
        $display("[DIV %0t] auto_mmioBridge_mmio_in_d_bits_corrupt g=%h i=%h", $time, g_auto_mmioBridge_mmio_in_d_bits_corrupt, i_auto_mmioBridge_mmio_in_d_bits_corrupt); end end
    if (!$isunknown(g_auto_in_3_a_ready) && g_auto_in_3_a_ready !== i_auto_in_3_a_ready) begin errors++;
      if(!reported[10]) begin reported[10]=1; distinct_div++;
        $display("[DIV %0t] auto_in_3_a_ready g=%h i=%h", $time, g_auto_in_3_a_ready, i_auto_in_3_a_ready); end end
    if (!$isunknown(g_auto_in_3_b_valid) && g_auto_in_3_b_valid !== i_auto_in_3_b_valid) begin errors++;
      if(!reported[11]) begin reported[11]=1; distinct_div++;
        $display("[DIV %0t] auto_in_3_b_valid g=%h i=%h", $time, g_auto_in_3_b_valid, i_auto_in_3_b_valid); end end
    if (!$isunknown(g_auto_in_3_b_bits_opcode) && g_auto_in_3_b_bits_opcode !== i_auto_in_3_b_bits_opcode) begin errors++;
      if(!reported[12]) begin reported[12]=1; distinct_div++;
        $display("[DIV %0t] auto_in_3_b_bits_opcode g=%h i=%h", $time, g_auto_in_3_b_bits_opcode, i_auto_in_3_b_bits_opcode); end end
    if (!$isunknown(g_auto_in_3_b_bits_param) && g_auto_in_3_b_bits_param !== i_auto_in_3_b_bits_param) begin errors++;
      if(!reported[13]) begin reported[13]=1; distinct_div++;
        $display("[DIV %0t] auto_in_3_b_bits_param g=%h i=%h", $time, g_auto_in_3_b_bits_param, i_auto_in_3_b_bits_param); end end
    if (!$isunknown(g_auto_in_3_b_bits_address) && g_auto_in_3_b_bits_address !== i_auto_in_3_b_bits_address) begin errors++;
      if(!reported[14]) begin reported[14]=1; distinct_div++;
        $display("[DIV %0t] auto_in_3_b_bits_address g=%h i=%h", $time, g_auto_in_3_b_bits_address, i_auto_in_3_b_bits_address); end end
    if (!$isunknown(g_auto_in_3_b_bits_data) && g_auto_in_3_b_bits_data !== i_auto_in_3_b_bits_data) begin errors++;
      if(!reported[15]) begin reported[15]=1; distinct_div++;
        $display("[DIV %0t] auto_in_3_b_bits_data g=%h i=%h", $time, g_auto_in_3_b_bits_data, i_auto_in_3_b_bits_data); end end
    if (!$isunknown(g_auto_in_3_c_ready) && g_auto_in_3_c_ready !== i_auto_in_3_c_ready) begin errors++;
      if(!reported[16]) begin reported[16]=1; distinct_div++;
        $display("[DIV %0t] auto_in_3_c_ready g=%h i=%h", $time, g_auto_in_3_c_ready, i_auto_in_3_c_ready); end end
    if (!$isunknown(g_auto_in_3_d_valid) && g_auto_in_3_d_valid !== i_auto_in_3_d_valid) begin errors++;
      if(!reported[17]) begin reported[17]=1; distinct_div++;
        $display("[DIV %0t] auto_in_3_d_valid g=%h i=%h", $time, g_auto_in_3_d_valid, i_auto_in_3_d_valid); end end
    if (!$isunknown(g_auto_in_3_d_bits_opcode) && g_auto_in_3_d_bits_opcode !== i_auto_in_3_d_bits_opcode) begin errors++;
      if(!reported[18]) begin reported[18]=1; distinct_div++;
        $display("[DIV %0t] auto_in_3_d_bits_opcode g=%h i=%h", $time, g_auto_in_3_d_bits_opcode, i_auto_in_3_d_bits_opcode); end end
    if (!$isunknown(g_auto_in_3_d_bits_param) && g_auto_in_3_d_bits_param !== i_auto_in_3_d_bits_param) begin errors++;
      if(!reported[19]) begin reported[19]=1; distinct_div++;
        $display("[DIV %0t] auto_in_3_d_bits_param g=%h i=%h", $time, g_auto_in_3_d_bits_param, i_auto_in_3_d_bits_param); end end
    if (!$isunknown(g_auto_in_3_d_bits_source) && g_auto_in_3_d_bits_source !== i_auto_in_3_d_bits_source) begin errors++;
      if(!reported[20]) begin reported[20]=1; distinct_div++;
        $display("[DIV %0t] auto_in_3_d_bits_source g=%h i=%h", $time, g_auto_in_3_d_bits_source, i_auto_in_3_d_bits_source); end end
    if (!$isunknown(g_auto_in_3_d_bits_sink) && g_auto_in_3_d_bits_sink !== i_auto_in_3_d_bits_sink) begin errors++;
      if(!reported[21]) begin reported[21]=1; distinct_div++;
        $display("[DIV %0t] auto_in_3_d_bits_sink g=%h i=%h", $time, g_auto_in_3_d_bits_sink, i_auto_in_3_d_bits_sink); end end
    if (!$isunknown(g_auto_in_3_d_bits_denied) && g_auto_in_3_d_bits_denied !== i_auto_in_3_d_bits_denied) begin errors++;
      if(!reported[22]) begin reported[22]=1; distinct_div++;
        $display("[DIV %0t] auto_in_3_d_bits_denied g=%h i=%h", $time, g_auto_in_3_d_bits_denied, i_auto_in_3_d_bits_denied); end end
    if (!$isunknown(g_auto_in_3_d_bits_echo_isKeyword) && g_auto_in_3_d_bits_echo_isKeyword !== i_auto_in_3_d_bits_echo_isKeyword) begin errors++;
      if(!reported[23]) begin reported[23]=1; distinct_div++;
        $display("[DIV %0t] auto_in_3_d_bits_echo_isKeyword g=%h i=%h", $time, g_auto_in_3_d_bits_echo_isKeyword, i_auto_in_3_d_bits_echo_isKeyword); end end
    if (!$isunknown(g_auto_in_3_d_bits_data) && g_auto_in_3_d_bits_data !== i_auto_in_3_d_bits_data) begin errors++;
      if(!reported[24]) begin reported[24]=1; distinct_div++;
        $display("[DIV %0t] auto_in_3_d_bits_data g=%h i=%h", $time, g_auto_in_3_d_bits_data, i_auto_in_3_d_bits_data); end end
    if (!$isunknown(g_auto_in_3_d_bits_corrupt) && g_auto_in_3_d_bits_corrupt !== i_auto_in_3_d_bits_corrupt) begin errors++;
      if(!reported[25]) begin reported[25]=1; distinct_div++;
        $display("[DIV %0t] auto_in_3_d_bits_corrupt g=%h i=%h", $time, g_auto_in_3_d_bits_corrupt, i_auto_in_3_d_bits_corrupt); end end
    if (!$isunknown(g_auto_in_2_a_ready) && g_auto_in_2_a_ready !== i_auto_in_2_a_ready) begin errors++;
      if(!reported[26]) begin reported[26]=1; distinct_div++;
        $display("[DIV %0t] auto_in_2_a_ready g=%h i=%h", $time, g_auto_in_2_a_ready, i_auto_in_2_a_ready); end end
    if (!$isunknown(g_auto_in_2_b_valid) && g_auto_in_2_b_valid !== i_auto_in_2_b_valid) begin errors++;
      if(!reported[27]) begin reported[27]=1; distinct_div++;
        $display("[DIV %0t] auto_in_2_b_valid g=%h i=%h", $time, g_auto_in_2_b_valid, i_auto_in_2_b_valid); end end
    if (!$isunknown(g_auto_in_2_b_bits_opcode) && g_auto_in_2_b_bits_opcode !== i_auto_in_2_b_bits_opcode) begin errors++;
      if(!reported[28]) begin reported[28]=1; distinct_div++;
        $display("[DIV %0t] auto_in_2_b_bits_opcode g=%h i=%h", $time, g_auto_in_2_b_bits_opcode, i_auto_in_2_b_bits_opcode); end end
    if (!$isunknown(g_auto_in_2_b_bits_param) && g_auto_in_2_b_bits_param !== i_auto_in_2_b_bits_param) begin errors++;
      if(!reported[29]) begin reported[29]=1; distinct_div++;
        $display("[DIV %0t] auto_in_2_b_bits_param g=%h i=%h", $time, g_auto_in_2_b_bits_param, i_auto_in_2_b_bits_param); end end
    if (!$isunknown(g_auto_in_2_b_bits_address) && g_auto_in_2_b_bits_address !== i_auto_in_2_b_bits_address) begin errors++;
      if(!reported[30]) begin reported[30]=1; distinct_div++;
        $display("[DIV %0t] auto_in_2_b_bits_address g=%h i=%h", $time, g_auto_in_2_b_bits_address, i_auto_in_2_b_bits_address); end end
    if (!$isunknown(g_auto_in_2_b_bits_data) && g_auto_in_2_b_bits_data !== i_auto_in_2_b_bits_data) begin errors++;
      if(!reported[31]) begin reported[31]=1; distinct_div++;
        $display("[DIV %0t] auto_in_2_b_bits_data g=%h i=%h", $time, g_auto_in_2_b_bits_data, i_auto_in_2_b_bits_data); end end
    if (!$isunknown(g_auto_in_2_c_ready) && g_auto_in_2_c_ready !== i_auto_in_2_c_ready) begin errors++;
      if(!reported[32]) begin reported[32]=1; distinct_div++;
        $display("[DIV %0t] auto_in_2_c_ready g=%h i=%h", $time, g_auto_in_2_c_ready, i_auto_in_2_c_ready); end end
    if (!$isunknown(g_auto_in_2_d_valid) && g_auto_in_2_d_valid !== i_auto_in_2_d_valid) begin errors++;
      if(!reported[33]) begin reported[33]=1; distinct_div++;
        $display("[DIV %0t] auto_in_2_d_valid g=%h i=%h", $time, g_auto_in_2_d_valid, i_auto_in_2_d_valid); end end
    if (!$isunknown(g_auto_in_2_d_bits_opcode) && g_auto_in_2_d_bits_opcode !== i_auto_in_2_d_bits_opcode) begin errors++;
      if(!reported[34]) begin reported[34]=1; distinct_div++;
        $display("[DIV %0t] auto_in_2_d_bits_opcode g=%h i=%h", $time, g_auto_in_2_d_bits_opcode, i_auto_in_2_d_bits_opcode); end end
    if (!$isunknown(g_auto_in_2_d_bits_param) && g_auto_in_2_d_bits_param !== i_auto_in_2_d_bits_param) begin errors++;
      if(!reported[35]) begin reported[35]=1; distinct_div++;
        $display("[DIV %0t] auto_in_2_d_bits_param g=%h i=%h", $time, g_auto_in_2_d_bits_param, i_auto_in_2_d_bits_param); end end
    if (!$isunknown(g_auto_in_2_d_bits_source) && g_auto_in_2_d_bits_source !== i_auto_in_2_d_bits_source) begin errors++;
      if(!reported[36]) begin reported[36]=1; distinct_div++;
        $display("[DIV %0t] auto_in_2_d_bits_source g=%h i=%h", $time, g_auto_in_2_d_bits_source, i_auto_in_2_d_bits_source); end end
    if (!$isunknown(g_auto_in_2_d_bits_sink) && g_auto_in_2_d_bits_sink !== i_auto_in_2_d_bits_sink) begin errors++;
      if(!reported[37]) begin reported[37]=1; distinct_div++;
        $display("[DIV %0t] auto_in_2_d_bits_sink g=%h i=%h", $time, g_auto_in_2_d_bits_sink, i_auto_in_2_d_bits_sink); end end
    if (!$isunknown(g_auto_in_2_d_bits_denied) && g_auto_in_2_d_bits_denied !== i_auto_in_2_d_bits_denied) begin errors++;
      if(!reported[38]) begin reported[38]=1; distinct_div++;
        $display("[DIV %0t] auto_in_2_d_bits_denied g=%h i=%h", $time, g_auto_in_2_d_bits_denied, i_auto_in_2_d_bits_denied); end end
    if (!$isunknown(g_auto_in_2_d_bits_echo_isKeyword) && g_auto_in_2_d_bits_echo_isKeyword !== i_auto_in_2_d_bits_echo_isKeyword) begin errors++;
      if(!reported[39]) begin reported[39]=1; distinct_div++;
        $display("[DIV %0t] auto_in_2_d_bits_echo_isKeyword g=%h i=%h", $time, g_auto_in_2_d_bits_echo_isKeyword, i_auto_in_2_d_bits_echo_isKeyword); end end
    if (!$isunknown(g_auto_in_2_d_bits_data) && g_auto_in_2_d_bits_data !== i_auto_in_2_d_bits_data) begin errors++;
      if(!reported[40]) begin reported[40]=1; distinct_div++;
        $display("[DIV %0t] auto_in_2_d_bits_data g=%h i=%h", $time, g_auto_in_2_d_bits_data, i_auto_in_2_d_bits_data); end end
    if (!$isunknown(g_auto_in_2_d_bits_corrupt) && g_auto_in_2_d_bits_corrupt !== i_auto_in_2_d_bits_corrupt) begin errors++;
      if(!reported[41]) begin reported[41]=1; distinct_div++;
        $display("[DIV %0t] auto_in_2_d_bits_corrupt g=%h i=%h", $time, g_auto_in_2_d_bits_corrupt, i_auto_in_2_d_bits_corrupt); end end
    if (!$isunknown(g_auto_in_1_a_ready) && g_auto_in_1_a_ready !== i_auto_in_1_a_ready) begin errors++;
      if(!reported[42]) begin reported[42]=1; distinct_div++;
        $display("[DIV %0t] auto_in_1_a_ready g=%h i=%h", $time, g_auto_in_1_a_ready, i_auto_in_1_a_ready); end end
    if (!$isunknown(g_auto_in_1_b_valid) && g_auto_in_1_b_valid !== i_auto_in_1_b_valid) begin errors++;
      if(!reported[43]) begin reported[43]=1; distinct_div++;
        $display("[DIV %0t] auto_in_1_b_valid g=%h i=%h", $time, g_auto_in_1_b_valid, i_auto_in_1_b_valid); end end
    if (!$isunknown(g_auto_in_1_b_bits_opcode) && g_auto_in_1_b_bits_opcode !== i_auto_in_1_b_bits_opcode) begin errors++;
      if(!reported[44]) begin reported[44]=1; distinct_div++;
        $display("[DIV %0t] auto_in_1_b_bits_opcode g=%h i=%h", $time, g_auto_in_1_b_bits_opcode, i_auto_in_1_b_bits_opcode); end end
    if (!$isunknown(g_auto_in_1_b_bits_param) && g_auto_in_1_b_bits_param !== i_auto_in_1_b_bits_param) begin errors++;
      if(!reported[45]) begin reported[45]=1; distinct_div++;
        $display("[DIV %0t] auto_in_1_b_bits_param g=%h i=%h", $time, g_auto_in_1_b_bits_param, i_auto_in_1_b_bits_param); end end
    if (!$isunknown(g_auto_in_1_b_bits_address) && g_auto_in_1_b_bits_address !== i_auto_in_1_b_bits_address) begin errors++;
      if(!reported[46]) begin reported[46]=1; distinct_div++;
        $display("[DIV %0t] auto_in_1_b_bits_address g=%h i=%h", $time, g_auto_in_1_b_bits_address, i_auto_in_1_b_bits_address); end end
    if (!$isunknown(g_auto_in_1_b_bits_data) && g_auto_in_1_b_bits_data !== i_auto_in_1_b_bits_data) begin errors++;
      if(!reported[47]) begin reported[47]=1; distinct_div++;
        $display("[DIV %0t] auto_in_1_b_bits_data g=%h i=%h", $time, g_auto_in_1_b_bits_data, i_auto_in_1_b_bits_data); end end
    if (!$isunknown(g_auto_in_1_c_ready) && g_auto_in_1_c_ready !== i_auto_in_1_c_ready) begin errors++;
      if(!reported[48]) begin reported[48]=1; distinct_div++;
        $display("[DIV %0t] auto_in_1_c_ready g=%h i=%h", $time, g_auto_in_1_c_ready, i_auto_in_1_c_ready); end end
    if (!$isunknown(g_auto_in_1_d_valid) && g_auto_in_1_d_valid !== i_auto_in_1_d_valid) begin errors++;
      if(!reported[49]) begin reported[49]=1; distinct_div++;
        $display("[DIV %0t] auto_in_1_d_valid g=%h i=%h", $time, g_auto_in_1_d_valid, i_auto_in_1_d_valid); end end
    if (!$isunknown(g_auto_in_1_d_bits_opcode) && g_auto_in_1_d_bits_opcode !== i_auto_in_1_d_bits_opcode) begin errors++;
      if(!reported[50]) begin reported[50]=1; distinct_div++;
        $display("[DIV %0t] auto_in_1_d_bits_opcode g=%h i=%h", $time, g_auto_in_1_d_bits_opcode, i_auto_in_1_d_bits_opcode); end end
    if (!$isunknown(g_auto_in_1_d_bits_param) && g_auto_in_1_d_bits_param !== i_auto_in_1_d_bits_param) begin errors++;
      if(!reported[51]) begin reported[51]=1; distinct_div++;
        $display("[DIV %0t] auto_in_1_d_bits_param g=%h i=%h", $time, g_auto_in_1_d_bits_param, i_auto_in_1_d_bits_param); end end
    if (!$isunknown(g_auto_in_1_d_bits_source) && g_auto_in_1_d_bits_source !== i_auto_in_1_d_bits_source) begin errors++;
      if(!reported[52]) begin reported[52]=1; distinct_div++;
        $display("[DIV %0t] auto_in_1_d_bits_source g=%h i=%h", $time, g_auto_in_1_d_bits_source, i_auto_in_1_d_bits_source); end end
    if (!$isunknown(g_auto_in_1_d_bits_sink) && g_auto_in_1_d_bits_sink !== i_auto_in_1_d_bits_sink) begin errors++;
      if(!reported[53]) begin reported[53]=1; distinct_div++;
        $display("[DIV %0t] auto_in_1_d_bits_sink g=%h i=%h", $time, g_auto_in_1_d_bits_sink, i_auto_in_1_d_bits_sink); end end
    if (!$isunknown(g_auto_in_1_d_bits_denied) && g_auto_in_1_d_bits_denied !== i_auto_in_1_d_bits_denied) begin errors++;
      if(!reported[54]) begin reported[54]=1; distinct_div++;
        $display("[DIV %0t] auto_in_1_d_bits_denied g=%h i=%h", $time, g_auto_in_1_d_bits_denied, i_auto_in_1_d_bits_denied); end end
    if (!$isunknown(g_auto_in_1_d_bits_echo_isKeyword) && g_auto_in_1_d_bits_echo_isKeyword !== i_auto_in_1_d_bits_echo_isKeyword) begin errors++;
      if(!reported[55]) begin reported[55]=1; distinct_div++;
        $display("[DIV %0t] auto_in_1_d_bits_echo_isKeyword g=%h i=%h", $time, g_auto_in_1_d_bits_echo_isKeyword, i_auto_in_1_d_bits_echo_isKeyword); end end
    if (!$isunknown(g_auto_in_1_d_bits_data) && g_auto_in_1_d_bits_data !== i_auto_in_1_d_bits_data) begin errors++;
      if(!reported[56]) begin reported[56]=1; distinct_div++;
        $display("[DIV %0t] auto_in_1_d_bits_data g=%h i=%h", $time, g_auto_in_1_d_bits_data, i_auto_in_1_d_bits_data); end end
    if (!$isunknown(g_auto_in_1_d_bits_corrupt) && g_auto_in_1_d_bits_corrupt !== i_auto_in_1_d_bits_corrupt) begin errors++;
      if(!reported[57]) begin reported[57]=1; distinct_div++;
        $display("[DIV %0t] auto_in_1_d_bits_corrupt g=%h i=%h", $time, g_auto_in_1_d_bits_corrupt, i_auto_in_1_d_bits_corrupt); end end
    if (!$isunknown(g_auto_in_0_a_ready) && g_auto_in_0_a_ready !== i_auto_in_0_a_ready) begin errors++;
      if(!reported[58]) begin reported[58]=1; distinct_div++;
        $display("[DIV %0t] auto_in_0_a_ready g=%h i=%h", $time, g_auto_in_0_a_ready, i_auto_in_0_a_ready); end end
    if (!$isunknown(g_auto_in_0_b_valid) && g_auto_in_0_b_valid !== i_auto_in_0_b_valid) begin errors++;
      if(!reported[59]) begin reported[59]=1; distinct_div++;
        $display("[DIV %0t] auto_in_0_b_valid g=%h i=%h", $time, g_auto_in_0_b_valid, i_auto_in_0_b_valid); end end
    if (!$isunknown(g_auto_in_0_b_bits_opcode) && g_auto_in_0_b_bits_opcode !== i_auto_in_0_b_bits_opcode) begin errors++;
      if(!reported[60]) begin reported[60]=1; distinct_div++;
        $display("[DIV %0t] auto_in_0_b_bits_opcode g=%h i=%h", $time, g_auto_in_0_b_bits_opcode, i_auto_in_0_b_bits_opcode); end end
    if (!$isunknown(g_auto_in_0_b_bits_param) && g_auto_in_0_b_bits_param !== i_auto_in_0_b_bits_param) begin errors++;
      if(!reported[61]) begin reported[61]=1; distinct_div++;
        $display("[DIV %0t] auto_in_0_b_bits_param g=%h i=%h", $time, g_auto_in_0_b_bits_param, i_auto_in_0_b_bits_param); end end
    if (!$isunknown(g_auto_in_0_b_bits_address) && g_auto_in_0_b_bits_address !== i_auto_in_0_b_bits_address) begin errors++;
      if(!reported[62]) begin reported[62]=1; distinct_div++;
        $display("[DIV %0t] auto_in_0_b_bits_address g=%h i=%h", $time, g_auto_in_0_b_bits_address, i_auto_in_0_b_bits_address); end end
    if (!$isunknown(g_auto_in_0_b_bits_data) && g_auto_in_0_b_bits_data !== i_auto_in_0_b_bits_data) begin errors++;
      if(!reported[63]) begin reported[63]=1; distinct_div++;
        $display("[DIV %0t] auto_in_0_b_bits_data g=%h i=%h", $time, g_auto_in_0_b_bits_data, i_auto_in_0_b_bits_data); end end
    if (!$isunknown(g_auto_in_0_c_ready) && g_auto_in_0_c_ready !== i_auto_in_0_c_ready) begin errors++;
      if(!reported[64]) begin reported[64]=1; distinct_div++;
        $display("[DIV %0t] auto_in_0_c_ready g=%h i=%h", $time, g_auto_in_0_c_ready, i_auto_in_0_c_ready); end end
    if (!$isunknown(g_auto_in_0_d_valid) && g_auto_in_0_d_valid !== i_auto_in_0_d_valid) begin errors++;
      if(!reported[65]) begin reported[65]=1; distinct_div++;
        $display("[DIV %0t] auto_in_0_d_valid g=%h i=%h", $time, g_auto_in_0_d_valid, i_auto_in_0_d_valid); end end
    if (!$isunknown(g_auto_in_0_d_bits_opcode) && g_auto_in_0_d_bits_opcode !== i_auto_in_0_d_bits_opcode) begin errors++;
      if(!reported[66]) begin reported[66]=1; distinct_div++;
        $display("[DIV %0t] auto_in_0_d_bits_opcode g=%h i=%h", $time, g_auto_in_0_d_bits_opcode, i_auto_in_0_d_bits_opcode); end end
    if (!$isunknown(g_auto_in_0_d_bits_param) && g_auto_in_0_d_bits_param !== i_auto_in_0_d_bits_param) begin errors++;
      if(!reported[67]) begin reported[67]=1; distinct_div++;
        $display("[DIV %0t] auto_in_0_d_bits_param g=%h i=%h", $time, g_auto_in_0_d_bits_param, i_auto_in_0_d_bits_param); end end
    if (!$isunknown(g_auto_in_0_d_bits_source) && g_auto_in_0_d_bits_source !== i_auto_in_0_d_bits_source) begin errors++;
      if(!reported[68]) begin reported[68]=1; distinct_div++;
        $display("[DIV %0t] auto_in_0_d_bits_source g=%h i=%h", $time, g_auto_in_0_d_bits_source, i_auto_in_0_d_bits_source); end end
    if (!$isunknown(g_auto_in_0_d_bits_sink) && g_auto_in_0_d_bits_sink !== i_auto_in_0_d_bits_sink) begin errors++;
      if(!reported[69]) begin reported[69]=1; distinct_div++;
        $display("[DIV %0t] auto_in_0_d_bits_sink g=%h i=%h", $time, g_auto_in_0_d_bits_sink, i_auto_in_0_d_bits_sink); end end
    if (!$isunknown(g_auto_in_0_d_bits_denied) && g_auto_in_0_d_bits_denied !== i_auto_in_0_d_bits_denied) begin errors++;
      if(!reported[70]) begin reported[70]=1; distinct_div++;
        $display("[DIV %0t] auto_in_0_d_bits_denied g=%h i=%h", $time, g_auto_in_0_d_bits_denied, i_auto_in_0_d_bits_denied); end end
    if (!$isunknown(g_auto_in_0_d_bits_echo_isKeyword) && g_auto_in_0_d_bits_echo_isKeyword !== i_auto_in_0_d_bits_echo_isKeyword) begin errors++;
      if(!reported[71]) begin reported[71]=1; distinct_div++;
        $display("[DIV %0t] auto_in_0_d_bits_echo_isKeyword g=%h i=%h", $time, g_auto_in_0_d_bits_echo_isKeyword, i_auto_in_0_d_bits_echo_isKeyword); end end
    if (!$isunknown(g_auto_in_0_d_bits_data) && g_auto_in_0_d_bits_data !== i_auto_in_0_d_bits_data) begin errors++;
      if(!reported[72]) begin reported[72]=1; distinct_div++;
        $display("[DIV %0t] auto_in_0_d_bits_data g=%h i=%h", $time, g_auto_in_0_d_bits_data, i_auto_in_0_d_bits_data); end end
    if (!$isunknown(g_auto_in_0_d_bits_corrupt) && g_auto_in_0_d_bits_corrupt !== i_auto_in_0_d_bits_corrupt) begin errors++;
      if(!reported[73]) begin reported[73]=1; distinct_div++;
        $display("[DIV %0t] auto_in_0_d_bits_corrupt g=%h i=%h", $time, g_auto_in_0_d_bits_corrupt, i_auto_in_0_d_bits_corrupt); end end
    if (!$isunknown(g_io_l2_hint_valid) && g_io_l2_hint_valid !== i_io_l2_hint_valid) begin errors++;
      if(!reported[74]) begin reported[74]=1; distinct_div++;
        $display("[DIV %0t] io_l2_hint_valid g=%h i=%h", $time, g_io_l2_hint_valid, i_io_l2_hint_valid); end end
    if (!$isunknown(g_io_l2_hint_bits_sourceId) && g_io_l2_hint_bits_sourceId !== i_io_l2_hint_bits_sourceId) begin errors++;
      if(!reported[75]) begin reported[75]=1; distinct_div++;
        $display("[DIV %0t] io_l2_hint_bits_sourceId g=%h i=%h", $time, g_io_l2_hint_bits_sourceId, i_io_l2_hint_bits_sourceId); end end
    if (!$isunknown(g_io_l2_hint_bits_isKeyword) && g_io_l2_hint_bits_isKeyword !== i_io_l2_hint_bits_isKeyword) begin errors++;
      if(!reported[76]) begin reported[76]=1; distinct_div++;
        $display("[DIV %0t] io_l2_hint_bits_isKeyword g=%h i=%h", $time, g_io_l2_hint_bits_isKeyword, i_io_l2_hint_bits_isKeyword); end end
    if (!$isunknown(g_io_l2_tlb_req_req_valid) && g_io_l2_tlb_req_req_valid !== i_io_l2_tlb_req_req_valid) begin errors++;
      if(!reported[77]) begin reported[77]=1; distinct_div++;
        $display("[DIV %0t] io_l2_tlb_req_req_valid g=%h i=%h", $time, g_io_l2_tlb_req_req_valid, i_io_l2_tlb_req_req_valid); end end
    if (!$isunknown(g_io_l2_tlb_req_req_bits_vaddr) && g_io_l2_tlb_req_req_bits_vaddr !== i_io_l2_tlb_req_req_bits_vaddr) begin errors++;
      if(!reported[78]) begin reported[78]=1; distinct_div++;
        $display("[DIV %0t] io_l2_tlb_req_req_bits_vaddr g=%h i=%h", $time, g_io_l2_tlb_req_req_bits_vaddr, i_io_l2_tlb_req_req_bits_vaddr); end end
    if (!$isunknown(g_io_l2_tlb_req_req_bits_cmd) && g_io_l2_tlb_req_req_bits_cmd !== i_io_l2_tlb_req_req_bits_cmd) begin errors++;
      if(!reported[79]) begin reported[79]=1; distinct_div++;
        $display("[DIV %0t] io_l2_tlb_req_req_bits_cmd g=%h i=%h", $time, g_io_l2_tlb_req_req_bits_cmd, i_io_l2_tlb_req_req_bits_cmd); end end
    if (!$isunknown(g_io_l2_tlb_req_req_bits_kill) && g_io_l2_tlb_req_req_bits_kill !== i_io_l2_tlb_req_req_bits_kill) begin errors++;
      if(!reported[80]) begin reported[80]=1; distinct_div++;
        $display("[DIV %0t] io_l2_tlb_req_req_bits_kill g=%h i=%h", $time, g_io_l2_tlb_req_req_bits_kill, i_io_l2_tlb_req_req_bits_kill); end end
    if (!$isunknown(g_io_l2_tlb_req_req_bits_no_translate) && g_io_l2_tlb_req_req_bits_no_translate !== i_io_l2_tlb_req_req_bits_no_translate) begin errors++;
      if(!reported[81]) begin reported[81]=1; distinct_div++;
        $display("[DIV %0t] io_l2_tlb_req_req_bits_no_translate g=%h i=%h", $time, g_io_l2_tlb_req_req_bits_no_translate, i_io_l2_tlb_req_req_bits_no_translate); end end
    if (!$isunknown(g_io_debugTopDown_l2MissMatch) && g_io_debugTopDown_l2MissMatch !== i_io_debugTopDown_l2MissMatch) begin errors++;
      if(!reported[82]) begin reported[82]=1; distinct_div++;
        $display("[DIV %0t] io_debugTopDown_l2MissMatch g=%h i=%h", $time, g_io_debugTopDown_l2MissMatch, i_io_debugTopDown_l2MissMatch); end end
    if (!$isunknown(g_io_l2Miss) && g_io_l2Miss !== i_io_l2Miss) begin errors++;
      if(!reported[83]) begin reported[83]=1; distinct_div++;
        $display("[DIV %0t] io_l2Miss g=%h i=%h", $time, g_io_l2Miss, i_io_l2Miss); end end
    if (!$isunknown(g_io_error_valid) && g_io_error_valid !== i_io_error_valid) begin errors++;
      if(!reported[84]) begin reported[84]=1; distinct_div++;
        $display("[DIV %0t] io_error_valid g=%h i=%h", $time, g_io_error_valid, i_io_error_valid); end end
    if (!$isunknown(g_io_error_address) && g_io_error_address !== i_io_error_address) begin errors++;
      if(!reported[85]) begin reported[85]=1; distinct_div++;
        $display("[DIV %0t] io_error_address g=%h i=%h", $time, g_io_error_address, i_io_error_address); end end
    if (!$isunknown(g_io_perf_1_value) && g_io_perf_1_value !== i_io_perf_1_value) begin errors++;
      if(!reported[86]) begin reported[86]=1; distinct_div++;
        $display("[DIV %0t] io_perf_1_value g=%h i=%h", $time, g_io_perf_1_value, i_io_perf_1_value); end end
    if (!$isunknown(g_io_perf_2_value) && g_io_perf_2_value !== i_io_perf_2_value) begin errors++;
      if(!reported[87]) begin reported[87]=1; distinct_div++;
        $display("[DIV %0t] io_perf_2_value g=%h i=%h", $time, g_io_perf_2_value, i_io_perf_2_value); end end
    if (!$isunknown(g_io_perf_3_value) && g_io_perf_3_value !== i_io_perf_3_value) begin errors++;
      if(!reported[88]) begin reported[88]=1; distinct_div++;
        $display("[DIV %0t] io_perf_3_value g=%h i=%h", $time, g_io_perf_3_value, i_io_perf_3_value); end end
    if (!$isunknown(g_io_perf_4_value) && g_io_perf_4_value !== i_io_perf_4_value) begin errors++;
      if(!reported[89]) begin reported[89]=1; distinct_div++;
        $display("[DIV %0t] io_perf_4_value g=%h i=%h", $time, g_io_perf_4_value, i_io_perf_4_value); end end
    if (!$isunknown(g_io_perf_5_value) && g_io_perf_5_value !== i_io_perf_5_value) begin errors++;
      if(!reported[90]) begin reported[90]=1; distinct_div++;
        $display("[DIV %0t] io_perf_5_value g=%h i=%h", $time, g_io_perf_5_value, i_io_perf_5_value); end end
    if (!$isunknown(g_io_perf_6_value) && g_io_perf_6_value !== i_io_perf_6_value) begin errors++;
      if(!reported[91]) begin reported[91]=1; distinct_div++;
        $display("[DIV %0t] io_perf_6_value g=%h i=%h", $time, g_io_perf_6_value, i_io_perf_6_value); end end
    if (!$isunknown(g_io_perf_7_value) && g_io_perf_7_value !== i_io_perf_7_value) begin errors++;
      if(!reported[92]) begin reported[92]=1; distinct_div++;
        $display("[DIV %0t] io_perf_7_value g=%h i=%h", $time, g_io_perf_7_value, i_io_perf_7_value); end end
    if (!$isunknown(g_io_perf_8_value) && g_io_perf_8_value !== i_io_perf_8_value) begin errors++;
      if(!reported[93]) begin reported[93]=1; distinct_div++;
        $display("[DIV %0t] io_perf_8_value g=%h i=%h", $time, g_io_perf_8_value, i_io_perf_8_value); end end
    if (!$isunknown(g_io_perf_9_value) && g_io_perf_9_value !== i_io_perf_9_value) begin errors++;
      if(!reported[94]) begin reported[94]=1; distinct_div++;
        $display("[DIV %0t] io_perf_9_value g=%h i=%h", $time, g_io_perf_9_value, i_io_perf_9_value); end end
    if (!$isunknown(g_io_perf_10_value) && g_io_perf_10_value !== i_io_perf_10_value) begin errors++;
      if(!reported[95]) begin reported[95]=1; distinct_div++;
        $display("[DIV %0t] io_perf_10_value g=%h i=%h", $time, g_io_perf_10_value, i_io_perf_10_value); end end
    if (!$isunknown(g_io_perf_11_value) && g_io_perf_11_value !== i_io_perf_11_value) begin errors++;
      if(!reported[96]) begin reported[96]=1; distinct_div++;
        $display("[DIV %0t] io_perf_11_value g=%h i=%h", $time, g_io_perf_11_value, i_io_perf_11_value); end end
    if (!$isunknown(g_io_perf_12_value) && g_io_perf_12_value !== i_io_perf_12_value) begin errors++;
      if(!reported[97]) begin reported[97]=1; distinct_div++;
        $display("[DIV %0t] io_perf_12_value g=%h i=%h", $time, g_io_perf_12_value, i_io_perf_12_value); end end
    if (!$isunknown(g_io_perf_13_value) && g_io_perf_13_value !== i_io_perf_13_value) begin errors++;
      if(!reported[98]) begin reported[98]=1; distinct_div++;
        $display("[DIV %0t] io_perf_13_value g=%h i=%h", $time, g_io_perf_13_value, i_io_perf_13_value); end end
    if (!$isunknown(g_io_perf_14_value) && g_io_perf_14_value !== i_io_perf_14_value) begin errors++;
      if(!reported[99]) begin reported[99]=1; distinct_div++;
        $display("[DIV %0t] io_perf_14_value g=%h i=%h", $time, g_io_perf_14_value, i_io_perf_14_value); end end
    if (!$isunknown(g_io_perf_15_value) && g_io_perf_15_value !== i_io_perf_15_value) begin errors++;
      if(!reported[100]) begin reported[100]=1; distinct_div++;
        $display("[DIV %0t] io_perf_15_value g=%h i=%h", $time, g_io_perf_15_value, i_io_perf_15_value); end end
    if (!$isunknown(g_io_perf_16_value) && g_io_perf_16_value !== i_io_perf_16_value) begin errors++;
      if(!reported[101]) begin reported[101]=1; distinct_div++;
        $display("[DIV %0t] io_perf_16_value g=%h i=%h", $time, g_io_perf_16_value, i_io_perf_16_value); end end
    if (!$isunknown(g_io_perf_17_value) && g_io_perf_17_value !== i_io_perf_17_value) begin errors++;
      if(!reported[102]) begin reported[102]=1; distinct_div++;
        $display("[DIV %0t] io_perf_17_value g=%h i=%h", $time, g_io_perf_17_value, i_io_perf_17_value); end end
    if (!$isunknown(g_io_perf_18_value) && g_io_perf_18_value !== i_io_perf_18_value) begin errors++;
      if(!reported[103]) begin reported[103]=1; distinct_div++;
        $display("[DIV %0t] io_perf_18_value g=%h i=%h", $time, g_io_perf_18_value, i_io_perf_18_value); end end
    if (!$isunknown(g_io_perf_19_value) && g_io_perf_19_value !== i_io_perf_19_value) begin errors++;
      if(!reported[104]) begin reported[104]=1; distinct_div++;
        $display("[DIV %0t] io_perf_19_value g=%h i=%h", $time, g_io_perf_19_value, i_io_perf_19_value); end end
    if (!$isunknown(g_io_perf_20_value) && g_io_perf_20_value !== i_io_perf_20_value) begin errors++;
      if(!reported[105]) begin reported[105]=1; distinct_div++;
        $display("[DIV %0t] io_perf_20_value g=%h i=%h", $time, g_io_perf_20_value, i_io_perf_20_value); end end
    if (!$isunknown(g_io_perf_21_value) && g_io_perf_21_value !== i_io_perf_21_value) begin errors++;
      if(!reported[106]) begin reported[106]=1; distinct_div++;
        $display("[DIV %0t] io_perf_21_value g=%h i=%h", $time, g_io_perf_21_value, i_io_perf_21_value); end end
    if (!$isunknown(g_io_perf_22_value) && g_io_perf_22_value !== i_io_perf_22_value) begin errors++;
      if(!reported[107]) begin reported[107]=1; distinct_div++;
        $display("[DIV %0t] io_perf_22_value g=%h i=%h", $time, g_io_perf_22_value, i_io_perf_22_value); end end
    if (!$isunknown(g_io_perf_23_value) && g_io_perf_23_value !== i_io_perf_23_value) begin errors++;
      if(!reported[108]) begin reported[108]=1; distinct_div++;
        $display("[DIV %0t] io_perf_23_value g=%h i=%h", $time, g_io_perf_23_value, i_io_perf_23_value); end end
    if (!$isunknown(g_io_perf_24_value) && g_io_perf_24_value !== i_io_perf_24_value) begin errors++;
      if(!reported[109]) begin reported[109]=1; distinct_div++;
        $display("[DIV %0t] io_perf_24_value g=%h i=%h", $time, g_io_perf_24_value, i_io_perf_24_value); end end
    if (!$isunknown(g_io_perf_25_value) && g_io_perf_25_value !== i_io_perf_25_value) begin errors++;
      if(!reported[110]) begin reported[110]=1; distinct_div++;
        $display("[DIV %0t] io_perf_25_value g=%h i=%h", $time, g_io_perf_25_value, i_io_perf_25_value); end end
    if (!$isunknown(g_io_perf_26_value) && g_io_perf_26_value !== i_io_perf_26_value) begin errors++;
      if(!reported[111]) begin reported[111]=1; distinct_div++;
        $display("[DIV %0t] io_perf_26_value g=%h i=%h", $time, g_io_perf_26_value, i_io_perf_26_value); end end
    if (!$isunknown(g_io_perf_27_value) && g_io_perf_27_value !== i_io_perf_27_value) begin errors++;
      if(!reported[112]) begin reported[112]=1; distinct_div++;
        $display("[DIV %0t] io_perf_27_value g=%h i=%h", $time, g_io_perf_27_value, i_io_perf_27_value); end end
    if (!$isunknown(g_io_perf_28_value) && g_io_perf_28_value !== i_io_perf_28_value) begin errors++;
      if(!reported[113]) begin reported[113]=1; distinct_div++;
        $display("[DIV %0t] io_perf_28_value g=%h i=%h", $time, g_io_perf_28_value, i_io_perf_28_value); end end
    if (!$isunknown(g_io_perf_29_value) && g_io_perf_29_value !== i_io_perf_29_value) begin errors++;
      if(!reported[114]) begin reported[114]=1; distinct_div++;
        $display("[DIV %0t] io_perf_29_value g=%h i=%h", $time, g_io_perf_29_value, i_io_perf_29_value); end end
    if (!$isunknown(g_io_perf_30_value) && g_io_perf_30_value !== i_io_perf_30_value) begin errors++;
      if(!reported[115]) begin reported[115]=1; distinct_div++;
        $display("[DIV %0t] io_perf_30_value g=%h i=%h", $time, g_io_perf_30_value, i_io_perf_30_value); end end
    if (!$isunknown(g_io_perf_31_value) && g_io_perf_31_value !== i_io_perf_31_value) begin errors++;
      if(!reported[116]) begin reported[116]=1; distinct_div++;
        $display("[DIV %0t] io_perf_31_value g=%h i=%h", $time, g_io_perf_31_value, i_io_perf_31_value); end end
    if (!$isunknown(g_io_perf_32_value) && g_io_perf_32_value !== i_io_perf_32_value) begin errors++;
      if(!reported[117]) begin reported[117]=1; distinct_div++;
        $display("[DIV %0t] io_perf_32_value g=%h i=%h", $time, g_io_perf_32_value, i_io_perf_32_value); end end
    if (!$isunknown(g_io_perf_33_value) && g_io_perf_33_value !== i_io_perf_33_value) begin errors++;
      if(!reported[118]) begin reported[118]=1; distinct_div++;
        $display("[DIV %0t] io_perf_33_value g=%h i=%h", $time, g_io_perf_33_value, i_io_perf_33_value); end end
    if (!$isunknown(g_io_perf_34_value) && g_io_perf_34_value !== i_io_perf_34_value) begin errors++;
      if(!reported[119]) begin reported[119]=1; distinct_div++;
        $display("[DIV %0t] io_perf_34_value g=%h i=%h", $time, g_io_perf_34_value, i_io_perf_34_value); end end
    if (!$isunknown(g_io_perf_35_value) && g_io_perf_35_value !== i_io_perf_35_value) begin errors++;
      if(!reported[120]) begin reported[120]=1; distinct_div++;
        $display("[DIV %0t] io_perf_35_value g=%h i=%h", $time, g_io_perf_35_value, i_io_perf_35_value); end end
    if (!$isunknown(g_io_perf_36_value) && g_io_perf_36_value !== i_io_perf_36_value) begin errors++;
      if(!reported[121]) begin reported[121]=1; distinct_div++;
        $display("[DIV %0t] io_perf_36_value g=%h i=%h", $time, g_io_perf_36_value, i_io_perf_36_value); end end
    if (!$isunknown(g_io_perf_37_value) && g_io_perf_37_value !== i_io_perf_37_value) begin errors++;
      if(!reported[122]) begin reported[122]=1; distinct_div++;
        $display("[DIV %0t] io_perf_37_value g=%h i=%h", $time, g_io_perf_37_value, i_io_perf_37_value); end end
    if (!$isunknown(g_io_perf_38_value) && g_io_perf_38_value !== i_io_perf_38_value) begin errors++;
      if(!reported[123]) begin reported[123]=1; distinct_div++;
        $display("[DIV %0t] io_perf_38_value g=%h i=%h", $time, g_io_perf_38_value, i_io_perf_38_value); end end
    if (!$isunknown(g_io_perf_39_value) && g_io_perf_39_value !== i_io_perf_39_value) begin errors++;
      if(!reported[124]) begin reported[124]=1; distinct_div++;
        $display("[DIV %0t] io_perf_39_value g=%h i=%h", $time, g_io_perf_39_value, i_io_perf_39_value); end end
    if (!$isunknown(g_io_perf_40_value) && g_io_perf_40_value !== i_io_perf_40_value) begin errors++;
      if(!reported[125]) begin reported[125]=1; distinct_div++;
        $display("[DIV %0t] io_perf_40_value g=%h i=%h", $time, g_io_perf_40_value, i_io_perf_40_value); end end
    if (!$isunknown(g_io_perf_41_value) && g_io_perf_41_value !== i_io_perf_41_value) begin errors++;
      if(!reported[126]) begin reported[126]=1; distinct_div++;
        $display("[DIV %0t] io_perf_41_value g=%h i=%h", $time, g_io_perf_41_value, i_io_perf_41_value); end end
    if (!$isunknown(g_io_perf_42_value) && g_io_perf_42_value !== i_io_perf_42_value) begin errors++;
      if(!reported[127]) begin reported[127]=1; distinct_div++;
        $display("[DIV %0t] io_perf_42_value g=%h i=%h", $time, g_io_perf_42_value, i_io_perf_42_value); end end
    if (!$isunknown(g_io_perf_43_value) && g_io_perf_43_value !== i_io_perf_43_value) begin errors++;
      if(!reported[128]) begin reported[128]=1; distinct_div++;
        $display("[DIV %0t] io_perf_43_value g=%h i=%h", $time, g_io_perf_43_value, i_io_perf_43_value); end end
    if (!$isunknown(g_io_perf_44_value) && g_io_perf_44_value !== i_io_perf_44_value) begin errors++;
      if(!reported[129]) begin reported[129]=1; distinct_div++;
        $display("[DIV %0t] io_perf_44_value g=%h i=%h", $time, g_io_perf_44_value, i_io_perf_44_value); end end
    if (!$isunknown(g_io_perf_45_value) && g_io_perf_45_value !== i_io_perf_45_value) begin errors++;
      if(!reported[130]) begin reported[130]=1; distinct_div++;
        $display("[DIV %0t] io_perf_45_value g=%h i=%h", $time, g_io_perf_45_value, i_io_perf_45_value); end end
    if (!$isunknown(g_io_perf_46_value) && g_io_perf_46_value !== i_io_perf_46_value) begin errors++;
      if(!reported[131]) begin reported[131]=1; distinct_div++;
        $display("[DIV %0t] io_perf_46_value g=%h i=%h", $time, g_io_perf_46_value, i_io_perf_46_value); end end
    if (!$isunknown(g_io_perf_47_value) && g_io_perf_47_value !== i_io_perf_47_value) begin errors++;
      if(!reported[132]) begin reported[132]=1; distinct_div++;
        $display("[DIV %0t] io_perf_47_value g=%h i=%h", $time, g_io_perf_47_value, i_io_perf_47_value); end end
    if (!$isunknown(g_io_perf_48_value) && g_io_perf_48_value !== i_io_perf_48_value) begin errors++;
      if(!reported[133]) begin reported[133]=1; distinct_div++;
        $display("[DIV %0t] io_perf_48_value g=%h i=%h", $time, g_io_perf_48_value, i_io_perf_48_value); end end
    if (!$isunknown(g_io_chi_txsactive) && g_io_chi_txsactive !== i_io_chi_txsactive) begin errors++;
      if(!reported[134]) begin reported[134]=1; distinct_div++;
        $display("[DIV %0t] io_chi_txsactive g=%h i=%h", $time, g_io_chi_txsactive, i_io_chi_txsactive); end end
    if (!$isunknown(g_io_chi_syscoreq) && g_io_chi_syscoreq !== i_io_chi_syscoreq) begin errors++;
      if(!reported[135]) begin reported[135]=1; distinct_div++;
        $display("[DIV %0t] io_chi_syscoreq g=%h i=%h", $time, g_io_chi_syscoreq, i_io_chi_syscoreq); end end
    if (!$isunknown(g_io_chi_tx_linkactivereq) && g_io_chi_tx_linkactivereq !== i_io_chi_tx_linkactivereq) begin errors++;
      if(!reported[136]) begin reported[136]=1; distinct_div++;
        $display("[DIV %0t] io_chi_tx_linkactivereq g=%h i=%h", $time, g_io_chi_tx_linkactivereq, i_io_chi_tx_linkactivereq); end end
    if (!$isunknown(g_io_chi_tx_req_flitpend) && g_io_chi_tx_req_flitpend !== i_io_chi_tx_req_flitpend) begin errors++;
      if(!reported[137]) begin reported[137]=1; distinct_div++;
        $display("[DIV %0t] io_chi_tx_req_flitpend g=%h i=%h", $time, g_io_chi_tx_req_flitpend, i_io_chi_tx_req_flitpend); end end
    if (!$isunknown(g_io_chi_tx_req_flitv) && g_io_chi_tx_req_flitv !== i_io_chi_tx_req_flitv) begin errors++;
      if(!reported[138]) begin reported[138]=1; distinct_div++;
        $display("[DIV %0t] io_chi_tx_req_flitv g=%h i=%h", $time, g_io_chi_tx_req_flitv, i_io_chi_tx_req_flitv); end end
    if (!$isunknown(g_io_chi_tx_req_flit) && g_io_chi_tx_req_flit !== i_io_chi_tx_req_flit) begin errors++;
      if(!reported[139]) begin reported[139]=1; distinct_div++;
        $display("[DIV %0t] io_chi_tx_req_flit g=%h i=%h", $time, g_io_chi_tx_req_flit, i_io_chi_tx_req_flit); end end
    if (!$isunknown(g_io_chi_tx_rsp_flitpend) && g_io_chi_tx_rsp_flitpend !== i_io_chi_tx_rsp_flitpend) begin errors++;
      if(!reported[140]) begin reported[140]=1; distinct_div++;
        $display("[DIV %0t] io_chi_tx_rsp_flitpend g=%h i=%h", $time, g_io_chi_tx_rsp_flitpend, i_io_chi_tx_rsp_flitpend); end end
    if (!$isunknown(g_io_chi_tx_rsp_flitv) && g_io_chi_tx_rsp_flitv !== i_io_chi_tx_rsp_flitv) begin errors++;
      if(!reported[141]) begin reported[141]=1; distinct_div++;
        $display("[DIV %0t] io_chi_tx_rsp_flitv g=%h i=%h", $time, g_io_chi_tx_rsp_flitv, i_io_chi_tx_rsp_flitv); end end
    if (!$isunknown(g_io_chi_tx_rsp_flit) && g_io_chi_tx_rsp_flit !== i_io_chi_tx_rsp_flit) begin errors++;
      if(!reported[142]) begin reported[142]=1; distinct_div++;
        $display("[DIV %0t] io_chi_tx_rsp_flit g=%h i=%h", $time, g_io_chi_tx_rsp_flit, i_io_chi_tx_rsp_flit); end end
    if (!$isunknown(g_io_chi_tx_dat_flitpend) && g_io_chi_tx_dat_flitpend !== i_io_chi_tx_dat_flitpend) begin errors++;
      if(!reported[143]) begin reported[143]=1; distinct_div++;
        $display("[DIV %0t] io_chi_tx_dat_flitpend g=%h i=%h", $time, g_io_chi_tx_dat_flitpend, i_io_chi_tx_dat_flitpend); end end
    if (!$isunknown(g_io_chi_tx_dat_flitv) && g_io_chi_tx_dat_flitv !== i_io_chi_tx_dat_flitv) begin errors++;
      if(!reported[144]) begin reported[144]=1; distinct_div++;
        $display("[DIV %0t] io_chi_tx_dat_flitv g=%h i=%h", $time, g_io_chi_tx_dat_flitv, i_io_chi_tx_dat_flitv); end end
    if (!$isunknown(g_io_chi_tx_dat_flit) && g_io_chi_tx_dat_flit !== i_io_chi_tx_dat_flit) begin errors++;
      if(!reported[145]) begin reported[145]=1; distinct_div++;
        $display("[DIV %0t] io_chi_tx_dat_flit g=%h i=%h", $time, g_io_chi_tx_dat_flit, i_io_chi_tx_dat_flit); end end
    if (!$isunknown(g_io_chi_rx_linkactiveack) && g_io_chi_rx_linkactiveack !== i_io_chi_rx_linkactiveack) begin errors++;
      if(!reported[146]) begin reported[146]=1; distinct_div++;
        $display("[DIV %0t] io_chi_rx_linkactiveack g=%h i=%h", $time, g_io_chi_rx_linkactiveack, i_io_chi_rx_linkactiveack); end end
    if (!$isunknown(g_io_chi_rx_rsp_lcrdv) && g_io_chi_rx_rsp_lcrdv !== i_io_chi_rx_rsp_lcrdv) begin errors++;
      if(!reported[147]) begin reported[147]=1; distinct_div++;
        $display("[DIV %0t] io_chi_rx_rsp_lcrdv g=%h i=%h", $time, g_io_chi_rx_rsp_lcrdv, i_io_chi_rx_rsp_lcrdv); end end
    if (!$isunknown(g_io_chi_rx_dat_lcrdv) && g_io_chi_rx_dat_lcrdv !== i_io_chi_rx_dat_lcrdv) begin errors++;
      if(!reported[148]) begin reported[148]=1; distinct_div++;
        $display("[DIV %0t] io_chi_rx_dat_lcrdv g=%h i=%h", $time, g_io_chi_rx_dat_lcrdv, i_io_chi_rx_dat_lcrdv); end end
    if (!$isunknown(g_io_chi_rx_snp_lcrdv) && g_io_chi_rx_snp_lcrdv !== i_io_chi_rx_snp_lcrdv) begin errors++;
      if(!reported[149]) begin reported[149]=1; distinct_div++;
        $display("[DIV %0t] io_chi_rx_snp_lcrdv g=%h i=%h", $time, g_io_chi_rx_snp_lcrdv, i_io_chi_rx_snp_lcrdv); end end
  end

  initial begin
    if (!$value$plusargs("NCYCLES=%d", NCYCLES)) NCYCLES = 200000;
    rst = 1; repeat (16) @(posedge clk); rst = 0;
    repeat (NCYCLES) @(posedge clk);
    $display("distinct_diverging_ports=%0d / %0d", distinct_div, 150);
    $display("checks=%0d errors=%0d", checks, errors);
    if (errors == 0 && checks > 1000) $display("TEST PASSED"); else $display("TEST FAILED");
    $finish;
  end
endmodule
