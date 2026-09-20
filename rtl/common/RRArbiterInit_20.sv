// =============================================================================
// RRArbiterInit_20.sv —— 轮转仲裁器家族薄 wrapper：TL2CHICoupledL2 顶层 5 路 CHI TXREQ 通道仲裁
//
// 本变体规模：仲裁宽度 N=5，payload 打平 W=151 位（28 个字段），chosen/lastGrant 3 位。
//   端口面：in_ready 输出有、out_ready 输入有、io_chosen 输出有。
//   例化者：TL2CHICoupledL2.sv。
//   ★golden 的不对称★：bits_size 仅 in_4 有端口（其余填 3'h6）、bits_tgtID 仅 in_4 有端口（其余填 11'h0） —— 只有部分输入有真端口，其余各路在 golden 的
//   选择表里是常量。照抄，不许补齐成对称（FM 不做可达性分析）。
//
// 本文件只做参数与端口对位；仲裁逻辑核在 rtl/common/RRArbiterInit.sv
// （模块 xs_RRArbiterInit_core），核体全家族共一份。本文件由
// verif/ut/RRArbiterInitVariants/gen.py 生成，勿手改。
//
// 设计源：rocket-chip util/Arbiters.scala (class LockingRRArbiter)
// golden 对照：G1-canonical/golden-rtl/RRArbiterInit_20.sv
// =============================================================================
package rrarbiterinit_20_pkg;
  // payload 字段表：顺序 = golden io_out_bits_* 的端口顺序，靠前者占高位。
  // 打平成 151 位送进仲裁核，核只按 chosen 选一路，不看字段结构。
  typedef struct packed {
    logic [3:0]  qos;
    logic [10:0] tgtID;
    logic [11:0] txnID;
    logic [10:0] returnNID;
    logic        stashNIDValid;
    logic [11:0] returnTxnID;
    logic [6:0]  opcode;
    logic [2:0]  size;
    logic [47:0] addr;
    logic        ns;
    logic        likelyshared;
    logic        allowRetry;
    logic [1:0]  order;
    logic [3:0]  pCrdType;
    logic        memAttr_allocate;
    logic        memAttr_cacheable;
    logic        memAttr_device;
    logic        memAttr_ewa;
    logic        snpAttr;
    logic [7:0]  lpIDWithPadding;
    logic        snoopMe;
    logic        expCompAck;
    logic [1:0]  tagOp;
    logic        traceTag;
    logic        mpam_perfMonGroup;
    logic [8:0]  mpam_partID;
    logic        mpam_mpamNS;
    logic [3:0]  rsvdc;
  } payload_t;
endpackage

module RRArbiterInit_20 import rrarbiterinit_20_pkg::*; (
  input         clock,
  input         reset,
  output        io_in_0_ready,
  input         io_in_0_valid,
  input  [3:0]  io_in_0_bits_qos,
  input  [11:0] io_in_0_bits_txnID,
  input  [10:0] io_in_0_bits_returnNID,
  input         io_in_0_bits_stashNIDValid,
  input  [11:0] io_in_0_bits_returnTxnID,
  input  [6:0]  io_in_0_bits_opcode,
  input  [47:0] io_in_0_bits_addr,
  input         io_in_0_bits_ns,
  input         io_in_0_bits_likelyshared,
  input         io_in_0_bits_allowRetry,
  input  [1:0]  io_in_0_bits_order,
  input  [3:0]  io_in_0_bits_pCrdType,
  input         io_in_0_bits_memAttr_allocate,
  input         io_in_0_bits_memAttr_cacheable,
  input         io_in_0_bits_memAttr_device,
  input         io_in_0_bits_memAttr_ewa,
  input         io_in_0_bits_snpAttr,
  input  [7:0]  io_in_0_bits_lpIDWithPadding,
  input         io_in_0_bits_snoopMe,
  input         io_in_0_bits_expCompAck,
  input  [1:0]  io_in_0_bits_tagOp,
  input         io_in_0_bits_traceTag,
  input         io_in_0_bits_mpam_perfMonGroup,
  input  [8:0]  io_in_0_bits_mpam_partID,
  input         io_in_0_bits_mpam_mpamNS,
  input  [3:0]  io_in_0_bits_rsvdc,
  output        io_in_1_ready,
  input         io_in_1_valid,
  input  [3:0]  io_in_1_bits_qos,
  input  [11:0] io_in_1_bits_txnID,
  input  [10:0] io_in_1_bits_returnNID,
  input         io_in_1_bits_stashNIDValid,
  input  [11:0] io_in_1_bits_returnTxnID,
  input  [6:0]  io_in_1_bits_opcode,
  input  [47:0] io_in_1_bits_addr,
  input         io_in_1_bits_ns,
  input         io_in_1_bits_likelyshared,
  input         io_in_1_bits_allowRetry,
  input  [1:0]  io_in_1_bits_order,
  input  [3:0]  io_in_1_bits_pCrdType,
  input         io_in_1_bits_memAttr_allocate,
  input         io_in_1_bits_memAttr_cacheable,
  input         io_in_1_bits_memAttr_device,
  input         io_in_1_bits_memAttr_ewa,
  input         io_in_1_bits_snpAttr,
  input  [7:0]  io_in_1_bits_lpIDWithPadding,
  input         io_in_1_bits_snoopMe,
  input         io_in_1_bits_expCompAck,
  input  [1:0]  io_in_1_bits_tagOp,
  input         io_in_1_bits_traceTag,
  input         io_in_1_bits_mpam_perfMonGroup,
  input  [8:0]  io_in_1_bits_mpam_partID,
  input         io_in_1_bits_mpam_mpamNS,
  input  [3:0]  io_in_1_bits_rsvdc,
  output        io_in_2_ready,
  input         io_in_2_valid,
  input  [3:0]  io_in_2_bits_qos,
  input  [11:0] io_in_2_bits_txnID,
  input  [10:0] io_in_2_bits_returnNID,
  input         io_in_2_bits_stashNIDValid,
  input  [11:0] io_in_2_bits_returnTxnID,
  input  [6:0]  io_in_2_bits_opcode,
  input  [47:0] io_in_2_bits_addr,
  input         io_in_2_bits_ns,
  input         io_in_2_bits_likelyshared,
  input         io_in_2_bits_allowRetry,
  input  [1:0]  io_in_2_bits_order,
  input  [3:0]  io_in_2_bits_pCrdType,
  input         io_in_2_bits_memAttr_allocate,
  input         io_in_2_bits_memAttr_cacheable,
  input         io_in_2_bits_memAttr_device,
  input         io_in_2_bits_memAttr_ewa,
  input         io_in_2_bits_snpAttr,
  input  [7:0]  io_in_2_bits_lpIDWithPadding,
  input         io_in_2_bits_snoopMe,
  input         io_in_2_bits_expCompAck,
  input  [1:0]  io_in_2_bits_tagOp,
  input         io_in_2_bits_traceTag,
  input         io_in_2_bits_mpam_perfMonGroup,
  input  [8:0]  io_in_2_bits_mpam_partID,
  input         io_in_2_bits_mpam_mpamNS,
  input  [3:0]  io_in_2_bits_rsvdc,
  output        io_in_3_ready,
  input         io_in_3_valid,
  input  [3:0]  io_in_3_bits_qos,
  input  [11:0] io_in_3_bits_txnID,
  input  [10:0] io_in_3_bits_returnNID,
  input         io_in_3_bits_stashNIDValid,
  input  [11:0] io_in_3_bits_returnTxnID,
  input  [6:0]  io_in_3_bits_opcode,
  input  [47:0] io_in_3_bits_addr,
  input         io_in_3_bits_ns,
  input         io_in_3_bits_likelyshared,
  input         io_in_3_bits_allowRetry,
  input  [1:0]  io_in_3_bits_order,
  input  [3:0]  io_in_3_bits_pCrdType,
  input         io_in_3_bits_memAttr_allocate,
  input         io_in_3_bits_memAttr_cacheable,
  input         io_in_3_bits_memAttr_device,
  input         io_in_3_bits_memAttr_ewa,
  input         io_in_3_bits_snpAttr,
  input  [7:0]  io_in_3_bits_lpIDWithPadding,
  input         io_in_3_bits_snoopMe,
  input         io_in_3_bits_expCompAck,
  input  [1:0]  io_in_3_bits_tagOp,
  input         io_in_3_bits_traceTag,
  input         io_in_3_bits_mpam_perfMonGroup,
  input  [8:0]  io_in_3_bits_mpam_partID,
  input         io_in_3_bits_mpam_mpamNS,
  input  [3:0]  io_in_3_bits_rsvdc,
  output        io_in_4_ready,
  input         io_in_4_valid,
  input  [3:0]  io_in_4_bits_qos,
  input  [10:0] io_in_4_bits_tgtID,
  input  [11:0] io_in_4_bits_txnID,
  input  [10:0] io_in_4_bits_returnNID,
  input         io_in_4_bits_stashNIDValid,
  input  [11:0] io_in_4_bits_returnTxnID,
  input  [6:0]  io_in_4_bits_opcode,
  input  [2:0]  io_in_4_bits_size,
  input  [47:0] io_in_4_bits_addr,
  input         io_in_4_bits_ns,
  input         io_in_4_bits_likelyshared,
  input         io_in_4_bits_allowRetry,
  input  [1:0]  io_in_4_bits_order,
  input  [3:0]  io_in_4_bits_pCrdType,
  input         io_in_4_bits_memAttr_allocate,
  input         io_in_4_bits_memAttr_cacheable,
  input         io_in_4_bits_memAttr_device,
  input         io_in_4_bits_memAttr_ewa,
  input         io_in_4_bits_snpAttr,
  input  [7:0]  io_in_4_bits_lpIDWithPadding,
  input         io_in_4_bits_snoopMe,
  input         io_in_4_bits_expCompAck,
  input  [1:0]  io_in_4_bits_tagOp,
  input         io_in_4_bits_traceTag,
  input         io_in_4_bits_mpam_perfMonGroup,
  input  [8:0]  io_in_4_bits_mpam_partID,
  input         io_in_4_bits_mpam_mpamNS,
  input  [3:0]  io_in_4_bits_rsvdc,
  input         io_out_ready,
  output        io_out_valid,
  output [3:0]  io_out_bits_qos,
  output [10:0] io_out_bits_tgtID,
  output [11:0] io_out_bits_txnID,
  output [10:0] io_out_bits_returnNID,
  output        io_out_bits_stashNIDValid,
  output [11:0] io_out_bits_returnTxnID,
  output [6:0]  io_out_bits_opcode,
  output [2:0]  io_out_bits_size,
  output [47:0] io_out_bits_addr,
  output        io_out_bits_ns,
  output        io_out_bits_likelyshared,
  output        io_out_bits_allowRetry,
  output [1:0]  io_out_bits_order,
  output [3:0]  io_out_bits_pCrdType,
  output        io_out_bits_memAttr_allocate,
  output        io_out_bits_memAttr_cacheable,
  output        io_out_bits_memAttr_device,
  output        io_out_bits_memAttr_ewa,
  output        io_out_bits_snpAttr,
  output [7:0]  io_out_bits_lpIDWithPadding,
  output        io_out_bits_snoopMe,
  output        io_out_bits_expCompAck,
  output [1:0]  io_out_bits_tagOp,
  output        io_out_bits_traceTag,
  output        io_out_bits_mpam_perfMonGroup,
  output [8:0]  io_out_bits_mpam_partID,
  output        io_out_bits_mpam_mpamNS,
  output [3:0]  io_out_bits_rsvdc,
  output [2:0]  io_chosen
);
  localparam int N = 5;
  localparam int W = $bits(payload_t);

  // 打包：每一路按字段表顺序拼成 W 位（下面的拆包用同一张表，反过来一次）。
  payload_t [N-1:0] in_payload;
  assign in_payload[0] = {
    io_in_0_bits_qos,
    11'h0,
    io_in_0_bits_txnID,
    io_in_0_bits_returnNID,
    io_in_0_bits_stashNIDValid,
    io_in_0_bits_returnTxnID,
    io_in_0_bits_opcode,
    3'h6,
    io_in_0_bits_addr,
    io_in_0_bits_ns,
    io_in_0_bits_likelyshared,
    io_in_0_bits_allowRetry,
    io_in_0_bits_order,
    io_in_0_bits_pCrdType,
    io_in_0_bits_memAttr_allocate,
    io_in_0_bits_memAttr_cacheable,
    io_in_0_bits_memAttr_device,
    io_in_0_bits_memAttr_ewa,
    io_in_0_bits_snpAttr,
    io_in_0_bits_lpIDWithPadding,
    io_in_0_bits_snoopMe,
    io_in_0_bits_expCompAck,
    io_in_0_bits_tagOp,
    io_in_0_bits_traceTag,
    io_in_0_bits_mpam_perfMonGroup,
    io_in_0_bits_mpam_partID,
    io_in_0_bits_mpam_mpamNS,
    io_in_0_bits_rsvdc};
  assign in_payload[1] = {
    io_in_1_bits_qos,
    11'h0,
    io_in_1_bits_txnID,
    io_in_1_bits_returnNID,
    io_in_1_bits_stashNIDValid,
    io_in_1_bits_returnTxnID,
    io_in_1_bits_opcode,
    3'h6,
    io_in_1_bits_addr,
    io_in_1_bits_ns,
    io_in_1_bits_likelyshared,
    io_in_1_bits_allowRetry,
    io_in_1_bits_order,
    io_in_1_bits_pCrdType,
    io_in_1_bits_memAttr_allocate,
    io_in_1_bits_memAttr_cacheable,
    io_in_1_bits_memAttr_device,
    io_in_1_bits_memAttr_ewa,
    io_in_1_bits_snpAttr,
    io_in_1_bits_lpIDWithPadding,
    io_in_1_bits_snoopMe,
    io_in_1_bits_expCompAck,
    io_in_1_bits_tagOp,
    io_in_1_bits_traceTag,
    io_in_1_bits_mpam_perfMonGroup,
    io_in_1_bits_mpam_partID,
    io_in_1_bits_mpam_mpamNS,
    io_in_1_bits_rsvdc};
  assign in_payload[2] = {
    io_in_2_bits_qos,
    11'h0,
    io_in_2_bits_txnID,
    io_in_2_bits_returnNID,
    io_in_2_bits_stashNIDValid,
    io_in_2_bits_returnTxnID,
    io_in_2_bits_opcode,
    3'h6,
    io_in_2_bits_addr,
    io_in_2_bits_ns,
    io_in_2_bits_likelyshared,
    io_in_2_bits_allowRetry,
    io_in_2_bits_order,
    io_in_2_bits_pCrdType,
    io_in_2_bits_memAttr_allocate,
    io_in_2_bits_memAttr_cacheable,
    io_in_2_bits_memAttr_device,
    io_in_2_bits_memAttr_ewa,
    io_in_2_bits_snpAttr,
    io_in_2_bits_lpIDWithPadding,
    io_in_2_bits_snoopMe,
    io_in_2_bits_expCompAck,
    io_in_2_bits_tagOp,
    io_in_2_bits_traceTag,
    io_in_2_bits_mpam_perfMonGroup,
    io_in_2_bits_mpam_partID,
    io_in_2_bits_mpam_mpamNS,
    io_in_2_bits_rsvdc};
  assign in_payload[3] = {
    io_in_3_bits_qos,
    11'h0,
    io_in_3_bits_txnID,
    io_in_3_bits_returnNID,
    io_in_3_bits_stashNIDValid,
    io_in_3_bits_returnTxnID,
    io_in_3_bits_opcode,
    3'h6,
    io_in_3_bits_addr,
    io_in_3_bits_ns,
    io_in_3_bits_likelyshared,
    io_in_3_bits_allowRetry,
    io_in_3_bits_order,
    io_in_3_bits_pCrdType,
    io_in_3_bits_memAttr_allocate,
    io_in_3_bits_memAttr_cacheable,
    io_in_3_bits_memAttr_device,
    io_in_3_bits_memAttr_ewa,
    io_in_3_bits_snpAttr,
    io_in_3_bits_lpIDWithPadding,
    io_in_3_bits_snoopMe,
    io_in_3_bits_expCompAck,
    io_in_3_bits_tagOp,
    io_in_3_bits_traceTag,
    io_in_3_bits_mpam_perfMonGroup,
    io_in_3_bits_mpam_partID,
    io_in_3_bits_mpam_mpamNS,
    io_in_3_bits_rsvdc};
  assign in_payload[4] = {
    io_in_4_bits_qos,
    io_in_4_bits_tgtID,
    io_in_4_bits_txnID,
    io_in_4_bits_returnNID,
    io_in_4_bits_stashNIDValid,
    io_in_4_bits_returnTxnID,
    io_in_4_bits_opcode,
    io_in_4_bits_size,
    io_in_4_bits_addr,
    io_in_4_bits_ns,
    io_in_4_bits_likelyshared,
    io_in_4_bits_allowRetry,
    io_in_4_bits_order,
    io_in_4_bits_pCrdType,
    io_in_4_bits_memAttr_allocate,
    io_in_4_bits_memAttr_cacheable,
    io_in_4_bits_memAttr_device,
    io_in_4_bits_memAttr_ewa,
    io_in_4_bits_snpAttr,
    io_in_4_bits_lpIDWithPadding,
    io_in_4_bits_snoopMe,
    io_in_4_bits_expCompAck,
    io_in_4_bits_tagOp,
    io_in_4_bits_traceTag,
    io_in_4_bits_mpam_perfMonGroup,
    io_in_4_bits_mpam_partID,
    io_in_4_bits_mpam_mpamNS,
    io_in_4_bits_rsvdc};

  payload_t out_payload;
  xs_RRArbiterInit_core #(.N(N), .W(W)) u_core (
    .clock     (clock),
    .reset     (reset),
    .in_valid  ({io_in_4_valid, io_in_3_valid, io_in_2_valid, io_in_1_valid,
                 io_in_0_valid}),
    .in_bits   (in_payload),
    .in_ready  ({io_in_4_ready, io_in_3_ready, io_in_2_ready, io_in_1_ready,
                 io_in_0_ready}),
    .out_ready (io_out_ready),
    .out_valid (io_out_valid),
    .out_bits  (out_payload),
    .chosen    (io_chosen)
  );

  // 拆包：与上面的打包共用同一张字段表。
  assign io_out_bits_qos = out_payload.qos;
  assign io_out_bits_tgtID = out_payload.tgtID;
  assign io_out_bits_txnID = out_payload.txnID;
  assign io_out_bits_returnNID = out_payload.returnNID;
  assign io_out_bits_stashNIDValid = out_payload.stashNIDValid;
  assign io_out_bits_returnTxnID = out_payload.returnTxnID;
  assign io_out_bits_opcode = out_payload.opcode;
  assign io_out_bits_size = out_payload.size;
  assign io_out_bits_addr = out_payload.addr;
  assign io_out_bits_ns = out_payload.ns;
  assign io_out_bits_likelyshared = out_payload.likelyshared;
  assign io_out_bits_allowRetry = out_payload.allowRetry;
  assign io_out_bits_order = out_payload.order;
  assign io_out_bits_pCrdType = out_payload.pCrdType;
  assign io_out_bits_memAttr_allocate = out_payload.memAttr_allocate;
  assign io_out_bits_memAttr_cacheable = out_payload.memAttr_cacheable;
  assign io_out_bits_memAttr_device = out_payload.memAttr_device;
  assign io_out_bits_memAttr_ewa = out_payload.memAttr_ewa;
  assign io_out_bits_snpAttr = out_payload.snpAttr;
  assign io_out_bits_lpIDWithPadding = out_payload.lpIDWithPadding;
  assign io_out_bits_snoopMe = out_payload.snoopMe;
  assign io_out_bits_expCompAck = out_payload.expCompAck;
  assign io_out_bits_tagOp = out_payload.tagOp;
  assign io_out_bits_traceTag = out_payload.traceTag;
  assign io_out_bits_mpam_perfMonGroup = out_payload.mpam_perfMonGroup;
  assign io_out_bits_mpam_partID = out_payload.mpam_partID;
  assign io_out_bits_mpam_mpamNS = out_payload.mpam_mpamNS;
  assign io_out_bits_rsvdc = out_payload.rsvdc;
endmodule
