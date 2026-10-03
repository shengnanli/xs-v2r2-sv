// Sparse 27-bit field extractor for mask 000011100000000000001010101.
// Packed input bits return to their architectural positions; all others are zero.
// Explicit per-position assignments make the inverse mapping directly auditable.
module UIntExtractor_27_000011100000000000001010101(input logic [6:0] io_in, output logic [26:0] io_out);
  always_comb begin
    io_out = 27'b0;
    io_out[22] = io_in[6];
    io_out[21] = io_in[5];
    io_out[20] = io_in[4];
    io_out[6] = io_in[3];
    io_out[4] = io_in[2];
    io_out[2] = io_in[1];
    io_out[0] = io_in[0];
  end
endmodule
