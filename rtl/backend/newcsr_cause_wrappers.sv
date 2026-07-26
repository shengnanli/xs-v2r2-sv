// NewCSR cause family AUX wrappers (McauseModule, ScauseModule). Both golden
// bodies are byte-identical apart from the trap-write port name; each is a thin
// wrapper over the readable primitive xs_cause (rtl/backend/newcsr_cause.sv).
// FM-verified strict, no black box.
//
// (VScauseModule is the H-extension guest variant, out of scope this wave.)

module McauseModule(
  input         clock,
  input         reset,
  input         w_wen,
  input  [63:0] w_wdata,
  output [63:0] rdata,
  output        regOut_Interrupt,
  output [62:0] regOut_ExceptionCode,
  input         trapToM_mcause_valid,
  input         trapToM_mcause_bits_Interrupt,
  input  [62:0] trapToM_mcause_bits_ExceptionCode
);
  xs_cause u_core (
    .clock(clock), .reset(reset), .w_wen(w_wen), .w_wdata(w_wdata),
    .rdata(rdata),
    .regOut_Interrupt(regOut_Interrupt),
    .regOut_ExceptionCode(regOut_ExceptionCode),
    .trap_valid(trapToM_mcause_valid),
    .trap_bits_Interrupt(trapToM_mcause_bits_Interrupt),
    .trap_bits_ExceptionCode(trapToM_mcause_bits_ExceptionCode));
endmodule

module ScauseModule(
  input         clock,
  input         reset,
  input         w_wen,
  input  [63:0] w_wdata,
  output [63:0] rdata,
  output        regOut_Interrupt,
  output [62:0] regOut_ExceptionCode,
  input         trapToHS_scause_valid,
  input         trapToHS_scause_bits_Interrupt,
  input  [62:0] trapToHS_scause_bits_ExceptionCode
);
  xs_cause u_core (
    .clock(clock), .reset(reset), .w_wen(w_wen), .w_wdata(w_wdata),
    .rdata(rdata),
    .regOut_Interrupt(regOut_Interrupt),
    .regOut_ExceptionCode(regOut_ExceptionCode),
    .trap_valid(trapToHS_scause_valid),
    .trap_bits_Interrupt(trapToHS_scause_bits_Interrupt),
    .trap_bits_ExceptionCode(trapToHS_scause_bits_ExceptionCode));
endmodule
