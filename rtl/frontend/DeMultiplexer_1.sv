// =============================================================================
// DeMultiplexer_1 —— 一入多出解复用器（xs_DeMultiplexer_core 家族的一个变体）
//
// 本变体的参数与规模（按 G1 golden 现读，不从上一轮继承）：
//   出口数 NUM_OUT = 10；广播载荷 WIDTH = 50 位，2 个字段：blkPaddr=42b, vSetIdx=8b；
//   chosen 端口：有，4 位 = clog2(10)；
//   端口 45 个 = in 的 ready/valid 2 根 + in 载荷 2 根
//                + 10 个出口 ×(ready/valid + 载荷 2 根) + chosen 1 根；
//   golden 模块体 = 纯组合 assign，无寄存器 / 无时钟 / 无子模块。
//   使用者：ICacheMissUnit：把预取 miss 投给 10 个预取 MSHR 中第一个空闲的。
//
// 结构：golden 同名端口表 -> 载荷拼成 50 位、out_ready 按"出口 0 在最高位"拼成
//   位图 -> 设参例化 xs_DeMultiplexer_core（分发语义与不变式都在
//   xs_DeMultiplexer_core.sv 里讲）-> 把广播出来的载荷与 valid 拆回各出口端口。
// 自动生成：verif/ut/DeMultiplexer/gen.py（读 G1 golden）—— 勿手改
// =============================================================================

module DeMultiplexer_1(
  output        io_in_ready,
  input         io_in_valid,
  input  [41:0] io_in_bits_blkPaddr,
  input  [7:0]  io_in_bits_vSetIdx,
  input         io_out_0_ready,
  output        io_out_0_valid,
  output [41:0] io_out_0_bits_blkPaddr,
  output [7:0]  io_out_0_bits_vSetIdx,
  input         io_out_1_ready,
  output        io_out_1_valid,
  output [41:0] io_out_1_bits_blkPaddr,
  output [7:0]  io_out_1_bits_vSetIdx,
  input         io_out_2_ready,
  output        io_out_2_valid,
  output [41:0] io_out_2_bits_blkPaddr,
  output [7:0]  io_out_2_bits_vSetIdx,
  input         io_out_3_ready,
  output        io_out_3_valid,
  output [41:0] io_out_3_bits_blkPaddr,
  output [7:0]  io_out_3_bits_vSetIdx,
  input         io_out_4_ready,
  output        io_out_4_valid,
  output [41:0] io_out_4_bits_blkPaddr,
  output [7:0]  io_out_4_bits_vSetIdx,
  input         io_out_5_ready,
  output        io_out_5_valid,
  output [41:0] io_out_5_bits_blkPaddr,
  output [7:0]  io_out_5_bits_vSetIdx,
  input         io_out_6_ready,
  output        io_out_6_valid,
  output [41:0] io_out_6_bits_blkPaddr,
  output [7:0]  io_out_6_bits_vSetIdx,
  input         io_out_7_ready,
  output        io_out_7_valid,
  output [41:0] io_out_7_bits_blkPaddr,
  output [7:0]  io_out_7_bits_vSetIdx,
  input         io_out_8_ready,
  output        io_out_8_valid,
  output [41:0] io_out_8_bits_blkPaddr,
  output [7:0]  io_out_8_bits_vSetIdx,
  input         io_out_9_ready,
  output        io_out_9_valid,
  output [41:0] io_out_9_bits_blkPaddr,
  output [7:0]  io_out_9_bits_vSetIdx,
  output [3:0]  io_chosen
);

  localparam int unsigned NUM_OUT = 10;
  localparam int unsigned WIDTH   = 50;

  logic [NUM_OUT-1:0]       out_ready_vec;
  logic [NUM_OUT-1:0]       out_valid_vec;
  logic [NUM_OUT*WIDTH-1:0] out_bits_flat;

  // 位序：出口 0 在最高位（与核里的优先级约定一致）
  assign out_ready_vec = {io_out_0_ready, io_out_1_ready, io_out_2_ready, io_out_3_ready, io_out_4_ready, io_out_5_ready, io_out_6_ready, io_out_7_ready, io_out_8_ready, io_out_9_ready};
  assign {io_out_0_valid, io_out_1_valid, io_out_2_valid, io_out_3_valid, io_out_4_valid, io_out_5_valid, io_out_6_valid, io_out_7_valid, io_out_8_valid, io_out_9_valid} = out_valid_vec;

  xs_DeMultiplexer_core #(
    .WIDTH         (WIDTH),
    .NUM_OUT       (NUM_OUT),
    .CHOSEN_W      (4),
    // 端口表事实：$bits 只认端口声明，抄错位宽这些常量立刻跟着变
    .PORT_BITS_IN  ($bits({io_in_bits_blkPaddr, io_in_bits_vSetIdx})),
    .PORT_BITS_OUT0($bits({io_out_0_bits_blkPaddr, io_out_0_bits_vSetIdx})),
    .HAS_CHOSEN    (1'b1),
    .GOLDEN_PORTS  (45),
    .GOLDEN_FIELDS (2)
  ) u_core (
    .in_valid (io_in_valid),
    .in_ready (io_in_ready),
    .in_bits  ({io_in_bits_blkPaddr, io_in_bits_vSetIdx}),
    .out_ready(out_ready_vec),
    .out_valid(out_valid_vec),
    .out_bits (out_bits_flat),
    .chosen   (io_chosen)
  );

  assign {io_out_0_bits_blkPaddr, io_out_0_bits_vSetIdx} = out_bits_flat[9*WIDTH +: WIDTH];   // 第 0 个出口
  assign {io_out_1_bits_blkPaddr, io_out_1_bits_vSetIdx} = out_bits_flat[8*WIDTH +: WIDTH];   // 第 1 个出口
  assign {io_out_2_bits_blkPaddr, io_out_2_bits_vSetIdx} = out_bits_flat[7*WIDTH +: WIDTH];   // 第 2 个出口
  assign {io_out_3_bits_blkPaddr, io_out_3_bits_vSetIdx} = out_bits_flat[6*WIDTH +: WIDTH];   // 第 3 个出口
  assign {io_out_4_bits_blkPaddr, io_out_4_bits_vSetIdx} = out_bits_flat[5*WIDTH +: WIDTH];   // 第 4 个出口
  assign {io_out_5_bits_blkPaddr, io_out_5_bits_vSetIdx} = out_bits_flat[4*WIDTH +: WIDTH];   // 第 5 个出口
  assign {io_out_6_bits_blkPaddr, io_out_6_bits_vSetIdx} = out_bits_flat[3*WIDTH +: WIDTH];   // 第 6 个出口
  assign {io_out_7_bits_blkPaddr, io_out_7_bits_vSetIdx} = out_bits_flat[2*WIDTH +: WIDTH];   // 第 7 个出口
  assign {io_out_8_bits_blkPaddr, io_out_8_bits_vSetIdx} = out_bits_flat[1*WIDTH +: WIDTH];   // 第 8 个出口
  assign {io_out_9_bits_blkPaddr, io_out_9_bits_vSetIdx} = out_bits_flat[0*WIDTH +: WIDTH];   // 第 9 个出口

endmodule
