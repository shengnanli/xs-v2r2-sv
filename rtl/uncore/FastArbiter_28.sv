// =============================================================================
//  FastArbiter_28 —— 5 路 round-robin 仲裁器可读核 (xs_FastArbiter_28_core)
// -----------------------------------------------------------------------------
//  TL2CHICoupledL2 直接子: CHI DAT (data) 通道 5 路 FastArbiter。前 4 路 (0..3) 是对称
//  的 CHI DAT flit; 第 5 路 (io_in_4) 额外携带 qos/cBusy/tagOp/tag/tu/rsvdc 6 个字段
//  (input-4 专属), 其余字段 (tgtID/txnID/homeNID/opcode/respErr/resp/dataSource/dbID/
//  ccID/dataID/traceTag/be/data/dataCheck/poison) 5 路皆有。
//
//  round-robin 算法与 FastArbiter_1/2/27/44/46/47 相同, 只是 NUM=5 (5 位状态):
//    rrSelOH  = lowest_oh(rrGrantMask & pendingMask)
//    chosenOH = (rrSelOH 命中 valid) ? rrSelOH : lowest_oh(valids)
//    pendingMask <= valids & ~chosenOH; rrGrantMask <= gt_mask(chosenOH)  (下游 ready 时)
//  握手: io_in_i_ready = chosenOH[i] & io_out_ready; io_out_valid = |valids。
//  input-4 专属字段: chosenOH[4] ? io_in_4_bits_X : 0 (其余 chosen 时该输出为 0, 忠实 golden)。
//  与 golden FastArbiter_28 逐位等价。
// =============================================================================
module xs_FastArbiter_28_core (
  input          clock,
  input          reset,
  output         io_in_0_ready,
  input          io_in_0_valid,
  input  [10:0]  io_in_0_bits_tgtID,
  input  [11:0]  io_in_0_bits_txnID,
  input  [10:0]  io_in_0_bits_homeNID,
  input  [3:0]   io_in_0_bits_opcode,
  input  [1:0]   io_in_0_bits_respErr,
  input  [2:0]   io_in_0_bits_resp,
  input  [3:0]   io_in_0_bits_dataSource,
  input  [11:0]  io_in_0_bits_dbID,
  input  [1:0]   io_in_0_bits_ccID,
  input  [1:0]   io_in_0_bits_dataID,
  input          io_in_0_bits_traceTag,
  input  [31:0]  io_in_0_bits_be,
  input  [255:0] io_in_0_bits_data,
  input  [31:0]  io_in_0_bits_dataCheck,
  input  [3:0]   io_in_0_bits_poison,
  output         io_in_1_ready,
  input          io_in_1_valid,
  input  [10:0]  io_in_1_bits_tgtID,
  input  [11:0]  io_in_1_bits_txnID,
  input  [10:0]  io_in_1_bits_homeNID,
  input  [3:0]   io_in_1_bits_opcode,
  input  [1:0]   io_in_1_bits_respErr,
  input  [2:0]   io_in_1_bits_resp,
  input  [3:0]   io_in_1_bits_dataSource,
  input  [11:0]  io_in_1_bits_dbID,
  input  [1:0]   io_in_1_bits_ccID,
  input  [1:0]   io_in_1_bits_dataID,
  input          io_in_1_bits_traceTag,
  input  [31:0]  io_in_1_bits_be,
  input  [255:0] io_in_1_bits_data,
  input  [31:0]  io_in_1_bits_dataCheck,
  input  [3:0]   io_in_1_bits_poison,
  output         io_in_2_ready,
  input          io_in_2_valid,
  input  [10:0]  io_in_2_bits_tgtID,
  input  [11:0]  io_in_2_bits_txnID,
  input  [10:0]  io_in_2_bits_homeNID,
  input  [3:0]   io_in_2_bits_opcode,
  input  [1:0]   io_in_2_bits_respErr,
  input  [2:0]   io_in_2_bits_resp,
  input  [3:0]   io_in_2_bits_dataSource,
  input  [11:0]  io_in_2_bits_dbID,
  input  [1:0]   io_in_2_bits_ccID,
  input  [1:0]   io_in_2_bits_dataID,
  input          io_in_2_bits_traceTag,
  input  [31:0]  io_in_2_bits_be,
  input  [255:0] io_in_2_bits_data,
  input  [31:0]  io_in_2_bits_dataCheck,
  input  [3:0]   io_in_2_bits_poison,
  output         io_in_3_ready,
  input          io_in_3_valid,
  input  [10:0]  io_in_3_bits_tgtID,
  input  [11:0]  io_in_3_bits_txnID,
  input  [10:0]  io_in_3_bits_homeNID,
  input  [3:0]   io_in_3_bits_opcode,
  input  [1:0]   io_in_3_bits_respErr,
  input  [2:0]   io_in_3_bits_resp,
  input  [3:0]   io_in_3_bits_dataSource,
  input  [11:0]  io_in_3_bits_dbID,
  input  [1:0]   io_in_3_bits_ccID,
  input  [1:0]   io_in_3_bits_dataID,
  input          io_in_3_bits_traceTag,
  input  [31:0]  io_in_3_bits_be,
  input  [255:0] io_in_3_bits_data,
  input  [31:0]  io_in_3_bits_dataCheck,
  input  [3:0]   io_in_3_bits_poison,
  output         io_in_4_ready,
  input          io_in_4_valid,
  input  [3:0]   io_in_4_bits_qos,
  input  [10:0]  io_in_4_bits_tgtID,
  input  [11:0]  io_in_4_bits_txnID,
  input  [10:0]  io_in_4_bits_homeNID,
  input  [3:0]   io_in_4_bits_opcode,
  input  [1:0]   io_in_4_bits_respErr,
  input  [2:0]   io_in_4_bits_resp,
  input  [3:0]   io_in_4_bits_dataSource,
  input  [2:0]   io_in_4_bits_cBusy,
  input  [11:0]  io_in_4_bits_dbID,
  input  [1:0]   io_in_4_bits_ccID,
  input  [1:0]   io_in_4_bits_dataID,
  input  [1:0]   io_in_4_bits_tagOp,
  input  [7:0]   io_in_4_bits_tag,
  input  [1:0]   io_in_4_bits_tu,
  input          io_in_4_bits_traceTag,
  input  [3:0]   io_in_4_bits_rsvdc,
  input  [31:0]  io_in_4_bits_be,
  input  [255:0] io_in_4_bits_data,
  input  [31:0]  io_in_4_bits_dataCheck,
  input  [3:0]   io_in_4_bits_poison,
  input          io_out_ready,
  output         io_out_valid,
  output [3:0]   io_out_bits_qos,
  output [10:0]  io_out_bits_tgtID,
  output [11:0]  io_out_bits_txnID,
  output [10:0]  io_out_bits_homeNID,
  output [3:0]   io_out_bits_opcode,
  output [1:0]   io_out_bits_respErr,
  output [2:0]   io_out_bits_resp,
  output [3:0]   io_out_bits_dataSource,
  output [2:0]   io_out_bits_cBusy,
  output [11:0]  io_out_bits_dbID,
  output [1:0]   io_out_bits_ccID,
  output [1:0]   io_out_bits_dataID,
  output [1:0]   io_out_bits_tagOp,
  output [7:0]   io_out_bits_tag,
  output [1:0]   io_out_bits_tu,
  output         io_out_bits_traceTag,
  output [3:0]   io_out_bits_rsvdc,
  output [31:0]  io_out_bits_be,
  output [255:0] io_out_bits_data,
  output [31:0]  io_out_bits_dataCheck,
  output [3:0]   io_out_bits_poison
);

  localparam int unsigned NUM = 5;

  // 5 路共有字段打包: tgtID(11)|txnID(12)|homeNID(11)|opcode(4)|respErr(2)|resp(3)|
  //   dataSource(4)|dbID(12)|ccID(2)|dataID(2)|traceTag(1)|be(32)|data(256)|dataCheck(32)|poison(4)
  //   = 388 位
  localparam int unsigned W = 388;
  logic [NUM-1:0] valids;
  logic [W-1:0]   pin [NUM];

  assign valids = {io_in_4_valid, io_in_3_valid, io_in_2_valid, io_in_1_valid, io_in_0_valid};
  assign pin[0] = {io_in_0_bits_tgtID, io_in_0_bits_txnID, io_in_0_bits_homeNID, io_in_0_bits_opcode,
                   io_in_0_bits_respErr, io_in_0_bits_resp, io_in_0_bits_dataSource, io_in_0_bits_dbID,
                   io_in_0_bits_ccID, io_in_0_bits_dataID, io_in_0_bits_traceTag, io_in_0_bits_be,
                   io_in_0_bits_data, io_in_0_bits_dataCheck, io_in_0_bits_poison};
  assign pin[1] = {io_in_1_bits_tgtID, io_in_1_bits_txnID, io_in_1_bits_homeNID, io_in_1_bits_opcode,
                   io_in_1_bits_respErr, io_in_1_bits_resp, io_in_1_bits_dataSource, io_in_1_bits_dbID,
                   io_in_1_bits_ccID, io_in_1_bits_dataID, io_in_1_bits_traceTag, io_in_1_bits_be,
                   io_in_1_bits_data, io_in_1_bits_dataCheck, io_in_1_bits_poison};
  assign pin[2] = {io_in_2_bits_tgtID, io_in_2_bits_txnID, io_in_2_bits_homeNID, io_in_2_bits_opcode,
                   io_in_2_bits_respErr, io_in_2_bits_resp, io_in_2_bits_dataSource, io_in_2_bits_dbID,
                   io_in_2_bits_ccID, io_in_2_bits_dataID, io_in_2_bits_traceTag, io_in_2_bits_be,
                   io_in_2_bits_data, io_in_2_bits_dataCheck, io_in_2_bits_poison};
  assign pin[3] = {io_in_3_bits_tgtID, io_in_3_bits_txnID, io_in_3_bits_homeNID, io_in_3_bits_opcode,
                   io_in_3_bits_respErr, io_in_3_bits_resp, io_in_3_bits_dataSource, io_in_3_bits_dbID,
                   io_in_3_bits_ccID, io_in_3_bits_dataID, io_in_3_bits_traceTag, io_in_3_bits_be,
                   io_in_3_bits_data, io_in_3_bits_dataCheck, io_in_3_bits_poison};
  assign pin[4] = {io_in_4_bits_tgtID, io_in_4_bits_txnID, io_in_4_bits_homeNID, io_in_4_bits_opcode,
                   io_in_4_bits_respErr, io_in_4_bits_resp, io_in_4_bits_dataSource, io_in_4_bits_dbID,
                   io_in_4_bits_ccID, io_in_4_bits_dataID, io_in_4_bits_traceTag, io_in_4_bits_be,
                   io_in_4_bits_data, io_in_4_bits_dataCheck, io_in_4_bits_poison};

  // ---- round-robin 状态 + 组合选胜 (NUM=5) ----
  reg   [NUM-1:0] pendingMask;
  reg   [NUM-1:0] rrGrantMask;
  logic [NUM-1:0] chosenOH;

  logic [NUM-1:0] cand;
  logic [NUM-1:0] rrSelOH;
  assign cand    = rrGrantMask & pendingMask;
  assign rrSelOH = cand & (~cand + {{(NUM-1){1'b0}}, 1'b1});
  logic [NUM-1:0] baseOH;
  assign baseOH   = valids & (~valids + {{(NUM-1){1'b0}}, 1'b1});
  assign chosenOH = (|(rrSelOH & valids)) ? rrSelOH : baseOH;

  logic [NUM-1:0] gtMask;
  always_comb begin
    gtMask = '0;
    for (int i = 0; i < NUM; i++)
      gtMask[i] = |(chosenOH & ((NUM'(1) << i) - NUM'(1)));
  end

  always @(posedge clock or posedge reset) begin
    if (reset) begin
      pendingMask <= '0;
      rrGrantMask <= '0;
    end else if (io_out_ready & (|valids)) begin
      pendingMask <= valids & ~chosenOH;
      rrGrantMask <= gtMask;
    end
  end

  // ---- 5 路共有字段: 胜者 payload one-hot OR 归约 ----
  logic [W-1:0] psel;
  always_comb begin
    psel = '0;
    for (int i = 0; i < NUM; i++)
      if (chosenOH[i]) psel |= pin[i];
  end

  assign io_in_0_ready = chosenOH[0] & io_out_ready;
  assign io_in_1_ready = chosenOH[1] & io_out_ready;
  assign io_in_2_ready = chosenOH[2] & io_out_ready;
  assign io_in_3_ready = chosenOH[3] & io_out_ready;
  assign io_in_4_ready = chosenOH[4] & io_out_ready;

  assign io_out_valid          = |valids;

  // 5 路共有字段 (来自 psel)
  assign io_out_bits_tgtID      = psel[387:377];
  assign io_out_bits_txnID      = psel[376:365];
  assign io_out_bits_homeNID    = psel[364:354];
  assign io_out_bits_opcode     = psel[353:350];
  assign io_out_bits_respErr    = psel[349:348];
  assign io_out_bits_resp       = psel[347:345];
  assign io_out_bits_dataSource = psel[344:341];
  assign io_out_bits_dbID       = psel[340:329];
  assign io_out_bits_ccID       = psel[328:327];
  assign io_out_bits_dataID     = psel[326:325];
  assign io_out_bits_traceTag   = psel[324];
  assign io_out_bits_be         = psel[323:292];
  assign io_out_bits_data       = psel[291:36];
  assign io_out_bits_dataCheck  = psel[35:4];
  assign io_out_bits_poison     = psel[3:0];

  // input-4 专属字段: 仅当选中第 5 路 (chosenOH[4]) 才透传, 否则 0 (忠实 golden)。
  assign io_out_bits_qos    = chosenOH[4] ? io_in_4_bits_qos    : 4'h0;
  assign io_out_bits_cBusy  = chosenOH[4] ? io_in_4_bits_cBusy  : 3'h0;
  assign io_out_bits_tagOp  = chosenOH[4] ? io_in_4_bits_tagOp  : 2'h0;
  assign io_out_bits_tag    = chosenOH[4] ? io_in_4_bits_tag    : 8'h0;
  assign io_out_bits_tu     = chosenOH[4] ? io_in_4_bits_tu     : 2'h0;
  assign io_out_bits_rsvdc  = chosenOH[4] ? io_in_4_bits_rsvdc  : 4'h0;

endmodule
