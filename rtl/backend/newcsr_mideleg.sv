// NewCSR bespoke module: MidelegModule (machine interrupt delegation CSR).
//
// Faithful, readable reimplementation of the golden MidelegModule. mideleg is a
// bit-mask WARL register delegating supervisor-visible interrupt sources to S.
// Only four bits are architected here (SSI, STI, SEI, LCOFI); the remaining bit
// positions read as fixed constants (the interrupt-code layout). Transcribed
// bit-for-bit from golden — note the rdata packing embeds constant nibbles
// 3'h5 and 3'h1 between the register bits, so it is NOT a simple sparse mask.
//
// Fields (write bit position -> read bit position):
//   SSI   : w_wdata[1]  -> rdata[1]
//   STI   : w_wdata[5]  -> rdata[5]
//   SEI   : w_wdata[9]  -> rdata[9]
//   LCOFI : w_wdata[13] -> rdata[13]
// rdata = {50'h0, LCOFI, 3'h5, SEI, 3'h1, STI, 3'h1, SSI, 1'h0}.
// All async-reset to 0.

module xs_mideleg (
    input         clock,
    input         reset,
    input         w_wen,
    input  [63:0] w_wdata,
    output [63:0] rdata,
    output        regOut_SSI,
    output        regOut_STI,
    output        regOut_SEI,
    output        regOut_LCOFI
);

  reg reg_SSI, reg_STI, reg_SEI, reg_LCOFI;

  always @(posedge clock or posedge reset) begin
    if (reset) begin
      reg_SSI   <= 1'h0;
      reg_STI   <= 1'h0;
      reg_SEI   <= 1'h0;
      reg_LCOFI <= 1'h0;
    end
    else if (w_wen) begin
      reg_SSI   <= w_wdata[1];
      reg_STI   <= w_wdata[5];
      reg_SEI   <= w_wdata[9];
      reg_LCOFI <= w_wdata[13];
    end
  end

  assign rdata =
    {50'h0, reg_LCOFI, 3'h5, reg_SEI, 3'h1, reg_STI, 3'h1, reg_SSI, 1'h0};

  assign regOut_SSI   = reg_SSI;
  assign regOut_STI   = reg_STI;
  assign regOut_SEI   = reg_SEI;
  assign regOut_LCOFI = reg_LCOFI;

endmodule
