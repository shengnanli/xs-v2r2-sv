// =============================================================================
// Arbiter5_MSHRAcquire —— 固定优先级仲裁器（xs_FixedPriorityArbiter_core 家族的一个变体）
//
// 本变体的参数与规模（按 G1 golden 现读，不从上一轮继承）：
//   入口数 NUM_IN = 5；载荷 WIDTH = 60 位，3 个字段：acquire_source=4b, acquire_address=48b, vSetIdx=8b；
//   端口 26 个 = 每路 ready/valid 共 10 根 + out_ready/out_valid 2 根
//                + 14 根 *_bits_* 载荷端口；
//   golden 模块体 = 纯组合 assign，无寄存器 / 无时钟 / 无子模块。
//   使用者：ICacheMissUnit：把 4 个取指 MSHR + 1 路预取的 Acquire 并成一路。
//   常量替换：前 4 路 golden 没有 acquire_source 端口，仲裁器替它们填该路下标常量，
//   只有最后一路用自己的端口值 —— 薄文件在拼载荷时填入。
//
// 结构：golden 同名端口表 -> 每路载荷按输出字段顺序 MSB 优先拼成 60 位 ->
//   按"优先级从高到低"MSB 优先拼成 in_bits -> 设参例化 xs_FixedPriorityArbiter_core
//   （仲裁语义与不变式都在 xs_FixedPriorityArbiter_core.sv 里讲）-> 拆包回输出端口。
// 自动生成：verif/ut/Arbiter2_ICacheMissReq/gen.py（读 G1 golden）—— 勿手改
// =============================================================================

module Arbiter5_MSHRAcquire(
  output        io_in_0_ready,
  input         io_in_0_valid,
  input  [47:0] io_in_0_bits_acquire_address,
  input  [7:0]  io_in_0_bits_vSetIdx,
  output        io_in_1_ready,
  input         io_in_1_valid,
  input  [47:0] io_in_1_bits_acquire_address,
  input  [7:0]  io_in_1_bits_vSetIdx,
  output        io_in_2_ready,
  input         io_in_2_valid,
  input  [47:0] io_in_2_bits_acquire_address,
  input  [7:0]  io_in_2_bits_vSetIdx,
  output        io_in_3_ready,
  input         io_in_3_valid,
  input  [47:0] io_in_3_bits_acquire_address,
  input  [7:0]  io_in_3_bits_vSetIdx,
  output        io_in_4_ready,
  input         io_in_4_valid,
  input  [3:0]  io_in_4_bits_acquire_source,
  input  [47:0] io_in_4_bits_acquire_address,
  input  [7:0]  io_in_4_bits_vSetIdx,
  input         io_out_ready,
  output        io_out_valid,
  output [3:0]  io_out_bits_acquire_source,
  output [47:0] io_out_bits_acquire_address,
  output [7:0]  io_out_bits_vSetIdx
);

  localparam int unsigned NUM_IN  = 5;
  localparam int unsigned WIDTH   = 60;

  // 每一路的载荷（下标 4 = 第 0 路 = 优先级最高，与 in_valid 位序一致）
  logic [WIDTH-1:0] way_bits [NUM_IN];
  assign way_bits[4] = {4'd0, io_in_0_bits_acquire_address, io_in_0_bits_vSetIdx};   // 第 0 路（优先级第 1 高）
  assign way_bits[3] = {4'd1, io_in_1_bits_acquire_address, io_in_1_bits_vSetIdx};   // 第 1 路（优先级第 2 高）
  assign way_bits[2] = {4'd2, io_in_2_bits_acquire_address, io_in_2_bits_vSetIdx};   // 第 2 路（优先级第 3 高）
  assign way_bits[1] = {4'd3, io_in_3_bits_acquire_address, io_in_3_bits_vSetIdx};   // 第 3 路（优先级第 4 高）
  assign way_bits[0] = {io_in_4_bits_acquire_source, io_in_4_bits_acquire_address, io_in_4_bits_vSetIdx};   // 第 4 路（优先级第 5 高）

  logic [NUM_IN*WIDTH-1:0] in_bits_flat;
  for (genvar k = 0; k < NUM_IN; k++) begin : g_pack
    assign in_bits_flat[k*WIDTH +: WIDTH] = way_bits[k];
  end

  logic [NUM_IN-1:0] in_valid_vec;
  logic [NUM_IN-1:0] in_ready_vec;
  assign in_valid_vec = {io_in_0_valid, io_in_1_valid, io_in_2_valid, io_in_3_valid, io_in_4_valid};
  assign {io_in_0_ready, io_in_1_ready, io_in_2_ready, io_in_3_ready, io_in_4_ready} = in_ready_vec;

  logic [WIDTH-1:0] out_bits_flat;

  xs_FixedPriorityArbiter_core #(
    .WIDTH            (WIDTH),
    .NUM_IN           (NUM_IN),
    // 端口表事实：$bits 只认端口声明，抄错位宽这些常量立刻跟着变
    .PORT_BITS_OUT    ($bits({io_out_bits_acquire_source, io_out_bits_acquire_address, io_out_bits_vSetIdx})),
    .PORT_BITS_LAST_IN($bits({io_in_4_bits_acquire_source, io_in_4_bits_acquire_address, io_in_4_bits_vSetIdx})),
    .GOLDEN_PORTS     (26),
    .GOLDEN_BITS_PORTS(14)
  ) u_core (
    .in_valid (in_valid_vec),
    .in_ready (in_ready_vec),
    .in_bits  (in_bits_flat),
    .out_ready(io_out_ready),
    .out_valid(io_out_valid),
    .out_bits (out_bits_flat)
  );

  assign {io_out_bits_acquire_source, io_out_bits_acquire_address, io_out_bits_vSetIdx} = out_bits_flat;

endmodule
