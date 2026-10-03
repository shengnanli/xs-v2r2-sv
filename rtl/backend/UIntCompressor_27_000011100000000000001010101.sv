// Sparse 27-bit field compressor for mask 000011100000000000001010101.
// Selected source bits are packed from highest listed position to output MSB.
// Unselected bits are deliberately discarded; no arithmetic is performed.
module UIntCompressor_27_000011100000000000001010101(input logic [26:0] io_in, output logic [6:0] io_out);
  assign io_out = {io_in[22], io_in[21], io_in[20], io_in[6], io_in[4], io_in[2], io_in[0]};
endmodule
