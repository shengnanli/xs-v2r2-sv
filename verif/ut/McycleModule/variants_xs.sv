// counter _xs UT variants (与 wrapper 同, 模块名改 _xs)。
module cycleModule_xs(
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

module McycleModule_xs(
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

module MinstretModule_xs(
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

module StimecmpModule_xs(
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

module HtimedeltaModule_xs(
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

module timeModule_xs(
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

