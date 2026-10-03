// MtopiModule packs interrupt identity and priority into the TOPI CSR layout.
// The semantic core names the operation; the exact-name wrapper preserves integration.
// This leaf is combinational and contains no hidden architectural state.
module xs_MtopiModule_core (
  input  logic [11:0] iid,
  input  logic [7:0]  irq_priority,
  output logic [63:0] value,
  output logic [11:0] iid_view
);
  assign value = {36'b0, iid, 8'b0, irq_priority};
  assign iid_view = iid;
endmodule

module MtopiModule (
  output logic [63:0] rdata,
  output logic [11:0] regOut_IID,
  input  logic [11:0] topIR_mtopi_IID,
  input  logic [7:0]  topIR_mtopi_IPRIO
);
  xs_MtopiModule_core u_core (
    .iid(topIR_mtopi_IID),
    .irq_priority(topIR_mtopi_IPRIO),
    .value(rdata),
    .iid_view(regOut_IID)
  );
endmodule
