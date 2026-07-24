// NewCSR counter AUX wrapper (HtimedeltaModule). Single-module copy from newcsr_counter_wrappers.sv
// (scripts/gen_newcsr_counter.py). Thin wrapper over xs_ucounter/xs_mcounter/xs_rwlatch/xs_time.
// FM-verified against golden HtimedeltaModule.sv in signoff-strict mode. 铁律: wrapper 单独提交。
module HtimedeltaModule(
  input         clock,
  input         reset,
  input         w_wen,
  input  [63:0] w_wdata,
  output [63:0] rdata,
  output [63:0] regOut_ALL
);
  xs_rwlatch #(.RESET_VAL(64'h0)) u_core (
    .clock   (clock),
    .reset   (reset),
    .w_wen   (w_wen),
    .w_wdata (w_wdata),
    .rdata   (rdata),
    .regOut  (regOut_ALL)
  );
endmodule
