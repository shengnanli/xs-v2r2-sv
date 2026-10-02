// Combine four L2 cache error-reporting lanes into one report.
// Lower input number has fixed priority, with payload selected from the winning lane.
// This observation path has no ready signal, so selection depends only on valid.
module Arbiter4_L2CacheErrorInfo (
  input  logic        io_in_0_valid,
  input  logic        io_in_0_bits_valid,
  input  logic [45:0] io_in_0_bits_address,
  input  logic        io_in_1_valid,
  input  logic        io_in_1_bits_valid,
  input  logic [45:0] io_in_1_bits_address,
  input  logic        io_in_2_valid,
  input  logic        io_in_2_bits_valid,
  input  logic [45:0] io_in_2_bits_address,
  input  logic        io_in_3_valid,
  input  logic        io_in_3_bits_valid,
  input  logic [45:0] io_in_3_bits_address,
  output logic        io_out_valid,
  output logic        io_out_bits_valid,
  output logic [45:0] io_out_bits_address
);
  always_comb begin
    io_out_valid = io_in_0_valid || io_in_1_valid ||
                   io_in_2_valid || io_in_3_valid;

    if (io_in_0_valid) begin
      io_out_bits_valid = io_in_0_bits_valid;
      io_out_bits_address = io_in_0_bits_address;
    end else if (io_in_1_valid) begin
      io_out_bits_valid = io_in_1_bits_valid;
      io_out_bits_address = io_in_1_bits_address;
    end else if (io_in_2_valid) begin
      io_out_bits_valid = io_in_2_bits_valid;
      io_out_bits_address = io_in_2_bits_address;
    end else begin
      io_out_bits_valid = io_in_3_bits_valid;
      io_out_bits_address = io_in_3_bits_address;
    end
  end
endmodule
