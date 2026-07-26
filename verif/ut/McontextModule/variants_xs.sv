// mcontext UT variant (_xs): a name-distinct copy of the impl body so the tb can
// double-instantiate golden McontextModule vs the readable impl. This mirrors
// rtl/backend/newcsr_context_wrappers.sv:McontextModule exactly (the authoritative
// impl is FM-verified against golden; this copy is only for the UT smoke test).
module McontextModule_xs(
  input         clock,
  input         w_wen,
  input  [63:0] w_wdata,
  output [13:0] rdata,
  output [13:0] regOut_HCONTEXT,
  input         fromHcontext_valid,
  input  [13:0] fromHcontext_bits_HCONTEXT,
  output [13:0] toHcontext_HCONTEXT
);
  reg [13:0] reg_HCONTEXT;
  always @(posedge clock) begin
    if (w_wen)
      reg_HCONTEXT <= w_wdata[13:0];
    else if (fromHcontext_valid)
      reg_HCONTEXT <= fromHcontext_bits_HCONTEXT;
  end
  assign rdata               = reg_HCONTEXT;
  assign regOut_HCONTEXT     = reg_HCONTEXT;
  assign toHcontext_HCONTEXT = reg_HCONTEXT;
endmodule
