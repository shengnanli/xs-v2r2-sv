// =============================================================================
// RRArbiterInit_11.sv —— 轮转仲裁器家族薄 wrapper：LoadQueueUncache 16 个 uncache 条目的发射仲裁
//
// 本变体规模：仲裁宽度 N=16，payload 打平 W=117 位（7 个字段），chosen/lastGrant 4 位。
//   端口面：in_ready 输出有、out_ready 输入有、io_chosen 输出无。
//   例化者：LoadQueueUncache.sv。
//   ★golden 的派生输出★：bits_id 没有任何输入端口来源，golden 用一张
//   「下标即取值」的常数表按 chosen 取值（等价于把 chosen 零扩展）。照抄该结构。
//
// 本文件只做参数与端口对位；仲裁逻辑核在 rtl/common/RRArbiterInit.sv
// （模块 xs_RRArbiterInit_core），核体全家族共一份。本文件由
// verif/ut/RRArbiterInitVariants/gen.py 生成，勿手改。
//
// 设计源：rocket-chip util/Arbiters.scala (class LockingRRArbiter)
// golden 对照：G1-canonical/golden-rtl/RRArbiterInit_11.sv
// =============================================================================
package rrarbiterinit_11_pkg;
  // payload 字段表：顺序 = golden io_out_bits_* 的端口顺序，靠前者占高位。
  // 打平成 117 位送进仲裁核，核只按 chosen 选一路，不看字段结构。
  typedef struct packed {
    logic        robIdx_flag;
    logic [7:0]  robIdx_value;
    logic [47:0] addr;
    logic [49:0] vaddr;
    logic [7:0]  mask;
    logic        nc;
    logic        memBackTypeMM;
  } payload_t;
endpackage

module RRArbiterInit_11 import rrarbiterinit_11_pkg::*; (
  input         clock,
  input         reset,
  output        io_in_0_ready,
  input         io_in_0_valid,
  input         io_in_0_bits_robIdx_flag,
  input  [7:0]  io_in_0_bits_robIdx_value,
  input  [47:0] io_in_0_bits_addr,
  input  [49:0] io_in_0_bits_vaddr,
  input  [7:0]  io_in_0_bits_mask,
  input         io_in_0_bits_nc,
  input         io_in_0_bits_memBackTypeMM,
  output        io_in_1_ready,
  input         io_in_1_valid,
  input         io_in_1_bits_robIdx_flag,
  input  [7:0]  io_in_1_bits_robIdx_value,
  input  [47:0] io_in_1_bits_addr,
  input  [49:0] io_in_1_bits_vaddr,
  input  [7:0]  io_in_1_bits_mask,
  input         io_in_1_bits_nc,
  input         io_in_1_bits_memBackTypeMM,
  output        io_in_2_ready,
  input         io_in_2_valid,
  input         io_in_2_bits_robIdx_flag,
  input  [7:0]  io_in_2_bits_robIdx_value,
  input  [47:0] io_in_2_bits_addr,
  input  [49:0] io_in_2_bits_vaddr,
  input  [7:0]  io_in_2_bits_mask,
  input         io_in_2_bits_nc,
  input         io_in_2_bits_memBackTypeMM,
  output        io_in_3_ready,
  input         io_in_3_valid,
  input         io_in_3_bits_robIdx_flag,
  input  [7:0]  io_in_3_bits_robIdx_value,
  input  [47:0] io_in_3_bits_addr,
  input  [49:0] io_in_3_bits_vaddr,
  input  [7:0]  io_in_3_bits_mask,
  input         io_in_3_bits_nc,
  input         io_in_3_bits_memBackTypeMM,
  output        io_in_4_ready,
  input         io_in_4_valid,
  input         io_in_4_bits_robIdx_flag,
  input  [7:0]  io_in_4_bits_robIdx_value,
  input  [47:0] io_in_4_bits_addr,
  input  [49:0] io_in_4_bits_vaddr,
  input  [7:0]  io_in_4_bits_mask,
  input         io_in_4_bits_nc,
  input         io_in_4_bits_memBackTypeMM,
  output        io_in_5_ready,
  input         io_in_5_valid,
  input         io_in_5_bits_robIdx_flag,
  input  [7:0]  io_in_5_bits_robIdx_value,
  input  [47:0] io_in_5_bits_addr,
  input  [49:0] io_in_5_bits_vaddr,
  input  [7:0]  io_in_5_bits_mask,
  input         io_in_5_bits_nc,
  input         io_in_5_bits_memBackTypeMM,
  output        io_in_6_ready,
  input         io_in_6_valid,
  input         io_in_6_bits_robIdx_flag,
  input  [7:0]  io_in_6_bits_robIdx_value,
  input  [47:0] io_in_6_bits_addr,
  input  [49:0] io_in_6_bits_vaddr,
  input  [7:0]  io_in_6_bits_mask,
  input         io_in_6_bits_nc,
  input         io_in_6_bits_memBackTypeMM,
  output        io_in_7_ready,
  input         io_in_7_valid,
  input         io_in_7_bits_robIdx_flag,
  input  [7:0]  io_in_7_bits_robIdx_value,
  input  [47:0] io_in_7_bits_addr,
  input  [49:0] io_in_7_bits_vaddr,
  input  [7:0]  io_in_7_bits_mask,
  input         io_in_7_bits_nc,
  input         io_in_7_bits_memBackTypeMM,
  output        io_in_8_ready,
  input         io_in_8_valid,
  input         io_in_8_bits_robIdx_flag,
  input  [7:0]  io_in_8_bits_robIdx_value,
  input  [47:0] io_in_8_bits_addr,
  input  [49:0] io_in_8_bits_vaddr,
  input  [7:0]  io_in_8_bits_mask,
  input         io_in_8_bits_nc,
  input         io_in_8_bits_memBackTypeMM,
  output        io_in_9_ready,
  input         io_in_9_valid,
  input         io_in_9_bits_robIdx_flag,
  input  [7:0]  io_in_9_bits_robIdx_value,
  input  [47:0] io_in_9_bits_addr,
  input  [49:0] io_in_9_bits_vaddr,
  input  [7:0]  io_in_9_bits_mask,
  input         io_in_9_bits_nc,
  input         io_in_9_bits_memBackTypeMM,
  output        io_in_10_ready,
  input         io_in_10_valid,
  input         io_in_10_bits_robIdx_flag,
  input  [7:0]  io_in_10_bits_robIdx_value,
  input  [47:0] io_in_10_bits_addr,
  input  [49:0] io_in_10_bits_vaddr,
  input  [7:0]  io_in_10_bits_mask,
  input         io_in_10_bits_nc,
  input         io_in_10_bits_memBackTypeMM,
  output        io_in_11_ready,
  input         io_in_11_valid,
  input         io_in_11_bits_robIdx_flag,
  input  [7:0]  io_in_11_bits_robIdx_value,
  input  [47:0] io_in_11_bits_addr,
  input  [49:0] io_in_11_bits_vaddr,
  input  [7:0]  io_in_11_bits_mask,
  input         io_in_11_bits_nc,
  input         io_in_11_bits_memBackTypeMM,
  output        io_in_12_ready,
  input         io_in_12_valid,
  input         io_in_12_bits_robIdx_flag,
  input  [7:0]  io_in_12_bits_robIdx_value,
  input  [47:0] io_in_12_bits_addr,
  input  [49:0] io_in_12_bits_vaddr,
  input  [7:0]  io_in_12_bits_mask,
  input         io_in_12_bits_nc,
  input         io_in_12_bits_memBackTypeMM,
  output        io_in_13_ready,
  input         io_in_13_valid,
  input         io_in_13_bits_robIdx_flag,
  input  [7:0]  io_in_13_bits_robIdx_value,
  input  [47:0] io_in_13_bits_addr,
  input  [49:0] io_in_13_bits_vaddr,
  input  [7:0]  io_in_13_bits_mask,
  input         io_in_13_bits_nc,
  input         io_in_13_bits_memBackTypeMM,
  output        io_in_14_ready,
  input         io_in_14_valid,
  input         io_in_14_bits_robIdx_flag,
  input  [7:0]  io_in_14_bits_robIdx_value,
  input  [47:0] io_in_14_bits_addr,
  input  [49:0] io_in_14_bits_vaddr,
  input  [7:0]  io_in_14_bits_mask,
  input         io_in_14_bits_nc,
  input         io_in_14_bits_memBackTypeMM,
  output        io_in_15_ready,
  input         io_in_15_valid,
  input         io_in_15_bits_robIdx_flag,
  input  [7:0]  io_in_15_bits_robIdx_value,
  input  [47:0] io_in_15_bits_addr,
  input  [49:0] io_in_15_bits_vaddr,
  input  [7:0]  io_in_15_bits_mask,
  input         io_in_15_bits_nc,
  input         io_in_15_bits_memBackTypeMM,
  input         io_out_ready,
  output        io_out_valid,
  output        io_out_bits_robIdx_flag,
  output [7:0]  io_out_bits_robIdx_value,
  output [47:0] io_out_bits_addr,
  output [49:0] io_out_bits_vaddr,
  output [7:0]  io_out_bits_mask,
  output [6:0]  io_out_bits_id,
  output        io_out_bits_nc,
  output        io_out_bits_memBackTypeMM
);
  localparam int N = 16;
  localparam int W = $bits(payload_t);

  // 打包：每一路按字段表顺序拼成 W 位（下面的拆包用同一张表，反过来一次）。
  payload_t [N-1:0] in_payload;
  assign in_payload[0] = {
    io_in_0_bits_robIdx_flag,
    io_in_0_bits_robIdx_value,
    io_in_0_bits_addr,
    io_in_0_bits_vaddr,
    io_in_0_bits_mask,
    io_in_0_bits_nc,
    io_in_0_bits_memBackTypeMM};
  assign in_payload[1] = {
    io_in_1_bits_robIdx_flag,
    io_in_1_bits_robIdx_value,
    io_in_1_bits_addr,
    io_in_1_bits_vaddr,
    io_in_1_bits_mask,
    io_in_1_bits_nc,
    io_in_1_bits_memBackTypeMM};
  assign in_payload[2] = {
    io_in_2_bits_robIdx_flag,
    io_in_2_bits_robIdx_value,
    io_in_2_bits_addr,
    io_in_2_bits_vaddr,
    io_in_2_bits_mask,
    io_in_2_bits_nc,
    io_in_2_bits_memBackTypeMM};
  assign in_payload[3] = {
    io_in_3_bits_robIdx_flag,
    io_in_3_bits_robIdx_value,
    io_in_3_bits_addr,
    io_in_3_bits_vaddr,
    io_in_3_bits_mask,
    io_in_3_bits_nc,
    io_in_3_bits_memBackTypeMM};
  assign in_payload[4] = {
    io_in_4_bits_robIdx_flag,
    io_in_4_bits_robIdx_value,
    io_in_4_bits_addr,
    io_in_4_bits_vaddr,
    io_in_4_bits_mask,
    io_in_4_bits_nc,
    io_in_4_bits_memBackTypeMM};
  assign in_payload[5] = {
    io_in_5_bits_robIdx_flag,
    io_in_5_bits_robIdx_value,
    io_in_5_bits_addr,
    io_in_5_bits_vaddr,
    io_in_5_bits_mask,
    io_in_5_bits_nc,
    io_in_5_bits_memBackTypeMM};
  assign in_payload[6] = {
    io_in_6_bits_robIdx_flag,
    io_in_6_bits_robIdx_value,
    io_in_6_bits_addr,
    io_in_6_bits_vaddr,
    io_in_6_bits_mask,
    io_in_6_bits_nc,
    io_in_6_bits_memBackTypeMM};
  assign in_payload[7] = {
    io_in_7_bits_robIdx_flag,
    io_in_7_bits_robIdx_value,
    io_in_7_bits_addr,
    io_in_7_bits_vaddr,
    io_in_7_bits_mask,
    io_in_7_bits_nc,
    io_in_7_bits_memBackTypeMM};
  assign in_payload[8] = {
    io_in_8_bits_robIdx_flag,
    io_in_8_bits_robIdx_value,
    io_in_8_bits_addr,
    io_in_8_bits_vaddr,
    io_in_8_bits_mask,
    io_in_8_bits_nc,
    io_in_8_bits_memBackTypeMM};
  assign in_payload[9] = {
    io_in_9_bits_robIdx_flag,
    io_in_9_bits_robIdx_value,
    io_in_9_bits_addr,
    io_in_9_bits_vaddr,
    io_in_9_bits_mask,
    io_in_9_bits_nc,
    io_in_9_bits_memBackTypeMM};
  assign in_payload[10] = {
    io_in_10_bits_robIdx_flag,
    io_in_10_bits_robIdx_value,
    io_in_10_bits_addr,
    io_in_10_bits_vaddr,
    io_in_10_bits_mask,
    io_in_10_bits_nc,
    io_in_10_bits_memBackTypeMM};
  assign in_payload[11] = {
    io_in_11_bits_robIdx_flag,
    io_in_11_bits_robIdx_value,
    io_in_11_bits_addr,
    io_in_11_bits_vaddr,
    io_in_11_bits_mask,
    io_in_11_bits_nc,
    io_in_11_bits_memBackTypeMM};
  assign in_payload[12] = {
    io_in_12_bits_robIdx_flag,
    io_in_12_bits_robIdx_value,
    io_in_12_bits_addr,
    io_in_12_bits_vaddr,
    io_in_12_bits_mask,
    io_in_12_bits_nc,
    io_in_12_bits_memBackTypeMM};
  assign in_payload[13] = {
    io_in_13_bits_robIdx_flag,
    io_in_13_bits_robIdx_value,
    io_in_13_bits_addr,
    io_in_13_bits_vaddr,
    io_in_13_bits_mask,
    io_in_13_bits_nc,
    io_in_13_bits_memBackTypeMM};
  assign in_payload[14] = {
    io_in_14_bits_robIdx_flag,
    io_in_14_bits_robIdx_value,
    io_in_14_bits_addr,
    io_in_14_bits_vaddr,
    io_in_14_bits_mask,
    io_in_14_bits_nc,
    io_in_14_bits_memBackTypeMM};
  assign in_payload[15] = {
    io_in_15_bits_robIdx_flag,
    io_in_15_bits_robIdx_value,
    io_in_15_bits_addr,
    io_in_15_bits_vaddr,
    io_in_15_bits_mask,
    io_in_15_bits_nc,
    io_in_15_bits_memBackTypeMM};

  payload_t out_payload;
  logic [3:0] chosen;   // golden 没有 io_chosen 端口，但派生输出要用它
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
    .chosen    (chosen)
  );

  // 拆包：与上面的打包共用同一张字段表。
  assign io_out_bits_robIdx_flag = out_payload.robIdx_flag;
  assign io_out_bits_robIdx_value = out_payload.robIdx_value;
  assign io_out_bits_addr = out_payload.addr;
  assign io_out_bits_vaddr = out_payload.vaddr;
  assign io_out_bits_mask = out_payload.mask;
  assign io_out_bits_nc = out_payload.nc;
  assign io_out_bits_memBackTypeMM = out_payload.memBackTypeMM;

  // io_out_bits_id：golden 用一张常数表 `_GEN[chosen]`，第 idx 项恒等于 idx。
  //   照抄这张表的结构（值上等于把 chosen 零扩展到 7 位）。
  logic [15:0][6:0] id_by_index;
  always_comb
    for (int idx = 0; idx < 16; idx++) id_by_index[idx] = 7'(idx);
  assign io_out_bits_id = id_by_index[chosen];
endmodule
