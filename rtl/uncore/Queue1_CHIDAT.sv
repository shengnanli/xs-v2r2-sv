// Queue1_CHIDAT.sv — one-entry CHI DAT queue with ready/valid flow-through.
// The payload order and widths are derived from the read-only G1 golden.
// Queue state is shared with xs_ChiselQueue1_core; payload remains unreset.

module xs_Queue1_CHIDAT_core #(
  parameter int unsigned W = 422
)(
  input  logic clock,
  input  logic reset,
  input  logic enq_valid,
  output logic enq_ready,
  input  logic [W-1:0] enq_word,
  input  logic deq_ready,
  output logic deq_valid,
  output logic [W-1:0] deq_word
);
  xs_ChiselQueue1_core #(.W(W), .PIPE(1'b1)) queue (
    .clock(clock), .reset(reset),
    .enq_valid(enq_valid), .enq_ready(enq_ready), .enq_word(enq_word),
    .deq_valid(deq_valid), .deq_ready(deq_ready), .deq_word(deq_word) );
endmodule

module Queue1_CHIDAT (
  input  logic clock,
  input  logic reset,
  output logic io_enq_ready,
  input  logic io_enq_valid,
  input  logic [3:0] io_enq_bits_qos,
  input  logic [10:0] io_enq_bits_tgtID,
  input  logic [10:0] io_enq_bits_srcID,
  input  logic [11:0] io_enq_bits_txnID,
  input  logic [10:0] io_enq_bits_homeNID,
  input  logic [3:0] io_enq_bits_opcode,
  input  logic [1:0] io_enq_bits_respErr,
  input  logic [2:0] io_enq_bits_resp,
  input  logic [3:0] io_enq_bits_dataSource,
  input  logic [2:0] io_enq_bits_cBusy,
  input  logic [11:0] io_enq_bits_dbID,
  input  logic [1:0] io_enq_bits_ccID,
  input  logic [1:0] io_enq_bits_dataID,
  input  logic [1:0] io_enq_bits_tagOp,
  input  logic [7:0] io_enq_bits_tag,
  input  logic [1:0] io_enq_bits_tu,
  input  logic io_enq_bits_traceTag,
  input  logic [3:0] io_enq_bits_rsvdc,
  input  logic [31:0] io_enq_bits_be,
  input  logic [255:0] io_enq_bits_data,
  input  logic [31:0] io_enq_bits_dataCheck,
  input  logic [3:0] io_enq_bits_poison,
  input  logic io_deq_ready,
  output logic io_deq_valid,
  output logic [3:0] io_deq_bits_qos,
  output logic [10:0] io_deq_bits_tgtID,
  output logic [10:0] io_deq_bits_srcID,
  output logic [11:0] io_deq_bits_txnID,
  output logic [10:0] io_deq_bits_homeNID,
  output logic [3:0] io_deq_bits_opcode,
  output logic [1:0] io_deq_bits_respErr,
  output logic [2:0] io_deq_bits_resp,
  output logic [3:0] io_deq_bits_dataSource,
  output logic [2:0] io_deq_bits_cBusy,
  output logic [11:0] io_deq_bits_dbID,
  output logic [1:0] io_deq_bits_ccID,
  output logic [1:0] io_deq_bits_dataID,
  output logic [1:0] io_deq_bits_tagOp,
  output logic [7:0] io_deq_bits_tag,
  output logic [1:0] io_deq_bits_tu,
  output logic io_deq_bits_traceTag,
  output logic [3:0] io_deq_bits_rsvdc,
  output logic [31:0] io_deq_bits_be,
  output logic [255:0] io_deq_bits_data,
  output logic [31:0] io_deq_bits_dataCheck,
  output logic [3:0] io_deq_bits_poison
);
  logic [421:0] enq_word, deq_word;
  assign enq_word = {
    io_enq_bits_poison,
    io_enq_bits_dataCheck,
    io_enq_bits_data,
    io_enq_bits_be,
    io_enq_bits_rsvdc,
    io_enq_bits_traceTag,
    io_enq_bits_tu,
    io_enq_bits_tag,
    io_enq_bits_tagOp,
    io_enq_bits_dataID,
    io_enq_bits_ccID,
    io_enq_bits_dbID,
    io_enq_bits_cBusy,
    io_enq_bits_dataSource,
    io_enq_bits_resp,
    io_enq_bits_respErr,
    io_enq_bits_opcode,
    io_enq_bits_homeNID,
    io_enq_bits_txnID,
    io_enq_bits_srcID,
    io_enq_bits_tgtID,
    io_enq_bits_qos
  };
  xs_Queue1_CHIDAT_core #(.W(422)) u_core (
    .clock(clock), .reset(reset),
    .enq_valid(io_enq_valid), .enq_ready(io_enq_ready),
    .enq_word(enq_word), .deq_ready(io_deq_ready),
    .deq_valid(io_deq_valid), .deq_word(deq_word) );
  assign io_deq_bits_qos = deq_word[3:0];
  assign io_deq_bits_tgtID = deq_word[14:4];
  assign io_deq_bits_srcID = deq_word[25:15];
  assign io_deq_bits_txnID = deq_word[37:26];
  assign io_deq_bits_homeNID = deq_word[48:38];
  assign io_deq_bits_opcode = deq_word[52:49];
  assign io_deq_bits_respErr = deq_word[54:53];
  assign io_deq_bits_resp = deq_word[57:55];
  assign io_deq_bits_dataSource = deq_word[61:58];
  assign io_deq_bits_cBusy = deq_word[64:62];
  assign io_deq_bits_dbID = deq_word[76:65];
  assign io_deq_bits_ccID = deq_word[78:77];
  assign io_deq_bits_dataID = deq_word[80:79];
  assign io_deq_bits_tagOp = deq_word[82:81];
  assign io_deq_bits_tag = deq_word[90:83];
  assign io_deq_bits_tu = deq_word[92:91];
  assign io_deq_bits_traceTag = deq_word[93];
  assign io_deq_bits_rsvdc = deq_word[97:94];
  assign io_deq_bits_be = deq_word[129:98];
  assign io_deq_bits_data = deq_word[385:130];
  assign io_deq_bits_dataCheck = deq_word[417:386];
  assign io_deq_bits_poison = deq_word[421:418];
endmodule
