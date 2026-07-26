// NewCSR CSR-field primitive: scratch (xscratch scratch register CSR).
//
// Faithful, readable reimplementation of the golden scratch family
// (MscratchModule / SscratchModule / VSscratchModule — all byte-identical). A
// scratch CSR is a plain 64-bit read/write register with NO reset (golden has
// no reset port; the register powers up X in sim, deterministic only after the
// first write). Written on any w_wen; rdata = regOut_ALL = reg_ALL.

module xs_scratch (
    input         clock,
    input         w_wen,
    input  [63:0] w_wdata,
    output [63:0] rdata,
    output [63:0] regOut_ALL
);

  reg [63:0] reg_ALL;

  always @(posedge clock) begin
    if (w_wen)
      reg_ALL <= w_wdata;
  end

  assign rdata      = reg_ALL;
  assign regOut_ALL = reg_ALL;

endmodule
