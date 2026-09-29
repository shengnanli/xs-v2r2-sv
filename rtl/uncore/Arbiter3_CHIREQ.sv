// Arbiter3_CHIREQ.sv —— MainPipe_1 的 toTXREQ_arb：s3/s4/s5 三级发往 CHI TXREQ 的请求（CHIREQ）并成一路
//
// chisel3 Arbiter（3 入口，lowest-index-wins，纯组合）；核是 rtl/frontend/xs_FixedPriorityArbiter_core.sv（已签核）。
// 载荷 = 每一路 13 个字段、100 位，字段表与 io_out_bits_* 逐名逐宽相同，按 golden 端口顺序 MSB 优先拼。
// ★少两根 ready★：MainPipe 对这一路的 out.ready 恒 1，firtool 把 io_out_ready 与 io_in_0_ready（= out_ready）一起删了；
// 核的 out_ready 接 1'b1，in_ready 最高位（第 0 路）悬空，端口数恒等式把这两根加回去。
// golden 206 行；本文件由 scripts/gen_l2_arbiter3.py 从 golden 端口表生成（勿手改）。

module Arbiter3_CHIREQ (
  input  logic io_in_0_valid,
  input  logic [10:0] io_in_0_bits_tgtID,
  input  logic [10:0] io_in_0_bits_srcID,
  input  logic [11:0] io_in_0_bits_txnID,
  input  logic [6:0] io_in_0_bits_opcode,
  input  logic [47:0] io_in_0_bits_addr,
  input  logic io_in_0_bits_likelyshared,
  input  logic io_in_0_bits_allowRetry,
  input  logic [3:0] io_in_0_bits_pCrdType,
  input  logic io_in_0_bits_memAttr_allocate,
  input  logic io_in_0_bits_memAttr_cacheable,
  input  logic io_in_0_bits_memAttr_device,
  input  logic io_in_0_bits_memAttr_ewa,
  input  logic io_in_0_bits_expCompAck,
  output logic io_in_1_ready,
  input  logic io_in_1_valid,
  input  logic [10:0] io_in_1_bits_tgtID,
  input  logic [10:0] io_in_1_bits_srcID,
  input  logic [11:0] io_in_1_bits_txnID,
  input  logic [6:0] io_in_1_bits_opcode,
  input  logic [47:0] io_in_1_bits_addr,
  input  logic io_in_1_bits_likelyshared,
  input  logic io_in_1_bits_allowRetry,
  input  logic [3:0] io_in_1_bits_pCrdType,
  input  logic io_in_1_bits_memAttr_allocate,
  input  logic io_in_1_bits_memAttr_cacheable,
  input  logic io_in_1_bits_memAttr_device,
  input  logic io_in_1_bits_memAttr_ewa,
  input  logic io_in_1_bits_expCompAck,
  output logic io_in_2_ready,
  input  logic io_in_2_valid,
  input  logic [10:0] io_in_2_bits_tgtID,
  input  logic [10:0] io_in_2_bits_srcID,
  input  logic [11:0] io_in_2_bits_txnID,
  input  logic [6:0] io_in_2_bits_opcode,
  input  logic [47:0] io_in_2_bits_addr,
  input  logic io_in_2_bits_likelyshared,
  input  logic io_in_2_bits_allowRetry,
  input  logic [3:0] io_in_2_bits_pCrdType,
  input  logic io_in_2_bits_memAttr_allocate,
  input  logic io_in_2_bits_memAttr_cacheable,
  input  logic io_in_2_bits_memAttr_device,
  input  logic io_in_2_bits_memAttr_ewa,
  input  logic io_in_2_bits_expCompAck,
  output logic io_out_valid,
  output logic [10:0] io_out_bits_tgtID,
  output logic [10:0] io_out_bits_srcID,
  output logic [11:0] io_out_bits_txnID,
  output logic [6:0] io_out_bits_opcode,
  output logic [47:0] io_out_bits_addr,
  output logic io_out_bits_likelyshared,
  output logic io_out_bits_allowRetry,
  output logic [3:0] io_out_bits_pCrdType,
  output logic io_out_bits_memAttr_allocate,
  output logic io_out_bits_memAttr_cacheable,
  output logic io_out_bits_memAttr_device,
  output logic io_out_bits_memAttr_ewa,
  output logic io_out_bits_expCompAck
);

  localparam int unsigned NUM_IN = 3;
  localparam int unsigned WIDTH  = 100;

  // 位 NUM_IN-1 = 第 0 路（优先级最高），与核的 in_valid 位序一致
  logic [NUM_IN-1:0]       in_valid_vec;
  logic [NUM_IN-1:0]       in_ready_vec;
  logic [NUM_IN*WIDTH-1:0] in_bits_flat;
  logic [WIDTH-1:0]        out_bits_flat;
  assign in_valid_vec = {io_in_0_valid, io_in_1_valid, io_in_2_valid};
  assign in_bits_flat = {
    {io_in_0_bits_tgtID,
     io_in_0_bits_srcID,
     io_in_0_bits_txnID,
     io_in_0_bits_opcode,
     io_in_0_bits_addr,
     io_in_0_bits_likelyshared,
     io_in_0_bits_allowRetry,
     io_in_0_bits_pCrdType,
     io_in_0_bits_memAttr_allocate,
     io_in_0_bits_memAttr_cacheable,
     io_in_0_bits_memAttr_device,
     io_in_0_bits_memAttr_ewa,
     io_in_0_bits_expCompAck},
    {io_in_1_bits_tgtID,
     io_in_1_bits_srcID,
     io_in_1_bits_txnID,
     io_in_1_bits_opcode,
     io_in_1_bits_addr,
     io_in_1_bits_likelyshared,
     io_in_1_bits_allowRetry,
     io_in_1_bits_pCrdType,
     io_in_1_bits_memAttr_allocate,
     io_in_1_bits_memAttr_cacheable,
     io_in_1_bits_memAttr_device,
     io_in_1_bits_memAttr_ewa,
     io_in_1_bits_expCompAck},
    {io_in_2_bits_tgtID,
     io_in_2_bits_srcID,
     io_in_2_bits_txnID,
     io_in_2_bits_opcode,
     io_in_2_bits_addr,
     io_in_2_bits_likelyshared,
     io_in_2_bits_allowRetry,
     io_in_2_bits_pCrdType,
     io_in_2_bits_memAttr_allocate,
     io_in_2_bits_memAttr_cacheable,
     io_in_2_bits_memAttr_device,
     io_in_2_bits_memAttr_ewa,
     io_in_2_bits_expCompAck}
  };
  assign io_in_1_ready = in_ready_vec[1];
  assign io_in_2_ready = in_ready_vec[0];

  xs_FixedPriorityArbiter_core #(
    .WIDTH            (WIDTH),
    .NUM_IN           (NUM_IN),
    .PORT_BITS_OUT    ($bits({io_out_bits_tgtID,
                         io_out_bits_srcID,
                         io_out_bits_txnID,
                         io_out_bits_opcode,
                         io_out_bits_addr,
                         io_out_bits_likelyshared,
                         io_out_bits_allowRetry,
                         io_out_bits_pCrdType,
                         io_out_bits_memAttr_allocate,
                         io_out_bits_memAttr_cacheable,
                         io_out_bits_memAttr_device,
                         io_out_bits_memAttr_ewa,
                         io_out_bits_expCompAck})),
    .PORT_BITS_LAST_IN($bits({io_in_2_bits_tgtID,
                         io_in_2_bits_srcID,
                         io_in_2_bits_txnID,
                         io_in_2_bits_opcode,
                         io_in_2_bits_addr,
                         io_in_2_bits_likelyshared,
                         io_in_2_bits_allowRetry,
                         io_in_2_bits_pCrdType,
                         io_in_2_bits_memAttr_allocate,
                         io_in_2_bits_memAttr_cacheable,
                         io_in_2_bits_memAttr_device,
                         io_in_2_bits_memAttr_ewa,
                         io_in_2_bits_expCompAck})),
    .GOLDEN_PORTS     (58 + 2),   // 现存端口 + firtool 删掉的 ready
    .GOLDEN_BITS_PORTS(52)
  ) u_core (
    .in_valid (in_valid_vec),
    .in_ready (in_ready_vec),
    .in_bits  (in_bits_flat),
    .out_ready(1'b1),
    .out_valid(io_out_valid),
    .out_bits (out_bits_flat)
  );

  assign {io_out_bits_tgtID,
          io_out_bits_srcID,
          io_out_bits_txnID,
          io_out_bits_opcode,
          io_out_bits_addr,
          io_out_bits_likelyshared,
          io_out_bits_allowRetry,
          io_out_bits_pCrdType,
          io_out_bits_memAttr_allocate,
          io_out_bits_memAttr_cacheable,
          io_out_bits_memAttr_device,
          io_out_bits_memAttr_ewa,
          io_out_bits_expCompAck} = out_bits_flat;

endmodule
