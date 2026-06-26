// 自动生成:scripts/gen_xstile.py —— 勿手改(顶层 glue 为从 Scala 意图的可读重写)

// 3 子模块类型黑盒 stub(空体,所有 output 驱 0)。
// 注:UT/FM 默认用 golden 子模块真定义(-f 闭包);本 stub 仅备快速 elaborate。

module IntBuffer(
  input  clock,
  input  reset,
  input  auto_in_0,
  output  auto_out_0
);
  assign auto_out_0 = '0;
endmodule

module L2Top(
  input  clock,
  input  reset,
  input  auto_inner_buffers_out_a_ready,
  output  auto_inner_buffers_out_a_valid,
  output  [3:0] auto_inner_buffers_out_a_bits_opcode,
  output  [2:0] auto_inner_buffers_out_a_bits_param,
  output  [1:0] auto_inner_buffers_out_a_bits_size,
  output  [2:0] auto_inner_buffers_out_a_bits_source,
  output  [29:0] auto_inner_buffers_out_a_bits_address,
  output  [7:0] auto_inner_buffers_out_a_bits_mask,
  output  [63:0] auto_inner_buffers_out_a_bits_data,
  output  auto_inner_buffers_out_a_bits_corrupt,
  output  auto_inner_buffers_out_d_ready,
  input  auto_inner_buffers_out_d_valid,
  input  [3:0] auto_inner_buffers_out_d_bits_opcode,
  input  [1:0] auto_inner_buffers_out_d_bits_param,
  input  [1:0] auto_inner_buffers_out_d_bits_size,
  input  [2:0] auto_inner_buffers_out_d_bits_source,
  input  auto_inner_buffers_out_d_bits_sink,
  input  auto_inner_buffers_out_d_bits_denied,
  input  [63:0] auto_inner_buffers_out_d_bits_data,
  input  auto_inner_buffers_out_d_bits_corrupt,
  output  auto_inner_buffers_in_a_ready,
  input  auto_inner_buffers_in_a_valid,
  input  [3:0] auto_inner_buffers_in_a_bits_opcode,
  input  [2:0] auto_inner_buffers_in_a_bits_param,
  input  [1:0] auto_inner_buffers_in_a_bits_size,
  input  [1:0] auto_inner_buffers_in_a_bits_source,
  input  [47:0] auto_inner_buffers_in_a_bits_address,
  input  auto_inner_buffers_in_a_bits_user_memBackType_MM,
  input  auto_inner_buffers_in_a_bits_user_memPageType_NC,
  input  [7:0] auto_inner_buffers_in_a_bits_mask,
  input  [63:0] auto_inner_buffers_in_a_bits_data,
  input  auto_inner_buffers_in_a_bits_corrupt,
  input  auto_inner_buffers_in_d_ready,
  output  auto_inner_buffers_in_d_valid,
  output  [3:0] auto_inner_buffers_in_d_bits_opcode,
  output  [1:0] auto_inner_buffers_in_d_bits_param,
  output  [1:0] auto_inner_buffers_in_d_bits_size,
  output  [1:0] auto_inner_buffers_in_d_bits_source,
  output  auto_inner_buffers_in_d_bits_sink,
  output  auto_inner_buffers_in_d_bits_denied,
  output  [63:0] auto_inner_buffers_in_d_bits_data,
  output  auto_inner_buffers_in_d_bits_corrupt,
  input  [63:0] auto_inner_l2cache_pf_recv_in_addr,
  input  [4:0] auto_inner_l2cache_pf_recv_in_pf_source,
  input  auto_inner_l2cache_pf_recv_in_addr_valid,
  output  auto_inner_i_mmio_buffer_in_a_ready,
  input  auto_inner_i_mmio_buffer_in_a_valid,
  input  [2:0] auto_inner_i_mmio_buffer_in_a_bits_param,
  input  [47:0] auto_inner_i_mmio_buffer_in_a_bits_address,
  input  auto_inner_i_mmio_buffer_in_a_bits_corrupt,
  input  auto_inner_i_mmio_buffer_in_d_ready,
  output  auto_inner_i_mmio_buffer_in_d_valid,
  output  [3:0] auto_inner_i_mmio_buffer_in_d_bits_opcode,
  output  [1:0] auto_inner_i_mmio_buffer_in_d_bits_param,
  output  [1:0] auto_inner_i_mmio_buffer_in_d_bits_size,
  output  auto_inner_i_mmio_buffer_in_d_bits_source,
  output  auto_inner_i_mmio_buffer_in_d_bits_sink,
  output  auto_inner_i_mmio_buffer_in_d_bits_denied,
  output  [63:0] auto_inner_i_mmio_buffer_in_d_bits_data,
  output  auto_inner_i_mmio_buffer_in_d_bits_corrupt,
  output  auto_inner_ptw_to_l2_buffer_in_a_ready,
  input  auto_inner_ptw_to_l2_buffer_in_a_valid,
  input  [3:0] auto_inner_ptw_to_l2_buffer_in_a_bits_opcode,
  input  [2:0] auto_inner_ptw_to_l2_buffer_in_a_bits_param,
  input  [2:0] auto_inner_ptw_to_l2_buffer_in_a_bits_size,
  input  [2:0] auto_inner_ptw_to_l2_buffer_in_a_bits_source,
  input  [47:0] auto_inner_ptw_to_l2_buffer_in_a_bits_address,
  input  [4:0] auto_inner_ptw_to_l2_buffer_in_a_bits_user_reqSource,
  input  [31:0] auto_inner_ptw_to_l2_buffer_in_a_bits_mask,
  input  [255:0] auto_inner_ptw_to_l2_buffer_in_a_bits_data,
  input  auto_inner_ptw_to_l2_buffer_in_a_bits_corrupt,
  input  auto_inner_ptw_to_l2_buffer_in_d_ready,
  output  auto_inner_ptw_to_l2_buffer_in_d_valid,
  output  [3:0] auto_inner_ptw_to_l2_buffer_in_d_bits_opcode,
  output  [1:0] auto_inner_ptw_to_l2_buffer_in_d_bits_param,
  output  [2:0] auto_inner_ptw_to_l2_buffer_in_d_bits_size,
  output  [2:0] auto_inner_ptw_to_l2_buffer_in_d_bits_source,
  output  [9:0] auto_inner_ptw_to_l2_buffer_in_d_bits_sink,
  output  auto_inner_ptw_to_l2_buffer_in_d_bits_denied,
  output  [255:0] auto_inner_ptw_to_l2_buffer_in_d_bits_data,
  output  auto_inner_ptw_to_l2_buffer_in_d_bits_corrupt,
  output  auto_inner_logger_in_1_a_ready,
  input  auto_inner_logger_in_1_a_valid,
  input  [3:0] auto_inner_logger_in_1_a_bits_opcode,
  input  [2:0] auto_inner_logger_in_1_a_bits_param,
  input  [2:0] auto_inner_logger_in_1_a_bits_size,
  input  [3:0] auto_inner_logger_in_1_a_bits_source,
  input  [47:0] auto_inner_logger_in_1_a_bits_address,
  input  [1:0] auto_inner_logger_in_1_a_bits_user_alias,
  input  [4:0] auto_inner_logger_in_1_a_bits_user_reqSource,
  input  auto_inner_logger_in_1_a_bits_user_needHint,
  input  [31:0] auto_inner_logger_in_1_a_bits_mask,
  input  [255:0] auto_inner_logger_in_1_a_bits_data,
  input  auto_inner_logger_in_1_a_bits_corrupt,
  input  auto_inner_logger_in_1_d_ready,
  output  auto_inner_logger_in_1_d_valid,
  output  [3:0] auto_inner_logger_in_1_d_bits_opcode,
  output  [1:0] auto_inner_logger_in_1_d_bits_param,
  output  [2:0] auto_inner_logger_in_1_d_bits_size,
  output  [3:0] auto_inner_logger_in_1_d_bits_source,
  output  [9:0] auto_inner_logger_in_1_d_bits_sink,
  output  auto_inner_logger_in_1_d_bits_denied,
  output  [255:0] auto_inner_logger_in_1_d_bits_data,
  output  auto_inner_logger_in_1_d_bits_corrupt,
  output  auto_inner_logger_in_0_a_ready,
  input  auto_inner_logger_in_0_a_valid,
  input  [3:0] auto_inner_logger_in_0_a_bits_opcode,
  input  [2:0] auto_inner_logger_in_0_a_bits_param,
  input  [2:0] auto_inner_logger_in_0_a_bits_size,
  input  [5:0] auto_inner_logger_in_0_a_bits_source,
  input  [47:0] auto_inner_logger_in_0_a_bits_address,
  input  [1:0] auto_inner_logger_in_0_a_bits_user_alias,
  input  [43:0] auto_inner_logger_in_0_a_bits_user_vaddr,
  input  [4:0] auto_inner_logger_in_0_a_bits_user_reqSource,
  input  auto_inner_logger_in_0_a_bits_user_needHint,
  input  auto_inner_logger_in_0_a_bits_echo_isKeyword,
  input  [31:0] auto_inner_logger_in_0_a_bits_mask,
  input  [255:0] auto_inner_logger_in_0_a_bits_data,
  input  auto_inner_logger_in_0_a_bits_corrupt,
  input  auto_inner_logger_in_0_b_ready,
  output  auto_inner_logger_in_0_b_valid,
  output  [2:0] auto_inner_logger_in_0_b_bits_opcode,
  output  [1:0] auto_inner_logger_in_0_b_bits_param,
  output  [2:0] auto_inner_logger_in_0_b_bits_size,
  output  [5:0] auto_inner_logger_in_0_b_bits_source,
  output  [47:0] auto_inner_logger_in_0_b_bits_address,
  output  [31:0] auto_inner_logger_in_0_b_bits_mask,
  output  [255:0] auto_inner_logger_in_0_b_bits_data,
  output  auto_inner_logger_in_0_b_bits_corrupt,
  output  auto_inner_logger_in_0_c_ready,
  input  auto_inner_logger_in_0_c_valid,
  input  [2:0] auto_inner_logger_in_0_c_bits_opcode,
  input  [2:0] auto_inner_logger_in_0_c_bits_param,
  input  [2:0] auto_inner_logger_in_0_c_bits_size,
  input  [5:0] auto_inner_logger_in_0_c_bits_source,
  input  [47:0] auto_inner_logger_in_0_c_bits_address,
  input  [1:0] auto_inner_logger_in_0_c_bits_user_alias,
  input  [43:0] auto_inner_logger_in_0_c_bits_user_vaddr,
  input  [4:0] auto_inner_logger_in_0_c_bits_user_reqSource,
  input  auto_inner_logger_in_0_c_bits_user_needHint,
  input  auto_inner_logger_in_0_c_bits_echo_isKeyword,
  input  [255:0] auto_inner_logger_in_0_c_bits_data,
  input  auto_inner_logger_in_0_c_bits_corrupt,
  input  auto_inner_logger_in_0_d_ready,
  output  auto_inner_logger_in_0_d_valid,
  output  [3:0] auto_inner_logger_in_0_d_bits_opcode,
  output  [1:0] auto_inner_logger_in_0_d_bits_param,
  output  [2:0] auto_inner_logger_in_0_d_bits_size,
  output  [5:0] auto_inner_logger_in_0_d_bits_source,
  output  [9:0] auto_inner_logger_in_0_d_bits_sink,
  output  auto_inner_logger_in_0_d_bits_denied,
  output  auto_inner_logger_in_0_d_bits_echo_isKeyword,
  output  [255:0] auto_inner_logger_in_0_d_bits_data,
  output  auto_inner_logger_in_0_d_bits_corrupt,
  output  auto_inner_logger_in_0_e_ready,
  input  auto_inner_logger_in_0_e_valid,
  input  [9:0] auto_inner_logger_in_0_e_bits_sink,
  output  auto_inner_beu_int_out_0,
  output  auto_inner_beu_local_int_source_out_0,
  input  auto_inner_nmi_int_in_0,
  input  auto_inner_nmi_int_in_1,
  output  auto_inner_nmi_int_out_0,
  output  auto_inner_nmi_int_out_1,
  input  auto_inner_plic_int_in_1_0,
  input  auto_inner_plic_int_in_0_0,
  output  auto_inner_plic_int_out_1_0,
  output  auto_inner_plic_int_out_0_0,
  input  auto_inner_debug_int_in_0,
  output  auto_inner_debug_int_out_0,
  input  auto_inner_clint_int_in_0,
  input  auto_inner_clint_int_in_1,
  output  auto_inner_clint_int_out_0,
  output  auto_inner_clint_int_out_1,
  input  io_beu_errors_icache_ecc_error_valid,
  input  [47:0] io_beu_errors_icache_ecc_error_bits,
  input  io_beu_errors_dcache_ecc_error_valid,
  input  [47:0] io_beu_errors_dcache_ecc_error_bits,
  input  io_beu_errors_uncache_ecc_error_valid,
  input  [47:0] io_beu_errors_uncache_ecc_error_bits,
  input  [47:0] io_reset_vector_fromTile,
  output  [47:0] io_reset_vector_toCore,
  input  [63:0] io_hartId_fromTile,
  output  [63:0] io_hartId_toCore,
  input  io_msiInfo_fromTile_valid,
  input  [10:0] io_msiInfo_fromTile_bits,
  output  io_msiInfo_toCore_valid,
  output  [10:0] io_msiInfo_toCore_bits,
  input  io_cpu_halt_fromCore,
  output  io_cpu_halt_toTile,
  input  io_cpu_critical_error_fromCore,
  output  io_cpu_critical_error_toTile,
  input  io_hartIsInReset_resetInFrontend,
  output  io_hartIsInReset_toTile,
  output  io_traceCoreInterface_fromCore_fromEncoder_enable,
  output  io_traceCoreInterface_fromCore_fromEncoder_stall,
  input  [2:0] io_traceCoreInterface_fromCore_toEncoder_priv,
  input  [63:0] io_traceCoreInterface_fromCore_toEncoder_trap_cause,
  input  [49:0] io_traceCoreInterface_fromCore_toEncoder_trap_tval,
  input  io_traceCoreInterface_fromCore_toEncoder_groups_0_valid,
  input  [49:0] io_traceCoreInterface_fromCore_toEncoder_groups_0_bits_iaddr,
  input  [3:0] io_traceCoreInterface_fromCore_toEncoder_groups_0_bits_itype,
  input  [6:0] io_traceCoreInterface_fromCore_toEncoder_groups_0_bits_iretire,
  input  io_traceCoreInterface_fromCore_toEncoder_groups_0_bits_ilastsize,
  input  io_traceCoreInterface_fromCore_toEncoder_groups_1_valid,
  input  [49:0] io_traceCoreInterface_fromCore_toEncoder_groups_1_bits_iaddr,
  input  [3:0] io_traceCoreInterface_fromCore_toEncoder_groups_1_bits_itype,
  input  [6:0] io_traceCoreInterface_fromCore_toEncoder_groups_1_bits_iretire,
  input  io_traceCoreInterface_fromCore_toEncoder_groups_1_bits_ilastsize,
  input  io_traceCoreInterface_fromCore_toEncoder_groups_2_valid,
  input  [49:0] io_traceCoreInterface_fromCore_toEncoder_groups_2_bits_iaddr,
  input  [3:0] io_traceCoreInterface_fromCore_toEncoder_groups_2_bits_itype,
  input  [6:0] io_traceCoreInterface_fromCore_toEncoder_groups_2_bits_iretire,
  input  io_traceCoreInterface_fromCore_toEncoder_groups_2_bits_ilastsize,
  input  io_traceCoreInterface_toTile_fromEncoder_enable,
  input  io_traceCoreInterface_toTile_fromEncoder_stall,
  output  [2:0] io_traceCoreInterface_toTile_toEncoder_priv,
  output  [63:0] io_traceCoreInterface_toTile_toEncoder_trap_cause,
  output  [49:0] io_traceCoreInterface_toTile_toEncoder_trap_tval,
  output  [49:0] io_traceCoreInterface_toTile_toEncoder_groups_0_bits_iaddr,
  output  [3:0] io_traceCoreInterface_toTile_toEncoder_groups_0_bits_itype,
  output  [6:0] io_traceCoreInterface_toTile_toEncoder_groups_0_bits_iretire,
  output  io_traceCoreInterface_toTile_toEncoder_groups_0_bits_ilastsize,
  output  [49:0] io_traceCoreInterface_toTile_toEncoder_groups_1_bits_iaddr,
  output  [3:0] io_traceCoreInterface_toTile_toEncoder_groups_1_bits_itype,
  output  [6:0] io_traceCoreInterface_toTile_toEncoder_groups_1_bits_iretire,
  output  io_traceCoreInterface_toTile_toEncoder_groups_1_bits_ilastsize,
  output  [49:0] io_traceCoreInterface_toTile_toEncoder_groups_2_bits_iaddr,
  output  [3:0] io_traceCoreInterface_toTile_toEncoder_groups_2_bits_itype,
  output  [6:0] io_traceCoreInterface_toTile_toEncoder_groups_2_bits_iretire,
  output  io_traceCoreInterface_toTile_toEncoder_groups_2_bits_ilastsize,
  input  io_debugTopDown_robHeadPaddr_valid,
  input  [35:0] io_debugTopDown_robHeadPaddr_bits,
  output  io_debugTopDown_l2MissMatch,
  output  io_l2Miss,
  input  io_l3Miss_fromTile,
  output  io_l3Miss_toCore,
  input  io_clintTime_fromTile_valid,
  input  [63:0] io_clintTime_fromTile_bits,
  output  io_clintTime_toCore_valid,
  output  [63:0] io_clintTime_toCore_bits,
  output  io_chi_txsactive,
  input  io_chi_rxsactive,
  output  io_chi_syscoreq,
  input  io_chi_syscoack,
  output  io_chi_tx_linkactivereq,
  input  io_chi_tx_linkactiveack,
  output  io_chi_tx_req_flitpend,
  output  io_chi_tx_req_flitv,
  output  [161:0] io_chi_tx_req_flit,
  input  io_chi_tx_req_lcrdv,
  output  io_chi_tx_rsp_flitpend,
  output  io_chi_tx_rsp_flitv,
  output  [72:0] io_chi_tx_rsp_flit,
  input  io_chi_tx_rsp_lcrdv,
  output  io_chi_tx_dat_flitpend,
  output  io_chi_tx_dat_flitv,
  output  [421:0] io_chi_tx_dat_flit,
  input  io_chi_tx_dat_lcrdv,
  input  io_chi_rx_linkactivereq,
  output  io_chi_rx_linkactiveack,
  input  io_chi_rx_rsp_flitpend,
  input  io_chi_rx_rsp_flitv,
  input  [72:0] io_chi_rx_rsp_flit,
  output  io_chi_rx_rsp_lcrdv,
  input  io_chi_rx_dat_flitpend,
  input  io_chi_rx_dat_flitv,
  input  [421:0] io_chi_rx_dat_flit,
  output  io_chi_rx_dat_lcrdv,
  input  io_chi_rx_snp_flitpend,
  input  io_chi_rx_snp_flitv,
  input  [114:0] io_chi_rx_snp_flit,
  output  io_chi_rx_snp_lcrdv,
  input  [10:0] io_nodeID,
  input  io_pfCtrlFromCore_l2_pf_master_en,
  input  io_pfCtrlFromCore_l2_pf_recv_en,
  input  io_pfCtrlFromCore_l2_pbop_en,
  input  io_pfCtrlFromCore_l2_vbop_en,
  output  io_l2_tlb_req_req_valid,
  output  [49:0] io_l2_tlb_req_req_bits_vaddr,
  output  [2:0] io_l2_tlb_req_req_bits_cmd,
  output  io_l2_tlb_req_req_bits_kill,
  output  io_l2_tlb_req_req_bits_no_translate,
  input  io_l2_tlb_req_resp_valid,
  input  [47:0] io_l2_tlb_req_resp_bits_paddr_0,
  input  [1:0] io_l2_tlb_req_resp_bits_pbmt_0,
  input  io_l2_tlb_req_resp_bits_miss,
  input  io_l2_tlb_req_resp_bits_excp_0_gpf_ld,
  input  io_l2_tlb_req_resp_bits_excp_0_pf_ld,
  input  io_l2_tlb_req_resp_bits_excp_0_af_ld,
  input  io_l2_pmp_resp_ld,
  input  io_l2_pmp_resp_mmio,
  output  io_l2_hint_valid,
  output  [3:0] io_l2_hint_bits_sourceId,
  output  io_l2_hint_bits_isKeyword,
  output  [5:0] io_perfEvents_1_value,
  output  [5:0] io_perfEvents_2_value,
  output  [5:0] io_perfEvents_3_value,
  output  [5:0] io_perfEvents_4_value,
  output  [5:0] io_perfEvents_5_value,
  output  [5:0] io_perfEvents_6_value,
  output  [5:0] io_perfEvents_7_value,
  output  [5:0] io_perfEvents_8_value,
  output  [5:0] io_perfEvents_9_value,
  output  [5:0] io_perfEvents_10_value,
  output  [5:0] io_perfEvents_11_value,
  output  [5:0] io_perfEvents_12_value,
  output  [5:0] io_perfEvents_13_value,
  output  [5:0] io_perfEvents_14_value,
  output  [5:0] io_perfEvents_15_value,
  output  [5:0] io_perfEvents_16_value,
  output  [5:0] io_perfEvents_17_value,
  output  [5:0] io_perfEvents_18_value,
  output  [5:0] io_perfEvents_19_value,
  output  [5:0] io_perfEvents_20_value,
  output  [5:0] io_perfEvents_21_value,
  output  [5:0] io_perfEvents_22_value,
  output  [5:0] io_perfEvents_23_value,
  output  [5:0] io_perfEvents_24_value,
  output  [5:0] io_perfEvents_25_value,
  output  [5:0] io_perfEvents_26_value,
  output  [5:0] io_perfEvents_27_value,
  output  [5:0] io_perfEvents_28_value,
  output  [5:0] io_perfEvents_29_value,
  output  [5:0] io_perfEvents_30_value,
  output  [5:0] io_perfEvents_31_value,
  output  [5:0] io_perfEvents_32_value,
  output  [5:0] io_perfEvents_33_value,
  output  [5:0] io_perfEvents_34_value,
  output  [5:0] io_perfEvents_35_value,
  output  [5:0] io_perfEvents_36_value,
  output  [5:0] io_perfEvents_37_value,
  output  [5:0] io_perfEvents_38_value,
  output  [5:0] io_perfEvents_39_value,
  output  [5:0] io_perfEvents_40_value,
  output  [5:0] io_perfEvents_41_value,
  output  [5:0] io_perfEvents_42_value,
  output  [5:0] io_perfEvents_43_value,
  output  [5:0] io_perfEvents_44_value,
  output  [5:0] io_perfEvents_45_value,
  output  [5:0] io_perfEvents_46_value,
  output  [5:0] io_perfEvents_47_value,
  output  [5:0] io_perfEvents_48_value,
  input  io_dft_ram_hold,
  input  io_dft_ram_bypass,
  input  io_dft_ram_bp_clken,
  input  io_dft_ram_aux_clk,
  input  io_dft_ram_aux_ckbp,
  input  io_dft_ram_mcp_hold,
  input  io_dft_cgen
);
  assign auto_inner_buffers_out_a_valid = '0;
  assign auto_inner_buffers_out_a_bits_opcode = '0;
  assign auto_inner_buffers_out_a_bits_param = '0;
  assign auto_inner_buffers_out_a_bits_size = '0;
  assign auto_inner_buffers_out_a_bits_source = '0;
  assign auto_inner_buffers_out_a_bits_address = '0;
  assign auto_inner_buffers_out_a_bits_mask = '0;
  assign auto_inner_buffers_out_a_bits_data = '0;
  assign auto_inner_buffers_out_a_bits_corrupt = '0;
  assign auto_inner_buffers_out_d_ready = '0;
  assign auto_inner_buffers_in_a_ready = '0;
  assign auto_inner_buffers_in_d_valid = '0;
  assign auto_inner_buffers_in_d_bits_opcode = '0;
  assign auto_inner_buffers_in_d_bits_param = '0;
  assign auto_inner_buffers_in_d_bits_size = '0;
  assign auto_inner_buffers_in_d_bits_source = '0;
  assign auto_inner_buffers_in_d_bits_sink = '0;
  assign auto_inner_buffers_in_d_bits_denied = '0;
  assign auto_inner_buffers_in_d_bits_data = '0;
  assign auto_inner_buffers_in_d_bits_corrupt = '0;
  assign auto_inner_i_mmio_buffer_in_a_ready = '0;
  assign auto_inner_i_mmio_buffer_in_d_valid = '0;
  assign auto_inner_i_mmio_buffer_in_d_bits_opcode = '0;
  assign auto_inner_i_mmio_buffer_in_d_bits_param = '0;
  assign auto_inner_i_mmio_buffer_in_d_bits_size = '0;
  assign auto_inner_i_mmio_buffer_in_d_bits_source = '0;
  assign auto_inner_i_mmio_buffer_in_d_bits_sink = '0;
  assign auto_inner_i_mmio_buffer_in_d_bits_denied = '0;
  assign auto_inner_i_mmio_buffer_in_d_bits_data = '0;
  assign auto_inner_i_mmio_buffer_in_d_bits_corrupt = '0;
  assign auto_inner_ptw_to_l2_buffer_in_a_ready = '0;
  assign auto_inner_ptw_to_l2_buffer_in_d_valid = '0;
  assign auto_inner_ptw_to_l2_buffer_in_d_bits_opcode = '0;
  assign auto_inner_ptw_to_l2_buffer_in_d_bits_param = '0;
  assign auto_inner_ptw_to_l2_buffer_in_d_bits_size = '0;
  assign auto_inner_ptw_to_l2_buffer_in_d_bits_source = '0;
  assign auto_inner_ptw_to_l2_buffer_in_d_bits_sink = '0;
  assign auto_inner_ptw_to_l2_buffer_in_d_bits_denied = '0;
  assign auto_inner_ptw_to_l2_buffer_in_d_bits_data = '0;
  assign auto_inner_ptw_to_l2_buffer_in_d_bits_corrupt = '0;
  assign auto_inner_logger_in_1_a_ready = '0;
  assign auto_inner_logger_in_1_d_valid = '0;
  assign auto_inner_logger_in_1_d_bits_opcode = '0;
  assign auto_inner_logger_in_1_d_bits_param = '0;
  assign auto_inner_logger_in_1_d_bits_size = '0;
  assign auto_inner_logger_in_1_d_bits_source = '0;
  assign auto_inner_logger_in_1_d_bits_sink = '0;
  assign auto_inner_logger_in_1_d_bits_denied = '0;
  assign auto_inner_logger_in_1_d_bits_data = '0;
  assign auto_inner_logger_in_1_d_bits_corrupt = '0;
  assign auto_inner_logger_in_0_a_ready = '0;
  assign auto_inner_logger_in_0_b_valid = '0;
  assign auto_inner_logger_in_0_b_bits_opcode = '0;
  assign auto_inner_logger_in_0_b_bits_param = '0;
  assign auto_inner_logger_in_0_b_bits_size = '0;
  assign auto_inner_logger_in_0_b_bits_source = '0;
  assign auto_inner_logger_in_0_b_bits_address = '0;
  assign auto_inner_logger_in_0_b_bits_mask = '0;
  assign auto_inner_logger_in_0_b_bits_data = '0;
  assign auto_inner_logger_in_0_b_bits_corrupt = '0;
  assign auto_inner_logger_in_0_c_ready = '0;
  assign auto_inner_logger_in_0_d_valid = '0;
  assign auto_inner_logger_in_0_d_bits_opcode = '0;
  assign auto_inner_logger_in_0_d_bits_param = '0;
  assign auto_inner_logger_in_0_d_bits_size = '0;
  assign auto_inner_logger_in_0_d_bits_source = '0;
  assign auto_inner_logger_in_0_d_bits_sink = '0;
  assign auto_inner_logger_in_0_d_bits_denied = '0;
  assign auto_inner_logger_in_0_d_bits_echo_isKeyword = '0;
  assign auto_inner_logger_in_0_d_bits_data = '0;
  assign auto_inner_logger_in_0_d_bits_corrupt = '0;
  assign auto_inner_logger_in_0_e_ready = '0;
  assign auto_inner_beu_int_out_0 = '0;
  assign auto_inner_beu_local_int_source_out_0 = '0;
  assign auto_inner_nmi_int_out_0 = '0;
  assign auto_inner_nmi_int_out_1 = '0;
  assign auto_inner_plic_int_out_1_0 = '0;
  assign auto_inner_plic_int_out_0_0 = '0;
  assign auto_inner_debug_int_out_0 = '0;
  assign auto_inner_clint_int_out_0 = '0;
  assign auto_inner_clint_int_out_1 = '0;
  assign io_reset_vector_toCore = '0;
  assign io_hartId_toCore = '0;
  assign io_msiInfo_toCore_valid = '0;
  assign io_msiInfo_toCore_bits = '0;
  assign io_cpu_halt_toTile = '0;
  assign io_cpu_critical_error_toTile = '0;
  assign io_hartIsInReset_toTile = '0;
  assign io_traceCoreInterface_fromCore_fromEncoder_enable = '0;
  assign io_traceCoreInterface_fromCore_fromEncoder_stall = '0;
  assign io_traceCoreInterface_toTile_toEncoder_priv = '0;
  assign io_traceCoreInterface_toTile_toEncoder_trap_cause = '0;
  assign io_traceCoreInterface_toTile_toEncoder_trap_tval = '0;
  assign io_traceCoreInterface_toTile_toEncoder_groups_0_bits_iaddr = '0;
  assign io_traceCoreInterface_toTile_toEncoder_groups_0_bits_itype = '0;
  assign io_traceCoreInterface_toTile_toEncoder_groups_0_bits_iretire = '0;
  assign io_traceCoreInterface_toTile_toEncoder_groups_0_bits_ilastsize = '0;
  assign io_traceCoreInterface_toTile_toEncoder_groups_1_bits_iaddr = '0;
  assign io_traceCoreInterface_toTile_toEncoder_groups_1_bits_itype = '0;
  assign io_traceCoreInterface_toTile_toEncoder_groups_1_bits_iretire = '0;
  assign io_traceCoreInterface_toTile_toEncoder_groups_1_bits_ilastsize = '0;
  assign io_traceCoreInterface_toTile_toEncoder_groups_2_bits_iaddr = '0;
  assign io_traceCoreInterface_toTile_toEncoder_groups_2_bits_itype = '0;
  assign io_traceCoreInterface_toTile_toEncoder_groups_2_bits_iretire = '0;
  assign io_traceCoreInterface_toTile_toEncoder_groups_2_bits_ilastsize = '0;
  assign io_debugTopDown_l2MissMatch = '0;
  assign io_l2Miss = '0;
  assign io_l3Miss_toCore = '0;
  assign io_clintTime_toCore_valid = '0;
  assign io_clintTime_toCore_bits = '0;
  assign io_chi_txsactive = '0;
  assign io_chi_syscoreq = '0;
  assign io_chi_tx_linkactivereq = '0;
  assign io_chi_tx_req_flitpend = '0;
  assign io_chi_tx_req_flitv = '0;
  assign io_chi_tx_req_flit = '0;
  assign io_chi_tx_rsp_flitpend = '0;
  assign io_chi_tx_rsp_flitv = '0;
  assign io_chi_tx_rsp_flit = '0;
  assign io_chi_tx_dat_flitpend = '0;
  assign io_chi_tx_dat_flitv = '0;
  assign io_chi_tx_dat_flit = '0;
  assign io_chi_rx_linkactiveack = '0;
  assign io_chi_rx_rsp_lcrdv = '0;
  assign io_chi_rx_dat_lcrdv = '0;
  assign io_chi_rx_snp_lcrdv = '0;
  assign io_l2_tlb_req_req_valid = '0;
  assign io_l2_tlb_req_req_bits_vaddr = '0;
  assign io_l2_tlb_req_req_bits_cmd = '0;
  assign io_l2_tlb_req_req_bits_kill = '0;
  assign io_l2_tlb_req_req_bits_no_translate = '0;
  assign io_l2_hint_valid = '0;
  assign io_l2_hint_bits_sourceId = '0;
  assign io_l2_hint_bits_isKeyword = '0;
  assign io_perfEvents_1_value = '0;
  assign io_perfEvents_2_value = '0;
  assign io_perfEvents_3_value = '0;
  assign io_perfEvents_4_value = '0;
  assign io_perfEvents_5_value = '0;
  assign io_perfEvents_6_value = '0;
  assign io_perfEvents_7_value = '0;
  assign io_perfEvents_8_value = '0;
  assign io_perfEvents_9_value = '0;
  assign io_perfEvents_10_value = '0;
  assign io_perfEvents_11_value = '0;
  assign io_perfEvents_12_value = '0;
  assign io_perfEvents_13_value = '0;
  assign io_perfEvents_14_value = '0;
  assign io_perfEvents_15_value = '0;
  assign io_perfEvents_16_value = '0;
  assign io_perfEvents_17_value = '0;
  assign io_perfEvents_18_value = '0;
  assign io_perfEvents_19_value = '0;
  assign io_perfEvents_20_value = '0;
  assign io_perfEvents_21_value = '0;
  assign io_perfEvents_22_value = '0;
  assign io_perfEvents_23_value = '0;
  assign io_perfEvents_24_value = '0;
  assign io_perfEvents_25_value = '0;
  assign io_perfEvents_26_value = '0;
  assign io_perfEvents_27_value = '0;
  assign io_perfEvents_28_value = '0;
  assign io_perfEvents_29_value = '0;
  assign io_perfEvents_30_value = '0;
  assign io_perfEvents_31_value = '0;
  assign io_perfEvents_32_value = '0;
  assign io_perfEvents_33_value = '0;
  assign io_perfEvents_34_value = '0;
  assign io_perfEvents_35_value = '0;
  assign io_perfEvents_36_value = '0;
  assign io_perfEvents_37_value = '0;
  assign io_perfEvents_38_value = '0;
  assign io_perfEvents_39_value = '0;
  assign io_perfEvents_40_value = '0;
  assign io_perfEvents_41_value = '0;
  assign io_perfEvents_42_value = '0;
  assign io_perfEvents_43_value = '0;
  assign io_perfEvents_44_value = '0;
  assign io_perfEvents_45_value = '0;
  assign io_perfEvents_46_value = '0;
  assign io_perfEvents_47_value = '0;
  assign io_perfEvents_48_value = '0;
endmodule

module XSCore(
  input  clock,
  input  reset,
  input  auto_memBlock_inner_buffers_out_a_ready,
  output  auto_memBlock_inner_buffers_out_a_valid,
  output  [3:0] auto_memBlock_inner_buffers_out_a_bits_opcode,
  output  [2:0] auto_memBlock_inner_buffers_out_a_bits_param,
  output  [1:0] auto_memBlock_inner_buffers_out_a_bits_size,
  output  [1:0] auto_memBlock_inner_buffers_out_a_bits_source,
  output  [47:0] auto_memBlock_inner_buffers_out_a_bits_address,
  output  auto_memBlock_inner_buffers_out_a_bits_user_memBackType_MM,
  output  auto_memBlock_inner_buffers_out_a_bits_user_memPageType_NC,
  output  [7:0] auto_memBlock_inner_buffers_out_a_bits_mask,
  output  [63:0] auto_memBlock_inner_buffers_out_a_bits_data,
  output  auto_memBlock_inner_buffers_out_a_bits_corrupt,
  output  auto_memBlock_inner_buffers_out_d_ready,
  input  auto_memBlock_inner_buffers_out_d_valid,
  input  [3:0] auto_memBlock_inner_buffers_out_d_bits_opcode,
  input  [1:0] auto_memBlock_inner_buffers_out_d_bits_param,
  input  [1:0] auto_memBlock_inner_buffers_out_d_bits_size,
  input  [1:0] auto_memBlock_inner_buffers_out_d_bits_source,
  input  auto_memBlock_inner_buffers_out_d_bits_sink,
  input  auto_memBlock_inner_buffers_out_d_bits_denied,
  input  [63:0] auto_memBlock_inner_buffers_out_d_bits_data,
  input  auto_memBlock_inner_buffers_out_d_bits_corrupt,
  input  auto_memBlock_inner_frontendBridge_instr_uncache_out_a_ready,
  output  auto_memBlock_inner_frontendBridge_instr_uncache_out_a_valid,
  output  [2:0] auto_memBlock_inner_frontendBridge_instr_uncache_out_a_bits_param,
  output  [47:0] auto_memBlock_inner_frontendBridge_instr_uncache_out_a_bits_address,
  output  auto_memBlock_inner_frontendBridge_instr_uncache_out_a_bits_corrupt,
  output  auto_memBlock_inner_frontendBridge_instr_uncache_out_d_ready,
  input  auto_memBlock_inner_frontendBridge_instr_uncache_out_d_valid,
  input  [3:0] auto_memBlock_inner_frontendBridge_instr_uncache_out_d_bits_opcode,
  input  [1:0] auto_memBlock_inner_frontendBridge_instr_uncache_out_d_bits_param,
  input  [1:0] auto_memBlock_inner_frontendBridge_instr_uncache_out_d_bits_size,
  input  auto_memBlock_inner_frontendBridge_instr_uncache_out_d_bits_source,
  input  auto_memBlock_inner_frontendBridge_instr_uncache_out_d_bits_sink,
  input  auto_memBlock_inner_frontendBridge_instr_uncache_out_d_bits_denied,
  input  [63:0] auto_memBlock_inner_frontendBridge_instr_uncache_out_d_bits_data,
  input  auto_memBlock_inner_frontendBridge_instr_uncache_out_d_bits_corrupt,
  output  auto_memBlock_inner_frontendBridge_icachectrl_in_a_ready,
  input  auto_memBlock_inner_frontendBridge_icachectrl_in_a_valid,
  input  [3:0] auto_memBlock_inner_frontendBridge_icachectrl_in_a_bits_opcode,
  input  [2:0] auto_memBlock_inner_frontendBridge_icachectrl_in_a_bits_param,
  input  [1:0] auto_memBlock_inner_frontendBridge_icachectrl_in_a_bits_size,
  input  [2:0] auto_memBlock_inner_frontendBridge_icachectrl_in_a_bits_source,
  input  [29:0] auto_memBlock_inner_frontendBridge_icachectrl_in_a_bits_address,
  input  [7:0] auto_memBlock_inner_frontendBridge_icachectrl_in_a_bits_mask,
  input  [63:0] auto_memBlock_inner_frontendBridge_icachectrl_in_a_bits_data,
  input  auto_memBlock_inner_frontendBridge_icachectrl_in_a_bits_corrupt,
  input  auto_memBlock_inner_frontendBridge_icachectrl_in_d_ready,
  output  auto_memBlock_inner_frontendBridge_icachectrl_in_d_valid,
  output  [3:0] auto_memBlock_inner_frontendBridge_icachectrl_in_d_bits_opcode,
  output  [1:0] auto_memBlock_inner_frontendBridge_icachectrl_in_d_bits_param,
  output  [1:0] auto_memBlock_inner_frontendBridge_icachectrl_in_d_bits_size,
  output  [2:0] auto_memBlock_inner_frontendBridge_icachectrl_in_d_bits_source,
  output  auto_memBlock_inner_frontendBridge_icachectrl_in_d_bits_sink,
  output  auto_memBlock_inner_frontendBridge_icachectrl_in_d_bits_denied,
  output  [63:0] auto_memBlock_inner_frontendBridge_icachectrl_in_d_bits_data,
  output  auto_memBlock_inner_frontendBridge_icachectrl_in_d_bits_corrupt,
  input  auto_memBlock_inner_frontendBridge_icache_out_a_ready,
  output  auto_memBlock_inner_frontendBridge_icache_out_a_valid,
  output  [3:0] auto_memBlock_inner_frontendBridge_icache_out_a_bits_opcode,
  output  [2:0] auto_memBlock_inner_frontendBridge_icache_out_a_bits_param,
  output  [2:0] auto_memBlock_inner_frontendBridge_icache_out_a_bits_size,
  output  [3:0] auto_memBlock_inner_frontendBridge_icache_out_a_bits_source,
  output  [47:0] auto_memBlock_inner_frontendBridge_icache_out_a_bits_address,
  output  [1:0] auto_memBlock_inner_frontendBridge_icache_out_a_bits_user_alias,
  output  [4:0] auto_memBlock_inner_frontendBridge_icache_out_a_bits_user_reqSource,
  output  auto_memBlock_inner_frontendBridge_icache_out_a_bits_user_needHint,
  output  [31:0] auto_memBlock_inner_frontendBridge_icache_out_a_bits_mask,
  output  [255:0] auto_memBlock_inner_frontendBridge_icache_out_a_bits_data,
  output  auto_memBlock_inner_frontendBridge_icache_out_a_bits_corrupt,
  output  auto_memBlock_inner_frontendBridge_icache_out_d_ready,
  input  auto_memBlock_inner_frontendBridge_icache_out_d_valid,
  input  [3:0] auto_memBlock_inner_frontendBridge_icache_out_d_bits_opcode,
  input  [1:0] auto_memBlock_inner_frontendBridge_icache_out_d_bits_param,
  input  [2:0] auto_memBlock_inner_frontendBridge_icache_out_d_bits_size,
  input  [3:0] auto_memBlock_inner_frontendBridge_icache_out_d_bits_source,
  input  [9:0] auto_memBlock_inner_frontendBridge_icache_out_d_bits_sink,
  input  auto_memBlock_inner_frontendBridge_icache_out_d_bits_denied,
  input  [255:0] auto_memBlock_inner_frontendBridge_icache_out_d_bits_data,
  input  auto_memBlock_inner_frontendBridge_icache_out_d_bits_corrupt,
  input  auto_memBlock_inner_ptw_to_l2_buffer_out_a_ready,
  output  auto_memBlock_inner_ptw_to_l2_buffer_out_a_valid,
  output  [3:0] auto_memBlock_inner_ptw_to_l2_buffer_out_a_bits_opcode,
  output  [2:0] auto_memBlock_inner_ptw_to_l2_buffer_out_a_bits_param,
  output  [2:0] auto_memBlock_inner_ptw_to_l2_buffer_out_a_bits_size,
  output  [2:0] auto_memBlock_inner_ptw_to_l2_buffer_out_a_bits_source,
  output  [47:0] auto_memBlock_inner_ptw_to_l2_buffer_out_a_bits_address,
  output  [4:0] auto_memBlock_inner_ptw_to_l2_buffer_out_a_bits_user_reqSource,
  output  [31:0] auto_memBlock_inner_ptw_to_l2_buffer_out_a_bits_mask,
  output  [255:0] auto_memBlock_inner_ptw_to_l2_buffer_out_a_bits_data,
  output  auto_memBlock_inner_ptw_to_l2_buffer_out_a_bits_corrupt,
  output  auto_memBlock_inner_ptw_to_l2_buffer_out_d_ready,
  input  auto_memBlock_inner_ptw_to_l2_buffer_out_d_valid,
  input  [3:0] auto_memBlock_inner_ptw_to_l2_buffer_out_d_bits_opcode,
  input  [1:0] auto_memBlock_inner_ptw_to_l2_buffer_out_d_bits_param,
  input  [2:0] auto_memBlock_inner_ptw_to_l2_buffer_out_d_bits_size,
  input  [2:0] auto_memBlock_inner_ptw_to_l2_buffer_out_d_bits_source,
  input  [9:0] auto_memBlock_inner_ptw_to_l2_buffer_out_d_bits_sink,
  input  auto_memBlock_inner_ptw_to_l2_buffer_out_d_bits_denied,
  input  [255:0] auto_memBlock_inner_ptw_to_l2_buffer_out_d_bits_data,
  input  auto_memBlock_inner_ptw_to_l2_buffer_out_d_bits_corrupt,
  input  auto_memBlock_inner_beu_local_int_sink_in_0,
  input  auto_memBlock_inner_nmi_int_sink_in_0,
  input  auto_memBlock_inner_nmi_int_sink_in_1,
  input  auto_memBlock_inner_plic_int_sink_in_1_0,
  input  auto_memBlock_inner_plic_int_sink_in_0_0,
  input  auto_memBlock_inner_debug_int_sink_in_0,
  input  auto_memBlock_inner_clint_int_sink_in_0,
  input  auto_memBlock_inner_clint_int_sink_in_1,
  output  [63:0] auto_memBlock_inner_l2_pf_sender_out_addr,
  output  [4:0] auto_memBlock_inner_l2_pf_sender_out_pf_source,
  output  auto_memBlock_inner_l2_pf_sender_out_addr_valid,
  input  auto_memBlock_inner_dcache_client_out_a_ready,
  output  auto_memBlock_inner_dcache_client_out_a_valid,
  output  [3:0] auto_memBlock_inner_dcache_client_out_a_bits_opcode,
  output  [2:0] auto_memBlock_inner_dcache_client_out_a_bits_param,
  output  [2:0] auto_memBlock_inner_dcache_client_out_a_bits_size,
  output  [5:0] auto_memBlock_inner_dcache_client_out_a_bits_source,
  output  [47:0] auto_memBlock_inner_dcache_client_out_a_bits_address,
  output  [1:0] auto_memBlock_inner_dcache_client_out_a_bits_user_alias,
  output  [43:0] auto_memBlock_inner_dcache_client_out_a_bits_user_vaddr,
  output  [4:0] auto_memBlock_inner_dcache_client_out_a_bits_user_reqSource,
  output  auto_memBlock_inner_dcache_client_out_a_bits_user_needHint,
  output  auto_memBlock_inner_dcache_client_out_a_bits_echo_isKeyword,
  output  [31:0] auto_memBlock_inner_dcache_client_out_a_bits_mask,
  output  [255:0] auto_memBlock_inner_dcache_client_out_a_bits_data,
  output  auto_memBlock_inner_dcache_client_out_a_bits_corrupt,
  output  auto_memBlock_inner_dcache_client_out_b_ready,
  input  auto_memBlock_inner_dcache_client_out_b_valid,
  input  [2:0] auto_memBlock_inner_dcache_client_out_b_bits_opcode,
  input  [1:0] auto_memBlock_inner_dcache_client_out_b_bits_param,
  input  [2:0] auto_memBlock_inner_dcache_client_out_b_bits_size,
  input  [5:0] auto_memBlock_inner_dcache_client_out_b_bits_source,
  input  [47:0] auto_memBlock_inner_dcache_client_out_b_bits_address,
  input  [31:0] auto_memBlock_inner_dcache_client_out_b_bits_mask,
  input  [255:0] auto_memBlock_inner_dcache_client_out_b_bits_data,
  input  auto_memBlock_inner_dcache_client_out_b_bits_corrupt,
  input  auto_memBlock_inner_dcache_client_out_c_ready,
  output  auto_memBlock_inner_dcache_client_out_c_valid,
  output  [2:0] auto_memBlock_inner_dcache_client_out_c_bits_opcode,
  output  [2:0] auto_memBlock_inner_dcache_client_out_c_bits_param,
  output  [2:0] auto_memBlock_inner_dcache_client_out_c_bits_size,
  output  [5:0] auto_memBlock_inner_dcache_client_out_c_bits_source,
  output  [47:0] auto_memBlock_inner_dcache_client_out_c_bits_address,
  output  [1:0] auto_memBlock_inner_dcache_client_out_c_bits_user_alias,
  output  [43:0] auto_memBlock_inner_dcache_client_out_c_bits_user_vaddr,
  output  [4:0] auto_memBlock_inner_dcache_client_out_c_bits_user_reqSource,
  output  auto_memBlock_inner_dcache_client_out_c_bits_user_needHint,
  output  auto_memBlock_inner_dcache_client_out_c_bits_echo_isKeyword,
  output  [255:0] auto_memBlock_inner_dcache_client_out_c_bits_data,
  output  auto_memBlock_inner_dcache_client_out_c_bits_corrupt,
  output  auto_memBlock_inner_dcache_client_out_d_ready,
  input  auto_memBlock_inner_dcache_client_out_d_valid,
  input  [3:0] auto_memBlock_inner_dcache_client_out_d_bits_opcode,
  input  [1:0] auto_memBlock_inner_dcache_client_out_d_bits_param,
  input  [2:0] auto_memBlock_inner_dcache_client_out_d_bits_size,
  input  [5:0] auto_memBlock_inner_dcache_client_out_d_bits_source,
  input  [9:0] auto_memBlock_inner_dcache_client_out_d_bits_sink,
  input  auto_memBlock_inner_dcache_client_out_d_bits_denied,
  input  auto_memBlock_inner_dcache_client_out_d_bits_echo_isKeyword,
  input  [255:0] auto_memBlock_inner_dcache_client_out_d_bits_data,
  input  auto_memBlock_inner_dcache_client_out_d_bits_corrupt,
  input  auto_memBlock_inner_dcache_client_out_e_ready,
  output  auto_memBlock_inner_dcache_client_out_e_valid,
  output  [9:0] auto_memBlock_inner_dcache_client_out_e_bits_sink,
  input  [5:0] io_hartId,
  input  io_msiInfo_valid,
  input  [10:0] io_msiInfo_bits,
  input  io_clintTime_valid,
  input  [63:0] io_clintTime_bits,
  input  [47:0] io_reset_vector,
  output  io_cpu_halt,
  input  io_l2_flush_done,
  output  io_l2_flush_en,
  output  io_power_down_en,
  output  io_cpu_critical_error,
  output  io_resetInFrontend,
  input  io_traceCoreInterface_fromEncoder_enable,
  input  io_traceCoreInterface_fromEncoder_stall,
  output  [2:0] io_traceCoreInterface_toEncoder_priv,
  output  [63:0] io_traceCoreInterface_toEncoder_trap_cause,
  output  [49:0] io_traceCoreInterface_toEncoder_trap_tval,
  output  io_traceCoreInterface_toEncoder_groups_0_valid,
  output  [49:0] io_traceCoreInterface_toEncoder_groups_0_bits_iaddr,
  output  [3:0] io_traceCoreInterface_toEncoder_groups_0_bits_itype,
  output  [6:0] io_traceCoreInterface_toEncoder_groups_0_bits_iretire,
  output  io_traceCoreInterface_toEncoder_groups_0_bits_ilastsize,
  output  io_traceCoreInterface_toEncoder_groups_1_valid,
  output  [49:0] io_traceCoreInterface_toEncoder_groups_1_bits_iaddr,
  output  [3:0] io_traceCoreInterface_toEncoder_groups_1_bits_itype,
  output  [6:0] io_traceCoreInterface_toEncoder_groups_1_bits_iretire,
  output  io_traceCoreInterface_toEncoder_groups_1_bits_ilastsize,
  output  io_traceCoreInterface_toEncoder_groups_2_valid,
  output  [49:0] io_traceCoreInterface_toEncoder_groups_2_bits_iaddr,
  output  [3:0] io_traceCoreInterface_toEncoder_groups_2_bits_itype,
  output  [6:0] io_traceCoreInterface_toEncoder_groups_2_bits_iretire,
  output  io_traceCoreInterface_toEncoder_groups_2_bits_ilastsize,
  output  io_l2PfCtrl_l2_pf_master_en,
  output  io_l2PfCtrl_l2_pf_recv_en,
  output  io_l2PfCtrl_l2_pbop_en,
  output  io_l2PfCtrl_l2_vbop_en,
  input  [5:0] io_perfEvents_1_value,
  input  [5:0] io_perfEvents_2_value,
  input  [5:0] io_perfEvents_3_value,
  input  [5:0] io_perfEvents_4_value,
  input  [5:0] io_perfEvents_5_value,
  input  [5:0] io_perfEvents_6_value,
  input  [5:0] io_perfEvents_7_value,
  input  [5:0] io_perfEvents_8_value,
  input  [5:0] io_perfEvents_9_value,
  input  [5:0] io_perfEvents_10_value,
  input  [5:0] io_perfEvents_11_value,
  input  [5:0] io_perfEvents_12_value,
  input  [5:0] io_perfEvents_13_value,
  input  [5:0] io_perfEvents_14_value,
  input  [5:0] io_perfEvents_15_value,
  input  [5:0] io_perfEvents_16_value,
  input  [5:0] io_perfEvents_17_value,
  input  [5:0] io_perfEvents_18_value,
  input  [5:0] io_perfEvents_19_value,
  input  [5:0] io_perfEvents_20_value,
  input  [5:0] io_perfEvents_21_value,
  input  [5:0] io_perfEvents_22_value,
  input  [5:0] io_perfEvents_23_value,
  input  [5:0] io_perfEvents_24_value,
  input  [5:0] io_perfEvents_25_value,
  input  [5:0] io_perfEvents_26_value,
  input  [5:0] io_perfEvents_27_value,
  input  [5:0] io_perfEvents_28_value,
  input  [5:0] io_perfEvents_29_value,
  input  [5:0] io_perfEvents_30_value,
  input  [5:0] io_perfEvents_31_value,
  input  [5:0] io_perfEvents_32_value,
  input  [5:0] io_perfEvents_33_value,
  input  [5:0] io_perfEvents_34_value,
  input  [5:0] io_perfEvents_35_value,
  input  [5:0] io_perfEvents_36_value,
  input  [5:0] io_perfEvents_37_value,
  input  [5:0] io_perfEvents_38_value,
  input  [5:0] io_perfEvents_39_value,
  input  [5:0] io_perfEvents_40_value,
  input  [5:0] io_perfEvents_41_value,
  input  [5:0] io_perfEvents_42_value,
  input  [5:0] io_perfEvents_43_value,
  input  [5:0] io_perfEvents_44_value,
  input  [5:0] io_perfEvents_45_value,
  input  [5:0] io_perfEvents_46_value,
  input  [5:0] io_perfEvents_47_value,
  input  [5:0] io_perfEvents_48_value,
  output  io_beu_errors_icache_ecc_error_valid,
  output  [47:0] io_beu_errors_icache_ecc_error_bits,
  output  io_beu_errors_dcache_ecc_error_valid,
  output  [47:0] io_beu_errors_dcache_ecc_error_bits,
  output  io_beu_errors_uncache_ecc_error_valid,
  output  [47:0] io_beu_errors_uncache_ecc_error_bits,
  input  io_l2_hint_valid,
  input  [3:0] io_l2_hint_bits_sourceId,
  input  io_l2_hint_bits_isKeyword,
  input  io_l2_tlb_req_req_valid,
  input  [49:0] io_l2_tlb_req_req_bits_vaddr,
  input  [2:0] io_l2_tlb_req_req_bits_cmd,
  input  io_l2_tlb_req_req_bits_kill,
  input  io_l2_tlb_req_req_bits_no_translate,
  output  io_l2_tlb_req_resp_valid,
  output  [47:0] io_l2_tlb_req_resp_bits_paddr_0,
  output  [1:0] io_l2_tlb_req_resp_bits_pbmt_0,
  output  io_l2_tlb_req_resp_bits_miss,
  output  io_l2_tlb_req_resp_bits_excp_0_gpf_ld,
  output  io_l2_tlb_req_resp_bits_excp_0_pf_ld,
  output  io_l2_tlb_req_resp_bits_excp_0_af_ld,
  output  io_l2_pmp_resp_ld,
  output  io_l2_pmp_resp_mmio,
  output  io_debugTopDown_robHeadPaddr_valid,
  output  [47:0] io_debugTopDown_robHeadPaddr_bits,
  input  io_debugTopDown_l2MissMatch,
  input  io_debugTopDown_l3MissMatch,
  input  io_topDownInfo_l2Miss,
  input  io_topDownInfo_l3Miss,
  input  io_dft_ram_hold,
  input  io_dft_ram_bypass,
  input  io_dft_ram_bp_clken,
  input  io_dft_ram_aux_clk,
  input  io_dft_ram_aux_ckbp,
  input  io_dft_ram_mcp_hold,
  input  io_dft_cgen
);
  assign auto_memBlock_inner_buffers_out_a_valid = '0;
  assign auto_memBlock_inner_buffers_out_a_bits_opcode = '0;
  assign auto_memBlock_inner_buffers_out_a_bits_param = '0;
  assign auto_memBlock_inner_buffers_out_a_bits_size = '0;
  assign auto_memBlock_inner_buffers_out_a_bits_source = '0;
  assign auto_memBlock_inner_buffers_out_a_bits_address = '0;
  assign auto_memBlock_inner_buffers_out_a_bits_user_memBackType_MM = '0;
  assign auto_memBlock_inner_buffers_out_a_bits_user_memPageType_NC = '0;
  assign auto_memBlock_inner_buffers_out_a_bits_mask = '0;
  assign auto_memBlock_inner_buffers_out_a_bits_data = '0;
  assign auto_memBlock_inner_buffers_out_a_bits_corrupt = '0;
  assign auto_memBlock_inner_buffers_out_d_ready = '0;
  assign auto_memBlock_inner_frontendBridge_instr_uncache_out_a_valid = '0;
  assign auto_memBlock_inner_frontendBridge_instr_uncache_out_a_bits_param = '0;
  assign auto_memBlock_inner_frontendBridge_instr_uncache_out_a_bits_address = '0;
  assign auto_memBlock_inner_frontendBridge_instr_uncache_out_a_bits_corrupt = '0;
  assign auto_memBlock_inner_frontendBridge_instr_uncache_out_d_ready = '0;
  assign auto_memBlock_inner_frontendBridge_icachectrl_in_a_ready = '0;
  assign auto_memBlock_inner_frontendBridge_icachectrl_in_d_valid = '0;
  assign auto_memBlock_inner_frontendBridge_icachectrl_in_d_bits_opcode = '0;
  assign auto_memBlock_inner_frontendBridge_icachectrl_in_d_bits_param = '0;
  assign auto_memBlock_inner_frontendBridge_icachectrl_in_d_bits_size = '0;
  assign auto_memBlock_inner_frontendBridge_icachectrl_in_d_bits_source = '0;
  assign auto_memBlock_inner_frontendBridge_icachectrl_in_d_bits_sink = '0;
  assign auto_memBlock_inner_frontendBridge_icachectrl_in_d_bits_denied = '0;
  assign auto_memBlock_inner_frontendBridge_icachectrl_in_d_bits_data = '0;
  assign auto_memBlock_inner_frontendBridge_icachectrl_in_d_bits_corrupt = '0;
  assign auto_memBlock_inner_frontendBridge_icache_out_a_valid = '0;
  assign auto_memBlock_inner_frontendBridge_icache_out_a_bits_opcode = '0;
  assign auto_memBlock_inner_frontendBridge_icache_out_a_bits_param = '0;
  assign auto_memBlock_inner_frontendBridge_icache_out_a_bits_size = '0;
  assign auto_memBlock_inner_frontendBridge_icache_out_a_bits_source = '0;
  assign auto_memBlock_inner_frontendBridge_icache_out_a_bits_address = '0;
  assign auto_memBlock_inner_frontendBridge_icache_out_a_bits_user_alias = '0;
  assign auto_memBlock_inner_frontendBridge_icache_out_a_bits_user_reqSource = '0;
  assign auto_memBlock_inner_frontendBridge_icache_out_a_bits_user_needHint = '0;
  assign auto_memBlock_inner_frontendBridge_icache_out_a_bits_mask = '0;
  assign auto_memBlock_inner_frontendBridge_icache_out_a_bits_data = '0;
  assign auto_memBlock_inner_frontendBridge_icache_out_a_bits_corrupt = '0;
  assign auto_memBlock_inner_frontendBridge_icache_out_d_ready = '0;
  assign auto_memBlock_inner_ptw_to_l2_buffer_out_a_valid = '0;
  assign auto_memBlock_inner_ptw_to_l2_buffer_out_a_bits_opcode = '0;
  assign auto_memBlock_inner_ptw_to_l2_buffer_out_a_bits_param = '0;
  assign auto_memBlock_inner_ptw_to_l2_buffer_out_a_bits_size = '0;
  assign auto_memBlock_inner_ptw_to_l2_buffer_out_a_bits_source = '0;
  assign auto_memBlock_inner_ptw_to_l2_buffer_out_a_bits_address = '0;
  assign auto_memBlock_inner_ptw_to_l2_buffer_out_a_bits_user_reqSource = '0;
  assign auto_memBlock_inner_ptw_to_l2_buffer_out_a_bits_mask = '0;
  assign auto_memBlock_inner_ptw_to_l2_buffer_out_a_bits_data = '0;
  assign auto_memBlock_inner_ptw_to_l2_buffer_out_a_bits_corrupt = '0;
  assign auto_memBlock_inner_ptw_to_l2_buffer_out_d_ready = '0;
  assign auto_memBlock_inner_l2_pf_sender_out_addr = '0;
  assign auto_memBlock_inner_l2_pf_sender_out_pf_source = '0;
  assign auto_memBlock_inner_l2_pf_sender_out_addr_valid = '0;
  assign auto_memBlock_inner_dcache_client_out_a_valid = '0;
  assign auto_memBlock_inner_dcache_client_out_a_bits_opcode = '0;
  assign auto_memBlock_inner_dcache_client_out_a_bits_param = '0;
  assign auto_memBlock_inner_dcache_client_out_a_bits_size = '0;
  assign auto_memBlock_inner_dcache_client_out_a_bits_source = '0;
  assign auto_memBlock_inner_dcache_client_out_a_bits_address = '0;
  assign auto_memBlock_inner_dcache_client_out_a_bits_user_alias = '0;
  assign auto_memBlock_inner_dcache_client_out_a_bits_user_vaddr = '0;
  assign auto_memBlock_inner_dcache_client_out_a_bits_user_reqSource = '0;
  assign auto_memBlock_inner_dcache_client_out_a_bits_user_needHint = '0;
  assign auto_memBlock_inner_dcache_client_out_a_bits_echo_isKeyword = '0;
  assign auto_memBlock_inner_dcache_client_out_a_bits_mask = '0;
  assign auto_memBlock_inner_dcache_client_out_a_bits_data = '0;
  assign auto_memBlock_inner_dcache_client_out_a_bits_corrupt = '0;
  assign auto_memBlock_inner_dcache_client_out_b_ready = '0;
  assign auto_memBlock_inner_dcache_client_out_c_valid = '0;
  assign auto_memBlock_inner_dcache_client_out_c_bits_opcode = '0;
  assign auto_memBlock_inner_dcache_client_out_c_bits_param = '0;
  assign auto_memBlock_inner_dcache_client_out_c_bits_size = '0;
  assign auto_memBlock_inner_dcache_client_out_c_bits_source = '0;
  assign auto_memBlock_inner_dcache_client_out_c_bits_address = '0;
  assign auto_memBlock_inner_dcache_client_out_c_bits_user_alias = '0;
  assign auto_memBlock_inner_dcache_client_out_c_bits_user_vaddr = '0;
  assign auto_memBlock_inner_dcache_client_out_c_bits_user_reqSource = '0;
  assign auto_memBlock_inner_dcache_client_out_c_bits_user_needHint = '0;
  assign auto_memBlock_inner_dcache_client_out_c_bits_echo_isKeyword = '0;
  assign auto_memBlock_inner_dcache_client_out_c_bits_data = '0;
  assign auto_memBlock_inner_dcache_client_out_c_bits_corrupt = '0;
  assign auto_memBlock_inner_dcache_client_out_d_ready = '0;
  assign auto_memBlock_inner_dcache_client_out_e_valid = '0;
  assign auto_memBlock_inner_dcache_client_out_e_bits_sink = '0;
  assign io_cpu_halt = '0;
  assign io_l2_flush_en = '0;
  assign io_power_down_en = '0;
  assign io_cpu_critical_error = '0;
  assign io_resetInFrontend = '0;
  assign io_traceCoreInterface_toEncoder_priv = '0;
  assign io_traceCoreInterface_toEncoder_trap_cause = '0;
  assign io_traceCoreInterface_toEncoder_trap_tval = '0;
  assign io_traceCoreInterface_toEncoder_groups_0_valid = '0;
  assign io_traceCoreInterface_toEncoder_groups_0_bits_iaddr = '0;
  assign io_traceCoreInterface_toEncoder_groups_0_bits_itype = '0;
  assign io_traceCoreInterface_toEncoder_groups_0_bits_iretire = '0;
  assign io_traceCoreInterface_toEncoder_groups_0_bits_ilastsize = '0;
  assign io_traceCoreInterface_toEncoder_groups_1_valid = '0;
  assign io_traceCoreInterface_toEncoder_groups_1_bits_iaddr = '0;
  assign io_traceCoreInterface_toEncoder_groups_1_bits_itype = '0;
  assign io_traceCoreInterface_toEncoder_groups_1_bits_iretire = '0;
  assign io_traceCoreInterface_toEncoder_groups_1_bits_ilastsize = '0;
  assign io_traceCoreInterface_toEncoder_groups_2_valid = '0;
  assign io_traceCoreInterface_toEncoder_groups_2_bits_iaddr = '0;
  assign io_traceCoreInterface_toEncoder_groups_2_bits_itype = '0;
  assign io_traceCoreInterface_toEncoder_groups_2_bits_iretire = '0;
  assign io_traceCoreInterface_toEncoder_groups_2_bits_ilastsize = '0;
  assign io_l2PfCtrl_l2_pf_master_en = '0;
  assign io_l2PfCtrl_l2_pf_recv_en = '0;
  assign io_l2PfCtrl_l2_pbop_en = '0;
  assign io_l2PfCtrl_l2_vbop_en = '0;
  assign io_beu_errors_icache_ecc_error_valid = '0;
  assign io_beu_errors_icache_ecc_error_bits = '0;
  assign io_beu_errors_dcache_ecc_error_valid = '0;
  assign io_beu_errors_dcache_ecc_error_bits = '0;
  assign io_beu_errors_uncache_ecc_error_valid = '0;
  assign io_beu_errors_uncache_ecc_error_bits = '0;
  assign io_l2_tlb_req_resp_valid = '0;
  assign io_l2_tlb_req_resp_bits_paddr_0 = '0;
  assign io_l2_tlb_req_resp_bits_pbmt_0 = '0;
  assign io_l2_tlb_req_resp_bits_miss = '0;
  assign io_l2_tlb_req_resp_bits_excp_0_gpf_ld = '0;
  assign io_l2_tlb_req_resp_bits_excp_0_pf_ld = '0;
  assign io_l2_tlb_req_resp_bits_excp_0_af_ld = '0;
  assign io_l2_pmp_resp_ld = '0;
  assign io_l2_pmp_resp_mmio = '0;
  assign io_debugTopDown_robHeadPaddr_valid = '0;
  assign io_debugTopDown_robHeadPaddr_bits = '0;
endmodule

