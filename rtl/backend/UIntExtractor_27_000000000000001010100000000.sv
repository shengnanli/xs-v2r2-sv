// Sparse 27-bit field extractor for mask 000000000000001010100000000.
// Packed input bits return to their architectural positions; all others are zero.
// Explicit per-position assignments make the inverse mapping directly auditable.
module UIntExtractor_27_000000000000001010100000000(input logic [2:0] io_in, output logic [26:0] io_out);
  always_comb begin
    io_out = 27'b0;
    io_out[12] = io_in[2];
    io_out[10] = io_in[1];
    io_out[8] = io_in[0];
  end
endmodule
