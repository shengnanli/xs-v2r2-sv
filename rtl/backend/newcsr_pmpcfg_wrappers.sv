// 自动生成: scripts/gen_newcsr_pmpcfg.py —— 勿手改
// NewCSR Pmpcfg family thin wrappers (Pmpcfg0Module HI=0, Pmpcfg2Module HI=1).
// Each wrapper instantiates the readable primitive xs_pmpcfg (see
// rtl/backend/newcsr_pmpcfg.sv) with the per-instance 64-bit half select HI.
// FM-verified against golden PmpcfgNModule.sv in signoff-strict mode.

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

module Pmpcfg2Module(
  output [63:0]  rdata,
  output [63:0]  regOut_ALL,
  input  [127:0] cfgRData
);
  xs_pmpcfg #(.HI(1'b1)) u_core (
    .rdata      (rdata),
    .regOut_ALL (regOut_ALL),
    .cfgRData   (cfgRData)
  );
endmodule
