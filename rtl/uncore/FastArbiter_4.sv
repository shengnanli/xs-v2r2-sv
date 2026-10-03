// =============================================================================
// FastArbiter_4.sv —— FastArbiter 家族薄 wrapper：L2 MSHRCtl 16 个 MSHR 发往 CHI TXRSP（CompAck）的仲裁
//
// 本变体规模：N=16 路，载荷打平 W=29 位（4 个字段，其中 1 个常量字段）。
//   例化者：MSHRCtl.sv（实例 txrsp_arb）。
//   常量字段：每个请求方给这些字段喂的都是同一个常量，firtool 于是删掉了它们
//   的输入端口、把输出折成 `K & |chosenOH`。本文件把常量喂进每一路，核里的
//   Mux1H 自然得出同一结果：
//     opcode                   = 5'h2   —— MSHR.scala:347 orsp.opcode := CompAck
//
// 本文件只做"字段打包 → 核 → 拆包"的端口对位；仲裁逻辑（轮转 + 挂起记忆）
// 在 rtl/common/xs_FastArbiter_core.sv，全家族共一份。
// 本文件由 scripts/gen_fastarbiter_l2.py 生成，勿手改。
// golden 对照：G1-canonical/golden-rtl/FastArbiter_4.sv
// =============================================================================
package fastarbiter_4_pkg;
  // 载荷字段表：顺序 = golden io_out_bits_* 的端口顺序，靠前者占高位。
  typedef struct packed {
    logic [10:0] tgtID;
    logic [11:0] txnID;
    logic [4:0]  opcode;   // 常量 5'h2
    logic        traceTag;
  } payload_t;
endpackage

module FastArbiter_4 import fastarbiter_4_pkg::*; (
  input         clock,
  input         reset,
  output        io_in_0_ready,
  input         io_in_0_valid,
  input  [10:0] io_in_0_bits_tgtID,
  input  [11:0] io_in_0_bits_txnID,
  input         io_in_0_bits_traceTag,
  output        io_in_1_ready,
  input         io_in_1_valid,
  input  [10:0] io_in_1_bits_tgtID,
  input  [11:0] io_in_1_bits_txnID,
  input         io_in_1_bits_traceTag,
  output        io_in_2_ready,
  input         io_in_2_valid,
  input  [10:0] io_in_2_bits_tgtID,
  input  [11:0] io_in_2_bits_txnID,
  input         io_in_2_bits_traceTag,
  output        io_in_3_ready,
  input         io_in_3_valid,
  input  [10:0] io_in_3_bits_tgtID,
  input  [11:0] io_in_3_bits_txnID,
  input         io_in_3_bits_traceTag,
  output        io_in_4_ready,
  input         io_in_4_valid,
  input  [10:0] io_in_4_bits_tgtID,
  input  [11:0] io_in_4_bits_txnID,
  input         io_in_4_bits_traceTag,
  output        io_in_5_ready,
  input         io_in_5_valid,
  input  [10:0] io_in_5_bits_tgtID,
  input  [11:0] io_in_5_bits_txnID,
  input         io_in_5_bits_traceTag,
  output        io_in_6_ready,
  input         io_in_6_valid,
  input  [10:0] io_in_6_bits_tgtID,
  input  [11:0] io_in_6_bits_txnID,
  input         io_in_6_bits_traceTag,
  output        io_in_7_ready,
  input         io_in_7_valid,
  input  [10:0] io_in_7_bits_tgtID,
  input  [11:0] io_in_7_bits_txnID,
  input         io_in_7_bits_traceTag,
  output        io_in_8_ready,
  input         io_in_8_valid,
  input  [10:0] io_in_8_bits_tgtID,
  input  [11:0] io_in_8_bits_txnID,
  input         io_in_8_bits_traceTag,
  output        io_in_9_ready,
  input         io_in_9_valid,
  input  [10:0] io_in_9_bits_tgtID,
  input  [11:0] io_in_9_bits_txnID,
  input         io_in_9_bits_traceTag,
  output        io_in_10_ready,
  input         io_in_10_valid,
  input  [10:0] io_in_10_bits_tgtID,
  input  [11:0] io_in_10_bits_txnID,
  input         io_in_10_bits_traceTag,
  output        io_in_11_ready,
  input         io_in_11_valid,
  input  [10:0] io_in_11_bits_tgtID,
  input  [11:0] io_in_11_bits_txnID,
  input         io_in_11_bits_traceTag,
  output        io_in_12_ready,
  input         io_in_12_valid,
  input  [10:0] io_in_12_bits_tgtID,
  input  [11:0] io_in_12_bits_txnID,
  input         io_in_12_bits_traceTag,
  output        io_in_13_ready,
  input         io_in_13_valid,
  input  [10:0] io_in_13_bits_tgtID,
  input  [11:0] io_in_13_bits_txnID,
  input         io_in_13_bits_traceTag,
  output        io_in_14_ready,
  input         io_in_14_valid,
  input  [10:0] io_in_14_bits_tgtID,
  input  [11:0] io_in_14_bits_txnID,
  input         io_in_14_bits_traceTag,
  output        io_in_15_ready,
  input         io_in_15_valid,
  input  [10:0] io_in_15_bits_tgtID,
  input  [11:0] io_in_15_bits_txnID,
  input         io_in_15_bits_traceTag,
  input         io_out_ready,
  output        io_out_valid,
  output [10:0] io_out_bits_tgtID,
  output [11:0] io_out_bits_txnID,
  output [4:0]  io_out_bits_opcode,
  output        io_out_bits_traceTag
);
  localparam int N = 16;
  localparam int W = $bits(payload_t);

  // ---- 打包：第 i 路的全部字段按字段表拼成一个 payload_t（常量字段每路都喂同一个值）
  payload_t [N-1:0] in_payload;
  assign in_payload[0] = '{
    tgtID: io_in_0_bits_tgtID,
    txnID: io_in_0_bits_txnID,
    opcode: 5'h2,
    traceTag: io_in_0_bits_traceTag
  };
  assign in_payload[1] = '{
    tgtID: io_in_1_bits_tgtID,
    txnID: io_in_1_bits_txnID,
    opcode: 5'h2,
    traceTag: io_in_1_bits_traceTag
  };
  assign in_payload[2] = '{
    tgtID: io_in_2_bits_tgtID,
    txnID: io_in_2_bits_txnID,
    opcode: 5'h2,
    traceTag: io_in_2_bits_traceTag
  };
  assign in_payload[3] = '{
    tgtID: io_in_3_bits_tgtID,
    txnID: io_in_3_bits_txnID,
    opcode: 5'h2,
    traceTag: io_in_3_bits_traceTag
  };
  assign in_payload[4] = '{
    tgtID: io_in_4_bits_tgtID,
    txnID: io_in_4_bits_txnID,
    opcode: 5'h2,
    traceTag: io_in_4_bits_traceTag
  };
  assign in_payload[5] = '{
    tgtID: io_in_5_bits_tgtID,
    txnID: io_in_5_bits_txnID,
    opcode: 5'h2,
    traceTag: io_in_5_bits_traceTag
  };
  assign in_payload[6] = '{
    tgtID: io_in_6_bits_tgtID,
    txnID: io_in_6_bits_txnID,
    opcode: 5'h2,
    traceTag: io_in_6_bits_traceTag
  };
  assign in_payload[7] = '{
    tgtID: io_in_7_bits_tgtID,
    txnID: io_in_7_bits_txnID,
    opcode: 5'h2,
    traceTag: io_in_7_bits_traceTag
  };
  assign in_payload[8] = '{
    tgtID: io_in_8_bits_tgtID,
    txnID: io_in_8_bits_txnID,
    opcode: 5'h2,
    traceTag: io_in_8_bits_traceTag
  };
  assign in_payload[9] = '{
    tgtID: io_in_9_bits_tgtID,
    txnID: io_in_9_bits_txnID,
    opcode: 5'h2,
    traceTag: io_in_9_bits_traceTag
  };
  assign in_payload[10] = '{
    tgtID: io_in_10_bits_tgtID,
    txnID: io_in_10_bits_txnID,
    opcode: 5'h2,
    traceTag: io_in_10_bits_traceTag
  };
  assign in_payload[11] = '{
    tgtID: io_in_11_bits_tgtID,
    txnID: io_in_11_bits_txnID,
    opcode: 5'h2,
    traceTag: io_in_11_bits_traceTag
  };
  assign in_payload[12] = '{
    tgtID: io_in_12_bits_tgtID,
    txnID: io_in_12_bits_txnID,
    opcode: 5'h2,
    traceTag: io_in_12_bits_traceTag
  };
  assign in_payload[13] = '{
    tgtID: io_in_13_bits_tgtID,
    txnID: io_in_13_bits_txnID,
    opcode: 5'h2,
    traceTag: io_in_13_bits_traceTag
  };
  assign in_payload[14] = '{
    tgtID: io_in_14_bits_tgtID,
    txnID: io_in_14_bits_txnID,
    opcode: 5'h2,
    traceTag: io_in_14_bits_traceTag
  };
  assign in_payload[15] = '{
    tgtID: io_in_15_bits_tgtID,
    txnID: io_in_15_bits_txnID,
    opcode: 5'h2,
    traceTag: io_in_15_bits_traceTag
  };

  // ---- 核例化：仲裁逻辑全在 xs_FastArbiter_core
  payload_t out_payload;
  xs_FastArbiter_core #(.N(N), .W(W)) u_core (
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
    .out_bits  (out_payload)
  );

  // ---- 拆包：与打包共用同一张字段表
  assign io_out_bits_tgtID = out_payload.tgtID;
  assign io_out_bits_txnID = out_payload.txnID;
  assign io_out_bits_opcode = out_payload.opcode;
  assign io_out_bits_traceTag = out_payload.traceTag;
endmodule
