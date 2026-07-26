// NewCSR CSR-field primitives: Iprio (AIA interrupt-priority CSR array).
//
// Faithful, readable, parameterized reimplementation of the golden Iprio family
// (iprio0..iprio15 packed into even-indexed 64-bit CSRs; RV64 exposes
// Iprio0/2/4/6/8/10/12/14 in two flavors: base "machine" (mie_* gated) and the
// "_1" supervisor/VS flavor (sie_* gated). 16 golden modules total).
//
// GOLDEN REALITY (bug-for-bug — the family is NOT uniform per index; the golden
// firtool output has THREE structurally distinct body shapes):
//
//   (A) reg_ALL + masked read  [Iprio4/6/8/10/12/14 base and _1, 12 modules]
//       reg_ALL is a 64-bit register written whole on w_wen. The read is
//       reg_ALL bitwise-AND a 64-bit gate mask assembled from eight 8-bit
//       lanes, each replicated from one interrupt-enable bit.  The base
//       machine flavor's mie_* ports are all UNREAD (rdata = 64'h0), i.e. the
//       gate mask is 64'h0.  The _1 supervisor flavor masks each byte-lane
//       with the corresponding sie_LC*IE enable.  Covered by xs_iprio_ext:
//       the wrapper assembles gate_mask (0 for base, {8{sie..}} lanes for _1).
//
//   (B) six named 8-bit fields  [Iprio0/2 base and _1, 4 modules]
//       Six independent 8-bit priority registers, each written from a distinct
//       (non-uniform) 8-bit slice of w_wdata, each read gated by a distinct
//       enable and packed into rdata at a distinct byte position (with some
//       byte lanes forced to 0).  The slice map, gate selection and packing are
//       fully index-specific, so xs_iprio6 exposes the six raw registers (with
//       per-instance write-slice offsets as parameters) and the thin wrapper
//       performs the index-specific gating + packing faithfully.
//
// No behavioral divergence is invented; every mask/slice/pack is transcribed
// from the corresponding golden module.

// ----------------------------------------------------------------------------
// (A) reg_ALL + masked read.  Covers Iprio{4,6,8,10,12,14}Module[_1].
//     rdata = reg_ALL & gate_mask.  Base machine flavor drives gate_mask=0
//     (matching golden rdata=64'h0 with unread mie_* ports); _1 flavor drives
//     the concatenated {8{sie_*}} byte lanes.
// ----------------------------------------------------------------------------
module xs_iprio_ext #(
    parameter int unsigned IDX = 4  // even iprio group index (4..14); doc/provenance only
) (
    input         clock,
    input         reset,
    input         w_wen,      // CSR write enable (writes reg_ALL whole)
    input  [63:0] w_wdata,    // CSR write data
    input  [63:0] gate_mask,  // per-instance read gate (0 for base, {8{ie}} lanes for _1)
    output [63:0] rdata       // CSR read data = reg_ALL & gate_mask
);

  reg [63:0] reg_ALL;

  always @(posedge clock or posedge reset) begin
    if (reset)
      reg_ALL <= 64'h0;
    else if (w_wen)
      reg_ALL <= w_wdata;
  end

  assign rdata = reg_ALL & gate_mask;

endmodule

// ----------------------------------------------------------------------------
// (B) six named 8-bit priority fields.  Covers Iprio{0,2}Module[_1].
//     Each of the six 8-bit registers is written from a parameterized 8-bit
//     slice of w_wdata (WOFF{0..5} = LSB of that slice).  The wrapper reads the
//     raw registers back out (reg0..reg5) and applies the index-specific enable
//     gating and rdata byte-packing.  Async-reset to 0, write priority under
//     w_wen (matching golden if(reset)/else if(w_wen)).
// ----------------------------------------------------------------------------
module xs_iprio6 #(
    parameter int unsigned WOFF0 = 8,
    parameter int unsigned WOFF1 = 16,
    parameter int unsigned WOFF2 = 24,
    parameter int unsigned WOFF3 = 40,
    parameter int unsigned WOFF4 = 48,
    parameter int unsigned WOFF5 = 56
) (
    input        clock,
    input        reset,
    input        w_wen,
    input [63:0] w_wdata,
    output [7:0] reg0,
    output [7:0] reg1,
    output [7:0] reg2,
    output [7:0] reg3,
    output [7:0] reg4,
    output [7:0] reg5
);

  reg [7:0] r0, r1, r2, r3, r4, r5;

  always @(posedge clock or posedge reset) begin
    if (reset) begin
      r0 <= 8'h0;
      r1 <= 8'h0;
      r2 <= 8'h0;
      r3 <= 8'h0;
      r4 <= 8'h0;
      r5 <= 8'h0;
    end
    else if (w_wen) begin
      r0 <= w_wdata[WOFF0 +: 8];
      r1 <= w_wdata[WOFF1 +: 8];
      r2 <= w_wdata[WOFF2 +: 8];
      r3 <= w_wdata[WOFF3 +: 8];
      r4 <= w_wdata[WOFF4 +: 8];
      r5 <= w_wdata[WOFF5 +: 8];
    end
  end

  assign reg0 = r0;
  assign reg1 = r1;
  assign reg2 = r2;
  assign reg3 = r3;
  assign reg4 = r4;
  assign reg5 = r5;

endmodule
