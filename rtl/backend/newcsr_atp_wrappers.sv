// NewCSR address-translation-pointer CSRs (SatpModule, VSatpModule, HgatpModule).
//
// The *atp / hgatp CSRs each hold {MODE, ASID|VMID, PPN} with slightly different
// WARL rules, so they are transcribed individually (no shared primitive). All
// MODE fields are WARL-legalized: only Bare(0), Sv39(8), Sv48(9) are accepted; a
// write with any other MODE is dropped for MODE (and for satp/hgatp the whole
// register keeps its old value on an illegal MODE). FM-verified strict, no black
// box. VSatp/Hgatp are H-extension (Kunminghu V2R2 is hypervisor-capable).

// ---- satp (supervisor address translation & protection) --------------------
// On w_wen with a legal MODE, latch MODE/ASID/PPN together; PPN is zero-extended
// from the low 36 bits. An illegal MODE drops the entire write.
module SatpModule(
  input         clock,
  input         reset,
  input         w_wen,
  input  [63:0] w_wdata,
  output [63:0] rdata,
  output [3:0]  regOut_MODE,
  output [15:0] regOut_ASID,
  output [43:0] regOut_PPN
);
  reg [3:0]  reg_MODE;
  reg [15:0] reg_ASID;
  reg [43:0] reg_PPN;
  always @(posedge clock or posedge reset) begin
    if (reset) begin
      reg_MODE <= 4'h0;
      reg_ASID <= 16'h0;
      reg_PPN  <= 44'h0;
    end
    else if (w_wen
             & (|{w_wdata[63:60] == 4'h9,
                  w_wdata[63:60] == 4'h8,
                  w_wdata[63:60] == 4'h0})) begin
      reg_MODE <= w_wdata[63:60];
      reg_ASID <= w_wdata[59:44];
      reg_PPN  <= {8'h0, w_wdata[35:0]};
    end
  end
  assign rdata       = {reg_MODE, reg_ASID, reg_PPN};
  assign regOut_MODE = reg_MODE;
  assign regOut_ASID = reg_ASID;
  assign regOut_PPN  = reg_PPN;
endmodule

// ---- vsatp (virtual-supervisor atp) ----------------------------------------
// PPN is additionally masked by the active hgatp MODE (guest-physical width).
// modeLegal[2:0] one-hots the three legal MODE encodings (Sv48/Sv39/Bare);
// writeLegal is a normal write of a legal MODE; writeIllegalNonVirt is the
// odd golden path where a non-virtualized write of an *illegal* MODE still
// updates ASID/PPN (but not MODE). Both preserved verbatim from golden.
module VSatpModule(
  input         clock,
  input         reset,
  input         w_wen,
  input  [63:0] w_wdata,
  output [63:0] rdata,
  output [3:0]  regOut_MODE,
  output [15:0] regOut_ASID,
  output [43:0] regOut_PPN,
  input         v,
  input  [3:0]  hgatp_MODE
);
  reg  [3:0]  reg_MODE;
  reg  [15:0] reg_ASID;
  reg  [43:0] reg_PPN;
  wire [2:0]  modeLegal =
    {w_wdata[63:60] == 4'h9, w_wdata[63:60] == 4'h8, w_wdata[63:60] == 4'h0};
  wire        writeLegal          = w_wen & (|modeLegal);
  wire        writeIllegalNonVirt = w_wen & ~v & modeLegal == 3'h0;
  always @(posedge clock or posedge reset) begin
    if (reset) begin
      reg_MODE <= 4'h0;
      reg_ASID <= 16'h0;
      reg_PPN  <= 44'h0;
    end
    else begin
      if (writeLegal | writeIllegalNonVirt & w_wen & (|modeLegal))
        reg_MODE <= w_wdata[63:60];
      if (writeLegal | writeIllegalNonVirt)
        reg_ASID <= w_wdata[59:44];
      if (writeLegal | writeIllegalNonVirt)
        reg_PPN <=
          w_wdata[43:0]
          & ((hgatp_MODE == 4'h0 ? 44'hFFFFFFFFF : 44'h0)
             | (hgatp_MODE == 4'h8 ? 44'h1FFFFFFF : 44'h0)
             | (hgatp_MODE == 4'h9 ? 44'h3FFFFFFFFF : 44'h0));
    end
  end
  assign rdata       = {reg_MODE, reg_ASID, reg_PPN};
  assign regOut_MODE = reg_MODE;
  assign regOut_ASID = reg_ASID;
  assign regOut_PPN  = reg_PPN;
endmodule

// ---- hgatp (hypervisor guest address translation & protection) -------------
// Holds {MODE, VMID, PPN}; MODE WARL-legalized like satp, VMID/PPN updated on any
// write. PPN low 2 bits are forced to 0 (Sv-x4 4KiB*4 root alignment).
module HgatpModule(
  input         clock,
  input         reset,
  input         w_wen,
  input  [63:0] w_wdata,
  output [63:0] rdata,
  output [3:0]  regOut_MODE,
  output [13:0] regOut_VMID,
  output [43:0] regOut_PPN
);
  reg [3:0]  reg_MODE;
  reg [13:0] reg_VMID;
  reg [43:0] reg_PPN;
  always @(posedge clock or posedge reset) begin
    if (reset) begin
      reg_MODE <= 4'h0;
      reg_VMID <= 14'h0;
      reg_PPN  <= 44'h0;
    end
    else begin
      if (w_wen
          & (|{w_wdata[63:60] == 4'h9, w_wdata[63:60] == 4'h8, w_wdata[63:60] == 4'h0}))
        reg_MODE <= w_wdata[63:60];
      if (w_wen) begin
        reg_VMID <= w_wdata[57:44];
        reg_PPN  <= {8'h0, w_wdata[35:2], 2'h0};
      end
    end
  end
  assign rdata       = {reg_MODE, 2'h0, reg_VMID, reg_PPN};
  assign regOut_MODE = reg_MODE;
  assign regOut_VMID = reg_VMID;
  assign regOut_PPN  = reg_PPN;
endmodule
