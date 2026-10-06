// FrontendBridge 自检测试台
// 双实例使用同一组随机激励，逐拍比较全部输出端口。
// 激励覆盖三个独立通道的 valid/ready、连续传输和下游背压。
// 复位释放后运行至少 200000 拍，结束时检查握手覆盖计数。

`timescale 1ns/1ps

module tb;
  int unsigned NCYCLES = 200000;
  bit clock = 1'b0;
  logic reset;
  longint unsigned checks = 0;
  longint unsigned errors = 0;
  int unsigned cyc = 0;

  always #5 clock = ~clock;

  function automatic logic [255:0] random_bits(input int unsigned width);
    logic [255:0] value;
    value = '0;
    for (int unsigned n = 0; n < width; n += 32)
      value[n +: 32] = $urandom;
    return value;
  endfunction

  logic auto_instr_uncache_in_a_valid;
  logic [47:0] auto_instr_uncache_in_a_bits_address;
  logic auto_instr_uncache_in_a_bits_user_memPageType_NC;
  logic auto_instr_uncache_in_a_bits_user_memBackType_MM;
  logic auto_instr_uncache_out_a_ready;
  logic auto_instr_uncache_out_d_valid;
  logic [3:0] auto_instr_uncache_out_d_bits_opcode;
  logic [1:0] auto_instr_uncache_out_d_bits_param;
  logic [1:0] auto_instr_uncache_out_d_bits_size;
  logic auto_instr_uncache_out_d_bits_source;
  logic auto_instr_uncache_out_d_bits_sink;
  logic auto_instr_uncache_out_d_bits_denied;
  logic [63:0] auto_instr_uncache_out_d_bits_data;
  logic auto_instr_uncache_out_d_bits_corrupt;

  logic auto_icachectrl_in_a_valid;
  logic [3:0] auto_icachectrl_in_a_bits_opcode;
  logic [2:0] auto_icachectrl_in_a_bits_param;
  logic [1:0] auto_icachectrl_in_a_bits_size;
  logic [4:0] auto_icachectrl_in_a_bits_source;
  logic [29:0] auto_icachectrl_in_a_bits_address;
  logic [7:0] auto_icachectrl_in_a_bits_mask;
  logic [63:0] auto_icachectrl_in_a_bits_data;
  logic auto_icachectrl_in_a_bits_corrupt;
  logic auto_icachectrl_in_d_ready;
  logic auto_icachectrl_out_a_ready;
  logic auto_icachectrl_out_d_valid;
  logic [3:0] auto_icachectrl_out_d_bits_opcode;
  logic [1:0] auto_icachectrl_out_d_bits_size;
  logic [4:0] auto_icachectrl_out_d_bits_source;
  logic [63:0] auto_icachectrl_out_d_bits_data;

  logic auto_icache_in_a_valid;
  logic [3:0] auto_icache_in_a_bits_source;
  logic [47:0] auto_icache_in_a_bits_address;
  logic auto_icache_out_a_ready;
  logic auto_icache_out_d_valid;
  logic [3:0] auto_icache_out_d_bits_opcode;
  logic [1:0] auto_icache_out_d_bits_param;
  logic [2:0] auto_icache_out_d_bits_size;
  logic [3:0] auto_icache_out_d_bits_source;
  logic [9:0] auto_icache_out_d_bits_sink;
  logic auto_icache_out_d_bits_denied;
  logic [255:0] auto_icache_out_d_bits_data;
  logic auto_icache_out_d_bits_corrupt;

  wire [51:0] g_outputs;
  wire [51:0] x_outputs;

  wire auto_instr_uncache_in_a_ready_g;
  wire auto_instr_uncache_in_d_valid_g;
  wire auto_instr_uncache_in_d_bits_source_g;
  wire [63:0] auto_instr_uncache_in_d_bits_data_g;
  wire auto_instr_uncache_in_d_bits_corrupt_g;
  wire auto_instr_uncache_out_a_valid_g;
  wire [2:0] auto_instr_uncache_out_a_bits_param_g;
  wire [47:0] auto_instr_uncache_out_a_bits_address_g;
  wire auto_instr_uncache_out_a_bits_user_memPageType_NC_g;
  wire auto_instr_uncache_out_a_bits_user_memBackType_MM_g;
  wire auto_instr_uncache_out_a_bits_corrupt_g;
  wire auto_instr_uncache_out_d_ready_g;
  wire auto_icachectrl_in_a_ready_g;
  wire auto_icachectrl_in_d_valid_g;
  wire [3:0] auto_icachectrl_in_d_bits_opcode_g;
  wire [1:0] auto_icachectrl_in_d_bits_param_g;
  wire [1:0] auto_icachectrl_in_d_bits_size_g;
  wire [4:0] auto_icachectrl_in_d_bits_source_g;
  wire auto_icachectrl_in_d_bits_sink_g;
  wire auto_icachectrl_in_d_bits_denied_g;
  wire [63:0] auto_icachectrl_in_d_bits_data_g;
  wire auto_icachectrl_in_d_bits_corrupt_g;
  wire auto_icachectrl_out_a_valid_g;
  wire [3:0] auto_icachectrl_out_a_bits_opcode_g;
  wire [1:0] auto_icachectrl_out_a_bits_size_g;
  wire [4:0] auto_icachectrl_out_a_bits_source_g;
  wire [29:0] auto_icachectrl_out_a_bits_address_g;
  wire [7:0] auto_icachectrl_out_a_bits_mask_g;
  wire [63:0] auto_icachectrl_out_a_bits_data_g;
  wire auto_icachectrl_out_d_ready_g;
  wire auto_icache_in_a_ready_g;
  wire auto_icache_in_d_valid_g;
  wire [3:0] auto_icache_in_d_bits_opcode_g;
  wire [2:0] auto_icache_in_d_bits_size_g;
  wire [3:0] auto_icache_in_d_bits_source_g;
  wire [255:0] auto_icache_in_d_bits_data_g;
  wire auto_icache_in_d_bits_corrupt_g;
  wire auto_icache_out_a_valid_g;
  wire [3:0] auto_icache_out_a_bits_opcode_g;
  wire [2:0] auto_icache_out_a_bits_param_g;
  wire [2:0] auto_icache_out_a_bits_size_g;
  wire [3:0] auto_icache_out_a_bits_source_g;
  wire [47:0] auto_icache_out_a_bits_address_g;
  wire [1:0] auto_icache_out_a_bits_user_alias_g;
  wire [4:0] auto_icache_out_a_bits_user_reqSource_g;
  wire auto_icache_out_a_bits_user_needHint_g;
  wire [31:0] auto_icache_out_a_bits_mask_g;
  wire [255:0] auto_icache_out_a_bits_data_g;
  wire auto_icache_out_a_bits_corrupt_g;
  wire auto_icache_out_d_ready_g;

  wire auto_instr_uncache_in_a_ready_x;
  wire auto_instr_uncache_in_d_valid_x;
  wire auto_instr_uncache_in_d_bits_source_x;
  wire [63:0] auto_instr_uncache_in_d_bits_data_x;
  wire auto_instr_uncache_in_d_bits_corrupt_x;
  wire auto_instr_uncache_out_a_valid_x;
  wire [2:0] auto_instr_uncache_out_a_bits_param_x;
  wire [47:0] auto_instr_uncache_out_a_bits_address_x;
  wire auto_instr_uncache_out_a_bits_user_memPageType_NC_x;
  wire auto_instr_uncache_out_a_bits_user_memBackType_MM_x;
  wire auto_instr_uncache_out_a_bits_corrupt_x;
  wire auto_instr_uncache_out_d_ready_x;
  wire auto_icachectrl_in_a_ready_x;
  wire auto_icachectrl_in_d_valid_x;
  wire [3:0] auto_icachectrl_in_d_bits_opcode_x;
  wire [1:0] auto_icachectrl_in_d_bits_param_x;
  wire [1:0] auto_icachectrl_in_d_bits_size_x;
  wire [4:0] auto_icachectrl_in_d_bits_source_x;
  wire auto_icachectrl_in_d_bits_sink_x;
  wire auto_icachectrl_in_d_bits_denied_x;
  wire [63:0] auto_icachectrl_in_d_bits_data_x;
  wire auto_icachectrl_in_d_bits_corrupt_x;
  wire auto_icachectrl_out_a_valid_x;
  wire [3:0] auto_icachectrl_out_a_bits_opcode_x;
  wire [1:0] auto_icachectrl_out_a_bits_size_x;
  wire [4:0] auto_icachectrl_out_a_bits_source_x;
  wire [29:0] auto_icachectrl_out_a_bits_address_x;
  wire [7:0] auto_icachectrl_out_a_bits_mask_x;
  wire [63:0] auto_icachectrl_out_a_bits_data_x;
  wire auto_icachectrl_out_d_ready_x;
  wire auto_icache_in_a_ready_x;
  wire auto_icache_in_d_valid_x;
  wire [3:0] auto_icache_in_d_bits_opcode_x;
  wire [2:0] auto_icache_in_d_bits_size_x;
  wire [3:0] auto_icache_in_d_bits_source_x;
  wire [255:0] auto_icache_in_d_bits_data_x;
  wire auto_icache_in_d_bits_corrupt_x;
  wire auto_icache_out_a_valid_x;
  wire [3:0] auto_icache_out_a_bits_opcode_x;
  wire [2:0] auto_icache_out_a_bits_param_x;
  wire [2:0] auto_icache_out_a_bits_size_x;
  wire [3:0] auto_icache_out_a_bits_source_x;
  wire [47:0] auto_icache_out_a_bits_address_x;
  wire [1:0] auto_icache_out_a_bits_user_alias_x;
  wire [4:0] auto_icache_out_a_bits_user_reqSource_x;
  wire auto_icache_out_a_bits_user_needHint_x;
  wire [31:0] auto_icache_out_a_bits_mask_x;
  wire [255:0] auto_icache_out_a_bits_data_x;
  wire auto_icache_out_a_bits_corrupt_x;
  wire auto_icache_out_d_ready_x;

  FrontendBridge g (
    .clock(clock), .reset(reset),
    .auto_instr_uncache_in_a_ready(auto_instr_uncache_in_a_ready_g),
    .auto_instr_uncache_in_a_valid(auto_instr_uncache_in_a_valid),
    .auto_instr_uncache_in_a_bits_address(auto_instr_uncache_in_a_bits_address),
    .auto_instr_uncache_in_a_bits_user_memPageType_NC(auto_instr_uncache_in_a_bits_user_memPageType_NC),
    .auto_instr_uncache_in_a_bits_user_memBackType_MM(auto_instr_uncache_in_a_bits_user_memBackType_MM),
    .auto_instr_uncache_in_d_valid(auto_instr_uncache_in_d_valid_g),
    .auto_instr_uncache_in_d_bits_source(auto_instr_uncache_in_d_bits_source_g),
    .auto_instr_uncache_in_d_bits_data(auto_instr_uncache_in_d_bits_data_g),
    .auto_instr_uncache_in_d_bits_corrupt(auto_instr_uncache_in_d_bits_corrupt_g),
    .auto_instr_uncache_out_a_ready(auto_instr_uncache_out_a_ready),
    .auto_instr_uncache_out_a_valid(auto_instr_uncache_out_a_valid_g),
    .auto_instr_uncache_out_a_bits_param(auto_instr_uncache_out_a_bits_param_g),
    .auto_instr_uncache_out_a_bits_address(auto_instr_uncache_out_a_bits_address_g),
    .auto_instr_uncache_out_a_bits_user_memPageType_NC(auto_instr_uncache_out_a_bits_user_memPageType_NC_g),
    .auto_instr_uncache_out_a_bits_user_memBackType_MM(auto_instr_uncache_out_a_bits_user_memBackType_MM_g),
    .auto_instr_uncache_out_a_bits_corrupt(auto_instr_uncache_out_a_bits_corrupt_g),
    .auto_instr_uncache_out_d_ready(auto_instr_uncache_out_d_ready_g),
    .auto_instr_uncache_out_d_valid(auto_instr_uncache_out_d_valid),
    .auto_instr_uncache_out_d_bits_opcode(auto_instr_uncache_out_d_bits_opcode),
    .auto_instr_uncache_out_d_bits_param(auto_instr_uncache_out_d_bits_param),
    .auto_instr_uncache_out_d_bits_size(auto_instr_uncache_out_d_bits_size),
    .auto_instr_uncache_out_d_bits_source(auto_instr_uncache_out_d_bits_source),
    .auto_instr_uncache_out_d_bits_sink(auto_instr_uncache_out_d_bits_sink),
    .auto_instr_uncache_out_d_bits_denied(auto_instr_uncache_out_d_bits_denied),
    .auto_instr_uncache_out_d_bits_data(auto_instr_uncache_out_d_bits_data),
    .auto_instr_uncache_out_d_bits_corrupt(auto_instr_uncache_out_d_bits_corrupt),
    .auto_icachectrl_in_a_ready(auto_icachectrl_in_a_ready_g),
    .auto_icachectrl_in_a_valid(auto_icachectrl_in_a_valid),
    .auto_icachectrl_in_a_bits_opcode(auto_icachectrl_in_a_bits_opcode),
    .auto_icachectrl_in_a_bits_param(auto_icachectrl_in_a_bits_param),
    .auto_icachectrl_in_a_bits_size(auto_icachectrl_in_a_bits_size),
    .auto_icachectrl_in_a_bits_source(auto_icachectrl_in_a_bits_source),
    .auto_icachectrl_in_a_bits_address(auto_icachectrl_in_a_bits_address),
    .auto_icachectrl_in_a_bits_mask(auto_icachectrl_in_a_bits_mask),
    .auto_icachectrl_in_a_bits_data(auto_icachectrl_in_a_bits_data),
    .auto_icachectrl_in_a_bits_corrupt(auto_icachectrl_in_a_bits_corrupt),
    .auto_icachectrl_in_d_ready(auto_icachectrl_in_d_ready),
    .auto_icachectrl_in_d_valid(auto_icachectrl_in_d_valid_g),
    .auto_icachectrl_in_d_bits_opcode(auto_icachectrl_in_d_bits_opcode_g),
    .auto_icachectrl_in_d_bits_param(auto_icachectrl_in_d_bits_param_g),
    .auto_icachectrl_in_d_bits_size(auto_icachectrl_in_d_bits_size_g),
    .auto_icachectrl_in_d_bits_source(auto_icachectrl_in_d_bits_source_g),
    .auto_icachectrl_in_d_bits_sink(auto_icachectrl_in_d_bits_sink_g),
    .auto_icachectrl_in_d_bits_denied(auto_icachectrl_in_d_bits_denied_g),
    .auto_icachectrl_in_d_bits_data(auto_icachectrl_in_d_bits_data_g),
    .auto_icachectrl_in_d_bits_corrupt(auto_icachectrl_in_d_bits_corrupt_g),
    .auto_icachectrl_out_a_ready(auto_icachectrl_out_a_ready),
    .auto_icachectrl_out_a_valid(auto_icachectrl_out_a_valid_g),
    .auto_icachectrl_out_a_bits_opcode(auto_icachectrl_out_a_bits_opcode_g),
    .auto_icachectrl_out_a_bits_size(auto_icachectrl_out_a_bits_size_g),
    .auto_icachectrl_out_a_bits_source(auto_icachectrl_out_a_bits_source_g),
    .auto_icachectrl_out_a_bits_address(auto_icachectrl_out_a_bits_address_g),
    .auto_icachectrl_out_a_bits_mask(auto_icachectrl_out_a_bits_mask_g),
    .auto_icachectrl_out_a_bits_data(auto_icachectrl_out_a_bits_data_g),
    .auto_icachectrl_out_d_ready(auto_icachectrl_out_d_ready_g),
    .auto_icachectrl_out_d_valid(auto_icachectrl_out_d_valid),
    .auto_icachectrl_out_d_bits_opcode(auto_icachectrl_out_d_bits_opcode),
    .auto_icachectrl_out_d_bits_size(auto_icachectrl_out_d_bits_size),
    .auto_icachectrl_out_d_bits_source(auto_icachectrl_out_d_bits_source),
    .auto_icachectrl_out_d_bits_data(auto_icachectrl_out_d_bits_data),
    .auto_icache_in_a_ready(auto_icache_in_a_ready_g),
    .auto_icache_in_a_valid(auto_icache_in_a_valid),
    .auto_icache_in_a_bits_source(auto_icache_in_a_bits_source),
    .auto_icache_in_a_bits_address(auto_icache_in_a_bits_address),
    .auto_icache_in_d_valid(auto_icache_in_d_valid_g),
    .auto_icache_in_d_bits_opcode(auto_icache_in_d_bits_opcode_g),
    .auto_icache_in_d_bits_size(auto_icache_in_d_bits_size_g),
    .auto_icache_in_d_bits_source(auto_icache_in_d_bits_source_g),
    .auto_icache_in_d_bits_data(auto_icache_in_d_bits_data_g),
    .auto_icache_in_d_bits_corrupt(auto_icache_in_d_bits_corrupt_g),
    .auto_icache_out_a_ready(auto_icache_out_a_ready),
    .auto_icache_out_a_valid(auto_icache_out_a_valid_g),
    .auto_icache_out_a_bits_opcode(auto_icache_out_a_bits_opcode_g),
    .auto_icache_out_a_bits_param(auto_icache_out_a_bits_param_g),
    .auto_icache_out_a_bits_size(auto_icache_out_a_bits_size_g),
    .auto_icache_out_a_bits_source(auto_icache_out_a_bits_source_g),
    .auto_icache_out_a_bits_address(auto_icache_out_a_bits_address_g),
    .auto_icache_out_a_bits_user_alias(auto_icache_out_a_bits_user_alias_g),
    .auto_icache_out_a_bits_user_reqSource(auto_icache_out_a_bits_user_reqSource_g),
    .auto_icache_out_a_bits_user_needHint(auto_icache_out_a_bits_user_needHint_g),
    .auto_icache_out_a_bits_mask(auto_icache_out_a_bits_mask_g),
    .auto_icache_out_a_bits_data(auto_icache_out_a_bits_data_g),
    .auto_icache_out_a_bits_corrupt(auto_icache_out_a_bits_corrupt_g),
    .auto_icache_out_d_ready(auto_icache_out_d_ready_g),
    .auto_icache_out_d_valid(auto_icache_out_d_valid),
    .auto_icache_out_d_bits_opcode(auto_icache_out_d_bits_opcode),
    .auto_icache_out_d_bits_param(auto_icache_out_d_bits_param),
    .auto_icache_out_d_bits_size(auto_icache_out_d_bits_size),
    .auto_icache_out_d_bits_source(auto_icache_out_d_bits_source),
    .auto_icache_out_d_bits_sink(auto_icache_out_d_bits_sink),
    .auto_icache_out_d_bits_denied(auto_icache_out_d_bits_denied),
    .auto_icache_out_d_bits_data(auto_icache_out_d_bits_data),
    .auto_icache_out_d_bits_corrupt(auto_icache_out_d_bits_corrupt)
  );

  FrontendBridge_xs x (
    .clock(clock), .reset(reset),
    .auto_instr_uncache_in_a_ready(auto_instr_uncache_in_a_ready_x),
    .auto_instr_uncache_in_a_valid(auto_instr_uncache_in_a_valid),
    .auto_instr_uncache_in_a_bits_address(auto_instr_uncache_in_a_bits_address),
    .auto_instr_uncache_in_a_bits_user_memPageType_NC(auto_instr_uncache_in_a_bits_user_memPageType_NC),
    .auto_instr_uncache_in_a_bits_user_memBackType_MM(auto_instr_uncache_in_a_bits_user_memBackType_MM),
    .auto_instr_uncache_in_d_valid(auto_instr_uncache_in_d_valid_x),
    .auto_instr_uncache_in_d_bits_source(auto_instr_uncache_in_d_bits_source_x),
    .auto_instr_uncache_in_d_bits_data(auto_instr_uncache_in_d_bits_data_x),
    .auto_instr_uncache_in_d_bits_corrupt(auto_instr_uncache_in_d_bits_corrupt_x),
    .auto_instr_uncache_out_a_ready(auto_instr_uncache_out_a_ready),
    .auto_instr_uncache_out_a_valid(auto_instr_uncache_out_a_valid_x),
    .auto_instr_uncache_out_a_bits_param(auto_instr_uncache_out_a_bits_param_x),
    .auto_instr_uncache_out_a_bits_address(auto_instr_uncache_out_a_bits_address_x),
    .auto_instr_uncache_out_a_bits_user_memPageType_NC(auto_instr_uncache_out_a_bits_user_memPageType_NC_x),
    .auto_instr_uncache_out_a_bits_user_memBackType_MM(auto_instr_uncache_out_a_bits_user_memBackType_MM_x),
    .auto_instr_uncache_out_a_bits_corrupt(auto_instr_uncache_out_a_bits_corrupt_x),
    .auto_instr_uncache_out_d_ready(auto_instr_uncache_out_d_ready_x),
    .auto_instr_uncache_out_d_valid(auto_instr_uncache_out_d_valid),
    .auto_instr_uncache_out_d_bits_opcode(auto_instr_uncache_out_d_bits_opcode),
    .auto_instr_uncache_out_d_bits_param(auto_instr_uncache_out_d_bits_param),
    .auto_instr_uncache_out_d_bits_size(auto_instr_uncache_out_d_bits_size),
    .auto_instr_uncache_out_d_bits_source(auto_instr_uncache_out_d_bits_source),
    .auto_instr_uncache_out_d_bits_sink(auto_instr_uncache_out_d_bits_sink),
    .auto_instr_uncache_out_d_bits_denied(auto_instr_uncache_out_d_bits_denied),
    .auto_instr_uncache_out_d_bits_data(auto_instr_uncache_out_d_bits_data),
    .auto_instr_uncache_out_d_bits_corrupt(auto_instr_uncache_out_d_bits_corrupt),
    .auto_icachectrl_in_a_ready(auto_icachectrl_in_a_ready_x),
    .auto_icachectrl_in_a_valid(auto_icachectrl_in_a_valid),
    .auto_icachectrl_in_a_bits_opcode(auto_icachectrl_in_a_bits_opcode),
    .auto_icachectrl_in_a_bits_param(auto_icachectrl_in_a_bits_param),
    .auto_icachectrl_in_a_bits_size(auto_icachectrl_in_a_bits_size),
    .auto_icachectrl_in_a_bits_source(auto_icachectrl_in_a_bits_source),
    .auto_icachectrl_in_a_bits_address(auto_icachectrl_in_a_bits_address),
    .auto_icachectrl_in_a_bits_mask(auto_icachectrl_in_a_bits_mask),
    .auto_icachectrl_in_a_bits_data(auto_icachectrl_in_a_bits_data),
    .auto_icachectrl_in_a_bits_corrupt(auto_icachectrl_in_a_bits_corrupt),
    .auto_icachectrl_in_d_ready(auto_icachectrl_in_d_ready),
    .auto_icachectrl_in_d_valid(auto_icachectrl_in_d_valid_x),
    .auto_icachectrl_in_d_bits_opcode(auto_icachectrl_in_d_bits_opcode_x),
    .auto_icachectrl_in_d_bits_param(auto_icachectrl_in_d_bits_param_x),
    .auto_icachectrl_in_d_bits_size(auto_icachectrl_in_d_bits_size_x),
    .auto_icachectrl_in_d_bits_source(auto_icachectrl_in_d_bits_source_x),
    .auto_icachectrl_in_d_bits_sink(auto_icachectrl_in_d_bits_sink_x),
    .auto_icachectrl_in_d_bits_denied(auto_icachectrl_in_d_bits_denied_x),
    .auto_icachectrl_in_d_bits_data(auto_icachectrl_in_d_bits_data_x),
    .auto_icachectrl_in_d_bits_corrupt(auto_icachectrl_in_d_bits_corrupt_x),
    .auto_icachectrl_out_a_ready(auto_icachectrl_out_a_ready),
    .auto_icachectrl_out_a_valid(auto_icachectrl_out_a_valid_x),
    .auto_icachectrl_out_a_bits_opcode(auto_icachectrl_out_a_bits_opcode_x),
    .auto_icachectrl_out_a_bits_size(auto_icachectrl_out_a_bits_size_x),
    .auto_icachectrl_out_a_bits_source(auto_icachectrl_out_a_bits_source_x),
    .auto_icachectrl_out_a_bits_address(auto_icachectrl_out_a_bits_address_x),
    .auto_icachectrl_out_a_bits_mask(auto_icachectrl_out_a_bits_mask_x),
    .auto_icachectrl_out_a_bits_data(auto_icachectrl_out_a_bits_data_x),
    .auto_icachectrl_out_d_ready(auto_icachectrl_out_d_ready_x),
    .auto_icachectrl_out_d_valid(auto_icachectrl_out_d_valid),
    .auto_icachectrl_out_d_bits_opcode(auto_icachectrl_out_d_bits_opcode),
    .auto_icachectrl_out_d_bits_size(auto_icachectrl_out_d_bits_size),
    .auto_icachectrl_out_d_bits_source(auto_icachectrl_out_d_bits_source),
    .auto_icachectrl_out_d_bits_data(auto_icachectrl_out_d_bits_data),
    .auto_icache_in_a_ready(auto_icache_in_a_ready_x),
    .auto_icache_in_a_valid(auto_icache_in_a_valid),
    .auto_icache_in_a_bits_source(auto_icache_in_a_bits_source),
    .auto_icache_in_a_bits_address(auto_icache_in_a_bits_address),
    .auto_icache_in_d_valid(auto_icache_in_d_valid_x),
    .auto_icache_in_d_bits_opcode(auto_icache_in_d_bits_opcode_x),
    .auto_icache_in_d_bits_size(auto_icache_in_d_bits_size_x),
    .auto_icache_in_d_bits_source(auto_icache_in_d_bits_source_x),
    .auto_icache_in_d_bits_data(auto_icache_in_d_bits_data_x),
    .auto_icache_in_d_bits_corrupt(auto_icache_in_d_bits_corrupt_x),
    .auto_icache_out_a_ready(auto_icache_out_a_ready),
    .auto_icache_out_a_valid(auto_icache_out_a_valid_x),
    .auto_icache_out_a_bits_opcode(auto_icache_out_a_bits_opcode_x),
    .auto_icache_out_a_bits_param(auto_icache_out_a_bits_param_x),
    .auto_icache_out_a_bits_size(auto_icache_out_a_bits_size_x),
    .auto_icache_out_a_bits_source(auto_icache_out_a_bits_source_x),
    .auto_icache_out_a_bits_address(auto_icache_out_a_bits_address_x),
    .auto_icache_out_a_bits_user_alias(auto_icache_out_a_bits_user_alias_x),
    .auto_icache_out_a_bits_user_reqSource(auto_icache_out_a_bits_user_reqSource_x),
    .auto_icache_out_a_bits_user_needHint(auto_icache_out_a_bits_user_needHint_x),
    .auto_icache_out_a_bits_mask(auto_icache_out_a_bits_mask_x),
    .auto_icache_out_a_bits_data(auto_icache_out_a_bits_data_x),
    .auto_icache_out_a_bits_corrupt(auto_icache_out_a_bits_corrupt_x),
    .auto_icache_out_d_ready(auto_icache_out_d_ready_x),
    .auto_icache_out_d_valid(auto_icache_out_d_valid),
    .auto_icache_out_d_bits_opcode(auto_icache_out_d_bits_opcode),
    .auto_icache_out_d_bits_param(auto_icache_out_d_bits_param),
    .auto_icache_out_d_bits_size(auto_icache_out_d_bits_size),
    .auto_icache_out_d_bits_source(auto_icache_out_d_bits_source),
    .auto_icache_out_d_bits_sink(auto_icache_out_d_bits_sink),
    .auto_icache_out_d_bits_denied(auto_icache_out_d_bits_denied),
    .auto_icache_out_d_bits_data(auto_icache_out_d_bits_data),
    .auto_icache_out_d_bits_corrupt(auto_icache_out_d_bits_corrupt)
  );

  assign g_outputs = {
    auto_instr_uncache_in_a_ready_g,
    auto_instr_uncache_in_d_valid_g,
    auto_instr_uncache_in_d_bits_source_g,
    auto_instr_uncache_in_d_bits_data_g,
    auto_instr_uncache_in_d_bits_corrupt_g,
    auto_instr_uncache_out_a_valid_g,
    auto_instr_uncache_out_a_bits_param_g,
    auto_instr_uncache_out_a_bits_address_g,
    auto_instr_uncache_out_a_bits_user_memPageType_NC_g,
    auto_instr_uncache_out_a_bits_user_memBackType_MM_g,
    auto_instr_uncache_out_a_bits_corrupt_g,
    auto_instr_uncache_out_d_ready_g,
    auto_icachectrl_in_a_ready_g,
    auto_icachectrl_in_d_valid_g,
    auto_icachectrl_in_d_bits_opcode_g,
    auto_icachectrl_in_d_bits_param_g,
    auto_icachectrl_in_d_bits_size_g,
    auto_icachectrl_in_d_bits_source_g,
    auto_icachectrl_in_d_bits_sink_g,
    auto_icachectrl_in_d_bits_denied_g,
    auto_icachectrl_in_d_bits_data_g,
    auto_icachectrl_in_d_bits_corrupt_g,
    auto_icachectrl_out_a_valid_g,
    auto_icachectrl_out_a_bits_opcode_g,
    auto_icachectrl_out_a_bits_size_g,
    auto_icachectrl_out_a_bits_source_g,
    auto_icachectrl_out_a_bits_address_g,
    auto_icachectrl_out_a_bits_mask_g,
    auto_icachectrl_out_a_bits_data_g,
    auto_icachectrl_out_d_ready_g,
    auto_icache_in_a_ready_g,
    auto_icache_in_d_valid_g,
    auto_icache_in_d_bits_opcode_g,
    auto_icache_in_d_bits_size_g,
    auto_icache_in_d_bits_source_g,
    auto_icache_in_d_bits_data_g,
    auto_icache_in_d_bits_corrupt_g,
    auto_icache_out_a_valid_g,
    auto_icache_out_a_bits_opcode_g,
    auto_icache_out_a_bits_param_g,
    auto_icache_out_a_bits_size_g,
    auto_icache_out_a_bits_source_g,
    auto_icache_out_a_bits_address_g,
    auto_icache_out_a_bits_user_alias_g,
    auto_icache_out_a_bits_user_reqSource_g,
    auto_icache_out_a_bits_user_needHint_g,
    auto_icache_out_a_bits_mask_g,
    auto_icache_out_a_bits_data_g,
    auto_icache_out_a_bits_corrupt_g,
    auto_icache_out_d_ready_g
  };

  assign x_outputs = {
    auto_instr_uncache_in_a_ready_x,
    auto_instr_uncache_in_d_valid_x,
    auto_instr_uncache_in_d_bits_source_x,
    auto_instr_uncache_in_d_bits_data_x,
    auto_instr_uncache_in_d_bits_corrupt_x,
    auto_instr_uncache_out_a_valid_x,
    auto_instr_uncache_out_a_bits_param_x,
    auto_instr_uncache_out_a_bits_address_x,
    auto_instr_uncache_out_a_bits_user_memPageType_NC_x,
    auto_instr_uncache_out_a_bits_user_memBackType_MM_x,
    auto_instr_uncache_out_a_bits_corrupt_x,
    auto_instr_uncache_out_d_ready_x,
    auto_icachectrl_in_a_ready_x,
    auto_icachectrl_in_d_valid_x,
    auto_icachectrl_in_d_bits_opcode_x,
    auto_icachectrl_in_d_bits_param_x,
    auto_icachectrl_in_d_bits_size_x,
    auto_icachectrl_in_d_bits_source_x,
    auto_icachectrl_in_d_bits_sink_x,
    auto_icachectrl_in_d_bits_denied_x,
    auto_icachectrl_in_d_bits_data_x,
    auto_icachectrl_in_d_bits_corrupt_x,
    auto_icachectrl_out_a_valid_x,
    auto_icachectrl_out_a_bits_opcode_x,
    auto_icachectrl_out_a_bits_size_x,
    auto_icachectrl_out_a_bits_source_x,
    auto_icachectrl_out_a_bits_address_x,
    auto_icachectrl_out_a_bits_mask_x,
    auto_icachectrl_out_a_bits_data_x,
    auto_icachectrl_out_d_ready_x,
    auto_icache_in_a_ready_x,
    auto_icache_in_d_valid_x,
    auto_icache_in_d_bits_opcode_x,
    auto_icache_in_d_bits_size_x,
    auto_icache_in_d_bits_source_x,
    auto_icache_in_d_bits_data_x,
    auto_icache_in_d_bits_corrupt_x,
    auto_icache_out_a_valid_x,
    auto_icache_out_a_bits_opcode_x,
    auto_icache_out_a_bits_param_x,
    auto_icache_out_a_bits_size_x,
    auto_icache_out_a_bits_source_x,
    auto_icache_out_a_bits_address_x,
    auto_icache_out_a_bits_user_alias_x,
    auto_icache_out_a_bits_user_reqSource_x,
    auto_icache_out_a_bits_user_needHint_x,
    auto_icache_out_a_bits_mask_x,
    auto_icache_out_a_bits_data_x,
    auto_icache_out_a_bits_corrupt_x,
    auto_icache_out_d_ready_x
  };

  task automatic drive_inputs;
    begin
      auto_instr_uncache_in_a_valid = $urandom;
      auto_instr_uncache_in_a_bits_address = random_bits(48);
      auto_instr_uncache_in_a_bits_user_memPageType_NC = $urandom;
      auto_instr_uncache_in_a_bits_user_memBackType_MM = $urandom;
      auto_instr_uncache_out_a_ready = (cyc[10:0] < 11'd256) ? 1'b0 : $urandom;
      auto_instr_uncache_out_d_valid = $urandom;
      auto_instr_uncache_out_d_bits_opcode = random_bits(4);
      auto_instr_uncache_out_d_bits_param = random_bits(2);
      auto_instr_uncache_out_d_bits_size = random_bits(2);
      auto_instr_uncache_out_d_bits_source = $urandom;
      auto_instr_uncache_out_d_bits_sink = $urandom;
      auto_instr_uncache_out_d_bits_denied = $urandom;
      auto_instr_uncache_out_d_bits_data = random_bits(64);
      auto_instr_uncache_out_d_bits_corrupt = $urandom;

      auto_icachectrl_in_a_valid = $urandom;
      auto_icachectrl_in_a_bits_opcode = random_bits(4);
      auto_icachectrl_in_a_bits_param = random_bits(3);
      auto_icachectrl_in_a_bits_size = random_bits(2);
      auto_icachectrl_in_a_bits_source = random_bits(5);
      auto_icachectrl_in_a_bits_address = random_bits(30);
      auto_icachectrl_in_a_bits_mask = random_bits(8);
      auto_icachectrl_in_a_bits_data = random_bits(64);
      auto_icachectrl_in_a_bits_corrupt = $urandom;
      auto_icachectrl_in_d_ready = $urandom;
      auto_icachectrl_out_a_ready = (cyc[10:0] < 11'd256) ? 1'b0 : $urandom;
      auto_icachectrl_out_d_valid = $urandom;
      auto_icachectrl_out_d_bits_opcode = random_bits(4);
      auto_icachectrl_out_d_bits_size = random_bits(2);
      auto_icachectrl_out_d_bits_source = random_bits(5);
      auto_icachectrl_out_d_bits_data = random_bits(64);

      auto_icache_in_a_valid = $urandom;
      auto_icache_in_a_bits_source = random_bits(4);
      auto_icache_in_a_bits_address = random_bits(48);
      auto_icache_out_a_ready = (cyc[10:0] < 11'd256) ? 1'b0 : $urandom;
      auto_icache_out_d_valid = $urandom;
      auto_icache_out_d_bits_opcode = random_bits(4);
      auto_icache_out_d_bits_param = random_bits(2);
      auto_icache_out_d_bits_size = random_bits(3);
      auto_icache_out_d_bits_source = random_bits(4);
      auto_icache_out_d_bits_sink = random_bits(10);
      auto_icache_out_d_bits_denied = $urandom;
      auto_icache_out_d_bits_data = random_bits(256);
      auto_icache_out_d_bits_corrupt = $urandom;
    end
  endtask

  longint unsigned cov_icache_a = 0;
  longint unsigned cov_icache_d = 0;
  longint unsigned cov_icachectrl_a = 0;
  longint unsigned cov_icachectrl_d = 0;
  longint unsigned cov_uncache_a = 0;
  longint unsigned cov_uncache_d = 0;
  longint unsigned cov_backpressure = 0;

  always @(negedge clock) begin
    if (!reset) begin
      checks++;
      if (g_outputs !== x_outputs) begin
        errors++;
        if (errors < 20)
          $display("[cyc %0d] FrontendBridge output mismatch", cyc);
      end
    end
  end

  initial begin
    void'($value$plusargs("ncycles=%d", NCYCLES));
    reset = 1'b1;
    drive_inputs();

    repeat (5) @(posedge clock);
    @(negedge clock);
    reset = 1'b0;

    for (cyc = 0; cyc < NCYCLES; cyc++) begin
      @(negedge clock);
      drive_inputs();

      if (auto_icache_in_a_valid && auto_icache_in_a_ready_g)
        cov_icache_a++;
      if (auto_icache_out_d_valid && auto_icache_out_d_ready_g)
        cov_icache_d++;
      if (auto_icachectrl_in_a_valid && auto_icachectrl_in_a_ready_g)
        cov_icachectrl_a++;
      if (auto_icachectrl_out_d_valid && auto_icachectrl_out_d_ready_g)
        cov_icachectrl_d++;
      if (auto_instr_uncache_in_a_valid && auto_instr_uncache_in_a_ready_g)
        cov_uncache_a++;
      if (auto_instr_uncache_out_d_valid && auto_instr_uncache_out_d_ready_g)
        cov_uncache_d++;
      if (!auto_icache_out_a_ready ||
          !auto_icachectrl_out_a_ready ||
          !auto_instr_uncache_out_a_ready)
        cov_backpressure++;
    end

    $display("checks=%0d errors=%0d", checks, errors);
    $display("coverage: icache_a=%0d icache_d=%0d icachectrl_a=%0d icachectrl_d=%0d uncache_a=%0d uncache_d=%0d backpressure=%0d",
             cov_icache_a, cov_icache_d, cov_icachectrl_a, cov_icachectrl_d,
             cov_uncache_a, cov_uncache_d, cov_backpressure);

    if (errors == 0 &&
        cov_icache_a > 0 && cov_icache_d > 0 &&
        cov_icachectrl_a > 0 && cov_icachectrl_d > 0 &&
        cov_uncache_a > 0 && cov_uncache_d > 0 &&
        cov_backpressure > 0)
      $display("TEST PASSED");
    else
      $display("TEST FAILED");
    $finish;
  end
endmodule
