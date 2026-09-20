// =============================================================================
// RRArbiterInit_13.sv —— 轮转仲裁器家族薄 wrapper：MMIOBridge 16 个 MMIO 条目发往 CHI TXREQ 的仲裁
//
// 本变体规模：仲裁宽度 N=16，payload 打平 W=79 位（9 个字段），chosen/lastGrant 4 位。
//   端口面：in_ready 输出有、out_ready 输入有、io_chosen 输出无。
//   例化者：MMIOBridge.sv。
//
// 本文件只做参数与端口对位；仲裁逻辑核在 rtl/common/RRArbiterInit.sv
// （模块 xs_RRArbiterInit_core），核体全家族共一份。本文件由
// verif/ut/RRArbiterInitVariants/gen.py 生成，勿手改。
//
// 设计源：rocket-chip util/Arbiters.scala (class LockingRRArbiter)
// golden 对照：G1-canonical/golden-rtl/RRArbiterInit_13.sv
// =============================================================================
package rrarbiterinit_13_pkg;
  // payload 字段表：顺序 = golden io_out_bits_* 的端口顺序，靠前者占高位。
  // 打平成 79 位送进仲裁核，核只按 chosen 选一路，不看字段结构。
  typedef struct packed {
    logic [11:0] txnID;
    logic [6:0]  opcode;
    logic [2:0]  size;
    logic [47:0] addr;
    logic        allowRetry;
    logic [1:0]  order;
    logic [3:0]  pCrdType;
    logic        memAttr_device;
    logic        memAttr_ewa;
  } payload_t;
endpackage

module RRArbiterInit_13 import rrarbiterinit_13_pkg::*; (
  input         clock,
  input         reset,
  output        io_in_0_ready,
  input         io_in_0_valid,
  input  [11:0] io_in_0_bits_txnID,
  input  [6:0]  io_in_0_bits_opcode,
  input  [2:0]  io_in_0_bits_size,
  input  [47:0] io_in_0_bits_addr,
  input         io_in_0_bits_allowRetry,
  input  [1:0]  io_in_0_bits_order,
  input  [3:0]  io_in_0_bits_pCrdType,
  input         io_in_0_bits_memAttr_device,
  input         io_in_0_bits_memAttr_ewa,
  output        io_in_1_ready,
  input         io_in_1_valid,
  input  [11:0] io_in_1_bits_txnID,
  input  [6:0]  io_in_1_bits_opcode,
  input  [2:0]  io_in_1_bits_size,
  input  [47:0] io_in_1_bits_addr,
  input         io_in_1_bits_allowRetry,
  input  [1:0]  io_in_1_bits_order,
  input  [3:0]  io_in_1_bits_pCrdType,
  input         io_in_1_bits_memAttr_device,
  input         io_in_1_bits_memAttr_ewa,
  output        io_in_2_ready,
  input         io_in_2_valid,
  input  [11:0] io_in_2_bits_txnID,
  input  [6:0]  io_in_2_bits_opcode,
  input  [2:0]  io_in_2_bits_size,
  input  [47:0] io_in_2_bits_addr,
  input         io_in_2_bits_allowRetry,
  input  [1:0]  io_in_2_bits_order,
  input  [3:0]  io_in_2_bits_pCrdType,
  input         io_in_2_bits_memAttr_device,
  input         io_in_2_bits_memAttr_ewa,
  output        io_in_3_ready,
  input         io_in_3_valid,
  input  [11:0] io_in_3_bits_txnID,
  input  [6:0]  io_in_3_bits_opcode,
  input  [2:0]  io_in_3_bits_size,
  input  [47:0] io_in_3_bits_addr,
  input         io_in_3_bits_allowRetry,
  input  [1:0]  io_in_3_bits_order,
  input  [3:0]  io_in_3_bits_pCrdType,
  input         io_in_3_bits_memAttr_device,
  input         io_in_3_bits_memAttr_ewa,
  output        io_in_4_ready,
  input         io_in_4_valid,
  input  [11:0] io_in_4_bits_txnID,
  input  [6:0]  io_in_4_bits_opcode,
  input  [2:0]  io_in_4_bits_size,
  input  [47:0] io_in_4_bits_addr,
  input         io_in_4_bits_allowRetry,
  input  [1:0]  io_in_4_bits_order,
  input  [3:0]  io_in_4_bits_pCrdType,
  input         io_in_4_bits_memAttr_device,
  input         io_in_4_bits_memAttr_ewa,
  output        io_in_5_ready,
  input         io_in_5_valid,
  input  [11:0] io_in_5_bits_txnID,
  input  [6:0]  io_in_5_bits_opcode,
  input  [2:0]  io_in_5_bits_size,
  input  [47:0] io_in_5_bits_addr,
  input         io_in_5_bits_allowRetry,
  input  [1:0]  io_in_5_bits_order,
  input  [3:0]  io_in_5_bits_pCrdType,
  input         io_in_5_bits_memAttr_device,
  input         io_in_5_bits_memAttr_ewa,
  output        io_in_6_ready,
  input         io_in_6_valid,
  input  [11:0] io_in_6_bits_txnID,
  input  [6:0]  io_in_6_bits_opcode,
  input  [2:0]  io_in_6_bits_size,
  input  [47:0] io_in_6_bits_addr,
  input         io_in_6_bits_allowRetry,
  input  [1:0]  io_in_6_bits_order,
  input  [3:0]  io_in_6_bits_pCrdType,
  input         io_in_6_bits_memAttr_device,
  input         io_in_6_bits_memAttr_ewa,
  output        io_in_7_ready,
  input         io_in_7_valid,
  input  [11:0] io_in_7_bits_txnID,
  input  [6:0]  io_in_7_bits_opcode,
  input  [2:0]  io_in_7_bits_size,
  input  [47:0] io_in_7_bits_addr,
  input         io_in_7_bits_allowRetry,
  input  [1:0]  io_in_7_bits_order,
  input  [3:0]  io_in_7_bits_pCrdType,
  input         io_in_7_bits_memAttr_device,
  input         io_in_7_bits_memAttr_ewa,
  output        io_in_8_ready,
  input         io_in_8_valid,
  input  [11:0] io_in_8_bits_txnID,
  input  [6:0]  io_in_8_bits_opcode,
  input  [2:0]  io_in_8_bits_size,
  input  [47:0] io_in_8_bits_addr,
  input         io_in_8_bits_allowRetry,
  input  [1:0]  io_in_8_bits_order,
  input  [3:0]  io_in_8_bits_pCrdType,
  input         io_in_8_bits_memAttr_device,
  input         io_in_8_bits_memAttr_ewa,
  output        io_in_9_ready,
  input         io_in_9_valid,
  input  [11:0] io_in_9_bits_txnID,
  input  [6:0]  io_in_9_bits_opcode,
  input  [2:0]  io_in_9_bits_size,
  input  [47:0] io_in_9_bits_addr,
  input         io_in_9_bits_allowRetry,
  input  [1:0]  io_in_9_bits_order,
  input  [3:0]  io_in_9_bits_pCrdType,
  input         io_in_9_bits_memAttr_device,
  input         io_in_9_bits_memAttr_ewa,
  output        io_in_10_ready,
  input         io_in_10_valid,
  input  [11:0] io_in_10_bits_txnID,
  input  [6:0]  io_in_10_bits_opcode,
  input  [2:0]  io_in_10_bits_size,
  input  [47:0] io_in_10_bits_addr,
  input         io_in_10_bits_allowRetry,
  input  [1:0]  io_in_10_bits_order,
  input  [3:0]  io_in_10_bits_pCrdType,
  input         io_in_10_bits_memAttr_device,
  input         io_in_10_bits_memAttr_ewa,
  output        io_in_11_ready,
  input         io_in_11_valid,
  input  [11:0] io_in_11_bits_txnID,
  input  [6:0]  io_in_11_bits_opcode,
  input  [2:0]  io_in_11_bits_size,
  input  [47:0] io_in_11_bits_addr,
  input         io_in_11_bits_allowRetry,
  input  [1:0]  io_in_11_bits_order,
  input  [3:0]  io_in_11_bits_pCrdType,
  input         io_in_11_bits_memAttr_device,
  input         io_in_11_bits_memAttr_ewa,
  output        io_in_12_ready,
  input         io_in_12_valid,
  input  [11:0] io_in_12_bits_txnID,
  input  [6:0]  io_in_12_bits_opcode,
  input  [2:0]  io_in_12_bits_size,
  input  [47:0] io_in_12_bits_addr,
  input         io_in_12_bits_allowRetry,
  input  [1:0]  io_in_12_bits_order,
  input  [3:0]  io_in_12_bits_pCrdType,
  input         io_in_12_bits_memAttr_device,
  input         io_in_12_bits_memAttr_ewa,
  output        io_in_13_ready,
  input         io_in_13_valid,
  input  [11:0] io_in_13_bits_txnID,
  input  [6:0]  io_in_13_bits_opcode,
  input  [2:0]  io_in_13_bits_size,
  input  [47:0] io_in_13_bits_addr,
  input         io_in_13_bits_allowRetry,
  input  [1:0]  io_in_13_bits_order,
  input  [3:0]  io_in_13_bits_pCrdType,
  input         io_in_13_bits_memAttr_device,
  input         io_in_13_bits_memAttr_ewa,
  output        io_in_14_ready,
  input         io_in_14_valid,
  input  [11:0] io_in_14_bits_txnID,
  input  [6:0]  io_in_14_bits_opcode,
  input  [2:0]  io_in_14_bits_size,
  input  [47:0] io_in_14_bits_addr,
  input         io_in_14_bits_allowRetry,
  input  [1:0]  io_in_14_bits_order,
  input  [3:0]  io_in_14_bits_pCrdType,
  input         io_in_14_bits_memAttr_device,
  input         io_in_14_bits_memAttr_ewa,
  output        io_in_15_ready,
  input         io_in_15_valid,
  input  [11:0] io_in_15_bits_txnID,
  input  [6:0]  io_in_15_bits_opcode,
  input  [2:0]  io_in_15_bits_size,
  input  [47:0] io_in_15_bits_addr,
  input         io_in_15_bits_allowRetry,
  input  [1:0]  io_in_15_bits_order,
  input  [3:0]  io_in_15_bits_pCrdType,
  input         io_in_15_bits_memAttr_device,
  input         io_in_15_bits_memAttr_ewa,
  input         io_out_ready,
  output        io_out_valid,
  output [11:0] io_out_bits_txnID,
  output [6:0]  io_out_bits_opcode,
  output [2:0]  io_out_bits_size,
  output [47:0] io_out_bits_addr,
  output        io_out_bits_allowRetry,
  output [1:0]  io_out_bits_order,
  output [3:0]  io_out_bits_pCrdType,
  output        io_out_bits_memAttr_device,
  output        io_out_bits_memAttr_ewa
);
  localparam int N = 16;
  localparam int W = $bits(payload_t);

  // 打包：每一路按字段表顺序拼成 W 位（下面的拆包用同一张表，反过来一次）。
  payload_t [N-1:0] in_payload;
  assign in_payload[0] = {
    io_in_0_bits_txnID,
    io_in_0_bits_opcode,
    io_in_0_bits_size,
    io_in_0_bits_addr,
    io_in_0_bits_allowRetry,
    io_in_0_bits_order,
    io_in_0_bits_pCrdType,
    io_in_0_bits_memAttr_device,
    io_in_0_bits_memAttr_ewa};
  assign in_payload[1] = {
    io_in_1_bits_txnID,
    io_in_1_bits_opcode,
    io_in_1_bits_size,
    io_in_1_bits_addr,
    io_in_1_bits_allowRetry,
    io_in_1_bits_order,
    io_in_1_bits_pCrdType,
    io_in_1_bits_memAttr_device,
    io_in_1_bits_memAttr_ewa};
  assign in_payload[2] = {
    io_in_2_bits_txnID,
    io_in_2_bits_opcode,
    io_in_2_bits_size,
    io_in_2_bits_addr,
    io_in_2_bits_allowRetry,
    io_in_2_bits_order,
    io_in_2_bits_pCrdType,
    io_in_2_bits_memAttr_device,
    io_in_2_bits_memAttr_ewa};
  assign in_payload[3] = {
    io_in_3_bits_txnID,
    io_in_3_bits_opcode,
    io_in_3_bits_size,
    io_in_3_bits_addr,
    io_in_3_bits_allowRetry,
    io_in_3_bits_order,
    io_in_3_bits_pCrdType,
    io_in_3_bits_memAttr_device,
    io_in_3_bits_memAttr_ewa};
  assign in_payload[4] = {
    io_in_4_bits_txnID,
    io_in_4_bits_opcode,
    io_in_4_bits_size,
    io_in_4_bits_addr,
    io_in_4_bits_allowRetry,
    io_in_4_bits_order,
    io_in_4_bits_pCrdType,
    io_in_4_bits_memAttr_device,
    io_in_4_bits_memAttr_ewa};
  assign in_payload[5] = {
    io_in_5_bits_txnID,
    io_in_5_bits_opcode,
    io_in_5_bits_size,
    io_in_5_bits_addr,
    io_in_5_bits_allowRetry,
    io_in_5_bits_order,
    io_in_5_bits_pCrdType,
    io_in_5_bits_memAttr_device,
    io_in_5_bits_memAttr_ewa};
  assign in_payload[6] = {
    io_in_6_bits_txnID,
    io_in_6_bits_opcode,
    io_in_6_bits_size,
    io_in_6_bits_addr,
    io_in_6_bits_allowRetry,
    io_in_6_bits_order,
    io_in_6_bits_pCrdType,
    io_in_6_bits_memAttr_device,
    io_in_6_bits_memAttr_ewa};
  assign in_payload[7] = {
    io_in_7_bits_txnID,
    io_in_7_bits_opcode,
    io_in_7_bits_size,
    io_in_7_bits_addr,
    io_in_7_bits_allowRetry,
    io_in_7_bits_order,
    io_in_7_bits_pCrdType,
    io_in_7_bits_memAttr_device,
    io_in_7_bits_memAttr_ewa};
  assign in_payload[8] = {
    io_in_8_bits_txnID,
    io_in_8_bits_opcode,
    io_in_8_bits_size,
    io_in_8_bits_addr,
    io_in_8_bits_allowRetry,
    io_in_8_bits_order,
    io_in_8_bits_pCrdType,
    io_in_8_bits_memAttr_device,
    io_in_8_bits_memAttr_ewa};
  assign in_payload[9] = {
    io_in_9_bits_txnID,
    io_in_9_bits_opcode,
    io_in_9_bits_size,
    io_in_9_bits_addr,
    io_in_9_bits_allowRetry,
    io_in_9_bits_order,
    io_in_9_bits_pCrdType,
    io_in_9_bits_memAttr_device,
    io_in_9_bits_memAttr_ewa};
  assign in_payload[10] = {
    io_in_10_bits_txnID,
    io_in_10_bits_opcode,
    io_in_10_bits_size,
    io_in_10_bits_addr,
    io_in_10_bits_allowRetry,
    io_in_10_bits_order,
    io_in_10_bits_pCrdType,
    io_in_10_bits_memAttr_device,
    io_in_10_bits_memAttr_ewa};
  assign in_payload[11] = {
    io_in_11_bits_txnID,
    io_in_11_bits_opcode,
    io_in_11_bits_size,
    io_in_11_bits_addr,
    io_in_11_bits_allowRetry,
    io_in_11_bits_order,
    io_in_11_bits_pCrdType,
    io_in_11_bits_memAttr_device,
    io_in_11_bits_memAttr_ewa};
  assign in_payload[12] = {
    io_in_12_bits_txnID,
    io_in_12_bits_opcode,
    io_in_12_bits_size,
    io_in_12_bits_addr,
    io_in_12_bits_allowRetry,
    io_in_12_bits_order,
    io_in_12_bits_pCrdType,
    io_in_12_bits_memAttr_device,
    io_in_12_bits_memAttr_ewa};
  assign in_payload[13] = {
    io_in_13_bits_txnID,
    io_in_13_bits_opcode,
    io_in_13_bits_size,
    io_in_13_bits_addr,
    io_in_13_bits_allowRetry,
    io_in_13_bits_order,
    io_in_13_bits_pCrdType,
    io_in_13_bits_memAttr_device,
    io_in_13_bits_memAttr_ewa};
  assign in_payload[14] = {
    io_in_14_bits_txnID,
    io_in_14_bits_opcode,
    io_in_14_bits_size,
    io_in_14_bits_addr,
    io_in_14_bits_allowRetry,
    io_in_14_bits_order,
    io_in_14_bits_pCrdType,
    io_in_14_bits_memAttr_device,
    io_in_14_bits_memAttr_ewa};
  assign in_payload[15] = {
    io_in_15_bits_txnID,
    io_in_15_bits_opcode,
    io_in_15_bits_size,
    io_in_15_bits_addr,
    io_in_15_bits_allowRetry,
    io_in_15_bits_order,
    io_in_15_bits_pCrdType,
    io_in_15_bits_memAttr_device,
    io_in_15_bits_memAttr_ewa};

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
    .chosen    ()                  // 本变体 golden 无 io_chosen 输出端口
  );

  // 拆包：与上面的打包共用同一张字段表。
  assign io_out_bits_txnID = out_payload.txnID;
  assign io_out_bits_opcode = out_payload.opcode;
  assign io_out_bits_size = out_payload.size;
  assign io_out_bits_addr = out_payload.addr;
  assign io_out_bits_allowRetry = out_payload.allowRetry;
  assign io_out_bits_order = out_payload.order;
  assign io_out_bits_pCrdType = out_payload.pCrdType;
  assign io_out_bits_memAttr_device = out_payload.memAttr_device;
  assign io_out_bits_memAttr_ewa = out_payload.memAttr_ewa;
endmodule
