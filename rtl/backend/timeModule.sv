// timeModule.sv — the unprivileged `time` CSR of NewCSR (read-only shadow of mtime).
// Scala: NewCSR/Unprivileged.scala (val time = CSRModule("time", ...)).
// The real counter lives outside the core (CLINT/AIA mtime); every RTC tick
// it arrives here as mHPM.time (valid + 64-bit value).  This module keeps a
// local copy that software reads with `rdtime`:
//   * stime  = mHPM.time.bits                  (what HS/U software sees)
//   * vstime = mHPM.time.bits + htimedelta     (what a guest, V=1, sees)
//   * the local copy is reloaded with the view of the *current* mode
//     (v ? vstime : stime) whenever a tick arrives and dcsr.STOPTIME is not
//     stopping time in debug mode, or one cycle after the virtualisation mode
//     changed (nextV != v is registered for timing, then forces a reload).
//   * updated = the tick (not stopped) delayed one cycle.
// Reset: the copy itself has no reset (golden `always @(posedge clock)`); the
// two one-bit control flops reset asynchronously to 0.
module xs_timeModule_core (
  input  logic        clk,
  input  logic        rst,
  input  logic        tick_valid,       // mHPM.time.valid
  input  logic [63:0] mtime,            // mHPM.time.bits
  input  logic        v,                // current virtualisation mode
  input  logic        next_v,           // virtualisation mode next cycle
  input  logic [63:0] htimedelta,
  input  logic        stop_time,        // debug mode with dcsr.STOPTIME
  output logic [63:0] time_value,       // rdata
  output logic        updated,
  output logic [63:0] stime,
  output logic [63:0] vstime
);
  logic        tick;               // a tick that is allowed to count
  logic        virt_mode_changed;  // RegNext(nextV =/= v, false.B)
  logic        tick_q;             // GatedValidRegNext(tick)
  logic [63:0] time_q;

  assign tick   = tick_valid & ~stop_time;
  assign stime  = mtime;
  assign vstime = mtime + htimedelta;   // wraps at 64 bits

  always_ff @(posedge clk or posedge rst) begin
    if (rst) begin
      virt_mode_changed <= 1'b0;
      tick_q            <= 1'b0;
    end else begin
      virt_mode_changed <= (next_v != v);
      tick_q            <= tick;
    end
  end

  always_ff @(posedge clk) begin
    if (tick | virt_mode_changed)
      time_q <= v ? vstime : stime;
  end

  assign time_value = time_q;
  assign updated    = tick_q;
endmodule

module timeModule (
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
  xs_timeModule_core u_core (
    .clk        (clock),
    .rst        (reset),
    .tick_valid (mHPM_time_valid),
    .mtime      (mHPM_time_bits),
    .v          (v),
    .next_v     (nextV),
    .htimedelta (htimedelta),
    .stop_time  (debugModeStopTime),
    .time_value (rdata),
    .updated    (updated),
    .stime      (stime),
    .vstime     (vstime)
  );
endmodule
