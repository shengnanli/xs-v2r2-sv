// =============================================================================
// FastArbiter_26.sv —— FastArbiter 家族薄 wrapper：L2 4 个 slice 的 CHI TXRSP 汇成一路下游的仲裁（带赢家下标 io_chosen）
//
// 本变体规模：N=4 路，载荷打平 W=62 位（12 个字段，无常量字段）。
//   例化者：TL2CHICoupledL2.sv（实例 txrsp_arb）、RNXbar.sv（实例 rxrspArbs_0）。
//   多一个 io_chosen 输出 = 赢家下标（OHToUInt(chosenOH)）。核不导出 chosenOH，这里在
//   载荷低 N 位捎带第 k 路的独热标识 1<<k：核按 Mux1H（按位或）选载荷，输出低 N 位
//   恰好就是 chosenOH（无人 valid 时全 0）—— 与 FastArbiter_2 同一做法，不改已签核的核。
//
// 本文件只做"字段打包 → 核 → 拆包"的端口对位；仲裁逻辑（轮转 + 挂起记忆）
// 在 rtl/common/xs_FastArbiter_core.sv，全家族共一份。
// 本文件由 scripts/gen_fastarbiter_l2c.py 生成，勿手改。
// golden 对照：G1-canonical/golden-rtl/FastArbiter_26.sv
// =============================================================================
package fastarbiter_26_pkg;
  // 载荷字段表：顺序 = golden io_out_bits_* 的端口顺序，靠前者占高位。
  typedef struct packed {
    logic [3:0]  qos;
    logic [10:0] tgtID;
    logic [11:0] txnID;
    logic [4:0]  opcode;
    logic [1:0]  respErr;
    logic [2:0]  resp;
    logic [2:0]  fwdState;
    logic [2:0]  cBusy;
    logic [11:0] dbID;
    logic [3:0]  pCrdType;
    logic [1:0]  tagOp;
    logic        traceTag;
  } payload_t;
endpackage

module FastArbiter_26 import fastarbiter_26_pkg::*; (
  input         clock,
  input         reset,
  output        io_in_0_ready,
  input         io_in_0_valid,
  input  [3:0]  io_in_0_bits_qos,
  input  [10:0] io_in_0_bits_tgtID,
  input  [11:0] io_in_0_bits_txnID,
  input  [4:0]  io_in_0_bits_opcode,
  input  [1:0]  io_in_0_bits_respErr,
  input  [2:0]  io_in_0_bits_resp,
  input  [2:0]  io_in_0_bits_fwdState,
  input  [2:0]  io_in_0_bits_cBusy,
  input  [11:0] io_in_0_bits_dbID,
  input  [3:0]  io_in_0_bits_pCrdType,
  input  [1:0]  io_in_0_bits_tagOp,
  input         io_in_0_bits_traceTag,
  output        io_in_1_ready,
  input         io_in_1_valid,
  input  [3:0]  io_in_1_bits_qos,
  input  [10:0] io_in_1_bits_tgtID,
  input  [11:0] io_in_1_bits_txnID,
  input  [4:0]  io_in_1_bits_opcode,
  input  [1:0]  io_in_1_bits_respErr,
  input  [2:0]  io_in_1_bits_resp,
  input  [2:0]  io_in_1_bits_fwdState,
  input  [2:0]  io_in_1_bits_cBusy,
  input  [11:0] io_in_1_bits_dbID,
  input  [3:0]  io_in_1_bits_pCrdType,
  input  [1:0]  io_in_1_bits_tagOp,
  input         io_in_1_bits_traceTag,
  output        io_in_2_ready,
  input         io_in_2_valid,
  input  [3:0]  io_in_2_bits_qos,
  input  [10:0] io_in_2_bits_tgtID,
  input  [11:0] io_in_2_bits_txnID,
  input  [4:0]  io_in_2_bits_opcode,
  input  [1:0]  io_in_2_bits_respErr,
  input  [2:0]  io_in_2_bits_resp,
  input  [2:0]  io_in_2_bits_fwdState,
  input  [2:0]  io_in_2_bits_cBusy,
  input  [11:0] io_in_2_bits_dbID,
  input  [3:0]  io_in_2_bits_pCrdType,
  input  [1:0]  io_in_2_bits_tagOp,
  input         io_in_2_bits_traceTag,
  output        io_in_3_ready,
  input         io_in_3_valid,
  input  [3:0]  io_in_3_bits_qos,
  input  [10:0] io_in_3_bits_tgtID,
  input  [11:0] io_in_3_bits_txnID,
  input  [4:0]  io_in_3_bits_opcode,
  input  [1:0]  io_in_3_bits_respErr,
  input  [2:0]  io_in_3_bits_resp,
  input  [2:0]  io_in_3_bits_fwdState,
  input  [2:0]  io_in_3_bits_cBusy,
  input  [11:0] io_in_3_bits_dbID,
  input  [3:0]  io_in_3_bits_pCrdType,
  input  [1:0]  io_in_3_bits_tagOp,
  input         io_in_3_bits_traceTag,
  input         io_out_ready,
  output        io_out_valid,
  output [3:0]  io_out_bits_qos,
  output [10:0] io_out_bits_tgtID,
  output [11:0] io_out_bits_txnID,
  output [4:0]  io_out_bits_opcode,
  output [1:0]  io_out_bits_respErr,
  output [2:0]  io_out_bits_resp,
  output [2:0]  io_out_bits_fwdState,
  output [2:0]  io_out_bits_cBusy,
  output [11:0] io_out_bits_dbID,
  output [3:0]  io_out_bits_pCrdType,
  output [1:0]  io_out_bits_tagOp,
  output        io_out_bits_traceTag,
  output [1:0]  io_chosen
);
  localparam int N = 4;
  localparam int W = $bits(payload_t);

  // 每路送进核的字 = {载荷, 独热标识}
  typedef struct packed {
    payload_t     payload;
    logic [N-1:0] tag_oh;   // 第 k 路恒为 1<<k
  } word_t;

  // ---- 打包：第 i 路的全部字段按字段表拼成一个 payload_t，低位捎带独热标识
  word_t [N-1:0] in_word;
  assign in_word[0] = '{
    payload: '{
      qos: io_in_0_bits_qos,
      tgtID: io_in_0_bits_tgtID,
      txnID: io_in_0_bits_txnID,
      opcode: io_in_0_bits_opcode,
      respErr: io_in_0_bits_respErr,
      resp: io_in_0_bits_resp,
      fwdState: io_in_0_bits_fwdState,
      cBusy: io_in_0_bits_cBusy,
      dbID: io_in_0_bits_dbID,
      pCrdType: io_in_0_bits_pCrdType,
      tagOp: io_in_0_bits_tagOp,
      traceTag: io_in_0_bits_traceTag
    },
    tag_oh: N'(1 << 0)
  };
  assign in_word[1] = '{
    payload: '{
      qos: io_in_1_bits_qos,
      tgtID: io_in_1_bits_tgtID,
      txnID: io_in_1_bits_txnID,
      opcode: io_in_1_bits_opcode,
      respErr: io_in_1_bits_respErr,
      resp: io_in_1_bits_resp,
      fwdState: io_in_1_bits_fwdState,
      cBusy: io_in_1_bits_cBusy,
      dbID: io_in_1_bits_dbID,
      pCrdType: io_in_1_bits_pCrdType,
      tagOp: io_in_1_bits_tagOp,
      traceTag: io_in_1_bits_traceTag
    },
    tag_oh: N'(1 << 1)
  };
  assign in_word[2] = '{
    payload: '{
      qos: io_in_2_bits_qos,
      tgtID: io_in_2_bits_tgtID,
      txnID: io_in_2_bits_txnID,
      opcode: io_in_2_bits_opcode,
      respErr: io_in_2_bits_respErr,
      resp: io_in_2_bits_resp,
      fwdState: io_in_2_bits_fwdState,
      cBusy: io_in_2_bits_cBusy,
      dbID: io_in_2_bits_dbID,
      pCrdType: io_in_2_bits_pCrdType,
      tagOp: io_in_2_bits_tagOp,
      traceTag: io_in_2_bits_traceTag
    },
    tag_oh: N'(1 << 2)
  };
  assign in_word[3] = '{
    payload: '{
      qos: io_in_3_bits_qos,
      tgtID: io_in_3_bits_tgtID,
      txnID: io_in_3_bits_txnID,
      opcode: io_in_3_bits_opcode,
      respErr: io_in_3_bits_respErr,
      resp: io_in_3_bits_resp,
      fwdState: io_in_3_bits_fwdState,
      cBusy: io_in_3_bits_cBusy,
      dbID: io_in_3_bits_dbID,
      pCrdType: io_in_3_bits_pCrdType,
      tagOp: io_in_3_bits_tagOp,
      traceTag: io_in_3_bits_traceTag
    },
    tag_oh: N'(1 << 3)
  };

  // ---- 核例化：仲裁逻辑全在 xs_FastArbiter_core
  word_t out_word;
  xs_FastArbiter_core #(.N(N), .W($bits(word_t))) u_core (
    .clock     (clock),
    .reset     (reset),
    .in_valid  ({io_in_3_valid, io_in_2_valid, io_in_1_valid, io_in_0_valid}),
    .in_bits   (in_word),
    .in_ready  ({io_in_3_ready, io_in_2_ready, io_in_1_ready, io_in_0_ready}),
    .out_ready (io_out_ready),
    .out_valid (io_out_valid),
    .out_bits  (out_word)
  );

  // ---- 拆包：与打包共用同一张字段表
  assign io_out_bits_qos = out_word.payload.qos;
  assign io_out_bits_tgtID = out_word.payload.tgtID;
  assign io_out_bits_txnID = out_word.payload.txnID;
  assign io_out_bits_opcode = out_word.payload.opcode;
  assign io_out_bits_respErr = out_word.payload.respErr;
  assign io_out_bits_resp = out_word.payload.resp;
  assign io_out_bits_fwdState = out_word.payload.fwdState;
  assign io_out_bits_cBusy = out_word.payload.cBusy;
  assign io_out_bits_dbID = out_word.payload.dbID;
  assign io_out_bits_pCrdType = out_word.payload.pCrdType;
  assign io_out_bits_tagOp = out_word.payload.tagOp;
  assign io_out_bits_traceTag = out_word.payload.traceTag;

  // ---- 赢家下标：OHToUInt(chosenOH)，chosenOH = 载荷捎带回来的独热标识
  logic [N-1:0] chosen_oh;
  assign chosen_oh = out_word.tag_oh;
  assign io_chosen = {chosen_oh[3] | chosen_oh[2], chosen_oh[3] | chosen_oh[1]};
endmodule
