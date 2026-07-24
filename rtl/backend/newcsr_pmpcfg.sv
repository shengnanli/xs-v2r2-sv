// NewCSR CSR-field primitive: Pmpcfg (PMP config CSR read slicer).
//
// Faithful, readable, parameterized reimplementation of the golden
// PmpcfgNModule family (Pmpcfg0Module, Pmpcfg2Module — RV64 uses only the
// even-numbered pmpcfg CSRs; each packs 8 PMP config bytes).
//
// IMPORTANT — golden reality vs. WARL spec:
//   The golden PmpcfgNModule modules are NOT the PMP-config WARL write logic
//   (R/W/X/A/L legalization). That WARL legalization lives upstream in the PMP
//   config-entry logic, which produces the already-legalized 128-bit packed
//   read bus `cfgRData`. The PmpcfgNModule modules are purely-combinational
//   read slicers that expose one 64-bit half of that bus as a CSR read:
//
//     Pmpcfg0Module : rdata = regOut_ALL = cfgRData[63:0]     (HI=0)
//     Pmpcfg2Module : rdata = regOut_ALL = cfgRData[127:64]   (HI=1)
//
//   We reimplement this bug-for-bug; the only per-instance difference is which
//   64-bit half is selected, carried by the HI parameter. No clock/reset/
//   registers exist in golden (pure comb), so none here.

module xs_pmpcfg #(
    parameter bit HI = 1'b0  // 0 -> low half cfgRData[63:0]; 1 -> high half [127:64]
) (
    output [63:0]  rdata,      // CSR read data (selected 64-bit half of cfgRData)
    output [63:0]  regOut_ALL, // architectural value (same selected half)
    input  [127:0] cfgRData    // upstream-legalized packed 128-bit PMP config bus
);

  wire [63:0] sel = HI ? cfgRData[127:64] : cfgRData[63:0];

  assign rdata      = sel;
  assign regOut_ALL = sel;

endmodule
