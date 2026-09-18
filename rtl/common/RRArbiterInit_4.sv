// =============================================================================
// RRArbiterInit_4.sv —— 轮转仲裁器家族薄 wrapper：LLPTW 6 个条目发往 Bitmap 的查询仲裁
//
// 本变体规模：仲裁宽度 N=6，payload 打平 W=81 位（5 个字段），chosen/lastGrant 3 位。
//   端口面：in_ready 输出★无★、out_ready 输入有、io_chosen 输出有。
//   例化者：LLPTW.sv。
//
// 本文件只做参数与端口对位；仲裁逻辑核在 rtl/common/RRArbiterInit.sv
// （模块 xs_RRArbiterInit_core），核体全家族共一份。本文件由
// verif/ut/RRArbiterInitVariants/gen.py 生成，勿手改。
//
// 设计源：rocket-chip util/Arbiters.scala (class LockingRRArbiter)
// golden 对照：G1-canonical/golden-rtl/RRArbiterInit_4.sv
// =============================================================================
package rrarbiterinit_4_pkg;
  // payload 字段表：顺序 = golden io_out_bits_* 的端口顺序，靠前者占高位。
  // 打平成 81 位送进仲裁核，核只按 chosen 选一路，不看字段结构。
  typedef struct packed {
    logic [35:0] bmppn;
    logic [37:0] vpn;
    logic [3:0]  way_info;
    logic [1:0]  s2xlate;
    logic        n;
  } payload_t;
endpackage

module RRArbiterInit_4 import rrarbiterinit_4_pkg::*; (
  input         clock,
  input         reset,
  input         io_in_0_valid,
  input  [35:0] io_in_0_bits_bmppn,
  input  [37:0] io_in_0_bits_vpn,
  input  [3:0]  io_in_0_bits_way_info,
  input  [1:0]  io_in_0_bits_s2xlate,
  input         io_in_0_bits_n,
  input         io_in_1_valid,
  input  [35:0] io_in_1_bits_bmppn,
  input  [37:0] io_in_1_bits_vpn,
  input  [3:0]  io_in_1_bits_way_info,
  input  [1:0]  io_in_1_bits_s2xlate,
  input         io_in_1_bits_n,
  input         io_in_2_valid,
  input  [35:0] io_in_2_bits_bmppn,
  input  [37:0] io_in_2_bits_vpn,
  input  [3:0]  io_in_2_bits_way_info,
  input  [1:0]  io_in_2_bits_s2xlate,
  input         io_in_2_bits_n,
  input         io_in_3_valid,
  input  [35:0] io_in_3_bits_bmppn,
  input  [37:0] io_in_3_bits_vpn,
  input  [3:0]  io_in_3_bits_way_info,
  input  [1:0]  io_in_3_bits_s2xlate,
  input         io_in_3_bits_n,
  input         io_in_4_valid,
  input  [35:0] io_in_4_bits_bmppn,
  input  [37:0] io_in_4_bits_vpn,
  input  [3:0]  io_in_4_bits_way_info,
  input  [1:0]  io_in_4_bits_s2xlate,
  input         io_in_4_bits_n,
  input         io_in_5_valid,
  input  [35:0] io_in_5_bits_bmppn,
  input  [37:0] io_in_5_bits_vpn,
  input  [3:0]  io_in_5_bits_way_info,
  input  [1:0]  io_in_5_bits_s2xlate,
  input         io_in_5_bits_n,
  input         io_out_ready,
  output        io_out_valid,
  output [35:0] io_out_bits_bmppn,
  output [37:0] io_out_bits_vpn,
  output [3:0]  io_out_bits_way_info,
  output [1:0]  io_out_bits_s2xlate,
  output        io_out_bits_n,
  output [2:0]  io_chosen
);
  localparam int N = 6;
  localparam int W = $bits(payload_t);

  // 打包：每一路按字段表顺序拼成 W 位（下面的拆包用同一张表，反过来一次）。
  payload_t [N-1:0] in_payload;
  assign in_payload[0] = {
    io_in_0_bits_bmppn,
    io_in_0_bits_vpn,
    io_in_0_bits_way_info,
    io_in_0_bits_s2xlate,
    io_in_0_bits_n};
  assign in_payload[1] = {
    io_in_1_bits_bmppn,
    io_in_1_bits_vpn,
    io_in_1_bits_way_info,
    io_in_1_bits_s2xlate,
    io_in_1_bits_n};
  assign in_payload[2] = {
    io_in_2_bits_bmppn,
    io_in_2_bits_vpn,
    io_in_2_bits_way_info,
    io_in_2_bits_s2xlate,
    io_in_2_bits_n};
  assign in_payload[3] = {
    io_in_3_bits_bmppn,
    io_in_3_bits_vpn,
    io_in_3_bits_way_info,
    io_in_3_bits_s2xlate,
    io_in_3_bits_n};
  assign in_payload[4] = {
    io_in_4_bits_bmppn,
    io_in_4_bits_vpn,
    io_in_4_bits_way_info,
    io_in_4_bits_s2xlate,
    io_in_4_bits_n};
  assign in_payload[5] = {
    io_in_5_bits_bmppn,
    io_in_5_bits_vpn,
    io_in_5_bits_way_info,
    io_in_5_bits_s2xlate,
    io_in_5_bits_n};

  payload_t out_payload;
  xs_RRArbiterInit_core #(.N(N), .W(W)) u_core (
    .clock     (clock),
    .reset     (reset),
    .in_valid  ({io_in_5_valid, io_in_4_valid, io_in_3_valid, io_in_2_valid,
                 io_in_1_valid, io_in_0_valid}),
    .in_bits   (in_payload),
    .in_ready  (),                 // 本变体 golden 无 in_ready 输出端口
    .out_ready (io_out_ready),
    .out_valid (io_out_valid),
    .out_bits  (out_payload),
    .chosen    (io_chosen)
  );

  // 拆包：与上面的打包共用同一张字段表。
  assign io_out_bits_bmppn = out_payload.bmppn;
  assign io_out_bits_vpn = out_payload.vpn;
  assign io_out_bits_way_info = out_payload.way_info;
  assign io_out_bits_s2xlate = out_payload.s2xlate;
  assign io_out_bits_n = out_payload.n;
endmodule
