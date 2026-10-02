// HipModule.sv — hypervisor interrupt-pending CSR (hip) slice inside NewCSR.
// hip is a read view: every pending bit lives elsewhere (mip / hvip) and this
// leaf only assembles the 64-bit CSR encoding. The one writable-looking bit,
// VSSIP (bit 2), is not stored here: a write sideband (toHvip_VSSIP_*) forwards
// the write to the hvip register, and reads always reflect hvip_VSSIP.
// Hardwired-zero bits: [63:13], [11], [9:7], [5:3], [1:0]. No state, no reset.
module xs_HipModule_core (
  input  logic        wen,            // w_wen: CSR write strobe (to hvip sideband)
  input  logic [63:0] wdata,          // w_wdata: only bit 2 (VSSIP) is forwarded
  input  logic        mip_vstip,      // VSTIP pending lives in mip
  input  logic        mip_vseip,      // VSEIP pending lives in mip
  input  logic        mip_sgeip,      // SGEIP pending lives in mip
  input  logic        hvip_vssip,     // VSSIP pending lives in hvip
  output logic [63:0] value,          // assembled hip read data
  output logic        out_vssip,
  output logic        out_vstip,
  output logic        out_vseip,
  output logic        out_sgeip,
  output logic        hvip_wen,       // sideband write strobe to hvip.VSSIP
  output logic        hvip_wbit       // sideband write data bit
);
  // hip layout: SGEIP=12, VSEIP=10, VSTIP=6, VSSIP=2; all other bits hard 0.
  assign value = {51'h0, mip_sgeip, 1'h0, mip_vseip, 3'h0,
                  mip_vstip, 3'h0, hvip_vssip, 2'h0};
  assign out_vssip = hvip_vssip;
  assign out_vstip = mip_vstip;
  assign out_vseip = mip_vseip;
  assign out_sgeip = mip_sgeip;
  // Write sideband: note golden does NOT gate the bits with wen
  // (toHvip_VSSIP_bits = w_wdata[2] unconditionally); kept bug-for-bug.
  assign hvip_wen  = wen;
  assign hvip_wbit = wdata[2];
endmodule

module HipModule (
  input         w_wen,
  input  [63:0] w_wdata,
  output [63:0] rdata,
  output        regOut_VSSIP,
  output        regOut_VSTIP,
  output        regOut_VSEIP,
  output        regOut_SGEIP,
  input         mip_VSTIP,
  input         mip_VSEIP,
  input         mip_SGEIP,
  input         hvip_VSSIP,
  output        toHvip_VSSIP_valid,
  output        toHvip_VSSIP_bits
);
  xs_HipModule_core u_core (
    .wen(w_wen),
    .wdata(w_wdata),
    .mip_vstip(mip_VSTIP),
    .mip_vseip(mip_VSEIP),
    .mip_sgeip(mip_SGEIP),
    .hvip_vssip(hvip_VSSIP),
    .value(rdata),
    .out_vssip(regOut_VSSIP),
    .out_vstip(regOut_VSTIP),
    .out_vseip(regOut_VSEIP),
    .out_sgeip(regOut_SGEIP),
    .hvip_wen(toHvip_VSSIP_valid),
    .hvip_wbit(toHvip_VSSIP_bits)
  );
endmodule
