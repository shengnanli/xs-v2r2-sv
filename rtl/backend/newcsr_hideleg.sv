// NewCSR bespoke module: HidelegModule (hypervisor interrupt delegation CSR).
//
// Faithful, readable reimplementation of the golden HidelegModule. hideleg
// delegates VS-mode interrupts from HS-mode down to VS-mode. Only the three
// standard VS interrupts (VSSI/VSTI/VSEI) plus the local counter-overflow
// interrupt (LCOFI) are backed by writable registers; every other architected
// mip/mie bit is hardwired to read 0 out of this CSR (it can never delegate S/M
// interrupts). Additionally, hideleg is subordinate to mideleg: an interrupt can
// only be delegated to VS if HS itself was delegated it, so the LCOFI *output*
// is gated by mideleg_LCOFI (golden _regOut_LCOFI_WIRE_2 = reg_LCOFI &
// mideleg_LCOFI). VSSI/VSTI/VSEI need no such gate (they are inherently guest).
//
// Bit positions in the CSR word:  VSSI=2  VSTI=6  VSEI=10  LCOFI=13.
// All async-reset to 0.

module xs_hideleg (
    input         clock,
    input         reset,
    input         w_wen,
    input  [63:0] w_wdata,
    output [63:0] rdata,
    output        regOut_SSI,
    output        regOut_VSSI,
    output        regOut_MSI,
    output        regOut_STI,
    output        regOut_VSTI,
    output        regOut_MTI,
    output        regOut_SEI,
    output        regOut_VSEI,
    output        regOut_MEI,
    output        regOut_SGEI,
    output        regOut_LCOFI,
    input         mideleg_SSI,
    input         mideleg_STI,
    input         mideleg_SEI,
    input         mideleg_LCOFI
);

  reg reg_VSSI, reg_VSTI, reg_VSEI, reg_LCOFI;

  wire regOut_LCOFI_gated = reg_LCOFI & mideleg_LCOFI;

  always @(posedge clock or posedge reset) begin
    if (reset) begin
      reg_VSSI  <= 1'h0;
      reg_VSTI  <= 1'h0;
      reg_VSEI  <= 1'h0;
      reg_LCOFI <= 1'h0;
    end
    else if (w_wen) begin
      reg_VSSI  <= w_wdata[2];
      reg_VSTI  <= w_wdata[6];
      reg_VSEI  <= w_wdata[10];
      reg_LCOFI <= w_wdata[13];
    end
  end

  assign rdata =
    {50'h0, regOut_LCOFI_gated, 2'h0, reg_VSEI, 3'h0, reg_VSTI, 3'h0, reg_VSSI, 2'h0};

  assign regOut_SSI   = 1'h0;
  assign regOut_VSSI  = reg_VSSI;
  assign regOut_MSI   = 1'h0;
  assign regOut_STI   = 1'h0;
  assign regOut_VSTI  = reg_VSTI;
  assign regOut_MTI   = 1'h0;
  assign regOut_SEI   = 1'h0;
  assign regOut_VSEI  = reg_VSEI;
  assign regOut_MEI   = 1'h0;
  assign regOut_SGEI  = 1'h0;
  assign regOut_LCOFI = regOut_LCOFI_gated;

endmodule
