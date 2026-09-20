// =============================================================================
// RRArbiterInit_12.sv —— 轮转仲裁器家族薄 wrapper：PTWNewFilter 3 路页表遍历请求仲裁（家族里最窄的一路）
//
// 本变体规模：仲裁宽度 N=3，payload 打平 W=40 位（2 个字段），chosen/lastGrant 2 位。
//   端口面：in_ready 输出有、out_ready 输入有、io_chosen 输出无。
//   例化者：PTWNewFilter.sv。
//
// 本文件只做参数与端口对位；仲裁逻辑核在 rtl/common/RRArbiterInit.sv
// （模块 xs_RRArbiterInit_core），核体全家族共一份。本文件由
// verif/ut/RRArbiterInitVariants/gen.py 生成，勿手改。
//
// 设计源：rocket-chip util/Arbiters.scala (class LockingRRArbiter)
// golden 对照：G1-canonical/golden-rtl/RRArbiterInit_12.sv
// =============================================================================
package rrarbiterinit_12_pkg;
  // payload 字段表：顺序 = golden io_out_bits_* 的端口顺序，靠前者占高位。
  // 打平成 40 位送进仲裁核，核只按 chosen 选一路，不看字段结构。
  typedef struct packed {
    logic [37:0] vpn;
    logic [1:0]  s2xlate;
  } payload_t;
endpackage

module RRArbiterInit_12 import rrarbiterinit_12_pkg::*; (
  input         clock,
  input         reset,
  output        io_in_0_ready,
  input         io_in_0_valid,
  input  [37:0] io_in_0_bits_vpn,
  input  [1:0]  io_in_0_bits_s2xlate,
  output        io_in_1_ready,
  input         io_in_1_valid,
  input  [37:0] io_in_1_bits_vpn,
  input  [1:0]  io_in_1_bits_s2xlate,
  output        io_in_2_ready,
  input         io_in_2_valid,
  input  [37:0] io_in_2_bits_vpn,
  input  [1:0]  io_in_2_bits_s2xlate,
  input         io_out_ready,
  output        io_out_valid,
  output [37:0] io_out_bits_vpn,
  output [1:0]  io_out_bits_s2xlate
);
  localparam int N = 3;
  localparam int W = $bits(payload_t);

  // 打包：每一路按字段表顺序拼成 W 位（下面的拆包用同一张表，反过来一次）。
  payload_t [N-1:0] in_payload;
  assign in_payload[0] = {
    io_in_0_bits_vpn,
    io_in_0_bits_s2xlate};
  assign in_payload[1] = {
    io_in_1_bits_vpn,
    io_in_1_bits_s2xlate};
  assign in_payload[2] = {
    io_in_2_bits_vpn,
    io_in_2_bits_s2xlate};

  payload_t out_payload;
  xs_RRArbiterInit_core #(.N(N), .W(W)) u_core (
    .clock     (clock),
    .reset     (reset),
    .in_valid  ({io_in_2_valid, io_in_1_valid, io_in_0_valid}),
    .in_bits   (in_payload),
    .in_ready  ({io_in_2_ready, io_in_1_ready, io_in_0_ready}),
    .out_ready (io_out_ready),
    .out_valid (io_out_valid),
    .out_bits  (out_payload),
    .chosen    ()                  // 本变体 golden 无 io_chosen 输出端口
  );

  // 拆包：与上面的打包共用同一张字段表。
  assign io_out_bits_vpn = out_payload.vpn;
  assign io_out_bits_s2xlate = out_payload.s2xlate;
endmodule
