// 自动生成:scripts/gen_l2top.py —— 勿手改(顶层 glue 为从 Scala 意图的可读重写)

// 15 子模块类型黑盒 stub(空体,所有 output 驱 0)。
// 注:UT/FM 默认用 golden 子模块真定义(-f 闭包);本 stub 仅备快速 elaborate。

module BusErrorUnit(
  input  clock,
  input  reset,
  output  auto_in_a_ready,
  input  auto_in_a_valid,
  input  [3:0] auto_in_a_bits_opcode,
  input  [1:0] auto_in_a_bits_size,
  input  [2:0] auto_in_a_bits_source,
  input  [29:0] auto_in_a_bits_address,
  input  [7:0] auto_in_a_bits_mask,
  input  [63:0] auto_in_a_bits_data,
  input  auto_in_d_ready,
  output  auto_in_d_valid,
  output  [3:0] auto_in_d_bits_opcode,
  output  [1:0] auto_in_d_bits_size,
  output  [2:0] auto_in_d_bits_source,
  output  [63:0] auto_in_d_bits_data,
  output  auto_int_out_0,
  input  io_errors_icache_ecc_error_valid,
  input  [47:0] io_errors_icache_ecc_error_bits,
  input  io_errors_dcache_ecc_error_valid,
  input  [47:0] io_errors_dcache_ecc_error_bits,
  input  io_errors_uncache_ecc_error_valid,
  input  [47:0] io_errors_uncache_ecc_error_bits,
  input  io_errors_l2_ecc_error_valid,
  input  [47:0] io_errors_l2_ecc_error_bits,
  output  io_interrupt
);
  assign auto_in_a_ready = '0;
  assign auto_in_d_valid = '0;
  assign auto_in_d_bits_opcode = '0;
  assign auto_in_d_bits_size = '0;
  assign auto_in_d_bits_source = '0;
  assign auto_in_d_bits_data = '0;
  assign auto_int_out_0 = '0;
  assign io_interrupt = '0;
endmodule

module BusPerfMonitor(
  output  auto_in_2_a_ready,
  input  auto_in_2_a_valid,
  input  [3:0] auto_in_2_a_bits_opcode,
  input  [2:0] auto_in_2_a_bits_param,
  input  [2:0] auto_in_2_a_bits_size,
  input  [2:0] auto_in_2_a_bits_source,
  input  [47:0] auto_in_2_a_bits_address,
  input  [4:0] auto_in_2_a_bits_user_reqSource,
  input  [31:0] auto_in_2_a_bits_mask,
  input  [255:0] auto_in_2_a_bits_data,
  input  auto_in_2_a_bits_corrupt,
  input  auto_in_2_d_ready,
  output  auto_in_2_d_valid,
  output  [3:0] auto_in_2_d_bits_opcode,
  output  [1:0] auto_in_2_d_bits_param,
  output  [2:0] auto_in_2_d_bits_size,
  output  [2:0] auto_in_2_d_bits_source,
  output  [9:0] auto_in_2_d_bits_sink,
  output  auto_in_2_d_bits_denied,
  output  [255:0] auto_in_2_d_bits_data,
  output  auto_in_2_d_bits_corrupt,
  output  auto_in_1_a_ready,
  input  auto_in_1_a_valid,
  input  [3:0] auto_in_1_a_bits_opcode,
  input  [2:0] auto_in_1_a_bits_param,
  input  [2:0] auto_in_1_a_bits_size,
  input  [3:0] auto_in_1_a_bits_source,
  input  [47:0] auto_in_1_a_bits_address,
  input  [1:0] auto_in_1_a_bits_user_alias,
  input  [4:0] auto_in_1_a_bits_user_reqSource,
  input  auto_in_1_a_bits_user_needHint,
  input  [31:0] auto_in_1_a_bits_mask,
  input  [255:0] auto_in_1_a_bits_data,
  input  auto_in_1_a_bits_corrupt,
  input  auto_in_1_d_ready,
  output  auto_in_1_d_valid,
  output  [3:0] auto_in_1_d_bits_opcode,
  output  [1:0] auto_in_1_d_bits_param,
  output  [2:0] auto_in_1_d_bits_size,
  output  [3:0] auto_in_1_d_bits_source,
  output  [9:0] auto_in_1_d_bits_sink,
  output  auto_in_1_d_bits_denied,
  output  [255:0] auto_in_1_d_bits_data,
  output  auto_in_1_d_bits_corrupt,
  output  auto_in_0_a_ready,
  input  auto_in_0_a_valid,
  input  [3:0] auto_in_0_a_bits_opcode,
  input  [2:0] auto_in_0_a_bits_param,
  input  [2:0] auto_in_0_a_bits_size,
  input  [5:0] auto_in_0_a_bits_source,
  input  [47:0] auto_in_0_a_bits_address,
  input  [1:0] auto_in_0_a_bits_user_alias,
  input  [43:0] auto_in_0_a_bits_user_vaddr,
  input  [4:0] auto_in_0_a_bits_user_reqSource,
  input  auto_in_0_a_bits_user_needHint,
  input  auto_in_0_a_bits_echo_isKeyword,
  input  [31:0] auto_in_0_a_bits_mask,
  input  [255:0] auto_in_0_a_bits_data,
  input  auto_in_0_a_bits_corrupt,
  input  auto_in_0_b_ready,
  output  auto_in_0_b_valid,
  output  [2:0] auto_in_0_b_bits_opcode,
  output  [1:0] auto_in_0_b_bits_param,
  output  [2:0] auto_in_0_b_bits_size,
  output  [5:0] auto_in_0_b_bits_source,
  output  [47:0] auto_in_0_b_bits_address,
  output  [31:0] auto_in_0_b_bits_mask,
  output  [255:0] auto_in_0_b_bits_data,
  output  auto_in_0_b_bits_corrupt,
  output  auto_in_0_c_ready,
  input  auto_in_0_c_valid,
  input  [2:0] auto_in_0_c_bits_opcode,
  input  [2:0] auto_in_0_c_bits_param,
  input  [2:0] auto_in_0_c_bits_size,
  input  [5:0] auto_in_0_c_bits_source,
  input  [47:0] auto_in_0_c_bits_address,
  input  [1:0] auto_in_0_c_bits_user_alias,
  input  [43:0] auto_in_0_c_bits_user_vaddr,
  input  [4:0] auto_in_0_c_bits_user_reqSource,
  input  auto_in_0_c_bits_user_needHint,
  input  auto_in_0_c_bits_echo_isKeyword,
  input  [255:0] auto_in_0_c_bits_data,
  input  auto_in_0_c_bits_corrupt,
  input  auto_in_0_d_ready,
  output  auto_in_0_d_valid,
  output  [3:0] auto_in_0_d_bits_opcode,
  output  [1:0] auto_in_0_d_bits_param,
  output  [2:0] auto_in_0_d_bits_size,
  output  [5:0] auto_in_0_d_bits_source,
  output  [9:0] auto_in_0_d_bits_sink,
  output  auto_in_0_d_bits_denied,
  output  auto_in_0_d_bits_echo_isKeyword,
  output  [255:0] auto_in_0_d_bits_data,
  output  auto_in_0_d_bits_corrupt,
  output  auto_in_0_e_ready,
  input  auto_in_0_e_valid,
  input  [9:0] auto_in_0_e_bits_sink,
  input  auto_out_2_a_ready,
  output  auto_out_2_a_valid,
  output  [3:0] auto_out_2_a_bits_opcode,
  output  [2:0] auto_out_2_a_bits_param,
  output  [2:0] auto_out_2_a_bits_size,
  output  [2:0] auto_out_2_a_bits_source,
  output  [47:0] auto_out_2_a_bits_address,
  output  [4:0] auto_out_2_a_bits_user_reqSource,
  output  [31:0] auto_out_2_a_bits_mask,
  output  [255:0] auto_out_2_a_bits_data,
  output  auto_out_2_a_bits_corrupt,
  output  auto_out_2_d_ready,
  input  auto_out_2_d_valid,
  input  [3:0] auto_out_2_d_bits_opcode,
  input  [1:0] auto_out_2_d_bits_param,
  input  [2:0] auto_out_2_d_bits_size,
  input  [2:0] auto_out_2_d_bits_source,
  input  [9:0] auto_out_2_d_bits_sink,
  input  auto_out_2_d_bits_denied,
  input  [255:0] auto_out_2_d_bits_data,
  input  auto_out_2_d_bits_corrupt,
  input  auto_out_1_a_ready,
  output  auto_out_1_a_valid,
  output  [3:0] auto_out_1_a_bits_opcode,
  output  [2:0] auto_out_1_a_bits_param,
  output  [2:0] auto_out_1_a_bits_size,
  output  [3:0] auto_out_1_a_bits_source,
  output  [47:0] auto_out_1_a_bits_address,
  output  [1:0] auto_out_1_a_bits_user_alias,
  output  [4:0] auto_out_1_a_bits_user_reqSource,
  output  auto_out_1_a_bits_user_needHint,
  output  [31:0] auto_out_1_a_bits_mask,
  output  [255:0] auto_out_1_a_bits_data,
  output  auto_out_1_a_bits_corrupt,
  output  auto_out_1_d_ready,
  input  auto_out_1_d_valid,
  input  [3:0] auto_out_1_d_bits_opcode,
  input  [1:0] auto_out_1_d_bits_param,
  input  [2:0] auto_out_1_d_bits_size,
  input  [3:0] auto_out_1_d_bits_source,
  input  [9:0] auto_out_1_d_bits_sink,
  input  auto_out_1_d_bits_denied,
  input  [255:0] auto_out_1_d_bits_data,
  input  auto_out_1_d_bits_corrupt,
  input  auto_out_0_a_ready,
  output  auto_out_0_a_valid,
  output  [3:0] auto_out_0_a_bits_opcode,
  output  [2:0] auto_out_0_a_bits_param,
  output  [2:0] auto_out_0_a_bits_size,
  output  [5:0] auto_out_0_a_bits_source,
  output  [47:0] auto_out_0_a_bits_address,
  output  [1:0] auto_out_0_a_bits_user_alias,
  output  [43:0] auto_out_0_a_bits_user_vaddr,
  output  [4:0] auto_out_0_a_bits_user_reqSource,
  output  auto_out_0_a_bits_user_needHint,
  output  auto_out_0_a_bits_echo_isKeyword,
  output  [31:0] auto_out_0_a_bits_mask,
  output  [255:0] auto_out_0_a_bits_data,
  output  auto_out_0_a_bits_corrupt,
  output  auto_out_0_b_ready,
  input  auto_out_0_b_valid,
  input  [2:0] auto_out_0_b_bits_opcode,
  input  [1:0] auto_out_0_b_bits_param,
  input  [2:0] auto_out_0_b_bits_size,
  input  [5:0] auto_out_0_b_bits_source,
  input  [47:0] auto_out_0_b_bits_address,
  input  [31:0] auto_out_0_b_bits_mask,
  input  [255:0] auto_out_0_b_bits_data,
  input  auto_out_0_b_bits_corrupt,
  input  auto_out_0_c_ready,
  output  auto_out_0_c_valid,
  output  [2:0] auto_out_0_c_bits_opcode,
  output  [2:0] auto_out_0_c_bits_param,
  output  [2:0] auto_out_0_c_bits_size,
  output  [5:0] auto_out_0_c_bits_source,
  output  [47:0] auto_out_0_c_bits_address,
  output  [1:0] auto_out_0_c_bits_user_alias,
  output  [43:0] auto_out_0_c_bits_user_vaddr,
  output  [4:0] auto_out_0_c_bits_user_reqSource,
  output  auto_out_0_c_bits_user_needHint,
  output  auto_out_0_c_bits_echo_isKeyword,
  output  [255:0] auto_out_0_c_bits_data,
  output  auto_out_0_c_bits_corrupt,
  output  auto_out_0_d_ready,
  input  auto_out_0_d_valid,
  input  [3:0] auto_out_0_d_bits_opcode,
  input  [1:0] auto_out_0_d_bits_param,
  input  [2:0] auto_out_0_d_bits_size,
  input  [5:0] auto_out_0_d_bits_source,
  input  [9:0] auto_out_0_d_bits_sink,
  input  auto_out_0_d_bits_denied,
  input  auto_out_0_d_bits_echo_isKeyword,
  input  [255:0] auto_out_0_d_bits_data,
  input  auto_out_0_d_bits_corrupt,
  input  auto_out_0_e_ready,
  output  auto_out_0_e_valid,
  output  [9:0] auto_out_0_e_bits_sink
);
  assign auto_in_2_a_ready = '0;
  assign auto_in_2_d_valid = '0;
  assign auto_in_2_d_bits_opcode = '0;
  assign auto_in_2_d_bits_param = '0;
  assign auto_in_2_d_bits_size = '0;
  assign auto_in_2_d_bits_source = '0;
  assign auto_in_2_d_bits_sink = '0;
  assign auto_in_2_d_bits_denied = '0;
  assign auto_in_2_d_bits_data = '0;
  assign auto_in_2_d_bits_corrupt = '0;
  assign auto_in_1_a_ready = '0;
  assign auto_in_1_d_valid = '0;
  assign auto_in_1_d_bits_opcode = '0;
  assign auto_in_1_d_bits_param = '0;
  assign auto_in_1_d_bits_size = '0;
  assign auto_in_1_d_bits_source = '0;
  assign auto_in_1_d_bits_sink = '0;
  assign auto_in_1_d_bits_denied = '0;
  assign auto_in_1_d_bits_data = '0;
  assign auto_in_1_d_bits_corrupt = '0;
  assign auto_in_0_a_ready = '0;
  assign auto_in_0_b_valid = '0;
  assign auto_in_0_b_bits_opcode = '0;
  assign auto_in_0_b_bits_param = '0;
  assign auto_in_0_b_bits_size = '0;
  assign auto_in_0_b_bits_source = '0;
  assign auto_in_0_b_bits_address = '0;
  assign auto_in_0_b_bits_mask = '0;
  assign auto_in_0_b_bits_data = '0;
  assign auto_in_0_b_bits_corrupt = '0;
  assign auto_in_0_c_ready = '0;
  assign auto_in_0_d_valid = '0;
  assign auto_in_0_d_bits_opcode = '0;
  assign auto_in_0_d_bits_param = '0;
  assign auto_in_0_d_bits_size = '0;
  assign auto_in_0_d_bits_source = '0;
  assign auto_in_0_d_bits_sink = '0;
  assign auto_in_0_d_bits_denied = '0;
  assign auto_in_0_d_bits_echo_isKeyword = '0;
  assign auto_in_0_d_bits_data = '0;
  assign auto_in_0_d_bits_corrupt = '0;
  assign auto_in_0_e_ready = '0;
  assign auto_out_2_a_valid = '0;
  assign auto_out_2_a_bits_opcode = '0;
  assign auto_out_2_a_bits_param = '0;
  assign auto_out_2_a_bits_size = '0;
  assign auto_out_2_a_bits_source = '0;
  assign auto_out_2_a_bits_address = '0;
  assign auto_out_2_a_bits_user_reqSource = '0;
  assign auto_out_2_a_bits_mask = '0;
  assign auto_out_2_a_bits_data = '0;
  assign auto_out_2_a_bits_corrupt = '0;
  assign auto_out_2_d_ready = '0;
  assign auto_out_1_a_valid = '0;
  assign auto_out_1_a_bits_opcode = '0;
  assign auto_out_1_a_bits_param = '0;
  assign auto_out_1_a_bits_size = '0;
  assign auto_out_1_a_bits_source = '0;
  assign auto_out_1_a_bits_address = '0;
  assign auto_out_1_a_bits_user_alias = '0;
  assign auto_out_1_a_bits_user_reqSource = '0;
  assign auto_out_1_a_bits_user_needHint = '0;
  assign auto_out_1_a_bits_mask = '0;
  assign auto_out_1_a_bits_data = '0;
  assign auto_out_1_a_bits_corrupt = '0;
  assign auto_out_1_d_ready = '0;
  assign auto_out_0_a_valid = '0;
  assign auto_out_0_a_bits_opcode = '0;
  assign auto_out_0_a_bits_param = '0;
  assign auto_out_0_a_bits_size = '0;
  assign auto_out_0_a_bits_source = '0;
  assign auto_out_0_a_bits_address = '0;
  assign auto_out_0_a_bits_user_alias = '0;
  assign auto_out_0_a_bits_user_vaddr = '0;
  assign auto_out_0_a_bits_user_reqSource = '0;
  assign auto_out_0_a_bits_user_needHint = '0;
  assign auto_out_0_a_bits_echo_isKeyword = '0;
  assign auto_out_0_a_bits_mask = '0;
  assign auto_out_0_a_bits_data = '0;
  assign auto_out_0_a_bits_corrupt = '0;
  assign auto_out_0_b_ready = '0;
  assign auto_out_0_c_valid = '0;
  assign auto_out_0_c_bits_opcode = '0;
  assign auto_out_0_c_bits_param = '0;
  assign auto_out_0_c_bits_size = '0;
  assign auto_out_0_c_bits_source = '0;
  assign auto_out_0_c_bits_address = '0;
  assign auto_out_0_c_bits_user_alias = '0;
  assign auto_out_0_c_bits_user_vaddr = '0;
  assign auto_out_0_c_bits_user_reqSource = '0;
  assign auto_out_0_c_bits_user_needHint = '0;
  assign auto_out_0_c_bits_echo_isKeyword = '0;
  assign auto_out_0_c_bits_data = '0;
  assign auto_out_0_c_bits_corrupt = '0;
  assign auto_out_0_d_ready = '0;
  assign auto_out_0_e_valid = '0;
  assign auto_out_0_e_bits_sink = '0;
endmodule

module DelayN_334(
  input  clock,
  input  [47:0] io_in,
  output  [47:0] io_out
);
  assign io_out = '0;
endmodule

module TL2CHICoupledL2(
  input  clock,
  input  reset,
  output  auto_mmioBridge_mmio_in_a_ready,
  input  auto_mmioBridge_mmio_in_a_valid,
  input  [3:0] auto_mmioBridge_mmio_in_a_bits_opcode,
  input  [2:0] auto_mmioBridge_mmio_in_a_bits_param,
  input  [1:0] auto_mmioBridge_mmio_in_a_bits_size,
  input  [2:0] auto_mmioBridge_mmio_in_a_bits_source,
  input  [47:0] auto_mmioBridge_mmio_in_a_bits_address,
  input  auto_mmioBridge_mmio_in_a_bits_user_memBackType_MM,
  input  auto_mmioBridge_mmio_in_a_bits_user_memPageType_NC,
  input  [7:0] auto_mmioBridge_mmio_in_a_bits_mask,
  input  [63:0] auto_mmioBridge_mmio_in_a_bits_data,
  input  auto_mmioBridge_mmio_in_a_bits_corrupt,
  input  auto_mmioBridge_mmio_in_d_ready,
  output  auto_mmioBridge_mmio_in_d_valid,
  output  [3:0] auto_mmioBridge_mmio_in_d_bits_opcode,
  output  [1:0] auto_mmioBridge_mmio_in_d_bits_param,
  output  [1:0] auto_mmioBridge_mmio_in_d_bits_size,
  output  [2:0] auto_mmioBridge_mmio_in_d_bits_source,
  output  auto_mmioBridge_mmio_in_d_bits_sink,
  output  auto_mmioBridge_mmio_in_d_bits_denied,
  output  [63:0] auto_mmioBridge_mmio_in_d_bits_data,
  output  auto_mmioBridge_mmio_in_d_bits_corrupt,
  output  auto_in_3_a_ready,
  input  auto_in_3_a_valid,
  input  [3:0] auto_in_3_a_bits_opcode,
  input  [2:0] auto_in_3_a_bits_param,
  input  [2:0] auto_in_3_a_bits_size,
  input  [6:0] auto_in_3_a_bits_source,
  input  [47:0] auto_in_3_a_bits_address,
  input  [4:0] auto_in_3_a_bits_user_reqSource,
  input  [1:0] auto_in_3_a_bits_user_alias,
  input  [43:0] auto_in_3_a_bits_user_vaddr,
  input  auto_in_3_a_bits_user_needHint,
  input  auto_in_3_a_bits_echo_isKeyword,
  input  auto_in_3_a_bits_corrupt,
  input  auto_in_3_b_ready,
  output  auto_in_3_b_valid,
  output  [2:0] auto_in_3_b_bits_opcode,
  output  [1:0] auto_in_3_b_bits_param,
  output  [47:0] auto_in_3_b_bits_address,
  output  [255:0] auto_in_3_b_bits_data,
  output  auto_in_3_c_ready,
  input  auto_in_3_c_valid,
  input  [2:0] auto_in_3_c_bits_opcode,
  input  [2:0] auto_in_3_c_bits_param,
  input  [2:0] auto_in_3_c_bits_size,
  input  [6:0] auto_in_3_c_bits_source,
  input  [47:0] auto_in_3_c_bits_address,
  input  [255:0] auto_in_3_c_bits_data,
  input  auto_in_3_c_bits_corrupt,
  input  auto_in_3_d_ready,
  output  auto_in_3_d_valid,
  output  [3:0] auto_in_3_d_bits_opcode,
  output  [1:0] auto_in_3_d_bits_param,
  output  [6:0] auto_in_3_d_bits_source,
  output  [7:0] auto_in_3_d_bits_sink,
  output  auto_in_3_d_bits_denied,
  output  auto_in_3_d_bits_echo_isKeyword,
  output  [255:0] auto_in_3_d_bits_data,
  output  auto_in_3_d_bits_corrupt,
  input  auto_in_3_e_valid,
  input  [7:0] auto_in_3_e_bits_sink,
  output  auto_in_2_a_ready,
  input  auto_in_2_a_valid,
  input  [3:0] auto_in_2_a_bits_opcode,
  input  [2:0] auto_in_2_a_bits_param,
  input  [2:0] auto_in_2_a_bits_size,
  input  [6:0] auto_in_2_a_bits_source,
  input  [47:0] auto_in_2_a_bits_address,
  input  [4:0] auto_in_2_a_bits_user_reqSource,
  input  [1:0] auto_in_2_a_bits_user_alias,
  input  [43:0] auto_in_2_a_bits_user_vaddr,
  input  auto_in_2_a_bits_user_needHint,
  input  auto_in_2_a_bits_echo_isKeyword,
  input  auto_in_2_a_bits_corrupt,
  input  auto_in_2_b_ready,
  output  auto_in_2_b_valid,
  output  [2:0] auto_in_2_b_bits_opcode,
  output  [1:0] auto_in_2_b_bits_param,
  output  [47:0] auto_in_2_b_bits_address,
  output  [255:0] auto_in_2_b_bits_data,
  output  auto_in_2_c_ready,
  input  auto_in_2_c_valid,
  input  [2:0] auto_in_2_c_bits_opcode,
  input  [2:0] auto_in_2_c_bits_param,
  input  [2:0] auto_in_2_c_bits_size,
  input  [6:0] auto_in_2_c_bits_source,
  input  [47:0] auto_in_2_c_bits_address,
  input  [255:0] auto_in_2_c_bits_data,
  input  auto_in_2_c_bits_corrupt,
  input  auto_in_2_d_ready,
  output  auto_in_2_d_valid,
  output  [3:0] auto_in_2_d_bits_opcode,
  output  [1:0] auto_in_2_d_bits_param,
  output  [6:0] auto_in_2_d_bits_source,
  output  [7:0] auto_in_2_d_bits_sink,
  output  auto_in_2_d_bits_denied,
  output  auto_in_2_d_bits_echo_isKeyword,
  output  [255:0] auto_in_2_d_bits_data,
  output  auto_in_2_d_bits_corrupt,
  input  auto_in_2_e_valid,
  input  [7:0] auto_in_2_e_bits_sink,
  output  auto_in_1_a_ready,
  input  auto_in_1_a_valid,
  input  [3:0] auto_in_1_a_bits_opcode,
  input  [2:0] auto_in_1_a_bits_param,
  input  [2:0] auto_in_1_a_bits_size,
  input  [6:0] auto_in_1_a_bits_source,
  input  [47:0] auto_in_1_a_bits_address,
  input  [4:0] auto_in_1_a_bits_user_reqSource,
  input  [1:0] auto_in_1_a_bits_user_alias,
  input  [43:0] auto_in_1_a_bits_user_vaddr,
  input  auto_in_1_a_bits_user_needHint,
  input  auto_in_1_a_bits_echo_isKeyword,
  input  auto_in_1_a_bits_corrupt,
  input  auto_in_1_b_ready,
  output  auto_in_1_b_valid,
  output  [2:0] auto_in_1_b_bits_opcode,
  output  [1:0] auto_in_1_b_bits_param,
  output  [47:0] auto_in_1_b_bits_address,
  output  [255:0] auto_in_1_b_bits_data,
  output  auto_in_1_c_ready,
  input  auto_in_1_c_valid,
  input  [2:0] auto_in_1_c_bits_opcode,
  input  [2:0] auto_in_1_c_bits_param,
  input  [2:0] auto_in_1_c_bits_size,
  input  [6:0] auto_in_1_c_bits_source,
  input  [47:0] auto_in_1_c_bits_address,
  input  [255:0] auto_in_1_c_bits_data,
  input  auto_in_1_c_bits_corrupt,
  input  auto_in_1_d_ready,
  output  auto_in_1_d_valid,
  output  [3:0] auto_in_1_d_bits_opcode,
  output  [1:0] auto_in_1_d_bits_param,
  output  [6:0] auto_in_1_d_bits_source,
  output  [7:0] auto_in_1_d_bits_sink,
  output  auto_in_1_d_bits_denied,
  output  auto_in_1_d_bits_echo_isKeyword,
  output  [255:0] auto_in_1_d_bits_data,
  output  auto_in_1_d_bits_corrupt,
  input  auto_in_1_e_valid,
  input  [7:0] auto_in_1_e_bits_sink,
  output  auto_in_0_a_ready,
  input  auto_in_0_a_valid,
  input  [3:0] auto_in_0_a_bits_opcode,
  input  [2:0] auto_in_0_a_bits_param,
  input  [2:0] auto_in_0_a_bits_size,
  input  [6:0] auto_in_0_a_bits_source,
  input  [47:0] auto_in_0_a_bits_address,
  input  [4:0] auto_in_0_a_bits_user_reqSource,
  input  [1:0] auto_in_0_a_bits_user_alias,
  input  [43:0] auto_in_0_a_bits_user_vaddr,
  input  auto_in_0_a_bits_user_needHint,
  input  auto_in_0_a_bits_echo_isKeyword,
  input  auto_in_0_a_bits_corrupt,
  input  auto_in_0_b_ready,
  output  auto_in_0_b_valid,
  output  [2:0] auto_in_0_b_bits_opcode,
  output  [1:0] auto_in_0_b_bits_param,
  output  [47:0] auto_in_0_b_bits_address,
  output  [255:0] auto_in_0_b_bits_data,
  output  auto_in_0_c_ready,
  input  auto_in_0_c_valid,
  input  [2:0] auto_in_0_c_bits_opcode,
  input  [2:0] auto_in_0_c_bits_param,
  input  [2:0] auto_in_0_c_bits_size,
  input  [6:0] auto_in_0_c_bits_source,
  input  [47:0] auto_in_0_c_bits_address,
  input  [255:0] auto_in_0_c_bits_data,
  input  auto_in_0_c_bits_corrupt,
  input  auto_in_0_d_ready,
  output  auto_in_0_d_valid,
  output  [3:0] auto_in_0_d_bits_opcode,
  output  [1:0] auto_in_0_d_bits_param,
  output  [6:0] auto_in_0_d_bits_source,
  output  [7:0] auto_in_0_d_bits_sink,
  output  auto_in_0_d_bits_denied,
  output  auto_in_0_d_bits_echo_isKeyword,
  output  [255:0] auto_in_0_d_bits_data,
  output  auto_in_0_d_bits_corrupt,
  input  auto_in_0_e_valid,
  input  [7:0] auto_in_0_e_bits_sink,
  input  [63:0] auto_pf_recv_in_addr,
  input  [4:0] auto_pf_recv_in_pf_source,
  input  auto_pf_recv_in_addr_valid,
  input  io_pfCtrlFromCore_l2_pf_master_en,
  input  io_pfCtrlFromCore_l2_pf_recv_en,
  input  io_pfCtrlFromCore_l2_pbop_en,
  input  io_pfCtrlFromCore_l2_vbop_en,
  output  io_l2_hint_valid,
  output  [31:0] io_l2_hint_bits_sourceId,
  output  io_l2_hint_bits_isKeyword,
  output  io_l2_tlb_req_req_valid,
  output  [49:0] io_l2_tlb_req_req_bits_vaddr,
  output  [2:0] io_l2_tlb_req_req_bits_cmd,
  output  io_l2_tlb_req_req_bits_kill,
  output  io_l2_tlb_req_req_bits_no_translate,
  input  io_l2_tlb_req_resp_valid,
  input  [47:0] io_l2_tlb_req_resp_bits_paddr_0,
  input  [1:0] io_l2_tlb_req_resp_bits_pbmt,
  input  io_l2_tlb_req_resp_bits_miss,
  input  io_l2_tlb_req_resp_bits_excp_0_gpf_ld,
  input  io_l2_tlb_req_resp_bits_excp_0_pf_ld,
  input  io_l2_tlb_req_resp_bits_excp_0_af_ld,
  input  io_l2_tlb_req_pmp_resp_ld,
  input  io_l2_tlb_req_pmp_resp_mmio,
  input  io_debugTopDown_robHeadPaddr_valid,
  input  [35:0] io_debugTopDown_robHeadPaddr_bits,
  output  io_debugTopDown_l2MissMatch,
  output  io_l2Miss,
  output  io_error_valid,
  output  [45:0] io_error_address,
  input  io_dft_ram_hold,
  input  io_dft_ram_bypass,
  input  io_dft_ram_bp_clken,
  input  io_dft_ram_aux_clk,
  input  io_dft_ram_aux_ckbp,
  input  io_dft_ram_mcp_hold,
  input  io_dft_cgen,
  output  [5:0] io_perf_1_value,
  output  [5:0] io_perf_2_value,
  output  [5:0] io_perf_3_value,
  output  [5:0] io_perf_4_value,
  output  [5:0] io_perf_5_value,
  output  [5:0] io_perf_6_value,
  output  [5:0] io_perf_7_value,
  output  [5:0] io_perf_8_value,
  output  [5:0] io_perf_9_value,
  output  [5:0] io_perf_10_value,
  output  [5:0] io_perf_11_value,
  output  [5:0] io_perf_12_value,
  output  [5:0] io_perf_13_value,
  output  [5:0] io_perf_14_value,
  output  [5:0] io_perf_15_value,
  output  [5:0] io_perf_16_value,
  output  [5:0] io_perf_17_value,
  output  [5:0] io_perf_18_value,
  output  [5:0] io_perf_19_value,
  output  [5:0] io_perf_20_value,
  output  [5:0] io_perf_21_value,
  output  [5:0] io_perf_22_value,
  output  [5:0] io_perf_23_value,
  output  [5:0] io_perf_24_value,
  output  [5:0] io_perf_25_value,
  output  [5:0] io_perf_26_value,
  output  [5:0] io_perf_27_value,
  output  [5:0] io_perf_28_value,
  output  [5:0] io_perf_29_value,
  output  [5:0] io_perf_30_value,
  output  [5:0] io_perf_31_value,
  output  [5:0] io_perf_32_value,
  output  [5:0] io_perf_33_value,
  output  [5:0] io_perf_34_value,
  output  [5:0] io_perf_35_value,
  output  [5:0] io_perf_36_value,
  output  [5:0] io_perf_37_value,
  output  [5:0] io_perf_38_value,
  output  [5:0] io_perf_39_value,
  output  [5:0] io_perf_40_value,
  output  [5:0] io_perf_41_value,
  output  [5:0] io_perf_42_value,
  output  [5:0] io_perf_43_value,
  output  [5:0] io_perf_44_value,
  output  [5:0] io_perf_45_value,
  output  [5:0] io_perf_46_value,
  output  [5:0] io_perf_47_value,
  output  [5:0] io_perf_48_value,
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
  input  [10:0] io_nodeID
);
  assign auto_mmioBridge_mmio_in_a_ready = '0;
  assign auto_mmioBridge_mmio_in_d_valid = '0;
  assign auto_mmioBridge_mmio_in_d_bits_opcode = '0;
  assign auto_mmioBridge_mmio_in_d_bits_param = '0;
  assign auto_mmioBridge_mmio_in_d_bits_size = '0;
  assign auto_mmioBridge_mmio_in_d_bits_source = '0;
  assign auto_mmioBridge_mmio_in_d_bits_sink = '0;
  assign auto_mmioBridge_mmio_in_d_bits_denied = '0;
  assign auto_mmioBridge_mmio_in_d_bits_data = '0;
  assign auto_mmioBridge_mmio_in_d_bits_corrupt = '0;
  assign auto_in_3_a_ready = '0;
  assign auto_in_3_b_valid = '0;
  assign auto_in_3_b_bits_opcode = '0;
  assign auto_in_3_b_bits_param = '0;
  assign auto_in_3_b_bits_address = '0;
  assign auto_in_3_b_bits_data = '0;
  assign auto_in_3_c_ready = '0;
  assign auto_in_3_d_valid = '0;
  assign auto_in_3_d_bits_opcode = '0;
  assign auto_in_3_d_bits_param = '0;
  assign auto_in_3_d_bits_source = '0;
  assign auto_in_3_d_bits_sink = '0;
  assign auto_in_3_d_bits_denied = '0;
  assign auto_in_3_d_bits_echo_isKeyword = '0;
  assign auto_in_3_d_bits_data = '0;
  assign auto_in_3_d_bits_corrupt = '0;
  assign auto_in_2_a_ready = '0;
  assign auto_in_2_b_valid = '0;
  assign auto_in_2_b_bits_opcode = '0;
  assign auto_in_2_b_bits_param = '0;
  assign auto_in_2_b_bits_address = '0;
  assign auto_in_2_b_bits_data = '0;
  assign auto_in_2_c_ready = '0;
  assign auto_in_2_d_valid = '0;
  assign auto_in_2_d_bits_opcode = '0;
  assign auto_in_2_d_bits_param = '0;
  assign auto_in_2_d_bits_source = '0;
  assign auto_in_2_d_bits_sink = '0;
  assign auto_in_2_d_bits_denied = '0;
  assign auto_in_2_d_bits_echo_isKeyword = '0;
  assign auto_in_2_d_bits_data = '0;
  assign auto_in_2_d_bits_corrupt = '0;
  assign auto_in_1_a_ready = '0;
  assign auto_in_1_b_valid = '0;
  assign auto_in_1_b_bits_opcode = '0;
  assign auto_in_1_b_bits_param = '0;
  assign auto_in_1_b_bits_address = '0;
  assign auto_in_1_b_bits_data = '0;
  assign auto_in_1_c_ready = '0;
  assign auto_in_1_d_valid = '0;
  assign auto_in_1_d_bits_opcode = '0;
  assign auto_in_1_d_bits_param = '0;
  assign auto_in_1_d_bits_source = '0;
  assign auto_in_1_d_bits_sink = '0;
  assign auto_in_1_d_bits_denied = '0;
  assign auto_in_1_d_bits_echo_isKeyword = '0;
  assign auto_in_1_d_bits_data = '0;
  assign auto_in_1_d_bits_corrupt = '0;
  assign auto_in_0_a_ready = '0;
  assign auto_in_0_b_valid = '0;
  assign auto_in_0_b_bits_opcode = '0;
  assign auto_in_0_b_bits_param = '0;
  assign auto_in_0_b_bits_address = '0;
  assign auto_in_0_b_bits_data = '0;
  assign auto_in_0_c_ready = '0;
  assign auto_in_0_d_valid = '0;
  assign auto_in_0_d_bits_opcode = '0;
  assign auto_in_0_d_bits_param = '0;
  assign auto_in_0_d_bits_source = '0;
  assign auto_in_0_d_bits_sink = '0;
  assign auto_in_0_d_bits_denied = '0;
  assign auto_in_0_d_bits_echo_isKeyword = '0;
  assign auto_in_0_d_bits_data = '0;
  assign auto_in_0_d_bits_corrupt = '0;
  assign io_l2_hint_valid = '0;
  assign io_l2_hint_bits_sourceId = '0;
  assign io_l2_hint_bits_isKeyword = '0;
  assign io_l2_tlb_req_req_valid = '0;
  assign io_l2_tlb_req_req_bits_vaddr = '0;
  assign io_l2_tlb_req_req_bits_cmd = '0;
  assign io_l2_tlb_req_req_bits_kill = '0;
  assign io_l2_tlb_req_req_bits_no_translate = '0;
  assign io_debugTopDown_l2MissMatch = '0;
  assign io_l2Miss = '0;
  assign io_error_valid = '0;
  assign io_error_address = '0;
  assign io_perf_1_value = '0;
  assign io_perf_2_value = '0;
  assign io_perf_3_value = '0;
  assign io_perf_4_value = '0;
  assign io_perf_5_value = '0;
  assign io_perf_6_value = '0;
  assign io_perf_7_value = '0;
  assign io_perf_8_value = '0;
  assign io_perf_9_value = '0;
  assign io_perf_10_value = '0;
  assign io_perf_11_value = '0;
  assign io_perf_12_value = '0;
  assign io_perf_13_value = '0;
  assign io_perf_14_value = '0;
  assign io_perf_15_value = '0;
  assign io_perf_16_value = '0;
  assign io_perf_17_value = '0;
  assign io_perf_18_value = '0;
  assign io_perf_19_value = '0;
  assign io_perf_20_value = '0;
  assign io_perf_21_value = '0;
  assign io_perf_22_value = '0;
  assign io_perf_23_value = '0;
  assign io_perf_24_value = '0;
  assign io_perf_25_value = '0;
  assign io_perf_26_value = '0;
  assign io_perf_27_value = '0;
  assign io_perf_28_value = '0;
  assign io_perf_29_value = '0;
  assign io_perf_30_value = '0;
  assign io_perf_31_value = '0;
  assign io_perf_32_value = '0;
  assign io_perf_33_value = '0;
  assign io_perf_34_value = '0;
  assign io_perf_35_value = '0;
  assign io_perf_36_value = '0;
  assign io_perf_37_value = '0;
  assign io_perf_38_value = '0;
  assign io_perf_39_value = '0;
  assign io_perf_40_value = '0;
  assign io_perf_41_value = '0;
  assign io_perf_42_value = '0;
  assign io_perf_43_value = '0;
  assign io_perf_44_value = '0;
  assign io_perf_45_value = '0;
  assign io_perf_46_value = '0;
  assign io_perf_47_value = '0;
  assign io_perf_48_value = '0;
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
endmodule

module TLBuffer_13(
  input  clock,
  input  reset,
  output  auto_in_3_a_ready,
  input  auto_in_3_a_valid,
  input  [3:0] auto_in_3_a_bits_opcode,
  input  [2:0] auto_in_3_a_bits_param,
  input  [2:0] auto_in_3_a_bits_size,
  input  [6:0] auto_in_3_a_bits_source,
  input  [47:0] auto_in_3_a_bits_address,
  input  [4:0] auto_in_3_a_bits_user_reqSource,
  input  [1:0] auto_in_3_a_bits_user_alias,
  input  [43:0] auto_in_3_a_bits_user_vaddr,
  input  auto_in_3_a_bits_user_needHint,
  input  auto_in_3_a_bits_echo_isKeyword,
  input  [31:0] auto_in_3_a_bits_mask,
  input  [255:0] auto_in_3_a_bits_data,
  input  auto_in_3_a_bits_corrupt,
  input  auto_in_3_b_ready,
  output  auto_in_3_b_valid,
  output  [2:0] auto_in_3_b_bits_opcode,
  output  [1:0] auto_in_3_b_bits_param,
  output  [2:0] auto_in_3_b_bits_size,
  output  [6:0] auto_in_3_b_bits_source,
  output  [47:0] auto_in_3_b_bits_address,
  output  [31:0] auto_in_3_b_bits_mask,
  output  [255:0] auto_in_3_b_bits_data,
  output  auto_in_3_b_bits_corrupt,
  output  auto_in_3_c_ready,
  input  auto_in_3_c_valid,
  input  [2:0] auto_in_3_c_bits_opcode,
  input  [2:0] auto_in_3_c_bits_param,
  input  [2:0] auto_in_3_c_bits_size,
  input  [6:0] auto_in_3_c_bits_source,
  input  [47:0] auto_in_3_c_bits_address,
  input  [4:0] auto_in_3_c_bits_user_reqSource,
  input  [1:0] auto_in_3_c_bits_user_alias,
  input  [43:0] auto_in_3_c_bits_user_vaddr,
  input  auto_in_3_c_bits_user_needHint,
  input  auto_in_3_c_bits_echo_isKeyword,
  input  [255:0] auto_in_3_c_bits_data,
  input  auto_in_3_c_bits_corrupt,
  input  auto_in_3_d_ready,
  output  auto_in_3_d_valid,
  output  [3:0] auto_in_3_d_bits_opcode,
  output  [1:0] auto_in_3_d_bits_param,
  output  [2:0] auto_in_3_d_bits_size,
  output  [6:0] auto_in_3_d_bits_source,
  output  [7:0] auto_in_3_d_bits_sink,
  output  auto_in_3_d_bits_denied,
  output  auto_in_3_d_bits_echo_isKeyword,
  output  [255:0] auto_in_3_d_bits_data,
  output  auto_in_3_d_bits_corrupt,
  output  auto_in_3_e_ready,
  input  auto_in_3_e_valid,
  input  [7:0] auto_in_3_e_bits_sink,
  output  auto_in_2_a_ready,
  input  auto_in_2_a_valid,
  input  [3:0] auto_in_2_a_bits_opcode,
  input  [2:0] auto_in_2_a_bits_param,
  input  [2:0] auto_in_2_a_bits_size,
  input  [6:0] auto_in_2_a_bits_source,
  input  [47:0] auto_in_2_a_bits_address,
  input  [4:0] auto_in_2_a_bits_user_reqSource,
  input  [1:0] auto_in_2_a_bits_user_alias,
  input  [43:0] auto_in_2_a_bits_user_vaddr,
  input  auto_in_2_a_bits_user_needHint,
  input  auto_in_2_a_bits_echo_isKeyword,
  input  [31:0] auto_in_2_a_bits_mask,
  input  [255:0] auto_in_2_a_bits_data,
  input  auto_in_2_a_bits_corrupt,
  input  auto_in_2_b_ready,
  output  auto_in_2_b_valid,
  output  [2:0] auto_in_2_b_bits_opcode,
  output  [1:0] auto_in_2_b_bits_param,
  output  [2:0] auto_in_2_b_bits_size,
  output  [6:0] auto_in_2_b_bits_source,
  output  [47:0] auto_in_2_b_bits_address,
  output  [31:0] auto_in_2_b_bits_mask,
  output  [255:0] auto_in_2_b_bits_data,
  output  auto_in_2_b_bits_corrupt,
  output  auto_in_2_c_ready,
  input  auto_in_2_c_valid,
  input  [2:0] auto_in_2_c_bits_opcode,
  input  [2:0] auto_in_2_c_bits_param,
  input  [2:0] auto_in_2_c_bits_size,
  input  [6:0] auto_in_2_c_bits_source,
  input  [47:0] auto_in_2_c_bits_address,
  input  [4:0] auto_in_2_c_bits_user_reqSource,
  input  [1:0] auto_in_2_c_bits_user_alias,
  input  [43:0] auto_in_2_c_bits_user_vaddr,
  input  auto_in_2_c_bits_user_needHint,
  input  auto_in_2_c_bits_echo_isKeyword,
  input  [255:0] auto_in_2_c_bits_data,
  input  auto_in_2_c_bits_corrupt,
  input  auto_in_2_d_ready,
  output  auto_in_2_d_valid,
  output  [3:0] auto_in_2_d_bits_opcode,
  output  [1:0] auto_in_2_d_bits_param,
  output  [2:0] auto_in_2_d_bits_size,
  output  [6:0] auto_in_2_d_bits_source,
  output  [7:0] auto_in_2_d_bits_sink,
  output  auto_in_2_d_bits_denied,
  output  auto_in_2_d_bits_echo_isKeyword,
  output  [255:0] auto_in_2_d_bits_data,
  output  auto_in_2_d_bits_corrupt,
  output  auto_in_2_e_ready,
  input  auto_in_2_e_valid,
  input  [7:0] auto_in_2_e_bits_sink,
  output  auto_in_1_a_ready,
  input  auto_in_1_a_valid,
  input  [3:0] auto_in_1_a_bits_opcode,
  input  [2:0] auto_in_1_a_bits_param,
  input  [2:0] auto_in_1_a_bits_size,
  input  [6:0] auto_in_1_a_bits_source,
  input  [47:0] auto_in_1_a_bits_address,
  input  [4:0] auto_in_1_a_bits_user_reqSource,
  input  [1:0] auto_in_1_a_bits_user_alias,
  input  [43:0] auto_in_1_a_bits_user_vaddr,
  input  auto_in_1_a_bits_user_needHint,
  input  auto_in_1_a_bits_echo_isKeyword,
  input  [31:0] auto_in_1_a_bits_mask,
  input  [255:0] auto_in_1_a_bits_data,
  input  auto_in_1_a_bits_corrupt,
  input  auto_in_1_b_ready,
  output  auto_in_1_b_valid,
  output  [2:0] auto_in_1_b_bits_opcode,
  output  [1:0] auto_in_1_b_bits_param,
  output  [2:0] auto_in_1_b_bits_size,
  output  [6:0] auto_in_1_b_bits_source,
  output  [47:0] auto_in_1_b_bits_address,
  output  [31:0] auto_in_1_b_bits_mask,
  output  [255:0] auto_in_1_b_bits_data,
  output  auto_in_1_b_bits_corrupt,
  output  auto_in_1_c_ready,
  input  auto_in_1_c_valid,
  input  [2:0] auto_in_1_c_bits_opcode,
  input  [2:0] auto_in_1_c_bits_param,
  input  [2:0] auto_in_1_c_bits_size,
  input  [6:0] auto_in_1_c_bits_source,
  input  [47:0] auto_in_1_c_bits_address,
  input  [4:0] auto_in_1_c_bits_user_reqSource,
  input  [1:0] auto_in_1_c_bits_user_alias,
  input  [43:0] auto_in_1_c_bits_user_vaddr,
  input  auto_in_1_c_bits_user_needHint,
  input  auto_in_1_c_bits_echo_isKeyword,
  input  [255:0] auto_in_1_c_bits_data,
  input  auto_in_1_c_bits_corrupt,
  input  auto_in_1_d_ready,
  output  auto_in_1_d_valid,
  output  [3:0] auto_in_1_d_bits_opcode,
  output  [1:0] auto_in_1_d_bits_param,
  output  [2:0] auto_in_1_d_bits_size,
  output  [6:0] auto_in_1_d_bits_source,
  output  [7:0] auto_in_1_d_bits_sink,
  output  auto_in_1_d_bits_denied,
  output  auto_in_1_d_bits_echo_isKeyword,
  output  [255:0] auto_in_1_d_bits_data,
  output  auto_in_1_d_bits_corrupt,
  output  auto_in_1_e_ready,
  input  auto_in_1_e_valid,
  input  [7:0] auto_in_1_e_bits_sink,
  output  auto_in_0_a_ready,
  input  auto_in_0_a_valid,
  input  [3:0] auto_in_0_a_bits_opcode,
  input  [2:0] auto_in_0_a_bits_param,
  input  [2:0] auto_in_0_a_bits_size,
  input  [6:0] auto_in_0_a_bits_source,
  input  [47:0] auto_in_0_a_bits_address,
  input  [4:0] auto_in_0_a_bits_user_reqSource,
  input  [1:0] auto_in_0_a_bits_user_alias,
  input  [43:0] auto_in_0_a_bits_user_vaddr,
  input  auto_in_0_a_bits_user_needHint,
  input  auto_in_0_a_bits_echo_isKeyword,
  input  [31:0] auto_in_0_a_bits_mask,
  input  [255:0] auto_in_0_a_bits_data,
  input  auto_in_0_a_bits_corrupt,
  input  auto_in_0_b_ready,
  output  auto_in_0_b_valid,
  output  [2:0] auto_in_0_b_bits_opcode,
  output  [1:0] auto_in_0_b_bits_param,
  output  [2:0] auto_in_0_b_bits_size,
  output  [6:0] auto_in_0_b_bits_source,
  output  [47:0] auto_in_0_b_bits_address,
  output  [31:0] auto_in_0_b_bits_mask,
  output  [255:0] auto_in_0_b_bits_data,
  output  auto_in_0_b_bits_corrupt,
  output  auto_in_0_c_ready,
  input  auto_in_0_c_valid,
  input  [2:0] auto_in_0_c_bits_opcode,
  input  [2:0] auto_in_0_c_bits_param,
  input  [2:0] auto_in_0_c_bits_size,
  input  [6:0] auto_in_0_c_bits_source,
  input  [47:0] auto_in_0_c_bits_address,
  input  [4:0] auto_in_0_c_bits_user_reqSource,
  input  [1:0] auto_in_0_c_bits_user_alias,
  input  [43:0] auto_in_0_c_bits_user_vaddr,
  input  auto_in_0_c_bits_user_needHint,
  input  auto_in_0_c_bits_echo_isKeyword,
  input  [255:0] auto_in_0_c_bits_data,
  input  auto_in_0_c_bits_corrupt,
  input  auto_in_0_d_ready,
  output  auto_in_0_d_valid,
  output  [3:0] auto_in_0_d_bits_opcode,
  output  [1:0] auto_in_0_d_bits_param,
  output  [2:0] auto_in_0_d_bits_size,
  output  [6:0] auto_in_0_d_bits_source,
  output  [7:0] auto_in_0_d_bits_sink,
  output  auto_in_0_d_bits_denied,
  output  auto_in_0_d_bits_echo_isKeyword,
  output  [255:0] auto_in_0_d_bits_data,
  output  auto_in_0_d_bits_corrupt,
  output  auto_in_0_e_ready,
  input  auto_in_0_e_valid,
  input  [7:0] auto_in_0_e_bits_sink,
  input  auto_out_3_a_ready,
  output  auto_out_3_a_valid,
  output  [3:0] auto_out_3_a_bits_opcode,
  output  [2:0] auto_out_3_a_bits_param,
  output  [2:0] auto_out_3_a_bits_size,
  output  [6:0] auto_out_3_a_bits_source,
  output  [47:0] auto_out_3_a_bits_address,
  output  [4:0] auto_out_3_a_bits_user_reqSource,
  output  [1:0] auto_out_3_a_bits_user_alias,
  output  [43:0] auto_out_3_a_bits_user_vaddr,
  output  auto_out_3_a_bits_user_needHint,
  output  auto_out_3_a_bits_echo_isKeyword,
  output  auto_out_3_a_bits_corrupt,
  output  auto_out_3_b_ready,
  input  auto_out_3_b_valid,
  input  [2:0] auto_out_3_b_bits_opcode,
  input  [1:0] auto_out_3_b_bits_param,
  input  [47:0] auto_out_3_b_bits_address,
  input  [255:0] auto_out_3_b_bits_data,
  input  auto_out_3_c_ready,
  output  auto_out_3_c_valid,
  output  [2:0] auto_out_3_c_bits_opcode,
  output  [2:0] auto_out_3_c_bits_param,
  output  [2:0] auto_out_3_c_bits_size,
  output  [6:0] auto_out_3_c_bits_source,
  output  [47:0] auto_out_3_c_bits_address,
  output  [255:0] auto_out_3_c_bits_data,
  output  auto_out_3_c_bits_corrupt,
  output  auto_out_3_d_ready,
  input  auto_out_3_d_valid,
  input  [3:0] auto_out_3_d_bits_opcode,
  input  [1:0] auto_out_3_d_bits_param,
  input  [6:0] auto_out_3_d_bits_source,
  input  [7:0] auto_out_3_d_bits_sink,
  input  auto_out_3_d_bits_denied,
  input  auto_out_3_d_bits_echo_isKeyword,
  input  [255:0] auto_out_3_d_bits_data,
  input  auto_out_3_d_bits_corrupt,
  output  auto_out_3_e_valid,
  output  [7:0] auto_out_3_e_bits_sink,
  input  auto_out_2_a_ready,
  output  auto_out_2_a_valid,
  output  [3:0] auto_out_2_a_bits_opcode,
  output  [2:0] auto_out_2_a_bits_param,
  output  [2:0] auto_out_2_a_bits_size,
  output  [6:0] auto_out_2_a_bits_source,
  output  [47:0] auto_out_2_a_bits_address,
  output  [4:0] auto_out_2_a_bits_user_reqSource,
  output  [1:0] auto_out_2_a_bits_user_alias,
  output  [43:0] auto_out_2_a_bits_user_vaddr,
  output  auto_out_2_a_bits_user_needHint,
  output  auto_out_2_a_bits_echo_isKeyword,
  output  auto_out_2_a_bits_corrupt,
  output  auto_out_2_b_ready,
  input  auto_out_2_b_valid,
  input  [2:0] auto_out_2_b_bits_opcode,
  input  [1:0] auto_out_2_b_bits_param,
  input  [47:0] auto_out_2_b_bits_address,
  input  [255:0] auto_out_2_b_bits_data,
  input  auto_out_2_c_ready,
  output  auto_out_2_c_valid,
  output  [2:0] auto_out_2_c_bits_opcode,
  output  [2:0] auto_out_2_c_bits_param,
  output  [2:0] auto_out_2_c_bits_size,
  output  [6:0] auto_out_2_c_bits_source,
  output  [47:0] auto_out_2_c_bits_address,
  output  [255:0] auto_out_2_c_bits_data,
  output  auto_out_2_c_bits_corrupt,
  output  auto_out_2_d_ready,
  input  auto_out_2_d_valid,
  input  [3:0] auto_out_2_d_bits_opcode,
  input  [1:0] auto_out_2_d_bits_param,
  input  [6:0] auto_out_2_d_bits_source,
  input  [7:0] auto_out_2_d_bits_sink,
  input  auto_out_2_d_bits_denied,
  input  auto_out_2_d_bits_echo_isKeyword,
  input  [255:0] auto_out_2_d_bits_data,
  input  auto_out_2_d_bits_corrupt,
  output  auto_out_2_e_valid,
  output  [7:0] auto_out_2_e_bits_sink,
  input  auto_out_1_a_ready,
  output  auto_out_1_a_valid,
  output  [3:0] auto_out_1_a_bits_opcode,
  output  [2:0] auto_out_1_a_bits_param,
  output  [2:0] auto_out_1_a_bits_size,
  output  [6:0] auto_out_1_a_bits_source,
  output  [47:0] auto_out_1_a_bits_address,
  output  [4:0] auto_out_1_a_bits_user_reqSource,
  output  [1:0] auto_out_1_a_bits_user_alias,
  output  [43:0] auto_out_1_a_bits_user_vaddr,
  output  auto_out_1_a_bits_user_needHint,
  output  auto_out_1_a_bits_echo_isKeyword,
  output  auto_out_1_a_bits_corrupt,
  output  auto_out_1_b_ready,
  input  auto_out_1_b_valid,
  input  [2:0] auto_out_1_b_bits_opcode,
  input  [1:0] auto_out_1_b_bits_param,
  input  [47:0] auto_out_1_b_bits_address,
  input  [255:0] auto_out_1_b_bits_data,
  input  auto_out_1_c_ready,
  output  auto_out_1_c_valid,
  output  [2:0] auto_out_1_c_bits_opcode,
  output  [2:0] auto_out_1_c_bits_param,
  output  [2:0] auto_out_1_c_bits_size,
  output  [6:0] auto_out_1_c_bits_source,
  output  [47:0] auto_out_1_c_bits_address,
  output  [255:0] auto_out_1_c_bits_data,
  output  auto_out_1_c_bits_corrupt,
  output  auto_out_1_d_ready,
  input  auto_out_1_d_valid,
  input  [3:0] auto_out_1_d_bits_opcode,
  input  [1:0] auto_out_1_d_bits_param,
  input  [6:0] auto_out_1_d_bits_source,
  input  [7:0] auto_out_1_d_bits_sink,
  input  auto_out_1_d_bits_denied,
  input  auto_out_1_d_bits_echo_isKeyword,
  input  [255:0] auto_out_1_d_bits_data,
  input  auto_out_1_d_bits_corrupt,
  output  auto_out_1_e_valid,
  output  [7:0] auto_out_1_e_bits_sink,
  input  auto_out_0_a_ready,
  output  auto_out_0_a_valid,
  output  [3:0] auto_out_0_a_bits_opcode,
  output  [2:0] auto_out_0_a_bits_param,
  output  [2:0] auto_out_0_a_bits_size,
  output  [6:0] auto_out_0_a_bits_source,
  output  [47:0] auto_out_0_a_bits_address,
  output  [4:0] auto_out_0_a_bits_user_reqSource,
  output  [1:0] auto_out_0_a_bits_user_alias,
  output  [43:0] auto_out_0_a_bits_user_vaddr,
  output  auto_out_0_a_bits_user_needHint,
  output  auto_out_0_a_bits_echo_isKeyword,
  output  auto_out_0_a_bits_corrupt,
  output  auto_out_0_b_ready,
  input  auto_out_0_b_valid,
  input  [2:0] auto_out_0_b_bits_opcode,
  input  [1:0] auto_out_0_b_bits_param,
  input  [47:0] auto_out_0_b_bits_address,
  input  [255:0] auto_out_0_b_bits_data,
  input  auto_out_0_c_ready,
  output  auto_out_0_c_valid,
  output  [2:0] auto_out_0_c_bits_opcode,
  output  [2:0] auto_out_0_c_bits_param,
  output  [2:0] auto_out_0_c_bits_size,
  output  [6:0] auto_out_0_c_bits_source,
  output  [47:0] auto_out_0_c_bits_address,
  output  [255:0] auto_out_0_c_bits_data,
  output  auto_out_0_c_bits_corrupt,
  output  auto_out_0_d_ready,
  input  auto_out_0_d_valid,
  input  [3:0] auto_out_0_d_bits_opcode,
  input  [1:0] auto_out_0_d_bits_param,
  input  [6:0] auto_out_0_d_bits_source,
  input  [7:0] auto_out_0_d_bits_sink,
  input  auto_out_0_d_bits_denied,
  input  auto_out_0_d_bits_echo_isKeyword,
  input  [255:0] auto_out_0_d_bits_data,
  input  auto_out_0_d_bits_corrupt,
  output  auto_out_0_e_valid,
  output  [7:0] auto_out_0_e_bits_sink
);
  assign auto_in_3_a_ready = '0;
  assign auto_in_3_b_valid = '0;
  assign auto_in_3_b_bits_opcode = '0;
  assign auto_in_3_b_bits_param = '0;
  assign auto_in_3_b_bits_size = '0;
  assign auto_in_3_b_bits_source = '0;
  assign auto_in_3_b_bits_address = '0;
  assign auto_in_3_b_bits_mask = '0;
  assign auto_in_3_b_bits_data = '0;
  assign auto_in_3_b_bits_corrupt = '0;
  assign auto_in_3_c_ready = '0;
  assign auto_in_3_d_valid = '0;
  assign auto_in_3_d_bits_opcode = '0;
  assign auto_in_3_d_bits_param = '0;
  assign auto_in_3_d_bits_size = '0;
  assign auto_in_3_d_bits_source = '0;
  assign auto_in_3_d_bits_sink = '0;
  assign auto_in_3_d_bits_denied = '0;
  assign auto_in_3_d_bits_echo_isKeyword = '0;
  assign auto_in_3_d_bits_data = '0;
  assign auto_in_3_d_bits_corrupt = '0;
  assign auto_in_3_e_ready = '0;
  assign auto_in_2_a_ready = '0;
  assign auto_in_2_b_valid = '0;
  assign auto_in_2_b_bits_opcode = '0;
  assign auto_in_2_b_bits_param = '0;
  assign auto_in_2_b_bits_size = '0;
  assign auto_in_2_b_bits_source = '0;
  assign auto_in_2_b_bits_address = '0;
  assign auto_in_2_b_bits_mask = '0;
  assign auto_in_2_b_bits_data = '0;
  assign auto_in_2_b_bits_corrupt = '0;
  assign auto_in_2_c_ready = '0;
  assign auto_in_2_d_valid = '0;
  assign auto_in_2_d_bits_opcode = '0;
  assign auto_in_2_d_bits_param = '0;
  assign auto_in_2_d_bits_size = '0;
  assign auto_in_2_d_bits_source = '0;
  assign auto_in_2_d_bits_sink = '0;
  assign auto_in_2_d_bits_denied = '0;
  assign auto_in_2_d_bits_echo_isKeyword = '0;
  assign auto_in_2_d_bits_data = '0;
  assign auto_in_2_d_bits_corrupt = '0;
  assign auto_in_2_e_ready = '0;
  assign auto_in_1_a_ready = '0;
  assign auto_in_1_b_valid = '0;
  assign auto_in_1_b_bits_opcode = '0;
  assign auto_in_1_b_bits_param = '0;
  assign auto_in_1_b_bits_size = '0;
  assign auto_in_1_b_bits_source = '0;
  assign auto_in_1_b_bits_address = '0;
  assign auto_in_1_b_bits_mask = '0;
  assign auto_in_1_b_bits_data = '0;
  assign auto_in_1_b_bits_corrupt = '0;
  assign auto_in_1_c_ready = '0;
  assign auto_in_1_d_valid = '0;
  assign auto_in_1_d_bits_opcode = '0;
  assign auto_in_1_d_bits_param = '0;
  assign auto_in_1_d_bits_size = '0;
  assign auto_in_1_d_bits_source = '0;
  assign auto_in_1_d_bits_sink = '0;
  assign auto_in_1_d_bits_denied = '0;
  assign auto_in_1_d_bits_echo_isKeyword = '0;
  assign auto_in_1_d_bits_data = '0;
  assign auto_in_1_d_bits_corrupt = '0;
  assign auto_in_1_e_ready = '0;
  assign auto_in_0_a_ready = '0;
  assign auto_in_0_b_valid = '0;
  assign auto_in_0_b_bits_opcode = '0;
  assign auto_in_0_b_bits_param = '0;
  assign auto_in_0_b_bits_size = '0;
  assign auto_in_0_b_bits_source = '0;
  assign auto_in_0_b_bits_address = '0;
  assign auto_in_0_b_bits_mask = '0;
  assign auto_in_0_b_bits_data = '0;
  assign auto_in_0_b_bits_corrupt = '0;
  assign auto_in_0_c_ready = '0;
  assign auto_in_0_d_valid = '0;
  assign auto_in_0_d_bits_opcode = '0;
  assign auto_in_0_d_bits_param = '0;
  assign auto_in_0_d_bits_size = '0;
  assign auto_in_0_d_bits_source = '0;
  assign auto_in_0_d_bits_sink = '0;
  assign auto_in_0_d_bits_denied = '0;
  assign auto_in_0_d_bits_echo_isKeyword = '0;
  assign auto_in_0_d_bits_data = '0;
  assign auto_in_0_d_bits_corrupt = '0;
  assign auto_in_0_e_ready = '0;
  assign auto_out_3_a_valid = '0;
  assign auto_out_3_a_bits_opcode = '0;
  assign auto_out_3_a_bits_param = '0;
  assign auto_out_3_a_bits_size = '0;
  assign auto_out_3_a_bits_source = '0;
  assign auto_out_3_a_bits_address = '0;
  assign auto_out_3_a_bits_user_reqSource = '0;
  assign auto_out_3_a_bits_user_alias = '0;
  assign auto_out_3_a_bits_user_vaddr = '0;
  assign auto_out_3_a_bits_user_needHint = '0;
  assign auto_out_3_a_bits_echo_isKeyword = '0;
  assign auto_out_3_a_bits_corrupt = '0;
  assign auto_out_3_b_ready = '0;
  assign auto_out_3_c_valid = '0;
  assign auto_out_3_c_bits_opcode = '0;
  assign auto_out_3_c_bits_param = '0;
  assign auto_out_3_c_bits_size = '0;
  assign auto_out_3_c_bits_source = '0;
  assign auto_out_3_c_bits_address = '0;
  assign auto_out_3_c_bits_data = '0;
  assign auto_out_3_c_bits_corrupt = '0;
  assign auto_out_3_d_ready = '0;
  assign auto_out_3_e_valid = '0;
  assign auto_out_3_e_bits_sink = '0;
  assign auto_out_2_a_valid = '0;
  assign auto_out_2_a_bits_opcode = '0;
  assign auto_out_2_a_bits_param = '0;
  assign auto_out_2_a_bits_size = '0;
  assign auto_out_2_a_bits_source = '0;
  assign auto_out_2_a_bits_address = '0;
  assign auto_out_2_a_bits_user_reqSource = '0;
  assign auto_out_2_a_bits_user_alias = '0;
  assign auto_out_2_a_bits_user_vaddr = '0;
  assign auto_out_2_a_bits_user_needHint = '0;
  assign auto_out_2_a_bits_echo_isKeyword = '0;
  assign auto_out_2_a_bits_corrupt = '0;
  assign auto_out_2_b_ready = '0;
  assign auto_out_2_c_valid = '0;
  assign auto_out_2_c_bits_opcode = '0;
  assign auto_out_2_c_bits_param = '0;
  assign auto_out_2_c_bits_size = '0;
  assign auto_out_2_c_bits_source = '0;
  assign auto_out_2_c_bits_address = '0;
  assign auto_out_2_c_bits_data = '0;
  assign auto_out_2_c_bits_corrupt = '0;
  assign auto_out_2_d_ready = '0;
  assign auto_out_2_e_valid = '0;
  assign auto_out_2_e_bits_sink = '0;
  assign auto_out_1_a_valid = '0;
  assign auto_out_1_a_bits_opcode = '0;
  assign auto_out_1_a_bits_param = '0;
  assign auto_out_1_a_bits_size = '0;
  assign auto_out_1_a_bits_source = '0;
  assign auto_out_1_a_bits_address = '0;
  assign auto_out_1_a_bits_user_reqSource = '0;
  assign auto_out_1_a_bits_user_alias = '0;
  assign auto_out_1_a_bits_user_vaddr = '0;
  assign auto_out_1_a_bits_user_needHint = '0;
  assign auto_out_1_a_bits_echo_isKeyword = '0;
  assign auto_out_1_a_bits_corrupt = '0;
  assign auto_out_1_b_ready = '0;
  assign auto_out_1_c_valid = '0;
  assign auto_out_1_c_bits_opcode = '0;
  assign auto_out_1_c_bits_param = '0;
  assign auto_out_1_c_bits_size = '0;
  assign auto_out_1_c_bits_source = '0;
  assign auto_out_1_c_bits_address = '0;
  assign auto_out_1_c_bits_data = '0;
  assign auto_out_1_c_bits_corrupt = '0;
  assign auto_out_1_d_ready = '0;
  assign auto_out_1_e_valid = '0;
  assign auto_out_1_e_bits_sink = '0;
  assign auto_out_0_a_valid = '0;
  assign auto_out_0_a_bits_opcode = '0;
  assign auto_out_0_a_bits_param = '0;
  assign auto_out_0_a_bits_size = '0;
  assign auto_out_0_a_bits_source = '0;
  assign auto_out_0_a_bits_address = '0;
  assign auto_out_0_a_bits_user_reqSource = '0;
  assign auto_out_0_a_bits_user_alias = '0;
  assign auto_out_0_a_bits_user_vaddr = '0;
  assign auto_out_0_a_bits_user_needHint = '0;
  assign auto_out_0_a_bits_echo_isKeyword = '0;
  assign auto_out_0_a_bits_corrupt = '0;
  assign auto_out_0_b_ready = '0;
  assign auto_out_0_c_valid = '0;
  assign auto_out_0_c_bits_opcode = '0;
  assign auto_out_0_c_bits_param = '0;
  assign auto_out_0_c_bits_size = '0;
  assign auto_out_0_c_bits_source = '0;
  assign auto_out_0_c_bits_address = '0;
  assign auto_out_0_c_bits_data = '0;
  assign auto_out_0_c_bits_corrupt = '0;
  assign auto_out_0_d_ready = '0;
  assign auto_out_0_e_valid = '0;
  assign auto_out_0_e_bits_sink = '0;
endmodule

module TLBuffer_15(
  input  clock,
  input  reset,
  output  auto_in_a_ready,
  input  auto_in_a_valid,
  input  [3:0] auto_in_a_bits_opcode,
  input  [2:0] auto_in_a_bits_param,
  input  [1:0] auto_in_a_bits_size,
  input  auto_in_a_bits_source,
  input  [47:0] auto_in_a_bits_address,
  input  [7:0] auto_in_a_bits_mask,
  input  [63:0] auto_in_a_bits_data,
  input  auto_in_a_bits_corrupt,
  input  auto_in_d_ready,
  output  auto_in_d_valid,
  output  [3:0] auto_in_d_bits_opcode,
  output  [1:0] auto_in_d_bits_param,
  output  [1:0] auto_in_d_bits_size,
  output  auto_in_d_bits_source,
  output  auto_in_d_bits_sink,
  output  auto_in_d_bits_denied,
  output  [63:0] auto_in_d_bits_data,
  output  auto_in_d_bits_corrupt,
  input  auto_out_a_ready,
  output  auto_out_a_valid,
  output  [3:0] auto_out_a_bits_opcode,
  output  [2:0] auto_out_a_bits_param,
  output  [1:0] auto_out_a_bits_size,
  output  auto_out_a_bits_source,
  output  [47:0] auto_out_a_bits_address,
  output  [7:0] auto_out_a_bits_mask,
  output  [63:0] auto_out_a_bits_data,
  output  auto_out_a_bits_corrupt,
  output  auto_out_d_ready,
  input  auto_out_d_valid,
  input  [3:0] auto_out_d_bits_opcode,
  input  [1:0] auto_out_d_bits_param,
  input  [1:0] auto_out_d_bits_size,
  input  auto_out_d_bits_source,
  input  auto_out_d_bits_sink,
  input  auto_out_d_bits_denied,
  input  [63:0] auto_out_d_bits_data,
  input  auto_out_d_bits_corrupt
);
  assign auto_in_a_ready = '0;
  assign auto_in_d_valid = '0;
  assign auto_in_d_bits_opcode = '0;
  assign auto_in_d_bits_param = '0;
  assign auto_in_d_bits_size = '0;
  assign auto_in_d_bits_source = '0;
  assign auto_in_d_bits_sink = '0;
  assign auto_in_d_bits_denied = '0;
  assign auto_in_d_bits_data = '0;
  assign auto_in_d_bits_corrupt = '0;
  assign auto_out_a_valid = '0;
  assign auto_out_a_bits_opcode = '0;
  assign auto_out_a_bits_param = '0;
  assign auto_out_a_bits_size = '0;
  assign auto_out_a_bits_source = '0;
  assign auto_out_a_bits_address = '0;
  assign auto_out_a_bits_mask = '0;
  assign auto_out_a_bits_data = '0;
  assign auto_out_a_bits_corrupt = '0;
  assign auto_out_d_ready = '0;
endmodule

module TLBuffer_20(
  input  clock,
  input  reset,
  output  auto_in_a_ready,
  input  auto_in_a_valid,
  input  [3:0] auto_in_a_bits_opcode,
  input  [2:0] auto_in_a_bits_param,
  input  [1:0] auto_in_a_bits_size,
  input  [2:0] auto_in_a_bits_source,
  input  [29:0] auto_in_a_bits_address,
  input  [7:0] auto_in_a_bits_mask,
  input  [63:0] auto_in_a_bits_data,
  input  auto_in_a_bits_corrupt,
  input  auto_in_d_ready,
  output  auto_in_d_valid,
  output  [3:0] auto_in_d_bits_opcode,
  output  [1:0] auto_in_d_bits_param,
  output  [1:0] auto_in_d_bits_size,
  output  [2:0] auto_in_d_bits_source,
  output  auto_in_d_bits_sink,
  output  auto_in_d_bits_denied,
  output  [63:0] auto_in_d_bits_data,
  output  auto_in_d_bits_corrupt,
  input  auto_out_a_ready,
  output  auto_out_a_valid,
  output  [3:0] auto_out_a_bits_opcode,
  output  [2:0] auto_out_a_bits_param,
  output  [1:0] auto_out_a_bits_size,
  output  [2:0] auto_out_a_bits_source,
  output  [29:0] auto_out_a_bits_address,
  output  [7:0] auto_out_a_bits_mask,
  output  [63:0] auto_out_a_bits_data,
  output  auto_out_a_bits_corrupt,
  output  auto_out_d_ready,
  input  auto_out_d_valid,
  input  [3:0] auto_out_d_bits_opcode,
  input  [1:0] auto_out_d_bits_param,
  input  [1:0] auto_out_d_bits_size,
  input  [2:0] auto_out_d_bits_source,
  input  auto_out_d_bits_sink,
  input  auto_out_d_bits_denied,
  input  [63:0] auto_out_d_bits_data,
  input  auto_out_d_bits_corrupt
);
  assign auto_in_a_ready = '0;
  assign auto_in_d_valid = '0;
  assign auto_in_d_bits_opcode = '0;
  assign auto_in_d_bits_param = '0;
  assign auto_in_d_bits_size = '0;
  assign auto_in_d_bits_source = '0;
  assign auto_in_d_bits_sink = '0;
  assign auto_in_d_bits_denied = '0;
  assign auto_in_d_bits_data = '0;
  assign auto_in_d_bits_corrupt = '0;
  assign auto_out_a_valid = '0;
  assign auto_out_a_bits_opcode = '0;
  assign auto_out_a_bits_param = '0;
  assign auto_out_a_bits_size = '0;
  assign auto_out_a_bits_source = '0;
  assign auto_out_a_bits_address = '0;
  assign auto_out_a_bits_mask = '0;
  assign auto_out_a_bits_data = '0;
  assign auto_out_a_bits_corrupt = '0;
  assign auto_out_d_ready = '0;
endmodule

module TLBuffer_22(
  input  clock,
  input  reset,
  output  auto_in_a_ready,
  input  auto_in_a_valid,
  input  [3:0] auto_in_a_bits_opcode,
  input  [2:0] auto_in_a_bits_param,
  input  [1:0] auto_in_a_bits_size,
  input  [2:0] auto_in_a_bits_source,
  input  [47:0] auto_in_a_bits_address,
  input  auto_in_a_bits_user_memBackType_MM,
  input  auto_in_a_bits_user_memPageType_NC,
  input  [7:0] auto_in_a_bits_mask,
  input  [63:0] auto_in_a_bits_data,
  input  auto_in_a_bits_corrupt,
  input  auto_in_d_ready,
  output  auto_in_d_valid,
  output  [3:0] auto_in_d_bits_opcode,
  output  [1:0] auto_in_d_bits_param,
  output  [1:0] auto_in_d_bits_size,
  output  [2:0] auto_in_d_bits_source,
  output  auto_in_d_bits_sink,
  output  auto_in_d_bits_denied,
  output  [63:0] auto_in_d_bits_data,
  output  auto_in_d_bits_corrupt,
  input  auto_out_a_ready,
  output  auto_out_a_valid,
  output  [3:0] auto_out_a_bits_opcode,
  output  [2:0] auto_out_a_bits_param,
  output  [1:0] auto_out_a_bits_size,
  output  [2:0] auto_out_a_bits_source,
  output  [47:0] auto_out_a_bits_address,
  output  auto_out_a_bits_user_memBackType_MM,
  output  auto_out_a_bits_user_memPageType_NC,
  output  [7:0] auto_out_a_bits_mask,
  output  [63:0] auto_out_a_bits_data,
  output  auto_out_a_bits_corrupt,
  output  auto_out_d_ready,
  input  auto_out_d_valid,
  input  [3:0] auto_out_d_bits_opcode,
  input  [1:0] auto_out_d_bits_param,
  input  [1:0] auto_out_d_bits_size,
  input  [2:0] auto_out_d_bits_source,
  input  auto_out_d_bits_sink,
  input  auto_out_d_bits_denied,
  input  [63:0] auto_out_d_bits_data,
  input  auto_out_d_bits_corrupt
);
  assign auto_in_a_ready = '0;
  assign auto_in_d_valid = '0;
  assign auto_in_d_bits_opcode = '0;
  assign auto_in_d_bits_param = '0;
  assign auto_in_d_bits_size = '0;
  assign auto_in_d_bits_source = '0;
  assign auto_in_d_bits_sink = '0;
  assign auto_in_d_bits_denied = '0;
  assign auto_in_d_bits_data = '0;
  assign auto_in_d_bits_corrupt = '0;
  assign auto_out_a_valid = '0;
  assign auto_out_a_bits_opcode = '0;
  assign auto_out_a_bits_param = '0;
  assign auto_out_a_bits_size = '0;
  assign auto_out_a_bits_source = '0;
  assign auto_out_a_bits_address = '0;
  assign auto_out_a_bits_user_memBackType_MM = '0;
  assign auto_out_a_bits_user_memPageType_NC = '0;
  assign auto_out_a_bits_mask = '0;
  assign auto_out_a_bits_data = '0;
  assign auto_out_a_bits_corrupt = '0;
  assign auto_out_d_ready = '0;
endmodule

module TLBuffer_6(
  input  clock,
  input  reset,
  output  auto_in_a_ready,
  input  auto_in_a_valid,
  input  [3:0] auto_in_a_bits_opcode,
  input  [2:0] auto_in_a_bits_param,
  input  [2:0] auto_in_a_bits_size,
  input  [2:0] auto_in_a_bits_source,
  input  [47:0] auto_in_a_bits_address,
  input  [4:0] auto_in_a_bits_user_reqSource,
  input  [31:0] auto_in_a_bits_mask,
  input  [255:0] auto_in_a_bits_data,
  input  auto_in_a_bits_corrupt,
  input  auto_in_d_ready,
  output  auto_in_d_valid,
  output  [3:0] auto_in_d_bits_opcode,
  output  [1:0] auto_in_d_bits_param,
  output  [2:0] auto_in_d_bits_size,
  output  [2:0] auto_in_d_bits_source,
  output  [9:0] auto_in_d_bits_sink,
  output  auto_in_d_bits_denied,
  output  [255:0] auto_in_d_bits_data,
  output  auto_in_d_bits_corrupt,
  input  auto_out_a_ready,
  output  auto_out_a_valid,
  output  [3:0] auto_out_a_bits_opcode,
  output  [2:0] auto_out_a_bits_param,
  output  [2:0] auto_out_a_bits_size,
  output  [2:0] auto_out_a_bits_source,
  output  [47:0] auto_out_a_bits_address,
  output  [4:0] auto_out_a_bits_user_reqSource,
  output  [31:0] auto_out_a_bits_mask,
  output  [255:0] auto_out_a_bits_data,
  output  auto_out_a_bits_corrupt,
  output  auto_out_d_ready,
  input  auto_out_d_valid,
  input  [3:0] auto_out_d_bits_opcode,
  input  [1:0] auto_out_d_bits_param,
  input  [2:0] auto_out_d_bits_size,
  input  [2:0] auto_out_d_bits_source,
  input  [9:0] auto_out_d_bits_sink,
  input  auto_out_d_bits_denied,
  input  [255:0] auto_out_d_bits_data,
  input  auto_out_d_bits_corrupt
);
  assign auto_in_a_ready = '0;
  assign auto_in_d_valid = '0;
  assign auto_in_d_bits_opcode = '0;
  assign auto_in_d_bits_param = '0;
  assign auto_in_d_bits_size = '0;
  assign auto_in_d_bits_source = '0;
  assign auto_in_d_bits_sink = '0;
  assign auto_in_d_bits_denied = '0;
  assign auto_in_d_bits_data = '0;
  assign auto_in_d_bits_corrupt = '0;
  assign auto_out_a_valid = '0;
  assign auto_out_a_bits_opcode = '0;
  assign auto_out_a_bits_param = '0;
  assign auto_out_a_bits_size = '0;
  assign auto_out_a_bits_source = '0;
  assign auto_out_a_bits_address = '0;
  assign auto_out_a_bits_user_reqSource = '0;
  assign auto_out_a_bits_mask = '0;
  assign auto_out_a_bits_data = '0;
  assign auto_out_a_bits_corrupt = '0;
  assign auto_out_d_ready = '0;
endmodule

module TLBuffer_8(
  input  clock,
  input  reset,
  output  auto_in_a_ready,
  input  auto_in_a_valid,
  input  [3:0] auto_in_a_bits_opcode,
  input  [2:0] auto_in_a_bits_param,
  input  [1:0] auto_in_a_bits_size,
  input  [1:0] auto_in_a_bits_source,
  input  [47:0] auto_in_a_bits_address,
  input  auto_in_a_bits_user_memPageType_NC,
  input  auto_in_a_bits_user_memBackType_MM,
  input  [7:0] auto_in_a_bits_mask,
  input  [63:0] auto_in_a_bits_data,
  input  auto_in_a_bits_corrupt,
  input  auto_in_d_ready,
  output  auto_in_d_valid,
  output  [3:0] auto_in_d_bits_opcode,
  output  [1:0] auto_in_d_bits_param,
  output  [1:0] auto_in_d_bits_size,
  output  [1:0] auto_in_d_bits_source,
  output  auto_in_d_bits_sink,
  output  auto_in_d_bits_denied,
  output  [63:0] auto_in_d_bits_data,
  output  auto_in_d_bits_corrupt,
  input  auto_out_a_ready,
  output  auto_out_a_valid,
  output  [3:0] auto_out_a_bits_opcode,
  output  [2:0] auto_out_a_bits_param,
  output  [1:0] auto_out_a_bits_size,
  output  [1:0] auto_out_a_bits_source,
  output  [47:0] auto_out_a_bits_address,
  output  auto_out_a_bits_user_memPageType_NC,
  output  auto_out_a_bits_user_memBackType_MM,
  output  [7:0] auto_out_a_bits_mask,
  output  [63:0] auto_out_a_bits_data,
  output  auto_out_a_bits_corrupt,
  output  auto_out_d_ready,
  input  auto_out_d_valid,
  input  [3:0] auto_out_d_bits_opcode,
  input  [1:0] auto_out_d_bits_param,
  input  [1:0] auto_out_d_bits_size,
  input  [1:0] auto_out_d_bits_source,
  input  auto_out_d_bits_sink,
  input  auto_out_d_bits_denied,
  input  [63:0] auto_out_d_bits_data,
  input  auto_out_d_bits_corrupt
);
  assign auto_in_a_ready = '0;
  assign auto_in_d_valid = '0;
  assign auto_in_d_bits_opcode = '0;
  assign auto_in_d_bits_param = '0;
  assign auto_in_d_bits_size = '0;
  assign auto_in_d_bits_source = '0;
  assign auto_in_d_bits_sink = '0;
  assign auto_in_d_bits_denied = '0;
  assign auto_in_d_bits_data = '0;
  assign auto_in_d_bits_corrupt = '0;
  assign auto_out_a_valid = '0;
  assign auto_out_a_bits_opcode = '0;
  assign auto_out_a_bits_param = '0;
  assign auto_out_a_bits_size = '0;
  assign auto_out_a_bits_source = '0;
  assign auto_out_a_bits_address = '0;
  assign auto_out_a_bits_user_memPageType_NC = '0;
  assign auto_out_a_bits_user_memBackType_MM = '0;
  assign auto_out_a_bits_mask = '0;
  assign auto_out_a_bits_data = '0;
  assign auto_out_a_bits_corrupt = '0;
  assign auto_out_d_ready = '0;
endmodule

module TLLogger(
  output  auto_in_a_ready,
  input  auto_in_a_valid,
  input  [3:0] auto_in_a_bits_opcode,
  input  [2:0] auto_in_a_bits_param,
  input  [2:0] auto_in_a_bits_size,
  input  [5:0] auto_in_a_bits_source,
  input  [47:0] auto_in_a_bits_address,
  input  [1:0] auto_in_a_bits_user_alias,
  input  [43:0] auto_in_a_bits_user_vaddr,
  input  [4:0] auto_in_a_bits_user_reqSource,
  input  auto_in_a_bits_user_needHint,
  input  auto_in_a_bits_echo_isKeyword,
  input  [31:0] auto_in_a_bits_mask,
  input  [255:0] auto_in_a_bits_data,
  input  auto_in_a_bits_corrupt,
  input  auto_in_b_ready,
  output  auto_in_b_valid,
  output  [2:0] auto_in_b_bits_opcode,
  output  [1:0] auto_in_b_bits_param,
  output  [2:0] auto_in_b_bits_size,
  output  [5:0] auto_in_b_bits_source,
  output  [47:0] auto_in_b_bits_address,
  output  [31:0] auto_in_b_bits_mask,
  output  [255:0] auto_in_b_bits_data,
  output  auto_in_b_bits_corrupt,
  output  auto_in_c_ready,
  input  auto_in_c_valid,
  input  [2:0] auto_in_c_bits_opcode,
  input  [2:0] auto_in_c_bits_param,
  input  [2:0] auto_in_c_bits_size,
  input  [5:0] auto_in_c_bits_source,
  input  [47:0] auto_in_c_bits_address,
  input  [1:0] auto_in_c_bits_user_alias,
  input  [43:0] auto_in_c_bits_user_vaddr,
  input  [4:0] auto_in_c_bits_user_reqSource,
  input  auto_in_c_bits_user_needHint,
  input  auto_in_c_bits_echo_isKeyword,
  input  [255:0] auto_in_c_bits_data,
  input  auto_in_c_bits_corrupt,
  input  auto_in_d_ready,
  output  auto_in_d_valid,
  output  [3:0] auto_in_d_bits_opcode,
  output  [1:0] auto_in_d_bits_param,
  output  [2:0] auto_in_d_bits_size,
  output  [5:0] auto_in_d_bits_source,
  output  [9:0] auto_in_d_bits_sink,
  output  auto_in_d_bits_denied,
  output  auto_in_d_bits_echo_isKeyword,
  output  [255:0] auto_in_d_bits_data,
  output  auto_in_d_bits_corrupt,
  output  auto_in_e_ready,
  input  auto_in_e_valid,
  input  [9:0] auto_in_e_bits_sink,
  input  auto_out_a_ready,
  output  auto_out_a_valid,
  output  [3:0] auto_out_a_bits_opcode,
  output  [2:0] auto_out_a_bits_param,
  output  [2:0] auto_out_a_bits_size,
  output  [5:0] auto_out_a_bits_source,
  output  [47:0] auto_out_a_bits_address,
  output  [1:0] auto_out_a_bits_user_alias,
  output  [43:0] auto_out_a_bits_user_vaddr,
  output  [4:0] auto_out_a_bits_user_reqSource,
  output  auto_out_a_bits_user_needHint,
  output  auto_out_a_bits_echo_isKeyword,
  output  [31:0] auto_out_a_bits_mask,
  output  [255:0] auto_out_a_bits_data,
  output  auto_out_a_bits_corrupt,
  output  auto_out_b_ready,
  input  auto_out_b_valid,
  input  [2:0] auto_out_b_bits_opcode,
  input  [1:0] auto_out_b_bits_param,
  input  [2:0] auto_out_b_bits_size,
  input  [5:0] auto_out_b_bits_source,
  input  [47:0] auto_out_b_bits_address,
  input  [31:0] auto_out_b_bits_mask,
  input  [255:0] auto_out_b_bits_data,
  input  auto_out_b_bits_corrupt,
  input  auto_out_c_ready,
  output  auto_out_c_valid,
  output  [2:0] auto_out_c_bits_opcode,
  output  [2:0] auto_out_c_bits_param,
  output  [2:0] auto_out_c_bits_size,
  output  [5:0] auto_out_c_bits_source,
  output  [47:0] auto_out_c_bits_address,
  output  [1:0] auto_out_c_bits_user_alias,
  output  [43:0] auto_out_c_bits_user_vaddr,
  output  [4:0] auto_out_c_bits_user_reqSource,
  output  auto_out_c_bits_user_needHint,
  output  auto_out_c_bits_echo_isKeyword,
  output  [255:0] auto_out_c_bits_data,
  output  auto_out_c_bits_corrupt,
  output  auto_out_d_ready,
  input  auto_out_d_valid,
  input  [3:0] auto_out_d_bits_opcode,
  input  [1:0] auto_out_d_bits_param,
  input  [2:0] auto_out_d_bits_size,
  input  [5:0] auto_out_d_bits_source,
  input  [9:0] auto_out_d_bits_sink,
  input  auto_out_d_bits_denied,
  input  auto_out_d_bits_echo_isKeyword,
  input  [255:0] auto_out_d_bits_data,
  input  auto_out_d_bits_corrupt,
  input  auto_out_e_ready,
  output  auto_out_e_valid,
  output  [9:0] auto_out_e_bits_sink
);
  assign auto_in_a_ready = '0;
  assign auto_in_b_valid = '0;
  assign auto_in_b_bits_opcode = '0;
  assign auto_in_b_bits_param = '0;
  assign auto_in_b_bits_size = '0;
  assign auto_in_b_bits_source = '0;
  assign auto_in_b_bits_address = '0;
  assign auto_in_b_bits_mask = '0;
  assign auto_in_b_bits_data = '0;
  assign auto_in_b_bits_corrupt = '0;
  assign auto_in_c_ready = '0;
  assign auto_in_d_valid = '0;
  assign auto_in_d_bits_opcode = '0;
  assign auto_in_d_bits_param = '0;
  assign auto_in_d_bits_size = '0;
  assign auto_in_d_bits_source = '0;
  assign auto_in_d_bits_sink = '0;
  assign auto_in_d_bits_denied = '0;
  assign auto_in_d_bits_echo_isKeyword = '0;
  assign auto_in_d_bits_data = '0;
  assign auto_in_d_bits_corrupt = '0;
  assign auto_in_e_ready = '0;
  assign auto_out_a_valid = '0;
  assign auto_out_a_bits_opcode = '0;
  assign auto_out_a_bits_param = '0;
  assign auto_out_a_bits_size = '0;
  assign auto_out_a_bits_source = '0;
  assign auto_out_a_bits_address = '0;
  assign auto_out_a_bits_user_alias = '0;
  assign auto_out_a_bits_user_vaddr = '0;
  assign auto_out_a_bits_user_reqSource = '0;
  assign auto_out_a_bits_user_needHint = '0;
  assign auto_out_a_bits_echo_isKeyword = '0;
  assign auto_out_a_bits_mask = '0;
  assign auto_out_a_bits_data = '0;
  assign auto_out_a_bits_corrupt = '0;
  assign auto_out_b_ready = '0;
  assign auto_out_c_valid = '0;
  assign auto_out_c_bits_opcode = '0;
  assign auto_out_c_bits_param = '0;
  assign auto_out_c_bits_size = '0;
  assign auto_out_c_bits_source = '0;
  assign auto_out_c_bits_address = '0;
  assign auto_out_c_bits_user_alias = '0;
  assign auto_out_c_bits_user_vaddr = '0;
  assign auto_out_c_bits_user_reqSource = '0;
  assign auto_out_c_bits_user_needHint = '0;
  assign auto_out_c_bits_echo_isKeyword = '0;
  assign auto_out_c_bits_data = '0;
  assign auto_out_c_bits_corrupt = '0;
  assign auto_out_d_ready = '0;
  assign auto_out_e_valid = '0;
  assign auto_out_e_bits_sink = '0;
endmodule

module TLLogger_1(
  output  auto_in_a_ready,
  input  auto_in_a_valid,
  input  [3:0] auto_in_a_bits_opcode,
  input  [2:0] auto_in_a_bits_param,
  input  [2:0] auto_in_a_bits_size,
  input  [3:0] auto_in_a_bits_source,
  input  [47:0] auto_in_a_bits_address,
  input  [1:0] auto_in_a_bits_user_alias,
  input  [4:0] auto_in_a_bits_user_reqSource,
  input  auto_in_a_bits_user_needHint,
  input  [31:0] auto_in_a_bits_mask,
  input  [255:0] auto_in_a_bits_data,
  input  auto_in_a_bits_corrupt,
  input  auto_in_d_ready,
  output  auto_in_d_valid,
  output  [3:0] auto_in_d_bits_opcode,
  output  [1:0] auto_in_d_bits_param,
  output  [2:0] auto_in_d_bits_size,
  output  [3:0] auto_in_d_bits_source,
  output  [9:0] auto_in_d_bits_sink,
  output  auto_in_d_bits_denied,
  output  [255:0] auto_in_d_bits_data,
  output  auto_in_d_bits_corrupt,
  input  auto_out_a_ready,
  output  auto_out_a_valid,
  output  [3:0] auto_out_a_bits_opcode,
  output  [2:0] auto_out_a_bits_param,
  output  [2:0] auto_out_a_bits_size,
  output  [3:0] auto_out_a_bits_source,
  output  [47:0] auto_out_a_bits_address,
  output  [1:0] auto_out_a_bits_user_alias,
  output  [4:0] auto_out_a_bits_user_reqSource,
  output  auto_out_a_bits_user_needHint,
  output  [31:0] auto_out_a_bits_mask,
  output  [255:0] auto_out_a_bits_data,
  output  auto_out_a_bits_corrupt,
  output  auto_out_d_ready,
  input  auto_out_d_valid,
  input  [3:0] auto_out_d_bits_opcode,
  input  [1:0] auto_out_d_bits_param,
  input  [2:0] auto_out_d_bits_size,
  input  [3:0] auto_out_d_bits_source,
  input  [9:0] auto_out_d_bits_sink,
  input  auto_out_d_bits_denied,
  input  [255:0] auto_out_d_bits_data,
  input  auto_out_d_bits_corrupt
);
  assign auto_in_a_ready = '0;
  assign auto_in_d_valid = '0;
  assign auto_in_d_bits_opcode = '0;
  assign auto_in_d_bits_param = '0;
  assign auto_in_d_bits_size = '0;
  assign auto_in_d_bits_source = '0;
  assign auto_in_d_bits_sink = '0;
  assign auto_in_d_bits_denied = '0;
  assign auto_in_d_bits_data = '0;
  assign auto_in_d_bits_corrupt = '0;
  assign auto_out_a_valid = '0;
  assign auto_out_a_bits_opcode = '0;
  assign auto_out_a_bits_param = '0;
  assign auto_out_a_bits_size = '0;
  assign auto_out_a_bits_source = '0;
  assign auto_out_a_bits_address = '0;
  assign auto_out_a_bits_user_alias = '0;
  assign auto_out_a_bits_user_reqSource = '0;
  assign auto_out_a_bits_user_needHint = '0;
  assign auto_out_a_bits_mask = '0;
  assign auto_out_a_bits_data = '0;
  assign auto_out_a_bits_corrupt = '0;
  assign auto_out_d_ready = '0;
endmodule

module TLLogger_2(
  output  auto_in_a_ready,
  input  auto_in_a_valid,
  input  [3:0] auto_in_a_bits_opcode,
  input  [2:0] auto_in_a_bits_param,
  input  [2:0] auto_in_a_bits_size,
  input  [2:0] auto_in_a_bits_source,
  input  [47:0] auto_in_a_bits_address,
  input  [4:0] auto_in_a_bits_user_reqSource,
  input  [31:0] auto_in_a_bits_mask,
  input  [255:0] auto_in_a_bits_data,
  input  auto_in_a_bits_corrupt,
  input  auto_in_d_ready,
  output  auto_in_d_valid,
  output  [3:0] auto_in_d_bits_opcode,
  output  [1:0] auto_in_d_bits_param,
  output  [2:0] auto_in_d_bits_size,
  output  [2:0] auto_in_d_bits_source,
  output  [9:0] auto_in_d_bits_sink,
  output  auto_in_d_bits_denied,
  output  [255:0] auto_in_d_bits_data,
  output  auto_in_d_bits_corrupt,
  input  auto_out_a_ready,
  output  auto_out_a_valid,
  output  [3:0] auto_out_a_bits_opcode,
  output  [2:0] auto_out_a_bits_param,
  output  [2:0] auto_out_a_bits_size,
  output  [2:0] auto_out_a_bits_source,
  output  [47:0] auto_out_a_bits_address,
  output  [4:0] auto_out_a_bits_user_reqSource,
  output  [31:0] auto_out_a_bits_mask,
  output  [255:0] auto_out_a_bits_data,
  output  auto_out_a_bits_corrupt,
  output  auto_out_d_ready,
  input  auto_out_d_valid,
  input  [3:0] auto_out_d_bits_opcode,
  input  [1:0] auto_out_d_bits_param,
  input  [2:0] auto_out_d_bits_size,
  input  [2:0] auto_out_d_bits_source,
  input  [9:0] auto_out_d_bits_sink,
  input  auto_out_d_bits_denied,
  input  [255:0] auto_out_d_bits_data,
  input  auto_out_d_bits_corrupt
);
  assign auto_in_a_ready = '0;
  assign auto_in_d_valid = '0;
  assign auto_in_d_bits_opcode = '0;
  assign auto_in_d_bits_param = '0;
  assign auto_in_d_bits_size = '0;
  assign auto_in_d_bits_source = '0;
  assign auto_in_d_bits_sink = '0;
  assign auto_in_d_bits_denied = '0;
  assign auto_in_d_bits_data = '0;
  assign auto_in_d_bits_corrupt = '0;
  assign auto_out_a_valid = '0;
  assign auto_out_a_bits_opcode = '0;
  assign auto_out_a_bits_param = '0;
  assign auto_out_a_bits_size = '0;
  assign auto_out_a_bits_source = '0;
  assign auto_out_a_bits_address = '0;
  assign auto_out_a_bits_user_reqSource = '0;
  assign auto_out_a_bits_mask = '0;
  assign auto_out_a_bits_data = '0;
  assign auto_out_a_bits_corrupt = '0;
  assign auto_out_d_ready = '0;
endmodule

module TLXbar_5(
  input  clock,
  input  reset,
  output  auto_in_2_a_ready,
  input  auto_in_2_a_valid,
  input  [3:0] auto_in_2_a_bits_opcode,
  input  [2:0] auto_in_2_a_bits_param,
  input  [2:0] auto_in_2_a_bits_size,
  input  [2:0] auto_in_2_a_bits_source,
  input  [47:0] auto_in_2_a_bits_address,
  input  [4:0] auto_in_2_a_bits_user_reqSource,
  input  [31:0] auto_in_2_a_bits_mask,
  input  [255:0] auto_in_2_a_bits_data,
  input  auto_in_2_a_bits_corrupt,
  input  auto_in_2_d_ready,
  output  auto_in_2_d_valid,
  output  [3:0] auto_in_2_d_bits_opcode,
  output  [1:0] auto_in_2_d_bits_param,
  output  [2:0] auto_in_2_d_bits_size,
  output  [2:0] auto_in_2_d_bits_source,
  output  [9:0] auto_in_2_d_bits_sink,
  output  auto_in_2_d_bits_denied,
  output  [255:0] auto_in_2_d_bits_data,
  output  auto_in_2_d_bits_corrupt,
  output  auto_in_1_a_ready,
  input  auto_in_1_a_valid,
  input  [3:0] auto_in_1_a_bits_opcode,
  input  [2:0] auto_in_1_a_bits_param,
  input  [2:0] auto_in_1_a_bits_size,
  input  [3:0] auto_in_1_a_bits_source,
  input  [47:0] auto_in_1_a_bits_address,
  input  [1:0] auto_in_1_a_bits_user_alias,
  input  [4:0] auto_in_1_a_bits_user_reqSource,
  input  auto_in_1_a_bits_user_needHint,
  input  [31:0] auto_in_1_a_bits_mask,
  input  [255:0] auto_in_1_a_bits_data,
  input  auto_in_1_a_bits_corrupt,
  input  auto_in_1_d_ready,
  output  auto_in_1_d_valid,
  output  [3:0] auto_in_1_d_bits_opcode,
  output  [1:0] auto_in_1_d_bits_param,
  output  [2:0] auto_in_1_d_bits_size,
  output  [3:0] auto_in_1_d_bits_source,
  output  [9:0] auto_in_1_d_bits_sink,
  output  auto_in_1_d_bits_denied,
  output  [255:0] auto_in_1_d_bits_data,
  output  auto_in_1_d_bits_corrupt,
  output  auto_in_0_a_ready,
  input  auto_in_0_a_valid,
  input  [3:0] auto_in_0_a_bits_opcode,
  input  [2:0] auto_in_0_a_bits_param,
  input  [2:0] auto_in_0_a_bits_size,
  input  [5:0] auto_in_0_a_bits_source,
  input  [47:0] auto_in_0_a_bits_address,
  input  [1:0] auto_in_0_a_bits_user_alias,
  input  [43:0] auto_in_0_a_bits_user_vaddr,
  input  [4:0] auto_in_0_a_bits_user_reqSource,
  input  auto_in_0_a_bits_user_needHint,
  input  auto_in_0_a_bits_echo_isKeyword,
  input  [31:0] auto_in_0_a_bits_mask,
  input  [255:0] auto_in_0_a_bits_data,
  input  auto_in_0_a_bits_corrupt,
  input  auto_in_0_b_ready,
  output  auto_in_0_b_valid,
  output  [2:0] auto_in_0_b_bits_opcode,
  output  [1:0] auto_in_0_b_bits_param,
  output  [2:0] auto_in_0_b_bits_size,
  output  [5:0] auto_in_0_b_bits_source,
  output  [47:0] auto_in_0_b_bits_address,
  output  [31:0] auto_in_0_b_bits_mask,
  output  [255:0] auto_in_0_b_bits_data,
  output  auto_in_0_b_bits_corrupt,
  output  auto_in_0_c_ready,
  input  auto_in_0_c_valid,
  input  [2:0] auto_in_0_c_bits_opcode,
  input  [2:0] auto_in_0_c_bits_param,
  input  [2:0] auto_in_0_c_bits_size,
  input  [5:0] auto_in_0_c_bits_source,
  input  [47:0] auto_in_0_c_bits_address,
  input  [1:0] auto_in_0_c_bits_user_alias,
  input  [43:0] auto_in_0_c_bits_user_vaddr,
  input  [4:0] auto_in_0_c_bits_user_reqSource,
  input  auto_in_0_c_bits_user_needHint,
  input  auto_in_0_c_bits_echo_isKeyword,
  input  [255:0] auto_in_0_c_bits_data,
  input  auto_in_0_c_bits_corrupt,
  input  auto_in_0_d_ready,
  output  auto_in_0_d_valid,
  output  [3:0] auto_in_0_d_bits_opcode,
  output  [1:0] auto_in_0_d_bits_param,
  output  [2:0] auto_in_0_d_bits_size,
  output  [5:0] auto_in_0_d_bits_source,
  output  [9:0] auto_in_0_d_bits_sink,
  output  auto_in_0_d_bits_denied,
  output  auto_in_0_d_bits_echo_isKeyword,
  output  [255:0] auto_in_0_d_bits_data,
  output  auto_in_0_d_bits_corrupt,
  output  auto_in_0_e_ready,
  input  auto_in_0_e_valid,
  input  [9:0] auto_in_0_e_bits_sink,
  input  auto_out_3_a_ready,
  output  auto_out_3_a_valid,
  output  [3:0] auto_out_3_a_bits_opcode,
  output  [2:0] auto_out_3_a_bits_param,
  output  [2:0] auto_out_3_a_bits_size,
  output  [6:0] auto_out_3_a_bits_source,
  output  [47:0] auto_out_3_a_bits_address,
  output  [4:0] auto_out_3_a_bits_user_reqSource,
  output  [1:0] auto_out_3_a_bits_user_alias,
  output  [43:0] auto_out_3_a_bits_user_vaddr,
  output  auto_out_3_a_bits_user_needHint,
  output  auto_out_3_a_bits_echo_isKeyword,
  output  [31:0] auto_out_3_a_bits_mask,
  output  [255:0] auto_out_3_a_bits_data,
  output  auto_out_3_a_bits_corrupt,
  output  auto_out_3_b_ready,
  input  auto_out_3_b_valid,
  input  [2:0] auto_out_3_b_bits_opcode,
  input  [1:0] auto_out_3_b_bits_param,
  input  [2:0] auto_out_3_b_bits_size,
  input  [6:0] auto_out_3_b_bits_source,
  input  [47:0] auto_out_3_b_bits_address,
  input  [31:0] auto_out_3_b_bits_mask,
  input  [255:0] auto_out_3_b_bits_data,
  input  auto_out_3_b_bits_corrupt,
  input  auto_out_3_c_ready,
  output  auto_out_3_c_valid,
  output  [2:0] auto_out_3_c_bits_opcode,
  output  [2:0] auto_out_3_c_bits_param,
  output  [2:0] auto_out_3_c_bits_size,
  output  [6:0] auto_out_3_c_bits_source,
  output  [47:0] auto_out_3_c_bits_address,
  output  [4:0] auto_out_3_c_bits_user_reqSource,
  output  [1:0] auto_out_3_c_bits_user_alias,
  output  [43:0] auto_out_3_c_bits_user_vaddr,
  output  auto_out_3_c_bits_user_needHint,
  output  auto_out_3_c_bits_echo_isKeyword,
  output  [255:0] auto_out_3_c_bits_data,
  output  auto_out_3_c_bits_corrupt,
  output  auto_out_3_d_ready,
  input  auto_out_3_d_valid,
  input  [3:0] auto_out_3_d_bits_opcode,
  input  [1:0] auto_out_3_d_bits_param,
  input  [2:0] auto_out_3_d_bits_size,
  input  [6:0] auto_out_3_d_bits_source,
  input  [7:0] auto_out_3_d_bits_sink,
  input  auto_out_3_d_bits_denied,
  input  auto_out_3_d_bits_echo_isKeyword,
  input  [255:0] auto_out_3_d_bits_data,
  input  auto_out_3_d_bits_corrupt,
  input  auto_out_3_e_ready,
  output  auto_out_3_e_valid,
  output  [7:0] auto_out_3_e_bits_sink,
  input  auto_out_2_a_ready,
  output  auto_out_2_a_valid,
  output  [3:0] auto_out_2_a_bits_opcode,
  output  [2:0] auto_out_2_a_bits_param,
  output  [2:0] auto_out_2_a_bits_size,
  output  [6:0] auto_out_2_a_bits_source,
  output  [47:0] auto_out_2_a_bits_address,
  output  [4:0] auto_out_2_a_bits_user_reqSource,
  output  [1:0] auto_out_2_a_bits_user_alias,
  output  [43:0] auto_out_2_a_bits_user_vaddr,
  output  auto_out_2_a_bits_user_needHint,
  output  auto_out_2_a_bits_echo_isKeyword,
  output  [31:0] auto_out_2_a_bits_mask,
  output  [255:0] auto_out_2_a_bits_data,
  output  auto_out_2_a_bits_corrupt,
  output  auto_out_2_b_ready,
  input  auto_out_2_b_valid,
  input  [2:0] auto_out_2_b_bits_opcode,
  input  [1:0] auto_out_2_b_bits_param,
  input  [2:0] auto_out_2_b_bits_size,
  input  [6:0] auto_out_2_b_bits_source,
  input  [47:0] auto_out_2_b_bits_address,
  input  [31:0] auto_out_2_b_bits_mask,
  input  [255:0] auto_out_2_b_bits_data,
  input  auto_out_2_b_bits_corrupt,
  input  auto_out_2_c_ready,
  output  auto_out_2_c_valid,
  output  [2:0] auto_out_2_c_bits_opcode,
  output  [2:0] auto_out_2_c_bits_param,
  output  [2:0] auto_out_2_c_bits_size,
  output  [6:0] auto_out_2_c_bits_source,
  output  [47:0] auto_out_2_c_bits_address,
  output  [4:0] auto_out_2_c_bits_user_reqSource,
  output  [1:0] auto_out_2_c_bits_user_alias,
  output  [43:0] auto_out_2_c_bits_user_vaddr,
  output  auto_out_2_c_bits_user_needHint,
  output  auto_out_2_c_bits_echo_isKeyword,
  output  [255:0] auto_out_2_c_bits_data,
  output  auto_out_2_c_bits_corrupt,
  output  auto_out_2_d_ready,
  input  auto_out_2_d_valid,
  input  [3:0] auto_out_2_d_bits_opcode,
  input  [1:0] auto_out_2_d_bits_param,
  input  [2:0] auto_out_2_d_bits_size,
  input  [6:0] auto_out_2_d_bits_source,
  input  [7:0] auto_out_2_d_bits_sink,
  input  auto_out_2_d_bits_denied,
  input  auto_out_2_d_bits_echo_isKeyword,
  input  [255:0] auto_out_2_d_bits_data,
  input  auto_out_2_d_bits_corrupt,
  input  auto_out_2_e_ready,
  output  auto_out_2_e_valid,
  output  [7:0] auto_out_2_e_bits_sink,
  input  auto_out_1_a_ready,
  output  auto_out_1_a_valid,
  output  [3:0] auto_out_1_a_bits_opcode,
  output  [2:0] auto_out_1_a_bits_param,
  output  [2:0] auto_out_1_a_bits_size,
  output  [6:0] auto_out_1_a_bits_source,
  output  [47:0] auto_out_1_a_bits_address,
  output  [4:0] auto_out_1_a_bits_user_reqSource,
  output  [1:0] auto_out_1_a_bits_user_alias,
  output  [43:0] auto_out_1_a_bits_user_vaddr,
  output  auto_out_1_a_bits_user_needHint,
  output  auto_out_1_a_bits_echo_isKeyword,
  output  [31:0] auto_out_1_a_bits_mask,
  output  [255:0] auto_out_1_a_bits_data,
  output  auto_out_1_a_bits_corrupt,
  output  auto_out_1_b_ready,
  input  auto_out_1_b_valid,
  input  [2:0] auto_out_1_b_bits_opcode,
  input  [1:0] auto_out_1_b_bits_param,
  input  [2:0] auto_out_1_b_bits_size,
  input  [6:0] auto_out_1_b_bits_source,
  input  [47:0] auto_out_1_b_bits_address,
  input  [31:0] auto_out_1_b_bits_mask,
  input  [255:0] auto_out_1_b_bits_data,
  input  auto_out_1_b_bits_corrupt,
  input  auto_out_1_c_ready,
  output  auto_out_1_c_valid,
  output  [2:0] auto_out_1_c_bits_opcode,
  output  [2:0] auto_out_1_c_bits_param,
  output  [2:0] auto_out_1_c_bits_size,
  output  [6:0] auto_out_1_c_bits_source,
  output  [47:0] auto_out_1_c_bits_address,
  output  [4:0] auto_out_1_c_bits_user_reqSource,
  output  [1:0] auto_out_1_c_bits_user_alias,
  output  [43:0] auto_out_1_c_bits_user_vaddr,
  output  auto_out_1_c_bits_user_needHint,
  output  auto_out_1_c_bits_echo_isKeyword,
  output  [255:0] auto_out_1_c_bits_data,
  output  auto_out_1_c_bits_corrupt,
  output  auto_out_1_d_ready,
  input  auto_out_1_d_valid,
  input  [3:0] auto_out_1_d_bits_opcode,
  input  [1:0] auto_out_1_d_bits_param,
  input  [2:0] auto_out_1_d_bits_size,
  input  [6:0] auto_out_1_d_bits_source,
  input  [7:0] auto_out_1_d_bits_sink,
  input  auto_out_1_d_bits_denied,
  input  auto_out_1_d_bits_echo_isKeyword,
  input  [255:0] auto_out_1_d_bits_data,
  input  auto_out_1_d_bits_corrupt,
  input  auto_out_1_e_ready,
  output  auto_out_1_e_valid,
  output  [7:0] auto_out_1_e_bits_sink,
  input  auto_out_0_a_ready,
  output  auto_out_0_a_valid,
  output  [3:0] auto_out_0_a_bits_opcode,
  output  [2:0] auto_out_0_a_bits_param,
  output  [2:0] auto_out_0_a_bits_size,
  output  [6:0] auto_out_0_a_bits_source,
  output  [47:0] auto_out_0_a_bits_address,
  output  [4:0] auto_out_0_a_bits_user_reqSource,
  output  [1:0] auto_out_0_a_bits_user_alias,
  output  [43:0] auto_out_0_a_bits_user_vaddr,
  output  auto_out_0_a_bits_user_needHint,
  output  auto_out_0_a_bits_echo_isKeyword,
  output  [31:0] auto_out_0_a_bits_mask,
  output  [255:0] auto_out_0_a_bits_data,
  output  auto_out_0_a_bits_corrupt,
  output  auto_out_0_b_ready,
  input  auto_out_0_b_valid,
  input  [2:0] auto_out_0_b_bits_opcode,
  input  [1:0] auto_out_0_b_bits_param,
  input  [2:0] auto_out_0_b_bits_size,
  input  [6:0] auto_out_0_b_bits_source,
  input  [47:0] auto_out_0_b_bits_address,
  input  [31:0] auto_out_0_b_bits_mask,
  input  [255:0] auto_out_0_b_bits_data,
  input  auto_out_0_b_bits_corrupt,
  input  auto_out_0_c_ready,
  output  auto_out_0_c_valid,
  output  [2:0] auto_out_0_c_bits_opcode,
  output  [2:0] auto_out_0_c_bits_param,
  output  [2:0] auto_out_0_c_bits_size,
  output  [6:0] auto_out_0_c_bits_source,
  output  [47:0] auto_out_0_c_bits_address,
  output  [4:0] auto_out_0_c_bits_user_reqSource,
  output  [1:0] auto_out_0_c_bits_user_alias,
  output  [43:0] auto_out_0_c_bits_user_vaddr,
  output  auto_out_0_c_bits_user_needHint,
  output  auto_out_0_c_bits_echo_isKeyword,
  output  [255:0] auto_out_0_c_bits_data,
  output  auto_out_0_c_bits_corrupt,
  output  auto_out_0_d_ready,
  input  auto_out_0_d_valid,
  input  [3:0] auto_out_0_d_bits_opcode,
  input  [1:0] auto_out_0_d_bits_param,
  input  [2:0] auto_out_0_d_bits_size,
  input  [6:0] auto_out_0_d_bits_source,
  input  [7:0] auto_out_0_d_bits_sink,
  input  auto_out_0_d_bits_denied,
  input  auto_out_0_d_bits_echo_isKeyword,
  input  [255:0] auto_out_0_d_bits_data,
  input  auto_out_0_d_bits_corrupt,
  input  auto_out_0_e_ready,
  output  auto_out_0_e_valid,
  output  [7:0] auto_out_0_e_bits_sink
);
  assign auto_in_2_a_ready = '0;
  assign auto_in_2_d_valid = '0;
  assign auto_in_2_d_bits_opcode = '0;
  assign auto_in_2_d_bits_param = '0;
  assign auto_in_2_d_bits_size = '0;
  assign auto_in_2_d_bits_source = '0;
  assign auto_in_2_d_bits_sink = '0;
  assign auto_in_2_d_bits_denied = '0;
  assign auto_in_2_d_bits_data = '0;
  assign auto_in_2_d_bits_corrupt = '0;
  assign auto_in_1_a_ready = '0;
  assign auto_in_1_d_valid = '0;
  assign auto_in_1_d_bits_opcode = '0;
  assign auto_in_1_d_bits_param = '0;
  assign auto_in_1_d_bits_size = '0;
  assign auto_in_1_d_bits_source = '0;
  assign auto_in_1_d_bits_sink = '0;
  assign auto_in_1_d_bits_denied = '0;
  assign auto_in_1_d_bits_data = '0;
  assign auto_in_1_d_bits_corrupt = '0;
  assign auto_in_0_a_ready = '0;
  assign auto_in_0_b_valid = '0;
  assign auto_in_0_b_bits_opcode = '0;
  assign auto_in_0_b_bits_param = '0;
  assign auto_in_0_b_bits_size = '0;
  assign auto_in_0_b_bits_source = '0;
  assign auto_in_0_b_bits_address = '0;
  assign auto_in_0_b_bits_mask = '0;
  assign auto_in_0_b_bits_data = '0;
  assign auto_in_0_b_bits_corrupt = '0;
  assign auto_in_0_c_ready = '0;
  assign auto_in_0_d_valid = '0;
  assign auto_in_0_d_bits_opcode = '0;
  assign auto_in_0_d_bits_param = '0;
  assign auto_in_0_d_bits_size = '0;
  assign auto_in_0_d_bits_source = '0;
  assign auto_in_0_d_bits_sink = '0;
  assign auto_in_0_d_bits_denied = '0;
  assign auto_in_0_d_bits_echo_isKeyword = '0;
  assign auto_in_0_d_bits_data = '0;
  assign auto_in_0_d_bits_corrupt = '0;
  assign auto_in_0_e_ready = '0;
  assign auto_out_3_a_valid = '0;
  assign auto_out_3_a_bits_opcode = '0;
  assign auto_out_3_a_bits_param = '0;
  assign auto_out_3_a_bits_size = '0;
  assign auto_out_3_a_bits_source = '0;
  assign auto_out_3_a_bits_address = '0;
  assign auto_out_3_a_bits_user_reqSource = '0;
  assign auto_out_3_a_bits_user_alias = '0;
  assign auto_out_3_a_bits_user_vaddr = '0;
  assign auto_out_3_a_bits_user_needHint = '0;
  assign auto_out_3_a_bits_echo_isKeyword = '0;
  assign auto_out_3_a_bits_mask = '0;
  assign auto_out_3_a_bits_data = '0;
  assign auto_out_3_a_bits_corrupt = '0;
  assign auto_out_3_b_ready = '0;
  assign auto_out_3_c_valid = '0;
  assign auto_out_3_c_bits_opcode = '0;
  assign auto_out_3_c_bits_param = '0;
  assign auto_out_3_c_bits_size = '0;
  assign auto_out_3_c_bits_source = '0;
  assign auto_out_3_c_bits_address = '0;
  assign auto_out_3_c_bits_user_reqSource = '0;
  assign auto_out_3_c_bits_user_alias = '0;
  assign auto_out_3_c_bits_user_vaddr = '0;
  assign auto_out_3_c_bits_user_needHint = '0;
  assign auto_out_3_c_bits_echo_isKeyword = '0;
  assign auto_out_3_c_bits_data = '0;
  assign auto_out_3_c_bits_corrupt = '0;
  assign auto_out_3_d_ready = '0;
  assign auto_out_3_e_valid = '0;
  assign auto_out_3_e_bits_sink = '0;
  assign auto_out_2_a_valid = '0;
  assign auto_out_2_a_bits_opcode = '0;
  assign auto_out_2_a_bits_param = '0;
  assign auto_out_2_a_bits_size = '0;
  assign auto_out_2_a_bits_source = '0;
  assign auto_out_2_a_bits_address = '0;
  assign auto_out_2_a_bits_user_reqSource = '0;
  assign auto_out_2_a_bits_user_alias = '0;
  assign auto_out_2_a_bits_user_vaddr = '0;
  assign auto_out_2_a_bits_user_needHint = '0;
  assign auto_out_2_a_bits_echo_isKeyword = '0;
  assign auto_out_2_a_bits_mask = '0;
  assign auto_out_2_a_bits_data = '0;
  assign auto_out_2_a_bits_corrupt = '0;
  assign auto_out_2_b_ready = '0;
  assign auto_out_2_c_valid = '0;
  assign auto_out_2_c_bits_opcode = '0;
  assign auto_out_2_c_bits_param = '0;
  assign auto_out_2_c_bits_size = '0;
  assign auto_out_2_c_bits_source = '0;
  assign auto_out_2_c_bits_address = '0;
  assign auto_out_2_c_bits_user_reqSource = '0;
  assign auto_out_2_c_bits_user_alias = '0;
  assign auto_out_2_c_bits_user_vaddr = '0;
  assign auto_out_2_c_bits_user_needHint = '0;
  assign auto_out_2_c_bits_echo_isKeyword = '0;
  assign auto_out_2_c_bits_data = '0;
  assign auto_out_2_c_bits_corrupt = '0;
  assign auto_out_2_d_ready = '0;
  assign auto_out_2_e_valid = '0;
  assign auto_out_2_e_bits_sink = '0;
  assign auto_out_1_a_valid = '0;
  assign auto_out_1_a_bits_opcode = '0;
  assign auto_out_1_a_bits_param = '0;
  assign auto_out_1_a_bits_size = '0;
  assign auto_out_1_a_bits_source = '0;
  assign auto_out_1_a_bits_address = '0;
  assign auto_out_1_a_bits_user_reqSource = '0;
  assign auto_out_1_a_bits_user_alias = '0;
  assign auto_out_1_a_bits_user_vaddr = '0;
  assign auto_out_1_a_bits_user_needHint = '0;
  assign auto_out_1_a_bits_echo_isKeyword = '0;
  assign auto_out_1_a_bits_mask = '0;
  assign auto_out_1_a_bits_data = '0;
  assign auto_out_1_a_bits_corrupt = '0;
  assign auto_out_1_b_ready = '0;
  assign auto_out_1_c_valid = '0;
  assign auto_out_1_c_bits_opcode = '0;
  assign auto_out_1_c_bits_param = '0;
  assign auto_out_1_c_bits_size = '0;
  assign auto_out_1_c_bits_source = '0;
  assign auto_out_1_c_bits_address = '0;
  assign auto_out_1_c_bits_user_reqSource = '0;
  assign auto_out_1_c_bits_user_alias = '0;
  assign auto_out_1_c_bits_user_vaddr = '0;
  assign auto_out_1_c_bits_user_needHint = '0;
  assign auto_out_1_c_bits_echo_isKeyword = '0;
  assign auto_out_1_c_bits_data = '0;
  assign auto_out_1_c_bits_corrupt = '0;
  assign auto_out_1_d_ready = '0;
  assign auto_out_1_e_valid = '0;
  assign auto_out_1_e_bits_sink = '0;
  assign auto_out_0_a_valid = '0;
  assign auto_out_0_a_bits_opcode = '0;
  assign auto_out_0_a_bits_param = '0;
  assign auto_out_0_a_bits_size = '0;
  assign auto_out_0_a_bits_source = '0;
  assign auto_out_0_a_bits_address = '0;
  assign auto_out_0_a_bits_user_reqSource = '0;
  assign auto_out_0_a_bits_user_alias = '0;
  assign auto_out_0_a_bits_user_vaddr = '0;
  assign auto_out_0_a_bits_user_needHint = '0;
  assign auto_out_0_a_bits_echo_isKeyword = '0;
  assign auto_out_0_a_bits_mask = '0;
  assign auto_out_0_a_bits_data = '0;
  assign auto_out_0_a_bits_corrupt = '0;
  assign auto_out_0_b_ready = '0;
  assign auto_out_0_c_valid = '0;
  assign auto_out_0_c_bits_opcode = '0;
  assign auto_out_0_c_bits_param = '0;
  assign auto_out_0_c_bits_size = '0;
  assign auto_out_0_c_bits_source = '0;
  assign auto_out_0_c_bits_address = '0;
  assign auto_out_0_c_bits_user_reqSource = '0;
  assign auto_out_0_c_bits_user_alias = '0;
  assign auto_out_0_c_bits_user_vaddr = '0;
  assign auto_out_0_c_bits_user_needHint = '0;
  assign auto_out_0_c_bits_echo_isKeyword = '0;
  assign auto_out_0_c_bits_data = '0;
  assign auto_out_0_c_bits_corrupt = '0;
  assign auto_out_0_d_ready = '0;
  assign auto_out_0_e_valid = '0;
  assign auto_out_0_e_bits_sink = '0;
endmodule

module TLXbar_6(
  input  clock,
  input  reset,
  output  auto_in_1_a_ready,
  input  auto_in_1_a_valid,
  input  [3:0] auto_in_1_a_bits_opcode,
  input  [2:0] auto_in_1_a_bits_param,
  input  [1:0] auto_in_1_a_bits_size,
  input  [1:0] auto_in_1_a_bits_source,
  input  [47:0] auto_in_1_a_bits_address,
  input  auto_in_1_a_bits_user_memBackType_MM,
  input  auto_in_1_a_bits_user_memPageType_NC,
  input  [7:0] auto_in_1_a_bits_mask,
  input  [63:0] auto_in_1_a_bits_data,
  input  auto_in_1_a_bits_corrupt,
  input  auto_in_1_d_ready,
  output  auto_in_1_d_valid,
  output  [3:0] auto_in_1_d_bits_opcode,
  output  [1:0] auto_in_1_d_bits_param,
  output  [1:0] auto_in_1_d_bits_size,
  output  [1:0] auto_in_1_d_bits_source,
  output  auto_in_1_d_bits_sink,
  output  auto_in_1_d_bits_denied,
  output  [63:0] auto_in_1_d_bits_data,
  output  auto_in_1_d_bits_corrupt,
  output  auto_in_0_a_ready,
  input  auto_in_0_a_valid,
  input  [3:0] auto_in_0_a_bits_opcode,
  input  [2:0] auto_in_0_a_bits_param,
  input  [1:0] auto_in_0_a_bits_size,
  input  auto_in_0_a_bits_source,
  input  [47:0] auto_in_0_a_bits_address,
  input  [7:0] auto_in_0_a_bits_mask,
  input  [63:0] auto_in_0_a_bits_data,
  input  auto_in_0_a_bits_corrupt,
  input  auto_in_0_d_ready,
  output  auto_in_0_d_valid,
  output  [3:0] auto_in_0_d_bits_opcode,
  output  [1:0] auto_in_0_d_bits_param,
  output  [1:0] auto_in_0_d_bits_size,
  output  auto_in_0_d_bits_sink,
  output  auto_in_0_d_bits_denied,
  output  [63:0] auto_in_0_d_bits_data,
  output  auto_in_0_d_bits_corrupt,
  input  auto_out_2_a_ready,
  output  auto_out_2_a_valid,
  output  [3:0] auto_out_2_a_bits_opcode,
  output  [2:0] auto_out_2_a_bits_param,
  output  [1:0] auto_out_2_a_bits_size,
  output  [2:0] auto_out_2_a_bits_source,
  output  [47:0] auto_out_2_a_bits_address,
  output  auto_out_2_a_bits_user_memBackType_MM,
  output  auto_out_2_a_bits_user_memPageType_NC,
  output  [7:0] auto_out_2_a_bits_mask,
  output  [63:0] auto_out_2_a_bits_data,
  output  auto_out_2_a_bits_corrupt,
  output  auto_out_2_d_ready,
  input  auto_out_2_d_valid,
  input  [3:0] auto_out_2_d_bits_opcode,
  input  [1:0] auto_out_2_d_bits_param,
  input  [1:0] auto_out_2_d_bits_size,
  input  [2:0] auto_out_2_d_bits_source,
  input  auto_out_2_d_bits_sink,
  input  auto_out_2_d_bits_denied,
  input  [63:0] auto_out_2_d_bits_data,
  input  auto_out_2_d_bits_corrupt,
  input  auto_out_1_a_ready,
  output  auto_out_1_a_valid,
  output  [3:0] auto_out_1_a_bits_opcode,
  output  [2:0] auto_out_1_a_bits_param,
  output  [1:0] auto_out_1_a_bits_size,
  output  [2:0] auto_out_1_a_bits_source,
  output  [29:0] auto_out_1_a_bits_address,
  output  [7:0] auto_out_1_a_bits_mask,
  output  [63:0] auto_out_1_a_bits_data,
  output  auto_out_1_a_bits_corrupt,
  output  auto_out_1_d_ready,
  input  auto_out_1_d_valid,
  input  [3:0] auto_out_1_d_bits_opcode,
  input  [1:0] auto_out_1_d_bits_param,
  input  [1:0] auto_out_1_d_bits_size,
  input  [2:0] auto_out_1_d_bits_source,
  input  auto_out_1_d_bits_sink,
  input  auto_out_1_d_bits_denied,
  input  [63:0] auto_out_1_d_bits_data,
  input  auto_out_1_d_bits_corrupt,
  input  auto_out_0_a_ready,
  output  auto_out_0_a_valid,
  output  [3:0] auto_out_0_a_bits_opcode,
  output  [2:0] auto_out_0_a_bits_param,
  output  [1:0] auto_out_0_a_bits_size,
  output  [2:0] auto_out_0_a_bits_source,
  output  [29:0] auto_out_0_a_bits_address,
  output  [7:0] auto_out_0_a_bits_mask,
  output  [63:0] auto_out_0_a_bits_data,
  output  auto_out_0_a_bits_corrupt,
  output  auto_out_0_d_ready,
  input  auto_out_0_d_valid,
  input  [3:0] auto_out_0_d_bits_opcode,
  input  [1:0] auto_out_0_d_bits_param,
  input  [1:0] auto_out_0_d_bits_size,
  input  [2:0] auto_out_0_d_bits_source,
  input  auto_out_0_d_bits_sink,
  input  auto_out_0_d_bits_denied,
  input  [63:0] auto_out_0_d_bits_data,
  input  auto_out_0_d_bits_corrupt
);
  assign auto_in_1_a_ready = '0;
  assign auto_in_1_d_valid = '0;
  assign auto_in_1_d_bits_opcode = '0;
  assign auto_in_1_d_bits_param = '0;
  assign auto_in_1_d_bits_size = '0;
  assign auto_in_1_d_bits_source = '0;
  assign auto_in_1_d_bits_sink = '0;
  assign auto_in_1_d_bits_denied = '0;
  assign auto_in_1_d_bits_data = '0;
  assign auto_in_1_d_bits_corrupt = '0;
  assign auto_in_0_a_ready = '0;
  assign auto_in_0_d_valid = '0;
  assign auto_in_0_d_bits_opcode = '0;
  assign auto_in_0_d_bits_param = '0;
  assign auto_in_0_d_bits_size = '0;
  assign auto_in_0_d_bits_sink = '0;
  assign auto_in_0_d_bits_denied = '0;
  assign auto_in_0_d_bits_data = '0;
  assign auto_in_0_d_bits_corrupt = '0;
  assign auto_out_2_a_valid = '0;
  assign auto_out_2_a_bits_opcode = '0;
  assign auto_out_2_a_bits_param = '0;
  assign auto_out_2_a_bits_size = '0;
  assign auto_out_2_a_bits_source = '0;
  assign auto_out_2_a_bits_address = '0;
  assign auto_out_2_a_bits_user_memBackType_MM = '0;
  assign auto_out_2_a_bits_user_memPageType_NC = '0;
  assign auto_out_2_a_bits_mask = '0;
  assign auto_out_2_a_bits_data = '0;
  assign auto_out_2_a_bits_corrupt = '0;
  assign auto_out_2_d_ready = '0;
  assign auto_out_1_a_valid = '0;
  assign auto_out_1_a_bits_opcode = '0;
  assign auto_out_1_a_bits_param = '0;
  assign auto_out_1_a_bits_size = '0;
  assign auto_out_1_a_bits_source = '0;
  assign auto_out_1_a_bits_address = '0;
  assign auto_out_1_a_bits_mask = '0;
  assign auto_out_1_a_bits_data = '0;
  assign auto_out_1_a_bits_corrupt = '0;
  assign auto_out_1_d_ready = '0;
  assign auto_out_0_a_valid = '0;
  assign auto_out_0_a_bits_opcode = '0;
  assign auto_out_0_a_bits_param = '0;
  assign auto_out_0_a_bits_size = '0;
  assign auto_out_0_a_bits_source = '0;
  assign auto_out_0_a_bits_address = '0;
  assign auto_out_0_a_bits_mask = '0;
  assign auto_out_0_a_bits_data = '0;
  assign auto_out_0_a_bits_corrupt = '0;
  assign auto_out_0_d_ready = '0;
endmodule

