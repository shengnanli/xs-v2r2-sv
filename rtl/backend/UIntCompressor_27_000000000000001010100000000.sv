// Sparse 27-bit field compressor for mask 000000000000001010100000000.
// Selected source bits are packed from highest listed position to output MSB.
// Unselected bits are deliberately discarded; no arithmetic is performed.
module UIntCompressor_27_000000000000001010100000000(input logic [26:0] io_in, output logic [2:0] io_out);
  assign io_out = {io_in[12], io_in[10], io_in[8]};
endmodule
