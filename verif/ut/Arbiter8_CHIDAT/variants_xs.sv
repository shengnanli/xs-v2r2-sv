// 自动生成: scripts/gen_arbiter8.py —— 勿手改
module Arbiter8_CHIDAT_xs(
  output io_in_0_ready,
  input io_in_0_valid,
  input [10:0] io_in_0_bits_tgtID,
  input [11:0] io_in_0_bits_txnID,
  input [1:0] io_in_0_bits_respErr,
  input [1:0] io_in_0_bits_ccID,
  input [1:0] io_in_0_bits_dataID,
  input io_in_0_bits_traceTag,
  input [31:0] io_in_0_bits_be,
  input [255:0] io_in_0_bits_data,
  input [31:0] io_in_0_bits_dataCheck,
  input [3:0] io_in_0_bits_poison,
  output io_in_1_ready,
  input io_in_1_valid,
  input [10:0] io_in_1_bits_tgtID,
  input [11:0] io_in_1_bits_txnID,
  input [1:0] io_in_1_bits_respErr,
  input [1:0] io_in_1_bits_ccID,
  input [1:0] io_in_1_bits_dataID,
  input io_in_1_bits_traceTag,
  input [31:0] io_in_1_bits_be,
  input [255:0] io_in_1_bits_data,
  input [31:0] io_in_1_bits_dataCheck,
  input [3:0] io_in_1_bits_poison,
  output io_in_2_ready,
  input io_in_2_valid,
  input [10:0] io_in_2_bits_tgtID,
  input [11:0] io_in_2_bits_txnID,
  input [1:0] io_in_2_bits_respErr,
  input [1:0] io_in_2_bits_ccID,
  input [1:0] io_in_2_bits_dataID,
  input io_in_2_bits_traceTag,
  input [31:0] io_in_2_bits_be,
  input [255:0] io_in_2_bits_data,
  input [31:0] io_in_2_bits_dataCheck,
  input [3:0] io_in_2_bits_poison,
  output io_in_3_ready,
  input io_in_3_valid,
  input [10:0] io_in_3_bits_tgtID,
  input [11:0] io_in_3_bits_txnID,
  input [1:0] io_in_3_bits_respErr,
  input [1:0] io_in_3_bits_ccID,
  input [1:0] io_in_3_bits_dataID,
  input io_in_3_bits_traceTag,
  input [31:0] io_in_3_bits_be,
  input [255:0] io_in_3_bits_data,
  input [31:0] io_in_3_bits_dataCheck,
  input [3:0] io_in_3_bits_poison,
  output io_in_4_ready,
  input io_in_4_valid,
  input [10:0] io_in_4_bits_tgtID,
  input [11:0] io_in_4_bits_txnID,
  input [1:0] io_in_4_bits_respErr,
  input [1:0] io_in_4_bits_ccID,
  input [1:0] io_in_4_bits_dataID,
  input io_in_4_bits_traceTag,
  input [31:0] io_in_4_bits_be,
  input [255:0] io_in_4_bits_data,
  input [31:0] io_in_4_bits_dataCheck,
  input [3:0] io_in_4_bits_poison,
  output io_in_5_ready,
  input io_in_5_valid,
  input [10:0] io_in_5_bits_tgtID,
  input [11:0] io_in_5_bits_txnID,
  input [1:0] io_in_5_bits_respErr,
  input [1:0] io_in_5_bits_ccID,
  input [1:0] io_in_5_bits_dataID,
  input io_in_5_bits_traceTag,
  input [31:0] io_in_5_bits_be,
  input [255:0] io_in_5_bits_data,
  input [31:0] io_in_5_bits_dataCheck,
  input [3:0] io_in_5_bits_poison,
  output io_in_6_ready,
  input io_in_6_valid,
  input [10:0] io_in_6_bits_tgtID,
  input [11:0] io_in_6_bits_txnID,
  input [1:0] io_in_6_bits_respErr,
  input [1:0] io_in_6_bits_ccID,
  input [1:0] io_in_6_bits_dataID,
  input io_in_6_bits_traceTag,
  input [31:0] io_in_6_bits_be,
  input [255:0] io_in_6_bits_data,
  input [31:0] io_in_6_bits_dataCheck,
  input [3:0] io_in_6_bits_poison,
  output io_in_7_ready,
  input io_in_7_valid,
  input [10:0] io_in_7_bits_tgtID,
  input [11:0] io_in_7_bits_txnID,
  input [1:0] io_in_7_bits_respErr,
  input [1:0] io_in_7_bits_ccID,
  input [1:0] io_in_7_bits_dataID,
  input io_in_7_bits_traceTag,
  input [31:0] io_in_7_bits_be,
  input [255:0] io_in_7_bits_data,
  input [31:0] io_in_7_bits_dataCheck,
  input [3:0] io_in_7_bits_poison,
  input io_out_ready,
  output io_out_valid,
  output [10:0] io_out_bits_tgtID,
  output [11:0] io_out_bits_txnID,
  output [1:0] io_out_bits_respErr,
  output [1:0] io_out_bits_ccID,
  output [1:0] io_out_bits_dataID,
  output io_out_bits_traceTag,
  output [31:0] io_out_bits_be,
  output [255:0] io_out_bits_data,
  output [31:0] io_out_bits_dataCheck,
  output [3:0] io_out_bits_poison
);
  // ---- 8 输入固定优先级仲裁器: xs_arbiter8_core (WIDTH=354) ----
  localparam int unsigned W = 354;
  logic [7:0] c_valids;
  logic [7:0] c_readies;
  logic [W-1:0] c_pin [8];
  logic [W-1:0] c_pout;
  wire c_out_valid;
  assign c_valids = {io_in_7_valid, io_in_6_valid, io_in_5_valid, io_in_4_valid, io_in_3_valid, io_in_2_valid, io_in_1_valid, io_in_0_valid};
  assign c_pin[0] = {io_in_0_bits_tgtID, io_in_0_bits_txnID, io_in_0_bits_respErr, io_in_0_bits_ccID, io_in_0_bits_dataID, io_in_0_bits_traceTag, io_in_0_bits_be, io_in_0_bits_data, io_in_0_bits_dataCheck, io_in_0_bits_poison};
  assign c_pin[1] = {io_in_1_bits_tgtID, io_in_1_bits_txnID, io_in_1_bits_respErr, io_in_1_bits_ccID, io_in_1_bits_dataID, io_in_1_bits_traceTag, io_in_1_bits_be, io_in_1_bits_data, io_in_1_bits_dataCheck, io_in_1_bits_poison};
  assign c_pin[2] = {io_in_2_bits_tgtID, io_in_2_bits_txnID, io_in_2_bits_respErr, io_in_2_bits_ccID, io_in_2_bits_dataID, io_in_2_bits_traceTag, io_in_2_bits_be, io_in_2_bits_data, io_in_2_bits_dataCheck, io_in_2_bits_poison};
  assign c_pin[3] = {io_in_3_bits_tgtID, io_in_3_bits_txnID, io_in_3_bits_respErr, io_in_3_bits_ccID, io_in_3_bits_dataID, io_in_3_bits_traceTag, io_in_3_bits_be, io_in_3_bits_data, io_in_3_bits_dataCheck, io_in_3_bits_poison};
  assign c_pin[4] = {io_in_4_bits_tgtID, io_in_4_bits_txnID, io_in_4_bits_respErr, io_in_4_bits_ccID, io_in_4_bits_dataID, io_in_4_bits_traceTag, io_in_4_bits_be, io_in_4_bits_data, io_in_4_bits_dataCheck, io_in_4_bits_poison};
  assign c_pin[5] = {io_in_5_bits_tgtID, io_in_5_bits_txnID, io_in_5_bits_respErr, io_in_5_bits_ccID, io_in_5_bits_dataID, io_in_5_bits_traceTag, io_in_5_bits_be, io_in_5_bits_data, io_in_5_bits_dataCheck, io_in_5_bits_poison};
  assign c_pin[6] = {io_in_6_bits_tgtID, io_in_6_bits_txnID, io_in_6_bits_respErr, io_in_6_bits_ccID, io_in_6_bits_dataID, io_in_6_bits_traceTag, io_in_6_bits_be, io_in_6_bits_data, io_in_6_bits_dataCheck, io_in_6_bits_poison};
  assign c_pin[7] = {io_in_7_bits_tgtID, io_in_7_bits_txnID, io_in_7_bits_respErr, io_in_7_bits_ccID, io_in_7_bits_dataID, io_in_7_bits_traceTag, io_in_7_bits_be, io_in_7_bits_data, io_in_7_bits_dataCheck, io_in_7_bits_poison};
  xs_arbiter8_core #(.WIDTH(W)) u_core (
    .valids(c_valids), .out_ready(io_out_ready), .pin(c_pin),
    .readies(c_readies), .out_valid(c_out_valid), .pout(c_pout)
  );
  assign io_in_0_ready = c_readies[0];
  assign io_in_1_ready = c_readies[1];
  assign io_in_2_ready = c_readies[2];
  assign io_in_3_ready = c_readies[3];
  assign io_in_4_ready = c_readies[4];
  assign io_in_5_ready = c_readies[5];
  assign io_in_6_ready = c_readies[6];
  assign io_in_7_ready = c_readies[7];
  assign io_out_valid = c_out_valid;
  assign io_out_bits_tgtID = c_pout[353:343];
  assign io_out_bits_txnID = c_pout[342:331];
  assign io_out_bits_respErr = c_pout[330:329];
  assign io_out_bits_ccID = c_pout[328:327];
  assign io_out_bits_dataID = c_pout[326:325];
  assign io_out_bits_traceTag = c_pout[324];
  assign io_out_bits_be = c_pout[323:292];
  assign io_out_bits_data = c_pout[291:36];
  assign io_out_bits_dataCheck = c_pout[35:4];
  assign io_out_bits_poison = c_pout[3:0];
endmodule
