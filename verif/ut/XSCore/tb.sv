// 自动生成：scripts/gen_l2slice_ut.py —— 勿手改（命令行见同目录 Makefile 的 gentb）
// 目标：XSCore
// golden <T> 与派生 <T>_xs 双例化，同激励逐拍 4 态比全部输出；覆盖闸见文件尾。
`timescale 1ns/1ps
module tb;
  int unsigned NCYCLES = 200000;
  bit clock = 0;
  always #5 clock = ~clock;
  logic reset;
  longint checks = 0, errors = 0;
  longint cyc = 0;   // 复位释放后的拍号（--narrow 表达式可用它做分相激励）
  function automatic logic [4095:0] rnd(input int w);
    logic [4095:0] v;
    v = '0;
    for (int i = 0; i < w; i += 32) v[i+:32] = $urandom;
    return v;
  endfunction

  // ======================= XSCore =======================
  logic XSCore__auto_memBlock_inner_buffers_out_a_ready;
  logic XSCore__auto_memBlock_inner_buffers_out_d_valid;
  logic [3:0] XSCore__auto_memBlock_inner_buffers_out_d_bits_opcode;
  logic [1:0] XSCore__auto_memBlock_inner_buffers_out_d_bits_param;
  logic [1:0] XSCore__auto_memBlock_inner_buffers_out_d_bits_size;
  logic [3:0] XSCore__auto_memBlock_inner_buffers_out_d_bits_source;
  logic XSCore__auto_memBlock_inner_buffers_out_d_bits_sink;
  logic XSCore__auto_memBlock_inner_buffers_out_d_bits_denied;
  logic [63:0] XSCore__auto_memBlock_inner_buffers_out_d_bits_data;
  logic XSCore__auto_memBlock_inner_buffers_out_d_bits_corrupt;
  logic XSCore__auto_memBlock_inner_frontendBridge_instr_uncache_out_a_ready;
  logic XSCore__auto_memBlock_inner_frontendBridge_instr_uncache_out_d_valid;
  logic [3:0] XSCore__auto_memBlock_inner_frontendBridge_instr_uncache_out_d_bits_opcode;
  logic [1:0] XSCore__auto_memBlock_inner_frontendBridge_instr_uncache_out_d_bits_param;
  logic [1:0] XSCore__auto_memBlock_inner_frontendBridge_instr_uncache_out_d_bits_size;
  logic XSCore__auto_memBlock_inner_frontendBridge_instr_uncache_out_d_bits_source;
  logic XSCore__auto_memBlock_inner_frontendBridge_instr_uncache_out_d_bits_sink;
  logic XSCore__auto_memBlock_inner_frontendBridge_instr_uncache_out_d_bits_denied;
  logic [63:0] XSCore__auto_memBlock_inner_frontendBridge_instr_uncache_out_d_bits_data;
  logic XSCore__auto_memBlock_inner_frontendBridge_instr_uncache_out_d_bits_corrupt;
  logic XSCore__auto_memBlock_inner_frontendBridge_icachectrl_in_a_valid;
  logic [3:0] XSCore__auto_memBlock_inner_frontendBridge_icachectrl_in_a_bits_opcode;
  logic [2:0] XSCore__auto_memBlock_inner_frontendBridge_icachectrl_in_a_bits_param;
  logic [1:0] XSCore__auto_memBlock_inner_frontendBridge_icachectrl_in_a_bits_size;
  logic [4:0] XSCore__auto_memBlock_inner_frontendBridge_icachectrl_in_a_bits_source;
  logic [29:0] XSCore__auto_memBlock_inner_frontendBridge_icachectrl_in_a_bits_address;
  logic [7:0] XSCore__auto_memBlock_inner_frontendBridge_icachectrl_in_a_bits_mask;
  logic [63:0] XSCore__auto_memBlock_inner_frontendBridge_icachectrl_in_a_bits_data;
  logic XSCore__auto_memBlock_inner_frontendBridge_icachectrl_in_a_bits_corrupt;
  logic XSCore__auto_memBlock_inner_frontendBridge_icachectrl_in_d_ready;
  logic XSCore__auto_memBlock_inner_frontendBridge_icache_out_a_ready;
  logic XSCore__auto_memBlock_inner_frontendBridge_icache_out_d_valid;
  logic [3:0] XSCore__auto_memBlock_inner_frontendBridge_icache_out_d_bits_opcode;
  logic [1:0] XSCore__auto_memBlock_inner_frontendBridge_icache_out_d_bits_param;
  logic [2:0] XSCore__auto_memBlock_inner_frontendBridge_icache_out_d_bits_size;
  logic [3:0] XSCore__auto_memBlock_inner_frontendBridge_icache_out_d_bits_source;
  logic [9:0] XSCore__auto_memBlock_inner_frontendBridge_icache_out_d_bits_sink;
  logic XSCore__auto_memBlock_inner_frontendBridge_icache_out_d_bits_denied;
  logic [255:0] XSCore__auto_memBlock_inner_frontendBridge_icache_out_d_bits_data;
  logic XSCore__auto_memBlock_inner_frontendBridge_icache_out_d_bits_corrupt;
  logic XSCore__auto_memBlock_inner_ptw_to_l2_buffer_out_a_ready;
  logic XSCore__auto_memBlock_inner_ptw_to_l2_buffer_out_d_valid;
  logic [3:0] XSCore__auto_memBlock_inner_ptw_to_l2_buffer_out_d_bits_opcode;
  logic [1:0] XSCore__auto_memBlock_inner_ptw_to_l2_buffer_out_d_bits_param;
  logic [2:0] XSCore__auto_memBlock_inner_ptw_to_l2_buffer_out_d_bits_size;
  logic [3:0] XSCore__auto_memBlock_inner_ptw_to_l2_buffer_out_d_bits_source;
  logic [9:0] XSCore__auto_memBlock_inner_ptw_to_l2_buffer_out_d_bits_sink;
  logic XSCore__auto_memBlock_inner_ptw_to_l2_buffer_out_d_bits_denied;
  logic [255:0] XSCore__auto_memBlock_inner_ptw_to_l2_buffer_out_d_bits_data;
  logic XSCore__auto_memBlock_inner_ptw_to_l2_buffer_out_d_bits_corrupt;
  logic XSCore__auto_memBlock_inner_beu_local_int_sink_in_0;
  logic XSCore__auto_memBlock_inner_nmi_int_sink_in_0;
  logic XSCore__auto_memBlock_inner_nmi_int_sink_in_1;
  logic XSCore__auto_memBlock_inner_plic_int_sink_in_1_0;
  logic XSCore__auto_memBlock_inner_plic_int_sink_in_0_0;
  logic XSCore__auto_memBlock_inner_debug_int_sink_in_0;
  logic XSCore__auto_memBlock_inner_clint_int_sink_in_0;
  logic XSCore__auto_memBlock_inner_clint_int_sink_in_1;
  logic XSCore__auto_memBlock_inner_dcache_client_out_a_ready;
  logic XSCore__auto_memBlock_inner_dcache_client_out_b_valid;
  logic [2:0] XSCore__auto_memBlock_inner_dcache_client_out_b_bits_opcode;
  logic [1:0] XSCore__auto_memBlock_inner_dcache_client_out_b_bits_param;
  logic [2:0] XSCore__auto_memBlock_inner_dcache_client_out_b_bits_size;
  logic [5:0] XSCore__auto_memBlock_inner_dcache_client_out_b_bits_source;
  logic [47:0] XSCore__auto_memBlock_inner_dcache_client_out_b_bits_address;
  logic [31:0] XSCore__auto_memBlock_inner_dcache_client_out_b_bits_mask;
  logic [255:0] XSCore__auto_memBlock_inner_dcache_client_out_b_bits_data;
  logic XSCore__auto_memBlock_inner_dcache_client_out_b_bits_corrupt;
  logic XSCore__auto_memBlock_inner_dcache_client_out_c_ready;
  logic XSCore__auto_memBlock_inner_dcache_client_out_d_valid;
  logic [3:0] XSCore__auto_memBlock_inner_dcache_client_out_d_bits_opcode;
  logic [1:0] XSCore__auto_memBlock_inner_dcache_client_out_d_bits_param;
  logic [2:0] XSCore__auto_memBlock_inner_dcache_client_out_d_bits_size;
  logic [5:0] XSCore__auto_memBlock_inner_dcache_client_out_d_bits_source;
  logic [9:0] XSCore__auto_memBlock_inner_dcache_client_out_d_bits_sink;
  logic XSCore__auto_memBlock_inner_dcache_client_out_d_bits_denied;
  logic XSCore__auto_memBlock_inner_dcache_client_out_d_bits_echo_isKeyword;
  logic [255:0] XSCore__auto_memBlock_inner_dcache_client_out_d_bits_data;
  logic XSCore__auto_memBlock_inner_dcache_client_out_d_bits_corrupt;
  logic XSCore__auto_memBlock_inner_dcache_client_out_e_ready;
  logic [5:0] XSCore__io_hartId;
  logic XSCore__io_msiInfo_valid;
  logic [11:0] XSCore__io_msiInfo_bits;
  logic XSCore__io_clintTime_valid;
  logic [63:0] XSCore__io_clintTime_bits;
  logic [47:0] XSCore__io_reset_vector;
  logic XSCore__io_l2_flush_done;
  logic XSCore__io_traceCoreInterface_fromEncoder_enable;
  logic XSCore__io_traceCoreInterface_fromEncoder_stall;
  logic [5:0] XSCore__io_perfEvents_1_value;
  logic [5:0] XSCore__io_perfEvents_2_value;
  logic [5:0] XSCore__io_perfEvents_3_value;
  logic [5:0] XSCore__io_perfEvents_4_value;
  logic [5:0] XSCore__io_perfEvents_5_value;
  logic [5:0] XSCore__io_perfEvents_6_value;
  logic [5:0] XSCore__io_perfEvents_7_value;
  logic [5:0] XSCore__io_perfEvents_8_value;
  logic [5:0] XSCore__io_perfEvents_9_value;
  logic [5:0] XSCore__io_perfEvents_10_value;
  logic [5:0] XSCore__io_perfEvents_11_value;
  logic [5:0] XSCore__io_perfEvents_12_value;
  logic [5:0] XSCore__io_perfEvents_13_value;
  logic [5:0] XSCore__io_perfEvents_14_value;
  logic [5:0] XSCore__io_perfEvents_15_value;
  logic [5:0] XSCore__io_perfEvents_16_value;
  logic [5:0] XSCore__io_perfEvents_17_value;
  logic [5:0] XSCore__io_perfEvents_18_value;
  logic [5:0] XSCore__io_perfEvents_19_value;
  logic [5:0] XSCore__io_perfEvents_20_value;
  logic [5:0] XSCore__io_perfEvents_21_value;
  logic [5:0] XSCore__io_perfEvents_22_value;
  logic [5:0] XSCore__io_perfEvents_23_value;
  logic [5:0] XSCore__io_perfEvents_24_value;
  logic [5:0] XSCore__io_perfEvents_25_value;
  logic [5:0] XSCore__io_perfEvents_26_value;
  logic [5:0] XSCore__io_perfEvents_27_value;
  logic [5:0] XSCore__io_perfEvents_28_value;
  logic [5:0] XSCore__io_perfEvents_29_value;
  logic [5:0] XSCore__io_perfEvents_30_value;
  logic [5:0] XSCore__io_perfEvents_31_value;
  logic [5:0] XSCore__io_perfEvents_32_value;
  logic [5:0] XSCore__io_perfEvents_33_value;
  logic [5:0] XSCore__io_perfEvents_34_value;
  logic [5:0] XSCore__io_perfEvents_35_value;
  logic [5:0] XSCore__io_perfEvents_36_value;
  logic [5:0] XSCore__io_perfEvents_37_value;
  logic [5:0] XSCore__io_perfEvents_38_value;
  logic [5:0] XSCore__io_perfEvents_39_value;
  logic [5:0] XSCore__io_perfEvents_40_value;
  logic [5:0] XSCore__io_perfEvents_41_value;
  logic [5:0] XSCore__io_perfEvents_42_value;
  logic [5:0] XSCore__io_perfEvents_43_value;
  logic [5:0] XSCore__io_perfEvents_44_value;
  logic [5:0] XSCore__io_perfEvents_45_value;
  logic [5:0] XSCore__io_perfEvents_46_value;
  logic [5:0] XSCore__io_perfEvents_47_value;
  logic [5:0] XSCore__io_perfEvents_48_value;
  logic [5:0] XSCore__io_perfEvents_49_value;
  logic [5:0] XSCore__io_perfEvents_50_value;
  logic [5:0] XSCore__io_perfEvents_51_value;
  logic [5:0] XSCore__io_perfEvents_52_value;
  logic [5:0] XSCore__io_perfEvents_53_value;
  logic [5:0] XSCore__io_perfEvents_54_value;
  logic [5:0] XSCore__io_perfEvents_55_value;
  logic [5:0] XSCore__io_perfEvents_56_value;
  logic [5:0] XSCore__io_perfEvents_57_value;
  logic [5:0] XSCore__io_perfEvents_58_value;
  logic [5:0] XSCore__io_perfEvents_59_value;
  logic [5:0] XSCore__io_perfEvents_60_value;
  logic [5:0] XSCore__io_perfEvents_61_value;
  logic [5:0] XSCore__io_perfEvents_62_value;
  logic [5:0] XSCore__io_perfEvents_63_value;
  logic [5:0] XSCore__io_perfEvents_64_value;
  logic [5:0] XSCore__io_perfEvents_65_value;
  logic [5:0] XSCore__io_perfEvents_66_value;
  logic [5:0] XSCore__io_perfEvents_67_value;
  logic [5:0] XSCore__io_perfEvents_68_value;
  logic XSCore__io_l2_hint_valid;
  logic [3:0] XSCore__io_l2_hint_bits_sourceId;
  logic XSCore__io_l2_hint_bits_isKeyword;
  logic XSCore__io_l2_tlb_req_req_valid;
  logic [49:0] XSCore__io_l2_tlb_req_req_bits_vaddr;
  logic [2:0] XSCore__io_l2_tlb_req_req_bits_cmd;
  logic XSCore__io_l2_tlb_req_req_bits_kill;
  logic XSCore__io_l2_tlb_req_req_bits_isPrefetch;
  logic XSCore__io_l2_tlb_req_req_bits_no_translate;
  logic XSCore__io_debugTopDown_l2MissMatch;
  logic XSCore__io_debugTopDown_l3MissMatch;
  logic XSCore__io_topDownInfo_l2Miss;
  logic XSCore__io_topDownInfo_l3Miss;
  logic XSCore__io_dft_ram_hold;
  logic XSCore__io_dft_ram_bypass;
  logic XSCore__io_dft_ram_bp_clken;
  logic XSCore__io_dft_ram_aux_clk;
  logic XSCore__io_dft_ram_aux_ckbp;
  logic XSCore__io_dft_ram_mcp_hold;
  logic XSCore__io_dft_cgen;
  wire  g_XSCore__auto_memBlock_inner_buffers_out_a_valid;
  wire  i_XSCore__auto_memBlock_inner_buffers_out_a_valid;
  logic p_XSCore__auto_memBlock_inner_buffers_out_a_valid;
  bit   t_XSCore__auto_memBlock_inner_buffers_out_a_valid;
  wire  [3:0] g_XSCore__auto_memBlock_inner_buffers_out_a_bits_opcode;
  wire  [3:0] i_XSCore__auto_memBlock_inner_buffers_out_a_bits_opcode;
  logic [3:0] p_XSCore__auto_memBlock_inner_buffers_out_a_bits_opcode;
  bit   t_XSCore__auto_memBlock_inner_buffers_out_a_bits_opcode;
  wire  [2:0] g_XSCore__auto_memBlock_inner_buffers_out_a_bits_param;
  wire  [2:0] i_XSCore__auto_memBlock_inner_buffers_out_a_bits_param;
  logic [2:0] p_XSCore__auto_memBlock_inner_buffers_out_a_bits_param;
  bit   t_XSCore__auto_memBlock_inner_buffers_out_a_bits_param;
  wire  [1:0] g_XSCore__auto_memBlock_inner_buffers_out_a_bits_size;
  wire  [1:0] i_XSCore__auto_memBlock_inner_buffers_out_a_bits_size;
  logic [1:0] p_XSCore__auto_memBlock_inner_buffers_out_a_bits_size;
  bit   t_XSCore__auto_memBlock_inner_buffers_out_a_bits_size;
  wire  [3:0] g_XSCore__auto_memBlock_inner_buffers_out_a_bits_source;
  wire  [3:0] i_XSCore__auto_memBlock_inner_buffers_out_a_bits_source;
  logic [3:0] p_XSCore__auto_memBlock_inner_buffers_out_a_bits_source;
  bit   t_XSCore__auto_memBlock_inner_buffers_out_a_bits_source;
  wire  [47:0] g_XSCore__auto_memBlock_inner_buffers_out_a_bits_address;
  wire  [47:0] i_XSCore__auto_memBlock_inner_buffers_out_a_bits_address;
  logic [47:0] p_XSCore__auto_memBlock_inner_buffers_out_a_bits_address;
  bit   t_XSCore__auto_memBlock_inner_buffers_out_a_bits_address;
  wire  g_XSCore__auto_memBlock_inner_buffers_out_a_bits_user_memBackType_MM;
  wire  i_XSCore__auto_memBlock_inner_buffers_out_a_bits_user_memBackType_MM;
  logic p_XSCore__auto_memBlock_inner_buffers_out_a_bits_user_memBackType_MM;
  bit   t_XSCore__auto_memBlock_inner_buffers_out_a_bits_user_memBackType_MM;
  wire  g_XSCore__auto_memBlock_inner_buffers_out_a_bits_user_memPageType_NC;
  wire  i_XSCore__auto_memBlock_inner_buffers_out_a_bits_user_memPageType_NC;
  logic p_XSCore__auto_memBlock_inner_buffers_out_a_bits_user_memPageType_NC;
  bit   t_XSCore__auto_memBlock_inner_buffers_out_a_bits_user_memPageType_NC;
  wire  [7:0] g_XSCore__auto_memBlock_inner_buffers_out_a_bits_mask;
  wire  [7:0] i_XSCore__auto_memBlock_inner_buffers_out_a_bits_mask;
  logic [7:0] p_XSCore__auto_memBlock_inner_buffers_out_a_bits_mask;
  bit   t_XSCore__auto_memBlock_inner_buffers_out_a_bits_mask;
  wire  [63:0] g_XSCore__auto_memBlock_inner_buffers_out_a_bits_data;
  wire  [63:0] i_XSCore__auto_memBlock_inner_buffers_out_a_bits_data;
  logic [63:0] p_XSCore__auto_memBlock_inner_buffers_out_a_bits_data;
  bit   t_XSCore__auto_memBlock_inner_buffers_out_a_bits_data;
  wire  g_XSCore__auto_memBlock_inner_buffers_out_a_bits_corrupt;
  wire  i_XSCore__auto_memBlock_inner_buffers_out_a_bits_corrupt;
  logic p_XSCore__auto_memBlock_inner_buffers_out_a_bits_corrupt;
  bit   t_XSCore__auto_memBlock_inner_buffers_out_a_bits_corrupt;
  wire  g_XSCore__auto_memBlock_inner_buffers_out_d_ready;
  wire  i_XSCore__auto_memBlock_inner_buffers_out_d_ready;
  logic p_XSCore__auto_memBlock_inner_buffers_out_d_ready;
  bit   t_XSCore__auto_memBlock_inner_buffers_out_d_ready;
  wire  g_XSCore__auto_memBlock_inner_frontendBridge_instr_uncache_out_a_valid;
  wire  i_XSCore__auto_memBlock_inner_frontendBridge_instr_uncache_out_a_valid;
  logic p_XSCore__auto_memBlock_inner_frontendBridge_instr_uncache_out_a_valid;
  bit   t_XSCore__auto_memBlock_inner_frontendBridge_instr_uncache_out_a_valid;
  wire  [2:0] g_XSCore__auto_memBlock_inner_frontendBridge_instr_uncache_out_a_bits_param;
  wire  [2:0] i_XSCore__auto_memBlock_inner_frontendBridge_instr_uncache_out_a_bits_param;
  logic [2:0] p_XSCore__auto_memBlock_inner_frontendBridge_instr_uncache_out_a_bits_param;
  bit   t_XSCore__auto_memBlock_inner_frontendBridge_instr_uncache_out_a_bits_param;
  wire  [47:0] g_XSCore__auto_memBlock_inner_frontendBridge_instr_uncache_out_a_bits_address;
  wire  [47:0] i_XSCore__auto_memBlock_inner_frontendBridge_instr_uncache_out_a_bits_address;
  logic [47:0] p_XSCore__auto_memBlock_inner_frontendBridge_instr_uncache_out_a_bits_address;
  bit   t_XSCore__auto_memBlock_inner_frontendBridge_instr_uncache_out_a_bits_address;
  wire  g_XSCore__auto_memBlock_inner_frontendBridge_instr_uncache_out_a_bits_user_memPageType_NC;
  wire  i_XSCore__auto_memBlock_inner_frontendBridge_instr_uncache_out_a_bits_user_memPageType_NC;
  logic p_XSCore__auto_memBlock_inner_frontendBridge_instr_uncache_out_a_bits_user_memPageType_NC;
  bit   t_XSCore__auto_memBlock_inner_frontendBridge_instr_uncache_out_a_bits_user_memPageType_NC;
  wire  g_XSCore__auto_memBlock_inner_frontendBridge_instr_uncache_out_a_bits_user_memBackType_MM;
  wire  i_XSCore__auto_memBlock_inner_frontendBridge_instr_uncache_out_a_bits_user_memBackType_MM;
  logic p_XSCore__auto_memBlock_inner_frontendBridge_instr_uncache_out_a_bits_user_memBackType_MM;
  bit   t_XSCore__auto_memBlock_inner_frontendBridge_instr_uncache_out_a_bits_user_memBackType_MM;
  wire  g_XSCore__auto_memBlock_inner_frontendBridge_instr_uncache_out_a_bits_corrupt;
  wire  i_XSCore__auto_memBlock_inner_frontendBridge_instr_uncache_out_a_bits_corrupt;
  logic p_XSCore__auto_memBlock_inner_frontendBridge_instr_uncache_out_a_bits_corrupt;
  bit   t_XSCore__auto_memBlock_inner_frontendBridge_instr_uncache_out_a_bits_corrupt;
  wire  g_XSCore__auto_memBlock_inner_frontendBridge_instr_uncache_out_d_ready;
  wire  i_XSCore__auto_memBlock_inner_frontendBridge_instr_uncache_out_d_ready;
  logic p_XSCore__auto_memBlock_inner_frontendBridge_instr_uncache_out_d_ready;
  bit   t_XSCore__auto_memBlock_inner_frontendBridge_instr_uncache_out_d_ready;
  wire  g_XSCore__auto_memBlock_inner_frontendBridge_icachectrl_in_a_ready;
  wire  i_XSCore__auto_memBlock_inner_frontendBridge_icachectrl_in_a_ready;
  logic p_XSCore__auto_memBlock_inner_frontendBridge_icachectrl_in_a_ready;
  bit   t_XSCore__auto_memBlock_inner_frontendBridge_icachectrl_in_a_ready;
  wire  g_XSCore__auto_memBlock_inner_frontendBridge_icachectrl_in_d_valid;
  wire  i_XSCore__auto_memBlock_inner_frontendBridge_icachectrl_in_d_valid;
  logic p_XSCore__auto_memBlock_inner_frontendBridge_icachectrl_in_d_valid;
  bit   t_XSCore__auto_memBlock_inner_frontendBridge_icachectrl_in_d_valid;
  wire  [3:0] g_XSCore__auto_memBlock_inner_frontendBridge_icachectrl_in_d_bits_opcode;
  wire  [3:0] i_XSCore__auto_memBlock_inner_frontendBridge_icachectrl_in_d_bits_opcode;
  logic [3:0] p_XSCore__auto_memBlock_inner_frontendBridge_icachectrl_in_d_bits_opcode;
  bit   t_XSCore__auto_memBlock_inner_frontendBridge_icachectrl_in_d_bits_opcode;
  wire  [1:0] g_XSCore__auto_memBlock_inner_frontendBridge_icachectrl_in_d_bits_param;
  wire  [1:0] i_XSCore__auto_memBlock_inner_frontendBridge_icachectrl_in_d_bits_param;
  logic [1:0] p_XSCore__auto_memBlock_inner_frontendBridge_icachectrl_in_d_bits_param;
  bit   t_XSCore__auto_memBlock_inner_frontendBridge_icachectrl_in_d_bits_param;
  wire  [1:0] g_XSCore__auto_memBlock_inner_frontendBridge_icachectrl_in_d_bits_size;
  wire  [1:0] i_XSCore__auto_memBlock_inner_frontendBridge_icachectrl_in_d_bits_size;
  logic [1:0] p_XSCore__auto_memBlock_inner_frontendBridge_icachectrl_in_d_bits_size;
  bit   t_XSCore__auto_memBlock_inner_frontendBridge_icachectrl_in_d_bits_size;
  wire  [4:0] g_XSCore__auto_memBlock_inner_frontendBridge_icachectrl_in_d_bits_source;
  wire  [4:0] i_XSCore__auto_memBlock_inner_frontendBridge_icachectrl_in_d_bits_source;
  logic [4:0] p_XSCore__auto_memBlock_inner_frontendBridge_icachectrl_in_d_bits_source;
  bit   t_XSCore__auto_memBlock_inner_frontendBridge_icachectrl_in_d_bits_source;
  wire  g_XSCore__auto_memBlock_inner_frontendBridge_icachectrl_in_d_bits_sink;
  wire  i_XSCore__auto_memBlock_inner_frontendBridge_icachectrl_in_d_bits_sink;
  logic p_XSCore__auto_memBlock_inner_frontendBridge_icachectrl_in_d_bits_sink;
  bit   t_XSCore__auto_memBlock_inner_frontendBridge_icachectrl_in_d_bits_sink;
  wire  g_XSCore__auto_memBlock_inner_frontendBridge_icachectrl_in_d_bits_denied;
  wire  i_XSCore__auto_memBlock_inner_frontendBridge_icachectrl_in_d_bits_denied;
  logic p_XSCore__auto_memBlock_inner_frontendBridge_icachectrl_in_d_bits_denied;
  bit   t_XSCore__auto_memBlock_inner_frontendBridge_icachectrl_in_d_bits_denied;
  wire  [63:0] g_XSCore__auto_memBlock_inner_frontendBridge_icachectrl_in_d_bits_data;
  wire  [63:0] i_XSCore__auto_memBlock_inner_frontendBridge_icachectrl_in_d_bits_data;
  logic [63:0] p_XSCore__auto_memBlock_inner_frontendBridge_icachectrl_in_d_bits_data;
  bit   t_XSCore__auto_memBlock_inner_frontendBridge_icachectrl_in_d_bits_data;
  wire  g_XSCore__auto_memBlock_inner_frontendBridge_icachectrl_in_d_bits_corrupt;
  wire  i_XSCore__auto_memBlock_inner_frontendBridge_icachectrl_in_d_bits_corrupt;
  logic p_XSCore__auto_memBlock_inner_frontendBridge_icachectrl_in_d_bits_corrupt;
  bit   t_XSCore__auto_memBlock_inner_frontendBridge_icachectrl_in_d_bits_corrupt;
  wire  g_XSCore__auto_memBlock_inner_frontendBridge_icache_out_a_valid;
  wire  i_XSCore__auto_memBlock_inner_frontendBridge_icache_out_a_valid;
  logic p_XSCore__auto_memBlock_inner_frontendBridge_icache_out_a_valid;
  bit   t_XSCore__auto_memBlock_inner_frontendBridge_icache_out_a_valid;
  wire  [3:0] g_XSCore__auto_memBlock_inner_frontendBridge_icache_out_a_bits_opcode;
  wire  [3:0] i_XSCore__auto_memBlock_inner_frontendBridge_icache_out_a_bits_opcode;
  logic [3:0] p_XSCore__auto_memBlock_inner_frontendBridge_icache_out_a_bits_opcode;
  bit   t_XSCore__auto_memBlock_inner_frontendBridge_icache_out_a_bits_opcode;
  wire  [2:0] g_XSCore__auto_memBlock_inner_frontendBridge_icache_out_a_bits_param;
  wire  [2:0] i_XSCore__auto_memBlock_inner_frontendBridge_icache_out_a_bits_param;
  logic [2:0] p_XSCore__auto_memBlock_inner_frontendBridge_icache_out_a_bits_param;
  bit   t_XSCore__auto_memBlock_inner_frontendBridge_icache_out_a_bits_param;
  wire  [2:0] g_XSCore__auto_memBlock_inner_frontendBridge_icache_out_a_bits_size;
  wire  [2:0] i_XSCore__auto_memBlock_inner_frontendBridge_icache_out_a_bits_size;
  logic [2:0] p_XSCore__auto_memBlock_inner_frontendBridge_icache_out_a_bits_size;
  bit   t_XSCore__auto_memBlock_inner_frontendBridge_icache_out_a_bits_size;
  wire  [3:0] g_XSCore__auto_memBlock_inner_frontendBridge_icache_out_a_bits_source;
  wire  [3:0] i_XSCore__auto_memBlock_inner_frontendBridge_icache_out_a_bits_source;
  logic [3:0] p_XSCore__auto_memBlock_inner_frontendBridge_icache_out_a_bits_source;
  bit   t_XSCore__auto_memBlock_inner_frontendBridge_icache_out_a_bits_source;
  wire  [47:0] g_XSCore__auto_memBlock_inner_frontendBridge_icache_out_a_bits_address;
  wire  [47:0] i_XSCore__auto_memBlock_inner_frontendBridge_icache_out_a_bits_address;
  logic [47:0] p_XSCore__auto_memBlock_inner_frontendBridge_icache_out_a_bits_address;
  bit   t_XSCore__auto_memBlock_inner_frontendBridge_icache_out_a_bits_address;
  wire  [1:0] g_XSCore__auto_memBlock_inner_frontendBridge_icache_out_a_bits_user_alias;
  wire  [1:0] i_XSCore__auto_memBlock_inner_frontendBridge_icache_out_a_bits_user_alias;
  logic [1:0] p_XSCore__auto_memBlock_inner_frontendBridge_icache_out_a_bits_user_alias;
  bit   t_XSCore__auto_memBlock_inner_frontendBridge_icache_out_a_bits_user_alias;
  wire  [4:0] g_XSCore__auto_memBlock_inner_frontendBridge_icache_out_a_bits_user_reqSource;
  wire  [4:0] i_XSCore__auto_memBlock_inner_frontendBridge_icache_out_a_bits_user_reqSource;
  logic [4:0] p_XSCore__auto_memBlock_inner_frontendBridge_icache_out_a_bits_user_reqSource;
  bit   t_XSCore__auto_memBlock_inner_frontendBridge_icache_out_a_bits_user_reqSource;
  wire  g_XSCore__auto_memBlock_inner_frontendBridge_icache_out_a_bits_user_needHint;
  wire  i_XSCore__auto_memBlock_inner_frontendBridge_icache_out_a_bits_user_needHint;
  logic p_XSCore__auto_memBlock_inner_frontendBridge_icache_out_a_bits_user_needHint;
  bit   t_XSCore__auto_memBlock_inner_frontendBridge_icache_out_a_bits_user_needHint;
  wire  [31:0] g_XSCore__auto_memBlock_inner_frontendBridge_icache_out_a_bits_mask;
  wire  [31:0] i_XSCore__auto_memBlock_inner_frontendBridge_icache_out_a_bits_mask;
  logic [31:0] p_XSCore__auto_memBlock_inner_frontendBridge_icache_out_a_bits_mask;
  bit   t_XSCore__auto_memBlock_inner_frontendBridge_icache_out_a_bits_mask;
  wire  [255:0] g_XSCore__auto_memBlock_inner_frontendBridge_icache_out_a_bits_data;
  wire  [255:0] i_XSCore__auto_memBlock_inner_frontendBridge_icache_out_a_bits_data;
  logic [255:0] p_XSCore__auto_memBlock_inner_frontendBridge_icache_out_a_bits_data;
  bit   t_XSCore__auto_memBlock_inner_frontendBridge_icache_out_a_bits_data;
  wire  g_XSCore__auto_memBlock_inner_frontendBridge_icache_out_a_bits_corrupt;
  wire  i_XSCore__auto_memBlock_inner_frontendBridge_icache_out_a_bits_corrupt;
  logic p_XSCore__auto_memBlock_inner_frontendBridge_icache_out_a_bits_corrupt;
  bit   t_XSCore__auto_memBlock_inner_frontendBridge_icache_out_a_bits_corrupt;
  wire  g_XSCore__auto_memBlock_inner_frontendBridge_icache_out_d_ready;
  wire  i_XSCore__auto_memBlock_inner_frontendBridge_icache_out_d_ready;
  logic p_XSCore__auto_memBlock_inner_frontendBridge_icache_out_d_ready;
  bit   t_XSCore__auto_memBlock_inner_frontendBridge_icache_out_d_ready;
  wire  g_XSCore__auto_memBlock_inner_ptw_to_l2_buffer_out_a_valid;
  wire  i_XSCore__auto_memBlock_inner_ptw_to_l2_buffer_out_a_valid;
  logic p_XSCore__auto_memBlock_inner_ptw_to_l2_buffer_out_a_valid;
  bit   t_XSCore__auto_memBlock_inner_ptw_to_l2_buffer_out_a_valid;
  wire  [3:0] g_XSCore__auto_memBlock_inner_ptw_to_l2_buffer_out_a_bits_opcode;
  wire  [3:0] i_XSCore__auto_memBlock_inner_ptw_to_l2_buffer_out_a_bits_opcode;
  logic [3:0] p_XSCore__auto_memBlock_inner_ptw_to_l2_buffer_out_a_bits_opcode;
  bit   t_XSCore__auto_memBlock_inner_ptw_to_l2_buffer_out_a_bits_opcode;
  wire  [2:0] g_XSCore__auto_memBlock_inner_ptw_to_l2_buffer_out_a_bits_param;
  wire  [2:0] i_XSCore__auto_memBlock_inner_ptw_to_l2_buffer_out_a_bits_param;
  logic [2:0] p_XSCore__auto_memBlock_inner_ptw_to_l2_buffer_out_a_bits_param;
  bit   t_XSCore__auto_memBlock_inner_ptw_to_l2_buffer_out_a_bits_param;
  wire  [2:0] g_XSCore__auto_memBlock_inner_ptw_to_l2_buffer_out_a_bits_size;
  wire  [2:0] i_XSCore__auto_memBlock_inner_ptw_to_l2_buffer_out_a_bits_size;
  logic [2:0] p_XSCore__auto_memBlock_inner_ptw_to_l2_buffer_out_a_bits_size;
  bit   t_XSCore__auto_memBlock_inner_ptw_to_l2_buffer_out_a_bits_size;
  wire  [3:0] g_XSCore__auto_memBlock_inner_ptw_to_l2_buffer_out_a_bits_source;
  wire  [3:0] i_XSCore__auto_memBlock_inner_ptw_to_l2_buffer_out_a_bits_source;
  logic [3:0] p_XSCore__auto_memBlock_inner_ptw_to_l2_buffer_out_a_bits_source;
  bit   t_XSCore__auto_memBlock_inner_ptw_to_l2_buffer_out_a_bits_source;
  wire  [47:0] g_XSCore__auto_memBlock_inner_ptw_to_l2_buffer_out_a_bits_address;
  wire  [47:0] i_XSCore__auto_memBlock_inner_ptw_to_l2_buffer_out_a_bits_address;
  logic [47:0] p_XSCore__auto_memBlock_inner_ptw_to_l2_buffer_out_a_bits_address;
  bit   t_XSCore__auto_memBlock_inner_ptw_to_l2_buffer_out_a_bits_address;
  wire  [4:0] g_XSCore__auto_memBlock_inner_ptw_to_l2_buffer_out_a_bits_user_reqSource;
  wire  [4:0] i_XSCore__auto_memBlock_inner_ptw_to_l2_buffer_out_a_bits_user_reqSource;
  logic [4:0] p_XSCore__auto_memBlock_inner_ptw_to_l2_buffer_out_a_bits_user_reqSource;
  bit   t_XSCore__auto_memBlock_inner_ptw_to_l2_buffer_out_a_bits_user_reqSource;
  wire  [31:0] g_XSCore__auto_memBlock_inner_ptw_to_l2_buffer_out_a_bits_mask;
  wire  [31:0] i_XSCore__auto_memBlock_inner_ptw_to_l2_buffer_out_a_bits_mask;
  logic [31:0] p_XSCore__auto_memBlock_inner_ptw_to_l2_buffer_out_a_bits_mask;
  bit   t_XSCore__auto_memBlock_inner_ptw_to_l2_buffer_out_a_bits_mask;
  wire  [255:0] g_XSCore__auto_memBlock_inner_ptw_to_l2_buffer_out_a_bits_data;
  wire  [255:0] i_XSCore__auto_memBlock_inner_ptw_to_l2_buffer_out_a_bits_data;
  logic [255:0] p_XSCore__auto_memBlock_inner_ptw_to_l2_buffer_out_a_bits_data;
  bit   t_XSCore__auto_memBlock_inner_ptw_to_l2_buffer_out_a_bits_data;
  wire  g_XSCore__auto_memBlock_inner_ptw_to_l2_buffer_out_a_bits_corrupt;
  wire  i_XSCore__auto_memBlock_inner_ptw_to_l2_buffer_out_a_bits_corrupt;
  logic p_XSCore__auto_memBlock_inner_ptw_to_l2_buffer_out_a_bits_corrupt;
  bit   t_XSCore__auto_memBlock_inner_ptw_to_l2_buffer_out_a_bits_corrupt;
  wire  g_XSCore__auto_memBlock_inner_ptw_to_l2_buffer_out_d_ready;
  wire  i_XSCore__auto_memBlock_inner_ptw_to_l2_buffer_out_d_ready;
  logic p_XSCore__auto_memBlock_inner_ptw_to_l2_buffer_out_d_ready;
  bit   t_XSCore__auto_memBlock_inner_ptw_to_l2_buffer_out_d_ready;
  wire  [63:0] g_XSCore__auto_memBlock_inner_l2_pf_sender_out_addr;
  wire  [63:0] i_XSCore__auto_memBlock_inner_l2_pf_sender_out_addr;
  logic [63:0] p_XSCore__auto_memBlock_inner_l2_pf_sender_out_addr;
  bit   t_XSCore__auto_memBlock_inner_l2_pf_sender_out_addr;
  wire  [4:0] g_XSCore__auto_memBlock_inner_l2_pf_sender_out_pf_source;
  wire  [4:0] i_XSCore__auto_memBlock_inner_l2_pf_sender_out_pf_source;
  logic [4:0] p_XSCore__auto_memBlock_inner_l2_pf_sender_out_pf_source;
  bit   t_XSCore__auto_memBlock_inner_l2_pf_sender_out_pf_source;
  wire  g_XSCore__auto_memBlock_inner_l2_pf_sender_out_addr_valid;
  wire  i_XSCore__auto_memBlock_inner_l2_pf_sender_out_addr_valid;
  logic p_XSCore__auto_memBlock_inner_l2_pf_sender_out_addr_valid;
  bit   t_XSCore__auto_memBlock_inner_l2_pf_sender_out_addr_valid;
  wire  g_XSCore__auto_memBlock_inner_dcache_client_out_a_valid;
  wire  i_XSCore__auto_memBlock_inner_dcache_client_out_a_valid;
  logic p_XSCore__auto_memBlock_inner_dcache_client_out_a_valid;
  bit   t_XSCore__auto_memBlock_inner_dcache_client_out_a_valid;
  wire  [3:0] g_XSCore__auto_memBlock_inner_dcache_client_out_a_bits_opcode;
  wire  [3:0] i_XSCore__auto_memBlock_inner_dcache_client_out_a_bits_opcode;
  logic [3:0] p_XSCore__auto_memBlock_inner_dcache_client_out_a_bits_opcode;
  bit   t_XSCore__auto_memBlock_inner_dcache_client_out_a_bits_opcode;
  wire  [2:0] g_XSCore__auto_memBlock_inner_dcache_client_out_a_bits_param;
  wire  [2:0] i_XSCore__auto_memBlock_inner_dcache_client_out_a_bits_param;
  logic [2:0] p_XSCore__auto_memBlock_inner_dcache_client_out_a_bits_param;
  bit   t_XSCore__auto_memBlock_inner_dcache_client_out_a_bits_param;
  wire  [2:0] g_XSCore__auto_memBlock_inner_dcache_client_out_a_bits_size;
  wire  [2:0] i_XSCore__auto_memBlock_inner_dcache_client_out_a_bits_size;
  logic [2:0] p_XSCore__auto_memBlock_inner_dcache_client_out_a_bits_size;
  bit   t_XSCore__auto_memBlock_inner_dcache_client_out_a_bits_size;
  wire  [5:0] g_XSCore__auto_memBlock_inner_dcache_client_out_a_bits_source;
  wire  [5:0] i_XSCore__auto_memBlock_inner_dcache_client_out_a_bits_source;
  logic [5:0] p_XSCore__auto_memBlock_inner_dcache_client_out_a_bits_source;
  bit   t_XSCore__auto_memBlock_inner_dcache_client_out_a_bits_source;
  wire  [47:0] g_XSCore__auto_memBlock_inner_dcache_client_out_a_bits_address;
  wire  [47:0] i_XSCore__auto_memBlock_inner_dcache_client_out_a_bits_address;
  logic [47:0] p_XSCore__auto_memBlock_inner_dcache_client_out_a_bits_address;
  bit   t_XSCore__auto_memBlock_inner_dcache_client_out_a_bits_address;
  wire  [1:0] g_XSCore__auto_memBlock_inner_dcache_client_out_a_bits_user_alias;
  wire  [1:0] i_XSCore__auto_memBlock_inner_dcache_client_out_a_bits_user_alias;
  logic [1:0] p_XSCore__auto_memBlock_inner_dcache_client_out_a_bits_user_alias;
  bit   t_XSCore__auto_memBlock_inner_dcache_client_out_a_bits_user_alias;
  wire  [43:0] g_XSCore__auto_memBlock_inner_dcache_client_out_a_bits_user_vaddr;
  wire  [43:0] i_XSCore__auto_memBlock_inner_dcache_client_out_a_bits_user_vaddr;
  logic [43:0] p_XSCore__auto_memBlock_inner_dcache_client_out_a_bits_user_vaddr;
  bit   t_XSCore__auto_memBlock_inner_dcache_client_out_a_bits_user_vaddr;
  wire  [4:0] g_XSCore__auto_memBlock_inner_dcache_client_out_a_bits_user_reqSource;
  wire  [4:0] i_XSCore__auto_memBlock_inner_dcache_client_out_a_bits_user_reqSource;
  logic [4:0] p_XSCore__auto_memBlock_inner_dcache_client_out_a_bits_user_reqSource;
  bit   t_XSCore__auto_memBlock_inner_dcache_client_out_a_bits_user_reqSource;
  wire  g_XSCore__auto_memBlock_inner_dcache_client_out_a_bits_user_needHint;
  wire  i_XSCore__auto_memBlock_inner_dcache_client_out_a_bits_user_needHint;
  logic p_XSCore__auto_memBlock_inner_dcache_client_out_a_bits_user_needHint;
  bit   t_XSCore__auto_memBlock_inner_dcache_client_out_a_bits_user_needHint;
  wire  g_XSCore__auto_memBlock_inner_dcache_client_out_a_bits_echo_isKeyword;
  wire  i_XSCore__auto_memBlock_inner_dcache_client_out_a_bits_echo_isKeyword;
  logic p_XSCore__auto_memBlock_inner_dcache_client_out_a_bits_echo_isKeyword;
  bit   t_XSCore__auto_memBlock_inner_dcache_client_out_a_bits_echo_isKeyword;
  wire  [31:0] g_XSCore__auto_memBlock_inner_dcache_client_out_a_bits_mask;
  wire  [31:0] i_XSCore__auto_memBlock_inner_dcache_client_out_a_bits_mask;
  logic [31:0] p_XSCore__auto_memBlock_inner_dcache_client_out_a_bits_mask;
  bit   t_XSCore__auto_memBlock_inner_dcache_client_out_a_bits_mask;
  wire  [255:0] g_XSCore__auto_memBlock_inner_dcache_client_out_a_bits_data;
  wire  [255:0] i_XSCore__auto_memBlock_inner_dcache_client_out_a_bits_data;
  logic [255:0] p_XSCore__auto_memBlock_inner_dcache_client_out_a_bits_data;
  bit   t_XSCore__auto_memBlock_inner_dcache_client_out_a_bits_data;
  wire  g_XSCore__auto_memBlock_inner_dcache_client_out_a_bits_corrupt;
  wire  i_XSCore__auto_memBlock_inner_dcache_client_out_a_bits_corrupt;
  logic p_XSCore__auto_memBlock_inner_dcache_client_out_a_bits_corrupt;
  bit   t_XSCore__auto_memBlock_inner_dcache_client_out_a_bits_corrupt;
  wire  g_XSCore__auto_memBlock_inner_dcache_client_out_b_ready;
  wire  i_XSCore__auto_memBlock_inner_dcache_client_out_b_ready;
  logic p_XSCore__auto_memBlock_inner_dcache_client_out_b_ready;
  bit   t_XSCore__auto_memBlock_inner_dcache_client_out_b_ready;
  wire  g_XSCore__auto_memBlock_inner_dcache_client_out_c_valid;
  wire  i_XSCore__auto_memBlock_inner_dcache_client_out_c_valid;
  logic p_XSCore__auto_memBlock_inner_dcache_client_out_c_valid;
  bit   t_XSCore__auto_memBlock_inner_dcache_client_out_c_valid;
  wire  [2:0] g_XSCore__auto_memBlock_inner_dcache_client_out_c_bits_opcode;
  wire  [2:0] i_XSCore__auto_memBlock_inner_dcache_client_out_c_bits_opcode;
  logic [2:0] p_XSCore__auto_memBlock_inner_dcache_client_out_c_bits_opcode;
  bit   t_XSCore__auto_memBlock_inner_dcache_client_out_c_bits_opcode;
  wire  [2:0] g_XSCore__auto_memBlock_inner_dcache_client_out_c_bits_param;
  wire  [2:0] i_XSCore__auto_memBlock_inner_dcache_client_out_c_bits_param;
  logic [2:0] p_XSCore__auto_memBlock_inner_dcache_client_out_c_bits_param;
  bit   t_XSCore__auto_memBlock_inner_dcache_client_out_c_bits_param;
  wire  [2:0] g_XSCore__auto_memBlock_inner_dcache_client_out_c_bits_size;
  wire  [2:0] i_XSCore__auto_memBlock_inner_dcache_client_out_c_bits_size;
  logic [2:0] p_XSCore__auto_memBlock_inner_dcache_client_out_c_bits_size;
  bit   t_XSCore__auto_memBlock_inner_dcache_client_out_c_bits_size;
  wire  [5:0] g_XSCore__auto_memBlock_inner_dcache_client_out_c_bits_source;
  wire  [5:0] i_XSCore__auto_memBlock_inner_dcache_client_out_c_bits_source;
  logic [5:0] p_XSCore__auto_memBlock_inner_dcache_client_out_c_bits_source;
  bit   t_XSCore__auto_memBlock_inner_dcache_client_out_c_bits_source;
  wire  [47:0] g_XSCore__auto_memBlock_inner_dcache_client_out_c_bits_address;
  wire  [47:0] i_XSCore__auto_memBlock_inner_dcache_client_out_c_bits_address;
  logic [47:0] p_XSCore__auto_memBlock_inner_dcache_client_out_c_bits_address;
  bit   t_XSCore__auto_memBlock_inner_dcache_client_out_c_bits_address;
  wire  [1:0] g_XSCore__auto_memBlock_inner_dcache_client_out_c_bits_user_alias;
  wire  [1:0] i_XSCore__auto_memBlock_inner_dcache_client_out_c_bits_user_alias;
  logic [1:0] p_XSCore__auto_memBlock_inner_dcache_client_out_c_bits_user_alias;
  bit   t_XSCore__auto_memBlock_inner_dcache_client_out_c_bits_user_alias;
  wire  [43:0] g_XSCore__auto_memBlock_inner_dcache_client_out_c_bits_user_vaddr;
  wire  [43:0] i_XSCore__auto_memBlock_inner_dcache_client_out_c_bits_user_vaddr;
  logic [43:0] p_XSCore__auto_memBlock_inner_dcache_client_out_c_bits_user_vaddr;
  bit   t_XSCore__auto_memBlock_inner_dcache_client_out_c_bits_user_vaddr;
  wire  [4:0] g_XSCore__auto_memBlock_inner_dcache_client_out_c_bits_user_reqSource;
  wire  [4:0] i_XSCore__auto_memBlock_inner_dcache_client_out_c_bits_user_reqSource;
  logic [4:0] p_XSCore__auto_memBlock_inner_dcache_client_out_c_bits_user_reqSource;
  bit   t_XSCore__auto_memBlock_inner_dcache_client_out_c_bits_user_reqSource;
  wire  g_XSCore__auto_memBlock_inner_dcache_client_out_c_bits_user_needHint;
  wire  i_XSCore__auto_memBlock_inner_dcache_client_out_c_bits_user_needHint;
  logic p_XSCore__auto_memBlock_inner_dcache_client_out_c_bits_user_needHint;
  bit   t_XSCore__auto_memBlock_inner_dcache_client_out_c_bits_user_needHint;
  wire  g_XSCore__auto_memBlock_inner_dcache_client_out_c_bits_echo_isKeyword;
  wire  i_XSCore__auto_memBlock_inner_dcache_client_out_c_bits_echo_isKeyword;
  logic p_XSCore__auto_memBlock_inner_dcache_client_out_c_bits_echo_isKeyword;
  bit   t_XSCore__auto_memBlock_inner_dcache_client_out_c_bits_echo_isKeyword;
  wire  [255:0] g_XSCore__auto_memBlock_inner_dcache_client_out_c_bits_data;
  wire  [255:0] i_XSCore__auto_memBlock_inner_dcache_client_out_c_bits_data;
  logic [255:0] p_XSCore__auto_memBlock_inner_dcache_client_out_c_bits_data;
  bit   t_XSCore__auto_memBlock_inner_dcache_client_out_c_bits_data;
  wire  g_XSCore__auto_memBlock_inner_dcache_client_out_c_bits_corrupt;
  wire  i_XSCore__auto_memBlock_inner_dcache_client_out_c_bits_corrupt;
  logic p_XSCore__auto_memBlock_inner_dcache_client_out_c_bits_corrupt;
  bit   t_XSCore__auto_memBlock_inner_dcache_client_out_c_bits_corrupt;
  wire  g_XSCore__auto_memBlock_inner_dcache_client_out_d_ready;
  wire  i_XSCore__auto_memBlock_inner_dcache_client_out_d_ready;
  logic p_XSCore__auto_memBlock_inner_dcache_client_out_d_ready;
  bit   t_XSCore__auto_memBlock_inner_dcache_client_out_d_ready;
  wire  g_XSCore__auto_memBlock_inner_dcache_client_out_e_valid;
  wire  i_XSCore__auto_memBlock_inner_dcache_client_out_e_valid;
  logic p_XSCore__auto_memBlock_inner_dcache_client_out_e_valid;
  bit   t_XSCore__auto_memBlock_inner_dcache_client_out_e_valid;
  wire  [9:0] g_XSCore__auto_memBlock_inner_dcache_client_out_e_bits_sink;
  wire  [9:0] i_XSCore__auto_memBlock_inner_dcache_client_out_e_bits_sink;
  logic [9:0] p_XSCore__auto_memBlock_inner_dcache_client_out_e_bits_sink;
  bit   t_XSCore__auto_memBlock_inner_dcache_client_out_e_bits_sink;
  wire  g_XSCore__io_msiAck;
  wire  i_XSCore__io_msiAck;
  logic p_XSCore__io_msiAck;
  bit   t_XSCore__io_msiAck;
  wire  g_XSCore__io_cpu_halt;
  wire  i_XSCore__io_cpu_halt;
  logic p_XSCore__io_cpu_halt;
  bit   t_XSCore__io_cpu_halt;
  wire  g_XSCore__io_l2_flush_en;
  wire  i_XSCore__io_l2_flush_en;
  logic p_XSCore__io_l2_flush_en;
  bit   t_XSCore__io_l2_flush_en;
  wire  g_XSCore__io_power_down_en;
  wire  i_XSCore__io_power_down_en;
  logic p_XSCore__io_power_down_en;
  bit   t_XSCore__io_power_down_en;
  wire  g_XSCore__io_cpu_critical_error;
  wire  i_XSCore__io_cpu_critical_error;
  logic p_XSCore__io_cpu_critical_error;
  bit   t_XSCore__io_cpu_critical_error;
  wire  g_XSCore__io_resetInFrontend;
  wire  i_XSCore__io_resetInFrontend;
  logic p_XSCore__io_resetInFrontend;
  bit   t_XSCore__io_resetInFrontend;
  wire  [2:0] g_XSCore__io_traceCoreInterface_toEncoder_priv;
  wire  [2:0] i_XSCore__io_traceCoreInterface_toEncoder_priv;
  logic [2:0] p_XSCore__io_traceCoreInterface_toEncoder_priv;
  bit   t_XSCore__io_traceCoreInterface_toEncoder_priv;
  wire  [63:0] g_XSCore__io_traceCoreInterface_toEncoder_mstatus;
  wire  [63:0] i_XSCore__io_traceCoreInterface_toEncoder_mstatus;
  logic [63:0] p_XSCore__io_traceCoreInterface_toEncoder_mstatus;
  bit   t_XSCore__io_traceCoreInterface_toEncoder_mstatus;
  wire  [63:0] g_XSCore__io_traceCoreInterface_toEncoder_trap_cause;
  wire  [63:0] i_XSCore__io_traceCoreInterface_toEncoder_trap_cause;
  logic [63:0] p_XSCore__io_traceCoreInterface_toEncoder_trap_cause;
  bit   t_XSCore__io_traceCoreInterface_toEncoder_trap_cause;
  wire  [49:0] g_XSCore__io_traceCoreInterface_toEncoder_trap_tval;
  wire  [49:0] i_XSCore__io_traceCoreInterface_toEncoder_trap_tval;
  logic [49:0] p_XSCore__io_traceCoreInterface_toEncoder_trap_tval;
  bit   t_XSCore__io_traceCoreInterface_toEncoder_trap_tval;
  wire  g_XSCore__io_traceCoreInterface_toEncoder_groups_0_valid;
  wire  i_XSCore__io_traceCoreInterface_toEncoder_groups_0_valid;
  logic p_XSCore__io_traceCoreInterface_toEncoder_groups_0_valid;
  bit   t_XSCore__io_traceCoreInterface_toEncoder_groups_0_valid;
  wire  [49:0] g_XSCore__io_traceCoreInterface_toEncoder_groups_0_bits_iaddr;
  wire  [49:0] i_XSCore__io_traceCoreInterface_toEncoder_groups_0_bits_iaddr;
  logic [49:0] p_XSCore__io_traceCoreInterface_toEncoder_groups_0_bits_iaddr;
  bit   t_XSCore__io_traceCoreInterface_toEncoder_groups_0_bits_iaddr;
  wire  [3:0] g_XSCore__io_traceCoreInterface_toEncoder_groups_0_bits_itype;
  wire  [3:0] i_XSCore__io_traceCoreInterface_toEncoder_groups_0_bits_itype;
  logic [3:0] p_XSCore__io_traceCoreInterface_toEncoder_groups_0_bits_itype;
  bit   t_XSCore__io_traceCoreInterface_toEncoder_groups_0_bits_itype;
  wire  [6:0] g_XSCore__io_traceCoreInterface_toEncoder_groups_0_bits_iretire;
  wire  [6:0] i_XSCore__io_traceCoreInterface_toEncoder_groups_0_bits_iretire;
  logic [6:0] p_XSCore__io_traceCoreInterface_toEncoder_groups_0_bits_iretire;
  bit   t_XSCore__io_traceCoreInterface_toEncoder_groups_0_bits_iretire;
  wire  g_XSCore__io_traceCoreInterface_toEncoder_groups_0_bits_ilastsize;
  wire  i_XSCore__io_traceCoreInterface_toEncoder_groups_0_bits_ilastsize;
  logic p_XSCore__io_traceCoreInterface_toEncoder_groups_0_bits_ilastsize;
  bit   t_XSCore__io_traceCoreInterface_toEncoder_groups_0_bits_ilastsize;
  wire  g_XSCore__io_traceCoreInterface_toEncoder_groups_1_valid;
  wire  i_XSCore__io_traceCoreInterface_toEncoder_groups_1_valid;
  logic p_XSCore__io_traceCoreInterface_toEncoder_groups_1_valid;
  bit   t_XSCore__io_traceCoreInterface_toEncoder_groups_1_valid;
  wire  [49:0] g_XSCore__io_traceCoreInterface_toEncoder_groups_1_bits_iaddr;
  wire  [49:0] i_XSCore__io_traceCoreInterface_toEncoder_groups_1_bits_iaddr;
  logic [49:0] p_XSCore__io_traceCoreInterface_toEncoder_groups_1_bits_iaddr;
  bit   t_XSCore__io_traceCoreInterface_toEncoder_groups_1_bits_iaddr;
  wire  [3:0] g_XSCore__io_traceCoreInterface_toEncoder_groups_1_bits_itype;
  wire  [3:0] i_XSCore__io_traceCoreInterface_toEncoder_groups_1_bits_itype;
  logic [3:0] p_XSCore__io_traceCoreInterface_toEncoder_groups_1_bits_itype;
  bit   t_XSCore__io_traceCoreInterface_toEncoder_groups_1_bits_itype;
  wire  [6:0] g_XSCore__io_traceCoreInterface_toEncoder_groups_1_bits_iretire;
  wire  [6:0] i_XSCore__io_traceCoreInterface_toEncoder_groups_1_bits_iretire;
  logic [6:0] p_XSCore__io_traceCoreInterface_toEncoder_groups_1_bits_iretire;
  bit   t_XSCore__io_traceCoreInterface_toEncoder_groups_1_bits_iretire;
  wire  g_XSCore__io_traceCoreInterface_toEncoder_groups_1_bits_ilastsize;
  wire  i_XSCore__io_traceCoreInterface_toEncoder_groups_1_bits_ilastsize;
  logic p_XSCore__io_traceCoreInterface_toEncoder_groups_1_bits_ilastsize;
  bit   t_XSCore__io_traceCoreInterface_toEncoder_groups_1_bits_ilastsize;
  wire  g_XSCore__io_traceCoreInterface_toEncoder_groups_2_valid;
  wire  i_XSCore__io_traceCoreInterface_toEncoder_groups_2_valid;
  logic p_XSCore__io_traceCoreInterface_toEncoder_groups_2_valid;
  bit   t_XSCore__io_traceCoreInterface_toEncoder_groups_2_valid;
  wire  [49:0] g_XSCore__io_traceCoreInterface_toEncoder_groups_2_bits_iaddr;
  wire  [49:0] i_XSCore__io_traceCoreInterface_toEncoder_groups_2_bits_iaddr;
  logic [49:0] p_XSCore__io_traceCoreInterface_toEncoder_groups_2_bits_iaddr;
  bit   t_XSCore__io_traceCoreInterface_toEncoder_groups_2_bits_iaddr;
  wire  [3:0] g_XSCore__io_traceCoreInterface_toEncoder_groups_2_bits_itype;
  wire  [3:0] i_XSCore__io_traceCoreInterface_toEncoder_groups_2_bits_itype;
  logic [3:0] p_XSCore__io_traceCoreInterface_toEncoder_groups_2_bits_itype;
  bit   t_XSCore__io_traceCoreInterface_toEncoder_groups_2_bits_itype;
  wire  [6:0] g_XSCore__io_traceCoreInterface_toEncoder_groups_2_bits_iretire;
  wire  [6:0] i_XSCore__io_traceCoreInterface_toEncoder_groups_2_bits_iretire;
  logic [6:0] p_XSCore__io_traceCoreInterface_toEncoder_groups_2_bits_iretire;
  bit   t_XSCore__io_traceCoreInterface_toEncoder_groups_2_bits_iretire;
  wire  g_XSCore__io_traceCoreInterface_toEncoder_groups_2_bits_ilastsize;
  wire  i_XSCore__io_traceCoreInterface_toEncoder_groups_2_bits_ilastsize;
  logic p_XSCore__io_traceCoreInterface_toEncoder_groups_2_bits_ilastsize;
  bit   t_XSCore__io_traceCoreInterface_toEncoder_groups_2_bits_ilastsize;
  wire  g_XSCore__io_l2PfCtrl_l2_pf_master_en;
  wire  i_XSCore__io_l2PfCtrl_l2_pf_master_en;
  logic p_XSCore__io_l2PfCtrl_l2_pf_master_en;
  bit   t_XSCore__io_l2PfCtrl_l2_pf_master_en;
  wire  g_XSCore__io_l2PfCtrl_l2_pf_recv_en;
  wire  i_XSCore__io_l2PfCtrl_l2_pf_recv_en;
  logic p_XSCore__io_l2PfCtrl_l2_pf_recv_en;
  bit   t_XSCore__io_l2PfCtrl_l2_pf_recv_en;
  wire  g_XSCore__io_l2PfCtrl_l2_pbop_en;
  wire  i_XSCore__io_l2PfCtrl_l2_pbop_en;
  logic p_XSCore__io_l2PfCtrl_l2_pbop_en;
  bit   t_XSCore__io_l2PfCtrl_l2_pbop_en;
  wire  g_XSCore__io_l2PfCtrl_l2_vbop_en;
  wire  i_XSCore__io_l2PfCtrl_l2_vbop_en;
  logic p_XSCore__io_l2PfCtrl_l2_vbop_en;
  bit   t_XSCore__io_l2PfCtrl_l2_vbop_en;
  wire  [9:0] g_XSCore__io_l2PfCtrl_l2_pf_delay_latency;
  wire  [9:0] i_XSCore__io_l2PfCtrl_l2_pf_delay_latency;
  logic [9:0] p_XSCore__io_l2PfCtrl_l2_pf_delay_latency;
  bit   t_XSCore__io_l2PfCtrl_l2_pf_delay_latency;
  wire  g_XSCore__io_beu_errors_icache_ecc_error_valid;
  wire  i_XSCore__io_beu_errors_icache_ecc_error_valid;
  logic p_XSCore__io_beu_errors_icache_ecc_error_valid;
  bit   t_XSCore__io_beu_errors_icache_ecc_error_valid;
  wire  [47:0] g_XSCore__io_beu_errors_icache_ecc_error_bits;
  wire  [47:0] i_XSCore__io_beu_errors_icache_ecc_error_bits;
  logic [47:0] p_XSCore__io_beu_errors_icache_ecc_error_bits;
  bit   t_XSCore__io_beu_errors_icache_ecc_error_bits;
  wire  g_XSCore__io_beu_errors_dcache_ecc_error_valid;
  wire  i_XSCore__io_beu_errors_dcache_ecc_error_valid;
  logic p_XSCore__io_beu_errors_dcache_ecc_error_valid;
  bit   t_XSCore__io_beu_errors_dcache_ecc_error_valid;
  wire  [47:0] g_XSCore__io_beu_errors_dcache_ecc_error_bits;
  wire  [47:0] i_XSCore__io_beu_errors_dcache_ecc_error_bits;
  logic [47:0] p_XSCore__io_beu_errors_dcache_ecc_error_bits;
  bit   t_XSCore__io_beu_errors_dcache_ecc_error_bits;
  wire  g_XSCore__io_beu_errors_uncache_ecc_error_valid;
  wire  i_XSCore__io_beu_errors_uncache_ecc_error_valid;
  logic p_XSCore__io_beu_errors_uncache_ecc_error_valid;
  bit   t_XSCore__io_beu_errors_uncache_ecc_error_valid;
  wire  [47:0] g_XSCore__io_beu_errors_uncache_ecc_error_bits;
  wire  [47:0] i_XSCore__io_beu_errors_uncache_ecc_error_bits;
  logic [47:0] p_XSCore__io_beu_errors_uncache_ecc_error_bits;
  bit   t_XSCore__io_beu_errors_uncache_ecc_error_bits;
  wire  g_XSCore__io_l2_tlb_req_resp_valid;
  wire  i_XSCore__io_l2_tlb_req_resp_valid;
  logic p_XSCore__io_l2_tlb_req_resp_valid;
  bit   t_XSCore__io_l2_tlb_req_resp_valid;
  wire  [47:0] g_XSCore__io_l2_tlb_req_resp_bits_paddr_0;
  wire  [47:0] i_XSCore__io_l2_tlb_req_resp_bits_paddr_0;
  logic [47:0] p_XSCore__io_l2_tlb_req_resp_bits_paddr_0;
  bit   t_XSCore__io_l2_tlb_req_resp_bits_paddr_0;
  wire  [1:0] g_XSCore__io_l2_tlb_req_resp_bits_pbmt_0;
  wire  [1:0] i_XSCore__io_l2_tlb_req_resp_bits_pbmt_0;
  logic [1:0] p_XSCore__io_l2_tlb_req_resp_bits_pbmt_0;
  bit   t_XSCore__io_l2_tlb_req_resp_bits_pbmt_0;
  wire  g_XSCore__io_l2_tlb_req_resp_bits_miss;
  wire  i_XSCore__io_l2_tlb_req_resp_bits_miss;
  logic p_XSCore__io_l2_tlb_req_resp_bits_miss;
  bit   t_XSCore__io_l2_tlb_req_resp_bits_miss;
  wire  g_XSCore__io_l2_tlb_req_resp_bits_excp_0_gpf_ld;
  wire  i_XSCore__io_l2_tlb_req_resp_bits_excp_0_gpf_ld;
  logic p_XSCore__io_l2_tlb_req_resp_bits_excp_0_gpf_ld;
  bit   t_XSCore__io_l2_tlb_req_resp_bits_excp_0_gpf_ld;
  wire  g_XSCore__io_l2_tlb_req_resp_bits_excp_0_pf_ld;
  wire  i_XSCore__io_l2_tlb_req_resp_bits_excp_0_pf_ld;
  logic p_XSCore__io_l2_tlb_req_resp_bits_excp_0_pf_ld;
  bit   t_XSCore__io_l2_tlb_req_resp_bits_excp_0_pf_ld;
  wire  g_XSCore__io_l2_tlb_req_resp_bits_excp_0_af_ld;
  wire  i_XSCore__io_l2_tlb_req_resp_bits_excp_0_af_ld;
  logic p_XSCore__io_l2_tlb_req_resp_bits_excp_0_af_ld;
  bit   t_XSCore__io_l2_tlb_req_resp_bits_excp_0_af_ld;
  wire  g_XSCore__io_l2_pmp_resp_ld;
  wire  i_XSCore__io_l2_pmp_resp_ld;
  logic p_XSCore__io_l2_pmp_resp_ld;
  bit   t_XSCore__io_l2_pmp_resp_ld;
  wire  g_XSCore__io_l2_pmp_resp_mmio;
  wire  i_XSCore__io_l2_pmp_resp_mmio;
  logic p_XSCore__io_l2_pmp_resp_mmio;
  bit   t_XSCore__io_l2_pmp_resp_mmio;
  wire  g_XSCore__io_debugTopDown_robHeadPaddr_valid;
  wire  i_XSCore__io_debugTopDown_robHeadPaddr_valid;
  logic p_XSCore__io_debugTopDown_robHeadPaddr_valid;
  bit   t_XSCore__io_debugTopDown_robHeadPaddr_valid;
  wire  [47:0] g_XSCore__io_debugTopDown_robHeadPaddr_bits;
  wire  [47:0] i_XSCore__io_debugTopDown_robHeadPaddr_bits;
  logic [47:0] p_XSCore__io_debugTopDown_robHeadPaddr_bits;
  bit   t_XSCore__io_debugTopDown_robHeadPaddr_bits;
  wire  [600:0] g_XSCore__gatewayIn_packed_0_bore;
  wire  [600:0] i_XSCore__gatewayIn_packed_0_bore;
  logic [600:0] p_XSCore__gatewayIn_packed_0_bore;
  bit   t_XSCore__gatewayIn_packed_0_bore;
  wire  [600:0] g_XSCore__gatewayIn_packed_1_bore;
  wire  [600:0] i_XSCore__gatewayIn_packed_1_bore;
  logic [600:0] p_XSCore__gatewayIn_packed_1_bore;
  bit   t_XSCore__gatewayIn_packed_1_bore;
  wire  [600:0] g_XSCore__gatewayIn_packed_2_bore;
  wire  [600:0] i_XSCore__gatewayIn_packed_2_bore;
  logic [600:0] p_XSCore__gatewayIn_packed_2_bore;
  bit   t_XSCore__gatewayIn_packed_2_bore;
  wire  [338:0] g_XSCore__gatewayIn_packed_3_bore;
  wire  [338:0] i_XSCore__gatewayIn_packed_3_bore;
  logic [338:0] p_XSCore__gatewayIn_packed_3_bore;
  bit   t_XSCore__gatewayIn_packed_3_bore;
  wire  [338:0] g_XSCore__gatewayIn_packed_4_bore;
  wire  [338:0] i_XSCore__gatewayIn_packed_4_bore;
  logic [338:0] p_XSCore__gatewayIn_packed_4_bore;
  bit   t_XSCore__gatewayIn_packed_4_bore;
  wire  [338:0] g_XSCore__gatewayIn_packed_5_bore;
  wire  [338:0] i_XSCore__gatewayIn_packed_5_bore;
  logic [338:0] p_XSCore__gatewayIn_packed_5_bore;
  bit   t_XSCore__gatewayIn_packed_5_bore;
  wire  [321:0] g_XSCore__gatewayIn_packed_6_bore;
  wire  [321:0] i_XSCore__gatewayIn_packed_6_bore;
  logic [321:0] p_XSCore__gatewayIn_packed_6_bore;
  bit   t_XSCore__gatewayIn_packed_6_bore;
  wire  [91:0] g_XSCore__gatewayIn_packed_7_bore;
  wire  [91:0] i_XSCore__gatewayIn_packed_7_bore;
  logic [91:0] p_XSCore__gatewayIn_packed_7_bore;
  bit   t_XSCore__gatewayIn_packed_7_bore;
  wire  [321:0] g_XSCore__gatewayIn_packed_8_bore;
  wire  [321:0] i_XSCore__gatewayIn_packed_8_bore;
  logic [321:0] p_XSCore__gatewayIn_packed_8_bore;
  bit   t_XSCore__gatewayIn_packed_8_bore;
  wire  [91:0] g_XSCore__gatewayIn_packed_9_bore;
  wire  [91:0] i_XSCore__gatewayIn_packed_9_bore;
  logic [91:0] p_XSCore__gatewayIn_packed_9_bore;
  bit   t_XSCore__gatewayIn_packed_9_bore;
  wire  [321:0] g_XSCore__gatewayIn_packed_10_bore;
  wire  [321:0] i_XSCore__gatewayIn_packed_10_bore;
  logic [321:0] p_XSCore__gatewayIn_packed_10_bore;
  bit   t_XSCore__gatewayIn_packed_10_bore;
  wire  [91:0] g_XSCore__gatewayIn_packed_11_bore;
  wire  [91:0] i_XSCore__gatewayIn_packed_11_bore;
  logic [91:0] p_XSCore__gatewayIn_packed_11_bore;
  bit   t_XSCore__gatewayIn_packed_11_bore;
  wire  [321:0] g_XSCore__gatewayIn_packed_12_bore;
  wire  [321:0] i_XSCore__gatewayIn_packed_12_bore;
  logic [321:0] p_XSCore__gatewayIn_packed_12_bore;
  bit   t_XSCore__gatewayIn_packed_12_bore;
  wire  [91:0] g_XSCore__gatewayIn_packed_13_bore;
  wire  [91:0] i_XSCore__gatewayIn_packed_13_bore;
  logic [91:0] p_XSCore__gatewayIn_packed_13_bore;
  bit   t_XSCore__gatewayIn_packed_13_bore;
  wire  [321:0] g_XSCore__gatewayIn_packed_14_bore;
  wire  [321:0] i_XSCore__gatewayIn_packed_14_bore;
  logic [321:0] p_XSCore__gatewayIn_packed_14_bore;
  bit   t_XSCore__gatewayIn_packed_14_bore;
  wire  [91:0] g_XSCore__gatewayIn_packed_15_bore;
  wire  [91:0] i_XSCore__gatewayIn_packed_15_bore;
  logic [91:0] p_XSCore__gatewayIn_packed_15_bore;
  bit   t_XSCore__gatewayIn_packed_15_bore;
  wire  [321:0] g_XSCore__gatewayIn_packed_16_bore;
  wire  [321:0] i_XSCore__gatewayIn_packed_16_bore;
  logic [321:0] p_XSCore__gatewayIn_packed_16_bore;
  bit   t_XSCore__gatewayIn_packed_16_bore;
  wire  [91:0] g_XSCore__gatewayIn_packed_17_bore;
  wire  [91:0] i_XSCore__gatewayIn_packed_17_bore;
  logic [91:0] p_XSCore__gatewayIn_packed_17_bore;
  bit   t_XSCore__gatewayIn_packed_17_bore;
  wire  [321:0] g_XSCore__gatewayIn_packed_18_bore;
  wire  [321:0] i_XSCore__gatewayIn_packed_18_bore;
  logic [321:0] p_XSCore__gatewayIn_packed_18_bore;
  bit   t_XSCore__gatewayIn_packed_18_bore;
  wire  [91:0] g_XSCore__gatewayIn_packed_19_bore;
  wire  [91:0] i_XSCore__gatewayIn_packed_19_bore;
  logic [91:0] p_XSCore__gatewayIn_packed_19_bore;
  bit   t_XSCore__gatewayIn_packed_19_bore;
  wire  [321:0] g_XSCore__gatewayIn_packed_20_bore;
  wire  [321:0] i_XSCore__gatewayIn_packed_20_bore;
  logic [321:0] p_XSCore__gatewayIn_packed_20_bore;
  bit   t_XSCore__gatewayIn_packed_20_bore;
  wire  [91:0] g_XSCore__gatewayIn_packed_21_bore;
  wire  [91:0] i_XSCore__gatewayIn_packed_21_bore;
  logic [91:0] p_XSCore__gatewayIn_packed_21_bore;
  bit   t_XSCore__gatewayIn_packed_21_bore;
  wire  [265:0] g_XSCore__gatewayIn_packed_22_bore;
  wire  [265:0] i_XSCore__gatewayIn_packed_22_bore;
  logic [265:0] p_XSCore__gatewayIn_packed_22_bore;
  bit   t_XSCore__gatewayIn_packed_22_bore;
  wire  [263:0] g_XSCore__gatewayIn_packed_23_bore;
  wire  [263:0] i_XSCore__gatewayIn_packed_23_bore;
  logic [263:0] p_XSCore__gatewayIn_packed_23_bore;
  bit   t_XSCore__gatewayIn_packed_23_bore;
  wire  [263:0] g_XSCore__gatewayIn_packed_24_bore;
  wire  [263:0] i_XSCore__gatewayIn_packed_24_bore;
  logic [263:0] p_XSCore__gatewayIn_packed_24_bore;
  bit   t_XSCore__gatewayIn_packed_24_bore;
  wire  [583:0] g_XSCore__gatewayIn_packed_25_bore;
  wire  [583:0] i_XSCore__gatewayIn_packed_25_bore;
  logic [583:0] p_XSCore__gatewayIn_packed_25_bore;
  bit   t_XSCore__gatewayIn_packed_25_bore;
  wire  [14343:0] g_XSCore__gatewayIn_packed_26_bore;
  wire  [14343:0] i_XSCore__gatewayIn_packed_26_bore;
  logic [14343:0] p_XSCore__gatewayIn_packed_26_bore;
  bit   t_XSCore__gatewayIn_packed_26_bore;
  wire  [12295:0] g_XSCore__gatewayIn_packed_27_bore;
  wire  [12295:0] i_XSCore__gatewayIn_packed_27_bore;
  logic [12295:0] p_XSCore__gatewayIn_packed_27_bore;
  bit   t_XSCore__gatewayIn_packed_27_bore;
  wire  [19207:0] g_XSCore__gatewayIn_packed_28_bore;
  wire  [19207:0] i_XSCore__gatewayIn_packed_28_bore;
  logic [19207:0] p_XSCore__gatewayIn_packed_28_bore;
  bit   t_XSCore__gatewayIn_packed_28_bore;
  wire  [172:0] g_XSCore__gatewayIn_packed_29_bore;
  wire  [172:0] i_XSCore__gatewayIn_packed_29_bore;
  logic [172:0] p_XSCore__gatewayIn_packed_29_bore;
  bit   t_XSCore__gatewayIn_packed_29_bore;
  wire  [9:0] g_XSCore__gatewayIn_packed_30_bore;
  wire  [9:0] i_XSCore__gatewayIn_packed_30_bore;
  logic [9:0] p_XSCore__gatewayIn_packed_30_bore;
  bit   t_XSCore__gatewayIn_packed_30_bore;
  wire  [1159:0] g_XSCore__gatewayIn_packed_31_bore;
  wire  [1159:0] i_XSCore__gatewayIn_packed_31_bore;
  logic [1159:0] p_XSCore__gatewayIn_packed_31_bore;
  bit   t_XSCore__gatewayIn_packed_31_bore;
  wire  [264:0] g_XSCore__gatewayIn_packed_32_bore;
  wire  [264:0] i_XSCore__gatewayIn_packed_32_bore;
  logic [264:0] p_XSCore__gatewayIn_packed_32_bore;
  bit   t_XSCore__gatewayIn_packed_32_bore;
  wire  [199:0] g_XSCore__gatewayIn_packed_33_bore;
  wire  [199:0] i_XSCore__gatewayIn_packed_33_bore;
  logic [199:0] p_XSCore__gatewayIn_packed_33_bore;
  bit   t_XSCore__gatewayIn_packed_33_bore;
  wire  [455:0] g_XSCore__gatewayIn_packed_34_bore;
  wire  [455:0] i_XSCore__gatewayIn_packed_34_bore;
  logic [455:0] p_XSCore__gatewayIn_packed_34_bore;
  bit   t_XSCore__gatewayIn_packed_34_bore;
  wire  [71:0] g_XSCore__gatewayIn_packed_35_bore;
  wire  [71:0] i_XSCore__gatewayIn_packed_35_bore;
  logic [71:0] p_XSCore__gatewayIn_packed_35_bore;
  bit   t_XSCore__gatewayIn_packed_35_bore;
  wire  [1095:0] g_XSCore__gatewayIn_packed_36_bore;
  wire  [1095:0] i_XSCore__gatewayIn_packed_36_bore;
  logic [1095:0] p_XSCore__gatewayIn_packed_36_bore;
  bit   t_XSCore__gatewayIn_packed_36_bore;
  wire  [18:0] g_XSCore__gatewayIn_packed_37_bore;
  wire  [18:0] i_XSCore__gatewayIn_packed_37_bore;
  logic [18:0] p_XSCore__gatewayIn_packed_37_bore;
  bit   t_XSCore__gatewayIn_packed_37_bore;
  wire  [72:0] g_XSCore__gatewayIn_packed_38_bore;
  wire  [72:0] i_XSCore__gatewayIn_packed_38_bore;
  logic [72:0] p_XSCore__gatewayIn_packed_38_bore;
  bit   t_XSCore__gatewayIn_packed_38_bore;
  wire  [264:0] g_XSCore__gatewayIn_packed_39_bore;
  wire  [264:0] i_XSCore__gatewayIn_packed_39_bore;
  logic [264:0] p_XSCore__gatewayIn_packed_39_bore;
  bit   t_XSCore__gatewayIn_packed_39_bore;
  wire  [9:0] g_XSCore__gatewayIn_packed_40_bore;
  wire  [9:0] i_XSCore__gatewayIn_packed_40_bore;
  logic [9:0] p_XSCore__gatewayIn_packed_40_bore;
  bit   t_XSCore__gatewayIn_packed_40_bore;
  wire  [600:0] g_XSCore__gatewayIn_packed_41_bore;
  wire  [600:0] i_XSCore__gatewayIn_packed_41_bore;
  logic [600:0] p_XSCore__gatewayIn_packed_41_bore;
  bit   t_XSCore__gatewayIn_packed_41_bore;
  wire  [152:0] g_XSCore__gatewayIn_packed_42_bore;
  wire  [152:0] i_XSCore__gatewayIn_packed_42_bore;
  logic [152:0] p_XSCore__gatewayIn_packed_42_bore;
  bit   t_XSCore__gatewayIn_packed_42_bore;
  wire  [600:0] g_XSCore__gatewayIn_packed_43_bore;
  wire  [600:0] i_XSCore__gatewayIn_packed_43_bore;
  logic [600:0] p_XSCore__gatewayIn_packed_43_bore;
  bit   t_XSCore__gatewayIn_packed_43_bore;
  wire  [968:0] g_XSCore__gatewayIn_packed_44_bore;
  wire  [968:0] i_XSCore__gatewayIn_packed_44_bore;
  logic [968:0] p_XSCore__gatewayIn_packed_44_bore;
  bit   t_XSCore__gatewayIn_packed_44_bore;
  wire  [968:0] g_XSCore__gatewayIn_packed_45_bore;
  wire  [968:0] i_XSCore__gatewayIn_packed_45_bore;
  logic [968:0] p_XSCore__gatewayIn_packed_45_bore;
  bit   t_XSCore__gatewayIn_packed_45_bore;
  wire  [480:0] g_XSCore__gatewayIn_packed_46_bore;
  wire  [480:0] i_XSCore__gatewayIn_packed_46_bore;
  logic [480:0] p_XSCore__gatewayIn_packed_46_bore;
  bit   t_XSCore__gatewayIn_packed_46_bore;
  wire  [9:0] g_XSCore__gatewayIn_packed_47_bore;
  wire  [9:0] i_XSCore__gatewayIn_packed_47_bore;
  logic [9:0] p_XSCore__gatewayIn_packed_47_bore;
  bit   t_XSCore__gatewayIn_packed_47_bore;
  wire  [72:0] g_XSCore__gatewayIn_packed_48_bore;
  wire  [72:0] i_XSCore__gatewayIn_packed_48_bore;
  logic [72:0] p_XSCore__gatewayIn_packed_48_bore;
  bit   t_XSCore__gatewayIn_packed_48_bore;
  wire  [656:0] g_XSCore__gatewayIn_packed_49_bore;
  wire  [656:0] i_XSCore__gatewayIn_packed_49_bore;
  logic [656:0] p_XSCore__gatewayIn_packed_49_bore;
  bit   t_XSCore__gatewayIn_packed_49_bore;
  wire  [324:0] g_XSCore__gatewayIn_packed_50_bore;
  wire  [324:0] i_XSCore__gatewayIn_packed_50_bore;
  logic [324:0] p_XSCore__gatewayIn_packed_50_bore;
  bit   t_XSCore__gatewayIn_packed_50_bore;
  wire  [324:0] g_XSCore__gatewayIn_packed_51_bore;
  wire  [324:0] i_XSCore__gatewayIn_packed_51_bore;
  logic [324:0] p_XSCore__gatewayIn_packed_51_bore;
  bit   t_XSCore__gatewayIn_packed_51_bore;
  wire  [324:0] g_XSCore__gatewayIn_packed_52_bore;
  wire  [324:0] i_XSCore__gatewayIn_packed_52_bore;
  logic [324:0] p_XSCore__gatewayIn_packed_52_bore;
  bit   t_XSCore__gatewayIn_packed_52_bore;
  wire  [338:0] g_XSCore__gatewayIn_packed_53_bore;
  wire  [338:0] i_XSCore__gatewayIn_packed_53_bore;
  logic [338:0] p_XSCore__gatewayIn_packed_53_bore;
  bit   t_XSCore__gatewayIn_packed_53_bore;
  wire  [338:0] g_XSCore__gatewayIn_packed_54_bore;
  wire  [338:0] i_XSCore__gatewayIn_packed_54_bore;
  logic [338:0] p_XSCore__gatewayIn_packed_54_bore;
  bit   t_XSCore__gatewayIn_packed_54_bore;
  wire  [338:0] g_XSCore__gatewayIn_packed_55_bore;
  wire  [338:0] i_XSCore__gatewayIn_packed_55_bore;
  logic [338:0] p_XSCore__gatewayIn_packed_55_bore;
  bit   t_XSCore__gatewayIn_packed_55_bore;
  wire  [338:0] g_XSCore__gatewayIn_packed_56_bore;
  wire  [338:0] i_XSCore__gatewayIn_packed_56_bore;
  logic [338:0] p_XSCore__gatewayIn_packed_56_bore;
  bit   t_XSCore__gatewayIn_packed_56_bore;
  wire  [338:0] g_XSCore__gatewayIn_packed_57_bore;
  wire  [338:0] i_XSCore__gatewayIn_packed_57_bore;
  logic [338:0] p_XSCore__gatewayIn_packed_57_bore;
  bit   t_XSCore__gatewayIn_packed_57_bore;
  wire  [338:0] g_XSCore__gatewayIn_packed_58_bore;
  wire  [338:0] i_XSCore__gatewayIn_packed_58_bore;
  logic [338:0] p_XSCore__gatewayIn_packed_58_bore;
  bit   t_XSCore__gatewayIn_packed_58_bore;
  wire  [338:0] g_XSCore__gatewayIn_packed_59_bore;
  wire  [338:0] i_XSCore__gatewayIn_packed_59_bore;
  logic [338:0] p_XSCore__gatewayIn_packed_59_bore;
  bit   t_XSCore__gatewayIn_packed_59_bore;
  wire  [338:0] g_XSCore__gatewayIn_packed_60_bore;
  wire  [338:0] i_XSCore__gatewayIn_packed_60_bore;
  logic [338:0] p_XSCore__gatewayIn_packed_60_bore;
  bit   t_XSCore__gatewayIn_packed_60_bore;
  XSCore u_g_XSCore (
    .clock (clock),
    .reset (reset),
    .auto_memBlock_inner_buffers_out_a_ready (XSCore__auto_memBlock_inner_buffers_out_a_ready),
    .auto_memBlock_inner_buffers_out_a_valid (g_XSCore__auto_memBlock_inner_buffers_out_a_valid),
    .auto_memBlock_inner_buffers_out_a_bits_opcode (g_XSCore__auto_memBlock_inner_buffers_out_a_bits_opcode),
    .auto_memBlock_inner_buffers_out_a_bits_param (g_XSCore__auto_memBlock_inner_buffers_out_a_bits_param),
    .auto_memBlock_inner_buffers_out_a_bits_size (g_XSCore__auto_memBlock_inner_buffers_out_a_bits_size),
    .auto_memBlock_inner_buffers_out_a_bits_source (g_XSCore__auto_memBlock_inner_buffers_out_a_bits_source),
    .auto_memBlock_inner_buffers_out_a_bits_address (g_XSCore__auto_memBlock_inner_buffers_out_a_bits_address),
    .auto_memBlock_inner_buffers_out_a_bits_user_memBackType_MM (g_XSCore__auto_memBlock_inner_buffers_out_a_bits_user_memBackType_MM),
    .auto_memBlock_inner_buffers_out_a_bits_user_memPageType_NC (g_XSCore__auto_memBlock_inner_buffers_out_a_bits_user_memPageType_NC),
    .auto_memBlock_inner_buffers_out_a_bits_mask (g_XSCore__auto_memBlock_inner_buffers_out_a_bits_mask),
    .auto_memBlock_inner_buffers_out_a_bits_data (g_XSCore__auto_memBlock_inner_buffers_out_a_bits_data),
    .auto_memBlock_inner_buffers_out_a_bits_corrupt (g_XSCore__auto_memBlock_inner_buffers_out_a_bits_corrupt),
    .auto_memBlock_inner_buffers_out_d_ready (g_XSCore__auto_memBlock_inner_buffers_out_d_ready),
    .auto_memBlock_inner_buffers_out_d_valid (XSCore__auto_memBlock_inner_buffers_out_d_valid),
    .auto_memBlock_inner_buffers_out_d_bits_opcode (XSCore__auto_memBlock_inner_buffers_out_d_bits_opcode),
    .auto_memBlock_inner_buffers_out_d_bits_param (XSCore__auto_memBlock_inner_buffers_out_d_bits_param),
    .auto_memBlock_inner_buffers_out_d_bits_size (XSCore__auto_memBlock_inner_buffers_out_d_bits_size),
    .auto_memBlock_inner_buffers_out_d_bits_source (XSCore__auto_memBlock_inner_buffers_out_d_bits_source),
    .auto_memBlock_inner_buffers_out_d_bits_sink (XSCore__auto_memBlock_inner_buffers_out_d_bits_sink),
    .auto_memBlock_inner_buffers_out_d_bits_denied (XSCore__auto_memBlock_inner_buffers_out_d_bits_denied),
    .auto_memBlock_inner_buffers_out_d_bits_data (XSCore__auto_memBlock_inner_buffers_out_d_bits_data),
    .auto_memBlock_inner_buffers_out_d_bits_corrupt (XSCore__auto_memBlock_inner_buffers_out_d_bits_corrupt),
    .auto_memBlock_inner_frontendBridge_instr_uncache_out_a_ready (XSCore__auto_memBlock_inner_frontendBridge_instr_uncache_out_a_ready),
    .auto_memBlock_inner_frontendBridge_instr_uncache_out_a_valid (g_XSCore__auto_memBlock_inner_frontendBridge_instr_uncache_out_a_valid),
    .auto_memBlock_inner_frontendBridge_instr_uncache_out_a_bits_param (g_XSCore__auto_memBlock_inner_frontendBridge_instr_uncache_out_a_bits_param),
    .auto_memBlock_inner_frontendBridge_instr_uncache_out_a_bits_address (g_XSCore__auto_memBlock_inner_frontendBridge_instr_uncache_out_a_bits_address),
    .auto_memBlock_inner_frontendBridge_instr_uncache_out_a_bits_user_memPageType_NC (g_XSCore__auto_memBlock_inner_frontendBridge_instr_uncache_out_a_bits_user_memPageType_NC),
    .auto_memBlock_inner_frontendBridge_instr_uncache_out_a_bits_user_memBackType_MM (g_XSCore__auto_memBlock_inner_frontendBridge_instr_uncache_out_a_bits_user_memBackType_MM),
    .auto_memBlock_inner_frontendBridge_instr_uncache_out_a_bits_corrupt (g_XSCore__auto_memBlock_inner_frontendBridge_instr_uncache_out_a_bits_corrupt),
    .auto_memBlock_inner_frontendBridge_instr_uncache_out_d_ready (g_XSCore__auto_memBlock_inner_frontendBridge_instr_uncache_out_d_ready),
    .auto_memBlock_inner_frontendBridge_instr_uncache_out_d_valid (XSCore__auto_memBlock_inner_frontendBridge_instr_uncache_out_d_valid),
    .auto_memBlock_inner_frontendBridge_instr_uncache_out_d_bits_opcode (XSCore__auto_memBlock_inner_frontendBridge_instr_uncache_out_d_bits_opcode),
    .auto_memBlock_inner_frontendBridge_instr_uncache_out_d_bits_param (XSCore__auto_memBlock_inner_frontendBridge_instr_uncache_out_d_bits_param),
    .auto_memBlock_inner_frontendBridge_instr_uncache_out_d_bits_size (XSCore__auto_memBlock_inner_frontendBridge_instr_uncache_out_d_bits_size),
    .auto_memBlock_inner_frontendBridge_instr_uncache_out_d_bits_source (XSCore__auto_memBlock_inner_frontendBridge_instr_uncache_out_d_bits_source),
    .auto_memBlock_inner_frontendBridge_instr_uncache_out_d_bits_sink (XSCore__auto_memBlock_inner_frontendBridge_instr_uncache_out_d_bits_sink),
    .auto_memBlock_inner_frontendBridge_instr_uncache_out_d_bits_denied (XSCore__auto_memBlock_inner_frontendBridge_instr_uncache_out_d_bits_denied),
    .auto_memBlock_inner_frontendBridge_instr_uncache_out_d_bits_data (XSCore__auto_memBlock_inner_frontendBridge_instr_uncache_out_d_bits_data),
    .auto_memBlock_inner_frontendBridge_instr_uncache_out_d_bits_corrupt (XSCore__auto_memBlock_inner_frontendBridge_instr_uncache_out_d_bits_corrupt),
    .auto_memBlock_inner_frontendBridge_icachectrl_in_a_ready (g_XSCore__auto_memBlock_inner_frontendBridge_icachectrl_in_a_ready),
    .auto_memBlock_inner_frontendBridge_icachectrl_in_a_valid (XSCore__auto_memBlock_inner_frontendBridge_icachectrl_in_a_valid),
    .auto_memBlock_inner_frontendBridge_icachectrl_in_a_bits_opcode (XSCore__auto_memBlock_inner_frontendBridge_icachectrl_in_a_bits_opcode),
    .auto_memBlock_inner_frontendBridge_icachectrl_in_a_bits_param (XSCore__auto_memBlock_inner_frontendBridge_icachectrl_in_a_bits_param),
    .auto_memBlock_inner_frontendBridge_icachectrl_in_a_bits_size (XSCore__auto_memBlock_inner_frontendBridge_icachectrl_in_a_bits_size),
    .auto_memBlock_inner_frontendBridge_icachectrl_in_a_bits_source (XSCore__auto_memBlock_inner_frontendBridge_icachectrl_in_a_bits_source),
    .auto_memBlock_inner_frontendBridge_icachectrl_in_a_bits_address (XSCore__auto_memBlock_inner_frontendBridge_icachectrl_in_a_bits_address),
    .auto_memBlock_inner_frontendBridge_icachectrl_in_a_bits_mask (XSCore__auto_memBlock_inner_frontendBridge_icachectrl_in_a_bits_mask),
    .auto_memBlock_inner_frontendBridge_icachectrl_in_a_bits_data (XSCore__auto_memBlock_inner_frontendBridge_icachectrl_in_a_bits_data),
    .auto_memBlock_inner_frontendBridge_icachectrl_in_a_bits_corrupt (XSCore__auto_memBlock_inner_frontendBridge_icachectrl_in_a_bits_corrupt),
    .auto_memBlock_inner_frontendBridge_icachectrl_in_d_ready (XSCore__auto_memBlock_inner_frontendBridge_icachectrl_in_d_ready),
    .auto_memBlock_inner_frontendBridge_icachectrl_in_d_valid (g_XSCore__auto_memBlock_inner_frontendBridge_icachectrl_in_d_valid),
    .auto_memBlock_inner_frontendBridge_icachectrl_in_d_bits_opcode (g_XSCore__auto_memBlock_inner_frontendBridge_icachectrl_in_d_bits_opcode),
    .auto_memBlock_inner_frontendBridge_icachectrl_in_d_bits_param (g_XSCore__auto_memBlock_inner_frontendBridge_icachectrl_in_d_bits_param),
    .auto_memBlock_inner_frontendBridge_icachectrl_in_d_bits_size (g_XSCore__auto_memBlock_inner_frontendBridge_icachectrl_in_d_bits_size),
    .auto_memBlock_inner_frontendBridge_icachectrl_in_d_bits_source (g_XSCore__auto_memBlock_inner_frontendBridge_icachectrl_in_d_bits_source),
    .auto_memBlock_inner_frontendBridge_icachectrl_in_d_bits_sink (g_XSCore__auto_memBlock_inner_frontendBridge_icachectrl_in_d_bits_sink),
    .auto_memBlock_inner_frontendBridge_icachectrl_in_d_bits_denied (g_XSCore__auto_memBlock_inner_frontendBridge_icachectrl_in_d_bits_denied),
    .auto_memBlock_inner_frontendBridge_icachectrl_in_d_bits_data (g_XSCore__auto_memBlock_inner_frontendBridge_icachectrl_in_d_bits_data),
    .auto_memBlock_inner_frontendBridge_icachectrl_in_d_bits_corrupt (g_XSCore__auto_memBlock_inner_frontendBridge_icachectrl_in_d_bits_corrupt),
    .auto_memBlock_inner_frontendBridge_icache_out_a_ready (XSCore__auto_memBlock_inner_frontendBridge_icache_out_a_ready),
    .auto_memBlock_inner_frontendBridge_icache_out_a_valid (g_XSCore__auto_memBlock_inner_frontendBridge_icache_out_a_valid),
    .auto_memBlock_inner_frontendBridge_icache_out_a_bits_opcode (g_XSCore__auto_memBlock_inner_frontendBridge_icache_out_a_bits_opcode),
    .auto_memBlock_inner_frontendBridge_icache_out_a_bits_param (g_XSCore__auto_memBlock_inner_frontendBridge_icache_out_a_bits_param),
    .auto_memBlock_inner_frontendBridge_icache_out_a_bits_size (g_XSCore__auto_memBlock_inner_frontendBridge_icache_out_a_bits_size),
    .auto_memBlock_inner_frontendBridge_icache_out_a_bits_source (g_XSCore__auto_memBlock_inner_frontendBridge_icache_out_a_bits_source),
    .auto_memBlock_inner_frontendBridge_icache_out_a_bits_address (g_XSCore__auto_memBlock_inner_frontendBridge_icache_out_a_bits_address),
    .auto_memBlock_inner_frontendBridge_icache_out_a_bits_user_alias (g_XSCore__auto_memBlock_inner_frontendBridge_icache_out_a_bits_user_alias),
    .auto_memBlock_inner_frontendBridge_icache_out_a_bits_user_reqSource (g_XSCore__auto_memBlock_inner_frontendBridge_icache_out_a_bits_user_reqSource),
    .auto_memBlock_inner_frontendBridge_icache_out_a_bits_user_needHint (g_XSCore__auto_memBlock_inner_frontendBridge_icache_out_a_bits_user_needHint),
    .auto_memBlock_inner_frontendBridge_icache_out_a_bits_mask (g_XSCore__auto_memBlock_inner_frontendBridge_icache_out_a_bits_mask),
    .auto_memBlock_inner_frontendBridge_icache_out_a_bits_data (g_XSCore__auto_memBlock_inner_frontendBridge_icache_out_a_bits_data),
    .auto_memBlock_inner_frontendBridge_icache_out_a_bits_corrupt (g_XSCore__auto_memBlock_inner_frontendBridge_icache_out_a_bits_corrupt),
    .auto_memBlock_inner_frontendBridge_icache_out_d_ready (g_XSCore__auto_memBlock_inner_frontendBridge_icache_out_d_ready),
    .auto_memBlock_inner_frontendBridge_icache_out_d_valid (XSCore__auto_memBlock_inner_frontendBridge_icache_out_d_valid),
    .auto_memBlock_inner_frontendBridge_icache_out_d_bits_opcode (XSCore__auto_memBlock_inner_frontendBridge_icache_out_d_bits_opcode),
    .auto_memBlock_inner_frontendBridge_icache_out_d_bits_param (XSCore__auto_memBlock_inner_frontendBridge_icache_out_d_bits_param),
    .auto_memBlock_inner_frontendBridge_icache_out_d_bits_size (XSCore__auto_memBlock_inner_frontendBridge_icache_out_d_bits_size),
    .auto_memBlock_inner_frontendBridge_icache_out_d_bits_source (XSCore__auto_memBlock_inner_frontendBridge_icache_out_d_bits_source),
    .auto_memBlock_inner_frontendBridge_icache_out_d_bits_sink (XSCore__auto_memBlock_inner_frontendBridge_icache_out_d_bits_sink),
    .auto_memBlock_inner_frontendBridge_icache_out_d_bits_denied (XSCore__auto_memBlock_inner_frontendBridge_icache_out_d_bits_denied),
    .auto_memBlock_inner_frontendBridge_icache_out_d_bits_data (XSCore__auto_memBlock_inner_frontendBridge_icache_out_d_bits_data),
    .auto_memBlock_inner_frontendBridge_icache_out_d_bits_corrupt (XSCore__auto_memBlock_inner_frontendBridge_icache_out_d_bits_corrupt),
    .auto_memBlock_inner_ptw_to_l2_buffer_out_a_ready (XSCore__auto_memBlock_inner_ptw_to_l2_buffer_out_a_ready),
    .auto_memBlock_inner_ptw_to_l2_buffer_out_a_valid (g_XSCore__auto_memBlock_inner_ptw_to_l2_buffer_out_a_valid),
    .auto_memBlock_inner_ptw_to_l2_buffer_out_a_bits_opcode (g_XSCore__auto_memBlock_inner_ptw_to_l2_buffer_out_a_bits_opcode),
    .auto_memBlock_inner_ptw_to_l2_buffer_out_a_bits_param (g_XSCore__auto_memBlock_inner_ptw_to_l2_buffer_out_a_bits_param),
    .auto_memBlock_inner_ptw_to_l2_buffer_out_a_bits_size (g_XSCore__auto_memBlock_inner_ptw_to_l2_buffer_out_a_bits_size),
    .auto_memBlock_inner_ptw_to_l2_buffer_out_a_bits_source (g_XSCore__auto_memBlock_inner_ptw_to_l2_buffer_out_a_bits_source),
    .auto_memBlock_inner_ptw_to_l2_buffer_out_a_bits_address (g_XSCore__auto_memBlock_inner_ptw_to_l2_buffer_out_a_bits_address),
    .auto_memBlock_inner_ptw_to_l2_buffer_out_a_bits_user_reqSource (g_XSCore__auto_memBlock_inner_ptw_to_l2_buffer_out_a_bits_user_reqSource),
    .auto_memBlock_inner_ptw_to_l2_buffer_out_a_bits_mask (g_XSCore__auto_memBlock_inner_ptw_to_l2_buffer_out_a_bits_mask),
    .auto_memBlock_inner_ptw_to_l2_buffer_out_a_bits_data (g_XSCore__auto_memBlock_inner_ptw_to_l2_buffer_out_a_bits_data),
    .auto_memBlock_inner_ptw_to_l2_buffer_out_a_bits_corrupt (g_XSCore__auto_memBlock_inner_ptw_to_l2_buffer_out_a_bits_corrupt),
    .auto_memBlock_inner_ptw_to_l2_buffer_out_d_ready (g_XSCore__auto_memBlock_inner_ptw_to_l2_buffer_out_d_ready),
    .auto_memBlock_inner_ptw_to_l2_buffer_out_d_valid (XSCore__auto_memBlock_inner_ptw_to_l2_buffer_out_d_valid),
    .auto_memBlock_inner_ptw_to_l2_buffer_out_d_bits_opcode (XSCore__auto_memBlock_inner_ptw_to_l2_buffer_out_d_bits_opcode),
    .auto_memBlock_inner_ptw_to_l2_buffer_out_d_bits_param (XSCore__auto_memBlock_inner_ptw_to_l2_buffer_out_d_bits_param),
    .auto_memBlock_inner_ptw_to_l2_buffer_out_d_bits_size (XSCore__auto_memBlock_inner_ptw_to_l2_buffer_out_d_bits_size),
    .auto_memBlock_inner_ptw_to_l2_buffer_out_d_bits_source (XSCore__auto_memBlock_inner_ptw_to_l2_buffer_out_d_bits_source),
    .auto_memBlock_inner_ptw_to_l2_buffer_out_d_bits_sink (XSCore__auto_memBlock_inner_ptw_to_l2_buffer_out_d_bits_sink),
    .auto_memBlock_inner_ptw_to_l2_buffer_out_d_bits_denied (XSCore__auto_memBlock_inner_ptw_to_l2_buffer_out_d_bits_denied),
    .auto_memBlock_inner_ptw_to_l2_buffer_out_d_bits_data (XSCore__auto_memBlock_inner_ptw_to_l2_buffer_out_d_bits_data),
    .auto_memBlock_inner_ptw_to_l2_buffer_out_d_bits_corrupt (XSCore__auto_memBlock_inner_ptw_to_l2_buffer_out_d_bits_corrupt),
    .auto_memBlock_inner_beu_local_int_sink_in_0 (XSCore__auto_memBlock_inner_beu_local_int_sink_in_0),
    .auto_memBlock_inner_nmi_int_sink_in_0 (XSCore__auto_memBlock_inner_nmi_int_sink_in_0),
    .auto_memBlock_inner_nmi_int_sink_in_1 (XSCore__auto_memBlock_inner_nmi_int_sink_in_1),
    .auto_memBlock_inner_plic_int_sink_in_1_0 (XSCore__auto_memBlock_inner_plic_int_sink_in_1_0),
    .auto_memBlock_inner_plic_int_sink_in_0_0 (XSCore__auto_memBlock_inner_plic_int_sink_in_0_0),
    .auto_memBlock_inner_debug_int_sink_in_0 (XSCore__auto_memBlock_inner_debug_int_sink_in_0),
    .auto_memBlock_inner_clint_int_sink_in_0 (XSCore__auto_memBlock_inner_clint_int_sink_in_0),
    .auto_memBlock_inner_clint_int_sink_in_1 (XSCore__auto_memBlock_inner_clint_int_sink_in_1),
    .auto_memBlock_inner_l2_pf_sender_out_addr (g_XSCore__auto_memBlock_inner_l2_pf_sender_out_addr),
    .auto_memBlock_inner_l2_pf_sender_out_pf_source (g_XSCore__auto_memBlock_inner_l2_pf_sender_out_pf_source),
    .auto_memBlock_inner_l2_pf_sender_out_addr_valid (g_XSCore__auto_memBlock_inner_l2_pf_sender_out_addr_valid),
    .auto_memBlock_inner_dcache_client_out_a_ready (XSCore__auto_memBlock_inner_dcache_client_out_a_ready),
    .auto_memBlock_inner_dcache_client_out_a_valid (g_XSCore__auto_memBlock_inner_dcache_client_out_a_valid),
    .auto_memBlock_inner_dcache_client_out_a_bits_opcode (g_XSCore__auto_memBlock_inner_dcache_client_out_a_bits_opcode),
    .auto_memBlock_inner_dcache_client_out_a_bits_param (g_XSCore__auto_memBlock_inner_dcache_client_out_a_bits_param),
    .auto_memBlock_inner_dcache_client_out_a_bits_size (g_XSCore__auto_memBlock_inner_dcache_client_out_a_bits_size),
    .auto_memBlock_inner_dcache_client_out_a_bits_source (g_XSCore__auto_memBlock_inner_dcache_client_out_a_bits_source),
    .auto_memBlock_inner_dcache_client_out_a_bits_address (g_XSCore__auto_memBlock_inner_dcache_client_out_a_bits_address),
    .auto_memBlock_inner_dcache_client_out_a_bits_user_alias (g_XSCore__auto_memBlock_inner_dcache_client_out_a_bits_user_alias),
    .auto_memBlock_inner_dcache_client_out_a_bits_user_vaddr (g_XSCore__auto_memBlock_inner_dcache_client_out_a_bits_user_vaddr),
    .auto_memBlock_inner_dcache_client_out_a_bits_user_reqSource (g_XSCore__auto_memBlock_inner_dcache_client_out_a_bits_user_reqSource),
    .auto_memBlock_inner_dcache_client_out_a_bits_user_needHint (g_XSCore__auto_memBlock_inner_dcache_client_out_a_bits_user_needHint),
    .auto_memBlock_inner_dcache_client_out_a_bits_echo_isKeyword (g_XSCore__auto_memBlock_inner_dcache_client_out_a_bits_echo_isKeyword),
    .auto_memBlock_inner_dcache_client_out_a_bits_mask (g_XSCore__auto_memBlock_inner_dcache_client_out_a_bits_mask),
    .auto_memBlock_inner_dcache_client_out_a_bits_data (g_XSCore__auto_memBlock_inner_dcache_client_out_a_bits_data),
    .auto_memBlock_inner_dcache_client_out_a_bits_corrupt (g_XSCore__auto_memBlock_inner_dcache_client_out_a_bits_corrupt),
    .auto_memBlock_inner_dcache_client_out_b_ready (g_XSCore__auto_memBlock_inner_dcache_client_out_b_ready),
    .auto_memBlock_inner_dcache_client_out_b_valid (XSCore__auto_memBlock_inner_dcache_client_out_b_valid),
    .auto_memBlock_inner_dcache_client_out_b_bits_opcode (XSCore__auto_memBlock_inner_dcache_client_out_b_bits_opcode),
    .auto_memBlock_inner_dcache_client_out_b_bits_param (XSCore__auto_memBlock_inner_dcache_client_out_b_bits_param),
    .auto_memBlock_inner_dcache_client_out_b_bits_size (XSCore__auto_memBlock_inner_dcache_client_out_b_bits_size),
    .auto_memBlock_inner_dcache_client_out_b_bits_source (XSCore__auto_memBlock_inner_dcache_client_out_b_bits_source),
    .auto_memBlock_inner_dcache_client_out_b_bits_address (XSCore__auto_memBlock_inner_dcache_client_out_b_bits_address),
    .auto_memBlock_inner_dcache_client_out_b_bits_mask (XSCore__auto_memBlock_inner_dcache_client_out_b_bits_mask),
    .auto_memBlock_inner_dcache_client_out_b_bits_data (XSCore__auto_memBlock_inner_dcache_client_out_b_bits_data),
    .auto_memBlock_inner_dcache_client_out_b_bits_corrupt (XSCore__auto_memBlock_inner_dcache_client_out_b_bits_corrupt),
    .auto_memBlock_inner_dcache_client_out_c_ready (XSCore__auto_memBlock_inner_dcache_client_out_c_ready),
    .auto_memBlock_inner_dcache_client_out_c_valid (g_XSCore__auto_memBlock_inner_dcache_client_out_c_valid),
    .auto_memBlock_inner_dcache_client_out_c_bits_opcode (g_XSCore__auto_memBlock_inner_dcache_client_out_c_bits_opcode),
    .auto_memBlock_inner_dcache_client_out_c_bits_param (g_XSCore__auto_memBlock_inner_dcache_client_out_c_bits_param),
    .auto_memBlock_inner_dcache_client_out_c_bits_size (g_XSCore__auto_memBlock_inner_dcache_client_out_c_bits_size),
    .auto_memBlock_inner_dcache_client_out_c_bits_source (g_XSCore__auto_memBlock_inner_dcache_client_out_c_bits_source),
    .auto_memBlock_inner_dcache_client_out_c_bits_address (g_XSCore__auto_memBlock_inner_dcache_client_out_c_bits_address),
    .auto_memBlock_inner_dcache_client_out_c_bits_user_alias (g_XSCore__auto_memBlock_inner_dcache_client_out_c_bits_user_alias),
    .auto_memBlock_inner_dcache_client_out_c_bits_user_vaddr (g_XSCore__auto_memBlock_inner_dcache_client_out_c_bits_user_vaddr),
    .auto_memBlock_inner_dcache_client_out_c_bits_user_reqSource (g_XSCore__auto_memBlock_inner_dcache_client_out_c_bits_user_reqSource),
    .auto_memBlock_inner_dcache_client_out_c_bits_user_needHint (g_XSCore__auto_memBlock_inner_dcache_client_out_c_bits_user_needHint),
    .auto_memBlock_inner_dcache_client_out_c_bits_echo_isKeyword (g_XSCore__auto_memBlock_inner_dcache_client_out_c_bits_echo_isKeyword),
    .auto_memBlock_inner_dcache_client_out_c_bits_data (g_XSCore__auto_memBlock_inner_dcache_client_out_c_bits_data),
    .auto_memBlock_inner_dcache_client_out_c_bits_corrupt (g_XSCore__auto_memBlock_inner_dcache_client_out_c_bits_corrupt),
    .auto_memBlock_inner_dcache_client_out_d_ready (g_XSCore__auto_memBlock_inner_dcache_client_out_d_ready),
    .auto_memBlock_inner_dcache_client_out_d_valid (XSCore__auto_memBlock_inner_dcache_client_out_d_valid),
    .auto_memBlock_inner_dcache_client_out_d_bits_opcode (XSCore__auto_memBlock_inner_dcache_client_out_d_bits_opcode),
    .auto_memBlock_inner_dcache_client_out_d_bits_param (XSCore__auto_memBlock_inner_dcache_client_out_d_bits_param),
    .auto_memBlock_inner_dcache_client_out_d_bits_size (XSCore__auto_memBlock_inner_dcache_client_out_d_bits_size),
    .auto_memBlock_inner_dcache_client_out_d_bits_source (XSCore__auto_memBlock_inner_dcache_client_out_d_bits_source),
    .auto_memBlock_inner_dcache_client_out_d_bits_sink (XSCore__auto_memBlock_inner_dcache_client_out_d_bits_sink),
    .auto_memBlock_inner_dcache_client_out_d_bits_denied (XSCore__auto_memBlock_inner_dcache_client_out_d_bits_denied),
    .auto_memBlock_inner_dcache_client_out_d_bits_echo_isKeyword (XSCore__auto_memBlock_inner_dcache_client_out_d_bits_echo_isKeyword),
    .auto_memBlock_inner_dcache_client_out_d_bits_data (XSCore__auto_memBlock_inner_dcache_client_out_d_bits_data),
    .auto_memBlock_inner_dcache_client_out_d_bits_corrupt (XSCore__auto_memBlock_inner_dcache_client_out_d_bits_corrupt),
    .auto_memBlock_inner_dcache_client_out_e_ready (XSCore__auto_memBlock_inner_dcache_client_out_e_ready),
    .auto_memBlock_inner_dcache_client_out_e_valid (g_XSCore__auto_memBlock_inner_dcache_client_out_e_valid),
    .auto_memBlock_inner_dcache_client_out_e_bits_sink (g_XSCore__auto_memBlock_inner_dcache_client_out_e_bits_sink),
    .io_hartId (XSCore__io_hartId),
    .io_msiInfo_valid (XSCore__io_msiInfo_valid),
    .io_msiInfo_bits (XSCore__io_msiInfo_bits),
    .io_msiAck (g_XSCore__io_msiAck),
    .io_clintTime_valid (XSCore__io_clintTime_valid),
    .io_clintTime_bits (XSCore__io_clintTime_bits),
    .io_reset_vector (XSCore__io_reset_vector),
    .io_cpu_halt (g_XSCore__io_cpu_halt),
    .io_l2_flush_done (XSCore__io_l2_flush_done),
    .io_l2_flush_en (g_XSCore__io_l2_flush_en),
    .io_power_down_en (g_XSCore__io_power_down_en),
    .io_cpu_critical_error (g_XSCore__io_cpu_critical_error),
    .io_resetInFrontend (g_XSCore__io_resetInFrontend),
    .io_traceCoreInterface_fromEncoder_enable (XSCore__io_traceCoreInterface_fromEncoder_enable),
    .io_traceCoreInterface_fromEncoder_stall (XSCore__io_traceCoreInterface_fromEncoder_stall),
    .io_traceCoreInterface_toEncoder_priv (g_XSCore__io_traceCoreInterface_toEncoder_priv),
    .io_traceCoreInterface_toEncoder_mstatus (g_XSCore__io_traceCoreInterface_toEncoder_mstatus),
    .io_traceCoreInterface_toEncoder_trap_cause (g_XSCore__io_traceCoreInterface_toEncoder_trap_cause),
    .io_traceCoreInterface_toEncoder_trap_tval (g_XSCore__io_traceCoreInterface_toEncoder_trap_tval),
    .io_traceCoreInterface_toEncoder_groups_0_valid (g_XSCore__io_traceCoreInterface_toEncoder_groups_0_valid),
    .io_traceCoreInterface_toEncoder_groups_0_bits_iaddr (g_XSCore__io_traceCoreInterface_toEncoder_groups_0_bits_iaddr),
    .io_traceCoreInterface_toEncoder_groups_0_bits_itype (g_XSCore__io_traceCoreInterface_toEncoder_groups_0_bits_itype),
    .io_traceCoreInterface_toEncoder_groups_0_bits_iretire (g_XSCore__io_traceCoreInterface_toEncoder_groups_0_bits_iretire),
    .io_traceCoreInterface_toEncoder_groups_0_bits_ilastsize (g_XSCore__io_traceCoreInterface_toEncoder_groups_0_bits_ilastsize),
    .io_traceCoreInterface_toEncoder_groups_1_valid (g_XSCore__io_traceCoreInterface_toEncoder_groups_1_valid),
    .io_traceCoreInterface_toEncoder_groups_1_bits_iaddr (g_XSCore__io_traceCoreInterface_toEncoder_groups_1_bits_iaddr),
    .io_traceCoreInterface_toEncoder_groups_1_bits_itype (g_XSCore__io_traceCoreInterface_toEncoder_groups_1_bits_itype),
    .io_traceCoreInterface_toEncoder_groups_1_bits_iretire (g_XSCore__io_traceCoreInterface_toEncoder_groups_1_bits_iretire),
    .io_traceCoreInterface_toEncoder_groups_1_bits_ilastsize (g_XSCore__io_traceCoreInterface_toEncoder_groups_1_bits_ilastsize),
    .io_traceCoreInterface_toEncoder_groups_2_valid (g_XSCore__io_traceCoreInterface_toEncoder_groups_2_valid),
    .io_traceCoreInterface_toEncoder_groups_2_bits_iaddr (g_XSCore__io_traceCoreInterface_toEncoder_groups_2_bits_iaddr),
    .io_traceCoreInterface_toEncoder_groups_2_bits_itype (g_XSCore__io_traceCoreInterface_toEncoder_groups_2_bits_itype),
    .io_traceCoreInterface_toEncoder_groups_2_bits_iretire (g_XSCore__io_traceCoreInterface_toEncoder_groups_2_bits_iretire),
    .io_traceCoreInterface_toEncoder_groups_2_bits_ilastsize (g_XSCore__io_traceCoreInterface_toEncoder_groups_2_bits_ilastsize),
    .io_l2PfCtrl_l2_pf_master_en (g_XSCore__io_l2PfCtrl_l2_pf_master_en),
    .io_l2PfCtrl_l2_pf_recv_en (g_XSCore__io_l2PfCtrl_l2_pf_recv_en),
    .io_l2PfCtrl_l2_pbop_en (g_XSCore__io_l2PfCtrl_l2_pbop_en),
    .io_l2PfCtrl_l2_vbop_en (g_XSCore__io_l2PfCtrl_l2_vbop_en),
    .io_l2PfCtrl_l2_pf_delay_latency (g_XSCore__io_l2PfCtrl_l2_pf_delay_latency),
    .io_perfEvents_1_value (XSCore__io_perfEvents_1_value),
    .io_perfEvents_2_value (XSCore__io_perfEvents_2_value),
    .io_perfEvents_3_value (XSCore__io_perfEvents_3_value),
    .io_perfEvents_4_value (XSCore__io_perfEvents_4_value),
    .io_perfEvents_5_value (XSCore__io_perfEvents_5_value),
    .io_perfEvents_6_value (XSCore__io_perfEvents_6_value),
    .io_perfEvents_7_value (XSCore__io_perfEvents_7_value),
    .io_perfEvents_8_value (XSCore__io_perfEvents_8_value),
    .io_perfEvents_9_value (XSCore__io_perfEvents_9_value),
    .io_perfEvents_10_value (XSCore__io_perfEvents_10_value),
    .io_perfEvents_11_value (XSCore__io_perfEvents_11_value),
    .io_perfEvents_12_value (XSCore__io_perfEvents_12_value),
    .io_perfEvents_13_value (XSCore__io_perfEvents_13_value),
    .io_perfEvents_14_value (XSCore__io_perfEvents_14_value),
    .io_perfEvents_15_value (XSCore__io_perfEvents_15_value),
    .io_perfEvents_16_value (XSCore__io_perfEvents_16_value),
    .io_perfEvents_17_value (XSCore__io_perfEvents_17_value),
    .io_perfEvents_18_value (XSCore__io_perfEvents_18_value),
    .io_perfEvents_19_value (XSCore__io_perfEvents_19_value),
    .io_perfEvents_20_value (XSCore__io_perfEvents_20_value),
    .io_perfEvents_21_value (XSCore__io_perfEvents_21_value),
    .io_perfEvents_22_value (XSCore__io_perfEvents_22_value),
    .io_perfEvents_23_value (XSCore__io_perfEvents_23_value),
    .io_perfEvents_24_value (XSCore__io_perfEvents_24_value),
    .io_perfEvents_25_value (XSCore__io_perfEvents_25_value),
    .io_perfEvents_26_value (XSCore__io_perfEvents_26_value),
    .io_perfEvents_27_value (XSCore__io_perfEvents_27_value),
    .io_perfEvents_28_value (XSCore__io_perfEvents_28_value),
    .io_perfEvents_29_value (XSCore__io_perfEvents_29_value),
    .io_perfEvents_30_value (XSCore__io_perfEvents_30_value),
    .io_perfEvents_31_value (XSCore__io_perfEvents_31_value),
    .io_perfEvents_32_value (XSCore__io_perfEvents_32_value),
    .io_perfEvents_33_value (XSCore__io_perfEvents_33_value),
    .io_perfEvents_34_value (XSCore__io_perfEvents_34_value),
    .io_perfEvents_35_value (XSCore__io_perfEvents_35_value),
    .io_perfEvents_36_value (XSCore__io_perfEvents_36_value),
    .io_perfEvents_37_value (XSCore__io_perfEvents_37_value),
    .io_perfEvents_38_value (XSCore__io_perfEvents_38_value),
    .io_perfEvents_39_value (XSCore__io_perfEvents_39_value),
    .io_perfEvents_40_value (XSCore__io_perfEvents_40_value),
    .io_perfEvents_41_value (XSCore__io_perfEvents_41_value),
    .io_perfEvents_42_value (XSCore__io_perfEvents_42_value),
    .io_perfEvents_43_value (XSCore__io_perfEvents_43_value),
    .io_perfEvents_44_value (XSCore__io_perfEvents_44_value),
    .io_perfEvents_45_value (XSCore__io_perfEvents_45_value),
    .io_perfEvents_46_value (XSCore__io_perfEvents_46_value),
    .io_perfEvents_47_value (XSCore__io_perfEvents_47_value),
    .io_perfEvents_48_value (XSCore__io_perfEvents_48_value),
    .io_perfEvents_49_value (XSCore__io_perfEvents_49_value),
    .io_perfEvents_50_value (XSCore__io_perfEvents_50_value),
    .io_perfEvents_51_value (XSCore__io_perfEvents_51_value),
    .io_perfEvents_52_value (XSCore__io_perfEvents_52_value),
    .io_perfEvents_53_value (XSCore__io_perfEvents_53_value),
    .io_perfEvents_54_value (XSCore__io_perfEvents_54_value),
    .io_perfEvents_55_value (XSCore__io_perfEvents_55_value),
    .io_perfEvents_56_value (XSCore__io_perfEvents_56_value),
    .io_perfEvents_57_value (XSCore__io_perfEvents_57_value),
    .io_perfEvents_58_value (XSCore__io_perfEvents_58_value),
    .io_perfEvents_59_value (XSCore__io_perfEvents_59_value),
    .io_perfEvents_60_value (XSCore__io_perfEvents_60_value),
    .io_perfEvents_61_value (XSCore__io_perfEvents_61_value),
    .io_perfEvents_62_value (XSCore__io_perfEvents_62_value),
    .io_perfEvents_63_value (XSCore__io_perfEvents_63_value),
    .io_perfEvents_64_value (XSCore__io_perfEvents_64_value),
    .io_perfEvents_65_value (XSCore__io_perfEvents_65_value),
    .io_perfEvents_66_value (XSCore__io_perfEvents_66_value),
    .io_perfEvents_67_value (XSCore__io_perfEvents_67_value),
    .io_perfEvents_68_value (XSCore__io_perfEvents_68_value),
    .io_beu_errors_icache_ecc_error_valid (g_XSCore__io_beu_errors_icache_ecc_error_valid),
    .io_beu_errors_icache_ecc_error_bits (g_XSCore__io_beu_errors_icache_ecc_error_bits),
    .io_beu_errors_dcache_ecc_error_valid (g_XSCore__io_beu_errors_dcache_ecc_error_valid),
    .io_beu_errors_dcache_ecc_error_bits (g_XSCore__io_beu_errors_dcache_ecc_error_bits),
    .io_beu_errors_uncache_ecc_error_valid (g_XSCore__io_beu_errors_uncache_ecc_error_valid),
    .io_beu_errors_uncache_ecc_error_bits (g_XSCore__io_beu_errors_uncache_ecc_error_bits),
    .io_l2_hint_valid (XSCore__io_l2_hint_valid),
    .io_l2_hint_bits_sourceId (XSCore__io_l2_hint_bits_sourceId),
    .io_l2_hint_bits_isKeyword (XSCore__io_l2_hint_bits_isKeyword),
    .io_l2_tlb_req_req_valid (XSCore__io_l2_tlb_req_req_valid),
    .io_l2_tlb_req_req_bits_vaddr (XSCore__io_l2_tlb_req_req_bits_vaddr),
    .io_l2_tlb_req_req_bits_cmd (XSCore__io_l2_tlb_req_req_bits_cmd),
    .io_l2_tlb_req_req_bits_kill (XSCore__io_l2_tlb_req_req_bits_kill),
    .io_l2_tlb_req_req_bits_isPrefetch (XSCore__io_l2_tlb_req_req_bits_isPrefetch),
    .io_l2_tlb_req_req_bits_no_translate (XSCore__io_l2_tlb_req_req_bits_no_translate),
    .io_l2_tlb_req_resp_valid (g_XSCore__io_l2_tlb_req_resp_valid),
    .io_l2_tlb_req_resp_bits_paddr_0 (g_XSCore__io_l2_tlb_req_resp_bits_paddr_0),
    .io_l2_tlb_req_resp_bits_pbmt_0 (g_XSCore__io_l2_tlb_req_resp_bits_pbmt_0),
    .io_l2_tlb_req_resp_bits_miss (g_XSCore__io_l2_tlb_req_resp_bits_miss),
    .io_l2_tlb_req_resp_bits_excp_0_gpf_ld (g_XSCore__io_l2_tlb_req_resp_bits_excp_0_gpf_ld),
    .io_l2_tlb_req_resp_bits_excp_0_pf_ld (g_XSCore__io_l2_tlb_req_resp_bits_excp_0_pf_ld),
    .io_l2_tlb_req_resp_bits_excp_0_af_ld (g_XSCore__io_l2_tlb_req_resp_bits_excp_0_af_ld),
    .io_l2_pmp_resp_ld (g_XSCore__io_l2_pmp_resp_ld),
    .io_l2_pmp_resp_mmio (g_XSCore__io_l2_pmp_resp_mmio),
    .io_debugTopDown_robHeadPaddr_valid (g_XSCore__io_debugTopDown_robHeadPaddr_valid),
    .io_debugTopDown_robHeadPaddr_bits (g_XSCore__io_debugTopDown_robHeadPaddr_bits),
    .io_debugTopDown_l2MissMatch (XSCore__io_debugTopDown_l2MissMatch),
    .io_debugTopDown_l3MissMatch (XSCore__io_debugTopDown_l3MissMatch),
    .io_topDownInfo_l2Miss (XSCore__io_topDownInfo_l2Miss),
    .io_topDownInfo_l3Miss (XSCore__io_topDownInfo_l3Miss),
    .io_dft_ram_hold (XSCore__io_dft_ram_hold),
    .io_dft_ram_bypass (XSCore__io_dft_ram_bypass),
    .io_dft_ram_bp_clken (XSCore__io_dft_ram_bp_clken),
    .io_dft_ram_aux_clk (XSCore__io_dft_ram_aux_clk),
    .io_dft_ram_aux_ckbp (XSCore__io_dft_ram_aux_ckbp),
    .io_dft_ram_mcp_hold (XSCore__io_dft_ram_mcp_hold),
    .io_dft_cgen (XSCore__io_dft_cgen),
    .gatewayIn_packed_0_bore (g_XSCore__gatewayIn_packed_0_bore),
    .gatewayIn_packed_1_bore (g_XSCore__gatewayIn_packed_1_bore),
    .gatewayIn_packed_2_bore (g_XSCore__gatewayIn_packed_2_bore),
    .gatewayIn_packed_3_bore (g_XSCore__gatewayIn_packed_3_bore),
    .gatewayIn_packed_4_bore (g_XSCore__gatewayIn_packed_4_bore),
    .gatewayIn_packed_5_bore (g_XSCore__gatewayIn_packed_5_bore),
    .gatewayIn_packed_6_bore (g_XSCore__gatewayIn_packed_6_bore),
    .gatewayIn_packed_7_bore (g_XSCore__gatewayIn_packed_7_bore),
    .gatewayIn_packed_8_bore (g_XSCore__gatewayIn_packed_8_bore),
    .gatewayIn_packed_9_bore (g_XSCore__gatewayIn_packed_9_bore),
    .gatewayIn_packed_10_bore (g_XSCore__gatewayIn_packed_10_bore),
    .gatewayIn_packed_11_bore (g_XSCore__gatewayIn_packed_11_bore),
    .gatewayIn_packed_12_bore (g_XSCore__gatewayIn_packed_12_bore),
    .gatewayIn_packed_13_bore (g_XSCore__gatewayIn_packed_13_bore),
    .gatewayIn_packed_14_bore (g_XSCore__gatewayIn_packed_14_bore),
    .gatewayIn_packed_15_bore (g_XSCore__gatewayIn_packed_15_bore),
    .gatewayIn_packed_16_bore (g_XSCore__gatewayIn_packed_16_bore),
    .gatewayIn_packed_17_bore (g_XSCore__gatewayIn_packed_17_bore),
    .gatewayIn_packed_18_bore (g_XSCore__gatewayIn_packed_18_bore),
    .gatewayIn_packed_19_bore (g_XSCore__gatewayIn_packed_19_bore),
    .gatewayIn_packed_20_bore (g_XSCore__gatewayIn_packed_20_bore),
    .gatewayIn_packed_21_bore (g_XSCore__gatewayIn_packed_21_bore),
    .gatewayIn_packed_22_bore (g_XSCore__gatewayIn_packed_22_bore),
    .gatewayIn_packed_23_bore (g_XSCore__gatewayIn_packed_23_bore),
    .gatewayIn_packed_24_bore (g_XSCore__gatewayIn_packed_24_bore),
    .gatewayIn_packed_25_bore (g_XSCore__gatewayIn_packed_25_bore),
    .gatewayIn_packed_26_bore (g_XSCore__gatewayIn_packed_26_bore),
    .gatewayIn_packed_27_bore (g_XSCore__gatewayIn_packed_27_bore),
    .gatewayIn_packed_28_bore (g_XSCore__gatewayIn_packed_28_bore),
    .gatewayIn_packed_29_bore (g_XSCore__gatewayIn_packed_29_bore),
    .gatewayIn_packed_30_bore (g_XSCore__gatewayIn_packed_30_bore),
    .gatewayIn_packed_31_bore (g_XSCore__gatewayIn_packed_31_bore),
    .gatewayIn_packed_32_bore (g_XSCore__gatewayIn_packed_32_bore),
    .gatewayIn_packed_33_bore (g_XSCore__gatewayIn_packed_33_bore),
    .gatewayIn_packed_34_bore (g_XSCore__gatewayIn_packed_34_bore),
    .gatewayIn_packed_35_bore (g_XSCore__gatewayIn_packed_35_bore),
    .gatewayIn_packed_36_bore (g_XSCore__gatewayIn_packed_36_bore),
    .gatewayIn_packed_37_bore (g_XSCore__gatewayIn_packed_37_bore),
    .gatewayIn_packed_38_bore (g_XSCore__gatewayIn_packed_38_bore),
    .gatewayIn_packed_39_bore (g_XSCore__gatewayIn_packed_39_bore),
    .gatewayIn_packed_40_bore (g_XSCore__gatewayIn_packed_40_bore),
    .gatewayIn_packed_41_bore (g_XSCore__gatewayIn_packed_41_bore),
    .gatewayIn_packed_42_bore (g_XSCore__gatewayIn_packed_42_bore),
    .gatewayIn_packed_43_bore (g_XSCore__gatewayIn_packed_43_bore),
    .gatewayIn_packed_44_bore (g_XSCore__gatewayIn_packed_44_bore),
    .gatewayIn_packed_45_bore (g_XSCore__gatewayIn_packed_45_bore),
    .gatewayIn_packed_46_bore (g_XSCore__gatewayIn_packed_46_bore),
    .gatewayIn_packed_47_bore (g_XSCore__gatewayIn_packed_47_bore),
    .gatewayIn_packed_48_bore (g_XSCore__gatewayIn_packed_48_bore),
    .gatewayIn_packed_49_bore (g_XSCore__gatewayIn_packed_49_bore),
    .gatewayIn_packed_50_bore (g_XSCore__gatewayIn_packed_50_bore),
    .gatewayIn_packed_51_bore (g_XSCore__gatewayIn_packed_51_bore),
    .gatewayIn_packed_52_bore (g_XSCore__gatewayIn_packed_52_bore),
    .gatewayIn_packed_53_bore (g_XSCore__gatewayIn_packed_53_bore),
    .gatewayIn_packed_54_bore (g_XSCore__gatewayIn_packed_54_bore),
    .gatewayIn_packed_55_bore (g_XSCore__gatewayIn_packed_55_bore),
    .gatewayIn_packed_56_bore (g_XSCore__gatewayIn_packed_56_bore),
    .gatewayIn_packed_57_bore (g_XSCore__gatewayIn_packed_57_bore),
    .gatewayIn_packed_58_bore (g_XSCore__gatewayIn_packed_58_bore),
    .gatewayIn_packed_59_bore (g_XSCore__gatewayIn_packed_59_bore),
    .gatewayIn_packed_60_bore (g_XSCore__gatewayIn_packed_60_bore)
  );
  XSCore_xs u_i_XSCore (
    .clock (clock),
    .reset (reset),
    .auto_memBlock_inner_buffers_out_a_ready (XSCore__auto_memBlock_inner_buffers_out_a_ready),
    .auto_memBlock_inner_buffers_out_a_valid (i_XSCore__auto_memBlock_inner_buffers_out_a_valid),
    .auto_memBlock_inner_buffers_out_a_bits_opcode (i_XSCore__auto_memBlock_inner_buffers_out_a_bits_opcode),
    .auto_memBlock_inner_buffers_out_a_bits_param (i_XSCore__auto_memBlock_inner_buffers_out_a_bits_param),
    .auto_memBlock_inner_buffers_out_a_bits_size (i_XSCore__auto_memBlock_inner_buffers_out_a_bits_size),
    .auto_memBlock_inner_buffers_out_a_bits_source (i_XSCore__auto_memBlock_inner_buffers_out_a_bits_source),
    .auto_memBlock_inner_buffers_out_a_bits_address (i_XSCore__auto_memBlock_inner_buffers_out_a_bits_address),
    .auto_memBlock_inner_buffers_out_a_bits_user_memBackType_MM (i_XSCore__auto_memBlock_inner_buffers_out_a_bits_user_memBackType_MM),
    .auto_memBlock_inner_buffers_out_a_bits_user_memPageType_NC (i_XSCore__auto_memBlock_inner_buffers_out_a_bits_user_memPageType_NC),
    .auto_memBlock_inner_buffers_out_a_bits_mask (i_XSCore__auto_memBlock_inner_buffers_out_a_bits_mask),
    .auto_memBlock_inner_buffers_out_a_bits_data (i_XSCore__auto_memBlock_inner_buffers_out_a_bits_data),
    .auto_memBlock_inner_buffers_out_a_bits_corrupt (i_XSCore__auto_memBlock_inner_buffers_out_a_bits_corrupt),
    .auto_memBlock_inner_buffers_out_d_ready (i_XSCore__auto_memBlock_inner_buffers_out_d_ready),
    .auto_memBlock_inner_buffers_out_d_valid (XSCore__auto_memBlock_inner_buffers_out_d_valid),
    .auto_memBlock_inner_buffers_out_d_bits_opcode (XSCore__auto_memBlock_inner_buffers_out_d_bits_opcode),
    .auto_memBlock_inner_buffers_out_d_bits_param (XSCore__auto_memBlock_inner_buffers_out_d_bits_param),
    .auto_memBlock_inner_buffers_out_d_bits_size (XSCore__auto_memBlock_inner_buffers_out_d_bits_size),
    .auto_memBlock_inner_buffers_out_d_bits_source (XSCore__auto_memBlock_inner_buffers_out_d_bits_source),
    .auto_memBlock_inner_buffers_out_d_bits_sink (XSCore__auto_memBlock_inner_buffers_out_d_bits_sink),
    .auto_memBlock_inner_buffers_out_d_bits_denied (XSCore__auto_memBlock_inner_buffers_out_d_bits_denied),
    .auto_memBlock_inner_buffers_out_d_bits_data (XSCore__auto_memBlock_inner_buffers_out_d_bits_data),
    .auto_memBlock_inner_buffers_out_d_bits_corrupt (XSCore__auto_memBlock_inner_buffers_out_d_bits_corrupt),
    .auto_memBlock_inner_frontendBridge_instr_uncache_out_a_ready (XSCore__auto_memBlock_inner_frontendBridge_instr_uncache_out_a_ready),
    .auto_memBlock_inner_frontendBridge_instr_uncache_out_a_valid (i_XSCore__auto_memBlock_inner_frontendBridge_instr_uncache_out_a_valid),
    .auto_memBlock_inner_frontendBridge_instr_uncache_out_a_bits_param (i_XSCore__auto_memBlock_inner_frontendBridge_instr_uncache_out_a_bits_param),
    .auto_memBlock_inner_frontendBridge_instr_uncache_out_a_bits_address (i_XSCore__auto_memBlock_inner_frontendBridge_instr_uncache_out_a_bits_address),
    .auto_memBlock_inner_frontendBridge_instr_uncache_out_a_bits_user_memPageType_NC (i_XSCore__auto_memBlock_inner_frontendBridge_instr_uncache_out_a_bits_user_memPageType_NC),
    .auto_memBlock_inner_frontendBridge_instr_uncache_out_a_bits_user_memBackType_MM (i_XSCore__auto_memBlock_inner_frontendBridge_instr_uncache_out_a_bits_user_memBackType_MM),
    .auto_memBlock_inner_frontendBridge_instr_uncache_out_a_bits_corrupt (i_XSCore__auto_memBlock_inner_frontendBridge_instr_uncache_out_a_bits_corrupt),
    .auto_memBlock_inner_frontendBridge_instr_uncache_out_d_ready (i_XSCore__auto_memBlock_inner_frontendBridge_instr_uncache_out_d_ready),
    .auto_memBlock_inner_frontendBridge_instr_uncache_out_d_valid (XSCore__auto_memBlock_inner_frontendBridge_instr_uncache_out_d_valid),
    .auto_memBlock_inner_frontendBridge_instr_uncache_out_d_bits_opcode (XSCore__auto_memBlock_inner_frontendBridge_instr_uncache_out_d_bits_opcode),
    .auto_memBlock_inner_frontendBridge_instr_uncache_out_d_bits_param (XSCore__auto_memBlock_inner_frontendBridge_instr_uncache_out_d_bits_param),
    .auto_memBlock_inner_frontendBridge_instr_uncache_out_d_bits_size (XSCore__auto_memBlock_inner_frontendBridge_instr_uncache_out_d_bits_size),
    .auto_memBlock_inner_frontendBridge_instr_uncache_out_d_bits_source (XSCore__auto_memBlock_inner_frontendBridge_instr_uncache_out_d_bits_source),
    .auto_memBlock_inner_frontendBridge_instr_uncache_out_d_bits_sink (XSCore__auto_memBlock_inner_frontendBridge_instr_uncache_out_d_bits_sink),
    .auto_memBlock_inner_frontendBridge_instr_uncache_out_d_bits_denied (XSCore__auto_memBlock_inner_frontendBridge_instr_uncache_out_d_bits_denied),
    .auto_memBlock_inner_frontendBridge_instr_uncache_out_d_bits_data (XSCore__auto_memBlock_inner_frontendBridge_instr_uncache_out_d_bits_data),
    .auto_memBlock_inner_frontendBridge_instr_uncache_out_d_bits_corrupt (XSCore__auto_memBlock_inner_frontendBridge_instr_uncache_out_d_bits_corrupt),
    .auto_memBlock_inner_frontendBridge_icachectrl_in_a_ready (i_XSCore__auto_memBlock_inner_frontendBridge_icachectrl_in_a_ready),
    .auto_memBlock_inner_frontendBridge_icachectrl_in_a_valid (XSCore__auto_memBlock_inner_frontendBridge_icachectrl_in_a_valid),
    .auto_memBlock_inner_frontendBridge_icachectrl_in_a_bits_opcode (XSCore__auto_memBlock_inner_frontendBridge_icachectrl_in_a_bits_opcode),
    .auto_memBlock_inner_frontendBridge_icachectrl_in_a_bits_param (XSCore__auto_memBlock_inner_frontendBridge_icachectrl_in_a_bits_param),
    .auto_memBlock_inner_frontendBridge_icachectrl_in_a_bits_size (XSCore__auto_memBlock_inner_frontendBridge_icachectrl_in_a_bits_size),
    .auto_memBlock_inner_frontendBridge_icachectrl_in_a_bits_source (XSCore__auto_memBlock_inner_frontendBridge_icachectrl_in_a_bits_source),
    .auto_memBlock_inner_frontendBridge_icachectrl_in_a_bits_address (XSCore__auto_memBlock_inner_frontendBridge_icachectrl_in_a_bits_address),
    .auto_memBlock_inner_frontendBridge_icachectrl_in_a_bits_mask (XSCore__auto_memBlock_inner_frontendBridge_icachectrl_in_a_bits_mask),
    .auto_memBlock_inner_frontendBridge_icachectrl_in_a_bits_data (XSCore__auto_memBlock_inner_frontendBridge_icachectrl_in_a_bits_data),
    .auto_memBlock_inner_frontendBridge_icachectrl_in_a_bits_corrupt (XSCore__auto_memBlock_inner_frontendBridge_icachectrl_in_a_bits_corrupt),
    .auto_memBlock_inner_frontendBridge_icachectrl_in_d_ready (XSCore__auto_memBlock_inner_frontendBridge_icachectrl_in_d_ready),
    .auto_memBlock_inner_frontendBridge_icachectrl_in_d_valid (i_XSCore__auto_memBlock_inner_frontendBridge_icachectrl_in_d_valid),
    .auto_memBlock_inner_frontendBridge_icachectrl_in_d_bits_opcode (i_XSCore__auto_memBlock_inner_frontendBridge_icachectrl_in_d_bits_opcode),
    .auto_memBlock_inner_frontendBridge_icachectrl_in_d_bits_param (i_XSCore__auto_memBlock_inner_frontendBridge_icachectrl_in_d_bits_param),
    .auto_memBlock_inner_frontendBridge_icachectrl_in_d_bits_size (i_XSCore__auto_memBlock_inner_frontendBridge_icachectrl_in_d_bits_size),
    .auto_memBlock_inner_frontendBridge_icachectrl_in_d_bits_source (i_XSCore__auto_memBlock_inner_frontendBridge_icachectrl_in_d_bits_source),
    .auto_memBlock_inner_frontendBridge_icachectrl_in_d_bits_sink (i_XSCore__auto_memBlock_inner_frontendBridge_icachectrl_in_d_bits_sink),
    .auto_memBlock_inner_frontendBridge_icachectrl_in_d_bits_denied (i_XSCore__auto_memBlock_inner_frontendBridge_icachectrl_in_d_bits_denied),
    .auto_memBlock_inner_frontendBridge_icachectrl_in_d_bits_data (i_XSCore__auto_memBlock_inner_frontendBridge_icachectrl_in_d_bits_data),
    .auto_memBlock_inner_frontendBridge_icachectrl_in_d_bits_corrupt (i_XSCore__auto_memBlock_inner_frontendBridge_icachectrl_in_d_bits_corrupt),
    .auto_memBlock_inner_frontendBridge_icache_out_a_ready (XSCore__auto_memBlock_inner_frontendBridge_icache_out_a_ready),
    .auto_memBlock_inner_frontendBridge_icache_out_a_valid (i_XSCore__auto_memBlock_inner_frontendBridge_icache_out_a_valid),
    .auto_memBlock_inner_frontendBridge_icache_out_a_bits_opcode (i_XSCore__auto_memBlock_inner_frontendBridge_icache_out_a_bits_opcode),
    .auto_memBlock_inner_frontendBridge_icache_out_a_bits_param (i_XSCore__auto_memBlock_inner_frontendBridge_icache_out_a_bits_param),
    .auto_memBlock_inner_frontendBridge_icache_out_a_bits_size (i_XSCore__auto_memBlock_inner_frontendBridge_icache_out_a_bits_size),
    .auto_memBlock_inner_frontendBridge_icache_out_a_bits_source (i_XSCore__auto_memBlock_inner_frontendBridge_icache_out_a_bits_source),
    .auto_memBlock_inner_frontendBridge_icache_out_a_bits_address (i_XSCore__auto_memBlock_inner_frontendBridge_icache_out_a_bits_address),
    .auto_memBlock_inner_frontendBridge_icache_out_a_bits_user_alias (i_XSCore__auto_memBlock_inner_frontendBridge_icache_out_a_bits_user_alias),
    .auto_memBlock_inner_frontendBridge_icache_out_a_bits_user_reqSource (i_XSCore__auto_memBlock_inner_frontendBridge_icache_out_a_bits_user_reqSource),
    .auto_memBlock_inner_frontendBridge_icache_out_a_bits_user_needHint (i_XSCore__auto_memBlock_inner_frontendBridge_icache_out_a_bits_user_needHint),
    .auto_memBlock_inner_frontendBridge_icache_out_a_bits_mask (i_XSCore__auto_memBlock_inner_frontendBridge_icache_out_a_bits_mask),
    .auto_memBlock_inner_frontendBridge_icache_out_a_bits_data (i_XSCore__auto_memBlock_inner_frontendBridge_icache_out_a_bits_data),
    .auto_memBlock_inner_frontendBridge_icache_out_a_bits_corrupt (i_XSCore__auto_memBlock_inner_frontendBridge_icache_out_a_bits_corrupt),
    .auto_memBlock_inner_frontendBridge_icache_out_d_ready (i_XSCore__auto_memBlock_inner_frontendBridge_icache_out_d_ready),
    .auto_memBlock_inner_frontendBridge_icache_out_d_valid (XSCore__auto_memBlock_inner_frontendBridge_icache_out_d_valid),
    .auto_memBlock_inner_frontendBridge_icache_out_d_bits_opcode (XSCore__auto_memBlock_inner_frontendBridge_icache_out_d_bits_opcode),
    .auto_memBlock_inner_frontendBridge_icache_out_d_bits_param (XSCore__auto_memBlock_inner_frontendBridge_icache_out_d_bits_param),
    .auto_memBlock_inner_frontendBridge_icache_out_d_bits_size (XSCore__auto_memBlock_inner_frontendBridge_icache_out_d_bits_size),
    .auto_memBlock_inner_frontendBridge_icache_out_d_bits_source (XSCore__auto_memBlock_inner_frontendBridge_icache_out_d_bits_source),
    .auto_memBlock_inner_frontendBridge_icache_out_d_bits_sink (XSCore__auto_memBlock_inner_frontendBridge_icache_out_d_bits_sink),
    .auto_memBlock_inner_frontendBridge_icache_out_d_bits_denied (XSCore__auto_memBlock_inner_frontendBridge_icache_out_d_bits_denied),
    .auto_memBlock_inner_frontendBridge_icache_out_d_bits_data (XSCore__auto_memBlock_inner_frontendBridge_icache_out_d_bits_data),
    .auto_memBlock_inner_frontendBridge_icache_out_d_bits_corrupt (XSCore__auto_memBlock_inner_frontendBridge_icache_out_d_bits_corrupt),
    .auto_memBlock_inner_ptw_to_l2_buffer_out_a_ready (XSCore__auto_memBlock_inner_ptw_to_l2_buffer_out_a_ready),
    .auto_memBlock_inner_ptw_to_l2_buffer_out_a_valid (i_XSCore__auto_memBlock_inner_ptw_to_l2_buffer_out_a_valid),
    .auto_memBlock_inner_ptw_to_l2_buffer_out_a_bits_opcode (i_XSCore__auto_memBlock_inner_ptw_to_l2_buffer_out_a_bits_opcode),
    .auto_memBlock_inner_ptw_to_l2_buffer_out_a_bits_param (i_XSCore__auto_memBlock_inner_ptw_to_l2_buffer_out_a_bits_param),
    .auto_memBlock_inner_ptw_to_l2_buffer_out_a_bits_size (i_XSCore__auto_memBlock_inner_ptw_to_l2_buffer_out_a_bits_size),
    .auto_memBlock_inner_ptw_to_l2_buffer_out_a_bits_source (i_XSCore__auto_memBlock_inner_ptw_to_l2_buffer_out_a_bits_source),
    .auto_memBlock_inner_ptw_to_l2_buffer_out_a_bits_address (i_XSCore__auto_memBlock_inner_ptw_to_l2_buffer_out_a_bits_address),
    .auto_memBlock_inner_ptw_to_l2_buffer_out_a_bits_user_reqSource (i_XSCore__auto_memBlock_inner_ptw_to_l2_buffer_out_a_bits_user_reqSource),
    .auto_memBlock_inner_ptw_to_l2_buffer_out_a_bits_mask (i_XSCore__auto_memBlock_inner_ptw_to_l2_buffer_out_a_bits_mask),
    .auto_memBlock_inner_ptw_to_l2_buffer_out_a_bits_data (i_XSCore__auto_memBlock_inner_ptw_to_l2_buffer_out_a_bits_data),
    .auto_memBlock_inner_ptw_to_l2_buffer_out_a_bits_corrupt (i_XSCore__auto_memBlock_inner_ptw_to_l2_buffer_out_a_bits_corrupt),
    .auto_memBlock_inner_ptw_to_l2_buffer_out_d_ready (i_XSCore__auto_memBlock_inner_ptw_to_l2_buffer_out_d_ready),
    .auto_memBlock_inner_ptw_to_l2_buffer_out_d_valid (XSCore__auto_memBlock_inner_ptw_to_l2_buffer_out_d_valid),
    .auto_memBlock_inner_ptw_to_l2_buffer_out_d_bits_opcode (XSCore__auto_memBlock_inner_ptw_to_l2_buffer_out_d_bits_opcode),
    .auto_memBlock_inner_ptw_to_l2_buffer_out_d_bits_param (XSCore__auto_memBlock_inner_ptw_to_l2_buffer_out_d_bits_param),
    .auto_memBlock_inner_ptw_to_l2_buffer_out_d_bits_size (XSCore__auto_memBlock_inner_ptw_to_l2_buffer_out_d_bits_size),
    .auto_memBlock_inner_ptw_to_l2_buffer_out_d_bits_source (XSCore__auto_memBlock_inner_ptw_to_l2_buffer_out_d_bits_source),
    .auto_memBlock_inner_ptw_to_l2_buffer_out_d_bits_sink (XSCore__auto_memBlock_inner_ptw_to_l2_buffer_out_d_bits_sink),
    .auto_memBlock_inner_ptw_to_l2_buffer_out_d_bits_denied (XSCore__auto_memBlock_inner_ptw_to_l2_buffer_out_d_bits_denied),
    .auto_memBlock_inner_ptw_to_l2_buffer_out_d_bits_data (XSCore__auto_memBlock_inner_ptw_to_l2_buffer_out_d_bits_data),
    .auto_memBlock_inner_ptw_to_l2_buffer_out_d_bits_corrupt (XSCore__auto_memBlock_inner_ptw_to_l2_buffer_out_d_bits_corrupt),
    .auto_memBlock_inner_beu_local_int_sink_in_0 (XSCore__auto_memBlock_inner_beu_local_int_sink_in_0),
    .auto_memBlock_inner_nmi_int_sink_in_0 (XSCore__auto_memBlock_inner_nmi_int_sink_in_0),
    .auto_memBlock_inner_nmi_int_sink_in_1 (XSCore__auto_memBlock_inner_nmi_int_sink_in_1),
    .auto_memBlock_inner_plic_int_sink_in_1_0 (XSCore__auto_memBlock_inner_plic_int_sink_in_1_0),
    .auto_memBlock_inner_plic_int_sink_in_0_0 (XSCore__auto_memBlock_inner_plic_int_sink_in_0_0),
    .auto_memBlock_inner_debug_int_sink_in_0 (XSCore__auto_memBlock_inner_debug_int_sink_in_0),
    .auto_memBlock_inner_clint_int_sink_in_0 (XSCore__auto_memBlock_inner_clint_int_sink_in_0),
    .auto_memBlock_inner_clint_int_sink_in_1 (XSCore__auto_memBlock_inner_clint_int_sink_in_1),
    .auto_memBlock_inner_l2_pf_sender_out_addr (i_XSCore__auto_memBlock_inner_l2_pf_sender_out_addr),
    .auto_memBlock_inner_l2_pf_sender_out_pf_source (i_XSCore__auto_memBlock_inner_l2_pf_sender_out_pf_source),
    .auto_memBlock_inner_l2_pf_sender_out_addr_valid (i_XSCore__auto_memBlock_inner_l2_pf_sender_out_addr_valid),
    .auto_memBlock_inner_dcache_client_out_a_ready (XSCore__auto_memBlock_inner_dcache_client_out_a_ready),
    .auto_memBlock_inner_dcache_client_out_a_valid (i_XSCore__auto_memBlock_inner_dcache_client_out_a_valid),
    .auto_memBlock_inner_dcache_client_out_a_bits_opcode (i_XSCore__auto_memBlock_inner_dcache_client_out_a_bits_opcode),
    .auto_memBlock_inner_dcache_client_out_a_bits_param (i_XSCore__auto_memBlock_inner_dcache_client_out_a_bits_param),
    .auto_memBlock_inner_dcache_client_out_a_bits_size (i_XSCore__auto_memBlock_inner_dcache_client_out_a_bits_size),
    .auto_memBlock_inner_dcache_client_out_a_bits_source (i_XSCore__auto_memBlock_inner_dcache_client_out_a_bits_source),
    .auto_memBlock_inner_dcache_client_out_a_bits_address (i_XSCore__auto_memBlock_inner_dcache_client_out_a_bits_address),
    .auto_memBlock_inner_dcache_client_out_a_bits_user_alias (i_XSCore__auto_memBlock_inner_dcache_client_out_a_bits_user_alias),
    .auto_memBlock_inner_dcache_client_out_a_bits_user_vaddr (i_XSCore__auto_memBlock_inner_dcache_client_out_a_bits_user_vaddr),
    .auto_memBlock_inner_dcache_client_out_a_bits_user_reqSource (i_XSCore__auto_memBlock_inner_dcache_client_out_a_bits_user_reqSource),
    .auto_memBlock_inner_dcache_client_out_a_bits_user_needHint (i_XSCore__auto_memBlock_inner_dcache_client_out_a_bits_user_needHint),
    .auto_memBlock_inner_dcache_client_out_a_bits_echo_isKeyword (i_XSCore__auto_memBlock_inner_dcache_client_out_a_bits_echo_isKeyword),
    .auto_memBlock_inner_dcache_client_out_a_bits_mask (i_XSCore__auto_memBlock_inner_dcache_client_out_a_bits_mask),
    .auto_memBlock_inner_dcache_client_out_a_bits_data (i_XSCore__auto_memBlock_inner_dcache_client_out_a_bits_data),
    .auto_memBlock_inner_dcache_client_out_a_bits_corrupt (i_XSCore__auto_memBlock_inner_dcache_client_out_a_bits_corrupt),
    .auto_memBlock_inner_dcache_client_out_b_ready (i_XSCore__auto_memBlock_inner_dcache_client_out_b_ready),
    .auto_memBlock_inner_dcache_client_out_b_valid (XSCore__auto_memBlock_inner_dcache_client_out_b_valid),
    .auto_memBlock_inner_dcache_client_out_b_bits_opcode (XSCore__auto_memBlock_inner_dcache_client_out_b_bits_opcode),
    .auto_memBlock_inner_dcache_client_out_b_bits_param (XSCore__auto_memBlock_inner_dcache_client_out_b_bits_param),
    .auto_memBlock_inner_dcache_client_out_b_bits_size (XSCore__auto_memBlock_inner_dcache_client_out_b_bits_size),
    .auto_memBlock_inner_dcache_client_out_b_bits_source (XSCore__auto_memBlock_inner_dcache_client_out_b_bits_source),
    .auto_memBlock_inner_dcache_client_out_b_bits_address (XSCore__auto_memBlock_inner_dcache_client_out_b_bits_address),
    .auto_memBlock_inner_dcache_client_out_b_bits_mask (XSCore__auto_memBlock_inner_dcache_client_out_b_bits_mask),
    .auto_memBlock_inner_dcache_client_out_b_bits_data (XSCore__auto_memBlock_inner_dcache_client_out_b_bits_data),
    .auto_memBlock_inner_dcache_client_out_b_bits_corrupt (XSCore__auto_memBlock_inner_dcache_client_out_b_bits_corrupt),
    .auto_memBlock_inner_dcache_client_out_c_ready (XSCore__auto_memBlock_inner_dcache_client_out_c_ready),
    .auto_memBlock_inner_dcache_client_out_c_valid (i_XSCore__auto_memBlock_inner_dcache_client_out_c_valid),
    .auto_memBlock_inner_dcache_client_out_c_bits_opcode (i_XSCore__auto_memBlock_inner_dcache_client_out_c_bits_opcode),
    .auto_memBlock_inner_dcache_client_out_c_bits_param (i_XSCore__auto_memBlock_inner_dcache_client_out_c_bits_param),
    .auto_memBlock_inner_dcache_client_out_c_bits_size (i_XSCore__auto_memBlock_inner_dcache_client_out_c_bits_size),
    .auto_memBlock_inner_dcache_client_out_c_bits_source (i_XSCore__auto_memBlock_inner_dcache_client_out_c_bits_source),
    .auto_memBlock_inner_dcache_client_out_c_bits_address (i_XSCore__auto_memBlock_inner_dcache_client_out_c_bits_address),
    .auto_memBlock_inner_dcache_client_out_c_bits_user_alias (i_XSCore__auto_memBlock_inner_dcache_client_out_c_bits_user_alias),
    .auto_memBlock_inner_dcache_client_out_c_bits_user_vaddr (i_XSCore__auto_memBlock_inner_dcache_client_out_c_bits_user_vaddr),
    .auto_memBlock_inner_dcache_client_out_c_bits_user_reqSource (i_XSCore__auto_memBlock_inner_dcache_client_out_c_bits_user_reqSource),
    .auto_memBlock_inner_dcache_client_out_c_bits_user_needHint (i_XSCore__auto_memBlock_inner_dcache_client_out_c_bits_user_needHint),
    .auto_memBlock_inner_dcache_client_out_c_bits_echo_isKeyword (i_XSCore__auto_memBlock_inner_dcache_client_out_c_bits_echo_isKeyword),
    .auto_memBlock_inner_dcache_client_out_c_bits_data (i_XSCore__auto_memBlock_inner_dcache_client_out_c_bits_data),
    .auto_memBlock_inner_dcache_client_out_c_bits_corrupt (i_XSCore__auto_memBlock_inner_dcache_client_out_c_bits_corrupt),
    .auto_memBlock_inner_dcache_client_out_d_ready (i_XSCore__auto_memBlock_inner_dcache_client_out_d_ready),
    .auto_memBlock_inner_dcache_client_out_d_valid (XSCore__auto_memBlock_inner_dcache_client_out_d_valid),
    .auto_memBlock_inner_dcache_client_out_d_bits_opcode (XSCore__auto_memBlock_inner_dcache_client_out_d_bits_opcode),
    .auto_memBlock_inner_dcache_client_out_d_bits_param (XSCore__auto_memBlock_inner_dcache_client_out_d_bits_param),
    .auto_memBlock_inner_dcache_client_out_d_bits_size (XSCore__auto_memBlock_inner_dcache_client_out_d_bits_size),
    .auto_memBlock_inner_dcache_client_out_d_bits_source (XSCore__auto_memBlock_inner_dcache_client_out_d_bits_source),
    .auto_memBlock_inner_dcache_client_out_d_bits_sink (XSCore__auto_memBlock_inner_dcache_client_out_d_bits_sink),
    .auto_memBlock_inner_dcache_client_out_d_bits_denied (XSCore__auto_memBlock_inner_dcache_client_out_d_bits_denied),
    .auto_memBlock_inner_dcache_client_out_d_bits_echo_isKeyword (XSCore__auto_memBlock_inner_dcache_client_out_d_bits_echo_isKeyword),
    .auto_memBlock_inner_dcache_client_out_d_bits_data (XSCore__auto_memBlock_inner_dcache_client_out_d_bits_data),
    .auto_memBlock_inner_dcache_client_out_d_bits_corrupt (XSCore__auto_memBlock_inner_dcache_client_out_d_bits_corrupt),
    .auto_memBlock_inner_dcache_client_out_e_ready (XSCore__auto_memBlock_inner_dcache_client_out_e_ready),
    .auto_memBlock_inner_dcache_client_out_e_valid (i_XSCore__auto_memBlock_inner_dcache_client_out_e_valid),
    .auto_memBlock_inner_dcache_client_out_e_bits_sink (i_XSCore__auto_memBlock_inner_dcache_client_out_e_bits_sink),
    .io_hartId (XSCore__io_hartId),
    .io_msiInfo_valid (XSCore__io_msiInfo_valid),
    .io_msiInfo_bits (XSCore__io_msiInfo_bits),
    .io_msiAck (i_XSCore__io_msiAck),
    .io_clintTime_valid (XSCore__io_clintTime_valid),
    .io_clintTime_bits (XSCore__io_clintTime_bits),
    .io_reset_vector (XSCore__io_reset_vector),
    .io_cpu_halt (i_XSCore__io_cpu_halt),
    .io_l2_flush_done (XSCore__io_l2_flush_done),
    .io_l2_flush_en (i_XSCore__io_l2_flush_en),
    .io_power_down_en (i_XSCore__io_power_down_en),
    .io_cpu_critical_error (i_XSCore__io_cpu_critical_error),
    .io_resetInFrontend (i_XSCore__io_resetInFrontend),
    .io_traceCoreInterface_fromEncoder_enable (XSCore__io_traceCoreInterface_fromEncoder_enable),
    .io_traceCoreInterface_fromEncoder_stall (XSCore__io_traceCoreInterface_fromEncoder_stall),
    .io_traceCoreInterface_toEncoder_priv (i_XSCore__io_traceCoreInterface_toEncoder_priv),
    .io_traceCoreInterface_toEncoder_mstatus (i_XSCore__io_traceCoreInterface_toEncoder_mstatus),
    .io_traceCoreInterface_toEncoder_trap_cause (i_XSCore__io_traceCoreInterface_toEncoder_trap_cause),
    .io_traceCoreInterface_toEncoder_trap_tval (i_XSCore__io_traceCoreInterface_toEncoder_trap_tval),
    .io_traceCoreInterface_toEncoder_groups_0_valid (i_XSCore__io_traceCoreInterface_toEncoder_groups_0_valid),
    .io_traceCoreInterface_toEncoder_groups_0_bits_iaddr (i_XSCore__io_traceCoreInterface_toEncoder_groups_0_bits_iaddr),
    .io_traceCoreInterface_toEncoder_groups_0_bits_itype (i_XSCore__io_traceCoreInterface_toEncoder_groups_0_bits_itype),
    .io_traceCoreInterface_toEncoder_groups_0_bits_iretire (i_XSCore__io_traceCoreInterface_toEncoder_groups_0_bits_iretire),
    .io_traceCoreInterface_toEncoder_groups_0_bits_ilastsize (i_XSCore__io_traceCoreInterface_toEncoder_groups_0_bits_ilastsize),
    .io_traceCoreInterface_toEncoder_groups_1_valid (i_XSCore__io_traceCoreInterface_toEncoder_groups_1_valid),
    .io_traceCoreInterface_toEncoder_groups_1_bits_iaddr (i_XSCore__io_traceCoreInterface_toEncoder_groups_1_bits_iaddr),
    .io_traceCoreInterface_toEncoder_groups_1_bits_itype (i_XSCore__io_traceCoreInterface_toEncoder_groups_1_bits_itype),
    .io_traceCoreInterface_toEncoder_groups_1_bits_iretire (i_XSCore__io_traceCoreInterface_toEncoder_groups_1_bits_iretire),
    .io_traceCoreInterface_toEncoder_groups_1_bits_ilastsize (i_XSCore__io_traceCoreInterface_toEncoder_groups_1_bits_ilastsize),
    .io_traceCoreInterface_toEncoder_groups_2_valid (i_XSCore__io_traceCoreInterface_toEncoder_groups_2_valid),
    .io_traceCoreInterface_toEncoder_groups_2_bits_iaddr (i_XSCore__io_traceCoreInterface_toEncoder_groups_2_bits_iaddr),
    .io_traceCoreInterface_toEncoder_groups_2_bits_itype (i_XSCore__io_traceCoreInterface_toEncoder_groups_2_bits_itype),
    .io_traceCoreInterface_toEncoder_groups_2_bits_iretire (i_XSCore__io_traceCoreInterface_toEncoder_groups_2_bits_iretire),
    .io_traceCoreInterface_toEncoder_groups_2_bits_ilastsize (i_XSCore__io_traceCoreInterface_toEncoder_groups_2_bits_ilastsize),
    .io_l2PfCtrl_l2_pf_master_en (i_XSCore__io_l2PfCtrl_l2_pf_master_en),
    .io_l2PfCtrl_l2_pf_recv_en (i_XSCore__io_l2PfCtrl_l2_pf_recv_en),
    .io_l2PfCtrl_l2_pbop_en (i_XSCore__io_l2PfCtrl_l2_pbop_en),
    .io_l2PfCtrl_l2_vbop_en (i_XSCore__io_l2PfCtrl_l2_vbop_en),
    .io_l2PfCtrl_l2_pf_delay_latency (i_XSCore__io_l2PfCtrl_l2_pf_delay_latency),
    .io_perfEvents_1_value (XSCore__io_perfEvents_1_value),
    .io_perfEvents_2_value (XSCore__io_perfEvents_2_value),
    .io_perfEvents_3_value (XSCore__io_perfEvents_3_value),
    .io_perfEvents_4_value (XSCore__io_perfEvents_4_value),
    .io_perfEvents_5_value (XSCore__io_perfEvents_5_value),
    .io_perfEvents_6_value (XSCore__io_perfEvents_6_value),
    .io_perfEvents_7_value (XSCore__io_perfEvents_7_value),
    .io_perfEvents_8_value (XSCore__io_perfEvents_8_value),
    .io_perfEvents_9_value (XSCore__io_perfEvents_9_value),
    .io_perfEvents_10_value (XSCore__io_perfEvents_10_value),
    .io_perfEvents_11_value (XSCore__io_perfEvents_11_value),
    .io_perfEvents_12_value (XSCore__io_perfEvents_12_value),
    .io_perfEvents_13_value (XSCore__io_perfEvents_13_value),
    .io_perfEvents_14_value (XSCore__io_perfEvents_14_value),
    .io_perfEvents_15_value (XSCore__io_perfEvents_15_value),
    .io_perfEvents_16_value (XSCore__io_perfEvents_16_value),
    .io_perfEvents_17_value (XSCore__io_perfEvents_17_value),
    .io_perfEvents_18_value (XSCore__io_perfEvents_18_value),
    .io_perfEvents_19_value (XSCore__io_perfEvents_19_value),
    .io_perfEvents_20_value (XSCore__io_perfEvents_20_value),
    .io_perfEvents_21_value (XSCore__io_perfEvents_21_value),
    .io_perfEvents_22_value (XSCore__io_perfEvents_22_value),
    .io_perfEvents_23_value (XSCore__io_perfEvents_23_value),
    .io_perfEvents_24_value (XSCore__io_perfEvents_24_value),
    .io_perfEvents_25_value (XSCore__io_perfEvents_25_value),
    .io_perfEvents_26_value (XSCore__io_perfEvents_26_value),
    .io_perfEvents_27_value (XSCore__io_perfEvents_27_value),
    .io_perfEvents_28_value (XSCore__io_perfEvents_28_value),
    .io_perfEvents_29_value (XSCore__io_perfEvents_29_value),
    .io_perfEvents_30_value (XSCore__io_perfEvents_30_value),
    .io_perfEvents_31_value (XSCore__io_perfEvents_31_value),
    .io_perfEvents_32_value (XSCore__io_perfEvents_32_value),
    .io_perfEvents_33_value (XSCore__io_perfEvents_33_value),
    .io_perfEvents_34_value (XSCore__io_perfEvents_34_value),
    .io_perfEvents_35_value (XSCore__io_perfEvents_35_value),
    .io_perfEvents_36_value (XSCore__io_perfEvents_36_value),
    .io_perfEvents_37_value (XSCore__io_perfEvents_37_value),
    .io_perfEvents_38_value (XSCore__io_perfEvents_38_value),
    .io_perfEvents_39_value (XSCore__io_perfEvents_39_value),
    .io_perfEvents_40_value (XSCore__io_perfEvents_40_value),
    .io_perfEvents_41_value (XSCore__io_perfEvents_41_value),
    .io_perfEvents_42_value (XSCore__io_perfEvents_42_value),
    .io_perfEvents_43_value (XSCore__io_perfEvents_43_value),
    .io_perfEvents_44_value (XSCore__io_perfEvents_44_value),
    .io_perfEvents_45_value (XSCore__io_perfEvents_45_value),
    .io_perfEvents_46_value (XSCore__io_perfEvents_46_value),
    .io_perfEvents_47_value (XSCore__io_perfEvents_47_value),
    .io_perfEvents_48_value (XSCore__io_perfEvents_48_value),
    .io_perfEvents_49_value (XSCore__io_perfEvents_49_value),
    .io_perfEvents_50_value (XSCore__io_perfEvents_50_value),
    .io_perfEvents_51_value (XSCore__io_perfEvents_51_value),
    .io_perfEvents_52_value (XSCore__io_perfEvents_52_value),
    .io_perfEvents_53_value (XSCore__io_perfEvents_53_value),
    .io_perfEvents_54_value (XSCore__io_perfEvents_54_value),
    .io_perfEvents_55_value (XSCore__io_perfEvents_55_value),
    .io_perfEvents_56_value (XSCore__io_perfEvents_56_value),
    .io_perfEvents_57_value (XSCore__io_perfEvents_57_value),
    .io_perfEvents_58_value (XSCore__io_perfEvents_58_value),
    .io_perfEvents_59_value (XSCore__io_perfEvents_59_value),
    .io_perfEvents_60_value (XSCore__io_perfEvents_60_value),
    .io_perfEvents_61_value (XSCore__io_perfEvents_61_value),
    .io_perfEvents_62_value (XSCore__io_perfEvents_62_value),
    .io_perfEvents_63_value (XSCore__io_perfEvents_63_value),
    .io_perfEvents_64_value (XSCore__io_perfEvents_64_value),
    .io_perfEvents_65_value (XSCore__io_perfEvents_65_value),
    .io_perfEvents_66_value (XSCore__io_perfEvents_66_value),
    .io_perfEvents_67_value (XSCore__io_perfEvents_67_value),
    .io_perfEvents_68_value (XSCore__io_perfEvents_68_value),
    .io_beu_errors_icache_ecc_error_valid (i_XSCore__io_beu_errors_icache_ecc_error_valid),
    .io_beu_errors_icache_ecc_error_bits (i_XSCore__io_beu_errors_icache_ecc_error_bits),
    .io_beu_errors_dcache_ecc_error_valid (i_XSCore__io_beu_errors_dcache_ecc_error_valid),
    .io_beu_errors_dcache_ecc_error_bits (i_XSCore__io_beu_errors_dcache_ecc_error_bits),
    .io_beu_errors_uncache_ecc_error_valid (i_XSCore__io_beu_errors_uncache_ecc_error_valid),
    .io_beu_errors_uncache_ecc_error_bits (i_XSCore__io_beu_errors_uncache_ecc_error_bits),
    .io_l2_hint_valid (XSCore__io_l2_hint_valid),
    .io_l2_hint_bits_sourceId (XSCore__io_l2_hint_bits_sourceId),
    .io_l2_hint_bits_isKeyword (XSCore__io_l2_hint_bits_isKeyword),
    .io_l2_tlb_req_req_valid (XSCore__io_l2_tlb_req_req_valid),
    .io_l2_tlb_req_req_bits_vaddr (XSCore__io_l2_tlb_req_req_bits_vaddr),
    .io_l2_tlb_req_req_bits_cmd (XSCore__io_l2_tlb_req_req_bits_cmd),
    .io_l2_tlb_req_req_bits_kill (XSCore__io_l2_tlb_req_req_bits_kill),
    .io_l2_tlb_req_req_bits_isPrefetch (XSCore__io_l2_tlb_req_req_bits_isPrefetch),
    .io_l2_tlb_req_req_bits_no_translate (XSCore__io_l2_tlb_req_req_bits_no_translate),
    .io_l2_tlb_req_resp_valid (i_XSCore__io_l2_tlb_req_resp_valid),
    .io_l2_tlb_req_resp_bits_paddr_0 (i_XSCore__io_l2_tlb_req_resp_bits_paddr_0),
    .io_l2_tlb_req_resp_bits_pbmt_0 (i_XSCore__io_l2_tlb_req_resp_bits_pbmt_0),
    .io_l2_tlb_req_resp_bits_miss (i_XSCore__io_l2_tlb_req_resp_bits_miss),
    .io_l2_tlb_req_resp_bits_excp_0_gpf_ld (i_XSCore__io_l2_tlb_req_resp_bits_excp_0_gpf_ld),
    .io_l2_tlb_req_resp_bits_excp_0_pf_ld (i_XSCore__io_l2_tlb_req_resp_bits_excp_0_pf_ld),
    .io_l2_tlb_req_resp_bits_excp_0_af_ld (i_XSCore__io_l2_tlb_req_resp_bits_excp_0_af_ld),
    .io_l2_pmp_resp_ld (i_XSCore__io_l2_pmp_resp_ld),
    .io_l2_pmp_resp_mmio (i_XSCore__io_l2_pmp_resp_mmio),
    .io_debugTopDown_robHeadPaddr_valid (i_XSCore__io_debugTopDown_robHeadPaddr_valid),
    .io_debugTopDown_robHeadPaddr_bits (i_XSCore__io_debugTopDown_robHeadPaddr_bits),
    .io_debugTopDown_l2MissMatch (XSCore__io_debugTopDown_l2MissMatch),
    .io_debugTopDown_l3MissMatch (XSCore__io_debugTopDown_l3MissMatch),
    .io_topDownInfo_l2Miss (XSCore__io_topDownInfo_l2Miss),
    .io_topDownInfo_l3Miss (XSCore__io_topDownInfo_l3Miss),
    .io_dft_ram_hold (XSCore__io_dft_ram_hold),
    .io_dft_ram_bypass (XSCore__io_dft_ram_bypass),
    .io_dft_ram_bp_clken (XSCore__io_dft_ram_bp_clken),
    .io_dft_ram_aux_clk (XSCore__io_dft_ram_aux_clk),
    .io_dft_ram_aux_ckbp (XSCore__io_dft_ram_aux_ckbp),
    .io_dft_ram_mcp_hold (XSCore__io_dft_ram_mcp_hold),
    .io_dft_cgen (XSCore__io_dft_cgen),
    .gatewayIn_packed_0_bore (i_XSCore__gatewayIn_packed_0_bore),
    .gatewayIn_packed_1_bore (i_XSCore__gatewayIn_packed_1_bore),
    .gatewayIn_packed_2_bore (i_XSCore__gatewayIn_packed_2_bore),
    .gatewayIn_packed_3_bore (i_XSCore__gatewayIn_packed_3_bore),
    .gatewayIn_packed_4_bore (i_XSCore__gatewayIn_packed_4_bore),
    .gatewayIn_packed_5_bore (i_XSCore__gatewayIn_packed_5_bore),
    .gatewayIn_packed_6_bore (i_XSCore__gatewayIn_packed_6_bore),
    .gatewayIn_packed_7_bore (i_XSCore__gatewayIn_packed_7_bore),
    .gatewayIn_packed_8_bore (i_XSCore__gatewayIn_packed_8_bore),
    .gatewayIn_packed_9_bore (i_XSCore__gatewayIn_packed_9_bore),
    .gatewayIn_packed_10_bore (i_XSCore__gatewayIn_packed_10_bore),
    .gatewayIn_packed_11_bore (i_XSCore__gatewayIn_packed_11_bore),
    .gatewayIn_packed_12_bore (i_XSCore__gatewayIn_packed_12_bore),
    .gatewayIn_packed_13_bore (i_XSCore__gatewayIn_packed_13_bore),
    .gatewayIn_packed_14_bore (i_XSCore__gatewayIn_packed_14_bore),
    .gatewayIn_packed_15_bore (i_XSCore__gatewayIn_packed_15_bore),
    .gatewayIn_packed_16_bore (i_XSCore__gatewayIn_packed_16_bore),
    .gatewayIn_packed_17_bore (i_XSCore__gatewayIn_packed_17_bore),
    .gatewayIn_packed_18_bore (i_XSCore__gatewayIn_packed_18_bore),
    .gatewayIn_packed_19_bore (i_XSCore__gatewayIn_packed_19_bore),
    .gatewayIn_packed_20_bore (i_XSCore__gatewayIn_packed_20_bore),
    .gatewayIn_packed_21_bore (i_XSCore__gatewayIn_packed_21_bore),
    .gatewayIn_packed_22_bore (i_XSCore__gatewayIn_packed_22_bore),
    .gatewayIn_packed_23_bore (i_XSCore__gatewayIn_packed_23_bore),
    .gatewayIn_packed_24_bore (i_XSCore__gatewayIn_packed_24_bore),
    .gatewayIn_packed_25_bore (i_XSCore__gatewayIn_packed_25_bore),
    .gatewayIn_packed_26_bore (i_XSCore__gatewayIn_packed_26_bore),
    .gatewayIn_packed_27_bore (i_XSCore__gatewayIn_packed_27_bore),
    .gatewayIn_packed_28_bore (i_XSCore__gatewayIn_packed_28_bore),
    .gatewayIn_packed_29_bore (i_XSCore__gatewayIn_packed_29_bore),
    .gatewayIn_packed_30_bore (i_XSCore__gatewayIn_packed_30_bore),
    .gatewayIn_packed_31_bore (i_XSCore__gatewayIn_packed_31_bore),
    .gatewayIn_packed_32_bore (i_XSCore__gatewayIn_packed_32_bore),
    .gatewayIn_packed_33_bore (i_XSCore__gatewayIn_packed_33_bore),
    .gatewayIn_packed_34_bore (i_XSCore__gatewayIn_packed_34_bore),
    .gatewayIn_packed_35_bore (i_XSCore__gatewayIn_packed_35_bore),
    .gatewayIn_packed_36_bore (i_XSCore__gatewayIn_packed_36_bore),
    .gatewayIn_packed_37_bore (i_XSCore__gatewayIn_packed_37_bore),
    .gatewayIn_packed_38_bore (i_XSCore__gatewayIn_packed_38_bore),
    .gatewayIn_packed_39_bore (i_XSCore__gatewayIn_packed_39_bore),
    .gatewayIn_packed_40_bore (i_XSCore__gatewayIn_packed_40_bore),
    .gatewayIn_packed_41_bore (i_XSCore__gatewayIn_packed_41_bore),
    .gatewayIn_packed_42_bore (i_XSCore__gatewayIn_packed_42_bore),
    .gatewayIn_packed_43_bore (i_XSCore__gatewayIn_packed_43_bore),
    .gatewayIn_packed_44_bore (i_XSCore__gatewayIn_packed_44_bore),
    .gatewayIn_packed_45_bore (i_XSCore__gatewayIn_packed_45_bore),
    .gatewayIn_packed_46_bore (i_XSCore__gatewayIn_packed_46_bore),
    .gatewayIn_packed_47_bore (i_XSCore__gatewayIn_packed_47_bore),
    .gatewayIn_packed_48_bore (i_XSCore__gatewayIn_packed_48_bore),
    .gatewayIn_packed_49_bore (i_XSCore__gatewayIn_packed_49_bore),
    .gatewayIn_packed_50_bore (i_XSCore__gatewayIn_packed_50_bore),
    .gatewayIn_packed_51_bore (i_XSCore__gatewayIn_packed_51_bore),
    .gatewayIn_packed_52_bore (i_XSCore__gatewayIn_packed_52_bore),
    .gatewayIn_packed_53_bore (i_XSCore__gatewayIn_packed_53_bore),
    .gatewayIn_packed_54_bore (i_XSCore__gatewayIn_packed_54_bore),
    .gatewayIn_packed_55_bore (i_XSCore__gatewayIn_packed_55_bore),
    .gatewayIn_packed_56_bore (i_XSCore__gatewayIn_packed_56_bore),
    .gatewayIn_packed_57_bore (i_XSCore__gatewayIn_packed_57_bore),
    .gatewayIn_packed_58_bore (i_XSCore__gatewayIn_packed_58_bore),
    .gatewayIn_packed_59_bore (i_XSCore__gatewayIn_packed_59_bore),
    .gatewayIn_packed_60_bore (i_XSCore__gatewayIn_packed_60_bore)
  );
  task automatic drive_XSCore();
    XSCore__auto_memBlock_inner_buffers_out_a_ready = (($urandom % 4) != 0);
    XSCore__auto_memBlock_inner_buffers_out_d_valid = $urandom % 2;
    XSCore__auto_memBlock_inner_buffers_out_d_bits_opcode = rnd(4);
    XSCore__auto_memBlock_inner_buffers_out_d_bits_param = rnd(2);
    XSCore__auto_memBlock_inner_buffers_out_d_bits_size = rnd(2);
    XSCore__auto_memBlock_inner_buffers_out_d_bits_source = rnd(4);
    XSCore__auto_memBlock_inner_buffers_out_d_bits_sink = $urandom % 2;
    XSCore__auto_memBlock_inner_buffers_out_d_bits_denied = $urandom % 2;
    XSCore__auto_memBlock_inner_buffers_out_d_bits_data = rnd(64);
    XSCore__auto_memBlock_inner_buffers_out_d_bits_corrupt = $urandom % 2;
    XSCore__auto_memBlock_inner_frontendBridge_instr_uncache_out_a_ready = (($urandom % 4) != 0);
    XSCore__auto_memBlock_inner_frontendBridge_instr_uncache_out_d_valid = $urandom % 2;
    XSCore__auto_memBlock_inner_frontendBridge_instr_uncache_out_d_bits_opcode = rnd(4);
    XSCore__auto_memBlock_inner_frontendBridge_instr_uncache_out_d_bits_param = rnd(2);
    XSCore__auto_memBlock_inner_frontendBridge_instr_uncache_out_d_bits_size = rnd(2);
    XSCore__auto_memBlock_inner_frontendBridge_instr_uncache_out_d_bits_source = $urandom % 2;
    XSCore__auto_memBlock_inner_frontendBridge_instr_uncache_out_d_bits_sink = $urandom % 2;
    XSCore__auto_memBlock_inner_frontendBridge_instr_uncache_out_d_bits_denied = $urandom % 2;
    XSCore__auto_memBlock_inner_frontendBridge_instr_uncache_out_d_bits_data = rnd(64);
    XSCore__auto_memBlock_inner_frontendBridge_instr_uncache_out_d_bits_corrupt = $urandom % 2;
    XSCore__auto_memBlock_inner_frontendBridge_icachectrl_in_a_valid = $urandom % 2;
    XSCore__auto_memBlock_inner_frontendBridge_icachectrl_in_a_bits_opcode = rnd(4);
    XSCore__auto_memBlock_inner_frontendBridge_icachectrl_in_a_bits_param = rnd(3);
    XSCore__auto_memBlock_inner_frontendBridge_icachectrl_in_a_bits_size = rnd(2);
    XSCore__auto_memBlock_inner_frontendBridge_icachectrl_in_a_bits_source = rnd(5);
    XSCore__auto_memBlock_inner_frontendBridge_icachectrl_in_a_bits_address = rnd(30);
    XSCore__auto_memBlock_inner_frontendBridge_icachectrl_in_a_bits_mask = rnd(8);
    XSCore__auto_memBlock_inner_frontendBridge_icachectrl_in_a_bits_data = rnd(64);
    XSCore__auto_memBlock_inner_frontendBridge_icachectrl_in_a_bits_corrupt = $urandom % 2;
    XSCore__auto_memBlock_inner_frontendBridge_icachectrl_in_d_ready = (($urandom % 4) != 0);
    XSCore__auto_memBlock_inner_frontendBridge_icache_out_a_ready = (($urandom % 4) != 0);
    XSCore__auto_memBlock_inner_frontendBridge_icache_out_d_valid = $urandom % 2;
    XSCore__auto_memBlock_inner_frontendBridge_icache_out_d_bits_opcode = rnd(4);
    XSCore__auto_memBlock_inner_frontendBridge_icache_out_d_bits_param = rnd(2);
    XSCore__auto_memBlock_inner_frontendBridge_icache_out_d_bits_size = rnd(3);
    XSCore__auto_memBlock_inner_frontendBridge_icache_out_d_bits_source = rnd(4);
    XSCore__auto_memBlock_inner_frontendBridge_icache_out_d_bits_sink = rnd(10);
    XSCore__auto_memBlock_inner_frontendBridge_icache_out_d_bits_denied = $urandom % 2;
    XSCore__auto_memBlock_inner_frontendBridge_icache_out_d_bits_data = rnd(256);
    XSCore__auto_memBlock_inner_frontendBridge_icache_out_d_bits_corrupt = $urandom % 2;
    XSCore__auto_memBlock_inner_ptw_to_l2_buffer_out_a_ready = (($urandom % 4) != 0);
    XSCore__auto_memBlock_inner_ptw_to_l2_buffer_out_d_valid = $urandom % 2;
    XSCore__auto_memBlock_inner_ptw_to_l2_buffer_out_d_bits_opcode = rnd(4);
    XSCore__auto_memBlock_inner_ptw_to_l2_buffer_out_d_bits_param = rnd(2);
    XSCore__auto_memBlock_inner_ptw_to_l2_buffer_out_d_bits_size = rnd(3);
    XSCore__auto_memBlock_inner_ptw_to_l2_buffer_out_d_bits_source = rnd(4);
    XSCore__auto_memBlock_inner_ptw_to_l2_buffer_out_d_bits_sink = rnd(10);
    XSCore__auto_memBlock_inner_ptw_to_l2_buffer_out_d_bits_denied = $urandom % 2;
    XSCore__auto_memBlock_inner_ptw_to_l2_buffer_out_d_bits_data = rnd(256);
    XSCore__auto_memBlock_inner_ptw_to_l2_buffer_out_d_bits_corrupt = $urandom % 2;
    XSCore__auto_memBlock_inner_beu_local_int_sink_in_0 = $urandom % 2;
    XSCore__auto_memBlock_inner_nmi_int_sink_in_0 = $urandom % 2;
    XSCore__auto_memBlock_inner_nmi_int_sink_in_1 = $urandom % 2;
    XSCore__auto_memBlock_inner_plic_int_sink_in_1_0 = $urandom % 2;
    XSCore__auto_memBlock_inner_plic_int_sink_in_0_0 = $urandom % 2;
    XSCore__auto_memBlock_inner_debug_int_sink_in_0 = $urandom % 2;
    XSCore__auto_memBlock_inner_clint_int_sink_in_0 = $urandom % 2;
    XSCore__auto_memBlock_inner_clint_int_sink_in_1 = $urandom % 2;
    XSCore__auto_memBlock_inner_dcache_client_out_a_ready = (($urandom % 4) != 0);
    XSCore__auto_memBlock_inner_dcache_client_out_b_valid = $urandom % 2;
    XSCore__auto_memBlock_inner_dcache_client_out_b_bits_opcode = rnd(3);
    XSCore__auto_memBlock_inner_dcache_client_out_b_bits_param = rnd(2);
    XSCore__auto_memBlock_inner_dcache_client_out_b_bits_size = rnd(3);
    XSCore__auto_memBlock_inner_dcache_client_out_b_bits_source = rnd(6);
    XSCore__auto_memBlock_inner_dcache_client_out_b_bits_address = rnd(48);
    XSCore__auto_memBlock_inner_dcache_client_out_b_bits_mask = rnd(32);
    XSCore__auto_memBlock_inner_dcache_client_out_b_bits_data = rnd(256);
    XSCore__auto_memBlock_inner_dcache_client_out_b_bits_corrupt = $urandom % 2;
    XSCore__auto_memBlock_inner_dcache_client_out_c_ready = (($urandom % 4) != 0);
    XSCore__auto_memBlock_inner_dcache_client_out_d_valid = $urandom % 2;
    XSCore__auto_memBlock_inner_dcache_client_out_d_bits_opcode = rnd(4);
    XSCore__auto_memBlock_inner_dcache_client_out_d_bits_param = rnd(2);
    XSCore__auto_memBlock_inner_dcache_client_out_d_bits_size = rnd(3);
    XSCore__auto_memBlock_inner_dcache_client_out_d_bits_source = rnd(6);
    XSCore__auto_memBlock_inner_dcache_client_out_d_bits_sink = rnd(10);
    XSCore__auto_memBlock_inner_dcache_client_out_d_bits_denied = $urandom % 2;
    XSCore__auto_memBlock_inner_dcache_client_out_d_bits_echo_isKeyword = $urandom % 2;
    XSCore__auto_memBlock_inner_dcache_client_out_d_bits_data = rnd(256);
    XSCore__auto_memBlock_inner_dcache_client_out_d_bits_corrupt = $urandom % 2;
    XSCore__auto_memBlock_inner_dcache_client_out_e_ready = (($urandom % 4) != 0);
    XSCore__io_hartId = rnd(6);
    XSCore__io_msiInfo_valid = $urandom % 2;
    XSCore__io_msiInfo_bits = rnd(12);
    XSCore__io_clintTime_valid = $urandom % 2;
    XSCore__io_clintTime_bits = rnd(64);
    XSCore__io_reset_vector = (((cyc / 5000) % 4) == 2) ? rnd(48) : 48'h8000_0000;
    XSCore__io_l2_flush_done = $urandom % 2;
    XSCore__io_traceCoreInterface_fromEncoder_enable = $urandom % 2;
    XSCore__io_traceCoreInterface_fromEncoder_stall = $urandom % 2;
    XSCore__io_perfEvents_1_value = rnd(6);
    XSCore__io_perfEvents_2_value = rnd(6);
    XSCore__io_perfEvents_3_value = rnd(6);
    XSCore__io_perfEvents_4_value = rnd(6);
    XSCore__io_perfEvents_5_value = rnd(6);
    XSCore__io_perfEvents_6_value = rnd(6);
    XSCore__io_perfEvents_7_value = rnd(6);
    XSCore__io_perfEvents_8_value = rnd(6);
    XSCore__io_perfEvents_9_value = rnd(6);
    XSCore__io_perfEvents_10_value = rnd(6);
    XSCore__io_perfEvents_11_value = rnd(6);
    XSCore__io_perfEvents_12_value = rnd(6);
    XSCore__io_perfEvents_13_value = rnd(6);
    XSCore__io_perfEvents_14_value = rnd(6);
    XSCore__io_perfEvents_15_value = rnd(6);
    XSCore__io_perfEvents_16_value = rnd(6);
    XSCore__io_perfEvents_17_value = rnd(6);
    XSCore__io_perfEvents_18_value = rnd(6);
    XSCore__io_perfEvents_19_value = rnd(6);
    XSCore__io_perfEvents_20_value = rnd(6);
    XSCore__io_perfEvents_21_value = rnd(6);
    XSCore__io_perfEvents_22_value = rnd(6);
    XSCore__io_perfEvents_23_value = rnd(6);
    XSCore__io_perfEvents_24_value = rnd(6);
    XSCore__io_perfEvents_25_value = rnd(6);
    XSCore__io_perfEvents_26_value = rnd(6);
    XSCore__io_perfEvents_27_value = rnd(6);
    XSCore__io_perfEvents_28_value = rnd(6);
    XSCore__io_perfEvents_29_value = rnd(6);
    XSCore__io_perfEvents_30_value = rnd(6);
    XSCore__io_perfEvents_31_value = rnd(6);
    XSCore__io_perfEvents_32_value = rnd(6);
    XSCore__io_perfEvents_33_value = rnd(6);
    XSCore__io_perfEvents_34_value = rnd(6);
    XSCore__io_perfEvents_35_value = rnd(6);
    XSCore__io_perfEvents_36_value = rnd(6);
    XSCore__io_perfEvents_37_value = rnd(6);
    XSCore__io_perfEvents_38_value = rnd(6);
    XSCore__io_perfEvents_39_value = rnd(6);
    XSCore__io_perfEvents_40_value = rnd(6);
    XSCore__io_perfEvents_41_value = rnd(6);
    XSCore__io_perfEvents_42_value = rnd(6);
    XSCore__io_perfEvents_43_value = rnd(6);
    XSCore__io_perfEvents_44_value = rnd(6);
    XSCore__io_perfEvents_45_value = rnd(6);
    XSCore__io_perfEvents_46_value = rnd(6);
    XSCore__io_perfEvents_47_value = rnd(6);
    XSCore__io_perfEvents_48_value = rnd(6);
    XSCore__io_perfEvents_49_value = rnd(6);
    XSCore__io_perfEvents_50_value = rnd(6);
    XSCore__io_perfEvents_51_value = rnd(6);
    XSCore__io_perfEvents_52_value = rnd(6);
    XSCore__io_perfEvents_53_value = rnd(6);
    XSCore__io_perfEvents_54_value = rnd(6);
    XSCore__io_perfEvents_55_value = rnd(6);
    XSCore__io_perfEvents_56_value = rnd(6);
    XSCore__io_perfEvents_57_value = rnd(6);
    XSCore__io_perfEvents_58_value = rnd(6);
    XSCore__io_perfEvents_59_value = rnd(6);
    XSCore__io_perfEvents_60_value = rnd(6);
    XSCore__io_perfEvents_61_value = rnd(6);
    XSCore__io_perfEvents_62_value = rnd(6);
    XSCore__io_perfEvents_63_value = rnd(6);
    XSCore__io_perfEvents_64_value = rnd(6);
    XSCore__io_perfEvents_65_value = rnd(6);
    XSCore__io_perfEvents_66_value = rnd(6);
    XSCore__io_perfEvents_67_value = rnd(6);
    XSCore__io_perfEvents_68_value = rnd(6);
    XSCore__io_l2_hint_valid = $urandom % 2;
    XSCore__io_l2_hint_bits_sourceId = rnd(4);
    XSCore__io_l2_hint_bits_isKeyword = $urandom % 2;
    XSCore__io_l2_tlb_req_req_valid = $urandom % 2;
    XSCore__io_l2_tlb_req_req_bits_vaddr = rnd(50);
    XSCore__io_l2_tlb_req_req_bits_cmd = rnd(3);
    XSCore__io_l2_tlb_req_req_bits_kill = $urandom % 2;
    XSCore__io_l2_tlb_req_req_bits_isPrefetch = $urandom % 2;
    XSCore__io_l2_tlb_req_req_bits_no_translate = $urandom % 2;
    XSCore__io_debugTopDown_l2MissMatch = $urandom % 2;
    XSCore__io_debugTopDown_l3MissMatch = $urandom % 2;
    XSCore__io_topDownInfo_l2Miss = $urandom % 2;
    XSCore__io_topDownInfo_l3Miss = $urandom % 2;
    XSCore__io_dft_ram_hold = (((cyc / 5000) % 4) == 2) ? $urandom : '0;
    XSCore__io_dft_ram_bypass = (((cyc / 5000) % 4) == 2) ? $urandom : '0;
    XSCore__io_dft_ram_bp_clken = (((cyc / 5000) % 4) == 2) ? $urandom : '0;
    XSCore__io_dft_ram_aux_clk = (((cyc / 5000) % 4) == 2) ? $urandom : '0;
    XSCore__io_dft_ram_aux_ckbp = (((cyc / 5000) % 4) == 2) ? $urandom : '0;
    XSCore__io_dft_ram_mcp_hold = (((cyc / 5000) % 4) == 2) ? $urandom : '0;
    XSCore__io_dft_cgen = (((cyc / 5000) % 4) == 2) ? $urandom : '0;
  endtask
  task automatic check_XSCore();
    checks++;
    if (g_XSCore__auto_memBlock_inner_buffers_out_a_valid !== i_XSCore__auto_memBlock_inner_buffers_out_a_valid) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH XSCore.auto_memBlock_inner_buffers_out_a_valid g=%h i=%h", cyc, g_XSCore__auto_memBlock_inner_buffers_out_a_valid, i_XSCore__auto_memBlock_inner_buffers_out_a_valid);
    end
    if (g_XSCore__auto_memBlock_inner_buffers_out_a_valid !== p_XSCore__auto_memBlock_inner_buffers_out_a_valid) t_XSCore__auto_memBlock_inner_buffers_out_a_valid = 1'b1;
    p_XSCore__auto_memBlock_inner_buffers_out_a_valid = g_XSCore__auto_memBlock_inner_buffers_out_a_valid;
    checks++;
    if (g_XSCore__auto_memBlock_inner_buffers_out_a_bits_opcode !== i_XSCore__auto_memBlock_inner_buffers_out_a_bits_opcode) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH XSCore.auto_memBlock_inner_buffers_out_a_bits_opcode g=%h i=%h", cyc, g_XSCore__auto_memBlock_inner_buffers_out_a_bits_opcode, i_XSCore__auto_memBlock_inner_buffers_out_a_bits_opcode);
    end
    if (g_XSCore__auto_memBlock_inner_buffers_out_a_bits_opcode !== p_XSCore__auto_memBlock_inner_buffers_out_a_bits_opcode) t_XSCore__auto_memBlock_inner_buffers_out_a_bits_opcode = 1'b1;
    p_XSCore__auto_memBlock_inner_buffers_out_a_bits_opcode = g_XSCore__auto_memBlock_inner_buffers_out_a_bits_opcode;
    checks++;
    if (g_XSCore__auto_memBlock_inner_buffers_out_a_bits_param !== i_XSCore__auto_memBlock_inner_buffers_out_a_bits_param) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH XSCore.auto_memBlock_inner_buffers_out_a_bits_param g=%h i=%h", cyc, g_XSCore__auto_memBlock_inner_buffers_out_a_bits_param, i_XSCore__auto_memBlock_inner_buffers_out_a_bits_param);
    end
    if (g_XSCore__auto_memBlock_inner_buffers_out_a_bits_param !== p_XSCore__auto_memBlock_inner_buffers_out_a_bits_param) t_XSCore__auto_memBlock_inner_buffers_out_a_bits_param = 1'b1;
    p_XSCore__auto_memBlock_inner_buffers_out_a_bits_param = g_XSCore__auto_memBlock_inner_buffers_out_a_bits_param;
    checks++;
    if (g_XSCore__auto_memBlock_inner_buffers_out_a_bits_size !== i_XSCore__auto_memBlock_inner_buffers_out_a_bits_size) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH XSCore.auto_memBlock_inner_buffers_out_a_bits_size g=%h i=%h", cyc, g_XSCore__auto_memBlock_inner_buffers_out_a_bits_size, i_XSCore__auto_memBlock_inner_buffers_out_a_bits_size);
    end
    if (g_XSCore__auto_memBlock_inner_buffers_out_a_bits_size !== p_XSCore__auto_memBlock_inner_buffers_out_a_bits_size) t_XSCore__auto_memBlock_inner_buffers_out_a_bits_size = 1'b1;
    p_XSCore__auto_memBlock_inner_buffers_out_a_bits_size = g_XSCore__auto_memBlock_inner_buffers_out_a_bits_size;
    checks++;
    if (g_XSCore__auto_memBlock_inner_buffers_out_a_bits_source !== i_XSCore__auto_memBlock_inner_buffers_out_a_bits_source) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH XSCore.auto_memBlock_inner_buffers_out_a_bits_source g=%h i=%h", cyc, g_XSCore__auto_memBlock_inner_buffers_out_a_bits_source, i_XSCore__auto_memBlock_inner_buffers_out_a_bits_source);
    end
    if (g_XSCore__auto_memBlock_inner_buffers_out_a_bits_source !== p_XSCore__auto_memBlock_inner_buffers_out_a_bits_source) t_XSCore__auto_memBlock_inner_buffers_out_a_bits_source = 1'b1;
    p_XSCore__auto_memBlock_inner_buffers_out_a_bits_source = g_XSCore__auto_memBlock_inner_buffers_out_a_bits_source;
    checks++;
    if (g_XSCore__auto_memBlock_inner_buffers_out_a_bits_address !== i_XSCore__auto_memBlock_inner_buffers_out_a_bits_address) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH XSCore.auto_memBlock_inner_buffers_out_a_bits_address g=%h i=%h", cyc, g_XSCore__auto_memBlock_inner_buffers_out_a_bits_address, i_XSCore__auto_memBlock_inner_buffers_out_a_bits_address);
    end
    if (g_XSCore__auto_memBlock_inner_buffers_out_a_bits_address !== p_XSCore__auto_memBlock_inner_buffers_out_a_bits_address) t_XSCore__auto_memBlock_inner_buffers_out_a_bits_address = 1'b1;
    p_XSCore__auto_memBlock_inner_buffers_out_a_bits_address = g_XSCore__auto_memBlock_inner_buffers_out_a_bits_address;
    checks++;
    if (g_XSCore__auto_memBlock_inner_buffers_out_a_bits_user_memBackType_MM !== i_XSCore__auto_memBlock_inner_buffers_out_a_bits_user_memBackType_MM) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH XSCore.auto_memBlock_inner_buffers_out_a_bits_user_memBackType_MM g=%h i=%h", cyc, g_XSCore__auto_memBlock_inner_buffers_out_a_bits_user_memBackType_MM, i_XSCore__auto_memBlock_inner_buffers_out_a_bits_user_memBackType_MM);
    end
    if (g_XSCore__auto_memBlock_inner_buffers_out_a_bits_user_memBackType_MM !== p_XSCore__auto_memBlock_inner_buffers_out_a_bits_user_memBackType_MM) t_XSCore__auto_memBlock_inner_buffers_out_a_bits_user_memBackType_MM = 1'b1;
    p_XSCore__auto_memBlock_inner_buffers_out_a_bits_user_memBackType_MM = g_XSCore__auto_memBlock_inner_buffers_out_a_bits_user_memBackType_MM;
    checks++;
    if (g_XSCore__auto_memBlock_inner_buffers_out_a_bits_user_memPageType_NC !== i_XSCore__auto_memBlock_inner_buffers_out_a_bits_user_memPageType_NC) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH XSCore.auto_memBlock_inner_buffers_out_a_bits_user_memPageType_NC g=%h i=%h", cyc, g_XSCore__auto_memBlock_inner_buffers_out_a_bits_user_memPageType_NC, i_XSCore__auto_memBlock_inner_buffers_out_a_bits_user_memPageType_NC);
    end
    if (g_XSCore__auto_memBlock_inner_buffers_out_a_bits_user_memPageType_NC !== p_XSCore__auto_memBlock_inner_buffers_out_a_bits_user_memPageType_NC) t_XSCore__auto_memBlock_inner_buffers_out_a_bits_user_memPageType_NC = 1'b1;
    p_XSCore__auto_memBlock_inner_buffers_out_a_bits_user_memPageType_NC = g_XSCore__auto_memBlock_inner_buffers_out_a_bits_user_memPageType_NC;
    checks++;
    if (g_XSCore__auto_memBlock_inner_buffers_out_a_bits_mask !== i_XSCore__auto_memBlock_inner_buffers_out_a_bits_mask) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH XSCore.auto_memBlock_inner_buffers_out_a_bits_mask g=%h i=%h", cyc, g_XSCore__auto_memBlock_inner_buffers_out_a_bits_mask, i_XSCore__auto_memBlock_inner_buffers_out_a_bits_mask);
    end
    if (g_XSCore__auto_memBlock_inner_buffers_out_a_bits_mask !== p_XSCore__auto_memBlock_inner_buffers_out_a_bits_mask) t_XSCore__auto_memBlock_inner_buffers_out_a_bits_mask = 1'b1;
    p_XSCore__auto_memBlock_inner_buffers_out_a_bits_mask = g_XSCore__auto_memBlock_inner_buffers_out_a_bits_mask;
    checks++;
    if (g_XSCore__auto_memBlock_inner_buffers_out_a_bits_data !== i_XSCore__auto_memBlock_inner_buffers_out_a_bits_data) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH XSCore.auto_memBlock_inner_buffers_out_a_bits_data g=%h i=%h", cyc, g_XSCore__auto_memBlock_inner_buffers_out_a_bits_data, i_XSCore__auto_memBlock_inner_buffers_out_a_bits_data);
    end
    if (g_XSCore__auto_memBlock_inner_buffers_out_a_bits_data !== p_XSCore__auto_memBlock_inner_buffers_out_a_bits_data) t_XSCore__auto_memBlock_inner_buffers_out_a_bits_data = 1'b1;
    p_XSCore__auto_memBlock_inner_buffers_out_a_bits_data = g_XSCore__auto_memBlock_inner_buffers_out_a_bits_data;
    checks++;
    if (g_XSCore__auto_memBlock_inner_buffers_out_a_bits_corrupt !== i_XSCore__auto_memBlock_inner_buffers_out_a_bits_corrupt) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH XSCore.auto_memBlock_inner_buffers_out_a_bits_corrupt g=%h i=%h", cyc, g_XSCore__auto_memBlock_inner_buffers_out_a_bits_corrupt, i_XSCore__auto_memBlock_inner_buffers_out_a_bits_corrupt);
    end
    if (g_XSCore__auto_memBlock_inner_buffers_out_a_bits_corrupt !== p_XSCore__auto_memBlock_inner_buffers_out_a_bits_corrupt) t_XSCore__auto_memBlock_inner_buffers_out_a_bits_corrupt = 1'b1;
    p_XSCore__auto_memBlock_inner_buffers_out_a_bits_corrupt = g_XSCore__auto_memBlock_inner_buffers_out_a_bits_corrupt;
    checks++;
    if (g_XSCore__auto_memBlock_inner_buffers_out_d_ready !== i_XSCore__auto_memBlock_inner_buffers_out_d_ready) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH XSCore.auto_memBlock_inner_buffers_out_d_ready g=%h i=%h", cyc, g_XSCore__auto_memBlock_inner_buffers_out_d_ready, i_XSCore__auto_memBlock_inner_buffers_out_d_ready);
    end
    if (g_XSCore__auto_memBlock_inner_buffers_out_d_ready !== p_XSCore__auto_memBlock_inner_buffers_out_d_ready) t_XSCore__auto_memBlock_inner_buffers_out_d_ready = 1'b1;
    p_XSCore__auto_memBlock_inner_buffers_out_d_ready = g_XSCore__auto_memBlock_inner_buffers_out_d_ready;
    checks++;
    if (g_XSCore__auto_memBlock_inner_frontendBridge_instr_uncache_out_a_valid !== i_XSCore__auto_memBlock_inner_frontendBridge_instr_uncache_out_a_valid) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH XSCore.auto_memBlock_inner_frontendBridge_instr_uncache_out_a_valid g=%h i=%h", cyc, g_XSCore__auto_memBlock_inner_frontendBridge_instr_uncache_out_a_valid, i_XSCore__auto_memBlock_inner_frontendBridge_instr_uncache_out_a_valid);
    end
    if (g_XSCore__auto_memBlock_inner_frontendBridge_instr_uncache_out_a_valid !== p_XSCore__auto_memBlock_inner_frontendBridge_instr_uncache_out_a_valid) t_XSCore__auto_memBlock_inner_frontendBridge_instr_uncache_out_a_valid = 1'b1;
    p_XSCore__auto_memBlock_inner_frontendBridge_instr_uncache_out_a_valid = g_XSCore__auto_memBlock_inner_frontendBridge_instr_uncache_out_a_valid;
    checks++;
    if (g_XSCore__auto_memBlock_inner_frontendBridge_instr_uncache_out_a_bits_param !== i_XSCore__auto_memBlock_inner_frontendBridge_instr_uncache_out_a_bits_param) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH XSCore.auto_memBlock_inner_frontendBridge_instr_uncache_out_a_bits_param g=%h i=%h", cyc, g_XSCore__auto_memBlock_inner_frontendBridge_instr_uncache_out_a_bits_param, i_XSCore__auto_memBlock_inner_frontendBridge_instr_uncache_out_a_bits_param);
    end
    if (g_XSCore__auto_memBlock_inner_frontendBridge_instr_uncache_out_a_bits_param !== p_XSCore__auto_memBlock_inner_frontendBridge_instr_uncache_out_a_bits_param) t_XSCore__auto_memBlock_inner_frontendBridge_instr_uncache_out_a_bits_param = 1'b1;
    p_XSCore__auto_memBlock_inner_frontendBridge_instr_uncache_out_a_bits_param = g_XSCore__auto_memBlock_inner_frontendBridge_instr_uncache_out_a_bits_param;
    checks++;
    if (g_XSCore__auto_memBlock_inner_frontendBridge_instr_uncache_out_a_bits_address !== i_XSCore__auto_memBlock_inner_frontendBridge_instr_uncache_out_a_bits_address) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH XSCore.auto_memBlock_inner_frontendBridge_instr_uncache_out_a_bits_address g=%h i=%h", cyc, g_XSCore__auto_memBlock_inner_frontendBridge_instr_uncache_out_a_bits_address, i_XSCore__auto_memBlock_inner_frontendBridge_instr_uncache_out_a_bits_address);
    end
    if (g_XSCore__auto_memBlock_inner_frontendBridge_instr_uncache_out_a_bits_address !== p_XSCore__auto_memBlock_inner_frontendBridge_instr_uncache_out_a_bits_address) t_XSCore__auto_memBlock_inner_frontendBridge_instr_uncache_out_a_bits_address = 1'b1;
    p_XSCore__auto_memBlock_inner_frontendBridge_instr_uncache_out_a_bits_address = g_XSCore__auto_memBlock_inner_frontendBridge_instr_uncache_out_a_bits_address;
    checks++;
    if (g_XSCore__auto_memBlock_inner_frontendBridge_instr_uncache_out_a_bits_user_memPageType_NC !== i_XSCore__auto_memBlock_inner_frontendBridge_instr_uncache_out_a_bits_user_memPageType_NC) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH XSCore.auto_memBlock_inner_frontendBridge_instr_uncache_out_a_bits_user_memPageType_NC g=%h i=%h", cyc, g_XSCore__auto_memBlock_inner_frontendBridge_instr_uncache_out_a_bits_user_memPageType_NC, i_XSCore__auto_memBlock_inner_frontendBridge_instr_uncache_out_a_bits_user_memPageType_NC);
    end
    if (g_XSCore__auto_memBlock_inner_frontendBridge_instr_uncache_out_a_bits_user_memPageType_NC !== p_XSCore__auto_memBlock_inner_frontendBridge_instr_uncache_out_a_bits_user_memPageType_NC) t_XSCore__auto_memBlock_inner_frontendBridge_instr_uncache_out_a_bits_user_memPageType_NC = 1'b1;
    p_XSCore__auto_memBlock_inner_frontendBridge_instr_uncache_out_a_bits_user_memPageType_NC = g_XSCore__auto_memBlock_inner_frontendBridge_instr_uncache_out_a_bits_user_memPageType_NC;
    checks++;
    if (g_XSCore__auto_memBlock_inner_frontendBridge_instr_uncache_out_a_bits_user_memBackType_MM !== i_XSCore__auto_memBlock_inner_frontendBridge_instr_uncache_out_a_bits_user_memBackType_MM) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH XSCore.auto_memBlock_inner_frontendBridge_instr_uncache_out_a_bits_user_memBackType_MM g=%h i=%h", cyc, g_XSCore__auto_memBlock_inner_frontendBridge_instr_uncache_out_a_bits_user_memBackType_MM, i_XSCore__auto_memBlock_inner_frontendBridge_instr_uncache_out_a_bits_user_memBackType_MM);
    end
    if (g_XSCore__auto_memBlock_inner_frontendBridge_instr_uncache_out_a_bits_user_memBackType_MM !== p_XSCore__auto_memBlock_inner_frontendBridge_instr_uncache_out_a_bits_user_memBackType_MM) t_XSCore__auto_memBlock_inner_frontendBridge_instr_uncache_out_a_bits_user_memBackType_MM = 1'b1;
    p_XSCore__auto_memBlock_inner_frontendBridge_instr_uncache_out_a_bits_user_memBackType_MM = g_XSCore__auto_memBlock_inner_frontendBridge_instr_uncache_out_a_bits_user_memBackType_MM;
    checks++;
    if (g_XSCore__auto_memBlock_inner_frontendBridge_instr_uncache_out_a_bits_corrupt !== i_XSCore__auto_memBlock_inner_frontendBridge_instr_uncache_out_a_bits_corrupt) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH XSCore.auto_memBlock_inner_frontendBridge_instr_uncache_out_a_bits_corrupt g=%h i=%h", cyc, g_XSCore__auto_memBlock_inner_frontendBridge_instr_uncache_out_a_bits_corrupt, i_XSCore__auto_memBlock_inner_frontendBridge_instr_uncache_out_a_bits_corrupt);
    end
    if (g_XSCore__auto_memBlock_inner_frontendBridge_instr_uncache_out_a_bits_corrupt !== p_XSCore__auto_memBlock_inner_frontendBridge_instr_uncache_out_a_bits_corrupt) t_XSCore__auto_memBlock_inner_frontendBridge_instr_uncache_out_a_bits_corrupt = 1'b1;
    p_XSCore__auto_memBlock_inner_frontendBridge_instr_uncache_out_a_bits_corrupt = g_XSCore__auto_memBlock_inner_frontendBridge_instr_uncache_out_a_bits_corrupt;
    checks++;
    if (g_XSCore__auto_memBlock_inner_frontendBridge_instr_uncache_out_d_ready !== i_XSCore__auto_memBlock_inner_frontendBridge_instr_uncache_out_d_ready) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH XSCore.auto_memBlock_inner_frontendBridge_instr_uncache_out_d_ready g=%h i=%h", cyc, g_XSCore__auto_memBlock_inner_frontendBridge_instr_uncache_out_d_ready, i_XSCore__auto_memBlock_inner_frontendBridge_instr_uncache_out_d_ready);
    end
    if (g_XSCore__auto_memBlock_inner_frontendBridge_instr_uncache_out_d_ready !== p_XSCore__auto_memBlock_inner_frontendBridge_instr_uncache_out_d_ready) t_XSCore__auto_memBlock_inner_frontendBridge_instr_uncache_out_d_ready = 1'b1;
    p_XSCore__auto_memBlock_inner_frontendBridge_instr_uncache_out_d_ready = g_XSCore__auto_memBlock_inner_frontendBridge_instr_uncache_out_d_ready;
    checks++;
    if (g_XSCore__auto_memBlock_inner_frontendBridge_icachectrl_in_a_ready !== i_XSCore__auto_memBlock_inner_frontendBridge_icachectrl_in_a_ready) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH XSCore.auto_memBlock_inner_frontendBridge_icachectrl_in_a_ready g=%h i=%h", cyc, g_XSCore__auto_memBlock_inner_frontendBridge_icachectrl_in_a_ready, i_XSCore__auto_memBlock_inner_frontendBridge_icachectrl_in_a_ready);
    end
    if (g_XSCore__auto_memBlock_inner_frontendBridge_icachectrl_in_a_ready !== p_XSCore__auto_memBlock_inner_frontendBridge_icachectrl_in_a_ready) t_XSCore__auto_memBlock_inner_frontendBridge_icachectrl_in_a_ready = 1'b1;
    p_XSCore__auto_memBlock_inner_frontendBridge_icachectrl_in_a_ready = g_XSCore__auto_memBlock_inner_frontendBridge_icachectrl_in_a_ready;
    checks++;
    if (g_XSCore__auto_memBlock_inner_frontendBridge_icachectrl_in_d_valid !== i_XSCore__auto_memBlock_inner_frontendBridge_icachectrl_in_d_valid) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH XSCore.auto_memBlock_inner_frontendBridge_icachectrl_in_d_valid g=%h i=%h", cyc, g_XSCore__auto_memBlock_inner_frontendBridge_icachectrl_in_d_valid, i_XSCore__auto_memBlock_inner_frontendBridge_icachectrl_in_d_valid);
    end
    if (g_XSCore__auto_memBlock_inner_frontendBridge_icachectrl_in_d_valid !== p_XSCore__auto_memBlock_inner_frontendBridge_icachectrl_in_d_valid) t_XSCore__auto_memBlock_inner_frontendBridge_icachectrl_in_d_valid = 1'b1;
    p_XSCore__auto_memBlock_inner_frontendBridge_icachectrl_in_d_valid = g_XSCore__auto_memBlock_inner_frontendBridge_icachectrl_in_d_valid;
    checks++;
    if (g_XSCore__auto_memBlock_inner_frontendBridge_icachectrl_in_d_bits_opcode !== i_XSCore__auto_memBlock_inner_frontendBridge_icachectrl_in_d_bits_opcode) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH XSCore.auto_memBlock_inner_frontendBridge_icachectrl_in_d_bits_opcode g=%h i=%h", cyc, g_XSCore__auto_memBlock_inner_frontendBridge_icachectrl_in_d_bits_opcode, i_XSCore__auto_memBlock_inner_frontendBridge_icachectrl_in_d_bits_opcode);
    end
    if (g_XSCore__auto_memBlock_inner_frontendBridge_icachectrl_in_d_bits_opcode !== p_XSCore__auto_memBlock_inner_frontendBridge_icachectrl_in_d_bits_opcode) t_XSCore__auto_memBlock_inner_frontendBridge_icachectrl_in_d_bits_opcode = 1'b1;
    p_XSCore__auto_memBlock_inner_frontendBridge_icachectrl_in_d_bits_opcode = g_XSCore__auto_memBlock_inner_frontendBridge_icachectrl_in_d_bits_opcode;
    checks++;
    if (g_XSCore__auto_memBlock_inner_frontendBridge_icachectrl_in_d_bits_param !== i_XSCore__auto_memBlock_inner_frontendBridge_icachectrl_in_d_bits_param) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH XSCore.auto_memBlock_inner_frontendBridge_icachectrl_in_d_bits_param g=%h i=%h", cyc, g_XSCore__auto_memBlock_inner_frontendBridge_icachectrl_in_d_bits_param, i_XSCore__auto_memBlock_inner_frontendBridge_icachectrl_in_d_bits_param);
    end
    if (g_XSCore__auto_memBlock_inner_frontendBridge_icachectrl_in_d_bits_param !== p_XSCore__auto_memBlock_inner_frontendBridge_icachectrl_in_d_bits_param) t_XSCore__auto_memBlock_inner_frontendBridge_icachectrl_in_d_bits_param = 1'b1;
    p_XSCore__auto_memBlock_inner_frontendBridge_icachectrl_in_d_bits_param = g_XSCore__auto_memBlock_inner_frontendBridge_icachectrl_in_d_bits_param;
    checks++;
    if (g_XSCore__auto_memBlock_inner_frontendBridge_icachectrl_in_d_bits_size !== i_XSCore__auto_memBlock_inner_frontendBridge_icachectrl_in_d_bits_size) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH XSCore.auto_memBlock_inner_frontendBridge_icachectrl_in_d_bits_size g=%h i=%h", cyc, g_XSCore__auto_memBlock_inner_frontendBridge_icachectrl_in_d_bits_size, i_XSCore__auto_memBlock_inner_frontendBridge_icachectrl_in_d_bits_size);
    end
    if (g_XSCore__auto_memBlock_inner_frontendBridge_icachectrl_in_d_bits_size !== p_XSCore__auto_memBlock_inner_frontendBridge_icachectrl_in_d_bits_size) t_XSCore__auto_memBlock_inner_frontendBridge_icachectrl_in_d_bits_size = 1'b1;
    p_XSCore__auto_memBlock_inner_frontendBridge_icachectrl_in_d_bits_size = g_XSCore__auto_memBlock_inner_frontendBridge_icachectrl_in_d_bits_size;
    checks++;
    if (g_XSCore__auto_memBlock_inner_frontendBridge_icachectrl_in_d_bits_source !== i_XSCore__auto_memBlock_inner_frontendBridge_icachectrl_in_d_bits_source) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH XSCore.auto_memBlock_inner_frontendBridge_icachectrl_in_d_bits_source g=%h i=%h", cyc, g_XSCore__auto_memBlock_inner_frontendBridge_icachectrl_in_d_bits_source, i_XSCore__auto_memBlock_inner_frontendBridge_icachectrl_in_d_bits_source);
    end
    if (g_XSCore__auto_memBlock_inner_frontendBridge_icachectrl_in_d_bits_source !== p_XSCore__auto_memBlock_inner_frontendBridge_icachectrl_in_d_bits_source) t_XSCore__auto_memBlock_inner_frontendBridge_icachectrl_in_d_bits_source = 1'b1;
    p_XSCore__auto_memBlock_inner_frontendBridge_icachectrl_in_d_bits_source = g_XSCore__auto_memBlock_inner_frontendBridge_icachectrl_in_d_bits_source;
    checks++;
    if (g_XSCore__auto_memBlock_inner_frontendBridge_icachectrl_in_d_bits_sink !== i_XSCore__auto_memBlock_inner_frontendBridge_icachectrl_in_d_bits_sink) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH XSCore.auto_memBlock_inner_frontendBridge_icachectrl_in_d_bits_sink g=%h i=%h", cyc, g_XSCore__auto_memBlock_inner_frontendBridge_icachectrl_in_d_bits_sink, i_XSCore__auto_memBlock_inner_frontendBridge_icachectrl_in_d_bits_sink);
    end
    if (g_XSCore__auto_memBlock_inner_frontendBridge_icachectrl_in_d_bits_sink !== p_XSCore__auto_memBlock_inner_frontendBridge_icachectrl_in_d_bits_sink) t_XSCore__auto_memBlock_inner_frontendBridge_icachectrl_in_d_bits_sink = 1'b1;
    p_XSCore__auto_memBlock_inner_frontendBridge_icachectrl_in_d_bits_sink = g_XSCore__auto_memBlock_inner_frontendBridge_icachectrl_in_d_bits_sink;
    checks++;
    if (g_XSCore__auto_memBlock_inner_frontendBridge_icachectrl_in_d_bits_denied !== i_XSCore__auto_memBlock_inner_frontendBridge_icachectrl_in_d_bits_denied) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH XSCore.auto_memBlock_inner_frontendBridge_icachectrl_in_d_bits_denied g=%h i=%h", cyc, g_XSCore__auto_memBlock_inner_frontendBridge_icachectrl_in_d_bits_denied, i_XSCore__auto_memBlock_inner_frontendBridge_icachectrl_in_d_bits_denied);
    end
    if (g_XSCore__auto_memBlock_inner_frontendBridge_icachectrl_in_d_bits_denied !== p_XSCore__auto_memBlock_inner_frontendBridge_icachectrl_in_d_bits_denied) t_XSCore__auto_memBlock_inner_frontendBridge_icachectrl_in_d_bits_denied = 1'b1;
    p_XSCore__auto_memBlock_inner_frontendBridge_icachectrl_in_d_bits_denied = g_XSCore__auto_memBlock_inner_frontendBridge_icachectrl_in_d_bits_denied;
    checks++;
    if (g_XSCore__auto_memBlock_inner_frontendBridge_icachectrl_in_d_bits_data !== i_XSCore__auto_memBlock_inner_frontendBridge_icachectrl_in_d_bits_data) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH XSCore.auto_memBlock_inner_frontendBridge_icachectrl_in_d_bits_data g=%h i=%h", cyc, g_XSCore__auto_memBlock_inner_frontendBridge_icachectrl_in_d_bits_data, i_XSCore__auto_memBlock_inner_frontendBridge_icachectrl_in_d_bits_data);
    end
    if (g_XSCore__auto_memBlock_inner_frontendBridge_icachectrl_in_d_bits_data !== p_XSCore__auto_memBlock_inner_frontendBridge_icachectrl_in_d_bits_data) t_XSCore__auto_memBlock_inner_frontendBridge_icachectrl_in_d_bits_data = 1'b1;
    p_XSCore__auto_memBlock_inner_frontendBridge_icachectrl_in_d_bits_data = g_XSCore__auto_memBlock_inner_frontendBridge_icachectrl_in_d_bits_data;
    checks++;
    if (g_XSCore__auto_memBlock_inner_frontendBridge_icachectrl_in_d_bits_corrupt !== i_XSCore__auto_memBlock_inner_frontendBridge_icachectrl_in_d_bits_corrupt) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH XSCore.auto_memBlock_inner_frontendBridge_icachectrl_in_d_bits_corrupt g=%h i=%h", cyc, g_XSCore__auto_memBlock_inner_frontendBridge_icachectrl_in_d_bits_corrupt, i_XSCore__auto_memBlock_inner_frontendBridge_icachectrl_in_d_bits_corrupt);
    end
    if (g_XSCore__auto_memBlock_inner_frontendBridge_icachectrl_in_d_bits_corrupt !== p_XSCore__auto_memBlock_inner_frontendBridge_icachectrl_in_d_bits_corrupt) t_XSCore__auto_memBlock_inner_frontendBridge_icachectrl_in_d_bits_corrupt = 1'b1;
    p_XSCore__auto_memBlock_inner_frontendBridge_icachectrl_in_d_bits_corrupt = g_XSCore__auto_memBlock_inner_frontendBridge_icachectrl_in_d_bits_corrupt;
    checks++;
    if (g_XSCore__auto_memBlock_inner_frontendBridge_icache_out_a_valid !== i_XSCore__auto_memBlock_inner_frontendBridge_icache_out_a_valid) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH XSCore.auto_memBlock_inner_frontendBridge_icache_out_a_valid g=%h i=%h", cyc, g_XSCore__auto_memBlock_inner_frontendBridge_icache_out_a_valid, i_XSCore__auto_memBlock_inner_frontendBridge_icache_out_a_valid);
    end
    if (g_XSCore__auto_memBlock_inner_frontendBridge_icache_out_a_valid !== p_XSCore__auto_memBlock_inner_frontendBridge_icache_out_a_valid) t_XSCore__auto_memBlock_inner_frontendBridge_icache_out_a_valid = 1'b1;
    p_XSCore__auto_memBlock_inner_frontendBridge_icache_out_a_valid = g_XSCore__auto_memBlock_inner_frontendBridge_icache_out_a_valid;
    checks++;
    if (g_XSCore__auto_memBlock_inner_frontendBridge_icache_out_a_bits_opcode !== i_XSCore__auto_memBlock_inner_frontendBridge_icache_out_a_bits_opcode) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH XSCore.auto_memBlock_inner_frontendBridge_icache_out_a_bits_opcode g=%h i=%h", cyc, g_XSCore__auto_memBlock_inner_frontendBridge_icache_out_a_bits_opcode, i_XSCore__auto_memBlock_inner_frontendBridge_icache_out_a_bits_opcode);
    end
    if (g_XSCore__auto_memBlock_inner_frontendBridge_icache_out_a_bits_opcode !== p_XSCore__auto_memBlock_inner_frontendBridge_icache_out_a_bits_opcode) t_XSCore__auto_memBlock_inner_frontendBridge_icache_out_a_bits_opcode = 1'b1;
    p_XSCore__auto_memBlock_inner_frontendBridge_icache_out_a_bits_opcode = g_XSCore__auto_memBlock_inner_frontendBridge_icache_out_a_bits_opcode;
    checks++;
    if (g_XSCore__auto_memBlock_inner_frontendBridge_icache_out_a_bits_param !== i_XSCore__auto_memBlock_inner_frontendBridge_icache_out_a_bits_param) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH XSCore.auto_memBlock_inner_frontendBridge_icache_out_a_bits_param g=%h i=%h", cyc, g_XSCore__auto_memBlock_inner_frontendBridge_icache_out_a_bits_param, i_XSCore__auto_memBlock_inner_frontendBridge_icache_out_a_bits_param);
    end
    if (g_XSCore__auto_memBlock_inner_frontendBridge_icache_out_a_bits_param !== p_XSCore__auto_memBlock_inner_frontendBridge_icache_out_a_bits_param) t_XSCore__auto_memBlock_inner_frontendBridge_icache_out_a_bits_param = 1'b1;
    p_XSCore__auto_memBlock_inner_frontendBridge_icache_out_a_bits_param = g_XSCore__auto_memBlock_inner_frontendBridge_icache_out_a_bits_param;
    checks++;
    if (g_XSCore__auto_memBlock_inner_frontendBridge_icache_out_a_bits_size !== i_XSCore__auto_memBlock_inner_frontendBridge_icache_out_a_bits_size) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH XSCore.auto_memBlock_inner_frontendBridge_icache_out_a_bits_size g=%h i=%h", cyc, g_XSCore__auto_memBlock_inner_frontendBridge_icache_out_a_bits_size, i_XSCore__auto_memBlock_inner_frontendBridge_icache_out_a_bits_size);
    end
    if (g_XSCore__auto_memBlock_inner_frontendBridge_icache_out_a_bits_size !== p_XSCore__auto_memBlock_inner_frontendBridge_icache_out_a_bits_size) t_XSCore__auto_memBlock_inner_frontendBridge_icache_out_a_bits_size = 1'b1;
    p_XSCore__auto_memBlock_inner_frontendBridge_icache_out_a_bits_size = g_XSCore__auto_memBlock_inner_frontendBridge_icache_out_a_bits_size;
    checks++;
    if (g_XSCore__auto_memBlock_inner_frontendBridge_icache_out_a_bits_source !== i_XSCore__auto_memBlock_inner_frontendBridge_icache_out_a_bits_source) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH XSCore.auto_memBlock_inner_frontendBridge_icache_out_a_bits_source g=%h i=%h", cyc, g_XSCore__auto_memBlock_inner_frontendBridge_icache_out_a_bits_source, i_XSCore__auto_memBlock_inner_frontendBridge_icache_out_a_bits_source);
    end
    if (g_XSCore__auto_memBlock_inner_frontendBridge_icache_out_a_bits_source !== p_XSCore__auto_memBlock_inner_frontendBridge_icache_out_a_bits_source) t_XSCore__auto_memBlock_inner_frontendBridge_icache_out_a_bits_source = 1'b1;
    p_XSCore__auto_memBlock_inner_frontendBridge_icache_out_a_bits_source = g_XSCore__auto_memBlock_inner_frontendBridge_icache_out_a_bits_source;
    checks++;
    if (g_XSCore__auto_memBlock_inner_frontendBridge_icache_out_a_bits_address !== i_XSCore__auto_memBlock_inner_frontendBridge_icache_out_a_bits_address) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH XSCore.auto_memBlock_inner_frontendBridge_icache_out_a_bits_address g=%h i=%h", cyc, g_XSCore__auto_memBlock_inner_frontendBridge_icache_out_a_bits_address, i_XSCore__auto_memBlock_inner_frontendBridge_icache_out_a_bits_address);
    end
    if (g_XSCore__auto_memBlock_inner_frontendBridge_icache_out_a_bits_address !== p_XSCore__auto_memBlock_inner_frontendBridge_icache_out_a_bits_address) t_XSCore__auto_memBlock_inner_frontendBridge_icache_out_a_bits_address = 1'b1;
    p_XSCore__auto_memBlock_inner_frontendBridge_icache_out_a_bits_address = g_XSCore__auto_memBlock_inner_frontendBridge_icache_out_a_bits_address;
    checks++;
    if (g_XSCore__auto_memBlock_inner_frontendBridge_icache_out_a_bits_user_alias !== i_XSCore__auto_memBlock_inner_frontendBridge_icache_out_a_bits_user_alias) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH XSCore.auto_memBlock_inner_frontendBridge_icache_out_a_bits_user_alias g=%h i=%h", cyc, g_XSCore__auto_memBlock_inner_frontendBridge_icache_out_a_bits_user_alias, i_XSCore__auto_memBlock_inner_frontendBridge_icache_out_a_bits_user_alias);
    end
    if (g_XSCore__auto_memBlock_inner_frontendBridge_icache_out_a_bits_user_alias !== p_XSCore__auto_memBlock_inner_frontendBridge_icache_out_a_bits_user_alias) t_XSCore__auto_memBlock_inner_frontendBridge_icache_out_a_bits_user_alias = 1'b1;
    p_XSCore__auto_memBlock_inner_frontendBridge_icache_out_a_bits_user_alias = g_XSCore__auto_memBlock_inner_frontendBridge_icache_out_a_bits_user_alias;
    checks++;
    if (g_XSCore__auto_memBlock_inner_frontendBridge_icache_out_a_bits_user_reqSource !== i_XSCore__auto_memBlock_inner_frontendBridge_icache_out_a_bits_user_reqSource) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH XSCore.auto_memBlock_inner_frontendBridge_icache_out_a_bits_user_reqSource g=%h i=%h", cyc, g_XSCore__auto_memBlock_inner_frontendBridge_icache_out_a_bits_user_reqSource, i_XSCore__auto_memBlock_inner_frontendBridge_icache_out_a_bits_user_reqSource);
    end
    if (g_XSCore__auto_memBlock_inner_frontendBridge_icache_out_a_bits_user_reqSource !== p_XSCore__auto_memBlock_inner_frontendBridge_icache_out_a_bits_user_reqSource) t_XSCore__auto_memBlock_inner_frontendBridge_icache_out_a_bits_user_reqSource = 1'b1;
    p_XSCore__auto_memBlock_inner_frontendBridge_icache_out_a_bits_user_reqSource = g_XSCore__auto_memBlock_inner_frontendBridge_icache_out_a_bits_user_reqSource;
    checks++;
    if (g_XSCore__auto_memBlock_inner_frontendBridge_icache_out_a_bits_user_needHint !== i_XSCore__auto_memBlock_inner_frontendBridge_icache_out_a_bits_user_needHint) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH XSCore.auto_memBlock_inner_frontendBridge_icache_out_a_bits_user_needHint g=%h i=%h", cyc, g_XSCore__auto_memBlock_inner_frontendBridge_icache_out_a_bits_user_needHint, i_XSCore__auto_memBlock_inner_frontendBridge_icache_out_a_bits_user_needHint);
    end
    if (g_XSCore__auto_memBlock_inner_frontendBridge_icache_out_a_bits_user_needHint !== p_XSCore__auto_memBlock_inner_frontendBridge_icache_out_a_bits_user_needHint) t_XSCore__auto_memBlock_inner_frontendBridge_icache_out_a_bits_user_needHint = 1'b1;
    p_XSCore__auto_memBlock_inner_frontendBridge_icache_out_a_bits_user_needHint = g_XSCore__auto_memBlock_inner_frontendBridge_icache_out_a_bits_user_needHint;
    checks++;
    if (g_XSCore__auto_memBlock_inner_frontendBridge_icache_out_a_bits_mask !== i_XSCore__auto_memBlock_inner_frontendBridge_icache_out_a_bits_mask) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH XSCore.auto_memBlock_inner_frontendBridge_icache_out_a_bits_mask g=%h i=%h", cyc, g_XSCore__auto_memBlock_inner_frontendBridge_icache_out_a_bits_mask, i_XSCore__auto_memBlock_inner_frontendBridge_icache_out_a_bits_mask);
    end
    if (g_XSCore__auto_memBlock_inner_frontendBridge_icache_out_a_bits_mask !== p_XSCore__auto_memBlock_inner_frontendBridge_icache_out_a_bits_mask) t_XSCore__auto_memBlock_inner_frontendBridge_icache_out_a_bits_mask = 1'b1;
    p_XSCore__auto_memBlock_inner_frontendBridge_icache_out_a_bits_mask = g_XSCore__auto_memBlock_inner_frontendBridge_icache_out_a_bits_mask;
    checks++;
    if (g_XSCore__auto_memBlock_inner_frontendBridge_icache_out_a_bits_data !== i_XSCore__auto_memBlock_inner_frontendBridge_icache_out_a_bits_data) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH XSCore.auto_memBlock_inner_frontendBridge_icache_out_a_bits_data g=%h i=%h", cyc, g_XSCore__auto_memBlock_inner_frontendBridge_icache_out_a_bits_data, i_XSCore__auto_memBlock_inner_frontendBridge_icache_out_a_bits_data);
    end
    if (g_XSCore__auto_memBlock_inner_frontendBridge_icache_out_a_bits_data !== p_XSCore__auto_memBlock_inner_frontendBridge_icache_out_a_bits_data) t_XSCore__auto_memBlock_inner_frontendBridge_icache_out_a_bits_data = 1'b1;
    p_XSCore__auto_memBlock_inner_frontendBridge_icache_out_a_bits_data = g_XSCore__auto_memBlock_inner_frontendBridge_icache_out_a_bits_data;
    checks++;
    if (g_XSCore__auto_memBlock_inner_frontendBridge_icache_out_a_bits_corrupt !== i_XSCore__auto_memBlock_inner_frontendBridge_icache_out_a_bits_corrupt) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH XSCore.auto_memBlock_inner_frontendBridge_icache_out_a_bits_corrupt g=%h i=%h", cyc, g_XSCore__auto_memBlock_inner_frontendBridge_icache_out_a_bits_corrupt, i_XSCore__auto_memBlock_inner_frontendBridge_icache_out_a_bits_corrupt);
    end
    if (g_XSCore__auto_memBlock_inner_frontendBridge_icache_out_a_bits_corrupt !== p_XSCore__auto_memBlock_inner_frontendBridge_icache_out_a_bits_corrupt) t_XSCore__auto_memBlock_inner_frontendBridge_icache_out_a_bits_corrupt = 1'b1;
    p_XSCore__auto_memBlock_inner_frontendBridge_icache_out_a_bits_corrupt = g_XSCore__auto_memBlock_inner_frontendBridge_icache_out_a_bits_corrupt;
    checks++;
    if (g_XSCore__auto_memBlock_inner_frontendBridge_icache_out_d_ready !== i_XSCore__auto_memBlock_inner_frontendBridge_icache_out_d_ready) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH XSCore.auto_memBlock_inner_frontendBridge_icache_out_d_ready g=%h i=%h", cyc, g_XSCore__auto_memBlock_inner_frontendBridge_icache_out_d_ready, i_XSCore__auto_memBlock_inner_frontendBridge_icache_out_d_ready);
    end
    if (g_XSCore__auto_memBlock_inner_frontendBridge_icache_out_d_ready !== p_XSCore__auto_memBlock_inner_frontendBridge_icache_out_d_ready) t_XSCore__auto_memBlock_inner_frontendBridge_icache_out_d_ready = 1'b1;
    p_XSCore__auto_memBlock_inner_frontendBridge_icache_out_d_ready = g_XSCore__auto_memBlock_inner_frontendBridge_icache_out_d_ready;
    checks++;
    if (g_XSCore__auto_memBlock_inner_ptw_to_l2_buffer_out_a_valid !== i_XSCore__auto_memBlock_inner_ptw_to_l2_buffer_out_a_valid) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH XSCore.auto_memBlock_inner_ptw_to_l2_buffer_out_a_valid g=%h i=%h", cyc, g_XSCore__auto_memBlock_inner_ptw_to_l2_buffer_out_a_valid, i_XSCore__auto_memBlock_inner_ptw_to_l2_buffer_out_a_valid);
    end
    if (g_XSCore__auto_memBlock_inner_ptw_to_l2_buffer_out_a_valid !== p_XSCore__auto_memBlock_inner_ptw_to_l2_buffer_out_a_valid) t_XSCore__auto_memBlock_inner_ptw_to_l2_buffer_out_a_valid = 1'b1;
    p_XSCore__auto_memBlock_inner_ptw_to_l2_buffer_out_a_valid = g_XSCore__auto_memBlock_inner_ptw_to_l2_buffer_out_a_valid;
    checks++;
    if (g_XSCore__auto_memBlock_inner_ptw_to_l2_buffer_out_a_bits_opcode !== i_XSCore__auto_memBlock_inner_ptw_to_l2_buffer_out_a_bits_opcode) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH XSCore.auto_memBlock_inner_ptw_to_l2_buffer_out_a_bits_opcode g=%h i=%h", cyc, g_XSCore__auto_memBlock_inner_ptw_to_l2_buffer_out_a_bits_opcode, i_XSCore__auto_memBlock_inner_ptw_to_l2_buffer_out_a_bits_opcode);
    end
    if (g_XSCore__auto_memBlock_inner_ptw_to_l2_buffer_out_a_bits_opcode !== p_XSCore__auto_memBlock_inner_ptw_to_l2_buffer_out_a_bits_opcode) t_XSCore__auto_memBlock_inner_ptw_to_l2_buffer_out_a_bits_opcode = 1'b1;
    p_XSCore__auto_memBlock_inner_ptw_to_l2_buffer_out_a_bits_opcode = g_XSCore__auto_memBlock_inner_ptw_to_l2_buffer_out_a_bits_opcode;
    checks++;
    if (g_XSCore__auto_memBlock_inner_ptw_to_l2_buffer_out_a_bits_param !== i_XSCore__auto_memBlock_inner_ptw_to_l2_buffer_out_a_bits_param) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH XSCore.auto_memBlock_inner_ptw_to_l2_buffer_out_a_bits_param g=%h i=%h", cyc, g_XSCore__auto_memBlock_inner_ptw_to_l2_buffer_out_a_bits_param, i_XSCore__auto_memBlock_inner_ptw_to_l2_buffer_out_a_bits_param);
    end
    if (g_XSCore__auto_memBlock_inner_ptw_to_l2_buffer_out_a_bits_param !== p_XSCore__auto_memBlock_inner_ptw_to_l2_buffer_out_a_bits_param) t_XSCore__auto_memBlock_inner_ptw_to_l2_buffer_out_a_bits_param = 1'b1;
    p_XSCore__auto_memBlock_inner_ptw_to_l2_buffer_out_a_bits_param = g_XSCore__auto_memBlock_inner_ptw_to_l2_buffer_out_a_bits_param;
    checks++;
    if (g_XSCore__auto_memBlock_inner_ptw_to_l2_buffer_out_a_bits_size !== i_XSCore__auto_memBlock_inner_ptw_to_l2_buffer_out_a_bits_size) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH XSCore.auto_memBlock_inner_ptw_to_l2_buffer_out_a_bits_size g=%h i=%h", cyc, g_XSCore__auto_memBlock_inner_ptw_to_l2_buffer_out_a_bits_size, i_XSCore__auto_memBlock_inner_ptw_to_l2_buffer_out_a_bits_size);
    end
    if (g_XSCore__auto_memBlock_inner_ptw_to_l2_buffer_out_a_bits_size !== p_XSCore__auto_memBlock_inner_ptw_to_l2_buffer_out_a_bits_size) t_XSCore__auto_memBlock_inner_ptw_to_l2_buffer_out_a_bits_size = 1'b1;
    p_XSCore__auto_memBlock_inner_ptw_to_l2_buffer_out_a_bits_size = g_XSCore__auto_memBlock_inner_ptw_to_l2_buffer_out_a_bits_size;
    checks++;
    if (g_XSCore__auto_memBlock_inner_ptw_to_l2_buffer_out_a_bits_source !== i_XSCore__auto_memBlock_inner_ptw_to_l2_buffer_out_a_bits_source) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH XSCore.auto_memBlock_inner_ptw_to_l2_buffer_out_a_bits_source g=%h i=%h", cyc, g_XSCore__auto_memBlock_inner_ptw_to_l2_buffer_out_a_bits_source, i_XSCore__auto_memBlock_inner_ptw_to_l2_buffer_out_a_bits_source);
    end
    if (g_XSCore__auto_memBlock_inner_ptw_to_l2_buffer_out_a_bits_source !== p_XSCore__auto_memBlock_inner_ptw_to_l2_buffer_out_a_bits_source) t_XSCore__auto_memBlock_inner_ptw_to_l2_buffer_out_a_bits_source = 1'b1;
    p_XSCore__auto_memBlock_inner_ptw_to_l2_buffer_out_a_bits_source = g_XSCore__auto_memBlock_inner_ptw_to_l2_buffer_out_a_bits_source;
    checks++;
    if (g_XSCore__auto_memBlock_inner_ptw_to_l2_buffer_out_a_bits_address !== i_XSCore__auto_memBlock_inner_ptw_to_l2_buffer_out_a_bits_address) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH XSCore.auto_memBlock_inner_ptw_to_l2_buffer_out_a_bits_address g=%h i=%h", cyc, g_XSCore__auto_memBlock_inner_ptw_to_l2_buffer_out_a_bits_address, i_XSCore__auto_memBlock_inner_ptw_to_l2_buffer_out_a_bits_address);
    end
    if (g_XSCore__auto_memBlock_inner_ptw_to_l2_buffer_out_a_bits_address !== p_XSCore__auto_memBlock_inner_ptw_to_l2_buffer_out_a_bits_address) t_XSCore__auto_memBlock_inner_ptw_to_l2_buffer_out_a_bits_address = 1'b1;
    p_XSCore__auto_memBlock_inner_ptw_to_l2_buffer_out_a_bits_address = g_XSCore__auto_memBlock_inner_ptw_to_l2_buffer_out_a_bits_address;
    checks++;
    if (g_XSCore__auto_memBlock_inner_ptw_to_l2_buffer_out_a_bits_user_reqSource !== i_XSCore__auto_memBlock_inner_ptw_to_l2_buffer_out_a_bits_user_reqSource) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH XSCore.auto_memBlock_inner_ptw_to_l2_buffer_out_a_bits_user_reqSource g=%h i=%h", cyc, g_XSCore__auto_memBlock_inner_ptw_to_l2_buffer_out_a_bits_user_reqSource, i_XSCore__auto_memBlock_inner_ptw_to_l2_buffer_out_a_bits_user_reqSource);
    end
    if (g_XSCore__auto_memBlock_inner_ptw_to_l2_buffer_out_a_bits_user_reqSource !== p_XSCore__auto_memBlock_inner_ptw_to_l2_buffer_out_a_bits_user_reqSource) t_XSCore__auto_memBlock_inner_ptw_to_l2_buffer_out_a_bits_user_reqSource = 1'b1;
    p_XSCore__auto_memBlock_inner_ptw_to_l2_buffer_out_a_bits_user_reqSource = g_XSCore__auto_memBlock_inner_ptw_to_l2_buffer_out_a_bits_user_reqSource;
    checks++;
    if (g_XSCore__auto_memBlock_inner_ptw_to_l2_buffer_out_a_bits_mask !== i_XSCore__auto_memBlock_inner_ptw_to_l2_buffer_out_a_bits_mask) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH XSCore.auto_memBlock_inner_ptw_to_l2_buffer_out_a_bits_mask g=%h i=%h", cyc, g_XSCore__auto_memBlock_inner_ptw_to_l2_buffer_out_a_bits_mask, i_XSCore__auto_memBlock_inner_ptw_to_l2_buffer_out_a_bits_mask);
    end
    if (g_XSCore__auto_memBlock_inner_ptw_to_l2_buffer_out_a_bits_mask !== p_XSCore__auto_memBlock_inner_ptw_to_l2_buffer_out_a_bits_mask) t_XSCore__auto_memBlock_inner_ptw_to_l2_buffer_out_a_bits_mask = 1'b1;
    p_XSCore__auto_memBlock_inner_ptw_to_l2_buffer_out_a_bits_mask = g_XSCore__auto_memBlock_inner_ptw_to_l2_buffer_out_a_bits_mask;
    checks++;
    if (g_XSCore__auto_memBlock_inner_ptw_to_l2_buffer_out_a_bits_data !== i_XSCore__auto_memBlock_inner_ptw_to_l2_buffer_out_a_bits_data) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH XSCore.auto_memBlock_inner_ptw_to_l2_buffer_out_a_bits_data g=%h i=%h", cyc, g_XSCore__auto_memBlock_inner_ptw_to_l2_buffer_out_a_bits_data, i_XSCore__auto_memBlock_inner_ptw_to_l2_buffer_out_a_bits_data);
    end
    if (g_XSCore__auto_memBlock_inner_ptw_to_l2_buffer_out_a_bits_data !== p_XSCore__auto_memBlock_inner_ptw_to_l2_buffer_out_a_bits_data) t_XSCore__auto_memBlock_inner_ptw_to_l2_buffer_out_a_bits_data = 1'b1;
    p_XSCore__auto_memBlock_inner_ptw_to_l2_buffer_out_a_bits_data = g_XSCore__auto_memBlock_inner_ptw_to_l2_buffer_out_a_bits_data;
    checks++;
    if (g_XSCore__auto_memBlock_inner_ptw_to_l2_buffer_out_a_bits_corrupt !== i_XSCore__auto_memBlock_inner_ptw_to_l2_buffer_out_a_bits_corrupt) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH XSCore.auto_memBlock_inner_ptw_to_l2_buffer_out_a_bits_corrupt g=%h i=%h", cyc, g_XSCore__auto_memBlock_inner_ptw_to_l2_buffer_out_a_bits_corrupt, i_XSCore__auto_memBlock_inner_ptw_to_l2_buffer_out_a_bits_corrupt);
    end
    if (g_XSCore__auto_memBlock_inner_ptw_to_l2_buffer_out_a_bits_corrupt !== p_XSCore__auto_memBlock_inner_ptw_to_l2_buffer_out_a_bits_corrupt) t_XSCore__auto_memBlock_inner_ptw_to_l2_buffer_out_a_bits_corrupt = 1'b1;
    p_XSCore__auto_memBlock_inner_ptw_to_l2_buffer_out_a_bits_corrupt = g_XSCore__auto_memBlock_inner_ptw_to_l2_buffer_out_a_bits_corrupt;
    checks++;
    if (g_XSCore__auto_memBlock_inner_ptw_to_l2_buffer_out_d_ready !== i_XSCore__auto_memBlock_inner_ptw_to_l2_buffer_out_d_ready) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH XSCore.auto_memBlock_inner_ptw_to_l2_buffer_out_d_ready g=%h i=%h", cyc, g_XSCore__auto_memBlock_inner_ptw_to_l2_buffer_out_d_ready, i_XSCore__auto_memBlock_inner_ptw_to_l2_buffer_out_d_ready);
    end
    if (g_XSCore__auto_memBlock_inner_ptw_to_l2_buffer_out_d_ready !== p_XSCore__auto_memBlock_inner_ptw_to_l2_buffer_out_d_ready) t_XSCore__auto_memBlock_inner_ptw_to_l2_buffer_out_d_ready = 1'b1;
    p_XSCore__auto_memBlock_inner_ptw_to_l2_buffer_out_d_ready = g_XSCore__auto_memBlock_inner_ptw_to_l2_buffer_out_d_ready;
    checks++;
    if (g_XSCore__auto_memBlock_inner_l2_pf_sender_out_addr !== i_XSCore__auto_memBlock_inner_l2_pf_sender_out_addr) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH XSCore.auto_memBlock_inner_l2_pf_sender_out_addr g=%h i=%h", cyc, g_XSCore__auto_memBlock_inner_l2_pf_sender_out_addr, i_XSCore__auto_memBlock_inner_l2_pf_sender_out_addr);
    end
    if (g_XSCore__auto_memBlock_inner_l2_pf_sender_out_addr !== p_XSCore__auto_memBlock_inner_l2_pf_sender_out_addr) t_XSCore__auto_memBlock_inner_l2_pf_sender_out_addr = 1'b1;
    p_XSCore__auto_memBlock_inner_l2_pf_sender_out_addr = g_XSCore__auto_memBlock_inner_l2_pf_sender_out_addr;
    checks++;
    if (g_XSCore__auto_memBlock_inner_l2_pf_sender_out_pf_source !== i_XSCore__auto_memBlock_inner_l2_pf_sender_out_pf_source) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH XSCore.auto_memBlock_inner_l2_pf_sender_out_pf_source g=%h i=%h", cyc, g_XSCore__auto_memBlock_inner_l2_pf_sender_out_pf_source, i_XSCore__auto_memBlock_inner_l2_pf_sender_out_pf_source);
    end
    if (g_XSCore__auto_memBlock_inner_l2_pf_sender_out_pf_source !== p_XSCore__auto_memBlock_inner_l2_pf_sender_out_pf_source) t_XSCore__auto_memBlock_inner_l2_pf_sender_out_pf_source = 1'b1;
    p_XSCore__auto_memBlock_inner_l2_pf_sender_out_pf_source = g_XSCore__auto_memBlock_inner_l2_pf_sender_out_pf_source;
    checks++;
    if (g_XSCore__auto_memBlock_inner_l2_pf_sender_out_addr_valid !== i_XSCore__auto_memBlock_inner_l2_pf_sender_out_addr_valid) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH XSCore.auto_memBlock_inner_l2_pf_sender_out_addr_valid g=%h i=%h", cyc, g_XSCore__auto_memBlock_inner_l2_pf_sender_out_addr_valid, i_XSCore__auto_memBlock_inner_l2_pf_sender_out_addr_valid);
    end
    if (g_XSCore__auto_memBlock_inner_l2_pf_sender_out_addr_valid !== p_XSCore__auto_memBlock_inner_l2_pf_sender_out_addr_valid) t_XSCore__auto_memBlock_inner_l2_pf_sender_out_addr_valid = 1'b1;
    p_XSCore__auto_memBlock_inner_l2_pf_sender_out_addr_valid = g_XSCore__auto_memBlock_inner_l2_pf_sender_out_addr_valid;
    checks++;
    if (g_XSCore__auto_memBlock_inner_dcache_client_out_a_valid !== i_XSCore__auto_memBlock_inner_dcache_client_out_a_valid) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH XSCore.auto_memBlock_inner_dcache_client_out_a_valid g=%h i=%h", cyc, g_XSCore__auto_memBlock_inner_dcache_client_out_a_valid, i_XSCore__auto_memBlock_inner_dcache_client_out_a_valid);
    end
    if (g_XSCore__auto_memBlock_inner_dcache_client_out_a_valid !== p_XSCore__auto_memBlock_inner_dcache_client_out_a_valid) t_XSCore__auto_memBlock_inner_dcache_client_out_a_valid = 1'b1;
    p_XSCore__auto_memBlock_inner_dcache_client_out_a_valid = g_XSCore__auto_memBlock_inner_dcache_client_out_a_valid;
    checks++;
    if (g_XSCore__auto_memBlock_inner_dcache_client_out_a_bits_opcode !== i_XSCore__auto_memBlock_inner_dcache_client_out_a_bits_opcode) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH XSCore.auto_memBlock_inner_dcache_client_out_a_bits_opcode g=%h i=%h", cyc, g_XSCore__auto_memBlock_inner_dcache_client_out_a_bits_opcode, i_XSCore__auto_memBlock_inner_dcache_client_out_a_bits_opcode);
    end
    if (g_XSCore__auto_memBlock_inner_dcache_client_out_a_bits_opcode !== p_XSCore__auto_memBlock_inner_dcache_client_out_a_bits_opcode) t_XSCore__auto_memBlock_inner_dcache_client_out_a_bits_opcode = 1'b1;
    p_XSCore__auto_memBlock_inner_dcache_client_out_a_bits_opcode = g_XSCore__auto_memBlock_inner_dcache_client_out_a_bits_opcode;
    checks++;
    if (g_XSCore__auto_memBlock_inner_dcache_client_out_a_bits_param !== i_XSCore__auto_memBlock_inner_dcache_client_out_a_bits_param) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH XSCore.auto_memBlock_inner_dcache_client_out_a_bits_param g=%h i=%h", cyc, g_XSCore__auto_memBlock_inner_dcache_client_out_a_bits_param, i_XSCore__auto_memBlock_inner_dcache_client_out_a_bits_param);
    end
    if (g_XSCore__auto_memBlock_inner_dcache_client_out_a_bits_param !== p_XSCore__auto_memBlock_inner_dcache_client_out_a_bits_param) t_XSCore__auto_memBlock_inner_dcache_client_out_a_bits_param = 1'b1;
    p_XSCore__auto_memBlock_inner_dcache_client_out_a_bits_param = g_XSCore__auto_memBlock_inner_dcache_client_out_a_bits_param;
    checks++;
    if (g_XSCore__auto_memBlock_inner_dcache_client_out_a_bits_size !== i_XSCore__auto_memBlock_inner_dcache_client_out_a_bits_size) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH XSCore.auto_memBlock_inner_dcache_client_out_a_bits_size g=%h i=%h", cyc, g_XSCore__auto_memBlock_inner_dcache_client_out_a_bits_size, i_XSCore__auto_memBlock_inner_dcache_client_out_a_bits_size);
    end
    if (g_XSCore__auto_memBlock_inner_dcache_client_out_a_bits_size !== p_XSCore__auto_memBlock_inner_dcache_client_out_a_bits_size) t_XSCore__auto_memBlock_inner_dcache_client_out_a_bits_size = 1'b1;
    p_XSCore__auto_memBlock_inner_dcache_client_out_a_bits_size = g_XSCore__auto_memBlock_inner_dcache_client_out_a_bits_size;
    checks++;
    if (g_XSCore__auto_memBlock_inner_dcache_client_out_a_bits_source !== i_XSCore__auto_memBlock_inner_dcache_client_out_a_bits_source) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH XSCore.auto_memBlock_inner_dcache_client_out_a_bits_source g=%h i=%h", cyc, g_XSCore__auto_memBlock_inner_dcache_client_out_a_bits_source, i_XSCore__auto_memBlock_inner_dcache_client_out_a_bits_source);
    end
    if (g_XSCore__auto_memBlock_inner_dcache_client_out_a_bits_source !== p_XSCore__auto_memBlock_inner_dcache_client_out_a_bits_source) t_XSCore__auto_memBlock_inner_dcache_client_out_a_bits_source = 1'b1;
    p_XSCore__auto_memBlock_inner_dcache_client_out_a_bits_source = g_XSCore__auto_memBlock_inner_dcache_client_out_a_bits_source;
    checks++;
    if (g_XSCore__auto_memBlock_inner_dcache_client_out_a_bits_address !== i_XSCore__auto_memBlock_inner_dcache_client_out_a_bits_address) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH XSCore.auto_memBlock_inner_dcache_client_out_a_bits_address g=%h i=%h", cyc, g_XSCore__auto_memBlock_inner_dcache_client_out_a_bits_address, i_XSCore__auto_memBlock_inner_dcache_client_out_a_bits_address);
    end
    if (g_XSCore__auto_memBlock_inner_dcache_client_out_a_bits_address !== p_XSCore__auto_memBlock_inner_dcache_client_out_a_bits_address) t_XSCore__auto_memBlock_inner_dcache_client_out_a_bits_address = 1'b1;
    p_XSCore__auto_memBlock_inner_dcache_client_out_a_bits_address = g_XSCore__auto_memBlock_inner_dcache_client_out_a_bits_address;
    checks++;
    if (g_XSCore__auto_memBlock_inner_dcache_client_out_a_bits_user_alias !== i_XSCore__auto_memBlock_inner_dcache_client_out_a_bits_user_alias) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH XSCore.auto_memBlock_inner_dcache_client_out_a_bits_user_alias g=%h i=%h", cyc, g_XSCore__auto_memBlock_inner_dcache_client_out_a_bits_user_alias, i_XSCore__auto_memBlock_inner_dcache_client_out_a_bits_user_alias);
    end
    if (g_XSCore__auto_memBlock_inner_dcache_client_out_a_bits_user_alias !== p_XSCore__auto_memBlock_inner_dcache_client_out_a_bits_user_alias) t_XSCore__auto_memBlock_inner_dcache_client_out_a_bits_user_alias = 1'b1;
    p_XSCore__auto_memBlock_inner_dcache_client_out_a_bits_user_alias = g_XSCore__auto_memBlock_inner_dcache_client_out_a_bits_user_alias;
    checks++;
    if (g_XSCore__auto_memBlock_inner_dcache_client_out_a_bits_user_vaddr !== i_XSCore__auto_memBlock_inner_dcache_client_out_a_bits_user_vaddr) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH XSCore.auto_memBlock_inner_dcache_client_out_a_bits_user_vaddr g=%h i=%h", cyc, g_XSCore__auto_memBlock_inner_dcache_client_out_a_bits_user_vaddr, i_XSCore__auto_memBlock_inner_dcache_client_out_a_bits_user_vaddr);
    end
    if (g_XSCore__auto_memBlock_inner_dcache_client_out_a_bits_user_vaddr !== p_XSCore__auto_memBlock_inner_dcache_client_out_a_bits_user_vaddr) t_XSCore__auto_memBlock_inner_dcache_client_out_a_bits_user_vaddr = 1'b1;
    p_XSCore__auto_memBlock_inner_dcache_client_out_a_bits_user_vaddr = g_XSCore__auto_memBlock_inner_dcache_client_out_a_bits_user_vaddr;
    checks++;
    if (g_XSCore__auto_memBlock_inner_dcache_client_out_a_bits_user_reqSource !== i_XSCore__auto_memBlock_inner_dcache_client_out_a_bits_user_reqSource) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH XSCore.auto_memBlock_inner_dcache_client_out_a_bits_user_reqSource g=%h i=%h", cyc, g_XSCore__auto_memBlock_inner_dcache_client_out_a_bits_user_reqSource, i_XSCore__auto_memBlock_inner_dcache_client_out_a_bits_user_reqSource);
    end
    if (g_XSCore__auto_memBlock_inner_dcache_client_out_a_bits_user_reqSource !== p_XSCore__auto_memBlock_inner_dcache_client_out_a_bits_user_reqSource) t_XSCore__auto_memBlock_inner_dcache_client_out_a_bits_user_reqSource = 1'b1;
    p_XSCore__auto_memBlock_inner_dcache_client_out_a_bits_user_reqSource = g_XSCore__auto_memBlock_inner_dcache_client_out_a_bits_user_reqSource;
    checks++;
    if (g_XSCore__auto_memBlock_inner_dcache_client_out_a_bits_user_needHint !== i_XSCore__auto_memBlock_inner_dcache_client_out_a_bits_user_needHint) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH XSCore.auto_memBlock_inner_dcache_client_out_a_bits_user_needHint g=%h i=%h", cyc, g_XSCore__auto_memBlock_inner_dcache_client_out_a_bits_user_needHint, i_XSCore__auto_memBlock_inner_dcache_client_out_a_bits_user_needHint);
    end
    if (g_XSCore__auto_memBlock_inner_dcache_client_out_a_bits_user_needHint !== p_XSCore__auto_memBlock_inner_dcache_client_out_a_bits_user_needHint) t_XSCore__auto_memBlock_inner_dcache_client_out_a_bits_user_needHint = 1'b1;
    p_XSCore__auto_memBlock_inner_dcache_client_out_a_bits_user_needHint = g_XSCore__auto_memBlock_inner_dcache_client_out_a_bits_user_needHint;
    checks++;
    if (g_XSCore__auto_memBlock_inner_dcache_client_out_a_bits_echo_isKeyword !== i_XSCore__auto_memBlock_inner_dcache_client_out_a_bits_echo_isKeyword) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH XSCore.auto_memBlock_inner_dcache_client_out_a_bits_echo_isKeyword g=%h i=%h", cyc, g_XSCore__auto_memBlock_inner_dcache_client_out_a_bits_echo_isKeyword, i_XSCore__auto_memBlock_inner_dcache_client_out_a_bits_echo_isKeyword);
    end
    if (g_XSCore__auto_memBlock_inner_dcache_client_out_a_bits_echo_isKeyword !== p_XSCore__auto_memBlock_inner_dcache_client_out_a_bits_echo_isKeyword) t_XSCore__auto_memBlock_inner_dcache_client_out_a_bits_echo_isKeyword = 1'b1;
    p_XSCore__auto_memBlock_inner_dcache_client_out_a_bits_echo_isKeyword = g_XSCore__auto_memBlock_inner_dcache_client_out_a_bits_echo_isKeyword;
    checks++;
    if (g_XSCore__auto_memBlock_inner_dcache_client_out_a_bits_mask !== i_XSCore__auto_memBlock_inner_dcache_client_out_a_bits_mask) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH XSCore.auto_memBlock_inner_dcache_client_out_a_bits_mask g=%h i=%h", cyc, g_XSCore__auto_memBlock_inner_dcache_client_out_a_bits_mask, i_XSCore__auto_memBlock_inner_dcache_client_out_a_bits_mask);
    end
    if (g_XSCore__auto_memBlock_inner_dcache_client_out_a_bits_mask !== p_XSCore__auto_memBlock_inner_dcache_client_out_a_bits_mask) t_XSCore__auto_memBlock_inner_dcache_client_out_a_bits_mask = 1'b1;
    p_XSCore__auto_memBlock_inner_dcache_client_out_a_bits_mask = g_XSCore__auto_memBlock_inner_dcache_client_out_a_bits_mask;
    checks++;
    if (g_XSCore__auto_memBlock_inner_dcache_client_out_a_bits_data !== i_XSCore__auto_memBlock_inner_dcache_client_out_a_bits_data) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH XSCore.auto_memBlock_inner_dcache_client_out_a_bits_data g=%h i=%h", cyc, g_XSCore__auto_memBlock_inner_dcache_client_out_a_bits_data, i_XSCore__auto_memBlock_inner_dcache_client_out_a_bits_data);
    end
    if (g_XSCore__auto_memBlock_inner_dcache_client_out_a_bits_data !== p_XSCore__auto_memBlock_inner_dcache_client_out_a_bits_data) t_XSCore__auto_memBlock_inner_dcache_client_out_a_bits_data = 1'b1;
    p_XSCore__auto_memBlock_inner_dcache_client_out_a_bits_data = g_XSCore__auto_memBlock_inner_dcache_client_out_a_bits_data;
    checks++;
    if (g_XSCore__auto_memBlock_inner_dcache_client_out_a_bits_corrupt !== i_XSCore__auto_memBlock_inner_dcache_client_out_a_bits_corrupt) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH XSCore.auto_memBlock_inner_dcache_client_out_a_bits_corrupt g=%h i=%h", cyc, g_XSCore__auto_memBlock_inner_dcache_client_out_a_bits_corrupt, i_XSCore__auto_memBlock_inner_dcache_client_out_a_bits_corrupt);
    end
    if (g_XSCore__auto_memBlock_inner_dcache_client_out_a_bits_corrupt !== p_XSCore__auto_memBlock_inner_dcache_client_out_a_bits_corrupt) t_XSCore__auto_memBlock_inner_dcache_client_out_a_bits_corrupt = 1'b1;
    p_XSCore__auto_memBlock_inner_dcache_client_out_a_bits_corrupt = g_XSCore__auto_memBlock_inner_dcache_client_out_a_bits_corrupt;
    checks++;
    if (g_XSCore__auto_memBlock_inner_dcache_client_out_b_ready !== i_XSCore__auto_memBlock_inner_dcache_client_out_b_ready) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH XSCore.auto_memBlock_inner_dcache_client_out_b_ready g=%h i=%h", cyc, g_XSCore__auto_memBlock_inner_dcache_client_out_b_ready, i_XSCore__auto_memBlock_inner_dcache_client_out_b_ready);
    end
    if (g_XSCore__auto_memBlock_inner_dcache_client_out_b_ready !== p_XSCore__auto_memBlock_inner_dcache_client_out_b_ready) t_XSCore__auto_memBlock_inner_dcache_client_out_b_ready = 1'b1;
    p_XSCore__auto_memBlock_inner_dcache_client_out_b_ready = g_XSCore__auto_memBlock_inner_dcache_client_out_b_ready;
    checks++;
    if (g_XSCore__auto_memBlock_inner_dcache_client_out_c_valid !== i_XSCore__auto_memBlock_inner_dcache_client_out_c_valid) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH XSCore.auto_memBlock_inner_dcache_client_out_c_valid g=%h i=%h", cyc, g_XSCore__auto_memBlock_inner_dcache_client_out_c_valid, i_XSCore__auto_memBlock_inner_dcache_client_out_c_valid);
    end
    if (g_XSCore__auto_memBlock_inner_dcache_client_out_c_valid !== p_XSCore__auto_memBlock_inner_dcache_client_out_c_valid) t_XSCore__auto_memBlock_inner_dcache_client_out_c_valid = 1'b1;
    p_XSCore__auto_memBlock_inner_dcache_client_out_c_valid = g_XSCore__auto_memBlock_inner_dcache_client_out_c_valid;
    checks++;
    if (g_XSCore__auto_memBlock_inner_dcache_client_out_c_bits_opcode !== i_XSCore__auto_memBlock_inner_dcache_client_out_c_bits_opcode) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH XSCore.auto_memBlock_inner_dcache_client_out_c_bits_opcode g=%h i=%h", cyc, g_XSCore__auto_memBlock_inner_dcache_client_out_c_bits_opcode, i_XSCore__auto_memBlock_inner_dcache_client_out_c_bits_opcode);
    end
    if (g_XSCore__auto_memBlock_inner_dcache_client_out_c_bits_opcode !== p_XSCore__auto_memBlock_inner_dcache_client_out_c_bits_opcode) t_XSCore__auto_memBlock_inner_dcache_client_out_c_bits_opcode = 1'b1;
    p_XSCore__auto_memBlock_inner_dcache_client_out_c_bits_opcode = g_XSCore__auto_memBlock_inner_dcache_client_out_c_bits_opcode;
    checks++;
    if (g_XSCore__auto_memBlock_inner_dcache_client_out_c_bits_param !== i_XSCore__auto_memBlock_inner_dcache_client_out_c_bits_param) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH XSCore.auto_memBlock_inner_dcache_client_out_c_bits_param g=%h i=%h", cyc, g_XSCore__auto_memBlock_inner_dcache_client_out_c_bits_param, i_XSCore__auto_memBlock_inner_dcache_client_out_c_bits_param);
    end
    if (g_XSCore__auto_memBlock_inner_dcache_client_out_c_bits_param !== p_XSCore__auto_memBlock_inner_dcache_client_out_c_bits_param) t_XSCore__auto_memBlock_inner_dcache_client_out_c_bits_param = 1'b1;
    p_XSCore__auto_memBlock_inner_dcache_client_out_c_bits_param = g_XSCore__auto_memBlock_inner_dcache_client_out_c_bits_param;
    checks++;
    if (g_XSCore__auto_memBlock_inner_dcache_client_out_c_bits_size !== i_XSCore__auto_memBlock_inner_dcache_client_out_c_bits_size) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH XSCore.auto_memBlock_inner_dcache_client_out_c_bits_size g=%h i=%h", cyc, g_XSCore__auto_memBlock_inner_dcache_client_out_c_bits_size, i_XSCore__auto_memBlock_inner_dcache_client_out_c_bits_size);
    end
    if (g_XSCore__auto_memBlock_inner_dcache_client_out_c_bits_size !== p_XSCore__auto_memBlock_inner_dcache_client_out_c_bits_size) t_XSCore__auto_memBlock_inner_dcache_client_out_c_bits_size = 1'b1;
    p_XSCore__auto_memBlock_inner_dcache_client_out_c_bits_size = g_XSCore__auto_memBlock_inner_dcache_client_out_c_bits_size;
    checks++;
    if (g_XSCore__auto_memBlock_inner_dcache_client_out_c_bits_source !== i_XSCore__auto_memBlock_inner_dcache_client_out_c_bits_source) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH XSCore.auto_memBlock_inner_dcache_client_out_c_bits_source g=%h i=%h", cyc, g_XSCore__auto_memBlock_inner_dcache_client_out_c_bits_source, i_XSCore__auto_memBlock_inner_dcache_client_out_c_bits_source);
    end
    if (g_XSCore__auto_memBlock_inner_dcache_client_out_c_bits_source !== p_XSCore__auto_memBlock_inner_dcache_client_out_c_bits_source) t_XSCore__auto_memBlock_inner_dcache_client_out_c_bits_source = 1'b1;
    p_XSCore__auto_memBlock_inner_dcache_client_out_c_bits_source = g_XSCore__auto_memBlock_inner_dcache_client_out_c_bits_source;
    checks++;
    if (g_XSCore__auto_memBlock_inner_dcache_client_out_c_bits_address !== i_XSCore__auto_memBlock_inner_dcache_client_out_c_bits_address) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH XSCore.auto_memBlock_inner_dcache_client_out_c_bits_address g=%h i=%h", cyc, g_XSCore__auto_memBlock_inner_dcache_client_out_c_bits_address, i_XSCore__auto_memBlock_inner_dcache_client_out_c_bits_address);
    end
    if (g_XSCore__auto_memBlock_inner_dcache_client_out_c_bits_address !== p_XSCore__auto_memBlock_inner_dcache_client_out_c_bits_address) t_XSCore__auto_memBlock_inner_dcache_client_out_c_bits_address = 1'b1;
    p_XSCore__auto_memBlock_inner_dcache_client_out_c_bits_address = g_XSCore__auto_memBlock_inner_dcache_client_out_c_bits_address;
    checks++;
    if (g_XSCore__auto_memBlock_inner_dcache_client_out_c_bits_user_alias !== i_XSCore__auto_memBlock_inner_dcache_client_out_c_bits_user_alias) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH XSCore.auto_memBlock_inner_dcache_client_out_c_bits_user_alias g=%h i=%h", cyc, g_XSCore__auto_memBlock_inner_dcache_client_out_c_bits_user_alias, i_XSCore__auto_memBlock_inner_dcache_client_out_c_bits_user_alias);
    end
    if (g_XSCore__auto_memBlock_inner_dcache_client_out_c_bits_user_alias !== p_XSCore__auto_memBlock_inner_dcache_client_out_c_bits_user_alias) t_XSCore__auto_memBlock_inner_dcache_client_out_c_bits_user_alias = 1'b1;
    p_XSCore__auto_memBlock_inner_dcache_client_out_c_bits_user_alias = g_XSCore__auto_memBlock_inner_dcache_client_out_c_bits_user_alias;
    checks++;
    if (g_XSCore__auto_memBlock_inner_dcache_client_out_c_bits_user_vaddr !== i_XSCore__auto_memBlock_inner_dcache_client_out_c_bits_user_vaddr) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH XSCore.auto_memBlock_inner_dcache_client_out_c_bits_user_vaddr g=%h i=%h", cyc, g_XSCore__auto_memBlock_inner_dcache_client_out_c_bits_user_vaddr, i_XSCore__auto_memBlock_inner_dcache_client_out_c_bits_user_vaddr);
    end
    if (g_XSCore__auto_memBlock_inner_dcache_client_out_c_bits_user_vaddr !== p_XSCore__auto_memBlock_inner_dcache_client_out_c_bits_user_vaddr) t_XSCore__auto_memBlock_inner_dcache_client_out_c_bits_user_vaddr = 1'b1;
    p_XSCore__auto_memBlock_inner_dcache_client_out_c_bits_user_vaddr = g_XSCore__auto_memBlock_inner_dcache_client_out_c_bits_user_vaddr;
    checks++;
    if (g_XSCore__auto_memBlock_inner_dcache_client_out_c_bits_user_reqSource !== i_XSCore__auto_memBlock_inner_dcache_client_out_c_bits_user_reqSource) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH XSCore.auto_memBlock_inner_dcache_client_out_c_bits_user_reqSource g=%h i=%h", cyc, g_XSCore__auto_memBlock_inner_dcache_client_out_c_bits_user_reqSource, i_XSCore__auto_memBlock_inner_dcache_client_out_c_bits_user_reqSource);
    end
    if (g_XSCore__auto_memBlock_inner_dcache_client_out_c_bits_user_reqSource !== p_XSCore__auto_memBlock_inner_dcache_client_out_c_bits_user_reqSource) t_XSCore__auto_memBlock_inner_dcache_client_out_c_bits_user_reqSource = 1'b1;
    p_XSCore__auto_memBlock_inner_dcache_client_out_c_bits_user_reqSource = g_XSCore__auto_memBlock_inner_dcache_client_out_c_bits_user_reqSource;
    checks++;
    if (g_XSCore__auto_memBlock_inner_dcache_client_out_c_bits_user_needHint !== i_XSCore__auto_memBlock_inner_dcache_client_out_c_bits_user_needHint) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH XSCore.auto_memBlock_inner_dcache_client_out_c_bits_user_needHint g=%h i=%h", cyc, g_XSCore__auto_memBlock_inner_dcache_client_out_c_bits_user_needHint, i_XSCore__auto_memBlock_inner_dcache_client_out_c_bits_user_needHint);
    end
    if (g_XSCore__auto_memBlock_inner_dcache_client_out_c_bits_user_needHint !== p_XSCore__auto_memBlock_inner_dcache_client_out_c_bits_user_needHint) t_XSCore__auto_memBlock_inner_dcache_client_out_c_bits_user_needHint = 1'b1;
    p_XSCore__auto_memBlock_inner_dcache_client_out_c_bits_user_needHint = g_XSCore__auto_memBlock_inner_dcache_client_out_c_bits_user_needHint;
    checks++;
    if (g_XSCore__auto_memBlock_inner_dcache_client_out_c_bits_echo_isKeyword !== i_XSCore__auto_memBlock_inner_dcache_client_out_c_bits_echo_isKeyword) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH XSCore.auto_memBlock_inner_dcache_client_out_c_bits_echo_isKeyword g=%h i=%h", cyc, g_XSCore__auto_memBlock_inner_dcache_client_out_c_bits_echo_isKeyword, i_XSCore__auto_memBlock_inner_dcache_client_out_c_bits_echo_isKeyword);
    end
    if (g_XSCore__auto_memBlock_inner_dcache_client_out_c_bits_echo_isKeyword !== p_XSCore__auto_memBlock_inner_dcache_client_out_c_bits_echo_isKeyword) t_XSCore__auto_memBlock_inner_dcache_client_out_c_bits_echo_isKeyword = 1'b1;
    p_XSCore__auto_memBlock_inner_dcache_client_out_c_bits_echo_isKeyword = g_XSCore__auto_memBlock_inner_dcache_client_out_c_bits_echo_isKeyword;
    checks++;
    if (g_XSCore__auto_memBlock_inner_dcache_client_out_c_bits_data !== i_XSCore__auto_memBlock_inner_dcache_client_out_c_bits_data) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH XSCore.auto_memBlock_inner_dcache_client_out_c_bits_data g=%h i=%h", cyc, g_XSCore__auto_memBlock_inner_dcache_client_out_c_bits_data, i_XSCore__auto_memBlock_inner_dcache_client_out_c_bits_data);
    end
    if (g_XSCore__auto_memBlock_inner_dcache_client_out_c_bits_data !== p_XSCore__auto_memBlock_inner_dcache_client_out_c_bits_data) t_XSCore__auto_memBlock_inner_dcache_client_out_c_bits_data = 1'b1;
    p_XSCore__auto_memBlock_inner_dcache_client_out_c_bits_data = g_XSCore__auto_memBlock_inner_dcache_client_out_c_bits_data;
    checks++;
    if (g_XSCore__auto_memBlock_inner_dcache_client_out_c_bits_corrupt !== i_XSCore__auto_memBlock_inner_dcache_client_out_c_bits_corrupt) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH XSCore.auto_memBlock_inner_dcache_client_out_c_bits_corrupt g=%h i=%h", cyc, g_XSCore__auto_memBlock_inner_dcache_client_out_c_bits_corrupt, i_XSCore__auto_memBlock_inner_dcache_client_out_c_bits_corrupt);
    end
    if (g_XSCore__auto_memBlock_inner_dcache_client_out_c_bits_corrupt !== p_XSCore__auto_memBlock_inner_dcache_client_out_c_bits_corrupt) t_XSCore__auto_memBlock_inner_dcache_client_out_c_bits_corrupt = 1'b1;
    p_XSCore__auto_memBlock_inner_dcache_client_out_c_bits_corrupt = g_XSCore__auto_memBlock_inner_dcache_client_out_c_bits_corrupt;
    checks++;
    if (g_XSCore__auto_memBlock_inner_dcache_client_out_d_ready !== i_XSCore__auto_memBlock_inner_dcache_client_out_d_ready) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH XSCore.auto_memBlock_inner_dcache_client_out_d_ready g=%h i=%h", cyc, g_XSCore__auto_memBlock_inner_dcache_client_out_d_ready, i_XSCore__auto_memBlock_inner_dcache_client_out_d_ready);
    end
    if (g_XSCore__auto_memBlock_inner_dcache_client_out_d_ready !== p_XSCore__auto_memBlock_inner_dcache_client_out_d_ready) t_XSCore__auto_memBlock_inner_dcache_client_out_d_ready = 1'b1;
    p_XSCore__auto_memBlock_inner_dcache_client_out_d_ready = g_XSCore__auto_memBlock_inner_dcache_client_out_d_ready;
    checks++;
    if (g_XSCore__auto_memBlock_inner_dcache_client_out_e_valid !== i_XSCore__auto_memBlock_inner_dcache_client_out_e_valid) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH XSCore.auto_memBlock_inner_dcache_client_out_e_valid g=%h i=%h", cyc, g_XSCore__auto_memBlock_inner_dcache_client_out_e_valid, i_XSCore__auto_memBlock_inner_dcache_client_out_e_valid);
    end
    if (g_XSCore__auto_memBlock_inner_dcache_client_out_e_valid !== p_XSCore__auto_memBlock_inner_dcache_client_out_e_valid) t_XSCore__auto_memBlock_inner_dcache_client_out_e_valid = 1'b1;
    p_XSCore__auto_memBlock_inner_dcache_client_out_e_valid = g_XSCore__auto_memBlock_inner_dcache_client_out_e_valid;
    checks++;
    if (g_XSCore__auto_memBlock_inner_dcache_client_out_e_bits_sink !== i_XSCore__auto_memBlock_inner_dcache_client_out_e_bits_sink) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH XSCore.auto_memBlock_inner_dcache_client_out_e_bits_sink g=%h i=%h", cyc, g_XSCore__auto_memBlock_inner_dcache_client_out_e_bits_sink, i_XSCore__auto_memBlock_inner_dcache_client_out_e_bits_sink);
    end
    if (g_XSCore__auto_memBlock_inner_dcache_client_out_e_bits_sink !== p_XSCore__auto_memBlock_inner_dcache_client_out_e_bits_sink) t_XSCore__auto_memBlock_inner_dcache_client_out_e_bits_sink = 1'b1;
    p_XSCore__auto_memBlock_inner_dcache_client_out_e_bits_sink = g_XSCore__auto_memBlock_inner_dcache_client_out_e_bits_sink;
    checks++;
    if (g_XSCore__io_msiAck !== i_XSCore__io_msiAck) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH XSCore.io_msiAck g=%h i=%h", cyc, g_XSCore__io_msiAck, i_XSCore__io_msiAck);
    end
    if (g_XSCore__io_msiAck !== p_XSCore__io_msiAck) t_XSCore__io_msiAck = 1'b1;
    p_XSCore__io_msiAck = g_XSCore__io_msiAck;
    checks++;
    if (g_XSCore__io_cpu_halt !== i_XSCore__io_cpu_halt) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH XSCore.io_cpu_halt g=%h i=%h", cyc, g_XSCore__io_cpu_halt, i_XSCore__io_cpu_halt);
    end
    if (g_XSCore__io_cpu_halt !== p_XSCore__io_cpu_halt) t_XSCore__io_cpu_halt = 1'b1;
    p_XSCore__io_cpu_halt = g_XSCore__io_cpu_halt;
    checks++;
    if (g_XSCore__io_l2_flush_en !== i_XSCore__io_l2_flush_en) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH XSCore.io_l2_flush_en g=%h i=%h", cyc, g_XSCore__io_l2_flush_en, i_XSCore__io_l2_flush_en);
    end
    if (g_XSCore__io_l2_flush_en !== p_XSCore__io_l2_flush_en) t_XSCore__io_l2_flush_en = 1'b1;
    p_XSCore__io_l2_flush_en = g_XSCore__io_l2_flush_en;
    checks++;
    if (g_XSCore__io_power_down_en !== i_XSCore__io_power_down_en) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH XSCore.io_power_down_en g=%h i=%h", cyc, g_XSCore__io_power_down_en, i_XSCore__io_power_down_en);
    end
    if (g_XSCore__io_power_down_en !== p_XSCore__io_power_down_en) t_XSCore__io_power_down_en = 1'b1;
    p_XSCore__io_power_down_en = g_XSCore__io_power_down_en;
    checks++;
    if (g_XSCore__io_cpu_critical_error !== i_XSCore__io_cpu_critical_error) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH XSCore.io_cpu_critical_error g=%h i=%h", cyc, g_XSCore__io_cpu_critical_error, i_XSCore__io_cpu_critical_error);
    end
    if (g_XSCore__io_cpu_critical_error !== p_XSCore__io_cpu_critical_error) t_XSCore__io_cpu_critical_error = 1'b1;
    p_XSCore__io_cpu_critical_error = g_XSCore__io_cpu_critical_error;
    checks++;
    if (g_XSCore__io_resetInFrontend !== i_XSCore__io_resetInFrontend) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH XSCore.io_resetInFrontend g=%h i=%h", cyc, g_XSCore__io_resetInFrontend, i_XSCore__io_resetInFrontend);
    end
    if (g_XSCore__io_resetInFrontend !== p_XSCore__io_resetInFrontend) t_XSCore__io_resetInFrontend = 1'b1;
    p_XSCore__io_resetInFrontend = g_XSCore__io_resetInFrontend;
    checks++;
    if (g_XSCore__io_traceCoreInterface_toEncoder_priv !== i_XSCore__io_traceCoreInterface_toEncoder_priv) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH XSCore.io_traceCoreInterface_toEncoder_priv g=%h i=%h", cyc, g_XSCore__io_traceCoreInterface_toEncoder_priv, i_XSCore__io_traceCoreInterface_toEncoder_priv);
    end
    if (g_XSCore__io_traceCoreInterface_toEncoder_priv !== p_XSCore__io_traceCoreInterface_toEncoder_priv) t_XSCore__io_traceCoreInterface_toEncoder_priv = 1'b1;
    p_XSCore__io_traceCoreInterface_toEncoder_priv = g_XSCore__io_traceCoreInterface_toEncoder_priv;
    checks++;
    if (g_XSCore__io_traceCoreInterface_toEncoder_mstatus !== i_XSCore__io_traceCoreInterface_toEncoder_mstatus) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH XSCore.io_traceCoreInterface_toEncoder_mstatus g=%h i=%h", cyc, g_XSCore__io_traceCoreInterface_toEncoder_mstatus, i_XSCore__io_traceCoreInterface_toEncoder_mstatus);
    end
    if (g_XSCore__io_traceCoreInterface_toEncoder_mstatus !== p_XSCore__io_traceCoreInterface_toEncoder_mstatus) t_XSCore__io_traceCoreInterface_toEncoder_mstatus = 1'b1;
    p_XSCore__io_traceCoreInterface_toEncoder_mstatus = g_XSCore__io_traceCoreInterface_toEncoder_mstatus;
    checks++;
    if (g_XSCore__io_traceCoreInterface_toEncoder_trap_cause !== i_XSCore__io_traceCoreInterface_toEncoder_trap_cause) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH XSCore.io_traceCoreInterface_toEncoder_trap_cause g=%h i=%h", cyc, g_XSCore__io_traceCoreInterface_toEncoder_trap_cause, i_XSCore__io_traceCoreInterface_toEncoder_trap_cause);
    end
    if (g_XSCore__io_traceCoreInterface_toEncoder_trap_cause !== p_XSCore__io_traceCoreInterface_toEncoder_trap_cause) t_XSCore__io_traceCoreInterface_toEncoder_trap_cause = 1'b1;
    p_XSCore__io_traceCoreInterface_toEncoder_trap_cause = g_XSCore__io_traceCoreInterface_toEncoder_trap_cause;
    checks++;
    if (g_XSCore__io_traceCoreInterface_toEncoder_trap_tval !== i_XSCore__io_traceCoreInterface_toEncoder_trap_tval) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH XSCore.io_traceCoreInterface_toEncoder_trap_tval g=%h i=%h", cyc, g_XSCore__io_traceCoreInterface_toEncoder_trap_tval, i_XSCore__io_traceCoreInterface_toEncoder_trap_tval);
    end
    if (g_XSCore__io_traceCoreInterface_toEncoder_trap_tval !== p_XSCore__io_traceCoreInterface_toEncoder_trap_tval) t_XSCore__io_traceCoreInterface_toEncoder_trap_tval = 1'b1;
    p_XSCore__io_traceCoreInterface_toEncoder_trap_tval = g_XSCore__io_traceCoreInterface_toEncoder_trap_tval;
    checks++;
    if (g_XSCore__io_traceCoreInterface_toEncoder_groups_0_valid !== i_XSCore__io_traceCoreInterface_toEncoder_groups_0_valid) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH XSCore.io_traceCoreInterface_toEncoder_groups_0_valid g=%h i=%h", cyc, g_XSCore__io_traceCoreInterface_toEncoder_groups_0_valid, i_XSCore__io_traceCoreInterface_toEncoder_groups_0_valid);
    end
    if (g_XSCore__io_traceCoreInterface_toEncoder_groups_0_valid !== p_XSCore__io_traceCoreInterface_toEncoder_groups_0_valid) t_XSCore__io_traceCoreInterface_toEncoder_groups_0_valid = 1'b1;
    p_XSCore__io_traceCoreInterface_toEncoder_groups_0_valid = g_XSCore__io_traceCoreInterface_toEncoder_groups_0_valid;
    checks++;
    if (g_XSCore__io_traceCoreInterface_toEncoder_groups_0_bits_iaddr !== i_XSCore__io_traceCoreInterface_toEncoder_groups_0_bits_iaddr) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH XSCore.io_traceCoreInterface_toEncoder_groups_0_bits_iaddr g=%h i=%h", cyc, g_XSCore__io_traceCoreInterface_toEncoder_groups_0_bits_iaddr, i_XSCore__io_traceCoreInterface_toEncoder_groups_0_bits_iaddr);
    end
    if (g_XSCore__io_traceCoreInterface_toEncoder_groups_0_bits_iaddr !== p_XSCore__io_traceCoreInterface_toEncoder_groups_0_bits_iaddr) t_XSCore__io_traceCoreInterface_toEncoder_groups_0_bits_iaddr = 1'b1;
    p_XSCore__io_traceCoreInterface_toEncoder_groups_0_bits_iaddr = g_XSCore__io_traceCoreInterface_toEncoder_groups_0_bits_iaddr;
    checks++;
    if (g_XSCore__io_traceCoreInterface_toEncoder_groups_0_bits_itype !== i_XSCore__io_traceCoreInterface_toEncoder_groups_0_bits_itype) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH XSCore.io_traceCoreInterface_toEncoder_groups_0_bits_itype g=%h i=%h", cyc, g_XSCore__io_traceCoreInterface_toEncoder_groups_0_bits_itype, i_XSCore__io_traceCoreInterface_toEncoder_groups_0_bits_itype);
    end
    if (g_XSCore__io_traceCoreInterface_toEncoder_groups_0_bits_itype !== p_XSCore__io_traceCoreInterface_toEncoder_groups_0_bits_itype) t_XSCore__io_traceCoreInterface_toEncoder_groups_0_bits_itype = 1'b1;
    p_XSCore__io_traceCoreInterface_toEncoder_groups_0_bits_itype = g_XSCore__io_traceCoreInterface_toEncoder_groups_0_bits_itype;
    checks++;
    if (g_XSCore__io_traceCoreInterface_toEncoder_groups_0_bits_iretire !== i_XSCore__io_traceCoreInterface_toEncoder_groups_0_bits_iretire) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH XSCore.io_traceCoreInterface_toEncoder_groups_0_bits_iretire g=%h i=%h", cyc, g_XSCore__io_traceCoreInterface_toEncoder_groups_0_bits_iretire, i_XSCore__io_traceCoreInterface_toEncoder_groups_0_bits_iretire);
    end
    if (g_XSCore__io_traceCoreInterface_toEncoder_groups_0_bits_iretire !== p_XSCore__io_traceCoreInterface_toEncoder_groups_0_bits_iretire) t_XSCore__io_traceCoreInterface_toEncoder_groups_0_bits_iretire = 1'b1;
    p_XSCore__io_traceCoreInterface_toEncoder_groups_0_bits_iretire = g_XSCore__io_traceCoreInterface_toEncoder_groups_0_bits_iretire;
    checks++;
    if (g_XSCore__io_traceCoreInterface_toEncoder_groups_0_bits_ilastsize !== i_XSCore__io_traceCoreInterface_toEncoder_groups_0_bits_ilastsize) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH XSCore.io_traceCoreInterface_toEncoder_groups_0_bits_ilastsize g=%h i=%h", cyc, g_XSCore__io_traceCoreInterface_toEncoder_groups_0_bits_ilastsize, i_XSCore__io_traceCoreInterface_toEncoder_groups_0_bits_ilastsize);
    end
    if (g_XSCore__io_traceCoreInterface_toEncoder_groups_0_bits_ilastsize !== p_XSCore__io_traceCoreInterface_toEncoder_groups_0_bits_ilastsize) t_XSCore__io_traceCoreInterface_toEncoder_groups_0_bits_ilastsize = 1'b1;
    p_XSCore__io_traceCoreInterface_toEncoder_groups_0_bits_ilastsize = g_XSCore__io_traceCoreInterface_toEncoder_groups_0_bits_ilastsize;
    checks++;
    if (g_XSCore__io_traceCoreInterface_toEncoder_groups_1_valid !== i_XSCore__io_traceCoreInterface_toEncoder_groups_1_valid) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH XSCore.io_traceCoreInterface_toEncoder_groups_1_valid g=%h i=%h", cyc, g_XSCore__io_traceCoreInterface_toEncoder_groups_1_valid, i_XSCore__io_traceCoreInterface_toEncoder_groups_1_valid);
    end
    if (g_XSCore__io_traceCoreInterface_toEncoder_groups_1_valid !== p_XSCore__io_traceCoreInterface_toEncoder_groups_1_valid) t_XSCore__io_traceCoreInterface_toEncoder_groups_1_valid = 1'b1;
    p_XSCore__io_traceCoreInterface_toEncoder_groups_1_valid = g_XSCore__io_traceCoreInterface_toEncoder_groups_1_valid;
    checks++;
    if (g_XSCore__io_traceCoreInterface_toEncoder_groups_1_bits_iaddr !== i_XSCore__io_traceCoreInterface_toEncoder_groups_1_bits_iaddr) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH XSCore.io_traceCoreInterface_toEncoder_groups_1_bits_iaddr g=%h i=%h", cyc, g_XSCore__io_traceCoreInterface_toEncoder_groups_1_bits_iaddr, i_XSCore__io_traceCoreInterface_toEncoder_groups_1_bits_iaddr);
    end
    if (g_XSCore__io_traceCoreInterface_toEncoder_groups_1_bits_iaddr !== p_XSCore__io_traceCoreInterface_toEncoder_groups_1_bits_iaddr) t_XSCore__io_traceCoreInterface_toEncoder_groups_1_bits_iaddr = 1'b1;
    p_XSCore__io_traceCoreInterface_toEncoder_groups_1_bits_iaddr = g_XSCore__io_traceCoreInterface_toEncoder_groups_1_bits_iaddr;
    checks++;
    if (g_XSCore__io_traceCoreInterface_toEncoder_groups_1_bits_itype !== i_XSCore__io_traceCoreInterface_toEncoder_groups_1_bits_itype) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH XSCore.io_traceCoreInterface_toEncoder_groups_1_bits_itype g=%h i=%h", cyc, g_XSCore__io_traceCoreInterface_toEncoder_groups_1_bits_itype, i_XSCore__io_traceCoreInterface_toEncoder_groups_1_bits_itype);
    end
    if (g_XSCore__io_traceCoreInterface_toEncoder_groups_1_bits_itype !== p_XSCore__io_traceCoreInterface_toEncoder_groups_1_bits_itype) t_XSCore__io_traceCoreInterface_toEncoder_groups_1_bits_itype = 1'b1;
    p_XSCore__io_traceCoreInterface_toEncoder_groups_1_bits_itype = g_XSCore__io_traceCoreInterface_toEncoder_groups_1_bits_itype;
    checks++;
    if (g_XSCore__io_traceCoreInterface_toEncoder_groups_1_bits_iretire !== i_XSCore__io_traceCoreInterface_toEncoder_groups_1_bits_iretire) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH XSCore.io_traceCoreInterface_toEncoder_groups_1_bits_iretire g=%h i=%h", cyc, g_XSCore__io_traceCoreInterface_toEncoder_groups_1_bits_iretire, i_XSCore__io_traceCoreInterface_toEncoder_groups_1_bits_iretire);
    end
    if (g_XSCore__io_traceCoreInterface_toEncoder_groups_1_bits_iretire !== p_XSCore__io_traceCoreInterface_toEncoder_groups_1_bits_iretire) t_XSCore__io_traceCoreInterface_toEncoder_groups_1_bits_iretire = 1'b1;
    p_XSCore__io_traceCoreInterface_toEncoder_groups_1_bits_iretire = g_XSCore__io_traceCoreInterface_toEncoder_groups_1_bits_iretire;
    checks++;
    if (g_XSCore__io_traceCoreInterface_toEncoder_groups_1_bits_ilastsize !== i_XSCore__io_traceCoreInterface_toEncoder_groups_1_bits_ilastsize) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH XSCore.io_traceCoreInterface_toEncoder_groups_1_bits_ilastsize g=%h i=%h", cyc, g_XSCore__io_traceCoreInterface_toEncoder_groups_1_bits_ilastsize, i_XSCore__io_traceCoreInterface_toEncoder_groups_1_bits_ilastsize);
    end
    if (g_XSCore__io_traceCoreInterface_toEncoder_groups_1_bits_ilastsize !== p_XSCore__io_traceCoreInterface_toEncoder_groups_1_bits_ilastsize) t_XSCore__io_traceCoreInterface_toEncoder_groups_1_bits_ilastsize = 1'b1;
    p_XSCore__io_traceCoreInterface_toEncoder_groups_1_bits_ilastsize = g_XSCore__io_traceCoreInterface_toEncoder_groups_1_bits_ilastsize;
    checks++;
    if (g_XSCore__io_traceCoreInterface_toEncoder_groups_2_valid !== i_XSCore__io_traceCoreInterface_toEncoder_groups_2_valid) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH XSCore.io_traceCoreInterface_toEncoder_groups_2_valid g=%h i=%h", cyc, g_XSCore__io_traceCoreInterface_toEncoder_groups_2_valid, i_XSCore__io_traceCoreInterface_toEncoder_groups_2_valid);
    end
    if (g_XSCore__io_traceCoreInterface_toEncoder_groups_2_valid !== p_XSCore__io_traceCoreInterface_toEncoder_groups_2_valid) t_XSCore__io_traceCoreInterface_toEncoder_groups_2_valid = 1'b1;
    p_XSCore__io_traceCoreInterface_toEncoder_groups_2_valid = g_XSCore__io_traceCoreInterface_toEncoder_groups_2_valid;
    checks++;
    if (g_XSCore__io_traceCoreInterface_toEncoder_groups_2_bits_iaddr !== i_XSCore__io_traceCoreInterface_toEncoder_groups_2_bits_iaddr) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH XSCore.io_traceCoreInterface_toEncoder_groups_2_bits_iaddr g=%h i=%h", cyc, g_XSCore__io_traceCoreInterface_toEncoder_groups_2_bits_iaddr, i_XSCore__io_traceCoreInterface_toEncoder_groups_2_bits_iaddr);
    end
    if (g_XSCore__io_traceCoreInterface_toEncoder_groups_2_bits_iaddr !== p_XSCore__io_traceCoreInterface_toEncoder_groups_2_bits_iaddr) t_XSCore__io_traceCoreInterface_toEncoder_groups_2_bits_iaddr = 1'b1;
    p_XSCore__io_traceCoreInterface_toEncoder_groups_2_bits_iaddr = g_XSCore__io_traceCoreInterface_toEncoder_groups_2_bits_iaddr;
    checks++;
    if (g_XSCore__io_traceCoreInterface_toEncoder_groups_2_bits_itype !== i_XSCore__io_traceCoreInterface_toEncoder_groups_2_bits_itype) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH XSCore.io_traceCoreInterface_toEncoder_groups_2_bits_itype g=%h i=%h", cyc, g_XSCore__io_traceCoreInterface_toEncoder_groups_2_bits_itype, i_XSCore__io_traceCoreInterface_toEncoder_groups_2_bits_itype);
    end
    if (g_XSCore__io_traceCoreInterface_toEncoder_groups_2_bits_itype !== p_XSCore__io_traceCoreInterface_toEncoder_groups_2_bits_itype) t_XSCore__io_traceCoreInterface_toEncoder_groups_2_bits_itype = 1'b1;
    p_XSCore__io_traceCoreInterface_toEncoder_groups_2_bits_itype = g_XSCore__io_traceCoreInterface_toEncoder_groups_2_bits_itype;
    checks++;
    if (g_XSCore__io_traceCoreInterface_toEncoder_groups_2_bits_iretire !== i_XSCore__io_traceCoreInterface_toEncoder_groups_2_bits_iretire) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH XSCore.io_traceCoreInterface_toEncoder_groups_2_bits_iretire g=%h i=%h", cyc, g_XSCore__io_traceCoreInterface_toEncoder_groups_2_bits_iretire, i_XSCore__io_traceCoreInterface_toEncoder_groups_2_bits_iretire);
    end
    if (g_XSCore__io_traceCoreInterface_toEncoder_groups_2_bits_iretire !== p_XSCore__io_traceCoreInterface_toEncoder_groups_2_bits_iretire) t_XSCore__io_traceCoreInterface_toEncoder_groups_2_bits_iretire = 1'b1;
    p_XSCore__io_traceCoreInterface_toEncoder_groups_2_bits_iretire = g_XSCore__io_traceCoreInterface_toEncoder_groups_2_bits_iretire;
    checks++;
    if (g_XSCore__io_traceCoreInterface_toEncoder_groups_2_bits_ilastsize !== i_XSCore__io_traceCoreInterface_toEncoder_groups_2_bits_ilastsize) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH XSCore.io_traceCoreInterface_toEncoder_groups_2_bits_ilastsize g=%h i=%h", cyc, g_XSCore__io_traceCoreInterface_toEncoder_groups_2_bits_ilastsize, i_XSCore__io_traceCoreInterface_toEncoder_groups_2_bits_ilastsize);
    end
    if (g_XSCore__io_traceCoreInterface_toEncoder_groups_2_bits_ilastsize !== p_XSCore__io_traceCoreInterface_toEncoder_groups_2_bits_ilastsize) t_XSCore__io_traceCoreInterface_toEncoder_groups_2_bits_ilastsize = 1'b1;
    p_XSCore__io_traceCoreInterface_toEncoder_groups_2_bits_ilastsize = g_XSCore__io_traceCoreInterface_toEncoder_groups_2_bits_ilastsize;
    checks++;
    if (g_XSCore__io_l2PfCtrl_l2_pf_master_en !== i_XSCore__io_l2PfCtrl_l2_pf_master_en) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH XSCore.io_l2PfCtrl_l2_pf_master_en g=%h i=%h", cyc, g_XSCore__io_l2PfCtrl_l2_pf_master_en, i_XSCore__io_l2PfCtrl_l2_pf_master_en);
    end
    if (g_XSCore__io_l2PfCtrl_l2_pf_master_en !== p_XSCore__io_l2PfCtrl_l2_pf_master_en) t_XSCore__io_l2PfCtrl_l2_pf_master_en = 1'b1;
    p_XSCore__io_l2PfCtrl_l2_pf_master_en = g_XSCore__io_l2PfCtrl_l2_pf_master_en;
    checks++;
    if (g_XSCore__io_l2PfCtrl_l2_pf_recv_en !== i_XSCore__io_l2PfCtrl_l2_pf_recv_en) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH XSCore.io_l2PfCtrl_l2_pf_recv_en g=%h i=%h", cyc, g_XSCore__io_l2PfCtrl_l2_pf_recv_en, i_XSCore__io_l2PfCtrl_l2_pf_recv_en);
    end
    if (g_XSCore__io_l2PfCtrl_l2_pf_recv_en !== p_XSCore__io_l2PfCtrl_l2_pf_recv_en) t_XSCore__io_l2PfCtrl_l2_pf_recv_en = 1'b1;
    p_XSCore__io_l2PfCtrl_l2_pf_recv_en = g_XSCore__io_l2PfCtrl_l2_pf_recv_en;
    checks++;
    if (g_XSCore__io_l2PfCtrl_l2_pbop_en !== i_XSCore__io_l2PfCtrl_l2_pbop_en) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH XSCore.io_l2PfCtrl_l2_pbop_en g=%h i=%h", cyc, g_XSCore__io_l2PfCtrl_l2_pbop_en, i_XSCore__io_l2PfCtrl_l2_pbop_en);
    end
    if (g_XSCore__io_l2PfCtrl_l2_pbop_en !== p_XSCore__io_l2PfCtrl_l2_pbop_en) t_XSCore__io_l2PfCtrl_l2_pbop_en = 1'b1;
    p_XSCore__io_l2PfCtrl_l2_pbop_en = g_XSCore__io_l2PfCtrl_l2_pbop_en;
    checks++;
    if (g_XSCore__io_l2PfCtrl_l2_vbop_en !== i_XSCore__io_l2PfCtrl_l2_vbop_en) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH XSCore.io_l2PfCtrl_l2_vbop_en g=%h i=%h", cyc, g_XSCore__io_l2PfCtrl_l2_vbop_en, i_XSCore__io_l2PfCtrl_l2_vbop_en);
    end
    if (g_XSCore__io_l2PfCtrl_l2_vbop_en !== p_XSCore__io_l2PfCtrl_l2_vbop_en) t_XSCore__io_l2PfCtrl_l2_vbop_en = 1'b1;
    p_XSCore__io_l2PfCtrl_l2_vbop_en = g_XSCore__io_l2PfCtrl_l2_vbop_en;
    checks++;
    if (g_XSCore__io_l2PfCtrl_l2_pf_delay_latency !== i_XSCore__io_l2PfCtrl_l2_pf_delay_latency) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH XSCore.io_l2PfCtrl_l2_pf_delay_latency g=%h i=%h", cyc, g_XSCore__io_l2PfCtrl_l2_pf_delay_latency, i_XSCore__io_l2PfCtrl_l2_pf_delay_latency);
    end
    if (g_XSCore__io_l2PfCtrl_l2_pf_delay_latency !== p_XSCore__io_l2PfCtrl_l2_pf_delay_latency) t_XSCore__io_l2PfCtrl_l2_pf_delay_latency = 1'b1;
    p_XSCore__io_l2PfCtrl_l2_pf_delay_latency = g_XSCore__io_l2PfCtrl_l2_pf_delay_latency;
    checks++;
    if (g_XSCore__io_beu_errors_icache_ecc_error_valid !== i_XSCore__io_beu_errors_icache_ecc_error_valid) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH XSCore.io_beu_errors_icache_ecc_error_valid g=%h i=%h", cyc, g_XSCore__io_beu_errors_icache_ecc_error_valid, i_XSCore__io_beu_errors_icache_ecc_error_valid);
    end
    if (g_XSCore__io_beu_errors_icache_ecc_error_valid !== p_XSCore__io_beu_errors_icache_ecc_error_valid) t_XSCore__io_beu_errors_icache_ecc_error_valid = 1'b1;
    p_XSCore__io_beu_errors_icache_ecc_error_valid = g_XSCore__io_beu_errors_icache_ecc_error_valid;
    checks++;
    if (g_XSCore__io_beu_errors_icache_ecc_error_bits !== i_XSCore__io_beu_errors_icache_ecc_error_bits) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH XSCore.io_beu_errors_icache_ecc_error_bits g=%h i=%h", cyc, g_XSCore__io_beu_errors_icache_ecc_error_bits, i_XSCore__io_beu_errors_icache_ecc_error_bits);
    end
    if (g_XSCore__io_beu_errors_icache_ecc_error_bits !== p_XSCore__io_beu_errors_icache_ecc_error_bits) t_XSCore__io_beu_errors_icache_ecc_error_bits = 1'b1;
    p_XSCore__io_beu_errors_icache_ecc_error_bits = g_XSCore__io_beu_errors_icache_ecc_error_bits;
    checks++;
    if (g_XSCore__io_beu_errors_dcache_ecc_error_valid !== i_XSCore__io_beu_errors_dcache_ecc_error_valid) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH XSCore.io_beu_errors_dcache_ecc_error_valid g=%h i=%h", cyc, g_XSCore__io_beu_errors_dcache_ecc_error_valid, i_XSCore__io_beu_errors_dcache_ecc_error_valid);
    end
    if (g_XSCore__io_beu_errors_dcache_ecc_error_valid !== p_XSCore__io_beu_errors_dcache_ecc_error_valid) t_XSCore__io_beu_errors_dcache_ecc_error_valid = 1'b1;
    p_XSCore__io_beu_errors_dcache_ecc_error_valid = g_XSCore__io_beu_errors_dcache_ecc_error_valid;
    checks++;
    if (g_XSCore__io_beu_errors_dcache_ecc_error_bits !== i_XSCore__io_beu_errors_dcache_ecc_error_bits) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH XSCore.io_beu_errors_dcache_ecc_error_bits g=%h i=%h", cyc, g_XSCore__io_beu_errors_dcache_ecc_error_bits, i_XSCore__io_beu_errors_dcache_ecc_error_bits);
    end
    if (g_XSCore__io_beu_errors_dcache_ecc_error_bits !== p_XSCore__io_beu_errors_dcache_ecc_error_bits) t_XSCore__io_beu_errors_dcache_ecc_error_bits = 1'b1;
    p_XSCore__io_beu_errors_dcache_ecc_error_bits = g_XSCore__io_beu_errors_dcache_ecc_error_bits;
    checks++;
    if (g_XSCore__io_beu_errors_uncache_ecc_error_valid !== i_XSCore__io_beu_errors_uncache_ecc_error_valid) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH XSCore.io_beu_errors_uncache_ecc_error_valid g=%h i=%h", cyc, g_XSCore__io_beu_errors_uncache_ecc_error_valid, i_XSCore__io_beu_errors_uncache_ecc_error_valid);
    end
    if (g_XSCore__io_beu_errors_uncache_ecc_error_valid !== p_XSCore__io_beu_errors_uncache_ecc_error_valid) t_XSCore__io_beu_errors_uncache_ecc_error_valid = 1'b1;
    p_XSCore__io_beu_errors_uncache_ecc_error_valid = g_XSCore__io_beu_errors_uncache_ecc_error_valid;
    checks++;
    if (g_XSCore__io_beu_errors_uncache_ecc_error_bits !== i_XSCore__io_beu_errors_uncache_ecc_error_bits) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH XSCore.io_beu_errors_uncache_ecc_error_bits g=%h i=%h", cyc, g_XSCore__io_beu_errors_uncache_ecc_error_bits, i_XSCore__io_beu_errors_uncache_ecc_error_bits);
    end
    if (g_XSCore__io_beu_errors_uncache_ecc_error_bits !== p_XSCore__io_beu_errors_uncache_ecc_error_bits) t_XSCore__io_beu_errors_uncache_ecc_error_bits = 1'b1;
    p_XSCore__io_beu_errors_uncache_ecc_error_bits = g_XSCore__io_beu_errors_uncache_ecc_error_bits;
    checks++;
    if (g_XSCore__io_l2_tlb_req_resp_valid !== i_XSCore__io_l2_tlb_req_resp_valid) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH XSCore.io_l2_tlb_req_resp_valid g=%h i=%h", cyc, g_XSCore__io_l2_tlb_req_resp_valid, i_XSCore__io_l2_tlb_req_resp_valid);
    end
    if (g_XSCore__io_l2_tlb_req_resp_valid !== p_XSCore__io_l2_tlb_req_resp_valid) t_XSCore__io_l2_tlb_req_resp_valid = 1'b1;
    p_XSCore__io_l2_tlb_req_resp_valid = g_XSCore__io_l2_tlb_req_resp_valid;
    checks++;
    if (g_XSCore__io_l2_tlb_req_resp_bits_paddr_0 !== i_XSCore__io_l2_tlb_req_resp_bits_paddr_0) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH XSCore.io_l2_tlb_req_resp_bits_paddr_0 g=%h i=%h", cyc, g_XSCore__io_l2_tlb_req_resp_bits_paddr_0, i_XSCore__io_l2_tlb_req_resp_bits_paddr_0);
    end
    if (g_XSCore__io_l2_tlb_req_resp_bits_paddr_0 !== p_XSCore__io_l2_tlb_req_resp_bits_paddr_0) t_XSCore__io_l2_tlb_req_resp_bits_paddr_0 = 1'b1;
    p_XSCore__io_l2_tlb_req_resp_bits_paddr_0 = g_XSCore__io_l2_tlb_req_resp_bits_paddr_0;
    checks++;
    if (g_XSCore__io_l2_tlb_req_resp_bits_pbmt_0 !== i_XSCore__io_l2_tlb_req_resp_bits_pbmt_0) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH XSCore.io_l2_tlb_req_resp_bits_pbmt_0 g=%h i=%h", cyc, g_XSCore__io_l2_tlb_req_resp_bits_pbmt_0, i_XSCore__io_l2_tlb_req_resp_bits_pbmt_0);
    end
    if (g_XSCore__io_l2_tlb_req_resp_bits_pbmt_0 !== p_XSCore__io_l2_tlb_req_resp_bits_pbmt_0) t_XSCore__io_l2_tlb_req_resp_bits_pbmt_0 = 1'b1;
    p_XSCore__io_l2_tlb_req_resp_bits_pbmt_0 = g_XSCore__io_l2_tlb_req_resp_bits_pbmt_0;
    checks++;
    if (g_XSCore__io_l2_tlb_req_resp_bits_miss !== i_XSCore__io_l2_tlb_req_resp_bits_miss) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH XSCore.io_l2_tlb_req_resp_bits_miss g=%h i=%h", cyc, g_XSCore__io_l2_tlb_req_resp_bits_miss, i_XSCore__io_l2_tlb_req_resp_bits_miss);
    end
    if (g_XSCore__io_l2_tlb_req_resp_bits_miss !== p_XSCore__io_l2_tlb_req_resp_bits_miss) t_XSCore__io_l2_tlb_req_resp_bits_miss = 1'b1;
    p_XSCore__io_l2_tlb_req_resp_bits_miss = g_XSCore__io_l2_tlb_req_resp_bits_miss;
    checks++;
    if (g_XSCore__io_l2_tlb_req_resp_bits_excp_0_gpf_ld !== i_XSCore__io_l2_tlb_req_resp_bits_excp_0_gpf_ld) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH XSCore.io_l2_tlb_req_resp_bits_excp_0_gpf_ld g=%h i=%h", cyc, g_XSCore__io_l2_tlb_req_resp_bits_excp_0_gpf_ld, i_XSCore__io_l2_tlb_req_resp_bits_excp_0_gpf_ld);
    end
    if (g_XSCore__io_l2_tlb_req_resp_bits_excp_0_gpf_ld !== p_XSCore__io_l2_tlb_req_resp_bits_excp_0_gpf_ld) t_XSCore__io_l2_tlb_req_resp_bits_excp_0_gpf_ld = 1'b1;
    p_XSCore__io_l2_tlb_req_resp_bits_excp_0_gpf_ld = g_XSCore__io_l2_tlb_req_resp_bits_excp_0_gpf_ld;
    checks++;
    if (g_XSCore__io_l2_tlb_req_resp_bits_excp_0_pf_ld !== i_XSCore__io_l2_tlb_req_resp_bits_excp_0_pf_ld) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH XSCore.io_l2_tlb_req_resp_bits_excp_0_pf_ld g=%h i=%h", cyc, g_XSCore__io_l2_tlb_req_resp_bits_excp_0_pf_ld, i_XSCore__io_l2_tlb_req_resp_bits_excp_0_pf_ld);
    end
    if (g_XSCore__io_l2_tlb_req_resp_bits_excp_0_pf_ld !== p_XSCore__io_l2_tlb_req_resp_bits_excp_0_pf_ld) t_XSCore__io_l2_tlb_req_resp_bits_excp_0_pf_ld = 1'b1;
    p_XSCore__io_l2_tlb_req_resp_bits_excp_0_pf_ld = g_XSCore__io_l2_tlb_req_resp_bits_excp_0_pf_ld;
    checks++;
    if (g_XSCore__io_l2_tlb_req_resp_bits_excp_0_af_ld !== i_XSCore__io_l2_tlb_req_resp_bits_excp_0_af_ld) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH XSCore.io_l2_tlb_req_resp_bits_excp_0_af_ld g=%h i=%h", cyc, g_XSCore__io_l2_tlb_req_resp_bits_excp_0_af_ld, i_XSCore__io_l2_tlb_req_resp_bits_excp_0_af_ld);
    end
    if (g_XSCore__io_l2_tlb_req_resp_bits_excp_0_af_ld !== p_XSCore__io_l2_tlb_req_resp_bits_excp_0_af_ld) t_XSCore__io_l2_tlb_req_resp_bits_excp_0_af_ld = 1'b1;
    p_XSCore__io_l2_tlb_req_resp_bits_excp_0_af_ld = g_XSCore__io_l2_tlb_req_resp_bits_excp_0_af_ld;
    checks++;
    if (g_XSCore__io_l2_pmp_resp_ld !== i_XSCore__io_l2_pmp_resp_ld) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH XSCore.io_l2_pmp_resp_ld g=%h i=%h", cyc, g_XSCore__io_l2_pmp_resp_ld, i_XSCore__io_l2_pmp_resp_ld);
    end
    if (g_XSCore__io_l2_pmp_resp_ld !== p_XSCore__io_l2_pmp_resp_ld) t_XSCore__io_l2_pmp_resp_ld = 1'b1;
    p_XSCore__io_l2_pmp_resp_ld = g_XSCore__io_l2_pmp_resp_ld;
    checks++;
    if (g_XSCore__io_l2_pmp_resp_mmio !== i_XSCore__io_l2_pmp_resp_mmio) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH XSCore.io_l2_pmp_resp_mmio g=%h i=%h", cyc, g_XSCore__io_l2_pmp_resp_mmio, i_XSCore__io_l2_pmp_resp_mmio);
    end
    if (g_XSCore__io_l2_pmp_resp_mmio !== p_XSCore__io_l2_pmp_resp_mmio) t_XSCore__io_l2_pmp_resp_mmio = 1'b1;
    p_XSCore__io_l2_pmp_resp_mmio = g_XSCore__io_l2_pmp_resp_mmio;
    checks++;
    if (g_XSCore__io_debugTopDown_robHeadPaddr_valid !== i_XSCore__io_debugTopDown_robHeadPaddr_valid) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH XSCore.io_debugTopDown_robHeadPaddr_valid g=%h i=%h", cyc, g_XSCore__io_debugTopDown_robHeadPaddr_valid, i_XSCore__io_debugTopDown_robHeadPaddr_valid);
    end
    if (g_XSCore__io_debugTopDown_robHeadPaddr_valid !== p_XSCore__io_debugTopDown_robHeadPaddr_valid) t_XSCore__io_debugTopDown_robHeadPaddr_valid = 1'b1;
    p_XSCore__io_debugTopDown_robHeadPaddr_valid = g_XSCore__io_debugTopDown_robHeadPaddr_valid;
    checks++;
    if (g_XSCore__io_debugTopDown_robHeadPaddr_bits !== i_XSCore__io_debugTopDown_robHeadPaddr_bits) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH XSCore.io_debugTopDown_robHeadPaddr_bits g=%h i=%h", cyc, g_XSCore__io_debugTopDown_robHeadPaddr_bits, i_XSCore__io_debugTopDown_robHeadPaddr_bits);
    end
    if (g_XSCore__io_debugTopDown_robHeadPaddr_bits !== p_XSCore__io_debugTopDown_robHeadPaddr_bits) t_XSCore__io_debugTopDown_robHeadPaddr_bits = 1'b1;
    p_XSCore__io_debugTopDown_robHeadPaddr_bits = g_XSCore__io_debugTopDown_robHeadPaddr_bits;
    checks++;
    if (g_XSCore__gatewayIn_packed_0_bore !== i_XSCore__gatewayIn_packed_0_bore) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH XSCore.gatewayIn_packed_0_bore g=%h i=%h", cyc, g_XSCore__gatewayIn_packed_0_bore, i_XSCore__gatewayIn_packed_0_bore);
    end
    if (g_XSCore__gatewayIn_packed_0_bore !== p_XSCore__gatewayIn_packed_0_bore) t_XSCore__gatewayIn_packed_0_bore = 1'b1;
    p_XSCore__gatewayIn_packed_0_bore = g_XSCore__gatewayIn_packed_0_bore;
    checks++;
    if (g_XSCore__gatewayIn_packed_1_bore !== i_XSCore__gatewayIn_packed_1_bore) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH XSCore.gatewayIn_packed_1_bore g=%h i=%h", cyc, g_XSCore__gatewayIn_packed_1_bore, i_XSCore__gatewayIn_packed_1_bore);
    end
    if (g_XSCore__gatewayIn_packed_1_bore !== p_XSCore__gatewayIn_packed_1_bore) t_XSCore__gatewayIn_packed_1_bore = 1'b1;
    p_XSCore__gatewayIn_packed_1_bore = g_XSCore__gatewayIn_packed_1_bore;
    checks++;
    if (g_XSCore__gatewayIn_packed_2_bore !== i_XSCore__gatewayIn_packed_2_bore) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH XSCore.gatewayIn_packed_2_bore g=%h i=%h", cyc, g_XSCore__gatewayIn_packed_2_bore, i_XSCore__gatewayIn_packed_2_bore);
    end
    if (g_XSCore__gatewayIn_packed_2_bore !== p_XSCore__gatewayIn_packed_2_bore) t_XSCore__gatewayIn_packed_2_bore = 1'b1;
    p_XSCore__gatewayIn_packed_2_bore = g_XSCore__gatewayIn_packed_2_bore;
    checks++;
    if (g_XSCore__gatewayIn_packed_3_bore !== i_XSCore__gatewayIn_packed_3_bore) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH XSCore.gatewayIn_packed_3_bore g=%h i=%h", cyc, g_XSCore__gatewayIn_packed_3_bore, i_XSCore__gatewayIn_packed_3_bore);
    end
    if (g_XSCore__gatewayIn_packed_3_bore !== p_XSCore__gatewayIn_packed_3_bore) t_XSCore__gatewayIn_packed_3_bore = 1'b1;
    p_XSCore__gatewayIn_packed_3_bore = g_XSCore__gatewayIn_packed_3_bore;
    checks++;
    if (g_XSCore__gatewayIn_packed_4_bore !== i_XSCore__gatewayIn_packed_4_bore) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH XSCore.gatewayIn_packed_4_bore g=%h i=%h", cyc, g_XSCore__gatewayIn_packed_4_bore, i_XSCore__gatewayIn_packed_4_bore);
    end
    if (g_XSCore__gatewayIn_packed_4_bore !== p_XSCore__gatewayIn_packed_4_bore) t_XSCore__gatewayIn_packed_4_bore = 1'b1;
    p_XSCore__gatewayIn_packed_4_bore = g_XSCore__gatewayIn_packed_4_bore;
    checks++;
    if (g_XSCore__gatewayIn_packed_5_bore !== i_XSCore__gatewayIn_packed_5_bore) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH XSCore.gatewayIn_packed_5_bore g=%h i=%h", cyc, g_XSCore__gatewayIn_packed_5_bore, i_XSCore__gatewayIn_packed_5_bore);
    end
    if (g_XSCore__gatewayIn_packed_5_bore !== p_XSCore__gatewayIn_packed_5_bore) t_XSCore__gatewayIn_packed_5_bore = 1'b1;
    p_XSCore__gatewayIn_packed_5_bore = g_XSCore__gatewayIn_packed_5_bore;
    checks++;
    if (g_XSCore__gatewayIn_packed_6_bore !== i_XSCore__gatewayIn_packed_6_bore) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH XSCore.gatewayIn_packed_6_bore g=%h i=%h", cyc, g_XSCore__gatewayIn_packed_6_bore, i_XSCore__gatewayIn_packed_6_bore);
    end
    if (g_XSCore__gatewayIn_packed_6_bore !== p_XSCore__gatewayIn_packed_6_bore) t_XSCore__gatewayIn_packed_6_bore = 1'b1;
    p_XSCore__gatewayIn_packed_6_bore = g_XSCore__gatewayIn_packed_6_bore;
    checks++;
    if (g_XSCore__gatewayIn_packed_7_bore !== i_XSCore__gatewayIn_packed_7_bore) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH XSCore.gatewayIn_packed_7_bore g=%h i=%h", cyc, g_XSCore__gatewayIn_packed_7_bore, i_XSCore__gatewayIn_packed_7_bore);
    end
    if (g_XSCore__gatewayIn_packed_7_bore !== p_XSCore__gatewayIn_packed_7_bore) t_XSCore__gatewayIn_packed_7_bore = 1'b1;
    p_XSCore__gatewayIn_packed_7_bore = g_XSCore__gatewayIn_packed_7_bore;
    checks++;
    if (g_XSCore__gatewayIn_packed_8_bore !== i_XSCore__gatewayIn_packed_8_bore) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH XSCore.gatewayIn_packed_8_bore g=%h i=%h", cyc, g_XSCore__gatewayIn_packed_8_bore, i_XSCore__gatewayIn_packed_8_bore);
    end
    if (g_XSCore__gatewayIn_packed_8_bore !== p_XSCore__gatewayIn_packed_8_bore) t_XSCore__gatewayIn_packed_8_bore = 1'b1;
    p_XSCore__gatewayIn_packed_8_bore = g_XSCore__gatewayIn_packed_8_bore;
    checks++;
    if (g_XSCore__gatewayIn_packed_9_bore !== i_XSCore__gatewayIn_packed_9_bore) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH XSCore.gatewayIn_packed_9_bore g=%h i=%h", cyc, g_XSCore__gatewayIn_packed_9_bore, i_XSCore__gatewayIn_packed_9_bore);
    end
    if (g_XSCore__gatewayIn_packed_9_bore !== p_XSCore__gatewayIn_packed_9_bore) t_XSCore__gatewayIn_packed_9_bore = 1'b1;
    p_XSCore__gatewayIn_packed_9_bore = g_XSCore__gatewayIn_packed_9_bore;
    checks++;
    if (g_XSCore__gatewayIn_packed_10_bore !== i_XSCore__gatewayIn_packed_10_bore) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH XSCore.gatewayIn_packed_10_bore g=%h i=%h", cyc, g_XSCore__gatewayIn_packed_10_bore, i_XSCore__gatewayIn_packed_10_bore);
    end
    if (g_XSCore__gatewayIn_packed_10_bore !== p_XSCore__gatewayIn_packed_10_bore) t_XSCore__gatewayIn_packed_10_bore = 1'b1;
    p_XSCore__gatewayIn_packed_10_bore = g_XSCore__gatewayIn_packed_10_bore;
    checks++;
    if (g_XSCore__gatewayIn_packed_11_bore !== i_XSCore__gatewayIn_packed_11_bore) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH XSCore.gatewayIn_packed_11_bore g=%h i=%h", cyc, g_XSCore__gatewayIn_packed_11_bore, i_XSCore__gatewayIn_packed_11_bore);
    end
    if (g_XSCore__gatewayIn_packed_11_bore !== p_XSCore__gatewayIn_packed_11_bore) t_XSCore__gatewayIn_packed_11_bore = 1'b1;
    p_XSCore__gatewayIn_packed_11_bore = g_XSCore__gatewayIn_packed_11_bore;
    checks++;
    if (g_XSCore__gatewayIn_packed_12_bore !== i_XSCore__gatewayIn_packed_12_bore) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH XSCore.gatewayIn_packed_12_bore g=%h i=%h", cyc, g_XSCore__gatewayIn_packed_12_bore, i_XSCore__gatewayIn_packed_12_bore);
    end
    if (g_XSCore__gatewayIn_packed_12_bore !== p_XSCore__gatewayIn_packed_12_bore) t_XSCore__gatewayIn_packed_12_bore = 1'b1;
    p_XSCore__gatewayIn_packed_12_bore = g_XSCore__gatewayIn_packed_12_bore;
    checks++;
    if (g_XSCore__gatewayIn_packed_13_bore !== i_XSCore__gatewayIn_packed_13_bore) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH XSCore.gatewayIn_packed_13_bore g=%h i=%h", cyc, g_XSCore__gatewayIn_packed_13_bore, i_XSCore__gatewayIn_packed_13_bore);
    end
    if (g_XSCore__gatewayIn_packed_13_bore !== p_XSCore__gatewayIn_packed_13_bore) t_XSCore__gatewayIn_packed_13_bore = 1'b1;
    p_XSCore__gatewayIn_packed_13_bore = g_XSCore__gatewayIn_packed_13_bore;
    checks++;
    if (g_XSCore__gatewayIn_packed_14_bore !== i_XSCore__gatewayIn_packed_14_bore) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH XSCore.gatewayIn_packed_14_bore g=%h i=%h", cyc, g_XSCore__gatewayIn_packed_14_bore, i_XSCore__gatewayIn_packed_14_bore);
    end
    if (g_XSCore__gatewayIn_packed_14_bore !== p_XSCore__gatewayIn_packed_14_bore) t_XSCore__gatewayIn_packed_14_bore = 1'b1;
    p_XSCore__gatewayIn_packed_14_bore = g_XSCore__gatewayIn_packed_14_bore;
    checks++;
    if (g_XSCore__gatewayIn_packed_15_bore !== i_XSCore__gatewayIn_packed_15_bore) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH XSCore.gatewayIn_packed_15_bore g=%h i=%h", cyc, g_XSCore__gatewayIn_packed_15_bore, i_XSCore__gatewayIn_packed_15_bore);
    end
    if (g_XSCore__gatewayIn_packed_15_bore !== p_XSCore__gatewayIn_packed_15_bore) t_XSCore__gatewayIn_packed_15_bore = 1'b1;
    p_XSCore__gatewayIn_packed_15_bore = g_XSCore__gatewayIn_packed_15_bore;
    checks++;
    if (g_XSCore__gatewayIn_packed_16_bore !== i_XSCore__gatewayIn_packed_16_bore) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH XSCore.gatewayIn_packed_16_bore g=%h i=%h", cyc, g_XSCore__gatewayIn_packed_16_bore, i_XSCore__gatewayIn_packed_16_bore);
    end
    if (g_XSCore__gatewayIn_packed_16_bore !== p_XSCore__gatewayIn_packed_16_bore) t_XSCore__gatewayIn_packed_16_bore = 1'b1;
    p_XSCore__gatewayIn_packed_16_bore = g_XSCore__gatewayIn_packed_16_bore;
    checks++;
    if (g_XSCore__gatewayIn_packed_17_bore !== i_XSCore__gatewayIn_packed_17_bore) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH XSCore.gatewayIn_packed_17_bore g=%h i=%h", cyc, g_XSCore__gatewayIn_packed_17_bore, i_XSCore__gatewayIn_packed_17_bore);
    end
    if (g_XSCore__gatewayIn_packed_17_bore !== p_XSCore__gatewayIn_packed_17_bore) t_XSCore__gatewayIn_packed_17_bore = 1'b1;
    p_XSCore__gatewayIn_packed_17_bore = g_XSCore__gatewayIn_packed_17_bore;
    checks++;
    if (g_XSCore__gatewayIn_packed_18_bore !== i_XSCore__gatewayIn_packed_18_bore) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH XSCore.gatewayIn_packed_18_bore g=%h i=%h", cyc, g_XSCore__gatewayIn_packed_18_bore, i_XSCore__gatewayIn_packed_18_bore);
    end
    if (g_XSCore__gatewayIn_packed_18_bore !== p_XSCore__gatewayIn_packed_18_bore) t_XSCore__gatewayIn_packed_18_bore = 1'b1;
    p_XSCore__gatewayIn_packed_18_bore = g_XSCore__gatewayIn_packed_18_bore;
    checks++;
    if (g_XSCore__gatewayIn_packed_19_bore !== i_XSCore__gatewayIn_packed_19_bore) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH XSCore.gatewayIn_packed_19_bore g=%h i=%h", cyc, g_XSCore__gatewayIn_packed_19_bore, i_XSCore__gatewayIn_packed_19_bore);
    end
    if (g_XSCore__gatewayIn_packed_19_bore !== p_XSCore__gatewayIn_packed_19_bore) t_XSCore__gatewayIn_packed_19_bore = 1'b1;
    p_XSCore__gatewayIn_packed_19_bore = g_XSCore__gatewayIn_packed_19_bore;
    checks++;
    if (g_XSCore__gatewayIn_packed_20_bore !== i_XSCore__gatewayIn_packed_20_bore) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH XSCore.gatewayIn_packed_20_bore g=%h i=%h", cyc, g_XSCore__gatewayIn_packed_20_bore, i_XSCore__gatewayIn_packed_20_bore);
    end
    if (g_XSCore__gatewayIn_packed_20_bore !== p_XSCore__gatewayIn_packed_20_bore) t_XSCore__gatewayIn_packed_20_bore = 1'b1;
    p_XSCore__gatewayIn_packed_20_bore = g_XSCore__gatewayIn_packed_20_bore;
    checks++;
    if (g_XSCore__gatewayIn_packed_21_bore !== i_XSCore__gatewayIn_packed_21_bore) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH XSCore.gatewayIn_packed_21_bore g=%h i=%h", cyc, g_XSCore__gatewayIn_packed_21_bore, i_XSCore__gatewayIn_packed_21_bore);
    end
    if (g_XSCore__gatewayIn_packed_21_bore !== p_XSCore__gatewayIn_packed_21_bore) t_XSCore__gatewayIn_packed_21_bore = 1'b1;
    p_XSCore__gatewayIn_packed_21_bore = g_XSCore__gatewayIn_packed_21_bore;
    checks++;
    if (g_XSCore__gatewayIn_packed_22_bore !== i_XSCore__gatewayIn_packed_22_bore) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH XSCore.gatewayIn_packed_22_bore g=%h i=%h", cyc, g_XSCore__gatewayIn_packed_22_bore, i_XSCore__gatewayIn_packed_22_bore);
    end
    if (g_XSCore__gatewayIn_packed_22_bore !== p_XSCore__gatewayIn_packed_22_bore) t_XSCore__gatewayIn_packed_22_bore = 1'b1;
    p_XSCore__gatewayIn_packed_22_bore = g_XSCore__gatewayIn_packed_22_bore;
    checks++;
    if (g_XSCore__gatewayIn_packed_23_bore !== i_XSCore__gatewayIn_packed_23_bore) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH XSCore.gatewayIn_packed_23_bore g=%h i=%h", cyc, g_XSCore__gatewayIn_packed_23_bore, i_XSCore__gatewayIn_packed_23_bore);
    end
    if (g_XSCore__gatewayIn_packed_23_bore !== p_XSCore__gatewayIn_packed_23_bore) t_XSCore__gatewayIn_packed_23_bore = 1'b1;
    p_XSCore__gatewayIn_packed_23_bore = g_XSCore__gatewayIn_packed_23_bore;
    checks++;
    if (g_XSCore__gatewayIn_packed_24_bore !== i_XSCore__gatewayIn_packed_24_bore) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH XSCore.gatewayIn_packed_24_bore g=%h i=%h", cyc, g_XSCore__gatewayIn_packed_24_bore, i_XSCore__gatewayIn_packed_24_bore);
    end
    if (g_XSCore__gatewayIn_packed_24_bore !== p_XSCore__gatewayIn_packed_24_bore) t_XSCore__gatewayIn_packed_24_bore = 1'b1;
    p_XSCore__gatewayIn_packed_24_bore = g_XSCore__gatewayIn_packed_24_bore;
    checks++;
    if (g_XSCore__gatewayIn_packed_25_bore !== i_XSCore__gatewayIn_packed_25_bore) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH XSCore.gatewayIn_packed_25_bore g=%h i=%h", cyc, g_XSCore__gatewayIn_packed_25_bore, i_XSCore__gatewayIn_packed_25_bore);
    end
    if (g_XSCore__gatewayIn_packed_25_bore !== p_XSCore__gatewayIn_packed_25_bore) t_XSCore__gatewayIn_packed_25_bore = 1'b1;
    p_XSCore__gatewayIn_packed_25_bore = g_XSCore__gatewayIn_packed_25_bore;
    checks++;
    if (g_XSCore__gatewayIn_packed_26_bore !== i_XSCore__gatewayIn_packed_26_bore) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH XSCore.gatewayIn_packed_26_bore g=%h i=%h", cyc, g_XSCore__gatewayIn_packed_26_bore, i_XSCore__gatewayIn_packed_26_bore);
    end
    if (g_XSCore__gatewayIn_packed_26_bore !== p_XSCore__gatewayIn_packed_26_bore) t_XSCore__gatewayIn_packed_26_bore = 1'b1;
    p_XSCore__gatewayIn_packed_26_bore = g_XSCore__gatewayIn_packed_26_bore;
    checks++;
    if (g_XSCore__gatewayIn_packed_27_bore !== i_XSCore__gatewayIn_packed_27_bore) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH XSCore.gatewayIn_packed_27_bore g=%h i=%h", cyc, g_XSCore__gatewayIn_packed_27_bore, i_XSCore__gatewayIn_packed_27_bore);
    end
    if (g_XSCore__gatewayIn_packed_27_bore !== p_XSCore__gatewayIn_packed_27_bore) t_XSCore__gatewayIn_packed_27_bore = 1'b1;
    p_XSCore__gatewayIn_packed_27_bore = g_XSCore__gatewayIn_packed_27_bore;
    checks++;
    if (g_XSCore__gatewayIn_packed_28_bore !== i_XSCore__gatewayIn_packed_28_bore) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH XSCore.gatewayIn_packed_28_bore g=%h i=%h", cyc, g_XSCore__gatewayIn_packed_28_bore, i_XSCore__gatewayIn_packed_28_bore);
    end
    if (g_XSCore__gatewayIn_packed_28_bore !== p_XSCore__gatewayIn_packed_28_bore) t_XSCore__gatewayIn_packed_28_bore = 1'b1;
    p_XSCore__gatewayIn_packed_28_bore = g_XSCore__gatewayIn_packed_28_bore;
    checks++;
    if (g_XSCore__gatewayIn_packed_29_bore !== i_XSCore__gatewayIn_packed_29_bore) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH XSCore.gatewayIn_packed_29_bore g=%h i=%h", cyc, g_XSCore__gatewayIn_packed_29_bore, i_XSCore__gatewayIn_packed_29_bore);
    end
    if (g_XSCore__gatewayIn_packed_29_bore !== p_XSCore__gatewayIn_packed_29_bore) t_XSCore__gatewayIn_packed_29_bore = 1'b1;
    p_XSCore__gatewayIn_packed_29_bore = g_XSCore__gatewayIn_packed_29_bore;
    checks++;
    if (g_XSCore__gatewayIn_packed_30_bore !== i_XSCore__gatewayIn_packed_30_bore) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH XSCore.gatewayIn_packed_30_bore g=%h i=%h", cyc, g_XSCore__gatewayIn_packed_30_bore, i_XSCore__gatewayIn_packed_30_bore);
    end
    if (g_XSCore__gatewayIn_packed_30_bore !== p_XSCore__gatewayIn_packed_30_bore) t_XSCore__gatewayIn_packed_30_bore = 1'b1;
    p_XSCore__gatewayIn_packed_30_bore = g_XSCore__gatewayIn_packed_30_bore;
    checks++;
    if (g_XSCore__gatewayIn_packed_31_bore !== i_XSCore__gatewayIn_packed_31_bore) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH XSCore.gatewayIn_packed_31_bore g=%h i=%h", cyc, g_XSCore__gatewayIn_packed_31_bore, i_XSCore__gatewayIn_packed_31_bore);
    end
    if (g_XSCore__gatewayIn_packed_31_bore !== p_XSCore__gatewayIn_packed_31_bore) t_XSCore__gatewayIn_packed_31_bore = 1'b1;
    p_XSCore__gatewayIn_packed_31_bore = g_XSCore__gatewayIn_packed_31_bore;
    checks++;
    if (g_XSCore__gatewayIn_packed_32_bore !== i_XSCore__gatewayIn_packed_32_bore) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH XSCore.gatewayIn_packed_32_bore g=%h i=%h", cyc, g_XSCore__gatewayIn_packed_32_bore, i_XSCore__gatewayIn_packed_32_bore);
    end
    if (g_XSCore__gatewayIn_packed_32_bore !== p_XSCore__gatewayIn_packed_32_bore) t_XSCore__gatewayIn_packed_32_bore = 1'b1;
    p_XSCore__gatewayIn_packed_32_bore = g_XSCore__gatewayIn_packed_32_bore;
    checks++;
    if (g_XSCore__gatewayIn_packed_33_bore !== i_XSCore__gatewayIn_packed_33_bore) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH XSCore.gatewayIn_packed_33_bore g=%h i=%h", cyc, g_XSCore__gatewayIn_packed_33_bore, i_XSCore__gatewayIn_packed_33_bore);
    end
    if (g_XSCore__gatewayIn_packed_33_bore !== p_XSCore__gatewayIn_packed_33_bore) t_XSCore__gatewayIn_packed_33_bore = 1'b1;
    p_XSCore__gatewayIn_packed_33_bore = g_XSCore__gatewayIn_packed_33_bore;
    checks++;
    if (g_XSCore__gatewayIn_packed_34_bore !== i_XSCore__gatewayIn_packed_34_bore) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH XSCore.gatewayIn_packed_34_bore g=%h i=%h", cyc, g_XSCore__gatewayIn_packed_34_bore, i_XSCore__gatewayIn_packed_34_bore);
    end
    if (g_XSCore__gatewayIn_packed_34_bore !== p_XSCore__gatewayIn_packed_34_bore) t_XSCore__gatewayIn_packed_34_bore = 1'b1;
    p_XSCore__gatewayIn_packed_34_bore = g_XSCore__gatewayIn_packed_34_bore;
    checks++;
    if (g_XSCore__gatewayIn_packed_35_bore !== i_XSCore__gatewayIn_packed_35_bore) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH XSCore.gatewayIn_packed_35_bore g=%h i=%h", cyc, g_XSCore__gatewayIn_packed_35_bore, i_XSCore__gatewayIn_packed_35_bore);
    end
    if (g_XSCore__gatewayIn_packed_35_bore !== p_XSCore__gatewayIn_packed_35_bore) t_XSCore__gatewayIn_packed_35_bore = 1'b1;
    p_XSCore__gatewayIn_packed_35_bore = g_XSCore__gatewayIn_packed_35_bore;
    checks++;
    if (g_XSCore__gatewayIn_packed_36_bore !== i_XSCore__gatewayIn_packed_36_bore) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH XSCore.gatewayIn_packed_36_bore g=%h i=%h", cyc, g_XSCore__gatewayIn_packed_36_bore, i_XSCore__gatewayIn_packed_36_bore);
    end
    if (g_XSCore__gatewayIn_packed_36_bore !== p_XSCore__gatewayIn_packed_36_bore) t_XSCore__gatewayIn_packed_36_bore = 1'b1;
    p_XSCore__gatewayIn_packed_36_bore = g_XSCore__gatewayIn_packed_36_bore;
    checks++;
    if (g_XSCore__gatewayIn_packed_37_bore !== i_XSCore__gatewayIn_packed_37_bore) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH XSCore.gatewayIn_packed_37_bore g=%h i=%h", cyc, g_XSCore__gatewayIn_packed_37_bore, i_XSCore__gatewayIn_packed_37_bore);
    end
    if (g_XSCore__gatewayIn_packed_37_bore !== p_XSCore__gatewayIn_packed_37_bore) t_XSCore__gatewayIn_packed_37_bore = 1'b1;
    p_XSCore__gatewayIn_packed_37_bore = g_XSCore__gatewayIn_packed_37_bore;
    checks++;
    if (g_XSCore__gatewayIn_packed_38_bore !== i_XSCore__gatewayIn_packed_38_bore) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH XSCore.gatewayIn_packed_38_bore g=%h i=%h", cyc, g_XSCore__gatewayIn_packed_38_bore, i_XSCore__gatewayIn_packed_38_bore);
    end
    if (g_XSCore__gatewayIn_packed_38_bore !== p_XSCore__gatewayIn_packed_38_bore) t_XSCore__gatewayIn_packed_38_bore = 1'b1;
    p_XSCore__gatewayIn_packed_38_bore = g_XSCore__gatewayIn_packed_38_bore;
    checks++;
    if (g_XSCore__gatewayIn_packed_39_bore !== i_XSCore__gatewayIn_packed_39_bore) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH XSCore.gatewayIn_packed_39_bore g=%h i=%h", cyc, g_XSCore__gatewayIn_packed_39_bore, i_XSCore__gatewayIn_packed_39_bore);
    end
    if (g_XSCore__gatewayIn_packed_39_bore !== p_XSCore__gatewayIn_packed_39_bore) t_XSCore__gatewayIn_packed_39_bore = 1'b1;
    p_XSCore__gatewayIn_packed_39_bore = g_XSCore__gatewayIn_packed_39_bore;
    checks++;
    if (g_XSCore__gatewayIn_packed_40_bore !== i_XSCore__gatewayIn_packed_40_bore) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH XSCore.gatewayIn_packed_40_bore g=%h i=%h", cyc, g_XSCore__gatewayIn_packed_40_bore, i_XSCore__gatewayIn_packed_40_bore);
    end
    if (g_XSCore__gatewayIn_packed_40_bore !== p_XSCore__gatewayIn_packed_40_bore) t_XSCore__gatewayIn_packed_40_bore = 1'b1;
    p_XSCore__gatewayIn_packed_40_bore = g_XSCore__gatewayIn_packed_40_bore;
    checks++;
    if (g_XSCore__gatewayIn_packed_41_bore !== i_XSCore__gatewayIn_packed_41_bore) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH XSCore.gatewayIn_packed_41_bore g=%h i=%h", cyc, g_XSCore__gatewayIn_packed_41_bore, i_XSCore__gatewayIn_packed_41_bore);
    end
    if (g_XSCore__gatewayIn_packed_41_bore !== p_XSCore__gatewayIn_packed_41_bore) t_XSCore__gatewayIn_packed_41_bore = 1'b1;
    p_XSCore__gatewayIn_packed_41_bore = g_XSCore__gatewayIn_packed_41_bore;
    checks++;
    if (g_XSCore__gatewayIn_packed_42_bore !== i_XSCore__gatewayIn_packed_42_bore) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH XSCore.gatewayIn_packed_42_bore g=%h i=%h", cyc, g_XSCore__gatewayIn_packed_42_bore, i_XSCore__gatewayIn_packed_42_bore);
    end
    if (g_XSCore__gatewayIn_packed_42_bore !== p_XSCore__gatewayIn_packed_42_bore) t_XSCore__gatewayIn_packed_42_bore = 1'b1;
    p_XSCore__gatewayIn_packed_42_bore = g_XSCore__gatewayIn_packed_42_bore;
    checks++;
    if (g_XSCore__gatewayIn_packed_43_bore !== i_XSCore__gatewayIn_packed_43_bore) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH XSCore.gatewayIn_packed_43_bore g=%h i=%h", cyc, g_XSCore__gatewayIn_packed_43_bore, i_XSCore__gatewayIn_packed_43_bore);
    end
    if (g_XSCore__gatewayIn_packed_43_bore !== p_XSCore__gatewayIn_packed_43_bore) t_XSCore__gatewayIn_packed_43_bore = 1'b1;
    p_XSCore__gatewayIn_packed_43_bore = g_XSCore__gatewayIn_packed_43_bore;
    checks++;
    if (g_XSCore__gatewayIn_packed_44_bore !== i_XSCore__gatewayIn_packed_44_bore) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH XSCore.gatewayIn_packed_44_bore g=%h i=%h", cyc, g_XSCore__gatewayIn_packed_44_bore, i_XSCore__gatewayIn_packed_44_bore);
    end
    if (g_XSCore__gatewayIn_packed_44_bore !== p_XSCore__gatewayIn_packed_44_bore) t_XSCore__gatewayIn_packed_44_bore = 1'b1;
    p_XSCore__gatewayIn_packed_44_bore = g_XSCore__gatewayIn_packed_44_bore;
    checks++;
    if (g_XSCore__gatewayIn_packed_45_bore !== i_XSCore__gatewayIn_packed_45_bore) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH XSCore.gatewayIn_packed_45_bore g=%h i=%h", cyc, g_XSCore__gatewayIn_packed_45_bore, i_XSCore__gatewayIn_packed_45_bore);
    end
    if (g_XSCore__gatewayIn_packed_45_bore !== p_XSCore__gatewayIn_packed_45_bore) t_XSCore__gatewayIn_packed_45_bore = 1'b1;
    p_XSCore__gatewayIn_packed_45_bore = g_XSCore__gatewayIn_packed_45_bore;
    checks++;
    if (g_XSCore__gatewayIn_packed_46_bore !== i_XSCore__gatewayIn_packed_46_bore) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH XSCore.gatewayIn_packed_46_bore g=%h i=%h", cyc, g_XSCore__gatewayIn_packed_46_bore, i_XSCore__gatewayIn_packed_46_bore);
    end
    if (g_XSCore__gatewayIn_packed_46_bore !== p_XSCore__gatewayIn_packed_46_bore) t_XSCore__gatewayIn_packed_46_bore = 1'b1;
    p_XSCore__gatewayIn_packed_46_bore = g_XSCore__gatewayIn_packed_46_bore;
    checks++;
    if (g_XSCore__gatewayIn_packed_47_bore !== i_XSCore__gatewayIn_packed_47_bore) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH XSCore.gatewayIn_packed_47_bore g=%h i=%h", cyc, g_XSCore__gatewayIn_packed_47_bore, i_XSCore__gatewayIn_packed_47_bore);
    end
    if (g_XSCore__gatewayIn_packed_47_bore !== p_XSCore__gatewayIn_packed_47_bore) t_XSCore__gatewayIn_packed_47_bore = 1'b1;
    p_XSCore__gatewayIn_packed_47_bore = g_XSCore__gatewayIn_packed_47_bore;
    checks++;
    if (g_XSCore__gatewayIn_packed_48_bore !== i_XSCore__gatewayIn_packed_48_bore) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH XSCore.gatewayIn_packed_48_bore g=%h i=%h", cyc, g_XSCore__gatewayIn_packed_48_bore, i_XSCore__gatewayIn_packed_48_bore);
    end
    if (g_XSCore__gatewayIn_packed_48_bore !== p_XSCore__gatewayIn_packed_48_bore) t_XSCore__gatewayIn_packed_48_bore = 1'b1;
    p_XSCore__gatewayIn_packed_48_bore = g_XSCore__gatewayIn_packed_48_bore;
    checks++;
    if (g_XSCore__gatewayIn_packed_49_bore !== i_XSCore__gatewayIn_packed_49_bore) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH XSCore.gatewayIn_packed_49_bore g=%h i=%h", cyc, g_XSCore__gatewayIn_packed_49_bore, i_XSCore__gatewayIn_packed_49_bore);
    end
    if (g_XSCore__gatewayIn_packed_49_bore !== p_XSCore__gatewayIn_packed_49_bore) t_XSCore__gatewayIn_packed_49_bore = 1'b1;
    p_XSCore__gatewayIn_packed_49_bore = g_XSCore__gatewayIn_packed_49_bore;
    checks++;
    if (g_XSCore__gatewayIn_packed_50_bore !== i_XSCore__gatewayIn_packed_50_bore) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH XSCore.gatewayIn_packed_50_bore g=%h i=%h", cyc, g_XSCore__gatewayIn_packed_50_bore, i_XSCore__gatewayIn_packed_50_bore);
    end
    if (g_XSCore__gatewayIn_packed_50_bore !== p_XSCore__gatewayIn_packed_50_bore) t_XSCore__gatewayIn_packed_50_bore = 1'b1;
    p_XSCore__gatewayIn_packed_50_bore = g_XSCore__gatewayIn_packed_50_bore;
    checks++;
    if (g_XSCore__gatewayIn_packed_51_bore !== i_XSCore__gatewayIn_packed_51_bore) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH XSCore.gatewayIn_packed_51_bore g=%h i=%h", cyc, g_XSCore__gatewayIn_packed_51_bore, i_XSCore__gatewayIn_packed_51_bore);
    end
    if (g_XSCore__gatewayIn_packed_51_bore !== p_XSCore__gatewayIn_packed_51_bore) t_XSCore__gatewayIn_packed_51_bore = 1'b1;
    p_XSCore__gatewayIn_packed_51_bore = g_XSCore__gatewayIn_packed_51_bore;
    checks++;
    if (g_XSCore__gatewayIn_packed_52_bore !== i_XSCore__gatewayIn_packed_52_bore) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH XSCore.gatewayIn_packed_52_bore g=%h i=%h", cyc, g_XSCore__gatewayIn_packed_52_bore, i_XSCore__gatewayIn_packed_52_bore);
    end
    if (g_XSCore__gatewayIn_packed_52_bore !== p_XSCore__gatewayIn_packed_52_bore) t_XSCore__gatewayIn_packed_52_bore = 1'b1;
    p_XSCore__gatewayIn_packed_52_bore = g_XSCore__gatewayIn_packed_52_bore;
    checks++;
    if (g_XSCore__gatewayIn_packed_53_bore !== i_XSCore__gatewayIn_packed_53_bore) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH XSCore.gatewayIn_packed_53_bore g=%h i=%h", cyc, g_XSCore__gatewayIn_packed_53_bore, i_XSCore__gatewayIn_packed_53_bore);
    end
    if (g_XSCore__gatewayIn_packed_53_bore !== p_XSCore__gatewayIn_packed_53_bore) t_XSCore__gatewayIn_packed_53_bore = 1'b1;
    p_XSCore__gatewayIn_packed_53_bore = g_XSCore__gatewayIn_packed_53_bore;
    checks++;
    if (g_XSCore__gatewayIn_packed_54_bore !== i_XSCore__gatewayIn_packed_54_bore) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH XSCore.gatewayIn_packed_54_bore g=%h i=%h", cyc, g_XSCore__gatewayIn_packed_54_bore, i_XSCore__gatewayIn_packed_54_bore);
    end
    if (g_XSCore__gatewayIn_packed_54_bore !== p_XSCore__gatewayIn_packed_54_bore) t_XSCore__gatewayIn_packed_54_bore = 1'b1;
    p_XSCore__gatewayIn_packed_54_bore = g_XSCore__gatewayIn_packed_54_bore;
    checks++;
    if (g_XSCore__gatewayIn_packed_55_bore !== i_XSCore__gatewayIn_packed_55_bore) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH XSCore.gatewayIn_packed_55_bore g=%h i=%h", cyc, g_XSCore__gatewayIn_packed_55_bore, i_XSCore__gatewayIn_packed_55_bore);
    end
    if (g_XSCore__gatewayIn_packed_55_bore !== p_XSCore__gatewayIn_packed_55_bore) t_XSCore__gatewayIn_packed_55_bore = 1'b1;
    p_XSCore__gatewayIn_packed_55_bore = g_XSCore__gatewayIn_packed_55_bore;
    checks++;
    if (g_XSCore__gatewayIn_packed_56_bore !== i_XSCore__gatewayIn_packed_56_bore) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH XSCore.gatewayIn_packed_56_bore g=%h i=%h", cyc, g_XSCore__gatewayIn_packed_56_bore, i_XSCore__gatewayIn_packed_56_bore);
    end
    if (g_XSCore__gatewayIn_packed_56_bore !== p_XSCore__gatewayIn_packed_56_bore) t_XSCore__gatewayIn_packed_56_bore = 1'b1;
    p_XSCore__gatewayIn_packed_56_bore = g_XSCore__gatewayIn_packed_56_bore;
    checks++;
    if (g_XSCore__gatewayIn_packed_57_bore !== i_XSCore__gatewayIn_packed_57_bore) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH XSCore.gatewayIn_packed_57_bore g=%h i=%h", cyc, g_XSCore__gatewayIn_packed_57_bore, i_XSCore__gatewayIn_packed_57_bore);
    end
    if (g_XSCore__gatewayIn_packed_57_bore !== p_XSCore__gatewayIn_packed_57_bore) t_XSCore__gatewayIn_packed_57_bore = 1'b1;
    p_XSCore__gatewayIn_packed_57_bore = g_XSCore__gatewayIn_packed_57_bore;
    checks++;
    if (g_XSCore__gatewayIn_packed_58_bore !== i_XSCore__gatewayIn_packed_58_bore) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH XSCore.gatewayIn_packed_58_bore g=%h i=%h", cyc, g_XSCore__gatewayIn_packed_58_bore, i_XSCore__gatewayIn_packed_58_bore);
    end
    if (g_XSCore__gatewayIn_packed_58_bore !== p_XSCore__gatewayIn_packed_58_bore) t_XSCore__gatewayIn_packed_58_bore = 1'b1;
    p_XSCore__gatewayIn_packed_58_bore = g_XSCore__gatewayIn_packed_58_bore;
    checks++;
    if (g_XSCore__gatewayIn_packed_59_bore !== i_XSCore__gatewayIn_packed_59_bore) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH XSCore.gatewayIn_packed_59_bore g=%h i=%h", cyc, g_XSCore__gatewayIn_packed_59_bore, i_XSCore__gatewayIn_packed_59_bore);
    end
    if (g_XSCore__gatewayIn_packed_59_bore !== p_XSCore__gatewayIn_packed_59_bore) t_XSCore__gatewayIn_packed_59_bore = 1'b1;
    p_XSCore__gatewayIn_packed_59_bore = g_XSCore__gatewayIn_packed_59_bore;
    checks++;
    if (g_XSCore__gatewayIn_packed_60_bore !== i_XSCore__gatewayIn_packed_60_bore) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH XSCore.gatewayIn_packed_60_bore g=%h i=%h", cyc, g_XSCore__gatewayIn_packed_60_bore, i_XSCore__gatewayIn_packed_60_bore);
    end
    if (g_XSCore__gatewayIn_packed_60_bore !== p_XSCore__gatewayIn_packed_60_bore) t_XSCore__gatewayIn_packed_60_bore = 1'b1;
    p_XSCore__gatewayIn_packed_60_bore = g_XSCore__gatewayIn_packed_60_bore;
  endtask
  longint cov_XSCore_icache_req = 0;
  longint cov_XSCore_icache_resp = 0;
  longint cov_XSCore_cfvec = 0;
  longint cov_XSCore_redirect = 0;
  longint cov_XSCore_lsq_enq = 0;
  task automatic cover_XSCore();
    if (u_g_XSCore._frontend_auto_inner_icache_client_out_a_valid) cov_XSCore_icache_req++;
    if (u_g_XSCore._memBlock_auto_inner_frontendBridge_icache_in_d_valid) cov_XSCore_icache_resp++;
    if (u_g_XSCore._frontend_io_backend_cfVec_0_valid) cov_XSCore_cfvec++;
    if (u_g_XSCore._backend_io_frontend_toFtq_redirect_valid) cov_XSCore_redirect++;
    if (u_g_XSCore._backend_io_mem_lsqEnqIO_req_0_valid) cov_XSCore_lsq_enq++;
  endtask
  task automatic preinit_XSCore();
  endtask
  task automatic sync_XSCore();
  endtask

  bit covfail = 0;
  initial begin
    void'($value$plusargs("ncycles=%d", NCYCLES));
    reset = 1'b1;
    drive_XSCore();
    #1;
    preinit_XSCore();
    sync_XSCore();
    repeat (5) @(posedge clock);
    @(negedge clock) reset = 1'b0;
    for (cyc = 0; cyc < NCYCLES; cyc++) begin
      @(negedge clock);
      if (reset) reset = 1'b0; else if (($urandom % 20000) == 0) reset = 1'b1;
      drive_XSCore();
      #1;
      check_XSCore();
      cover_XSCore();
    end
    begin int tg; tg = 0;
      if (t_XSCore__auto_memBlock_inner_buffers_out_a_valid) tg++; else $display("COV: XSCore.auto_memBlock_inner_buffers_out_a_valid never toggled");
      if (t_XSCore__auto_memBlock_inner_buffers_out_a_bits_opcode) tg++; else $display("COV: XSCore.auto_memBlock_inner_buffers_out_a_bits_opcode never toggled");
      if (t_XSCore__auto_memBlock_inner_buffers_out_a_bits_param) tg++; else $display("COV: XSCore.auto_memBlock_inner_buffers_out_a_bits_param never toggled");
      if (t_XSCore__auto_memBlock_inner_buffers_out_a_bits_size) tg++; else $display("COV: XSCore.auto_memBlock_inner_buffers_out_a_bits_size never toggled");
      if (t_XSCore__auto_memBlock_inner_buffers_out_a_bits_source) tg++; else $display("COV: XSCore.auto_memBlock_inner_buffers_out_a_bits_source never toggled");
      if (t_XSCore__auto_memBlock_inner_buffers_out_a_bits_address) tg++; else $display("COV: XSCore.auto_memBlock_inner_buffers_out_a_bits_address never toggled");
      if (t_XSCore__auto_memBlock_inner_buffers_out_a_bits_user_memBackType_MM) tg++; else $display("COV: XSCore.auto_memBlock_inner_buffers_out_a_bits_user_memBackType_MM never toggled");
      if (t_XSCore__auto_memBlock_inner_buffers_out_a_bits_user_memPageType_NC) tg++; else $display("COV: XSCore.auto_memBlock_inner_buffers_out_a_bits_user_memPageType_NC never toggled");
      if (t_XSCore__auto_memBlock_inner_buffers_out_a_bits_mask) tg++; else $display("COV: XSCore.auto_memBlock_inner_buffers_out_a_bits_mask never toggled");
      if (t_XSCore__auto_memBlock_inner_buffers_out_a_bits_data) tg++; else $display("COV: XSCore.auto_memBlock_inner_buffers_out_a_bits_data never toggled");
      if (t_XSCore__auto_memBlock_inner_buffers_out_a_bits_corrupt) tg++; else $display("COV: XSCore.auto_memBlock_inner_buffers_out_a_bits_corrupt never toggled");
      if (t_XSCore__auto_memBlock_inner_buffers_out_d_ready) tg++; else $display("COV: XSCore.auto_memBlock_inner_buffers_out_d_ready never toggled");
      if (t_XSCore__auto_memBlock_inner_frontendBridge_instr_uncache_out_a_valid) tg++; else $display("COV: XSCore.auto_memBlock_inner_frontendBridge_instr_uncache_out_a_valid never toggled");
      if (t_XSCore__auto_memBlock_inner_frontendBridge_instr_uncache_out_a_bits_param) tg++; else $display("COV: XSCore.auto_memBlock_inner_frontendBridge_instr_uncache_out_a_bits_param never toggled");
      if (t_XSCore__auto_memBlock_inner_frontendBridge_instr_uncache_out_a_bits_address) tg++; else $display("COV: XSCore.auto_memBlock_inner_frontendBridge_instr_uncache_out_a_bits_address never toggled");
      if (t_XSCore__auto_memBlock_inner_frontendBridge_instr_uncache_out_a_bits_user_memPageType_NC) tg++; else $display("COV: XSCore.auto_memBlock_inner_frontendBridge_instr_uncache_out_a_bits_user_memPageType_NC never toggled");
      if (t_XSCore__auto_memBlock_inner_frontendBridge_instr_uncache_out_a_bits_user_memBackType_MM) tg++; else $display("COV: XSCore.auto_memBlock_inner_frontendBridge_instr_uncache_out_a_bits_user_memBackType_MM never toggled");
      if (t_XSCore__auto_memBlock_inner_frontendBridge_instr_uncache_out_a_bits_corrupt) tg++; else $display("COV: XSCore.auto_memBlock_inner_frontendBridge_instr_uncache_out_a_bits_corrupt never toggled");
      if (t_XSCore__auto_memBlock_inner_frontendBridge_instr_uncache_out_d_ready) tg++; else $display("COV: XSCore.auto_memBlock_inner_frontendBridge_instr_uncache_out_d_ready never toggled");
      if (t_XSCore__auto_memBlock_inner_frontendBridge_icachectrl_in_a_ready) tg++; else $display("COV: XSCore.auto_memBlock_inner_frontendBridge_icachectrl_in_a_ready never toggled");
      if (t_XSCore__auto_memBlock_inner_frontendBridge_icachectrl_in_d_valid) tg++; else $display("COV: XSCore.auto_memBlock_inner_frontendBridge_icachectrl_in_d_valid never toggled");
      if (t_XSCore__auto_memBlock_inner_frontendBridge_icachectrl_in_d_bits_opcode) tg++; else $display("COV: XSCore.auto_memBlock_inner_frontendBridge_icachectrl_in_d_bits_opcode never toggled");
      if (t_XSCore__auto_memBlock_inner_frontendBridge_icachectrl_in_d_bits_param) tg++; else $display("COV: XSCore.auto_memBlock_inner_frontendBridge_icachectrl_in_d_bits_param never toggled");
      if (t_XSCore__auto_memBlock_inner_frontendBridge_icachectrl_in_d_bits_size) tg++; else $display("COV: XSCore.auto_memBlock_inner_frontendBridge_icachectrl_in_d_bits_size never toggled");
      if (t_XSCore__auto_memBlock_inner_frontendBridge_icachectrl_in_d_bits_source) tg++; else $display("COV: XSCore.auto_memBlock_inner_frontendBridge_icachectrl_in_d_bits_source never toggled");
      if (t_XSCore__auto_memBlock_inner_frontendBridge_icachectrl_in_d_bits_sink) tg++; else $display("COV: XSCore.auto_memBlock_inner_frontendBridge_icachectrl_in_d_bits_sink never toggled");
      if (t_XSCore__auto_memBlock_inner_frontendBridge_icachectrl_in_d_bits_denied) tg++; else $display("COV: XSCore.auto_memBlock_inner_frontendBridge_icachectrl_in_d_bits_denied never toggled");
      if (t_XSCore__auto_memBlock_inner_frontendBridge_icachectrl_in_d_bits_data) tg++; else $display("COV: XSCore.auto_memBlock_inner_frontendBridge_icachectrl_in_d_bits_data never toggled");
      if (t_XSCore__auto_memBlock_inner_frontendBridge_icachectrl_in_d_bits_corrupt) tg++; else $display("COV: XSCore.auto_memBlock_inner_frontendBridge_icachectrl_in_d_bits_corrupt never toggled");
      if (t_XSCore__auto_memBlock_inner_frontendBridge_icache_out_a_valid) tg++; else $display("COV: XSCore.auto_memBlock_inner_frontendBridge_icache_out_a_valid never toggled");
      if (t_XSCore__auto_memBlock_inner_frontendBridge_icache_out_a_bits_opcode) tg++; else $display("COV: XSCore.auto_memBlock_inner_frontendBridge_icache_out_a_bits_opcode never toggled");
      if (t_XSCore__auto_memBlock_inner_frontendBridge_icache_out_a_bits_param) tg++; else $display("COV: XSCore.auto_memBlock_inner_frontendBridge_icache_out_a_bits_param never toggled");
      if (t_XSCore__auto_memBlock_inner_frontendBridge_icache_out_a_bits_size) tg++; else $display("COV: XSCore.auto_memBlock_inner_frontendBridge_icache_out_a_bits_size never toggled");
      if (t_XSCore__auto_memBlock_inner_frontendBridge_icache_out_a_bits_source) tg++; else $display("COV: XSCore.auto_memBlock_inner_frontendBridge_icache_out_a_bits_source never toggled");
      if (t_XSCore__auto_memBlock_inner_frontendBridge_icache_out_a_bits_address) tg++; else $display("COV: XSCore.auto_memBlock_inner_frontendBridge_icache_out_a_bits_address never toggled");
      if (t_XSCore__auto_memBlock_inner_frontendBridge_icache_out_a_bits_user_alias) tg++; else $display("COV: XSCore.auto_memBlock_inner_frontendBridge_icache_out_a_bits_user_alias never toggled");
      if (t_XSCore__auto_memBlock_inner_frontendBridge_icache_out_a_bits_user_reqSource) tg++; else $display("COV: XSCore.auto_memBlock_inner_frontendBridge_icache_out_a_bits_user_reqSource never toggled");
      if (t_XSCore__auto_memBlock_inner_frontendBridge_icache_out_a_bits_user_needHint) tg++; else $display("COV: XSCore.auto_memBlock_inner_frontendBridge_icache_out_a_bits_user_needHint never toggled");
      if (t_XSCore__auto_memBlock_inner_frontendBridge_icache_out_a_bits_mask) tg++; else $display("COV: XSCore.auto_memBlock_inner_frontendBridge_icache_out_a_bits_mask never toggled");
      if (t_XSCore__auto_memBlock_inner_frontendBridge_icache_out_a_bits_data) tg++; else $display("COV: XSCore.auto_memBlock_inner_frontendBridge_icache_out_a_bits_data never toggled");
      if (t_XSCore__auto_memBlock_inner_frontendBridge_icache_out_a_bits_corrupt) tg++; else $display("COV: XSCore.auto_memBlock_inner_frontendBridge_icache_out_a_bits_corrupt never toggled");
      if (t_XSCore__auto_memBlock_inner_frontendBridge_icache_out_d_ready) tg++; else $display("COV: XSCore.auto_memBlock_inner_frontendBridge_icache_out_d_ready never toggled");
      if (t_XSCore__auto_memBlock_inner_ptw_to_l2_buffer_out_a_valid) tg++; else $display("COV: XSCore.auto_memBlock_inner_ptw_to_l2_buffer_out_a_valid never toggled");
      if (t_XSCore__auto_memBlock_inner_ptw_to_l2_buffer_out_a_bits_opcode) tg++; else $display("COV: XSCore.auto_memBlock_inner_ptw_to_l2_buffer_out_a_bits_opcode never toggled");
      if (t_XSCore__auto_memBlock_inner_ptw_to_l2_buffer_out_a_bits_param) tg++; else $display("COV: XSCore.auto_memBlock_inner_ptw_to_l2_buffer_out_a_bits_param never toggled");
      if (t_XSCore__auto_memBlock_inner_ptw_to_l2_buffer_out_a_bits_size) tg++; else $display("COV: XSCore.auto_memBlock_inner_ptw_to_l2_buffer_out_a_bits_size never toggled");
      if (t_XSCore__auto_memBlock_inner_ptw_to_l2_buffer_out_a_bits_source) tg++; else $display("COV: XSCore.auto_memBlock_inner_ptw_to_l2_buffer_out_a_bits_source never toggled");
      if (t_XSCore__auto_memBlock_inner_ptw_to_l2_buffer_out_a_bits_address) tg++; else $display("COV: XSCore.auto_memBlock_inner_ptw_to_l2_buffer_out_a_bits_address never toggled");
      if (t_XSCore__auto_memBlock_inner_ptw_to_l2_buffer_out_a_bits_user_reqSource) tg++; else $display("COV: XSCore.auto_memBlock_inner_ptw_to_l2_buffer_out_a_bits_user_reqSource never toggled");
      if (t_XSCore__auto_memBlock_inner_ptw_to_l2_buffer_out_a_bits_mask) tg++; else $display("COV: XSCore.auto_memBlock_inner_ptw_to_l2_buffer_out_a_bits_mask never toggled");
      if (t_XSCore__auto_memBlock_inner_ptw_to_l2_buffer_out_a_bits_data) tg++; else $display("COV: XSCore.auto_memBlock_inner_ptw_to_l2_buffer_out_a_bits_data never toggled");
      if (t_XSCore__auto_memBlock_inner_ptw_to_l2_buffer_out_a_bits_corrupt) tg++; else $display("COV: XSCore.auto_memBlock_inner_ptw_to_l2_buffer_out_a_bits_corrupt never toggled");
      if (t_XSCore__auto_memBlock_inner_ptw_to_l2_buffer_out_d_ready) tg++; else $display("COV: XSCore.auto_memBlock_inner_ptw_to_l2_buffer_out_d_ready never toggled");
      if (t_XSCore__auto_memBlock_inner_l2_pf_sender_out_addr) tg++; else $display("COV: XSCore.auto_memBlock_inner_l2_pf_sender_out_addr never toggled");
      if (t_XSCore__auto_memBlock_inner_l2_pf_sender_out_pf_source) tg++; else $display("COV: XSCore.auto_memBlock_inner_l2_pf_sender_out_pf_source never toggled");
      if (t_XSCore__auto_memBlock_inner_l2_pf_sender_out_addr_valid) tg++; else $display("COV: XSCore.auto_memBlock_inner_l2_pf_sender_out_addr_valid never toggled");
      if (t_XSCore__auto_memBlock_inner_dcache_client_out_a_valid) tg++; else $display("COV: XSCore.auto_memBlock_inner_dcache_client_out_a_valid never toggled");
      if (t_XSCore__auto_memBlock_inner_dcache_client_out_a_bits_opcode) tg++; else $display("COV: XSCore.auto_memBlock_inner_dcache_client_out_a_bits_opcode never toggled");
      if (t_XSCore__auto_memBlock_inner_dcache_client_out_a_bits_param) tg++; else $display("COV: XSCore.auto_memBlock_inner_dcache_client_out_a_bits_param never toggled");
      if (t_XSCore__auto_memBlock_inner_dcache_client_out_a_bits_size) tg++; else $display("COV: XSCore.auto_memBlock_inner_dcache_client_out_a_bits_size never toggled");
      if (t_XSCore__auto_memBlock_inner_dcache_client_out_a_bits_source) tg++; else $display("COV: XSCore.auto_memBlock_inner_dcache_client_out_a_bits_source never toggled");
      if (t_XSCore__auto_memBlock_inner_dcache_client_out_a_bits_address) tg++; else $display("COV: XSCore.auto_memBlock_inner_dcache_client_out_a_bits_address never toggled");
      if (t_XSCore__auto_memBlock_inner_dcache_client_out_a_bits_user_alias) tg++; else $display("COV: XSCore.auto_memBlock_inner_dcache_client_out_a_bits_user_alias never toggled");
      if (t_XSCore__auto_memBlock_inner_dcache_client_out_a_bits_user_vaddr) tg++; else $display("COV: XSCore.auto_memBlock_inner_dcache_client_out_a_bits_user_vaddr never toggled");
      if (t_XSCore__auto_memBlock_inner_dcache_client_out_a_bits_user_reqSource) tg++; else $display("COV: XSCore.auto_memBlock_inner_dcache_client_out_a_bits_user_reqSource never toggled");
      if (t_XSCore__auto_memBlock_inner_dcache_client_out_a_bits_user_needHint) tg++; else $display("COV: XSCore.auto_memBlock_inner_dcache_client_out_a_bits_user_needHint never toggled");
      if (t_XSCore__auto_memBlock_inner_dcache_client_out_a_bits_echo_isKeyword) tg++; else $display("COV: XSCore.auto_memBlock_inner_dcache_client_out_a_bits_echo_isKeyword never toggled");
      if (t_XSCore__auto_memBlock_inner_dcache_client_out_a_bits_mask) tg++; else $display("COV: XSCore.auto_memBlock_inner_dcache_client_out_a_bits_mask never toggled");
      if (t_XSCore__auto_memBlock_inner_dcache_client_out_a_bits_data) tg++; else $display("COV: XSCore.auto_memBlock_inner_dcache_client_out_a_bits_data never toggled");
      if (t_XSCore__auto_memBlock_inner_dcache_client_out_a_bits_corrupt) tg++; else $display("COV: XSCore.auto_memBlock_inner_dcache_client_out_a_bits_corrupt never toggled");
      if (t_XSCore__auto_memBlock_inner_dcache_client_out_b_ready) tg++; else $display("COV: XSCore.auto_memBlock_inner_dcache_client_out_b_ready never toggled");
      if (t_XSCore__auto_memBlock_inner_dcache_client_out_c_valid) tg++; else $display("COV: XSCore.auto_memBlock_inner_dcache_client_out_c_valid never toggled");
      if (t_XSCore__auto_memBlock_inner_dcache_client_out_c_bits_opcode) tg++; else $display("COV: XSCore.auto_memBlock_inner_dcache_client_out_c_bits_opcode never toggled");
      if (t_XSCore__auto_memBlock_inner_dcache_client_out_c_bits_param) tg++; else $display("COV: XSCore.auto_memBlock_inner_dcache_client_out_c_bits_param never toggled");
      if (t_XSCore__auto_memBlock_inner_dcache_client_out_c_bits_size) tg++; else $display("COV: XSCore.auto_memBlock_inner_dcache_client_out_c_bits_size never toggled");
      if (t_XSCore__auto_memBlock_inner_dcache_client_out_c_bits_source) tg++; else $display("COV: XSCore.auto_memBlock_inner_dcache_client_out_c_bits_source never toggled");
      if (t_XSCore__auto_memBlock_inner_dcache_client_out_c_bits_address) tg++; else $display("COV: XSCore.auto_memBlock_inner_dcache_client_out_c_bits_address never toggled");
      if (t_XSCore__auto_memBlock_inner_dcache_client_out_c_bits_user_alias) tg++; else $display("COV: XSCore.auto_memBlock_inner_dcache_client_out_c_bits_user_alias never toggled");
      if (t_XSCore__auto_memBlock_inner_dcache_client_out_c_bits_user_vaddr) tg++; else $display("COV: XSCore.auto_memBlock_inner_dcache_client_out_c_bits_user_vaddr never toggled");
      if (t_XSCore__auto_memBlock_inner_dcache_client_out_c_bits_user_reqSource) tg++; else $display("COV: XSCore.auto_memBlock_inner_dcache_client_out_c_bits_user_reqSource never toggled");
      if (t_XSCore__auto_memBlock_inner_dcache_client_out_c_bits_user_needHint) tg++; else $display("COV: XSCore.auto_memBlock_inner_dcache_client_out_c_bits_user_needHint never toggled");
      if (t_XSCore__auto_memBlock_inner_dcache_client_out_c_bits_echo_isKeyword) tg++; else $display("COV: XSCore.auto_memBlock_inner_dcache_client_out_c_bits_echo_isKeyword never toggled");
      if (t_XSCore__auto_memBlock_inner_dcache_client_out_c_bits_data) tg++; else $display("COV: XSCore.auto_memBlock_inner_dcache_client_out_c_bits_data never toggled");
      if (t_XSCore__auto_memBlock_inner_dcache_client_out_c_bits_corrupt) tg++; else $display("COV: XSCore.auto_memBlock_inner_dcache_client_out_c_bits_corrupt never toggled");
      if (t_XSCore__auto_memBlock_inner_dcache_client_out_d_ready) tg++; else $display("COV: XSCore.auto_memBlock_inner_dcache_client_out_d_ready never toggled");
      if (t_XSCore__auto_memBlock_inner_dcache_client_out_e_valid) tg++; else $display("COV: XSCore.auto_memBlock_inner_dcache_client_out_e_valid never toggled");
      if (t_XSCore__auto_memBlock_inner_dcache_client_out_e_bits_sink) tg++; else $display("COV: XSCore.auto_memBlock_inner_dcache_client_out_e_bits_sink never toggled");
      if (t_XSCore__io_msiAck) tg++; else $display("COV: XSCore.io_msiAck never toggled");
      if (t_XSCore__io_cpu_halt) tg++; else $display("COV: XSCore.io_cpu_halt never toggled");
      if (t_XSCore__io_l2_flush_en) tg++; else $display("COV: XSCore.io_l2_flush_en never toggled");
      if (t_XSCore__io_power_down_en) tg++; else $display("COV: XSCore.io_power_down_en never toggled");
      if (t_XSCore__io_cpu_critical_error) tg++; else $display("COV: XSCore.io_cpu_critical_error never toggled");
      if (t_XSCore__io_resetInFrontend) tg++; else $display("COV: XSCore.io_resetInFrontend never toggled");
      if (t_XSCore__io_traceCoreInterface_toEncoder_priv) tg++; else $display("COV: XSCore.io_traceCoreInterface_toEncoder_priv never toggled");
      if (t_XSCore__io_traceCoreInterface_toEncoder_mstatus) tg++; else $display("COV: XSCore.io_traceCoreInterface_toEncoder_mstatus never toggled");
      if (t_XSCore__io_traceCoreInterface_toEncoder_trap_cause) tg++; else $display("COV: XSCore.io_traceCoreInterface_toEncoder_trap_cause never toggled");
      if (t_XSCore__io_traceCoreInterface_toEncoder_trap_tval) tg++; else $display("COV: XSCore.io_traceCoreInterface_toEncoder_trap_tval never toggled");
      if (t_XSCore__io_traceCoreInterface_toEncoder_groups_0_valid) tg++; else $display("COV: XSCore.io_traceCoreInterface_toEncoder_groups_0_valid never toggled");
      if (t_XSCore__io_traceCoreInterface_toEncoder_groups_0_bits_iaddr) tg++; else $display("COV: XSCore.io_traceCoreInterface_toEncoder_groups_0_bits_iaddr never toggled");
      if (t_XSCore__io_traceCoreInterface_toEncoder_groups_0_bits_itype) tg++; else $display("COV: XSCore.io_traceCoreInterface_toEncoder_groups_0_bits_itype never toggled");
      if (t_XSCore__io_traceCoreInterface_toEncoder_groups_0_bits_iretire) tg++; else $display("COV: XSCore.io_traceCoreInterface_toEncoder_groups_0_bits_iretire never toggled");
      if (t_XSCore__io_traceCoreInterface_toEncoder_groups_0_bits_ilastsize) tg++; else $display("COV: XSCore.io_traceCoreInterface_toEncoder_groups_0_bits_ilastsize never toggled");
      if (t_XSCore__io_traceCoreInterface_toEncoder_groups_1_valid) tg++; else $display("COV: XSCore.io_traceCoreInterface_toEncoder_groups_1_valid never toggled");
      if (t_XSCore__io_traceCoreInterface_toEncoder_groups_1_bits_iaddr) tg++; else $display("COV: XSCore.io_traceCoreInterface_toEncoder_groups_1_bits_iaddr never toggled");
      if (t_XSCore__io_traceCoreInterface_toEncoder_groups_1_bits_itype) tg++; else $display("COV: XSCore.io_traceCoreInterface_toEncoder_groups_1_bits_itype never toggled");
      if (t_XSCore__io_traceCoreInterface_toEncoder_groups_1_bits_iretire) tg++; else $display("COV: XSCore.io_traceCoreInterface_toEncoder_groups_1_bits_iretire never toggled");
      if (t_XSCore__io_traceCoreInterface_toEncoder_groups_1_bits_ilastsize) tg++; else $display("COV: XSCore.io_traceCoreInterface_toEncoder_groups_1_bits_ilastsize never toggled");
      if (t_XSCore__io_traceCoreInterface_toEncoder_groups_2_valid) tg++; else $display("COV: XSCore.io_traceCoreInterface_toEncoder_groups_2_valid never toggled");
      if (t_XSCore__io_traceCoreInterface_toEncoder_groups_2_bits_iaddr) tg++; else $display("COV: XSCore.io_traceCoreInterface_toEncoder_groups_2_bits_iaddr never toggled");
      if (t_XSCore__io_traceCoreInterface_toEncoder_groups_2_bits_itype) tg++; else $display("COV: XSCore.io_traceCoreInterface_toEncoder_groups_2_bits_itype never toggled");
      if (t_XSCore__io_traceCoreInterface_toEncoder_groups_2_bits_iretire) tg++; else $display("COV: XSCore.io_traceCoreInterface_toEncoder_groups_2_bits_iretire never toggled");
      if (t_XSCore__io_traceCoreInterface_toEncoder_groups_2_bits_ilastsize) tg++; else $display("COV: XSCore.io_traceCoreInterface_toEncoder_groups_2_bits_ilastsize never toggled");
      if (t_XSCore__io_l2PfCtrl_l2_pf_master_en) tg++; else $display("COV: XSCore.io_l2PfCtrl_l2_pf_master_en never toggled");
      if (t_XSCore__io_l2PfCtrl_l2_pf_recv_en) tg++; else $display("COV: XSCore.io_l2PfCtrl_l2_pf_recv_en never toggled");
      if (t_XSCore__io_l2PfCtrl_l2_pbop_en) tg++; else $display("COV: XSCore.io_l2PfCtrl_l2_pbop_en never toggled");
      if (t_XSCore__io_l2PfCtrl_l2_vbop_en) tg++; else $display("COV: XSCore.io_l2PfCtrl_l2_vbop_en never toggled");
      if (t_XSCore__io_l2PfCtrl_l2_pf_delay_latency) tg++; else $display("COV: XSCore.io_l2PfCtrl_l2_pf_delay_latency never toggled");
      if (t_XSCore__io_beu_errors_icache_ecc_error_valid) tg++; else $display("COV: XSCore.io_beu_errors_icache_ecc_error_valid never toggled");
      if (t_XSCore__io_beu_errors_icache_ecc_error_bits) tg++; else $display("COV: XSCore.io_beu_errors_icache_ecc_error_bits never toggled");
      if (t_XSCore__io_beu_errors_dcache_ecc_error_valid) tg++; else $display("COV: XSCore.io_beu_errors_dcache_ecc_error_valid never toggled");
      if (t_XSCore__io_beu_errors_dcache_ecc_error_bits) tg++; else $display("COV: XSCore.io_beu_errors_dcache_ecc_error_bits never toggled");
      if (t_XSCore__io_beu_errors_uncache_ecc_error_valid) tg++; else $display("COV: XSCore.io_beu_errors_uncache_ecc_error_valid never toggled");
      if (t_XSCore__io_beu_errors_uncache_ecc_error_bits) tg++; else $display("COV: XSCore.io_beu_errors_uncache_ecc_error_bits never toggled");
      if (t_XSCore__io_l2_tlb_req_resp_valid) tg++; else $display("COV: XSCore.io_l2_tlb_req_resp_valid never toggled");
      if (t_XSCore__io_l2_tlb_req_resp_bits_paddr_0) tg++; else $display("COV: XSCore.io_l2_tlb_req_resp_bits_paddr_0 never toggled");
      if (t_XSCore__io_l2_tlb_req_resp_bits_pbmt_0) tg++; else $display("COV: XSCore.io_l2_tlb_req_resp_bits_pbmt_0 never toggled");
      if (t_XSCore__io_l2_tlb_req_resp_bits_miss) tg++; else $display("COV: XSCore.io_l2_tlb_req_resp_bits_miss never toggled");
      if (t_XSCore__io_l2_tlb_req_resp_bits_excp_0_gpf_ld) tg++; else $display("COV: XSCore.io_l2_tlb_req_resp_bits_excp_0_gpf_ld never toggled");
      if (t_XSCore__io_l2_tlb_req_resp_bits_excp_0_pf_ld) tg++; else $display("COV: XSCore.io_l2_tlb_req_resp_bits_excp_0_pf_ld never toggled");
      if (t_XSCore__io_l2_tlb_req_resp_bits_excp_0_af_ld) tg++; else $display("COV: XSCore.io_l2_tlb_req_resp_bits_excp_0_af_ld never toggled");
      if (t_XSCore__io_l2_pmp_resp_ld) tg++; else $display("COV: XSCore.io_l2_pmp_resp_ld never toggled");
      if (t_XSCore__io_l2_pmp_resp_mmio) tg++; else $display("COV: XSCore.io_l2_pmp_resp_mmio never toggled");
      if (t_XSCore__io_debugTopDown_robHeadPaddr_valid) tg++; else $display("COV: XSCore.io_debugTopDown_robHeadPaddr_valid never toggled");
      if (t_XSCore__io_debugTopDown_robHeadPaddr_bits) tg++; else $display("COV: XSCore.io_debugTopDown_robHeadPaddr_bits never toggled");
      if (t_XSCore__gatewayIn_packed_0_bore) tg++; else $display("COV: XSCore.gatewayIn_packed_0_bore never toggled");
      if (t_XSCore__gatewayIn_packed_1_bore) tg++; else $display("COV: XSCore.gatewayIn_packed_1_bore never toggled");
      if (t_XSCore__gatewayIn_packed_2_bore) tg++; else $display("COV: XSCore.gatewayIn_packed_2_bore never toggled");
      if (t_XSCore__gatewayIn_packed_3_bore) tg++; else $display("COV: XSCore.gatewayIn_packed_3_bore never toggled");
      if (t_XSCore__gatewayIn_packed_4_bore) tg++; else $display("COV: XSCore.gatewayIn_packed_4_bore never toggled");
      if (t_XSCore__gatewayIn_packed_5_bore) tg++; else $display("COV: XSCore.gatewayIn_packed_5_bore never toggled");
      if (t_XSCore__gatewayIn_packed_6_bore) tg++; else $display("COV: XSCore.gatewayIn_packed_6_bore never toggled");
      if (t_XSCore__gatewayIn_packed_7_bore) tg++; else $display("COV: XSCore.gatewayIn_packed_7_bore never toggled");
      if (t_XSCore__gatewayIn_packed_8_bore) tg++; else $display("COV: XSCore.gatewayIn_packed_8_bore never toggled");
      if (t_XSCore__gatewayIn_packed_9_bore) tg++; else $display("COV: XSCore.gatewayIn_packed_9_bore never toggled");
      if (t_XSCore__gatewayIn_packed_10_bore) tg++; else $display("COV: XSCore.gatewayIn_packed_10_bore never toggled");
      if (t_XSCore__gatewayIn_packed_11_bore) tg++; else $display("COV: XSCore.gatewayIn_packed_11_bore never toggled");
      if (t_XSCore__gatewayIn_packed_12_bore) tg++; else $display("COV: XSCore.gatewayIn_packed_12_bore never toggled");
      if (t_XSCore__gatewayIn_packed_13_bore) tg++; else $display("COV: XSCore.gatewayIn_packed_13_bore never toggled");
      if (t_XSCore__gatewayIn_packed_14_bore) tg++; else $display("COV: XSCore.gatewayIn_packed_14_bore never toggled");
      if (t_XSCore__gatewayIn_packed_15_bore) tg++; else $display("COV: XSCore.gatewayIn_packed_15_bore never toggled");
      if (t_XSCore__gatewayIn_packed_16_bore) tg++; else $display("COV: XSCore.gatewayIn_packed_16_bore never toggled");
      if (t_XSCore__gatewayIn_packed_17_bore) tg++; else $display("COV: XSCore.gatewayIn_packed_17_bore never toggled");
      if (t_XSCore__gatewayIn_packed_18_bore) tg++; else $display("COV: XSCore.gatewayIn_packed_18_bore never toggled");
      if (t_XSCore__gatewayIn_packed_19_bore) tg++; else $display("COV: XSCore.gatewayIn_packed_19_bore never toggled");
      if (t_XSCore__gatewayIn_packed_20_bore) tg++; else $display("COV: XSCore.gatewayIn_packed_20_bore never toggled");
      if (t_XSCore__gatewayIn_packed_21_bore) tg++; else $display("COV: XSCore.gatewayIn_packed_21_bore never toggled");
      if (t_XSCore__gatewayIn_packed_22_bore) tg++; else $display("COV: XSCore.gatewayIn_packed_22_bore never toggled");
      if (t_XSCore__gatewayIn_packed_23_bore) tg++; else $display("COV: XSCore.gatewayIn_packed_23_bore never toggled");
      if (t_XSCore__gatewayIn_packed_24_bore) tg++; else $display("COV: XSCore.gatewayIn_packed_24_bore never toggled");
      if (t_XSCore__gatewayIn_packed_25_bore) tg++; else $display("COV: XSCore.gatewayIn_packed_25_bore never toggled");
      if (t_XSCore__gatewayIn_packed_26_bore) tg++; else $display("COV: XSCore.gatewayIn_packed_26_bore never toggled");
      if (t_XSCore__gatewayIn_packed_27_bore) tg++; else $display("COV: XSCore.gatewayIn_packed_27_bore never toggled");
      if (t_XSCore__gatewayIn_packed_28_bore) tg++; else $display("COV: XSCore.gatewayIn_packed_28_bore never toggled");
      if (t_XSCore__gatewayIn_packed_29_bore) tg++; else $display("COV: XSCore.gatewayIn_packed_29_bore never toggled");
      if (t_XSCore__gatewayIn_packed_30_bore) tg++; else $display("COV: XSCore.gatewayIn_packed_30_bore never toggled");
      if (t_XSCore__gatewayIn_packed_31_bore) tg++; else $display("COV: XSCore.gatewayIn_packed_31_bore never toggled");
      if (t_XSCore__gatewayIn_packed_32_bore) tg++; else $display("COV: XSCore.gatewayIn_packed_32_bore never toggled");
      if (t_XSCore__gatewayIn_packed_33_bore) tg++; else $display("COV: XSCore.gatewayIn_packed_33_bore never toggled");
      if (t_XSCore__gatewayIn_packed_34_bore) tg++; else $display("COV: XSCore.gatewayIn_packed_34_bore never toggled");
      if (t_XSCore__gatewayIn_packed_35_bore) tg++; else $display("COV: XSCore.gatewayIn_packed_35_bore never toggled");
      if (t_XSCore__gatewayIn_packed_36_bore) tg++; else $display("COV: XSCore.gatewayIn_packed_36_bore never toggled");
      if (t_XSCore__gatewayIn_packed_37_bore) tg++; else $display("COV: XSCore.gatewayIn_packed_37_bore never toggled");
      if (t_XSCore__gatewayIn_packed_38_bore) tg++; else $display("COV: XSCore.gatewayIn_packed_38_bore never toggled");
      if (t_XSCore__gatewayIn_packed_39_bore) tg++; else $display("COV: XSCore.gatewayIn_packed_39_bore never toggled");
      if (t_XSCore__gatewayIn_packed_40_bore) tg++; else $display("COV: XSCore.gatewayIn_packed_40_bore never toggled");
      if (t_XSCore__gatewayIn_packed_41_bore) tg++; else $display("COV: XSCore.gatewayIn_packed_41_bore never toggled");
      if (t_XSCore__gatewayIn_packed_42_bore) tg++; else $display("COV: XSCore.gatewayIn_packed_42_bore never toggled");
      if (t_XSCore__gatewayIn_packed_43_bore) tg++; else $display("COV: XSCore.gatewayIn_packed_43_bore never toggled");
      if (t_XSCore__gatewayIn_packed_44_bore) tg++; else $display("COV: XSCore.gatewayIn_packed_44_bore never toggled");
      if (t_XSCore__gatewayIn_packed_45_bore) tg++; else $display("COV: XSCore.gatewayIn_packed_45_bore never toggled");
      if (t_XSCore__gatewayIn_packed_46_bore) tg++; else $display("COV: XSCore.gatewayIn_packed_46_bore never toggled");
      if (t_XSCore__gatewayIn_packed_47_bore) tg++; else $display("COV: XSCore.gatewayIn_packed_47_bore never toggled");
      if (t_XSCore__gatewayIn_packed_48_bore) tg++; else $display("COV: XSCore.gatewayIn_packed_48_bore never toggled");
      if (t_XSCore__gatewayIn_packed_49_bore) tg++; else $display("COV: XSCore.gatewayIn_packed_49_bore never toggled");
      if (t_XSCore__gatewayIn_packed_50_bore) tg++; else $display("COV: XSCore.gatewayIn_packed_50_bore never toggled");
      if (t_XSCore__gatewayIn_packed_51_bore) tg++; else $display("COV: XSCore.gatewayIn_packed_51_bore never toggled");
      if (t_XSCore__gatewayIn_packed_52_bore) tg++; else $display("COV: XSCore.gatewayIn_packed_52_bore never toggled");
      if (t_XSCore__gatewayIn_packed_53_bore) tg++; else $display("COV: XSCore.gatewayIn_packed_53_bore never toggled");
      if (t_XSCore__gatewayIn_packed_54_bore) tg++; else $display("COV: XSCore.gatewayIn_packed_54_bore never toggled");
      if (t_XSCore__gatewayIn_packed_55_bore) tg++; else $display("COV: XSCore.gatewayIn_packed_55_bore never toggled");
      if (t_XSCore__gatewayIn_packed_56_bore) tg++; else $display("COV: XSCore.gatewayIn_packed_56_bore never toggled");
      if (t_XSCore__gatewayIn_packed_57_bore) tg++; else $display("COV: XSCore.gatewayIn_packed_57_bore never toggled");
      if (t_XSCore__gatewayIn_packed_58_bore) tg++; else $display("COV: XSCore.gatewayIn_packed_58_bore never toggled");
      if (t_XSCore__gatewayIn_packed_59_bore) tg++; else $display("COV: XSCore.gatewayIn_packed_59_bore never toggled");
      if (t_XSCore__gatewayIn_packed_60_bore) tg++; else $display("COV: XSCore.gatewayIn_packed_60_bore never toggled");
      $display("XSCore: toggled=%0d/195 (need >= 1)", tg);
      if (tg < 1) covfail = 1;
      $display("XSCore: cover icache_req = %0d", cov_XSCore_icache_req);
      if (cov_XSCore_icache_req == 0) covfail = 1;
      $display("XSCore: cover icache_resp = %0d", cov_XSCore_icache_resp);
      if (cov_XSCore_icache_resp == 0) covfail = 1;
      $display("XSCore: cover cfvec = %0d", cov_XSCore_cfvec);
      if (cov_XSCore_cfvec == 0) covfail = 1;
      $display("XSCore: cover redirect = %0d", cov_XSCore_redirect);
      if (cov_XSCore_redirect == 0) covfail = 1;
      $display("XSCore: cover lsq_enq = %0d", cov_XSCore_lsq_enq);
      if (cov_XSCore_lsq_enq == 0) covfail = 1;
    end
    $display("checks=%0d errors=%0d", checks, errors);
    if (errors != 0) begin $display("TEST FAILED (mismatch)"); $fatal(1); end
    if (checks == 0 || covfail) begin $display("TEST FAILED (coverage)"); $fatal(1); end
    $display("TEST PASSED");
    $finish;
  end
endmodule
