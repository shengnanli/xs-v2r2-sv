// 自动生成:scripts/gen_l2top.py —— 勿手改(顶层 glue 为从 Scala 意图的可读重写)

`timescale 1ns/1ps
module tb;
  int unsigned NCYCLES = 200000;
  bit clk = 0, rst;
  int errors = 0, checks = 0;
  always #5 clk = ~clk;

  logic auto_inner_buffers_out_a_ready;
  logic auto_inner_buffers_out_d_valid;
  logic [3:0] auto_inner_buffers_out_d_bits_opcode;
  logic [1:0] auto_inner_buffers_out_d_bits_param;
  logic [1:0] auto_inner_buffers_out_d_bits_size;
  logic [2:0] auto_inner_buffers_out_d_bits_source;
  logic auto_inner_buffers_out_d_bits_sink;
  logic auto_inner_buffers_out_d_bits_denied;
  logic [63:0] auto_inner_buffers_out_d_bits_data;
  logic auto_inner_buffers_out_d_bits_corrupt;
  logic auto_inner_buffers_in_a_valid;
  logic [3:0] auto_inner_buffers_in_a_bits_opcode;
  logic [2:0] auto_inner_buffers_in_a_bits_param;
  logic [1:0] auto_inner_buffers_in_a_bits_size;
  logic [1:0] auto_inner_buffers_in_a_bits_source;
  logic [47:0] auto_inner_buffers_in_a_bits_address;
  logic auto_inner_buffers_in_a_bits_user_memBackType_MM;
  logic auto_inner_buffers_in_a_bits_user_memPageType_NC;
  logic [7:0] auto_inner_buffers_in_a_bits_mask;
  logic [63:0] auto_inner_buffers_in_a_bits_data;
  logic auto_inner_buffers_in_a_bits_corrupt;
  logic auto_inner_buffers_in_d_ready;
  logic [63:0] auto_inner_l2cache_pf_recv_in_addr;
  logic [4:0] auto_inner_l2cache_pf_recv_in_pf_source;
  logic auto_inner_l2cache_pf_recv_in_addr_valid;
  logic auto_inner_i_mmio_buffer_in_a_valid;
  logic [2:0] auto_inner_i_mmio_buffer_in_a_bits_param;
  logic [47:0] auto_inner_i_mmio_buffer_in_a_bits_address;
  logic auto_inner_i_mmio_buffer_in_a_bits_corrupt;
  logic auto_inner_i_mmio_buffer_in_d_ready;
  logic auto_inner_ptw_to_l2_buffer_in_a_valid;
  logic [3:0] auto_inner_ptw_to_l2_buffer_in_a_bits_opcode;
  logic [2:0] auto_inner_ptw_to_l2_buffer_in_a_bits_param;
  logic [2:0] auto_inner_ptw_to_l2_buffer_in_a_bits_size;
  logic [2:0] auto_inner_ptw_to_l2_buffer_in_a_bits_source;
  logic [47:0] auto_inner_ptw_to_l2_buffer_in_a_bits_address;
  logic [4:0] auto_inner_ptw_to_l2_buffer_in_a_bits_user_reqSource;
  logic [31:0] auto_inner_ptw_to_l2_buffer_in_a_bits_mask;
  logic [255:0] auto_inner_ptw_to_l2_buffer_in_a_bits_data;
  logic auto_inner_ptw_to_l2_buffer_in_a_bits_corrupt;
  logic auto_inner_ptw_to_l2_buffer_in_d_ready;
  logic auto_inner_logger_in_1_a_valid;
  logic [3:0] auto_inner_logger_in_1_a_bits_opcode;
  logic [2:0] auto_inner_logger_in_1_a_bits_param;
  logic [2:0] auto_inner_logger_in_1_a_bits_size;
  logic [3:0] auto_inner_logger_in_1_a_bits_source;
  logic [47:0] auto_inner_logger_in_1_a_bits_address;
  logic [1:0] auto_inner_logger_in_1_a_bits_user_alias;
  logic [4:0] auto_inner_logger_in_1_a_bits_user_reqSource;
  logic auto_inner_logger_in_1_a_bits_user_needHint;
  logic [31:0] auto_inner_logger_in_1_a_bits_mask;
  logic [255:0] auto_inner_logger_in_1_a_bits_data;
  logic auto_inner_logger_in_1_a_bits_corrupt;
  logic auto_inner_logger_in_1_d_ready;
  logic auto_inner_logger_in_0_a_valid;
  logic [3:0] auto_inner_logger_in_0_a_bits_opcode;
  logic [2:0] auto_inner_logger_in_0_a_bits_param;
  logic [2:0] auto_inner_logger_in_0_a_bits_size;
  logic [5:0] auto_inner_logger_in_0_a_bits_source;
  logic [47:0] auto_inner_logger_in_0_a_bits_address;
  logic [1:0] auto_inner_logger_in_0_a_bits_user_alias;
  logic [43:0] auto_inner_logger_in_0_a_bits_user_vaddr;
  logic [4:0] auto_inner_logger_in_0_a_bits_user_reqSource;
  logic auto_inner_logger_in_0_a_bits_user_needHint;
  logic auto_inner_logger_in_0_a_bits_echo_isKeyword;
  logic [31:0] auto_inner_logger_in_0_a_bits_mask;
  logic [255:0] auto_inner_logger_in_0_a_bits_data;
  logic auto_inner_logger_in_0_a_bits_corrupt;
  logic auto_inner_logger_in_0_b_ready;
  logic auto_inner_logger_in_0_c_valid;
  logic [2:0] auto_inner_logger_in_0_c_bits_opcode;
  logic [2:0] auto_inner_logger_in_0_c_bits_param;
  logic [2:0] auto_inner_logger_in_0_c_bits_size;
  logic [5:0] auto_inner_logger_in_0_c_bits_source;
  logic [47:0] auto_inner_logger_in_0_c_bits_address;
  logic [1:0] auto_inner_logger_in_0_c_bits_user_alias;
  logic [43:0] auto_inner_logger_in_0_c_bits_user_vaddr;
  logic [4:0] auto_inner_logger_in_0_c_bits_user_reqSource;
  logic auto_inner_logger_in_0_c_bits_user_needHint;
  logic auto_inner_logger_in_0_c_bits_echo_isKeyword;
  logic [255:0] auto_inner_logger_in_0_c_bits_data;
  logic auto_inner_logger_in_0_c_bits_corrupt;
  logic auto_inner_logger_in_0_d_ready;
  logic auto_inner_logger_in_0_e_valid;
  logic [9:0] auto_inner_logger_in_0_e_bits_sink;
  logic auto_inner_nmi_int_in_0;
  logic auto_inner_nmi_int_in_1;
  logic auto_inner_plic_int_in_1_0;
  logic auto_inner_plic_int_in_0_0;
  logic auto_inner_debug_int_in_0;
  logic auto_inner_clint_int_in_0;
  logic auto_inner_clint_int_in_1;
  logic io_beu_errors_icache_ecc_error_valid;
  logic [47:0] io_beu_errors_icache_ecc_error_bits;
  logic io_beu_errors_dcache_ecc_error_valid;
  logic [47:0] io_beu_errors_dcache_ecc_error_bits;
  logic io_beu_errors_uncache_ecc_error_valid;
  logic [47:0] io_beu_errors_uncache_ecc_error_bits;
  logic [47:0] io_reset_vector_fromTile;
  logic [63:0] io_hartId_fromTile;
  logic io_msiInfo_fromTile_valid;
  logic [10:0] io_msiInfo_fromTile_bits;
  logic io_cpu_halt_fromCore;
  logic io_cpu_critical_error_fromCore;
  logic io_hartIsInReset_resetInFrontend;
  logic [2:0] io_traceCoreInterface_fromCore_toEncoder_priv;
  logic [63:0] io_traceCoreInterface_fromCore_toEncoder_trap_cause;
  logic [49:0] io_traceCoreInterface_fromCore_toEncoder_trap_tval;
  logic io_traceCoreInterface_fromCore_toEncoder_groups_0_valid;
  logic [49:0] io_traceCoreInterface_fromCore_toEncoder_groups_0_bits_iaddr;
  logic [3:0] io_traceCoreInterface_fromCore_toEncoder_groups_0_bits_itype;
  logic [6:0] io_traceCoreInterface_fromCore_toEncoder_groups_0_bits_iretire;
  logic io_traceCoreInterface_fromCore_toEncoder_groups_0_bits_ilastsize;
  logic io_traceCoreInterface_fromCore_toEncoder_groups_1_valid;
  logic [49:0] io_traceCoreInterface_fromCore_toEncoder_groups_1_bits_iaddr;
  logic [3:0] io_traceCoreInterface_fromCore_toEncoder_groups_1_bits_itype;
  logic [6:0] io_traceCoreInterface_fromCore_toEncoder_groups_1_bits_iretire;
  logic io_traceCoreInterface_fromCore_toEncoder_groups_1_bits_ilastsize;
  logic io_traceCoreInterface_fromCore_toEncoder_groups_2_valid;
  logic [49:0] io_traceCoreInterface_fromCore_toEncoder_groups_2_bits_iaddr;
  logic [3:0] io_traceCoreInterface_fromCore_toEncoder_groups_2_bits_itype;
  logic [6:0] io_traceCoreInterface_fromCore_toEncoder_groups_2_bits_iretire;
  logic io_traceCoreInterface_fromCore_toEncoder_groups_2_bits_ilastsize;
  logic io_traceCoreInterface_toTile_fromEncoder_enable;
  logic io_traceCoreInterface_toTile_fromEncoder_stall;
  logic io_debugTopDown_robHeadPaddr_valid;
  logic [35:0] io_debugTopDown_robHeadPaddr_bits;
  logic io_l3Miss_fromTile;
  logic io_clintTime_fromTile_valid;
  logic [63:0] io_clintTime_fromTile_bits;
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
  logic io_pfCtrlFromCore_l2_pf_master_en;
  logic io_pfCtrlFromCore_l2_pf_recv_en;
  logic io_pfCtrlFromCore_l2_pbop_en;
  logic io_pfCtrlFromCore_l2_vbop_en;
  logic io_l2_tlb_req_resp_valid;
  logic [47:0] io_l2_tlb_req_resp_bits_paddr_0;
  logic [1:0] io_l2_tlb_req_resp_bits_pbmt_0;
  logic io_l2_tlb_req_resp_bits_miss;
  logic io_l2_tlb_req_resp_bits_excp_0_gpf_ld;
  logic io_l2_tlb_req_resp_bits_excp_0_pf_ld;
  logic io_l2_tlb_req_resp_bits_excp_0_af_ld;
  logic io_l2_pmp_resp_ld;
  logic io_l2_pmp_resp_mmio;
  logic io_dft_ram_hold;
  logic io_dft_ram_bypass;
  logic io_dft_ram_bp_clken;
  logic io_dft_ram_aux_clk;
  logic io_dft_ram_aux_ckbp;
  logic io_dft_ram_mcp_hold;
  logic io_dft_cgen;
  wire g_auto_inner_buffers_out_a_valid;
  wire i_auto_inner_buffers_out_a_valid;
  wire [3:0] g_auto_inner_buffers_out_a_bits_opcode;
  wire [3:0] i_auto_inner_buffers_out_a_bits_opcode;
  wire [2:0] g_auto_inner_buffers_out_a_bits_param;
  wire [2:0] i_auto_inner_buffers_out_a_bits_param;
  wire [1:0] g_auto_inner_buffers_out_a_bits_size;
  wire [1:0] i_auto_inner_buffers_out_a_bits_size;
  wire [2:0] g_auto_inner_buffers_out_a_bits_source;
  wire [2:0] i_auto_inner_buffers_out_a_bits_source;
  wire [29:0] g_auto_inner_buffers_out_a_bits_address;
  wire [29:0] i_auto_inner_buffers_out_a_bits_address;
  wire [7:0] g_auto_inner_buffers_out_a_bits_mask;
  wire [7:0] i_auto_inner_buffers_out_a_bits_mask;
  wire [63:0] g_auto_inner_buffers_out_a_bits_data;
  wire [63:0] i_auto_inner_buffers_out_a_bits_data;
  wire g_auto_inner_buffers_out_a_bits_corrupt;
  wire i_auto_inner_buffers_out_a_bits_corrupt;
  wire g_auto_inner_buffers_out_d_ready;
  wire i_auto_inner_buffers_out_d_ready;
  wire g_auto_inner_buffers_in_a_ready;
  wire i_auto_inner_buffers_in_a_ready;
  wire g_auto_inner_buffers_in_d_valid;
  wire i_auto_inner_buffers_in_d_valid;
  wire [3:0] g_auto_inner_buffers_in_d_bits_opcode;
  wire [3:0] i_auto_inner_buffers_in_d_bits_opcode;
  wire [1:0] g_auto_inner_buffers_in_d_bits_param;
  wire [1:0] i_auto_inner_buffers_in_d_bits_param;
  wire [1:0] g_auto_inner_buffers_in_d_bits_size;
  wire [1:0] i_auto_inner_buffers_in_d_bits_size;
  wire [1:0] g_auto_inner_buffers_in_d_bits_source;
  wire [1:0] i_auto_inner_buffers_in_d_bits_source;
  wire g_auto_inner_buffers_in_d_bits_sink;
  wire i_auto_inner_buffers_in_d_bits_sink;
  wire g_auto_inner_buffers_in_d_bits_denied;
  wire i_auto_inner_buffers_in_d_bits_denied;
  wire [63:0] g_auto_inner_buffers_in_d_bits_data;
  wire [63:0] i_auto_inner_buffers_in_d_bits_data;
  wire g_auto_inner_buffers_in_d_bits_corrupt;
  wire i_auto_inner_buffers_in_d_bits_corrupt;
  wire g_auto_inner_i_mmio_buffer_in_a_ready;
  wire i_auto_inner_i_mmio_buffer_in_a_ready;
  wire g_auto_inner_i_mmio_buffer_in_d_valid;
  wire i_auto_inner_i_mmio_buffer_in_d_valid;
  wire [3:0] g_auto_inner_i_mmio_buffer_in_d_bits_opcode;
  wire [3:0] i_auto_inner_i_mmio_buffer_in_d_bits_opcode;
  wire [1:0] g_auto_inner_i_mmio_buffer_in_d_bits_param;
  wire [1:0] i_auto_inner_i_mmio_buffer_in_d_bits_param;
  wire [1:0] g_auto_inner_i_mmio_buffer_in_d_bits_size;
  wire [1:0] i_auto_inner_i_mmio_buffer_in_d_bits_size;
  wire g_auto_inner_i_mmio_buffer_in_d_bits_source;
  wire i_auto_inner_i_mmio_buffer_in_d_bits_source;
  wire g_auto_inner_i_mmio_buffer_in_d_bits_sink;
  wire i_auto_inner_i_mmio_buffer_in_d_bits_sink;
  wire g_auto_inner_i_mmio_buffer_in_d_bits_denied;
  wire i_auto_inner_i_mmio_buffer_in_d_bits_denied;
  wire [63:0] g_auto_inner_i_mmio_buffer_in_d_bits_data;
  wire [63:0] i_auto_inner_i_mmio_buffer_in_d_bits_data;
  wire g_auto_inner_i_mmio_buffer_in_d_bits_corrupt;
  wire i_auto_inner_i_mmio_buffer_in_d_bits_corrupt;
  wire g_auto_inner_ptw_to_l2_buffer_in_a_ready;
  wire i_auto_inner_ptw_to_l2_buffer_in_a_ready;
  wire g_auto_inner_ptw_to_l2_buffer_in_d_valid;
  wire i_auto_inner_ptw_to_l2_buffer_in_d_valid;
  wire [3:0] g_auto_inner_ptw_to_l2_buffer_in_d_bits_opcode;
  wire [3:0] i_auto_inner_ptw_to_l2_buffer_in_d_bits_opcode;
  wire [1:0] g_auto_inner_ptw_to_l2_buffer_in_d_bits_param;
  wire [1:0] i_auto_inner_ptw_to_l2_buffer_in_d_bits_param;
  wire [2:0] g_auto_inner_ptw_to_l2_buffer_in_d_bits_size;
  wire [2:0] i_auto_inner_ptw_to_l2_buffer_in_d_bits_size;
  wire [2:0] g_auto_inner_ptw_to_l2_buffer_in_d_bits_source;
  wire [2:0] i_auto_inner_ptw_to_l2_buffer_in_d_bits_source;
  wire [9:0] g_auto_inner_ptw_to_l2_buffer_in_d_bits_sink;
  wire [9:0] i_auto_inner_ptw_to_l2_buffer_in_d_bits_sink;
  wire g_auto_inner_ptw_to_l2_buffer_in_d_bits_denied;
  wire i_auto_inner_ptw_to_l2_buffer_in_d_bits_denied;
  wire [255:0] g_auto_inner_ptw_to_l2_buffer_in_d_bits_data;
  wire [255:0] i_auto_inner_ptw_to_l2_buffer_in_d_bits_data;
  wire g_auto_inner_ptw_to_l2_buffer_in_d_bits_corrupt;
  wire i_auto_inner_ptw_to_l2_buffer_in_d_bits_corrupt;
  wire g_auto_inner_logger_in_1_a_ready;
  wire i_auto_inner_logger_in_1_a_ready;
  wire g_auto_inner_logger_in_1_d_valid;
  wire i_auto_inner_logger_in_1_d_valid;
  wire [3:0] g_auto_inner_logger_in_1_d_bits_opcode;
  wire [3:0] i_auto_inner_logger_in_1_d_bits_opcode;
  wire [1:0] g_auto_inner_logger_in_1_d_bits_param;
  wire [1:0] i_auto_inner_logger_in_1_d_bits_param;
  wire [2:0] g_auto_inner_logger_in_1_d_bits_size;
  wire [2:0] i_auto_inner_logger_in_1_d_bits_size;
  wire [3:0] g_auto_inner_logger_in_1_d_bits_source;
  wire [3:0] i_auto_inner_logger_in_1_d_bits_source;
  wire [9:0] g_auto_inner_logger_in_1_d_bits_sink;
  wire [9:0] i_auto_inner_logger_in_1_d_bits_sink;
  wire g_auto_inner_logger_in_1_d_bits_denied;
  wire i_auto_inner_logger_in_1_d_bits_denied;
  wire [255:0] g_auto_inner_logger_in_1_d_bits_data;
  wire [255:0] i_auto_inner_logger_in_1_d_bits_data;
  wire g_auto_inner_logger_in_1_d_bits_corrupt;
  wire i_auto_inner_logger_in_1_d_bits_corrupt;
  wire g_auto_inner_logger_in_0_a_ready;
  wire i_auto_inner_logger_in_0_a_ready;
  wire g_auto_inner_logger_in_0_b_valid;
  wire i_auto_inner_logger_in_0_b_valid;
  wire [2:0] g_auto_inner_logger_in_0_b_bits_opcode;
  wire [2:0] i_auto_inner_logger_in_0_b_bits_opcode;
  wire [1:0] g_auto_inner_logger_in_0_b_bits_param;
  wire [1:0] i_auto_inner_logger_in_0_b_bits_param;
  wire [2:0] g_auto_inner_logger_in_0_b_bits_size;
  wire [2:0] i_auto_inner_logger_in_0_b_bits_size;
  wire [5:0] g_auto_inner_logger_in_0_b_bits_source;
  wire [5:0] i_auto_inner_logger_in_0_b_bits_source;
  wire [47:0] g_auto_inner_logger_in_0_b_bits_address;
  wire [47:0] i_auto_inner_logger_in_0_b_bits_address;
  wire [31:0] g_auto_inner_logger_in_0_b_bits_mask;
  wire [31:0] i_auto_inner_logger_in_0_b_bits_mask;
  wire [255:0] g_auto_inner_logger_in_0_b_bits_data;
  wire [255:0] i_auto_inner_logger_in_0_b_bits_data;
  wire g_auto_inner_logger_in_0_b_bits_corrupt;
  wire i_auto_inner_logger_in_0_b_bits_corrupt;
  wire g_auto_inner_logger_in_0_c_ready;
  wire i_auto_inner_logger_in_0_c_ready;
  wire g_auto_inner_logger_in_0_d_valid;
  wire i_auto_inner_logger_in_0_d_valid;
  wire [3:0] g_auto_inner_logger_in_0_d_bits_opcode;
  wire [3:0] i_auto_inner_logger_in_0_d_bits_opcode;
  wire [1:0] g_auto_inner_logger_in_0_d_bits_param;
  wire [1:0] i_auto_inner_logger_in_0_d_bits_param;
  wire [2:0] g_auto_inner_logger_in_0_d_bits_size;
  wire [2:0] i_auto_inner_logger_in_0_d_bits_size;
  wire [5:0] g_auto_inner_logger_in_0_d_bits_source;
  wire [5:0] i_auto_inner_logger_in_0_d_bits_source;
  wire [9:0] g_auto_inner_logger_in_0_d_bits_sink;
  wire [9:0] i_auto_inner_logger_in_0_d_bits_sink;
  wire g_auto_inner_logger_in_0_d_bits_denied;
  wire i_auto_inner_logger_in_0_d_bits_denied;
  wire g_auto_inner_logger_in_0_d_bits_echo_isKeyword;
  wire i_auto_inner_logger_in_0_d_bits_echo_isKeyword;
  wire [255:0] g_auto_inner_logger_in_0_d_bits_data;
  wire [255:0] i_auto_inner_logger_in_0_d_bits_data;
  wire g_auto_inner_logger_in_0_d_bits_corrupt;
  wire i_auto_inner_logger_in_0_d_bits_corrupt;
  wire g_auto_inner_logger_in_0_e_ready;
  wire i_auto_inner_logger_in_0_e_ready;
  wire g_auto_inner_beu_int_out_0;
  wire i_auto_inner_beu_int_out_0;
  wire g_auto_inner_beu_local_int_source_out_0;
  wire i_auto_inner_beu_local_int_source_out_0;
  wire g_auto_inner_nmi_int_out_0;
  wire i_auto_inner_nmi_int_out_0;
  wire g_auto_inner_nmi_int_out_1;
  wire i_auto_inner_nmi_int_out_1;
  wire g_auto_inner_plic_int_out_1_0;
  wire i_auto_inner_plic_int_out_1_0;
  wire g_auto_inner_plic_int_out_0_0;
  wire i_auto_inner_plic_int_out_0_0;
  wire g_auto_inner_debug_int_out_0;
  wire i_auto_inner_debug_int_out_0;
  wire g_auto_inner_clint_int_out_0;
  wire i_auto_inner_clint_int_out_0;
  wire g_auto_inner_clint_int_out_1;
  wire i_auto_inner_clint_int_out_1;
  wire [47:0] g_io_reset_vector_toCore;
  wire [47:0] i_io_reset_vector_toCore;
  wire [63:0] g_io_hartId_toCore;
  wire [63:0] i_io_hartId_toCore;
  wire g_io_msiInfo_toCore_valid;
  wire i_io_msiInfo_toCore_valid;
  wire [10:0] g_io_msiInfo_toCore_bits;
  wire [10:0] i_io_msiInfo_toCore_bits;
  wire g_io_cpu_halt_toTile;
  wire i_io_cpu_halt_toTile;
  wire g_io_cpu_critical_error_toTile;
  wire i_io_cpu_critical_error_toTile;
  wire g_io_hartIsInReset_toTile;
  wire i_io_hartIsInReset_toTile;
  wire g_io_traceCoreInterface_fromCore_fromEncoder_enable;
  wire i_io_traceCoreInterface_fromCore_fromEncoder_enable;
  wire g_io_traceCoreInterface_fromCore_fromEncoder_stall;
  wire i_io_traceCoreInterface_fromCore_fromEncoder_stall;
  wire [2:0] g_io_traceCoreInterface_toTile_toEncoder_priv;
  wire [2:0] i_io_traceCoreInterface_toTile_toEncoder_priv;
  wire [63:0] g_io_traceCoreInterface_toTile_toEncoder_trap_cause;
  wire [63:0] i_io_traceCoreInterface_toTile_toEncoder_trap_cause;
  wire [49:0] g_io_traceCoreInterface_toTile_toEncoder_trap_tval;
  wire [49:0] i_io_traceCoreInterface_toTile_toEncoder_trap_tval;
  wire [49:0] g_io_traceCoreInterface_toTile_toEncoder_groups_0_bits_iaddr;
  wire [49:0] i_io_traceCoreInterface_toTile_toEncoder_groups_0_bits_iaddr;
  wire [3:0] g_io_traceCoreInterface_toTile_toEncoder_groups_0_bits_itype;
  wire [3:0] i_io_traceCoreInterface_toTile_toEncoder_groups_0_bits_itype;
  wire [6:0] g_io_traceCoreInterface_toTile_toEncoder_groups_0_bits_iretire;
  wire [6:0] i_io_traceCoreInterface_toTile_toEncoder_groups_0_bits_iretire;
  wire g_io_traceCoreInterface_toTile_toEncoder_groups_0_bits_ilastsize;
  wire i_io_traceCoreInterface_toTile_toEncoder_groups_0_bits_ilastsize;
  wire [49:0] g_io_traceCoreInterface_toTile_toEncoder_groups_1_bits_iaddr;
  wire [49:0] i_io_traceCoreInterface_toTile_toEncoder_groups_1_bits_iaddr;
  wire [3:0] g_io_traceCoreInterface_toTile_toEncoder_groups_1_bits_itype;
  wire [3:0] i_io_traceCoreInterface_toTile_toEncoder_groups_1_bits_itype;
  wire [6:0] g_io_traceCoreInterface_toTile_toEncoder_groups_1_bits_iretire;
  wire [6:0] i_io_traceCoreInterface_toTile_toEncoder_groups_1_bits_iretire;
  wire g_io_traceCoreInterface_toTile_toEncoder_groups_1_bits_ilastsize;
  wire i_io_traceCoreInterface_toTile_toEncoder_groups_1_bits_ilastsize;
  wire [49:0] g_io_traceCoreInterface_toTile_toEncoder_groups_2_bits_iaddr;
  wire [49:0] i_io_traceCoreInterface_toTile_toEncoder_groups_2_bits_iaddr;
  wire [3:0] g_io_traceCoreInterface_toTile_toEncoder_groups_2_bits_itype;
  wire [3:0] i_io_traceCoreInterface_toTile_toEncoder_groups_2_bits_itype;
  wire [6:0] g_io_traceCoreInterface_toTile_toEncoder_groups_2_bits_iretire;
  wire [6:0] i_io_traceCoreInterface_toTile_toEncoder_groups_2_bits_iretire;
  wire g_io_traceCoreInterface_toTile_toEncoder_groups_2_bits_ilastsize;
  wire i_io_traceCoreInterface_toTile_toEncoder_groups_2_bits_ilastsize;
  wire g_io_debugTopDown_l2MissMatch;
  wire i_io_debugTopDown_l2MissMatch;
  wire g_io_l2Miss;
  wire i_io_l2Miss;
  wire g_io_l3Miss_toCore;
  wire i_io_l3Miss_toCore;
  wire g_io_clintTime_toCore_valid;
  wire i_io_clintTime_toCore_valid;
  wire [63:0] g_io_clintTime_toCore_bits;
  wire [63:0] i_io_clintTime_toCore_bits;
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
  wire g_io_l2_hint_valid;
  wire i_io_l2_hint_valid;
  wire [3:0] g_io_l2_hint_bits_sourceId;
  wire [3:0] i_io_l2_hint_bits_sourceId;
  wire g_io_l2_hint_bits_isKeyword;
  wire i_io_l2_hint_bits_isKeyword;
  wire [5:0] g_io_perfEvents_1_value;
  wire [5:0] i_io_perfEvents_1_value;
  wire [5:0] g_io_perfEvents_2_value;
  wire [5:0] i_io_perfEvents_2_value;
  wire [5:0] g_io_perfEvents_3_value;
  wire [5:0] i_io_perfEvents_3_value;
  wire [5:0] g_io_perfEvents_4_value;
  wire [5:0] i_io_perfEvents_4_value;
  wire [5:0] g_io_perfEvents_5_value;
  wire [5:0] i_io_perfEvents_5_value;
  wire [5:0] g_io_perfEvents_6_value;
  wire [5:0] i_io_perfEvents_6_value;
  wire [5:0] g_io_perfEvents_7_value;
  wire [5:0] i_io_perfEvents_7_value;
  wire [5:0] g_io_perfEvents_8_value;
  wire [5:0] i_io_perfEvents_8_value;
  wire [5:0] g_io_perfEvents_9_value;
  wire [5:0] i_io_perfEvents_9_value;
  wire [5:0] g_io_perfEvents_10_value;
  wire [5:0] i_io_perfEvents_10_value;
  wire [5:0] g_io_perfEvents_11_value;
  wire [5:0] i_io_perfEvents_11_value;
  wire [5:0] g_io_perfEvents_12_value;
  wire [5:0] i_io_perfEvents_12_value;
  wire [5:0] g_io_perfEvents_13_value;
  wire [5:0] i_io_perfEvents_13_value;
  wire [5:0] g_io_perfEvents_14_value;
  wire [5:0] i_io_perfEvents_14_value;
  wire [5:0] g_io_perfEvents_15_value;
  wire [5:0] i_io_perfEvents_15_value;
  wire [5:0] g_io_perfEvents_16_value;
  wire [5:0] i_io_perfEvents_16_value;
  wire [5:0] g_io_perfEvents_17_value;
  wire [5:0] i_io_perfEvents_17_value;
  wire [5:0] g_io_perfEvents_18_value;
  wire [5:0] i_io_perfEvents_18_value;
  wire [5:0] g_io_perfEvents_19_value;
  wire [5:0] i_io_perfEvents_19_value;
  wire [5:0] g_io_perfEvents_20_value;
  wire [5:0] i_io_perfEvents_20_value;
  wire [5:0] g_io_perfEvents_21_value;
  wire [5:0] i_io_perfEvents_21_value;
  wire [5:0] g_io_perfEvents_22_value;
  wire [5:0] i_io_perfEvents_22_value;
  wire [5:0] g_io_perfEvents_23_value;
  wire [5:0] i_io_perfEvents_23_value;
  wire [5:0] g_io_perfEvents_24_value;
  wire [5:0] i_io_perfEvents_24_value;
  wire [5:0] g_io_perfEvents_25_value;
  wire [5:0] i_io_perfEvents_25_value;
  wire [5:0] g_io_perfEvents_26_value;
  wire [5:0] i_io_perfEvents_26_value;
  wire [5:0] g_io_perfEvents_27_value;
  wire [5:0] i_io_perfEvents_27_value;
  wire [5:0] g_io_perfEvents_28_value;
  wire [5:0] i_io_perfEvents_28_value;
  wire [5:0] g_io_perfEvents_29_value;
  wire [5:0] i_io_perfEvents_29_value;
  wire [5:0] g_io_perfEvents_30_value;
  wire [5:0] i_io_perfEvents_30_value;
  wire [5:0] g_io_perfEvents_31_value;
  wire [5:0] i_io_perfEvents_31_value;
  wire [5:0] g_io_perfEvents_32_value;
  wire [5:0] i_io_perfEvents_32_value;
  wire [5:0] g_io_perfEvents_33_value;
  wire [5:0] i_io_perfEvents_33_value;
  wire [5:0] g_io_perfEvents_34_value;
  wire [5:0] i_io_perfEvents_34_value;
  wire [5:0] g_io_perfEvents_35_value;
  wire [5:0] i_io_perfEvents_35_value;
  wire [5:0] g_io_perfEvents_36_value;
  wire [5:0] i_io_perfEvents_36_value;
  wire [5:0] g_io_perfEvents_37_value;
  wire [5:0] i_io_perfEvents_37_value;
  wire [5:0] g_io_perfEvents_38_value;
  wire [5:0] i_io_perfEvents_38_value;
  wire [5:0] g_io_perfEvents_39_value;
  wire [5:0] i_io_perfEvents_39_value;
  wire [5:0] g_io_perfEvents_40_value;
  wire [5:0] i_io_perfEvents_40_value;
  wire [5:0] g_io_perfEvents_41_value;
  wire [5:0] i_io_perfEvents_41_value;
  wire [5:0] g_io_perfEvents_42_value;
  wire [5:0] i_io_perfEvents_42_value;
  wire [5:0] g_io_perfEvents_43_value;
  wire [5:0] i_io_perfEvents_43_value;
  wire [5:0] g_io_perfEvents_44_value;
  wire [5:0] i_io_perfEvents_44_value;
  wire [5:0] g_io_perfEvents_45_value;
  wire [5:0] i_io_perfEvents_45_value;
  wire [5:0] g_io_perfEvents_46_value;
  wire [5:0] i_io_perfEvents_46_value;
  wire [5:0] g_io_perfEvents_47_value;
  wire [5:0] i_io_perfEvents_47_value;
  wire [5:0] g_io_perfEvents_48_value;
  wire [5:0] i_io_perfEvents_48_value;

  L2Top    u_g (.clock(clk), .reset(rst), .auto_inner_buffers_out_a_ready(auto_inner_buffers_out_a_ready), .auto_inner_buffers_out_a_valid(g_auto_inner_buffers_out_a_valid), .auto_inner_buffers_out_a_bits_opcode(g_auto_inner_buffers_out_a_bits_opcode), .auto_inner_buffers_out_a_bits_param(g_auto_inner_buffers_out_a_bits_param), .auto_inner_buffers_out_a_bits_size(g_auto_inner_buffers_out_a_bits_size), .auto_inner_buffers_out_a_bits_source(g_auto_inner_buffers_out_a_bits_source), .auto_inner_buffers_out_a_bits_address(g_auto_inner_buffers_out_a_bits_address), .auto_inner_buffers_out_a_bits_mask(g_auto_inner_buffers_out_a_bits_mask), .auto_inner_buffers_out_a_bits_data(g_auto_inner_buffers_out_a_bits_data), .auto_inner_buffers_out_a_bits_corrupt(g_auto_inner_buffers_out_a_bits_corrupt), .auto_inner_buffers_out_d_ready(g_auto_inner_buffers_out_d_ready), .auto_inner_buffers_out_d_valid(auto_inner_buffers_out_d_valid), .auto_inner_buffers_out_d_bits_opcode(auto_inner_buffers_out_d_bits_opcode), .auto_inner_buffers_out_d_bits_param(auto_inner_buffers_out_d_bits_param), .auto_inner_buffers_out_d_bits_size(auto_inner_buffers_out_d_bits_size), .auto_inner_buffers_out_d_bits_source(auto_inner_buffers_out_d_bits_source), .auto_inner_buffers_out_d_bits_sink(auto_inner_buffers_out_d_bits_sink), .auto_inner_buffers_out_d_bits_denied(auto_inner_buffers_out_d_bits_denied), .auto_inner_buffers_out_d_bits_data(auto_inner_buffers_out_d_bits_data), .auto_inner_buffers_out_d_bits_corrupt(auto_inner_buffers_out_d_bits_corrupt), .auto_inner_buffers_in_a_ready(g_auto_inner_buffers_in_a_ready), .auto_inner_buffers_in_a_valid(auto_inner_buffers_in_a_valid), .auto_inner_buffers_in_a_bits_opcode(auto_inner_buffers_in_a_bits_opcode), .auto_inner_buffers_in_a_bits_param(auto_inner_buffers_in_a_bits_param), .auto_inner_buffers_in_a_bits_size(auto_inner_buffers_in_a_bits_size), .auto_inner_buffers_in_a_bits_source(auto_inner_buffers_in_a_bits_source), .auto_inner_buffers_in_a_bits_address(auto_inner_buffers_in_a_bits_address), .auto_inner_buffers_in_a_bits_user_memBackType_MM(auto_inner_buffers_in_a_bits_user_memBackType_MM), .auto_inner_buffers_in_a_bits_user_memPageType_NC(auto_inner_buffers_in_a_bits_user_memPageType_NC), .auto_inner_buffers_in_a_bits_mask(auto_inner_buffers_in_a_bits_mask), .auto_inner_buffers_in_a_bits_data(auto_inner_buffers_in_a_bits_data), .auto_inner_buffers_in_a_bits_corrupt(auto_inner_buffers_in_a_bits_corrupt), .auto_inner_buffers_in_d_ready(auto_inner_buffers_in_d_ready), .auto_inner_buffers_in_d_valid(g_auto_inner_buffers_in_d_valid), .auto_inner_buffers_in_d_bits_opcode(g_auto_inner_buffers_in_d_bits_opcode), .auto_inner_buffers_in_d_bits_param(g_auto_inner_buffers_in_d_bits_param), .auto_inner_buffers_in_d_bits_size(g_auto_inner_buffers_in_d_bits_size), .auto_inner_buffers_in_d_bits_source(g_auto_inner_buffers_in_d_bits_source), .auto_inner_buffers_in_d_bits_sink(g_auto_inner_buffers_in_d_bits_sink), .auto_inner_buffers_in_d_bits_denied(g_auto_inner_buffers_in_d_bits_denied), .auto_inner_buffers_in_d_bits_data(g_auto_inner_buffers_in_d_bits_data), .auto_inner_buffers_in_d_bits_corrupt(g_auto_inner_buffers_in_d_bits_corrupt), .auto_inner_l2cache_pf_recv_in_addr(auto_inner_l2cache_pf_recv_in_addr), .auto_inner_l2cache_pf_recv_in_pf_source(auto_inner_l2cache_pf_recv_in_pf_source), .auto_inner_l2cache_pf_recv_in_addr_valid(auto_inner_l2cache_pf_recv_in_addr_valid), .auto_inner_i_mmio_buffer_in_a_ready(g_auto_inner_i_mmio_buffer_in_a_ready), .auto_inner_i_mmio_buffer_in_a_valid(auto_inner_i_mmio_buffer_in_a_valid), .auto_inner_i_mmio_buffer_in_a_bits_param(auto_inner_i_mmio_buffer_in_a_bits_param), .auto_inner_i_mmio_buffer_in_a_bits_address(auto_inner_i_mmio_buffer_in_a_bits_address), .auto_inner_i_mmio_buffer_in_a_bits_corrupt(auto_inner_i_mmio_buffer_in_a_bits_corrupt), .auto_inner_i_mmio_buffer_in_d_ready(auto_inner_i_mmio_buffer_in_d_ready), .auto_inner_i_mmio_buffer_in_d_valid(g_auto_inner_i_mmio_buffer_in_d_valid), .auto_inner_i_mmio_buffer_in_d_bits_opcode(g_auto_inner_i_mmio_buffer_in_d_bits_opcode), .auto_inner_i_mmio_buffer_in_d_bits_param(g_auto_inner_i_mmio_buffer_in_d_bits_param), .auto_inner_i_mmio_buffer_in_d_bits_size(g_auto_inner_i_mmio_buffer_in_d_bits_size), .auto_inner_i_mmio_buffer_in_d_bits_source(g_auto_inner_i_mmio_buffer_in_d_bits_source), .auto_inner_i_mmio_buffer_in_d_bits_sink(g_auto_inner_i_mmio_buffer_in_d_bits_sink), .auto_inner_i_mmio_buffer_in_d_bits_denied(g_auto_inner_i_mmio_buffer_in_d_bits_denied), .auto_inner_i_mmio_buffer_in_d_bits_data(g_auto_inner_i_mmio_buffer_in_d_bits_data), .auto_inner_i_mmio_buffer_in_d_bits_corrupt(g_auto_inner_i_mmio_buffer_in_d_bits_corrupt), .auto_inner_ptw_to_l2_buffer_in_a_ready(g_auto_inner_ptw_to_l2_buffer_in_a_ready), .auto_inner_ptw_to_l2_buffer_in_a_valid(auto_inner_ptw_to_l2_buffer_in_a_valid), .auto_inner_ptw_to_l2_buffer_in_a_bits_opcode(auto_inner_ptw_to_l2_buffer_in_a_bits_opcode), .auto_inner_ptw_to_l2_buffer_in_a_bits_param(auto_inner_ptw_to_l2_buffer_in_a_bits_param), .auto_inner_ptw_to_l2_buffer_in_a_bits_size(auto_inner_ptw_to_l2_buffer_in_a_bits_size), .auto_inner_ptw_to_l2_buffer_in_a_bits_source(auto_inner_ptw_to_l2_buffer_in_a_bits_source), .auto_inner_ptw_to_l2_buffer_in_a_bits_address(auto_inner_ptw_to_l2_buffer_in_a_bits_address), .auto_inner_ptw_to_l2_buffer_in_a_bits_user_reqSource(auto_inner_ptw_to_l2_buffer_in_a_bits_user_reqSource), .auto_inner_ptw_to_l2_buffer_in_a_bits_mask(auto_inner_ptw_to_l2_buffer_in_a_bits_mask), .auto_inner_ptw_to_l2_buffer_in_a_bits_data(auto_inner_ptw_to_l2_buffer_in_a_bits_data), .auto_inner_ptw_to_l2_buffer_in_a_bits_corrupt(auto_inner_ptw_to_l2_buffer_in_a_bits_corrupt), .auto_inner_ptw_to_l2_buffer_in_d_ready(auto_inner_ptw_to_l2_buffer_in_d_ready), .auto_inner_ptw_to_l2_buffer_in_d_valid(g_auto_inner_ptw_to_l2_buffer_in_d_valid), .auto_inner_ptw_to_l2_buffer_in_d_bits_opcode(g_auto_inner_ptw_to_l2_buffer_in_d_bits_opcode), .auto_inner_ptw_to_l2_buffer_in_d_bits_param(g_auto_inner_ptw_to_l2_buffer_in_d_bits_param), .auto_inner_ptw_to_l2_buffer_in_d_bits_size(g_auto_inner_ptw_to_l2_buffer_in_d_bits_size), .auto_inner_ptw_to_l2_buffer_in_d_bits_source(g_auto_inner_ptw_to_l2_buffer_in_d_bits_source), .auto_inner_ptw_to_l2_buffer_in_d_bits_sink(g_auto_inner_ptw_to_l2_buffer_in_d_bits_sink), .auto_inner_ptw_to_l2_buffer_in_d_bits_denied(g_auto_inner_ptw_to_l2_buffer_in_d_bits_denied), .auto_inner_ptw_to_l2_buffer_in_d_bits_data(g_auto_inner_ptw_to_l2_buffer_in_d_bits_data), .auto_inner_ptw_to_l2_buffer_in_d_bits_corrupt(g_auto_inner_ptw_to_l2_buffer_in_d_bits_corrupt), .auto_inner_logger_in_1_a_ready(g_auto_inner_logger_in_1_a_ready), .auto_inner_logger_in_1_a_valid(auto_inner_logger_in_1_a_valid), .auto_inner_logger_in_1_a_bits_opcode(auto_inner_logger_in_1_a_bits_opcode), .auto_inner_logger_in_1_a_bits_param(auto_inner_logger_in_1_a_bits_param), .auto_inner_logger_in_1_a_bits_size(auto_inner_logger_in_1_a_bits_size), .auto_inner_logger_in_1_a_bits_source(auto_inner_logger_in_1_a_bits_source), .auto_inner_logger_in_1_a_bits_address(auto_inner_logger_in_1_a_bits_address), .auto_inner_logger_in_1_a_bits_user_alias(auto_inner_logger_in_1_a_bits_user_alias), .auto_inner_logger_in_1_a_bits_user_reqSource(auto_inner_logger_in_1_a_bits_user_reqSource), .auto_inner_logger_in_1_a_bits_user_needHint(auto_inner_logger_in_1_a_bits_user_needHint), .auto_inner_logger_in_1_a_bits_mask(auto_inner_logger_in_1_a_bits_mask), .auto_inner_logger_in_1_a_bits_data(auto_inner_logger_in_1_a_bits_data), .auto_inner_logger_in_1_a_bits_corrupt(auto_inner_logger_in_1_a_bits_corrupt), .auto_inner_logger_in_1_d_ready(auto_inner_logger_in_1_d_ready), .auto_inner_logger_in_1_d_valid(g_auto_inner_logger_in_1_d_valid), .auto_inner_logger_in_1_d_bits_opcode(g_auto_inner_logger_in_1_d_bits_opcode), .auto_inner_logger_in_1_d_bits_param(g_auto_inner_logger_in_1_d_bits_param), .auto_inner_logger_in_1_d_bits_size(g_auto_inner_logger_in_1_d_bits_size), .auto_inner_logger_in_1_d_bits_source(g_auto_inner_logger_in_1_d_bits_source), .auto_inner_logger_in_1_d_bits_sink(g_auto_inner_logger_in_1_d_bits_sink), .auto_inner_logger_in_1_d_bits_denied(g_auto_inner_logger_in_1_d_bits_denied), .auto_inner_logger_in_1_d_bits_data(g_auto_inner_logger_in_1_d_bits_data), .auto_inner_logger_in_1_d_bits_corrupt(g_auto_inner_logger_in_1_d_bits_corrupt), .auto_inner_logger_in_0_a_ready(g_auto_inner_logger_in_0_a_ready), .auto_inner_logger_in_0_a_valid(auto_inner_logger_in_0_a_valid), .auto_inner_logger_in_0_a_bits_opcode(auto_inner_logger_in_0_a_bits_opcode), .auto_inner_logger_in_0_a_bits_param(auto_inner_logger_in_0_a_bits_param), .auto_inner_logger_in_0_a_bits_size(auto_inner_logger_in_0_a_bits_size), .auto_inner_logger_in_0_a_bits_source(auto_inner_logger_in_0_a_bits_source), .auto_inner_logger_in_0_a_bits_address(auto_inner_logger_in_0_a_bits_address), .auto_inner_logger_in_0_a_bits_user_alias(auto_inner_logger_in_0_a_bits_user_alias), .auto_inner_logger_in_0_a_bits_user_vaddr(auto_inner_logger_in_0_a_bits_user_vaddr), .auto_inner_logger_in_0_a_bits_user_reqSource(auto_inner_logger_in_0_a_bits_user_reqSource), .auto_inner_logger_in_0_a_bits_user_needHint(auto_inner_logger_in_0_a_bits_user_needHint), .auto_inner_logger_in_0_a_bits_echo_isKeyword(auto_inner_logger_in_0_a_bits_echo_isKeyword), .auto_inner_logger_in_0_a_bits_mask(auto_inner_logger_in_0_a_bits_mask), .auto_inner_logger_in_0_a_bits_data(auto_inner_logger_in_0_a_bits_data), .auto_inner_logger_in_0_a_bits_corrupt(auto_inner_logger_in_0_a_bits_corrupt), .auto_inner_logger_in_0_b_ready(auto_inner_logger_in_0_b_ready), .auto_inner_logger_in_0_b_valid(g_auto_inner_logger_in_0_b_valid), .auto_inner_logger_in_0_b_bits_opcode(g_auto_inner_logger_in_0_b_bits_opcode), .auto_inner_logger_in_0_b_bits_param(g_auto_inner_logger_in_0_b_bits_param), .auto_inner_logger_in_0_b_bits_size(g_auto_inner_logger_in_0_b_bits_size), .auto_inner_logger_in_0_b_bits_source(g_auto_inner_logger_in_0_b_bits_source), .auto_inner_logger_in_0_b_bits_address(g_auto_inner_logger_in_0_b_bits_address), .auto_inner_logger_in_0_b_bits_mask(g_auto_inner_logger_in_0_b_bits_mask), .auto_inner_logger_in_0_b_bits_data(g_auto_inner_logger_in_0_b_bits_data), .auto_inner_logger_in_0_b_bits_corrupt(g_auto_inner_logger_in_0_b_bits_corrupt), .auto_inner_logger_in_0_c_ready(g_auto_inner_logger_in_0_c_ready), .auto_inner_logger_in_0_c_valid(auto_inner_logger_in_0_c_valid), .auto_inner_logger_in_0_c_bits_opcode(auto_inner_logger_in_0_c_bits_opcode), .auto_inner_logger_in_0_c_bits_param(auto_inner_logger_in_0_c_bits_param), .auto_inner_logger_in_0_c_bits_size(auto_inner_logger_in_0_c_bits_size), .auto_inner_logger_in_0_c_bits_source(auto_inner_logger_in_0_c_bits_source), .auto_inner_logger_in_0_c_bits_address(auto_inner_logger_in_0_c_bits_address), .auto_inner_logger_in_0_c_bits_user_alias(auto_inner_logger_in_0_c_bits_user_alias), .auto_inner_logger_in_0_c_bits_user_vaddr(auto_inner_logger_in_0_c_bits_user_vaddr), .auto_inner_logger_in_0_c_bits_user_reqSource(auto_inner_logger_in_0_c_bits_user_reqSource), .auto_inner_logger_in_0_c_bits_user_needHint(auto_inner_logger_in_0_c_bits_user_needHint), .auto_inner_logger_in_0_c_bits_echo_isKeyword(auto_inner_logger_in_0_c_bits_echo_isKeyword), .auto_inner_logger_in_0_c_bits_data(auto_inner_logger_in_0_c_bits_data), .auto_inner_logger_in_0_c_bits_corrupt(auto_inner_logger_in_0_c_bits_corrupt), .auto_inner_logger_in_0_d_ready(auto_inner_logger_in_0_d_ready), .auto_inner_logger_in_0_d_valid(g_auto_inner_logger_in_0_d_valid), .auto_inner_logger_in_0_d_bits_opcode(g_auto_inner_logger_in_0_d_bits_opcode), .auto_inner_logger_in_0_d_bits_param(g_auto_inner_logger_in_0_d_bits_param), .auto_inner_logger_in_0_d_bits_size(g_auto_inner_logger_in_0_d_bits_size), .auto_inner_logger_in_0_d_bits_source(g_auto_inner_logger_in_0_d_bits_source), .auto_inner_logger_in_0_d_bits_sink(g_auto_inner_logger_in_0_d_bits_sink), .auto_inner_logger_in_0_d_bits_denied(g_auto_inner_logger_in_0_d_bits_denied), .auto_inner_logger_in_0_d_bits_echo_isKeyword(g_auto_inner_logger_in_0_d_bits_echo_isKeyword), .auto_inner_logger_in_0_d_bits_data(g_auto_inner_logger_in_0_d_bits_data), .auto_inner_logger_in_0_d_bits_corrupt(g_auto_inner_logger_in_0_d_bits_corrupt), .auto_inner_logger_in_0_e_ready(g_auto_inner_logger_in_0_e_ready), .auto_inner_logger_in_0_e_valid(auto_inner_logger_in_0_e_valid), .auto_inner_logger_in_0_e_bits_sink(auto_inner_logger_in_0_e_bits_sink), .auto_inner_beu_int_out_0(g_auto_inner_beu_int_out_0), .auto_inner_beu_local_int_source_out_0(g_auto_inner_beu_local_int_source_out_0), .auto_inner_nmi_int_in_0(auto_inner_nmi_int_in_0), .auto_inner_nmi_int_in_1(auto_inner_nmi_int_in_1), .auto_inner_nmi_int_out_0(g_auto_inner_nmi_int_out_0), .auto_inner_nmi_int_out_1(g_auto_inner_nmi_int_out_1), .auto_inner_plic_int_in_1_0(auto_inner_plic_int_in_1_0), .auto_inner_plic_int_in_0_0(auto_inner_plic_int_in_0_0), .auto_inner_plic_int_out_1_0(g_auto_inner_plic_int_out_1_0), .auto_inner_plic_int_out_0_0(g_auto_inner_plic_int_out_0_0), .auto_inner_debug_int_in_0(auto_inner_debug_int_in_0), .auto_inner_debug_int_out_0(g_auto_inner_debug_int_out_0), .auto_inner_clint_int_in_0(auto_inner_clint_int_in_0), .auto_inner_clint_int_in_1(auto_inner_clint_int_in_1), .auto_inner_clint_int_out_0(g_auto_inner_clint_int_out_0), .auto_inner_clint_int_out_1(g_auto_inner_clint_int_out_1), .io_beu_errors_icache_ecc_error_valid(io_beu_errors_icache_ecc_error_valid), .io_beu_errors_icache_ecc_error_bits(io_beu_errors_icache_ecc_error_bits), .io_beu_errors_dcache_ecc_error_valid(io_beu_errors_dcache_ecc_error_valid), .io_beu_errors_dcache_ecc_error_bits(io_beu_errors_dcache_ecc_error_bits), .io_beu_errors_uncache_ecc_error_valid(io_beu_errors_uncache_ecc_error_valid), .io_beu_errors_uncache_ecc_error_bits(io_beu_errors_uncache_ecc_error_bits), .io_reset_vector_fromTile(io_reset_vector_fromTile), .io_reset_vector_toCore(g_io_reset_vector_toCore), .io_hartId_fromTile(io_hartId_fromTile), .io_hartId_toCore(g_io_hartId_toCore), .io_msiInfo_fromTile_valid(io_msiInfo_fromTile_valid), .io_msiInfo_fromTile_bits(io_msiInfo_fromTile_bits), .io_msiInfo_toCore_valid(g_io_msiInfo_toCore_valid), .io_msiInfo_toCore_bits(g_io_msiInfo_toCore_bits), .io_cpu_halt_fromCore(io_cpu_halt_fromCore), .io_cpu_halt_toTile(g_io_cpu_halt_toTile), .io_cpu_critical_error_fromCore(io_cpu_critical_error_fromCore), .io_cpu_critical_error_toTile(g_io_cpu_critical_error_toTile), .io_hartIsInReset_resetInFrontend(io_hartIsInReset_resetInFrontend), .io_hartIsInReset_toTile(g_io_hartIsInReset_toTile), .io_traceCoreInterface_fromCore_fromEncoder_enable(g_io_traceCoreInterface_fromCore_fromEncoder_enable), .io_traceCoreInterface_fromCore_fromEncoder_stall(g_io_traceCoreInterface_fromCore_fromEncoder_stall), .io_traceCoreInterface_fromCore_toEncoder_priv(io_traceCoreInterface_fromCore_toEncoder_priv), .io_traceCoreInterface_fromCore_toEncoder_trap_cause(io_traceCoreInterface_fromCore_toEncoder_trap_cause), .io_traceCoreInterface_fromCore_toEncoder_trap_tval(io_traceCoreInterface_fromCore_toEncoder_trap_tval), .io_traceCoreInterface_fromCore_toEncoder_groups_0_valid(io_traceCoreInterface_fromCore_toEncoder_groups_0_valid), .io_traceCoreInterface_fromCore_toEncoder_groups_0_bits_iaddr(io_traceCoreInterface_fromCore_toEncoder_groups_0_bits_iaddr), .io_traceCoreInterface_fromCore_toEncoder_groups_0_bits_itype(io_traceCoreInterface_fromCore_toEncoder_groups_0_bits_itype), .io_traceCoreInterface_fromCore_toEncoder_groups_0_bits_iretire(io_traceCoreInterface_fromCore_toEncoder_groups_0_bits_iretire), .io_traceCoreInterface_fromCore_toEncoder_groups_0_bits_ilastsize(io_traceCoreInterface_fromCore_toEncoder_groups_0_bits_ilastsize), .io_traceCoreInterface_fromCore_toEncoder_groups_1_valid(io_traceCoreInterface_fromCore_toEncoder_groups_1_valid), .io_traceCoreInterface_fromCore_toEncoder_groups_1_bits_iaddr(io_traceCoreInterface_fromCore_toEncoder_groups_1_bits_iaddr), .io_traceCoreInterface_fromCore_toEncoder_groups_1_bits_itype(io_traceCoreInterface_fromCore_toEncoder_groups_1_bits_itype), .io_traceCoreInterface_fromCore_toEncoder_groups_1_bits_iretire(io_traceCoreInterface_fromCore_toEncoder_groups_1_bits_iretire), .io_traceCoreInterface_fromCore_toEncoder_groups_1_bits_ilastsize(io_traceCoreInterface_fromCore_toEncoder_groups_1_bits_ilastsize), .io_traceCoreInterface_fromCore_toEncoder_groups_2_valid(io_traceCoreInterface_fromCore_toEncoder_groups_2_valid), .io_traceCoreInterface_fromCore_toEncoder_groups_2_bits_iaddr(io_traceCoreInterface_fromCore_toEncoder_groups_2_bits_iaddr), .io_traceCoreInterface_fromCore_toEncoder_groups_2_bits_itype(io_traceCoreInterface_fromCore_toEncoder_groups_2_bits_itype), .io_traceCoreInterface_fromCore_toEncoder_groups_2_bits_iretire(io_traceCoreInterface_fromCore_toEncoder_groups_2_bits_iretire), .io_traceCoreInterface_fromCore_toEncoder_groups_2_bits_ilastsize(io_traceCoreInterface_fromCore_toEncoder_groups_2_bits_ilastsize), .io_traceCoreInterface_toTile_fromEncoder_enable(io_traceCoreInterface_toTile_fromEncoder_enable), .io_traceCoreInterface_toTile_fromEncoder_stall(io_traceCoreInterface_toTile_fromEncoder_stall), .io_traceCoreInterface_toTile_toEncoder_priv(g_io_traceCoreInterface_toTile_toEncoder_priv), .io_traceCoreInterface_toTile_toEncoder_trap_cause(g_io_traceCoreInterface_toTile_toEncoder_trap_cause), .io_traceCoreInterface_toTile_toEncoder_trap_tval(g_io_traceCoreInterface_toTile_toEncoder_trap_tval), .io_traceCoreInterface_toTile_toEncoder_groups_0_bits_iaddr(g_io_traceCoreInterface_toTile_toEncoder_groups_0_bits_iaddr), .io_traceCoreInterface_toTile_toEncoder_groups_0_bits_itype(g_io_traceCoreInterface_toTile_toEncoder_groups_0_bits_itype), .io_traceCoreInterface_toTile_toEncoder_groups_0_bits_iretire(g_io_traceCoreInterface_toTile_toEncoder_groups_0_bits_iretire), .io_traceCoreInterface_toTile_toEncoder_groups_0_bits_ilastsize(g_io_traceCoreInterface_toTile_toEncoder_groups_0_bits_ilastsize), .io_traceCoreInterface_toTile_toEncoder_groups_1_bits_iaddr(g_io_traceCoreInterface_toTile_toEncoder_groups_1_bits_iaddr), .io_traceCoreInterface_toTile_toEncoder_groups_1_bits_itype(g_io_traceCoreInterface_toTile_toEncoder_groups_1_bits_itype), .io_traceCoreInterface_toTile_toEncoder_groups_1_bits_iretire(g_io_traceCoreInterface_toTile_toEncoder_groups_1_bits_iretire), .io_traceCoreInterface_toTile_toEncoder_groups_1_bits_ilastsize(g_io_traceCoreInterface_toTile_toEncoder_groups_1_bits_ilastsize), .io_traceCoreInterface_toTile_toEncoder_groups_2_bits_iaddr(g_io_traceCoreInterface_toTile_toEncoder_groups_2_bits_iaddr), .io_traceCoreInterface_toTile_toEncoder_groups_2_bits_itype(g_io_traceCoreInterface_toTile_toEncoder_groups_2_bits_itype), .io_traceCoreInterface_toTile_toEncoder_groups_2_bits_iretire(g_io_traceCoreInterface_toTile_toEncoder_groups_2_bits_iretire), .io_traceCoreInterface_toTile_toEncoder_groups_2_bits_ilastsize(g_io_traceCoreInterface_toTile_toEncoder_groups_2_bits_ilastsize), .io_debugTopDown_robHeadPaddr_valid(io_debugTopDown_robHeadPaddr_valid), .io_debugTopDown_robHeadPaddr_bits(io_debugTopDown_robHeadPaddr_bits), .io_debugTopDown_l2MissMatch(g_io_debugTopDown_l2MissMatch), .io_l2Miss(g_io_l2Miss), .io_l3Miss_fromTile(io_l3Miss_fromTile), .io_l3Miss_toCore(g_io_l3Miss_toCore), .io_clintTime_fromTile_valid(io_clintTime_fromTile_valid), .io_clintTime_fromTile_bits(io_clintTime_fromTile_bits), .io_clintTime_toCore_valid(g_io_clintTime_toCore_valid), .io_clintTime_toCore_bits(g_io_clintTime_toCore_bits), .io_chi_txsactive(g_io_chi_txsactive), .io_chi_rxsactive(io_chi_rxsactive), .io_chi_syscoreq(g_io_chi_syscoreq), .io_chi_syscoack(io_chi_syscoack), .io_chi_tx_linkactivereq(g_io_chi_tx_linkactivereq), .io_chi_tx_linkactiveack(io_chi_tx_linkactiveack), .io_chi_tx_req_flitpend(g_io_chi_tx_req_flitpend), .io_chi_tx_req_flitv(g_io_chi_tx_req_flitv), .io_chi_tx_req_flit(g_io_chi_tx_req_flit), .io_chi_tx_req_lcrdv(io_chi_tx_req_lcrdv), .io_chi_tx_rsp_flitpend(g_io_chi_tx_rsp_flitpend), .io_chi_tx_rsp_flitv(g_io_chi_tx_rsp_flitv), .io_chi_tx_rsp_flit(g_io_chi_tx_rsp_flit), .io_chi_tx_rsp_lcrdv(io_chi_tx_rsp_lcrdv), .io_chi_tx_dat_flitpend(g_io_chi_tx_dat_flitpend), .io_chi_tx_dat_flitv(g_io_chi_tx_dat_flitv), .io_chi_tx_dat_flit(g_io_chi_tx_dat_flit), .io_chi_tx_dat_lcrdv(io_chi_tx_dat_lcrdv), .io_chi_rx_linkactivereq(io_chi_rx_linkactivereq), .io_chi_rx_linkactiveack(g_io_chi_rx_linkactiveack), .io_chi_rx_rsp_flitpend(io_chi_rx_rsp_flitpend), .io_chi_rx_rsp_flitv(io_chi_rx_rsp_flitv), .io_chi_rx_rsp_flit(io_chi_rx_rsp_flit), .io_chi_rx_rsp_lcrdv(g_io_chi_rx_rsp_lcrdv), .io_chi_rx_dat_flitpend(io_chi_rx_dat_flitpend), .io_chi_rx_dat_flitv(io_chi_rx_dat_flitv), .io_chi_rx_dat_flit(io_chi_rx_dat_flit), .io_chi_rx_dat_lcrdv(g_io_chi_rx_dat_lcrdv), .io_chi_rx_snp_flitpend(io_chi_rx_snp_flitpend), .io_chi_rx_snp_flitv(io_chi_rx_snp_flitv), .io_chi_rx_snp_flit(io_chi_rx_snp_flit), .io_chi_rx_snp_lcrdv(g_io_chi_rx_snp_lcrdv), .io_nodeID(io_nodeID), .io_pfCtrlFromCore_l2_pf_master_en(io_pfCtrlFromCore_l2_pf_master_en), .io_pfCtrlFromCore_l2_pf_recv_en(io_pfCtrlFromCore_l2_pf_recv_en), .io_pfCtrlFromCore_l2_pbop_en(io_pfCtrlFromCore_l2_pbop_en), .io_pfCtrlFromCore_l2_vbop_en(io_pfCtrlFromCore_l2_vbop_en), .io_l2_tlb_req_req_valid(g_io_l2_tlb_req_req_valid), .io_l2_tlb_req_req_bits_vaddr(g_io_l2_tlb_req_req_bits_vaddr), .io_l2_tlb_req_req_bits_cmd(g_io_l2_tlb_req_req_bits_cmd), .io_l2_tlb_req_req_bits_kill(g_io_l2_tlb_req_req_bits_kill), .io_l2_tlb_req_req_bits_no_translate(g_io_l2_tlb_req_req_bits_no_translate), .io_l2_tlb_req_resp_valid(io_l2_tlb_req_resp_valid), .io_l2_tlb_req_resp_bits_paddr_0(io_l2_tlb_req_resp_bits_paddr_0), .io_l2_tlb_req_resp_bits_pbmt_0(io_l2_tlb_req_resp_bits_pbmt_0), .io_l2_tlb_req_resp_bits_miss(io_l2_tlb_req_resp_bits_miss), .io_l2_tlb_req_resp_bits_excp_0_gpf_ld(io_l2_tlb_req_resp_bits_excp_0_gpf_ld), .io_l2_tlb_req_resp_bits_excp_0_pf_ld(io_l2_tlb_req_resp_bits_excp_0_pf_ld), .io_l2_tlb_req_resp_bits_excp_0_af_ld(io_l2_tlb_req_resp_bits_excp_0_af_ld), .io_l2_pmp_resp_ld(io_l2_pmp_resp_ld), .io_l2_pmp_resp_mmio(io_l2_pmp_resp_mmio), .io_l2_hint_valid(g_io_l2_hint_valid), .io_l2_hint_bits_sourceId(g_io_l2_hint_bits_sourceId), .io_l2_hint_bits_isKeyword(g_io_l2_hint_bits_isKeyword), .io_perfEvents_1_value(g_io_perfEvents_1_value), .io_perfEvents_2_value(g_io_perfEvents_2_value), .io_perfEvents_3_value(g_io_perfEvents_3_value), .io_perfEvents_4_value(g_io_perfEvents_4_value), .io_perfEvents_5_value(g_io_perfEvents_5_value), .io_perfEvents_6_value(g_io_perfEvents_6_value), .io_perfEvents_7_value(g_io_perfEvents_7_value), .io_perfEvents_8_value(g_io_perfEvents_8_value), .io_perfEvents_9_value(g_io_perfEvents_9_value), .io_perfEvents_10_value(g_io_perfEvents_10_value), .io_perfEvents_11_value(g_io_perfEvents_11_value), .io_perfEvents_12_value(g_io_perfEvents_12_value), .io_perfEvents_13_value(g_io_perfEvents_13_value), .io_perfEvents_14_value(g_io_perfEvents_14_value), .io_perfEvents_15_value(g_io_perfEvents_15_value), .io_perfEvents_16_value(g_io_perfEvents_16_value), .io_perfEvents_17_value(g_io_perfEvents_17_value), .io_perfEvents_18_value(g_io_perfEvents_18_value), .io_perfEvents_19_value(g_io_perfEvents_19_value), .io_perfEvents_20_value(g_io_perfEvents_20_value), .io_perfEvents_21_value(g_io_perfEvents_21_value), .io_perfEvents_22_value(g_io_perfEvents_22_value), .io_perfEvents_23_value(g_io_perfEvents_23_value), .io_perfEvents_24_value(g_io_perfEvents_24_value), .io_perfEvents_25_value(g_io_perfEvents_25_value), .io_perfEvents_26_value(g_io_perfEvents_26_value), .io_perfEvents_27_value(g_io_perfEvents_27_value), .io_perfEvents_28_value(g_io_perfEvents_28_value), .io_perfEvents_29_value(g_io_perfEvents_29_value), .io_perfEvents_30_value(g_io_perfEvents_30_value), .io_perfEvents_31_value(g_io_perfEvents_31_value), .io_perfEvents_32_value(g_io_perfEvents_32_value), .io_perfEvents_33_value(g_io_perfEvents_33_value), .io_perfEvents_34_value(g_io_perfEvents_34_value), .io_perfEvents_35_value(g_io_perfEvents_35_value), .io_perfEvents_36_value(g_io_perfEvents_36_value), .io_perfEvents_37_value(g_io_perfEvents_37_value), .io_perfEvents_38_value(g_io_perfEvents_38_value), .io_perfEvents_39_value(g_io_perfEvents_39_value), .io_perfEvents_40_value(g_io_perfEvents_40_value), .io_perfEvents_41_value(g_io_perfEvents_41_value), .io_perfEvents_42_value(g_io_perfEvents_42_value), .io_perfEvents_43_value(g_io_perfEvents_43_value), .io_perfEvents_44_value(g_io_perfEvents_44_value), .io_perfEvents_45_value(g_io_perfEvents_45_value), .io_perfEvents_46_value(g_io_perfEvents_46_value), .io_perfEvents_47_value(g_io_perfEvents_47_value), .io_perfEvents_48_value(g_io_perfEvents_48_value), .io_dft_ram_hold(io_dft_ram_hold), .io_dft_ram_bypass(io_dft_ram_bypass), .io_dft_ram_bp_clken(io_dft_ram_bp_clken), .io_dft_ram_aux_clk(io_dft_ram_aux_clk), .io_dft_ram_aux_ckbp(io_dft_ram_aux_ckbp), .io_dft_ram_mcp_hold(io_dft_ram_mcp_hold), .io_dft_cgen(io_dft_cgen));
  L2Top_xs u_i (.clock(clk), .reset(rst), .auto_inner_buffers_out_a_ready(auto_inner_buffers_out_a_ready), .auto_inner_buffers_out_a_valid(i_auto_inner_buffers_out_a_valid), .auto_inner_buffers_out_a_bits_opcode(i_auto_inner_buffers_out_a_bits_opcode), .auto_inner_buffers_out_a_bits_param(i_auto_inner_buffers_out_a_bits_param), .auto_inner_buffers_out_a_bits_size(i_auto_inner_buffers_out_a_bits_size), .auto_inner_buffers_out_a_bits_source(i_auto_inner_buffers_out_a_bits_source), .auto_inner_buffers_out_a_bits_address(i_auto_inner_buffers_out_a_bits_address), .auto_inner_buffers_out_a_bits_mask(i_auto_inner_buffers_out_a_bits_mask), .auto_inner_buffers_out_a_bits_data(i_auto_inner_buffers_out_a_bits_data), .auto_inner_buffers_out_a_bits_corrupt(i_auto_inner_buffers_out_a_bits_corrupt), .auto_inner_buffers_out_d_ready(i_auto_inner_buffers_out_d_ready), .auto_inner_buffers_out_d_valid(auto_inner_buffers_out_d_valid), .auto_inner_buffers_out_d_bits_opcode(auto_inner_buffers_out_d_bits_opcode), .auto_inner_buffers_out_d_bits_param(auto_inner_buffers_out_d_bits_param), .auto_inner_buffers_out_d_bits_size(auto_inner_buffers_out_d_bits_size), .auto_inner_buffers_out_d_bits_source(auto_inner_buffers_out_d_bits_source), .auto_inner_buffers_out_d_bits_sink(auto_inner_buffers_out_d_bits_sink), .auto_inner_buffers_out_d_bits_denied(auto_inner_buffers_out_d_bits_denied), .auto_inner_buffers_out_d_bits_data(auto_inner_buffers_out_d_bits_data), .auto_inner_buffers_out_d_bits_corrupt(auto_inner_buffers_out_d_bits_corrupt), .auto_inner_buffers_in_a_ready(i_auto_inner_buffers_in_a_ready), .auto_inner_buffers_in_a_valid(auto_inner_buffers_in_a_valid), .auto_inner_buffers_in_a_bits_opcode(auto_inner_buffers_in_a_bits_opcode), .auto_inner_buffers_in_a_bits_param(auto_inner_buffers_in_a_bits_param), .auto_inner_buffers_in_a_bits_size(auto_inner_buffers_in_a_bits_size), .auto_inner_buffers_in_a_bits_source(auto_inner_buffers_in_a_bits_source), .auto_inner_buffers_in_a_bits_address(auto_inner_buffers_in_a_bits_address), .auto_inner_buffers_in_a_bits_user_memBackType_MM(auto_inner_buffers_in_a_bits_user_memBackType_MM), .auto_inner_buffers_in_a_bits_user_memPageType_NC(auto_inner_buffers_in_a_bits_user_memPageType_NC), .auto_inner_buffers_in_a_bits_mask(auto_inner_buffers_in_a_bits_mask), .auto_inner_buffers_in_a_bits_data(auto_inner_buffers_in_a_bits_data), .auto_inner_buffers_in_a_bits_corrupt(auto_inner_buffers_in_a_bits_corrupt), .auto_inner_buffers_in_d_ready(auto_inner_buffers_in_d_ready), .auto_inner_buffers_in_d_valid(i_auto_inner_buffers_in_d_valid), .auto_inner_buffers_in_d_bits_opcode(i_auto_inner_buffers_in_d_bits_opcode), .auto_inner_buffers_in_d_bits_param(i_auto_inner_buffers_in_d_bits_param), .auto_inner_buffers_in_d_bits_size(i_auto_inner_buffers_in_d_bits_size), .auto_inner_buffers_in_d_bits_source(i_auto_inner_buffers_in_d_bits_source), .auto_inner_buffers_in_d_bits_sink(i_auto_inner_buffers_in_d_bits_sink), .auto_inner_buffers_in_d_bits_denied(i_auto_inner_buffers_in_d_bits_denied), .auto_inner_buffers_in_d_bits_data(i_auto_inner_buffers_in_d_bits_data), .auto_inner_buffers_in_d_bits_corrupt(i_auto_inner_buffers_in_d_bits_corrupt), .auto_inner_l2cache_pf_recv_in_addr(auto_inner_l2cache_pf_recv_in_addr), .auto_inner_l2cache_pf_recv_in_pf_source(auto_inner_l2cache_pf_recv_in_pf_source), .auto_inner_l2cache_pf_recv_in_addr_valid(auto_inner_l2cache_pf_recv_in_addr_valid), .auto_inner_i_mmio_buffer_in_a_ready(i_auto_inner_i_mmio_buffer_in_a_ready), .auto_inner_i_mmio_buffer_in_a_valid(auto_inner_i_mmio_buffer_in_a_valid), .auto_inner_i_mmio_buffer_in_a_bits_param(auto_inner_i_mmio_buffer_in_a_bits_param), .auto_inner_i_mmio_buffer_in_a_bits_address(auto_inner_i_mmio_buffer_in_a_bits_address), .auto_inner_i_mmio_buffer_in_a_bits_corrupt(auto_inner_i_mmio_buffer_in_a_bits_corrupt), .auto_inner_i_mmio_buffer_in_d_ready(auto_inner_i_mmio_buffer_in_d_ready), .auto_inner_i_mmio_buffer_in_d_valid(i_auto_inner_i_mmio_buffer_in_d_valid), .auto_inner_i_mmio_buffer_in_d_bits_opcode(i_auto_inner_i_mmio_buffer_in_d_bits_opcode), .auto_inner_i_mmio_buffer_in_d_bits_param(i_auto_inner_i_mmio_buffer_in_d_bits_param), .auto_inner_i_mmio_buffer_in_d_bits_size(i_auto_inner_i_mmio_buffer_in_d_bits_size), .auto_inner_i_mmio_buffer_in_d_bits_source(i_auto_inner_i_mmio_buffer_in_d_bits_source), .auto_inner_i_mmio_buffer_in_d_bits_sink(i_auto_inner_i_mmio_buffer_in_d_bits_sink), .auto_inner_i_mmio_buffer_in_d_bits_denied(i_auto_inner_i_mmio_buffer_in_d_bits_denied), .auto_inner_i_mmio_buffer_in_d_bits_data(i_auto_inner_i_mmio_buffer_in_d_bits_data), .auto_inner_i_mmio_buffer_in_d_bits_corrupt(i_auto_inner_i_mmio_buffer_in_d_bits_corrupt), .auto_inner_ptw_to_l2_buffer_in_a_ready(i_auto_inner_ptw_to_l2_buffer_in_a_ready), .auto_inner_ptw_to_l2_buffer_in_a_valid(auto_inner_ptw_to_l2_buffer_in_a_valid), .auto_inner_ptw_to_l2_buffer_in_a_bits_opcode(auto_inner_ptw_to_l2_buffer_in_a_bits_opcode), .auto_inner_ptw_to_l2_buffer_in_a_bits_param(auto_inner_ptw_to_l2_buffer_in_a_bits_param), .auto_inner_ptw_to_l2_buffer_in_a_bits_size(auto_inner_ptw_to_l2_buffer_in_a_bits_size), .auto_inner_ptw_to_l2_buffer_in_a_bits_source(auto_inner_ptw_to_l2_buffer_in_a_bits_source), .auto_inner_ptw_to_l2_buffer_in_a_bits_address(auto_inner_ptw_to_l2_buffer_in_a_bits_address), .auto_inner_ptw_to_l2_buffer_in_a_bits_user_reqSource(auto_inner_ptw_to_l2_buffer_in_a_bits_user_reqSource), .auto_inner_ptw_to_l2_buffer_in_a_bits_mask(auto_inner_ptw_to_l2_buffer_in_a_bits_mask), .auto_inner_ptw_to_l2_buffer_in_a_bits_data(auto_inner_ptw_to_l2_buffer_in_a_bits_data), .auto_inner_ptw_to_l2_buffer_in_a_bits_corrupt(auto_inner_ptw_to_l2_buffer_in_a_bits_corrupt), .auto_inner_ptw_to_l2_buffer_in_d_ready(auto_inner_ptw_to_l2_buffer_in_d_ready), .auto_inner_ptw_to_l2_buffer_in_d_valid(i_auto_inner_ptw_to_l2_buffer_in_d_valid), .auto_inner_ptw_to_l2_buffer_in_d_bits_opcode(i_auto_inner_ptw_to_l2_buffer_in_d_bits_opcode), .auto_inner_ptw_to_l2_buffer_in_d_bits_param(i_auto_inner_ptw_to_l2_buffer_in_d_bits_param), .auto_inner_ptw_to_l2_buffer_in_d_bits_size(i_auto_inner_ptw_to_l2_buffer_in_d_bits_size), .auto_inner_ptw_to_l2_buffer_in_d_bits_source(i_auto_inner_ptw_to_l2_buffer_in_d_bits_source), .auto_inner_ptw_to_l2_buffer_in_d_bits_sink(i_auto_inner_ptw_to_l2_buffer_in_d_bits_sink), .auto_inner_ptw_to_l2_buffer_in_d_bits_denied(i_auto_inner_ptw_to_l2_buffer_in_d_bits_denied), .auto_inner_ptw_to_l2_buffer_in_d_bits_data(i_auto_inner_ptw_to_l2_buffer_in_d_bits_data), .auto_inner_ptw_to_l2_buffer_in_d_bits_corrupt(i_auto_inner_ptw_to_l2_buffer_in_d_bits_corrupt), .auto_inner_logger_in_1_a_ready(i_auto_inner_logger_in_1_a_ready), .auto_inner_logger_in_1_a_valid(auto_inner_logger_in_1_a_valid), .auto_inner_logger_in_1_a_bits_opcode(auto_inner_logger_in_1_a_bits_opcode), .auto_inner_logger_in_1_a_bits_param(auto_inner_logger_in_1_a_bits_param), .auto_inner_logger_in_1_a_bits_size(auto_inner_logger_in_1_a_bits_size), .auto_inner_logger_in_1_a_bits_source(auto_inner_logger_in_1_a_bits_source), .auto_inner_logger_in_1_a_bits_address(auto_inner_logger_in_1_a_bits_address), .auto_inner_logger_in_1_a_bits_user_alias(auto_inner_logger_in_1_a_bits_user_alias), .auto_inner_logger_in_1_a_bits_user_reqSource(auto_inner_logger_in_1_a_bits_user_reqSource), .auto_inner_logger_in_1_a_bits_user_needHint(auto_inner_logger_in_1_a_bits_user_needHint), .auto_inner_logger_in_1_a_bits_mask(auto_inner_logger_in_1_a_bits_mask), .auto_inner_logger_in_1_a_bits_data(auto_inner_logger_in_1_a_bits_data), .auto_inner_logger_in_1_a_bits_corrupt(auto_inner_logger_in_1_a_bits_corrupt), .auto_inner_logger_in_1_d_ready(auto_inner_logger_in_1_d_ready), .auto_inner_logger_in_1_d_valid(i_auto_inner_logger_in_1_d_valid), .auto_inner_logger_in_1_d_bits_opcode(i_auto_inner_logger_in_1_d_bits_opcode), .auto_inner_logger_in_1_d_bits_param(i_auto_inner_logger_in_1_d_bits_param), .auto_inner_logger_in_1_d_bits_size(i_auto_inner_logger_in_1_d_bits_size), .auto_inner_logger_in_1_d_bits_source(i_auto_inner_logger_in_1_d_bits_source), .auto_inner_logger_in_1_d_bits_sink(i_auto_inner_logger_in_1_d_bits_sink), .auto_inner_logger_in_1_d_bits_denied(i_auto_inner_logger_in_1_d_bits_denied), .auto_inner_logger_in_1_d_bits_data(i_auto_inner_logger_in_1_d_bits_data), .auto_inner_logger_in_1_d_bits_corrupt(i_auto_inner_logger_in_1_d_bits_corrupt), .auto_inner_logger_in_0_a_ready(i_auto_inner_logger_in_0_a_ready), .auto_inner_logger_in_0_a_valid(auto_inner_logger_in_0_a_valid), .auto_inner_logger_in_0_a_bits_opcode(auto_inner_logger_in_0_a_bits_opcode), .auto_inner_logger_in_0_a_bits_param(auto_inner_logger_in_0_a_bits_param), .auto_inner_logger_in_0_a_bits_size(auto_inner_logger_in_0_a_bits_size), .auto_inner_logger_in_0_a_bits_source(auto_inner_logger_in_0_a_bits_source), .auto_inner_logger_in_0_a_bits_address(auto_inner_logger_in_0_a_bits_address), .auto_inner_logger_in_0_a_bits_user_alias(auto_inner_logger_in_0_a_bits_user_alias), .auto_inner_logger_in_0_a_bits_user_vaddr(auto_inner_logger_in_0_a_bits_user_vaddr), .auto_inner_logger_in_0_a_bits_user_reqSource(auto_inner_logger_in_0_a_bits_user_reqSource), .auto_inner_logger_in_0_a_bits_user_needHint(auto_inner_logger_in_0_a_bits_user_needHint), .auto_inner_logger_in_0_a_bits_echo_isKeyword(auto_inner_logger_in_0_a_bits_echo_isKeyword), .auto_inner_logger_in_0_a_bits_mask(auto_inner_logger_in_0_a_bits_mask), .auto_inner_logger_in_0_a_bits_data(auto_inner_logger_in_0_a_bits_data), .auto_inner_logger_in_0_a_bits_corrupt(auto_inner_logger_in_0_a_bits_corrupt), .auto_inner_logger_in_0_b_ready(auto_inner_logger_in_0_b_ready), .auto_inner_logger_in_0_b_valid(i_auto_inner_logger_in_0_b_valid), .auto_inner_logger_in_0_b_bits_opcode(i_auto_inner_logger_in_0_b_bits_opcode), .auto_inner_logger_in_0_b_bits_param(i_auto_inner_logger_in_0_b_bits_param), .auto_inner_logger_in_0_b_bits_size(i_auto_inner_logger_in_0_b_bits_size), .auto_inner_logger_in_0_b_bits_source(i_auto_inner_logger_in_0_b_bits_source), .auto_inner_logger_in_0_b_bits_address(i_auto_inner_logger_in_0_b_bits_address), .auto_inner_logger_in_0_b_bits_mask(i_auto_inner_logger_in_0_b_bits_mask), .auto_inner_logger_in_0_b_bits_data(i_auto_inner_logger_in_0_b_bits_data), .auto_inner_logger_in_0_b_bits_corrupt(i_auto_inner_logger_in_0_b_bits_corrupt), .auto_inner_logger_in_0_c_ready(i_auto_inner_logger_in_0_c_ready), .auto_inner_logger_in_0_c_valid(auto_inner_logger_in_0_c_valid), .auto_inner_logger_in_0_c_bits_opcode(auto_inner_logger_in_0_c_bits_opcode), .auto_inner_logger_in_0_c_bits_param(auto_inner_logger_in_0_c_bits_param), .auto_inner_logger_in_0_c_bits_size(auto_inner_logger_in_0_c_bits_size), .auto_inner_logger_in_0_c_bits_source(auto_inner_logger_in_0_c_bits_source), .auto_inner_logger_in_0_c_bits_address(auto_inner_logger_in_0_c_bits_address), .auto_inner_logger_in_0_c_bits_user_alias(auto_inner_logger_in_0_c_bits_user_alias), .auto_inner_logger_in_0_c_bits_user_vaddr(auto_inner_logger_in_0_c_bits_user_vaddr), .auto_inner_logger_in_0_c_bits_user_reqSource(auto_inner_logger_in_0_c_bits_user_reqSource), .auto_inner_logger_in_0_c_bits_user_needHint(auto_inner_logger_in_0_c_bits_user_needHint), .auto_inner_logger_in_0_c_bits_echo_isKeyword(auto_inner_logger_in_0_c_bits_echo_isKeyword), .auto_inner_logger_in_0_c_bits_data(auto_inner_logger_in_0_c_bits_data), .auto_inner_logger_in_0_c_bits_corrupt(auto_inner_logger_in_0_c_bits_corrupt), .auto_inner_logger_in_0_d_ready(auto_inner_logger_in_0_d_ready), .auto_inner_logger_in_0_d_valid(i_auto_inner_logger_in_0_d_valid), .auto_inner_logger_in_0_d_bits_opcode(i_auto_inner_logger_in_0_d_bits_opcode), .auto_inner_logger_in_0_d_bits_param(i_auto_inner_logger_in_0_d_bits_param), .auto_inner_logger_in_0_d_bits_size(i_auto_inner_logger_in_0_d_bits_size), .auto_inner_logger_in_0_d_bits_source(i_auto_inner_logger_in_0_d_bits_source), .auto_inner_logger_in_0_d_bits_sink(i_auto_inner_logger_in_0_d_bits_sink), .auto_inner_logger_in_0_d_bits_denied(i_auto_inner_logger_in_0_d_bits_denied), .auto_inner_logger_in_0_d_bits_echo_isKeyword(i_auto_inner_logger_in_0_d_bits_echo_isKeyword), .auto_inner_logger_in_0_d_bits_data(i_auto_inner_logger_in_0_d_bits_data), .auto_inner_logger_in_0_d_bits_corrupt(i_auto_inner_logger_in_0_d_bits_corrupt), .auto_inner_logger_in_0_e_ready(i_auto_inner_logger_in_0_e_ready), .auto_inner_logger_in_0_e_valid(auto_inner_logger_in_0_e_valid), .auto_inner_logger_in_0_e_bits_sink(auto_inner_logger_in_0_e_bits_sink), .auto_inner_beu_int_out_0(i_auto_inner_beu_int_out_0), .auto_inner_beu_local_int_source_out_0(i_auto_inner_beu_local_int_source_out_0), .auto_inner_nmi_int_in_0(auto_inner_nmi_int_in_0), .auto_inner_nmi_int_in_1(auto_inner_nmi_int_in_1), .auto_inner_nmi_int_out_0(i_auto_inner_nmi_int_out_0), .auto_inner_nmi_int_out_1(i_auto_inner_nmi_int_out_1), .auto_inner_plic_int_in_1_0(auto_inner_plic_int_in_1_0), .auto_inner_plic_int_in_0_0(auto_inner_plic_int_in_0_0), .auto_inner_plic_int_out_1_0(i_auto_inner_plic_int_out_1_0), .auto_inner_plic_int_out_0_0(i_auto_inner_plic_int_out_0_0), .auto_inner_debug_int_in_0(auto_inner_debug_int_in_0), .auto_inner_debug_int_out_0(i_auto_inner_debug_int_out_0), .auto_inner_clint_int_in_0(auto_inner_clint_int_in_0), .auto_inner_clint_int_in_1(auto_inner_clint_int_in_1), .auto_inner_clint_int_out_0(i_auto_inner_clint_int_out_0), .auto_inner_clint_int_out_1(i_auto_inner_clint_int_out_1), .io_beu_errors_icache_ecc_error_valid(io_beu_errors_icache_ecc_error_valid), .io_beu_errors_icache_ecc_error_bits(io_beu_errors_icache_ecc_error_bits), .io_beu_errors_dcache_ecc_error_valid(io_beu_errors_dcache_ecc_error_valid), .io_beu_errors_dcache_ecc_error_bits(io_beu_errors_dcache_ecc_error_bits), .io_beu_errors_uncache_ecc_error_valid(io_beu_errors_uncache_ecc_error_valid), .io_beu_errors_uncache_ecc_error_bits(io_beu_errors_uncache_ecc_error_bits), .io_reset_vector_fromTile(io_reset_vector_fromTile), .io_reset_vector_toCore(i_io_reset_vector_toCore), .io_hartId_fromTile(io_hartId_fromTile), .io_hartId_toCore(i_io_hartId_toCore), .io_msiInfo_fromTile_valid(io_msiInfo_fromTile_valid), .io_msiInfo_fromTile_bits(io_msiInfo_fromTile_bits), .io_msiInfo_toCore_valid(i_io_msiInfo_toCore_valid), .io_msiInfo_toCore_bits(i_io_msiInfo_toCore_bits), .io_cpu_halt_fromCore(io_cpu_halt_fromCore), .io_cpu_halt_toTile(i_io_cpu_halt_toTile), .io_cpu_critical_error_fromCore(io_cpu_critical_error_fromCore), .io_cpu_critical_error_toTile(i_io_cpu_critical_error_toTile), .io_hartIsInReset_resetInFrontend(io_hartIsInReset_resetInFrontend), .io_hartIsInReset_toTile(i_io_hartIsInReset_toTile), .io_traceCoreInterface_fromCore_fromEncoder_enable(i_io_traceCoreInterface_fromCore_fromEncoder_enable), .io_traceCoreInterface_fromCore_fromEncoder_stall(i_io_traceCoreInterface_fromCore_fromEncoder_stall), .io_traceCoreInterface_fromCore_toEncoder_priv(io_traceCoreInterface_fromCore_toEncoder_priv), .io_traceCoreInterface_fromCore_toEncoder_trap_cause(io_traceCoreInterface_fromCore_toEncoder_trap_cause), .io_traceCoreInterface_fromCore_toEncoder_trap_tval(io_traceCoreInterface_fromCore_toEncoder_trap_tval), .io_traceCoreInterface_fromCore_toEncoder_groups_0_valid(io_traceCoreInterface_fromCore_toEncoder_groups_0_valid), .io_traceCoreInterface_fromCore_toEncoder_groups_0_bits_iaddr(io_traceCoreInterface_fromCore_toEncoder_groups_0_bits_iaddr), .io_traceCoreInterface_fromCore_toEncoder_groups_0_bits_itype(io_traceCoreInterface_fromCore_toEncoder_groups_0_bits_itype), .io_traceCoreInterface_fromCore_toEncoder_groups_0_bits_iretire(io_traceCoreInterface_fromCore_toEncoder_groups_0_bits_iretire), .io_traceCoreInterface_fromCore_toEncoder_groups_0_bits_ilastsize(io_traceCoreInterface_fromCore_toEncoder_groups_0_bits_ilastsize), .io_traceCoreInterface_fromCore_toEncoder_groups_1_valid(io_traceCoreInterface_fromCore_toEncoder_groups_1_valid), .io_traceCoreInterface_fromCore_toEncoder_groups_1_bits_iaddr(io_traceCoreInterface_fromCore_toEncoder_groups_1_bits_iaddr), .io_traceCoreInterface_fromCore_toEncoder_groups_1_bits_itype(io_traceCoreInterface_fromCore_toEncoder_groups_1_bits_itype), .io_traceCoreInterface_fromCore_toEncoder_groups_1_bits_iretire(io_traceCoreInterface_fromCore_toEncoder_groups_1_bits_iretire), .io_traceCoreInterface_fromCore_toEncoder_groups_1_bits_ilastsize(io_traceCoreInterface_fromCore_toEncoder_groups_1_bits_ilastsize), .io_traceCoreInterface_fromCore_toEncoder_groups_2_valid(io_traceCoreInterface_fromCore_toEncoder_groups_2_valid), .io_traceCoreInterface_fromCore_toEncoder_groups_2_bits_iaddr(io_traceCoreInterface_fromCore_toEncoder_groups_2_bits_iaddr), .io_traceCoreInterface_fromCore_toEncoder_groups_2_bits_itype(io_traceCoreInterface_fromCore_toEncoder_groups_2_bits_itype), .io_traceCoreInterface_fromCore_toEncoder_groups_2_bits_iretire(io_traceCoreInterface_fromCore_toEncoder_groups_2_bits_iretire), .io_traceCoreInterface_fromCore_toEncoder_groups_2_bits_ilastsize(io_traceCoreInterface_fromCore_toEncoder_groups_2_bits_ilastsize), .io_traceCoreInterface_toTile_fromEncoder_enable(io_traceCoreInterface_toTile_fromEncoder_enable), .io_traceCoreInterface_toTile_fromEncoder_stall(io_traceCoreInterface_toTile_fromEncoder_stall), .io_traceCoreInterface_toTile_toEncoder_priv(i_io_traceCoreInterface_toTile_toEncoder_priv), .io_traceCoreInterface_toTile_toEncoder_trap_cause(i_io_traceCoreInterface_toTile_toEncoder_trap_cause), .io_traceCoreInterface_toTile_toEncoder_trap_tval(i_io_traceCoreInterface_toTile_toEncoder_trap_tval), .io_traceCoreInterface_toTile_toEncoder_groups_0_bits_iaddr(i_io_traceCoreInterface_toTile_toEncoder_groups_0_bits_iaddr), .io_traceCoreInterface_toTile_toEncoder_groups_0_bits_itype(i_io_traceCoreInterface_toTile_toEncoder_groups_0_bits_itype), .io_traceCoreInterface_toTile_toEncoder_groups_0_bits_iretire(i_io_traceCoreInterface_toTile_toEncoder_groups_0_bits_iretire), .io_traceCoreInterface_toTile_toEncoder_groups_0_bits_ilastsize(i_io_traceCoreInterface_toTile_toEncoder_groups_0_bits_ilastsize), .io_traceCoreInterface_toTile_toEncoder_groups_1_bits_iaddr(i_io_traceCoreInterface_toTile_toEncoder_groups_1_bits_iaddr), .io_traceCoreInterface_toTile_toEncoder_groups_1_bits_itype(i_io_traceCoreInterface_toTile_toEncoder_groups_1_bits_itype), .io_traceCoreInterface_toTile_toEncoder_groups_1_bits_iretire(i_io_traceCoreInterface_toTile_toEncoder_groups_1_bits_iretire), .io_traceCoreInterface_toTile_toEncoder_groups_1_bits_ilastsize(i_io_traceCoreInterface_toTile_toEncoder_groups_1_bits_ilastsize), .io_traceCoreInterface_toTile_toEncoder_groups_2_bits_iaddr(i_io_traceCoreInterface_toTile_toEncoder_groups_2_bits_iaddr), .io_traceCoreInterface_toTile_toEncoder_groups_2_bits_itype(i_io_traceCoreInterface_toTile_toEncoder_groups_2_bits_itype), .io_traceCoreInterface_toTile_toEncoder_groups_2_bits_iretire(i_io_traceCoreInterface_toTile_toEncoder_groups_2_bits_iretire), .io_traceCoreInterface_toTile_toEncoder_groups_2_bits_ilastsize(i_io_traceCoreInterface_toTile_toEncoder_groups_2_bits_ilastsize), .io_debugTopDown_robHeadPaddr_valid(io_debugTopDown_robHeadPaddr_valid), .io_debugTopDown_robHeadPaddr_bits(io_debugTopDown_robHeadPaddr_bits), .io_debugTopDown_l2MissMatch(i_io_debugTopDown_l2MissMatch), .io_l2Miss(i_io_l2Miss), .io_l3Miss_fromTile(io_l3Miss_fromTile), .io_l3Miss_toCore(i_io_l3Miss_toCore), .io_clintTime_fromTile_valid(io_clintTime_fromTile_valid), .io_clintTime_fromTile_bits(io_clintTime_fromTile_bits), .io_clintTime_toCore_valid(i_io_clintTime_toCore_valid), .io_clintTime_toCore_bits(i_io_clintTime_toCore_bits), .io_chi_txsactive(i_io_chi_txsactive), .io_chi_rxsactive(io_chi_rxsactive), .io_chi_syscoreq(i_io_chi_syscoreq), .io_chi_syscoack(io_chi_syscoack), .io_chi_tx_linkactivereq(i_io_chi_tx_linkactivereq), .io_chi_tx_linkactiveack(io_chi_tx_linkactiveack), .io_chi_tx_req_flitpend(i_io_chi_tx_req_flitpend), .io_chi_tx_req_flitv(i_io_chi_tx_req_flitv), .io_chi_tx_req_flit(i_io_chi_tx_req_flit), .io_chi_tx_req_lcrdv(io_chi_tx_req_lcrdv), .io_chi_tx_rsp_flitpend(i_io_chi_tx_rsp_flitpend), .io_chi_tx_rsp_flitv(i_io_chi_tx_rsp_flitv), .io_chi_tx_rsp_flit(i_io_chi_tx_rsp_flit), .io_chi_tx_rsp_lcrdv(io_chi_tx_rsp_lcrdv), .io_chi_tx_dat_flitpend(i_io_chi_tx_dat_flitpend), .io_chi_tx_dat_flitv(i_io_chi_tx_dat_flitv), .io_chi_tx_dat_flit(i_io_chi_tx_dat_flit), .io_chi_tx_dat_lcrdv(io_chi_tx_dat_lcrdv), .io_chi_rx_linkactivereq(io_chi_rx_linkactivereq), .io_chi_rx_linkactiveack(i_io_chi_rx_linkactiveack), .io_chi_rx_rsp_flitpend(io_chi_rx_rsp_flitpend), .io_chi_rx_rsp_flitv(io_chi_rx_rsp_flitv), .io_chi_rx_rsp_flit(io_chi_rx_rsp_flit), .io_chi_rx_rsp_lcrdv(i_io_chi_rx_rsp_lcrdv), .io_chi_rx_dat_flitpend(io_chi_rx_dat_flitpend), .io_chi_rx_dat_flitv(io_chi_rx_dat_flitv), .io_chi_rx_dat_flit(io_chi_rx_dat_flit), .io_chi_rx_dat_lcrdv(i_io_chi_rx_dat_lcrdv), .io_chi_rx_snp_flitpend(io_chi_rx_snp_flitpend), .io_chi_rx_snp_flitv(io_chi_rx_snp_flitv), .io_chi_rx_snp_flit(io_chi_rx_snp_flit), .io_chi_rx_snp_lcrdv(i_io_chi_rx_snp_lcrdv), .io_nodeID(io_nodeID), .io_pfCtrlFromCore_l2_pf_master_en(io_pfCtrlFromCore_l2_pf_master_en), .io_pfCtrlFromCore_l2_pf_recv_en(io_pfCtrlFromCore_l2_pf_recv_en), .io_pfCtrlFromCore_l2_pbop_en(io_pfCtrlFromCore_l2_pbop_en), .io_pfCtrlFromCore_l2_vbop_en(io_pfCtrlFromCore_l2_vbop_en), .io_l2_tlb_req_req_valid(i_io_l2_tlb_req_req_valid), .io_l2_tlb_req_req_bits_vaddr(i_io_l2_tlb_req_req_bits_vaddr), .io_l2_tlb_req_req_bits_cmd(i_io_l2_tlb_req_req_bits_cmd), .io_l2_tlb_req_req_bits_kill(i_io_l2_tlb_req_req_bits_kill), .io_l2_tlb_req_req_bits_no_translate(i_io_l2_tlb_req_req_bits_no_translate), .io_l2_tlb_req_resp_valid(io_l2_tlb_req_resp_valid), .io_l2_tlb_req_resp_bits_paddr_0(io_l2_tlb_req_resp_bits_paddr_0), .io_l2_tlb_req_resp_bits_pbmt_0(io_l2_tlb_req_resp_bits_pbmt_0), .io_l2_tlb_req_resp_bits_miss(io_l2_tlb_req_resp_bits_miss), .io_l2_tlb_req_resp_bits_excp_0_gpf_ld(io_l2_tlb_req_resp_bits_excp_0_gpf_ld), .io_l2_tlb_req_resp_bits_excp_0_pf_ld(io_l2_tlb_req_resp_bits_excp_0_pf_ld), .io_l2_tlb_req_resp_bits_excp_0_af_ld(io_l2_tlb_req_resp_bits_excp_0_af_ld), .io_l2_pmp_resp_ld(io_l2_pmp_resp_ld), .io_l2_pmp_resp_mmio(io_l2_pmp_resp_mmio), .io_l2_hint_valid(i_io_l2_hint_valid), .io_l2_hint_bits_sourceId(i_io_l2_hint_bits_sourceId), .io_l2_hint_bits_isKeyword(i_io_l2_hint_bits_isKeyword), .io_perfEvents_1_value(i_io_perfEvents_1_value), .io_perfEvents_2_value(i_io_perfEvents_2_value), .io_perfEvents_3_value(i_io_perfEvents_3_value), .io_perfEvents_4_value(i_io_perfEvents_4_value), .io_perfEvents_5_value(i_io_perfEvents_5_value), .io_perfEvents_6_value(i_io_perfEvents_6_value), .io_perfEvents_7_value(i_io_perfEvents_7_value), .io_perfEvents_8_value(i_io_perfEvents_8_value), .io_perfEvents_9_value(i_io_perfEvents_9_value), .io_perfEvents_10_value(i_io_perfEvents_10_value), .io_perfEvents_11_value(i_io_perfEvents_11_value), .io_perfEvents_12_value(i_io_perfEvents_12_value), .io_perfEvents_13_value(i_io_perfEvents_13_value), .io_perfEvents_14_value(i_io_perfEvents_14_value), .io_perfEvents_15_value(i_io_perfEvents_15_value), .io_perfEvents_16_value(i_io_perfEvents_16_value), .io_perfEvents_17_value(i_io_perfEvents_17_value), .io_perfEvents_18_value(i_io_perfEvents_18_value), .io_perfEvents_19_value(i_io_perfEvents_19_value), .io_perfEvents_20_value(i_io_perfEvents_20_value), .io_perfEvents_21_value(i_io_perfEvents_21_value), .io_perfEvents_22_value(i_io_perfEvents_22_value), .io_perfEvents_23_value(i_io_perfEvents_23_value), .io_perfEvents_24_value(i_io_perfEvents_24_value), .io_perfEvents_25_value(i_io_perfEvents_25_value), .io_perfEvents_26_value(i_io_perfEvents_26_value), .io_perfEvents_27_value(i_io_perfEvents_27_value), .io_perfEvents_28_value(i_io_perfEvents_28_value), .io_perfEvents_29_value(i_io_perfEvents_29_value), .io_perfEvents_30_value(i_io_perfEvents_30_value), .io_perfEvents_31_value(i_io_perfEvents_31_value), .io_perfEvents_32_value(i_io_perfEvents_32_value), .io_perfEvents_33_value(i_io_perfEvents_33_value), .io_perfEvents_34_value(i_io_perfEvents_34_value), .io_perfEvents_35_value(i_io_perfEvents_35_value), .io_perfEvents_36_value(i_io_perfEvents_36_value), .io_perfEvents_37_value(i_io_perfEvents_37_value), .io_perfEvents_38_value(i_io_perfEvents_38_value), .io_perfEvents_39_value(i_io_perfEvents_39_value), .io_perfEvents_40_value(i_io_perfEvents_40_value), .io_perfEvents_41_value(i_io_perfEvents_41_value), .io_perfEvents_42_value(i_io_perfEvents_42_value), .io_perfEvents_43_value(i_io_perfEvents_43_value), .io_perfEvents_44_value(i_io_perfEvents_44_value), .io_perfEvents_45_value(i_io_perfEvents_45_value), .io_perfEvents_46_value(i_io_perfEvents_46_value), .io_perfEvents_47_value(i_io_perfEvents_47_value), .io_perfEvents_48_value(i_io_perfEvents_48_value), .io_dft_ram_hold(io_dft_ram_hold), .io_dft_ram_bypass(io_dft_ram_bypass), .io_dft_ram_bp_clken(io_dft_ram_bp_clken), .io_dft_ram_aux_clk(io_dft_ram_aux_clk), .io_dft_ram_aux_ckbp(io_dft_ram_aux_ckbp), .io_dft_ram_mcp_hold(io_dft_ram_mcp_hold), .io_dft_cgen(io_dft_cgen));

  bit reported [0:181];
  int distinct_div = 0;

  always @(negedge clk) begin
    if (rst) begin
      auto_inner_buffers_out_a_ready <= 1'b0;
      auto_inner_buffers_out_d_valid <= 1'b0;
      auto_inner_buffers_in_a_valid <= 1'b0;
      auto_inner_buffers_in_d_ready <= 1'b0;
      auto_inner_l2cache_pf_recv_in_addr_valid <= 1'b0;
      auto_inner_i_mmio_buffer_in_a_valid <= 1'b0;
      auto_inner_i_mmio_buffer_in_d_ready <= 1'b0;
      auto_inner_ptw_to_l2_buffer_in_a_valid <= 1'b0;
      auto_inner_ptw_to_l2_buffer_in_d_ready <= 1'b0;
      auto_inner_logger_in_1_a_valid <= 1'b0;
      auto_inner_logger_in_1_d_ready <= 1'b0;
      auto_inner_logger_in_0_a_valid <= 1'b0;
      auto_inner_logger_in_0_b_ready <= 1'b0;
      auto_inner_logger_in_0_c_valid <= 1'b0;
      auto_inner_logger_in_0_d_ready <= 1'b0;
      auto_inner_logger_in_0_e_valid <= 1'b0;
      io_beu_errors_icache_ecc_error_valid <= 1'b0;
      io_beu_errors_dcache_ecc_error_valid <= 1'b0;
      io_beu_errors_uncache_ecc_error_valid <= 1'b0;
      io_msiInfo_fromTile_valid <= 1'b0;
      io_traceCoreInterface_fromCore_toEncoder_groups_0_valid <= 1'b0;
      io_traceCoreInterface_fromCore_toEncoder_groups_1_valid <= 1'b0;
      io_traceCoreInterface_fromCore_toEncoder_groups_2_valid <= 1'b0;
      io_debugTopDown_robHeadPaddr_valid <= 1'b0;
      io_clintTime_fromTile_valid <= 1'b0;
      io_l2_tlb_req_resp_valid <= 1'b0;
    end else begin
      auto_inner_buffers_out_a_ready <= $urandom_range(0,1);
      auto_inner_buffers_out_d_valid <= $urandom_range(0,1);
      auto_inner_buffers_out_d_bits_opcode <= 4'($urandom);
      auto_inner_buffers_out_d_bits_param <= 2'($urandom);
      auto_inner_buffers_out_d_bits_size <= 2'($urandom);
      auto_inner_buffers_out_d_bits_source <= 3'($urandom);
      auto_inner_buffers_out_d_bits_sink <= $urandom_range(0,1);
      auto_inner_buffers_out_d_bits_denied <= $urandom_range(0,1);
      auto_inner_buffers_out_d_bits_data <= {$urandom(), $urandom()};
      auto_inner_buffers_out_d_bits_corrupt <= $urandom_range(0,1);
      auto_inner_buffers_in_a_valid <= $urandom_range(0,1);
      auto_inner_buffers_in_a_bits_opcode <= 4'($urandom);
      auto_inner_buffers_in_a_bits_param <= 3'($urandom);
      auto_inner_buffers_in_a_bits_size <= 2'($urandom);
      auto_inner_buffers_in_a_bits_source <= 2'($urandom);
      auto_inner_buffers_in_a_bits_address <= {$urandom(), $urandom()};
      auto_inner_buffers_in_a_bits_user_memBackType_MM <= $urandom_range(0,1);
      auto_inner_buffers_in_a_bits_user_memPageType_NC <= $urandom_range(0,1);
      auto_inner_buffers_in_a_bits_mask <= 8'($urandom);
      auto_inner_buffers_in_a_bits_data <= {$urandom(), $urandom()};
      auto_inner_buffers_in_a_bits_corrupt <= $urandom_range(0,1);
      auto_inner_buffers_in_d_ready <= $urandom_range(0,1);
      auto_inner_l2cache_pf_recv_in_addr <= {$urandom(), $urandom()};
      auto_inner_l2cache_pf_recv_in_pf_source <= 5'($urandom);
      auto_inner_l2cache_pf_recv_in_addr_valid <= $urandom_range(0,1);
      auto_inner_i_mmio_buffer_in_a_valid <= $urandom_range(0,1);
      auto_inner_i_mmio_buffer_in_a_bits_param <= 3'($urandom);
      auto_inner_i_mmio_buffer_in_a_bits_address <= {$urandom(), $urandom()};
      auto_inner_i_mmio_buffer_in_a_bits_corrupt <= $urandom_range(0,1);
      auto_inner_i_mmio_buffer_in_d_ready <= $urandom_range(0,1);
      auto_inner_ptw_to_l2_buffer_in_a_valid <= $urandom_range(0,1);
      auto_inner_ptw_to_l2_buffer_in_a_bits_opcode <= 4'($urandom);
      auto_inner_ptw_to_l2_buffer_in_a_bits_param <= 3'($urandom);
      auto_inner_ptw_to_l2_buffer_in_a_bits_size <= 3'($urandom);
      auto_inner_ptw_to_l2_buffer_in_a_bits_source <= 3'($urandom);
      auto_inner_ptw_to_l2_buffer_in_a_bits_address <= {$urandom(), $urandom()};
      auto_inner_ptw_to_l2_buffer_in_a_bits_user_reqSource <= 5'($urandom);
      auto_inner_ptw_to_l2_buffer_in_a_bits_mask <= 32'($urandom);
      auto_inner_ptw_to_l2_buffer_in_a_bits_data <= {$urandom(), $urandom(), $urandom(), $urandom(), $urandom(), $urandom(), $urandom(), $urandom()};
      auto_inner_ptw_to_l2_buffer_in_a_bits_corrupt <= $urandom_range(0,1);
      auto_inner_ptw_to_l2_buffer_in_d_ready <= $urandom_range(0,1);
      auto_inner_logger_in_1_a_valid <= $urandom_range(0,1);
      auto_inner_logger_in_1_a_bits_opcode <= 4'($urandom);
      auto_inner_logger_in_1_a_bits_param <= 3'($urandom);
      auto_inner_logger_in_1_a_bits_size <= 3'($urandom);
      auto_inner_logger_in_1_a_bits_source <= 4'($urandom);
      auto_inner_logger_in_1_a_bits_address <= {$urandom(), $urandom()};
      auto_inner_logger_in_1_a_bits_user_alias <= 2'($urandom);
      auto_inner_logger_in_1_a_bits_user_reqSource <= 5'($urandom);
      auto_inner_logger_in_1_a_bits_user_needHint <= $urandom_range(0,1);
      auto_inner_logger_in_1_a_bits_mask <= 32'($urandom);
      auto_inner_logger_in_1_a_bits_data <= {$urandom(), $urandom(), $urandom(), $urandom(), $urandom(), $urandom(), $urandom(), $urandom()};
      auto_inner_logger_in_1_a_bits_corrupt <= $urandom_range(0,1);
      auto_inner_logger_in_1_d_ready <= $urandom_range(0,1);
      auto_inner_logger_in_0_a_valid <= $urandom_range(0,1);
      auto_inner_logger_in_0_a_bits_opcode <= 4'($urandom);
      auto_inner_logger_in_0_a_bits_param <= 3'($urandom);
      auto_inner_logger_in_0_a_bits_size <= 3'($urandom);
      auto_inner_logger_in_0_a_bits_source <= 6'($urandom);
      auto_inner_logger_in_0_a_bits_address <= {$urandom(), $urandom()};
      auto_inner_logger_in_0_a_bits_user_alias <= 2'($urandom);
      auto_inner_logger_in_0_a_bits_user_vaddr <= {$urandom(), $urandom()};
      auto_inner_logger_in_0_a_bits_user_reqSource <= 5'($urandom);
      auto_inner_logger_in_0_a_bits_user_needHint <= $urandom_range(0,1);
      auto_inner_logger_in_0_a_bits_echo_isKeyword <= $urandom_range(0,1);
      auto_inner_logger_in_0_a_bits_mask <= 32'($urandom);
      auto_inner_logger_in_0_a_bits_data <= {$urandom(), $urandom(), $urandom(), $urandom(), $urandom(), $urandom(), $urandom(), $urandom()};
      auto_inner_logger_in_0_a_bits_corrupt <= $urandom_range(0,1);
      auto_inner_logger_in_0_b_ready <= $urandom_range(0,1);
      auto_inner_logger_in_0_c_valid <= $urandom_range(0,1);
      auto_inner_logger_in_0_c_bits_opcode <= 3'($urandom);
      auto_inner_logger_in_0_c_bits_param <= 3'($urandom);
      auto_inner_logger_in_0_c_bits_size <= 3'($urandom);
      auto_inner_logger_in_0_c_bits_source <= 6'($urandom);
      auto_inner_logger_in_0_c_bits_address <= {$urandom(), $urandom()};
      auto_inner_logger_in_0_c_bits_user_alias <= 2'($urandom);
      auto_inner_logger_in_0_c_bits_user_vaddr <= {$urandom(), $urandom()};
      auto_inner_logger_in_0_c_bits_user_reqSource <= 5'($urandom);
      auto_inner_logger_in_0_c_bits_user_needHint <= $urandom_range(0,1);
      auto_inner_logger_in_0_c_bits_echo_isKeyword <= $urandom_range(0,1);
      auto_inner_logger_in_0_c_bits_data <= {$urandom(), $urandom(), $urandom(), $urandom(), $urandom(), $urandom(), $urandom(), $urandom()};
      auto_inner_logger_in_0_c_bits_corrupt <= $urandom_range(0,1);
      auto_inner_logger_in_0_d_ready <= $urandom_range(0,1);
      auto_inner_logger_in_0_e_valid <= $urandom_range(0,1);
      auto_inner_logger_in_0_e_bits_sink <= 10'($urandom);
      auto_inner_nmi_int_in_0 <= $urandom_range(0,1);
      auto_inner_nmi_int_in_1 <= $urandom_range(0,1);
      auto_inner_plic_int_in_1_0 <= $urandom_range(0,1);
      auto_inner_plic_int_in_0_0 <= $urandom_range(0,1);
      auto_inner_debug_int_in_0 <= $urandom_range(0,1);
      auto_inner_clint_int_in_0 <= $urandom_range(0,1);
      auto_inner_clint_int_in_1 <= $urandom_range(0,1);
      io_beu_errors_icache_ecc_error_valid <= $urandom_range(0,1);
      io_beu_errors_icache_ecc_error_bits <= {$urandom(), $urandom()};
      io_beu_errors_dcache_ecc_error_valid <= $urandom_range(0,1);
      io_beu_errors_dcache_ecc_error_bits <= {$urandom(), $urandom()};
      io_beu_errors_uncache_ecc_error_valid <= $urandom_range(0,1);
      io_beu_errors_uncache_ecc_error_bits <= {$urandom(), $urandom()};
      io_reset_vector_fromTile <= {$urandom(), $urandom()};
      io_hartId_fromTile <= {$urandom(), $urandom()};
      io_msiInfo_fromTile_valid <= $urandom_range(0,1);
      io_msiInfo_fromTile_bits <= 11'($urandom);
      io_cpu_halt_fromCore <= $urandom_range(0,1);
      io_cpu_critical_error_fromCore <= $urandom_range(0,1);
      io_hartIsInReset_resetInFrontend <= $urandom_range(0,1);
      io_traceCoreInterface_fromCore_toEncoder_priv <= 3'($urandom);
      io_traceCoreInterface_fromCore_toEncoder_trap_cause <= {$urandom(), $urandom()};
      io_traceCoreInterface_fromCore_toEncoder_trap_tval <= {$urandom(), $urandom()};
      io_traceCoreInterface_fromCore_toEncoder_groups_0_valid <= $urandom_range(0,1);
      io_traceCoreInterface_fromCore_toEncoder_groups_0_bits_iaddr <= {$urandom(), $urandom()};
      io_traceCoreInterface_fromCore_toEncoder_groups_0_bits_itype <= 4'($urandom);
      io_traceCoreInterface_fromCore_toEncoder_groups_0_bits_iretire <= 7'($urandom);
      io_traceCoreInterface_fromCore_toEncoder_groups_0_bits_ilastsize <= $urandom_range(0,1);
      io_traceCoreInterface_fromCore_toEncoder_groups_1_valid <= $urandom_range(0,1);
      io_traceCoreInterface_fromCore_toEncoder_groups_1_bits_iaddr <= {$urandom(), $urandom()};
      io_traceCoreInterface_fromCore_toEncoder_groups_1_bits_itype <= 4'($urandom);
      io_traceCoreInterface_fromCore_toEncoder_groups_1_bits_iretire <= 7'($urandom);
      io_traceCoreInterface_fromCore_toEncoder_groups_1_bits_ilastsize <= $urandom_range(0,1);
      io_traceCoreInterface_fromCore_toEncoder_groups_2_valid <= $urandom_range(0,1);
      io_traceCoreInterface_fromCore_toEncoder_groups_2_bits_iaddr <= {$urandom(), $urandom()};
      io_traceCoreInterface_fromCore_toEncoder_groups_2_bits_itype <= 4'($urandom);
      io_traceCoreInterface_fromCore_toEncoder_groups_2_bits_iretire <= 7'($urandom);
      io_traceCoreInterface_fromCore_toEncoder_groups_2_bits_ilastsize <= $urandom_range(0,1);
      io_traceCoreInterface_toTile_fromEncoder_enable <= $urandom_range(0,1);
      io_traceCoreInterface_toTile_fromEncoder_stall <= $urandom_range(0,1);
      io_debugTopDown_robHeadPaddr_valid <= $urandom_range(0,1);
      io_debugTopDown_robHeadPaddr_bits <= {$urandom(), $urandom()};
      io_l3Miss_fromTile <= $urandom_range(0,1);
      io_clintTime_fromTile_valid <= $urandom_range(0,1);
      io_clintTime_fromTile_bits <= {$urandom(), $urandom()};
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
      io_pfCtrlFromCore_l2_pf_master_en <= $urandom_range(0,1);
      io_pfCtrlFromCore_l2_pf_recv_en <= $urandom_range(0,1);
      io_pfCtrlFromCore_l2_pbop_en <= $urandom_range(0,1);
      io_pfCtrlFromCore_l2_vbop_en <= $urandom_range(0,1);
      io_l2_tlb_req_resp_valid <= $urandom_range(0,1);
      io_l2_tlb_req_resp_bits_paddr_0 <= {$urandom(), $urandom()};
      io_l2_tlb_req_resp_bits_pbmt_0 <= 2'($urandom);
      io_l2_tlb_req_resp_bits_miss <= $urandom_range(0,1);
      io_l2_tlb_req_resp_bits_excp_0_gpf_ld <= $urandom_range(0,1);
      io_l2_tlb_req_resp_bits_excp_0_pf_ld <= $urandom_range(0,1);
      io_l2_tlb_req_resp_bits_excp_0_af_ld <= $urandom_range(0,1);
      io_l2_pmp_resp_ld <= $urandom_range(0,1);
      io_l2_pmp_resp_mmio <= $urandom_range(0,1);
      io_dft_ram_hold <= $urandom_range(0,1);
      io_dft_ram_bypass <= $urandom_range(0,1);
      io_dft_ram_bp_clken <= $urandom_range(0,1);
      io_dft_ram_aux_clk <= $urandom_range(0,1);
      io_dft_ram_aux_ckbp <= $urandom_range(0,1);
      io_dft_ram_mcp_hold <= $urandom_range(0,1);
      io_dft_cgen <= $urandom_range(0,1);
    end
  end

  always @(negedge clk) if (!rst) begin
    #4; checks++;
    if (!$isunknown(g_auto_inner_buffers_out_a_valid) && g_auto_inner_buffers_out_a_valid !== i_auto_inner_buffers_out_a_valid) begin errors++;
      if(!reported[0]) begin reported[0]=1; distinct_div++;
        $display("[DIV %0t] auto_inner_buffers_out_a_valid g=%h i=%h", $time, g_auto_inner_buffers_out_a_valid, i_auto_inner_buffers_out_a_valid); end end
    if (!$isunknown(g_auto_inner_buffers_out_a_bits_opcode) && g_auto_inner_buffers_out_a_bits_opcode !== i_auto_inner_buffers_out_a_bits_opcode) begin errors++;
      if(!reported[1]) begin reported[1]=1; distinct_div++;
        $display("[DIV %0t] auto_inner_buffers_out_a_bits_opcode g=%h i=%h", $time, g_auto_inner_buffers_out_a_bits_opcode, i_auto_inner_buffers_out_a_bits_opcode); end end
    if (!$isunknown(g_auto_inner_buffers_out_a_bits_param) && g_auto_inner_buffers_out_a_bits_param !== i_auto_inner_buffers_out_a_bits_param) begin errors++;
      if(!reported[2]) begin reported[2]=1; distinct_div++;
        $display("[DIV %0t] auto_inner_buffers_out_a_bits_param g=%h i=%h", $time, g_auto_inner_buffers_out_a_bits_param, i_auto_inner_buffers_out_a_bits_param); end end
    if (!$isunknown(g_auto_inner_buffers_out_a_bits_size) && g_auto_inner_buffers_out_a_bits_size !== i_auto_inner_buffers_out_a_bits_size) begin errors++;
      if(!reported[3]) begin reported[3]=1; distinct_div++;
        $display("[DIV %0t] auto_inner_buffers_out_a_bits_size g=%h i=%h", $time, g_auto_inner_buffers_out_a_bits_size, i_auto_inner_buffers_out_a_bits_size); end end
    if (!$isunknown(g_auto_inner_buffers_out_a_bits_source) && g_auto_inner_buffers_out_a_bits_source !== i_auto_inner_buffers_out_a_bits_source) begin errors++;
      if(!reported[4]) begin reported[4]=1; distinct_div++;
        $display("[DIV %0t] auto_inner_buffers_out_a_bits_source g=%h i=%h", $time, g_auto_inner_buffers_out_a_bits_source, i_auto_inner_buffers_out_a_bits_source); end end
    if (!$isunknown(g_auto_inner_buffers_out_a_bits_address) && g_auto_inner_buffers_out_a_bits_address !== i_auto_inner_buffers_out_a_bits_address) begin errors++;
      if(!reported[5]) begin reported[5]=1; distinct_div++;
        $display("[DIV %0t] auto_inner_buffers_out_a_bits_address g=%h i=%h", $time, g_auto_inner_buffers_out_a_bits_address, i_auto_inner_buffers_out_a_bits_address); end end
    if (!$isunknown(g_auto_inner_buffers_out_a_bits_mask) && g_auto_inner_buffers_out_a_bits_mask !== i_auto_inner_buffers_out_a_bits_mask) begin errors++;
      if(!reported[6]) begin reported[6]=1; distinct_div++;
        $display("[DIV %0t] auto_inner_buffers_out_a_bits_mask g=%h i=%h", $time, g_auto_inner_buffers_out_a_bits_mask, i_auto_inner_buffers_out_a_bits_mask); end end
    if (!$isunknown(g_auto_inner_buffers_out_a_bits_data) && g_auto_inner_buffers_out_a_bits_data !== i_auto_inner_buffers_out_a_bits_data) begin errors++;
      if(!reported[7]) begin reported[7]=1; distinct_div++;
        $display("[DIV %0t] auto_inner_buffers_out_a_bits_data g=%h i=%h", $time, g_auto_inner_buffers_out_a_bits_data, i_auto_inner_buffers_out_a_bits_data); end end
    if (!$isunknown(g_auto_inner_buffers_out_a_bits_corrupt) && g_auto_inner_buffers_out_a_bits_corrupt !== i_auto_inner_buffers_out_a_bits_corrupt) begin errors++;
      if(!reported[8]) begin reported[8]=1; distinct_div++;
        $display("[DIV %0t] auto_inner_buffers_out_a_bits_corrupt g=%h i=%h", $time, g_auto_inner_buffers_out_a_bits_corrupt, i_auto_inner_buffers_out_a_bits_corrupt); end end
    if (!$isunknown(g_auto_inner_buffers_out_d_ready) && g_auto_inner_buffers_out_d_ready !== i_auto_inner_buffers_out_d_ready) begin errors++;
      if(!reported[9]) begin reported[9]=1; distinct_div++;
        $display("[DIV %0t] auto_inner_buffers_out_d_ready g=%h i=%h", $time, g_auto_inner_buffers_out_d_ready, i_auto_inner_buffers_out_d_ready); end end
    if (!$isunknown(g_auto_inner_buffers_in_a_ready) && g_auto_inner_buffers_in_a_ready !== i_auto_inner_buffers_in_a_ready) begin errors++;
      if(!reported[10]) begin reported[10]=1; distinct_div++;
        $display("[DIV %0t] auto_inner_buffers_in_a_ready g=%h i=%h", $time, g_auto_inner_buffers_in_a_ready, i_auto_inner_buffers_in_a_ready); end end
    if (!$isunknown(g_auto_inner_buffers_in_d_valid) && g_auto_inner_buffers_in_d_valid !== i_auto_inner_buffers_in_d_valid) begin errors++;
      if(!reported[11]) begin reported[11]=1; distinct_div++;
        $display("[DIV %0t] auto_inner_buffers_in_d_valid g=%h i=%h", $time, g_auto_inner_buffers_in_d_valid, i_auto_inner_buffers_in_d_valid); end end
    if (!$isunknown(g_auto_inner_buffers_in_d_bits_opcode) && g_auto_inner_buffers_in_d_bits_opcode !== i_auto_inner_buffers_in_d_bits_opcode) begin errors++;
      if(!reported[12]) begin reported[12]=1; distinct_div++;
        $display("[DIV %0t] auto_inner_buffers_in_d_bits_opcode g=%h i=%h", $time, g_auto_inner_buffers_in_d_bits_opcode, i_auto_inner_buffers_in_d_bits_opcode); end end
    if (!$isunknown(g_auto_inner_buffers_in_d_bits_param) && g_auto_inner_buffers_in_d_bits_param !== i_auto_inner_buffers_in_d_bits_param) begin errors++;
      if(!reported[13]) begin reported[13]=1; distinct_div++;
        $display("[DIV %0t] auto_inner_buffers_in_d_bits_param g=%h i=%h", $time, g_auto_inner_buffers_in_d_bits_param, i_auto_inner_buffers_in_d_bits_param); end end
    if (!$isunknown(g_auto_inner_buffers_in_d_bits_size) && g_auto_inner_buffers_in_d_bits_size !== i_auto_inner_buffers_in_d_bits_size) begin errors++;
      if(!reported[14]) begin reported[14]=1; distinct_div++;
        $display("[DIV %0t] auto_inner_buffers_in_d_bits_size g=%h i=%h", $time, g_auto_inner_buffers_in_d_bits_size, i_auto_inner_buffers_in_d_bits_size); end end
    if (!$isunknown(g_auto_inner_buffers_in_d_bits_source) && g_auto_inner_buffers_in_d_bits_source !== i_auto_inner_buffers_in_d_bits_source) begin errors++;
      if(!reported[15]) begin reported[15]=1; distinct_div++;
        $display("[DIV %0t] auto_inner_buffers_in_d_bits_source g=%h i=%h", $time, g_auto_inner_buffers_in_d_bits_source, i_auto_inner_buffers_in_d_bits_source); end end
    if (!$isunknown(g_auto_inner_buffers_in_d_bits_sink) && g_auto_inner_buffers_in_d_bits_sink !== i_auto_inner_buffers_in_d_bits_sink) begin errors++;
      if(!reported[16]) begin reported[16]=1; distinct_div++;
        $display("[DIV %0t] auto_inner_buffers_in_d_bits_sink g=%h i=%h", $time, g_auto_inner_buffers_in_d_bits_sink, i_auto_inner_buffers_in_d_bits_sink); end end
    if (!$isunknown(g_auto_inner_buffers_in_d_bits_denied) && g_auto_inner_buffers_in_d_bits_denied !== i_auto_inner_buffers_in_d_bits_denied) begin errors++;
      if(!reported[17]) begin reported[17]=1; distinct_div++;
        $display("[DIV %0t] auto_inner_buffers_in_d_bits_denied g=%h i=%h", $time, g_auto_inner_buffers_in_d_bits_denied, i_auto_inner_buffers_in_d_bits_denied); end end
    if (!$isunknown(g_auto_inner_buffers_in_d_bits_data) && g_auto_inner_buffers_in_d_bits_data !== i_auto_inner_buffers_in_d_bits_data) begin errors++;
      if(!reported[18]) begin reported[18]=1; distinct_div++;
        $display("[DIV %0t] auto_inner_buffers_in_d_bits_data g=%h i=%h", $time, g_auto_inner_buffers_in_d_bits_data, i_auto_inner_buffers_in_d_bits_data); end end
    if (!$isunknown(g_auto_inner_buffers_in_d_bits_corrupt) && g_auto_inner_buffers_in_d_bits_corrupt !== i_auto_inner_buffers_in_d_bits_corrupt) begin errors++;
      if(!reported[19]) begin reported[19]=1; distinct_div++;
        $display("[DIV %0t] auto_inner_buffers_in_d_bits_corrupt g=%h i=%h", $time, g_auto_inner_buffers_in_d_bits_corrupt, i_auto_inner_buffers_in_d_bits_corrupt); end end
    if (!$isunknown(g_auto_inner_i_mmio_buffer_in_a_ready) && g_auto_inner_i_mmio_buffer_in_a_ready !== i_auto_inner_i_mmio_buffer_in_a_ready) begin errors++;
      if(!reported[20]) begin reported[20]=1; distinct_div++;
        $display("[DIV %0t] auto_inner_i_mmio_buffer_in_a_ready g=%h i=%h", $time, g_auto_inner_i_mmio_buffer_in_a_ready, i_auto_inner_i_mmio_buffer_in_a_ready); end end
    if (!$isunknown(g_auto_inner_i_mmio_buffer_in_d_valid) && g_auto_inner_i_mmio_buffer_in_d_valid !== i_auto_inner_i_mmio_buffer_in_d_valid) begin errors++;
      if(!reported[21]) begin reported[21]=1; distinct_div++;
        $display("[DIV %0t] auto_inner_i_mmio_buffer_in_d_valid g=%h i=%h", $time, g_auto_inner_i_mmio_buffer_in_d_valid, i_auto_inner_i_mmio_buffer_in_d_valid); end end
    if (!$isunknown(g_auto_inner_i_mmio_buffer_in_d_bits_opcode) && g_auto_inner_i_mmio_buffer_in_d_bits_opcode !== i_auto_inner_i_mmio_buffer_in_d_bits_opcode) begin errors++;
      if(!reported[22]) begin reported[22]=1; distinct_div++;
        $display("[DIV %0t] auto_inner_i_mmio_buffer_in_d_bits_opcode g=%h i=%h", $time, g_auto_inner_i_mmio_buffer_in_d_bits_opcode, i_auto_inner_i_mmio_buffer_in_d_bits_opcode); end end
    if (!$isunknown(g_auto_inner_i_mmio_buffer_in_d_bits_param) && g_auto_inner_i_mmio_buffer_in_d_bits_param !== i_auto_inner_i_mmio_buffer_in_d_bits_param) begin errors++;
      if(!reported[23]) begin reported[23]=1; distinct_div++;
        $display("[DIV %0t] auto_inner_i_mmio_buffer_in_d_bits_param g=%h i=%h", $time, g_auto_inner_i_mmio_buffer_in_d_bits_param, i_auto_inner_i_mmio_buffer_in_d_bits_param); end end
    if (!$isunknown(g_auto_inner_i_mmio_buffer_in_d_bits_size) && g_auto_inner_i_mmio_buffer_in_d_bits_size !== i_auto_inner_i_mmio_buffer_in_d_bits_size) begin errors++;
      if(!reported[24]) begin reported[24]=1; distinct_div++;
        $display("[DIV %0t] auto_inner_i_mmio_buffer_in_d_bits_size g=%h i=%h", $time, g_auto_inner_i_mmio_buffer_in_d_bits_size, i_auto_inner_i_mmio_buffer_in_d_bits_size); end end
    if (!$isunknown(g_auto_inner_i_mmio_buffer_in_d_bits_source) && g_auto_inner_i_mmio_buffer_in_d_bits_source !== i_auto_inner_i_mmio_buffer_in_d_bits_source) begin errors++;
      if(!reported[25]) begin reported[25]=1; distinct_div++;
        $display("[DIV %0t] auto_inner_i_mmio_buffer_in_d_bits_source g=%h i=%h", $time, g_auto_inner_i_mmio_buffer_in_d_bits_source, i_auto_inner_i_mmio_buffer_in_d_bits_source); end end
    if (!$isunknown(g_auto_inner_i_mmio_buffer_in_d_bits_sink) && g_auto_inner_i_mmio_buffer_in_d_bits_sink !== i_auto_inner_i_mmio_buffer_in_d_bits_sink) begin errors++;
      if(!reported[26]) begin reported[26]=1; distinct_div++;
        $display("[DIV %0t] auto_inner_i_mmio_buffer_in_d_bits_sink g=%h i=%h", $time, g_auto_inner_i_mmio_buffer_in_d_bits_sink, i_auto_inner_i_mmio_buffer_in_d_bits_sink); end end
    if (!$isunknown(g_auto_inner_i_mmio_buffer_in_d_bits_denied) && g_auto_inner_i_mmio_buffer_in_d_bits_denied !== i_auto_inner_i_mmio_buffer_in_d_bits_denied) begin errors++;
      if(!reported[27]) begin reported[27]=1; distinct_div++;
        $display("[DIV %0t] auto_inner_i_mmio_buffer_in_d_bits_denied g=%h i=%h", $time, g_auto_inner_i_mmio_buffer_in_d_bits_denied, i_auto_inner_i_mmio_buffer_in_d_bits_denied); end end
    if (!$isunknown(g_auto_inner_i_mmio_buffer_in_d_bits_data) && g_auto_inner_i_mmio_buffer_in_d_bits_data !== i_auto_inner_i_mmio_buffer_in_d_bits_data) begin errors++;
      if(!reported[28]) begin reported[28]=1; distinct_div++;
        $display("[DIV %0t] auto_inner_i_mmio_buffer_in_d_bits_data g=%h i=%h", $time, g_auto_inner_i_mmio_buffer_in_d_bits_data, i_auto_inner_i_mmio_buffer_in_d_bits_data); end end
    if (!$isunknown(g_auto_inner_i_mmio_buffer_in_d_bits_corrupt) && g_auto_inner_i_mmio_buffer_in_d_bits_corrupt !== i_auto_inner_i_mmio_buffer_in_d_bits_corrupt) begin errors++;
      if(!reported[29]) begin reported[29]=1; distinct_div++;
        $display("[DIV %0t] auto_inner_i_mmio_buffer_in_d_bits_corrupt g=%h i=%h", $time, g_auto_inner_i_mmio_buffer_in_d_bits_corrupt, i_auto_inner_i_mmio_buffer_in_d_bits_corrupt); end end
    if (!$isunknown(g_auto_inner_ptw_to_l2_buffer_in_a_ready) && g_auto_inner_ptw_to_l2_buffer_in_a_ready !== i_auto_inner_ptw_to_l2_buffer_in_a_ready) begin errors++;
      if(!reported[30]) begin reported[30]=1; distinct_div++;
        $display("[DIV %0t] auto_inner_ptw_to_l2_buffer_in_a_ready g=%h i=%h", $time, g_auto_inner_ptw_to_l2_buffer_in_a_ready, i_auto_inner_ptw_to_l2_buffer_in_a_ready); end end
    if (!$isunknown(g_auto_inner_ptw_to_l2_buffer_in_d_valid) && g_auto_inner_ptw_to_l2_buffer_in_d_valid !== i_auto_inner_ptw_to_l2_buffer_in_d_valid) begin errors++;
      if(!reported[31]) begin reported[31]=1; distinct_div++;
        $display("[DIV %0t] auto_inner_ptw_to_l2_buffer_in_d_valid g=%h i=%h", $time, g_auto_inner_ptw_to_l2_buffer_in_d_valid, i_auto_inner_ptw_to_l2_buffer_in_d_valid); end end
    if (!$isunknown(g_auto_inner_ptw_to_l2_buffer_in_d_bits_opcode) && g_auto_inner_ptw_to_l2_buffer_in_d_bits_opcode !== i_auto_inner_ptw_to_l2_buffer_in_d_bits_opcode) begin errors++;
      if(!reported[32]) begin reported[32]=1; distinct_div++;
        $display("[DIV %0t] auto_inner_ptw_to_l2_buffer_in_d_bits_opcode g=%h i=%h", $time, g_auto_inner_ptw_to_l2_buffer_in_d_bits_opcode, i_auto_inner_ptw_to_l2_buffer_in_d_bits_opcode); end end
    if (!$isunknown(g_auto_inner_ptw_to_l2_buffer_in_d_bits_param) && g_auto_inner_ptw_to_l2_buffer_in_d_bits_param !== i_auto_inner_ptw_to_l2_buffer_in_d_bits_param) begin errors++;
      if(!reported[33]) begin reported[33]=1; distinct_div++;
        $display("[DIV %0t] auto_inner_ptw_to_l2_buffer_in_d_bits_param g=%h i=%h", $time, g_auto_inner_ptw_to_l2_buffer_in_d_bits_param, i_auto_inner_ptw_to_l2_buffer_in_d_bits_param); end end
    if (!$isunknown(g_auto_inner_ptw_to_l2_buffer_in_d_bits_size) && g_auto_inner_ptw_to_l2_buffer_in_d_bits_size !== i_auto_inner_ptw_to_l2_buffer_in_d_bits_size) begin errors++;
      if(!reported[34]) begin reported[34]=1; distinct_div++;
        $display("[DIV %0t] auto_inner_ptw_to_l2_buffer_in_d_bits_size g=%h i=%h", $time, g_auto_inner_ptw_to_l2_buffer_in_d_bits_size, i_auto_inner_ptw_to_l2_buffer_in_d_bits_size); end end
    if (!$isunknown(g_auto_inner_ptw_to_l2_buffer_in_d_bits_source) && g_auto_inner_ptw_to_l2_buffer_in_d_bits_source !== i_auto_inner_ptw_to_l2_buffer_in_d_bits_source) begin errors++;
      if(!reported[35]) begin reported[35]=1; distinct_div++;
        $display("[DIV %0t] auto_inner_ptw_to_l2_buffer_in_d_bits_source g=%h i=%h", $time, g_auto_inner_ptw_to_l2_buffer_in_d_bits_source, i_auto_inner_ptw_to_l2_buffer_in_d_bits_source); end end
    if (!$isunknown(g_auto_inner_ptw_to_l2_buffer_in_d_bits_sink) && g_auto_inner_ptw_to_l2_buffer_in_d_bits_sink !== i_auto_inner_ptw_to_l2_buffer_in_d_bits_sink) begin errors++;
      if(!reported[36]) begin reported[36]=1; distinct_div++;
        $display("[DIV %0t] auto_inner_ptw_to_l2_buffer_in_d_bits_sink g=%h i=%h", $time, g_auto_inner_ptw_to_l2_buffer_in_d_bits_sink, i_auto_inner_ptw_to_l2_buffer_in_d_bits_sink); end end
    if (!$isunknown(g_auto_inner_ptw_to_l2_buffer_in_d_bits_denied) && g_auto_inner_ptw_to_l2_buffer_in_d_bits_denied !== i_auto_inner_ptw_to_l2_buffer_in_d_bits_denied) begin errors++;
      if(!reported[37]) begin reported[37]=1; distinct_div++;
        $display("[DIV %0t] auto_inner_ptw_to_l2_buffer_in_d_bits_denied g=%h i=%h", $time, g_auto_inner_ptw_to_l2_buffer_in_d_bits_denied, i_auto_inner_ptw_to_l2_buffer_in_d_bits_denied); end end
    if (!$isunknown(g_auto_inner_ptw_to_l2_buffer_in_d_bits_data) && g_auto_inner_ptw_to_l2_buffer_in_d_bits_data !== i_auto_inner_ptw_to_l2_buffer_in_d_bits_data) begin errors++;
      if(!reported[38]) begin reported[38]=1; distinct_div++;
        $display("[DIV %0t] auto_inner_ptw_to_l2_buffer_in_d_bits_data g=%h i=%h", $time, g_auto_inner_ptw_to_l2_buffer_in_d_bits_data, i_auto_inner_ptw_to_l2_buffer_in_d_bits_data); end end
    if (!$isunknown(g_auto_inner_ptw_to_l2_buffer_in_d_bits_corrupt) && g_auto_inner_ptw_to_l2_buffer_in_d_bits_corrupt !== i_auto_inner_ptw_to_l2_buffer_in_d_bits_corrupt) begin errors++;
      if(!reported[39]) begin reported[39]=1; distinct_div++;
        $display("[DIV %0t] auto_inner_ptw_to_l2_buffer_in_d_bits_corrupt g=%h i=%h", $time, g_auto_inner_ptw_to_l2_buffer_in_d_bits_corrupt, i_auto_inner_ptw_to_l2_buffer_in_d_bits_corrupt); end end
    if (!$isunknown(g_auto_inner_logger_in_1_a_ready) && g_auto_inner_logger_in_1_a_ready !== i_auto_inner_logger_in_1_a_ready) begin errors++;
      if(!reported[40]) begin reported[40]=1; distinct_div++;
        $display("[DIV %0t] auto_inner_logger_in_1_a_ready g=%h i=%h", $time, g_auto_inner_logger_in_1_a_ready, i_auto_inner_logger_in_1_a_ready); end end
    if (!$isunknown(g_auto_inner_logger_in_1_d_valid) && g_auto_inner_logger_in_1_d_valid !== i_auto_inner_logger_in_1_d_valid) begin errors++;
      if(!reported[41]) begin reported[41]=1; distinct_div++;
        $display("[DIV %0t] auto_inner_logger_in_1_d_valid g=%h i=%h", $time, g_auto_inner_logger_in_1_d_valid, i_auto_inner_logger_in_1_d_valid); end end
    if (!$isunknown(g_auto_inner_logger_in_1_d_bits_opcode) && g_auto_inner_logger_in_1_d_bits_opcode !== i_auto_inner_logger_in_1_d_bits_opcode) begin errors++;
      if(!reported[42]) begin reported[42]=1; distinct_div++;
        $display("[DIV %0t] auto_inner_logger_in_1_d_bits_opcode g=%h i=%h", $time, g_auto_inner_logger_in_1_d_bits_opcode, i_auto_inner_logger_in_1_d_bits_opcode); end end
    if (!$isunknown(g_auto_inner_logger_in_1_d_bits_param) && g_auto_inner_logger_in_1_d_bits_param !== i_auto_inner_logger_in_1_d_bits_param) begin errors++;
      if(!reported[43]) begin reported[43]=1; distinct_div++;
        $display("[DIV %0t] auto_inner_logger_in_1_d_bits_param g=%h i=%h", $time, g_auto_inner_logger_in_1_d_bits_param, i_auto_inner_logger_in_1_d_bits_param); end end
    if (!$isunknown(g_auto_inner_logger_in_1_d_bits_size) && g_auto_inner_logger_in_1_d_bits_size !== i_auto_inner_logger_in_1_d_bits_size) begin errors++;
      if(!reported[44]) begin reported[44]=1; distinct_div++;
        $display("[DIV %0t] auto_inner_logger_in_1_d_bits_size g=%h i=%h", $time, g_auto_inner_logger_in_1_d_bits_size, i_auto_inner_logger_in_1_d_bits_size); end end
    if (!$isunknown(g_auto_inner_logger_in_1_d_bits_source) && g_auto_inner_logger_in_1_d_bits_source !== i_auto_inner_logger_in_1_d_bits_source) begin errors++;
      if(!reported[45]) begin reported[45]=1; distinct_div++;
        $display("[DIV %0t] auto_inner_logger_in_1_d_bits_source g=%h i=%h", $time, g_auto_inner_logger_in_1_d_bits_source, i_auto_inner_logger_in_1_d_bits_source); end end
    if (!$isunknown(g_auto_inner_logger_in_1_d_bits_sink) && g_auto_inner_logger_in_1_d_bits_sink !== i_auto_inner_logger_in_1_d_bits_sink) begin errors++;
      if(!reported[46]) begin reported[46]=1; distinct_div++;
        $display("[DIV %0t] auto_inner_logger_in_1_d_bits_sink g=%h i=%h", $time, g_auto_inner_logger_in_1_d_bits_sink, i_auto_inner_logger_in_1_d_bits_sink); end end
    if (!$isunknown(g_auto_inner_logger_in_1_d_bits_denied) && g_auto_inner_logger_in_1_d_bits_denied !== i_auto_inner_logger_in_1_d_bits_denied) begin errors++;
      if(!reported[47]) begin reported[47]=1; distinct_div++;
        $display("[DIV %0t] auto_inner_logger_in_1_d_bits_denied g=%h i=%h", $time, g_auto_inner_logger_in_1_d_bits_denied, i_auto_inner_logger_in_1_d_bits_denied); end end
    if (!$isunknown(g_auto_inner_logger_in_1_d_bits_data) && g_auto_inner_logger_in_1_d_bits_data !== i_auto_inner_logger_in_1_d_bits_data) begin errors++;
      if(!reported[48]) begin reported[48]=1; distinct_div++;
        $display("[DIV %0t] auto_inner_logger_in_1_d_bits_data g=%h i=%h", $time, g_auto_inner_logger_in_1_d_bits_data, i_auto_inner_logger_in_1_d_bits_data); end end
    if (!$isunknown(g_auto_inner_logger_in_1_d_bits_corrupt) && g_auto_inner_logger_in_1_d_bits_corrupt !== i_auto_inner_logger_in_1_d_bits_corrupt) begin errors++;
      if(!reported[49]) begin reported[49]=1; distinct_div++;
        $display("[DIV %0t] auto_inner_logger_in_1_d_bits_corrupt g=%h i=%h", $time, g_auto_inner_logger_in_1_d_bits_corrupt, i_auto_inner_logger_in_1_d_bits_corrupt); end end
    if (!$isunknown(g_auto_inner_logger_in_0_a_ready) && g_auto_inner_logger_in_0_a_ready !== i_auto_inner_logger_in_0_a_ready) begin errors++;
      if(!reported[50]) begin reported[50]=1; distinct_div++;
        $display("[DIV %0t] auto_inner_logger_in_0_a_ready g=%h i=%h", $time, g_auto_inner_logger_in_0_a_ready, i_auto_inner_logger_in_0_a_ready); end end
    if (!$isunknown(g_auto_inner_logger_in_0_b_valid) && g_auto_inner_logger_in_0_b_valid !== i_auto_inner_logger_in_0_b_valid) begin errors++;
      if(!reported[51]) begin reported[51]=1; distinct_div++;
        $display("[DIV %0t] auto_inner_logger_in_0_b_valid g=%h i=%h", $time, g_auto_inner_logger_in_0_b_valid, i_auto_inner_logger_in_0_b_valid); end end
    if (!$isunknown(g_auto_inner_logger_in_0_b_bits_opcode) && g_auto_inner_logger_in_0_b_bits_opcode !== i_auto_inner_logger_in_0_b_bits_opcode) begin errors++;
      if(!reported[52]) begin reported[52]=1; distinct_div++;
        $display("[DIV %0t] auto_inner_logger_in_0_b_bits_opcode g=%h i=%h", $time, g_auto_inner_logger_in_0_b_bits_opcode, i_auto_inner_logger_in_0_b_bits_opcode); end end
    if (!$isunknown(g_auto_inner_logger_in_0_b_bits_param) && g_auto_inner_logger_in_0_b_bits_param !== i_auto_inner_logger_in_0_b_bits_param) begin errors++;
      if(!reported[53]) begin reported[53]=1; distinct_div++;
        $display("[DIV %0t] auto_inner_logger_in_0_b_bits_param g=%h i=%h", $time, g_auto_inner_logger_in_0_b_bits_param, i_auto_inner_logger_in_0_b_bits_param); end end
    if (!$isunknown(g_auto_inner_logger_in_0_b_bits_size) && g_auto_inner_logger_in_0_b_bits_size !== i_auto_inner_logger_in_0_b_bits_size) begin errors++;
      if(!reported[54]) begin reported[54]=1; distinct_div++;
        $display("[DIV %0t] auto_inner_logger_in_0_b_bits_size g=%h i=%h", $time, g_auto_inner_logger_in_0_b_bits_size, i_auto_inner_logger_in_0_b_bits_size); end end
    if (!$isunknown(g_auto_inner_logger_in_0_b_bits_source) && g_auto_inner_logger_in_0_b_bits_source !== i_auto_inner_logger_in_0_b_bits_source) begin errors++;
      if(!reported[55]) begin reported[55]=1; distinct_div++;
        $display("[DIV %0t] auto_inner_logger_in_0_b_bits_source g=%h i=%h", $time, g_auto_inner_logger_in_0_b_bits_source, i_auto_inner_logger_in_0_b_bits_source); end end
    if (!$isunknown(g_auto_inner_logger_in_0_b_bits_address) && g_auto_inner_logger_in_0_b_bits_address !== i_auto_inner_logger_in_0_b_bits_address) begin errors++;
      if(!reported[56]) begin reported[56]=1; distinct_div++;
        $display("[DIV %0t] auto_inner_logger_in_0_b_bits_address g=%h i=%h", $time, g_auto_inner_logger_in_0_b_bits_address, i_auto_inner_logger_in_0_b_bits_address); end end
    if (!$isunknown(g_auto_inner_logger_in_0_b_bits_mask) && g_auto_inner_logger_in_0_b_bits_mask !== i_auto_inner_logger_in_0_b_bits_mask) begin errors++;
      if(!reported[57]) begin reported[57]=1; distinct_div++;
        $display("[DIV %0t] auto_inner_logger_in_0_b_bits_mask g=%h i=%h", $time, g_auto_inner_logger_in_0_b_bits_mask, i_auto_inner_logger_in_0_b_bits_mask); end end
    if (!$isunknown(g_auto_inner_logger_in_0_b_bits_data) && g_auto_inner_logger_in_0_b_bits_data !== i_auto_inner_logger_in_0_b_bits_data) begin errors++;
      if(!reported[58]) begin reported[58]=1; distinct_div++;
        $display("[DIV %0t] auto_inner_logger_in_0_b_bits_data g=%h i=%h", $time, g_auto_inner_logger_in_0_b_bits_data, i_auto_inner_logger_in_0_b_bits_data); end end
    if (!$isunknown(g_auto_inner_logger_in_0_b_bits_corrupt) && g_auto_inner_logger_in_0_b_bits_corrupt !== i_auto_inner_logger_in_0_b_bits_corrupt) begin errors++;
      if(!reported[59]) begin reported[59]=1; distinct_div++;
        $display("[DIV %0t] auto_inner_logger_in_0_b_bits_corrupt g=%h i=%h", $time, g_auto_inner_logger_in_0_b_bits_corrupt, i_auto_inner_logger_in_0_b_bits_corrupt); end end
    if (!$isunknown(g_auto_inner_logger_in_0_c_ready) && g_auto_inner_logger_in_0_c_ready !== i_auto_inner_logger_in_0_c_ready) begin errors++;
      if(!reported[60]) begin reported[60]=1; distinct_div++;
        $display("[DIV %0t] auto_inner_logger_in_0_c_ready g=%h i=%h", $time, g_auto_inner_logger_in_0_c_ready, i_auto_inner_logger_in_0_c_ready); end end
    if (!$isunknown(g_auto_inner_logger_in_0_d_valid) && g_auto_inner_logger_in_0_d_valid !== i_auto_inner_logger_in_0_d_valid) begin errors++;
      if(!reported[61]) begin reported[61]=1; distinct_div++;
        $display("[DIV %0t] auto_inner_logger_in_0_d_valid g=%h i=%h", $time, g_auto_inner_logger_in_0_d_valid, i_auto_inner_logger_in_0_d_valid); end end
    if (!$isunknown(g_auto_inner_logger_in_0_d_bits_opcode) && g_auto_inner_logger_in_0_d_bits_opcode !== i_auto_inner_logger_in_0_d_bits_opcode) begin errors++;
      if(!reported[62]) begin reported[62]=1; distinct_div++;
        $display("[DIV %0t] auto_inner_logger_in_0_d_bits_opcode g=%h i=%h", $time, g_auto_inner_logger_in_0_d_bits_opcode, i_auto_inner_logger_in_0_d_bits_opcode); end end
    if (!$isunknown(g_auto_inner_logger_in_0_d_bits_param) && g_auto_inner_logger_in_0_d_bits_param !== i_auto_inner_logger_in_0_d_bits_param) begin errors++;
      if(!reported[63]) begin reported[63]=1; distinct_div++;
        $display("[DIV %0t] auto_inner_logger_in_0_d_bits_param g=%h i=%h", $time, g_auto_inner_logger_in_0_d_bits_param, i_auto_inner_logger_in_0_d_bits_param); end end
    if (!$isunknown(g_auto_inner_logger_in_0_d_bits_size) && g_auto_inner_logger_in_0_d_bits_size !== i_auto_inner_logger_in_0_d_bits_size) begin errors++;
      if(!reported[64]) begin reported[64]=1; distinct_div++;
        $display("[DIV %0t] auto_inner_logger_in_0_d_bits_size g=%h i=%h", $time, g_auto_inner_logger_in_0_d_bits_size, i_auto_inner_logger_in_0_d_bits_size); end end
    if (!$isunknown(g_auto_inner_logger_in_0_d_bits_source) && g_auto_inner_logger_in_0_d_bits_source !== i_auto_inner_logger_in_0_d_bits_source) begin errors++;
      if(!reported[65]) begin reported[65]=1; distinct_div++;
        $display("[DIV %0t] auto_inner_logger_in_0_d_bits_source g=%h i=%h", $time, g_auto_inner_logger_in_0_d_bits_source, i_auto_inner_logger_in_0_d_bits_source); end end
    if (!$isunknown(g_auto_inner_logger_in_0_d_bits_sink) && g_auto_inner_logger_in_0_d_bits_sink !== i_auto_inner_logger_in_0_d_bits_sink) begin errors++;
      if(!reported[66]) begin reported[66]=1; distinct_div++;
        $display("[DIV %0t] auto_inner_logger_in_0_d_bits_sink g=%h i=%h", $time, g_auto_inner_logger_in_0_d_bits_sink, i_auto_inner_logger_in_0_d_bits_sink); end end
    if (!$isunknown(g_auto_inner_logger_in_0_d_bits_denied) && g_auto_inner_logger_in_0_d_bits_denied !== i_auto_inner_logger_in_0_d_bits_denied) begin errors++;
      if(!reported[67]) begin reported[67]=1; distinct_div++;
        $display("[DIV %0t] auto_inner_logger_in_0_d_bits_denied g=%h i=%h", $time, g_auto_inner_logger_in_0_d_bits_denied, i_auto_inner_logger_in_0_d_bits_denied); end end
    if (!$isunknown(g_auto_inner_logger_in_0_d_bits_echo_isKeyword) && g_auto_inner_logger_in_0_d_bits_echo_isKeyword !== i_auto_inner_logger_in_0_d_bits_echo_isKeyword) begin errors++;
      if(!reported[68]) begin reported[68]=1; distinct_div++;
        $display("[DIV %0t] auto_inner_logger_in_0_d_bits_echo_isKeyword g=%h i=%h", $time, g_auto_inner_logger_in_0_d_bits_echo_isKeyword, i_auto_inner_logger_in_0_d_bits_echo_isKeyword); end end
    if (!$isunknown(g_auto_inner_logger_in_0_d_bits_data) && g_auto_inner_logger_in_0_d_bits_data !== i_auto_inner_logger_in_0_d_bits_data) begin errors++;
      if(!reported[69]) begin reported[69]=1; distinct_div++;
        $display("[DIV %0t] auto_inner_logger_in_0_d_bits_data g=%h i=%h", $time, g_auto_inner_logger_in_0_d_bits_data, i_auto_inner_logger_in_0_d_bits_data); end end
    if (!$isunknown(g_auto_inner_logger_in_0_d_bits_corrupt) && g_auto_inner_logger_in_0_d_bits_corrupt !== i_auto_inner_logger_in_0_d_bits_corrupt) begin errors++;
      if(!reported[70]) begin reported[70]=1; distinct_div++;
        $display("[DIV %0t] auto_inner_logger_in_0_d_bits_corrupt g=%h i=%h", $time, g_auto_inner_logger_in_0_d_bits_corrupt, i_auto_inner_logger_in_0_d_bits_corrupt); end end
    if (!$isunknown(g_auto_inner_logger_in_0_e_ready) && g_auto_inner_logger_in_0_e_ready !== i_auto_inner_logger_in_0_e_ready) begin errors++;
      if(!reported[71]) begin reported[71]=1; distinct_div++;
        $display("[DIV %0t] auto_inner_logger_in_0_e_ready g=%h i=%h", $time, g_auto_inner_logger_in_0_e_ready, i_auto_inner_logger_in_0_e_ready); end end
    if (!$isunknown(g_auto_inner_beu_int_out_0) && g_auto_inner_beu_int_out_0 !== i_auto_inner_beu_int_out_0) begin errors++;
      if(!reported[72]) begin reported[72]=1; distinct_div++;
        $display("[DIV %0t] auto_inner_beu_int_out_0 g=%h i=%h", $time, g_auto_inner_beu_int_out_0, i_auto_inner_beu_int_out_0); end end
    if (!$isunknown(g_auto_inner_beu_local_int_source_out_0) && g_auto_inner_beu_local_int_source_out_0 !== i_auto_inner_beu_local_int_source_out_0) begin errors++;
      if(!reported[73]) begin reported[73]=1; distinct_div++;
        $display("[DIV %0t] auto_inner_beu_local_int_source_out_0 g=%h i=%h", $time, g_auto_inner_beu_local_int_source_out_0, i_auto_inner_beu_local_int_source_out_0); end end
    if (!$isunknown(g_auto_inner_nmi_int_out_0) && g_auto_inner_nmi_int_out_0 !== i_auto_inner_nmi_int_out_0) begin errors++;
      if(!reported[74]) begin reported[74]=1; distinct_div++;
        $display("[DIV %0t] auto_inner_nmi_int_out_0 g=%h i=%h", $time, g_auto_inner_nmi_int_out_0, i_auto_inner_nmi_int_out_0); end end
    if (!$isunknown(g_auto_inner_nmi_int_out_1) && g_auto_inner_nmi_int_out_1 !== i_auto_inner_nmi_int_out_1) begin errors++;
      if(!reported[75]) begin reported[75]=1; distinct_div++;
        $display("[DIV %0t] auto_inner_nmi_int_out_1 g=%h i=%h", $time, g_auto_inner_nmi_int_out_1, i_auto_inner_nmi_int_out_1); end end
    if (!$isunknown(g_auto_inner_plic_int_out_1_0) && g_auto_inner_plic_int_out_1_0 !== i_auto_inner_plic_int_out_1_0) begin errors++;
      if(!reported[76]) begin reported[76]=1; distinct_div++;
        $display("[DIV %0t] auto_inner_plic_int_out_1_0 g=%h i=%h", $time, g_auto_inner_plic_int_out_1_0, i_auto_inner_plic_int_out_1_0); end end
    if (!$isunknown(g_auto_inner_plic_int_out_0_0) && g_auto_inner_plic_int_out_0_0 !== i_auto_inner_plic_int_out_0_0) begin errors++;
      if(!reported[77]) begin reported[77]=1; distinct_div++;
        $display("[DIV %0t] auto_inner_plic_int_out_0_0 g=%h i=%h", $time, g_auto_inner_plic_int_out_0_0, i_auto_inner_plic_int_out_0_0); end end
    if (!$isunknown(g_auto_inner_debug_int_out_0) && g_auto_inner_debug_int_out_0 !== i_auto_inner_debug_int_out_0) begin errors++;
      if(!reported[78]) begin reported[78]=1; distinct_div++;
        $display("[DIV %0t] auto_inner_debug_int_out_0 g=%h i=%h", $time, g_auto_inner_debug_int_out_0, i_auto_inner_debug_int_out_0); end end
    if (!$isunknown(g_auto_inner_clint_int_out_0) && g_auto_inner_clint_int_out_0 !== i_auto_inner_clint_int_out_0) begin errors++;
      if(!reported[79]) begin reported[79]=1; distinct_div++;
        $display("[DIV %0t] auto_inner_clint_int_out_0 g=%h i=%h", $time, g_auto_inner_clint_int_out_0, i_auto_inner_clint_int_out_0); end end
    if (!$isunknown(g_auto_inner_clint_int_out_1) && g_auto_inner_clint_int_out_1 !== i_auto_inner_clint_int_out_1) begin errors++;
      if(!reported[80]) begin reported[80]=1; distinct_div++;
        $display("[DIV %0t] auto_inner_clint_int_out_1 g=%h i=%h", $time, g_auto_inner_clint_int_out_1, i_auto_inner_clint_int_out_1); end end
    if (!$isunknown(g_io_reset_vector_toCore) && g_io_reset_vector_toCore !== i_io_reset_vector_toCore) begin errors++;
      if(!reported[81]) begin reported[81]=1; distinct_div++;
        $display("[DIV %0t] io_reset_vector_toCore g=%h i=%h", $time, g_io_reset_vector_toCore, i_io_reset_vector_toCore); end end
    if (!$isunknown(g_io_hartId_toCore) && g_io_hartId_toCore !== i_io_hartId_toCore) begin errors++;
      if(!reported[82]) begin reported[82]=1; distinct_div++;
        $display("[DIV %0t] io_hartId_toCore g=%h i=%h", $time, g_io_hartId_toCore, i_io_hartId_toCore); end end
    if (!$isunknown(g_io_msiInfo_toCore_valid) && g_io_msiInfo_toCore_valid !== i_io_msiInfo_toCore_valid) begin errors++;
      if(!reported[83]) begin reported[83]=1; distinct_div++;
        $display("[DIV %0t] io_msiInfo_toCore_valid g=%h i=%h", $time, g_io_msiInfo_toCore_valid, i_io_msiInfo_toCore_valid); end end
    if (!$isunknown(g_io_msiInfo_toCore_bits) && g_io_msiInfo_toCore_bits !== i_io_msiInfo_toCore_bits) begin errors++;
      if(!reported[84]) begin reported[84]=1; distinct_div++;
        $display("[DIV %0t] io_msiInfo_toCore_bits g=%h i=%h", $time, g_io_msiInfo_toCore_bits, i_io_msiInfo_toCore_bits); end end
    if (!$isunknown(g_io_cpu_halt_toTile) && g_io_cpu_halt_toTile !== i_io_cpu_halt_toTile) begin errors++;
      if(!reported[85]) begin reported[85]=1; distinct_div++;
        $display("[DIV %0t] io_cpu_halt_toTile g=%h i=%h", $time, g_io_cpu_halt_toTile, i_io_cpu_halt_toTile); end end
    if (!$isunknown(g_io_cpu_critical_error_toTile) && g_io_cpu_critical_error_toTile !== i_io_cpu_critical_error_toTile) begin errors++;
      if(!reported[86]) begin reported[86]=1; distinct_div++;
        $display("[DIV %0t] io_cpu_critical_error_toTile g=%h i=%h", $time, g_io_cpu_critical_error_toTile, i_io_cpu_critical_error_toTile); end end
    if (!$isunknown(g_io_hartIsInReset_toTile) && g_io_hartIsInReset_toTile !== i_io_hartIsInReset_toTile) begin errors++;
      if(!reported[87]) begin reported[87]=1; distinct_div++;
        $display("[DIV %0t] io_hartIsInReset_toTile g=%h i=%h", $time, g_io_hartIsInReset_toTile, i_io_hartIsInReset_toTile); end end
    if (!$isunknown(g_io_traceCoreInterface_fromCore_fromEncoder_enable) && g_io_traceCoreInterface_fromCore_fromEncoder_enable !== i_io_traceCoreInterface_fromCore_fromEncoder_enable) begin errors++;
      if(!reported[88]) begin reported[88]=1; distinct_div++;
        $display("[DIV %0t] io_traceCoreInterface_fromCore_fromEncoder_enable g=%h i=%h", $time, g_io_traceCoreInterface_fromCore_fromEncoder_enable, i_io_traceCoreInterface_fromCore_fromEncoder_enable); end end
    if (!$isunknown(g_io_traceCoreInterface_fromCore_fromEncoder_stall) && g_io_traceCoreInterface_fromCore_fromEncoder_stall !== i_io_traceCoreInterface_fromCore_fromEncoder_stall) begin errors++;
      if(!reported[89]) begin reported[89]=1; distinct_div++;
        $display("[DIV %0t] io_traceCoreInterface_fromCore_fromEncoder_stall g=%h i=%h", $time, g_io_traceCoreInterface_fromCore_fromEncoder_stall, i_io_traceCoreInterface_fromCore_fromEncoder_stall); end end
    if (!$isunknown(g_io_traceCoreInterface_toTile_toEncoder_priv) && g_io_traceCoreInterface_toTile_toEncoder_priv !== i_io_traceCoreInterface_toTile_toEncoder_priv) begin errors++;
      if(!reported[90]) begin reported[90]=1; distinct_div++;
        $display("[DIV %0t] io_traceCoreInterface_toTile_toEncoder_priv g=%h i=%h", $time, g_io_traceCoreInterface_toTile_toEncoder_priv, i_io_traceCoreInterface_toTile_toEncoder_priv); end end
    if (!$isunknown(g_io_traceCoreInterface_toTile_toEncoder_trap_cause) && g_io_traceCoreInterface_toTile_toEncoder_trap_cause !== i_io_traceCoreInterface_toTile_toEncoder_trap_cause) begin errors++;
      if(!reported[91]) begin reported[91]=1; distinct_div++;
        $display("[DIV %0t] io_traceCoreInterface_toTile_toEncoder_trap_cause g=%h i=%h", $time, g_io_traceCoreInterface_toTile_toEncoder_trap_cause, i_io_traceCoreInterface_toTile_toEncoder_trap_cause); end end
    if (!$isunknown(g_io_traceCoreInterface_toTile_toEncoder_trap_tval) && g_io_traceCoreInterface_toTile_toEncoder_trap_tval !== i_io_traceCoreInterface_toTile_toEncoder_trap_tval) begin errors++;
      if(!reported[92]) begin reported[92]=1; distinct_div++;
        $display("[DIV %0t] io_traceCoreInterface_toTile_toEncoder_trap_tval g=%h i=%h", $time, g_io_traceCoreInterface_toTile_toEncoder_trap_tval, i_io_traceCoreInterface_toTile_toEncoder_trap_tval); end end
    if (!$isunknown(g_io_traceCoreInterface_toTile_toEncoder_groups_0_bits_iaddr) && g_io_traceCoreInterface_toTile_toEncoder_groups_0_bits_iaddr !== i_io_traceCoreInterface_toTile_toEncoder_groups_0_bits_iaddr) begin errors++;
      if(!reported[93]) begin reported[93]=1; distinct_div++;
        $display("[DIV %0t] io_traceCoreInterface_toTile_toEncoder_groups_0_bits_iaddr g=%h i=%h", $time, g_io_traceCoreInterface_toTile_toEncoder_groups_0_bits_iaddr, i_io_traceCoreInterface_toTile_toEncoder_groups_0_bits_iaddr); end end
    if (!$isunknown(g_io_traceCoreInterface_toTile_toEncoder_groups_0_bits_itype) && g_io_traceCoreInterface_toTile_toEncoder_groups_0_bits_itype !== i_io_traceCoreInterface_toTile_toEncoder_groups_0_bits_itype) begin errors++;
      if(!reported[94]) begin reported[94]=1; distinct_div++;
        $display("[DIV %0t] io_traceCoreInterface_toTile_toEncoder_groups_0_bits_itype g=%h i=%h", $time, g_io_traceCoreInterface_toTile_toEncoder_groups_0_bits_itype, i_io_traceCoreInterface_toTile_toEncoder_groups_0_bits_itype); end end
    if (!$isunknown(g_io_traceCoreInterface_toTile_toEncoder_groups_0_bits_iretire) && g_io_traceCoreInterface_toTile_toEncoder_groups_0_bits_iretire !== i_io_traceCoreInterface_toTile_toEncoder_groups_0_bits_iretire) begin errors++;
      if(!reported[95]) begin reported[95]=1; distinct_div++;
        $display("[DIV %0t] io_traceCoreInterface_toTile_toEncoder_groups_0_bits_iretire g=%h i=%h", $time, g_io_traceCoreInterface_toTile_toEncoder_groups_0_bits_iretire, i_io_traceCoreInterface_toTile_toEncoder_groups_0_bits_iretire); end end
    if (!$isunknown(g_io_traceCoreInterface_toTile_toEncoder_groups_0_bits_ilastsize) && g_io_traceCoreInterface_toTile_toEncoder_groups_0_bits_ilastsize !== i_io_traceCoreInterface_toTile_toEncoder_groups_0_bits_ilastsize) begin errors++;
      if(!reported[96]) begin reported[96]=1; distinct_div++;
        $display("[DIV %0t] io_traceCoreInterface_toTile_toEncoder_groups_0_bits_ilastsize g=%h i=%h", $time, g_io_traceCoreInterface_toTile_toEncoder_groups_0_bits_ilastsize, i_io_traceCoreInterface_toTile_toEncoder_groups_0_bits_ilastsize); end end
    if (!$isunknown(g_io_traceCoreInterface_toTile_toEncoder_groups_1_bits_iaddr) && g_io_traceCoreInterface_toTile_toEncoder_groups_1_bits_iaddr !== i_io_traceCoreInterface_toTile_toEncoder_groups_1_bits_iaddr) begin errors++;
      if(!reported[97]) begin reported[97]=1; distinct_div++;
        $display("[DIV %0t] io_traceCoreInterface_toTile_toEncoder_groups_1_bits_iaddr g=%h i=%h", $time, g_io_traceCoreInterface_toTile_toEncoder_groups_1_bits_iaddr, i_io_traceCoreInterface_toTile_toEncoder_groups_1_bits_iaddr); end end
    if (!$isunknown(g_io_traceCoreInterface_toTile_toEncoder_groups_1_bits_itype) && g_io_traceCoreInterface_toTile_toEncoder_groups_1_bits_itype !== i_io_traceCoreInterface_toTile_toEncoder_groups_1_bits_itype) begin errors++;
      if(!reported[98]) begin reported[98]=1; distinct_div++;
        $display("[DIV %0t] io_traceCoreInterface_toTile_toEncoder_groups_1_bits_itype g=%h i=%h", $time, g_io_traceCoreInterface_toTile_toEncoder_groups_1_bits_itype, i_io_traceCoreInterface_toTile_toEncoder_groups_1_bits_itype); end end
    if (!$isunknown(g_io_traceCoreInterface_toTile_toEncoder_groups_1_bits_iretire) && g_io_traceCoreInterface_toTile_toEncoder_groups_1_bits_iretire !== i_io_traceCoreInterface_toTile_toEncoder_groups_1_bits_iretire) begin errors++;
      if(!reported[99]) begin reported[99]=1; distinct_div++;
        $display("[DIV %0t] io_traceCoreInterface_toTile_toEncoder_groups_1_bits_iretire g=%h i=%h", $time, g_io_traceCoreInterface_toTile_toEncoder_groups_1_bits_iretire, i_io_traceCoreInterface_toTile_toEncoder_groups_1_bits_iretire); end end
    if (!$isunknown(g_io_traceCoreInterface_toTile_toEncoder_groups_1_bits_ilastsize) && g_io_traceCoreInterface_toTile_toEncoder_groups_1_bits_ilastsize !== i_io_traceCoreInterface_toTile_toEncoder_groups_1_bits_ilastsize) begin errors++;
      if(!reported[100]) begin reported[100]=1; distinct_div++;
        $display("[DIV %0t] io_traceCoreInterface_toTile_toEncoder_groups_1_bits_ilastsize g=%h i=%h", $time, g_io_traceCoreInterface_toTile_toEncoder_groups_1_bits_ilastsize, i_io_traceCoreInterface_toTile_toEncoder_groups_1_bits_ilastsize); end end
    if (!$isunknown(g_io_traceCoreInterface_toTile_toEncoder_groups_2_bits_iaddr) && g_io_traceCoreInterface_toTile_toEncoder_groups_2_bits_iaddr !== i_io_traceCoreInterface_toTile_toEncoder_groups_2_bits_iaddr) begin errors++;
      if(!reported[101]) begin reported[101]=1; distinct_div++;
        $display("[DIV %0t] io_traceCoreInterface_toTile_toEncoder_groups_2_bits_iaddr g=%h i=%h", $time, g_io_traceCoreInterface_toTile_toEncoder_groups_2_bits_iaddr, i_io_traceCoreInterface_toTile_toEncoder_groups_2_bits_iaddr); end end
    if (!$isunknown(g_io_traceCoreInterface_toTile_toEncoder_groups_2_bits_itype) && g_io_traceCoreInterface_toTile_toEncoder_groups_2_bits_itype !== i_io_traceCoreInterface_toTile_toEncoder_groups_2_bits_itype) begin errors++;
      if(!reported[102]) begin reported[102]=1; distinct_div++;
        $display("[DIV %0t] io_traceCoreInterface_toTile_toEncoder_groups_2_bits_itype g=%h i=%h", $time, g_io_traceCoreInterface_toTile_toEncoder_groups_2_bits_itype, i_io_traceCoreInterface_toTile_toEncoder_groups_2_bits_itype); end end
    if (!$isunknown(g_io_traceCoreInterface_toTile_toEncoder_groups_2_bits_iretire) && g_io_traceCoreInterface_toTile_toEncoder_groups_2_bits_iretire !== i_io_traceCoreInterface_toTile_toEncoder_groups_2_bits_iretire) begin errors++;
      if(!reported[103]) begin reported[103]=1; distinct_div++;
        $display("[DIV %0t] io_traceCoreInterface_toTile_toEncoder_groups_2_bits_iretire g=%h i=%h", $time, g_io_traceCoreInterface_toTile_toEncoder_groups_2_bits_iretire, i_io_traceCoreInterface_toTile_toEncoder_groups_2_bits_iretire); end end
    if (!$isunknown(g_io_traceCoreInterface_toTile_toEncoder_groups_2_bits_ilastsize) && g_io_traceCoreInterface_toTile_toEncoder_groups_2_bits_ilastsize !== i_io_traceCoreInterface_toTile_toEncoder_groups_2_bits_ilastsize) begin errors++;
      if(!reported[104]) begin reported[104]=1; distinct_div++;
        $display("[DIV %0t] io_traceCoreInterface_toTile_toEncoder_groups_2_bits_ilastsize g=%h i=%h", $time, g_io_traceCoreInterface_toTile_toEncoder_groups_2_bits_ilastsize, i_io_traceCoreInterface_toTile_toEncoder_groups_2_bits_ilastsize); end end
    if (!$isunknown(g_io_debugTopDown_l2MissMatch) && g_io_debugTopDown_l2MissMatch !== i_io_debugTopDown_l2MissMatch) begin errors++;
      if(!reported[105]) begin reported[105]=1; distinct_div++;
        $display("[DIV %0t] io_debugTopDown_l2MissMatch g=%h i=%h", $time, g_io_debugTopDown_l2MissMatch, i_io_debugTopDown_l2MissMatch); end end
    if (!$isunknown(g_io_l2Miss) && g_io_l2Miss !== i_io_l2Miss) begin errors++;
      if(!reported[106]) begin reported[106]=1; distinct_div++;
        $display("[DIV %0t] io_l2Miss g=%h i=%h", $time, g_io_l2Miss, i_io_l2Miss); end end
    if (!$isunknown(g_io_l3Miss_toCore) && g_io_l3Miss_toCore !== i_io_l3Miss_toCore) begin errors++;
      if(!reported[107]) begin reported[107]=1; distinct_div++;
        $display("[DIV %0t] io_l3Miss_toCore g=%h i=%h", $time, g_io_l3Miss_toCore, i_io_l3Miss_toCore); end end
    if (!$isunknown(g_io_clintTime_toCore_valid) && g_io_clintTime_toCore_valid !== i_io_clintTime_toCore_valid) begin errors++;
      if(!reported[108]) begin reported[108]=1; distinct_div++;
        $display("[DIV %0t] io_clintTime_toCore_valid g=%h i=%h", $time, g_io_clintTime_toCore_valid, i_io_clintTime_toCore_valid); end end
    if (!$isunknown(g_io_clintTime_toCore_bits) && g_io_clintTime_toCore_bits !== i_io_clintTime_toCore_bits) begin errors++;
      if(!reported[109]) begin reported[109]=1; distinct_div++;
        $display("[DIV %0t] io_clintTime_toCore_bits g=%h i=%h", $time, g_io_clintTime_toCore_bits, i_io_clintTime_toCore_bits); end end
    if (!$isunknown(g_io_chi_txsactive) && g_io_chi_txsactive !== i_io_chi_txsactive) begin errors++;
      if(!reported[110]) begin reported[110]=1; distinct_div++;
        $display("[DIV %0t] io_chi_txsactive g=%h i=%h", $time, g_io_chi_txsactive, i_io_chi_txsactive); end end
    if (!$isunknown(g_io_chi_syscoreq) && g_io_chi_syscoreq !== i_io_chi_syscoreq) begin errors++;
      if(!reported[111]) begin reported[111]=1; distinct_div++;
        $display("[DIV %0t] io_chi_syscoreq g=%h i=%h", $time, g_io_chi_syscoreq, i_io_chi_syscoreq); end end
    if (!$isunknown(g_io_chi_tx_linkactivereq) && g_io_chi_tx_linkactivereq !== i_io_chi_tx_linkactivereq) begin errors++;
      if(!reported[112]) begin reported[112]=1; distinct_div++;
        $display("[DIV %0t] io_chi_tx_linkactivereq g=%h i=%h", $time, g_io_chi_tx_linkactivereq, i_io_chi_tx_linkactivereq); end end
    if (!$isunknown(g_io_chi_tx_req_flitpend) && g_io_chi_tx_req_flitpend !== i_io_chi_tx_req_flitpend) begin errors++;
      if(!reported[113]) begin reported[113]=1; distinct_div++;
        $display("[DIV %0t] io_chi_tx_req_flitpend g=%h i=%h", $time, g_io_chi_tx_req_flitpend, i_io_chi_tx_req_flitpend); end end
    if (!$isunknown(g_io_chi_tx_req_flitv) && g_io_chi_tx_req_flitv !== i_io_chi_tx_req_flitv) begin errors++;
      if(!reported[114]) begin reported[114]=1; distinct_div++;
        $display("[DIV %0t] io_chi_tx_req_flitv g=%h i=%h", $time, g_io_chi_tx_req_flitv, i_io_chi_tx_req_flitv); end end
    if (!$isunknown(g_io_chi_tx_req_flit) && g_io_chi_tx_req_flit !== i_io_chi_tx_req_flit) begin errors++;
      if(!reported[115]) begin reported[115]=1; distinct_div++;
        $display("[DIV %0t] io_chi_tx_req_flit g=%h i=%h", $time, g_io_chi_tx_req_flit, i_io_chi_tx_req_flit); end end
    if (!$isunknown(g_io_chi_tx_rsp_flitpend) && g_io_chi_tx_rsp_flitpend !== i_io_chi_tx_rsp_flitpend) begin errors++;
      if(!reported[116]) begin reported[116]=1; distinct_div++;
        $display("[DIV %0t] io_chi_tx_rsp_flitpend g=%h i=%h", $time, g_io_chi_tx_rsp_flitpend, i_io_chi_tx_rsp_flitpend); end end
    if (!$isunknown(g_io_chi_tx_rsp_flitv) && g_io_chi_tx_rsp_flitv !== i_io_chi_tx_rsp_flitv) begin errors++;
      if(!reported[117]) begin reported[117]=1; distinct_div++;
        $display("[DIV %0t] io_chi_tx_rsp_flitv g=%h i=%h", $time, g_io_chi_tx_rsp_flitv, i_io_chi_tx_rsp_flitv); end end
    if (!$isunknown(g_io_chi_tx_rsp_flit) && g_io_chi_tx_rsp_flit !== i_io_chi_tx_rsp_flit) begin errors++;
      if(!reported[118]) begin reported[118]=1; distinct_div++;
        $display("[DIV %0t] io_chi_tx_rsp_flit g=%h i=%h", $time, g_io_chi_tx_rsp_flit, i_io_chi_tx_rsp_flit); end end
    if (!$isunknown(g_io_chi_tx_dat_flitpend) && g_io_chi_tx_dat_flitpend !== i_io_chi_tx_dat_flitpend) begin errors++;
      if(!reported[119]) begin reported[119]=1; distinct_div++;
        $display("[DIV %0t] io_chi_tx_dat_flitpend g=%h i=%h", $time, g_io_chi_tx_dat_flitpend, i_io_chi_tx_dat_flitpend); end end
    if (!$isunknown(g_io_chi_tx_dat_flitv) && g_io_chi_tx_dat_flitv !== i_io_chi_tx_dat_flitv) begin errors++;
      if(!reported[120]) begin reported[120]=1; distinct_div++;
        $display("[DIV %0t] io_chi_tx_dat_flitv g=%h i=%h", $time, g_io_chi_tx_dat_flitv, i_io_chi_tx_dat_flitv); end end
    if (!$isunknown(g_io_chi_tx_dat_flit) && g_io_chi_tx_dat_flit !== i_io_chi_tx_dat_flit) begin errors++;
      if(!reported[121]) begin reported[121]=1; distinct_div++;
        $display("[DIV %0t] io_chi_tx_dat_flit g=%h i=%h", $time, g_io_chi_tx_dat_flit, i_io_chi_tx_dat_flit); end end
    if (!$isunknown(g_io_chi_rx_linkactiveack) && g_io_chi_rx_linkactiveack !== i_io_chi_rx_linkactiveack) begin errors++;
      if(!reported[122]) begin reported[122]=1; distinct_div++;
        $display("[DIV %0t] io_chi_rx_linkactiveack g=%h i=%h", $time, g_io_chi_rx_linkactiveack, i_io_chi_rx_linkactiveack); end end
    if (!$isunknown(g_io_chi_rx_rsp_lcrdv) && g_io_chi_rx_rsp_lcrdv !== i_io_chi_rx_rsp_lcrdv) begin errors++;
      if(!reported[123]) begin reported[123]=1; distinct_div++;
        $display("[DIV %0t] io_chi_rx_rsp_lcrdv g=%h i=%h", $time, g_io_chi_rx_rsp_lcrdv, i_io_chi_rx_rsp_lcrdv); end end
    if (!$isunknown(g_io_chi_rx_dat_lcrdv) && g_io_chi_rx_dat_lcrdv !== i_io_chi_rx_dat_lcrdv) begin errors++;
      if(!reported[124]) begin reported[124]=1; distinct_div++;
        $display("[DIV %0t] io_chi_rx_dat_lcrdv g=%h i=%h", $time, g_io_chi_rx_dat_lcrdv, i_io_chi_rx_dat_lcrdv); end end
    if (!$isunknown(g_io_chi_rx_snp_lcrdv) && g_io_chi_rx_snp_lcrdv !== i_io_chi_rx_snp_lcrdv) begin errors++;
      if(!reported[125]) begin reported[125]=1; distinct_div++;
        $display("[DIV %0t] io_chi_rx_snp_lcrdv g=%h i=%h", $time, g_io_chi_rx_snp_lcrdv, i_io_chi_rx_snp_lcrdv); end end
    if (!$isunknown(g_io_l2_tlb_req_req_valid) && g_io_l2_tlb_req_req_valid !== i_io_l2_tlb_req_req_valid) begin errors++;
      if(!reported[126]) begin reported[126]=1; distinct_div++;
        $display("[DIV %0t] io_l2_tlb_req_req_valid g=%h i=%h", $time, g_io_l2_tlb_req_req_valid, i_io_l2_tlb_req_req_valid); end end
    if (!$isunknown(g_io_l2_tlb_req_req_bits_vaddr) && g_io_l2_tlb_req_req_bits_vaddr !== i_io_l2_tlb_req_req_bits_vaddr) begin errors++;
      if(!reported[127]) begin reported[127]=1; distinct_div++;
        $display("[DIV %0t] io_l2_tlb_req_req_bits_vaddr g=%h i=%h", $time, g_io_l2_tlb_req_req_bits_vaddr, i_io_l2_tlb_req_req_bits_vaddr); end end
    if (!$isunknown(g_io_l2_tlb_req_req_bits_cmd) && g_io_l2_tlb_req_req_bits_cmd !== i_io_l2_tlb_req_req_bits_cmd) begin errors++;
      if(!reported[128]) begin reported[128]=1; distinct_div++;
        $display("[DIV %0t] io_l2_tlb_req_req_bits_cmd g=%h i=%h", $time, g_io_l2_tlb_req_req_bits_cmd, i_io_l2_tlb_req_req_bits_cmd); end end
    if (!$isunknown(g_io_l2_tlb_req_req_bits_kill) && g_io_l2_tlb_req_req_bits_kill !== i_io_l2_tlb_req_req_bits_kill) begin errors++;
      if(!reported[129]) begin reported[129]=1; distinct_div++;
        $display("[DIV %0t] io_l2_tlb_req_req_bits_kill g=%h i=%h", $time, g_io_l2_tlb_req_req_bits_kill, i_io_l2_tlb_req_req_bits_kill); end end
    if (!$isunknown(g_io_l2_tlb_req_req_bits_no_translate) && g_io_l2_tlb_req_req_bits_no_translate !== i_io_l2_tlb_req_req_bits_no_translate) begin errors++;
      if(!reported[130]) begin reported[130]=1; distinct_div++;
        $display("[DIV %0t] io_l2_tlb_req_req_bits_no_translate g=%h i=%h", $time, g_io_l2_tlb_req_req_bits_no_translate, i_io_l2_tlb_req_req_bits_no_translate); end end
    if (!$isunknown(g_io_l2_hint_valid) && g_io_l2_hint_valid !== i_io_l2_hint_valid) begin errors++;
      if(!reported[131]) begin reported[131]=1; distinct_div++;
        $display("[DIV %0t] io_l2_hint_valid g=%h i=%h", $time, g_io_l2_hint_valid, i_io_l2_hint_valid); end end
    if (!$isunknown(g_io_l2_hint_bits_sourceId) && g_io_l2_hint_bits_sourceId !== i_io_l2_hint_bits_sourceId) begin errors++;
      if(!reported[132]) begin reported[132]=1; distinct_div++;
        $display("[DIV %0t] io_l2_hint_bits_sourceId g=%h i=%h", $time, g_io_l2_hint_bits_sourceId, i_io_l2_hint_bits_sourceId); end end
    if (!$isunknown(g_io_l2_hint_bits_isKeyword) && g_io_l2_hint_bits_isKeyword !== i_io_l2_hint_bits_isKeyword) begin errors++;
      if(!reported[133]) begin reported[133]=1; distinct_div++;
        $display("[DIV %0t] io_l2_hint_bits_isKeyword g=%h i=%h", $time, g_io_l2_hint_bits_isKeyword, i_io_l2_hint_bits_isKeyword); end end
    if (!$isunknown(g_io_perfEvents_1_value) && g_io_perfEvents_1_value !== i_io_perfEvents_1_value) begin errors++;
      if(!reported[134]) begin reported[134]=1; distinct_div++;
        $display("[DIV %0t] io_perfEvents_1_value g=%h i=%h", $time, g_io_perfEvents_1_value, i_io_perfEvents_1_value); end end
    if (!$isunknown(g_io_perfEvents_2_value) && g_io_perfEvents_2_value !== i_io_perfEvents_2_value) begin errors++;
      if(!reported[135]) begin reported[135]=1; distinct_div++;
        $display("[DIV %0t] io_perfEvents_2_value g=%h i=%h", $time, g_io_perfEvents_2_value, i_io_perfEvents_2_value); end end
    if (!$isunknown(g_io_perfEvents_3_value) && g_io_perfEvents_3_value !== i_io_perfEvents_3_value) begin errors++;
      if(!reported[136]) begin reported[136]=1; distinct_div++;
        $display("[DIV %0t] io_perfEvents_3_value g=%h i=%h", $time, g_io_perfEvents_3_value, i_io_perfEvents_3_value); end end
    if (!$isunknown(g_io_perfEvents_4_value) && g_io_perfEvents_4_value !== i_io_perfEvents_4_value) begin errors++;
      if(!reported[137]) begin reported[137]=1; distinct_div++;
        $display("[DIV %0t] io_perfEvents_4_value g=%h i=%h", $time, g_io_perfEvents_4_value, i_io_perfEvents_4_value); end end
    if (!$isunknown(g_io_perfEvents_5_value) && g_io_perfEvents_5_value !== i_io_perfEvents_5_value) begin errors++;
      if(!reported[138]) begin reported[138]=1; distinct_div++;
        $display("[DIV %0t] io_perfEvents_5_value g=%h i=%h", $time, g_io_perfEvents_5_value, i_io_perfEvents_5_value); end end
    if (!$isunknown(g_io_perfEvents_6_value) && g_io_perfEvents_6_value !== i_io_perfEvents_6_value) begin errors++;
      if(!reported[139]) begin reported[139]=1; distinct_div++;
        $display("[DIV %0t] io_perfEvents_6_value g=%h i=%h", $time, g_io_perfEvents_6_value, i_io_perfEvents_6_value); end end
    if (!$isunknown(g_io_perfEvents_7_value) && g_io_perfEvents_7_value !== i_io_perfEvents_7_value) begin errors++;
      if(!reported[140]) begin reported[140]=1; distinct_div++;
        $display("[DIV %0t] io_perfEvents_7_value g=%h i=%h", $time, g_io_perfEvents_7_value, i_io_perfEvents_7_value); end end
    if (!$isunknown(g_io_perfEvents_8_value) && g_io_perfEvents_8_value !== i_io_perfEvents_8_value) begin errors++;
      if(!reported[141]) begin reported[141]=1; distinct_div++;
        $display("[DIV %0t] io_perfEvents_8_value g=%h i=%h", $time, g_io_perfEvents_8_value, i_io_perfEvents_8_value); end end
    if (!$isunknown(g_io_perfEvents_9_value) && g_io_perfEvents_9_value !== i_io_perfEvents_9_value) begin errors++;
      if(!reported[142]) begin reported[142]=1; distinct_div++;
        $display("[DIV %0t] io_perfEvents_9_value g=%h i=%h", $time, g_io_perfEvents_9_value, i_io_perfEvents_9_value); end end
    if (!$isunknown(g_io_perfEvents_10_value) && g_io_perfEvents_10_value !== i_io_perfEvents_10_value) begin errors++;
      if(!reported[143]) begin reported[143]=1; distinct_div++;
        $display("[DIV %0t] io_perfEvents_10_value g=%h i=%h", $time, g_io_perfEvents_10_value, i_io_perfEvents_10_value); end end
    if (!$isunknown(g_io_perfEvents_11_value) && g_io_perfEvents_11_value !== i_io_perfEvents_11_value) begin errors++;
      if(!reported[144]) begin reported[144]=1; distinct_div++;
        $display("[DIV %0t] io_perfEvents_11_value g=%h i=%h", $time, g_io_perfEvents_11_value, i_io_perfEvents_11_value); end end
    if (!$isunknown(g_io_perfEvents_12_value) && g_io_perfEvents_12_value !== i_io_perfEvents_12_value) begin errors++;
      if(!reported[145]) begin reported[145]=1; distinct_div++;
        $display("[DIV %0t] io_perfEvents_12_value g=%h i=%h", $time, g_io_perfEvents_12_value, i_io_perfEvents_12_value); end end
    if (!$isunknown(g_io_perfEvents_13_value) && g_io_perfEvents_13_value !== i_io_perfEvents_13_value) begin errors++;
      if(!reported[146]) begin reported[146]=1; distinct_div++;
        $display("[DIV %0t] io_perfEvents_13_value g=%h i=%h", $time, g_io_perfEvents_13_value, i_io_perfEvents_13_value); end end
    if (!$isunknown(g_io_perfEvents_14_value) && g_io_perfEvents_14_value !== i_io_perfEvents_14_value) begin errors++;
      if(!reported[147]) begin reported[147]=1; distinct_div++;
        $display("[DIV %0t] io_perfEvents_14_value g=%h i=%h", $time, g_io_perfEvents_14_value, i_io_perfEvents_14_value); end end
    if (!$isunknown(g_io_perfEvents_15_value) && g_io_perfEvents_15_value !== i_io_perfEvents_15_value) begin errors++;
      if(!reported[148]) begin reported[148]=1; distinct_div++;
        $display("[DIV %0t] io_perfEvents_15_value g=%h i=%h", $time, g_io_perfEvents_15_value, i_io_perfEvents_15_value); end end
    if (!$isunknown(g_io_perfEvents_16_value) && g_io_perfEvents_16_value !== i_io_perfEvents_16_value) begin errors++;
      if(!reported[149]) begin reported[149]=1; distinct_div++;
        $display("[DIV %0t] io_perfEvents_16_value g=%h i=%h", $time, g_io_perfEvents_16_value, i_io_perfEvents_16_value); end end
    if (!$isunknown(g_io_perfEvents_17_value) && g_io_perfEvents_17_value !== i_io_perfEvents_17_value) begin errors++;
      if(!reported[150]) begin reported[150]=1; distinct_div++;
        $display("[DIV %0t] io_perfEvents_17_value g=%h i=%h", $time, g_io_perfEvents_17_value, i_io_perfEvents_17_value); end end
    if (!$isunknown(g_io_perfEvents_18_value) && g_io_perfEvents_18_value !== i_io_perfEvents_18_value) begin errors++;
      if(!reported[151]) begin reported[151]=1; distinct_div++;
        $display("[DIV %0t] io_perfEvents_18_value g=%h i=%h", $time, g_io_perfEvents_18_value, i_io_perfEvents_18_value); end end
    if (!$isunknown(g_io_perfEvents_19_value) && g_io_perfEvents_19_value !== i_io_perfEvents_19_value) begin errors++;
      if(!reported[152]) begin reported[152]=1; distinct_div++;
        $display("[DIV %0t] io_perfEvents_19_value g=%h i=%h", $time, g_io_perfEvents_19_value, i_io_perfEvents_19_value); end end
    if (!$isunknown(g_io_perfEvents_20_value) && g_io_perfEvents_20_value !== i_io_perfEvents_20_value) begin errors++;
      if(!reported[153]) begin reported[153]=1; distinct_div++;
        $display("[DIV %0t] io_perfEvents_20_value g=%h i=%h", $time, g_io_perfEvents_20_value, i_io_perfEvents_20_value); end end
    if (!$isunknown(g_io_perfEvents_21_value) && g_io_perfEvents_21_value !== i_io_perfEvents_21_value) begin errors++;
      if(!reported[154]) begin reported[154]=1; distinct_div++;
        $display("[DIV %0t] io_perfEvents_21_value g=%h i=%h", $time, g_io_perfEvents_21_value, i_io_perfEvents_21_value); end end
    if (!$isunknown(g_io_perfEvents_22_value) && g_io_perfEvents_22_value !== i_io_perfEvents_22_value) begin errors++;
      if(!reported[155]) begin reported[155]=1; distinct_div++;
        $display("[DIV %0t] io_perfEvents_22_value g=%h i=%h", $time, g_io_perfEvents_22_value, i_io_perfEvents_22_value); end end
    if (!$isunknown(g_io_perfEvents_23_value) && g_io_perfEvents_23_value !== i_io_perfEvents_23_value) begin errors++;
      if(!reported[156]) begin reported[156]=1; distinct_div++;
        $display("[DIV %0t] io_perfEvents_23_value g=%h i=%h", $time, g_io_perfEvents_23_value, i_io_perfEvents_23_value); end end
    if (!$isunknown(g_io_perfEvents_24_value) && g_io_perfEvents_24_value !== i_io_perfEvents_24_value) begin errors++;
      if(!reported[157]) begin reported[157]=1; distinct_div++;
        $display("[DIV %0t] io_perfEvents_24_value g=%h i=%h", $time, g_io_perfEvents_24_value, i_io_perfEvents_24_value); end end
    if (!$isunknown(g_io_perfEvents_25_value) && g_io_perfEvents_25_value !== i_io_perfEvents_25_value) begin errors++;
      if(!reported[158]) begin reported[158]=1; distinct_div++;
        $display("[DIV %0t] io_perfEvents_25_value g=%h i=%h", $time, g_io_perfEvents_25_value, i_io_perfEvents_25_value); end end
    if (!$isunknown(g_io_perfEvents_26_value) && g_io_perfEvents_26_value !== i_io_perfEvents_26_value) begin errors++;
      if(!reported[159]) begin reported[159]=1; distinct_div++;
        $display("[DIV %0t] io_perfEvents_26_value g=%h i=%h", $time, g_io_perfEvents_26_value, i_io_perfEvents_26_value); end end
    if (!$isunknown(g_io_perfEvents_27_value) && g_io_perfEvents_27_value !== i_io_perfEvents_27_value) begin errors++;
      if(!reported[160]) begin reported[160]=1; distinct_div++;
        $display("[DIV %0t] io_perfEvents_27_value g=%h i=%h", $time, g_io_perfEvents_27_value, i_io_perfEvents_27_value); end end
    if (!$isunknown(g_io_perfEvents_28_value) && g_io_perfEvents_28_value !== i_io_perfEvents_28_value) begin errors++;
      if(!reported[161]) begin reported[161]=1; distinct_div++;
        $display("[DIV %0t] io_perfEvents_28_value g=%h i=%h", $time, g_io_perfEvents_28_value, i_io_perfEvents_28_value); end end
    if (!$isunknown(g_io_perfEvents_29_value) && g_io_perfEvents_29_value !== i_io_perfEvents_29_value) begin errors++;
      if(!reported[162]) begin reported[162]=1; distinct_div++;
        $display("[DIV %0t] io_perfEvents_29_value g=%h i=%h", $time, g_io_perfEvents_29_value, i_io_perfEvents_29_value); end end
    if (!$isunknown(g_io_perfEvents_30_value) && g_io_perfEvents_30_value !== i_io_perfEvents_30_value) begin errors++;
      if(!reported[163]) begin reported[163]=1; distinct_div++;
        $display("[DIV %0t] io_perfEvents_30_value g=%h i=%h", $time, g_io_perfEvents_30_value, i_io_perfEvents_30_value); end end
    if (!$isunknown(g_io_perfEvents_31_value) && g_io_perfEvents_31_value !== i_io_perfEvents_31_value) begin errors++;
      if(!reported[164]) begin reported[164]=1; distinct_div++;
        $display("[DIV %0t] io_perfEvents_31_value g=%h i=%h", $time, g_io_perfEvents_31_value, i_io_perfEvents_31_value); end end
    if (!$isunknown(g_io_perfEvents_32_value) && g_io_perfEvents_32_value !== i_io_perfEvents_32_value) begin errors++;
      if(!reported[165]) begin reported[165]=1; distinct_div++;
        $display("[DIV %0t] io_perfEvents_32_value g=%h i=%h", $time, g_io_perfEvents_32_value, i_io_perfEvents_32_value); end end
    if (!$isunknown(g_io_perfEvents_33_value) && g_io_perfEvents_33_value !== i_io_perfEvents_33_value) begin errors++;
      if(!reported[166]) begin reported[166]=1; distinct_div++;
        $display("[DIV %0t] io_perfEvents_33_value g=%h i=%h", $time, g_io_perfEvents_33_value, i_io_perfEvents_33_value); end end
    if (!$isunknown(g_io_perfEvents_34_value) && g_io_perfEvents_34_value !== i_io_perfEvents_34_value) begin errors++;
      if(!reported[167]) begin reported[167]=1; distinct_div++;
        $display("[DIV %0t] io_perfEvents_34_value g=%h i=%h", $time, g_io_perfEvents_34_value, i_io_perfEvents_34_value); end end
    if (!$isunknown(g_io_perfEvents_35_value) && g_io_perfEvents_35_value !== i_io_perfEvents_35_value) begin errors++;
      if(!reported[168]) begin reported[168]=1; distinct_div++;
        $display("[DIV %0t] io_perfEvents_35_value g=%h i=%h", $time, g_io_perfEvents_35_value, i_io_perfEvents_35_value); end end
    if (!$isunknown(g_io_perfEvents_36_value) && g_io_perfEvents_36_value !== i_io_perfEvents_36_value) begin errors++;
      if(!reported[169]) begin reported[169]=1; distinct_div++;
        $display("[DIV %0t] io_perfEvents_36_value g=%h i=%h", $time, g_io_perfEvents_36_value, i_io_perfEvents_36_value); end end
    if (!$isunknown(g_io_perfEvents_37_value) && g_io_perfEvents_37_value !== i_io_perfEvents_37_value) begin errors++;
      if(!reported[170]) begin reported[170]=1; distinct_div++;
        $display("[DIV %0t] io_perfEvents_37_value g=%h i=%h", $time, g_io_perfEvents_37_value, i_io_perfEvents_37_value); end end
    if (!$isunknown(g_io_perfEvents_38_value) && g_io_perfEvents_38_value !== i_io_perfEvents_38_value) begin errors++;
      if(!reported[171]) begin reported[171]=1; distinct_div++;
        $display("[DIV %0t] io_perfEvents_38_value g=%h i=%h", $time, g_io_perfEvents_38_value, i_io_perfEvents_38_value); end end
    if (!$isunknown(g_io_perfEvents_39_value) && g_io_perfEvents_39_value !== i_io_perfEvents_39_value) begin errors++;
      if(!reported[172]) begin reported[172]=1; distinct_div++;
        $display("[DIV %0t] io_perfEvents_39_value g=%h i=%h", $time, g_io_perfEvents_39_value, i_io_perfEvents_39_value); end end
    if (!$isunknown(g_io_perfEvents_40_value) && g_io_perfEvents_40_value !== i_io_perfEvents_40_value) begin errors++;
      if(!reported[173]) begin reported[173]=1; distinct_div++;
        $display("[DIV %0t] io_perfEvents_40_value g=%h i=%h", $time, g_io_perfEvents_40_value, i_io_perfEvents_40_value); end end
    if (!$isunknown(g_io_perfEvents_41_value) && g_io_perfEvents_41_value !== i_io_perfEvents_41_value) begin errors++;
      if(!reported[174]) begin reported[174]=1; distinct_div++;
        $display("[DIV %0t] io_perfEvents_41_value g=%h i=%h", $time, g_io_perfEvents_41_value, i_io_perfEvents_41_value); end end
    if (!$isunknown(g_io_perfEvents_42_value) && g_io_perfEvents_42_value !== i_io_perfEvents_42_value) begin errors++;
      if(!reported[175]) begin reported[175]=1; distinct_div++;
        $display("[DIV %0t] io_perfEvents_42_value g=%h i=%h", $time, g_io_perfEvents_42_value, i_io_perfEvents_42_value); end end
    if (!$isunknown(g_io_perfEvents_43_value) && g_io_perfEvents_43_value !== i_io_perfEvents_43_value) begin errors++;
      if(!reported[176]) begin reported[176]=1; distinct_div++;
        $display("[DIV %0t] io_perfEvents_43_value g=%h i=%h", $time, g_io_perfEvents_43_value, i_io_perfEvents_43_value); end end
    if (!$isunknown(g_io_perfEvents_44_value) && g_io_perfEvents_44_value !== i_io_perfEvents_44_value) begin errors++;
      if(!reported[177]) begin reported[177]=1; distinct_div++;
        $display("[DIV %0t] io_perfEvents_44_value g=%h i=%h", $time, g_io_perfEvents_44_value, i_io_perfEvents_44_value); end end
    if (!$isunknown(g_io_perfEvents_45_value) && g_io_perfEvents_45_value !== i_io_perfEvents_45_value) begin errors++;
      if(!reported[178]) begin reported[178]=1; distinct_div++;
        $display("[DIV %0t] io_perfEvents_45_value g=%h i=%h", $time, g_io_perfEvents_45_value, i_io_perfEvents_45_value); end end
    if (!$isunknown(g_io_perfEvents_46_value) && g_io_perfEvents_46_value !== i_io_perfEvents_46_value) begin errors++;
      if(!reported[179]) begin reported[179]=1; distinct_div++;
        $display("[DIV %0t] io_perfEvents_46_value g=%h i=%h", $time, g_io_perfEvents_46_value, i_io_perfEvents_46_value); end end
    if (!$isunknown(g_io_perfEvents_47_value) && g_io_perfEvents_47_value !== i_io_perfEvents_47_value) begin errors++;
      if(!reported[180]) begin reported[180]=1; distinct_div++;
        $display("[DIV %0t] io_perfEvents_47_value g=%h i=%h", $time, g_io_perfEvents_47_value, i_io_perfEvents_47_value); end end
    if (!$isunknown(g_io_perfEvents_48_value) && g_io_perfEvents_48_value !== i_io_perfEvents_48_value) begin errors++;
      if(!reported[181]) begin reported[181]=1; distinct_div++;
        $display("[DIV %0t] io_perfEvents_48_value g=%h i=%h", $time, g_io_perfEvents_48_value, i_io_perfEvents_48_value); end end
  end

  initial begin
    if (!$value$plusargs("NCYCLES=%d", NCYCLES)) NCYCLES = 200000;
    rst = 1; repeat (16) @(posedge clk); rst = 0;
    repeat (NCYCLES) @(posedge clk);
    $display("distinct_diverging_ports=%0d / %0d", distinct_div, 182);
    $display("checks=%0d errors=%0d", checks, errors);
    if (errors == 0 && checks > 1000) $display("TEST PASSED"); else $display("TEST FAILED");
    $finish;
  end
endmodule
