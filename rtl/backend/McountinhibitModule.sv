// McountinhibitModule.sv — machine counter inhibit CSR.
// The reserved bit two remains zero on reads; writable fields retain their source bits.
// Reset and CSR write timing match the canonical machine CSR leaf.
module xs_McountinhibitModule_core (
  input logic clock, input logic reset, input logic csr_wen,
  input logic [63:0] csr_wdata,
  output logic [63:0] rdata,
  output logic cy, output logic ir, output logic [28:0] hpm3
);
  logic cy_q, ir_q;
  logic [28:0] hpm3_q;

  always_ff @(posedge clock or posedge reset) begin
    if (reset) begin
      cy_q <= 1'b0;
      ir_q <= 1'b0;
      hpm3_q <= 29'h0;
    end else if (csr_wen) begin
      cy_q <= csr_wdata[0];
      ir_q <= csr_wdata[2];
      hpm3_q <= csr_wdata[31:3];
    end
  end

  assign rdata = {32'h0, hpm3_q, ir_q, 1'b0, cy_q};
  assign cy = cy_q;
  assign ir = ir_q;
  assign hpm3 = hpm3_q;
endmodule

// BEGIN GENERATED(csr_m) — generated wrapper; do not edit this block.
module McountinhibitModule(
  input         clock,
  input         reset,
  input         w_wen,
  input  [63:0] w_wdata,
  output [63:0] rdata,
  output        regOut_CY,
  output        regOut_IR,
  output [28:0] regOut_HPM3
);

  xs_McountinhibitModule_core u_core (
    .clock     (clock),
    .reset     (reset),
    .csr_wen   (w_wen),
    .csr_wdata (w_wdata),
    .rdata     (rdata),
    .cy        (regOut_CY),
    .ir        (regOut_IR),
    .hpm3      (regOut_HPM3)
  );
endmodule
// END GENERATED
