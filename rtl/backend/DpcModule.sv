// DpcModule.sv — debug PC CSR wrapper around the canonical EPC/tvec core.
// Debug entry and software writes merge bitwise into the 63-bit saved EPC; bit zero reads zero.
// Parent: NewCSR; ports are generated from the G1 golden module to keep the contract exact.

// BEGIN GENERATED(csr_dh)
module DpcModule(
  input logic clock,
  input logic reset,
  input logic w_wen,
  input logic [63:0] w_wdata,
  output logic [63:0] rdata,
  output logic [62:0] regOut_epc,
  input logic trapToD_dpc_valid,
  input logic [62:0] trapToD_dpc_bits_epc
);

  xs_CsrEpcTvec_core #(.IS_TVEC(1'b0)) u_core (
    .clock(clock),
    .reset(reset),
    .wen(w_wen),
    .wdata(w_wdata),
    .trap_valid(trapToD_dpc_valid),
    .trap_epc(trapToD_dpc_bits_epc),
    .rdata(rdata),
    .epc(regOut_epc),
    .mode(),
    .addr()
  );
endmodule
// END GENERATED
