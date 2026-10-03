// SpillRegister_7.sv — two-stage spill buffer for a 32-bit scalar bus.
// The shared core preserves ordering under backpressure: the older item
// moves to the spill stage before a newer item enters the first stage.
// Valid bits reset asynchronously; payload bits intentionally do not reset.

module SpillRegister_7 (
  input  logic clock,
  input  logic reset,
  input  logic io_in_valid,
  input  logic io_in_bits_0,
  input  logic io_in_bits_1,
  input  logic io_in_bits_2,
  input  logic io_in_bits_3,
  input  logic io_in_bits_4,
  input  logic io_in_bits_5,
  input  logic io_in_bits_6,
  input  logic io_in_bits_7,
  input  logic io_in_bits_8,
  input  logic io_in_bits_9,
  input  logic io_in_bits_10,
  input  logic io_in_bits_11,
  input  logic io_in_bits_12,
  input  logic io_in_bits_13,
  input  logic io_in_bits_14,
  input  logic io_in_bits_15,
  input  logic io_in_bits_16,
  input  logic io_in_bits_17,
  input  logic io_in_bits_18,
  input  logic io_in_bits_19,
  input  logic io_in_bits_20,
  input  logic io_in_bits_21,
  input  logic io_in_bits_22,
  input  logic io_in_bits_23,
  input  logic io_in_bits_24,
  input  logic io_in_bits_25,
  input  logic io_in_bits_26,
  input  logic io_in_bits_27,
  input  logic io_in_bits_28,
  input  logic io_in_bits_29,
  input  logic io_in_bits_30,
  input  logic io_in_bits_31,
  input  logic io_out_ready,
  output logic io_out_valid,
  output logic io_out_bits_0,
  output logic io_out_bits_1,
  output logic io_out_bits_2,
  output logic io_out_bits_3,
  output logic io_out_bits_4,
  output logic io_out_bits_5,
  output logic io_out_bits_6,
  output logic io_out_bits_7,
  output logic io_out_bits_8,
  output logic io_out_bits_9,
  output logic io_out_bits_10,
  output logic io_out_bits_11,
  output logic io_out_bits_12,
  output logic io_out_bits_13,
  output logic io_out_bits_14,
  output logic io_out_bits_15,
  output logic io_out_bits_16,
  output logic io_out_bits_17,
  output logic io_out_bits_18,
  output logic io_out_bits_19,
  output logic io_out_bits_20,
  output logic io_out_bits_21,
  output logic io_out_bits_22,
  output logic io_out_bits_23,
  output logic io_out_bits_24,
  output logic io_out_bits_25,
  output logic io_out_bits_26,
  output logic io_out_bits_27,
  output logic io_out_bits_28,
  output logic io_out_bits_29,
  output logic io_out_bits_30,
  output logic io_out_bits_31
);
  logic [31:0] in_payload, out_payload;
  assign in_payload = {
    io_in_bits_0,
    io_in_bits_1,
    io_in_bits_2,
    io_in_bits_3,
    io_in_bits_4,
    io_in_bits_5,
    io_in_bits_6,
    io_in_bits_7,
    io_in_bits_8,
    io_in_bits_9,
    io_in_bits_10,
    io_in_bits_11,
    io_in_bits_12,
    io_in_bits_13,
    io_in_bits_14,
    io_in_bits_15,
    io_in_bits_16,
    io_in_bits_17,
    io_in_bits_18,
    io_in_bits_19,
    io_in_bits_20,
    io_in_bits_21,
    io_in_bits_22,
    io_in_bits_23,
    io_in_bits_24,
    io_in_bits_25,
    io_in_bits_26,
    io_in_bits_27,
    io_in_bits_28,
    io_in_bits_29,
    io_in_bits_30,
    io_in_bits_31
  };
  xs_SpillRegister_core #(.W(32)) u_core (
    .clock(clock), .reset(reset),
    .in_ready(), .in_valid(io_in_valid), .in_payload(in_payload),
    .out_ready(io_out_ready), .out_valid(io_out_valid),
    .out_payload(out_payload) );
  assign io_out_bits_0 = out_payload[31];
  assign io_out_bits_1 = out_payload[30];
  assign io_out_bits_2 = out_payload[29];
  assign io_out_bits_3 = out_payload[28];
  assign io_out_bits_4 = out_payload[27];
  assign io_out_bits_5 = out_payload[26];
  assign io_out_bits_6 = out_payload[25];
  assign io_out_bits_7 = out_payload[24];
  assign io_out_bits_8 = out_payload[23];
  assign io_out_bits_9 = out_payload[22];
  assign io_out_bits_10 = out_payload[21];
  assign io_out_bits_11 = out_payload[20];
  assign io_out_bits_12 = out_payload[19];
  assign io_out_bits_13 = out_payload[18];
  assign io_out_bits_14 = out_payload[17];
  assign io_out_bits_15 = out_payload[16];
  assign io_out_bits_16 = out_payload[15];
  assign io_out_bits_17 = out_payload[14];
  assign io_out_bits_18 = out_payload[13];
  assign io_out_bits_19 = out_payload[12];
  assign io_out_bits_20 = out_payload[11];
  assign io_out_bits_21 = out_payload[10];
  assign io_out_bits_22 = out_payload[9];
  assign io_out_bits_23 = out_payload[8];
  assign io_out_bits_24 = out_payload[7];
  assign io_out_bits_25 = out_payload[6];
  assign io_out_bits_26 = out_payload[5];
  assign io_out_bits_27 = out_payload[4];
  assign io_out_bits_28 = out_payload[3];
  assign io_out_bits_29 = out_payload[2];
  assign io_out_bits_30 = out_payload[1];
  assign io_out_bits_31 = out_payload[0];
endmodule
