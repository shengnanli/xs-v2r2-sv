// 自动生成：scripts/gen_fastarbiter4.py —— 勿手改
// FastArbiter_7 双例化逐拍比对: golden FastArbiter_7 vs 可读 FastArbiter_7_xs。
// 激励: 全随机 (随机 valids + 随机 io_out_ready 自然遍历 round-robin 轮转相位)。
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

  logic io_in_0_valid;
  logic [30:0] io_in_0_bits_tag;
  logic [8:0] io_in_0_bits_set;
  logic [1:0] io_in_0_bits_param;
  logic [1:0] io_in_0_bits_alias;
  logic io_in_1_valid;
  logic [30:0] io_in_1_bits_tag;
  logic [8:0] io_in_1_bits_set;
  logic [1:0] io_in_1_bits_param;
  logic [1:0] io_in_1_bits_alias;
  logic io_in_2_valid;
  logic [30:0] io_in_2_bits_tag;
  logic [8:0] io_in_2_bits_set;
  logic [1:0] io_in_2_bits_param;
  logic [1:0] io_in_2_bits_alias;
  logic io_in_3_valid;
  logic [30:0] io_in_3_bits_tag;
  logic [8:0] io_in_3_bits_set;
  logic [1:0] io_in_3_bits_param;
  logic [1:0] io_in_3_bits_alias;
  logic io_in_4_valid;
  logic [30:0] io_in_4_bits_tag;
  logic [8:0] io_in_4_bits_set;
  logic [1:0] io_in_4_bits_param;
  logic [1:0] io_in_4_bits_alias;
  logic io_in_5_valid;
  logic [30:0] io_in_5_bits_tag;
  logic [8:0] io_in_5_bits_set;
  logic [1:0] io_in_5_bits_param;
  logic [1:0] io_in_5_bits_alias;
  logic io_in_6_valid;
  logic [30:0] io_in_6_bits_tag;
  logic [8:0] io_in_6_bits_set;
  logic [1:0] io_in_6_bits_param;
  logic [1:0] io_in_6_bits_alias;
  logic io_in_7_valid;
  logic [30:0] io_in_7_bits_tag;
  logic [8:0] io_in_7_bits_set;
  logic [1:0] io_in_7_bits_param;
  logic [1:0] io_in_7_bits_alias;
  logic io_in_8_valid;
  logic [30:0] io_in_8_bits_tag;
  logic [8:0] io_in_8_bits_set;
  logic [1:0] io_in_8_bits_param;
  logic [1:0] io_in_8_bits_alias;
  logic io_in_9_valid;
  logic [30:0] io_in_9_bits_tag;
  logic [8:0] io_in_9_bits_set;
  logic [1:0] io_in_9_bits_param;
  logic [1:0] io_in_9_bits_alias;
  logic io_in_10_valid;
  logic [30:0] io_in_10_bits_tag;
  logic [8:0] io_in_10_bits_set;
  logic [1:0] io_in_10_bits_param;
  logic [1:0] io_in_10_bits_alias;
  logic io_in_11_valid;
  logic [30:0] io_in_11_bits_tag;
  logic [8:0] io_in_11_bits_set;
  logic [1:0] io_in_11_bits_param;
  logic [1:0] io_in_11_bits_alias;
  logic io_in_12_valid;
  logic [30:0] io_in_12_bits_tag;
  logic [8:0] io_in_12_bits_set;
  logic [1:0] io_in_12_bits_param;
  logic [1:0] io_in_12_bits_alias;
  logic io_in_13_valid;
  logic [30:0] io_in_13_bits_tag;
  logic [8:0] io_in_13_bits_set;
  logic [1:0] io_in_13_bits_param;
  logic [1:0] io_in_13_bits_alias;
  logic io_in_14_valid;
  logic [30:0] io_in_14_bits_tag;
  logic [8:0] io_in_14_bits_set;
  logic [1:0] io_in_14_bits_param;
  logic [1:0] io_in_14_bits_alias;
  logic io_in_15_valid;
  logic [30:0] io_in_15_bits_tag;
  logic [8:0] io_in_15_bits_set;
  logic [1:0] io_in_15_bits_param;
  logic [1:0] io_in_15_bits_alias;
  logic io_out_ready;
  wire g_io_in_0_ready;
  wire i_io_in_0_ready;
  wire g_io_in_1_ready;
  wire i_io_in_1_ready;
  wire g_io_in_2_ready;
  wire i_io_in_2_ready;
  wire g_io_in_3_ready;
  wire i_io_in_3_ready;
  wire g_io_in_4_ready;
  wire i_io_in_4_ready;
  wire g_io_in_5_ready;
  wire i_io_in_5_ready;
  wire g_io_in_6_ready;
  wire i_io_in_6_ready;
  wire g_io_in_7_ready;
  wire i_io_in_7_ready;
  wire g_io_in_8_ready;
  wire i_io_in_8_ready;
  wire g_io_in_9_ready;
  wire i_io_in_9_ready;
  wire g_io_in_10_ready;
  wire i_io_in_10_ready;
  wire g_io_in_11_ready;
  wire i_io_in_11_ready;
  wire g_io_in_12_ready;
  wire i_io_in_12_ready;
  wire g_io_in_13_ready;
  wire i_io_in_13_ready;
  wire g_io_in_14_ready;
  wire i_io_in_14_ready;
  wire g_io_in_15_ready;
  wire i_io_in_15_ready;
  wire g_io_out_valid;
  wire i_io_out_valid;
  wire [30:0] g_io_out_bits_tag;
  wire [30:0] i_io_out_bits_tag;
  wire [8:0] g_io_out_bits_set;
  wire [8:0] i_io_out_bits_set;
  wire [2:0] g_io_out_bits_opcode;
  wire [2:0] i_io_out_bits_opcode;
  wire [1:0] g_io_out_bits_param;
  wire [1:0] i_io_out_bits_param;
  wire [1:0] g_io_out_bits_alias;
  wire [1:0] i_io_out_bits_alias;

  FastArbiter_7 u_g (
    .clock(clock),
    .reset(reset),
    .io_in_0_ready(g_io_in_0_ready),
    .io_in_0_valid(io_in_0_valid),
    .io_in_0_bits_tag(io_in_0_bits_tag),
    .io_in_0_bits_set(io_in_0_bits_set),
    .io_in_0_bits_param(io_in_0_bits_param),
    .io_in_0_bits_alias(io_in_0_bits_alias),
    .io_in_1_ready(g_io_in_1_ready),
    .io_in_1_valid(io_in_1_valid),
    .io_in_1_bits_tag(io_in_1_bits_tag),
    .io_in_1_bits_set(io_in_1_bits_set),
    .io_in_1_bits_param(io_in_1_bits_param),
    .io_in_1_bits_alias(io_in_1_bits_alias),
    .io_in_2_ready(g_io_in_2_ready),
    .io_in_2_valid(io_in_2_valid),
    .io_in_2_bits_tag(io_in_2_bits_tag),
    .io_in_2_bits_set(io_in_2_bits_set),
    .io_in_2_bits_param(io_in_2_bits_param),
    .io_in_2_bits_alias(io_in_2_bits_alias),
    .io_in_3_ready(g_io_in_3_ready),
    .io_in_3_valid(io_in_3_valid),
    .io_in_3_bits_tag(io_in_3_bits_tag),
    .io_in_3_bits_set(io_in_3_bits_set),
    .io_in_3_bits_param(io_in_3_bits_param),
    .io_in_3_bits_alias(io_in_3_bits_alias),
    .io_in_4_ready(g_io_in_4_ready),
    .io_in_4_valid(io_in_4_valid),
    .io_in_4_bits_tag(io_in_4_bits_tag),
    .io_in_4_bits_set(io_in_4_bits_set),
    .io_in_4_bits_param(io_in_4_bits_param),
    .io_in_4_bits_alias(io_in_4_bits_alias),
    .io_in_5_ready(g_io_in_5_ready),
    .io_in_5_valid(io_in_5_valid),
    .io_in_5_bits_tag(io_in_5_bits_tag),
    .io_in_5_bits_set(io_in_5_bits_set),
    .io_in_5_bits_param(io_in_5_bits_param),
    .io_in_5_bits_alias(io_in_5_bits_alias),
    .io_in_6_ready(g_io_in_6_ready),
    .io_in_6_valid(io_in_6_valid),
    .io_in_6_bits_tag(io_in_6_bits_tag),
    .io_in_6_bits_set(io_in_6_bits_set),
    .io_in_6_bits_param(io_in_6_bits_param),
    .io_in_6_bits_alias(io_in_6_bits_alias),
    .io_in_7_ready(g_io_in_7_ready),
    .io_in_7_valid(io_in_7_valid),
    .io_in_7_bits_tag(io_in_7_bits_tag),
    .io_in_7_bits_set(io_in_7_bits_set),
    .io_in_7_bits_param(io_in_7_bits_param),
    .io_in_7_bits_alias(io_in_7_bits_alias),
    .io_in_8_ready(g_io_in_8_ready),
    .io_in_8_valid(io_in_8_valid),
    .io_in_8_bits_tag(io_in_8_bits_tag),
    .io_in_8_bits_set(io_in_8_bits_set),
    .io_in_8_bits_param(io_in_8_bits_param),
    .io_in_8_bits_alias(io_in_8_bits_alias),
    .io_in_9_ready(g_io_in_9_ready),
    .io_in_9_valid(io_in_9_valid),
    .io_in_9_bits_tag(io_in_9_bits_tag),
    .io_in_9_bits_set(io_in_9_bits_set),
    .io_in_9_bits_param(io_in_9_bits_param),
    .io_in_9_bits_alias(io_in_9_bits_alias),
    .io_in_10_ready(g_io_in_10_ready),
    .io_in_10_valid(io_in_10_valid),
    .io_in_10_bits_tag(io_in_10_bits_tag),
    .io_in_10_bits_set(io_in_10_bits_set),
    .io_in_10_bits_param(io_in_10_bits_param),
    .io_in_10_bits_alias(io_in_10_bits_alias),
    .io_in_11_ready(g_io_in_11_ready),
    .io_in_11_valid(io_in_11_valid),
    .io_in_11_bits_tag(io_in_11_bits_tag),
    .io_in_11_bits_set(io_in_11_bits_set),
    .io_in_11_bits_param(io_in_11_bits_param),
    .io_in_11_bits_alias(io_in_11_bits_alias),
    .io_in_12_ready(g_io_in_12_ready),
    .io_in_12_valid(io_in_12_valid),
    .io_in_12_bits_tag(io_in_12_bits_tag),
    .io_in_12_bits_set(io_in_12_bits_set),
    .io_in_12_bits_param(io_in_12_bits_param),
    .io_in_12_bits_alias(io_in_12_bits_alias),
    .io_in_13_ready(g_io_in_13_ready),
    .io_in_13_valid(io_in_13_valid),
    .io_in_13_bits_tag(io_in_13_bits_tag),
    .io_in_13_bits_set(io_in_13_bits_set),
    .io_in_13_bits_param(io_in_13_bits_param),
    .io_in_13_bits_alias(io_in_13_bits_alias),
    .io_in_14_ready(g_io_in_14_ready),
    .io_in_14_valid(io_in_14_valid),
    .io_in_14_bits_tag(io_in_14_bits_tag),
    .io_in_14_bits_set(io_in_14_bits_set),
    .io_in_14_bits_param(io_in_14_bits_param),
    .io_in_14_bits_alias(io_in_14_bits_alias),
    .io_in_15_ready(g_io_in_15_ready),
    .io_in_15_valid(io_in_15_valid),
    .io_in_15_bits_tag(io_in_15_bits_tag),
    .io_in_15_bits_set(io_in_15_bits_set),
    .io_in_15_bits_param(io_in_15_bits_param),
    .io_in_15_bits_alias(io_in_15_bits_alias),
    .io_out_ready(io_out_ready),
    .io_out_valid(g_io_out_valid),
    .io_out_bits_tag(g_io_out_bits_tag),
    .io_out_bits_set(g_io_out_bits_set),
    .io_out_bits_opcode(g_io_out_bits_opcode),
    .io_out_bits_param(g_io_out_bits_param),
    .io_out_bits_alias(g_io_out_bits_alias)
  );

  FastArbiter_7_xs u_i (
    .clock(clock),
    .reset(reset),
    .io_in_0_ready(i_io_in_0_ready),
    .io_in_0_valid(io_in_0_valid),
    .io_in_0_bits_tag(io_in_0_bits_tag),
    .io_in_0_bits_set(io_in_0_bits_set),
    .io_in_0_bits_param(io_in_0_bits_param),
    .io_in_0_bits_alias(io_in_0_bits_alias),
    .io_in_1_ready(i_io_in_1_ready),
    .io_in_1_valid(io_in_1_valid),
    .io_in_1_bits_tag(io_in_1_bits_tag),
    .io_in_1_bits_set(io_in_1_bits_set),
    .io_in_1_bits_param(io_in_1_bits_param),
    .io_in_1_bits_alias(io_in_1_bits_alias),
    .io_in_2_ready(i_io_in_2_ready),
    .io_in_2_valid(io_in_2_valid),
    .io_in_2_bits_tag(io_in_2_bits_tag),
    .io_in_2_bits_set(io_in_2_bits_set),
    .io_in_2_bits_param(io_in_2_bits_param),
    .io_in_2_bits_alias(io_in_2_bits_alias),
    .io_in_3_ready(i_io_in_3_ready),
    .io_in_3_valid(io_in_3_valid),
    .io_in_3_bits_tag(io_in_3_bits_tag),
    .io_in_3_bits_set(io_in_3_bits_set),
    .io_in_3_bits_param(io_in_3_bits_param),
    .io_in_3_bits_alias(io_in_3_bits_alias),
    .io_in_4_ready(i_io_in_4_ready),
    .io_in_4_valid(io_in_4_valid),
    .io_in_4_bits_tag(io_in_4_bits_tag),
    .io_in_4_bits_set(io_in_4_bits_set),
    .io_in_4_bits_param(io_in_4_bits_param),
    .io_in_4_bits_alias(io_in_4_bits_alias),
    .io_in_5_ready(i_io_in_5_ready),
    .io_in_5_valid(io_in_5_valid),
    .io_in_5_bits_tag(io_in_5_bits_tag),
    .io_in_5_bits_set(io_in_5_bits_set),
    .io_in_5_bits_param(io_in_5_bits_param),
    .io_in_5_bits_alias(io_in_5_bits_alias),
    .io_in_6_ready(i_io_in_6_ready),
    .io_in_6_valid(io_in_6_valid),
    .io_in_6_bits_tag(io_in_6_bits_tag),
    .io_in_6_bits_set(io_in_6_bits_set),
    .io_in_6_bits_param(io_in_6_bits_param),
    .io_in_6_bits_alias(io_in_6_bits_alias),
    .io_in_7_ready(i_io_in_7_ready),
    .io_in_7_valid(io_in_7_valid),
    .io_in_7_bits_tag(io_in_7_bits_tag),
    .io_in_7_bits_set(io_in_7_bits_set),
    .io_in_7_bits_param(io_in_7_bits_param),
    .io_in_7_bits_alias(io_in_7_bits_alias),
    .io_in_8_ready(i_io_in_8_ready),
    .io_in_8_valid(io_in_8_valid),
    .io_in_8_bits_tag(io_in_8_bits_tag),
    .io_in_8_bits_set(io_in_8_bits_set),
    .io_in_8_bits_param(io_in_8_bits_param),
    .io_in_8_bits_alias(io_in_8_bits_alias),
    .io_in_9_ready(i_io_in_9_ready),
    .io_in_9_valid(io_in_9_valid),
    .io_in_9_bits_tag(io_in_9_bits_tag),
    .io_in_9_bits_set(io_in_9_bits_set),
    .io_in_9_bits_param(io_in_9_bits_param),
    .io_in_9_bits_alias(io_in_9_bits_alias),
    .io_in_10_ready(i_io_in_10_ready),
    .io_in_10_valid(io_in_10_valid),
    .io_in_10_bits_tag(io_in_10_bits_tag),
    .io_in_10_bits_set(io_in_10_bits_set),
    .io_in_10_bits_param(io_in_10_bits_param),
    .io_in_10_bits_alias(io_in_10_bits_alias),
    .io_in_11_ready(i_io_in_11_ready),
    .io_in_11_valid(io_in_11_valid),
    .io_in_11_bits_tag(io_in_11_bits_tag),
    .io_in_11_bits_set(io_in_11_bits_set),
    .io_in_11_bits_param(io_in_11_bits_param),
    .io_in_11_bits_alias(io_in_11_bits_alias),
    .io_in_12_ready(i_io_in_12_ready),
    .io_in_12_valid(io_in_12_valid),
    .io_in_12_bits_tag(io_in_12_bits_tag),
    .io_in_12_bits_set(io_in_12_bits_set),
    .io_in_12_bits_param(io_in_12_bits_param),
    .io_in_12_bits_alias(io_in_12_bits_alias),
    .io_in_13_ready(i_io_in_13_ready),
    .io_in_13_valid(io_in_13_valid),
    .io_in_13_bits_tag(io_in_13_bits_tag),
    .io_in_13_bits_set(io_in_13_bits_set),
    .io_in_13_bits_param(io_in_13_bits_param),
    .io_in_13_bits_alias(io_in_13_bits_alias),
    .io_in_14_ready(i_io_in_14_ready),
    .io_in_14_valid(io_in_14_valid),
    .io_in_14_bits_tag(io_in_14_bits_tag),
    .io_in_14_bits_set(io_in_14_bits_set),
    .io_in_14_bits_param(io_in_14_bits_param),
    .io_in_14_bits_alias(io_in_14_bits_alias),
    .io_in_15_ready(i_io_in_15_ready),
    .io_in_15_valid(io_in_15_valid),
    .io_in_15_bits_tag(io_in_15_bits_tag),
    .io_in_15_bits_set(io_in_15_bits_set),
    .io_in_15_bits_param(io_in_15_bits_param),
    .io_in_15_bits_alias(io_in_15_bits_alias),
    .io_out_ready(io_out_ready),
    .io_out_valid(i_io_out_valid),
    .io_out_bits_tag(i_io_out_bits_tag),
    .io_out_bits_set(i_io_out_bits_set),
    .io_out_bits_opcode(i_io_out_bits_opcode),
    .io_out_bits_param(i_io_out_bits_param),
    .io_out_bits_alias(i_io_out_bits_alias)
  );

  task automatic drive_random_inputs();
    io_in_0_valid <= $urandom_range(0, 1);
    io_in_0_bits_tag <= 31'({$urandom});
    io_in_0_bits_set <= 9'({$urandom});
    io_in_0_bits_param <= 2'({$urandom});
    io_in_0_bits_alias <= 2'({$urandom});
    io_in_1_valid <= $urandom_range(0, 1);
    io_in_1_bits_tag <= 31'({$urandom});
    io_in_1_bits_set <= 9'({$urandom});
    io_in_1_bits_param <= 2'({$urandom});
    io_in_1_bits_alias <= 2'({$urandom});
    io_in_2_valid <= $urandom_range(0, 1);
    io_in_2_bits_tag <= 31'({$urandom});
    io_in_2_bits_set <= 9'({$urandom});
    io_in_2_bits_param <= 2'({$urandom});
    io_in_2_bits_alias <= 2'({$urandom});
    io_in_3_valid <= $urandom_range(0, 1);
    io_in_3_bits_tag <= 31'({$urandom});
    io_in_3_bits_set <= 9'({$urandom});
    io_in_3_bits_param <= 2'({$urandom});
    io_in_3_bits_alias <= 2'({$urandom});
    io_in_4_valid <= $urandom_range(0, 1);
    io_in_4_bits_tag <= 31'({$urandom});
    io_in_4_bits_set <= 9'({$urandom});
    io_in_4_bits_param <= 2'({$urandom});
    io_in_4_bits_alias <= 2'({$urandom});
    io_in_5_valid <= $urandom_range(0, 1);
    io_in_5_bits_tag <= 31'({$urandom});
    io_in_5_bits_set <= 9'({$urandom});
    io_in_5_bits_param <= 2'({$urandom});
    io_in_5_bits_alias <= 2'({$urandom});
    io_in_6_valid <= $urandom_range(0, 1);
    io_in_6_bits_tag <= 31'({$urandom});
    io_in_6_bits_set <= 9'({$urandom});
    io_in_6_bits_param <= 2'({$urandom});
    io_in_6_bits_alias <= 2'({$urandom});
    io_in_7_valid <= $urandom_range(0, 1);
    io_in_7_bits_tag <= 31'({$urandom});
    io_in_7_bits_set <= 9'({$urandom});
    io_in_7_bits_param <= 2'({$urandom});
    io_in_7_bits_alias <= 2'({$urandom});
    io_in_8_valid <= $urandom_range(0, 1);
    io_in_8_bits_tag <= 31'({$urandom});
    io_in_8_bits_set <= 9'({$urandom});
    io_in_8_bits_param <= 2'({$urandom});
    io_in_8_bits_alias <= 2'({$urandom});
    io_in_9_valid <= $urandom_range(0, 1);
    io_in_9_bits_tag <= 31'({$urandom});
    io_in_9_bits_set <= 9'({$urandom});
    io_in_9_bits_param <= 2'({$urandom});
    io_in_9_bits_alias <= 2'({$urandom});
    io_in_10_valid <= $urandom_range(0, 1);
    io_in_10_bits_tag <= 31'({$urandom});
    io_in_10_bits_set <= 9'({$urandom});
    io_in_10_bits_param <= 2'({$urandom});
    io_in_10_bits_alias <= 2'({$urandom});
    io_in_11_valid <= $urandom_range(0, 1);
    io_in_11_bits_tag <= 31'({$urandom});
    io_in_11_bits_set <= 9'({$urandom});
    io_in_11_bits_param <= 2'({$urandom});
    io_in_11_bits_alias <= 2'({$urandom});
    io_in_12_valid <= $urandom_range(0, 1);
    io_in_12_bits_tag <= 31'({$urandom});
    io_in_12_bits_set <= 9'({$urandom});
    io_in_12_bits_param <= 2'({$urandom});
    io_in_12_bits_alias <= 2'({$urandom});
    io_in_13_valid <= $urandom_range(0, 1);
    io_in_13_bits_tag <= 31'({$urandom});
    io_in_13_bits_set <= 9'({$urandom});
    io_in_13_bits_param <= 2'({$urandom});
    io_in_13_bits_alias <= 2'({$urandom});
    io_in_14_valid <= $urandom_range(0, 1);
    io_in_14_bits_tag <= 31'({$urandom});
    io_in_14_bits_set <= 9'({$urandom});
    io_in_14_bits_param <= 2'({$urandom});
    io_in_14_bits_alias <= 2'({$urandom});
    io_in_15_valid <= $urandom_range(0, 1);
    io_in_15_bits_tag <= 31'({$urandom});
    io_in_15_bits_set <= 9'({$urandom});
    io_in_15_bits_param <= 2'({$urandom});
    io_in_15_bits_alias <= 2'({$urandom});
    io_out_ready <= $urandom_range(0, 1);
  endtask

  task automatic check_outputs();
    `CHECK(io_in_0_ready)
    `CHECK(io_in_1_ready)
    `CHECK(io_in_2_ready)
    `CHECK(io_in_3_ready)
    `CHECK(io_in_4_ready)
    `CHECK(io_in_5_ready)
    `CHECK(io_in_6_ready)
    `CHECK(io_in_7_ready)
    `CHECK(io_in_8_ready)
    `CHECK(io_in_9_ready)
    `CHECK(io_in_10_ready)
    `CHECK(io_in_11_ready)
    `CHECK(io_in_12_ready)
    `CHECK(io_in_13_ready)
    `CHECK(io_in_14_ready)
    `CHECK(io_in_15_ready)
    `CHECK(io_out_valid)
    `CHECK(io_out_bits_tag)
    `CHECK(io_out_bits_set)
    `CHECK(io_out_bits_opcode)
    `CHECK(io_out_bits_param)
    `CHECK(io_out_bits_alias)
  endtask

  initial begin
    if ($value$plusargs("NCYCLES=%d", NCYCLES)) begin end
    reset = 1'b1;
    io_in_0_valid = '0;
    io_in_0_bits_tag = '0;
    io_in_0_bits_set = '0;
    io_in_0_bits_param = '0;
    io_in_0_bits_alias = '0;
    io_in_1_valid = '0;
    io_in_1_bits_tag = '0;
    io_in_1_bits_set = '0;
    io_in_1_bits_param = '0;
    io_in_1_bits_alias = '0;
    io_in_2_valid = '0;
    io_in_2_bits_tag = '0;
    io_in_2_bits_set = '0;
    io_in_2_bits_param = '0;
    io_in_2_bits_alias = '0;
    io_in_3_valid = '0;
    io_in_3_bits_tag = '0;
    io_in_3_bits_set = '0;
    io_in_3_bits_param = '0;
    io_in_3_bits_alias = '0;
    io_in_4_valid = '0;
    io_in_4_bits_tag = '0;
    io_in_4_bits_set = '0;
    io_in_4_bits_param = '0;
    io_in_4_bits_alias = '0;
    io_in_5_valid = '0;
    io_in_5_bits_tag = '0;
    io_in_5_bits_set = '0;
    io_in_5_bits_param = '0;
    io_in_5_bits_alias = '0;
    io_in_6_valid = '0;
    io_in_6_bits_tag = '0;
    io_in_6_bits_set = '0;
    io_in_6_bits_param = '0;
    io_in_6_bits_alias = '0;
    io_in_7_valid = '0;
    io_in_7_bits_tag = '0;
    io_in_7_bits_set = '0;
    io_in_7_bits_param = '0;
    io_in_7_bits_alias = '0;
    io_in_8_valid = '0;
    io_in_8_bits_tag = '0;
    io_in_8_bits_set = '0;
    io_in_8_bits_param = '0;
    io_in_8_bits_alias = '0;
    io_in_9_valid = '0;
    io_in_9_bits_tag = '0;
    io_in_9_bits_set = '0;
    io_in_9_bits_param = '0;
    io_in_9_bits_alias = '0;
    io_in_10_valid = '0;
    io_in_10_bits_tag = '0;
    io_in_10_bits_set = '0;
    io_in_10_bits_param = '0;
    io_in_10_bits_alias = '0;
    io_in_11_valid = '0;
    io_in_11_bits_tag = '0;
    io_in_11_bits_set = '0;
    io_in_11_bits_param = '0;
    io_in_11_bits_alias = '0;
    io_in_12_valid = '0;
    io_in_12_bits_tag = '0;
    io_in_12_bits_set = '0;
    io_in_12_bits_param = '0;
    io_in_12_bits_alias = '0;
    io_in_13_valid = '0;
    io_in_13_bits_tag = '0;
    io_in_13_bits_set = '0;
    io_in_13_bits_param = '0;
    io_in_13_bits_alias = '0;
    io_in_14_valid = '0;
    io_in_14_bits_tag = '0;
    io_in_14_bits_set = '0;
    io_in_14_bits_param = '0;
    io_in_14_bits_alias = '0;
    io_in_15_valid = '0;
    io_in_15_bits_tag = '0;
    io_in_15_bits_set = '0;
    io_in_15_bits_param = '0;
    io_in_15_bits_alias = '0;
    io_out_ready = '0;
    repeat (6) @(posedge clock);
    reset = 1'b0;
    repeat (NCYCLES) begin
      @(negedge clock);
      drive_random_inputs();
      @(posedge clock);
      #1 check_outputs();
    end
    $display("FastArbiter_7 checks=%0d errors=%0d", checks, errors);
    if (errors == 0 && checks > 1000) begin
      $display("TEST PASSED");
      $finish;
    end
    $display("TEST FAILED");
    $fatal(1);
  end
endmodule
`undef CHECK
