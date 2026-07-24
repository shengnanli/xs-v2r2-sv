// NewCSR Pmpaddr AUX wrapper (index 0, golden Pmpaddr0Module).
// Thin wrapper over the readable primitive xs_pmpaddr (rtl/backend/
// newcsr_pmpaddr.sv). Binds golden per-instance read-mux port addrRData_0 to
// the primitive's generic addr_rdata. FM-verified against golden in strict mode.
// (Wrapper file committed per pilot铁律 — required for independent AUX FM.)
module Pmpaddr0Module(
  input         clock,
  input         reset,
  input         w_wen,
  input  [63:0] w_wdata,
  output [63:0] rdata,
  output [45:0] regOut_ADDRESS,
  input  [63:0] addrRData_0
);
  xs_pmpaddr #(.IDX(0)) u_core (
    .clock          (clock),
    .reset          (reset),
    .w_wen          (w_wen),
    .w_wdata        (w_wdata),
    .rdata          (rdata),
    .regOut_ADDRESS (regOut_ADDRESS),
    .addr_rdata     (addrRData_0)
  );
endmodule
