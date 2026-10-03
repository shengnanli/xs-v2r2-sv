// Sixteen-way fixed-priority TileLink D-channel arbiter.
// Pipeline/control leaf: input zero is highest priority; all ready signals are gated by output ready.
// The selected payload is combinational and remains stable whenever the sink is stalled.
module Arbiter16_TLBundleD(
  output        io_in_0_ready,
  input         io_in_0_valid,
  input  [3:0]  io_in_0_bits_opcode,
  input  [1:0]  io_in_0_bits_size,
  input  [4:0]  io_in_0_bits_source,
  input         io_in_0_bits_denied,
  input  [63:0] io_in_0_bits_data,
  input         io_in_0_bits_corrupt,
  output        io_in_1_ready,
  input         io_in_1_valid,
  input  [3:0]  io_in_1_bits_opcode,
  input  [1:0]  io_in_1_bits_size,
  input  [4:0]  io_in_1_bits_source,
  input         io_in_1_bits_denied,
  input  [63:0] io_in_1_bits_data,
  input         io_in_1_bits_corrupt,
  output        io_in_2_ready,
  input         io_in_2_valid,
  input  [3:0]  io_in_2_bits_opcode,
  input  [1:0]  io_in_2_bits_size,
  input  [4:0]  io_in_2_bits_source,
  input         io_in_2_bits_denied,
  input  [63:0] io_in_2_bits_data,
  input         io_in_2_bits_corrupt,
  output        io_in_3_ready,
  input         io_in_3_valid,
  input  [3:0]  io_in_3_bits_opcode,
  input  [1:0]  io_in_3_bits_size,
  input  [4:0]  io_in_3_bits_source,
  input         io_in_3_bits_denied,
  input  [63:0] io_in_3_bits_data,
  input         io_in_3_bits_corrupt,
  output        io_in_4_ready,
  input         io_in_4_valid,
  input  [3:0]  io_in_4_bits_opcode,
  input  [1:0]  io_in_4_bits_size,
  input  [4:0]  io_in_4_bits_source,
  input         io_in_4_bits_denied,
  input  [63:0] io_in_4_bits_data,
  input         io_in_4_bits_corrupt,
  output        io_in_5_ready,
  input         io_in_5_valid,
  input  [3:0]  io_in_5_bits_opcode,
  input  [1:0]  io_in_5_bits_size,
  input  [4:0]  io_in_5_bits_source,
  input         io_in_5_bits_denied,
  input  [63:0] io_in_5_bits_data,
  input         io_in_5_bits_corrupt,
  output        io_in_6_ready,
  input         io_in_6_valid,
  input  [3:0]  io_in_6_bits_opcode,
  input  [1:0]  io_in_6_bits_size,
  input  [4:0]  io_in_6_bits_source,
  input         io_in_6_bits_denied,
  input  [63:0] io_in_6_bits_data,
  input         io_in_6_bits_corrupt,
  output        io_in_7_ready,
  input         io_in_7_valid,
  input  [3:0]  io_in_7_bits_opcode,
  input  [1:0]  io_in_7_bits_size,
  input  [4:0]  io_in_7_bits_source,
  input         io_in_7_bits_denied,
  input  [63:0] io_in_7_bits_data,
  input         io_in_7_bits_corrupt,
  output        io_in_8_ready,
  input         io_in_8_valid,
  input  [3:0]  io_in_8_bits_opcode,
  input  [1:0]  io_in_8_bits_size,
  input  [4:0]  io_in_8_bits_source,
  input         io_in_8_bits_denied,
  input  [63:0] io_in_8_bits_data,
  input         io_in_8_bits_corrupt,
  output        io_in_9_ready,
  input         io_in_9_valid,
  input  [3:0]  io_in_9_bits_opcode,
  input  [1:0]  io_in_9_bits_size,
  input  [4:0]  io_in_9_bits_source,
  input         io_in_9_bits_denied,
  input  [63:0] io_in_9_bits_data,
  input         io_in_9_bits_corrupt,
  output        io_in_10_ready,
  input         io_in_10_valid,
  input  [3:0]  io_in_10_bits_opcode,
  input  [1:0]  io_in_10_bits_size,
  input  [4:0]  io_in_10_bits_source,
  input         io_in_10_bits_denied,
  input  [63:0] io_in_10_bits_data,
  input         io_in_10_bits_corrupt,
  output        io_in_11_ready,
  input         io_in_11_valid,
  input  [3:0]  io_in_11_bits_opcode,
  input  [1:0]  io_in_11_bits_size,
  input  [4:0]  io_in_11_bits_source,
  input         io_in_11_bits_denied,
  input  [63:0] io_in_11_bits_data,
  input         io_in_11_bits_corrupt,
  output        io_in_12_ready,
  input         io_in_12_valid,
  input  [3:0]  io_in_12_bits_opcode,
  input  [1:0]  io_in_12_bits_size,
  input  [4:0]  io_in_12_bits_source,
  input         io_in_12_bits_denied,
  input  [63:0] io_in_12_bits_data,
  input         io_in_12_bits_corrupt,
  output        io_in_13_ready,
  input         io_in_13_valid,
  input  [3:0]  io_in_13_bits_opcode,
  input  [1:0]  io_in_13_bits_size,
  input  [4:0]  io_in_13_bits_source,
  input         io_in_13_bits_denied,
  input  [63:0] io_in_13_bits_data,
  input         io_in_13_bits_corrupt,
  output        io_in_14_ready,
  input         io_in_14_valid,
  input  [3:0]  io_in_14_bits_opcode,
  input  [1:0]  io_in_14_bits_size,
  input  [4:0]  io_in_14_bits_source,
  input         io_in_14_bits_denied,
  input  [63:0] io_in_14_bits_data,
  input         io_in_14_bits_corrupt,
  output        io_in_15_ready,
  input         io_in_15_valid,
  input  [3:0]  io_in_15_bits_opcode,
  input  [1:0]  io_in_15_bits_size,
  input  [4:0]  io_in_15_bits_source,
  input         io_in_15_bits_denied,
  input  [63:0] io_in_15_bits_data,
  input         io_in_15_bits_corrupt,
  input         io_out_ready,
  output        io_out_valid,
  output [3:0]  io_out_bits_opcode,
  output [1:0]  io_out_bits_size,
  output [4:0]  io_out_bits_source,
  output        io_out_bits_denied,
  output [63:0] io_out_bits_data,
  output        io_out_bits_corrupt
);

  // Input arrays are ordered from highest (zero) to lowest (fifteen) priority.
  logic [15:0] valid_by_input;
  logic [3:0] opcode_by_input [0:15];
  logic [1:0] size_by_input [0:15];
  logic [4:0] source_by_input [0:15];
  logic denied_by_input [0:15];
  logic [63:0] data_by_input [0:15];
  logic corrupt_by_input [0:15];
  logic [15:0] ready_by_input;
  logic [3:0] winner;
  logic winner_found;
  integer input_index;

  always_comb begin
    valid_by_input = {
      io_in_15_valid, io_in_14_valid, io_in_13_valid, io_in_12_valid,
      io_in_11_valid, io_in_10_valid, io_in_9_valid, io_in_8_valid,
      io_in_7_valid, io_in_6_valid, io_in_5_valid, io_in_4_valid,
      io_in_3_valid, io_in_2_valid, io_in_1_valid, io_in_0_valid
    };
    opcode_by_input[0] = io_in_0_bits_opcode; opcode_by_input[1] = io_in_1_bits_opcode;
    opcode_by_input[2] = io_in_2_bits_opcode; opcode_by_input[3] = io_in_3_bits_opcode;
    opcode_by_input[4] = io_in_4_bits_opcode; opcode_by_input[5] = io_in_5_bits_opcode;
    opcode_by_input[6] = io_in_6_bits_opcode; opcode_by_input[7] = io_in_7_bits_opcode;
    opcode_by_input[8] = io_in_8_bits_opcode; opcode_by_input[9] = io_in_9_bits_opcode;
    opcode_by_input[10] = io_in_10_bits_opcode; opcode_by_input[11] = io_in_11_bits_opcode;
    opcode_by_input[12] = io_in_12_bits_opcode; opcode_by_input[13] = io_in_13_bits_opcode;
    opcode_by_input[14] = io_in_14_bits_opcode; opcode_by_input[15] = io_in_15_bits_opcode;
    size_by_input[0] = io_in_0_bits_size; size_by_input[1] = io_in_1_bits_size;
    size_by_input[2] = io_in_2_bits_size; size_by_input[3] = io_in_3_bits_size;
    size_by_input[4] = io_in_4_bits_size; size_by_input[5] = io_in_5_bits_size;
    size_by_input[6] = io_in_6_bits_size; size_by_input[7] = io_in_7_bits_size;
    size_by_input[8] = io_in_8_bits_size; size_by_input[9] = io_in_9_bits_size;
    size_by_input[10] = io_in_10_bits_size; size_by_input[11] = io_in_11_bits_size;
    size_by_input[12] = io_in_12_bits_size; size_by_input[13] = io_in_13_bits_size;
    size_by_input[14] = io_in_14_bits_size; size_by_input[15] = io_in_15_bits_size;
    source_by_input[0] = io_in_0_bits_source; source_by_input[1] = io_in_1_bits_source;
    source_by_input[2] = io_in_2_bits_source; source_by_input[3] = io_in_3_bits_source;
    source_by_input[4] = io_in_4_bits_source; source_by_input[5] = io_in_5_bits_source;
    source_by_input[6] = io_in_6_bits_source; source_by_input[7] = io_in_7_bits_source;
    source_by_input[8] = io_in_8_bits_source; source_by_input[9] = io_in_9_bits_source;
    source_by_input[10] = io_in_10_bits_source; source_by_input[11] = io_in_11_bits_source;
    source_by_input[12] = io_in_12_bits_source; source_by_input[13] = io_in_13_bits_source;
    source_by_input[14] = io_in_14_bits_source; source_by_input[15] = io_in_15_bits_source;
    denied_by_input[0] = io_in_0_bits_denied; denied_by_input[1] = io_in_1_bits_denied;
    denied_by_input[2] = io_in_2_bits_denied; denied_by_input[3] = io_in_3_bits_denied;
    denied_by_input[4] = io_in_4_bits_denied; denied_by_input[5] = io_in_5_bits_denied;
    denied_by_input[6] = io_in_6_bits_denied; denied_by_input[7] = io_in_7_bits_denied;
    denied_by_input[8] = io_in_8_bits_denied; denied_by_input[9] = io_in_9_bits_denied;
    denied_by_input[10] = io_in_10_bits_denied; denied_by_input[11] = io_in_11_bits_denied;
    denied_by_input[12] = io_in_12_bits_denied; denied_by_input[13] = io_in_13_bits_denied;
    denied_by_input[14] = io_in_14_bits_denied; denied_by_input[15] = io_in_15_bits_denied;
    data_by_input[0] = io_in_0_bits_data; data_by_input[1] = io_in_1_bits_data;
    data_by_input[2] = io_in_2_bits_data; data_by_input[3] = io_in_3_bits_data;
    data_by_input[4] = io_in_4_bits_data; data_by_input[5] = io_in_5_bits_data;
    data_by_input[6] = io_in_6_bits_data; data_by_input[7] = io_in_7_bits_data;
    data_by_input[8] = io_in_8_bits_data; data_by_input[9] = io_in_9_bits_data;
    data_by_input[10] = io_in_10_bits_data; data_by_input[11] = io_in_11_bits_data;
    data_by_input[12] = io_in_12_bits_data; data_by_input[13] = io_in_13_bits_data;
    data_by_input[14] = io_in_14_bits_data; data_by_input[15] = io_in_15_bits_data;
    corrupt_by_input[0] = io_in_0_bits_corrupt; corrupt_by_input[1] = io_in_1_bits_corrupt;
    corrupt_by_input[2] = io_in_2_bits_corrupt; corrupt_by_input[3] = io_in_3_bits_corrupt;
    corrupt_by_input[4] = io_in_4_bits_corrupt; corrupt_by_input[5] = io_in_5_bits_corrupt;
    corrupt_by_input[6] = io_in_6_bits_corrupt; corrupt_by_input[7] = io_in_7_bits_corrupt;
    corrupt_by_input[8] = io_in_8_bits_corrupt; corrupt_by_input[9] = io_in_9_bits_corrupt;
    corrupt_by_input[10] = io_in_10_bits_corrupt; corrupt_by_input[11] = io_in_11_bits_corrupt;
    corrupt_by_input[12] = io_in_12_bits_corrupt; corrupt_by_input[13] = io_in_13_bits_corrupt;
    corrupt_by_input[14] = io_in_14_bits_corrupt; corrupt_by_input[15] = io_in_15_bits_corrupt;

    ready_by_input = '0;
    // G1 falls through to input 15 when no request is valid.
    winner = 4'd15;
    winner_found = 1'b0;
    for (input_index = 0; input_index < 16; input_index = input_index + 1) begin
      ready_by_input[input_index] = io_out_ready & ~winner_found;
      if (valid_by_input[input_index] && !winner_found) begin
        winner = input_index[3:0];
        winner_found = 1'b1;
      end
    end
  end

  assign io_in_0_ready = ready_by_input[0]; assign io_in_1_ready = ready_by_input[1];
  assign io_in_2_ready = ready_by_input[2]; assign io_in_3_ready = ready_by_input[3];
  assign io_in_4_ready = ready_by_input[4]; assign io_in_5_ready = ready_by_input[5];
  assign io_in_6_ready = ready_by_input[6]; assign io_in_7_ready = ready_by_input[7];
  assign io_in_8_ready = ready_by_input[8]; assign io_in_9_ready = ready_by_input[9];
  assign io_in_10_ready = ready_by_input[10]; assign io_in_11_ready = ready_by_input[11];
  assign io_in_12_ready = ready_by_input[12]; assign io_in_13_ready = ready_by_input[13];
  assign io_in_14_ready = ready_by_input[14]; assign io_in_15_ready = ready_by_input[15];
  assign io_out_valid = |valid_by_input;
  assign io_out_bits_opcode = opcode_by_input[winner];
  assign io_out_bits_size = size_by_input[winner];
  assign io_out_bits_source = source_by_input[winner];
  assign io_out_bits_denied = denied_by_input[winner];
  assign io_out_bits_data = data_by_input[winner];
  assign io_out_bits_corrupt = corrupt_by_input[winner];
endmodule
