// NewCSR CSR-field primitive: Mhpmcounter (machine-mode HPM counter).
//
// Faithful, readable, parameterized reimplementation of the golden
// MhpmcounterNModule family (Mhpmcounter3Module .. Mhpmcounter31Module,
// N=3..31, index IDX = N-3, 29 instances).
//
// Golden behavior (bug-for-bug identical across all 29 instances; the ONLY
// per-instance difference is the bit index selected from mcountinhibit_HPM3,
// which is HPM3[IDX] where IDX = N-3):
//
//   reg_ALL is a 64-bit architectural machine-mode HPM counter, async-reset
//   to 0. Write priority (matching golden's if/else-if chain):
//     1) explicit CSR write w_wen -> latch w_wdata
//     2) else if any perf event (|perf_value) AND not counting-inhibited ->
//        increment by perf_value (65-bit add, low 64 kept)
//     3) else hold
//
//   countingInhibit = mcountinhibit_HPM3[IDX] | ~countingEn
//   counterAdd      = {1'b0, reg_ALL} + perf_value        (65-bit)
//   reg_ALL <= reset      ? 64'h0
//            : w_wen       ? w_wdata
//            : (|perf_value & ~countingInhibit) ? counterAdd[63:0]
//                                                : reg_ALL
//   rdata          = reg_ALL
//   regOut_ALL     = reg_ALL
//   toMhpmeventOF  = ~countingInhibit & counterAdd[64]   (overflow carry)
//
// The golden ports mcountinhibit_CY and mcountinhibit_IR are declared but
// unread in every instance (dead inputs; the CY/IR inhibit only applies to
// mcycle/minstret, not the generic HPM counters). We preserve them as ports
// for interface parity; they are intentionally unused (bug-for-bug with
// golden — Formality sees them as matched unread ref/impl inputs).

module xs_mhpmcounter #(
    parameter int unsigned IDX = 0  // hpm counter index (0-based, = N-3); selects HPM3[IDX]
) (
    input         clock,
    input         reset,
    input         w_wen,               // explicit CSR write enable (highest priority)
    input  [63:0] w_wdata,             // CSR write data
    output [63:0] rdata,               // CSR read data (= reg_ALL)
    output [63:0] regOut_ALL,          // architectural counter value (= reg_ALL)
    input         mcountinhibit_CY,    // unread in golden (dead input, kept for parity)
    input         mcountinhibit_IR,    // unread in golden (dead input, kept for parity)
    input  [28:0] mcountinhibit_HPM3,  // per-HPM inhibit bits; this counter uses [IDX]
    input         countingEn,          // global counting enable
    input  [5:0]  perf_value,          // performance event increment this cycle
    output        toMhpmeventOF        // overflow flag to mhpmevent (carry-out of add)
);

  reg [63:0] reg_ALL;

  wire        countingInhibit = mcountinhibit_HPM3[IDX] | ~countingEn;
  wire [64:0] counterAdd      = 65'({1'h0, reg_ALL} + {59'h0, perf_value});

  always @(posedge clock or posedge reset) begin
    if (reset)
      reg_ALL <= 64'h0;
    else if (w_wen)
      reg_ALL <= w_wdata;
    else if ((|perf_value) & ~countingInhibit)
      reg_ALL <= counterAdd[63:0];
  end

  assign rdata         = reg_ALL;
  assign regOut_ALL    = reg_ALL;
  assign toMhpmeventOF = ~countingInhibit & counterAdd[64];

endmodule
