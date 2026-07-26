// NewCSR InterruptFilter primitives (readable, parametric).
//
// These primitives back the InterruptFilter CSR module (RISC-V interrupt
// priority resolution + M/HS/VS delegation + virtual-interrupt injection).
// They are shared by the generated readable core (InterruptFilter.sv core body).
//
// The golden RTL (CIRCT-flattened) unrolls the whole priority network into
// thousands of `_T_`/`_GEN_` wires.  Every reduction node in that network is the
// SAME 2-input "min-priority" merge (golden calls it `minIprio`), so we recover
// the tree structure and re-emit each node as one xs_iprio_merge instance.  This
// is correct-by-construction (each instance reproduces the golden node body
// bit-for-bit) and removes the _T_/_GEN_ noise, exposing the real tree shape.
//
// -----------------------------------------------------------------------------
// xs_iprio_merge : 2-input min-priority merge.
//
// Each candidate is a tuple {enable, isZero, greaterThan255, prioNum[7:0],
// idx[5:0]}.  `enable` = this candidate holds a pending&enabled interrupt.
// `isZero` = its programmed priority value is 0 (special "unprioritized" case).
// `greaterThan255` = its priority value overflowed 8 bits (only the external
// MEIP/SEIP leaf, reg index 3, can set this — its priority comes from the 11-bit
// mtopei/stopei IPRIO).  `prioNum` = the 8-bit priority; `idx` = interrupt slot.
//
// Winner selection (transcribed bit-for-bit from golden, e.g. lines 1513-1589):
//   T_1  onlyA  =  a.enable & ~b.enable          -> a wins
//   T_3  onlyB  = ~a.enable &  b.enable          -> b wins
//   T_4  both   =  a.enable &  b.enable
//     T_5  bothZero =  a.isZero &  b.isZero      -> a (lower idx / left tie)
//     T_7  aZbNZ   =  a.isZero & ~b.isZero
//       T_8  aLo   =  a.idx < THRESH             -> a if aLo else b
//     T_11 aNZbZ   = ~a.isZero &  b.isZero
//       T_12 bLo   =  b.idx < THRESH             -> b if bLo else a
//     T_16 bothNZ  = ~a.isZero & ~b.isZero
//       a>255 -> b ; b>255 -> a ; else T_24 (a.prio<=b.prio) ? a : b
// THRESH distinguishes the high-priority region (VSEI/SEI) from local-custom
// interrupts: M-tree = 6'h19, HS-tree = 6'h1C, HV-tree = 6'h20 (never taken —
// hviprio idx values are all below threshold, kept for uniformity).
//
// gt255 output: forwarded only when the winning side won through a NON-bothNZ
// path AND that side is >255 (in bothNZ a >255 candidate has already lost, so it
// can no longer influence a higher merge).  Only one side ever carries gt255.
// -----------------------------------------------------------------------------
module xs_iprio_merge #(
    parameter logic [5:0] THRESH = 6'h1C
) (
    input             a_enable,
    input             a_isZero,
    input             a_gt255,
    input      [7:0]  a_prio,
    input      [5:0]  a_idx,
    input             b_enable,
    input             b_isZero,
    input             b_gt255,
    input      [7:0]  b_prio,
    input      [5:0]  b_idx,
    output            o_enable,
    output            o_isZero,
    output            o_gt255,
    output     [7:0]  o_prio,
    output     [5:0]  o_idx
);
  // Comparison predicates (golden T_1 .. T_24).
  wire onlyA   =  a_enable & ~b_enable;               // T_1
  wire onlyB   = ~a_enable &  b_enable;               // T_3
  wire both    =  a_enable &  b_enable;               // T_4
  wire bothZero=  a_isZero &  b_isZero;               // T_5
  wire aZbNZ   =  a_isZero & ~b_isZero;               // T_7
  wire aLo     =  a_idx < THRESH;                     // T_8
  wire aNZbZ   = ~a_isZero &  b_isZero;               // T_11
  wire bLo     =  b_idx < THRESH;                     // T_12
  wire bothNZ  = ~a_isZero & ~b_isZero;               // T_16
  wire aPrioLe =  a_prio <= b_prio;                   // T_24

  // Winner of the both-nonzero branch (unifies the a-gt255 / b-gt255 / plain
  // node variants: a>255 loses, b>255 loses, else compare).
  wire bothNZ_pickA = ~a_gt255 & (b_gt255 | aPrioLe);

  // Field selection as golden's priority-OR of guarded terms (identical shape).
  assign o_prio =
      (onlyA ? a_prio : 8'h0)
    | (onlyB ? b_prio : 8'h0)
    | (both
         ? (bothZero ? a_prio : 8'h0)
           | (aZbNZ ? (aLo ? a_prio : b_prio) : 8'h0)
           | (aNZbZ ? (bLo ? b_prio : a_prio) : 8'h0)
           | (bothNZ ? (bothNZ_pickA ? a_prio : b_prio) : 8'h0)
         : 8'h0);

  assign o_idx =
      (onlyA ? a_idx : 6'h0)
    | (onlyB ? b_idx : 6'h0)
    | (both
         ? (bothZero ? a_idx : 6'h0)
           | (aZbNZ ? (aLo ? a_idx : b_idx) : 6'h0)
           | (aNZbZ ? (bLo ? b_idx : a_idx) : 6'h0)
           | (bothNZ ? (bothNZ_pickA ? a_idx : b_idx) : 6'h0)
         : 6'h0);

  assign o_isZero =
      onlyA & a_isZero
    | onlyB & b_isZero
    | both
      & (bothZero & a_isZero
         | aZbNZ & (aLo ? a_isZero : b_isZero)
         | aNZbZ & (bLo ? b_isZero : a_isZero)
         | bothNZ & (bothNZ_pickA ? a_isZero : b_isZero));

  assign o_enable =
      onlyA & a_enable
    | onlyB & b_enable
    | both
      & (bothZero & a_enable
         | aZbNZ & (aLo ? a_enable : b_enable)
         | aNZbZ & (bLo ? b_enable : a_enable)
         | bothNZ & (bothNZ_pickA ? a_enable : b_enable));

  // gt255 forwards through the non-both-nonzero winning path only.
  wire aWins_nonBothNZ = onlyA | both & (bothZero | aZbNZ & aLo | aNZbZ & ~bLo);
  wire bWins_nonBothNZ = onlyB | both & (aZbNZ & ~aLo | aNZbZ & bLo);
  assign o_gt255 = a_gt255 & aWins_nonBothNZ | b_gt255 & bWins_nonBothNZ;
endmodule

// -----------------------------------------------------------------------------
// xs_delay_n : the output pipeline stage backing InterruptFilter's DelayN cells.
//
// IMPORTANT de-obfuscation note: despite the golden instance names ("DelayN_17",
// "DelayN_210") these are NOT 17- or 210-cycle delays.  The golden module bodies
// are identical 5-stage shift registers (REG..REG_4); only the payload WIDTH
// differs (1-bit for the flag paths, 8-bit for the interrupt vector).  The
// suffix is just the CIRCT dedup id.  We elaborate them on both FM sides as this
// parametric 5-deep shift register (no black-box).
// -----------------------------------------------------------------------------
module xs_delay_n #(
    parameter int WIDTH = 1
) (
    input                    clock,
    input      [WIDTH-1:0]   io_in,
    output     [WIDTH-1:0]   io_out
);
  reg [WIDTH-1:0] r0, r1, r2, r3, r4;
  always @(posedge clock) begin
    r0 <= io_in;
    r1 <= r0;
    r2 <= r1;
    r3 <= r2;
    r4 <= r3;
  end
  assign io_out = r4;
endmodule

// Golden-named delay cells (readable wrappers over xs_delay_n).  Same module
// names as golden so FM matches them structurally; elaborated on both sides.
module DelayN_17(input clock, input io_in, output io_out);
  xs_delay_n #(.WIDTH(1)) u (.clock(clock), .io_in(io_in), .io_out(io_out));
endmodule

module DelayN_210(input clock, input [7:0] io_in, output [7:0] io_out);
  xs_delay_n #(.WIDTH(8)) u (.clock(clock), .io_in(io_in), .io_out(io_out));
endmodule
