// =============================================================================
// tb —— L2Top UT：golden L2Top 与重写 L2Top_xs 双例化，同激励逐拍比对
//       全部 208 个输出（4 态 !==）；激励 / 同步 / arm 规则见 gen_tb.py 文件头。
// 本文件由 verif/ut/L2Top/gen_tb.py 生成，勿手改。
// =============================================================================
`timescale 1ns/1ps
module tb;
  int unsigned NCYCLES = 200000;
  bit clock = 0; always #5 clock = ~clock;
  logic reset;
  longint errors = 0, checks = 0;
  longint cyc = 0;
  // 阶段（同 Slice tb）：每 4000 拍 [0,2000) 常速；[2000,3000) 下游慢；[3000,4000) MBIST 窗口。
  // 另每 50000 拍里有 600 拍 RX 链路去激活（rx_linkactivereq=0），走 LinkMonitor 的信用回收。
  function automatic bit slow_phase();  return (cyc % 4000) >= 2000 && (cyc % 4000) < 3000; endfunction
  function automatic bit mbist_phase(); return (cyc % 4000) >= 3000; endfunction
  function automatic bit link_down_phase(); return (cyc % 50000) >= 30000 && (cyc % 50000) < 30600; endfunction

  logic auto_inner_buffers_out_a_ready;
  logic auto_inner_buffers_out_d_valid;
  logic [3:0] auto_inner_buffers_out_d_bits_opcode;
  logic [1:0] auto_inner_buffers_out_d_bits_param;
  logic [1:0] auto_inner_buffers_out_d_bits_size;
  logic [4:0] auto_inner_buffers_out_d_bits_source;
  logic auto_inner_buffers_out_d_bits_sink;
  logic auto_inner_buffers_out_d_bits_denied;
  logic [63:0] auto_inner_buffers_out_d_bits_data;
  logic auto_inner_buffers_out_d_bits_corrupt;
  logic auto_inner_buffers_in_a_valid;
  logic [3:0] auto_inner_buffers_in_a_bits_opcode;
  logic [2:0] auto_inner_buffers_in_a_bits_param;
  logic [1:0] auto_inner_buffers_in_a_bits_size;
  logic [3:0] auto_inner_buffers_in_a_bits_source;
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
  logic auto_inner_i_mmio_buffer_in_a_bits_user_memPageType_NC;
  logic auto_inner_i_mmio_buffer_in_a_bits_user_memBackType_MM;
  logic auto_inner_i_mmio_buffer_in_a_bits_corrupt;
  logic auto_inner_i_mmio_buffer_in_d_ready;
  logic auto_inner_ptw_to_l2_buffer_in_a_valid;
  logic [3:0] auto_inner_ptw_to_l2_buffer_in_a_bits_opcode;
  logic [2:0] auto_inner_ptw_to_l2_buffer_in_a_bits_param;
  logic [2:0] auto_inner_ptw_to_l2_buffer_in_a_bits_size;
  logic [3:0] auto_inner_ptw_to_l2_buffer_in_a_bits_source;
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
  logic [11:0] io_msiInfo_fromTile_bits;
  logic io_msiAck_fromCore;
  logic io_cpu_halt_fromCore;
  logic io_cpu_critical_error_fromCore;
  logic io_hartIsInReset_resetInFrontend;
  logic [2:0] io_traceCoreInterface_fromCore_toEncoder_priv;
  logic [63:0] io_traceCoreInterface_fromCore_toEncoder_mstatus;
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
  logic [9:0] io_pfCtrlFromCore_l2_pf_delay_latency;
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
  logic g_auto_inner_buffers_out_a_valid, i_auto_inner_buffers_out_a_valid;
  logic [3:0] g_auto_inner_buffers_out_a_bits_opcode, i_auto_inner_buffers_out_a_bits_opcode;
  logic [2:0] g_auto_inner_buffers_out_a_bits_param, i_auto_inner_buffers_out_a_bits_param;
  logic [1:0] g_auto_inner_buffers_out_a_bits_size, i_auto_inner_buffers_out_a_bits_size;
  logic [4:0] g_auto_inner_buffers_out_a_bits_source, i_auto_inner_buffers_out_a_bits_source;
  logic [29:0] g_auto_inner_buffers_out_a_bits_address, i_auto_inner_buffers_out_a_bits_address;
  logic [7:0] g_auto_inner_buffers_out_a_bits_mask, i_auto_inner_buffers_out_a_bits_mask;
  logic [63:0] g_auto_inner_buffers_out_a_bits_data, i_auto_inner_buffers_out_a_bits_data;
  logic g_auto_inner_buffers_out_a_bits_corrupt, i_auto_inner_buffers_out_a_bits_corrupt;
  logic g_auto_inner_buffers_out_d_ready, i_auto_inner_buffers_out_d_ready;
  logic g_auto_inner_buffers_in_a_ready, i_auto_inner_buffers_in_a_ready;
  logic g_auto_inner_buffers_in_d_valid, i_auto_inner_buffers_in_d_valid;
  logic [3:0] g_auto_inner_buffers_in_d_bits_opcode, i_auto_inner_buffers_in_d_bits_opcode;
  logic [1:0] g_auto_inner_buffers_in_d_bits_param, i_auto_inner_buffers_in_d_bits_param;
  logic [1:0] g_auto_inner_buffers_in_d_bits_size, i_auto_inner_buffers_in_d_bits_size;
  logic [3:0] g_auto_inner_buffers_in_d_bits_source, i_auto_inner_buffers_in_d_bits_source;
  logic g_auto_inner_buffers_in_d_bits_sink, i_auto_inner_buffers_in_d_bits_sink;
  logic g_auto_inner_buffers_in_d_bits_denied, i_auto_inner_buffers_in_d_bits_denied;
  logic [63:0] g_auto_inner_buffers_in_d_bits_data, i_auto_inner_buffers_in_d_bits_data;
  logic g_auto_inner_buffers_in_d_bits_corrupt, i_auto_inner_buffers_in_d_bits_corrupt;
  logic g_auto_inner_intBuffer_out_0, i_auto_inner_intBuffer_out_0;
  logic g_auto_inner_i_mmio_buffer_in_a_ready, i_auto_inner_i_mmio_buffer_in_a_ready;
  logic g_auto_inner_i_mmio_buffer_in_d_valid, i_auto_inner_i_mmio_buffer_in_d_valid;
  logic [3:0] g_auto_inner_i_mmio_buffer_in_d_bits_opcode, i_auto_inner_i_mmio_buffer_in_d_bits_opcode;
  logic [1:0] g_auto_inner_i_mmio_buffer_in_d_bits_param, i_auto_inner_i_mmio_buffer_in_d_bits_param;
  logic [1:0] g_auto_inner_i_mmio_buffer_in_d_bits_size, i_auto_inner_i_mmio_buffer_in_d_bits_size;
  logic g_auto_inner_i_mmio_buffer_in_d_bits_source, i_auto_inner_i_mmio_buffer_in_d_bits_source;
  logic g_auto_inner_i_mmio_buffer_in_d_bits_sink, i_auto_inner_i_mmio_buffer_in_d_bits_sink;
  logic g_auto_inner_i_mmio_buffer_in_d_bits_denied, i_auto_inner_i_mmio_buffer_in_d_bits_denied;
  logic [63:0] g_auto_inner_i_mmio_buffer_in_d_bits_data, i_auto_inner_i_mmio_buffer_in_d_bits_data;
  logic g_auto_inner_i_mmio_buffer_in_d_bits_corrupt, i_auto_inner_i_mmio_buffer_in_d_bits_corrupt;
  logic g_auto_inner_ptw_to_l2_buffer_in_a_ready, i_auto_inner_ptw_to_l2_buffer_in_a_ready;
  logic g_auto_inner_ptw_to_l2_buffer_in_d_valid, i_auto_inner_ptw_to_l2_buffer_in_d_valid;
  logic [3:0] g_auto_inner_ptw_to_l2_buffer_in_d_bits_opcode, i_auto_inner_ptw_to_l2_buffer_in_d_bits_opcode;
  logic [1:0] g_auto_inner_ptw_to_l2_buffer_in_d_bits_param, i_auto_inner_ptw_to_l2_buffer_in_d_bits_param;
  logic [2:0] g_auto_inner_ptw_to_l2_buffer_in_d_bits_size, i_auto_inner_ptw_to_l2_buffer_in_d_bits_size;
  logic [3:0] g_auto_inner_ptw_to_l2_buffer_in_d_bits_source, i_auto_inner_ptw_to_l2_buffer_in_d_bits_source;
  logic [9:0] g_auto_inner_ptw_to_l2_buffer_in_d_bits_sink, i_auto_inner_ptw_to_l2_buffer_in_d_bits_sink;
  logic g_auto_inner_ptw_to_l2_buffer_in_d_bits_denied, i_auto_inner_ptw_to_l2_buffer_in_d_bits_denied;
  logic [255:0] g_auto_inner_ptw_to_l2_buffer_in_d_bits_data, i_auto_inner_ptw_to_l2_buffer_in_d_bits_data;
  logic g_auto_inner_ptw_to_l2_buffer_in_d_bits_corrupt, i_auto_inner_ptw_to_l2_buffer_in_d_bits_corrupt;
  logic g_auto_inner_logger_in_1_a_ready, i_auto_inner_logger_in_1_a_ready;
  logic g_auto_inner_logger_in_1_d_valid, i_auto_inner_logger_in_1_d_valid;
  logic [3:0] g_auto_inner_logger_in_1_d_bits_opcode, i_auto_inner_logger_in_1_d_bits_opcode;
  logic [1:0] g_auto_inner_logger_in_1_d_bits_param, i_auto_inner_logger_in_1_d_bits_param;
  logic [2:0] g_auto_inner_logger_in_1_d_bits_size, i_auto_inner_logger_in_1_d_bits_size;
  logic [3:0] g_auto_inner_logger_in_1_d_bits_source, i_auto_inner_logger_in_1_d_bits_source;
  logic [9:0] g_auto_inner_logger_in_1_d_bits_sink, i_auto_inner_logger_in_1_d_bits_sink;
  logic g_auto_inner_logger_in_1_d_bits_denied, i_auto_inner_logger_in_1_d_bits_denied;
  logic [255:0] g_auto_inner_logger_in_1_d_bits_data, i_auto_inner_logger_in_1_d_bits_data;
  logic g_auto_inner_logger_in_1_d_bits_corrupt, i_auto_inner_logger_in_1_d_bits_corrupt;
  logic g_auto_inner_logger_in_0_a_ready, i_auto_inner_logger_in_0_a_ready;
  logic g_auto_inner_logger_in_0_b_valid, i_auto_inner_logger_in_0_b_valid;
  logic [2:0] g_auto_inner_logger_in_0_b_bits_opcode, i_auto_inner_logger_in_0_b_bits_opcode;
  logic [1:0] g_auto_inner_logger_in_0_b_bits_param, i_auto_inner_logger_in_0_b_bits_param;
  logic [2:0] g_auto_inner_logger_in_0_b_bits_size, i_auto_inner_logger_in_0_b_bits_size;
  logic [5:0] g_auto_inner_logger_in_0_b_bits_source, i_auto_inner_logger_in_0_b_bits_source;
  logic [47:0] g_auto_inner_logger_in_0_b_bits_address, i_auto_inner_logger_in_0_b_bits_address;
  logic [31:0] g_auto_inner_logger_in_0_b_bits_mask, i_auto_inner_logger_in_0_b_bits_mask;
  logic [255:0] g_auto_inner_logger_in_0_b_bits_data, i_auto_inner_logger_in_0_b_bits_data;
  logic g_auto_inner_logger_in_0_b_bits_corrupt, i_auto_inner_logger_in_0_b_bits_corrupt;
  logic g_auto_inner_logger_in_0_c_ready, i_auto_inner_logger_in_0_c_ready;
  logic g_auto_inner_logger_in_0_d_valid, i_auto_inner_logger_in_0_d_valid;
  logic [3:0] g_auto_inner_logger_in_0_d_bits_opcode, i_auto_inner_logger_in_0_d_bits_opcode;
  logic [1:0] g_auto_inner_logger_in_0_d_bits_param, i_auto_inner_logger_in_0_d_bits_param;
  logic [2:0] g_auto_inner_logger_in_0_d_bits_size, i_auto_inner_logger_in_0_d_bits_size;
  logic [5:0] g_auto_inner_logger_in_0_d_bits_source, i_auto_inner_logger_in_0_d_bits_source;
  logic [9:0] g_auto_inner_logger_in_0_d_bits_sink, i_auto_inner_logger_in_0_d_bits_sink;
  logic g_auto_inner_logger_in_0_d_bits_denied, i_auto_inner_logger_in_0_d_bits_denied;
  logic g_auto_inner_logger_in_0_d_bits_echo_isKeyword, i_auto_inner_logger_in_0_d_bits_echo_isKeyword;
  logic [255:0] g_auto_inner_logger_in_0_d_bits_data, i_auto_inner_logger_in_0_d_bits_data;
  logic g_auto_inner_logger_in_0_d_bits_corrupt, i_auto_inner_logger_in_0_d_bits_corrupt;
  logic g_auto_inner_logger_in_0_e_ready, i_auto_inner_logger_in_0_e_ready;
  logic g_auto_inner_beu_int_out_0, i_auto_inner_beu_int_out_0;
  logic g_auto_inner_nmi_int_out_0, i_auto_inner_nmi_int_out_0;
  logic g_auto_inner_nmi_int_out_1, i_auto_inner_nmi_int_out_1;
  logic g_auto_inner_plic_int_out_1_0, i_auto_inner_plic_int_out_1_0;
  logic g_auto_inner_plic_int_out_0_0, i_auto_inner_plic_int_out_0_0;
  logic g_auto_inner_debug_int_out_0, i_auto_inner_debug_int_out_0;
  logic g_auto_inner_clint_int_out_0, i_auto_inner_clint_int_out_0;
  logic g_auto_inner_clint_int_out_1, i_auto_inner_clint_int_out_1;
  logic [47:0] g_io_reset_vector_toCore, i_io_reset_vector_toCore;
  logic [63:0] g_io_hartId_toCore, i_io_hartId_toCore;
  logic g_io_msiInfo_toCore_valid, i_io_msiInfo_toCore_valid;
  logic [11:0] g_io_msiInfo_toCore_bits, i_io_msiInfo_toCore_bits;
  logic g_io_msiAck_toTile, i_io_msiAck_toTile;
  logic g_io_cpu_halt_toTile, i_io_cpu_halt_toTile;
  logic g_io_cpu_critical_error_toTile, i_io_cpu_critical_error_toTile;
  logic g_io_hartIsInReset_toTile, i_io_hartIsInReset_toTile;
  logic g_io_traceCoreInterface_fromCore_fromEncoder_enable, i_io_traceCoreInterface_fromCore_fromEncoder_enable;
  logic g_io_traceCoreInterface_fromCore_fromEncoder_stall, i_io_traceCoreInterface_fromCore_fromEncoder_stall;
  logic [2:0] g_io_traceCoreInterface_toTile_toEncoder_priv, i_io_traceCoreInterface_toTile_toEncoder_priv;
  logic [63:0] g_io_traceCoreInterface_toTile_toEncoder_mstatus, i_io_traceCoreInterface_toTile_toEncoder_mstatus;
  logic [63:0] g_io_traceCoreInterface_toTile_toEncoder_trap_cause, i_io_traceCoreInterface_toTile_toEncoder_trap_cause;
  logic [49:0] g_io_traceCoreInterface_toTile_toEncoder_trap_tval, i_io_traceCoreInterface_toTile_toEncoder_trap_tval;
  logic g_io_traceCoreInterface_toTile_toEncoder_groups_0_valid, i_io_traceCoreInterface_toTile_toEncoder_groups_0_valid;
  logic [49:0] g_io_traceCoreInterface_toTile_toEncoder_groups_0_bits_iaddr, i_io_traceCoreInterface_toTile_toEncoder_groups_0_bits_iaddr;
  logic [3:0] g_io_traceCoreInterface_toTile_toEncoder_groups_0_bits_itype, i_io_traceCoreInterface_toTile_toEncoder_groups_0_bits_itype;
  logic [6:0] g_io_traceCoreInterface_toTile_toEncoder_groups_0_bits_iretire, i_io_traceCoreInterface_toTile_toEncoder_groups_0_bits_iretire;
  logic g_io_traceCoreInterface_toTile_toEncoder_groups_0_bits_ilastsize, i_io_traceCoreInterface_toTile_toEncoder_groups_0_bits_ilastsize;
  logic g_io_traceCoreInterface_toTile_toEncoder_groups_1_valid, i_io_traceCoreInterface_toTile_toEncoder_groups_1_valid;
  logic [49:0] g_io_traceCoreInterface_toTile_toEncoder_groups_1_bits_iaddr, i_io_traceCoreInterface_toTile_toEncoder_groups_1_bits_iaddr;
  logic [3:0] g_io_traceCoreInterface_toTile_toEncoder_groups_1_bits_itype, i_io_traceCoreInterface_toTile_toEncoder_groups_1_bits_itype;
  logic [6:0] g_io_traceCoreInterface_toTile_toEncoder_groups_1_bits_iretire, i_io_traceCoreInterface_toTile_toEncoder_groups_1_bits_iretire;
  logic g_io_traceCoreInterface_toTile_toEncoder_groups_1_bits_ilastsize, i_io_traceCoreInterface_toTile_toEncoder_groups_1_bits_ilastsize;
  logic g_io_traceCoreInterface_toTile_toEncoder_groups_2_valid, i_io_traceCoreInterface_toTile_toEncoder_groups_2_valid;
  logic [49:0] g_io_traceCoreInterface_toTile_toEncoder_groups_2_bits_iaddr, i_io_traceCoreInterface_toTile_toEncoder_groups_2_bits_iaddr;
  logic [3:0] g_io_traceCoreInterface_toTile_toEncoder_groups_2_bits_itype, i_io_traceCoreInterface_toTile_toEncoder_groups_2_bits_itype;
  logic [6:0] g_io_traceCoreInterface_toTile_toEncoder_groups_2_bits_iretire, i_io_traceCoreInterface_toTile_toEncoder_groups_2_bits_iretire;
  logic g_io_traceCoreInterface_toTile_toEncoder_groups_2_bits_ilastsize, i_io_traceCoreInterface_toTile_toEncoder_groups_2_bits_ilastsize;
  logic g_io_debugTopDown_l2MissMatch, i_io_debugTopDown_l2MissMatch;
  logic g_io_l2Miss, i_io_l2Miss;
  logic g_io_l3Miss_toCore, i_io_l3Miss_toCore;
  logic g_io_clintTime_toCore_valid, i_io_clintTime_toCore_valid;
  logic [63:0] g_io_clintTime_toCore_bits, i_io_clintTime_toCore_bits;
  logic g_io_chi_txsactive, i_io_chi_txsactive;
  logic g_io_chi_syscoreq, i_io_chi_syscoreq;
  logic g_io_chi_tx_linkactivereq, i_io_chi_tx_linkactivereq;
  logic g_io_chi_tx_req_flitpend, i_io_chi_tx_req_flitpend;
  logic g_io_chi_tx_req_flitv, i_io_chi_tx_req_flitv;
  logic [161:0] g_io_chi_tx_req_flit, i_io_chi_tx_req_flit;
  logic g_io_chi_tx_rsp_flitpend, i_io_chi_tx_rsp_flitpend;
  logic g_io_chi_tx_rsp_flitv, i_io_chi_tx_rsp_flitv;
  logic [72:0] g_io_chi_tx_rsp_flit, i_io_chi_tx_rsp_flit;
  logic g_io_chi_tx_dat_flitpend, i_io_chi_tx_dat_flitpend;
  logic g_io_chi_tx_dat_flitv, i_io_chi_tx_dat_flitv;
  logic [421:0] g_io_chi_tx_dat_flit, i_io_chi_tx_dat_flit;
  logic g_io_chi_rx_linkactiveack, i_io_chi_rx_linkactiveack;
  logic g_io_chi_rx_rsp_lcrdv, i_io_chi_rx_rsp_lcrdv;
  logic g_io_chi_rx_dat_lcrdv, i_io_chi_rx_dat_lcrdv;
  logic g_io_chi_rx_snp_lcrdv, i_io_chi_rx_snp_lcrdv;
  logic g_io_l2_tlb_req_req_valid, i_io_l2_tlb_req_req_valid;
  logic [49:0] g_io_l2_tlb_req_req_bits_vaddr, i_io_l2_tlb_req_req_bits_vaddr;
  logic [2:0] g_io_l2_tlb_req_req_bits_cmd, i_io_l2_tlb_req_req_bits_cmd;
  logic g_io_l2_tlb_req_req_bits_kill, i_io_l2_tlb_req_req_bits_kill;
  logic g_io_l2_tlb_req_req_bits_isPrefetch, i_io_l2_tlb_req_req_bits_isPrefetch;
  logic g_io_l2_tlb_req_req_bits_no_translate, i_io_l2_tlb_req_req_bits_no_translate;
  logic g_io_l2_hint_valid, i_io_l2_hint_valid;
  logic [3:0] g_io_l2_hint_bits_sourceId, i_io_l2_hint_bits_sourceId;
  logic g_io_l2_hint_bits_isKeyword, i_io_l2_hint_bits_isKeyword;
  logic [5:0] g_io_perfEvents_1_value, i_io_perfEvents_1_value;
  logic [5:0] g_io_perfEvents_2_value, i_io_perfEvents_2_value;
  logic [5:0] g_io_perfEvents_3_value, i_io_perfEvents_3_value;
  logic [5:0] g_io_perfEvents_4_value, i_io_perfEvents_4_value;
  logic [5:0] g_io_perfEvents_5_value, i_io_perfEvents_5_value;
  logic [5:0] g_io_perfEvents_6_value, i_io_perfEvents_6_value;
  logic [5:0] g_io_perfEvents_7_value, i_io_perfEvents_7_value;
  logic [5:0] g_io_perfEvents_8_value, i_io_perfEvents_8_value;
  logic [5:0] g_io_perfEvents_9_value, i_io_perfEvents_9_value;
  logic [5:0] g_io_perfEvents_10_value, i_io_perfEvents_10_value;
  logic [5:0] g_io_perfEvents_11_value, i_io_perfEvents_11_value;
  logic [5:0] g_io_perfEvents_12_value, i_io_perfEvents_12_value;
  logic [5:0] g_io_perfEvents_13_value, i_io_perfEvents_13_value;
  logic [5:0] g_io_perfEvents_14_value, i_io_perfEvents_14_value;
  logic [5:0] g_io_perfEvents_15_value, i_io_perfEvents_15_value;
  logic [5:0] g_io_perfEvents_16_value, i_io_perfEvents_16_value;
  logic [5:0] g_io_perfEvents_17_value, i_io_perfEvents_17_value;
  logic [5:0] g_io_perfEvents_18_value, i_io_perfEvents_18_value;
  logic [5:0] g_io_perfEvents_19_value, i_io_perfEvents_19_value;
  logic [5:0] g_io_perfEvents_20_value, i_io_perfEvents_20_value;
  logic [5:0] g_io_perfEvents_21_value, i_io_perfEvents_21_value;
  logic [5:0] g_io_perfEvents_22_value, i_io_perfEvents_22_value;
  logic [5:0] g_io_perfEvents_23_value, i_io_perfEvents_23_value;
  logic [5:0] g_io_perfEvents_24_value, i_io_perfEvents_24_value;
  logic [5:0] g_io_perfEvents_25_value, i_io_perfEvents_25_value;
  logic [5:0] g_io_perfEvents_26_value, i_io_perfEvents_26_value;
  logic [5:0] g_io_perfEvents_27_value, i_io_perfEvents_27_value;
  logic [5:0] g_io_perfEvents_28_value, i_io_perfEvents_28_value;
  logic [5:0] g_io_perfEvents_29_value, i_io_perfEvents_29_value;
  logic [5:0] g_io_perfEvents_30_value, i_io_perfEvents_30_value;
  logic [5:0] g_io_perfEvents_31_value, i_io_perfEvents_31_value;
  logic [5:0] g_io_perfEvents_32_value, i_io_perfEvents_32_value;
  logic [5:0] g_io_perfEvents_33_value, i_io_perfEvents_33_value;
  logic [5:0] g_io_perfEvents_34_value, i_io_perfEvents_34_value;
  logic [5:0] g_io_perfEvents_35_value, i_io_perfEvents_35_value;
  logic [5:0] g_io_perfEvents_36_value, i_io_perfEvents_36_value;
  logic [5:0] g_io_perfEvents_37_value, i_io_perfEvents_37_value;
  logic [5:0] g_io_perfEvents_38_value, i_io_perfEvents_38_value;
  logic [5:0] g_io_perfEvents_39_value, i_io_perfEvents_39_value;
  logic [5:0] g_io_perfEvents_40_value, i_io_perfEvents_40_value;
  logic [5:0] g_io_perfEvents_41_value, i_io_perfEvents_41_value;
  logic [5:0] g_io_perfEvents_42_value, i_io_perfEvents_42_value;
  logic [5:0] g_io_perfEvents_43_value, i_io_perfEvents_43_value;
  logic [5:0] g_io_perfEvents_44_value, i_io_perfEvents_44_value;
  logic [5:0] g_io_perfEvents_45_value, i_io_perfEvents_45_value;
  logic [5:0] g_io_perfEvents_46_value, i_io_perfEvents_46_value;
  logic [5:0] g_io_perfEvents_47_value, i_io_perfEvents_47_value;
  logic [5:0] g_io_perfEvents_48_value, i_io_perfEvents_48_value;
  logic [5:0] g_io_perfEvents_49_value, i_io_perfEvents_49_value;
  logic [5:0] g_io_perfEvents_50_value, i_io_perfEvents_50_value;
  logic [5:0] g_io_perfEvents_51_value, i_io_perfEvents_51_value;
  logic [5:0] g_io_perfEvents_52_value, i_io_perfEvents_52_value;
  logic [5:0] g_io_perfEvents_53_value, i_io_perfEvents_53_value;
  logic [5:0] g_io_perfEvents_54_value, i_io_perfEvents_54_value;
  logic [5:0] g_io_perfEvents_55_value, i_io_perfEvents_55_value;
  logic [5:0] g_io_perfEvents_56_value, i_io_perfEvents_56_value;
  logic [5:0] g_io_perfEvents_57_value, i_io_perfEvents_57_value;
  logic [5:0] g_io_perfEvents_58_value, i_io_perfEvents_58_value;
  logic [5:0] g_io_perfEvents_59_value, i_io_perfEvents_59_value;
  logic [5:0] g_io_perfEvents_60_value, i_io_perfEvents_60_value;
  logic [5:0] g_io_perfEvents_61_value, i_io_perfEvents_61_value;
  logic [5:0] g_io_perfEvents_62_value, i_io_perfEvents_62_value;
  logic [5:0] g_io_perfEvents_63_value, i_io_perfEvents_63_value;
  logic [5:0] g_io_perfEvents_64_value, i_io_perfEvents_64_value;
  logic [5:0] g_io_perfEvents_65_value, i_io_perfEvents_65_value;
  logic [5:0] g_io_perfEvents_66_value, i_io_perfEvents_66_value;
  logic [5:0] g_io_perfEvents_67_value, i_io_perfEvents_67_value;
  logic [5:0] g_io_perfEvents_68_value, i_io_perfEvents_68_value;

  L2Top u_g (
    .clock(clock),
    .reset(reset),
    .auto_inner_buffers_out_a_ready(auto_inner_buffers_out_a_ready),
    .auto_inner_buffers_out_a_valid(g_auto_inner_buffers_out_a_valid),
    .auto_inner_buffers_out_a_bits_opcode(g_auto_inner_buffers_out_a_bits_opcode),
    .auto_inner_buffers_out_a_bits_param(g_auto_inner_buffers_out_a_bits_param),
    .auto_inner_buffers_out_a_bits_size(g_auto_inner_buffers_out_a_bits_size),
    .auto_inner_buffers_out_a_bits_source(g_auto_inner_buffers_out_a_bits_source),
    .auto_inner_buffers_out_a_bits_address(g_auto_inner_buffers_out_a_bits_address),
    .auto_inner_buffers_out_a_bits_mask(g_auto_inner_buffers_out_a_bits_mask),
    .auto_inner_buffers_out_a_bits_data(g_auto_inner_buffers_out_a_bits_data),
    .auto_inner_buffers_out_a_bits_corrupt(g_auto_inner_buffers_out_a_bits_corrupt),
    .auto_inner_buffers_out_d_ready(g_auto_inner_buffers_out_d_ready),
    .auto_inner_buffers_out_d_valid(auto_inner_buffers_out_d_valid),
    .auto_inner_buffers_out_d_bits_opcode(auto_inner_buffers_out_d_bits_opcode),
    .auto_inner_buffers_out_d_bits_param(auto_inner_buffers_out_d_bits_param),
    .auto_inner_buffers_out_d_bits_size(auto_inner_buffers_out_d_bits_size),
    .auto_inner_buffers_out_d_bits_source(auto_inner_buffers_out_d_bits_source),
    .auto_inner_buffers_out_d_bits_sink(auto_inner_buffers_out_d_bits_sink),
    .auto_inner_buffers_out_d_bits_denied(auto_inner_buffers_out_d_bits_denied),
    .auto_inner_buffers_out_d_bits_data(auto_inner_buffers_out_d_bits_data),
    .auto_inner_buffers_out_d_bits_corrupt(auto_inner_buffers_out_d_bits_corrupt),
    .auto_inner_buffers_in_a_ready(g_auto_inner_buffers_in_a_ready),
    .auto_inner_buffers_in_a_valid(auto_inner_buffers_in_a_valid),
    .auto_inner_buffers_in_a_bits_opcode(auto_inner_buffers_in_a_bits_opcode),
    .auto_inner_buffers_in_a_bits_param(auto_inner_buffers_in_a_bits_param),
    .auto_inner_buffers_in_a_bits_size(auto_inner_buffers_in_a_bits_size),
    .auto_inner_buffers_in_a_bits_source(auto_inner_buffers_in_a_bits_source),
    .auto_inner_buffers_in_a_bits_address(auto_inner_buffers_in_a_bits_address),
    .auto_inner_buffers_in_a_bits_user_memBackType_MM(auto_inner_buffers_in_a_bits_user_memBackType_MM),
    .auto_inner_buffers_in_a_bits_user_memPageType_NC(auto_inner_buffers_in_a_bits_user_memPageType_NC),
    .auto_inner_buffers_in_a_bits_mask(auto_inner_buffers_in_a_bits_mask),
    .auto_inner_buffers_in_a_bits_data(auto_inner_buffers_in_a_bits_data),
    .auto_inner_buffers_in_a_bits_corrupt(auto_inner_buffers_in_a_bits_corrupt),
    .auto_inner_buffers_in_d_ready(auto_inner_buffers_in_d_ready),
    .auto_inner_buffers_in_d_valid(g_auto_inner_buffers_in_d_valid),
    .auto_inner_buffers_in_d_bits_opcode(g_auto_inner_buffers_in_d_bits_opcode),
    .auto_inner_buffers_in_d_bits_param(g_auto_inner_buffers_in_d_bits_param),
    .auto_inner_buffers_in_d_bits_size(g_auto_inner_buffers_in_d_bits_size),
    .auto_inner_buffers_in_d_bits_source(g_auto_inner_buffers_in_d_bits_source),
    .auto_inner_buffers_in_d_bits_sink(g_auto_inner_buffers_in_d_bits_sink),
    .auto_inner_buffers_in_d_bits_denied(g_auto_inner_buffers_in_d_bits_denied),
    .auto_inner_buffers_in_d_bits_data(g_auto_inner_buffers_in_d_bits_data),
    .auto_inner_buffers_in_d_bits_corrupt(g_auto_inner_buffers_in_d_bits_corrupt),
    .auto_inner_l2cache_pf_recv_in_addr(auto_inner_l2cache_pf_recv_in_addr),
    .auto_inner_l2cache_pf_recv_in_pf_source(auto_inner_l2cache_pf_recv_in_pf_source),
    .auto_inner_l2cache_pf_recv_in_addr_valid(auto_inner_l2cache_pf_recv_in_addr_valid),
    .auto_inner_intBuffer_out_0(g_auto_inner_intBuffer_out_0),
    .auto_inner_i_mmio_buffer_in_a_ready(g_auto_inner_i_mmio_buffer_in_a_ready),
    .auto_inner_i_mmio_buffer_in_a_valid(auto_inner_i_mmio_buffer_in_a_valid),
    .auto_inner_i_mmio_buffer_in_a_bits_param(auto_inner_i_mmio_buffer_in_a_bits_param),
    .auto_inner_i_mmio_buffer_in_a_bits_address(auto_inner_i_mmio_buffer_in_a_bits_address),
    .auto_inner_i_mmio_buffer_in_a_bits_user_memPageType_NC(auto_inner_i_mmio_buffer_in_a_bits_user_memPageType_NC),
    .auto_inner_i_mmio_buffer_in_a_bits_user_memBackType_MM(auto_inner_i_mmio_buffer_in_a_bits_user_memBackType_MM),
    .auto_inner_i_mmio_buffer_in_a_bits_corrupt(auto_inner_i_mmio_buffer_in_a_bits_corrupt),
    .auto_inner_i_mmio_buffer_in_d_ready(auto_inner_i_mmio_buffer_in_d_ready),
    .auto_inner_i_mmio_buffer_in_d_valid(g_auto_inner_i_mmio_buffer_in_d_valid),
    .auto_inner_i_mmio_buffer_in_d_bits_opcode(g_auto_inner_i_mmio_buffer_in_d_bits_opcode),
    .auto_inner_i_mmio_buffer_in_d_bits_param(g_auto_inner_i_mmio_buffer_in_d_bits_param),
    .auto_inner_i_mmio_buffer_in_d_bits_size(g_auto_inner_i_mmio_buffer_in_d_bits_size),
    .auto_inner_i_mmio_buffer_in_d_bits_source(g_auto_inner_i_mmio_buffer_in_d_bits_source),
    .auto_inner_i_mmio_buffer_in_d_bits_sink(g_auto_inner_i_mmio_buffer_in_d_bits_sink),
    .auto_inner_i_mmio_buffer_in_d_bits_denied(g_auto_inner_i_mmio_buffer_in_d_bits_denied),
    .auto_inner_i_mmio_buffer_in_d_bits_data(g_auto_inner_i_mmio_buffer_in_d_bits_data),
    .auto_inner_i_mmio_buffer_in_d_bits_corrupt(g_auto_inner_i_mmio_buffer_in_d_bits_corrupt),
    .auto_inner_ptw_to_l2_buffer_in_a_ready(g_auto_inner_ptw_to_l2_buffer_in_a_ready),
    .auto_inner_ptw_to_l2_buffer_in_a_valid(auto_inner_ptw_to_l2_buffer_in_a_valid),
    .auto_inner_ptw_to_l2_buffer_in_a_bits_opcode(auto_inner_ptw_to_l2_buffer_in_a_bits_opcode),
    .auto_inner_ptw_to_l2_buffer_in_a_bits_param(auto_inner_ptw_to_l2_buffer_in_a_bits_param),
    .auto_inner_ptw_to_l2_buffer_in_a_bits_size(auto_inner_ptw_to_l2_buffer_in_a_bits_size),
    .auto_inner_ptw_to_l2_buffer_in_a_bits_source(auto_inner_ptw_to_l2_buffer_in_a_bits_source),
    .auto_inner_ptw_to_l2_buffer_in_a_bits_address(auto_inner_ptw_to_l2_buffer_in_a_bits_address),
    .auto_inner_ptw_to_l2_buffer_in_a_bits_user_reqSource(auto_inner_ptw_to_l2_buffer_in_a_bits_user_reqSource),
    .auto_inner_ptw_to_l2_buffer_in_a_bits_mask(auto_inner_ptw_to_l2_buffer_in_a_bits_mask),
    .auto_inner_ptw_to_l2_buffer_in_a_bits_data(auto_inner_ptw_to_l2_buffer_in_a_bits_data),
    .auto_inner_ptw_to_l2_buffer_in_a_bits_corrupt(auto_inner_ptw_to_l2_buffer_in_a_bits_corrupt),
    .auto_inner_ptw_to_l2_buffer_in_d_ready(auto_inner_ptw_to_l2_buffer_in_d_ready),
    .auto_inner_ptw_to_l2_buffer_in_d_valid(g_auto_inner_ptw_to_l2_buffer_in_d_valid),
    .auto_inner_ptw_to_l2_buffer_in_d_bits_opcode(g_auto_inner_ptw_to_l2_buffer_in_d_bits_opcode),
    .auto_inner_ptw_to_l2_buffer_in_d_bits_param(g_auto_inner_ptw_to_l2_buffer_in_d_bits_param),
    .auto_inner_ptw_to_l2_buffer_in_d_bits_size(g_auto_inner_ptw_to_l2_buffer_in_d_bits_size),
    .auto_inner_ptw_to_l2_buffer_in_d_bits_source(g_auto_inner_ptw_to_l2_buffer_in_d_bits_source),
    .auto_inner_ptw_to_l2_buffer_in_d_bits_sink(g_auto_inner_ptw_to_l2_buffer_in_d_bits_sink),
    .auto_inner_ptw_to_l2_buffer_in_d_bits_denied(g_auto_inner_ptw_to_l2_buffer_in_d_bits_denied),
    .auto_inner_ptw_to_l2_buffer_in_d_bits_data(g_auto_inner_ptw_to_l2_buffer_in_d_bits_data),
    .auto_inner_ptw_to_l2_buffer_in_d_bits_corrupt(g_auto_inner_ptw_to_l2_buffer_in_d_bits_corrupt),
    .auto_inner_logger_in_1_a_ready(g_auto_inner_logger_in_1_a_ready),
    .auto_inner_logger_in_1_a_valid(auto_inner_logger_in_1_a_valid),
    .auto_inner_logger_in_1_a_bits_opcode(auto_inner_logger_in_1_a_bits_opcode),
    .auto_inner_logger_in_1_a_bits_param(auto_inner_logger_in_1_a_bits_param),
    .auto_inner_logger_in_1_a_bits_size(auto_inner_logger_in_1_a_bits_size),
    .auto_inner_logger_in_1_a_bits_source(auto_inner_logger_in_1_a_bits_source),
    .auto_inner_logger_in_1_a_bits_address(auto_inner_logger_in_1_a_bits_address),
    .auto_inner_logger_in_1_a_bits_user_alias(auto_inner_logger_in_1_a_bits_user_alias),
    .auto_inner_logger_in_1_a_bits_user_reqSource(auto_inner_logger_in_1_a_bits_user_reqSource),
    .auto_inner_logger_in_1_a_bits_user_needHint(auto_inner_logger_in_1_a_bits_user_needHint),
    .auto_inner_logger_in_1_a_bits_mask(auto_inner_logger_in_1_a_bits_mask),
    .auto_inner_logger_in_1_a_bits_data(auto_inner_logger_in_1_a_bits_data),
    .auto_inner_logger_in_1_a_bits_corrupt(auto_inner_logger_in_1_a_bits_corrupt),
    .auto_inner_logger_in_1_d_ready(auto_inner_logger_in_1_d_ready),
    .auto_inner_logger_in_1_d_valid(g_auto_inner_logger_in_1_d_valid),
    .auto_inner_logger_in_1_d_bits_opcode(g_auto_inner_logger_in_1_d_bits_opcode),
    .auto_inner_logger_in_1_d_bits_param(g_auto_inner_logger_in_1_d_bits_param),
    .auto_inner_logger_in_1_d_bits_size(g_auto_inner_logger_in_1_d_bits_size),
    .auto_inner_logger_in_1_d_bits_source(g_auto_inner_logger_in_1_d_bits_source),
    .auto_inner_logger_in_1_d_bits_sink(g_auto_inner_logger_in_1_d_bits_sink),
    .auto_inner_logger_in_1_d_bits_denied(g_auto_inner_logger_in_1_d_bits_denied),
    .auto_inner_logger_in_1_d_bits_data(g_auto_inner_logger_in_1_d_bits_data),
    .auto_inner_logger_in_1_d_bits_corrupt(g_auto_inner_logger_in_1_d_bits_corrupt),
    .auto_inner_logger_in_0_a_ready(g_auto_inner_logger_in_0_a_ready),
    .auto_inner_logger_in_0_a_valid(auto_inner_logger_in_0_a_valid),
    .auto_inner_logger_in_0_a_bits_opcode(auto_inner_logger_in_0_a_bits_opcode),
    .auto_inner_logger_in_0_a_bits_param(auto_inner_logger_in_0_a_bits_param),
    .auto_inner_logger_in_0_a_bits_size(auto_inner_logger_in_0_a_bits_size),
    .auto_inner_logger_in_0_a_bits_source(auto_inner_logger_in_0_a_bits_source),
    .auto_inner_logger_in_0_a_bits_address(auto_inner_logger_in_0_a_bits_address),
    .auto_inner_logger_in_0_a_bits_user_alias(auto_inner_logger_in_0_a_bits_user_alias),
    .auto_inner_logger_in_0_a_bits_user_vaddr(auto_inner_logger_in_0_a_bits_user_vaddr),
    .auto_inner_logger_in_0_a_bits_user_reqSource(auto_inner_logger_in_0_a_bits_user_reqSource),
    .auto_inner_logger_in_0_a_bits_user_needHint(auto_inner_logger_in_0_a_bits_user_needHint),
    .auto_inner_logger_in_0_a_bits_echo_isKeyword(auto_inner_logger_in_0_a_bits_echo_isKeyword),
    .auto_inner_logger_in_0_a_bits_mask(auto_inner_logger_in_0_a_bits_mask),
    .auto_inner_logger_in_0_a_bits_data(auto_inner_logger_in_0_a_bits_data),
    .auto_inner_logger_in_0_a_bits_corrupt(auto_inner_logger_in_0_a_bits_corrupt),
    .auto_inner_logger_in_0_b_ready(auto_inner_logger_in_0_b_ready),
    .auto_inner_logger_in_0_b_valid(g_auto_inner_logger_in_0_b_valid),
    .auto_inner_logger_in_0_b_bits_opcode(g_auto_inner_logger_in_0_b_bits_opcode),
    .auto_inner_logger_in_0_b_bits_param(g_auto_inner_logger_in_0_b_bits_param),
    .auto_inner_logger_in_0_b_bits_size(g_auto_inner_logger_in_0_b_bits_size),
    .auto_inner_logger_in_0_b_bits_source(g_auto_inner_logger_in_0_b_bits_source),
    .auto_inner_logger_in_0_b_bits_address(g_auto_inner_logger_in_0_b_bits_address),
    .auto_inner_logger_in_0_b_bits_mask(g_auto_inner_logger_in_0_b_bits_mask),
    .auto_inner_logger_in_0_b_bits_data(g_auto_inner_logger_in_0_b_bits_data),
    .auto_inner_logger_in_0_b_bits_corrupt(g_auto_inner_logger_in_0_b_bits_corrupt),
    .auto_inner_logger_in_0_c_ready(g_auto_inner_logger_in_0_c_ready),
    .auto_inner_logger_in_0_c_valid(auto_inner_logger_in_0_c_valid),
    .auto_inner_logger_in_0_c_bits_opcode(auto_inner_logger_in_0_c_bits_opcode),
    .auto_inner_logger_in_0_c_bits_param(auto_inner_logger_in_0_c_bits_param),
    .auto_inner_logger_in_0_c_bits_size(auto_inner_logger_in_0_c_bits_size),
    .auto_inner_logger_in_0_c_bits_source(auto_inner_logger_in_0_c_bits_source),
    .auto_inner_logger_in_0_c_bits_address(auto_inner_logger_in_0_c_bits_address),
    .auto_inner_logger_in_0_c_bits_user_alias(auto_inner_logger_in_0_c_bits_user_alias),
    .auto_inner_logger_in_0_c_bits_user_vaddr(auto_inner_logger_in_0_c_bits_user_vaddr),
    .auto_inner_logger_in_0_c_bits_user_reqSource(auto_inner_logger_in_0_c_bits_user_reqSource),
    .auto_inner_logger_in_0_c_bits_user_needHint(auto_inner_logger_in_0_c_bits_user_needHint),
    .auto_inner_logger_in_0_c_bits_echo_isKeyword(auto_inner_logger_in_0_c_bits_echo_isKeyword),
    .auto_inner_logger_in_0_c_bits_data(auto_inner_logger_in_0_c_bits_data),
    .auto_inner_logger_in_0_c_bits_corrupt(auto_inner_logger_in_0_c_bits_corrupt),
    .auto_inner_logger_in_0_d_ready(auto_inner_logger_in_0_d_ready),
    .auto_inner_logger_in_0_d_valid(g_auto_inner_logger_in_0_d_valid),
    .auto_inner_logger_in_0_d_bits_opcode(g_auto_inner_logger_in_0_d_bits_opcode),
    .auto_inner_logger_in_0_d_bits_param(g_auto_inner_logger_in_0_d_bits_param),
    .auto_inner_logger_in_0_d_bits_size(g_auto_inner_logger_in_0_d_bits_size),
    .auto_inner_logger_in_0_d_bits_source(g_auto_inner_logger_in_0_d_bits_source),
    .auto_inner_logger_in_0_d_bits_sink(g_auto_inner_logger_in_0_d_bits_sink),
    .auto_inner_logger_in_0_d_bits_denied(g_auto_inner_logger_in_0_d_bits_denied),
    .auto_inner_logger_in_0_d_bits_echo_isKeyword(g_auto_inner_logger_in_0_d_bits_echo_isKeyword),
    .auto_inner_logger_in_0_d_bits_data(g_auto_inner_logger_in_0_d_bits_data),
    .auto_inner_logger_in_0_d_bits_corrupt(g_auto_inner_logger_in_0_d_bits_corrupt),
    .auto_inner_logger_in_0_e_ready(g_auto_inner_logger_in_0_e_ready),
    .auto_inner_logger_in_0_e_valid(auto_inner_logger_in_0_e_valid),
    .auto_inner_logger_in_0_e_bits_sink(auto_inner_logger_in_0_e_bits_sink),
    .auto_inner_beu_int_out_0(g_auto_inner_beu_int_out_0),
    .auto_inner_nmi_int_in_0(auto_inner_nmi_int_in_0),
    .auto_inner_nmi_int_in_1(auto_inner_nmi_int_in_1),
    .auto_inner_nmi_int_out_0(g_auto_inner_nmi_int_out_0),
    .auto_inner_nmi_int_out_1(g_auto_inner_nmi_int_out_1),
    .auto_inner_plic_int_in_1_0(auto_inner_plic_int_in_1_0),
    .auto_inner_plic_int_in_0_0(auto_inner_plic_int_in_0_0),
    .auto_inner_plic_int_out_1_0(g_auto_inner_plic_int_out_1_0),
    .auto_inner_plic_int_out_0_0(g_auto_inner_plic_int_out_0_0),
    .auto_inner_debug_int_in_0(auto_inner_debug_int_in_0),
    .auto_inner_debug_int_out_0(g_auto_inner_debug_int_out_0),
    .auto_inner_clint_int_in_0(auto_inner_clint_int_in_0),
    .auto_inner_clint_int_in_1(auto_inner_clint_int_in_1),
    .auto_inner_clint_int_out_0(g_auto_inner_clint_int_out_0),
    .auto_inner_clint_int_out_1(g_auto_inner_clint_int_out_1),
    .io_beu_errors_icache_ecc_error_valid(io_beu_errors_icache_ecc_error_valid),
    .io_beu_errors_icache_ecc_error_bits(io_beu_errors_icache_ecc_error_bits),
    .io_beu_errors_dcache_ecc_error_valid(io_beu_errors_dcache_ecc_error_valid),
    .io_beu_errors_dcache_ecc_error_bits(io_beu_errors_dcache_ecc_error_bits),
    .io_beu_errors_uncache_ecc_error_valid(io_beu_errors_uncache_ecc_error_valid),
    .io_beu_errors_uncache_ecc_error_bits(io_beu_errors_uncache_ecc_error_bits),
    .io_reset_vector_fromTile(io_reset_vector_fromTile),
    .io_reset_vector_toCore(g_io_reset_vector_toCore),
    .io_hartId_fromTile(io_hartId_fromTile),
    .io_hartId_toCore(g_io_hartId_toCore),
    .io_msiInfo_fromTile_valid(io_msiInfo_fromTile_valid),
    .io_msiInfo_fromTile_bits(io_msiInfo_fromTile_bits),
    .io_msiInfo_toCore_valid(g_io_msiInfo_toCore_valid),
    .io_msiInfo_toCore_bits(g_io_msiInfo_toCore_bits),
    .io_msiAck_fromCore(io_msiAck_fromCore),
    .io_msiAck_toTile(g_io_msiAck_toTile),
    .io_cpu_halt_fromCore(io_cpu_halt_fromCore),
    .io_cpu_halt_toTile(g_io_cpu_halt_toTile),
    .io_cpu_critical_error_fromCore(io_cpu_critical_error_fromCore),
    .io_cpu_critical_error_toTile(g_io_cpu_critical_error_toTile),
    .io_hartIsInReset_resetInFrontend(io_hartIsInReset_resetInFrontend),
    .io_hartIsInReset_toTile(g_io_hartIsInReset_toTile),
    .io_traceCoreInterface_fromCore_fromEncoder_enable(g_io_traceCoreInterface_fromCore_fromEncoder_enable),
    .io_traceCoreInterface_fromCore_fromEncoder_stall(g_io_traceCoreInterface_fromCore_fromEncoder_stall),
    .io_traceCoreInterface_fromCore_toEncoder_priv(io_traceCoreInterface_fromCore_toEncoder_priv),
    .io_traceCoreInterface_fromCore_toEncoder_mstatus(io_traceCoreInterface_fromCore_toEncoder_mstatus),
    .io_traceCoreInterface_fromCore_toEncoder_trap_cause(io_traceCoreInterface_fromCore_toEncoder_trap_cause),
    .io_traceCoreInterface_fromCore_toEncoder_trap_tval(io_traceCoreInterface_fromCore_toEncoder_trap_tval),
    .io_traceCoreInterface_fromCore_toEncoder_groups_0_valid(io_traceCoreInterface_fromCore_toEncoder_groups_0_valid),
    .io_traceCoreInterface_fromCore_toEncoder_groups_0_bits_iaddr(io_traceCoreInterface_fromCore_toEncoder_groups_0_bits_iaddr),
    .io_traceCoreInterface_fromCore_toEncoder_groups_0_bits_itype(io_traceCoreInterface_fromCore_toEncoder_groups_0_bits_itype),
    .io_traceCoreInterface_fromCore_toEncoder_groups_0_bits_iretire(io_traceCoreInterface_fromCore_toEncoder_groups_0_bits_iretire),
    .io_traceCoreInterface_fromCore_toEncoder_groups_0_bits_ilastsize(io_traceCoreInterface_fromCore_toEncoder_groups_0_bits_ilastsize),
    .io_traceCoreInterface_fromCore_toEncoder_groups_1_valid(io_traceCoreInterface_fromCore_toEncoder_groups_1_valid),
    .io_traceCoreInterface_fromCore_toEncoder_groups_1_bits_iaddr(io_traceCoreInterface_fromCore_toEncoder_groups_1_bits_iaddr),
    .io_traceCoreInterface_fromCore_toEncoder_groups_1_bits_itype(io_traceCoreInterface_fromCore_toEncoder_groups_1_bits_itype),
    .io_traceCoreInterface_fromCore_toEncoder_groups_1_bits_iretire(io_traceCoreInterface_fromCore_toEncoder_groups_1_bits_iretire),
    .io_traceCoreInterface_fromCore_toEncoder_groups_1_bits_ilastsize(io_traceCoreInterface_fromCore_toEncoder_groups_1_bits_ilastsize),
    .io_traceCoreInterface_fromCore_toEncoder_groups_2_valid(io_traceCoreInterface_fromCore_toEncoder_groups_2_valid),
    .io_traceCoreInterface_fromCore_toEncoder_groups_2_bits_iaddr(io_traceCoreInterface_fromCore_toEncoder_groups_2_bits_iaddr),
    .io_traceCoreInterface_fromCore_toEncoder_groups_2_bits_itype(io_traceCoreInterface_fromCore_toEncoder_groups_2_bits_itype),
    .io_traceCoreInterface_fromCore_toEncoder_groups_2_bits_iretire(io_traceCoreInterface_fromCore_toEncoder_groups_2_bits_iretire),
    .io_traceCoreInterface_fromCore_toEncoder_groups_2_bits_ilastsize(io_traceCoreInterface_fromCore_toEncoder_groups_2_bits_ilastsize),
    .io_traceCoreInterface_toTile_fromEncoder_enable(io_traceCoreInterface_toTile_fromEncoder_enable),
    .io_traceCoreInterface_toTile_fromEncoder_stall(io_traceCoreInterface_toTile_fromEncoder_stall),
    .io_traceCoreInterface_toTile_toEncoder_priv(g_io_traceCoreInterface_toTile_toEncoder_priv),
    .io_traceCoreInterface_toTile_toEncoder_mstatus(g_io_traceCoreInterface_toTile_toEncoder_mstatus),
    .io_traceCoreInterface_toTile_toEncoder_trap_cause(g_io_traceCoreInterface_toTile_toEncoder_trap_cause),
    .io_traceCoreInterface_toTile_toEncoder_trap_tval(g_io_traceCoreInterface_toTile_toEncoder_trap_tval),
    .io_traceCoreInterface_toTile_toEncoder_groups_0_valid(g_io_traceCoreInterface_toTile_toEncoder_groups_0_valid),
    .io_traceCoreInterface_toTile_toEncoder_groups_0_bits_iaddr(g_io_traceCoreInterface_toTile_toEncoder_groups_0_bits_iaddr),
    .io_traceCoreInterface_toTile_toEncoder_groups_0_bits_itype(g_io_traceCoreInterface_toTile_toEncoder_groups_0_bits_itype),
    .io_traceCoreInterface_toTile_toEncoder_groups_0_bits_iretire(g_io_traceCoreInterface_toTile_toEncoder_groups_0_bits_iretire),
    .io_traceCoreInterface_toTile_toEncoder_groups_0_bits_ilastsize(g_io_traceCoreInterface_toTile_toEncoder_groups_0_bits_ilastsize),
    .io_traceCoreInterface_toTile_toEncoder_groups_1_valid(g_io_traceCoreInterface_toTile_toEncoder_groups_1_valid),
    .io_traceCoreInterface_toTile_toEncoder_groups_1_bits_iaddr(g_io_traceCoreInterface_toTile_toEncoder_groups_1_bits_iaddr),
    .io_traceCoreInterface_toTile_toEncoder_groups_1_bits_itype(g_io_traceCoreInterface_toTile_toEncoder_groups_1_bits_itype),
    .io_traceCoreInterface_toTile_toEncoder_groups_1_bits_iretire(g_io_traceCoreInterface_toTile_toEncoder_groups_1_bits_iretire),
    .io_traceCoreInterface_toTile_toEncoder_groups_1_bits_ilastsize(g_io_traceCoreInterface_toTile_toEncoder_groups_1_bits_ilastsize),
    .io_traceCoreInterface_toTile_toEncoder_groups_2_valid(g_io_traceCoreInterface_toTile_toEncoder_groups_2_valid),
    .io_traceCoreInterface_toTile_toEncoder_groups_2_bits_iaddr(g_io_traceCoreInterface_toTile_toEncoder_groups_2_bits_iaddr),
    .io_traceCoreInterface_toTile_toEncoder_groups_2_bits_itype(g_io_traceCoreInterface_toTile_toEncoder_groups_2_bits_itype),
    .io_traceCoreInterface_toTile_toEncoder_groups_2_bits_iretire(g_io_traceCoreInterface_toTile_toEncoder_groups_2_bits_iretire),
    .io_traceCoreInterface_toTile_toEncoder_groups_2_bits_ilastsize(g_io_traceCoreInterface_toTile_toEncoder_groups_2_bits_ilastsize),
    .io_debugTopDown_robHeadPaddr_valid(io_debugTopDown_robHeadPaddr_valid),
    .io_debugTopDown_robHeadPaddr_bits(io_debugTopDown_robHeadPaddr_bits),
    .io_debugTopDown_l2MissMatch(g_io_debugTopDown_l2MissMatch),
    .io_l2Miss(g_io_l2Miss),
    .io_l3Miss_fromTile(io_l3Miss_fromTile),
    .io_l3Miss_toCore(g_io_l3Miss_toCore),
    .io_clintTime_fromTile_valid(io_clintTime_fromTile_valid),
    .io_clintTime_fromTile_bits(io_clintTime_fromTile_bits),
    .io_clintTime_toCore_valid(g_io_clintTime_toCore_valid),
    .io_clintTime_toCore_bits(g_io_clintTime_toCore_bits),
    .io_chi_txsactive(g_io_chi_txsactive),
    .io_chi_rxsactive(io_chi_rxsactive),
    .io_chi_syscoreq(g_io_chi_syscoreq),
    .io_chi_syscoack(io_chi_syscoack),
    .io_chi_tx_linkactivereq(g_io_chi_tx_linkactivereq),
    .io_chi_tx_linkactiveack(io_chi_tx_linkactiveack),
    .io_chi_tx_req_flitpend(g_io_chi_tx_req_flitpend),
    .io_chi_tx_req_flitv(g_io_chi_tx_req_flitv),
    .io_chi_tx_req_flit(g_io_chi_tx_req_flit),
    .io_chi_tx_req_lcrdv(io_chi_tx_req_lcrdv),
    .io_chi_tx_rsp_flitpend(g_io_chi_tx_rsp_flitpend),
    .io_chi_tx_rsp_flitv(g_io_chi_tx_rsp_flitv),
    .io_chi_tx_rsp_flit(g_io_chi_tx_rsp_flit),
    .io_chi_tx_rsp_lcrdv(io_chi_tx_rsp_lcrdv),
    .io_chi_tx_dat_flitpend(g_io_chi_tx_dat_flitpend),
    .io_chi_tx_dat_flitv(g_io_chi_tx_dat_flitv),
    .io_chi_tx_dat_flit(g_io_chi_tx_dat_flit),
    .io_chi_tx_dat_lcrdv(io_chi_tx_dat_lcrdv),
    .io_chi_rx_linkactivereq(io_chi_rx_linkactivereq),
    .io_chi_rx_linkactiveack(g_io_chi_rx_linkactiveack),
    .io_chi_rx_rsp_flitpend(io_chi_rx_rsp_flitpend),
    .io_chi_rx_rsp_flitv(io_chi_rx_rsp_flitv),
    .io_chi_rx_rsp_flit(io_chi_rx_rsp_flit),
    .io_chi_rx_rsp_lcrdv(g_io_chi_rx_rsp_lcrdv),
    .io_chi_rx_dat_flitpend(io_chi_rx_dat_flitpend),
    .io_chi_rx_dat_flitv(io_chi_rx_dat_flitv),
    .io_chi_rx_dat_flit(io_chi_rx_dat_flit),
    .io_chi_rx_dat_lcrdv(g_io_chi_rx_dat_lcrdv),
    .io_chi_rx_snp_flitpend(io_chi_rx_snp_flitpend),
    .io_chi_rx_snp_flitv(io_chi_rx_snp_flitv),
    .io_chi_rx_snp_flit(io_chi_rx_snp_flit),
    .io_chi_rx_snp_lcrdv(g_io_chi_rx_snp_lcrdv),
    .io_nodeID(io_nodeID),
    .io_pfCtrlFromCore_l2_pf_master_en(io_pfCtrlFromCore_l2_pf_master_en),
    .io_pfCtrlFromCore_l2_pf_recv_en(io_pfCtrlFromCore_l2_pf_recv_en),
    .io_pfCtrlFromCore_l2_pbop_en(io_pfCtrlFromCore_l2_pbop_en),
    .io_pfCtrlFromCore_l2_vbop_en(io_pfCtrlFromCore_l2_vbop_en),
    .io_pfCtrlFromCore_l2_pf_delay_latency(io_pfCtrlFromCore_l2_pf_delay_latency),
    .io_l2_tlb_req_req_valid(g_io_l2_tlb_req_req_valid),
    .io_l2_tlb_req_req_bits_vaddr(g_io_l2_tlb_req_req_bits_vaddr),
    .io_l2_tlb_req_req_bits_cmd(g_io_l2_tlb_req_req_bits_cmd),
    .io_l2_tlb_req_req_bits_kill(g_io_l2_tlb_req_req_bits_kill),
    .io_l2_tlb_req_req_bits_isPrefetch(g_io_l2_tlb_req_req_bits_isPrefetch),
    .io_l2_tlb_req_req_bits_no_translate(g_io_l2_tlb_req_req_bits_no_translate),
    .io_l2_tlb_req_resp_valid(io_l2_tlb_req_resp_valid),
    .io_l2_tlb_req_resp_bits_paddr_0(io_l2_tlb_req_resp_bits_paddr_0),
    .io_l2_tlb_req_resp_bits_pbmt_0(io_l2_tlb_req_resp_bits_pbmt_0),
    .io_l2_tlb_req_resp_bits_miss(io_l2_tlb_req_resp_bits_miss),
    .io_l2_tlb_req_resp_bits_excp_0_gpf_ld(io_l2_tlb_req_resp_bits_excp_0_gpf_ld),
    .io_l2_tlb_req_resp_bits_excp_0_pf_ld(io_l2_tlb_req_resp_bits_excp_0_pf_ld),
    .io_l2_tlb_req_resp_bits_excp_0_af_ld(io_l2_tlb_req_resp_bits_excp_0_af_ld),
    .io_l2_pmp_resp_ld(io_l2_pmp_resp_ld),
    .io_l2_pmp_resp_mmio(io_l2_pmp_resp_mmio),
    .io_l2_hint_valid(g_io_l2_hint_valid),
    .io_l2_hint_bits_sourceId(g_io_l2_hint_bits_sourceId),
    .io_l2_hint_bits_isKeyword(g_io_l2_hint_bits_isKeyword),
    .io_perfEvents_1_value(g_io_perfEvents_1_value),
    .io_perfEvents_2_value(g_io_perfEvents_2_value),
    .io_perfEvents_3_value(g_io_perfEvents_3_value),
    .io_perfEvents_4_value(g_io_perfEvents_4_value),
    .io_perfEvents_5_value(g_io_perfEvents_5_value),
    .io_perfEvents_6_value(g_io_perfEvents_6_value),
    .io_perfEvents_7_value(g_io_perfEvents_7_value),
    .io_perfEvents_8_value(g_io_perfEvents_8_value),
    .io_perfEvents_9_value(g_io_perfEvents_9_value),
    .io_perfEvents_10_value(g_io_perfEvents_10_value),
    .io_perfEvents_11_value(g_io_perfEvents_11_value),
    .io_perfEvents_12_value(g_io_perfEvents_12_value),
    .io_perfEvents_13_value(g_io_perfEvents_13_value),
    .io_perfEvents_14_value(g_io_perfEvents_14_value),
    .io_perfEvents_15_value(g_io_perfEvents_15_value),
    .io_perfEvents_16_value(g_io_perfEvents_16_value),
    .io_perfEvents_17_value(g_io_perfEvents_17_value),
    .io_perfEvents_18_value(g_io_perfEvents_18_value),
    .io_perfEvents_19_value(g_io_perfEvents_19_value),
    .io_perfEvents_20_value(g_io_perfEvents_20_value),
    .io_perfEvents_21_value(g_io_perfEvents_21_value),
    .io_perfEvents_22_value(g_io_perfEvents_22_value),
    .io_perfEvents_23_value(g_io_perfEvents_23_value),
    .io_perfEvents_24_value(g_io_perfEvents_24_value),
    .io_perfEvents_25_value(g_io_perfEvents_25_value),
    .io_perfEvents_26_value(g_io_perfEvents_26_value),
    .io_perfEvents_27_value(g_io_perfEvents_27_value),
    .io_perfEvents_28_value(g_io_perfEvents_28_value),
    .io_perfEvents_29_value(g_io_perfEvents_29_value),
    .io_perfEvents_30_value(g_io_perfEvents_30_value),
    .io_perfEvents_31_value(g_io_perfEvents_31_value),
    .io_perfEvents_32_value(g_io_perfEvents_32_value),
    .io_perfEvents_33_value(g_io_perfEvents_33_value),
    .io_perfEvents_34_value(g_io_perfEvents_34_value),
    .io_perfEvents_35_value(g_io_perfEvents_35_value),
    .io_perfEvents_36_value(g_io_perfEvents_36_value),
    .io_perfEvents_37_value(g_io_perfEvents_37_value),
    .io_perfEvents_38_value(g_io_perfEvents_38_value),
    .io_perfEvents_39_value(g_io_perfEvents_39_value),
    .io_perfEvents_40_value(g_io_perfEvents_40_value),
    .io_perfEvents_41_value(g_io_perfEvents_41_value),
    .io_perfEvents_42_value(g_io_perfEvents_42_value),
    .io_perfEvents_43_value(g_io_perfEvents_43_value),
    .io_perfEvents_44_value(g_io_perfEvents_44_value),
    .io_perfEvents_45_value(g_io_perfEvents_45_value),
    .io_perfEvents_46_value(g_io_perfEvents_46_value),
    .io_perfEvents_47_value(g_io_perfEvents_47_value),
    .io_perfEvents_48_value(g_io_perfEvents_48_value),
    .io_perfEvents_49_value(g_io_perfEvents_49_value),
    .io_perfEvents_50_value(g_io_perfEvents_50_value),
    .io_perfEvents_51_value(g_io_perfEvents_51_value),
    .io_perfEvents_52_value(g_io_perfEvents_52_value),
    .io_perfEvents_53_value(g_io_perfEvents_53_value),
    .io_perfEvents_54_value(g_io_perfEvents_54_value),
    .io_perfEvents_55_value(g_io_perfEvents_55_value),
    .io_perfEvents_56_value(g_io_perfEvents_56_value),
    .io_perfEvents_57_value(g_io_perfEvents_57_value),
    .io_perfEvents_58_value(g_io_perfEvents_58_value),
    .io_perfEvents_59_value(g_io_perfEvents_59_value),
    .io_perfEvents_60_value(g_io_perfEvents_60_value),
    .io_perfEvents_61_value(g_io_perfEvents_61_value),
    .io_perfEvents_62_value(g_io_perfEvents_62_value),
    .io_perfEvents_63_value(g_io_perfEvents_63_value),
    .io_perfEvents_64_value(g_io_perfEvents_64_value),
    .io_perfEvents_65_value(g_io_perfEvents_65_value),
    .io_perfEvents_66_value(g_io_perfEvents_66_value),
    .io_perfEvents_67_value(g_io_perfEvents_67_value),
    .io_perfEvents_68_value(g_io_perfEvents_68_value),
    .io_dft_ram_hold(io_dft_ram_hold),
    .io_dft_ram_bypass(io_dft_ram_bypass),
    .io_dft_ram_bp_clken(io_dft_ram_bp_clken),
    .io_dft_ram_aux_clk(io_dft_ram_aux_clk),
    .io_dft_ram_aux_ckbp(io_dft_ram_aux_ckbp),
    .io_dft_ram_mcp_hold(io_dft_ram_mcp_hold),
    .io_dft_cgen(io_dft_cgen)
  );
  L2Top_xs u_i (
    .clock(clock),
    .reset(reset),
    .auto_inner_buffers_out_a_ready(auto_inner_buffers_out_a_ready),
    .auto_inner_buffers_out_a_valid(i_auto_inner_buffers_out_a_valid),
    .auto_inner_buffers_out_a_bits_opcode(i_auto_inner_buffers_out_a_bits_opcode),
    .auto_inner_buffers_out_a_bits_param(i_auto_inner_buffers_out_a_bits_param),
    .auto_inner_buffers_out_a_bits_size(i_auto_inner_buffers_out_a_bits_size),
    .auto_inner_buffers_out_a_bits_source(i_auto_inner_buffers_out_a_bits_source),
    .auto_inner_buffers_out_a_bits_address(i_auto_inner_buffers_out_a_bits_address),
    .auto_inner_buffers_out_a_bits_mask(i_auto_inner_buffers_out_a_bits_mask),
    .auto_inner_buffers_out_a_bits_data(i_auto_inner_buffers_out_a_bits_data),
    .auto_inner_buffers_out_a_bits_corrupt(i_auto_inner_buffers_out_a_bits_corrupt),
    .auto_inner_buffers_out_d_ready(i_auto_inner_buffers_out_d_ready),
    .auto_inner_buffers_out_d_valid(auto_inner_buffers_out_d_valid),
    .auto_inner_buffers_out_d_bits_opcode(auto_inner_buffers_out_d_bits_opcode),
    .auto_inner_buffers_out_d_bits_param(auto_inner_buffers_out_d_bits_param),
    .auto_inner_buffers_out_d_bits_size(auto_inner_buffers_out_d_bits_size),
    .auto_inner_buffers_out_d_bits_source(auto_inner_buffers_out_d_bits_source),
    .auto_inner_buffers_out_d_bits_sink(auto_inner_buffers_out_d_bits_sink),
    .auto_inner_buffers_out_d_bits_denied(auto_inner_buffers_out_d_bits_denied),
    .auto_inner_buffers_out_d_bits_data(auto_inner_buffers_out_d_bits_data),
    .auto_inner_buffers_out_d_bits_corrupt(auto_inner_buffers_out_d_bits_corrupt),
    .auto_inner_buffers_in_a_ready(i_auto_inner_buffers_in_a_ready),
    .auto_inner_buffers_in_a_valid(auto_inner_buffers_in_a_valid),
    .auto_inner_buffers_in_a_bits_opcode(auto_inner_buffers_in_a_bits_opcode),
    .auto_inner_buffers_in_a_bits_param(auto_inner_buffers_in_a_bits_param),
    .auto_inner_buffers_in_a_bits_size(auto_inner_buffers_in_a_bits_size),
    .auto_inner_buffers_in_a_bits_source(auto_inner_buffers_in_a_bits_source),
    .auto_inner_buffers_in_a_bits_address(auto_inner_buffers_in_a_bits_address),
    .auto_inner_buffers_in_a_bits_user_memBackType_MM(auto_inner_buffers_in_a_bits_user_memBackType_MM),
    .auto_inner_buffers_in_a_bits_user_memPageType_NC(auto_inner_buffers_in_a_bits_user_memPageType_NC),
    .auto_inner_buffers_in_a_bits_mask(auto_inner_buffers_in_a_bits_mask),
    .auto_inner_buffers_in_a_bits_data(auto_inner_buffers_in_a_bits_data),
    .auto_inner_buffers_in_a_bits_corrupt(auto_inner_buffers_in_a_bits_corrupt),
    .auto_inner_buffers_in_d_ready(auto_inner_buffers_in_d_ready),
    .auto_inner_buffers_in_d_valid(i_auto_inner_buffers_in_d_valid),
    .auto_inner_buffers_in_d_bits_opcode(i_auto_inner_buffers_in_d_bits_opcode),
    .auto_inner_buffers_in_d_bits_param(i_auto_inner_buffers_in_d_bits_param),
    .auto_inner_buffers_in_d_bits_size(i_auto_inner_buffers_in_d_bits_size),
    .auto_inner_buffers_in_d_bits_source(i_auto_inner_buffers_in_d_bits_source),
    .auto_inner_buffers_in_d_bits_sink(i_auto_inner_buffers_in_d_bits_sink),
    .auto_inner_buffers_in_d_bits_denied(i_auto_inner_buffers_in_d_bits_denied),
    .auto_inner_buffers_in_d_bits_data(i_auto_inner_buffers_in_d_bits_data),
    .auto_inner_buffers_in_d_bits_corrupt(i_auto_inner_buffers_in_d_bits_corrupt),
    .auto_inner_l2cache_pf_recv_in_addr(auto_inner_l2cache_pf_recv_in_addr),
    .auto_inner_l2cache_pf_recv_in_pf_source(auto_inner_l2cache_pf_recv_in_pf_source),
    .auto_inner_l2cache_pf_recv_in_addr_valid(auto_inner_l2cache_pf_recv_in_addr_valid),
    .auto_inner_intBuffer_out_0(i_auto_inner_intBuffer_out_0),
    .auto_inner_i_mmio_buffer_in_a_ready(i_auto_inner_i_mmio_buffer_in_a_ready),
    .auto_inner_i_mmio_buffer_in_a_valid(auto_inner_i_mmio_buffer_in_a_valid),
    .auto_inner_i_mmio_buffer_in_a_bits_param(auto_inner_i_mmio_buffer_in_a_bits_param),
    .auto_inner_i_mmio_buffer_in_a_bits_address(auto_inner_i_mmio_buffer_in_a_bits_address),
    .auto_inner_i_mmio_buffer_in_a_bits_user_memPageType_NC(auto_inner_i_mmio_buffer_in_a_bits_user_memPageType_NC),
    .auto_inner_i_mmio_buffer_in_a_bits_user_memBackType_MM(auto_inner_i_mmio_buffer_in_a_bits_user_memBackType_MM),
    .auto_inner_i_mmio_buffer_in_a_bits_corrupt(auto_inner_i_mmio_buffer_in_a_bits_corrupt),
    .auto_inner_i_mmio_buffer_in_d_ready(auto_inner_i_mmio_buffer_in_d_ready),
    .auto_inner_i_mmio_buffer_in_d_valid(i_auto_inner_i_mmio_buffer_in_d_valid),
    .auto_inner_i_mmio_buffer_in_d_bits_opcode(i_auto_inner_i_mmio_buffer_in_d_bits_opcode),
    .auto_inner_i_mmio_buffer_in_d_bits_param(i_auto_inner_i_mmio_buffer_in_d_bits_param),
    .auto_inner_i_mmio_buffer_in_d_bits_size(i_auto_inner_i_mmio_buffer_in_d_bits_size),
    .auto_inner_i_mmio_buffer_in_d_bits_source(i_auto_inner_i_mmio_buffer_in_d_bits_source),
    .auto_inner_i_mmio_buffer_in_d_bits_sink(i_auto_inner_i_mmio_buffer_in_d_bits_sink),
    .auto_inner_i_mmio_buffer_in_d_bits_denied(i_auto_inner_i_mmio_buffer_in_d_bits_denied),
    .auto_inner_i_mmio_buffer_in_d_bits_data(i_auto_inner_i_mmio_buffer_in_d_bits_data),
    .auto_inner_i_mmio_buffer_in_d_bits_corrupt(i_auto_inner_i_mmio_buffer_in_d_bits_corrupt),
    .auto_inner_ptw_to_l2_buffer_in_a_ready(i_auto_inner_ptw_to_l2_buffer_in_a_ready),
    .auto_inner_ptw_to_l2_buffer_in_a_valid(auto_inner_ptw_to_l2_buffer_in_a_valid),
    .auto_inner_ptw_to_l2_buffer_in_a_bits_opcode(auto_inner_ptw_to_l2_buffer_in_a_bits_opcode),
    .auto_inner_ptw_to_l2_buffer_in_a_bits_param(auto_inner_ptw_to_l2_buffer_in_a_bits_param),
    .auto_inner_ptw_to_l2_buffer_in_a_bits_size(auto_inner_ptw_to_l2_buffer_in_a_bits_size),
    .auto_inner_ptw_to_l2_buffer_in_a_bits_source(auto_inner_ptw_to_l2_buffer_in_a_bits_source),
    .auto_inner_ptw_to_l2_buffer_in_a_bits_address(auto_inner_ptw_to_l2_buffer_in_a_bits_address),
    .auto_inner_ptw_to_l2_buffer_in_a_bits_user_reqSource(auto_inner_ptw_to_l2_buffer_in_a_bits_user_reqSource),
    .auto_inner_ptw_to_l2_buffer_in_a_bits_mask(auto_inner_ptw_to_l2_buffer_in_a_bits_mask),
    .auto_inner_ptw_to_l2_buffer_in_a_bits_data(auto_inner_ptw_to_l2_buffer_in_a_bits_data),
    .auto_inner_ptw_to_l2_buffer_in_a_bits_corrupt(auto_inner_ptw_to_l2_buffer_in_a_bits_corrupt),
    .auto_inner_ptw_to_l2_buffer_in_d_ready(auto_inner_ptw_to_l2_buffer_in_d_ready),
    .auto_inner_ptw_to_l2_buffer_in_d_valid(i_auto_inner_ptw_to_l2_buffer_in_d_valid),
    .auto_inner_ptw_to_l2_buffer_in_d_bits_opcode(i_auto_inner_ptw_to_l2_buffer_in_d_bits_opcode),
    .auto_inner_ptw_to_l2_buffer_in_d_bits_param(i_auto_inner_ptw_to_l2_buffer_in_d_bits_param),
    .auto_inner_ptw_to_l2_buffer_in_d_bits_size(i_auto_inner_ptw_to_l2_buffer_in_d_bits_size),
    .auto_inner_ptw_to_l2_buffer_in_d_bits_source(i_auto_inner_ptw_to_l2_buffer_in_d_bits_source),
    .auto_inner_ptw_to_l2_buffer_in_d_bits_sink(i_auto_inner_ptw_to_l2_buffer_in_d_bits_sink),
    .auto_inner_ptw_to_l2_buffer_in_d_bits_denied(i_auto_inner_ptw_to_l2_buffer_in_d_bits_denied),
    .auto_inner_ptw_to_l2_buffer_in_d_bits_data(i_auto_inner_ptw_to_l2_buffer_in_d_bits_data),
    .auto_inner_ptw_to_l2_buffer_in_d_bits_corrupt(i_auto_inner_ptw_to_l2_buffer_in_d_bits_corrupt),
    .auto_inner_logger_in_1_a_ready(i_auto_inner_logger_in_1_a_ready),
    .auto_inner_logger_in_1_a_valid(auto_inner_logger_in_1_a_valid),
    .auto_inner_logger_in_1_a_bits_opcode(auto_inner_logger_in_1_a_bits_opcode),
    .auto_inner_logger_in_1_a_bits_param(auto_inner_logger_in_1_a_bits_param),
    .auto_inner_logger_in_1_a_bits_size(auto_inner_logger_in_1_a_bits_size),
    .auto_inner_logger_in_1_a_bits_source(auto_inner_logger_in_1_a_bits_source),
    .auto_inner_logger_in_1_a_bits_address(auto_inner_logger_in_1_a_bits_address),
    .auto_inner_logger_in_1_a_bits_user_alias(auto_inner_logger_in_1_a_bits_user_alias),
    .auto_inner_logger_in_1_a_bits_user_reqSource(auto_inner_logger_in_1_a_bits_user_reqSource),
    .auto_inner_logger_in_1_a_bits_user_needHint(auto_inner_logger_in_1_a_bits_user_needHint),
    .auto_inner_logger_in_1_a_bits_mask(auto_inner_logger_in_1_a_bits_mask),
    .auto_inner_logger_in_1_a_bits_data(auto_inner_logger_in_1_a_bits_data),
    .auto_inner_logger_in_1_a_bits_corrupt(auto_inner_logger_in_1_a_bits_corrupt),
    .auto_inner_logger_in_1_d_ready(auto_inner_logger_in_1_d_ready),
    .auto_inner_logger_in_1_d_valid(i_auto_inner_logger_in_1_d_valid),
    .auto_inner_logger_in_1_d_bits_opcode(i_auto_inner_logger_in_1_d_bits_opcode),
    .auto_inner_logger_in_1_d_bits_param(i_auto_inner_logger_in_1_d_bits_param),
    .auto_inner_logger_in_1_d_bits_size(i_auto_inner_logger_in_1_d_bits_size),
    .auto_inner_logger_in_1_d_bits_source(i_auto_inner_logger_in_1_d_bits_source),
    .auto_inner_logger_in_1_d_bits_sink(i_auto_inner_logger_in_1_d_bits_sink),
    .auto_inner_logger_in_1_d_bits_denied(i_auto_inner_logger_in_1_d_bits_denied),
    .auto_inner_logger_in_1_d_bits_data(i_auto_inner_logger_in_1_d_bits_data),
    .auto_inner_logger_in_1_d_bits_corrupt(i_auto_inner_logger_in_1_d_bits_corrupt),
    .auto_inner_logger_in_0_a_ready(i_auto_inner_logger_in_0_a_ready),
    .auto_inner_logger_in_0_a_valid(auto_inner_logger_in_0_a_valid),
    .auto_inner_logger_in_0_a_bits_opcode(auto_inner_logger_in_0_a_bits_opcode),
    .auto_inner_logger_in_0_a_bits_param(auto_inner_logger_in_0_a_bits_param),
    .auto_inner_logger_in_0_a_bits_size(auto_inner_logger_in_0_a_bits_size),
    .auto_inner_logger_in_0_a_bits_source(auto_inner_logger_in_0_a_bits_source),
    .auto_inner_logger_in_0_a_bits_address(auto_inner_logger_in_0_a_bits_address),
    .auto_inner_logger_in_0_a_bits_user_alias(auto_inner_logger_in_0_a_bits_user_alias),
    .auto_inner_logger_in_0_a_bits_user_vaddr(auto_inner_logger_in_0_a_bits_user_vaddr),
    .auto_inner_logger_in_0_a_bits_user_reqSource(auto_inner_logger_in_0_a_bits_user_reqSource),
    .auto_inner_logger_in_0_a_bits_user_needHint(auto_inner_logger_in_0_a_bits_user_needHint),
    .auto_inner_logger_in_0_a_bits_echo_isKeyword(auto_inner_logger_in_0_a_bits_echo_isKeyword),
    .auto_inner_logger_in_0_a_bits_mask(auto_inner_logger_in_0_a_bits_mask),
    .auto_inner_logger_in_0_a_bits_data(auto_inner_logger_in_0_a_bits_data),
    .auto_inner_logger_in_0_a_bits_corrupt(auto_inner_logger_in_0_a_bits_corrupt),
    .auto_inner_logger_in_0_b_ready(auto_inner_logger_in_0_b_ready),
    .auto_inner_logger_in_0_b_valid(i_auto_inner_logger_in_0_b_valid),
    .auto_inner_logger_in_0_b_bits_opcode(i_auto_inner_logger_in_0_b_bits_opcode),
    .auto_inner_logger_in_0_b_bits_param(i_auto_inner_logger_in_0_b_bits_param),
    .auto_inner_logger_in_0_b_bits_size(i_auto_inner_logger_in_0_b_bits_size),
    .auto_inner_logger_in_0_b_bits_source(i_auto_inner_logger_in_0_b_bits_source),
    .auto_inner_logger_in_0_b_bits_address(i_auto_inner_logger_in_0_b_bits_address),
    .auto_inner_logger_in_0_b_bits_mask(i_auto_inner_logger_in_0_b_bits_mask),
    .auto_inner_logger_in_0_b_bits_data(i_auto_inner_logger_in_0_b_bits_data),
    .auto_inner_logger_in_0_b_bits_corrupt(i_auto_inner_logger_in_0_b_bits_corrupt),
    .auto_inner_logger_in_0_c_ready(i_auto_inner_logger_in_0_c_ready),
    .auto_inner_logger_in_0_c_valid(auto_inner_logger_in_0_c_valid),
    .auto_inner_logger_in_0_c_bits_opcode(auto_inner_logger_in_0_c_bits_opcode),
    .auto_inner_logger_in_0_c_bits_param(auto_inner_logger_in_0_c_bits_param),
    .auto_inner_logger_in_0_c_bits_size(auto_inner_logger_in_0_c_bits_size),
    .auto_inner_logger_in_0_c_bits_source(auto_inner_logger_in_0_c_bits_source),
    .auto_inner_logger_in_0_c_bits_address(auto_inner_logger_in_0_c_bits_address),
    .auto_inner_logger_in_0_c_bits_user_alias(auto_inner_logger_in_0_c_bits_user_alias),
    .auto_inner_logger_in_0_c_bits_user_vaddr(auto_inner_logger_in_0_c_bits_user_vaddr),
    .auto_inner_logger_in_0_c_bits_user_reqSource(auto_inner_logger_in_0_c_bits_user_reqSource),
    .auto_inner_logger_in_0_c_bits_user_needHint(auto_inner_logger_in_0_c_bits_user_needHint),
    .auto_inner_logger_in_0_c_bits_echo_isKeyword(auto_inner_logger_in_0_c_bits_echo_isKeyword),
    .auto_inner_logger_in_0_c_bits_data(auto_inner_logger_in_0_c_bits_data),
    .auto_inner_logger_in_0_c_bits_corrupt(auto_inner_logger_in_0_c_bits_corrupt),
    .auto_inner_logger_in_0_d_ready(auto_inner_logger_in_0_d_ready),
    .auto_inner_logger_in_0_d_valid(i_auto_inner_logger_in_0_d_valid),
    .auto_inner_logger_in_0_d_bits_opcode(i_auto_inner_logger_in_0_d_bits_opcode),
    .auto_inner_logger_in_0_d_bits_param(i_auto_inner_logger_in_0_d_bits_param),
    .auto_inner_logger_in_0_d_bits_size(i_auto_inner_logger_in_0_d_bits_size),
    .auto_inner_logger_in_0_d_bits_source(i_auto_inner_logger_in_0_d_bits_source),
    .auto_inner_logger_in_0_d_bits_sink(i_auto_inner_logger_in_0_d_bits_sink),
    .auto_inner_logger_in_0_d_bits_denied(i_auto_inner_logger_in_0_d_bits_denied),
    .auto_inner_logger_in_0_d_bits_echo_isKeyword(i_auto_inner_logger_in_0_d_bits_echo_isKeyword),
    .auto_inner_logger_in_0_d_bits_data(i_auto_inner_logger_in_0_d_bits_data),
    .auto_inner_logger_in_0_d_bits_corrupt(i_auto_inner_logger_in_0_d_bits_corrupt),
    .auto_inner_logger_in_0_e_ready(i_auto_inner_logger_in_0_e_ready),
    .auto_inner_logger_in_0_e_valid(auto_inner_logger_in_0_e_valid),
    .auto_inner_logger_in_0_e_bits_sink(auto_inner_logger_in_0_e_bits_sink),
    .auto_inner_beu_int_out_0(i_auto_inner_beu_int_out_0),
    .auto_inner_nmi_int_in_0(auto_inner_nmi_int_in_0),
    .auto_inner_nmi_int_in_1(auto_inner_nmi_int_in_1),
    .auto_inner_nmi_int_out_0(i_auto_inner_nmi_int_out_0),
    .auto_inner_nmi_int_out_1(i_auto_inner_nmi_int_out_1),
    .auto_inner_plic_int_in_1_0(auto_inner_plic_int_in_1_0),
    .auto_inner_plic_int_in_0_0(auto_inner_plic_int_in_0_0),
    .auto_inner_plic_int_out_1_0(i_auto_inner_plic_int_out_1_0),
    .auto_inner_plic_int_out_0_0(i_auto_inner_plic_int_out_0_0),
    .auto_inner_debug_int_in_0(auto_inner_debug_int_in_0),
    .auto_inner_debug_int_out_0(i_auto_inner_debug_int_out_0),
    .auto_inner_clint_int_in_0(auto_inner_clint_int_in_0),
    .auto_inner_clint_int_in_1(auto_inner_clint_int_in_1),
    .auto_inner_clint_int_out_0(i_auto_inner_clint_int_out_0),
    .auto_inner_clint_int_out_1(i_auto_inner_clint_int_out_1),
    .io_beu_errors_icache_ecc_error_valid(io_beu_errors_icache_ecc_error_valid),
    .io_beu_errors_icache_ecc_error_bits(io_beu_errors_icache_ecc_error_bits),
    .io_beu_errors_dcache_ecc_error_valid(io_beu_errors_dcache_ecc_error_valid),
    .io_beu_errors_dcache_ecc_error_bits(io_beu_errors_dcache_ecc_error_bits),
    .io_beu_errors_uncache_ecc_error_valid(io_beu_errors_uncache_ecc_error_valid),
    .io_beu_errors_uncache_ecc_error_bits(io_beu_errors_uncache_ecc_error_bits),
    .io_reset_vector_fromTile(io_reset_vector_fromTile),
    .io_reset_vector_toCore(i_io_reset_vector_toCore),
    .io_hartId_fromTile(io_hartId_fromTile),
    .io_hartId_toCore(i_io_hartId_toCore),
    .io_msiInfo_fromTile_valid(io_msiInfo_fromTile_valid),
    .io_msiInfo_fromTile_bits(io_msiInfo_fromTile_bits),
    .io_msiInfo_toCore_valid(i_io_msiInfo_toCore_valid),
    .io_msiInfo_toCore_bits(i_io_msiInfo_toCore_bits),
    .io_msiAck_fromCore(io_msiAck_fromCore),
    .io_msiAck_toTile(i_io_msiAck_toTile),
    .io_cpu_halt_fromCore(io_cpu_halt_fromCore),
    .io_cpu_halt_toTile(i_io_cpu_halt_toTile),
    .io_cpu_critical_error_fromCore(io_cpu_critical_error_fromCore),
    .io_cpu_critical_error_toTile(i_io_cpu_critical_error_toTile),
    .io_hartIsInReset_resetInFrontend(io_hartIsInReset_resetInFrontend),
    .io_hartIsInReset_toTile(i_io_hartIsInReset_toTile),
    .io_traceCoreInterface_fromCore_fromEncoder_enable(i_io_traceCoreInterface_fromCore_fromEncoder_enable),
    .io_traceCoreInterface_fromCore_fromEncoder_stall(i_io_traceCoreInterface_fromCore_fromEncoder_stall),
    .io_traceCoreInterface_fromCore_toEncoder_priv(io_traceCoreInterface_fromCore_toEncoder_priv),
    .io_traceCoreInterface_fromCore_toEncoder_mstatus(io_traceCoreInterface_fromCore_toEncoder_mstatus),
    .io_traceCoreInterface_fromCore_toEncoder_trap_cause(io_traceCoreInterface_fromCore_toEncoder_trap_cause),
    .io_traceCoreInterface_fromCore_toEncoder_trap_tval(io_traceCoreInterface_fromCore_toEncoder_trap_tval),
    .io_traceCoreInterface_fromCore_toEncoder_groups_0_valid(io_traceCoreInterface_fromCore_toEncoder_groups_0_valid),
    .io_traceCoreInterface_fromCore_toEncoder_groups_0_bits_iaddr(io_traceCoreInterface_fromCore_toEncoder_groups_0_bits_iaddr),
    .io_traceCoreInterface_fromCore_toEncoder_groups_0_bits_itype(io_traceCoreInterface_fromCore_toEncoder_groups_0_bits_itype),
    .io_traceCoreInterface_fromCore_toEncoder_groups_0_bits_iretire(io_traceCoreInterface_fromCore_toEncoder_groups_0_bits_iretire),
    .io_traceCoreInterface_fromCore_toEncoder_groups_0_bits_ilastsize(io_traceCoreInterface_fromCore_toEncoder_groups_0_bits_ilastsize),
    .io_traceCoreInterface_fromCore_toEncoder_groups_1_valid(io_traceCoreInterface_fromCore_toEncoder_groups_1_valid),
    .io_traceCoreInterface_fromCore_toEncoder_groups_1_bits_iaddr(io_traceCoreInterface_fromCore_toEncoder_groups_1_bits_iaddr),
    .io_traceCoreInterface_fromCore_toEncoder_groups_1_bits_itype(io_traceCoreInterface_fromCore_toEncoder_groups_1_bits_itype),
    .io_traceCoreInterface_fromCore_toEncoder_groups_1_bits_iretire(io_traceCoreInterface_fromCore_toEncoder_groups_1_bits_iretire),
    .io_traceCoreInterface_fromCore_toEncoder_groups_1_bits_ilastsize(io_traceCoreInterface_fromCore_toEncoder_groups_1_bits_ilastsize),
    .io_traceCoreInterface_fromCore_toEncoder_groups_2_valid(io_traceCoreInterface_fromCore_toEncoder_groups_2_valid),
    .io_traceCoreInterface_fromCore_toEncoder_groups_2_bits_iaddr(io_traceCoreInterface_fromCore_toEncoder_groups_2_bits_iaddr),
    .io_traceCoreInterface_fromCore_toEncoder_groups_2_bits_itype(io_traceCoreInterface_fromCore_toEncoder_groups_2_bits_itype),
    .io_traceCoreInterface_fromCore_toEncoder_groups_2_bits_iretire(io_traceCoreInterface_fromCore_toEncoder_groups_2_bits_iretire),
    .io_traceCoreInterface_fromCore_toEncoder_groups_2_bits_ilastsize(io_traceCoreInterface_fromCore_toEncoder_groups_2_bits_ilastsize),
    .io_traceCoreInterface_toTile_fromEncoder_enable(io_traceCoreInterface_toTile_fromEncoder_enable),
    .io_traceCoreInterface_toTile_fromEncoder_stall(io_traceCoreInterface_toTile_fromEncoder_stall),
    .io_traceCoreInterface_toTile_toEncoder_priv(i_io_traceCoreInterface_toTile_toEncoder_priv),
    .io_traceCoreInterface_toTile_toEncoder_mstatus(i_io_traceCoreInterface_toTile_toEncoder_mstatus),
    .io_traceCoreInterface_toTile_toEncoder_trap_cause(i_io_traceCoreInterface_toTile_toEncoder_trap_cause),
    .io_traceCoreInterface_toTile_toEncoder_trap_tval(i_io_traceCoreInterface_toTile_toEncoder_trap_tval),
    .io_traceCoreInterface_toTile_toEncoder_groups_0_valid(i_io_traceCoreInterface_toTile_toEncoder_groups_0_valid),
    .io_traceCoreInterface_toTile_toEncoder_groups_0_bits_iaddr(i_io_traceCoreInterface_toTile_toEncoder_groups_0_bits_iaddr),
    .io_traceCoreInterface_toTile_toEncoder_groups_0_bits_itype(i_io_traceCoreInterface_toTile_toEncoder_groups_0_bits_itype),
    .io_traceCoreInterface_toTile_toEncoder_groups_0_bits_iretire(i_io_traceCoreInterface_toTile_toEncoder_groups_0_bits_iretire),
    .io_traceCoreInterface_toTile_toEncoder_groups_0_bits_ilastsize(i_io_traceCoreInterface_toTile_toEncoder_groups_0_bits_ilastsize),
    .io_traceCoreInterface_toTile_toEncoder_groups_1_valid(i_io_traceCoreInterface_toTile_toEncoder_groups_1_valid),
    .io_traceCoreInterface_toTile_toEncoder_groups_1_bits_iaddr(i_io_traceCoreInterface_toTile_toEncoder_groups_1_bits_iaddr),
    .io_traceCoreInterface_toTile_toEncoder_groups_1_bits_itype(i_io_traceCoreInterface_toTile_toEncoder_groups_1_bits_itype),
    .io_traceCoreInterface_toTile_toEncoder_groups_1_bits_iretire(i_io_traceCoreInterface_toTile_toEncoder_groups_1_bits_iretire),
    .io_traceCoreInterface_toTile_toEncoder_groups_1_bits_ilastsize(i_io_traceCoreInterface_toTile_toEncoder_groups_1_bits_ilastsize),
    .io_traceCoreInterface_toTile_toEncoder_groups_2_valid(i_io_traceCoreInterface_toTile_toEncoder_groups_2_valid),
    .io_traceCoreInterface_toTile_toEncoder_groups_2_bits_iaddr(i_io_traceCoreInterface_toTile_toEncoder_groups_2_bits_iaddr),
    .io_traceCoreInterface_toTile_toEncoder_groups_2_bits_itype(i_io_traceCoreInterface_toTile_toEncoder_groups_2_bits_itype),
    .io_traceCoreInterface_toTile_toEncoder_groups_2_bits_iretire(i_io_traceCoreInterface_toTile_toEncoder_groups_2_bits_iretire),
    .io_traceCoreInterface_toTile_toEncoder_groups_2_bits_ilastsize(i_io_traceCoreInterface_toTile_toEncoder_groups_2_bits_ilastsize),
    .io_debugTopDown_robHeadPaddr_valid(io_debugTopDown_robHeadPaddr_valid),
    .io_debugTopDown_robHeadPaddr_bits(io_debugTopDown_robHeadPaddr_bits),
    .io_debugTopDown_l2MissMatch(i_io_debugTopDown_l2MissMatch),
    .io_l2Miss(i_io_l2Miss),
    .io_l3Miss_fromTile(io_l3Miss_fromTile),
    .io_l3Miss_toCore(i_io_l3Miss_toCore),
    .io_clintTime_fromTile_valid(io_clintTime_fromTile_valid),
    .io_clintTime_fromTile_bits(io_clintTime_fromTile_bits),
    .io_clintTime_toCore_valid(i_io_clintTime_toCore_valid),
    .io_clintTime_toCore_bits(i_io_clintTime_toCore_bits),
    .io_chi_txsactive(i_io_chi_txsactive),
    .io_chi_rxsactive(io_chi_rxsactive),
    .io_chi_syscoreq(i_io_chi_syscoreq),
    .io_chi_syscoack(io_chi_syscoack),
    .io_chi_tx_linkactivereq(i_io_chi_tx_linkactivereq),
    .io_chi_tx_linkactiveack(io_chi_tx_linkactiveack),
    .io_chi_tx_req_flitpend(i_io_chi_tx_req_flitpend),
    .io_chi_tx_req_flitv(i_io_chi_tx_req_flitv),
    .io_chi_tx_req_flit(i_io_chi_tx_req_flit),
    .io_chi_tx_req_lcrdv(io_chi_tx_req_lcrdv),
    .io_chi_tx_rsp_flitpend(i_io_chi_tx_rsp_flitpend),
    .io_chi_tx_rsp_flitv(i_io_chi_tx_rsp_flitv),
    .io_chi_tx_rsp_flit(i_io_chi_tx_rsp_flit),
    .io_chi_tx_rsp_lcrdv(io_chi_tx_rsp_lcrdv),
    .io_chi_tx_dat_flitpend(i_io_chi_tx_dat_flitpend),
    .io_chi_tx_dat_flitv(i_io_chi_tx_dat_flitv),
    .io_chi_tx_dat_flit(i_io_chi_tx_dat_flit),
    .io_chi_tx_dat_lcrdv(io_chi_tx_dat_lcrdv),
    .io_chi_rx_linkactivereq(io_chi_rx_linkactivereq),
    .io_chi_rx_linkactiveack(i_io_chi_rx_linkactiveack),
    .io_chi_rx_rsp_flitpend(io_chi_rx_rsp_flitpend),
    .io_chi_rx_rsp_flitv(io_chi_rx_rsp_flitv),
    .io_chi_rx_rsp_flit(io_chi_rx_rsp_flit),
    .io_chi_rx_rsp_lcrdv(i_io_chi_rx_rsp_lcrdv),
    .io_chi_rx_dat_flitpend(io_chi_rx_dat_flitpend),
    .io_chi_rx_dat_flitv(io_chi_rx_dat_flitv),
    .io_chi_rx_dat_flit(io_chi_rx_dat_flit),
    .io_chi_rx_dat_lcrdv(i_io_chi_rx_dat_lcrdv),
    .io_chi_rx_snp_flitpend(io_chi_rx_snp_flitpend),
    .io_chi_rx_snp_flitv(io_chi_rx_snp_flitv),
    .io_chi_rx_snp_flit(io_chi_rx_snp_flit),
    .io_chi_rx_snp_lcrdv(i_io_chi_rx_snp_lcrdv),
    .io_nodeID(io_nodeID),
    .io_pfCtrlFromCore_l2_pf_master_en(io_pfCtrlFromCore_l2_pf_master_en),
    .io_pfCtrlFromCore_l2_pf_recv_en(io_pfCtrlFromCore_l2_pf_recv_en),
    .io_pfCtrlFromCore_l2_pbop_en(io_pfCtrlFromCore_l2_pbop_en),
    .io_pfCtrlFromCore_l2_vbop_en(io_pfCtrlFromCore_l2_vbop_en),
    .io_pfCtrlFromCore_l2_pf_delay_latency(io_pfCtrlFromCore_l2_pf_delay_latency),
    .io_l2_tlb_req_req_valid(i_io_l2_tlb_req_req_valid),
    .io_l2_tlb_req_req_bits_vaddr(i_io_l2_tlb_req_req_bits_vaddr),
    .io_l2_tlb_req_req_bits_cmd(i_io_l2_tlb_req_req_bits_cmd),
    .io_l2_tlb_req_req_bits_kill(i_io_l2_tlb_req_req_bits_kill),
    .io_l2_tlb_req_req_bits_isPrefetch(i_io_l2_tlb_req_req_bits_isPrefetch),
    .io_l2_tlb_req_req_bits_no_translate(i_io_l2_tlb_req_req_bits_no_translate),
    .io_l2_tlb_req_resp_valid(io_l2_tlb_req_resp_valid),
    .io_l2_tlb_req_resp_bits_paddr_0(io_l2_tlb_req_resp_bits_paddr_0),
    .io_l2_tlb_req_resp_bits_pbmt_0(io_l2_tlb_req_resp_bits_pbmt_0),
    .io_l2_tlb_req_resp_bits_miss(io_l2_tlb_req_resp_bits_miss),
    .io_l2_tlb_req_resp_bits_excp_0_gpf_ld(io_l2_tlb_req_resp_bits_excp_0_gpf_ld),
    .io_l2_tlb_req_resp_bits_excp_0_pf_ld(io_l2_tlb_req_resp_bits_excp_0_pf_ld),
    .io_l2_tlb_req_resp_bits_excp_0_af_ld(io_l2_tlb_req_resp_bits_excp_0_af_ld),
    .io_l2_pmp_resp_ld(io_l2_pmp_resp_ld),
    .io_l2_pmp_resp_mmio(io_l2_pmp_resp_mmio),
    .io_l2_hint_valid(i_io_l2_hint_valid),
    .io_l2_hint_bits_sourceId(i_io_l2_hint_bits_sourceId),
    .io_l2_hint_bits_isKeyword(i_io_l2_hint_bits_isKeyword),
    .io_perfEvents_1_value(i_io_perfEvents_1_value),
    .io_perfEvents_2_value(i_io_perfEvents_2_value),
    .io_perfEvents_3_value(i_io_perfEvents_3_value),
    .io_perfEvents_4_value(i_io_perfEvents_4_value),
    .io_perfEvents_5_value(i_io_perfEvents_5_value),
    .io_perfEvents_6_value(i_io_perfEvents_6_value),
    .io_perfEvents_7_value(i_io_perfEvents_7_value),
    .io_perfEvents_8_value(i_io_perfEvents_8_value),
    .io_perfEvents_9_value(i_io_perfEvents_9_value),
    .io_perfEvents_10_value(i_io_perfEvents_10_value),
    .io_perfEvents_11_value(i_io_perfEvents_11_value),
    .io_perfEvents_12_value(i_io_perfEvents_12_value),
    .io_perfEvents_13_value(i_io_perfEvents_13_value),
    .io_perfEvents_14_value(i_io_perfEvents_14_value),
    .io_perfEvents_15_value(i_io_perfEvents_15_value),
    .io_perfEvents_16_value(i_io_perfEvents_16_value),
    .io_perfEvents_17_value(i_io_perfEvents_17_value),
    .io_perfEvents_18_value(i_io_perfEvents_18_value),
    .io_perfEvents_19_value(i_io_perfEvents_19_value),
    .io_perfEvents_20_value(i_io_perfEvents_20_value),
    .io_perfEvents_21_value(i_io_perfEvents_21_value),
    .io_perfEvents_22_value(i_io_perfEvents_22_value),
    .io_perfEvents_23_value(i_io_perfEvents_23_value),
    .io_perfEvents_24_value(i_io_perfEvents_24_value),
    .io_perfEvents_25_value(i_io_perfEvents_25_value),
    .io_perfEvents_26_value(i_io_perfEvents_26_value),
    .io_perfEvents_27_value(i_io_perfEvents_27_value),
    .io_perfEvents_28_value(i_io_perfEvents_28_value),
    .io_perfEvents_29_value(i_io_perfEvents_29_value),
    .io_perfEvents_30_value(i_io_perfEvents_30_value),
    .io_perfEvents_31_value(i_io_perfEvents_31_value),
    .io_perfEvents_32_value(i_io_perfEvents_32_value),
    .io_perfEvents_33_value(i_io_perfEvents_33_value),
    .io_perfEvents_34_value(i_io_perfEvents_34_value),
    .io_perfEvents_35_value(i_io_perfEvents_35_value),
    .io_perfEvents_36_value(i_io_perfEvents_36_value),
    .io_perfEvents_37_value(i_io_perfEvents_37_value),
    .io_perfEvents_38_value(i_io_perfEvents_38_value),
    .io_perfEvents_39_value(i_io_perfEvents_39_value),
    .io_perfEvents_40_value(i_io_perfEvents_40_value),
    .io_perfEvents_41_value(i_io_perfEvents_41_value),
    .io_perfEvents_42_value(i_io_perfEvents_42_value),
    .io_perfEvents_43_value(i_io_perfEvents_43_value),
    .io_perfEvents_44_value(i_io_perfEvents_44_value),
    .io_perfEvents_45_value(i_io_perfEvents_45_value),
    .io_perfEvents_46_value(i_io_perfEvents_46_value),
    .io_perfEvents_47_value(i_io_perfEvents_47_value),
    .io_perfEvents_48_value(i_io_perfEvents_48_value),
    .io_perfEvents_49_value(i_io_perfEvents_49_value),
    .io_perfEvents_50_value(i_io_perfEvents_50_value),
    .io_perfEvents_51_value(i_io_perfEvents_51_value),
    .io_perfEvents_52_value(i_io_perfEvents_52_value),
    .io_perfEvents_53_value(i_io_perfEvents_53_value),
    .io_perfEvents_54_value(i_io_perfEvents_54_value),
    .io_perfEvents_55_value(i_io_perfEvents_55_value),
    .io_perfEvents_56_value(i_io_perfEvents_56_value),
    .io_perfEvents_57_value(i_io_perfEvents_57_value),
    .io_perfEvents_58_value(i_io_perfEvents_58_value),
    .io_perfEvents_59_value(i_io_perfEvents_59_value),
    .io_perfEvents_60_value(i_io_perfEvents_60_value),
    .io_perfEvents_61_value(i_io_perfEvents_61_value),
    .io_perfEvents_62_value(i_io_perfEvents_62_value),
    .io_perfEvents_63_value(i_io_perfEvents_63_value),
    .io_perfEvents_64_value(i_io_perfEvents_64_value),
    .io_perfEvents_65_value(i_io_perfEvents_65_value),
    .io_perfEvents_66_value(i_io_perfEvents_66_value),
    .io_perfEvents_67_value(i_io_perfEvents_67_value),
    .io_perfEvents_68_value(i_io_perfEvents_68_value),
    .io_dft_ram_hold(io_dft_ram_hold),
    .io_dft_ram_bypass(io_dft_ram_bypass),
    .io_dft_ram_bp_clken(io_dft_ram_bp_clken),
    .io_dft_ram_aux_clk(io_dft_ram_aux_clk),
    .io_dft_ram_aux_ckbp(io_dft_ram_aux_ckbp),
    .io_dft_ram_mcp_hold(io_dft_ram_mcp_hold),
    .io_dft_cgen(io_dft_cgen)
  );

  // ---- 地址域：{tag 31 位, set 9 位, bank 2 位, offset 6 位}；tag 0..15、set 0..3（同 Slice tb）----
  function automatic logic [47:0] pick_addr(input int bank);
    return {31'($urandom_range(0, 15)), 9'($urandom_range(0, 3)), 2'(bank),
            ($urandom_range(0, 7) == 0) ? 6'($urandom) : 6'h0};
  endfunction
  function automatic logic [3:0] pick_a_opcode();
    case ($urandom_range(0, 9))
      0, 1: return 4'h4;  2: return 4'h5;  3, 4, 5: return 4'h6;  6, 7: return 4'h7;
      default: return 4'($urandom);
    endcase
  endfunction
  function automatic logic [3:0] pick_mmio_opcode();
    case ($urandom_range(0, 7))
      0, 1, 2: return 4'h4;  3, 4: return 4'h0;  5, 6: return 4'h1;  default: return 4'($urandom);
    endcase
  endfunction
  function automatic logic [4:0] pick_pf_source();
    case ($urandom_range(0, 7))
      0, 1: return 5'd10;  2, 3: return 5'd11;  4: return 5'd12;  5, 6: return 5'd14;  default: return 5'($urandom);
    endcase
  endfunction
  // RXRSP opcode：RetryAck 3 / Comp 4 / CompDBIDResp 5 / DBIDResp 6 / PCrdGrant 7 / ReadReceipt 8 / RespSepData B
  function automatic logic [4:0] pick_rsp_opcode();
    case ($urandom_range(0, 7))
      0: return 5'h3;  1: return 5'h4;  2: return 5'h5;  3: return 5'h6;
      4: return 5'h8;  5: return 5'hB;  6: return 5'h7;  default: return 5'($urandom);
    endcase
  endfunction

  // ---- RXRSP / RXDAT 的目标：slice k 的 MSHR（txnID = {0, k, mshrId}）或 MMIO 槽（{1, 槽号}）----
  //   kind 0 = RXDAT；1 = RetryAck；2 = 其余 RXRSP（规则同 verif/ut/Slice/gen_tb.py 的 pick_target）
  //   MMIO 槽：响应在路上（LinkMonitor + rx*Pipe 约 3 拍）时槽仍显示在等，此时再给同一个槽发任何响应，到达时槽
  //   可能已换了状态，RXDAT 就卡在 rxdatPipe 出口（ready 只看 txnID 对上的槽）——整个 RXDAT 通道从此停摆。
  //   所以给过响应（RSP 或 DAT）的槽 16 拍内不再选。
  longint mmio_sent [16];
  initial foreach (mmio_sent[k]) mmio_sent[k] = -100;
  function automatic int pick_target(input int kind);
    int c[$];
    if (u_g.inner_l2cache.slices_0.mshrCtl.mshrs_0.req_valid && !u_g.inner_l2cache.slices_0.mshrCtl.mshrs_0.gotRetryAck && (
          kind == 0 ? !u_g.inner_l2cache.slices_0.mshrCtl.mshrs_0.state_w_grantlast :
          kind == 1 ? (u_g.inner_l2cache.slices_0.mshrCtl.mshrs_0.state_s_acquire && !u_g.inner_l2cache.slices_0.mshrCtl.mshrs_0.state_w_grantfirst && !u_g.inner_l2cache.slices_0.mshrCtl.mshrs_0.state_w_grant ||
                       u_g.inner_l2cache.slices_0.mshrCtl.mshrs_0.state_s_release && !u_g.inner_l2cache.slices_0.mshrCtl.mshrs_0.state_w_releaseack) :
                      (!u_g.inner_l2cache.slices_0.mshrCtl.mshrs_0.state_w_grant || !u_g.inner_l2cache.slices_0.mshrCtl.mshrs_0.state_w_releaseack))) c.push_back(0);
    if (u_g.inner_l2cache.slices_0.mshrCtl.mshrs_1.req_valid && !u_g.inner_l2cache.slices_0.mshrCtl.mshrs_1.gotRetryAck && (
          kind == 0 ? !u_g.inner_l2cache.slices_0.mshrCtl.mshrs_1.state_w_grantlast :
          kind == 1 ? (u_g.inner_l2cache.slices_0.mshrCtl.mshrs_1.state_s_acquire && !u_g.inner_l2cache.slices_0.mshrCtl.mshrs_1.state_w_grantfirst && !u_g.inner_l2cache.slices_0.mshrCtl.mshrs_1.state_w_grant ||
                       u_g.inner_l2cache.slices_0.mshrCtl.mshrs_1.state_s_release && !u_g.inner_l2cache.slices_0.mshrCtl.mshrs_1.state_w_releaseack) :
                      (!u_g.inner_l2cache.slices_0.mshrCtl.mshrs_1.state_w_grant || !u_g.inner_l2cache.slices_0.mshrCtl.mshrs_1.state_w_releaseack))) c.push_back(1);
    if (u_g.inner_l2cache.slices_0.mshrCtl.mshrs_2.req_valid && !u_g.inner_l2cache.slices_0.mshrCtl.mshrs_2.gotRetryAck && (
          kind == 0 ? !u_g.inner_l2cache.slices_0.mshrCtl.mshrs_2.state_w_grantlast :
          kind == 1 ? (u_g.inner_l2cache.slices_0.mshrCtl.mshrs_2.state_s_acquire && !u_g.inner_l2cache.slices_0.mshrCtl.mshrs_2.state_w_grantfirst && !u_g.inner_l2cache.slices_0.mshrCtl.mshrs_2.state_w_grant ||
                       u_g.inner_l2cache.slices_0.mshrCtl.mshrs_2.state_s_release && !u_g.inner_l2cache.slices_0.mshrCtl.mshrs_2.state_w_releaseack) :
                      (!u_g.inner_l2cache.slices_0.mshrCtl.mshrs_2.state_w_grant || !u_g.inner_l2cache.slices_0.mshrCtl.mshrs_2.state_w_releaseack))) c.push_back(2);
    if (u_g.inner_l2cache.slices_0.mshrCtl.mshrs_3.req_valid && !u_g.inner_l2cache.slices_0.mshrCtl.mshrs_3.gotRetryAck && (
          kind == 0 ? !u_g.inner_l2cache.slices_0.mshrCtl.mshrs_3.state_w_grantlast :
          kind == 1 ? (u_g.inner_l2cache.slices_0.mshrCtl.mshrs_3.state_s_acquire && !u_g.inner_l2cache.slices_0.mshrCtl.mshrs_3.state_w_grantfirst && !u_g.inner_l2cache.slices_0.mshrCtl.mshrs_3.state_w_grant ||
                       u_g.inner_l2cache.slices_0.mshrCtl.mshrs_3.state_s_release && !u_g.inner_l2cache.slices_0.mshrCtl.mshrs_3.state_w_releaseack) :
                      (!u_g.inner_l2cache.slices_0.mshrCtl.mshrs_3.state_w_grant || !u_g.inner_l2cache.slices_0.mshrCtl.mshrs_3.state_w_releaseack))) c.push_back(3);
    if (u_g.inner_l2cache.slices_0.mshrCtl.mshrs_4.req_valid && !u_g.inner_l2cache.slices_0.mshrCtl.mshrs_4.gotRetryAck && (
          kind == 0 ? !u_g.inner_l2cache.slices_0.mshrCtl.mshrs_4.state_w_grantlast :
          kind == 1 ? (u_g.inner_l2cache.slices_0.mshrCtl.mshrs_4.state_s_acquire && !u_g.inner_l2cache.slices_0.mshrCtl.mshrs_4.state_w_grantfirst && !u_g.inner_l2cache.slices_0.mshrCtl.mshrs_4.state_w_grant ||
                       u_g.inner_l2cache.slices_0.mshrCtl.mshrs_4.state_s_release && !u_g.inner_l2cache.slices_0.mshrCtl.mshrs_4.state_w_releaseack) :
                      (!u_g.inner_l2cache.slices_0.mshrCtl.mshrs_4.state_w_grant || !u_g.inner_l2cache.slices_0.mshrCtl.mshrs_4.state_w_releaseack))) c.push_back(4);
    if (u_g.inner_l2cache.slices_0.mshrCtl.mshrs_5.req_valid && !u_g.inner_l2cache.slices_0.mshrCtl.mshrs_5.gotRetryAck && (
          kind == 0 ? !u_g.inner_l2cache.slices_0.mshrCtl.mshrs_5.state_w_grantlast :
          kind == 1 ? (u_g.inner_l2cache.slices_0.mshrCtl.mshrs_5.state_s_acquire && !u_g.inner_l2cache.slices_0.mshrCtl.mshrs_5.state_w_grantfirst && !u_g.inner_l2cache.slices_0.mshrCtl.mshrs_5.state_w_grant ||
                       u_g.inner_l2cache.slices_0.mshrCtl.mshrs_5.state_s_release && !u_g.inner_l2cache.slices_0.mshrCtl.mshrs_5.state_w_releaseack) :
                      (!u_g.inner_l2cache.slices_0.mshrCtl.mshrs_5.state_w_grant || !u_g.inner_l2cache.slices_0.mshrCtl.mshrs_5.state_w_releaseack))) c.push_back(5);
    if (u_g.inner_l2cache.slices_0.mshrCtl.mshrs_6.req_valid && !u_g.inner_l2cache.slices_0.mshrCtl.mshrs_6.gotRetryAck && (
          kind == 0 ? !u_g.inner_l2cache.slices_0.mshrCtl.mshrs_6.state_w_grantlast :
          kind == 1 ? (u_g.inner_l2cache.slices_0.mshrCtl.mshrs_6.state_s_acquire && !u_g.inner_l2cache.slices_0.mshrCtl.mshrs_6.state_w_grantfirst && !u_g.inner_l2cache.slices_0.mshrCtl.mshrs_6.state_w_grant ||
                       u_g.inner_l2cache.slices_0.mshrCtl.mshrs_6.state_s_release && !u_g.inner_l2cache.slices_0.mshrCtl.mshrs_6.state_w_releaseack) :
                      (!u_g.inner_l2cache.slices_0.mshrCtl.mshrs_6.state_w_grant || !u_g.inner_l2cache.slices_0.mshrCtl.mshrs_6.state_w_releaseack))) c.push_back(6);
    if (u_g.inner_l2cache.slices_0.mshrCtl.mshrs_7.req_valid && !u_g.inner_l2cache.slices_0.mshrCtl.mshrs_7.gotRetryAck && (
          kind == 0 ? !u_g.inner_l2cache.slices_0.mshrCtl.mshrs_7.state_w_grantlast :
          kind == 1 ? (u_g.inner_l2cache.slices_0.mshrCtl.mshrs_7.state_s_acquire && !u_g.inner_l2cache.slices_0.mshrCtl.mshrs_7.state_w_grantfirst && !u_g.inner_l2cache.slices_0.mshrCtl.mshrs_7.state_w_grant ||
                       u_g.inner_l2cache.slices_0.mshrCtl.mshrs_7.state_s_release && !u_g.inner_l2cache.slices_0.mshrCtl.mshrs_7.state_w_releaseack) :
                      (!u_g.inner_l2cache.slices_0.mshrCtl.mshrs_7.state_w_grant || !u_g.inner_l2cache.slices_0.mshrCtl.mshrs_7.state_w_releaseack))) c.push_back(7);
    if (u_g.inner_l2cache.slices_0.mshrCtl.mshrs_8.req_valid && !u_g.inner_l2cache.slices_0.mshrCtl.mshrs_8.gotRetryAck && (
          kind == 0 ? !u_g.inner_l2cache.slices_0.mshrCtl.mshrs_8.state_w_grantlast :
          kind == 1 ? (u_g.inner_l2cache.slices_0.mshrCtl.mshrs_8.state_s_acquire && !u_g.inner_l2cache.slices_0.mshrCtl.mshrs_8.state_w_grantfirst && !u_g.inner_l2cache.slices_0.mshrCtl.mshrs_8.state_w_grant ||
                       u_g.inner_l2cache.slices_0.mshrCtl.mshrs_8.state_s_release && !u_g.inner_l2cache.slices_0.mshrCtl.mshrs_8.state_w_releaseack) :
                      (!u_g.inner_l2cache.slices_0.mshrCtl.mshrs_8.state_w_grant || !u_g.inner_l2cache.slices_0.mshrCtl.mshrs_8.state_w_releaseack))) c.push_back(8);
    if (u_g.inner_l2cache.slices_0.mshrCtl.mshrs_9.req_valid && !u_g.inner_l2cache.slices_0.mshrCtl.mshrs_9.gotRetryAck && (
          kind == 0 ? !u_g.inner_l2cache.slices_0.mshrCtl.mshrs_9.state_w_grantlast :
          kind == 1 ? (u_g.inner_l2cache.slices_0.mshrCtl.mshrs_9.state_s_acquire && !u_g.inner_l2cache.slices_0.mshrCtl.mshrs_9.state_w_grantfirst && !u_g.inner_l2cache.slices_0.mshrCtl.mshrs_9.state_w_grant ||
                       u_g.inner_l2cache.slices_0.mshrCtl.mshrs_9.state_s_release && !u_g.inner_l2cache.slices_0.mshrCtl.mshrs_9.state_w_releaseack) :
                      (!u_g.inner_l2cache.slices_0.mshrCtl.mshrs_9.state_w_grant || !u_g.inner_l2cache.slices_0.mshrCtl.mshrs_9.state_w_releaseack))) c.push_back(9);
    if (u_g.inner_l2cache.slices_0.mshrCtl.mshrs_10.req_valid && !u_g.inner_l2cache.slices_0.mshrCtl.mshrs_10.gotRetryAck && (
          kind == 0 ? !u_g.inner_l2cache.slices_0.mshrCtl.mshrs_10.state_w_grantlast :
          kind == 1 ? (u_g.inner_l2cache.slices_0.mshrCtl.mshrs_10.state_s_acquire && !u_g.inner_l2cache.slices_0.mshrCtl.mshrs_10.state_w_grantfirst && !u_g.inner_l2cache.slices_0.mshrCtl.mshrs_10.state_w_grant ||
                       u_g.inner_l2cache.slices_0.mshrCtl.mshrs_10.state_s_release && !u_g.inner_l2cache.slices_0.mshrCtl.mshrs_10.state_w_releaseack) :
                      (!u_g.inner_l2cache.slices_0.mshrCtl.mshrs_10.state_w_grant || !u_g.inner_l2cache.slices_0.mshrCtl.mshrs_10.state_w_releaseack))) c.push_back(10);
    if (u_g.inner_l2cache.slices_0.mshrCtl.mshrs_11.req_valid && !u_g.inner_l2cache.slices_0.mshrCtl.mshrs_11.gotRetryAck && (
          kind == 0 ? !u_g.inner_l2cache.slices_0.mshrCtl.mshrs_11.state_w_grantlast :
          kind == 1 ? (u_g.inner_l2cache.slices_0.mshrCtl.mshrs_11.state_s_acquire && !u_g.inner_l2cache.slices_0.mshrCtl.mshrs_11.state_w_grantfirst && !u_g.inner_l2cache.slices_0.mshrCtl.mshrs_11.state_w_grant ||
                       u_g.inner_l2cache.slices_0.mshrCtl.mshrs_11.state_s_release && !u_g.inner_l2cache.slices_0.mshrCtl.mshrs_11.state_w_releaseack) :
                      (!u_g.inner_l2cache.slices_0.mshrCtl.mshrs_11.state_w_grant || !u_g.inner_l2cache.slices_0.mshrCtl.mshrs_11.state_w_releaseack))) c.push_back(11);
    if (u_g.inner_l2cache.slices_0.mshrCtl.mshrs_12.req_valid && !u_g.inner_l2cache.slices_0.mshrCtl.mshrs_12.gotRetryAck && (
          kind == 0 ? !u_g.inner_l2cache.slices_0.mshrCtl.mshrs_12.state_w_grantlast :
          kind == 1 ? (u_g.inner_l2cache.slices_0.mshrCtl.mshrs_12.state_s_acquire && !u_g.inner_l2cache.slices_0.mshrCtl.mshrs_12.state_w_grantfirst && !u_g.inner_l2cache.slices_0.mshrCtl.mshrs_12.state_w_grant ||
                       u_g.inner_l2cache.slices_0.mshrCtl.mshrs_12.state_s_release && !u_g.inner_l2cache.slices_0.mshrCtl.mshrs_12.state_w_releaseack) :
                      (!u_g.inner_l2cache.slices_0.mshrCtl.mshrs_12.state_w_grant || !u_g.inner_l2cache.slices_0.mshrCtl.mshrs_12.state_w_releaseack))) c.push_back(12);
    if (u_g.inner_l2cache.slices_0.mshrCtl.mshrs_13.req_valid && !u_g.inner_l2cache.slices_0.mshrCtl.mshrs_13.gotRetryAck && (
          kind == 0 ? !u_g.inner_l2cache.slices_0.mshrCtl.mshrs_13.state_w_grantlast :
          kind == 1 ? (u_g.inner_l2cache.slices_0.mshrCtl.mshrs_13.state_s_acquire && !u_g.inner_l2cache.slices_0.mshrCtl.mshrs_13.state_w_grantfirst && !u_g.inner_l2cache.slices_0.mshrCtl.mshrs_13.state_w_grant ||
                       u_g.inner_l2cache.slices_0.mshrCtl.mshrs_13.state_s_release && !u_g.inner_l2cache.slices_0.mshrCtl.mshrs_13.state_w_releaseack) :
                      (!u_g.inner_l2cache.slices_0.mshrCtl.mshrs_13.state_w_grant || !u_g.inner_l2cache.slices_0.mshrCtl.mshrs_13.state_w_releaseack))) c.push_back(13);
    if (u_g.inner_l2cache.slices_0.mshrCtl.mshrs_14.req_valid && !u_g.inner_l2cache.slices_0.mshrCtl.mshrs_14.gotRetryAck && (
          kind == 0 ? !u_g.inner_l2cache.slices_0.mshrCtl.mshrs_14.state_w_grantlast :
          kind == 1 ? (u_g.inner_l2cache.slices_0.mshrCtl.mshrs_14.state_s_acquire && !u_g.inner_l2cache.slices_0.mshrCtl.mshrs_14.state_w_grantfirst && !u_g.inner_l2cache.slices_0.mshrCtl.mshrs_14.state_w_grant ||
                       u_g.inner_l2cache.slices_0.mshrCtl.mshrs_14.state_s_release && !u_g.inner_l2cache.slices_0.mshrCtl.mshrs_14.state_w_releaseack) :
                      (!u_g.inner_l2cache.slices_0.mshrCtl.mshrs_14.state_w_grant || !u_g.inner_l2cache.slices_0.mshrCtl.mshrs_14.state_w_releaseack))) c.push_back(14);
    if (u_g.inner_l2cache.slices_0.mshrCtl.mshrs_15.req_valid && !u_g.inner_l2cache.slices_0.mshrCtl.mshrs_15.gotRetryAck && (
          kind == 0 ? !u_g.inner_l2cache.slices_0.mshrCtl.mshrs_15.state_w_grantlast :
          kind == 1 ? (u_g.inner_l2cache.slices_0.mshrCtl.mshrs_15.state_s_acquire && !u_g.inner_l2cache.slices_0.mshrCtl.mshrs_15.state_w_grantfirst && !u_g.inner_l2cache.slices_0.mshrCtl.mshrs_15.state_w_grant ||
                       u_g.inner_l2cache.slices_0.mshrCtl.mshrs_15.state_s_release && !u_g.inner_l2cache.slices_0.mshrCtl.mshrs_15.state_w_releaseack) :
                      (!u_g.inner_l2cache.slices_0.mshrCtl.mshrs_15.state_w_grant || !u_g.inner_l2cache.slices_0.mshrCtl.mshrs_15.state_w_releaseack))) c.push_back(15);
    if (u_g.inner_l2cache.slices_1.mshrCtl.mshrs_0.req_valid && !u_g.inner_l2cache.slices_1.mshrCtl.mshrs_0.gotRetryAck && (
          kind == 0 ? !u_g.inner_l2cache.slices_1.mshrCtl.mshrs_0.state_w_grantlast :
          kind == 1 ? (u_g.inner_l2cache.slices_1.mshrCtl.mshrs_0.state_s_acquire && !u_g.inner_l2cache.slices_1.mshrCtl.mshrs_0.state_w_grantfirst && !u_g.inner_l2cache.slices_1.mshrCtl.mshrs_0.state_w_grant ||
                       u_g.inner_l2cache.slices_1.mshrCtl.mshrs_0.state_s_release && !u_g.inner_l2cache.slices_1.mshrCtl.mshrs_0.state_w_releaseack) :
                      (!u_g.inner_l2cache.slices_1.mshrCtl.mshrs_0.state_w_grant || !u_g.inner_l2cache.slices_1.mshrCtl.mshrs_0.state_w_releaseack))) c.push_back(512);
    if (u_g.inner_l2cache.slices_1.mshrCtl.mshrs_1.req_valid && !u_g.inner_l2cache.slices_1.mshrCtl.mshrs_1.gotRetryAck && (
          kind == 0 ? !u_g.inner_l2cache.slices_1.mshrCtl.mshrs_1.state_w_grantlast :
          kind == 1 ? (u_g.inner_l2cache.slices_1.mshrCtl.mshrs_1.state_s_acquire && !u_g.inner_l2cache.slices_1.mshrCtl.mshrs_1.state_w_grantfirst && !u_g.inner_l2cache.slices_1.mshrCtl.mshrs_1.state_w_grant ||
                       u_g.inner_l2cache.slices_1.mshrCtl.mshrs_1.state_s_release && !u_g.inner_l2cache.slices_1.mshrCtl.mshrs_1.state_w_releaseack) :
                      (!u_g.inner_l2cache.slices_1.mshrCtl.mshrs_1.state_w_grant || !u_g.inner_l2cache.slices_1.mshrCtl.mshrs_1.state_w_releaseack))) c.push_back(513);
    if (u_g.inner_l2cache.slices_1.mshrCtl.mshrs_2.req_valid && !u_g.inner_l2cache.slices_1.mshrCtl.mshrs_2.gotRetryAck && (
          kind == 0 ? !u_g.inner_l2cache.slices_1.mshrCtl.mshrs_2.state_w_grantlast :
          kind == 1 ? (u_g.inner_l2cache.slices_1.mshrCtl.mshrs_2.state_s_acquire && !u_g.inner_l2cache.slices_1.mshrCtl.mshrs_2.state_w_grantfirst && !u_g.inner_l2cache.slices_1.mshrCtl.mshrs_2.state_w_grant ||
                       u_g.inner_l2cache.slices_1.mshrCtl.mshrs_2.state_s_release && !u_g.inner_l2cache.slices_1.mshrCtl.mshrs_2.state_w_releaseack) :
                      (!u_g.inner_l2cache.slices_1.mshrCtl.mshrs_2.state_w_grant || !u_g.inner_l2cache.slices_1.mshrCtl.mshrs_2.state_w_releaseack))) c.push_back(514);
    if (u_g.inner_l2cache.slices_1.mshrCtl.mshrs_3.req_valid && !u_g.inner_l2cache.slices_1.mshrCtl.mshrs_3.gotRetryAck && (
          kind == 0 ? !u_g.inner_l2cache.slices_1.mshrCtl.mshrs_3.state_w_grantlast :
          kind == 1 ? (u_g.inner_l2cache.slices_1.mshrCtl.mshrs_3.state_s_acquire && !u_g.inner_l2cache.slices_1.mshrCtl.mshrs_3.state_w_grantfirst && !u_g.inner_l2cache.slices_1.mshrCtl.mshrs_3.state_w_grant ||
                       u_g.inner_l2cache.slices_1.mshrCtl.mshrs_3.state_s_release && !u_g.inner_l2cache.slices_1.mshrCtl.mshrs_3.state_w_releaseack) :
                      (!u_g.inner_l2cache.slices_1.mshrCtl.mshrs_3.state_w_grant || !u_g.inner_l2cache.slices_1.mshrCtl.mshrs_3.state_w_releaseack))) c.push_back(515);
    if (u_g.inner_l2cache.slices_1.mshrCtl.mshrs_4.req_valid && !u_g.inner_l2cache.slices_1.mshrCtl.mshrs_4.gotRetryAck && (
          kind == 0 ? !u_g.inner_l2cache.slices_1.mshrCtl.mshrs_4.state_w_grantlast :
          kind == 1 ? (u_g.inner_l2cache.slices_1.mshrCtl.mshrs_4.state_s_acquire && !u_g.inner_l2cache.slices_1.mshrCtl.mshrs_4.state_w_grantfirst && !u_g.inner_l2cache.slices_1.mshrCtl.mshrs_4.state_w_grant ||
                       u_g.inner_l2cache.slices_1.mshrCtl.mshrs_4.state_s_release && !u_g.inner_l2cache.slices_1.mshrCtl.mshrs_4.state_w_releaseack) :
                      (!u_g.inner_l2cache.slices_1.mshrCtl.mshrs_4.state_w_grant || !u_g.inner_l2cache.slices_1.mshrCtl.mshrs_4.state_w_releaseack))) c.push_back(516);
    if (u_g.inner_l2cache.slices_1.mshrCtl.mshrs_5.req_valid && !u_g.inner_l2cache.slices_1.mshrCtl.mshrs_5.gotRetryAck && (
          kind == 0 ? !u_g.inner_l2cache.slices_1.mshrCtl.mshrs_5.state_w_grantlast :
          kind == 1 ? (u_g.inner_l2cache.slices_1.mshrCtl.mshrs_5.state_s_acquire && !u_g.inner_l2cache.slices_1.mshrCtl.mshrs_5.state_w_grantfirst && !u_g.inner_l2cache.slices_1.mshrCtl.mshrs_5.state_w_grant ||
                       u_g.inner_l2cache.slices_1.mshrCtl.mshrs_5.state_s_release && !u_g.inner_l2cache.slices_1.mshrCtl.mshrs_5.state_w_releaseack) :
                      (!u_g.inner_l2cache.slices_1.mshrCtl.mshrs_5.state_w_grant || !u_g.inner_l2cache.slices_1.mshrCtl.mshrs_5.state_w_releaseack))) c.push_back(517);
    if (u_g.inner_l2cache.slices_1.mshrCtl.mshrs_6.req_valid && !u_g.inner_l2cache.slices_1.mshrCtl.mshrs_6.gotRetryAck && (
          kind == 0 ? !u_g.inner_l2cache.slices_1.mshrCtl.mshrs_6.state_w_grantlast :
          kind == 1 ? (u_g.inner_l2cache.slices_1.mshrCtl.mshrs_6.state_s_acquire && !u_g.inner_l2cache.slices_1.mshrCtl.mshrs_6.state_w_grantfirst && !u_g.inner_l2cache.slices_1.mshrCtl.mshrs_6.state_w_grant ||
                       u_g.inner_l2cache.slices_1.mshrCtl.mshrs_6.state_s_release && !u_g.inner_l2cache.slices_1.mshrCtl.mshrs_6.state_w_releaseack) :
                      (!u_g.inner_l2cache.slices_1.mshrCtl.mshrs_6.state_w_grant || !u_g.inner_l2cache.slices_1.mshrCtl.mshrs_6.state_w_releaseack))) c.push_back(518);
    if (u_g.inner_l2cache.slices_1.mshrCtl.mshrs_7.req_valid && !u_g.inner_l2cache.slices_1.mshrCtl.mshrs_7.gotRetryAck && (
          kind == 0 ? !u_g.inner_l2cache.slices_1.mshrCtl.mshrs_7.state_w_grantlast :
          kind == 1 ? (u_g.inner_l2cache.slices_1.mshrCtl.mshrs_7.state_s_acquire && !u_g.inner_l2cache.slices_1.mshrCtl.mshrs_7.state_w_grantfirst && !u_g.inner_l2cache.slices_1.mshrCtl.mshrs_7.state_w_grant ||
                       u_g.inner_l2cache.slices_1.mshrCtl.mshrs_7.state_s_release && !u_g.inner_l2cache.slices_1.mshrCtl.mshrs_7.state_w_releaseack) :
                      (!u_g.inner_l2cache.slices_1.mshrCtl.mshrs_7.state_w_grant || !u_g.inner_l2cache.slices_1.mshrCtl.mshrs_7.state_w_releaseack))) c.push_back(519);
    if (u_g.inner_l2cache.slices_1.mshrCtl.mshrs_8.req_valid && !u_g.inner_l2cache.slices_1.mshrCtl.mshrs_8.gotRetryAck && (
          kind == 0 ? !u_g.inner_l2cache.slices_1.mshrCtl.mshrs_8.state_w_grantlast :
          kind == 1 ? (u_g.inner_l2cache.slices_1.mshrCtl.mshrs_8.state_s_acquire && !u_g.inner_l2cache.slices_1.mshrCtl.mshrs_8.state_w_grantfirst && !u_g.inner_l2cache.slices_1.mshrCtl.mshrs_8.state_w_grant ||
                       u_g.inner_l2cache.slices_1.mshrCtl.mshrs_8.state_s_release && !u_g.inner_l2cache.slices_1.mshrCtl.mshrs_8.state_w_releaseack) :
                      (!u_g.inner_l2cache.slices_1.mshrCtl.mshrs_8.state_w_grant || !u_g.inner_l2cache.slices_1.mshrCtl.mshrs_8.state_w_releaseack))) c.push_back(520);
    if (u_g.inner_l2cache.slices_1.mshrCtl.mshrs_9.req_valid && !u_g.inner_l2cache.slices_1.mshrCtl.mshrs_9.gotRetryAck && (
          kind == 0 ? !u_g.inner_l2cache.slices_1.mshrCtl.mshrs_9.state_w_grantlast :
          kind == 1 ? (u_g.inner_l2cache.slices_1.mshrCtl.mshrs_9.state_s_acquire && !u_g.inner_l2cache.slices_1.mshrCtl.mshrs_9.state_w_grantfirst && !u_g.inner_l2cache.slices_1.mshrCtl.mshrs_9.state_w_grant ||
                       u_g.inner_l2cache.slices_1.mshrCtl.mshrs_9.state_s_release && !u_g.inner_l2cache.slices_1.mshrCtl.mshrs_9.state_w_releaseack) :
                      (!u_g.inner_l2cache.slices_1.mshrCtl.mshrs_9.state_w_grant || !u_g.inner_l2cache.slices_1.mshrCtl.mshrs_9.state_w_releaseack))) c.push_back(521);
    if (u_g.inner_l2cache.slices_1.mshrCtl.mshrs_10.req_valid && !u_g.inner_l2cache.slices_1.mshrCtl.mshrs_10.gotRetryAck && (
          kind == 0 ? !u_g.inner_l2cache.slices_1.mshrCtl.mshrs_10.state_w_grantlast :
          kind == 1 ? (u_g.inner_l2cache.slices_1.mshrCtl.mshrs_10.state_s_acquire && !u_g.inner_l2cache.slices_1.mshrCtl.mshrs_10.state_w_grantfirst && !u_g.inner_l2cache.slices_1.mshrCtl.mshrs_10.state_w_grant ||
                       u_g.inner_l2cache.slices_1.mshrCtl.mshrs_10.state_s_release && !u_g.inner_l2cache.slices_1.mshrCtl.mshrs_10.state_w_releaseack) :
                      (!u_g.inner_l2cache.slices_1.mshrCtl.mshrs_10.state_w_grant || !u_g.inner_l2cache.slices_1.mshrCtl.mshrs_10.state_w_releaseack))) c.push_back(522);
    if (u_g.inner_l2cache.slices_1.mshrCtl.mshrs_11.req_valid && !u_g.inner_l2cache.slices_1.mshrCtl.mshrs_11.gotRetryAck && (
          kind == 0 ? !u_g.inner_l2cache.slices_1.mshrCtl.mshrs_11.state_w_grantlast :
          kind == 1 ? (u_g.inner_l2cache.slices_1.mshrCtl.mshrs_11.state_s_acquire && !u_g.inner_l2cache.slices_1.mshrCtl.mshrs_11.state_w_grantfirst && !u_g.inner_l2cache.slices_1.mshrCtl.mshrs_11.state_w_grant ||
                       u_g.inner_l2cache.slices_1.mshrCtl.mshrs_11.state_s_release && !u_g.inner_l2cache.slices_1.mshrCtl.mshrs_11.state_w_releaseack) :
                      (!u_g.inner_l2cache.slices_1.mshrCtl.mshrs_11.state_w_grant || !u_g.inner_l2cache.slices_1.mshrCtl.mshrs_11.state_w_releaseack))) c.push_back(523);
    if (u_g.inner_l2cache.slices_1.mshrCtl.mshrs_12.req_valid && !u_g.inner_l2cache.slices_1.mshrCtl.mshrs_12.gotRetryAck && (
          kind == 0 ? !u_g.inner_l2cache.slices_1.mshrCtl.mshrs_12.state_w_grantlast :
          kind == 1 ? (u_g.inner_l2cache.slices_1.mshrCtl.mshrs_12.state_s_acquire && !u_g.inner_l2cache.slices_1.mshrCtl.mshrs_12.state_w_grantfirst && !u_g.inner_l2cache.slices_1.mshrCtl.mshrs_12.state_w_grant ||
                       u_g.inner_l2cache.slices_1.mshrCtl.mshrs_12.state_s_release && !u_g.inner_l2cache.slices_1.mshrCtl.mshrs_12.state_w_releaseack) :
                      (!u_g.inner_l2cache.slices_1.mshrCtl.mshrs_12.state_w_grant || !u_g.inner_l2cache.slices_1.mshrCtl.mshrs_12.state_w_releaseack))) c.push_back(524);
    if (u_g.inner_l2cache.slices_1.mshrCtl.mshrs_13.req_valid && !u_g.inner_l2cache.slices_1.mshrCtl.mshrs_13.gotRetryAck && (
          kind == 0 ? !u_g.inner_l2cache.slices_1.mshrCtl.mshrs_13.state_w_grantlast :
          kind == 1 ? (u_g.inner_l2cache.slices_1.mshrCtl.mshrs_13.state_s_acquire && !u_g.inner_l2cache.slices_1.mshrCtl.mshrs_13.state_w_grantfirst && !u_g.inner_l2cache.slices_1.mshrCtl.mshrs_13.state_w_grant ||
                       u_g.inner_l2cache.slices_1.mshrCtl.mshrs_13.state_s_release && !u_g.inner_l2cache.slices_1.mshrCtl.mshrs_13.state_w_releaseack) :
                      (!u_g.inner_l2cache.slices_1.mshrCtl.mshrs_13.state_w_grant || !u_g.inner_l2cache.slices_1.mshrCtl.mshrs_13.state_w_releaseack))) c.push_back(525);
    if (u_g.inner_l2cache.slices_1.mshrCtl.mshrs_14.req_valid && !u_g.inner_l2cache.slices_1.mshrCtl.mshrs_14.gotRetryAck && (
          kind == 0 ? !u_g.inner_l2cache.slices_1.mshrCtl.mshrs_14.state_w_grantlast :
          kind == 1 ? (u_g.inner_l2cache.slices_1.mshrCtl.mshrs_14.state_s_acquire && !u_g.inner_l2cache.slices_1.mshrCtl.mshrs_14.state_w_grantfirst && !u_g.inner_l2cache.slices_1.mshrCtl.mshrs_14.state_w_grant ||
                       u_g.inner_l2cache.slices_1.mshrCtl.mshrs_14.state_s_release && !u_g.inner_l2cache.slices_1.mshrCtl.mshrs_14.state_w_releaseack) :
                      (!u_g.inner_l2cache.slices_1.mshrCtl.mshrs_14.state_w_grant || !u_g.inner_l2cache.slices_1.mshrCtl.mshrs_14.state_w_releaseack))) c.push_back(526);
    if (u_g.inner_l2cache.slices_1.mshrCtl.mshrs_15.req_valid && !u_g.inner_l2cache.slices_1.mshrCtl.mshrs_15.gotRetryAck && (
          kind == 0 ? !u_g.inner_l2cache.slices_1.mshrCtl.mshrs_15.state_w_grantlast :
          kind == 1 ? (u_g.inner_l2cache.slices_1.mshrCtl.mshrs_15.state_s_acquire && !u_g.inner_l2cache.slices_1.mshrCtl.mshrs_15.state_w_grantfirst && !u_g.inner_l2cache.slices_1.mshrCtl.mshrs_15.state_w_grant ||
                       u_g.inner_l2cache.slices_1.mshrCtl.mshrs_15.state_s_release && !u_g.inner_l2cache.slices_1.mshrCtl.mshrs_15.state_w_releaseack) :
                      (!u_g.inner_l2cache.slices_1.mshrCtl.mshrs_15.state_w_grant || !u_g.inner_l2cache.slices_1.mshrCtl.mshrs_15.state_w_releaseack))) c.push_back(527);
    if (u_g.inner_l2cache.slices_2.mshrCtl.mshrs_0.req_valid && !u_g.inner_l2cache.slices_2.mshrCtl.mshrs_0.gotRetryAck && (
          kind == 0 ? !u_g.inner_l2cache.slices_2.mshrCtl.mshrs_0.state_w_grantlast :
          kind == 1 ? (u_g.inner_l2cache.slices_2.mshrCtl.mshrs_0.state_s_acquire && !u_g.inner_l2cache.slices_2.mshrCtl.mshrs_0.state_w_grantfirst && !u_g.inner_l2cache.slices_2.mshrCtl.mshrs_0.state_w_grant ||
                       u_g.inner_l2cache.slices_2.mshrCtl.mshrs_0.state_s_release && !u_g.inner_l2cache.slices_2.mshrCtl.mshrs_0.state_w_releaseack) :
                      (!u_g.inner_l2cache.slices_2.mshrCtl.mshrs_0.state_w_grant || !u_g.inner_l2cache.slices_2.mshrCtl.mshrs_0.state_w_releaseack))) c.push_back(1024);
    if (u_g.inner_l2cache.slices_2.mshrCtl.mshrs_1.req_valid && !u_g.inner_l2cache.slices_2.mshrCtl.mshrs_1.gotRetryAck && (
          kind == 0 ? !u_g.inner_l2cache.slices_2.mshrCtl.mshrs_1.state_w_grantlast :
          kind == 1 ? (u_g.inner_l2cache.slices_2.mshrCtl.mshrs_1.state_s_acquire && !u_g.inner_l2cache.slices_2.mshrCtl.mshrs_1.state_w_grantfirst && !u_g.inner_l2cache.slices_2.mshrCtl.mshrs_1.state_w_grant ||
                       u_g.inner_l2cache.slices_2.mshrCtl.mshrs_1.state_s_release && !u_g.inner_l2cache.slices_2.mshrCtl.mshrs_1.state_w_releaseack) :
                      (!u_g.inner_l2cache.slices_2.mshrCtl.mshrs_1.state_w_grant || !u_g.inner_l2cache.slices_2.mshrCtl.mshrs_1.state_w_releaseack))) c.push_back(1025);
    if (u_g.inner_l2cache.slices_2.mshrCtl.mshrs_2.req_valid && !u_g.inner_l2cache.slices_2.mshrCtl.mshrs_2.gotRetryAck && (
          kind == 0 ? !u_g.inner_l2cache.slices_2.mshrCtl.mshrs_2.state_w_grantlast :
          kind == 1 ? (u_g.inner_l2cache.slices_2.mshrCtl.mshrs_2.state_s_acquire && !u_g.inner_l2cache.slices_2.mshrCtl.mshrs_2.state_w_grantfirst && !u_g.inner_l2cache.slices_2.mshrCtl.mshrs_2.state_w_grant ||
                       u_g.inner_l2cache.slices_2.mshrCtl.mshrs_2.state_s_release && !u_g.inner_l2cache.slices_2.mshrCtl.mshrs_2.state_w_releaseack) :
                      (!u_g.inner_l2cache.slices_2.mshrCtl.mshrs_2.state_w_grant || !u_g.inner_l2cache.slices_2.mshrCtl.mshrs_2.state_w_releaseack))) c.push_back(1026);
    if (u_g.inner_l2cache.slices_2.mshrCtl.mshrs_3.req_valid && !u_g.inner_l2cache.slices_2.mshrCtl.mshrs_3.gotRetryAck && (
          kind == 0 ? !u_g.inner_l2cache.slices_2.mshrCtl.mshrs_3.state_w_grantlast :
          kind == 1 ? (u_g.inner_l2cache.slices_2.mshrCtl.mshrs_3.state_s_acquire && !u_g.inner_l2cache.slices_2.mshrCtl.mshrs_3.state_w_grantfirst && !u_g.inner_l2cache.slices_2.mshrCtl.mshrs_3.state_w_grant ||
                       u_g.inner_l2cache.slices_2.mshrCtl.mshrs_3.state_s_release && !u_g.inner_l2cache.slices_2.mshrCtl.mshrs_3.state_w_releaseack) :
                      (!u_g.inner_l2cache.slices_2.mshrCtl.mshrs_3.state_w_grant || !u_g.inner_l2cache.slices_2.mshrCtl.mshrs_3.state_w_releaseack))) c.push_back(1027);
    if (u_g.inner_l2cache.slices_2.mshrCtl.mshrs_4.req_valid && !u_g.inner_l2cache.slices_2.mshrCtl.mshrs_4.gotRetryAck && (
          kind == 0 ? !u_g.inner_l2cache.slices_2.mshrCtl.mshrs_4.state_w_grantlast :
          kind == 1 ? (u_g.inner_l2cache.slices_2.mshrCtl.mshrs_4.state_s_acquire && !u_g.inner_l2cache.slices_2.mshrCtl.mshrs_4.state_w_grantfirst && !u_g.inner_l2cache.slices_2.mshrCtl.mshrs_4.state_w_grant ||
                       u_g.inner_l2cache.slices_2.mshrCtl.mshrs_4.state_s_release && !u_g.inner_l2cache.slices_2.mshrCtl.mshrs_4.state_w_releaseack) :
                      (!u_g.inner_l2cache.slices_2.mshrCtl.mshrs_4.state_w_grant || !u_g.inner_l2cache.slices_2.mshrCtl.mshrs_4.state_w_releaseack))) c.push_back(1028);
    if (u_g.inner_l2cache.slices_2.mshrCtl.mshrs_5.req_valid && !u_g.inner_l2cache.slices_2.mshrCtl.mshrs_5.gotRetryAck && (
          kind == 0 ? !u_g.inner_l2cache.slices_2.mshrCtl.mshrs_5.state_w_grantlast :
          kind == 1 ? (u_g.inner_l2cache.slices_2.mshrCtl.mshrs_5.state_s_acquire && !u_g.inner_l2cache.slices_2.mshrCtl.mshrs_5.state_w_grantfirst && !u_g.inner_l2cache.slices_2.mshrCtl.mshrs_5.state_w_grant ||
                       u_g.inner_l2cache.slices_2.mshrCtl.mshrs_5.state_s_release && !u_g.inner_l2cache.slices_2.mshrCtl.mshrs_5.state_w_releaseack) :
                      (!u_g.inner_l2cache.slices_2.mshrCtl.mshrs_5.state_w_grant || !u_g.inner_l2cache.slices_2.mshrCtl.mshrs_5.state_w_releaseack))) c.push_back(1029);
    if (u_g.inner_l2cache.slices_2.mshrCtl.mshrs_6.req_valid && !u_g.inner_l2cache.slices_2.mshrCtl.mshrs_6.gotRetryAck && (
          kind == 0 ? !u_g.inner_l2cache.slices_2.mshrCtl.mshrs_6.state_w_grantlast :
          kind == 1 ? (u_g.inner_l2cache.slices_2.mshrCtl.mshrs_6.state_s_acquire && !u_g.inner_l2cache.slices_2.mshrCtl.mshrs_6.state_w_grantfirst && !u_g.inner_l2cache.slices_2.mshrCtl.mshrs_6.state_w_grant ||
                       u_g.inner_l2cache.slices_2.mshrCtl.mshrs_6.state_s_release && !u_g.inner_l2cache.slices_2.mshrCtl.mshrs_6.state_w_releaseack) :
                      (!u_g.inner_l2cache.slices_2.mshrCtl.mshrs_6.state_w_grant || !u_g.inner_l2cache.slices_2.mshrCtl.mshrs_6.state_w_releaseack))) c.push_back(1030);
    if (u_g.inner_l2cache.slices_2.mshrCtl.mshrs_7.req_valid && !u_g.inner_l2cache.slices_2.mshrCtl.mshrs_7.gotRetryAck && (
          kind == 0 ? !u_g.inner_l2cache.slices_2.mshrCtl.mshrs_7.state_w_grantlast :
          kind == 1 ? (u_g.inner_l2cache.slices_2.mshrCtl.mshrs_7.state_s_acquire && !u_g.inner_l2cache.slices_2.mshrCtl.mshrs_7.state_w_grantfirst && !u_g.inner_l2cache.slices_2.mshrCtl.mshrs_7.state_w_grant ||
                       u_g.inner_l2cache.slices_2.mshrCtl.mshrs_7.state_s_release && !u_g.inner_l2cache.slices_2.mshrCtl.mshrs_7.state_w_releaseack) :
                      (!u_g.inner_l2cache.slices_2.mshrCtl.mshrs_7.state_w_grant || !u_g.inner_l2cache.slices_2.mshrCtl.mshrs_7.state_w_releaseack))) c.push_back(1031);
    if (u_g.inner_l2cache.slices_2.mshrCtl.mshrs_8.req_valid && !u_g.inner_l2cache.slices_2.mshrCtl.mshrs_8.gotRetryAck && (
          kind == 0 ? !u_g.inner_l2cache.slices_2.mshrCtl.mshrs_8.state_w_grantlast :
          kind == 1 ? (u_g.inner_l2cache.slices_2.mshrCtl.mshrs_8.state_s_acquire && !u_g.inner_l2cache.slices_2.mshrCtl.mshrs_8.state_w_grantfirst && !u_g.inner_l2cache.slices_2.mshrCtl.mshrs_8.state_w_grant ||
                       u_g.inner_l2cache.slices_2.mshrCtl.mshrs_8.state_s_release && !u_g.inner_l2cache.slices_2.mshrCtl.mshrs_8.state_w_releaseack) :
                      (!u_g.inner_l2cache.slices_2.mshrCtl.mshrs_8.state_w_grant || !u_g.inner_l2cache.slices_2.mshrCtl.mshrs_8.state_w_releaseack))) c.push_back(1032);
    if (u_g.inner_l2cache.slices_2.mshrCtl.mshrs_9.req_valid && !u_g.inner_l2cache.slices_2.mshrCtl.mshrs_9.gotRetryAck && (
          kind == 0 ? !u_g.inner_l2cache.slices_2.mshrCtl.mshrs_9.state_w_grantlast :
          kind == 1 ? (u_g.inner_l2cache.slices_2.mshrCtl.mshrs_9.state_s_acquire && !u_g.inner_l2cache.slices_2.mshrCtl.mshrs_9.state_w_grantfirst && !u_g.inner_l2cache.slices_2.mshrCtl.mshrs_9.state_w_grant ||
                       u_g.inner_l2cache.slices_2.mshrCtl.mshrs_9.state_s_release && !u_g.inner_l2cache.slices_2.mshrCtl.mshrs_9.state_w_releaseack) :
                      (!u_g.inner_l2cache.slices_2.mshrCtl.mshrs_9.state_w_grant || !u_g.inner_l2cache.slices_2.mshrCtl.mshrs_9.state_w_releaseack))) c.push_back(1033);
    if (u_g.inner_l2cache.slices_2.mshrCtl.mshrs_10.req_valid && !u_g.inner_l2cache.slices_2.mshrCtl.mshrs_10.gotRetryAck && (
          kind == 0 ? !u_g.inner_l2cache.slices_2.mshrCtl.mshrs_10.state_w_grantlast :
          kind == 1 ? (u_g.inner_l2cache.slices_2.mshrCtl.mshrs_10.state_s_acquire && !u_g.inner_l2cache.slices_2.mshrCtl.mshrs_10.state_w_grantfirst && !u_g.inner_l2cache.slices_2.mshrCtl.mshrs_10.state_w_grant ||
                       u_g.inner_l2cache.slices_2.mshrCtl.mshrs_10.state_s_release && !u_g.inner_l2cache.slices_2.mshrCtl.mshrs_10.state_w_releaseack) :
                      (!u_g.inner_l2cache.slices_2.mshrCtl.mshrs_10.state_w_grant || !u_g.inner_l2cache.slices_2.mshrCtl.mshrs_10.state_w_releaseack))) c.push_back(1034);
    if (u_g.inner_l2cache.slices_2.mshrCtl.mshrs_11.req_valid && !u_g.inner_l2cache.slices_2.mshrCtl.mshrs_11.gotRetryAck && (
          kind == 0 ? !u_g.inner_l2cache.slices_2.mshrCtl.mshrs_11.state_w_grantlast :
          kind == 1 ? (u_g.inner_l2cache.slices_2.mshrCtl.mshrs_11.state_s_acquire && !u_g.inner_l2cache.slices_2.mshrCtl.mshrs_11.state_w_grantfirst && !u_g.inner_l2cache.slices_2.mshrCtl.mshrs_11.state_w_grant ||
                       u_g.inner_l2cache.slices_2.mshrCtl.mshrs_11.state_s_release && !u_g.inner_l2cache.slices_2.mshrCtl.mshrs_11.state_w_releaseack) :
                      (!u_g.inner_l2cache.slices_2.mshrCtl.mshrs_11.state_w_grant || !u_g.inner_l2cache.slices_2.mshrCtl.mshrs_11.state_w_releaseack))) c.push_back(1035);
    if (u_g.inner_l2cache.slices_2.mshrCtl.mshrs_12.req_valid && !u_g.inner_l2cache.slices_2.mshrCtl.mshrs_12.gotRetryAck && (
          kind == 0 ? !u_g.inner_l2cache.slices_2.mshrCtl.mshrs_12.state_w_grantlast :
          kind == 1 ? (u_g.inner_l2cache.slices_2.mshrCtl.mshrs_12.state_s_acquire && !u_g.inner_l2cache.slices_2.mshrCtl.mshrs_12.state_w_grantfirst && !u_g.inner_l2cache.slices_2.mshrCtl.mshrs_12.state_w_grant ||
                       u_g.inner_l2cache.slices_2.mshrCtl.mshrs_12.state_s_release && !u_g.inner_l2cache.slices_2.mshrCtl.mshrs_12.state_w_releaseack) :
                      (!u_g.inner_l2cache.slices_2.mshrCtl.mshrs_12.state_w_grant || !u_g.inner_l2cache.slices_2.mshrCtl.mshrs_12.state_w_releaseack))) c.push_back(1036);
    if (u_g.inner_l2cache.slices_2.mshrCtl.mshrs_13.req_valid && !u_g.inner_l2cache.slices_2.mshrCtl.mshrs_13.gotRetryAck && (
          kind == 0 ? !u_g.inner_l2cache.slices_2.mshrCtl.mshrs_13.state_w_grantlast :
          kind == 1 ? (u_g.inner_l2cache.slices_2.mshrCtl.mshrs_13.state_s_acquire && !u_g.inner_l2cache.slices_2.mshrCtl.mshrs_13.state_w_grantfirst && !u_g.inner_l2cache.slices_2.mshrCtl.mshrs_13.state_w_grant ||
                       u_g.inner_l2cache.slices_2.mshrCtl.mshrs_13.state_s_release && !u_g.inner_l2cache.slices_2.mshrCtl.mshrs_13.state_w_releaseack) :
                      (!u_g.inner_l2cache.slices_2.mshrCtl.mshrs_13.state_w_grant || !u_g.inner_l2cache.slices_2.mshrCtl.mshrs_13.state_w_releaseack))) c.push_back(1037);
    if (u_g.inner_l2cache.slices_2.mshrCtl.mshrs_14.req_valid && !u_g.inner_l2cache.slices_2.mshrCtl.mshrs_14.gotRetryAck && (
          kind == 0 ? !u_g.inner_l2cache.slices_2.mshrCtl.mshrs_14.state_w_grantlast :
          kind == 1 ? (u_g.inner_l2cache.slices_2.mshrCtl.mshrs_14.state_s_acquire && !u_g.inner_l2cache.slices_2.mshrCtl.mshrs_14.state_w_grantfirst && !u_g.inner_l2cache.slices_2.mshrCtl.mshrs_14.state_w_grant ||
                       u_g.inner_l2cache.slices_2.mshrCtl.mshrs_14.state_s_release && !u_g.inner_l2cache.slices_2.mshrCtl.mshrs_14.state_w_releaseack) :
                      (!u_g.inner_l2cache.slices_2.mshrCtl.mshrs_14.state_w_grant || !u_g.inner_l2cache.slices_2.mshrCtl.mshrs_14.state_w_releaseack))) c.push_back(1038);
    if (u_g.inner_l2cache.slices_2.mshrCtl.mshrs_15.req_valid && !u_g.inner_l2cache.slices_2.mshrCtl.mshrs_15.gotRetryAck && (
          kind == 0 ? !u_g.inner_l2cache.slices_2.mshrCtl.mshrs_15.state_w_grantlast :
          kind == 1 ? (u_g.inner_l2cache.slices_2.mshrCtl.mshrs_15.state_s_acquire && !u_g.inner_l2cache.slices_2.mshrCtl.mshrs_15.state_w_grantfirst && !u_g.inner_l2cache.slices_2.mshrCtl.mshrs_15.state_w_grant ||
                       u_g.inner_l2cache.slices_2.mshrCtl.mshrs_15.state_s_release && !u_g.inner_l2cache.slices_2.mshrCtl.mshrs_15.state_w_releaseack) :
                      (!u_g.inner_l2cache.slices_2.mshrCtl.mshrs_15.state_w_grant || !u_g.inner_l2cache.slices_2.mshrCtl.mshrs_15.state_w_releaseack))) c.push_back(1039);
    if (u_g.inner_l2cache.slices_3.mshrCtl.mshrs_0.req_valid && !u_g.inner_l2cache.slices_3.mshrCtl.mshrs_0.gotRetryAck && (
          kind == 0 ? !u_g.inner_l2cache.slices_3.mshrCtl.mshrs_0.state_w_grantlast :
          kind == 1 ? (u_g.inner_l2cache.slices_3.mshrCtl.mshrs_0.state_s_acquire && !u_g.inner_l2cache.slices_3.mshrCtl.mshrs_0.state_w_grantfirst && !u_g.inner_l2cache.slices_3.mshrCtl.mshrs_0.state_w_grant ||
                       u_g.inner_l2cache.slices_3.mshrCtl.mshrs_0.state_s_release && !u_g.inner_l2cache.slices_3.mshrCtl.mshrs_0.state_w_releaseack) :
                      (!u_g.inner_l2cache.slices_3.mshrCtl.mshrs_0.state_w_grant || !u_g.inner_l2cache.slices_3.mshrCtl.mshrs_0.state_w_releaseack))) c.push_back(1536);
    if (u_g.inner_l2cache.slices_3.mshrCtl.mshrs_1.req_valid && !u_g.inner_l2cache.slices_3.mshrCtl.mshrs_1.gotRetryAck && (
          kind == 0 ? !u_g.inner_l2cache.slices_3.mshrCtl.mshrs_1.state_w_grantlast :
          kind == 1 ? (u_g.inner_l2cache.slices_3.mshrCtl.mshrs_1.state_s_acquire && !u_g.inner_l2cache.slices_3.mshrCtl.mshrs_1.state_w_grantfirst && !u_g.inner_l2cache.slices_3.mshrCtl.mshrs_1.state_w_grant ||
                       u_g.inner_l2cache.slices_3.mshrCtl.mshrs_1.state_s_release && !u_g.inner_l2cache.slices_3.mshrCtl.mshrs_1.state_w_releaseack) :
                      (!u_g.inner_l2cache.slices_3.mshrCtl.mshrs_1.state_w_grant || !u_g.inner_l2cache.slices_3.mshrCtl.mshrs_1.state_w_releaseack))) c.push_back(1537);
    if (u_g.inner_l2cache.slices_3.mshrCtl.mshrs_2.req_valid && !u_g.inner_l2cache.slices_3.mshrCtl.mshrs_2.gotRetryAck && (
          kind == 0 ? !u_g.inner_l2cache.slices_3.mshrCtl.mshrs_2.state_w_grantlast :
          kind == 1 ? (u_g.inner_l2cache.slices_3.mshrCtl.mshrs_2.state_s_acquire && !u_g.inner_l2cache.slices_3.mshrCtl.mshrs_2.state_w_grantfirst && !u_g.inner_l2cache.slices_3.mshrCtl.mshrs_2.state_w_grant ||
                       u_g.inner_l2cache.slices_3.mshrCtl.mshrs_2.state_s_release && !u_g.inner_l2cache.slices_3.mshrCtl.mshrs_2.state_w_releaseack) :
                      (!u_g.inner_l2cache.slices_3.mshrCtl.mshrs_2.state_w_grant || !u_g.inner_l2cache.slices_3.mshrCtl.mshrs_2.state_w_releaseack))) c.push_back(1538);
    if (u_g.inner_l2cache.slices_3.mshrCtl.mshrs_3.req_valid && !u_g.inner_l2cache.slices_3.mshrCtl.mshrs_3.gotRetryAck && (
          kind == 0 ? !u_g.inner_l2cache.slices_3.mshrCtl.mshrs_3.state_w_grantlast :
          kind == 1 ? (u_g.inner_l2cache.slices_3.mshrCtl.mshrs_3.state_s_acquire && !u_g.inner_l2cache.slices_3.mshrCtl.mshrs_3.state_w_grantfirst && !u_g.inner_l2cache.slices_3.mshrCtl.mshrs_3.state_w_grant ||
                       u_g.inner_l2cache.slices_3.mshrCtl.mshrs_3.state_s_release && !u_g.inner_l2cache.slices_3.mshrCtl.mshrs_3.state_w_releaseack) :
                      (!u_g.inner_l2cache.slices_3.mshrCtl.mshrs_3.state_w_grant || !u_g.inner_l2cache.slices_3.mshrCtl.mshrs_3.state_w_releaseack))) c.push_back(1539);
    if (u_g.inner_l2cache.slices_3.mshrCtl.mshrs_4.req_valid && !u_g.inner_l2cache.slices_3.mshrCtl.mshrs_4.gotRetryAck && (
          kind == 0 ? !u_g.inner_l2cache.slices_3.mshrCtl.mshrs_4.state_w_grantlast :
          kind == 1 ? (u_g.inner_l2cache.slices_3.mshrCtl.mshrs_4.state_s_acquire && !u_g.inner_l2cache.slices_3.mshrCtl.mshrs_4.state_w_grantfirst && !u_g.inner_l2cache.slices_3.mshrCtl.mshrs_4.state_w_grant ||
                       u_g.inner_l2cache.slices_3.mshrCtl.mshrs_4.state_s_release && !u_g.inner_l2cache.slices_3.mshrCtl.mshrs_4.state_w_releaseack) :
                      (!u_g.inner_l2cache.slices_3.mshrCtl.mshrs_4.state_w_grant || !u_g.inner_l2cache.slices_3.mshrCtl.mshrs_4.state_w_releaseack))) c.push_back(1540);
    if (u_g.inner_l2cache.slices_3.mshrCtl.mshrs_5.req_valid && !u_g.inner_l2cache.slices_3.mshrCtl.mshrs_5.gotRetryAck && (
          kind == 0 ? !u_g.inner_l2cache.slices_3.mshrCtl.mshrs_5.state_w_grantlast :
          kind == 1 ? (u_g.inner_l2cache.slices_3.mshrCtl.mshrs_5.state_s_acquire && !u_g.inner_l2cache.slices_3.mshrCtl.mshrs_5.state_w_grantfirst && !u_g.inner_l2cache.slices_3.mshrCtl.mshrs_5.state_w_grant ||
                       u_g.inner_l2cache.slices_3.mshrCtl.mshrs_5.state_s_release && !u_g.inner_l2cache.slices_3.mshrCtl.mshrs_5.state_w_releaseack) :
                      (!u_g.inner_l2cache.slices_3.mshrCtl.mshrs_5.state_w_grant || !u_g.inner_l2cache.slices_3.mshrCtl.mshrs_5.state_w_releaseack))) c.push_back(1541);
    if (u_g.inner_l2cache.slices_3.mshrCtl.mshrs_6.req_valid && !u_g.inner_l2cache.slices_3.mshrCtl.mshrs_6.gotRetryAck && (
          kind == 0 ? !u_g.inner_l2cache.slices_3.mshrCtl.mshrs_6.state_w_grantlast :
          kind == 1 ? (u_g.inner_l2cache.slices_3.mshrCtl.mshrs_6.state_s_acquire && !u_g.inner_l2cache.slices_3.mshrCtl.mshrs_6.state_w_grantfirst && !u_g.inner_l2cache.slices_3.mshrCtl.mshrs_6.state_w_grant ||
                       u_g.inner_l2cache.slices_3.mshrCtl.mshrs_6.state_s_release && !u_g.inner_l2cache.slices_3.mshrCtl.mshrs_6.state_w_releaseack) :
                      (!u_g.inner_l2cache.slices_3.mshrCtl.mshrs_6.state_w_grant || !u_g.inner_l2cache.slices_3.mshrCtl.mshrs_6.state_w_releaseack))) c.push_back(1542);
    if (u_g.inner_l2cache.slices_3.mshrCtl.mshrs_7.req_valid && !u_g.inner_l2cache.slices_3.mshrCtl.mshrs_7.gotRetryAck && (
          kind == 0 ? !u_g.inner_l2cache.slices_3.mshrCtl.mshrs_7.state_w_grantlast :
          kind == 1 ? (u_g.inner_l2cache.slices_3.mshrCtl.mshrs_7.state_s_acquire && !u_g.inner_l2cache.slices_3.mshrCtl.mshrs_7.state_w_grantfirst && !u_g.inner_l2cache.slices_3.mshrCtl.mshrs_7.state_w_grant ||
                       u_g.inner_l2cache.slices_3.mshrCtl.mshrs_7.state_s_release && !u_g.inner_l2cache.slices_3.mshrCtl.mshrs_7.state_w_releaseack) :
                      (!u_g.inner_l2cache.slices_3.mshrCtl.mshrs_7.state_w_grant || !u_g.inner_l2cache.slices_3.mshrCtl.mshrs_7.state_w_releaseack))) c.push_back(1543);
    if (u_g.inner_l2cache.slices_3.mshrCtl.mshrs_8.req_valid && !u_g.inner_l2cache.slices_3.mshrCtl.mshrs_8.gotRetryAck && (
          kind == 0 ? !u_g.inner_l2cache.slices_3.mshrCtl.mshrs_8.state_w_grantlast :
          kind == 1 ? (u_g.inner_l2cache.slices_3.mshrCtl.mshrs_8.state_s_acquire && !u_g.inner_l2cache.slices_3.mshrCtl.mshrs_8.state_w_grantfirst && !u_g.inner_l2cache.slices_3.mshrCtl.mshrs_8.state_w_grant ||
                       u_g.inner_l2cache.slices_3.mshrCtl.mshrs_8.state_s_release && !u_g.inner_l2cache.slices_3.mshrCtl.mshrs_8.state_w_releaseack) :
                      (!u_g.inner_l2cache.slices_3.mshrCtl.mshrs_8.state_w_grant || !u_g.inner_l2cache.slices_3.mshrCtl.mshrs_8.state_w_releaseack))) c.push_back(1544);
    if (u_g.inner_l2cache.slices_3.mshrCtl.mshrs_9.req_valid && !u_g.inner_l2cache.slices_3.mshrCtl.mshrs_9.gotRetryAck && (
          kind == 0 ? !u_g.inner_l2cache.slices_3.mshrCtl.mshrs_9.state_w_grantlast :
          kind == 1 ? (u_g.inner_l2cache.slices_3.mshrCtl.mshrs_9.state_s_acquire && !u_g.inner_l2cache.slices_3.mshrCtl.mshrs_9.state_w_grantfirst && !u_g.inner_l2cache.slices_3.mshrCtl.mshrs_9.state_w_grant ||
                       u_g.inner_l2cache.slices_3.mshrCtl.mshrs_9.state_s_release && !u_g.inner_l2cache.slices_3.mshrCtl.mshrs_9.state_w_releaseack) :
                      (!u_g.inner_l2cache.slices_3.mshrCtl.mshrs_9.state_w_grant || !u_g.inner_l2cache.slices_3.mshrCtl.mshrs_9.state_w_releaseack))) c.push_back(1545);
    if (u_g.inner_l2cache.slices_3.mshrCtl.mshrs_10.req_valid && !u_g.inner_l2cache.slices_3.mshrCtl.mshrs_10.gotRetryAck && (
          kind == 0 ? !u_g.inner_l2cache.slices_3.mshrCtl.mshrs_10.state_w_grantlast :
          kind == 1 ? (u_g.inner_l2cache.slices_3.mshrCtl.mshrs_10.state_s_acquire && !u_g.inner_l2cache.slices_3.mshrCtl.mshrs_10.state_w_grantfirst && !u_g.inner_l2cache.slices_3.mshrCtl.mshrs_10.state_w_grant ||
                       u_g.inner_l2cache.slices_3.mshrCtl.mshrs_10.state_s_release && !u_g.inner_l2cache.slices_3.mshrCtl.mshrs_10.state_w_releaseack) :
                      (!u_g.inner_l2cache.slices_3.mshrCtl.mshrs_10.state_w_grant || !u_g.inner_l2cache.slices_3.mshrCtl.mshrs_10.state_w_releaseack))) c.push_back(1546);
    if (u_g.inner_l2cache.slices_3.mshrCtl.mshrs_11.req_valid && !u_g.inner_l2cache.slices_3.mshrCtl.mshrs_11.gotRetryAck && (
          kind == 0 ? !u_g.inner_l2cache.slices_3.mshrCtl.mshrs_11.state_w_grantlast :
          kind == 1 ? (u_g.inner_l2cache.slices_3.mshrCtl.mshrs_11.state_s_acquire && !u_g.inner_l2cache.slices_3.mshrCtl.mshrs_11.state_w_grantfirst && !u_g.inner_l2cache.slices_3.mshrCtl.mshrs_11.state_w_grant ||
                       u_g.inner_l2cache.slices_3.mshrCtl.mshrs_11.state_s_release && !u_g.inner_l2cache.slices_3.mshrCtl.mshrs_11.state_w_releaseack) :
                      (!u_g.inner_l2cache.slices_3.mshrCtl.mshrs_11.state_w_grant || !u_g.inner_l2cache.slices_3.mshrCtl.mshrs_11.state_w_releaseack))) c.push_back(1547);
    if (u_g.inner_l2cache.slices_3.mshrCtl.mshrs_12.req_valid && !u_g.inner_l2cache.slices_3.mshrCtl.mshrs_12.gotRetryAck && (
          kind == 0 ? !u_g.inner_l2cache.slices_3.mshrCtl.mshrs_12.state_w_grantlast :
          kind == 1 ? (u_g.inner_l2cache.slices_3.mshrCtl.mshrs_12.state_s_acquire && !u_g.inner_l2cache.slices_3.mshrCtl.mshrs_12.state_w_grantfirst && !u_g.inner_l2cache.slices_3.mshrCtl.mshrs_12.state_w_grant ||
                       u_g.inner_l2cache.slices_3.mshrCtl.mshrs_12.state_s_release && !u_g.inner_l2cache.slices_3.mshrCtl.mshrs_12.state_w_releaseack) :
                      (!u_g.inner_l2cache.slices_3.mshrCtl.mshrs_12.state_w_grant || !u_g.inner_l2cache.slices_3.mshrCtl.mshrs_12.state_w_releaseack))) c.push_back(1548);
    if (u_g.inner_l2cache.slices_3.mshrCtl.mshrs_13.req_valid && !u_g.inner_l2cache.slices_3.mshrCtl.mshrs_13.gotRetryAck && (
          kind == 0 ? !u_g.inner_l2cache.slices_3.mshrCtl.mshrs_13.state_w_grantlast :
          kind == 1 ? (u_g.inner_l2cache.slices_3.mshrCtl.mshrs_13.state_s_acquire && !u_g.inner_l2cache.slices_3.mshrCtl.mshrs_13.state_w_grantfirst && !u_g.inner_l2cache.slices_3.mshrCtl.mshrs_13.state_w_grant ||
                       u_g.inner_l2cache.slices_3.mshrCtl.mshrs_13.state_s_release && !u_g.inner_l2cache.slices_3.mshrCtl.mshrs_13.state_w_releaseack) :
                      (!u_g.inner_l2cache.slices_3.mshrCtl.mshrs_13.state_w_grant || !u_g.inner_l2cache.slices_3.mshrCtl.mshrs_13.state_w_releaseack))) c.push_back(1549);
    if (u_g.inner_l2cache.slices_3.mshrCtl.mshrs_14.req_valid && !u_g.inner_l2cache.slices_3.mshrCtl.mshrs_14.gotRetryAck && (
          kind == 0 ? !u_g.inner_l2cache.slices_3.mshrCtl.mshrs_14.state_w_grantlast :
          kind == 1 ? (u_g.inner_l2cache.slices_3.mshrCtl.mshrs_14.state_s_acquire && !u_g.inner_l2cache.slices_3.mshrCtl.mshrs_14.state_w_grantfirst && !u_g.inner_l2cache.slices_3.mshrCtl.mshrs_14.state_w_grant ||
                       u_g.inner_l2cache.slices_3.mshrCtl.mshrs_14.state_s_release && !u_g.inner_l2cache.slices_3.mshrCtl.mshrs_14.state_w_releaseack) :
                      (!u_g.inner_l2cache.slices_3.mshrCtl.mshrs_14.state_w_grant || !u_g.inner_l2cache.slices_3.mshrCtl.mshrs_14.state_w_releaseack))) c.push_back(1550);
    if (u_g.inner_l2cache.slices_3.mshrCtl.mshrs_15.req_valid && !u_g.inner_l2cache.slices_3.mshrCtl.mshrs_15.gotRetryAck && (
          kind == 0 ? !u_g.inner_l2cache.slices_3.mshrCtl.mshrs_15.state_w_grantlast :
          kind == 1 ? (u_g.inner_l2cache.slices_3.mshrCtl.mshrs_15.state_s_acquire && !u_g.inner_l2cache.slices_3.mshrCtl.mshrs_15.state_w_grantfirst && !u_g.inner_l2cache.slices_3.mshrCtl.mshrs_15.state_w_grant ||
                       u_g.inner_l2cache.slices_3.mshrCtl.mshrs_15.state_s_release && !u_g.inner_l2cache.slices_3.mshrCtl.mshrs_15.state_w_releaseack) :
                      (!u_g.inner_l2cache.slices_3.mshrCtl.mshrs_15.state_w_grant || !u_g.inner_l2cache.slices_3.mshrCtl.mshrs_15.state_w_releaseack))) c.push_back(1551);
    begin
      int cm[$];
      if ((kind == 0 ? u_g.inner_l2cache.mmioBridge._entries_0_io_chi_rx_dat_ready : u_g.inner_l2cache.mmioBridge._entries_0_io_chi_rx_rsp_ready) && cyc - mmio_sent[0] > 16) cm.push_back(2048);
      if ((kind == 0 ? u_g.inner_l2cache.mmioBridge._entries_1_io_chi_rx_dat_ready : u_g.inner_l2cache.mmioBridge._entries_1_io_chi_rx_rsp_ready) && cyc - mmio_sent[1] > 16) cm.push_back(2049);
      if ((kind == 0 ? u_g.inner_l2cache.mmioBridge._entries_2_io_chi_rx_dat_ready : u_g.inner_l2cache.mmioBridge._entries_2_io_chi_rx_rsp_ready) && cyc - mmio_sent[2] > 16) cm.push_back(2050);
      if ((kind == 0 ? u_g.inner_l2cache.mmioBridge._entries_3_io_chi_rx_dat_ready : u_g.inner_l2cache.mmioBridge._entries_3_io_chi_rx_rsp_ready) && cyc - mmio_sent[3] > 16) cm.push_back(2051);
      if ((kind == 0 ? u_g.inner_l2cache.mmioBridge._entries_4_io_chi_rx_dat_ready : u_g.inner_l2cache.mmioBridge._entries_4_io_chi_rx_rsp_ready) && cyc - mmio_sent[4] > 16) cm.push_back(2052);
      if ((kind == 0 ? u_g.inner_l2cache.mmioBridge._entries_5_io_chi_rx_dat_ready : u_g.inner_l2cache.mmioBridge._entries_5_io_chi_rx_rsp_ready) && cyc - mmio_sent[5] > 16) cm.push_back(2053);
      if ((kind == 0 ? u_g.inner_l2cache.mmioBridge._entries_6_io_chi_rx_dat_ready : u_g.inner_l2cache.mmioBridge._entries_6_io_chi_rx_rsp_ready) && cyc - mmio_sent[6] > 16) cm.push_back(2054);
      if ((kind == 0 ? u_g.inner_l2cache.mmioBridge._entries_7_io_chi_rx_dat_ready : u_g.inner_l2cache.mmioBridge._entries_7_io_chi_rx_rsp_ready) && cyc - mmio_sent[7] > 16) cm.push_back(2055);
      if ((kind == 0 ? u_g.inner_l2cache.mmioBridge._entries_8_io_chi_rx_dat_ready : u_g.inner_l2cache.mmioBridge._entries_8_io_chi_rx_rsp_ready) && cyc - mmio_sent[8] > 16) cm.push_back(2056);
      if ((kind == 0 ? u_g.inner_l2cache.mmioBridge._entries_9_io_chi_rx_dat_ready : u_g.inner_l2cache.mmioBridge._entries_9_io_chi_rx_rsp_ready) && cyc - mmio_sent[9] > 16) cm.push_back(2057);
      if ((kind == 0 ? u_g.inner_l2cache.mmioBridge._entries_10_io_chi_rx_dat_ready : u_g.inner_l2cache.mmioBridge._entries_10_io_chi_rx_rsp_ready) && cyc - mmio_sent[10] > 16) cm.push_back(2058);
      if ((kind == 0 ? u_g.inner_l2cache.mmioBridge._entries_11_io_chi_rx_dat_ready : u_g.inner_l2cache.mmioBridge._entries_11_io_chi_rx_rsp_ready) && cyc - mmio_sent[11] > 16) cm.push_back(2059);
      if ((kind == 0 ? u_g.inner_l2cache.mmioBridge._entries_12_io_chi_rx_dat_ready : u_g.inner_l2cache.mmioBridge._entries_12_io_chi_rx_rsp_ready) && cyc - mmio_sent[12] > 16) cm.push_back(2060);
      if ((kind == 0 ? u_g.inner_l2cache.mmioBridge._entries_13_io_chi_rx_dat_ready : u_g.inner_l2cache.mmioBridge._entries_13_io_chi_rx_rsp_ready) && cyc - mmio_sent[13] > 16) cm.push_back(2061);
      if ((kind == 0 ? u_g.inner_l2cache.mmioBridge._entries_14_io_chi_rx_dat_ready : u_g.inner_l2cache.mmioBridge._entries_14_io_chi_rx_rsp_ready) && cyc - mmio_sent[14] > 16) cm.push_back(2062);
      if ((kind == 0 ? u_g.inner_l2cache.mmioBridge._entries_15_io_chi_rx_dat_ready : u_g.inner_l2cache.mmioBridge._entries_15_io_chi_rx_rsp_ready) && cyc - mmio_sent[15] > 16) cm.push_back(2063);
      if (cm.size() != 0 && (c.size() == 0 || $urandom_range(0, 7) == 0)) return cm[$urandom_range(0, cm.size() - 1)];
    end
    if (c.size() == 0) return -1;
    return c[$urandom_range(0, c.size() - 1)];
  endfunction

  // ---- CHI 信用：RX 侧按 golden 的 lcrdv 记账，有信用才发 flit；TX 侧 tb 发信用，在途不超过 4 ----
  int rx_crd_rsp = 0, rx_crd_dat = 0, rx_crd_snp = 0;
  int tx_crd_req = 0, tx_crd_rsp = 0, tx_crd_dat = 0;
  bit tlb_q = 0;           // 上一拍 golden 发了 L2 TLB 请求
  task automatic credit_model_account();
    // 上一拍的结果：golden 发来的 RX 信用 / tb 发出的 RX flit；tb 发出的 TX 信用 / golden 发出的 TX flit
    if (g_io_chi_rx_rsp_lcrdv) rx_crd_rsp++;
    if (io_chi_rx_rsp_flitv) rx_crd_rsp--;
    if (g_io_chi_rx_dat_lcrdv) rx_crd_dat++;
    if (io_chi_rx_dat_flitv) rx_crd_dat--;
    if (g_io_chi_rx_snp_lcrdv) rx_crd_snp++;
    if (io_chi_rx_snp_flitv) rx_crd_snp--;
    if (g_io_chi_tx_req_flitv && tx_crd_req > 0) tx_crd_req--;
    if (io_chi_tx_req_lcrdv) tx_crd_req++;
    if (g_io_chi_tx_rsp_flitv && tx_crd_rsp > 0) tx_crd_rsp--;
    if (io_chi_tx_rsp_lcrdv) tx_crd_rsp++;
    if (g_io_chi_tx_dat_flitv && tx_crd_dat > 0) tx_crd_dat--;
    if (io_chi_tx_dat_lcrdv) tx_crd_dat++;
    if (reset || !g_io_chi_rx_linkactiveack) begin rx_crd_rsp = 0; rx_crd_dat = 0; rx_crd_snp = 0; end
    if (reset || !g_io_chi_tx_linkactivereq) begin tx_crd_req = 0; tx_crd_rsp = 0; tx_crd_dat = 0; end
  endtask
  task automatic credit_model_drive();
    io_chi_tx_req_lcrdv = (tx_crd_req < 4) && ($urandom_range(0, 1) == 0) && g_io_chi_tx_linkactivereq && io_chi_tx_linkactiveack;
    io_chi_tx_rsp_lcrdv = (tx_crd_rsp < 4) && ($urandom_range(0, 1) == 0) && g_io_chi_tx_linkactivereq && io_chi_tx_linkactiveack;
    io_chi_tx_dat_lcrdv = (tx_crd_dat < 4) && ($urandom_range(0, 1) == 0) && g_io_chi_tx_linkactivereq && io_chi_tx_linkactiveack;
  endtask

  task automatic rx_flits();
    automatic int t;
    // RSP flit（73 位）：qos[3:0] tgtID[14:4] srcID[25:15] txnID[37:26] opcode[42:38] respErr[44:43] resp[47:45]
    //   fwdState[50:48] cBusy[53:51] dbID[65:54] pCrdType[69:66] tagOp[71:70] traceTag[72]
    io_chi_rx_rsp_flit = 73'({$urandom, $urandom, $urandom});
    io_chi_rx_rsp_flit[42:38] = pick_rsp_opcode();
    io_chi_rx_rsp_flit[25:15] = ($urandom_range(0, 15) == 0) ? 11'($urandom) : 11'($urandom_range(0, 1));
    io_chi_rx_rsp_flit[69:66] = ($urandom_range(0, 15) == 0) ? 4'($urandom) : 4'($urandom_range(0, 1));
    io_chi_rx_rsp_flit[44:43] = ($urandom_range(0, 15) == 0) ? 2'($urandom) : 2'h0;
    io_chi_rx_rsp_flitv = (rx_crd_rsp > 0) && (slow_phase() ? ($urandom_range(0, 31) == 0) : ($urandom_range(0, 3) == 0));
    if (io_chi_rx_rsp_flitv && io_chi_rx_rsp_flit[42:38] != 5'h7 && io_chi_rx_rsp_flit[42:38] != 5'h0) begin
      t = pick_target(io_chi_rx_rsp_flit[42:38] == 5'h3 ? 1 : 2);
      if (t < 0) io_chi_rx_rsp_flitv = 1'b0; else io_chi_rx_rsp_flit[37:26] = 12'(t);
      if (t >= 'h800) mmio_sent[t & 15] = cyc;
    end
    io_chi_rx_rsp_flitpend = io_chi_rx_rsp_flitv | ($urandom_range(0, 3) == 0);
    // DAT flit（422 位）：txnID[37:26] homeNID[48:38] opcode[52:49] respErr[54:53] dataID[80:79] dataCheck[417:386] poison[421:418]
    io_chi_rx_dat_flit = 422'({$urandom, $urandom, $urandom, $urandom, $urandom, $urandom, $urandom,
                               $urandom, $urandom, $urandom, $urandom, $urandom, $urandom, $urandom});
    io_chi_rx_dat_flit[52:49] = ($urandom_range(0, 7) == 0) ? 4'($urandom) : (($urandom_range(0, 3) == 0) ? 4'hB : 4'h4);
    io_chi_rx_dat_flit[80:79] = 2'($urandom_range(0, 1)) << 1;
    io_chi_rx_dat_flit[48:38] = ($urandom_range(0, 15) == 0) ? 11'($urandom) : 11'($urandom_range(0, 1));
    io_chi_rx_dat_flit[54:53] = ($urandom_range(0, 15) == 0) ? 2'($urandom) : 2'h0;
    io_chi_rx_dat_flit[421:418] = ($urandom_range(0, 15) == 0) ? 4'($urandom) : 4'h0;
    io_chi_rx_dat_flitv = (rx_crd_dat > 0) && (slow_phase() ? ($urandom_range(0, 31) == 0) : ($urandom_range(0, 3) == 0));
    if (io_chi_rx_dat_flitv) begin
      t = pick_target(0);
      if (t < 0) io_chi_rx_dat_flitv = 1'b0; else io_chi_rx_dat_flit[37:26] = 12'(t);
      if (t >= 'h800) mmio_sent[t & 15] = cyc;
    end
    io_chi_rx_dat_flitpend = io_chi_rx_dat_flitv | ($urandom_range(0, 3) == 0);
    // SNP flit（115 位）：srcID[14:4] txnID[26:15] opcode[54:50] addr[99:55]（= 物理地址 >> 3）
    io_chi_rx_snp_flit = 115'({$urandom, $urandom, $urandom, $urandom});
    io_chi_rx_snp_flit[54:50] = ($urandom_range(0, 3) == 0) ? 5'($urandom) : 5'($urandom_range(1, 10));
    io_chi_rx_snp_flit[99:55] = 45'(pick_addr($urandom_range(0, 3)) >> 3);
    io_chi_rx_snp_flit[14:4] = ($urandom_range(0, 15) == 0) ? 11'($urandom) : 11'($urandom_range(0, 1));
    io_chi_rx_snp_flitv = (rx_crd_snp > 0) && ($urandom_range(0, 9) == 0);
    io_chi_rx_snp_flitpend = io_chi_rx_snp_flitv | ($urandom_range(0, 3) == 0);
  endtask

  task automatic drive();
    credit_model_account();   // 先记上一拍的账（必须在本拍重摇输入之前：要读上一拍发出的 flitv / lcrdv）
    auto_inner_buffers_out_a_ready = ($urandom_range(0, 9) < 8);
    auto_inner_buffers_out_d_valid = ($urandom_range(0, 3) == 0);
    auto_inner_buffers_out_d_bits_opcode = ($urandom_range(0, 1) == 0) ? 4'h1 : 4'h0;
    auto_inner_buffers_out_d_bits_param = 2'($urandom);
    auto_inner_buffers_out_d_bits_size = 2'($urandom);
    auto_inner_buffers_out_d_bits_source = 5'($urandom);
    auto_inner_buffers_out_d_bits_sink = 1'($urandom);
    auto_inner_buffers_out_d_bits_denied = 1'($urandom);
    auto_inner_buffers_out_d_bits_data = 64'({$urandom, $urandom});
    auto_inner_buffers_out_d_bits_corrupt = 1'($urandom);
    auto_inner_buffers_in_a_valid = ($urandom_range(0, 7) == 0);
    auto_inner_buffers_in_a_bits_opcode = pick_mmio_opcode();
    auto_inner_buffers_in_a_bits_param = 3'($urandom);
    auto_inner_buffers_in_a_bits_size = 2'($urandom);
    auto_inner_buffers_in_a_bits_source = 4'($urandom);
    auto_inner_buffers_in_a_bits_address = ($urandom_range(0, 3) == 0) ? 48'h3801_0000 + 48'($urandom_range(0, 'hFFF)) : ($urandom_range(0, 2) == 0) ? 48'h3802_2000 + 48'($urandom_range(0, 'hFF)) : 48'($urandom_range(0, 'h3FFF_FFFF));
    auto_inner_buffers_in_a_bits_user_memBackType_MM = 1'($urandom);
    auto_inner_buffers_in_a_bits_user_memPageType_NC = 1'($urandom);
    auto_inner_buffers_in_a_bits_mask = 8'($urandom);
    auto_inner_buffers_in_a_bits_data = 64'({$urandom, $urandom});
    auto_inner_buffers_in_a_bits_corrupt = 1'($urandom);
    auto_inner_buffers_in_d_ready = ($urandom_range(0, 9) < 8);
    auto_inner_l2cache_pf_recv_in_addr = 64'({$urandom, $urandom});
    auto_inner_l2cache_pf_recv_in_pf_source = pick_pf_source();
    auto_inner_l2cache_pf_recv_in_addr_valid = ($urandom_range(0, 7) == 0);
    auto_inner_i_mmio_buffer_in_a_valid = ($urandom_range(0, 7) == 0);
    auto_inner_i_mmio_buffer_in_a_bits_param = 3'($urandom);
    auto_inner_i_mmio_buffer_in_a_bits_address = ($urandom_range(0, 3) == 0) ? 48'h3801_0000 + 48'($urandom_range(0, 'hFFF)) : ($urandom_range(0, 2) == 0) ? 48'h3802_2000 + 48'($urandom_range(0, 'hFF)) : 48'($urandom_range(0, 'h3FFF_FFFF));
    auto_inner_i_mmio_buffer_in_a_bits_user_memPageType_NC = 1'($urandom);
    auto_inner_i_mmio_buffer_in_a_bits_user_memBackType_MM = 1'($urandom);
    auto_inner_i_mmio_buffer_in_a_bits_corrupt = 1'($urandom);
    auto_inner_i_mmio_buffer_in_d_ready = ($urandom_range(0, 9) < 8);
    auto_inner_ptw_to_l2_buffer_in_a_valid = ($urandom_range(0, 7) == 0);
    auto_inner_ptw_to_l2_buffer_in_a_bits_opcode = ($urandom_range(0, 7) == 0) ? 4'($urandom) : 4'h4;
    auto_inner_ptw_to_l2_buffer_in_a_bits_param = 3'($urandom);
    auto_inner_ptw_to_l2_buffer_in_a_bits_size = ($urandom_range(0, 7) == 0) ? 3'($urandom) : 3'h6;
    auto_inner_ptw_to_l2_buffer_in_a_bits_source = 4'($urandom_range(0, 3));
    auto_inner_ptw_to_l2_buffer_in_a_bits_address = pick_addr($urandom_range(0, 3));
    auto_inner_ptw_to_l2_buffer_in_a_bits_user_reqSource = 5'($urandom);
    auto_inner_ptw_to_l2_buffer_in_a_bits_mask = 32'($urandom);
    auto_inner_ptw_to_l2_buffer_in_a_bits_data = 256'({$urandom, $urandom, $urandom, $urandom, $urandom, $urandom, $urandom, $urandom});
    auto_inner_ptw_to_l2_buffer_in_a_bits_corrupt = 1'($urandom);
    auto_inner_ptw_to_l2_buffer_in_d_ready = ($urandom_range(0, 9) < 8);
    auto_inner_logger_in_1_a_valid = ($urandom_range(0, 7) == 0);
    auto_inner_logger_in_1_a_bits_opcode = ($urandom_range(0, 7) == 0) ? 4'($urandom) : 4'h4;
    auto_inner_logger_in_1_a_bits_param = 3'($urandom);
    auto_inner_logger_in_1_a_bits_size = ($urandom_range(0, 7) == 0) ? 3'($urandom) : 3'h6;
    auto_inner_logger_in_1_a_bits_source = 4'($urandom_range(0, 3));
    auto_inner_logger_in_1_a_bits_address = pick_addr($urandom_range(0, 3));
    auto_inner_logger_in_1_a_bits_user_alias = 2'($urandom);
    auto_inner_logger_in_1_a_bits_user_reqSource = 5'($urandom);
    auto_inner_logger_in_1_a_bits_user_needHint = 1'($urandom);
    auto_inner_logger_in_1_a_bits_mask = 32'($urandom);
    auto_inner_logger_in_1_a_bits_data = 256'({$urandom, $urandom, $urandom, $urandom, $urandom, $urandom, $urandom, $urandom});
    auto_inner_logger_in_1_a_bits_corrupt = 1'($urandom);
    auto_inner_logger_in_1_d_ready = ($urandom_range(0, 9) < 8);
    auto_inner_logger_in_0_a_valid = ($urandom_range(0, 3) == 0);
    auto_inner_logger_in_0_a_bits_opcode = pick_a_opcode();
    auto_inner_logger_in_0_a_bits_param = 3'($urandom);
    auto_inner_logger_in_0_a_bits_size = ($urandom_range(0, 7) == 0) ? 3'($urandom) : 3'h6;
    auto_inner_logger_in_0_a_bits_source = 7'($urandom_range(0, 7));
    auto_inner_logger_in_0_a_bits_address = pick_addr($urandom_range(0, 3));
    auto_inner_logger_in_0_a_bits_user_alias = 2'($urandom);
    auto_inner_logger_in_0_a_bits_user_vaddr = 44'({$urandom, $urandom});
    auto_inner_logger_in_0_a_bits_user_reqSource = 5'($urandom);
    auto_inner_logger_in_0_a_bits_user_needHint = 1'($urandom);
    auto_inner_logger_in_0_a_bits_echo_isKeyword = 1'($urandom);
    auto_inner_logger_in_0_a_bits_mask = 32'($urandom);
    auto_inner_logger_in_0_a_bits_data = 256'({$urandom, $urandom, $urandom, $urandom, $urandom, $urandom, $urandom, $urandom});
    auto_inner_logger_in_0_a_bits_corrupt = ($urandom_range(0, 31) == 0);
    auto_inner_logger_in_0_b_ready = ($urandom_range(0, 9) < 8);
    auto_inner_logger_in_0_c_valid = ($urandom_range(0, 9) == 0);
    auto_inner_logger_in_0_c_bits_opcode = ($urandom_range(0, 9) == 0) ? 3'($urandom) : 3'($urandom_range(4, 7));
    auto_inner_logger_in_0_c_bits_param = 3'($urandom);
    auto_inner_logger_in_0_c_bits_size = ($urandom_range(0, 7) == 0) ? 3'($urandom) : 3'h6;
    auto_inner_logger_in_0_c_bits_source = 7'($urandom_range(0, 7));
    auto_inner_logger_in_0_c_bits_address = pick_addr($urandom_range(0, 3));
    auto_inner_logger_in_0_c_bits_user_alias = 2'($urandom);
    auto_inner_logger_in_0_c_bits_user_vaddr = 44'({$urandom, $urandom});
    auto_inner_logger_in_0_c_bits_user_reqSource = 5'($urandom);
    auto_inner_logger_in_0_c_bits_user_needHint = 1'($urandom);
    auto_inner_logger_in_0_c_bits_echo_isKeyword = 1'($urandom);
    auto_inner_logger_in_0_c_bits_data = 256'({$urandom, $urandom, $urandom, $urandom, $urandom, $urandom, $urandom, $urandom});
    auto_inner_logger_in_0_c_bits_corrupt = ($urandom_range(0, 31) == 0);
    auto_inner_logger_in_0_d_ready = ($urandom_range(0, 9) < 8);
    auto_inner_logger_in_0_e_valid = ($urandom_range(0, 4) == 0);
    auto_inner_logger_in_0_e_bits_sink = 8'($urandom_range(0, 16));
    auto_inner_nmi_int_in_0 = ($urandom_range(0, 15) == 0);
    auto_inner_nmi_int_in_1 = ($urandom_range(0, 15) == 0);
    auto_inner_plic_int_in_1_0 = ($urandom_range(0, 15) == 0);
    auto_inner_plic_int_in_0_0 = ($urandom_range(0, 15) == 0);
    auto_inner_debug_int_in_0 = ($urandom_range(0, 15) == 0);
    auto_inner_clint_int_in_0 = ($urandom_range(0, 15) == 0);
    auto_inner_clint_int_in_1 = ($urandom_range(0, 15) == 0);
    io_beu_errors_icache_ecc_error_valid = ($urandom_range(0, 31) == 0);
    io_beu_errors_icache_ecc_error_bits = 48'({$urandom, $urandom});
    io_beu_errors_dcache_ecc_error_valid = ($urandom_range(0, 31) == 0);
    io_beu_errors_dcache_ecc_error_bits = 48'({$urandom, $urandom});
    io_beu_errors_uncache_ecc_error_valid = ($urandom_range(0, 31) == 0);
    io_beu_errors_uncache_ecc_error_bits = 48'({$urandom, $urandom});
    io_reset_vector_fromTile = 48'({$urandom, $urandom});
    io_hartId_fromTile = 64'({$urandom, $urandom});
    io_msiInfo_fromTile_valid = ($urandom_range(0, 3) == 0);
    io_msiInfo_fromTile_bits = 12'($urandom);
    io_msiAck_fromCore = ($urandom_range(0, 3) == 0);
    io_cpu_halt_fromCore = ($urandom_range(0, 3) == 0);
    io_cpu_critical_error_fromCore = ($urandom_range(0, 3) == 0);
    io_hartIsInReset_resetInFrontend = ($urandom_range(0, 63) == 0);
    io_traceCoreInterface_fromCore_toEncoder_priv = 3'($urandom);
    io_traceCoreInterface_fromCore_toEncoder_mstatus = 64'({$urandom, $urandom});
    io_traceCoreInterface_fromCore_toEncoder_trap_cause = 64'({$urandom, $urandom});
    io_traceCoreInterface_fromCore_toEncoder_trap_tval = 50'({$urandom, $urandom});
    io_traceCoreInterface_fromCore_toEncoder_groups_0_valid = 1'($urandom);
    io_traceCoreInterface_fromCore_toEncoder_groups_0_bits_iaddr = 50'({$urandom, $urandom});
    io_traceCoreInterface_fromCore_toEncoder_groups_0_bits_itype = ($urandom_range(0, 1) == 0) ? 4'($urandom_range(1, 2)) : 4'($urandom);
    io_traceCoreInterface_fromCore_toEncoder_groups_0_bits_iretire = 7'($urandom);
    io_traceCoreInterface_fromCore_toEncoder_groups_0_bits_ilastsize = 1'($urandom);
    io_traceCoreInterface_fromCore_toEncoder_groups_1_valid = 1'($urandom);
    io_traceCoreInterface_fromCore_toEncoder_groups_1_bits_iaddr = 50'({$urandom, $urandom});
    io_traceCoreInterface_fromCore_toEncoder_groups_1_bits_itype = ($urandom_range(0, 1) == 0) ? 4'($urandom_range(1, 2)) : 4'($urandom);
    io_traceCoreInterface_fromCore_toEncoder_groups_1_bits_iretire = 7'($urandom);
    io_traceCoreInterface_fromCore_toEncoder_groups_1_bits_ilastsize = 1'($urandom);
    io_traceCoreInterface_fromCore_toEncoder_groups_2_valid = 1'($urandom);
    io_traceCoreInterface_fromCore_toEncoder_groups_2_bits_iaddr = 50'({$urandom, $urandom});
    io_traceCoreInterface_fromCore_toEncoder_groups_2_bits_itype = ($urandom_range(0, 1) == 0) ? 4'($urandom_range(1, 2)) : 4'($urandom);
    io_traceCoreInterface_fromCore_toEncoder_groups_2_bits_iretire = 7'($urandom);
    io_traceCoreInterface_fromCore_toEncoder_groups_2_bits_ilastsize = 1'($urandom);
    io_traceCoreInterface_toTile_fromEncoder_enable = 1'($urandom);
    io_traceCoreInterface_toTile_fromEncoder_stall = 1'($urandom);
    io_debugTopDown_robHeadPaddr_valid = 1'($urandom);
    io_debugTopDown_robHeadPaddr_bits = 36'(pick_addr($urandom_range(0, 3)));
    io_l3Miss_fromTile = ($urandom_range(0, 3) == 0);
    io_clintTime_fromTile_valid = ($urandom_range(0, 3) == 0);
    io_clintTime_fromTile_bits = 64'({$urandom, $urandom});
    io_chi_rxsactive = 1'($urandom);
    io_chi_syscoack = ($urandom_range(0, 31) == 0) ? 1'($urandom) : g_io_chi_syscoreq;
    io_chi_tx_linkactiveack = ($urandom_range(0, 63) == 0) ? 1'($urandom) : g_io_chi_tx_linkactivereq;
    io_chi_tx_req_lcrdv = 1'b0;
    io_chi_tx_rsp_lcrdv = 1'b0;
    io_chi_tx_dat_lcrdv = 1'b0;
    io_chi_rx_linkactivereq = link_down_phase() ? 1'b0 : 1'b1;
    io_chi_rx_rsp_flitpend = '0;
    io_chi_rx_rsp_flitv = '0;
    io_chi_rx_rsp_flit = '0;
    io_chi_rx_dat_flitpend = '0;
    io_chi_rx_dat_flitv = '0;
    io_chi_rx_dat_flit = '0;
    io_chi_rx_snp_flitpend = '0;
    io_chi_rx_snp_flitv = '0;
    io_chi_rx_snp_flit = '0;
    io_nodeID = 11'($urandom_range(0, 3));
    io_pfCtrlFromCore_l2_pf_master_en = ($urandom_range(0, 15) != 0);
    io_pfCtrlFromCore_l2_pf_recv_en = ($urandom_range(0, 7) != 0);
    io_pfCtrlFromCore_l2_pbop_en = ($urandom_range(0, 7) != 0);
    io_pfCtrlFromCore_l2_vbop_en = ($urandom_range(0, 7) != 0);
    io_pfCtrlFromCore_l2_pf_delay_latency = 10'($urandom_range(0, 15));
    io_l2_tlb_req_resp_valid = tlb_q;
    io_l2_tlb_req_resp_bits_paddr_0 = 48'({$urandom, $urandom});
    io_l2_tlb_req_resp_bits_pbmt_0 = 2'($urandom);
    io_l2_tlb_req_resp_bits_miss = ($urandom_range(0, 3) == 0);
    io_l2_tlb_req_resp_bits_excp_0_gpf_ld = ($urandom_range(0, 19) == 0);
    io_l2_tlb_req_resp_bits_excp_0_pf_ld = ($urandom_range(0, 19) == 0);
    io_l2_tlb_req_resp_bits_excp_0_af_ld = ($urandom_range(0, 19) == 0);
    io_l2_pmp_resp_ld = 1'($urandom);
    io_l2_pmp_resp_mmio = 1'($urandom);
    io_dft_ram_hold = ($urandom_range(0, 63) == 0);
    io_dft_ram_bypass = ($urandom_range(0, 63) == 0);
    io_dft_ram_bp_clken = ($urandom_range(0, 63) == 0);
    io_dft_ram_aux_clk = 1'b0;
    io_dft_ram_aux_ckbp = 1'b0;
    io_dft_ram_mcp_hold = ($urandom_range(0, 63) == 0);
    io_dft_cgen = ($urandom_range(0, 63) == 0);
    if ($urandom_range(0, 3) != 0) auto_inner_logger_in_0_a_bits_user_vaddr = 44'(auto_inner_logger_in_0_a_bits_address);
    tlb_q = g_io_l2_tlb_req_req_valid;
    credit_model_drive();
    rx_flits();
    reset = ($urandom_range(0, 39999) == 0);
  endtask

  // ---- arm（按输出分组）----
  logic [15:0] pf_alloc_seen = 0;
  bit pf_tlb_seen = 0;
  bit [3:0] armed = 0;
  task automatic update_arm();
    pf_alloc_seen |= {u_g.inner_l2cache.prefetcher.vbop.reqFilter.alloc_15, u_g.inner_l2cache.prefetcher.vbop.reqFilter.alloc_14, u_g.inner_l2cache.prefetcher.vbop.reqFilter.alloc_13, u_g.inner_l2cache.prefetcher.vbop.reqFilter.alloc_12, u_g.inner_l2cache.prefetcher.vbop.reqFilter.alloc_11, u_g.inner_l2cache.prefetcher.vbop.reqFilter.alloc_10, u_g.inner_l2cache.prefetcher.vbop.reqFilter.alloc_9, u_g.inner_l2cache.prefetcher.vbop.reqFilter.alloc_8, u_g.inner_l2cache.prefetcher.vbop.reqFilter.alloc_7, u_g.inner_l2cache.prefetcher.vbop.reqFilter.alloc_6, u_g.inner_l2cache.prefetcher.vbop.reqFilter.alloc_5, u_g.inner_l2cache.prefetcher.vbop.reqFilter.alloc_4, u_g.inner_l2cache.prefetcher.vbop.reqFilter.alloc_3, u_g.inner_l2cache.prefetcher.vbop.reqFilter.alloc_2, u_g.inner_l2cache.prefetcher.vbop.reqFilter.alloc_1, u_g.inner_l2cache.prefetcher.vbop.reqFilter.alloc_0};
    if (g_io_l2_tlb_req_req_valid) pf_tlb_seen = 1;
    if (u_g.inner_l2cache.linkMonitor.Decoupled2LCredit_txreqLink.out_flitv_REG) armed[0] = 1;
    if (u_g.inner_l2cache.linkMonitor.Decoupled2LCredit_txrspLink.out_flitv_REG) armed[1] = 1;
    if (u_g.inner_l2cache.linkMonitor.Decoupled2LCredit_txdatLink.out_flitv_REG) armed[2] = 1;
    if ((&pf_alloc_seen) & pf_tlb_seen) armed[3] = 1;
  endtask

  `define CK(nm) begin checks++; if (g_``nm !== i_``nm) begin errors++; \
    if (errors <= 40) $display("[cycle %0d] MISMATCH %s golden=%h impl=%h", cyc, `"nm`", g_``nm, i_``nm); \
    end end
  task automatic check();
    `CK(auto_inner_buffers_out_a_valid)
    `CK(auto_inner_buffers_out_a_bits_opcode)
    `CK(auto_inner_buffers_out_a_bits_param)
    `CK(auto_inner_buffers_out_a_bits_size)
    `CK(auto_inner_buffers_out_a_bits_source)
    `CK(auto_inner_buffers_out_a_bits_address)
    `CK(auto_inner_buffers_out_a_bits_mask)
    `CK(auto_inner_buffers_out_a_bits_data)
    `CK(auto_inner_buffers_out_a_bits_corrupt)
    `CK(auto_inner_buffers_out_d_ready)
    `CK(auto_inner_buffers_in_a_ready)
    `CK(auto_inner_buffers_in_d_valid)
    `CK(auto_inner_buffers_in_d_bits_opcode)
    `CK(auto_inner_buffers_in_d_bits_param)
    `CK(auto_inner_buffers_in_d_bits_size)
    `CK(auto_inner_buffers_in_d_bits_source)
    `CK(auto_inner_buffers_in_d_bits_sink)
    `CK(auto_inner_buffers_in_d_bits_denied)
    `CK(auto_inner_buffers_in_d_bits_data)
    `CK(auto_inner_buffers_in_d_bits_corrupt)
    `CK(auto_inner_intBuffer_out_0)
    `CK(auto_inner_i_mmio_buffer_in_a_ready)
    `CK(auto_inner_i_mmio_buffer_in_d_valid)
    `CK(auto_inner_i_mmio_buffer_in_d_bits_opcode)
    `CK(auto_inner_i_mmio_buffer_in_d_bits_param)
    `CK(auto_inner_i_mmio_buffer_in_d_bits_size)
    `CK(auto_inner_i_mmio_buffer_in_d_bits_source)
    `CK(auto_inner_i_mmio_buffer_in_d_bits_sink)
    `CK(auto_inner_i_mmio_buffer_in_d_bits_denied)
    `CK(auto_inner_i_mmio_buffer_in_d_bits_data)
    `CK(auto_inner_i_mmio_buffer_in_d_bits_corrupt)
    `CK(auto_inner_ptw_to_l2_buffer_in_a_ready)
    `CK(auto_inner_ptw_to_l2_buffer_in_d_valid)
    `CK(auto_inner_ptw_to_l2_buffer_in_d_bits_opcode)
    `CK(auto_inner_ptw_to_l2_buffer_in_d_bits_param)
    `CK(auto_inner_ptw_to_l2_buffer_in_d_bits_size)
    `CK(auto_inner_ptw_to_l2_buffer_in_d_bits_source)
    `CK(auto_inner_ptw_to_l2_buffer_in_d_bits_sink)
    `CK(auto_inner_ptw_to_l2_buffer_in_d_bits_denied)
    `CK(auto_inner_ptw_to_l2_buffer_in_d_bits_data)
    `CK(auto_inner_ptw_to_l2_buffer_in_d_bits_corrupt)
    `CK(auto_inner_logger_in_1_a_ready)
    `CK(auto_inner_logger_in_1_d_valid)
    `CK(auto_inner_logger_in_1_d_bits_opcode)
    `CK(auto_inner_logger_in_1_d_bits_param)
    `CK(auto_inner_logger_in_1_d_bits_size)
    `CK(auto_inner_logger_in_1_d_bits_source)
    `CK(auto_inner_logger_in_1_d_bits_sink)
    `CK(auto_inner_logger_in_1_d_bits_denied)
    `CK(auto_inner_logger_in_1_d_bits_data)
    `CK(auto_inner_logger_in_1_d_bits_corrupt)
    `CK(auto_inner_logger_in_0_a_ready)
    `CK(auto_inner_logger_in_0_b_valid)
    `CK(auto_inner_logger_in_0_b_bits_opcode)
    `CK(auto_inner_logger_in_0_b_bits_param)
    `CK(auto_inner_logger_in_0_b_bits_size)
    `CK(auto_inner_logger_in_0_b_bits_source)
    `CK(auto_inner_logger_in_0_b_bits_address)
    `CK(auto_inner_logger_in_0_b_bits_mask)
    `CK(auto_inner_logger_in_0_b_bits_data)
    `CK(auto_inner_logger_in_0_b_bits_corrupt)
    `CK(auto_inner_logger_in_0_c_ready)
    `CK(auto_inner_logger_in_0_d_valid)
    `CK(auto_inner_logger_in_0_d_bits_opcode)
    `CK(auto_inner_logger_in_0_d_bits_param)
    `CK(auto_inner_logger_in_0_d_bits_size)
    `CK(auto_inner_logger_in_0_d_bits_source)
    `CK(auto_inner_logger_in_0_d_bits_sink)
    `CK(auto_inner_logger_in_0_d_bits_denied)
    `CK(auto_inner_logger_in_0_d_bits_echo_isKeyword)
    `CK(auto_inner_logger_in_0_d_bits_data)
    `CK(auto_inner_logger_in_0_d_bits_corrupt)
    `CK(auto_inner_logger_in_0_e_ready)
    `CK(auto_inner_beu_int_out_0)
    `CK(auto_inner_nmi_int_out_0)
    `CK(auto_inner_nmi_int_out_1)
    `CK(auto_inner_plic_int_out_1_0)
    `CK(auto_inner_plic_int_out_0_0)
    `CK(auto_inner_debug_int_out_0)
    `CK(auto_inner_clint_int_out_0)
    `CK(auto_inner_clint_int_out_1)
    `CK(io_reset_vector_toCore)
    `CK(io_hartId_toCore)
    `CK(io_msiInfo_toCore_valid)
    `CK(io_msiInfo_toCore_bits)
    `CK(io_msiAck_toTile)
    `CK(io_cpu_halt_toTile)
    `CK(io_cpu_critical_error_toTile)
    `CK(io_hartIsInReset_toTile)
    `CK(io_traceCoreInterface_fromCore_fromEncoder_enable)
    `CK(io_traceCoreInterface_fromCore_fromEncoder_stall)
    `CK(io_traceCoreInterface_toTile_toEncoder_priv)
    `CK(io_traceCoreInterface_toTile_toEncoder_mstatus)
    `CK(io_traceCoreInterface_toTile_toEncoder_trap_cause)
    `CK(io_traceCoreInterface_toTile_toEncoder_trap_tval)
    `CK(io_traceCoreInterface_toTile_toEncoder_groups_0_valid)
    `CK(io_traceCoreInterface_toTile_toEncoder_groups_0_bits_iaddr)
    `CK(io_traceCoreInterface_toTile_toEncoder_groups_0_bits_itype)
    `CK(io_traceCoreInterface_toTile_toEncoder_groups_0_bits_iretire)
    `CK(io_traceCoreInterface_toTile_toEncoder_groups_0_bits_ilastsize)
    `CK(io_traceCoreInterface_toTile_toEncoder_groups_1_valid)
    `CK(io_traceCoreInterface_toTile_toEncoder_groups_1_bits_iaddr)
    `CK(io_traceCoreInterface_toTile_toEncoder_groups_1_bits_itype)
    `CK(io_traceCoreInterface_toTile_toEncoder_groups_1_bits_iretire)
    `CK(io_traceCoreInterface_toTile_toEncoder_groups_1_bits_ilastsize)
    `CK(io_traceCoreInterface_toTile_toEncoder_groups_2_valid)
    `CK(io_traceCoreInterface_toTile_toEncoder_groups_2_bits_iaddr)
    `CK(io_traceCoreInterface_toTile_toEncoder_groups_2_bits_itype)
    `CK(io_traceCoreInterface_toTile_toEncoder_groups_2_bits_iretire)
    `CK(io_traceCoreInterface_toTile_toEncoder_groups_2_bits_ilastsize)
    `CK(io_debugTopDown_l2MissMatch)
    `CK(io_l2Miss)
    `CK(io_l3Miss_toCore)
    `CK(io_clintTime_toCore_valid)
    `CK(io_clintTime_toCore_bits)
    `CK(io_chi_txsactive)
    `CK(io_chi_syscoreq)
    `CK(io_chi_tx_linkactivereq)
    if (armed[0]) `CK(io_chi_tx_req_flitpend)
    if (armed[0]) `CK(io_chi_tx_req_flitv)
    if (armed[0]) `CK(io_chi_tx_req_flit)
    if (armed[1]) `CK(io_chi_tx_rsp_flitpend)
    if (armed[1]) `CK(io_chi_tx_rsp_flitv)
    if (armed[1]) `CK(io_chi_tx_rsp_flit)
    if (armed[2]) `CK(io_chi_tx_dat_flitpend)
    if (armed[2]) `CK(io_chi_tx_dat_flitv)
    if (armed[2]) `CK(io_chi_tx_dat_flit)
    `CK(io_chi_rx_linkactiveack)
    `CK(io_chi_rx_rsp_lcrdv)
    `CK(io_chi_rx_dat_lcrdv)
    `CK(io_chi_rx_snp_lcrdv)
    `CK(io_l2_tlb_req_req_valid)
    if (armed[3]) `CK(io_l2_tlb_req_req_bits_vaddr)
    if (armed[3]) `CK(io_l2_tlb_req_req_bits_cmd)
    if (armed[3]) `CK(io_l2_tlb_req_req_bits_kill)
    if (armed[3]) `CK(io_l2_tlb_req_req_bits_isPrefetch)
    if (armed[3]) `CK(io_l2_tlb_req_req_bits_no_translate)
    `CK(io_l2_hint_valid)
    `CK(io_l2_hint_bits_sourceId)
    `CK(io_l2_hint_bits_isKeyword)
    `CK(io_perfEvents_1_value)
    `CK(io_perfEvents_2_value)
    `CK(io_perfEvents_3_value)
    `CK(io_perfEvents_4_value)
    `CK(io_perfEvents_5_value)
    `CK(io_perfEvents_6_value)
    `CK(io_perfEvents_7_value)
    `CK(io_perfEvents_8_value)
    `CK(io_perfEvents_9_value)
    `CK(io_perfEvents_10_value)
    `CK(io_perfEvents_11_value)
    `CK(io_perfEvents_12_value)
    `CK(io_perfEvents_13_value)
    `CK(io_perfEvents_14_value)
    `CK(io_perfEvents_15_value)
    `CK(io_perfEvents_16_value)
    `CK(io_perfEvents_17_value)
    `CK(io_perfEvents_18_value)
    `CK(io_perfEvents_19_value)
    `CK(io_perfEvents_20_value)
    `CK(io_perfEvents_21_value)
    `CK(io_perfEvents_22_value)
    `CK(io_perfEvents_23_value)
    `CK(io_perfEvents_24_value)
    `CK(io_perfEvents_25_value)
    `CK(io_perfEvents_26_value)
    `CK(io_perfEvents_27_value)
    `CK(io_perfEvents_28_value)
    `CK(io_perfEvents_29_value)
    `CK(io_perfEvents_30_value)
    `CK(io_perfEvents_31_value)
    `CK(io_perfEvents_32_value)
    `CK(io_perfEvents_33_value)
    `CK(io_perfEvents_34_value)
    `CK(io_perfEvents_35_value)
    `CK(io_perfEvents_36_value)
    `CK(io_perfEvents_37_value)
    `CK(io_perfEvents_38_value)
    `CK(io_perfEvents_39_value)
    `CK(io_perfEvents_40_value)
    `CK(io_perfEvents_41_value)
    `CK(io_perfEvents_42_value)
    `CK(io_perfEvents_43_value)
    `CK(io_perfEvents_44_value)
    `CK(io_perfEvents_45_value)
    `CK(io_perfEvents_46_value)
    `CK(io_perfEvents_47_value)
    `CK(io_perfEvents_48_value)
    `CK(io_perfEvents_49_value)
    `CK(io_perfEvents_50_value)
    `CK(io_perfEvents_51_value)
    `CK(io_perfEvents_52_value)
    `CK(io_perfEvents_53_value)
    `CK(io_perfEvents_54_value)
    `CK(io_perfEvents_55_value)
    `CK(io_perfEvents_56_value)
    `CK(io_perfEvents_57_value)
    `CK(io_perfEvents_58_value)
    `CK(io_perfEvents_59_value)
    `CK(io_perfEvents_60_value)
    `CK(io_perfEvents_61_value)
    `CK(io_perfEvents_62_value)
    `CK(io_perfEvents_63_value)
    `CK(io_perfEvents_64_value)
    `CK(io_perfEvents_65_value)
    `CK(io_perfEvents_66_value)
    `CK(io_perfEvents_67_value)
    `CK(io_perfEvents_68_value)
  endtask

  longint cov [29];
  localparam string COV_NAME [29] = '{"hint 发出", "D 被 hint 挡住", "(信息)releaseSourceD", "TXREQ 可缓存发出", "TXREQ MMIO 发出", "TXREQ 被一致性挡住", "TXDAT 发出", "TXRSP 发出", "RXRSP 到 slice", "RXRSP 到 MMIO", "RXDAT 到 slice", "RXDAT 到 MMIO", "RXSNP 收下", "PCrdGrant 入队", "P-Credit 授出", "预取请求到 slice", "预取 train", "(信息)L2 TLB 请求", "l2Miss", "topDown MissMatch", "DCache A 收下", "DCache D 收下", "DCache B 发出", "ICache D 收下", "PTW D 收下", "外部 MMIO A 发出", "BEU 收到 L1 错误", "trace trap 锁存", "hartIsInReset"};
  localparam bit COV_INFO [29] = '{1'b0, 1'b0, 1'b1, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b1, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0};   // 1 = 只打印、不计入判据
  task automatic sample();
    if (u_g.inner_l2cache.hintFire) cov[0]++;
    if (u_g.inner_l2cache._slices_1_io_in_d_valid & ~(u_g.inner_l2cache.sliceCanFire_1 | u_g.inner_l2cache.allCanFire)) cov[1]++;
    if (u_g.inner_l2cache.releaseSourceD_2) cov[2]++;
    if (u_g.inner_l2cache._txreq_arb_io_out_valid & u_g.inner_l2cache._linkMonitor_io_in_tx_req_ready & u_g.inner_l2cache.req_pass & u_g.inner_l2cache._txreq_arb_io_chosen != 3'h4) cov[3]++;
    if (u_g.inner_l2cache._txreq_arb_io_out_valid & u_g.inner_l2cache._linkMonitor_io_in_tx_req_ready & u_g.inner_l2cache._txreq_arb_io_chosen == 3'h4) cov[4]++;
    if (u_g.inner_l2cache._txreq_arb_io_out_valid & ~u_g.inner_l2cache.req_pass) cov[5]++;
    if (g_io_chi_tx_dat_flitv) cov[6]++;
    if (g_io_chi_tx_rsp_flitv) cov[7]++;
    if (u_g.inner_l2cache._rxrspPipe_pipeline_io_out_valid & ~u_g.inner_l2cache._rxrspPipe_pipeline_io_out_bits_txnID[11] & ~u_g.inner_l2cache.isPCrdGrant) cov[8]++;
    if (u_g.inner_l2cache._rxrspPipe_pipeline_io_out_valid & u_g.inner_l2cache._rxrspPipe_pipeline_io_out_bits_txnID[11] & ~u_g.inner_l2cache.isPCrdGrant) cov[9]++;
    if (u_g.inner_l2cache._rxdatPipe_pipeline_io_out_valid & ~u_g.inner_l2cache._rxdatPipe_pipeline_io_out_bits_txnID[11]) cov[10]++;
    if (u_g.inner_l2cache._rxdatPipe_pipeline_io_out_valid & u_g.inner_l2cache._rxdatPipe_pipeline_io_out_bits_txnID[11]) cov[11]++;
    if (u_g.inner_l2cache._linkMonitor_io_in_rx_snp_valid & u_g.inner_l2cache._slices_0_io_out_rx_snp_ready) cov[12]++;
    if (u_g.inner_l2cache.pCrdGrantValid_s1) cov[13]++;
    if (u_g.inner_l2cache._pcrdgrant_arb_io_out_valid) cov[14]++;
    if (u_g.inner_l2cache._prefetcher_io_req_valid & (|{u_g.inner_l2cache.prefetchReqsReady_0, u_g.inner_l2cache.prefetchReqsReady_1, u_g.inner_l2cache.prefetchReqsReady_2, u_g.inner_l2cache.prefetchReqsReady_3})) cov[15]++;
    if (u_g.inner_l2cache._prefetch_train_arb_io_out_valid) cov[16]++;
    if (g_io_l2_tlb_req_req_valid) cov[17]++;
    if (g_io_l2Miss) cov[18]++;
    if (g_io_debugTopDown_l2MissMatch) cov[19]++;
    if (auto_inner_logger_in_0_a_valid & g_auto_inner_logger_in_0_a_ready) cov[20]++;
    if (g_auto_inner_logger_in_0_d_valid & auto_inner_logger_in_0_d_ready) cov[21]++;
    if (g_auto_inner_logger_in_0_b_valid & auto_inner_logger_in_0_b_ready) cov[22]++;
    if (g_auto_inner_logger_in_1_d_valid & auto_inner_logger_in_1_d_ready) cov[23]++;
    if (g_auto_inner_ptw_to_l2_buffer_in_d_valid & auto_inner_ptw_to_l2_buffer_in_d_ready) cov[24]++;
    if (g_auto_inner_buffers_out_a_valid & auto_inner_buffers_out_a_ready) cov[25]++;
    if (io_beu_errors_dcache_ecc_error_valid & ~g_io_hartIsInReset_toTile) cov[26]++;
    if (io_traceCoreInterface_fromCore_toEncoder_groups_0_valid & io_traceCoreInterface_fromCore_toEncoder_groups_0_bits_itype == 4'h1) cov[27]++;
    if (g_io_hartIsInReset_toTile) cov[28]++;
  endtask

  task automatic sync_init();
    force u_i.inner_l2cache.slices_0.u_core.mshrCtl.u_core.mshrs[0].entry.u_core.tgtid_rcompack = u_g.inner_l2cache.slices_0.mshrCtl.mshrs_0.tgtid_rcompack;
    force u_i.inner_l2cache.slices_0.u_core.mshrCtl.u_core.mshrs[0].entry.u_core.txnid_rcompack = u_g.inner_l2cache.slices_0.mshrCtl.mshrs_0.txnid_rcompack;
    force u_i.inner_l2cache.slices_0.u_core.mshrCtl.u_core.mshrs[0].entry.u_core.tgtid_wcompack = u_g.inner_l2cache.slices_0.mshrCtl.mshrs_0.tgtid_wcompack;
    force u_i.inner_l2cache.slices_0.u_core.mshrCtl.u_core.mshrs[0].entry.u_core.txnid_wcompack = u_g.inner_l2cache.slices_0.mshrCtl.mshrs_0.txnid_wcompack;
    force u_i.inner_l2cache.slices_0.u_core.mshrCtl.u_core.mshrs[0].entry.u_core.srcid_retryack = u_g.inner_l2cache.slices_0.mshrCtl.mshrs_0.srcid_retryack;
    force u_i.inner_l2cache.slices_0.u_core.mshrCtl.u_core.mshrs[0].entry.u_core.acquire_ts = u_g.inner_l2cache.slices_0.mshrCtl.mshrs_0.acquire_ts;
    force u_i.inner_l2cache.slices_0.u_core.mshrCtl.u_core.mshrs[0].entry.u_core.release_ts = u_g.inner_l2cache.slices_0.mshrCtl.mshrs_0.release_ts;
    force u_i.inner_l2cache.slices_0.u_core.mshrCtl.u_core.mshrs[0].entry.u_core.acquire_period_valid_REG = u_g.inner_l2cache.slices_0.mshrCtl.mshrs_0.acquire_period_valid_REG;
    force u_i.inner_l2cache.slices_0.u_core.mshrCtl.u_core.mshrs[0].entry.u_core.release_period_valid_REG = u_g.inner_l2cache.slices_0.mshrCtl.mshrs_0.release_period_valid_REG;
    force u_i.inner_l2cache.slices_0.u_core.mshrCtl.u_core.mshrs[0].entry.u_core.REG = u_g.inner_l2cache.slices_0.mshrCtl.mshrs_0.REG;
    force u_i.inner_l2cache.slices_0.u_core.mshrCtl.u_core.mshrs[0].entry.u_core.REG_1 = u_g.inner_l2cache.slices_0.mshrCtl.mshrs_0.REG_1;
    force u_i.inner_l2cache.slices_0.u_core.mshrCtl.u_core.mshrs[0].entry.u_core.REG_2 = u_g.inner_l2cache.slices_0.mshrCtl.mshrs_0.REG_2;
    force u_i.inner_l2cache.slices_0.u_core.mshrCtl.u_core.mshrs[0].entry.u_core.REG_3 = u_g.inner_l2cache.slices_0.mshrCtl.mshrs_0.REG_3;
    force u_i.inner_l2cache.slices_0.u_core.mshrCtl.u_core.mshrs[1].entry.u_core.tgtid_rcompack = u_g.inner_l2cache.slices_0.mshrCtl.mshrs_1.tgtid_rcompack;
    force u_i.inner_l2cache.slices_0.u_core.mshrCtl.u_core.mshrs[1].entry.u_core.txnid_rcompack = u_g.inner_l2cache.slices_0.mshrCtl.mshrs_1.txnid_rcompack;
    force u_i.inner_l2cache.slices_0.u_core.mshrCtl.u_core.mshrs[1].entry.u_core.tgtid_wcompack = u_g.inner_l2cache.slices_0.mshrCtl.mshrs_1.tgtid_wcompack;
    force u_i.inner_l2cache.slices_0.u_core.mshrCtl.u_core.mshrs[1].entry.u_core.txnid_wcompack = u_g.inner_l2cache.slices_0.mshrCtl.mshrs_1.txnid_wcompack;
    force u_i.inner_l2cache.slices_0.u_core.mshrCtl.u_core.mshrs[1].entry.u_core.srcid_retryack = u_g.inner_l2cache.slices_0.mshrCtl.mshrs_1.srcid_retryack;
    force u_i.inner_l2cache.slices_0.u_core.mshrCtl.u_core.mshrs[1].entry.u_core.acquire_ts = u_g.inner_l2cache.slices_0.mshrCtl.mshrs_1.acquire_ts;
    force u_i.inner_l2cache.slices_0.u_core.mshrCtl.u_core.mshrs[1].entry.u_core.release_ts = u_g.inner_l2cache.slices_0.mshrCtl.mshrs_1.release_ts;
    force u_i.inner_l2cache.slices_0.u_core.mshrCtl.u_core.mshrs[1].entry.u_core.acquire_period_valid_REG = u_g.inner_l2cache.slices_0.mshrCtl.mshrs_1.acquire_period_valid_REG;
    force u_i.inner_l2cache.slices_0.u_core.mshrCtl.u_core.mshrs[1].entry.u_core.release_period_valid_REG = u_g.inner_l2cache.slices_0.mshrCtl.mshrs_1.release_period_valid_REG;
    force u_i.inner_l2cache.slices_0.u_core.mshrCtl.u_core.mshrs[1].entry.u_core.REG = u_g.inner_l2cache.slices_0.mshrCtl.mshrs_1.REG;
    force u_i.inner_l2cache.slices_0.u_core.mshrCtl.u_core.mshrs[1].entry.u_core.REG_1 = u_g.inner_l2cache.slices_0.mshrCtl.mshrs_1.REG_1;
    force u_i.inner_l2cache.slices_0.u_core.mshrCtl.u_core.mshrs[1].entry.u_core.REG_2 = u_g.inner_l2cache.slices_0.mshrCtl.mshrs_1.REG_2;
    force u_i.inner_l2cache.slices_0.u_core.mshrCtl.u_core.mshrs[1].entry.u_core.REG_3 = u_g.inner_l2cache.slices_0.mshrCtl.mshrs_1.REG_3;
    force u_i.inner_l2cache.slices_0.u_core.mshrCtl.u_core.mshrs[2].entry.u_core.tgtid_rcompack = u_g.inner_l2cache.slices_0.mshrCtl.mshrs_2.tgtid_rcompack;
    force u_i.inner_l2cache.slices_0.u_core.mshrCtl.u_core.mshrs[2].entry.u_core.txnid_rcompack = u_g.inner_l2cache.slices_0.mshrCtl.mshrs_2.txnid_rcompack;
    force u_i.inner_l2cache.slices_0.u_core.mshrCtl.u_core.mshrs[2].entry.u_core.tgtid_wcompack = u_g.inner_l2cache.slices_0.mshrCtl.mshrs_2.tgtid_wcompack;
    force u_i.inner_l2cache.slices_0.u_core.mshrCtl.u_core.mshrs[2].entry.u_core.txnid_wcompack = u_g.inner_l2cache.slices_0.mshrCtl.mshrs_2.txnid_wcompack;
    force u_i.inner_l2cache.slices_0.u_core.mshrCtl.u_core.mshrs[2].entry.u_core.srcid_retryack = u_g.inner_l2cache.slices_0.mshrCtl.mshrs_2.srcid_retryack;
    force u_i.inner_l2cache.slices_0.u_core.mshrCtl.u_core.mshrs[2].entry.u_core.acquire_ts = u_g.inner_l2cache.slices_0.mshrCtl.mshrs_2.acquire_ts;
    force u_i.inner_l2cache.slices_0.u_core.mshrCtl.u_core.mshrs[2].entry.u_core.release_ts = u_g.inner_l2cache.slices_0.mshrCtl.mshrs_2.release_ts;
    force u_i.inner_l2cache.slices_0.u_core.mshrCtl.u_core.mshrs[2].entry.u_core.acquire_period_valid_REG = u_g.inner_l2cache.slices_0.mshrCtl.mshrs_2.acquire_period_valid_REG;
    force u_i.inner_l2cache.slices_0.u_core.mshrCtl.u_core.mshrs[2].entry.u_core.release_period_valid_REG = u_g.inner_l2cache.slices_0.mshrCtl.mshrs_2.release_period_valid_REG;
    force u_i.inner_l2cache.slices_0.u_core.mshrCtl.u_core.mshrs[2].entry.u_core.REG = u_g.inner_l2cache.slices_0.mshrCtl.mshrs_2.REG;
    force u_i.inner_l2cache.slices_0.u_core.mshrCtl.u_core.mshrs[2].entry.u_core.REG_1 = u_g.inner_l2cache.slices_0.mshrCtl.mshrs_2.REG_1;
    force u_i.inner_l2cache.slices_0.u_core.mshrCtl.u_core.mshrs[2].entry.u_core.REG_2 = u_g.inner_l2cache.slices_0.mshrCtl.mshrs_2.REG_2;
    force u_i.inner_l2cache.slices_0.u_core.mshrCtl.u_core.mshrs[2].entry.u_core.REG_3 = u_g.inner_l2cache.slices_0.mshrCtl.mshrs_2.REG_3;
    force u_i.inner_l2cache.slices_0.u_core.mshrCtl.u_core.mshrs[3].entry.u_core.tgtid_rcompack = u_g.inner_l2cache.slices_0.mshrCtl.mshrs_3.tgtid_rcompack;
    force u_i.inner_l2cache.slices_0.u_core.mshrCtl.u_core.mshrs[3].entry.u_core.txnid_rcompack = u_g.inner_l2cache.slices_0.mshrCtl.mshrs_3.txnid_rcompack;
    force u_i.inner_l2cache.slices_0.u_core.mshrCtl.u_core.mshrs[3].entry.u_core.tgtid_wcompack = u_g.inner_l2cache.slices_0.mshrCtl.mshrs_3.tgtid_wcompack;
    force u_i.inner_l2cache.slices_0.u_core.mshrCtl.u_core.mshrs[3].entry.u_core.txnid_wcompack = u_g.inner_l2cache.slices_0.mshrCtl.mshrs_3.txnid_wcompack;
    force u_i.inner_l2cache.slices_0.u_core.mshrCtl.u_core.mshrs[3].entry.u_core.srcid_retryack = u_g.inner_l2cache.slices_0.mshrCtl.mshrs_3.srcid_retryack;
    force u_i.inner_l2cache.slices_0.u_core.mshrCtl.u_core.mshrs[3].entry.u_core.acquire_ts = u_g.inner_l2cache.slices_0.mshrCtl.mshrs_3.acquire_ts;
    force u_i.inner_l2cache.slices_0.u_core.mshrCtl.u_core.mshrs[3].entry.u_core.release_ts = u_g.inner_l2cache.slices_0.mshrCtl.mshrs_3.release_ts;
    force u_i.inner_l2cache.slices_0.u_core.mshrCtl.u_core.mshrs[3].entry.u_core.acquire_period_valid_REG = u_g.inner_l2cache.slices_0.mshrCtl.mshrs_3.acquire_period_valid_REG;
    force u_i.inner_l2cache.slices_0.u_core.mshrCtl.u_core.mshrs[3].entry.u_core.release_period_valid_REG = u_g.inner_l2cache.slices_0.mshrCtl.mshrs_3.release_period_valid_REG;
    force u_i.inner_l2cache.slices_0.u_core.mshrCtl.u_core.mshrs[3].entry.u_core.REG = u_g.inner_l2cache.slices_0.mshrCtl.mshrs_3.REG;
    force u_i.inner_l2cache.slices_0.u_core.mshrCtl.u_core.mshrs[3].entry.u_core.REG_1 = u_g.inner_l2cache.slices_0.mshrCtl.mshrs_3.REG_1;
    force u_i.inner_l2cache.slices_0.u_core.mshrCtl.u_core.mshrs[3].entry.u_core.REG_2 = u_g.inner_l2cache.slices_0.mshrCtl.mshrs_3.REG_2;
    force u_i.inner_l2cache.slices_0.u_core.mshrCtl.u_core.mshrs[3].entry.u_core.REG_3 = u_g.inner_l2cache.slices_0.mshrCtl.mshrs_3.REG_3;
    force u_i.inner_l2cache.slices_0.u_core.mshrCtl.u_core.mshrs[4].entry.u_core.tgtid_rcompack = u_g.inner_l2cache.slices_0.mshrCtl.mshrs_4.tgtid_rcompack;
    force u_i.inner_l2cache.slices_0.u_core.mshrCtl.u_core.mshrs[4].entry.u_core.txnid_rcompack = u_g.inner_l2cache.slices_0.mshrCtl.mshrs_4.txnid_rcompack;
    force u_i.inner_l2cache.slices_0.u_core.mshrCtl.u_core.mshrs[4].entry.u_core.tgtid_wcompack = u_g.inner_l2cache.slices_0.mshrCtl.mshrs_4.tgtid_wcompack;
    force u_i.inner_l2cache.slices_0.u_core.mshrCtl.u_core.mshrs[4].entry.u_core.txnid_wcompack = u_g.inner_l2cache.slices_0.mshrCtl.mshrs_4.txnid_wcompack;
    force u_i.inner_l2cache.slices_0.u_core.mshrCtl.u_core.mshrs[4].entry.u_core.srcid_retryack = u_g.inner_l2cache.slices_0.mshrCtl.mshrs_4.srcid_retryack;
    force u_i.inner_l2cache.slices_0.u_core.mshrCtl.u_core.mshrs[4].entry.u_core.acquire_ts = u_g.inner_l2cache.slices_0.mshrCtl.mshrs_4.acquire_ts;
    force u_i.inner_l2cache.slices_0.u_core.mshrCtl.u_core.mshrs[4].entry.u_core.release_ts = u_g.inner_l2cache.slices_0.mshrCtl.mshrs_4.release_ts;
    force u_i.inner_l2cache.slices_0.u_core.mshrCtl.u_core.mshrs[4].entry.u_core.acquire_period_valid_REG = u_g.inner_l2cache.slices_0.mshrCtl.mshrs_4.acquire_period_valid_REG;
    force u_i.inner_l2cache.slices_0.u_core.mshrCtl.u_core.mshrs[4].entry.u_core.release_period_valid_REG = u_g.inner_l2cache.slices_0.mshrCtl.mshrs_4.release_period_valid_REG;
    force u_i.inner_l2cache.slices_0.u_core.mshrCtl.u_core.mshrs[4].entry.u_core.REG = u_g.inner_l2cache.slices_0.mshrCtl.mshrs_4.REG;
    force u_i.inner_l2cache.slices_0.u_core.mshrCtl.u_core.mshrs[4].entry.u_core.REG_1 = u_g.inner_l2cache.slices_0.mshrCtl.mshrs_4.REG_1;
    force u_i.inner_l2cache.slices_0.u_core.mshrCtl.u_core.mshrs[4].entry.u_core.REG_2 = u_g.inner_l2cache.slices_0.mshrCtl.mshrs_4.REG_2;
    force u_i.inner_l2cache.slices_0.u_core.mshrCtl.u_core.mshrs[4].entry.u_core.REG_3 = u_g.inner_l2cache.slices_0.mshrCtl.mshrs_4.REG_3;
    force u_i.inner_l2cache.slices_0.u_core.mshrCtl.u_core.mshrs[5].entry.u_core.tgtid_rcompack = u_g.inner_l2cache.slices_0.mshrCtl.mshrs_5.tgtid_rcompack;
    force u_i.inner_l2cache.slices_0.u_core.mshrCtl.u_core.mshrs[5].entry.u_core.txnid_rcompack = u_g.inner_l2cache.slices_0.mshrCtl.mshrs_5.txnid_rcompack;
    force u_i.inner_l2cache.slices_0.u_core.mshrCtl.u_core.mshrs[5].entry.u_core.tgtid_wcompack = u_g.inner_l2cache.slices_0.mshrCtl.mshrs_5.tgtid_wcompack;
    force u_i.inner_l2cache.slices_0.u_core.mshrCtl.u_core.mshrs[5].entry.u_core.txnid_wcompack = u_g.inner_l2cache.slices_0.mshrCtl.mshrs_5.txnid_wcompack;
    force u_i.inner_l2cache.slices_0.u_core.mshrCtl.u_core.mshrs[5].entry.u_core.srcid_retryack = u_g.inner_l2cache.slices_0.mshrCtl.mshrs_5.srcid_retryack;
    force u_i.inner_l2cache.slices_0.u_core.mshrCtl.u_core.mshrs[5].entry.u_core.acquire_ts = u_g.inner_l2cache.slices_0.mshrCtl.mshrs_5.acquire_ts;
    force u_i.inner_l2cache.slices_0.u_core.mshrCtl.u_core.mshrs[5].entry.u_core.release_ts = u_g.inner_l2cache.slices_0.mshrCtl.mshrs_5.release_ts;
    force u_i.inner_l2cache.slices_0.u_core.mshrCtl.u_core.mshrs[5].entry.u_core.acquire_period_valid_REG = u_g.inner_l2cache.slices_0.mshrCtl.mshrs_5.acquire_period_valid_REG;
    force u_i.inner_l2cache.slices_0.u_core.mshrCtl.u_core.mshrs[5].entry.u_core.release_period_valid_REG = u_g.inner_l2cache.slices_0.mshrCtl.mshrs_5.release_period_valid_REG;
    force u_i.inner_l2cache.slices_0.u_core.mshrCtl.u_core.mshrs[5].entry.u_core.REG = u_g.inner_l2cache.slices_0.mshrCtl.mshrs_5.REG;
    force u_i.inner_l2cache.slices_0.u_core.mshrCtl.u_core.mshrs[5].entry.u_core.REG_1 = u_g.inner_l2cache.slices_0.mshrCtl.mshrs_5.REG_1;
    force u_i.inner_l2cache.slices_0.u_core.mshrCtl.u_core.mshrs[5].entry.u_core.REG_2 = u_g.inner_l2cache.slices_0.mshrCtl.mshrs_5.REG_2;
    force u_i.inner_l2cache.slices_0.u_core.mshrCtl.u_core.mshrs[5].entry.u_core.REG_3 = u_g.inner_l2cache.slices_0.mshrCtl.mshrs_5.REG_3;
    force u_i.inner_l2cache.slices_0.u_core.mshrCtl.u_core.mshrs[6].entry.u_core.tgtid_rcompack = u_g.inner_l2cache.slices_0.mshrCtl.mshrs_6.tgtid_rcompack;
    force u_i.inner_l2cache.slices_0.u_core.mshrCtl.u_core.mshrs[6].entry.u_core.txnid_rcompack = u_g.inner_l2cache.slices_0.mshrCtl.mshrs_6.txnid_rcompack;
    force u_i.inner_l2cache.slices_0.u_core.mshrCtl.u_core.mshrs[6].entry.u_core.tgtid_wcompack = u_g.inner_l2cache.slices_0.mshrCtl.mshrs_6.tgtid_wcompack;
    force u_i.inner_l2cache.slices_0.u_core.mshrCtl.u_core.mshrs[6].entry.u_core.txnid_wcompack = u_g.inner_l2cache.slices_0.mshrCtl.mshrs_6.txnid_wcompack;
    force u_i.inner_l2cache.slices_0.u_core.mshrCtl.u_core.mshrs[6].entry.u_core.srcid_retryack = u_g.inner_l2cache.slices_0.mshrCtl.mshrs_6.srcid_retryack;
    force u_i.inner_l2cache.slices_0.u_core.mshrCtl.u_core.mshrs[6].entry.u_core.acquire_ts = u_g.inner_l2cache.slices_0.mshrCtl.mshrs_6.acquire_ts;
    force u_i.inner_l2cache.slices_0.u_core.mshrCtl.u_core.mshrs[6].entry.u_core.release_ts = u_g.inner_l2cache.slices_0.mshrCtl.mshrs_6.release_ts;
    force u_i.inner_l2cache.slices_0.u_core.mshrCtl.u_core.mshrs[6].entry.u_core.acquire_period_valid_REG = u_g.inner_l2cache.slices_0.mshrCtl.mshrs_6.acquire_period_valid_REG;
    force u_i.inner_l2cache.slices_0.u_core.mshrCtl.u_core.mshrs[6].entry.u_core.release_period_valid_REG = u_g.inner_l2cache.slices_0.mshrCtl.mshrs_6.release_period_valid_REG;
    force u_i.inner_l2cache.slices_0.u_core.mshrCtl.u_core.mshrs[6].entry.u_core.REG = u_g.inner_l2cache.slices_0.mshrCtl.mshrs_6.REG;
    force u_i.inner_l2cache.slices_0.u_core.mshrCtl.u_core.mshrs[6].entry.u_core.REG_1 = u_g.inner_l2cache.slices_0.mshrCtl.mshrs_6.REG_1;
    force u_i.inner_l2cache.slices_0.u_core.mshrCtl.u_core.mshrs[6].entry.u_core.REG_2 = u_g.inner_l2cache.slices_0.mshrCtl.mshrs_6.REG_2;
    force u_i.inner_l2cache.slices_0.u_core.mshrCtl.u_core.mshrs[6].entry.u_core.REG_3 = u_g.inner_l2cache.slices_0.mshrCtl.mshrs_6.REG_3;
    force u_i.inner_l2cache.slices_0.u_core.mshrCtl.u_core.mshrs[7].entry.u_core.tgtid_rcompack = u_g.inner_l2cache.slices_0.mshrCtl.mshrs_7.tgtid_rcompack;
    force u_i.inner_l2cache.slices_0.u_core.mshrCtl.u_core.mshrs[7].entry.u_core.txnid_rcompack = u_g.inner_l2cache.slices_0.mshrCtl.mshrs_7.txnid_rcompack;
    force u_i.inner_l2cache.slices_0.u_core.mshrCtl.u_core.mshrs[7].entry.u_core.tgtid_wcompack = u_g.inner_l2cache.slices_0.mshrCtl.mshrs_7.tgtid_wcompack;
    force u_i.inner_l2cache.slices_0.u_core.mshrCtl.u_core.mshrs[7].entry.u_core.txnid_wcompack = u_g.inner_l2cache.slices_0.mshrCtl.mshrs_7.txnid_wcompack;
    force u_i.inner_l2cache.slices_0.u_core.mshrCtl.u_core.mshrs[7].entry.u_core.srcid_retryack = u_g.inner_l2cache.slices_0.mshrCtl.mshrs_7.srcid_retryack;
    force u_i.inner_l2cache.slices_0.u_core.mshrCtl.u_core.mshrs[7].entry.u_core.acquire_ts = u_g.inner_l2cache.slices_0.mshrCtl.mshrs_7.acquire_ts;
    force u_i.inner_l2cache.slices_0.u_core.mshrCtl.u_core.mshrs[7].entry.u_core.release_ts = u_g.inner_l2cache.slices_0.mshrCtl.mshrs_7.release_ts;
    force u_i.inner_l2cache.slices_0.u_core.mshrCtl.u_core.mshrs[7].entry.u_core.acquire_period_valid_REG = u_g.inner_l2cache.slices_0.mshrCtl.mshrs_7.acquire_period_valid_REG;
    force u_i.inner_l2cache.slices_0.u_core.mshrCtl.u_core.mshrs[7].entry.u_core.release_period_valid_REG = u_g.inner_l2cache.slices_0.mshrCtl.mshrs_7.release_period_valid_REG;
    force u_i.inner_l2cache.slices_0.u_core.mshrCtl.u_core.mshrs[7].entry.u_core.REG = u_g.inner_l2cache.slices_0.mshrCtl.mshrs_7.REG;
    force u_i.inner_l2cache.slices_0.u_core.mshrCtl.u_core.mshrs[7].entry.u_core.REG_1 = u_g.inner_l2cache.slices_0.mshrCtl.mshrs_7.REG_1;
    force u_i.inner_l2cache.slices_0.u_core.mshrCtl.u_core.mshrs[7].entry.u_core.REG_2 = u_g.inner_l2cache.slices_0.mshrCtl.mshrs_7.REG_2;
    force u_i.inner_l2cache.slices_0.u_core.mshrCtl.u_core.mshrs[7].entry.u_core.REG_3 = u_g.inner_l2cache.slices_0.mshrCtl.mshrs_7.REG_3;
    force u_i.inner_l2cache.slices_0.u_core.mshrCtl.u_core.mshrs[8].entry.u_core.tgtid_rcompack = u_g.inner_l2cache.slices_0.mshrCtl.mshrs_8.tgtid_rcompack;
    force u_i.inner_l2cache.slices_0.u_core.mshrCtl.u_core.mshrs[8].entry.u_core.txnid_rcompack = u_g.inner_l2cache.slices_0.mshrCtl.mshrs_8.txnid_rcompack;
    force u_i.inner_l2cache.slices_0.u_core.mshrCtl.u_core.mshrs[8].entry.u_core.tgtid_wcompack = u_g.inner_l2cache.slices_0.mshrCtl.mshrs_8.tgtid_wcompack;
    force u_i.inner_l2cache.slices_0.u_core.mshrCtl.u_core.mshrs[8].entry.u_core.txnid_wcompack = u_g.inner_l2cache.slices_0.mshrCtl.mshrs_8.txnid_wcompack;
    force u_i.inner_l2cache.slices_0.u_core.mshrCtl.u_core.mshrs[8].entry.u_core.srcid_retryack = u_g.inner_l2cache.slices_0.mshrCtl.mshrs_8.srcid_retryack;
    force u_i.inner_l2cache.slices_0.u_core.mshrCtl.u_core.mshrs[8].entry.u_core.acquire_ts = u_g.inner_l2cache.slices_0.mshrCtl.mshrs_8.acquire_ts;
    force u_i.inner_l2cache.slices_0.u_core.mshrCtl.u_core.mshrs[8].entry.u_core.release_ts = u_g.inner_l2cache.slices_0.mshrCtl.mshrs_8.release_ts;
    force u_i.inner_l2cache.slices_0.u_core.mshrCtl.u_core.mshrs[8].entry.u_core.acquire_period_valid_REG = u_g.inner_l2cache.slices_0.mshrCtl.mshrs_8.acquire_period_valid_REG;
    force u_i.inner_l2cache.slices_0.u_core.mshrCtl.u_core.mshrs[8].entry.u_core.release_period_valid_REG = u_g.inner_l2cache.slices_0.mshrCtl.mshrs_8.release_period_valid_REG;
    force u_i.inner_l2cache.slices_0.u_core.mshrCtl.u_core.mshrs[8].entry.u_core.REG = u_g.inner_l2cache.slices_0.mshrCtl.mshrs_8.REG;
    force u_i.inner_l2cache.slices_0.u_core.mshrCtl.u_core.mshrs[8].entry.u_core.REG_1 = u_g.inner_l2cache.slices_0.mshrCtl.mshrs_8.REG_1;
    force u_i.inner_l2cache.slices_0.u_core.mshrCtl.u_core.mshrs[8].entry.u_core.REG_2 = u_g.inner_l2cache.slices_0.mshrCtl.mshrs_8.REG_2;
    force u_i.inner_l2cache.slices_0.u_core.mshrCtl.u_core.mshrs[8].entry.u_core.REG_3 = u_g.inner_l2cache.slices_0.mshrCtl.mshrs_8.REG_3;
    force u_i.inner_l2cache.slices_0.u_core.mshrCtl.u_core.mshrs[9].entry.u_core.tgtid_rcompack = u_g.inner_l2cache.slices_0.mshrCtl.mshrs_9.tgtid_rcompack;
    force u_i.inner_l2cache.slices_0.u_core.mshrCtl.u_core.mshrs[9].entry.u_core.txnid_rcompack = u_g.inner_l2cache.slices_0.mshrCtl.mshrs_9.txnid_rcompack;
    force u_i.inner_l2cache.slices_0.u_core.mshrCtl.u_core.mshrs[9].entry.u_core.tgtid_wcompack = u_g.inner_l2cache.slices_0.mshrCtl.mshrs_9.tgtid_wcompack;
    force u_i.inner_l2cache.slices_0.u_core.mshrCtl.u_core.mshrs[9].entry.u_core.txnid_wcompack = u_g.inner_l2cache.slices_0.mshrCtl.mshrs_9.txnid_wcompack;
    force u_i.inner_l2cache.slices_0.u_core.mshrCtl.u_core.mshrs[9].entry.u_core.srcid_retryack = u_g.inner_l2cache.slices_0.mshrCtl.mshrs_9.srcid_retryack;
    force u_i.inner_l2cache.slices_0.u_core.mshrCtl.u_core.mshrs[9].entry.u_core.acquire_ts = u_g.inner_l2cache.slices_0.mshrCtl.mshrs_9.acquire_ts;
    force u_i.inner_l2cache.slices_0.u_core.mshrCtl.u_core.mshrs[9].entry.u_core.release_ts = u_g.inner_l2cache.slices_0.mshrCtl.mshrs_9.release_ts;
    force u_i.inner_l2cache.slices_0.u_core.mshrCtl.u_core.mshrs[9].entry.u_core.acquire_period_valid_REG = u_g.inner_l2cache.slices_0.mshrCtl.mshrs_9.acquire_period_valid_REG;
    force u_i.inner_l2cache.slices_0.u_core.mshrCtl.u_core.mshrs[9].entry.u_core.release_period_valid_REG = u_g.inner_l2cache.slices_0.mshrCtl.mshrs_9.release_period_valid_REG;
    force u_i.inner_l2cache.slices_0.u_core.mshrCtl.u_core.mshrs[9].entry.u_core.REG = u_g.inner_l2cache.slices_0.mshrCtl.mshrs_9.REG;
    force u_i.inner_l2cache.slices_0.u_core.mshrCtl.u_core.mshrs[9].entry.u_core.REG_1 = u_g.inner_l2cache.slices_0.mshrCtl.mshrs_9.REG_1;
    force u_i.inner_l2cache.slices_0.u_core.mshrCtl.u_core.mshrs[9].entry.u_core.REG_2 = u_g.inner_l2cache.slices_0.mshrCtl.mshrs_9.REG_2;
    force u_i.inner_l2cache.slices_0.u_core.mshrCtl.u_core.mshrs[9].entry.u_core.REG_3 = u_g.inner_l2cache.slices_0.mshrCtl.mshrs_9.REG_3;
    force u_i.inner_l2cache.slices_0.u_core.mshrCtl.u_core.mshrs[10].entry.u_core.tgtid_rcompack = u_g.inner_l2cache.slices_0.mshrCtl.mshrs_10.tgtid_rcompack;
    force u_i.inner_l2cache.slices_0.u_core.mshrCtl.u_core.mshrs[10].entry.u_core.txnid_rcompack = u_g.inner_l2cache.slices_0.mshrCtl.mshrs_10.txnid_rcompack;
    force u_i.inner_l2cache.slices_0.u_core.mshrCtl.u_core.mshrs[10].entry.u_core.tgtid_wcompack = u_g.inner_l2cache.slices_0.mshrCtl.mshrs_10.tgtid_wcompack;
    force u_i.inner_l2cache.slices_0.u_core.mshrCtl.u_core.mshrs[10].entry.u_core.txnid_wcompack = u_g.inner_l2cache.slices_0.mshrCtl.mshrs_10.txnid_wcompack;
    force u_i.inner_l2cache.slices_0.u_core.mshrCtl.u_core.mshrs[10].entry.u_core.srcid_retryack = u_g.inner_l2cache.slices_0.mshrCtl.mshrs_10.srcid_retryack;
    force u_i.inner_l2cache.slices_0.u_core.mshrCtl.u_core.mshrs[10].entry.u_core.acquire_ts = u_g.inner_l2cache.slices_0.mshrCtl.mshrs_10.acquire_ts;
    force u_i.inner_l2cache.slices_0.u_core.mshrCtl.u_core.mshrs[10].entry.u_core.release_ts = u_g.inner_l2cache.slices_0.mshrCtl.mshrs_10.release_ts;
    force u_i.inner_l2cache.slices_0.u_core.mshrCtl.u_core.mshrs[10].entry.u_core.acquire_period_valid_REG = u_g.inner_l2cache.slices_0.mshrCtl.mshrs_10.acquire_period_valid_REG;
    force u_i.inner_l2cache.slices_0.u_core.mshrCtl.u_core.mshrs[10].entry.u_core.release_period_valid_REG = u_g.inner_l2cache.slices_0.mshrCtl.mshrs_10.release_period_valid_REG;
    force u_i.inner_l2cache.slices_0.u_core.mshrCtl.u_core.mshrs[10].entry.u_core.REG = u_g.inner_l2cache.slices_0.mshrCtl.mshrs_10.REG;
    force u_i.inner_l2cache.slices_0.u_core.mshrCtl.u_core.mshrs[10].entry.u_core.REG_1 = u_g.inner_l2cache.slices_0.mshrCtl.mshrs_10.REG_1;
    force u_i.inner_l2cache.slices_0.u_core.mshrCtl.u_core.mshrs[10].entry.u_core.REG_2 = u_g.inner_l2cache.slices_0.mshrCtl.mshrs_10.REG_2;
    force u_i.inner_l2cache.slices_0.u_core.mshrCtl.u_core.mshrs[10].entry.u_core.REG_3 = u_g.inner_l2cache.slices_0.mshrCtl.mshrs_10.REG_3;
    force u_i.inner_l2cache.slices_0.u_core.mshrCtl.u_core.mshrs[11].entry.u_core.tgtid_rcompack = u_g.inner_l2cache.slices_0.mshrCtl.mshrs_11.tgtid_rcompack;
    force u_i.inner_l2cache.slices_0.u_core.mshrCtl.u_core.mshrs[11].entry.u_core.txnid_rcompack = u_g.inner_l2cache.slices_0.mshrCtl.mshrs_11.txnid_rcompack;
    force u_i.inner_l2cache.slices_0.u_core.mshrCtl.u_core.mshrs[11].entry.u_core.tgtid_wcompack = u_g.inner_l2cache.slices_0.mshrCtl.mshrs_11.tgtid_wcompack;
    force u_i.inner_l2cache.slices_0.u_core.mshrCtl.u_core.mshrs[11].entry.u_core.txnid_wcompack = u_g.inner_l2cache.slices_0.mshrCtl.mshrs_11.txnid_wcompack;
    force u_i.inner_l2cache.slices_0.u_core.mshrCtl.u_core.mshrs[11].entry.u_core.srcid_retryack = u_g.inner_l2cache.slices_0.mshrCtl.mshrs_11.srcid_retryack;
    force u_i.inner_l2cache.slices_0.u_core.mshrCtl.u_core.mshrs[11].entry.u_core.acquire_ts = u_g.inner_l2cache.slices_0.mshrCtl.mshrs_11.acquire_ts;
    force u_i.inner_l2cache.slices_0.u_core.mshrCtl.u_core.mshrs[11].entry.u_core.release_ts = u_g.inner_l2cache.slices_0.mshrCtl.mshrs_11.release_ts;
    force u_i.inner_l2cache.slices_0.u_core.mshrCtl.u_core.mshrs[11].entry.u_core.acquire_period_valid_REG = u_g.inner_l2cache.slices_0.mshrCtl.mshrs_11.acquire_period_valid_REG;
    force u_i.inner_l2cache.slices_0.u_core.mshrCtl.u_core.mshrs[11].entry.u_core.release_period_valid_REG = u_g.inner_l2cache.slices_0.mshrCtl.mshrs_11.release_period_valid_REG;
    force u_i.inner_l2cache.slices_0.u_core.mshrCtl.u_core.mshrs[11].entry.u_core.REG = u_g.inner_l2cache.slices_0.mshrCtl.mshrs_11.REG;
    force u_i.inner_l2cache.slices_0.u_core.mshrCtl.u_core.mshrs[11].entry.u_core.REG_1 = u_g.inner_l2cache.slices_0.mshrCtl.mshrs_11.REG_1;
    force u_i.inner_l2cache.slices_0.u_core.mshrCtl.u_core.mshrs[11].entry.u_core.REG_2 = u_g.inner_l2cache.slices_0.mshrCtl.mshrs_11.REG_2;
    force u_i.inner_l2cache.slices_0.u_core.mshrCtl.u_core.mshrs[11].entry.u_core.REG_3 = u_g.inner_l2cache.slices_0.mshrCtl.mshrs_11.REG_3;
    force u_i.inner_l2cache.slices_0.u_core.mshrCtl.u_core.mshrs[12].entry.u_core.tgtid_rcompack = u_g.inner_l2cache.slices_0.mshrCtl.mshrs_12.tgtid_rcompack;
    force u_i.inner_l2cache.slices_0.u_core.mshrCtl.u_core.mshrs[12].entry.u_core.txnid_rcompack = u_g.inner_l2cache.slices_0.mshrCtl.mshrs_12.txnid_rcompack;
    force u_i.inner_l2cache.slices_0.u_core.mshrCtl.u_core.mshrs[12].entry.u_core.tgtid_wcompack = u_g.inner_l2cache.slices_0.mshrCtl.mshrs_12.tgtid_wcompack;
    force u_i.inner_l2cache.slices_0.u_core.mshrCtl.u_core.mshrs[12].entry.u_core.txnid_wcompack = u_g.inner_l2cache.slices_0.mshrCtl.mshrs_12.txnid_wcompack;
    force u_i.inner_l2cache.slices_0.u_core.mshrCtl.u_core.mshrs[12].entry.u_core.srcid_retryack = u_g.inner_l2cache.slices_0.mshrCtl.mshrs_12.srcid_retryack;
    force u_i.inner_l2cache.slices_0.u_core.mshrCtl.u_core.mshrs[12].entry.u_core.acquire_ts = u_g.inner_l2cache.slices_0.mshrCtl.mshrs_12.acquire_ts;
    force u_i.inner_l2cache.slices_0.u_core.mshrCtl.u_core.mshrs[12].entry.u_core.release_ts = u_g.inner_l2cache.slices_0.mshrCtl.mshrs_12.release_ts;
    force u_i.inner_l2cache.slices_0.u_core.mshrCtl.u_core.mshrs[12].entry.u_core.acquire_period_valid_REG = u_g.inner_l2cache.slices_0.mshrCtl.mshrs_12.acquire_period_valid_REG;
    force u_i.inner_l2cache.slices_0.u_core.mshrCtl.u_core.mshrs[12].entry.u_core.release_period_valid_REG = u_g.inner_l2cache.slices_0.mshrCtl.mshrs_12.release_period_valid_REG;
    force u_i.inner_l2cache.slices_0.u_core.mshrCtl.u_core.mshrs[12].entry.u_core.REG = u_g.inner_l2cache.slices_0.mshrCtl.mshrs_12.REG;
    force u_i.inner_l2cache.slices_0.u_core.mshrCtl.u_core.mshrs[12].entry.u_core.REG_1 = u_g.inner_l2cache.slices_0.mshrCtl.mshrs_12.REG_1;
    force u_i.inner_l2cache.slices_0.u_core.mshrCtl.u_core.mshrs[12].entry.u_core.REG_2 = u_g.inner_l2cache.slices_0.mshrCtl.mshrs_12.REG_2;
    force u_i.inner_l2cache.slices_0.u_core.mshrCtl.u_core.mshrs[12].entry.u_core.REG_3 = u_g.inner_l2cache.slices_0.mshrCtl.mshrs_12.REG_3;
    force u_i.inner_l2cache.slices_0.u_core.mshrCtl.u_core.mshrs[13].entry.u_core.tgtid_rcompack = u_g.inner_l2cache.slices_0.mshrCtl.mshrs_13.tgtid_rcompack;
    force u_i.inner_l2cache.slices_0.u_core.mshrCtl.u_core.mshrs[13].entry.u_core.txnid_rcompack = u_g.inner_l2cache.slices_0.mshrCtl.mshrs_13.txnid_rcompack;
    force u_i.inner_l2cache.slices_0.u_core.mshrCtl.u_core.mshrs[13].entry.u_core.tgtid_wcompack = u_g.inner_l2cache.slices_0.mshrCtl.mshrs_13.tgtid_wcompack;
    force u_i.inner_l2cache.slices_0.u_core.mshrCtl.u_core.mshrs[13].entry.u_core.txnid_wcompack = u_g.inner_l2cache.slices_0.mshrCtl.mshrs_13.txnid_wcompack;
    force u_i.inner_l2cache.slices_0.u_core.mshrCtl.u_core.mshrs[13].entry.u_core.srcid_retryack = u_g.inner_l2cache.slices_0.mshrCtl.mshrs_13.srcid_retryack;
    force u_i.inner_l2cache.slices_0.u_core.mshrCtl.u_core.mshrs[13].entry.u_core.acquire_ts = u_g.inner_l2cache.slices_0.mshrCtl.mshrs_13.acquire_ts;
    force u_i.inner_l2cache.slices_0.u_core.mshrCtl.u_core.mshrs[13].entry.u_core.release_ts = u_g.inner_l2cache.slices_0.mshrCtl.mshrs_13.release_ts;
    force u_i.inner_l2cache.slices_0.u_core.mshrCtl.u_core.mshrs[13].entry.u_core.acquire_period_valid_REG = u_g.inner_l2cache.slices_0.mshrCtl.mshrs_13.acquire_period_valid_REG;
    force u_i.inner_l2cache.slices_0.u_core.mshrCtl.u_core.mshrs[13].entry.u_core.release_period_valid_REG = u_g.inner_l2cache.slices_0.mshrCtl.mshrs_13.release_period_valid_REG;
    force u_i.inner_l2cache.slices_0.u_core.mshrCtl.u_core.mshrs[13].entry.u_core.REG = u_g.inner_l2cache.slices_0.mshrCtl.mshrs_13.REG;
    force u_i.inner_l2cache.slices_0.u_core.mshrCtl.u_core.mshrs[13].entry.u_core.REG_1 = u_g.inner_l2cache.slices_0.mshrCtl.mshrs_13.REG_1;
    force u_i.inner_l2cache.slices_0.u_core.mshrCtl.u_core.mshrs[13].entry.u_core.REG_2 = u_g.inner_l2cache.slices_0.mshrCtl.mshrs_13.REG_2;
    force u_i.inner_l2cache.slices_0.u_core.mshrCtl.u_core.mshrs[13].entry.u_core.REG_3 = u_g.inner_l2cache.slices_0.mshrCtl.mshrs_13.REG_3;
    force u_i.inner_l2cache.slices_0.u_core.mshrCtl.u_core.mshrs[14].entry.u_core.tgtid_rcompack = u_g.inner_l2cache.slices_0.mshrCtl.mshrs_14.tgtid_rcompack;
    force u_i.inner_l2cache.slices_0.u_core.mshrCtl.u_core.mshrs[14].entry.u_core.txnid_rcompack = u_g.inner_l2cache.slices_0.mshrCtl.mshrs_14.txnid_rcompack;
    force u_i.inner_l2cache.slices_0.u_core.mshrCtl.u_core.mshrs[14].entry.u_core.tgtid_wcompack = u_g.inner_l2cache.slices_0.mshrCtl.mshrs_14.tgtid_wcompack;
    force u_i.inner_l2cache.slices_0.u_core.mshrCtl.u_core.mshrs[14].entry.u_core.txnid_wcompack = u_g.inner_l2cache.slices_0.mshrCtl.mshrs_14.txnid_wcompack;
    force u_i.inner_l2cache.slices_0.u_core.mshrCtl.u_core.mshrs[14].entry.u_core.srcid_retryack = u_g.inner_l2cache.slices_0.mshrCtl.mshrs_14.srcid_retryack;
    force u_i.inner_l2cache.slices_0.u_core.mshrCtl.u_core.mshrs[14].entry.u_core.acquire_ts = u_g.inner_l2cache.slices_0.mshrCtl.mshrs_14.acquire_ts;
    force u_i.inner_l2cache.slices_0.u_core.mshrCtl.u_core.mshrs[14].entry.u_core.release_ts = u_g.inner_l2cache.slices_0.mshrCtl.mshrs_14.release_ts;
    force u_i.inner_l2cache.slices_0.u_core.mshrCtl.u_core.mshrs[14].entry.u_core.acquire_period_valid_REG = u_g.inner_l2cache.slices_0.mshrCtl.mshrs_14.acquire_period_valid_REG;
    force u_i.inner_l2cache.slices_0.u_core.mshrCtl.u_core.mshrs[14].entry.u_core.release_period_valid_REG = u_g.inner_l2cache.slices_0.mshrCtl.mshrs_14.release_period_valid_REG;
    force u_i.inner_l2cache.slices_0.u_core.mshrCtl.u_core.mshrs[14].entry.u_core.REG = u_g.inner_l2cache.slices_0.mshrCtl.mshrs_14.REG;
    force u_i.inner_l2cache.slices_0.u_core.mshrCtl.u_core.mshrs[14].entry.u_core.REG_1 = u_g.inner_l2cache.slices_0.mshrCtl.mshrs_14.REG_1;
    force u_i.inner_l2cache.slices_0.u_core.mshrCtl.u_core.mshrs[14].entry.u_core.REG_2 = u_g.inner_l2cache.slices_0.mshrCtl.mshrs_14.REG_2;
    force u_i.inner_l2cache.slices_0.u_core.mshrCtl.u_core.mshrs[14].entry.u_core.REG_3 = u_g.inner_l2cache.slices_0.mshrCtl.mshrs_14.REG_3;
    force u_i.inner_l2cache.slices_0.u_core.mshrCtl.u_core.mshrs[15].entry.u_core.tgtid_rcompack = u_g.inner_l2cache.slices_0.mshrCtl.mshrs_15.tgtid_rcompack;
    force u_i.inner_l2cache.slices_0.u_core.mshrCtl.u_core.mshrs[15].entry.u_core.txnid_rcompack = u_g.inner_l2cache.slices_0.mshrCtl.mshrs_15.txnid_rcompack;
    force u_i.inner_l2cache.slices_0.u_core.mshrCtl.u_core.mshrs[15].entry.u_core.tgtid_wcompack = u_g.inner_l2cache.slices_0.mshrCtl.mshrs_15.tgtid_wcompack;
    force u_i.inner_l2cache.slices_0.u_core.mshrCtl.u_core.mshrs[15].entry.u_core.txnid_wcompack = u_g.inner_l2cache.slices_0.mshrCtl.mshrs_15.txnid_wcompack;
    force u_i.inner_l2cache.slices_0.u_core.mshrCtl.u_core.mshrs[15].entry.u_core.srcid_retryack = u_g.inner_l2cache.slices_0.mshrCtl.mshrs_15.srcid_retryack;
    force u_i.inner_l2cache.slices_0.u_core.mshrCtl.u_core.mshrs[15].entry.u_core.acquire_ts = u_g.inner_l2cache.slices_0.mshrCtl.mshrs_15.acquire_ts;
    force u_i.inner_l2cache.slices_0.u_core.mshrCtl.u_core.mshrs[15].entry.u_core.release_ts = u_g.inner_l2cache.slices_0.mshrCtl.mshrs_15.release_ts;
    force u_i.inner_l2cache.slices_0.u_core.mshrCtl.u_core.mshrs[15].entry.u_core.acquire_period_valid_REG = u_g.inner_l2cache.slices_0.mshrCtl.mshrs_15.acquire_period_valid_REG;
    force u_i.inner_l2cache.slices_0.u_core.mshrCtl.u_core.mshrs[15].entry.u_core.release_period_valid_REG = u_g.inner_l2cache.slices_0.mshrCtl.mshrs_15.release_period_valid_REG;
    force u_i.inner_l2cache.slices_0.u_core.mshrCtl.u_core.mshrs[15].entry.u_core.REG = u_g.inner_l2cache.slices_0.mshrCtl.mshrs_15.REG;
    force u_i.inner_l2cache.slices_0.u_core.mshrCtl.u_core.mshrs[15].entry.u_core.REG_1 = u_g.inner_l2cache.slices_0.mshrCtl.mshrs_15.REG_1;
    force u_i.inner_l2cache.slices_0.u_core.mshrCtl.u_core.mshrs[15].entry.u_core.REG_2 = u_g.inner_l2cache.slices_0.mshrCtl.mshrs_15.REG_2;
    force u_i.inner_l2cache.slices_0.u_core.mshrCtl.u_core.mshrs[15].entry.u_core.REG_3 = u_g.inner_l2cache.slices_0.mshrCtl.mshrs_15.REG_3;
    force u_i.inner_l2cache.slices_0.u_core.mshrCtl.u_core.io_perf_0_value_REG = u_g.inner_l2cache.slices_0.mshrCtl.io_perf_0_value_REG;
    force u_i.inner_l2cache.slices_0.u_core.mshrCtl.u_core.io_perf_0_value_REG_1 = u_g.inner_l2cache.slices_0.mshrCtl.io_perf_0_value_REG_1;
    force u_i.inner_l2cache.slices_0.u_core.mshrCtl.u_core.io_perf_1_value_REG = u_g.inner_l2cache.slices_0.mshrCtl.io_perf_1_value_REG;
    force u_i.inner_l2cache.slices_0.u_core.mshrCtl.u_core.io_perf_1_value_REG_1 = u_g.inner_l2cache.slices_0.mshrCtl.io_perf_1_value_REG_1;
    force u_i.inner_l2cache.slices_0.u_core.mshrCtl.u_core.io_perf_3_value_REG = u_g.inner_l2cache.slices_0.mshrCtl.io_perf_3_value_REG;
    force u_i.inner_l2cache.slices_0.u_core.mshrCtl.u_core.io_perf_3_value_REG_1 = u_g.inner_l2cache.slices_0.mshrCtl.io_perf_3_value_REG_1;
    force u_i.inner_l2cache.slices_0.u_core.mshrCtl.u_core.REG = u_g.inner_l2cache.slices_0.mshrCtl.REG;
    force u_i.inner_l2cache.slices_0.u_core.mainPipe.u_core.data_s4 = u_g.inner_l2cache.slices_0.mainPipe.data_s4;
    force u_i.inner_l2cache.slices_0.u_core.mainPipe.u_core.data_s5 = u_g.inner_l2cache.slices_0.mainPipe.data_s5;
    force u_i.inner_l2cache.slices_0.u_core.mainPipe.u_core.s3DropValid_d1 = u_g.inner_l2cache.slices_0.mainPipe.REG;
    force u_i.inner_l2cache.slices_0.u_core.mainPipe.u_core.reqDrop_s3_d1 = u_g.inner_l2cache.slices_0.mainPipe.reqDropped_s5_REG;
    force u_i.inner_l2cache.slices_0.u_core.mainPipe.u_core.reqDrop_s3_d2 = u_g.inner_l2cache.slices_0.mainPipe.reqDropped_s5_REG_1;
    force u_i.inner_l2cache.slices_0.u_core.mainPipe.u_core.reqDrop_s4_d1 = u_g.inner_l2cache.slices_0.mainPipe.reqDropped_s5_REG_2;
    u_i.inner_l2cache.slices_0.u_core.mainPipe.customL1Hint.hintQueue.ram_ext.Memory = u_g.inner_l2cache.slices_0.mainPipe.customL1Hint.hintQueue.ram_ext.Memory;
    u_i.inner_l2cache.slices_0.u_core.mainPipe.customL1Hint.hint_s1Queue.ram_ext.Memory = u_g.inner_l2cache.slices_0.mainPipe.customL1Hint.hint_s1Queue.ram_ext.Memory;
    force u_i.inner_l2cache.slices_0.u_core.mainPipe.u_core.perf_d1[0] = u_g.inner_l2cache.slices_0.mainPipe.io_perf_0_value_REG;
    force u_i.inner_l2cache.slices_0.u_core.mainPipe.u_core.perf[0] = u_g.inner_l2cache.slices_0.mainPipe.io_perf_0_value_REG_1;
    force u_i.inner_l2cache.slices_0.u_core.mainPipe.u_core.perf_d1[1] = u_g.inner_l2cache.slices_0.mainPipe.io_perf_1_value_REG;
    force u_i.inner_l2cache.slices_0.u_core.mainPipe.u_core.perf[1] = u_g.inner_l2cache.slices_0.mainPipe.io_perf_1_value_REG_1;
    force u_i.inner_l2cache.slices_0.u_core.mainPipe.u_core.perf_d1[2] = u_g.inner_l2cache.slices_0.mainPipe.io_perf_2_value_REG;
    force u_i.inner_l2cache.slices_0.u_core.mainPipe.u_core.perf[2] = u_g.inner_l2cache.slices_0.mainPipe.io_perf_2_value_REG_1;
    force u_i.inner_l2cache.slices_0.u_core.mainPipe.u_core.perf_d1[3] = u_g.inner_l2cache.slices_0.mainPipe.io_perf_3_value_REG;
    force u_i.inner_l2cache.slices_0.u_core.mainPipe.u_core.perf[3] = u_g.inner_l2cache.slices_0.mainPipe.io_perf_3_value_REG_1;
    force u_i.inner_l2cache.slices_0.u_core.mainPipe.u_core.perf_d1[4] = u_g.inner_l2cache.slices_0.mainPipe.io_perf_4_value_REG;
    force u_i.inner_l2cache.slices_0.u_core.mainPipe.u_core.perf[4] = u_g.inner_l2cache.slices_0.mainPipe.io_perf_4_value_REG_1;
    force u_i.inner_l2cache.slices_0.u_core.mainPipe.u_core.perf_d1[5] = u_g.inner_l2cache.slices_0.mainPipe.io_perf_5_value_REG;
    force u_i.inner_l2cache.slices_0.u_core.mainPipe.u_core.perf[5] = u_g.inner_l2cache.slices_0.mainPipe.io_perf_5_value_REG_1;
    force u_i.inner_l2cache.slices_0.u_core.mainPipe.u_core.perf_d1[6] = u_g.inner_l2cache.slices_0.mainPipe.io_perf_6_value_REG;
    force u_i.inner_l2cache.slices_0.u_core.mainPipe.u_core.perf[6] = u_g.inner_l2cache.slices_0.mainPipe.io_perf_6_value_REG_1;
    force u_i.inner_l2cache.slices_0.u_core.mainPipe.u_core.perf_d1[7] = u_g.inner_l2cache.slices_0.mainPipe.io_perf_7_value_REG;
    force u_i.inner_l2cache.slices_0.u_core.mainPipe.u_core.perf[7] = u_g.inner_l2cache.slices_0.mainPipe.io_perf_7_value_REG_1;
    force u_i.inner_l2cache.slices_0.u_core.mainPipe.u_core.perf_d1[8] = u_g.inner_l2cache.slices_0.mainPipe.io_perf_8_value_REG;
    force u_i.inner_l2cache.slices_0.u_core.mainPipe.u_core.perf[8] = u_g.inner_l2cache.slices_0.mainPipe.io_perf_8_value_REG_1;
    force u_i.inner_l2cache.slices_0.u_core.mainPipe.u_core.perf_d1[9] = u_g.inner_l2cache.slices_0.mainPipe.io_perf_9_value_REG;
    force u_i.inner_l2cache.slices_0.u_core.mainPipe.u_core.perf[9] = u_g.inner_l2cache.slices_0.mainPipe.io_perf_9_value_REG_1;
    force u_i.inner_l2cache.slices_0.u_core.mainPipe.u_core.perf_d1[10] = u_g.inner_l2cache.slices_0.mainPipe.io_perf_10_value_REG;
    force u_i.inner_l2cache.slices_0.u_core.mainPipe.u_core.perf[10] = u_g.inner_l2cache.slices_0.mainPipe.io_perf_10_value_REG_1;
    force u_i.inner_l2cache.slices_0.u_core.mainPipe.u_core.perf_d1[11] = u_g.inner_l2cache.slices_0.mainPipe.io_perf_11_value_REG;
    force u_i.inner_l2cache.slices_0.u_core.mainPipe.u_core.perf[11] = u_g.inner_l2cache.slices_0.mainPipe.io_perf_11_value_REG_1;
    force u_i.inner_l2cache.slices_0.u_core.mainPipe.u_core.perf_d1[12] = u_g.inner_l2cache.slices_0.mainPipe.io_perf_12_value_REG;
    force u_i.inner_l2cache.slices_0.u_core.mainPipe.u_core.perf[12] = u_g.inner_l2cache.slices_0.mainPipe.io_perf_12_value_REG_1;
    u_i.inner_l2cache.slices_0.u_core.grantBuf.grantQueue.ram_ext.Memory = u_g.inner_l2cache.slices_0.grantBuf.grantQueue.ram_ext.Memory;
    u_i.inner_l2cache.slices_0.u_core.grantBuf.grantQueueData0.ram_data_data_ext.Memory = u_g.inner_l2cache.slices_0.grantBuf.grantQueueData0.ram_data_data_ext.Memory;
    u_i.inner_l2cache.slices_0.u_core.grantBuf.grantQueueData1.ram_data_data_ext.Memory = u_g.inner_l2cache.slices_0.grantBuf.grantQueueData1.ram_data_data_ext.Memory;
    u_i.inner_l2cache.slices_0.u_core.grantBuf.pftRespQueue.ram_ext.Memory = u_g.inner_l2cache.slices_0.grantBuf.pftRespQueue.ram_ext.Memory;
    force u_i.inner_l2cache.slices_0.u_core.grantBuf.u_core.validPrev[0] = u_g.inner_l2cache.slices_0.grantBuf.REG;
    force u_i.inner_l2cache.slices_0.u_core.grantBuf.u_core.histValidPrev[0] = u_g.inner_l2cache.slices_0.grantBuf.enable_REG;
    force u_i.inner_l2cache.slices_0.u_core.grantBuf.u_core.validPrev[1] = u_g.inner_l2cache.slices_0.grantBuf.REG_1;
    force u_i.inner_l2cache.slices_0.u_core.grantBuf.u_core.histValidPrev[1] = u_g.inner_l2cache.slices_0.grantBuf.enable_REG_1;
    force u_i.inner_l2cache.slices_0.u_core.grantBuf.u_core.validPrev[2] = u_g.inner_l2cache.slices_0.grantBuf.REG_2;
    force u_i.inner_l2cache.slices_0.u_core.grantBuf.u_core.histValidPrev[2] = u_g.inner_l2cache.slices_0.grantBuf.enable_REG_2;
    force u_i.inner_l2cache.slices_0.u_core.grantBuf.u_core.validPrev[3] = u_g.inner_l2cache.slices_0.grantBuf.REG_3;
    force u_i.inner_l2cache.slices_0.u_core.grantBuf.u_core.histValidPrev[3] = u_g.inner_l2cache.slices_0.grantBuf.enable_REG_3;
    force u_i.inner_l2cache.slices_0.u_core.grantBuf.u_core.validPrev[4] = u_g.inner_l2cache.slices_0.grantBuf.REG_4;
    force u_i.inner_l2cache.slices_0.u_core.grantBuf.u_core.histValidPrev[4] = u_g.inner_l2cache.slices_0.grantBuf.enable_REG_4;
    force u_i.inner_l2cache.slices_0.u_core.grantBuf.u_core.validPrev[5] = u_g.inner_l2cache.slices_0.grantBuf.REG_5;
    force u_i.inner_l2cache.slices_0.u_core.grantBuf.u_core.histValidPrev[5] = u_g.inner_l2cache.slices_0.grantBuf.enable_REG_5;
    force u_i.inner_l2cache.slices_0.u_core.grantBuf.u_core.validPrev[6] = u_g.inner_l2cache.slices_0.grantBuf.REG_6;
    force u_i.inner_l2cache.slices_0.u_core.grantBuf.u_core.histValidPrev[6] = u_g.inner_l2cache.slices_0.grantBuf.enable_REG_6;
    force u_i.inner_l2cache.slices_0.u_core.grantBuf.u_core.validPrev[7] = u_g.inner_l2cache.slices_0.grantBuf.REG_7;
    force u_i.inner_l2cache.slices_0.u_core.grantBuf.u_core.histValidPrev[7] = u_g.inner_l2cache.slices_0.grantBuf.enable_REG_7;
    force u_i.inner_l2cache.slices_0.u_core.grantBuf.u_core.validPrev[8] = u_g.inner_l2cache.slices_0.grantBuf.REG_8;
    force u_i.inner_l2cache.slices_0.u_core.grantBuf.u_core.histValidPrev[8] = u_g.inner_l2cache.slices_0.grantBuf.enable_REG_8;
    force u_i.inner_l2cache.slices_0.u_core.grantBuf.u_core.validPrev[9] = u_g.inner_l2cache.slices_0.grantBuf.REG_9;
    force u_i.inner_l2cache.slices_0.u_core.grantBuf.u_core.histValidPrev[9] = u_g.inner_l2cache.slices_0.grantBuf.enable_REG_9;
    force u_i.inner_l2cache.slices_0.u_core.grantBuf.u_core.validPrev[10] = u_g.inner_l2cache.slices_0.grantBuf.REG_10;
    force u_i.inner_l2cache.slices_0.u_core.grantBuf.u_core.histValidPrev[10] = u_g.inner_l2cache.slices_0.grantBuf.enable_REG_10;
    force u_i.inner_l2cache.slices_0.u_core.grantBuf.u_core.validPrev[11] = u_g.inner_l2cache.slices_0.grantBuf.REG_11;
    force u_i.inner_l2cache.slices_0.u_core.grantBuf.u_core.histValidPrev[11] = u_g.inner_l2cache.slices_0.grantBuf.enable_REG_11;
    force u_i.inner_l2cache.slices_0.u_core.grantBuf.u_core.validPrev[12] = u_g.inner_l2cache.slices_0.grantBuf.REG_12;
    force u_i.inner_l2cache.slices_0.u_core.grantBuf.u_core.histValidPrev[12] = u_g.inner_l2cache.slices_0.grantBuf.enable_REG_12;
    force u_i.inner_l2cache.slices_0.u_core.grantBuf.u_core.validPrev[13] = u_g.inner_l2cache.slices_0.grantBuf.REG_13;
    force u_i.inner_l2cache.slices_0.u_core.grantBuf.u_core.histValidPrev[13] = u_g.inner_l2cache.slices_0.grantBuf.enable_REG_13;
    force u_i.inner_l2cache.slices_0.u_core.grantBuf.u_core.validPrev[14] = u_g.inner_l2cache.slices_0.grantBuf.REG_14;
    force u_i.inner_l2cache.slices_0.u_core.grantBuf.u_core.histValidPrev[14] = u_g.inner_l2cache.slices_0.grantBuf.enable_REG_14;
    force u_i.inner_l2cache.slices_0.u_core.grantBuf.u_core.validPrev[15] = u_g.inner_l2cache.slices_0.grantBuf.REG_15;
    force u_i.inner_l2cache.slices_0.u_core.grantBuf.u_core.histValidPrev[15] = u_g.inner_l2cache.slices_0.grantBuf.enable_REG_15;
    u_i.inner_l2cache.slices_0.u_core.rxsnp.queue.ram_ext.Memory = u_g.inner_l2cache.slices_0.rxsnp.queue.ram_ext.Memory;
    force u_i.inner_l2cache.slices_0.u_core.rxsnp.u_core.replPrevForBlock[0] = u_g.inner_l2cache.slices_0.rxsnp.replaceBlockSnpMask_REG;
    force u_i.inner_l2cache.slices_0.u_core.rxsnp.u_core.replPrevForNest[0] = u_g.inner_l2cache.slices_0.rxsnp.replaceNestSnpMask_REG;
    force u_i.inner_l2cache.slices_0.u_core.rxsnp.u_core.replPrevForBlock[1] = u_g.inner_l2cache.slices_0.rxsnp.replaceBlockSnpMask_REG_1;
    force u_i.inner_l2cache.slices_0.u_core.rxsnp.u_core.replPrevForNest[1] = u_g.inner_l2cache.slices_0.rxsnp.replaceNestSnpMask_REG_1;
    force u_i.inner_l2cache.slices_0.u_core.rxsnp.u_core.replPrevForBlock[2] = u_g.inner_l2cache.slices_0.rxsnp.replaceBlockSnpMask_REG_2;
    force u_i.inner_l2cache.slices_0.u_core.rxsnp.u_core.replPrevForNest[2] = u_g.inner_l2cache.slices_0.rxsnp.replaceNestSnpMask_REG_2;
    force u_i.inner_l2cache.slices_0.u_core.rxsnp.u_core.replPrevForBlock[3] = u_g.inner_l2cache.slices_0.rxsnp.replaceBlockSnpMask_REG_3;
    force u_i.inner_l2cache.slices_0.u_core.rxsnp.u_core.replPrevForNest[3] = u_g.inner_l2cache.slices_0.rxsnp.replaceNestSnpMask_REG_3;
    force u_i.inner_l2cache.slices_0.u_core.rxsnp.u_core.replPrevForBlock[4] = u_g.inner_l2cache.slices_0.rxsnp.replaceBlockSnpMask_REG_4;
    force u_i.inner_l2cache.slices_0.u_core.rxsnp.u_core.replPrevForNest[4] = u_g.inner_l2cache.slices_0.rxsnp.replaceNestSnpMask_REG_4;
    force u_i.inner_l2cache.slices_0.u_core.rxsnp.u_core.replPrevForBlock[5] = u_g.inner_l2cache.slices_0.rxsnp.replaceBlockSnpMask_REG_5;
    force u_i.inner_l2cache.slices_0.u_core.rxsnp.u_core.replPrevForNest[5] = u_g.inner_l2cache.slices_0.rxsnp.replaceNestSnpMask_REG_5;
    force u_i.inner_l2cache.slices_0.u_core.rxsnp.u_core.replPrevForBlock[6] = u_g.inner_l2cache.slices_0.rxsnp.replaceBlockSnpMask_REG_6;
    force u_i.inner_l2cache.slices_0.u_core.rxsnp.u_core.replPrevForNest[6] = u_g.inner_l2cache.slices_0.rxsnp.replaceNestSnpMask_REG_6;
    force u_i.inner_l2cache.slices_0.u_core.rxsnp.u_core.replPrevForBlock[7] = u_g.inner_l2cache.slices_0.rxsnp.replaceBlockSnpMask_REG_7;
    force u_i.inner_l2cache.slices_0.u_core.rxsnp.u_core.replPrevForNest[7] = u_g.inner_l2cache.slices_0.rxsnp.replaceNestSnpMask_REG_7;
    force u_i.inner_l2cache.slices_0.u_core.rxsnp.u_core.replPrevForBlock[8] = u_g.inner_l2cache.slices_0.rxsnp.replaceBlockSnpMask_REG_8;
    force u_i.inner_l2cache.slices_0.u_core.rxsnp.u_core.replPrevForNest[8] = u_g.inner_l2cache.slices_0.rxsnp.replaceNestSnpMask_REG_8;
    force u_i.inner_l2cache.slices_0.u_core.rxsnp.u_core.replPrevForBlock[9] = u_g.inner_l2cache.slices_0.rxsnp.replaceBlockSnpMask_REG_9;
    force u_i.inner_l2cache.slices_0.u_core.rxsnp.u_core.replPrevForNest[9] = u_g.inner_l2cache.slices_0.rxsnp.replaceNestSnpMask_REG_9;
    force u_i.inner_l2cache.slices_0.u_core.rxsnp.u_core.replPrevForBlock[10] = u_g.inner_l2cache.slices_0.rxsnp.replaceBlockSnpMask_REG_10;
    force u_i.inner_l2cache.slices_0.u_core.rxsnp.u_core.replPrevForNest[10] = u_g.inner_l2cache.slices_0.rxsnp.replaceNestSnpMask_REG_10;
    force u_i.inner_l2cache.slices_0.u_core.rxsnp.u_core.replPrevForBlock[11] = u_g.inner_l2cache.slices_0.rxsnp.replaceBlockSnpMask_REG_11;
    force u_i.inner_l2cache.slices_0.u_core.rxsnp.u_core.replPrevForNest[11] = u_g.inner_l2cache.slices_0.rxsnp.replaceNestSnpMask_REG_11;
    force u_i.inner_l2cache.slices_0.u_core.rxsnp.u_core.replPrevForBlock[12] = u_g.inner_l2cache.slices_0.rxsnp.replaceBlockSnpMask_REG_12;
    force u_i.inner_l2cache.slices_0.u_core.rxsnp.u_core.replPrevForNest[12] = u_g.inner_l2cache.slices_0.rxsnp.replaceNestSnpMask_REG_12;
    force u_i.inner_l2cache.slices_0.u_core.rxsnp.u_core.replPrevForBlock[13] = u_g.inner_l2cache.slices_0.rxsnp.replaceBlockSnpMask_REG_13;
    force u_i.inner_l2cache.slices_0.u_core.rxsnp.u_core.replPrevForNest[13] = u_g.inner_l2cache.slices_0.rxsnp.replaceNestSnpMask_REG_13;
    force u_i.inner_l2cache.slices_0.u_core.rxsnp.u_core.replPrevForBlock[14] = u_g.inner_l2cache.slices_0.rxsnp.replaceBlockSnpMask_REG_14;
    force u_i.inner_l2cache.slices_0.u_core.rxsnp.u_core.replPrevForNest[14] = u_g.inner_l2cache.slices_0.rxsnp.replaceNestSnpMask_REG_14;
    force u_i.inner_l2cache.slices_0.u_core.rxsnp.u_core.replPrevForBlock[15] = u_g.inner_l2cache.slices_0.rxsnp.replaceBlockSnpMask_REG_15;
    force u_i.inner_l2cache.slices_0.u_core.rxsnp.u_core.replPrevForNest[15] = u_g.inner_l2cache.slices_0.rxsnp.replaceNestSnpMask_REG_15;
    force u_i.inner_l2cache.slices_0.u_core.reqBuf.chosenQ.u_core.ram = u_g.inner_l2cache.slices_0.reqBuf.chosenQ.ram;
    force u_i.inner_l2cache.slices_0.u_core.reqBuf.u_core.hitPfPrev_set = u_g.inner_l2cache.slices_0.reqBuf.io_hasHitPfInMSHR_valid_REG_set;
    force u_i.inner_l2cache.slices_0.u_core.reqBuf.u_core.hitPfPrev_tag = u_g.inner_l2cache.slices_0.reqBuf.io_hasHitPfInMSHR_valid_REG_tag;
    force u_i.inner_l2cache.slices_0.u_core.reqBuf.u_core.mergeAPrev_set = u_g.inner_l2cache.slices_0.reqBuf.io_hasMergeA_REG_set;
    force u_i.inner_l2cache.slices_0.u_core.reqBuf.u_core.mergeAPrev_tag = u_g.inner_l2cache.slices_0.reqBuf.io_hasMergeA_REG_tag;
    force u_i.inner_l2cache.slices_0.u_core.reqBuf.u_core.sameSetS3Valid[0] = u_g.inner_l2cache.slices_0.reqBuf.canFlow_sameSet_s3_REG;
    force u_i.inner_l2cache.slices_0.u_core.reqBuf.u_core.sameSetS3Set[0] = u_g.inner_l2cache.slices_0.reqBuf.canFlow_sameSet_s3_r;
    force u_i.inner_l2cache.slices_0.u_core.reqBuf.u_core.sameSetS3Valid[1] = u_g.inner_l2cache.slices_0.reqBuf.buffer_rdy_sameSet_s3_REG;
    force u_i.inner_l2cache.slices_0.u_core.reqBuf.u_core.sameSetS3Set[1] = u_g.inner_l2cache.slices_0.reqBuf.buffer_rdy_sameSet_s3_r;
    force u_i.inner_l2cache.slices_0.u_core.reqBuf.u_core.sameSetS3Valid[2] = u_g.inner_l2cache.slices_0.reqBuf.buffer_0_rdy_sameSet_s3_REG;
    force u_i.inner_l2cache.slices_0.u_core.reqBuf.u_core.sameSetS3Set[2] = u_g.inner_l2cache.slices_0.reqBuf.buffer_0_rdy_sameSet_s3_r;
    force u_i.inner_l2cache.slices_0.u_core.reqBuf.u_core.sameSetS3Valid[3] = u_g.inner_l2cache.slices_0.reqBuf.buffer_1_rdy_sameSet_s3_REG;
    force u_i.inner_l2cache.slices_0.u_core.reqBuf.u_core.sameSetS3Set[3] = u_g.inner_l2cache.slices_0.reqBuf.buffer_1_rdy_sameSet_s3_r;
    force u_i.inner_l2cache.slices_0.u_core.reqBuf.u_core.sameSetS3Valid[4] = u_g.inner_l2cache.slices_0.reqBuf.buffer_2_rdy_sameSet_s3_REG;
    force u_i.inner_l2cache.slices_0.u_core.reqBuf.u_core.sameSetS3Set[4] = u_g.inner_l2cache.slices_0.reqBuf.buffer_2_rdy_sameSet_s3_r;
    force u_i.inner_l2cache.slices_0.u_core.reqBuf.u_core.sameSetS3Valid[5] = u_g.inner_l2cache.slices_0.reqBuf.buffer_3_rdy_sameSet_s3_REG;
    force u_i.inner_l2cache.slices_0.u_core.reqBuf.u_core.sameSetS3Set[5] = u_g.inner_l2cache.slices_0.reqBuf.buffer_3_rdy_sameSet_s3_r;
    force u_i.inner_l2cache.slices_0.u_core.sinkC.u_core.bufRespStage[0] = u_g.inner_l2cache.slices_0.sinkC.r_0;
    force u_i.inner_l2cache.slices_0.u_core.sinkC.u_core.bufRespStage[1] = u_g.inner_l2cache.slices_0.sinkC.r_1;
    force u_i.inner_l2cache.slices_0.u_core.sinkC.u_core.bufRespOut[0] = u_g.inner_l2cache.slices_0.sinkC.REG_0;
    force u_i.inner_l2cache.slices_0.u_core.sinkC.u_core.bufRespOut[1] = u_g.inner_l2cache.slices_0.sinkC.REG_1;
    force u_i.inner_l2cache.slices_0.u_core.sinkC.u_core.refillIdReg = u_g.inner_l2cache.slices_0.sinkC.io_refillBufWrite_bits_id_REG;
    force u_i.inner_l2cache.slices_0.u_core.sinkC.u_core.refillBufIdxReg = u_g.inner_l2cache.slices_0.sinkC.io_refillBufWrite_bits_data_data_REG;
    force u_i.inner_l2cache.slices_0.u_core.sinkC.u_core.taskFirePrev = u_g.inner_l2cache.slices_0.sinkC.REG_1_0;
    force u_i.inner_l2cache.slices_0.u_core.sinkC.u_core.taskBufIdxPrev = u_g.inner_l2cache.slices_0.sinkC.REG_2;
    force u_i.inner_l2cache.slices_0.u_core.reqArb.u_core.ds_mcp2_stall = u_g.inner_l2cache.slices_0.reqArb.ds_mcp2_stall;
    force u_i.inner_l2cache.slices_0.u_core.refillBuf.u_core.buffer[0][0] = u_g.inner_l2cache.slices_0.refillBuf.buffer_0_0;
    force u_i.inner_l2cache.slices_0.u_core.refillBuf.u_core.buffer[0][1] = u_g.inner_l2cache.slices_0.refillBuf.buffer_0_1;
    force u_i.inner_l2cache.slices_0.u_core.refillBuf.u_core.buffer[1][0] = u_g.inner_l2cache.slices_0.refillBuf.buffer_1_0;
    force u_i.inner_l2cache.slices_0.u_core.refillBuf.u_core.buffer[1][1] = u_g.inner_l2cache.slices_0.refillBuf.buffer_1_1;
    force u_i.inner_l2cache.slices_0.u_core.refillBuf.u_core.buffer[2][0] = u_g.inner_l2cache.slices_0.refillBuf.buffer_2_0;
    force u_i.inner_l2cache.slices_0.u_core.refillBuf.u_core.buffer[2][1] = u_g.inner_l2cache.slices_0.refillBuf.buffer_2_1;
    force u_i.inner_l2cache.slices_0.u_core.refillBuf.u_core.buffer[3][0] = u_g.inner_l2cache.slices_0.refillBuf.buffer_3_0;
    force u_i.inner_l2cache.slices_0.u_core.refillBuf.u_core.buffer[3][1] = u_g.inner_l2cache.slices_0.refillBuf.buffer_3_1;
    force u_i.inner_l2cache.slices_0.u_core.refillBuf.u_core.buffer[4][0] = u_g.inner_l2cache.slices_0.refillBuf.buffer_4_0;
    force u_i.inner_l2cache.slices_0.u_core.refillBuf.u_core.buffer[4][1] = u_g.inner_l2cache.slices_0.refillBuf.buffer_4_1;
    force u_i.inner_l2cache.slices_0.u_core.refillBuf.u_core.buffer[5][0] = u_g.inner_l2cache.slices_0.refillBuf.buffer_5_0;
    force u_i.inner_l2cache.slices_0.u_core.refillBuf.u_core.buffer[5][1] = u_g.inner_l2cache.slices_0.refillBuf.buffer_5_1;
    force u_i.inner_l2cache.slices_0.u_core.refillBuf.u_core.buffer[6][0] = u_g.inner_l2cache.slices_0.refillBuf.buffer_6_0;
    force u_i.inner_l2cache.slices_0.u_core.refillBuf.u_core.buffer[6][1] = u_g.inner_l2cache.slices_0.refillBuf.buffer_6_1;
    force u_i.inner_l2cache.slices_0.u_core.refillBuf.u_core.buffer[7][0] = u_g.inner_l2cache.slices_0.refillBuf.buffer_7_0;
    force u_i.inner_l2cache.slices_0.u_core.refillBuf.u_core.buffer[7][1] = u_g.inner_l2cache.slices_0.refillBuf.buffer_7_1;
    force u_i.inner_l2cache.slices_0.u_core.refillBuf.u_core.buffer[8][0] = u_g.inner_l2cache.slices_0.refillBuf.buffer_8_0;
    force u_i.inner_l2cache.slices_0.u_core.refillBuf.u_core.buffer[8][1] = u_g.inner_l2cache.slices_0.refillBuf.buffer_8_1;
    force u_i.inner_l2cache.slices_0.u_core.refillBuf.u_core.buffer[9][0] = u_g.inner_l2cache.slices_0.refillBuf.buffer_9_0;
    force u_i.inner_l2cache.slices_0.u_core.refillBuf.u_core.buffer[9][1] = u_g.inner_l2cache.slices_0.refillBuf.buffer_9_1;
    force u_i.inner_l2cache.slices_0.u_core.refillBuf.u_core.buffer[10][0] = u_g.inner_l2cache.slices_0.refillBuf.buffer_10_0;
    force u_i.inner_l2cache.slices_0.u_core.refillBuf.u_core.buffer[10][1] = u_g.inner_l2cache.slices_0.refillBuf.buffer_10_1;
    force u_i.inner_l2cache.slices_0.u_core.refillBuf.u_core.buffer[11][0] = u_g.inner_l2cache.slices_0.refillBuf.buffer_11_0;
    force u_i.inner_l2cache.slices_0.u_core.refillBuf.u_core.buffer[11][1] = u_g.inner_l2cache.slices_0.refillBuf.buffer_11_1;
    force u_i.inner_l2cache.slices_0.u_core.refillBuf.u_core.buffer[12][0] = u_g.inner_l2cache.slices_0.refillBuf.buffer_12_0;
    force u_i.inner_l2cache.slices_0.u_core.refillBuf.u_core.buffer[12][1] = u_g.inner_l2cache.slices_0.refillBuf.buffer_12_1;
    force u_i.inner_l2cache.slices_0.u_core.refillBuf.u_core.buffer[13][0] = u_g.inner_l2cache.slices_0.refillBuf.buffer_13_0;
    force u_i.inner_l2cache.slices_0.u_core.refillBuf.u_core.buffer[13][1] = u_g.inner_l2cache.slices_0.refillBuf.buffer_13_1;
    force u_i.inner_l2cache.slices_0.u_core.refillBuf.u_core.buffer[14][0] = u_g.inner_l2cache.slices_0.refillBuf.buffer_14_0;
    force u_i.inner_l2cache.slices_0.u_core.refillBuf.u_core.buffer[14][1] = u_g.inner_l2cache.slices_0.refillBuf.buffer_14_1;
    force u_i.inner_l2cache.slices_0.u_core.refillBuf.u_core.buffer[15][0] = u_g.inner_l2cache.slices_0.refillBuf.buffer_15_0;
    force u_i.inner_l2cache.slices_0.u_core.refillBuf.u_core.buffer[15][1] = u_g.inner_l2cache.slices_0.refillBuf.buffer_15_1;
    force u_i.inner_l2cache.slices_0.u_core.releaseBuf.u_core.buffer[0][0] = u_g.inner_l2cache.slices_0.releaseBuf.buffer_0_0;
    force u_i.inner_l2cache.slices_0.u_core.releaseBuf.u_core.buffer[0][1] = u_g.inner_l2cache.slices_0.releaseBuf.buffer_0_1;
    force u_i.inner_l2cache.slices_0.u_core.releaseBuf.u_core.buffer[1][0] = u_g.inner_l2cache.slices_0.releaseBuf.buffer_1_0;
    force u_i.inner_l2cache.slices_0.u_core.releaseBuf.u_core.buffer[1][1] = u_g.inner_l2cache.slices_0.releaseBuf.buffer_1_1;
    force u_i.inner_l2cache.slices_0.u_core.releaseBuf.u_core.buffer[2][0] = u_g.inner_l2cache.slices_0.releaseBuf.buffer_2_0;
    force u_i.inner_l2cache.slices_0.u_core.releaseBuf.u_core.buffer[2][1] = u_g.inner_l2cache.slices_0.releaseBuf.buffer_2_1;
    force u_i.inner_l2cache.slices_0.u_core.releaseBuf.u_core.buffer[3][0] = u_g.inner_l2cache.slices_0.releaseBuf.buffer_3_0;
    force u_i.inner_l2cache.slices_0.u_core.releaseBuf.u_core.buffer[3][1] = u_g.inner_l2cache.slices_0.releaseBuf.buffer_3_1;
    force u_i.inner_l2cache.slices_0.u_core.releaseBuf.u_core.buffer[4][0] = u_g.inner_l2cache.slices_0.releaseBuf.buffer_4_0;
    force u_i.inner_l2cache.slices_0.u_core.releaseBuf.u_core.buffer[4][1] = u_g.inner_l2cache.slices_0.releaseBuf.buffer_4_1;
    force u_i.inner_l2cache.slices_0.u_core.releaseBuf.u_core.buffer[5][0] = u_g.inner_l2cache.slices_0.releaseBuf.buffer_5_0;
    force u_i.inner_l2cache.slices_0.u_core.releaseBuf.u_core.buffer[5][1] = u_g.inner_l2cache.slices_0.releaseBuf.buffer_5_1;
    force u_i.inner_l2cache.slices_0.u_core.releaseBuf.u_core.buffer[6][0] = u_g.inner_l2cache.slices_0.releaseBuf.buffer_6_0;
    force u_i.inner_l2cache.slices_0.u_core.releaseBuf.u_core.buffer[6][1] = u_g.inner_l2cache.slices_0.releaseBuf.buffer_6_1;
    force u_i.inner_l2cache.slices_0.u_core.releaseBuf.u_core.buffer[7][0] = u_g.inner_l2cache.slices_0.releaseBuf.buffer_7_0;
    force u_i.inner_l2cache.slices_0.u_core.releaseBuf.u_core.buffer[7][1] = u_g.inner_l2cache.slices_0.releaseBuf.buffer_7_1;
    force u_i.inner_l2cache.slices_0.u_core.releaseBuf.u_core.buffer[8][0] = u_g.inner_l2cache.slices_0.releaseBuf.buffer_8_0;
    force u_i.inner_l2cache.slices_0.u_core.releaseBuf.u_core.buffer[8][1] = u_g.inner_l2cache.slices_0.releaseBuf.buffer_8_1;
    force u_i.inner_l2cache.slices_0.u_core.releaseBuf.u_core.buffer[9][0] = u_g.inner_l2cache.slices_0.releaseBuf.buffer_9_0;
    force u_i.inner_l2cache.slices_0.u_core.releaseBuf.u_core.buffer[9][1] = u_g.inner_l2cache.slices_0.releaseBuf.buffer_9_1;
    force u_i.inner_l2cache.slices_0.u_core.releaseBuf.u_core.buffer[10][0] = u_g.inner_l2cache.slices_0.releaseBuf.buffer_10_0;
    force u_i.inner_l2cache.slices_0.u_core.releaseBuf.u_core.buffer[10][1] = u_g.inner_l2cache.slices_0.releaseBuf.buffer_10_1;
    force u_i.inner_l2cache.slices_0.u_core.releaseBuf.u_core.buffer[11][0] = u_g.inner_l2cache.slices_0.releaseBuf.buffer_11_0;
    force u_i.inner_l2cache.slices_0.u_core.releaseBuf.u_core.buffer[11][1] = u_g.inner_l2cache.slices_0.releaseBuf.buffer_11_1;
    force u_i.inner_l2cache.slices_0.u_core.releaseBuf.u_core.buffer[12][0] = u_g.inner_l2cache.slices_0.releaseBuf.buffer_12_0;
    force u_i.inner_l2cache.slices_0.u_core.releaseBuf.u_core.buffer[12][1] = u_g.inner_l2cache.slices_0.releaseBuf.buffer_12_1;
    force u_i.inner_l2cache.slices_0.u_core.releaseBuf.u_core.buffer[13][0] = u_g.inner_l2cache.slices_0.releaseBuf.buffer_13_0;
    force u_i.inner_l2cache.slices_0.u_core.releaseBuf.u_core.buffer[13][1] = u_g.inner_l2cache.slices_0.releaseBuf.buffer_13_1;
    force u_i.inner_l2cache.slices_0.u_core.releaseBuf.u_core.buffer[14][0] = u_g.inner_l2cache.slices_0.releaseBuf.buffer_14_0;
    force u_i.inner_l2cache.slices_0.u_core.releaseBuf.u_core.buffer[14][1] = u_g.inner_l2cache.slices_0.releaseBuf.buffer_14_1;
    force u_i.inner_l2cache.slices_0.u_core.releaseBuf.u_core.buffer[15][0] = u_g.inner_l2cache.slices_0.releaseBuf.buffer_15_0;
    force u_i.inner_l2cache.slices_0.u_core.releaseBuf.u_core.buffer[15][1] = u_g.inner_l2cache.slices_0.releaseBuf.buffer_15_1;
    u_i.inner_l2cache.slices_0.u_core.txdat.queue.ram_ext.Memory = u_g.inner_l2cache.slices_0.txdat.queue.ram_ext.Memory;
    u_i.inner_l2cache.slices_0.u_core.txdat.queueData0.ram_data_ext.Memory = u_g.inner_l2cache.slices_0.txdat.queueData0.ram_data_ext.Memory;
    u_i.inner_l2cache.slices_0.u_core.txdat.queueData1.ram_data_ext.Memory = u_g.inner_l2cache.slices_0.txdat.queueData1.ram_data_ext.Memory;
    u_i.inner_l2cache.slices_0.directory.tagArray.array_0_0_0.array.array.array_14_ext.ram = u_g.inner_l2cache.slices_0.directory.tagArray.array_0_0_0.array.array.array_14_ext.ram;
    u_i.inner_l2cache.slices_0.directory.tagArray.array_0_0_0.array.array.array_14_ext.reg_RW0_addr = u_g.inner_l2cache.slices_0.directory.tagArray.array_0_0_0.array.array.array_14_ext.reg_RW0_addr;
    u_i.inner_l2cache.slices_0.directory.tagArray.array_0_0_0.array.array.array_14_ext.reg_RW0_ren = u_g.inner_l2cache.slices_0.directory.tagArray.array_0_0_0.array.array.array_14_ext.reg_RW0_ren;
    force u_i.inner_l2cache.slices_0.directory.tagArray.array_0_0_0.u_core.rdataReg = u_g.inner_l2cache.slices_0.directory.tagArray.array_0_0_0.rdataReg;
    u_i.inner_l2cache.slices_0.directory.tagArray.array_0_0_1.array.array.array_14_ext.ram = u_g.inner_l2cache.slices_0.directory.tagArray.array_0_0_1.array.array.array_14_ext.ram;
    u_i.inner_l2cache.slices_0.directory.tagArray.array_0_0_1.array.array.array_14_ext.reg_RW0_addr = u_g.inner_l2cache.slices_0.directory.tagArray.array_0_0_1.array.array.array_14_ext.reg_RW0_addr;
    u_i.inner_l2cache.slices_0.directory.tagArray.array_0_0_1.array.array.array_14_ext.reg_RW0_ren = u_g.inner_l2cache.slices_0.directory.tagArray.array_0_0_1.array.array.array_14_ext.reg_RW0_ren;
    force u_i.inner_l2cache.slices_0.directory.tagArray.array_0_0_1.u_core.rdataReg = u_g.inner_l2cache.slices_0.directory.tagArray.array_0_0_1.rdataReg;
    u_i.inner_l2cache.slices_0.directory.tagArray.array_0_1_0.array.array.array_14_ext.ram = u_g.inner_l2cache.slices_0.directory.tagArray.array_0_1_0.array.array.array_14_ext.ram;
    u_i.inner_l2cache.slices_0.directory.tagArray.array_0_1_0.array.array.array_14_ext.reg_RW0_addr = u_g.inner_l2cache.slices_0.directory.tagArray.array_0_1_0.array.array.array_14_ext.reg_RW0_addr;
    u_i.inner_l2cache.slices_0.directory.tagArray.array_0_1_0.array.array.array_14_ext.reg_RW0_ren = u_g.inner_l2cache.slices_0.directory.tagArray.array_0_1_0.array.array.array_14_ext.reg_RW0_ren;
    force u_i.inner_l2cache.slices_0.directory.tagArray.array_0_1_0.u_core.rdataReg = u_g.inner_l2cache.slices_0.directory.tagArray.array_0_1_0.rdataReg;
    u_i.inner_l2cache.slices_0.directory.tagArray.array_0_1_1.array.array.array_14_ext.ram = u_g.inner_l2cache.slices_0.directory.tagArray.array_0_1_1.array.array.array_14_ext.ram;
    u_i.inner_l2cache.slices_0.directory.tagArray.array_0_1_1.array.array.array_14_ext.reg_RW0_addr = u_g.inner_l2cache.slices_0.directory.tagArray.array_0_1_1.array.array.array_14_ext.reg_RW0_addr;
    u_i.inner_l2cache.slices_0.directory.tagArray.array_0_1_1.array.array.array_14_ext.reg_RW0_ren = u_g.inner_l2cache.slices_0.directory.tagArray.array_0_1_1.array.array.array_14_ext.reg_RW0_ren;
    force u_i.inner_l2cache.slices_0.directory.tagArray.array_0_1_1.u_core.rdataReg = u_g.inner_l2cache.slices_0.directory.tagArray.array_0_1_1.rdataReg;
    u_i.inner_l2cache.slices_0.directory.metaArray.array.array.array_15_ext.ram = u_g.inner_l2cache.slices_0.directory.metaArray.array.array.array_15_ext.ram;
    u_i.inner_l2cache.slices_0.directory.metaArray.array.array.array_15_ext.reg_RW0_addr = u_g.inner_l2cache.slices_0.directory.metaArray.array.array.array_15_ext.reg_RW0_addr;
    u_i.inner_l2cache.slices_0.directory.metaArray.array.array.array_15_ext.reg_RW0_ren = u_g.inner_l2cache.slices_0.directory.metaArray.array.array.array_15_ext.reg_RW0_ren;
    force u_i.inner_l2cache.slices_0.directory.metaArray.u_core.rdataReg = u_g.inner_l2cache.slices_0.directory.metaArray.rdataReg;
    u_i.inner_l2cache.slices_0.directory.replacer_sram_opt.array.array.array_16_ext.ram = u_g.inner_l2cache.slices_0.directory.replacer_sram_opt.array.array.array_16_ext.ram;
    u_i.inner_l2cache.slices_0.directory.replacer_sram_opt.array.array.array_16_ext.reg_RW0_addr = u_g.inner_l2cache.slices_0.directory.replacer_sram_opt.array.array.array_16_ext.reg_RW0_addr;
    u_i.inner_l2cache.slices_0.directory.replacer_sram_opt.array.array.array_16_ext.reg_RW0_ren = u_g.inner_l2cache.slices_0.directory.replacer_sram_opt.array.array.array_16_ext.reg_RW0_ren;
    force u_i.inner_l2cache.slices_0.directory.replacer_sram_opt.u_core.rdataReg = u_g.inner_l2cache.slices_0.directory.replacer_sram_opt.rdataReg;
    u_i.inner_l2cache.slices_0.directory.origin_bit_opt.array.array.array_17_ext.ram = u_g.inner_l2cache.slices_0.directory.origin_bit_opt.array.array.array_17_ext.ram;
    u_i.inner_l2cache.slices_0.directory.origin_bit_opt.array.array.array_17_ext.reg_RW0_addr = u_g.inner_l2cache.slices_0.directory.origin_bit_opt.array.array.array_17_ext.reg_RW0_addr;
    u_i.inner_l2cache.slices_0.directory.origin_bit_opt.array.array.array_17_ext.reg_RW0_ren = u_g.inner_l2cache.slices_0.directory.origin_bit_opt.array.array.array_17_ext.reg_RW0_ren;
    force u_i.inner_l2cache.slices_0.directory.origin_bit_opt.u_core.rdataReg = u_g.inner_l2cache.slices_0.directory.origin_bit_opt.rdataReg;
    u_i.inner_l2cache.slices_0.dataStorage.array.array_0_0_0.array.array.array_18_ext.ram = u_g.inner_l2cache.slices_0.dataStorage.array.array_0_0_0.array.array.array_18_ext.ram;
    u_i.inner_l2cache.slices_0.dataStorage.array.array_0_0_0.array.array.array_18_ext.reg_RW0_addr = u_g.inner_l2cache.slices_0.dataStorage.array.array_0_0_0.array.array.array_18_ext.reg_RW0_addr;
    u_i.inner_l2cache.slices_0.dataStorage.array.array_0_0_0.array.array.array_18_ext.reg_RW0_ren = u_g.inner_l2cache.slices_0.dataStorage.array.array_0_0_0.array.array.array_18_ext.reg_RW0_ren;
    force u_i.inner_l2cache.slices_0.dataStorage.array.array_0_0_0.u_core.rdataReg = u_g.inner_l2cache.slices_0.dataStorage.array.array_0_0_0.rdataReg;
    u_i.inner_l2cache.slices_0.dataStorage.array.array_0_0_1.array.array.array_18_ext.ram = u_g.inner_l2cache.slices_0.dataStorage.array.array_0_0_1.array.array.array_18_ext.ram;
    u_i.inner_l2cache.slices_0.dataStorage.array.array_0_0_1.array.array.array_18_ext.reg_RW0_addr = u_g.inner_l2cache.slices_0.dataStorage.array.array_0_0_1.array.array.array_18_ext.reg_RW0_addr;
    u_i.inner_l2cache.slices_0.dataStorage.array.array_0_0_1.array.array.array_18_ext.reg_RW0_ren = u_g.inner_l2cache.slices_0.dataStorage.array.array_0_0_1.array.array.array_18_ext.reg_RW0_ren;
    force u_i.inner_l2cache.slices_0.dataStorage.array.array_0_0_1.u_core.rdataReg = u_g.inner_l2cache.slices_0.dataStorage.array.array_0_0_1.rdataReg;
    u_i.inner_l2cache.slices_0.dataStorage.array.array_0_0_2.array.array.array_18_ext.ram = u_g.inner_l2cache.slices_0.dataStorage.array.array_0_0_2.array.array.array_18_ext.ram;
    u_i.inner_l2cache.slices_0.dataStorage.array.array_0_0_2.array.array.array_18_ext.reg_RW0_addr = u_g.inner_l2cache.slices_0.dataStorage.array.array_0_0_2.array.array.array_18_ext.reg_RW0_addr;
    u_i.inner_l2cache.slices_0.dataStorage.array.array_0_0_2.array.array.array_18_ext.reg_RW0_ren = u_g.inner_l2cache.slices_0.dataStorage.array.array_0_0_2.array.array.array_18_ext.reg_RW0_ren;
    force u_i.inner_l2cache.slices_0.dataStorage.array.array_0_0_2.u_core.rdataReg = u_g.inner_l2cache.slices_0.dataStorage.array.array_0_0_2.rdataReg;
    u_i.inner_l2cache.slices_0.dataStorage.array.array_0_0_3.array.array.array_18_ext.ram = u_g.inner_l2cache.slices_0.dataStorage.array.array_0_0_3.array.array.array_18_ext.ram;
    u_i.inner_l2cache.slices_0.dataStorage.array.array_0_0_3.array.array.array_18_ext.reg_RW0_addr = u_g.inner_l2cache.slices_0.dataStorage.array.array_0_0_3.array.array.array_18_ext.reg_RW0_addr;
    u_i.inner_l2cache.slices_0.dataStorage.array.array_0_0_3.array.array.array_18_ext.reg_RW0_ren = u_g.inner_l2cache.slices_0.dataStorage.array.array_0_0_3.array.array.array_18_ext.reg_RW0_ren;
    force u_i.inner_l2cache.slices_0.dataStorage.array.array_0_0_3.u_core.rdataReg = u_g.inner_l2cache.slices_0.dataStorage.array.array_0_0_3.rdataReg;
    force u_i.inner_l2cache.slices_0.dataStorage.u_core.error_REG = u_g.inner_l2cache.slices_0.dataStorage.error_REG;
    force u_i.inner_l2cache.slices_0.dataStorage.u_core.error_REG_1 = u_g.inner_l2cache.slices_0.dataStorage.error_REG_1;
    force u_i.inner_l2cache.slices_0.mbistPl.u_core.g_node_return.pipelineDataOutReg = u_g.inner_l2cache.slices_0.mbistPl.pipelineDataOutReg;
    u_i.inner_l2cache.slices_0.u_core.txreq.u_core.queue.ram_ext.Memory = u_g.inner_l2cache.slices_0.txreq.queue.ram_ext.Memory;
    u_i.inner_l2cache.slices_0.u_core.txrsp.u_core.queue.ram_ext.Memory = u_g.inner_l2cache.slices_0.txrsp.queue.ram_ext.Memory;
    force u_i.inner_l2cache.slices_0.u_core.io_error_bits_REG_valid = u_g.inner_l2cache.slices_0.io_error_bits_REG_valid;
    force u_i.inner_l2cache.slices_0.u_core.io_error_bits_REG_address = u_g.inner_l2cache.slices_0.io_error_bits_REG_address;
    force u_i.inner_l2cache.slices_0.u_core.io_perf_0_value_REG = u_g.inner_l2cache.slices_0.io_perf_0_value_REG;
    force u_i.inner_l2cache.slices_0.u_core.io_perf_0_value_REG_1 = u_g.inner_l2cache.slices_0.io_perf_0_value_REG_1;
    force u_i.inner_l2cache.slices_0.u_core.io_perf_1_value_REG = u_g.inner_l2cache.slices_0.io_perf_1_value_REG;
    force u_i.inner_l2cache.slices_0.u_core.io_perf_1_value_REG_1 = u_g.inner_l2cache.slices_0.io_perf_1_value_REG_1;
    force u_i.inner_l2cache.slices_0.u_core.io_perf_3_value_REG = u_g.inner_l2cache.slices_0.io_perf_3_value_REG;
    force u_i.inner_l2cache.slices_0.u_core.io_perf_3_value_REG_1 = u_g.inner_l2cache.slices_0.io_perf_3_value_REG_1;
    force u_i.inner_l2cache.slices_0.u_core.io_perf_4_value_REG = u_g.inner_l2cache.slices_0.io_perf_4_value_REG;
    force u_i.inner_l2cache.slices_0.u_core.io_perf_4_value_REG_1 = u_g.inner_l2cache.slices_0.io_perf_4_value_REG_1;
    force u_i.inner_l2cache.slices_0.u_core.io_perf_5_value_REG = u_g.inner_l2cache.slices_0.io_perf_5_value_REG;
    force u_i.inner_l2cache.slices_0.u_core.io_perf_5_value_REG_1 = u_g.inner_l2cache.slices_0.io_perf_5_value_REG_1;
    force u_i.inner_l2cache.slices_0.u_core.io_perf_6_value_REG = u_g.inner_l2cache.slices_0.io_perf_6_value_REG;
    force u_i.inner_l2cache.slices_0.u_core.io_perf_6_value_REG_1 = u_g.inner_l2cache.slices_0.io_perf_6_value_REG_1;
    force u_i.inner_l2cache.slices_0.u_core.io_perf_7_value_REG = u_g.inner_l2cache.slices_0.io_perf_7_value_REG;
    force u_i.inner_l2cache.slices_0.u_core.io_perf_7_value_REG_1 = u_g.inner_l2cache.slices_0.io_perf_7_value_REG_1;
    force u_i.inner_l2cache.slices_0.u_core.io_perf_8_value_REG = u_g.inner_l2cache.slices_0.io_perf_8_value_REG;
    force u_i.inner_l2cache.slices_0.u_core.io_perf_8_value_REG_1 = u_g.inner_l2cache.slices_0.io_perf_8_value_REG_1;
    force u_i.inner_l2cache.slices_0.u_core.io_perf_9_value_REG = u_g.inner_l2cache.slices_0.io_perf_9_value_REG;
    force u_i.inner_l2cache.slices_0.u_core.io_perf_9_value_REG_1 = u_g.inner_l2cache.slices_0.io_perf_9_value_REG_1;
    force u_i.inner_l2cache.slices_0.u_core.io_perf_10_value_REG = u_g.inner_l2cache.slices_0.io_perf_10_value_REG;
    force u_i.inner_l2cache.slices_0.u_core.io_perf_10_value_REG_1 = u_g.inner_l2cache.slices_0.io_perf_10_value_REG_1;
    force u_i.inner_l2cache.slices_0.u_core.io_perf_11_value_REG = u_g.inner_l2cache.slices_0.io_perf_11_value_REG;
    force u_i.inner_l2cache.slices_0.u_core.io_perf_11_value_REG_1 = u_g.inner_l2cache.slices_0.io_perf_11_value_REG_1;
    force u_i.inner_l2cache.slices_0.u_core.io_perf_12_value_REG = u_g.inner_l2cache.slices_0.io_perf_12_value_REG;
    force u_i.inner_l2cache.slices_0.u_core.io_perf_12_value_REG_1 = u_g.inner_l2cache.slices_0.io_perf_12_value_REG_1;
    force u_i.inner_l2cache.slices_0.u_core.io_perf_13_value_REG = u_g.inner_l2cache.slices_0.io_perf_13_value_REG;
    force u_i.inner_l2cache.slices_0.u_core.io_perf_13_value_REG_1 = u_g.inner_l2cache.slices_0.io_perf_13_value_REG_1;
    force u_i.inner_l2cache.slices_0.u_core.io_perf_14_value_REG = u_g.inner_l2cache.slices_0.io_perf_14_value_REG;
    force u_i.inner_l2cache.slices_0.u_core.io_perf_14_value_REG_1 = u_g.inner_l2cache.slices_0.io_perf_14_value_REG_1;
    force u_i.inner_l2cache.slices_0.u_core.io_perf_15_value_REG = u_g.inner_l2cache.slices_0.io_perf_15_value_REG;
    force u_i.inner_l2cache.slices_0.u_core.io_perf_15_value_REG_1 = u_g.inner_l2cache.slices_0.io_perf_15_value_REG_1;
    force u_i.inner_l2cache.slices_0.u_core.io_perf_16_value_REG = u_g.inner_l2cache.slices_0.io_perf_16_value_REG;
    force u_i.inner_l2cache.slices_0.u_core.io_perf_16_value_REG_1 = u_g.inner_l2cache.slices_0.io_perf_16_value_REG_1;
    force u_i.inner_l2cache.slices_1.u_core.mshrCtl.u_core.mshrs[0].entry.u_core.tgtid_rcompack = u_g.inner_l2cache.slices_1.mshrCtl.mshrs_0.tgtid_rcompack;
    force u_i.inner_l2cache.slices_1.u_core.mshrCtl.u_core.mshrs[0].entry.u_core.txnid_rcompack = u_g.inner_l2cache.slices_1.mshrCtl.mshrs_0.txnid_rcompack;
    force u_i.inner_l2cache.slices_1.u_core.mshrCtl.u_core.mshrs[0].entry.u_core.tgtid_wcompack = u_g.inner_l2cache.slices_1.mshrCtl.mshrs_0.tgtid_wcompack;
    force u_i.inner_l2cache.slices_1.u_core.mshrCtl.u_core.mshrs[0].entry.u_core.txnid_wcompack = u_g.inner_l2cache.slices_1.mshrCtl.mshrs_0.txnid_wcompack;
    force u_i.inner_l2cache.slices_1.u_core.mshrCtl.u_core.mshrs[0].entry.u_core.srcid_retryack = u_g.inner_l2cache.slices_1.mshrCtl.mshrs_0.srcid_retryack;
    force u_i.inner_l2cache.slices_1.u_core.mshrCtl.u_core.mshrs[0].entry.u_core.acquire_ts = u_g.inner_l2cache.slices_1.mshrCtl.mshrs_0.acquire_ts;
    force u_i.inner_l2cache.slices_1.u_core.mshrCtl.u_core.mshrs[0].entry.u_core.release_ts = u_g.inner_l2cache.slices_1.mshrCtl.mshrs_0.release_ts;
    force u_i.inner_l2cache.slices_1.u_core.mshrCtl.u_core.mshrs[0].entry.u_core.acquire_period_valid_REG = u_g.inner_l2cache.slices_1.mshrCtl.mshrs_0.acquire_period_valid_REG;
    force u_i.inner_l2cache.slices_1.u_core.mshrCtl.u_core.mshrs[0].entry.u_core.release_period_valid_REG = u_g.inner_l2cache.slices_1.mshrCtl.mshrs_0.release_period_valid_REG;
    force u_i.inner_l2cache.slices_1.u_core.mshrCtl.u_core.mshrs[0].entry.u_core.REG = u_g.inner_l2cache.slices_1.mshrCtl.mshrs_0.REG;
    force u_i.inner_l2cache.slices_1.u_core.mshrCtl.u_core.mshrs[0].entry.u_core.REG_1 = u_g.inner_l2cache.slices_1.mshrCtl.mshrs_0.REG_1;
    force u_i.inner_l2cache.slices_1.u_core.mshrCtl.u_core.mshrs[0].entry.u_core.REG_2 = u_g.inner_l2cache.slices_1.mshrCtl.mshrs_0.REG_2;
    force u_i.inner_l2cache.slices_1.u_core.mshrCtl.u_core.mshrs[0].entry.u_core.REG_3 = u_g.inner_l2cache.slices_1.mshrCtl.mshrs_0.REG_3;
    force u_i.inner_l2cache.slices_1.u_core.mshrCtl.u_core.mshrs[1].entry.u_core.tgtid_rcompack = u_g.inner_l2cache.slices_1.mshrCtl.mshrs_1.tgtid_rcompack;
    force u_i.inner_l2cache.slices_1.u_core.mshrCtl.u_core.mshrs[1].entry.u_core.txnid_rcompack = u_g.inner_l2cache.slices_1.mshrCtl.mshrs_1.txnid_rcompack;
    force u_i.inner_l2cache.slices_1.u_core.mshrCtl.u_core.mshrs[1].entry.u_core.tgtid_wcompack = u_g.inner_l2cache.slices_1.mshrCtl.mshrs_1.tgtid_wcompack;
    force u_i.inner_l2cache.slices_1.u_core.mshrCtl.u_core.mshrs[1].entry.u_core.txnid_wcompack = u_g.inner_l2cache.slices_1.mshrCtl.mshrs_1.txnid_wcompack;
    force u_i.inner_l2cache.slices_1.u_core.mshrCtl.u_core.mshrs[1].entry.u_core.srcid_retryack = u_g.inner_l2cache.slices_1.mshrCtl.mshrs_1.srcid_retryack;
    force u_i.inner_l2cache.slices_1.u_core.mshrCtl.u_core.mshrs[1].entry.u_core.acquire_ts = u_g.inner_l2cache.slices_1.mshrCtl.mshrs_1.acquire_ts;
    force u_i.inner_l2cache.slices_1.u_core.mshrCtl.u_core.mshrs[1].entry.u_core.release_ts = u_g.inner_l2cache.slices_1.mshrCtl.mshrs_1.release_ts;
    force u_i.inner_l2cache.slices_1.u_core.mshrCtl.u_core.mshrs[1].entry.u_core.acquire_period_valid_REG = u_g.inner_l2cache.slices_1.mshrCtl.mshrs_1.acquire_period_valid_REG;
    force u_i.inner_l2cache.slices_1.u_core.mshrCtl.u_core.mshrs[1].entry.u_core.release_period_valid_REG = u_g.inner_l2cache.slices_1.mshrCtl.mshrs_1.release_period_valid_REG;
    force u_i.inner_l2cache.slices_1.u_core.mshrCtl.u_core.mshrs[1].entry.u_core.REG = u_g.inner_l2cache.slices_1.mshrCtl.mshrs_1.REG;
    force u_i.inner_l2cache.slices_1.u_core.mshrCtl.u_core.mshrs[1].entry.u_core.REG_1 = u_g.inner_l2cache.slices_1.mshrCtl.mshrs_1.REG_1;
    force u_i.inner_l2cache.slices_1.u_core.mshrCtl.u_core.mshrs[1].entry.u_core.REG_2 = u_g.inner_l2cache.slices_1.mshrCtl.mshrs_1.REG_2;
    force u_i.inner_l2cache.slices_1.u_core.mshrCtl.u_core.mshrs[1].entry.u_core.REG_3 = u_g.inner_l2cache.slices_1.mshrCtl.mshrs_1.REG_3;
    force u_i.inner_l2cache.slices_1.u_core.mshrCtl.u_core.mshrs[2].entry.u_core.tgtid_rcompack = u_g.inner_l2cache.slices_1.mshrCtl.mshrs_2.tgtid_rcompack;
    force u_i.inner_l2cache.slices_1.u_core.mshrCtl.u_core.mshrs[2].entry.u_core.txnid_rcompack = u_g.inner_l2cache.slices_1.mshrCtl.mshrs_2.txnid_rcompack;
    force u_i.inner_l2cache.slices_1.u_core.mshrCtl.u_core.mshrs[2].entry.u_core.tgtid_wcompack = u_g.inner_l2cache.slices_1.mshrCtl.mshrs_2.tgtid_wcompack;
    force u_i.inner_l2cache.slices_1.u_core.mshrCtl.u_core.mshrs[2].entry.u_core.txnid_wcompack = u_g.inner_l2cache.slices_1.mshrCtl.mshrs_2.txnid_wcompack;
    force u_i.inner_l2cache.slices_1.u_core.mshrCtl.u_core.mshrs[2].entry.u_core.srcid_retryack = u_g.inner_l2cache.slices_1.mshrCtl.mshrs_2.srcid_retryack;
    force u_i.inner_l2cache.slices_1.u_core.mshrCtl.u_core.mshrs[2].entry.u_core.acquire_ts = u_g.inner_l2cache.slices_1.mshrCtl.mshrs_2.acquire_ts;
    force u_i.inner_l2cache.slices_1.u_core.mshrCtl.u_core.mshrs[2].entry.u_core.release_ts = u_g.inner_l2cache.slices_1.mshrCtl.mshrs_2.release_ts;
    force u_i.inner_l2cache.slices_1.u_core.mshrCtl.u_core.mshrs[2].entry.u_core.acquire_period_valid_REG = u_g.inner_l2cache.slices_1.mshrCtl.mshrs_2.acquire_period_valid_REG;
    force u_i.inner_l2cache.slices_1.u_core.mshrCtl.u_core.mshrs[2].entry.u_core.release_period_valid_REG = u_g.inner_l2cache.slices_1.mshrCtl.mshrs_2.release_period_valid_REG;
    force u_i.inner_l2cache.slices_1.u_core.mshrCtl.u_core.mshrs[2].entry.u_core.REG = u_g.inner_l2cache.slices_1.mshrCtl.mshrs_2.REG;
    force u_i.inner_l2cache.slices_1.u_core.mshrCtl.u_core.mshrs[2].entry.u_core.REG_1 = u_g.inner_l2cache.slices_1.mshrCtl.mshrs_2.REG_1;
    force u_i.inner_l2cache.slices_1.u_core.mshrCtl.u_core.mshrs[2].entry.u_core.REG_2 = u_g.inner_l2cache.slices_1.mshrCtl.mshrs_2.REG_2;
    force u_i.inner_l2cache.slices_1.u_core.mshrCtl.u_core.mshrs[2].entry.u_core.REG_3 = u_g.inner_l2cache.slices_1.mshrCtl.mshrs_2.REG_3;
    force u_i.inner_l2cache.slices_1.u_core.mshrCtl.u_core.mshrs[3].entry.u_core.tgtid_rcompack = u_g.inner_l2cache.slices_1.mshrCtl.mshrs_3.tgtid_rcompack;
    force u_i.inner_l2cache.slices_1.u_core.mshrCtl.u_core.mshrs[3].entry.u_core.txnid_rcompack = u_g.inner_l2cache.slices_1.mshrCtl.mshrs_3.txnid_rcompack;
    force u_i.inner_l2cache.slices_1.u_core.mshrCtl.u_core.mshrs[3].entry.u_core.tgtid_wcompack = u_g.inner_l2cache.slices_1.mshrCtl.mshrs_3.tgtid_wcompack;
    force u_i.inner_l2cache.slices_1.u_core.mshrCtl.u_core.mshrs[3].entry.u_core.txnid_wcompack = u_g.inner_l2cache.slices_1.mshrCtl.mshrs_3.txnid_wcompack;
    force u_i.inner_l2cache.slices_1.u_core.mshrCtl.u_core.mshrs[3].entry.u_core.srcid_retryack = u_g.inner_l2cache.slices_1.mshrCtl.mshrs_3.srcid_retryack;
    force u_i.inner_l2cache.slices_1.u_core.mshrCtl.u_core.mshrs[3].entry.u_core.acquire_ts = u_g.inner_l2cache.slices_1.mshrCtl.mshrs_3.acquire_ts;
    force u_i.inner_l2cache.slices_1.u_core.mshrCtl.u_core.mshrs[3].entry.u_core.release_ts = u_g.inner_l2cache.slices_1.mshrCtl.mshrs_3.release_ts;
    force u_i.inner_l2cache.slices_1.u_core.mshrCtl.u_core.mshrs[3].entry.u_core.acquire_period_valid_REG = u_g.inner_l2cache.slices_1.mshrCtl.mshrs_3.acquire_period_valid_REG;
    force u_i.inner_l2cache.slices_1.u_core.mshrCtl.u_core.mshrs[3].entry.u_core.release_period_valid_REG = u_g.inner_l2cache.slices_1.mshrCtl.mshrs_3.release_period_valid_REG;
    force u_i.inner_l2cache.slices_1.u_core.mshrCtl.u_core.mshrs[3].entry.u_core.REG = u_g.inner_l2cache.slices_1.mshrCtl.mshrs_3.REG;
    force u_i.inner_l2cache.slices_1.u_core.mshrCtl.u_core.mshrs[3].entry.u_core.REG_1 = u_g.inner_l2cache.slices_1.mshrCtl.mshrs_3.REG_1;
    force u_i.inner_l2cache.slices_1.u_core.mshrCtl.u_core.mshrs[3].entry.u_core.REG_2 = u_g.inner_l2cache.slices_1.mshrCtl.mshrs_3.REG_2;
    force u_i.inner_l2cache.slices_1.u_core.mshrCtl.u_core.mshrs[3].entry.u_core.REG_3 = u_g.inner_l2cache.slices_1.mshrCtl.mshrs_3.REG_3;
    force u_i.inner_l2cache.slices_1.u_core.mshrCtl.u_core.mshrs[4].entry.u_core.tgtid_rcompack = u_g.inner_l2cache.slices_1.mshrCtl.mshrs_4.tgtid_rcompack;
    force u_i.inner_l2cache.slices_1.u_core.mshrCtl.u_core.mshrs[4].entry.u_core.txnid_rcompack = u_g.inner_l2cache.slices_1.mshrCtl.mshrs_4.txnid_rcompack;
    force u_i.inner_l2cache.slices_1.u_core.mshrCtl.u_core.mshrs[4].entry.u_core.tgtid_wcompack = u_g.inner_l2cache.slices_1.mshrCtl.mshrs_4.tgtid_wcompack;
    force u_i.inner_l2cache.slices_1.u_core.mshrCtl.u_core.mshrs[4].entry.u_core.txnid_wcompack = u_g.inner_l2cache.slices_1.mshrCtl.mshrs_4.txnid_wcompack;
    force u_i.inner_l2cache.slices_1.u_core.mshrCtl.u_core.mshrs[4].entry.u_core.srcid_retryack = u_g.inner_l2cache.slices_1.mshrCtl.mshrs_4.srcid_retryack;
    force u_i.inner_l2cache.slices_1.u_core.mshrCtl.u_core.mshrs[4].entry.u_core.acquire_ts = u_g.inner_l2cache.slices_1.mshrCtl.mshrs_4.acquire_ts;
    force u_i.inner_l2cache.slices_1.u_core.mshrCtl.u_core.mshrs[4].entry.u_core.release_ts = u_g.inner_l2cache.slices_1.mshrCtl.mshrs_4.release_ts;
    force u_i.inner_l2cache.slices_1.u_core.mshrCtl.u_core.mshrs[4].entry.u_core.acquire_period_valid_REG = u_g.inner_l2cache.slices_1.mshrCtl.mshrs_4.acquire_period_valid_REG;
    force u_i.inner_l2cache.slices_1.u_core.mshrCtl.u_core.mshrs[4].entry.u_core.release_period_valid_REG = u_g.inner_l2cache.slices_1.mshrCtl.mshrs_4.release_period_valid_REG;
    force u_i.inner_l2cache.slices_1.u_core.mshrCtl.u_core.mshrs[4].entry.u_core.REG = u_g.inner_l2cache.slices_1.mshrCtl.mshrs_4.REG;
    force u_i.inner_l2cache.slices_1.u_core.mshrCtl.u_core.mshrs[4].entry.u_core.REG_1 = u_g.inner_l2cache.slices_1.mshrCtl.mshrs_4.REG_1;
    force u_i.inner_l2cache.slices_1.u_core.mshrCtl.u_core.mshrs[4].entry.u_core.REG_2 = u_g.inner_l2cache.slices_1.mshrCtl.mshrs_4.REG_2;
    force u_i.inner_l2cache.slices_1.u_core.mshrCtl.u_core.mshrs[4].entry.u_core.REG_3 = u_g.inner_l2cache.slices_1.mshrCtl.mshrs_4.REG_3;
    force u_i.inner_l2cache.slices_1.u_core.mshrCtl.u_core.mshrs[5].entry.u_core.tgtid_rcompack = u_g.inner_l2cache.slices_1.mshrCtl.mshrs_5.tgtid_rcompack;
    force u_i.inner_l2cache.slices_1.u_core.mshrCtl.u_core.mshrs[5].entry.u_core.txnid_rcompack = u_g.inner_l2cache.slices_1.mshrCtl.mshrs_5.txnid_rcompack;
    force u_i.inner_l2cache.slices_1.u_core.mshrCtl.u_core.mshrs[5].entry.u_core.tgtid_wcompack = u_g.inner_l2cache.slices_1.mshrCtl.mshrs_5.tgtid_wcompack;
    force u_i.inner_l2cache.slices_1.u_core.mshrCtl.u_core.mshrs[5].entry.u_core.txnid_wcompack = u_g.inner_l2cache.slices_1.mshrCtl.mshrs_5.txnid_wcompack;
    force u_i.inner_l2cache.slices_1.u_core.mshrCtl.u_core.mshrs[5].entry.u_core.srcid_retryack = u_g.inner_l2cache.slices_1.mshrCtl.mshrs_5.srcid_retryack;
    force u_i.inner_l2cache.slices_1.u_core.mshrCtl.u_core.mshrs[5].entry.u_core.acquire_ts = u_g.inner_l2cache.slices_1.mshrCtl.mshrs_5.acquire_ts;
    force u_i.inner_l2cache.slices_1.u_core.mshrCtl.u_core.mshrs[5].entry.u_core.release_ts = u_g.inner_l2cache.slices_1.mshrCtl.mshrs_5.release_ts;
    force u_i.inner_l2cache.slices_1.u_core.mshrCtl.u_core.mshrs[5].entry.u_core.acquire_period_valid_REG = u_g.inner_l2cache.slices_1.mshrCtl.mshrs_5.acquire_period_valid_REG;
    force u_i.inner_l2cache.slices_1.u_core.mshrCtl.u_core.mshrs[5].entry.u_core.release_period_valid_REG = u_g.inner_l2cache.slices_1.mshrCtl.mshrs_5.release_period_valid_REG;
    force u_i.inner_l2cache.slices_1.u_core.mshrCtl.u_core.mshrs[5].entry.u_core.REG = u_g.inner_l2cache.slices_1.mshrCtl.mshrs_5.REG;
    force u_i.inner_l2cache.slices_1.u_core.mshrCtl.u_core.mshrs[5].entry.u_core.REG_1 = u_g.inner_l2cache.slices_1.mshrCtl.mshrs_5.REG_1;
    force u_i.inner_l2cache.slices_1.u_core.mshrCtl.u_core.mshrs[5].entry.u_core.REG_2 = u_g.inner_l2cache.slices_1.mshrCtl.mshrs_5.REG_2;
    force u_i.inner_l2cache.slices_1.u_core.mshrCtl.u_core.mshrs[5].entry.u_core.REG_3 = u_g.inner_l2cache.slices_1.mshrCtl.mshrs_5.REG_3;
    force u_i.inner_l2cache.slices_1.u_core.mshrCtl.u_core.mshrs[6].entry.u_core.tgtid_rcompack = u_g.inner_l2cache.slices_1.mshrCtl.mshrs_6.tgtid_rcompack;
    force u_i.inner_l2cache.slices_1.u_core.mshrCtl.u_core.mshrs[6].entry.u_core.txnid_rcompack = u_g.inner_l2cache.slices_1.mshrCtl.mshrs_6.txnid_rcompack;
    force u_i.inner_l2cache.slices_1.u_core.mshrCtl.u_core.mshrs[6].entry.u_core.tgtid_wcompack = u_g.inner_l2cache.slices_1.mshrCtl.mshrs_6.tgtid_wcompack;
    force u_i.inner_l2cache.slices_1.u_core.mshrCtl.u_core.mshrs[6].entry.u_core.txnid_wcompack = u_g.inner_l2cache.slices_1.mshrCtl.mshrs_6.txnid_wcompack;
    force u_i.inner_l2cache.slices_1.u_core.mshrCtl.u_core.mshrs[6].entry.u_core.srcid_retryack = u_g.inner_l2cache.slices_1.mshrCtl.mshrs_6.srcid_retryack;
    force u_i.inner_l2cache.slices_1.u_core.mshrCtl.u_core.mshrs[6].entry.u_core.acquire_ts = u_g.inner_l2cache.slices_1.mshrCtl.mshrs_6.acquire_ts;
    force u_i.inner_l2cache.slices_1.u_core.mshrCtl.u_core.mshrs[6].entry.u_core.release_ts = u_g.inner_l2cache.slices_1.mshrCtl.mshrs_6.release_ts;
    force u_i.inner_l2cache.slices_1.u_core.mshrCtl.u_core.mshrs[6].entry.u_core.acquire_period_valid_REG = u_g.inner_l2cache.slices_1.mshrCtl.mshrs_6.acquire_period_valid_REG;
    force u_i.inner_l2cache.slices_1.u_core.mshrCtl.u_core.mshrs[6].entry.u_core.release_period_valid_REG = u_g.inner_l2cache.slices_1.mshrCtl.mshrs_6.release_period_valid_REG;
    force u_i.inner_l2cache.slices_1.u_core.mshrCtl.u_core.mshrs[6].entry.u_core.REG = u_g.inner_l2cache.slices_1.mshrCtl.mshrs_6.REG;
    force u_i.inner_l2cache.slices_1.u_core.mshrCtl.u_core.mshrs[6].entry.u_core.REG_1 = u_g.inner_l2cache.slices_1.mshrCtl.mshrs_6.REG_1;
    force u_i.inner_l2cache.slices_1.u_core.mshrCtl.u_core.mshrs[6].entry.u_core.REG_2 = u_g.inner_l2cache.slices_1.mshrCtl.mshrs_6.REG_2;
    force u_i.inner_l2cache.slices_1.u_core.mshrCtl.u_core.mshrs[6].entry.u_core.REG_3 = u_g.inner_l2cache.slices_1.mshrCtl.mshrs_6.REG_3;
    force u_i.inner_l2cache.slices_1.u_core.mshrCtl.u_core.mshrs[7].entry.u_core.tgtid_rcompack = u_g.inner_l2cache.slices_1.mshrCtl.mshrs_7.tgtid_rcompack;
    force u_i.inner_l2cache.slices_1.u_core.mshrCtl.u_core.mshrs[7].entry.u_core.txnid_rcompack = u_g.inner_l2cache.slices_1.mshrCtl.mshrs_7.txnid_rcompack;
    force u_i.inner_l2cache.slices_1.u_core.mshrCtl.u_core.mshrs[7].entry.u_core.tgtid_wcompack = u_g.inner_l2cache.slices_1.mshrCtl.mshrs_7.tgtid_wcompack;
    force u_i.inner_l2cache.slices_1.u_core.mshrCtl.u_core.mshrs[7].entry.u_core.txnid_wcompack = u_g.inner_l2cache.slices_1.mshrCtl.mshrs_7.txnid_wcompack;
    force u_i.inner_l2cache.slices_1.u_core.mshrCtl.u_core.mshrs[7].entry.u_core.srcid_retryack = u_g.inner_l2cache.slices_1.mshrCtl.mshrs_7.srcid_retryack;
    force u_i.inner_l2cache.slices_1.u_core.mshrCtl.u_core.mshrs[7].entry.u_core.acquire_ts = u_g.inner_l2cache.slices_1.mshrCtl.mshrs_7.acquire_ts;
    force u_i.inner_l2cache.slices_1.u_core.mshrCtl.u_core.mshrs[7].entry.u_core.release_ts = u_g.inner_l2cache.slices_1.mshrCtl.mshrs_7.release_ts;
    force u_i.inner_l2cache.slices_1.u_core.mshrCtl.u_core.mshrs[7].entry.u_core.acquire_period_valid_REG = u_g.inner_l2cache.slices_1.mshrCtl.mshrs_7.acquire_period_valid_REG;
    force u_i.inner_l2cache.slices_1.u_core.mshrCtl.u_core.mshrs[7].entry.u_core.release_period_valid_REG = u_g.inner_l2cache.slices_1.mshrCtl.mshrs_7.release_period_valid_REG;
    force u_i.inner_l2cache.slices_1.u_core.mshrCtl.u_core.mshrs[7].entry.u_core.REG = u_g.inner_l2cache.slices_1.mshrCtl.mshrs_7.REG;
    force u_i.inner_l2cache.slices_1.u_core.mshrCtl.u_core.mshrs[7].entry.u_core.REG_1 = u_g.inner_l2cache.slices_1.mshrCtl.mshrs_7.REG_1;
    force u_i.inner_l2cache.slices_1.u_core.mshrCtl.u_core.mshrs[7].entry.u_core.REG_2 = u_g.inner_l2cache.slices_1.mshrCtl.mshrs_7.REG_2;
    force u_i.inner_l2cache.slices_1.u_core.mshrCtl.u_core.mshrs[7].entry.u_core.REG_3 = u_g.inner_l2cache.slices_1.mshrCtl.mshrs_7.REG_3;
    force u_i.inner_l2cache.slices_1.u_core.mshrCtl.u_core.mshrs[8].entry.u_core.tgtid_rcompack = u_g.inner_l2cache.slices_1.mshrCtl.mshrs_8.tgtid_rcompack;
    force u_i.inner_l2cache.slices_1.u_core.mshrCtl.u_core.mshrs[8].entry.u_core.txnid_rcompack = u_g.inner_l2cache.slices_1.mshrCtl.mshrs_8.txnid_rcompack;
    force u_i.inner_l2cache.slices_1.u_core.mshrCtl.u_core.mshrs[8].entry.u_core.tgtid_wcompack = u_g.inner_l2cache.slices_1.mshrCtl.mshrs_8.tgtid_wcompack;
    force u_i.inner_l2cache.slices_1.u_core.mshrCtl.u_core.mshrs[8].entry.u_core.txnid_wcompack = u_g.inner_l2cache.slices_1.mshrCtl.mshrs_8.txnid_wcompack;
    force u_i.inner_l2cache.slices_1.u_core.mshrCtl.u_core.mshrs[8].entry.u_core.srcid_retryack = u_g.inner_l2cache.slices_1.mshrCtl.mshrs_8.srcid_retryack;
    force u_i.inner_l2cache.slices_1.u_core.mshrCtl.u_core.mshrs[8].entry.u_core.acquire_ts = u_g.inner_l2cache.slices_1.mshrCtl.mshrs_8.acquire_ts;
    force u_i.inner_l2cache.slices_1.u_core.mshrCtl.u_core.mshrs[8].entry.u_core.release_ts = u_g.inner_l2cache.slices_1.mshrCtl.mshrs_8.release_ts;
    force u_i.inner_l2cache.slices_1.u_core.mshrCtl.u_core.mshrs[8].entry.u_core.acquire_period_valid_REG = u_g.inner_l2cache.slices_1.mshrCtl.mshrs_8.acquire_period_valid_REG;
    force u_i.inner_l2cache.slices_1.u_core.mshrCtl.u_core.mshrs[8].entry.u_core.release_period_valid_REG = u_g.inner_l2cache.slices_1.mshrCtl.mshrs_8.release_period_valid_REG;
    force u_i.inner_l2cache.slices_1.u_core.mshrCtl.u_core.mshrs[8].entry.u_core.REG = u_g.inner_l2cache.slices_1.mshrCtl.mshrs_8.REG;
    force u_i.inner_l2cache.slices_1.u_core.mshrCtl.u_core.mshrs[8].entry.u_core.REG_1 = u_g.inner_l2cache.slices_1.mshrCtl.mshrs_8.REG_1;
    force u_i.inner_l2cache.slices_1.u_core.mshrCtl.u_core.mshrs[8].entry.u_core.REG_2 = u_g.inner_l2cache.slices_1.mshrCtl.mshrs_8.REG_2;
    force u_i.inner_l2cache.slices_1.u_core.mshrCtl.u_core.mshrs[8].entry.u_core.REG_3 = u_g.inner_l2cache.slices_1.mshrCtl.mshrs_8.REG_3;
    force u_i.inner_l2cache.slices_1.u_core.mshrCtl.u_core.mshrs[9].entry.u_core.tgtid_rcompack = u_g.inner_l2cache.slices_1.mshrCtl.mshrs_9.tgtid_rcompack;
    force u_i.inner_l2cache.slices_1.u_core.mshrCtl.u_core.mshrs[9].entry.u_core.txnid_rcompack = u_g.inner_l2cache.slices_1.mshrCtl.mshrs_9.txnid_rcompack;
    force u_i.inner_l2cache.slices_1.u_core.mshrCtl.u_core.mshrs[9].entry.u_core.tgtid_wcompack = u_g.inner_l2cache.slices_1.mshrCtl.mshrs_9.tgtid_wcompack;
    force u_i.inner_l2cache.slices_1.u_core.mshrCtl.u_core.mshrs[9].entry.u_core.txnid_wcompack = u_g.inner_l2cache.slices_1.mshrCtl.mshrs_9.txnid_wcompack;
    force u_i.inner_l2cache.slices_1.u_core.mshrCtl.u_core.mshrs[9].entry.u_core.srcid_retryack = u_g.inner_l2cache.slices_1.mshrCtl.mshrs_9.srcid_retryack;
    force u_i.inner_l2cache.slices_1.u_core.mshrCtl.u_core.mshrs[9].entry.u_core.acquire_ts = u_g.inner_l2cache.slices_1.mshrCtl.mshrs_9.acquire_ts;
    force u_i.inner_l2cache.slices_1.u_core.mshrCtl.u_core.mshrs[9].entry.u_core.release_ts = u_g.inner_l2cache.slices_1.mshrCtl.mshrs_9.release_ts;
    force u_i.inner_l2cache.slices_1.u_core.mshrCtl.u_core.mshrs[9].entry.u_core.acquire_period_valid_REG = u_g.inner_l2cache.slices_1.mshrCtl.mshrs_9.acquire_period_valid_REG;
    force u_i.inner_l2cache.slices_1.u_core.mshrCtl.u_core.mshrs[9].entry.u_core.release_period_valid_REG = u_g.inner_l2cache.slices_1.mshrCtl.mshrs_9.release_period_valid_REG;
    force u_i.inner_l2cache.slices_1.u_core.mshrCtl.u_core.mshrs[9].entry.u_core.REG = u_g.inner_l2cache.slices_1.mshrCtl.mshrs_9.REG;
    force u_i.inner_l2cache.slices_1.u_core.mshrCtl.u_core.mshrs[9].entry.u_core.REG_1 = u_g.inner_l2cache.slices_1.mshrCtl.mshrs_9.REG_1;
    force u_i.inner_l2cache.slices_1.u_core.mshrCtl.u_core.mshrs[9].entry.u_core.REG_2 = u_g.inner_l2cache.slices_1.mshrCtl.mshrs_9.REG_2;
    force u_i.inner_l2cache.slices_1.u_core.mshrCtl.u_core.mshrs[9].entry.u_core.REG_3 = u_g.inner_l2cache.slices_1.mshrCtl.mshrs_9.REG_3;
    force u_i.inner_l2cache.slices_1.u_core.mshrCtl.u_core.mshrs[10].entry.u_core.tgtid_rcompack = u_g.inner_l2cache.slices_1.mshrCtl.mshrs_10.tgtid_rcompack;
    force u_i.inner_l2cache.slices_1.u_core.mshrCtl.u_core.mshrs[10].entry.u_core.txnid_rcompack = u_g.inner_l2cache.slices_1.mshrCtl.mshrs_10.txnid_rcompack;
    force u_i.inner_l2cache.slices_1.u_core.mshrCtl.u_core.mshrs[10].entry.u_core.tgtid_wcompack = u_g.inner_l2cache.slices_1.mshrCtl.mshrs_10.tgtid_wcompack;
    force u_i.inner_l2cache.slices_1.u_core.mshrCtl.u_core.mshrs[10].entry.u_core.txnid_wcompack = u_g.inner_l2cache.slices_1.mshrCtl.mshrs_10.txnid_wcompack;
    force u_i.inner_l2cache.slices_1.u_core.mshrCtl.u_core.mshrs[10].entry.u_core.srcid_retryack = u_g.inner_l2cache.slices_1.mshrCtl.mshrs_10.srcid_retryack;
    force u_i.inner_l2cache.slices_1.u_core.mshrCtl.u_core.mshrs[10].entry.u_core.acquire_ts = u_g.inner_l2cache.slices_1.mshrCtl.mshrs_10.acquire_ts;
    force u_i.inner_l2cache.slices_1.u_core.mshrCtl.u_core.mshrs[10].entry.u_core.release_ts = u_g.inner_l2cache.slices_1.mshrCtl.mshrs_10.release_ts;
    force u_i.inner_l2cache.slices_1.u_core.mshrCtl.u_core.mshrs[10].entry.u_core.acquire_period_valid_REG = u_g.inner_l2cache.slices_1.mshrCtl.mshrs_10.acquire_period_valid_REG;
    force u_i.inner_l2cache.slices_1.u_core.mshrCtl.u_core.mshrs[10].entry.u_core.release_period_valid_REG = u_g.inner_l2cache.slices_1.mshrCtl.mshrs_10.release_period_valid_REG;
    force u_i.inner_l2cache.slices_1.u_core.mshrCtl.u_core.mshrs[10].entry.u_core.REG = u_g.inner_l2cache.slices_1.mshrCtl.mshrs_10.REG;
    force u_i.inner_l2cache.slices_1.u_core.mshrCtl.u_core.mshrs[10].entry.u_core.REG_1 = u_g.inner_l2cache.slices_1.mshrCtl.mshrs_10.REG_1;
    force u_i.inner_l2cache.slices_1.u_core.mshrCtl.u_core.mshrs[10].entry.u_core.REG_2 = u_g.inner_l2cache.slices_1.mshrCtl.mshrs_10.REG_2;
    force u_i.inner_l2cache.slices_1.u_core.mshrCtl.u_core.mshrs[10].entry.u_core.REG_3 = u_g.inner_l2cache.slices_1.mshrCtl.mshrs_10.REG_3;
    force u_i.inner_l2cache.slices_1.u_core.mshrCtl.u_core.mshrs[11].entry.u_core.tgtid_rcompack = u_g.inner_l2cache.slices_1.mshrCtl.mshrs_11.tgtid_rcompack;
    force u_i.inner_l2cache.slices_1.u_core.mshrCtl.u_core.mshrs[11].entry.u_core.txnid_rcompack = u_g.inner_l2cache.slices_1.mshrCtl.mshrs_11.txnid_rcompack;
    force u_i.inner_l2cache.slices_1.u_core.mshrCtl.u_core.mshrs[11].entry.u_core.tgtid_wcompack = u_g.inner_l2cache.slices_1.mshrCtl.mshrs_11.tgtid_wcompack;
    force u_i.inner_l2cache.slices_1.u_core.mshrCtl.u_core.mshrs[11].entry.u_core.txnid_wcompack = u_g.inner_l2cache.slices_1.mshrCtl.mshrs_11.txnid_wcompack;
    force u_i.inner_l2cache.slices_1.u_core.mshrCtl.u_core.mshrs[11].entry.u_core.srcid_retryack = u_g.inner_l2cache.slices_1.mshrCtl.mshrs_11.srcid_retryack;
    force u_i.inner_l2cache.slices_1.u_core.mshrCtl.u_core.mshrs[11].entry.u_core.acquire_ts = u_g.inner_l2cache.slices_1.mshrCtl.mshrs_11.acquire_ts;
    force u_i.inner_l2cache.slices_1.u_core.mshrCtl.u_core.mshrs[11].entry.u_core.release_ts = u_g.inner_l2cache.slices_1.mshrCtl.mshrs_11.release_ts;
    force u_i.inner_l2cache.slices_1.u_core.mshrCtl.u_core.mshrs[11].entry.u_core.acquire_period_valid_REG = u_g.inner_l2cache.slices_1.mshrCtl.mshrs_11.acquire_period_valid_REG;
    force u_i.inner_l2cache.slices_1.u_core.mshrCtl.u_core.mshrs[11].entry.u_core.release_period_valid_REG = u_g.inner_l2cache.slices_1.mshrCtl.mshrs_11.release_period_valid_REG;
    force u_i.inner_l2cache.slices_1.u_core.mshrCtl.u_core.mshrs[11].entry.u_core.REG = u_g.inner_l2cache.slices_1.mshrCtl.mshrs_11.REG;
    force u_i.inner_l2cache.slices_1.u_core.mshrCtl.u_core.mshrs[11].entry.u_core.REG_1 = u_g.inner_l2cache.slices_1.mshrCtl.mshrs_11.REG_1;
    force u_i.inner_l2cache.slices_1.u_core.mshrCtl.u_core.mshrs[11].entry.u_core.REG_2 = u_g.inner_l2cache.slices_1.mshrCtl.mshrs_11.REG_2;
    force u_i.inner_l2cache.slices_1.u_core.mshrCtl.u_core.mshrs[11].entry.u_core.REG_3 = u_g.inner_l2cache.slices_1.mshrCtl.mshrs_11.REG_3;
    force u_i.inner_l2cache.slices_1.u_core.mshrCtl.u_core.mshrs[12].entry.u_core.tgtid_rcompack = u_g.inner_l2cache.slices_1.mshrCtl.mshrs_12.tgtid_rcompack;
    force u_i.inner_l2cache.slices_1.u_core.mshrCtl.u_core.mshrs[12].entry.u_core.txnid_rcompack = u_g.inner_l2cache.slices_1.mshrCtl.mshrs_12.txnid_rcompack;
    force u_i.inner_l2cache.slices_1.u_core.mshrCtl.u_core.mshrs[12].entry.u_core.tgtid_wcompack = u_g.inner_l2cache.slices_1.mshrCtl.mshrs_12.tgtid_wcompack;
    force u_i.inner_l2cache.slices_1.u_core.mshrCtl.u_core.mshrs[12].entry.u_core.txnid_wcompack = u_g.inner_l2cache.slices_1.mshrCtl.mshrs_12.txnid_wcompack;
    force u_i.inner_l2cache.slices_1.u_core.mshrCtl.u_core.mshrs[12].entry.u_core.srcid_retryack = u_g.inner_l2cache.slices_1.mshrCtl.mshrs_12.srcid_retryack;
    force u_i.inner_l2cache.slices_1.u_core.mshrCtl.u_core.mshrs[12].entry.u_core.acquire_ts = u_g.inner_l2cache.slices_1.mshrCtl.mshrs_12.acquire_ts;
    force u_i.inner_l2cache.slices_1.u_core.mshrCtl.u_core.mshrs[12].entry.u_core.release_ts = u_g.inner_l2cache.slices_1.mshrCtl.mshrs_12.release_ts;
    force u_i.inner_l2cache.slices_1.u_core.mshrCtl.u_core.mshrs[12].entry.u_core.acquire_period_valid_REG = u_g.inner_l2cache.slices_1.mshrCtl.mshrs_12.acquire_period_valid_REG;
    force u_i.inner_l2cache.slices_1.u_core.mshrCtl.u_core.mshrs[12].entry.u_core.release_period_valid_REG = u_g.inner_l2cache.slices_1.mshrCtl.mshrs_12.release_period_valid_REG;
    force u_i.inner_l2cache.slices_1.u_core.mshrCtl.u_core.mshrs[12].entry.u_core.REG = u_g.inner_l2cache.slices_1.mshrCtl.mshrs_12.REG;
    force u_i.inner_l2cache.slices_1.u_core.mshrCtl.u_core.mshrs[12].entry.u_core.REG_1 = u_g.inner_l2cache.slices_1.mshrCtl.mshrs_12.REG_1;
    force u_i.inner_l2cache.slices_1.u_core.mshrCtl.u_core.mshrs[12].entry.u_core.REG_2 = u_g.inner_l2cache.slices_1.mshrCtl.mshrs_12.REG_2;
    force u_i.inner_l2cache.slices_1.u_core.mshrCtl.u_core.mshrs[12].entry.u_core.REG_3 = u_g.inner_l2cache.slices_1.mshrCtl.mshrs_12.REG_3;
    force u_i.inner_l2cache.slices_1.u_core.mshrCtl.u_core.mshrs[13].entry.u_core.tgtid_rcompack = u_g.inner_l2cache.slices_1.mshrCtl.mshrs_13.tgtid_rcompack;
    force u_i.inner_l2cache.slices_1.u_core.mshrCtl.u_core.mshrs[13].entry.u_core.txnid_rcompack = u_g.inner_l2cache.slices_1.mshrCtl.mshrs_13.txnid_rcompack;
    force u_i.inner_l2cache.slices_1.u_core.mshrCtl.u_core.mshrs[13].entry.u_core.tgtid_wcompack = u_g.inner_l2cache.slices_1.mshrCtl.mshrs_13.tgtid_wcompack;
    force u_i.inner_l2cache.slices_1.u_core.mshrCtl.u_core.mshrs[13].entry.u_core.txnid_wcompack = u_g.inner_l2cache.slices_1.mshrCtl.mshrs_13.txnid_wcompack;
    force u_i.inner_l2cache.slices_1.u_core.mshrCtl.u_core.mshrs[13].entry.u_core.srcid_retryack = u_g.inner_l2cache.slices_1.mshrCtl.mshrs_13.srcid_retryack;
    force u_i.inner_l2cache.slices_1.u_core.mshrCtl.u_core.mshrs[13].entry.u_core.acquire_ts = u_g.inner_l2cache.slices_1.mshrCtl.mshrs_13.acquire_ts;
    force u_i.inner_l2cache.slices_1.u_core.mshrCtl.u_core.mshrs[13].entry.u_core.release_ts = u_g.inner_l2cache.slices_1.mshrCtl.mshrs_13.release_ts;
    force u_i.inner_l2cache.slices_1.u_core.mshrCtl.u_core.mshrs[13].entry.u_core.acquire_period_valid_REG = u_g.inner_l2cache.slices_1.mshrCtl.mshrs_13.acquire_period_valid_REG;
    force u_i.inner_l2cache.slices_1.u_core.mshrCtl.u_core.mshrs[13].entry.u_core.release_period_valid_REG = u_g.inner_l2cache.slices_1.mshrCtl.mshrs_13.release_period_valid_REG;
    force u_i.inner_l2cache.slices_1.u_core.mshrCtl.u_core.mshrs[13].entry.u_core.REG = u_g.inner_l2cache.slices_1.mshrCtl.mshrs_13.REG;
    force u_i.inner_l2cache.slices_1.u_core.mshrCtl.u_core.mshrs[13].entry.u_core.REG_1 = u_g.inner_l2cache.slices_1.mshrCtl.mshrs_13.REG_1;
    force u_i.inner_l2cache.slices_1.u_core.mshrCtl.u_core.mshrs[13].entry.u_core.REG_2 = u_g.inner_l2cache.slices_1.mshrCtl.mshrs_13.REG_2;
    force u_i.inner_l2cache.slices_1.u_core.mshrCtl.u_core.mshrs[13].entry.u_core.REG_3 = u_g.inner_l2cache.slices_1.mshrCtl.mshrs_13.REG_3;
    force u_i.inner_l2cache.slices_1.u_core.mshrCtl.u_core.mshrs[14].entry.u_core.tgtid_rcompack = u_g.inner_l2cache.slices_1.mshrCtl.mshrs_14.tgtid_rcompack;
    force u_i.inner_l2cache.slices_1.u_core.mshrCtl.u_core.mshrs[14].entry.u_core.txnid_rcompack = u_g.inner_l2cache.slices_1.mshrCtl.mshrs_14.txnid_rcompack;
    force u_i.inner_l2cache.slices_1.u_core.mshrCtl.u_core.mshrs[14].entry.u_core.tgtid_wcompack = u_g.inner_l2cache.slices_1.mshrCtl.mshrs_14.tgtid_wcompack;
    force u_i.inner_l2cache.slices_1.u_core.mshrCtl.u_core.mshrs[14].entry.u_core.txnid_wcompack = u_g.inner_l2cache.slices_1.mshrCtl.mshrs_14.txnid_wcompack;
    force u_i.inner_l2cache.slices_1.u_core.mshrCtl.u_core.mshrs[14].entry.u_core.srcid_retryack = u_g.inner_l2cache.slices_1.mshrCtl.mshrs_14.srcid_retryack;
    force u_i.inner_l2cache.slices_1.u_core.mshrCtl.u_core.mshrs[14].entry.u_core.acquire_ts = u_g.inner_l2cache.slices_1.mshrCtl.mshrs_14.acquire_ts;
    force u_i.inner_l2cache.slices_1.u_core.mshrCtl.u_core.mshrs[14].entry.u_core.release_ts = u_g.inner_l2cache.slices_1.mshrCtl.mshrs_14.release_ts;
    force u_i.inner_l2cache.slices_1.u_core.mshrCtl.u_core.mshrs[14].entry.u_core.acquire_period_valid_REG = u_g.inner_l2cache.slices_1.mshrCtl.mshrs_14.acquire_period_valid_REG;
    force u_i.inner_l2cache.slices_1.u_core.mshrCtl.u_core.mshrs[14].entry.u_core.release_period_valid_REG = u_g.inner_l2cache.slices_1.mshrCtl.mshrs_14.release_period_valid_REG;
    force u_i.inner_l2cache.slices_1.u_core.mshrCtl.u_core.mshrs[14].entry.u_core.REG = u_g.inner_l2cache.slices_1.mshrCtl.mshrs_14.REG;
    force u_i.inner_l2cache.slices_1.u_core.mshrCtl.u_core.mshrs[14].entry.u_core.REG_1 = u_g.inner_l2cache.slices_1.mshrCtl.mshrs_14.REG_1;
    force u_i.inner_l2cache.slices_1.u_core.mshrCtl.u_core.mshrs[14].entry.u_core.REG_2 = u_g.inner_l2cache.slices_1.mshrCtl.mshrs_14.REG_2;
    force u_i.inner_l2cache.slices_1.u_core.mshrCtl.u_core.mshrs[14].entry.u_core.REG_3 = u_g.inner_l2cache.slices_1.mshrCtl.mshrs_14.REG_3;
    force u_i.inner_l2cache.slices_1.u_core.mshrCtl.u_core.mshrs[15].entry.u_core.tgtid_rcompack = u_g.inner_l2cache.slices_1.mshrCtl.mshrs_15.tgtid_rcompack;
    force u_i.inner_l2cache.slices_1.u_core.mshrCtl.u_core.mshrs[15].entry.u_core.txnid_rcompack = u_g.inner_l2cache.slices_1.mshrCtl.mshrs_15.txnid_rcompack;
    force u_i.inner_l2cache.slices_1.u_core.mshrCtl.u_core.mshrs[15].entry.u_core.tgtid_wcompack = u_g.inner_l2cache.slices_1.mshrCtl.mshrs_15.tgtid_wcompack;
    force u_i.inner_l2cache.slices_1.u_core.mshrCtl.u_core.mshrs[15].entry.u_core.txnid_wcompack = u_g.inner_l2cache.slices_1.mshrCtl.mshrs_15.txnid_wcompack;
    force u_i.inner_l2cache.slices_1.u_core.mshrCtl.u_core.mshrs[15].entry.u_core.srcid_retryack = u_g.inner_l2cache.slices_1.mshrCtl.mshrs_15.srcid_retryack;
    force u_i.inner_l2cache.slices_1.u_core.mshrCtl.u_core.mshrs[15].entry.u_core.acquire_ts = u_g.inner_l2cache.slices_1.mshrCtl.mshrs_15.acquire_ts;
    force u_i.inner_l2cache.slices_1.u_core.mshrCtl.u_core.mshrs[15].entry.u_core.release_ts = u_g.inner_l2cache.slices_1.mshrCtl.mshrs_15.release_ts;
    force u_i.inner_l2cache.slices_1.u_core.mshrCtl.u_core.mshrs[15].entry.u_core.acquire_period_valid_REG = u_g.inner_l2cache.slices_1.mshrCtl.mshrs_15.acquire_period_valid_REG;
    force u_i.inner_l2cache.slices_1.u_core.mshrCtl.u_core.mshrs[15].entry.u_core.release_period_valid_REG = u_g.inner_l2cache.slices_1.mshrCtl.mshrs_15.release_period_valid_REG;
    force u_i.inner_l2cache.slices_1.u_core.mshrCtl.u_core.mshrs[15].entry.u_core.REG = u_g.inner_l2cache.slices_1.mshrCtl.mshrs_15.REG;
    force u_i.inner_l2cache.slices_1.u_core.mshrCtl.u_core.mshrs[15].entry.u_core.REG_1 = u_g.inner_l2cache.slices_1.mshrCtl.mshrs_15.REG_1;
    force u_i.inner_l2cache.slices_1.u_core.mshrCtl.u_core.mshrs[15].entry.u_core.REG_2 = u_g.inner_l2cache.slices_1.mshrCtl.mshrs_15.REG_2;
    force u_i.inner_l2cache.slices_1.u_core.mshrCtl.u_core.mshrs[15].entry.u_core.REG_3 = u_g.inner_l2cache.slices_1.mshrCtl.mshrs_15.REG_3;
    force u_i.inner_l2cache.slices_1.u_core.mshrCtl.u_core.io_perf_0_value_REG = u_g.inner_l2cache.slices_1.mshrCtl.io_perf_0_value_REG;
    force u_i.inner_l2cache.slices_1.u_core.mshrCtl.u_core.io_perf_0_value_REG_1 = u_g.inner_l2cache.slices_1.mshrCtl.io_perf_0_value_REG_1;
    force u_i.inner_l2cache.slices_1.u_core.mshrCtl.u_core.io_perf_1_value_REG = u_g.inner_l2cache.slices_1.mshrCtl.io_perf_1_value_REG;
    force u_i.inner_l2cache.slices_1.u_core.mshrCtl.u_core.io_perf_1_value_REG_1 = u_g.inner_l2cache.slices_1.mshrCtl.io_perf_1_value_REG_1;
    force u_i.inner_l2cache.slices_1.u_core.mshrCtl.u_core.io_perf_3_value_REG = u_g.inner_l2cache.slices_1.mshrCtl.io_perf_3_value_REG;
    force u_i.inner_l2cache.slices_1.u_core.mshrCtl.u_core.io_perf_3_value_REG_1 = u_g.inner_l2cache.slices_1.mshrCtl.io_perf_3_value_REG_1;
    force u_i.inner_l2cache.slices_1.u_core.mshrCtl.u_core.REG = u_g.inner_l2cache.slices_1.mshrCtl.REG;
    force u_i.inner_l2cache.slices_1.u_core.mainPipe.u_core.data_s4 = u_g.inner_l2cache.slices_1.mainPipe.data_s4;
    force u_i.inner_l2cache.slices_1.u_core.mainPipe.u_core.data_s5 = u_g.inner_l2cache.slices_1.mainPipe.data_s5;
    force u_i.inner_l2cache.slices_1.u_core.mainPipe.u_core.s3DropValid_d1 = u_g.inner_l2cache.slices_1.mainPipe.REG;
    force u_i.inner_l2cache.slices_1.u_core.mainPipe.u_core.reqDrop_s3_d1 = u_g.inner_l2cache.slices_1.mainPipe.reqDropped_s5_REG;
    force u_i.inner_l2cache.slices_1.u_core.mainPipe.u_core.reqDrop_s3_d2 = u_g.inner_l2cache.slices_1.mainPipe.reqDropped_s5_REG_1;
    force u_i.inner_l2cache.slices_1.u_core.mainPipe.u_core.reqDrop_s4_d1 = u_g.inner_l2cache.slices_1.mainPipe.reqDropped_s5_REG_2;
    u_i.inner_l2cache.slices_1.u_core.mainPipe.customL1Hint.hintQueue.ram_ext.Memory = u_g.inner_l2cache.slices_1.mainPipe.customL1Hint.hintQueue.ram_ext.Memory;
    u_i.inner_l2cache.slices_1.u_core.mainPipe.customL1Hint.hint_s1Queue.ram_ext.Memory = u_g.inner_l2cache.slices_1.mainPipe.customL1Hint.hint_s1Queue.ram_ext.Memory;
    force u_i.inner_l2cache.slices_1.u_core.mainPipe.u_core.perf_d1[0] = u_g.inner_l2cache.slices_1.mainPipe.io_perf_0_value_REG;
    force u_i.inner_l2cache.slices_1.u_core.mainPipe.u_core.perf[0] = u_g.inner_l2cache.slices_1.mainPipe.io_perf_0_value_REG_1;
    force u_i.inner_l2cache.slices_1.u_core.mainPipe.u_core.perf_d1[1] = u_g.inner_l2cache.slices_1.mainPipe.io_perf_1_value_REG;
    force u_i.inner_l2cache.slices_1.u_core.mainPipe.u_core.perf[1] = u_g.inner_l2cache.slices_1.mainPipe.io_perf_1_value_REG_1;
    force u_i.inner_l2cache.slices_1.u_core.mainPipe.u_core.perf_d1[2] = u_g.inner_l2cache.slices_1.mainPipe.io_perf_2_value_REG;
    force u_i.inner_l2cache.slices_1.u_core.mainPipe.u_core.perf[2] = u_g.inner_l2cache.slices_1.mainPipe.io_perf_2_value_REG_1;
    force u_i.inner_l2cache.slices_1.u_core.mainPipe.u_core.perf_d1[3] = u_g.inner_l2cache.slices_1.mainPipe.io_perf_3_value_REG;
    force u_i.inner_l2cache.slices_1.u_core.mainPipe.u_core.perf[3] = u_g.inner_l2cache.slices_1.mainPipe.io_perf_3_value_REG_1;
    force u_i.inner_l2cache.slices_1.u_core.mainPipe.u_core.perf_d1[4] = u_g.inner_l2cache.slices_1.mainPipe.io_perf_4_value_REG;
    force u_i.inner_l2cache.slices_1.u_core.mainPipe.u_core.perf[4] = u_g.inner_l2cache.slices_1.mainPipe.io_perf_4_value_REG_1;
    force u_i.inner_l2cache.slices_1.u_core.mainPipe.u_core.perf_d1[5] = u_g.inner_l2cache.slices_1.mainPipe.io_perf_5_value_REG;
    force u_i.inner_l2cache.slices_1.u_core.mainPipe.u_core.perf[5] = u_g.inner_l2cache.slices_1.mainPipe.io_perf_5_value_REG_1;
    force u_i.inner_l2cache.slices_1.u_core.mainPipe.u_core.perf_d1[6] = u_g.inner_l2cache.slices_1.mainPipe.io_perf_6_value_REG;
    force u_i.inner_l2cache.slices_1.u_core.mainPipe.u_core.perf[6] = u_g.inner_l2cache.slices_1.mainPipe.io_perf_6_value_REG_1;
    force u_i.inner_l2cache.slices_1.u_core.mainPipe.u_core.perf_d1[7] = u_g.inner_l2cache.slices_1.mainPipe.io_perf_7_value_REG;
    force u_i.inner_l2cache.slices_1.u_core.mainPipe.u_core.perf[7] = u_g.inner_l2cache.slices_1.mainPipe.io_perf_7_value_REG_1;
    force u_i.inner_l2cache.slices_1.u_core.mainPipe.u_core.perf_d1[8] = u_g.inner_l2cache.slices_1.mainPipe.io_perf_8_value_REG;
    force u_i.inner_l2cache.slices_1.u_core.mainPipe.u_core.perf[8] = u_g.inner_l2cache.slices_1.mainPipe.io_perf_8_value_REG_1;
    force u_i.inner_l2cache.slices_1.u_core.mainPipe.u_core.perf_d1[9] = u_g.inner_l2cache.slices_1.mainPipe.io_perf_9_value_REG;
    force u_i.inner_l2cache.slices_1.u_core.mainPipe.u_core.perf[9] = u_g.inner_l2cache.slices_1.mainPipe.io_perf_9_value_REG_1;
    force u_i.inner_l2cache.slices_1.u_core.mainPipe.u_core.perf_d1[10] = u_g.inner_l2cache.slices_1.mainPipe.io_perf_10_value_REG;
    force u_i.inner_l2cache.slices_1.u_core.mainPipe.u_core.perf[10] = u_g.inner_l2cache.slices_1.mainPipe.io_perf_10_value_REG_1;
    force u_i.inner_l2cache.slices_1.u_core.mainPipe.u_core.perf_d1[11] = u_g.inner_l2cache.slices_1.mainPipe.io_perf_11_value_REG;
    force u_i.inner_l2cache.slices_1.u_core.mainPipe.u_core.perf[11] = u_g.inner_l2cache.slices_1.mainPipe.io_perf_11_value_REG_1;
    force u_i.inner_l2cache.slices_1.u_core.mainPipe.u_core.perf_d1[12] = u_g.inner_l2cache.slices_1.mainPipe.io_perf_12_value_REG;
    force u_i.inner_l2cache.slices_1.u_core.mainPipe.u_core.perf[12] = u_g.inner_l2cache.slices_1.mainPipe.io_perf_12_value_REG_1;
    u_i.inner_l2cache.slices_1.u_core.grantBuf.grantQueue.ram_ext.Memory = u_g.inner_l2cache.slices_1.grantBuf.grantQueue.ram_ext.Memory;
    u_i.inner_l2cache.slices_1.u_core.grantBuf.grantQueueData0.ram_data_data_ext.Memory = u_g.inner_l2cache.slices_1.grantBuf.grantQueueData0.ram_data_data_ext.Memory;
    u_i.inner_l2cache.slices_1.u_core.grantBuf.grantQueueData1.ram_data_data_ext.Memory = u_g.inner_l2cache.slices_1.grantBuf.grantQueueData1.ram_data_data_ext.Memory;
    u_i.inner_l2cache.slices_1.u_core.grantBuf.pftRespQueue.ram_ext.Memory = u_g.inner_l2cache.slices_1.grantBuf.pftRespQueue.ram_ext.Memory;
    force u_i.inner_l2cache.slices_1.u_core.grantBuf.u_core.validPrev[0] = u_g.inner_l2cache.slices_1.grantBuf.REG;
    force u_i.inner_l2cache.slices_1.u_core.grantBuf.u_core.histValidPrev[0] = u_g.inner_l2cache.slices_1.grantBuf.enable_REG;
    force u_i.inner_l2cache.slices_1.u_core.grantBuf.u_core.validPrev[1] = u_g.inner_l2cache.slices_1.grantBuf.REG_1;
    force u_i.inner_l2cache.slices_1.u_core.grantBuf.u_core.histValidPrev[1] = u_g.inner_l2cache.slices_1.grantBuf.enable_REG_1;
    force u_i.inner_l2cache.slices_1.u_core.grantBuf.u_core.validPrev[2] = u_g.inner_l2cache.slices_1.grantBuf.REG_2;
    force u_i.inner_l2cache.slices_1.u_core.grantBuf.u_core.histValidPrev[2] = u_g.inner_l2cache.slices_1.grantBuf.enable_REG_2;
    force u_i.inner_l2cache.slices_1.u_core.grantBuf.u_core.validPrev[3] = u_g.inner_l2cache.slices_1.grantBuf.REG_3;
    force u_i.inner_l2cache.slices_1.u_core.grantBuf.u_core.histValidPrev[3] = u_g.inner_l2cache.slices_1.grantBuf.enable_REG_3;
    force u_i.inner_l2cache.slices_1.u_core.grantBuf.u_core.validPrev[4] = u_g.inner_l2cache.slices_1.grantBuf.REG_4;
    force u_i.inner_l2cache.slices_1.u_core.grantBuf.u_core.histValidPrev[4] = u_g.inner_l2cache.slices_1.grantBuf.enable_REG_4;
    force u_i.inner_l2cache.slices_1.u_core.grantBuf.u_core.validPrev[5] = u_g.inner_l2cache.slices_1.grantBuf.REG_5;
    force u_i.inner_l2cache.slices_1.u_core.grantBuf.u_core.histValidPrev[5] = u_g.inner_l2cache.slices_1.grantBuf.enable_REG_5;
    force u_i.inner_l2cache.slices_1.u_core.grantBuf.u_core.validPrev[6] = u_g.inner_l2cache.slices_1.grantBuf.REG_6;
    force u_i.inner_l2cache.slices_1.u_core.grantBuf.u_core.histValidPrev[6] = u_g.inner_l2cache.slices_1.grantBuf.enable_REG_6;
    force u_i.inner_l2cache.slices_1.u_core.grantBuf.u_core.validPrev[7] = u_g.inner_l2cache.slices_1.grantBuf.REG_7;
    force u_i.inner_l2cache.slices_1.u_core.grantBuf.u_core.histValidPrev[7] = u_g.inner_l2cache.slices_1.grantBuf.enable_REG_7;
    force u_i.inner_l2cache.slices_1.u_core.grantBuf.u_core.validPrev[8] = u_g.inner_l2cache.slices_1.grantBuf.REG_8;
    force u_i.inner_l2cache.slices_1.u_core.grantBuf.u_core.histValidPrev[8] = u_g.inner_l2cache.slices_1.grantBuf.enable_REG_8;
    force u_i.inner_l2cache.slices_1.u_core.grantBuf.u_core.validPrev[9] = u_g.inner_l2cache.slices_1.grantBuf.REG_9;
    force u_i.inner_l2cache.slices_1.u_core.grantBuf.u_core.histValidPrev[9] = u_g.inner_l2cache.slices_1.grantBuf.enable_REG_9;
    force u_i.inner_l2cache.slices_1.u_core.grantBuf.u_core.validPrev[10] = u_g.inner_l2cache.slices_1.grantBuf.REG_10;
    force u_i.inner_l2cache.slices_1.u_core.grantBuf.u_core.histValidPrev[10] = u_g.inner_l2cache.slices_1.grantBuf.enable_REG_10;
    force u_i.inner_l2cache.slices_1.u_core.grantBuf.u_core.validPrev[11] = u_g.inner_l2cache.slices_1.grantBuf.REG_11;
    force u_i.inner_l2cache.slices_1.u_core.grantBuf.u_core.histValidPrev[11] = u_g.inner_l2cache.slices_1.grantBuf.enable_REG_11;
    force u_i.inner_l2cache.slices_1.u_core.grantBuf.u_core.validPrev[12] = u_g.inner_l2cache.slices_1.grantBuf.REG_12;
    force u_i.inner_l2cache.slices_1.u_core.grantBuf.u_core.histValidPrev[12] = u_g.inner_l2cache.slices_1.grantBuf.enable_REG_12;
    force u_i.inner_l2cache.slices_1.u_core.grantBuf.u_core.validPrev[13] = u_g.inner_l2cache.slices_1.grantBuf.REG_13;
    force u_i.inner_l2cache.slices_1.u_core.grantBuf.u_core.histValidPrev[13] = u_g.inner_l2cache.slices_1.grantBuf.enable_REG_13;
    force u_i.inner_l2cache.slices_1.u_core.grantBuf.u_core.validPrev[14] = u_g.inner_l2cache.slices_1.grantBuf.REG_14;
    force u_i.inner_l2cache.slices_1.u_core.grantBuf.u_core.histValidPrev[14] = u_g.inner_l2cache.slices_1.grantBuf.enable_REG_14;
    force u_i.inner_l2cache.slices_1.u_core.grantBuf.u_core.validPrev[15] = u_g.inner_l2cache.slices_1.grantBuf.REG_15;
    force u_i.inner_l2cache.slices_1.u_core.grantBuf.u_core.histValidPrev[15] = u_g.inner_l2cache.slices_1.grantBuf.enable_REG_15;
    u_i.inner_l2cache.slices_1.u_core.rxsnp.queue.ram_ext.Memory = u_g.inner_l2cache.slices_1.rxsnp.queue.ram_ext.Memory;
    force u_i.inner_l2cache.slices_1.u_core.rxsnp.u_core.replPrevForBlock[0] = u_g.inner_l2cache.slices_1.rxsnp.replaceBlockSnpMask_REG;
    force u_i.inner_l2cache.slices_1.u_core.rxsnp.u_core.replPrevForNest[0] = u_g.inner_l2cache.slices_1.rxsnp.replaceNestSnpMask_REG;
    force u_i.inner_l2cache.slices_1.u_core.rxsnp.u_core.replPrevForBlock[1] = u_g.inner_l2cache.slices_1.rxsnp.replaceBlockSnpMask_REG_1;
    force u_i.inner_l2cache.slices_1.u_core.rxsnp.u_core.replPrevForNest[1] = u_g.inner_l2cache.slices_1.rxsnp.replaceNestSnpMask_REG_1;
    force u_i.inner_l2cache.slices_1.u_core.rxsnp.u_core.replPrevForBlock[2] = u_g.inner_l2cache.slices_1.rxsnp.replaceBlockSnpMask_REG_2;
    force u_i.inner_l2cache.slices_1.u_core.rxsnp.u_core.replPrevForNest[2] = u_g.inner_l2cache.slices_1.rxsnp.replaceNestSnpMask_REG_2;
    force u_i.inner_l2cache.slices_1.u_core.rxsnp.u_core.replPrevForBlock[3] = u_g.inner_l2cache.slices_1.rxsnp.replaceBlockSnpMask_REG_3;
    force u_i.inner_l2cache.slices_1.u_core.rxsnp.u_core.replPrevForNest[3] = u_g.inner_l2cache.slices_1.rxsnp.replaceNestSnpMask_REG_3;
    force u_i.inner_l2cache.slices_1.u_core.rxsnp.u_core.replPrevForBlock[4] = u_g.inner_l2cache.slices_1.rxsnp.replaceBlockSnpMask_REG_4;
    force u_i.inner_l2cache.slices_1.u_core.rxsnp.u_core.replPrevForNest[4] = u_g.inner_l2cache.slices_1.rxsnp.replaceNestSnpMask_REG_4;
    force u_i.inner_l2cache.slices_1.u_core.rxsnp.u_core.replPrevForBlock[5] = u_g.inner_l2cache.slices_1.rxsnp.replaceBlockSnpMask_REG_5;
    force u_i.inner_l2cache.slices_1.u_core.rxsnp.u_core.replPrevForNest[5] = u_g.inner_l2cache.slices_1.rxsnp.replaceNestSnpMask_REG_5;
    force u_i.inner_l2cache.slices_1.u_core.rxsnp.u_core.replPrevForBlock[6] = u_g.inner_l2cache.slices_1.rxsnp.replaceBlockSnpMask_REG_6;
    force u_i.inner_l2cache.slices_1.u_core.rxsnp.u_core.replPrevForNest[6] = u_g.inner_l2cache.slices_1.rxsnp.replaceNestSnpMask_REG_6;
    force u_i.inner_l2cache.slices_1.u_core.rxsnp.u_core.replPrevForBlock[7] = u_g.inner_l2cache.slices_1.rxsnp.replaceBlockSnpMask_REG_7;
    force u_i.inner_l2cache.slices_1.u_core.rxsnp.u_core.replPrevForNest[7] = u_g.inner_l2cache.slices_1.rxsnp.replaceNestSnpMask_REG_7;
    force u_i.inner_l2cache.slices_1.u_core.rxsnp.u_core.replPrevForBlock[8] = u_g.inner_l2cache.slices_1.rxsnp.replaceBlockSnpMask_REG_8;
    force u_i.inner_l2cache.slices_1.u_core.rxsnp.u_core.replPrevForNest[8] = u_g.inner_l2cache.slices_1.rxsnp.replaceNestSnpMask_REG_8;
    force u_i.inner_l2cache.slices_1.u_core.rxsnp.u_core.replPrevForBlock[9] = u_g.inner_l2cache.slices_1.rxsnp.replaceBlockSnpMask_REG_9;
    force u_i.inner_l2cache.slices_1.u_core.rxsnp.u_core.replPrevForNest[9] = u_g.inner_l2cache.slices_1.rxsnp.replaceNestSnpMask_REG_9;
    force u_i.inner_l2cache.slices_1.u_core.rxsnp.u_core.replPrevForBlock[10] = u_g.inner_l2cache.slices_1.rxsnp.replaceBlockSnpMask_REG_10;
    force u_i.inner_l2cache.slices_1.u_core.rxsnp.u_core.replPrevForNest[10] = u_g.inner_l2cache.slices_1.rxsnp.replaceNestSnpMask_REG_10;
    force u_i.inner_l2cache.slices_1.u_core.rxsnp.u_core.replPrevForBlock[11] = u_g.inner_l2cache.slices_1.rxsnp.replaceBlockSnpMask_REG_11;
    force u_i.inner_l2cache.slices_1.u_core.rxsnp.u_core.replPrevForNest[11] = u_g.inner_l2cache.slices_1.rxsnp.replaceNestSnpMask_REG_11;
    force u_i.inner_l2cache.slices_1.u_core.rxsnp.u_core.replPrevForBlock[12] = u_g.inner_l2cache.slices_1.rxsnp.replaceBlockSnpMask_REG_12;
    force u_i.inner_l2cache.slices_1.u_core.rxsnp.u_core.replPrevForNest[12] = u_g.inner_l2cache.slices_1.rxsnp.replaceNestSnpMask_REG_12;
    force u_i.inner_l2cache.slices_1.u_core.rxsnp.u_core.replPrevForBlock[13] = u_g.inner_l2cache.slices_1.rxsnp.replaceBlockSnpMask_REG_13;
    force u_i.inner_l2cache.slices_1.u_core.rxsnp.u_core.replPrevForNest[13] = u_g.inner_l2cache.slices_1.rxsnp.replaceNestSnpMask_REG_13;
    force u_i.inner_l2cache.slices_1.u_core.rxsnp.u_core.replPrevForBlock[14] = u_g.inner_l2cache.slices_1.rxsnp.replaceBlockSnpMask_REG_14;
    force u_i.inner_l2cache.slices_1.u_core.rxsnp.u_core.replPrevForNest[14] = u_g.inner_l2cache.slices_1.rxsnp.replaceNestSnpMask_REG_14;
    force u_i.inner_l2cache.slices_1.u_core.rxsnp.u_core.replPrevForBlock[15] = u_g.inner_l2cache.slices_1.rxsnp.replaceBlockSnpMask_REG_15;
    force u_i.inner_l2cache.slices_1.u_core.rxsnp.u_core.replPrevForNest[15] = u_g.inner_l2cache.slices_1.rxsnp.replaceNestSnpMask_REG_15;
    force u_i.inner_l2cache.slices_1.u_core.reqBuf.chosenQ.u_core.ram = u_g.inner_l2cache.slices_1.reqBuf.chosenQ.ram;
    force u_i.inner_l2cache.slices_1.u_core.reqBuf.u_core.hitPfPrev_set = u_g.inner_l2cache.slices_1.reqBuf.io_hasHitPfInMSHR_valid_REG_set;
    force u_i.inner_l2cache.slices_1.u_core.reqBuf.u_core.hitPfPrev_tag = u_g.inner_l2cache.slices_1.reqBuf.io_hasHitPfInMSHR_valid_REG_tag;
    force u_i.inner_l2cache.slices_1.u_core.reqBuf.u_core.mergeAPrev_set = u_g.inner_l2cache.slices_1.reqBuf.io_hasMergeA_REG_set;
    force u_i.inner_l2cache.slices_1.u_core.reqBuf.u_core.mergeAPrev_tag = u_g.inner_l2cache.slices_1.reqBuf.io_hasMergeA_REG_tag;
    force u_i.inner_l2cache.slices_1.u_core.reqBuf.u_core.sameSetS3Valid[0] = u_g.inner_l2cache.slices_1.reqBuf.canFlow_sameSet_s3_REG;
    force u_i.inner_l2cache.slices_1.u_core.reqBuf.u_core.sameSetS3Set[0] = u_g.inner_l2cache.slices_1.reqBuf.canFlow_sameSet_s3_r;
    force u_i.inner_l2cache.slices_1.u_core.reqBuf.u_core.sameSetS3Valid[1] = u_g.inner_l2cache.slices_1.reqBuf.buffer_rdy_sameSet_s3_REG;
    force u_i.inner_l2cache.slices_1.u_core.reqBuf.u_core.sameSetS3Set[1] = u_g.inner_l2cache.slices_1.reqBuf.buffer_rdy_sameSet_s3_r;
    force u_i.inner_l2cache.slices_1.u_core.reqBuf.u_core.sameSetS3Valid[2] = u_g.inner_l2cache.slices_1.reqBuf.buffer_0_rdy_sameSet_s3_REG;
    force u_i.inner_l2cache.slices_1.u_core.reqBuf.u_core.sameSetS3Set[2] = u_g.inner_l2cache.slices_1.reqBuf.buffer_0_rdy_sameSet_s3_r;
    force u_i.inner_l2cache.slices_1.u_core.reqBuf.u_core.sameSetS3Valid[3] = u_g.inner_l2cache.slices_1.reqBuf.buffer_1_rdy_sameSet_s3_REG;
    force u_i.inner_l2cache.slices_1.u_core.reqBuf.u_core.sameSetS3Set[3] = u_g.inner_l2cache.slices_1.reqBuf.buffer_1_rdy_sameSet_s3_r;
    force u_i.inner_l2cache.slices_1.u_core.reqBuf.u_core.sameSetS3Valid[4] = u_g.inner_l2cache.slices_1.reqBuf.buffer_2_rdy_sameSet_s3_REG;
    force u_i.inner_l2cache.slices_1.u_core.reqBuf.u_core.sameSetS3Set[4] = u_g.inner_l2cache.slices_1.reqBuf.buffer_2_rdy_sameSet_s3_r;
    force u_i.inner_l2cache.slices_1.u_core.reqBuf.u_core.sameSetS3Valid[5] = u_g.inner_l2cache.slices_1.reqBuf.buffer_3_rdy_sameSet_s3_REG;
    force u_i.inner_l2cache.slices_1.u_core.reqBuf.u_core.sameSetS3Set[5] = u_g.inner_l2cache.slices_1.reqBuf.buffer_3_rdy_sameSet_s3_r;
    force u_i.inner_l2cache.slices_1.u_core.sinkC.u_core.bufRespStage[0] = u_g.inner_l2cache.slices_1.sinkC.r_0;
    force u_i.inner_l2cache.slices_1.u_core.sinkC.u_core.bufRespStage[1] = u_g.inner_l2cache.slices_1.sinkC.r_1;
    force u_i.inner_l2cache.slices_1.u_core.sinkC.u_core.bufRespOut[0] = u_g.inner_l2cache.slices_1.sinkC.REG_0;
    force u_i.inner_l2cache.slices_1.u_core.sinkC.u_core.bufRespOut[1] = u_g.inner_l2cache.slices_1.sinkC.REG_1;
    force u_i.inner_l2cache.slices_1.u_core.sinkC.u_core.refillIdReg = u_g.inner_l2cache.slices_1.sinkC.io_refillBufWrite_bits_id_REG;
    force u_i.inner_l2cache.slices_1.u_core.sinkC.u_core.refillBufIdxReg = u_g.inner_l2cache.slices_1.sinkC.io_refillBufWrite_bits_data_data_REG;
    force u_i.inner_l2cache.slices_1.u_core.sinkC.u_core.taskFirePrev = u_g.inner_l2cache.slices_1.sinkC.REG_1_0;
    force u_i.inner_l2cache.slices_1.u_core.sinkC.u_core.taskBufIdxPrev = u_g.inner_l2cache.slices_1.sinkC.REG_2;
    force u_i.inner_l2cache.slices_1.u_core.reqArb.u_core.ds_mcp2_stall = u_g.inner_l2cache.slices_1.reqArb.ds_mcp2_stall;
    force u_i.inner_l2cache.slices_1.u_core.refillBuf.u_core.buffer[0][0] = u_g.inner_l2cache.slices_1.refillBuf.buffer_0_0;
    force u_i.inner_l2cache.slices_1.u_core.refillBuf.u_core.buffer[0][1] = u_g.inner_l2cache.slices_1.refillBuf.buffer_0_1;
    force u_i.inner_l2cache.slices_1.u_core.refillBuf.u_core.buffer[1][0] = u_g.inner_l2cache.slices_1.refillBuf.buffer_1_0;
    force u_i.inner_l2cache.slices_1.u_core.refillBuf.u_core.buffer[1][1] = u_g.inner_l2cache.slices_1.refillBuf.buffer_1_1;
    force u_i.inner_l2cache.slices_1.u_core.refillBuf.u_core.buffer[2][0] = u_g.inner_l2cache.slices_1.refillBuf.buffer_2_0;
    force u_i.inner_l2cache.slices_1.u_core.refillBuf.u_core.buffer[2][1] = u_g.inner_l2cache.slices_1.refillBuf.buffer_2_1;
    force u_i.inner_l2cache.slices_1.u_core.refillBuf.u_core.buffer[3][0] = u_g.inner_l2cache.slices_1.refillBuf.buffer_3_0;
    force u_i.inner_l2cache.slices_1.u_core.refillBuf.u_core.buffer[3][1] = u_g.inner_l2cache.slices_1.refillBuf.buffer_3_1;
    force u_i.inner_l2cache.slices_1.u_core.refillBuf.u_core.buffer[4][0] = u_g.inner_l2cache.slices_1.refillBuf.buffer_4_0;
    force u_i.inner_l2cache.slices_1.u_core.refillBuf.u_core.buffer[4][1] = u_g.inner_l2cache.slices_1.refillBuf.buffer_4_1;
    force u_i.inner_l2cache.slices_1.u_core.refillBuf.u_core.buffer[5][0] = u_g.inner_l2cache.slices_1.refillBuf.buffer_5_0;
    force u_i.inner_l2cache.slices_1.u_core.refillBuf.u_core.buffer[5][1] = u_g.inner_l2cache.slices_1.refillBuf.buffer_5_1;
    force u_i.inner_l2cache.slices_1.u_core.refillBuf.u_core.buffer[6][0] = u_g.inner_l2cache.slices_1.refillBuf.buffer_6_0;
    force u_i.inner_l2cache.slices_1.u_core.refillBuf.u_core.buffer[6][1] = u_g.inner_l2cache.slices_1.refillBuf.buffer_6_1;
    force u_i.inner_l2cache.slices_1.u_core.refillBuf.u_core.buffer[7][0] = u_g.inner_l2cache.slices_1.refillBuf.buffer_7_0;
    force u_i.inner_l2cache.slices_1.u_core.refillBuf.u_core.buffer[7][1] = u_g.inner_l2cache.slices_1.refillBuf.buffer_7_1;
    force u_i.inner_l2cache.slices_1.u_core.refillBuf.u_core.buffer[8][0] = u_g.inner_l2cache.slices_1.refillBuf.buffer_8_0;
    force u_i.inner_l2cache.slices_1.u_core.refillBuf.u_core.buffer[8][1] = u_g.inner_l2cache.slices_1.refillBuf.buffer_8_1;
    force u_i.inner_l2cache.slices_1.u_core.refillBuf.u_core.buffer[9][0] = u_g.inner_l2cache.slices_1.refillBuf.buffer_9_0;
    force u_i.inner_l2cache.slices_1.u_core.refillBuf.u_core.buffer[9][1] = u_g.inner_l2cache.slices_1.refillBuf.buffer_9_1;
    force u_i.inner_l2cache.slices_1.u_core.refillBuf.u_core.buffer[10][0] = u_g.inner_l2cache.slices_1.refillBuf.buffer_10_0;
    force u_i.inner_l2cache.slices_1.u_core.refillBuf.u_core.buffer[10][1] = u_g.inner_l2cache.slices_1.refillBuf.buffer_10_1;
    force u_i.inner_l2cache.slices_1.u_core.refillBuf.u_core.buffer[11][0] = u_g.inner_l2cache.slices_1.refillBuf.buffer_11_0;
    force u_i.inner_l2cache.slices_1.u_core.refillBuf.u_core.buffer[11][1] = u_g.inner_l2cache.slices_1.refillBuf.buffer_11_1;
    force u_i.inner_l2cache.slices_1.u_core.refillBuf.u_core.buffer[12][0] = u_g.inner_l2cache.slices_1.refillBuf.buffer_12_0;
    force u_i.inner_l2cache.slices_1.u_core.refillBuf.u_core.buffer[12][1] = u_g.inner_l2cache.slices_1.refillBuf.buffer_12_1;
    force u_i.inner_l2cache.slices_1.u_core.refillBuf.u_core.buffer[13][0] = u_g.inner_l2cache.slices_1.refillBuf.buffer_13_0;
    force u_i.inner_l2cache.slices_1.u_core.refillBuf.u_core.buffer[13][1] = u_g.inner_l2cache.slices_1.refillBuf.buffer_13_1;
    force u_i.inner_l2cache.slices_1.u_core.refillBuf.u_core.buffer[14][0] = u_g.inner_l2cache.slices_1.refillBuf.buffer_14_0;
    force u_i.inner_l2cache.slices_1.u_core.refillBuf.u_core.buffer[14][1] = u_g.inner_l2cache.slices_1.refillBuf.buffer_14_1;
    force u_i.inner_l2cache.slices_1.u_core.refillBuf.u_core.buffer[15][0] = u_g.inner_l2cache.slices_1.refillBuf.buffer_15_0;
    force u_i.inner_l2cache.slices_1.u_core.refillBuf.u_core.buffer[15][1] = u_g.inner_l2cache.slices_1.refillBuf.buffer_15_1;
    force u_i.inner_l2cache.slices_1.u_core.releaseBuf.u_core.buffer[0][0] = u_g.inner_l2cache.slices_1.releaseBuf.buffer_0_0;
    force u_i.inner_l2cache.slices_1.u_core.releaseBuf.u_core.buffer[0][1] = u_g.inner_l2cache.slices_1.releaseBuf.buffer_0_1;
    force u_i.inner_l2cache.slices_1.u_core.releaseBuf.u_core.buffer[1][0] = u_g.inner_l2cache.slices_1.releaseBuf.buffer_1_0;
    force u_i.inner_l2cache.slices_1.u_core.releaseBuf.u_core.buffer[1][1] = u_g.inner_l2cache.slices_1.releaseBuf.buffer_1_1;
    force u_i.inner_l2cache.slices_1.u_core.releaseBuf.u_core.buffer[2][0] = u_g.inner_l2cache.slices_1.releaseBuf.buffer_2_0;
    force u_i.inner_l2cache.slices_1.u_core.releaseBuf.u_core.buffer[2][1] = u_g.inner_l2cache.slices_1.releaseBuf.buffer_2_1;
    force u_i.inner_l2cache.slices_1.u_core.releaseBuf.u_core.buffer[3][0] = u_g.inner_l2cache.slices_1.releaseBuf.buffer_3_0;
    force u_i.inner_l2cache.slices_1.u_core.releaseBuf.u_core.buffer[3][1] = u_g.inner_l2cache.slices_1.releaseBuf.buffer_3_1;
    force u_i.inner_l2cache.slices_1.u_core.releaseBuf.u_core.buffer[4][0] = u_g.inner_l2cache.slices_1.releaseBuf.buffer_4_0;
    force u_i.inner_l2cache.slices_1.u_core.releaseBuf.u_core.buffer[4][1] = u_g.inner_l2cache.slices_1.releaseBuf.buffer_4_1;
    force u_i.inner_l2cache.slices_1.u_core.releaseBuf.u_core.buffer[5][0] = u_g.inner_l2cache.slices_1.releaseBuf.buffer_5_0;
    force u_i.inner_l2cache.slices_1.u_core.releaseBuf.u_core.buffer[5][1] = u_g.inner_l2cache.slices_1.releaseBuf.buffer_5_1;
    force u_i.inner_l2cache.slices_1.u_core.releaseBuf.u_core.buffer[6][0] = u_g.inner_l2cache.slices_1.releaseBuf.buffer_6_0;
    force u_i.inner_l2cache.slices_1.u_core.releaseBuf.u_core.buffer[6][1] = u_g.inner_l2cache.slices_1.releaseBuf.buffer_6_1;
    force u_i.inner_l2cache.slices_1.u_core.releaseBuf.u_core.buffer[7][0] = u_g.inner_l2cache.slices_1.releaseBuf.buffer_7_0;
    force u_i.inner_l2cache.slices_1.u_core.releaseBuf.u_core.buffer[7][1] = u_g.inner_l2cache.slices_1.releaseBuf.buffer_7_1;
    force u_i.inner_l2cache.slices_1.u_core.releaseBuf.u_core.buffer[8][0] = u_g.inner_l2cache.slices_1.releaseBuf.buffer_8_0;
    force u_i.inner_l2cache.slices_1.u_core.releaseBuf.u_core.buffer[8][1] = u_g.inner_l2cache.slices_1.releaseBuf.buffer_8_1;
    force u_i.inner_l2cache.slices_1.u_core.releaseBuf.u_core.buffer[9][0] = u_g.inner_l2cache.slices_1.releaseBuf.buffer_9_0;
    force u_i.inner_l2cache.slices_1.u_core.releaseBuf.u_core.buffer[9][1] = u_g.inner_l2cache.slices_1.releaseBuf.buffer_9_1;
    force u_i.inner_l2cache.slices_1.u_core.releaseBuf.u_core.buffer[10][0] = u_g.inner_l2cache.slices_1.releaseBuf.buffer_10_0;
    force u_i.inner_l2cache.slices_1.u_core.releaseBuf.u_core.buffer[10][1] = u_g.inner_l2cache.slices_1.releaseBuf.buffer_10_1;
    force u_i.inner_l2cache.slices_1.u_core.releaseBuf.u_core.buffer[11][0] = u_g.inner_l2cache.slices_1.releaseBuf.buffer_11_0;
    force u_i.inner_l2cache.slices_1.u_core.releaseBuf.u_core.buffer[11][1] = u_g.inner_l2cache.slices_1.releaseBuf.buffer_11_1;
    force u_i.inner_l2cache.slices_1.u_core.releaseBuf.u_core.buffer[12][0] = u_g.inner_l2cache.slices_1.releaseBuf.buffer_12_0;
    force u_i.inner_l2cache.slices_1.u_core.releaseBuf.u_core.buffer[12][1] = u_g.inner_l2cache.slices_1.releaseBuf.buffer_12_1;
    force u_i.inner_l2cache.slices_1.u_core.releaseBuf.u_core.buffer[13][0] = u_g.inner_l2cache.slices_1.releaseBuf.buffer_13_0;
    force u_i.inner_l2cache.slices_1.u_core.releaseBuf.u_core.buffer[13][1] = u_g.inner_l2cache.slices_1.releaseBuf.buffer_13_1;
    force u_i.inner_l2cache.slices_1.u_core.releaseBuf.u_core.buffer[14][0] = u_g.inner_l2cache.slices_1.releaseBuf.buffer_14_0;
    force u_i.inner_l2cache.slices_1.u_core.releaseBuf.u_core.buffer[14][1] = u_g.inner_l2cache.slices_1.releaseBuf.buffer_14_1;
    force u_i.inner_l2cache.slices_1.u_core.releaseBuf.u_core.buffer[15][0] = u_g.inner_l2cache.slices_1.releaseBuf.buffer_15_0;
    force u_i.inner_l2cache.slices_1.u_core.releaseBuf.u_core.buffer[15][1] = u_g.inner_l2cache.slices_1.releaseBuf.buffer_15_1;
    u_i.inner_l2cache.slices_1.u_core.txdat.queue.ram_ext.Memory = u_g.inner_l2cache.slices_1.txdat.queue.ram_ext.Memory;
    u_i.inner_l2cache.slices_1.u_core.txdat.queueData0.ram_data_ext.Memory = u_g.inner_l2cache.slices_1.txdat.queueData0.ram_data_ext.Memory;
    u_i.inner_l2cache.slices_1.u_core.txdat.queueData1.ram_data_ext.Memory = u_g.inner_l2cache.slices_1.txdat.queueData1.ram_data_ext.Memory;
    u_i.inner_l2cache.slices_1.directory.tagArray.array_0_0_0.array.array.array_14_ext.ram = u_g.inner_l2cache.slices_1.directory.tagArray.array_0_0_0.array.array.array_14_ext.ram;
    u_i.inner_l2cache.slices_1.directory.tagArray.array_0_0_0.array.array.array_14_ext.reg_RW0_addr = u_g.inner_l2cache.slices_1.directory.tagArray.array_0_0_0.array.array.array_14_ext.reg_RW0_addr;
    u_i.inner_l2cache.slices_1.directory.tagArray.array_0_0_0.array.array.array_14_ext.reg_RW0_ren = u_g.inner_l2cache.slices_1.directory.tagArray.array_0_0_0.array.array.array_14_ext.reg_RW0_ren;
    force u_i.inner_l2cache.slices_1.directory.tagArray.array_0_0_0.u_core.rdataReg = u_g.inner_l2cache.slices_1.directory.tagArray.array_0_0_0.rdataReg;
    u_i.inner_l2cache.slices_1.directory.tagArray.array_0_0_1.array.array.array_14_ext.ram = u_g.inner_l2cache.slices_1.directory.tagArray.array_0_0_1.array.array.array_14_ext.ram;
    u_i.inner_l2cache.slices_1.directory.tagArray.array_0_0_1.array.array.array_14_ext.reg_RW0_addr = u_g.inner_l2cache.slices_1.directory.tagArray.array_0_0_1.array.array.array_14_ext.reg_RW0_addr;
    u_i.inner_l2cache.slices_1.directory.tagArray.array_0_0_1.array.array.array_14_ext.reg_RW0_ren = u_g.inner_l2cache.slices_1.directory.tagArray.array_0_0_1.array.array.array_14_ext.reg_RW0_ren;
    force u_i.inner_l2cache.slices_1.directory.tagArray.array_0_0_1.u_core.rdataReg = u_g.inner_l2cache.slices_1.directory.tagArray.array_0_0_1.rdataReg;
    u_i.inner_l2cache.slices_1.directory.tagArray.array_0_1_0.array.array.array_14_ext.ram = u_g.inner_l2cache.slices_1.directory.tagArray.array_0_1_0.array.array.array_14_ext.ram;
    u_i.inner_l2cache.slices_1.directory.tagArray.array_0_1_0.array.array.array_14_ext.reg_RW0_addr = u_g.inner_l2cache.slices_1.directory.tagArray.array_0_1_0.array.array.array_14_ext.reg_RW0_addr;
    u_i.inner_l2cache.slices_1.directory.tagArray.array_0_1_0.array.array.array_14_ext.reg_RW0_ren = u_g.inner_l2cache.slices_1.directory.tagArray.array_0_1_0.array.array.array_14_ext.reg_RW0_ren;
    force u_i.inner_l2cache.slices_1.directory.tagArray.array_0_1_0.u_core.rdataReg = u_g.inner_l2cache.slices_1.directory.tagArray.array_0_1_0.rdataReg;
    u_i.inner_l2cache.slices_1.directory.tagArray.array_0_1_1.array.array.array_14_ext.ram = u_g.inner_l2cache.slices_1.directory.tagArray.array_0_1_1.array.array.array_14_ext.ram;
    u_i.inner_l2cache.slices_1.directory.tagArray.array_0_1_1.array.array.array_14_ext.reg_RW0_addr = u_g.inner_l2cache.slices_1.directory.tagArray.array_0_1_1.array.array.array_14_ext.reg_RW0_addr;
    u_i.inner_l2cache.slices_1.directory.tagArray.array_0_1_1.array.array.array_14_ext.reg_RW0_ren = u_g.inner_l2cache.slices_1.directory.tagArray.array_0_1_1.array.array.array_14_ext.reg_RW0_ren;
    force u_i.inner_l2cache.slices_1.directory.tagArray.array_0_1_1.u_core.rdataReg = u_g.inner_l2cache.slices_1.directory.tagArray.array_0_1_1.rdataReg;
    u_i.inner_l2cache.slices_1.directory.metaArray.array.array.array_15_ext.ram = u_g.inner_l2cache.slices_1.directory.metaArray.array.array.array_15_ext.ram;
    u_i.inner_l2cache.slices_1.directory.metaArray.array.array.array_15_ext.reg_RW0_addr = u_g.inner_l2cache.slices_1.directory.metaArray.array.array.array_15_ext.reg_RW0_addr;
    u_i.inner_l2cache.slices_1.directory.metaArray.array.array.array_15_ext.reg_RW0_ren = u_g.inner_l2cache.slices_1.directory.metaArray.array.array.array_15_ext.reg_RW0_ren;
    force u_i.inner_l2cache.slices_1.directory.metaArray.u_core.rdataReg = u_g.inner_l2cache.slices_1.directory.metaArray.rdataReg;
    u_i.inner_l2cache.slices_1.directory.replacer_sram_opt.array.array.array_16_ext.ram = u_g.inner_l2cache.slices_1.directory.replacer_sram_opt.array.array.array_16_ext.ram;
    u_i.inner_l2cache.slices_1.directory.replacer_sram_opt.array.array.array_16_ext.reg_RW0_addr = u_g.inner_l2cache.slices_1.directory.replacer_sram_opt.array.array.array_16_ext.reg_RW0_addr;
    u_i.inner_l2cache.slices_1.directory.replacer_sram_opt.array.array.array_16_ext.reg_RW0_ren = u_g.inner_l2cache.slices_1.directory.replacer_sram_opt.array.array.array_16_ext.reg_RW0_ren;
    force u_i.inner_l2cache.slices_1.directory.replacer_sram_opt.u_core.rdataReg = u_g.inner_l2cache.slices_1.directory.replacer_sram_opt.rdataReg;
    u_i.inner_l2cache.slices_1.directory.origin_bit_opt.array.array.array_17_ext.ram = u_g.inner_l2cache.slices_1.directory.origin_bit_opt.array.array.array_17_ext.ram;
    u_i.inner_l2cache.slices_1.directory.origin_bit_opt.array.array.array_17_ext.reg_RW0_addr = u_g.inner_l2cache.slices_1.directory.origin_bit_opt.array.array.array_17_ext.reg_RW0_addr;
    u_i.inner_l2cache.slices_1.directory.origin_bit_opt.array.array.array_17_ext.reg_RW0_ren = u_g.inner_l2cache.slices_1.directory.origin_bit_opt.array.array.array_17_ext.reg_RW0_ren;
    force u_i.inner_l2cache.slices_1.directory.origin_bit_opt.u_core.rdataReg = u_g.inner_l2cache.slices_1.directory.origin_bit_opt.rdataReg;
    u_i.inner_l2cache.slices_1.dataStorage.array.array_0_0_0.array.array.array_18_ext.ram = u_g.inner_l2cache.slices_1.dataStorage.array.array_0_0_0.array.array.array_18_ext.ram;
    u_i.inner_l2cache.slices_1.dataStorage.array.array_0_0_0.array.array.array_18_ext.reg_RW0_addr = u_g.inner_l2cache.slices_1.dataStorage.array.array_0_0_0.array.array.array_18_ext.reg_RW0_addr;
    u_i.inner_l2cache.slices_1.dataStorage.array.array_0_0_0.array.array.array_18_ext.reg_RW0_ren = u_g.inner_l2cache.slices_1.dataStorage.array.array_0_0_0.array.array.array_18_ext.reg_RW0_ren;
    force u_i.inner_l2cache.slices_1.dataStorage.array.array_0_0_0.u_core.rdataReg = u_g.inner_l2cache.slices_1.dataStorage.array.array_0_0_0.rdataReg;
    u_i.inner_l2cache.slices_1.dataStorage.array.array_0_0_1.array.array.array_18_ext.ram = u_g.inner_l2cache.slices_1.dataStorage.array.array_0_0_1.array.array.array_18_ext.ram;
    u_i.inner_l2cache.slices_1.dataStorage.array.array_0_0_1.array.array.array_18_ext.reg_RW0_addr = u_g.inner_l2cache.slices_1.dataStorage.array.array_0_0_1.array.array.array_18_ext.reg_RW0_addr;
    u_i.inner_l2cache.slices_1.dataStorage.array.array_0_0_1.array.array.array_18_ext.reg_RW0_ren = u_g.inner_l2cache.slices_1.dataStorage.array.array_0_0_1.array.array.array_18_ext.reg_RW0_ren;
    force u_i.inner_l2cache.slices_1.dataStorage.array.array_0_0_1.u_core.rdataReg = u_g.inner_l2cache.slices_1.dataStorage.array.array_0_0_1.rdataReg;
    u_i.inner_l2cache.slices_1.dataStorage.array.array_0_0_2.array.array.array_18_ext.ram = u_g.inner_l2cache.slices_1.dataStorage.array.array_0_0_2.array.array.array_18_ext.ram;
    u_i.inner_l2cache.slices_1.dataStorage.array.array_0_0_2.array.array.array_18_ext.reg_RW0_addr = u_g.inner_l2cache.slices_1.dataStorage.array.array_0_0_2.array.array.array_18_ext.reg_RW0_addr;
    u_i.inner_l2cache.slices_1.dataStorage.array.array_0_0_2.array.array.array_18_ext.reg_RW0_ren = u_g.inner_l2cache.slices_1.dataStorage.array.array_0_0_2.array.array.array_18_ext.reg_RW0_ren;
    force u_i.inner_l2cache.slices_1.dataStorage.array.array_0_0_2.u_core.rdataReg = u_g.inner_l2cache.slices_1.dataStorage.array.array_0_0_2.rdataReg;
    u_i.inner_l2cache.slices_1.dataStorage.array.array_0_0_3.array.array.array_18_ext.ram = u_g.inner_l2cache.slices_1.dataStorage.array.array_0_0_3.array.array.array_18_ext.ram;
    u_i.inner_l2cache.slices_1.dataStorage.array.array_0_0_3.array.array.array_18_ext.reg_RW0_addr = u_g.inner_l2cache.slices_1.dataStorage.array.array_0_0_3.array.array.array_18_ext.reg_RW0_addr;
    u_i.inner_l2cache.slices_1.dataStorage.array.array_0_0_3.array.array.array_18_ext.reg_RW0_ren = u_g.inner_l2cache.slices_1.dataStorage.array.array_0_0_3.array.array.array_18_ext.reg_RW0_ren;
    force u_i.inner_l2cache.slices_1.dataStorage.array.array_0_0_3.u_core.rdataReg = u_g.inner_l2cache.slices_1.dataStorage.array.array_0_0_3.rdataReg;
    force u_i.inner_l2cache.slices_1.dataStorage.u_core.error_REG = u_g.inner_l2cache.slices_1.dataStorage.error_REG;
    force u_i.inner_l2cache.slices_1.dataStorage.u_core.error_REG_1 = u_g.inner_l2cache.slices_1.dataStorage.error_REG_1;
    force u_i.inner_l2cache.slices_1.mbistPl.u_core.g_node_return.pipelineDataOutReg = u_g.inner_l2cache.slices_1.mbistPl.pipelineDataOutReg;
    u_i.inner_l2cache.slices_1.u_core.txreq.u_core.queue.ram_ext.Memory = u_g.inner_l2cache.slices_1.txreq.queue.ram_ext.Memory;
    u_i.inner_l2cache.slices_1.u_core.txrsp.u_core.queue.ram_ext.Memory = u_g.inner_l2cache.slices_1.txrsp.queue.ram_ext.Memory;
    force u_i.inner_l2cache.slices_1.u_core.io_error_bits_REG_valid = u_g.inner_l2cache.slices_1.io_error_bits_REG_valid;
    force u_i.inner_l2cache.slices_1.u_core.io_error_bits_REG_address = u_g.inner_l2cache.slices_1.io_error_bits_REG_address;
    force u_i.inner_l2cache.slices_1.u_core.io_perf_0_value_REG = u_g.inner_l2cache.slices_1.io_perf_0_value_REG;
    force u_i.inner_l2cache.slices_1.u_core.io_perf_0_value_REG_1 = u_g.inner_l2cache.slices_1.io_perf_0_value_REG_1;
    force u_i.inner_l2cache.slices_1.u_core.io_perf_1_value_REG = u_g.inner_l2cache.slices_1.io_perf_1_value_REG;
    force u_i.inner_l2cache.slices_1.u_core.io_perf_1_value_REG_1 = u_g.inner_l2cache.slices_1.io_perf_1_value_REG_1;
    force u_i.inner_l2cache.slices_1.u_core.io_perf_3_value_REG = u_g.inner_l2cache.slices_1.io_perf_3_value_REG;
    force u_i.inner_l2cache.slices_1.u_core.io_perf_3_value_REG_1 = u_g.inner_l2cache.slices_1.io_perf_3_value_REG_1;
    force u_i.inner_l2cache.slices_1.u_core.io_perf_4_value_REG = u_g.inner_l2cache.slices_1.io_perf_4_value_REG;
    force u_i.inner_l2cache.slices_1.u_core.io_perf_4_value_REG_1 = u_g.inner_l2cache.slices_1.io_perf_4_value_REG_1;
    force u_i.inner_l2cache.slices_1.u_core.io_perf_5_value_REG = u_g.inner_l2cache.slices_1.io_perf_5_value_REG;
    force u_i.inner_l2cache.slices_1.u_core.io_perf_5_value_REG_1 = u_g.inner_l2cache.slices_1.io_perf_5_value_REG_1;
    force u_i.inner_l2cache.slices_1.u_core.io_perf_6_value_REG = u_g.inner_l2cache.slices_1.io_perf_6_value_REG;
    force u_i.inner_l2cache.slices_1.u_core.io_perf_6_value_REG_1 = u_g.inner_l2cache.slices_1.io_perf_6_value_REG_1;
    force u_i.inner_l2cache.slices_1.u_core.io_perf_7_value_REG = u_g.inner_l2cache.slices_1.io_perf_7_value_REG;
    force u_i.inner_l2cache.slices_1.u_core.io_perf_7_value_REG_1 = u_g.inner_l2cache.slices_1.io_perf_7_value_REG_1;
    force u_i.inner_l2cache.slices_1.u_core.io_perf_8_value_REG = u_g.inner_l2cache.slices_1.io_perf_8_value_REG;
    force u_i.inner_l2cache.slices_1.u_core.io_perf_8_value_REG_1 = u_g.inner_l2cache.slices_1.io_perf_8_value_REG_1;
    force u_i.inner_l2cache.slices_1.u_core.io_perf_9_value_REG = u_g.inner_l2cache.slices_1.io_perf_9_value_REG;
    force u_i.inner_l2cache.slices_1.u_core.io_perf_9_value_REG_1 = u_g.inner_l2cache.slices_1.io_perf_9_value_REG_1;
    force u_i.inner_l2cache.slices_1.u_core.io_perf_10_value_REG = u_g.inner_l2cache.slices_1.io_perf_10_value_REG;
    force u_i.inner_l2cache.slices_1.u_core.io_perf_10_value_REG_1 = u_g.inner_l2cache.slices_1.io_perf_10_value_REG_1;
    force u_i.inner_l2cache.slices_1.u_core.io_perf_11_value_REG = u_g.inner_l2cache.slices_1.io_perf_11_value_REG;
    force u_i.inner_l2cache.slices_1.u_core.io_perf_11_value_REG_1 = u_g.inner_l2cache.slices_1.io_perf_11_value_REG_1;
    force u_i.inner_l2cache.slices_1.u_core.io_perf_12_value_REG = u_g.inner_l2cache.slices_1.io_perf_12_value_REG;
    force u_i.inner_l2cache.slices_1.u_core.io_perf_12_value_REG_1 = u_g.inner_l2cache.slices_1.io_perf_12_value_REG_1;
    force u_i.inner_l2cache.slices_1.u_core.io_perf_13_value_REG = u_g.inner_l2cache.slices_1.io_perf_13_value_REG;
    force u_i.inner_l2cache.slices_1.u_core.io_perf_13_value_REG_1 = u_g.inner_l2cache.slices_1.io_perf_13_value_REG_1;
    force u_i.inner_l2cache.slices_1.u_core.io_perf_14_value_REG = u_g.inner_l2cache.slices_1.io_perf_14_value_REG;
    force u_i.inner_l2cache.slices_1.u_core.io_perf_14_value_REG_1 = u_g.inner_l2cache.slices_1.io_perf_14_value_REG_1;
    force u_i.inner_l2cache.slices_1.u_core.io_perf_15_value_REG = u_g.inner_l2cache.slices_1.io_perf_15_value_REG;
    force u_i.inner_l2cache.slices_1.u_core.io_perf_15_value_REG_1 = u_g.inner_l2cache.slices_1.io_perf_15_value_REG_1;
    force u_i.inner_l2cache.slices_1.u_core.io_perf_16_value_REG = u_g.inner_l2cache.slices_1.io_perf_16_value_REG;
    force u_i.inner_l2cache.slices_1.u_core.io_perf_16_value_REG_1 = u_g.inner_l2cache.slices_1.io_perf_16_value_REG_1;
    force u_i.inner_l2cache.slices_2.u_core.mshrCtl.u_core.mshrs[0].entry.u_core.tgtid_rcompack = u_g.inner_l2cache.slices_2.mshrCtl.mshrs_0.tgtid_rcompack;
    force u_i.inner_l2cache.slices_2.u_core.mshrCtl.u_core.mshrs[0].entry.u_core.txnid_rcompack = u_g.inner_l2cache.slices_2.mshrCtl.mshrs_0.txnid_rcompack;
    force u_i.inner_l2cache.slices_2.u_core.mshrCtl.u_core.mshrs[0].entry.u_core.tgtid_wcompack = u_g.inner_l2cache.slices_2.mshrCtl.mshrs_0.tgtid_wcompack;
    force u_i.inner_l2cache.slices_2.u_core.mshrCtl.u_core.mshrs[0].entry.u_core.txnid_wcompack = u_g.inner_l2cache.slices_2.mshrCtl.mshrs_0.txnid_wcompack;
    force u_i.inner_l2cache.slices_2.u_core.mshrCtl.u_core.mshrs[0].entry.u_core.srcid_retryack = u_g.inner_l2cache.slices_2.mshrCtl.mshrs_0.srcid_retryack;
    force u_i.inner_l2cache.slices_2.u_core.mshrCtl.u_core.mshrs[0].entry.u_core.acquire_ts = u_g.inner_l2cache.slices_2.mshrCtl.mshrs_0.acquire_ts;
    force u_i.inner_l2cache.slices_2.u_core.mshrCtl.u_core.mshrs[0].entry.u_core.release_ts = u_g.inner_l2cache.slices_2.mshrCtl.mshrs_0.release_ts;
    force u_i.inner_l2cache.slices_2.u_core.mshrCtl.u_core.mshrs[0].entry.u_core.acquire_period_valid_REG = u_g.inner_l2cache.slices_2.mshrCtl.mshrs_0.acquire_period_valid_REG;
    force u_i.inner_l2cache.slices_2.u_core.mshrCtl.u_core.mshrs[0].entry.u_core.release_period_valid_REG = u_g.inner_l2cache.slices_2.mshrCtl.mshrs_0.release_period_valid_REG;
    force u_i.inner_l2cache.slices_2.u_core.mshrCtl.u_core.mshrs[0].entry.u_core.REG = u_g.inner_l2cache.slices_2.mshrCtl.mshrs_0.REG;
    force u_i.inner_l2cache.slices_2.u_core.mshrCtl.u_core.mshrs[0].entry.u_core.REG_1 = u_g.inner_l2cache.slices_2.mshrCtl.mshrs_0.REG_1;
    force u_i.inner_l2cache.slices_2.u_core.mshrCtl.u_core.mshrs[0].entry.u_core.REG_2 = u_g.inner_l2cache.slices_2.mshrCtl.mshrs_0.REG_2;
    force u_i.inner_l2cache.slices_2.u_core.mshrCtl.u_core.mshrs[0].entry.u_core.REG_3 = u_g.inner_l2cache.slices_2.mshrCtl.mshrs_0.REG_3;
    force u_i.inner_l2cache.slices_2.u_core.mshrCtl.u_core.mshrs[1].entry.u_core.tgtid_rcompack = u_g.inner_l2cache.slices_2.mshrCtl.mshrs_1.tgtid_rcompack;
    force u_i.inner_l2cache.slices_2.u_core.mshrCtl.u_core.mshrs[1].entry.u_core.txnid_rcompack = u_g.inner_l2cache.slices_2.mshrCtl.mshrs_1.txnid_rcompack;
    force u_i.inner_l2cache.slices_2.u_core.mshrCtl.u_core.mshrs[1].entry.u_core.tgtid_wcompack = u_g.inner_l2cache.slices_2.mshrCtl.mshrs_1.tgtid_wcompack;
    force u_i.inner_l2cache.slices_2.u_core.mshrCtl.u_core.mshrs[1].entry.u_core.txnid_wcompack = u_g.inner_l2cache.slices_2.mshrCtl.mshrs_1.txnid_wcompack;
    force u_i.inner_l2cache.slices_2.u_core.mshrCtl.u_core.mshrs[1].entry.u_core.srcid_retryack = u_g.inner_l2cache.slices_2.mshrCtl.mshrs_1.srcid_retryack;
    force u_i.inner_l2cache.slices_2.u_core.mshrCtl.u_core.mshrs[1].entry.u_core.acquire_ts = u_g.inner_l2cache.slices_2.mshrCtl.mshrs_1.acquire_ts;
    force u_i.inner_l2cache.slices_2.u_core.mshrCtl.u_core.mshrs[1].entry.u_core.release_ts = u_g.inner_l2cache.slices_2.mshrCtl.mshrs_1.release_ts;
    force u_i.inner_l2cache.slices_2.u_core.mshrCtl.u_core.mshrs[1].entry.u_core.acquire_period_valid_REG = u_g.inner_l2cache.slices_2.mshrCtl.mshrs_1.acquire_period_valid_REG;
    force u_i.inner_l2cache.slices_2.u_core.mshrCtl.u_core.mshrs[1].entry.u_core.release_period_valid_REG = u_g.inner_l2cache.slices_2.mshrCtl.mshrs_1.release_period_valid_REG;
    force u_i.inner_l2cache.slices_2.u_core.mshrCtl.u_core.mshrs[1].entry.u_core.REG = u_g.inner_l2cache.slices_2.mshrCtl.mshrs_1.REG;
    force u_i.inner_l2cache.slices_2.u_core.mshrCtl.u_core.mshrs[1].entry.u_core.REG_1 = u_g.inner_l2cache.slices_2.mshrCtl.mshrs_1.REG_1;
    force u_i.inner_l2cache.slices_2.u_core.mshrCtl.u_core.mshrs[1].entry.u_core.REG_2 = u_g.inner_l2cache.slices_2.mshrCtl.mshrs_1.REG_2;
    force u_i.inner_l2cache.slices_2.u_core.mshrCtl.u_core.mshrs[1].entry.u_core.REG_3 = u_g.inner_l2cache.slices_2.mshrCtl.mshrs_1.REG_3;
    force u_i.inner_l2cache.slices_2.u_core.mshrCtl.u_core.mshrs[2].entry.u_core.tgtid_rcompack = u_g.inner_l2cache.slices_2.mshrCtl.mshrs_2.tgtid_rcompack;
    force u_i.inner_l2cache.slices_2.u_core.mshrCtl.u_core.mshrs[2].entry.u_core.txnid_rcompack = u_g.inner_l2cache.slices_2.mshrCtl.mshrs_2.txnid_rcompack;
    force u_i.inner_l2cache.slices_2.u_core.mshrCtl.u_core.mshrs[2].entry.u_core.tgtid_wcompack = u_g.inner_l2cache.slices_2.mshrCtl.mshrs_2.tgtid_wcompack;
    force u_i.inner_l2cache.slices_2.u_core.mshrCtl.u_core.mshrs[2].entry.u_core.txnid_wcompack = u_g.inner_l2cache.slices_2.mshrCtl.mshrs_2.txnid_wcompack;
    force u_i.inner_l2cache.slices_2.u_core.mshrCtl.u_core.mshrs[2].entry.u_core.srcid_retryack = u_g.inner_l2cache.slices_2.mshrCtl.mshrs_2.srcid_retryack;
    force u_i.inner_l2cache.slices_2.u_core.mshrCtl.u_core.mshrs[2].entry.u_core.acquire_ts = u_g.inner_l2cache.slices_2.mshrCtl.mshrs_2.acquire_ts;
    force u_i.inner_l2cache.slices_2.u_core.mshrCtl.u_core.mshrs[2].entry.u_core.release_ts = u_g.inner_l2cache.slices_2.mshrCtl.mshrs_2.release_ts;
    force u_i.inner_l2cache.slices_2.u_core.mshrCtl.u_core.mshrs[2].entry.u_core.acquire_period_valid_REG = u_g.inner_l2cache.slices_2.mshrCtl.mshrs_2.acquire_period_valid_REG;
    force u_i.inner_l2cache.slices_2.u_core.mshrCtl.u_core.mshrs[2].entry.u_core.release_period_valid_REG = u_g.inner_l2cache.slices_2.mshrCtl.mshrs_2.release_period_valid_REG;
    force u_i.inner_l2cache.slices_2.u_core.mshrCtl.u_core.mshrs[2].entry.u_core.REG = u_g.inner_l2cache.slices_2.mshrCtl.mshrs_2.REG;
    force u_i.inner_l2cache.slices_2.u_core.mshrCtl.u_core.mshrs[2].entry.u_core.REG_1 = u_g.inner_l2cache.slices_2.mshrCtl.mshrs_2.REG_1;
    force u_i.inner_l2cache.slices_2.u_core.mshrCtl.u_core.mshrs[2].entry.u_core.REG_2 = u_g.inner_l2cache.slices_2.mshrCtl.mshrs_2.REG_2;
    force u_i.inner_l2cache.slices_2.u_core.mshrCtl.u_core.mshrs[2].entry.u_core.REG_3 = u_g.inner_l2cache.slices_2.mshrCtl.mshrs_2.REG_3;
    force u_i.inner_l2cache.slices_2.u_core.mshrCtl.u_core.mshrs[3].entry.u_core.tgtid_rcompack = u_g.inner_l2cache.slices_2.mshrCtl.mshrs_3.tgtid_rcompack;
    force u_i.inner_l2cache.slices_2.u_core.mshrCtl.u_core.mshrs[3].entry.u_core.txnid_rcompack = u_g.inner_l2cache.slices_2.mshrCtl.mshrs_3.txnid_rcompack;
    force u_i.inner_l2cache.slices_2.u_core.mshrCtl.u_core.mshrs[3].entry.u_core.tgtid_wcompack = u_g.inner_l2cache.slices_2.mshrCtl.mshrs_3.tgtid_wcompack;
    force u_i.inner_l2cache.slices_2.u_core.mshrCtl.u_core.mshrs[3].entry.u_core.txnid_wcompack = u_g.inner_l2cache.slices_2.mshrCtl.mshrs_3.txnid_wcompack;
    force u_i.inner_l2cache.slices_2.u_core.mshrCtl.u_core.mshrs[3].entry.u_core.srcid_retryack = u_g.inner_l2cache.slices_2.mshrCtl.mshrs_3.srcid_retryack;
    force u_i.inner_l2cache.slices_2.u_core.mshrCtl.u_core.mshrs[3].entry.u_core.acquire_ts = u_g.inner_l2cache.slices_2.mshrCtl.mshrs_3.acquire_ts;
    force u_i.inner_l2cache.slices_2.u_core.mshrCtl.u_core.mshrs[3].entry.u_core.release_ts = u_g.inner_l2cache.slices_2.mshrCtl.mshrs_3.release_ts;
    force u_i.inner_l2cache.slices_2.u_core.mshrCtl.u_core.mshrs[3].entry.u_core.acquire_period_valid_REG = u_g.inner_l2cache.slices_2.mshrCtl.mshrs_3.acquire_period_valid_REG;
    force u_i.inner_l2cache.slices_2.u_core.mshrCtl.u_core.mshrs[3].entry.u_core.release_period_valid_REG = u_g.inner_l2cache.slices_2.mshrCtl.mshrs_3.release_period_valid_REG;
    force u_i.inner_l2cache.slices_2.u_core.mshrCtl.u_core.mshrs[3].entry.u_core.REG = u_g.inner_l2cache.slices_2.mshrCtl.mshrs_3.REG;
    force u_i.inner_l2cache.slices_2.u_core.mshrCtl.u_core.mshrs[3].entry.u_core.REG_1 = u_g.inner_l2cache.slices_2.mshrCtl.mshrs_3.REG_1;
    force u_i.inner_l2cache.slices_2.u_core.mshrCtl.u_core.mshrs[3].entry.u_core.REG_2 = u_g.inner_l2cache.slices_2.mshrCtl.mshrs_3.REG_2;
    force u_i.inner_l2cache.slices_2.u_core.mshrCtl.u_core.mshrs[3].entry.u_core.REG_3 = u_g.inner_l2cache.slices_2.mshrCtl.mshrs_3.REG_3;
    force u_i.inner_l2cache.slices_2.u_core.mshrCtl.u_core.mshrs[4].entry.u_core.tgtid_rcompack = u_g.inner_l2cache.slices_2.mshrCtl.mshrs_4.tgtid_rcompack;
    force u_i.inner_l2cache.slices_2.u_core.mshrCtl.u_core.mshrs[4].entry.u_core.txnid_rcompack = u_g.inner_l2cache.slices_2.mshrCtl.mshrs_4.txnid_rcompack;
    force u_i.inner_l2cache.slices_2.u_core.mshrCtl.u_core.mshrs[4].entry.u_core.tgtid_wcompack = u_g.inner_l2cache.slices_2.mshrCtl.mshrs_4.tgtid_wcompack;
    force u_i.inner_l2cache.slices_2.u_core.mshrCtl.u_core.mshrs[4].entry.u_core.txnid_wcompack = u_g.inner_l2cache.slices_2.mshrCtl.mshrs_4.txnid_wcompack;
    force u_i.inner_l2cache.slices_2.u_core.mshrCtl.u_core.mshrs[4].entry.u_core.srcid_retryack = u_g.inner_l2cache.slices_2.mshrCtl.mshrs_4.srcid_retryack;
    force u_i.inner_l2cache.slices_2.u_core.mshrCtl.u_core.mshrs[4].entry.u_core.acquire_ts = u_g.inner_l2cache.slices_2.mshrCtl.mshrs_4.acquire_ts;
    force u_i.inner_l2cache.slices_2.u_core.mshrCtl.u_core.mshrs[4].entry.u_core.release_ts = u_g.inner_l2cache.slices_2.mshrCtl.mshrs_4.release_ts;
    force u_i.inner_l2cache.slices_2.u_core.mshrCtl.u_core.mshrs[4].entry.u_core.acquire_period_valid_REG = u_g.inner_l2cache.slices_2.mshrCtl.mshrs_4.acquire_period_valid_REG;
    force u_i.inner_l2cache.slices_2.u_core.mshrCtl.u_core.mshrs[4].entry.u_core.release_period_valid_REG = u_g.inner_l2cache.slices_2.mshrCtl.mshrs_4.release_period_valid_REG;
    force u_i.inner_l2cache.slices_2.u_core.mshrCtl.u_core.mshrs[4].entry.u_core.REG = u_g.inner_l2cache.slices_2.mshrCtl.mshrs_4.REG;
    force u_i.inner_l2cache.slices_2.u_core.mshrCtl.u_core.mshrs[4].entry.u_core.REG_1 = u_g.inner_l2cache.slices_2.mshrCtl.mshrs_4.REG_1;
    force u_i.inner_l2cache.slices_2.u_core.mshrCtl.u_core.mshrs[4].entry.u_core.REG_2 = u_g.inner_l2cache.slices_2.mshrCtl.mshrs_4.REG_2;
    force u_i.inner_l2cache.slices_2.u_core.mshrCtl.u_core.mshrs[4].entry.u_core.REG_3 = u_g.inner_l2cache.slices_2.mshrCtl.mshrs_4.REG_3;
    force u_i.inner_l2cache.slices_2.u_core.mshrCtl.u_core.mshrs[5].entry.u_core.tgtid_rcompack = u_g.inner_l2cache.slices_2.mshrCtl.mshrs_5.tgtid_rcompack;
    force u_i.inner_l2cache.slices_2.u_core.mshrCtl.u_core.mshrs[5].entry.u_core.txnid_rcompack = u_g.inner_l2cache.slices_2.mshrCtl.mshrs_5.txnid_rcompack;
    force u_i.inner_l2cache.slices_2.u_core.mshrCtl.u_core.mshrs[5].entry.u_core.tgtid_wcompack = u_g.inner_l2cache.slices_2.mshrCtl.mshrs_5.tgtid_wcompack;
    force u_i.inner_l2cache.slices_2.u_core.mshrCtl.u_core.mshrs[5].entry.u_core.txnid_wcompack = u_g.inner_l2cache.slices_2.mshrCtl.mshrs_5.txnid_wcompack;
    force u_i.inner_l2cache.slices_2.u_core.mshrCtl.u_core.mshrs[5].entry.u_core.srcid_retryack = u_g.inner_l2cache.slices_2.mshrCtl.mshrs_5.srcid_retryack;
    force u_i.inner_l2cache.slices_2.u_core.mshrCtl.u_core.mshrs[5].entry.u_core.acquire_ts = u_g.inner_l2cache.slices_2.mshrCtl.mshrs_5.acquire_ts;
    force u_i.inner_l2cache.slices_2.u_core.mshrCtl.u_core.mshrs[5].entry.u_core.release_ts = u_g.inner_l2cache.slices_2.mshrCtl.mshrs_5.release_ts;
    force u_i.inner_l2cache.slices_2.u_core.mshrCtl.u_core.mshrs[5].entry.u_core.acquire_period_valid_REG = u_g.inner_l2cache.slices_2.mshrCtl.mshrs_5.acquire_period_valid_REG;
    force u_i.inner_l2cache.slices_2.u_core.mshrCtl.u_core.mshrs[5].entry.u_core.release_period_valid_REG = u_g.inner_l2cache.slices_2.mshrCtl.mshrs_5.release_period_valid_REG;
    force u_i.inner_l2cache.slices_2.u_core.mshrCtl.u_core.mshrs[5].entry.u_core.REG = u_g.inner_l2cache.slices_2.mshrCtl.mshrs_5.REG;
    force u_i.inner_l2cache.slices_2.u_core.mshrCtl.u_core.mshrs[5].entry.u_core.REG_1 = u_g.inner_l2cache.slices_2.mshrCtl.mshrs_5.REG_1;
    force u_i.inner_l2cache.slices_2.u_core.mshrCtl.u_core.mshrs[5].entry.u_core.REG_2 = u_g.inner_l2cache.slices_2.mshrCtl.mshrs_5.REG_2;
    force u_i.inner_l2cache.slices_2.u_core.mshrCtl.u_core.mshrs[5].entry.u_core.REG_3 = u_g.inner_l2cache.slices_2.mshrCtl.mshrs_5.REG_3;
    force u_i.inner_l2cache.slices_2.u_core.mshrCtl.u_core.mshrs[6].entry.u_core.tgtid_rcompack = u_g.inner_l2cache.slices_2.mshrCtl.mshrs_6.tgtid_rcompack;
    force u_i.inner_l2cache.slices_2.u_core.mshrCtl.u_core.mshrs[6].entry.u_core.txnid_rcompack = u_g.inner_l2cache.slices_2.mshrCtl.mshrs_6.txnid_rcompack;
    force u_i.inner_l2cache.slices_2.u_core.mshrCtl.u_core.mshrs[6].entry.u_core.tgtid_wcompack = u_g.inner_l2cache.slices_2.mshrCtl.mshrs_6.tgtid_wcompack;
    force u_i.inner_l2cache.slices_2.u_core.mshrCtl.u_core.mshrs[6].entry.u_core.txnid_wcompack = u_g.inner_l2cache.slices_2.mshrCtl.mshrs_6.txnid_wcompack;
    force u_i.inner_l2cache.slices_2.u_core.mshrCtl.u_core.mshrs[6].entry.u_core.srcid_retryack = u_g.inner_l2cache.slices_2.mshrCtl.mshrs_6.srcid_retryack;
    force u_i.inner_l2cache.slices_2.u_core.mshrCtl.u_core.mshrs[6].entry.u_core.acquire_ts = u_g.inner_l2cache.slices_2.mshrCtl.mshrs_6.acquire_ts;
    force u_i.inner_l2cache.slices_2.u_core.mshrCtl.u_core.mshrs[6].entry.u_core.release_ts = u_g.inner_l2cache.slices_2.mshrCtl.mshrs_6.release_ts;
    force u_i.inner_l2cache.slices_2.u_core.mshrCtl.u_core.mshrs[6].entry.u_core.acquire_period_valid_REG = u_g.inner_l2cache.slices_2.mshrCtl.mshrs_6.acquire_period_valid_REG;
    force u_i.inner_l2cache.slices_2.u_core.mshrCtl.u_core.mshrs[6].entry.u_core.release_period_valid_REG = u_g.inner_l2cache.slices_2.mshrCtl.mshrs_6.release_period_valid_REG;
    force u_i.inner_l2cache.slices_2.u_core.mshrCtl.u_core.mshrs[6].entry.u_core.REG = u_g.inner_l2cache.slices_2.mshrCtl.mshrs_6.REG;
    force u_i.inner_l2cache.slices_2.u_core.mshrCtl.u_core.mshrs[6].entry.u_core.REG_1 = u_g.inner_l2cache.slices_2.mshrCtl.mshrs_6.REG_1;
    force u_i.inner_l2cache.slices_2.u_core.mshrCtl.u_core.mshrs[6].entry.u_core.REG_2 = u_g.inner_l2cache.slices_2.mshrCtl.mshrs_6.REG_2;
    force u_i.inner_l2cache.slices_2.u_core.mshrCtl.u_core.mshrs[6].entry.u_core.REG_3 = u_g.inner_l2cache.slices_2.mshrCtl.mshrs_6.REG_3;
    force u_i.inner_l2cache.slices_2.u_core.mshrCtl.u_core.mshrs[7].entry.u_core.tgtid_rcompack = u_g.inner_l2cache.slices_2.mshrCtl.mshrs_7.tgtid_rcompack;
    force u_i.inner_l2cache.slices_2.u_core.mshrCtl.u_core.mshrs[7].entry.u_core.txnid_rcompack = u_g.inner_l2cache.slices_2.mshrCtl.mshrs_7.txnid_rcompack;
    force u_i.inner_l2cache.slices_2.u_core.mshrCtl.u_core.mshrs[7].entry.u_core.tgtid_wcompack = u_g.inner_l2cache.slices_2.mshrCtl.mshrs_7.tgtid_wcompack;
    force u_i.inner_l2cache.slices_2.u_core.mshrCtl.u_core.mshrs[7].entry.u_core.txnid_wcompack = u_g.inner_l2cache.slices_2.mshrCtl.mshrs_7.txnid_wcompack;
    force u_i.inner_l2cache.slices_2.u_core.mshrCtl.u_core.mshrs[7].entry.u_core.srcid_retryack = u_g.inner_l2cache.slices_2.mshrCtl.mshrs_7.srcid_retryack;
    force u_i.inner_l2cache.slices_2.u_core.mshrCtl.u_core.mshrs[7].entry.u_core.acquire_ts = u_g.inner_l2cache.slices_2.mshrCtl.mshrs_7.acquire_ts;
    force u_i.inner_l2cache.slices_2.u_core.mshrCtl.u_core.mshrs[7].entry.u_core.release_ts = u_g.inner_l2cache.slices_2.mshrCtl.mshrs_7.release_ts;
    force u_i.inner_l2cache.slices_2.u_core.mshrCtl.u_core.mshrs[7].entry.u_core.acquire_period_valid_REG = u_g.inner_l2cache.slices_2.mshrCtl.mshrs_7.acquire_period_valid_REG;
    force u_i.inner_l2cache.slices_2.u_core.mshrCtl.u_core.mshrs[7].entry.u_core.release_period_valid_REG = u_g.inner_l2cache.slices_2.mshrCtl.mshrs_7.release_period_valid_REG;
    force u_i.inner_l2cache.slices_2.u_core.mshrCtl.u_core.mshrs[7].entry.u_core.REG = u_g.inner_l2cache.slices_2.mshrCtl.mshrs_7.REG;
    force u_i.inner_l2cache.slices_2.u_core.mshrCtl.u_core.mshrs[7].entry.u_core.REG_1 = u_g.inner_l2cache.slices_2.mshrCtl.mshrs_7.REG_1;
    force u_i.inner_l2cache.slices_2.u_core.mshrCtl.u_core.mshrs[7].entry.u_core.REG_2 = u_g.inner_l2cache.slices_2.mshrCtl.mshrs_7.REG_2;
    force u_i.inner_l2cache.slices_2.u_core.mshrCtl.u_core.mshrs[7].entry.u_core.REG_3 = u_g.inner_l2cache.slices_2.mshrCtl.mshrs_7.REG_3;
    force u_i.inner_l2cache.slices_2.u_core.mshrCtl.u_core.mshrs[8].entry.u_core.tgtid_rcompack = u_g.inner_l2cache.slices_2.mshrCtl.mshrs_8.tgtid_rcompack;
    force u_i.inner_l2cache.slices_2.u_core.mshrCtl.u_core.mshrs[8].entry.u_core.txnid_rcompack = u_g.inner_l2cache.slices_2.mshrCtl.mshrs_8.txnid_rcompack;
    force u_i.inner_l2cache.slices_2.u_core.mshrCtl.u_core.mshrs[8].entry.u_core.tgtid_wcompack = u_g.inner_l2cache.slices_2.mshrCtl.mshrs_8.tgtid_wcompack;
    force u_i.inner_l2cache.slices_2.u_core.mshrCtl.u_core.mshrs[8].entry.u_core.txnid_wcompack = u_g.inner_l2cache.slices_2.mshrCtl.mshrs_8.txnid_wcompack;
    force u_i.inner_l2cache.slices_2.u_core.mshrCtl.u_core.mshrs[8].entry.u_core.srcid_retryack = u_g.inner_l2cache.slices_2.mshrCtl.mshrs_8.srcid_retryack;
    force u_i.inner_l2cache.slices_2.u_core.mshrCtl.u_core.mshrs[8].entry.u_core.acquire_ts = u_g.inner_l2cache.slices_2.mshrCtl.mshrs_8.acquire_ts;
    force u_i.inner_l2cache.slices_2.u_core.mshrCtl.u_core.mshrs[8].entry.u_core.release_ts = u_g.inner_l2cache.slices_2.mshrCtl.mshrs_8.release_ts;
    force u_i.inner_l2cache.slices_2.u_core.mshrCtl.u_core.mshrs[8].entry.u_core.acquire_period_valid_REG = u_g.inner_l2cache.slices_2.mshrCtl.mshrs_8.acquire_period_valid_REG;
    force u_i.inner_l2cache.slices_2.u_core.mshrCtl.u_core.mshrs[8].entry.u_core.release_period_valid_REG = u_g.inner_l2cache.slices_2.mshrCtl.mshrs_8.release_period_valid_REG;
    force u_i.inner_l2cache.slices_2.u_core.mshrCtl.u_core.mshrs[8].entry.u_core.REG = u_g.inner_l2cache.slices_2.mshrCtl.mshrs_8.REG;
    force u_i.inner_l2cache.slices_2.u_core.mshrCtl.u_core.mshrs[8].entry.u_core.REG_1 = u_g.inner_l2cache.slices_2.mshrCtl.mshrs_8.REG_1;
    force u_i.inner_l2cache.slices_2.u_core.mshrCtl.u_core.mshrs[8].entry.u_core.REG_2 = u_g.inner_l2cache.slices_2.mshrCtl.mshrs_8.REG_2;
    force u_i.inner_l2cache.slices_2.u_core.mshrCtl.u_core.mshrs[8].entry.u_core.REG_3 = u_g.inner_l2cache.slices_2.mshrCtl.mshrs_8.REG_3;
    force u_i.inner_l2cache.slices_2.u_core.mshrCtl.u_core.mshrs[9].entry.u_core.tgtid_rcompack = u_g.inner_l2cache.slices_2.mshrCtl.mshrs_9.tgtid_rcompack;
    force u_i.inner_l2cache.slices_2.u_core.mshrCtl.u_core.mshrs[9].entry.u_core.txnid_rcompack = u_g.inner_l2cache.slices_2.mshrCtl.mshrs_9.txnid_rcompack;
    force u_i.inner_l2cache.slices_2.u_core.mshrCtl.u_core.mshrs[9].entry.u_core.tgtid_wcompack = u_g.inner_l2cache.slices_2.mshrCtl.mshrs_9.tgtid_wcompack;
    force u_i.inner_l2cache.slices_2.u_core.mshrCtl.u_core.mshrs[9].entry.u_core.txnid_wcompack = u_g.inner_l2cache.slices_2.mshrCtl.mshrs_9.txnid_wcompack;
    force u_i.inner_l2cache.slices_2.u_core.mshrCtl.u_core.mshrs[9].entry.u_core.srcid_retryack = u_g.inner_l2cache.slices_2.mshrCtl.mshrs_9.srcid_retryack;
    force u_i.inner_l2cache.slices_2.u_core.mshrCtl.u_core.mshrs[9].entry.u_core.acquire_ts = u_g.inner_l2cache.slices_2.mshrCtl.mshrs_9.acquire_ts;
    force u_i.inner_l2cache.slices_2.u_core.mshrCtl.u_core.mshrs[9].entry.u_core.release_ts = u_g.inner_l2cache.slices_2.mshrCtl.mshrs_9.release_ts;
    force u_i.inner_l2cache.slices_2.u_core.mshrCtl.u_core.mshrs[9].entry.u_core.acquire_period_valid_REG = u_g.inner_l2cache.slices_2.mshrCtl.mshrs_9.acquire_period_valid_REG;
    force u_i.inner_l2cache.slices_2.u_core.mshrCtl.u_core.mshrs[9].entry.u_core.release_period_valid_REG = u_g.inner_l2cache.slices_2.mshrCtl.mshrs_9.release_period_valid_REG;
    force u_i.inner_l2cache.slices_2.u_core.mshrCtl.u_core.mshrs[9].entry.u_core.REG = u_g.inner_l2cache.slices_2.mshrCtl.mshrs_9.REG;
    force u_i.inner_l2cache.slices_2.u_core.mshrCtl.u_core.mshrs[9].entry.u_core.REG_1 = u_g.inner_l2cache.slices_2.mshrCtl.mshrs_9.REG_1;
    force u_i.inner_l2cache.slices_2.u_core.mshrCtl.u_core.mshrs[9].entry.u_core.REG_2 = u_g.inner_l2cache.slices_2.mshrCtl.mshrs_9.REG_2;
    force u_i.inner_l2cache.slices_2.u_core.mshrCtl.u_core.mshrs[9].entry.u_core.REG_3 = u_g.inner_l2cache.slices_2.mshrCtl.mshrs_9.REG_3;
    force u_i.inner_l2cache.slices_2.u_core.mshrCtl.u_core.mshrs[10].entry.u_core.tgtid_rcompack = u_g.inner_l2cache.slices_2.mshrCtl.mshrs_10.tgtid_rcompack;
    force u_i.inner_l2cache.slices_2.u_core.mshrCtl.u_core.mshrs[10].entry.u_core.txnid_rcompack = u_g.inner_l2cache.slices_2.mshrCtl.mshrs_10.txnid_rcompack;
    force u_i.inner_l2cache.slices_2.u_core.mshrCtl.u_core.mshrs[10].entry.u_core.tgtid_wcompack = u_g.inner_l2cache.slices_2.mshrCtl.mshrs_10.tgtid_wcompack;
    force u_i.inner_l2cache.slices_2.u_core.mshrCtl.u_core.mshrs[10].entry.u_core.txnid_wcompack = u_g.inner_l2cache.slices_2.mshrCtl.mshrs_10.txnid_wcompack;
    force u_i.inner_l2cache.slices_2.u_core.mshrCtl.u_core.mshrs[10].entry.u_core.srcid_retryack = u_g.inner_l2cache.slices_2.mshrCtl.mshrs_10.srcid_retryack;
    force u_i.inner_l2cache.slices_2.u_core.mshrCtl.u_core.mshrs[10].entry.u_core.acquire_ts = u_g.inner_l2cache.slices_2.mshrCtl.mshrs_10.acquire_ts;
    force u_i.inner_l2cache.slices_2.u_core.mshrCtl.u_core.mshrs[10].entry.u_core.release_ts = u_g.inner_l2cache.slices_2.mshrCtl.mshrs_10.release_ts;
    force u_i.inner_l2cache.slices_2.u_core.mshrCtl.u_core.mshrs[10].entry.u_core.acquire_period_valid_REG = u_g.inner_l2cache.slices_2.mshrCtl.mshrs_10.acquire_period_valid_REG;
    force u_i.inner_l2cache.slices_2.u_core.mshrCtl.u_core.mshrs[10].entry.u_core.release_period_valid_REG = u_g.inner_l2cache.slices_2.mshrCtl.mshrs_10.release_period_valid_REG;
    force u_i.inner_l2cache.slices_2.u_core.mshrCtl.u_core.mshrs[10].entry.u_core.REG = u_g.inner_l2cache.slices_2.mshrCtl.mshrs_10.REG;
    force u_i.inner_l2cache.slices_2.u_core.mshrCtl.u_core.mshrs[10].entry.u_core.REG_1 = u_g.inner_l2cache.slices_2.mshrCtl.mshrs_10.REG_1;
    force u_i.inner_l2cache.slices_2.u_core.mshrCtl.u_core.mshrs[10].entry.u_core.REG_2 = u_g.inner_l2cache.slices_2.mshrCtl.mshrs_10.REG_2;
    force u_i.inner_l2cache.slices_2.u_core.mshrCtl.u_core.mshrs[10].entry.u_core.REG_3 = u_g.inner_l2cache.slices_2.mshrCtl.mshrs_10.REG_3;
    force u_i.inner_l2cache.slices_2.u_core.mshrCtl.u_core.mshrs[11].entry.u_core.tgtid_rcompack = u_g.inner_l2cache.slices_2.mshrCtl.mshrs_11.tgtid_rcompack;
    force u_i.inner_l2cache.slices_2.u_core.mshrCtl.u_core.mshrs[11].entry.u_core.txnid_rcompack = u_g.inner_l2cache.slices_2.mshrCtl.mshrs_11.txnid_rcompack;
    force u_i.inner_l2cache.slices_2.u_core.mshrCtl.u_core.mshrs[11].entry.u_core.tgtid_wcompack = u_g.inner_l2cache.slices_2.mshrCtl.mshrs_11.tgtid_wcompack;
    force u_i.inner_l2cache.slices_2.u_core.mshrCtl.u_core.mshrs[11].entry.u_core.txnid_wcompack = u_g.inner_l2cache.slices_2.mshrCtl.mshrs_11.txnid_wcompack;
    force u_i.inner_l2cache.slices_2.u_core.mshrCtl.u_core.mshrs[11].entry.u_core.srcid_retryack = u_g.inner_l2cache.slices_2.mshrCtl.mshrs_11.srcid_retryack;
    force u_i.inner_l2cache.slices_2.u_core.mshrCtl.u_core.mshrs[11].entry.u_core.acquire_ts = u_g.inner_l2cache.slices_2.mshrCtl.mshrs_11.acquire_ts;
    force u_i.inner_l2cache.slices_2.u_core.mshrCtl.u_core.mshrs[11].entry.u_core.release_ts = u_g.inner_l2cache.slices_2.mshrCtl.mshrs_11.release_ts;
    force u_i.inner_l2cache.slices_2.u_core.mshrCtl.u_core.mshrs[11].entry.u_core.acquire_period_valid_REG = u_g.inner_l2cache.slices_2.mshrCtl.mshrs_11.acquire_period_valid_REG;
    force u_i.inner_l2cache.slices_2.u_core.mshrCtl.u_core.mshrs[11].entry.u_core.release_period_valid_REG = u_g.inner_l2cache.slices_2.mshrCtl.mshrs_11.release_period_valid_REG;
    force u_i.inner_l2cache.slices_2.u_core.mshrCtl.u_core.mshrs[11].entry.u_core.REG = u_g.inner_l2cache.slices_2.mshrCtl.mshrs_11.REG;
    force u_i.inner_l2cache.slices_2.u_core.mshrCtl.u_core.mshrs[11].entry.u_core.REG_1 = u_g.inner_l2cache.slices_2.mshrCtl.mshrs_11.REG_1;
    force u_i.inner_l2cache.slices_2.u_core.mshrCtl.u_core.mshrs[11].entry.u_core.REG_2 = u_g.inner_l2cache.slices_2.mshrCtl.mshrs_11.REG_2;
    force u_i.inner_l2cache.slices_2.u_core.mshrCtl.u_core.mshrs[11].entry.u_core.REG_3 = u_g.inner_l2cache.slices_2.mshrCtl.mshrs_11.REG_3;
    force u_i.inner_l2cache.slices_2.u_core.mshrCtl.u_core.mshrs[12].entry.u_core.tgtid_rcompack = u_g.inner_l2cache.slices_2.mshrCtl.mshrs_12.tgtid_rcompack;
    force u_i.inner_l2cache.slices_2.u_core.mshrCtl.u_core.mshrs[12].entry.u_core.txnid_rcompack = u_g.inner_l2cache.slices_2.mshrCtl.mshrs_12.txnid_rcompack;
    force u_i.inner_l2cache.slices_2.u_core.mshrCtl.u_core.mshrs[12].entry.u_core.tgtid_wcompack = u_g.inner_l2cache.slices_2.mshrCtl.mshrs_12.tgtid_wcompack;
    force u_i.inner_l2cache.slices_2.u_core.mshrCtl.u_core.mshrs[12].entry.u_core.txnid_wcompack = u_g.inner_l2cache.slices_2.mshrCtl.mshrs_12.txnid_wcompack;
    force u_i.inner_l2cache.slices_2.u_core.mshrCtl.u_core.mshrs[12].entry.u_core.srcid_retryack = u_g.inner_l2cache.slices_2.mshrCtl.mshrs_12.srcid_retryack;
    force u_i.inner_l2cache.slices_2.u_core.mshrCtl.u_core.mshrs[12].entry.u_core.acquire_ts = u_g.inner_l2cache.slices_2.mshrCtl.mshrs_12.acquire_ts;
    force u_i.inner_l2cache.slices_2.u_core.mshrCtl.u_core.mshrs[12].entry.u_core.release_ts = u_g.inner_l2cache.slices_2.mshrCtl.mshrs_12.release_ts;
    force u_i.inner_l2cache.slices_2.u_core.mshrCtl.u_core.mshrs[12].entry.u_core.acquire_period_valid_REG = u_g.inner_l2cache.slices_2.mshrCtl.mshrs_12.acquire_period_valid_REG;
    force u_i.inner_l2cache.slices_2.u_core.mshrCtl.u_core.mshrs[12].entry.u_core.release_period_valid_REG = u_g.inner_l2cache.slices_2.mshrCtl.mshrs_12.release_period_valid_REG;
    force u_i.inner_l2cache.slices_2.u_core.mshrCtl.u_core.mshrs[12].entry.u_core.REG = u_g.inner_l2cache.slices_2.mshrCtl.mshrs_12.REG;
    force u_i.inner_l2cache.slices_2.u_core.mshrCtl.u_core.mshrs[12].entry.u_core.REG_1 = u_g.inner_l2cache.slices_2.mshrCtl.mshrs_12.REG_1;
    force u_i.inner_l2cache.slices_2.u_core.mshrCtl.u_core.mshrs[12].entry.u_core.REG_2 = u_g.inner_l2cache.slices_2.mshrCtl.mshrs_12.REG_2;
    force u_i.inner_l2cache.slices_2.u_core.mshrCtl.u_core.mshrs[12].entry.u_core.REG_3 = u_g.inner_l2cache.slices_2.mshrCtl.mshrs_12.REG_3;
    force u_i.inner_l2cache.slices_2.u_core.mshrCtl.u_core.mshrs[13].entry.u_core.tgtid_rcompack = u_g.inner_l2cache.slices_2.mshrCtl.mshrs_13.tgtid_rcompack;
    force u_i.inner_l2cache.slices_2.u_core.mshrCtl.u_core.mshrs[13].entry.u_core.txnid_rcompack = u_g.inner_l2cache.slices_2.mshrCtl.mshrs_13.txnid_rcompack;
    force u_i.inner_l2cache.slices_2.u_core.mshrCtl.u_core.mshrs[13].entry.u_core.tgtid_wcompack = u_g.inner_l2cache.slices_2.mshrCtl.mshrs_13.tgtid_wcompack;
    force u_i.inner_l2cache.slices_2.u_core.mshrCtl.u_core.mshrs[13].entry.u_core.txnid_wcompack = u_g.inner_l2cache.slices_2.mshrCtl.mshrs_13.txnid_wcompack;
    force u_i.inner_l2cache.slices_2.u_core.mshrCtl.u_core.mshrs[13].entry.u_core.srcid_retryack = u_g.inner_l2cache.slices_2.mshrCtl.mshrs_13.srcid_retryack;
    force u_i.inner_l2cache.slices_2.u_core.mshrCtl.u_core.mshrs[13].entry.u_core.acquire_ts = u_g.inner_l2cache.slices_2.mshrCtl.mshrs_13.acquire_ts;
    force u_i.inner_l2cache.slices_2.u_core.mshrCtl.u_core.mshrs[13].entry.u_core.release_ts = u_g.inner_l2cache.slices_2.mshrCtl.mshrs_13.release_ts;
    force u_i.inner_l2cache.slices_2.u_core.mshrCtl.u_core.mshrs[13].entry.u_core.acquire_period_valid_REG = u_g.inner_l2cache.slices_2.mshrCtl.mshrs_13.acquire_period_valid_REG;
    force u_i.inner_l2cache.slices_2.u_core.mshrCtl.u_core.mshrs[13].entry.u_core.release_period_valid_REG = u_g.inner_l2cache.slices_2.mshrCtl.mshrs_13.release_period_valid_REG;
    force u_i.inner_l2cache.slices_2.u_core.mshrCtl.u_core.mshrs[13].entry.u_core.REG = u_g.inner_l2cache.slices_2.mshrCtl.mshrs_13.REG;
    force u_i.inner_l2cache.slices_2.u_core.mshrCtl.u_core.mshrs[13].entry.u_core.REG_1 = u_g.inner_l2cache.slices_2.mshrCtl.mshrs_13.REG_1;
    force u_i.inner_l2cache.slices_2.u_core.mshrCtl.u_core.mshrs[13].entry.u_core.REG_2 = u_g.inner_l2cache.slices_2.mshrCtl.mshrs_13.REG_2;
    force u_i.inner_l2cache.slices_2.u_core.mshrCtl.u_core.mshrs[13].entry.u_core.REG_3 = u_g.inner_l2cache.slices_2.mshrCtl.mshrs_13.REG_3;
    force u_i.inner_l2cache.slices_2.u_core.mshrCtl.u_core.mshrs[14].entry.u_core.tgtid_rcompack = u_g.inner_l2cache.slices_2.mshrCtl.mshrs_14.tgtid_rcompack;
    force u_i.inner_l2cache.slices_2.u_core.mshrCtl.u_core.mshrs[14].entry.u_core.txnid_rcompack = u_g.inner_l2cache.slices_2.mshrCtl.mshrs_14.txnid_rcompack;
    force u_i.inner_l2cache.slices_2.u_core.mshrCtl.u_core.mshrs[14].entry.u_core.tgtid_wcompack = u_g.inner_l2cache.slices_2.mshrCtl.mshrs_14.tgtid_wcompack;
    force u_i.inner_l2cache.slices_2.u_core.mshrCtl.u_core.mshrs[14].entry.u_core.txnid_wcompack = u_g.inner_l2cache.slices_2.mshrCtl.mshrs_14.txnid_wcompack;
    force u_i.inner_l2cache.slices_2.u_core.mshrCtl.u_core.mshrs[14].entry.u_core.srcid_retryack = u_g.inner_l2cache.slices_2.mshrCtl.mshrs_14.srcid_retryack;
    force u_i.inner_l2cache.slices_2.u_core.mshrCtl.u_core.mshrs[14].entry.u_core.acquire_ts = u_g.inner_l2cache.slices_2.mshrCtl.mshrs_14.acquire_ts;
    force u_i.inner_l2cache.slices_2.u_core.mshrCtl.u_core.mshrs[14].entry.u_core.release_ts = u_g.inner_l2cache.slices_2.mshrCtl.mshrs_14.release_ts;
    force u_i.inner_l2cache.slices_2.u_core.mshrCtl.u_core.mshrs[14].entry.u_core.acquire_period_valid_REG = u_g.inner_l2cache.slices_2.mshrCtl.mshrs_14.acquire_period_valid_REG;
    force u_i.inner_l2cache.slices_2.u_core.mshrCtl.u_core.mshrs[14].entry.u_core.release_period_valid_REG = u_g.inner_l2cache.slices_2.mshrCtl.mshrs_14.release_period_valid_REG;
    force u_i.inner_l2cache.slices_2.u_core.mshrCtl.u_core.mshrs[14].entry.u_core.REG = u_g.inner_l2cache.slices_2.mshrCtl.mshrs_14.REG;
    force u_i.inner_l2cache.slices_2.u_core.mshrCtl.u_core.mshrs[14].entry.u_core.REG_1 = u_g.inner_l2cache.slices_2.mshrCtl.mshrs_14.REG_1;
    force u_i.inner_l2cache.slices_2.u_core.mshrCtl.u_core.mshrs[14].entry.u_core.REG_2 = u_g.inner_l2cache.slices_2.mshrCtl.mshrs_14.REG_2;
    force u_i.inner_l2cache.slices_2.u_core.mshrCtl.u_core.mshrs[14].entry.u_core.REG_3 = u_g.inner_l2cache.slices_2.mshrCtl.mshrs_14.REG_3;
    force u_i.inner_l2cache.slices_2.u_core.mshrCtl.u_core.mshrs[15].entry.u_core.tgtid_rcompack = u_g.inner_l2cache.slices_2.mshrCtl.mshrs_15.tgtid_rcompack;
    force u_i.inner_l2cache.slices_2.u_core.mshrCtl.u_core.mshrs[15].entry.u_core.txnid_rcompack = u_g.inner_l2cache.slices_2.mshrCtl.mshrs_15.txnid_rcompack;
    force u_i.inner_l2cache.slices_2.u_core.mshrCtl.u_core.mshrs[15].entry.u_core.tgtid_wcompack = u_g.inner_l2cache.slices_2.mshrCtl.mshrs_15.tgtid_wcompack;
    force u_i.inner_l2cache.slices_2.u_core.mshrCtl.u_core.mshrs[15].entry.u_core.txnid_wcompack = u_g.inner_l2cache.slices_2.mshrCtl.mshrs_15.txnid_wcompack;
    force u_i.inner_l2cache.slices_2.u_core.mshrCtl.u_core.mshrs[15].entry.u_core.srcid_retryack = u_g.inner_l2cache.slices_2.mshrCtl.mshrs_15.srcid_retryack;
    force u_i.inner_l2cache.slices_2.u_core.mshrCtl.u_core.mshrs[15].entry.u_core.acquire_ts = u_g.inner_l2cache.slices_2.mshrCtl.mshrs_15.acquire_ts;
    force u_i.inner_l2cache.slices_2.u_core.mshrCtl.u_core.mshrs[15].entry.u_core.release_ts = u_g.inner_l2cache.slices_2.mshrCtl.mshrs_15.release_ts;
    force u_i.inner_l2cache.slices_2.u_core.mshrCtl.u_core.mshrs[15].entry.u_core.acquire_period_valid_REG = u_g.inner_l2cache.slices_2.mshrCtl.mshrs_15.acquire_period_valid_REG;
    force u_i.inner_l2cache.slices_2.u_core.mshrCtl.u_core.mshrs[15].entry.u_core.release_period_valid_REG = u_g.inner_l2cache.slices_2.mshrCtl.mshrs_15.release_period_valid_REG;
    force u_i.inner_l2cache.slices_2.u_core.mshrCtl.u_core.mshrs[15].entry.u_core.REG = u_g.inner_l2cache.slices_2.mshrCtl.mshrs_15.REG;
    force u_i.inner_l2cache.slices_2.u_core.mshrCtl.u_core.mshrs[15].entry.u_core.REG_1 = u_g.inner_l2cache.slices_2.mshrCtl.mshrs_15.REG_1;
    force u_i.inner_l2cache.slices_2.u_core.mshrCtl.u_core.mshrs[15].entry.u_core.REG_2 = u_g.inner_l2cache.slices_2.mshrCtl.mshrs_15.REG_2;
    force u_i.inner_l2cache.slices_2.u_core.mshrCtl.u_core.mshrs[15].entry.u_core.REG_3 = u_g.inner_l2cache.slices_2.mshrCtl.mshrs_15.REG_3;
    force u_i.inner_l2cache.slices_2.u_core.mshrCtl.u_core.io_perf_0_value_REG = u_g.inner_l2cache.slices_2.mshrCtl.io_perf_0_value_REG;
    force u_i.inner_l2cache.slices_2.u_core.mshrCtl.u_core.io_perf_0_value_REG_1 = u_g.inner_l2cache.slices_2.mshrCtl.io_perf_0_value_REG_1;
    force u_i.inner_l2cache.slices_2.u_core.mshrCtl.u_core.io_perf_1_value_REG = u_g.inner_l2cache.slices_2.mshrCtl.io_perf_1_value_REG;
    force u_i.inner_l2cache.slices_2.u_core.mshrCtl.u_core.io_perf_1_value_REG_1 = u_g.inner_l2cache.slices_2.mshrCtl.io_perf_1_value_REG_1;
    force u_i.inner_l2cache.slices_2.u_core.mshrCtl.u_core.io_perf_3_value_REG = u_g.inner_l2cache.slices_2.mshrCtl.io_perf_3_value_REG;
    force u_i.inner_l2cache.slices_2.u_core.mshrCtl.u_core.io_perf_3_value_REG_1 = u_g.inner_l2cache.slices_2.mshrCtl.io_perf_3_value_REG_1;
    force u_i.inner_l2cache.slices_2.u_core.mshrCtl.u_core.REG = u_g.inner_l2cache.slices_2.mshrCtl.REG;
    force u_i.inner_l2cache.slices_2.u_core.mainPipe.u_core.data_s4 = u_g.inner_l2cache.slices_2.mainPipe.data_s4;
    force u_i.inner_l2cache.slices_2.u_core.mainPipe.u_core.data_s5 = u_g.inner_l2cache.slices_2.mainPipe.data_s5;
    force u_i.inner_l2cache.slices_2.u_core.mainPipe.u_core.s3DropValid_d1 = u_g.inner_l2cache.slices_2.mainPipe.REG;
    force u_i.inner_l2cache.slices_2.u_core.mainPipe.u_core.reqDrop_s3_d1 = u_g.inner_l2cache.slices_2.mainPipe.reqDropped_s5_REG;
    force u_i.inner_l2cache.slices_2.u_core.mainPipe.u_core.reqDrop_s3_d2 = u_g.inner_l2cache.slices_2.mainPipe.reqDropped_s5_REG_1;
    force u_i.inner_l2cache.slices_2.u_core.mainPipe.u_core.reqDrop_s4_d1 = u_g.inner_l2cache.slices_2.mainPipe.reqDropped_s5_REG_2;
    u_i.inner_l2cache.slices_2.u_core.mainPipe.customL1Hint.hintQueue.ram_ext.Memory = u_g.inner_l2cache.slices_2.mainPipe.customL1Hint.hintQueue.ram_ext.Memory;
    u_i.inner_l2cache.slices_2.u_core.mainPipe.customL1Hint.hint_s1Queue.ram_ext.Memory = u_g.inner_l2cache.slices_2.mainPipe.customL1Hint.hint_s1Queue.ram_ext.Memory;
    force u_i.inner_l2cache.slices_2.u_core.mainPipe.u_core.perf_d1[0] = u_g.inner_l2cache.slices_2.mainPipe.io_perf_0_value_REG;
    force u_i.inner_l2cache.slices_2.u_core.mainPipe.u_core.perf[0] = u_g.inner_l2cache.slices_2.mainPipe.io_perf_0_value_REG_1;
    force u_i.inner_l2cache.slices_2.u_core.mainPipe.u_core.perf_d1[1] = u_g.inner_l2cache.slices_2.mainPipe.io_perf_1_value_REG;
    force u_i.inner_l2cache.slices_2.u_core.mainPipe.u_core.perf[1] = u_g.inner_l2cache.slices_2.mainPipe.io_perf_1_value_REG_1;
    force u_i.inner_l2cache.slices_2.u_core.mainPipe.u_core.perf_d1[2] = u_g.inner_l2cache.slices_2.mainPipe.io_perf_2_value_REG;
    force u_i.inner_l2cache.slices_2.u_core.mainPipe.u_core.perf[2] = u_g.inner_l2cache.slices_2.mainPipe.io_perf_2_value_REG_1;
    force u_i.inner_l2cache.slices_2.u_core.mainPipe.u_core.perf_d1[3] = u_g.inner_l2cache.slices_2.mainPipe.io_perf_3_value_REG;
    force u_i.inner_l2cache.slices_2.u_core.mainPipe.u_core.perf[3] = u_g.inner_l2cache.slices_2.mainPipe.io_perf_3_value_REG_1;
    force u_i.inner_l2cache.slices_2.u_core.mainPipe.u_core.perf_d1[4] = u_g.inner_l2cache.slices_2.mainPipe.io_perf_4_value_REG;
    force u_i.inner_l2cache.slices_2.u_core.mainPipe.u_core.perf[4] = u_g.inner_l2cache.slices_2.mainPipe.io_perf_4_value_REG_1;
    force u_i.inner_l2cache.slices_2.u_core.mainPipe.u_core.perf_d1[5] = u_g.inner_l2cache.slices_2.mainPipe.io_perf_5_value_REG;
    force u_i.inner_l2cache.slices_2.u_core.mainPipe.u_core.perf[5] = u_g.inner_l2cache.slices_2.mainPipe.io_perf_5_value_REG_1;
    force u_i.inner_l2cache.slices_2.u_core.mainPipe.u_core.perf_d1[6] = u_g.inner_l2cache.slices_2.mainPipe.io_perf_6_value_REG;
    force u_i.inner_l2cache.slices_2.u_core.mainPipe.u_core.perf[6] = u_g.inner_l2cache.slices_2.mainPipe.io_perf_6_value_REG_1;
    force u_i.inner_l2cache.slices_2.u_core.mainPipe.u_core.perf_d1[7] = u_g.inner_l2cache.slices_2.mainPipe.io_perf_7_value_REG;
    force u_i.inner_l2cache.slices_2.u_core.mainPipe.u_core.perf[7] = u_g.inner_l2cache.slices_2.mainPipe.io_perf_7_value_REG_1;
    force u_i.inner_l2cache.slices_2.u_core.mainPipe.u_core.perf_d1[8] = u_g.inner_l2cache.slices_2.mainPipe.io_perf_8_value_REG;
    force u_i.inner_l2cache.slices_2.u_core.mainPipe.u_core.perf[8] = u_g.inner_l2cache.slices_2.mainPipe.io_perf_8_value_REG_1;
    force u_i.inner_l2cache.slices_2.u_core.mainPipe.u_core.perf_d1[9] = u_g.inner_l2cache.slices_2.mainPipe.io_perf_9_value_REG;
    force u_i.inner_l2cache.slices_2.u_core.mainPipe.u_core.perf[9] = u_g.inner_l2cache.slices_2.mainPipe.io_perf_9_value_REG_1;
    force u_i.inner_l2cache.slices_2.u_core.mainPipe.u_core.perf_d1[10] = u_g.inner_l2cache.slices_2.mainPipe.io_perf_10_value_REG;
    force u_i.inner_l2cache.slices_2.u_core.mainPipe.u_core.perf[10] = u_g.inner_l2cache.slices_2.mainPipe.io_perf_10_value_REG_1;
    force u_i.inner_l2cache.slices_2.u_core.mainPipe.u_core.perf_d1[11] = u_g.inner_l2cache.slices_2.mainPipe.io_perf_11_value_REG;
    force u_i.inner_l2cache.slices_2.u_core.mainPipe.u_core.perf[11] = u_g.inner_l2cache.slices_2.mainPipe.io_perf_11_value_REG_1;
    force u_i.inner_l2cache.slices_2.u_core.mainPipe.u_core.perf_d1[12] = u_g.inner_l2cache.slices_2.mainPipe.io_perf_12_value_REG;
    force u_i.inner_l2cache.slices_2.u_core.mainPipe.u_core.perf[12] = u_g.inner_l2cache.slices_2.mainPipe.io_perf_12_value_REG_1;
    u_i.inner_l2cache.slices_2.u_core.grantBuf.grantQueue.ram_ext.Memory = u_g.inner_l2cache.slices_2.grantBuf.grantQueue.ram_ext.Memory;
    u_i.inner_l2cache.slices_2.u_core.grantBuf.grantQueueData0.ram_data_data_ext.Memory = u_g.inner_l2cache.slices_2.grantBuf.grantQueueData0.ram_data_data_ext.Memory;
    u_i.inner_l2cache.slices_2.u_core.grantBuf.grantQueueData1.ram_data_data_ext.Memory = u_g.inner_l2cache.slices_2.grantBuf.grantQueueData1.ram_data_data_ext.Memory;
    u_i.inner_l2cache.slices_2.u_core.grantBuf.pftRespQueue.ram_ext.Memory = u_g.inner_l2cache.slices_2.grantBuf.pftRespQueue.ram_ext.Memory;
    force u_i.inner_l2cache.slices_2.u_core.grantBuf.u_core.validPrev[0] = u_g.inner_l2cache.slices_2.grantBuf.REG;
    force u_i.inner_l2cache.slices_2.u_core.grantBuf.u_core.histValidPrev[0] = u_g.inner_l2cache.slices_2.grantBuf.enable_REG;
    force u_i.inner_l2cache.slices_2.u_core.grantBuf.u_core.validPrev[1] = u_g.inner_l2cache.slices_2.grantBuf.REG_1;
    force u_i.inner_l2cache.slices_2.u_core.grantBuf.u_core.histValidPrev[1] = u_g.inner_l2cache.slices_2.grantBuf.enable_REG_1;
    force u_i.inner_l2cache.slices_2.u_core.grantBuf.u_core.validPrev[2] = u_g.inner_l2cache.slices_2.grantBuf.REG_2;
    force u_i.inner_l2cache.slices_2.u_core.grantBuf.u_core.histValidPrev[2] = u_g.inner_l2cache.slices_2.grantBuf.enable_REG_2;
    force u_i.inner_l2cache.slices_2.u_core.grantBuf.u_core.validPrev[3] = u_g.inner_l2cache.slices_2.grantBuf.REG_3;
    force u_i.inner_l2cache.slices_2.u_core.grantBuf.u_core.histValidPrev[3] = u_g.inner_l2cache.slices_2.grantBuf.enable_REG_3;
    force u_i.inner_l2cache.slices_2.u_core.grantBuf.u_core.validPrev[4] = u_g.inner_l2cache.slices_2.grantBuf.REG_4;
    force u_i.inner_l2cache.slices_2.u_core.grantBuf.u_core.histValidPrev[4] = u_g.inner_l2cache.slices_2.grantBuf.enable_REG_4;
    force u_i.inner_l2cache.slices_2.u_core.grantBuf.u_core.validPrev[5] = u_g.inner_l2cache.slices_2.grantBuf.REG_5;
    force u_i.inner_l2cache.slices_2.u_core.grantBuf.u_core.histValidPrev[5] = u_g.inner_l2cache.slices_2.grantBuf.enable_REG_5;
    force u_i.inner_l2cache.slices_2.u_core.grantBuf.u_core.validPrev[6] = u_g.inner_l2cache.slices_2.grantBuf.REG_6;
    force u_i.inner_l2cache.slices_2.u_core.grantBuf.u_core.histValidPrev[6] = u_g.inner_l2cache.slices_2.grantBuf.enable_REG_6;
    force u_i.inner_l2cache.slices_2.u_core.grantBuf.u_core.validPrev[7] = u_g.inner_l2cache.slices_2.grantBuf.REG_7;
    force u_i.inner_l2cache.slices_2.u_core.grantBuf.u_core.histValidPrev[7] = u_g.inner_l2cache.slices_2.grantBuf.enable_REG_7;
    force u_i.inner_l2cache.slices_2.u_core.grantBuf.u_core.validPrev[8] = u_g.inner_l2cache.slices_2.grantBuf.REG_8;
    force u_i.inner_l2cache.slices_2.u_core.grantBuf.u_core.histValidPrev[8] = u_g.inner_l2cache.slices_2.grantBuf.enable_REG_8;
    force u_i.inner_l2cache.slices_2.u_core.grantBuf.u_core.validPrev[9] = u_g.inner_l2cache.slices_2.grantBuf.REG_9;
    force u_i.inner_l2cache.slices_2.u_core.grantBuf.u_core.histValidPrev[9] = u_g.inner_l2cache.slices_2.grantBuf.enable_REG_9;
    force u_i.inner_l2cache.slices_2.u_core.grantBuf.u_core.validPrev[10] = u_g.inner_l2cache.slices_2.grantBuf.REG_10;
    force u_i.inner_l2cache.slices_2.u_core.grantBuf.u_core.histValidPrev[10] = u_g.inner_l2cache.slices_2.grantBuf.enable_REG_10;
    force u_i.inner_l2cache.slices_2.u_core.grantBuf.u_core.validPrev[11] = u_g.inner_l2cache.slices_2.grantBuf.REG_11;
    force u_i.inner_l2cache.slices_2.u_core.grantBuf.u_core.histValidPrev[11] = u_g.inner_l2cache.slices_2.grantBuf.enable_REG_11;
    force u_i.inner_l2cache.slices_2.u_core.grantBuf.u_core.validPrev[12] = u_g.inner_l2cache.slices_2.grantBuf.REG_12;
    force u_i.inner_l2cache.slices_2.u_core.grantBuf.u_core.histValidPrev[12] = u_g.inner_l2cache.slices_2.grantBuf.enable_REG_12;
    force u_i.inner_l2cache.slices_2.u_core.grantBuf.u_core.validPrev[13] = u_g.inner_l2cache.slices_2.grantBuf.REG_13;
    force u_i.inner_l2cache.slices_2.u_core.grantBuf.u_core.histValidPrev[13] = u_g.inner_l2cache.slices_2.grantBuf.enable_REG_13;
    force u_i.inner_l2cache.slices_2.u_core.grantBuf.u_core.validPrev[14] = u_g.inner_l2cache.slices_2.grantBuf.REG_14;
    force u_i.inner_l2cache.slices_2.u_core.grantBuf.u_core.histValidPrev[14] = u_g.inner_l2cache.slices_2.grantBuf.enable_REG_14;
    force u_i.inner_l2cache.slices_2.u_core.grantBuf.u_core.validPrev[15] = u_g.inner_l2cache.slices_2.grantBuf.REG_15;
    force u_i.inner_l2cache.slices_2.u_core.grantBuf.u_core.histValidPrev[15] = u_g.inner_l2cache.slices_2.grantBuf.enable_REG_15;
    u_i.inner_l2cache.slices_2.u_core.rxsnp.queue.ram_ext.Memory = u_g.inner_l2cache.slices_2.rxsnp.queue.ram_ext.Memory;
    force u_i.inner_l2cache.slices_2.u_core.rxsnp.u_core.replPrevForBlock[0] = u_g.inner_l2cache.slices_2.rxsnp.replaceBlockSnpMask_REG;
    force u_i.inner_l2cache.slices_2.u_core.rxsnp.u_core.replPrevForNest[0] = u_g.inner_l2cache.slices_2.rxsnp.replaceNestSnpMask_REG;
    force u_i.inner_l2cache.slices_2.u_core.rxsnp.u_core.replPrevForBlock[1] = u_g.inner_l2cache.slices_2.rxsnp.replaceBlockSnpMask_REG_1;
    force u_i.inner_l2cache.slices_2.u_core.rxsnp.u_core.replPrevForNest[1] = u_g.inner_l2cache.slices_2.rxsnp.replaceNestSnpMask_REG_1;
    force u_i.inner_l2cache.slices_2.u_core.rxsnp.u_core.replPrevForBlock[2] = u_g.inner_l2cache.slices_2.rxsnp.replaceBlockSnpMask_REG_2;
    force u_i.inner_l2cache.slices_2.u_core.rxsnp.u_core.replPrevForNest[2] = u_g.inner_l2cache.slices_2.rxsnp.replaceNestSnpMask_REG_2;
    force u_i.inner_l2cache.slices_2.u_core.rxsnp.u_core.replPrevForBlock[3] = u_g.inner_l2cache.slices_2.rxsnp.replaceBlockSnpMask_REG_3;
    force u_i.inner_l2cache.slices_2.u_core.rxsnp.u_core.replPrevForNest[3] = u_g.inner_l2cache.slices_2.rxsnp.replaceNestSnpMask_REG_3;
    force u_i.inner_l2cache.slices_2.u_core.rxsnp.u_core.replPrevForBlock[4] = u_g.inner_l2cache.slices_2.rxsnp.replaceBlockSnpMask_REG_4;
    force u_i.inner_l2cache.slices_2.u_core.rxsnp.u_core.replPrevForNest[4] = u_g.inner_l2cache.slices_2.rxsnp.replaceNestSnpMask_REG_4;
    force u_i.inner_l2cache.slices_2.u_core.rxsnp.u_core.replPrevForBlock[5] = u_g.inner_l2cache.slices_2.rxsnp.replaceBlockSnpMask_REG_5;
    force u_i.inner_l2cache.slices_2.u_core.rxsnp.u_core.replPrevForNest[5] = u_g.inner_l2cache.slices_2.rxsnp.replaceNestSnpMask_REG_5;
    force u_i.inner_l2cache.slices_2.u_core.rxsnp.u_core.replPrevForBlock[6] = u_g.inner_l2cache.slices_2.rxsnp.replaceBlockSnpMask_REG_6;
    force u_i.inner_l2cache.slices_2.u_core.rxsnp.u_core.replPrevForNest[6] = u_g.inner_l2cache.slices_2.rxsnp.replaceNestSnpMask_REG_6;
    force u_i.inner_l2cache.slices_2.u_core.rxsnp.u_core.replPrevForBlock[7] = u_g.inner_l2cache.slices_2.rxsnp.replaceBlockSnpMask_REG_7;
    force u_i.inner_l2cache.slices_2.u_core.rxsnp.u_core.replPrevForNest[7] = u_g.inner_l2cache.slices_2.rxsnp.replaceNestSnpMask_REG_7;
    force u_i.inner_l2cache.slices_2.u_core.rxsnp.u_core.replPrevForBlock[8] = u_g.inner_l2cache.slices_2.rxsnp.replaceBlockSnpMask_REG_8;
    force u_i.inner_l2cache.slices_2.u_core.rxsnp.u_core.replPrevForNest[8] = u_g.inner_l2cache.slices_2.rxsnp.replaceNestSnpMask_REG_8;
    force u_i.inner_l2cache.slices_2.u_core.rxsnp.u_core.replPrevForBlock[9] = u_g.inner_l2cache.slices_2.rxsnp.replaceBlockSnpMask_REG_9;
    force u_i.inner_l2cache.slices_2.u_core.rxsnp.u_core.replPrevForNest[9] = u_g.inner_l2cache.slices_2.rxsnp.replaceNestSnpMask_REG_9;
    force u_i.inner_l2cache.slices_2.u_core.rxsnp.u_core.replPrevForBlock[10] = u_g.inner_l2cache.slices_2.rxsnp.replaceBlockSnpMask_REG_10;
    force u_i.inner_l2cache.slices_2.u_core.rxsnp.u_core.replPrevForNest[10] = u_g.inner_l2cache.slices_2.rxsnp.replaceNestSnpMask_REG_10;
    force u_i.inner_l2cache.slices_2.u_core.rxsnp.u_core.replPrevForBlock[11] = u_g.inner_l2cache.slices_2.rxsnp.replaceBlockSnpMask_REG_11;
    force u_i.inner_l2cache.slices_2.u_core.rxsnp.u_core.replPrevForNest[11] = u_g.inner_l2cache.slices_2.rxsnp.replaceNestSnpMask_REG_11;
    force u_i.inner_l2cache.slices_2.u_core.rxsnp.u_core.replPrevForBlock[12] = u_g.inner_l2cache.slices_2.rxsnp.replaceBlockSnpMask_REG_12;
    force u_i.inner_l2cache.slices_2.u_core.rxsnp.u_core.replPrevForNest[12] = u_g.inner_l2cache.slices_2.rxsnp.replaceNestSnpMask_REG_12;
    force u_i.inner_l2cache.slices_2.u_core.rxsnp.u_core.replPrevForBlock[13] = u_g.inner_l2cache.slices_2.rxsnp.replaceBlockSnpMask_REG_13;
    force u_i.inner_l2cache.slices_2.u_core.rxsnp.u_core.replPrevForNest[13] = u_g.inner_l2cache.slices_2.rxsnp.replaceNestSnpMask_REG_13;
    force u_i.inner_l2cache.slices_2.u_core.rxsnp.u_core.replPrevForBlock[14] = u_g.inner_l2cache.slices_2.rxsnp.replaceBlockSnpMask_REG_14;
    force u_i.inner_l2cache.slices_2.u_core.rxsnp.u_core.replPrevForNest[14] = u_g.inner_l2cache.slices_2.rxsnp.replaceNestSnpMask_REG_14;
    force u_i.inner_l2cache.slices_2.u_core.rxsnp.u_core.replPrevForBlock[15] = u_g.inner_l2cache.slices_2.rxsnp.replaceBlockSnpMask_REG_15;
    force u_i.inner_l2cache.slices_2.u_core.rxsnp.u_core.replPrevForNest[15] = u_g.inner_l2cache.slices_2.rxsnp.replaceNestSnpMask_REG_15;
    force u_i.inner_l2cache.slices_2.u_core.reqBuf.chosenQ.u_core.ram = u_g.inner_l2cache.slices_2.reqBuf.chosenQ.ram;
    force u_i.inner_l2cache.slices_2.u_core.reqBuf.u_core.hitPfPrev_set = u_g.inner_l2cache.slices_2.reqBuf.io_hasHitPfInMSHR_valid_REG_set;
    force u_i.inner_l2cache.slices_2.u_core.reqBuf.u_core.hitPfPrev_tag = u_g.inner_l2cache.slices_2.reqBuf.io_hasHitPfInMSHR_valid_REG_tag;
    force u_i.inner_l2cache.slices_2.u_core.reqBuf.u_core.mergeAPrev_set = u_g.inner_l2cache.slices_2.reqBuf.io_hasMergeA_REG_set;
    force u_i.inner_l2cache.slices_2.u_core.reqBuf.u_core.mergeAPrev_tag = u_g.inner_l2cache.slices_2.reqBuf.io_hasMergeA_REG_tag;
    force u_i.inner_l2cache.slices_2.u_core.reqBuf.u_core.sameSetS3Valid[0] = u_g.inner_l2cache.slices_2.reqBuf.canFlow_sameSet_s3_REG;
    force u_i.inner_l2cache.slices_2.u_core.reqBuf.u_core.sameSetS3Set[0] = u_g.inner_l2cache.slices_2.reqBuf.canFlow_sameSet_s3_r;
    force u_i.inner_l2cache.slices_2.u_core.reqBuf.u_core.sameSetS3Valid[1] = u_g.inner_l2cache.slices_2.reqBuf.buffer_rdy_sameSet_s3_REG;
    force u_i.inner_l2cache.slices_2.u_core.reqBuf.u_core.sameSetS3Set[1] = u_g.inner_l2cache.slices_2.reqBuf.buffer_rdy_sameSet_s3_r;
    force u_i.inner_l2cache.slices_2.u_core.reqBuf.u_core.sameSetS3Valid[2] = u_g.inner_l2cache.slices_2.reqBuf.buffer_0_rdy_sameSet_s3_REG;
    force u_i.inner_l2cache.slices_2.u_core.reqBuf.u_core.sameSetS3Set[2] = u_g.inner_l2cache.slices_2.reqBuf.buffer_0_rdy_sameSet_s3_r;
    force u_i.inner_l2cache.slices_2.u_core.reqBuf.u_core.sameSetS3Valid[3] = u_g.inner_l2cache.slices_2.reqBuf.buffer_1_rdy_sameSet_s3_REG;
    force u_i.inner_l2cache.slices_2.u_core.reqBuf.u_core.sameSetS3Set[3] = u_g.inner_l2cache.slices_2.reqBuf.buffer_1_rdy_sameSet_s3_r;
    force u_i.inner_l2cache.slices_2.u_core.reqBuf.u_core.sameSetS3Valid[4] = u_g.inner_l2cache.slices_2.reqBuf.buffer_2_rdy_sameSet_s3_REG;
    force u_i.inner_l2cache.slices_2.u_core.reqBuf.u_core.sameSetS3Set[4] = u_g.inner_l2cache.slices_2.reqBuf.buffer_2_rdy_sameSet_s3_r;
    force u_i.inner_l2cache.slices_2.u_core.reqBuf.u_core.sameSetS3Valid[5] = u_g.inner_l2cache.slices_2.reqBuf.buffer_3_rdy_sameSet_s3_REG;
    force u_i.inner_l2cache.slices_2.u_core.reqBuf.u_core.sameSetS3Set[5] = u_g.inner_l2cache.slices_2.reqBuf.buffer_3_rdy_sameSet_s3_r;
    force u_i.inner_l2cache.slices_2.u_core.sinkC.u_core.bufRespStage[0] = u_g.inner_l2cache.slices_2.sinkC.r_0;
    force u_i.inner_l2cache.slices_2.u_core.sinkC.u_core.bufRespStage[1] = u_g.inner_l2cache.slices_2.sinkC.r_1;
    force u_i.inner_l2cache.slices_2.u_core.sinkC.u_core.bufRespOut[0] = u_g.inner_l2cache.slices_2.sinkC.REG_0;
    force u_i.inner_l2cache.slices_2.u_core.sinkC.u_core.bufRespOut[1] = u_g.inner_l2cache.slices_2.sinkC.REG_1;
    force u_i.inner_l2cache.slices_2.u_core.sinkC.u_core.refillIdReg = u_g.inner_l2cache.slices_2.sinkC.io_refillBufWrite_bits_id_REG;
    force u_i.inner_l2cache.slices_2.u_core.sinkC.u_core.refillBufIdxReg = u_g.inner_l2cache.slices_2.sinkC.io_refillBufWrite_bits_data_data_REG;
    force u_i.inner_l2cache.slices_2.u_core.sinkC.u_core.taskFirePrev = u_g.inner_l2cache.slices_2.sinkC.REG_1_0;
    force u_i.inner_l2cache.slices_2.u_core.sinkC.u_core.taskBufIdxPrev = u_g.inner_l2cache.slices_2.sinkC.REG_2;
    force u_i.inner_l2cache.slices_2.u_core.reqArb.u_core.ds_mcp2_stall = u_g.inner_l2cache.slices_2.reqArb.ds_mcp2_stall;
    force u_i.inner_l2cache.slices_2.u_core.refillBuf.u_core.buffer[0][0] = u_g.inner_l2cache.slices_2.refillBuf.buffer_0_0;
    force u_i.inner_l2cache.slices_2.u_core.refillBuf.u_core.buffer[0][1] = u_g.inner_l2cache.slices_2.refillBuf.buffer_0_1;
    force u_i.inner_l2cache.slices_2.u_core.refillBuf.u_core.buffer[1][0] = u_g.inner_l2cache.slices_2.refillBuf.buffer_1_0;
    force u_i.inner_l2cache.slices_2.u_core.refillBuf.u_core.buffer[1][1] = u_g.inner_l2cache.slices_2.refillBuf.buffer_1_1;
    force u_i.inner_l2cache.slices_2.u_core.refillBuf.u_core.buffer[2][0] = u_g.inner_l2cache.slices_2.refillBuf.buffer_2_0;
    force u_i.inner_l2cache.slices_2.u_core.refillBuf.u_core.buffer[2][1] = u_g.inner_l2cache.slices_2.refillBuf.buffer_2_1;
    force u_i.inner_l2cache.slices_2.u_core.refillBuf.u_core.buffer[3][0] = u_g.inner_l2cache.slices_2.refillBuf.buffer_3_0;
    force u_i.inner_l2cache.slices_2.u_core.refillBuf.u_core.buffer[3][1] = u_g.inner_l2cache.slices_2.refillBuf.buffer_3_1;
    force u_i.inner_l2cache.slices_2.u_core.refillBuf.u_core.buffer[4][0] = u_g.inner_l2cache.slices_2.refillBuf.buffer_4_0;
    force u_i.inner_l2cache.slices_2.u_core.refillBuf.u_core.buffer[4][1] = u_g.inner_l2cache.slices_2.refillBuf.buffer_4_1;
    force u_i.inner_l2cache.slices_2.u_core.refillBuf.u_core.buffer[5][0] = u_g.inner_l2cache.slices_2.refillBuf.buffer_5_0;
    force u_i.inner_l2cache.slices_2.u_core.refillBuf.u_core.buffer[5][1] = u_g.inner_l2cache.slices_2.refillBuf.buffer_5_1;
    force u_i.inner_l2cache.slices_2.u_core.refillBuf.u_core.buffer[6][0] = u_g.inner_l2cache.slices_2.refillBuf.buffer_6_0;
    force u_i.inner_l2cache.slices_2.u_core.refillBuf.u_core.buffer[6][1] = u_g.inner_l2cache.slices_2.refillBuf.buffer_6_1;
    force u_i.inner_l2cache.slices_2.u_core.refillBuf.u_core.buffer[7][0] = u_g.inner_l2cache.slices_2.refillBuf.buffer_7_0;
    force u_i.inner_l2cache.slices_2.u_core.refillBuf.u_core.buffer[7][1] = u_g.inner_l2cache.slices_2.refillBuf.buffer_7_1;
    force u_i.inner_l2cache.slices_2.u_core.refillBuf.u_core.buffer[8][0] = u_g.inner_l2cache.slices_2.refillBuf.buffer_8_0;
    force u_i.inner_l2cache.slices_2.u_core.refillBuf.u_core.buffer[8][1] = u_g.inner_l2cache.slices_2.refillBuf.buffer_8_1;
    force u_i.inner_l2cache.slices_2.u_core.refillBuf.u_core.buffer[9][0] = u_g.inner_l2cache.slices_2.refillBuf.buffer_9_0;
    force u_i.inner_l2cache.slices_2.u_core.refillBuf.u_core.buffer[9][1] = u_g.inner_l2cache.slices_2.refillBuf.buffer_9_1;
    force u_i.inner_l2cache.slices_2.u_core.refillBuf.u_core.buffer[10][0] = u_g.inner_l2cache.slices_2.refillBuf.buffer_10_0;
    force u_i.inner_l2cache.slices_2.u_core.refillBuf.u_core.buffer[10][1] = u_g.inner_l2cache.slices_2.refillBuf.buffer_10_1;
    force u_i.inner_l2cache.slices_2.u_core.refillBuf.u_core.buffer[11][0] = u_g.inner_l2cache.slices_2.refillBuf.buffer_11_0;
    force u_i.inner_l2cache.slices_2.u_core.refillBuf.u_core.buffer[11][1] = u_g.inner_l2cache.slices_2.refillBuf.buffer_11_1;
    force u_i.inner_l2cache.slices_2.u_core.refillBuf.u_core.buffer[12][0] = u_g.inner_l2cache.slices_2.refillBuf.buffer_12_0;
    force u_i.inner_l2cache.slices_2.u_core.refillBuf.u_core.buffer[12][1] = u_g.inner_l2cache.slices_2.refillBuf.buffer_12_1;
    force u_i.inner_l2cache.slices_2.u_core.refillBuf.u_core.buffer[13][0] = u_g.inner_l2cache.slices_2.refillBuf.buffer_13_0;
    force u_i.inner_l2cache.slices_2.u_core.refillBuf.u_core.buffer[13][1] = u_g.inner_l2cache.slices_2.refillBuf.buffer_13_1;
    force u_i.inner_l2cache.slices_2.u_core.refillBuf.u_core.buffer[14][0] = u_g.inner_l2cache.slices_2.refillBuf.buffer_14_0;
    force u_i.inner_l2cache.slices_2.u_core.refillBuf.u_core.buffer[14][1] = u_g.inner_l2cache.slices_2.refillBuf.buffer_14_1;
    force u_i.inner_l2cache.slices_2.u_core.refillBuf.u_core.buffer[15][0] = u_g.inner_l2cache.slices_2.refillBuf.buffer_15_0;
    force u_i.inner_l2cache.slices_2.u_core.refillBuf.u_core.buffer[15][1] = u_g.inner_l2cache.slices_2.refillBuf.buffer_15_1;
    force u_i.inner_l2cache.slices_2.u_core.releaseBuf.u_core.buffer[0][0] = u_g.inner_l2cache.slices_2.releaseBuf.buffer_0_0;
    force u_i.inner_l2cache.slices_2.u_core.releaseBuf.u_core.buffer[0][1] = u_g.inner_l2cache.slices_2.releaseBuf.buffer_0_1;
    force u_i.inner_l2cache.slices_2.u_core.releaseBuf.u_core.buffer[1][0] = u_g.inner_l2cache.slices_2.releaseBuf.buffer_1_0;
    force u_i.inner_l2cache.slices_2.u_core.releaseBuf.u_core.buffer[1][1] = u_g.inner_l2cache.slices_2.releaseBuf.buffer_1_1;
    force u_i.inner_l2cache.slices_2.u_core.releaseBuf.u_core.buffer[2][0] = u_g.inner_l2cache.slices_2.releaseBuf.buffer_2_0;
    force u_i.inner_l2cache.slices_2.u_core.releaseBuf.u_core.buffer[2][1] = u_g.inner_l2cache.slices_2.releaseBuf.buffer_2_1;
    force u_i.inner_l2cache.slices_2.u_core.releaseBuf.u_core.buffer[3][0] = u_g.inner_l2cache.slices_2.releaseBuf.buffer_3_0;
    force u_i.inner_l2cache.slices_2.u_core.releaseBuf.u_core.buffer[3][1] = u_g.inner_l2cache.slices_2.releaseBuf.buffer_3_1;
    force u_i.inner_l2cache.slices_2.u_core.releaseBuf.u_core.buffer[4][0] = u_g.inner_l2cache.slices_2.releaseBuf.buffer_4_0;
    force u_i.inner_l2cache.slices_2.u_core.releaseBuf.u_core.buffer[4][1] = u_g.inner_l2cache.slices_2.releaseBuf.buffer_4_1;
    force u_i.inner_l2cache.slices_2.u_core.releaseBuf.u_core.buffer[5][0] = u_g.inner_l2cache.slices_2.releaseBuf.buffer_5_0;
    force u_i.inner_l2cache.slices_2.u_core.releaseBuf.u_core.buffer[5][1] = u_g.inner_l2cache.slices_2.releaseBuf.buffer_5_1;
    force u_i.inner_l2cache.slices_2.u_core.releaseBuf.u_core.buffer[6][0] = u_g.inner_l2cache.slices_2.releaseBuf.buffer_6_0;
    force u_i.inner_l2cache.slices_2.u_core.releaseBuf.u_core.buffer[6][1] = u_g.inner_l2cache.slices_2.releaseBuf.buffer_6_1;
    force u_i.inner_l2cache.slices_2.u_core.releaseBuf.u_core.buffer[7][0] = u_g.inner_l2cache.slices_2.releaseBuf.buffer_7_0;
    force u_i.inner_l2cache.slices_2.u_core.releaseBuf.u_core.buffer[7][1] = u_g.inner_l2cache.slices_2.releaseBuf.buffer_7_1;
    force u_i.inner_l2cache.slices_2.u_core.releaseBuf.u_core.buffer[8][0] = u_g.inner_l2cache.slices_2.releaseBuf.buffer_8_0;
    force u_i.inner_l2cache.slices_2.u_core.releaseBuf.u_core.buffer[8][1] = u_g.inner_l2cache.slices_2.releaseBuf.buffer_8_1;
    force u_i.inner_l2cache.slices_2.u_core.releaseBuf.u_core.buffer[9][0] = u_g.inner_l2cache.slices_2.releaseBuf.buffer_9_0;
    force u_i.inner_l2cache.slices_2.u_core.releaseBuf.u_core.buffer[9][1] = u_g.inner_l2cache.slices_2.releaseBuf.buffer_9_1;
    force u_i.inner_l2cache.slices_2.u_core.releaseBuf.u_core.buffer[10][0] = u_g.inner_l2cache.slices_2.releaseBuf.buffer_10_0;
    force u_i.inner_l2cache.slices_2.u_core.releaseBuf.u_core.buffer[10][1] = u_g.inner_l2cache.slices_2.releaseBuf.buffer_10_1;
    force u_i.inner_l2cache.slices_2.u_core.releaseBuf.u_core.buffer[11][0] = u_g.inner_l2cache.slices_2.releaseBuf.buffer_11_0;
    force u_i.inner_l2cache.slices_2.u_core.releaseBuf.u_core.buffer[11][1] = u_g.inner_l2cache.slices_2.releaseBuf.buffer_11_1;
    force u_i.inner_l2cache.slices_2.u_core.releaseBuf.u_core.buffer[12][0] = u_g.inner_l2cache.slices_2.releaseBuf.buffer_12_0;
    force u_i.inner_l2cache.slices_2.u_core.releaseBuf.u_core.buffer[12][1] = u_g.inner_l2cache.slices_2.releaseBuf.buffer_12_1;
    force u_i.inner_l2cache.slices_2.u_core.releaseBuf.u_core.buffer[13][0] = u_g.inner_l2cache.slices_2.releaseBuf.buffer_13_0;
    force u_i.inner_l2cache.slices_2.u_core.releaseBuf.u_core.buffer[13][1] = u_g.inner_l2cache.slices_2.releaseBuf.buffer_13_1;
    force u_i.inner_l2cache.slices_2.u_core.releaseBuf.u_core.buffer[14][0] = u_g.inner_l2cache.slices_2.releaseBuf.buffer_14_0;
    force u_i.inner_l2cache.slices_2.u_core.releaseBuf.u_core.buffer[14][1] = u_g.inner_l2cache.slices_2.releaseBuf.buffer_14_1;
    force u_i.inner_l2cache.slices_2.u_core.releaseBuf.u_core.buffer[15][0] = u_g.inner_l2cache.slices_2.releaseBuf.buffer_15_0;
    force u_i.inner_l2cache.slices_2.u_core.releaseBuf.u_core.buffer[15][1] = u_g.inner_l2cache.slices_2.releaseBuf.buffer_15_1;
    u_i.inner_l2cache.slices_2.u_core.txdat.queue.ram_ext.Memory = u_g.inner_l2cache.slices_2.txdat.queue.ram_ext.Memory;
    u_i.inner_l2cache.slices_2.u_core.txdat.queueData0.ram_data_ext.Memory = u_g.inner_l2cache.slices_2.txdat.queueData0.ram_data_ext.Memory;
    u_i.inner_l2cache.slices_2.u_core.txdat.queueData1.ram_data_ext.Memory = u_g.inner_l2cache.slices_2.txdat.queueData1.ram_data_ext.Memory;
    u_i.inner_l2cache.slices_2.directory.tagArray.array_0_0_0.array.array.array_14_ext.ram = u_g.inner_l2cache.slices_2.directory.tagArray.array_0_0_0.array.array.array_14_ext.ram;
    u_i.inner_l2cache.slices_2.directory.tagArray.array_0_0_0.array.array.array_14_ext.reg_RW0_addr = u_g.inner_l2cache.slices_2.directory.tagArray.array_0_0_0.array.array.array_14_ext.reg_RW0_addr;
    u_i.inner_l2cache.slices_2.directory.tagArray.array_0_0_0.array.array.array_14_ext.reg_RW0_ren = u_g.inner_l2cache.slices_2.directory.tagArray.array_0_0_0.array.array.array_14_ext.reg_RW0_ren;
    force u_i.inner_l2cache.slices_2.directory.tagArray.array_0_0_0.u_core.rdataReg = u_g.inner_l2cache.slices_2.directory.tagArray.array_0_0_0.rdataReg;
    u_i.inner_l2cache.slices_2.directory.tagArray.array_0_0_1.array.array.array_14_ext.ram = u_g.inner_l2cache.slices_2.directory.tagArray.array_0_0_1.array.array.array_14_ext.ram;
    u_i.inner_l2cache.slices_2.directory.tagArray.array_0_0_1.array.array.array_14_ext.reg_RW0_addr = u_g.inner_l2cache.slices_2.directory.tagArray.array_0_0_1.array.array.array_14_ext.reg_RW0_addr;
    u_i.inner_l2cache.slices_2.directory.tagArray.array_0_0_1.array.array.array_14_ext.reg_RW0_ren = u_g.inner_l2cache.slices_2.directory.tagArray.array_0_0_1.array.array.array_14_ext.reg_RW0_ren;
    force u_i.inner_l2cache.slices_2.directory.tagArray.array_0_0_1.u_core.rdataReg = u_g.inner_l2cache.slices_2.directory.tagArray.array_0_0_1.rdataReg;
    u_i.inner_l2cache.slices_2.directory.tagArray.array_0_1_0.array.array.array_14_ext.ram = u_g.inner_l2cache.slices_2.directory.tagArray.array_0_1_0.array.array.array_14_ext.ram;
    u_i.inner_l2cache.slices_2.directory.tagArray.array_0_1_0.array.array.array_14_ext.reg_RW0_addr = u_g.inner_l2cache.slices_2.directory.tagArray.array_0_1_0.array.array.array_14_ext.reg_RW0_addr;
    u_i.inner_l2cache.slices_2.directory.tagArray.array_0_1_0.array.array.array_14_ext.reg_RW0_ren = u_g.inner_l2cache.slices_2.directory.tagArray.array_0_1_0.array.array.array_14_ext.reg_RW0_ren;
    force u_i.inner_l2cache.slices_2.directory.tagArray.array_0_1_0.u_core.rdataReg = u_g.inner_l2cache.slices_2.directory.tagArray.array_0_1_0.rdataReg;
    u_i.inner_l2cache.slices_2.directory.tagArray.array_0_1_1.array.array.array_14_ext.ram = u_g.inner_l2cache.slices_2.directory.tagArray.array_0_1_1.array.array.array_14_ext.ram;
    u_i.inner_l2cache.slices_2.directory.tagArray.array_0_1_1.array.array.array_14_ext.reg_RW0_addr = u_g.inner_l2cache.slices_2.directory.tagArray.array_0_1_1.array.array.array_14_ext.reg_RW0_addr;
    u_i.inner_l2cache.slices_2.directory.tagArray.array_0_1_1.array.array.array_14_ext.reg_RW0_ren = u_g.inner_l2cache.slices_2.directory.tagArray.array_0_1_1.array.array.array_14_ext.reg_RW0_ren;
    force u_i.inner_l2cache.slices_2.directory.tagArray.array_0_1_1.u_core.rdataReg = u_g.inner_l2cache.slices_2.directory.tagArray.array_0_1_1.rdataReg;
    u_i.inner_l2cache.slices_2.directory.metaArray.array.array.array_15_ext.ram = u_g.inner_l2cache.slices_2.directory.metaArray.array.array.array_15_ext.ram;
    u_i.inner_l2cache.slices_2.directory.metaArray.array.array.array_15_ext.reg_RW0_addr = u_g.inner_l2cache.slices_2.directory.metaArray.array.array.array_15_ext.reg_RW0_addr;
    u_i.inner_l2cache.slices_2.directory.metaArray.array.array.array_15_ext.reg_RW0_ren = u_g.inner_l2cache.slices_2.directory.metaArray.array.array.array_15_ext.reg_RW0_ren;
    force u_i.inner_l2cache.slices_2.directory.metaArray.u_core.rdataReg = u_g.inner_l2cache.slices_2.directory.metaArray.rdataReg;
    u_i.inner_l2cache.slices_2.directory.replacer_sram_opt.array.array.array_16_ext.ram = u_g.inner_l2cache.slices_2.directory.replacer_sram_opt.array.array.array_16_ext.ram;
    u_i.inner_l2cache.slices_2.directory.replacer_sram_opt.array.array.array_16_ext.reg_RW0_addr = u_g.inner_l2cache.slices_2.directory.replacer_sram_opt.array.array.array_16_ext.reg_RW0_addr;
    u_i.inner_l2cache.slices_2.directory.replacer_sram_opt.array.array.array_16_ext.reg_RW0_ren = u_g.inner_l2cache.slices_2.directory.replacer_sram_opt.array.array.array_16_ext.reg_RW0_ren;
    force u_i.inner_l2cache.slices_2.directory.replacer_sram_opt.u_core.rdataReg = u_g.inner_l2cache.slices_2.directory.replacer_sram_opt.rdataReg;
    u_i.inner_l2cache.slices_2.directory.origin_bit_opt.array.array.array_17_ext.ram = u_g.inner_l2cache.slices_2.directory.origin_bit_opt.array.array.array_17_ext.ram;
    u_i.inner_l2cache.slices_2.directory.origin_bit_opt.array.array.array_17_ext.reg_RW0_addr = u_g.inner_l2cache.slices_2.directory.origin_bit_opt.array.array.array_17_ext.reg_RW0_addr;
    u_i.inner_l2cache.slices_2.directory.origin_bit_opt.array.array.array_17_ext.reg_RW0_ren = u_g.inner_l2cache.slices_2.directory.origin_bit_opt.array.array.array_17_ext.reg_RW0_ren;
    force u_i.inner_l2cache.slices_2.directory.origin_bit_opt.u_core.rdataReg = u_g.inner_l2cache.slices_2.directory.origin_bit_opt.rdataReg;
    u_i.inner_l2cache.slices_2.dataStorage.array.array_0_0_0.array.array.array_18_ext.ram = u_g.inner_l2cache.slices_2.dataStorage.array.array_0_0_0.array.array.array_18_ext.ram;
    u_i.inner_l2cache.slices_2.dataStorage.array.array_0_0_0.array.array.array_18_ext.reg_RW0_addr = u_g.inner_l2cache.slices_2.dataStorage.array.array_0_0_0.array.array.array_18_ext.reg_RW0_addr;
    u_i.inner_l2cache.slices_2.dataStorage.array.array_0_0_0.array.array.array_18_ext.reg_RW0_ren = u_g.inner_l2cache.slices_2.dataStorage.array.array_0_0_0.array.array.array_18_ext.reg_RW0_ren;
    force u_i.inner_l2cache.slices_2.dataStorage.array.array_0_0_0.u_core.rdataReg = u_g.inner_l2cache.slices_2.dataStorage.array.array_0_0_0.rdataReg;
    u_i.inner_l2cache.slices_2.dataStorage.array.array_0_0_1.array.array.array_18_ext.ram = u_g.inner_l2cache.slices_2.dataStorage.array.array_0_0_1.array.array.array_18_ext.ram;
    u_i.inner_l2cache.slices_2.dataStorage.array.array_0_0_1.array.array.array_18_ext.reg_RW0_addr = u_g.inner_l2cache.slices_2.dataStorage.array.array_0_0_1.array.array.array_18_ext.reg_RW0_addr;
    u_i.inner_l2cache.slices_2.dataStorage.array.array_0_0_1.array.array.array_18_ext.reg_RW0_ren = u_g.inner_l2cache.slices_2.dataStorage.array.array_0_0_1.array.array.array_18_ext.reg_RW0_ren;
    force u_i.inner_l2cache.slices_2.dataStorage.array.array_0_0_1.u_core.rdataReg = u_g.inner_l2cache.slices_2.dataStorage.array.array_0_0_1.rdataReg;
    u_i.inner_l2cache.slices_2.dataStorage.array.array_0_0_2.array.array.array_18_ext.ram = u_g.inner_l2cache.slices_2.dataStorage.array.array_0_0_2.array.array.array_18_ext.ram;
    u_i.inner_l2cache.slices_2.dataStorage.array.array_0_0_2.array.array.array_18_ext.reg_RW0_addr = u_g.inner_l2cache.slices_2.dataStorage.array.array_0_0_2.array.array.array_18_ext.reg_RW0_addr;
    u_i.inner_l2cache.slices_2.dataStorage.array.array_0_0_2.array.array.array_18_ext.reg_RW0_ren = u_g.inner_l2cache.slices_2.dataStorage.array.array_0_0_2.array.array.array_18_ext.reg_RW0_ren;
    force u_i.inner_l2cache.slices_2.dataStorage.array.array_0_0_2.u_core.rdataReg = u_g.inner_l2cache.slices_2.dataStorage.array.array_0_0_2.rdataReg;
    u_i.inner_l2cache.slices_2.dataStorage.array.array_0_0_3.array.array.array_18_ext.ram = u_g.inner_l2cache.slices_2.dataStorage.array.array_0_0_3.array.array.array_18_ext.ram;
    u_i.inner_l2cache.slices_2.dataStorage.array.array_0_0_3.array.array.array_18_ext.reg_RW0_addr = u_g.inner_l2cache.slices_2.dataStorage.array.array_0_0_3.array.array.array_18_ext.reg_RW0_addr;
    u_i.inner_l2cache.slices_2.dataStorage.array.array_0_0_3.array.array.array_18_ext.reg_RW0_ren = u_g.inner_l2cache.slices_2.dataStorage.array.array_0_0_3.array.array.array_18_ext.reg_RW0_ren;
    force u_i.inner_l2cache.slices_2.dataStorage.array.array_0_0_3.u_core.rdataReg = u_g.inner_l2cache.slices_2.dataStorage.array.array_0_0_3.rdataReg;
    force u_i.inner_l2cache.slices_2.dataStorage.u_core.error_REG = u_g.inner_l2cache.slices_2.dataStorage.error_REG;
    force u_i.inner_l2cache.slices_2.dataStorage.u_core.error_REG_1 = u_g.inner_l2cache.slices_2.dataStorage.error_REG_1;
    force u_i.inner_l2cache.slices_2.mbistPl.u_core.g_node_return.pipelineDataOutReg = u_g.inner_l2cache.slices_2.mbistPl.pipelineDataOutReg;
    u_i.inner_l2cache.slices_2.u_core.txreq.u_core.queue.ram_ext.Memory = u_g.inner_l2cache.slices_2.txreq.queue.ram_ext.Memory;
    u_i.inner_l2cache.slices_2.u_core.txrsp.u_core.queue.ram_ext.Memory = u_g.inner_l2cache.slices_2.txrsp.queue.ram_ext.Memory;
    force u_i.inner_l2cache.slices_2.u_core.io_error_bits_REG_valid = u_g.inner_l2cache.slices_2.io_error_bits_REG_valid;
    force u_i.inner_l2cache.slices_2.u_core.io_error_bits_REG_address = u_g.inner_l2cache.slices_2.io_error_bits_REG_address;
    force u_i.inner_l2cache.slices_2.u_core.io_perf_0_value_REG = u_g.inner_l2cache.slices_2.io_perf_0_value_REG;
    force u_i.inner_l2cache.slices_2.u_core.io_perf_0_value_REG_1 = u_g.inner_l2cache.slices_2.io_perf_0_value_REG_1;
    force u_i.inner_l2cache.slices_2.u_core.io_perf_1_value_REG = u_g.inner_l2cache.slices_2.io_perf_1_value_REG;
    force u_i.inner_l2cache.slices_2.u_core.io_perf_1_value_REG_1 = u_g.inner_l2cache.slices_2.io_perf_1_value_REG_1;
    force u_i.inner_l2cache.slices_2.u_core.io_perf_3_value_REG = u_g.inner_l2cache.slices_2.io_perf_3_value_REG;
    force u_i.inner_l2cache.slices_2.u_core.io_perf_3_value_REG_1 = u_g.inner_l2cache.slices_2.io_perf_3_value_REG_1;
    force u_i.inner_l2cache.slices_2.u_core.io_perf_4_value_REG = u_g.inner_l2cache.slices_2.io_perf_4_value_REG;
    force u_i.inner_l2cache.slices_2.u_core.io_perf_4_value_REG_1 = u_g.inner_l2cache.slices_2.io_perf_4_value_REG_1;
    force u_i.inner_l2cache.slices_2.u_core.io_perf_5_value_REG = u_g.inner_l2cache.slices_2.io_perf_5_value_REG;
    force u_i.inner_l2cache.slices_2.u_core.io_perf_5_value_REG_1 = u_g.inner_l2cache.slices_2.io_perf_5_value_REG_1;
    force u_i.inner_l2cache.slices_2.u_core.io_perf_6_value_REG = u_g.inner_l2cache.slices_2.io_perf_6_value_REG;
    force u_i.inner_l2cache.slices_2.u_core.io_perf_6_value_REG_1 = u_g.inner_l2cache.slices_2.io_perf_6_value_REG_1;
    force u_i.inner_l2cache.slices_2.u_core.io_perf_7_value_REG = u_g.inner_l2cache.slices_2.io_perf_7_value_REG;
    force u_i.inner_l2cache.slices_2.u_core.io_perf_7_value_REG_1 = u_g.inner_l2cache.slices_2.io_perf_7_value_REG_1;
    force u_i.inner_l2cache.slices_2.u_core.io_perf_8_value_REG = u_g.inner_l2cache.slices_2.io_perf_8_value_REG;
    force u_i.inner_l2cache.slices_2.u_core.io_perf_8_value_REG_1 = u_g.inner_l2cache.slices_2.io_perf_8_value_REG_1;
    force u_i.inner_l2cache.slices_2.u_core.io_perf_9_value_REG = u_g.inner_l2cache.slices_2.io_perf_9_value_REG;
    force u_i.inner_l2cache.slices_2.u_core.io_perf_9_value_REG_1 = u_g.inner_l2cache.slices_2.io_perf_9_value_REG_1;
    force u_i.inner_l2cache.slices_2.u_core.io_perf_10_value_REG = u_g.inner_l2cache.slices_2.io_perf_10_value_REG;
    force u_i.inner_l2cache.slices_2.u_core.io_perf_10_value_REG_1 = u_g.inner_l2cache.slices_2.io_perf_10_value_REG_1;
    force u_i.inner_l2cache.slices_2.u_core.io_perf_11_value_REG = u_g.inner_l2cache.slices_2.io_perf_11_value_REG;
    force u_i.inner_l2cache.slices_2.u_core.io_perf_11_value_REG_1 = u_g.inner_l2cache.slices_2.io_perf_11_value_REG_1;
    force u_i.inner_l2cache.slices_2.u_core.io_perf_12_value_REG = u_g.inner_l2cache.slices_2.io_perf_12_value_REG;
    force u_i.inner_l2cache.slices_2.u_core.io_perf_12_value_REG_1 = u_g.inner_l2cache.slices_2.io_perf_12_value_REG_1;
    force u_i.inner_l2cache.slices_2.u_core.io_perf_13_value_REG = u_g.inner_l2cache.slices_2.io_perf_13_value_REG;
    force u_i.inner_l2cache.slices_2.u_core.io_perf_13_value_REG_1 = u_g.inner_l2cache.slices_2.io_perf_13_value_REG_1;
    force u_i.inner_l2cache.slices_2.u_core.io_perf_14_value_REG = u_g.inner_l2cache.slices_2.io_perf_14_value_REG;
    force u_i.inner_l2cache.slices_2.u_core.io_perf_14_value_REG_1 = u_g.inner_l2cache.slices_2.io_perf_14_value_REG_1;
    force u_i.inner_l2cache.slices_2.u_core.io_perf_15_value_REG = u_g.inner_l2cache.slices_2.io_perf_15_value_REG;
    force u_i.inner_l2cache.slices_2.u_core.io_perf_15_value_REG_1 = u_g.inner_l2cache.slices_2.io_perf_15_value_REG_1;
    force u_i.inner_l2cache.slices_2.u_core.io_perf_16_value_REG = u_g.inner_l2cache.slices_2.io_perf_16_value_REG;
    force u_i.inner_l2cache.slices_2.u_core.io_perf_16_value_REG_1 = u_g.inner_l2cache.slices_2.io_perf_16_value_REG_1;
    force u_i.inner_l2cache.slices_3.u_core.mshrCtl.u_core.mshrs[0].entry.u_core.tgtid_rcompack = u_g.inner_l2cache.slices_3.mshrCtl.mshrs_0.tgtid_rcompack;
    force u_i.inner_l2cache.slices_3.u_core.mshrCtl.u_core.mshrs[0].entry.u_core.txnid_rcompack = u_g.inner_l2cache.slices_3.mshrCtl.mshrs_0.txnid_rcompack;
    force u_i.inner_l2cache.slices_3.u_core.mshrCtl.u_core.mshrs[0].entry.u_core.tgtid_wcompack = u_g.inner_l2cache.slices_3.mshrCtl.mshrs_0.tgtid_wcompack;
    force u_i.inner_l2cache.slices_3.u_core.mshrCtl.u_core.mshrs[0].entry.u_core.txnid_wcompack = u_g.inner_l2cache.slices_3.mshrCtl.mshrs_0.txnid_wcompack;
    force u_i.inner_l2cache.slices_3.u_core.mshrCtl.u_core.mshrs[0].entry.u_core.srcid_retryack = u_g.inner_l2cache.slices_3.mshrCtl.mshrs_0.srcid_retryack;
    force u_i.inner_l2cache.slices_3.u_core.mshrCtl.u_core.mshrs[0].entry.u_core.acquire_ts = u_g.inner_l2cache.slices_3.mshrCtl.mshrs_0.acquire_ts;
    force u_i.inner_l2cache.slices_3.u_core.mshrCtl.u_core.mshrs[0].entry.u_core.release_ts = u_g.inner_l2cache.slices_3.mshrCtl.mshrs_0.release_ts;
    force u_i.inner_l2cache.slices_3.u_core.mshrCtl.u_core.mshrs[0].entry.u_core.acquire_period_valid_REG = u_g.inner_l2cache.slices_3.mshrCtl.mshrs_0.acquire_period_valid_REG;
    force u_i.inner_l2cache.slices_3.u_core.mshrCtl.u_core.mshrs[0].entry.u_core.release_period_valid_REG = u_g.inner_l2cache.slices_3.mshrCtl.mshrs_0.release_period_valid_REG;
    force u_i.inner_l2cache.slices_3.u_core.mshrCtl.u_core.mshrs[0].entry.u_core.REG = u_g.inner_l2cache.slices_3.mshrCtl.mshrs_0.REG;
    force u_i.inner_l2cache.slices_3.u_core.mshrCtl.u_core.mshrs[0].entry.u_core.REG_1 = u_g.inner_l2cache.slices_3.mshrCtl.mshrs_0.REG_1;
    force u_i.inner_l2cache.slices_3.u_core.mshrCtl.u_core.mshrs[0].entry.u_core.REG_2 = u_g.inner_l2cache.slices_3.mshrCtl.mshrs_0.REG_2;
    force u_i.inner_l2cache.slices_3.u_core.mshrCtl.u_core.mshrs[0].entry.u_core.REG_3 = u_g.inner_l2cache.slices_3.mshrCtl.mshrs_0.REG_3;
    force u_i.inner_l2cache.slices_3.u_core.mshrCtl.u_core.mshrs[1].entry.u_core.tgtid_rcompack = u_g.inner_l2cache.slices_3.mshrCtl.mshrs_1.tgtid_rcompack;
    force u_i.inner_l2cache.slices_3.u_core.mshrCtl.u_core.mshrs[1].entry.u_core.txnid_rcompack = u_g.inner_l2cache.slices_3.mshrCtl.mshrs_1.txnid_rcompack;
    force u_i.inner_l2cache.slices_3.u_core.mshrCtl.u_core.mshrs[1].entry.u_core.tgtid_wcompack = u_g.inner_l2cache.slices_3.mshrCtl.mshrs_1.tgtid_wcompack;
    force u_i.inner_l2cache.slices_3.u_core.mshrCtl.u_core.mshrs[1].entry.u_core.txnid_wcompack = u_g.inner_l2cache.slices_3.mshrCtl.mshrs_1.txnid_wcompack;
    force u_i.inner_l2cache.slices_3.u_core.mshrCtl.u_core.mshrs[1].entry.u_core.srcid_retryack = u_g.inner_l2cache.slices_3.mshrCtl.mshrs_1.srcid_retryack;
    force u_i.inner_l2cache.slices_3.u_core.mshrCtl.u_core.mshrs[1].entry.u_core.acquire_ts = u_g.inner_l2cache.slices_3.mshrCtl.mshrs_1.acquire_ts;
    force u_i.inner_l2cache.slices_3.u_core.mshrCtl.u_core.mshrs[1].entry.u_core.release_ts = u_g.inner_l2cache.slices_3.mshrCtl.mshrs_1.release_ts;
    force u_i.inner_l2cache.slices_3.u_core.mshrCtl.u_core.mshrs[1].entry.u_core.acquire_period_valid_REG = u_g.inner_l2cache.slices_3.mshrCtl.mshrs_1.acquire_period_valid_REG;
    force u_i.inner_l2cache.slices_3.u_core.mshrCtl.u_core.mshrs[1].entry.u_core.release_period_valid_REG = u_g.inner_l2cache.slices_3.mshrCtl.mshrs_1.release_period_valid_REG;
    force u_i.inner_l2cache.slices_3.u_core.mshrCtl.u_core.mshrs[1].entry.u_core.REG = u_g.inner_l2cache.slices_3.mshrCtl.mshrs_1.REG;
    force u_i.inner_l2cache.slices_3.u_core.mshrCtl.u_core.mshrs[1].entry.u_core.REG_1 = u_g.inner_l2cache.slices_3.mshrCtl.mshrs_1.REG_1;
    force u_i.inner_l2cache.slices_3.u_core.mshrCtl.u_core.mshrs[1].entry.u_core.REG_2 = u_g.inner_l2cache.slices_3.mshrCtl.mshrs_1.REG_2;
    force u_i.inner_l2cache.slices_3.u_core.mshrCtl.u_core.mshrs[1].entry.u_core.REG_3 = u_g.inner_l2cache.slices_3.mshrCtl.mshrs_1.REG_3;
    force u_i.inner_l2cache.slices_3.u_core.mshrCtl.u_core.mshrs[2].entry.u_core.tgtid_rcompack = u_g.inner_l2cache.slices_3.mshrCtl.mshrs_2.tgtid_rcompack;
    force u_i.inner_l2cache.slices_3.u_core.mshrCtl.u_core.mshrs[2].entry.u_core.txnid_rcompack = u_g.inner_l2cache.slices_3.mshrCtl.mshrs_2.txnid_rcompack;
    force u_i.inner_l2cache.slices_3.u_core.mshrCtl.u_core.mshrs[2].entry.u_core.tgtid_wcompack = u_g.inner_l2cache.slices_3.mshrCtl.mshrs_2.tgtid_wcompack;
    force u_i.inner_l2cache.slices_3.u_core.mshrCtl.u_core.mshrs[2].entry.u_core.txnid_wcompack = u_g.inner_l2cache.slices_3.mshrCtl.mshrs_2.txnid_wcompack;
    force u_i.inner_l2cache.slices_3.u_core.mshrCtl.u_core.mshrs[2].entry.u_core.srcid_retryack = u_g.inner_l2cache.slices_3.mshrCtl.mshrs_2.srcid_retryack;
    force u_i.inner_l2cache.slices_3.u_core.mshrCtl.u_core.mshrs[2].entry.u_core.acquire_ts = u_g.inner_l2cache.slices_3.mshrCtl.mshrs_2.acquire_ts;
    force u_i.inner_l2cache.slices_3.u_core.mshrCtl.u_core.mshrs[2].entry.u_core.release_ts = u_g.inner_l2cache.slices_3.mshrCtl.mshrs_2.release_ts;
    force u_i.inner_l2cache.slices_3.u_core.mshrCtl.u_core.mshrs[2].entry.u_core.acquire_period_valid_REG = u_g.inner_l2cache.slices_3.mshrCtl.mshrs_2.acquire_period_valid_REG;
    force u_i.inner_l2cache.slices_3.u_core.mshrCtl.u_core.mshrs[2].entry.u_core.release_period_valid_REG = u_g.inner_l2cache.slices_3.mshrCtl.mshrs_2.release_period_valid_REG;
    force u_i.inner_l2cache.slices_3.u_core.mshrCtl.u_core.mshrs[2].entry.u_core.REG = u_g.inner_l2cache.slices_3.mshrCtl.mshrs_2.REG;
    force u_i.inner_l2cache.slices_3.u_core.mshrCtl.u_core.mshrs[2].entry.u_core.REG_1 = u_g.inner_l2cache.slices_3.mshrCtl.mshrs_2.REG_1;
    force u_i.inner_l2cache.slices_3.u_core.mshrCtl.u_core.mshrs[2].entry.u_core.REG_2 = u_g.inner_l2cache.slices_3.mshrCtl.mshrs_2.REG_2;
    force u_i.inner_l2cache.slices_3.u_core.mshrCtl.u_core.mshrs[2].entry.u_core.REG_3 = u_g.inner_l2cache.slices_3.mshrCtl.mshrs_2.REG_3;
    force u_i.inner_l2cache.slices_3.u_core.mshrCtl.u_core.mshrs[3].entry.u_core.tgtid_rcompack = u_g.inner_l2cache.slices_3.mshrCtl.mshrs_3.tgtid_rcompack;
    force u_i.inner_l2cache.slices_3.u_core.mshrCtl.u_core.mshrs[3].entry.u_core.txnid_rcompack = u_g.inner_l2cache.slices_3.mshrCtl.mshrs_3.txnid_rcompack;
    force u_i.inner_l2cache.slices_3.u_core.mshrCtl.u_core.mshrs[3].entry.u_core.tgtid_wcompack = u_g.inner_l2cache.slices_3.mshrCtl.mshrs_3.tgtid_wcompack;
    force u_i.inner_l2cache.slices_3.u_core.mshrCtl.u_core.mshrs[3].entry.u_core.txnid_wcompack = u_g.inner_l2cache.slices_3.mshrCtl.mshrs_3.txnid_wcompack;
    force u_i.inner_l2cache.slices_3.u_core.mshrCtl.u_core.mshrs[3].entry.u_core.srcid_retryack = u_g.inner_l2cache.slices_3.mshrCtl.mshrs_3.srcid_retryack;
    force u_i.inner_l2cache.slices_3.u_core.mshrCtl.u_core.mshrs[3].entry.u_core.acquire_ts = u_g.inner_l2cache.slices_3.mshrCtl.mshrs_3.acquire_ts;
    force u_i.inner_l2cache.slices_3.u_core.mshrCtl.u_core.mshrs[3].entry.u_core.release_ts = u_g.inner_l2cache.slices_3.mshrCtl.mshrs_3.release_ts;
    force u_i.inner_l2cache.slices_3.u_core.mshrCtl.u_core.mshrs[3].entry.u_core.acquire_period_valid_REG = u_g.inner_l2cache.slices_3.mshrCtl.mshrs_3.acquire_period_valid_REG;
    force u_i.inner_l2cache.slices_3.u_core.mshrCtl.u_core.mshrs[3].entry.u_core.release_period_valid_REG = u_g.inner_l2cache.slices_3.mshrCtl.mshrs_3.release_period_valid_REG;
    force u_i.inner_l2cache.slices_3.u_core.mshrCtl.u_core.mshrs[3].entry.u_core.REG = u_g.inner_l2cache.slices_3.mshrCtl.mshrs_3.REG;
    force u_i.inner_l2cache.slices_3.u_core.mshrCtl.u_core.mshrs[3].entry.u_core.REG_1 = u_g.inner_l2cache.slices_3.mshrCtl.mshrs_3.REG_1;
    force u_i.inner_l2cache.slices_3.u_core.mshrCtl.u_core.mshrs[3].entry.u_core.REG_2 = u_g.inner_l2cache.slices_3.mshrCtl.mshrs_3.REG_2;
    force u_i.inner_l2cache.slices_3.u_core.mshrCtl.u_core.mshrs[3].entry.u_core.REG_3 = u_g.inner_l2cache.slices_3.mshrCtl.mshrs_3.REG_3;
    force u_i.inner_l2cache.slices_3.u_core.mshrCtl.u_core.mshrs[4].entry.u_core.tgtid_rcompack = u_g.inner_l2cache.slices_3.mshrCtl.mshrs_4.tgtid_rcompack;
    force u_i.inner_l2cache.slices_3.u_core.mshrCtl.u_core.mshrs[4].entry.u_core.txnid_rcompack = u_g.inner_l2cache.slices_3.mshrCtl.mshrs_4.txnid_rcompack;
    force u_i.inner_l2cache.slices_3.u_core.mshrCtl.u_core.mshrs[4].entry.u_core.tgtid_wcompack = u_g.inner_l2cache.slices_3.mshrCtl.mshrs_4.tgtid_wcompack;
    force u_i.inner_l2cache.slices_3.u_core.mshrCtl.u_core.mshrs[4].entry.u_core.txnid_wcompack = u_g.inner_l2cache.slices_3.mshrCtl.mshrs_4.txnid_wcompack;
    force u_i.inner_l2cache.slices_3.u_core.mshrCtl.u_core.mshrs[4].entry.u_core.srcid_retryack = u_g.inner_l2cache.slices_3.mshrCtl.mshrs_4.srcid_retryack;
    force u_i.inner_l2cache.slices_3.u_core.mshrCtl.u_core.mshrs[4].entry.u_core.acquire_ts = u_g.inner_l2cache.slices_3.mshrCtl.mshrs_4.acquire_ts;
    force u_i.inner_l2cache.slices_3.u_core.mshrCtl.u_core.mshrs[4].entry.u_core.release_ts = u_g.inner_l2cache.slices_3.mshrCtl.mshrs_4.release_ts;
    force u_i.inner_l2cache.slices_3.u_core.mshrCtl.u_core.mshrs[4].entry.u_core.acquire_period_valid_REG = u_g.inner_l2cache.slices_3.mshrCtl.mshrs_4.acquire_period_valid_REG;
    force u_i.inner_l2cache.slices_3.u_core.mshrCtl.u_core.mshrs[4].entry.u_core.release_period_valid_REG = u_g.inner_l2cache.slices_3.mshrCtl.mshrs_4.release_period_valid_REG;
    force u_i.inner_l2cache.slices_3.u_core.mshrCtl.u_core.mshrs[4].entry.u_core.REG = u_g.inner_l2cache.slices_3.mshrCtl.mshrs_4.REG;
    force u_i.inner_l2cache.slices_3.u_core.mshrCtl.u_core.mshrs[4].entry.u_core.REG_1 = u_g.inner_l2cache.slices_3.mshrCtl.mshrs_4.REG_1;
    force u_i.inner_l2cache.slices_3.u_core.mshrCtl.u_core.mshrs[4].entry.u_core.REG_2 = u_g.inner_l2cache.slices_3.mshrCtl.mshrs_4.REG_2;
    force u_i.inner_l2cache.slices_3.u_core.mshrCtl.u_core.mshrs[4].entry.u_core.REG_3 = u_g.inner_l2cache.slices_3.mshrCtl.mshrs_4.REG_3;
    force u_i.inner_l2cache.slices_3.u_core.mshrCtl.u_core.mshrs[5].entry.u_core.tgtid_rcompack = u_g.inner_l2cache.slices_3.mshrCtl.mshrs_5.tgtid_rcompack;
    force u_i.inner_l2cache.slices_3.u_core.mshrCtl.u_core.mshrs[5].entry.u_core.txnid_rcompack = u_g.inner_l2cache.slices_3.mshrCtl.mshrs_5.txnid_rcompack;
    force u_i.inner_l2cache.slices_3.u_core.mshrCtl.u_core.mshrs[5].entry.u_core.tgtid_wcompack = u_g.inner_l2cache.slices_3.mshrCtl.mshrs_5.tgtid_wcompack;
    force u_i.inner_l2cache.slices_3.u_core.mshrCtl.u_core.mshrs[5].entry.u_core.txnid_wcompack = u_g.inner_l2cache.slices_3.mshrCtl.mshrs_5.txnid_wcompack;
    force u_i.inner_l2cache.slices_3.u_core.mshrCtl.u_core.mshrs[5].entry.u_core.srcid_retryack = u_g.inner_l2cache.slices_3.mshrCtl.mshrs_5.srcid_retryack;
    force u_i.inner_l2cache.slices_3.u_core.mshrCtl.u_core.mshrs[5].entry.u_core.acquire_ts = u_g.inner_l2cache.slices_3.mshrCtl.mshrs_5.acquire_ts;
    force u_i.inner_l2cache.slices_3.u_core.mshrCtl.u_core.mshrs[5].entry.u_core.release_ts = u_g.inner_l2cache.slices_3.mshrCtl.mshrs_5.release_ts;
    force u_i.inner_l2cache.slices_3.u_core.mshrCtl.u_core.mshrs[5].entry.u_core.acquire_period_valid_REG = u_g.inner_l2cache.slices_3.mshrCtl.mshrs_5.acquire_period_valid_REG;
    force u_i.inner_l2cache.slices_3.u_core.mshrCtl.u_core.mshrs[5].entry.u_core.release_period_valid_REG = u_g.inner_l2cache.slices_3.mshrCtl.mshrs_5.release_period_valid_REG;
    force u_i.inner_l2cache.slices_3.u_core.mshrCtl.u_core.mshrs[5].entry.u_core.REG = u_g.inner_l2cache.slices_3.mshrCtl.mshrs_5.REG;
    force u_i.inner_l2cache.slices_3.u_core.mshrCtl.u_core.mshrs[5].entry.u_core.REG_1 = u_g.inner_l2cache.slices_3.mshrCtl.mshrs_5.REG_1;
    force u_i.inner_l2cache.slices_3.u_core.mshrCtl.u_core.mshrs[5].entry.u_core.REG_2 = u_g.inner_l2cache.slices_3.mshrCtl.mshrs_5.REG_2;
    force u_i.inner_l2cache.slices_3.u_core.mshrCtl.u_core.mshrs[5].entry.u_core.REG_3 = u_g.inner_l2cache.slices_3.mshrCtl.mshrs_5.REG_3;
    force u_i.inner_l2cache.slices_3.u_core.mshrCtl.u_core.mshrs[6].entry.u_core.tgtid_rcompack = u_g.inner_l2cache.slices_3.mshrCtl.mshrs_6.tgtid_rcompack;
    force u_i.inner_l2cache.slices_3.u_core.mshrCtl.u_core.mshrs[6].entry.u_core.txnid_rcompack = u_g.inner_l2cache.slices_3.mshrCtl.mshrs_6.txnid_rcompack;
    force u_i.inner_l2cache.slices_3.u_core.mshrCtl.u_core.mshrs[6].entry.u_core.tgtid_wcompack = u_g.inner_l2cache.slices_3.mshrCtl.mshrs_6.tgtid_wcompack;
    force u_i.inner_l2cache.slices_3.u_core.mshrCtl.u_core.mshrs[6].entry.u_core.txnid_wcompack = u_g.inner_l2cache.slices_3.mshrCtl.mshrs_6.txnid_wcompack;
    force u_i.inner_l2cache.slices_3.u_core.mshrCtl.u_core.mshrs[6].entry.u_core.srcid_retryack = u_g.inner_l2cache.slices_3.mshrCtl.mshrs_6.srcid_retryack;
    force u_i.inner_l2cache.slices_3.u_core.mshrCtl.u_core.mshrs[6].entry.u_core.acquire_ts = u_g.inner_l2cache.slices_3.mshrCtl.mshrs_6.acquire_ts;
    force u_i.inner_l2cache.slices_3.u_core.mshrCtl.u_core.mshrs[6].entry.u_core.release_ts = u_g.inner_l2cache.slices_3.mshrCtl.mshrs_6.release_ts;
    force u_i.inner_l2cache.slices_3.u_core.mshrCtl.u_core.mshrs[6].entry.u_core.acquire_period_valid_REG = u_g.inner_l2cache.slices_3.mshrCtl.mshrs_6.acquire_period_valid_REG;
    force u_i.inner_l2cache.slices_3.u_core.mshrCtl.u_core.mshrs[6].entry.u_core.release_period_valid_REG = u_g.inner_l2cache.slices_3.mshrCtl.mshrs_6.release_period_valid_REG;
    force u_i.inner_l2cache.slices_3.u_core.mshrCtl.u_core.mshrs[6].entry.u_core.REG = u_g.inner_l2cache.slices_3.mshrCtl.mshrs_6.REG;
    force u_i.inner_l2cache.slices_3.u_core.mshrCtl.u_core.mshrs[6].entry.u_core.REG_1 = u_g.inner_l2cache.slices_3.mshrCtl.mshrs_6.REG_1;
    force u_i.inner_l2cache.slices_3.u_core.mshrCtl.u_core.mshrs[6].entry.u_core.REG_2 = u_g.inner_l2cache.slices_3.mshrCtl.mshrs_6.REG_2;
    force u_i.inner_l2cache.slices_3.u_core.mshrCtl.u_core.mshrs[6].entry.u_core.REG_3 = u_g.inner_l2cache.slices_3.mshrCtl.mshrs_6.REG_3;
    force u_i.inner_l2cache.slices_3.u_core.mshrCtl.u_core.mshrs[7].entry.u_core.tgtid_rcompack = u_g.inner_l2cache.slices_3.mshrCtl.mshrs_7.tgtid_rcompack;
    force u_i.inner_l2cache.slices_3.u_core.mshrCtl.u_core.mshrs[7].entry.u_core.txnid_rcompack = u_g.inner_l2cache.slices_3.mshrCtl.mshrs_7.txnid_rcompack;
    force u_i.inner_l2cache.slices_3.u_core.mshrCtl.u_core.mshrs[7].entry.u_core.tgtid_wcompack = u_g.inner_l2cache.slices_3.mshrCtl.mshrs_7.tgtid_wcompack;
    force u_i.inner_l2cache.slices_3.u_core.mshrCtl.u_core.mshrs[7].entry.u_core.txnid_wcompack = u_g.inner_l2cache.slices_3.mshrCtl.mshrs_7.txnid_wcompack;
    force u_i.inner_l2cache.slices_3.u_core.mshrCtl.u_core.mshrs[7].entry.u_core.srcid_retryack = u_g.inner_l2cache.slices_3.mshrCtl.mshrs_7.srcid_retryack;
    force u_i.inner_l2cache.slices_3.u_core.mshrCtl.u_core.mshrs[7].entry.u_core.acquire_ts = u_g.inner_l2cache.slices_3.mshrCtl.mshrs_7.acquire_ts;
    force u_i.inner_l2cache.slices_3.u_core.mshrCtl.u_core.mshrs[7].entry.u_core.release_ts = u_g.inner_l2cache.slices_3.mshrCtl.mshrs_7.release_ts;
    force u_i.inner_l2cache.slices_3.u_core.mshrCtl.u_core.mshrs[7].entry.u_core.acquire_period_valid_REG = u_g.inner_l2cache.slices_3.mshrCtl.mshrs_7.acquire_period_valid_REG;
    force u_i.inner_l2cache.slices_3.u_core.mshrCtl.u_core.mshrs[7].entry.u_core.release_period_valid_REG = u_g.inner_l2cache.slices_3.mshrCtl.mshrs_7.release_period_valid_REG;
    force u_i.inner_l2cache.slices_3.u_core.mshrCtl.u_core.mshrs[7].entry.u_core.REG = u_g.inner_l2cache.slices_3.mshrCtl.mshrs_7.REG;
    force u_i.inner_l2cache.slices_3.u_core.mshrCtl.u_core.mshrs[7].entry.u_core.REG_1 = u_g.inner_l2cache.slices_3.mshrCtl.mshrs_7.REG_1;
    force u_i.inner_l2cache.slices_3.u_core.mshrCtl.u_core.mshrs[7].entry.u_core.REG_2 = u_g.inner_l2cache.slices_3.mshrCtl.mshrs_7.REG_2;
    force u_i.inner_l2cache.slices_3.u_core.mshrCtl.u_core.mshrs[7].entry.u_core.REG_3 = u_g.inner_l2cache.slices_3.mshrCtl.mshrs_7.REG_3;
    force u_i.inner_l2cache.slices_3.u_core.mshrCtl.u_core.mshrs[8].entry.u_core.tgtid_rcompack = u_g.inner_l2cache.slices_3.mshrCtl.mshrs_8.tgtid_rcompack;
    force u_i.inner_l2cache.slices_3.u_core.mshrCtl.u_core.mshrs[8].entry.u_core.txnid_rcompack = u_g.inner_l2cache.slices_3.mshrCtl.mshrs_8.txnid_rcompack;
    force u_i.inner_l2cache.slices_3.u_core.mshrCtl.u_core.mshrs[8].entry.u_core.tgtid_wcompack = u_g.inner_l2cache.slices_3.mshrCtl.mshrs_8.tgtid_wcompack;
    force u_i.inner_l2cache.slices_3.u_core.mshrCtl.u_core.mshrs[8].entry.u_core.txnid_wcompack = u_g.inner_l2cache.slices_3.mshrCtl.mshrs_8.txnid_wcompack;
    force u_i.inner_l2cache.slices_3.u_core.mshrCtl.u_core.mshrs[8].entry.u_core.srcid_retryack = u_g.inner_l2cache.slices_3.mshrCtl.mshrs_8.srcid_retryack;
    force u_i.inner_l2cache.slices_3.u_core.mshrCtl.u_core.mshrs[8].entry.u_core.acquire_ts = u_g.inner_l2cache.slices_3.mshrCtl.mshrs_8.acquire_ts;
    force u_i.inner_l2cache.slices_3.u_core.mshrCtl.u_core.mshrs[8].entry.u_core.release_ts = u_g.inner_l2cache.slices_3.mshrCtl.mshrs_8.release_ts;
    force u_i.inner_l2cache.slices_3.u_core.mshrCtl.u_core.mshrs[8].entry.u_core.acquire_period_valid_REG = u_g.inner_l2cache.slices_3.mshrCtl.mshrs_8.acquire_period_valid_REG;
    force u_i.inner_l2cache.slices_3.u_core.mshrCtl.u_core.mshrs[8].entry.u_core.release_period_valid_REG = u_g.inner_l2cache.slices_3.mshrCtl.mshrs_8.release_period_valid_REG;
    force u_i.inner_l2cache.slices_3.u_core.mshrCtl.u_core.mshrs[8].entry.u_core.REG = u_g.inner_l2cache.slices_3.mshrCtl.mshrs_8.REG;
    force u_i.inner_l2cache.slices_3.u_core.mshrCtl.u_core.mshrs[8].entry.u_core.REG_1 = u_g.inner_l2cache.slices_3.mshrCtl.mshrs_8.REG_1;
    force u_i.inner_l2cache.slices_3.u_core.mshrCtl.u_core.mshrs[8].entry.u_core.REG_2 = u_g.inner_l2cache.slices_3.mshrCtl.mshrs_8.REG_2;
    force u_i.inner_l2cache.slices_3.u_core.mshrCtl.u_core.mshrs[8].entry.u_core.REG_3 = u_g.inner_l2cache.slices_3.mshrCtl.mshrs_8.REG_3;
    force u_i.inner_l2cache.slices_3.u_core.mshrCtl.u_core.mshrs[9].entry.u_core.tgtid_rcompack = u_g.inner_l2cache.slices_3.mshrCtl.mshrs_9.tgtid_rcompack;
    force u_i.inner_l2cache.slices_3.u_core.mshrCtl.u_core.mshrs[9].entry.u_core.txnid_rcompack = u_g.inner_l2cache.slices_3.mshrCtl.mshrs_9.txnid_rcompack;
    force u_i.inner_l2cache.slices_3.u_core.mshrCtl.u_core.mshrs[9].entry.u_core.tgtid_wcompack = u_g.inner_l2cache.slices_3.mshrCtl.mshrs_9.tgtid_wcompack;
    force u_i.inner_l2cache.slices_3.u_core.mshrCtl.u_core.mshrs[9].entry.u_core.txnid_wcompack = u_g.inner_l2cache.slices_3.mshrCtl.mshrs_9.txnid_wcompack;
    force u_i.inner_l2cache.slices_3.u_core.mshrCtl.u_core.mshrs[9].entry.u_core.srcid_retryack = u_g.inner_l2cache.slices_3.mshrCtl.mshrs_9.srcid_retryack;
    force u_i.inner_l2cache.slices_3.u_core.mshrCtl.u_core.mshrs[9].entry.u_core.acquire_ts = u_g.inner_l2cache.slices_3.mshrCtl.mshrs_9.acquire_ts;
    force u_i.inner_l2cache.slices_3.u_core.mshrCtl.u_core.mshrs[9].entry.u_core.release_ts = u_g.inner_l2cache.slices_3.mshrCtl.mshrs_9.release_ts;
    force u_i.inner_l2cache.slices_3.u_core.mshrCtl.u_core.mshrs[9].entry.u_core.acquire_period_valid_REG = u_g.inner_l2cache.slices_3.mshrCtl.mshrs_9.acquire_period_valid_REG;
    force u_i.inner_l2cache.slices_3.u_core.mshrCtl.u_core.mshrs[9].entry.u_core.release_period_valid_REG = u_g.inner_l2cache.slices_3.mshrCtl.mshrs_9.release_period_valid_REG;
    force u_i.inner_l2cache.slices_3.u_core.mshrCtl.u_core.mshrs[9].entry.u_core.REG = u_g.inner_l2cache.slices_3.mshrCtl.mshrs_9.REG;
    force u_i.inner_l2cache.slices_3.u_core.mshrCtl.u_core.mshrs[9].entry.u_core.REG_1 = u_g.inner_l2cache.slices_3.mshrCtl.mshrs_9.REG_1;
    force u_i.inner_l2cache.slices_3.u_core.mshrCtl.u_core.mshrs[9].entry.u_core.REG_2 = u_g.inner_l2cache.slices_3.mshrCtl.mshrs_9.REG_2;
    force u_i.inner_l2cache.slices_3.u_core.mshrCtl.u_core.mshrs[9].entry.u_core.REG_3 = u_g.inner_l2cache.slices_3.mshrCtl.mshrs_9.REG_3;
    force u_i.inner_l2cache.slices_3.u_core.mshrCtl.u_core.mshrs[10].entry.u_core.tgtid_rcompack = u_g.inner_l2cache.slices_3.mshrCtl.mshrs_10.tgtid_rcompack;
    force u_i.inner_l2cache.slices_3.u_core.mshrCtl.u_core.mshrs[10].entry.u_core.txnid_rcompack = u_g.inner_l2cache.slices_3.mshrCtl.mshrs_10.txnid_rcompack;
    force u_i.inner_l2cache.slices_3.u_core.mshrCtl.u_core.mshrs[10].entry.u_core.tgtid_wcompack = u_g.inner_l2cache.slices_3.mshrCtl.mshrs_10.tgtid_wcompack;
    force u_i.inner_l2cache.slices_3.u_core.mshrCtl.u_core.mshrs[10].entry.u_core.txnid_wcompack = u_g.inner_l2cache.slices_3.mshrCtl.mshrs_10.txnid_wcompack;
    force u_i.inner_l2cache.slices_3.u_core.mshrCtl.u_core.mshrs[10].entry.u_core.srcid_retryack = u_g.inner_l2cache.slices_3.mshrCtl.mshrs_10.srcid_retryack;
    force u_i.inner_l2cache.slices_3.u_core.mshrCtl.u_core.mshrs[10].entry.u_core.acquire_ts = u_g.inner_l2cache.slices_3.mshrCtl.mshrs_10.acquire_ts;
    force u_i.inner_l2cache.slices_3.u_core.mshrCtl.u_core.mshrs[10].entry.u_core.release_ts = u_g.inner_l2cache.slices_3.mshrCtl.mshrs_10.release_ts;
    force u_i.inner_l2cache.slices_3.u_core.mshrCtl.u_core.mshrs[10].entry.u_core.acquire_period_valid_REG = u_g.inner_l2cache.slices_3.mshrCtl.mshrs_10.acquire_period_valid_REG;
    force u_i.inner_l2cache.slices_3.u_core.mshrCtl.u_core.mshrs[10].entry.u_core.release_period_valid_REG = u_g.inner_l2cache.slices_3.mshrCtl.mshrs_10.release_period_valid_REG;
    force u_i.inner_l2cache.slices_3.u_core.mshrCtl.u_core.mshrs[10].entry.u_core.REG = u_g.inner_l2cache.slices_3.mshrCtl.mshrs_10.REG;
    force u_i.inner_l2cache.slices_3.u_core.mshrCtl.u_core.mshrs[10].entry.u_core.REG_1 = u_g.inner_l2cache.slices_3.mshrCtl.mshrs_10.REG_1;
    force u_i.inner_l2cache.slices_3.u_core.mshrCtl.u_core.mshrs[10].entry.u_core.REG_2 = u_g.inner_l2cache.slices_3.mshrCtl.mshrs_10.REG_2;
    force u_i.inner_l2cache.slices_3.u_core.mshrCtl.u_core.mshrs[10].entry.u_core.REG_3 = u_g.inner_l2cache.slices_3.mshrCtl.mshrs_10.REG_3;
    force u_i.inner_l2cache.slices_3.u_core.mshrCtl.u_core.mshrs[11].entry.u_core.tgtid_rcompack = u_g.inner_l2cache.slices_3.mshrCtl.mshrs_11.tgtid_rcompack;
    force u_i.inner_l2cache.slices_3.u_core.mshrCtl.u_core.mshrs[11].entry.u_core.txnid_rcompack = u_g.inner_l2cache.slices_3.mshrCtl.mshrs_11.txnid_rcompack;
    force u_i.inner_l2cache.slices_3.u_core.mshrCtl.u_core.mshrs[11].entry.u_core.tgtid_wcompack = u_g.inner_l2cache.slices_3.mshrCtl.mshrs_11.tgtid_wcompack;
    force u_i.inner_l2cache.slices_3.u_core.mshrCtl.u_core.mshrs[11].entry.u_core.txnid_wcompack = u_g.inner_l2cache.slices_3.mshrCtl.mshrs_11.txnid_wcompack;
    force u_i.inner_l2cache.slices_3.u_core.mshrCtl.u_core.mshrs[11].entry.u_core.srcid_retryack = u_g.inner_l2cache.slices_3.mshrCtl.mshrs_11.srcid_retryack;
    force u_i.inner_l2cache.slices_3.u_core.mshrCtl.u_core.mshrs[11].entry.u_core.acquire_ts = u_g.inner_l2cache.slices_3.mshrCtl.mshrs_11.acquire_ts;
    force u_i.inner_l2cache.slices_3.u_core.mshrCtl.u_core.mshrs[11].entry.u_core.release_ts = u_g.inner_l2cache.slices_3.mshrCtl.mshrs_11.release_ts;
    force u_i.inner_l2cache.slices_3.u_core.mshrCtl.u_core.mshrs[11].entry.u_core.acquire_period_valid_REG = u_g.inner_l2cache.slices_3.mshrCtl.mshrs_11.acquire_period_valid_REG;
    force u_i.inner_l2cache.slices_3.u_core.mshrCtl.u_core.mshrs[11].entry.u_core.release_period_valid_REG = u_g.inner_l2cache.slices_3.mshrCtl.mshrs_11.release_period_valid_REG;
    force u_i.inner_l2cache.slices_3.u_core.mshrCtl.u_core.mshrs[11].entry.u_core.REG = u_g.inner_l2cache.slices_3.mshrCtl.mshrs_11.REG;
    force u_i.inner_l2cache.slices_3.u_core.mshrCtl.u_core.mshrs[11].entry.u_core.REG_1 = u_g.inner_l2cache.slices_3.mshrCtl.mshrs_11.REG_1;
    force u_i.inner_l2cache.slices_3.u_core.mshrCtl.u_core.mshrs[11].entry.u_core.REG_2 = u_g.inner_l2cache.slices_3.mshrCtl.mshrs_11.REG_2;
    force u_i.inner_l2cache.slices_3.u_core.mshrCtl.u_core.mshrs[11].entry.u_core.REG_3 = u_g.inner_l2cache.slices_3.mshrCtl.mshrs_11.REG_3;
    force u_i.inner_l2cache.slices_3.u_core.mshrCtl.u_core.mshrs[12].entry.u_core.tgtid_rcompack = u_g.inner_l2cache.slices_3.mshrCtl.mshrs_12.tgtid_rcompack;
    force u_i.inner_l2cache.slices_3.u_core.mshrCtl.u_core.mshrs[12].entry.u_core.txnid_rcompack = u_g.inner_l2cache.slices_3.mshrCtl.mshrs_12.txnid_rcompack;
    force u_i.inner_l2cache.slices_3.u_core.mshrCtl.u_core.mshrs[12].entry.u_core.tgtid_wcompack = u_g.inner_l2cache.slices_3.mshrCtl.mshrs_12.tgtid_wcompack;
    force u_i.inner_l2cache.slices_3.u_core.mshrCtl.u_core.mshrs[12].entry.u_core.txnid_wcompack = u_g.inner_l2cache.slices_3.mshrCtl.mshrs_12.txnid_wcompack;
    force u_i.inner_l2cache.slices_3.u_core.mshrCtl.u_core.mshrs[12].entry.u_core.srcid_retryack = u_g.inner_l2cache.slices_3.mshrCtl.mshrs_12.srcid_retryack;
    force u_i.inner_l2cache.slices_3.u_core.mshrCtl.u_core.mshrs[12].entry.u_core.acquire_ts = u_g.inner_l2cache.slices_3.mshrCtl.mshrs_12.acquire_ts;
    force u_i.inner_l2cache.slices_3.u_core.mshrCtl.u_core.mshrs[12].entry.u_core.release_ts = u_g.inner_l2cache.slices_3.mshrCtl.mshrs_12.release_ts;
    force u_i.inner_l2cache.slices_3.u_core.mshrCtl.u_core.mshrs[12].entry.u_core.acquire_period_valid_REG = u_g.inner_l2cache.slices_3.mshrCtl.mshrs_12.acquire_period_valid_REG;
    force u_i.inner_l2cache.slices_3.u_core.mshrCtl.u_core.mshrs[12].entry.u_core.release_period_valid_REG = u_g.inner_l2cache.slices_3.mshrCtl.mshrs_12.release_period_valid_REG;
    force u_i.inner_l2cache.slices_3.u_core.mshrCtl.u_core.mshrs[12].entry.u_core.REG = u_g.inner_l2cache.slices_3.mshrCtl.mshrs_12.REG;
    force u_i.inner_l2cache.slices_3.u_core.mshrCtl.u_core.mshrs[12].entry.u_core.REG_1 = u_g.inner_l2cache.slices_3.mshrCtl.mshrs_12.REG_1;
    force u_i.inner_l2cache.slices_3.u_core.mshrCtl.u_core.mshrs[12].entry.u_core.REG_2 = u_g.inner_l2cache.slices_3.mshrCtl.mshrs_12.REG_2;
    force u_i.inner_l2cache.slices_3.u_core.mshrCtl.u_core.mshrs[12].entry.u_core.REG_3 = u_g.inner_l2cache.slices_3.mshrCtl.mshrs_12.REG_3;
    force u_i.inner_l2cache.slices_3.u_core.mshrCtl.u_core.mshrs[13].entry.u_core.tgtid_rcompack = u_g.inner_l2cache.slices_3.mshrCtl.mshrs_13.tgtid_rcompack;
    force u_i.inner_l2cache.slices_3.u_core.mshrCtl.u_core.mshrs[13].entry.u_core.txnid_rcompack = u_g.inner_l2cache.slices_3.mshrCtl.mshrs_13.txnid_rcompack;
    force u_i.inner_l2cache.slices_3.u_core.mshrCtl.u_core.mshrs[13].entry.u_core.tgtid_wcompack = u_g.inner_l2cache.slices_3.mshrCtl.mshrs_13.tgtid_wcompack;
    force u_i.inner_l2cache.slices_3.u_core.mshrCtl.u_core.mshrs[13].entry.u_core.txnid_wcompack = u_g.inner_l2cache.slices_3.mshrCtl.mshrs_13.txnid_wcompack;
    force u_i.inner_l2cache.slices_3.u_core.mshrCtl.u_core.mshrs[13].entry.u_core.srcid_retryack = u_g.inner_l2cache.slices_3.mshrCtl.mshrs_13.srcid_retryack;
    force u_i.inner_l2cache.slices_3.u_core.mshrCtl.u_core.mshrs[13].entry.u_core.acquire_ts = u_g.inner_l2cache.slices_3.mshrCtl.mshrs_13.acquire_ts;
    force u_i.inner_l2cache.slices_3.u_core.mshrCtl.u_core.mshrs[13].entry.u_core.release_ts = u_g.inner_l2cache.slices_3.mshrCtl.mshrs_13.release_ts;
    force u_i.inner_l2cache.slices_3.u_core.mshrCtl.u_core.mshrs[13].entry.u_core.acquire_period_valid_REG = u_g.inner_l2cache.slices_3.mshrCtl.mshrs_13.acquire_period_valid_REG;
    force u_i.inner_l2cache.slices_3.u_core.mshrCtl.u_core.mshrs[13].entry.u_core.release_period_valid_REG = u_g.inner_l2cache.slices_3.mshrCtl.mshrs_13.release_period_valid_REG;
    force u_i.inner_l2cache.slices_3.u_core.mshrCtl.u_core.mshrs[13].entry.u_core.REG = u_g.inner_l2cache.slices_3.mshrCtl.mshrs_13.REG;
    force u_i.inner_l2cache.slices_3.u_core.mshrCtl.u_core.mshrs[13].entry.u_core.REG_1 = u_g.inner_l2cache.slices_3.mshrCtl.mshrs_13.REG_1;
    force u_i.inner_l2cache.slices_3.u_core.mshrCtl.u_core.mshrs[13].entry.u_core.REG_2 = u_g.inner_l2cache.slices_3.mshrCtl.mshrs_13.REG_2;
    force u_i.inner_l2cache.slices_3.u_core.mshrCtl.u_core.mshrs[13].entry.u_core.REG_3 = u_g.inner_l2cache.slices_3.mshrCtl.mshrs_13.REG_3;
    force u_i.inner_l2cache.slices_3.u_core.mshrCtl.u_core.mshrs[14].entry.u_core.tgtid_rcompack = u_g.inner_l2cache.slices_3.mshrCtl.mshrs_14.tgtid_rcompack;
    force u_i.inner_l2cache.slices_3.u_core.mshrCtl.u_core.mshrs[14].entry.u_core.txnid_rcompack = u_g.inner_l2cache.slices_3.mshrCtl.mshrs_14.txnid_rcompack;
    force u_i.inner_l2cache.slices_3.u_core.mshrCtl.u_core.mshrs[14].entry.u_core.tgtid_wcompack = u_g.inner_l2cache.slices_3.mshrCtl.mshrs_14.tgtid_wcompack;
    force u_i.inner_l2cache.slices_3.u_core.mshrCtl.u_core.mshrs[14].entry.u_core.txnid_wcompack = u_g.inner_l2cache.slices_3.mshrCtl.mshrs_14.txnid_wcompack;
    force u_i.inner_l2cache.slices_3.u_core.mshrCtl.u_core.mshrs[14].entry.u_core.srcid_retryack = u_g.inner_l2cache.slices_3.mshrCtl.mshrs_14.srcid_retryack;
    force u_i.inner_l2cache.slices_3.u_core.mshrCtl.u_core.mshrs[14].entry.u_core.acquire_ts = u_g.inner_l2cache.slices_3.mshrCtl.mshrs_14.acquire_ts;
    force u_i.inner_l2cache.slices_3.u_core.mshrCtl.u_core.mshrs[14].entry.u_core.release_ts = u_g.inner_l2cache.slices_3.mshrCtl.mshrs_14.release_ts;
    force u_i.inner_l2cache.slices_3.u_core.mshrCtl.u_core.mshrs[14].entry.u_core.acquire_period_valid_REG = u_g.inner_l2cache.slices_3.mshrCtl.mshrs_14.acquire_period_valid_REG;
    force u_i.inner_l2cache.slices_3.u_core.mshrCtl.u_core.mshrs[14].entry.u_core.release_period_valid_REG = u_g.inner_l2cache.slices_3.mshrCtl.mshrs_14.release_period_valid_REG;
    force u_i.inner_l2cache.slices_3.u_core.mshrCtl.u_core.mshrs[14].entry.u_core.REG = u_g.inner_l2cache.slices_3.mshrCtl.mshrs_14.REG;
    force u_i.inner_l2cache.slices_3.u_core.mshrCtl.u_core.mshrs[14].entry.u_core.REG_1 = u_g.inner_l2cache.slices_3.mshrCtl.mshrs_14.REG_1;
    force u_i.inner_l2cache.slices_3.u_core.mshrCtl.u_core.mshrs[14].entry.u_core.REG_2 = u_g.inner_l2cache.slices_3.mshrCtl.mshrs_14.REG_2;
    force u_i.inner_l2cache.slices_3.u_core.mshrCtl.u_core.mshrs[14].entry.u_core.REG_3 = u_g.inner_l2cache.slices_3.mshrCtl.mshrs_14.REG_3;
    force u_i.inner_l2cache.slices_3.u_core.mshrCtl.u_core.mshrs[15].entry.u_core.tgtid_rcompack = u_g.inner_l2cache.slices_3.mshrCtl.mshrs_15.tgtid_rcompack;
    force u_i.inner_l2cache.slices_3.u_core.mshrCtl.u_core.mshrs[15].entry.u_core.txnid_rcompack = u_g.inner_l2cache.slices_3.mshrCtl.mshrs_15.txnid_rcompack;
    force u_i.inner_l2cache.slices_3.u_core.mshrCtl.u_core.mshrs[15].entry.u_core.tgtid_wcompack = u_g.inner_l2cache.slices_3.mshrCtl.mshrs_15.tgtid_wcompack;
    force u_i.inner_l2cache.slices_3.u_core.mshrCtl.u_core.mshrs[15].entry.u_core.txnid_wcompack = u_g.inner_l2cache.slices_3.mshrCtl.mshrs_15.txnid_wcompack;
    force u_i.inner_l2cache.slices_3.u_core.mshrCtl.u_core.mshrs[15].entry.u_core.srcid_retryack = u_g.inner_l2cache.slices_3.mshrCtl.mshrs_15.srcid_retryack;
    force u_i.inner_l2cache.slices_3.u_core.mshrCtl.u_core.mshrs[15].entry.u_core.acquire_ts = u_g.inner_l2cache.slices_3.mshrCtl.mshrs_15.acquire_ts;
    force u_i.inner_l2cache.slices_3.u_core.mshrCtl.u_core.mshrs[15].entry.u_core.release_ts = u_g.inner_l2cache.slices_3.mshrCtl.mshrs_15.release_ts;
    force u_i.inner_l2cache.slices_3.u_core.mshrCtl.u_core.mshrs[15].entry.u_core.acquire_period_valid_REG = u_g.inner_l2cache.slices_3.mshrCtl.mshrs_15.acquire_period_valid_REG;
    force u_i.inner_l2cache.slices_3.u_core.mshrCtl.u_core.mshrs[15].entry.u_core.release_period_valid_REG = u_g.inner_l2cache.slices_3.mshrCtl.mshrs_15.release_period_valid_REG;
    force u_i.inner_l2cache.slices_3.u_core.mshrCtl.u_core.mshrs[15].entry.u_core.REG = u_g.inner_l2cache.slices_3.mshrCtl.mshrs_15.REG;
    force u_i.inner_l2cache.slices_3.u_core.mshrCtl.u_core.mshrs[15].entry.u_core.REG_1 = u_g.inner_l2cache.slices_3.mshrCtl.mshrs_15.REG_1;
    force u_i.inner_l2cache.slices_3.u_core.mshrCtl.u_core.mshrs[15].entry.u_core.REG_2 = u_g.inner_l2cache.slices_3.mshrCtl.mshrs_15.REG_2;
    force u_i.inner_l2cache.slices_3.u_core.mshrCtl.u_core.mshrs[15].entry.u_core.REG_3 = u_g.inner_l2cache.slices_3.mshrCtl.mshrs_15.REG_3;
    force u_i.inner_l2cache.slices_3.u_core.mshrCtl.u_core.io_perf_0_value_REG = u_g.inner_l2cache.slices_3.mshrCtl.io_perf_0_value_REG;
    force u_i.inner_l2cache.slices_3.u_core.mshrCtl.u_core.io_perf_0_value_REG_1 = u_g.inner_l2cache.slices_3.mshrCtl.io_perf_0_value_REG_1;
    force u_i.inner_l2cache.slices_3.u_core.mshrCtl.u_core.io_perf_1_value_REG = u_g.inner_l2cache.slices_3.mshrCtl.io_perf_1_value_REG;
    force u_i.inner_l2cache.slices_3.u_core.mshrCtl.u_core.io_perf_1_value_REG_1 = u_g.inner_l2cache.slices_3.mshrCtl.io_perf_1_value_REG_1;
    force u_i.inner_l2cache.slices_3.u_core.mshrCtl.u_core.io_perf_3_value_REG = u_g.inner_l2cache.slices_3.mshrCtl.io_perf_3_value_REG;
    force u_i.inner_l2cache.slices_3.u_core.mshrCtl.u_core.io_perf_3_value_REG_1 = u_g.inner_l2cache.slices_3.mshrCtl.io_perf_3_value_REG_1;
    force u_i.inner_l2cache.slices_3.u_core.mshrCtl.u_core.REG = u_g.inner_l2cache.slices_3.mshrCtl.REG;
    force u_i.inner_l2cache.slices_3.u_core.mainPipe.u_core.data_s4 = u_g.inner_l2cache.slices_3.mainPipe.data_s4;
    force u_i.inner_l2cache.slices_3.u_core.mainPipe.u_core.data_s5 = u_g.inner_l2cache.slices_3.mainPipe.data_s5;
    force u_i.inner_l2cache.slices_3.u_core.mainPipe.u_core.s3DropValid_d1 = u_g.inner_l2cache.slices_3.mainPipe.REG;
    force u_i.inner_l2cache.slices_3.u_core.mainPipe.u_core.reqDrop_s3_d1 = u_g.inner_l2cache.slices_3.mainPipe.reqDropped_s5_REG;
    force u_i.inner_l2cache.slices_3.u_core.mainPipe.u_core.reqDrop_s3_d2 = u_g.inner_l2cache.slices_3.mainPipe.reqDropped_s5_REG_1;
    force u_i.inner_l2cache.slices_3.u_core.mainPipe.u_core.reqDrop_s4_d1 = u_g.inner_l2cache.slices_3.mainPipe.reqDropped_s5_REG_2;
    u_i.inner_l2cache.slices_3.u_core.mainPipe.customL1Hint.hintQueue.ram_ext.Memory = u_g.inner_l2cache.slices_3.mainPipe.customL1Hint.hintQueue.ram_ext.Memory;
    u_i.inner_l2cache.slices_3.u_core.mainPipe.customL1Hint.hint_s1Queue.ram_ext.Memory = u_g.inner_l2cache.slices_3.mainPipe.customL1Hint.hint_s1Queue.ram_ext.Memory;
    force u_i.inner_l2cache.slices_3.u_core.mainPipe.u_core.perf_d1[0] = u_g.inner_l2cache.slices_3.mainPipe.io_perf_0_value_REG;
    force u_i.inner_l2cache.slices_3.u_core.mainPipe.u_core.perf[0] = u_g.inner_l2cache.slices_3.mainPipe.io_perf_0_value_REG_1;
    force u_i.inner_l2cache.slices_3.u_core.mainPipe.u_core.perf_d1[1] = u_g.inner_l2cache.slices_3.mainPipe.io_perf_1_value_REG;
    force u_i.inner_l2cache.slices_3.u_core.mainPipe.u_core.perf[1] = u_g.inner_l2cache.slices_3.mainPipe.io_perf_1_value_REG_1;
    force u_i.inner_l2cache.slices_3.u_core.mainPipe.u_core.perf_d1[2] = u_g.inner_l2cache.slices_3.mainPipe.io_perf_2_value_REG;
    force u_i.inner_l2cache.slices_3.u_core.mainPipe.u_core.perf[2] = u_g.inner_l2cache.slices_3.mainPipe.io_perf_2_value_REG_1;
    force u_i.inner_l2cache.slices_3.u_core.mainPipe.u_core.perf_d1[3] = u_g.inner_l2cache.slices_3.mainPipe.io_perf_3_value_REG;
    force u_i.inner_l2cache.slices_3.u_core.mainPipe.u_core.perf[3] = u_g.inner_l2cache.slices_3.mainPipe.io_perf_3_value_REG_1;
    force u_i.inner_l2cache.slices_3.u_core.mainPipe.u_core.perf_d1[4] = u_g.inner_l2cache.slices_3.mainPipe.io_perf_4_value_REG;
    force u_i.inner_l2cache.slices_3.u_core.mainPipe.u_core.perf[4] = u_g.inner_l2cache.slices_3.mainPipe.io_perf_4_value_REG_1;
    force u_i.inner_l2cache.slices_3.u_core.mainPipe.u_core.perf_d1[5] = u_g.inner_l2cache.slices_3.mainPipe.io_perf_5_value_REG;
    force u_i.inner_l2cache.slices_3.u_core.mainPipe.u_core.perf[5] = u_g.inner_l2cache.slices_3.mainPipe.io_perf_5_value_REG_1;
    force u_i.inner_l2cache.slices_3.u_core.mainPipe.u_core.perf_d1[6] = u_g.inner_l2cache.slices_3.mainPipe.io_perf_6_value_REG;
    force u_i.inner_l2cache.slices_3.u_core.mainPipe.u_core.perf[6] = u_g.inner_l2cache.slices_3.mainPipe.io_perf_6_value_REG_1;
    force u_i.inner_l2cache.slices_3.u_core.mainPipe.u_core.perf_d1[7] = u_g.inner_l2cache.slices_3.mainPipe.io_perf_7_value_REG;
    force u_i.inner_l2cache.slices_3.u_core.mainPipe.u_core.perf[7] = u_g.inner_l2cache.slices_3.mainPipe.io_perf_7_value_REG_1;
    force u_i.inner_l2cache.slices_3.u_core.mainPipe.u_core.perf_d1[8] = u_g.inner_l2cache.slices_3.mainPipe.io_perf_8_value_REG;
    force u_i.inner_l2cache.slices_3.u_core.mainPipe.u_core.perf[8] = u_g.inner_l2cache.slices_3.mainPipe.io_perf_8_value_REG_1;
    force u_i.inner_l2cache.slices_3.u_core.mainPipe.u_core.perf_d1[9] = u_g.inner_l2cache.slices_3.mainPipe.io_perf_9_value_REG;
    force u_i.inner_l2cache.slices_3.u_core.mainPipe.u_core.perf[9] = u_g.inner_l2cache.slices_3.mainPipe.io_perf_9_value_REG_1;
    force u_i.inner_l2cache.slices_3.u_core.mainPipe.u_core.perf_d1[10] = u_g.inner_l2cache.slices_3.mainPipe.io_perf_10_value_REG;
    force u_i.inner_l2cache.slices_3.u_core.mainPipe.u_core.perf[10] = u_g.inner_l2cache.slices_3.mainPipe.io_perf_10_value_REG_1;
    force u_i.inner_l2cache.slices_3.u_core.mainPipe.u_core.perf_d1[11] = u_g.inner_l2cache.slices_3.mainPipe.io_perf_11_value_REG;
    force u_i.inner_l2cache.slices_3.u_core.mainPipe.u_core.perf[11] = u_g.inner_l2cache.slices_3.mainPipe.io_perf_11_value_REG_1;
    force u_i.inner_l2cache.slices_3.u_core.mainPipe.u_core.perf_d1[12] = u_g.inner_l2cache.slices_3.mainPipe.io_perf_12_value_REG;
    force u_i.inner_l2cache.slices_3.u_core.mainPipe.u_core.perf[12] = u_g.inner_l2cache.slices_3.mainPipe.io_perf_12_value_REG_1;
    u_i.inner_l2cache.slices_3.u_core.grantBuf.grantQueue.ram_ext.Memory = u_g.inner_l2cache.slices_3.grantBuf.grantQueue.ram_ext.Memory;
    u_i.inner_l2cache.slices_3.u_core.grantBuf.grantQueueData0.ram_data_data_ext.Memory = u_g.inner_l2cache.slices_3.grantBuf.grantQueueData0.ram_data_data_ext.Memory;
    u_i.inner_l2cache.slices_3.u_core.grantBuf.grantQueueData1.ram_data_data_ext.Memory = u_g.inner_l2cache.slices_3.grantBuf.grantQueueData1.ram_data_data_ext.Memory;
    u_i.inner_l2cache.slices_3.u_core.grantBuf.pftRespQueue.ram_ext.Memory = u_g.inner_l2cache.slices_3.grantBuf.pftRespQueue.ram_ext.Memory;
    force u_i.inner_l2cache.slices_3.u_core.grantBuf.u_core.validPrev[0] = u_g.inner_l2cache.slices_3.grantBuf.REG;
    force u_i.inner_l2cache.slices_3.u_core.grantBuf.u_core.histValidPrev[0] = u_g.inner_l2cache.slices_3.grantBuf.enable_REG;
    force u_i.inner_l2cache.slices_3.u_core.grantBuf.u_core.validPrev[1] = u_g.inner_l2cache.slices_3.grantBuf.REG_1;
    force u_i.inner_l2cache.slices_3.u_core.grantBuf.u_core.histValidPrev[1] = u_g.inner_l2cache.slices_3.grantBuf.enable_REG_1;
    force u_i.inner_l2cache.slices_3.u_core.grantBuf.u_core.validPrev[2] = u_g.inner_l2cache.slices_3.grantBuf.REG_2;
    force u_i.inner_l2cache.slices_3.u_core.grantBuf.u_core.histValidPrev[2] = u_g.inner_l2cache.slices_3.grantBuf.enable_REG_2;
    force u_i.inner_l2cache.slices_3.u_core.grantBuf.u_core.validPrev[3] = u_g.inner_l2cache.slices_3.grantBuf.REG_3;
    force u_i.inner_l2cache.slices_3.u_core.grantBuf.u_core.histValidPrev[3] = u_g.inner_l2cache.slices_3.grantBuf.enable_REG_3;
    force u_i.inner_l2cache.slices_3.u_core.grantBuf.u_core.validPrev[4] = u_g.inner_l2cache.slices_3.grantBuf.REG_4;
    force u_i.inner_l2cache.slices_3.u_core.grantBuf.u_core.histValidPrev[4] = u_g.inner_l2cache.slices_3.grantBuf.enable_REG_4;
    force u_i.inner_l2cache.slices_3.u_core.grantBuf.u_core.validPrev[5] = u_g.inner_l2cache.slices_3.grantBuf.REG_5;
    force u_i.inner_l2cache.slices_3.u_core.grantBuf.u_core.histValidPrev[5] = u_g.inner_l2cache.slices_3.grantBuf.enable_REG_5;
    force u_i.inner_l2cache.slices_3.u_core.grantBuf.u_core.validPrev[6] = u_g.inner_l2cache.slices_3.grantBuf.REG_6;
    force u_i.inner_l2cache.slices_3.u_core.grantBuf.u_core.histValidPrev[6] = u_g.inner_l2cache.slices_3.grantBuf.enable_REG_6;
    force u_i.inner_l2cache.slices_3.u_core.grantBuf.u_core.validPrev[7] = u_g.inner_l2cache.slices_3.grantBuf.REG_7;
    force u_i.inner_l2cache.slices_3.u_core.grantBuf.u_core.histValidPrev[7] = u_g.inner_l2cache.slices_3.grantBuf.enable_REG_7;
    force u_i.inner_l2cache.slices_3.u_core.grantBuf.u_core.validPrev[8] = u_g.inner_l2cache.slices_3.grantBuf.REG_8;
    force u_i.inner_l2cache.slices_3.u_core.grantBuf.u_core.histValidPrev[8] = u_g.inner_l2cache.slices_3.grantBuf.enable_REG_8;
    force u_i.inner_l2cache.slices_3.u_core.grantBuf.u_core.validPrev[9] = u_g.inner_l2cache.slices_3.grantBuf.REG_9;
    force u_i.inner_l2cache.slices_3.u_core.grantBuf.u_core.histValidPrev[9] = u_g.inner_l2cache.slices_3.grantBuf.enable_REG_9;
    force u_i.inner_l2cache.slices_3.u_core.grantBuf.u_core.validPrev[10] = u_g.inner_l2cache.slices_3.grantBuf.REG_10;
    force u_i.inner_l2cache.slices_3.u_core.grantBuf.u_core.histValidPrev[10] = u_g.inner_l2cache.slices_3.grantBuf.enable_REG_10;
    force u_i.inner_l2cache.slices_3.u_core.grantBuf.u_core.validPrev[11] = u_g.inner_l2cache.slices_3.grantBuf.REG_11;
    force u_i.inner_l2cache.slices_3.u_core.grantBuf.u_core.histValidPrev[11] = u_g.inner_l2cache.slices_3.grantBuf.enable_REG_11;
    force u_i.inner_l2cache.slices_3.u_core.grantBuf.u_core.validPrev[12] = u_g.inner_l2cache.slices_3.grantBuf.REG_12;
    force u_i.inner_l2cache.slices_3.u_core.grantBuf.u_core.histValidPrev[12] = u_g.inner_l2cache.slices_3.grantBuf.enable_REG_12;
    force u_i.inner_l2cache.slices_3.u_core.grantBuf.u_core.validPrev[13] = u_g.inner_l2cache.slices_3.grantBuf.REG_13;
    force u_i.inner_l2cache.slices_3.u_core.grantBuf.u_core.histValidPrev[13] = u_g.inner_l2cache.slices_3.grantBuf.enable_REG_13;
    force u_i.inner_l2cache.slices_3.u_core.grantBuf.u_core.validPrev[14] = u_g.inner_l2cache.slices_3.grantBuf.REG_14;
    force u_i.inner_l2cache.slices_3.u_core.grantBuf.u_core.histValidPrev[14] = u_g.inner_l2cache.slices_3.grantBuf.enable_REG_14;
    force u_i.inner_l2cache.slices_3.u_core.grantBuf.u_core.validPrev[15] = u_g.inner_l2cache.slices_3.grantBuf.REG_15;
    force u_i.inner_l2cache.slices_3.u_core.grantBuf.u_core.histValidPrev[15] = u_g.inner_l2cache.slices_3.grantBuf.enable_REG_15;
    u_i.inner_l2cache.slices_3.u_core.rxsnp.queue.ram_ext.Memory = u_g.inner_l2cache.slices_3.rxsnp.queue.ram_ext.Memory;
    force u_i.inner_l2cache.slices_3.u_core.rxsnp.u_core.replPrevForBlock[0] = u_g.inner_l2cache.slices_3.rxsnp.replaceBlockSnpMask_REG;
    force u_i.inner_l2cache.slices_3.u_core.rxsnp.u_core.replPrevForNest[0] = u_g.inner_l2cache.slices_3.rxsnp.replaceNestSnpMask_REG;
    force u_i.inner_l2cache.slices_3.u_core.rxsnp.u_core.replPrevForBlock[1] = u_g.inner_l2cache.slices_3.rxsnp.replaceBlockSnpMask_REG_1;
    force u_i.inner_l2cache.slices_3.u_core.rxsnp.u_core.replPrevForNest[1] = u_g.inner_l2cache.slices_3.rxsnp.replaceNestSnpMask_REG_1;
    force u_i.inner_l2cache.slices_3.u_core.rxsnp.u_core.replPrevForBlock[2] = u_g.inner_l2cache.slices_3.rxsnp.replaceBlockSnpMask_REG_2;
    force u_i.inner_l2cache.slices_3.u_core.rxsnp.u_core.replPrevForNest[2] = u_g.inner_l2cache.slices_3.rxsnp.replaceNestSnpMask_REG_2;
    force u_i.inner_l2cache.slices_3.u_core.rxsnp.u_core.replPrevForBlock[3] = u_g.inner_l2cache.slices_3.rxsnp.replaceBlockSnpMask_REG_3;
    force u_i.inner_l2cache.slices_3.u_core.rxsnp.u_core.replPrevForNest[3] = u_g.inner_l2cache.slices_3.rxsnp.replaceNestSnpMask_REG_3;
    force u_i.inner_l2cache.slices_3.u_core.rxsnp.u_core.replPrevForBlock[4] = u_g.inner_l2cache.slices_3.rxsnp.replaceBlockSnpMask_REG_4;
    force u_i.inner_l2cache.slices_3.u_core.rxsnp.u_core.replPrevForNest[4] = u_g.inner_l2cache.slices_3.rxsnp.replaceNestSnpMask_REG_4;
    force u_i.inner_l2cache.slices_3.u_core.rxsnp.u_core.replPrevForBlock[5] = u_g.inner_l2cache.slices_3.rxsnp.replaceBlockSnpMask_REG_5;
    force u_i.inner_l2cache.slices_3.u_core.rxsnp.u_core.replPrevForNest[5] = u_g.inner_l2cache.slices_3.rxsnp.replaceNestSnpMask_REG_5;
    force u_i.inner_l2cache.slices_3.u_core.rxsnp.u_core.replPrevForBlock[6] = u_g.inner_l2cache.slices_3.rxsnp.replaceBlockSnpMask_REG_6;
    force u_i.inner_l2cache.slices_3.u_core.rxsnp.u_core.replPrevForNest[6] = u_g.inner_l2cache.slices_3.rxsnp.replaceNestSnpMask_REG_6;
    force u_i.inner_l2cache.slices_3.u_core.rxsnp.u_core.replPrevForBlock[7] = u_g.inner_l2cache.slices_3.rxsnp.replaceBlockSnpMask_REG_7;
    force u_i.inner_l2cache.slices_3.u_core.rxsnp.u_core.replPrevForNest[7] = u_g.inner_l2cache.slices_3.rxsnp.replaceNestSnpMask_REG_7;
    force u_i.inner_l2cache.slices_3.u_core.rxsnp.u_core.replPrevForBlock[8] = u_g.inner_l2cache.slices_3.rxsnp.replaceBlockSnpMask_REG_8;
    force u_i.inner_l2cache.slices_3.u_core.rxsnp.u_core.replPrevForNest[8] = u_g.inner_l2cache.slices_3.rxsnp.replaceNestSnpMask_REG_8;
    force u_i.inner_l2cache.slices_3.u_core.rxsnp.u_core.replPrevForBlock[9] = u_g.inner_l2cache.slices_3.rxsnp.replaceBlockSnpMask_REG_9;
    force u_i.inner_l2cache.slices_3.u_core.rxsnp.u_core.replPrevForNest[9] = u_g.inner_l2cache.slices_3.rxsnp.replaceNestSnpMask_REG_9;
    force u_i.inner_l2cache.slices_3.u_core.rxsnp.u_core.replPrevForBlock[10] = u_g.inner_l2cache.slices_3.rxsnp.replaceBlockSnpMask_REG_10;
    force u_i.inner_l2cache.slices_3.u_core.rxsnp.u_core.replPrevForNest[10] = u_g.inner_l2cache.slices_3.rxsnp.replaceNestSnpMask_REG_10;
    force u_i.inner_l2cache.slices_3.u_core.rxsnp.u_core.replPrevForBlock[11] = u_g.inner_l2cache.slices_3.rxsnp.replaceBlockSnpMask_REG_11;
    force u_i.inner_l2cache.slices_3.u_core.rxsnp.u_core.replPrevForNest[11] = u_g.inner_l2cache.slices_3.rxsnp.replaceNestSnpMask_REG_11;
    force u_i.inner_l2cache.slices_3.u_core.rxsnp.u_core.replPrevForBlock[12] = u_g.inner_l2cache.slices_3.rxsnp.replaceBlockSnpMask_REG_12;
    force u_i.inner_l2cache.slices_3.u_core.rxsnp.u_core.replPrevForNest[12] = u_g.inner_l2cache.slices_3.rxsnp.replaceNestSnpMask_REG_12;
    force u_i.inner_l2cache.slices_3.u_core.rxsnp.u_core.replPrevForBlock[13] = u_g.inner_l2cache.slices_3.rxsnp.replaceBlockSnpMask_REG_13;
    force u_i.inner_l2cache.slices_3.u_core.rxsnp.u_core.replPrevForNest[13] = u_g.inner_l2cache.slices_3.rxsnp.replaceNestSnpMask_REG_13;
    force u_i.inner_l2cache.slices_3.u_core.rxsnp.u_core.replPrevForBlock[14] = u_g.inner_l2cache.slices_3.rxsnp.replaceBlockSnpMask_REG_14;
    force u_i.inner_l2cache.slices_3.u_core.rxsnp.u_core.replPrevForNest[14] = u_g.inner_l2cache.slices_3.rxsnp.replaceNestSnpMask_REG_14;
    force u_i.inner_l2cache.slices_3.u_core.rxsnp.u_core.replPrevForBlock[15] = u_g.inner_l2cache.slices_3.rxsnp.replaceBlockSnpMask_REG_15;
    force u_i.inner_l2cache.slices_3.u_core.rxsnp.u_core.replPrevForNest[15] = u_g.inner_l2cache.slices_3.rxsnp.replaceNestSnpMask_REG_15;
    force u_i.inner_l2cache.slices_3.u_core.reqBuf.chosenQ.u_core.ram = u_g.inner_l2cache.slices_3.reqBuf.chosenQ.ram;
    force u_i.inner_l2cache.slices_3.u_core.reqBuf.u_core.hitPfPrev_set = u_g.inner_l2cache.slices_3.reqBuf.io_hasHitPfInMSHR_valid_REG_set;
    force u_i.inner_l2cache.slices_3.u_core.reqBuf.u_core.hitPfPrev_tag = u_g.inner_l2cache.slices_3.reqBuf.io_hasHitPfInMSHR_valid_REG_tag;
    force u_i.inner_l2cache.slices_3.u_core.reqBuf.u_core.mergeAPrev_set = u_g.inner_l2cache.slices_3.reqBuf.io_hasMergeA_REG_set;
    force u_i.inner_l2cache.slices_3.u_core.reqBuf.u_core.mergeAPrev_tag = u_g.inner_l2cache.slices_3.reqBuf.io_hasMergeA_REG_tag;
    force u_i.inner_l2cache.slices_3.u_core.reqBuf.u_core.sameSetS3Valid[0] = u_g.inner_l2cache.slices_3.reqBuf.canFlow_sameSet_s3_REG;
    force u_i.inner_l2cache.slices_3.u_core.reqBuf.u_core.sameSetS3Set[0] = u_g.inner_l2cache.slices_3.reqBuf.canFlow_sameSet_s3_r;
    force u_i.inner_l2cache.slices_3.u_core.reqBuf.u_core.sameSetS3Valid[1] = u_g.inner_l2cache.slices_3.reqBuf.buffer_rdy_sameSet_s3_REG;
    force u_i.inner_l2cache.slices_3.u_core.reqBuf.u_core.sameSetS3Set[1] = u_g.inner_l2cache.slices_3.reqBuf.buffer_rdy_sameSet_s3_r;
    force u_i.inner_l2cache.slices_3.u_core.reqBuf.u_core.sameSetS3Valid[2] = u_g.inner_l2cache.slices_3.reqBuf.buffer_0_rdy_sameSet_s3_REG;
    force u_i.inner_l2cache.slices_3.u_core.reqBuf.u_core.sameSetS3Set[2] = u_g.inner_l2cache.slices_3.reqBuf.buffer_0_rdy_sameSet_s3_r;
    force u_i.inner_l2cache.slices_3.u_core.reqBuf.u_core.sameSetS3Valid[3] = u_g.inner_l2cache.slices_3.reqBuf.buffer_1_rdy_sameSet_s3_REG;
    force u_i.inner_l2cache.slices_3.u_core.reqBuf.u_core.sameSetS3Set[3] = u_g.inner_l2cache.slices_3.reqBuf.buffer_1_rdy_sameSet_s3_r;
    force u_i.inner_l2cache.slices_3.u_core.reqBuf.u_core.sameSetS3Valid[4] = u_g.inner_l2cache.slices_3.reqBuf.buffer_2_rdy_sameSet_s3_REG;
    force u_i.inner_l2cache.slices_3.u_core.reqBuf.u_core.sameSetS3Set[4] = u_g.inner_l2cache.slices_3.reqBuf.buffer_2_rdy_sameSet_s3_r;
    force u_i.inner_l2cache.slices_3.u_core.reqBuf.u_core.sameSetS3Valid[5] = u_g.inner_l2cache.slices_3.reqBuf.buffer_3_rdy_sameSet_s3_REG;
    force u_i.inner_l2cache.slices_3.u_core.reqBuf.u_core.sameSetS3Set[5] = u_g.inner_l2cache.slices_3.reqBuf.buffer_3_rdy_sameSet_s3_r;
    force u_i.inner_l2cache.slices_3.u_core.sinkC.u_core.bufRespStage[0] = u_g.inner_l2cache.slices_3.sinkC.r_0;
    force u_i.inner_l2cache.slices_3.u_core.sinkC.u_core.bufRespStage[1] = u_g.inner_l2cache.slices_3.sinkC.r_1;
    force u_i.inner_l2cache.slices_3.u_core.sinkC.u_core.bufRespOut[0] = u_g.inner_l2cache.slices_3.sinkC.REG_0;
    force u_i.inner_l2cache.slices_3.u_core.sinkC.u_core.bufRespOut[1] = u_g.inner_l2cache.slices_3.sinkC.REG_1;
    force u_i.inner_l2cache.slices_3.u_core.sinkC.u_core.refillIdReg = u_g.inner_l2cache.slices_3.sinkC.io_refillBufWrite_bits_id_REG;
    force u_i.inner_l2cache.slices_3.u_core.sinkC.u_core.refillBufIdxReg = u_g.inner_l2cache.slices_3.sinkC.io_refillBufWrite_bits_data_data_REG;
    force u_i.inner_l2cache.slices_3.u_core.sinkC.u_core.taskFirePrev = u_g.inner_l2cache.slices_3.sinkC.REG_1_0;
    force u_i.inner_l2cache.slices_3.u_core.sinkC.u_core.taskBufIdxPrev = u_g.inner_l2cache.slices_3.sinkC.REG_2;
    force u_i.inner_l2cache.slices_3.u_core.reqArb.u_core.ds_mcp2_stall = u_g.inner_l2cache.slices_3.reqArb.ds_mcp2_stall;
    force u_i.inner_l2cache.slices_3.u_core.refillBuf.u_core.buffer[0][0] = u_g.inner_l2cache.slices_3.refillBuf.buffer_0_0;
    force u_i.inner_l2cache.slices_3.u_core.refillBuf.u_core.buffer[0][1] = u_g.inner_l2cache.slices_3.refillBuf.buffer_0_1;
    force u_i.inner_l2cache.slices_3.u_core.refillBuf.u_core.buffer[1][0] = u_g.inner_l2cache.slices_3.refillBuf.buffer_1_0;
    force u_i.inner_l2cache.slices_3.u_core.refillBuf.u_core.buffer[1][1] = u_g.inner_l2cache.slices_3.refillBuf.buffer_1_1;
    force u_i.inner_l2cache.slices_3.u_core.refillBuf.u_core.buffer[2][0] = u_g.inner_l2cache.slices_3.refillBuf.buffer_2_0;
    force u_i.inner_l2cache.slices_3.u_core.refillBuf.u_core.buffer[2][1] = u_g.inner_l2cache.slices_3.refillBuf.buffer_2_1;
    force u_i.inner_l2cache.slices_3.u_core.refillBuf.u_core.buffer[3][0] = u_g.inner_l2cache.slices_3.refillBuf.buffer_3_0;
    force u_i.inner_l2cache.slices_3.u_core.refillBuf.u_core.buffer[3][1] = u_g.inner_l2cache.slices_3.refillBuf.buffer_3_1;
    force u_i.inner_l2cache.slices_3.u_core.refillBuf.u_core.buffer[4][0] = u_g.inner_l2cache.slices_3.refillBuf.buffer_4_0;
    force u_i.inner_l2cache.slices_3.u_core.refillBuf.u_core.buffer[4][1] = u_g.inner_l2cache.slices_3.refillBuf.buffer_4_1;
    force u_i.inner_l2cache.slices_3.u_core.refillBuf.u_core.buffer[5][0] = u_g.inner_l2cache.slices_3.refillBuf.buffer_5_0;
    force u_i.inner_l2cache.slices_3.u_core.refillBuf.u_core.buffer[5][1] = u_g.inner_l2cache.slices_3.refillBuf.buffer_5_1;
    force u_i.inner_l2cache.slices_3.u_core.refillBuf.u_core.buffer[6][0] = u_g.inner_l2cache.slices_3.refillBuf.buffer_6_0;
    force u_i.inner_l2cache.slices_3.u_core.refillBuf.u_core.buffer[6][1] = u_g.inner_l2cache.slices_3.refillBuf.buffer_6_1;
    force u_i.inner_l2cache.slices_3.u_core.refillBuf.u_core.buffer[7][0] = u_g.inner_l2cache.slices_3.refillBuf.buffer_7_0;
    force u_i.inner_l2cache.slices_3.u_core.refillBuf.u_core.buffer[7][1] = u_g.inner_l2cache.slices_3.refillBuf.buffer_7_1;
    force u_i.inner_l2cache.slices_3.u_core.refillBuf.u_core.buffer[8][0] = u_g.inner_l2cache.slices_3.refillBuf.buffer_8_0;
    force u_i.inner_l2cache.slices_3.u_core.refillBuf.u_core.buffer[8][1] = u_g.inner_l2cache.slices_3.refillBuf.buffer_8_1;
    force u_i.inner_l2cache.slices_3.u_core.refillBuf.u_core.buffer[9][0] = u_g.inner_l2cache.slices_3.refillBuf.buffer_9_0;
    force u_i.inner_l2cache.slices_3.u_core.refillBuf.u_core.buffer[9][1] = u_g.inner_l2cache.slices_3.refillBuf.buffer_9_1;
    force u_i.inner_l2cache.slices_3.u_core.refillBuf.u_core.buffer[10][0] = u_g.inner_l2cache.slices_3.refillBuf.buffer_10_0;
    force u_i.inner_l2cache.slices_3.u_core.refillBuf.u_core.buffer[10][1] = u_g.inner_l2cache.slices_3.refillBuf.buffer_10_1;
    force u_i.inner_l2cache.slices_3.u_core.refillBuf.u_core.buffer[11][0] = u_g.inner_l2cache.slices_3.refillBuf.buffer_11_0;
    force u_i.inner_l2cache.slices_3.u_core.refillBuf.u_core.buffer[11][1] = u_g.inner_l2cache.slices_3.refillBuf.buffer_11_1;
    force u_i.inner_l2cache.slices_3.u_core.refillBuf.u_core.buffer[12][0] = u_g.inner_l2cache.slices_3.refillBuf.buffer_12_0;
    force u_i.inner_l2cache.slices_3.u_core.refillBuf.u_core.buffer[12][1] = u_g.inner_l2cache.slices_3.refillBuf.buffer_12_1;
    force u_i.inner_l2cache.slices_3.u_core.refillBuf.u_core.buffer[13][0] = u_g.inner_l2cache.slices_3.refillBuf.buffer_13_0;
    force u_i.inner_l2cache.slices_3.u_core.refillBuf.u_core.buffer[13][1] = u_g.inner_l2cache.slices_3.refillBuf.buffer_13_1;
    force u_i.inner_l2cache.slices_3.u_core.refillBuf.u_core.buffer[14][0] = u_g.inner_l2cache.slices_3.refillBuf.buffer_14_0;
    force u_i.inner_l2cache.slices_3.u_core.refillBuf.u_core.buffer[14][1] = u_g.inner_l2cache.slices_3.refillBuf.buffer_14_1;
    force u_i.inner_l2cache.slices_3.u_core.refillBuf.u_core.buffer[15][0] = u_g.inner_l2cache.slices_3.refillBuf.buffer_15_0;
    force u_i.inner_l2cache.slices_3.u_core.refillBuf.u_core.buffer[15][1] = u_g.inner_l2cache.slices_3.refillBuf.buffer_15_1;
    force u_i.inner_l2cache.slices_3.u_core.releaseBuf.u_core.buffer[0][0] = u_g.inner_l2cache.slices_3.releaseBuf.buffer_0_0;
    force u_i.inner_l2cache.slices_3.u_core.releaseBuf.u_core.buffer[0][1] = u_g.inner_l2cache.slices_3.releaseBuf.buffer_0_1;
    force u_i.inner_l2cache.slices_3.u_core.releaseBuf.u_core.buffer[1][0] = u_g.inner_l2cache.slices_3.releaseBuf.buffer_1_0;
    force u_i.inner_l2cache.slices_3.u_core.releaseBuf.u_core.buffer[1][1] = u_g.inner_l2cache.slices_3.releaseBuf.buffer_1_1;
    force u_i.inner_l2cache.slices_3.u_core.releaseBuf.u_core.buffer[2][0] = u_g.inner_l2cache.slices_3.releaseBuf.buffer_2_0;
    force u_i.inner_l2cache.slices_3.u_core.releaseBuf.u_core.buffer[2][1] = u_g.inner_l2cache.slices_3.releaseBuf.buffer_2_1;
    force u_i.inner_l2cache.slices_3.u_core.releaseBuf.u_core.buffer[3][0] = u_g.inner_l2cache.slices_3.releaseBuf.buffer_3_0;
    force u_i.inner_l2cache.slices_3.u_core.releaseBuf.u_core.buffer[3][1] = u_g.inner_l2cache.slices_3.releaseBuf.buffer_3_1;
    force u_i.inner_l2cache.slices_3.u_core.releaseBuf.u_core.buffer[4][0] = u_g.inner_l2cache.slices_3.releaseBuf.buffer_4_0;
    force u_i.inner_l2cache.slices_3.u_core.releaseBuf.u_core.buffer[4][1] = u_g.inner_l2cache.slices_3.releaseBuf.buffer_4_1;
    force u_i.inner_l2cache.slices_3.u_core.releaseBuf.u_core.buffer[5][0] = u_g.inner_l2cache.slices_3.releaseBuf.buffer_5_0;
    force u_i.inner_l2cache.slices_3.u_core.releaseBuf.u_core.buffer[5][1] = u_g.inner_l2cache.slices_3.releaseBuf.buffer_5_1;
    force u_i.inner_l2cache.slices_3.u_core.releaseBuf.u_core.buffer[6][0] = u_g.inner_l2cache.slices_3.releaseBuf.buffer_6_0;
    force u_i.inner_l2cache.slices_3.u_core.releaseBuf.u_core.buffer[6][1] = u_g.inner_l2cache.slices_3.releaseBuf.buffer_6_1;
    force u_i.inner_l2cache.slices_3.u_core.releaseBuf.u_core.buffer[7][0] = u_g.inner_l2cache.slices_3.releaseBuf.buffer_7_0;
    force u_i.inner_l2cache.slices_3.u_core.releaseBuf.u_core.buffer[7][1] = u_g.inner_l2cache.slices_3.releaseBuf.buffer_7_1;
    force u_i.inner_l2cache.slices_3.u_core.releaseBuf.u_core.buffer[8][0] = u_g.inner_l2cache.slices_3.releaseBuf.buffer_8_0;
    force u_i.inner_l2cache.slices_3.u_core.releaseBuf.u_core.buffer[8][1] = u_g.inner_l2cache.slices_3.releaseBuf.buffer_8_1;
    force u_i.inner_l2cache.slices_3.u_core.releaseBuf.u_core.buffer[9][0] = u_g.inner_l2cache.slices_3.releaseBuf.buffer_9_0;
    force u_i.inner_l2cache.slices_3.u_core.releaseBuf.u_core.buffer[9][1] = u_g.inner_l2cache.slices_3.releaseBuf.buffer_9_1;
    force u_i.inner_l2cache.slices_3.u_core.releaseBuf.u_core.buffer[10][0] = u_g.inner_l2cache.slices_3.releaseBuf.buffer_10_0;
    force u_i.inner_l2cache.slices_3.u_core.releaseBuf.u_core.buffer[10][1] = u_g.inner_l2cache.slices_3.releaseBuf.buffer_10_1;
    force u_i.inner_l2cache.slices_3.u_core.releaseBuf.u_core.buffer[11][0] = u_g.inner_l2cache.slices_3.releaseBuf.buffer_11_0;
    force u_i.inner_l2cache.slices_3.u_core.releaseBuf.u_core.buffer[11][1] = u_g.inner_l2cache.slices_3.releaseBuf.buffer_11_1;
    force u_i.inner_l2cache.slices_3.u_core.releaseBuf.u_core.buffer[12][0] = u_g.inner_l2cache.slices_3.releaseBuf.buffer_12_0;
    force u_i.inner_l2cache.slices_3.u_core.releaseBuf.u_core.buffer[12][1] = u_g.inner_l2cache.slices_3.releaseBuf.buffer_12_1;
    force u_i.inner_l2cache.slices_3.u_core.releaseBuf.u_core.buffer[13][0] = u_g.inner_l2cache.slices_3.releaseBuf.buffer_13_0;
    force u_i.inner_l2cache.slices_3.u_core.releaseBuf.u_core.buffer[13][1] = u_g.inner_l2cache.slices_3.releaseBuf.buffer_13_1;
    force u_i.inner_l2cache.slices_3.u_core.releaseBuf.u_core.buffer[14][0] = u_g.inner_l2cache.slices_3.releaseBuf.buffer_14_0;
    force u_i.inner_l2cache.slices_3.u_core.releaseBuf.u_core.buffer[14][1] = u_g.inner_l2cache.slices_3.releaseBuf.buffer_14_1;
    force u_i.inner_l2cache.slices_3.u_core.releaseBuf.u_core.buffer[15][0] = u_g.inner_l2cache.slices_3.releaseBuf.buffer_15_0;
    force u_i.inner_l2cache.slices_3.u_core.releaseBuf.u_core.buffer[15][1] = u_g.inner_l2cache.slices_3.releaseBuf.buffer_15_1;
    u_i.inner_l2cache.slices_3.u_core.txdat.queue.ram_ext.Memory = u_g.inner_l2cache.slices_3.txdat.queue.ram_ext.Memory;
    u_i.inner_l2cache.slices_3.u_core.txdat.queueData0.ram_data_ext.Memory = u_g.inner_l2cache.slices_3.txdat.queueData0.ram_data_ext.Memory;
    u_i.inner_l2cache.slices_3.u_core.txdat.queueData1.ram_data_ext.Memory = u_g.inner_l2cache.slices_3.txdat.queueData1.ram_data_ext.Memory;
    u_i.inner_l2cache.slices_3.directory.tagArray.array_0_0_0.array.array.array_14_ext.ram = u_g.inner_l2cache.slices_3.directory.tagArray.array_0_0_0.array.array.array_14_ext.ram;
    u_i.inner_l2cache.slices_3.directory.tagArray.array_0_0_0.array.array.array_14_ext.reg_RW0_addr = u_g.inner_l2cache.slices_3.directory.tagArray.array_0_0_0.array.array.array_14_ext.reg_RW0_addr;
    u_i.inner_l2cache.slices_3.directory.tagArray.array_0_0_0.array.array.array_14_ext.reg_RW0_ren = u_g.inner_l2cache.slices_3.directory.tagArray.array_0_0_0.array.array.array_14_ext.reg_RW0_ren;
    force u_i.inner_l2cache.slices_3.directory.tagArray.array_0_0_0.u_core.rdataReg = u_g.inner_l2cache.slices_3.directory.tagArray.array_0_0_0.rdataReg;
    u_i.inner_l2cache.slices_3.directory.tagArray.array_0_0_1.array.array.array_14_ext.ram = u_g.inner_l2cache.slices_3.directory.tagArray.array_0_0_1.array.array.array_14_ext.ram;
    u_i.inner_l2cache.slices_3.directory.tagArray.array_0_0_1.array.array.array_14_ext.reg_RW0_addr = u_g.inner_l2cache.slices_3.directory.tagArray.array_0_0_1.array.array.array_14_ext.reg_RW0_addr;
    u_i.inner_l2cache.slices_3.directory.tagArray.array_0_0_1.array.array.array_14_ext.reg_RW0_ren = u_g.inner_l2cache.slices_3.directory.tagArray.array_0_0_1.array.array.array_14_ext.reg_RW0_ren;
    force u_i.inner_l2cache.slices_3.directory.tagArray.array_0_0_1.u_core.rdataReg = u_g.inner_l2cache.slices_3.directory.tagArray.array_0_0_1.rdataReg;
    u_i.inner_l2cache.slices_3.directory.tagArray.array_0_1_0.array.array.array_14_ext.ram = u_g.inner_l2cache.slices_3.directory.tagArray.array_0_1_0.array.array.array_14_ext.ram;
    u_i.inner_l2cache.slices_3.directory.tagArray.array_0_1_0.array.array.array_14_ext.reg_RW0_addr = u_g.inner_l2cache.slices_3.directory.tagArray.array_0_1_0.array.array.array_14_ext.reg_RW0_addr;
    u_i.inner_l2cache.slices_3.directory.tagArray.array_0_1_0.array.array.array_14_ext.reg_RW0_ren = u_g.inner_l2cache.slices_3.directory.tagArray.array_0_1_0.array.array.array_14_ext.reg_RW0_ren;
    force u_i.inner_l2cache.slices_3.directory.tagArray.array_0_1_0.u_core.rdataReg = u_g.inner_l2cache.slices_3.directory.tagArray.array_0_1_0.rdataReg;
    u_i.inner_l2cache.slices_3.directory.tagArray.array_0_1_1.array.array.array_14_ext.ram = u_g.inner_l2cache.slices_3.directory.tagArray.array_0_1_1.array.array.array_14_ext.ram;
    u_i.inner_l2cache.slices_3.directory.tagArray.array_0_1_1.array.array.array_14_ext.reg_RW0_addr = u_g.inner_l2cache.slices_3.directory.tagArray.array_0_1_1.array.array.array_14_ext.reg_RW0_addr;
    u_i.inner_l2cache.slices_3.directory.tagArray.array_0_1_1.array.array.array_14_ext.reg_RW0_ren = u_g.inner_l2cache.slices_3.directory.tagArray.array_0_1_1.array.array.array_14_ext.reg_RW0_ren;
    force u_i.inner_l2cache.slices_3.directory.tagArray.array_0_1_1.u_core.rdataReg = u_g.inner_l2cache.slices_3.directory.tagArray.array_0_1_1.rdataReg;
    u_i.inner_l2cache.slices_3.directory.metaArray.array.array.array_15_ext.ram = u_g.inner_l2cache.slices_3.directory.metaArray.array.array.array_15_ext.ram;
    u_i.inner_l2cache.slices_3.directory.metaArray.array.array.array_15_ext.reg_RW0_addr = u_g.inner_l2cache.slices_3.directory.metaArray.array.array.array_15_ext.reg_RW0_addr;
    u_i.inner_l2cache.slices_3.directory.metaArray.array.array.array_15_ext.reg_RW0_ren = u_g.inner_l2cache.slices_3.directory.metaArray.array.array.array_15_ext.reg_RW0_ren;
    force u_i.inner_l2cache.slices_3.directory.metaArray.u_core.rdataReg = u_g.inner_l2cache.slices_3.directory.metaArray.rdataReg;
    u_i.inner_l2cache.slices_3.directory.replacer_sram_opt.array.array.array_16_ext.ram = u_g.inner_l2cache.slices_3.directory.replacer_sram_opt.array.array.array_16_ext.ram;
    u_i.inner_l2cache.slices_3.directory.replacer_sram_opt.array.array.array_16_ext.reg_RW0_addr = u_g.inner_l2cache.slices_3.directory.replacer_sram_opt.array.array.array_16_ext.reg_RW0_addr;
    u_i.inner_l2cache.slices_3.directory.replacer_sram_opt.array.array.array_16_ext.reg_RW0_ren = u_g.inner_l2cache.slices_3.directory.replacer_sram_opt.array.array.array_16_ext.reg_RW0_ren;
    force u_i.inner_l2cache.slices_3.directory.replacer_sram_opt.u_core.rdataReg = u_g.inner_l2cache.slices_3.directory.replacer_sram_opt.rdataReg;
    u_i.inner_l2cache.slices_3.directory.origin_bit_opt.array.array.array_17_ext.ram = u_g.inner_l2cache.slices_3.directory.origin_bit_opt.array.array.array_17_ext.ram;
    u_i.inner_l2cache.slices_3.directory.origin_bit_opt.array.array.array_17_ext.reg_RW0_addr = u_g.inner_l2cache.slices_3.directory.origin_bit_opt.array.array.array_17_ext.reg_RW0_addr;
    u_i.inner_l2cache.slices_3.directory.origin_bit_opt.array.array.array_17_ext.reg_RW0_ren = u_g.inner_l2cache.slices_3.directory.origin_bit_opt.array.array.array_17_ext.reg_RW0_ren;
    force u_i.inner_l2cache.slices_3.directory.origin_bit_opt.u_core.rdataReg = u_g.inner_l2cache.slices_3.directory.origin_bit_opt.rdataReg;
    u_i.inner_l2cache.slices_3.dataStorage.array.array_0_0_0.array.array.array_18_ext.ram = u_g.inner_l2cache.slices_3.dataStorage.array.array_0_0_0.array.array.array_18_ext.ram;
    u_i.inner_l2cache.slices_3.dataStorage.array.array_0_0_0.array.array.array_18_ext.reg_RW0_addr = u_g.inner_l2cache.slices_3.dataStorage.array.array_0_0_0.array.array.array_18_ext.reg_RW0_addr;
    u_i.inner_l2cache.slices_3.dataStorage.array.array_0_0_0.array.array.array_18_ext.reg_RW0_ren = u_g.inner_l2cache.slices_3.dataStorage.array.array_0_0_0.array.array.array_18_ext.reg_RW0_ren;
    force u_i.inner_l2cache.slices_3.dataStorage.array.array_0_0_0.u_core.rdataReg = u_g.inner_l2cache.slices_3.dataStorage.array.array_0_0_0.rdataReg;
    u_i.inner_l2cache.slices_3.dataStorage.array.array_0_0_1.array.array.array_18_ext.ram = u_g.inner_l2cache.slices_3.dataStorage.array.array_0_0_1.array.array.array_18_ext.ram;
    u_i.inner_l2cache.slices_3.dataStorage.array.array_0_0_1.array.array.array_18_ext.reg_RW0_addr = u_g.inner_l2cache.slices_3.dataStorage.array.array_0_0_1.array.array.array_18_ext.reg_RW0_addr;
    u_i.inner_l2cache.slices_3.dataStorage.array.array_0_0_1.array.array.array_18_ext.reg_RW0_ren = u_g.inner_l2cache.slices_3.dataStorage.array.array_0_0_1.array.array.array_18_ext.reg_RW0_ren;
    force u_i.inner_l2cache.slices_3.dataStorage.array.array_0_0_1.u_core.rdataReg = u_g.inner_l2cache.slices_3.dataStorage.array.array_0_0_1.rdataReg;
    u_i.inner_l2cache.slices_3.dataStorage.array.array_0_0_2.array.array.array_18_ext.ram = u_g.inner_l2cache.slices_3.dataStorage.array.array_0_0_2.array.array.array_18_ext.ram;
    u_i.inner_l2cache.slices_3.dataStorage.array.array_0_0_2.array.array.array_18_ext.reg_RW0_addr = u_g.inner_l2cache.slices_3.dataStorage.array.array_0_0_2.array.array.array_18_ext.reg_RW0_addr;
    u_i.inner_l2cache.slices_3.dataStorage.array.array_0_0_2.array.array.array_18_ext.reg_RW0_ren = u_g.inner_l2cache.slices_3.dataStorage.array.array_0_0_2.array.array.array_18_ext.reg_RW0_ren;
    force u_i.inner_l2cache.slices_3.dataStorage.array.array_0_0_2.u_core.rdataReg = u_g.inner_l2cache.slices_3.dataStorage.array.array_0_0_2.rdataReg;
    u_i.inner_l2cache.slices_3.dataStorage.array.array_0_0_3.array.array.array_18_ext.ram = u_g.inner_l2cache.slices_3.dataStorage.array.array_0_0_3.array.array.array_18_ext.ram;
    u_i.inner_l2cache.slices_3.dataStorage.array.array_0_0_3.array.array.array_18_ext.reg_RW0_addr = u_g.inner_l2cache.slices_3.dataStorage.array.array_0_0_3.array.array.array_18_ext.reg_RW0_addr;
    u_i.inner_l2cache.slices_3.dataStorage.array.array_0_0_3.array.array.array_18_ext.reg_RW0_ren = u_g.inner_l2cache.slices_3.dataStorage.array.array_0_0_3.array.array.array_18_ext.reg_RW0_ren;
    force u_i.inner_l2cache.slices_3.dataStorage.array.array_0_0_3.u_core.rdataReg = u_g.inner_l2cache.slices_3.dataStorage.array.array_0_0_3.rdataReg;
    force u_i.inner_l2cache.slices_3.dataStorage.u_core.error_REG = u_g.inner_l2cache.slices_3.dataStorage.error_REG;
    force u_i.inner_l2cache.slices_3.dataStorage.u_core.error_REG_1 = u_g.inner_l2cache.slices_3.dataStorage.error_REG_1;
    force u_i.inner_l2cache.slices_3.mbistPl.u_core.g_node_return.pipelineDataOutReg = u_g.inner_l2cache.slices_3.mbistPl.pipelineDataOutReg;
    u_i.inner_l2cache.slices_3.u_core.txreq.u_core.queue.ram_ext.Memory = u_g.inner_l2cache.slices_3.txreq.queue.ram_ext.Memory;
    u_i.inner_l2cache.slices_3.u_core.txrsp.u_core.queue.ram_ext.Memory = u_g.inner_l2cache.slices_3.txrsp.queue.ram_ext.Memory;
    force u_i.inner_l2cache.slices_3.u_core.io_error_bits_REG_valid = u_g.inner_l2cache.slices_3.io_error_bits_REG_valid;
    force u_i.inner_l2cache.slices_3.u_core.io_error_bits_REG_address = u_g.inner_l2cache.slices_3.io_error_bits_REG_address;
    force u_i.inner_l2cache.slices_3.u_core.io_perf_0_value_REG = u_g.inner_l2cache.slices_3.io_perf_0_value_REG;
    force u_i.inner_l2cache.slices_3.u_core.io_perf_0_value_REG_1 = u_g.inner_l2cache.slices_3.io_perf_0_value_REG_1;
    force u_i.inner_l2cache.slices_3.u_core.io_perf_1_value_REG = u_g.inner_l2cache.slices_3.io_perf_1_value_REG;
    force u_i.inner_l2cache.slices_3.u_core.io_perf_1_value_REG_1 = u_g.inner_l2cache.slices_3.io_perf_1_value_REG_1;
    force u_i.inner_l2cache.slices_3.u_core.io_perf_3_value_REG = u_g.inner_l2cache.slices_3.io_perf_3_value_REG;
    force u_i.inner_l2cache.slices_3.u_core.io_perf_3_value_REG_1 = u_g.inner_l2cache.slices_3.io_perf_3_value_REG_1;
    force u_i.inner_l2cache.slices_3.u_core.io_perf_4_value_REG = u_g.inner_l2cache.slices_3.io_perf_4_value_REG;
    force u_i.inner_l2cache.slices_3.u_core.io_perf_4_value_REG_1 = u_g.inner_l2cache.slices_3.io_perf_4_value_REG_1;
    force u_i.inner_l2cache.slices_3.u_core.io_perf_5_value_REG = u_g.inner_l2cache.slices_3.io_perf_5_value_REG;
    force u_i.inner_l2cache.slices_3.u_core.io_perf_5_value_REG_1 = u_g.inner_l2cache.slices_3.io_perf_5_value_REG_1;
    force u_i.inner_l2cache.slices_3.u_core.io_perf_6_value_REG = u_g.inner_l2cache.slices_3.io_perf_6_value_REG;
    force u_i.inner_l2cache.slices_3.u_core.io_perf_6_value_REG_1 = u_g.inner_l2cache.slices_3.io_perf_6_value_REG_1;
    force u_i.inner_l2cache.slices_3.u_core.io_perf_7_value_REG = u_g.inner_l2cache.slices_3.io_perf_7_value_REG;
    force u_i.inner_l2cache.slices_3.u_core.io_perf_7_value_REG_1 = u_g.inner_l2cache.slices_3.io_perf_7_value_REG_1;
    force u_i.inner_l2cache.slices_3.u_core.io_perf_8_value_REG = u_g.inner_l2cache.slices_3.io_perf_8_value_REG;
    force u_i.inner_l2cache.slices_3.u_core.io_perf_8_value_REG_1 = u_g.inner_l2cache.slices_3.io_perf_8_value_REG_1;
    force u_i.inner_l2cache.slices_3.u_core.io_perf_9_value_REG = u_g.inner_l2cache.slices_3.io_perf_9_value_REG;
    force u_i.inner_l2cache.slices_3.u_core.io_perf_9_value_REG_1 = u_g.inner_l2cache.slices_3.io_perf_9_value_REG_1;
    force u_i.inner_l2cache.slices_3.u_core.io_perf_10_value_REG = u_g.inner_l2cache.slices_3.io_perf_10_value_REG;
    force u_i.inner_l2cache.slices_3.u_core.io_perf_10_value_REG_1 = u_g.inner_l2cache.slices_3.io_perf_10_value_REG_1;
    force u_i.inner_l2cache.slices_3.u_core.io_perf_11_value_REG = u_g.inner_l2cache.slices_3.io_perf_11_value_REG;
    force u_i.inner_l2cache.slices_3.u_core.io_perf_11_value_REG_1 = u_g.inner_l2cache.slices_3.io_perf_11_value_REG_1;
    force u_i.inner_l2cache.slices_3.u_core.io_perf_12_value_REG = u_g.inner_l2cache.slices_3.io_perf_12_value_REG;
    force u_i.inner_l2cache.slices_3.u_core.io_perf_12_value_REG_1 = u_g.inner_l2cache.slices_3.io_perf_12_value_REG_1;
    force u_i.inner_l2cache.slices_3.u_core.io_perf_13_value_REG = u_g.inner_l2cache.slices_3.io_perf_13_value_REG;
    force u_i.inner_l2cache.slices_3.u_core.io_perf_13_value_REG_1 = u_g.inner_l2cache.slices_3.io_perf_13_value_REG_1;
    force u_i.inner_l2cache.slices_3.u_core.io_perf_14_value_REG = u_g.inner_l2cache.slices_3.io_perf_14_value_REG;
    force u_i.inner_l2cache.slices_3.u_core.io_perf_14_value_REG_1 = u_g.inner_l2cache.slices_3.io_perf_14_value_REG_1;
    force u_i.inner_l2cache.slices_3.u_core.io_perf_15_value_REG = u_g.inner_l2cache.slices_3.io_perf_15_value_REG;
    force u_i.inner_l2cache.slices_3.u_core.io_perf_15_value_REG_1 = u_g.inner_l2cache.slices_3.io_perf_15_value_REG_1;
    force u_i.inner_l2cache.slices_3.u_core.io_perf_16_value_REG = u_g.inner_l2cache.slices_3.io_perf_16_value_REG;
    force u_i.inner_l2cache.slices_3.u_core.io_perf_16_value_REG_1 = u_g.inner_l2cache.slices_3.io_perf_16_value_REG_1;
    force u_i.inner_l2cache.mmioBridge.entries_0.u_core.s_txreq = u_g.inner_l2cache.mmioBridge.entries_0.s_txreq;
    force u_i.inner_l2cache.mmioBridge.entries_0.u_core.s_ncbwrdata = u_g.inner_l2cache.mmioBridge.entries_0.s_ncbwrdata;
    force u_i.inner_l2cache.mmioBridge.entries_0.u_core.s_resp = u_g.inner_l2cache.mmioBridge.entries_0.s_resp;
    force u_i.inner_l2cache.mmioBridge.entries_0.u_core.w_comp = u_g.inner_l2cache.mmioBridge.entries_0.w_comp;
    force u_i.inner_l2cache.mmioBridge.entries_0.u_core.w_dbidresp = u_g.inner_l2cache.mmioBridge.entries_0.w_dbidresp;
    force u_i.inner_l2cache.mmioBridge.entries_0.u_core.w_compdata = u_g.inner_l2cache.mmioBridge.entries_0.w_compdata;
    force u_i.inner_l2cache.mmioBridge.entries_0.u_core.w_pcrdgrant = u_g.inner_l2cache.mmioBridge.entries_0.w_pcrdgrant;
    force u_i.inner_l2cache.mmioBridge.entries_0.u_core.w_readreceipt = u_g.inner_l2cache.mmioBridge.entries_0.w_readreceipt;
    force u_i.inner_l2cache.mmioBridge.entries_0.u_core.allowRetry = u_g.inner_l2cache.mmioBridge.entries_0.allowRetry;
    force u_i.inner_l2cache.mmioBridge.entries_0.u_core.req_opcode = u_g.inner_l2cache.mmioBridge.entries_0.req_opcode;
    force u_i.inner_l2cache.mmioBridge.entries_0.u_core.req_size = u_g.inner_l2cache.mmioBridge.entries_0.req_size;
    force u_i.inner_l2cache.mmioBridge.entries_0.u_core.req_source = u_g.inner_l2cache.mmioBridge.entries_0.req_source;
    force u_i.inner_l2cache.mmioBridge.entries_0.u_core.req_address = u_g.inner_l2cache.mmioBridge.entries_0.req_address;
    force u_i.inner_l2cache.mmioBridge.entries_0.u_core.req_user_memBackType_MM = u_g.inner_l2cache.mmioBridge.entries_0.req_user_memBackType_MM;
    force u_i.inner_l2cache.mmioBridge.entries_0.u_core.req_user_memPageType_NC = u_g.inner_l2cache.mmioBridge.entries_0.req_user_memPageType_NC;
    force u_i.inner_l2cache.mmioBridge.entries_0.u_core.req_mask = u_g.inner_l2cache.mmioBridge.entries_0.req_mask;
    force u_i.inner_l2cache.mmioBridge.entries_0.u_core.req_data = u_g.inner_l2cache.mmioBridge.entries_0.req_data;
    force u_i.inner_l2cache.mmioBridge.entries_0.u_core.req_corrupt = u_g.inner_l2cache.mmioBridge.entries_0.req_corrupt;
    force u_i.inner_l2cache.mmioBridge.entries_0.u_core.rdata = u_g.inner_l2cache.mmioBridge.entries_0.rdata;
    force u_i.inner_l2cache.mmioBridge.entries_0.u_core.srcID = u_g.inner_l2cache.mmioBridge.entries_0.srcID;
    force u_i.inner_l2cache.mmioBridge.entries_0.u_core.dbID = u_g.inner_l2cache.mmioBridge.entries_0.dbID;
    force u_i.inner_l2cache.mmioBridge.entries_0.u_core.pCrdType = u_g.inner_l2cache.mmioBridge.entries_0.pCrdType;
    force u_i.inner_l2cache.mmioBridge.entries_0.u_core.denied = u_g.inner_l2cache.mmioBridge.entries_0.denied;
    force u_i.inner_l2cache.mmioBridge.entries_0.u_core.corrupt = u_g.inner_l2cache.mmioBridge.entries_0.corrupt;
    force u_i.inner_l2cache.mmioBridge.entries_0.u_core.traceTag = u_g.inner_l2cache.mmioBridge.entries_0.traceTag;
    force u_i.inner_l2cache.mmioBridge.entries_1.u_core.s_txreq = u_g.inner_l2cache.mmioBridge.entries_1.s_txreq;
    force u_i.inner_l2cache.mmioBridge.entries_1.u_core.s_ncbwrdata = u_g.inner_l2cache.mmioBridge.entries_1.s_ncbwrdata;
    force u_i.inner_l2cache.mmioBridge.entries_1.u_core.s_resp = u_g.inner_l2cache.mmioBridge.entries_1.s_resp;
    force u_i.inner_l2cache.mmioBridge.entries_1.u_core.w_comp = u_g.inner_l2cache.mmioBridge.entries_1.w_comp;
    force u_i.inner_l2cache.mmioBridge.entries_1.u_core.w_dbidresp = u_g.inner_l2cache.mmioBridge.entries_1.w_dbidresp;
    force u_i.inner_l2cache.mmioBridge.entries_1.u_core.w_compdata = u_g.inner_l2cache.mmioBridge.entries_1.w_compdata;
    force u_i.inner_l2cache.mmioBridge.entries_1.u_core.w_pcrdgrant = u_g.inner_l2cache.mmioBridge.entries_1.w_pcrdgrant;
    force u_i.inner_l2cache.mmioBridge.entries_1.u_core.w_readreceipt = u_g.inner_l2cache.mmioBridge.entries_1.w_readreceipt;
    force u_i.inner_l2cache.mmioBridge.entries_1.u_core.allowRetry = u_g.inner_l2cache.mmioBridge.entries_1.allowRetry;
    force u_i.inner_l2cache.mmioBridge.entries_1.u_core.req_opcode = u_g.inner_l2cache.mmioBridge.entries_1.req_opcode;
    force u_i.inner_l2cache.mmioBridge.entries_1.u_core.req_size = u_g.inner_l2cache.mmioBridge.entries_1.req_size;
    force u_i.inner_l2cache.mmioBridge.entries_1.u_core.req_source = u_g.inner_l2cache.mmioBridge.entries_1.req_source;
    force u_i.inner_l2cache.mmioBridge.entries_1.u_core.req_address = u_g.inner_l2cache.mmioBridge.entries_1.req_address;
    force u_i.inner_l2cache.mmioBridge.entries_1.u_core.req_user_memBackType_MM = u_g.inner_l2cache.mmioBridge.entries_1.req_user_memBackType_MM;
    force u_i.inner_l2cache.mmioBridge.entries_1.u_core.req_user_memPageType_NC = u_g.inner_l2cache.mmioBridge.entries_1.req_user_memPageType_NC;
    force u_i.inner_l2cache.mmioBridge.entries_1.u_core.req_mask = u_g.inner_l2cache.mmioBridge.entries_1.req_mask;
    force u_i.inner_l2cache.mmioBridge.entries_1.u_core.req_data = u_g.inner_l2cache.mmioBridge.entries_1.req_data;
    force u_i.inner_l2cache.mmioBridge.entries_1.u_core.req_corrupt = u_g.inner_l2cache.mmioBridge.entries_1.req_corrupt;
    force u_i.inner_l2cache.mmioBridge.entries_1.u_core.rdata = u_g.inner_l2cache.mmioBridge.entries_1.rdata;
    force u_i.inner_l2cache.mmioBridge.entries_1.u_core.srcID = u_g.inner_l2cache.mmioBridge.entries_1.srcID;
    force u_i.inner_l2cache.mmioBridge.entries_1.u_core.dbID = u_g.inner_l2cache.mmioBridge.entries_1.dbID;
    force u_i.inner_l2cache.mmioBridge.entries_1.u_core.pCrdType = u_g.inner_l2cache.mmioBridge.entries_1.pCrdType;
    force u_i.inner_l2cache.mmioBridge.entries_1.u_core.denied = u_g.inner_l2cache.mmioBridge.entries_1.denied;
    force u_i.inner_l2cache.mmioBridge.entries_1.u_core.corrupt = u_g.inner_l2cache.mmioBridge.entries_1.corrupt;
    force u_i.inner_l2cache.mmioBridge.entries_1.u_core.traceTag = u_g.inner_l2cache.mmioBridge.entries_1.traceTag;
    force u_i.inner_l2cache.mmioBridge.entries_2.u_core.s_txreq = u_g.inner_l2cache.mmioBridge.entries_2.s_txreq;
    force u_i.inner_l2cache.mmioBridge.entries_2.u_core.s_ncbwrdata = u_g.inner_l2cache.mmioBridge.entries_2.s_ncbwrdata;
    force u_i.inner_l2cache.mmioBridge.entries_2.u_core.s_resp = u_g.inner_l2cache.mmioBridge.entries_2.s_resp;
    force u_i.inner_l2cache.mmioBridge.entries_2.u_core.w_comp = u_g.inner_l2cache.mmioBridge.entries_2.w_comp;
    force u_i.inner_l2cache.mmioBridge.entries_2.u_core.w_dbidresp = u_g.inner_l2cache.mmioBridge.entries_2.w_dbidresp;
    force u_i.inner_l2cache.mmioBridge.entries_2.u_core.w_compdata = u_g.inner_l2cache.mmioBridge.entries_2.w_compdata;
    force u_i.inner_l2cache.mmioBridge.entries_2.u_core.w_pcrdgrant = u_g.inner_l2cache.mmioBridge.entries_2.w_pcrdgrant;
    force u_i.inner_l2cache.mmioBridge.entries_2.u_core.w_readreceipt = u_g.inner_l2cache.mmioBridge.entries_2.w_readreceipt;
    force u_i.inner_l2cache.mmioBridge.entries_2.u_core.allowRetry = u_g.inner_l2cache.mmioBridge.entries_2.allowRetry;
    force u_i.inner_l2cache.mmioBridge.entries_2.u_core.req_opcode = u_g.inner_l2cache.mmioBridge.entries_2.req_opcode;
    force u_i.inner_l2cache.mmioBridge.entries_2.u_core.req_size = u_g.inner_l2cache.mmioBridge.entries_2.req_size;
    force u_i.inner_l2cache.mmioBridge.entries_2.u_core.req_source = u_g.inner_l2cache.mmioBridge.entries_2.req_source;
    force u_i.inner_l2cache.mmioBridge.entries_2.u_core.req_address = u_g.inner_l2cache.mmioBridge.entries_2.req_address;
    force u_i.inner_l2cache.mmioBridge.entries_2.u_core.req_user_memBackType_MM = u_g.inner_l2cache.mmioBridge.entries_2.req_user_memBackType_MM;
    force u_i.inner_l2cache.mmioBridge.entries_2.u_core.req_user_memPageType_NC = u_g.inner_l2cache.mmioBridge.entries_2.req_user_memPageType_NC;
    force u_i.inner_l2cache.mmioBridge.entries_2.u_core.req_mask = u_g.inner_l2cache.mmioBridge.entries_2.req_mask;
    force u_i.inner_l2cache.mmioBridge.entries_2.u_core.req_data = u_g.inner_l2cache.mmioBridge.entries_2.req_data;
    force u_i.inner_l2cache.mmioBridge.entries_2.u_core.req_corrupt = u_g.inner_l2cache.mmioBridge.entries_2.req_corrupt;
    force u_i.inner_l2cache.mmioBridge.entries_2.u_core.rdata = u_g.inner_l2cache.mmioBridge.entries_2.rdata;
    force u_i.inner_l2cache.mmioBridge.entries_2.u_core.srcID = u_g.inner_l2cache.mmioBridge.entries_2.srcID;
    force u_i.inner_l2cache.mmioBridge.entries_2.u_core.dbID = u_g.inner_l2cache.mmioBridge.entries_2.dbID;
    force u_i.inner_l2cache.mmioBridge.entries_2.u_core.pCrdType = u_g.inner_l2cache.mmioBridge.entries_2.pCrdType;
    force u_i.inner_l2cache.mmioBridge.entries_2.u_core.denied = u_g.inner_l2cache.mmioBridge.entries_2.denied;
    force u_i.inner_l2cache.mmioBridge.entries_2.u_core.corrupt = u_g.inner_l2cache.mmioBridge.entries_2.corrupt;
    force u_i.inner_l2cache.mmioBridge.entries_2.u_core.traceTag = u_g.inner_l2cache.mmioBridge.entries_2.traceTag;
    force u_i.inner_l2cache.mmioBridge.entries_3.u_core.s_txreq = u_g.inner_l2cache.mmioBridge.entries_3.s_txreq;
    force u_i.inner_l2cache.mmioBridge.entries_3.u_core.s_ncbwrdata = u_g.inner_l2cache.mmioBridge.entries_3.s_ncbwrdata;
    force u_i.inner_l2cache.mmioBridge.entries_3.u_core.s_resp = u_g.inner_l2cache.mmioBridge.entries_3.s_resp;
    force u_i.inner_l2cache.mmioBridge.entries_3.u_core.w_comp = u_g.inner_l2cache.mmioBridge.entries_3.w_comp;
    force u_i.inner_l2cache.mmioBridge.entries_3.u_core.w_dbidresp = u_g.inner_l2cache.mmioBridge.entries_3.w_dbidresp;
    force u_i.inner_l2cache.mmioBridge.entries_3.u_core.w_compdata = u_g.inner_l2cache.mmioBridge.entries_3.w_compdata;
    force u_i.inner_l2cache.mmioBridge.entries_3.u_core.w_pcrdgrant = u_g.inner_l2cache.mmioBridge.entries_3.w_pcrdgrant;
    force u_i.inner_l2cache.mmioBridge.entries_3.u_core.w_readreceipt = u_g.inner_l2cache.mmioBridge.entries_3.w_readreceipt;
    force u_i.inner_l2cache.mmioBridge.entries_3.u_core.allowRetry = u_g.inner_l2cache.mmioBridge.entries_3.allowRetry;
    force u_i.inner_l2cache.mmioBridge.entries_3.u_core.req_opcode = u_g.inner_l2cache.mmioBridge.entries_3.req_opcode;
    force u_i.inner_l2cache.mmioBridge.entries_3.u_core.req_size = u_g.inner_l2cache.mmioBridge.entries_3.req_size;
    force u_i.inner_l2cache.mmioBridge.entries_3.u_core.req_source = u_g.inner_l2cache.mmioBridge.entries_3.req_source;
    force u_i.inner_l2cache.mmioBridge.entries_3.u_core.req_address = u_g.inner_l2cache.mmioBridge.entries_3.req_address;
    force u_i.inner_l2cache.mmioBridge.entries_3.u_core.req_user_memBackType_MM = u_g.inner_l2cache.mmioBridge.entries_3.req_user_memBackType_MM;
    force u_i.inner_l2cache.mmioBridge.entries_3.u_core.req_user_memPageType_NC = u_g.inner_l2cache.mmioBridge.entries_3.req_user_memPageType_NC;
    force u_i.inner_l2cache.mmioBridge.entries_3.u_core.req_mask = u_g.inner_l2cache.mmioBridge.entries_3.req_mask;
    force u_i.inner_l2cache.mmioBridge.entries_3.u_core.req_data = u_g.inner_l2cache.mmioBridge.entries_3.req_data;
    force u_i.inner_l2cache.mmioBridge.entries_3.u_core.req_corrupt = u_g.inner_l2cache.mmioBridge.entries_3.req_corrupt;
    force u_i.inner_l2cache.mmioBridge.entries_3.u_core.rdata = u_g.inner_l2cache.mmioBridge.entries_3.rdata;
    force u_i.inner_l2cache.mmioBridge.entries_3.u_core.srcID = u_g.inner_l2cache.mmioBridge.entries_3.srcID;
    force u_i.inner_l2cache.mmioBridge.entries_3.u_core.dbID = u_g.inner_l2cache.mmioBridge.entries_3.dbID;
    force u_i.inner_l2cache.mmioBridge.entries_3.u_core.pCrdType = u_g.inner_l2cache.mmioBridge.entries_3.pCrdType;
    force u_i.inner_l2cache.mmioBridge.entries_3.u_core.denied = u_g.inner_l2cache.mmioBridge.entries_3.denied;
    force u_i.inner_l2cache.mmioBridge.entries_3.u_core.corrupt = u_g.inner_l2cache.mmioBridge.entries_3.corrupt;
    force u_i.inner_l2cache.mmioBridge.entries_3.u_core.traceTag = u_g.inner_l2cache.mmioBridge.entries_3.traceTag;
    force u_i.inner_l2cache.mmioBridge.entries_4.u_core.s_txreq = u_g.inner_l2cache.mmioBridge.entries_4.s_txreq;
    force u_i.inner_l2cache.mmioBridge.entries_4.u_core.s_ncbwrdata = u_g.inner_l2cache.mmioBridge.entries_4.s_ncbwrdata;
    force u_i.inner_l2cache.mmioBridge.entries_4.u_core.s_resp = u_g.inner_l2cache.mmioBridge.entries_4.s_resp;
    force u_i.inner_l2cache.mmioBridge.entries_4.u_core.w_comp = u_g.inner_l2cache.mmioBridge.entries_4.w_comp;
    force u_i.inner_l2cache.mmioBridge.entries_4.u_core.w_dbidresp = u_g.inner_l2cache.mmioBridge.entries_4.w_dbidresp;
    force u_i.inner_l2cache.mmioBridge.entries_4.u_core.w_compdata = u_g.inner_l2cache.mmioBridge.entries_4.w_compdata;
    force u_i.inner_l2cache.mmioBridge.entries_4.u_core.w_pcrdgrant = u_g.inner_l2cache.mmioBridge.entries_4.w_pcrdgrant;
    force u_i.inner_l2cache.mmioBridge.entries_4.u_core.w_readreceipt = u_g.inner_l2cache.mmioBridge.entries_4.w_readreceipt;
    force u_i.inner_l2cache.mmioBridge.entries_4.u_core.allowRetry = u_g.inner_l2cache.mmioBridge.entries_4.allowRetry;
    force u_i.inner_l2cache.mmioBridge.entries_4.u_core.req_opcode = u_g.inner_l2cache.mmioBridge.entries_4.req_opcode;
    force u_i.inner_l2cache.mmioBridge.entries_4.u_core.req_size = u_g.inner_l2cache.mmioBridge.entries_4.req_size;
    force u_i.inner_l2cache.mmioBridge.entries_4.u_core.req_source = u_g.inner_l2cache.mmioBridge.entries_4.req_source;
    force u_i.inner_l2cache.mmioBridge.entries_4.u_core.req_address = u_g.inner_l2cache.mmioBridge.entries_4.req_address;
    force u_i.inner_l2cache.mmioBridge.entries_4.u_core.req_user_memBackType_MM = u_g.inner_l2cache.mmioBridge.entries_4.req_user_memBackType_MM;
    force u_i.inner_l2cache.mmioBridge.entries_4.u_core.req_user_memPageType_NC = u_g.inner_l2cache.mmioBridge.entries_4.req_user_memPageType_NC;
    force u_i.inner_l2cache.mmioBridge.entries_4.u_core.req_mask = u_g.inner_l2cache.mmioBridge.entries_4.req_mask;
    force u_i.inner_l2cache.mmioBridge.entries_4.u_core.req_data = u_g.inner_l2cache.mmioBridge.entries_4.req_data;
    force u_i.inner_l2cache.mmioBridge.entries_4.u_core.req_corrupt = u_g.inner_l2cache.mmioBridge.entries_4.req_corrupt;
    force u_i.inner_l2cache.mmioBridge.entries_4.u_core.rdata = u_g.inner_l2cache.mmioBridge.entries_4.rdata;
    force u_i.inner_l2cache.mmioBridge.entries_4.u_core.srcID = u_g.inner_l2cache.mmioBridge.entries_4.srcID;
    force u_i.inner_l2cache.mmioBridge.entries_4.u_core.dbID = u_g.inner_l2cache.mmioBridge.entries_4.dbID;
    force u_i.inner_l2cache.mmioBridge.entries_4.u_core.pCrdType = u_g.inner_l2cache.mmioBridge.entries_4.pCrdType;
    force u_i.inner_l2cache.mmioBridge.entries_4.u_core.denied = u_g.inner_l2cache.mmioBridge.entries_4.denied;
    force u_i.inner_l2cache.mmioBridge.entries_4.u_core.corrupt = u_g.inner_l2cache.mmioBridge.entries_4.corrupt;
    force u_i.inner_l2cache.mmioBridge.entries_4.u_core.traceTag = u_g.inner_l2cache.mmioBridge.entries_4.traceTag;
    force u_i.inner_l2cache.mmioBridge.entries_5.u_core.s_txreq = u_g.inner_l2cache.mmioBridge.entries_5.s_txreq;
    force u_i.inner_l2cache.mmioBridge.entries_5.u_core.s_ncbwrdata = u_g.inner_l2cache.mmioBridge.entries_5.s_ncbwrdata;
    force u_i.inner_l2cache.mmioBridge.entries_5.u_core.s_resp = u_g.inner_l2cache.mmioBridge.entries_5.s_resp;
    force u_i.inner_l2cache.mmioBridge.entries_5.u_core.w_comp = u_g.inner_l2cache.mmioBridge.entries_5.w_comp;
    force u_i.inner_l2cache.mmioBridge.entries_5.u_core.w_dbidresp = u_g.inner_l2cache.mmioBridge.entries_5.w_dbidresp;
    force u_i.inner_l2cache.mmioBridge.entries_5.u_core.w_compdata = u_g.inner_l2cache.mmioBridge.entries_5.w_compdata;
    force u_i.inner_l2cache.mmioBridge.entries_5.u_core.w_pcrdgrant = u_g.inner_l2cache.mmioBridge.entries_5.w_pcrdgrant;
    force u_i.inner_l2cache.mmioBridge.entries_5.u_core.w_readreceipt = u_g.inner_l2cache.mmioBridge.entries_5.w_readreceipt;
    force u_i.inner_l2cache.mmioBridge.entries_5.u_core.allowRetry = u_g.inner_l2cache.mmioBridge.entries_5.allowRetry;
    force u_i.inner_l2cache.mmioBridge.entries_5.u_core.req_opcode = u_g.inner_l2cache.mmioBridge.entries_5.req_opcode;
    force u_i.inner_l2cache.mmioBridge.entries_5.u_core.req_size = u_g.inner_l2cache.mmioBridge.entries_5.req_size;
    force u_i.inner_l2cache.mmioBridge.entries_5.u_core.req_source = u_g.inner_l2cache.mmioBridge.entries_5.req_source;
    force u_i.inner_l2cache.mmioBridge.entries_5.u_core.req_address = u_g.inner_l2cache.mmioBridge.entries_5.req_address;
    force u_i.inner_l2cache.mmioBridge.entries_5.u_core.req_user_memBackType_MM = u_g.inner_l2cache.mmioBridge.entries_5.req_user_memBackType_MM;
    force u_i.inner_l2cache.mmioBridge.entries_5.u_core.req_user_memPageType_NC = u_g.inner_l2cache.mmioBridge.entries_5.req_user_memPageType_NC;
    force u_i.inner_l2cache.mmioBridge.entries_5.u_core.req_mask = u_g.inner_l2cache.mmioBridge.entries_5.req_mask;
    force u_i.inner_l2cache.mmioBridge.entries_5.u_core.req_data = u_g.inner_l2cache.mmioBridge.entries_5.req_data;
    force u_i.inner_l2cache.mmioBridge.entries_5.u_core.req_corrupt = u_g.inner_l2cache.mmioBridge.entries_5.req_corrupt;
    force u_i.inner_l2cache.mmioBridge.entries_5.u_core.rdata = u_g.inner_l2cache.mmioBridge.entries_5.rdata;
    force u_i.inner_l2cache.mmioBridge.entries_5.u_core.srcID = u_g.inner_l2cache.mmioBridge.entries_5.srcID;
    force u_i.inner_l2cache.mmioBridge.entries_5.u_core.dbID = u_g.inner_l2cache.mmioBridge.entries_5.dbID;
    force u_i.inner_l2cache.mmioBridge.entries_5.u_core.pCrdType = u_g.inner_l2cache.mmioBridge.entries_5.pCrdType;
    force u_i.inner_l2cache.mmioBridge.entries_5.u_core.denied = u_g.inner_l2cache.mmioBridge.entries_5.denied;
    force u_i.inner_l2cache.mmioBridge.entries_5.u_core.corrupt = u_g.inner_l2cache.mmioBridge.entries_5.corrupt;
    force u_i.inner_l2cache.mmioBridge.entries_5.u_core.traceTag = u_g.inner_l2cache.mmioBridge.entries_5.traceTag;
    force u_i.inner_l2cache.mmioBridge.entries_6.u_core.s_txreq = u_g.inner_l2cache.mmioBridge.entries_6.s_txreq;
    force u_i.inner_l2cache.mmioBridge.entries_6.u_core.s_ncbwrdata = u_g.inner_l2cache.mmioBridge.entries_6.s_ncbwrdata;
    force u_i.inner_l2cache.mmioBridge.entries_6.u_core.s_resp = u_g.inner_l2cache.mmioBridge.entries_6.s_resp;
    force u_i.inner_l2cache.mmioBridge.entries_6.u_core.w_comp = u_g.inner_l2cache.mmioBridge.entries_6.w_comp;
    force u_i.inner_l2cache.mmioBridge.entries_6.u_core.w_dbidresp = u_g.inner_l2cache.mmioBridge.entries_6.w_dbidresp;
    force u_i.inner_l2cache.mmioBridge.entries_6.u_core.w_compdata = u_g.inner_l2cache.mmioBridge.entries_6.w_compdata;
    force u_i.inner_l2cache.mmioBridge.entries_6.u_core.w_pcrdgrant = u_g.inner_l2cache.mmioBridge.entries_6.w_pcrdgrant;
    force u_i.inner_l2cache.mmioBridge.entries_6.u_core.w_readreceipt = u_g.inner_l2cache.mmioBridge.entries_6.w_readreceipt;
    force u_i.inner_l2cache.mmioBridge.entries_6.u_core.allowRetry = u_g.inner_l2cache.mmioBridge.entries_6.allowRetry;
    force u_i.inner_l2cache.mmioBridge.entries_6.u_core.req_opcode = u_g.inner_l2cache.mmioBridge.entries_6.req_opcode;
    force u_i.inner_l2cache.mmioBridge.entries_6.u_core.req_size = u_g.inner_l2cache.mmioBridge.entries_6.req_size;
    force u_i.inner_l2cache.mmioBridge.entries_6.u_core.req_source = u_g.inner_l2cache.mmioBridge.entries_6.req_source;
    force u_i.inner_l2cache.mmioBridge.entries_6.u_core.req_address = u_g.inner_l2cache.mmioBridge.entries_6.req_address;
    force u_i.inner_l2cache.mmioBridge.entries_6.u_core.req_user_memBackType_MM = u_g.inner_l2cache.mmioBridge.entries_6.req_user_memBackType_MM;
    force u_i.inner_l2cache.mmioBridge.entries_6.u_core.req_user_memPageType_NC = u_g.inner_l2cache.mmioBridge.entries_6.req_user_memPageType_NC;
    force u_i.inner_l2cache.mmioBridge.entries_6.u_core.req_mask = u_g.inner_l2cache.mmioBridge.entries_6.req_mask;
    force u_i.inner_l2cache.mmioBridge.entries_6.u_core.req_data = u_g.inner_l2cache.mmioBridge.entries_6.req_data;
    force u_i.inner_l2cache.mmioBridge.entries_6.u_core.req_corrupt = u_g.inner_l2cache.mmioBridge.entries_6.req_corrupt;
    force u_i.inner_l2cache.mmioBridge.entries_6.u_core.rdata = u_g.inner_l2cache.mmioBridge.entries_6.rdata;
    force u_i.inner_l2cache.mmioBridge.entries_6.u_core.srcID = u_g.inner_l2cache.mmioBridge.entries_6.srcID;
    force u_i.inner_l2cache.mmioBridge.entries_6.u_core.dbID = u_g.inner_l2cache.mmioBridge.entries_6.dbID;
    force u_i.inner_l2cache.mmioBridge.entries_6.u_core.pCrdType = u_g.inner_l2cache.mmioBridge.entries_6.pCrdType;
    force u_i.inner_l2cache.mmioBridge.entries_6.u_core.denied = u_g.inner_l2cache.mmioBridge.entries_6.denied;
    force u_i.inner_l2cache.mmioBridge.entries_6.u_core.corrupt = u_g.inner_l2cache.mmioBridge.entries_6.corrupt;
    force u_i.inner_l2cache.mmioBridge.entries_6.u_core.traceTag = u_g.inner_l2cache.mmioBridge.entries_6.traceTag;
    force u_i.inner_l2cache.mmioBridge.entries_7.u_core.s_txreq = u_g.inner_l2cache.mmioBridge.entries_7.s_txreq;
    force u_i.inner_l2cache.mmioBridge.entries_7.u_core.s_ncbwrdata = u_g.inner_l2cache.mmioBridge.entries_7.s_ncbwrdata;
    force u_i.inner_l2cache.mmioBridge.entries_7.u_core.s_resp = u_g.inner_l2cache.mmioBridge.entries_7.s_resp;
    force u_i.inner_l2cache.mmioBridge.entries_7.u_core.w_comp = u_g.inner_l2cache.mmioBridge.entries_7.w_comp;
    force u_i.inner_l2cache.mmioBridge.entries_7.u_core.w_dbidresp = u_g.inner_l2cache.mmioBridge.entries_7.w_dbidresp;
    force u_i.inner_l2cache.mmioBridge.entries_7.u_core.w_compdata = u_g.inner_l2cache.mmioBridge.entries_7.w_compdata;
    force u_i.inner_l2cache.mmioBridge.entries_7.u_core.w_pcrdgrant = u_g.inner_l2cache.mmioBridge.entries_7.w_pcrdgrant;
    force u_i.inner_l2cache.mmioBridge.entries_7.u_core.w_readreceipt = u_g.inner_l2cache.mmioBridge.entries_7.w_readreceipt;
    force u_i.inner_l2cache.mmioBridge.entries_7.u_core.allowRetry = u_g.inner_l2cache.mmioBridge.entries_7.allowRetry;
    force u_i.inner_l2cache.mmioBridge.entries_7.u_core.req_opcode = u_g.inner_l2cache.mmioBridge.entries_7.req_opcode;
    force u_i.inner_l2cache.mmioBridge.entries_7.u_core.req_size = u_g.inner_l2cache.mmioBridge.entries_7.req_size;
    force u_i.inner_l2cache.mmioBridge.entries_7.u_core.req_source = u_g.inner_l2cache.mmioBridge.entries_7.req_source;
    force u_i.inner_l2cache.mmioBridge.entries_7.u_core.req_address = u_g.inner_l2cache.mmioBridge.entries_7.req_address;
    force u_i.inner_l2cache.mmioBridge.entries_7.u_core.req_user_memBackType_MM = u_g.inner_l2cache.mmioBridge.entries_7.req_user_memBackType_MM;
    force u_i.inner_l2cache.mmioBridge.entries_7.u_core.req_user_memPageType_NC = u_g.inner_l2cache.mmioBridge.entries_7.req_user_memPageType_NC;
    force u_i.inner_l2cache.mmioBridge.entries_7.u_core.req_mask = u_g.inner_l2cache.mmioBridge.entries_7.req_mask;
    force u_i.inner_l2cache.mmioBridge.entries_7.u_core.req_data = u_g.inner_l2cache.mmioBridge.entries_7.req_data;
    force u_i.inner_l2cache.mmioBridge.entries_7.u_core.req_corrupt = u_g.inner_l2cache.mmioBridge.entries_7.req_corrupt;
    force u_i.inner_l2cache.mmioBridge.entries_7.u_core.rdata = u_g.inner_l2cache.mmioBridge.entries_7.rdata;
    force u_i.inner_l2cache.mmioBridge.entries_7.u_core.srcID = u_g.inner_l2cache.mmioBridge.entries_7.srcID;
    force u_i.inner_l2cache.mmioBridge.entries_7.u_core.dbID = u_g.inner_l2cache.mmioBridge.entries_7.dbID;
    force u_i.inner_l2cache.mmioBridge.entries_7.u_core.pCrdType = u_g.inner_l2cache.mmioBridge.entries_7.pCrdType;
    force u_i.inner_l2cache.mmioBridge.entries_7.u_core.denied = u_g.inner_l2cache.mmioBridge.entries_7.denied;
    force u_i.inner_l2cache.mmioBridge.entries_7.u_core.corrupt = u_g.inner_l2cache.mmioBridge.entries_7.corrupt;
    force u_i.inner_l2cache.mmioBridge.entries_7.u_core.traceTag = u_g.inner_l2cache.mmioBridge.entries_7.traceTag;
    force u_i.inner_l2cache.mmioBridge.entries_8.u_core.s_txreq = u_g.inner_l2cache.mmioBridge.entries_8.s_txreq;
    force u_i.inner_l2cache.mmioBridge.entries_8.u_core.s_ncbwrdata = u_g.inner_l2cache.mmioBridge.entries_8.s_ncbwrdata;
    force u_i.inner_l2cache.mmioBridge.entries_8.u_core.s_resp = u_g.inner_l2cache.mmioBridge.entries_8.s_resp;
    force u_i.inner_l2cache.mmioBridge.entries_8.u_core.w_comp = u_g.inner_l2cache.mmioBridge.entries_8.w_comp;
    force u_i.inner_l2cache.mmioBridge.entries_8.u_core.w_dbidresp = u_g.inner_l2cache.mmioBridge.entries_8.w_dbidresp;
    force u_i.inner_l2cache.mmioBridge.entries_8.u_core.w_compdata = u_g.inner_l2cache.mmioBridge.entries_8.w_compdata;
    force u_i.inner_l2cache.mmioBridge.entries_8.u_core.w_pcrdgrant = u_g.inner_l2cache.mmioBridge.entries_8.w_pcrdgrant;
    force u_i.inner_l2cache.mmioBridge.entries_8.u_core.w_readreceipt = u_g.inner_l2cache.mmioBridge.entries_8.w_readreceipt;
    force u_i.inner_l2cache.mmioBridge.entries_8.u_core.allowRetry = u_g.inner_l2cache.mmioBridge.entries_8.allowRetry;
    force u_i.inner_l2cache.mmioBridge.entries_8.u_core.req_opcode = u_g.inner_l2cache.mmioBridge.entries_8.req_opcode;
    force u_i.inner_l2cache.mmioBridge.entries_8.u_core.req_size = u_g.inner_l2cache.mmioBridge.entries_8.req_size;
    force u_i.inner_l2cache.mmioBridge.entries_8.u_core.req_source = u_g.inner_l2cache.mmioBridge.entries_8.req_source;
    force u_i.inner_l2cache.mmioBridge.entries_8.u_core.req_address = u_g.inner_l2cache.mmioBridge.entries_8.req_address;
    force u_i.inner_l2cache.mmioBridge.entries_8.u_core.req_user_memBackType_MM = u_g.inner_l2cache.mmioBridge.entries_8.req_user_memBackType_MM;
    force u_i.inner_l2cache.mmioBridge.entries_8.u_core.req_user_memPageType_NC = u_g.inner_l2cache.mmioBridge.entries_8.req_user_memPageType_NC;
    force u_i.inner_l2cache.mmioBridge.entries_8.u_core.req_mask = u_g.inner_l2cache.mmioBridge.entries_8.req_mask;
    force u_i.inner_l2cache.mmioBridge.entries_8.u_core.req_data = u_g.inner_l2cache.mmioBridge.entries_8.req_data;
    force u_i.inner_l2cache.mmioBridge.entries_8.u_core.req_corrupt = u_g.inner_l2cache.mmioBridge.entries_8.req_corrupt;
    force u_i.inner_l2cache.mmioBridge.entries_8.u_core.rdata = u_g.inner_l2cache.mmioBridge.entries_8.rdata;
    force u_i.inner_l2cache.mmioBridge.entries_8.u_core.srcID = u_g.inner_l2cache.mmioBridge.entries_8.srcID;
    force u_i.inner_l2cache.mmioBridge.entries_8.u_core.dbID = u_g.inner_l2cache.mmioBridge.entries_8.dbID;
    force u_i.inner_l2cache.mmioBridge.entries_8.u_core.pCrdType = u_g.inner_l2cache.mmioBridge.entries_8.pCrdType;
    force u_i.inner_l2cache.mmioBridge.entries_8.u_core.denied = u_g.inner_l2cache.mmioBridge.entries_8.denied;
    force u_i.inner_l2cache.mmioBridge.entries_8.u_core.corrupt = u_g.inner_l2cache.mmioBridge.entries_8.corrupt;
    force u_i.inner_l2cache.mmioBridge.entries_8.u_core.traceTag = u_g.inner_l2cache.mmioBridge.entries_8.traceTag;
    force u_i.inner_l2cache.mmioBridge.entries_9.u_core.s_txreq = u_g.inner_l2cache.mmioBridge.entries_9.s_txreq;
    force u_i.inner_l2cache.mmioBridge.entries_9.u_core.s_ncbwrdata = u_g.inner_l2cache.mmioBridge.entries_9.s_ncbwrdata;
    force u_i.inner_l2cache.mmioBridge.entries_9.u_core.s_resp = u_g.inner_l2cache.mmioBridge.entries_9.s_resp;
    force u_i.inner_l2cache.mmioBridge.entries_9.u_core.w_comp = u_g.inner_l2cache.mmioBridge.entries_9.w_comp;
    force u_i.inner_l2cache.mmioBridge.entries_9.u_core.w_dbidresp = u_g.inner_l2cache.mmioBridge.entries_9.w_dbidresp;
    force u_i.inner_l2cache.mmioBridge.entries_9.u_core.w_compdata = u_g.inner_l2cache.mmioBridge.entries_9.w_compdata;
    force u_i.inner_l2cache.mmioBridge.entries_9.u_core.w_pcrdgrant = u_g.inner_l2cache.mmioBridge.entries_9.w_pcrdgrant;
    force u_i.inner_l2cache.mmioBridge.entries_9.u_core.w_readreceipt = u_g.inner_l2cache.mmioBridge.entries_9.w_readreceipt;
    force u_i.inner_l2cache.mmioBridge.entries_9.u_core.allowRetry = u_g.inner_l2cache.mmioBridge.entries_9.allowRetry;
    force u_i.inner_l2cache.mmioBridge.entries_9.u_core.req_opcode = u_g.inner_l2cache.mmioBridge.entries_9.req_opcode;
    force u_i.inner_l2cache.mmioBridge.entries_9.u_core.req_size = u_g.inner_l2cache.mmioBridge.entries_9.req_size;
    force u_i.inner_l2cache.mmioBridge.entries_9.u_core.req_source = u_g.inner_l2cache.mmioBridge.entries_9.req_source;
    force u_i.inner_l2cache.mmioBridge.entries_9.u_core.req_address = u_g.inner_l2cache.mmioBridge.entries_9.req_address;
    force u_i.inner_l2cache.mmioBridge.entries_9.u_core.req_user_memBackType_MM = u_g.inner_l2cache.mmioBridge.entries_9.req_user_memBackType_MM;
    force u_i.inner_l2cache.mmioBridge.entries_9.u_core.req_user_memPageType_NC = u_g.inner_l2cache.mmioBridge.entries_9.req_user_memPageType_NC;
    force u_i.inner_l2cache.mmioBridge.entries_9.u_core.req_mask = u_g.inner_l2cache.mmioBridge.entries_9.req_mask;
    force u_i.inner_l2cache.mmioBridge.entries_9.u_core.req_data = u_g.inner_l2cache.mmioBridge.entries_9.req_data;
    force u_i.inner_l2cache.mmioBridge.entries_9.u_core.req_corrupt = u_g.inner_l2cache.mmioBridge.entries_9.req_corrupt;
    force u_i.inner_l2cache.mmioBridge.entries_9.u_core.rdata = u_g.inner_l2cache.mmioBridge.entries_9.rdata;
    force u_i.inner_l2cache.mmioBridge.entries_9.u_core.srcID = u_g.inner_l2cache.mmioBridge.entries_9.srcID;
    force u_i.inner_l2cache.mmioBridge.entries_9.u_core.dbID = u_g.inner_l2cache.mmioBridge.entries_9.dbID;
    force u_i.inner_l2cache.mmioBridge.entries_9.u_core.pCrdType = u_g.inner_l2cache.mmioBridge.entries_9.pCrdType;
    force u_i.inner_l2cache.mmioBridge.entries_9.u_core.denied = u_g.inner_l2cache.mmioBridge.entries_9.denied;
    force u_i.inner_l2cache.mmioBridge.entries_9.u_core.corrupt = u_g.inner_l2cache.mmioBridge.entries_9.corrupt;
    force u_i.inner_l2cache.mmioBridge.entries_9.u_core.traceTag = u_g.inner_l2cache.mmioBridge.entries_9.traceTag;
    force u_i.inner_l2cache.mmioBridge.entries_10.u_core.s_txreq = u_g.inner_l2cache.mmioBridge.entries_10.s_txreq;
    force u_i.inner_l2cache.mmioBridge.entries_10.u_core.s_ncbwrdata = u_g.inner_l2cache.mmioBridge.entries_10.s_ncbwrdata;
    force u_i.inner_l2cache.mmioBridge.entries_10.u_core.s_resp = u_g.inner_l2cache.mmioBridge.entries_10.s_resp;
    force u_i.inner_l2cache.mmioBridge.entries_10.u_core.w_comp = u_g.inner_l2cache.mmioBridge.entries_10.w_comp;
    force u_i.inner_l2cache.mmioBridge.entries_10.u_core.w_dbidresp = u_g.inner_l2cache.mmioBridge.entries_10.w_dbidresp;
    force u_i.inner_l2cache.mmioBridge.entries_10.u_core.w_compdata = u_g.inner_l2cache.mmioBridge.entries_10.w_compdata;
    force u_i.inner_l2cache.mmioBridge.entries_10.u_core.w_pcrdgrant = u_g.inner_l2cache.mmioBridge.entries_10.w_pcrdgrant;
    force u_i.inner_l2cache.mmioBridge.entries_10.u_core.w_readreceipt = u_g.inner_l2cache.mmioBridge.entries_10.w_readreceipt;
    force u_i.inner_l2cache.mmioBridge.entries_10.u_core.allowRetry = u_g.inner_l2cache.mmioBridge.entries_10.allowRetry;
    force u_i.inner_l2cache.mmioBridge.entries_10.u_core.req_opcode = u_g.inner_l2cache.mmioBridge.entries_10.req_opcode;
    force u_i.inner_l2cache.mmioBridge.entries_10.u_core.req_size = u_g.inner_l2cache.mmioBridge.entries_10.req_size;
    force u_i.inner_l2cache.mmioBridge.entries_10.u_core.req_source = u_g.inner_l2cache.mmioBridge.entries_10.req_source;
    force u_i.inner_l2cache.mmioBridge.entries_10.u_core.req_address = u_g.inner_l2cache.mmioBridge.entries_10.req_address;
    force u_i.inner_l2cache.mmioBridge.entries_10.u_core.req_user_memBackType_MM = u_g.inner_l2cache.mmioBridge.entries_10.req_user_memBackType_MM;
    force u_i.inner_l2cache.mmioBridge.entries_10.u_core.req_user_memPageType_NC = u_g.inner_l2cache.mmioBridge.entries_10.req_user_memPageType_NC;
    force u_i.inner_l2cache.mmioBridge.entries_10.u_core.req_mask = u_g.inner_l2cache.mmioBridge.entries_10.req_mask;
    force u_i.inner_l2cache.mmioBridge.entries_10.u_core.req_data = u_g.inner_l2cache.mmioBridge.entries_10.req_data;
    force u_i.inner_l2cache.mmioBridge.entries_10.u_core.req_corrupt = u_g.inner_l2cache.mmioBridge.entries_10.req_corrupt;
    force u_i.inner_l2cache.mmioBridge.entries_10.u_core.rdata = u_g.inner_l2cache.mmioBridge.entries_10.rdata;
    force u_i.inner_l2cache.mmioBridge.entries_10.u_core.srcID = u_g.inner_l2cache.mmioBridge.entries_10.srcID;
    force u_i.inner_l2cache.mmioBridge.entries_10.u_core.dbID = u_g.inner_l2cache.mmioBridge.entries_10.dbID;
    force u_i.inner_l2cache.mmioBridge.entries_10.u_core.pCrdType = u_g.inner_l2cache.mmioBridge.entries_10.pCrdType;
    force u_i.inner_l2cache.mmioBridge.entries_10.u_core.denied = u_g.inner_l2cache.mmioBridge.entries_10.denied;
    force u_i.inner_l2cache.mmioBridge.entries_10.u_core.corrupt = u_g.inner_l2cache.mmioBridge.entries_10.corrupt;
    force u_i.inner_l2cache.mmioBridge.entries_10.u_core.traceTag = u_g.inner_l2cache.mmioBridge.entries_10.traceTag;
    force u_i.inner_l2cache.mmioBridge.entries_11.u_core.s_txreq = u_g.inner_l2cache.mmioBridge.entries_11.s_txreq;
    force u_i.inner_l2cache.mmioBridge.entries_11.u_core.s_ncbwrdata = u_g.inner_l2cache.mmioBridge.entries_11.s_ncbwrdata;
    force u_i.inner_l2cache.mmioBridge.entries_11.u_core.s_resp = u_g.inner_l2cache.mmioBridge.entries_11.s_resp;
    force u_i.inner_l2cache.mmioBridge.entries_11.u_core.w_comp = u_g.inner_l2cache.mmioBridge.entries_11.w_comp;
    force u_i.inner_l2cache.mmioBridge.entries_11.u_core.w_dbidresp = u_g.inner_l2cache.mmioBridge.entries_11.w_dbidresp;
    force u_i.inner_l2cache.mmioBridge.entries_11.u_core.w_compdata = u_g.inner_l2cache.mmioBridge.entries_11.w_compdata;
    force u_i.inner_l2cache.mmioBridge.entries_11.u_core.w_pcrdgrant = u_g.inner_l2cache.mmioBridge.entries_11.w_pcrdgrant;
    force u_i.inner_l2cache.mmioBridge.entries_11.u_core.w_readreceipt = u_g.inner_l2cache.mmioBridge.entries_11.w_readreceipt;
    force u_i.inner_l2cache.mmioBridge.entries_11.u_core.allowRetry = u_g.inner_l2cache.mmioBridge.entries_11.allowRetry;
    force u_i.inner_l2cache.mmioBridge.entries_11.u_core.req_opcode = u_g.inner_l2cache.mmioBridge.entries_11.req_opcode;
    force u_i.inner_l2cache.mmioBridge.entries_11.u_core.req_size = u_g.inner_l2cache.mmioBridge.entries_11.req_size;
    force u_i.inner_l2cache.mmioBridge.entries_11.u_core.req_source = u_g.inner_l2cache.mmioBridge.entries_11.req_source;
    force u_i.inner_l2cache.mmioBridge.entries_11.u_core.req_address = u_g.inner_l2cache.mmioBridge.entries_11.req_address;
    force u_i.inner_l2cache.mmioBridge.entries_11.u_core.req_user_memBackType_MM = u_g.inner_l2cache.mmioBridge.entries_11.req_user_memBackType_MM;
    force u_i.inner_l2cache.mmioBridge.entries_11.u_core.req_user_memPageType_NC = u_g.inner_l2cache.mmioBridge.entries_11.req_user_memPageType_NC;
    force u_i.inner_l2cache.mmioBridge.entries_11.u_core.req_mask = u_g.inner_l2cache.mmioBridge.entries_11.req_mask;
    force u_i.inner_l2cache.mmioBridge.entries_11.u_core.req_data = u_g.inner_l2cache.mmioBridge.entries_11.req_data;
    force u_i.inner_l2cache.mmioBridge.entries_11.u_core.req_corrupt = u_g.inner_l2cache.mmioBridge.entries_11.req_corrupt;
    force u_i.inner_l2cache.mmioBridge.entries_11.u_core.rdata = u_g.inner_l2cache.mmioBridge.entries_11.rdata;
    force u_i.inner_l2cache.mmioBridge.entries_11.u_core.srcID = u_g.inner_l2cache.mmioBridge.entries_11.srcID;
    force u_i.inner_l2cache.mmioBridge.entries_11.u_core.dbID = u_g.inner_l2cache.mmioBridge.entries_11.dbID;
    force u_i.inner_l2cache.mmioBridge.entries_11.u_core.pCrdType = u_g.inner_l2cache.mmioBridge.entries_11.pCrdType;
    force u_i.inner_l2cache.mmioBridge.entries_11.u_core.denied = u_g.inner_l2cache.mmioBridge.entries_11.denied;
    force u_i.inner_l2cache.mmioBridge.entries_11.u_core.corrupt = u_g.inner_l2cache.mmioBridge.entries_11.corrupt;
    force u_i.inner_l2cache.mmioBridge.entries_11.u_core.traceTag = u_g.inner_l2cache.mmioBridge.entries_11.traceTag;
    force u_i.inner_l2cache.mmioBridge.entries_12.u_core.s_txreq = u_g.inner_l2cache.mmioBridge.entries_12.s_txreq;
    force u_i.inner_l2cache.mmioBridge.entries_12.u_core.s_ncbwrdata = u_g.inner_l2cache.mmioBridge.entries_12.s_ncbwrdata;
    force u_i.inner_l2cache.mmioBridge.entries_12.u_core.s_resp = u_g.inner_l2cache.mmioBridge.entries_12.s_resp;
    force u_i.inner_l2cache.mmioBridge.entries_12.u_core.w_comp = u_g.inner_l2cache.mmioBridge.entries_12.w_comp;
    force u_i.inner_l2cache.mmioBridge.entries_12.u_core.w_dbidresp = u_g.inner_l2cache.mmioBridge.entries_12.w_dbidresp;
    force u_i.inner_l2cache.mmioBridge.entries_12.u_core.w_compdata = u_g.inner_l2cache.mmioBridge.entries_12.w_compdata;
    force u_i.inner_l2cache.mmioBridge.entries_12.u_core.w_pcrdgrant = u_g.inner_l2cache.mmioBridge.entries_12.w_pcrdgrant;
    force u_i.inner_l2cache.mmioBridge.entries_12.u_core.w_readreceipt = u_g.inner_l2cache.mmioBridge.entries_12.w_readreceipt;
    force u_i.inner_l2cache.mmioBridge.entries_12.u_core.allowRetry = u_g.inner_l2cache.mmioBridge.entries_12.allowRetry;
    force u_i.inner_l2cache.mmioBridge.entries_12.u_core.req_opcode = u_g.inner_l2cache.mmioBridge.entries_12.req_opcode;
    force u_i.inner_l2cache.mmioBridge.entries_12.u_core.req_size = u_g.inner_l2cache.mmioBridge.entries_12.req_size;
    force u_i.inner_l2cache.mmioBridge.entries_12.u_core.req_source = u_g.inner_l2cache.mmioBridge.entries_12.req_source;
    force u_i.inner_l2cache.mmioBridge.entries_12.u_core.req_address = u_g.inner_l2cache.mmioBridge.entries_12.req_address;
    force u_i.inner_l2cache.mmioBridge.entries_12.u_core.req_user_memBackType_MM = u_g.inner_l2cache.mmioBridge.entries_12.req_user_memBackType_MM;
    force u_i.inner_l2cache.mmioBridge.entries_12.u_core.req_user_memPageType_NC = u_g.inner_l2cache.mmioBridge.entries_12.req_user_memPageType_NC;
    force u_i.inner_l2cache.mmioBridge.entries_12.u_core.req_mask = u_g.inner_l2cache.mmioBridge.entries_12.req_mask;
    force u_i.inner_l2cache.mmioBridge.entries_12.u_core.req_data = u_g.inner_l2cache.mmioBridge.entries_12.req_data;
    force u_i.inner_l2cache.mmioBridge.entries_12.u_core.req_corrupt = u_g.inner_l2cache.mmioBridge.entries_12.req_corrupt;
    force u_i.inner_l2cache.mmioBridge.entries_12.u_core.rdata = u_g.inner_l2cache.mmioBridge.entries_12.rdata;
    force u_i.inner_l2cache.mmioBridge.entries_12.u_core.srcID = u_g.inner_l2cache.mmioBridge.entries_12.srcID;
    force u_i.inner_l2cache.mmioBridge.entries_12.u_core.dbID = u_g.inner_l2cache.mmioBridge.entries_12.dbID;
    force u_i.inner_l2cache.mmioBridge.entries_12.u_core.pCrdType = u_g.inner_l2cache.mmioBridge.entries_12.pCrdType;
    force u_i.inner_l2cache.mmioBridge.entries_12.u_core.denied = u_g.inner_l2cache.mmioBridge.entries_12.denied;
    force u_i.inner_l2cache.mmioBridge.entries_12.u_core.corrupt = u_g.inner_l2cache.mmioBridge.entries_12.corrupt;
    force u_i.inner_l2cache.mmioBridge.entries_12.u_core.traceTag = u_g.inner_l2cache.mmioBridge.entries_12.traceTag;
    force u_i.inner_l2cache.mmioBridge.entries_13.u_core.s_txreq = u_g.inner_l2cache.mmioBridge.entries_13.s_txreq;
    force u_i.inner_l2cache.mmioBridge.entries_13.u_core.s_ncbwrdata = u_g.inner_l2cache.mmioBridge.entries_13.s_ncbwrdata;
    force u_i.inner_l2cache.mmioBridge.entries_13.u_core.s_resp = u_g.inner_l2cache.mmioBridge.entries_13.s_resp;
    force u_i.inner_l2cache.mmioBridge.entries_13.u_core.w_comp = u_g.inner_l2cache.mmioBridge.entries_13.w_comp;
    force u_i.inner_l2cache.mmioBridge.entries_13.u_core.w_dbidresp = u_g.inner_l2cache.mmioBridge.entries_13.w_dbidresp;
    force u_i.inner_l2cache.mmioBridge.entries_13.u_core.w_compdata = u_g.inner_l2cache.mmioBridge.entries_13.w_compdata;
    force u_i.inner_l2cache.mmioBridge.entries_13.u_core.w_pcrdgrant = u_g.inner_l2cache.mmioBridge.entries_13.w_pcrdgrant;
    force u_i.inner_l2cache.mmioBridge.entries_13.u_core.w_readreceipt = u_g.inner_l2cache.mmioBridge.entries_13.w_readreceipt;
    force u_i.inner_l2cache.mmioBridge.entries_13.u_core.allowRetry = u_g.inner_l2cache.mmioBridge.entries_13.allowRetry;
    force u_i.inner_l2cache.mmioBridge.entries_13.u_core.req_opcode = u_g.inner_l2cache.mmioBridge.entries_13.req_opcode;
    force u_i.inner_l2cache.mmioBridge.entries_13.u_core.req_size = u_g.inner_l2cache.mmioBridge.entries_13.req_size;
    force u_i.inner_l2cache.mmioBridge.entries_13.u_core.req_source = u_g.inner_l2cache.mmioBridge.entries_13.req_source;
    force u_i.inner_l2cache.mmioBridge.entries_13.u_core.req_address = u_g.inner_l2cache.mmioBridge.entries_13.req_address;
    force u_i.inner_l2cache.mmioBridge.entries_13.u_core.req_user_memBackType_MM = u_g.inner_l2cache.mmioBridge.entries_13.req_user_memBackType_MM;
    force u_i.inner_l2cache.mmioBridge.entries_13.u_core.req_user_memPageType_NC = u_g.inner_l2cache.mmioBridge.entries_13.req_user_memPageType_NC;
    force u_i.inner_l2cache.mmioBridge.entries_13.u_core.req_mask = u_g.inner_l2cache.mmioBridge.entries_13.req_mask;
    force u_i.inner_l2cache.mmioBridge.entries_13.u_core.req_data = u_g.inner_l2cache.mmioBridge.entries_13.req_data;
    force u_i.inner_l2cache.mmioBridge.entries_13.u_core.req_corrupt = u_g.inner_l2cache.mmioBridge.entries_13.req_corrupt;
    force u_i.inner_l2cache.mmioBridge.entries_13.u_core.rdata = u_g.inner_l2cache.mmioBridge.entries_13.rdata;
    force u_i.inner_l2cache.mmioBridge.entries_13.u_core.srcID = u_g.inner_l2cache.mmioBridge.entries_13.srcID;
    force u_i.inner_l2cache.mmioBridge.entries_13.u_core.dbID = u_g.inner_l2cache.mmioBridge.entries_13.dbID;
    force u_i.inner_l2cache.mmioBridge.entries_13.u_core.pCrdType = u_g.inner_l2cache.mmioBridge.entries_13.pCrdType;
    force u_i.inner_l2cache.mmioBridge.entries_13.u_core.denied = u_g.inner_l2cache.mmioBridge.entries_13.denied;
    force u_i.inner_l2cache.mmioBridge.entries_13.u_core.corrupt = u_g.inner_l2cache.mmioBridge.entries_13.corrupt;
    force u_i.inner_l2cache.mmioBridge.entries_13.u_core.traceTag = u_g.inner_l2cache.mmioBridge.entries_13.traceTag;
    force u_i.inner_l2cache.mmioBridge.entries_14.u_core.s_txreq = u_g.inner_l2cache.mmioBridge.entries_14.s_txreq;
    force u_i.inner_l2cache.mmioBridge.entries_14.u_core.s_ncbwrdata = u_g.inner_l2cache.mmioBridge.entries_14.s_ncbwrdata;
    force u_i.inner_l2cache.mmioBridge.entries_14.u_core.s_resp = u_g.inner_l2cache.mmioBridge.entries_14.s_resp;
    force u_i.inner_l2cache.mmioBridge.entries_14.u_core.w_comp = u_g.inner_l2cache.mmioBridge.entries_14.w_comp;
    force u_i.inner_l2cache.mmioBridge.entries_14.u_core.w_dbidresp = u_g.inner_l2cache.mmioBridge.entries_14.w_dbidresp;
    force u_i.inner_l2cache.mmioBridge.entries_14.u_core.w_compdata = u_g.inner_l2cache.mmioBridge.entries_14.w_compdata;
    force u_i.inner_l2cache.mmioBridge.entries_14.u_core.w_pcrdgrant = u_g.inner_l2cache.mmioBridge.entries_14.w_pcrdgrant;
    force u_i.inner_l2cache.mmioBridge.entries_14.u_core.w_readreceipt = u_g.inner_l2cache.mmioBridge.entries_14.w_readreceipt;
    force u_i.inner_l2cache.mmioBridge.entries_14.u_core.allowRetry = u_g.inner_l2cache.mmioBridge.entries_14.allowRetry;
    force u_i.inner_l2cache.mmioBridge.entries_14.u_core.req_opcode = u_g.inner_l2cache.mmioBridge.entries_14.req_opcode;
    force u_i.inner_l2cache.mmioBridge.entries_14.u_core.req_size = u_g.inner_l2cache.mmioBridge.entries_14.req_size;
    force u_i.inner_l2cache.mmioBridge.entries_14.u_core.req_source = u_g.inner_l2cache.mmioBridge.entries_14.req_source;
    force u_i.inner_l2cache.mmioBridge.entries_14.u_core.req_address = u_g.inner_l2cache.mmioBridge.entries_14.req_address;
    force u_i.inner_l2cache.mmioBridge.entries_14.u_core.req_user_memBackType_MM = u_g.inner_l2cache.mmioBridge.entries_14.req_user_memBackType_MM;
    force u_i.inner_l2cache.mmioBridge.entries_14.u_core.req_user_memPageType_NC = u_g.inner_l2cache.mmioBridge.entries_14.req_user_memPageType_NC;
    force u_i.inner_l2cache.mmioBridge.entries_14.u_core.req_mask = u_g.inner_l2cache.mmioBridge.entries_14.req_mask;
    force u_i.inner_l2cache.mmioBridge.entries_14.u_core.req_data = u_g.inner_l2cache.mmioBridge.entries_14.req_data;
    force u_i.inner_l2cache.mmioBridge.entries_14.u_core.req_corrupt = u_g.inner_l2cache.mmioBridge.entries_14.req_corrupt;
    force u_i.inner_l2cache.mmioBridge.entries_14.u_core.rdata = u_g.inner_l2cache.mmioBridge.entries_14.rdata;
    force u_i.inner_l2cache.mmioBridge.entries_14.u_core.srcID = u_g.inner_l2cache.mmioBridge.entries_14.srcID;
    force u_i.inner_l2cache.mmioBridge.entries_14.u_core.dbID = u_g.inner_l2cache.mmioBridge.entries_14.dbID;
    force u_i.inner_l2cache.mmioBridge.entries_14.u_core.pCrdType = u_g.inner_l2cache.mmioBridge.entries_14.pCrdType;
    force u_i.inner_l2cache.mmioBridge.entries_14.u_core.denied = u_g.inner_l2cache.mmioBridge.entries_14.denied;
    force u_i.inner_l2cache.mmioBridge.entries_14.u_core.corrupt = u_g.inner_l2cache.mmioBridge.entries_14.corrupt;
    force u_i.inner_l2cache.mmioBridge.entries_14.u_core.traceTag = u_g.inner_l2cache.mmioBridge.entries_14.traceTag;
    force u_i.inner_l2cache.mmioBridge.entries_15.u_core.s_txreq = u_g.inner_l2cache.mmioBridge.entries_15.s_txreq;
    force u_i.inner_l2cache.mmioBridge.entries_15.u_core.s_ncbwrdata = u_g.inner_l2cache.mmioBridge.entries_15.s_ncbwrdata;
    force u_i.inner_l2cache.mmioBridge.entries_15.u_core.s_resp = u_g.inner_l2cache.mmioBridge.entries_15.s_resp;
    force u_i.inner_l2cache.mmioBridge.entries_15.u_core.w_comp = u_g.inner_l2cache.mmioBridge.entries_15.w_comp;
    force u_i.inner_l2cache.mmioBridge.entries_15.u_core.w_dbidresp = u_g.inner_l2cache.mmioBridge.entries_15.w_dbidresp;
    force u_i.inner_l2cache.mmioBridge.entries_15.u_core.w_compdata = u_g.inner_l2cache.mmioBridge.entries_15.w_compdata;
    force u_i.inner_l2cache.mmioBridge.entries_15.u_core.w_pcrdgrant = u_g.inner_l2cache.mmioBridge.entries_15.w_pcrdgrant;
    force u_i.inner_l2cache.mmioBridge.entries_15.u_core.w_readreceipt = u_g.inner_l2cache.mmioBridge.entries_15.w_readreceipt;
    force u_i.inner_l2cache.mmioBridge.entries_15.u_core.allowRetry = u_g.inner_l2cache.mmioBridge.entries_15.allowRetry;
    force u_i.inner_l2cache.mmioBridge.entries_15.u_core.req_opcode = u_g.inner_l2cache.mmioBridge.entries_15.req_opcode;
    force u_i.inner_l2cache.mmioBridge.entries_15.u_core.req_size = u_g.inner_l2cache.mmioBridge.entries_15.req_size;
    force u_i.inner_l2cache.mmioBridge.entries_15.u_core.req_source = u_g.inner_l2cache.mmioBridge.entries_15.req_source;
    force u_i.inner_l2cache.mmioBridge.entries_15.u_core.req_address = u_g.inner_l2cache.mmioBridge.entries_15.req_address;
    force u_i.inner_l2cache.mmioBridge.entries_15.u_core.req_user_memBackType_MM = u_g.inner_l2cache.mmioBridge.entries_15.req_user_memBackType_MM;
    force u_i.inner_l2cache.mmioBridge.entries_15.u_core.req_user_memPageType_NC = u_g.inner_l2cache.mmioBridge.entries_15.req_user_memPageType_NC;
    force u_i.inner_l2cache.mmioBridge.entries_15.u_core.req_mask = u_g.inner_l2cache.mmioBridge.entries_15.req_mask;
    force u_i.inner_l2cache.mmioBridge.entries_15.u_core.req_data = u_g.inner_l2cache.mmioBridge.entries_15.req_data;
    force u_i.inner_l2cache.mmioBridge.entries_15.u_core.req_corrupt = u_g.inner_l2cache.mmioBridge.entries_15.req_corrupt;
    force u_i.inner_l2cache.mmioBridge.entries_15.u_core.rdata = u_g.inner_l2cache.mmioBridge.entries_15.rdata;
    force u_i.inner_l2cache.mmioBridge.entries_15.u_core.srcID = u_g.inner_l2cache.mmioBridge.entries_15.srcID;
    force u_i.inner_l2cache.mmioBridge.entries_15.u_core.dbID = u_g.inner_l2cache.mmioBridge.entries_15.dbID;
    force u_i.inner_l2cache.mmioBridge.entries_15.u_core.pCrdType = u_g.inner_l2cache.mmioBridge.entries_15.pCrdType;
    force u_i.inner_l2cache.mmioBridge.entries_15.u_core.denied = u_g.inner_l2cache.mmioBridge.entries_15.denied;
    force u_i.inner_l2cache.mmioBridge.entries_15.u_core.corrupt = u_g.inner_l2cache.mmioBridge.entries_15.corrupt;
    force u_i.inner_l2cache.mmioBridge.entries_15.u_core.traceTag = u_g.inner_l2cache.mmioBridge.entries_15.traceTag;
    force u_i.inner_l2cache.mbistPl.u_core.g_node_return.pipelineDataOutReg = u_g.inner_l2cache.mbistPl.pipelineDataOutReg;
    u_i.inner_l2cache.pCrdQueue_s2.ram_ext.Memory = u_g.inner_l2cache.pCrdQueue_s2.ram_ext.Memory;
    u_i.inner_l2cache.pCrdQueue_s3.ram_ext.Memory = u_g.inner_l2cache.pCrdQueue_s3.ram_ext.Memory;
    u_i.inner_l2cache.linkMonitor.LCredit2Decoupled_rxsnp.u_core.queue.ram_ext.Memory = u_g.inner_l2cache.linkMonitor.LCredit2Decoupled_rxsnp.queue.ram_ext.Memory;
    u_i.inner_buffer.u_bank_0.nodeOut_a_q.ram_ext.Memory = u_g.inner_buffer.nodeOut_a_q.ram_ext.Memory;
    u_i.inner_buffer.u_bank_0.nodeIn_d_q.ram_ext.Memory = u_g.inner_buffer.nodeIn_d_q.ram_ext.Memory;
    u_i.inner_buffer.u_bank_0.nodeIn_b_q.ram_ext.Memory = u_g.inner_buffer.nodeIn_b_q.ram_ext.Memory;
    u_i.inner_buffer.u_bank_0.nodeOut_c_q.ram_ext.Memory = u_g.inner_buffer.nodeOut_c_q.ram_ext.Memory;
    u_i.inner_buffer.u_bank_0.nodeOut_e_q.ram_sink_ext.Memory = u_g.inner_buffer.nodeOut_e_q.ram_sink_ext.Memory;
    u_i.inner_buffer.u_bank_1.nodeOut_a_q.ram_ext.Memory = u_g.inner_buffer.nodeOut_a_q_1.ram_ext.Memory;
    u_i.inner_buffer.u_bank_1.nodeIn_d_q.ram_ext.Memory = u_g.inner_buffer.nodeIn_d_q_1.ram_ext.Memory;
    u_i.inner_buffer.u_bank_1.nodeIn_b_q.ram_ext.Memory = u_g.inner_buffer.nodeIn_b_q_1.ram_ext.Memory;
    u_i.inner_buffer.u_bank_1.nodeOut_c_q.ram_ext.Memory = u_g.inner_buffer.nodeOut_c_q_1.ram_ext.Memory;
    u_i.inner_buffer.u_bank_1.nodeOut_e_q.ram_sink_ext.Memory = u_g.inner_buffer.nodeOut_e_q_1.ram_sink_ext.Memory;
    u_i.inner_buffer.u_bank_2.nodeOut_a_q.ram_ext.Memory = u_g.inner_buffer.nodeOut_a_q_2.ram_ext.Memory;
    u_i.inner_buffer.u_bank_2.nodeIn_d_q.ram_ext.Memory = u_g.inner_buffer.nodeIn_d_q_2.ram_ext.Memory;
    u_i.inner_buffer.u_bank_2.nodeIn_b_q.ram_ext.Memory = u_g.inner_buffer.nodeIn_b_q_2.ram_ext.Memory;
    u_i.inner_buffer.u_bank_2.nodeOut_c_q.ram_ext.Memory = u_g.inner_buffer.nodeOut_c_q_2.ram_ext.Memory;
    u_i.inner_buffer.u_bank_2.nodeOut_e_q.ram_sink_ext.Memory = u_g.inner_buffer.nodeOut_e_q_2.ram_sink_ext.Memory;
    u_i.inner_buffer.u_bank_3.nodeOut_a_q.ram_ext.Memory = u_g.inner_buffer.nodeOut_a_q_3.ram_ext.Memory;
    u_i.inner_buffer.u_bank_3.nodeIn_d_q.ram_ext.Memory = u_g.inner_buffer.nodeIn_d_q_3.ram_ext.Memory;
    u_i.inner_buffer.u_bank_3.nodeIn_b_q.ram_ext.Memory = u_g.inner_buffer.nodeIn_b_q_3.ram_ext.Memory;
    u_i.inner_buffer.u_bank_3.nodeOut_c_q.ram_ext.Memory = u_g.inner_buffer.nodeOut_c_q_3.ram_ext.Memory;
    u_i.inner_buffer.u_bank_3.nodeOut_e_q.ram_sink_ext.Memory = u_g.inner_buffer.nodeOut_e_q_3.ram_sink_ext.Memory;
    u_i.inner_ptw_to_l2_buffer.nodeOut_a_q.ram_ext.Memory = u_g.inner_ptw_to_l2_buffer.nodeOut_a_q.ram_ext.Memory;
    u_i.inner_ptw_to_l2_buffer.nodeIn_d_q.ram_ext.Memory = u_g.inner_ptw_to_l2_buffer.nodeIn_d_q.ram_ext.Memory;
    u_i.inner_i_mmio_buffer.nodeOut_a_q.ram_ext.Memory = u_g.inner_i_mmio_buffer.nodeOut_a_q.ram_ext.Memory;
    u_i.inner_i_mmio_buffer.nodeIn_d_q.ram_ext.Memory = u_g.inner_i_mmio_buffer.nodeIn_d_q.ram_ext.Memory;
    u_i.inner_buffers.nodeOut_a_q.ram_ext.Memory = u_g.inner_buffers.nodeOut_a_q.ram_ext.Memory;
    u_i.inner_buffers.nodeIn_d_q.ram_ext.Memory = u_g.inner_buffers.nodeIn_d_q.ram_ext.Memory;
    u_i.inner_buffers_1.nodeOut_a_q.ram_ext.Memory = u_g.inner_buffers_1.nodeOut_a_q.ram_ext.Memory;
    u_i.inner_buffers_1.nodeIn_d_q.ram_ext.Memory = u_g.inner_buffers_1.nodeIn_d_q.ram_ext.Memory;
    u_i.inner_buffers_2.nodeOut_a_q.ram_ext.Memory = u_g.inner_buffers_2.nodeOut_a_q.ram_ext.Memory;
    u_i.inner_buffers_2.nodeIn_d_q.ram_ext.Memory = u_g.inner_buffers_2.nodeIn_d_q.ram_ext.Memory;
    u_i.inner_buffers_3.nodeOut_a_q.ram_ext.Memory = u_g.inner_buffers_3.nodeOut_a_q.ram_ext.Memory;
    u_i.inner_buffers_3.nodeIn_d_q.ram_ext.Memory = u_g.inner_buffers_3.nodeIn_d_q.ram_ext.Memory;
    u_i.inner_buffers_4.nodeOut_a_q.ram_ext.Memory = u_g.inner_buffers_4.nodeOut_a_q.ram_ext.Memory;
    u_i.inner_buffers_4.nodeIn_d_q.ram_ext.Memory = u_g.inner_buffers_4.nodeIn_d_q.ram_ext.Memory;
    u_i.inner_buffers_5.nodeOut_a_q.ram_ext.Memory = u_g.inner_buffers_5.nodeOut_a_q.ram_ext.Memory;
    u_i.inner_buffers_5.nodeIn_d_q.ram_ext.Memory = u_g.inner_buffers_5.nodeIn_d_q.ram_ext.Memory;
    u_i.inner_buffer_1.nodeOut_a_q.ram_ext.Memory = u_g.inner_buffer_1.nodeOut_a_q.ram_ext.Memory;
    u_i.inner_buffer_1.nodeIn_d_q.ram_ext.Memory = u_g.inner_buffer_1.nodeIn_d_q.ram_ext.Memory;
    force u_i.u_core.msiToCore_bits = u_g.inner_io_msiInfo_toCore_bits_r;
    force u_i.u_core.traceOut_trapCause = u_g.inner_io_traceCoreInterface_toTile_toEncoder_trap_r_cause;
    force u_i.u_core.traceOut_trapTval = u_g.inner_io_traceCoreInterface_toTile_toEncoder_trap_r_tval;
    force u_i.u_core.traceOut_priv = u_g.inner_io_traceCoreInterface_toTile_toEncoder_priv_r;
    force u_i.inner_io_clintTime_toCore_pipMod.u_core.g_chain.data_q[0] = u_g.inner_io_clintTime_toCore_pipMod.res_bits;
    force u_i.u_core.traceOut_ilastsize[0] = u_g.inner_io_traceCoreInterface_toTile_toEncoder_groups_0_bits_ilastsize_r;
    force u_i.u_core.traceOut_iaddr[0] = u_g.inner_io_traceCoreInterface_toTile_toEncoder_groups_0_bits_iaddr_r;
    force u_i.u_core.traceOut_ilastsize[1] = u_g.inner_io_traceCoreInterface_toTile_toEncoder_groups_1_bits_ilastsize_r;
    force u_i.u_core.traceOut_iaddr[1] = u_g.inner_io_traceCoreInterface_toTile_toEncoder_groups_1_bits_iaddr_r;
    force u_i.u_core.traceOut_ilastsize[2] = u_g.inner_io_traceCoreInterface_toTile_toEncoder_groups_2_bits_ilastsize_r;
    force u_i.u_core.traceOut_iaddr[2] = u_g.inner_io_traceCoreInterface_toTile_toEncoder_groups_2_bits_iaddr_r;
    force u_i.inner_xbar.u_core.g_out_a[0].u_arb.beats_left = u_g.inner_xbar.beatsLeft;
    force u_i.inner_xbar.u_core.g_out_a[0].u_arb.mask = u_g.inner_xbar.readys_mask;
    force u_i.inner_xbar.u_core.g_out_a[0].u_arb.state = {u_g.inner_xbar.state_2, u_g.inner_xbar.state_1, u_g.inner_xbar.state_0};
    force u_i.inner_xbar.u_core.g_out_a[1].u_arb.beats_left = u_g.inner_xbar.beatsLeft_1;
    force u_i.inner_xbar.u_core.g_out_a[1].u_arb.mask = u_g.inner_xbar.readys_mask_1;
    force u_i.inner_xbar.u_core.g_out_a[1].u_arb.state = {u_g.inner_xbar.state_1_2, u_g.inner_xbar.state_1_1, u_g.inner_xbar.state_1_0};
    force u_i.inner_xbar.u_core.g_out_a[2].u_arb.beats_left = u_g.inner_xbar.beatsLeft_2;
    force u_i.inner_xbar.u_core.g_out_a[2].u_arb.mask = u_g.inner_xbar.readys_mask_2;
    force u_i.inner_xbar.u_core.g_out_a[2].u_arb.state = {u_g.inner_xbar.state_2_2, u_g.inner_xbar.state_2_1, u_g.inner_xbar.state_2_0};
    force u_i.inner_xbar.u_core.g_out_a[3].u_arb.beats_left = u_g.inner_xbar.beatsLeft_3;
    force u_i.inner_xbar.u_core.g_out_a[3].u_arb.mask = u_g.inner_xbar.readys_mask_3;
    force u_i.inner_xbar.u_core.g_out_a[3].u_arb.state = {u_g.inner_xbar.state_3_2, u_g.inner_xbar.state_3_1, u_g.inner_xbar.state_3_0};
    force u_i.inner_xbar.u_core.u_arb_b.beats_left = u_g.inner_xbar.beatsLeft_4;
    force u_i.inner_xbar.u_core.u_arb_b.mask = u_g.inner_xbar.readys_mask_4;
    force u_i.inner_xbar.u_core.u_arb_b.state = {u_g.inner_xbar.state_4_3, u_g.inner_xbar.state_4_2, u_g.inner_xbar.state_4_1, u_g.inner_xbar.state_4_0};
    force u_i.inner_xbar.u_core.g_in_d[0].u_arb.beats_left = u_g.inner_xbar.beatsLeft_5;
    force u_i.inner_xbar.u_core.g_in_d[0].u_arb.mask = u_g.inner_xbar.readys_mask_5;
    force u_i.inner_xbar.u_core.g_in_d[0].u_arb.state = {u_g.inner_xbar.state_5_3, u_g.inner_xbar.state_5_2, u_g.inner_xbar.state_5_1, u_g.inner_xbar.state_5_0};
    force u_i.inner_xbar.u_core.g_in_d[1].u_arb.beats_left = u_g.inner_xbar.beatsLeft_6;
    force u_i.inner_xbar.u_core.g_in_d[1].u_arb.mask = u_g.inner_xbar.readys_mask_6;
    force u_i.inner_xbar.u_core.g_in_d[1].u_arb.state = {u_g.inner_xbar.state_6_3, u_g.inner_xbar.state_6_2, u_g.inner_xbar.state_6_1, u_g.inner_xbar.state_6_0};
    force u_i.inner_xbar.u_core.g_in_d[2].u_arb.beats_left = u_g.inner_xbar.beatsLeft_7;
    force u_i.inner_xbar.u_core.g_in_d[2].u_arb.mask = u_g.inner_xbar.readys_mask_7;
    force u_i.inner_xbar.u_core.g_in_d[2].u_arb.state = {u_g.inner_xbar.state_7_3, u_g.inner_xbar.state_7_2, u_g.inner_xbar.state_7_1, u_g.inner_xbar.state_7_0};
    force u_i.inner_xbar_1.u_core.g_out_a[0].u_arb.beats_left = u_g.inner_xbar_1.beatsLeft;
    force u_i.inner_xbar_1.u_core.g_out_a[0].u_arb.mask = u_g.inner_xbar_1.readys_mask;
    force u_i.inner_xbar_1.u_core.g_out_a[0].u_arb.state = {u_g.inner_xbar_1.state_1, u_g.inner_xbar_1.state_0};
    force u_i.inner_xbar_1.u_core.g_out_a[1].u_arb.beats_left = u_g.inner_xbar_1.beatsLeft_1;
    force u_i.inner_xbar_1.u_core.g_out_a[1].u_arb.mask = u_g.inner_xbar_1.readys_mask_1;
    force u_i.inner_xbar_1.u_core.g_out_a[1].u_arb.state = {u_g.inner_xbar_1.state_1_1, u_g.inner_xbar_1.state_1_0};
    force u_i.inner_xbar_1.u_core.g_out_a[2].u_arb.beats_left = u_g.inner_xbar_1.beatsLeft_2;
    force u_i.inner_xbar_1.u_core.g_out_a[2].u_arb.mask = u_g.inner_xbar_1.readys_mask_2;
    force u_i.inner_xbar_1.u_core.g_out_a[2].u_arb.state = {u_g.inner_xbar_1.state_2_1, u_g.inner_xbar_1.state_2_0};
    force u_i.inner_xbar_1.u_core.g_in_d[0].u_arb.beats_left = u_g.inner_xbar_1.beatsLeft_3;
    force u_i.inner_xbar_1.u_core.g_in_d[0].u_arb.mask = u_g.inner_xbar_1.readys_mask_3;
    force u_i.inner_xbar_1.u_core.g_in_d[0].u_arb.state = {u_g.inner_xbar_1.state_3_2, u_g.inner_xbar_1.state_3_1, u_g.inner_xbar_1.state_3_0};
    force u_i.inner_xbar_1.u_core.g_in_d[1].u_arb.beats_left = u_g.inner_xbar_1.beatsLeft_4;
    force u_i.inner_xbar_1.u_core.g_in_d[1].u_arb.mask = u_g.inner_xbar_1.readys_mask_4;
    force u_i.inner_xbar_1.u_core.g_in_d[1].u_arb.state = {u_g.inner_xbar_1.state_4_2, u_g.inner_xbar_1.state_4_1, u_g.inner_xbar_1.state_4_0};
    #1;
    release u_i.inner_l2cache.slices_0.u_core.mshrCtl.u_core.mshrs[0].entry.u_core.tgtid_rcompack;
    release u_i.inner_l2cache.slices_0.u_core.mshrCtl.u_core.mshrs[0].entry.u_core.txnid_rcompack;
    release u_i.inner_l2cache.slices_0.u_core.mshrCtl.u_core.mshrs[0].entry.u_core.tgtid_wcompack;
    release u_i.inner_l2cache.slices_0.u_core.mshrCtl.u_core.mshrs[0].entry.u_core.txnid_wcompack;
    release u_i.inner_l2cache.slices_0.u_core.mshrCtl.u_core.mshrs[0].entry.u_core.srcid_retryack;
    release u_i.inner_l2cache.slices_0.u_core.mshrCtl.u_core.mshrs[0].entry.u_core.acquire_ts;
    release u_i.inner_l2cache.slices_0.u_core.mshrCtl.u_core.mshrs[0].entry.u_core.release_ts;
    release u_i.inner_l2cache.slices_0.u_core.mshrCtl.u_core.mshrs[0].entry.u_core.acquire_period_valid_REG;
    release u_i.inner_l2cache.slices_0.u_core.mshrCtl.u_core.mshrs[0].entry.u_core.release_period_valid_REG;
    release u_i.inner_l2cache.slices_0.u_core.mshrCtl.u_core.mshrs[0].entry.u_core.REG;
    release u_i.inner_l2cache.slices_0.u_core.mshrCtl.u_core.mshrs[0].entry.u_core.REG_1;
    release u_i.inner_l2cache.slices_0.u_core.mshrCtl.u_core.mshrs[0].entry.u_core.REG_2;
    release u_i.inner_l2cache.slices_0.u_core.mshrCtl.u_core.mshrs[0].entry.u_core.REG_3;
    release u_i.inner_l2cache.slices_0.u_core.mshrCtl.u_core.mshrs[1].entry.u_core.tgtid_rcompack;
    release u_i.inner_l2cache.slices_0.u_core.mshrCtl.u_core.mshrs[1].entry.u_core.txnid_rcompack;
    release u_i.inner_l2cache.slices_0.u_core.mshrCtl.u_core.mshrs[1].entry.u_core.tgtid_wcompack;
    release u_i.inner_l2cache.slices_0.u_core.mshrCtl.u_core.mshrs[1].entry.u_core.txnid_wcompack;
    release u_i.inner_l2cache.slices_0.u_core.mshrCtl.u_core.mshrs[1].entry.u_core.srcid_retryack;
    release u_i.inner_l2cache.slices_0.u_core.mshrCtl.u_core.mshrs[1].entry.u_core.acquire_ts;
    release u_i.inner_l2cache.slices_0.u_core.mshrCtl.u_core.mshrs[1].entry.u_core.release_ts;
    release u_i.inner_l2cache.slices_0.u_core.mshrCtl.u_core.mshrs[1].entry.u_core.acquire_period_valid_REG;
    release u_i.inner_l2cache.slices_0.u_core.mshrCtl.u_core.mshrs[1].entry.u_core.release_period_valid_REG;
    release u_i.inner_l2cache.slices_0.u_core.mshrCtl.u_core.mshrs[1].entry.u_core.REG;
    release u_i.inner_l2cache.slices_0.u_core.mshrCtl.u_core.mshrs[1].entry.u_core.REG_1;
    release u_i.inner_l2cache.slices_0.u_core.mshrCtl.u_core.mshrs[1].entry.u_core.REG_2;
    release u_i.inner_l2cache.slices_0.u_core.mshrCtl.u_core.mshrs[1].entry.u_core.REG_3;
    release u_i.inner_l2cache.slices_0.u_core.mshrCtl.u_core.mshrs[2].entry.u_core.tgtid_rcompack;
    release u_i.inner_l2cache.slices_0.u_core.mshrCtl.u_core.mshrs[2].entry.u_core.txnid_rcompack;
    release u_i.inner_l2cache.slices_0.u_core.mshrCtl.u_core.mshrs[2].entry.u_core.tgtid_wcompack;
    release u_i.inner_l2cache.slices_0.u_core.mshrCtl.u_core.mshrs[2].entry.u_core.txnid_wcompack;
    release u_i.inner_l2cache.slices_0.u_core.mshrCtl.u_core.mshrs[2].entry.u_core.srcid_retryack;
    release u_i.inner_l2cache.slices_0.u_core.mshrCtl.u_core.mshrs[2].entry.u_core.acquire_ts;
    release u_i.inner_l2cache.slices_0.u_core.mshrCtl.u_core.mshrs[2].entry.u_core.release_ts;
    release u_i.inner_l2cache.slices_0.u_core.mshrCtl.u_core.mshrs[2].entry.u_core.acquire_period_valid_REG;
    release u_i.inner_l2cache.slices_0.u_core.mshrCtl.u_core.mshrs[2].entry.u_core.release_period_valid_REG;
    release u_i.inner_l2cache.slices_0.u_core.mshrCtl.u_core.mshrs[2].entry.u_core.REG;
    release u_i.inner_l2cache.slices_0.u_core.mshrCtl.u_core.mshrs[2].entry.u_core.REG_1;
    release u_i.inner_l2cache.slices_0.u_core.mshrCtl.u_core.mshrs[2].entry.u_core.REG_2;
    release u_i.inner_l2cache.slices_0.u_core.mshrCtl.u_core.mshrs[2].entry.u_core.REG_3;
    release u_i.inner_l2cache.slices_0.u_core.mshrCtl.u_core.mshrs[3].entry.u_core.tgtid_rcompack;
    release u_i.inner_l2cache.slices_0.u_core.mshrCtl.u_core.mshrs[3].entry.u_core.txnid_rcompack;
    release u_i.inner_l2cache.slices_0.u_core.mshrCtl.u_core.mshrs[3].entry.u_core.tgtid_wcompack;
    release u_i.inner_l2cache.slices_0.u_core.mshrCtl.u_core.mshrs[3].entry.u_core.txnid_wcompack;
    release u_i.inner_l2cache.slices_0.u_core.mshrCtl.u_core.mshrs[3].entry.u_core.srcid_retryack;
    release u_i.inner_l2cache.slices_0.u_core.mshrCtl.u_core.mshrs[3].entry.u_core.acquire_ts;
    release u_i.inner_l2cache.slices_0.u_core.mshrCtl.u_core.mshrs[3].entry.u_core.release_ts;
    release u_i.inner_l2cache.slices_0.u_core.mshrCtl.u_core.mshrs[3].entry.u_core.acquire_period_valid_REG;
    release u_i.inner_l2cache.slices_0.u_core.mshrCtl.u_core.mshrs[3].entry.u_core.release_period_valid_REG;
    release u_i.inner_l2cache.slices_0.u_core.mshrCtl.u_core.mshrs[3].entry.u_core.REG;
    release u_i.inner_l2cache.slices_0.u_core.mshrCtl.u_core.mshrs[3].entry.u_core.REG_1;
    release u_i.inner_l2cache.slices_0.u_core.mshrCtl.u_core.mshrs[3].entry.u_core.REG_2;
    release u_i.inner_l2cache.slices_0.u_core.mshrCtl.u_core.mshrs[3].entry.u_core.REG_3;
    release u_i.inner_l2cache.slices_0.u_core.mshrCtl.u_core.mshrs[4].entry.u_core.tgtid_rcompack;
    release u_i.inner_l2cache.slices_0.u_core.mshrCtl.u_core.mshrs[4].entry.u_core.txnid_rcompack;
    release u_i.inner_l2cache.slices_0.u_core.mshrCtl.u_core.mshrs[4].entry.u_core.tgtid_wcompack;
    release u_i.inner_l2cache.slices_0.u_core.mshrCtl.u_core.mshrs[4].entry.u_core.txnid_wcompack;
    release u_i.inner_l2cache.slices_0.u_core.mshrCtl.u_core.mshrs[4].entry.u_core.srcid_retryack;
    release u_i.inner_l2cache.slices_0.u_core.mshrCtl.u_core.mshrs[4].entry.u_core.acquire_ts;
    release u_i.inner_l2cache.slices_0.u_core.mshrCtl.u_core.mshrs[4].entry.u_core.release_ts;
    release u_i.inner_l2cache.slices_0.u_core.mshrCtl.u_core.mshrs[4].entry.u_core.acquire_period_valid_REG;
    release u_i.inner_l2cache.slices_0.u_core.mshrCtl.u_core.mshrs[4].entry.u_core.release_period_valid_REG;
    release u_i.inner_l2cache.slices_0.u_core.mshrCtl.u_core.mshrs[4].entry.u_core.REG;
    release u_i.inner_l2cache.slices_0.u_core.mshrCtl.u_core.mshrs[4].entry.u_core.REG_1;
    release u_i.inner_l2cache.slices_0.u_core.mshrCtl.u_core.mshrs[4].entry.u_core.REG_2;
    release u_i.inner_l2cache.slices_0.u_core.mshrCtl.u_core.mshrs[4].entry.u_core.REG_3;
    release u_i.inner_l2cache.slices_0.u_core.mshrCtl.u_core.mshrs[5].entry.u_core.tgtid_rcompack;
    release u_i.inner_l2cache.slices_0.u_core.mshrCtl.u_core.mshrs[5].entry.u_core.txnid_rcompack;
    release u_i.inner_l2cache.slices_0.u_core.mshrCtl.u_core.mshrs[5].entry.u_core.tgtid_wcompack;
    release u_i.inner_l2cache.slices_0.u_core.mshrCtl.u_core.mshrs[5].entry.u_core.txnid_wcompack;
    release u_i.inner_l2cache.slices_0.u_core.mshrCtl.u_core.mshrs[5].entry.u_core.srcid_retryack;
    release u_i.inner_l2cache.slices_0.u_core.mshrCtl.u_core.mshrs[5].entry.u_core.acquire_ts;
    release u_i.inner_l2cache.slices_0.u_core.mshrCtl.u_core.mshrs[5].entry.u_core.release_ts;
    release u_i.inner_l2cache.slices_0.u_core.mshrCtl.u_core.mshrs[5].entry.u_core.acquire_period_valid_REG;
    release u_i.inner_l2cache.slices_0.u_core.mshrCtl.u_core.mshrs[5].entry.u_core.release_period_valid_REG;
    release u_i.inner_l2cache.slices_0.u_core.mshrCtl.u_core.mshrs[5].entry.u_core.REG;
    release u_i.inner_l2cache.slices_0.u_core.mshrCtl.u_core.mshrs[5].entry.u_core.REG_1;
    release u_i.inner_l2cache.slices_0.u_core.mshrCtl.u_core.mshrs[5].entry.u_core.REG_2;
    release u_i.inner_l2cache.slices_0.u_core.mshrCtl.u_core.mshrs[5].entry.u_core.REG_3;
    release u_i.inner_l2cache.slices_0.u_core.mshrCtl.u_core.mshrs[6].entry.u_core.tgtid_rcompack;
    release u_i.inner_l2cache.slices_0.u_core.mshrCtl.u_core.mshrs[6].entry.u_core.txnid_rcompack;
    release u_i.inner_l2cache.slices_0.u_core.mshrCtl.u_core.mshrs[6].entry.u_core.tgtid_wcompack;
    release u_i.inner_l2cache.slices_0.u_core.mshrCtl.u_core.mshrs[6].entry.u_core.txnid_wcompack;
    release u_i.inner_l2cache.slices_0.u_core.mshrCtl.u_core.mshrs[6].entry.u_core.srcid_retryack;
    release u_i.inner_l2cache.slices_0.u_core.mshrCtl.u_core.mshrs[6].entry.u_core.acquire_ts;
    release u_i.inner_l2cache.slices_0.u_core.mshrCtl.u_core.mshrs[6].entry.u_core.release_ts;
    release u_i.inner_l2cache.slices_0.u_core.mshrCtl.u_core.mshrs[6].entry.u_core.acquire_period_valid_REG;
    release u_i.inner_l2cache.slices_0.u_core.mshrCtl.u_core.mshrs[6].entry.u_core.release_period_valid_REG;
    release u_i.inner_l2cache.slices_0.u_core.mshrCtl.u_core.mshrs[6].entry.u_core.REG;
    release u_i.inner_l2cache.slices_0.u_core.mshrCtl.u_core.mshrs[6].entry.u_core.REG_1;
    release u_i.inner_l2cache.slices_0.u_core.mshrCtl.u_core.mshrs[6].entry.u_core.REG_2;
    release u_i.inner_l2cache.slices_0.u_core.mshrCtl.u_core.mshrs[6].entry.u_core.REG_3;
    release u_i.inner_l2cache.slices_0.u_core.mshrCtl.u_core.mshrs[7].entry.u_core.tgtid_rcompack;
    release u_i.inner_l2cache.slices_0.u_core.mshrCtl.u_core.mshrs[7].entry.u_core.txnid_rcompack;
    release u_i.inner_l2cache.slices_0.u_core.mshrCtl.u_core.mshrs[7].entry.u_core.tgtid_wcompack;
    release u_i.inner_l2cache.slices_0.u_core.mshrCtl.u_core.mshrs[7].entry.u_core.txnid_wcompack;
    release u_i.inner_l2cache.slices_0.u_core.mshrCtl.u_core.mshrs[7].entry.u_core.srcid_retryack;
    release u_i.inner_l2cache.slices_0.u_core.mshrCtl.u_core.mshrs[7].entry.u_core.acquire_ts;
    release u_i.inner_l2cache.slices_0.u_core.mshrCtl.u_core.mshrs[7].entry.u_core.release_ts;
    release u_i.inner_l2cache.slices_0.u_core.mshrCtl.u_core.mshrs[7].entry.u_core.acquire_period_valid_REG;
    release u_i.inner_l2cache.slices_0.u_core.mshrCtl.u_core.mshrs[7].entry.u_core.release_period_valid_REG;
    release u_i.inner_l2cache.slices_0.u_core.mshrCtl.u_core.mshrs[7].entry.u_core.REG;
    release u_i.inner_l2cache.slices_0.u_core.mshrCtl.u_core.mshrs[7].entry.u_core.REG_1;
    release u_i.inner_l2cache.slices_0.u_core.mshrCtl.u_core.mshrs[7].entry.u_core.REG_2;
    release u_i.inner_l2cache.slices_0.u_core.mshrCtl.u_core.mshrs[7].entry.u_core.REG_3;
    release u_i.inner_l2cache.slices_0.u_core.mshrCtl.u_core.mshrs[8].entry.u_core.tgtid_rcompack;
    release u_i.inner_l2cache.slices_0.u_core.mshrCtl.u_core.mshrs[8].entry.u_core.txnid_rcompack;
    release u_i.inner_l2cache.slices_0.u_core.mshrCtl.u_core.mshrs[8].entry.u_core.tgtid_wcompack;
    release u_i.inner_l2cache.slices_0.u_core.mshrCtl.u_core.mshrs[8].entry.u_core.txnid_wcompack;
    release u_i.inner_l2cache.slices_0.u_core.mshrCtl.u_core.mshrs[8].entry.u_core.srcid_retryack;
    release u_i.inner_l2cache.slices_0.u_core.mshrCtl.u_core.mshrs[8].entry.u_core.acquire_ts;
    release u_i.inner_l2cache.slices_0.u_core.mshrCtl.u_core.mshrs[8].entry.u_core.release_ts;
    release u_i.inner_l2cache.slices_0.u_core.mshrCtl.u_core.mshrs[8].entry.u_core.acquire_period_valid_REG;
    release u_i.inner_l2cache.slices_0.u_core.mshrCtl.u_core.mshrs[8].entry.u_core.release_period_valid_REG;
    release u_i.inner_l2cache.slices_0.u_core.mshrCtl.u_core.mshrs[8].entry.u_core.REG;
    release u_i.inner_l2cache.slices_0.u_core.mshrCtl.u_core.mshrs[8].entry.u_core.REG_1;
    release u_i.inner_l2cache.slices_0.u_core.mshrCtl.u_core.mshrs[8].entry.u_core.REG_2;
    release u_i.inner_l2cache.slices_0.u_core.mshrCtl.u_core.mshrs[8].entry.u_core.REG_3;
    release u_i.inner_l2cache.slices_0.u_core.mshrCtl.u_core.mshrs[9].entry.u_core.tgtid_rcompack;
    release u_i.inner_l2cache.slices_0.u_core.mshrCtl.u_core.mshrs[9].entry.u_core.txnid_rcompack;
    release u_i.inner_l2cache.slices_0.u_core.mshrCtl.u_core.mshrs[9].entry.u_core.tgtid_wcompack;
    release u_i.inner_l2cache.slices_0.u_core.mshrCtl.u_core.mshrs[9].entry.u_core.txnid_wcompack;
    release u_i.inner_l2cache.slices_0.u_core.mshrCtl.u_core.mshrs[9].entry.u_core.srcid_retryack;
    release u_i.inner_l2cache.slices_0.u_core.mshrCtl.u_core.mshrs[9].entry.u_core.acquire_ts;
    release u_i.inner_l2cache.slices_0.u_core.mshrCtl.u_core.mshrs[9].entry.u_core.release_ts;
    release u_i.inner_l2cache.slices_0.u_core.mshrCtl.u_core.mshrs[9].entry.u_core.acquire_period_valid_REG;
    release u_i.inner_l2cache.slices_0.u_core.mshrCtl.u_core.mshrs[9].entry.u_core.release_period_valid_REG;
    release u_i.inner_l2cache.slices_0.u_core.mshrCtl.u_core.mshrs[9].entry.u_core.REG;
    release u_i.inner_l2cache.slices_0.u_core.mshrCtl.u_core.mshrs[9].entry.u_core.REG_1;
    release u_i.inner_l2cache.slices_0.u_core.mshrCtl.u_core.mshrs[9].entry.u_core.REG_2;
    release u_i.inner_l2cache.slices_0.u_core.mshrCtl.u_core.mshrs[9].entry.u_core.REG_3;
    release u_i.inner_l2cache.slices_0.u_core.mshrCtl.u_core.mshrs[10].entry.u_core.tgtid_rcompack;
    release u_i.inner_l2cache.slices_0.u_core.mshrCtl.u_core.mshrs[10].entry.u_core.txnid_rcompack;
    release u_i.inner_l2cache.slices_0.u_core.mshrCtl.u_core.mshrs[10].entry.u_core.tgtid_wcompack;
    release u_i.inner_l2cache.slices_0.u_core.mshrCtl.u_core.mshrs[10].entry.u_core.txnid_wcompack;
    release u_i.inner_l2cache.slices_0.u_core.mshrCtl.u_core.mshrs[10].entry.u_core.srcid_retryack;
    release u_i.inner_l2cache.slices_0.u_core.mshrCtl.u_core.mshrs[10].entry.u_core.acquire_ts;
    release u_i.inner_l2cache.slices_0.u_core.mshrCtl.u_core.mshrs[10].entry.u_core.release_ts;
    release u_i.inner_l2cache.slices_0.u_core.mshrCtl.u_core.mshrs[10].entry.u_core.acquire_period_valid_REG;
    release u_i.inner_l2cache.slices_0.u_core.mshrCtl.u_core.mshrs[10].entry.u_core.release_period_valid_REG;
    release u_i.inner_l2cache.slices_0.u_core.mshrCtl.u_core.mshrs[10].entry.u_core.REG;
    release u_i.inner_l2cache.slices_0.u_core.mshrCtl.u_core.mshrs[10].entry.u_core.REG_1;
    release u_i.inner_l2cache.slices_0.u_core.mshrCtl.u_core.mshrs[10].entry.u_core.REG_2;
    release u_i.inner_l2cache.slices_0.u_core.mshrCtl.u_core.mshrs[10].entry.u_core.REG_3;
    release u_i.inner_l2cache.slices_0.u_core.mshrCtl.u_core.mshrs[11].entry.u_core.tgtid_rcompack;
    release u_i.inner_l2cache.slices_0.u_core.mshrCtl.u_core.mshrs[11].entry.u_core.txnid_rcompack;
    release u_i.inner_l2cache.slices_0.u_core.mshrCtl.u_core.mshrs[11].entry.u_core.tgtid_wcompack;
    release u_i.inner_l2cache.slices_0.u_core.mshrCtl.u_core.mshrs[11].entry.u_core.txnid_wcompack;
    release u_i.inner_l2cache.slices_0.u_core.mshrCtl.u_core.mshrs[11].entry.u_core.srcid_retryack;
    release u_i.inner_l2cache.slices_0.u_core.mshrCtl.u_core.mshrs[11].entry.u_core.acquire_ts;
    release u_i.inner_l2cache.slices_0.u_core.mshrCtl.u_core.mshrs[11].entry.u_core.release_ts;
    release u_i.inner_l2cache.slices_0.u_core.mshrCtl.u_core.mshrs[11].entry.u_core.acquire_period_valid_REG;
    release u_i.inner_l2cache.slices_0.u_core.mshrCtl.u_core.mshrs[11].entry.u_core.release_period_valid_REG;
    release u_i.inner_l2cache.slices_0.u_core.mshrCtl.u_core.mshrs[11].entry.u_core.REG;
    release u_i.inner_l2cache.slices_0.u_core.mshrCtl.u_core.mshrs[11].entry.u_core.REG_1;
    release u_i.inner_l2cache.slices_0.u_core.mshrCtl.u_core.mshrs[11].entry.u_core.REG_2;
    release u_i.inner_l2cache.slices_0.u_core.mshrCtl.u_core.mshrs[11].entry.u_core.REG_3;
    release u_i.inner_l2cache.slices_0.u_core.mshrCtl.u_core.mshrs[12].entry.u_core.tgtid_rcompack;
    release u_i.inner_l2cache.slices_0.u_core.mshrCtl.u_core.mshrs[12].entry.u_core.txnid_rcompack;
    release u_i.inner_l2cache.slices_0.u_core.mshrCtl.u_core.mshrs[12].entry.u_core.tgtid_wcompack;
    release u_i.inner_l2cache.slices_0.u_core.mshrCtl.u_core.mshrs[12].entry.u_core.txnid_wcompack;
    release u_i.inner_l2cache.slices_0.u_core.mshrCtl.u_core.mshrs[12].entry.u_core.srcid_retryack;
    release u_i.inner_l2cache.slices_0.u_core.mshrCtl.u_core.mshrs[12].entry.u_core.acquire_ts;
    release u_i.inner_l2cache.slices_0.u_core.mshrCtl.u_core.mshrs[12].entry.u_core.release_ts;
    release u_i.inner_l2cache.slices_0.u_core.mshrCtl.u_core.mshrs[12].entry.u_core.acquire_period_valid_REG;
    release u_i.inner_l2cache.slices_0.u_core.mshrCtl.u_core.mshrs[12].entry.u_core.release_period_valid_REG;
    release u_i.inner_l2cache.slices_0.u_core.mshrCtl.u_core.mshrs[12].entry.u_core.REG;
    release u_i.inner_l2cache.slices_0.u_core.mshrCtl.u_core.mshrs[12].entry.u_core.REG_1;
    release u_i.inner_l2cache.slices_0.u_core.mshrCtl.u_core.mshrs[12].entry.u_core.REG_2;
    release u_i.inner_l2cache.slices_0.u_core.mshrCtl.u_core.mshrs[12].entry.u_core.REG_3;
    release u_i.inner_l2cache.slices_0.u_core.mshrCtl.u_core.mshrs[13].entry.u_core.tgtid_rcompack;
    release u_i.inner_l2cache.slices_0.u_core.mshrCtl.u_core.mshrs[13].entry.u_core.txnid_rcompack;
    release u_i.inner_l2cache.slices_0.u_core.mshrCtl.u_core.mshrs[13].entry.u_core.tgtid_wcompack;
    release u_i.inner_l2cache.slices_0.u_core.mshrCtl.u_core.mshrs[13].entry.u_core.txnid_wcompack;
    release u_i.inner_l2cache.slices_0.u_core.mshrCtl.u_core.mshrs[13].entry.u_core.srcid_retryack;
    release u_i.inner_l2cache.slices_0.u_core.mshrCtl.u_core.mshrs[13].entry.u_core.acquire_ts;
    release u_i.inner_l2cache.slices_0.u_core.mshrCtl.u_core.mshrs[13].entry.u_core.release_ts;
    release u_i.inner_l2cache.slices_0.u_core.mshrCtl.u_core.mshrs[13].entry.u_core.acquire_period_valid_REG;
    release u_i.inner_l2cache.slices_0.u_core.mshrCtl.u_core.mshrs[13].entry.u_core.release_period_valid_REG;
    release u_i.inner_l2cache.slices_0.u_core.mshrCtl.u_core.mshrs[13].entry.u_core.REG;
    release u_i.inner_l2cache.slices_0.u_core.mshrCtl.u_core.mshrs[13].entry.u_core.REG_1;
    release u_i.inner_l2cache.slices_0.u_core.mshrCtl.u_core.mshrs[13].entry.u_core.REG_2;
    release u_i.inner_l2cache.slices_0.u_core.mshrCtl.u_core.mshrs[13].entry.u_core.REG_3;
    release u_i.inner_l2cache.slices_0.u_core.mshrCtl.u_core.mshrs[14].entry.u_core.tgtid_rcompack;
    release u_i.inner_l2cache.slices_0.u_core.mshrCtl.u_core.mshrs[14].entry.u_core.txnid_rcompack;
    release u_i.inner_l2cache.slices_0.u_core.mshrCtl.u_core.mshrs[14].entry.u_core.tgtid_wcompack;
    release u_i.inner_l2cache.slices_0.u_core.mshrCtl.u_core.mshrs[14].entry.u_core.txnid_wcompack;
    release u_i.inner_l2cache.slices_0.u_core.mshrCtl.u_core.mshrs[14].entry.u_core.srcid_retryack;
    release u_i.inner_l2cache.slices_0.u_core.mshrCtl.u_core.mshrs[14].entry.u_core.acquire_ts;
    release u_i.inner_l2cache.slices_0.u_core.mshrCtl.u_core.mshrs[14].entry.u_core.release_ts;
    release u_i.inner_l2cache.slices_0.u_core.mshrCtl.u_core.mshrs[14].entry.u_core.acquire_period_valid_REG;
    release u_i.inner_l2cache.slices_0.u_core.mshrCtl.u_core.mshrs[14].entry.u_core.release_period_valid_REG;
    release u_i.inner_l2cache.slices_0.u_core.mshrCtl.u_core.mshrs[14].entry.u_core.REG;
    release u_i.inner_l2cache.slices_0.u_core.mshrCtl.u_core.mshrs[14].entry.u_core.REG_1;
    release u_i.inner_l2cache.slices_0.u_core.mshrCtl.u_core.mshrs[14].entry.u_core.REG_2;
    release u_i.inner_l2cache.slices_0.u_core.mshrCtl.u_core.mshrs[14].entry.u_core.REG_3;
    release u_i.inner_l2cache.slices_0.u_core.mshrCtl.u_core.mshrs[15].entry.u_core.tgtid_rcompack;
    release u_i.inner_l2cache.slices_0.u_core.mshrCtl.u_core.mshrs[15].entry.u_core.txnid_rcompack;
    release u_i.inner_l2cache.slices_0.u_core.mshrCtl.u_core.mshrs[15].entry.u_core.tgtid_wcompack;
    release u_i.inner_l2cache.slices_0.u_core.mshrCtl.u_core.mshrs[15].entry.u_core.txnid_wcompack;
    release u_i.inner_l2cache.slices_0.u_core.mshrCtl.u_core.mshrs[15].entry.u_core.srcid_retryack;
    release u_i.inner_l2cache.slices_0.u_core.mshrCtl.u_core.mshrs[15].entry.u_core.acquire_ts;
    release u_i.inner_l2cache.slices_0.u_core.mshrCtl.u_core.mshrs[15].entry.u_core.release_ts;
    release u_i.inner_l2cache.slices_0.u_core.mshrCtl.u_core.mshrs[15].entry.u_core.acquire_period_valid_REG;
    release u_i.inner_l2cache.slices_0.u_core.mshrCtl.u_core.mshrs[15].entry.u_core.release_period_valid_REG;
    release u_i.inner_l2cache.slices_0.u_core.mshrCtl.u_core.mshrs[15].entry.u_core.REG;
    release u_i.inner_l2cache.slices_0.u_core.mshrCtl.u_core.mshrs[15].entry.u_core.REG_1;
    release u_i.inner_l2cache.slices_0.u_core.mshrCtl.u_core.mshrs[15].entry.u_core.REG_2;
    release u_i.inner_l2cache.slices_0.u_core.mshrCtl.u_core.mshrs[15].entry.u_core.REG_3;
    release u_i.inner_l2cache.slices_0.u_core.mshrCtl.u_core.io_perf_0_value_REG;
    release u_i.inner_l2cache.slices_0.u_core.mshrCtl.u_core.io_perf_0_value_REG_1;
    release u_i.inner_l2cache.slices_0.u_core.mshrCtl.u_core.io_perf_1_value_REG;
    release u_i.inner_l2cache.slices_0.u_core.mshrCtl.u_core.io_perf_1_value_REG_1;
    release u_i.inner_l2cache.slices_0.u_core.mshrCtl.u_core.io_perf_3_value_REG;
    release u_i.inner_l2cache.slices_0.u_core.mshrCtl.u_core.io_perf_3_value_REG_1;
    release u_i.inner_l2cache.slices_0.u_core.mshrCtl.u_core.REG;
    release u_i.inner_l2cache.slices_0.u_core.mainPipe.u_core.data_s4;
    release u_i.inner_l2cache.slices_0.u_core.mainPipe.u_core.data_s5;
    release u_i.inner_l2cache.slices_0.u_core.mainPipe.u_core.s3DropValid_d1;
    release u_i.inner_l2cache.slices_0.u_core.mainPipe.u_core.reqDrop_s3_d1;
    release u_i.inner_l2cache.slices_0.u_core.mainPipe.u_core.reqDrop_s3_d2;
    release u_i.inner_l2cache.slices_0.u_core.mainPipe.u_core.reqDrop_s4_d1;
    release u_i.inner_l2cache.slices_0.u_core.mainPipe.u_core.perf_d1[0];
    release u_i.inner_l2cache.slices_0.u_core.mainPipe.u_core.perf[0];
    release u_i.inner_l2cache.slices_0.u_core.mainPipe.u_core.perf_d1[1];
    release u_i.inner_l2cache.slices_0.u_core.mainPipe.u_core.perf[1];
    release u_i.inner_l2cache.slices_0.u_core.mainPipe.u_core.perf_d1[2];
    release u_i.inner_l2cache.slices_0.u_core.mainPipe.u_core.perf[2];
    release u_i.inner_l2cache.slices_0.u_core.mainPipe.u_core.perf_d1[3];
    release u_i.inner_l2cache.slices_0.u_core.mainPipe.u_core.perf[3];
    release u_i.inner_l2cache.slices_0.u_core.mainPipe.u_core.perf_d1[4];
    release u_i.inner_l2cache.slices_0.u_core.mainPipe.u_core.perf[4];
    release u_i.inner_l2cache.slices_0.u_core.mainPipe.u_core.perf_d1[5];
    release u_i.inner_l2cache.slices_0.u_core.mainPipe.u_core.perf[5];
    release u_i.inner_l2cache.slices_0.u_core.mainPipe.u_core.perf_d1[6];
    release u_i.inner_l2cache.slices_0.u_core.mainPipe.u_core.perf[6];
    release u_i.inner_l2cache.slices_0.u_core.mainPipe.u_core.perf_d1[7];
    release u_i.inner_l2cache.slices_0.u_core.mainPipe.u_core.perf[7];
    release u_i.inner_l2cache.slices_0.u_core.mainPipe.u_core.perf_d1[8];
    release u_i.inner_l2cache.slices_0.u_core.mainPipe.u_core.perf[8];
    release u_i.inner_l2cache.slices_0.u_core.mainPipe.u_core.perf_d1[9];
    release u_i.inner_l2cache.slices_0.u_core.mainPipe.u_core.perf[9];
    release u_i.inner_l2cache.slices_0.u_core.mainPipe.u_core.perf_d1[10];
    release u_i.inner_l2cache.slices_0.u_core.mainPipe.u_core.perf[10];
    release u_i.inner_l2cache.slices_0.u_core.mainPipe.u_core.perf_d1[11];
    release u_i.inner_l2cache.slices_0.u_core.mainPipe.u_core.perf[11];
    release u_i.inner_l2cache.slices_0.u_core.mainPipe.u_core.perf_d1[12];
    release u_i.inner_l2cache.slices_0.u_core.mainPipe.u_core.perf[12];
    release u_i.inner_l2cache.slices_0.u_core.grantBuf.u_core.validPrev[0];
    release u_i.inner_l2cache.slices_0.u_core.grantBuf.u_core.histValidPrev[0];
    release u_i.inner_l2cache.slices_0.u_core.grantBuf.u_core.validPrev[1];
    release u_i.inner_l2cache.slices_0.u_core.grantBuf.u_core.histValidPrev[1];
    release u_i.inner_l2cache.slices_0.u_core.grantBuf.u_core.validPrev[2];
    release u_i.inner_l2cache.slices_0.u_core.grantBuf.u_core.histValidPrev[2];
    release u_i.inner_l2cache.slices_0.u_core.grantBuf.u_core.validPrev[3];
    release u_i.inner_l2cache.slices_0.u_core.grantBuf.u_core.histValidPrev[3];
    release u_i.inner_l2cache.slices_0.u_core.grantBuf.u_core.validPrev[4];
    release u_i.inner_l2cache.slices_0.u_core.grantBuf.u_core.histValidPrev[4];
    release u_i.inner_l2cache.slices_0.u_core.grantBuf.u_core.validPrev[5];
    release u_i.inner_l2cache.slices_0.u_core.grantBuf.u_core.histValidPrev[5];
    release u_i.inner_l2cache.slices_0.u_core.grantBuf.u_core.validPrev[6];
    release u_i.inner_l2cache.slices_0.u_core.grantBuf.u_core.histValidPrev[6];
    release u_i.inner_l2cache.slices_0.u_core.grantBuf.u_core.validPrev[7];
    release u_i.inner_l2cache.slices_0.u_core.grantBuf.u_core.histValidPrev[7];
    release u_i.inner_l2cache.slices_0.u_core.grantBuf.u_core.validPrev[8];
    release u_i.inner_l2cache.slices_0.u_core.grantBuf.u_core.histValidPrev[8];
    release u_i.inner_l2cache.slices_0.u_core.grantBuf.u_core.validPrev[9];
    release u_i.inner_l2cache.slices_0.u_core.grantBuf.u_core.histValidPrev[9];
    release u_i.inner_l2cache.slices_0.u_core.grantBuf.u_core.validPrev[10];
    release u_i.inner_l2cache.slices_0.u_core.grantBuf.u_core.histValidPrev[10];
    release u_i.inner_l2cache.slices_0.u_core.grantBuf.u_core.validPrev[11];
    release u_i.inner_l2cache.slices_0.u_core.grantBuf.u_core.histValidPrev[11];
    release u_i.inner_l2cache.slices_0.u_core.grantBuf.u_core.validPrev[12];
    release u_i.inner_l2cache.slices_0.u_core.grantBuf.u_core.histValidPrev[12];
    release u_i.inner_l2cache.slices_0.u_core.grantBuf.u_core.validPrev[13];
    release u_i.inner_l2cache.slices_0.u_core.grantBuf.u_core.histValidPrev[13];
    release u_i.inner_l2cache.slices_0.u_core.grantBuf.u_core.validPrev[14];
    release u_i.inner_l2cache.slices_0.u_core.grantBuf.u_core.histValidPrev[14];
    release u_i.inner_l2cache.slices_0.u_core.grantBuf.u_core.validPrev[15];
    release u_i.inner_l2cache.slices_0.u_core.grantBuf.u_core.histValidPrev[15];
    release u_i.inner_l2cache.slices_0.u_core.rxsnp.u_core.replPrevForBlock[0];
    release u_i.inner_l2cache.slices_0.u_core.rxsnp.u_core.replPrevForNest[0];
    release u_i.inner_l2cache.slices_0.u_core.rxsnp.u_core.replPrevForBlock[1];
    release u_i.inner_l2cache.slices_0.u_core.rxsnp.u_core.replPrevForNest[1];
    release u_i.inner_l2cache.slices_0.u_core.rxsnp.u_core.replPrevForBlock[2];
    release u_i.inner_l2cache.slices_0.u_core.rxsnp.u_core.replPrevForNest[2];
    release u_i.inner_l2cache.slices_0.u_core.rxsnp.u_core.replPrevForBlock[3];
    release u_i.inner_l2cache.slices_0.u_core.rxsnp.u_core.replPrevForNest[3];
    release u_i.inner_l2cache.slices_0.u_core.rxsnp.u_core.replPrevForBlock[4];
    release u_i.inner_l2cache.slices_0.u_core.rxsnp.u_core.replPrevForNest[4];
    release u_i.inner_l2cache.slices_0.u_core.rxsnp.u_core.replPrevForBlock[5];
    release u_i.inner_l2cache.slices_0.u_core.rxsnp.u_core.replPrevForNest[5];
    release u_i.inner_l2cache.slices_0.u_core.rxsnp.u_core.replPrevForBlock[6];
    release u_i.inner_l2cache.slices_0.u_core.rxsnp.u_core.replPrevForNest[6];
    release u_i.inner_l2cache.slices_0.u_core.rxsnp.u_core.replPrevForBlock[7];
    release u_i.inner_l2cache.slices_0.u_core.rxsnp.u_core.replPrevForNest[7];
    release u_i.inner_l2cache.slices_0.u_core.rxsnp.u_core.replPrevForBlock[8];
    release u_i.inner_l2cache.slices_0.u_core.rxsnp.u_core.replPrevForNest[8];
    release u_i.inner_l2cache.slices_0.u_core.rxsnp.u_core.replPrevForBlock[9];
    release u_i.inner_l2cache.slices_0.u_core.rxsnp.u_core.replPrevForNest[9];
    release u_i.inner_l2cache.slices_0.u_core.rxsnp.u_core.replPrevForBlock[10];
    release u_i.inner_l2cache.slices_0.u_core.rxsnp.u_core.replPrevForNest[10];
    release u_i.inner_l2cache.slices_0.u_core.rxsnp.u_core.replPrevForBlock[11];
    release u_i.inner_l2cache.slices_0.u_core.rxsnp.u_core.replPrevForNest[11];
    release u_i.inner_l2cache.slices_0.u_core.rxsnp.u_core.replPrevForBlock[12];
    release u_i.inner_l2cache.slices_0.u_core.rxsnp.u_core.replPrevForNest[12];
    release u_i.inner_l2cache.slices_0.u_core.rxsnp.u_core.replPrevForBlock[13];
    release u_i.inner_l2cache.slices_0.u_core.rxsnp.u_core.replPrevForNest[13];
    release u_i.inner_l2cache.slices_0.u_core.rxsnp.u_core.replPrevForBlock[14];
    release u_i.inner_l2cache.slices_0.u_core.rxsnp.u_core.replPrevForNest[14];
    release u_i.inner_l2cache.slices_0.u_core.rxsnp.u_core.replPrevForBlock[15];
    release u_i.inner_l2cache.slices_0.u_core.rxsnp.u_core.replPrevForNest[15];
    release u_i.inner_l2cache.slices_0.u_core.reqBuf.chosenQ.u_core.ram;
    release u_i.inner_l2cache.slices_0.u_core.reqBuf.u_core.hitPfPrev_set;
    release u_i.inner_l2cache.slices_0.u_core.reqBuf.u_core.hitPfPrev_tag;
    release u_i.inner_l2cache.slices_0.u_core.reqBuf.u_core.mergeAPrev_set;
    release u_i.inner_l2cache.slices_0.u_core.reqBuf.u_core.mergeAPrev_tag;
    release u_i.inner_l2cache.slices_0.u_core.reqBuf.u_core.sameSetS3Valid[0];
    release u_i.inner_l2cache.slices_0.u_core.reqBuf.u_core.sameSetS3Set[0];
    release u_i.inner_l2cache.slices_0.u_core.reqBuf.u_core.sameSetS3Valid[1];
    release u_i.inner_l2cache.slices_0.u_core.reqBuf.u_core.sameSetS3Set[1];
    release u_i.inner_l2cache.slices_0.u_core.reqBuf.u_core.sameSetS3Valid[2];
    release u_i.inner_l2cache.slices_0.u_core.reqBuf.u_core.sameSetS3Set[2];
    release u_i.inner_l2cache.slices_0.u_core.reqBuf.u_core.sameSetS3Valid[3];
    release u_i.inner_l2cache.slices_0.u_core.reqBuf.u_core.sameSetS3Set[3];
    release u_i.inner_l2cache.slices_0.u_core.reqBuf.u_core.sameSetS3Valid[4];
    release u_i.inner_l2cache.slices_0.u_core.reqBuf.u_core.sameSetS3Set[4];
    release u_i.inner_l2cache.slices_0.u_core.reqBuf.u_core.sameSetS3Valid[5];
    release u_i.inner_l2cache.slices_0.u_core.reqBuf.u_core.sameSetS3Set[5];
    release u_i.inner_l2cache.slices_0.u_core.sinkC.u_core.bufRespStage[0];
    release u_i.inner_l2cache.slices_0.u_core.sinkC.u_core.bufRespStage[1];
    release u_i.inner_l2cache.slices_0.u_core.sinkC.u_core.bufRespOut[0];
    release u_i.inner_l2cache.slices_0.u_core.sinkC.u_core.bufRespOut[1];
    release u_i.inner_l2cache.slices_0.u_core.sinkC.u_core.refillIdReg;
    release u_i.inner_l2cache.slices_0.u_core.sinkC.u_core.refillBufIdxReg;
    release u_i.inner_l2cache.slices_0.u_core.sinkC.u_core.taskFirePrev;
    release u_i.inner_l2cache.slices_0.u_core.sinkC.u_core.taskBufIdxPrev;
    release u_i.inner_l2cache.slices_0.u_core.reqArb.u_core.ds_mcp2_stall;
    release u_i.inner_l2cache.slices_0.u_core.refillBuf.u_core.buffer[0][0];
    release u_i.inner_l2cache.slices_0.u_core.refillBuf.u_core.buffer[0][1];
    release u_i.inner_l2cache.slices_0.u_core.refillBuf.u_core.buffer[1][0];
    release u_i.inner_l2cache.slices_0.u_core.refillBuf.u_core.buffer[1][1];
    release u_i.inner_l2cache.slices_0.u_core.refillBuf.u_core.buffer[2][0];
    release u_i.inner_l2cache.slices_0.u_core.refillBuf.u_core.buffer[2][1];
    release u_i.inner_l2cache.slices_0.u_core.refillBuf.u_core.buffer[3][0];
    release u_i.inner_l2cache.slices_0.u_core.refillBuf.u_core.buffer[3][1];
    release u_i.inner_l2cache.slices_0.u_core.refillBuf.u_core.buffer[4][0];
    release u_i.inner_l2cache.slices_0.u_core.refillBuf.u_core.buffer[4][1];
    release u_i.inner_l2cache.slices_0.u_core.refillBuf.u_core.buffer[5][0];
    release u_i.inner_l2cache.slices_0.u_core.refillBuf.u_core.buffer[5][1];
    release u_i.inner_l2cache.slices_0.u_core.refillBuf.u_core.buffer[6][0];
    release u_i.inner_l2cache.slices_0.u_core.refillBuf.u_core.buffer[6][1];
    release u_i.inner_l2cache.slices_0.u_core.refillBuf.u_core.buffer[7][0];
    release u_i.inner_l2cache.slices_0.u_core.refillBuf.u_core.buffer[7][1];
    release u_i.inner_l2cache.slices_0.u_core.refillBuf.u_core.buffer[8][0];
    release u_i.inner_l2cache.slices_0.u_core.refillBuf.u_core.buffer[8][1];
    release u_i.inner_l2cache.slices_0.u_core.refillBuf.u_core.buffer[9][0];
    release u_i.inner_l2cache.slices_0.u_core.refillBuf.u_core.buffer[9][1];
    release u_i.inner_l2cache.slices_0.u_core.refillBuf.u_core.buffer[10][0];
    release u_i.inner_l2cache.slices_0.u_core.refillBuf.u_core.buffer[10][1];
    release u_i.inner_l2cache.slices_0.u_core.refillBuf.u_core.buffer[11][0];
    release u_i.inner_l2cache.slices_0.u_core.refillBuf.u_core.buffer[11][1];
    release u_i.inner_l2cache.slices_0.u_core.refillBuf.u_core.buffer[12][0];
    release u_i.inner_l2cache.slices_0.u_core.refillBuf.u_core.buffer[12][1];
    release u_i.inner_l2cache.slices_0.u_core.refillBuf.u_core.buffer[13][0];
    release u_i.inner_l2cache.slices_0.u_core.refillBuf.u_core.buffer[13][1];
    release u_i.inner_l2cache.slices_0.u_core.refillBuf.u_core.buffer[14][0];
    release u_i.inner_l2cache.slices_0.u_core.refillBuf.u_core.buffer[14][1];
    release u_i.inner_l2cache.slices_0.u_core.refillBuf.u_core.buffer[15][0];
    release u_i.inner_l2cache.slices_0.u_core.refillBuf.u_core.buffer[15][1];
    release u_i.inner_l2cache.slices_0.u_core.releaseBuf.u_core.buffer[0][0];
    release u_i.inner_l2cache.slices_0.u_core.releaseBuf.u_core.buffer[0][1];
    release u_i.inner_l2cache.slices_0.u_core.releaseBuf.u_core.buffer[1][0];
    release u_i.inner_l2cache.slices_0.u_core.releaseBuf.u_core.buffer[1][1];
    release u_i.inner_l2cache.slices_0.u_core.releaseBuf.u_core.buffer[2][0];
    release u_i.inner_l2cache.slices_0.u_core.releaseBuf.u_core.buffer[2][1];
    release u_i.inner_l2cache.slices_0.u_core.releaseBuf.u_core.buffer[3][0];
    release u_i.inner_l2cache.slices_0.u_core.releaseBuf.u_core.buffer[3][1];
    release u_i.inner_l2cache.slices_0.u_core.releaseBuf.u_core.buffer[4][0];
    release u_i.inner_l2cache.slices_0.u_core.releaseBuf.u_core.buffer[4][1];
    release u_i.inner_l2cache.slices_0.u_core.releaseBuf.u_core.buffer[5][0];
    release u_i.inner_l2cache.slices_0.u_core.releaseBuf.u_core.buffer[5][1];
    release u_i.inner_l2cache.slices_0.u_core.releaseBuf.u_core.buffer[6][0];
    release u_i.inner_l2cache.slices_0.u_core.releaseBuf.u_core.buffer[6][1];
    release u_i.inner_l2cache.slices_0.u_core.releaseBuf.u_core.buffer[7][0];
    release u_i.inner_l2cache.slices_0.u_core.releaseBuf.u_core.buffer[7][1];
    release u_i.inner_l2cache.slices_0.u_core.releaseBuf.u_core.buffer[8][0];
    release u_i.inner_l2cache.slices_0.u_core.releaseBuf.u_core.buffer[8][1];
    release u_i.inner_l2cache.slices_0.u_core.releaseBuf.u_core.buffer[9][0];
    release u_i.inner_l2cache.slices_0.u_core.releaseBuf.u_core.buffer[9][1];
    release u_i.inner_l2cache.slices_0.u_core.releaseBuf.u_core.buffer[10][0];
    release u_i.inner_l2cache.slices_0.u_core.releaseBuf.u_core.buffer[10][1];
    release u_i.inner_l2cache.slices_0.u_core.releaseBuf.u_core.buffer[11][0];
    release u_i.inner_l2cache.slices_0.u_core.releaseBuf.u_core.buffer[11][1];
    release u_i.inner_l2cache.slices_0.u_core.releaseBuf.u_core.buffer[12][0];
    release u_i.inner_l2cache.slices_0.u_core.releaseBuf.u_core.buffer[12][1];
    release u_i.inner_l2cache.slices_0.u_core.releaseBuf.u_core.buffer[13][0];
    release u_i.inner_l2cache.slices_0.u_core.releaseBuf.u_core.buffer[13][1];
    release u_i.inner_l2cache.slices_0.u_core.releaseBuf.u_core.buffer[14][0];
    release u_i.inner_l2cache.slices_0.u_core.releaseBuf.u_core.buffer[14][1];
    release u_i.inner_l2cache.slices_0.u_core.releaseBuf.u_core.buffer[15][0];
    release u_i.inner_l2cache.slices_0.u_core.releaseBuf.u_core.buffer[15][1];
    release u_i.inner_l2cache.slices_0.directory.tagArray.array_0_0_0.u_core.rdataReg;
    release u_i.inner_l2cache.slices_0.directory.tagArray.array_0_0_1.u_core.rdataReg;
    release u_i.inner_l2cache.slices_0.directory.tagArray.array_0_1_0.u_core.rdataReg;
    release u_i.inner_l2cache.slices_0.directory.tagArray.array_0_1_1.u_core.rdataReg;
    release u_i.inner_l2cache.slices_0.directory.metaArray.u_core.rdataReg;
    release u_i.inner_l2cache.slices_0.directory.replacer_sram_opt.u_core.rdataReg;
    release u_i.inner_l2cache.slices_0.directory.origin_bit_opt.u_core.rdataReg;
    release u_i.inner_l2cache.slices_0.dataStorage.array.array_0_0_0.u_core.rdataReg;
    release u_i.inner_l2cache.slices_0.dataStorage.array.array_0_0_1.u_core.rdataReg;
    release u_i.inner_l2cache.slices_0.dataStorage.array.array_0_0_2.u_core.rdataReg;
    release u_i.inner_l2cache.slices_0.dataStorage.array.array_0_0_3.u_core.rdataReg;
    release u_i.inner_l2cache.slices_0.dataStorage.u_core.error_REG;
    release u_i.inner_l2cache.slices_0.dataStorage.u_core.error_REG_1;
    release u_i.inner_l2cache.slices_0.mbistPl.u_core.g_node_return.pipelineDataOutReg;
    release u_i.inner_l2cache.slices_0.u_core.io_error_bits_REG_valid;
    release u_i.inner_l2cache.slices_0.u_core.io_error_bits_REG_address;
    release u_i.inner_l2cache.slices_0.u_core.io_perf_0_value_REG;
    release u_i.inner_l2cache.slices_0.u_core.io_perf_0_value_REG_1;
    release u_i.inner_l2cache.slices_0.u_core.io_perf_1_value_REG;
    release u_i.inner_l2cache.slices_0.u_core.io_perf_1_value_REG_1;
    release u_i.inner_l2cache.slices_0.u_core.io_perf_3_value_REG;
    release u_i.inner_l2cache.slices_0.u_core.io_perf_3_value_REG_1;
    release u_i.inner_l2cache.slices_0.u_core.io_perf_4_value_REG;
    release u_i.inner_l2cache.slices_0.u_core.io_perf_4_value_REG_1;
    release u_i.inner_l2cache.slices_0.u_core.io_perf_5_value_REG;
    release u_i.inner_l2cache.slices_0.u_core.io_perf_5_value_REG_1;
    release u_i.inner_l2cache.slices_0.u_core.io_perf_6_value_REG;
    release u_i.inner_l2cache.slices_0.u_core.io_perf_6_value_REG_1;
    release u_i.inner_l2cache.slices_0.u_core.io_perf_7_value_REG;
    release u_i.inner_l2cache.slices_0.u_core.io_perf_7_value_REG_1;
    release u_i.inner_l2cache.slices_0.u_core.io_perf_8_value_REG;
    release u_i.inner_l2cache.slices_0.u_core.io_perf_8_value_REG_1;
    release u_i.inner_l2cache.slices_0.u_core.io_perf_9_value_REG;
    release u_i.inner_l2cache.slices_0.u_core.io_perf_9_value_REG_1;
    release u_i.inner_l2cache.slices_0.u_core.io_perf_10_value_REG;
    release u_i.inner_l2cache.slices_0.u_core.io_perf_10_value_REG_1;
    release u_i.inner_l2cache.slices_0.u_core.io_perf_11_value_REG;
    release u_i.inner_l2cache.slices_0.u_core.io_perf_11_value_REG_1;
    release u_i.inner_l2cache.slices_0.u_core.io_perf_12_value_REG;
    release u_i.inner_l2cache.slices_0.u_core.io_perf_12_value_REG_1;
    release u_i.inner_l2cache.slices_0.u_core.io_perf_13_value_REG;
    release u_i.inner_l2cache.slices_0.u_core.io_perf_13_value_REG_1;
    release u_i.inner_l2cache.slices_0.u_core.io_perf_14_value_REG;
    release u_i.inner_l2cache.slices_0.u_core.io_perf_14_value_REG_1;
    release u_i.inner_l2cache.slices_0.u_core.io_perf_15_value_REG;
    release u_i.inner_l2cache.slices_0.u_core.io_perf_15_value_REG_1;
    release u_i.inner_l2cache.slices_0.u_core.io_perf_16_value_REG;
    release u_i.inner_l2cache.slices_0.u_core.io_perf_16_value_REG_1;
    release u_i.inner_l2cache.slices_1.u_core.mshrCtl.u_core.mshrs[0].entry.u_core.tgtid_rcompack;
    release u_i.inner_l2cache.slices_1.u_core.mshrCtl.u_core.mshrs[0].entry.u_core.txnid_rcompack;
    release u_i.inner_l2cache.slices_1.u_core.mshrCtl.u_core.mshrs[0].entry.u_core.tgtid_wcompack;
    release u_i.inner_l2cache.slices_1.u_core.mshrCtl.u_core.mshrs[0].entry.u_core.txnid_wcompack;
    release u_i.inner_l2cache.slices_1.u_core.mshrCtl.u_core.mshrs[0].entry.u_core.srcid_retryack;
    release u_i.inner_l2cache.slices_1.u_core.mshrCtl.u_core.mshrs[0].entry.u_core.acquire_ts;
    release u_i.inner_l2cache.slices_1.u_core.mshrCtl.u_core.mshrs[0].entry.u_core.release_ts;
    release u_i.inner_l2cache.slices_1.u_core.mshrCtl.u_core.mshrs[0].entry.u_core.acquire_period_valid_REG;
    release u_i.inner_l2cache.slices_1.u_core.mshrCtl.u_core.mshrs[0].entry.u_core.release_period_valid_REG;
    release u_i.inner_l2cache.slices_1.u_core.mshrCtl.u_core.mshrs[0].entry.u_core.REG;
    release u_i.inner_l2cache.slices_1.u_core.mshrCtl.u_core.mshrs[0].entry.u_core.REG_1;
    release u_i.inner_l2cache.slices_1.u_core.mshrCtl.u_core.mshrs[0].entry.u_core.REG_2;
    release u_i.inner_l2cache.slices_1.u_core.mshrCtl.u_core.mshrs[0].entry.u_core.REG_3;
    release u_i.inner_l2cache.slices_1.u_core.mshrCtl.u_core.mshrs[1].entry.u_core.tgtid_rcompack;
    release u_i.inner_l2cache.slices_1.u_core.mshrCtl.u_core.mshrs[1].entry.u_core.txnid_rcompack;
    release u_i.inner_l2cache.slices_1.u_core.mshrCtl.u_core.mshrs[1].entry.u_core.tgtid_wcompack;
    release u_i.inner_l2cache.slices_1.u_core.mshrCtl.u_core.mshrs[1].entry.u_core.txnid_wcompack;
    release u_i.inner_l2cache.slices_1.u_core.mshrCtl.u_core.mshrs[1].entry.u_core.srcid_retryack;
    release u_i.inner_l2cache.slices_1.u_core.mshrCtl.u_core.mshrs[1].entry.u_core.acquire_ts;
    release u_i.inner_l2cache.slices_1.u_core.mshrCtl.u_core.mshrs[1].entry.u_core.release_ts;
    release u_i.inner_l2cache.slices_1.u_core.mshrCtl.u_core.mshrs[1].entry.u_core.acquire_period_valid_REG;
    release u_i.inner_l2cache.slices_1.u_core.mshrCtl.u_core.mshrs[1].entry.u_core.release_period_valid_REG;
    release u_i.inner_l2cache.slices_1.u_core.mshrCtl.u_core.mshrs[1].entry.u_core.REG;
    release u_i.inner_l2cache.slices_1.u_core.mshrCtl.u_core.mshrs[1].entry.u_core.REG_1;
    release u_i.inner_l2cache.slices_1.u_core.mshrCtl.u_core.mshrs[1].entry.u_core.REG_2;
    release u_i.inner_l2cache.slices_1.u_core.mshrCtl.u_core.mshrs[1].entry.u_core.REG_3;
    release u_i.inner_l2cache.slices_1.u_core.mshrCtl.u_core.mshrs[2].entry.u_core.tgtid_rcompack;
    release u_i.inner_l2cache.slices_1.u_core.mshrCtl.u_core.mshrs[2].entry.u_core.txnid_rcompack;
    release u_i.inner_l2cache.slices_1.u_core.mshrCtl.u_core.mshrs[2].entry.u_core.tgtid_wcompack;
    release u_i.inner_l2cache.slices_1.u_core.mshrCtl.u_core.mshrs[2].entry.u_core.txnid_wcompack;
    release u_i.inner_l2cache.slices_1.u_core.mshrCtl.u_core.mshrs[2].entry.u_core.srcid_retryack;
    release u_i.inner_l2cache.slices_1.u_core.mshrCtl.u_core.mshrs[2].entry.u_core.acquire_ts;
    release u_i.inner_l2cache.slices_1.u_core.mshrCtl.u_core.mshrs[2].entry.u_core.release_ts;
    release u_i.inner_l2cache.slices_1.u_core.mshrCtl.u_core.mshrs[2].entry.u_core.acquire_period_valid_REG;
    release u_i.inner_l2cache.slices_1.u_core.mshrCtl.u_core.mshrs[2].entry.u_core.release_period_valid_REG;
    release u_i.inner_l2cache.slices_1.u_core.mshrCtl.u_core.mshrs[2].entry.u_core.REG;
    release u_i.inner_l2cache.slices_1.u_core.mshrCtl.u_core.mshrs[2].entry.u_core.REG_1;
    release u_i.inner_l2cache.slices_1.u_core.mshrCtl.u_core.mshrs[2].entry.u_core.REG_2;
    release u_i.inner_l2cache.slices_1.u_core.mshrCtl.u_core.mshrs[2].entry.u_core.REG_3;
    release u_i.inner_l2cache.slices_1.u_core.mshrCtl.u_core.mshrs[3].entry.u_core.tgtid_rcompack;
    release u_i.inner_l2cache.slices_1.u_core.mshrCtl.u_core.mshrs[3].entry.u_core.txnid_rcompack;
    release u_i.inner_l2cache.slices_1.u_core.mshrCtl.u_core.mshrs[3].entry.u_core.tgtid_wcompack;
    release u_i.inner_l2cache.slices_1.u_core.mshrCtl.u_core.mshrs[3].entry.u_core.txnid_wcompack;
    release u_i.inner_l2cache.slices_1.u_core.mshrCtl.u_core.mshrs[3].entry.u_core.srcid_retryack;
    release u_i.inner_l2cache.slices_1.u_core.mshrCtl.u_core.mshrs[3].entry.u_core.acquire_ts;
    release u_i.inner_l2cache.slices_1.u_core.mshrCtl.u_core.mshrs[3].entry.u_core.release_ts;
    release u_i.inner_l2cache.slices_1.u_core.mshrCtl.u_core.mshrs[3].entry.u_core.acquire_period_valid_REG;
    release u_i.inner_l2cache.slices_1.u_core.mshrCtl.u_core.mshrs[3].entry.u_core.release_period_valid_REG;
    release u_i.inner_l2cache.slices_1.u_core.mshrCtl.u_core.mshrs[3].entry.u_core.REG;
    release u_i.inner_l2cache.slices_1.u_core.mshrCtl.u_core.mshrs[3].entry.u_core.REG_1;
    release u_i.inner_l2cache.slices_1.u_core.mshrCtl.u_core.mshrs[3].entry.u_core.REG_2;
    release u_i.inner_l2cache.slices_1.u_core.mshrCtl.u_core.mshrs[3].entry.u_core.REG_3;
    release u_i.inner_l2cache.slices_1.u_core.mshrCtl.u_core.mshrs[4].entry.u_core.tgtid_rcompack;
    release u_i.inner_l2cache.slices_1.u_core.mshrCtl.u_core.mshrs[4].entry.u_core.txnid_rcompack;
    release u_i.inner_l2cache.slices_1.u_core.mshrCtl.u_core.mshrs[4].entry.u_core.tgtid_wcompack;
    release u_i.inner_l2cache.slices_1.u_core.mshrCtl.u_core.mshrs[4].entry.u_core.txnid_wcompack;
    release u_i.inner_l2cache.slices_1.u_core.mshrCtl.u_core.mshrs[4].entry.u_core.srcid_retryack;
    release u_i.inner_l2cache.slices_1.u_core.mshrCtl.u_core.mshrs[4].entry.u_core.acquire_ts;
    release u_i.inner_l2cache.slices_1.u_core.mshrCtl.u_core.mshrs[4].entry.u_core.release_ts;
    release u_i.inner_l2cache.slices_1.u_core.mshrCtl.u_core.mshrs[4].entry.u_core.acquire_period_valid_REG;
    release u_i.inner_l2cache.slices_1.u_core.mshrCtl.u_core.mshrs[4].entry.u_core.release_period_valid_REG;
    release u_i.inner_l2cache.slices_1.u_core.mshrCtl.u_core.mshrs[4].entry.u_core.REG;
    release u_i.inner_l2cache.slices_1.u_core.mshrCtl.u_core.mshrs[4].entry.u_core.REG_1;
    release u_i.inner_l2cache.slices_1.u_core.mshrCtl.u_core.mshrs[4].entry.u_core.REG_2;
    release u_i.inner_l2cache.slices_1.u_core.mshrCtl.u_core.mshrs[4].entry.u_core.REG_3;
    release u_i.inner_l2cache.slices_1.u_core.mshrCtl.u_core.mshrs[5].entry.u_core.tgtid_rcompack;
    release u_i.inner_l2cache.slices_1.u_core.mshrCtl.u_core.mshrs[5].entry.u_core.txnid_rcompack;
    release u_i.inner_l2cache.slices_1.u_core.mshrCtl.u_core.mshrs[5].entry.u_core.tgtid_wcompack;
    release u_i.inner_l2cache.slices_1.u_core.mshrCtl.u_core.mshrs[5].entry.u_core.txnid_wcompack;
    release u_i.inner_l2cache.slices_1.u_core.mshrCtl.u_core.mshrs[5].entry.u_core.srcid_retryack;
    release u_i.inner_l2cache.slices_1.u_core.mshrCtl.u_core.mshrs[5].entry.u_core.acquire_ts;
    release u_i.inner_l2cache.slices_1.u_core.mshrCtl.u_core.mshrs[5].entry.u_core.release_ts;
    release u_i.inner_l2cache.slices_1.u_core.mshrCtl.u_core.mshrs[5].entry.u_core.acquire_period_valid_REG;
    release u_i.inner_l2cache.slices_1.u_core.mshrCtl.u_core.mshrs[5].entry.u_core.release_period_valid_REG;
    release u_i.inner_l2cache.slices_1.u_core.mshrCtl.u_core.mshrs[5].entry.u_core.REG;
    release u_i.inner_l2cache.slices_1.u_core.mshrCtl.u_core.mshrs[5].entry.u_core.REG_1;
    release u_i.inner_l2cache.slices_1.u_core.mshrCtl.u_core.mshrs[5].entry.u_core.REG_2;
    release u_i.inner_l2cache.slices_1.u_core.mshrCtl.u_core.mshrs[5].entry.u_core.REG_3;
    release u_i.inner_l2cache.slices_1.u_core.mshrCtl.u_core.mshrs[6].entry.u_core.tgtid_rcompack;
    release u_i.inner_l2cache.slices_1.u_core.mshrCtl.u_core.mshrs[6].entry.u_core.txnid_rcompack;
    release u_i.inner_l2cache.slices_1.u_core.mshrCtl.u_core.mshrs[6].entry.u_core.tgtid_wcompack;
    release u_i.inner_l2cache.slices_1.u_core.mshrCtl.u_core.mshrs[6].entry.u_core.txnid_wcompack;
    release u_i.inner_l2cache.slices_1.u_core.mshrCtl.u_core.mshrs[6].entry.u_core.srcid_retryack;
    release u_i.inner_l2cache.slices_1.u_core.mshrCtl.u_core.mshrs[6].entry.u_core.acquire_ts;
    release u_i.inner_l2cache.slices_1.u_core.mshrCtl.u_core.mshrs[6].entry.u_core.release_ts;
    release u_i.inner_l2cache.slices_1.u_core.mshrCtl.u_core.mshrs[6].entry.u_core.acquire_period_valid_REG;
    release u_i.inner_l2cache.slices_1.u_core.mshrCtl.u_core.mshrs[6].entry.u_core.release_period_valid_REG;
    release u_i.inner_l2cache.slices_1.u_core.mshrCtl.u_core.mshrs[6].entry.u_core.REG;
    release u_i.inner_l2cache.slices_1.u_core.mshrCtl.u_core.mshrs[6].entry.u_core.REG_1;
    release u_i.inner_l2cache.slices_1.u_core.mshrCtl.u_core.mshrs[6].entry.u_core.REG_2;
    release u_i.inner_l2cache.slices_1.u_core.mshrCtl.u_core.mshrs[6].entry.u_core.REG_3;
    release u_i.inner_l2cache.slices_1.u_core.mshrCtl.u_core.mshrs[7].entry.u_core.tgtid_rcompack;
    release u_i.inner_l2cache.slices_1.u_core.mshrCtl.u_core.mshrs[7].entry.u_core.txnid_rcompack;
    release u_i.inner_l2cache.slices_1.u_core.mshrCtl.u_core.mshrs[7].entry.u_core.tgtid_wcompack;
    release u_i.inner_l2cache.slices_1.u_core.mshrCtl.u_core.mshrs[7].entry.u_core.txnid_wcompack;
    release u_i.inner_l2cache.slices_1.u_core.mshrCtl.u_core.mshrs[7].entry.u_core.srcid_retryack;
    release u_i.inner_l2cache.slices_1.u_core.mshrCtl.u_core.mshrs[7].entry.u_core.acquire_ts;
    release u_i.inner_l2cache.slices_1.u_core.mshrCtl.u_core.mshrs[7].entry.u_core.release_ts;
    release u_i.inner_l2cache.slices_1.u_core.mshrCtl.u_core.mshrs[7].entry.u_core.acquire_period_valid_REG;
    release u_i.inner_l2cache.slices_1.u_core.mshrCtl.u_core.mshrs[7].entry.u_core.release_period_valid_REG;
    release u_i.inner_l2cache.slices_1.u_core.mshrCtl.u_core.mshrs[7].entry.u_core.REG;
    release u_i.inner_l2cache.slices_1.u_core.mshrCtl.u_core.mshrs[7].entry.u_core.REG_1;
    release u_i.inner_l2cache.slices_1.u_core.mshrCtl.u_core.mshrs[7].entry.u_core.REG_2;
    release u_i.inner_l2cache.slices_1.u_core.mshrCtl.u_core.mshrs[7].entry.u_core.REG_3;
    release u_i.inner_l2cache.slices_1.u_core.mshrCtl.u_core.mshrs[8].entry.u_core.tgtid_rcompack;
    release u_i.inner_l2cache.slices_1.u_core.mshrCtl.u_core.mshrs[8].entry.u_core.txnid_rcompack;
    release u_i.inner_l2cache.slices_1.u_core.mshrCtl.u_core.mshrs[8].entry.u_core.tgtid_wcompack;
    release u_i.inner_l2cache.slices_1.u_core.mshrCtl.u_core.mshrs[8].entry.u_core.txnid_wcompack;
    release u_i.inner_l2cache.slices_1.u_core.mshrCtl.u_core.mshrs[8].entry.u_core.srcid_retryack;
    release u_i.inner_l2cache.slices_1.u_core.mshrCtl.u_core.mshrs[8].entry.u_core.acquire_ts;
    release u_i.inner_l2cache.slices_1.u_core.mshrCtl.u_core.mshrs[8].entry.u_core.release_ts;
    release u_i.inner_l2cache.slices_1.u_core.mshrCtl.u_core.mshrs[8].entry.u_core.acquire_period_valid_REG;
    release u_i.inner_l2cache.slices_1.u_core.mshrCtl.u_core.mshrs[8].entry.u_core.release_period_valid_REG;
    release u_i.inner_l2cache.slices_1.u_core.mshrCtl.u_core.mshrs[8].entry.u_core.REG;
    release u_i.inner_l2cache.slices_1.u_core.mshrCtl.u_core.mshrs[8].entry.u_core.REG_1;
    release u_i.inner_l2cache.slices_1.u_core.mshrCtl.u_core.mshrs[8].entry.u_core.REG_2;
    release u_i.inner_l2cache.slices_1.u_core.mshrCtl.u_core.mshrs[8].entry.u_core.REG_3;
    release u_i.inner_l2cache.slices_1.u_core.mshrCtl.u_core.mshrs[9].entry.u_core.tgtid_rcompack;
    release u_i.inner_l2cache.slices_1.u_core.mshrCtl.u_core.mshrs[9].entry.u_core.txnid_rcompack;
    release u_i.inner_l2cache.slices_1.u_core.mshrCtl.u_core.mshrs[9].entry.u_core.tgtid_wcompack;
    release u_i.inner_l2cache.slices_1.u_core.mshrCtl.u_core.mshrs[9].entry.u_core.txnid_wcompack;
    release u_i.inner_l2cache.slices_1.u_core.mshrCtl.u_core.mshrs[9].entry.u_core.srcid_retryack;
    release u_i.inner_l2cache.slices_1.u_core.mshrCtl.u_core.mshrs[9].entry.u_core.acquire_ts;
    release u_i.inner_l2cache.slices_1.u_core.mshrCtl.u_core.mshrs[9].entry.u_core.release_ts;
    release u_i.inner_l2cache.slices_1.u_core.mshrCtl.u_core.mshrs[9].entry.u_core.acquire_period_valid_REG;
    release u_i.inner_l2cache.slices_1.u_core.mshrCtl.u_core.mshrs[9].entry.u_core.release_period_valid_REG;
    release u_i.inner_l2cache.slices_1.u_core.mshrCtl.u_core.mshrs[9].entry.u_core.REG;
    release u_i.inner_l2cache.slices_1.u_core.mshrCtl.u_core.mshrs[9].entry.u_core.REG_1;
    release u_i.inner_l2cache.slices_1.u_core.mshrCtl.u_core.mshrs[9].entry.u_core.REG_2;
    release u_i.inner_l2cache.slices_1.u_core.mshrCtl.u_core.mshrs[9].entry.u_core.REG_3;
    release u_i.inner_l2cache.slices_1.u_core.mshrCtl.u_core.mshrs[10].entry.u_core.tgtid_rcompack;
    release u_i.inner_l2cache.slices_1.u_core.mshrCtl.u_core.mshrs[10].entry.u_core.txnid_rcompack;
    release u_i.inner_l2cache.slices_1.u_core.mshrCtl.u_core.mshrs[10].entry.u_core.tgtid_wcompack;
    release u_i.inner_l2cache.slices_1.u_core.mshrCtl.u_core.mshrs[10].entry.u_core.txnid_wcompack;
    release u_i.inner_l2cache.slices_1.u_core.mshrCtl.u_core.mshrs[10].entry.u_core.srcid_retryack;
    release u_i.inner_l2cache.slices_1.u_core.mshrCtl.u_core.mshrs[10].entry.u_core.acquire_ts;
    release u_i.inner_l2cache.slices_1.u_core.mshrCtl.u_core.mshrs[10].entry.u_core.release_ts;
    release u_i.inner_l2cache.slices_1.u_core.mshrCtl.u_core.mshrs[10].entry.u_core.acquire_period_valid_REG;
    release u_i.inner_l2cache.slices_1.u_core.mshrCtl.u_core.mshrs[10].entry.u_core.release_period_valid_REG;
    release u_i.inner_l2cache.slices_1.u_core.mshrCtl.u_core.mshrs[10].entry.u_core.REG;
    release u_i.inner_l2cache.slices_1.u_core.mshrCtl.u_core.mshrs[10].entry.u_core.REG_1;
    release u_i.inner_l2cache.slices_1.u_core.mshrCtl.u_core.mshrs[10].entry.u_core.REG_2;
    release u_i.inner_l2cache.slices_1.u_core.mshrCtl.u_core.mshrs[10].entry.u_core.REG_3;
    release u_i.inner_l2cache.slices_1.u_core.mshrCtl.u_core.mshrs[11].entry.u_core.tgtid_rcompack;
    release u_i.inner_l2cache.slices_1.u_core.mshrCtl.u_core.mshrs[11].entry.u_core.txnid_rcompack;
    release u_i.inner_l2cache.slices_1.u_core.mshrCtl.u_core.mshrs[11].entry.u_core.tgtid_wcompack;
    release u_i.inner_l2cache.slices_1.u_core.mshrCtl.u_core.mshrs[11].entry.u_core.txnid_wcompack;
    release u_i.inner_l2cache.slices_1.u_core.mshrCtl.u_core.mshrs[11].entry.u_core.srcid_retryack;
    release u_i.inner_l2cache.slices_1.u_core.mshrCtl.u_core.mshrs[11].entry.u_core.acquire_ts;
    release u_i.inner_l2cache.slices_1.u_core.mshrCtl.u_core.mshrs[11].entry.u_core.release_ts;
    release u_i.inner_l2cache.slices_1.u_core.mshrCtl.u_core.mshrs[11].entry.u_core.acquire_period_valid_REG;
    release u_i.inner_l2cache.slices_1.u_core.mshrCtl.u_core.mshrs[11].entry.u_core.release_period_valid_REG;
    release u_i.inner_l2cache.slices_1.u_core.mshrCtl.u_core.mshrs[11].entry.u_core.REG;
    release u_i.inner_l2cache.slices_1.u_core.mshrCtl.u_core.mshrs[11].entry.u_core.REG_1;
    release u_i.inner_l2cache.slices_1.u_core.mshrCtl.u_core.mshrs[11].entry.u_core.REG_2;
    release u_i.inner_l2cache.slices_1.u_core.mshrCtl.u_core.mshrs[11].entry.u_core.REG_3;
    release u_i.inner_l2cache.slices_1.u_core.mshrCtl.u_core.mshrs[12].entry.u_core.tgtid_rcompack;
    release u_i.inner_l2cache.slices_1.u_core.mshrCtl.u_core.mshrs[12].entry.u_core.txnid_rcompack;
    release u_i.inner_l2cache.slices_1.u_core.mshrCtl.u_core.mshrs[12].entry.u_core.tgtid_wcompack;
    release u_i.inner_l2cache.slices_1.u_core.mshrCtl.u_core.mshrs[12].entry.u_core.txnid_wcompack;
    release u_i.inner_l2cache.slices_1.u_core.mshrCtl.u_core.mshrs[12].entry.u_core.srcid_retryack;
    release u_i.inner_l2cache.slices_1.u_core.mshrCtl.u_core.mshrs[12].entry.u_core.acquire_ts;
    release u_i.inner_l2cache.slices_1.u_core.mshrCtl.u_core.mshrs[12].entry.u_core.release_ts;
    release u_i.inner_l2cache.slices_1.u_core.mshrCtl.u_core.mshrs[12].entry.u_core.acquire_period_valid_REG;
    release u_i.inner_l2cache.slices_1.u_core.mshrCtl.u_core.mshrs[12].entry.u_core.release_period_valid_REG;
    release u_i.inner_l2cache.slices_1.u_core.mshrCtl.u_core.mshrs[12].entry.u_core.REG;
    release u_i.inner_l2cache.slices_1.u_core.mshrCtl.u_core.mshrs[12].entry.u_core.REG_1;
    release u_i.inner_l2cache.slices_1.u_core.mshrCtl.u_core.mshrs[12].entry.u_core.REG_2;
    release u_i.inner_l2cache.slices_1.u_core.mshrCtl.u_core.mshrs[12].entry.u_core.REG_3;
    release u_i.inner_l2cache.slices_1.u_core.mshrCtl.u_core.mshrs[13].entry.u_core.tgtid_rcompack;
    release u_i.inner_l2cache.slices_1.u_core.mshrCtl.u_core.mshrs[13].entry.u_core.txnid_rcompack;
    release u_i.inner_l2cache.slices_1.u_core.mshrCtl.u_core.mshrs[13].entry.u_core.tgtid_wcompack;
    release u_i.inner_l2cache.slices_1.u_core.mshrCtl.u_core.mshrs[13].entry.u_core.txnid_wcompack;
    release u_i.inner_l2cache.slices_1.u_core.mshrCtl.u_core.mshrs[13].entry.u_core.srcid_retryack;
    release u_i.inner_l2cache.slices_1.u_core.mshrCtl.u_core.mshrs[13].entry.u_core.acquire_ts;
    release u_i.inner_l2cache.slices_1.u_core.mshrCtl.u_core.mshrs[13].entry.u_core.release_ts;
    release u_i.inner_l2cache.slices_1.u_core.mshrCtl.u_core.mshrs[13].entry.u_core.acquire_period_valid_REG;
    release u_i.inner_l2cache.slices_1.u_core.mshrCtl.u_core.mshrs[13].entry.u_core.release_period_valid_REG;
    release u_i.inner_l2cache.slices_1.u_core.mshrCtl.u_core.mshrs[13].entry.u_core.REG;
    release u_i.inner_l2cache.slices_1.u_core.mshrCtl.u_core.mshrs[13].entry.u_core.REG_1;
    release u_i.inner_l2cache.slices_1.u_core.mshrCtl.u_core.mshrs[13].entry.u_core.REG_2;
    release u_i.inner_l2cache.slices_1.u_core.mshrCtl.u_core.mshrs[13].entry.u_core.REG_3;
    release u_i.inner_l2cache.slices_1.u_core.mshrCtl.u_core.mshrs[14].entry.u_core.tgtid_rcompack;
    release u_i.inner_l2cache.slices_1.u_core.mshrCtl.u_core.mshrs[14].entry.u_core.txnid_rcompack;
    release u_i.inner_l2cache.slices_1.u_core.mshrCtl.u_core.mshrs[14].entry.u_core.tgtid_wcompack;
    release u_i.inner_l2cache.slices_1.u_core.mshrCtl.u_core.mshrs[14].entry.u_core.txnid_wcompack;
    release u_i.inner_l2cache.slices_1.u_core.mshrCtl.u_core.mshrs[14].entry.u_core.srcid_retryack;
    release u_i.inner_l2cache.slices_1.u_core.mshrCtl.u_core.mshrs[14].entry.u_core.acquire_ts;
    release u_i.inner_l2cache.slices_1.u_core.mshrCtl.u_core.mshrs[14].entry.u_core.release_ts;
    release u_i.inner_l2cache.slices_1.u_core.mshrCtl.u_core.mshrs[14].entry.u_core.acquire_period_valid_REG;
    release u_i.inner_l2cache.slices_1.u_core.mshrCtl.u_core.mshrs[14].entry.u_core.release_period_valid_REG;
    release u_i.inner_l2cache.slices_1.u_core.mshrCtl.u_core.mshrs[14].entry.u_core.REG;
    release u_i.inner_l2cache.slices_1.u_core.mshrCtl.u_core.mshrs[14].entry.u_core.REG_1;
    release u_i.inner_l2cache.slices_1.u_core.mshrCtl.u_core.mshrs[14].entry.u_core.REG_2;
    release u_i.inner_l2cache.slices_1.u_core.mshrCtl.u_core.mshrs[14].entry.u_core.REG_3;
    release u_i.inner_l2cache.slices_1.u_core.mshrCtl.u_core.mshrs[15].entry.u_core.tgtid_rcompack;
    release u_i.inner_l2cache.slices_1.u_core.mshrCtl.u_core.mshrs[15].entry.u_core.txnid_rcompack;
    release u_i.inner_l2cache.slices_1.u_core.mshrCtl.u_core.mshrs[15].entry.u_core.tgtid_wcompack;
    release u_i.inner_l2cache.slices_1.u_core.mshrCtl.u_core.mshrs[15].entry.u_core.txnid_wcompack;
    release u_i.inner_l2cache.slices_1.u_core.mshrCtl.u_core.mshrs[15].entry.u_core.srcid_retryack;
    release u_i.inner_l2cache.slices_1.u_core.mshrCtl.u_core.mshrs[15].entry.u_core.acquire_ts;
    release u_i.inner_l2cache.slices_1.u_core.mshrCtl.u_core.mshrs[15].entry.u_core.release_ts;
    release u_i.inner_l2cache.slices_1.u_core.mshrCtl.u_core.mshrs[15].entry.u_core.acquire_period_valid_REG;
    release u_i.inner_l2cache.slices_1.u_core.mshrCtl.u_core.mshrs[15].entry.u_core.release_period_valid_REG;
    release u_i.inner_l2cache.slices_1.u_core.mshrCtl.u_core.mshrs[15].entry.u_core.REG;
    release u_i.inner_l2cache.slices_1.u_core.mshrCtl.u_core.mshrs[15].entry.u_core.REG_1;
    release u_i.inner_l2cache.slices_1.u_core.mshrCtl.u_core.mshrs[15].entry.u_core.REG_2;
    release u_i.inner_l2cache.slices_1.u_core.mshrCtl.u_core.mshrs[15].entry.u_core.REG_3;
    release u_i.inner_l2cache.slices_1.u_core.mshrCtl.u_core.io_perf_0_value_REG;
    release u_i.inner_l2cache.slices_1.u_core.mshrCtl.u_core.io_perf_0_value_REG_1;
    release u_i.inner_l2cache.slices_1.u_core.mshrCtl.u_core.io_perf_1_value_REG;
    release u_i.inner_l2cache.slices_1.u_core.mshrCtl.u_core.io_perf_1_value_REG_1;
    release u_i.inner_l2cache.slices_1.u_core.mshrCtl.u_core.io_perf_3_value_REG;
    release u_i.inner_l2cache.slices_1.u_core.mshrCtl.u_core.io_perf_3_value_REG_1;
    release u_i.inner_l2cache.slices_1.u_core.mshrCtl.u_core.REG;
    release u_i.inner_l2cache.slices_1.u_core.mainPipe.u_core.data_s4;
    release u_i.inner_l2cache.slices_1.u_core.mainPipe.u_core.data_s5;
    release u_i.inner_l2cache.slices_1.u_core.mainPipe.u_core.s3DropValid_d1;
    release u_i.inner_l2cache.slices_1.u_core.mainPipe.u_core.reqDrop_s3_d1;
    release u_i.inner_l2cache.slices_1.u_core.mainPipe.u_core.reqDrop_s3_d2;
    release u_i.inner_l2cache.slices_1.u_core.mainPipe.u_core.reqDrop_s4_d1;
    release u_i.inner_l2cache.slices_1.u_core.mainPipe.u_core.perf_d1[0];
    release u_i.inner_l2cache.slices_1.u_core.mainPipe.u_core.perf[0];
    release u_i.inner_l2cache.slices_1.u_core.mainPipe.u_core.perf_d1[1];
    release u_i.inner_l2cache.slices_1.u_core.mainPipe.u_core.perf[1];
    release u_i.inner_l2cache.slices_1.u_core.mainPipe.u_core.perf_d1[2];
    release u_i.inner_l2cache.slices_1.u_core.mainPipe.u_core.perf[2];
    release u_i.inner_l2cache.slices_1.u_core.mainPipe.u_core.perf_d1[3];
    release u_i.inner_l2cache.slices_1.u_core.mainPipe.u_core.perf[3];
    release u_i.inner_l2cache.slices_1.u_core.mainPipe.u_core.perf_d1[4];
    release u_i.inner_l2cache.slices_1.u_core.mainPipe.u_core.perf[4];
    release u_i.inner_l2cache.slices_1.u_core.mainPipe.u_core.perf_d1[5];
    release u_i.inner_l2cache.slices_1.u_core.mainPipe.u_core.perf[5];
    release u_i.inner_l2cache.slices_1.u_core.mainPipe.u_core.perf_d1[6];
    release u_i.inner_l2cache.slices_1.u_core.mainPipe.u_core.perf[6];
    release u_i.inner_l2cache.slices_1.u_core.mainPipe.u_core.perf_d1[7];
    release u_i.inner_l2cache.slices_1.u_core.mainPipe.u_core.perf[7];
    release u_i.inner_l2cache.slices_1.u_core.mainPipe.u_core.perf_d1[8];
    release u_i.inner_l2cache.slices_1.u_core.mainPipe.u_core.perf[8];
    release u_i.inner_l2cache.slices_1.u_core.mainPipe.u_core.perf_d1[9];
    release u_i.inner_l2cache.slices_1.u_core.mainPipe.u_core.perf[9];
    release u_i.inner_l2cache.slices_1.u_core.mainPipe.u_core.perf_d1[10];
    release u_i.inner_l2cache.slices_1.u_core.mainPipe.u_core.perf[10];
    release u_i.inner_l2cache.slices_1.u_core.mainPipe.u_core.perf_d1[11];
    release u_i.inner_l2cache.slices_1.u_core.mainPipe.u_core.perf[11];
    release u_i.inner_l2cache.slices_1.u_core.mainPipe.u_core.perf_d1[12];
    release u_i.inner_l2cache.slices_1.u_core.mainPipe.u_core.perf[12];
    release u_i.inner_l2cache.slices_1.u_core.grantBuf.u_core.validPrev[0];
    release u_i.inner_l2cache.slices_1.u_core.grantBuf.u_core.histValidPrev[0];
    release u_i.inner_l2cache.slices_1.u_core.grantBuf.u_core.validPrev[1];
    release u_i.inner_l2cache.slices_1.u_core.grantBuf.u_core.histValidPrev[1];
    release u_i.inner_l2cache.slices_1.u_core.grantBuf.u_core.validPrev[2];
    release u_i.inner_l2cache.slices_1.u_core.grantBuf.u_core.histValidPrev[2];
    release u_i.inner_l2cache.slices_1.u_core.grantBuf.u_core.validPrev[3];
    release u_i.inner_l2cache.slices_1.u_core.grantBuf.u_core.histValidPrev[3];
    release u_i.inner_l2cache.slices_1.u_core.grantBuf.u_core.validPrev[4];
    release u_i.inner_l2cache.slices_1.u_core.grantBuf.u_core.histValidPrev[4];
    release u_i.inner_l2cache.slices_1.u_core.grantBuf.u_core.validPrev[5];
    release u_i.inner_l2cache.slices_1.u_core.grantBuf.u_core.histValidPrev[5];
    release u_i.inner_l2cache.slices_1.u_core.grantBuf.u_core.validPrev[6];
    release u_i.inner_l2cache.slices_1.u_core.grantBuf.u_core.histValidPrev[6];
    release u_i.inner_l2cache.slices_1.u_core.grantBuf.u_core.validPrev[7];
    release u_i.inner_l2cache.slices_1.u_core.grantBuf.u_core.histValidPrev[7];
    release u_i.inner_l2cache.slices_1.u_core.grantBuf.u_core.validPrev[8];
    release u_i.inner_l2cache.slices_1.u_core.grantBuf.u_core.histValidPrev[8];
    release u_i.inner_l2cache.slices_1.u_core.grantBuf.u_core.validPrev[9];
    release u_i.inner_l2cache.slices_1.u_core.grantBuf.u_core.histValidPrev[9];
    release u_i.inner_l2cache.slices_1.u_core.grantBuf.u_core.validPrev[10];
    release u_i.inner_l2cache.slices_1.u_core.grantBuf.u_core.histValidPrev[10];
    release u_i.inner_l2cache.slices_1.u_core.grantBuf.u_core.validPrev[11];
    release u_i.inner_l2cache.slices_1.u_core.grantBuf.u_core.histValidPrev[11];
    release u_i.inner_l2cache.slices_1.u_core.grantBuf.u_core.validPrev[12];
    release u_i.inner_l2cache.slices_1.u_core.grantBuf.u_core.histValidPrev[12];
    release u_i.inner_l2cache.slices_1.u_core.grantBuf.u_core.validPrev[13];
    release u_i.inner_l2cache.slices_1.u_core.grantBuf.u_core.histValidPrev[13];
    release u_i.inner_l2cache.slices_1.u_core.grantBuf.u_core.validPrev[14];
    release u_i.inner_l2cache.slices_1.u_core.grantBuf.u_core.histValidPrev[14];
    release u_i.inner_l2cache.slices_1.u_core.grantBuf.u_core.validPrev[15];
    release u_i.inner_l2cache.slices_1.u_core.grantBuf.u_core.histValidPrev[15];
    release u_i.inner_l2cache.slices_1.u_core.rxsnp.u_core.replPrevForBlock[0];
    release u_i.inner_l2cache.slices_1.u_core.rxsnp.u_core.replPrevForNest[0];
    release u_i.inner_l2cache.slices_1.u_core.rxsnp.u_core.replPrevForBlock[1];
    release u_i.inner_l2cache.slices_1.u_core.rxsnp.u_core.replPrevForNest[1];
    release u_i.inner_l2cache.slices_1.u_core.rxsnp.u_core.replPrevForBlock[2];
    release u_i.inner_l2cache.slices_1.u_core.rxsnp.u_core.replPrevForNest[2];
    release u_i.inner_l2cache.slices_1.u_core.rxsnp.u_core.replPrevForBlock[3];
    release u_i.inner_l2cache.slices_1.u_core.rxsnp.u_core.replPrevForNest[3];
    release u_i.inner_l2cache.slices_1.u_core.rxsnp.u_core.replPrevForBlock[4];
    release u_i.inner_l2cache.slices_1.u_core.rxsnp.u_core.replPrevForNest[4];
    release u_i.inner_l2cache.slices_1.u_core.rxsnp.u_core.replPrevForBlock[5];
    release u_i.inner_l2cache.slices_1.u_core.rxsnp.u_core.replPrevForNest[5];
    release u_i.inner_l2cache.slices_1.u_core.rxsnp.u_core.replPrevForBlock[6];
    release u_i.inner_l2cache.slices_1.u_core.rxsnp.u_core.replPrevForNest[6];
    release u_i.inner_l2cache.slices_1.u_core.rxsnp.u_core.replPrevForBlock[7];
    release u_i.inner_l2cache.slices_1.u_core.rxsnp.u_core.replPrevForNest[7];
    release u_i.inner_l2cache.slices_1.u_core.rxsnp.u_core.replPrevForBlock[8];
    release u_i.inner_l2cache.slices_1.u_core.rxsnp.u_core.replPrevForNest[8];
    release u_i.inner_l2cache.slices_1.u_core.rxsnp.u_core.replPrevForBlock[9];
    release u_i.inner_l2cache.slices_1.u_core.rxsnp.u_core.replPrevForNest[9];
    release u_i.inner_l2cache.slices_1.u_core.rxsnp.u_core.replPrevForBlock[10];
    release u_i.inner_l2cache.slices_1.u_core.rxsnp.u_core.replPrevForNest[10];
    release u_i.inner_l2cache.slices_1.u_core.rxsnp.u_core.replPrevForBlock[11];
    release u_i.inner_l2cache.slices_1.u_core.rxsnp.u_core.replPrevForNest[11];
    release u_i.inner_l2cache.slices_1.u_core.rxsnp.u_core.replPrevForBlock[12];
    release u_i.inner_l2cache.slices_1.u_core.rxsnp.u_core.replPrevForNest[12];
    release u_i.inner_l2cache.slices_1.u_core.rxsnp.u_core.replPrevForBlock[13];
    release u_i.inner_l2cache.slices_1.u_core.rxsnp.u_core.replPrevForNest[13];
    release u_i.inner_l2cache.slices_1.u_core.rxsnp.u_core.replPrevForBlock[14];
    release u_i.inner_l2cache.slices_1.u_core.rxsnp.u_core.replPrevForNest[14];
    release u_i.inner_l2cache.slices_1.u_core.rxsnp.u_core.replPrevForBlock[15];
    release u_i.inner_l2cache.slices_1.u_core.rxsnp.u_core.replPrevForNest[15];
    release u_i.inner_l2cache.slices_1.u_core.reqBuf.chosenQ.u_core.ram;
    release u_i.inner_l2cache.slices_1.u_core.reqBuf.u_core.hitPfPrev_set;
    release u_i.inner_l2cache.slices_1.u_core.reqBuf.u_core.hitPfPrev_tag;
    release u_i.inner_l2cache.slices_1.u_core.reqBuf.u_core.mergeAPrev_set;
    release u_i.inner_l2cache.slices_1.u_core.reqBuf.u_core.mergeAPrev_tag;
    release u_i.inner_l2cache.slices_1.u_core.reqBuf.u_core.sameSetS3Valid[0];
    release u_i.inner_l2cache.slices_1.u_core.reqBuf.u_core.sameSetS3Set[0];
    release u_i.inner_l2cache.slices_1.u_core.reqBuf.u_core.sameSetS3Valid[1];
    release u_i.inner_l2cache.slices_1.u_core.reqBuf.u_core.sameSetS3Set[1];
    release u_i.inner_l2cache.slices_1.u_core.reqBuf.u_core.sameSetS3Valid[2];
    release u_i.inner_l2cache.slices_1.u_core.reqBuf.u_core.sameSetS3Set[2];
    release u_i.inner_l2cache.slices_1.u_core.reqBuf.u_core.sameSetS3Valid[3];
    release u_i.inner_l2cache.slices_1.u_core.reqBuf.u_core.sameSetS3Set[3];
    release u_i.inner_l2cache.slices_1.u_core.reqBuf.u_core.sameSetS3Valid[4];
    release u_i.inner_l2cache.slices_1.u_core.reqBuf.u_core.sameSetS3Set[4];
    release u_i.inner_l2cache.slices_1.u_core.reqBuf.u_core.sameSetS3Valid[5];
    release u_i.inner_l2cache.slices_1.u_core.reqBuf.u_core.sameSetS3Set[5];
    release u_i.inner_l2cache.slices_1.u_core.sinkC.u_core.bufRespStage[0];
    release u_i.inner_l2cache.slices_1.u_core.sinkC.u_core.bufRespStage[1];
    release u_i.inner_l2cache.slices_1.u_core.sinkC.u_core.bufRespOut[0];
    release u_i.inner_l2cache.slices_1.u_core.sinkC.u_core.bufRespOut[1];
    release u_i.inner_l2cache.slices_1.u_core.sinkC.u_core.refillIdReg;
    release u_i.inner_l2cache.slices_1.u_core.sinkC.u_core.refillBufIdxReg;
    release u_i.inner_l2cache.slices_1.u_core.sinkC.u_core.taskFirePrev;
    release u_i.inner_l2cache.slices_1.u_core.sinkC.u_core.taskBufIdxPrev;
    release u_i.inner_l2cache.slices_1.u_core.reqArb.u_core.ds_mcp2_stall;
    release u_i.inner_l2cache.slices_1.u_core.refillBuf.u_core.buffer[0][0];
    release u_i.inner_l2cache.slices_1.u_core.refillBuf.u_core.buffer[0][1];
    release u_i.inner_l2cache.slices_1.u_core.refillBuf.u_core.buffer[1][0];
    release u_i.inner_l2cache.slices_1.u_core.refillBuf.u_core.buffer[1][1];
    release u_i.inner_l2cache.slices_1.u_core.refillBuf.u_core.buffer[2][0];
    release u_i.inner_l2cache.slices_1.u_core.refillBuf.u_core.buffer[2][1];
    release u_i.inner_l2cache.slices_1.u_core.refillBuf.u_core.buffer[3][0];
    release u_i.inner_l2cache.slices_1.u_core.refillBuf.u_core.buffer[3][1];
    release u_i.inner_l2cache.slices_1.u_core.refillBuf.u_core.buffer[4][0];
    release u_i.inner_l2cache.slices_1.u_core.refillBuf.u_core.buffer[4][1];
    release u_i.inner_l2cache.slices_1.u_core.refillBuf.u_core.buffer[5][0];
    release u_i.inner_l2cache.slices_1.u_core.refillBuf.u_core.buffer[5][1];
    release u_i.inner_l2cache.slices_1.u_core.refillBuf.u_core.buffer[6][0];
    release u_i.inner_l2cache.slices_1.u_core.refillBuf.u_core.buffer[6][1];
    release u_i.inner_l2cache.slices_1.u_core.refillBuf.u_core.buffer[7][0];
    release u_i.inner_l2cache.slices_1.u_core.refillBuf.u_core.buffer[7][1];
    release u_i.inner_l2cache.slices_1.u_core.refillBuf.u_core.buffer[8][0];
    release u_i.inner_l2cache.slices_1.u_core.refillBuf.u_core.buffer[8][1];
    release u_i.inner_l2cache.slices_1.u_core.refillBuf.u_core.buffer[9][0];
    release u_i.inner_l2cache.slices_1.u_core.refillBuf.u_core.buffer[9][1];
    release u_i.inner_l2cache.slices_1.u_core.refillBuf.u_core.buffer[10][0];
    release u_i.inner_l2cache.slices_1.u_core.refillBuf.u_core.buffer[10][1];
    release u_i.inner_l2cache.slices_1.u_core.refillBuf.u_core.buffer[11][0];
    release u_i.inner_l2cache.slices_1.u_core.refillBuf.u_core.buffer[11][1];
    release u_i.inner_l2cache.slices_1.u_core.refillBuf.u_core.buffer[12][0];
    release u_i.inner_l2cache.slices_1.u_core.refillBuf.u_core.buffer[12][1];
    release u_i.inner_l2cache.slices_1.u_core.refillBuf.u_core.buffer[13][0];
    release u_i.inner_l2cache.slices_1.u_core.refillBuf.u_core.buffer[13][1];
    release u_i.inner_l2cache.slices_1.u_core.refillBuf.u_core.buffer[14][0];
    release u_i.inner_l2cache.slices_1.u_core.refillBuf.u_core.buffer[14][1];
    release u_i.inner_l2cache.slices_1.u_core.refillBuf.u_core.buffer[15][0];
    release u_i.inner_l2cache.slices_1.u_core.refillBuf.u_core.buffer[15][1];
    release u_i.inner_l2cache.slices_1.u_core.releaseBuf.u_core.buffer[0][0];
    release u_i.inner_l2cache.slices_1.u_core.releaseBuf.u_core.buffer[0][1];
    release u_i.inner_l2cache.slices_1.u_core.releaseBuf.u_core.buffer[1][0];
    release u_i.inner_l2cache.slices_1.u_core.releaseBuf.u_core.buffer[1][1];
    release u_i.inner_l2cache.slices_1.u_core.releaseBuf.u_core.buffer[2][0];
    release u_i.inner_l2cache.slices_1.u_core.releaseBuf.u_core.buffer[2][1];
    release u_i.inner_l2cache.slices_1.u_core.releaseBuf.u_core.buffer[3][0];
    release u_i.inner_l2cache.slices_1.u_core.releaseBuf.u_core.buffer[3][1];
    release u_i.inner_l2cache.slices_1.u_core.releaseBuf.u_core.buffer[4][0];
    release u_i.inner_l2cache.slices_1.u_core.releaseBuf.u_core.buffer[4][1];
    release u_i.inner_l2cache.slices_1.u_core.releaseBuf.u_core.buffer[5][0];
    release u_i.inner_l2cache.slices_1.u_core.releaseBuf.u_core.buffer[5][1];
    release u_i.inner_l2cache.slices_1.u_core.releaseBuf.u_core.buffer[6][0];
    release u_i.inner_l2cache.slices_1.u_core.releaseBuf.u_core.buffer[6][1];
    release u_i.inner_l2cache.slices_1.u_core.releaseBuf.u_core.buffer[7][0];
    release u_i.inner_l2cache.slices_1.u_core.releaseBuf.u_core.buffer[7][1];
    release u_i.inner_l2cache.slices_1.u_core.releaseBuf.u_core.buffer[8][0];
    release u_i.inner_l2cache.slices_1.u_core.releaseBuf.u_core.buffer[8][1];
    release u_i.inner_l2cache.slices_1.u_core.releaseBuf.u_core.buffer[9][0];
    release u_i.inner_l2cache.slices_1.u_core.releaseBuf.u_core.buffer[9][1];
    release u_i.inner_l2cache.slices_1.u_core.releaseBuf.u_core.buffer[10][0];
    release u_i.inner_l2cache.slices_1.u_core.releaseBuf.u_core.buffer[10][1];
    release u_i.inner_l2cache.slices_1.u_core.releaseBuf.u_core.buffer[11][0];
    release u_i.inner_l2cache.slices_1.u_core.releaseBuf.u_core.buffer[11][1];
    release u_i.inner_l2cache.slices_1.u_core.releaseBuf.u_core.buffer[12][0];
    release u_i.inner_l2cache.slices_1.u_core.releaseBuf.u_core.buffer[12][1];
    release u_i.inner_l2cache.slices_1.u_core.releaseBuf.u_core.buffer[13][0];
    release u_i.inner_l2cache.slices_1.u_core.releaseBuf.u_core.buffer[13][1];
    release u_i.inner_l2cache.slices_1.u_core.releaseBuf.u_core.buffer[14][0];
    release u_i.inner_l2cache.slices_1.u_core.releaseBuf.u_core.buffer[14][1];
    release u_i.inner_l2cache.slices_1.u_core.releaseBuf.u_core.buffer[15][0];
    release u_i.inner_l2cache.slices_1.u_core.releaseBuf.u_core.buffer[15][1];
    release u_i.inner_l2cache.slices_1.directory.tagArray.array_0_0_0.u_core.rdataReg;
    release u_i.inner_l2cache.slices_1.directory.tagArray.array_0_0_1.u_core.rdataReg;
    release u_i.inner_l2cache.slices_1.directory.tagArray.array_0_1_0.u_core.rdataReg;
    release u_i.inner_l2cache.slices_1.directory.tagArray.array_0_1_1.u_core.rdataReg;
    release u_i.inner_l2cache.slices_1.directory.metaArray.u_core.rdataReg;
    release u_i.inner_l2cache.slices_1.directory.replacer_sram_opt.u_core.rdataReg;
    release u_i.inner_l2cache.slices_1.directory.origin_bit_opt.u_core.rdataReg;
    release u_i.inner_l2cache.slices_1.dataStorage.array.array_0_0_0.u_core.rdataReg;
    release u_i.inner_l2cache.slices_1.dataStorage.array.array_0_0_1.u_core.rdataReg;
    release u_i.inner_l2cache.slices_1.dataStorage.array.array_0_0_2.u_core.rdataReg;
    release u_i.inner_l2cache.slices_1.dataStorage.array.array_0_0_3.u_core.rdataReg;
    release u_i.inner_l2cache.slices_1.dataStorage.u_core.error_REG;
    release u_i.inner_l2cache.slices_1.dataStorage.u_core.error_REG_1;
    release u_i.inner_l2cache.slices_1.mbistPl.u_core.g_node_return.pipelineDataOutReg;
    release u_i.inner_l2cache.slices_1.u_core.io_error_bits_REG_valid;
    release u_i.inner_l2cache.slices_1.u_core.io_error_bits_REG_address;
    release u_i.inner_l2cache.slices_1.u_core.io_perf_0_value_REG;
    release u_i.inner_l2cache.slices_1.u_core.io_perf_0_value_REG_1;
    release u_i.inner_l2cache.slices_1.u_core.io_perf_1_value_REG;
    release u_i.inner_l2cache.slices_1.u_core.io_perf_1_value_REG_1;
    release u_i.inner_l2cache.slices_1.u_core.io_perf_3_value_REG;
    release u_i.inner_l2cache.slices_1.u_core.io_perf_3_value_REG_1;
    release u_i.inner_l2cache.slices_1.u_core.io_perf_4_value_REG;
    release u_i.inner_l2cache.slices_1.u_core.io_perf_4_value_REG_1;
    release u_i.inner_l2cache.slices_1.u_core.io_perf_5_value_REG;
    release u_i.inner_l2cache.slices_1.u_core.io_perf_5_value_REG_1;
    release u_i.inner_l2cache.slices_1.u_core.io_perf_6_value_REG;
    release u_i.inner_l2cache.slices_1.u_core.io_perf_6_value_REG_1;
    release u_i.inner_l2cache.slices_1.u_core.io_perf_7_value_REG;
    release u_i.inner_l2cache.slices_1.u_core.io_perf_7_value_REG_1;
    release u_i.inner_l2cache.slices_1.u_core.io_perf_8_value_REG;
    release u_i.inner_l2cache.slices_1.u_core.io_perf_8_value_REG_1;
    release u_i.inner_l2cache.slices_1.u_core.io_perf_9_value_REG;
    release u_i.inner_l2cache.slices_1.u_core.io_perf_9_value_REG_1;
    release u_i.inner_l2cache.slices_1.u_core.io_perf_10_value_REG;
    release u_i.inner_l2cache.slices_1.u_core.io_perf_10_value_REG_1;
    release u_i.inner_l2cache.slices_1.u_core.io_perf_11_value_REG;
    release u_i.inner_l2cache.slices_1.u_core.io_perf_11_value_REG_1;
    release u_i.inner_l2cache.slices_1.u_core.io_perf_12_value_REG;
    release u_i.inner_l2cache.slices_1.u_core.io_perf_12_value_REG_1;
    release u_i.inner_l2cache.slices_1.u_core.io_perf_13_value_REG;
    release u_i.inner_l2cache.slices_1.u_core.io_perf_13_value_REG_1;
    release u_i.inner_l2cache.slices_1.u_core.io_perf_14_value_REG;
    release u_i.inner_l2cache.slices_1.u_core.io_perf_14_value_REG_1;
    release u_i.inner_l2cache.slices_1.u_core.io_perf_15_value_REG;
    release u_i.inner_l2cache.slices_1.u_core.io_perf_15_value_REG_1;
    release u_i.inner_l2cache.slices_1.u_core.io_perf_16_value_REG;
    release u_i.inner_l2cache.slices_1.u_core.io_perf_16_value_REG_1;
    release u_i.inner_l2cache.slices_2.u_core.mshrCtl.u_core.mshrs[0].entry.u_core.tgtid_rcompack;
    release u_i.inner_l2cache.slices_2.u_core.mshrCtl.u_core.mshrs[0].entry.u_core.txnid_rcompack;
    release u_i.inner_l2cache.slices_2.u_core.mshrCtl.u_core.mshrs[0].entry.u_core.tgtid_wcompack;
    release u_i.inner_l2cache.slices_2.u_core.mshrCtl.u_core.mshrs[0].entry.u_core.txnid_wcompack;
    release u_i.inner_l2cache.slices_2.u_core.mshrCtl.u_core.mshrs[0].entry.u_core.srcid_retryack;
    release u_i.inner_l2cache.slices_2.u_core.mshrCtl.u_core.mshrs[0].entry.u_core.acquire_ts;
    release u_i.inner_l2cache.slices_2.u_core.mshrCtl.u_core.mshrs[0].entry.u_core.release_ts;
    release u_i.inner_l2cache.slices_2.u_core.mshrCtl.u_core.mshrs[0].entry.u_core.acquire_period_valid_REG;
    release u_i.inner_l2cache.slices_2.u_core.mshrCtl.u_core.mshrs[0].entry.u_core.release_period_valid_REG;
    release u_i.inner_l2cache.slices_2.u_core.mshrCtl.u_core.mshrs[0].entry.u_core.REG;
    release u_i.inner_l2cache.slices_2.u_core.mshrCtl.u_core.mshrs[0].entry.u_core.REG_1;
    release u_i.inner_l2cache.slices_2.u_core.mshrCtl.u_core.mshrs[0].entry.u_core.REG_2;
    release u_i.inner_l2cache.slices_2.u_core.mshrCtl.u_core.mshrs[0].entry.u_core.REG_3;
    release u_i.inner_l2cache.slices_2.u_core.mshrCtl.u_core.mshrs[1].entry.u_core.tgtid_rcompack;
    release u_i.inner_l2cache.slices_2.u_core.mshrCtl.u_core.mshrs[1].entry.u_core.txnid_rcompack;
    release u_i.inner_l2cache.slices_2.u_core.mshrCtl.u_core.mshrs[1].entry.u_core.tgtid_wcompack;
    release u_i.inner_l2cache.slices_2.u_core.mshrCtl.u_core.mshrs[1].entry.u_core.txnid_wcompack;
    release u_i.inner_l2cache.slices_2.u_core.mshrCtl.u_core.mshrs[1].entry.u_core.srcid_retryack;
    release u_i.inner_l2cache.slices_2.u_core.mshrCtl.u_core.mshrs[1].entry.u_core.acquire_ts;
    release u_i.inner_l2cache.slices_2.u_core.mshrCtl.u_core.mshrs[1].entry.u_core.release_ts;
    release u_i.inner_l2cache.slices_2.u_core.mshrCtl.u_core.mshrs[1].entry.u_core.acquire_period_valid_REG;
    release u_i.inner_l2cache.slices_2.u_core.mshrCtl.u_core.mshrs[1].entry.u_core.release_period_valid_REG;
    release u_i.inner_l2cache.slices_2.u_core.mshrCtl.u_core.mshrs[1].entry.u_core.REG;
    release u_i.inner_l2cache.slices_2.u_core.mshrCtl.u_core.mshrs[1].entry.u_core.REG_1;
    release u_i.inner_l2cache.slices_2.u_core.mshrCtl.u_core.mshrs[1].entry.u_core.REG_2;
    release u_i.inner_l2cache.slices_2.u_core.mshrCtl.u_core.mshrs[1].entry.u_core.REG_3;
    release u_i.inner_l2cache.slices_2.u_core.mshrCtl.u_core.mshrs[2].entry.u_core.tgtid_rcompack;
    release u_i.inner_l2cache.slices_2.u_core.mshrCtl.u_core.mshrs[2].entry.u_core.txnid_rcompack;
    release u_i.inner_l2cache.slices_2.u_core.mshrCtl.u_core.mshrs[2].entry.u_core.tgtid_wcompack;
    release u_i.inner_l2cache.slices_2.u_core.mshrCtl.u_core.mshrs[2].entry.u_core.txnid_wcompack;
    release u_i.inner_l2cache.slices_2.u_core.mshrCtl.u_core.mshrs[2].entry.u_core.srcid_retryack;
    release u_i.inner_l2cache.slices_2.u_core.mshrCtl.u_core.mshrs[2].entry.u_core.acquire_ts;
    release u_i.inner_l2cache.slices_2.u_core.mshrCtl.u_core.mshrs[2].entry.u_core.release_ts;
    release u_i.inner_l2cache.slices_2.u_core.mshrCtl.u_core.mshrs[2].entry.u_core.acquire_period_valid_REG;
    release u_i.inner_l2cache.slices_2.u_core.mshrCtl.u_core.mshrs[2].entry.u_core.release_period_valid_REG;
    release u_i.inner_l2cache.slices_2.u_core.mshrCtl.u_core.mshrs[2].entry.u_core.REG;
    release u_i.inner_l2cache.slices_2.u_core.mshrCtl.u_core.mshrs[2].entry.u_core.REG_1;
    release u_i.inner_l2cache.slices_2.u_core.mshrCtl.u_core.mshrs[2].entry.u_core.REG_2;
    release u_i.inner_l2cache.slices_2.u_core.mshrCtl.u_core.mshrs[2].entry.u_core.REG_3;
    release u_i.inner_l2cache.slices_2.u_core.mshrCtl.u_core.mshrs[3].entry.u_core.tgtid_rcompack;
    release u_i.inner_l2cache.slices_2.u_core.mshrCtl.u_core.mshrs[3].entry.u_core.txnid_rcompack;
    release u_i.inner_l2cache.slices_2.u_core.mshrCtl.u_core.mshrs[3].entry.u_core.tgtid_wcompack;
    release u_i.inner_l2cache.slices_2.u_core.mshrCtl.u_core.mshrs[3].entry.u_core.txnid_wcompack;
    release u_i.inner_l2cache.slices_2.u_core.mshrCtl.u_core.mshrs[3].entry.u_core.srcid_retryack;
    release u_i.inner_l2cache.slices_2.u_core.mshrCtl.u_core.mshrs[3].entry.u_core.acquire_ts;
    release u_i.inner_l2cache.slices_2.u_core.mshrCtl.u_core.mshrs[3].entry.u_core.release_ts;
    release u_i.inner_l2cache.slices_2.u_core.mshrCtl.u_core.mshrs[3].entry.u_core.acquire_period_valid_REG;
    release u_i.inner_l2cache.slices_2.u_core.mshrCtl.u_core.mshrs[3].entry.u_core.release_period_valid_REG;
    release u_i.inner_l2cache.slices_2.u_core.mshrCtl.u_core.mshrs[3].entry.u_core.REG;
    release u_i.inner_l2cache.slices_2.u_core.mshrCtl.u_core.mshrs[3].entry.u_core.REG_1;
    release u_i.inner_l2cache.slices_2.u_core.mshrCtl.u_core.mshrs[3].entry.u_core.REG_2;
    release u_i.inner_l2cache.slices_2.u_core.mshrCtl.u_core.mshrs[3].entry.u_core.REG_3;
    release u_i.inner_l2cache.slices_2.u_core.mshrCtl.u_core.mshrs[4].entry.u_core.tgtid_rcompack;
    release u_i.inner_l2cache.slices_2.u_core.mshrCtl.u_core.mshrs[4].entry.u_core.txnid_rcompack;
    release u_i.inner_l2cache.slices_2.u_core.mshrCtl.u_core.mshrs[4].entry.u_core.tgtid_wcompack;
    release u_i.inner_l2cache.slices_2.u_core.mshrCtl.u_core.mshrs[4].entry.u_core.txnid_wcompack;
    release u_i.inner_l2cache.slices_2.u_core.mshrCtl.u_core.mshrs[4].entry.u_core.srcid_retryack;
    release u_i.inner_l2cache.slices_2.u_core.mshrCtl.u_core.mshrs[4].entry.u_core.acquire_ts;
    release u_i.inner_l2cache.slices_2.u_core.mshrCtl.u_core.mshrs[4].entry.u_core.release_ts;
    release u_i.inner_l2cache.slices_2.u_core.mshrCtl.u_core.mshrs[4].entry.u_core.acquire_period_valid_REG;
    release u_i.inner_l2cache.slices_2.u_core.mshrCtl.u_core.mshrs[4].entry.u_core.release_period_valid_REG;
    release u_i.inner_l2cache.slices_2.u_core.mshrCtl.u_core.mshrs[4].entry.u_core.REG;
    release u_i.inner_l2cache.slices_2.u_core.mshrCtl.u_core.mshrs[4].entry.u_core.REG_1;
    release u_i.inner_l2cache.slices_2.u_core.mshrCtl.u_core.mshrs[4].entry.u_core.REG_2;
    release u_i.inner_l2cache.slices_2.u_core.mshrCtl.u_core.mshrs[4].entry.u_core.REG_3;
    release u_i.inner_l2cache.slices_2.u_core.mshrCtl.u_core.mshrs[5].entry.u_core.tgtid_rcompack;
    release u_i.inner_l2cache.slices_2.u_core.mshrCtl.u_core.mshrs[5].entry.u_core.txnid_rcompack;
    release u_i.inner_l2cache.slices_2.u_core.mshrCtl.u_core.mshrs[5].entry.u_core.tgtid_wcompack;
    release u_i.inner_l2cache.slices_2.u_core.mshrCtl.u_core.mshrs[5].entry.u_core.txnid_wcompack;
    release u_i.inner_l2cache.slices_2.u_core.mshrCtl.u_core.mshrs[5].entry.u_core.srcid_retryack;
    release u_i.inner_l2cache.slices_2.u_core.mshrCtl.u_core.mshrs[5].entry.u_core.acquire_ts;
    release u_i.inner_l2cache.slices_2.u_core.mshrCtl.u_core.mshrs[5].entry.u_core.release_ts;
    release u_i.inner_l2cache.slices_2.u_core.mshrCtl.u_core.mshrs[5].entry.u_core.acquire_period_valid_REG;
    release u_i.inner_l2cache.slices_2.u_core.mshrCtl.u_core.mshrs[5].entry.u_core.release_period_valid_REG;
    release u_i.inner_l2cache.slices_2.u_core.mshrCtl.u_core.mshrs[5].entry.u_core.REG;
    release u_i.inner_l2cache.slices_2.u_core.mshrCtl.u_core.mshrs[5].entry.u_core.REG_1;
    release u_i.inner_l2cache.slices_2.u_core.mshrCtl.u_core.mshrs[5].entry.u_core.REG_2;
    release u_i.inner_l2cache.slices_2.u_core.mshrCtl.u_core.mshrs[5].entry.u_core.REG_3;
    release u_i.inner_l2cache.slices_2.u_core.mshrCtl.u_core.mshrs[6].entry.u_core.tgtid_rcompack;
    release u_i.inner_l2cache.slices_2.u_core.mshrCtl.u_core.mshrs[6].entry.u_core.txnid_rcompack;
    release u_i.inner_l2cache.slices_2.u_core.mshrCtl.u_core.mshrs[6].entry.u_core.tgtid_wcompack;
    release u_i.inner_l2cache.slices_2.u_core.mshrCtl.u_core.mshrs[6].entry.u_core.txnid_wcompack;
    release u_i.inner_l2cache.slices_2.u_core.mshrCtl.u_core.mshrs[6].entry.u_core.srcid_retryack;
    release u_i.inner_l2cache.slices_2.u_core.mshrCtl.u_core.mshrs[6].entry.u_core.acquire_ts;
    release u_i.inner_l2cache.slices_2.u_core.mshrCtl.u_core.mshrs[6].entry.u_core.release_ts;
    release u_i.inner_l2cache.slices_2.u_core.mshrCtl.u_core.mshrs[6].entry.u_core.acquire_period_valid_REG;
    release u_i.inner_l2cache.slices_2.u_core.mshrCtl.u_core.mshrs[6].entry.u_core.release_period_valid_REG;
    release u_i.inner_l2cache.slices_2.u_core.mshrCtl.u_core.mshrs[6].entry.u_core.REG;
    release u_i.inner_l2cache.slices_2.u_core.mshrCtl.u_core.mshrs[6].entry.u_core.REG_1;
    release u_i.inner_l2cache.slices_2.u_core.mshrCtl.u_core.mshrs[6].entry.u_core.REG_2;
    release u_i.inner_l2cache.slices_2.u_core.mshrCtl.u_core.mshrs[6].entry.u_core.REG_3;
    release u_i.inner_l2cache.slices_2.u_core.mshrCtl.u_core.mshrs[7].entry.u_core.tgtid_rcompack;
    release u_i.inner_l2cache.slices_2.u_core.mshrCtl.u_core.mshrs[7].entry.u_core.txnid_rcompack;
    release u_i.inner_l2cache.slices_2.u_core.mshrCtl.u_core.mshrs[7].entry.u_core.tgtid_wcompack;
    release u_i.inner_l2cache.slices_2.u_core.mshrCtl.u_core.mshrs[7].entry.u_core.txnid_wcompack;
    release u_i.inner_l2cache.slices_2.u_core.mshrCtl.u_core.mshrs[7].entry.u_core.srcid_retryack;
    release u_i.inner_l2cache.slices_2.u_core.mshrCtl.u_core.mshrs[7].entry.u_core.acquire_ts;
    release u_i.inner_l2cache.slices_2.u_core.mshrCtl.u_core.mshrs[7].entry.u_core.release_ts;
    release u_i.inner_l2cache.slices_2.u_core.mshrCtl.u_core.mshrs[7].entry.u_core.acquire_period_valid_REG;
    release u_i.inner_l2cache.slices_2.u_core.mshrCtl.u_core.mshrs[7].entry.u_core.release_period_valid_REG;
    release u_i.inner_l2cache.slices_2.u_core.mshrCtl.u_core.mshrs[7].entry.u_core.REG;
    release u_i.inner_l2cache.slices_2.u_core.mshrCtl.u_core.mshrs[7].entry.u_core.REG_1;
    release u_i.inner_l2cache.slices_2.u_core.mshrCtl.u_core.mshrs[7].entry.u_core.REG_2;
    release u_i.inner_l2cache.slices_2.u_core.mshrCtl.u_core.mshrs[7].entry.u_core.REG_3;
    release u_i.inner_l2cache.slices_2.u_core.mshrCtl.u_core.mshrs[8].entry.u_core.tgtid_rcompack;
    release u_i.inner_l2cache.slices_2.u_core.mshrCtl.u_core.mshrs[8].entry.u_core.txnid_rcompack;
    release u_i.inner_l2cache.slices_2.u_core.mshrCtl.u_core.mshrs[8].entry.u_core.tgtid_wcompack;
    release u_i.inner_l2cache.slices_2.u_core.mshrCtl.u_core.mshrs[8].entry.u_core.txnid_wcompack;
    release u_i.inner_l2cache.slices_2.u_core.mshrCtl.u_core.mshrs[8].entry.u_core.srcid_retryack;
    release u_i.inner_l2cache.slices_2.u_core.mshrCtl.u_core.mshrs[8].entry.u_core.acquire_ts;
    release u_i.inner_l2cache.slices_2.u_core.mshrCtl.u_core.mshrs[8].entry.u_core.release_ts;
    release u_i.inner_l2cache.slices_2.u_core.mshrCtl.u_core.mshrs[8].entry.u_core.acquire_period_valid_REG;
    release u_i.inner_l2cache.slices_2.u_core.mshrCtl.u_core.mshrs[8].entry.u_core.release_period_valid_REG;
    release u_i.inner_l2cache.slices_2.u_core.mshrCtl.u_core.mshrs[8].entry.u_core.REG;
    release u_i.inner_l2cache.slices_2.u_core.mshrCtl.u_core.mshrs[8].entry.u_core.REG_1;
    release u_i.inner_l2cache.slices_2.u_core.mshrCtl.u_core.mshrs[8].entry.u_core.REG_2;
    release u_i.inner_l2cache.slices_2.u_core.mshrCtl.u_core.mshrs[8].entry.u_core.REG_3;
    release u_i.inner_l2cache.slices_2.u_core.mshrCtl.u_core.mshrs[9].entry.u_core.tgtid_rcompack;
    release u_i.inner_l2cache.slices_2.u_core.mshrCtl.u_core.mshrs[9].entry.u_core.txnid_rcompack;
    release u_i.inner_l2cache.slices_2.u_core.mshrCtl.u_core.mshrs[9].entry.u_core.tgtid_wcompack;
    release u_i.inner_l2cache.slices_2.u_core.mshrCtl.u_core.mshrs[9].entry.u_core.txnid_wcompack;
    release u_i.inner_l2cache.slices_2.u_core.mshrCtl.u_core.mshrs[9].entry.u_core.srcid_retryack;
    release u_i.inner_l2cache.slices_2.u_core.mshrCtl.u_core.mshrs[9].entry.u_core.acquire_ts;
    release u_i.inner_l2cache.slices_2.u_core.mshrCtl.u_core.mshrs[9].entry.u_core.release_ts;
    release u_i.inner_l2cache.slices_2.u_core.mshrCtl.u_core.mshrs[9].entry.u_core.acquire_period_valid_REG;
    release u_i.inner_l2cache.slices_2.u_core.mshrCtl.u_core.mshrs[9].entry.u_core.release_period_valid_REG;
    release u_i.inner_l2cache.slices_2.u_core.mshrCtl.u_core.mshrs[9].entry.u_core.REG;
    release u_i.inner_l2cache.slices_2.u_core.mshrCtl.u_core.mshrs[9].entry.u_core.REG_1;
    release u_i.inner_l2cache.slices_2.u_core.mshrCtl.u_core.mshrs[9].entry.u_core.REG_2;
    release u_i.inner_l2cache.slices_2.u_core.mshrCtl.u_core.mshrs[9].entry.u_core.REG_3;
    release u_i.inner_l2cache.slices_2.u_core.mshrCtl.u_core.mshrs[10].entry.u_core.tgtid_rcompack;
    release u_i.inner_l2cache.slices_2.u_core.mshrCtl.u_core.mshrs[10].entry.u_core.txnid_rcompack;
    release u_i.inner_l2cache.slices_2.u_core.mshrCtl.u_core.mshrs[10].entry.u_core.tgtid_wcompack;
    release u_i.inner_l2cache.slices_2.u_core.mshrCtl.u_core.mshrs[10].entry.u_core.txnid_wcompack;
    release u_i.inner_l2cache.slices_2.u_core.mshrCtl.u_core.mshrs[10].entry.u_core.srcid_retryack;
    release u_i.inner_l2cache.slices_2.u_core.mshrCtl.u_core.mshrs[10].entry.u_core.acquire_ts;
    release u_i.inner_l2cache.slices_2.u_core.mshrCtl.u_core.mshrs[10].entry.u_core.release_ts;
    release u_i.inner_l2cache.slices_2.u_core.mshrCtl.u_core.mshrs[10].entry.u_core.acquire_period_valid_REG;
    release u_i.inner_l2cache.slices_2.u_core.mshrCtl.u_core.mshrs[10].entry.u_core.release_period_valid_REG;
    release u_i.inner_l2cache.slices_2.u_core.mshrCtl.u_core.mshrs[10].entry.u_core.REG;
    release u_i.inner_l2cache.slices_2.u_core.mshrCtl.u_core.mshrs[10].entry.u_core.REG_1;
    release u_i.inner_l2cache.slices_2.u_core.mshrCtl.u_core.mshrs[10].entry.u_core.REG_2;
    release u_i.inner_l2cache.slices_2.u_core.mshrCtl.u_core.mshrs[10].entry.u_core.REG_3;
    release u_i.inner_l2cache.slices_2.u_core.mshrCtl.u_core.mshrs[11].entry.u_core.tgtid_rcompack;
    release u_i.inner_l2cache.slices_2.u_core.mshrCtl.u_core.mshrs[11].entry.u_core.txnid_rcompack;
    release u_i.inner_l2cache.slices_2.u_core.mshrCtl.u_core.mshrs[11].entry.u_core.tgtid_wcompack;
    release u_i.inner_l2cache.slices_2.u_core.mshrCtl.u_core.mshrs[11].entry.u_core.txnid_wcompack;
    release u_i.inner_l2cache.slices_2.u_core.mshrCtl.u_core.mshrs[11].entry.u_core.srcid_retryack;
    release u_i.inner_l2cache.slices_2.u_core.mshrCtl.u_core.mshrs[11].entry.u_core.acquire_ts;
    release u_i.inner_l2cache.slices_2.u_core.mshrCtl.u_core.mshrs[11].entry.u_core.release_ts;
    release u_i.inner_l2cache.slices_2.u_core.mshrCtl.u_core.mshrs[11].entry.u_core.acquire_period_valid_REG;
    release u_i.inner_l2cache.slices_2.u_core.mshrCtl.u_core.mshrs[11].entry.u_core.release_period_valid_REG;
    release u_i.inner_l2cache.slices_2.u_core.mshrCtl.u_core.mshrs[11].entry.u_core.REG;
    release u_i.inner_l2cache.slices_2.u_core.mshrCtl.u_core.mshrs[11].entry.u_core.REG_1;
    release u_i.inner_l2cache.slices_2.u_core.mshrCtl.u_core.mshrs[11].entry.u_core.REG_2;
    release u_i.inner_l2cache.slices_2.u_core.mshrCtl.u_core.mshrs[11].entry.u_core.REG_3;
    release u_i.inner_l2cache.slices_2.u_core.mshrCtl.u_core.mshrs[12].entry.u_core.tgtid_rcompack;
    release u_i.inner_l2cache.slices_2.u_core.mshrCtl.u_core.mshrs[12].entry.u_core.txnid_rcompack;
    release u_i.inner_l2cache.slices_2.u_core.mshrCtl.u_core.mshrs[12].entry.u_core.tgtid_wcompack;
    release u_i.inner_l2cache.slices_2.u_core.mshrCtl.u_core.mshrs[12].entry.u_core.txnid_wcompack;
    release u_i.inner_l2cache.slices_2.u_core.mshrCtl.u_core.mshrs[12].entry.u_core.srcid_retryack;
    release u_i.inner_l2cache.slices_2.u_core.mshrCtl.u_core.mshrs[12].entry.u_core.acquire_ts;
    release u_i.inner_l2cache.slices_2.u_core.mshrCtl.u_core.mshrs[12].entry.u_core.release_ts;
    release u_i.inner_l2cache.slices_2.u_core.mshrCtl.u_core.mshrs[12].entry.u_core.acquire_period_valid_REG;
    release u_i.inner_l2cache.slices_2.u_core.mshrCtl.u_core.mshrs[12].entry.u_core.release_period_valid_REG;
    release u_i.inner_l2cache.slices_2.u_core.mshrCtl.u_core.mshrs[12].entry.u_core.REG;
    release u_i.inner_l2cache.slices_2.u_core.mshrCtl.u_core.mshrs[12].entry.u_core.REG_1;
    release u_i.inner_l2cache.slices_2.u_core.mshrCtl.u_core.mshrs[12].entry.u_core.REG_2;
    release u_i.inner_l2cache.slices_2.u_core.mshrCtl.u_core.mshrs[12].entry.u_core.REG_3;
    release u_i.inner_l2cache.slices_2.u_core.mshrCtl.u_core.mshrs[13].entry.u_core.tgtid_rcompack;
    release u_i.inner_l2cache.slices_2.u_core.mshrCtl.u_core.mshrs[13].entry.u_core.txnid_rcompack;
    release u_i.inner_l2cache.slices_2.u_core.mshrCtl.u_core.mshrs[13].entry.u_core.tgtid_wcompack;
    release u_i.inner_l2cache.slices_2.u_core.mshrCtl.u_core.mshrs[13].entry.u_core.txnid_wcompack;
    release u_i.inner_l2cache.slices_2.u_core.mshrCtl.u_core.mshrs[13].entry.u_core.srcid_retryack;
    release u_i.inner_l2cache.slices_2.u_core.mshrCtl.u_core.mshrs[13].entry.u_core.acquire_ts;
    release u_i.inner_l2cache.slices_2.u_core.mshrCtl.u_core.mshrs[13].entry.u_core.release_ts;
    release u_i.inner_l2cache.slices_2.u_core.mshrCtl.u_core.mshrs[13].entry.u_core.acquire_period_valid_REG;
    release u_i.inner_l2cache.slices_2.u_core.mshrCtl.u_core.mshrs[13].entry.u_core.release_period_valid_REG;
    release u_i.inner_l2cache.slices_2.u_core.mshrCtl.u_core.mshrs[13].entry.u_core.REG;
    release u_i.inner_l2cache.slices_2.u_core.mshrCtl.u_core.mshrs[13].entry.u_core.REG_1;
    release u_i.inner_l2cache.slices_2.u_core.mshrCtl.u_core.mshrs[13].entry.u_core.REG_2;
    release u_i.inner_l2cache.slices_2.u_core.mshrCtl.u_core.mshrs[13].entry.u_core.REG_3;
    release u_i.inner_l2cache.slices_2.u_core.mshrCtl.u_core.mshrs[14].entry.u_core.tgtid_rcompack;
    release u_i.inner_l2cache.slices_2.u_core.mshrCtl.u_core.mshrs[14].entry.u_core.txnid_rcompack;
    release u_i.inner_l2cache.slices_2.u_core.mshrCtl.u_core.mshrs[14].entry.u_core.tgtid_wcompack;
    release u_i.inner_l2cache.slices_2.u_core.mshrCtl.u_core.mshrs[14].entry.u_core.txnid_wcompack;
    release u_i.inner_l2cache.slices_2.u_core.mshrCtl.u_core.mshrs[14].entry.u_core.srcid_retryack;
    release u_i.inner_l2cache.slices_2.u_core.mshrCtl.u_core.mshrs[14].entry.u_core.acquire_ts;
    release u_i.inner_l2cache.slices_2.u_core.mshrCtl.u_core.mshrs[14].entry.u_core.release_ts;
    release u_i.inner_l2cache.slices_2.u_core.mshrCtl.u_core.mshrs[14].entry.u_core.acquire_period_valid_REG;
    release u_i.inner_l2cache.slices_2.u_core.mshrCtl.u_core.mshrs[14].entry.u_core.release_period_valid_REG;
    release u_i.inner_l2cache.slices_2.u_core.mshrCtl.u_core.mshrs[14].entry.u_core.REG;
    release u_i.inner_l2cache.slices_2.u_core.mshrCtl.u_core.mshrs[14].entry.u_core.REG_1;
    release u_i.inner_l2cache.slices_2.u_core.mshrCtl.u_core.mshrs[14].entry.u_core.REG_2;
    release u_i.inner_l2cache.slices_2.u_core.mshrCtl.u_core.mshrs[14].entry.u_core.REG_3;
    release u_i.inner_l2cache.slices_2.u_core.mshrCtl.u_core.mshrs[15].entry.u_core.tgtid_rcompack;
    release u_i.inner_l2cache.slices_2.u_core.mshrCtl.u_core.mshrs[15].entry.u_core.txnid_rcompack;
    release u_i.inner_l2cache.slices_2.u_core.mshrCtl.u_core.mshrs[15].entry.u_core.tgtid_wcompack;
    release u_i.inner_l2cache.slices_2.u_core.mshrCtl.u_core.mshrs[15].entry.u_core.txnid_wcompack;
    release u_i.inner_l2cache.slices_2.u_core.mshrCtl.u_core.mshrs[15].entry.u_core.srcid_retryack;
    release u_i.inner_l2cache.slices_2.u_core.mshrCtl.u_core.mshrs[15].entry.u_core.acquire_ts;
    release u_i.inner_l2cache.slices_2.u_core.mshrCtl.u_core.mshrs[15].entry.u_core.release_ts;
    release u_i.inner_l2cache.slices_2.u_core.mshrCtl.u_core.mshrs[15].entry.u_core.acquire_period_valid_REG;
    release u_i.inner_l2cache.slices_2.u_core.mshrCtl.u_core.mshrs[15].entry.u_core.release_period_valid_REG;
    release u_i.inner_l2cache.slices_2.u_core.mshrCtl.u_core.mshrs[15].entry.u_core.REG;
    release u_i.inner_l2cache.slices_2.u_core.mshrCtl.u_core.mshrs[15].entry.u_core.REG_1;
    release u_i.inner_l2cache.slices_2.u_core.mshrCtl.u_core.mshrs[15].entry.u_core.REG_2;
    release u_i.inner_l2cache.slices_2.u_core.mshrCtl.u_core.mshrs[15].entry.u_core.REG_3;
    release u_i.inner_l2cache.slices_2.u_core.mshrCtl.u_core.io_perf_0_value_REG;
    release u_i.inner_l2cache.slices_2.u_core.mshrCtl.u_core.io_perf_0_value_REG_1;
    release u_i.inner_l2cache.slices_2.u_core.mshrCtl.u_core.io_perf_1_value_REG;
    release u_i.inner_l2cache.slices_2.u_core.mshrCtl.u_core.io_perf_1_value_REG_1;
    release u_i.inner_l2cache.slices_2.u_core.mshrCtl.u_core.io_perf_3_value_REG;
    release u_i.inner_l2cache.slices_2.u_core.mshrCtl.u_core.io_perf_3_value_REG_1;
    release u_i.inner_l2cache.slices_2.u_core.mshrCtl.u_core.REG;
    release u_i.inner_l2cache.slices_2.u_core.mainPipe.u_core.data_s4;
    release u_i.inner_l2cache.slices_2.u_core.mainPipe.u_core.data_s5;
    release u_i.inner_l2cache.slices_2.u_core.mainPipe.u_core.s3DropValid_d1;
    release u_i.inner_l2cache.slices_2.u_core.mainPipe.u_core.reqDrop_s3_d1;
    release u_i.inner_l2cache.slices_2.u_core.mainPipe.u_core.reqDrop_s3_d2;
    release u_i.inner_l2cache.slices_2.u_core.mainPipe.u_core.reqDrop_s4_d1;
    release u_i.inner_l2cache.slices_2.u_core.mainPipe.u_core.perf_d1[0];
    release u_i.inner_l2cache.slices_2.u_core.mainPipe.u_core.perf[0];
    release u_i.inner_l2cache.slices_2.u_core.mainPipe.u_core.perf_d1[1];
    release u_i.inner_l2cache.slices_2.u_core.mainPipe.u_core.perf[1];
    release u_i.inner_l2cache.slices_2.u_core.mainPipe.u_core.perf_d1[2];
    release u_i.inner_l2cache.slices_2.u_core.mainPipe.u_core.perf[2];
    release u_i.inner_l2cache.slices_2.u_core.mainPipe.u_core.perf_d1[3];
    release u_i.inner_l2cache.slices_2.u_core.mainPipe.u_core.perf[3];
    release u_i.inner_l2cache.slices_2.u_core.mainPipe.u_core.perf_d1[4];
    release u_i.inner_l2cache.slices_2.u_core.mainPipe.u_core.perf[4];
    release u_i.inner_l2cache.slices_2.u_core.mainPipe.u_core.perf_d1[5];
    release u_i.inner_l2cache.slices_2.u_core.mainPipe.u_core.perf[5];
    release u_i.inner_l2cache.slices_2.u_core.mainPipe.u_core.perf_d1[6];
    release u_i.inner_l2cache.slices_2.u_core.mainPipe.u_core.perf[6];
    release u_i.inner_l2cache.slices_2.u_core.mainPipe.u_core.perf_d1[7];
    release u_i.inner_l2cache.slices_2.u_core.mainPipe.u_core.perf[7];
    release u_i.inner_l2cache.slices_2.u_core.mainPipe.u_core.perf_d1[8];
    release u_i.inner_l2cache.slices_2.u_core.mainPipe.u_core.perf[8];
    release u_i.inner_l2cache.slices_2.u_core.mainPipe.u_core.perf_d1[9];
    release u_i.inner_l2cache.slices_2.u_core.mainPipe.u_core.perf[9];
    release u_i.inner_l2cache.slices_2.u_core.mainPipe.u_core.perf_d1[10];
    release u_i.inner_l2cache.slices_2.u_core.mainPipe.u_core.perf[10];
    release u_i.inner_l2cache.slices_2.u_core.mainPipe.u_core.perf_d1[11];
    release u_i.inner_l2cache.slices_2.u_core.mainPipe.u_core.perf[11];
    release u_i.inner_l2cache.slices_2.u_core.mainPipe.u_core.perf_d1[12];
    release u_i.inner_l2cache.slices_2.u_core.mainPipe.u_core.perf[12];
    release u_i.inner_l2cache.slices_2.u_core.grantBuf.u_core.validPrev[0];
    release u_i.inner_l2cache.slices_2.u_core.grantBuf.u_core.histValidPrev[0];
    release u_i.inner_l2cache.slices_2.u_core.grantBuf.u_core.validPrev[1];
    release u_i.inner_l2cache.slices_2.u_core.grantBuf.u_core.histValidPrev[1];
    release u_i.inner_l2cache.slices_2.u_core.grantBuf.u_core.validPrev[2];
    release u_i.inner_l2cache.slices_2.u_core.grantBuf.u_core.histValidPrev[2];
    release u_i.inner_l2cache.slices_2.u_core.grantBuf.u_core.validPrev[3];
    release u_i.inner_l2cache.slices_2.u_core.grantBuf.u_core.histValidPrev[3];
    release u_i.inner_l2cache.slices_2.u_core.grantBuf.u_core.validPrev[4];
    release u_i.inner_l2cache.slices_2.u_core.grantBuf.u_core.histValidPrev[4];
    release u_i.inner_l2cache.slices_2.u_core.grantBuf.u_core.validPrev[5];
    release u_i.inner_l2cache.slices_2.u_core.grantBuf.u_core.histValidPrev[5];
    release u_i.inner_l2cache.slices_2.u_core.grantBuf.u_core.validPrev[6];
    release u_i.inner_l2cache.slices_2.u_core.grantBuf.u_core.histValidPrev[6];
    release u_i.inner_l2cache.slices_2.u_core.grantBuf.u_core.validPrev[7];
    release u_i.inner_l2cache.slices_2.u_core.grantBuf.u_core.histValidPrev[7];
    release u_i.inner_l2cache.slices_2.u_core.grantBuf.u_core.validPrev[8];
    release u_i.inner_l2cache.slices_2.u_core.grantBuf.u_core.histValidPrev[8];
    release u_i.inner_l2cache.slices_2.u_core.grantBuf.u_core.validPrev[9];
    release u_i.inner_l2cache.slices_2.u_core.grantBuf.u_core.histValidPrev[9];
    release u_i.inner_l2cache.slices_2.u_core.grantBuf.u_core.validPrev[10];
    release u_i.inner_l2cache.slices_2.u_core.grantBuf.u_core.histValidPrev[10];
    release u_i.inner_l2cache.slices_2.u_core.grantBuf.u_core.validPrev[11];
    release u_i.inner_l2cache.slices_2.u_core.grantBuf.u_core.histValidPrev[11];
    release u_i.inner_l2cache.slices_2.u_core.grantBuf.u_core.validPrev[12];
    release u_i.inner_l2cache.slices_2.u_core.grantBuf.u_core.histValidPrev[12];
    release u_i.inner_l2cache.slices_2.u_core.grantBuf.u_core.validPrev[13];
    release u_i.inner_l2cache.slices_2.u_core.grantBuf.u_core.histValidPrev[13];
    release u_i.inner_l2cache.slices_2.u_core.grantBuf.u_core.validPrev[14];
    release u_i.inner_l2cache.slices_2.u_core.grantBuf.u_core.histValidPrev[14];
    release u_i.inner_l2cache.slices_2.u_core.grantBuf.u_core.validPrev[15];
    release u_i.inner_l2cache.slices_2.u_core.grantBuf.u_core.histValidPrev[15];
    release u_i.inner_l2cache.slices_2.u_core.rxsnp.u_core.replPrevForBlock[0];
    release u_i.inner_l2cache.slices_2.u_core.rxsnp.u_core.replPrevForNest[0];
    release u_i.inner_l2cache.slices_2.u_core.rxsnp.u_core.replPrevForBlock[1];
    release u_i.inner_l2cache.slices_2.u_core.rxsnp.u_core.replPrevForNest[1];
    release u_i.inner_l2cache.slices_2.u_core.rxsnp.u_core.replPrevForBlock[2];
    release u_i.inner_l2cache.slices_2.u_core.rxsnp.u_core.replPrevForNest[2];
    release u_i.inner_l2cache.slices_2.u_core.rxsnp.u_core.replPrevForBlock[3];
    release u_i.inner_l2cache.slices_2.u_core.rxsnp.u_core.replPrevForNest[3];
    release u_i.inner_l2cache.slices_2.u_core.rxsnp.u_core.replPrevForBlock[4];
    release u_i.inner_l2cache.slices_2.u_core.rxsnp.u_core.replPrevForNest[4];
    release u_i.inner_l2cache.slices_2.u_core.rxsnp.u_core.replPrevForBlock[5];
    release u_i.inner_l2cache.slices_2.u_core.rxsnp.u_core.replPrevForNest[5];
    release u_i.inner_l2cache.slices_2.u_core.rxsnp.u_core.replPrevForBlock[6];
    release u_i.inner_l2cache.slices_2.u_core.rxsnp.u_core.replPrevForNest[6];
    release u_i.inner_l2cache.slices_2.u_core.rxsnp.u_core.replPrevForBlock[7];
    release u_i.inner_l2cache.slices_2.u_core.rxsnp.u_core.replPrevForNest[7];
    release u_i.inner_l2cache.slices_2.u_core.rxsnp.u_core.replPrevForBlock[8];
    release u_i.inner_l2cache.slices_2.u_core.rxsnp.u_core.replPrevForNest[8];
    release u_i.inner_l2cache.slices_2.u_core.rxsnp.u_core.replPrevForBlock[9];
    release u_i.inner_l2cache.slices_2.u_core.rxsnp.u_core.replPrevForNest[9];
    release u_i.inner_l2cache.slices_2.u_core.rxsnp.u_core.replPrevForBlock[10];
    release u_i.inner_l2cache.slices_2.u_core.rxsnp.u_core.replPrevForNest[10];
    release u_i.inner_l2cache.slices_2.u_core.rxsnp.u_core.replPrevForBlock[11];
    release u_i.inner_l2cache.slices_2.u_core.rxsnp.u_core.replPrevForNest[11];
    release u_i.inner_l2cache.slices_2.u_core.rxsnp.u_core.replPrevForBlock[12];
    release u_i.inner_l2cache.slices_2.u_core.rxsnp.u_core.replPrevForNest[12];
    release u_i.inner_l2cache.slices_2.u_core.rxsnp.u_core.replPrevForBlock[13];
    release u_i.inner_l2cache.slices_2.u_core.rxsnp.u_core.replPrevForNest[13];
    release u_i.inner_l2cache.slices_2.u_core.rxsnp.u_core.replPrevForBlock[14];
    release u_i.inner_l2cache.slices_2.u_core.rxsnp.u_core.replPrevForNest[14];
    release u_i.inner_l2cache.slices_2.u_core.rxsnp.u_core.replPrevForBlock[15];
    release u_i.inner_l2cache.slices_2.u_core.rxsnp.u_core.replPrevForNest[15];
    release u_i.inner_l2cache.slices_2.u_core.reqBuf.chosenQ.u_core.ram;
    release u_i.inner_l2cache.slices_2.u_core.reqBuf.u_core.hitPfPrev_set;
    release u_i.inner_l2cache.slices_2.u_core.reqBuf.u_core.hitPfPrev_tag;
    release u_i.inner_l2cache.slices_2.u_core.reqBuf.u_core.mergeAPrev_set;
    release u_i.inner_l2cache.slices_2.u_core.reqBuf.u_core.mergeAPrev_tag;
    release u_i.inner_l2cache.slices_2.u_core.reqBuf.u_core.sameSetS3Valid[0];
    release u_i.inner_l2cache.slices_2.u_core.reqBuf.u_core.sameSetS3Set[0];
    release u_i.inner_l2cache.slices_2.u_core.reqBuf.u_core.sameSetS3Valid[1];
    release u_i.inner_l2cache.slices_2.u_core.reqBuf.u_core.sameSetS3Set[1];
    release u_i.inner_l2cache.slices_2.u_core.reqBuf.u_core.sameSetS3Valid[2];
    release u_i.inner_l2cache.slices_2.u_core.reqBuf.u_core.sameSetS3Set[2];
    release u_i.inner_l2cache.slices_2.u_core.reqBuf.u_core.sameSetS3Valid[3];
    release u_i.inner_l2cache.slices_2.u_core.reqBuf.u_core.sameSetS3Set[3];
    release u_i.inner_l2cache.slices_2.u_core.reqBuf.u_core.sameSetS3Valid[4];
    release u_i.inner_l2cache.slices_2.u_core.reqBuf.u_core.sameSetS3Set[4];
    release u_i.inner_l2cache.slices_2.u_core.reqBuf.u_core.sameSetS3Valid[5];
    release u_i.inner_l2cache.slices_2.u_core.reqBuf.u_core.sameSetS3Set[5];
    release u_i.inner_l2cache.slices_2.u_core.sinkC.u_core.bufRespStage[0];
    release u_i.inner_l2cache.slices_2.u_core.sinkC.u_core.bufRespStage[1];
    release u_i.inner_l2cache.slices_2.u_core.sinkC.u_core.bufRespOut[0];
    release u_i.inner_l2cache.slices_2.u_core.sinkC.u_core.bufRespOut[1];
    release u_i.inner_l2cache.slices_2.u_core.sinkC.u_core.refillIdReg;
    release u_i.inner_l2cache.slices_2.u_core.sinkC.u_core.refillBufIdxReg;
    release u_i.inner_l2cache.slices_2.u_core.sinkC.u_core.taskFirePrev;
    release u_i.inner_l2cache.slices_2.u_core.sinkC.u_core.taskBufIdxPrev;
    release u_i.inner_l2cache.slices_2.u_core.reqArb.u_core.ds_mcp2_stall;
    release u_i.inner_l2cache.slices_2.u_core.refillBuf.u_core.buffer[0][0];
    release u_i.inner_l2cache.slices_2.u_core.refillBuf.u_core.buffer[0][1];
    release u_i.inner_l2cache.slices_2.u_core.refillBuf.u_core.buffer[1][0];
    release u_i.inner_l2cache.slices_2.u_core.refillBuf.u_core.buffer[1][1];
    release u_i.inner_l2cache.slices_2.u_core.refillBuf.u_core.buffer[2][0];
    release u_i.inner_l2cache.slices_2.u_core.refillBuf.u_core.buffer[2][1];
    release u_i.inner_l2cache.slices_2.u_core.refillBuf.u_core.buffer[3][0];
    release u_i.inner_l2cache.slices_2.u_core.refillBuf.u_core.buffer[3][1];
    release u_i.inner_l2cache.slices_2.u_core.refillBuf.u_core.buffer[4][0];
    release u_i.inner_l2cache.slices_2.u_core.refillBuf.u_core.buffer[4][1];
    release u_i.inner_l2cache.slices_2.u_core.refillBuf.u_core.buffer[5][0];
    release u_i.inner_l2cache.slices_2.u_core.refillBuf.u_core.buffer[5][1];
    release u_i.inner_l2cache.slices_2.u_core.refillBuf.u_core.buffer[6][0];
    release u_i.inner_l2cache.slices_2.u_core.refillBuf.u_core.buffer[6][1];
    release u_i.inner_l2cache.slices_2.u_core.refillBuf.u_core.buffer[7][0];
    release u_i.inner_l2cache.slices_2.u_core.refillBuf.u_core.buffer[7][1];
    release u_i.inner_l2cache.slices_2.u_core.refillBuf.u_core.buffer[8][0];
    release u_i.inner_l2cache.slices_2.u_core.refillBuf.u_core.buffer[8][1];
    release u_i.inner_l2cache.slices_2.u_core.refillBuf.u_core.buffer[9][0];
    release u_i.inner_l2cache.slices_2.u_core.refillBuf.u_core.buffer[9][1];
    release u_i.inner_l2cache.slices_2.u_core.refillBuf.u_core.buffer[10][0];
    release u_i.inner_l2cache.slices_2.u_core.refillBuf.u_core.buffer[10][1];
    release u_i.inner_l2cache.slices_2.u_core.refillBuf.u_core.buffer[11][0];
    release u_i.inner_l2cache.slices_2.u_core.refillBuf.u_core.buffer[11][1];
    release u_i.inner_l2cache.slices_2.u_core.refillBuf.u_core.buffer[12][0];
    release u_i.inner_l2cache.slices_2.u_core.refillBuf.u_core.buffer[12][1];
    release u_i.inner_l2cache.slices_2.u_core.refillBuf.u_core.buffer[13][0];
    release u_i.inner_l2cache.slices_2.u_core.refillBuf.u_core.buffer[13][1];
    release u_i.inner_l2cache.slices_2.u_core.refillBuf.u_core.buffer[14][0];
    release u_i.inner_l2cache.slices_2.u_core.refillBuf.u_core.buffer[14][1];
    release u_i.inner_l2cache.slices_2.u_core.refillBuf.u_core.buffer[15][0];
    release u_i.inner_l2cache.slices_2.u_core.refillBuf.u_core.buffer[15][1];
    release u_i.inner_l2cache.slices_2.u_core.releaseBuf.u_core.buffer[0][0];
    release u_i.inner_l2cache.slices_2.u_core.releaseBuf.u_core.buffer[0][1];
    release u_i.inner_l2cache.slices_2.u_core.releaseBuf.u_core.buffer[1][0];
    release u_i.inner_l2cache.slices_2.u_core.releaseBuf.u_core.buffer[1][1];
    release u_i.inner_l2cache.slices_2.u_core.releaseBuf.u_core.buffer[2][0];
    release u_i.inner_l2cache.slices_2.u_core.releaseBuf.u_core.buffer[2][1];
    release u_i.inner_l2cache.slices_2.u_core.releaseBuf.u_core.buffer[3][0];
    release u_i.inner_l2cache.slices_2.u_core.releaseBuf.u_core.buffer[3][1];
    release u_i.inner_l2cache.slices_2.u_core.releaseBuf.u_core.buffer[4][0];
    release u_i.inner_l2cache.slices_2.u_core.releaseBuf.u_core.buffer[4][1];
    release u_i.inner_l2cache.slices_2.u_core.releaseBuf.u_core.buffer[5][0];
    release u_i.inner_l2cache.slices_2.u_core.releaseBuf.u_core.buffer[5][1];
    release u_i.inner_l2cache.slices_2.u_core.releaseBuf.u_core.buffer[6][0];
    release u_i.inner_l2cache.slices_2.u_core.releaseBuf.u_core.buffer[6][1];
    release u_i.inner_l2cache.slices_2.u_core.releaseBuf.u_core.buffer[7][0];
    release u_i.inner_l2cache.slices_2.u_core.releaseBuf.u_core.buffer[7][1];
    release u_i.inner_l2cache.slices_2.u_core.releaseBuf.u_core.buffer[8][0];
    release u_i.inner_l2cache.slices_2.u_core.releaseBuf.u_core.buffer[8][1];
    release u_i.inner_l2cache.slices_2.u_core.releaseBuf.u_core.buffer[9][0];
    release u_i.inner_l2cache.slices_2.u_core.releaseBuf.u_core.buffer[9][1];
    release u_i.inner_l2cache.slices_2.u_core.releaseBuf.u_core.buffer[10][0];
    release u_i.inner_l2cache.slices_2.u_core.releaseBuf.u_core.buffer[10][1];
    release u_i.inner_l2cache.slices_2.u_core.releaseBuf.u_core.buffer[11][0];
    release u_i.inner_l2cache.slices_2.u_core.releaseBuf.u_core.buffer[11][1];
    release u_i.inner_l2cache.slices_2.u_core.releaseBuf.u_core.buffer[12][0];
    release u_i.inner_l2cache.slices_2.u_core.releaseBuf.u_core.buffer[12][1];
    release u_i.inner_l2cache.slices_2.u_core.releaseBuf.u_core.buffer[13][0];
    release u_i.inner_l2cache.slices_2.u_core.releaseBuf.u_core.buffer[13][1];
    release u_i.inner_l2cache.slices_2.u_core.releaseBuf.u_core.buffer[14][0];
    release u_i.inner_l2cache.slices_2.u_core.releaseBuf.u_core.buffer[14][1];
    release u_i.inner_l2cache.slices_2.u_core.releaseBuf.u_core.buffer[15][0];
    release u_i.inner_l2cache.slices_2.u_core.releaseBuf.u_core.buffer[15][1];
    release u_i.inner_l2cache.slices_2.directory.tagArray.array_0_0_0.u_core.rdataReg;
    release u_i.inner_l2cache.slices_2.directory.tagArray.array_0_0_1.u_core.rdataReg;
    release u_i.inner_l2cache.slices_2.directory.tagArray.array_0_1_0.u_core.rdataReg;
    release u_i.inner_l2cache.slices_2.directory.tagArray.array_0_1_1.u_core.rdataReg;
    release u_i.inner_l2cache.slices_2.directory.metaArray.u_core.rdataReg;
    release u_i.inner_l2cache.slices_2.directory.replacer_sram_opt.u_core.rdataReg;
    release u_i.inner_l2cache.slices_2.directory.origin_bit_opt.u_core.rdataReg;
    release u_i.inner_l2cache.slices_2.dataStorage.array.array_0_0_0.u_core.rdataReg;
    release u_i.inner_l2cache.slices_2.dataStorage.array.array_0_0_1.u_core.rdataReg;
    release u_i.inner_l2cache.slices_2.dataStorage.array.array_0_0_2.u_core.rdataReg;
    release u_i.inner_l2cache.slices_2.dataStorage.array.array_0_0_3.u_core.rdataReg;
    release u_i.inner_l2cache.slices_2.dataStorage.u_core.error_REG;
    release u_i.inner_l2cache.slices_2.dataStorage.u_core.error_REG_1;
    release u_i.inner_l2cache.slices_2.mbistPl.u_core.g_node_return.pipelineDataOutReg;
    release u_i.inner_l2cache.slices_2.u_core.io_error_bits_REG_valid;
    release u_i.inner_l2cache.slices_2.u_core.io_error_bits_REG_address;
    release u_i.inner_l2cache.slices_2.u_core.io_perf_0_value_REG;
    release u_i.inner_l2cache.slices_2.u_core.io_perf_0_value_REG_1;
    release u_i.inner_l2cache.slices_2.u_core.io_perf_1_value_REG;
    release u_i.inner_l2cache.slices_2.u_core.io_perf_1_value_REG_1;
    release u_i.inner_l2cache.slices_2.u_core.io_perf_3_value_REG;
    release u_i.inner_l2cache.slices_2.u_core.io_perf_3_value_REG_1;
    release u_i.inner_l2cache.slices_2.u_core.io_perf_4_value_REG;
    release u_i.inner_l2cache.slices_2.u_core.io_perf_4_value_REG_1;
    release u_i.inner_l2cache.slices_2.u_core.io_perf_5_value_REG;
    release u_i.inner_l2cache.slices_2.u_core.io_perf_5_value_REG_1;
    release u_i.inner_l2cache.slices_2.u_core.io_perf_6_value_REG;
    release u_i.inner_l2cache.slices_2.u_core.io_perf_6_value_REG_1;
    release u_i.inner_l2cache.slices_2.u_core.io_perf_7_value_REG;
    release u_i.inner_l2cache.slices_2.u_core.io_perf_7_value_REG_1;
    release u_i.inner_l2cache.slices_2.u_core.io_perf_8_value_REG;
    release u_i.inner_l2cache.slices_2.u_core.io_perf_8_value_REG_1;
    release u_i.inner_l2cache.slices_2.u_core.io_perf_9_value_REG;
    release u_i.inner_l2cache.slices_2.u_core.io_perf_9_value_REG_1;
    release u_i.inner_l2cache.slices_2.u_core.io_perf_10_value_REG;
    release u_i.inner_l2cache.slices_2.u_core.io_perf_10_value_REG_1;
    release u_i.inner_l2cache.slices_2.u_core.io_perf_11_value_REG;
    release u_i.inner_l2cache.slices_2.u_core.io_perf_11_value_REG_1;
    release u_i.inner_l2cache.slices_2.u_core.io_perf_12_value_REG;
    release u_i.inner_l2cache.slices_2.u_core.io_perf_12_value_REG_1;
    release u_i.inner_l2cache.slices_2.u_core.io_perf_13_value_REG;
    release u_i.inner_l2cache.slices_2.u_core.io_perf_13_value_REG_1;
    release u_i.inner_l2cache.slices_2.u_core.io_perf_14_value_REG;
    release u_i.inner_l2cache.slices_2.u_core.io_perf_14_value_REG_1;
    release u_i.inner_l2cache.slices_2.u_core.io_perf_15_value_REG;
    release u_i.inner_l2cache.slices_2.u_core.io_perf_15_value_REG_1;
    release u_i.inner_l2cache.slices_2.u_core.io_perf_16_value_REG;
    release u_i.inner_l2cache.slices_2.u_core.io_perf_16_value_REG_1;
    release u_i.inner_l2cache.slices_3.u_core.mshrCtl.u_core.mshrs[0].entry.u_core.tgtid_rcompack;
    release u_i.inner_l2cache.slices_3.u_core.mshrCtl.u_core.mshrs[0].entry.u_core.txnid_rcompack;
    release u_i.inner_l2cache.slices_3.u_core.mshrCtl.u_core.mshrs[0].entry.u_core.tgtid_wcompack;
    release u_i.inner_l2cache.slices_3.u_core.mshrCtl.u_core.mshrs[0].entry.u_core.txnid_wcompack;
    release u_i.inner_l2cache.slices_3.u_core.mshrCtl.u_core.mshrs[0].entry.u_core.srcid_retryack;
    release u_i.inner_l2cache.slices_3.u_core.mshrCtl.u_core.mshrs[0].entry.u_core.acquire_ts;
    release u_i.inner_l2cache.slices_3.u_core.mshrCtl.u_core.mshrs[0].entry.u_core.release_ts;
    release u_i.inner_l2cache.slices_3.u_core.mshrCtl.u_core.mshrs[0].entry.u_core.acquire_period_valid_REG;
    release u_i.inner_l2cache.slices_3.u_core.mshrCtl.u_core.mshrs[0].entry.u_core.release_period_valid_REG;
    release u_i.inner_l2cache.slices_3.u_core.mshrCtl.u_core.mshrs[0].entry.u_core.REG;
    release u_i.inner_l2cache.slices_3.u_core.mshrCtl.u_core.mshrs[0].entry.u_core.REG_1;
    release u_i.inner_l2cache.slices_3.u_core.mshrCtl.u_core.mshrs[0].entry.u_core.REG_2;
    release u_i.inner_l2cache.slices_3.u_core.mshrCtl.u_core.mshrs[0].entry.u_core.REG_3;
    release u_i.inner_l2cache.slices_3.u_core.mshrCtl.u_core.mshrs[1].entry.u_core.tgtid_rcompack;
    release u_i.inner_l2cache.slices_3.u_core.mshrCtl.u_core.mshrs[1].entry.u_core.txnid_rcompack;
    release u_i.inner_l2cache.slices_3.u_core.mshrCtl.u_core.mshrs[1].entry.u_core.tgtid_wcompack;
    release u_i.inner_l2cache.slices_3.u_core.mshrCtl.u_core.mshrs[1].entry.u_core.txnid_wcompack;
    release u_i.inner_l2cache.slices_3.u_core.mshrCtl.u_core.mshrs[1].entry.u_core.srcid_retryack;
    release u_i.inner_l2cache.slices_3.u_core.mshrCtl.u_core.mshrs[1].entry.u_core.acquire_ts;
    release u_i.inner_l2cache.slices_3.u_core.mshrCtl.u_core.mshrs[1].entry.u_core.release_ts;
    release u_i.inner_l2cache.slices_3.u_core.mshrCtl.u_core.mshrs[1].entry.u_core.acquire_period_valid_REG;
    release u_i.inner_l2cache.slices_3.u_core.mshrCtl.u_core.mshrs[1].entry.u_core.release_period_valid_REG;
    release u_i.inner_l2cache.slices_3.u_core.mshrCtl.u_core.mshrs[1].entry.u_core.REG;
    release u_i.inner_l2cache.slices_3.u_core.mshrCtl.u_core.mshrs[1].entry.u_core.REG_1;
    release u_i.inner_l2cache.slices_3.u_core.mshrCtl.u_core.mshrs[1].entry.u_core.REG_2;
    release u_i.inner_l2cache.slices_3.u_core.mshrCtl.u_core.mshrs[1].entry.u_core.REG_3;
    release u_i.inner_l2cache.slices_3.u_core.mshrCtl.u_core.mshrs[2].entry.u_core.tgtid_rcompack;
    release u_i.inner_l2cache.slices_3.u_core.mshrCtl.u_core.mshrs[2].entry.u_core.txnid_rcompack;
    release u_i.inner_l2cache.slices_3.u_core.mshrCtl.u_core.mshrs[2].entry.u_core.tgtid_wcompack;
    release u_i.inner_l2cache.slices_3.u_core.mshrCtl.u_core.mshrs[2].entry.u_core.txnid_wcompack;
    release u_i.inner_l2cache.slices_3.u_core.mshrCtl.u_core.mshrs[2].entry.u_core.srcid_retryack;
    release u_i.inner_l2cache.slices_3.u_core.mshrCtl.u_core.mshrs[2].entry.u_core.acquire_ts;
    release u_i.inner_l2cache.slices_3.u_core.mshrCtl.u_core.mshrs[2].entry.u_core.release_ts;
    release u_i.inner_l2cache.slices_3.u_core.mshrCtl.u_core.mshrs[2].entry.u_core.acquire_period_valid_REG;
    release u_i.inner_l2cache.slices_3.u_core.mshrCtl.u_core.mshrs[2].entry.u_core.release_period_valid_REG;
    release u_i.inner_l2cache.slices_3.u_core.mshrCtl.u_core.mshrs[2].entry.u_core.REG;
    release u_i.inner_l2cache.slices_3.u_core.mshrCtl.u_core.mshrs[2].entry.u_core.REG_1;
    release u_i.inner_l2cache.slices_3.u_core.mshrCtl.u_core.mshrs[2].entry.u_core.REG_2;
    release u_i.inner_l2cache.slices_3.u_core.mshrCtl.u_core.mshrs[2].entry.u_core.REG_3;
    release u_i.inner_l2cache.slices_3.u_core.mshrCtl.u_core.mshrs[3].entry.u_core.tgtid_rcompack;
    release u_i.inner_l2cache.slices_3.u_core.mshrCtl.u_core.mshrs[3].entry.u_core.txnid_rcompack;
    release u_i.inner_l2cache.slices_3.u_core.mshrCtl.u_core.mshrs[3].entry.u_core.tgtid_wcompack;
    release u_i.inner_l2cache.slices_3.u_core.mshrCtl.u_core.mshrs[3].entry.u_core.txnid_wcompack;
    release u_i.inner_l2cache.slices_3.u_core.mshrCtl.u_core.mshrs[3].entry.u_core.srcid_retryack;
    release u_i.inner_l2cache.slices_3.u_core.mshrCtl.u_core.mshrs[3].entry.u_core.acquire_ts;
    release u_i.inner_l2cache.slices_3.u_core.mshrCtl.u_core.mshrs[3].entry.u_core.release_ts;
    release u_i.inner_l2cache.slices_3.u_core.mshrCtl.u_core.mshrs[3].entry.u_core.acquire_period_valid_REG;
    release u_i.inner_l2cache.slices_3.u_core.mshrCtl.u_core.mshrs[3].entry.u_core.release_period_valid_REG;
    release u_i.inner_l2cache.slices_3.u_core.mshrCtl.u_core.mshrs[3].entry.u_core.REG;
    release u_i.inner_l2cache.slices_3.u_core.mshrCtl.u_core.mshrs[3].entry.u_core.REG_1;
    release u_i.inner_l2cache.slices_3.u_core.mshrCtl.u_core.mshrs[3].entry.u_core.REG_2;
    release u_i.inner_l2cache.slices_3.u_core.mshrCtl.u_core.mshrs[3].entry.u_core.REG_3;
    release u_i.inner_l2cache.slices_3.u_core.mshrCtl.u_core.mshrs[4].entry.u_core.tgtid_rcompack;
    release u_i.inner_l2cache.slices_3.u_core.mshrCtl.u_core.mshrs[4].entry.u_core.txnid_rcompack;
    release u_i.inner_l2cache.slices_3.u_core.mshrCtl.u_core.mshrs[4].entry.u_core.tgtid_wcompack;
    release u_i.inner_l2cache.slices_3.u_core.mshrCtl.u_core.mshrs[4].entry.u_core.txnid_wcompack;
    release u_i.inner_l2cache.slices_3.u_core.mshrCtl.u_core.mshrs[4].entry.u_core.srcid_retryack;
    release u_i.inner_l2cache.slices_3.u_core.mshrCtl.u_core.mshrs[4].entry.u_core.acquire_ts;
    release u_i.inner_l2cache.slices_3.u_core.mshrCtl.u_core.mshrs[4].entry.u_core.release_ts;
    release u_i.inner_l2cache.slices_3.u_core.mshrCtl.u_core.mshrs[4].entry.u_core.acquire_period_valid_REG;
    release u_i.inner_l2cache.slices_3.u_core.mshrCtl.u_core.mshrs[4].entry.u_core.release_period_valid_REG;
    release u_i.inner_l2cache.slices_3.u_core.mshrCtl.u_core.mshrs[4].entry.u_core.REG;
    release u_i.inner_l2cache.slices_3.u_core.mshrCtl.u_core.mshrs[4].entry.u_core.REG_1;
    release u_i.inner_l2cache.slices_3.u_core.mshrCtl.u_core.mshrs[4].entry.u_core.REG_2;
    release u_i.inner_l2cache.slices_3.u_core.mshrCtl.u_core.mshrs[4].entry.u_core.REG_3;
    release u_i.inner_l2cache.slices_3.u_core.mshrCtl.u_core.mshrs[5].entry.u_core.tgtid_rcompack;
    release u_i.inner_l2cache.slices_3.u_core.mshrCtl.u_core.mshrs[5].entry.u_core.txnid_rcompack;
    release u_i.inner_l2cache.slices_3.u_core.mshrCtl.u_core.mshrs[5].entry.u_core.tgtid_wcompack;
    release u_i.inner_l2cache.slices_3.u_core.mshrCtl.u_core.mshrs[5].entry.u_core.txnid_wcompack;
    release u_i.inner_l2cache.slices_3.u_core.mshrCtl.u_core.mshrs[5].entry.u_core.srcid_retryack;
    release u_i.inner_l2cache.slices_3.u_core.mshrCtl.u_core.mshrs[5].entry.u_core.acquire_ts;
    release u_i.inner_l2cache.slices_3.u_core.mshrCtl.u_core.mshrs[5].entry.u_core.release_ts;
    release u_i.inner_l2cache.slices_3.u_core.mshrCtl.u_core.mshrs[5].entry.u_core.acquire_period_valid_REG;
    release u_i.inner_l2cache.slices_3.u_core.mshrCtl.u_core.mshrs[5].entry.u_core.release_period_valid_REG;
    release u_i.inner_l2cache.slices_3.u_core.mshrCtl.u_core.mshrs[5].entry.u_core.REG;
    release u_i.inner_l2cache.slices_3.u_core.mshrCtl.u_core.mshrs[5].entry.u_core.REG_1;
    release u_i.inner_l2cache.slices_3.u_core.mshrCtl.u_core.mshrs[5].entry.u_core.REG_2;
    release u_i.inner_l2cache.slices_3.u_core.mshrCtl.u_core.mshrs[5].entry.u_core.REG_3;
    release u_i.inner_l2cache.slices_3.u_core.mshrCtl.u_core.mshrs[6].entry.u_core.tgtid_rcompack;
    release u_i.inner_l2cache.slices_3.u_core.mshrCtl.u_core.mshrs[6].entry.u_core.txnid_rcompack;
    release u_i.inner_l2cache.slices_3.u_core.mshrCtl.u_core.mshrs[6].entry.u_core.tgtid_wcompack;
    release u_i.inner_l2cache.slices_3.u_core.mshrCtl.u_core.mshrs[6].entry.u_core.txnid_wcompack;
    release u_i.inner_l2cache.slices_3.u_core.mshrCtl.u_core.mshrs[6].entry.u_core.srcid_retryack;
    release u_i.inner_l2cache.slices_3.u_core.mshrCtl.u_core.mshrs[6].entry.u_core.acquire_ts;
    release u_i.inner_l2cache.slices_3.u_core.mshrCtl.u_core.mshrs[6].entry.u_core.release_ts;
    release u_i.inner_l2cache.slices_3.u_core.mshrCtl.u_core.mshrs[6].entry.u_core.acquire_period_valid_REG;
    release u_i.inner_l2cache.slices_3.u_core.mshrCtl.u_core.mshrs[6].entry.u_core.release_period_valid_REG;
    release u_i.inner_l2cache.slices_3.u_core.mshrCtl.u_core.mshrs[6].entry.u_core.REG;
    release u_i.inner_l2cache.slices_3.u_core.mshrCtl.u_core.mshrs[6].entry.u_core.REG_1;
    release u_i.inner_l2cache.slices_3.u_core.mshrCtl.u_core.mshrs[6].entry.u_core.REG_2;
    release u_i.inner_l2cache.slices_3.u_core.mshrCtl.u_core.mshrs[6].entry.u_core.REG_3;
    release u_i.inner_l2cache.slices_3.u_core.mshrCtl.u_core.mshrs[7].entry.u_core.tgtid_rcompack;
    release u_i.inner_l2cache.slices_3.u_core.mshrCtl.u_core.mshrs[7].entry.u_core.txnid_rcompack;
    release u_i.inner_l2cache.slices_3.u_core.mshrCtl.u_core.mshrs[7].entry.u_core.tgtid_wcompack;
    release u_i.inner_l2cache.slices_3.u_core.mshrCtl.u_core.mshrs[7].entry.u_core.txnid_wcompack;
    release u_i.inner_l2cache.slices_3.u_core.mshrCtl.u_core.mshrs[7].entry.u_core.srcid_retryack;
    release u_i.inner_l2cache.slices_3.u_core.mshrCtl.u_core.mshrs[7].entry.u_core.acquire_ts;
    release u_i.inner_l2cache.slices_3.u_core.mshrCtl.u_core.mshrs[7].entry.u_core.release_ts;
    release u_i.inner_l2cache.slices_3.u_core.mshrCtl.u_core.mshrs[7].entry.u_core.acquire_period_valid_REG;
    release u_i.inner_l2cache.slices_3.u_core.mshrCtl.u_core.mshrs[7].entry.u_core.release_period_valid_REG;
    release u_i.inner_l2cache.slices_3.u_core.mshrCtl.u_core.mshrs[7].entry.u_core.REG;
    release u_i.inner_l2cache.slices_3.u_core.mshrCtl.u_core.mshrs[7].entry.u_core.REG_1;
    release u_i.inner_l2cache.slices_3.u_core.mshrCtl.u_core.mshrs[7].entry.u_core.REG_2;
    release u_i.inner_l2cache.slices_3.u_core.mshrCtl.u_core.mshrs[7].entry.u_core.REG_3;
    release u_i.inner_l2cache.slices_3.u_core.mshrCtl.u_core.mshrs[8].entry.u_core.tgtid_rcompack;
    release u_i.inner_l2cache.slices_3.u_core.mshrCtl.u_core.mshrs[8].entry.u_core.txnid_rcompack;
    release u_i.inner_l2cache.slices_3.u_core.mshrCtl.u_core.mshrs[8].entry.u_core.tgtid_wcompack;
    release u_i.inner_l2cache.slices_3.u_core.mshrCtl.u_core.mshrs[8].entry.u_core.txnid_wcompack;
    release u_i.inner_l2cache.slices_3.u_core.mshrCtl.u_core.mshrs[8].entry.u_core.srcid_retryack;
    release u_i.inner_l2cache.slices_3.u_core.mshrCtl.u_core.mshrs[8].entry.u_core.acquire_ts;
    release u_i.inner_l2cache.slices_3.u_core.mshrCtl.u_core.mshrs[8].entry.u_core.release_ts;
    release u_i.inner_l2cache.slices_3.u_core.mshrCtl.u_core.mshrs[8].entry.u_core.acquire_period_valid_REG;
    release u_i.inner_l2cache.slices_3.u_core.mshrCtl.u_core.mshrs[8].entry.u_core.release_period_valid_REG;
    release u_i.inner_l2cache.slices_3.u_core.mshrCtl.u_core.mshrs[8].entry.u_core.REG;
    release u_i.inner_l2cache.slices_3.u_core.mshrCtl.u_core.mshrs[8].entry.u_core.REG_1;
    release u_i.inner_l2cache.slices_3.u_core.mshrCtl.u_core.mshrs[8].entry.u_core.REG_2;
    release u_i.inner_l2cache.slices_3.u_core.mshrCtl.u_core.mshrs[8].entry.u_core.REG_3;
    release u_i.inner_l2cache.slices_3.u_core.mshrCtl.u_core.mshrs[9].entry.u_core.tgtid_rcompack;
    release u_i.inner_l2cache.slices_3.u_core.mshrCtl.u_core.mshrs[9].entry.u_core.txnid_rcompack;
    release u_i.inner_l2cache.slices_3.u_core.mshrCtl.u_core.mshrs[9].entry.u_core.tgtid_wcompack;
    release u_i.inner_l2cache.slices_3.u_core.mshrCtl.u_core.mshrs[9].entry.u_core.txnid_wcompack;
    release u_i.inner_l2cache.slices_3.u_core.mshrCtl.u_core.mshrs[9].entry.u_core.srcid_retryack;
    release u_i.inner_l2cache.slices_3.u_core.mshrCtl.u_core.mshrs[9].entry.u_core.acquire_ts;
    release u_i.inner_l2cache.slices_3.u_core.mshrCtl.u_core.mshrs[9].entry.u_core.release_ts;
    release u_i.inner_l2cache.slices_3.u_core.mshrCtl.u_core.mshrs[9].entry.u_core.acquire_period_valid_REG;
    release u_i.inner_l2cache.slices_3.u_core.mshrCtl.u_core.mshrs[9].entry.u_core.release_period_valid_REG;
    release u_i.inner_l2cache.slices_3.u_core.mshrCtl.u_core.mshrs[9].entry.u_core.REG;
    release u_i.inner_l2cache.slices_3.u_core.mshrCtl.u_core.mshrs[9].entry.u_core.REG_1;
    release u_i.inner_l2cache.slices_3.u_core.mshrCtl.u_core.mshrs[9].entry.u_core.REG_2;
    release u_i.inner_l2cache.slices_3.u_core.mshrCtl.u_core.mshrs[9].entry.u_core.REG_3;
    release u_i.inner_l2cache.slices_3.u_core.mshrCtl.u_core.mshrs[10].entry.u_core.tgtid_rcompack;
    release u_i.inner_l2cache.slices_3.u_core.mshrCtl.u_core.mshrs[10].entry.u_core.txnid_rcompack;
    release u_i.inner_l2cache.slices_3.u_core.mshrCtl.u_core.mshrs[10].entry.u_core.tgtid_wcompack;
    release u_i.inner_l2cache.slices_3.u_core.mshrCtl.u_core.mshrs[10].entry.u_core.txnid_wcompack;
    release u_i.inner_l2cache.slices_3.u_core.mshrCtl.u_core.mshrs[10].entry.u_core.srcid_retryack;
    release u_i.inner_l2cache.slices_3.u_core.mshrCtl.u_core.mshrs[10].entry.u_core.acquire_ts;
    release u_i.inner_l2cache.slices_3.u_core.mshrCtl.u_core.mshrs[10].entry.u_core.release_ts;
    release u_i.inner_l2cache.slices_3.u_core.mshrCtl.u_core.mshrs[10].entry.u_core.acquire_period_valid_REG;
    release u_i.inner_l2cache.slices_3.u_core.mshrCtl.u_core.mshrs[10].entry.u_core.release_period_valid_REG;
    release u_i.inner_l2cache.slices_3.u_core.mshrCtl.u_core.mshrs[10].entry.u_core.REG;
    release u_i.inner_l2cache.slices_3.u_core.mshrCtl.u_core.mshrs[10].entry.u_core.REG_1;
    release u_i.inner_l2cache.slices_3.u_core.mshrCtl.u_core.mshrs[10].entry.u_core.REG_2;
    release u_i.inner_l2cache.slices_3.u_core.mshrCtl.u_core.mshrs[10].entry.u_core.REG_3;
    release u_i.inner_l2cache.slices_3.u_core.mshrCtl.u_core.mshrs[11].entry.u_core.tgtid_rcompack;
    release u_i.inner_l2cache.slices_3.u_core.mshrCtl.u_core.mshrs[11].entry.u_core.txnid_rcompack;
    release u_i.inner_l2cache.slices_3.u_core.mshrCtl.u_core.mshrs[11].entry.u_core.tgtid_wcompack;
    release u_i.inner_l2cache.slices_3.u_core.mshrCtl.u_core.mshrs[11].entry.u_core.txnid_wcompack;
    release u_i.inner_l2cache.slices_3.u_core.mshrCtl.u_core.mshrs[11].entry.u_core.srcid_retryack;
    release u_i.inner_l2cache.slices_3.u_core.mshrCtl.u_core.mshrs[11].entry.u_core.acquire_ts;
    release u_i.inner_l2cache.slices_3.u_core.mshrCtl.u_core.mshrs[11].entry.u_core.release_ts;
    release u_i.inner_l2cache.slices_3.u_core.mshrCtl.u_core.mshrs[11].entry.u_core.acquire_period_valid_REG;
    release u_i.inner_l2cache.slices_3.u_core.mshrCtl.u_core.mshrs[11].entry.u_core.release_period_valid_REG;
    release u_i.inner_l2cache.slices_3.u_core.mshrCtl.u_core.mshrs[11].entry.u_core.REG;
    release u_i.inner_l2cache.slices_3.u_core.mshrCtl.u_core.mshrs[11].entry.u_core.REG_1;
    release u_i.inner_l2cache.slices_3.u_core.mshrCtl.u_core.mshrs[11].entry.u_core.REG_2;
    release u_i.inner_l2cache.slices_3.u_core.mshrCtl.u_core.mshrs[11].entry.u_core.REG_3;
    release u_i.inner_l2cache.slices_3.u_core.mshrCtl.u_core.mshrs[12].entry.u_core.tgtid_rcompack;
    release u_i.inner_l2cache.slices_3.u_core.mshrCtl.u_core.mshrs[12].entry.u_core.txnid_rcompack;
    release u_i.inner_l2cache.slices_3.u_core.mshrCtl.u_core.mshrs[12].entry.u_core.tgtid_wcompack;
    release u_i.inner_l2cache.slices_3.u_core.mshrCtl.u_core.mshrs[12].entry.u_core.txnid_wcompack;
    release u_i.inner_l2cache.slices_3.u_core.mshrCtl.u_core.mshrs[12].entry.u_core.srcid_retryack;
    release u_i.inner_l2cache.slices_3.u_core.mshrCtl.u_core.mshrs[12].entry.u_core.acquire_ts;
    release u_i.inner_l2cache.slices_3.u_core.mshrCtl.u_core.mshrs[12].entry.u_core.release_ts;
    release u_i.inner_l2cache.slices_3.u_core.mshrCtl.u_core.mshrs[12].entry.u_core.acquire_period_valid_REG;
    release u_i.inner_l2cache.slices_3.u_core.mshrCtl.u_core.mshrs[12].entry.u_core.release_period_valid_REG;
    release u_i.inner_l2cache.slices_3.u_core.mshrCtl.u_core.mshrs[12].entry.u_core.REG;
    release u_i.inner_l2cache.slices_3.u_core.mshrCtl.u_core.mshrs[12].entry.u_core.REG_1;
    release u_i.inner_l2cache.slices_3.u_core.mshrCtl.u_core.mshrs[12].entry.u_core.REG_2;
    release u_i.inner_l2cache.slices_3.u_core.mshrCtl.u_core.mshrs[12].entry.u_core.REG_3;
    release u_i.inner_l2cache.slices_3.u_core.mshrCtl.u_core.mshrs[13].entry.u_core.tgtid_rcompack;
    release u_i.inner_l2cache.slices_3.u_core.mshrCtl.u_core.mshrs[13].entry.u_core.txnid_rcompack;
    release u_i.inner_l2cache.slices_3.u_core.mshrCtl.u_core.mshrs[13].entry.u_core.tgtid_wcompack;
    release u_i.inner_l2cache.slices_3.u_core.mshrCtl.u_core.mshrs[13].entry.u_core.txnid_wcompack;
    release u_i.inner_l2cache.slices_3.u_core.mshrCtl.u_core.mshrs[13].entry.u_core.srcid_retryack;
    release u_i.inner_l2cache.slices_3.u_core.mshrCtl.u_core.mshrs[13].entry.u_core.acquire_ts;
    release u_i.inner_l2cache.slices_3.u_core.mshrCtl.u_core.mshrs[13].entry.u_core.release_ts;
    release u_i.inner_l2cache.slices_3.u_core.mshrCtl.u_core.mshrs[13].entry.u_core.acquire_period_valid_REG;
    release u_i.inner_l2cache.slices_3.u_core.mshrCtl.u_core.mshrs[13].entry.u_core.release_period_valid_REG;
    release u_i.inner_l2cache.slices_3.u_core.mshrCtl.u_core.mshrs[13].entry.u_core.REG;
    release u_i.inner_l2cache.slices_3.u_core.mshrCtl.u_core.mshrs[13].entry.u_core.REG_1;
    release u_i.inner_l2cache.slices_3.u_core.mshrCtl.u_core.mshrs[13].entry.u_core.REG_2;
    release u_i.inner_l2cache.slices_3.u_core.mshrCtl.u_core.mshrs[13].entry.u_core.REG_3;
    release u_i.inner_l2cache.slices_3.u_core.mshrCtl.u_core.mshrs[14].entry.u_core.tgtid_rcompack;
    release u_i.inner_l2cache.slices_3.u_core.mshrCtl.u_core.mshrs[14].entry.u_core.txnid_rcompack;
    release u_i.inner_l2cache.slices_3.u_core.mshrCtl.u_core.mshrs[14].entry.u_core.tgtid_wcompack;
    release u_i.inner_l2cache.slices_3.u_core.mshrCtl.u_core.mshrs[14].entry.u_core.txnid_wcompack;
    release u_i.inner_l2cache.slices_3.u_core.mshrCtl.u_core.mshrs[14].entry.u_core.srcid_retryack;
    release u_i.inner_l2cache.slices_3.u_core.mshrCtl.u_core.mshrs[14].entry.u_core.acquire_ts;
    release u_i.inner_l2cache.slices_3.u_core.mshrCtl.u_core.mshrs[14].entry.u_core.release_ts;
    release u_i.inner_l2cache.slices_3.u_core.mshrCtl.u_core.mshrs[14].entry.u_core.acquire_period_valid_REG;
    release u_i.inner_l2cache.slices_3.u_core.mshrCtl.u_core.mshrs[14].entry.u_core.release_period_valid_REG;
    release u_i.inner_l2cache.slices_3.u_core.mshrCtl.u_core.mshrs[14].entry.u_core.REG;
    release u_i.inner_l2cache.slices_3.u_core.mshrCtl.u_core.mshrs[14].entry.u_core.REG_1;
    release u_i.inner_l2cache.slices_3.u_core.mshrCtl.u_core.mshrs[14].entry.u_core.REG_2;
    release u_i.inner_l2cache.slices_3.u_core.mshrCtl.u_core.mshrs[14].entry.u_core.REG_3;
    release u_i.inner_l2cache.slices_3.u_core.mshrCtl.u_core.mshrs[15].entry.u_core.tgtid_rcompack;
    release u_i.inner_l2cache.slices_3.u_core.mshrCtl.u_core.mshrs[15].entry.u_core.txnid_rcompack;
    release u_i.inner_l2cache.slices_3.u_core.mshrCtl.u_core.mshrs[15].entry.u_core.tgtid_wcompack;
    release u_i.inner_l2cache.slices_3.u_core.mshrCtl.u_core.mshrs[15].entry.u_core.txnid_wcompack;
    release u_i.inner_l2cache.slices_3.u_core.mshrCtl.u_core.mshrs[15].entry.u_core.srcid_retryack;
    release u_i.inner_l2cache.slices_3.u_core.mshrCtl.u_core.mshrs[15].entry.u_core.acquire_ts;
    release u_i.inner_l2cache.slices_3.u_core.mshrCtl.u_core.mshrs[15].entry.u_core.release_ts;
    release u_i.inner_l2cache.slices_3.u_core.mshrCtl.u_core.mshrs[15].entry.u_core.acquire_period_valid_REG;
    release u_i.inner_l2cache.slices_3.u_core.mshrCtl.u_core.mshrs[15].entry.u_core.release_period_valid_REG;
    release u_i.inner_l2cache.slices_3.u_core.mshrCtl.u_core.mshrs[15].entry.u_core.REG;
    release u_i.inner_l2cache.slices_3.u_core.mshrCtl.u_core.mshrs[15].entry.u_core.REG_1;
    release u_i.inner_l2cache.slices_3.u_core.mshrCtl.u_core.mshrs[15].entry.u_core.REG_2;
    release u_i.inner_l2cache.slices_3.u_core.mshrCtl.u_core.mshrs[15].entry.u_core.REG_3;
    release u_i.inner_l2cache.slices_3.u_core.mshrCtl.u_core.io_perf_0_value_REG;
    release u_i.inner_l2cache.slices_3.u_core.mshrCtl.u_core.io_perf_0_value_REG_1;
    release u_i.inner_l2cache.slices_3.u_core.mshrCtl.u_core.io_perf_1_value_REG;
    release u_i.inner_l2cache.slices_3.u_core.mshrCtl.u_core.io_perf_1_value_REG_1;
    release u_i.inner_l2cache.slices_3.u_core.mshrCtl.u_core.io_perf_3_value_REG;
    release u_i.inner_l2cache.slices_3.u_core.mshrCtl.u_core.io_perf_3_value_REG_1;
    release u_i.inner_l2cache.slices_3.u_core.mshrCtl.u_core.REG;
    release u_i.inner_l2cache.slices_3.u_core.mainPipe.u_core.data_s4;
    release u_i.inner_l2cache.slices_3.u_core.mainPipe.u_core.data_s5;
    release u_i.inner_l2cache.slices_3.u_core.mainPipe.u_core.s3DropValid_d1;
    release u_i.inner_l2cache.slices_3.u_core.mainPipe.u_core.reqDrop_s3_d1;
    release u_i.inner_l2cache.slices_3.u_core.mainPipe.u_core.reqDrop_s3_d2;
    release u_i.inner_l2cache.slices_3.u_core.mainPipe.u_core.reqDrop_s4_d1;
    release u_i.inner_l2cache.slices_3.u_core.mainPipe.u_core.perf_d1[0];
    release u_i.inner_l2cache.slices_3.u_core.mainPipe.u_core.perf[0];
    release u_i.inner_l2cache.slices_3.u_core.mainPipe.u_core.perf_d1[1];
    release u_i.inner_l2cache.slices_3.u_core.mainPipe.u_core.perf[1];
    release u_i.inner_l2cache.slices_3.u_core.mainPipe.u_core.perf_d1[2];
    release u_i.inner_l2cache.slices_3.u_core.mainPipe.u_core.perf[2];
    release u_i.inner_l2cache.slices_3.u_core.mainPipe.u_core.perf_d1[3];
    release u_i.inner_l2cache.slices_3.u_core.mainPipe.u_core.perf[3];
    release u_i.inner_l2cache.slices_3.u_core.mainPipe.u_core.perf_d1[4];
    release u_i.inner_l2cache.slices_3.u_core.mainPipe.u_core.perf[4];
    release u_i.inner_l2cache.slices_3.u_core.mainPipe.u_core.perf_d1[5];
    release u_i.inner_l2cache.slices_3.u_core.mainPipe.u_core.perf[5];
    release u_i.inner_l2cache.slices_3.u_core.mainPipe.u_core.perf_d1[6];
    release u_i.inner_l2cache.slices_3.u_core.mainPipe.u_core.perf[6];
    release u_i.inner_l2cache.slices_3.u_core.mainPipe.u_core.perf_d1[7];
    release u_i.inner_l2cache.slices_3.u_core.mainPipe.u_core.perf[7];
    release u_i.inner_l2cache.slices_3.u_core.mainPipe.u_core.perf_d1[8];
    release u_i.inner_l2cache.slices_3.u_core.mainPipe.u_core.perf[8];
    release u_i.inner_l2cache.slices_3.u_core.mainPipe.u_core.perf_d1[9];
    release u_i.inner_l2cache.slices_3.u_core.mainPipe.u_core.perf[9];
    release u_i.inner_l2cache.slices_3.u_core.mainPipe.u_core.perf_d1[10];
    release u_i.inner_l2cache.slices_3.u_core.mainPipe.u_core.perf[10];
    release u_i.inner_l2cache.slices_3.u_core.mainPipe.u_core.perf_d1[11];
    release u_i.inner_l2cache.slices_3.u_core.mainPipe.u_core.perf[11];
    release u_i.inner_l2cache.slices_3.u_core.mainPipe.u_core.perf_d1[12];
    release u_i.inner_l2cache.slices_3.u_core.mainPipe.u_core.perf[12];
    release u_i.inner_l2cache.slices_3.u_core.grantBuf.u_core.validPrev[0];
    release u_i.inner_l2cache.slices_3.u_core.grantBuf.u_core.histValidPrev[0];
    release u_i.inner_l2cache.slices_3.u_core.grantBuf.u_core.validPrev[1];
    release u_i.inner_l2cache.slices_3.u_core.grantBuf.u_core.histValidPrev[1];
    release u_i.inner_l2cache.slices_3.u_core.grantBuf.u_core.validPrev[2];
    release u_i.inner_l2cache.slices_3.u_core.grantBuf.u_core.histValidPrev[2];
    release u_i.inner_l2cache.slices_3.u_core.grantBuf.u_core.validPrev[3];
    release u_i.inner_l2cache.slices_3.u_core.grantBuf.u_core.histValidPrev[3];
    release u_i.inner_l2cache.slices_3.u_core.grantBuf.u_core.validPrev[4];
    release u_i.inner_l2cache.slices_3.u_core.grantBuf.u_core.histValidPrev[4];
    release u_i.inner_l2cache.slices_3.u_core.grantBuf.u_core.validPrev[5];
    release u_i.inner_l2cache.slices_3.u_core.grantBuf.u_core.histValidPrev[5];
    release u_i.inner_l2cache.slices_3.u_core.grantBuf.u_core.validPrev[6];
    release u_i.inner_l2cache.slices_3.u_core.grantBuf.u_core.histValidPrev[6];
    release u_i.inner_l2cache.slices_3.u_core.grantBuf.u_core.validPrev[7];
    release u_i.inner_l2cache.slices_3.u_core.grantBuf.u_core.histValidPrev[7];
    release u_i.inner_l2cache.slices_3.u_core.grantBuf.u_core.validPrev[8];
    release u_i.inner_l2cache.slices_3.u_core.grantBuf.u_core.histValidPrev[8];
    release u_i.inner_l2cache.slices_3.u_core.grantBuf.u_core.validPrev[9];
    release u_i.inner_l2cache.slices_3.u_core.grantBuf.u_core.histValidPrev[9];
    release u_i.inner_l2cache.slices_3.u_core.grantBuf.u_core.validPrev[10];
    release u_i.inner_l2cache.slices_3.u_core.grantBuf.u_core.histValidPrev[10];
    release u_i.inner_l2cache.slices_3.u_core.grantBuf.u_core.validPrev[11];
    release u_i.inner_l2cache.slices_3.u_core.grantBuf.u_core.histValidPrev[11];
    release u_i.inner_l2cache.slices_3.u_core.grantBuf.u_core.validPrev[12];
    release u_i.inner_l2cache.slices_3.u_core.grantBuf.u_core.histValidPrev[12];
    release u_i.inner_l2cache.slices_3.u_core.grantBuf.u_core.validPrev[13];
    release u_i.inner_l2cache.slices_3.u_core.grantBuf.u_core.histValidPrev[13];
    release u_i.inner_l2cache.slices_3.u_core.grantBuf.u_core.validPrev[14];
    release u_i.inner_l2cache.slices_3.u_core.grantBuf.u_core.histValidPrev[14];
    release u_i.inner_l2cache.slices_3.u_core.grantBuf.u_core.validPrev[15];
    release u_i.inner_l2cache.slices_3.u_core.grantBuf.u_core.histValidPrev[15];
    release u_i.inner_l2cache.slices_3.u_core.rxsnp.u_core.replPrevForBlock[0];
    release u_i.inner_l2cache.slices_3.u_core.rxsnp.u_core.replPrevForNest[0];
    release u_i.inner_l2cache.slices_3.u_core.rxsnp.u_core.replPrevForBlock[1];
    release u_i.inner_l2cache.slices_3.u_core.rxsnp.u_core.replPrevForNest[1];
    release u_i.inner_l2cache.slices_3.u_core.rxsnp.u_core.replPrevForBlock[2];
    release u_i.inner_l2cache.slices_3.u_core.rxsnp.u_core.replPrevForNest[2];
    release u_i.inner_l2cache.slices_3.u_core.rxsnp.u_core.replPrevForBlock[3];
    release u_i.inner_l2cache.slices_3.u_core.rxsnp.u_core.replPrevForNest[3];
    release u_i.inner_l2cache.slices_3.u_core.rxsnp.u_core.replPrevForBlock[4];
    release u_i.inner_l2cache.slices_3.u_core.rxsnp.u_core.replPrevForNest[4];
    release u_i.inner_l2cache.slices_3.u_core.rxsnp.u_core.replPrevForBlock[5];
    release u_i.inner_l2cache.slices_3.u_core.rxsnp.u_core.replPrevForNest[5];
    release u_i.inner_l2cache.slices_3.u_core.rxsnp.u_core.replPrevForBlock[6];
    release u_i.inner_l2cache.slices_3.u_core.rxsnp.u_core.replPrevForNest[6];
    release u_i.inner_l2cache.slices_3.u_core.rxsnp.u_core.replPrevForBlock[7];
    release u_i.inner_l2cache.slices_3.u_core.rxsnp.u_core.replPrevForNest[7];
    release u_i.inner_l2cache.slices_3.u_core.rxsnp.u_core.replPrevForBlock[8];
    release u_i.inner_l2cache.slices_3.u_core.rxsnp.u_core.replPrevForNest[8];
    release u_i.inner_l2cache.slices_3.u_core.rxsnp.u_core.replPrevForBlock[9];
    release u_i.inner_l2cache.slices_3.u_core.rxsnp.u_core.replPrevForNest[9];
    release u_i.inner_l2cache.slices_3.u_core.rxsnp.u_core.replPrevForBlock[10];
    release u_i.inner_l2cache.slices_3.u_core.rxsnp.u_core.replPrevForNest[10];
    release u_i.inner_l2cache.slices_3.u_core.rxsnp.u_core.replPrevForBlock[11];
    release u_i.inner_l2cache.slices_3.u_core.rxsnp.u_core.replPrevForNest[11];
    release u_i.inner_l2cache.slices_3.u_core.rxsnp.u_core.replPrevForBlock[12];
    release u_i.inner_l2cache.slices_3.u_core.rxsnp.u_core.replPrevForNest[12];
    release u_i.inner_l2cache.slices_3.u_core.rxsnp.u_core.replPrevForBlock[13];
    release u_i.inner_l2cache.slices_3.u_core.rxsnp.u_core.replPrevForNest[13];
    release u_i.inner_l2cache.slices_3.u_core.rxsnp.u_core.replPrevForBlock[14];
    release u_i.inner_l2cache.slices_3.u_core.rxsnp.u_core.replPrevForNest[14];
    release u_i.inner_l2cache.slices_3.u_core.rxsnp.u_core.replPrevForBlock[15];
    release u_i.inner_l2cache.slices_3.u_core.rxsnp.u_core.replPrevForNest[15];
    release u_i.inner_l2cache.slices_3.u_core.reqBuf.chosenQ.u_core.ram;
    release u_i.inner_l2cache.slices_3.u_core.reqBuf.u_core.hitPfPrev_set;
    release u_i.inner_l2cache.slices_3.u_core.reqBuf.u_core.hitPfPrev_tag;
    release u_i.inner_l2cache.slices_3.u_core.reqBuf.u_core.mergeAPrev_set;
    release u_i.inner_l2cache.slices_3.u_core.reqBuf.u_core.mergeAPrev_tag;
    release u_i.inner_l2cache.slices_3.u_core.reqBuf.u_core.sameSetS3Valid[0];
    release u_i.inner_l2cache.slices_3.u_core.reqBuf.u_core.sameSetS3Set[0];
    release u_i.inner_l2cache.slices_3.u_core.reqBuf.u_core.sameSetS3Valid[1];
    release u_i.inner_l2cache.slices_3.u_core.reqBuf.u_core.sameSetS3Set[1];
    release u_i.inner_l2cache.slices_3.u_core.reqBuf.u_core.sameSetS3Valid[2];
    release u_i.inner_l2cache.slices_3.u_core.reqBuf.u_core.sameSetS3Set[2];
    release u_i.inner_l2cache.slices_3.u_core.reqBuf.u_core.sameSetS3Valid[3];
    release u_i.inner_l2cache.slices_3.u_core.reqBuf.u_core.sameSetS3Set[3];
    release u_i.inner_l2cache.slices_3.u_core.reqBuf.u_core.sameSetS3Valid[4];
    release u_i.inner_l2cache.slices_3.u_core.reqBuf.u_core.sameSetS3Set[4];
    release u_i.inner_l2cache.slices_3.u_core.reqBuf.u_core.sameSetS3Valid[5];
    release u_i.inner_l2cache.slices_3.u_core.reqBuf.u_core.sameSetS3Set[5];
    release u_i.inner_l2cache.slices_3.u_core.sinkC.u_core.bufRespStage[0];
    release u_i.inner_l2cache.slices_3.u_core.sinkC.u_core.bufRespStage[1];
    release u_i.inner_l2cache.slices_3.u_core.sinkC.u_core.bufRespOut[0];
    release u_i.inner_l2cache.slices_3.u_core.sinkC.u_core.bufRespOut[1];
    release u_i.inner_l2cache.slices_3.u_core.sinkC.u_core.refillIdReg;
    release u_i.inner_l2cache.slices_3.u_core.sinkC.u_core.refillBufIdxReg;
    release u_i.inner_l2cache.slices_3.u_core.sinkC.u_core.taskFirePrev;
    release u_i.inner_l2cache.slices_3.u_core.sinkC.u_core.taskBufIdxPrev;
    release u_i.inner_l2cache.slices_3.u_core.reqArb.u_core.ds_mcp2_stall;
    release u_i.inner_l2cache.slices_3.u_core.refillBuf.u_core.buffer[0][0];
    release u_i.inner_l2cache.slices_3.u_core.refillBuf.u_core.buffer[0][1];
    release u_i.inner_l2cache.slices_3.u_core.refillBuf.u_core.buffer[1][0];
    release u_i.inner_l2cache.slices_3.u_core.refillBuf.u_core.buffer[1][1];
    release u_i.inner_l2cache.slices_3.u_core.refillBuf.u_core.buffer[2][0];
    release u_i.inner_l2cache.slices_3.u_core.refillBuf.u_core.buffer[2][1];
    release u_i.inner_l2cache.slices_3.u_core.refillBuf.u_core.buffer[3][0];
    release u_i.inner_l2cache.slices_3.u_core.refillBuf.u_core.buffer[3][1];
    release u_i.inner_l2cache.slices_3.u_core.refillBuf.u_core.buffer[4][0];
    release u_i.inner_l2cache.slices_3.u_core.refillBuf.u_core.buffer[4][1];
    release u_i.inner_l2cache.slices_3.u_core.refillBuf.u_core.buffer[5][0];
    release u_i.inner_l2cache.slices_3.u_core.refillBuf.u_core.buffer[5][1];
    release u_i.inner_l2cache.slices_3.u_core.refillBuf.u_core.buffer[6][0];
    release u_i.inner_l2cache.slices_3.u_core.refillBuf.u_core.buffer[6][1];
    release u_i.inner_l2cache.slices_3.u_core.refillBuf.u_core.buffer[7][0];
    release u_i.inner_l2cache.slices_3.u_core.refillBuf.u_core.buffer[7][1];
    release u_i.inner_l2cache.slices_3.u_core.refillBuf.u_core.buffer[8][0];
    release u_i.inner_l2cache.slices_3.u_core.refillBuf.u_core.buffer[8][1];
    release u_i.inner_l2cache.slices_3.u_core.refillBuf.u_core.buffer[9][0];
    release u_i.inner_l2cache.slices_3.u_core.refillBuf.u_core.buffer[9][1];
    release u_i.inner_l2cache.slices_3.u_core.refillBuf.u_core.buffer[10][0];
    release u_i.inner_l2cache.slices_3.u_core.refillBuf.u_core.buffer[10][1];
    release u_i.inner_l2cache.slices_3.u_core.refillBuf.u_core.buffer[11][0];
    release u_i.inner_l2cache.slices_3.u_core.refillBuf.u_core.buffer[11][1];
    release u_i.inner_l2cache.slices_3.u_core.refillBuf.u_core.buffer[12][0];
    release u_i.inner_l2cache.slices_3.u_core.refillBuf.u_core.buffer[12][1];
    release u_i.inner_l2cache.slices_3.u_core.refillBuf.u_core.buffer[13][0];
    release u_i.inner_l2cache.slices_3.u_core.refillBuf.u_core.buffer[13][1];
    release u_i.inner_l2cache.slices_3.u_core.refillBuf.u_core.buffer[14][0];
    release u_i.inner_l2cache.slices_3.u_core.refillBuf.u_core.buffer[14][1];
    release u_i.inner_l2cache.slices_3.u_core.refillBuf.u_core.buffer[15][0];
    release u_i.inner_l2cache.slices_3.u_core.refillBuf.u_core.buffer[15][1];
    release u_i.inner_l2cache.slices_3.u_core.releaseBuf.u_core.buffer[0][0];
    release u_i.inner_l2cache.slices_3.u_core.releaseBuf.u_core.buffer[0][1];
    release u_i.inner_l2cache.slices_3.u_core.releaseBuf.u_core.buffer[1][0];
    release u_i.inner_l2cache.slices_3.u_core.releaseBuf.u_core.buffer[1][1];
    release u_i.inner_l2cache.slices_3.u_core.releaseBuf.u_core.buffer[2][0];
    release u_i.inner_l2cache.slices_3.u_core.releaseBuf.u_core.buffer[2][1];
    release u_i.inner_l2cache.slices_3.u_core.releaseBuf.u_core.buffer[3][0];
    release u_i.inner_l2cache.slices_3.u_core.releaseBuf.u_core.buffer[3][1];
    release u_i.inner_l2cache.slices_3.u_core.releaseBuf.u_core.buffer[4][0];
    release u_i.inner_l2cache.slices_3.u_core.releaseBuf.u_core.buffer[4][1];
    release u_i.inner_l2cache.slices_3.u_core.releaseBuf.u_core.buffer[5][0];
    release u_i.inner_l2cache.slices_3.u_core.releaseBuf.u_core.buffer[5][1];
    release u_i.inner_l2cache.slices_3.u_core.releaseBuf.u_core.buffer[6][0];
    release u_i.inner_l2cache.slices_3.u_core.releaseBuf.u_core.buffer[6][1];
    release u_i.inner_l2cache.slices_3.u_core.releaseBuf.u_core.buffer[7][0];
    release u_i.inner_l2cache.slices_3.u_core.releaseBuf.u_core.buffer[7][1];
    release u_i.inner_l2cache.slices_3.u_core.releaseBuf.u_core.buffer[8][0];
    release u_i.inner_l2cache.slices_3.u_core.releaseBuf.u_core.buffer[8][1];
    release u_i.inner_l2cache.slices_3.u_core.releaseBuf.u_core.buffer[9][0];
    release u_i.inner_l2cache.slices_3.u_core.releaseBuf.u_core.buffer[9][1];
    release u_i.inner_l2cache.slices_3.u_core.releaseBuf.u_core.buffer[10][0];
    release u_i.inner_l2cache.slices_3.u_core.releaseBuf.u_core.buffer[10][1];
    release u_i.inner_l2cache.slices_3.u_core.releaseBuf.u_core.buffer[11][0];
    release u_i.inner_l2cache.slices_3.u_core.releaseBuf.u_core.buffer[11][1];
    release u_i.inner_l2cache.slices_3.u_core.releaseBuf.u_core.buffer[12][0];
    release u_i.inner_l2cache.slices_3.u_core.releaseBuf.u_core.buffer[12][1];
    release u_i.inner_l2cache.slices_3.u_core.releaseBuf.u_core.buffer[13][0];
    release u_i.inner_l2cache.slices_3.u_core.releaseBuf.u_core.buffer[13][1];
    release u_i.inner_l2cache.slices_3.u_core.releaseBuf.u_core.buffer[14][0];
    release u_i.inner_l2cache.slices_3.u_core.releaseBuf.u_core.buffer[14][1];
    release u_i.inner_l2cache.slices_3.u_core.releaseBuf.u_core.buffer[15][0];
    release u_i.inner_l2cache.slices_3.u_core.releaseBuf.u_core.buffer[15][1];
    release u_i.inner_l2cache.slices_3.directory.tagArray.array_0_0_0.u_core.rdataReg;
    release u_i.inner_l2cache.slices_3.directory.tagArray.array_0_0_1.u_core.rdataReg;
    release u_i.inner_l2cache.slices_3.directory.tagArray.array_0_1_0.u_core.rdataReg;
    release u_i.inner_l2cache.slices_3.directory.tagArray.array_0_1_1.u_core.rdataReg;
    release u_i.inner_l2cache.slices_3.directory.metaArray.u_core.rdataReg;
    release u_i.inner_l2cache.slices_3.directory.replacer_sram_opt.u_core.rdataReg;
    release u_i.inner_l2cache.slices_3.directory.origin_bit_opt.u_core.rdataReg;
    release u_i.inner_l2cache.slices_3.dataStorage.array.array_0_0_0.u_core.rdataReg;
    release u_i.inner_l2cache.slices_3.dataStorage.array.array_0_0_1.u_core.rdataReg;
    release u_i.inner_l2cache.slices_3.dataStorage.array.array_0_0_2.u_core.rdataReg;
    release u_i.inner_l2cache.slices_3.dataStorage.array.array_0_0_3.u_core.rdataReg;
    release u_i.inner_l2cache.slices_3.dataStorage.u_core.error_REG;
    release u_i.inner_l2cache.slices_3.dataStorage.u_core.error_REG_1;
    release u_i.inner_l2cache.slices_3.mbistPl.u_core.g_node_return.pipelineDataOutReg;
    release u_i.inner_l2cache.slices_3.u_core.io_error_bits_REG_valid;
    release u_i.inner_l2cache.slices_3.u_core.io_error_bits_REG_address;
    release u_i.inner_l2cache.slices_3.u_core.io_perf_0_value_REG;
    release u_i.inner_l2cache.slices_3.u_core.io_perf_0_value_REG_1;
    release u_i.inner_l2cache.slices_3.u_core.io_perf_1_value_REG;
    release u_i.inner_l2cache.slices_3.u_core.io_perf_1_value_REG_1;
    release u_i.inner_l2cache.slices_3.u_core.io_perf_3_value_REG;
    release u_i.inner_l2cache.slices_3.u_core.io_perf_3_value_REG_1;
    release u_i.inner_l2cache.slices_3.u_core.io_perf_4_value_REG;
    release u_i.inner_l2cache.slices_3.u_core.io_perf_4_value_REG_1;
    release u_i.inner_l2cache.slices_3.u_core.io_perf_5_value_REG;
    release u_i.inner_l2cache.slices_3.u_core.io_perf_5_value_REG_1;
    release u_i.inner_l2cache.slices_3.u_core.io_perf_6_value_REG;
    release u_i.inner_l2cache.slices_3.u_core.io_perf_6_value_REG_1;
    release u_i.inner_l2cache.slices_3.u_core.io_perf_7_value_REG;
    release u_i.inner_l2cache.slices_3.u_core.io_perf_7_value_REG_1;
    release u_i.inner_l2cache.slices_3.u_core.io_perf_8_value_REG;
    release u_i.inner_l2cache.slices_3.u_core.io_perf_8_value_REG_1;
    release u_i.inner_l2cache.slices_3.u_core.io_perf_9_value_REG;
    release u_i.inner_l2cache.slices_3.u_core.io_perf_9_value_REG_1;
    release u_i.inner_l2cache.slices_3.u_core.io_perf_10_value_REG;
    release u_i.inner_l2cache.slices_3.u_core.io_perf_10_value_REG_1;
    release u_i.inner_l2cache.slices_3.u_core.io_perf_11_value_REG;
    release u_i.inner_l2cache.slices_3.u_core.io_perf_11_value_REG_1;
    release u_i.inner_l2cache.slices_3.u_core.io_perf_12_value_REG;
    release u_i.inner_l2cache.slices_3.u_core.io_perf_12_value_REG_1;
    release u_i.inner_l2cache.slices_3.u_core.io_perf_13_value_REG;
    release u_i.inner_l2cache.slices_3.u_core.io_perf_13_value_REG_1;
    release u_i.inner_l2cache.slices_3.u_core.io_perf_14_value_REG;
    release u_i.inner_l2cache.slices_3.u_core.io_perf_14_value_REG_1;
    release u_i.inner_l2cache.slices_3.u_core.io_perf_15_value_REG;
    release u_i.inner_l2cache.slices_3.u_core.io_perf_15_value_REG_1;
    release u_i.inner_l2cache.slices_3.u_core.io_perf_16_value_REG;
    release u_i.inner_l2cache.slices_3.u_core.io_perf_16_value_REG_1;
    release u_i.inner_l2cache.mmioBridge.entries_0.u_core.s_txreq;
    release u_i.inner_l2cache.mmioBridge.entries_0.u_core.s_ncbwrdata;
    release u_i.inner_l2cache.mmioBridge.entries_0.u_core.s_resp;
    release u_i.inner_l2cache.mmioBridge.entries_0.u_core.w_comp;
    release u_i.inner_l2cache.mmioBridge.entries_0.u_core.w_dbidresp;
    release u_i.inner_l2cache.mmioBridge.entries_0.u_core.w_compdata;
    release u_i.inner_l2cache.mmioBridge.entries_0.u_core.w_pcrdgrant;
    release u_i.inner_l2cache.mmioBridge.entries_0.u_core.w_readreceipt;
    release u_i.inner_l2cache.mmioBridge.entries_0.u_core.allowRetry;
    release u_i.inner_l2cache.mmioBridge.entries_0.u_core.req_opcode;
    release u_i.inner_l2cache.mmioBridge.entries_0.u_core.req_size;
    release u_i.inner_l2cache.mmioBridge.entries_0.u_core.req_source;
    release u_i.inner_l2cache.mmioBridge.entries_0.u_core.req_address;
    release u_i.inner_l2cache.mmioBridge.entries_0.u_core.req_user_memBackType_MM;
    release u_i.inner_l2cache.mmioBridge.entries_0.u_core.req_user_memPageType_NC;
    release u_i.inner_l2cache.mmioBridge.entries_0.u_core.req_mask;
    release u_i.inner_l2cache.mmioBridge.entries_0.u_core.req_data;
    release u_i.inner_l2cache.mmioBridge.entries_0.u_core.req_corrupt;
    release u_i.inner_l2cache.mmioBridge.entries_0.u_core.rdata;
    release u_i.inner_l2cache.mmioBridge.entries_0.u_core.srcID;
    release u_i.inner_l2cache.mmioBridge.entries_0.u_core.dbID;
    release u_i.inner_l2cache.mmioBridge.entries_0.u_core.pCrdType;
    release u_i.inner_l2cache.mmioBridge.entries_0.u_core.denied;
    release u_i.inner_l2cache.mmioBridge.entries_0.u_core.corrupt;
    release u_i.inner_l2cache.mmioBridge.entries_0.u_core.traceTag;
    release u_i.inner_l2cache.mmioBridge.entries_1.u_core.s_txreq;
    release u_i.inner_l2cache.mmioBridge.entries_1.u_core.s_ncbwrdata;
    release u_i.inner_l2cache.mmioBridge.entries_1.u_core.s_resp;
    release u_i.inner_l2cache.mmioBridge.entries_1.u_core.w_comp;
    release u_i.inner_l2cache.mmioBridge.entries_1.u_core.w_dbidresp;
    release u_i.inner_l2cache.mmioBridge.entries_1.u_core.w_compdata;
    release u_i.inner_l2cache.mmioBridge.entries_1.u_core.w_pcrdgrant;
    release u_i.inner_l2cache.mmioBridge.entries_1.u_core.w_readreceipt;
    release u_i.inner_l2cache.mmioBridge.entries_1.u_core.allowRetry;
    release u_i.inner_l2cache.mmioBridge.entries_1.u_core.req_opcode;
    release u_i.inner_l2cache.mmioBridge.entries_1.u_core.req_size;
    release u_i.inner_l2cache.mmioBridge.entries_1.u_core.req_source;
    release u_i.inner_l2cache.mmioBridge.entries_1.u_core.req_address;
    release u_i.inner_l2cache.mmioBridge.entries_1.u_core.req_user_memBackType_MM;
    release u_i.inner_l2cache.mmioBridge.entries_1.u_core.req_user_memPageType_NC;
    release u_i.inner_l2cache.mmioBridge.entries_1.u_core.req_mask;
    release u_i.inner_l2cache.mmioBridge.entries_1.u_core.req_data;
    release u_i.inner_l2cache.mmioBridge.entries_1.u_core.req_corrupt;
    release u_i.inner_l2cache.mmioBridge.entries_1.u_core.rdata;
    release u_i.inner_l2cache.mmioBridge.entries_1.u_core.srcID;
    release u_i.inner_l2cache.mmioBridge.entries_1.u_core.dbID;
    release u_i.inner_l2cache.mmioBridge.entries_1.u_core.pCrdType;
    release u_i.inner_l2cache.mmioBridge.entries_1.u_core.denied;
    release u_i.inner_l2cache.mmioBridge.entries_1.u_core.corrupt;
    release u_i.inner_l2cache.mmioBridge.entries_1.u_core.traceTag;
    release u_i.inner_l2cache.mmioBridge.entries_2.u_core.s_txreq;
    release u_i.inner_l2cache.mmioBridge.entries_2.u_core.s_ncbwrdata;
    release u_i.inner_l2cache.mmioBridge.entries_2.u_core.s_resp;
    release u_i.inner_l2cache.mmioBridge.entries_2.u_core.w_comp;
    release u_i.inner_l2cache.mmioBridge.entries_2.u_core.w_dbidresp;
    release u_i.inner_l2cache.mmioBridge.entries_2.u_core.w_compdata;
    release u_i.inner_l2cache.mmioBridge.entries_2.u_core.w_pcrdgrant;
    release u_i.inner_l2cache.mmioBridge.entries_2.u_core.w_readreceipt;
    release u_i.inner_l2cache.mmioBridge.entries_2.u_core.allowRetry;
    release u_i.inner_l2cache.mmioBridge.entries_2.u_core.req_opcode;
    release u_i.inner_l2cache.mmioBridge.entries_2.u_core.req_size;
    release u_i.inner_l2cache.mmioBridge.entries_2.u_core.req_source;
    release u_i.inner_l2cache.mmioBridge.entries_2.u_core.req_address;
    release u_i.inner_l2cache.mmioBridge.entries_2.u_core.req_user_memBackType_MM;
    release u_i.inner_l2cache.mmioBridge.entries_2.u_core.req_user_memPageType_NC;
    release u_i.inner_l2cache.mmioBridge.entries_2.u_core.req_mask;
    release u_i.inner_l2cache.mmioBridge.entries_2.u_core.req_data;
    release u_i.inner_l2cache.mmioBridge.entries_2.u_core.req_corrupt;
    release u_i.inner_l2cache.mmioBridge.entries_2.u_core.rdata;
    release u_i.inner_l2cache.mmioBridge.entries_2.u_core.srcID;
    release u_i.inner_l2cache.mmioBridge.entries_2.u_core.dbID;
    release u_i.inner_l2cache.mmioBridge.entries_2.u_core.pCrdType;
    release u_i.inner_l2cache.mmioBridge.entries_2.u_core.denied;
    release u_i.inner_l2cache.mmioBridge.entries_2.u_core.corrupt;
    release u_i.inner_l2cache.mmioBridge.entries_2.u_core.traceTag;
    release u_i.inner_l2cache.mmioBridge.entries_3.u_core.s_txreq;
    release u_i.inner_l2cache.mmioBridge.entries_3.u_core.s_ncbwrdata;
    release u_i.inner_l2cache.mmioBridge.entries_3.u_core.s_resp;
    release u_i.inner_l2cache.mmioBridge.entries_3.u_core.w_comp;
    release u_i.inner_l2cache.mmioBridge.entries_3.u_core.w_dbidresp;
    release u_i.inner_l2cache.mmioBridge.entries_3.u_core.w_compdata;
    release u_i.inner_l2cache.mmioBridge.entries_3.u_core.w_pcrdgrant;
    release u_i.inner_l2cache.mmioBridge.entries_3.u_core.w_readreceipt;
    release u_i.inner_l2cache.mmioBridge.entries_3.u_core.allowRetry;
    release u_i.inner_l2cache.mmioBridge.entries_3.u_core.req_opcode;
    release u_i.inner_l2cache.mmioBridge.entries_3.u_core.req_size;
    release u_i.inner_l2cache.mmioBridge.entries_3.u_core.req_source;
    release u_i.inner_l2cache.mmioBridge.entries_3.u_core.req_address;
    release u_i.inner_l2cache.mmioBridge.entries_3.u_core.req_user_memBackType_MM;
    release u_i.inner_l2cache.mmioBridge.entries_3.u_core.req_user_memPageType_NC;
    release u_i.inner_l2cache.mmioBridge.entries_3.u_core.req_mask;
    release u_i.inner_l2cache.mmioBridge.entries_3.u_core.req_data;
    release u_i.inner_l2cache.mmioBridge.entries_3.u_core.req_corrupt;
    release u_i.inner_l2cache.mmioBridge.entries_3.u_core.rdata;
    release u_i.inner_l2cache.mmioBridge.entries_3.u_core.srcID;
    release u_i.inner_l2cache.mmioBridge.entries_3.u_core.dbID;
    release u_i.inner_l2cache.mmioBridge.entries_3.u_core.pCrdType;
    release u_i.inner_l2cache.mmioBridge.entries_3.u_core.denied;
    release u_i.inner_l2cache.mmioBridge.entries_3.u_core.corrupt;
    release u_i.inner_l2cache.mmioBridge.entries_3.u_core.traceTag;
    release u_i.inner_l2cache.mmioBridge.entries_4.u_core.s_txreq;
    release u_i.inner_l2cache.mmioBridge.entries_4.u_core.s_ncbwrdata;
    release u_i.inner_l2cache.mmioBridge.entries_4.u_core.s_resp;
    release u_i.inner_l2cache.mmioBridge.entries_4.u_core.w_comp;
    release u_i.inner_l2cache.mmioBridge.entries_4.u_core.w_dbidresp;
    release u_i.inner_l2cache.mmioBridge.entries_4.u_core.w_compdata;
    release u_i.inner_l2cache.mmioBridge.entries_4.u_core.w_pcrdgrant;
    release u_i.inner_l2cache.mmioBridge.entries_4.u_core.w_readreceipt;
    release u_i.inner_l2cache.mmioBridge.entries_4.u_core.allowRetry;
    release u_i.inner_l2cache.mmioBridge.entries_4.u_core.req_opcode;
    release u_i.inner_l2cache.mmioBridge.entries_4.u_core.req_size;
    release u_i.inner_l2cache.mmioBridge.entries_4.u_core.req_source;
    release u_i.inner_l2cache.mmioBridge.entries_4.u_core.req_address;
    release u_i.inner_l2cache.mmioBridge.entries_4.u_core.req_user_memBackType_MM;
    release u_i.inner_l2cache.mmioBridge.entries_4.u_core.req_user_memPageType_NC;
    release u_i.inner_l2cache.mmioBridge.entries_4.u_core.req_mask;
    release u_i.inner_l2cache.mmioBridge.entries_4.u_core.req_data;
    release u_i.inner_l2cache.mmioBridge.entries_4.u_core.req_corrupt;
    release u_i.inner_l2cache.mmioBridge.entries_4.u_core.rdata;
    release u_i.inner_l2cache.mmioBridge.entries_4.u_core.srcID;
    release u_i.inner_l2cache.mmioBridge.entries_4.u_core.dbID;
    release u_i.inner_l2cache.mmioBridge.entries_4.u_core.pCrdType;
    release u_i.inner_l2cache.mmioBridge.entries_4.u_core.denied;
    release u_i.inner_l2cache.mmioBridge.entries_4.u_core.corrupt;
    release u_i.inner_l2cache.mmioBridge.entries_4.u_core.traceTag;
    release u_i.inner_l2cache.mmioBridge.entries_5.u_core.s_txreq;
    release u_i.inner_l2cache.mmioBridge.entries_5.u_core.s_ncbwrdata;
    release u_i.inner_l2cache.mmioBridge.entries_5.u_core.s_resp;
    release u_i.inner_l2cache.mmioBridge.entries_5.u_core.w_comp;
    release u_i.inner_l2cache.mmioBridge.entries_5.u_core.w_dbidresp;
    release u_i.inner_l2cache.mmioBridge.entries_5.u_core.w_compdata;
    release u_i.inner_l2cache.mmioBridge.entries_5.u_core.w_pcrdgrant;
    release u_i.inner_l2cache.mmioBridge.entries_5.u_core.w_readreceipt;
    release u_i.inner_l2cache.mmioBridge.entries_5.u_core.allowRetry;
    release u_i.inner_l2cache.mmioBridge.entries_5.u_core.req_opcode;
    release u_i.inner_l2cache.mmioBridge.entries_5.u_core.req_size;
    release u_i.inner_l2cache.mmioBridge.entries_5.u_core.req_source;
    release u_i.inner_l2cache.mmioBridge.entries_5.u_core.req_address;
    release u_i.inner_l2cache.mmioBridge.entries_5.u_core.req_user_memBackType_MM;
    release u_i.inner_l2cache.mmioBridge.entries_5.u_core.req_user_memPageType_NC;
    release u_i.inner_l2cache.mmioBridge.entries_5.u_core.req_mask;
    release u_i.inner_l2cache.mmioBridge.entries_5.u_core.req_data;
    release u_i.inner_l2cache.mmioBridge.entries_5.u_core.req_corrupt;
    release u_i.inner_l2cache.mmioBridge.entries_5.u_core.rdata;
    release u_i.inner_l2cache.mmioBridge.entries_5.u_core.srcID;
    release u_i.inner_l2cache.mmioBridge.entries_5.u_core.dbID;
    release u_i.inner_l2cache.mmioBridge.entries_5.u_core.pCrdType;
    release u_i.inner_l2cache.mmioBridge.entries_5.u_core.denied;
    release u_i.inner_l2cache.mmioBridge.entries_5.u_core.corrupt;
    release u_i.inner_l2cache.mmioBridge.entries_5.u_core.traceTag;
    release u_i.inner_l2cache.mmioBridge.entries_6.u_core.s_txreq;
    release u_i.inner_l2cache.mmioBridge.entries_6.u_core.s_ncbwrdata;
    release u_i.inner_l2cache.mmioBridge.entries_6.u_core.s_resp;
    release u_i.inner_l2cache.mmioBridge.entries_6.u_core.w_comp;
    release u_i.inner_l2cache.mmioBridge.entries_6.u_core.w_dbidresp;
    release u_i.inner_l2cache.mmioBridge.entries_6.u_core.w_compdata;
    release u_i.inner_l2cache.mmioBridge.entries_6.u_core.w_pcrdgrant;
    release u_i.inner_l2cache.mmioBridge.entries_6.u_core.w_readreceipt;
    release u_i.inner_l2cache.mmioBridge.entries_6.u_core.allowRetry;
    release u_i.inner_l2cache.mmioBridge.entries_6.u_core.req_opcode;
    release u_i.inner_l2cache.mmioBridge.entries_6.u_core.req_size;
    release u_i.inner_l2cache.mmioBridge.entries_6.u_core.req_source;
    release u_i.inner_l2cache.mmioBridge.entries_6.u_core.req_address;
    release u_i.inner_l2cache.mmioBridge.entries_6.u_core.req_user_memBackType_MM;
    release u_i.inner_l2cache.mmioBridge.entries_6.u_core.req_user_memPageType_NC;
    release u_i.inner_l2cache.mmioBridge.entries_6.u_core.req_mask;
    release u_i.inner_l2cache.mmioBridge.entries_6.u_core.req_data;
    release u_i.inner_l2cache.mmioBridge.entries_6.u_core.req_corrupt;
    release u_i.inner_l2cache.mmioBridge.entries_6.u_core.rdata;
    release u_i.inner_l2cache.mmioBridge.entries_6.u_core.srcID;
    release u_i.inner_l2cache.mmioBridge.entries_6.u_core.dbID;
    release u_i.inner_l2cache.mmioBridge.entries_6.u_core.pCrdType;
    release u_i.inner_l2cache.mmioBridge.entries_6.u_core.denied;
    release u_i.inner_l2cache.mmioBridge.entries_6.u_core.corrupt;
    release u_i.inner_l2cache.mmioBridge.entries_6.u_core.traceTag;
    release u_i.inner_l2cache.mmioBridge.entries_7.u_core.s_txreq;
    release u_i.inner_l2cache.mmioBridge.entries_7.u_core.s_ncbwrdata;
    release u_i.inner_l2cache.mmioBridge.entries_7.u_core.s_resp;
    release u_i.inner_l2cache.mmioBridge.entries_7.u_core.w_comp;
    release u_i.inner_l2cache.mmioBridge.entries_7.u_core.w_dbidresp;
    release u_i.inner_l2cache.mmioBridge.entries_7.u_core.w_compdata;
    release u_i.inner_l2cache.mmioBridge.entries_7.u_core.w_pcrdgrant;
    release u_i.inner_l2cache.mmioBridge.entries_7.u_core.w_readreceipt;
    release u_i.inner_l2cache.mmioBridge.entries_7.u_core.allowRetry;
    release u_i.inner_l2cache.mmioBridge.entries_7.u_core.req_opcode;
    release u_i.inner_l2cache.mmioBridge.entries_7.u_core.req_size;
    release u_i.inner_l2cache.mmioBridge.entries_7.u_core.req_source;
    release u_i.inner_l2cache.mmioBridge.entries_7.u_core.req_address;
    release u_i.inner_l2cache.mmioBridge.entries_7.u_core.req_user_memBackType_MM;
    release u_i.inner_l2cache.mmioBridge.entries_7.u_core.req_user_memPageType_NC;
    release u_i.inner_l2cache.mmioBridge.entries_7.u_core.req_mask;
    release u_i.inner_l2cache.mmioBridge.entries_7.u_core.req_data;
    release u_i.inner_l2cache.mmioBridge.entries_7.u_core.req_corrupt;
    release u_i.inner_l2cache.mmioBridge.entries_7.u_core.rdata;
    release u_i.inner_l2cache.mmioBridge.entries_7.u_core.srcID;
    release u_i.inner_l2cache.mmioBridge.entries_7.u_core.dbID;
    release u_i.inner_l2cache.mmioBridge.entries_7.u_core.pCrdType;
    release u_i.inner_l2cache.mmioBridge.entries_7.u_core.denied;
    release u_i.inner_l2cache.mmioBridge.entries_7.u_core.corrupt;
    release u_i.inner_l2cache.mmioBridge.entries_7.u_core.traceTag;
    release u_i.inner_l2cache.mmioBridge.entries_8.u_core.s_txreq;
    release u_i.inner_l2cache.mmioBridge.entries_8.u_core.s_ncbwrdata;
    release u_i.inner_l2cache.mmioBridge.entries_8.u_core.s_resp;
    release u_i.inner_l2cache.mmioBridge.entries_8.u_core.w_comp;
    release u_i.inner_l2cache.mmioBridge.entries_8.u_core.w_dbidresp;
    release u_i.inner_l2cache.mmioBridge.entries_8.u_core.w_compdata;
    release u_i.inner_l2cache.mmioBridge.entries_8.u_core.w_pcrdgrant;
    release u_i.inner_l2cache.mmioBridge.entries_8.u_core.w_readreceipt;
    release u_i.inner_l2cache.mmioBridge.entries_8.u_core.allowRetry;
    release u_i.inner_l2cache.mmioBridge.entries_8.u_core.req_opcode;
    release u_i.inner_l2cache.mmioBridge.entries_8.u_core.req_size;
    release u_i.inner_l2cache.mmioBridge.entries_8.u_core.req_source;
    release u_i.inner_l2cache.mmioBridge.entries_8.u_core.req_address;
    release u_i.inner_l2cache.mmioBridge.entries_8.u_core.req_user_memBackType_MM;
    release u_i.inner_l2cache.mmioBridge.entries_8.u_core.req_user_memPageType_NC;
    release u_i.inner_l2cache.mmioBridge.entries_8.u_core.req_mask;
    release u_i.inner_l2cache.mmioBridge.entries_8.u_core.req_data;
    release u_i.inner_l2cache.mmioBridge.entries_8.u_core.req_corrupt;
    release u_i.inner_l2cache.mmioBridge.entries_8.u_core.rdata;
    release u_i.inner_l2cache.mmioBridge.entries_8.u_core.srcID;
    release u_i.inner_l2cache.mmioBridge.entries_8.u_core.dbID;
    release u_i.inner_l2cache.mmioBridge.entries_8.u_core.pCrdType;
    release u_i.inner_l2cache.mmioBridge.entries_8.u_core.denied;
    release u_i.inner_l2cache.mmioBridge.entries_8.u_core.corrupt;
    release u_i.inner_l2cache.mmioBridge.entries_8.u_core.traceTag;
    release u_i.inner_l2cache.mmioBridge.entries_9.u_core.s_txreq;
    release u_i.inner_l2cache.mmioBridge.entries_9.u_core.s_ncbwrdata;
    release u_i.inner_l2cache.mmioBridge.entries_9.u_core.s_resp;
    release u_i.inner_l2cache.mmioBridge.entries_9.u_core.w_comp;
    release u_i.inner_l2cache.mmioBridge.entries_9.u_core.w_dbidresp;
    release u_i.inner_l2cache.mmioBridge.entries_9.u_core.w_compdata;
    release u_i.inner_l2cache.mmioBridge.entries_9.u_core.w_pcrdgrant;
    release u_i.inner_l2cache.mmioBridge.entries_9.u_core.w_readreceipt;
    release u_i.inner_l2cache.mmioBridge.entries_9.u_core.allowRetry;
    release u_i.inner_l2cache.mmioBridge.entries_9.u_core.req_opcode;
    release u_i.inner_l2cache.mmioBridge.entries_9.u_core.req_size;
    release u_i.inner_l2cache.mmioBridge.entries_9.u_core.req_source;
    release u_i.inner_l2cache.mmioBridge.entries_9.u_core.req_address;
    release u_i.inner_l2cache.mmioBridge.entries_9.u_core.req_user_memBackType_MM;
    release u_i.inner_l2cache.mmioBridge.entries_9.u_core.req_user_memPageType_NC;
    release u_i.inner_l2cache.mmioBridge.entries_9.u_core.req_mask;
    release u_i.inner_l2cache.mmioBridge.entries_9.u_core.req_data;
    release u_i.inner_l2cache.mmioBridge.entries_9.u_core.req_corrupt;
    release u_i.inner_l2cache.mmioBridge.entries_9.u_core.rdata;
    release u_i.inner_l2cache.mmioBridge.entries_9.u_core.srcID;
    release u_i.inner_l2cache.mmioBridge.entries_9.u_core.dbID;
    release u_i.inner_l2cache.mmioBridge.entries_9.u_core.pCrdType;
    release u_i.inner_l2cache.mmioBridge.entries_9.u_core.denied;
    release u_i.inner_l2cache.mmioBridge.entries_9.u_core.corrupt;
    release u_i.inner_l2cache.mmioBridge.entries_9.u_core.traceTag;
    release u_i.inner_l2cache.mmioBridge.entries_10.u_core.s_txreq;
    release u_i.inner_l2cache.mmioBridge.entries_10.u_core.s_ncbwrdata;
    release u_i.inner_l2cache.mmioBridge.entries_10.u_core.s_resp;
    release u_i.inner_l2cache.mmioBridge.entries_10.u_core.w_comp;
    release u_i.inner_l2cache.mmioBridge.entries_10.u_core.w_dbidresp;
    release u_i.inner_l2cache.mmioBridge.entries_10.u_core.w_compdata;
    release u_i.inner_l2cache.mmioBridge.entries_10.u_core.w_pcrdgrant;
    release u_i.inner_l2cache.mmioBridge.entries_10.u_core.w_readreceipt;
    release u_i.inner_l2cache.mmioBridge.entries_10.u_core.allowRetry;
    release u_i.inner_l2cache.mmioBridge.entries_10.u_core.req_opcode;
    release u_i.inner_l2cache.mmioBridge.entries_10.u_core.req_size;
    release u_i.inner_l2cache.mmioBridge.entries_10.u_core.req_source;
    release u_i.inner_l2cache.mmioBridge.entries_10.u_core.req_address;
    release u_i.inner_l2cache.mmioBridge.entries_10.u_core.req_user_memBackType_MM;
    release u_i.inner_l2cache.mmioBridge.entries_10.u_core.req_user_memPageType_NC;
    release u_i.inner_l2cache.mmioBridge.entries_10.u_core.req_mask;
    release u_i.inner_l2cache.mmioBridge.entries_10.u_core.req_data;
    release u_i.inner_l2cache.mmioBridge.entries_10.u_core.req_corrupt;
    release u_i.inner_l2cache.mmioBridge.entries_10.u_core.rdata;
    release u_i.inner_l2cache.mmioBridge.entries_10.u_core.srcID;
    release u_i.inner_l2cache.mmioBridge.entries_10.u_core.dbID;
    release u_i.inner_l2cache.mmioBridge.entries_10.u_core.pCrdType;
    release u_i.inner_l2cache.mmioBridge.entries_10.u_core.denied;
    release u_i.inner_l2cache.mmioBridge.entries_10.u_core.corrupt;
    release u_i.inner_l2cache.mmioBridge.entries_10.u_core.traceTag;
    release u_i.inner_l2cache.mmioBridge.entries_11.u_core.s_txreq;
    release u_i.inner_l2cache.mmioBridge.entries_11.u_core.s_ncbwrdata;
    release u_i.inner_l2cache.mmioBridge.entries_11.u_core.s_resp;
    release u_i.inner_l2cache.mmioBridge.entries_11.u_core.w_comp;
    release u_i.inner_l2cache.mmioBridge.entries_11.u_core.w_dbidresp;
    release u_i.inner_l2cache.mmioBridge.entries_11.u_core.w_compdata;
    release u_i.inner_l2cache.mmioBridge.entries_11.u_core.w_pcrdgrant;
    release u_i.inner_l2cache.mmioBridge.entries_11.u_core.w_readreceipt;
    release u_i.inner_l2cache.mmioBridge.entries_11.u_core.allowRetry;
    release u_i.inner_l2cache.mmioBridge.entries_11.u_core.req_opcode;
    release u_i.inner_l2cache.mmioBridge.entries_11.u_core.req_size;
    release u_i.inner_l2cache.mmioBridge.entries_11.u_core.req_source;
    release u_i.inner_l2cache.mmioBridge.entries_11.u_core.req_address;
    release u_i.inner_l2cache.mmioBridge.entries_11.u_core.req_user_memBackType_MM;
    release u_i.inner_l2cache.mmioBridge.entries_11.u_core.req_user_memPageType_NC;
    release u_i.inner_l2cache.mmioBridge.entries_11.u_core.req_mask;
    release u_i.inner_l2cache.mmioBridge.entries_11.u_core.req_data;
    release u_i.inner_l2cache.mmioBridge.entries_11.u_core.req_corrupt;
    release u_i.inner_l2cache.mmioBridge.entries_11.u_core.rdata;
    release u_i.inner_l2cache.mmioBridge.entries_11.u_core.srcID;
    release u_i.inner_l2cache.mmioBridge.entries_11.u_core.dbID;
    release u_i.inner_l2cache.mmioBridge.entries_11.u_core.pCrdType;
    release u_i.inner_l2cache.mmioBridge.entries_11.u_core.denied;
    release u_i.inner_l2cache.mmioBridge.entries_11.u_core.corrupt;
    release u_i.inner_l2cache.mmioBridge.entries_11.u_core.traceTag;
    release u_i.inner_l2cache.mmioBridge.entries_12.u_core.s_txreq;
    release u_i.inner_l2cache.mmioBridge.entries_12.u_core.s_ncbwrdata;
    release u_i.inner_l2cache.mmioBridge.entries_12.u_core.s_resp;
    release u_i.inner_l2cache.mmioBridge.entries_12.u_core.w_comp;
    release u_i.inner_l2cache.mmioBridge.entries_12.u_core.w_dbidresp;
    release u_i.inner_l2cache.mmioBridge.entries_12.u_core.w_compdata;
    release u_i.inner_l2cache.mmioBridge.entries_12.u_core.w_pcrdgrant;
    release u_i.inner_l2cache.mmioBridge.entries_12.u_core.w_readreceipt;
    release u_i.inner_l2cache.mmioBridge.entries_12.u_core.allowRetry;
    release u_i.inner_l2cache.mmioBridge.entries_12.u_core.req_opcode;
    release u_i.inner_l2cache.mmioBridge.entries_12.u_core.req_size;
    release u_i.inner_l2cache.mmioBridge.entries_12.u_core.req_source;
    release u_i.inner_l2cache.mmioBridge.entries_12.u_core.req_address;
    release u_i.inner_l2cache.mmioBridge.entries_12.u_core.req_user_memBackType_MM;
    release u_i.inner_l2cache.mmioBridge.entries_12.u_core.req_user_memPageType_NC;
    release u_i.inner_l2cache.mmioBridge.entries_12.u_core.req_mask;
    release u_i.inner_l2cache.mmioBridge.entries_12.u_core.req_data;
    release u_i.inner_l2cache.mmioBridge.entries_12.u_core.req_corrupt;
    release u_i.inner_l2cache.mmioBridge.entries_12.u_core.rdata;
    release u_i.inner_l2cache.mmioBridge.entries_12.u_core.srcID;
    release u_i.inner_l2cache.mmioBridge.entries_12.u_core.dbID;
    release u_i.inner_l2cache.mmioBridge.entries_12.u_core.pCrdType;
    release u_i.inner_l2cache.mmioBridge.entries_12.u_core.denied;
    release u_i.inner_l2cache.mmioBridge.entries_12.u_core.corrupt;
    release u_i.inner_l2cache.mmioBridge.entries_12.u_core.traceTag;
    release u_i.inner_l2cache.mmioBridge.entries_13.u_core.s_txreq;
    release u_i.inner_l2cache.mmioBridge.entries_13.u_core.s_ncbwrdata;
    release u_i.inner_l2cache.mmioBridge.entries_13.u_core.s_resp;
    release u_i.inner_l2cache.mmioBridge.entries_13.u_core.w_comp;
    release u_i.inner_l2cache.mmioBridge.entries_13.u_core.w_dbidresp;
    release u_i.inner_l2cache.mmioBridge.entries_13.u_core.w_compdata;
    release u_i.inner_l2cache.mmioBridge.entries_13.u_core.w_pcrdgrant;
    release u_i.inner_l2cache.mmioBridge.entries_13.u_core.w_readreceipt;
    release u_i.inner_l2cache.mmioBridge.entries_13.u_core.allowRetry;
    release u_i.inner_l2cache.mmioBridge.entries_13.u_core.req_opcode;
    release u_i.inner_l2cache.mmioBridge.entries_13.u_core.req_size;
    release u_i.inner_l2cache.mmioBridge.entries_13.u_core.req_source;
    release u_i.inner_l2cache.mmioBridge.entries_13.u_core.req_address;
    release u_i.inner_l2cache.mmioBridge.entries_13.u_core.req_user_memBackType_MM;
    release u_i.inner_l2cache.mmioBridge.entries_13.u_core.req_user_memPageType_NC;
    release u_i.inner_l2cache.mmioBridge.entries_13.u_core.req_mask;
    release u_i.inner_l2cache.mmioBridge.entries_13.u_core.req_data;
    release u_i.inner_l2cache.mmioBridge.entries_13.u_core.req_corrupt;
    release u_i.inner_l2cache.mmioBridge.entries_13.u_core.rdata;
    release u_i.inner_l2cache.mmioBridge.entries_13.u_core.srcID;
    release u_i.inner_l2cache.mmioBridge.entries_13.u_core.dbID;
    release u_i.inner_l2cache.mmioBridge.entries_13.u_core.pCrdType;
    release u_i.inner_l2cache.mmioBridge.entries_13.u_core.denied;
    release u_i.inner_l2cache.mmioBridge.entries_13.u_core.corrupt;
    release u_i.inner_l2cache.mmioBridge.entries_13.u_core.traceTag;
    release u_i.inner_l2cache.mmioBridge.entries_14.u_core.s_txreq;
    release u_i.inner_l2cache.mmioBridge.entries_14.u_core.s_ncbwrdata;
    release u_i.inner_l2cache.mmioBridge.entries_14.u_core.s_resp;
    release u_i.inner_l2cache.mmioBridge.entries_14.u_core.w_comp;
    release u_i.inner_l2cache.mmioBridge.entries_14.u_core.w_dbidresp;
    release u_i.inner_l2cache.mmioBridge.entries_14.u_core.w_compdata;
    release u_i.inner_l2cache.mmioBridge.entries_14.u_core.w_pcrdgrant;
    release u_i.inner_l2cache.mmioBridge.entries_14.u_core.w_readreceipt;
    release u_i.inner_l2cache.mmioBridge.entries_14.u_core.allowRetry;
    release u_i.inner_l2cache.mmioBridge.entries_14.u_core.req_opcode;
    release u_i.inner_l2cache.mmioBridge.entries_14.u_core.req_size;
    release u_i.inner_l2cache.mmioBridge.entries_14.u_core.req_source;
    release u_i.inner_l2cache.mmioBridge.entries_14.u_core.req_address;
    release u_i.inner_l2cache.mmioBridge.entries_14.u_core.req_user_memBackType_MM;
    release u_i.inner_l2cache.mmioBridge.entries_14.u_core.req_user_memPageType_NC;
    release u_i.inner_l2cache.mmioBridge.entries_14.u_core.req_mask;
    release u_i.inner_l2cache.mmioBridge.entries_14.u_core.req_data;
    release u_i.inner_l2cache.mmioBridge.entries_14.u_core.req_corrupt;
    release u_i.inner_l2cache.mmioBridge.entries_14.u_core.rdata;
    release u_i.inner_l2cache.mmioBridge.entries_14.u_core.srcID;
    release u_i.inner_l2cache.mmioBridge.entries_14.u_core.dbID;
    release u_i.inner_l2cache.mmioBridge.entries_14.u_core.pCrdType;
    release u_i.inner_l2cache.mmioBridge.entries_14.u_core.denied;
    release u_i.inner_l2cache.mmioBridge.entries_14.u_core.corrupt;
    release u_i.inner_l2cache.mmioBridge.entries_14.u_core.traceTag;
    release u_i.inner_l2cache.mmioBridge.entries_15.u_core.s_txreq;
    release u_i.inner_l2cache.mmioBridge.entries_15.u_core.s_ncbwrdata;
    release u_i.inner_l2cache.mmioBridge.entries_15.u_core.s_resp;
    release u_i.inner_l2cache.mmioBridge.entries_15.u_core.w_comp;
    release u_i.inner_l2cache.mmioBridge.entries_15.u_core.w_dbidresp;
    release u_i.inner_l2cache.mmioBridge.entries_15.u_core.w_compdata;
    release u_i.inner_l2cache.mmioBridge.entries_15.u_core.w_pcrdgrant;
    release u_i.inner_l2cache.mmioBridge.entries_15.u_core.w_readreceipt;
    release u_i.inner_l2cache.mmioBridge.entries_15.u_core.allowRetry;
    release u_i.inner_l2cache.mmioBridge.entries_15.u_core.req_opcode;
    release u_i.inner_l2cache.mmioBridge.entries_15.u_core.req_size;
    release u_i.inner_l2cache.mmioBridge.entries_15.u_core.req_source;
    release u_i.inner_l2cache.mmioBridge.entries_15.u_core.req_address;
    release u_i.inner_l2cache.mmioBridge.entries_15.u_core.req_user_memBackType_MM;
    release u_i.inner_l2cache.mmioBridge.entries_15.u_core.req_user_memPageType_NC;
    release u_i.inner_l2cache.mmioBridge.entries_15.u_core.req_mask;
    release u_i.inner_l2cache.mmioBridge.entries_15.u_core.req_data;
    release u_i.inner_l2cache.mmioBridge.entries_15.u_core.req_corrupt;
    release u_i.inner_l2cache.mmioBridge.entries_15.u_core.rdata;
    release u_i.inner_l2cache.mmioBridge.entries_15.u_core.srcID;
    release u_i.inner_l2cache.mmioBridge.entries_15.u_core.dbID;
    release u_i.inner_l2cache.mmioBridge.entries_15.u_core.pCrdType;
    release u_i.inner_l2cache.mmioBridge.entries_15.u_core.denied;
    release u_i.inner_l2cache.mmioBridge.entries_15.u_core.corrupt;
    release u_i.inner_l2cache.mmioBridge.entries_15.u_core.traceTag;
    release u_i.inner_l2cache.mbistPl.u_core.g_node_return.pipelineDataOutReg;
    release u_i.u_core.msiToCore_bits;
    release u_i.u_core.traceOut_trapCause;
    release u_i.u_core.traceOut_trapTval;
    release u_i.u_core.traceOut_priv;
    release u_i.inner_io_clintTime_toCore_pipMod.u_core.g_chain.data_q[0];
    release u_i.u_core.traceOut_ilastsize[0];
    release u_i.u_core.traceOut_iaddr[0];
    release u_i.u_core.traceOut_ilastsize[1];
    release u_i.u_core.traceOut_iaddr[1];
    release u_i.u_core.traceOut_ilastsize[2];
    release u_i.u_core.traceOut_iaddr[2];
    release u_i.inner_xbar.u_core.g_out_a[0].u_arb.beats_left;
    release u_i.inner_xbar.u_core.g_out_a[0].u_arb.mask;
    release u_i.inner_xbar.u_core.g_out_a[0].u_arb.state;
    release u_i.inner_xbar.u_core.g_out_a[1].u_arb.beats_left;
    release u_i.inner_xbar.u_core.g_out_a[1].u_arb.mask;
    release u_i.inner_xbar.u_core.g_out_a[1].u_arb.state;
    release u_i.inner_xbar.u_core.g_out_a[2].u_arb.beats_left;
    release u_i.inner_xbar.u_core.g_out_a[2].u_arb.mask;
    release u_i.inner_xbar.u_core.g_out_a[2].u_arb.state;
    release u_i.inner_xbar.u_core.g_out_a[3].u_arb.beats_left;
    release u_i.inner_xbar.u_core.g_out_a[3].u_arb.mask;
    release u_i.inner_xbar.u_core.g_out_a[3].u_arb.state;
    release u_i.inner_xbar.u_core.u_arb_b.beats_left;
    release u_i.inner_xbar.u_core.u_arb_b.mask;
    release u_i.inner_xbar.u_core.u_arb_b.state;
    release u_i.inner_xbar.u_core.g_in_d[0].u_arb.beats_left;
    release u_i.inner_xbar.u_core.g_in_d[0].u_arb.mask;
    release u_i.inner_xbar.u_core.g_in_d[0].u_arb.state;
    release u_i.inner_xbar.u_core.g_in_d[1].u_arb.beats_left;
    release u_i.inner_xbar.u_core.g_in_d[1].u_arb.mask;
    release u_i.inner_xbar.u_core.g_in_d[1].u_arb.state;
    release u_i.inner_xbar.u_core.g_in_d[2].u_arb.beats_left;
    release u_i.inner_xbar.u_core.g_in_d[2].u_arb.mask;
    release u_i.inner_xbar.u_core.g_in_d[2].u_arb.state;
    release u_i.inner_xbar_1.u_core.g_out_a[0].u_arb.beats_left;
    release u_i.inner_xbar_1.u_core.g_out_a[0].u_arb.mask;
    release u_i.inner_xbar_1.u_core.g_out_a[0].u_arb.state;
    release u_i.inner_xbar_1.u_core.g_out_a[1].u_arb.beats_left;
    release u_i.inner_xbar_1.u_core.g_out_a[1].u_arb.mask;
    release u_i.inner_xbar_1.u_core.g_out_a[1].u_arb.state;
    release u_i.inner_xbar_1.u_core.g_out_a[2].u_arb.beats_left;
    release u_i.inner_xbar_1.u_core.g_out_a[2].u_arb.mask;
    release u_i.inner_xbar_1.u_core.g_out_a[2].u_arb.state;
    release u_i.inner_xbar_1.u_core.g_in_d[0].u_arb.beats_left;
    release u_i.inner_xbar_1.u_core.g_in_d[0].u_arb.mask;
    release u_i.inner_xbar_1.u_core.g_in_d[0].u_arb.state;
    release u_i.inner_xbar_1.u_core.g_in_d[1].u_arb.beats_left;
    release u_i.inner_xbar_1.u_core.g_in_d[1].u_arb.mask;
    release u_i.inner_xbar_1.u_core.g_in_d[1].u_arb.state;
  endtask

  initial begin
    if (!$value$plusargs("ncycles=%d", NCYCLES)) NCYCLES = 200000;
    foreach (cov[k]) cov[k] = 0;
    drive(); reset = 1'b1;
    #1;
    sync_init();          // 未复位寄存器两侧同初值（见文件头）
    repeat (8) @(posedge clock);
    #1; drive(); reset = 1'b0;
    repeat (NCYCLES) begin
      @(posedge clock); #1; cyc++;
      update_arm(); check(); sample(); drive();
    end
    begin
      int zero = 0;
      foreach (cov[k]) begin
        $display("COVER %-24s %0d", COV_NAME[k], cov[k]);
        if (cov[k] == 0 && !COV_INFO[k]) zero++;
      end
      $display("ARMED=%b", armed);
      if ((armed & 4'b0111) != 4'b0111) zero++;   // 只要求标了必需的 arm 组
      $display("checks=%0d errors=%0d cover_zero=%0d", checks, errors, zero);
      if (errors == 0 && zero == 0) $display("TEST PASSED");
      else $display("TEST FAILED");
    end
    $finish;
  end
endmodule
