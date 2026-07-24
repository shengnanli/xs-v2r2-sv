// NewCSR indireg AUX wrapper (Sireg2Module). Single-module copy from newcsr_indireg_wrappers.sv
// (scripts/gen_newcsr_indireg.py). Thin wrapper over xs_indireg[_wo] (newcsr_indireg.sv).
// FM-verified against golden Sireg2Module.sv in signoff-strict mode. 铁律: wrapper 单独提交。
module Sireg2Module(
  input         clock,
  input         w_wen,
  input  [63:0] w_wdata,
  output [63:0] regOut_ALL
);
  xs_indireg_wo u_core (
    .clock      (clock),
    .w_wen      (w_wen),
    .w_wdata    (w_wdata),
    .regOut_ALL (regOut_ALL)
  );
endmodule
