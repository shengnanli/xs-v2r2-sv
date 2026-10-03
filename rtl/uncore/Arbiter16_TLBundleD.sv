// =============================================================================
// Arbiter16_TLBundleD —— MMIOBridge 的 D 通道汇流：16 个 MMIO 表项的 TileLink 应答并成一路
//
// 在哪一层：L2（TL2CHICoupledL2）里的 MMIOBridge 把核发来的 MMIO/uncache 请求分给 16 个表项，
//   各表项拿到 CHI 应答后把 TileLink D 拍（AccessAck / AccessAckData）回给核；
//   `arb(entries.map(_.io.resp), bus.d, Some("mmio_channel_D"))`（coupledL2/tl2chi/MMIOBridge.scala）
//   用 chisel3 Arbiter 把这 16 路并到 bus.d 上（实例 mmio_channel_D_arb）。
// 语义：Chisel Arbiter —— 固定优先级、编号小者优先、纯组合、无锁定：
//   out_valid = 任一路 valid；in_ready[k] = 比 k 编号小的都没在请求 && out_ready（in_ready[0] = out_ready）；
//   载荷取优先级最高那一路；一路都没请求时出口给第 15 路的载荷（golden 三元链的兜底分支）。
// 结构：golden 端口 -> 拼成 16 路等宽载荷 -> 共享核 xs_FixedPriorityArbiter_core（rtl/frontend，已签核）-> 拆回端口。
//   D 拍里 TileLink 的 param/sink 字段在这条通路上恒定被 firtool 删掉，所以每路载荷只有 6 个字段、77 位。
// golden 对照：G1-canonical/golden-rtl/Arbiter16_TLBundleD.sv（450 行 / 136 端口）
// =============================================================================
module Arbiter16_TLBundleD (
  output logic io_in_0_ready,
  input  logic io_in_0_valid,
  input  logic [3:0] io_in_0_bits_opcode,
  input  logic [1:0] io_in_0_bits_size,
  input  logic [4:0] io_in_0_bits_source,
  input  logic io_in_0_bits_denied,
  input  logic [63:0] io_in_0_bits_data,
  input  logic io_in_0_bits_corrupt,
  output logic io_in_1_ready,
  input  logic io_in_1_valid,
  input  logic [3:0] io_in_1_bits_opcode,
  input  logic [1:0] io_in_1_bits_size,
  input  logic [4:0] io_in_1_bits_source,
  input  logic io_in_1_bits_denied,
  input  logic [63:0] io_in_1_bits_data,
  input  logic io_in_1_bits_corrupt,
  output logic io_in_2_ready,
  input  logic io_in_2_valid,
  input  logic [3:0] io_in_2_bits_opcode,
  input  logic [1:0] io_in_2_bits_size,
  input  logic [4:0] io_in_2_bits_source,
  input  logic io_in_2_bits_denied,
  input  logic [63:0] io_in_2_bits_data,
  input  logic io_in_2_bits_corrupt,
  output logic io_in_3_ready,
  input  logic io_in_3_valid,
  input  logic [3:0] io_in_3_bits_opcode,
  input  logic [1:0] io_in_3_bits_size,
  input  logic [4:0] io_in_3_bits_source,
  input  logic io_in_3_bits_denied,
  input  logic [63:0] io_in_3_bits_data,
  input  logic io_in_3_bits_corrupt,
  output logic io_in_4_ready,
  input  logic io_in_4_valid,
  input  logic [3:0] io_in_4_bits_opcode,
  input  logic [1:0] io_in_4_bits_size,
  input  logic [4:0] io_in_4_bits_source,
  input  logic io_in_4_bits_denied,
  input  logic [63:0] io_in_4_bits_data,
  input  logic io_in_4_bits_corrupt,
  output logic io_in_5_ready,
  input  logic io_in_5_valid,
  input  logic [3:0] io_in_5_bits_opcode,
  input  logic [1:0] io_in_5_bits_size,
  input  logic [4:0] io_in_5_bits_source,
  input  logic io_in_5_bits_denied,
  input  logic [63:0] io_in_5_bits_data,
  input  logic io_in_5_bits_corrupt,
  output logic io_in_6_ready,
  input  logic io_in_6_valid,
  input  logic [3:0] io_in_6_bits_opcode,
  input  logic [1:0] io_in_6_bits_size,
  input  logic [4:0] io_in_6_bits_source,
  input  logic io_in_6_bits_denied,
  input  logic [63:0] io_in_6_bits_data,
  input  logic io_in_6_bits_corrupt,
  output logic io_in_7_ready,
  input  logic io_in_7_valid,
  input  logic [3:0] io_in_7_bits_opcode,
  input  logic [1:0] io_in_7_bits_size,
  input  logic [4:0] io_in_7_bits_source,
  input  logic io_in_7_bits_denied,
  input  logic [63:0] io_in_7_bits_data,
  input  logic io_in_7_bits_corrupt,
  output logic io_in_8_ready,
  input  logic io_in_8_valid,
  input  logic [3:0] io_in_8_bits_opcode,
  input  logic [1:0] io_in_8_bits_size,
  input  logic [4:0] io_in_8_bits_source,
  input  logic io_in_8_bits_denied,
  input  logic [63:0] io_in_8_bits_data,
  input  logic io_in_8_bits_corrupt,
  output logic io_in_9_ready,
  input  logic io_in_9_valid,
  input  logic [3:0] io_in_9_bits_opcode,
  input  logic [1:0] io_in_9_bits_size,
  input  logic [4:0] io_in_9_bits_source,
  input  logic io_in_9_bits_denied,
  input  logic [63:0] io_in_9_bits_data,
  input  logic io_in_9_bits_corrupt,
  output logic io_in_10_ready,
  input  logic io_in_10_valid,
  input  logic [3:0] io_in_10_bits_opcode,
  input  logic [1:0] io_in_10_bits_size,
  input  logic [4:0] io_in_10_bits_source,
  input  logic io_in_10_bits_denied,
  input  logic [63:0] io_in_10_bits_data,
  input  logic io_in_10_bits_corrupt,
  output logic io_in_11_ready,
  input  logic io_in_11_valid,
  input  logic [3:0] io_in_11_bits_opcode,
  input  logic [1:0] io_in_11_bits_size,
  input  logic [4:0] io_in_11_bits_source,
  input  logic io_in_11_bits_denied,
  input  logic [63:0] io_in_11_bits_data,
  input  logic io_in_11_bits_corrupt,
  output logic io_in_12_ready,
  input  logic io_in_12_valid,
  input  logic [3:0] io_in_12_bits_opcode,
  input  logic [1:0] io_in_12_bits_size,
  input  logic [4:0] io_in_12_bits_source,
  input  logic io_in_12_bits_denied,
  input  logic [63:0] io_in_12_bits_data,
  input  logic io_in_12_bits_corrupt,
  output logic io_in_13_ready,
  input  logic io_in_13_valid,
  input  logic [3:0] io_in_13_bits_opcode,
  input  logic [1:0] io_in_13_bits_size,
  input  logic [4:0] io_in_13_bits_source,
  input  logic io_in_13_bits_denied,
  input  logic [63:0] io_in_13_bits_data,
  input  logic io_in_13_bits_corrupt,
  output logic io_in_14_ready,
  input  logic io_in_14_valid,
  input  logic [3:0] io_in_14_bits_opcode,
  input  logic [1:0] io_in_14_bits_size,
  input  logic [4:0] io_in_14_bits_source,
  input  logic io_in_14_bits_denied,
  input  logic [63:0] io_in_14_bits_data,
  input  logic io_in_14_bits_corrupt,
  output logic io_in_15_ready,
  input  logic io_in_15_valid,
  input  logic [3:0] io_in_15_bits_opcode,
  input  logic [1:0] io_in_15_bits_size,
  input  logic [4:0] io_in_15_bits_source,
  input  logic io_in_15_bits_denied,
  input  logic [63:0] io_in_15_bits_data,
  input  logic io_in_15_bits_corrupt,
  input  logic io_out_ready,
  output logic io_out_valid,
  output logic [3:0] io_out_bits_opcode,
  output logic [1:0] io_out_bits_size,
  output logic [4:0] io_out_bits_source,
  output logic io_out_bits_denied,
  output logic [63:0] io_out_bits_data,
  output logic io_out_bits_corrupt
);

  localparam int unsigned NUM_IN = 16;
  localparam int unsigned WIDTH  = 77;   // 每路载荷：opcode(4) + size(2) + source(5) + denied(1) + data(64) + corrupt(1)

  // ---------------------------------------------------------------------------
  // 1. 入口拼接：位 NUM_IN-1 = 第 0 路（优先级最高），与核的 in_valid 位序一致；
  //    每路载荷按 io_out_bits_* 的端口顺序 MSB 优先拼，缺端口的字段在原位置填常量
  // ---------------------------------------------------------------------------
  logic [NUM_IN-1:0]       in_valid_vec;
  logic [NUM_IN-1:0]       in_ready_vec;
  logic [NUM_IN*WIDTH-1:0] in_bits_flat;
  logic [WIDTH-1:0]        out_bits_flat;

  assign in_valid_vec = {io_in_0_valid, io_in_1_valid, io_in_2_valid, io_in_3_valid, io_in_4_valid, io_in_5_valid, io_in_6_valid, io_in_7_valid, io_in_8_valid, io_in_9_valid, io_in_10_valid, io_in_11_valid, io_in_12_valid, io_in_13_valid, io_in_14_valid, io_in_15_valid};
  assign in_bits_flat = {
    {io_in_0_bits_opcode,
     io_in_0_bits_size,
     io_in_0_bits_source,
     io_in_0_bits_denied,
     io_in_0_bits_data,
     io_in_0_bits_corrupt},
    {io_in_1_bits_opcode,
     io_in_1_bits_size,
     io_in_1_bits_source,
     io_in_1_bits_denied,
     io_in_1_bits_data,
     io_in_1_bits_corrupt},
    {io_in_2_bits_opcode,
     io_in_2_bits_size,
     io_in_2_bits_source,
     io_in_2_bits_denied,
     io_in_2_bits_data,
     io_in_2_bits_corrupt},
    {io_in_3_bits_opcode,
     io_in_3_bits_size,
     io_in_3_bits_source,
     io_in_3_bits_denied,
     io_in_3_bits_data,
     io_in_3_bits_corrupt},
    {io_in_4_bits_opcode,
     io_in_4_bits_size,
     io_in_4_bits_source,
     io_in_4_bits_denied,
     io_in_4_bits_data,
     io_in_4_bits_corrupt},
    {io_in_5_bits_opcode,
     io_in_5_bits_size,
     io_in_5_bits_source,
     io_in_5_bits_denied,
     io_in_5_bits_data,
     io_in_5_bits_corrupt},
    {io_in_6_bits_opcode,
     io_in_6_bits_size,
     io_in_6_bits_source,
     io_in_6_bits_denied,
     io_in_6_bits_data,
     io_in_6_bits_corrupt},
    {io_in_7_bits_opcode,
     io_in_7_bits_size,
     io_in_7_bits_source,
     io_in_7_bits_denied,
     io_in_7_bits_data,
     io_in_7_bits_corrupt},
    {io_in_8_bits_opcode,
     io_in_8_bits_size,
     io_in_8_bits_source,
     io_in_8_bits_denied,
     io_in_8_bits_data,
     io_in_8_bits_corrupt},
    {io_in_9_bits_opcode,
     io_in_9_bits_size,
     io_in_9_bits_source,
     io_in_9_bits_denied,
     io_in_9_bits_data,
     io_in_9_bits_corrupt},
    {io_in_10_bits_opcode,
     io_in_10_bits_size,
     io_in_10_bits_source,
     io_in_10_bits_denied,
     io_in_10_bits_data,
     io_in_10_bits_corrupt},
    {io_in_11_bits_opcode,
     io_in_11_bits_size,
     io_in_11_bits_source,
     io_in_11_bits_denied,
     io_in_11_bits_data,
     io_in_11_bits_corrupt},
    {io_in_12_bits_opcode,
     io_in_12_bits_size,
     io_in_12_bits_source,
     io_in_12_bits_denied,
     io_in_12_bits_data,
     io_in_12_bits_corrupt},
    {io_in_13_bits_opcode,
     io_in_13_bits_size,
     io_in_13_bits_source,
     io_in_13_bits_denied,
     io_in_13_bits_data,
     io_in_13_bits_corrupt},
    {io_in_14_bits_opcode,
     io_in_14_bits_size,
     io_in_14_bits_source,
     io_in_14_bits_denied,
     io_in_14_bits_data,
     io_in_14_bits_corrupt},
    {io_in_15_bits_opcode,
     io_in_15_bits_size,
     io_in_15_bits_source,
     io_in_15_bits_denied,
     io_in_15_bits_data,
     io_in_15_bits_corrupt}
  };

  // ---------------------------------------------------------------------------
  // 2. 仲裁核（固定优先级，纯组合；语义见 xs_FixedPriorityArbiter_core 文件头）
  // ---------------------------------------------------------------------------
  xs_FixedPriorityArbiter_core #(
    .WIDTH            (WIDTH),
    .NUM_IN           (NUM_IN),
    .PORT_BITS_OUT    ($bits({io_out_bits_opcode, io_out_bits_size, io_out_bits_source, io_out_bits_denied, io_out_bits_data, io_out_bits_corrupt})),
    .PORT_BITS_LAST_IN($bits({io_in_15_bits_opcode, io_in_15_bits_size, io_in_15_bits_source, io_in_15_bits_denied, io_in_15_bits_data, io_in_15_bits_corrupt})),
    .GOLDEN_PORTS     (136),
    .GOLDEN_BITS_PORTS(102)
  ) u_core (
    .in_valid (in_valid_vec),
    .in_ready (in_ready_vec),
    .in_bits  (in_bits_flat),
    .out_ready(io_out_ready),
    .out_valid(io_out_valid),
    .out_bits (out_bits_flat)
  );

  // ---------------------------------------------------------------------------
  // 3. 出口拆分与各路 ready
  // ---------------------------------------------------------------------------
  assign io_in_0_ready = in_ready_vec[NUM_IN-1-0];
  assign io_in_1_ready = in_ready_vec[NUM_IN-1-1];
  assign io_in_2_ready = in_ready_vec[NUM_IN-1-2];
  assign io_in_3_ready = in_ready_vec[NUM_IN-1-3];
  assign io_in_4_ready = in_ready_vec[NUM_IN-1-4];
  assign io_in_5_ready = in_ready_vec[NUM_IN-1-5];
  assign io_in_6_ready = in_ready_vec[NUM_IN-1-6];
  assign io_in_7_ready = in_ready_vec[NUM_IN-1-7];
  assign io_in_8_ready = in_ready_vec[NUM_IN-1-8];
  assign io_in_9_ready = in_ready_vec[NUM_IN-1-9];
  assign io_in_10_ready = in_ready_vec[NUM_IN-1-10];
  assign io_in_11_ready = in_ready_vec[NUM_IN-1-11];
  assign io_in_12_ready = in_ready_vec[NUM_IN-1-12];
  assign io_in_13_ready = in_ready_vec[NUM_IN-1-13];
  assign io_in_14_ready = in_ready_vec[NUM_IN-1-14];
  assign io_in_15_ready = in_ready_vec[NUM_IN-1-15];
  assign {io_out_bits_opcode,
          io_out_bits_size,
          io_out_bits_source,
          io_out_bits_denied,
          io_out_bits_data,
          io_out_bits_corrupt} = out_bits_flat;
endmodule
