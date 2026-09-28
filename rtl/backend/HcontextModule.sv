// Read hcontext and forward a masked write to the shared mcontext storage.
// The small semantic core makes the architectural transform explicit;
// the outer module preserves the generated RTL interface exactly.
module HcontextModule (
  input  logic        w_wen,
  input  logic [63:0] w_wdata,
  output logic [13:0] rdata,
  output logic [13:0] regOut_HCONTEXT,
  input  logic [13:0] fromMcontext_HCONTEXT,
  output logic        toMcontext_valid,
  output logic [13:0] toMcontext_bits_HCONTEXT
);
  assign rdata = fromMcontext_HCONTEXT;
  assign regOut_HCONTEXT = fromMcontext_HCONTEXT;
  assign toMcontext_valid = w_wen;
  assign toMcontext_bits_HCONTEXT = w_wdata[13:0];
endmodule
