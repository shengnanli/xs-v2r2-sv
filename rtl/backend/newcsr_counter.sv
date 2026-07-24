// NewCSR CSR-field primitives: base counters & time-compare CSRs.
//
// Faithful, readable reimplementation of the golden base-counter / time CSR
// modules (cycle, instret, Mcycle, Minstret, Htimedelta, Stimecmp, VStimecmp,
// time). Each shape transcribed bug-for-bug from golden (note: several golden
// counters use a clock-ONLY always block with NO reset; the timecmp registers
// async-reset to ALL-ONES; Htimedelta async-resets to 0).

// ---- (A) unprivileged shadow counter: cycle / instret. ----------------------
//   reg_X clock-only latch of the machine-mode value on unprivCountUpdate
//   (NO reset). Read returns the (stale) shadow when debugModeStopCount, else
//   the live machine-mode value.  (Same read-mux as Hpmcounter but WITHOUT the
//   async reset that Hpmcounter has — golden cycle/instret have no reset.)
//     reg_X <= unprivCountUpdate ? mhpm_src : reg_X      (clock-only, no reset)
//     rdata  = debugModeStopCount ? reg_X : mhpm_src
module xs_ucounter (
    input         clock,
    input  [63:0] mhpm_src,           // live machine-mode counter value
    input         debugModeStopCount, // read-mux select: stale shadow vs live
    input         unprivCountUpdate,  // shadow write enable
    output [63:0] rdata
);
  reg [63:0] reg_X;
  always @(posedge clock) begin
    if (unprivCountUpdate)
      reg_X <= mhpm_src;
  end
  assign rdata = debugModeStopCount ? reg_X : mhpm_src;
endmodule

// ---- (B) machine counter with write-or-increment: Mcycle / Minstret. --------
//   reg_ALL clock-only (NO reset). Priority:
//     1) w_wen        -> latch w_wdata
//     2) else if inhibit (mcountinhibit_CY / _IR) -> hold
//     3) else         -> reg_ALL + incr
//   Mcycle uses incr = 1; Minstret uses incr = {57'h0, robCommit_instNum_bits}.
//   The wrapper supplies the 64-bit incr, matching golden's per-instance add.
//     rdata = regOut_ALL = reg_ALL
module xs_mcounter (
    input         clock,
    input         w_wen,
    input  [63:0] w_wdata,
    input         inhibit,   // mcountinhibit_CY (Mcycle) / _IR (Minstret)
    input  [63:0] incr,      // per-instance increment (1 for Mcycle; robCommit for Minstret)
    output [63:0] rdata,
    output [63:0] regOut_ALL
);
  reg [63:0] reg_ALL;
  always @(posedge clock) begin
    if (w_wen)
      reg_ALL <= w_wdata;
    else if (inhibit) begin
      // hold (matches golden empty else-if body)
    end
    else
      reg_ALL <= 64'(reg_ALL + incr);
  end
  assign rdata      = reg_ALL;
  assign regOut_ALL = reg_ALL;
endmodule

// ---- (C) async-reset write-latch: Htimedelta / Stimecmp / VStimecmp. --------
//   reg_X async-reset to RESET_VAL, else write-latch w_wdata on w_wen.
//   Htimedelta RESET_VAL=0; Stimecmp/VStimecmp RESET_VAL=all-ones.
//     rdata = regOut = reg_X
module xs_rwlatch #(
    parameter logic [63:0] RESET_VAL = 64'h0
) (
    input         clock,
    input         reset,
    input         w_wen,
    input  [63:0] w_wdata,
    output [63:0] rdata,
    output [63:0] regOut
);
  reg [63:0] reg_X;
  always @(posedge clock or posedge reset) begin
    if (reset)
      reg_X <= RESET_VAL;
    else if (w_wen)
      reg_X <= w_wdata;
  end
  assign rdata  = reg_X;
  assign regOut = reg_X;
endmodule

// ---- (D) time CSR (bespoke): reg_time + virtMode staging + vstime add. ------
//   reg_time clock-only (NO reset) latch, updated when
//     (mHPM_time_valid & ~debugModeStopTime) | virtModeChanged,
//   selecting the virtualized (mHPM_time_bits + htimedelta) value when v.
//   virtModeChanged / updated_last_REG are async-reset flops.
//     rdata   = reg_time
//     updated = updated_last_REG   (= last-cycle mHPM_time_valid & ~debugModeStopTime)
//     stime   = mHPM_time_bits
//     vstime  = mHPM_time_bits + htimedelta
module xs_time (
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
  reg  [63:0] reg_time;
  wire [63:0] vstimeTmp = 64'(mHPM_time_bits + htimedelta);
  reg         virtModeChanged;
  reg         updated_last_REG;

  always @(posedge clock) begin
    if ((mHPM_time_valid & ~debugModeStopTime) | virtModeChanged)
      reg_time <= v ? vstimeTmp : mHPM_time_bits;
  end

  always @(posedge clock or posedge reset) begin
    if (reset) begin
      virtModeChanged  <= 1'h0;
      updated_last_REG <= 1'h0;
    end
    else begin
      virtModeChanged  <= nextV != v;
      updated_last_REG <= mHPM_time_valid & ~debugModeStopTime;
    end
  end

  assign rdata   = reg_time;
  assign updated = updated_last_REG;
  assign stime   = mHPM_time_bits;
  assign vstime  = vstimeTmp;
endmodule
