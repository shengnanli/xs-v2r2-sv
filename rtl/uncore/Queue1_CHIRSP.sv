// Queue1_CHIRSP.sv — one-entry CHI response queue with ready/valid flow-through.
// The payload order and widths are derived from the read-only G1 golden.
// Queue state is shared with xs_ChiselQueue1_core; payload remains unreset.

module xs_Queue1_CHIRSP_core #(
  parameter int unsigned W = 73
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

module Queue1_CHIRSP (
  input  logic clock,
  input  logic reset,
  output logic io_enq_ready,
  input  logic io_enq_valid,
  input  logic [3:0] io_enq_bits_qos,
  input  logic [10:0] io_enq_bits_tgtID,
  input  logic [10:0] io_enq_bits_srcID,
  input  logic [11:0] io_enq_bits_txnID,
  input  logic [4:0] io_enq_bits_opcode,
  input  logic [1:0] io_enq_bits_respErr,
  input  logic [2:0] io_enq_bits_resp,
  input  logic [2:0] io_enq_bits_fwdState,
  input  logic [2:0] io_enq_bits_cBusy,
  input  logic [11:0] io_enq_bits_dbID,
  input  logic [3:0] io_enq_bits_pCrdType,
  input  logic [1:0] io_enq_bits_tagOp,
  input  logic io_enq_bits_traceTag,
  input  logic io_deq_ready,
  output logic io_deq_valid,
  output logic [3:0] io_deq_bits_qos,
  output logic [10:0] io_deq_bits_tgtID,
  output logic [10:0] io_deq_bits_srcID,
  output logic [11:0] io_deq_bits_txnID,
  output logic [4:0] io_deq_bits_opcode,
  output logic [1:0] io_deq_bits_respErr,
  output logic [2:0] io_deq_bits_resp,
  output logic [2:0] io_deq_bits_fwdState,
  output logic [2:0] io_deq_bits_cBusy,
  output logic [11:0] io_deq_bits_dbID,
  output logic [3:0] io_deq_bits_pCrdType,
  output logic [1:0] io_deq_bits_tagOp,
  output logic io_deq_bits_traceTag
);
  logic [72:0] enq_word, deq_word;
  assign enq_word = {
    io_enq_bits_traceTag,
    io_enq_bits_tagOp,
    io_enq_bits_pCrdType,
    io_enq_bits_dbID,
    io_enq_bits_cBusy,
    io_enq_bits_fwdState,
    io_enq_bits_resp,
    io_enq_bits_respErr,
    io_enq_bits_opcode,
    io_enq_bits_txnID,
    io_enq_bits_srcID,
    io_enq_bits_tgtID,
    io_enq_bits_qos
  };
  xs_Queue1_CHIRSP_core #(.W(73)) u_core (
    .clock(clock), .reset(reset),
    .enq_valid(io_enq_valid), .enq_ready(io_enq_ready),
    .enq_word(enq_word), .deq_ready(io_deq_ready),
    .deq_valid(io_deq_valid), .deq_word(deq_word) );
  assign io_deq_bits_qos = deq_word[3:0];
  assign io_deq_bits_tgtID = deq_word[14:4];
  assign io_deq_bits_srcID = deq_word[25:15];
  assign io_deq_bits_txnID = deq_word[37:26];
  assign io_deq_bits_opcode = deq_word[42:38];
  assign io_deq_bits_respErr = deq_word[44:43];
  assign io_deq_bits_resp = deq_word[47:45];
  assign io_deq_bits_fwdState = deq_word[50:48];
  assign io_deq_bits_cBusy = deq_word[53:51];
  assign io_deq_bits_dbID = deq_word[65:54];
  assign io_deq_bits_pCrdType = deq_word[69:66];
  assign io_deq_bits_tagOp = deq_word[71:70];
  assign io_deq_bits_traceTag = deq_word[72];
endmodule
