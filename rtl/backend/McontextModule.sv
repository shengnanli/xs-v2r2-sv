// McontextModule.sv — machine context CSR storage and hypervisor-context bridge.
// A software CSR write wins over the incoming H-context update in the same cycle.
// Reset is asynchronous and the wrapper keeps the flattened NewCSR port names.
module xs_McontextModule_core (
  input logic clock, input logic reset, input logic csr_wen,
  input logic [63:0] csr_wdata,
  output logic [13:0] rdata, output logic [13:0] hcontext,
  input logic from_hcontext_valid,
  input logic [13:0] from_hcontext,
  output logic [13:0] to_hcontext
);
  logic [13:0] hcontext_q;

  always_ff @(posedge clock or posedge reset) begin
    if (reset)
      hcontext_q <= 14'h0;
    else if (csr_wen)
      hcontext_q <= csr_wdata[13:0];
    else if (from_hcontext_valid)
      hcontext_q <= from_hcontext;
  end

  assign rdata = hcontext_q;
  assign hcontext = hcontext_q;
  assign to_hcontext = hcontext_q;
endmodule

// BEGIN GENERATED(csr_m) — generated wrapper; do not edit this block.
module McontextModule(
  input         clock,
  input         reset,
  input         w_wen,
  input  [63:0] w_wdata,
  output [13:0] rdata,
  output [13:0] regOut_HCONTEXT,
  input         fromHcontext_valid,
  input  [13:0] fromHcontext_bits_HCONTEXT,
  output [13:0] toHcontext_HCONTEXT
);

  xs_McontextModule_core u_core (
    .clock               (clock),
    .reset               (reset),
    .csr_wen             (w_wen),
    .csr_wdata           (w_wdata),
    .rdata               (rdata),
    .hcontext            (regOut_HCONTEXT),
    .from_hcontext_valid (fromHcontext_valid),
    .from_hcontext       (fromHcontext_bits_HCONTEXT),
    .to_hcontext         (toHcontext_HCONTEXT)
  );
endmodule
// END GENERATED
