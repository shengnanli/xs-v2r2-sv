// NewCSR Pmpcfg AUX wrapper (Pmpcfg0Module, low half HI=0).
// Thin wrapper over the readable primitive xs_pmpcfg (rtl/backend/
// newcsr_pmpcfg.sv). Selects cfgRData[63:0]. FM-verified against golden strict.
// (Wrapper file committed per pilot铁律 — required for independent AUX FM.)
module Pmpcfg0Module(
  output [63:0]  rdata,
  output [63:0]  regOut_ALL,
  input  [127:0] cfgRData
);
  xs_pmpcfg #(.HI(1'b0)) u_core (
    .rdata      (rdata),
    .regOut_ALL (regOut_ALL),
    .cfgRData   (cfgRData)
  );
endmodule
