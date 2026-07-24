// NewCSR CSR-field primitive: Hpmcounter (unprivileged HPM counter shadow).
//
// Faithful, readable, parameterized reimplementation of the golden
// HpmcounterNModule family (Hpmcounter3Module .. Hpmcounter31Module, N=3..31).
//
// Golden behavior (bug-for-bug identical across all 29 instances; the only
// per-instance difference is the machine-mode source input port name
// mHPM_hpmcounters_{N-3}, which the thin wrapper binds to `mhpm_src`):
//
//   reg_hpmcounter is a 64-bit architectural shadow of the machine-mode HPM
//   counter mHPM_hpmcounters_i. It is asynchronous-reset to 0 and, on each
//   cycle where unprivCountUpdate is asserted, latches the machine-mode value.
//   Otherwise it holds. The read data path returns the (possibly stale) shadow
//   register when debugModeStopCount is set, else the live machine-mode value.
//
//   reg_hpmcounter <= (reset)            ? 64'h0
//                   : (unprivCountUpdate)? mhpm_src
//                                        : reg_hpmcounter;
//   rdata = debugModeStopCount ? reg_hpmcounter : mhpm_src;
//
// This module has no per-index behavioral divergence, so IDX is carried only
// for documentation/provenance and does not affect logic (matching golden).

module xs_hpmcounter #(
    parameter int unsigned IDX = 0  // hpmcounter index (0-based, = N-3); doc only
) (
    input         clock,
    input         reset,
    input  [63:0] mhpm_src,           // machine-mode HPM counter value (live)
    input         debugModeStopCount, // read-mux select: stale shadow vs live
    input         unprivCountUpdate,  // shadow-register write enable
    output [63:0] rdata               // unprivileged read data
);

  reg [63:0] reg_hpmcounter;

  always @(posedge clock or posedge reset) begin
    if (reset)
      reg_hpmcounter <= 64'h0;
    else if (unprivCountUpdate)
      reg_hpmcounter <= mhpm_src;
  end

  assign rdata = debugModeStopCount ? reg_hpmcounter : mhpm_src;

endmodule
