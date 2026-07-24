// NewCSR counter AUX wrapper (McycleModule). Single-module copy from newcsr_counter_wrappers.sv
// (scripts/gen_newcsr_counter.py). Thin wrapper over xs_ucounter/xs_mcounter/xs_rwlatch/xs_time.
// FM-verified against golden McycleModule.sv in signoff-strict mode. 铁律: wrapper 单独提交。
module McycleModule(
  input         clock,
  input         w_wen,
  input  [63:0] w_wdata,
  output [63:0] rdata,
  output [63:0] regOut_ALL,
  input         mcountinhibit_CY
);
  xs_mcounter u_core (
    .clock      (clock),
    .w_wen      (w_wen),
    .w_wdata    (w_wdata),
    .inhibit    (mcountinhibit_CY),
    .incr       (64'h1),
    .rdata      (rdata),
    .regOut_ALL (regOut_ALL)
  );
endmodule
