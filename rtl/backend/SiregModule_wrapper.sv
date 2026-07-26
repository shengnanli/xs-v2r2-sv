// NewCSR indireg AUX wrapper (SiregModule). Single-module copy from newcsr_indireg_wrappers.sv
// (scripts/gen_newcsr_indireg.py). Thin wrapper over xs_indireg[_wo] (newcsr_indireg.sv).
// FM-verified against golden SiregModule.sv in signoff-strict mode. 铁律: wrapper 单独提交。
module SiregModule(
  input         clock,
  input         w_wen,
  input  [63:0] w_wdata,
  output [63:0] rdata,
  output [63:0] regOut_ALL,
  input  [63:0] iregRead_sireg
);
  xs_indireg u_core (
    .clock      (clock),
    .w_wen      (w_wen),
    .w_wdata    (w_wdata),
    .iread      (iregRead_sireg),
    .rdata      (rdata),
    .regOut_ALL (regOut_ALL)
  );
endmodule
