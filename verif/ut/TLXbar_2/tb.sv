// 自动生成：scripts/gen_tlxbar2.py —— 勿手改
// TLXbar_2 双例化逐拍比对: golden TLXbar_2 vs 可读 TLXbar_2_xs。
// 激励: A 通道地址 1/2 概率清掉 bit26 (偏置进 out0/2/3/4 子树), 覆盖 5 条路由;
// D 通道 5 个从口 valid/载荷随机 (覆盖 5 路 round-robin 仲裁的争用)。
`timescale 1ns/1ps
`define CHECK(SIG) begin \
  if (!$isunknown(g_``SIG)) begin \
    checks++; \
    if (g_``SIG !== i_``SIG) begin \
      errors++; \
      if (errors <= 30) $display("[%0t] MISMATCH %s g=%0h i=%0h", $time, `"SIG`", g_``SIG, i_``SIG); \
    end \
  end \
end
module tb;
  int unsigned NCYCLES = 200000;
  bit clock = 0;
  bit reset;
  int errors = 0;
  int checks = 0;
  always #5 clock = ~clock;

  logic auto_in_a_valid;
  logic [3:0] auto_in_a_bits_opcode;
  logic [2:0] auto_in_a_bits_param;
  logic [1:0] auto_in_a_bits_size;
  logic [14:0] auto_in_a_bits_source;
  logic [29:0] auto_in_a_bits_address;
  logic [7:0] auto_in_a_bits_mask;
  logic [63:0] auto_in_a_bits_data;
  logic auto_in_a_bits_corrupt;
  logic auto_in_d_ready;
  logic auto_out_4_a_ready;
  logic auto_out_4_d_valid;
  logic [3:0] auto_out_4_d_bits_opcode;
  logic [1:0] auto_out_4_d_bits_param;
  logic [1:0] auto_out_4_d_bits_size;
  logic [14:0] auto_out_4_d_bits_source;
  logic auto_out_4_d_bits_sink;
  logic auto_out_4_d_bits_denied;
  logic [63:0] auto_out_4_d_bits_data;
  logic auto_out_4_d_bits_corrupt;
  logic auto_out_3_a_ready;
  logic auto_out_3_d_valid;
  logic [3:0] auto_out_3_d_bits_opcode;
  logic [1:0] auto_out_3_d_bits_size;
  logic [14:0] auto_out_3_d_bits_source;
  logic [63:0] auto_out_3_d_bits_data;
  logic auto_out_2_a_ready;
  logic auto_out_2_d_valid;
  logic [3:0] auto_out_2_d_bits_opcode;
  logic [1:0] auto_out_2_d_bits_size;
  logic [14:0] auto_out_2_d_bits_source;
  logic [63:0] auto_out_2_d_bits_data;
  logic auto_out_1_a_ready;
  logic auto_out_1_d_valid;
  logic [3:0] auto_out_1_d_bits_opcode;
  logic [1:0] auto_out_1_d_bits_size;
  logic [14:0] auto_out_1_d_bits_source;
  logic [63:0] auto_out_1_d_bits_data;
  logic auto_out_0_a_ready;
  logic auto_out_0_d_valid;
  logic [3:0] auto_out_0_d_bits_opcode;
  logic [1:0] auto_out_0_d_bits_size;
  logic [14:0] auto_out_0_d_bits_source;
  logic [63:0] auto_out_0_d_bits_data;
  wire g_auto_in_a_ready;
  wire i_auto_in_a_ready;
  wire g_auto_in_d_valid;
  wire i_auto_in_d_valid;
  wire [3:0] g_auto_in_d_bits_opcode;
  wire [3:0] i_auto_in_d_bits_opcode;
  wire [1:0] g_auto_in_d_bits_param;
  wire [1:0] i_auto_in_d_bits_param;
  wire [1:0] g_auto_in_d_bits_size;
  wire [1:0] i_auto_in_d_bits_size;
  wire [14:0] g_auto_in_d_bits_source;
  wire [14:0] i_auto_in_d_bits_source;
  wire g_auto_in_d_bits_sink;
  wire i_auto_in_d_bits_sink;
  wire g_auto_in_d_bits_denied;
  wire i_auto_in_d_bits_denied;
  wire [63:0] g_auto_in_d_bits_data;
  wire [63:0] i_auto_in_d_bits_data;
  wire g_auto_in_d_bits_corrupt;
  wire i_auto_in_d_bits_corrupt;
  wire g_auto_out_4_a_valid;
  wire i_auto_out_4_a_valid;
  wire [3:0] g_auto_out_4_a_bits_opcode;
  wire [3:0] i_auto_out_4_a_bits_opcode;
  wire [2:0] g_auto_out_4_a_bits_param;
  wire [2:0] i_auto_out_4_a_bits_param;
  wire [1:0] g_auto_out_4_a_bits_size;
  wire [1:0] i_auto_out_4_a_bits_size;
  wire [14:0] g_auto_out_4_a_bits_source;
  wire [14:0] i_auto_out_4_a_bits_source;
  wire [29:0] g_auto_out_4_a_bits_address;
  wire [29:0] i_auto_out_4_a_bits_address;
  wire [7:0] g_auto_out_4_a_bits_mask;
  wire [7:0] i_auto_out_4_a_bits_mask;
  wire [63:0] g_auto_out_4_a_bits_data;
  wire [63:0] i_auto_out_4_a_bits_data;
  wire g_auto_out_4_a_bits_corrupt;
  wire i_auto_out_4_a_bits_corrupt;
  wire g_auto_out_4_d_ready;
  wire i_auto_out_4_d_ready;
  wire g_auto_out_3_a_valid;
  wire i_auto_out_3_a_valid;
  wire [3:0] g_auto_out_3_a_bits_opcode;
  wire [3:0] i_auto_out_3_a_bits_opcode;
  wire [1:0] g_auto_out_3_a_bits_size;
  wire [1:0] i_auto_out_3_a_bits_size;
  wire [14:0] g_auto_out_3_a_bits_source;
  wire [14:0] i_auto_out_3_a_bits_source;
  wire [29:0] g_auto_out_3_a_bits_address;
  wire [29:0] i_auto_out_3_a_bits_address;
  wire [7:0] g_auto_out_3_a_bits_mask;
  wire [7:0] i_auto_out_3_a_bits_mask;
  wire [63:0] g_auto_out_3_a_bits_data;
  wire [63:0] i_auto_out_3_a_bits_data;
  wire g_auto_out_3_d_ready;
  wire i_auto_out_3_d_ready;
  wire g_auto_out_2_a_valid;
  wire i_auto_out_2_a_valid;
  wire [3:0] g_auto_out_2_a_bits_opcode;
  wire [3:0] i_auto_out_2_a_bits_opcode;
  wire [1:0] g_auto_out_2_a_bits_size;
  wire [1:0] i_auto_out_2_a_bits_size;
  wire [14:0] g_auto_out_2_a_bits_source;
  wire [14:0] i_auto_out_2_a_bits_source;
  wire [29:0] g_auto_out_2_a_bits_address;
  wire [29:0] i_auto_out_2_a_bits_address;
  wire [7:0] g_auto_out_2_a_bits_mask;
  wire [7:0] i_auto_out_2_a_bits_mask;
  wire [63:0] g_auto_out_2_a_bits_data;
  wire [63:0] i_auto_out_2_a_bits_data;
  wire g_auto_out_2_d_ready;
  wire i_auto_out_2_d_ready;
  wire g_auto_out_1_a_valid;
  wire i_auto_out_1_a_valid;
  wire [3:0] g_auto_out_1_a_bits_opcode;
  wire [3:0] i_auto_out_1_a_bits_opcode;
  wire [1:0] g_auto_out_1_a_bits_size;
  wire [1:0] i_auto_out_1_a_bits_size;
  wire [14:0] g_auto_out_1_a_bits_source;
  wire [14:0] i_auto_out_1_a_bits_source;
  wire [29:0] g_auto_out_1_a_bits_address;
  wire [29:0] i_auto_out_1_a_bits_address;
  wire [7:0] g_auto_out_1_a_bits_mask;
  wire [7:0] i_auto_out_1_a_bits_mask;
  wire [63:0] g_auto_out_1_a_bits_data;
  wire [63:0] i_auto_out_1_a_bits_data;
  wire g_auto_out_1_d_ready;
  wire i_auto_out_1_d_ready;
  wire g_auto_out_0_a_valid;
  wire i_auto_out_0_a_valid;
  wire [3:0] g_auto_out_0_a_bits_opcode;
  wire [3:0] i_auto_out_0_a_bits_opcode;
  wire [1:0] g_auto_out_0_a_bits_size;
  wire [1:0] i_auto_out_0_a_bits_size;
  wire [14:0] g_auto_out_0_a_bits_source;
  wire [14:0] i_auto_out_0_a_bits_source;
  wire [29:0] g_auto_out_0_a_bits_address;
  wire [29:0] i_auto_out_0_a_bits_address;
  wire [7:0] g_auto_out_0_a_bits_mask;
  wire [7:0] i_auto_out_0_a_bits_mask;
  wire [63:0] g_auto_out_0_a_bits_data;
  wire [63:0] i_auto_out_0_a_bits_data;
  wire g_auto_out_0_d_ready;
  wire i_auto_out_0_d_ready;

  TLXbar_2 u_g (
    .clock(clock),
    .reset(reset),
    .auto_in_a_ready(g_auto_in_a_ready),
    .auto_in_a_valid(auto_in_a_valid),
    .auto_in_a_bits_opcode(auto_in_a_bits_opcode),
    .auto_in_a_bits_param(auto_in_a_bits_param),
    .auto_in_a_bits_size(auto_in_a_bits_size),
    .auto_in_a_bits_source(auto_in_a_bits_source),
    .auto_in_a_bits_address(auto_in_a_bits_address),
    .auto_in_a_bits_mask(auto_in_a_bits_mask),
    .auto_in_a_bits_data(auto_in_a_bits_data),
    .auto_in_a_bits_corrupt(auto_in_a_bits_corrupt),
    .auto_in_d_ready(auto_in_d_ready),
    .auto_in_d_valid(g_auto_in_d_valid),
    .auto_in_d_bits_opcode(g_auto_in_d_bits_opcode),
    .auto_in_d_bits_param(g_auto_in_d_bits_param),
    .auto_in_d_bits_size(g_auto_in_d_bits_size),
    .auto_in_d_bits_source(g_auto_in_d_bits_source),
    .auto_in_d_bits_sink(g_auto_in_d_bits_sink),
    .auto_in_d_bits_denied(g_auto_in_d_bits_denied),
    .auto_in_d_bits_data(g_auto_in_d_bits_data),
    .auto_in_d_bits_corrupt(g_auto_in_d_bits_corrupt),
    .auto_out_4_a_ready(auto_out_4_a_ready),
    .auto_out_4_a_valid(g_auto_out_4_a_valid),
    .auto_out_4_a_bits_opcode(g_auto_out_4_a_bits_opcode),
    .auto_out_4_a_bits_param(g_auto_out_4_a_bits_param),
    .auto_out_4_a_bits_size(g_auto_out_4_a_bits_size),
    .auto_out_4_a_bits_source(g_auto_out_4_a_bits_source),
    .auto_out_4_a_bits_address(g_auto_out_4_a_bits_address),
    .auto_out_4_a_bits_mask(g_auto_out_4_a_bits_mask),
    .auto_out_4_a_bits_data(g_auto_out_4_a_bits_data),
    .auto_out_4_a_bits_corrupt(g_auto_out_4_a_bits_corrupt),
    .auto_out_4_d_ready(g_auto_out_4_d_ready),
    .auto_out_4_d_valid(auto_out_4_d_valid),
    .auto_out_4_d_bits_opcode(auto_out_4_d_bits_opcode),
    .auto_out_4_d_bits_param(auto_out_4_d_bits_param),
    .auto_out_4_d_bits_size(auto_out_4_d_bits_size),
    .auto_out_4_d_bits_source(auto_out_4_d_bits_source),
    .auto_out_4_d_bits_sink(auto_out_4_d_bits_sink),
    .auto_out_4_d_bits_denied(auto_out_4_d_bits_denied),
    .auto_out_4_d_bits_data(auto_out_4_d_bits_data),
    .auto_out_4_d_bits_corrupt(auto_out_4_d_bits_corrupt),
    .auto_out_3_a_ready(auto_out_3_a_ready),
    .auto_out_3_a_valid(g_auto_out_3_a_valid),
    .auto_out_3_a_bits_opcode(g_auto_out_3_a_bits_opcode),
    .auto_out_3_a_bits_size(g_auto_out_3_a_bits_size),
    .auto_out_3_a_bits_source(g_auto_out_3_a_bits_source),
    .auto_out_3_a_bits_address(g_auto_out_3_a_bits_address),
    .auto_out_3_a_bits_mask(g_auto_out_3_a_bits_mask),
    .auto_out_3_a_bits_data(g_auto_out_3_a_bits_data),
    .auto_out_3_d_ready(g_auto_out_3_d_ready),
    .auto_out_3_d_valid(auto_out_3_d_valid),
    .auto_out_3_d_bits_opcode(auto_out_3_d_bits_opcode),
    .auto_out_3_d_bits_size(auto_out_3_d_bits_size),
    .auto_out_3_d_bits_source(auto_out_3_d_bits_source),
    .auto_out_3_d_bits_data(auto_out_3_d_bits_data),
    .auto_out_2_a_ready(auto_out_2_a_ready),
    .auto_out_2_a_valid(g_auto_out_2_a_valid),
    .auto_out_2_a_bits_opcode(g_auto_out_2_a_bits_opcode),
    .auto_out_2_a_bits_size(g_auto_out_2_a_bits_size),
    .auto_out_2_a_bits_source(g_auto_out_2_a_bits_source),
    .auto_out_2_a_bits_address(g_auto_out_2_a_bits_address),
    .auto_out_2_a_bits_mask(g_auto_out_2_a_bits_mask),
    .auto_out_2_a_bits_data(g_auto_out_2_a_bits_data),
    .auto_out_2_d_ready(g_auto_out_2_d_ready),
    .auto_out_2_d_valid(auto_out_2_d_valid),
    .auto_out_2_d_bits_opcode(auto_out_2_d_bits_opcode),
    .auto_out_2_d_bits_size(auto_out_2_d_bits_size),
    .auto_out_2_d_bits_source(auto_out_2_d_bits_source),
    .auto_out_2_d_bits_data(auto_out_2_d_bits_data),
    .auto_out_1_a_ready(auto_out_1_a_ready),
    .auto_out_1_a_valid(g_auto_out_1_a_valid),
    .auto_out_1_a_bits_opcode(g_auto_out_1_a_bits_opcode),
    .auto_out_1_a_bits_size(g_auto_out_1_a_bits_size),
    .auto_out_1_a_bits_source(g_auto_out_1_a_bits_source),
    .auto_out_1_a_bits_address(g_auto_out_1_a_bits_address),
    .auto_out_1_a_bits_mask(g_auto_out_1_a_bits_mask),
    .auto_out_1_a_bits_data(g_auto_out_1_a_bits_data),
    .auto_out_1_d_ready(g_auto_out_1_d_ready),
    .auto_out_1_d_valid(auto_out_1_d_valid),
    .auto_out_1_d_bits_opcode(auto_out_1_d_bits_opcode),
    .auto_out_1_d_bits_size(auto_out_1_d_bits_size),
    .auto_out_1_d_bits_source(auto_out_1_d_bits_source),
    .auto_out_1_d_bits_data(auto_out_1_d_bits_data),
    .auto_out_0_a_ready(auto_out_0_a_ready),
    .auto_out_0_a_valid(g_auto_out_0_a_valid),
    .auto_out_0_a_bits_opcode(g_auto_out_0_a_bits_opcode),
    .auto_out_0_a_bits_size(g_auto_out_0_a_bits_size),
    .auto_out_0_a_bits_source(g_auto_out_0_a_bits_source),
    .auto_out_0_a_bits_address(g_auto_out_0_a_bits_address),
    .auto_out_0_a_bits_mask(g_auto_out_0_a_bits_mask),
    .auto_out_0_a_bits_data(g_auto_out_0_a_bits_data),
    .auto_out_0_d_ready(g_auto_out_0_d_ready),
    .auto_out_0_d_valid(auto_out_0_d_valid),
    .auto_out_0_d_bits_opcode(auto_out_0_d_bits_opcode),
    .auto_out_0_d_bits_size(auto_out_0_d_bits_size),
    .auto_out_0_d_bits_source(auto_out_0_d_bits_source),
    .auto_out_0_d_bits_data(auto_out_0_d_bits_data)
  );

  TLXbar_2_xs u_i (
    .clock(clock),
    .reset(reset),
    .auto_in_a_ready(i_auto_in_a_ready),
    .auto_in_a_valid(auto_in_a_valid),
    .auto_in_a_bits_opcode(auto_in_a_bits_opcode),
    .auto_in_a_bits_param(auto_in_a_bits_param),
    .auto_in_a_bits_size(auto_in_a_bits_size),
    .auto_in_a_bits_source(auto_in_a_bits_source),
    .auto_in_a_bits_address(auto_in_a_bits_address),
    .auto_in_a_bits_mask(auto_in_a_bits_mask),
    .auto_in_a_bits_data(auto_in_a_bits_data),
    .auto_in_a_bits_corrupt(auto_in_a_bits_corrupt),
    .auto_in_d_ready(auto_in_d_ready),
    .auto_in_d_valid(i_auto_in_d_valid),
    .auto_in_d_bits_opcode(i_auto_in_d_bits_opcode),
    .auto_in_d_bits_param(i_auto_in_d_bits_param),
    .auto_in_d_bits_size(i_auto_in_d_bits_size),
    .auto_in_d_bits_source(i_auto_in_d_bits_source),
    .auto_in_d_bits_sink(i_auto_in_d_bits_sink),
    .auto_in_d_bits_denied(i_auto_in_d_bits_denied),
    .auto_in_d_bits_data(i_auto_in_d_bits_data),
    .auto_in_d_bits_corrupt(i_auto_in_d_bits_corrupt),
    .auto_out_4_a_ready(auto_out_4_a_ready),
    .auto_out_4_a_valid(i_auto_out_4_a_valid),
    .auto_out_4_a_bits_opcode(i_auto_out_4_a_bits_opcode),
    .auto_out_4_a_bits_param(i_auto_out_4_a_bits_param),
    .auto_out_4_a_bits_size(i_auto_out_4_a_bits_size),
    .auto_out_4_a_bits_source(i_auto_out_4_a_bits_source),
    .auto_out_4_a_bits_address(i_auto_out_4_a_bits_address),
    .auto_out_4_a_bits_mask(i_auto_out_4_a_bits_mask),
    .auto_out_4_a_bits_data(i_auto_out_4_a_bits_data),
    .auto_out_4_a_bits_corrupt(i_auto_out_4_a_bits_corrupt),
    .auto_out_4_d_ready(i_auto_out_4_d_ready),
    .auto_out_4_d_valid(auto_out_4_d_valid),
    .auto_out_4_d_bits_opcode(auto_out_4_d_bits_opcode),
    .auto_out_4_d_bits_param(auto_out_4_d_bits_param),
    .auto_out_4_d_bits_size(auto_out_4_d_bits_size),
    .auto_out_4_d_bits_source(auto_out_4_d_bits_source),
    .auto_out_4_d_bits_sink(auto_out_4_d_bits_sink),
    .auto_out_4_d_bits_denied(auto_out_4_d_bits_denied),
    .auto_out_4_d_bits_data(auto_out_4_d_bits_data),
    .auto_out_4_d_bits_corrupt(auto_out_4_d_bits_corrupt),
    .auto_out_3_a_ready(auto_out_3_a_ready),
    .auto_out_3_a_valid(i_auto_out_3_a_valid),
    .auto_out_3_a_bits_opcode(i_auto_out_3_a_bits_opcode),
    .auto_out_3_a_bits_size(i_auto_out_3_a_bits_size),
    .auto_out_3_a_bits_source(i_auto_out_3_a_bits_source),
    .auto_out_3_a_bits_address(i_auto_out_3_a_bits_address),
    .auto_out_3_a_bits_mask(i_auto_out_3_a_bits_mask),
    .auto_out_3_a_bits_data(i_auto_out_3_a_bits_data),
    .auto_out_3_d_ready(i_auto_out_3_d_ready),
    .auto_out_3_d_valid(auto_out_3_d_valid),
    .auto_out_3_d_bits_opcode(auto_out_3_d_bits_opcode),
    .auto_out_3_d_bits_size(auto_out_3_d_bits_size),
    .auto_out_3_d_bits_source(auto_out_3_d_bits_source),
    .auto_out_3_d_bits_data(auto_out_3_d_bits_data),
    .auto_out_2_a_ready(auto_out_2_a_ready),
    .auto_out_2_a_valid(i_auto_out_2_a_valid),
    .auto_out_2_a_bits_opcode(i_auto_out_2_a_bits_opcode),
    .auto_out_2_a_bits_size(i_auto_out_2_a_bits_size),
    .auto_out_2_a_bits_source(i_auto_out_2_a_bits_source),
    .auto_out_2_a_bits_address(i_auto_out_2_a_bits_address),
    .auto_out_2_a_bits_mask(i_auto_out_2_a_bits_mask),
    .auto_out_2_a_bits_data(i_auto_out_2_a_bits_data),
    .auto_out_2_d_ready(i_auto_out_2_d_ready),
    .auto_out_2_d_valid(auto_out_2_d_valid),
    .auto_out_2_d_bits_opcode(auto_out_2_d_bits_opcode),
    .auto_out_2_d_bits_size(auto_out_2_d_bits_size),
    .auto_out_2_d_bits_source(auto_out_2_d_bits_source),
    .auto_out_2_d_bits_data(auto_out_2_d_bits_data),
    .auto_out_1_a_ready(auto_out_1_a_ready),
    .auto_out_1_a_valid(i_auto_out_1_a_valid),
    .auto_out_1_a_bits_opcode(i_auto_out_1_a_bits_opcode),
    .auto_out_1_a_bits_size(i_auto_out_1_a_bits_size),
    .auto_out_1_a_bits_source(i_auto_out_1_a_bits_source),
    .auto_out_1_a_bits_address(i_auto_out_1_a_bits_address),
    .auto_out_1_a_bits_mask(i_auto_out_1_a_bits_mask),
    .auto_out_1_a_bits_data(i_auto_out_1_a_bits_data),
    .auto_out_1_d_ready(i_auto_out_1_d_ready),
    .auto_out_1_d_valid(auto_out_1_d_valid),
    .auto_out_1_d_bits_opcode(auto_out_1_d_bits_opcode),
    .auto_out_1_d_bits_size(auto_out_1_d_bits_size),
    .auto_out_1_d_bits_source(auto_out_1_d_bits_source),
    .auto_out_1_d_bits_data(auto_out_1_d_bits_data),
    .auto_out_0_a_ready(auto_out_0_a_ready),
    .auto_out_0_a_valid(i_auto_out_0_a_valid),
    .auto_out_0_a_bits_opcode(i_auto_out_0_a_bits_opcode),
    .auto_out_0_a_bits_size(i_auto_out_0_a_bits_size),
    .auto_out_0_a_bits_source(i_auto_out_0_a_bits_source),
    .auto_out_0_a_bits_address(i_auto_out_0_a_bits_address),
    .auto_out_0_a_bits_mask(i_auto_out_0_a_bits_mask),
    .auto_out_0_a_bits_data(i_auto_out_0_a_bits_data),
    .auto_out_0_d_ready(i_auto_out_0_d_ready),
    .auto_out_0_d_valid(auto_out_0_d_valid),
    .auto_out_0_d_bits_opcode(auto_out_0_d_bits_opcode),
    .auto_out_0_d_bits_size(auto_out_0_d_bits_size),
    .auto_out_0_d_bits_source(auto_out_0_d_bits_source),
    .auto_out_0_d_bits_data(auto_out_0_d_bits_data)
  );

  task automatic drive_random_inputs();
    auto_in_a_valid <= $urandom_range(0, 1);
    auto_in_a_bits_opcode <= 4'({$urandom});
    auto_in_a_bits_param <= 3'({$urandom});
    auto_in_a_bits_size <= 2'({$urandom});
    auto_in_a_bits_source <= 15'({$urandom});
    if ($urandom_range(0, 1))
      auto_in_a_bits_address <= 30'({$urandom}) & ~(30'h1 << 26);
    else
      auto_in_a_bits_address <= 30'({$urandom});
    auto_in_a_bits_mask <= 8'({$urandom});
    auto_in_a_bits_data <= 64'({$urandom, $urandom});
    auto_in_a_bits_corrupt <= $urandom_range(0, 1);
    auto_in_d_ready <= $urandom_range(0, 1);
    auto_out_4_a_ready <= $urandom_range(0, 1);
    auto_out_4_d_valid <= $urandom_range(0, 1);
    auto_out_4_d_bits_opcode <= 4'({$urandom});
    auto_out_4_d_bits_param <= 2'({$urandom});
    auto_out_4_d_bits_size <= 2'({$urandom});
    auto_out_4_d_bits_source <= 15'({$urandom});
    auto_out_4_d_bits_sink <= $urandom_range(0, 1);
    auto_out_4_d_bits_denied <= $urandom_range(0, 1);
    auto_out_4_d_bits_data <= 64'({$urandom, $urandom});
    auto_out_4_d_bits_corrupt <= $urandom_range(0, 1);
    auto_out_3_a_ready <= $urandom_range(0, 1);
    auto_out_3_d_valid <= $urandom_range(0, 1);
    auto_out_3_d_bits_opcode <= 4'({$urandom});
    auto_out_3_d_bits_size <= 2'({$urandom});
    auto_out_3_d_bits_source <= 15'({$urandom});
    auto_out_3_d_bits_data <= 64'({$urandom, $urandom});
    auto_out_2_a_ready <= $urandom_range(0, 1);
    auto_out_2_d_valid <= $urandom_range(0, 1);
    auto_out_2_d_bits_opcode <= 4'({$urandom});
    auto_out_2_d_bits_size <= 2'({$urandom});
    auto_out_2_d_bits_source <= 15'({$urandom});
    auto_out_2_d_bits_data <= 64'({$urandom, $urandom});
    auto_out_1_a_ready <= $urandom_range(0, 1);
    auto_out_1_d_valid <= $urandom_range(0, 1);
    auto_out_1_d_bits_opcode <= 4'({$urandom});
    auto_out_1_d_bits_size <= 2'({$urandom});
    auto_out_1_d_bits_source <= 15'({$urandom});
    auto_out_1_d_bits_data <= 64'({$urandom, $urandom});
    auto_out_0_a_ready <= $urandom_range(0, 1);
    auto_out_0_d_valid <= $urandom_range(0, 1);
    auto_out_0_d_bits_opcode <= 4'({$urandom});
    auto_out_0_d_bits_size <= 2'({$urandom});
    auto_out_0_d_bits_source <= 15'({$urandom});
    auto_out_0_d_bits_data <= 64'({$urandom, $urandom});
  endtask

  task automatic check_outputs();
    `CHECK(auto_in_a_ready)
    `CHECK(auto_in_d_valid)
    `CHECK(auto_in_d_bits_opcode)
    `CHECK(auto_in_d_bits_param)
    `CHECK(auto_in_d_bits_size)
    `CHECK(auto_in_d_bits_source)
    `CHECK(auto_in_d_bits_sink)
    `CHECK(auto_in_d_bits_denied)
    `CHECK(auto_in_d_bits_data)
    `CHECK(auto_in_d_bits_corrupt)
    `CHECK(auto_out_4_a_valid)
    `CHECK(auto_out_4_a_bits_opcode)
    `CHECK(auto_out_4_a_bits_param)
    `CHECK(auto_out_4_a_bits_size)
    `CHECK(auto_out_4_a_bits_source)
    `CHECK(auto_out_4_a_bits_address)
    `CHECK(auto_out_4_a_bits_mask)
    `CHECK(auto_out_4_a_bits_data)
    `CHECK(auto_out_4_a_bits_corrupt)
    `CHECK(auto_out_4_d_ready)
    `CHECK(auto_out_3_a_valid)
    `CHECK(auto_out_3_a_bits_opcode)
    `CHECK(auto_out_3_a_bits_size)
    `CHECK(auto_out_3_a_bits_source)
    `CHECK(auto_out_3_a_bits_address)
    `CHECK(auto_out_3_a_bits_mask)
    `CHECK(auto_out_3_a_bits_data)
    `CHECK(auto_out_3_d_ready)
    `CHECK(auto_out_2_a_valid)
    `CHECK(auto_out_2_a_bits_opcode)
    `CHECK(auto_out_2_a_bits_size)
    `CHECK(auto_out_2_a_bits_source)
    `CHECK(auto_out_2_a_bits_address)
    `CHECK(auto_out_2_a_bits_mask)
    `CHECK(auto_out_2_a_bits_data)
    `CHECK(auto_out_2_d_ready)
    `CHECK(auto_out_1_a_valid)
    `CHECK(auto_out_1_a_bits_opcode)
    `CHECK(auto_out_1_a_bits_size)
    `CHECK(auto_out_1_a_bits_source)
    `CHECK(auto_out_1_a_bits_address)
    `CHECK(auto_out_1_a_bits_mask)
    `CHECK(auto_out_1_a_bits_data)
    `CHECK(auto_out_1_d_ready)
    `CHECK(auto_out_0_a_valid)
    `CHECK(auto_out_0_a_bits_opcode)
    `CHECK(auto_out_0_a_bits_size)
    `CHECK(auto_out_0_a_bits_source)
    `CHECK(auto_out_0_a_bits_address)
    `CHECK(auto_out_0_a_bits_mask)
    `CHECK(auto_out_0_a_bits_data)
    `CHECK(auto_out_0_d_ready)
  endtask

  initial begin
    if ($value$plusargs("NCYCLES=%d", NCYCLES)) begin end
    reset = 1'b1;
    auto_in_a_valid = '0;
    auto_in_a_bits_opcode = '0;
    auto_in_a_bits_param = '0;
    auto_in_a_bits_size = '0;
    auto_in_a_bits_source = '0;
    auto_in_a_bits_address = '0;
    auto_in_a_bits_mask = '0;
    auto_in_a_bits_data = '0;
    auto_in_a_bits_corrupt = '0;
    auto_in_d_ready = '0;
    auto_out_4_a_ready = '0;
    auto_out_4_d_valid = '0;
    auto_out_4_d_bits_opcode = '0;
    auto_out_4_d_bits_param = '0;
    auto_out_4_d_bits_size = '0;
    auto_out_4_d_bits_source = '0;
    auto_out_4_d_bits_sink = '0;
    auto_out_4_d_bits_denied = '0;
    auto_out_4_d_bits_data = '0;
    auto_out_4_d_bits_corrupt = '0;
    auto_out_3_a_ready = '0;
    auto_out_3_d_valid = '0;
    auto_out_3_d_bits_opcode = '0;
    auto_out_3_d_bits_size = '0;
    auto_out_3_d_bits_source = '0;
    auto_out_3_d_bits_data = '0;
    auto_out_2_a_ready = '0;
    auto_out_2_d_valid = '0;
    auto_out_2_d_bits_opcode = '0;
    auto_out_2_d_bits_size = '0;
    auto_out_2_d_bits_source = '0;
    auto_out_2_d_bits_data = '0;
    auto_out_1_a_ready = '0;
    auto_out_1_d_valid = '0;
    auto_out_1_d_bits_opcode = '0;
    auto_out_1_d_bits_size = '0;
    auto_out_1_d_bits_source = '0;
    auto_out_1_d_bits_data = '0;
    auto_out_0_a_ready = '0;
    auto_out_0_d_valid = '0;
    auto_out_0_d_bits_opcode = '0;
    auto_out_0_d_bits_size = '0;
    auto_out_0_d_bits_source = '0;
    auto_out_0_d_bits_data = '0;
    repeat (6) @(posedge clock);
    reset = 1'b0;
    repeat (NCYCLES) begin
      @(negedge clock);
      drive_random_inputs();
      @(posedge clock);
      #1 check_outputs();
    end
    $display("TLXbar_2 checks=%0d errors=%0d", checks, errors);
    if (errors == 0 && checks > 1000) begin
      $display("TEST PASSED");
      $finish;
    end
    $display("TEST FAILED");
    $fatal(1);
  end
endmodule
`undef CHECK
