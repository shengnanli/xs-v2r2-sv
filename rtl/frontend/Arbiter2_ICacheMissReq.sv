// =============================================================================
// Arbiter2_ICacheMissReq —— 固定优先级仲裁器（xs_FixedPriorityArbiter_core 家族的一个变体）
//
// 本变体的参数与规模（按 G1 golden 现读，不从上一轮继承）：
//   入口数 NUM_IN = 2；载荷 WIDTH = 50 位，2 个字段：blkPaddr=42b, vSetIdx=8b；
//   端口 12 个 = 每路 ready/valid 共 4 根 + out_ready/out_valid 2 根
//                + 6 根 *_bits_* 载荷端口；
//   golden 模块体 = 纯组合 assign，无寄存器 / 无时钟 / 无子模块。
//   使用者：ICacheMainPipe 与 IPrefetchPipe 各一处：把两路 miss 请求并成一路。
//
// 结构：golden 同名端口表 -> 每路载荷按输出字段顺序 MSB 优先拼成 50 位 ->
//   按"优先级从高到低"MSB 优先拼成 in_bits -> 设参例化 xs_FixedPriorityArbiter_core
//   （仲裁语义与不变式都在 xs_FixedPriorityArbiter_core.sv 里讲）-> 拆包回输出端口。
// 自动生成：verif/ut/Arbiter2_ICacheMissReq/gen.py（读 G1 golden）—— 勿手改
// =============================================================================

module Arbiter2_ICacheMissReq(
  output        io_in_0_ready,
  input         io_in_0_valid,
  input  [41:0] io_in_0_bits_blkPaddr,
  input  [7:0]  io_in_0_bits_vSetIdx,
  output        io_in_1_ready,
  input         io_in_1_valid,
  input  [41:0] io_in_1_bits_blkPaddr,
  input  [7:0]  io_in_1_bits_vSetIdx,
  input         io_out_ready,
  output        io_out_valid,
  output [41:0] io_out_bits_blkPaddr,
  output [7:0]  io_out_bits_vSetIdx
);

  localparam int unsigned NUM_IN  = 2;
  localparam int unsigned WIDTH   = 50;

  // 每一路的载荷（下标 1 = 第 0 路 = 优先级最高，与 in_valid 位序一致）
  logic [WIDTH-1:0] way_bits [NUM_IN];
  assign way_bits[1] = {io_in_0_bits_blkPaddr, io_in_0_bits_vSetIdx};   // 第 0 路（优先级第 1 高）
  assign way_bits[0] = {io_in_1_bits_blkPaddr, io_in_1_bits_vSetIdx};   // 第 1 路（优先级第 2 高）

  logic [NUM_IN*WIDTH-1:0] in_bits_flat;
  for (genvar k = 0; k < NUM_IN; k++) begin : g_pack
    assign in_bits_flat[k*WIDTH +: WIDTH] = way_bits[k];
  end

  logic [NUM_IN-1:0] in_valid_vec;
  logic [NUM_IN-1:0] in_ready_vec;
  assign in_valid_vec = {io_in_0_valid, io_in_1_valid};
  assign {io_in_0_ready, io_in_1_ready} = in_ready_vec;

  logic [WIDTH-1:0] out_bits_flat;

  xs_FixedPriorityArbiter_core #(
    .WIDTH            (WIDTH),
    .NUM_IN           (NUM_IN),
    // 端口表事实：$bits 只认端口声明，抄错位宽这些常量立刻跟着变
    .PORT_BITS_OUT    ($bits({io_out_bits_blkPaddr, io_out_bits_vSetIdx})),
    .PORT_BITS_LAST_IN($bits({io_in_1_bits_blkPaddr, io_in_1_bits_vSetIdx})),
    .GOLDEN_PORTS     (12),
    .GOLDEN_BITS_PORTS(6)
  ) u_core (
    .in_valid (in_valid_vec),
    .in_ready (in_ready_vec),
    .in_bits  (in_bits_flat),
    .out_ready(io_out_ready),
    .out_valid(io_out_valid),
    .out_bits (out_bits_flat)
  );

  assign {io_out_bits_blkPaddr, io_out_bits_vSetIdx} = out_bits_flat;

endmodule
