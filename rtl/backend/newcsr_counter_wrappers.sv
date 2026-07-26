// 自动生成: scripts/gen_newcsr_counter.py —— 勿手改
// NewCSR base-counter / time CSR thin wrappers (8 modules).
// xs_ucounter: cycle/instret (clock-only shadow + read-mux, 无 reset)
// xs_mcounter: Mcycle/Minstret (write-or-increment, 无 reset; incr 由 wrapper 装配)
// xs_rwlatch : Htimedelta(reset=0)/Stimecmp/VStimecmp(reset=all-ones) 写锁存
// xs_time    : timeModule (bespoke: reg_time + virtMode staging + vstime add)
// FM-verified against golden in signoff-strict mode.

module cycleModule(
  input         clock,
  output [63:0] rdata,
  input  [63:0] mHPM_cycle,
  input         debugModeStopCount,
  input         unprivCountUpdate
);
  xs_ucounter u_core (
    .clock              (clock),
    .mhpm_src           (mHPM_cycle),
    .debugModeStopCount (debugModeStopCount),
    .unprivCountUpdate  (unprivCountUpdate),
    .rdata              (rdata)
  );
endmodule

module instretModule(
  input         clock,
  output [63:0] rdata,
  input  [63:0] mHPM_instret,
  input         debugModeStopCount,
  input         unprivCountUpdate
);
  xs_ucounter u_core (
    .clock              (clock),
    .mhpm_src           (mHPM_instret),
    .debugModeStopCount (debugModeStopCount),
    .unprivCountUpdate  (unprivCountUpdate),
    .rdata              (rdata)
  );
endmodule

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

module MinstretModule(
  input         clock,
  input         w_wen,
  input  [63:0] w_wdata,
  output [63:0] rdata,
  output [63:0] regOut_ALL,
  input         mcountinhibit_IR,
  input  [6:0]  robCommit_instNum_bits
);
  xs_mcounter u_core (
    .clock      (clock),
    .w_wen      (w_wen),
    .w_wdata    (w_wdata),
    .inhibit    (mcountinhibit_IR),
    .incr       ({57'h0, robCommit_instNum_bits}),
    .rdata      (rdata),
    .regOut_ALL (regOut_ALL)
  );
endmodule

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

module StimecmpModule(
  input         clock,
  input         reset,
  input         w_wen,
  input  [63:0] w_wdata,
  output [63:0] rdata,
  output [63:0] regOut_stimecmp
);
  xs_rwlatch #(.RESET_VAL(64'hFFFFFFFFFFFFFFFF)) u_core (
    .clock   (clock),
    .reset   (reset),
    .w_wen   (w_wen),
    .w_wdata (w_wdata),
    .rdata   (rdata),
    .regOut  (regOut_stimecmp)
  );
endmodule

module VStimecmpModule(
  input         clock,
  input         reset,
  input         w_wen,
  input  [63:0] w_wdata,
  output [63:0] rdata,
  output [63:0] regOut_vstimecmp
);
  xs_rwlatch #(.RESET_VAL(64'hFFFFFFFFFFFFFFFF)) u_core (
    .clock   (clock),
    .reset   (reset),
    .w_wen   (w_wen),
    .w_wdata (w_wdata),
    .rdata   (rdata),
    .regOut  (regOut_vstimecmp)
  );
endmodule

module timeModule(
  input         clock,
  input         reset,
  output [63:0] rdata,
  input         mHPM_time_valid,
  input  [63:0] mHPM_time_bits,
  input         v,
  input         nextV,
  input  [63:0] htimedelta,
  input         debugModeStopTime,
  output        updated,
  output [63:0] stime,
  output [63:0] vstime
);
  xs_time u_core (
    .clock             (clock),
    .reset             (reset),
    .rdata             (rdata),
    .mHPM_time_valid   (mHPM_time_valid),
    .mHPM_time_bits    (mHPM_time_bits),
    .v                 (v),
    .nextV             (nextV),
    .htimedelta        (htimedelta),
    .debugModeStopTime (debugModeStopTime),
    .updated           (updated),
    .stime             (stime),
    .vstime            (vstime)
  );
endmodule
