// NewCSR CSR-field primitives: topi / topei (AIA top-interrupt read views).
//
// Faithful, readable reimplementations of the golden {M,S,VS}topi and
// {M,S,VS}topei module families. These are PURELY COMBINATIONAL read-only views
// onto interrupt state computed elsewhere (TopIR / IMSIC), so they hold no
// registers. All three privilege variants in each family are byte-identical
// apart from port names, so one primitive backs each family; the thin wrappers
// remap the {m,s,vs}topi_* / {m,s,vs}topei_* pins.
//
//   xs_topi  : *topi  CSR = {36'h0, IID[11:0], 8'h0, IPRIO[7:0]}.
//   xs_topei : *topei CSR = {37'h0, IID[10:0], 5'h0, IPRIO[10:0]}, and also
//              re-exports IID/IPRIO as regOut_* (they are wires here, not regs).

module xs_topi (
    output [63:0] rdata,
    input  [11:0] topIR_IID,
    input  [7:0]  topIR_IPRIO
);
  assign rdata = {36'h0, topIR_IID, 8'h0, topIR_IPRIO};
endmodule

module xs_topei (
    output [63:0] rdata,
    output [10:0] regOut_IID,
    output [10:0] regOut_IPRIO,
    input  [10:0] aiaToCSR_IID,
    input  [10:0] aiaToCSR_IPRIO
);
  assign rdata        = {37'h0, aiaToCSR_IID, 5'h0, aiaToCSR_IPRIO};
  assign regOut_IID   = aiaToCSR_IID;
  assign regOut_IPRIO = aiaToCSR_IPRIO;
endmodule
