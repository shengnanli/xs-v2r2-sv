// =============================================================================
// RRArbiterInit_8.sv —— 轮转仲裁器家族薄 wrapper：多级预取过滤器 16 路预取请求（paddr/alias/confidence/来源）仲裁
//
// 本变体规模：仲裁宽度 N=16，payload 打平 W=54 位（4 个字段），chosen/lastGrant 4 位。
//   端口面：in_ready 输出有、out_ready 输入有、io_chosen 输出有。
//   例化者：MutiLevelPrefetchFilter.sv。
//
// 本文件只做参数与端口对位；仲裁逻辑核在 rtl/common/RRArbiterInit.sv
// （模块 xs_RRArbiterInit_core），核体全家族共一份。本文件由
// verif/ut/RRArbiterInitVariants/gen.py 生成，勿手改。
//
// 设计源：rocket-chip util/Arbiters.scala (class LockingRRArbiter)
// golden 对照：G1-canonical/golden-rtl/RRArbiterInit_8.sv
// =============================================================================
package rrarbiterinit_8_pkg;
  // payload 字段表：顺序 = golden io_out_bits_* 的端口顺序，靠前者占高位。
  // 打平成 54 位送进仲裁核，核只按 chosen 选一路，不看字段结构。
  typedef struct packed {
    logic [47:0] req_paddr;
    logic [1:0]  req_alias;
    logic        req_confidence;
    logic [2:0]  req_pf_source_value;
  } payload_t;
endpackage

module RRArbiterInit_8 import rrarbiterinit_8_pkg::*; (
  input         clock,
  input         reset,
  output        io_in_0_ready,
  input         io_in_0_valid,
  input  [47:0] io_in_0_bits_req_paddr,
  input  [1:0]  io_in_0_bits_req_alias,
  input         io_in_0_bits_req_confidence,
  input  [2:0]  io_in_0_bits_req_pf_source_value,
  output        io_in_1_ready,
  input         io_in_1_valid,
  input  [47:0] io_in_1_bits_req_paddr,
  input  [1:0]  io_in_1_bits_req_alias,
  input         io_in_1_bits_req_confidence,
  input  [2:0]  io_in_1_bits_req_pf_source_value,
  output        io_in_2_ready,
  input         io_in_2_valid,
  input  [47:0] io_in_2_bits_req_paddr,
  input  [1:0]  io_in_2_bits_req_alias,
  input         io_in_2_bits_req_confidence,
  input  [2:0]  io_in_2_bits_req_pf_source_value,
  output        io_in_3_ready,
  input         io_in_3_valid,
  input  [47:0] io_in_3_bits_req_paddr,
  input  [1:0]  io_in_3_bits_req_alias,
  input         io_in_3_bits_req_confidence,
  input  [2:0]  io_in_3_bits_req_pf_source_value,
  output        io_in_4_ready,
  input         io_in_4_valid,
  input  [47:0] io_in_4_bits_req_paddr,
  input  [1:0]  io_in_4_bits_req_alias,
  input         io_in_4_bits_req_confidence,
  input  [2:0]  io_in_4_bits_req_pf_source_value,
  output        io_in_5_ready,
  input         io_in_5_valid,
  input  [47:0] io_in_5_bits_req_paddr,
  input  [1:0]  io_in_5_bits_req_alias,
  input         io_in_5_bits_req_confidence,
  input  [2:0]  io_in_5_bits_req_pf_source_value,
  output        io_in_6_ready,
  input         io_in_6_valid,
  input  [47:0] io_in_6_bits_req_paddr,
  input  [1:0]  io_in_6_bits_req_alias,
  input         io_in_6_bits_req_confidence,
  input  [2:0]  io_in_6_bits_req_pf_source_value,
  output        io_in_7_ready,
  input         io_in_7_valid,
  input  [47:0] io_in_7_bits_req_paddr,
  input  [1:0]  io_in_7_bits_req_alias,
  input         io_in_7_bits_req_confidence,
  input  [2:0]  io_in_7_bits_req_pf_source_value,
  output        io_in_8_ready,
  input         io_in_8_valid,
  input  [47:0] io_in_8_bits_req_paddr,
  input  [1:0]  io_in_8_bits_req_alias,
  input         io_in_8_bits_req_confidence,
  input  [2:0]  io_in_8_bits_req_pf_source_value,
  output        io_in_9_ready,
  input         io_in_9_valid,
  input  [47:0] io_in_9_bits_req_paddr,
  input  [1:0]  io_in_9_bits_req_alias,
  input         io_in_9_bits_req_confidence,
  input  [2:0]  io_in_9_bits_req_pf_source_value,
  output        io_in_10_ready,
  input         io_in_10_valid,
  input  [47:0] io_in_10_bits_req_paddr,
  input  [1:0]  io_in_10_bits_req_alias,
  input         io_in_10_bits_req_confidence,
  input  [2:0]  io_in_10_bits_req_pf_source_value,
  output        io_in_11_ready,
  input         io_in_11_valid,
  input  [47:0] io_in_11_bits_req_paddr,
  input  [1:0]  io_in_11_bits_req_alias,
  input         io_in_11_bits_req_confidence,
  input  [2:0]  io_in_11_bits_req_pf_source_value,
  output        io_in_12_ready,
  input         io_in_12_valid,
  input  [47:0] io_in_12_bits_req_paddr,
  input  [1:0]  io_in_12_bits_req_alias,
  input         io_in_12_bits_req_confidence,
  input  [2:0]  io_in_12_bits_req_pf_source_value,
  output        io_in_13_ready,
  input         io_in_13_valid,
  input  [47:0] io_in_13_bits_req_paddr,
  input  [1:0]  io_in_13_bits_req_alias,
  input         io_in_13_bits_req_confidence,
  input  [2:0]  io_in_13_bits_req_pf_source_value,
  output        io_in_14_ready,
  input         io_in_14_valid,
  input  [47:0] io_in_14_bits_req_paddr,
  input  [1:0]  io_in_14_bits_req_alias,
  input         io_in_14_bits_req_confidence,
  input  [2:0]  io_in_14_bits_req_pf_source_value,
  output        io_in_15_ready,
  input         io_in_15_valid,
  input  [47:0] io_in_15_bits_req_paddr,
  input  [1:0]  io_in_15_bits_req_alias,
  input         io_in_15_bits_req_confidence,
  input  [2:0]  io_in_15_bits_req_pf_source_value,
  input         io_out_ready,
  output        io_out_valid,
  output [47:0] io_out_bits_req_paddr,
  output [1:0]  io_out_bits_req_alias,
  output        io_out_bits_req_confidence,
  output [2:0]  io_out_bits_req_pf_source_value,
  output [3:0]  io_chosen
);
  localparam int N = 16;
  localparam int W = $bits(payload_t);

  // 打包：每一路按字段表顺序拼成 W 位（下面的拆包用同一张表，反过来一次）。
  payload_t [N-1:0] in_payload;
  assign in_payload[0] = {
    io_in_0_bits_req_paddr,
    io_in_0_bits_req_alias,
    io_in_0_bits_req_confidence,
    io_in_0_bits_req_pf_source_value};
  assign in_payload[1] = {
    io_in_1_bits_req_paddr,
    io_in_1_bits_req_alias,
    io_in_1_bits_req_confidence,
    io_in_1_bits_req_pf_source_value};
  assign in_payload[2] = {
    io_in_2_bits_req_paddr,
    io_in_2_bits_req_alias,
    io_in_2_bits_req_confidence,
    io_in_2_bits_req_pf_source_value};
  assign in_payload[3] = {
    io_in_3_bits_req_paddr,
    io_in_3_bits_req_alias,
    io_in_3_bits_req_confidence,
    io_in_3_bits_req_pf_source_value};
  assign in_payload[4] = {
    io_in_4_bits_req_paddr,
    io_in_4_bits_req_alias,
    io_in_4_bits_req_confidence,
    io_in_4_bits_req_pf_source_value};
  assign in_payload[5] = {
    io_in_5_bits_req_paddr,
    io_in_5_bits_req_alias,
    io_in_5_bits_req_confidence,
    io_in_5_bits_req_pf_source_value};
  assign in_payload[6] = {
    io_in_6_bits_req_paddr,
    io_in_6_bits_req_alias,
    io_in_6_bits_req_confidence,
    io_in_6_bits_req_pf_source_value};
  assign in_payload[7] = {
    io_in_7_bits_req_paddr,
    io_in_7_bits_req_alias,
    io_in_7_bits_req_confidence,
    io_in_7_bits_req_pf_source_value};
  assign in_payload[8] = {
    io_in_8_bits_req_paddr,
    io_in_8_bits_req_alias,
    io_in_8_bits_req_confidence,
    io_in_8_bits_req_pf_source_value};
  assign in_payload[9] = {
    io_in_9_bits_req_paddr,
    io_in_9_bits_req_alias,
    io_in_9_bits_req_confidence,
    io_in_9_bits_req_pf_source_value};
  assign in_payload[10] = {
    io_in_10_bits_req_paddr,
    io_in_10_bits_req_alias,
    io_in_10_bits_req_confidence,
    io_in_10_bits_req_pf_source_value};
  assign in_payload[11] = {
    io_in_11_bits_req_paddr,
    io_in_11_bits_req_alias,
    io_in_11_bits_req_confidence,
    io_in_11_bits_req_pf_source_value};
  assign in_payload[12] = {
    io_in_12_bits_req_paddr,
    io_in_12_bits_req_alias,
    io_in_12_bits_req_confidence,
    io_in_12_bits_req_pf_source_value};
  assign in_payload[13] = {
    io_in_13_bits_req_paddr,
    io_in_13_bits_req_alias,
    io_in_13_bits_req_confidence,
    io_in_13_bits_req_pf_source_value};
  assign in_payload[14] = {
    io_in_14_bits_req_paddr,
    io_in_14_bits_req_alias,
    io_in_14_bits_req_confidence,
    io_in_14_bits_req_pf_source_value};
  assign in_payload[15] = {
    io_in_15_bits_req_paddr,
    io_in_15_bits_req_alias,
    io_in_15_bits_req_confidence,
    io_in_15_bits_req_pf_source_value};

  payload_t out_payload;
  xs_RRArbiterInit_core #(.N(N), .W(W)) u_core (
    .clock     (clock),
    .reset     (reset),
    .in_valid  ({io_in_15_valid, io_in_14_valid, io_in_13_valid, io_in_12_valid,
                 io_in_11_valid, io_in_10_valid, io_in_9_valid, io_in_8_valid,
                 io_in_7_valid, io_in_6_valid, io_in_5_valid, io_in_4_valid,
                 io_in_3_valid, io_in_2_valid, io_in_1_valid, io_in_0_valid}),
    .in_bits   (in_payload),
    .in_ready  ({io_in_15_ready, io_in_14_ready, io_in_13_ready, io_in_12_ready,
                 io_in_11_ready, io_in_10_ready, io_in_9_ready, io_in_8_ready,
                 io_in_7_ready, io_in_6_ready, io_in_5_ready, io_in_4_ready,
                 io_in_3_ready, io_in_2_ready, io_in_1_ready, io_in_0_ready}),
    .out_ready (io_out_ready),
    .out_valid (io_out_valid),
    .out_bits  (out_payload),
    .chosen    (io_chosen)
  );

  // 拆包：与上面的打包共用同一张字段表。
  assign io_out_bits_req_paddr = out_payload.req_paddr;
  assign io_out_bits_req_alias = out_payload.req_alias;
  assign io_out_bits_req_confidence = out_payload.req_confidence;
  assign io_out_bits_req_pf_source_value = out_payload.req_pf_source_value;
endmodule
