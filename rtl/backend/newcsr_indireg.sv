// NewCSR CSR-field primitives: Indirect-register (Sireg/Mireg/VSireg family).
//
// Faithful, readable reimplementation of the golden {S,M,VS}iregNModule family
// (the AIA indirect-CSR select/data registers reachable via *iselect/*ireg).
// 18 golden modules: 3 base (SiregModule/MiregModule/VSiregModule) + 15
// numbered (S/M/VS × N=2..6).
//
// GOLDEN REALITY (bug-for-bug):
//   Every module holds a 64-bit reg_ALL that is a plain write-latch:
//       always @(posedge clock) if (w_wen) reg_ALL <= w_wdata;
//   NOTE: there is NO reset — golden uses a clock-only always block (the
//   indirect-data staging register is not architecturally reset). We reproduce
//   this exactly (no reset port, no async/sync reset of reg_ALL).
//
//   Two output shapes:
//     (1) base (SiregModule/MiregModule/VSiregModule): additionally passes an
//         externally-computed indirect read value straight through to rdata
//         (the actual selected indirect CSR is resolved upstream and fed back
//         in via iregRead_{sireg,mireg}); regOut_ALL exposes the raw staged reg.
//           rdata      = iread            (external indirect read passthrough)
//           regOut_ALL = reg_ALL          (raw staged write value)
//     (2) numbered (N=2..6): only exposes the raw staged register.
//           regOut_ALL = reg_ALL
//
// No behavioral divergence invented; transcribed from golden.

// ---- Shape (1): write-latch + external rdata passthrough + regOut. ----------
module xs_indireg (
    input         clock,
    input         w_wen,     // CSR write enable (write-latches w_wdata)
    input  [63:0] w_wdata,   // CSR write data
    input  [63:0] iread,     // external indirect read value (-> rdata passthrough)
    output [63:0] rdata,     // CSR read data = iread
    output [63:0] regOut_ALL // raw staged register value = reg_ALL
);

  reg [63:0] reg_ALL;

  always @(posedge clock) begin
    if (w_wen)
      reg_ALL <= w_wdata;
  end

  assign rdata      = iread;
  assign regOut_ALL = reg_ALL;

endmodule

// ---- Shape (2): write-latch, exposes only regOut_ALL (N=2..6). --------------
module xs_indireg_wo (
    input         clock,
    input         w_wen,
    input  [63:0] w_wdata,
    output [63:0] regOut_ALL
);

  reg [63:0] reg_ALL;

  always @(posedge clock) begin
    if (w_wen)
      reg_ALL <= w_wdata;
  end

  assign regOut_ALL = reg_ALL;

endmodule
