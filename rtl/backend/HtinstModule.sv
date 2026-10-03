// HtinstModule.sv — hypervisor trap-value CSR using the canonical trap-value core.
// Software and trap hardware writes merge bitwise, preserving the G1 write priority exactly.
// Parent: NewCSR; ports are generated from the G1 golden module to keep the contract exact.

// BEGIN GENERATED(csr_dh)
module HtinstModule(
  input logic clock,
  input logic reset,
  input logic w_wen,
  input logic [63:0] w_wdata,
  output logic [63:0] rdata,
  output logic [63:0] regOut_ALL,
  input logic trapToHS_htinst_valid,
  input logic [63:0] trapToHS_htinst_bits_ALL
);

  xs_CsrTrapValue_core u_core (
    .clock(clock),
    .reset(reset),
    .wen(w_wen),
    .wdata(w_wdata),
    .trap_valid(trapToHS_htinst_valid),
    .trap_wdata(trapToHS_htinst_bits_ALL),
    .value(rdata)
  );
  assign regOut_ALL = rdata;
endmodule
// END GENERATED
