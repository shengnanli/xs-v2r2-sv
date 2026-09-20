// =============================================================================
// RRArbiterInit_1.sv —— 轮转仲裁器家族薄 wrapper：LLPTW（末级页表遍历）6 个条目的 hptw 回填结果仲裁
//
// 本变体规模：仲裁宽度 N=6，payload 打平 W=127 位（7 个字段），chosen/lastGrant 3 位。
//   端口面：in_ready 输出★无★、out_ready 输入有、io_chosen 输出有。
//   例化者：LLPTW.sv。
//
// 本文件只做参数与端口对位；仲裁逻辑核在 rtl/common/RRArbiterInit.sv
// （模块 xs_RRArbiterInit_core），核体全家族共一份。本文件由
// verif/ut/RRArbiterInitVariants/gen.py 生成，勿手改。
//
// 设计源：rocket-chip util/Arbiters.scala (class LockingRRArbiter)
// golden 对照：G1-canonical/golden-rtl/RRArbiterInit_1.sv
// =============================================================================
package rrarbiterinit_1_pkg;
  // payload 字段表：顺序 = golden io_out_bits_* 的端口顺序，靠前者占高位。
  // 打平成 127 位送进仲裁核，核只按 chosen 选一路，不看字段结构。
  typedef struct packed {
    logic [37:0] req_info_vpn;
    logic [1:0]  req_info_s2xlate;
    logic [1:0]  req_info_source;
    logic [43:0] ppn;
    logic        hptw_resp_entry_n;
    logic [37:0] hptw_resp_entry_ppn;
    logic [1:0]  hptw_resp_entry_level;
  } payload_t;
endpackage

module RRArbiterInit_1 import rrarbiterinit_1_pkg::*; (
  input         clock,
  input         reset,
  input         io_in_0_valid,
  input  [37:0] io_in_0_bits_req_info_vpn,
  input  [1:0]  io_in_0_bits_req_info_s2xlate,
  input  [1:0]  io_in_0_bits_req_info_source,
  input  [43:0] io_in_0_bits_ppn,
  input         io_in_0_bits_hptw_resp_entry_n,
  input  [37:0] io_in_0_bits_hptw_resp_entry_ppn,
  input  [1:0]  io_in_0_bits_hptw_resp_entry_level,
  input         io_in_1_valid,
  input  [37:0] io_in_1_bits_req_info_vpn,
  input  [1:0]  io_in_1_bits_req_info_s2xlate,
  input  [1:0]  io_in_1_bits_req_info_source,
  input  [43:0] io_in_1_bits_ppn,
  input         io_in_1_bits_hptw_resp_entry_n,
  input  [37:0] io_in_1_bits_hptw_resp_entry_ppn,
  input  [1:0]  io_in_1_bits_hptw_resp_entry_level,
  input         io_in_2_valid,
  input  [37:0] io_in_2_bits_req_info_vpn,
  input  [1:0]  io_in_2_bits_req_info_s2xlate,
  input  [1:0]  io_in_2_bits_req_info_source,
  input  [43:0] io_in_2_bits_ppn,
  input         io_in_2_bits_hptw_resp_entry_n,
  input  [37:0] io_in_2_bits_hptw_resp_entry_ppn,
  input  [1:0]  io_in_2_bits_hptw_resp_entry_level,
  input         io_in_3_valid,
  input  [37:0] io_in_3_bits_req_info_vpn,
  input  [1:0]  io_in_3_bits_req_info_s2xlate,
  input  [1:0]  io_in_3_bits_req_info_source,
  input  [43:0] io_in_3_bits_ppn,
  input         io_in_3_bits_hptw_resp_entry_n,
  input  [37:0] io_in_3_bits_hptw_resp_entry_ppn,
  input  [1:0]  io_in_3_bits_hptw_resp_entry_level,
  input         io_in_4_valid,
  input  [37:0] io_in_4_bits_req_info_vpn,
  input  [1:0]  io_in_4_bits_req_info_s2xlate,
  input  [1:0]  io_in_4_bits_req_info_source,
  input  [43:0] io_in_4_bits_ppn,
  input         io_in_4_bits_hptw_resp_entry_n,
  input  [37:0] io_in_4_bits_hptw_resp_entry_ppn,
  input  [1:0]  io_in_4_bits_hptw_resp_entry_level,
  input         io_in_5_valid,
  input  [37:0] io_in_5_bits_req_info_vpn,
  input  [1:0]  io_in_5_bits_req_info_s2xlate,
  input  [1:0]  io_in_5_bits_req_info_source,
  input  [43:0] io_in_5_bits_ppn,
  input         io_in_5_bits_hptw_resp_entry_n,
  input  [37:0] io_in_5_bits_hptw_resp_entry_ppn,
  input  [1:0]  io_in_5_bits_hptw_resp_entry_level,
  input         io_out_ready,
  output        io_out_valid,
  output [37:0] io_out_bits_req_info_vpn,
  output [1:0]  io_out_bits_req_info_s2xlate,
  output [1:0]  io_out_bits_req_info_source,
  output [43:0] io_out_bits_ppn,
  output        io_out_bits_hptw_resp_entry_n,
  output [37:0] io_out_bits_hptw_resp_entry_ppn,
  output [1:0]  io_out_bits_hptw_resp_entry_level,
  output [2:0]  io_chosen
);
  localparam int N = 6;
  localparam int W = $bits(payload_t);

  // 打包：每一路按字段表顺序拼成 W 位（下面的拆包用同一张表，反过来一次）。
  payload_t [N-1:0] in_payload;
  assign in_payload[0] = {
    io_in_0_bits_req_info_vpn,
    io_in_0_bits_req_info_s2xlate,
    io_in_0_bits_req_info_source,
    io_in_0_bits_ppn,
    io_in_0_bits_hptw_resp_entry_n,
    io_in_0_bits_hptw_resp_entry_ppn,
    io_in_0_bits_hptw_resp_entry_level};
  assign in_payload[1] = {
    io_in_1_bits_req_info_vpn,
    io_in_1_bits_req_info_s2xlate,
    io_in_1_bits_req_info_source,
    io_in_1_bits_ppn,
    io_in_1_bits_hptw_resp_entry_n,
    io_in_1_bits_hptw_resp_entry_ppn,
    io_in_1_bits_hptw_resp_entry_level};
  assign in_payload[2] = {
    io_in_2_bits_req_info_vpn,
    io_in_2_bits_req_info_s2xlate,
    io_in_2_bits_req_info_source,
    io_in_2_bits_ppn,
    io_in_2_bits_hptw_resp_entry_n,
    io_in_2_bits_hptw_resp_entry_ppn,
    io_in_2_bits_hptw_resp_entry_level};
  assign in_payload[3] = {
    io_in_3_bits_req_info_vpn,
    io_in_3_bits_req_info_s2xlate,
    io_in_3_bits_req_info_source,
    io_in_3_bits_ppn,
    io_in_3_bits_hptw_resp_entry_n,
    io_in_3_bits_hptw_resp_entry_ppn,
    io_in_3_bits_hptw_resp_entry_level};
  assign in_payload[4] = {
    io_in_4_bits_req_info_vpn,
    io_in_4_bits_req_info_s2xlate,
    io_in_4_bits_req_info_source,
    io_in_4_bits_ppn,
    io_in_4_bits_hptw_resp_entry_n,
    io_in_4_bits_hptw_resp_entry_ppn,
    io_in_4_bits_hptw_resp_entry_level};
  assign in_payload[5] = {
    io_in_5_bits_req_info_vpn,
    io_in_5_bits_req_info_s2xlate,
    io_in_5_bits_req_info_source,
    io_in_5_bits_ppn,
    io_in_5_bits_hptw_resp_entry_n,
    io_in_5_bits_hptw_resp_entry_ppn,
    io_in_5_bits_hptw_resp_entry_level};

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
  assign io_out_bits_req_info_vpn = out_payload.req_info_vpn;
  assign io_out_bits_req_info_s2xlate = out_payload.req_info_s2xlate;
  assign io_out_bits_req_info_source = out_payload.req_info_source;
  assign io_out_bits_ppn = out_payload.ppn;
  assign io_out_bits_hptw_resp_entry_n = out_payload.hptw_resp_entry_n;
  assign io_out_bits_hptw_resp_entry_ppn = out_payload.hptw_resp_entry_ppn;
  assign io_out_bits_hptw_resp_entry_level = out_payload.hptw_resp_entry_level;
endmodule
