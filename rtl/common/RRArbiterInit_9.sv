// =============================================================================
// RRArbiterInit_9.sv —— 轮转仲裁器家族薄 wrapper：多级预取过滤器 16 路 {addr, source} 请求仲裁
//
// 本变体规模：仲裁宽度 N=16，payload 打平 W=53 位（2 个字段），chosen/lastGrant 4 位。
//   端口面：in_ready 输出★无★、out_ready 输入★无★、io_chosen 输出有。
//   （golden 里 io_out_ready 被常量 1 折掉了，所以端口表里没有它；本文件给核接 1'b1。）
//   例化者：MutiLevelPrefetchFilter.sv。
//
// 本文件只做参数与端口对位；仲裁逻辑核在 rtl/common/RRArbiterInit.sv
// （模块 xs_RRArbiterInit_core），核体全家族共一份。本文件由
// verif/ut/RRArbiterInitVariants/gen.py 生成，勿手改。
//
// 设计源：rocket-chip util/Arbiters.scala (class LockingRRArbiter)
// golden 对照：G1-canonical/golden-rtl/RRArbiterInit_9.sv
// =============================================================================
package rrarbiterinit_9_pkg;
  // payload 字段表：顺序 = golden io_out_bits_* 的端口顺序，靠前者占高位。
  // 打平成 53 位送进仲裁核，核只按 chosen 选一路，不看字段结构。
  typedef struct packed {
    logic [47:0] req_addr;
    logic [4:0]  req_source;
  } payload_t;
endpackage

module RRArbiterInit_9 import rrarbiterinit_9_pkg::*; (
  input         clock,
  input         reset,
  input         io_in_0_valid,
  input  [47:0] io_in_0_bits_req_addr,
  input  [4:0]  io_in_0_bits_req_source,
  input         io_in_1_valid,
  input  [47:0] io_in_1_bits_req_addr,
  input  [4:0]  io_in_1_bits_req_source,
  input         io_in_2_valid,
  input  [47:0] io_in_2_bits_req_addr,
  input  [4:0]  io_in_2_bits_req_source,
  input         io_in_3_valid,
  input  [47:0] io_in_3_bits_req_addr,
  input  [4:0]  io_in_3_bits_req_source,
  input         io_in_4_valid,
  input  [47:0] io_in_4_bits_req_addr,
  input  [4:0]  io_in_4_bits_req_source,
  input         io_in_5_valid,
  input  [47:0] io_in_5_bits_req_addr,
  input  [4:0]  io_in_5_bits_req_source,
  input         io_in_6_valid,
  input  [47:0] io_in_6_bits_req_addr,
  input  [4:0]  io_in_6_bits_req_source,
  input         io_in_7_valid,
  input  [47:0] io_in_7_bits_req_addr,
  input  [4:0]  io_in_7_bits_req_source,
  input         io_in_8_valid,
  input  [47:0] io_in_8_bits_req_addr,
  input  [4:0]  io_in_8_bits_req_source,
  input         io_in_9_valid,
  input  [47:0] io_in_9_bits_req_addr,
  input  [4:0]  io_in_9_bits_req_source,
  input         io_in_10_valid,
  input  [47:0] io_in_10_bits_req_addr,
  input  [4:0]  io_in_10_bits_req_source,
  input         io_in_11_valid,
  input  [47:0] io_in_11_bits_req_addr,
  input  [4:0]  io_in_11_bits_req_source,
  input         io_in_12_valid,
  input  [47:0] io_in_12_bits_req_addr,
  input  [4:0]  io_in_12_bits_req_source,
  input         io_in_13_valid,
  input  [47:0] io_in_13_bits_req_addr,
  input  [4:0]  io_in_13_bits_req_source,
  input         io_in_14_valid,
  input  [47:0] io_in_14_bits_req_addr,
  input  [4:0]  io_in_14_bits_req_source,
  input         io_in_15_valid,
  input  [47:0] io_in_15_bits_req_addr,
  input  [4:0]  io_in_15_bits_req_source,
  output        io_out_valid,
  output [47:0] io_out_bits_req_addr,
  output [4:0]  io_out_bits_req_source,
  output [3:0]  io_chosen
);
  localparam int N = 16;
  localparam int W = $bits(payload_t);

  // 打包：每一路按字段表顺序拼成 W 位（下面的拆包用同一张表，反过来一次）。
  payload_t [N-1:0] in_payload;
  assign in_payload[0] = {
    io_in_0_bits_req_addr,
    io_in_0_bits_req_source};
  assign in_payload[1] = {
    io_in_1_bits_req_addr,
    io_in_1_bits_req_source};
  assign in_payload[2] = {
    io_in_2_bits_req_addr,
    io_in_2_bits_req_source};
  assign in_payload[3] = {
    io_in_3_bits_req_addr,
    io_in_3_bits_req_source};
  assign in_payload[4] = {
    io_in_4_bits_req_addr,
    io_in_4_bits_req_source};
  assign in_payload[5] = {
    io_in_5_bits_req_addr,
    io_in_5_bits_req_source};
  assign in_payload[6] = {
    io_in_6_bits_req_addr,
    io_in_6_bits_req_source};
  assign in_payload[7] = {
    io_in_7_bits_req_addr,
    io_in_7_bits_req_source};
  assign in_payload[8] = {
    io_in_8_bits_req_addr,
    io_in_8_bits_req_source};
  assign in_payload[9] = {
    io_in_9_bits_req_addr,
    io_in_9_bits_req_source};
  assign in_payload[10] = {
    io_in_10_bits_req_addr,
    io_in_10_bits_req_source};
  assign in_payload[11] = {
    io_in_11_bits_req_addr,
    io_in_11_bits_req_source};
  assign in_payload[12] = {
    io_in_12_bits_req_addr,
    io_in_12_bits_req_source};
  assign in_payload[13] = {
    io_in_13_bits_req_addr,
    io_in_13_bits_req_source};
  assign in_payload[14] = {
    io_in_14_bits_req_addr,
    io_in_14_bits_req_source};
  assign in_payload[15] = {
    io_in_15_bits_req_addr,
    io_in_15_bits_req_source};

  payload_t out_payload;
  xs_RRArbiterInit_core #(.N(N), .W(W)) u_core (
    .clock     (clock),
    .reset     (reset),
    .in_valid  ({io_in_15_valid, io_in_14_valid, io_in_13_valid, io_in_12_valid,
                 io_in_11_valid, io_in_10_valid, io_in_9_valid, io_in_8_valid,
                 io_in_7_valid, io_in_6_valid, io_in_5_valid, io_in_4_valid,
                 io_in_3_valid, io_in_2_valid, io_in_1_valid, io_in_0_valid}),
    .in_bits   (in_payload),
    .in_ready  (),                 // 本变体 golden 无 in_ready 输出端口
    .out_ready (1'b1),             // 本变体 golden 无 io_out_ready 端口（恒 1）
    .out_valid (io_out_valid),
    .out_bits  (out_payload),
    .chosen    (io_chosen)
  );

  // 拆包：与上面的打包共用同一张字段表。
  assign io_out_bits_req_addr = out_payload.req_addr;
  assign io_out_bits_req_source = out_payload.req_source;
endmodule
